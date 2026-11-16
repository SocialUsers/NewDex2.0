--!strict

-- Real router + collector: one engine subscription, no Output echo.
do
	local oldLog = service.LogService
	local handlers = {}
	local connections, live = 0, 0
	local out = {}
	function out:Connect(fn)
		connections += 1
		live += 1
		local active = true
		handlers[#handlers + 1] = function(...)
			if active then
				fn(...)
			end
		end
		return {
			Disconnect = function()
				if active then
					active = false
					live -= 1
				end
			end,
		}
	end
	function out:Fire(...)
		for _, fn in ipairs(handlers) do
			fn(...)
		end
	end
	service.LogService = {
		MessageOut = out,
		ClearOutput = function()
			error("Roblox Output must not be cleared")
		end,
	}
	local function create()
		return Apps.BridgeCommandRouter.Create({ Apps = Apps, Main = Main, service = service, env = {}, Game = game })
	end
	local bridge = create()
	local function call(name, args)
		return bridge:Execute(name, args or {}, { inspect = true })
	end
	local initial = call("dex_get_logs")
	assert(initial.scope == "client" and #initial.entries == 0 and live == 1 and connections == 1)
	local base = initial.nextSequence
	local capabilities = bridge:Capabilities()
	local names = {}
	for _, tool in ipairs(capabilities.commands) do
		names[tool.name] = tool.grant
	end
	assert(names.dex_get_logs == "inspect" and names.dex_clear_logs == "inspect")
	for _, name in ipairs({ "dex_get_logs", "dex_clear_logs" }) do
		local ok, why = pcall(bridge.Execute, bridge, name, {}, { inspect = false })
		assert(not ok and tostring(why):find("PERMISSION_DENIED", 1, true))
	end
	out:Fire("hello", "MessageOutput")
	out:Fire("warning a.b", "MessageWarning")
	out:Fire("error", "MessageError")
	out:Fire("warning aXb", "MessageWarning")
	out:Fire("warning a.b last", "MessageWarning")
	out:Fire("info", "MessageInfo")
	local first = call("dex_get_logs", { afterSequence = base, limit = 2 })
	assert(
		#first.entries == 2
			and first.nextSequence == base + 2
			and first.hasMore
			and first.entries[1].timestamp > 0
			and first.entries[2].messageType == "MessageWarning"
	)
	local second = call("dex_get_logs", { afterSequence = first.nextSequence, limit = 200 })
	assert(#second.entries == 4 and not second.hasMore and second.nextSequence == base + 6)
	local filtered = call("dex_get_logs", { afterSequence = base, level = "warning", text = "a.b", limit = 1 })
	assert(
		#filtered.entries == 1
			and filtered.entries[1].sequence == base + 2
			and filtered.nextSequence == base + 4
			and filtered.hasMore,
		"literal filtering advances over examined nonmatches"
	)
	local rest = call("dex_get_logs", { afterSequence = filtered.nextSequence, level = "warning", text = "a.b" })
	assert(
		#rest.entries == 1
			and rest.entries[1].sequence == base + 5
			and rest.nextSequence == base + 6
			and not rest.hasMore
	)
	assert(
		#call("dex_get_logs", { afterSequence = rest.nextSequence }).entries == 0,
		"polling does not duplicate logs or echo bridge requests/results"
	)
	assert(
		#call("dex_get_logs", { level = "error" }).entries == 1
			and #call("dex_get_logs", { text = "WARNING" }).entries == 0,
		"level and case-sensitive literal filters"
	)
	for _, args in ipairs({
		{ limit = 0 },
		{ limit = 201 },
		{ level = "server" },
		{ afterSequence = -1 },
		{ afterSequence = base + 7 },
		{ text = string.rep("x", 1025) },
	}) do
		local ok, why = pcall(call, "dex_get_logs", args)
		assert(not ok and tostring(why):find("INVALID_ARGUMENT", 1, true))
	end
	local cleared = call("dex_clear_logs")
	assert(cleared.clearedMessages == 6 and cleared.robloxOutputCleared == false and cleared.nextSequence == base + 6)
	local empty = call("dex_get_logs", { afterSequence = base })
	assert(#empty.entries == 0 and empty.droppedSinceCursor == 6 and empty.nextSequence == base + 6)
	for index = 1, 600 do
		out:Fire("entry " .. index, "MessageOutput")
	end
	local overflow = call("dex_get_logs", { afterSequence = cleared.nextSequence, limit = 200 })
	assert(
		overflow.bufferedMessages == 512
			and overflow.droppedSinceCursor == 88
			and overflow.entries[1].sequence == base + 95
			and overflow.droppedMessages >= 94,
		"entry overflow reports the exact missing range"
	)
	local seen = {}
	local cursor = cleared.nextSequence
	local count = 0
	repeat
		local page = call("dex_get_logs", { afterSequence = cursor, limit = 37 })
		for _, entry in ipairs(page.entries) do
			assert(not seen[entry.sequence])
			seen[entry.sequence] = true
			count += 1
		end
		cursor = page.nextSequence
	until not page.hasMore
	assert(count == 512 and cursor == base + 606)
	call("dex_clear_logs")
	for _ = 1, 90 do
		out:Fire(string.rep("x", 4096), "MessageWarning")
	end
	local bytes = call("dex_get_logs", { limit = 200 })
	assert(
		bytes.bufferedBytes <= 262144 and bytes.bufferedMessages < 90 and #bytes.entries == 6 and bytes.hasMore,
		"total byte and response byte budgets are independent of entry count"
	)
	call("dex_clear_logs")
	out:Fire(string.rep("é", 3000), "MessageError")
	local unicode = call("dex_get_logs").entries[1]
	assert(
		unicode.truncated
			and unicode.originalBytes == 6000
			and #unicode.message == 4096
			and utf8.len(unicode.message) == 2048,
		"individual message cap preserves UTF-8"
	)
	local other = create()
	assert(live == 1 and connections == 1, "multiple users of the collector share exactly one subscription")
	bridge:Destroy()
	assert(live == 1)
	other:Destroy()
	other:Destroy()
	assert(live == 0, "last teardown disconnects exactly once")
	out:Fire("not captured while disconnected", "MessageOutput")
	bridge = create()
	assert(live == 1 and connections == 2)
	local reconnected = call("dex_get_logs", { afterSequence = unicode.sequence - 1 })
	assert(
		#reconnected.entries == 0
			and reconnected.nextSequence == unicode.sequence
			and reconnected.droppedSinceCursor == 1,
		"teardown releases data and reconnect reports the gap without resetting sequence IDs"
	)
	out:Fire("after reconnect", "MessageOutput")
	local new = call("dex_get_logs", { afterSequence = unicode.sequence })
	assert(
		#new.entries == 1 and new.entries[1].sequence == unicode.sequence + 1,
		"old listeners cannot duplicate reconnect logs"
	)
	bridge:Destroy()
	assert(live == 0)
	service.LogService = oldLog
	print(
		"PASS: client log filtering, literal matching, cursor pagination, count/byte/message caps, gaps, clear, grants, no feedback and one-subscription teardown/reconnect"
	)
end

--!strict

do
	initBridgeSelection()
	local bridge = Apps.BridgeCommandRouter.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		env = { loadstring = loadstring },
		Game = game,
	})
	local inspect = { inspect = true }
	local execute = { inspect = true, execute = true }
	local edit = { inspect = true, edit = true }
	local function call(name, args, grants)
		return bridge:Execute(name, args or {}, grants or inspect)
	end
	local function rejected(fn, needle)
		local ok, why = pcall(fn)
		assert(not ok and tostring(why):find(needle, 1, true), tostring(why))
	end
	for _, name in ipairs({
		"RemoteEvent",
		"UnreliableRemoteEvent",
		"RemoteFunction",
		"BindableEvent",
		"BindableFunction",
	}) do
		API.Classes[name] = { Name = name, Superclass = "Instance", Properties = {}, Tags = {} }
	end
	local folder = Instance.new("Folder", workspace)
	folder.Name = "Remote test fixture"
	local event = Instance.new("RemoteEvent", folder)
	event.Name = "Action"
	event.OnClientEvent = signal()
	local func = Instance.new("RemoteFunction", folder)
	func.Name = "Query"
	local bindable = Instance.new("BindableEvent", folder)
	bindable.Event = signal()
	local bindFunction = Instance.new("BindableFunction", folder)
	local sent, last = 0, nil
	event.FireServer = function(self, ...)
		assert(self == event)
		sent += 1
		last = table.pack(...)
	end
	func.InvokeServer = function(self, ...)
		assert(self == func)
		local values = table.pack(...)
		assert(values.n == 2 and values[1] == nil and values[2] == false)
		return nil, false, event
	end
	bindable.Fire = function(self, ...)
		last = table.pack(...)
		bindable.Event:Fire(...)
	end
	bindFunction.Invoke = function()
		return "local result", 0
	end
	local eid, fid = bridge.Registry:Id(event), bridge.Registry:Id(func)
	local discovered = call("dex_list_remotes", { rootId = bridge.Registry:Id(folder) })
	assert(#discovered.items == 4 and sent == 0, "discovery never calls endpoints")
	assert(call("dex_get_remote_info", { instanceId = eid }).operation == "FireServer")
	rejected(function()
		call("dex_fire_remote", { instanceId = eid })
	end, "PERMISSION_DENIED")
	assert(sent == 0, "inspection cannot fire remotes")
	local tableValue = {
		type = "Table",
		entries = {
			{ key = "enabled", value = false },
			{ key = "position", value = { type = "Vector3", x = 1, y = 2, z = 3 } },
		},
	}
	local fire =
		call("dex_fire_remote", { instanceId = eid, arguments = { { type = "nil" }, false, 0, tableValue } }, execute)
	assert(
		sent == 1
			and last.n == 4
			and last[1] == nil
			and last[2] == false
			and last[3] == 0
			and last[4].enabled == false
			and last[4].position == vec(1, 2, 3),
		"typed arguments preserve nil tuples and nested data without evaluating source"
	)
	assert(
		fire.status == "sent" and not fire.serverAcknowledged and not fire.serverResponded,
		"event send does not fabricate server acceptance"
	)
	local invoked = call("dex_invoke_remote", { instanceId = fid, arguments = { { type = "nil" }, false } }, execute)
	assert(
		invoked.status == "returned"
			and invoked.returnCount == 3
			and invoked.returns[1].type == "nil"
			and invoked.returns[2] == false
			and invoked.returns[3].id == eid
			and invoked.serverResponded,
		"server function return tuple preserves all positions"
	)
	local retrieved = call("dex_get_call", { callId = invoked.callId })
	assert(retrieved.returns[3].id == eid)
	local failing = Instance.new("RemoteFunction", folder)
	failing.InvokeServer = function()
		error("handler rejected input")
	end
	local failure = call("dex_invoke_remote", { instanceId = bridge.Registry:Id(failing) }, execute)
	assert(
		failure.status == "failed" and failure.error:find("handler rejected input", 1, true),
		"actual callback errors are preserved as failed calls"
	)
	local large = Instance.new("RemoteFunction", folder)
	large.InvokeServer = function()
		return string.rep("a", 40000)
	end
	local oversized = call("dex_invoke_remote", { instanceId = bridge.Registry:Id(large) }, execute)
	assert(
		oversized.status == "returned" and oversized.resultError and not oversized.returns,
		"serialization limits do not misreport an already executed invocation as unexecuted"
	)
	local localResult = call("dex_invoke_bindable", { instanceId = bridge.Registry:Id(bindFunction) }, execute)
	assert(localResult.scope == "client" and localResult.returns[2] == 0)
	call("dex_fire_bindable", { instanceId = bridge.Registry:Id(bindable), arguments = { "hello" } }, execute)
	assert(last[1] == "hello")
	rejected(function()
		call("dex_fire_remote", { instanceId = bridge.Registry:Id(bindable) }, execute)
	end, "INVALID_TARGET")
	local fake = Instance.new("RemoteEvent", folder)
	fake.Inferred = true
	rejected(function()
		call("dex_fire_remote", { instanceId = bridge.Registry:Id(fake) }, execute)
	end, "INFERRED_READ_ONLY")
	rejected(function()
		bridge.Codec:Decode({ type = "Table", entries = { { key = "x", value = 1 }, { key = "x", value = 2 } } })
	end, "duplicate table key")
	local watch = call("dex_watch_remote", { instanceId = eid })
	event.OnClientEvent:Fire(nil, false, "incoming")
	local observed = call("dex_get_remote_events", { watchId = watch.watchId })
	assert(
		observed.events[1].argumentCount == 3
			and observed.events[1].arguments[1].type == "nil"
			and observed.events[1].arguments[2] == false,
		"incoming event subscription preserves argument tuples"
	)
	assert(#call("dex_get_remote_events", { watchId = watch.watchId, afterId = observed.nextId }).events == 0)
	for index = 1, 30 do
		event.OnClientEvent:Fire(index)
	end
	assert(
		call("dex_get_remote_events", { watchId = watch.watchId }).dropped > 0,
		"high-frequency incoming event capture is rate bounded"
	)
	call("dex_stop_remote_watch", { watchId = watch.watchId })
	assert(#call("dex_list_remote_watches").watches == 0)
	local originalName = event.Name
	local changes = {
		{ command = "dex_rename_instance", args = { instanceId = eid, name = "Renamed by batch" } },
		{ command = "dex_set_attributes", args = { instanceIds = { eid }, attributes = { Enabled = false } } },
	}
	local before = Apps.History.Index
	local previousEntry = Apps.History.Entries[before]
	call("dex_apply_changes", { changes = changes }, edit)
	assert(
		event.Name == "Renamed by batch"
			and event:GetAttribute("Enabled") == false
			and Apps.History.Index == math.min(before + 1, Apps.History.Limit)
			and Apps.History.Entries[Apps.History.Index] ~= previousEntry,
		"structured batch is one real history transaction"
	)
	local history = call("dex_get_history")
	call("dex_undo", { expectedIndex = history.index, expectedHead = history.head }, edit)
	assert(
		event.Name == originalName and event:GetAttribute("Enabled") == nil,
		"one undo reverses the complete change set"
	)
	changes[2] =
		{ command = "dex_set_properties", args = { instanceIds = { eid }, properties = { MissingProperty = 1 } } }
	rejected(function()
		call("dex_apply_changes", { changes = changes }, edit)
	end, "INVALID_PROPERTY")
	assert(event.Name == originalName, "failed batch rolls back prior successful edit")
	rejected(function()
		call("dex_apply_changes", { changes = { { command = "dex_fire_remote", args = { instanceId = eid } } } }, edit)
	end, "INVALID_COMMAND")
	local blocked = {}
	for index = 1, 4 do
		local value = Instance.new("RemoteFunction", folder)
		value.InvokeServer = function()
			coroutine.yield()
			return true
		end
		local pending = call("dex_invoke_remote", { instanceId = bridge.Registry:Id(value) }, execute)
		assert(pending.status == "pending")
		blocked[index] = pending
	end
	local fifth = Instance.new("RemoteFunction", folder)
	rejected(function()
		call("dex_invoke_remote", { instanceId = bridge.Registry:Id(fifth) }, execute)
	end, "PENDING_CALL_LIMIT")
	local metadata = call("dex_list_calls")
	for _, record in ipairs(metadata.calls) do
		assert(record.returns == nil, "call listing omits retained payloads")
	end
	local retainedWatch = call("dex_watch_remote", { instanceId = eid })
	bridge:Destroy()
	event.OnClientEvent:Fire("late event")
	folder:Destroy()
	print(
		"PASS: remote discovery, explicit permissions/classes, nil/false/table calls and returns, incoming observations, pending invocation caps, one-transaction batches and rollback"
	)
end

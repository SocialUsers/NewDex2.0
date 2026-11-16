--!strict

do
	initBridgeSelection()
	local folder = Instance.new("Folder", workspace)
	folder.Name = "Testing fixture"
	local part = newPart(folder, vec())
	part.Name = "Asset.x.y"
	part.Anchored = false
	part.Transparency = 0.25
	part:SetAttribute("Ready", false)
	service.CollectionService:AddTag(part, "TestTarget")
	local registry = Apps.BridgeRegistry.Create({ Apps = Apps, Main = Main, Game = game })
	local codec = Apps.BridgeValueCodec.Create(registry)
	local fid, pid = registry:Id(folder), registry:Id(part)
	local clock, cancelled, onWait = 0, false, nil
	local waits = 0
	local dispatches = 0
	local testing
	local function startJob(run)
		local ok, value = pcall(run, function()
			return not cancelled
		end)
		return ok and { status = "completed", result = value } or { status = "failed", error = tostring(value) }
	end
	local read = function(name, args)
		dispatches += 1
		return { name = name, args = args, value = false }
	end
	local function create()
		return Apps.BridgeTestCommands.Create({
			Apps = Apps,
			Main = Main,
			service = service,
			Game = game,
			Registry = registry,
			Codec = codec,
			StartJob = startJob,
			Clock = function()
				return clock
			end,
			Wait = function(seconds)
				clock += seconds
				waits += 1
				if onWait then
					onWait(waits)
				end
			end,
			Read = function(name, args)
				return read(name, args)
			end,
		})
	end
	testing = create()
	local handlers = {}
	for _, command in ipairs(testing.Commands) do
		assert(command.Grant == "inspect")
		handlers[command.Name] = command.Run
	end
	local function call(name, args)
		return handlers["dex_" .. name](args or {})
	end
	local target = { instanceId = pid }
	local function condition(kind, name, expected, op)
		return { kind = kind, target = target, name = name, expected = expected, op = op }
	end
	local checked = call("assert_conditions", {
		checks = {
			{ label = "false property", condition = condition("property", "Anchored", false) },
			{ label = "false attribute", condition = condition("attribute", "Ready", false) },
			{ label = "missing attribute", condition = condition("attribute", "Absent", { type = "nil" }) },
			{
				condition = {
					kind = "property",
					target = target,
					name = "Transparency",
					expected = 0.3,
					tolerance = 0.051,
				},
			},
			{ condition = condition("property", "Name", "x.y", "contains") },
			{ condition = { kind = "tag", target = target, name = "TestTarget" } },
			{ condition = { kind = "class", target = target, className = "BasePart" } },
			{
				condition = {
					kind = "property",
					target = target,
					name = "Parent",
					expected = {
						type = "Instance",
						id = fid,
					},
				},
			},
			{ condition = condition("property", "Transparency", 0.5, "gt") },
			{ condition = condition("property", "Unknown", false) },
		},
	})
	assert(
		not checked.passed
			and checked.counts.passed == 8
			and checked.counts.failed == 1
			and checked.counts.unavailable == 1
			and checked.evaluated == 10
	)
	assert(
		checked.checks[10].name == "Unknown" and checked.checks[10].target.instanceId == pid,
		"unavailable checks retain the requested field and exact target"
	)
	assert(
		checked.checks[1].actual == false and checked.checks[3].actual.type == "nil",
		"assertions preserve actual false/nil rather than treating unavailable as success"
	)
	assert(checked.checks[5].passed and checked.checks[6].passed, "literal strings and tags use declarative predicates")
	local path = { rootId = fid, path = { "Appears" } }
	onWait = function(count)
		if count == 2 then
			local object = Instance.new("Folder", folder)
			object.Name = "Appears"
		end
	end
	local appeared = call(
		"wait_for_condition",
		{ condition = { kind = "exists", target = path }, timeoutSeconds = 1, pollIntervalSeconds = 0.1 }
	)
	assert(
		appeared.status == "completed"
			and appeared.result.status == "satisfied"
			and appeared.result.attempts == 3
			and waits == 2,
		"wait re-resolves exact paths after bounded yielding polls"
	)
	clock = 0
	waits = 0
	onWait = function(count)
		if count == 3 then
			part.Anchored = true
		end
	end
	local changed =
		call("wait_for_condition", { condition = condition("property", "Anchored", true), timeoutSeconds = 1 })
	assert(changed.result.satisfied and changed.result.attempts == 4 and changed.result.lastObservation.actual == true)
	part.Anchored = false
	clock = 0
	waits = 0
	onWait = nil
	local timeout = call(
		"wait_for_condition",
		{ condition = condition("property", "Anchored", true), timeoutSeconds = 0.25, pollIntervalSeconds = 0.1 }
	)
	assert(
		timeout.result.timedOut
			and timeout.result.status == "timed_out"
			and timeout.result.elapsed >= 0.25
			and waits == 3
	)
	clock = 0
	waits = 0
	onWait = function()
		clock += 1
		part.Anchored = true
	end
	local late =
		call("wait_for_condition", { condition = condition("property", "Anchored", true), timeoutSeconds = 0.1 })
	assert(
		late.result.timedOut and late.result.attempts == 1,
		"an oversleep cannot turn a post-deadline change into an on-time pass"
	)
	part.Anchored = false
	onWait = nil
	waits = 3
	local immediate =
		call("wait_for_condition", { condition = condition("property", "Anchored", false), timeoutSeconds = 0 })
	assert(
		immediate.result.satisfied and immediate.result.attempts == 1 and waits == 3,
		"zero timeout checks once without sleeping"
	)
	local unknown = call("wait_for_condition", {
		condition = { kind = "exists", target = { instanceId = "never-known" }, expected = false },
		timeoutSeconds = 0,
	})
	assert(
		unknown.result.timedOut and unknown.result.lastObservation.outcome == "unavailable",
		"unknown handles cannot prove nonexistence"
	)
	local disappearing = Instance.new("Folder", folder)
	local did = registry:Id(disappearing)
	clock = 0
	waits = 0
	onWait = function()
		disappearing:Destroy()
	end
	local gone = call(
		"wait_for_condition",
		{ condition = { kind = "exists", target = { instanceId = did }, expected = false }, timeoutSeconds = 1 }
	)
	assert(
		gone.result.satisfied and gone.result.lastObservation.actual == false,
		"a previously resolved handle can be observed leaving the session"
	)
	local duplicate = Instance.new("Folder", folder)
	duplicate.Name = "Appears"
	onWait = nil
	local ambiguous = call("wait_for_condition", { condition = { kind = "exists", target = path }, timeoutSeconds = 0 })
	assert(
		ambiguous.result.lastObservation.outcome == "unavailable"
			and ambiguous.result.lastObservation.error:find("AMBIGUOUS_TARGET", 1, true)
	)
	duplicate:Destroy()
	local wide = Instance.new("Folder", folder)
	wide.Name = "Wide"
	for _ = 1, 513 do
		Instance.new("Folder", wide)
	end
	local bounded = call("wait_for_condition", {
		condition = {
			kind = "exists",
			target = { rootId = registry:Id(wide), path = { "missing" } },
			expected = false,
		},
		timeoutSeconds = 0,
	})
	assert(
		bounded.result.lastObservation.outcome == "unavailable"
			and bounded.result.lastObservation.error:find("WORK_LIMIT", 1, true),
		"truncated path inspection does not silently prove absence"
	)
	part.Name = string.rep("x", 600)
	local checks = {}
	for _ = 1, 7 do
		checks[#checks + 1] = { condition = condition("property", "Name", string.rep("x", 600)) }
	end
	local truncated = call("assert_conditions", { checks = checks })
	assert(
		truncated.truncated and not truncated.passed and truncated.omittedChecks > 0,
		"incomplete assertions never claim overall pass"
	)
	part.Name = "Asset.x.y"
	local counts = {}
	for _ = 1, 20 do
		counts[#counts + 1] =
			{ condition = { kind = "child_count", target = { instanceId = registry:Id(wide) }, expected = 513 } }
	end
	local workLimited = call("assert_conditions", { checks = counts })
	assert(
		workLimited.candidatesExamined <= 8192 and workLimited.counts.unavailable > 0 and not workLimited.passed,
		"assertions share a candidate work budget instead of performing one large scan per check"
	)
	local requests = { { command = "dex_get_instance", args = { instanceId = pid } } }
	dispatches = 0
	for _, name in ipairs({
		"dex_set_properties",
		"dex_run_luau",
		"dex_invoke_remote",
		"dex_batch_read",
		"dex_wait_for_condition",
		"dex_clear_logs",
		"dex_watch_instance",
		"dex_read_script",
	}) do
		local ok, problem = pcall(call, "batch_read", { requests = { requests[1], { command = name, args = {} } } })
		assert(
			not ok and tostring(problem):find("PERMISSION_DENIED", 1, true) and dispatches == 0,
			"batch validates its whole allowlist before any read"
		)
	end
	local override = pcall(
		call,
		"batch_read",
		{ requests = { { command = "dex_get_instance", args = { instanceId = pid, sessionId = "other" } } } }
	)
	assert(not override and dispatches == 0)
	local batch = call("batch_read", { requests = requests })
	assert(batch.executed == 1 and batch.results[1].result.value == false and batch.nonAtomic and dispatches == 1)
	read = function(name, args)
		if args.fail then
			error("fixture read failed")
		end
		return { value = false }
	end
	local multi = {
		{ command = "dex_get_instance", args = {} },
		{ command = "dex_get_instance", args = { fail = true } },
		{ command = "dex_get_instance", args = {} },
	}
	local continued = call("batch_read", { requests = multi })
	assert(continued.executed == 3 and continued.failed == 1 and continued.results[3].ok)
	local stopped = call("batch_read", { requests = multi, stopOnError = true })
	assert(stopped.executed == 2 and stopped.skipped == 1 and stopped.results[3].error.code == "NOT_EXECUTED")
	read = function()
		return { large = string.rep("z", 10000) }
	end
	local large = call("batch_read", { requests = requests })
	assert(large.truncated and large.results[1].error.code == "RESULT_LIMIT" and large.results[1].result == nil)
	clock = 0
	read = function()
		clock += 0.1
		return { value = 1 }
	end
	local timed = call("batch_read", { requests = multi, timeoutSeconds = 0.15 })
	assert(timed.executed == 2 and timed.skipped == 1 and timed.timeBudgetExceeded)
	read = function()
		return {}
	end
	clock = 0
	waits = 0
	cancelled = false
	onWait = function()
		cancelled = true
	end
	local cancelledWait =
		call("wait_for_condition", { condition = condition("property", "Anchored", true), timeoutSeconds = 1 })
	assert(cancelledWait.status == "failed" and cancelledWait.error:find("CANCELLED", 1, true))
	cancelled = false
	onWait = function()
		testing:Destroy()
	end
	clock = 0
	local destroyed =
		call("wait_for_condition", { condition = condition("property", "Anchored", true), timeoutSeconds = 1 })
	assert(destroyed.status == "failed" and destroyed.error:find("CANCELLED", 1, true))
	local afterDestroy =
		pcall(call, "assert_conditions", { checks = { { condition = condition("property", "Anchored", false) } } })
	assert(not afterDestroy)
	-- Exercise the real router dispatcher so batching cannot bypass Inspect grants.
	local disabled = {}
	local bridge = Apps.BridgeCommandRouter.Create({
		Apps = Apps, Main = Main, service = service, env = {}, Game = game, DisabledTools = disabled,
	})
	local actualId = bridge.Registry:Id(part)
	local actual = bridge:Execute("dex_batch_read", {
		requests = {
			{ command = "dex_get_properties", args = { instanceId = actualId, properties = { "Anchored" } } },
			{ command = "dex_get_instance", args = { instanceId = "stale" } },
			{ command = "dex_get_attributes", args = { instanceId = actualId } },
		},
	}, { inspect = true })
	assert(
		actual.executed == 3
			and actual.failed == 1
			and actual.results[1].result.properties.Anchored == false
			and actual.results[3].result.attributes.Ready == false
	)
	disabled.dex_get_properties = true
	local filtered = bridge:Execute("dex_batch_read", {
		requests = { { command = "dex_get_properties", args = { instanceId = actualId } } },
	}, { inspect = true })
	assert(filtered.failed == 1 and not filtered.results[1].ok)
	assert(filtered.results[1].error.message:find("disabled", 1, true))
	local immediateJob = bridge:Execute("dex_wait_for_condition", {
		condition = { kind = "property", target = { instanceId = actualId }, name = "Anchored", expected = false },
		timeoutSeconds = 0,
	}, { inspect = true })
	local result = bridge:Execute("dex_get_job", { jobId = immediateJob.jobId }, { inspect = true })
	assert(result.status == "completed" and result.result.satisfied)
	for _, name in ipairs({ "dex_wait_for_condition", "dex_assert_conditions", "dex_batch_read" }) do
		local ok, problem = pcall(bridge.Execute, bridge, name, {}, { inspect = false })
		assert(not ok and tostring(problem):find("PERMISSION_DENIED", 1, true))
	end
	bridge:Destroy()
	registry:Destroy()
	folder:Destroy()
	print(
		"PASS: condition predicates, exact paths/ambiguity, typed assertions, bounded/cancellable waits, no-listener teardown, read-only batches, budget/error isolation and real router grants"
	)
end

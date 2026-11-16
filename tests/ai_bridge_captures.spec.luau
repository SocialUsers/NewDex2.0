--!strict

local capturedRoundTrip
do
	initBridgeSelection()
	local oldIsA = methods.IsA
	methods.IsA = function(self, class)
		return class == "LuaSourceContainer" and (self.ClassName == "ModuleScript" or self.ClassName == "LocalScript")
			or oldIsA(self, class)
	end
	API.Classes.ModuleScript =
		{ Name = "ModuleScript", Superclass = "Instance", Tags = {}, Properties = { { Name = "Source", Tags = {} } } }
	API.Classes.ObjectValue =
		{ Name = "ObjectValue", Superclass = "Instance", Tags = {}, Properties = { { Name = "Value", Tags = {} } } }
	API.Classes.ImageLabel = {
		Name = "ImageLabel",
		Superclass = "Instance",
		Tags = {},
		Properties = {
			{ Name = "Image", Tags = {} },
			{ Name = "Visible", Tags = {} },
		},
	}
	API.Classes.Part.Properties[#API.Classes.Part.Properties + 1] =
		{ Name = "transparency", Tags = { Deprecated = true } }
	API.Classes.Part.Properties[#API.Classes.Part.Properties + 1] =
		{ Name = "ProtectedFixture", Tags = {}, Security = { Read = "None", Write = "RobloxScriptSecurity" } }
	API.Classes.Part.Properties[#API.Classes.Part.Properties + 1] =
		{ Name = "PluginFixture", Tags = {}, Security = { Read = "None", Write = "PluginSecurity" } }
	local parent = Instance.new("Folder", workspace)
	parent.Name = "Reference capture"
	local part = newPart(parent, vec(2, 3, 4))
	part.Name = "Same"
	part.Anchored = false
	part.Transparency = 0
	part.ProtectedFixture = "evidence"
	part.PluginFixture = true
	local other = newPart(parent, vec(5, 3, 4))
	other.Name = "Same"
	other.Anchored = true
	local link = Instance.new("ObjectValue", parent)
	link.Value = part
	local image = Instance.new("ImageLabel", parent)
	image.Image = "rbxassetid://12345"
	image.Visible = true
	local scriptObject = Instance.new("ModuleScript", parent)
	scriptObject.Source =
		'local a = require(script.Parent.Same)\nlocal r = game:GetService("ReplicatedStorage")\nr.Action:FireServer(a)\nreturn a'
	part:SetAttribute("State", false)
	service.CollectionService:AddTag(part, "Fixture")
	local nativeCalls = 0
	local bridge = Apps.BridgeCommandRouter.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		env = {
			loadstring = loadstring,
			decompile = function()
				nativeCalls += 1
				return "return 1"
			end,
		},
		Game = game,
	})
	local function call(name, args)
		return bridge:Execute(name, args or {}, { inspect = true })
	end
	local spawnJob = task.spawn
	local pendingJobs = {}
	task.spawn = function(fn)
		local thread = spawnJob(fn)
		if coroutine.status(thread) == "suspended" then
			pendingJobs[#pendingJobs + 1] = thread
		end
		return thread
	end
	local function finish(job)
		local value
		for attempt = 1, 64 do
			for index = #pendingJobs, 1, -1 do
				local thread = pendingJobs[index]
				if coroutine.status(thread) == "suspended" then
					local ok, problem = coroutine.resume(thread)
					assert(ok, problem)
				end
				if coroutine.status(thread) == "dead" then
					table.remove(pendingJobs, index)
				end
			end
			value = call("dex_get_job", { jobId = job.jobId })
			if value.status ~= "running" and value.status ~= "queued" then
				break
			end
		end
		assert(value.status == "completed", value.error or value.status)
		return value.result
	end
	local pid, lid = bridge.Registry:Id(parent), bridge.Registry:Id(part)
	local function capture(name)
		return finish(call("dex_capture_system", { instanceIds = { pid, lid }, name = name }))
	end
	local before = capture("Shop closed")
	assert(before.counts.nodes == 6 and #before.roots == 1, "nested selected roots are deduplicated")
	local page = call("dex_read_capture", { captureId = before.captureId, section = "nodes", limit = 2 })
	assert(#page.items == 2 and page.nextOffset == 3 and page.total == 6)
	local all = {}
	local offset = 1
	repeat
		local p = call("dex_read_capture", { captureId = before.captureId, section = "nodes", offset = offset })
		for _, v in ipairs(p.items) do
			all[v.id] = v
		end
		offset = p.nextOffset
	until not offset
	assert(
		all[lid].attributes.State == false and all[lid].properties.Anchored == false,
		"capture retains false attributes/properties"
	)
	assert(
		not all[lid].properties.transparency and all[lid].properties.CFrame.type == "CFrame",
		"canonical typed property capture"
	)
	assert(
		all[lid].properties.ProtectedFixture == "evidence"
			and all[lid].writeRestricted.ProtectedFixture == "RobloxScriptSecurity",
		"protected values remain evidence with import restrictions"
	)
	assert(not all[lid].writeRestricted.PluginFixture, "plugin-writable values remain importable")
	assert(all[lid].tags[1] == "Fixture" and not all[lid].properties.Parent)
	local assets = call("dex_get_capture_assets", { captureId = before.captureId })
	assert(#assets.items == 1 and assets.items[1].assetId == "12345")
	local links = call("dex_get_capture_relationships", { captureId = before.captureId })
	assert(
		#links.items == 1 and links.items[1].internal and links.items[1].toId == lid,
		"internal links use IDs, including duplicate names"
	)
	local chunks = call("dex_read_capture", { captureId = before.captureId, section = "scripts" })
	assert(
		chunks.items[1].source == scriptObject.Source and chunks.items[1].offset == 1 and nativeCalls == 0,
		"readable capture invokes no decompiler"
	)
	capturedRoundTrip =
		{ format = "dex-plus-capture", version = 1, name = "Captured fixture", nodes = {}, scripts = chunks.items }
	for _, row in pairs(all) do
		capturedRoundTrip.nodes[#capturedRoundTrip.nodes + 1] = row
	end
	local measured = call("dex_measure_instances", { instanceIds = { lid } })
	assert(measured.instances[1].measurements.boundsCFrame.type == "CFrame" and measured.camera.scope == "client")
	part.Anchored = true
	part:SetAttribute("State", true)
	image.Visible = false
	part.Name = "Renamed"
	scriptObject.Source ..= "\n-- reference changed"
	local after = capture("Shop open")
	local diff = finish(call("dex_compare_captures", { beforeId = before.captureId, afterId = after.captureId }))
	local changes = call("dex_read_capture", { captureId = diff.captureId, section = "changes" }).items
	local seen = {}
	for _, change in ipairs(changes) do
		if change.instanceId == lid then
			seen[change.property or change.kind] = change
		end
	end
	assert(
		seen.Anchored.before == false
			and seen.Anchored.after == true
			and seen.State.before == false
			and seen.name.after == "Renamed",
		"comparison preserves false and separates field changes"
	)
	local sourceChanged = false
	for _, change in ipairs(changes) do
		if change.kind == "source" then
			sourceChanged = true
		end
	end
	assert(sourceChanged, "same-kind source edits are compared by content")
	local search = finish(call("dex_search_scripts", { rootId = pid, query = "Same", caseSensitive = true }))
	assert(
		#search.matches == 1 and search.matches[1].line == 1 and search.matches[1].column == 33,
		"literal search returns precise code location"
	)
	local trace = finish(call("dex_trace_scripts", { rootId = pid }))
	assert(#trace.matches == 3 and nativeCalls == 0, "dependency candidates without require/remote execution")
	-- The shared job ring evicts completed work instead of blocking new captures for 120 seconds.
	local tiny = finish(call("dex_capture_system", { instanceIds = { pid }, maxNodes = 2, includeSource = false }))
	assert(tiny.coverage.truncated and tiny.counts.nodes == 2, "wide subtree cap still visits queued children")
	local heartbeat = service.RunService.Heartbeat
	service.RunService.Heartbeat = signal()
	part.Changed = signal()
	part.AttributeChanged = signal()
	local record = call("dex_start_recording", { instanceId = lid, name = "Upgrade" })
	local started = finish(record.job)
	assert(started.status == "recording" and #call("dex_list_watches").watches == 1)
	call("dex_mark_recording", { recordingId = record.recordingId, label = "Purchased" })
	part.Anchored = false
	part.Changed:Fire("Anchored")
	local recording = finish(call("dex_stop_recording", { recordingId = record.recordingId }))
	assert(
		recording.comparison.counts.changes >= 1
			and recording.comparison.counts.events >= 1
			and recording.comparison.counts.markers == 1,
		"interaction retains actual events and before/after changes"
	)
	assert(
		#call("dex_list_watches").watches == 0
			and call("dex_get_recording", { recordingId = record.recordingId }).status == "completed",
		"finished recorder releases signals"
	)
	-- Cancellation also closes the watch when a capture yields before completion.
	local spawn = task.spawn
	task.spawn = function(fn)
		return coroutine.create(fn)
	end
	local pending = call("dex_start_recording", { instanceId = lid })
	call("dex_cancel_job", { jobId = pending.job.jobId })
	assert(#call("dex_list_watches").watches == 0, "cancelled setup releases its watch")
	task.spawn = spawn
	call("dex_cancel_recording", { recordingId = pending.recordingId })
	service.RunService.Heartbeat = heartbeat
	local retained = call("dex_list_captures")
	assert(#retained.captures <= 8 and retained.estimatedBytes <= 16 * 1024 * 1024)
	call("dex_delete_capture", { captureId = recording.comparison.captureId })
	local ok = pcall(call, "dex_get_capture", { captureId = recording.comparison.captureId })
	assert(not ok, "deletion invalidates capture handles")
	bridge:Destroy()
	task.spawn = spawnJob
	parent:Destroy()
	methods.IsA = oldIsA
	print(
		"PASS: portable capture paging, typed values/assets/links, bounded coverage, source search/tracing, identity diffs and interaction lifecycle"
	)
end

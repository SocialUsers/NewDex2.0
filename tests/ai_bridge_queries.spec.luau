--!strict

do
	initBridgeSelection()
	local folder = Instance.new("Folder", workspace)
	folder.Name = "Query fixture"
	local a = newPart(folder, vec(0, 0, 0))
	a.Name = "a.b"
	a.Anchored = false
	a:SetAttribute("Ready", false)
	local b = newPart(folder, vec(1, 0, 0))
	b.Name = "aXb"
	b.Anchored = true
	b:SetAttribute("Ready", true)
	service.CollectionService:AddTag(a, "Fixture")
	service.CollectionService:AddTag(b, "Fixture")
	local bridge =
		Apps.BridgeCommandRouter.Create({ Apps = Apps, Main = Main, service = service, env = {}, Game = game })
	local function call(name, args)
		return bridge:Execute(name, args or {}, { inspect = true })
	end
	local fid, aid, bid = bridge.Registry:Id(folder), bridge.Registry:Id(a), bridge.Registry:Id(b)
	local batch = call("dex_inspect_instances", {
		instanceIds = { aid, "stale", bid },
		properties = { "Anchored", "Parent", "Absent" },
		includeAttributes = true,
		includeTags = true,
	})
	assert(batch.scope == "client" and batch.processed == 3 and not batch.truncated)
	assert(
		batch.instances[1].properties.Anchored == false
			and batch.instances[1].attributes.Ready == false
			and batch.instances[1].tags[1] == "Fixture",
		"bulk inspection preserves false properties/attributes and reads tags"
	)
	assert(
		batch.instances[1].properties.Parent.id == fid
			and batch.instances[1].errors.Absent
			and batch.instances[2].error
			and batch.instances[3].properties.Anchored == true,
		"individual object/property errors do not discard later reads"
	)
	local nilBatch = call("dex_inspect_instances", { instanceIds = { fid }, properties = { "Parent" } })
	assert(nilBatch.instances[1].properties.Parent.type == "Instance")
	local function finish(job)
		local result = call("dex_get_job", { jobId = job.jobId })
		assert(result.status == "completed", result.error or result.status)
		return result.result
	end
	local query = finish(call("dex_query_instances", {
		rootId = fid,
		className = "BasePart",
		tags = { "Fixture" },
		attributes = { Ready = false },
		properties = {
			Anchored = false,
		},
	}))
	assert(
		#query.instances == 1 and query.instances[1].id == aid and query.scanned == 3 and not query.truncated,
		"tag/attribute/property predicates combine using exact false equality"
	)
	local literal = finish(call("dex_query_instances", { rootId = fid, name = "a.b", caseSensitive = true }))
	assert(#literal.instances == 1 and literal.instances[1].id == aid, "name filter is literal, not a pattern")
	local absent = finish(
		call(
			"dex_query_instances",
			{ rootId = fid, className = "BasePart", attributes = { Missing = { type = "nil" } } }
		)
	)
	assert(#absent.instances == 2, "typed nil tests missing attributes")
	local limited = finish(call("dex_query_instances", { rootId = fid, className = "BasePart", limit = 1 }))
	assert(#limited.instances == 1 and limited.truncated, "result limit never silently implies complete coverage")
	local bounded = finish(call("dex_query_instances", { rootId = fid, maxNodes = 1 }))
	assert(
		bounded.scanned == 1 and bounded.truncated and #bounded.instances == 1,
		"root inclusion and scan budget are explicit"
	)
	a:SetAttribute("Huge", string.rep("x", 9000))
	local large =
		call("dex_inspect_instances", { instanceIds = { aid }, properties = { "Anchored" }, includeAttributes = true })
	assert(
		large.truncated
			and large.omittedFields == 1
			and large.instances[1].errors.attributes
			and large.instances[1].properties.Anchored == false,
		"large optional values are bounded without losing useful fields"
	)
	local ok, why = pcall(bridge.Execute, bridge, "dex_query_instances", { rootId = fid }, { inspect = false })
	assert(not ok and tostring(why):find("PERMISSION_DENIED", 1, true))
	for _, args in ipairs({
		{ rootId = fid, tags = false },
		{ rootId = fid, attributes = false },
		{ rootId = fid, properties = false },
		{ rootId = fid, name = false },
	}) do
		local valid, problem = pcall(call, "dex_query_instances", args)
		assert(not valid and tostring(problem):find("INVALID_ARGUMENT", 1, true))
	end
	local names = {}
	for _, command in ipairs(bridge:Capabilities().commands) do
		names[command.name] = command.grant
	end
	assert(names.dex_inspect_instances == "inspect" and names.dex_query_instances == "inspect")
	bridge:Destroy()
	folder:Destroy()
	print(
		"PASS: bulk typed inspection, partial errors, literal structural queries, exact false/nil predicates, result/scan/byte limits and Inspect grants"
	)
end

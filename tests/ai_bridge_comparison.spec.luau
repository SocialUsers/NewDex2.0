--!strict

-- Real comparison/structure adapter with native-shaped, identity-preserving fixtures.
do
	local oldPart = API.Classes.Part
	local oldObjectValue = API.Classes.ObjectValue
	local oldBillboard = API.Classes.BillboardGui
	local originalIndex = instMT.__index
	local root = Instance.new("Folder", workspace)
	root.Name = "Comparison fixture"
	local class = { Name = "Part", Superclass = "Instance", Tags = {}, Properties = {} }
	for _, member in ipairs(oldPart.Properties) do
		class.Properties[#class.Properties + 1] = member
	end
	for _, name in ipairs({ "FixtureNil", "Unreadable", "lowercaseAlias" }) do
		class.Properties[#class.Properties + 1] = { Name = name, Tags = {} }
	end
	API.Classes.Part = class
	API.Classes.ObjectValue =
		{ Name = "ObjectValue", Superclass = "Instance", Tags = {}, Properties = { { Name = "Value", Tags = {} } } }
	API.Classes.BillboardGui =
		{ Name = "BillboardGui", Superclass = "Instance", Tags = {}, Properties = { { Name = "Adornee", Tags = {} } } }
	local left = newPart(root, vec(1, 2, 3))
	left.Name = "Same"
	left.Anchored = false
	local right = newPart(root, vec(1, 2, 3))
	right.Name = "Same"
	right.Anchored = true
	left:SetAttribute("Flag", false)
	right:SetAttribute("Flag", true)
	right:SetAttribute("OnlyRight", false)
	service.CollectionService:AddTag(left, "Fixture")
	service.CollectionService:AddTag(right, "Fixture")
	local protected = {}
	protected[left] = { Unreadable = true }
	protected[right] = { Unreadable = true }
	instMT.__index = function(object, key)
		if protected[object] and protected[object][key] then
			error("protected fixture property")
		end
		return originalIndex(object, key)
	end
	local registry = Apps.BridgeRegistry.Create({ Apps = Apps, Main = Main, Game = game })
	local codec = Apps.BridgeValueCodec.Create(registry)
	local progress, cancelAfter = 0, nil
	local onCheck
	local comparison = Apps.BridgeComparisonCommands.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		Game = game,
		Registry = registry,
		Codec = codec,
		StartJob = function(run)
			local ok, value = pcall(run, function()
				progress += 1
				if onCheck then
					onCheck(progress)
				end
				return not cancelAfter or progress <= cancelAfter
			end)
			return ok and { status = "completed", result = value } or { status = "failed", error = tostring(value) }
		end,
	})
	local handlers = {}
	for _, command in ipairs(comparison.Commands) do
		assert(command.Grant == "inspect")
		handlers[command.Name] = command.Run
	end
	local function call(name, args)
		return assert(handlers[name], name)(args or {})
	end
	local function finish(job)
		assert(job.status == "completed", job.error)
		return job.result
	end
	local lid, rid, rootId = registry:Id(left), registry:Id(right), registry:Id(root)
	local compared = call(
		"dex_compare_instances",
		{ leftId = lid, rightId = rid, properties = { "Anchored", "FixtureNil", "Unreadable", "Parent" } }
	)
	local byName = {}
	for _, row in ipairs(compared.properties) do
		byName[row.name] = row
	end
	assert(
		compared.scope == "client"
			and byName.Anchored.status == "different"
			and byName.Anchored.left == false
			and byName.Anchored.right == true,
		"typed false differences are not lost"
	)
	assert(
		byName.FixtureNil.status == "equal"
			and byName.FixtureNil.left.type == "nil"
			and byName.FixtureNil.right.type == "nil",
		"available nil equals available nil"
	)
	assert(
		byName.Unreadable.status == "unavailable" and byName.Unreadable.errors.left and byName.Unreadable.errors.right,
		"two failed reads must not be reported equal"
	)
	assert(byName.Parent.status == "equal" and byName.Parent.left.id == rootId, "Instance equality is exact identity")
	local attrs = {}
	for _, row in ipairs(compared.attributes) do
		attrs[row.name] = row
	end
	assert(
		attrs.Flag.left == false
			and attrs.Flag.status == "different"
			and attrs.OnlyRight.left.type == "nil"
			and attrs.OnlyRight.right == false,
		"attribute absence and false remain distinct"
	)
	assert(compared.tags.status == "equal" and compared.tags.left[1] == "Fixture")
	local defaults =
		call("dex_compare_instances", { leftId = lid, rightId = rid, includeAttributes = false, includeTags = false })
	for _, row in ipairs(defaults.properties) do
		assert(
			row.name ~= "Source" and row.name ~= "lowercaseAlias",
			"default canonical property set excludes source and aliases"
		)
	end
	assert(not defaults.tags and #defaults.attributes == 0)
	local valid, why = pcall(call, "dex_compare_instances", { leftId = lid, rightId = rid, properties = { "Source" } })
	assert(not valid and tostring(why):find("UNSUPPORTED", 1, true))
	local parentA = Instance.new("Folder", root)
	parentA.Name = "Same parent"
	local parentB = Instance.new("Folder", root)
	parentB.Name = "Same parent"
	local ca = newPart(parentA, vec())
	ca.Name = "Only one here"
	local cb = newPart(parentB, vec())
	cb.Name = "Only one here"
	local da = newPart(parentA, vec())
	da.Name = "Duplicate"
	local db = newPart(parentA, vec())
	db.Name = "Duplicate"
	local scriptObject = Instance.new("ModuleScript", parentA)
	local summary = finish(call("dex_summarize_hierarchy", { rootId = rootId, maxNodes = 10000, topClasses = 50 }))
	assert(
		summary.scope == "client"
			and summary.totals.instances == 10
			and summary.totals.parts == 6
			and summary.totals.moduleScripts == 1
			and summary.totals.maxDepth == 2,
		"summary counts the visited hierarchy with root included"
	)
	assert(summary.duplicateGroupCount == 3, "duplicate names use siblings of the exact same parent only")
	local groups = {}
	for _, row in ipairs(summary.duplicateNames) do
		groups[row.parent.id .. ":" .. row.name] = row
	end
	assert(
		groups[rootId .. ":Same"].count == 2
			and groups[rootId .. ":Same parent"].count == 2
			and groups[registry:Id(parentA) .. ":Duplicate"].count == 2
	)
	assert(
		not groups[registry:Id(parentA) .. ":Only one here"],
		"same name under different parents is not a sibling collision"
	)
	local capped = finish(call("dex_summarize_hierarchy", { rootId = rootId, maxNodes = 1 }))
	assert(
		capped.totals.instances == 1 and capped.coverage.truncated and capped.coverage.nodeLimitReached,
		"scan limits remain explicit"
	)
	local raceRoot = Instance.new("Folder", root)
	local raceA = Instance.new("Folder", raceRoot)
	raceA.Name = "A"
	local raceB = Instance.new("Folder", raceRoot)
	raceB.Name = "B"
	local stay = newPart(raceA, vec())
	stay.Name = "Shared"
	local moved = newPart(raceA, vec())
	moved.Name = "Shared"
	progress = 0
	onCheck = function(count)
		if count == 10 then
			moved.Parent = raceB
		end
	end
	local movedSummary = finish(call("dex_summarize_hierarchy", { rootId = registry:Id(raceRoot) }))
	onCheck = nil
	assert(
		movedSummary.duplicateGroupCount == 0
			and movedSummary.coverage.truncated
			and movedSummary.coverage.reparentedObjectsSkipped == 1,
		"reparenting at a queued checkpoint cannot create false duplicates under the old parent"
	)
	moved.Parent = raceA
	progress = 0
	onCheck = function(count)
		if count == 10 then
			moved.Parent = workspace
		end
	end
	local outsideSummary = finish(call("dex_summarize_hierarchy", { rootId = registry:Id(raceRoot) }))
	onCheck = nil
	assert(
		outsideSummary.duplicateGroupCount == 0
			and outsideSummary.coverage.outsideRootSkipped == 1
			and outsideSummary.coverage.truncated,
		"queued objects moved out of the selected subtree are omitted with explicit coverage"
	)
	moved.Parent = raceB
	local outside = newPart(workspace, vec())
	outside.Name = "Same external name"
	local detached = Instance.new("Part")
	detached.Name = "Detached target"
	local function objectValue(name, value)
		local object = Instance.new("ObjectValue", root)
		object.Name = name
		object.Value = value
		return object
	end
	local empty = objectValue("Empty", nil)
	local boundary = objectValue("Boundary", outside)
	local inside = objectValue("Inside", left)
	local unavailable = objectValue("Unavailable", detached)
	local denied = objectValue("Protected", left)
	protected[denied] = { Value = true }
	local model = Instance.new("Model", root)
	model.Name = "Optional primary"
	local weld = Instance.new("WeldConstraint", root)
	weld.Part0 = nil
	weld.Part1 = left
	local billboard = Instance.new("BillboardGui", root)
	billboard.Adornee = outside
	local references = finish(call("dex_validate_references", { rootId = rootId, limit = 100 }))
	local statuses = {}
	for _, row in ipairs(references.links) do
		statuses[row.source.id .. ":" .. row.property] = row
	end
	assert(
		statuses[registry:Id(empty) .. ":Value"].status == "nil"
			and statuses[registry:Id(empty) .. ":Value"].severity == "informational",
		"nil links are candidates, not automatically errors"
	)
	local scoped = statuses[registry:Id(boundary) .. ":Value"]
	assert(
		scoped.status == "outside_root"
			and scoped.target.id == registry:Id(outside)
			and scoped.severity == "informational",
		"external scope boundaries preserve target identity without claiming broken links"
	)
	assert(
		not statuses[registry:Id(inside) .. ":Value"] and references.coverage.insideRoot >= 2,
		"healthy internal links are counted without filling candidates"
	)
	assert(
		statuses[registry:Id(unavailable) .. ":Value"].status == "target_unavailable"
			and statuses[registry:Id(unavailable) .. ":Value"].target.available == false
	)
	assert(
		statuses[registry:Id(denied) .. ":Value"].status == "read_unavailable"
			and statuses[registry:Id(denied) .. ":Value"].error:find("protected fixture property", 1, true)
	)
	assert(
		statuses[registry:Id(model) .. ":PrimaryPart"].severity == "informational"
			and statuses[registry:Id(billboard) .. ":Adornee"].target.id == registry:Id(outside)
	)
	local referenceCap = finish(call("dex_validate_references", { rootId = rootId, limit = 1 }))
	assert(
		#referenceCap.links == 1
			and referenceCap.coverage.truncated
			and referenceCap.coverage.reason == "candidate_limit"
	)
	for index = 1, 50 do
		local key = "Large" .. index
		left:SetAttribute(key, string.rep("x", 500))
		right:SetAttribute(key, string.rep("y", 500))
	end
	local heavy = call("dex_compare_instances", { leftId = lid, rightId = rid, properties = { "Anchored" } })
	assert(
		heavy.coverage.truncated
			and heavy.coverage.reason == "result_byte_limit"
			and heavy.coverage.estimatedBytes <= 48 * 1024,
		"comparison output never exceeds its conservative result budget"
	)
	local attrsLeft = Instance.new("Folder", root)
	local attrsRight = Instance.new("Folder", root)
	for index = 1, 300 do
		attrsLeft:SetAttribute("Bound" .. index, false)
		attrsRight:SetAttribute("Bound" .. index, true)
	end
	local gathered = call("dex_compare_instances", {
		leftId = registry:Id(attrsLeft),
		rightId = registry:Id(attrsRight),
		properties = { "Name" },
		includeTags = false,
	})
	assert(
		gathered.coverage.attributeScanLimitReached
			and gathered.coverage.attributeEntriesExamined <= 258
			and #gathered.attributes <= 128
			and gathered.coverage.attributeNamesOmittedAtLeast >= 1,
		"attribute-name gathering is bounded before sorting/comparing and does not claim exhaustive omission counts"
	)
	local budgetRoot = Instance.new("Folder", root)
	for index = 1, 100 do
		local item = Instance.new("ObjectValue", budgetRoot)
		item.Name = string.rep("n", 250) .. index
		item.Value = outside
	end
	local budget = finish(call("dex_validate_references", { rootId = registry:Id(budgetRoot), limit = 100 }))
	assert(
		budget.coverage.truncated
			and budget.coverage.reason == "result_byte_limit"
			and budget.coverage.estimatedBytes <= 48 * 1024,
		"reference output bounds names and total serialized evidence"
	)
	for _, args in ipairs({
		{ rootId = rootId, maxNodes = 0 },
		{ rootId = rootId, maxNodes = 10001 },
		{
			rootId = rootId,
			topClasses = 51,
		},
	}) do
		local ok, problem = pcall(call, "dex_summarize_hierarchy", args)
		assert(not ok and tostring(problem):find("INVALID_ARGUMENT", 1, true))
	end
	progress = 0
	cancelAfter = 3
	local cancelled = call("dex_summarize_hierarchy", { rootId = rootId })
	assert(cancelled.status == "failed" and cancelled.error:find("CANCELLED", 1, true))
	cancelAfter = nil
	comparison:Destroy()
	local ended = call("dex_validate_references", { rootId = rootId })
	assert(ended.status == "failed" and ended.error:find("CANCELLED", 1, true))
	instMT.__index = originalIndex
	API.Classes.Part = oldPart
	API.Classes.ObjectValue = oldObjectValue
	API.Classes.BillboardGui = oldBillboard
	registry:Destroy()
	root:Destroy()
	outside:Destroy()
	detached:Destroy()
	print(
		"PASS: typed instance comparisons, unavailable-vs-nil/false, bounded class/sibling summaries, scoped reference candidates, limits and cooperative teardown"
	)
end

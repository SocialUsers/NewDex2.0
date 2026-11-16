--!strict

do
	local previousGetService = methods.GetService
	local services = {}
	methods.GetService = function(_, name)
		if not services[name] then
			services[name] = Instance.new(name, game)
			services[name].Name = name
		end
		return services[name]
	end
	API.Classes.ModuleScript = API.Classes.ModuleScript
		or { Name = "ModuleScript", Superclass = API.Classes.Instance, Properties = {}, Tags = {} }
	API.Classes.Script = API.Classes.Script
		or {
			Name = "Script",
			Superclass = API.Classes.Instance,
			Properties = {},
			Tags = {},
		}
	local evidence = Apps.ReconstructorEvidence.Create()
	evidence:Add(
		{ "ServerStorage", "Items", "Sword" },
		{ Source = "fixture", Kind = "conditional class", Class = "ModuleScript" }
	)
	evidence:Add({ "ServerScriptService", "Controllers", "Main" }, { Source = "fixture", Kind = "reference" })
	Explorer.SyncInferredTree(evidence)
	local folderNode = Explorer.InferredNodes[Apps.ReconstructorEvidence.Key({ "ServerStorage", "Items" })]
	local node = Explorer.InferredNodes[Apps.ReconstructorEvidence.Key({ "ServerStorage", "Items", "Sword" })]
	assert(
		node and node.Parent == folderNode and folderNode.Parent.Obj == services.ServerStorage,
		"claims attach under their real service nodes"
	)
	assert(
		node.Obj.ClassName == "ModuleScript" and folderNode.Obj.ClassName == "Folder",
		"typed Instances use class evidence and a Folder fallback"
	)
	assert(
		node.Obj.Name == "Sword"
			and node.Obj.Parent == folderNode.Obj
			and folderNode.Obj.Parent == services.ServerStorage
			and services.ServerStorage:FindFirstChild("Items") == folderNode.Obj,
		"actual client Instances are parented to their real local services"
	)
	assert(
		Explorer.IsInferredObject(node.Obj) and not Apps.History.IsHidden(node.Obj),
		"materialized objects remain visible to normal history reconciliation"
	)
	local count = #folderNode
	local previousUpdate = Explorer.PerformUpdate
	local repaintCount = 0
	Explorer.PerformUpdate = function(...)
		repaintCount += 1
		return previousUpdate(...)
	end
	Explorer.SyncInferredTree(evidence)
	assert(repaintCount == 0, "unchanged inference never rebuilds the main Explorer")
	Explorer.PerformUpdate = previousUpdate
	assert(
		#folderNode == count
			and Explorer.InferredNodes[Apps.ReconstructorEvidence.Key({ "ServerStorage", "Items", "Sword" })] == node,
		"incremental sync preserves node identity and does not duplicate"
	)
	Explorer.Selection:Set(node)
	assert(
		not Explorer.HasInferredSelection() and Explorer.HasReconstructedSelection(),
		"materialized objects use normal Properties and context menus"
	)
	assert(Explorer.CanDrop({ node }, folderNode), "local reconstructed objects support ordinary reparenting")
	Apps.History.Run("Local rename", function()
		Apps.History.Set(node.Obj, "Name", "Local edit")
	end)
	assert(node.Obj.Name == "Local edit")
	assert(Apps.History.Undo() and node.Obj.Name == "Sword", "local edits undo normally")
	assert(node.Obj:GetAttribute("Inferred") == nil, "normal objects carry no fake inference properties")
	local matches, ancestors, expanded = {}, {}, {}
	assert(
		Apps.SearchQuery.Scan({ folderNode }, Apps.SearchQuery.Compile("is:ModuleScript"), ancestors, matches, expanded)
	)
	assert(matches[node], "class filters use the actual materialized class")
	local previousSearch, previousQuery = Explorer.DoSearch, Explorer.Query
	local updates = 0
	Explorer.Query = "Sword"
	Explorer.DoSearch = function(query)
		assert(query == "Sword")
		updates += 1
	end
	evidence:Add({ "ServerStorage", "Items", "Sword2" }, { Source = "fixture", Kind = "reference" })
	Explorer.SyncInferredTree(evidence)
	flushTasks()
	assert(updates >= 1, "background inference refreshes the active query")
	Explorer.DoSearch, Explorer.Query = previousSearch, previousQuery
	Explorer.Selection:SetTable({})
	local controller = Explorer.InferredNodes[Apps.ReconstructorEvidence.Key({ "ServerScriptService", "Controllers" })]
	local entry = Explorer.InferredNodes[Apps.ReconstructorEvidence.Key({ "ServerScriptService", "Controllers", "Main" })]
	local old = controller.Obj
	Explorer.Selection:Set(controller)
	evidence:Add(
		{ "ServerScriptService", "Controllers" },
		{ Source = "upgrade", Kind = "require target", Class = "ModuleScript" }
	)
	evidence:Add(
		{ "ServerScriptService", "Controllers", "Main" },
		{ Source = "upgrade", Kind = "conditional ClassName constraint", Class = "Script" }
	)
	Explorer.SyncInferredTree(evidence)
	assert(
		controller.Obj.ClassName == "ModuleScript" and controller.Obj ~= old and old.Destroyed,
		"new evidence upgrades immutable class without keeping stale handles"
	)
	assert(
		Explorer.Selection.List[1] == controller and entry.Parent == controller and entry.Obj.Parent == controller.Obj,
		"class upgrades preserve selection and child hierarchy"
	)
	assert(
		entry.Obj.ClassName == "Script" and entry.Obj.Disabled == true and entry.Obj.Name == "Main",
		"script placeholders are real named disabled Scripts"
	)
	assert(
		nodes[old] == nil and not Explorer.IsInferredObject(old) and Explorer.IsInferredObject(controller.Obj),
		"replacement updates object indexes"
	)
	assert(
		controller.Obj.Parent == services.ServerScriptService and entry.Obj.Parent == controller.Obj,
		"disabled scripts live in the actual client service hierarchy"
	)
	Explorer.RightClickContext.Registered.VIEW_SCRIPT.OnClick()
	Explorer.RightClickContext.Registered.SAVE_SCRIPT.OnClick()
	Explorer.RightClickContext.Registered.SAVE_BYTECODE.OnClick()
	Explorer.Selection:SetTable({})
	methods.GetService = previousGetService
	print(
		"PASS: real client service hierarchy, stable identity, ordinary local history/editing, disabled scripts and actual class search"
	)
end

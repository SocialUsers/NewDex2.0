--!strict

do
	local provider = deps.env.getnilinstances
	Explorer.ClearSearch()
	local root = Instance.new("Folder")
	root.Name = "NilTestRoot"
	local nested = Instance.new("Folder", root)
	nested.Name = "NestedNil"
	local child = Instance.new("Part", nested)
	child.Name = "NilTestPart"
	local other = Instance.new("Folder")
	other.Name = "NilOther"
	deps.env.getnilinstances = function()
		return { child, root, root, nested, workspace, game, other, "bad", {} }
	end
	Explorer.InitNilInstances()
	local rootNode = nodes[root]
	local nilRoot = rootNode.Parent
	assert(nilRoot.Obj.Name == "Nil Instances" and Explorer.Expanded[nilRoot], "nil root loads and expands at startup")
	assert(nodes[nested].Parent == rootNode and nodes[child].Parent == nodes[nested], "nil subtree retains hierarchy")
	assert(nodes[workspace].Parent == nodes[game], "provider live entries are not moved to nil")
	assert(#nilRoot == 2, "duplicates and descendant entries do not create extra roots")
	Explorer.Selection:Set(nodes[child])
	for i = 1, 3 do
		assert(Explorer.RefreshNilInstances())
	end
	assert(
		nodes[root] == rootNode and Explorer.Selection.List[1] == nodes[child],
		"refresh preserves node identity and selection"
	)
	deps.env.getnilinstances = function()
		return { root, nilRoot.Obj }
	end
	assert(Explorer.RefreshNilInstances() and not nodes[other], "stale roots removed, virtual root never scans itself")
	Explorer.DoSearch("NilTestPart")
	assert(#Explorer.MatchList == 1 and Explorer.MatchList[1] == nodes[child], "nil descendants participate in search")
	-- Provider failure must not discard working nodes.
	deps.env.getnilinstances = function()
		error("provider failed")
	end
	assert(
		not Explorer.RefreshNilInstances() and Explorer.NilError and nodes[root] == rootNode,
		"provider exception preserves current view"
	)
	deps.env.getnilinstances = function()
		return false
	end
	assert(not Explorer.RefreshNilInstances() and nodes[root] == rootNode, "invalid response preserves current view")
	-- Child tracking includes objects moved from the normal tree, not just new nodes.
	Explorer.ClearSearch()
	local moved = Instance.new("Part", workspace)
	moved.Name = "MovedIntoNil"
	Explorer.SyncHistoryObject(moved)
	moved.Parent = root
	root.ChildAdded:Fire(moved)
	assert(nodes[moved].Parent == rootNode, "live object moved into nil retains a valid node")
	local added = Instance.new("Part", nested)
	added.Name = "NewNilChild"
	nested.ChildAdded:Fire(added)
	assert(nodes[added].Parent == nodes[nested], "new descendants are tracked")
	added.Name = "RenamedNilChild"
	added:GetPropertyChangedSignal("Name"):Fire()
	flushTasks()
	assert(nodes[added] and not nodes[added].Del, "nil rename refresh stays valid")
	-- Returning to the game removes nil-only tracking, preserving node identity.
	root.Parent = workspace
	root.AncestryChanged:Fire(root, workspace)
	flushTasks()
	assert(
		nodes[root] == rootNode and rootNode.Parent == nodes[workspace],
		"reparented root moves back to live hierarchy"
	)
	Explorer.HideNilInstances()
	assert(nodes[root] == rootNode and nodes[child], "hiding nil cannot remove live reparented instances")
	-- Successful refresh and Hide refresh search results and prune stale selection.
	root.Parent = nil
	Explorer.SyncHistoryObject(root)
	deps.env.getnilinstances = function()
		return { root }
	end
	assert(Explorer.RefreshNilInstances())
	Explorer.DoSearch("NilTestPart")
	Explorer.Selection:Set(nodes[child])
	Explorer.HideNilInstances()
	assert(
		not nodes[root] and not nodes[child] and #Explorer.MatchList == 0 and #Explorer.Selection.List == 0,
		"hide clears stale search and selection"
	)
	assert(root.Parent == nil and child.Parent == nested, "hide never mutates actual instances")
	Explorer.ClearSearch()
	Explorer.CloseHeaderPopup()
	Explorer.GuiElems.ToolBar.Options.Activated:Fire()
	local panel = Explorer.GuiElems.HeaderPopup
	local refresh = panel.Items:GetChildren()[3]
	assert(refresh:FindFirstChildOfClass("TextLabel").Text == "Refresh Nil Instances", "three-dot menu exposes refresh")
	refresh.Activated:Fire()
	assert(nodes[root] and not panel.Visible, "menu refresh repopulates hidden nil view")
	Explorer.HideNilInstances()
	deps.env.getnilinstances = nil
	assert(not Explorer.RefreshNilInstances() and Explorer.NilError, "unsupported environment returns clear status")
	deps.env.getnilinstances = provider
	Explorer.ForceUpdate()
	flushTasks()
	print(
		"PASS: nil startup, nested hierarchy, deduplication, safe refresh/error handling, search, child/reparent tracking, hide and menu refresh"
	)
end

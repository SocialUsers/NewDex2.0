--!strict

do
	local H = Apps.History
	H.Entries = {}
	H.Index = 0
	local group = Instance.new("Model", workspace)
	group.Name = "DeferredGroup"
	local inner = Instance.new("Model", group)
	inner.Name = "Nested"
	local a = Instance.new("Part", group)
	a.Name = "One"
	local b = Instance.new("Part", inner)
	b.Name = "Two"
	Explorer.SyncHistoryObject(group)
	Explorer.Expanded[nodes[group]] = true
	Explorer.ForceUpdate()
	local menu = Explorer.RightClickContext.Registered
	local function notificationBurst()
		-- Old remove/add notifications delivered after synchronous undo has restored instances.
		game.DescendantRemoving:Fire(group)
		game.DescendantRemoving:Fire(inner)
		game.DescendantRemoving:Fire(a)
		game.DescendantRemoving:Fire(b)
		game.DescendantAdded:Fire(group)
		game.DescendantAdded:Fire(inner)
		game.DescendantAdded:Fire(a)
		game.DescendantAdded:Fire(b)
		game.ItemChanged:Fire(a, "Parent")
		game.ItemChanged:Fire(b, "Parent")
		flushTasks()
		flushTasks()
	end
	local function consistent(obj)
		local node = nodes[obj]
		assert(node and not node.Del, "live object has valid node")
		assert(node.Parent == nodes[obj.Parent], "node parent matches real parent")
		local count = 0
		for _, entry in ipairs(node.Parent) do
			if entry.Obj == obj and not entry.Del then
				count += 1
			end
		end
		assert(count == 1, "no duplicate live entries")
	end
	Explorer.Selection:Set(nodes[group])
	menu.UNGROUP.OnClick()
	assert(group.Parent == nil and a.Parent == workspace and inner.Parent == workspace)
	assert(H.Undo())
	notificationBurst()
	assert(Explorer.Selection.List[1] == nodes[group], "delayed events must not invalidate restored selection node")
	consistent(group)
	consistent(inner)
	consistent(a)
	consistent(b)
	for i = 1, 15 do
		assert(H.Redo())
		notificationBurst()
		assert(group.Parent == nil and not nodes[group], "ungrouped container stays removed after delayed events")
		assert(a.Parent == workspace and inner.Parent == workspace, "children stay ungrouped")
		consistent(a)
		consistent(inner)
		consistent(b)
		assert(H.Undo())
		notificationBurst()
		assert(
			group.Parent == workspace and a.Parent == group and inner.Parent == group and b.Parent == inner,
			"undo restores exact original hierarchy"
		)
		consistent(group)
		consistent(inner)
		consistent(a)
		consistent(b)
	end
	-- A retained deletion must not reappear under Nil Instances.
	Explorer.Selection:Set(nodes[group])
	menu.DELETE.OnClick()
	deps.env.getnilinstances = function()
		return { group, inner, a, b }
	end
	Explorer.RefreshNilInstances()
	notificationBurst()
	assert(
		not nodes[group] and not nodes[inner] and not nodes[a] and not nodes[b],
		"nil refresh hides retained root and descendants"
	)
	assert(H.Undo())
	Explorer.RefreshNilInstances()
	notificationBurst()
	consistent(group)
	consistent(inner)
	consistent(a)
	consistent(b)
	-- Multiple selected nested groups use live child lists and a stable selection snapshot.
	Explorer.Selection:SetTable({ nodes[group], nodes[inner] })
	menu.UNGROUP.OnClick()
	notificationBurst()
	assert(
		group.Parent == nil and inner.Parent == nil and a.Parent == workspace and b.Parent == workspace,
		"nested ungroup moves all children once"
	)
	assert(H.Undo())
	notificationBurst()
	assert(
		group.Parent == workspace and inner.Parent == group and b.Parent == inner and a.Parent == group,
		"nested ungroup undo"
	)
	assert(H.Redo())
	notificationBurst()
	assert(
		a.Parent == workspace and b.Parent == workspace and not nodes[group] and not nodes[inner],
		"nested ungroup redo"
	)
	deps.env.getnilinstances = nil
	print(
		"PASS: delayed ancestry events, valid restored selection, 15 ungroup replay cycles, no duplicate nodes, retained nil-object filtering and nested multi-ungroup"
	)
end

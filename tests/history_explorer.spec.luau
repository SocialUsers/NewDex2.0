--!strict

do
	local previousLib = Apps.Lib
	Apps.Lib = Lib -- The real app registry includes the Window factory, not just apps.
	Apps.UninitializedWindow = { Window = {} }
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector2.new(1090, 790) },
		false
	)
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Touch, Position = Vector2.new(1090, 790) },
		false
	)
	Apps.Lib = previousLib
	Apps.UninitializedWindow = nil
	print("PASS: history hit-testing skips Window factories and uninitialized windows on mouse/touch input")
	local H = Apps.History
	H.Entries = {}
	H.Index = 0
	Explorer.ClearSearch()
	local parent = Instance.new("Folder", workspace)
	parent.Name = "UndoTests"
	local a = Instance.new("Folder", parent)
	a.Name = "A"
	local b = Instance.new("Folder", parent)
	b.Name = "B"
	local child = Instance.new("Part", a)
	child.Name = "Child"
	Explorer.SyncHistoryObject(parent)
	Explorer.Expanded[nodes[parent]] = true
	Explorer.ForceUpdate()
	local menu = Explorer.RightClickContext.Registered
	Explorer.Selection:SetTable({ nodes[a], nodes[child] })
	menu.DELETE.OnClick()
	assert(a.Parent == nil and child.Parent == a and #H.Entries == 1, "delete acts on selected roots as one step")
	assert(
		H.Undo() and a.Parent == parent and child.Parent == a and nodes[a] and nodes[child],
		"delete undo restores actual objects and subtree"
	)
	assert(H.Redo() and a.Parent == nil, "delete redo")
	H.Undo()
	Explorer.Selection:Set(nodes[parent])
	menu.DELETE_CHILDREN.OnClick()
	assert(a.Parent == nil and b.Parent == nil, "delete children")
	assert(H.Undo() and a.Parent == parent and b.Parent == parent, "restore all children in one step")
	Explorer.Selection:Set(nodes[a])
	menu.DUPLICATE.OnClick()
	local clone = Explorer.Selection.List[1].Obj
	assert(clone ~= a and clone.Parent == parent, "duplicate created")
	assert(H.Undo() and clone.Parent == nil, "undo duplicate")
	assert(H.Redo() and clone.Parent == parent, "redo same duplicate")
	Explorer.Selection:SetTable({ nodes[a], nodes[b] })
	menu.GROUP.OnClick()
	local group = Explorer.Selection.List[1].Obj
	assert(a.Parent == group and b.Parent == group, "group")
	assert(
		H.Undo() and a.Parent == parent and b.Parent == parent and group.Parent == nil,
		"undo group restores parentage"
	)
	assert(H.Redo() and group.Parent == parent and a.Parent == group, "redo group")
	Explorer.Selection:Set(nodes[group])
	menu.UNGROUP.OnClick()
	assert(group.Parent == nil and a.Parent == parent, "ungroup")
	assert(H.Undo() and group.Parent == parent and a.Parent == group, "undo ungroup")
	H.Undo() -- Undo group, putting A/B back under parent.
	Explorer.Selection:Set(nodes[b])
	assert(Explorer.DropNodes({ nodes[b] }, nodes[a], "Before"))
	local beforeB = nodes[b].ManualOrder
	local afterA = nodes[a].ManualOrder
	assert(beforeB < afterA, "sibling order")
	assert(H.Undo() and b.Parent == parent, "undo reorder")
	assert(H.Redo() and nodes[b].ManualOrder < nodes[a].ManualOrder, "redo explicit sibling order")
	assert(Explorer.DropNodes({ nodes[b] }, nodes[a], "Inside"))
	assert(b.Parent == a and H.Undo() and b.Parent == parent, "undo cross-parent move")
	assert(nodes[b].ManualOrder < nodes[a].ManualOrder, "undo cross-parent move restores sibling order after reparent")
	assert(H.Redo() and b.Parent == a, "redo cross-parent move")
	Explorer.Selection:Set(nodes[a])
	menu.CUT.OnClick()
	assert(a.Parent == nil and child.Parent == a, "cut retains original subtree for undo")
	assert(H.Undo() and a.Parent == parent, "undo cut")
	Explorer.Selection:Set(nodes[parent])
	menu.PASTE.OnClick()
	local pasted = Explorer.Selection.List[1].Obj
	assert(pasted ~= a and pasted.Parent == parent, "paste creates independent object")
	assert(H.Undo() and pasted.Parent == nil, "undo paste")
	assert(H.Redo() and pasted.Parent == parent, "redo paste restores same pasted instance")
	Explorer.Selection:Set(nodes[parent])
	local insertMenu = Explorer.InsertObjectContext
	if insertMenu then
		for _, item in ipairs(insertMenu.Items) do
			if item.Name == "Folder" and item.OnClick then
				local count = #parent:GetChildren()
				item.OnClick(item.Name)
				assert(#parent:GetChildren() == count + 1, "insert adds object")
				assert(H.Undo() and #parent:GetChildren() == count, "undo insert")
				assert(H.Redo() and #parent:GetChildren() == count + 1, "redo insert")
				break
			end
		end
	end
	H.Set(a, "Name", "Changed")
	service.UserInputService.Focus = nil
	H.Focused = true
	keys.LeftControl = true
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Z },
		false
	)
	assert(a.Name == "A", "Ctrl+Z invokes shared history")
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Y },
		false
	)
	assert(a.Name == "Changed", "Ctrl+Y invokes shared history")
	service.UserInputService.Focus = Instance.new("TextBox")
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Z },
		false
	)
	assert(a.Name == "Changed", "typing fields keep their own undo")
	service.UserInputService.Focus = nil
	keys.LeftControl = false
	print(
		"PASS: real Explorer delete/subtree restore, delete children, duplicate, group/ungroup, sibling ordering, cross-parent moves and Ctrl+Z/Ctrl+Y focus isolation"
	)
end

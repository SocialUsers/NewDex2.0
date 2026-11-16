--!strict

do
	local store = Apps.SelectionService.NewStore()
	local one, two = { Obj = Instance.new("Folder") }, { Obj = Instance.new("Folder") }
	local fired = 0
	local connection = store.Changed:Connect(function()
		fired += 1
	end)
	store:SetTable({ one, one, two })
	assert(#store.List == 2 and fired == 1, "selection is an ordered set")
	store:SetTable({ one, two })
	assert(fired == 1, "unchanged selection does not emit feedback")
	local bridge = Apps.SelectionService.Bind(store, function(object)
		return object == one.Obj and one or object == two.Obj and two
	end)
	bridge:Set({ two.Obj, one.Obj })
	assert(bridge:Get()[1] == two.Obj, "instance selection preserves order")
	local previous = table.clone(store.List)
	assert(
		not pcall(bridge.Set, bridge, { Instance.new("Folder") }) and store.List[1] == previous[1],
		"invalid selection is atomic"
	)
	connection:Disconnect()
	store.Changed:Destroy()
	one.Obj:Destroy()
	two.Obj:Destroy()

	local details = Apps.NodeDetailsPlaceholder.Measure(0, 80)
	assert(details.leftOfName == 41 and details.total == 121, "source node-width formula")
	assert(Apps.NodeDetailsPlaceholder.Measure(3, 80).leftOfName == 77, "source indentation width")
	local view = Apps.SessionView.Create(Instance.new("Frame", game))
	local before = view.Commits
	view:BeginFrame(40)
	assert(view.RootCount == 1 and view.Commits == before + 1, "forty row allocations use one root and one commit")
	for index = 1, 40 do
		local row = view:NewRow(index)
		assert(row.Indent and row.Insert)
	end
	local insert = view:NewRow(1).Insert
	local childCount = #insert:GetChildren()
	Apps.InsertObjectOverlay.Anchor(insert)
	Apps.InsertObjectOverlay.Anchor(insert)
	assert(#insert:GetChildren() == childCount, "opening the insert menu does not duplicate React-owned icons")
	assert(view.Commits == before + 1, "reading mounted rows does not synchronously render each row")
	view:Destroy()

	local menu = Apps.ContextMenu.new()
	menu.MaxHeight = 200
	for index = 1, 1000 do
		menu:Add({ Name = string.format("Item%04d", index) })
	end
	menu:Show(10, 10)
	assert(menu.MountedRows <= 10, "large insertion catalogs mount a bounded page")
	menu.GuiElems.SearchBar.Text = "Item0999"
	menu.GuiElems.SearchBar:GetPropertyChangedSignal("Text"):Fire()
	assert(menu.MountedRows == 1, "menu filtering preserves the whole logical catalog")
	menu:Destroy()
	local grouped = Apps.ContextMenu.new()
	grouped:Add({ Name = "Copy" })
	grouped:AddDivider()
	grouped:Add({ Name = "Paste" })
	grouped:Show(10, 10)
	local divider = grouped.GuiElems.List:FindFirstChild("Divider")
	assert(
		divider and divider.Line.Visible and divider.Line.Size.Y.Offset == 1,
		"right-click groups have a visible separator line"
	)
	assert(
		divider.Size.Y.Offset == 7 and grouped.ContentHeight == 2 * (grouped.Theme.RowHeight or 28) + 7,
		"unlabelled menu dividers use compact spacing"
	)
	grouped:Destroy()
	local base = Apps.ExplorerPolicy.RowState(false, true, false, true, Settings.Theme)
	local hover = Apps.ExplorerPolicy.RowState(false, true, true, true, Settings.Theme)
	assert(
		base.HoverOverlayTransparency == 1 and hover.HoverOverlayTransparency == 0.94,
		"hover remains visible over descendant selection tint"
	)
	assert(
		base.BackgroundColor == Settings.Theme.SelectionContext,
		"descendant tint uses its reference swatch without a second transparency blend"
	)
	local scrollFrame = Instance.new("ScrollingFrame", game)
	scrollFrame.CanvasPosition = Vector2.new(0, 0)
	local vertical = Apps.ScrollingView.New(scrollFrame, false)
	vertical.TotalSpace = 100
	vertical.VisibleSpace = 10
	vertical.Index = 200
	vertical:Update()
	assert(vertical.Index == 90 and scrollFrame.CanvasPosition.Y == 1800, "native canvas clamps to last logical row")
	local scrolled = 0
	vertical.Scrolled:Connect(function()
		scrolled += 1
	end)
	scrollFrame.CanvasPosition = Vector2.new(0, 45)
	scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Fire()
	assert(vertical.Index == 2 and scrolled == 1, "native scrolling maps partial rows without losing the remainder")
	scrollFrame:Destroy()
	print(
		"PASS: selection service atomicity, source geometry, one-root batch allocation and native scrolling contracts"
	)
end

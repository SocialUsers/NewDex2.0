--!strict

do
	local insert = Apps.InsertObjectOverlay
	local owner, other = {}, {}
	assert(insert.IsVisible(owner, nil, true, false), "hover shows insert")
	assert(not insert.IsVisible(owner, nil, false, false), "selection alone does not show insert")
	assert(not insert.IsVisible(owner, nil, true, true), "drag, rename or box selection suppress insert")
	assert(insert.IsVisible(owner, owner, false, true), "open popup keeps its own insert visible")
	assert(not insert.IsVisible(other, owner, true, false), "open popup hides other inserts")
	local parent = Instance.new("Frame", game)
	parent.Position = UDim2.fromOffset(100, 100)
	parent.Size = UDim2.fromOffset(300, 40)
	local view = Apps.SessionView.Create(parent)
	parent.CanvasPosition = Vector2.new(0, 20.35)
	view:SetCanvasIndex(1)
	view:EndFrame()
	assert(view.Layer.Position.Y.Offset == 20, "row layer stays fixed while native scrolling moves text once")
	parent.CanvasPosition = Vector2.new(0, 0)
	view:SetCanvasIndex(0)
	view:EndFrame()
	view:BeginFrame(1)
	local row = view:NewRow(1)
	assert(row.Insert.Size.X.Offset == 20 and row.Insert.StudioIcon.Size.X.Offset == 12, "source insert dimensions")
	local x, y = insert.Anchor(row.Insert)
	assert(
		x == row.Insert.AbsolutePosition.X - 220 and y == row.Insert.AbsolutePosition.Y + 20,
		"240px bottom-right popup anchor"
	)
	local state = {
		position = UDim2.fromOffset(-40, 0),
		size = UDim2.fromOffset(400, 20),
		depth = 24,
		height = 20,
		name = "Workspace",
		labelWidth = 200,
		guideCount = 3,
		expanded = true,
		hasChildren = true,
		BackgroundColor = Settings.Theme.ListSelection,
		BackgroundTransparency = 0,
		TextColor = Settings.Theme.Text,
		insertX = 120,
		insertVisible = true,
		connectedAbove = true,
		connectedBelow = false,
		backgroundX = 40,
		backgroundWidth = 252,
	}
	view:UpdateRow(row, state)
	view:EndFrame()
	assert(row.Position.X.Offset == -40 and row.Indent.EntryName.Text == "Workspace", "row data and horizontal offset")
	assert(row.SelectionTop.Visible and not row.SelectionBottom.Visible, "contiguous selection joins upper edge")
	assert(
		row.Background.Position.X.Offset == 40
			and row.Background.Size.X.Offset == 252
			and row.SelectionTop.Size.X.Offset == 252,
		"highlight and joining strips stay within the inset viewport while text scrolls horizontally"
	)
	assert(
		row.Indent.ZIndex > row.SelectionTop.ZIndex and row.Indent.EntryName.ZIndex > row.SelectionTop.ZIndex,
		"multi-selection joining strips remain below the entire icon/text branch"
	)
	local label = row.Indent.EntryName
	local guide = row.Guides:FindFirstChild("1")
	view:BindNodes({ {} })
	local resizeCommits = view.Commits
	for i = 1, 1000 do
		assert(view:ResizeViewport(1, 400 + i, 300 + i % 80, 40))
	end
	assert(
		view.Commits == resizeCommits and row.Indent.EntryName == label and label.Text == "Workspace",
		"viewport resizing retains text and bypasses React reconciliation"
	)
	assert(
		row.Size.X.Offset == 1400
			and row.Background.Size.X.Offset == 338
			and row.SelectionTop.Size.X.Offset == 338
			and row.SelectionWithin.Size.X.Offset == 333,
		"resize keeps highlight geometry joined and inside the viewport"
	)
	assert(
		row.Insert.Position.X.Offset == 245 and row.Background.Position.X.Offset == 40,
		"resize retains horizontal scroll and insertion bounds"
	)
	assert(not view:ResizeViewport(2, 500, 300, 0), "visible-row count changes request a full semantic paint")
	assert(
		guide:IsA("ImageLabel")
			and guide.Image == Main.GetStudioAsset("native/explorer/indent_guide")
			and guide.Size.X.Offset == 12,
		"indentation uses Studio's original alpha mask at its source tile width"
	)
	state.name = "ReplicatedStorage"
	state.guideCount = 1
	state.connectedAbove = false
	view:UpdateRow(row, state)
	view:EndFrame()
	assert(
		row.Indent.EntryName == label and label.Text == "ReplicatedStorage",
		"viewport slot preserves widget identity"
	)
	assert(row.Guides:FindFirstChild("1") == guide and row.Guides:FindFirstChild("3") == nil, "guide widgets recycle")
	assert(not row.SelectionTop.Visible, "recycled selection corner resets")
	view:BeginFrame(3)
	local a, b, c = {}, {}, {}
	view:BindNodes({ a, b, c })
	local rowA, rowB, rowC = view:NewRow(1), view:NewRow(2), view:NewRow(3)
	view:BindNodes({ b, c, {} })
	view:EndFrame()
	assert(
		view:NewRow(1) == rowB and view:NewRow(2) == rowC and view:NewRow(3) == rowA,
		"scrolling retains visible node widgets and recycles only departing rows"
	)
	view:BindNodes({ a, b, c })
	view:EndFrame()
	assert(view:NewRow(2) == rowB and view:NewRow(3) == rowC, "reverse scrolling retains node widgets too")
	view:Destroy()
	parent:Destroy()
	print("PASS: React row recycling, joined selection, horizontal scroll and source insert geometry/visibility")
end

do
	local frame = Instance.new("ScrollingFrame", game)
	frame.Size = UDim2.fromOffset(300, 200)
	frame.CanvasSize = UDim2.fromOffset(300, 2000)
	frame.CanvasPosition = Vector2.new(0, 300)
	local scroll = Apps.ScrollingView.New(frame, false)
	scroll.VisibleSpace = 10
	frame.InputChanged:Fire({
		UserInputType = Enum.UserInputType.MouseWheel,
		Position = { Z = -1 },
		IsModifierKeyDown = function()
			return true
		end,
	})
	assert(frame.CanvasPosition.Y == 497, "modified wheel adds a source page less native scroll increment")
	frame.InputChanged:Fire({
		UserInputType = Enum.UserInputType.MouseWheel,
		Position = { Z = -1 },
		IsModifierKeyDown = function()
			return false
		end,
	})
	assert(frame.CanvasPosition.Y == 497, "ordinary wheel remains engine-controlled")
	frame.CanvasPosition = Vector2.new(0, 1790)
	frame.InputChanged:Fire({
		UserInputType = Enum.UserInputType.MouseWheel,
		Position = { Z = -1 },
		IsModifierKeyDown = function()
			return true
		end,
	})
	assert(frame.CanvasPosition.Y == 1800, "page wheel clamps to native canvas bounds")
	frame:Destroy()
end

do
	local frame = Instance.new("ScrollingFrame", game)
	frame.Size = UDim2.fromOffset(300, 100)
	frame.CanvasSize = UDim2.fromOffset(300, 2000)
	local scroll = Apps.ScrollingView.New(frame, false)
	scroll.TotalSpace = 100
	scroll.VisibleSpace = 5
	scroll.Index = 10
	frame.CanvasPosition = Vector2.new(0, 207.75)
	scroll:Update()
	assert(
		frame.CanvasPosition.Y == 207.75,
		"viewport updates preserve fractional native scroll within the current row"
	)
	scroll.Index = 11
	scroll:Update()
	assert(frame.CanvasPosition.Y == 220, "explicit index changes still scroll to the requested row")
	frame:Destroy()
end

do
	local parent = Instance.new("Frame")
	parent.Size = UDim2.fromOffset(400, 300)
	local frame = Instance.new("ScrollingFrame", parent)
	frame.Size = UDim2.fromOffset(200, 160)
	frame.Position = UDim2.fromOffset(10, 20)
	frame.CanvasSize = UDim2.fromOffset(400, 500)
	frame.ScrollBarThickness = 6
	local active, blocked = true, false
	local borders = Apps.ScrollingView.AttachHoverBorders(frame, {
		IsActive = function()
			return active
		end,
		IsBlocked = function()
			return blocked
		end,
	})
	local p = frame.AbsolutePosition
	borders.Update(p.X + 198, p.Y + 50)
	assert(
		borders.Vertical.Visible and not borders.Horizontal.Visible,
		"vertical track hover shows only vertical divider"
	)
	assert(
		borders.Vertical.Size.X.Offset == 1
			and borders.Vertical.Position.X.Offset == -8
			and borders.Vertical.AnchorPoint.X == 0.5,
		"source one-pixel geometry and padding"
	)
	assert(borders.Vertical.BackgroundTransparency == 0.88, "source dark input-fill transparency")
	borders.Update(p.X + 50, p.Y + 158)
	assert(borders.Horizontal.Visible and not borders.Vertical.Visible, "horizontal track hover")
	borders.Update(p.X + 50, p.Y + 50)
	assert(not borders.Vertical.Visible and not borders.Horizontal.Visible, "content has no scrollbar divider")
	frame.DraggingScrollBar = Enum.DraggingScrollBar.Vertical
	borders.Update(p.X - 40, p.Y - 40)
	assert(borders.Vertical.Visible, "native thumb drag retains divider outside viewport")
	frame.DraggingScrollBar = Enum.DraggingScrollBar.None
	borders.Update()
	assert(not borders.Vertical.Visible, "release outside clears divider")
	blocked = true
	borders.Update(p.X + 198, p.Y + 50)
	assert(not borders.Vertical.Visible, "blocked hover stays hidden")
	blocked = false
	active = false
	borders.Update()
	assert(not borders.Vertical.Visible, "inactive window has no hover divider")
	active = true
	frame.CanvasSize = UDim2.fromOffset(0, 0)
	borders.Update()
	assert(not borders.Vertical.Visible and not borders.Horizontal.Visible, "no overflow has no divider")
	frame:Destroy()
	parent:Destroy()
	print(
		"PASS: source scrollbar hover border geometry, axes, exit, native drag retention, blockers, inactive window and overflow"
	)
end

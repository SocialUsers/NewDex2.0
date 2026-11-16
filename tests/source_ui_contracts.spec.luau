--!strict

-- Expected values come from the fingerprinted recovered files in fixtures/.
do
	local c = sourceUIContracts
	local parent = Instance.new("Frame", game)
	parent.Size = UDim2.fromOffset(320, 80)
	local view = Apps.SessionView.Create(parent)
	local bar = Apps.SearchBar.Create(view, parent)
	assert(parent.SearchFrame.Size.Y.Offset == c.searchBarHeight, "source search bar height")
	assert(parent.SearchFrame.Corner.CornerRadius.Offset == c.searchCorner, "source search corner radius")
	assert(parent.SearchFrame.Stroke.Thickness == c.searchFocusWidth, "source search focus width")
	assert(bar.Options.Size.X.Offset == c.searchBarHeight, "source settings button is square")
	assert(
		bar.SearchBox.BorderSizePixel == 0 and bar.SearchBox.ClipsDescendants,
		"source input clips text without native border"
	)
	assert(bar.SearchBox.ShouldEmitUpAndDownArrowEvents, "source search field emits arrow keys for dropdown navigation")
	assert(
		bar.History.Size.X.Offset == 16 and bar.SearchBox.Position.X.Offset == 5,
		"source inner icon sizing and side padding"
	)
	bar.SearchBox.Text = "something"
	bar.SearchBox:GetPropertyChangedSignal("Text"):Fire()
	assert(
		parent.SearchFrame.Reset.Size.X.Offset == 16 and bar.SearchBox.Size.X.Offset == -52,
		"clear/history controls reserve source spacing"
	)
	assert(parent.BottomBorder.Size.Y.Offset == 1, "source header bottom separator")
	local button = Apps.SearchBrowserButton.Create(view, parent, "Next", UDim2.fromOffset(0, 30))
	assert(
		button.Size.X.Offset == c.searchBrowserHeight and button.Size.Y.Offset == c.searchBrowserHeight,
		"source result navigation dimensions"
	)
	button.MouseEnter:Fire()
	assert(button.BackgroundTransparency == 0.92, "source result navigation hover")
	button.MouseLeave:Fire()
	assert(button.BackgroundTransparency == 1, "result navigation hover resets")
	local rename = Apps.RenameBox.Create(view, parent)
	assert(
		rename.Border.Thickness == c.renameStroke and rename.Corner.CornerRadius.Offset == c.renameCorner,
		"source rename outline geometry"
	)
	assert(rename.ClipsDescendants, "source rename field clips long text")
	assert(#Apps.ExplorerPolicy.FormatName(string.rep("a", 200)) == c.renameLimit, "source rename maximum length")
	assert(Apps.ExplorerPolicy.FormatName("One\nTwo\r") == "One Two", "source rename newline sanitization")
	local box = Apps.BoxSelectIndicator.Create(view)
	local glow = Apps.GradualEdgeScroll.Create(view)
	local edge = view.Layer.GradualEdgeScroll
	glow.Update(4, 2, 300, 80, -1, 0)
	assert(
		edge.Visible and edge.Position.Y.Offset == 2 and edge.Size.Y.Offset == 7 and edge.Fade.Rotation == 90,
		"edge feedback starts at seven pixels at the top"
	)
	glow.Update(4, 2, 300, 80, 1, 0)
	assert(edge.Size.Y.Offset == 7, "changing scroll direction restarts edge feedback")
	glow.Update(4, 2, 300, 80, 1, 3)
	assert(
		edge.Size.Y.Offset == 20 and edge.Position.Y.Offset == 62 and edge.Fade.Rotation == -90,
		"edge feedback grows and anchors at the bottom"
	)
	glow.Update(0, 0, 0, 0, 0, 0)
	assert(not edge.Visible, "feedback hides away from a scrolling edge")
	glow.Destroy()
	assert(not view.Layer:FindFirstChild("GradualEdgeScroll"), "gesture teardown removes edge feedback")
	assert(
		box.BackgroundTransparency == c.boxTransparency and box.SelectionOutline.Thickness == c.boxStroke,
		"source selection rectangle fill and stroke"
	)
	local savedHistory = Explorer.SearchHistory
	Explorer.SearchHistory = { "is:Part", "is:Folder" }
	Explorer.GuiElems.SearchBar:CaptureFocus()
	Explorer.GuiElems.ToolBar.SearchFrame.History.Activated:Fire()
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
		false
	)
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Return },
		false
	)
	assert(Explorer.Query == "is:Part", "history dropdown supports keyboard selection and Enter activation")
	Explorer.SelectMatches(true)
	assert(#Explorer.Selection.List == #Explorer.MatchList, "search select-all toggle selects every match")
	Explorer.SelectMatches(true)
	assert(#Explorer.Selection.List == 0, "search select-all toggle clears all selected matches")
	Explorer.SearchHistory = savedHistory
	Explorer.ClearSearch()
	Explorer.GuiElems.SearchBar:ReleaseFocus()
	local emptyMenu = Apps.ContextMenu.new()
	emptyMenu:Show(10, 10)
	assert(emptyMenu.GuiElems.Main.Size.Y.Offset >= 34, "empty catalogs leave room for the no-results message")
	emptyMenu:Destroy()
	Main.SecureGui = Main.SecureGui or function(gui)
		gui.Parent = game
	end
	local first = Instance.new("TextButton", parent)
	local secondButton = Instance.new("TextButton", parent)
	Apps.TooltipActions.Bind(first, "First tooltip", view)
	Apps.TooltipActions.Bind(secondButton, "Second tooltip", view)
	Main.Mouse.X = 1098
	Main.Mouse.Y = 799
	first.MouseEnter:Fire()
	flushTasks()
	first.MouseLeave:Fire()
	secondButton.MouseEnter:Fire()
	flushTasks()
	local shown = {}
	for _, gui in ipairs(game:GetChildren()) do
		if gui.Name:match("^ExplorerTooltip") and gui:FindFirstChild("Tooltip") then
			shown[#shown + 1] = gui.Tooltip
		end
	end
	assert(#shown == 1 and shown[1].Text == "Second tooltip", "tooltip portals never reuse another widget's content")
	local tip = shown[1]
	assert(
		tip.Font == Enum.Font.SourceSans and tip.TextSize == 17,
		"installed Explorer PluginStyles uses blur-fixed SourceSans 17"
	)
	assert(
		tip.BackgroundColor3.R == 242 / 255
			and tip.BackgroundColor3.G == 242 / 255
			and tip.BackgroundColor3.B == 243 / 255,
		"Studio dark tooltip uses the exact inverse surface token"
	)
	assert(
		tip.TextColor3.R == 17 / 255 and tip.TextColor3.G == 18 / 255 and tip.TextColor3.B == 22 / 255,
		"Studio inverse content token"
	)
	assert(
		tip.BorderSizePixel == 2
			and tip.BorderMode == Enum.BorderMode.Inset
			and not tip:FindFirstChildOfClass("UICorner"),
		"Studio tooltip uses square edges and two-pixel inset border"
	)
	assert(
		tip.Padding.PaddingLeft.Offset == 6
			and tip.Padding.PaddingTop.Offset == 4
			and tip.TextXAlignment == Enum.TextXAlignment.Left,
		"Studio tooltip padding and alignment"
	)
	assert(
		tip.Size.X.Offset == #"Second tooltip" * 7 + 18 and tip.Size.Y.Offset == 28,
		"tooltip fits measured content plus shipped panel padding/allowance"
	)
	assert(
		Apps.TooltipActions.Style.ShowDelay == 0.4 and Apps.TooltipActions.Style.HideDelay == 0.3,
		"installed show delay override and shipped hide delay"
	)
	local oldTheme = Settings.Theme.IconTheme
	Settings.Theme.IconTheme = "Light"
	Lib.StudioTooltip(secondButton, "Updated shared tooltip")
	secondButton.MouseEnter:Fire()
	flushTasks()
	assert(
		tip.Parent.Tooltip.Text == "Updated shared tooltip" and tip.Parent.Tooltip.BackgroundColor3.R == 43 / 255,
		"legacy bindings share the same tooltip and update content/theme without duplicate listeners"
	)
	service.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel })
	assert(not tip.Parent.Enabled, "scrolling dismisses tooltip rather than leaving stale row text")
	Settings.Theme.IconTheme = oldTheme
	secondButton.MouseEnter:Fire()
	service.UserInputService.InputBegan:Fire({
		UserInputType = Enum.UserInputType.MouseButton1,
		Position = Vector2.new(-100, -100),
	})
	flushTasks()
	assert(not tip.Parent.Enabled, "click cancels a pending tooltip show")

	assert(
		shown[1].Position.X.Offset + shown[1].Size.X.Offset <= Main.Mouse.ViewSizeX,
		"tooltip fits horizontal viewport"
	)
	assert(
		shown[1].Position.Y.Offset + shown[1].Size.Y.Offset <= Main.Mouse.ViewSizeY,
		"tooltip fits vertical viewport"
	)
	first.Destroying:Fire()
	secondButton.Destroying:Fire()
	flushTasks()
	view:Destroy()
	view:Destroy()
	parent:Destroy()
	Main.Mouse.X = -100
	Main.Mouse.Y = -100
	local savedSelection = table.clone(Explorer.Selection.List)
	local history = Apps.History
	local savedEntries, savedIndex, savedFocused = table.clone(history.Entries), history.Index, history.Focused
	local fixture = Instance.new("Folder", workspace)
	fixture.Name = "RenameAudit"
	local firstObject = Instance.new("Folder", fixture)
	firstObject.Name = "AAA"
	local secondObject = Instance.new("Folder", fixture)
	secondObject.Name = "ZZZ"
	Explorer.SyncHistoryObject(fixture)
	Explorer.SyncHistoryObject(firstObject)
	Explorer.SyncHistoryObject(secondObject)
	Explorer.Expanded[nodes[workspace]] = true
	Explorer.Expanded[nodes[fixture]] = true
	Explorer.ForceUpdate()
	Explorer.Selection:Set(nodes[firstObject])
	Explorer.SetRenamingNode(nodes[firstObject])
	local field = Explorer.TreeRenderer.Layer.RenameBox
	field.Text = "One\nTwo\r"
	field:GetPropertyChangedSignal("Text"):Fire()
	assert(field.Text == "One Two", "real rename controller sanitizes pasted text")
	field.Text = "Moved\t"
	field:GetPropertyChangedSignal("Text"):Fire()
	assert(
		firstObject.Name == "Moved" and Explorer.Selection.List[1].Obj == secondObject,
		"Tab commits and advances to the next visible instance"
	)
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Up },
		false
	)
	assert(
		Explorer.Selection.List[1].Obj == firstObject and service.UserInputService:GetFocusedTextBox() == field,
		"Up returns to the preceding instance while preserving rename focus"
	)
	Explorer.CancelRename()
	fixture:Destroy()
	Explorer.SyncHistoryObject(fixture)
	Explorer.Selection:SetTable(savedSelection)
	Explorer.ForceUpdate()
	history.Entries, history.Index, history.Focused = savedEntries, savedIndex, savedFocused
	local frame = Explorer.GuiElems.TreeFrame
	local oldCanvas = frame.CanvasPosition
	frame.CanvasPosition = Vector2.new(0, 45)
	frame:GetPropertyChangedSignal("CanvasPosition"):Fire()
	local origin, size = frame.AbsolutePosition, frame.AbsoluteSize
	Explorer.StartBoxSelect({ Position = Vector2.new(origin.X + 1, origin.Y + 50) })
	assert(Explorer.BoxSelecting, "scrolled blank space begins box selection")
	service.UserInputService.InputChanged:Fire({
		UserInputType = Enum.UserInputType.MouseMovement,
		Position = Vector2.new(origin.X + size.X - 2, origin.Y),
	})
	local rectangle = Explorer.TreeRenderer.Layer.SelectionBox
	assert(rectangle.Position.Y.Offset == 5, "box selection preserves the native canvas's fractional row offset")
	service.UserInputService.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
	frame.CanvasPosition = oldCanvas
	frame:GetPropertyChangedSignal("CanvasPosition"):Fire()
	Explorer.Selection:SetTable(savedSelection)
	Explorer.ForceUpdate()
	flushTasks()
	print("PASS: fingerprinted Studio UI contracts, rename normalization, tooltip isolation and idempotent teardown")
end

--!strict

do
	local viewer = Apps.ScriptViewer
	local previous = viewer.ActiveDocument
	local doc = viewer.OpenDocument({}, "GlobalSearchAudit", "local globalSearchNeedle = 1\nprint(globalSearchNeedle)")
	viewer.OpenFind(false)
	viewer.FindWidget.Find.Text = "globalSearchNeedle"
	keys.LeftControl, keys.LeftShift = true, true
	service.UserInputService.InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.H })
	keys.LeftControl, keys.LeftShift = false, false
	local widget, session = viewer.GlobalSearchWidget, viewer.GlobalSearch
	assert(
		widget.Find.Text == "globalSearchNeedle" and service.UserInputService:GetFocusedTextBox() == widget.Find,
		"promoting inline Find carries its query and focuses Find in Place"
	)
	for _, control in ipairs(widget.Frame:GetDescendants()) do
		if control:IsA("TextButton") and control:GetAttribute("SelectedHoverTransparency") then
			control.MouseEnter:Fire()
			assert(control.BackgroundTransparency == 0.85, "source toggle hover opacity")
			control.MouseLeave:Fire()
			assert(
				control.BackgroundTransparency == control:GetAttribute("SelectionTransparency"),
				"toggle hover restores input opacity"
			)
		end
	end
	assert(
		widget.Visible and widget.Frame.Visible and widget.Replace.Visible,
		"Replace All opens the separate window and its replacement input"
	)
	assert(widget.Frame.Parent == viewer.FindInPlaceWindow.GuiElems.Content, "search mounts inside its own window")
	widget.Find.Text = "globalSearchNeedle"
	session:Start("globalSearchNeedle", { Scope = "Open", MatchCase = true })
	local state = session.State
	assert(
		not state.Searching and state.MatchCount == 2 and #state.Groups == 1,
		"all-script search includes current unsaved buffers"
	)
	local group = state.Groups[1]
	local header
	for _, child in ipairs(widget.List:GetChildren()) do
		if child:IsA("TextButton") and child.Visible and child.Position.Y.Offset == 0 then
			header = child
			break
		end
	end
	assert(header, "result group header renders")
	header.MouseButton1Click:Fire()
	assert(widget.List.CanvasSize.Y.Offset == 24, "collapsed group hides the matches")
	service.UserInputService.InputBegan:Fire({
		UserInputType = Enum.UserInputType.Keyboard,
		KeyCode = Enum.KeyCode.Down,
	})
	assert(
		widget.List.CanvasSize.Y.Offset == 72 and viewer.CodeFrame.SearchActiveIndex == 1,
		"keyboard navigation expands a collapsed file and selects its first match"
	)
	viewer.CodeFrame.Editable = false
	local readOnlyText = viewer.CodeFrame:GetText()
	local denied = session:ReplaceAll("deniedReplacement")
	assert(
		denied.Error and viewer.CodeFrame:GetText() == readOnlyText,
		"global replacement respects the editor read-only guard"
	)
	viewer.CodeFrame.Editable = true
	local found
	for _, child in ipairs(widget.List:GetChildren()) do
		if child:IsA("TextButton") and child.Visible then
			for _, text in ipairs(child:GetChildren()) do
				if text:IsA("TextLabel") and text.Text:find("globalSearchNeedle", 1, true) then
					child.MouseButton1Click:Fire()
					found = true
					break
				end
			end
			if found then
				break
			end
		end
	end
	assert(
		found and viewer.CodeFrame.SearchVisible and #viewer.CodeFrame.SearchMatches == 2,
		"virtual result click paints actual find decorations"
	)
	local selected = viewer.GetSelectionState()
	assert(
		viewer.CodeFrame:GetText():sub(selected.First, selected.Last - 1) == "globalSearchNeedle",
		"result navigation selects the exact byte range"
	)
	assert(
		service.UserInputService:GetFocusedTextBox() == widget.Find,
		"mouse selection leaves result navigation available"
	)
	service.UserInputService.InputBegan:Fire({
		UserInputType = Enum.UserInputType.Keyboard,
		KeyCode = Enum.KeyCode.Down,
	})
	assert(viewer.CodeFrame.SearchActiveIndex == 2, "arrow keys continue from a mouse-selected result")
	local result = session:ReplaceAll("renamedGlobalNeedle")
	assert(
		not result.Error and result.Count == 2 and viewer.CodeFrame:GetText():find("renamedGlobalNeedle", 1, true),
		"replacement updates real editor buffers"
	)
	viewer.Undo(false)
	assert(
		viewer.CodeFrame:GetText():find("globalSearchNeedle", 1, true),
		"cross-script replacement preserves per-document Undo"
	)
	session:Start("globalSearchNeedle", { Scope = "Open" })
	local replaceAll
	local confirmation = widget.Frame:FindFirstChild("ReplaceAllConfirmation")
	local yes
	for _, item in ipairs(widget.Frame:GetDescendants()) do
		if item:IsA("TextButton") then
			if item.Text == "Replace All" then
				replaceAll = item
			elseif item.Text == "Yes" and item.Parent == confirmation then
				yes = item
			end
		end
	end
	assert(replaceAll and yes)
	widget.Replace.Text = "mustNotReplace"
	replaceAll.MouseButton1Click:Fire()
	assert(confirmation.Visible, "a fresh search allows confirmation")
	widget.Find.Text = "draftQuery"
	widget.Find:GetPropertyChangedSignal("Text"):Fire()
	assert(not confirmation.Visible and replaceAll.Interactable == false, "editing the query invalidates confirmation")
	yes.MouseButton1Click:Fire()
	assert(
		viewer.CodeFrame:GetText():find("globalSearchNeedle", 1, true),
		"stale confirmation must not change the buffer"
	)
	widget.Find.Text = "globalSearchNeedle"
	session:Start("globalSearchNeedle", { Scope = "Open" })
	replaceAll.MouseButton1Click:Fire()
	widget.Filter.Text = "draftPath"
	widget.Filter:GetPropertyChangedSignal("Text"):Fire()
	assert(not confirmation.Visible and replaceAll.Interactable == false, "editing the path invalidates confirmation")
	yes.MouseButton1Click:Fire()
	assert(viewer.CodeFrame:GetText():find("globalSearchNeedle", 1, true), "old path results cannot be replaced")
	widget.Filter.Text = ""
	session:Start("globalSearchNeedle", { Scope = "Open" })
	local many = {}
	for i = 1, 20000 do
		many[i] =
			{ Start = 7, Finish = 25, Line = i, Column = 7, SnippetColumn = 7, Text = "local globalSearchNeedle = 1" }
	end
	local progress = {
		Groups = { { Name = "LargeScript", Path = "Workspace.LargeScript", Matches = many } },
		MatchCount = 20000,
		Searching = true,
	}
	widget:Update(progress)
	local rebuilds = widget.RenderStats.FlatRebuilds
	for i = 1, 200 do
		progress.Scanned = i
		widget:Update(progress)
	end
	assert(widget.RenderStats.FlatRebuilds == rebuilds, "progress notifications do not rebuild 20,000 result records")
	assert(widget.RenderStats.RowWidgets < 30, "result tree retains only viewport-sized widget pool")
	widget.List.CanvasPosition = Vector2.new(0, 19990 * 24)
	assert(widget.RenderStats.RowWidgets < 30, "scrolling to the end reuses the same bounded row pool")
	widget:Update(session.State)
	widget.Find.Text = "missingGlobalNeedle"
	widget.Find.FocusLost:Fire(true)
	assert(
		session.State.Query == "missingGlobalNeedle" and service.UserInputService:GetFocusedTextBox() == widget.Find,
		"Enter starts an edited query and retains search focus"
	)
	widget:Close()
	assert(
		not widget.Frame.Visible
			and not viewer.CodeFrame.SearchVisible
			and service.UserInputService:GetFocusedTextBox() ~= widget.Find,
		"closing the panel releases space and match decorations"
	)
	viewer.SelectDocument(previous)
	viewer.CloseDocument(doc)
	print(
		"PASS: standalone Find in Place, unsaved document coverage, virtual navigation, exact selections, buffer replacement, undo and close cleanup"
	)
end

--!strict

do
	local editor = Apps.ScriptViewer
	local cf = editor.CodeFrame
	editor.OpenDocument("find-widget-integration", "Find widget", "cat12 Cat34 cat56\ncat12")
	local lines = cf.GuiElems.LinesFrame or cf.Frame
	local input = service.UserInputService
	local oldMouse, oldCursor = Main.Mouse, Lib.Window.SetTextCursor
	local cursor
	Main.Mouse = table.clone(oldMouse)
	Lib.Window.SetTextCursor = function(owner, enabled)
		assert(owner == lines)
		cursor = enabled
	end
	local movement = { UserInputType = Enum.UserInputType.MouseMovement }
	Main.Mouse.X = lines.AbsolutePosition.X + 4
	Main.Mouse.Y = lines.AbsolutePosition.Y + 4
	input.InputChanged:Fire(movement)
	assert(cursor == true, "code area owns the editor I-beam")
	editor.NewDocument()
	local newScript = editor.NewScriptDialog
	newScript.Gui:GetPropertyChangedSignal("Visible"):Fire()
	assert(cursor == false, "opening New Script clears the cursor even without pointer movement")
	input.InputChanged:Fire(movement)
	assert(cursor == false, "the modal excludes the entire editor surface")
	newScript:Hide()
	newScript.Gui:GetPropertyChangedSignal("Visible"):Fire()
	assert(cursor == true, "closing New Script restores the cursor over the code")
	assert(editor.OpenEditorContextMenu(nil, nil, true))
	assert(cursor == false, "opening the editor menu from the keyboard clears the cursor")
	editor.CloseEditorContextMenu()
	assert(cursor == true, "closing the editor menu recalculates the stationary pointer")
	editor.OpenFind(false)
	local view = editor.FindWidget
	local left = Main.Mouse.X
	Main.Mouse.X = math.max(lines.AbsolutePosition.X + 1, view.Gui.AbsolutePosition.X + 1)
	Main.Mouse.Y = math.max(lines.AbsolutePosition.Y + 1, view.Gui.AbsolutePosition.Y + 1)
	assert(Apps.EditorHitTest.Contains(lines, Main.Mouse.X, Main.Mouse.Y))
	assert(Apps.EditorHitTest.Contains(view.Gui, Main.Mouse.X, Main.Mouse.Y))
	view.Gui:GetPropertyChangedSignal("Visible"):Fire()
	assert(cursor == false, "Find overlay blocks the custom code cursor")
	Main.Mouse.X = left
	input.InputChanged:Fire(movement)
	assert(cursor == true, "code beside Find still shows the I-beam")
	Main.Mouse, Lib.Window.SetTextCursor = oldMouse, oldCursor
	assert(view.Find.MultiLine == false and view.Replace.MultiLine == false, "search fields are single-line")
	view.Replace.Text = "replacement"
	local originalSource = cf:GetText()
	view.Replace.FocusLost:Fire(true)
	assert(cf:GetText() == originalSource, "Enter in replacement field does not replace source")
	assert(
		view.Gui.Size.Y.Offset == 51 and view.Find.PlaceholderText == "Find...",
		"native collapsed widget has query and matching rows"
	)
	assert(
		view.Find.Position.X.Offset == 24 and view.Find.Position.Y.Offset == 4 and view.Find.Size.Y.Offset == 20,
		"native input margins and height"
	)
	assert(
		view.Buttons.FindPrevious.Size.X.Offset == 18 and view.Buttons.FindPrevious.Size.Y.Offset == 18,
		"native buttons have fixed 18 pixel bounds"
	)
	assert(
		view.Buttons.FindPrevious.Position.X.Offset == -62
			and view.Buttons.FindNext.Position.X.Offset == -42
			and view.Buttons.CloseDialog.Position.X.Offset == -22
			and view.Buttons.FindPrevious.Position.Y.Offset == 4,
		"native navigation grid keeps two pixel gaps and four pixel outer spacer"
	)
	assert(
		view.Gui.BottomBorder.Size.Y.Offset == 4 and view.Gui.BottomBorder.Position.Y.Offset == -4,
		"native footer frame has fixed four pixel height"
	)
	assert(
		view.Results.Position.X.Offset == 84,
		"results follow three eighteen pixel controls with two pixel grid spacing"
	)
	assert(
		view.Buttons.MatchRegularExpression.Position.X.Offset == 64
			and view.Buttons.MatchRegularExpression.Position.Y.Offset == 26,
		"regex is alongside case/word controls"
	)
	assert(
		view.Buttons.MatchRegularExpression.NativeIcon.Image == "mockasset://native/editor/regex",
		"regex uses original packaged Studio icon"
	)
	assert(
		view.Gui.BackgroundColor3.R == 25 / 255
			and view.Find.BackgroundColor3.R == 37 / 255
			and view.Find.BorderSizePixel == 1
			and view.Find.Font == Lib.StudioFont
			and view.Find.TextSize == 12,
		"the compact Find palette and typography are restored"
	)
	view.Find.Text = "cat"
	editor.RefreshFind(true)
	assert(
		#cf.SearchMatches == 4 and view.Results.Text == "  1 of 4 matches" and cf.SearchVisible,
		"inline results and source decorations update together"
	)
	view.Find:CaptureFocus()
	local sync = cf.SetCopyableSelection
	local synced = 0
	cf.SetCopyableSelection = function(self, ...)
		synced += 1
		return sync(self, ...)
	end
	cf:MoveCursor(0, 0)
	editor.RefreshFind(true)
	assert(
		synced == 0 and service.UserInputService:GetFocusedTextBox() == view.Find,
		"incremental search never touches the editor clipboard textbox or steals query focus"
	)
	cf.SetCopyableSelection = sync
	editor.FindNext()
	assert(view.Results.Text == "  2 of 4 matches", "next match advances the active result")
	view.Replace:CaptureFocus()
	view.Replace.FocusLost:Fire(true)
	assert(
		view.Results.Text == "  3 of 4 matches" and service.UserInputService:GetFocusedTextBox() == view.Replace,
		"Enter in Replace advances matches and retains focus"
	)
	view.Buttons.MatchCase.MouseButton1Click:Fire()
	assert(#cf.SearchMatches == 3 and view.Options.MatchCase, "case toggle recomputes matches immediately")
	assert(view.Buttons.MatchCase.BorderSizePixel == 1, "checked native buttons have a one pixel border")
	view.Buttons.MatchWholeWord.MouseButton1Click:Fire()
	assert(
		#cf.SearchMatches == 0 and view.Results.Text == "  0 matches",
		"whole-word mode excludes identifier fragments"
	)
	view.Buttons.MatchWholeWord.MouseButton1Click:Fire()
	view.Buttons.MatchRegularExpression.MouseButton1Click:Fire()
	view.Find.Text = "cat(\\d+)"
	editor.RefreshFind(true)
	assert(
		#cf.SearchMatches == 3 and not view.Results.Text:find("Invalid", 1, true),
		"real regex results reach the live widget"
	)
	editor.OpenFind(true)
	assert(
		view.Gui.Size.Y.Offset == 73
			and view.Replace.Visible
			and view.Replace.Position.Y.Offset == 26
			and view.Results.Position.Y.Offset == 48,
		"replace row expands and moves the option row"
	)
	view.Find.Text = "cat(\\d+)"
	view.Replace.Text = "<$1>"
	editor.RefreshFind(true)
	assert(
		editor.Replace(true) and cf:GetText() == "<12> Cat34 <56>\n<12>",
		"regex captures replace atomically through the editor"
	)
	editor.Undo(false)
	assert(cf:GetText() == "cat12 Cat34 cat56\ncat12", "one undo restores the full replacement")
	view.Find.Text = "("
	editor.RefreshFind(true)
	assert(
		view.Results.Text == "Invalid expression"
			and not view.Buttons.ReplaceAll.Interactable
			and #cf.SearchMatches == 0,
		"invalid regex cannot run replacement or leave stale spans"
	)
	view.Find.Text = ""
	editor.RefreshFind(true)
	assert(view.Results.Text == "" and not cf.SearchVisible, "empty queries clear all decorations")
	editor.SetRegex(false)
	editor.SetMatchCase(false)
	view.Find.Text = "cat"
	editor.RefreshFind(true)
	cf.Editable = false
	editor.RefreshFind(false)
	assert(
		view.Buttons.FindNext.Interactable
			and not view.Buttons.ReplaceNext.Interactable
			and not view.Buttons.ReplaceAll.Interactable,
		"read-only find keeps navigation enabled and disables replacement"
	)
	local source = cf:GetText()
	assert(not editor.Replace(true) and cf:GetText() == source, "find replacement honors read-only documents")
	cf.Editable = true
	editor.OpenDocument("find-replace-caret", "Replace from caret", "cat cat cat")
	editor.OpenFind(true)
	view.Find.Text = "cat"
	view.Replace.Text = "dog"
	editor.RefreshFind(true)
	cf.SelectionRange = { { 8, 0 }, { 8, 0 } }
	cf:MoveCursor(8, 0)
	assert(
		editor.Replace(false) and cf:GetText() == "cat cat dog",
		"Replace Next follows the caret after leaving a previously selected match"
	)
	editor.OpenDocument("find-horizontal", "Horizontal matches", string.rep("x", 180) .. " target")
	editor.OpenFind(false)
	view.Find.Text = "target"
	editor.RefreshFind(true)
	assert(cf.ViewX > 0, "finding a far-right result reveals it horizontally")
	view.Find.Text = "x"
	cf.SelectionRange = { { 0, 0 }, { 0, 0 } }
	cf:MoveCursor(0, 0)
	editor.RefreshFind(true)
	assert(cf.ViewX == 0, "finding a leftmost result resets stale horizontal scrolling")
	editor.OpenDocument(
		"find-vertical",
		"Vertical matches",
		string.rep("\n", 8) .. "target\ntarget" .. string.rep("\n", 35) .. "target"
	)
	editor.OpenFind(false)
	cf.Frame.Size = UDim2.fromOffset(550, cf.FontSize * 12)
	view.Gui.Position = UDim2.fromOffset(300, 0)
	view.Find.Text = "target"
	cf.ScrollV:ScrollTo(5)
	editor.RefreshFind(true)
	assert(cf.ViewY == 5, "a visible match does not recenter the viewport")
	editor.FindNext()
	assert(cf.ViewY == 5, "stepping between visible matches keeps the same viewport")
	editor.FindNext()
	assert(cf.ViewY == cf.CursorY - 11, "a match below the viewport scrolls just far enough to reveal it")
	editor.OpenDocument("find-normalized-replacement", "Normalized replacement", "a a")
	editor.OpenFind(true)
	view.Find.Text = "a"
	view.Replace.Text = "\tB\r\n"
	editor.RefreshFind(true)
	editor.Replace(false)
	assert(
		cf:GetText() == "    B\n a" and cf.SelectionRange[1][1] == 1 and cf.SelectionRange[1][2] == 1,
		"normalized replacement offsets select the correct next result"
	)
	editor.CloseFind()
	assert(not view.Gui.Visible and not cf.SearchVisible, "closing Find removes search decoration state")
	view.Find.Text = "a"
	view:SetResults(0, 1, nil)
	assert(view.Results.Text == "  1 match", "one unselected result uses the native singular count form")
	view:SetResults(1, 1, nil)
	assert(view.Results.Text == "  1 of 1 match", "selected single result uses the native indexed singular form")
	view:SetOptions({ MatchCase = false })
	assert(view.Buttons.MatchCase.BorderSizePixel == 0, "unchecked native buttons remove the checked border")
	editor.OpenDocument("find-step-race", "Find step race", "one one one one")
	editor.OpenFind(false)
	view.Find.Text = "one"
	view.Find.FocusLost:Fire(true)
	flushTasks()
	assert(cf.SearchActiveIndex == 1, "Enter during the query debounce selects exactly one match")
	view.Buttons.FindNext.MouseButton1Click:Fire()
	flushTasks()
	assert(cf.SearchActiveIndex == 2, "next button advances exactly one match")
	view.Find.FocusLost:Fire(true)
	flushTasks()
	assert(cf.SearchActiveIndex == 3, "Enter keeps the match selected after pending callbacks")
	editor.CloseFind()
	print(
		"PASS: native find widget geometry/icons, live toggles, result feedback, regex replacements, undo and read-only state"
	)
end

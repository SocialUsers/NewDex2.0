--!strict

do
	(function()
		local source = "é🙂 tail"
		local doc = editor.OpenDocument("source-derived-undo", "Recovered undo adapter", source)
		cf.SelectionRange = { { 0, 0 }, { #"é🙂", 0 } }
		cf:MoveCursor(#"é🙂", 0)
		cf:AppendText("q")
		assert(cf:GetText() == "q tail")
		editor.Undo(false)
		assert(
			cf:GetText() == source
				and cf.CursorX == #"é🙂"
				and cf.SelectionRange[1][1] == 0
				and cf.SelectionRange[2][1] == #"é🙂",
			"undo restores the pre-edit UTF-8 selection instead of its collapsed deletion cursor"
		)
		editor.Undo(true)
		assert(cf:GetText() == "q tail" and cf.CursorX == 1, "redo restores the final replacement caret")
		editor.Undo(false)
		cf:AppendText("r")
		assert(cf:GetText() == "r tail" and not editor.CanUndo(true))
		editor.Undo(true)
		assert(cf:GetText() == "r tail", "redo at the branch tip cannot fall through into undo")
		cf.SelectionRange = { { 0, 0 }, { 1, 0 } }
		cf:MoveCursor(1, 0)
		editor.OpenDocument("source-derived-other", "Other retained history", "untouched")
		editor.SelectDocument(doc)
		assert(
			cf:GetText() == "r tail" and cf.SelectionRange[1][1] == 0 and cf.SelectionRange[2][1] == 1,
			"tab switch restores the complete selection and caret"
		)
		cf.Editable = false
		assert(
			not editor.CanUndo(false) and not editor.CanUndo(true),
			"read-only menu capabilities match history shortcut guard"
		)
		editor.Undo(false)
		assert(cf:GetText() == "r tail")
		cf.Editable = true
		editor.Undo(false)
		assert(
			cf:GetText() == source and cf.SelectionRange[2][1] == #"é🙂",
			"independent tab retains its history and selection"
		)
		editor.Undo(true)
		editor.CloseDocument(doc)
		cf.GuiElems.EditBox:CaptureFocus()
		keys.LeftControl = true
		keys.LeftShift = true
		service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.T })
		keys.LeftControl = false
		keys.LeftShift = false
		assert(
			editor.ActiveDocument == doc and cf:GetText() == "r tail" and editor.CanUndo(false),
			"reopened tab retains the same bounded stack"
		)
		editor.Undo(false)
		assert(cf:GetText() == source)
		editor.OpenDocument("source-derived-normalized", "Normalized baseline", "é\r\n\tsecond")
		local normalized = cf:GetText()
		cf:MoveCursor(0, 0)
		cf:AppendText("x")
		editor.Undo(false)
		assert(
			cf:GetText() == normalized and not editor.CanUndo(false),
			"initial history baseline uses displayed CRLF/tab normalization"
		)
		print(
			"PASS: actual source-derived history adapter, UTF-8 selection/caret restoration, redo branching, tabs, reopen and read-only capabilities"
		)
	end)()
end

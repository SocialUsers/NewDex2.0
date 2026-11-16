--!strict

do
	local viewer = Apps.ScriptViewer
	local dialog = viewer.NewScriptDialog
	local oldShow, oldFocus, oldEditorFocus = Explorer.Window.Show, Explorer.Window.Focus, viewer.Window.Focus
	local showedExplorer = false
	Explorer.Window.Show = function()
		showedExplorer = true
	end
	Explorer.Window.Focus = function() end
	viewer.Window.Focus = function() end
	local parent = Instance.new("Folder", workspace)
	parent.Name = "ScriptCreationTests"
	Explorer.SyncHistoryObject(parent)
	Explorer.SelectService(parent)
	local documents = #viewer.Documents
	viewer.NewDocument()
	assert(
		dialog.Gui.Visible and #viewer.Documents == documents and #parent:GetChildren() == 0,
		"New script prompts before creating an object or opening a tab"
	)
	assert(
		dialog.Parent == parent and dialog.ParentPath.Text:find("ScriptCreationTests", 1, true),
		"selected Explorer parent is the default location"
	)
	assert(dialog.Gui.BackgroundTransparency == 1, "creation picker does not dim the entire editor")
	assert(dialog.ParentButton.Pick.Image == "mockasset://native/dragger/select-dark")
	assert(dialog.ParentButton.Pick.Size == UDim2.fromOffset(16, 16), "the small Studio icon renders at its native size")
	local panel = dialog.Gui.Panel
	local fields = panel.Fields
	assert(
		dialog.Name.Position.X.Offset == dialog.ParentButton.Position.X.Offset
			and dialog.Name.Size == dialog.ParentButton.Size,
		"name and parent fields share an exact control column and height"
	)
	assert(panel.Size.Y.Offset == 198, "the Insert Object layout fits the editor's compact height")
	for index, className in ipairs({ "ModuleScript", "LocalScript", "Script" }) do
		local record = dialog.TypeButtons[className]
		assert(record.Caption.Text == className and record.Button.ClassIcon.Image == "mockasset://class/" .. className)
		assert(not record.Button:FindFirstChild("Selected"), "the highlight identifies the selected type")
		assert(record.Button.Size.Y.Offset == 21 and record.Button.Position.Y.Offset == (index - 1) * 21)
	end
	dialog.TypeButtons.LocalScript.Button.Activated:Fire()
	assert(
		dialog.ClassName == "LocalScript" and dialog.Name.Text == "LocalScript",
		"type segments update the default name"
	)
	dialog.Name.Text = "CustomName"
	dialog:SelectType("ModuleScript")
	assert(dialog.Name.Text == "CustomName", "changing type preserves a custom name")
	local nested = Instance.new("Folder", parent)
	nested.Name = "NestedLocation"
	Explorer.SyncHistoryObject(nested)
	Explorer.ViewObj(nested)
	local row
	for _, entry in ipairs(Explorer.TreeRenderer.Layer:GetChildren()) do
		if entry.Name == "Entry" and entry.Indent.EntryName.Text == nested.Name then
			row = entry
			break
		end
	end
	assert(row, "the destination is rendered by the main Explorer")
	local oldX, oldY = Main.Mouse.X, Main.Mouse.Y
	local point = row.Indent.EntryName.AbsolutePosition
	Main.Mouse.X, Main.Mouse.Y = point.X + 2, point.Y + 2
	local oldSelection = Explorer.Selection.List[1]
	dialog.ParentButton.Activated:Fire()
	assert(showedExplorer, "picking opens the main Explorer even if it was closed")
	assert(dialog.Mode == "Parent" and not dialog.CreateButton.Interactable)
	assert(fields.Visible and dialog.ParentPath.Text == "Click an object in Explorer")
	assert(not panel:FindFirstChild("Locations"), "there is no second instance tree")
	assert(service.UserInputService:GetFocusedTextBox() ~= dialog.Name, "release editor focus for Explorer search")
	assert(dialog:Create() == false, "the dialog cannot create until the pick completes")
	Explorer.ClickSystem.OnDown:Fire(row, 1, 2)
	Explorer.ClickSystem.OnRelease:Fire(row, 1, 2)
	assert(dialog.Mode == "Parent" and dialog.Parent == parent, "right-click does not set the parent")
	Explorer.ClickSystem.OnDown:Fire(row, 1, 1)
	assert(dialog.Parent == parent and dialog.Mode == "Parent", "a press does not choose the parent yet")
	Explorer.ClickSystem.OnRelease:Fire(row, 1, 1)
	assert(dialog.Parent == nested and dialog.Mode == "Create", "clicking a real Explorer row chooses the parent")
	assert(Explorer.Selection.List[1] == oldSelection and #nested:GetChildren() == 0)
	assert(dialog.Name.Text == "CustomName", "choosing a parent preserves the name")
	dialog:ChooseParent(parent)
	local content = dialog.Gui.Parent
	local priorSize = content.Size
	content.Size = UDim2.fromOffset(340, 232)
	content:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	assert(panel.Size.X.Offset == 320 and panel.Size.Y.Offset == 198)
	dialog:OpenPicker()
	Explorer.ClickSystem.OnDown:Fire(row, 1, 1)
	service.UserInputService.InputBegan:Fire({
		UserInputType = Enum.UserInputType.Keyboard,
		KeyCode = Enum.KeyCode.Escape,
	})
	Explorer.ClickSystem.OnRelease:Fire(row, 1, 1)
	assert(dialog.Mode == "Create" and dialog.Gui.Visible and dialog.Parent == parent)
	assert(dialog.Name.Text == "CustomName", "Escape keeps the previous parent and name")
	dialog:OpenPicker()
	Explorer.Window.OnDeactivate:Fire()
	assert(dialog.Mode == "Create" and dialog.Gui.Visible, "closing Explorer cancels the pick")
	content.Size = priorSize
	content:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	Main.Mouse.X, Main.Mouse.Y = oldX, oldY
	nested:Destroy()
	Explorer.SyncHistoryObject(nested)
	dialog.Name.Text = "Cancelled"
	dialog:Hide()
	assert(
		#parent:GetChildren() == 0 and #viewer.Documents == documents,
		"cancelling creates neither a script nor a tab"
	)
	local old = API.Classes.ModuleScript
	API.Classes.ModuleScript =
		{ Name = "ModuleScript", Tags = {}, Superclass = "Instance", Properties = {}, Functions = {}, Events = {} }
	viewer.NewDocument()
	dialog.Name.Text = "NewModule"
	local doc = dialog:Create()
	assert(
		doc
			and doc.script
			and doc.script.Parent == parent
			and doc.script.ClassName == "ModuleScript"
			and doc.script.Name == "NewModule",
		"creation inserts the actual named script into the selected parent"
	)
	assert(
		viewer.ActiveDocument == doc and not dialog.Gui.Visible,
		"created script opens in its own tab and dismisses the dialog"
	)
	assert(Apps.History.Undo() and doc.script.Parent == nil, "new-script insertion participates in Explorer undo")
	assert(Apps.History.Redo() and doc.script.Parent == parent, "redo restores the same script object")
	assert(dialog.RecentParents[1] == parent, "successful creation remembers the parent")
	Explorer.Selection:Clear()
	viewer.NewDocument()
	assert(dialog.Parent == doc.script.Parent, "the open script supplies a parent when Explorer has no selection")
	panel.Cancel.Activated:Fire()
	assert(not dialog.Gui.Visible, "Cancel closes the chooser")
	local duplicate = Instance.new("ModuleScript", parent)
	duplicate.Name = "ModuleScript"
	Explorer.SelectService(duplicate)
	viewer.NewDocument()
	assert(
		dialog.Parent == parent and dialog.Name.Text == "ModuleScript1",
		"selected scripts use their parent and default names avoid siblings"
	)
	dialog.Name.Text = "NewModule"
	assert(dialog:Create() == false and dialog.Gui.Visible, "duplicate names cannot create ambiguous sibling scripts")
	duplicate:Destroy()
	viewer.NewDocument()
	dialog.Name.Text = "   "
	assert(
		dialog:Create() == false and dialog.Gui.Visible and #parent:GetChildren() == 1,
		"invalid names leave the dialog open without partial objects"
	)
	dialog:Hide()
	API.Classes.ModuleScript = old
	Explorer.Window.Show, Explorer.Window.Focus, viewer.Window.Focus = oldShow, oldFocus, oldEditorFocus
	print(
		"PASS: new-script parent picker, cancellation, actual object insertion, active tab, validation and Explorer undo/redo"
	)
end

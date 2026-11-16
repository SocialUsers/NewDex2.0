--!strict

Properties.DisplayAddAttributeWindow()
local win = Properties.AddAttributeWindow
local fields = win.Elements
assert(win.GuiElems.Main.Size.X.Offset == 252, "reference dialog width")
assert(fields.NameBox.Size.Y.Offset == 22 and fields.TypeChooser.Size.Y.Offset == 22, "matching field sizes")
assert(fields.SaveButton.Disabled and fields.SaveButton.Text == "Save", "empty create state")
assert(service.UserInputService.Focus == fields.NameBox.TextBox, "initial focus")
fields.NameBox:SetText("RBXReserved")
fields.SaveButton:Trigger("Click")
assert(#writes == 0 and not win.Closed and fields.Error.Text ~= "", "invalid name stays open")
fields.NameBox:SetText("Health")
fields.TypeChooser:SetSelected("number")
fields.NameBox.TextBox.FocusLost:Fire(true)
assert(#writes == 1 and writes[1][1].AttributeName == "Health" and writes[1][2] == 0, "Enter creates selected type")
assert(win.Closed and fields.TypeChooser.Context.Hidden, "dialog closes its type popup")
local previous = { AttributeName = "Enabled", ValueType = { Name = "bool" } }
Properties.DisplayAddAttributeWindow(previous)
assert(
	fields.NameBox:GetText() == "Enabled" and fields.TypeChooser.Selected == "boolean",
	"edit preserves name and type"
)
assert(fields.SaveButton.Text == "Save" and not fields.SaveButton.Disabled, "edit save enabled")
fields.NameBox:SetText("Visible")
fields.SaveButton:Trigger("Click")
assert(writes[2][4] == previous, "edit passes original attribute to update")
Properties.DisplayAddAttributeWindow()
assert(
	fields.NameBox:GetText() == "" and fields.TypeChooser.Selected == "string" and fields.Error.Text == "",
	"reopen resets create state"
)
print("PASS: actual attribute dialog construction, validation, Enter, edit prefill and dropdown cleanup")

assert(fields.NameCount.Text == "0/100", "empty character count")
fields.NameBox:SetText(string.rep("x", 101))
assert(fields.NameCount.Text == "101/100" and fields.SaveButton.Disabled, "character limit disables Save")
Properties.DisplayAddAttributeWindow(previous)
assert(not fields.TypeChooser.Visible and not fields.TypeLabel.Visible, "Rename cannot change attribute type")

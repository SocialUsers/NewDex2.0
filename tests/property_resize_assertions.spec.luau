--!strict

local oldScale = Settings.Properties.ScaleType
Settings.Properties.ScaleType = 1
Properties.Refresh()
assert(connects == 2 and reads == 2)
for i = 1, 500 do
	propsFrame.Size = UDim2.fromOffset(420 + i, 46)
	Properties.Refresh(true)
end
assert(connects == 2 and disconnects == 0 and reads == 2, "width-only resizing reuses listeners and rendered values")
object.Name = "Changed"
object:GetPropertyChangedSignal("Name"):Fire()
assert(
	reads == 3 and propEntries[1].GuiElems.ValueBox.Text == "Changed",
	"retained property listeners still update resized cells"
)
object:SetAttribute("Test", true)
object:GetPropertyChangedSignal("attr_Test"):Fire()
assert(propEntries[2].GuiElems.ValueBox.Text == "true", "retained attribute listeners still update resized cells")
viewList[3] =
	{ Class = "Instance", Name = "Archivable", ValueType = { Name = "bool", Category = "Primitive" }, Tags = {} }
Properties.ViewLayout = View.Layout(viewList)
autoUpdateObjs["Instance.Archivable"] = object
propsFrame.Size = UDim2.fromOffset(500, 69)
Properties.Refresh(true)
assert(connects == 3 and disconnects == 0, "height changes bind only the newly visible row")
propsFrame.Size = UDim2.fromOffset(500, 44)
Properties.ScrollOffset = 21
Properties.Refresh(true)
assert(connects == 5 and disconnects == 3, "scrolling reconnects changed rows and releases rows no longer visible")
Properties.ScrollOffset = 0
propsFrame.Size = UDim2.fromOffset(500, 44)
inputProp = viewList[1]
Properties.Refresh()
inputBox:CaptureFocus()
propsFrame.Size = UDim2.fromOffset(600, 44)
Properties.Refresh(true)
assert(
	inputBox.Visible and service.UserInputService:GetFocusedTextBox() == inputBox,
	"resizing retains the active property editor and focus"
)
inputBox:ReleaseFocus()
Settings.Properties.ScaleType = oldScale
Settings.Properties = oldPropertySettings
for _, entry in ipairs(propEntries) do
	disconnectPropertyRow(entry)
end
print(
	"PASS: 500 width changes reuse property/attribute values and listeners; height/scroll changes rebind; edit focus stays intact"
)

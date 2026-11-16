--!strict

local property = { ValueType = { Category = "Class" } }
local frame = { AbsolutePosition = Vector2.new(20, 20), AbsoluteSize = Vector2.new(100, 22) }
propEntries[1] = { Gui = { Visible = true }, GuiElems = { ValueFrame = frame } }
viewList[1] = property
Properties.Window = { Closed = false, OnDeactivate = signal() }
Properties.InitObjectPicker()
local function press(x, y, kind)
	local input = { UserInputType = kind or Enum.UserInputType.MouseButton1, Position = Vector2.new(x, y) }
	service.UserInputService.InputBegan:Fire(input)
	return input
end
local function release(input)
	service.UserInputService.InputEnded:Fire(input)
end
inputProp = property
release(press(30, 25))
assert(inputProp == property, "clicking the active value cell preserves its picker")
release(press(115, 25))
assert(inputProp == property, "clear button remains clickable")
local outside = press(500, 500)
assert(inputProp == property, "outside press leaves Explorer time to consume an object pick")
release(outside)
assert(inputProp == nil and refreshes == 1, "outside release cancels without a property write")
inputProp = property
outside = press(500, 500)
inputProp = nil -- Explorer.SelectObject consumes the picker on press.
release(outside)
assert(refreshes == 1, "a consumed object selection is not cancelled again")
inputProp = property
outside = press(500, 500)
local replacement = { ValueType = { Category = "Primitive" } }
inputProp = replacement
release(outside)
assert(inputProp == replacement, "outside cancellation preserves a newly opened editor")
inputProp = property
release(press(500, 500, Enum.UserInputType.Touch))
assert(inputProp == nil, "touch outside cancels")
inputProp = property
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape })
assert(inputProp == nil, "Escape cancels")
inputProp = property
Properties.Window.OnDeactivate:Fire()
assert(inputProp == property, "switching focus to Explorer must preserve an active picker")
Properties.Window.Closed = true
Properties.Window.OnDeactivate:Fire()
assert(inputProp == nil, "closing Properties must disarm its object picker")
print("PASS: object picker outside cancellation, clear-button bounds, Escape and consumed Explorer picks")

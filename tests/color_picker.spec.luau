--!strict

local picker = Lib.ColorPicker.new()
local content = picker.Window.Gui.Main.Content
assert(picker.Window.Gui.Main.Size == UDim2.fromOffset(524, 430))
assert(
	#content.BasicColors:GetChildren() == 49 and #content.CustomColors:GetChildren() == 17,
	"48 basic and 16 custom colors"
)
content.Hex.Text = "#127ACC"
content.Hex.FocusLost:Fire(false)
assert(picker.Color:ToHex() == "127ACC", "hex changes color")
content.AddCustom.Activated:Fire()
assert(Lib.CustomColors[1]:ToHex() == "127ACC", "custom color stores current value")
content.Hex.Text = "invalid"
content.Hex.FocusLost:Fire(false)
assert(content.Hex.Text == "#127ACC", "invalid hex restores current color")
local selected
picker.OnSelect:Connect(function(color)
	selected = color
end)
content.Ok.MouseButton1Click:Fire()
assert(selected:ToHex() == "127ACC" and picker.Window.Closed, "OK commits and closes")
print("PASS: actual color picker construction, palettes, Hex validation, custom save and OK")
do
	local previousPressed = service.UserInputService.IsMouseButtonPressed
	local x, y = Main.Mouse.X, Main.Mouse.Y
	service.UserInputService.IsMouseButtonPressed = function()
		return false
	end
	local target = Instance.new("Folder")
	target.IconTint = Color3.new(0, 0, 0)
	local prop = { Name = "IconTint", Class = "Folder", ValueType = { Name = "Color3", Category = "Other" } }
	local active = prop
	local commits = 0
	local widget
	local editors = Apps.PropertyValueEditors.Create({
		GetInputProp = function()
			return active
		end,
		SetInputProp = function(p)
			active = p
		end,
		ReadFirst = function()
			return target.IconTint
		end,
		Commit = function(p, value)
			commits += 1
			Apps.History.Run("Change " .. p.Name, function()
				Apps.History.Set(target, p.Name, value)
			end)
		end,
		Factories = {
			Color = function()
				widget = Lib.ColorPicker.new()
				return widget
			end,
		},
	})
	editors.ShowColor(prop)
	local panel = widget.Window.Gui.Main.Content
	local surface = panel.ColorSpaceFrame.ColorSpace
	assert(widget.Color:ToHex() == "000000" and commits == 0, "opening a black IconTint does not change it")
	Main.Mouse.X = surface.AbsolutePosition.X + 219
	Main.Mouse.Y = surface.AbsolutePosition.Y
	surface.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
	assert(
		widget.Color:ToHex() == "FF0000" and panel.Red.Input.Text == "255",
		"one click escapes zero brightness and updates RGB fields"
	)
	assert(target.IconTint:ToHex() == "000000", "preview remains uncommitted until OK")
	panel.Ok.MouseButton1Click:Fire()
	assert(
		commits == 1 and target.IconTint:ToHex() == "FF0000",
		"actual picker/editor/history chain commits Folder.IconTint"
	)
	widget:SetColor(Color3.fromRGB(0, 0, 64))
	Main.Mouse.X = surface.AbsolutePosition.X + 146
	surface.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
	assert(widget.Color:ToHex() == "004000", "nonzero user brightness stays unchanged when selecting a hue")
	widget:SetColor(Color3.new(4, -0.5, 0))
	assert(widget.Color:ToHex() == "FF0000", "picker normalizes extended RGB before deriving HSV")
	surface.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
	assert(widget.Color:ToHex() == "00FF00", "hue selection keeps brightness in range after an extended RGB input")
	widget:SetColor(Color3.new(0, 0, 0))
	assert(widget.Color:ToHex() == "000000", "black is still a valid explicit color")
	editors.Destroy()
	target:Destroy()
	service.UserInputService.IsMouseButtonPressed = previousPressed
	Main.Mouse.X, Main.Mouse.Y = x, y
	print(
		"PASS: real black-start hue-area click, RGB update, OK-to-IconTint write, preserved dim brightness and explicit black"
	)
end

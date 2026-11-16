--!strict

local connects, disconnects, reads = 0, 0, 0
local oldPropertySettings = Settings.Properties
Settings.Properties = Settings.Properties or {}
local object = Instance.new("Part")
object.Name = "Original"
object:SetAttribute("Test", false)
local function trackedSignal(key)
	local native = object:GetPropertyChangedSignal(key)
	return {
		Connect = function(_, callback)
			connects += 1
			local connection = native:Connect(callback)
			return {
				Disconnect = function()
					disconnects += 1
					connection:Disconnect()
				end,
			}
		end,
	}
end
local getPropChangedSignal = function(_, name)
	return trackedSignal(name)
end
local getAttributeChangedSignal = function(_, name)
	return trackedSignal("attr_" .. name)
end
local propsFrame = Instance.new("Frame")
propsFrame.Size = UDim2.fromOffset(420, 46)
local inputBox = Instance.new("TextBox")
local inputProp
local propEntries, checkboxes = {}, {}
local viewportWidth, viewportHeight
local viewList = {
	{ Class = "Instance", Name = "Name", ValueType = { Name = "string", Category = "Primitive" }, Tags = {} },
	{
		Class = "Instance",
		Name = "ATTR_Test",
		AttributeName = "Test",
		IsAttribute = true,
		ValueType = { Name = "bool", Category = "Primitive" },
		Tags = {},
	},
}
local autoUpdateObjs = { ["Instance.Name"] = object, ["Instance.ATTR_Test"] = object }
local scrollH = { Index = 0 }
local expanded = {}
local View = Apps.StudioPropertiesView
local Colors = { Surface = Color3.fromRGB(25, 26, 31), Text = Color3.new(1, 1, 1) }
local Properties = {
	Index = 0,
	ViewWidth = 150,
	MinInputWidth = 80,
	EntryIndent = 16,
	EntryOffset = 0,
	ExpandableTypes = {},
	ExpandableProps = {},
	FullNameFrame = Instance.new("Frame"),
	FullNameFrameAttach = { Disable = function() end },
}
Properties.ScrollOffset = 0
Properties.ColumnRatio = 0.5
Properties.ViewLayout = View.Layout(viewList)
function Properties.IsTextEditable()
	return true
end
function Properties.NewPropEntry()
	local row = { Gui = Instance.new("Frame"), GuiElems = {} }
	for _, name in ipairs({
		"NameFrame",
		"PropName",
		"ValueFrame",
		"Expand",
		"ValueBox",
		"RightButton",
		"EditAttributeButton",
		"ToggleAttributes",
		"RowButton",
		"EmptyAttributes",
		"TagRemove",
	}) do
		row.GuiElems[name] = Instance.new("TextLabel", row.Gui)
	end
	return row
end
function Properties.DisplayProp(prop, index)
	reads += 1
	local key = prop.Class .. "." .. prop.Name
	local target = autoUpdateObjs[key]
	local value
	if prop.IsAttribute then
		value = target:GetAttribute(prop.AttributeName)
	else
		value = target[prop.Name]
	end
	propEntries[index].GuiElems.ValueBox.Text = tostring(value)
end

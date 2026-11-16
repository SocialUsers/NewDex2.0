--!strict

Main.MenuApps = {}
Main.LargeIcons = { Display = function() end, DisplayByKey = function() end }
local Explorer = { Window = Lib.Window.new(), LegacyClassIcons = Main.LargeIcons }
local Properties = { Window = Lib.Window.new() }
local ScriptViewer = { Window = Lib.Window.new() }
local Console = { Window = Lib.Window.new() }
local SaveInstance = { Window = Lib.Window.new() }
local ModelViewer = { Window = Lib.Window.new() }
for _, app in ipairs({ Explorer, Properties, ScriptViewer, Console, SaveInstance, ModelViewer }) do
	function app.Window:Hide()
		self.Closed = true
		self.OnDeactivate:Fire()
	end
end
local selection = Apps.Explorer.Selection
service.TweenService = {
	Create = function(_, obj, info, props)
		return {
			Play = function()
				for k, v in pairs(props) do
					obj[k] = v
				end
			end,
		}
	end,
}
function methods:TweenSize(size)
	self.Size = size
end
local originalIndex = instMT.__index
instMT.__index = function(obj, key)
	if rawget(obj, "_props").ClassName == "UIGridLayout" and key == "AbsoluteContentSize" then
		local cell, pad = obj.CellSize, obj.CellPadding
		local columns = math.clamp(
			math.floor((obj.Parent.AbsoluteSize.X + pad.X.Offset) / (cell.X.Offset + pad.X.Offset)),
			1,
			obj.FillDirectionMaxCells
		)
		local count = #obj.Parent:GetChildren() - 1
		local rows = math.ceil(count / columns)
		local width = math.min(count, columns) * (cell.X.Offset + pad.X.Offset) - pad.X.Offset
		return Vector2.new(math.max(0, width), math.max(0, rows * (cell.Y.Offset + pad.Y.Offset) - pad.Y.Offset))
	end
	return originalIndex(obj, key)
end

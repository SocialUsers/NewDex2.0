--!strict

do
	local sidesGui = Instance.new("ScreenGui")
	local leftSide = { Hidden = false, Width = 340, Windows = {} }
	local rightSide = { Hidden = false, Width = 340, Windows = {} }
	local alignIndicator = Instance.new("ScreenGui")
	local indicator = Instance.new("Frame", alignIndicator)
	indicator.Name = "Indicator"
	local guiDragging = false
	local sideDisplayOrder = 1
	local function updateWindows() end
	local funcs = {}

	local function renderSide(side)
		local y = 0
		for _, win in ipairs(side.Windows) do
			win.PosY = y
			win.GuiElems.Main.Position =
				UDim2.fromOffset(side == leftSide and 0 or sidesGui.AbsoluteSize.X - side.Width, y)
			win.GuiElems.Main.Size = UDim2.fromOffset(side.Width, win.SizeY)
			y += win.SizeY + 4
		end
	end

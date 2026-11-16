--!strict

	updateWindows = function()
		updateSide(leftSide, true)
		updateSide(rightSide, true)
	end
	local function makeWindow()
		local gui = Instance.new("ScreenGui")
		local main = Instance.new("Frame", gui)
		main.Position = UDim2.fromOffset(400, 100)
		local top = Instance.new("Frame", main)
		local win = setmetatable(
			{
				Gui = gui,
				GuiElems = { Main = main, TopBar = top },
				Draggable = true,
				Alignable = true,
				Resizable = false,
				SizeY = 240,
				MinY = 100,
				PosY = 0,
			},
			{ __index = funcs }
		)
		function win:SetAligned(value)
			self.Aligned = value
			if not value and self.Side then
				local i = table.find(self.Side.Windows, self)
				if i then
					table.remove(self.Side.Windows, i)
				end
				self.Side = nil
			end
		end
		installDrag(win)
		return win
	end
	local win = makeWindow()
	local function press(w, x, y)
		w.GuiElems.TopBar.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector2.new(
			x,
			y
		) })
	end
	local function move(x, y)
		service.UserInputService.InputChanged:Fire({
			UserInputType = Enum.UserInputType.MouseMovement,
			Position = Vector2.new(x, y),
		})
	end
	local function release()
		service.UserInputService.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
	end
	local threshold = makeWindow()
	local initial = threshold.GuiElems.Main.Position
	press(threshold, 450, 110)
	move(454, 113)
	assert(
		threshold.GuiElems.Main.Position == initial and not threshold.Dragging,
		"pointer movement at the Manhattan threshold remains a click"
	)
	move(455, 113)
	assert(threshold.Dragging, "pointer movement beyond the Manhattan threshold begins dragging")
	release()
	assert(not threshold.Dragging, "release clears drag ownership")
	press(win, 450, 110)
	move(20, 120)
	assert(alignIndicator.Parent and indicator.Size.X.Offset == 340, "preview appears over full left dock area")
	local previewPos, previewSize = indicator.Position, indicator.Size
	release()
	assert(
		win.GuiElems.Main.Position == previewPos and win.GuiElems.Main.Size == previewSize,
		"empty dock preview matches committed position and size"
	)
	assert(
		win.Aligned and win.Side == leftSide and leftSide.Windows[1] == win and not alignIndicator.Parent,
		"release docks non-resizable alignable window and hides preview"
	)
	local other = makeWindow()
	press(other, 450, 110)
	move(200, 750)
	previewPos, previewSize = indicator.Position, indicator.Size
	release()
	assert(
		other.GuiElems.Main.Position == previewPos and other.GuiElems.Main.Size == previewSize,
		"split dock preview exactly matches resulting bounds"
	)
	assert(leftSide.Windows[2] == other, "lower drop inserts below existing window")
	press(win, 200, 20)
	move(500, 120)
	move(1080, 120)
	assert(not win.Aligned and alignIndicator.Parent, "detached window can preview opposite side")
	previewPos, previewSize = indicator.Position, indicator.Size
	release()
	assert(
		win.GuiElems.Main.Position == previewPos and win.GuiElems.Main.Size == previewSize,
		"right preview has no invented 24px inset"
	)
	assert(
		win.Side == rightSide and rightSide.Windows[1] == win and #leftSide.Windows == 1,
		"moving between docks removes old membership"
	)
	local floating = makeWindow()
	press(floating, 450, 110)
	move(200, 100)
	move(550, 100)
	release()
	assert(not floating.Aligned and not alignIndicator.Parent, "leaving dock area cancels pending snap")
	rightSide.Hidden = true
	press(floating, 450, 110)
	move(1070, 650)
	release()
	assert(floating.Side == rightSide and not rightSide.Hidden, "screen edge reopens hidden dock")
	local noDock = makeWindow()
	noDock.Alignable = false
	press(noDock, 450, 110)
	move(20, 100)
	release()
	assert(not noDock.Aligned, "non-alignable dialogs remain floating")
	local b = Instance.new("TextButton")
	Lib.SetSidebarIcon(b, false, false)
	assert(b.DockChevron.Rotation == 0, "left expanded chevron")
	Lib.SetSidebarIcon(b, true, false)
	assert(b.DockChevron.Rotation == 180, "left collapsed chevron")
	Lib.SetSidebarIcon(b, false, true)
	assert(b.DockChevron.Rotation == 180, "right expanded chevron")
	Lib.SetSidebarIcon(b, true, true)
	assert(b.DockChevron.Rotation == 0, "right collapsed chevron")
	assert(#b:GetChildren() == 1, "sidebar updates reuse one icon")
	assert(
		b.DockChevron:IsA("ImageLabel") and b.DockChevron.Image == "mockasset://native/sidebar/left",
		"sidebar uses the original Studio chevron"
	)
	print(
		"PASS: actual titlebar drag and AlignTo handlers, dock preview, both sides, insertion, hidden dock reopening, cancellation and sidebar icon states"
	)
end

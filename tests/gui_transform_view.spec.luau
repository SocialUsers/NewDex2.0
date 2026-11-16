--!strict

do
	local gui = Instance.new("ScreenGui")
	local view = Apps.GuiTransformView.Create(gui)
	local pink, green = Color3.fromRGB(255, 8, 103), Color3.new(0, 1, 0)
	local function colorEqual(a, b)
		return a.R == b.R and a.G == b.G and a.B == b.B
	end
	local custom = Color3.fromRGB(40, 80, 120)
	view:SetGuides({
		{ X = 550, From = 26, To = 726, Kind = "Center", TargetSource = "Screen" },
		{ Y = 400, From = 60, To = 1040, Kind = "Center", TargetSource = "Parent" },
		{ X = 130, From = 460, To = 40, Kind = "Edge", TargetSource = "Parent" },
		{ Y = 250, From = 90, To = 410, Kind = "Edge", Color = custom },
	})
	assert(#view.Guides == 4, "all alignment matches receive pooled guides, including both center axes")
	assert(
		view.Guides[1].Position == UDim2.fromOffset(550, 26) and view.Guides[1].Size == UDim2.fromOffset(1, 700),
		"vertical center guide uses explicit overlay endpoints"
	)
	assert(
		view.Guides[2].Position == UDim2.fromOffset(60, 400) and view.Guides[2].Size == UDim2.fromOffset(980, 1),
		"horizontal center guide shares the same overlay coordinate origin"
	)
	assert(
		colorEqual(view.Guides[1].BackgroundColor3, green) and colorEqual(view.Guides[2].BackgroundColor3, green),
		"both center alignments use the source's pure green"
	)
	assert(
		colorEqual(view.Guides[3].BackgroundColor3, pink)
			and view.Guides[3].Position == UDim2.fromOffset(130, 40)
			and view.Guides[3].Size == UDim2.fromOffset(1, 420),
		"edge semantics remain pink for parent targets and accept reversed endpoints"
	)
	assert(colorEqual(view.Guides[4].BackgroundColor3, custom), "controller can explicitly override guide color")
	local reused = view.Guides[1]
	view:SetGuides({ { X = 120 } })
	assert(
		view.Guides[1] == reused and colorEqual(view.Guides[1].BackgroundColor3, pink),
		"pooled line resets stale center color"
	)
	assert(
		view.Guides[1].Size == UDim2.fromOffset(1, gui.AbsoluteSize.Y),
		"legacy full-viewport guide requests remain supported"
	)
	for i = 2, 4 do
		assert(not view.Guides[i].Visible, "surplus pooled lines are hidden")
	end
	view:SetGuides({ { X = 0 / 0 }, { Y = 15, From = math.huge }, { Y = 20, From = 5, To = 5 } })
	assert(
		view.Guides[1].Visible
			and view.Guides[1].Position == UDim2.fromOffset(5, 20)
			and view.Guides[1].Size == UDim2.fromOffset(1, 1),
		"invalid coordinates never reach GUI properties and zero-length lines remain a pixel"
	)
	view:Hide()
	for _, guide in ipairs(view.Guides) do
		assert(not guide.Visible and not guide.Active, "guides hide with the editor and never consume input")
	end
	view:Destroy()
	gui:Destroy()
	print(
		"PASS: pooled GUI center/edge guides, exact semantic colors, explicit spans, overrides, coordinate validation and cleanup"
	)
end

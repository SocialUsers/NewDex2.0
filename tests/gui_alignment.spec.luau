--!strict

do
	local A, S = Apps.GuiAlignment, Apps.GuiTransformSession
	local screen = Instance.new("ScreenGui", game)
	screen.Enabled = true
	screen.RootPosition = Vector2.new(0, -36)
	local parent = newGui(screen, UDim2.fromOffset(60, 100), UDim2.fromOffset(500, 400))
	local selected = newGui(parent, UDim2.fromOffset(50, 80), UDim2.fromOffset(101, 51))
	local excluded = newGui(selected, UDim2.fromOffset(400, 300))
	local cousinParent = newGui(screen, UDim2.fromOffset(700, 80), UDim2.fromOffset(200, 300))
	local cousin = newGui(cousinParent, UDim2.fromOffset(20, 20), UDim2.fromOffset(30, 60))
	local invisible = newGui(screen)
	invisible.Visible = false
	local hiddenChild = newGui(invisible)
	local targets = A.Collect({ selected })
	local foundX, foundY, foundCousin = false, false, false
	for _, target in ipairs(targets.X) do
		assert(
			target.Source ~= selected
				and target.Source ~= excluded
				and target.Source ~= invisible
				and target.Source ~= hiddenChild,
			"selected descendants and hidden subtrees are excluded from alignment candidates"
		)
		if target.Source == "Screen" and target.Kind == "Center" and target.Value == 550 then
			foundX = true
		end
		if target.Source == cousin then
			foundCousin = true
		end
	end
	for _, target in ipairs(targets.Y) do
		if target.Source == "Screen" and target.Kind == "Center" and target.Value == 400 then
			foundY = true
		end
	end
	assert(
		foundX and foundY and foundCousin,
		"nested selection gets full-viewport centers and other visible descendants outside its immediate siblings"
	)
	local delta, matches = A.Snap(targets.X, { { Kind = "Center", Value = 548 } })
	assert(
		delta == 2 and #matches > 0 and matches[1].Kind == "Center",
		"center snapping matches center targets within the source's five-pixel tolerance"
	)
	local _, wrong = A.Snap({ { Value = 550, Kind = "Edge" } }, { { Kind = "Center", Value = 550 } })
	assert(#wrong == 0, "center and edge features are not conflated")
	local guides = A.Guides(
		{ { Value = 550, Kind = "Center", From = 0, To = 800, Source = "Screen" } },
		{ { Value = 400, Kind = "Center", From = 0, To = 1100, Source = "Screen" } },
		{ Center = Vector2.new(550, 400), Size = Vector2.new(101, 51), Rotation = 0 }
	)
	assert(
		#guides == 2 and guides[1].X == 550 and guides[2].Y == 400 and guides[1].From == -10 and guides[1].To == 810,
		"simultaneous center cross uses true viewport axes and source ten-pixel overhang"
	)
	local repeated = A.Guides(
		{ { Value = 550, Kind = "Center", From = 0, To = 600 }, { Value = 550, Kind = "Center", From = 200, To = 800 } },
		nil,
		{ Center = Vector2.new(550, 400), Size = Vector2.new(101, 51), Rotation = 0 }
	)
	assert(
		#repeated == 1 and repeated[1].From == -10 and repeated[1].To == 810,
		"coincident guides merge their span instead of allocating repeated overlay frames"
	)
	screen:Destroy()
	print(
		"PASS: full-screen/parent/cousin alignment targets, selected-descendant exclusion, center semantics, tolerance and guide extents"
	)
end

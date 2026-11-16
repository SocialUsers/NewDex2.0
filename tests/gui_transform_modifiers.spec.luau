--!strict

-- Focused session-level modifier checks. Append after gui_transform_mock and
-- production module loading, before the controller smoke test shuts down Main.
do
	local S = Apps.GuiTransformSession
	local function close(a, b, message)
		assert(math.abs(a - b) < 1e-6, message)
	end
	local function samePoint(a, b, message)
		close(a.X, b.X, message)
		close(a.Y, b.Y, message)
	end
	local function midpoint(a, b)
		return Vector2.new((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5)
	end
	local screen = Instance.new("ScreenGui", game)
	screen.Enabled = true
	screen.RootPosition = Vector2.new(0, 0)
	local parent = newGui(screen, UDim2.fromOffset(160, 100), UDim2.fromOffset(500, 400), Vector2.new(0.3, 0.6), 35)
	local parentZoom = Instance.new("UIScale", parent)
	parentZoom.Scale = 1.5
	local child = newGui(parent, UDim2.new(0.25, 17, 0.5, 23), UDim2.fromOffset(120, 60), Vector2.new(0.2, 0.85), -55)
	local childZoom = Instance.new("UIScale", child)
	childZoom.Scale = 0.75
	local beforePosition, beforeSize = child.Position, child.Size
	local initial = S.Geometry(child)
	-- Ctrl scales symmetrically from the visual center regardless of AnchorPoint,
	-- element rotation, rotated parent or inherited/own UIScale.
	for _, handle in ipairs({ { 1, 1 }, { -1, -1 }, { 1, 0 }, { 0, -1 } }) do
		local session = assert(S.Begin({ child }, "Scale"))
		local dx, dy = rot(handle[1] * 20, handle[2] * 10, initial.Rotation)
		assert(session:Resize(handle[1], handle[2], dx, dy, true, false))
		local actual = S.Geometry(child)
		samePoint(actual.Center, initial.Center, "Ctrl resizing keeps visual center fixed")
		close(actual.Size.X, initial.Size.X + (handle[1] ~= 0 and 40 or 0), "Ctrl doubles horizontal edge growth")
		close(actual.Size.Y, initial.Size.Y + (handle[2] ~= 0 and 20 or 0), "Ctrl doubles vertical edge growth")
		session:Cancel()
	end
	-- Shift on a side handle preserves aspect and pins the opposite edge's
	-- midpoint, while the unconstrained dimension expands around that midpoint.
	for _, sign in ipairs({ -1, 1 }) do
		local session = assert(S.Begin({ child }, "Scale"))
		local dx, dy = rot(sign * 30, 0, initial.Rotation)
		local fixed = sign == 1 and midpoint(initial.Corners[1], initial.Corners[4])
			or midpoint(initial.Corners[2], initial.Corners[3])
		assert(session:Resize(sign, 0, dx, dy, false, true))
		local actual = S.Geometry(child)
		close(actual.Size.X / actual.Size.Y, initial.Size.X / initial.Size.Y, "Shift side resize preserves aspect")
		samePoint(
			sign == 1 and midpoint(actual.Corners[1], actual.Corners[4])
				or midpoint(actual.Corners[2], actual.Corners[3]),
			fixed,
			"Shift side resize holds opposite edge midpoint"
		)
		session:Cancel()
	end
	for _, sign in ipairs({ -1, 1 }) do
		local session = assert(S.Begin({ child }, "Scale"))
		local dx, dy = rot(0, sign * 20, initial.Rotation)
		local fixed = sign == 1 and midpoint(initial.Corners[1], initial.Corners[2])
			or midpoint(initial.Corners[3], initial.Corners[4])
		assert(session:Resize(0, sign, dx, dy, false, true))
		local actual = S.Geometry(child)
		close(
			actual.Size.X / actual.Size.Y,
			initial.Size.X / initial.Size.Y,
			"Shift vertical side resize preserves aspect"
		)
		samePoint(
			sign == 1 and midpoint(actual.Corners[1], actual.Corners[2])
				or midpoint(actual.Corners[3], actual.Corners[4]),
			fixed,
			"Shift vertical side resize holds opposite edge midpoint"
		)
		session:Cancel()
	end
	for _, handle in ipairs({ { 1, 1, 1 }, { -1, 1, 2 }, { -1, -1, 3 }, { 1, -1, 4 } }) do
		local session = assert(S.Begin({ child }, "Scale"))
		local dx, dy = rot(handle[1] * 30, handle[2] * 10, initial.Rotation)
		assert(session:Resize(handle[1], handle[2], dx, dy, false, true))
		local actual = S.Geometry(child)
		close(actual.Size.X / actual.Size.Y, initial.Size.X / initial.Size.Y, "Shift corner resize preserves aspect")
		samePoint(actual.Corners[handle[3]], initial.Corners[handle[3]], "Shift corner resize holds opposite corner")
		session:Cancel()
	end
	-- Ctrl+Shift combines centered scaling and aspect lock. Toggling modifiers
	-- must recompute from the same immutable snapshot without accumulated drift.
	local session = assert(S.Begin({ child }, "Scale"))
	local dx, dy = rot(30, 10, initial.Rotation)
	assert(session:Resize(1, 1, dx, dy, true, true))
	local actual = S.Geometry(child)
	samePoint(actual.Center, initial.Center, "Ctrl+Shift preserves center")
	close(actual.Size.X / actual.Size.Y, initial.Size.X / initial.Size.Y, "Ctrl+Shift preserves aspect")
	assert(session:Resize(1, 1, dx, dy, false, false))
	local without = S.Geometry(child)
	close(without.Size.X, initial.Size.X + 30, "releasing Ctrl recomputes noncentered width from start")
	close(without.Size.Y, initial.Size.Y + 10, "releasing Shift recomputes independent height from start")
	session:Cancel()
	assert(
		child.Position == beforePosition and child.Size == beforeSize,
		"modifier cancellation restores exact original UDim2 values"
	)
	-- An aspect-preserving shrink must clamp the shared factor for both axes;
	-- clamping only the grabbed axis lets a narrow axis shrink below one pixel.
	local skinny = newGui(screen, UDim2.fromOffset(0, 0), UDim2.fromOffset(100, 10))
	session = assert(S.Begin({ skinny }, "Scale"))
	assert(session:Resize(1, 0, -1000, 0, false, true))
	actual = S.Geometry(skinny)
	assert(actual.Size.X >= 1 and actual.Size.Y >= 1, "Shift shrink never produces a subpixel dimension")
	close(actual.Size.X / actual.Size.Y, 10, "minimum-size clamp retains aspect ratio")
	session:Cancel()
	local tiny = newGui(screen, UDim2.fromOffset(200, 0), UDim2.fromOffset(2, 4), Vector2.new(0.5, 0.5), 20)
	session = assert(S.Begin({ skinny, tiny }, "Scale"))
	assert(session:Resize(1, 0, -10000, 0, false, true))
	for _, object in ipairs({ skinny, tiny }) do
		local geometry = S.Geometry(object)
		assert(
			geometry.Size.X >= 1 - 1e-6 and geometry.Size.Y >= 1 - 1e-6,
			"group shrinking clamps to every selected object's minimum dimension"
		)
	end
	session:Cancel()
	screen:Destroy()
	print(
		"PASS: GUI Ctrl/Shift modifiers, centered rotated resizing, aspect-locked opposite edges, immutable modifier changes and shared minimum size"
	)
end

--!strict

service.Workspace = workspace
workspace.Terrain = Instance.new("Terrain", workspace)
service.RunService = { RenderStepped = signal() }
local pointer = Vector2.new(550, 400)
service.GuiService = {
	GetGuiInset = function()
		return Vector2.new(0, 36), Vector2.new(0, 0)
	end,
}
function service.UserInputService:GetMouseLocation()
	return pointer
end
local modifiers = {}
service.UserInputService.IsKeyDown = function(_, key)
	return modifiers[key] == true
end
service.UserInputService.WindowFocusReleased = signal()
local action, keyAction
service.ContextActionService = {
	BindActionAtPriority = function(_, name, fn)
		if name:sub(-4) == "Keys" then
			keyAction = fn
		else
			action = fn
		end
	end,
	UnbindAction = function(_, name)
		if name:sub(-4) == "Keys" then
			keyAction = nil
		else
			action = nil
		end
	end,
}
Lib.StudioFont = Enum.Font.BuilderSans
Lib.ShowGui = function() end
Lib.StudioTooltip = function() end
Lib.IsCtrlDown = function()
	return modifiers[Enum.KeyCode.LeftControl] == true
end
Lib.IsShiftDown = function()
	return modifiers[Enum.KeyCode.LeftShift] == true
end
Main.GetStudioAsset = function(key)
	return key
end
Main.DisplayOrders.Core = 1
Main.GameInputLocked = false
Main.SetGameInputLocked = function(value)
	Main.GameInputLocked = value
end
Main.IsPointInDexUI = function(x)
	return x > 900
end
local camera = { CFrame = CFrame.new(0, 0, 20), ViewportSize = Vector2.new(1100, 800), FieldOfView = 70 }
function camera:WorldToScreenPoint(position)
	local localPoint = self.CFrame:PointToObjectSpace(position)
	local depth = -localPoint.Z
	return vec(550 + localPoint.X * 500 / depth, 364 - localPoint.Y * 500 / depth, depth)
end
function camera:ScreenPointToRay(x, y)
	return {
		Origin = self.CFrame.Position,
		Direction = self.CFrame:VectorToWorldSpace(vec((x - 550) / 500, -(y - 364) / 500, -1)).Unit,
	}
end
workspace.CurrentCamera = camera
local selected = newPart(workspace, vec(), vec(2, 2, 2))
Apps.Explorer =
	{ Selection = { List = { { Obj = selected } }, Changed = signal() }, SyncHistoryObject = function() end }
function Apps.Explorer.Selection:SetTable(values)
	self.List = values
	self.Changed:Fire()
end
Apps.History.Entries = {}
Apps.History.Index = 0
local beforeHistory = #Apps.History.Entries
local view = Apps.TransformGizmo.Create(Instance.new("ScreenGui"))
view:Update(camera, CFrame.new(), vec(2, 2, 2), "Move")
assert(#view.Handles == 20, "six arrows, three planes, free plane, four rotation rings and six scale handles")
local move
for _, h in ipairs(view.Handles) do
	if h.Kind == "Axis" and h.Axis == 1 and h.Sign == 1 then
		move = h
	end
end
local position = camera:WorldToScreenPoint(move.Start + (move.Finish - move.Start) * 0.5)
assert(view:HitTest(camera, position) == move, "move hit test uses screen coordinates including the top inset")
assert(
	move.Shaft.Color3.R == 0.8 and move.Shaft.Color3.G == 0 and move.Shaft.Color3.B == 0,
	"idle X axis uses the reference branch's dimmed red"
)
assert(
	not move.Shaft.AlwaysOnTop and move.OverlayShaft.AlwaysOnTop and move.OverlayShaft.Transparency == 0.45,
	"reference arrows use solid depth-tested and translucent on-top passes"
)
local hiddenDepthAxis
for _, h in ipairs(view.Handles) do
	if h.Kind == "Axis" and h.Axis == 3 then
		hiddenDepthAxis = h
		break
	end
end
assert(hiddenDepthAxis.Visible, "reference branch retains the depth-facing axes")
local allocated = #view.Instances
for _ = 1, 100 do
	view:Update(camera, CFrame.new(), vec(2, 2, 2), "Move", move)
end
assert(#view.Instances == allocated, "hover and frame updates reuse all native adornments")
view:Update(camera, CFrame.new(), vec(2, 2, 2), "Rotate")
local ring
for _, h in ipairs(view.Handles) do
	if h.Kind == "Rotate" and h.Axis == 3 then
		ring = h
	end
end
assert(
	ring.Ring.Angle == 360 and ring.Overlay.Angle == 360,
	"reference rotation uses complete rings in both depth passes"
)
local visibleRings = 0
for _, h in ipairs(view.Handles) do
	if h.Kind == "Rotate" and h.Visible then
		visibleRings += 1
	end
end
assert(visibleRings == 3, "reference rotation has three RGB rings and no outer white view ring")
local sample = ring.ProjectedRing[25]
assert(view:HitTest(camera, sample) ~= nil, "rotation ring pixels have a matching pick region")
view:Update(camera, CFrame.new(), vec(2, 2, 2), "Rotate", ring, nil, 15)
assert(
	#view.Ticks == 24 and view.Ticks[1].Visible,
	"hovering a complete ring renders snap ticks at the configured angle"
)
ring.DragStart = vec(1, 0, 0)
ring.DragAngle = math.pi * 0.5
view:Update(camera, CFrame.new(), vec(2, 2, 2), "Rotate", ring, ring, 15)
assert(
	ring.Ring.Angle == 360 and view.Sweep.Visible and view.Sweep.Angle == 90,
	"active rotation displays its complete ring and measured sweep"
)
for _, h in ipairs(view.Handles) do
	if h.Kind == "Rotate" and h ~= ring then
		assert(not h.Visible, "inactive rotation rings are hidden during the gesture")
	end
end
view:Update(camera, CFrame.new(), vec(2, 2, 2), "Scale")
local scale
for _, h in ipairs(view.Handles) do
	if h.Kind == "Scale" and h.Axis == 1 and h.Sign == 1 then
		scale = h
	end
end
assert(
	view:HitTest(camera, camera:WorldToScreenPoint(scale.Position)) == scale,
	"scale spheres are pickable at their rendered center"
)
view:Hide()
assert(view:HitTest(camera, position) == nil, "hidden handles never capture input")
view:Destroy()
local tools = Apps.TransformTools
tools.Init()
tools.SetTool("Move")
local oldMenuApps = Main.MenuApps
local pickerOn, pickerStarts, pickerStops = false, 0, 0
Main.MenuApps = Main.MenuApps or {}
local oldPicker = Main.MenuApps["Click part to select"]
Main.MenuApps["Click part to select"] = {
	Enable = function()
		if pickerOn then
			return
		end
		pickerOn = true
		pickerStarts += 1
		tools.SetWorldSelection(true)
	end,
	Disable = function()
		if not pickerOn then
			return
		end
		pickerOn = false
		pickerStops += 1
		tools.SetWorldSelection(false)
	end,
}
tools.SetTool("Select")
assert(
	pickerOn and tools.WorldSelection and tools.Toolbar.Select.BackgroundTransparency == 0,
	"toolbar Select activates the shared menu picker once"
)
Main.MenuApps["Click part to select"].Disable()
assert(
	not tools.WorldSelection and tools.Toolbar.Select.BackgroundTransparency == 1 and pickerStops == 1,
	"menu deselection clears toolbar selection and world picking"
)
Main.MenuApps["Click part to select"].Enable()
assert(
	tools.WorldSelection and tools.Toolbar.Select.BackgroundTransparency == 0 and pickerStarts == 2,
	"menu enable restores toolbar selection without recursive duplicate activation"
)
Main.MenuApps["Click part to select"] = oldPicker
Main.MenuApps = oldMenuApps
tools.SetTool("Move")
local pickedTarget, pickCalls = nil, 0
Apps.Explorer.SelectObject = function(target)
	pickedTarget = target
	pickCalls += 1
	return target ~= nil
end
Apps.Explorer.PickWorld = function(position)
	assert(position.X == 10 and position.Y == 100)
	return Apps.Explorer.SelectObject(Main.Mouse.Target)
end
local parentModel = Instance.new("Model", workspace)
local childPart = newPart(parentModel, vec(8, 0, 0), vec(2, 2, 2))
local oldTarget = Main.Mouse.Target
Main.Mouse.Target = childPart
tools.SetTool("Select")
service.UserInputService.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = vec(10, 100, 0) })
assert(
	pickedTarget == childPart and pickCalls == 1,
	"transform selection delegates the exact hit instead of promoting its parent Model"
)
modifiers[Enum.KeyCode.LeftShift] = true
modifiers[Enum.KeyCode.LeftControl] = true
service.UserInputService.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = vec(10, 100, 0) })
assert(
	pickedTarget == childPart and pickCalls == 2,
	"transform picker does not impose separate Shift/Ctrl selection rules"
)
modifiers[Enum.KeyCode.LeftShift] = false
modifiers[Enum.KeyCode.LeftControl] = false
tools.SetTool("Move")
tools.SetWorldSelection(false)
service.UserInputService.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = vec(10, 100, 0) })
assert(pickCalls == 2, "disabling click-to-select also stops transform mode's ordinary world picks")
Main.Mouse.Target = oldTarget
tools.SetTool("Move")
assert(tools.Toolbar.Snapping.RotateSnapUnit.TextSize == 18, "degree unit is readable alongside the angle field")
assert(tools.Toolbar.Move.Icon.Size == UDim2.fromOffset(24, 24), "48px ribbon PNGs display at exact half size")
assert(
	tools.Toolbar.Move.Icon.Image == "native/transform/ribbon/move",
	"new ribbon key cannot reuse a cached legacy toolbar PNG"
)
for _, name in ipairs({ "Options", "Hide", "Space" }) do
	local button = tools.Toolbar[name]
	button.MouseEnter:Fire()
	assert(button.BackgroundTransparency == 0, "toolbar button highlights on enter")
	button.MouseLeave:Fire()
	assert(button.BackgroundTransparency == 1, "all non-toggle toolbar buttons clear hover on leave")
end
tools.Toolbar.Move.MouseEnter:Fire()
tools.Toolbar.Move.MouseLeave:Fire()
assert(tools.Toolbar.Move.BackgroundTransparency == 0, "selected tool remains selected after hover leaves")
tools.Toolbar.Options.MouseButton1Click:Fire()
tools.Toolbar.Options.MouseEnter:Fire()
tools.Toolbar.Options.MouseLeave:Fire()
assert(
	tools.Toolbar.Snapping.Visible and tools.Toolbar.Options.BackgroundTransparency == 1,
	"open snapping popover does not latch the options hover"
)
tools.Toolbar.Options.MouseButton1Click:Fire()
local originalToolbarPosition = tools.Toolbar.Position
local toolbarHistory = #Apps.History.Entries
tools.Toolbar.DragHandle.InputBegan:Fire({
	UserInputType = Enum.UserInputType.MouseButton1,
	Position = vec(100, 100, 0),
})
assert(
	action(
		nil,
		Enum.UserInputState.Begin,
		{ UserInputType = Enum.UserInputType.MouseButton1, Position = vec(100, 100, 0) }
	)
			== Enum.ContextActionResult.Sink
		and not tools.Dragging,
	"toolbar dragging captures input without starting an object gesture"
)
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(180, 40, 0),
})
assert(
	tools.Toolbar.Position == UDim2.fromOffset(630, 716),
	"toolbar follows pointer delta while preserving its anchor and inset independence"
)
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(10000, 10000, 0),
})
assert(tools.Toolbar.Position == UDim2.fromOffset(930, 800), "toolbar stays within viewport bounds")
service.UserInputService.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
local droppedPosition = tools.Toolbar.Position
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(50, 50, 0),
})
Apps.Explorer.Selection.Changed:Fire()
assert(
	tools.Toolbar.Position == droppedPosition
		and #Apps.History.Entries == toolbarHistory
		and selected.CFrame.Position == vec(),
	"toolbar movement stops on release, survives selection refresh and never edits the object or history"
)
local touch = { UserInputType = Enum.UserInputType.Touch, Position = vec(100, 100, 0) }
tools.Toolbar.DragHandle.InputBegan:Fire(touch)
touch.Position = vec(-10000, -10000, 0)
service.UserInputService.InputChanged:Fire(touch)
assert(tools.Toolbar.Position == UDim2.fromOffset(170, 36), "touch dragging clamps to the upper-left screen edge")
service.UserInputService.InputEnded:Fire(touch)
tools.Toolbar.Options.MouseButton1Click:Fire()
assert(tools.Toolbar.Snapping.Position.Y.Offset == 44, "snapping popover opens below a toolbar moved to the top edge")
tools.Toolbar.Options.MouseButton1Click:Fire()
tools.Toolbar.Position = originalToolbarPosition
assert(
	keyAction(nil, Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.Two }) == Enum.ContextActionResult.Sink,
	"active tool shortcuts do not also equip gameplay tools"
)
assert(
	keyAction(nil, Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.L }) == Enum.ContextActionResult.Pass,
	"ordinary unmodified gameplay keys remain available"
)
service.RunService.RenderStepped:Fire()
local gizmo = tools.Gizmo
for _, h in ipairs(gizmo.Handles) do
	if h.Kind == "Axis" and h.Axis == 1 and h.Sign == 1 then
		move = h
	end
end
local start = camera:WorldToScreenPoint(move.Start + (move.Finish - move.Start) * 0.5)
pointer = Vector2.new(start.X, start.Y + 36)
service.RunService.RenderStepped:Fire()
assert(
	gizmo.Hover == move and move.HoverWeight == 1 and not gizmo.Animating,
	"raw mouse position converts through nonzero inset and hover feedback snaps immediately"
)
local down = { UserInputType = Enum.UserInputType.MouseButton1, Position = start }
local result = action(nil, Enum.UserInputState.Begin, down)
assert(result == Enum.ContextActionResult.Sink and tools.Dragging, "native action captures only a picked handle")
assert(
	action(nil, Enum.UserInputState.Begin, down) == Enum.ContextActionResult.Sink and tools.Dragging,
	"a second left press is captured without cancelling the gesture"
)
service.UserInputService.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton2 })
assert(tools.Dragging, "mouse buttons never cancel a transformation")
Apps.Explorer.Selection:SetTable({})
assert(
	tools.Dragging and Apps.Explorer.Selection.List[1].Obj == selected,
	"incidental selection changes cannot cancel an active gesture"
)
tools.SetTool("Rotate")
assert(tools.Tool == "Move" and tools.Dragging, "toolbar clicks cannot switch tools mid-gesture")
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(start.X + 50, start.Y, 0),
})
service.RunService.RenderStepped:Fire()
assert(
	selected.CFrame.Position.X > 1.9 and selected.CFrame.Position.X < 2.1,
	"moving the axis handle applies a world-space delta"
)
assert(
	tools.Readout.Visible and tools.Readout.Size.X.Offset < 100 and tools.Readout.Position.Y.Scale == 0,
	"move measurement uses a compact screen-space label attached to the handle"
)
assert(#Apps.History.Entries == beforeHistory, "drag previews do not append history")
service.UserInputService.InputEnded:Fire({
	UserInputType = Enum.UserInputType.MouseButton1,
	Position = vec(start.X + 75, start.Y, 0),
})
assert(
	not tools.Dragging and #Apps.History.Entries == beforeHistory + 1,
	"release commits exactly one history operation"
)
assert(
	math.abs(selected.CFrame.Position.X - 3) < 1e-6,
	"final pointer position is applied on release before committing"
)
assert(Apps.History.Undo())
assert(selected.CFrame.Position == vec(), "controller commits use real History undo")
service.RunService.RenderStepped:Fire()
local origin = camera:WorldToScreenPoint(move.Start + (move.Finish - move.Start) * 0.5)
action(nil, Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.MouseButton1, Position = origin })
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(origin.X + 50, origin.Y, 0),
})
service.RunService.RenderStepped:Fire()
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard })
assert(
	not tools.Dragging and selected.CFrame.Position == vec(),
	"Escape cancels the gesture and restores its starting transform"
)
local denied = action(
	nil,
	Enum.UserInputState.Begin,
	{ UserInputType = Enum.UserInputType.MouseButton1, Position = vec(950, 400, 0) }
)
assert(denied == Enum.ContextActionResult.Pass and not tools.Dragging, "Dex windows block gizmo input")
local geometryCalls = 0
local boundsOriginal = Apps.TransformSession.Bounds
Apps.TransformSession.Bounds = function(...)
	geometryCalls += 1
	return boundsOriginal(...)
end
for _ = 1, 100 do
	service.RunService.RenderStepped:Fire()
end
assert(geometryCalls <= 1, "stationary selection does not recalculate bounds on every display frame")
tools.Snapping = true
tools.MoveSnap = 1
service.RunService.RenderStepped:Fire()
origin = camera:WorldToScreenPoint(move.Start + (move.Finish - move.Start) * 0.5)
action(nil, Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.MouseButton1, Position = origin })
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(origin.X + 16, origin.Y, 0),
})
service.RunService.RenderStepped:Fire()
assert(math.abs(selected.CFrame.Position.X - 1) < 1e-6, "movement uses the configured snap increment")
modifiers[Enum.KeyCode.LeftShift] = true
service.RunService.RenderStepped:Fire()
assert(
	math.abs(selected.CFrame.Position.X - 0.64) < 1e-6,
	"Shift temporarily disables snapping without another pointer event"
)
tools.Cancel()
modifiers[Enum.KeyCode.LeftShift] = false
tools.SetTool("Rotate")
service.RunService.RenderStepped:Fire()
local rotating
for _, h in ipairs(gizmo.Handles) do
	if h.Kind == "Rotate" and h.Axis == 3 then
		rotating = h
	end
end
local sampleStart = rotating.ProjectedRing[13]
local sampleEnd = rotating.ProjectedRing[21]
tools.RotateSnap = 15
action(nil, Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.MouseButton1, Position = sampleStart })
assert(tools.Dragging, "rotation ring begins a production gesture")
service.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = sampleEnd })
service.RunService.RenderStepped:Fire()
assert(selected.CFrame.RightVector ~= vec(1, 0, 0), "rotation ring updates object orientation")
tools.Cancel()
assert(selected.CFrame.RightVector == vec(1, 0, 0), "rotation cancellation restores orientation")

-- Drive the real angle-unwrapping controller through full turns in both
-- directions, independently of camera-ray precision at ring intersections.
local rayPlaneOriginal = Apps.TransformSession.RayPlane
local hitTestOriginal = gizmo.HitTest
local theta = 0
Apps.TransformSession.RayPlane = function()
	return vec(math.cos(theta), math.sin(theta), 0)
end
gizmo.HitTest = function()
	return rotating
end
tools.Snapping = false
for _, direction in ipairs({ 1, -1 }) do
	theta = 0
	service.RunService.RenderStepped:Fire()
	action(
		nil,
		Enum.UserInputState.Begin,
		{ UserInputType = Enum.UserInputType.MouseButton1, Position = vec(650, 364, 0) }
	)
	assert(tools.Dragging, "rotation readout fixture begins a real gesture")
	for step = 1, 13 do
		theta = direction * step * math.pi / 4
		service.UserInputService.InputChanged:Fire({
			UserInputType = Enum.UserInputType.MouseMovement,
			Position = vec(650 + step, 364, 0),
		})
		service.RunService.RenderStepped:Fire()
		local expected = (step * 45) % 360
		assert(
			tools.Readout.Text == string.format("%.3f", expected),
			"rotation readout is positive and wraps at each full turn"
		)
		assert(
			(selected.CFrame.RightVector - vec(math.cos(theta), math.sin(theta), 0)).Magnitude < 1e-6,
			"wrapped UI preserves signed continuous object rotation"
		)
		assert(
			math.abs(rotating.DragAngle) <= 2 * math.pi,
			"rotation sweep also resets instead of accumulating beyond one turn"
		)
	end
	tools.Cancel()
end
Apps.TransformSession.RayPlane = rayPlaneOriginal
gizmo.HitTest = hitTestOriginal
tools.SetTool("Rotate")
service.RunService.RenderStepped:Fire()
local crossing = rotating.ProjectedRing[17]
assert(
	action(nil, Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.MouseButton1, Position = crossing })
			== Enum.ContextActionResult.Sink
		and tools.Dragging,
	"ring intersections and edge-on grabs start instead of silently failing"
)
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(crossing.X + 30, crossing.Y + 30, 0),
})
service.RunService.RenderStepped:Fire()
assert(selected.CFrame ~= CFrame.new(), "edge-on rotation remains draggable using its screen tangent")
tools.Cancel()
tools.SetTool("Scale")
service.RunService.RenderStepped:Fire()
for _, h in ipairs(gizmo.Handles) do
	if h.Kind == "Scale" and h.Axis == 1 and h.Sign == 1 then
		scale = h
	end
end
local scaleStart = camera:WorldToScreenPoint(scale.Position)
action(nil, Enum.UserInputState.Begin, { UserInputType = Enum.UserInputType.MouseButton1, Position = scaleStart })
assert(tools.Dragging, "scale sphere begins a production gesture")
service.UserInputService.InputChanged:Fire({
	UserInputType = Enum.UserInputType.MouseMovement,
	Position = vec(scaleStart.X + 50, scaleStart.Y, 0),
})
service.RunService.RenderStepped:Fire()
assert(
	selected.Size == vec(4, 2, 2) and selected.CFrame.Position == vec(1, 0, 0),
	"scale handle resizes one face while keeping its opposite face stationary"
)
assert(tools.Readout.Text == "4.000", "scale measurement displays the resized dimension rather than drag distance")
local centerPoint = camera:WorldToScreenPoint(selected.CFrame.Position)
assert(
	tools.Readout.Position.X.Offset == math.floor(centerPoint.X + 0.5)
		and tools.Readout.Position.Y.Offset == math.floor(centerPoint.Y + 36 + 0.5),
	"inset-independent measurement overlay stays centered on the object"
)
tools.Cancel()
assert(
	selected.Size == vec(2, 2, 2) and selected.CFrame.Position == vec(),
	"scale cancellation restores size and position"
)
tools.SetEnabled(false)
assert(not tools.Toolbar.Visible and not gizmo.Visible, "disabled tools hide their toolbar and world handles")
local largeModel = Instance.new("Model", workspace)
local modelChild = newPart(largeModel, vec(), vec(2, 2, 2))
local originalDescendants = methods.GetDescendants
local walks = 0
methods.GetDescendants = function(self)
	if self == largeModel then
		walks += 1
	end
	return originalDescendants(self)
end
Apps.Explorer.Selection:SetTable({ { Obj = largeModel } })
assert(walks == 0, "disabled transform tools do not walk selected models")
local savedGuiTools, savedMenu = Apps.GuiTransformTools, Main.MenuApps
local uiEnabled, menuEnabled = false, false
Apps.GuiTransformTools = {
	IsActive = function()
		return false
	end,
	SetEnabled = function(v)
		uiEnabled = v
	end,
	SetTool = function() end,
}
Main.MenuApps = { ["Transform Tools"] = {
	Enable = function(silent)
		assert(silent)
		menuEnabled = true
	end,
} }
tools.SetTool("Select")
assert(
	tools.Enabled and uiEnabled and menuEnabled,
	"tool activation restores UI controller and menu state after disabling"
)
assert(walks > 0 and tools.Toolbar.Visible, "enabling selects current geometry")
assert(modelChild._signals.Locked and not modelChild._signals.CFrame, "Select only watches transform eligibility")
methods.GetDescendants = originalDescendants
Apps.GuiTransformTools, Main.MenuApps = savedGuiTools, savedMenu
tools.SetEnabled(false)
Main.Shutdown()
assert(action == nil and keyAction == nil and gizmo.Destroyed, "shutdown releases input, view, and render connections")
print(
	"PASS: native transform handle geometry/picking, screen inset, cached view, production controller drag/release/cancel, UI exclusion, idle bounds and shutdown"
)

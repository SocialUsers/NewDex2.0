--!strict

local function near(a, b)
	return math.abs(a - b) < 1e-6
end
local function length(v)
	return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
end
local camera = Apps.PreviewCamera.Create()
for _, aspect in ipairs({ 0.25, 1, 4 }) do
	for _, radius in ipairs({ 0.01, 1, 1000 }) do
		camera:Fit(radius, aspect, true)
		local horizontal = math.atan(math.tan(math.rad(camera.FieldOfView / 2)) * aspect)
		local limiting = math.min(horizontal, math.rad(camera.FieldOfView / 2))
		assert(camera.Distance * math.sin(limiting) > radius, "entire bounding sphere fits both axes")
		local origin, direction = camera:Ray(400 * aspect, 400, 800 * aspect, 800)
		assert(
			near(length(direction), 1)
				and near(origin.X + direction.X * camera.Distance, 0)
				and near(origin.Y + direction.Y * camera.Distance, 0)
				and near(origin.Z + direction.Z * camera.Distance, 0),
			"center picking ray hits camera target at every aspect"
		)
	end
end
camera:Fit(10, 1, true)
local initial = camera.Distance
camera:Zoom(2)
assert(camera.Distance < initial, "wheel zoom is scale-relative")
camera:Zoom(1e4)
assert(camera.Distance == camera.Minimum, "zoom clamps before the camera crosses its target")
camera:Orbit(20, 1e5)
assert(camera.Pitch < math.pi / 2, "orbit cannot flip at poles")
camera:Pan(50, 20, 400)
local target = { camera.X, camera.Y, camera.Z }
camera:Resize(0.5)
assert(camera.X == target[1] and camera.Y == target[2] and camera.Z == target[3], "resize preserves panning")
local source = Instance.new("Model", workspace)
source.Name = "PreviewFixture"
source.Archivable = false
local original = Instance.new("Part", source)
original.Name = "Body"
original.Archivable = false
original.Size = vec(10, 10, 10)
original.CFrame = CFrame.new(500, 100, -200)
original.Anchored = false
original.CanQuery = false
original.Transparency = 0
local script = Instance.new("Script", source)
script.Archivable = false
local nested = Instance.new("Folder", source)
nested.Name = "Nested"
nested.Archivable = true
local detail = Instance.new("Part", nested)
detail.Name = "Detail"
detail.Archivable = true
detail.Size = vec(1, 1, 1)
detail.CFrame = CFrame.new(500, 100, -200)
detail.Transparency = 0
local sound = Instance.new("Sound", source)
sound.Archivable = true
local getChildren = methods.GetChildren
local childReads = 0
function methods:GetChildren()
	if self == source or self:IsDescendantOf(source) then
		childReads += 1
	end
	return getChildren(self)
end
local scene = Apps.PreviewScene.Build(source)
methods.GetChildren = getChildren
assert(childReads == 0, "copy mapping avoids per-instance calls into the live hierarchy")
assert(
	source.Archivable == false and original.Archivable == false and script.Archivable == false,
	"all non-archivable flags restore after a successful copy"
)
assert(
	original.CFrame.Position.X == 500
		and original.Anchored == false
		and original.CanQuery == false
		and script.Parent == source,
	"preview never moves, anchors, enables queries on, or removes scripts from the source"
)
assert(
	scene.PartCount == 2 and scene.Reverse[original].Anchored and scene.Reverse[original].CanQuery,
	"preview parts are independently safe and queryable"
)
assert(
	not scene.Reverse[script]:IsDescendantOf(scene.Model) and not scene.Reverse[sound]:IsDescendantOf(scene.Model),
	"scripts and audio are removed only from the snapshot"
)
local bounds = scene.Model:GetBoundingBox()
assert(near(bounds.Position.Magnitude, 0), "far-away source is recentered without changing source coordinates")
assert(#scene.Grid:GetChildren() == 42, "floor grid has a fixed geometry budget")
scene:SetGrid(true)
assert(scene.Grid.Parent == scene.World)
scene:SetGrid(false)
assert(scene.Grid.Parent == nil)
scene:Select(original)
assert(#scene.World.SelectionOutline:GetChildren() == 12, "selection outline has twelve edges")
local edge = scene.World.SelectionOutline:GetChildren()[1]
scene:Select(original)
assert(scene.World.SelectionOutline:GetChildren()[1] == edge, "reselecting a part keeps its outline")
scene:Select(nil)
assert(#scene.World.SelectionOutline:GetChildren() == 0, "empty picks clear the outline")
camera:Fit(scene.Radius, 1, true)
local origin, direction = camera:Ray(200, 200, 400, 400)
assert(scene:Pick(origin, direction, 1000) == original, "raycast result maps the visible clone back to its source part")
scene:Destroy()
assert(
	scene.World.Destroyed and scene.Grid.Destroyed and next(scene.Map) == nil,
	"scene disposal releases geometry and source maps"
)
local savedClone = methods.Clone
function methods:Clone()
	if self ~= source then
		return savedClone(self)
	end
	local transient = Instance.new("Part", source)
	transient.Name = "Transient"
	transient.Archivable = true
	transient.Size, transient.CFrame, transient.Transparency = original.Size, original.CFrame, 0
	original.Parent = nil
	original.Parent = source
	local copy = savedClone(self)
	transient:Destroy()
	return copy
end
local changing = Apps.PreviewScene.Build(source)
assert(
	changing.PartCount == 3 and changing.Reverse[original].Name == "Body",
	"changing child lists still render and match known parts"
)
assert(not changing.Map[changing.Reverse[source].Transient], "unmatched geometry does not pick an unrelated source")
changing:Destroy()
methods.Clone = savedClone
function methods:Clone()
	if self == source then
		error("synthetic clone failure")
	end
	return savedClone(self)
end
assert(
	not pcall(Apps.PreviewScene.Build, source)
		and not source.Archivable
		and not original.Archivable
		and not script.Archivable,
	"clone failure restores every temporary flag"
)
methods.Clone = savedClone
local viewer = Apps.ModelViewer
viewer.Init()
Apps.Explorer.GetNodes()[original] = { Obj = original }
assert(viewer.ViewModel(source), "viewer opens a preview")
local viewport = viewer.Viewport
local state = viewer.CameraState
assert(
	viewer.Footer.AbsoluteSize.Y == 22
		and viewer.Footer.Status.Text == "2 parts"
		and viewer.Footer.SourcePath.Text == source.Name,
	"compact footer shows count and short source name instead of paths and instructions"
)
assert(
	near(viewport.AbsolutePosition.Y + viewport.AbsoluteSize.Y, viewer.Footer.AbsolutePosition.Y),
	"larger viewport ends exactly at the compact status bar"
)
viewer.Footer.Help.MouseButton1Click:Fire()
assert(viewer.Help.Visible, "navigation help is available on demand")
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape })
assert(not viewer.Help.Visible, "Escape dismisses navigation help")
local toolbar = viewer.Window.GuiElems.Content.PreviewToolbar
toolbar.Light.MouseButton1Click:Fire()
assert(
	#viewer.ContextMenu.Items == 3 and viewer.ContextMenu.Items[1].Name == "Neutral",
	"lighting button opens a focused preset menu"
)
viewer.ContextMenu.Items[2].OnClick()
assert(viewer.Lighting == "Soft", "choosing a preset applies it directly")
toolbar.Background.MouseButton1Click:Fire()
assert(viewer.ContextMenu.Items[3].Name == "Transparent", "background options are discoverable without cycling")
local darkWidth = toolbar.Background.AbsoluteSize.X
viewer.SetBackground("Transparent")
assert(
	toolbar.Background.AbsoluteSize.X > darkWidth,
	"preset fields follow their text instead of retaining oversized fixed gaps"
)
for _, key in ipairs({ "Light", "Background" }) do
	local field = toolbar[key]
	local caption = field.Caption
	local arrow = field.DropdownArrow
	local textWidth =
		service.TextService:GetTextSize(caption.Text, caption.TextSize, caption.Font, Vector2.new(10000, 24)).X
	assert(
		caption.AbsolutePosition.X + textWidth <= arrow.AbsolutePosition.X
			and arrow.AbsolutePosition.X + 16 <= field.AbsolutePosition.X + field.AbsoluteSize.X,
		"dropdown captions and arrows have separate, non-overlapping bounds"
	)
	assert(not field:FindFirstChildOfClass("UIPadding"), "parent padding must not displace the dropdown arrow")
end
menuShows = 0
local selected = viewer.SelectAt(viewport.AbsoluteSize.X / 2, viewport.AbsoluteSize.Y / 2)
assert(
	selected == original and Apps.Explorer.LastViewed == original and Apps.Explorer.Selection.List[1].Obj == original,
	"preview click selects and reveals the actual source in Explorer"
)
local oldScene = viewer.Scene
local oldDistance = state.Distance
assert(
	not viewer.ViewModel(script) and viewer.Scene == oldScene and not oldScene.World.Destroyed,
	"invalid preview keeps the existing scene intact"
)
viewer.Zoom(2)
oldDistance = state.Distance
viewer.Refresh()
assert(
	viewer.Scene ~= oldScene and oldScene.World.Destroyed and near(state.Distance, oldDistance),
	"refresh replaces one snapshot and preserves the camera"
)
viewer.SetLighting("Flat")
assert(viewport.Ambient.R == 1 and viewport.LightColor.R == 0, "flat lighting preset")
viewer.SetBackground("Transparent")
assert(
	viewport.BackgroundTransparency == 1 and viewer.Window.GuiElems.Content.BackgroundTransparency == 1,
	"transparent background exposes the scene behind the window"
)
viewer.SetGrid(false)
assert(viewer.Scene.Grid.Parent == nil)
local writes = 0
local savedNewIndex = instMT.__newindex
instMT.__newindex = function(object, key, value)
	if object.Name == "PreviewCamera" and key == "CFrame" then
		writes += 1
	end
	return savedNewIndex(object, key, value)
end
service.RunService.RenderStepped:Fire(0.016)
writes = 0
for _ = 1, 10 do
	service.RunService.RenderStepped:Fire(0.016)
end
assert(writes == 0, "idle preview performs no camera writes")
viewer.AutoRotate = true
local spinYaw = state.Yaw
service.RunService.RenderStepped:Fire(0.05)
service.RunService.RenderStepped:Fire(0.05)
assert(near(state.Yaw - spinYaw, viewer.RotationSpeed * 0.1) and writes == 2, "auto rotation uses elapsed seconds")
viewer.AutoRotate = false
instMT.__newindex = savedNewIndex
local function event(kind, x, y, z)
	return { UserInputType = kind, Position = vec(x, y, z) }
end
local p, s = viewport.AbsolutePosition, viewport.AbsoluteSize
local cx, cy = p.X + s.X / 2, p.Y + s.Y / 2
local left = event(Enum.UserInputType.MouseButton1, cx, cy)
viewport.InputBegan:Fire(left)
local oldYaw = state.Yaw
service.UserInputService.InputChanged:Fire(event(Enum.UserInputType.MouseMovement, cx + 40, cy + 10))
service.UserInputService.InputEnded:Fire(event(Enum.UserInputType.MouseButton1, cx + 40, cy + 10))
assert(state.Yaw ~= oldYaw and viewer.Scene, "global mouse capture continues orbit outside the initiating GUI event")
local right = event(Enum.UserInputType.MouseButton2, cx, cy)
viewport.InputBegan:Fire(right)
service.UserInputService.InputEnded:Fire(right)
assert(menuShows == 1, "stationary right click opens the context menu")
local hasAutoUpdate, hasLighting = false, false
for _, item in ipairs(viewer.ContextMenu.Items) do
	assert(not item.Name:find("1/sec", 1, true), "menu labels omit scheduling details")
	if item.Name == "Enable Auto Update" then
		hasAutoUpdate = true
	end
	if item.Name == "Lighting" and item.Submenu and #item.Submenu == 3 then
		hasLighting = true
	end
end
assert(hasAutoUpdate and hasLighting, "plain action labels and grouped preset submenus")
viewport.InputBegan:Fire(right)
service.UserInputService.InputChanged:Fire(event(Enum.UserInputType.MouseMovement, cx + 20, cy))
service.UserInputService.InputEnded:Fire(event(Enum.UserInputType.MouseButton2, cx + 20, cy))
assert(menuShows == 1, "right-drag orbits without opening a context menu")
local a, b = event(Enum.UserInputType.Touch, cx - 30, cy), event(Enum.UserInputType.Touch, cx + 30, cy)
viewport.InputBegan:Fire(a)
viewport.InputBegan:Fire(b)
local oldDistance = state.Distance
service.UserInputService.InputChanged:Fire(event(Enum.UserInputType.MouseMovement, cx, cy))
assert(state.Distance == oldDistance, "mouse movement cannot drive a touch pinch")
a.Position = vec(cx - 60, cy)
service.UserInputService.InputChanged:Fire(a)
assert(state.Distance < oldDistance, "two-finger pinch zooms")
service.UserInputService.InputEnded:Fire(a)
service.UserInputService.InputEnded:Fire(b)
local count = viewer.Scene.World
local before = viewer.Scene
viewer.Window.OnDeactivate:Fire()
assert(viewer.Scene == before, "ordinary window focus loss retains its scene")
viewer.Window:Close()
assert(viewer.Scene == nil and count.Destroyed, "closing releases the WorldModel")
viewer.Window:Show()
assert(viewer.Scene and viewer.Scene.Source == source, "reopening restores the source preview")
viewer.AutoRefresh = true
local refreshed = viewer.Scene
service.RunService.RenderStepped:Fire(0.5)
assert(viewer.Scene == refreshed, "live refresh does not clone every frame")
service.RunService.RenderStepped:Fire(0.51)
assert(viewer.Scene == refreshed, "live refresh does not rebuild in the render callback")
flushTasks()
assert(viewer.Scene ~= refreshed and refreshed.World.Destroyed, "opt-in live refresh runs at most once per second")
viewer.Window.Minimized = true
viewer.Window.OnMinimize:Fire()
assert(viewer.Scene == nil, "minimizing releases the WorldModel")
viewer.Window.Minimized = false
viewer.Window.OnRestore:Fire()
assert(viewer.Scene, "restore recreates the preview")
viewer.StopViewModel()
assert(not viewer.IsViewing and viewer.Scene == nil, "stop clears the source and scene")
viewer.Window:Close()
viewer.Window:Show()
assert(viewer.Scene == nil, "stopped previews do not reopen stale models")
print(
	"PASS: preview camera fitting/rays, clone safety/failure recovery, grid/selection budgets, Explorer picking, gestures, refresh and window lifecycle"
)

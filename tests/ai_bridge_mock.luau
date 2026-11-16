--!strict

-- Adds engine-shaped values and services to the shared numerical/Instance doubles.
-- Production History, SelectionService, EditingService and TransformSession are
-- loaded by the Python harness; these fixtures do not replace their behavior.
service.Workspace = workspace
game.PlaceId = 123
game.GameId = 456
game.JobId = "test-client"
local rawTypeof = typeof
typeof = function(value)
	if getmetatable(value) == vectorMT then
		return "Vector3"
	end
	if getmetatable(value) == frameMT then
		return "CFrame"
	end
	if type(value) == "table" and rawget(value, "__bridgeType") then
		return value.__bridgeType
	end
	return rawTypeof(value)
end
local rawColor = Color3.new
Color3.new = function(...)
	local value = rawColor(...)
	value.__bridgeType = "Color3"
	return value
end
local materialType = setmetatable({}, {
	__tostring = function()
		return "Enum.Material"
	end,
})
Enum.Material = { Plastic = { Name = "Plastic", EnumType = materialType, __bridgeType = "EnumItem" } }
baseFrameIndex.GetComponents = function(cf)
	return cf.Position.X,
		cf.Position.Y,
		cf.Position.Z,
		cf.RightVector.X,
		cf.UpVector.X,
		cf.ZVector.X,
		cf.RightVector.Y,
		cf.UpVector.Y,
		cf.ZVector.Y,
		cf.RightVector.Z,
		cf.UpVector.Z,
		cf.ZVector.Z
end
baseFrameIndex.PointToWorldSpace = function(cf, value)
	return cf * value
end
function methods:GetAttributes()
	local result = {}
	for name, value in pairs(self._props) do
		if string.sub(name, 1, 5) == "attr_" then
			result[string.sub(name, 6)] = value
		end
	end
	return result
end
local tagStore = setmetatable({}, { __mode = "k" })
service.CollectionService = {
	GetTags = function(_, object)
		local tags = {}
		for tag in pairs(tagStore[object] or {}) do
			tags[#tags + 1] = tag
		end
		table.sort(tags)
		return tags
	end,
	HasTag = function(_, object, tag)
		return tagStore[object] and tagStore[object][tag] or false
	end,
	AddTag = function(_, object, tag)
		tagStore[object] = tagStore[object] or {}
		tagStore[object][tag] = true
	end,
	RemoveTag = function(_, object, tag)
		if tagStore[object] then
			tagStore[object][tag] = nil
		end
	end,
}
Apps.Signal = { new = signal }
local selectedNodes = {}
Apps.Explorer = {
	GetNodes = function()
		return selectedNodes
	end,
	IsInferredObject = function(object)
		return object ~= nil and object.Inferred == true
	end,
	IsReadOnlyInferenceObject = function(object)
		return object ~= nil and object.Inferred == true
	end,
	CaptureHistorySelection = function()
		return {}
	end,
	RestoreHistorySelection = function() end,
	SyncHistoryObject = function(object)
		selectedNodes[object] = selectedNodes[object] or { Obj = object }
	end,
}
local dexGui = Instance.new("ScreenGui", game)
Main.IsDexGuiObject = function(object)
	return object == dexGui or object:IsDescendantOf(dexGui)
end
API = { Classes = {} }
local function class(name, super, properties, tags)
	local list = {}
	for _, property in ipairs(properties or {}) do
		list[#list + 1] = { Name = property, Tags = property == "ClassName" and { ReadOnly = true } or {} }
	end
	API.Classes[name] = { Name = name, Superclass = super, Properties = list, Tags = tags or {} }
end
class("Instance", nil, { "Name", "ClassName", "Parent" })
class("Part", "Instance", { "CFrame", "Size", "Anchored", "Transparency", "Color", "Source" })
class("Folder", "Instance", {})
class("Model", "Instance", {})
class("Workspace", "Instance", {}, { Service = true })
class("Camera", "Instance", { "CFrame", "Focus", "FieldOfView", "CameraType", "CameraSubject" })
RMD = { Classes = {} }
local localPlayer = Instance.new("Player", game)
localPlayer.Name = "Tester"
localPlayer.DisplayName = "Test Player"
localPlayer.UserId = 1234
local character = Instance.new("Model", workspace)
localPlayer.Character = character
service.Players = {
	LocalPlayer = localPlayer,
	GetPlayers = function()
		return { localPlayer }
	end,
	GetPlayerByUserId = function(_, id)
		return id == 1234 and localPlayer or nil
	end,
}
local camera = Instance.new("Camera", workspace)
camera.CFrame = CFrame.new()
camera.Focus = CFrame.new()
camera.FieldOfView = 70
camera.CameraSubject = character
camera.CameraType = Enum.Material.Plastic
workspace.CurrentCamera = camera
task.spawn = function(fn)
	local thread = coroutine.create(fn)
	local ok, why = coroutine.resume(thread)
	assert(ok, why)
	return thread
end
task.cancel = function(thread)
	if coroutine.status(thread) ~= "dead" then
		coroutine.close(thread)
	end
end
task.wait = function()
	coroutine.yield()
end
local function initBridgeSelection()
	local store = Apps.SelectionService.NewStore()
	Apps.Explorer.Services = {
		Selection = Apps.SelectionService.Bind(store, function(object)
			if not selectedNodes[object] then
				selectedNodes[object] = { Obj = object }
			end
			return selectedNodes[object]
		end),
	}
end

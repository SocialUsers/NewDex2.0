--!strict

-- Numerical and lifecycle double for preview integration. This does not render
-- a Roblox ViewportFrame or establish engine raycast/mesh rendering fidelity.
local vectorMT = {}
vectorMT.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	end
	if k == "Unit" then
		return v / v.Magnitude
	end
end
local function vec(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMT)
end
vectorMT.__add = function(a, b)
	return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
vectorMT.__sub = function(a, b)
	return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
vectorMT.__unm = function(v)
	return vec(-v.X, -v.Y, -v.Z)
end
vectorMT.__mul = function(a, b)
	if type(a) == "number" then
		a, b = b, a
	end
	return vec(a.X * b, a.Y * b, a.Z * b)
end
vectorMT.__div = function(v, s)
	return vec(v.X / s, v.Y / s, v.Z / s)
end
Vector3.new = vec
local frameMT = {}
local function frame(position, right, up, back)
	return setmetatable({
		Position = position,
		RightVector = right or vec(1, 0, 0),
		UpVector = up or vec(0, 1, 0),
		BackVector = back or vec(0, 0, 1),
	}, frameMT)
end
local function dot(a, b)
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
local function cross(a, b)
	return vec(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
local function rotate(cf, v)
	return cf.RightVector * v.X + cf.UpVector * v.Y + cf.BackVector * v.Z
end
frameMT.__index = {
	PointToObjectSpace = function(cf, v)
		v = v - cf.Position
		return vec(dot(cf.RightVector, v), dot(cf.UpVector, v), dot(cf.BackVector, v))
	end,
	VectorToObjectSpace = function(cf, v)
		return vec(dot(cf.RightVector, v), dot(cf.UpVector, v), dot(cf.BackVector, v))
	end,
}
frameMT.__mul = function(a, b)
	if getmetatable(b) == vectorMT then
		return a.Position + rotate(a, b)
	end
	return frame(a * b.Position, rotate(a, b.RightVector), rotate(a, b.UpVector), rotate(a, b.BackVector))
end
CFrame = {
	new = function(x, y, z)
		return frame(type(x) == "table" and x or vec(x, y, z))
	end,
}
CFrame.lookAt = function(origin, target)
	local forward = (target - origin).Unit
	local right = cross(forward, vec(0, 1, 0)).Unit
	return frame(origin, right, cross(right, forward), -forward)
end
RaycastParams = {
	new = function()
		return {}
	end,
}
local originalIsA = methods.IsA
function methods:IsA(class)
	return originalIsA(self, class)
		or class == "LuaSourceContainer"
			and (self.ClassName == "Script" or self.ClassName == "LocalScript" or self.ClassName == "ModuleScript")
end
local originalDestroy = methods.Destroy
function methods:Destroy()
	for _, child in ipairs(self:GetChildren()) do
		child:Destroy()
	end
	originalDestroy(self)
end
function methods:GetBoundingBox()
	local minimum, maximum = vec(math.huge, math.huge, math.huge), vec(-math.huge, -math.huge, -math.huge)
	for _, object in ipairs(self:GetDescendants()) do
		if object:IsA("BasePart") then
			for _, x in ipairs({ -1, 1 }) do
				for _, y in ipairs({ -1, 1 }) do
					for _, z in ipairs({ -1, 1 }) do
						local p = object.CFrame
							* vec(object.Size.X * x / 2, object.Size.Y * y / 2, object.Size.Z * z / 2)
						minimum = vec(math.min(minimum.X, p.X), math.min(minimum.Y, p.Y), math.min(minimum.Z, p.Z))
						maximum = vec(math.max(maximum.X, p.X), math.max(maximum.Y, p.Y), math.max(maximum.Z, p.Z))
					end
				end
			end
		end
	end
	assert(minimum.X < math.huge, "No geometry")
	return CFrame.new((minimum + maximum) / 2), maximum - minimum
end
function methods:GetPivot()
	return CFrame.new()
end
function methods:PivotTo(offset)
	for _, object in ipairs(self:GetDescendants()) do
		if object:IsA("BasePart") then
			object.CFrame = offset * object.CFrame
		end
	end
end
function methods:Raycast(origin, direction, params)
	local closest, hit = math.huge, nil
	for _, object in ipairs(params.FilterDescendantsInstances[1]:GetDescendants()) do
		if object:IsA("BasePart") and object.CanQuery ~= false then
			local point = object.CFrame:PointToObjectSpace(origin)
			local ray = object.CFrame:VectorToObjectSpace(direction)
			local near, far = 0, 1
			for _, axis in ipairs({ "X", "Y", "Z" }) do
				local bound = object.Size[axis] / 2
				if math.abs(ray[axis]) < 1e-10 then
					if math.abs(point[axis]) > bound then
						far = -1
					end
				else
					local a, b = (-bound - point[axis]) / ray[axis], (bound - point[axis]) / ray[axis]
					near = math.max(near, math.min(a, b))
					far = math.min(far, math.max(a, b))
				end
			end
			if near <= far and near < closest then
				closest = near
				hit = object
			end
		end
	end
	return hit and { Instance = hit } or nil
end
service.UserInputService.WindowFocusReleased = signal()
service.RunService = { RenderStepped = signal() }
Lib.StudioFont = Enum.Font.BuilderSans
Lib.Window = {
	new = function()
		local window = {
			Closed = true,
			Minimized = false,
			OnActivate = signal(),
			OnDeactivate = signal(),
			OnMinimize = signal(),
			OnRestore = signal(),
		}
		local screen = Instance.new("ScreenGui")
		local content = Instance.new("Frame", screen)
		content.Size = UDim2.fromOffset(600, 400)
		window.Gui = screen
		window.GuiElems = { Content = content }
		function window:SetTitle(value)
			self.Title = value
		end
		function window:Resize(x, y)
			content.Size = UDim2.fromOffset(x, y)
		end
		function window:IsVisible()
			return not self.Closed and not self.Hidden
		end
		function window:Show()
			local old = self.Closed
			self.Closed = false
			if old then
				self.OnActivate:Fire()
			end
		end
		function window:Close()
			self.Closed = true
			self.OnDeactivate:Fire()
		end
		return window
	end,
}
Apps = {}
local menuShows = 0
Apps.ContextMenu = {
	IsAnyShown = function()
		return false
	end,
	new = function()
		local menu = { Items = {} }
		function menu:Clear()
			self.Items = {}
		end
		function menu:ApplyTheme() end
		function menu:Add(item)
			self.Items[#self.Items + 1] = item
		end
		function menu:AddDivider() end
		function menu:Show()
			menuShows += 1
		end
		function menu:Hide() end
		function menu:Destroy()
			self.Destroyed = true
		end
		return menu
	end,
}
local previewNodes = {}
Apps.Explorer = {
	Selection = { List = {}, Changed = signal() },
	GetNodes = function()
		return previewNodes
	end,
}
function Apps.Explorer.GetInstancePath(object)
	return object.Name
end
function Apps.Explorer.SelectService(object)
	Apps.Explorer.Selection.List = { { Obj = object } }
	Apps.Explorer.Selection.Changed:Fire()
end
function Apps.Explorer.ViewObj(object)
	Apps.Explorer.LastViewed = object
end

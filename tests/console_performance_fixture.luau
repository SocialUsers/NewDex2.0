--!strict

local function signal()
	local s = { listeners = {} }
	function s:Connect(fn)
		local connection = { connected = true }
		function connection:Disconnect()
			self.connected = false
		end
		table.insert(s.listeners, { connection, fn })
		return connection
	end
	function s:Fire(...)
		for _, item in ipairs(self.listeners) do
			if item[1].connected then
				item[2](...)
			end
		end
	end
	return s
end

local tasks = {}
task = {
	defer = function(fn)
		table.insert(tasks, coroutine.create(fn))
	end,
	wait = coroutine.yield,
}
local function flushFrame()
	local frame = tasks
	tasks = {}
	for _, thread in ipairs(frame) do
		local ok, err = coroutine.resume(thread)
		assert(ok, err)
		if coroutine.status(thread) ~= "dead" then
			table.insert(tasks, thread)
		end
	end
end
local function drain()
	for _ = 1, 100 do
		if #tasks == 0 then
			return
		end
		flushFrame()
	end
	error("output did not settle")
end

Enum = setmetatable({}, {
	__index = function(enums, key)
		local items = setmetatable({}, {
			__index = function(_, name)
				return name
			end,
		})
		enums[key] = items
		return items
	end,
})
UDim = {
	new = function()
		return 0
	end,
}
local function vector(x, y)
	return { X = x, Y = y }
end
Vector2 = { new = vector }
UDim2 = {
	new = function(_, x, _, y)
		return vector(x, y)
	end,
	fromOffset = vector,
	fromScale = vector,
}
local color = {
	ToHex = function()
		return "FFFFFF"
	end,
}
Color3 = {
	fromRGB = function()
		return color
	end,
}
DateTime = {
	now = function()
		return { UnixTimestampMillis = 120 }
	end,
}

local instances = {}
local function create(class, props)
	props = props or {}
	props.ClassName = class
	props.AbsolutePosition = vector(0, 0)
	props.AbsoluteSize = vector(100, 22)
	props.AbsoluteWindowSize = vector(300, 100)
	props.AbsoluteContentSize = vector(300, 300)
	props.Activated = signal()
	props.Focused = signal()
	props.FocusLost = signal()
	props.MouseEnter = signal()
	props.MouseLeave = signal()
	local signals = {}
	function props:GetPropertyChangedSignal(name)
		signals[name] = signals[name] or signal()
		return signals[name]
	end
	function props:Destroy()
		self.Destroyed = true
		self.Parent = nil
	end
	function props:IsFocused()
		return false
	end
	table.insert(instances, props)
	return props
end
local function named(name)
	for _, instance in ipairs(instances) do
		if instance.Name == name and not instance.Destroyed then
			return instance
		end
	end
	error("missing " .. name)
end
local function rows()
	local entries = {}
	for _, instance in ipairs(instances) do
		if instance.Name == "Message" and not instance.Destroyed then
			table.insert(entries, instance)
		end
	end
	table.sort(entries, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return entries
end

local LogService = { MessageOut = signal() }
local input = { InputBegan = signal(), InputEnded = signal(), InputChanged = signal() }
function input:IsKeyDown()
	return false
end
game = {
	GetService = function(_, name)
		return name == "LogService" and LogService or input
	end,
}
local main = { Alive = true, connections = {}, cleanups = {} }
function main.TrackSignal(s, fn)
	table.insert(main.connections, s:Connect(fn))
end
function main.AddCleanup(fn)
	table.insert(main.cleanups, fn)
end
function main.GetStudioAsset()
	return "asset"
end
local visible = false
local window = {
	GuiElems = { Content = create("Frame") },
	OnActivate = signal(),
	OnRestore = signal(),
	OnDeactivate = signal(),
	IsContentVisible = function()
		return visible
	end,
	SetTitle = function(self, title)
		self.Title = title
	end,
	SetResizeHandleStyle = function() end,
	Resize = function() end,
}
local lib = {
	Window = {
		new = function()
			return window
		end,
	},
	StudioText = function() end,
	StudioTooltip = function() end,
}
local menu = {}
function menu:ApplyTheme() end
function menu:Clear()
	self.items = {}
end
function menu:Add(item)
	self.items[item.Text] = item
end
function menu:AddDivider() end
function menu:Show()
	self.Shown = true
end
function menu:Hide()
	self.Shown = false
end
function menu:Destroy()
	self.destroyed = true
end
local apps = { ContextMenu = {
	new = function()
		return menu
	end,
} }
local theme = setmetatable({}, {
	__index = function()
		return color
	end,
})

local module = (function()
	-- PRODUCTION
end)()
module.InitDeps({ Main = main, Lib = lib, Apps = apps, Settings = { Theme = theme }, createSimple = create })
local console = module.Main()
console.Init()
console.Init()
assert(window.Title == "Console" and #LogService.MessageOut.listeners == 1)

local output = named("Output")
local filter = named("Filter")
for i = 1, 5000 do
	LogService.MessageOut:Fire("message" .. i, Enum.MessageType.MessageOutput)
end
assert(#tasks == 0 and #rows() == 0, "hidden Console defers all row creation")
visible = true
window.OnActivate:Fire()
flushFrame()
assert(#rows() == 32, "opening a backlog creates a bounded batch")
drain()
local recent = rows()
assert(#recent == 500 and recent[1].Text:find("message4501", 1, true), "keeps the newest 500 messages")

for i = 1, 3000 do
	LogService.MessageOut:Fire("visible" .. i, Enum.MessageType.MessageWarning)
end
LogService.MessageOut:Fire("warning [marker] <value>&", Enum.MessageType.MessageWarning)
LogService.MessageOut:Fire("error [marker]", Enum.MessageType.MessageError)
drain()
assert(#rows() == 500 and #LogService.MessageOut.listeners == 1, "a burst keeps rows and subscriptions bounded")
filter.Text = "[MARKER]"
filter:GetPropertyChangedSignal("Text"):Fire()
drain()
assert(#rows() == 2 and rows()[1].Text:find("&lt;value&gt;&amp;", 1, true), "filter is case insensitive and literal")
named("MessageType").Activated:Fire()
menu.items.Warning.OnClick()
menu:Hide()
drain()
assert(#rows() == 1 and rows()[1].Text:find("warning", 1, true), "type and text filters intersect")
rows()[1].Focused:Fire()
assert(rows()[1].Text:find("<value>&", 1, true), "copyable text preserves special characters")
rows()[1].FocusLost:Fire()

named("Options").Activated:Fire()
menu.items["Show Timestamp"].OnClick()
menu.items["Show Context"].OnClick()
menu.items["Increase Text Size"].OnClick()
drain()
assert(
	rows()[1].TextSize == 15 and rows()[1].Text:find("Client", 1, true) and not rows()[1].Text:find(".120", 1, true),
	"view options update rows"
)

local command = named("Command")
local syntax = named("CommandSyntax")
command.Focused:Fire()
command.Text = "local value = 42"
command:GetPropertyChangedSignal("Text"):Fire()
assert(syntax.Visible and syntax.Text:find("<font", 1, true), "command highlights while focused")
command.Text = ""
command:GetPropertyChangedSignal("Text"):Fire()
assert(not syntax.Visible, "empty command shows its placeholder")

command.Text = "assert(true)"
command.FocusLost:Fire(true)
command.Text = "error('command reached')"
local executed, problem = pcall(named("Run").Activated.Fire, named("Run").Activated)
assert(not executed and tostring(problem):find("command reached", 1, true), "Run executes the entered command")
LogService.MessageOut:Fire("pending [marker]", Enum.MessageType.MessageWarning)
named("Clear").Activated:Fire()
drain()
assert(#rows() == 0 and output.CanvasPosition.Y == 0, "clear discards pending output too")
visible = false
LogService.MessageOut:Fire("pending at close", Enum.MessageType.MessageWarning)
main.Alive = false
for _, connection in ipairs(main.connections) do
	connection:Disconnect()
end
for _, cleanup in ipairs(main.cleanups) do
	cleanup()
end
drain()
LogService.MessageOut:Fire("after shutdown", Enum.MessageType.MessageWarning)
assert(#rows() == 0 and #tasks == 0 and menu.destroyed and not LogService.MessageOut.listeners[1][1].connected)
print("PASS: Console backlog, batching, literal filters, options, command execution, clear and teardown")

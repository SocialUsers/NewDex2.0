--!strict

local function signal()
	local connections = {}
	return {
		Connect = function(_, callback)
			local key = {}
			connections[key] = callback
			return {
				Disconnect = function()
					connections[key] = nil
				end,
			}
		end,
		Count = function()
			local count = 0
			for _ in pairs(connections) do
				count += 1
			end
			return count
		end,
		Fire = function(_, ...)
			for key, callback in pairs(table.clone(connections)) do
				if connections[key] then
					callback(...)
				end
			end
		end,
	}
end

local now = 0
local os = {
	clock = function()
		return now
	end,
}
local function vec(x, y)
	return { X = x, Y = y }
end
local Vector2 = { new = vec }
local keyCode = { A = { Name = "A" }, F8 = { Name = "F8" }, W = { Name = "W" }, Unknown = { Name = "Unknown" } }
function keyCode:GetEnumItems()
	return { self.A, self.F8, self.W, self.Unknown }
end
local Enum = {
	KeyCode = keyCode,
	UserInputType = {
		Keyboard = "Key",
		MouseButton1 = "Mouse1",
		MouseButton2 = "Mouse2",
		MouseButton3 = "Mouse3",
		MouseMovement = "Move",
		MouseWheel = "Wheel",
	},
	MouseBehavior = { Default = "Default", LockCenter = "Locked" },
}
local Instance = {
	new = function()
		error("VirtualInputManager unavailable")
	end,
}
local input = {
	MouseBehavior = Enum.MouseBehavior.Default,
	InputBegan = signal(),
	InputEnded = signal(),
	InputChanged = signal(),
	WindowFocusReleased = signal(),
}
local mouse = vec(40, 50)
function input:GetMouseLocation()
	return mouse
end
function input:CreateVirtualInput()
	error("VirtualInput unavailable")
end
local key = function(item)
	return { UserInputType = Enum.UserInputType.Keyboard, KeyCode = item }
end
local heartbeat = signal()
local camera = { ViewportSize = vec(200, 100) }
local inputLog = {}
local function emitted(...)
	table.insert(inputLog, { ... })
end
local service =
	{ UserInputService = input, RunService = { Heartbeat = heartbeat }, Workspace = { CurrentCamera = camera } }
local funcs = {
	keypress = function(code)
		emitted("Down", code)
		input.InputBegan:Fire(key(keyCode.A), false)
	end,
	keyrelease = function(code)
		emitted("Up", code)
	end,
	mouse1press = function()
		emitted("Click")
	end,
	mouse1release = function()
		emitted("Release")
	end,
	mousemoveabs = function(x, y)
		emitted("Position", x, y)
	end,
	mousemoverel = function(x, y)
		emitted("Delta", x, y)
	end,
	mousescroll = function(delta)
		emitted("Scroll", delta)
	end,
}

-- MACRO MODULE FIXTURE

local Engine = MacroModule.Main()
local recordCount, progress = 0, 0
local reason, events
local allow = true
local engine = Engine.Create({
	OnState = function(state, nextReason, captured)
		if state == "Idle" then
			reason, events = nextReason, captured
		end
	end,
	OnEvent = function()
		recordCount += 1
	end,
	OnProgress = function(index)
		progress = index
	end,
	ShouldRecord = function(_, processed)
		return allow and not processed
	end,
	IsStopInput = function(event)
		return event.KeyCode == keyCode.F8
	end,
})
local function tick(t)
	now = t
	heartbeat:Fire()
end
local function clean()
	return heartbeat.Count()
			+ input.InputBegan.Count()
			+ input.InputChanged.Count()
			+ input.InputEnded.Count()
			+ input.WindowFocusReleased.Count()
		== 0
end
assert(engine.State == "Idle" and clean(), "idle engine subscribes to nothing")
local capabilities = engine:GetCapabilities()
assert(
	capabilities.Keyboard
		and capabilities.Mouse
		and capabilities.Movement
		and capabilities.RelativeMovement
		and capabilities.Wheel
)
assert(engine:StartRecording() and input.InputChanged.Count() == 1 and heartbeat.Count() == 1)
input.InputBegan:Fire(key(keyCode.W), false)
input.InputBegan:Fire(key(keyCode.W), false)
input.InputBegan:Fire(key(keyCode.A), true)
now = 0.2
input.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, false)
allow = false
mouse = vec(100, 80)
input.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
input.InputEnded:Fire(key(keyCode.W))
allow = true
input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement }, false)
input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement }, false)
input.MouseBehavior = Enum.MouseBehavior.LockCenter
input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Delta = vec(-8, 3) }, false)
input.MouseBehavior = Enum.MouseBehavior.Default
input.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = { Z = -1 } }, false)
now = 0.3
input.InputBegan:Fire(key(keyCode.A), false)
now = 0.4
input.InputBegan:Fire(key(keyCode.F8), false)
assert(engine.State == "Idle" and clean() and reason == "Stopped")
assert(recordCount == 8 and #events == 9 and Engine.Validate(events))
assert(events[1].Kind == "KeyDown" and events[1].Key == "W")
assert(events[2].Kind == "ButtonDown" and events[2].X == 0.2 and events[2].Y == 0.5)
assert(events[3].Kind == "ButtonUp" and events[3].X == 0.5 and events[3].Y == 0.8)
assert(events[4].Kind == "KeyUp" and events[4].Key == "W")
assert(events[5].Kind == "Move" and events[6].Kind == "RelativeMove" and events[6].DeltaX == -8)
assert(events[7].Kind == "Wheel" and events[7].Delta == -1)
assert(events[9].Kind == "KeyUp" and events[9].Key == "A" and events[9].Time == 0.4)
local captured = events

assert(not Engine.Validate({ [2] = { Kind = "KeyDown", Key = "A", Time = 0 } }))
assert(not Engine.Validate({ { Kind = "KeyDown", Key = "invalid", Time = 0 } }))
assert(not Engine.Validate({ { Kind = "Move", X = 2, Y = 0, Time = 0 } }))
assert(not Engine.Validate({ { Kind = "Move", X = 0, Y = 0, Time = 0 / 0 } }))
assert(not Engine.Validate({ { Kind = "KeyDown", Key = "A", Time = 2 }, { Kind = "KeyUp", Key = "A", Time = 1 } }))
assert(not engine:CanPlay({}))
assert(engine:CanPlay(captured))
assert(not engine:Play(captured, { Speed = 0 }))
assert(engine:Play(captured, { Speed = 0.5 }))
assert(input.InputChanged.Count() == 0 and input.InputEnded.Count() == 0 and not engine:StartRecording())
camera.ViewportSize = vec(400, 200)
tick(0.41)
assert(#inputLog == 1 and inputLog[1][1] == "Down" and inputLog[1][2] == 87)
tick(0.9)
assert(recordCount == 8 and progress == 7, "synthetic input was replayed without recording")
assert(inputLog[2][1] == "Position" and inputLog[2][2] == 80 and inputLog[2][3] == 100)
assert(inputLog[8][1] == "Delta" and inputLog[8][2] == -8)
assert(inputLog[10][1] == "Scroll" and inputLog[10][2] == -120)
tick(1.21)
assert(engine.State == "Idle" and clean() and reason == "Finished" and progress == 9)
assert(inputLog[#inputLog][1] == "Up" and inputLog[#inputLog][2] == 65)

table.clear(inputLog)
local held = {
	{ Kind = "KeyDown", Key = "W", Time = 0 },
	{ Kind = "ButtonDown", Button = 1, X = 0.5, Y = 0.5, Time = 0 },
	{ Kind = "Move", X = 0.5, Y = 1, Time = 1 },
}
assert(engine:Play(held, { Loop = true }))
tick(1.25)
assert(#inputLog == 3)
tick(2.26)
assert(#inputLog == 6 and inputLog[4][3] == 199 and inputLog[5][1] == "Up" and inputLog[6][1] == "Release")
tick(2.3)
assert(#inputLog == 9 and engine.State == "Playing")
input.WindowFocusReleased:Fire()
assert(#inputLog == 11 and inputLog[10][1] == "Up" and inputLog[11][1] == "Release")
assert(engine.State == "Idle" and clean() and reason == "Window lost focus")

funcs.mousemoveabs = function()
	error("denied")
end
assert(engine:Play(held))
tick(2.31)
assert(engine.State == "Idle" and clean() and reason:find("denied", 1, true))
assert(inputLog[#inputLog - 1][1] == "Up" and inputLog[#inputLog][1] == "Release")
assert(engine:StartRecording())
tick(603)
assert(engine.State == "Idle" and clean() and reason == "Recording limit reached")
engine:Destroy()
assert(not engine:StartRecording() and not engine:Play(held) and clean())

MacroModule.InitDeps({ env = {}, service = service })
local closed = 0
function input:CreateVirtualInput()
	return {
		SendKey = function(_, down, code, repeated)
			assert(code == keyCode.W and repeated == false)
			emitted(if down then "VirtualDown" else "VirtualUp")
		end,
		SendMouseButton = function(_, point, kind, down, repeats)
			assert(kind == Enum.UserInputType.MouseButton1 and repeats == 0)
			emitted(if down then "VirtualClick" else "VirtualRelease", point.X, point.Y)
		end,
		SendMousePosition = function(_, point)
			emitted("VirtualPosition", point.X, point.Y)
		end,
		Destroy = function()
			closed += 1
		end,
	}
end
local fallback = Engine.Create()
assert(fallback:Play(held))
table.clear(inputLog)
tick(603.1)
assert(inputLog[1][1] == "VirtualDown" and inputLog[2][1] == "VirtualClick" and inputLog[2][2] == 200)
tick(604.1)
assert(inputLog[3][1] == "VirtualPosition" and inputLog[4][1] == "VirtualUp" and inputLog[5][1] == "VirtualRelease")
assert(fallback.State == "Idle" and closed == 1 and clean())
print("PASS: macro capture, resize-aware replay, timing, loop release, failure cleanup, focus loss and bounds")

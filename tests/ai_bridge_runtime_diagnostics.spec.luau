--!strict

-- Runtime snapshots exercise real registry/codec without starting watches or loops.
do
	local oldPlayers, oldInput, oldStats, oldRun =
		service.Players, service.UserInputService, service.Stats, service.RunService
	local oldTags = Enum.DeveloperMemoryTag
	local oldPhysics = workspace.GetRealPhysicsFPS
	local oldStreaming, oldGravity, oldTime =
		workspace.StreamingEnabled, workspace.Gravity, workspace.DistributedGameTime
	local localPlayer = Instance.new("Player", game)
	localPlayer.UserId = 7
	localPlayer.Name = "Local"
	local other = Instance.new("Player", game)
	other.UserId = 8
	other.Name = "Remote player"
	local character = Instance.new("Model", workspace)
	localPlayer.Character = character
	local humanoid = Instance.new("Humanoid", character)
	humanoid.Health = 0
	humanoid.MaxHealth = 100
	humanoid.Sit = false
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16
	humanoid.GetState = function()
		return Enum.Material.Plastic
	end
	local root = newPart(character, vec(1, 2, 3))
	root.Name = "HumanoidRootPart"
	root.Anchored = false
	root.AssemblyLinearVelocity = vec(4, 0, 0)
	root.AssemblyAngularVelocity = vec()
	humanoid.RootPart = root
	local backpack = Instance.new("Backpack", localPlayer)
	for index = 1, 22 do
		local tool = Instance.new("Tool", index == 1 and character or backpack)
		tool.Name = "Tool " .. index
		tool.Enabled = false
		tool.CanBeDropped = false
	end
	service.Players = {
		LocalPlayer = localPlayer,
		GetPlayerByUserId = function(_, id)
			return id == 7 and localPlayer or id == 8 and other or nil
		end,
	}
	local gui = Instance.new("ScreenGui", localPlayer)
	local focused = Instance.new("TextBox", gui)
	focused.Text = "private typed content"
	local secret = Instance.new("TextBox", gui)
	secret.Text = "internal typed content"
	local owner = {
		IsDexGuiObject = function(object)
			return object == secret or Main.IsDexGuiObject and Main.IsDexGuiObject(object)
		end,
	}
	local registry = Apps.BridgeRegistry.Create({ Apps = Apps, Main = owner, Game = game })
	local codec = Apps.BridgeValueCodec.Create(registry)
	local nativeCalls = 0
	local pressed = {}
	for index = 1, 70 do
		pressed[index] = {
			KeyCode = "K" .. index,
			UserInputType = "Keyboard",
			UserInputState = "Begin",
			Text = "never copy input text",
		}
	end
	service.UserInputService = {
		KeyboardEnabled = true,
		MouseEnabled = false,
		TouchEnabled = false,
		GamepadEnabled = true,
		GetMouseLocation = function()
			nativeCalls += 1
			local point = Vector2.new(50, 60)
			point.__bridgeType = "Vector2"
			return point
		end,
		GetLastInputType = function()
			return Enum.Material.Plastic
		end,
		GetKeysPressed = function()
			nativeCalls += 1
			return pressed
		end,
		GetFocusedTextBox = function()
			nativeCalls += 1
			return focused
		end,
	}
	service.RunService = {
		IsClient = function()
			return true
		end,
		IsRunning = function()
			return false
		end,
		IsStudio = function()
			return false
		end,
	}
	local memoryTags = {}
	for index = 1, 40 do
		memoryTags[index] = "Tag" .. index
	end
	Enum.DeveloperMemoryTag = {
		GetEnumItems = function()
			return memoryTags
		end,
	}
	service.Stats = setmetatable({
		MemoryTrackingEnabled = false,
		InstanceCount = 0,
		FrameTime = 0.02,
		GetTotalMemoryUsageMb = function()
			nativeCalls += 1
			return 0
		end,
		GetMemoryUsageMbForTag = function(_, tag)
			if tag == "Tag2" then
				error("tag unavailable")
			end
			return 0
		end,
	}, {
		__index = function(_, key)
			if key == "PhysicsStepTime" then
				error("stats locked")
			end
			return nil
		end,
	})
	workspace.StreamingEnabled = false
	workspace.Gravity = 196.2
	workspace.DistributedGameTime = 0
	workspace.GetRealPhysicsFPS = function()
		return 60
	end
	local module = Apps.BridgeRuntimeDiagnostics.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		Game = game,
		Registry = registry,
		Codec = codec,
	})
	assert(nativeCalls == 0, "constructing diagnostics performs no background native reads")
	local handlers = {}
	for _, command in ipairs(module.Commands) do
		assert(command.Grant == "inspect")
		handlers[command.Name] = command.Run
	end
	local function call(name, args)
		return handlers["dex_" .. name](args or {})
	end
	local state = call("get_character_state")
	assert(state.scope == "client" and state.available and state.observedAt > 0 and state.userId == 7)
	assert(
		state.humanoid.properties.Health == 0
			and state.humanoid.properties.Sit == false
			and state.humanoid.properties.JumpHeight.type == "nil",
		"character snapshots preserve zero, false and typed nil"
	)
	assert(state.rootPart.properties.Anchored == false and state.rootPart.properties.CFrame.type == "CFrame")
	assert(
		#state.tools == 20 and state.tools[1].equipped and not state.tools[2].equipped and state.truncated,
		"equipped/backpack tool evidence is bounded and distinct"
	)
	assert(state.estimatedBytes <= 48 * 1024)
	local missing = call("get_character_state", { userId = 8 })
	assert(
		not missing.available and missing.reason == "character_unavailable" and missing.player.id == registry:Id(other)
	)
	local unknown = call("get_character_state", { userId = 999 })
	assert(not unknown.available and unknown.reason == "player_unavailable")
	local input = call("get_input_state")
	assert(input.capabilities.properties.MouseEnabled == false and input.pointer.properties.position.type == "Vector2")
	assert(
		input.focusedTextBox.id == registry:Id(focused)
			and input.focusedTextBox.Text == nil
			and input.focusedTextBox.text == nil,
		"focused game textbox is identity only, never its content"
	)
	assert(
		#input.pressedKeys <= 64
			and input.nativePressedKeys == 70
			and input.truncated
			and input.estimatedBytes <= 48 * 1024
	)
	for _, entry in ipairs(input.pressedKeys) do
		assert(entry.properties.Text == nil and entry.properties.UserInputType == "Keyboard")
	end
	service.UserInputService.GetFocusedTextBox = function()
		return secret
	end
	local excluded = call("get_input_state")
	assert(
		not excluded.focusedTextBox.available and not excluded.focusedTextBox.id,
		"focused Dex/internal GUI cannot escape registry privacy"
	)
	service.UserInputService.GetKeysPressed = function()
		error("input access denied")
	end
	assert(
		call("get_input_state").errors.pressedKeys:find("input access denied", 1, true),
		"native input failures are evidence, not empty successful reads"
	)
	local savedPerformance = Main.Performance
	Main.Performance = {
		Snapshot = function()
			return {
				Uptime = 1,
				Yields = 2,
				Metrics = { fixture = { Count = 3, Total = 0.01, Max = 0.005 } },
				SlowFrames = {},
			}
		end,
	}
	local measured = call("get_runtime_stats")
	assert(
		measured.dexPerformance and measured.dexPerformance.metrics[1].name == "fixture",
		"inspect diagnostics includes the bounded Dex trace"
	)
	Main.Performance = savedPerformance
	local stats = call("get_runtime_stats")
	assert(
		stats.scope == "client"
			and stats.memory.unit == "MB"
			and stats.memory.properties.total == 0
			and stats.memory.properties.trackingEnabled == false
	)
	assert(
		#stats.memory.tags == 32
			and stats.memory.nativeTags == 40
			and stats.truncated
			and stats.memory.tags[1].properties.usage == 0
			and stats.memory.tags[2].errors.usage
	)
	assert(stats.run.properties.IsRunning == false and stats.workspace.properties.StreamingEnabled == false)
	assert(
		stats.workspace.properties.physicsSimulationFPS == 60
			and not stats.renderFPS.available
			and stats.renderFPS.reason == "not_sampled",
		"physics simulation frequency is not presented as rendered/server FPS"
	)
	assert(stats.stats.errors.PhysicsStepTime:find("stats locked", 1, true) and stats.estimatedBytes <= 48 * 1024)
	service.Stats.GetTotalMemoryUsageMb = function()
		return 0 / 0
	end
	workspace.GetRealPhysicsFPS = function()
		return math.huge
	end
	local invalid = call("get_runtime_stats")
	assert(
		invalid.memory.errors.total and invalid.workspace.errors.physicsSimulationFPS,
		"nonfinite native results cannot reach JSON transport"
	)
	for _, args in ipairs({
		{ userId = -1 },
		{ userId = 1.5 },
		{ userId = math.huge },
		{ userId = "7" },
		{
			unexpected = true,
		},
	}) do
		local ok, why = pcall(call, "get_character_state", args)
		assert(not ok and tostring(why):find("INVALID_ARGUMENT", 1, true))
	end
	for _, name in ipairs({ "get_input_state", "get_runtime_stats" }) do
		local ok, why = pcall(call, name, { unexpected = true })
		assert(not ok and tostring(why):find("INVALID_ARGUMENT", 1, true))
	end
	module:Destroy()
	module:Destroy()
	for _, name in ipairs({ "get_character_state", "get_input_state", "get_runtime_stats" }) do
		local ok, why = pcall(call, name)
		assert(not ok and tostring(why):find("DISCONNECTED", 1, true))
	end
	registry:Destroy()
	character:Destroy()
	localPlayer:Destroy()
	other:Destroy()
	service.Players, service.UserInputService, service.Stats, service.RunService =
		oldPlayers, oldInput, oldStats, oldRun
	Enum.DeveloperMemoryTag = oldTags
	workspace.GetRealPhysicsFPS = oldPhysics
	workspace.StreamingEnabled, workspace.Gravity, workspace.DistributedGameTime = oldStreaming, oldGravity, oldTime
	print(
		"PASS: client character/input/stats snapshots, missing players, false/nil/finite values, private focus, native failures, output limits, no background reads and teardown"
	)
end

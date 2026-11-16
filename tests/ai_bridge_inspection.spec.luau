--!strict

-- Exercise the real inspection adapter against engine-shaped read-only fixtures.
do
	local originalLighting = service.Lighting
	local root = Instance.new("Folder", workspace)
	root.Name = "Inspection fixtures"
	local animator = Instance.new("Animator", root)
	animator.Name = "Animator"
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://7123"
	local track = setmetatable({
		Name = "Walk",
		IsPlaying = true,
		Length = 2,
		Speed = 0,
		TimePosition = 0,
		WeightCurrent = 0,
		WeightTarget = 1,
		Priority = Enum.Material.Plastic,
		Looped = false,
		Animation = animation,
	}, {
		__index = function(_, key)
			if key == "Broken" then
				error("blocked")
			end
		end,
	})
	local deniedTrack = setmetatable({ Name = "Restricted", Animation = nil }, {
		__index = function(_, key)
			if key == "Speed" then
				error("protected track field")
			end
			return nil
		end,
	})
	animator.GetPlayingAnimationTracks = function()
		return { track, deniedTrack }
	end
	local part = newPart(root, vec(1, 2, 3))
	local sound = Instance.new("Sound", part)
	sound.Name = "Silent fixture"
	sound.SoundId = "rbxassetid://123"
	sound.Playing = false
	sound.IsPaused = false
	sound.IsLoaded = false
	sound.TimePosition = 0
	sound.Volume = 0
	sound.SoundGroup = nil
	local playing = Instance.new("Sound", root)
	playing.Name = "Playing fixture"
	playing.Playing = true
	playing.SoundId = "rbxassetid://456"
	local modern = Instance.new("AudioPlayer", root)
	modern.Name = "Modern fixture"
	modern.Asset = "rbxassetid://789"
	modern.IsPlaying = true
	modern.IsReady = false
	modern.Volume = 0
	modern.AudioContent = nil
	local lighting = Instance.new("Lighting", game)
	lighting.Name = "Lighting"
	lighting.GlobalShadows = false
	lighting.ClockTime = 0
	lighting.Brightness = 0
	service.Lighting = lighting
	local sky = Instance.new("Sky", lighting)
	sky.SkyboxBk = "rbxassetid://999"
	sky.CelestialBodiesShown = false
	local effect = Instance.new("BloomEffect", lighting)
	effect.Enabled = false
	effect.Intensity = 0
	local registry = Apps.BridgeRegistry.Create({ Apps = Apps, Main = Main, Game = game })
	local codec = Apps.BridgeValueCodec.Create(registry)
	local progress = 0
	local cancelAfter
	local onCheck
	local lastJob
	local scans = 0
	local inspection = Apps.BridgeInspectionCommands.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		env = {},
		Game = game,
		Registry = registry,
		Codec = codec,
		StartJob = function(run)
			scans += 1
			local ok, value = pcall(run, function()
				progress += 1
				if onCheck then
					onCheck(progress)
				end
				return not cancelAfter or progress < cancelAfter
			end)
			lastJob = {
				status = ok and "completed" or "failed",
				result = ok and value or nil,
				error = not ok and tostring(value) or nil,
				jobId = "fixture" .. scans,
			}
			return lastJob
		end,
	})
	local commands = {}
	for _, command in ipairs(inspection.Commands) do
		assert(command.Grant == "inspect")
		commands[command.Name] = command.Run
	end
	local function call(name, args)
		return assert(commands[name], name)(args or {})
	end
	local function finish(job)
		assert(job.status == "completed", job.error)
		return job.result
	end
	local rows = finish(call("dex_get_playing_animations", { instanceId = registry:Id(root) }))
	assert(rows.scope == "client" and #rows.items == 2 and rows.coverage.animatorsVisited == 1)
	assert(
		rows.items[1].properties.AnimationId == "rbxassetid://7123"
			and rows.items[1].properties.Speed == 0
			and rows.items[1].properties.Looped == false,
		"track state preserves zero and false"
	)
	assert(
		rows.items[1].animator.id == registry:Id(animator)
			and not rows.items[1].id
			and rows.trackIdentity == "snapshot_descriptor",
		"detached tracks are descriptors, not fake registry handles"
	)
	assert(
		rows.items[2].errors.Speed:find("protected track field", 1, true)
			and rows.items[2].properties.AnimationId.type == "nil",
		"per-track field failures and nil source are retained"
	)
	local capped = finish(call("dex_get_playing_animations", { instanceId = registry:Id(animator), limit = 1 }))
	assert(#capped.items == 1 and capped.coverage.truncated and capped.coverage.reason == "track_limit")
	local audio = finish(call("dex_get_sound_state", { rootId = registry:Id(root) }))
	local byName = {}
	for _, item in ipairs(audio.items) do
		byName[item.instance.name] = item
	end
	assert(
		byName["Silent fixture"].properties.Playing == false
			and byName["Silent fixture"].properties.Volume == 0
			and byName["Silent fixture"].properties.SoundGroup.type == "nil",
		"sound state preserves false, zero and nil"
	)
	assert(
		byName["Silent fixture"].parent.id == registry:Id(part)
			and byName["Silent fixture"].spatialProperties.CFrame.type == "CFrame"
	)
	assert(
		byName["Modern fixture"].properties.IsReady == false
			and byName["Modern fixture"].spatialMode == "audio_graph_not_resolved",
		"modern audio reports supported state without claiming spatial graph resolution"
	)
	local only = finish(call("dex_get_sound_state", { rootId = registry:Id(root), playingOnly = true }))
	assert(#only.items == 2, "playing-only filter excludes known stopped sounds")
	local originalIndex = instMT.__index
	instMT.__index = function(object, key)
		if object == playing and key == "Playing" then
			error("cannot read playing")
		end
		return originalIndex(object, key)
	end
	playing._props.Playing = nil
	local unavailable = finish(call("dex_get_sound_state", { rootId = registry:Id(root), playingOnly = true }))
	assert(
		unavailable.coverage.playbackFilterUnavailable == 1 and unavailable.errors[1].property == "Playing",
		"unavailable playback fields are not guessed"
	)
	instMT.__index = originalIndex
	playing.Playing = true
	local direct = call("dex_get_lighting")
	assert(
		direct.kind == "lighting"
			and direct.properties.GlobalShadows == false
			and direct.properties.ClockTime == 0
			and not direct.jobId,
		"lighting snapshot is direct and preserves false/zero"
	)
	assert(
		#direct.items == 2 and direct.items[2].properties.Enabled == false and direct.items[2].properties.Intensity == 0
	)
	assert(direct.coverage.estimatedBytes <= 48 * 1024)
	-- Wide roots may allocate an engine child list, but queued work/visits stay bounded.
	local wide = Instance.new("Folder", root)
	for index = 1, 20 do
		local object = Instance.new("Sound", wide)
		object.Playing = true
		object.Name = "Sound " .. index
	end
	local bounded = finish(call("dex_get_sound_state", { rootId = registry:Id(wide), maxNodes = 5 }))
	assert(
		bounded.coverage.nodesVisited == 5 and #bounded.items == 4 and bounded.coverage.nodeLimitReached,
		"child queues cannot grow beyond traversal budget"
	)
	local many = Instance.new("Folder", root)
	for _ = 1, 18 do
		local object = Instance.new("Animator", many)
		object.GetPlayingAnimationTracks = function()
			return {}
		end
	end
	local animators = finish(call("dex_get_playing_animations", { instanceId = registry:Id(many) }))
	assert(animators.coverage.animatorsVisited == 16 and animators.coverage.reason == "animator_limit")
	for _ = 1, 40 do
		Instance.new("Atmosphere", lighting)
	end
	local effects = call("dex_get_lighting")
	assert(#effects.items <= 32 and effects.coverage.truncated)
	-- Property reads with unusually long strings are explicit omissions, never oversized responses.
	sound.SoundId = string.rep("x", 10000)
	local long = finish(call("dex_get_sound_state", { rootId = registry:Id(sound) }))
	assert(long.items[1].errors.SoundId == "property_string_limit" and long.coverage.estimatedBytes <= 48 * 1024)
	local heavy = Instance.new("Folder", root)
	for _ = 1, 100 do
		local object = Instance.new("Sound", heavy)
		object.SoundId = string.rep("x", 600)
	end
	local budget = finish(call("dex_get_sound_state", { rootId = registry:Id(heavy), limit = 100 }))
	assert(
		budget.coverage.truncated
			and budget.coverage.reason == "result_byte_limit"
			and budget.coverage.estimatedBytes <= 48 * 1024,
		"estimated serialized result budget bounds total retained rows"
	)
	local failedAnimator = Instance.new("Animator", root)
	failedAnimator.GetPlayingAnimationTracks = function()
		error("native track read denied")
	end
	local denied = finish(call("dex_get_playing_animations", { instanceId = registry:Id(failedAnimator) }))
	assert(
		#denied.items == 0
			and denied.errors[1].operation == "GetPlayingAnimationTracks"
			and denied.errors[1].error:find("native track read denied", 1, true),
		"native method errors remain explicit"
	)
	for _, args in ipairs({
		{ rootId = registry:Id(root), limit = 0 },
		{ rootId = registry:Id(root), limit = 101 },
		{ rootId = registry:Id(root), maxNodes = 5001 },
		{ rootId = registry:Id(root), playingOnly = "yes" },
	}) do
		local ok, why = pcall(call, "dex_get_sound_state", args)
		assert(not ok and tostring(why):find("INVALID_ARGUMENT", 1, true))
	end
	local transient = Instance.new("Animator", root)
	transient.Name = string.rep("€", 100)
	transient.GetPlayingAnimationTracks = function()
		return { track, track }
	end
	local transientId = registry:Id(transient)
	local stateReads = 0
	local watchedTrack = setmetatable({ Animation = animation }, {
		__index = function(_, key)
			if key == "Name" then
				stateReads += 1
			end
			return track[key]
		end,
	})
	transient.GetPlayingAnimationTracks = function()
		return { watchedTrack, watchedTrack }
	end
	onCheck = function()
		if stateReads == 1 then
			transient:Destroy()
		end
	end
	local stale = finish(call("dex_get_playing_animations", { instanceId = transientId }))
	onCheck = nil
	assert(
		#stale.items == 1
			and stale.errors[1].error:find("STALE_INSTANCE", 1, true)
			and stale.errors[1].instance.id == transientId
			and stale.coverage.reason == "stale_animator",
		"animator removal during a cooperative yield preserves completed descriptors and records stale identity"
	)
	assert(
		stale.items[1].animator.nameTruncated and utf8.len(stale.items[1].animator.name) == 85,
		"identity name caps do not split UTF-8 characters"
	)
	progress = 0
	cancelAfter = 3
	local cancelled = call("dex_get_sound_state", { rootId = registry:Id(root) })
	assert(
		cancelled.status == "failed" and cancelled.error:find("CANCELLED", 1, true),
		"queued child work checks cancellation cooperatively"
	)
	cancelAfter = nil
	inspection:Destroy()
	local ended = call("dex_get_sound_state", { rootId = registry:Id(root) })
	assert(ended.status == "failed" and ended.error:find("CANCELLED", 1, true))
	registry:Destroy()
	animation:Destroy()
	root:Destroy()
	lighting:Destroy()
	service.Lighting = originalLighting
	print(
		"PASS: bounded inspection jobs/direct lighting, detached track descriptors, legacy/modern sound state, false/nil/errors, node/animator/effect/byte limits and cooperative teardown"
	)
end

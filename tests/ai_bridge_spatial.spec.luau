--!strict

-- Spatial adapters exercise native-query contracts using bounded Roblox-shaped fixtures.
do
	local oldCamera = workspace.CurrentCamera
	local oldGui = service.GuiService
	local oldCore = service.CoreGui
	local oldPlayers = service.Players
	local oldOverlap = OverlapParams
	local oldMask = Apps.SelectionGeometryMask
	local folder = Instance.new("Folder", workspace)
	folder.Name = "Spatial fixture"
	local camera = Instance.new("Camera", workspace)
	camera.CFrame = CFrame.new()
	camera.ViewportSize = Vector2.new(800, 600)
	local calls = {}
	camera.WorldToScreenPoint = function(_, v)
		calls.projection = "screen"
		return vec(v.X, v.Y - 36, v.Z), v.Z > 0
	end
	camera.WorldToViewportPoint = function(_, v)
		calls.projection = "viewport"
		return vec(v.X, v.Y, v.Z), v.Z > 0
	end
	camera.ScreenPointToRay = function(_, x, y)
		calls.ray = "screen"
		return { Origin = vec(x, y, 0), Direction = vec(0, 0, -5) }
	end
	camera.ViewportPointToRay = function(_, x, y)
		calls.ray = "viewport"
		return { Origin = vec(x, y, 0), Direction = vec(0, 0, -5) }
	end
	workspace.CurrentCamera = camera
	service.GuiService = {
		GetGuiInset = function()
			return Vector2.new(0, 36), Vector2.new(0, 0)
		end,
	}
	local player = Instance.new("Player", game)
	local playerGui = Instance.new("PlayerGui", player)
	service.Players = { LocalPlayer = player }
	local core = Instance.new("CoreGui", game)
	service.CoreGui = core
	local ui = Instance.new("Frame", playerGui)
	ui.Name = "Real GUI"
	ui.Visible = false
	ui.Active = false
	local internal = Instance.new("Frame", playerGui)
	internal.Name = "Dex helper"
	Apps.SelectionGeometryMask = {
		IsInternal = function(object)
			return object == internal
		end,
	}
	playerGui.GetGuiObjectsAtPosition = function(_, x, y)
		calls.ui = { x = x, y = y }
		return { internal, ui }
	end
	core.GetGuiObjectsAtPosition = function()
		error("CoreGui denied")
	end
	local part = newPart(folder, vec())
	local other = newPart(folder, vec(4, 0, 0))
	local third = newPart(folder, vec(8, 0, 0))
	local joint = Instance.new("WeldConstraint", part)
	joint.Part0 = part
	joint.Part1 = other
	joint.Enabled = false
	part.Anchored = false
	part.CanCollide = false
	part.AssemblyMass = 0
	local recursiveCalls = 0
	part.GetConnectedParts = function(_, recursive)
		if recursive then
			recursiveCalls += 1
		end
		return { other }
	end
	other.GetConnectedParts = function(_, recursive)
		if recursive then
			recursiveCalls += 1
		end
		return { part, third }
	end
	third.GetConnectedParts = function(_, recursive)
		if recursive then
			recursiveCalls += 1
		end
		return { other }
	end
	part.GetJoints = function()
		return { joint }
	end
	other.GetJoints = function()
		return { joint }
	end
	third.GetJoints = function()
		error("fixture permission")
	end
	OverlapParams = {
		new = function()
			return {}
		end,
	}
	local oldBox, oldRadius = workspace.GetPartBoundsInBox, workspace.GetPartBoundsInRadius
	workspace.GetPartBoundsInBox = function(_, cf, extent, params)
		calls.overlap = params
		calls.shape = "box"
		return { internal, part, other }
	end
	workspace.GetPartBoundsInRadius = function(_, center, radius, params)
		calls.overlap = params
		calls.shape = "radius"
		return { part, other }
	end
	local registry = Apps.BridgeRegistry.Create({ Apps = Apps, Main = Main, Game = game })
	local codec = Apps.BridgeValueCodec.Create(registry)
	local checkCalls = 0
	local module = Apps.BridgeSpatialCommands.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		Game = game,
		Registry = registry,
		Codec = codec,
		StartJob = function(run)
			return { status = "completed", result = run(function()
				checkCalls += 1
				return true
			end) }
		end,
	})
	local handlers = {}
	for _, command in ipairs(module.Commands) do
		assert(command.Grant == "inspect")
		handlers[command.Name] = command.Run
	end
	local function call(name, args)
		return handlers["dex_" .. name](args or {})
	end
	local point = codec:Encode(vec(10, 50, 3))
	local projection = call("world_to_screen", { positions = { point } })
	assert(
		projection.scope == "client"
			and calls.projection == "screen"
			and projection.points[1].y == 14
			and projection.points[1].onScreen
	)
	assert(projection.guiInset.topLeft.y == 36 and projection.viewport.x == 800)
	local viewport =
		call("world_to_screen", { positions = { point, codec:Encode(vec(0, 0, -1)) }, coordinateSpace = "viewport" })
	assert(
		calls.projection == "viewport" and viewport.points[1].y == 50 and not viewport.points[2].onScreen,
		"projection preserves requested coordinate system and behind-camera flag"
	)
	local ray = call("screen_to_ray", { x = 10, y = 50, coordinateSpace = "viewport" })
	assert(
		calls.ray == "viewport" and ray.direction.z == -1 and ray.origin.x == 10 and ray.unitDirection,
		"ray is normalized without casting or scene edits"
	)
	call("screen_to_ray", { x = 0, y = 0 })
	assert(calls.ray == "screen")
	local hits = call("get_ui_at_point", { x = 20, y = 80, includeCoreGui = true })
	assert(
		calls.ui.x == 20 and calls.ui.y == 44 and hits.queryPoint.y == 44,
		"client viewport point is converted to native GUI inset coordinates once"
	)
	assert(
		#hits.containers[1].entries == 1
			and hits.containers[1].entries[1].rank == 2
			and hits.containers[1].entries[1].instance.name == "Real GUI",
		"native within-container order retained while Dex helpers are excluded"
	)
	assert(
		hits.containers[1].entries[1].properties.Visible == false
			and hits.containers[2].error:find("CoreGui denied", 1, true),
		"false properties and per-container access failures retained"
	)
	local oldHits = playerGui.GetGuiObjectsAtPosition
	playerGui.GetGuiObjectsAtPosition = function()
		local values = {}
		for index = 1, 600 do
			values[index] = internal
		end
		return values
	end
	local dense = call("get_ui_at_point", { x = 0, y = 0 })
	assert(
		dense.truncated and dense.containers[1].examined == 512 and dense.returned == 0,
		"dense internal hit lists have a bounded Lua examination count"
	)
	playerGui.GetGuiObjectsAtPosition = oldHits
	local box = call("query_parts", {
		shape = "box",
		cframe = codec:Encode(CFrame.new()),
		size = codec:Encode(vec(10, 10, 10)),
		limit = 2,
		excludeIds = { registry:Id(third) },
	})
	assert(
		calls.shape == "box"
			and calls.overlap.MaxParts == 3
			and calls.overlap.FilterDescendantsInstances[1] == third
			and #box.parts == 2
			and box.truncated,
		"native query bound, explicit exclusions and possible truncation are honest"
	)
	local radius = call("query_parts", { shape = "radius", center = codec:Encode(vec()), radius = 5 })
	assert(calls.shape == "radius" and #radius.parts == 2 and not radius.truncated)
	local assembly = call("get_assembly", { instanceId = registry:Id(part), limit = 2 }).result
	assert(
		assembly.scope == "client"
			and #assembly.parts == 2
			and #assembly.joints == 1
			and assembly.truncated
			and recursiveCalls == 0
			and checkCalls == 2,
		"assembly uses bounded cooperative BFS and deduplicates joints"
	)
	assert(
		assembly.parts[1].properties.Anchored == false
			and assembly.parts[1].properties.AssemblyMass == 0
			and assembly.joints[1].properties.Enabled == false,
		"physics false and zero values survive"
	)
	local full = call("get_assembly", { instanceId = registry:Id(part), limit = 10 }).result
	assert(
		#full.parts == 3 and #full.errors == 1 and full.errors[1].operation == "GetJoints",
		"native connection failures are per-node evidence"
	)
	for _, item in ipairs({
		{ "screen_to_ray", { x = 0 / 0, y = 0 } },
		{ "screen_to_ray", { x = 1e9, y = 0 } },
		{ "world_to_screen", { positions = { point }, coordinateSpace = "invalid" } },
		{ "world_to_screen", { positions = {} } },
		{ "query_parts", { shape = "radius", center = point, radius = -1 } },
		{ "query_parts", { shape = "box", cframe = codec:Encode(CFrame.new()), size = codec:Encode(vec(0, 1, 1)) } },
		{ "get_assembly", { instanceId = registry:Id(folder) } },
		{ "get_ui_at_point", { x = 0, y = 0, includeCoreGui = "yes" } },
	}) do
		assert(not pcall(call, item[1], item[2]), "invalid spatial argument must reject: " .. item[1])
	end
	module:Destroy()
	assert(
		not pcall(call, "get_assembly", { instanceId = registry:Id(part) }),
		"destroyed adapter cancels pending spatial analysis"
	)
	registry:Destroy()
	folder:Destroy()
	player:Destroy()
	core:Destroy()
	camera:Destroy()
	workspace.CurrentCamera = oldCamera
	service.GuiService = oldGui
	service.CoreGui = oldCore
	service.Players = oldPlayers
	OverlapParams = oldOverlap
	Apps.SelectionGeometryMask = oldMask
	workspace.GetPartBoundsInBox = oldBox
	workspace.GetPartBoundsInRadius = oldRadius
	print(
		"PASS: spatial projection/ray coordinates, inset-aware GUI hits, bounded overlap candidates, assembly BFS, field failures, false values and teardown"
	)
end

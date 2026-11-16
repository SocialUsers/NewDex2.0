--!strict

do
	initBridgeSelection()
	local cap, clipboard = 60, nil
	local files, folders = {}, {}
	local drawingHandles = {}
	local bridge = Apps.BridgeCommandRouter.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		env = {
			isfolder = function(path)
				return folders[path] == true
			end,
			makefolder = function(path)
				folders[path] = true
			end,
			isfile = function(path)
				return files[path] ~= nil
			end,
			writefile = function(path, text)
				files[path] = text
			end,
			readfile = function(path)
				return assert(files[path])
			end,
			appendfile = function(path, text)
				files[path] ..= text
			end,
			delfile = function(path)
				files[path] = nil
			end,
			Drawing = {
				new = function(kind)
					local handle = {
						Kind = kind,
						Remove = function(self)
							self.Removed = true
						end,
					}
					drawingHandles[#drawingHandles + 1] = handle
					return handle
				end,
			},
			crypt = {
				hash = function(data, algorithm)
					return algorithm .. ":" .. data
				end,
				base64 = {
					decode = function()
						return string.char(255)
					end,
					encode = function()
						return "/w=="
					end,
				},
			},
			loadstring = loadstring,
			getfpscap = function()
				return cap
			end,
			setfpscap = function(value)
				cap = value
			end,
			setclipboard = function(value)
				clipboard = value
			end,
		},
		Game = game,
	})
	local function call(name, args, grant)
		return bridge:Execute(name, args or {}, grant or { inspect = true })
	end
	local edit = { inspect = true, edit = true }
	local parent = Instance.new("Folder", workspace)
	parent.Name = "Bridge extras"
	local left = newPart(parent, vec(0, 0, 0))
	left.Name = "Same"
	left.Archivable = true
	local right = newPart(parent, vec(4, 0, 0))
	right.Name = "Same"
	local pid, lid = bridge.Registry:Id(parent), bridge.Registry:Id(left)
	local found = call("dex_resolve_path", { rootId = pid, segments = { "Same" } })
	assert(found.ambiguous and #found.instances == 2, "exact path resolution retains duplicate-name candidates")
	assert(call("dex_get_ancestors", { instanceId = lid }).ancestors[1].id == pid)
	local schema = call("dex_get_class_schema", { className = "Part" })
	local properties = {}
	for _, property in ipairs(schema.properties) do
		properties[property.name] = true
	end
	assert(properties.Name and properties.CFrame, "class schema includes inherited and own properties")
	assert(#bridge:Capabilities().commands == 136, "expanded runtime advertises exactly the supported handlers")
	local execute = { inspect = true, execute = true }
	assert(call("dex_get_executor_info").capabilities.getfpscap)
	assert(call("dex_get_fps_cap").fpsCap == 60)
	assert(not pcall(call, "dex_set_fps_cap", { fpsCap = 144 }, edit))
	assert(not pcall(call, "dex_set_fps_cap", { fpsCap = -1 }, execute))
	assert(call("dex_set_fps_cap", { fpsCap = 144 }, execute).requestedFpsCap == 144 and cap == 144)
	assert(call("dex_set_clipboard", { text = "Dex" }, execute).copied and clipboard == "Dex")
	assert(not pcall(call, "dex_click_button", { instanceId = lid }, execute))
	local path = { path = "test.luau" }
	assert(not pcall(call, "dex_read_file", path))
	assert(not pcall(call, "dex_write_file", { path = "../secret", text = "x" }, execute))
	assert(not pcall(call, "dex_write_file", { path = "folder/COM1.txt", text = "x" }, execute))
	assert(not pcall(call, "dex_write_file", { path = "folder\\outside", text = "x" }, execute))
	assert(call("dex_write_file", { path = path.path, text = "return " }, execute).written)
	assert(call("dex_append_file", { path = path.path, text = "42" }, execute).appended)
	assert(files["dex/bridge-files/test.luau"] == "return 42")
	assert(call("dex_read_file", path, execute).text == "return 42")
	assert(call("dex_file_exists", path, execute).file)
	local run = call("dex_load_file", path, execute)
	assert(run.runId)
	assert(call("dex_delete_file", path, execute).deleted)
	assert(not call("dex_file_exists", path, execute).file)
	assert(not pcall(call, "dex_draw_create", { kind = "Line" }))
	local drawing = call("dex_draw_create", { kind = "Line", properties = { Visible = true, Remove = false } }, execute)
	assert(drawing.errors.Remove and drawingHandles[1].Visible and #call("dex_list_drawings").drawings == 1)
	assert(
		call("dex_draw_update", { drawingId = drawing.drawingId, properties = { Thickness = 3 } }, execute).applied[1]
			== "Thickness"
	)
	assert(call("dex_draw_clear", {}, execute).removed == 1 and drawingHandles[1].Removed)
	assert(not pcall(call, "dex_draw_remove", { drawingId = drawing.drawingId }, execute))
	call("dex_draw_create", { kind = "Text" }, execute)
	assert(call("dex_crypt_hash", { data = "sample" }).hash == "sha256:sample")
	local decoded = call("dex_crypt_base64_decode", { data = "/w==" })
	assert(decoded.encoding == "base64" and decoded.data == "/w==")
	assert(not pcall(call, "dex_crypt_generate_key"))
	local bounds = call("dex_get_bounds", { instanceIds = { lid } })
	assert(bounds.size.type == "Vector3" and bounds.pivot.type == "CFrame")
	local ok = pcall(call, "dex_rename_instance", { instanceId = lid, name = "Denied" })
	assert(not ok and left.Name == "Same", "new edit commands retain core permission enforcement")
	call("dex_rename_instance", { instanceId = lid, name = "Changed" }, edit)
	assert(left.Name == "Changed")
	local state = call("dex_get_history")
	call("dex_undo", { expectedIndex = state.index, expectedHead = state.head }, edit)
	assert(left.Name == "Same")
	local duplicated = call("dex_duplicate_instances", { instanceIds = { lid } }, edit)
	assert(#duplicated.instances == 1 and duplicated.instances[1].id ~= lid, "duplicates receive new identities")
	local duplicate = bridge.Registry:Resolve(duplicated.instances[1].id)
	assert(duplicate.Parent == parent and duplicate.Name == left.Name)
	state = call("dex_get_history")
	call("dex_undo", { expectedIndex = state.index, expectedHead = state.head }, edit)
	assert(duplicate.Parent == nil, "duplicate parenting is reversible")
	local pivot = bridge.Codec:Encode(CFrame.new(5, 6, 7))
	call("dex_set_pivot", { instanceId = lid, pivot = pivot }, edit)
	assert(left:GetPivot().Position == vec(5, 6, 7))
	state = call("dex_get_history")
	call("dex_undo", { expectedIndex = state.index, expectedHead = state.head }, edit)
	assert(left:GetPivot().Position == vec(0, 0, 0), "absolute pivot changes use real history")
	local saved = call("dex_save_camera")
	local camera = workspace.CurrentCamera
	local oldFov = camera.FieldOfView
	camera.FieldOfView = 40
	call("dex_restore_camera", { snapshotId = saved.snapshotId }, edit)
	assert(camera.FieldOfView == oldFov, "saved camera restoration uses typed property writes")
	local checked = call("dex_check_luau", { source = "error('must never execute')" })
	assert(checked.valid and not checked.executed)
	assert(not call("dex_check_luau", { source = "local =" }).valid, "syntax checker reports actual compile failures")
	local beforeFocus = camera.CFrame
	local originalCameraType = Enum.CameraType
	local cameraEnum = setmetatable({}, {
		__tostring = function()
			return "Enum.CameraType"
		end,
	})
	Enum.CameraType = { Scriptable = { Name = "Scriptable", EnumType = cameraEnum, __bridgeType = "EnumItem" } }
	camera.ViewportSize = Vector2.new(800, 600)
	call("dex_focus_camera", { instanceIds = { lid } }, edit)
	assert(
		camera.CFrame.Position ~= beforeFocus.Position and camera.CameraType == Enum.CameraType.Scriptable,
		"framing targets actual geometry with Scriptable camera"
	)
	call("dex_restore_camera", { snapshotId = saved.snapshotId }, edit)
	Enum.CameraType = originalCameraType
	local originalRaycast, originalParams = workspace.Raycast, RaycastParams
	RaycastParams = {
		new = function()
			return {}
		end,
	}
	workspace.Raycast = function(_, origin, direction, params)
		assert(origin == vec(0, 0, 0) and direction == vec(0, 0, -20) and params.FilterDescendantsInstances[1] == right)
		return {
			Instance = left,
			Position = vec(0, 0, -4),
			Normal = vec(0, 0, 1),
			Distance = 4,
			Material = Enum.Material.Plastic,
		}
	end
	local ray = call("dex_raycast", {
		origin = { type = "Vector3", x = 0, y = 0, z = 0 },
		direction = { type = "Vector3", x = 0, y = 0, z = -20 },
		excludeIds = { bridge.Registry:Id(right) },
	})
	assert(
		ray.hit and ray.instance.id == lid and ray.distance == 4,
		"ray tool returns engine result and exact hit identity"
	)
	workspace.Raycast = originalRaycast
	RaycastParams = originalParams
	API.Classes.Frame =
		{ Name = "Frame", Superclass = "Instance", Tags = {}, Properties = { { Name = "Rotation", Tags = {} } } }
	local gui = Instance.new("Frame", parent)
	gui.Rotation = 0
	gui.AnchorPoint = Vector2.new(0, 0)
	gui.Visible = true
	gui.LayoutOrder = 0
	local gid = bridge.Registry:Id(gui)
	call("dex_set_ui_layout", { instanceIds = { gid }, properties = { Rotation = 45 } }, edit)
	assert(
		call("dex_get_ui_layout", { instanceId = gid }).layout.Rotation == 45,
		"UI layout edits and reads use actual metadata/property adapter"
	)
	local denied = pcall(call, "dex_set_ui_layout", { instanceIds = { gid }, properties = { Source = "bad" } }, edit)
	assert(not denied, "layout adapter cannot bypass Source write policy")
	local originalSpawn = task.spawn
	task.spawn = function(fn)
		return coroutine.create(fn)
	end
	local delayedScript = Instance.new("ModuleScript", parent)
	local originalMethod = methods.IsA
	methods.IsA = function(self, class)
		return class == "LuaSourceContainer" and self.ClassName == "ModuleScript" or originalMethod(self, class)
	end
	local waiting = call("dex_read_script", { instanceId = bridge.Registry:Id(delayedScript) })
	assert(
		waiting.status == "running" and call("dex_cancel_job", { jobId = waiting.jobId }).status == "cancelled",
		"jobs can be cancelled before scheduled work starts"
	)
	methods.IsA = originalMethod
	task.spawn = originalSpawn
	delayedScript:Destroy()
	local originalIsA = methods.IsA
	methods.IsA = function(self, class)
		return class == "LuaSourceContainer" and self.ClassName == "ModuleScript" or originalIsA(self, class)
	end
	local scriptObject = Instance.new("ModuleScript", parent)
	scriptObject.Source = "local one = 1\nlocal two = 2\nreturn one + two"
	local sid = bridge.Registry:Id(scriptObject)
	local read = call("dex_read_script", { instanceId = sid, startLine = 2, lineCount = 1 })
	local finished = call("dex_get_job", { jobId = read.jobId })
	assert(
		finished.status == "completed"
			and finished.result.source == "local two = 2"
			and finished.result.sourceKind == "Readable source",
		"script line reads are bounded asynchronous jobs"
	)
	assert(
		call("dex_cancel_job", { jobId = read.jobId }).status == "completed",
		"cancelling completed work does not rewrite its result"
	)
	Apps.Explorer.SyncHistoryObject(left)
	Apps.Explorer.SyncHistoryObject(scriptObject)
	scriptObject.Source = "local x = workspace['Same']"
	local refs = call("dex_find_references", { instanceId = lid })
	local matches = call("dex_get_job", { jobId = refs.jobId })
	assert(
		matches.status == "completed" and #matches.result.scripts >= 1,
		"reference job uses production scanner and labels script evidence"
	)
	methods.IsA = originalIsA
	-- Exercise the real bounded ActivitySession through the bridge (signal doubles).
	service.RunService = service.RunService or {}
	local originalHeartbeat = service.RunService.Heartbeat
	service.RunService.Heartbeat = signal()
	left.Changed = signal()
	left.AttributeChanged = signal()
	local watch = call("dex_watch_instance", { instanceId = lid })
	assert(#call("dex_list_watches").watches == 1)
	left.Name = "watched"
	left.Changed:Fire("Name")
	local events = call("dex_get_events", { watchId = watch.watchId })
	assert(#events.events >= 1 and events.events[1].name == "Name", "activity tools report actual recorder events")
	local after = call("dex_get_events", { watchId = watch.watchId, afterId = events.nextId })
	assert(#after.events == 0, "event cursor avoids replaying older events")
	call("dex_stop_watch", { watchId = watch.watchId })
	assert(#call("dex_list_watches").watches == 0)
	service.RunService.Heartbeat = originalHeartbeat
	bridge:Destroy()
	assert(drawingHandles[2].Removed, "bridge teardown removes owned drawings")
	parent:Destroy()
	print(
		"PASS: expanded MCP adapters: exact paths/schema, duplication and pivot undo, camera snapshots, syntax-only compilation, source jobs, references, real activity watches and cursors"
	)
end

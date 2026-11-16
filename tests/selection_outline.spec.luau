--!strict

do
	local stub = Explorer.UpdateSelectionVisuals
	Explorer.UpdateSelectionVisuals = productionSelectionVisuals
	local showGui = Lib.ShowGui
	Lib.ShowGui = function() end
	local previous = Settings.Explorer.PartSelectionBox
	local oldSelection = table.clone(Explorer.Selection.List)
	local oldWorkspace, oldRunService, oldCamera = service.Workspace, service.RunService, workspace.CurrentCamera
	local oldReader, oldWriter = deps.env.gethiddenproperty, deps.env.sethiddenproperty
	local probe = Instance.new("Highlight")
	local mt = getmetatable(probe)
	local oldNewIndex = mt.__newindex
	local hiddenWrites = 0
	mt.__newindex = function(object, key, value)
		if
			key == "ReservedId"
			or key == "StudioSelectionBox"
			or (object.ClassName == "Highlight" and key == "LineThickness")
		then
			error("private rendering property must never be configured")
		end
		return oldNewIndex(object, key, value)
	end
	deps.env.sethiddenproperty = function(object, key, value)
		hiddenWrites += 1
		oldNewIndex(object, key, value)
	end
	deps.env.gethiddenproperty = function(object, key)
		return object[key]
	end
	local projection = { X = 120, Y = 80, Z = 10 }
	local onScreen = true
	local frameSignal = signal()
	workspace.CurrentCamera = {
		WorldToScreenPoint = function(_, position)
			assert(position.Marker == true, "selection marker uses the object's pivot")
			return projection, onScreen
		end,
	}
	service.Workspace = workspace
	service.RunService = { RenderStepped = frameSignal }
	Settings.Explorer.PartSelectionBox = true
	local root = Instance.new("Model", workspace)
	root.Name = "OutlineFixture"
	local child = Instance.new("Part", root)
	child.Name = "Shape"
	local visible = Instance.new("Part", root)
	visible.Name = "VisibleShape"
	root.GetPivot = function()
		return { Position = { Marker = true } }
	end
	Explorer.SyncHistoryObject(root)
	Explorer.SyncHistoryObject(child)
	local registry = Explorer.GetNodes()
	local previousViewNode = Explorer.ViewNode
	local viewedNode
	Explorer.ViewNode = function(node)
		viewedNode = node
	end
	child.Locked = true
	assert(
		Explorer.SelectObject(child) and Explorer.Selection.List[1] == registry[child] and viewedNode == registry[child],
		"shared click picker selects and reveals the exact part even inside a Model or when locked"
	)
	assert(
		not Explorer.SelectObject(nil) and Explorer.Selection.List[1] == registry[child],
		"shared picker preserves selection on an empty click"
	)
	local newborn = Instance.new("Part", root)
	assert(
		Explorer.SelectObject(newborn) and Explorer.Selection.List[1] == registry[newborn],
		"shared picker reconciles newly created targets before selecting them"
	)
	newborn:Destroy()
	child.Locked = false
	Explorer.ViewNode = previousViewNode
	local oldParams, oldRaycast, oldPointer =
		RaycastParams, workspace.Raycast, service.UserInputService.GetMouseLocation
	local oldCharacter, oldFilter = service.Players.LocalPlayer.Character, Main.Mouse.TargetFilter
	local oldGuiService, oldUIHit = service.GuiService, Main.IsPointInDexUI
	local oldRootsForPick = Main.SelectionGeometryRoots
	local own = Instance.new("Folder", workspace)
	local character = Instance.new("Model", workspace)
	service.Players.LocalPlayer.Character = character
	Main.SelectionGeometryRoots = { [own] = true }
	service.GuiService = {
		GetGuiInset = function()
			return Vector2.new(20, 20)
		end,
	}
	Main.Mouse.TargetFilter = child -- a game-owned filter must not redirect the inspector
	local invisibleHitbox = Instance.new("Part", workspace)
	invisibleHitbox.Transparency = 1
	invisibleHitbox.LocalTransparencyModifier = 0
	child.Transparency = 0
	child.LocalTransparencyModifier = 0
	RaycastParams = {
		new = function()
			return {}
		end,
	}
	local direction = setmetatable({}, {
		__mul = function(_, distance)
			assert(distance == 15000)
			return "ray-direction"
		end,
	})
	local screenCalls, viewportCalls = 0, 0
	workspace.CurrentCamera = {
		ScreenPointToRay = function(_, x, y)
			assert(x == 50 and y == 60)
			screenCalls += 1
			return { Origin = "origin", Direction = direction }
		end,
		ViewportPointToRay = function(_, x, y)
			assert(x == 70 and y == 80)
			viewportCalls += 1
			return { Origin = "origin", Direction = direction }
		end,
	}
	service.UserInputService.GetMouseLocation = function()
		return Vector2.new(70, 80)
	end
	local casts = 0
	local dexUIHit = false
	local uiChecks = 0
	Main.IsPointInDexUI = function(x, y)
		assert(x == 50 and y == 60, "legacy live pointer and transform input use the same core-UI hit-test coordinates")
		uiChecks += 1
		return dexUIHit
	end
	workspace.Raycast = function(_, origin, d, params)
		casts += 1
		assert(origin == "origin" and d == "ray-direction")
		assert(
			table.find(params.FilterDescendantsInstances, own)
				and table.find(params.FilterDescendantsInstances, character),
			"world picker excludes proxy geometry and local character"
		)
		assert(
			not table.find(params.FilterDescendantsInstances, child),
			"game Mouse.TargetFilter must not make a visible target disappear"
		)
		if not table.find(params.FilterDescendantsInstances, invisibleHitbox) then
			return { Instance = invisibleHitbox }
		end
		return { Instance = child }
	end
	assert(
		Explorer.PickWorld(Vector2.new(50, 60)) and Explorer.Selection.List[1] == registry[child] and casts == 2,
		"world picker passes through invisible blockers to the actual visible part"
	)
	assert(
		Explorer.PickWorld() and screenCalls == 1 and viewportCalls == 1,
		"input-event and live pointer use their matching camera coordinate APIs"
	)
	local beforeBlocked = casts
	dexUIHit = true
	assert(
		not Explorer.PickWorld() and not Explorer.PickWorld(Vector2.new(50, 60)),
		"both legacy and transform callers refuse clicks owned by Dex UI"
	)
	assert(
		casts == beforeBlocked and Explorer.Selection.List[1] == registry[child],
		"blocked UI clicks never cast through to the world or replace selection"
	)
	assert(uiChecks == 4, "every pick path applies the shared UI ownership guard")
	dexUIHit = false
	workspace.Raycast = function()
		return nil
	end
	assert(
		not Explorer.PickWorld() and Explorer.Selection.List[1] == registry[child],
		"empty ray preserves the current selection"
	)
	RaycastParams, workspace.Raycast, service.UserInputService.GetMouseLocation = oldParams, oldRaycast, oldPointer
	service.Players.LocalPlayer.Character, Main.Mouse.TargetFilter = oldCharacter, oldFilter
	Main.SelectionGeometryRoots = oldRootsForPick
	service.GuiService, Main.IsPointInDexUI = oldGuiService, oldUIHit
	workspace.CurrentCamera = {
		WorldToScreenPoint = function(_, p)
			assert(p.Marker)
			return projection, onScreen
		end,
	}
	invisibleHitbox:Destroy()
	own:Destroy()
	character:Destroy()
	local oldGeometryRoots = Main.SelectionGeometryRoots
	local internalRoot = Instance.new("Folder")
	Main.SelectionGeometryRoots = { [internalRoot] = true }
	internalRoot.Parent = workspace
	local internalModel = Instance.new("Model", internalRoot)
	Explorer.SyncHistoryObject(internalRoot)
	Explorer.SyncHistoryObject(internalModel)
	assert(
		not registry[internalRoot] and not registry[internalModel],
		"selection geometry copies stay outside Explorer's object and search registry"
	)
	internalRoot:Destroy()
	Main.SelectionGeometryRoots = oldGeometryRoots
	Explorer.Selection:SetTable({ registry[root], registry[child] })
	Explorer.UpdateSelectionVisuals()
	local manager = Explorer.SelectionVisualManager
	local record = manager.Records[root]
	local outline, dot = record.Highlight, manager.PivotDot
	assert(
		#Explorer.SelectionVisualsHolder:GetChildren() == 2 and outline.Adornee == root and not manager.Records[child],
		"Explorer delegates model selection and descendant suppression to renderer"
	)
	assert(
		outline.ReservedId == nil
			and outline.FillTransparency == 1
			and Explorer.SelectionRenderingMode == "PublicFallback",
		"private property access never selects Studio's reserved renderer"
	)
	assert(
		dot.Name == "SelectionDot" and dot.Size == UDim2.fromOffset(3, 3) and dot.BorderSizePixel == 1 and dot.Visible,
		"small bordered pivot marker remains present"
	)
	Explorer.UpdateSelectionVisuals()
	assert(
		record == manager.Records[root] and outline == record.Highlight,
		"Explorer reuses selection renderer records"
	)
	assert(dot.Position == UDim2.fromOffset(120, 80), "marker is screen-projected at the pivot")
	projection = { X = 220, Y = 150, Z = 10 }
	frameSignal:Fire()
	assert(dot.Position == UDim2.fromOffset(220, 150), "marker follows camera or object motion")
	onScreen = false
	frameSignal:Fire()
	assert(not dot.Visible, "offscreen marker is hidden")
	onScreen = true
	local folder = Instance.new("Folder", workspace)
	local nested = Instance.new("Folder", folder)
	local shape = Instance.new("Part", nested)
	shape.GetPivot = root.GetPivot
	Explorer.SyncHistoryObject(folder)
	Explorer.SyncHistoryObject(nested)
	Explorer.SyncHistoryObject(shape)
	Explorer.Selection:SetTable({ registry[folder], registry[nested] })
	Explorer.UpdateSelectionVisuals()
	record = manager.Records[shape]
	assert(
		manager.Counts.Roots == 1 and record.Highlight.Adornee == shape,
		"nested folder selections delegate geometry once"
	)
	shape.Transparency = 1
	shape:GetPropertyChangedSignal("Transparency"):Fire()
	assert(not record.Highlight and record.Parts[shape].Bounds, "live invisible geometry uses public bounds")
	assert(
		record.Parts[shape].Bounds.StudioSelectionBox == nil and record.Parts[shape].Bounds.LineThickness == 0.02,
		"bounds never enable private Studio mode"
	)
	child.Transparency = 1
	Explorer.Selection:SetTable({ registry[root] })
	Explorer.UpdateSelectionVisuals()
	record = manager.Records[root]
	assert(
		record.Highlight and record.Parts[child].Bounds and not record.Bounds,
		"model combines visible silhouette and actual invisible-child bounds"
	)
	child.Transparency = 0
	child:GetPropertyChangedSignal("Transparency"):Fire()
	assert(
		not record.Parts[child].Bounds and #Explorer.SelectionVisualsHolder:GetChildren() == 2,
		"invisible-child fallback updates without rebuilding roots"
	)
	Explorer.Selection:Clear()
	Explorer.UpdateSelectionVisuals()
	assert(
		#Explorer.SelectionVisualsHolder:GetChildren() == 0 and manager.Counts.Roots == 0,
		"clearing selection removes all visuals"
	)
	manager:Destroy()
	Explorer.SelectionVisualManager = nil
	root:Destroy()
	folder:Destroy()
	Settings.Explorer.PartSelectionBox = previous
	Explorer.Selection:SetTable(oldSelection)
	Explorer.UpdateSelectionVisuals = stub
	Lib.ShowGui = showGui
	workspace.CurrentCamera = oldCamera
	service.Workspace, service.RunService = oldWorkspace, oldRunService
	deps.env.gethiddenproperty, deps.env.sethiddenproperty = oldReader, oldWriter
	mt.__newindex = oldNewIndex
	probe:Destroy()
	assert(hiddenWrites == 0, "no private rendering property written during real Explorer selection changes")
	print(
		"PASS: Explorer selection renderer integration, retained visuals, safe public rendering, invisible-child bounds, markers and cleanup"
	)
end

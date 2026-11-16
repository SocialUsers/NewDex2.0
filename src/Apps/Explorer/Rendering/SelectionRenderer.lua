--!strict

local Main, service

------------------------------ Initialization ------------------------------

local function InitDeps(d)
	Main, service = d.Main, d.service
end
------------------------------ Module ------------------------------

local function CreateModule()
	local Renderer = {}
	local function disconnect(list)
		for _, connection in ipairs(list) do
			connection:Disconnect()
		end
		table.clear(list)
	end
	local function destroy(object)
		if object then
			object:Destroy()
		end
	end
	local function invisible(part)
		local t = part.Transparency or 0
		local localT = part.LocalTransparencyModifier or 0
		return 1 - (1 - t) * (1 - localT) >= 1
	end
	function Renderer.Create(config)
		local parent = config.Parent
		local workspace = config.Workspace or service.Workspace
		local maxHighlights = config.MaxHighlights or 255
		local maxBounds = config.MaxBounds or 1000
		local manager = {
			Records = {},
			Folders = {},
			Counts = { Roots = 0, Highlights = 0, Bounds = 0, OmittedBounds = 0 },
			Destroyed = false,
		}
		manager.InspectorRecords = manager.Records
		local selection, selectionWatches = {}, {}
		local options = { PartEnabled = true, GuiEnabled = true, Color = Color3.fromRGB(0, 170, 255) }
		local pendingBounds, pendingHighlights = {}, {}
		local frameConnection, reconcileQueued, balanceQueued
		local reconcile, balance, updateRoot, removeRecord
		local function excluded(object)
			return config.IsExcluded and config.IsExcluded(object)
		end
		local function spatial(object)
			return (object:IsA("BasePart") or object:IsA("Model"))
				and not object:IsA("Terrain")
				and object ~= workspace
				and not excluded(object)
				and object:IsDescendantOf(workspace)
		end
		local function bind(list, event, callback)
			list[#list + 1] = event:Connect(callback)
		end
		local function queueBalance()
			if balanceQueued or manager.Destroyed then
				return
			end
			balanceQueued = true
			task.defer(function()
				balanceQueued = false
				if not manager.Destroyed then
					balance()
				end
			end)
		end
		local function clearPending(state)
			if pendingBounds[state] then
				pendingBounds[state] = nil
				manager.Counts.OmittedBounds -= 1
			end
		end
		local function releaseBounds(state)
			clearPending(state)
			if state.Bounds then
				state.Bounds:Destroy()
				state.Bounds = nil
				manager.Counts.Bounds -= 1
				queueBalance()
			end
		end
		local function requestBounds(state, target)
			if state.Bounds then
				return
			end
			if manager.Counts.Bounds >= maxBounds then
				if not pendingBounds[state] then
					pendingBounds[state] = target
					manager.Counts.OmittedBounds += 1
				end
				return
			end
			clearPending(state)
			local box = Instance.new("SelectionBox")
			box.Name = "SelectionBounds"
			box.Color3 = options.Color
			box.LineThickness = config.BoundsThickness or 0.02
			box.SurfaceTransparency = 1
			box.Transparency = 0
			box.Adornee = target
			box.Parent = parent
			state.Bounds = box
			manager.Counts.Bounds += 1
		end
		local function releaseHighlight(record)
			pendingHighlights[record] = nil
			if record.Highlight then
				record.Highlight:Destroy()
				record.Highlight = nil
				manager.Counts.Highlights -= 1
				queueBalance()
			end
		end
		local function requestHighlight(record, target)
			if record.Highlight then
				return
			end
			if manager.Counts.Highlights >= maxHighlights then
				pendingHighlights[record] = true
				return
			end
			pendingHighlights[record] = nil
			local highlight = Instance.new("Highlight")
			highlight.Name = "SelectionOutline"
			highlight.FillTransparency = 1
			highlight.OutlineTransparency = 0
			highlight.OutlineColor = options.Color
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Adornee = target or record.Object
			highlight.Parent = parent
			record.Highlight = highlight
			manager.Counts.Highlights += 1
		end
		local function queueReconcile()
			if reconcileQueued or manager.Destroyed then
				return
			end
			reconcileQueued = true
			task.defer(function()
				reconcileQueued = false
				if not manager.Destroyed then
					reconcile()
				end
			end)
		end
		local function updatePart(record, state)
			if manager.Destroyed or record.Destroyed or state.Destroyed then
				return
			end
			local hidden = invisible(state.Object)
			if hidden == state.Invisible then
				return
			end
			if hidden ~= state.Invisible then
				record.VisibleParts += (hidden and -1 or 1)
				record.HiddenParts += (hidden and 1 or -1)
				state.Invisible = hidden
			end
			updateRoot(record)
			if
				hidden
				and not record.PreparingMask
				and not (record.MaskActive and record.Mask and record.Mask.Entries[state.Object])
			then
				requestBounds(state, state.Object)
			else
				releaseBounds(state)
			end
		end
		local function removePart(record, part)
			local state = record.Parts[part]
			if not state then
				return
			end
			state.Destroyed = true
			record.Parts[part] = nil
			disconnect(state.Connections)
			if state.Invisible then
				record.HiddenParts -= 1
			else
				record.VisibleParts -= 1
			end
			if record.Mask then
				record.Mask:Remove(part)
			end
			releaseBounds(state)
			updateRoot(record)
		end
		local function watchPart(record, part)
			if not part:IsA("BasePart") or part:IsA("Terrain") or excluded(part) or record.Parts[part] then
				return
			end
			local state = { Object = part, Connections = {}, Invisible = invisible(part) }
			record.Parts[part] = state
			if state.Invisible then
				record.HiddenParts += 1
			else
				record.VisibleParts += 1
			end
			if record.Mask then
				record.Mask:Add(part)
			end
			bind(state.Connections, part:GetPropertyChangedSignal("Transparency"), function()
				updatePart(record, state)
			end)
			bind(state.Connections, part:GetPropertyChangedSignal("LocalTransparencyModifier"), function()
				updatePart(record, state)
			end)
			bind(state.Connections, part.AncestryChanged, function()
				if part ~= record.Object and not part:IsDescendantOf(record.Object) then
					removePart(record, part)
				end
			end)
			if not record.Collecting then
				updateRoot(record)
				if state.Invisible and not record.PreparingMask and not record.MaskActive then
					requestBounds(state, part)
				end
			end
		end
		updateRoot = function(record)
			if manager.Destroyed or record.Destroyed or record.Kind == "Gui" then
				return
			end
			local previousProblem = record.MaskUnavailable
			if record.Mask and record.Mask.Failed then
				record.MaskUnavailable = record.Mask.Problem
				record.Mask:Destroy()
				record.Mask = nil
			end
			if record.HiddenParts > 0 and config.GeometryMask and not record.Mask and not record.MaskUnavailable then
				local mask, problem = config.GeometryMask.Create(record.Parts, function()
					if not record.Destroyed then
						updateRoot(record)
					end
				end)
				record.Mask = mask
				record.MaskUnavailable = problem
			elseif record.HiddenParts == 0 and record.Mask then
				record.Mask:Destroy()
				record.Mask = nil
			end
			if record.MaskUnavailable and record.MaskUnavailable ~= previousProblem then
				manager.LastGeometryProblem = record.MaskUnavailable
				if config.ReportFailure then
					config.ReportFailure(record.Object, record.MaskUnavailable)
				end
			end
			local maskReady = record.Mask and record.Mask.Ready and not record.Mask.Failed
			local wasPreparing = record.PreparingMask
			record.PreparingMask = record.Mask ~= nil and not maskReady
			if record.PreparingMask then
				record.WantsHighlight = false
				record.RenderingMode = "PreparingGeometryMask"
				pendingHighlights[record] = nil
				if record.Highlight then
					record.Highlight.Enabled = false
				end
				releaseBounds(record)
				if not wasPreparing then
					for _, state in pairs(record.Parts) do
						releaseBounds(state)
					end
				end
				record.MaskActive = false
				record.MaskVersion = -1
				return
			end
			local want = record.VisibleParts > 0 or maskReady
			record.WantsHighlight = want
			if want then
				requestHighlight(record, maskReady and record.Mask.Model or record.Object)
			else
				releaseHighlight(record)
			end
			if record.Highlight then
				record.Highlight.Adornee = maskReady and record.Mask.Model or record.Object
				record.Highlight.Enabled = true
				record.RenderingMode = maskReady and "CombinedGeometryMask" or "PublicFallback"
				releaseBounds(record)
			else
				if record.VisibleParts > 0 then
					requestBounds(record, record.Object)
				else
					releaseBounds(record)
				end
			end
			local maskActive = not not (maskReady and record.Highlight)
			local maskVersion = record.Mask and record.Mask.Version or 0
			if record.MaskActive ~= maskActive or record.MaskVersion ~= maskVersion then
				record.MaskActive = maskActive
				record.MaskVersion = maskVersion
				for _, state in pairs(record.Parts) do
					if state.Invisible and not (maskActive and record.Mask.Entries[state.Object]) then
						requestBounds(state, state.Object)
					else
						releaseBounds(state)
					end
				end
			end
		end
		balance = function()
			for record in pairs(pendingHighlights) do
				if record.Destroyed or not record.WantsHighlight then
					pendingHighlights[record] = nil
				elseif manager.Counts.Highlights < maxHighlights then
					updateRoot(record)
				end
			end
			for state, target in pairs(pendingBounds) do
				if state.Destroyed then
					clearPending(state)
				elseif manager.Counts.Bounds < maxBounds then
					requestBounds(state, target)
				end
			end
		end
		local function style(record)
			if record.Highlight then
				record.Highlight.OutlineColor = options.Color
			end
			if record.Bounds then
				record.Bounds.Color3 = options.Color
			end
			if record.Parts then
				for _, state in pairs(record.Parts) do
					if state.Bounds then
						state.Bounds.Color3 = options.Color
					end
				end
			end
		end
		local dotRoots = {}
		local function updateDots()
			local roots = dotRoots
			table.clear(roots)
			for _, record in pairs(manager.Records) do
				if record.Mask then
					local mask = record.Mask
					local ok, problem = pcall(mask.Step, mask)
					if not ok then
						mask:Fail(problem)
					end
				end
				if record.Kind ~= "Gui" and record.Object.Parent then
					roots[#roots + 1] = record.Object
				end
			end
			local dot = manager.PivotDot
			if not dot then
				return
			end
			local camera = workspace.CurrentCamera
			local ok, position, onScreen = pcall(function()
				if not camera or #roots == 0 then
					return nil, false
				end
				local pivot
				if #roots == 1 then
					pivot = roots[1]:GetPivot()
				elseif config.SelectionPivot then
					pivot = config.SelectionPivot(roots)
				end
				if not pivot then
					return nil, false
				end
				return camera:WorldToScreenPoint(pivot.Position)
			end)
			local visible = ok and position ~= nil and onScreen and position.Z > 0
			if dot.Visible ~= visible then
				dot.Visible = visible
			end
			if visible then
				local nextPosition = UDim2.fromOffset(math.floor(position.X + 0.5), math.floor(position.Y + 0.5))
				if dot.Position ~= nextPosition then
					dot.Position = nextPosition
				end
			end
		end
		local function updateFrame()
			local needed = false
			for _, record in pairs(manager.Records) do
				if record.Kind ~= "Gui" then
					needed = true
					break
				end
			end
			if needed and not manager.PivotDot then
				local dot = Instance.new("Frame")
				dot.Name = "SelectionDot"
				dot.Size = UDim2.fromOffset(3, 3)
				dot.BackgroundColor3 = Color3.new(1, 1, 1)
				dot.BorderColor3 = Color3.new(0, 0, 0)
				dot.BorderSizePixel = 1
				dot.Selectable = false
				dot.Active = false
				dot.Visible = false
				dot.Parent = parent
				manager.PivotDot = dot
			elseif not needed then
				destroy(manager.PivotDot)
				manager.PivotDot = nil
				table.clear(dotRoots)
			end
			if needed and not frameConnection then
				frameConnection = service.RunService.RenderStepped:Connect(updateDots)
			elseif not needed and frameConnection then
				frameConnection:Disconnect()
				frameConnection = nil
			end
			if needed then
				updateDots()
			end
		end
		local function addRecord(object)
			local record = {
				Object = object,
				Connections = {},
				Kind = object:IsA("GuiObject") and "Gui" or object:IsA("Model") and "Model" or "Part",
			}
			manager.Records[object] = record
			manager.Counts.Roots += 1
			if record.Kind == "Gui" then
				if config.AttachGui then
					record.Gui, record.GuiCleanup = config.AttachGui(object, parent)
				end
			else
				record.Parts = {}
				record.VisibleParts = 0
				record.HiddenParts = 0
				record.Collecting = true
				if record.Kind == "Part" then
					watchPart(record, object)
				end
				for _, part in ipairs(object:GetDescendants()) do
					watchPart(record, part)
				end
				record.Collecting = false
				bind(record.Connections, object.DescendantAdded, function(part)
					watchPart(record, part)
				end)
				bind(record.Connections, object.DescendantRemoving, function(part)
					removePart(record, part)
				end)
				updateRoot(record)
			end
			bind(record.Connections, object.AncestryChanged, queueReconcile)
			return record
		end
		removeRecord = function(record)
			if record.Destroyed then
				return
			end
			record.Destroyed = true
			manager.Records[record.Object] = nil
			manager.Counts.Roots -= 1
			disconnect(record.Connections)
			if record.Parts then
				for _, state in pairs(record.Parts) do
					state.Destroyed = true
					disconnect(state.Connections)
					releaseBounds(state)
				end
				table.clear(record.Parts)
			end
			releaseHighlight(record)
			releaseBounds(record)
			if record.Mask then
				record.Mask:Destroy()
				record.Mask = nil
			end
			if type(record.GuiCleanup) == "function" then
				record.GuiCleanup()
			elseif record.GuiCleanup and record.GuiCleanup.Destroy then
				record.GuiCleanup.Destroy()
			end
			destroy(record.Gui)
		end
		reconcile = function()
			if manager.Destroyed then
				return
			end
			local expanded, folders, seen = {}, {}, {}
			local function append(object)
				if not seen[object] then
					seen[object] = true
					expanded[#expanded + 1] = object
				end
			end
			for _, object in ipairs(selection) do
				if object:IsA("Folder") then
					if options.PartEnabled then
						folders[object] = true
					end
				else
					append(object)
				end
			end
			local folderQueue = {}
			for folder in pairs(folders) do
				folderQueue[#folderQueue + 1] = folder
			end
			local index = 1
			while index <= #folderQueue do
				local folder = folderQueue[index]
				index += 1
				for _, object in ipairs(folder:GetChildren()) do
					if object:IsA("Folder") then
						if not folders[object] then
							folders[object] = true
							folderQueue[#folderQueue + 1] = object
						end
					elseif object:IsA("BasePart") or object:IsA("Model") then
						append(object)
					end
				end
			end
			for folder, record in pairs(manager.Folders) do
				if not folders[folder] then
					disconnect(record.Connections)
					manager.Folders[folder] = nil
				end
			end
			for folder in pairs(folders) do
				if not manager.Folders[folder] then
					local record = { Connections = {} }
					manager.Folders[folder] = record
					bind(record.Connections, folder.ChildAdded, queueReconcile)
					bind(record.Connections, folder.ChildRemoved, queueReconcile)
					bind(record.Connections, folder.AncestryChanged, queueReconcile)
				end
			end
			local wanted, spatialCandidates = {}, {}
			for _, object in ipairs(expanded) do
				if options.PartEnabled and spatial(object) then
					spatialCandidates[object] = true
				end
			end
			for _, object in ipairs(expanded) do
				if spatialCandidates[object] then
					local ancestor = object.Parent
					while ancestor and not spatialCandidates[ancestor] do
						ancestor = ancestor.Parent
					end
					if not ancestor then
						wanted[object] = true
					end
				elseif
					options.GuiEnabled
					and object.Parent
					and object:IsA("GuiObject")
					and not excluded(object)
					and not (config.HandlesGui and config.HandlesGui(object))
				then
					wanted[object] = true
				end
			end
			for object, record in pairs(manager.Records) do
				if not wanted[object] then
					removeRecord(record)
				end
			end
			for _, object in ipairs(expanded) do
				if wanted[object] then
					local record = manager.Records[object] or addRecord(object)
					updateRoot(record)
					style(record)
				end
			end
			balance()
			updateFrame()
		end
		function manager:Update(objects, settings)
			if self.Destroyed then
				return
			end
			selection = table.clone(objects or {})
			local selected = {}
			for _, object in ipairs(selection) do
				selected[object] = true
				if not selectionWatches[object] then
					selectionWatches[object] = object.AncestryChanged:Connect(queueReconcile)
				end
			end
			for object, connection in pairs(selectionWatches) do
				if not selected[object] then
					connection:Disconnect()
					selectionWatches[object] = nil
				end
			end
			settings = settings or {}
			options.PartEnabled = settings.PartEnabled ~= false
			options.GuiEnabled = settings.GuiEnabled ~= false
			options.Color = settings.Color or Color3.fromRGB(0, 170, 255)
			reconcile()
		end
		function manager:Destroy()
			table.clear(dotRoots)
			if self.Destroyed then
				return
			end
			self.Destroyed = true
			if frameConnection then
				frameConnection:Disconnect()
				frameConnection = nil
			end
			destroy(self.PivotDot)
			self.PivotDot = nil
			for _, record in pairs(self.Records) do
				removeRecord(record)
			end
			for _, record in pairs(self.Folders) do
				disconnect(record.Connections)
			end
			for _, connection in pairs(selectionWatches) do
				connection:Disconnect()
			end
			table.clear(selectionWatches)
			table.clear(self.Folders)
			table.clear(pendingBounds)
			table.clear(pendingHighlights)
			table.clear(selection)
			self.Counts.OmittedBounds = 0
		end
		if Main and Main.AddCleanup then
			Main.AddCleanup(function()
				manager:Destroy()
			end)
		end
		return manager
	end
	return Renderer
end
return { InitDeps = InitDeps, InitAfterMain = function() end, Main = CreateModule }

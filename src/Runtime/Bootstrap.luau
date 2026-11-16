--!strict

return function(baseUrl, options)
	local started = os.clock()
	local host = getfenv()
	local http = game:GetService("HttpService")
	local getSource = options and options.Fetch or function(path)
		return game:HttpGet(baseUrl .. path)
	end
	local prefetched = options and options.Manifest
	local manifest = http:JSONDecode(prefetched or getSource("manifest.json"))
	assert(manifest.schema == 1, "Unsupported Dex Explorer manifest")
	local stats = {
		Release = manifest.release,
		NetworkRequests = prefetched and 0 or 1,
		ManifestPrefetched = prefetched ~= nil,
		DownloadedBytes = 0,
		CacheHits = 0,
		Modules = 0,
		BundleRequests = 0,
		NativeIntegrityChecks = 0,
	}
	local function verifiedSha256(provider)
		local hash = type(provider) == "table" and provider.hash
		if type(hash) ~= "function" then
			return nil
		end
		local ok, digest = pcall(hash, "Dex Explorer\226\128\148Luau", "sha256")
		if
			ok
			and type(digest) == "string"
			and digest:lower() == "aa7b41355423929a52aec49bf1691136112f9a3aa0dde532217e55fc5b256d6b"
		then
			return hash
		end
	end

	local nativeSha256 = verifiedSha256(crypt) or verifiedSha256(type(syn) == "table" and syn.crypt)
	local directory = "dex/cache/modules"
	local function checksum(data)
		local a, b = 1, 0
		local byte = string.byte
		for offset = 1, #data, 4096 do
			local finish = math.min(offset + 4095, #data)
			local blockEnd = offset + math.floor((finish - offset + 1) / 8) * 8
			for index = offset, blockEnd - 1, 8 do
				local p, q, r, s, t, u, v, w = byte(data, index, index + 7)
				b += 8 * a + 8 * p + 7 * q + 6 * r + 5 * s + 4 * t + 3 * u + 2 * v + w
				a += p + q + r + s + t + u + v + w
			end
			for index = blockEnd, finish do
				a += byte(data, index)
				b += a
			end
			a %= 65521
			b %= 65521
		end
		return b * 65536 + a
	end
	if type(makefolder) == "function" then
		for _, path in ipairs({ "dex", "dex/cache", directory }) do
			pcall(makefolder, path)
		end
	end
	local sources, compiled, results, loaded, loading = {}, {}, {}, {}, {}
	local cacheChecked = {}
	local function valid(source, entry)
		if type(source) ~= "string" or #source ~= entry.bytes then
			return false
		end
		if nativeSha256 and type(entry.sha256) == "string" and #entry.sha256 == 64 and not source:find("\0", 1, true) then
			local ok, digest = pcall(nativeSha256, source, "sha256")
			if ok and type(digest) == "string" and digest:lower() == entry.sha256 then
				stats.NativeIntegrityChecks += 1
				return true
			end
		end
		return checksum(source) == entry.checksum
	end
	local function cacheSource(path, source, entry)
		sources[path] = source
		if type(writefile) == "function" and type(entry.sha256) == "string" then
			pcall(writefile, directory .. "/" .. entry.sha256 .. ".lua", source)
		end
	end
	local function readCached(path, entry)
		if cacheChecked[path] then
			return sources[path] ~= nil
		end
		cacheChecked[path] = true
		if type(readfile) == "function" and type(entry.sha256) == "string" then
			local ok, source = pcall(readfile, directory .. "/" .. entry.sha256 .. ".lua")
			if ok and valid(source, entry) then
				stats.CacheHits += 1
				sources[path] = source
				return true
			end
		end
		return false
	end
	local function fetch(path)
		if sources[path] then
			return sources[path]
		end
		local entry = assert(manifest.files[path], "Unknown module: " .. path)
		if readCached(path, entry) then
			return sources[path]
		end
		local source = getSource(path)
		stats.NetworkRequests += 1
		stats.DownloadedBytes += #source
		assert(valid(source, entry), "Dex Explorer download did not match release: " .. path)
		cacheSource(path, source, entry)
		return source
	end
	local context = setmetatable({
		oldgame = game,
		game = workspace.Parent,
		nodes = {},
		cloneref = cloneref or function(ref)
			return ref
		end,
	}, { __index = host })
	local runtime = { Stats = stats, ModulePaths = manifest.modules }
	context.DexRuntime = runtime
	local global = type(getgenv) == "function" and getgenv() or nil
	local staged, newMain
	if global then
		local proxy = setmetatable({}, {
			__index = function(_, key)
				if key == "DexPlus" and staged then
					return staged
				end
				return global[key]
			end,
			__newindex = function(_, key, value)
				if key == "DexPlus" then
					staged = value
				else
					global[key] = value
				end
			end,
		})
		context.getgenv = function()
			return proxy
		end
	end
	local function execute(path)
		if loaded[path] then
			return results[path]
		end
		assert(not loading[path], "Circular Dex Explorer dependency: " .. path)
		local chunk = compiled[path]
		if not chunk then
			local problem
			chunk, problem = loadstring(fetch(path), "@DexExplorer/" .. path)
			assert(chunk, "Dex Explorer compile failed: " .. path .. ": " .. tostring(problem))
			setfenv(chunk, context)
			compiled[path] = chunk
		end
		loading[path] = true
		local previousPath = runtime.LoadingPath
		runtime.LoadingPath = path
		if runtime.OnModuleLoading then
			runtime.OnModuleLoading(path)
		end
		local ok, value = pcall(chunk)
		loading[path] = nil
		runtime.LoadingPath = previousPath
		if previousPath and runtime.OnModuleLoading then
			runtime.OnModuleLoading(previousPath)
		end
		if not ok then
			error("Dex Explorer module failed: " .. path .. ": " .. tostring(value), 0)
		end
		compiled[path] = nil
		sources[path] = nil
		if path == manifest.modules.Lib and type(value) == "table" and type(value.InitDeps) == "function" then
			local initialize = value.InitDeps
			value.InitDeps = function(deps, ...)
				if type(deps) == "table" and type(deps.Main) == "table" then
					newMain = deps.Main
				end
				return initialize(deps, ...)
			end
		end
		loaded[path] = true
		results[path] = value
		stats.Modules += 1
		return value
	end
	runtime.Require = execute
	local paths, missingBytes = {}, 0
	for path, entry in pairs(manifest.files) do
		if not readCached(path, entry) then
			paths[#paths + 1] = path
			missingBytes += entry.bytes
		end
	end
	table.sort(paths)
	local packetBytes, packetCount = 0, 0
	if manifest.bundle then
		for _, entry in ipairs(manifest.bundles or { manifest.bundle }) do
			local needed = not entry.paths
			for _, path in ipairs(entry.paths or {}) do
				if not sources[path] then
					needed = true
					break
				end
			end
			if needed then
				packetBytes += entry.bytes
				packetCount += 1
			end
		end
	end
	local useBundle = manifest.bundle
		and #paths > 1
		and (
			packetBytes <= missingBytes * 1.35
			or (#paths >= 12 and packetCount * 4 <= #paths and packetBytes <= missingBytes * 3)
		)
	stats.MissingSourceBytes = missingBytes
	stats.CandidatePacketBytes = packetBytes
	stats.Transport = useBundle and "packets" or "individual"
	local function parallel(items, work, label)
		local cursor, remaining, failures = 0, #items, {}
		for _ = 1, math.min(4, #items) do
			task.spawn(function()
				while true do
					cursor += 1
					local item = items[cursor]
					if not item then
						break
					end
					local ok, problem = pcall(work, item)
					if not ok then
						local name = type(item) == "table" and item.path or item
						failures[#failures + 1] = tostring(name) .. ": " .. tostring(problem)
					end
					remaining -= 1
				end
			end)
		end
		while remaining > 0 do
			task.wait()
		end
		if #failures > 0 then
			error("[Dex Explorer] " .. label .. " failed:\n" .. table.concat(failures, "\n"), 0)
		end
	end
	if useBundle then
		local packets, requested = {}, {}
		for _, entry in ipairs(manifest.bundles or { manifest.bundle }) do
			local needed = not entry.paths
			for _, path in ipairs(entry.paths or {}) do
				if not sources[path] then
					needed = true
					break
				end
			end
			if needed then
				requested[#requested + 1] = entry
			end
		end
		parallel(requested, function(entry)
			local source = getSource(entry.path)
			stats.NetworkRequests += 1
			stats.BundleRequests += 1
			stats.DownloadedBytes += #source
			assert(valid(source, entry), "Dex Explorer batch download did not match release")
			local packet = http:JSONDecode(source)
			assert(
				packet.release == manifest.release and type(packet.files) == "table",
				"Invalid Dex Explorer release packet"
			)
			packets[entry.path] = packet.files
		end, "Batch download")
		local received = {}
		for _, files in pairs(packets) do
			for path, source in pairs(files) do
				received[path] = source
			end
		end
		for _, path in ipairs(paths) do
			assert(
				valid(received[path], manifest.files[path]),
				"Dex Explorer batch entry did not match release: " .. path
			)
		end
		for _, path in ipairs(paths) do
			cacheSource(path, received[path], manifest.files[path])
		end
	else
		parallel(paths, fetch, "Download")
	end
	stats.SourceReadySeconds = os.clock() - started
	context.EmbeddedModules = {}
	for name, path in pairs(manifest.modules) do
		local modulePath = path
		context.EmbeddedModules[name] = function()
			return execute(modulePath)
		end
	end
	if manifest.react then
		context.ReactVendor = execute(manifest.react)
	end
	context.StudioAssetData = execute(manifest.assets)
	stats.BootstrapSeconds = os.clock() - started
	if type(getgenv) == "function" then
		getgenv().DexPlusRuntimeStats = stats
	end
	local function copyPoint(point)
		if type(point) ~= "table" then
			return nil
		end
		if type(point[1]) ~= "number" or type(point[2]) ~= "number" then
			return nil
		end
		return { point[1], point[2] }
	end
	local function copyRange(range)
		if type(range) ~= "table" then
			return nil
		end
		local first, last = copyPoint(range[1]), copyPoint(range[2])
		if not first or not last then
			return nil
		end
		local result = { first, last }
		if range.Caret then
			result.Caret = copyPoint(range.Caret)
		end
		return result
	end
	local function editorSnapshot(previous)
		local viewer = type(previous) == "table" and previous.Apps and previous.Apps.ScriptViewer
		if type(viewer) ~= "table" or type(rawget(viewer, "Documents")) ~= "table" then
			return nil
		end
		local saved = { Documents = {} }
		for _, doc in ipairs(viewer.Documents) do
			local text = doc.text
			local active = doc == viewer.ActiveDocument
			local frame = active and viewer.CodeFrame
			if frame and type(frame.GetText) == "function" then
				text = frame:GetText()
			end
			if type(text) == "string" then
				local id = doc.id
				if type(id) ~= "string" and type(id) ~= "number" and typeof(id) ~= "Instance" then
					id = {}
				end
				local selection = copyRange(frame and frame.SelectionRange or doc.selection)
				local overwrite = doc.overwrite
				if frame then
					overwrite = frame.OverwriteMode
				end
				local additional = {}
				for _, range in ipairs(frame and frame.AdditionalSelections or doc.additional or {}) do
					local copied = copyRange(range)
					if copied then
						additional[#additional + 1] = copied
					end
				end
				saved.Documents[#saved.Documents + 1] = {
					Id = id,
					Title = type(doc.title) == "string" and doc.title or "Recovered script",
					Text = text,
					Script = typeof(doc.script) == "Instance" and doc.script or nil,
					Dirty = doc.dirty == true,
					X = frame and frame.CursorX or doc.x,
					Y = frame and frame.CursorY or doc.y,
					Selection = selection,
					Additional = additional,
					Overwrite = overwrite,
					ViewX = frame and frame.ViewX or doc.vx,
					ViewY = frame and frame.ViewY or doc.vy,
				}
				if active then
					saved.Active = #saved.Documents
				end
			end
		end
		if viewer.Window and type(viewer.Window.IsVisible) == "function" then
			saved.Visible = viewer.Window:IsVisible()
		end
		return saved
	end
	local function restoreEditor(saved, current)
		if not saved or #saved.Documents == 0 then
			return
		end
		local viewer = current and current.Apps and current.Apps.ScriptViewer
		assert(
			type(viewer) == "table" and type(viewer.OpenDocument) == "function",
			"New editor cannot restore open documents"
		)
		local frame = assert(viewer.CodeFrame, "New editor has no code frame")
		local initial = viewer.Documents and #viewer.Documents == 1 and viewer.Documents[1]
		if initial and (initial.text ~= "" or initial.script or initial.dirty) then
			initial = nil
		end
		local restored = {}
		for _, item in ipairs(saved.Documents) do
			local doc = viewer.OpenDocument(item.Id, item.Title, item.Text, item.Script)
			restored[#restored + 1] = doc
			doc.dirty = item.Dirty
			doc.overwrite = item.Overwrite == true
			if item.Selection then
				frame.SelectionRange = copyRange(item.Selection)
			end
			frame.AdditionalSelections = {}
			for index, range in ipairs(item.Additional) do
				frame.AdditionalSelections[index] = copyRange(range)
			end
			frame.OverwriteMode = item.Overwrite == true
			frame:MoveCursor(item.X or 0, item.Y or 0)
			frame:SetCopyableSelection()
			frame:Refresh()
			if frame.ScrollH then
				frame.ScrollH:ScrollTo(item.ViewX or 0)
			end
			if frame.ScrollV then
				frame.ScrollV:ScrollTo(item.ViewY or 0)
			end
		end
		if initial and viewer.CloseDocument then
			viewer.CloseDocument(initial)
		end
		if restored[saved.Active or 1] then
			viewer.SelectDocument(restored[saved.Active or 1])
		end
		if viewer.TabStrip then
			viewer.TabStrip:Update(viewer.Documents, viewer.ActiveDocument)
		end
		if saved.Visible == false and viewer.Window and viewer.Window.Hide then
			viewer.Window:Hide()
		end
		stats.RestoredEditorDocuments = #restored
		stats.EditorHistoryRestored = false
	end
	local ok, result = pcall(function()
		local value = execute(manifest.entry)
		if global and staged then
			local previous = global.DexPlus
			local saved = editorSnapshot(previous)
			restoreEditor(saved, staged)
			global.DexPlus = staged
			local priorMain = type(previous) == "table" and previous.Main
			if
				priorMain
				and priorMain ~= staged.Main
				and priorMain.Alive ~= false
				and not priorMain.DexPlusReplacementShutdown
				and type(priorMain.Shutdown) == "function"
			then
				priorMain.DexPlusReplacementShutdown = true
				local stopped, problem = pcall(priorMain.Shutdown)
				stats.PreviousRuntimeShutdown = stopped
				if not stopped then
					stats.PreviousRuntimeShutdownError = tostring(problem)
				end
			end
		end
		return value
	end)
	if not ok then
		local failedMain = staged and staged.Main or newMain
		if failedMain and type(failedMain.Shutdown) == "function" then
			pcall(failedMain.Shutdown)
		end
		error(result, 0)
	end
	stats.TotalSeconds = os.clock() - started
	return result
end

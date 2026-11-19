--!strict

local Apps, Main, env, world

------------------------------ Initialization ------------------------------

local function InitDeps(d)
	Apps, Main, env, world = d.Apps, d.Main, d.env, d.Game or game
end
------------------------------ Module ------------------------------

local function CreateModule()
	local Evidence = {}
	local MAX_STRING = 4096
	local MAX_DEPTH, MAX_ENTRIES = 6, 64

	-- Bounded structural descriptor of a live payload; feeds schema merging
	-- and string mining without ever materializing unbounded tables.
	local function describe(value, depth, seen)
		depth += 1
		if depth > MAX_DEPTH then
			return { t = "cut" }
		end
		local kind = typeof(value)
		if kind == "Instance" then
			local ok, path = pcall(function()
				return value:GetFullName()
			end)
			return { t = "Instance", path = ok and path or value.Name }
		elseif kind == "table" then
			if seen[value] then
				return { t = "cycle" }
			end
			seen[value] = true
			local out = { t = "table", n = {} }
			local count = 0
			for key, item in pairs(value) do
				count += 1
				if count > MAX_ENTRIES then
					out.truncated = true
					break
				end
				local label = type(key) == "string" and key or tostring(key)
				out.n[label] = describe(item, depth, seen)
			end
			seen[value] = nil
			return out
		elseif kind == "string" then
			return { t = "string", len = #value, s = #value <= MAX_STRING and value or nil }
		elseif kind == "number" then
			return {
				t = "number",
				v = value == value and value ~= math.huge and value ~= -math.huge and value or nil,
			}
		end
		return { t = kind }
	end

	local function mergeSchema(record, shape)
		record.Observations += 1
		record.Changed = true
		if type(shape) == "table" and shape.t == "table" and type(shape.n) == "table" then
			for key, item in pairs(shape.n) do
				local slot = record.Keys[key]
				if not slot then
					slot = { Types = {}, Count = 0 }
					record.Keys[key] = slot
				end
				local kind = type(item) == "table" and item.t or "unknown"
				slot.Types[kind] = true
				slot.Count += 1
			end
		end
	end

	function Evidence.Create(onEmit)
		local self = {
			Running = false,
			Remotes = {}, -- instance -> {Object, Class, Keys, Observations, LastPayload}
			Usages = {}, -- remote full name -> { [caller script path]: {Method, Count} }
		}
		local connections = {}
		local namecallOriginal = nil
		local stats = { Namecalls = 0, Payloads = 0, RemotesWatched = 0, HookErrors = 0 }
		local getcallingscript = type(env.getcallingscript) == "function" and env.getcallingscript or nil

		-- Strings inside live traffic are server-authored text; the shared log
		-- extractor turns them into path claims with zero extra pattern code.
		local function mine(label, value)
			if type(value) == "string" then
				if #value >= 6 and #value <= 65536 and Apps.ServerReferenceAnalysis then
					Apps.ServerReferenceAnalysis.Log(value, label, onEmit)
				end
			elseif type(value) == "table" then
				local budget = 64
				for _, item in pairs(value) do
					budget -= 1
					if budget <= 0 then
						break
					end
					mine(label, item)
				end
			end
		end

		local function watchRemote(object)
			local ok, class = pcall(function()
				return object.ClassName
			end)
			if
				not ok
				or (class ~= "RemoteEvent" and class ~= "UnreliableRemoteEvent" and class ~= "RemoteFunction")
			then
				return
			end
			local record = self.Remotes[object]
			if not record then
				record = { Object = object, Class = class, Keys = {}, Observations = 0 }
				self.Remotes[object] = record
				stats.RemotesWatched += 1
			end
			if connections[object] then
				return
			end
			local label = "remote payload"
			local okConn, connection
			if class == "RemoteFunction" then
				okConn, connection = pcall(function()
					return object.OnClientInvoke:Connect(function(...)
						stats.Payloads += 1
						local packed = table.pack(...)
						for index = 1, packed.n do
							mine(label, packed[index])
						end
						local shape = describe(packed, 0, {})
						mergeSchema(record, shape)
						record.LastPayload = shape
					end)
				end)
			else
				okConn, connection = pcall(function()
					return object.OnClientEvent:Connect(function(...)
						stats.Payloads += 1
						local packed = table.pack(...)
						for index = 1, packed.n do
							mine(label, packed[index])
						end
						local shape = describe(packed, 0, {})
						mergeSchema(record, shape)
						record.LastPayload = shape
					end)
				end)
			end
			if okConn and connection then
				connections[object] = connection
			end
		end

		function self:Start()
			if self.Running then
				return
			end
			self.Running = true
			for _, object in ipairs(world:GetDescendants()) do
				watchRemote(object)
			end
			Main.TrackSignal(world.DescendantAdded, function(object)
				if self.Running then
					watchRemote(object)
				end
			end)
			-- Passive __namecall mirror: arguments and results pass through
			-- untouched; engine-native cost is one table lookup per call.
			-- Integrity scanners that inspect metamethod identity can observe
			-- the hook, which is inherent to every namecall spy.
			local hookmetamethod, newcclosure = env.hookmetamethod, env.newcclosure
			if type(hookmetamethod) == "function" and type(newcclosure) == "function" then
				local ok, original = pcall(hookmetamethod, world, "__namecall", newcclosure(function(instance, method, ...)
					if self.Running and typeof(instance) == "Instance" then
						stats.Namecalls += 1
						local okClass, class = pcall(function()
							return instance.ClassName
						end)
						if
							okClass
							and (class == "RemoteEvent" or class == "RemoteFunction" or class == "UnreliableRemoteEvent")
						then
							local okName, name = pcall(function()
								return instance:GetFullName()
							end)
							if okName then
								local usage = self.Usages[name]
								if not usage then
									usage = {}
									self.Usages[name] = usage
								end
								local caller = "?"
								if getcallingscript then
									local okCaller, scriptObject = pcall(getcallingscript)
									if okCaller and typeof(scriptObject) == "Instance" then
										local okPath, path = pcall(function()
											return scriptObject:GetFullName()
										end)
										caller = okPath and path or scriptObject.Name
									end
								end
								local slot = usage[caller]
								if not slot then
									slot = { Method = tostring(method), Count = 0 }
									usage[caller] = slot
								end
								slot.Count += 1
								if method == "FireServer" or method == "InvokeServer" then
									local packed = table.pack(...)
									for index = 1, math.min(packed.n, 8) do
										mine("outgoing remote argument", packed[index])
									end
								end
							end
						end
					end
					return namecallOriginal(instance, method, ...)
				end))
				if ok and original then
					namecallOriginal = original
				else
					stats.HookErrors += 1
				end
			end
		end

		function self:Stop()
			if not self.Running then
				return
			end
			self.Running = false
			for _, connection in pairs(connections) do
				pcall(function()
					connection:Disconnect()
				end)
			end
			table.clear(connections)
			-- Restore the engine metamethod by re-hooking the captured
			-- original; executor variance makes this best-effort.
			if namecallOriginal and type(env.hookmetamethod) == "function" then
				pcall(hookmetamethod, world, "__namecall", namecallOriginal)
				namecallOriginal = nil
			end
		end

		function self:Schemas()
			local out = {}
			for object, record in pairs(self.Remotes) do
				local ok, name = pcall(function()
					return object:GetFullName()
				end)
				out[ok and name or tostring(object)] = {
					Class = record.Class,
					Observations = record.Observations,
					Keys = record.Keys,
				}
			end
			return out
		end

		function self:Usage()
			local out = {}
			for name, callers in pairs(self.Usages) do
				local rows = {}
				for caller, slot in pairs(callers) do
					rows[#rows + 1] = { Caller = caller, Method = slot.Method, Count = slot.Count }
				end
				table.sort(rows, function(a, b)
					return a.Caller < b.Caller
				end)
				out[name] = rows
			end
			return out
		end

		function self:Stats()
			return stats
		end

		function self:Destroy()
			self:Stop()
			table.clear(self.Remotes)
			table.clear(self.Usages)
		end

		if Main.AddCleanup then
			Main.AddCleanup(function()
				self:Destroy()
			end)
		end
		return self
	end

	return Evidence
end
return { InitDeps = InitDeps, InitAfterMain = function() end, Main = CreateModule }

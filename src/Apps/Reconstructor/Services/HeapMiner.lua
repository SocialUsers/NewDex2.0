--!strict

local Apps, env, world, clock, wait

------------------------------ Initialization ------------------------------

local function InitDeps(d)
	Apps, world = d.Apps, d.Game or game
	env = d.env
	clock, wait = d.Clock or os.clock, d.Wait or task.wait
end
------------------------------ Module ------------------------------

local function CreateModule()
	local Miner = {}
	local TABLE_BUDGET = 512
	local NESTED_BUDGET = 256
	local MAX_VISITED = 250000
	local MAX_ITERATIONS = 1500000
	local MAX_DUMPS = 512
	local SLICE = 0.002

	-- Two passes over the live GC heap. Pass 1 mines every reachable table's
	-- strings through the shared log extractor. Pass 2 generalizes retained
	-- function evidence: any closure owned by a replicated script is dumped
	-- and analyzed with its real upvalues as path seeds. Nothing is executed.
	function Miner.Sweep(emit, checkpoint, analyze)
		local stats = {
			Mode = "Heap sweep",
			Tables = 0,
			Functions = 0,
			Strings = 0,
			SeededDumps = 0,
			Owned = 0,
			Skipped = 0,
		}
		local getgc = env.getgc
		if type(getgc) ~= "function" or type(Apps.ServerReferenceAnalysis) ~= "table" then
			stats.Mode = "Unavailable"
			return stats
		end
		local ok, objects = pcall(getgc, true)
		if not ok or type(objects) ~= "table" then
			stats.Mode = "Unavailable"
			return stats
		end
		local label = "gc heap string"
		local visited = {}
		local visitedCount = 0
		local deadline = clock() + SLICE
		local function alive()
			if clock() >= deadline then
				wait()
				deadline = clock() + SLICE
			end
			return checkpoint == nil or checkpoint() ~= false
		end
		local limit = math.min(#objects, MAX_ITERATIONS)
		for index = 1, limit do
			if index % 2048 == 0 and not alive() then
				stats.Cancelled = true
				return stats
			end
			local value = objects[index]
			if type(value) == "table" and not visited[value] and visitedCount < MAX_VISITED then
				visited[value] = true
				visitedCount += 1
				stats.Tables += 1
				local budget = TABLE_BUDGET
				for _, item in pairs(value) do
					budget -= 1
					if budget <= 0 then
						stats.Skipped += 1
						break
					end
					if type(item) == "string" then
						if #item >= 6 and #item <= 65536 then
							stats.Strings += 1
							Apps.ServerReferenceAnalysis.Log(item, label, emit)
						end
					elseif type(item) == "table" and not visited[item] and visitedCount < MAX_VISITED then
						visited[item] = true
						visitedCount += 1
						local nested = NESTED_BUDGET
						for _, deep in pairs(item) do
							nested -= 1
							if nested <= 0 then
								break
							end
							if type(deep) == "string" and #deep >= 6 and #deep <= 65536 then
								stats.Strings += 1
								Apps.ServerReferenceAnalysis.Log(deep, label, emit)
							end
						end
					end
				end
			end
		end
		local dumpBytecode = type(env.dumpbytecode) == "function" and env.dumpbytecode or nil
		if not dumpBytecode then
			return stats
		end
		local upvaluesFn = (type(debug) == "table" and type(debug.getupvalues) == "function" and debug.getupvalues)
			or (type(env.getupvalues) == "function" and env.getupvalues)
			or nil
		local serviceStorage = pcall(function()
			return world:GetService("ServerStorage")
		end) and world:GetService("ServerStorage") or nil
		local scriptService = pcall(function()
			return world:GetService("ServerScriptService")
		end) and world:GetService("ServerScriptService") or nil
		local roots = {
			[serviceStorage] = { "ServerStorage" },
			[scriptService] = { "ServerScriptService" },
		}
		local seenFn = setmetatable({}, { __mode = "k" })
		for index = 1, limit do
			if index % 2048 == 0 and not alive() then
				stats.Cancelled = true
				return stats
			end
			local value = objects[index]
			if type(value) == "function" and not seenFn[value] then
				seenFn[value] = true
				stats.Functions += 1
				-- Ownership is resolved from the closure's environment; server
				-- scripts replicated into the client keep their env.script.
				local good, environment = pcall(getfenv, value)
				local owner = good and type(environment) == "table" and rawget(environment, "script")
				if not owner and good and type(environment) == "table" then
					local mt = getmetatable(environment)
					local inherited = type(mt) == "table" and rawget(mt, "__index")
					if type(inherited) == "table" then
						owner = rawget(inherited, "script")
					end
				end
				if typeof(owner) == "Instance" then
					stats.Owned += 1
					local seeds = {}
					if upvaluesFn then
						local goodUp, upvalues = pcall(upvaluesFn, value)
						if goodUp and type(upvalues) == "table" then
							for slot, upvalue in pairs(upvalues) do
								if type(slot) == "number" and slot >= 1 and slot <= 200 then
									if type(upvalue) == "string" and #upvalue <= 512 then
										seeds[slot] = upvalue
										if #upvalue >= 6 and #upvalue <= 65536 then
											Apps.ServerReferenceAnalysis.Log(upvalue, "heap upvalue", emit)
										end
									elseif roots[upvalue] then
										seeds[slot] = { Path = roots[upvalue] }
									elseif upvalue == world then
										seeds[slot] = { Global = "game" }
									end
								end
							end
						end
					end
					if stats.SeededDumps < MAX_DUMPS and type(analyze) == "function" then
						stats.SeededDumps += 1
						local goodBytes, bytes = pcall(dumpBytecode, value)
						if goodBytes and type(bytes) == "string" and #bytes <= 1024 * 1024 then
							local goodPath, path = pcall(function()
								return owner:GetFullName()
							end)
							local parsed, result = analyze(
								bytes,
								(goodPath and path or owner.Name) .. " (heap closure)",
								emit,
								checkpoint,
								seeds
							)
							if parsed then
								stats.Claims = (stats.Claims or 0) + result.Claims
							else
								stats.Rejected = (stats.Rejected or 0) + 1
							end
						end
					end
				end
			end
		end
		return stats
	end

	return Miner
end
return { InitDeps = InitDeps, InitAfterMain = function() end, Main = CreateModule }

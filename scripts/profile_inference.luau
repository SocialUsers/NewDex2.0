--!strict

local global = getgenv and getgenv() or _G
local dex = assert(global.DexPlus, "Load Dex Explorer first")
local deps = dex.Main.GetInitDeps()
local env = deps.env
local run = game:GetService("RunService")
local http = game:GetService("HttpService")
local report = { Version = 1, Started = os.time(), Steps = {}, Errors = {} }
local phase = "baseline"
local metrics = {}
local connection = run.Heartbeat:Connect(function(dt)
	local current = metrics[phase]
	if not current then
		current = { Frames = 0, MaxFrameSeconds = 0, Over50ms = 0 }
		metrics[phase] = current
	end
	current.Frames += 1
	current.MaxFrameSeconds = math.max(current.MaxFrameSeconds, dt)
	if dt > 0.05 then
		current.Over50ms += 1
	end
end)
local function save()
	pcall(makefolder, "dex")
	pcall(makefolder, "dex/validation")
	writefile("dex/validation/inference-profile.json", http:JSONEncode(report))
end
local ok, problem = xpcall(function()
	if dex.Apps.Reconstructor.Session then
		dex.Apps.Reconstructor.Session:Cancel()
	end
	task.wait(1)
	report.Baseline = metrics.baseline
	assert(type(env.getscriptbytecode) == "function", "Executor has no bytecode API")
	local candidates, seen = {}, {}
	local function add(obj)
		if #candidates >= 3 or seen[obj] then
			return
		end
		local success, viable = pcall(env.isViableDecompileScript, obj)
		if success and viable then
			seen[obj] = true
			candidates[#candidates + 1] = obj
		end
	end
	for _, node in ipairs(dex.Apps.Explorer.Selection.List) do
		if not node.Inferred then
			add(node.Obj)
		end
	end
	local nodes = dex.Apps.Explorer.GetInferenceNodes()
	local deadline = os.clock() + 0.001
	for obj, node in pairs(nodes) do
		if #candidates >= 3 then
			break
		end
		if os.clock() > deadline then
			task.wait()
			deadline = os.clock() + 0.001
		end
		local class = node.Class or obj.ClassName
		if not node.Inferred and (class == "ModuleScript" or class == "LocalScript" or class == "Script") then
			local ancestor, depth = node, 0
			while ancestor.Parent and ancestor.Parent ~= nodes[game] and depth < 64 do
				ancestor = ancestor.Parent
				depth += 1
			end
			if
				ancestor.Parent == nodes[game]
				and ancestor.Obj.Name ~= "CorePackages"
				and ancestor.Obj.Name ~= "CoreGui"
				and ancestor.Obj.Name ~= "RobloxReplicatedStorage"
			then
				add(obj)
			end
		end
	end
	local smallest, smallestBytecode
	local function measure(name, callback)
		phase = name
		report.Stage = name
		save()
		local started = os.clock()
		local success, value = pcall(callback)
		local seconds = os.clock() - started
		run.Heartbeat:Wait()
		run.Heartbeat:Wait()
		local step = { Name = name, Seconds = seconds, Success = success, Heartbeat = metrics[name] }
		report.Steps[#report.Steps + 1] = step
		save()
		return success, value, step
	end
	for index, obj in ipairs(candidates) do
		local success, bytes, step = measure("bytecode-" .. index, function()
			return env.getscriptbytecode(obj)
		end)
		if success and type(bytes) == "string" then
			step.Bytes = #bytes
			step.BytecodeVersion = bytes:byte(1)
			step.TypeVersion = bytes:byte(2)
			if not smallestBytecode or #bytes < #smallestBytecode then
				smallest, smallestBytecode = obj, bytes
			end
		end
		if step.Heartbeat and step.Heartbeat.MaxFrameSeconds > 0.1 then
			report.Stopped = "Bytecode retrieval exceeded a 100 ms frame; no further executor APIs called."
			return
		end
		task.wait(0.2)
	end
	if smallestBytecode and #smallestBytecode <= 16384 and type(env.decompile) == "function" then
		local success, source, step = measure("small-decompile", function()
			return env.decompile(smallest)
		end)
		if success and type(source) == "string" then
			step.SourceBytes = #source
			step.HasServerServiceText = source:find("ServerStorage", 1, true) ~= nil
				or source:find("ServerScriptService", 1, true) ~= nil
		end
	else
		report.DecompileSkipped = "No candidate below the 16 KiB bytecode limit"
	end
end, debug.traceback)
connection:Disconnect()
if not ok then
	report.Errors[#report.Errors + 1] = tostring(problem):sub(1, 500)
end
report.Finished = true
report.Stage = "finished"
save()
print("[Dex Explorer] Isolated inference profile saved. No game remotes were invoked.")

--!strict

local global = getgenv and getgenv() or _G
local dex = assert(global.DexPlus, "Load Dex Explorer first")
local paths = assert(
	loadstring(
		readfile("dex-explorer/development/src/Apps/Reconstructor/Services/BytecodePaths.lua"),
		"@DexExplorer/RuntimeEvidenceProfile"
	)
)().Main()
local http = game:GetService("HttpService")
local report = { Started = os.time(), Steps = {}, Functions = {}, Errors = {} }
local function save()
	writefile("dex-explorer/validation/runtime-evidence-profile.json", http:JSONEncode(report))
end
local function measure(name, fn)
	report.Stage = name
	save()
	local start = os.clock()
	local ok, result = pcall(fn)
	local seconds = os.clock() - start
	report.Steps[#report.Steps + 1] = { Name = name, Seconds = seconds, Success = ok }
	if not ok then
		report.Errors[#report.Errors + 1] = tostring(result):sub(1, 350)
	end
	save()
	task.wait()
	return ok, result, seconds
end
local ok, problem = xpcall(function()
	assert(
		type(filtergc) == "function" and type(dumpbytecode) == "function",
		"Potassium runtime inspection APIs unavailable"
	)
	local candidates = dex.Apps.Explorer.GetInferenceCandidates()
	local seen, functions = {}, {}
	for _, root in ipairs({ "ServerStorage", "ServerScriptService" }) do
		local success, result, seconds = measure("filter:" .. root, function()
			return filtergc("function", { IgnoreExecutor = true, Constants = { root } }, false)
		end)
		if seconds > 0.02 then
			report.Stop = "Filtered GC inspection exceeded 20 ms; no additional native calls"
			return
		end
		if success and type(result) == "table" then
			report.Matches = (report.Matches or 0) + #result
			for index, fn in ipairs(result) do
				if index > 2000 then
					break
				end
				if index % 16 == 0 then
					task.wait()
				end
				if type(fn) == "function" and not seen[fn] then
					local good, environment = pcall(getfenv, fn)
					local scriptObject = good and type(environment) == "table" and environment.script
					local node = scriptObject and candidates[scriptObject]
					if node and not node.Inferred then
						seen[fn] = true
						functions[#functions + 1] = fn
					end
				end
			end
		end
	end
	report.OwnedFunctions = #functions
	for index = 1, math.min(3, #functions) do
		local fn = functions[index]
		local success, bytes, seconds = measure("dump:" .. index, function()
			return dumpbytecode(fn)
		end)
		if seconds > 0.02 then
			report.Stop = "Function serialization exceeded 20 ms"
			return
		end
		if success and type(bytes) == "string" and #bytes <= 65536 then
			local record = { Bytes = #bytes, Version = bytes:byte(1), Types = bytes:byte(2) }
			report.Functions[#report.Functions + 1] = record
			local seeds = {}
			if type(debug.getupvalues) == "function" then
				local good, values, cost = measure("upvalues:" .. index, function()
					return debug.getupvalues(fn)
				end)
				if cost > 0.02 then
					report.Stop = "Upvalue inspection exceeded 20 ms"
					return
				end
				if good and type(values) == "table" then
					for slot, value in pairs(values) do
						if type(slot) == "number" and slot >= 1 and slot <= 200 then
							if type(value) == "string" and #value <= 512 then
								seeds[slot] = value
							elseif value == game:GetService("ServerStorage") then
								seeds[slot] = { Path = { "ServerStorage" } }
							elseif value == game:GetService("ServerScriptService") then
								seeds[slot] = { Path = { "ServerScriptService" } }
							end
						end
					end
				end
			end
			local seeded = 0
			for _ in pairs(seeds) do
				seeded += 1
			end
			record.Seeds = seeded
			local deadline = os.clock() + 0.001
			local parsed, info = paths.Analyze(bytes, "retained function profile", function() end, function()
				if os.clock() > deadline then
					task.wait()
					deadline = os.clock() + 0.001
				end
				return true
			end, seeds)
			record.Parsed = parsed
			record.Analysis = info
			save()
		end
	end
end, debug.traceback)
if not ok then
	report.Errors[#report.Errors + 1] = tostring(problem):sub(1, 600)
end
report.Finished = true
report.Stage = "Finished"
save()
print("[Dex Explorer] Runtime evidence API profile saved. No game functions, decompilers or remotes were invoked.")

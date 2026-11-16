--!strict

local global = getgenv and getgenv() or _G
local dex = assert(global.DexPlus, "Load Dex Explorer first")
local deps = dex.Main.GetInitDeps()
local env = deps.env
local paths = assert(
	loadstring(
		readfile("dex-explorer/development/src/Apps/Reconstructor/Services/BytecodePaths.lua"),
		"@DexExplorer/BytecodeFormat"
	)
)().Main()
local report = {
	Started = os.time(),
	Samples = {},
	Capabilities = { DumpBytecode = type(dumpbytecode), GetScriptClosure = type(getscriptclosure) },
}
local http = game:GetService("HttpService")
pcall(makefolder, "dex-explorer/validation/bytecode")
local function save()
	writefile("dex-explorer/validation/bytecode-format.json", http:JSONEncode(report))
end
save()
local candidates = dex.Apps.Explorer.GetInferenceCandidates()
local limit, visited = 0, 0
for obj, node in pairs(candidates) do
	if not node.Inferred and obj.ClassName ~= "StringValue" then
		visited += 1
		if visited % 8 == 0 then
			task.wait()
		end
		if visited > 20000 then
			break
		end
		local started = os.clock()
		local ok, bytes = pcall(env.getscriptbytecode, obj)
		local seconds = os.clock() - started
		if seconds > 0.02 then
			report.Stop = "Bytecode call exceeded 20 ms"
			save()
			break
		end
		if ok and type(bytes) == "string" and #bytes <= 65536 and dex.Apps.BytecodeStrings.HasServerHint(bytes) then
			limit += 1
			local sample = { Bytes = #bytes, ReadSeconds = seconds, Version = bytes:byte(1), Types = bytes:byte(2) }
			report.Samples[#report.Samples + 1] = sample
			local file = "dex-explorer/validation/bytecode/sample-" .. limit .. ".bin"
			writefile(file, bytes)
			sample.File = file
			local claims = 0
			local deadline = os.clock() + 0.001
			local function checkpoint()
				if os.clock() > deadline then
					task.wait()
					deadline = os.clock() + 0.001
				end
				return true
			end
			local parsed, info = paths.Analyze(bytes, "format sample", function()
				claims += 1
			end, checkpoint)
			sample.Parsed = parsed
			sample.Analysis = info
			sample.Claims = claims
			save()
			if limit >= 3 then
				break
			end
		end
	end
end
report.Finished = true
save()
print(
	"[Dex Explorer] Bytecode format check saved "
		.. #report.Samples
		.. " local samples. No decompiles or remotes invoked."
)

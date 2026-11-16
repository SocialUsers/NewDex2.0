--!strict

local originalTypeof = typeof
typeof = function(value)
	return getmetatable(value) == instMT and "Instance" or originalTypeof(value)
end
API.Classes.Instance = { Name = "Instance", Properties = {} }
API.Classes.Part = {
	Name = "Part",
	Superclass = "Instance",
	Properties = { { Name = "Link", ValueType = { Category = "Class", Name = "Instance" } } },
}
local target = Instance.new("Part", workspace)
target.Name = "Door"
local objects = {}
for index = 1, 12000 do
	local object = Instance.new("Part")
	object.Name = "Part" .. index
	object.Link = index % 300 == 0 and target or nil
	objects[object] = true
end
for index = 1, 512 do
	local object = Instance.new("LocalScript", workspace)
	object.Name = "Script" .. index
	objects[object] = true
end
Apps.Explorer.GetNodes = function()
	return objects
end
service.RunService.Heartbeat = signal()
Apps.ScriptViewer = { Documents = {} }
local native, sourceReads = 0, 0
referenceEnv.getscriptbytecode = function()
	native += 1
	return referenceBytecode
end
local originalIndex = instMT.__index
instMT.__index = function(object, key)
	if key == "Source" then
		sourceReads += 1
		error("Source protected")
	end
	return originalIndex(object, key)
end
local function run(name)
	local before, reads = native, sourceReads
	local started = os.clock()
	Apps.ReferenceFinder.Open(target)
	local frames = 0
	repeat
		service.RunService.Heartbeat:Fire(1 / 60)
		frames += 1
	until not Apps.ReferenceFinder.Status.Text:find("^Searching") or frames > 5000
	local result = Apps.ReferenceFinder.Results
	assert(
		frames <= 5000 and not result.Stats.Cancelled and #result.Scripts == 512 and #result.Direct == 40,
		"load benchmark retains complete candidate/property coverage"
	)
	if name == "warm" then
		assert(
			native == before and sourceReads == reads,
			"warm searches reuse decoded strings without native or protected-source retries"
		)
	end
	print(
		string.format(
			"BENCH %s: frames=%d cpu_ms=%.2f native=%d source_reads=%d scripts=%d properties=%d",
			name,
			frames,
			(os.clock() - started) * 1000,
			native - before,
			sourceReads - reads,
			#result.Scripts,
			#result.Direct
		)
	)
end
run("cold")
run("warm")
instMT.__index = originalIndex

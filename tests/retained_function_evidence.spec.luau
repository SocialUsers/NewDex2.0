--!strict

local M = require("../src/Apps/Reconstructor/Services/RetainedFunctionEvidence")
local now, gameCalls, queries, dumps, waits = 0, 0, 0, 0, 0
local world = {}
local services = { ServerStorage = {}, ServerScriptService = {} }
function world:GetService(name)
	return services[name]
end
local owner = {
	Name = "Owner",
	GetFullName = function()
		return "ReplicatedStorage.Owner"
	end,
}
local engine = { Name = "Engine" }
local first = function()
	gameCalls += 1
	error("must never run")
end
local second = function()
	gameCalls += 1
	error("must never run")
end
local other = function()
	gameCalls += 1
	error("must never run")
end
local owned = { [owner] = { Obj = owner } }
local claims = {}
local apps = {
	Explorer = {
		GetInferenceCandidates = function()
			return owned
		end,
	},
	BytecodePaths = {
		Analyze = function(bytes, label, emit, checkpoint, seeds)
			assert(bytes == "first" or bytes == "second")
			assert(label == "ReplicatedStorage.Owner (retained function)")
			assert(seeds[1].Path[1] == "ServerStorage" and seeds[2] == "Child" and seeds[3].Global == "game")
			emit({ "ServerStorage", "Child" }, { Class = "ModuleScript", Source = label })
			return true, { Claims = 1 }
		end,
	},
}
local slow = false
local api = {
	Filter = function(kind, options, single)
		queries += 1
		now += slow or 0.015
		assert(kind == "function" and options.IgnoreExecutor and not single)
		return options.Constants[1] == "ServerStorage" and { first, other } or { first, second }
	end,
	Environment = function(fn)
		return { script = fn == other and engine or owner }
	end,
	Dump = function(fn)
		dumps += 1
		return fn == first and "first" or "second"
	end,
	Upvalues = function()
		return { services.ServerStorage, "Child", world, {}, function() end }
	end,
}
M.InitDeps({
	Apps = apps,
	Game = world,
	Functions = api,
	Clock = function()
		return now
	end,
	Wait = function()
		waits += 1
	end,
})
local result = M.Main().Collect(function(path, evidence)
	claims[#claims + 1] = { path, evidence }
end, function()
	return true
end)
assert(
	result.Complete
		and result.Queries == 2
		and result.Owned == 2
		and result.Dumped == 2
		and result.Parsed == 2
		and result.Claims == 2
)
assert(
	gameCalls == 0 and dumps == 2 and waits == 2 and #claims == 2,
	"deduplicated, owned functions are serialized but never executed"
)
slow = 0.03
queries = 0
dumps = 0
local recovered = M.Main().Collect(function() end)
assert(
	recovered.Complete and recovered.DiscoveryOverruns == 2 and queries == 2 and dumps == 2,
	"mild discovery overruns retain results and yield before further native work"
)
slow = 0.11
queries = 0
dumps = 0
local paused = M.Main().Collect(function()
	error("unexpected claim")
end)
assert(paused.Paused and queries == 1 and dumps == 0, "slow native discovery stops further calls")
queries = 0
local cancelled = M.Main().Collect(function() end, function()
	return false
end)
assert(cancelled.Cancelled and queries == 0)
M.InitDeps({ Apps = apps, Game = world, Functions = {}, Wait = function() end })
assert(M.Main().Collect(function() end).Mode == "Unavailable")
print(
	"PASS: retained-function ownership, deduplication, seeded paths, no execution, native circuit stop and cancellation"
)

--!strict

local Analysis = require("../src/Apps/Reconstructor/Services/ServerReferenceAnalysis").Main()
local Evidence = require("../src/Apps/Reconstructor/Services/ReconstructorEvidence").Main()
local Module = require("../src/Apps/Reconstructor/Services/ReconstructorSession")
local queue, timers, cleanup = {}, {}, {}
local calls = 0
local remote = {}
function remote:IsA(class)
	return class == "RemoteFunction"
end
function remote:IsDescendantOf()
	return true
end
function remote:GetFullName()
	return "ReplicatedStorage.Test"
end
function remote:InvokeServer(...)
	calls += 1
	assert(select("#", ...) == 2 and select(1, ...) == "inspect" and select(2, ...) == false)
	error("ServerScriptService.Controllers.Test:14: test error")
end
local messages = {}
-- Required modules have their own environment. Inject a scheduler through deps.
local scheduler = {
	spawn = function(fn)
		queue[#queue + 1] = fn
		return fn
	end,
	delay = function(_, fn)
		timers[#timers + 1] = fn
	end,
}
local scriptObject = { Name = "Readable", Source = "require(game.ServerStorage.Readable.Module)" }
function scriptObject:IsA(class)
	return class == "LuaSourceContainer"
end
function scriptObject:GetFullName()
	return "ReplicatedStorage.Readable"
end
local irrelevant = { Name = "Irrelevant", Source = "", IsA = scriptObject.IsA, GetFullName = scriptObject.GetFullName }
local world = {
	GetDescendants = function()
		return { scriptObject, scriptObject, irrelevant }
	end,
}
local http = {
	JSONDecode = function(_, text)
		if text == "[null,false,null]" then
			return { [2] = false }
		end
		if text == '["a,b",[1,2],{"x":"z"}]' then
			return { "a,b", { 1, 2 }, { x = "z" } }
		end
		if text == "[]" then
			return {}
		end
		error("bad json")
	end,
}
local bytecodeReads = 0
Module.InitDeps({
	Apps = { ServerReferenceAnalysis = Analysis, ReconstructorEvidence = Evidence },
	Main = {
		AddCleanup = function(fn)
			cleanup[#cleanup + 1] = fn
		end,
	},
	env = {
		getloadedmodules = function()
			return { scriptObject }
		end,
		getscriptbytecode = function()
			bytecodeReads += 1
			return "ordinary client code"
		end,
	},
	service = { HttpService = http },
	Task = scheduler,
	Game = world,
})
local api = Module.Main()
api.Classes = { Folder = true, ModuleScript = true, Script = true }
local nulls, n = api.DecodeArguments("[null,false,null]")
assert(n == 3 and nulls[2] == false)
assert(select(2, api.DecodeArguments('["a,b",[1,2],{"x":"z"}]')) == 3)
assert(select(2, api.DecodeArguments("[]")) == 0)
assert(not api.DecodeArguments("{}"))
local session = api.Create(function(message)
	messages[#messages + 1] = message
end)
session:Import("require(game.ServerStorage.Modules.Example)", "pasted fixture")
assert(session.Tree.Nodes[Evidence.Key({ "ServerStorage", "Modules", "Example" })].Classes.ModuleScript)
assert(session:Probe(remote, { "inspect", false }))
assert(calls == 0 and session.ProbePending, "opening a session never auto invokes remotes")
assert(not session:Probe(remote, { "inspect", false }), "only one call may be in flight")
timers[1]()
assert(session.ProbePending, "timeout cannot release the outstanding server-call slot")
queue[1]()
assert(calls == 1 and not session.ProbePending)
assert(session.Tree.Nodes[Evidence.Key({ "ServerScriptService", "Controllers", "Test" })])
assert(not session:Probe(remote, { named = "bad" }))
assert(not session:Probe(nil, {}))
local many = {}
for i = 1, 17 do
	many[i] = i
end
assert(not session:Probe(remote, many))
assert(session:Scan())
assert(not session:Scan(), "scans do not overlap")
queue[2]()
assert(
	not session.Running
		and session.Stats.Scanned == 1
		and session.Stats.Discovered == 2
		and session.Stats.Unavailable == 1
)
assert(bytecodeReads == 0, "automatic scans must never call a blocking executor bytecode API")
assert(session.Tree.Nodes[Evidence.Key({ "ServerStorage", "Readable", "Module" })])
assert(calls == 1, "scanning never invokes remotes")
assert(session:Scan())
session:Cancel()
queue[3]()
assert(not session.Running, "cancelled scan stays cancelled")
assert(session:Scan())
queue[4]()
assert(session.Stats.Cached == 1 and session.Stats.Scanned == 0, "unchanged accessible source reuses cached analysis")
assert(bytecodeReads == 0)
assert(session:Scan({ Deep = true }))
queue[5]()
assert(bytecodeReads == 1 and session.Stats.Filtered == 1, "bytecode access is restricted to an explicit deep scan")
session:Destroy()
assert(not session:Probe(remote, {}))
print("PASS: manual-only remote calls, argument validation, timeout retention, error evidence and teardown")

-- Exercise the production reader/session contract, rather than only the
-- source-only fallback above. Interrupted analysis must not poison the cache.
local ReaderModule = require("../src/Apps/Reconstructor/Services/ScriptEvidenceReader")
ReaderModule.InitDeps({ env = {}, Apps = {} })
local work, delayed = {}, {}
local taskQueue = {
	spawn = function(fn)
		work[#work + 1] = fn
	end,
	delay = function(_, fn)
		delayed[#delayed + 1] = fn
	end,
}
local first = { Name = "Zeta", Source = 'require(game:GetService("Server" .. "Storage").Zeta)' }
local second = { Name = "Alpha", Source = 'require(game:GetService("Server" .. "Storage").Alpha)' }
for _, obj in ipairs({ first, second }) do
	obj.IsA = scriptObject.IsA
	obj.GetFullName = function(self)
		return "ReplicatedStorage." .. self.Name
	end
end
local visited, interrupt = {}, true
Module.InitDeps({
	Apps = {
		ReconstructorEvidence = Evidence,
		ScriptEvidenceReader = {
			Create = function(options)
				options.Wait = function() end
				return ReaderModule.Main().Create(options)
			end,
		},
		ServerReferenceAnalysis = {
			Log = Analysis.Log,
			Source = function(source, label, emit, checkpoint, tokens)
				visited[#visited + 1] = label
				if interrupt then
					return false
				end
				return Analysis.Source(source, label, emit, checkpoint, tokens)
			end,
		},
	},
	Main = {},
	env = {},
	service = {},
	Task = taskQueue,
	Game = {
		GetDescendants = function()
			return { first, second }
		end,
	},
})
local production = Module.Main()
production.Classes = { ModuleScript = true }
local consistent = production.Create()
assert(consistent:Scan())
assert(not consistent:RequestScan(), "arrivals queue behind an active scan")
work[1]()
assert(
	visited[1] == "ReplicatedStorage.Alpha" and visited[2] == "ReplicatedStorage.Zeta",
	"discovery order never determines bounded scan order"
)
assert(consistent.Stats.Deferred == 2 and consistent.Stats.Scanned == 0 and #delayed == 1)
interrupt = false
delayed[1]()
work[2]()
assert(
	consistent.Stats.Scanned == 2 and consistent.Stats.Cached == 0,
	"unfinished analysis is retried and committed only after success"
)
assert(
	consistent.Tree.Nodes[Evidence.Key({ "ServerStorage", "Alpha" })]
		and consistent.Tree.Nodes[Evidence.Key({ "ServerStorage", "Zeta" })],
	"constant-built services bypass no unsafe raw-text source filter"
)
assert(consistent:Scan())
work[3]()
assert(consistent.Stats.Cached == 2 and consistent.Stats.Scanned == 0)
consistent:Destroy()
print("PASS: deterministic scan ordering, queued arrivals, partial-analysis retry and production cache commit")

local brokenQueue = {}
Module.InitDeps({
	Apps = {
		ReconstructorEvidence = Evidence,
		ServerReferenceAnalysis = Analysis,
		Explorer = {
			GetInferenceNodes = function()
				error("discovery fixture failure")
			end,
		},
	},
	Main = {},
	env = {},
	service = {},
	Task = {
		spawn = function(fn)
			brokenQueue[#brokenQueue + 1] = fn
		end,
	},
	Game = {},
})
local broken = Module.Main().Create()
assert(broken:Scan())
brokenQueue[1]()
assert(
	not broken.Running
		and broken.Stats.Phase == "Failed"
		and broken.Stats.Error:find("discovery fixture failure", 1, true),
	"worker errors terminate and report instead of leaving a silently stuck scan"
)
print("PASS: protected asynchronous scan errors and explicit failed state")

local indexedWorld = {}
local worldNode = { Obj = indexedWorld }
local serviceNode = { Obj = { Name = "ReplicatedStorage" }, Parent = worldNode }
local indexedScript = { Name = "Indexed", ClassName = "ModuleScript", Source = "require(game.ServerStorage.Indexed)" }
indexedScript.GetFullName = function()
	return "ReplicatedStorage.Indexed"
end
local indexedNode = { Obj = indexedScript, Parent = serviceNode }
local largeIndex = { [indexedWorld] = worldNode, [indexedScript] = indexedNode }
for i = 1, 50000 do
	largeIndex[{}] = { Obj = { ClassName = "Part" }, Parent = serviceNode }
end
local indexedWork = {}
Module.InitDeps({
	Apps = {
		ReconstructorEvidence = Evidence,
		ServerReferenceAnalysis = Analysis,
		Explorer = {
			GetInferenceNodes = function()
				return largeIndex
			end,
			GetInferenceCandidates = function()
				return { [indexedScript] = indexedNode }
			end,
		},
	},
	Main = {},
	env = {},
	service = {},
	Task = {
		spawn = function(fn)
			indexedWork[#indexedWork + 1] = fn
		end,
	},
	Game = indexedWorld,
})
local indexed = Module.Main().Create()
assert(indexed:Scan())
indexedWork[1]()
assert(
	indexed.Stats.Phase == "Complete" and indexed.Stats.DiscoveryVisited == 1 and indexed.Stats.Scanned == 1,
	"discovery visits the maintained candidate index, not 50,000 unrelated objects"
)
assert(indexed.Tree.Nodes[Evidence.Key({ "ServerStorage", "Indexed" })])
print("PASS: indexed discovery avoids unrelated game geometry")

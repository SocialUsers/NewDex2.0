--!strict

local Strings = require("../src/Apps/Reconstructor/Services/BytecodeStrings").Main()
local Module = require("../src/Apps/Reconstructor/Services/ScriptEvidenceReader")
local function varint(value)
	local result = {}
	repeat
		local byte = value % 128
		value = math.floor(value / 128)
		result[#result + 1] = string.char(byte + (value > 0 and 128 or 0))
	until value == 0
	return table.concat(result)
end
local function bytes(strings)
	local result = { string.char(14, 3), varint(#strings) }
	for _, text in ipairs(strings) do
		result[#result + 1] = varint(#text) .. text
	end
	return table.concat(result)
end
local literal = bytes({ "ServerStorage.Modules.Example", "require", "Folder" })
local seen = {}
assert(Strings.Visit(literal, function(text)
	seen[#seen + 1] = text
end))
assert(#seen == 1 and seen[1] == "ServerStorage.Modules.Example")
local emitted = 0
assert(not Strings.Visit(literal:sub(1, -2), function()
	emitted += 1
end))
assert(emitted == 0, "truncated string tables publish no partial evidence")
assert(not Strings.Visit(string.char(99, 3, 0), function() end))
assert(not Strings.Visit(bytes(table.create(200, "ServerStorage.A")), function() end, function()
	return false
end))
local time, reads, decompiles, waits = 0, 0, 0, 0
local nativeCost = 0.01
local env = {
	getscriptbytecode = function(obj)
		reads += 1
		return obj.Bytes
	end,
	isViableDecompileScript = function()
		return true
	end,
	decompile = function()
		decompiles += 1
		time += nativeCost
		return "require(game.ServerStorage.Modules.Example)"
	end,
}
Module.InitDeps({ env = env, Apps = { BytecodeStrings = Strings } })
local api = Module.Main()
local hints = {}
local reader = api.Create({
	Clock = function()
		return time
	end,
	Wait = function(seconds)
		waits += 1
		time += seconds
	end,
	Literal = function(_, text)
		hints[#hints + 1] = text
	end,
})
local small = { Bytes = literal }
assert(reader:Read(small).Status == "Source" and reads == 1 and decompiles == 1)
local replay = reader:Read(small)
assert(replay.Status == "Source" and decompiles == 1, "uncommitted analysis replays without another native call")
reader:Commit(small, replay.Source)
assert(reader:Read(small).Status == "Cached" and decompiles == 1)
assert(#hints == 1)
local second = { Bytes = literal .. "different proto" }
assert(reader:Read(second).Status == "Source" and waits == 1, "native decompiles are paced")
local large = { Bytes = literal .. string.rep("x", 4096) }
assert(reader:Read(large).Status == "Deferred" and decompiles == 2, "large scripts never reach the native decompiler")
assert(reader:Read({ Bytes = bytes({ "ordinary client code" }) }).Status == "Filtered" and decompiles == 2)
nativeCost = 0.04
assert(reader:Read({ Bytes = literal .. "slow" }).Status == "Source")
assert(reader.DecompilePaused)
assert(
	reader:Read({ Bytes = literal .. "after slow" }).Status == "Deferred" and decompiles == 3,
	"slow native calls open the circuit"
)
assert(reader:Read(small, function()
	return false
end).Status == "Cancelled")
print(
	"PASS: bytecode string validation, small-candidate decompilation, pacing, cache reuse, large-script deferral and native circuit breaker"
)

local budgetReader = api.Create({
	Clock = function()
		return time
	end,
	Wait = function(seconds)
		time += seconds
	end,
})
nativeCost = 0
local batchStart = time
for i = 1, 32 do
	local obj = { Bytes = literal .. tostring(i) }
	local outcome = budgetReader:Read(obj)
	assert(outcome.Status == "Source")
	budgetReader:Commit(obj, outcome.Source)
end
assert(
	math.abs((time - batchStart) - 31 * 0.05) < 0.00001,
	"a full batch preserves a 50 ms native-call gap without the old 250 ms delay"
)
local pending = { Bytes = literal .. "pending" }
assert(budgetReader:Read(pending).Status == "Deferred")
budgetReader:BeginPass()
assert(budgetReader:Read(pending).Status == "Source", "pass limits cannot permanently cache away pending candidates")
local direct = { Source = "game.ServerStorage.Direct" }
assert(budgetReader:Read(direct).Status == "Source")
assert(budgetReader:Read(direct).Status == "Source", "cancelled source analysis stays pending")
budgetReader:Commit(direct, direct.Source)
assert(budgetReader:Read(direct).Status == "Cached")
print("PASS: transactional source cache, cancelled analysis replay and per-pass quota recovery")

local split = bytes({ "Server", "Storage", "Modules", "Inventory" })
assert(Strings.HasServerHint(split))
local splitReader = api.Create({
	Clock = function()
		return time
	end,
	Wait = function(seconds)
		time += seconds
	end,
})
local splitSource = splitReader:Read({ Bytes = split })
assert(
	splitSource.Status == "Source",
	"split service constants remain decompile candidates instead of being filtered out"
)
print("PASS: split service-name bytecode hints preserve computed-path candidates")

env.decompile = nil
local noDecompiler = api.Create({
	Clock = function()
		return time
	end,
	Wait = function() end,
})
local unavailable = noDecompiler:Read({ Bytes = literal })
assert(
	unavailable.Status == "Deferred" and unavailable.Reason == "Decompiler unavailable",
	"missing decompilers never masquerade as renewable quotas"
)
local failures = 0
env.decompile = function()
	failures += 1
	error("provider failed")
end
local failedReader = api.Create({
	Clock = function()
		return time
	end,
	Wait = function(seconds)
		time += seconds
	end,
})
local failedObject = { Bytes = literal }
for _ = 1, 3 do
	failedReader:BeginPass()
	assert(failedReader:Read(failedObject).Status == "Unavailable")
end
assert(failures == 2, "permanent provider failures cannot starve the remaining candidate queue")
print("PASS: missing-provider coverage reasons and bounded failure retries")

local recoveredTime, slowCalls = 0, 0
env.decompile = function()
	slowCalls += 1
	recoveredTime += slowCalls == 1 and 0.04 or 0.005
	return "require(game.ServerStorage.Recovered)"
end
local recovery = api.Create({
	Clock = function()
		return recoveredTime
	end,
	Wait = function(seconds)
		recoveredTime += seconds
	end,
})
assert(recovery:Read({ Bytes = literal .. "mild" }).Status == "Source" and recovery.DecompilePaused)
recoveredTime += 6
recovery:BeginPass()
assert(
	not recovery.DecompilePaused and recovery:Read({ Bytes = literal .. "later" }).Status == "Source",
	"a mild timing overrun cannot permanently disable the session"
)
env.decompile = function()
	recoveredTime += 0.2
	return ""
end
recovery:Read({ Bytes = literal .. "severe" })
recoveredTime += 6
recovery:BeginPass()
assert(recovery.DecompilePaused and recovery.SeverePause, "a severe native stall keeps the circuit open")
print("PASS: measured mild-overrun recovery and severe-stall stop")

local byteClock, byteCost = 0, 0.015
env.getscriptbytecode = function(obj)
	byteClock += byteCost
	return obj.Bytes
end
env.decompile = nil
local byteRecovery = api.Create({
	Clock = function()
		return byteClock
	end,
	Wait = function() end,
})
local outcome = byteRecovery:Read({ Bytes = literal .. "byte pause" })
assert(outcome.Status == "Deferred" and byteRecovery.BytecodePaused and not byteRecovery.SevereBytecodePause)
assert(byteRecovery:Read({ Bytes = literal }).Reason == "Bytecode circuit cooling down")
byteClock += 6
byteCost = 0.0001
byteRecovery:BeginPass()
assert(not byteRecovery.BytecodePaused and byteRecovery:Read({ Bytes = bytes({ "ordinary" }) }).Status == "Filtered")
print("PASS: mild bytecode read overruns cool down instead of permanently disabling later collection")

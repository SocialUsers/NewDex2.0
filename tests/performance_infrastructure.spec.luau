--!strict

local Buffer = require("../src/Shared/EditorBuffer").Main()
local b = Buffer.Create("abcdef")
b:Replace(3, 5, "XYZ")
assert(b:GetText() == "abXYZef")
b:Replace(1, 1, "!")
b:Replace(b.Length + 1, b.Length + 1, "?")
assert(b:GetText() == "!abXYZef?")
local reference = b:GetText()
math.randomseed(902)
for i = 1, 2000 do
	local first = math.random(1, #reference + 1)
	local last = math.random(first, #reference + 1)
	local value = ({ "", "abc", "\n", "é", "🙂" })[math.random(1, 5)]
	b:Replace(first, last, value)
	reference = reference:sub(1, first - 1) .. value .. reference:sub(last)
	assert(b:GetText() == reference and b.Length == #reference, "piece buffer differs from string edits")
	assert(#b.Pieces <= 256, "piece metadata must remain bounded")
end
local count = b.Stats.Materializations
b:GetText()
b:GetText()
assert(b.Stats.Materializations == count)
local control = require("../src/Apps/ScriptViewer/Util/EditorDocument")
control.InitDeps({ Apps = { EditorBuffer = { Create = Buffer.Create } } })
local doc = control.Main().Create("local x=1\nreturn x")
local changed = doc:Apply("InsertText", 1, 1, { Text = "-- note\n" })
assert(doc.Buffer and changed.Text == "-- note\nlocal x=1\nreturn x")
local now = 0
local listener
local alive = true
local waits = 0
local Main = {
	Alive = true,
	TrackSignal = function(signal, fn)
		listener = fn
		return { Disconnect = function() end }
	end,
}
local perf = require("../src/Shared/PerformanceRuntime")
perf.InitDeps({
	Main = Main,
	service = { RunService = { Heartbeat = {} } },
	Clock = function()
		return now
	end,
	Wait = function()
		waits += 1
		now += 0.016
		listener(0.016)
	end,
})
local P = perf.Main()
assert(P.Available())
now = 0.004
assert(not P.Available())
assert(P.Checkpoint("scan") and waits == 1 and P.Available())
assert(not P.Checkpoint("scan", function()
	return false
end) and waits == 1)
for i = 1, 200 do
	P.Record("scope/" .. i, 0.001)
	listener(0.1)
end
local snapshot = P.Snapshot()
local metrics = 0
for _ in pairs(snapshot.Metrics) do
	metrics += 1
end
assert(metrics <= 193 and #snapshot.SlowFrames == 120, "trace storage is bounded")
snapshot.Metrics.Other.Count = 0
assert(P.Metrics.Other.Count > 0, "snapshot must not mutate live metrics")
print(
	"PASS: piece edits/UTF-8 bytes, bounded fragmentation, materialization reuse, real editor integration, shared budget/yields/cancellation and bounded local traces"
)

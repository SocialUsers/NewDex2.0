--!strict
local raw, decoded, readFails, writeFails
local env = {
	isfile = function(path)
		assert(path == "dex/input-macros.json")
		return raw ~= nil
	end,
	readfile = function()
		if readFails then
			error("read error")
		end
		return raw
	end,
	writefile = function(_, data)
		if writeFails then
			return false
		end
		raw = data
	end,
}
local http = {
	JSONEncode = function(_, data)
		decoded = data
		return "encoded"
	end,
	JSONDecode = function(_, data)
		assert(data == "encoded")
		return decoded
	end,
}
local apps = { MacroEngine = { Validate = function(events) return type(events) == "table" end } }
local deps = { Apps = apps, env = env, service = { HttpService = http } }
local MacroStore = (function()
-- PRODUCTION
end)()
MacroStore.InitDeps(deps)
local store = MacroStore.Main()
assert(store.Available() and not store.Exists())
local name = "Walk and jump"
local macro = { Name = name, Events = { { Kind = "KeyDown", Time = 0, Key = "W" } }, Loop = false, Speed = 1 }
assert(store.Save({ macro }) and store.Exists())
local loaded, reason = store.Load()
assert(not reason and loaded[1].Name == name and loaded[1].Events[1].Key == "W", "saved macro round-trip")
macro.Hotkey = "F8"
assert(not store.Save({ macro }), "the emergency stop key cannot become a playback trigger")
macro.Hotkey = nil
macro.Speed = 0 / 0
assert(not store.Save({ macro }), "nonfinite speed rejected")
macro.Speed = 1
assert(not store.Save({ [1] = macro, stray = macro }), "array must have consecutive integer indexes")
writeFails = true
assert(not store.Save({ macro }), "failed writes are reported")
writeFails = false
readFails = true
local _, errorMessage = store.Load()
assert(errorMessage)
readFails = false
raw = "broken"
local macros, problem = store.Load()
assert(#macros == 0 and problem == "Invalid macro file")
env.isfile = nil
assert(not store.Available() and not store.Save({ macro }), "no executor storage required to load the tool")
print("PASS: macro library round-trip, limits, corrupt files and storage failures")

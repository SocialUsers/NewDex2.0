import argparse
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--luau', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / 'main.lua').read_text(encoding='utf-8')
start = source.index('\tMain.FetchAPI = function(')
end = source.index('\n\t\tlocal classes, enums = {}, {}', start)
driver = '''
local Main, Lib, service, game, script, task, require
local function run(cached, responses, elevated, upToDate)
    local calls = 0
    local progress = {}
    Main = {Elevated=elevated ~= false, DepsVersionData={"current"}, RobloxVersion="version-test", LocalDepsUpToDate=function() return upToDate ~= false end}
    Lib = {ReadFile=function() return cached end}
    service = {HttpService={JSONDecode=function(_, text)
        if text == "valid" or text == "fallback" then return {Classes={{Name="Instance"}}, Enums={}} end
        if text == "wrong-schema" then return {message="unavailable"} end
        error("Cannot parse JSON")
    end}}
    game = {HttpGet=function(_, url, bypass)
        calls += 1
        assert(bypass == true)
        if calls == 1 then assert(url == "https://setup.rbxcdn.com/version-test-API-Dump.json") end
        if calls == 2 then assert(url:find("Roblox-Client-Tracker", 1, true)) end
        local response = responses[calls]
        if response == false then error("HTTP failure") end
        return response
    end}
    script = {FindFirstChild=function() return true end, API={}}
    require = function() return cached end
    task = {spawn=function() end}
    INSTALL
    local ok, result = pcall(Main.FetchAPI, nil, nil, nil, function(message) progress[#progress+1] = message end)
    return ok, result, calls, Main, progress
end
local ok, result, calls, state = run("valid", {})
assert(ok and result.Classes and calls == 0 and state.RawAPI == "valid")
local _, _, _, _, progress = run("valid", {})
assert(table.concat(progress, "|") == "Reading dex-explorer/rbx_api.dat|Reading API-Dump.json", "cached API status names the actual file")
ok, result, calls, state = run("valid", {"fallback"}, true, false)
assert(ok and calls == 1 and state.RawAPI == "fallback")
for _, invalid in ipairs({"", "<html>unavailable</html>", "wrong-schema"}) do
    ok, result, calls, state = run(invalid, {"valid"})
    assert(ok and calls == 1 and state.RawAPI == "valid" and state.DepsVersionData[1] == "")
end
ok, result, calls, state = run(nil, {false, "fallback"})
assert(ok and calls == 2 and state.RawAPI == "fallback")
_, _, _, _, progress = run(nil, {false, "fallback"})
assert(table.concat(progress, "|") == "Reading dex-explorer/rbx_api.dat|Downloading version-test-API-Dump.json|Downloading API-Dump.json|Reading API-Dump.json", "fallback status follows the actual requested resource")
ok, result, calls, state = run(nil, {"wrong-schema", "fallback"})
assert(ok and calls == 2 and state.RawAPI == "fallback")
ok, result, calls, state = run(nil, {"bad", "bad"})
assert(not ok and calls == 2 and state.RawAPI == nil and tostring(result):find("metadata was unavailable", 1, true))
ok, result, calls = run("valid", {}, false)
assert(ok and calls == 0)
print("PASS: API metadata cache validation, repair, failed-request/schema fallback, clear failure and embedded Studio metadata")
'''
output = root / '.build/api_metadata_checks.luau'
output.parent.mkdir(exist_ok=True)
output.write_text(driver.replace('INSTALL', source[start:end] + '\nreturn api\nend'), encoding='utf-8')
subprocess.run([args.luau, str(output)], check=True)

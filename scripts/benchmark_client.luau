--!strict

local global = getgenv()
local http = game:GetService("HttpService")
local root = "dex-explorer/development/"
assert(type(readfile) == "function", "Stage the development runtime with python scripts/stage_client.py")
local report = { version = 1, started = os.time(), loads = {}, search = {}, errors = {} }
local originalRead = readfile

local function load(mode)
	local old = global.DexPlus
	if old and old.Main then
		old.Main.Shutdown()
	end
	local requests, bytes = 0, 0
	local function fetch(path)
		local source = originalRead(root .. path)
		requests += 1
		bytes += #source
		return source
	end
	local started = os.clock()
	local chunk = assert(loadstring(fetch("src/Runtime/Bootstrap.luau")))
	local environment = setmetatable({
		readfile = function(path)
			if mode == "cold" and path:find("dex-explorer/cache/modules/", 1, true) == 1 then
				error("benchmark cold cache")
			end
			assert(type(originalRead) == "function", "File API unavailable")
			return originalRead(path)
		end,
	}, { __index = getfenv() })
	setfenv(chunk, environment)
	chunk()(root, { Fetch = fetch })
	report.loads[mode] = {
		seconds = os.clock() - started,
		sourceReads = requests,
		sourceBytes = bytes,
		runtime = global.DexPlusRuntimeStats,
	}
	task.wait(0.2)
end

local ok, problem = xpcall(function()
	load("cold")
	load("warm")
	local explorer = assert(global.DexPlus.Apps.Explorer)
	local search = global.DexPlus.Apps.SearchQuery
	local originalScan = search.Scan
	local previousQuery = explorer.Query or ""
	local function runSearches(label, indexed)
		local samples = {}
		if not indexed then
			search.Scan = function(roots, predicate, results, matches, expanded, checkpoint)
				return originalScan(roots, predicate, results, matches, expanded, checkpoint)
			end
		end
		local success, failure = xpcall(function()
			for _, query in ipairs({ "p", "pa", "par", "part" }) do
				local started = os.clock()
				explorer.DoSearch(query)
				samples[#samples + 1] = {
					query = query,
					seconds = os.clock() - started,
					scan = search.LastScanStats,
					matches = #explorer.MatchList,
				}
				task.wait()
			end
		end, debug.traceback)
		search.Scan = originalScan
		report.search[label] = samples
		if not success then
			error(failure, 0)
		end
	end
	local success, failure = xpcall(function()
		runSearches("predicate", false)
		runSearches("indexed", true)
	end, debug.traceback)
	search.Scan = originalScan
	explorer.DoSearch(previousQuery)
	if not success then
		error(failure, 0)
	end
end, debug.traceback)
if not ok then
	report.errors[#report.errors + 1] = tostring(problem)
end
for _, path in ipairs({ "dex-explorer", "dex-explorer/validation" }) do
	pcall(makefolder, path)
end
writefile("dex-explorer/validation/performance.json", http:JSONEncode(report))
print("[Dex Explorer] Performance report saved to dex-explorer/validation/performance.json")
if not ok then
	warn(problem)
end

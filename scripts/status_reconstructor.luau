--!strict

local global = getgenv and getgenv() or _G
local dex = assert(global.DexPlus, "Dex Explorer is not running")
local app = assert(dex.Apps.Reconstructor, "Reconstructor module is missing")
local session = assert(app.Session, "Reconstructor session is missing")
local report = {
	Captured = os.time(),
	Alive = dex.Main.Alive,
	Running = session.Running,
	Status = app.Status,
	Stats = session.Stats,
	Nodes = session.Tree.Count,
}
if session.Worker then
	local ok, state = pcall(coroutine.status, session.Worker)
	report.Worker = ok and state or "unavailable"
end
local json = game:GetService("HttpService"):JSONEncode(report)
writefile("dex-explorer/validation/server-tree-status.json", json)
print("[Dex Explorer] Current server-tree status saved: " .. json)

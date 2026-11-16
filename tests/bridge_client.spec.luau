--!strict

local encoded = {}
local counter = 0
local json = {}
function json:JSONEncode(value)
	counter += 1
	local key = "json-" .. counter
	encoded[key] = value
	return key
end
function json:JSONDecode(value)
	assert(encoded[value], "invalid JSON fixture")
	return encoded[value]
end
local jobs, delayed = {}, {}
local function spawn(fn)
	jobs[#jobs + 1] = fn
end
local function drain()
	while #jobs > 0 do
		table.remove(jobs, 1)()
	end
end
local requestCount, patches, executed, destroyed = 0, {}, 0, 0
local sessionNumber = 0
local client
local race, yieldPatch, rejectTicket, rejectHello = false, false, false, false
local function request(options)
	requestCount += 1
	assert(
		options.Url:match("^http://127%.0%.0%.1:37429/bridge/"),
		"transport is confined to the explicitly paired loopback endpoint"
	)
	assert(not options.Url:find("Bearer", 1, true), "credentials are not placed in URLs")
	if options.Url:find("/bridge/ticket", 1, true) then
		if rejectTicket then
			return { StatusCode = 401 }
		end
		return { StatusCode = 200, Body = json:JSONEncode({ ticket = "dxwt_test_ticket" }) }
	end
	if options.Method == "POST" then
		sessionNumber += 1
		return {
			StatusCode = 200,
			Body = json:JSONEncode({ sessionId = "session-" .. sessionNumber, agentToken = "dxb_testing_token" }),
		}
	elseif options.Method == "PATCH" then
		local body = json:JSONDecode(options.Body)
		patches[#patches + 1] = body.grants
		if yieldPatch then
			yieldPatch = false
			coroutine.yield()
		end
		if race then
			race = false
			client:SetGrants({ edit = false, execute = false })
		end
		return { StatusCode = 200, Body = json:JSONEncode({}) }
	end
	assert(options.Method == "DELETE")
	return { StatusCode = 204 }
end
local sockets = {}
local websocket = {
	connect = function(url)
		assert(url == "ws://127.0.0.1:37429/bridge/ws?ticket=dxwt_test_ticket")
		local ws = { OnMessage = signal(), OnClose = signal(), Sent = {} }
		function ws:Send(text)
			local message = json:JSONDecode(text)
			if rejectHello and message.type == "hello" then
				error("closed before writing hello")
			end
			self.Sent[#self.Sent + 1] = message
		end
		function ws:Close()
			self.Closed = true
			self.OnClose:Fire()
		end
		sockets[#sockets + 1] = ws
		return ws
	end,
}
local function createRouter()
	return {
		Execute = function(_, name, args, grants)
			assert(grants.inspect, "inspect grant required")
			if name == "edit" then
				assert(grants.edit, "Edit access denied")
			end
			if args.stale then
				error("STALE_INSTANCE: Instance no longer exists")
			end
			executed += 1
			return { name = name, value = args.value }
		end,
		Capabilities = function()
			return {
				protocol = 1,
				commands = { { name = "read", grant = "inspect" }, { name = "edit", grant = "edit" } },
			}
		end,
		Destroy = function()
			destroyed += 1
		end,
	}
end
client = Client.Create({
	Http = json,
	Request = request,
	WebSocket = websocket,
	Router = createRouter,
	Spawn = spawn,
	Delay = function(_, fn)
		delayed[#delayed + 1] = fn
	end,
})
assert(requestCount == 0 and #sockets == 0, "creating the optional bridge performs no network work")
assert(not Client.ParseCode("https://evil.test/"))
assert(not Client.ParseCode("37429.short"))
assert(not Client.ParseCode("80." .. string.rep("a", 30)))
local code = "37429." .. string.rep("a", 32)
assert(client:Connect(code, { edit = true }))
local ws = sockets[1]
assert(
	ws.Sent[1].type == "hello" and ws.Sent[1].sessionId == "session-1",
	"initial message authenticates the correct session"
)
ws.OnMessage:Fire(json:JSONEncode({ type = "ready" }))
assert(client.State == "Connected")
local command = { type = "command", id = "cmd-1", name = "edit", args = { value = false, password = "never-log-this" } }
ws.OnMessage:Fire(json:JSONEncode(command))
drain()
assert(executed == 1 and ws.Sent[#ws.Sent].result.value == false)
assert(
	client:GetSummary().Completed == 1 and client:GetSummary().Port == 37429,
	"summary exposes useful connection data without credentials"
)
assert(
	client.Recent[1].RequestText:find("false", 1, true) and client.Recent[1].ResultText:find("false", 1, true),
	"activity retains actual arguments and returned false values"
)
assert(
	not client.Recent[1].RequestText:find("never-log-this", 1, true)
		and client.Recent[1].RequestText:find("[redacted]", 1, true),
	"credential fields are redacted"
)
assert(client.Recent[1].CommandId == "cmd-1")
assert(
	client.Recent[1].TimeLabel and client.Recent[1].Duration >= 0,
	"activity records bounded timings and completion time"
)
ws.OnMessage:Fire(json:JSONEncode(command))
drain()
assert(executed == 1, "a repeated completed command returns its old result without repeating the edit")
client:SetPaused(true)
ws.OnMessage:Fire(json:JSONEncode({ type = "command", id = "cmd-2", name = "edit", args = {} }))
drain()
assert(executed == 1 and ws.Sent[#ws.Sent].error.code == "PAUSED")
client:SetPaused(false)
client:SetGrants({ edit = false, execute = false })
ws.OnMessage:Fire(
	json:JSONEncode({ type = "command", id = "cmd-3", name = "edit", args = {}, grants = { edit = true } })
)
drain()
assert(executed == 1 and not ws.Sent[#ws.Sent].ok, "remote envelope grants cannot override local revocation")
assert(ws.Sent[#ws.Sent].error.code == "COMMAND_FAILED")
ws.OnMessage:Fire(json:JSONEncode({ type = "command", id = "cmd-stale", name = "read", args = { stale = true } }))
drain()
local staleResult = ws.Sent[#ws.Sent]
assert(not staleResult.ok and staleResult.error.code == "STALE_INSTANCE")
assert(staleResult.error.message == "Instance no longer exists")
race = true
client:SetGrants({ edit = true, execute = true })
assert(
	#patches == 3 and patches[2].edit and not patches[3].edit and not client.Grants.edit,
	"late upgrade acknowledgement cannot undo a newer revocation"
)
ws.OnMessage:Fire(json:JSONEncode({ type = "command", id = "cmd-4", name = "read", args = {} }))
client:Disconnect()
drain()
assert(
	executed == 1 and destroyed == 1 and client.State == "Disconnected",
	"disconnect invalidates queued commands and owns router cleanup"
)
for _, fn in ipairs(delayed) do
	fn()
end
assert(#sockets == 1, "cancelled timers cannot reconnect a disconnected session")
client:Destroy()
client:Destroy()
local unsupported =
	Client.Create({ Http = json, Request = false, WebSocket = false, Spawn = spawn, Delay = function() end })
assert(not unsupported:Supported(), "an unsupported executor reports capability absence without indexing HttpService")
unsupported:Destroy()
local policy = { dex_get_selection = true }
local modern = Client.Create({
	Http = json,
	Request = request,
	WebSocket = websocket,
	Router = createRouter,
	Spawn = spawn,
	Delay = function() end,
	DisabledTools = policy,
})
assert(modern:Connect(code))
local modernSocket = sockets[2]
assert(modernSocket.Sent[1].toolControls and modernSocket.Sent[1].disabledTools[1] == "dex_get_selection")
modernSocket.OnMessage:Fire(json:JSONEncode({ type = "ready", tools = { { name = "dex_get_selection" } } }))
assert(modern.ToolControls and #modern.CommandCatalog == 1 and modern.PolicyPending)
modernSocket.OnMessage:Fire(json:JSONEncode({ type = "tool_policy_ack", revision = modern.PolicyPending }))
assert(not modern.PolicyPending)
modernSocket.OnMessage:Fire(json:JSONEncode({ type = "command", id = "late", name = "dex_get_selection" }))
drain()
assert(modernSocket.Sent[#modernSocket.Sent].error.code == "COMMAND_DISABLED")
modernSocket.OnMessage:Fire(json:JSONEncode({
	type = "tool_activity", id = "tool-1", name = "dex_tool_plan", state = "running", request = "example",
}))
local running = modern.Recent[1]
assert(running.Status == "running" and running.RequestText == "example")
assert(modern:GetSummary().ActiveCommand == "dex_tool_plan")
modernSocket.OnMessage:Fire(json:JSONEncode({
	type = "tool_activity", id = "tool-1", name = "dex_tool_plan", state = "completed", result = "false", duration = 25,
}))
assert(#modern.Recent == 1 and modern.Recent[1] == running and running.Ok and running.ResultText == "false")
assert(modern:GetSummary().ActiveCommand == nil)
modern:Destroy()
drain()
local lifecycle = Client.Create({
	Http = json,
	Request = request,
	WebSocket = websocket,
	Router = createRouter,
	Spawn = spawn,
	Delay = function(_, fn)
		delayed[#delayed + 1] = fn
	end,
})
assert(lifecycle:Connect(code))
local first = sockets[#sockets]
first.OnMessage:Fire(json:JSONEncode({ type = "ready" }))
first:Close()
rejectTicket = true
local finalRetry = #delayed
delayed[finalRetry]()
assert(lifecycle.State == "Disconnected" and not lifecycle.SessionId and #delayed == finalRetry,
	"an expired session should stop reconnecting and allow a new pairing")

rejectTicket = false
rejectHello = true
assert(not lifecycle:Connect(code) and lifecycle.State == "Disconnected" and not lifecycle.SessionId,
	"a failed hello must tear down the session and return failure")
rejectHello = false

assert(lifecycle:Connect(code))
yieldPatch = true
local oldGrant = coroutine.create(function()
	assert(not lifecycle:SetGrants({ edit = true }))
end)
assert(coroutine.resume(oldGrant) and coroutine.status(oldGrant) == "suspended")
assert(lifecycle:Connect(code))
yieldPatch = true
local newGrant = coroutine.create(function()
	assert(lifecycle:SetGrants({ execute = true }))
end)
assert(coroutine.resume(newGrant) and coroutine.status(newGrant) == "suspended",
	"the previous session cannot keep the new session from starting its own grant update")
assert(coroutine.resume(oldGrant))
assert(lifecycle.UpdatingGrants,
	"a stale grant response cannot clear the in-flight flag for the new session")
assert(coroutine.resume(newGrant) and lifecycle.Grants.execute and not lifecycle.Grants.edit)
lifecycle:Destroy()
drain()
print(
	"PASS: bridge transport confinement, lazy startup, authenticated handshake, at-most-once edits, grant revocation races, pause and lifecycle cleanup"
)

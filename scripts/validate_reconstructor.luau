--!strict

local report = { Version = 2, Started = os.time(), Errors = {} }
local ok, problem = xpcall(function()
	local global = getgenv and getgenv() or _G
	local current = global.DexPlus
	if current and current.Main then
		current.Main.Shutdown()
	end
	local source = readfile("dex-explorer/development/src/Runtime/Bootstrap.luau")
	local boot = assert(loadstring(source, "@DexExplorer/ReconstructorValidation"))()
	boot("local-development/", {
		Fetch = function(path)
			return readfile("dex-explorer/development/" .. path)
		end,
	})
	current = assert(global.DexPlus, "Dex Explorer did not initialize")
	local apps = current.Apps
	local frames = 0
	local frameConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		frames += 1
		if frames > 2 then
			report.MaxFrameSeconds = math.max(report.MaxFrameSeconds or 0, dt)
			if dt > 0.05 then
				report.FramesOver50ms = (report.FramesOver50ms or 0) + 1
			end
		end
	end)
	local fixture = apps.ReconstructorEvidence.Create()
	apps.ServerReferenceAnalysis.Source(
		'local ss = game:GetService("ServerStorage")\nrequire(ss.Modules.Inventory)',
		"Isolated validation fixture",
		function(path, evidence)
			fixture:Add(path, evidence)
		end
	)
	local node = fixture.Nodes[apps.ReconstructorEvidence.Key({ "ServerStorage", "Modules", "Inventory" })]
	assert(node and node.Classes.ModuleScript, "Literal/alias inference failed")
	apps.Reconstructor.GetSession()
	assert(apps.Reconstructor.Session, "Reconstructor session failed to initialize")
	assert(not apps.Reconstructor.Session.ProbePending, "Initialization unexpectedly started a remote call")
	assert(type(apps.Explorer.SyncInferredTree) == "function", "Main Explorer inference overlay is missing")
	task.wait(2)
	report.Automatic = apps.Reconstructor.Automatic == true
	report.ScanStatus = apps.Reconstructor.Status
	report.ScanStats = apps.Reconstructor.Session.Stats
	report.FixtureNodes = fixture.Count
	report.InferredNodes = apps.Reconstructor.Session.Tree.Count
	report.StartupPassed = true
	report.Passed = false
	task.spawn(function()
		local deadline = os.clock() + 60
		while apps.Reconstructor.Session.Running and os.clock() < deadline do
			task.wait(1)
		end
		local treeSession = apps.Reconstructor.Session
		report.FirstScanStats = treeSession.Stats
		local before = {}
		for id in pairs(treeSession.Tree.Nodes) do
			before[id] = true
		end
		task.wait(12)
		deadline = os.clock() + 60
		while treeSession.Running and os.clock() < deadline do
			task.wait(1)
		end
		if not treeSession.Running then
			treeSession:RequestScan()
		end
		while treeSession.Running and os.clock() < deadline do
			task.wait(1)
		end
		report.AddedPaths = 0
		report.RetainedPaths = 0
		report.MissingPaths = 0
		for id in pairs(treeSession.Tree.Nodes) do
			if before[id] then
				report.RetainedPaths += 1
			else
				report.AddedPaths += 1
			end
		end
		for id in pairs(before) do
			if not treeSession.Tree.Nodes[id] then
				report.MissingPaths += 1
			end
		end
		frameConnection:Disconnect()
		report.ScanStatus = apps.Reconstructor.Status
		report.ScanStats = apps.Reconstructor.Session.Stats
		report.InferredNodes = apps.Reconstructor.Session.Tree.Count
		report.Scanning = apps.Reconstructor.Session.Running
		report.Passed = not report.Scanning and not treeSession.Stats.Error and treeSession.Stats.Phase == "Complete"
		if treeSession.Stats.Error then
			report.Errors[#report.Errors + 1] = treeSession.Stats.Error
		end
		if report.Scanning then
			report.Errors[#report.Errors + 1] = "Scan did not complete before validation deadline; phase: "
				.. tostring(treeSession.Stats.Phase)
		end
		print(
			report.Passed and "[Dex Explorer] Reconstructor scans completed; report saved."
				or "[Dex Explorer] Reconstructor scan incomplete or failed; report saved."
		)
		writefile("dex-explorer/validation/server-tree.json", game:GetService("HttpService"):JSONEncode(report))
	end)
end, debug.traceback)
if not ok then
	report.Errors[#report.Errors + 1] = tostring(problem)
end
local http = game:GetService("HttpService")
pcall(makefolder, "dex-explorer")
pcall(makefolder, "dex-explorer/validation")
writefile("dex-explorer/validation/server-tree.json", http:JSONEncode(report))
if ok then
	print(
		"[Dex Explorer] Reconstructor validation started. Wait for the completion message; startup alone is not a pass. No game remotes were invoked."
	)
else
	warn("[Dex Explorer] Reconstructor check failed: " .. tostring(problem))
end

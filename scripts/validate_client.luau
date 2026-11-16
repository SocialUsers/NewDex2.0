--!strict

local report = { version = 4, started = os.time(), errors = {}, rows = {} }
local http = game:GetService("HttpService")
local started = os.clock()
local current = getgenv and getgenv().DexPlus
local ok, problem = xpcall(function()
	if current and current.Main then
		current.Main.Shutdown()
	end
	if getgenv then
		getgenv().DexPlus = nil
	end
	local root = "dex-explorer/development/"
	assert(type(readfile) == "function", "Stage the development runtime with python scripts/stage_client.py")
	report.source = "local-development"
	local source = readfile(root .. "src/Runtime/Bootstrap.luau")
	local run = assert(loadstring(source, "@DexExplorer/ValidationBootstrap"))()
	run(root, {
		Fetch = function(path)
			return readfile(root .. path)
		end,
	})
end, debug.traceback)
report.loadSeconds = os.clock() - started
report.loaded = ok
if not ok then
	report.errors[#report.errors + 1] = tostring(problem)
end
task.wait(1)
report.runtime = getgenv and getgenv().DexPlusRuntimeStats or nil
current = getgenv and getgenv().DexPlus
if current and current.Apps and current.Apps.Explorer then
	local explorer = current.Apps.Explorer
	local view = explorer.TreeRenderer
	report.renderer =
		{ name = view.Renderer, roots = view.RootCount, commits = view.Commits, rowHeight = explorer.RowHeight }
	local viewport = explorer.GuiElems.TreeFrame
	report.viewport = {
		class = viewport.ClassName,
		canvasWidth = viewport.CanvasSize.X.Offset,
		canvasHeight = viewport.CanvasSize.Y.Offset,
		width = viewport.AbsoluteWindowSize.X,
		height = viewport.AbsoluteWindowSize.Y,
		scrollbar = viewport.ScrollBarThickness,
	}
	report.menus = { insert = explorer.InsertObjectContext ~= nil }
	report.palette = {}
	for _, key in ipairs({ "Main1", "ListSelection", "SelectionContext", "ExplorerHover" }) do
		local color = current.Settings.Theme[key]
		if color then
			report.palette[key] = { color.R, color.G, color.B }
		end
	end
	local refreshStart = os.clock()
	for _ = 1, 10 do
		explorer.Refresh()
	end
	report.tenRefreshSeconds = os.clock() - refreshStart
	report.services = {}
	local history = current.Apps.History
	local savedEntries, savedIndex, savedFocused = table.clone(history.Entries), history.Index, history.Focused
	local fixture = Instance.new("Folder")
	local success, serviceError = xpcall(function()
		local service = explorer.Services
		assert(service.Reflection.CanCreate("Folder"), "Folder class is not insertable")
		assert(not service.Reflection.CanCreate("Players"), "Services cannot be inserted")
		local inserted = service.Insertion.Insert(
			"Folder",
			{ { Obj = fixture } },
			{ DefaultProperties = { Folder = {
				Archivable = function()
					return false
				end,
			} } }
		)
		assert(
			#inserted == 1 and inserted[1].Parent == fixture and inserted[1].Archivable == false,
			"Insertion/default values"
		)
		service.Editing.Rename(inserted[1], "Validated")
		assert(inserted[1].Name == "Validated", "Rename")
		assert(history.Undo() and inserted[1].Name ~= "Validated", "Undo rename")
		assert(history.Redo() and inserted[1].Name == "Validated", "Redo rename")
		local store = current.Apps.SelectionService.NewStore()
		local node = { Obj = inserted[1] }
		local selection = current.Apps.SelectionService.Bind(store, function(obj)
			return obj == inserted[1] and node
		end)
		selection:Set({ inserted[1], inserted[1] })
		assert(#selection:Get() == 1, "Selection deduplication")
		store.Changed:Destroy()
	end, debug.traceback)
	fixture:Destroy()
	history.Entries, history.Index, history.Focused = savedEntries, savedIndex, savedFocused
	report.services.passed = success
	if not success then
		report.errors[#report.errors + 1] = serviceError
	end
end
local roots = {}
if current and current.Apps and current.Apps.Explorer then
	roots[1] = current.Apps.Explorer.GuiElems.TreeFrame
else
	pcall(function()
		roots[#roots + 1] = game:GetService("CoreGui")
	end)
	pcall(function()
		roots[#roots + 1] = game:GetService("Players").LocalPlayer.PlayerGui
	end)
end
local seen = {}
for _, root in ipairs(roots) do
	local found, items = pcall(root.GetDescendants, root)
	if found then
		for _, item in ipairs(items) do
			if item.Name == "Entry" and item:IsA("GuiObject") and item:FindFirstChild("Indent") and not seen[item] then
				seen[item] = true
				local row = {
					height = item.AbsoluteSize.Y,
					width = item.AbsoluteSize.X,
					x = item.AbsolutePosition.X,
					y = item.AbsolutePosition.Y,
				}
				local indent = item:FindFirstChild("Indent")
				if indent then
					row.indent = indent.Position.X.Offset
				end
				local insert = item:FindFirstChild("Insert")
				if insert then
					row.insertSize = { insert.AbsoluteSize.X, insert.AbsoluteSize.Y }
					local icon = insert:FindFirstChild("StudioIcon")
					if icon then
						row.insertIconSize = { icon.AbsoluteSize.X, icon.AbsoluteSize.Y }
					end
				end
				report.rows[#report.rows + 1] = row
			end
		end
	end
end
report.rowCount = #report.rows
report.ui = { passed = ok and current ~= nil, checks = {} }
local function check(name, callback)
	local success, value = pcall(callback)
	local passed = success and value == true
	report.ui.checks[#report.ui.checks + 1] =
		{ name = name, passed = passed, detail = not success and tostring(value) or nil }
	if not passed then
		report.ui.passed = false
	end
end
if current and current.Apps then
	local explorer = current.Apps.Explorer
	local viewport = explorer.GuiElems.TreeFrame
	local header = explorer.GuiElems.ToolBar
	check("Search field and settings are 20px", function()
		return header.SearchFrame.Size.Y.Offset == 20 and header.Options.Size.X.Offset == 20
	end)
	check("Search corner 6px and focus stroke 1.5px", function()
		return header.SearchFrame.Corner.CornerRadius.Offset == 6 and header.SearchFrame.Stroke.Thickness == 1.5
	end)
	check("Search history icon 16px", function()
		return header.SearchFrame.History.Size.X.Offset == 16
	end)
	check("Native scrollbar 6px without frame border", function()
		return viewport.ScrollBarThickness == 6 and viewport.BorderSizePixel == 0
	end)
	check("Rename outline 2px and corner 4px", function()
		local field = explorer.TreeRenderer.Layer.RenameBox
		return field.Border.Thickness == 2 and field.Corner.CornerRadius.Offset == 4
	end)
	check("Highlights fit beside the native scrollbar", function()
		for _, row in ipairs(explorer.TreeRenderer.Layer:GetChildren()) do
			if row.Name == "Entry" and row.Visible and row:FindFirstChild("Background") then
				local background = row.Background
				if math.abs(background.AbsolutePosition.X - viewport.AbsolutePosition.X) > 1.1 then
					return false
				end
				if
					background.AbsolutePosition.X + background.AbsoluteSize.X
					> viewport.AbsolutePosition.X + viewport.AbsoluteWindowSize.X + 0.1
				then
					return false
				end
				if row.Indent.ZIndex <= row.SelectionTop.ZIndex then
					return false
				end
			end
		end
		return true
	end)
	check("Properties row and column dividers exist", function()
		local template = current.Apps.Properties.EntryTemplate
		return template.RowDivider.Size.Y.Offset == 1 and template.ValueFrame.Line.Size.X.Offset == 1
	end)
	check("Properties uses the supplied reference surface", function()
		return current.Apps.Properties.GuiElems.PropsFrame.BackgroundColor3 == Color3.fromRGB(25, 26, 31)
	end)
end
if type(makefolder) == "function" then
	pcall(makefolder, "dex-explorer")
	pcall(makefolder, "dex-explorer/validation")
end
local json = http:JSONEncode(report)
if type(writefile) == "function" then
	writefile("dex-explorer/validation/latest.json", json)
end
print(
	"[Dex Explorer validation] "
		.. (ok and "Loaded" or "Failed")
		.. "; "
		.. string.format("%.3fs", report.loadSeconds)
		.. "; "
		.. report.rowCount
		.. " rows. Report: dex-explorer/validation/latest.json"
)
print(
	"[Dex Explorer UI audit] "
		.. (report.ui.passed and "Passed" or "Differences found")
		.. "; "
		.. #report.ui.checks
		.. " live geometry checks"
)
if problem then
	warn(problem)
end
return report

--!strict

local global = getgenv()
local report = { version = 1, started = os.time(), checks = {}, errors = {} }
local folder
local savedQuery
local function check(name, condition)
	report.checks[#report.checks + 1] = { name = name, passed = condition and true or false }
	assert(condition, name)
end
local ok, problem = xpcall(function()
	local old = global.DexPlus
	if old and old.Apps and old.Apps.Explorer then
		old.Apps.Explorer.SearchRevision = (old.Apps.Explorer.SearchRevision or 0) + 1
	end
	if old and old.Main then
		old.Main.Shutdown()
	end
	local bootstrap =
		assert(loadstring(readfile("dex-explorer/development/src/Runtime/Bootstrap.luau"), "@DexExplorer/IconValidation"))()
	bootstrap("local-development/", {
		Fetch = function(path)
			return readfile("dex-explorer/development/" .. path)
		end,
	})
	local runtime = assert(global.DexPlus)
	report.release = global.DexPlusRuntimeStats and global.DexPlusRuntimeStats.Release
	local explorer = runtime.Apps.Explorer
	savedQuery = explorer.Query or ""
	explorer.ClearSearch()
	folder = Instance.new("Folder")
	folder.Name = "DexIconTintValidation_" .. tostring(os.clock())
	folder.IconTint = Color3.fromRGB(255, 0, 0)
	folder.Parent = workspace
	explorer.SyncHistoryObject(folder)
	explorer.ViewNode(explorer.GetInferenceNodes()[folder])
	explorer.ForceUpdate()
	task.wait(0.25)
	local function icon()
		for _, row in ipairs(explorer.GuiElems.TreeFrame.ReactViewport:GetChildren()) do
			local indent = row:FindFirstChild("Indent")
			if indent and indent.EntryName.Text == folder.Name then
				return indent.Icon:FindFirstChild("StudioClassIcon")
			end
		end
	end
	local function near(a, b)
		return math.abs(a.R - b.R) < 0.002 and math.abs(a.G - b.G) < 0.002 and math.abs(a.B - b.B) < 0.002
	end
	local light = runtime.Settings.Theme.IconTheme == "Light"
	local saturation, value = light and 0.636364 or 0.492, light and 0.905882 or 0.980392
	local image = assert(icon(), "Folder row not mounted")
	check(
		"Tintable folder mask",
		image.Image == runtime.Main.GetStudioAsset("native/folder/tint/" .. (light and "Light" or "Dark"))
	)
	check("Initial red palette", near(image.ImageColor3, Color3.fromHSV(0, saturation, value)))
	folder.IconTint = Color3.fromRGB(0, 255, 0)
	task.wait(0.35)
	check(
		"Property change updates the existing row",
		near(assert(icon()).ImageColor3, Color3.fromHSV(1 / 3, saturation, value))
	)
	folder.IconTint = Color3.new(1, 1, 1)
	task.wait(0.35)
	check("Reset restores ordinary folder icon", assert(icon()).Image == runtime.Main.GetStudioAsset("class/Folder"))
	check("Reset clears the tint multiplier", near(assert(icon()).ImageColor3, Color3.new(1, 1, 1)))
end, debug.traceback)
if not ok then
	report.errors[#report.errors + 1] = tostring(problem)
end
if folder then
	pcall(function()
		folder:Destroy()
	end)
end
local runtime = global.DexPlus
if runtime and runtime.Apps and runtime.Apps.Explorer then
	pcall(function()
		if folder then
			runtime.Apps.Explorer.SyncHistoryObject(folder)
		end
		if savedQuery then
			runtime.Apps.Explorer.DoSearch(savedQuery)
		end
	end)
end
for _, path in ipairs({ "dex-explorer", "dex-explorer/validation" }) do
	pcall(makefolder, path)
end
writefile("dex-explorer/validation/icons.json", game:GetService("HttpService"):JSONEncode(report))
print(
	"[Dex Explorer] Icon validation: "
		.. (ok and "Passed" or "Differences found")
		.. "; saved dex-explorer/validation/icons.json"
)
if not ok then
	warn(problem)
end

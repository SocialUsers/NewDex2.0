--!strict

do
	local oldHSV = Color3.fromHSV
	local colorMT = {
		__eq = function(a, b)
			return a.R == b.R and a.G == b.G and a.B == b.B
		end,
	}
	Color3.fromHSV = function(h, s, v)
		local sector = math.floor(h * 6) % 6
		local f = h * 6 - math.floor(h * 6)
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		local channels = { { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } }
		local c = channels[sector + 1]
		return setmetatable({ R = c[1], G = c[2], B = c[3] }, colorMT)
	end
	local function hsv(h, s)
		return {
			ToHSV = function()
				return h, s, 1
			end,
		}
	end
	local folder = Instance.new("Folder", workspace)
	folder.Name = "IconTintAudit"
	folder.IconTint = hsv(0, 1)
	Explorer.SyncHistoryObject(folder)
	Explorer.ViewNode(nodes[folder])
	Explorer.ForceUpdate()
	local function row()
		for _, entry in ipairs(Explorer.GuiElems.TreeFrame.ReactViewport:GetChildren()) do
			if entry:FindFirstChild("Indent") and entry.Indent.EntryName.Text == folder.Name then
				return entry
			end
		end
		error("tinted folder row not visible")
	end
	local entry = row()
	local icon = entry.Indent.Icon.StudioClassIcon
	assert(
		icon.Image == Main.GetStudioAsset("native/folder/tint/Dark"),
		"saturated folders use Studio's tintable mask, not the normal yellow folder"
	)
	assert(
		math.abs(icon.ImageColor3.R - 0.980392) < 0.00001 and math.abs(icon.ImageColor3.G - 0.498039136) < 0.00001,
		"dark folder palette preserves hue with source saturation/value"
	)
	assert(
		not Explorer.UpdateRowIcon(entry, "Folder", 0, true, folder),
		"unchanged folder appearance retains the row paint cache"
	)
	local searches, oldSearch = 0, Explorer.DoSearch
	Explorer.DoSearch = function(...)
		searches += 1
		return oldSearch(...)
	end
	folder.IconTint = hsv(1 / 3, 1)
	game.ItemChanged:Fire(folder, "IconTint")
	flushTasks()
	icon = row().Indent.Icon.StudioClassIcon
	assert(
		icon.ImageColor3.G > 0.98 and icon.ImageColor3.R < 0.5 and searches == 0,
		"IconTint changes repaint immediately without restarting search"
	)
	folder.IconTint = hsv(0, 0)
	game.ItemChanged:Fire(folder, "IconTint")
	flushTasks()
	icon = row().Indent.Icon.StudioClassIcon
	assert(
		icon.Image == Main.GetStudioAsset("class/Folder") and icon.ImageColor3.R == 1 and icon.ImageColor3.G == 1,
		"resetting tint restores the original icon and white image multiplier"
	)
	local appearance = Apps.IconAppearance
	Settings.Theme.IconTheme = "Light"
	folder.IconTint = hsv(0, 1)
	local class, key, tint = appearance.Resolve(folder, "Folder")
	assert(
		key == "native/folder/tint/Light"
			and math.abs(tint.R - 0.905882) < 0.00001
			and math.abs(tint.G - 0.329411) < 0.00001,
		"light theme uses its own mask and source palette"
	)
	Settings.Theme.IconTheme = nil
	local scriptObject = Instance.new("Script")
	scriptObject.RunContext = Enum.RunContext.Client
	assert(appearance.Resolve(scriptObject, "Script") == "LocalScript", "client-context Scripts use LocalScript icons")
	scriptObject.RunContext = Enum.RunContext.Server
	assert(appearance.Resolve(scriptObject, "Script") == "Script", "server-context Scripts retain Script icons")
	local package = Instance.new("PackageLink")
	package.AutoUpdate = true
	local _, autoKey = appearance.Resolve(package, "PackageLink")
	assert(autoKey == "native/package/autoupdate", "automatic package updates use the shipped variant")
	package.AutoUpdate = false
	local _, normalKey = appearance.Resolve(package, "PackageLink")
	assert(normalKey == nil, "disabling auto-update restores the class icon")
	local locked = {
		IsA = function()
			return true
		end,
	}
	assert(appearance.Resolve(locked, "Folder") == "Folder", "unavailable IconTint falls back without an error")
	local starter = Instance.new("StarterGui")
	starter.ShowDevelopmentGui = false
	local gui = Instance.new("Frame", starter)
	gui.Visible = true
	assert(not Apps.ExplorerPolicy.IsEnabled(gui), "StarterGui development visibility dims descendants")
	starter.ShowDevelopmentGui = true
	assert(Apps.ExplorerPolicy.IsEnabled(gui), "enabling development visibility restores descendant state")
	Explorer.DoSearch = oldSearch
	folder.Parent = nil
	Explorer.SyncHistoryObject(folder)
	Explorer.CleanDeletedChildren()
	Explorer.ForceUpdate()
	Color3.fromHSV = oldHSV
	print(
		"PASS: rendered folder masks/palettes, live IconTint invalidation, reset, cached paints, RunContext, package variants and StarterGui state"
	)
end

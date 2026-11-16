--!strict

do
	local status = Apps.RowStatus
	local scans = 0
	local link = { ClassName = "PackageLink", ModifiedState = 1, HasNewVersion = false, AutoUpdate = false }
	local root = {
		FindFirstChildOfClass = function()
			scans += 1
			return link
		end,
	}
	link.Parent = root
	local key, text = status.Resolve(root, "Model")
	assert(
		key == "native/status/package/Dark/Modified_AutoupdateOff" and text ~= nil,
		"modified package uses original badge"
	)
	status.Resolve(root, "Model")
	assert(scans == 1, "package child lookup is cached across row renders")
	link.HasNewVersion = true
	status.Invalidate(link, "HasNewVersion")
	key = status.Resolve(root, "Model")
	assert(key == "native/status/package/Dark/UpdateAvailable_Modified", "link changes invalidate parent status")
	link.ModifiedState = 0
	status.Invalidate(link, "ModifiedState")
	assert(status.Resolve(root, "Model") == nil, "unavailable modified state omits badge")
	link.ModifiedState = 2
	link.HasNewVersion = false
	link.AutoUpdate = true
	status.Invalidate(link, "AutoUpdate")
	assert(
		status.Resolve(root, "Model") == "native/status/package/Dark/AutoupdateOn_Old",
		"unmodified auto-update state uses exact shipped asset"
	)
	link.Parent = nil
	root.FindFirstChildOfClass = function()
		return nil
	end
	status.Invalidate(link, "Parent")
	assert(status.Resolve(root, "Model") == nil, "removal invalidates previously cached parent")
	local unreadable = setmetatable({}, {
		__index = function()
			error("unavailable")
		end,
	})
	assert(status.Resolve(unreadable, "Folder") == nil, "unavailable client properties omit status")
	local oldTheme = Settings.Theme.IconTheme
	Settings.Theme.IconTheme = "Light"
	link.Parent = root
	root.FindFirstChildOfClass = function()
		return link
	end
	status.Invalidate(link, "Parent")
	assert(
		status.Resolve(root, "Model") == "native/status/package/Light/AutoupdateOn_Old",
		"theme changes resolve matching original badge"
	)
	local destination = {
		FindFirstChildOfClass = function()
			return link
		end,
	}
	assert(status.Resolve(destination, "Model") == nil, "destination root caches no package before the move")
	link.Parent = destination
	root.FindFirstChildOfClass = function()
		return nil
	end
	status.Invalidate(link, "Parent")
	assert(
		status.Resolve(root, "Model") == nil and status.Resolve(destination, "Model") ~= nil,
		"moves invalidate both old and new package roots"
	)
	Settings.Theme.IconTheme = oldTheme
	local savedGame, savedEnum = game, Enum
	local chat = { ClassName = "Chat", IsAutoMigrated = true }
	local textChat = { ClassName = "TextChatService", ChatVersion = "legacy" }
	local world = { AuthorityMode = "client" }
	game = {
		GetService = function(_, name)
			return ({ Chat = chat, TextChatService = textChat, Workspace = world })[name]
		end,
	}
	Enum = { ChatVersion = { TextChatService = "modern" }, AuthorityMode = { Server = "server" } }
	local warning, _, disabled = status.Resolve(chat, "Chat")
	assert(
		warning == "native/status/warning/Dark" and disabled == false,
		"readable legacy chat warns without dimming active Chat"
	)
	assert(status.Resolve(textChat, "TextChatService") ~= nil, "automatic chat migration warns on TextChatService")
	textChat.ChatVersion = "modern"
	status.Invalidate(textChat, "ChatVersion")
	local _, _, modernDisabled = status.Resolve(chat, "Chat")
	assert(
		modernDisabled == true and status.Resolve(textChat, "TextChatService") == nil,
		"cross-service invalidation updates Chat and clears migration warning"
	)
	local aurora = {}
	local _, _, auroraDisabled = status.Resolve(aurora, "AuroraScript")
	assert(auroraDisabled == true, "readable authority mismatch warns and dims AuroraScript")
	world.AuthorityMode = "server"
	status.Invalidate(world, "AuthorityMode")
	assert(status.Resolve(aurora, "AuroraScript") == nil, "authority mode changes clear cached Aurora warning")
	textChat.ChatVersion = nil
	chat.IsAutoMigrated = nil
	status.Invalidate(textChat, "ChatVersion")
	assert(
		status.Resolve(chat, "Chat") == nil and status.Resolve(textChat, "TextChatService") == nil,
		"unavailable chat state omits warnings"
	)
	world.AuthorityMode = nil
	status.Invalidate(world, "AuthorityMode")
	assert(status.Resolve(aurora, "AuroraScript") == nil, "unavailable authority state omits warning")
	game, Enum = savedGame, savedEnum
	local fixture = Instance.new("Model", workspace)
	fixture.Name = "PackageStatusAudit"
	local packageLink = Instance.new("PackageLink", fixture)
	packageLink.ModifiedState = 1
	packageLink.HasNewVersion = false
	packageLink.AutoUpdate = false
	Explorer.SyncHistoryObject(fixture)
	Explorer.ViewNode(nodes[fixture])
	Explorer.ForceUpdate()
	local function badge()
		for _, entry in ipairs(Explorer.TreeRenderer.Layer:GetChildren()) do
			if entry.Name == "Entry" and entry.Indent.EntryName.Text == fixture.Name then
				return entry.Indent.StatusBadge
			end
		end
		error("package fixture row not visible")
	end
	assert(
		badge().Visible and badge().Image == Main.GetStudioAsset("native/status/package/Dark/Modified_AutoupdateOff"),
		"real root row renders original package badge"
	)
	local searches, oldSearch = 0, Explorer.DoSearch
	Explorer.DoSearch = function(...)
		searches += 1
		return oldSearch(...)
	end
	packageLink.HasNewVersion = true
	game.ItemChanged:Fire(packageLink, "HasNewVersion")
	flushTasks()
	assert(
		badge().Image == Main.GetStudioAsset("native/status/package/Dark/UpdateAvailable_Modified") and searches == 0,
		"link property notification updates root badge without searching"
	)
	packageLink.Parent = nil
	game.ItemChanged:Fire(packageLink, "Parent")
	flushTasks()
	assert(not badge().Visible, "link removal clears rendered root badge")
	Explorer.DoSearch = oldSearch
	fixture.Parent = nil
	Explorer.SyncHistoryObject(fixture)
	Explorer.CleanDeletedChildren()
	Explorer.ForceUpdate()
	print("PASS: cached package badges, changes, removals, missing properties, themes and cross-service warnings")
end

--!strict

local actions = Apps.PluginActions
local explorerBind = assert(actions.ParseShortcut("shift + alt + F8"))
local editorBind = assert(actions.ParseShortcut("Alt + Ctrl + M"))
assert(explorerBind.Token == "Alt+Shift+F8" and editorBind.Token == "Ctrl+Alt+M")
assert(actions.ParseShortcut("Ctrl+Alt+6").Key == Enum.KeyCode.Six)
for _, invalid in ipairs({
	"Ctrl+C",
	"Ctrl+Alt+C",
	"Ctrl+Alt+L",
	"Alt+Shift+1",
	"Ctrl+Shift+Z",
	"Alt+Q",
	"Alt+Shift+F13",
	"Ctrl+Alt+Alt+M",
	"Ctrl+Alt++M",
	"Alt+Shift+",
	"Meta+Alt+Q",
	"Alt+Shift+F10",
	"Alt+Shift+L",
	"Alt+Shift+I",
}) do
	assert(not actions.ParseShortcut(invalid), invalid)
end

local part = Instance.new("Part")
local second = Instance.new("Folder")
local selection = { { Obj = part }, { Obj = second }, { Obj = game, Del = true } }
local function explorerContext()
	return actions.ExplorerContext(selection, second)
end
local viewer = {
	ActiveDocument = {},
	ActiveScript = Instance.new("ModuleScript"),
	GetSelectionState = function()
		return { First = 3, Last = 8, Selected = true }
	end,
	GetSelections = function()
		return { { First = 3, Last = 8 }, { First = 17, Last = 20 } }
	end,
}
local function editorContext()
	return actions.EditorContext(viewer, { Editable = false })
end
local bindings = {
	Explorer = {
		PluginID = "sample",
		ID = "tool",
		Name = "Inspect",
		Keybind = explorerBind,
		Shortcut = explorerBind.Token,
		Tooltip = "Inspect parts",
	},
	Editor = {
		PluginID = "sample",
		ID = "editor",
		Name = "Inspect selection",
		Keybind = editorBind,
		Shortcut = editorBind.Token,
	},
	Global = {
		PluginID = "sample",
		ID = "global",
		Name = "Global",
		Keybind = assert(actions.ParseShortcut("Ctrl+Alt+B")),
	},
}
local allowed, popup = true, false
local fired = {}
Apps.ContextMenu = {
	IsAnyShown = function()
		return popup
	end,
}
Apps.PluginRuntime = {
	GetActions = function(surface)
		return { bindings[surface] }
	end,
	IsActionAvailable = function()
		return allowed
	end,
	InvokeAction = function(pluginId, id, context, expected)
		assert(pluginId == "sample" and id == expected.ID)
		if expected == bindings[context.Surface] then
			fired[#fired + 1] = context
		end
	end,
}

local items = {}
local menu = {
	AddDivider = function()
		items[#items + 1] = "divider"
	end,
	Add = function(_, item)
		items[#items + 1] = item
	end,
}
actions.AddMenu(menu, "Explorer", explorerContext)
assert(items[1] == "divider" and items[2].Name == "Plugins")
local installed = items[2].Submenu[1]
assert(installed.Name == "Inspect" and installed.Description == "Inspect parts")
selection[1] = { Obj = game }
installed.OnClick()
assert(fired[1].Selection[1] == part and fired[1].Target == second and #fired[1].Selection == 2)
assert(table.isfrozen(fired[1]) and table.isfrozen(fired[1].Selection))
bindings.Explorer = table.clone(bindings.Explorer)
installed.OnClick()
assert(#fired == 1, "stale menu items cannot invoke the replacement")

table.clear(items)
allowed = false
actions.AddMenu(menu, "Editor", editorContext)
assert(#items == 0)
allowed = true
actions.AddMenu(menu, "Editor", editorContext)
items[2].Submenu[1].OnClick()
assert(fired[2].Editor == viewer and fired[2].Script == viewer.ActiveScript and not fired[2].Editable)
assert(fired[2].Selection.First == 3 and fired[2].Selections[2].Last == 20 and table.isfrozen(fired[2].Selections[2]))

local user = service.UserInputService
local function keyboard(key)
	return { KeyCode = key, UserInputType = Enum.UserInputType.Keyboard }
end
keys.LeftAlt, keys.LeftShift = true, true
assert(actions.HandleShortcut("Explorer", keyboard(Enum.KeyCode.F8), explorerContext))
flushTasks()
assert(#fired == 3 and fired[3].Surface == "Explorer")
keys.LeftControl = true
assert(not actions.HandleShortcut("Explorer", keyboard(Enum.KeyCode.F8), explorerContext))
keys.LeftShift = false
assert(actions.HandleShortcut("Editor", keyboard(Enum.KeyCode.M), editorContext))
viewer.ActiveDocument = {}
flushTasks()
assert(#fired == 3, "deferred action skips a document that changed")
assert(actions.HandleShortcut("Editor", keyboard(Enum.KeyCode.M), editorContext))
flushTasks()
assert(#fired == 4)

actions.Init()
actions.Init()
local input = keyboard(Enum.KeyCode.B)
user.Focus = {}
user.InputBegan:Fire(input, false)
user.Focus = nil
user.InputBegan:Fire(input, true)
popup = true
user.InputBegan:Fire(input, false)
popup = false
keys.LeftAlt, keys.RightAlt = false, true
user.InputBegan:Fire(input, false)
keys.LeftAlt, keys.RightAlt = true, false
keys.LeftMeta = true
user.InputBegan:Fire(input, false)
keys.LeftMeta = false
user.InputBegan:Fire(input, false)
flushTasks()
assert(#fired == 5 and fired[5].Surface == "Global")
print("PASS: plugin actions, context snapshots, stale menu gating, exact shortcuts, focus and reserved keys")

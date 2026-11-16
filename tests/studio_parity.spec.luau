--!strict

-- Exercises the real Explorer interaction code against the host model.
local policy = Apps.ExplorerPolicy
assert(policy.Tokens.IndentWidth == 12 and policy.Tokens.HeaderHeight == 29, "measured Studio layout constants")
local a, b, c, d = {}, {}, {}, {}
local ordered = { a, b, c, d }
assert(
	policy.Navigate(ordered, nil, 1) == a and policy.Navigate(ordered, nil, -1) == d,
	"empty selection starts at directional endpoint"
)
assert(policy.Navigate(ordered, a, 1, { [c] = true }) == c, "navigation skips search context")
local range = policy.Range(ordered, b, d)
assert(#range == 3 and range[1] == b and range[3] == d, "shift range is contiguous")
range = policy.Range(ordered, b, c)
assert(#range == 2 and range[2] == c, "reversing shift shrinks the range")
range = policy.Range(ordered, a, d, { [b] = true, [d] = true })
assert(#range == 2 and range[1] == b and range[2] == d, "search selection excludes ancestor context")
range = policy.Range(ordered, a, b, nil, { d })
assert(#range == 3 and range[1] == d, "additive range preserves existing selection")

Explorer.ClearSearch()
Explorer.ForceUpdate()
Explorer.Expanded[nodes[workspace]] = true
Explorer.Expanded[nodes[folder]] = true
Explorer.Expanded[nodes[model]] = true
Explorer.ForceUpdate()
local nameBefore = model.Name
Explorer.SetRenamingNode(nodes[model])
local rename = Explorer.Window.GuiElems.Content.List.ReactViewport:FindFirstChild("RenameBox")
rename.Text = "Cancelled rename"
rename.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape })
assert(model.Name == nameBefore and not rename.Visible, "Escape cancels rename without changing the object")
Explorer.SetRenamingNode(nodes[model])
rename.Text = ""
rename:ReleaseFocus()
assert(model.Name == nameBefore, "blank rename does not silently erase instance name")
Explorer.SetRenamingNode(nodes[model])
rename.Text = "Programmatic focus loss"
rename.FocusLost:Fire(false, nil)
assert(model.Name == nameBefore and not rename.Visible, "focus loss without input cancels like Studio")
Explorer.SetRenamingNode(nodes[model])
rename.Text = "Escape focus loss"
rename.FocusLost:Fire(false, { KeyCode = Enum.KeyCode.Escape })
assert(
	model.Name == nameBefore and not rename.Visible,
	"Escape focus loss cancels without relying on InputBegan ordering"
)
Explorer.SetRenamingNode(nodes[model])
rename.Text = "Committed by outside click"
rename.FocusLost:Fire(false, { UserInputType = Enum.UserInputType.MouseButton1 })
assert(model.Name == "Committed by outside click", "ordinary input focus loss commits")
rename:ReleaseFocus()
model.Name = nameBefore

do
	local oldHit, oldSetting = Lib.CheckMouseInGui, Settings.Explorer.ClickToRename
	local oldX, oldY = Main.Mouse.X, Main.Mouse.Y
	local oldRename = Explorer.SetRenamingNode
	local oldSelection = table.clone(Explorer.Selection.List)
	local called = 0
	Explorer.SetRenamingNode = function(node)
		assert(node == nodes[model])
		called += 1
	end
	Settings.Explorer.ClickToRename = true
	Explorer.Selection:Set(nodes[model])
	Explorer.ViewNode(nodes[model])
	Explorer.Refresh()
	local row
	for _, child in ipairs(Explorer.TreeRenderer.Layer:GetChildren()) do
		if child.Name == "Entry" and child.Indent.EntryName.Text == nameBefore then
			row = child
			break
		end
	end
	assert(row, "rename fixture row is visible")
	local label = row.Indent.EntryName
	local sys = Explorer.ClickSystem
	Main.Mouse.X, Main.Mouse.Y = label.AbsolutePosition.X + 1, label.AbsolutePosition.Y + 1
	local function click()
		Explorer.Window.OnDeactivate:Fire()
		sys.OnDown:Fire(row, 1, 1)
		sys.OnRelease:Fire(row, 1, 1)
	end
	Lib.CheckMouseInGui = function()
		return false
	end
	click()
	flushTasks()
	assert(called == 0 and Explorer.Selection.Map[nodes[model]], "full row selects without renaming outside label")
	Lib.CheckMouseInGui = function(gui)
		return gui == label
	end
	click()
	flushTasks()
	assert(called == 1, "label click still starts delayed rename")
	local oldIndex = Explorer.Index
	click()
	Explorer.Index += 1
	flushTasks()
	assert(called == 1, "recycled row cannot rename stale node after delay")
	Explorer.Index = oldIndex
	Lib.CheckMouseInGui, Settings.Explorer.ClickToRename = oldHit, oldSetting
	Explorer.SetRenamingNode = oldRename
	Main.Mouse.X, Main.Mouse.Y = oldX, oldY
	Explorer.Selection:SetTable(oldSelection)
	Explorer.Refresh()
end

Explorer.Selection:Set(nodes[part])
Explorer.Selection.Piviot = nodes[part]
Explorer.KeyboardFocusNode = nil
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector2.new(100, 100) },
	false
)
keys.LeftShift = true
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Up },
	false
)
assert(#Explorer.Selection.List == 2, "Shift+Up extends from fixed anchor")
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
	false
)
assert(
	#Explorer.Selection.List == 1 and Explorer.Selection.List[1] == nodes[part],
	"Shift+Down contracts selection back to anchor"
)
keys.LeftShift = false

local props = Explorer.RightClickContext.Registered
assert(
	props.GROUP.Name == "Group as Model" and props.GROUP_FOLDER.Name == "Group as Folder",
	"Studio grouping actions are distinct"
)
local destination = Instance.new("Folder", workspace)
destination.Name = "StudioParity"
local left = Instance.new("Folder", destination)
left.Name = "Left"
local right = Instance.new("Folder", destination)
right.Name = "Right"
Explorer.SyncHistoryObject(destination)
Explorer.Selection:SetTable({ nodes[left], nodes[right] })
keys.LeftControl = true
keys.LeftAlt = true
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.G },
	false
)
keys.LeftControl = false
keys.LeftAlt = false
local grouped = Explorer.Selection.List[1].Obj
assert(
	grouped:IsA("Folder") and left.Parent == grouped and right.Parent == grouped,
	"Ctrl+Alt+G groups actual instances into Folder"
)
assert(
	Apps.History.Undo() and left.Parent == destination and right.Parent == destination,
	"group as Folder is one reversible history action"
)

Explorer.Expanded[nodes[folder]] = false
Explorer.ForceUpdate()
Explorer.Selection:Set(nodes[folder])
Explorer.KeyboardFocusNode = nil
keys.LeftShift = true
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Right },
	false
)
assert(Explorer.Expanded[nodes[folder]] and Explorer.Expanded[nodes[model]], "Shift+Right expands full subtree")
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Right },
	false
)
assert(
	Explorer.Expanded[nodes[folder]] and Explorer.Selection.List[1] == nodes[folder][1],
	"Shift+Right on an expanded node moves to first child without toggling parent closed"
)
Explorer.Selection:Set(nodes[folder])
Explorer.KeyboardFocusNode = nil
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Left },
	false
)
keys.LeftShift = false
assert(
	not Explorer.Expanded[nodes[folder]] and not Explorer.Expanded[nodes[model]],
	"Shift+Left collapses full subtree"
)
Explorer.Selection:Clear()
Explorer.KeyboardFocusNode = nil
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
	false
)
assert(Explorer.Selection.List[1] == nodes[workspace], "Down from empty selection starts at the first row")
print(
	"PASS: Studio layout rules, filtered navigation, reversible range selection, rename cancellation and context-menu grouping"
)

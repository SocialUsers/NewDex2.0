--!strict

local oldWindow = Lib.Window.new
Lib.Window.new = function()
	local window = oldWindow()
	local elements = window.GuiElems
	elements.Outlines = Instance.new("ImageLabel", elements.Main)
	elements.TopBar = Instance.new("TextButton", elements.Main)
	elements.Title = Instance.new("TextLabel", elements.TopBar)
	for _, name in ipairs({ "Close", "Minimize" }) do
		local button = Instance.new("TextButton", elements.TopBar)
		button.Name = name
		Instance.new("ImageLabel", button).Name = "ImageLabel"
		elements[name] = button
	end
	function window:SetTitle(title)
		elements.Title.Text = title
	end
	function window:Resize(x, y)
		self.Size = { x, y }
		self.GuiElems.Main.Size = UDim2.fromOffset(x, y)
		self.GuiElems.Content:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	end
	function window:Show()
		self.Visible = true
	end
	function window:Hide()
		self.Visible = false
	end
	function window:IsContentVisible()
		return self.Visible == true
	end
	function window:SetResizeHandleStyle(style)
		self.Style = style
	end
	return window
end
Lib.StudioText = function() end
Lib.StudioTooltip = function() end
local newMenu = Lib.ContextMenu.new
function Lib.ContextMenu.new()
	local menu = newMenu()
	function menu:Destroy()
		self:Hide()
		table.clear(self.Items)
	end
	return menu
end
task.spawn = function(fn)
	return fn()
end
Apps.BridgeClient = Client
local app = Apps.AIBridge
assert(not app.Window and not app.Client, "bridge stays lazy until opened")
app.Open()
app.SetTab("Commands")
assert(#app.Client.CommandCatalog > 300 and app.Commands.Rows[1].Toggle.On)
assert(app.Pages.Commands:FindFirstChild("CommandCount").Text:find("Offline", 1, true))
app.Client.State = "Connected"
app.Open()
assert(app.Pages.Commands:FindFirstChild("CommandCount").Text:find("Restart MCP client", 1, true))
app.Client.State = "Disconnected"
app.SetTab("Connection")
app.Open()
local window = app.Window
local connection = app.Pages.Connection
assert(window.Visible and window.Style == "Dock" and app.Client.State == "Disconnected")
assert(not connection:FindFirstChild("ConnectionCard"), "connection uses a flat layout rather than nested panels")
assert(connection.Position.X.Offset == 138 and not connection:FindFirstChild("Footer"))
local strip = connection.StatusStrip
assert(strip.ConnectionHelp.HelpIcon.Image == Main.GetStudioAsset("bridge/external-v2"))
assert(window.GuiElems.Title.Text == "Dex MCP")
assert(not window.GuiElems.TopBar:FindFirstChild("BridgeBrand"))
local statusControl = strip.SessionStatus
local dot = statusControl:FindFirstChild("StatusDot")
local chevron = statusControl:FindFirstChild("Chevron")
assert(not statusControl.Active and not statusControl:FindFirstChild("Chevron").Visible)
assert(
	dot:FindFirstChildOfClass("UICorner").CornerRadius.Scale == 1 and dot.BackgroundColor3.R > dot.BackgroundColor3.G,
	"disconnected indicator is a red circle"
)
assert(
	connection.ClassName == "ScrollingFrame" and app.Pages.Setup.ClassName == "ScrollingFrame",
	"short windows retain all controls by scrolling"
)
app.Client.Error = nil
app.Client.Supported = function()
	return true
end
app.Open()
assert(app.ConnectControl.Gui.Text == "Paste & Connect" and app.ConnectControl.Enabled)
clipboardText = "not a pairing code"
app.ConnectControl.Gui.Activated:Fire()
local inlineError = connection:FindFirstChild("ConnectionError")
assert(inlineError.Visible and inlineError:FindFirstChild("Error").Text == "No pairing code on the clipboard.")
assert(inlineError.AbsolutePosition.Y >= app.PairingCode.AbsolutePosition.Y + app.PairingCode.AbsoluteSize.Y)
assert(app.PairingCode.Text == "")
local access = connection:FindFirstChild("Permissions")
assert(
	access.Position.X.Offset == app.PairingCode.Position.X.Offset and access.Size.X.Offset == -32,
	"content shares one inset grid"
)
assert(access.Position.Y.Offset > app.PairingCode.Position.Y.Offset + app.PairingCode.Size.Y.Offset + 50)
for _, name in ipairs({ "Inspect", "Edit objects", "Run code" }) do
	local row = access:FindFirstChild(name)
	assert(row:FindFirstChild("Title").Text == name)
	assert(row.Size.Y.Offset == 36)
end
local edit = access:FindFirstChild("Edit objects"):FindFirstChild("edit")
assert(edit.Position.X.Scale == access.ValueDivider.Position.X.Scale and edit.Position.X.Offset == 16)
local track = edit:FindFirstChild("Track")
local switchOffColor = track.BackgroundColor3
local thumb = track:FindFirstChild("Thumb")
assert(
	track and thumb and thumb.Position.X.Offset == 2 and edit.Size.X.Offset == 32,
	"old layout keeps the new permission switches"
)
edit.MouseEnter:Fire()
edit.MouseButton1Down:Fire()
edit.MouseLeave:Fire()
assert(
	thumb.BackgroundTransparency == 0 and track.BackgroundColor3 == switchOffColor,
	"toggle hover/pressed feedback clears on pointer exit"
)
assert(track:FindFirstChildOfClass("UICorner").CornerRadius.Offset == 10, "toggle track keeps its rounded pill shape")
edit.Activated:Fire()
assert(
	thumb.Position.X.Offset == 14 and app.Client.Grants.edit,
	"permissions still use real BridgeClient grant changes"
)
assert(connection:FindFirstChild("AccessNote").Text == "Object editing enabled")
edit.Activated:Fire()
assert(thumb.Position.X.Offset == 2 and not app.Client.Grants.edit)
app.PairingCode.Text = "incomplete"
app.PairingCode:GetPropertyChangedSignal("Text"):Fire()
assert(not app.ConnectControl.Enabled and not inlineError.Visible)
app.PairingCode.Text = "37429." .. string.rep("a", 32)
app.PairingCode:GetPropertyChangedSignal("Text"):Fire()
assert(app.ConnectControl.Enabled and connection:FindFirstChild("Session").Text == "Ready to connect")
local fieldIdleOutline = app.PairingCode:FindFirstChildOfClass("UIStroke").Color
app.PairingCode.Focused:Fire()
assert(app.PairingCode:FindFirstChildOfClass("UIStroke").Color == Settings.Theme.Focus)
app.PairingCode.FocusLost:Fire(false)
assert(app.PairingCode:FindFirstChildOfClass("UIStroke").Color == fieldIdleOutline)
app.Client.State = "Connected"
app.Client.SessionId = "fixture-session"
app.Open()
assert(dot.BackgroundColor3.G > dot.BackgroundColor3.R and not app.PairingCode.Visible)
assert(statusControl.Active and not app.PauseControl.Gui.Visible and not app.ConnectControl.Gui.Visible)
assert(chevron.Image == Main.GetStudioAsset("native/editor/submenu") and chevron.Rotation == 0)
assert(chevron.Position.X.Offset - app.StateLabel.Position.X.Offset - app.StateLabel.TextBounds.X == 5)
statusControl.Activated:Fire()
assert(app.PauseControl.Gui.Visible and app.ConnectControl.Gui.Visible)
assert(chevron.Rotation == 90)
assert(app.ConnectControl.Gui.Position.Y.Offset == app.PauseControl.Gui.Position.Y.Offset)
assert(
	app.ConnectControl.Gui.Position.X.Offset
			- app.PauseControl.Gui.Position.X.Offset
			- app.PauseControl.Gui.Size.X.Offset
		== 8
)
assert(not connection:FindFirstChild("PairingLabel").Visible)
assert(app.ConnectControl.Gui.Text == "Disconnect" and app.ConnectControl.Kind == "secondary")
app.PauseControl.Gui.Activated:Fire()
assert(app.Client.Paused and app.PauseControl.Gui.Text == "Resume" and app.StateLabel.Text == "Paused")
app.PauseControl.Gui.Activated:Fire()
assert(not app.Client.Paused)
app.Client.ActiveCommand = "dex_find_references"
app.Open()
assert(
	connection:FindFirstChild("Summary").Text == "Running find references…",
	"active commands replace generic connection copy"
)
assert(app.StateLabel.Text == "Busy")
statusControl.Activated:Fire()
assert(not app.PauseControl.Gui.Visible and not app.ConnectControl.Gui.Visible)
app.Client.State = "Reconnecting"
app.Open()
assert(not app.PauseControl.Gui.Visible and app.ConnectControl.Enabled)
assert(dot.BackgroundColor3.R > dot.BackgroundColor3.B and dot.BackgroundColor3.G > dot.BackgroundColor3.B)
app.Client.Error = "Dex MCP disconnected. Reconnecting"
app.Open()
assert(
	inlineError.Visible and inlineError.AbsolutePosition.Y + inlineError.AbsoluteSize.Y < access.AbsolutePosition.Y,
	"inline errors reserve space instead of overlapping access controls"
)
app.Client.Error = nil
app.Client.ActiveCommand = nil
app.ConnectControl.Gui.Activated:Fire()
assert(app.StateLabel.Text == "Disconnected" and app.PairingCode.Visible)
app.Open()
assert(access.Position.Y.Offset == 165 and not inlineError.Visible)
local setup = app.Pages.Setup
assert(not setup:FindFirstChild("Privacy") and not setup:FindFirstChild("SetupSummary"))
for index = 1, 3 do
	local action = setup:FindFirstChild("StepAction" .. index)
	assert(action:FindFirstChildOfClass("UIStroke").Enabled)
	local marker = setup:FindFirstChild("Step" .. index)
	assert(marker.BackgroundTransparency == 1 and marker:FindFirstChildOfClass("UIStroke"))
	assert(marker.Number.TextXAlignment == Enum.TextXAlignment.Center)
	assert(marker.Number.TextYAlignment == Enum.TextYAlignment.Center)
	assert(
		action.BackgroundTransparency == 0
			and action.Position.X.Offset == setup:FindFirstChild("StepTitle" .. index).Position.X.Offset,
		"setup actions are filled and align with text"
	)
end
setup:FindFirstChild("StepAction2").Activated:Fire()
assert(copiedText:find("dex_create_pairing", 1, true) and setup:FindFirstChild("StepAction2").Text == "Copied")
setup:FindFirstChild("StepAction2").Activated:Fire()
flushTasks()
assert(
	setup:FindFirstChild("StepAction2").Text == "Copy request",
	"repeated copy feedback returns to the original label"
)
strip.ConnectionHelp.Activated:Fire()
assert(app.ActiveTab == "Setup")
setup:FindFirstChild("StepAction3").Activated:Fire()
assert(app.ActiveTab == "Connection")
app.SetTab("Activity")
local entries = {
	{
		Name = "dex_get_tree",
		Ok = true,
		Duration = 0.012,
		TimeLabel = "12:34:56",
		RequestText = "{rootId = part1}",
		ResultText = "{children = 3}",
	},
	{ Name = "dex_set_properties", Ok = false, Duration = 0.004, Error = "Edit access denied" },
}
app.Client.Recent = entries
app.Activity:Update(entries)
assert(#app.Activity.Rows == 2 and app.Activity.Rows[1].Name.Text == "Set properties", "newest command appears first")
assert(
	app.Activity.Rows[1].Gui.Size.Y.Offset == 22 and app.Activity.Rows[1].Result.Position.X.Scale == 0.43,
	"activity aligns result and time in table columns"
)
app.Activity.Rows[1].Gui.Activated:Fire()
assert(app.Activity.Details.Visible)
assert(app.Activity.Details:FindFirstChild("DetailBody"):FindFirstChild("Explanation").Text == "Edit access denied")
app.Activity.CopyDetails.Activated:Fire()
assert(copiedText:find("Edit access denied", 1, true), "failure details can be copied")
app.Activity.Rows[1].Gui.MouseButton1Up:Fire()
assert(app.Activity.Rows[1].Gui.BackgroundTransparency == 0, "selected row retains its background after mouse up")
app.Activity.CloseDetails.Activated:Fire()
assert(not app.Activity.Details.Visible)
app.Activity.Rows[2].Gui.Activated:Fire()
local detailText = app.Activity.Details:FindFirstChild("DetailBody"):FindFirstChild("Explanation").Text
assert(
	detailText:find("rootId = part1", 1, true) and detailText:find("children = 3", 1, true),
	"inspection includes arguments and actual returned data"
)
app.Activity.CopyDetails.Activated:Fire()
assert(copiedText:find("children = 3", 1, true), "copy includes full recorded details")
app.Activity.CloseDetails.Activated:Fire()
app.Activity.ResultFilter.Activated:Fire()
app.Activity.ResultMenu.Items[3].OnClick()
assert(app.Activity.Rows[1].Result.Text == "Failed" and not app.Activity.Rows[2].Gui.Visible)
app.Activity.ResultFilter.Activated:Fire()
app.Activity.ResultMenu.Items[2].OnClick()
assert(app.Activity.Rows[1].Result.Text == "Completed" and not app.Activity.Rows[2].Gui.Visible)
app.Activity.ResultFilter.Activated:Fire()
app.Activity.ResultMenu.Items[1].OnClick()
assert(app.Activity.Rows[2].Gui.Visible)
app.Activity.Filter.Text = "denied"
app.Activity.Filter:GetPropertyChangedSignal("Text"):Fire()
assert(not app.Activity.Rows[2].Gui.Visible)
assert(app.Activity.Clear.Active and app.Activity.Clear.Parent == app.Activity.Gui)
app.Activity.Clear.Activated:Fire()
assert(#app.Client.Recent == 0 and not app.Activity.Clear.Active)
assert(not app.Activity.Rows[1].Gui.Visible and not app.Activity.Details.Visible)
app.Activity.Filter.Text = ""
app.Activity.Filter:GetPropertyChangedSignal("Text"):Fire()
local large = {}
for i = 1, 200 do
	large[i] = { Name = "dex_get_tree", Ok = true, Duration = 0.01, CommandId = tostring(i) }
end
app.Client.Recent = large
app.Activity:Update(large)
assert(
	#app.Activity.Rows <= math.ceil(app.Activity.List.AbsoluteSize.Y / 22) + 1,
	"activity mounts only the visible command rows"
)
assert(app.Activity.List.CanvasSize.Y.Offset == 4400, "virtual activity retains all 200 commands")
app.Activity.List.CanvasPosition = Vector2.new(0, 3520)
app.Activity.List:GetPropertyChangedSignal("CanvasPosition"):Fire()
assert(app.Activity.Rows[1].Entry == large[40], "activity scrolling reveals the correct older command")
app.Activity.Rows[1].Gui.Activated:Fire()
assert(app.Activity.Details.Visible, "recycled command rows retain inspection")
app.Activity.CloseDetails.Activated:Fire()
app.Client:ClearRecent()
app.Client.CommandCatalog = {
	{ name = "dex_get_selection", description = "Read the Explorer selection." },
	{ name = "dex_tool_plan", description = "Suggest steps for a goal." },
}
app.SetTab("Commands")
local commandList = app.Commands
assert(app.Pages.Commands.CommandFooter and app.Pages.Commands.CommandCount.Position.Y.Scale == 1)
assert(commandList.Rows[1].Toggle.On and commandList.Rows[2].Toggle.On)
commandList.Query.Text = "selection"
commandList.Query:GetPropertyChangedSignal("Text"):Fire()
assert(commandList.Rows[1].Item.name == "dex_get_selection" and not commandList.Rows[2].Gui.Visible)
commandList.Rows[1].Toggle.Gui.Activated:Fire()
assert(Settings.BridgeDisabledCommands.dex_get_selection and not commandList.Rows[1].Toggle.On)
commandList.Filter.Activated:Fire()
commandList.FilterMenu.Items[2].OnClick()
assert(commandList.Rows[1].Item.name == "dex_get_selection")
commandList.EnableAll.MouseEnter:Fire()
assert(commandList.EnableAll.BackgroundTransparency == 1)
commandList.EnableAll.MouseButton1Down:Fire()
assert(commandList.EnableAll.BackgroundTransparency == 1)
commandList.EnableAll.Activated:Fire()
assert(next(Settings.BridgeDisabledCommands) == nil and not commandList.Rows[1].Gui.Visible)
commandList.Filter.Activated:Fire()
assert(commandList.FilterMenu.Shown)
app.SetTab("Activity")
assert(not commandList.FilterMenu.Shown, "changing tabs closes the filter menu")
local live = { Name = "dex_tool_plan", Status = "running", RequestText = '{"goal":"inspect"}' }
app.Activity:Update({ live }, 1)
app.Activity.Rows[1].Gui.Activated:Fire()
app.Activity.Details:FindFirstChild("Result").Activated:Fire()
local explanation = app.Activity.Details:FindFirstChild("DetailBody"):FindFirstChild("Explanation")
assert(explanation.Text == "Running…")
live.Status = "completed"
live.ResultText = '{"steps":[]}'
app.Activity:Update({ live }, 2)
assert(explanation.Text == live.ResultText and app.Activity.Rows[1].Result.Text == "Completed")
app.Activity.CloseDetails.Activated:Fire()
local tabBar = window.GuiElems.Content:FindFirstChild("Tabs")
assert(not tabBar:FindFirstChild("ClearActivity"))
for _, size in ipairs({ { 280, 360 }, { 340, 360 }, { 440, 360 }, { 460, 360 }, { 520, 460 }, { 720, 540 } }) do
	window:Resize(size[1], size[2])
	local compact = size[1] < 460
	local nextEdge = compact and tabBar.AbsolutePosition.X or tabBar.AbsolutePosition.Y
	for _, name in ipairs({ "Connection", "Commands", "Activity", "Setup" }) do
		local button = tabBar:FindFirstChild(name)
		assert(
			button.Icon.Visible ~= compact
				and button.Icon.Image
					== Main.GetStudioAsset("bridge/" .. (name == "Connection" and "connection-v2" or name:lower()))
		)
		local start = compact and button.AbsolutePosition.X or button.AbsolutePosition.Y
		assert(start >= nextEdge - 1, "navigation has separate hit areas")
		nextEdge = start + (compact and button.AbsoluteSize.X or button.AbsoluteSize.Y)
	end
	assert(
		nextEdge
			<= (
				compact and tabBar.AbsolutePosition.X + tabBar.AbsoluteSize.X
				or tabBar.AbsolutePosition.Y + tabBar.AbsoluteSize.Y
			),
		"all navigation items fit"
	)
	local clear = app.Activity.Clear
	local search = app.Activity.Filter
	assert(search.AbsolutePosition.X + search.AbsoluteSize.X <= clear.AbsolutePosition.X)
	assert(app.Activity.ResultFilter.AbsolutePosition.Y > clear.AbsolutePosition.Y)
	assert(
		app.ConnectControl.Gui.AbsolutePosition.X + app.ConnectControl.Gui.AbsoluteSize.X
			<= connection.AbsolutePosition.X + connection.AbsoluteSize.X - 16,
		"connect stays inside at minimum and expanded widths"
	)
	assert(
		edit.AbsolutePosition.X + edit.AbsoluteSize.X <= connection.AbsolutePosition.X + connection.AbsoluteSize.X - 16
	)
	assert(app.Activity.List.AbsoluteSize.Y > 0, "activity retains a viewport at minimum height")
end
app.Hide()
assert(not window.Visible)
app.Open()
assert(app.Window == window and window.Visible)
local connectMethod = app.Client.Connect
local requestedGrants
local attemptedCode
app.Client.Connect = function(self, code, grants)
	attemptedCode = code
	requestedGrants = table.clone(grants)
	self.Grants = table.clone(grants)
	return true
end
local fixtureCode = "37429." .. string.rep("a", 32)
app.PairingCode.Text = ""
clipboardText = "  " .. fixtureCode .. " \n"
app.PairingCode:GetPropertyChangedSignal("Text"):Fire()
app.ConnectControl.Gui.Activated:Fire()
assert(attemptedCode == fixtureCode and not requestedGrants.edit and not requestedGrants.execute)
app.ConnectWithCode(fixtureCode, { edit = false, execute = true })
assert(
	requestedGrants.inspect and requestedGrants.execute and not requestedGrants.edit,
	"programmatic reconnect uses explicit existing grants"
)
assert(
	access
		:FindFirstChild("Run code")
		:FindFirstChild("execute")
		:FindFirstChild("Track")
		:FindFirstChild("Thumb").Position.X.Offset == 14,
	"reconnected grants stay visible in the normal permission controls"
)
app.Client.Connect = connectMethod
Main.Shutdown()
assert(app.Client.Destroyed, "shutdown owns transport and UI lifetime")
print(
	"PASS: bridge composed views, shared control states, flat layout, grants/pause, pairing feedback, readable activity/details and responsive bounds"
)

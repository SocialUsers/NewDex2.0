--!strict

do
	local previousNew = Lib.Window.new
	Lib.Window.new = function()
		local w = previousNew()
		local setTitle = w.SetTitle
		w.SetTitle = function(self, text)
			self.TestTitle = text
			return setTitle(self, text)
		end
		w.SetResizeHandleStyle = function(self, style)
			self.TestResizeStyle = style
		end
		w.Resize = w.Resize or function() end
		w.Show = w.Show or function()
			w.OnActivate:Fire()
		end
		w.Hide = w.Hide or function()
			w.OnDeactivate:Fire()
		end
		local show, hide = w.Show, w.Hide
		local visible = false
		w.Show = function(...)
			visible = true
			return show(...)
		end
		w.Hide = function(...)
			visible = false
			return hide(...)
		end
		w.IsVisible = function()
			return visible
		end
		return w
	end
	assert(Apps.Reconstructor.Window == nil, "inferred UI is lazy")
	Apps.Reconstructor.Open()
	assert(
		Apps.Reconstructor.Window.TestTitle == "Reconstructor" and Apps.Reconstructor.Window.TestResizeStyle == "Dock",
		"Reconstructor uses the shared title and resize style"
	)
	local session = Apps.Reconstructor.Session
	assert(session and not session.Running and not session.ProbePending, "opening UI starts no scan or probe")
	session:Import("local ss = game.ServerStorage\nrequire(ss.Modules.Inventory)", "UI fixture")
	flushTasks()
	local content = Apps.Reconstructor.Window.GuiElems.Content
	local frame = content:FindFirstChild("InferredTree")
	assert(frame and frame.BorderSizePixel == 0 and frame.ScrollBarThickness == 6)
	local ui = Apps.Reconstructor.GuiElems
	assert(
		not ui.Details.Visible and frame.Size.Y.Offset == -54 and not ui.TextImport.Visible,
		"tree gets the window until details or import are requested"
	)
	for _, widget in ipairs(content:GetDescendants()) do
		assert(
			widget.Name ~= "Probe once" and widget.Name ~= "Use selected remote",
			"legacy remote controls do not occupy the primary UI"
		)
	end
	local viewport = frame:FindFirstChild("ReactViewport")
	assert(viewport and #viewport:GetDescendants() > 0, "inference uses shared mounted React Explorer rows")
	local rootRow
	for _, gui in ipairs(viewport:GetDescendants()) do
		if
			gui.Name == "Entry"
			and gui:FindFirstChild("Indent")
			and gui.Indent.EntryName.Text:find("ServerStorage", 1, true)
		then
			rootRow = gui
			break
		end
	end
	assert(
		rootRow and rootRow.Indent.Expand.Visible and not rootRow.Insert.Visible,
		"inferred service root expands, without a live insert action"
	)
	rootRow.Indent.Expand.Activated:Fire()
	rootRow.Indent.Expand.Activated:Fire()
	local child
	for _, gui in ipairs(viewport:GetDescendants()) do
		if gui.Name == "Entry" and gui:FindFirstChild("Indent") and gui.Indent.EntryName.Text == "Modules" then
			child = gui
			break
		end
	end
	assert(child, "child references display beneath their service")
	child.Indent.Expand.Activated:Fire()
	local leaf
	for _, gui in ipairs(viewport:GetDescendants()) do
		if gui.Name == "Entry" and gui:FindFirstChild("Indent") and gui.Indent.EntryName.Text == "Inventory" then
			leaf = gui
			break
		end
	end
	assert(leaf, "nested references expand like normal Explorer objects")
	leaf.Activated:Fire()
	assert(
		ui.Details.Visible and frame.Size.Y.Offset == -180 and ui.Details.Path.Text == "ServerStorage.Modules.Inventory",
		"selection opens an aligned source details panel"
	)
	local newMenu = Apps.ContextMenu.new
	local openedMenu
	Apps.ContextMenu.new = function()
		openedMenu = newMenu()
		return openedMenu
	end
	ui.More.Activated:Fire()
	local actions = {}
	for _, item in ipairs(openedMenu.Items) do
		if item.Name then
			actions[item.Name] = item
		end
	end
	assert(
		actions["Expand all"] and actions["Export tree as JSON"] and actions["Add source or traceback…"],
		"secondary controls are available through overflow"
	)
	actions["Collapse all"].OnClick()
	assert(not ui.Details.Visible and frame.Size.Y.Offset == -54, "collapsing clears the hidden selection panel")
	actions["Expand all"].OnClick()
	actions["Add source or traceback…"].OnClick()
	assert(ui.TextImport.Visible and not frame.Visible, "text import is a separate focused view")
	ui.TextImport:FindFirstChild("Text").Text = "require(game.ServerScriptService.AddedModule)"
	ui.TextImport.Analyze.Activated:Fire()
	flushTasks()
	assert(not ui.TextImport.Visible and frame.Visible, "analysis returns to the tree")
	local foundImport = false
	for _, claim in pairs(session.Tree.Nodes) do
		if claim.Name == "AddedModule" then
			foundImport = true
		end
	end
	assert(foundImport, "the redesigned import retains source analysis")
	ui.Search.Text = "not-a-real-path"
	ui.Search:GetPropertyChangedSignal("Text"):Fire()
	assert(frame.Empty.Visible and frame.CanvasPosition.Y == 0, "filtering resets scroll and shows an empty state")
	ui.Search.Text = ""
	ui.Search:GetPropertyChangedSignal("Text"):Fire()
	local sorts = Apps.Reconstructor.ViewStats.Sorts
	ui.Search.Text = "module"
	ui.Search:GetPropertyChangedSignal("Text"):Fire()
	ui.Search.Text = "inventory"
	ui.Search:GetPropertyChangedSignal("Text"):Fire()
	ui.Search.Text = ""
	ui.Search:GetPropertyChangedSignal("Text"):Fire()
	assert(
		Apps.Reconstructor.ViewStats.Sorts == sorts,
		"query changes reuse sorted child lists rather than resorting the whole hierarchy"
	)
	Apps.ContextMenu.new = newMenu
	Apps.Reconstructor.Hide()
	assert(not session.Running)
	local rebuilds = Apps.Reconstructor.ViewStats.Rebuilds
	session:Import("require(game.ServerStorage.HiddenImport)", "Hidden UI fixture")
	flushTasks()
	assert(
		Apps.Reconstructor.ViewStats.Rebuilds == rebuilds,
		"hidden windows do not rebuild and repaint on background scan updates"
	)
	Apps.Reconstructor.Open()
	assert(Apps.Reconstructor.ViewStats.Rebuilds > rebuilds, "reopening reconciles the latest background results")
	Apps.Reconstructor.Hide()
	Lib.Window.new = previousNew
	print("PASS: lazy inference UI, shared React hierarchy, expansion, evidence selection and disabled insertion")
end

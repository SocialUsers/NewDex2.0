--!strict

do
	local fixture = Instance.new("Folder", workspace)
	fixture.Name = "Presentation\nAudit\r" .. string.rep("Long", 30)
	Explorer.SyncHistoryObject(fixture)
	Explorer.ViewNode(nodes[fixture])
	Explorer.Selection:Clear()
	Explorer.ForceUpdate()
	local function snapshot()
		Explorer.Refresh()
		local out = {}
		for _, r in ipairs(Explorer.TreeRenderer.Layer:GetChildren()) do
			if r.Name == "Entry" and r.Visible then
				out[#out + 1] = r.Indent.EntryName.Text
			end
		end
		return table.concat(out, "|") .. ":" .. Explorer.MaxDepth .. ":" .. Explorer.MaxNameWidth
	end
	local baseline = snapshot()
	Explorer.Update(true)
	assert(snapshot() == baseline, "branch rebuild preserves rendered order and extents")
	Explorer.Update(true)
	assert(snapshot() == baseline, "cached branch reuse preserves rendered order and extents")
	Explorer.ForceUpdate()
	assert(snapshot() == baseline, "forced rebuild agrees with cached tree")
	flushTasks()
	flushTasks()
	local originalUpdate = Explorer.Update
	local rebuilt = 0
	Explorer.Update = function(...)
		rebuilt += 1
		return originalUpdate(...)
	end
	Explorer.Expanded[nodes[fixture]] = nil
	local hiddenChild = Instance.new("Part", fixture)
	game.DescendantAdded:Fire(hiddenChild)
	flushTasks()
	flushTasks()
	assert(
		nodes[hiddenChild] and rebuilt == 0,
		"collapsed-branch churn updates nodes without rebuilding the visible tree"
	)
	Explorer.Update = originalUpdate
	local expected = Apps.ExplorerPolicy.FormatName(fixture.Name)
	local function getRow()
		for _, row in ipairs(Explorer.TreeRenderer.Layer:GetChildren()) do
			if row.Name == "Entry" and row.Indent.EntryName.Text == expected then
				return row
			end
		end
		error("formatted presentation row missing")
	end
	local row = getRow()
	assert(
		#row.Indent.EntryName.Text == #expected
			and #expected <= 100
			and not row.Indent.EntryName.Text:find("\n", 1, true),
		"real row uses source name cap and newline/CR formatting"
	)
	assert(
		row.Indent.EntryName.Size.X.Offset == nodes[fixture].LabelWidth,
		"formatted text and measured label bounds agree"
	)
	local mouseX, mouseY = Main.Mouse.X, Main.Mouse.Y
	local oldHovered = Explorer.HoveredObject
	Explorer.HoveredObject = fixture
	Main.Mouse.X = row.AbsolutePosition.X + 100
	Main.Mouse.Y = row.AbsolutePosition.Y + 10
	Explorer.Refresh()
	row = getRow()
	assert(row.Background.BackgroundTransparency < 1, "ordinary row hover is visible")
	Explorer.GuiElems.HeaderPopup.Visible = true
	Explorer.Refresh()
	assert(getRow().Background.BackgroundTransparency == 1, "header popup blocks underlying hover")
	Explorer.GuiElems.HeaderPopup.Visible = false
	Explorer.RightClickContext:Show(0, 0)
	Explorer.Refresh()
	assert(getRow().Background.BackgroundTransparency == 1, "context menu blocks underlying hover")
	Explorer.RightClickContext:Hide()
	Explorer.HoveredObject = oldHovered
	Main.Mouse.X, Main.Mouse.Y = mouseX, mouseY
	fixture.Parent = nil
	Explorer.SyncHistoryObject(fixture)
	Explorer.CleanDeletedChildren()
	Explorer.ForceUpdate()
	print("PASS: rendered name normalization/measurement and popup hover blockers")
end

--!strict

-- Sparse search must not sort unrelated siblings or change ordinary tree order.
do
	Explorer.ClearSearch()
	local folder = Instance.new("Folder", workspace)
	folder.Name = "SparseFixture"
	for i = 1, 1200 do
		local child = Instance.new("Part", folder)
		child.Name = "SparseOther" .. i
	end
	local hit = Instance.new("Part", folder)
	hit.Name = "SparseUniqueHit"
	Explorer.SyncHistoryObject(folder)
	local parent = nodes[folder]
	parent.Sorted = false
	local before = {}
	for i, node in ipairs(parent) do
		before[i] = node
	end
	local original = instMT.__tostring
	local reads = 0
	instMT.__tostring = function(o)
		if o.Parent == folder then
			reads += 1
		end
		return original(o)
	end
	Explorer.DoSearch("SparseUniqueHit")
	instMT.__tostring = original
	assert(
		#Explorer.MatchList == 1 and Explorer.MatchList[1].Obj == hit,
		"sparse projection retains exact match navigation"
	)
	assert(reads < 20, "sparse result display never sorts all unrelated siblings")
	assert(not parent.Sorted, "search projection does not mutate ordinary hierarchy sort state")
	for i, node in ipairs(before) do
		assert(parent[i] == node, "search retains source child order")
	end
	Explorer.DoSearch("SparseOther")
	assert(
		#Explorer.MatchList == 1200 and not parent.Sorted,
		"dense search keeps its sorted snapshot separate from the live hierarchy"
	)
	local sortedNames = {}
	for i, node in ipairs(parent) do
		sortedNames[i] = node.Obj.Name
	end
	Explorer.DoSearch("SparseOther1")
	for i, node in ipairs(parent) do
		assert(node.Obj.Name == sortedNames[i], "subsequent dense searches reuse native order")
	end
	Explorer.ClearSearch()
	folder.Parent = nil
	Explorer.SyncHistoryObject(folder)
	Explorer.CleanDeletedChildren()
end
-- Exercise the actual optimized handlers; no wall-clock thresholds in regressions.
do
	Explorer.ClearSearch()
	local container = Instance.new("Folder", workspace)
	container.Name = "ColdSortFixture"
	for i = 1, 400 do
		local child = Instance.new("Part", container)
		child.Name = "Part" .. ((i * 97) % 400)
	end
	Explorer.SyncHistoryObject(container)
	local parent = nodes[container]
	for _, node in ipairs(parent) do
		node.NameWidth = 30
	end
	Explorer.Expanded[nodes[workspace]] = true
	Explorer.Expanded[parent] = true
	parent.Sorted = false
	local original = instMT.__tostring
	local reads = 0
	instMT.__tostring = function(object)
		if object.Parent == container then
			reads += 1
		end
		return original(object)
	end
	Explorer.Update()
	instMT.__tostring = original
	assert(reads == 400, "actual cold hierarchy sort reads each native object name once")
	for i = 2, #parent do
		assert(parent[i - 1].Obj.Name < parent[i].Obj.Name, "cached sort keys retain alphabetical order")
	end
	local renamed = parent[1].Obj
	renamed.Name = "ZZZ"
	parent.Sorted = false
	Explorer.Update()
	assert(parent[#parent].Obj == renamed, "sort keys are fresh after a rename")
	container.Parent = nil
	Explorer.SyncHistoryObject(container)
	Explorer.CleanDeletedChildren()
	Explorer.ForceUpdate()
end
do
	local box, popup = Explorer.GuiElems.SearchBar, Explorer.GuiElems.HeaderPopup
	local previousSuggest = Apps.SearchQuery.Suggest
	local choices = {}
	for i = 1, 4000 do
		choices[i] = string.format("PerfClass%04d", i)
	end
	Apps.SearchQuery.Suggest = function(query, cursor)
		if query == "is:Perf" then
			return { Choices = choices, First = 4, Last = 7 }
		end
		return previousSuggest(query, cursor)
	end
	Explorer.ClearSearch()
	box:ReleaseFocus()
	box.Text = "is:Perf"
	box.CursorPosition = 8
	box:CaptureFocus()
	box:GetPropertyChangedSignal("Text"):Fire()
	assert(popup.Visible and #popup.Items:GetChildren() == 7, "4,000 choices use seven GUI rows")
	assert(popup.Items.CanvasSize.Y.Offset == 8 + 4000 * 27, "all choices stay scrollable")
	local firstRow = popup.Items:GetChildren()[1]
	box:GetPropertyChangedSignal("CursorPosition"):Fire()
	assert(popup.Items:GetChildren()[1] == firstRow, "duplicate caret event reuses rows")
	popup.Items.CanvasPosition = Vector2.new(0, 3995 * 27)
	popup.Items:GetPropertyChangedSignal("CanvasPosition"):Fire()
	local lastRow = popup.Items:GetChildren()[7]
	assert(lastRow:FindFirstChildOfClass("TextLabel").Text == choices[4000], "scroll reaches final choice")
	box:ReleaseFocus()
	lastRow.Activated:Fire()
	assert(
		box.Text == "is:" .. choices[4000] and not popup.Visible,
		"recycled row accepts its current value after blur"
	)
	box.Text = "is:Perf"
	box.CursorPosition = 8
	box:CaptureFocus()
	box:GetPropertyChangedSignal("Text"):Fire()
	for i = 1, 3999 do
		service.UserInputService.InputBegan:Fire(
			{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
			true
		)
	end
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Tab },
		true
	)
	assert(
		box.Text == "is:" .. choices[4000] and not popup.Visible,
		"keyboard can reach and accept every virtual choice"
	)
	Apps.SearchQuery.Suggest = previousSuggest
	Explorer.ClearSearch()
	box:ReleaseFocus()
	flushTasks()
	print(
		"PASS: 4,000 autocomplete choices, bounded rows, scroll-to-last, keyboard-to-last, duplicate events and blur/click mapping"
	)
end

do
	local update, refresh = Explorer.Update, Explorer.Refresh
	local updates, refreshes = 0, 0
	Explorer.Update = function()
		updates += 1
	end
	Explorer.Refresh = function()
		refreshes += 1
	end
	Explorer.ForceUpdate()
	updates, refreshes = 0, 0
	for i = 1, 1000 do
		Explorer.PerformUpdate()
		Explorer.PerformRefresh()
	end
	assert(updates == 0 and refreshes == 0, "hierarchy bursts never synchronously repaint/yield")
	flushTasks()
	assert(updates == 1 and refreshes == 1, "one redraw for 1,000 requests")
	Explorer.PerformUpdate()
	Explorer.ForceUpdate()
	Explorer.PerformUpdate()
	flushTasks()
	assert(updates == 3 and refreshes == 3, "obsolete scheduled updates cannot consume a newer ticket")
	for i = 1, 1000 do
		Explorer.PerformRefresh()
	end
	flushTasks()
	assert(refreshes == 4, "hover-independent refresh bursts coalesce")
	Explorer.PerformUpdate()
	Explorer.PerformUpdate(true)
	flushTasks()
	assert(updates == 4 and refreshes == 5, "instant request replaces pending delayed redraw exactly once")
	Explorer.Update, Explorer.Refresh = update, refresh
	Explorer.ForceUpdate()
	local count, display = 0, Explorer.DisplayClassIcon
	Explorer.DisplayClassIcon = function(...)
		count += 1
		return display(...)
	end
	local entry = Explorer.GuiElems.TreeFrame.ReactViewport:FindFirstChild("Entry")
	entry.MouseEnter:Fire()
	assert(count == 0, "hover preserves the unchanged class icon instead of repainting it")
	Explorer.DisplayClassIcon = display
	Explorer.CleanDeletedChildren()
	assert(not Explorer.CleanDeletedChildren(), "idle cleanup has no tree traversal work")
	print("PASS: 1,000-to-one redraw coalescing, stale timer cancellation, single-row hover and idle deletion cleanup")
end

do
	Explorer.ClearSearch()
	local parent = Instance.new("Folder", workspace)
	local children = {}
	for i = 1, 2048 do
		children[i] = Instance.new("Part", parent)
	end
	Explorer.SyncHistoryObject(parent)
	local parentNode = nodes[parent]
	local removed = {}
	for index, object in ipairs(children) do
		if index % 2 == 0 then
			object.Parent = nil
			removed[#removed + 1] = object
			game.DescendantRemoving:Fire(object)
			game.ItemChanged:Fire(object, "Parent")
		end
	end
	flushTasks()
	assert(#parentNode == 1024 and not parentNode.HasDel, "a removal burst compacts siblings once before repaint")
	for _, object in ipairs(removed) do
		assert(nodes[object] == nil, "removed instances leave the live registry")
	end
	for index, node in ipairs(parentNode) do
		assert(node.Obj == children[index * 2 - 1] and not node.Del, "compaction preserves surviving sibling order")
	end
	parent.Parent = nil
	Explorer.SyncHistoryObject(parent)
	Explorer.CleanDeletedChildren()
	flushTasks()
end

do
	-- Snapshot searches yield without exposing partial results and are cancelled
	-- by user intent, not by unrelated background hierarchy notifications.
	local previousWait = task.wait
	local root = nodes[workspace]
	local objects = {}
	for i = 1, 900 do
		local obj = Instance.new("Part", workspace)
		obj.Name = "PerfMatch" .. i
		obj.Anchored = i % 2 == 0
		objects[i] = obj
	end
	for _, obj in ipairs(objects) do
		Explorer.SyncHistoryObject(obj)
	end
	Explorer.ClearSearch()
	Explorer.ForceUpdate()
	local engine = Explorer.SearchEngine
	local originalRead = engine.Snapshots.State and true
	local waits = 0
	local compile = Apps.SearchQuery.Compile
	Apps.SearchQuery.Compile = function(query)
		local predicate, err = compile(query)
		if query == "PerfMatch" then
			local first = true
			local raw = predicate
			predicate = function(obj)
				if first then
					first = false
					local finish = os.clock() + 0.006
					repeat
					until os.clock() >= finish
				end
				return raw(obj)
			end
		end
		return predicate, err
	end
	Explorer.DoSearch("door")
	local old = Explorer.Matches
	local busyWait = function()
		waits += 1
		assert(Explorer.Query == "door" and Explorer.Matches == old, "pending search publishes partial results")
	end
	task.wait = busyWait
	assert(
		Explorer.DoSearch("PerfMatch") and waits > 0 and #Explorer.MatchList == 900,
		"snapshot search must yield and retain all results"
	)
	assert(Explorer.SearchView and Explorer.SearchView.Resolved < 100, "search eagerly materializes result rows")
	local once = false
	task.wait = function()
		if not once then
			once = true
			Explorer.ClearSearch()
		end
	end
	assert(Explorer.DoSearch("PerfMatch") == false and Explorer.Query == "", "clear does not cancel the engine")
	once = false
	task.wait = function()
		if not once then
			once = true
			Explorer.SearchRevision += 1
		end
	end
	assert(not Explorer.DoSearch("PerfMatch"), "typing does not cancel obsolete work")
	assert(not Explorer.SearchBusy and not engine.Busy, "cancelled search retains busy state")
	local mutated = false
	local removed = objects[1]
	task.wait = function()
		if not mutated then
			mutated = true
			removed.Parent = nil
			Explorer.SyncHistoryObject(removed)
		end
	end
	assert(Explorer.DoSearch("PerfMatch"), "a background mutation restarts or starves a snapshot query")
	task.wait = previousWait
	assert(
		Explorer.DoSearch("PerfMatch") and #Explorer.MatchList == 899,
		"pending deletion is not merged into the next snapshot"
	)
	local seen = {}
	for i = 1, #Explorer.MatchList do
		local node = Explorer.MatchList[i]
		assert(not seen[node.Obj], "duplicate result")
		seen[node.Obj] = true
	end
	Apps.SearchQuery.Compile = compile
	Explorer.DoSearch("Anchored=")
	assert(Explorer.SearchError and #Explorer.MatchList == 0, "invalid input must not scan")
	Explorer.ClearSearch()
	for _, obj in ipairs(objects) do
		obj.Parent = nil
		Explorer.SyncHistoryObject(obj)
	end
	Explorer.CleanDeletedChildren()
	Explorer.ForceUpdate()
	flushTasks()
	print(
		"PASS: virtual search completeness, lazy rows, atomic publication, clear/typing cancellation, snapshot mutation isolation, deletion delta and invalid input"
	)
end

do
	local index = Explorer.SearchEngine.Snapshots
	local object = Instance.new("Part", workspace)
	object.Name = "DeltaProbe"
	local child = Instance.new("Part", object)
	child.Name = "DeltaChild"
	Explorer.SyncHistoryObject(object)
	Explorer.ForceUpdate()
	assert(Explorer.DoSearch("deltaprobe") and Explorer.Matches[nodes[object]])
	local builds = index.Stats.Builds
	object.Name = "ChangedProbe"
	game.ItemChanged:Fire(object, "Name")
	flushTasks()
	assert(
		Explorer.DoSearch("changedprobe") and Explorer.Matches[nodes[object]],
		"real rename events update indexed names"
	)
	local added = Instance.new("Part", workspace)
	added.Name = "DeltaFresh"
	Explorer.SyncHistoryObject(added)
	Explorer.ForceUpdate()
	assert(
		Explorer.DoSearch("deltafresh") and Explorer.Matches[nodes[added]],
		"real insertion updates indexed membership"
	)
	object.Parent = nil
	Explorer.SyncHistoryObject(object)
	assert(
		Explorer.DoSearch("deltachild") and #Explorer.MatchList == 0,
		"real subtree removal removes indexed descendants"
	)
	assert(index.Stats.Builds == builds, "ordinary Explorer events never rebuild the complete name index")
	local copies = Main.SelectionGeometryObjects
	local renderCopy = Instance.new("Part")
	Main.SelectionGeometryObjects = { [renderCopy] = true }
	renderCopy.Parent = workspace
	game.DescendantAdded:Fire(renderCopy)
	game.ItemChanged:Fire(renderCopy, "Name")
	game.ItemChanged:Fire(renderCopy, "Parent")
	flushTasks()
	assert(not nodes[renderCopy], "selection copies do not enter the Explorer index")
	renderCopy:Destroy()
	Main.SelectionGeometryObjects = copies
	added.Parent = nil
	Explorer.SyncHistoryObject(added)
	Explorer.ClearSearch()
	Explorer.CleanDeletedChildren()
	Explorer.ForceUpdate()
	flushTasks()
	print("PASS: real Explorer rename/insertion/subtree-removal event wiring updates search without rebuilding")
end

do
	Explorer.ClearSearch()
	local folder = Instance.new("Folder", workspace)
	folder.Name = "OffscreenPaintFixture"
	local child = Instance.new("Folder", folder)
	Explorer.SyncHistoryObject(folder)
	Explorer.Expanded[nodes[workspace]] = true
	Explorer.Expanded[nodes[folder]] = false
	Explorer.ForceUpdate()
	local old = Explorer.PerformRefresh
	local requests = 0
	Explorer.PerformRefresh = function()
		requests += 1
	end
	for i = 1, 1000 do
		game.ItemChanged:Fire(child, "IconTint")
	end
	assert(requests == 0, "collapsed icon changes do not schedule row paints")
	game.ItemChanged:Fire(child, "ChatVersion")
	assert(requests == 1, "global status dependencies still refresh visible warnings")
	Explorer.PerformRefresh = old
	folder.Parent = nil
	Explorer.SyncHistoryObject(folder)
	Explorer.CleanDeletedChildren()
end

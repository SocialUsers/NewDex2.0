--!strict

do
	Explorer.ClearSearch()
	local group = Instance.new("Folder", workspace)
	group.Name = "IncrementalFixture"
	local a = Instance.new("Folder", group)
	a.Name = "A"
	local b = Instance.new("Folder", group)
	b.Name = "B"
	for i = 1, 12 do
		local obj = Instance.new("Part", a)
		obj.Name = "Part" .. i
	end
	Explorer.SyncHistoryObject(group)
	for _, obj in ipairs({ workspace, group, a, b }) do
		Explorer.Expanded[nodes[obj]] = true
	end
	Explorer.Update()
	local p = Explorer.VisibleProjection
	local function compare()
		local expected = table.clone(p.Rows)
		local width, depth = Explorer.MaxNameWidth, Explorer.MaxDepth
		Explorer.Update() -- Independent full production traversal, not a second splice.
		assert(#expected == #p.Rows, "incremental row count differs from full traversal")
		for i, node in ipairs(expected) do
			assert(p.Rows[i] == node and p.Indices[node] == i, "incremental order/index differs from full traversal")
		end
		assert(
			Explorer.MaxNameWidth == width and Explorer.MaxDepth == depth,
			"incremental scrollbar extents differ from full traversal"
		)
	end
	local patches = p.Stats.Patches
	local added = Instance.new("Part", a)
	added.Name = "Inserted"
	Explorer.SyncHistoryObject(added)
	Explorer.Update(true)
	assert(p.Stats.Patches > patches, "insertion did not use an incremental update")
	compare()
	local moved = a:GetChildren()[1]
	moved.Parent = b
	Explorer.SyncHistoryObject(moved)
	Explorer.Update(true)
	compare()
	moved.Parent = a
	Explorer.SyncHistoryObject(moved)
	Explorer.Update(true)
	compare()
	added.Name = "A very long renamed property row"
	nodes[added].NameWidth = nil
	nodes[a].Sorted = false
	Apps.SearchQuery.NameIndex.MarkDirty(nodes[added], false)
	-- Deliver the real rename signal so projection invalidation is exercised.
	game.ItemChanged:Fire(added, "Name")
	flushTasks()
	Explorer.Update(true)
	compare()
	Explorer.SetExpanded(nodes[a], false, false)
	Explorer.Update(true)
	compare()
	Explorer.SetExpanded(nodes[a], true, false)
	Explorer.Update(true)
	compare()
	added.Parent = nil
	Explorer.SyncHistoryObject(added)
	Explorer.Update(true)
	assert(p.Indices[nodes[added]] == nil, "deleted row remains indexed")
	compare()
	local before = p.Stats.Patches
	Explorer.DoSearch("Part")
	assert(p.Stats.Patches == before and not p.Valid, "search accidentally uses normal hierarchy splices")
	Explorer.ClearSearch()
	group.Parent = nil
	Explorer.SyncHistoryObject(group)
	Explorer.CleanDeletedChildren()
	Explorer.ForceUpdate()
	flushTasks()
	print(
		"PASS: real Explorer incremental insertion, bidirectional moves, rename/sort, collapse/expand, deletion, exact full-traversal order/indices/extents and search isolation"
	)
end

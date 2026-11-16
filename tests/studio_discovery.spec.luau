--!strict

do
	local selection = Lib.Set.new()
	local a, b = {}, {}
	local changes = 0
	selection.Changed:Connect(function()
		changes += 1
	end)
	selection:SetTable({ a, b, a })
	local list, map = selection.List, selection.Map
	selection.Piviot = a
	selection.ShiftSet = { a }
	assert(
		not selection:SetTable({ a, b }) and changes == 1 and selection.List == list and selection.Map == map,
		"equivalent ordered selection retains identity and observers"
	)
	assert(selection.Piviot == a and selection.ShiftSet[1] == a, "selection suppression preserves pivot/shift state")
	selection:SetTable({ b, a })
	assert(changes == 2 and selection.List[1] == b, "reordering is a real selection change")

	local parent = Instance.new("Folder", workspace)
	parent.Name = "HoverParent"
	local child = Instance.new("Folder", parent)
	child.Name = "HoverChild"
	Explorer.SyncHistoryObject(parent)
	Explorer.ClearSearch()
	local node = nodes[parent]
	Explorer.Expanded[node] = false
	local hovered, within = Explorer.ResolveHoveredNode(child)
	assert(hovered == node and within, "world hover resolves a hidden child to its collapsed visible parent")
	Explorer.Expanded[node] = true
	hovered, within = Explorer.ResolveHoveredNode(child)
	assert(hovered == nodes[child] and not within, "expanded children receive direct hover")
	parent.Parent = nil
	Explorer.SyncHistoryObject(parent)
	Explorer.CleanDeletedChildren()

	local savedMeta = RMD.Classes.Folder
	RMD.Classes.Folder =
		{ Summary = "A container", Properties = { Name = { Summary = "Object name", Browsable = "false" } } }
	assert(Apps.ReflectionService.GetSummary("Folder") == "A container", "insertion description comes from metadata")
	assert(
		Apps.ReflectionService.GetSummary("Folder", "Name") == "Object name",
		"property description comes from metadata"
	)
	assert(
		not Apps.ReflectionService.IsVisible("Folder", "Name", false, false)
			and Apps.ReflectionService.IsVisible("Folder", "Name", true, false),
		"metadata visibility respects the explicit hidden-properties override"
	)
	RMD.Classes.Folder = savedMeta
	local palette = table.clone(Settings.Theme)
	palette.SelectionProfile = "Studio"
	local context = Apps.ExplorerPolicy.RowState(false, true, false, true, palette)
	assert(context.BackgroundTransparency == 0.8, "Studio palette composites selected-parent context")

	local layout = Apps.WindowLayout
	local function pane(x)
		local w = {
			PosX = x,
			PosY = 15,
			SizeX = 300,
			SizeY = 240,
			Closed = false,
			Minimized = false,
			MinX = 100,
			MinY = 100,
			Alignable = true,
		}
		w.OnActivate = Lib.Signal.new()
		w.OnDeactivate = Lib.Signal.new()
		w.OnMinimize = Lib.Signal.new()
		w.OnActivate:Connect(function()
			w.Active = true
		end)
		w.OnDeactivate:Connect(function()
			w.Active = false
		end)
		w.OnMinimize:Connect(function()
			w.Active = false
		end)
		function w:StopTweens() end
		function w:SetAligned(value)
			self.Aligned = value
			if not value and self.Side then
				local i = table.find(self.Side.Windows, self)
				if i then
					table.remove(self.Side.Windows, i)
				end
				self.Side = nil
			end
		end
		function w:Close()
			self.Closed = true
		end
		function w:Show()
			self.Closed = false
		end
		function w:Resize(x, y)
			self.SizeX, self.SizeY = x, y
		end
		function w:MoveInBoundary() end
		function w:SetMinimized(value)
			self.Minimized = value
		end
		function w:AlignTo(side, pos, size)
			self.Side = side
			self.Aligned = true
			self.SizeY = size
			table.insert(side.Windows, pos, self)
		end
		return w
	end
	local first, second = pane(30), pane(80)
	local sides = {
		left = { Width = 300, Hidden = true, Windows = {} },
		right = {
			Width = 340,
			Hidden = false,
			Windows = { first, second },
		},
	}
	first.Side = sides.right
	first.Aligned = true
	second.Side = sides.right
	second.Aligned = true
	local windows = { Explorer = first, Properties = second }
	local captured = layout.Capture(windows, sides)
	assert(
		layout.Validate(captured) and captured.Sides.right.Panels[2] == "Properties",
		"layout stores stable IDs and ordered panel membership"
	)
	sides.right.Windows = { second, first }
	first.PosX = 90
	first.SizeY = 400
	sides.right.Hidden = true
	local updates = 0
	assert(
		layout.Apply(captured, windows, sides, function()
			updates += 1
		end),
		"valid layout restores"
	)
	assert(
		sides.right.Windows[1] == first
			and sides.right.Windows[2] == second
			and first.SizeY == 240
			and not sides.right.Hidden
			and updates == 1,
		"restoration keeps order, dimensions and visibility"
	)
	captured.Sides.right.Hidden = true
	assert(
		layout.Apply(captured, windows, sides, function() end) and not first.Active and not second.Active,
		"restoring a hidden dock deactivates its app controllers"
	)
	captured.Sides.right.Hidden = false
	local invalid = table.clone(captured)
	invalid.Sides = table.clone(captured.Sides)
	invalid.Sides.left = { Width = 300, Hidden = true, Panels = { "Explorer" } }
	assert(not layout.Apply(invalid, windows, sides, function()
		error("must not mutate")
	end), "duplicate panel membership is rejected before mutations")
	invalid = table.clone(captured)
	invalid.Version = 99
	assert(not layout.Validate(invalid), "unsupported layout schema falls back safely")
	print(
		"PASS: real ordered-set suppression, collapsed hover mapping, metadata descriptions/visibility, theme compositing and layout round-trip/validation"
	)
end

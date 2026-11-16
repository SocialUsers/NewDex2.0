--!strict

local builtinTypeof = typeof
typeof = function(value)
	return getmetatable(value) == instMT and "Instance" or builtinTypeof(value)
end
API.Classes.Instance =
	{ Name = "Instance", Properties = { { Name = "Parent", ValueType = { Category = "Class", Name = "Instance" } } } }
API.Classes.ObjectValue = {
	Name = "ObjectValue",
	Superclass = "Instance",
	Properties = {
		{ Name = "Value", ValueType = { Category = "Class", Name = "Instance" } },
		{ Name = "value", ValueType = { Category = "Class", Name = "Instance" } },
	},
}
API.Classes.Weld = {
	Name = "Weld",
	Superclass = "Instance",
	Properties = {
		{ Name = "Part0", ValueType = { Category = "Class", Name = "BasePart" } },
		{ Name = "Part1", ValueType = { Category = "Class", Name = "BasePart" } },
	},
}
API.Classes.InheritedWeld = { Name = "InheritedWeld", Superclass = { Name = "Weld" }, Properties = {} }
local target = Instance.new("Part", workspace)
target.Name = "Door"
local child = Instance.new("Part", target)
local value = Instance.new("ObjectValue", workspace)
value.Name = "DoorReference"
value.Value = target
value.value = target
local weld = Instance.new("InheritedWeld", workspace)
weld.Name = "Hinge"
weld.Part0 = target
weld.Part1 = child
local script = Instance.new("LocalScript", workspace)
script.Name = "DoorController"
script.Source =
	'local Doorbell = 1\r\nlocal door = 2\r\nlocal x = workspace.Door\r\n-- Door is also a text match\r\nprint("Door")'
local unreadable = Instance.new("ModuleScript", workspace)
unreadable.Name = "Unreadable"
local objects = { [target] = true, [child] = true, [value] = true, [weld] = true, [script] = true, [unreadable] = true }
local checks = 0
local result = Apps.ReferenceScan.Run({
	Target = target,
	Objects = objects,
	Checkpoint = function()
		checks += 1
		return true
	end,
})
assert(
	#result.Direct == 2 and result.Stats.Objects == 6,
	"canonical incoming object-value and inherited weld references; containment is omitted"
)
assert(
	#result.Scripts == 3 and result.Scripts[1].Line == 3 and result.Scripts[2].Line == 4 and result.Scripts[3].Line == 5,
	"script matches preserve CRLF line numbers and label comments/strings as text"
)
assert(
	result.Stats.UnavailableScripts == 1 and checks > 6,
	"unavailable source is counted and scanning checkpoints cooperate"
)
for _, item in ipairs(result.Scripts) do
	assert(
		item.Kind == "Text" and item.Source == script.Source,
		"text matches retain snapshots, never asserted identities"
	)
end
local buffered = Apps.ReferenceScan.Run({ Target = target, Objects = objects, Sources = { [script] = "print(Door)" } })
assert(
	#buffered.Scripts == 1 and buffered.Scripts[1].SourceKind == "Editor buffer",
	"editor buffers take precedence over live Source"
)
local cancelled = Apps.ReferenceScan.Run({
	Target = target,
	Objects = objects,
	Checkpoint = function()
		return false
	end,
})
assert(cancelled.Stats.Cancelled and cancelled.Stats.Objects == 0, "cancellation stops before property reads")
local capped = Apps.ReferenceScan.Run({ Target = target, Objects = objects, MaxResults = 1 })
assert(capped.Stats.Truncated and #capped.Direct + #capped.Scripts == 1, "result cap is explicit")
local large = Apps.ReferenceScan.Run({ Target = target, Objects = { [script] = true }, MaxScriptBytes = 8 })
assert(large.Stats.LargeScripts == 1 and #large.Scripts == 0, "script budget gaps are reported")
script.Source = string.rep("Doorbell ", 20000) .. "Door"
checks = 0
local long = Apps.ReferenceScan.Run({
	Target = target,
	Objects = { [script] = true },
	Checkpoint = function()
		checks += 1
		return true
	end,
})
assert(
	#long.Scripts == 1 and checks > 100 and long.Scripts[1].Snippet:find("Door", 1, true),
	"minified lines cooperate even with thousands of rejected prefix matches"
)
script.Source = "\tDoorbell(); Door()"
local tabs = Apps.ReferenceScan.Run({ Target = target, Objects = { [script] = true } })
assert(
	tabs.Scripts[1].Column == 14 and tabs.Scripts[1].EditorColumn == 17,
	"editor navigation accounts for normalized tabs and rejected name prefixes"
)
script.Source = 'print(Door, "<bad>&")'
local referenceNodes = objects
Apps.Explorer.GetNodes = function()
	return referenceNodes
end
assert(Apps.Explorer.Nodes == nil, "regression fixture must not invent a public Nodes field")
service.RunService.Heartbeat = signal()
Apps.ScriptViewer = {
	Documents = {},
	OpenReferenceResult = function(item)
		Apps.ScriptViewer.LastReference = item
	end,
}
local finder = Apps.ReferenceFinder
finder.Open(target)
for _ = 1, 20 do
	service.RunService.Heartbeat:Fire(0.1)
end
assert(
	#finder.Results.Direct == 2 and #finder.Results.Scripts == 1,
	"finder schedules the real scan and publishes separate groups"
)
assert(
	#finder.Rows <= math.ceil(finder.List.AbsoluteSize.Y / 22) + 1,
	"compact result tree mounts only a viewport-sized set of rows"
)
assert(
	finder.Rows[3].Title.Text:find("&lt;bad&gt;&amp;", 1, true)
		and finder.Rows[3].Title.Text:find("<font color=", 1, true),
	"result snippets escape code markup and highlight the matching name"
)
finder.Rows[3].Gui.MouseButton1Click:Fire()
finder.Rows[3].Gui.MouseLeave:Fire()
assert(finder.Rows[3].Gui.BackgroundTransparency == 0, "activated reference keeps its selected row state")
local current = finder.Flat[3].Item
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Down })
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Up })
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Return })
assert(Apps.ScriptViewer.LastReference == current, "keyboard navigation activates the selected result")
local reference
for _, item in ipairs(finder.Results.Direct) do
	if item.Object == value then
		reference = item
	end
end
assert(
	finder.Activate(reference) and Apps.Explorer.LastViewed == value,
	"confirmed link reveals the referencing object"
)
value.Value = nil
assert(finder.Activate(reference) == false, "stale direct references are checked again before navigation")
finder.Activate(finder.Results.Scripts[1])
assert(Apps.ScriptViewer.LastReference.Line == 1, "text rows navigate using their source snapshot")
finder.Filter.Text = "not present"
finder.Filter:GetPropertyChangedSignal("Text"):Fire()
service.RunService.Heartbeat:Fire(0.2)
assert(not finder.Rows[1].Gui.Visible, "filtering clears stale recycled rows")
finder.Refresh()
finder.Window:Close()
service.RunService.Heartbeat:Fire(0.1)
assert(finder.Results.Stats.Cancelled, "closing cancels pending work")
-- Production-like case: Source is inaccessible, no editor tab has been opened.
local byteScript = Instance.new("LocalScript", workspace)
byteScript.Name = "BytecodeController"
local byteScript2 = Instance.new("LocalScript", workspace)
byteScript2.Name = "BytecodeController2"
referenceNodes = { [byteScript] = true, [byteScript2] = true }
local calls, decompiles = 0, 0
referenceEnv.getscriptbytecode = function()
	calls += 1
	return referenceBytecode
end
referenceEnv.decompile = function()
	decompiles += 1
	error("must not auto-decompile")
end
local index = instMT.__index
instMT.__index = function(object, key)
	if key == "Source" and (object == byteScript or object == byteScript2) then
		error("Source is protected")
	end
	return index(object, key)
end
finder.Filter.Text = ""
finder.Open(target)
for _ = 1, 20 do
	local before = calls
	service.RunService.Heartbeat:Fire(0.1)
	assert(calls - before <= 32, "native reads stay within the bounded frame batch")
end
assert(
	#finder.Results.Scripts == 2 and finder.Results.Stats.BytecodeScripts == 2 and decompiles == 0,
	"protected-source scripts produce candidates from real compiler string tables without decompilation"
)
assert(
	finder.Flat[1].Text == "Scripts (2)" and finder.Flat[3].Item.Kind == "Bytecode",
	"script results are immediately visible in the default expanded tree"
)
local byteResult = finder.Results.Scripts[1]
finder.Activate(byteResult)
assert(
	Apps.ScriptViewer.LastReference == byteResult,
	"constant candidates open the script without an invented line number"
)
local priorCalls = calls
finder.Refresh()
for _ = 1, 10 do
	service.RunService.Heartbeat:Fire(0.1)
end
assert(calls == priorCalls and #finder.Results.Scripts == 2, "validated bytecode strings are reused across searches")
Apps.ReferenceSource.Store(byteScript, "return workspace.Door", "Cached decompiled source")
local cached = Apps.ReferenceSource.Read(byteScript)
assert(
	cached.Source == "return workspace.Door" and calls == priorCalls,
	"previously decompiled sources are reused without a native call"
)
assert(
	Apps.ReferenceScan.FindName("Doorbell.Door", "Door") == 10,
	"bytecode strings reject name prefixes without losing a later valid occurrence"
)
instMT.__index = index
referenceNodes = {}
finder.Open(target)
for _ = 1, 3 do
	service.RunService.Heartbeat:Fire(0.1)
end
assert(
	finder.Status.Text:find("0 scripts checked", 1, true)
		and finder.List.Empty.Text:find("No objects discovered", 1, true),
	"empty discovery is visibly different from a searched script with no matches"
)
local edgeScript = Instance.new("LocalScript", workspace)
local boundary = string.rep("-", 65534) .. "Door\nDoorbell\nDoor"
local edge = Apps.ReferenceScan.Run({
	Target = target,
	Objects = { [edgeScript] = true },
	Sources = {
		[edgeScript] = boundary,
	},
})
assert(
	#edge.Scripts == 2 and edge.Scripts[1].Line == 1 and edge.Scripts[1].Column == 65535 and edge.Scripts[2].Line == 3,
	"bounded text prefilter retains cross-chunk matches and exact locations"
)
local checks = 0
local cancelled = Apps.ReferenceScan.Run({
	Target = target,
	Objects = { [edgeScript] = true },
	Sources = { [edgeScript] = string.rep("x", 300000) },
	Checkpoint = function()
		checks += 1
		return checks < 4
	end,
})
assert(cancelled.Stats.Cancelled and checks == 4, "long no-match sources remain cancellable during chunk prefiltering")
local function expectedLines(text, name)
	local rows = {}
	local line = 0
	for body in (text .. "\n"):gmatch("(.-)\n") do
		line += 1
		local first = Apps.ReferenceScan.FindName(body, name)
		if first then
			local start = math.max(1, first - 50)
			rows[#rows + 1] = {
				Line = line,
				Column = first,
				EditorColumn = #body:sub(1, first - 1):gsub("\t", "    ") + 1,
				Snippet = (start > 1 and "..." or "")
					.. body:sub(start, math.min(#body, first + #name + 150)):gsub("\r$", ""):gsub("^%s+", ""),
			}
		end
	end
	return rows
end
local fixtures = {
	"Doorbell Door\n\n\tDoor Door\r\nreturn Door",
	"α\tDoor\nDoor_x\nDoor",
	string.rep("x", 65534) .. " Door\n\tDoor",
	string.rep("Doorbell ", 10000) .. "Door",
	string.rep("\n", 1000) .. "\treturn Door\r\n" .. string.rep("ignored\n", 3000) .. "Door",
	"\tDoor\r\n\treturn Door\n",
	"Door\n" .. string.rep("x", 70000) .. "\nDoor",
}
for _, name in ipairs({ "Door", ".", "x Door", "α" }) do
	target.Name = name
	for _, text in ipairs(fixtures) do
		local expected = expectedLines(text, name)
		local actual = Apps.ReferenceScan.Run({
			Target = target,
			Objects = { [edgeScript] = true },
			Sources = {
				[edgeScript] = text,
			},
		}).Scripts
		assert(#actual == #expected, "sparse scanning retains all matching lines")
		for i, row in ipairs(expected) do
			for key, value in pairs(row) do
				assert(actual[i][key] == value, "sparse result differs in " .. key)
			end
		end
	end
end
target.Name = "Door"
print(
	"PASS: direct reference identity, aliases/inheritance, text evidence, source precedence, cancellation/budgets, long lines, virtual rows and stale-link navigation"
)

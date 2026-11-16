--!strict

initBridgeSelection()
local router = Apps.BridgeCommandRouter.Create({
	Apps = Apps,
	Main = Main,
	service = service,
	env = { loadstring = loadstring },
	Game = game,
})
local inspect = { inspect = true }
local edit = { inspect = true, edit = true }
local execute = { inspect = true, execute = true }
local function command(name, args, grants)
	return router:Execute(name, args or {}, grants or inspect)
end
local function rejects(needle, fn)
	local ok, why = pcall(fn)
	assert(
		not ok and string.find(tostring(why), needle, 1, true),
		"expected rejection " .. needle .. ", got " .. tostring(why)
	)
end
local a = newPart(workspace, vec(0, 0, 0))
a.Name = "Duplicate"
a.Transparency = 0
local b = newPart(workspace, vec(6, 0, 0))
b.Name = "Duplicate"
b.Transparency = 0
local aid, bid = router.Registry:Id(a), router.Registry:Id(b)
assert(aid ~= bid, "same names have different stable instance handles")
local session = command("dex_get_session")
assert(session.placeId == 123 and session.player.userId == 1234 and session.root.id)
rejects("PERMISSION_DENIED", function()
	command("dex_set_properties", { instanceIds = { aid }, properties = { Name = "Denied" } })
end)
assert(a.Name == "Duplicate", "read-only grant cannot edit")
rejects("UNKNOWN_COMMAND", function()
	command("call_any_function", {})
end)
rejects("INSTANCE_UNAVAILABLE", function()
	router.Registry:Id(dexGui)
end)
rejects("STALE_INSTANCE", function()
	command("dex_get_instance", { instanceId = "Workspace.Duplicate" })
end)
local found = command("dex_find_instances", { name = "Duplicate", depth = 5, limit = 1 })
assert(#found.items == 1 and found.nextCursor, "search is paged and returns duplicate names individually")
local nextPage = command("dex_find_instances", { cursor = found.nextCursor, limit = 1 })
assert(#nextPage.items == 1 and nextPage.items[1].id ~= found.items[1].id)
rejects("STALE_CURSOR", function()
	command("dex_find_instances", { cursor = found.nextCursor })
end)
local properties = command("dex_get_properties", { instanceId = aid, properties = { "Name", "NotAProperty" } })
assert(
	properties.properties.Name == "Duplicate" and properties.errors.NotAProperty,
	"unavailable properties are separate from valid empty values"
)
local initialHistory = Apps.History.Index
command("dex_set_properties", { instanceIds = { aid, bid }, properties = { Name = "Renamed", Anchored = false } }, edit)
assert(
	a.Name == "Renamed" and b.Name == "Renamed" and a.Anchored == false and Apps.History.Index == initialHistory + 1,
	"multi-object edits share one real history transaction"
)
assert(router.Registry:Id(a) == aid, "rename retains object identity")
local state = command("dex_get_history")
command("dex_undo", { expectedIndex = state.index, expectedHead = state.head }, edit)
assert(a.Name == "Duplicate" and b.Name == "Duplicate", "AI undo uses existing History implementation")
state = command("dex_get_history")
command("dex_redo", { expectedIndex = state.index, expectedHead = state.head }, edit)
assert(a.Name == "Renamed" and b.Name == "Renamed")
local h = Apps.History
h.Limit = 3
for index = 1, 6 do
	h.Set(a, "Name", "human" .. index)
end
state = command("dex_get_history")
h.Set(a, "Name", "later human edit")
assert(h.Index == state.index, "bounded history index can stay unchanged")
rejects("HISTORY_CONFLICT", function()
	command("dex_undo", { expectedIndex = state.index, expectedHead = state.head }, edit)
end)
while h.CanUndo() do
	assert(h.Undo())
end
state = command("dex_get_history")
h.Set(a, "Name", "replacement redo branch")
assert(h.Undo())
rejects("HISTORY_CONFLICT", function()
	command("dex_redo", { expectedIndex = state.index, expectedHead = state.head }, edit)
end)
command("dex_set_attributes", { instanceIds = { aid }, attributes = { Enabled = false, Count = 0 } }, edit)
local attributes = command("dex_get_attributes", { instanceId = aid }).attributes
assert(attributes.Enabled == false and attributes.Count == 0)
command("dex_set_attributes", { instanceIds = { aid }, attributes = { Enabled = { type = "nil" } } }, edit)
assert(a:GetAttribute("Enabled") == nil, "typed nil removes an attribute without losing false values")
command("dex_set_tags", { instanceIds = { aid }, tags = { "One", "Two" } }, edit)
command("dex_set_tags", { instanceIds = { aid }, tags = {}, mode = "replace" }, edit)
assert(#command("dex_get_tags", { instanceId = aid }).tags == 0, "replace with an empty tag set clears tags")
command("dex_set_selection", { instanceIds = { aid, bid } }, edit)
assert(#command("dex_get_selection").instances == 2)
command("dex_set_selection", { instanceIds = { aid }, mode = "remove" }, edit)
assert(command("dex_get_selection").instances[1].id == bid)
command("dex_set_selection", { instanceIds = {} }, edit)
assert(#command("dex_get_selection").instances == 0, "selection can be cleared")
local parentId = router.Registry:Id(folder)
command("dex_reparent_instances", { instanceIds = { aid }, parentId = parentId }, edit)
assert(a.Parent == folder and router.Registry:Id(a) == aid, "reparent preserves instance identity")
rejects("INVALID_PARENT", function()
	command("dex_reparent_instances", { instanceIds = { parentId }, parentId = aid }, edit)
end)
a.Inferred = true
assert(command("dex_get_instance", { instanceId = aid }).provenance == "reconstructed")
rejects("INFERRED_READ_ONLY", function()
	command("dex_set_properties", { instanceIds = { aid }, properties = { Name = "fake" } }, edit)
end)
a.Inferred = false
rejects("UNSUPPORTED", function()
	command("dex_set_properties", { instanceIds = { aid }, properties = { Source = "return 1" } }, edit)
end)
rejects("READ_ONLY_PROPERTY", function()
	command("dex_set_properties", { instanceIds = { aid }, properties = { ClassName = "Folder" } }, edit)
end)
local previous = a.Transparency
local oldNewIndex = instMT.__newindex
instMT.__newindex = function(object, key, value)
	if object == b and key == "Transparency" and value == 0.5 then
		error("engine denies second target")
	end
	return oldNewIndex(object, key, value)
end
rejects("engine denies", function()
	command("dex_set_properties", { instanceIds = { aid, bid }, properties = { Transparency = 0.5 } }, edit)
end)
assert(a.Transparency == previous and b.Transparency == 0, "failed engine write rolls back earlier successful values")
instMT.__newindex = oldNewIndex
local created = command(
	"dex_create_instances",
	{ className = "Part", parentId = parentId, name = "AI part", properties = { Anchored = true } },
	edit
)
local createdObject = router.Registry:Resolve(created.instances[1].id)
assert(createdObject.Parent == folder and createdObject.Anchored and createdObject.Name == "AI part")
command("dex_delete_instances", { instanceIds = { created.instances[1].id } }, edit)
rejects("STALE_INSTANCE", function()
	router.Registry:Resolve(created.instances[1].id)
end)
state = command("dex_get_history")
command("dex_undo", { expectedIndex = state.index, expectedHead = state.head }, edit)
assert(
	router.Registry:Resolve(created.instances[1].id) == createdObject,
	"undo restores exactly the same object, not a replacement"
)
local wsid = router.Registry:Id(workspace)
rejects("INVALID_TARGET", function()
	command("dex_delete_instances", { instanceIds = { wsid } }, edit)
end)
local before = a.CFrame.Position
command(
	"dex_transform_instances",
	{ instanceIds = { aid }, operation = "move", value = { type = "Vector3", x = 2, y = 3, z = 4 } },
	edit
)
assert(a.CFrame.Position == before + vec(2, 3, 4), "programmatic movement uses actual TransformSession math")
state = command("dex_get_history")
command("dex_undo", { expectedIndex = state.index, expectedHead = state.head }, edit)
assert(a.CFrame.Position == before, "programmatic transform integrates real undo")
Apps.TransformTools = { Dragging = true }
rejects("BUSY", function()
	command("dex_set_properties", { instanceIds = { aid }, properties = { Name = "interference" } }, edit)
end)
Apps.TransformTools.Dragging = false
local codec = router.Codec
local encoded = codec:Encode(Enum.Material.Plastic)
assert(
	encoded.enum == "Material" and codec:Decode(encoded) == Enum.Material.Plastic,
	"enum values round trip through their correct enum type"
)
local colorSequence = { __bridgeType = "ColorSequence", Keypoints = { { Time = 0, Value = Color3.new(1, 0, 0) } } }
assert(
	codec:Encode(colorSequence).keypoints[1].envelope == nil,
	"ColorSequence does not access NumberSequence-only Envelope"
)
local cycle = {}
cycle.self = cycle
rejects("cyclic", function()
	codec:Encode(cycle)
end)
rejects("finite", function()
	codec:Decode(0 / 0)
end)
rejects("INVALID_VALUE", function()
	codec:Decode({ type = "Color3", r = 2, g = 0, b = 0 })
end)
rejects("PERMISSION_DENIED", function()
	command("dex_run_luau", { source = "return 1" }, edit)
end)
local run = command("dex_run_luau", { source = "print('test'); return nil, false, 7" }, execute)
assert(
	run.status == "completed"
		and run.returnCount == 3
		and run.returns[1].type == "nil"
		and run.returns[2] == false
		and run.returns[3] == 7,
	"runtime preserves nil slots and false return values"
)
assert(run.output[1].text == "test")
rejects("COMPILE_ERROR", function()
	command("dex_run_luau", { source = "local =" }, execute)
end)
run = command("dex_run_luau", { source = "error('run failure')" }, execute)
assert(
	run.status == "failed" and string.find(run.error, "run failure", 1, true),
	"runtime errors are actual failed run outcomes"
)
local vmSource = "local scope = assert(dex.vm); scope.count = (scope.count or 0) + 1; return scope.count"
assert(command("dex_run_luau", { source = vmSource, vm = "persistent", vmKey = "one" }, execute).returns[1] == 1)
assert(command("dex_run_luau", { source = vmSource, vm = "persistent", vmKey = "one" }, execute).returns[1] == 2)
assert(command("dex_run_luau", { source = vmSource, vm = "persistent", vmKey = "two" }, execute).returns[1] == 1)
assert(command("dex_run_luau", { source = "return true", vm = "reset", vmKey = "one" }, execute).status == "completed")
assert(command("dex_run_luau", { source = vmSource, vm = "persistent", vmKey = "one" }, execute).returns[1] == 1)
local connections = 0
testTeachCleanup = function()
	connections += 1
end
assert(command("dex_run_luau", {
	source = "dex.teach.State = {sessions = {{connections = {{Disconnect = testTeachCleanup}}}}}",
}, execute).status == "completed")
router:Destroy()
assert(connections == 1)
testTeachCleanup = nil
rejects("DISCONNECTED", function()
	command("dex_get_selection")
end)
print(
	"PASS: Dex MCP stable handles, grants, paged headless queries, real selection/edit/history/transform services, stale undo/redo conflicts, typed values and actual Luau runs"
)

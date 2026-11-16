--!strict

local H = Apps.History
H.Entries = {}
H.Index = 0
local a = Instance.new("Part", workspace)
a.Name = "HistoryA"
a.Anchored = false
a.Position = Vector3.new(1, 2, 3)
local b = Instance.new("Part", workspace)
b.Name = "HistoryB"
b.Anchored = true
b.Position = Vector3.new(4, 5, 6)
Explorer.SyncHistoryObject(a)
Explorer.SyncHistoryObject(b)
Explorer.Selection:SetTable({ nodes[a], nodes[b] })
Properties.SetProp({ Name = "Anchored", Class = "BasePart", ValueType = { Name = "bool" } }, false)
assert(not a.Anchored and not b.Anchored and #H.Entries == 1, "multi-property change grouped, no-op target omitted")
assert(H.Undo() and not a.Anchored and b.Anchored, "each object's distinct prior property restored")
assert(H.Redo() and not b.Anchored, "property redo")
Properties.SetProp({
	Name = "Position",
	Class = "BasePart",
	SubName = ".X",
	ValueType = { Name = "float" },
	RootType = {
		Name = "Vector3",
	},
}, 20)
assert(a.Position.X == 20 and b.Position.X == 20)
assert(
	H.Undo() and a.Position.X == 1 and b.Position.X == 4 and b.Position.Y == 5,
	"component undo restores complete per-object vectors"
)
local attr = {
	IsAttribute = true,
	Name = "ATTR_Enabled",
	AttributeName = "Enabled",
	Class = "Instance",
	ValueType = {
		Name = "bool",
	},
}
Properties.SetProp(attr, false)
assert(a:GetAttribute("Enabled") == false and b:GetAttribute("Enabled") == false)
assert(
	H.Undo() and a:GetAttribute("Enabled") == nil and b:GetAttribute("Enabled") == nil,
	"undo added attributes removes them"
)
H.Redo()
local renamed = {
	IsAttribute = true,
	Name = "ATTR_Visible",
	AttributeName = "Visible",
	Class = "Instance",
	ValueType = {
		Name = "bool",
	},
}
Properties.SetProp(renamed, true, true, attr)
assert(a:GetAttribute("Enabled") == nil and a:GetAttribute("Visible") == false)
assert(
	H.Undo() and a:GetAttribute("Enabled") == false and a:GetAttribute("Visible") == nil,
	"undo actual attribute rename"
)
H.Redo()
Properties.SetProp(renamed, nil, true)
assert(a:GetAttribute("Visible") == nil)
assert(H.Undo() and a:GetAttribute("Visible") == false, "undo actual attribute deletion restores false")
assert(H.Redo() and a:GetAttribute("Visible") == nil, "redo attribute deletion")

b:SetAttribute("Mixed", "second value")
a:SetAttribute("Mixed", false)
local untouched = Instance.new("Part", workspace)
Explorer.SyncHistoryObject(untouched)
Explorer.Selection:SetTable({ nodes[a], nodes[b], nodes[untouched] })
local mixed = {
	IsAttribute = true,
	Name = "ATTR_Mixed",
	AttributeName = "Mixed",
	Class = "Instance",
	MultiType = true,
	ValueType = { Name = "string" },
}
local newMixed = table.clone(mixed)
newMixed.Name = "ATTR_NewMixed"
newMixed.AttributeName = "NewMixed"
Properties.SetProp(newMixed, "", true, mixed)
assert(a:GetAttribute("Mixed") == nil and a:GetAttribute("NewMixed") == false)
assert(b:GetAttribute("Mixed") == nil and b:GetAttribute("NewMixed") == "second value")
assert(untouched:GetAttribute("NewMixed") == nil, "renaming does not create attributes on unrelated selected objects")
assert(H.Undo() and a:GetAttribute("Mixed") == false and b:GetAttribute("Mixed") == "second value")
assert(a:GetAttribute("NewMixed") == nil and b:GetAttribute("NewMixed") == nil)
untouched:Destroy()
Explorer.SyncHistoryObject(untouched)
Explorer.Selection:SetTable({ nodes[a], nodes[b] })
print(
	"PASS: actual Properties writes undo/redo multi-object values, vector components, attribute creation, mixed-type rename, deletion and false values"
)

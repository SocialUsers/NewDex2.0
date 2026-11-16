--!strict

local control = require("../src/Shared/History")
local Apps = {}
local tags = {}
control.InitDeps({
	Apps = Apps,
	Lib = {},
	service = {
		CollectionService = {
			HasTag = function(_, obj, tag)
				return tags[obj] and tags[obj][tag] or false
			end,
			AddTag = function(_, obj, tag)
				tags[obj] = tags[obj] or {}
				tags[obj][tag] = true
			end,
			RemoveTag = function(_, obj, tag)
				if tags[obj] then
					tags[obj][tag] = nil
				end
			end,
		},
	},
})
local H = control.Main()
local parent = { Name = "Parent" }
local obj = { Name = "Original", Parent = parent, Anchored = false, Attributes = {} }
function obj:GetAttribute(name)
	return self.Attributes[name]
end
function obj:SetAttribute(name, value)
	self.Attributes[name] = value
end
H.Set(obj, "Name", "Renamed")
assert(obj.Name == "Renamed" and H.CanUndo())
assert(H.Undo() and obj.Name == "Original")
assert(H.Redo() and obj.Name == "Renamed")
H.Run("Multiple edits", function()
	H.Set(obj, "Anchored", true)
	H.Attribute(obj, "Enabled", false)
	H.Tag(obj, "Enemy", true)
end)
local count = #H.Entries
assert(
	H.Undo() and obj.Anchored == false and obj:GetAttribute("Enabled") == nil and not tags[obj].Enemy,
	"grouped action restores false and absence"
)
assert(H.Redo() and obj.Anchored and obj:GetAttribute("Enabled") == false and tags[obj].Enemy)
H.Run("Rename attribute", function()
	H.Attribute(obj, "Visible", obj:GetAttribute("Enabled"))
	H.Attribute(obj, "Enabled", nil)
end)
assert(H.Undo() and obj:GetAttribute("Enabled") == false and obj:GetAttribute("Visible") == nil)
assert(H.Redo() and obj:GetAttribute("Enabled") == nil and obj:GetAttribute("Visible") == false)
H.Set(obj, "Parent", nil)
assert(obj.Parent == nil)
assert(H.Undo() and obj.Parent == parent, "deleted object retains same identity")
H.Set(obj, "Name", "Branch")
assert(not H.CanRedo(), "new edit clears redo branch")
count = #H.Entries
H.Set(obj, "Name", "Branch")
assert(#H.Entries == count, "no-op makes no entry")
local value, blocked = 1, false
H.Change("Protected", function()
	return value
end, function(v)
	if blocked then
		error("locked")
	end
	value = v
end, 2)
local index = H.Index
blocked = true
warn = function() end
assert(not H.Undo() and H.Index == index and value == 2, "failed replay retains cursor")
blocked = false
assert(H.Undo() and value == 1, "failed operation can be retried")
H.Limit = 5
for i = 1, 20 do
	H.Set(obj, "Name", tostring(i))
end
assert(#H.Entries == 5 and H.Index == 5, "history retention is bounded")
print(
	"PASS: history transactions, property/attribute/tag changes, nil/false, identity restoration, branch invalidation, no-ops, failed replay retry and bounded retention"
)

local startIndex = H.Index
local oldName = obj.Name
local success = pcall(function()
	H.Run("Interrupted structural operation", function()
		H.Set(obj, "Name", "Temporary")
		H.Set(obj, "Parent", nil)
		error("second child rejected")
	end)
end)
assert(
	not success and obj.Name == oldName and obj.Parent == parent and H.Index == startIndex,
	"failed operation rolls back successful earlier writes"
)
print("PASS: interrupted multi-object operation rolls back without adding a partial history entry")

local destination = { Name = "Destination" }
local oldOrder = { Parent = parent, Index = 3 }
local newOrder = { Parent = destination, Index = 1 }
local order = oldOrder
local rejectUndo = false
local function getOrder()
	return order
end
local function setOrder(nextOrder)
	assert(obj.Parent == nextOrder.Parent, "sibling order requires the corresponding parent")
	order = nextOrder
	if rejectUndo and nextOrder == oldOrder then
		error("order callback failed after writing")
	end
end
local function move()
	H.Set(obj, "Parent", destination)
	H.Record(getOrder, setOrder, oldOrder, newOrder, true)
	setOrder(newOrder)
end
H.Entries = {}
H.Index = 0
assert(not pcall(H.Run, "Interrupted move", function()
	move()
	error("failed after reordering")
end))
assert(
	obj.Parent == parent and order == oldOrder and H.Index == 0,
	"transaction rollback restores parent before sibling order"
)
H.Run("Move and reorder", move)
rejectUndo = true
assert(
	not H.Undo() and obj.Parent == destination and order == newOrder and H.Index == 1,
	"failed undo restores parent before sibling order"
)
rejectUndo = false
assert(H.Undo() and obj.Parent == parent and order == oldOrder)
assert(H.Redo() and obj.Parent == destination and order == newOrder)
print("PASS: transaction rollback and failed undo restore sibling order after restoring parent")

--!strict

local T = Apps.TransformSession
local function close(a, b, message)
	assert(math.abs(a - b) < 1e-7, message or tostring(a) .. " ~= " .. tostring(b))
end
local function equal(a, b, message)
	assert(a == b, message)
end
local model = Instance.new("Model", workspace)
model.Name = "TransformFixture"
local a = newPart(model, vec(-2, 0, 0))
local b = newPart(model, vec(2, 0, 0))
local outside = newPart(game, vec())
local locked = newPart(workspace, vec())
locked.Locked = true
local roots = T.Collect({ a, model, a, outside, locked })
assert(#roots == 1 and roots[1] == model, "selection deduplicates ancestors and rejects locked/non-world parts")
b.Locked = true
assert(#T.Collect({ model }) == 0, "models containing locked geometry cannot indirectly modify it")
b.Locked = false
Main.IsDexGuiObject = function(object)
	return object == a
end
assert(#T.Collect({ a, model }) == 0, "Dex-owned geometry cannot enter a transform")
Main.IsDexGuiObject = nil
Apps.Explorer.IsReadOnlyInferenceObject = function(object)
	return object == a
end
assert(#T.Collect({ a, model }) == 0, "inferred server geometry stays read-only")
Apps.Explorer.IsReadOnlyInferenceObject = nil
local bounds, size, pivot = T.Bounds({ model }, "World")
equal(bounds.Position, vec())
equal(size, vec(6, 2, 2))
equal(pivot.Position, vec())
a.PivotOffset = CFrame.new(1, 0, 0)
local _, _, partPivot = T.Bounds({ a }, "Local")
equal(partPivot.Position, vec(-1, 0, 0), "single-object pivot includes PivotOffset")
a.PivotOffset = CFrame.new()
local H = Apps.History
local session = T.Begin({ a, b }, "Move")
assert(session:Move(vec(10, 0, 0)))
assert(session:Move(vec(20, 0, 0)))
equal(a.CFrame.Position, vec(18, 0, 0), "preview updates are absolute, not accumulated")
assert(#H.Entries == 0, "preview produces no per-frame undo entries")
assert(session:Commit() and #H.Entries == 1, "whole multiselection gesture produces one undo entry")
assert(H.Undo())
equal(a.CFrame.Position, vec(-2, 0, 0))
equal(b.CFrame.Position, vec(2, 0, 0))
assert(H.Redo())
equal(a.CFrame.Position, vec(18, 0, 0))
equal(b.CFrame.Position, vec(22, 0, 0))
assert(H.Undo())
session = T.Begin({ a, b }, "Rotate", CFrame.new(), vec(6, 2, 2))
assert(session:Rotate(vec(0, 1, 0), math.pi * 0.5))
equal(a.CFrame.Position, vec(0, 0, 2))
equal(b.CFrame.Position, vec(0, 0, -2))
assert(session:Cancel())
equal(a.CFrame.Position, vec(-2, 0, 0))
session = T.Begin({ a }, "Scale")
assert(session:Scale(1, 2, false, false, 1))
equal(a.Size, vec(4, 2, 2))
equal(a.CFrame.Position, vec(-1, 0, 0))
assert(session:Commit())
assert(H.Undo())
equal(a.Size, vec(2, 2, 2))
equal(a.CFrame.Position, vec(-2, 0, 0))
assert(H.Redo())
equal(a.Size, vec(4, 2, 2))
assert(H.Undo())
session = T.Begin({ a }, "Scale")
assert(session:Scale(2, 1, false, false, -1))
equal(a.Size, vec(2, 3, 2))
equal(a.CFrame.Position, vec(-2, -0.5, 0))
assert(session:Cancel())
session = T.Begin({ a }, "Scale")
assert(session:Scale(3, 1, true, false))
equal(a.Size, vec(2, 2, 4))
equal(a.CFrame.Position, vec(-2, 0, 0))
assert(session:Scale(3, -100, true, false))
close(a.Size.Z, 0.001)
assert(session:Cancel())
a.PivotOffset = CFrame.new(1, 0, 0)
local actualPivot = a:GetPivot()
session = T.Begin({ a }, "Scale")
assert(session:Scale(1, 1, true, false))
equal(a:GetPivot(), actualPivot, "centered axis scaling keeps a custom pivot fixed")
equal(a.PivotOffset.Position, vec(2, 0, 0), "pivot offset scales with its geometry")
assert(session:Cancel())
equal(a.PivotOffset.Position, vec(1, 0, 0))
session = T.Begin({ a }, "Scale")
assert(session:Scale(1, 1, true, true))
equal(a:GetPivot(), actualPivot, "centered uniform scaling keeps a custom pivot fixed")
assert(session:Commit())
assert(H.Undo())
equal(a.PivotOffset.Position, vec(1, 0, 0))
equal(a:GetPivot(), actualPivot)
a.PivotOffset = CFrame.new()
session = T.Begin({ model }, "Scale", CFrame.new(), vec(6, 2, 2))
assert(session:Scale(1, 6, true, false))
close(model:GetScale(), 3)
equal(a.Size, vec(6, 6, 6))
equal(a.CFrame.Position, vec(-6, 0, 0))
assert(session:Scale(1, 3, true, false))
close(model:GetScale(), 2)
equal(a.Size, vec(4, 4, 4))
assert(session:Commit())
assert(H.Undo())
close(model:GetScale(), 1)
equal(a.Size, vec(2, 2, 2))
equal(a.CFrame.Position, vec(-2, 0, 0))
assert(H.Redo())
close(model:GetScale(), 2)
assert(H.Undo())
session = T.Begin({ a, b }, "Scale", CFrame.new(), vec(6, 2, 2))
assert(session:Scale(1, 6, false, false, 1))
equal(a.Size, vec(4, 4, 4))
equal(a.CFrame.Position, vec(-1, 0, 0))
equal(b.CFrame.Position, vec(7, 0, 0))
assert(session:Cancel())
equal(a.CFrame.Position, vec(-2, 0, 0))
local before = #H.Entries
session = T.Begin({ a }, "Move")
assert(session:Move(vec()))
assert(session:Commit())
assert(#H.Entries == before, "no-op gesture creates no history")
session = T.Begin({ a, b }, "Move")
assert(session:Move(vec(5, 0, 0)))
b.Parent = game
local ok = session:Move(vec(8, 0, 0))
assert(not ok, "departing selection terminates failed preview")
equal(a.CFrame.Position, vec(-2, 0, 0), "failed preview rolls back earlier writes")
b.Parent = model
equal(T.Snap(-0.5, 1), 0)
equal(T.Snap(0.5, 1), 1)
equal(T.Snap(0.7, 0), 0.7)
close(T.RayAxis(vec(3, 2, 5), vec(0, 0, -1), vec(), vec(1, 0, 0)), 3)
assert(T.RayAxis(vec(), vec(1, 0, 0), vec(), vec(1, 0, 0)) == nil, "parallel ray/axis does not create an infinite drag")
equal(T.RayPlane(vec(1, 2, 5), vec(0, 0, -1), vec(), vec(0, 0, 1)), vec(1, 2, 0))
assert(T.RayPlane(vec(), vec(1, 0, 0), vec(), vec(0, 0, 1)) == nil)
print(
	"PASS: transform eligibility, oriented bounds, immutable previews, move/rotation, face/center/model/group scaling, rollback, one-entry undo/redo and stable ray math"
)

-- Analytic extents must match the original corner construction at arbitrary poses.
do
	local samples = {}
	for i = 1, 12 do
		local part = newPart(workspace, vec(i * 7 - 33, i * 3 - 17, i * 11 - 55))
		part.CFrame = CFrame.new(part.CFrame.Position) * CFrame.fromAxisAngle(vec(1, 2, 3).Unit, i * 0.29)
		part.Size = vec(0.01 + i * 0.7, 0.02 + i * 0.3, 0.03 + i * 0.9)
		samples[i] = part
	end
	for _, space in ipairs({ "World", "Local", "Scale" }) do
		local reference = space == "Scale" and samples[1].CFrame or samples[1]:GetPivot()
		local orientation = space == "World" and CFrame.new() or reference - reference.Position
		local low = vec(math.huge, math.huge, math.huge)
		local high = -low
		for _, part in ipairs(samples) do
			local h = part.Size * 0.5
			for x = -1, 1, 2 do
				for y = -1, 1, 2 do
					for z = -1, 1, 2 do
						local p = orientation:PointToObjectSpace(part.CFrame * vec(h.X * x, h.Y * y, h.Z * z))
						low = vec(math.min(low.X, p.X), math.min(low.Y, p.Y), math.min(low.Z, p.Z))
						high = vec(math.max(high.X, p.X), math.max(high.Y, p.Y), math.max(high.Z, p.Z))
					end
				end
			end
		end
		local cf, size = T.Bounds(samples, space)
		assert((cf.Position - (orientation * CFrame.new((low + high) * 0.5)).Position).Magnitude < 1e-7)
		assert((size - (high - low)).Magnitude < 1e-7)
	end
	for _, part in ipairs(samples) do
		part:Destroy()
	end
end

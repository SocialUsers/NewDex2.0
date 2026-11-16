--!strict

local Query = require("../src/Apps/AssetManager/AssetQuery").Main()
local records = {}
for i = 1, 20000 do
	records[i] = {
		Key = tostring(i),
		Name = "Asset " .. tostring(i),
		URI = "rbxassetid://" .. i,
		Id = tostring(i),
		Kind = i % 2 == 0 and "Images" or "Sounds",
		Uses = { 1 },
	}
end
local function baseline(term, key, desc, category)
	local out = {}
	for _, r in ipairs(records) do
		if (category == "All" or r.Kind == category) and (r.Name .. " " .. r.URI):lower():find(term, 1, true) then
			out[#out + 1] = r
		end
	end
	table.sort(out, function(a, b)
		local av = key == "ID" and tonumber(a.Id) or key == "References" and #a.Uses or a.Name:lower()
		local bv = key == "ID" and tonumber(b.Id) or key == "References" and #b.Uses or b.Name:lower()
		if av == bv then
			return a.Key < b.Key
		end
		if desc then
			return av > bv
		end
		return av < bv
	end)
	return out
end
local index = Query.Create()
for _, key in ipairs({ "Name", "ID", "References" }) do
	for _, desc in ipairs({ false, true }) do
		for _, category in ipairs({ "All", "Images" }) do
			for _, term in ipairs({ "", "asset 1", "asset 12", "asset 123", "asset 1", "999", "" }) do
				local actual = index.Filter(records, category, term, key, desc)
				local expected = baseline(term, key, desc, category)
				assert(#actual == #expected)
				for i, r in ipairs(expected) do
					assert(actual[i] == r, "ordering mismatch")
				end
			end
		end
	end
end
assert(index.Stats.Sorts == 6, "queries reuse all six orderings")
assert(index.Filter(records, "All", "", "Name", false, function()
	return false
end) == nil, "cancelled queries never publish")
local changed = table.clone(records)
changed[1] = { Key = "new", Name = "New", URI = "new", Id = "new", Kind = "Images", Uses = {} }
assert(index.Filter(changed, "All", "new", "Name", false)[1] == changed[1], "new scans invalidate cache")
local terms = { "a", "as", "ass", "asse", "asset", "asset 1", "asset 12", "asset 123" }
local start = os.clock()
for _, term in ipairs(terms) do
	baseline(term, "Name", false, "All")
end
local before = os.clock() - start
local warm = Query.Create()
warm.Filter(records, "All", "", "Name", false)
start = os.clock()
for _, term in ipairs(terms) do
	warm.Filter(records, "All", term, "Name", false)
end
local after = os.clock() - start
print(
	string.format(
		"PASS: exact order/filter equivalence, invalidation and cancellation; 20k assets baseline %.1f ms, optimized warm %.1f ms (%.1fx)",
		before * 1000,
		after * 1000,
		before / after
	)
)

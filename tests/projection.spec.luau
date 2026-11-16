--!strict

local Factory = require("../src/Apps/Explorer/Services/ExplorerProjection").Main()
local root = {}
local service = { Parent = root, NameWidth = 5 }
root[1] = service
local expanded = { [service] = true }
local rows, indices = {}, {}
local p = Factory.Create(rows, indices)
local function oracle()
	local result = {}
	local function visit(parent)
		for _, node in ipairs(parent) do
			if not node.Del then
				result[#result + 1] = node
				if expanded[node] then
					visit(node)
				end
			end
		end
	end
	visit(root)
	return result
end
local function full()
	table.clear(rows)
	table.clear(indices)
	for i, node in ipairs(oracle()) do
		rows[i] = node
		indices[node] = i
	end
	p:Rebuild(root)
end
local function check()
	local expected = oracle()
	assert(#rows == #expected, "count mismatch")
	local width, depth = 0, 1
	for i, node in ipairs(expected) do
		assert(rows[i] == node and indices[node] == i, "order/position mismatch")
		local d = 0
		local parent = node
		while parent ~= root do
			d += 1
			parent = parent.Parent
		end
		assert(p.Depths[node] == d, "depth mismatch")
		width = math.max(width, node.NameWidth)
		depth = math.max(depth, d)
	end
	assert(p.Width == width and p.Depth == depth, "extent mismatch")
end
local context = { Root = root, Expanded = expanded, Sort = function() end, Measure = function() end }
for i = 1, 17500 do
	local group = { Parent = service, NameWidth = i % 79 + 1 }
	service[i] = group
	expanded[group] = true
	for j = 1, 3 do
		group[j] = { Parent = group, NameWidth = j * 3 }
	end
end
full()
assert(#rows == 70001)
local group = service[8700]
local added = { Parent = group, NameWidth = 120 }
group[#group + 1] = added
p:Mark(group)
assert(p:Try(context))
check()
assert(p.Stats.Projected == 4, "small branch change traverses unrelated branches")
local gone = table.remove(group, 4)
gone.Del = true
p:Mark(group)
assert(p:Try(context) and indices[gone] == nil)
check()
-- Large changes bypass the splice before touching published rows or measuring.
local snapshot = table.clone(rows)
p:Mark(service)
local calls = 0
context.Measure = function()
	calls += 1
end
assert(not p:Try(context) and calls == 0, "large fallback performs duplicate expensive preparation")
for i, node in ipairs(snapshot) do
	assert(rows[i] == node, "fallback modifies published rows")
end
full()
math.randomseed(7342)
for iteration = 1, 300 do
	local a, b = service[math.random(1, 17500)], service[math.random(1, 17500)]
	if #a > 0 then
		local node = table.remove(a, math.random(1, #a))
		node.Parent = b
		b[#b + 1] = node
		p:Mark(a)
		p:Mark(b)
		p:Mark(node)
	end
	if iteration % 3 == 0 then
		expanded[a] = not expanded[a]
		p:Mark(a)
	end
	assert(p:Try(context))
	check()
end
-- Hidden churn must not retain an ever-growing dirty-node map.
for i = 1, 10000 do
	p:Mark({ Parent = service })
end
assert(next(p.Dirty) == nil, "hidden churn accumulates dirty references")
print(
	"PASS: 70001 rows, four-row local projection, fallback isolation, width shrink, 300 bidirectional moves/collapses against an independent oracle, and bounded hidden churn"
)

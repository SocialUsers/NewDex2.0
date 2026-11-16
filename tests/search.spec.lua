--!strict

local module = require("../src/Shared/SearchQuery")
local classes = {
	Instance = { Properties = { Name = { Name = "Name" } } },
	BasePart = {
		Properties = {
			Anchored = { Name = "Anchored", ValueType = { Name = "bool" } },
			Transparency = { Name = "Transparency" },
			Material = { Name = "Material" },
		},
	},
	Part = { Properties = {} },
	MeshPart = { Properties = {} },
	Folder = { Properties = {} },
}
classes.BasePart.Superclass = classes.Instance
classes.Part.Superclass = classes.BasePart
classes.MeshPart.Superclass = classes.BasePart
classes.Folder.Superclass = classes.Instance
module.InitDeps({
	API = { Classes = classes },
	service = {
		CollectionService = {
			HasTag = function(_, obj, tag)
				return obj.Tags[tag] or false
			end,
			GetAllTags = function()
				return { "Light Source", "Light-Source", 'Light"Quote' }
			end,
		},
	},
})
local search = module.Main()
local obj = {
	Name = "Front Door",
	ClassName = "MeshPart",
	Anchored = false,
	Transparency = 0.5,
	Material = "Enum.Material.SmoothPlastic",
	Tags = { LightSource = true, ["Light Source"] = true },
}
function obj:IsA(class)
	return class == "MeshPart" or class == "BasePart" or class == "Instance"
end
local cases = {
	{ "", true },
	{ "door", true },
	{ "DOOR", true },
	{ '"Front Door"', true },
	{ "front door", true },
	{ "dog", false },
	{ "name:front", true },
	{ "classname:meshpart", true },
	{ "is:BasePart", true },
	{ "is:Part", false },
	{ "tag:LightSource", true },
	{ 'tag:"Light Source"', true },
	{ "tag:lightSource", false },
	{ "Anchored=false", true },
	{ "anchored = true", false },
	{ "anchored != true", true },
	{ "Transparency >= 0.5", true },
	{ "Transparency > 0.5", false },
	{ "transparency < 1", true },
	{ "Material=plas", true },
	{ "missing=false", false },
	{ "missing!=true", false },
	{ "door or dog", true },
	{ "dog and door", false },
	{ "(is:BasePart and Anchored=false) or tag:Other", true },
	{ "dog or door Anchored=true", false },
	{ "dog or door Anchored=false", true },
	{ '"and"', false },
	{ '"a\\"b"', false },
	{ 'name:"Front Door"', true },
}
for _, case in ipairs(cases) do
	local predicate, err = search.Compile(case[1])
	assert(predicate, case[1] .. ": " .. tostring(err))
	assert(predicate(obj) == case[2], "Wrong result: " .. case[1])
end
for _, query in ipairs({
	'"open',
	"(door",
	"door)",
	"is:NoSuchClass",
	"Anchored=",
	"door or",
	"door and",
	"()",
	"invalid:thing",
}) do
	local predicate, err = search.Compile(query)
	assert(not predicate and err, "Expected error: " .. query)
end
print("PASS: " .. #cases .. " search cases + 9 invalid queries")
local cart = { Name = "Cart" }
local barrier = { Name = "Barrier", Parent = cart }
local trim = { Name = "Trim", Parent = barrier, Transparency = 0.2, ClassName = "Part" }
local direct = { Name = "Trim", Parent = cart, Transparency = 0.2, ClassName = "Part" }
for _, case in ipairs({
	{ "Cart.*", barrier, true },
	{ "Cart.*", trim, false },
	{ "Cart.*.*", trim, true },
	{ "Cart.*.*", direct, false },
	{ "Cart.Barrier.*", trim, true },
	{ "Cart.*.Trim", trim, true },
	{ "Cart.**", cart, false },
	{ "Cart.**", barrier, true },
	{ "Cart.**", trim, true },
	{ "cart.barrier.trim", trim, true },
	{ "Cart.*.* Transparency < 1", trim, true },
}) do
	local predicate, err = search.Compile(case[1])
	assert(predicate, err)
	assert(predicate(case[2]) == case[3], case[1])
end
local dotName = { Name = "Part.One" }
assert(search.Compile('"Part.One"')(dotName), "quoted dots remain a literal name")
assert(not search.Compile("Cart..Trim"), "empty ancestry segment rejected")
print("PASS: documented child, grandchild, descendant and combined ancestry searches")

classes.BasePart.Properties.Position = { Name = "Position" }
obj.Position = { X = 10, Y = 5, Z = -2 }
assert(search.Compile("Position.X >= 10")(obj), "component comparison")
assert(not search.Compile("position.y > 5")(obj), "component boundary")
assert(not search.Compile("Position.Unknown=3")(obj), "unknown component safely fails")
print("PASS: case-insensitive property component search")

-- Public Explorer filtering documentation: ~=, complete units and byte RGB fields.
classes.BasePart.Properties.Position.ValueType = { Name = "Vector3" }
classes.BasePart.Properties.Size = { Name = "Size", ValueType = { Name = "Vector3" } }
classes.BasePart.Properties.Color = { Name = "Color", ValueType = { Name = "Color3" } }
obj.Size = { X = 21, Y = 6, Z = 22 }
obj.Color = { R = 128 / 255, G = 0, B = 1 }
for _, case in ipairs({
	{ "Transparency ~= 0.5", false },
	{ "Transparency~=0.25", true },
	{ 'Position = "10, 5, -2"', true },
	{ 'Position == "10, 5, 0"', false },
	{ 'Size > "20, 5, 20"', true },
	{ 'Size > "21, 5, 20"', false },
	{ 'Size >= "21, 6, 22"', true },
	{ 'Size < "22, 7, 23"', true },
	{ 'Size <= "21, 6, 22"', true },
	{ 'Size ~= "21, 6, 22"', false },
	{ 'Size ~= "21, 6, 23"', true },
	{ 'Size > "20, 5"', false },
	{ 'Size = "20, nope, 20"', false },
	{ 'Color = "128, 0, 255"', true },
	{ 'Color ~= "128, 0, 255"', false },
	{ 'Color ~= "128, 1, 255"', true },
	{ "Color.R > 120", true },
	{ "Color.R = 128", true },
	{ "Color.R > 128", false },
	{ "Color.G <= 0", true },
	{ "Color.B == 255", true },
}) do
	local predicate, problem = search.Compile(case[1])
	assert(predicate, problem)
	assert(predicate(obj) == case[2], "typed comparison failed: " .. case[1])
end
local originalName = obj.Name
obj.Name = "Arm~Left, Étage"
assert(search.Compile("Arm~Left")(obj), "a literal tilde remains valid in names")
assert(search.Compile('Name="Left, Étage"')(obj), "comma and Unicode in ordinary strings remain literal")
obj.Name = originalName
print("PASS: documented not-equal operator, full typed units, ordered all-component comparison and RGB byte fields")

local suggestions = search.Suggest("is:")
assert(#suggestions.Choices == 5 and suggestions.Choices[1] == "BasePart")
assert(search.Suggest("is:bas").Choices[1] == "BasePart")
assert(search.Suggest("Anchored=").Choices[1] == "false")
assert(search.Suggest("Anchored=t").Choices[1] == "true")
assert(search.Suggest("Anch") == nil)
assert(search.Suggest("door") == nil)
assert(search.Suggest("nonsense=") == nil)
assert(search.Suggest("is:Unknown") == nil)
local middle = search.Suggest("is:PaZZ AND Anchored=true", 6)
assert(middle.First == 4 and middle.Last == 7 and middle.Choices[1] == "Part")
print("PASS: autocomplete classes, boolean values, properties, unknown prefixes and caret replacement")
local tags = search.Suggest("tag:Light")
assert(
	table.find(tags.Choices, '"Light Source"') and table.find(tags.Choices, "Light-Source"),
	"tag suggestions quote names with spaces and retain safe hyphens"
)
local quotedTag = search.Suggest('tag:"Light SoZZ" and Anchored=true', 14)
assert(quotedTag and quotedTag.Choices[1] == '"Light Source"', "quoted tag prefixes autocomplete")
local completed = 'tag:"Light SoZZ" and Anchored=true'
completed = completed:sub(1, quotedTag.First - 1) .. quotedTag.Choices[1] .. completed:sub(quotedTag.Last + 1)
assert(
	completed == 'tag:"Light Source" and Anchored=true',
	"tag completion replaces one quoted value and preserves trailing clauses"
)
assert(search.Suggest("tag:Light-").Choices[1] == "Light-Source", "hyphenated tag prefix completes")
local escaped = search.Suggest('tag:"Light\\')
assert(not escaped, "unmatched escaped prefix safely has no candidate")
assert(search.Suggest('name:"is:Pa') == nil, "class syntax inside quoted names is literal")
assert(search.Suggest('"Anchored=t') == nil, "boolean syntax inside a quoted name is literal")
local escapedQuery = 'tag:"Light\\"QuZZ" AND Anchored=true'
local escapedCaret = assert(escapedQuery:find("QuZZ", 1, true)) + 2
local escapedChoice = assert(search.Suggest(escapedQuery, escapedCaret))
assert(escapedChoice.Choices[1] == '"Light\\"Quote"', "escaped tag quote is decoded for prefix matching")
local escapedCompleted = escapedQuery:sub(1, escapedChoice.First - 1)
	.. escapedChoice.Choices[1]
	.. escapedQuery:sub(escapedChoice.Last + 1)
assert(
	escapedCompleted == 'tag:"Light\\"Quote" AND Anchored=true',
	"replacement spans escaped quotes and preserves the next clause"
)
local beforeEscapedQuote = assert(search.Suggest(escapedQuery, 11))
local earlyCompleted = escapedQuery:sub(1, beforeEscapedQuote.First - 1)
	.. '"Light Source"'
	.. escapedQuery:sub(beforeEscapedQuote.Last + 1)
assert(
	earlyCompleted == 'tag:"Light Source" AND Anchored=true',
	"replacement tail skips escaped quote before the closing quote"
)
print("PASS: spaced, quoted and hyphenated tag completion preserves valid query syntax and surrounding clauses")

local live = search.Compile("Anchored=true")
obj.Anchored = true
assert(live(obj), "cached property lookup reads current true value")
obj.Anchored = false
assert(not live(obj), "cached property lookup reads current false value")
local renamed = search.Compile("name:window")
obj.Name = "Window"
assert(renamed(obj), "name lookup observes renames")
obj.Name = "Front Door"
assert(not renamed(obj), "names are not cached as stale results")
local denied = setmetatable({ ClassName = "Part" }, {
	__index = function()
		error("property denied")
	end,
})
assert(not live(denied), "inaccessible property remains a non-match")
print("PASS: optimized predicates observe live property/name changes and tolerate denied properties")

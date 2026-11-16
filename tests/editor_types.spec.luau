--!strict

do
	local language = Apps.EditorLanguage.New()
	local function completion(source, name)
		local result = language:Complete(source, #source + 1, {})
		for _, item in ipairs(result and result.Items or {}) do
			if item.Name == name then
				return item
			end
		end
	end
	local source = [[
--[=[A palette entry.]=]
export type Palette<T> = {
	--[==[The identifier.]==]
	name: string,
	create: typeof(--[=[Constructs an entry.]=] function(): Palette<number>
		return nil :: any
	end),
	count: T?,
}
type Concrete = Palette<number>
local p: Concrete = nil :: any
local observed = p.create
local other = p.name
]]
	local function hoverAt(expression, offset)
		local at = assert(source:find(expression, 1, true)) + (offset or 0)
		return language:Hover(source, at, {})
	end
	local alias = hoverAt("Palette<number>", 2)
	assert(alias.Documentation == "A palette entry." and alias.Detail:find("type Palette<T>", 1, true))
	local field = hoverAt("p.create", 3)
	assert(field.Detail == "create(): Palette<number>" and field.Documentation == "Constructs an entry.")
	assert(source:sub(field.First, field.Last - 1) == "create")
	assert(hoverAt("p.create", 0).Detail == "p: Concrete")
	assert(not hoverAt("p.create", 1), "the member separator has no hover")
	assert(hoverAt("p.name", 2).Documentation == "The identifier.")
	assert(completion(source .. "p.cr", "create").Documentation == "Constructs an entry.")
	local candidate = completion(source .. "local another: Pal", "Palette")
	assert(candidate.Kind == "Type" and candidate.Documentation == "A palette entry.")
	assert(completion(source .. "local another = 1 :: num", "number").Kind == "Type")
	assert(completion(source .. "local another: Par", "Part").Kind == "Type")
	local custom = [[
local ex = { Name = "ex", Nested = { Enabled = true } }
ex.Count = 1
function ex:Refresh(value: number) return { Value = value } end
local function build() return { Result = 1 } end
local values = { ex }
local Class = {}
Class.__index = Class
function Class:Rename(value: string) self.Name = value end
function Class.new() return setmetatable({ Name = "ex" }, Class) end
]]
	assert(completion(custom .. "ex.Na", "Name").Detail == "string")
	assert(completion(custom .. "ex . Na", "Name").Detail == "string")
	assert(completion(custom .. "ex.Nested.En", "Enabled").Detail == "boolean")
	assert(completion(custom .. "values[1].Co", "Count").Detail == "number")
	assert(completion(custom .. "build().Re", "Result").Detail == "number")
	assert(completion(custom .. "ex:Re", "Refresh").InsertCall)
	assert(completion(custom .. "ex : Re", "Refresh").InsertCall)
	assert(completion(custom .. "ex:Refresh(2).Va", "Value").Detail == "number")
	assert(completion(custom .. "Class.new():Ren", "Rename").InsertCall)
	assert(completion('ex = { Name = "ex" }\nex.Na', "Name").Detail == "string")
	assert(completion(custom .. "do local ex = {} end\nex.Na", "Name").Detail == "string")
	assert(completion("local v = Vector3.new()\nlocal x = v.Mag", "Magnitude").Detail == "number")
	assert(completion("local v = Vector3.new()\nlocal x = v:Do", "Dot").Detail == "Dot(other: Vector3): number")
	assert(completion('local name = "Hello"\nlocal x = name:lo', "lower").Detail == "lower(): string")
	assert(completion("local random = Random.new()\nrandom:NextInt", "NextInteger").InsertCall)
	assert(completion("local signal: RBXScriptSignal\nsignal:Con", "Connect").InsertCall)
	assert(completion('local name: "Hello" | "World"\nname:lo', "lower").InsertCall)
	assert(completion("local v: Vector3? = nil\nv:Do", "Dot").InsertCall)
	local subtype = "type Shape<T> = { Value: T }\nlocal shape: Shape<number>\nshape.Va"
	assert(completion(subtype, "Value").Detail == "number")
	local instanceType = API.Classes.Instance
	API.Classes.Instance = {
		Properties = {
			{ Name = "StudioSecret", ValueType = { Name = "string" }, Security = { Read = "RobloxScriptSecurity" } },
			{ Name = "Name", ValueType = { Name = "string" }, Security = { Read = "None" } },
		},
	}
	assert(completion('local part: Instance\npart:GetPropertyChangedSignal("Na', "Name").InsertText == "Name")
	assert(not completion("local part: Instance\npart.StudioSec", "StudioSecret"))
	API.Classes.Instance = instanceType
	assert(completion('local mode: "Open" | "Closed" = "Cl', "Closed").InsertText == "Closed")
	assert(completion('local mode: "Open" | "Closed" = Cl', "Closed").InsertText == '"Closed"')
	assert(
		completion('local function setMode(mode: "Open" | "Closed") end\nsetMode("Cl', "Closed").InsertText == "Closed"
	)
	assert(completion("local config: { Name: string, Enabled: boolean } = { Na", "Name").InsertText == "Name = ")
	local expected = [[
local function renderName(value: number): string return tostring(value) end
local function renderNumeric(value: number): number return value end
local renderLabel = "label"
local result: string = render
]]
	expected = expected:sub(1, -2)
	local choices = language:Complete(expected, #expected + 1, {}).Items
	assert(choices[1].Name == "renderLabel" and choices[2].Name == "renderName" and choices[2].InsertCall)
	local callback =
		"local function renderName(value: number): string return tostring(value) end\nlocal cb: (number) -> string = render"
	assert(not completion(callback, "renderName").InsertCall, "compatible functions insert a reference")
	local scoped = "do local unavailableName = 1 end\nlocal availableName = 2\nlocal result = ava"
	assert(not completion(scoped, "unavailableName") and completion(scoped, "availableName"))
	local parent = Instance.new("Folder", workspace)
	local scriptObject = Instance.new("LocalScript", parent)
	local config = Instance.new("ModuleScript", parent)
	config.Name = "Config"
	config.Source = "return { Value = 7 }"
	local helpers = Instance.new("ModuleScript", parent)
	helpers.Name = "Helpers"
	helpers.Source = [=[
--[[A record returned by Find.]]
export type Entry = { Id: number }
type Hidden = number
local API = {}
API.Settings = require(script.Parent.Config)
--[[Looks up an entry.]]
function API.Find(id: number) return { Id = id } end
return table.freeze(API)
]=]
	local function imported(text, name)
		local result = language:Complete(text, #text + 1, { Game = game, Workspace = workspace, Script = scriptObject })
		for _, item in ipairs(result and result.Items or {}) do
			if item.Name == name then
				return item
			end
		end
		error("Missing module completion for " .. text)
	end
	local find = imported("local lib = require(script.Parent.Helpers)\nlib.Fi", "Find")
	assert(
		find.Detail == "Find(id: number): { Id: number }"
			and find.Documentation == "Looks up an entry."
			and find.InsertCall
	)
	assert(imported('require("./Helpers").Settings.Va', "Value").Detail == "number")
	assert(imported('require("./Helpers").Set', "Settings").Detail == "{ Value: number }")
	assert(imported('require("./Helpers").Find(1).I', "Id").Detail == "number")
	local spaced = 'local config = require("./Config")\nconfig \t. \tValXX'
	local spacing = assert(language:Complete(spaced, #spaced - 1, { Game = game, Workspace = workspace, Script = scriptObject }))
	assert(spacing.First == #spaced - 4 and spacing.Last == #spaced + 1 and spacing.Items[1].Name == "Value")
	local function resolveMember() end
	local moduleSource = 'require("./Config")'
	local resolverContext = { Game = game, Workspace = workspace, Script = scriptObject }
	local resolve = Apps.EditorModuleTypes.Resolver(moduleSource, resolverContext, resolveMember)
	local mutable = resolve(1)
	mutable.Fields.Extra = "boolean"
	resolve = Apps.EditorModuleTypes.Resolver(moduleSource, resolverContext, resolveMember)
	assert(not resolve(1).Fields.Extra, "module exports are isolated between analyses")
	config.Source = 'return { Value = "new" }'
	assert(imported('local id = 1\nrequire("./Helpers").Settings.Va', "Value").Detail == "string")
	config.Source = "return { Value = 7 }"
	local moduleContext = { Game = game, Workspace = workspace, Script = scriptObject }
	local prefixed = 'local sentinel = 1\nlocal external = require("./Config")\nlocal value = '
	local generation = 0
	local function completePrefix(prefix)
		local text = prefixed .. prefix
		local ticket = generation
		return language:Complete(text, #text + 1, moduleContext, function()
			return generation == ticket
		end).Items[1]
	end
	assert(completePrefix("sent").Name == "sentinel")
	generation += 1
	assert(completePrefix("ext").Detail == "{ Value: number }")
	local fixture = Instance.new("Folder", workspace)
	fixture.Name = "VeryLongCompletionNameReal"
	local source = "local Objects = workspace\nlocal result = Objects.VeryLongCompletionName"
	local resolved = language:Complete(source .. "\nlocal Objects = game", #source + 1, moduleContext)
	assert(resolved and resolved.Items[1].Name == fixture.Name, "the following binding is outside the receiver scope")
	fixture:Destroy()
	local import = 'local lib = require("./Helpers")\n'
	local exported = imported(import .. "local entry: lib.En", "Entry")
	assert(exported.Kind == "Type" and exported.Documentation == "A record returned by Find.")
	assert(imported(import .. "local entry: lib.", "Entry").Kind == "Type")
	local hidden = import .. "local entry: lib.Hid"
	assert(not language:Complete(hidden, #hidden + 1, moduleContext))
	local shadowed = import .. "do local lib = {}\nlocal entry: lib.En"
	assert(not language:Complete(shadowed, #shadowed + 1, moduleContext))
	local hoverSource = import .. "return lib.Find"
	local importedHover = language:Hover(hoverSource, #hoverSource - 2, moduleContext)
	assert(importedHover.Detail == find.Detail and importedHover.Documentation == find.Documentation)
	local typedImport = import .. "local entry: lib.Entry"
	local typeHover = language:Hover(typedImport, #typedImport - 2, moduleContext)
	assert(typeHover.Kind == "Type" and typeHover.Documentation == exported.Documentation)
	local moduleEditContext = table.clone(moduleContext)
	moduleEditContext.ModuleSource = function(object)
		if object == helpers then
			return "return { Find = function(id: string): string return id end }"
		end
	end
	moduleEditContext.ModuleRevision = 1
	assert(language:Hover(hoverSource, #hoverSource - 2, moduleEditContext).Detail == "Find(id: string): string")
	local previous = deps.env.decompile
	local unreadable = Instance.new("ModuleScript", parent)
	unreadable.Name = "Unreadable"
	local decompiles = 0
	deps.env.decompile = function(object)
		assert(object == unreadable)
		decompiles += 1
		return "return { Loaded = true }"
	end
	local request = 'local ignored = require("./Config")\nrequire("./Unreadable").Lo'
	local changedPrefix = request .. "a"
	local latest, ready = true, 0
	local context = {
		Game = game,
		Workspace = workspace,
		Script = scriptObject,
		ModuleRequestValid = function()
			return latest
		end,
		OnModuleReady = function()
			ready += 1
		end,
	}
	assert(not language:Complete(request, #request + 1, context) and decompiles == 0)
	assert(not language:Complete(changedPrefix, #changedPrefix + 1, context) and decompiles == 0)
	local indexed = language.Symbols
	local analyzed = language.MemberAnalysis
	latest = false
	flushTasks()
	assert(decompiles == 0, "a stale completion never reaches the executor decompiler")
	latest = true
	assert(not language:Complete(request, #request + 1, context))
	assert(
		language.Symbols == indexed and language.MemberAnalysis == analyzed,
		"typing a member prefix reuses both indexes"
	)
	assert(not language:Complete(changedPrefix, #changedPrefix + 1, context))
	flushTasks()
	flushTasks()
	assert(decompiles == 1 and ready == 1, "rapid prefix changes share one decompile and one completion refresh")
	assert(language:Complete(request, #request + 1, context).Items[1].Name == "Loaded")
	assert(language:Complete(changedPrefix, #changedPrefix + 1, context).Items[1].Name == "Loaded")
	flushTasks()
	assert(decompiles == 1, "warm completion uses cached source")
	local checks = 0
	local uncached = Apps.EditorLanguage.New()
	assert(not uncached:Complete(request, #request + 1, context, function()
		checks += 1
		return false
	end))
	assert(checks > 0 and uncached.source == nil, "cancelled indexing cannot replace the current symbols")
	assert(uncached:Complete(request, #request + 1, context).Items[1].Name == "Loaded")
	deps.env.decompile = previous
	parent:Destroy()

	local typed = "local function pick<T>(result: T, target: Part): T? | string\n\treturn result\nend\n"
	local target = assert(typed:find("target", 1, true))
	assert(language:Hover(typed, target + 1, {}).Detail == "target: Part")
	assert(language.Symbols:Find("pick").ReturnType == "T? | string")
	local partial = "local function generic<TValue>(x: string)\n\tlocal y: TVa\nend"
	local stop = assert(partial:find("TVa\n", 1, true)) + 3
	local suggestions = language:Complete(partial, stop, {})
	assert(suggestions and suggestions.Items[1].Name == "TValue" and suggestions.Items[1].Kind == "Type")
	local overloadSource =
		"local candidate: (number, { key: string }) -> (string, number?) = nil :: any\nreturn candidate"
	assert(
		language:Hover(overloadSource, #overloadSource - 2, {}).Detail
			== "candidate: (number, { key: string }) -> (string, number?)"
	)
	local unrelated = "type A = { --[[Wrong owner.]] field: string }\nlocal b = {}\nreturn b.field"
	assert(language:Hover(unrelated, #unrelated - 2, {}) == nil)
	local inferred = [[
local prod = { Name = "Prod", PlaceId = 123, UniverseId = 456 }
local dev = { Name = "Dev", PlaceId = 789, UniverseId = 1011 }
local list = { prod, dev }
local function lookup(id)
    for _, item in ipairs(list) do
        if item.PlaceId == id then
            return item
        end
    end
    return nil
end
local api = table.freeze({ Data = list, Lookup = lookup, GetCurrent = function() return prod end })
local function distance(value) return math.abs(value) end
local decoded = { Text = "end", Symbol = ")", Ratio = 1.5 }
do
    local prod = false
end
return api.Data
]]
	local function inferredHover(expression, offset)
		return language:Hover(inferred, assert(inferred:find(expression, 1, true)) + (offset or 0), {})
	end
	local shape = "{ Name: string, PlaceId: number, UniverseId: number }"
	assert(inferredHover("prod =").Detail == "prod: " .. shape)
	assert(inferredHover("list =").Detail == "list: {" .. shape .. "}")
	assert(inferredHover("lookup(id)").Detail == "lookup(id: number): " .. shape .. " | nil")
	assert(inferredHover("function() return prod").Detail == "function(): " .. shape)
	assert(inferredHover("distance(value)").Detail == "distance(value: number): number")
	assert(inferredHover("decoded =").Detail == "decoded: { Ratio: number, Symbol: string, Text: string }")
	assert(inferredHover("return prod end", 7).Detail == "prod: " .. shape)
	local root, freeze = inferredHover("table.freeze"), inferredHover("table.freeze", 6)
	assert(root.Detail == "table: table" and root.DocGlobal == "table")
	assert(freeze.DocGlobal == "table.freeze" and freeze.HoverDetail:find("Lookup: (id: number) ->", 1, true))
	assert(inferredHover("api.Data", 4).Detail == "Data: {" .. shape .. "}")
	local prior = API.Classes.DataModel
	API.Classes.DataModel = { Properties = { { Name = "PlaceId", ValueType = { Name = "int64" } } } }
	local source = "local id = game.PlaceId"
	assert(language:Hover(source, 18, {}).Detail == "PlaceId: number")
	assert(language:Hover(source, 7, {}).Detail == "id: number")
	local nested = "return (game).PlaceId"
	assert(language:Hover(nested, #nested - 3, {}).Detail == "PlaceId: number")
	API.Classes.DataModel = prior
	local cancelled = 0
	local longSource = string.rep("local row = { Name = 'Prod' }\n", 250)
	local indexed = Apps.EditorSymbols.New()
	indexed:Index(longSource)
	assert(not Apps.EditorHoverTypes.Analyze(longSource, indexed, function() end, function()
		cancelled += 1
		return false
	end) and cancelled == 1, "cancelled hover analysis does not publish partial types")
	print(
		"PASS: scoped type documentation, local and generic type completion, typed parameters, type casts, alias fields and compound signatures"
	)
end

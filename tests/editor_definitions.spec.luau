--!strict

do
	local definitions = Apps.EditorDefinitions
	local folder = Instance.new("Folder", workspace)
	folder.Name = "DefinitionHost"
	local sourceScript = Instance.new("LocalScript", folder)
	sourceScript.Name = "Caller"
	local module = Instance.new("ModuleScript", folder)
	module.Name = "Inventory"
	local escaped = Instance.new("ModuleScript", folder)
	escaped.Name = 'Item" List'
	local serviceObject = Instance.new("ReplicatedStorage", game)
	serviceObject.Name = "DefinitionStorage"
	local serviceModule = Instance.new("ModuleScript", serviceObject)
	serviceModule.Name = "Definitions"
	local previousFindService = game.FindService
	game.FindService = function(_, name)
		return name == "ReplicatedStorage" and serviceObject or nil
	end

	local function expect(source, marker, object, offset)
		local start = assert(source:find(marker, 1, true))
		local result = definitions.Resolve(source, start + (offset or 0), sourceScript, game, workspace)
		assert(result and result.Object == object, source .. " @ " .. marker)
		assert(result.First <= start + (offset or 0) and result.Last > start + (offset or 0))
		return source:sub(result.First, result.Last - 1)
	end

	local function absent(source, marker, offset)
		local start = assert(source:find(marker, 1, true))
		assert(not definitions.Resolve(source, start + (offset or 0), sourceScript, game, workspace), source)
	end

	assert(expect("return require(script.Parent.Inventory)", "require", module) == "require")
	assert(expect("return require(script.Parent.Inventory)", "Inventory", module) == "Inventory")
	expect("return require((script.Parent).Inventory)", "Inventory", module)
	expect("return (script.Parent).Inventory", "Inventory", module)
	expect('return require(script.Parent["Item\\" List"])', "List", escaped)
	expect("return require(script.Parent[ [=[Inventory]=] ])", "Inventory", module)
	expect('return require(script.Parent:WaitForChild(\n "Inventory", 1.5\n))', "WaitForChild", module)
	expect('return require(script.Parent:FindFirstChild("Inventory", false))', "Inventory", module)
	expect("return require('./Inventory')", "Inventory", module)
	expect("return require './Inventory'", "require", module)
	expect("return require('@game/DefinitionStorage/Definitions')", "Definitions", serviceModule)
	expect("return require('@game/ReplicatedStorage/Definitions')", "Definitions", serviceModule)
	assert(
		expect("return require('@/ReplicatedStorage/Definitions')", "Definitions", serviceModule)
			== "@/ReplicatedStorage/Definitions"
	)
	assert(
		expect("return require([=[\n@game/ReplicatedStorage/Definitions]=])", "Definitions", serviceModule)
			== "@game/ReplicatedStorage/Definitions"
	)
	absent("return require('@/ReplicatedStorage/Definitions')", "'")
	expect("return require '@/ReplicatedStorage/Definitions'", "require", serviceModule)
	expect("return require((('@game/ReplicatedStorage/Definitions')))", "Definitions", serviceModule)
	expect("return require(`@game/ReplicatedStorage/Definitions`)", "Definitions", serviceModule)
	expect("return require([=[@game/ReplicatedStorage/Definitions]=])", "Definitions", serviceModule)
	expect(
		'local path: string = "@/ReplicatedStorage/Definitions"\nreturn require((path))',
		"((path))",
		serviceModule,
		2
	)
	expect('const path = "@game/ReplicatedStorage/Definitions"\nreturn require(path)', "(path)", serviceModule, 1)
	expect("return require('../DefinitionHost/Inventory')", "Inventory", module)
	local nested = Instance.new("ModuleScript", sourceScript)
	nested.Name = "Nested"
	expect("return require('@self/Nested')", "Nested", nested)
	assert(definitions.ResolvePath("@game/", sourceScript, game) == game)
	assert(definitions.ResolvePath("@/", sourceScript, game) == game)
	assert(definitions.ResolvePath("@game/ReplicatedStorage/", sourceScript, game) == serviceObject)
	assert(definitions.ResolvePath("@self/", sourceScript, game) == sourceScript)
	assert(definitions.ResolvePath("./", sourceScript, game) == folder)
	assert(definitions.ResolvePath("../", sourceScript, game) == workspace)
	assert(not definitions.ResolvePath("@external/Definitions", sourceScript, game))
	absent("return require('@game//ReplicatedStorage/Definitions')", "Definitions")
	absent("return require(`@game/ReplicatedStorage/{key}`)", "key")
	absent("return require(`@game/ReplicatedStorage/Definitions` .. dynamic)", "Definitions")
	absent('return require("@unknown/Definitions")', "Definitions")
	absent('local path = "@game/ReplicatedStorage/Definitions" .. extension\nreturn require(path)', "require")
	expect(
		"local store = game:GetService('ReplicatedStorage')\nreturn require(store.Definitions)",
		"Definitions",
		serviceModule
	)
	expect("local inventory = require('./Inventory')\nreturn inventory", "return inventory", module, 7)
	expect(
		"local parent = script.Parent\nlocal inventory = parent.Inventory\nreturn require(inventory)",
		"require",
		module
	)
	expect("return workspace.DefinitionHost.Inventory", "DefinitionHost", folder)
	expect("return script.Parent.Inventory", "Parent", folder)
	absent("-- script.Parent.Inventory", "Inventory")
	absent("--[=[\nscript.Parent.Inventory\n]=]", "Inventory")
	absent("return 'script.Parent.Inventory'", "Inventory")
	absent("return `{f(`test`)} script.Parent.Inventory`", "Inventory")
	absent("return helper(script.Parent).Inventory", "Inventory")
	absent("return require(1234)", "require")
	absent("return require(script.Parent)", "require")
	absent("return script.Parent:WaitForChild('Absent')", "Absent")
	absent("local script = {}\nreturn script.Parent.Inventory", "Inventory")
	absent("local require = other\nreturn require('./Inventory')", "return require", 7)
	absent("local parent = script.Parent\nparent,other = x,y\nreturn parent.Inventory", "Inventory")
	absent("local parent = script.Parent\nreturn function(parent) return parent.Inventory end", "Inventory")
	absent("do local parent = script.Parent end\nreturn parent.Inventory", "Inventory")
	absent("local module = require('./Inventory')\nreturn module.Name", "Name")
	absent("local parent = script.Parent or something\nreturn parent.Inventory", "Inventory")

	local previousSource = "return script.Parent.Inventory"
	assert(definitions.Prime(previousSource))
	local pendingSource = string.rep("-- padding\n", 900) .. previousSource
	assert(not definitions.Prime(pendingSource, function()
		return false
	end))
	assert(definitions.IsPrimed(previousSource) and not definitions.IsPrimed(pendingSource))
	expect(previousSource, "Inventory", module)
	module.Name = "RenamedInventory"
	absent(previousSource, "Inventory")

	game.FindService = previousFindService
	folder:Destroy()
	serviceObject:Destroy()
	print("PASS: definition navigation resolves static instance and module paths without executing code")
end

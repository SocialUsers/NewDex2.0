-- jsdotlua/symbol-luau@1.0.1; see THIRD_PARTY_NOTICES.md
return {
["symbol-luau"]=function()
--!strict
--[[
	A 'Symbol' is an opaque marker type, implemented to behave similarly to JS:
	https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol
]]
local Symbol = require(script:WaitForChild('Symbol'))
export type Symbol = Symbol.Symbol
local GlobalRegistry = require(script:WaitForChild('Registry.global'))

local SymbolObject = setmetatable({}, {
	--[[
		Creates a new symbol, using the given name when printed. Symbols are
		opaque, so this will always create a new, unique object
	]]
	__call = function(_, name: string?): Symbol.Symbol
		return Symbol.new(name)
	end,
})

SymbolObject.for_ = GlobalRegistry.getOrInit

return SymbolObject

end,
["symbol-luau/Registry.global"]=function()
local Symbol = require(script.Parent:WaitForChild('Symbol'))

local GlobalRegistry: { [string]: Symbol.Symbol } = {}

return {
	getOrInit = function(name: string): Symbol.Symbol
		if GlobalRegistry[name] == nil then
			GlobalRegistry[name] = Symbol.new(name)
		end

		return GlobalRegistry[name]
	end,
	-- Used for testing
	__clear = function()
		GlobalRegistry = {}
	end,
}

end,
["symbol-luau/Symbol"]=function()
--!strict
--[[
	Symbols have the type 'userdata', but when printed or coerced to a string,
	the symbol will turn into the string given as its name.

	**This implementation provides only the `Symbol()` constructor and the
	global registry via `Symbol.for_`.**

	Other behaviors, including the ability to find all symbol properties on
	objects, are not implemented.
]]
export type Symbol = typeof(newproxy(true)) & { [string]: any }

return {
	new = function(name: string?): Symbol
		local self = newproxy(true) :: any

		local wrappedName = "Symbol()"
		if name then
			wrappedName = ("Symbol(%s)"):format(name)
		end

		getmetatable(self).__tostring = function()
			return wrappedName
		end

		return (self :: any) :: Symbol
	end,
}

end,
}

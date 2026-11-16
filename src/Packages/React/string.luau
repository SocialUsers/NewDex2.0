-- jsdotlua/string@1.2.7; see THIRD_PARTY_NOTICES.md
return {
["string/charCodeAt"]=function()
local Number = require(script.Parent.Parent:WaitForChild('number'))

local NaN = Number.NaN

-- js  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/charCodeAt
-- lua http://www.lua.org/manual/5.4/manual.html#pdf-utf8.codepoint
return function(str: string, index: number): number
	if type(index) ~= "number" then
		index = 1
	end
	--[[
		Initial bounds check. Checking string.len is not an exhaustive upper bound,
		but it is cheaper to check string.len and handle utf8.offset than to check
		utf.len, which iterates over all codepoints.
	]]
	local length = string.len(str)
	if index < 1 or index > length then
		return NaN
	end

	-- utf8.offset returns nil for out of bounds
	local offset = utf8.offset(str, index)

	-- check that offset is not greater than the length of the string
	if offset == nil or offset > length then
		return NaN
	end

	local value = utf8.codepoint(str, offset, offset)

	if value == nil then
		return NaN
	end

	return value
end

end,
["string/endsWith"]=function()
local function endsWith(value: string, substring: string, optionalLength: number?): boolean
	local substringLength = substring:len()
	if substringLength == 0 then
		return true
	end
	local valueLength = value:len()
	local length = optionalLength or valueLength
	if length > valueLength then
		length = valueLength
	end
	if length < 1 then
		return false
	end
	local position = length - substringLength + 1
	return value:find(substring, position, true) == position
end

return endsWith

end,
["string/findOr"]=function()
type Match = {
	index: number,
	match: string
}

-- excluding the `+` and `*` character, since findOr tests and graphql use them explicitly
local luaPatternCharacters = "([" .. ("$%^()-[].?"):gsub("(.)", "%%%1") .. "])"

local function findOr(str: string, patternTable: { string }, initIndex: number?): Match | nil
	-- loop through all options in patern patternTable

	local init = utf8.offset(str, initIndex or 1)
	local matches = {}
	for _, value in patternTable do
		value = value:gsub(luaPatternCharacters, "%%%1")
		local iStart, iEnd = string.find(str, value, init)
		if iStart then
			local prefix = string.sub(str, 1, iStart - 1)
			local prefixEnd, invalidBytePosition = utf8.len(prefix)
			if prefixEnd == nil then
				error(("string `%s` has an invalid byte at position %s"):format(prefix, tostring(invalidBytePosition)))
			end
			local iStartIndex = prefixEnd :: number + 1
			local match = {
				index = iStartIndex,
				match = string.sub(str, iStart, iEnd),
			}
			table.insert(matches, match)
		end
	end

	-- if no matches, return nil
	if #matches == 0 then
		return nil
	end

	-- find the first matched index (after the init param)
	-- for each, if we get a hit, return the earliest index and matched term

	local firstMatch
	for _, value in matches do
		-- load first condition
		if firstMatch == nil then
			firstMatch = value
		end
		-- identify if current match comes before first match
		if value.index < firstMatch.index then
			firstMatch = value
		end
	end

	-- return first match
	return firstMatch
end

return findOr

end,
["string/includes"]=function()
-- excluding the `+` and `*` character, since findOr tests and graphql use them explicitly
local luaPatternCharacters = "([" .. ("$%^()-[].?"):gsub("(.)", "%%%1") .. "])"

local function includes(str: string, substring: string, position: (string | number)?): boolean
	local strLen, invalidBytePosition = utf8.len(str)
	assert(strLen ~= nil, ("string `%s` has an invalid byte at position %s"):format(str, tostring(invalidBytePosition)))
	if strLen == 0 then
		return false
	end

	if #substring == 0 then
		return true
	end

	local startIndex = 1
	if position ~= nil then
		startIndex = tonumber(position) or 1
		if startIndex > strLen then
			return false
		end
	end

	if startIndex < 1 then
		startIndex = 1
	end

	local init = utf8.offset(str, startIndex)
	local value = substring:gsub(luaPatternCharacters, "%%%1")
	local iStart, _ = string.find(str, value, init)
	return iStart ~= nil
end

return includes

end,
["string/indexOf"]=function()
-- excluding the `+` and `*` character, since findOr tests and graphql use them explicitly
local luaPatternCharacters = "([" .. ("$%^()-[].?"):gsub("(.)", "%%%1") .. "])"

-- Implements equivalent functionality to JavaScript's `String.indexOf`,
-- implementing the interface and behaviors defined at:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/indexOf
return function(str: string, searchElement: string, fromIndex: number?): number
	local length = #str
	local fromIndex_ = if fromIndex ~= nil then if fromIndex < 1 then 1 else fromIndex :: number else 1

	if #searchElement == 0 then
		return if fromIndex_ > length then length else fromIndex_
	end

	if fromIndex_ > length then
		return -1	
end

	searchElement = searchElement:gsub(luaPatternCharacters, "%%%1")
	local searchElementLength = #searchElement

	for i = fromIndex_, length do
		if string.sub(str, i, i + searchElementLength - 1) == searchElement then
			return i
		end
	end

	return -1
end

end,
["string"]=function()
return {
	charCodeAt = require(script:WaitForChild('charCodeAt')),
	endsWith = require(script:WaitForChild('endsWith')),
	findOr = require(script:WaitForChild('findOr')),
	includes = require(script:WaitForChild('includes')),
	indexOf = require(script:WaitForChild('indexOf')),
	lastIndexOf = require(script:WaitForChild('lastIndexOf')),
	slice = require(script:WaitForChild('slice')),
	split = require(script:WaitForChild('split')),
	startsWith = require(script:WaitForChild('startsWith')),
	substr = require(script:WaitForChild('substr')),
	trim = require(script:WaitForChild('trim')),
	trimEnd = require(script:WaitForChild('trimEnd')),
	trimStart = require(script:WaitForChild('trimStart')),
	-- aliases for trimEnd and trimStart
	trimRight = require(script:WaitForChild('trimEnd')),
	trimLeft = require(script:WaitForChild('trimStart')),
}

end,
["string/lastIndexOf"]=function()
local function lastIndexOf(str: string, searchValue: string, fromIndex: number?): number
	local strLength = string.len(str)
	local calculatedFromIndex
	if fromIndex then
		calculatedFromIndex = fromIndex
	else
		calculatedFromIndex = strLength
	end
	if fromIndex and fromIndex < 1 then
		calculatedFromIndex = 1
	end
	if fromIndex and fromIndex > strLength then
		calculatedFromIndex = strLength
	end
	if searchValue == "" then
		-- FIXME: Luau DFA doesn't understand that
		return calculatedFromIndex :: number
	end

	local lastFoundStartIndex, foundStartIndex
	-- Luau FIXME: Luau doesn't look beyond assignment for type, it should infer number? from loop bound
	local foundEndIndex: number? = 0
	repeat
		lastFoundStartIndex = foundStartIndex
		-- Luau FIXME: DFA doesn't understand until clause means foundEndIndex is never nil within loop
		foundStartIndex, foundEndIndex = string.find(str, searchValue, foundEndIndex :: number + 1, true)
	until foundStartIndex == nil or foundStartIndex > calculatedFromIndex

	if lastFoundStartIndex == nil then
		return -1	
end
	-- Luau FIXME: Luau should see the predicate above and known the line below can only be a number
	return lastFoundStartIndex :: number
end

return lastIndexOf

end,
["string/slice"]=function()
local function slice(str: string, startIndexStr: string | number, lastIndexStr: (string | number)?): string
	local strLen, invalidBytePosition = utf8.len(str)
	assert(strLen ~= nil, ("string `%s` has an invalid byte at position %s"):format(str, tostring(invalidBytePosition)))
	local startIndex = tonumber(startIndexStr)
	assert(typeof(startIndex) == "number", "startIndexStr should be a number")

	if startIndex + strLen < 0 then
		-- then |start index| is greater than string length
		startIndex = 1
	end

	if startIndex > strLen then
		return ""
	end

	-- if no last index length set, go to str length + 1
	local lastIndex = strLen + 1
	if lastIndexStr ~= nil then
		-- ROBLOX FIXME: add parseInt to encapsulate this logic and use it here
		local NaN = 0/0		
lastIndex = tonumber(lastIndexStr) or NaN -- this works because 0 is truthy in Lua
	end
	assert(typeof(lastIndex) == "number", "lastIndexStr should convert to number")

	if lastIndex > strLen then
		lastIndex = strLen + 1
	end

	local startIndexByte = utf8.offset(str, startIndex) :: number
	-- get char length of charset retunred at offset
	local lastIndexByte = utf8.offset(str, lastIndex) :: number - 1

	return string.sub(str, startIndexByte, lastIndexByte)
end

return slice

end,
["string/split"]=function()
local findOr = require(script.Parent:WaitForChild('findOr'))
local slice = require(script.Parent:WaitForChild('slice'))

local types = require(script.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
local MAX_SAFE_INTEGER = require(script.Parent.Parent:WaitForChild('number')).MAX_SAFE_INTEGER

type Pattern = string | Array<string>

local function split(str: string, _pattern: Pattern?, _limit: number?): Array<string>
	if _pattern == nil then
		return { str }
	end
	if _limit == 0 then
		return {}
	end
	local limit = if _limit == nil or _limit < 0 then MAX_SAFE_INTEGER else _limit
	local pattern = _pattern
	local patternList: Array<string>
	if typeof(pattern) == "string" then
		if pattern == "" then
			local result = {}
			for c in str:gmatch(".") do
				table.insert(result, c)
			end
			return result
		end
		patternList = { pattern }
	else
		patternList = pattern :: Array<string>
	end
	local init = 1
	local result = {}
	local lastMatch
	local strLen, invalidBytePosition = utf8.len(str)
	assert(strLen ~= nil, ("string `%s` has an invalid byte at position %s"):format(str, tostring(invalidBytePosition)))

	repeat
		local match = findOr(str, patternList, init)
		if match ~= nil then
			table.insert(result, slice(str, init, match.index))
			local matchLength = utf8.len(match.match)
			-- Luau FIXME? Luau doesn't understand that str has already been shown to be valid utf8 on line 26 and therefore won't be nil
			init = match.index + matchLength :: number
		else
			table.insert(result, slice(str, init, nil))
		end
		if match ~= nil then
			lastMatch = match
		end
	until match == nil or init > strLen or #result >= limit
	if lastMatch ~= nil then
		local lastMatchLength, invalidBytePosition_ = utf8.len(lastMatch.match)
		assert(
			lastMatchLength ~= nil,
			("string `%s` has an invalid byte at position %s"):format(lastMatch.match, tostring(invalidBytePosition_))
		)
		if lastMatch.index + lastMatchLength == strLen + 1 then
			table.insert(result, "")
		end
	end
	return result
end

return split

end,
["string/startsWith"]=function()
local function startsWith(value: string, substring: string, position: number?): boolean
	if string.len(substring) == 0 then
		return true
	end
	-- Luau FIXME: we have to use a tmp variable, as Luau doesn't understand the logic below narrow position to `number`
	local position_
	if position == nil or position < 1 then
		position_ = 1
	else
		position_ = position
	end

	if position_ > string.len(value) then
		return false
	end
	return value:find(substring, position_, true) == position_
end

return startsWith

end,
["string/substr"]=function()
return function(s: string, startIndex: number, numberOfCharacters: number?): string
	if numberOfCharacters and numberOfCharacters <= 0 then
		return ""
	end
	return string.sub(s, startIndex, numberOfCharacters and startIndex + numberOfCharacters - 1 or nil)
end

end,
["string/trim"]=function()
local trimStart = require(script.Parent:WaitForChild('trimStart'))
local trimEnd = require(script.Parent:WaitForChild('trimEnd'))

return function(source: string): string
	return trimStart(trimEnd(source))
end

end,
["string/trimEnd"]=function()
return function(source: string): string
	return (source:gsub("[%s]+$", ""))
end

end,
["string/trimStart"]=function()
return function(source: string): string
	return (source:gsub("^[%s]+", ""))
end

end,
}

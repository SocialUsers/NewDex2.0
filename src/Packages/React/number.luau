-- jsdotlua/number@1.2.7; see THIRD_PARTY_NOTICES.md
return {
["number"]=function()
return {
	isFinite = require(script:WaitForChild('isFinite')),
	isInteger = require(script:WaitForChild('isInteger')),
	isNaN = require(script:WaitForChild('isNaN')),
	isSafeInteger = require(script:WaitForChild('isSafeInteger')),
	MAX_SAFE_INTEGER = require(script:WaitForChild('MAX_SAFE_INTEGER')),
	MIN_SAFE_INTEGER = require(script:WaitForChild('MIN_SAFE_INTEGER')),
	NaN = 0/0,
	toExponential = require(script:WaitForChild('toExponential')),
}

end,
["number/isFinite"]=function()
return function(value)
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

end,
["number/isInteger"]=function()
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isInteger
return function(value)
	return type(value) == "number" and value ~= math.huge and value == math.floor(value)
end

end,
["number/isNaN"]=function()
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isNaN
return function(value)
	return type(value) == "number" and value ~= value
end

end,
["number/isSafeInteger"]=function()
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isSafeInteger
local isInteger = require(script.Parent:WaitForChild('isInteger'))
local MAX_SAFE_INTEGER = require(script.Parent:WaitForChild('MAX_SAFE_INTEGER'))

return function(value)
	return isInteger(value) and math.abs(value) <= MAX_SAFE_INTEGER
end

end,
["number/MAX_SAFE_INTEGER"]=function()
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER
return 9007199254740991

end,
["number/MIN_SAFE_INTEGER"]=function()
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_SAFE_INTEGER
return -9007199254740991
end,
["number/toExponential"]=function()
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toExponential
return function(value: string | number, fractionDigits: number?): string | nil
	local num = value
	if typeof(value) == "string" then
		-- ROBLOX FIXME: add parseInt to encapsulate this logic and use it here
		local NaN = 0/0		
num = tonumber(value) or NaN -- works because 0 is truthy in Lua
	end
	-- returns nil for invalid input instead of nan to be more lua-native
	if typeof(num) ~= "number" then
		return "nan"
	end

	if fractionDigits ~= nil then
		if typeof(fractionDigits) ~= "number" then
			error("TypeError: fractionDigits must be a number between 0 and 100")
		end
		if fractionDigits < 0 or fractionDigits > 100 then
			error("RangeError: fractionDigits must be between 0 and 100")
		end
	end

	local formatString
	if fractionDigits == nil then
		formatString = "%e"
	else
		formatString = "%." .. tostring(fractionDigits) .. "e"
	end

	local retval = string.format(formatString, num):gsub("%+0", "+"):gsub("%-0", "-"):gsub("0*e", "e")

	return retval
end

end,
}

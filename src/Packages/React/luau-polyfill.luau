-- jsdotlua/luau-polyfill@1.2.7; see THIRD_PARTY_NOTICES.md
return {
["luau-polyfill/AssertionError/AssertionError.global"]=function()
-- ROBLOX upstream: https://github.com/nodejs/node/blob/v18.1.0/lib/internal/assert/assertion_error.js
--[[
	Copyright Node.js contributors. All rights reserved.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to
	deal in the Software without restriction, including without limitation the
	rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
	sell copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
	IN THE SOFTWARE.
]]

local Collections = require(script.Parent.Parent.Parent:WaitForChild('collections'))
local Array = Collections.Array
local Object = Collections.Object
local Boolean = require(script.Parent.Parent.Parent:WaitForChild('boolean'))
local String = require(script.Parent.Parent.Parent:WaitForChild('string'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
local inspect = Collections.inspect

local Error = require(script.Parent.Parent:WaitForChild('Error'))
local instanceof = require(script.Parent.Parent.Parent:WaitForChild('instance-of'))

type Error = Error.Error
type Array<T> = types.Array<T>
type Object = types.Object
type Function = types.Function

-- ROBLOX deviation START: mock process to not change AssertionError internals
local process = {
	stderr = {
		isTTY = false,
		columns = 0,
		hasColors = function(...)
			return true
		end,
	},
}
-- ROBLOX deviation END
-- ROBLOX TODO START: implement ErrorCaptureStackTrace correctly
function ErrorCaptureStackTrace(err, ...)
	Error.captureStackTrace(err, ...)
end
-- ROBLOX TODO END
-- ROBLOX TODO START: use real remove colors
local function removeColors(str)
	return str
end
-- local removeColors = require_("internal/util").removeColors
-- ROBLOX TODO END
-- local validateObject = require_("internal/validators").validateObject
-- ROBLOX deviation START: isErrorStackTraceLimitWritable is not necessary ATM
-- local isErrorStackTraceLimitWritable = require_("internal/errors").isErrorStackTraceLimitWritable
-- ROBLOX deviation END
local blue = ""
local green = ""
local red = ""
local white = ""
local kReadableOperator = {
	deepStrictEqual = "Expected values to be strictly deep-equal:",
	strictEqual = "Expected values to be strictly equal:",
	strictEqualObject = 'Expected "actual" to be reference-equal to "expected":',
	deepEqual = "Expected values to be loosely deep-equal:",
	notDeepStrictEqual = 'Expected "actual" not to be strictly deep-equal to:',
	notStrictEqual = 'Expected "actual" to be strictly unequal to:',
	notStrictEqualObject = 'Expected "actual" not to be reference-equal to "expected":',
	notDeepEqual = 'Expected "actual" not to be loosely deep-equal to:',
	notIdentical = "Values have same structure but are not reference-equal:",
	notDeepEqualUnequal = "Expected values not to be loosely deep-equal:",
}
-- Comparing short primitives should just show === / !== instead of using the
-- diff.
local kMaxShortLength = 12
local function copyError(source: Object)
	local keys = Object.keys(source)
	-- ROBLOX TODO:
	local target = {} -- ObjectCreate(ObjectGetPrototypeOf(source))
	for _, key in keys do
		target[key] = source[key]
	end
	target.message = source.message
	return target
end

local function inspectValue(val)
	-- The util.inspect default values could be changed. This makes sure the
	-- error messages contain the necessary information nevertheless.
	return inspect(val, {
		compact = false,
		customInspect = false,
		depth = 1000,
		maxArrayLength = math.huge, -- Assert compares only enumerable properties (with a few exceptions).
		showHidden = false, -- Assert does not detect proxies currently.
		showProxy = false,
		sorted = true, -- Inspect getters as we also check them when comparing entries.
		getters = true,
	})
end

local function createErrDiff(actual, expected, operator)
	local other = ""
	local res = ""
	local end_ = ""
	local skipped = false
	local actualInspected = inspectValue(actual)
	local actualLines = String.split(actualInspected, "\n")
	local expectedLines = String.split(inspectValue(expected), "\n")

	local i = 0
	local indicator = ""

	-- In case both values are objects or functions explicitly mark them as not
	-- reference equal for the `strictEqual` operator.
	if
		operator == "strictEqual"
		and (
			typeof(actual) == "table" and actual ~= nil and typeof(expected) == "table" and expected ~= nil
			or typeof(actual) == "function" and typeof(expected) == "function"
		)
	then
		operator = "strictEqualObject"
	end

	-- If "actual" and "expected" fit on a single line and they are not strictly
	-- equal, check further special handling.
	if #actualLines == 1 and #expectedLines == 1 and actualLines[1] ~= expectedLines[1] then
		-- Check for the visible length using the `removeColors()` function, if
		-- appropriate.
		-- ROBLOX TODO START
		local c = false
		-- local c = inspect.defaultOptions.colors
		-- ROBLOX TODO END
		local actualRaw = if c then removeColors(actualLines[1]) else actualLines[1]
		local expectedRaw = if Boolean.toJSBoolean(c) then removeColors(expectedLines[1]) else expectedLines[1]
		local inputLength = string.len(actualRaw) + string.len(expectedRaw)
		-- If the character length of "actual" and "expected" together is less than
		-- kMaxShortLength and if neither is an object and at least one of them is
		-- not `zero`, use the strict equal comparison to visualize the output.
		if inputLength <= kMaxShortLength then
			if
				(typeof(actual) ~= "table" or actual == nil)
				and (typeof(expected) ~= "table" or expected == nil)
				and (actual ~= 0 or expected ~= 0)
			then
				-- -0 === +0
				return ("%s\n\n"):format(kReadableOperator[operator])
					.. ("%s !== %s\n"):format(actualLines[1], expectedLines[1])
			end
		elseif operator ~= "strictEqualObject" then
			-- If the stderr is a tty and the input length is lower than the current
			-- columns per line, add a mismatch indicator below the output. If it is
			-- not a tty, use a default value of 80 characters.
			local maxLength = if process.stderr.isTTY then process.stderr.columns else 80
			if inputLength < maxLength then
				while string.sub(actualRaw, i + 1, i + 1) == string.sub(expectedRaw, i + 1, i + 1) do
					i += 1
				end
				-- Ignore the first characters.
				if i > 2 then
					-- Add position indicator for the first mismatch in case it is a
					-- single line and the input length is less than the column length.
					indicator = ("\n  %s^"):format(string.rep(" ", i))
					i = 0
				end
			end
		end
	end

	-- Remove all ending lines that match (this optimizes the output for
	-- readability by reducing the number of total changed lines).
	local a = actualLines[#actualLines]
	local b = expectedLines[#expectedLines]
	while a == b do
		local i_ = i
		i += 1
		if i_ < 3 then
			end_ = ("\n  %s%s"):format(a, end_)
		else
			other = a
		end
		table.remove(actualLines)
		table.remove(expectedLines)
		if #actualLines == 0 or #expectedLines == 0 then
			break
		end
		a = actualLines[#actualLines]
		b = expectedLines[#expectedLines]
	end

	local maxLines = math.max(#actualLines, #expectedLines)
	-- Strict equal with identical objects that are not identical by reference.
	-- E.g., assert.deepStrictEqual({ a: Symbol() }, { a: Symbol() })
	if maxLines == 0 then
		-- We have to get the result again. The lines were all removed before.
		local actualLines_ = String.split(actualInspected, "\n")

		-- Only remove lines in case it makes sense to collapse those.
		-- TODO: Accept env to always show the full error.
		if #actualLines_ > 50 then
			actualLines_[47] = ("%s...%s"):format(blue, white)
			while #actualLines_ > 47 do
				table.remove(actualLines_)
			end
		end

		return ("%s\n\n"):format(kReadableOperator.notIdentical) .. ("%s\n"):format(Array.join(actualLines_, "\n"))
	end

	-- There were at least five identical lines at the end. Mark a couple of
	-- skipped.
	if i >= 5 then
		end_ = ("\n%s...%s%s"):format(blue, white, end_)
		skipped = true
	end
	if other ~= "" then
		end_ = ("\n  %s%s"):format(other, end_)
		other = ""
	end

	local printedLines = 0
	local identical = 0
	local msg = kReadableOperator[operator] .. ("\n%s+ actual%s %s- expected%s"):format(green, white, red, white)
	local skippedMsg = (" %s...%s Lines skipped"):format(blue, white)

	local lines = actualLines
	local plusMinus = ("%s+%s"):format(green, white)
	local maxLength = #expectedLines
	if #actualLines < maxLines then
		lines = expectedLines
		plusMinus = ("%s-%s"):format(red, white)
		maxLength = #actualLines
	end

	for ii = 1, maxLines do
		i = ii
		if maxLength < ii then
			-- If more than two former lines are identical, print them. Collapse them
			-- in case more than five lines were identical.
			if identical > 2 then
				if identical > 3 then
					if identical > 4 then
						if identical == 5 then
							res ..= ("\n  %s"):format(lines[(ii - 3)])
							printedLines += 1
						else
							res ..= ("\n%s...%s"):format(blue, white)
							skipped = true
						end
					end
					res ..= ("\n  %s"):format(lines[(ii - 2)])
					printedLines += 1
				end
				res ..= ("\n  %s"):format(lines[(ii - 1)])
				printedLines += 1
			end
			-- No identical lines before.
			identical = 0
			-- Add the expected line to the cache.
			if lines == actualLines then
				res ..= ("\n%s %s"):format(plusMinus, lines[ii])
			else
				other ..= ("\n%s %s"):format(plusMinus, lines[ii])
			end
			printedLines += 1
			-- Only extra actual lines exist
			-- Lines diverge
		else
			local expectedLine = expectedLines[ii]
			local actualLine = actualLines[ii]
			-- If the lines diverge, specifically check for lines that only diverge by
			-- a trailing comma. In that case it is actually identical and we should
			-- mark it as such.
			local divergingLines = actualLine ~= expectedLine
				and (
					not Boolean.toJSBoolean(String.endsWith(actualLine, ","))
					or String.slice(actualLine, 0, -1) ~= expectedLine
				)
			-- If the expected line has a trailing comma but is otherwise identical,
			-- add a comma at the end of the actual line. Otherwise the output could
			-- look weird as in:
			--
			--   [
			--     1         // No comma at the end!
			-- +   2
			--   ]
			--
			if
				divergingLines
				and String.endsWith(expectedLine, ",")
				and String.slice(expectedLine, 0, -1) == actualLine
			then
				divergingLines = false
				actualLine ..= ","
			end
			if divergingLines then
				-- If more than two former lines are identical, print them. Collapse
				-- them in case more than five lines were identical.
				if identical > 2 then
					if identical > 3 then
						if identical > 4 then
							if identical == 5 then
								res ..= ("\n  %s"):format(actualLines[ii - 3])
								printedLines += 1
							else
								res ..= ("\n%s...%s"):format(blue, white)
								skipped = true
							end
						end
						res ..= ("\n  %s"):format(actualLines[ii - 2])
						printedLines += 1
					end
					res ..= ("\n  %s"):format(actualLines[ii - 1])
					printedLines += 1
				end
				-- No identical lines before.
				identical = 0
				-- Add the actual line to the result and cache the expected diverging
				-- line so consecutive diverging lines show up as +++--- and not +-+-+-.
				res ..= ("\n%s+%s %s"):format(green, white, actualLine)
				other ..= ("\n%s-%s %s"):format(red, white, expectedLine)
				printedLines += 2
				-- Lines are identical
			else
				-- Add all cached information to the result before adding other things
				-- and reset the cache.
				res ..= other
				other = ""
				identical += 1
				-- The very first identical line since the last diverging line is be
				-- added to the result.
				if identical <= 2 then
					res ..= ("\n  %s"):format(actualLine)
					printedLines += 1
				end
			end
		end
		-- Inspected object to big (Show ~50 rows max)
		if printedLines > 50 and ii < maxLines - 2 then
			return ("%s%s\n%s\n%s...%s%s\n"):format(msg, skippedMsg, res, blue, white, other)
				.. ("%s...%s"):format(blue, white)
		end
	end

	return ("%s%s\n%s%s%s%s"):format(msg, if skipped then skippedMsg else "", res, other, end_, indicator)
end
-- ROBLOX deviation START: skipped as it is only needed in [inspect.custom] method
-- local function addEllipsis(string_)
-- 	local lines = String.split(string_, "\n", 11)
-- 	if #lines.length > 10 then
-- 		lines = Array.slice(lines, 0, 10)
-- 		return ("%s\n..."):format(Array.join(lines, "\n"))
-- 	elseif string.len(string_) > 512 then
-- 		return ("%s..."):format(String.slice(string_, 512))
-- 	end
-- 	return string_
-- end
-- ROBLOX deviation END

export type AssertionError = Error & {
	actual: any,
	expected: any,
	operator: string?,
	generatedMessage: boolean,
	code: "ERR_ASSERTION",
	toString: (self: AssertionError) -> any	-- ROBLOX deviation: skipped [inpect.custom] method
	-- [inspect.custom]: (self: AssertionError, recurseTimes: any, ctx: any) -> any,

}

type AssertionErrorStatics = {
	new: (options: AssertionErrorOptions) -> AssertionError,
	__index: AssertionError,
	__tostring: (self: AssertionError) -> string
}

local AssertionError: AssertionError & AssertionErrorStatics = (
	setmetatable({}, { __index = Error }) :: any
) :: AssertionError & AssertionErrorStatics
AssertionError.__index = AssertionError
AssertionError.__tostring = function(self: AssertionError)
	return self:toString()
end

type AssertionErrorOptions = {
	message: string?,
	actual: any?,
	expected: any?,
	-- ROBLOX note: this is optional in definitely-typed, but we always use it in Lua and it's only nil when details is non-nil
	operator: string?,
	stackStartFn: Function?
}

function AssertionError.new(options: AssertionErrorOptions): AssertionError
	local self: AssertionError
	-- validateObject(options, "options")
	-- stylua: ignore
	local message, operator, stackStartFn =
		options.message,
		options.operator,
		options.stackStartFn
	local actual, expected = options.actual, options.expected
	-- ROBLOX deviation START: Error.stackTraceLimit not available in Luau port
	-- local limit = Error.stackTraceLimit
	-- if isErrorStackTraceLimitWritable() then
	-- 	Error.stackTraceLimit = 0
	-- end
	-- ROBLOX deviation END
	if message ~= nil then
		self = (setmetatable(Error.new(tostring(message)), AssertionError) :: any) :: AssertionError
	else
		if process.stderr.isTTY then
			-- Reset on each call to make sure we handle dynamically set environment
			-- variables correct.
			if process.stderr:hasColors() then
				blue = "\u{001b}[34m"
				green = "\u{001b}[32m"
				white = "\u{001b}[39m"
				red = "\u{001b}[31m"
			else
				blue = ""
				green = ""
				white = ""
				red = ""
			end
		end
		-- Prevent the error stack from being visible by duplicating the error
		-- in a very close way to the original in case both sides are actually
		-- instances of Error.
		if
			typeof(actual) == "table"
			and actual ~= nil
			and typeof(expected) == "table"
			and expected ~= nil
			and Array.indexOf(Object.keys(actual), "stack") ~= -1			
and instanceof(actual, Error)
			and Array.indexOf(Object.keys(expected), "stack") ~= -1			
and instanceof(expected, Error)
		then
			actual = copyError(actual)
			expected = copyError(expected)
		end
		if operator == "deepStrictEqual" or operator == "strictEqual" then
			self = (
				setmetatable(Error.new(createErrDiff(actual, expected, operator)), AssertionError) :: any
			) :: AssertionError
		elseif operator == "notDeepStrictEqual" or operator == "notStrictEqual" then
			-- In case the objects are equal but the operator requires unequal, show
			-- the first object and say A equals B
			local base = kReadableOperator[operator]
			local res = String.split(inspectValue(actual), "\n")

			-- In case "actual" is an object or a function, it should not be
			-- reference equal.
			if
				operator == "notStrictEqual"
				and (typeof(actual) == "table" and actual ~= nil or typeof(actual) == "function")
			then
				base = kReadableOperator.notStrictEqualObject
			end

			-- Only remove lines in case it makes sense to collapse those.
			-- TODO: Accept env to always show the full error.
			if #res > 50 then
				res[47] = ("%s...%s"):format(blue, white)
				while #res > 47 do
					table.remove(res)
				end
			end

			-- Only print a single input.
			if #res == 1 then
				self = (
					setmetatable(
						Error.new(("%s%s%s"):format(base, if string.len(res[1]) > 5 then "\n\n" else " ", res[1])),
						AssertionError
					) :: any
				) :: AssertionError
			else
				self = (
					setmetatable(Error.new(("%s\n\n%s\n"):format(base, Array.join(res, "\n"))), AssertionError) :: any
				) :: AssertionError
			end
		else
			local res = inspectValue(actual)
			local other = inspectValue(expected)
			local knownOperator = kReadableOperator[tostring(operator)]
			if operator == "notDeepEqual" and res == other then
				res = ("%s\n\n%s"):format(knownOperator, res)
				if string.len(res) > 1024 then
					res = ("%s..."):format(String.slice(res, 0, 1021))
				end
				self = (setmetatable(Error.new(res), AssertionError) :: any) :: AssertionError
			else
				if string.len(res) > 512 then
					res = ("%s..."):format(String.slice(res, 0, 509))
				end
				if string.len(other) > 512 then
					other = ("%s..."):format(String.slice(other, 0, 509))
				end
				if operator == "deepEqual" then
					res = ("%s\n\n%s\n\nshould loosely deep-equal\n\n"):format(knownOperator, res)
				else
					local newOp = kReadableOperator[("%sUnequal"):format(tostring(operator))]
					if Boolean.toJSBoolean(newOp) then
						res = ("%s\n\n%s\n\nshould not loosely deep-equal\n\n"):format(newOp, res)
					else
						other = (" %s %s"):format(tostring(operator), other)
					end
				end
				self = (setmetatable(Error.new(("%s%s"):format(res, other)), AssertionError) :: any) :: AssertionError
			end
		end
	end
	-- ROBLOX deviation START: Error.stackTraceLimit not available in Luau port
	-- if Boolean.toJSBoolean(isErrorStackTraceLimitWritable()) then
	-- 	Error.stackTraceLimit = limit
	-- end
	-- ROBLOX deviation END
	self.generatedMessage = not Boolean.toJSBoolean(message)
	--[[
		ROBLOX deviation: not using ObjectDefineProperty:
		original code:
		ObjectDefineProperty(self, "name", {
			value = "AssertionError [ERR_ASSERTION]",
			enumerable = false,
			writable = true,
			configurable = true,
		})
	]]
	self.name = "AssertionError [ERR_ASSERTION]"
	self.code = "ERR_ASSERTION"
	-- ROBLOX deviation START: details field not in public API docs, nodejs test suite, or in definitely-typed
	-- if details ~= nil then
	-- 	self.actual = nil
	-- 	self.expected = nil
	-- 	self.operator = ""
	-- 	for i = 1, #details do
	-- 		self["message " .. tostring(i)] = details[i].message
	-- 		self["actual " .. tostring(i)] = details[i].actual
	-- 		self["expected " .. tostring(i)] = details[i].expected
	-- 		self["operator " .. tostring(i)] = details[i].operator
	-- 		self["stack trace " .. tostring(i)] = details[i].stack
	-- 	end
	-- else
	self.actual = actual
	self.expected = expected
	self.operator = operator
	-- end
	-- ROBLOX deviation END
	ErrorCaptureStackTrace(self, stackStartFn or AssertionError.new)
	-- Create error message including the error code in the name.
	--[[
		ROBLOX deviation: Lua doesn't support 'LuaMemberExpression' as a standalone type
		original code:
		this.stack
	]]
	-- Reset the name.
	self.name = "AssertionError"
	return (self :: any) :: AssertionError
end

function AssertionError:toString()
	return ("%s [%s]: %s"):format(self.name, self.code, self.message)
end

AssertionError.name = "AssertionError"

return { AssertionError = AssertionError }

end,
["luau-polyfill/AssertionError"]=function()
local AssertionErrorModule = require(script:WaitForChild('AssertionError.global'))

export type AssertionError = AssertionErrorModule.AssertionError

return AssertionErrorModule.AssertionError

end,
["luau-polyfill/encodeURIComponent"]=function()
-- reference documentation: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
local HttpService = game:GetService("HttpService")

local String = require(script.Parent.Parent:WaitForChild('string'))
local charCodeAt = String.charCodeAt
local Error = require(script.Parent:WaitForChild('Error'))

local function encodeURIComponent(value: string): string
	local valueLength = utf8.len(value)
	if valueLength == 0 or valueLength == nil then
		return ""
	end
	-- we don't exhaustively test the whole string for invalid characters like ECMA-262 15.1.3 says
	local check = charCodeAt(value, 1)
	if valueLength == 1 then
		if check == 0xD800 then
			error(Error.new("URI malformed"))
		end
		if check == 0xDFFF then
			error(Error.new("URI malformed"))
		end
	end
	if check >= 0xDC00 and check < 0xDFFF then
		error(Error.new("URI malformed"))
	end
	local encoded = HttpService:UrlEncode(value)
	-- reverting encoded chars which are not encoded by JS
	local result = encoded
		:gsub("%%2D", "-")
		:gsub("%%5F", "_")
		:gsub("%%2E", ".")
		:gsub("%%21", "!")
		:gsub("%%7E", "~")
		:gsub("%%2A", "*")
		:gsub("%%27", "'")
		:gsub("%%28", "(")
		:gsub("%%29", ")")
	return result
end

return encodeURIComponent

end,
["luau-polyfill/Error/Error.global"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))

type Function = types.Function

export type Error = { name: string, message: string, stack: string? }
type Error_private = Error & { __stack: string? }

local Error = {}

local DEFAULT_NAME = "Error"
Error.__index = Error
Error.__tostring = function(self)
	-- Luau FIXME: I can't cast to Error or Object here: Type 'Object' could not be converted into '{ @metatable *unknown*, {|  |} }'
	return getmetatable(Error :: any).__tostring(self)
end

-- ROBLOX NOTE: extracted __createError function so that both Error.new() and Error() can capture the stack trace at the same depth
local function __createError(message: string?): Error
	local self = (setmetatable({
		name = DEFAULT_NAME,
		message = message or "",
	}, Error) :: any) :: Error
	Error.__captureStackTrace(self, 4)
	return self
end

function Error.new(message: string?): Error
	return __createError(message)
end

function Error.captureStackTrace(err: Error, options: Function?)
	Error.__captureStackTrace(err, 3, options)
end

function Error.__captureStackTrace(err_: Error, level: number, options: Function?)
	local err = err_ :: Error_private
	if typeof(options) == "function" then
		local stack = debug.traceback(nil, level)
		local functionName: string = debug.info(options, "n")
		local sourceFilePath: string = debug.info(options, "s")

		local espacedSourceFilePath = string.gsub(sourceFilePath, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
		local stacktraceLinePattern = espacedSourceFilePath .. ":%d* function " .. functionName
		local beg = string.find(stack, stacktraceLinePattern)
		local end_ 		
if beg ~= nil then
			beg, end_ = string.find(stack, "\n", beg + 1)
		end
		if end_ ~= nil then
			stack = string.sub(stack, end_ + 1)
		end
		err.__stack = stack
	else
		err.__stack = debug.traceback(nil, level)
	end
	Error.__recalculateStacktrace(err)
end

function Error.__recalculateStacktrace(err_: Error)
	local err = err_ :: Error_private
	local message = err.message
	local name = err.name or DEFAULT_NAME

	local errName = name .. (if message ~= nil and message ~= "" then (": " .. message) else "")
	local stack = if err.__stack then err.__stack else ""

	err.stack = errName .. "\n" .. stack
end

return setmetatable(Error, {
	__call = function(_, ...)
		return __createError(...)
	end,
	__tostring = function(self)
		if self.name ~= nil then
			if self.message and self.message ~= "" then
				return string.format("%s: %s", tostring(self.name), tostring(self.message))
			end
			return tostring(self.name)
		end
		return tostring(DEFAULT_NAME)
	end,
})

end,
["luau-polyfill/Error"]=function()
local Error = require(script:WaitForChild('Error.global'))
export type Error = Error.Error
return Error

end,
["luau-polyfill/extends"]=function()
--!nonstrict
--[[
	deviation: Our constructors currently have no notion of 'super' so any
	such behavior in upstream JS must be implemented manually by setting fields

	A constructor passed to this class would typically look along the lines of:
	function(self, arg, otherArg)
		self.arg = arg
		self.otherArg = otherArg
	end

	But even something like function() end can be passed in as the constructor
	if no fields need to be set. In upstream JS, the equivalent would be
	returning an empty object from the constructor.
]]
return function(parent, childName, constructor)
	local Child = {}
	Child.__index = Child
	Child.__tostring = function(self)
		return getmetatable(parent).__tostring(self)
	end

	local mt = {}

	Child.new = function(...)
		local self = {}
		constructor(self, ...)
		return setmetatable(self, Child)
	end

	if typeof(getmetatable(parent)) == "table" and getmetatable(parent).__call then
		mt.__call = function(_, ...)
			return Child.new(...)
		end
	end

	mt.__index = parent
	mt.__tostring = function(self)
		-- Printing class name
		if self == Child then
			return tostring(childName)
		end
		return getmetatable(parent).__tostring(self)
	end

	setmetatable(Child, mt)

	return Child
end

end,
["luau-polyfill"]=function()
local Boolean = require(script.Parent:WaitForChild('boolean'))
local Collections = require(script.Parent:WaitForChild('collections'))
local Console = require(script.Parent:WaitForChild('console'))
local Math = require(script.Parent:WaitForChild('math'))
local Number = require(script.Parent:WaitForChild('number'))
local String = require(script.Parent:WaitForChild('string'))
local Symbol = require(script.Parent:WaitForChild('symbol-luau'))
local Timers = require(script.Parent:WaitForChild('timers'))
local types = require(script.Parent:WaitForChild('es7-types'))

local AssertionError = require(script:WaitForChild('AssertionError'))
local Error = require(script:WaitForChild('Error'))
local PromiseModule = require(script:WaitForChild('Promise'))
local extends = require(script:WaitForChild('extends'))
local instanceof = require(script.Parent:WaitForChild('instance-of'))

export type Array<T> = types.Array<T>
export type AssertionError = AssertionError.AssertionError
export type Error = Error.Error
export type Map<T, V> = types.Map<T, V>
export type Object = types.Object

export type PromiseLike<T> = PromiseModule.PromiseLike<T>
export type Promise<T> = PromiseModule.Promise<T>

export type Set<T> = types.Set<T>
export type Symbol = Symbol.Symbol
export type Timeout = Timers.Timeout
export type Interval = Timers.Interval
export type WeakMap<T, V> = Collections.WeakMap<T, V>

return {
	Array = Collections.Array,
	AssertionError = AssertionError,
	Boolean = Boolean,
	console = Console,
	Error = Error,
	extends = extends,
	instanceof = instanceof,
	Math = Math,
	Number = Number,
	Object = Collections.Object,
	Map = Collections.Map,
	coerceToMap = Collections.coerceToMap,
	coerceToTable = Collections.coerceToTable,
	Set = Collections.Set,
	WeakMap = Collections.WeakMap,
	String = String,
	Symbol = Symbol,
	setTimeout = Timers.setTimeout,
	clearTimeout = Timers.clearTimeout,
	setInterval = Timers.setInterval,
	clearInterval = Timers.clearInterval,
	util = {
		inspect = Collections.inspect,
	},
}

end,
["luau-polyfill/Promise"]=function()
-- this maps onto community promise libraries which won't support Luau, so we inline
export type PromiseLike<T> = {
	andThen: (
		self: PromiseLike<T>,
		resolve: ((T) -> ...(nil | T | PromiseLike<T>))?,
		reject: ((any) -> ...(nil | T | PromiseLike<T>))?
	) -> PromiseLike<T>
}

type PromiseStatus = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type Promise<T> = {
	andThen: (
		self: Promise<T>,
		resolve: ((T) -> ...(nil | T | PromiseLike<T>))?,
		reject: ((any) -> ...(nil | T | PromiseLike<T>))?
	) -> Promise<T>,

	catch: (Promise<T>, ((any) -> ...(nil | T | PromiseLike<nil>))) -> Promise<T>,

	onCancel: (Promise<T>, (() -> ())?) -> boolean,

	expect: (Promise<T>) -> ...T,

	-- FIXME Luau: need union type packs to parse  (...T) | () | PromiseLike<T> here
	await: (Promise<T>) -> (boolean, ...(T | any)),

	getStatus: (self: Promise<T>) -> PromiseStatus,
	-- FIXME Luau: need union type packs to parse  (...T) | () | PromiseLike<T> here
	awaitStatus: (self: Promise<T>) -> (PromiseStatus, ...(T | any))
}

return {}

end,
}

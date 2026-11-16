-- jsdotlua/collections@1.2.7; see THIRD_PARTY_NOTICES.md
return {
["collections/Array/concat"]=function()
local __DEV__ = _G.__DEV__
local isArray = require(script.Parent:WaitForChild('isArray'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

local RECEIVED_OBJECT_ERROR = [[Array.concat(...) only works with array-like tables but it received an object-like table.
You can avoid this error by wrapping the object-like table into an array. Example: `concat({1, 2}, {a = true})` should be `concat({1, 2}, { {a = true} }`]]
-- capture two separate generic arguments so that the type error in abuse cases is actionable, but needs CLI-49876 to avoid a false negative



local function concat<T, S>(source: Array<T> | T, ...: Array<S> | S): Array<T> & Array<S>
	local array
	local elementCount = 0

	if isArray(source) then
		array = table.clone(source :: Array<T>)
		elementCount = #(source :: Array<T>)
	else
		elementCount += 1
		array = {}
		array[elementCount] = source :: T
	end

	for i = 1, select("#", ...) do
		local value = select(i, ...)
		local valueType = typeof(value)
		if value == nil then
			-- do not insert nil
		elseif valueType == "table" then
			-- deviation: assume that table is an array, to avoid the expensive
			-- `isArray` check. In DEV mode, we throw if it is given an object-like
			-- table.
			if __DEV__ then
				if not isArray(value) then
					error(RECEIVED_OBJECT_ERROR)
				end
			end
			for k = 1, #value do
				elementCount += 1
				array[elementCount] = value[k]
			end
		else
			elementCount += 1
			array[elementCount] = value
		end
	end

	return (array :: any) :: Array<T> & Array<S>
end

return concat

end,
["collections/Array/every"]=function()
local __DEV__ = _G.__DEV__
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object
type callbackFn<T> = (element: T, index: number, array: Array<T>) -> boolean
type callbackFnWithThisArg<T, U> = (self: U, element: T, index: number, array: Array<T>) -> boolean

-- Implements Javascript's `Array.prototype.every` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/every
return function<T, U>(t: Array<T>, callback: callbackFn<T> | callbackFnWithThisArg<T, U>, thisArg: U?): boolean
	if __DEV__ then
		if typeof(t) ~= "table" then
			error(string.format("Array.every called on %s", typeof(t)))
		end
		if typeof(callback) ~= "function" then
			error("callback is not a function")
		end
	end

	local len = #t
	local k = 1

	while k <= len do
		local kValue = t[k]
		local testResult

		if kValue ~= nil then
			if thisArg ~= nil then
				testResult = (callback :: callbackFnWithThisArg<T, U>)(thisArg, kValue, k, t)
			else
				testResult = (callback :: callbackFn<T>)(kValue, k, t)
			end

			if not testResult then
				return false
			end
		end
		k += 1
	end
	return true
end

end,
["collections/Array/filter"]=function()
local __DEV__ = _G.__DEV__
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object
type callbackFn<T> = (element: T, index: number, array: Array<T>) -> boolean
type callbackFnWithThisArg<T, U> = (thisArg: U, element: T, index: number, array: Array<T>) -> boolean

-- Implements Javascript's `Array.prototype.filter` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/filter
return function<T, U>(t: Array<T>, callback: callbackFn<T> | callbackFnWithThisArg<T, U>, thisArg: U?): Array<T>
	if __DEV__ then
		if typeof(t) ~= "table" then
			error(string.format("Array.filter called on %s", typeof(t)))
		end
		if typeof(callback) ~= "function" then
			error("callback is not a function")
		end
	end

	local len = #t
	local res = {}
	local index = 1

	if thisArg == nil then
		for i = 1, len do
			local kValue = t[i]
			if kValue ~= nil then
				if (callback :: callbackFn<T>)(kValue, i, t) then
					res[index] = kValue
					index += 1
				end
			end
		end
	else
		for i = 1, len do
			local kValue = t[i]
			if kValue ~= nil then
				if (callback :: callbackFnWithThisArg<T, U>)(thisArg, kValue, i, t) then
					res[index] = kValue
					index += 1
				end
			end
		end
	end

	return res
end

end,
["collections/Array/find"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type PredicateFunction<T> = (value: T, index: number, array: Array<T>) -> boolean

return function<T>(array: Array<T>, predicate: PredicateFunction<T>): T | nil
	for i = 1, #array do
		local element = array[i]
		if predicate(element, i, array) then
			return element
		end
	end
	return nil
end

end,
["collections/Array/findIndex"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type PredicateFunction<T> = (T, number, Array<T>) -> boolean

return function<T>(array: Array<T>, predicate: PredicateFunction<T>): number
	for i = 1, #array do
		local element = array[i]
		if predicate(element, i, array) then
			return i
		end
	end
	return -1
end

end,
["collections/Array/flat"]=function()
local __DEV__ = _G.__DEV__
local isArray = require(script.Parent:WaitForChild('isArray'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
local function flat<T>(array: Array<T>, depth_: number?): Array<T>
	if __DEV__ then
		if typeof(array) ~= "table" then
			error(string.format("Array.flat called on %s", typeof(array)))
		end
		if depth_ ~= nil and typeof(depth_) ~= "number" then
			error("depth is not a number or nil")
		end
	end
	local depth = depth_ or 1
	local newArray = {}

	for _, v in array do
		if isArray(v) then
			local vArray = (v :: any) :: Array<T>
			local innerArrFlat: Array<T> = if depth > 1 then flat(vArray, depth - 1) else vArray
			for _, innerValue in innerArrFlat do
				table.insert(newArray, innerValue)
			end
		else
			table.insert(newArray, v)
		end
	end

	return newArray
end

return flat

end,
["collections/Array/flatMap"]=function()
local __DEV__ = _G.__DEV__
local flat = require(script.Parent:WaitForChild('flat'))
local map = require(script.Parent:WaitForChild('map'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type callbackFn<T, U> = (element: T, index: number, array: Array<T>) -> U
type callbackFnWithThisArg<T, U, V> = (thisArg: V, element: T, index: number, array: Array<T>) -> U

local function flatMap<T, U, V>(
	array: Array<T>,
	callback: callbackFn<T, U> | callbackFnWithThisArg<T, U, V>,
	thisArg: V?
): Array<U>
	if __DEV__ then
		if typeof(array) ~= "table" then
			error(string.format("Array.flatMap called on %s", typeof(array)))
		end
		if typeof(callback) ~= "function" then
			error("callback is not a function")
		end
	end
	return flat(map(array, callback, thisArg))
end

return flatMap

end,
["collections/Array/forEach"]=function()
local __DEV__ = _G.__DEV__
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object
type callbackFn<T> = (element: T, index: number, array: Array<T>) -> ()
type callbackFnWithThisArg<T, U> = (thisArg: U, element: T, index: number, array: Array<T>) -> ()

-- Implements Javascript's `Array.prototype.forEach` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach
return function<T, U>(t: Array<T>, callback: callbackFn<T> | callbackFnWithThisArg<T, U>, thisArg: U?): ()
	if __DEV__ then
		if typeof(t) ~= "table" then
			error(string.format("Array.forEach called on %s", typeof(t)))
		end
		if typeof(callback) ~= "function" then
			error("callback is not a function")
		end
	end

	local len = #t
	local k = 1

	while k <= len do
		local kValue = t[k]

		if thisArg ~= nil then
			(callback :: callbackFnWithThisArg<T, U>)(thisArg, kValue, k, t)
		else
			(callback :: callbackFn<T>)(kValue, k, t)
		end

		if #t < len then
			-- don't iterate on removed items, don't iterate more than original length
			len = #t
		end
		k += 1
	end
end

end,
["collections/Array/from/fromArray"]=function()
local types = require(script.Parent.Parent.Parent.Parent:WaitForChild('es7-types'))
type Object = types.Object

type Array<T> = types.Array<T>
type mapFn<T, U> = (element: T, index: number) -> U
type mapFnWithThisArg<T, U> = (thisArg: any, element: T, index: number) -> U

return function<T, U>(
	value: Array<T>,
	mapFn: (mapFn<T, U> | mapFnWithThisArg<T, U>)?,
	thisArg: Object?
	-- FIXME Luau: need overloading so the return type on this is more sane and doesn't require manual casts
): Array<U> | Array<T> | Array<string>
	local array = {}

	if mapFn then
		local arrayLength = #(value :: Array<T>)
		array = table.create(arrayLength)
		for i = 1, arrayLength do
			if thisArg ~= nil then
				(array :: Array<U>)[i] = (mapFn :: mapFnWithThisArg<T, U>)(thisArg, (value :: Array<T>)[i], i)
			else
				(array :: Array<U>)[i] = (mapFn :: mapFn<T, U>)((value :: Array<T>)[i], i)
			end
		end
	else
		array = table.clone(value :: Array<T>)
	end

	return array
end

end,
["collections/Array/from/fromMap"]=function()
local types = require(script.Parent.Parent.Parent.Parent:WaitForChild('es7-types'))
type Object = types.Object
type Array<T> = types.Array<T>
type Map<K, V> = types.Map<K, V>
type mapFn<T, U> = (element: T, index: number) -> U
type mapFnWithThisArg<T, U> = (thisArg: any, element: T, index: number) -> U

return function<T, U>(
	value: Map<any, any>,
	mapFn: (mapFn<T, U> | mapFnWithThisArg<T, U>)?,
	thisArg: Object?
	-- FIXME Luau: need overloading so the return type on this is more sane and doesn't require manual casts
): Array<U> | Array<T> | Array<string>
	local array = {}

	if mapFn then
		array = {}
		for i, v in value :: any do
			if thisArg ~= nil then
				(array :: Array<U>)[i] = (mapFn :: mapFnWithThisArg<T, U>)(thisArg, v, i)
			else
				(array :: Array<U>)[i] = (mapFn :: mapFn<T, U>)(v, i)
			end
		end
	else
		array = {}
		for i, v in value :: any do
			(array :: Array<T>)[i] = v
		end
	end

	return array
end

end,
["collections/Array/from/fromSet"]=function()
local types = require(script.Parent.Parent.Parent.Parent:WaitForChild('es7-types'))
type Object = types.Object
type Array<T> = types.Array<T>
type Set<T> = types.Set<T>
type mapFn<T, U> = (element: T, index: number) -> U
type mapFnWithThisArg<T, U> = (thisArg: any, element: T, index: number) -> U

return function<T, U>(
	value: Set<T>,
	mapFn: (mapFn<T, U> | mapFnWithThisArg<T, U>)?,
	thisArg: Object?
	-- FIXME Luau: need overloading so the return type on this is more sane and doesn't require manual casts
): Array<U> | Array<T> | Array<string>
	local array = {}

	if mapFn then
		array = {}
		for i, v in value :: any do
			if thisArg ~= nil then
				(array :: Array<U>)[i] = (mapFn :: mapFnWithThisArg<T, U>)(thisArg, v, i)
			else
				(array :: Array<U>)[i] = (mapFn :: mapFn<T, U>)(v, i)
			end
		end
	else
		array = table.clone((value :: any)._array)
	end

	return array
end

end,
["collections/Array/from/fromString"]=function()
local types = require(script.Parent.Parent.Parent.Parent:WaitForChild('es7-types'))
type Object = types.Object
type Array<T> = types.Array<T>

type mapFn<T, U> = (element: T, index: number) -> U
type mapFnWithThisArg<T, U> = (thisArg: any, element: T, index: number) -> U

return function<T, U>(
	value: string,
	mapFn: (mapFn<T, U> | mapFnWithThisArg<T, U>)?,
	thisArg: Object?
	-- FIXME Luau: need overloading so the return type on this is more sane and doesn't require manual casts
): Array<U> | Array<T> | Array<string>
	local array = {}

	local valueStringLength = #value
	array = table.create(valueStringLength)
	if mapFn then
		for i = 1, valueStringLength do
			if thisArg ~= nil then
				(array :: Array<U>)[i] = (mapFn :: mapFnWithThisArg<T, U>)(thisArg, string.sub(value, i, i) :: any, i)
			else
				(array :: Array<U>)[i] = (mapFn :: mapFn<T, U>)(string.sub(value, i, i) :: any, i)
			end
		end
	else
		for i = 1, valueStringLength do
			(array :: Array<string>)[i] = string.sub(value, i, i)
		end
	end

	return array
end

end,
["collections/Array/from"]=function()
local Set = require(script.Parent.Parent:WaitForChild('Set'))
local Map = require(script.Parent.Parent:WaitForChild('Map'):WaitForChild('Map'))
local isArray = require(script.Parent:WaitForChild('isArray'))
local instanceof = require(script.Parent.Parent.Parent:WaitForChild('instance-of'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))

local fromString = require(script:WaitForChild('fromString'))
local fromSet = require(script:WaitForChild('fromSet'))
local fromMap = require(script:WaitForChild('fromMap'))
local fromArray = require(script:WaitForChild('fromArray'))

type Array<T> = types.Array<T>
type Object = types.Object
type Set<T> = types.Set<T>
type Map<K, V> = types.Map<K, V>
type mapFn<T, U> = (element: T, index: number) -> U
type mapFnWithThisArg<T, U> = (thisArg: any, element: T, index: number) -> U

return function<T, U>(
	value: string | Array<T> | Set<T> | Map<any, any>,
	mapFn: (mapFn<T, U> | mapFnWithThisArg<T, U>)?,
	thisArg: Object?
	-- FIXME Luau: need overloading so the return type on this is more sane and doesn't require manual casts
): Array<U> | Array<T> | Array<string>
	if value == nil then
		error("cannot create array from a nil value")
	end
	local valueType = typeof(value)

	local array: Array<U> | Array<T> | Array<string>

	if valueType == "table" and isArray(value) then
		array = fromArray(value :: Array<T>, mapFn, thisArg)
	elseif instanceof(value, Set) then
		array = fromSet(value :: Set<T>, mapFn, thisArg)
	elseif instanceof(value, Map) then
		array = fromMap(value :: Map<any, any>, mapFn, thisArg)
	elseif valueType == "string" then
		array = fromString(value :: string, mapFn, thisArg)
	else
		array = {}
	end

	return array
end

end,
["collections/Array/includes"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
local indexOf = require(script.Parent:WaitForChild('indexOf'))

return function<T>(array: Array<T>, searchElement: T, fromIndex: number?): boolean
	return indexOf(array, searchElement, fromIndex) ~= -1
end

end,
["collections/Array/indexOf"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

-- Implements equivalent functionality to JavaScript's `array.indexOf`,
-- implementing the interface and behaviors defined at:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf
--
-- This implementation is loosely based on the one described in the polyfill
-- source in the above link
return function<T>(array: Array<T>, searchElement: T, fromIndex: number?): number
	local fromIndex_ = fromIndex or 1
	local length = #array

	-- In the JS impl, a negative fromIndex means we should use length - index;
	-- with Lua, of course, this means that 0 is still valid, but refers to the
	-- end of the array the way that '-1' would in JS
	if fromIndex_ < 1 then
		fromIndex_ = math.max(length - math.abs(fromIndex_), 1)
	end

	for i = fromIndex_, length do
		if array[i] == searchElement then
			return i
		end
	end

	return -1
end

end,
["collections/Array"]=function()
local ES7Types = require(script.Parent.Parent:WaitForChild('es7-types'))

export type Array<T> = ES7Types.Array<T>

return {
	concat = require(script:WaitForChild('concat')),
	every = require(script:WaitForChild('every')),
	filter = require(script:WaitForChild('filter')),
	find = require(script:WaitForChild('find')),
	findIndex = require(script:WaitForChild('findIndex')),
	flat = require(script:WaitForChild('flat')),
	flatMap = require(script:WaitForChild('flatMap')),
	forEach = require(script:WaitForChild('forEach')),
	from = require(script:WaitForChild('from')),
	includes = require(script:WaitForChild('includes')),
	indexOf = require(script:WaitForChild('indexOf')),
	isArray = require(script:WaitForChild('isArray')),
	join = require(script:WaitForChild('join')),
	map = require(script:WaitForChild('map')),
	reduce = require(script:WaitForChild('reduce')),
	reverse = require(script:WaitForChild('reverse')),
	shift = require(script:WaitForChild('shift')),
	slice = require(script:WaitForChild('slice')),
	some = require(script:WaitForChild('some')),
	sort = require(script:WaitForChild('sort')),
	splice = require(script:WaitForChild('splice')),
	unshift = require(script:WaitForChild('unshift')),
}

end,
["collections/Array/isArray"]=function()
return function(value: any): boolean
	if typeof(value) ~= "table" then
		return false
	end
	if next(value) == nil then
		-- an empty table is an empty array
		return true
	end

	local length = #value

	if length == 0 then
		return false
	end

	local count = 0
	local sum = 0
	for key in pairs(value) do
		if typeof(key) ~= "number" then
			return false
		end
		if key % 1 ~= 0 or key < 1 then
			return false
		end
		count += 1
		sum += key
	end

	return sum == (count * (count + 1) / 2)
end

end,
["collections/Array/join"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
local map = require(script.Parent:WaitForChild('map'))

return function<T>(arr: Array<T>, separator: string?): string
	if #arr == 0 then
		return ""
	end
	-- JS does tostring conversion implicitely but in Lua we need to do that explicitely
	local stringifiedArray = map(arr, function(item)
		return tostring(item)
	end)

	return table.concat(stringifiedArray, separator or ",")
end

end,
["collections/Array/map"]=function()
local __DEV__ = _G.__DEV__
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object
type callbackFn<T, U> = (element: T, index: number, array: Array<T>) -> U
type callbackFnWithThisArg<T, U, V> = (thisArg: V, element: T, index: number, array: Array<T>) -> U

-- Implements Javascript's `Array.prototype.map` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map
return function<T, U, V>(t: Array<T>, callback: callbackFn<T, U> | callbackFnWithThisArg<T, U, V>, thisArg: V?): Array<U>
	if __DEV__ then
		if typeof(t) ~= "table" then
			error(string.format("Array.map called on %s", typeof(t)))
		end
		if typeof(callback) ~= "function" then
			error("callback is not a function")
		end
	end

	local len = #t
	local A = {}
	local k = 1

	while k <= len do
		local kValue = t[k]

		if kValue ~= nil then
			local mappedValue

			if thisArg ~= nil then
				mappedValue = (callback :: callbackFnWithThisArg<T, U, V>)(thisArg, kValue, k, t)
			else
				mappedValue = (callback :: callbackFn<T, U>)(kValue, k, t)
			end

			A[k] = mappedValue
		end
		k += 1
	end

	return A
end

end,
["collections/Array/reduce"]=function()
local __DEV__ = _G.__DEV__
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type reduceFn<T, U> = (previousValue: U, currentValue: T, currentIndex: number, array: Array<T>) -> U

-- Implements Javascript's `Array.prototype.reduce` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce
-- TODO Luau: when Luau supports overloads, use them here so that reduceFn can correctly use T when initialValue (U) isn't supplied
return function<T, U>(array: Array<T>, callback: reduceFn<T, U>, initialValue: U?): U
	if __DEV__ then
		if typeof(array) ~= "table" then
			error(string.format("Array.reduce called on %s", typeof(array)))
		end
		if typeof(callback) ~= "function" then
			error("callback is not a function")
		end
	end

	local length = #array

	local value: T | U
	local initial = 1

	if initialValue ~= nil then
		value = initialValue
	else
		initial = 2
		if length == 0 then
			error("reduce of empty array with no initial value")
		end
		value = array[1]
	end

	for i = initial, length do
		value = callback(value :: U, array[i], i, array)
	end

	return value :: U
end

end,
["collections/Array/reverse"]=function()
-- https://programming-idioms.org/idiom/19/reverse-a-list/1314/lua
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

return function<T>(t: Array<T>): Array<T>
	local n = #t
	local i = 1
	while i < n do
		t[i], t[n] = t[n], t[i]
		i = i + 1
		n = n - 1
	end
	return t
end

end,
["collections/Array/shift"]=function()
local __DEV__ = _G.__DEV__
local isArray = require(script.Parent:WaitForChild('isArray'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

return function<T>(value: Array<T>): T?
	if __DEV__ then
		if not isArray(value) then
			error(string.format("Array.shift called on non-array %s", typeof(value)))
		end
	end

	if #value > 0 then
		return table.remove(value, 1)
	else
		return nil
	end
end

end,
["collections/Array/slice"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

-- Implements Javascript's `Array.prototype.slice` as defined below, but with 1-indexing
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/slice
return function<T>(t: Array<T>, start_idx: number?, end_idx: number?): Array<T>
	if typeof(t) ~= "table" then
		error(string.format("Array.slice called on %s", typeof(t)))
	end
	local length = #t

	local start_idx_ = start_idx or 1
	local end_idx_
	if end_idx == nil or end_idx > length + 1 then
		end_idx_ = length + 1
	else
		end_idx_ = end_idx
	end

	if start_idx_ > length + 1 then
		return {}
	end

	local slice = {}

	if start_idx_ < 1 then
		start_idx_ = math.max(length - math.abs(start_idx_), 1)
	end
	if end_idx_ < 1 then
		end_idx_ = math.max(length - math.abs(end_idx_), 1)
	end

	local idx = start_idx_
	local i = 1
	while idx < end_idx_ do
		slice[i] = t[idx]
		idx = idx + 1
		i = i + 1
	end

	return slice
end

end,
["collections/Array/some"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object

-- note: JS version can return anything that's truthy, but that won't work for us since Lua deviates (0 is truthy)
type callbackFn<T> = (element: T, index: number, array: Array<T>) -> boolean
type callbackFnWithThisArg<T, U> = (thisArg: U, element: T, index: number, array: Array<T>) -> boolean

-- Implements Javascript's `Array.prototype.map` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/some
return function<T, U>(t: Array<T>, callback: callbackFn<T> | callbackFnWithThisArg<T, U>, thisArg: U?): boolean
	if typeof(t) ~= "table" then
		error(string.format("Array.some called on %s", typeof(t)))
	end
	if typeof(callback) ~= "function" then
		error("callback is not a function")
	end

	for i, value in t do
		if thisArg ~= nil then
			if value ~= nil and (callback :: callbackFnWithThisArg<T, U>)(thisArg, value, i, t) then
				return true
			end
		else
			if value ~= nil and (callback :: callbackFn<T>)(value, i, t) then
				return true
			end
		end
	end
	return false
end

end,
["collections/Array/sort"]=function()
local None = require(script.Parent.Parent:WaitForChild('Object'):WaitForChild('None'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Comparable = (any, any) -> number
local defaultSort = function<T>(a: T, b: T): boolean
	return type(a) .. tostring(a) < type(b) .. tostring(b)
end

return function<T>(array: Array<T>, compare: Comparable?): Array<T>
	-- wrapperCompare interprets compare return value to be compatible with Lua's table.sort
	local wrappedCompare = defaultSort
	if compare ~= nil and compare ~= None then
		if typeof(compare :: any) ~= "function" then
			error("invalid argument to Array.sort: compareFunction must be a function")
		end
		wrappedCompare = function<T>(a: T, b: T)
			local result = compare(a, b)
			if typeof(result) ~= "number" then
				-- deviation: throw an error because
				-- it's not clearly defined what is
				-- the behavior when the compare function
				-- does not return a number
				error(("invalid result from compare function, expected number but got %s"):format(typeof(result)))
			end
			return result < 0
		end
	end
	table.sort(array, wrappedCompare)
	return array
end

end,
["collections/Array/splice"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

-- Implements equivalent functionality to JavaScript's `array.splice`, including
-- the interface and behaviors defined at:
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/splice
return function<T>(array: Array<T>, start: number, deleteCount: number?, ...: T): Array<T>
	-- Append varargs without removing anything
	if start > #array then
		local varargCount = select("#", ...)
		for i = 1, varargCount do
			local toInsert = select(i, ...)
			table.insert(array, toInsert)
		end
		return {}
	else
		local length = #array
		-- In the JS impl, a negative fromIndex means we should use length -
		-- index; with Lua, of course, this means that 0 is still valid, but
		-- refers to the end of the array the way that '-1' would in JS
		if start < 1 then
			start = math.max(length - math.abs(start), 1)
		end

		local deletedItems = {} :: Array<T>
		-- If no deleteCount was provided, we want to delete the rest of the
		-- array starting with `start`
		local deleteCount_: number = deleteCount or length
		if deleteCount_ > 0 then
			local lastIndex = math.min(length, start + math.max(0, deleteCount_ - 1))

			for i = start, lastIndex do
				local deleted = table.remove(array, start) :: T
				table.insert(deletedItems, deleted)
			end
		end

		local varargCount = select("#", ...)
		-- Do this in reverse order so we can always insert in the same spot
		for i = varargCount, 1, -1 do
			local toInsert = select(i, ...)
			table.insert(array, start, toInsert)
		end

		return deletedItems
	end
end

end,
["collections/Array/unshift"]=function()
local __DEV__ = _G.__DEV__
local isArray = require(script.Parent:WaitForChild('isArray'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

return function<T>(array: Array<T>, ...: T): number
	if __DEV__ then
		if not isArray(array) then
			error(string.format("Array.unshift called on non-array %s", typeof(array)))
		end
	end

	local numberOfItems = select("#", ...)
	if numberOfItems > 0 then
		for i = numberOfItems, 1, -1 do
			local toInsert = select(i, ...)
			table.insert(array, 1, toInsert)
		end
	end

	return #array
end

end,
["collections"]=function()
local Array = require(script:WaitForChild('Array'))
local Map = require(script:WaitForChild('Map'))
local Object = require(script:WaitForChild('Object'))
local Set = require(script:WaitForChild('Set'))
local WeakMap = require(script:WaitForChild('WeakMap'))
local inspect = require(script:WaitForChild('inspect'))

local types = require(script.Parent:WaitForChild('es7-types'))

export type Array<T> = types.Array<T>
export type Map<T, V> = types.Map<T, V>
export type Object = types.Object
export type Set<T> = types.Set<T>
export type WeakMap<T, V> = types.WeakMap<T, V>

return {
	Array = Array,
	Object = Object,
	Map = Map.Map,
	coerceToMap = Map.coerceToMap,
	coerceToTable = Map.coerceToTable,
	Set = Set,
	WeakMap = WeakMap,
	inspect = inspect,
}

end,
["collections/inspect"]=function()
-- derived from these upstream sources:
-- https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/inspect.js
local HttpService = game:GetService("HttpService")

local isArray = require(script.Parent:WaitForChild('Array'):WaitForChild('isArray'))
local ES7Types = require(script.Parent.Parent:WaitForChild('es7-types'))

type Array<T> = ES7Types.Array<T>
-- local NULL = require(srcWorkspace.luaUtils.null)

-- Support for options partial implementation
-- see: https://nodejs.org/dist/latest-v16.x/docs/api/util.html#utilinspectobject-options
export type InspectOptions = {
	depth: number?
}

type FormatOptions = {
	depth: number
}

local MAX_ARRAY_LENGTH = 10
local DEFAULT_RECURSIVE_DEPTH = 2

-- deviation: pre-declare functions
local formatValue
local formatObjectValue
local formatArray
local formatObject
local getObjectTag

--[[
 * Used to print values in error messages.
 ]]
local function inspect(value, options: InspectOptions?): string
	local inspectOptions: InspectOptions = options or { depth = DEFAULT_RECURSIVE_DEPTH }
	local depth = inspectOptions.depth or DEFAULT_RECURSIVE_DEPTH
	inspectOptions.depth = if depth >= 0 then depth else DEFAULT_RECURSIVE_DEPTH
	return formatValue(value, {}, inspectOptions :: FormatOptions)
end

local function isIndexKey(k, contiguousLength)
	return type(k) == "number"
		and k <= contiguousLength -- nothing out of bounds
		and 1 <= k -- nothing illegal for array indices
		and math.floor(k) == k -- no float keys
end

local function getTableLength(tbl)
	local length = 1
	local value = rawget(tbl, length)
	while value ~= nil do
		length += 1
		value = rawget(tbl, length)
	end
	return length - 1
end

local function sortKeysForPrinting(a: any, b)
	local typeofA = type(a)
	local typeofB = type(b)

	-- strings and numbers are sorted numerically/alphabetically
	if typeofA == typeofB and (typeofA == "number" or typeofA == "string") then
		return a < b
	end

	-- sort the rest by type name
	return typeofA < typeofB
end

local function rawpairs(t)
	return next, t, nil
end

local function getFragmentedKeys(tbl)
	local keys = {}
	local keysLength = 0
	local tableLength = getTableLength(tbl)
	for key, _ in rawpairs(tbl) do
		if not isIndexKey(key, tableLength) then
			keysLength = keysLength + 1
			keys[keysLength] = key
		end
	end
	table.sort(keys, sortKeysForPrinting)
	return keys, keysLength, tableLength
end

function formatValue(value, seenValues, options: FormatOptions)
	local valueType = typeof(value)
	if valueType == "string" then
		return HttpService:JSONEncode(value)
		-- deviation: format numbers like in JS
	elseif valueType == "number" then
		if value ~= value then
			return "NaN"
		elseif value == math.huge then
			return "Infinity"
		elseif value == -math.huge then
			return "-Infinity"
		else
			return tostring(value)
		end
	elseif valueType == "function" then
		local result = "[function"
		local functionName = debug.info(value :: (any) -> any, "n")
		if functionName ~= nil and functionName ~= "" then
			result ..= " " .. functionName
		end
		return result .. "]"
	elseif valueType == "table" then
		-- ROBLOX TODO: parameterize inspect with the library-specific NULL sentinel. maybe function generics?
		-- if value == NULL then
		-- 	return 'null'
		-- end
		return formatObjectValue(value, seenValues, options)
	else
		return tostring(value)
	end
end

function formatObjectValue(value, previouslySeenValues, options: FormatOptions)
	if table.find(previouslySeenValues, value) ~= nil then
		return "[Circular]"
	end

	local seenValues = { unpack(previouslySeenValues) }
	table.insert(seenValues, value)

	if typeof(value.toJSON) == "function" then
		local jsonValue = value:toJSON(value)

		if jsonValue ~= value then
			if typeof(jsonValue) == "string" then
				return jsonValue
			else
				return formatValue(jsonValue, seenValues, options)
			end
		end
	elseif isArray(value) then
		return formatArray(value, seenValues, options)
	end

	return formatObject(value, seenValues, options)
end

function formatObject(object, seenValues, options: FormatOptions)
	local result = ""
	local mt = getmetatable(object)
	if mt and rawget(mt, "__tostring") then
		return tostring(object)
	end

	local fragmentedKeys, fragmentedKeysLength, keysLength = getFragmentedKeys(object)

	if keysLength == 0 and fragmentedKeysLength == 0 then
		result ..= "{}"
		return result
	end
	if #seenValues > options.depth then
		result ..= "[" .. getObjectTag(object) .. "]"
		return result
	end

	local properties = {}
	for i = 1, keysLength do
		local value = formatValue(object[i], seenValues, options)

		table.insert(properties, value)
	end

	for i = 1, fragmentedKeysLength do
		local key = fragmentedKeys[i]
		local value = formatValue(object[key], seenValues, options)

		table.insert(properties, key .. ": " .. value)
	end

	result ..= "{ " .. table.concat(properties, ", ") .. " }"
	return result
end

function formatArray(array: Array<any>, seenValues: Array<any>, options: FormatOptions): string
	local length = #array
	if length == 0 then
		return "[]"
	end
	if #seenValues > options.depth then
		return "[Array]"
	end

	local len = math.min(MAX_ARRAY_LENGTH, length)
	local remaining = length - len
	local items = {}

	for i = 1, len do
		items[i] = (formatValue(array[i], seenValues, options))
	end

	if remaining == 1 then
		table.insert(items, "... 1 more item")
	elseif remaining > 1 then
		table.insert(items, ("... %s more items"):format(tostring(remaining)))
	end

	return "[" .. table.concat(items, ", ") .. "]"
end

function getObjectTag(_object): string
	-- local tag = Object.prototype.toString
	-- 	.call(object)
	-- 	.replace("")
	-- 	.replace("")

	-- if tag == "Object" and typeof(object.constructor) == "function" then
	-- 	local name = object.constructor.name

	-- 	if typeof(name) == "string" and name ~= "" then
	-- 		return name
	-- 	end
	-- end

	-- return tag
	return "Object"
end

return inspect

end,
["collections/Map/coerceToMap"]=function()
local Map = require(script.Parent:WaitForChild('Map'))
local Object = require(script.Parent.Parent:WaitForChild('Object'))
local instanceOf = require(script.Parent.Parent.Parent:WaitForChild('instance-of'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))

type Map<K, V> = types.Map<K, V>
type Table<K, V> = types.Table<K, V>

local function coerceToMap(mapLike: Map<any, any> | Table<any, any>): Map<any, any>
	return instanceOf(mapLike, Map) and mapLike :: Map<any, any> -- ROBLOX: order is preserved
		or Map.new(Object.entries(mapLike)) -- ROBLOX: order is not preserved
end

return coerceToMap

end,
["collections/Map/coerceToTable"]=function()
local Map = require(script.Parent:WaitForChild('Map'))
local instanceOf = require(script.Parent.Parent.Parent:WaitForChild('instance-of'))
local arrayReduce = require(script.Parent.Parent:WaitForChild('Array'):WaitForChild('reduce'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))

type Map<K, V> = types.Map<K, V>
type Table<K, V> = types.Table<K, V>

local function coerceToTable(mapLike: Map<any, any> | Table<any, any>): Table<any, any>
	if not instanceOf(mapLike, Map) then
		return mapLike :: Table<any, any>
	end

	-- create table from map
	return arrayReduce(mapLike:entries(), function(tbl, entry)
		tbl[entry[1] ] = entry[2]
		return tbl
	end, {})
end

return coerceToTable

end,
["collections/Map"]=function()
local ES7Types = require(script.Parent.Parent:WaitForChild('es7-types'))

local Map = require(script:WaitForChild('Map'))
local coerceToMap = require(script:WaitForChild('coerceToMap'))
local coerceToTable = require(script:WaitForChild('coerceToTable'))

export type Map<K, V> = ES7Types.Map<K, V>

return {
	Map = Map,
	coerceToMap = coerceToMap,
	coerceToTable = coerceToTable,
}

end,
["collections/Map/Map"]=function()
local __DEV__ = _G.__DEV__

local arrayForEach = require(script.Parent.Parent:WaitForChild('Array'):WaitForChild('forEach'))
local arrayMap = require(script.Parent.Parent:WaitForChild('Array'):WaitForChild('map'))
local isArray = require(script.Parent.Parent:WaitForChild('Array'):WaitForChild('isArray'))
local instanceof = require(script.Parent.Parent.Parent:WaitForChild('instance-of'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Object = types.Object
type Array<T> = types.Array<T>
type Table<T, V> = types.Table<T, V>
type Tuple<T, V> = types.Tuple<T, V>
type mapCallbackFn<K, V> = types.mapCallbackFn<K, V>
type mapCallbackFnWithThisArg<K, V> = types.mapCallbackFnWithThisArg<K, V>
type Map<K, V> = types.Map<K, V>

type Map_Statics = {
	new: <K, V>(iterable: Array<Array<any>>?) -> Map<K, V>
}

local Map: Map<any, any> & Map_Statics = ({} :: any) :: Map<any, any> & Map_Statics

function Map.new<K, V>(iterable: (Array<Array<any>> | Map<K, V>)?): Map<K, V>
	local array
	local map
	if iterable == nil then
		array = {}
		map = {}
	elseif isArray(iterable) then
		if __DEV__ then
			if #(iterable :: Array<Array<any>>) > 0 and typeof((iterable :: Array<Array<any>>)[1]) ~= "table" then
				error(
					"Value `"
						.. typeof((iterable :: Array<Array<any>>)[1])
						.. [[` is not an entry object.
 Cannot create Map from {K, V} form, it must be { {K, V}... }]]				
)
			end
		end
		array = table.create(#(iterable :: Array<Array<any>>))
		map = {}
		for _, entry in iterable :: Array<Array<any>> do
			local key = entry[1]
			if __DEV__ then
				if key == nil then
					error("cannot create Map from a table that isn't an array.")
				end
			end
			local val = entry[2]
			-- only add to array if new
			if map[key] == nil then
				table.insert(array, key)
			end
			-- always assign
			map[key] = val
		end
	elseif instanceof(iterable, Map) then
		array = table.clone((iterable :: Map<K, V>)._array)
		map = table.clone((iterable :: Map<K, V>)._map)
	else
		error(("`%s` `%s` is not iterable, cannot make Map using it"):format(typeof(iterable), tostring(iterable)))
	end

	return (setmetatable({
		size = #array,
		_map = map,
		_array = array,
	}, Map) :: any) :: Map<K, V>
end

-- TODO Luau: annoying type erasure here, probably needs the new Records language feature
function Map:set(key: any, value: any): Map<any, any>
	-- preserve initial insertion order
	if self._map[key] == nil then
		-- Luau FIXME: analyze should know self is Map<K, V> which includes size as a number
		self.size = self.size :: number + 1
		table.insert(self._array, key)
	end
	-- always update value
	self._map[key] = value
	return self
end

function Map:get(key)
	return self._map[key]
end

function Map:clear()
	local table_: any = table
	self.size = 0
	table_.clear(self._map)
	table_.clear(self._array)
end

function Map:delete(key): boolean
	if self._map[key] == nil then
		return false
	end
	-- Luau FIXME: analyze should know self is Map<K, V> which includes size as a number
	self.size = self.size :: number - 1
	self._map[key] = nil
	local index = table.find(self._array, key)
	if index then
		table.remove(self._array, index)
	end
	return true
end

-- Implements Javascript's `Map.prototype.forEach` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map/forEach
function Map:forEach(callback: mapCallbackFn<any, any> | mapCallbackFnWithThisArg<any, any>, thisArg: Object?): ()
	if __DEV__ then
		if typeof(callback) ~= "function" then
			error("callback is not a function")
		end
	end
	-- note: we can't turn this into a simple for-in loop, because the callbacks can modify the table and React, GQL, and Jest rely on JS behavior in that scenario
	arrayForEach(self._array, function(key)
		local value = self._map[key]

		if thisArg ~= nil then
			(callback :: mapCallbackFnWithThisArg<any, any>)(thisArg, value, key, self)
		else
			(callback :: mapCallbackFn<any, any>)(value, key, self)
		end
	end)
end

function Map:has(key): boolean
	return self._map[key] ~= nil
end

function Map:keys()
	return self._array
end

function Map:values()
	return arrayMap(self._array, function(key)
		return self._map[key]
	end)
end

function Map:entries()
	return arrayMap(self._array, function(key)
		return { key, self._map[key] }
	end)
end

function Map:ipairs()
	if __DEV__ then
		warn(
			debug.traceback(
				"`for _,_ in myMap:ipairs() do` is deprecated and will be removed in a future release, please use `for _,_ in myMap do` instead\n",
				2
			)
		)
	end
	return ipairs(self:entries())
end

function Map.__iter(self: Map<any, any>)
	return next, self:entries()
end

function Map.__index(self: Map<any, any>, key)
	local mapProp = rawget(Map, key)
	if mapProp ~= nil then
		return mapProp
	end
	if __DEV__ then
		assert(
			-- FIXME Luau: shouldn't need this cast, the self param is annotated already
			rawget(self :: any, "_map"),
			"Map has been corrupted, and is missing private state! Did you accidentally call table.clear() instead of map:clear()?"
		)
	end

	return Map.get(self, key)
end

function Map.__newindex(self: Map<any, any>, key, value)
	self:set(key, value)
end

return Map

end,
["collections/Object/assign"]=function()
local None = require(script.Parent:WaitForChild('None'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Object = types.Object

--[[
	Merges values from zero or more tables onto a target table. If a value is
	set to None, it will instead be removed from the table.

	This function is identical in functionality to JavaScript's Object.assign.
]]
-- Luau TODO: no way to strongly type this accurately, it doesn't eliminate deleted keys of T, and Luau won't do intersections of type packs: <T, ...U>(T, ...: ...U): T & ...U
return function<T, U, V, W>(target: T, source0: U?, source1: V?, source2: W?, ...): T & U & V & W
	if source0 ~= nil and typeof(source0 :: any) == "table" then
		for key, value in pairs(source0 :: any) do
			if value == None then
				(target :: any)[key] = nil
			else
				(target :: any)[key] = value
			end
		end
	end

	if source1 ~= nil and typeof(source1 :: any) == "table" then
		for key, value in pairs(source1 :: any) do
			if value == None then
				(target :: any)[key] = nil
			else
				(target :: any)[key] = value
			end
		end
	end

	if source2 ~= nil and typeof(source2 :: any) == "table" then
		for key, value in pairs(source2 :: any) do
			if value == None then
				(target :: any)[key] = nil
			else
				(target :: any)[key] = value
			end
		end
	end

	for index = 1, select("#", ...) do
		local rest = select(index, ...)

		if rest ~= nil and typeof(rest) == "table" then
			for key, value in pairs(rest) do
				if value == None then
					(target :: any)[key] = nil
				else
					(target :: any)[key] = value
				end
			end
		end
	end

	-- TODO? we can add & Object to this, if needed by real-world code, once CLI-49825 is fixed
	return (target :: any) :: T & U & V & W
end

end,
["collections/Object/entries"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Map<K, V> = types.Map<K, V>
type Tuple<T, V> = types.Tuple<T, V>

return function<T>(value: string | { [string]: T } | Array<T> | Map<any, T>): Array<Tuple<string, T>>
	assert(value :: any ~= nil, "cannot get entries from a nil value")
	local valueType = typeof(value)

	local entries: Array<Tuple<string, T>> = {}
	if valueType == "table" then
		for key, keyValue in pairs(value :: { [string]: T } | Array<T>) do
			-- Luau FIXME: Luau should see entries as Array<any>, given object is [string]: any, but it sees it as Array<Array<string>> despite all the manual annotation
			table.insert(entries, { key, keyValue })
		end
	elseif valueType == "string" then
		-- TODO: should we be using utf8.len?
		for i = 1, string.len(value :: string) do
			entries[i] = { tostring(i), string.sub(value :: string, i, i) }
		end
	end

	return entries
end

end,
["collections/Object/freeze"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object

return function<T>(t: T & (Object | Array<any>)): T
	-- Luau FIXME: model freeze better so it passes through the type constraint and doesn't erase
	return (table.freeze(t :: any) :: any) :: T
end

end,
["collections/Object"]=function()
return {
	assign = require(script:WaitForChild('assign')),
	entries = require(script:WaitForChild('entries')),
	freeze = require(script:WaitForChild('freeze')),
	is = require(script:WaitForChild('is')),
	isFrozen = require(script:WaitForChild('isFrozen')),
	keys = require(script:WaitForChild('keys')),
	preventExtensions = require(script:WaitForChild('preventExtensions')),
	seal = require(script:WaitForChild('seal')),
	values = require(script:WaitForChild('values')),
	-- Special marker type used in conjunction with `assign` to remove values
	-- from tables, since nil cannot be stored in a table
	None = require(script:WaitForChild('None')),
}

end,
["collections/Object/is"]=function()
-- Implements Javascript's `Object.is` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
return function(value1: any, value2: any): boolean
	if value1 == value2 then
		return value1 ~= 0 or 1 / value1 == 1 / value2
	else
		return value1 ~= value1 and value2 ~= value2
	end
end

end,
["collections/Object/isFrozen"]=function()
local __DEV__ = _G.__DEV__

local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object

return function(t: Object | Array<any>): boolean
	if __DEV__ then
		print("Luau now has a direct table.isfrozen call that can save the overhead of this library function call")
	end
	return table.isfrozen(t)
end

end,
["collections/Object/keys"]=function()
local Set = require(script.Parent.Parent:WaitForChild('Set'))
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
local instanceOf = require(script.Parent.Parent.Parent:WaitForChild('instance-of'))
type Array<T> = types.Array<T>
type Set<T> = types.Set<T>
type Table = { [any]: any }

return function(value: Set<any> | Table | string): Array<string>
	if value == nil then
		error("cannot extract keys from a nil value")
	end

	local valueType = typeof(value)

	local keys
	if valueType == "table" then
		keys = {}
		if instanceOf(value, Set) then
			return keys
		end

		for key in pairs(value :: Table) do
			table.insert(keys, key)
		end
	elseif valueType == "string" then
		local length = (value :: string):len()
		keys = table.create(length)
		for i = 1, length do
			keys[i] = tostring(i)
		end
	end

	return keys
end

end,
["collections/Object/None"]=function()
--!nonstrict
-- Marker used to specify that the value is nothing, because nil cannot be
-- stored in tables.
local None = newproxy(true)
local mt = getmetatable(None)
mt.__tostring = function()
	return "Object.None"
end

return None

end,
["collections/Object/preventExtensions"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object

-- FIXME: This should be updated to be closer to the actual
-- `Object.preventExtensions` functionality in JS. This requires additional
-- support from the VM
local function preventExtensions<T>(t: T & (Object | Array<any>)): T
	local name = tostring(t)

	return (
		setmetatable(t :: any, {
			__newindex = function(self, key, value)
				local message = ("%q (%s) is not a valid member of %s"):format(tostring(key), typeof(key), name)

				error(message, 2)
			end,
			__metatable = false,
		}) :: any
	) :: T
end

return preventExtensions

end,
["collections/Object/seal"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>
type Object = types.Object

return function<T>(t: T & (Object | Array<any>)): T
	-- Luau FIXME: model freeze better so it passes through the type constraint and doesn't erase
	return (table.freeze(t :: any) :: any) :: T
end

end,
["collections/Object/values"]=function()
local types = require(script.Parent.Parent.Parent:WaitForChild('es7-types'))
type Array<T> = types.Array<T>

-- TODO Luau: needs overloads to model this more correctly
return function<T>(value: { [string]: T } | Array<T> | string): Array<T> | Array<string>
	if value == nil then
		error("cannot extract values from a nil value")
	end
	local valueType = typeof(value)

	local array: Array<T> | Array<string>
	if valueType == "table" then
		array = {} :: Array<T>
		for _, keyValue in pairs(value :: { [string]: T } | Array<T>) do
			table.insert(array, keyValue)
		end
	elseif valueType == "string" then
		-- optimization to avoid rehashing/growth
		local valueStringLength = (value :: string):len()
		array = table.create(valueStringLength)
		for i = 1, valueStringLength do
			(array :: Array<string>)[i] = (value :: string):sub(i, i)
		end
	end

	return array
end

end,
["collections/Set"]=function()
--!nonstrict
local __DEV__ = _G.__DEV__

local inspect = require(script.Parent:WaitForChild('inspect'))
local isArray = require(script.Parent:WaitForChild('Array'):WaitForChild('isArray'))
local arrayForEach = require(script.Parent:WaitForChild('Array'):WaitForChild('forEach'))
local arrayFromString = require(script.Parent:WaitForChild('Array'):WaitForChild('from'):WaitForChild('fromString'))

local types = require(script.Parent.Parent:WaitForChild('es7-types'))

type Array<T> = types.Array<T>
type Object = types.Object
type setCallbackFn<T> = types.setCallbackFn<T>
type setCallbackFnWithThisArg<T> = types.setCallbackFnWithThisArg<T>
export type Set<T> = types.Set<T>

type Set_Statics = {
	new: <T>(iterable: Array<T> | Set<T> | string | nil) -> Set<T>
}

local Set: Set<any> & Set_Statics = (
	{
		__iter = function(self)
			return next, self._array
		end,
		__tostring = function(self)
			local result = "Set "
			if #self._array > 0 then
				result ..= "(" .. tostring(#self._array) .. ") "
			end
			result ..= inspect(self._array)
			return result
		end,
	} :: any
) :: Set<any> & Set_Statics;
(Set :: any).__index = Set

function Set.new<T>(iterable: Array<T> | Set<T> | string | nil): Set<T>
	local array
	local map = {}
	if iterable ~= nil then
		local arrayIterable

		if typeof(iterable) == "table" then
			if isArray(iterable) then
				arrayIterable = table.clone(iterable)
			else
				local mt = getmetatable(iterable :: any)
				if mt and rawget(mt, "__iter") then
					arrayIterable = iterable :: Set<T>
				elseif __DEV__ then
					error("cannot create array from an object-like table")
				end
			end
		elseif typeof(iterable) == "string" then
			-- TODO Luau: need overloads for `from` to avoid needing the manual cast
			arrayIterable = arrayFromString(iterable :: string) :: Array<string>
		else
			error(("cannot create array from value of type `%s`"):format(typeof(iterable)))
		end

		if arrayIterable then
			array = table.create(#arrayIterable)
			for _, element in arrayIterable do
				if not map[element] then
					map[element] = true
					table.insert(array, element)
				end
			end
		else
			array = {}
		end
	else
		array = {}
	end

	return (setmetatable({
		size = #array,
		_map = map,
		_array = array,
	}, Set) :: any) :: Set<T>
end

function Set:add(value)
	if not self._map[value] then
		-- Luau FIXME: analyze should know self is Set<T> which includes size as a number
		self.size = self.size :: number + 1
		self._map[value] = true
		table.insert(self._array, value)
	end
	return self
end

function Set:clear()
	self.size = 0
	table.clear(self._map)
	table.clear(self._array)
end

function Set:delete(value): boolean
	if not self._map[value] then
		return false
	end
	-- Luau FIXME: analyze should know self is Map<K, V> which includes size as a number
	self.size = self.size :: number - 1
	self._map[value] = nil
	local index = table.find(self._array, value)
	if index then
		table.remove(self._array, index)
	end
	return true
end

-- Implements Javascript's `Map.prototype.forEach` as defined below
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set/forEach
function Set:forEach(callback: setCallbackFn<any> | setCallbackFnWithThisArg<any>, thisArg: Object?): ()
	if typeof(callback) ~= "function" then
		error("callback is not a function")
	end

	-- note: we can't turn this into a simple for-in loop, because the callbacks can modify the table and React, GQL, and Jest rely on JS behavior in that scenario
	arrayForEach(self._array, function(value)
		if thisArg ~= nil then
			(callback :: setCallbackFnWithThisArg<any>)(thisArg, value, value, self)
		else
			(callback :: setCallbackFn<any>)(value, value, self)
		end
	end)
end

function Set:has(value): boolean
	return self._map[value] ~= nil
end

function Set:ipairs()
	if __DEV__ then
		warn(
			debug.traceback(
				"`for _,_ in mySet:ipairs() do` is deprecated and will be removed in a future release, please use `for _,_ in mySet do` instead\n",
				2
			)
		)
	end
	return ipairs(self._array)
end

return Set

end,
["collections/WeakMap"]=function()
local ES7Types = require(script.Parent.Parent:WaitForChild('es7-types'))

type WeakMap<K, V> = ES7Types.WeakMap<K, V>

type WeakMapPrivate<K, V> = {
	_weakMap: { [K]: V },
	-- method definitions
	get: (self: WeakMapPrivate<K, V>, K) -> V,
	set: (self: WeakMapPrivate<K, V>, K, V) -> WeakMapPrivate<K, V>,
	has: (self: WeakMapPrivate<K, V>, K) -> boolean
}
type WeakMap_Statics = {
	new: <K, V>() -> WeakMap<K, V>
}

local WeakMap: WeakMapPrivate<any, any> & WeakMap_Statics = {} :: any;
(WeakMap :: any).__index = WeakMap

function WeakMap.new<K, V>(): WeakMap<K, V>
	local weakMap = setmetatable({}, { __mode = "k" })
	return setmetatable({ _weakMap = weakMap }, WeakMap) :: any
end

function WeakMap:get(key)
	return self._weakMap[key]
end

function WeakMap:set(key, value)
	self._weakMap[key] = value
	return self
end

function WeakMap:has(key): boolean
	return self._weakMap[key] ~= nil
end

return WeakMap :: WeakMap<any, any> & WeakMap_Statics

end,
}

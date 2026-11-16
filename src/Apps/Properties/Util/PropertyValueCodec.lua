--!strict

local Lib

------------------------------ Initialization ------------------------------

local function InitDeps(dependencies)
	Lib = dependencies.Lib
end

local numberTypes = { int = true, int64 = true, float = true, double = true }

local function parseNumbers(text: string, minimum: number, maximum: number)
	local parts = string.split((text:gsub("[{}]", "")), ",")
	if #parts < minimum or #parts > maximum then
		return nil
	end
	local values = table.create(#parts)
	for index, part in ipairs(parts) do
		local value = tonumber(part)
		if value == nil or value ~= value or math.abs(value) == math.huge then
			return nil
		end
		values[index] = value
	end
	return values
end

------------------------------ Module ------------------------------

local function Main()
	local ValueCodec = {}
	local constructors = {
		Vector2 = { Vector2.new, 2, 2 },
		Vector3 = { Vector3.new, 3, 3 },
		UDim = { UDim.new, 2, 2 },
		UDim2 = { UDim2.new, 4, 4 },
		CFrame = {
			function(...)
				return CFrame.new(...)
			end,
			12,
			12,
		},
		Rect = { Rect.new, 4, 4 },
		NumberRange = {
			function(...)
				return NumberRange.new(...)
			end,
			1,
			2,
		},
		Color3 = { Color3.fromRGB, 3, 3 },
	}

	function ValueCodec.Parse(typeName: string, text: string)
		if typeName == "string" or typeName == "Content" then
			return text
		end
		if numberTypes[typeName] then
			local value = tonumber(text)
			return if value and value == value and math.abs(value) ~= math.huge then value else nil
		end
		if typeName == "Ray" then
			local values = parseNumbers(text, 6, 6)
			if not values then
				return nil
			end
			return Ray.new(Vector3.new(values[1], values[2], values[3]), Vector3.new(values[4], values[5], values[6]))
		end
		local constructor = constructors[typeName]
		if not constructor then
			return nil
		end
		local values = parseNumbers(text, constructor[2], constructor[3])
		if not values then
			return nil
		end
		local success, value = pcall(constructor[1], table.unpack(values))
		return if success then value else nil
	end

	function ValueCodec.Format(typeName: string, value): string
		if typeName == "Color3" then
			return Lib.ColorToBytes(value)
		elseif typeName == "NumberRange" then
			return value.Min .. ", " .. value.Max
		end
		return tostring(value)
	end

	return ValueCodec
end

return { InitDeps = InitDeps, InitAfterMain = function() end, Main = Main }

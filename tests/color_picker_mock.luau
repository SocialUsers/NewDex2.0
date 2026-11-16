--!strict

-- Extend the lightweight mock only for the real ColorPicker constructor.
local colorMethods = {}
function colorMethods:ToHex()
	assert(self.R >= 0 and self.R <= 1 and self.G >= 0 and self.G <= 1 and self.B >= 0 and self.B <= 1)
	return string.format(
		"%02X%02X%02X",
		math.floor(self.R * 255 + 0.5),
		math.floor(self.G * 255 + 0.5),
		math.floor(self.B * 255 + 0.5)
	)
end
function colorMethods:ToHSV()
	local maximum, minimum = math.max(self.R, self.G, self.B), math.min(self.R, self.G, self.B)
	local delta = maximum - minimum
	if delta == 0 then
		return 0, 0, maximum
	end
	local hue
	if maximum == self.R then
		hue = ((self.G - self.B) / delta) % 6
	elseif maximum == self.G then
		hue = (self.B - self.R) / delta + 2
	else
		hue = (self.R - self.G) / delta + 4
	end
	return hue / 6, maximum == 0 and 0 or delta / maximum, maximum
end
Color3.new = function(r, g, b)
	return setmetatable({ R = r, G = g, B = b, r = r, g = g, b = b }, { __index = colorMethods })
end
Color3.fromRGB = function(r, g, b)
	return Color3.new(r / 255, g / 255, b / 255)
end
Color3.fromHSV = function(h, s, v)
	local position = (h % 1) * 6
	local sector = math.floor(position)
	local f = position - sector
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	local channels = { { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } }
	local c = channels[sector + 1]
	return Color3.new(c[1], c[2], c[3])
end
Color3.toHSV = function(c)
	return c:ToHSV()
end
local savedWindow = Lib.Window.new
Lib.Window.new = function()
	local w = savedWindow()
	local bar = Instance.new("Frame", w.Gui.Main)
	bar.Name = "TopBar"
	for _, name in ipairs({ "Title", "Close", "Minimize" }) do
		local c = Instance.new(name == "Title" and "TextLabel" or "TextButton", bar)
		c.Name = name
		local image = Instance.new("ImageLabel", c)
		image.Name = "ImageLabel"
	end
	function w:Resize(x, y)
		self.Gui.Main.Size = UDim2.fromOffset(x, y)
	end
	return w
end

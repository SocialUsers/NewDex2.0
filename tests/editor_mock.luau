--!strict

-- Real editor text operations with rendering/Roblox services mocked.
local oldWindowFactory = Lib.Window.new
Lib.Window.new = function()
	local w = oldWindowFactory()
	w.Closed = true
	function w:Resize(x, y)
		self.SizeX = x
		self.SizeY = y
		self.GuiElems.Main.Size = UDim2.fromOffset(x, y)
	end
	function w:Show()
		local first = self.Closed
		self.Closed = false
		if first then
			self.OnActivate:Fire()
		end
	end
	function w:Close()
		self.Closed = true
	end
	function w:IsVisible()
		return not self.Closed
	end
	return w
end
identifyexecutor = function()
	return "Tests", "1"
end
task.spawn = function(fn)
	fn()
end
local funcs = {}
local tabSub = "\205"

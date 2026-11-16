--!strict

-- Wrapper stubs let the real Properties dialog function run without Roblox.
local function wrapper(gui)
	return setmetatable({ Gui = gui }, {
		__index = function(t, k)
			return gui[k]
		end,
		__newindex = function(t, k, v)
			gui[k] = v
		end,
	})
end
Lib.Label = {
	new = function()
		return wrapper(Instance.new("TextLabel"))
	end,
}
Lib.Button = {
	new = function()
		local b = wrapper(Instance.new("TextButton"))
		rawset(b, "OnClick", Lib.Signal.new())
		rawset(b, "SetDisabled", function(self, value)
			rawset(self, "Disabled", value)
		end)
		rawset(b, "Trigger", function(self, event)
			if not self.Disabled then
				self["On" .. event]:Fire()
			end
		end)
		return b
	end,
}
Lib.ViewportTextBox = {
	new = function()
		local b = wrapper(Instance.new("Frame"))
		rawset(b, "TextBox", Instance.new("TextBox", b.Gui))
		rawset(b, "GetText", function(self)
			return self.TextBox.Text
		end)
		rawset(b, "SetText", function(self, v)
			self.TextBox.Text = v
			self.TextBox:GetPropertyChangedSignal("Text"):Fire()
		end)
		return b
	end,
}
Lib.DropDown = {
	new = function()
		local d = wrapper(Instance.new("TextButton"))
		rawset(d, "GuiElems", { Label = Instance.new("TextLabel", d.Gui) })
		rawset(d, "Context", {
			Hide = function(self)
				self.Hidden = true
			end,
		})
		rawset(d, "SetOptions", function(self, options)
			rawset(self, "Options", options)
		end)
		rawset(d, "SetSelected", function(self, opt)
			rawset(self, "Selected", type(opt) == "number" and self.Options[opt] or opt)
		end)
		return d
	end,
}
local originalWindow = Lib.Window.new
Lib.Window.new = function()
	local win = originalWindow()
	win.GuiElems.Minimize = Instance.new("TextButton", win.GuiElems.Main)
	win.Elements = {}
	function win:SetSize(x, y)
		self.GuiElems.Main.Size = UDim2.fromOffset(x, y)
	end
	function win:SetTitle(text)
		self.Title = text
	end
	function win:Add(obj, name)
		obj.Gui.Parent = self.GuiElems.Content
		if name then
			self.Elements[name] = obj
		end
	end
	function win:Show()
		self.Closed = false
	end
	function win:Close()
		self.Closed = true
		self.OnDeactivate:Fire()
	end
	return win
end
Settings.Properties = {}
local writes = {}
Properties = {
	TypeNameConvert = { boolean = "bool", number = "double" },
	AllowedAttributeTypes = { "string", "boolean", "number" },
	DefaultPropValue = { string = "", bool = false, double = 0 },
	ShowExplorerProps = function() end,
	SetProp = function(...)
		writes[#writes + 1] = { ... }
	end,
}

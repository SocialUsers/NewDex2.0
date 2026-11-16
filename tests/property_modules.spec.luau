--!strict

-- Contracts between metadata, client reads, conversion and owned editor state.
do
	local function property(name, typeName)
		return {
			Name = name,
			Class = "Instance",
			Tags = {},
			ValueType = { Name = typeName or "string", Category = "Primitive" },
		}
	end

	local upper = property("BrickColor", "BrickColor")
	local alias = property("brickColor", "BrickColor")
	local standalone = property("lowerOnly")
	local list = Apps.PropertySchema.GetReadableProperties(
		{ ClassName = "Part", BrickColor = true, brickColor = true, lowerOnly = true },
		{ Name = "Part", Properties = { alias, standalone, upper } },
		{}
	)
	assert(#list == 2 and list[1] == standalone and list[2] == upper)
	local parent = property("Parent")
	assert(
		#Apps.PropertySchema.GetReadableProperties({}, { Properties = { parent } }, {}) == 1,
		"readable nil is retained"
	)

	local codec = Apps.PropertyValueCodec
	assert(codec.Parse("int", "17") == 17)
	assert(codec.Parse("int", "bad") == nil)
	assert(codec.Parse("double", "inf") == nil)
	assert(codec.Parse("Vector3", "1, bad, 3") == nil)
	assert(codec.Parse("Vector3", "1, 2, 3, 4") == nil)
	assert(codec.Parse("Vector3", "1, 2, 3").Z == 3)
	assert(codec.Parse("UDim2", "{0.5, 10}, {1, -2}").Y.Offset == -2)
	assert(codec.Format("int", 17) == "17")
	assert(codec.Parse("string", "") == "")
	local originalRange, originalRay, originalCFrame = NumberRange, Ray, CFrame
	NumberRange = {
		new = function(minimum, maximum)
			assert(type(minimum) == "number" and (maximum == nil or type(maximum) == "number"))
			return { Min = minimum, Max = maximum or minimum }
		end,
	}
	Ray = {
		new = function(origin, direction)
			return { Origin = origin, Direction = direction }
		end,
	}
	CFrame = {
		new = function(...)
			local numbers = { ... }
			assert(#numbers == 12)
			for _, number in ipairs(numbers) do
				assert(type(number) == "number")
			end
			return numbers
		end,
	}
	assert(codec.Parse("NumberRange", "2, 7").Max == 7)
	assert(codec.Parse("NumberRange", "2").Max == 2)
	assert(codec.Parse("NumberRange", "2, bad") == nil)
	assert(codec.Parse("Ray", "1,2,3,4,5,6").Direction.Z == 6)
	assert(codec.Parse("CFrame", "1,2,3,1,0,0,0,1,0,0,0,1")[3] == 3)
	NumberRange, Ray, CFrame = originalRange, originalRay, originalCFrame

	local reader = Apps.PropertyReader.Create({ TypeNames = {} })
	local id = property("UniqueId", "UniqueId")
	local valid = "1234567890abcdef1234567890abcdef"
	assert(reader.Read(id, { UniqueId = valid }) == valid)
	assert(reader.Read(id, { UniqueId = "00000000-0000-0000-0000-000000000000" }) == nil)
	assert(reader.Read(
		id,
		setmetatable({}, {
			__index = function()
				error("denied")
			end,
		})
	) == nil)
	assert(reader.Read(property("Enabled", "bool"), { Enabled = false }) == false)
	local object = Instance.new("Folder")
	object:SetAttribute("Flag", false)
	assert(
		reader.Read({ IsAttribute = true, AttributeName = "Flag", ValueType = { Name = "boolean" } }, object) == false
	)
	local fallback = Apps.PropertyReader.Create({
		TypeNames = {},
		ReadHiddenProperty = function()
			return valid
		end,
	})
	assert(fallback.Read(id, { UniqueId = string.rep("0", 32) }) == valid)

	local elements = {}
	for _, name in ipairs({
		"ValueFrame",
		"ValueBox",
		"ColorButton",
		"ColorPreview",
		"Gradient",
		"EnumArrow",
		"Checkbox",
		"RightButton",
		"RightButtonIcon",
		"SoundPreview",
	}) do
		elements[name] = Instance.new("Frame")
	end
	local checkboxController = {
		SetState = function(self, value)
			self.State = value
		end,
	}
	local native = Instance.new("ImageLabel")
	native.Name, native.Parent = "Native", elements.RightButton
	native.Image = "owned://ellipsis"
	local activeProperty
	local selected = { Enabled = false }
	local automatic = { ["Instance.Enabled"] = selected, ["Instance.CustomPhysicalProperties"] = selected }
	local cell = Apps.PropertyValueCell.Create({
		Entries = { { GuiElems = elements } },
		Checkboxes = { checkboxController },
		AutoUpdateObjs = automatic,
		Colors = { Text = Color3.new(1, 1, 1), ReadOnly = Color3.new(0.5, 0.5, 0.5) },
		GetInputProp = function()
			return activeProperty
		end,
		ReadValue = reader.Read,
		FormatValue = function(prop, value)
			return codec.Format(prop.ValueType.Name, value)
		end,
		RoundableTypes = {},
		IsSoundPlaying = function()
			return false
		end,
	})
	local boolean = property("Enabled", "bool")
	cell(boolean, 1)
	assert(elements.Checkbox.Visible and not elements.ValueBox.Visible and checkboxController.State == false)
	selected.Enabled = true
	boolean.Tags.ReadOnly = true
	cell(boolean, 1)
	assert(checkboxController.State == true and checkboxController.Disabled == true)
	selected.Enabled = nil
	cell(boolean, 1)
	assert(checkboxController.State == nil, "mixed/unavailable booleans preserve the indeterminate state")
	local physical = property("CustomPhysicalProperties", "PhysicalProperties")
	selected.CustomPhysicalProperties = {}
	cell(physical, 1)
	assert(checkboxController.State == true, "physical properties use the same checkbox controller")
	selected.CustomPhysicalProperties = nil
	cell(physical, 1)
	assert(checkboxController.State == false)
	local reference = property("Parent", "Instance")
	reference.ValueType.Category = "Class"
	activeProperty = reference
	cell(reference, 1)
	assert(elements.RightButton.Visible and elements.RightButtonIcon.Visible and not native.Visible)
	assert(elements.RightButton.Text == "", "object clear action has no text or ellipsis underneath")
	activeProperty = nil
	cell(property("Curve", "NumberSequence"), 1)
	assert(
		native.Visible and not elements.RightButtonIcon.Visible and elements.RightButton.Text == "",
		"sequence uses only one ellipsis image"
	)
	cell(boolean, 1)
	assert(
		not elements.RightButton.Visible and not native.Visible and not elements.RightButtonIcon.Visible,
		"recycled cells clear both icons"
	)
	-- A real Roblox Instance throws on missing named-child indexing. Reproduce
	-- the absent template glyph rather than supplying it in every fixture.
	native:Destroy()
	cell(boolean, 1)
	native = elements.RightButton:FindFirstChild("Native")
	assert(
		native and native:IsA("ImageLabel") and not native.Visible,
		"missing row glyph is recreated without failing ordinary property rendering"
	)
	cell(property("Curve", "NumberSequence"), 1)
	assert(native.Visible and elements.RightButton.Text == "", "recreated sequence glyph works")
	local count = #elements.RightButton:GetChildren()
	cell(property("Curve", "NumberSequence"), 1)
	assert(#elements.RightButton:GetChildren() == count, "rerender does not duplicate glyphs")
	activeProperty = reference
	cell(reference, 1)
	assert(
		not native.Visible and elements.RightButtonIcon.Visible and elements.RightButton.Text == "",
		"recreated glyph does not overlap the clear button"
	)
	activeProperty = nil
	local getAsset = Main.GetStudioAsset
	Main.GetStudioAsset = function()
		return nil
	end
	native:Destroy()
	cell(property("Curve", "NumberSequence"), 1)
	native = elements.RightButton:FindFirstChild("Native")
	assert(not native.Visible and elements.RightButton.Text == "…", "missing asset retains a usable ellipsis action")
	activeProperty = reference
	cell(reference, 1)
	assert(
		elements.RightButton.Text == "" and elements.RightButtonIcon.Visible,
		"fallback ellipsis clears when picking an object"
	)
	activeProperty = nil
	cell(boolean, 1)
	assert(not elements.RightButton.Visible and elements.RightButton.Text == "", "recycling clears fallback text")
	Main.GetStudioAsset = getAsset
	print("PASS: real value-cell rendering for selected boolean, read-only, mixed and physical properties")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(150, 23)
	local alpha, zeta = { Name = "Alpha" }, { Name = "Zeta" }
	local previous = rawget(Enum, "ModuleBoundaryTest")
	Enum.ModuleBoundaryTest = {
		GetEnumItems = function()
			return { zeta, alpha }
		end,
	}
	local first = { Name = "First", ValueType = { Name = "ModuleBoundaryTest", Category = "Enum" } }
	local second = { Name = "Second", ValueType = first.ValueType }
	local active, saved = first, {}
	local enumMenu, sequenceWidget
	local factories = {
		Enum = function()
			enumMenu = Lib.ContextMenu.new()
			return enumMenu
		end,
		NumberSequence = function()
			sequenceWidget = { OnSelect = Lib.Signal.new(), Gui = Instance.new("Frame") }
			function sequenceWidget:SetSequence(value)
				self.OnSelect:Fire(value)
			end
			function sequenceWidget:Show()
				self.Shown = true
			end
			function sequenceWidget:Hide()
				self.Shown = false
			end
			return sequenceWidget
		end,
	}
	local editors = Apps.PropertyValueEditors.Create({
		Entries = { { GuiElems = { ValueFrame = frame } } },
		GetInputProp = function()
			return active
		end,
		SetInputProp = function(value)
			active = value
		end,
		ReadFirst = function()
			return nil
		end,
		Commit = function(prop, value)
			table.insert(saved, { prop, value })
		end,
		Factories = factories,
	})
	assert(enumMenu == nil and sequenceWidget == nil, "widgets are lazy")
	editors.ShowEnum(1)
	assert(enumMenu.Items[1].Name == "Alpha", "enum options stay sorted")
	local stale = enumMenu.Items[1].OnClick
	active = second
	stale()
	assert(#saved == 0 and active == second, "old callback cannot edit another property")
	editors.ShowEnum(1)
	stale()
	assert(#saved == 0, "superseded edit is invalid even after reopening the same widget")
	enumMenu.Items[1].OnClick()
	assert(saved[1][1] == second and saved[1][2] == alpha and active == nil)

	local sequence = property("Sequence", "NumberSequence")
	active = sequence
	editors.ShowNumberSequence(sequence, "initial")
	assert(#saved == 1, "programmatic initialization is not a user edit")
	sequenceWidget.OnSelect:Fire("user edit")
	assert(#saved == 2 and saved[2][2] == "user edit")
	editors.Cancel()
	sequenceWidget.OnSelect:Fire("stale edit")
	assert(#saved == 2 and not sequenceWidget.Shown, "cancel invalidates and closes widgets")
	editors.Destroy()
	editors.Destroy()
	sequenceWidget.OnSelect:Fire("after destroy")
	assert(#saved == 2 and sequenceWidget.Gui.Destroyed, "destruction disconnects callbacks")
	Enum.ModuleBoundaryTest = previous
	print(
		"PASS: explicit property APIs, validated numeric input, fallback reads and owned editor cancellation/lifetime"
	)
end

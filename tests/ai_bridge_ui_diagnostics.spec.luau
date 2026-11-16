--!strict

-- Current engine evidence is kept separate from approximate text/clip calculations.
do
	local oldIsA = methods.IsA
	local oldTextService = service.TextService
	methods.IsA = function(self, class)
		return class == "GuiObject" and self.ClassName == "CanvasGroup"
			or class == "LayerCollector" and (self.ClassName == "ScreenGui" or self.ClassName == "SurfaceGui")
			or oldIsA(self, class)
	end
	local root = Instance.new("ScreenGui", game)
	root.Enabled = false
	root.IgnoreGuiInset = false
	root.DisplayOrder = 0
	local group = Instance.new("CanvasGroup", root)
	group.Size = UDim2.fromOffset(200, 200)
	group.Visible = true
	group.GroupTransparency = 1
	group.AbsoluteRotation = 0
	local parent = Instance.new("Frame", group)
	parent.Size = UDim2.fromOffset(100, 100)
	parent.Visible = false
	parent.ClipsDescendants = true
	parent.AbsoluteRotation = 0
	local text = Instance.new("TextLabel", parent)
	text.Name = "Diagnostic text"
	text.Position = UDim2.fromOffset(80, 80)
	text.Size = UDim2.fromOffset(50, 50)
	text.Visible = true
	text.AbsoluteRotation = 0
	text.Text = "Hello"
	text.ContentText = "Hello"
	text.TextSize = 16
	text.TextScaled = false
	text.RichText = false
	text.TextWrapped = true
	text.TextFits = false
	text.LineHeight = 1
	text.TextBounds = Vector2.new(40, 20)
	text.Font = Enum.Material.Plastic
	local layout = Instance.new("UIListLayout", parent)
	layout.Padding = UDim.new(0, 4)
	layout.Wraps = false
	local padding = Instance.new("UIPadding", text)
	padding.PaddingLeft = UDim.new(0, 3)
	local scale = Instance.new("UIScale", text)
	scale.Scale = 1
	local calls = 0
	service.TextService = {
		GetTextSize = function(_, value, fontSize, font, bounds)
			calls += 1
			assert(value == "Hello" and fontSize == 16 and bounds.X == 50)
			return Vector2.new(35, 16)
		end,
	}
	local registry = Apps.BridgeRegistry.Create({ Apps = Apps, Main = Main, Game = game })
	local codec = Apps.BridgeValueCodec.Create(registry)
	local diagnostics = Apps.BridgeUIDiagnostics.Create({
		Apps = Apps,
		Main = Main,
		service = service,
		Game = game,
		Registry = registry,
		Codec = codec,
	})
	local handlers = {}
	for _, command in ipairs(diagnostics.Commands) do
		assert(command.Grant == "inspect")
		handlers[command.Name] = command.Run
	end
	local function call(name, args)
		return handlers["dex_" .. name](args)
	end
	local id = registry:Id(text)
	local result = call("get_ui_diagnostics", { instanceId = id })
	assert(
		result.scope == "client"
			and result.visibilityEvidence.hiddenByVisible
			and result.visibilityEvidence.disabledLayer
			and result.visibilityEvidence.transparentCanvasGroup,
		"hidden GUI, disabled collector and transparent ancestor evidence retained"
	)
	assert(
		result.properties.Visible == true
			and result.ancestors[1].properties.Visible == false
			and result.ancestors[3].properties.Enabled == false,
		"false visibility properties are actual encoded booleans"
	)
	assert(
		result.rect.x == 80
			and result.rect.width == 50
			and result.clipAnalysis.intersection.width == 20
			and math.abs(result.clipAnalysis.visibleAreaFraction - 0.16) < 0.00001
			and result.clipAnalysis.status == "axis_aligned",
		"axis-aligned ancestor clipping uses resolved rect intersection"
	)
	local warnings = {}
	for _, warning in ipairs(result.warnings) do
		warnings[warning.code] = true
	end
	assert(warnings.PARTIALLY_CLIPPED and warnings.PARENT_LAYOUT)
	local hasParent = false
	local nilPadding = false
	for _, component in ipairs(result.components) do
		if component.instance.className == "UIPadding" then
			nilPadding = component.properties.PaddingRight.type == "nil"
		end
		if component.instance.className == "UIListLayout" then
			hasParent = component.relationship == "parent_layout"
				and component.affectsTarget
				and component.owner.id == registry:Id(parent)
		end
	end
	assert(
		hasParent and nilPadding and #result.components == 3,
		"target components and parent controlling layouts both inspected"
	)
	local ownGroup = call("get_ui_diagnostics", { instanceId = registry:Id(group) })
	assert(
		ownGroup.visibilityEvidence.transparentCanvasGroup and ownGroup.properties.GroupTransparency == 1,
		"selected CanvasGroup transparency is evidence too"
	)
	parent.AbsoluteRotation = 20
	local rotated = call("get_ui_diagnostics", { instanceId = id })
	assert(
		rotated.clipAnalysis.approximate and rotated.clipAnalysis.status == "axis_aligned_estimate",
		"rotated clipping is explicitly approximate"
	)
	for _, warning in ipairs(rotated.warnings) do
		assert(
			warning.code ~= "FULLY_CLIPPED" and warning.code ~= "PARTIALLY_CLIPPED",
			"rotation must not imply exact clipping"
		)
	end
	parent.AbsoluteRotation = 0
	text.Size = UDim2.fromOffset(0, 10)
	local zero = call("get_ui_diagnostics", { instanceId = id })
	assert(zero.visibilityEvidence.zeroSize)
	text.Size = UDim2.fromOffset(50, 50)
	local metrics = call("get_text_metrics", { instanceId = id })
	assert(
		metrics.properties.TextFits == false
			and metrics.properties.TextScaled == false
			and metrics.measurement.available
			and metrics.measurement.accuracy == "approximate_plain_text_legacy_font"
			and metrics.measurement.bounds.x == 35
			and calls == 1,
		"engine text evidence and plain legacy measurement are separated"
	)
	text.LineHeight = 2
	assert(
		call("get_text_metrics", { instanceId = id }).measurement.reason == "custom_line_height_not_measured"
			and calls == 1
	)
	text.LineHeight = 1
	text.RichText = true
	local rich = call("get_text_metrics", { instanceId = id })
	assert(not rich.measurement.available and rich.measurement.reason == "rich_text_not_measured" and calls == 1)
	text.RichText = false
	text.TextScaled = true
	assert(
		call("get_text_metrics", { instanceId = id }).measurement.reason == "scaled_text_not_measured" and calls == 1
	)
	text.TextScaled = false
	local previousFont = text.Font
	text.Font = Enum.Font.Unknown
	assert(
		call("get_text_metrics", { instanceId = id }).measurement.reason == "custom_or_unknown_font_not_measured"
			and calls == 1,
		"custom FontFace fonts do not invoke legacy measurement"
	)
	text.Font = previousFont
	text.Text = string.rep("é", 3000)
	local large = call("get_text_metrics", { instanceId = id })
	assert(
		large.text.bytes == 6000
			and large.text.previewTruncated
			and utf8.len(large.text.preview) == 1024
			and large.errors.Text == "property_string_limit"
			and large.measurement.reason == "text_measurement_limit"
			and calls == 1,
		"large text is capped without splitting UTF-8 and never measured"
	)
	text.Text = "Hello"
	service.TextService.GetTextSize = function()
		error("text service denied")
	end
	local failed = call("get_text_metrics", { instanceId = id })
	assert(not failed.measurement.available and failed.measurement.error:find("text service denied", 1, true))
	local originalIndex = instMT.__index
	instMT.__index = function(object, key)
		if object == text and key == "FontFace" then
			error("protected fixture field")
		end
		return originalIndex(object, key)
	end
	local denied = call("get_text_metrics", { instanceId = id })
	assert(denied.errors.FontFace:find("protected fixture field", 1, true))
	instMT.__index = originalIndex
	for _ = 1, 40 do
		local value = Instance.new("UIScale", text)
		value.Scale = 1
	end
	local capped = call("get_ui_diagnostics", { instanceId = id })
	assert(
		#capped.components > 0
			and #capped.components <= 32
			and capped.coverage.componentTruncated
			and capped.coverage.truncated
			and capped.coverage.estimatedBytes <= 48 * 1024,
		"component count and result budget are explicit"
	)
	local deepRoot = Instance.new("Folder", game)
	local cursor = deepRoot
	for _ = 1, 70 do
		local child = Instance.new("Frame", cursor)
		child.AbsoluteRotation = 0
		child.Name = string.rep("x", 240)
		cursor = child
	end
	local deep = call("get_ui_diagnostics", { instanceId = registry:Id(cursor) })
	assert(
		deep.coverage.ancestorTruncated and deep.coverage.truncated and deep.coverage.estimatedBytes <= 48 * 1024,
		"ancestor and serialized result budgets do not imply complete diagnostics"
	)
	for _, item in ipairs({
		{ "get_ui_diagnostics", { instanceId = registry:Id(root) } },
		{ "get_text_metrics", { instanceId = registry:Id(parent) } },
		{ "get_text_metrics", {} },
		{ "get_text_metrics", { instanceId = false } },
		{ "get_text_metrics", { instanceId = id, unknown = true } },
	}) do
		assert(not pcall(call, item[1], item[2]), "invalid target/args must reject")
	end
	diagnostics:Destroy()
	assert(not pcall(call, "get_text_metrics", { instanceId = id }), "destroyed adapter cannot inspect")
	registry:Destroy()
	root:Destroy()
	deepRoot:Destroy()
	methods.IsA = oldIsA
	service.TextService = oldTextService
	print(
		"PASS: UI visibility/clipping/layout evidence, bounded ancestors/components, text bounds/plain-font limits, errors, false/nil preservation and teardown"
	)
end

--!strict

local Main, Settings, service, createSimple

------------------------------ Initialization ------------------------------

local function InitDeps(d)
	Main, Settings, service, createSimple = d.Main, d.Settings, d.service, d.createSimple
end
------------------------------ Module ------------------------------

local function CreateModule()
	local Splash = {}
	-- https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md
	local function curve(x: number, x1: number, y1: number, x2: number, y2: number): number
		if x <= 0 then
			return 0
		elseif x >= 1 then
			return 1
		end
		local low, high, t = 0, 1, x
		for _ = 1, 12 do
			local a = 1 - t
			local value = 3 * a * a * t * x1 + 3 * a * t * t * x2 + t * t * t
			local delta = value - x
			if math.abs(delta) < 0.000001 then
				break
			end
			if delta < 0 then
				low = t
			else
				high = t
			end
			local derivative = 3 * a * a * x1 + 6 * a * t * (x2 - x1) + 3 * t * t * (1 - x2)
			local nextT = derivative > 0.00001 and t - delta / derivative or -1
			t = nextT > low and nextT < high and nextT or (low + high) / 2
		end
		local a = 1 - t
		return math.clamp(3 * a * a * t * y1 + 3 * a * t * t * y2 + t * t * t, 0, 1)
	end
	local function ramp(t: number, start: number, duration: number): number
		return curve((t - start) / duration, 0.05, 0.7, 0.1, 1)
	end
	function Splash.Create(initStatus: string?)
		local theme = Settings.Theme
		local brand = theme.Brand or theme.Focus
		local text = theme.SelectedText or theme.Text
		local gui = createSimple("ScreenGui", {
			Name = "DexExplorerLoading",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = Main.DisplayOrders.Menu,
		})
		local panel = createSimple("Frame", {
			Name = "Status",
			Parent = gui,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = theme.Menu,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -32, 0, 280),
			ClipsDescendants = true,
		})
		createSimple("UISizeConstraint", { Parent = panel, MaxSize = Vector2.new(488, 280) })
		createSimple("UICorner", { Parent = panel, CornerRadius = UDim.new(0, 8) })
		local outline =
			createSimple("UIStroke", { Parent = panel, Color = theme.Outline2, Transparency = 1, Thickness = 1 })
		local wipe = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.42, 0),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		local background = createSimple(
			"UIGradient",
			{ Parent = panel, Rotation = -22, Transparency = wipe, Offset = Vector2.new(-1.2, 0) }
		)
		local slab = createSimple("Frame", {
			Name = "Slab",
			Parent = panel,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Main2 or theme.Menu,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		})
		createSimple("UIGradient", {
			Parent = slab,
			Rotation = 25,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 1),
				NumberSequenceKeypoint.new(0.502, 0),
				NumberSequenceKeypoint.new(0.94, 0),
				NumberSequenceKeypoint.new(0.942, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})

		local titleMask = createSimple("Frame", {
			Name = "TitleMask",
			Parent = panel,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(32, 68),
			Size = UDim2.new(0.58, 0, 0, 74),
		})
		local title = createSimple("TextLabel", {
			Name = "Title",
			Parent = titleMask,
			BackgroundTransparency = 1,
			Text = "Dex",
			Font = Enum.Font.BuilderSansBold,
			TextSize = 49,
			TextColor3 = text,
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(196, 74),
		})
		local subtitleMask = createSimple("Frame", {
			Name = "SubtitleMask",
			Parent = panel,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Position = UDim2.fromOffset(35, 142),
			Size = UDim2.new(0.52, 0, 0, 20),
		})
		local subtitle = createSimple("TextLabel", {
			Name = "Subtitle",
			Parent = subtitleMask,
			BackgroundTransparency = 1,
			Text = "Explorer",
			Font = Enum.Font.BuilderSansMedium,
			TextSize = 13,
			TextColor3 = theme.PlaceholderText,
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(180, 20),
		})

		local mark = createSimple("Frame", {
			Name = "Brand",
			Parent = panel,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.77, 0, 0, 126),
			Size = UDim2.fromOffset(128, 128),
		})
		local reveal = createSimple("Frame", {
			Name = "Reveal",
			Parent = mark,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.fromScale(1, 1),
		})
		local markScale = createSimple("UIScale", { Name = "EntranceScale", Parent = mark, Scale = 0.9 })
		local image = Main.GetStudioAsset("branding/dex/toolbar-white-v1")
		local logo
		if image then
			logo = createSimple("ImageLabel", {
				Name = "Logo",
				Parent = reveal,
				BackgroundTransparency = 1,
				Image = image,
				ImageColor3 = text,
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Position = UDim2.fromOffset(14, 14),
				Size = UDim2.fromOffset(100, 100),
			})
		else
			logo = createSimple("TextLabel", {
				Name = "LogoFallback",
				Parent = reveal,
				BackgroundTransparency = 1,
				Text = "D",
				Font = Enum.Font.BuilderSansBold,
				TextColor3 = text,
				TextSize = 104,
				TextTransparency = 1,
				Size = UDim2.fromOffset(128, 128),
			})
		end

		local message = createSimple("TextLabel", {
			Name = "Message",
			Parent = panel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 46, 1, -72),
			Size = UDim2.new(1, -124, 0, 22),
			Font = Enum.Font.BuilderSans,
			TextSize = 12,
			TextColor3 = theme.PlaceholderText,
			TextTransparency = 1,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = initStatus or "Loading",
		})
		local activity = createSimple("Frame", {
			Name = "Activity",
			Parent = panel,
			BorderSizePixel = 0,
			BackgroundColor3 = brand,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 34, 1, -62),
			Size = UDim2.fromOffset(3, 3),
		})
		createSimple("UICorner", { Parent = activity, CornerRadius = UDim.new(0, 2) })
		local percent = createSimple("TextLabel", {
			Name = "Percent",
			Parent = panel,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -84, 1, -72),
			Size = UDim2.fromOffset(50, 22),
			Font = Enum.Font.BuilderSans,
			TextSize = 12,
			TextColor3 = theme.PlaceholderText,
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "0%",
		})
		local track = createSimple("Frame", {
			Name = "Progress",
			Parent = panel,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Outline2,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 1, -34),
			Size = UDim2.new(0, 0, 0, 3),
			ClipsDescendants = true,
		})
		local fill = createSimple("Frame", {
			Name = "Fill",
			Parent = track,
			BorderSizePixel = 0,
			BackgroundColor3 = brand,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0, 1),
			ClipsDescendants = true,
		})

		local elapsed, exitTime, progress, shown, stageAt = 0, 0, 0, 0, -1
		local closing, destroyed, connection = false, false, nil
		local function destroy()
			if destroyed then
				return
			end
			destroyed = true
			if connection then
				connection:Disconnect()
				connection = nil
			end
			gui:Destroy()
		end
		local function paint(dt)
			if destroyed then
				return
			end
			if Main.Alive == false then
				destroy()
				return
			end
			if closing then
				exitTime += dt
			else
				elapsed += dt
			end
			local exit = curve(exitTime / 0.22, 0.3, 0, 0.8, 0.15)
			local enter = ramp(elapsed, 0, 0.34)
			local visible = (1 - exit)
			background.Offset = Vector2.new(-1.2 + 2.4 * enter * visible, 0)
			panel.Position = UDim2.new(0.5, 0, 0.5, -6 * exit)
			outline.Transparency = 1 - 0.65 * enter * visible
			slab.BackgroundTransparency = 1 - 0.75 * enter * visible
			local word = ramp(elapsed, 0.06, 0.4)
			title.Position = UDim2.fromOffset(-32 * (1 - word), 0)
			title.TextTransparency = 1 - word * visible
			local desc = ramp(elapsed, 0.14, 0.3)
			subtitle.Position = UDim2.fromOffset(-24 * (1 - desc), 0)
			subtitle.TextTransparency = 1 - 0.8 * desc * visible
			local markIn = ramp(elapsed, 0.04, 0.4)
			markScale.Scale = 0.9 + 0.1 * markIn
			mark.Position = UDim2.new(0.77, 12 * (1 - markIn), 0, 126 + 6 * (1 - markIn))
			if image then
				logo.ImageTransparency = 1 - markIn * visible
			else
				logo.TextTransparency = 1 - markIn * visible
			end

			local status = ramp(elapsed, 0.18, 0.24) * visible
			local stage = ramp(elapsed - stageAt + (closing and exitTime or 0), 0, 0.16)
			message.TextTransparency = 1 - status * stage
			message.Position = UDim2.new(0, 46, 1, -72 + 2 * (1 - stage))
			activity.BackgroundTransparency = 1 - status * (0.55 + 0.2 * math.sin(elapsed * 2.6))
			percent.TextTransparency = 1 - status
			local trackIn = ramp(elapsed, 0.16, 0.32)
			local trackWidth = trackIn
			track.Position = UDim2.new(0.5, 0, 1, -34)
			track.Size = UDim2.new(trackWidth, -68 * trackWidth, 0, 3)
			track.AnchorPoint = Vector2.new(0.5, 0)
			track.BackgroundTransparency = 1 - 0.8 * status
			fill.BackgroundTransparency = 1 - status
			shown += (progress - shown) * (1 - math.exp(-dt * 12))
			if math.abs(progress - shown) < 0.0005 then
				shown = progress
			end
			fill.Size = UDim2.fromScale(shown, 1)
			if closing and exitTime >= 0.22 then
				destroy()
			end
		end
		Main.SecureGui(gui)
		if Main.AddCleanup then
			Main.AddCleanup(destroy)
		end
		local ok, con = pcall(function()
			return service.RunService.RenderStepped:Connect(function(dt)
				if type(dt) ~= "number" or dt ~= dt or dt <= 0 or dt == math.huge then
					return
				end
				paint(math.min(dt, 0.25))
			end)
		end)
		if ok and con then
			connection = con
		else
			paint(1)
		end
		return {
			SetProgress = function(value, target)
				if destroyed or closing then
					return
				end
				if type(value) == "string" and value ~= message.Text then
					message.Text = value
					stageAt = elapsed
				end
				if type(target) == "number" and target == target and target ~= math.huge and target ~= -math.huge then
					progress = math.max(progress, math.clamp(target, 0, 1))
					percent.Text = string.format("%d%%", math.floor(progress * 100 + 0.5))
					if not connection then
						shown = progress
						fill.Size = UDim2.fromScale(progress, 1)
					end
				end
			end,
			Close = function()
				if destroyed or closing then
					return
				end
				closing = true
				if not connection then
					destroy()
				end
			end,
		}
	end
	return Splash
end
local control = { InitDeps = InitDeps, InitAfterMain = function() end, Main = CreateModule }
if gethsfuncs then
	_G.moduleData = control
else
	return control
end

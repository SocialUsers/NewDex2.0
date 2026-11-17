--!strict

-- Exercise the real SearchBox/Explorer controllers against recovered source contracts.
do
	local savedSelection = table.clone(Explorer.Selection.List)
	local savedHistory = Explorer.SearchHistory
	local savedPlaces = Settings.Explorer.SearchHistoryByPlace
	local savedSave, savedClipboard = Main.SaveSettings, deps.env.setclipboard
	local savedExpand = Settings.Explorer.ExpandHierarchy
	local savedIncrement = Settings.Explorer.IncrementNames
	local saves, copied = 0, nil
	Main.SaveSettings = function()
		saves += 1
		return true
	end
	Settings.Explorer.SearchHistoryByPlace = {}
	Explorer.SearchHistory = {}
	Explorer.ClearSearch()
	local spinner = Explorer.GuiElems.SearchStatus.LoadingSpinner
	local angle = spinner.Rotation
	Explorer.SearchBusy = true
	Explorer.AdvanceSearchSpinner(1 / 60)
	assert(spinner.Rotation == angle, "loading spinner updates at most thirty times a second")
	Explorer.AdvanceSearchSpinner(1 / 60)
	assert(
		math.abs(spinner.Rotation - angle - 9) < 0.0001,
		"loading spinner follows source 270-degree-per-second rotation"
	)
	Explorer.SearchBusy = false
	angle = spinner.Rotation
	Explorer.AdvanceSearchSpinner(1)
	assert(spinner.Rotation == angle, "idle searches do not animate their spinner")
	local savedRun, savedActive, savedVisible = service.RunService, Explorer.Active, Explorer.Window.IsVisible
	local activeFrames = 0
	service.RunService = {
		Heartbeat = {
			Connect = function()
				activeFrames += 1
				return {
					Disconnect = function()
						activeFrames -= 1
					end,
				}
			end,
		},
	}
	Explorer.Active = true
	Explorer.Window.IsVisible = function()
		return true
	end
	Explorer.UpdateSearchSpinner()
	assert(activeFrames == 0, "idle Explorer does not bind the spinner")
	Explorer.SetSearchBusy(true, "example")
	Explorer.UpdateSearchSpinner()
	assert(activeFrames == 1, "a visible search binds one spinner callback")
	Explorer.Active = false
	Explorer.UpdateSearchSpinner()
	assert(activeFrames == 0, "hiding Explorer disconnects the spinner")
	Explorer.Active = true
	Explorer.UpdateSearchSpinner()
	Explorer.SetSearchBusy(false, "example")
	assert(activeFrames == 0, "completing a search disconnects the spinner")
	service.RunService, Explorer.Active, Explorer.Window.IsVisible = savedRun, savedActive, savedVisible
	Explorer.RememberSearch("  Door\nhandle\r  ")
	assert(Explorer.SearchHistory[1] == "Door handle", "history trims and normalizes committed queries")
	for index = 1, 12 do
		Explorer.RememberSearch("query" .. index)
	end
	assert(
		#Explorer.SearchHistory == 10
			and Explorer.SearchHistory[1] == "query12"
			and Explorer.SearchHistory[10] == "query3",
		"history keeps ten most recent unique queries"
	)
	local key = tostring(game.PlaceId or 0)
	assert(
		Settings.Explorer.SearchHistoryByPlace[key][1] == "query12" and saves == 13,
		"history changes persist through the existing settings writer"
	)
	local loaded = Apps.SearchBox.LoadHistory(game.PlaceId)
	assert(
		#loaded == 10 and loaded[1] == "query12" and loaded ~= Explorer.SearchHistory,
		"history reloads independently from saved place settings"
	)
	Settings.Explorer.SearchHistoryByPlace.other = { "foreign" }
	assert(
		#Apps.SearchBox.LoadHistory("other") == 1 and Apps.SearchBox.LoadHistory("other")[1] == "foreign",
		"search history is isolated by place"
	)
	loaded[1] = "modified"
	assert(
		Settings.Explorer.SearchHistoryByPlace[key][1] == "query12",
		"loaded history cannot mutate persisted history by alias"
	)
	local toolbar = Explorer.GuiElems.ToolBar
	local popup = Explorer.GuiElems.HeaderPopup
	Explorer.CloseHeaderPopup()
	toolbar.Options.Activated:Fire()
	local before = saves
	popup.Items:GetChildren()[1].Activated:Fire()
	assert(saves == before + 1, "header preference changes persist immediately")
	local prior = Settings.Explorer.IncrementNames
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
		false
	)
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Return },
		false
	)
	Explorer.GuiElems.SearchBar.FocusLost:Fire(true, { KeyCode = Enum.KeyCode.Return })
	assert(
		Settings.Explorer.IncrementNames ~= prior and popup.Visible and saves == before + 2,
		"settings supports keyboard selection/Enter once without submitting a search or closing"
	)
	Explorer.CloseHeaderPopup()
	local search = Explorer.GuiElems.SearchBar
	search.Text = "One\nTwo\r"
	search:GetPropertyChangedSignal("Text"):Fire()
	assert(search.Text == "One Two", "actual search field sanitizes pasted line breaks")
	search.Text = string.rep("a", 32768)
	search:GetPropertyChangedSignal("Text"):Fire()
	assert(#search.Text == 32767, "actual search field obeys Studio's query limit")
	search.Text = ""
	search:GetPropertyChangedSignal("Text"):Fire()
	search:CaptureFocus()
	local help = popup.Items.FilterHelp
	assert(help, "empty focus creates the syntax help control")
	deps.env.setclipboard = function(value)
		copied = value
	end
	help.Activated:Fire()
	assert(
		copied == "https://create.roblox.com/docs/studio/explorer#filtering-instances" and not popup.Visible,
		"syntax help copies the real guide when privileged browser opening is unavailable"
	)
	deps.env.setclipboard = nil
	search:ReleaseFocus()
	search:CaptureFocus()
	popup.Items.FilterHelp.Activated:Fire()
	assert(
		popup.Visible and popup.Items.SyntaxGuideUrl.Text == copied,
		"syntax guide remains accessible without browser or clipboard APIs"
	)
	Explorer.CloseHeaderPopup()
	search:ReleaseFocus()
	search.Text = "Anchored="
	search:CaptureFocus()
	search:GetPropertyChangedSignal("Text"):Fire()
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Up },
		false
	)
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Tab },
		false
	)
	assert(search.Text == "Anchored=true", "autocomplete Up wraps from its initial first item to the last")
	Explorer.CloseHeaderPopup()
	search:ReleaseFocus()
	Explorer.DoSearch("door")
	Explorer.Selection:Clear()
	toolbar.Parent.SearchStatus.Next.Activated:Fire()
	local first = Explorer.Selection.List[1]
	assert(first and Explorer.Matches[first], "next result control selects an actual match")
	keys.LeftControl = true
	toolbar.Parent.SearchStatus.Next.Activated:Fire()
	keys.LeftControl = false
	assert(
		#Explorer.Selection.List == 2 and Explorer.Selection.Map[first],
		"Ctrl+next preserves the existing result and adds another"
	)
	Explorer.StepMatch(-1, true)
	assert(#Explorer.Selection.List == 2, "stepping does not remove results when every result is already selected")
	search.Text = "door"
	search:CaptureFocus()
	Explorer.CloseHeaderPopup()
	Explorer.Selection:Clear()
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
		false
	)
	assert(
		service.UserInputService:GetFocusedTextBox() ~= search and #Explorer.Selection.List == 1,
		"Down without a dropdown transfers search focus to the first visible tree row"
	)
	Explorer.ClearSearch()
	Explorer.Selection:Set(nodes[part])
	Explorer.OpenInsert(nodes[model])
	assert(
		#Explorer.Selection.List == 1 and Explorer.Selection.List[1] == nodes[model],
		"plus insertion selects its target like the native popup controller"
	)
	Explorer.InsertObjectContext:Hide()
	local oldReveal = Explorer.MakeNodeVisible
	local reveals = 0
	Explorer.MakeNodeVisible = function()
		reveals += 1
	end
	local insertCalls = {}
	local oldInsert = Apps.InsertionService.Insert
	Apps.InsertionService.Insert = function(className, targets, options)
		insertCalls[#insertCalls + 1] = options
		options.Reveal(targets[1])
		return {}
	end
	local item
	for _, entry in ipairs(Explorer.InsertObjectContext.Items) do
		if entry.OnClick then
			item = entry
			break
		end
	end
	assert(item, "insertion menu retains its logical class action")
	Settings.Explorer.ExpandHierarchy = false
	item.OnClick(item.Name)
	assert(reveals == 0, "changing ExpandHierarchy after startup disables insertion reveal")
	Settings.Explorer.ExpandHierarchy = true
	item.OnClick(item.Name)
	assert(reveals == 1, "changing ExpandHierarchy after startup enables insertion reveal")
	Apps.InsertionService.Insert = oldInsert
	Explorer.MakeNodeVisible = oldReveal
	-- Real popup handlers: Studio starts repeating after 500 ms, then every 20 ms.
	local oldDelay = task.delay
	local scheduled = {}
	task.delay = function(delay, callback)
		if delay == 0.5 or delay == 0.02 then
			scheduled[#scheduled + 1] = { delay, callback }
		else
			return oldDelay(delay, callback)
		end
	end
	local function beginHistoryHold()
		Explorer.CloseHeaderPopup()
		Explorer.SearchHistory = { "First", "Second", "Third" }
		toolbar.SearchFrame.History.Activated:Fire()
		keys.Down = true
		service.UserInputService.InputBegan:Fire(
			{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
			false
		)
		return scheduled[#scheduled][2], #scheduled
	end
	local pending, count = beginHistoryHold()
	assert(
		scheduled[count][1] == 0.5 and popup.Items:GetChildren()[2].BackgroundTransparency == 0.92,
		"history arrow press selects immediately and schedules the source initial delay"
	)
	pending()
	assert(
		popup.Items:GetChildren()[3].BackgroundTransparency == 0.92
			and #scheduled == count + 1
			and scheduled[#scheduled][1] == 0.02,
		"held history arrow advances using the source repeat interval"
	)
	pending = scheduled[#scheduled][2]
	count = #scheduled
	service.UserInputService.InputEnded:Fire({
		UserInputType = Enum.UserInputType.Keyboard,
		KeyCode = Enum.KeyCode.Down,
	})
	pending()
	assert(
		#scheduled == count and popup.Items:GetChildren()[3].BackgroundTransparency == 0.92,
		"released popup arrows cannot repeat"
	)
	pending, count = beginHistoryHold()
	Explorer.CloseHeaderPopup()
	pending()
	assert(#scheduled == count, "closing a popup invalidates its pending key repeat")
	pending, count = beginHistoryHold()
	search.Text = "new query"
	search:GetPropertyChangedSignal("Text"):Fire()
	pending()
	assert(#scheduled == count, "typing invalidates an earlier dropdown repeat")
	pending, count = beginHistoryHold()
	Main.Alive = false
	pending()
	Main.Alive = true
	assert(#scheduled == count, "shutdown guard stops a pending dropdown repeat")
	pending, count = beginHistoryHold()
	keys.LeftShift = true
	pending()
	keys.LeftShift = false
	assert(#scheduled == count, "modifiers cancel an already held popup arrow")
	Explorer.CloseHeaderPopup()
	toolbar.Options.Activated:Fire()
	count = #scheduled
	keys.LeftControl = true
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
		false
	)
	keys.LeftControl = false
	assert(#scheduled == count, "Ctrl+arrow does not start settings dropdown repeat")
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
		false
	)
	scheduled[#scheduled][2]()
	assert(
		popup.Items:GetChildren()[2].BackgroundTransparency == 0.92,
		"held settings arrows use the same keyboard selection controller"
	)
	Explorer.CloseHeaderPopup()
	search.Text = "Anchored="
	search:GetPropertyChangedSignal("Text"):Fire()
	service.UserInputService.InputBegan:Fire(
		{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
		false
	)
	scheduled[#scheduled][2]()
	assert(popup.Items:GetChildren()[1].BackgroundTransparency == 0.92, "held autocomplete arrow wraps its choices")
	service.UserInputService.InputEnded:Fire({
		UserInputType = Enum.UserInputType.Keyboard,
		KeyCode = Enum.KeyCode.Down,
	})
	keys.Down = false
	task.delay = oldDelay
	Explorer.CloseHeaderPopup()
	search:ReleaseFocus()
	Explorer.SearchHistory = savedHistory
	Settings.Explorer.SearchHistoryByPlace = savedPlaces
	Main.SaveSettings = savedSave
	deps.env.setclipboard = savedClipboard
	Settings.Explorer.ExpandHierarchy = savedExpand
	Settings.Explorer.IncrementNames = savedIncrement
	Explorer.Selection:SetTable(savedSelection)
	Explorer.ClearSearch()
	flushTasks()
	print(
		"PASS: source search history, persistence, help action, additive result stepping and insertion target/preferences"
	)
end

--!strict

-- Install the real Lib.CodeFrame TextBox bridge and focus-bound keyboard route.
-- Earlier controller tests bypassed both, missing native cut/paste/undo events.
local saved = {}
local controllerCopyBuffer = cf.SetCopyableSelection
for name, method in pairs(funcs) do
	saved[name] = cf[name]
	cf[name] = method
end
cf.SetCopyableSelection = controllerCopyBuffer
local box = cf.GuiElems.EditBox
assert(
	box.Visible
		and box.TextEditable
		and not box.ClearTextOnFocus
		and box.TextTransparency == 1
		and box.Size.X.Offset == 1,
	"real CodeFrame input can receive native focus while remaining visually hidden"
)
local oldMetatable = getmetatable(box)
local propertyMetatable = table.clone(oldMetatable)
local deferredTextEvents = false
local queuedTextEvents = {}
propertyMetatable.__newindex = function(object, key, value)
	local before = object[key]
	oldMetatable.__newindex(object, key, value)
	if key == "Text" and before ~= value then
		if deferredTextEvents then
			queuedTextEvents[#queuedTextEvents + 1] = object
		else
			object:GetPropertyChangedSignal("Text"):Fire()
		end
	end
end
local function flushTextEvents()
	local count = 0
	while #queuedTextEvents > 0 do
		count += 1
		assert(count < 100, "deferred input must settle without a rewrite loop")
		table.remove(queuedTextEvents, 1):GetPropertyChangedSignal("Text"):Fire()
	end
end
setmetatable(box, propertyMetatable)
setupEditBox(cf)
local oldWrite, oldRead = deps.env.setclipboard, deps.env.getclipboard
local copied
deps.env.setclipboard = function(value)
	copied = value
end
deps.env.getclipboard = function()
	return "pasted"
end
editor.OpenDocument("real-input-route", "Native clipboard tests", "alpha beta")
box:CaptureFocus()
local function select(first, last)
	cf.SelectionRange = { { first, 0 }, { last, 0 } }
	cf:MoveCursor(last, 0)
	cf:SetCopyableSelection()
end
local function begin(key)
	keys.LeftControl = true
	keys[key] = true
	service.UserInputService.InputBegan:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = key })
end
local function finish(key)
	keys[key] = false
	keys.LeftControl = false
	service.UserInputService.InputEnded:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = key })
end
select(0, 5)
assert(
	box.Text == "alpha" and box.SelectionStart == 1 and box.CursorPosition == 6,
	"real native buffer mirrors selected source"
)
begin(Enum.KeyCode.X)
assert(cf:GetText() == " beta" and copied == "alpha", "focused Ctrl+X cuts through the real input route")
-- Roblox still runs its native TextBox operation after UIS listeners return.
box.Text = ""
finish(Enum.KeyCode.X)
assert(cf:GetText() == " beta", "native cut cannot delete a second range")
begin(Enum.KeyCode.Z)
box.Text = "alpha"
finish(Enum.KeyCode.Z)
assert(cf:GetText() == "alpha beta", "Ctrl+Z restores one source transaction and ignores TextBox history")
begin(Enum.KeyCode.Y)
box.Text = "stale native history"
finish(Enum.KeyCode.Y)
assert(cf:GetText() == " beta", "Ctrl+Y uses source redo without appending native history")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
select(0, 5)
begin(Enum.KeyCode.V)
assert(cf:GetText() == "pasted beta", "Ctrl+V explicitly routes to executor clipboard capability")
box.Text = "pasted"
finish(Enum.KeyCode.V)
assert(cf:GetText() == "pasted beta", "native paste notification is suppressed after API paste")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
assert(cf:GetText() == "alpha beta", "API paste remains one undo transaction")
do
	local previous = editor.ActiveDocument
	editor.OpenDocument("repeat-history", "Held shortcuts", "start")
	box:CaptureFocus()
	select(5, 5)
	editor.Command("InsertText", { Text = "a" })
	editor.Command("InsertText", { Text = "b" })
	editor.Command("InsertText", { Text = "c" })
	begin(Enum.KeyCode.Z)
	assert(cf:GetText() == "startab", "holding undo applies the first change immediately")
	flushTasks()
	flushTasks()
	assert(cf:GetText() == "start", "held Ctrl+Z repeats through source history")
	finish(Enum.KeyCode.Z)
	begin(Enum.KeyCode.Y)
	assert(cf:GetText() == "starta")
	flushTasks()
	assert(cf:GetText() == "startab", "held Ctrl+Y repeats through source history")
	keys.LeftControl = false
	service.UserInputService.InputEnded:Fire({ KeyCode = Enum.KeyCode.LeftControl })
	flushTasks()
	assert(cf:GetText() == "startab", "releasing Ctrl stops repeat even while Y is down")
	finish(Enum.KeyCode.Y)
	editor.SelectDocument(previous)
	box:CaptureFocus()
end
-- Executors need not expose getclipboard/setclipboard: Roblox's focused
-- TextBox supplies OS clipboard text and the native cut notification instead.
deps.env.setclipboard = nil
deps.env.getclipboard = nil
select(0, 5)
begin(Enum.KeyCode.V)
box.Text = "native"
finish(Enum.KeyCode.V)
assert(cf:GetText() == "native beta", "native paste works without a clipboard reader")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
assert(cf:GetText() == "alpha beta", "native paste is one undo transaction")
select(0, 5)
begin(Enum.KeyCode.X)
box.Text = ""
finish(Enum.KeyCode.X)
assert(cf:GetText() == " beta", "empty native Text event deletes the selected source without a clipboard writer")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
assert(cf:GetText() == "alpha beta", "native cut is one undo transaction")
select(0, 0)
assert(box.Text == "alpha beta\n", "native clipboard buffer selects the whole current line")
begin(Enum.KeyCode.X)
box.Text = ""
finish(Enum.KeyCode.X)
assert(cf:GetText() == "", "native cut with no selection deletes the copied whole line")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
assert(cf:GetText() == "alpha beta", "whole-line native cut can be undone")
select(0, 0)
keys.LeftControl = true
keys.X = true
box.Text = ""
begin(Enum.KeyCode.X)
finish(Enum.KeyCode.X)
assert(cf:GetText() == "", "native-first whole-line cut deletes once")
begin(Enum.KeyCode.V)
box.Text = "alpha beta\n"
finish(Enum.KeyCode.V)
assert(cf:GetText() == "alpha beta\n", "native-first cut retains structured whole-line clipboard semantics")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
assert(cf:GetText() == "alpha beta", "native-first cut/paste remain separate atomic history steps")
-- Native event first: do not run the API fallback a second time on InputBegan.
deps.env.getclipboard = function()
	return "duplicate"
end
select(0, 5)
keys.LeftControl = true
keys.V = true
box.Text = "first"
begin(Enum.KeyCode.V)
finish(Enum.KeyCode.V)
assert(cf:GetText() == "first beta", "native event before InputBegan cannot paste twice")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
select(0, 5)
deps.env.getclipboard = function()
	return "blocked"
end
cf.Editable = false
begin(Enum.KeyCode.V)
box.Text = "blocked"
finish(Enum.KeyCode.V)
assert(cf:GetText() == "alpha beta", "read-only source ignores API and native paste")
cf.Editable = true
-- Pending native clipboard events from one tab must never edit the next tab.
select(0, 5)
deps.env.getclipboard = nil
begin(Enum.KeyCode.V)
local previousDocument = editor.ActiveDocument
editor.OpenDocument("native-input-other", "Other native input", "untouched")
assert(box.Text == "untouched\n", "switching documents replaces the old native copy buffer with the current line")
box.Text = "late old-tab clipboard"
assert(cf:GetText() == "untouched", "a pending old-tab native paste cannot edit a different document")
finish(Enum.KeyCode.V)
editor.SelectDocument(previousDocument)
-- Ordinary input still follows the original bridge exactly once.
select(0, 0)
box.Text = "typed"
assert(cf:GetText() == "typedalpha beta", "ordinary TextBox input is not swallowed by a stale clipboard operation")
deps.env.getclipboard = function()
	return "!"
end
begin(Enum.KeyCode.V)
box.Text = "!"
finish(Enum.KeyCode.V)
begin(Enum.KeyCode.V)
box.Text = "!"
finish(Enum.KeyCode.V)
assert(
	cf:GetText() == "typed!!alpha beta",
	"separate Ctrl+V presses after key release are not swallowed by deduplication"
)
local before = cf:GetText()
begin(Enum.KeyCode.V)
finish(Enum.KeyCode.V)
before = cf:GetText()
box:ReleaseFocus()
box.Text = "late paste notification"
assert(cf:GetText() == before, "late native events after losing focus cannot mutate source")
begin(Enum.KeyCode.Y)
finish(Enum.KeyCode.Y)
assert(cf:GetText() == before, "source history shortcuts ignore a different or absent text focus")
deferredTextEvents = true
editor.OpenDocument("deferred-input-route", "Deferred native input", "alpha beta")
box:CaptureFocus()
select(0, 0)
flushTextEvents()
assert(cf:GetText() == "alpha beta", "deferred whole-line clipboard mirroring cannot insert source")
for index = 1, 5 do
	cf:SetEditing(true)
	select(index, index)
	flushTextEvents()
	assert(cf:GetText() == "alpha beta", "repeated mouse focus and release cannot duplicate text")
end
select(0, 5)
flushTextEvents()
assert(cf:GetText() == "alpha beta", "deferred selection mirroring cannot insert selected source")
box.Text = "q"
flushTextEvents()
assert(cf:GetText() == "q beta", "deferred ordinary typing replaces selected source exactly once")
begin(Enum.KeyCode.Z)
finish(Enum.KeyCode.Z)
flushTextEvents()
assert(cf:GetText() == "alpha beta", "deferred input remains a single source undo transaction")
local function completeWithKey(key, nativeFirst, payload)
	cf:SetText("math.sq")
	select(7, 7)
	flushTextEvents()
	assert(editor.Complete(), "completion fixture has a visible suggestion")
	local user = service.UserInputService
	local input = { UserInputType = Enum.UserInputType.Keyboard, KeyCode = key }
	keys[key] = true
	if nativeFirst then
		box.Text = payload
		flushTextEvents()
		assert(cf:GetText() == "math.sq", "native input leaves the suggestion and source intact before InputBegan")
	end
	user.InputBegan:Fire(input)
	assert(cf:GetText() == "math.sqrt()", "physical key accepts the completion without indenting")
	flushTasks()
	keys[key] = false
	user.InputEnded:Fire(input)
	box.Text = payload
	flushTextEvents()
	assert(cf:GetText() == "math.sqrt()", "late native input never adds a second edit")
	editor.Undo(false)
	assert(cf:GetText() == "math.sq", "completion acceptance has one undo step")
end
completeWithKey(Enum.KeyCode.Tab, false, "\t")
completeWithKey(Enum.KeyCode.Tab, true, "    ")
completeWithKey(Enum.KeyCode.Return, true, "\r\n")
deferredTextEvents = false
completeWithKey(Enum.KeyCode.Tab, true, "\t")
completeWithKey(Enum.KeyCode.Return, false, "\n")
cf:SetText("math.s")
select(6, 6)
assert(editor.Complete())
box.Text = "q"
local tabInput = { UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Tab }
keys.Tab = true
service.UserInputService.InputBegan:Fire(tabInput)
keys.Tab = false
service.UserInputService.InputEnded:Fire(tabInput)
assert(cf:GetText() == "math.sqrt()", "Tab accepts the refreshed suggestion before the deferred repaint")
cf:SetText("math.sq\nlocal value")
cf:MoveCursor(7, 0)
cf.SelectionRange = { { 7, 0 }, { 7, 0 } }
cf.AdditionalSelections = { { { 5, 1 }, { 5, 1 } } }
assert(editor.Complete(), "the primary caret still offers autocomplete with secondary carets")
assert(editor.AcceptCompletion(false) and cf:GetText() == "math.sqrt()\nlocal value")
assert(#cf.AdditionalSelections == 1 and cf.AdditionalSelections[1][1][1] == 5, "completion preserves secondary caret position")
cf.AdditionalSelections = {}
local function plainKey(key, payload)
	local input = { UserInputType = Enum.UserInputType.Keyboard, KeyCode = key }
	keys[key] = true
	service.UserInputService.InputBegan:Fire(input)
	keys[key] = false
	service.UserInputService.InputEnded:Fire(input)
	box.Text = payload
end
cf:SetText("local value")
select(11, 11)
plainKey(Enum.KeyCode.Tab, "\t")
assert(cf:GetText() == "local value    ", "Tab without suggestions still indents exactly once")
cf:SetText("    local value")
select(15, 15)
plainKey(Enum.KeyCode.Return, "\n")
assert(cf:GetText() == "    local value\n    ", "Enter without suggestions still inserts one indented line")
cf:SetText("if ex")
select(5, 5)
assert(editor.Complete(), "the partial condition also has an autocomplete candidate")
plainKey(Enum.KeyCode.Return, "\n")
assert(cf:GetText() == "if ex then\n    \nend" and cf.CursorY == 1 and cf.CursorX == 4)
editor.Undo(false)
assert(cf:GetText() == "if ex", "completing a header is one undo transaction")
cf:SetText("math.sqrt")
select(#"math.sqrt", #"math.sqrt")
box.Text = "("
flushTasks()
assert(editor.SignatureHelp.Visible, "typing an opening parenthesis triggers signature help")
cf:HandleEditorPointer({ UserInputType = Enum.UserInputType.MouseButton1 }, 10, 0)
flushTasks()
assert(not editor.SignatureHelp.Visible, "clicking without typing dismisses signature help even if the caret stays put")
cf:MoveCursor(9, 0)
cf:MoveCursor(10, 0)
flushTasks()
assert(not editor.SignatureHelp.Visible, "moving the caret alone does not open signature help")
cf:SetText("object:WaitForChild()\nwatchProfile()\nwatchCharacter()\nwar")
cf:MoveCursor(3, 3)
cf.SelectionRange = { { 3, 3 }, { 3, 3 } }
assert(editor.Complete())
local suggestions = editor.CompletionPopup.Suggestions
assert(suggestions.Suggestion1.Label.Text == "warn")
assert(suggestions.Suggestion1.Kind.Image == "mockasset://native/editor/completion/function")
assert(not suggestions.Suggestion2 or not suggestions.Suggestion2.Visible, "member and incidental fuzzy matches stay out of global completion")
assert(editor.CompletionPopup.Documentation.Signature.Text == "warn(...: T...): ()")
assert(editor.AcceptCompletion(false))
flushTasks()
assert(cf:GetText():sub(-6) == "warn()" and cf.CursorX == 5)
assert(editor.SignatureHelp.Visible and editor.SignatureHelp.Signature.Text == "warn(<b>...: T...</b>): ()")
do
	local user = service.UserInputService
	local lines = cf.GuiElems.LinesFrame or cf.Frame
	local oldLines = cf.GuiElems.LinesFrame
	cf.GuiElems.LinesFrame = lines
	local oldX, oldY = Main.Mouse.X, Main.Mouse.Y
	local oldRun = service.RunService
	service.RunService = { RenderStepped = signal() }
	setupMouseSelection(cf)
	local function move(column, row)
		Main.Mouse.X = lines.AbsolutePosition.X + cf:GetColumnPixelX(column, row) + 1
		Main.Mouse.Y = lines.AbsolutePosition.Y + row * cf.FontSize + 1
	end
	local click = { UserInputType = Enum.UserInputType.MouseButton1 }
	local function down()
		click.Position = Vector2.new(Main.Mouse.X, Main.Mouse.Y)
		lines.InputBegan:Fire(click)
	end
	local function up()
		user.InputEnded:Fire(click)
	end
	local function clickAt(column, row)
		move(column, row)
		down()
		up()
		flushTasks()
	end
	cf:SetText("Color3.fromRGB(255, 0, 0)\n\nColor3.fromRGB(0, 255, 0)")
	cf.ViewX, cf.ViewY = 0, 0
	clickAt(#"Color3.fromRGB(255, ", 0)
	assert(editor.SignatureHelp.Visible and editor.SignatureHelp.Signature.Text:find("<b>green:", 1, true))
	local swatch = editor.SignatureHelp.Parent.ColorSwatch
	assert(swatch.Visible and swatch.BackgroundColor3.R == 1 and swatch.BackgroundColor3.G == 0)
	clickAt(0, 1)
	assert(not editor.SignatureHelp.Visible and not swatch.Visible)
	clickAt(#"Color3.fromRGB(0, 255, ", 2)
	assert(editor.SignatureHelp.Visible and editor.SignatureHelp.Signature.Text:find("<b>blue:", 1, true))
	assert(swatch.Visible and swatch.BackgroundColor3.R == 0 and swatch.BackgroundColor3.G == 1)
	local previousPicker = Lib.ColorPicker
	local pickerSelection = signal()
	local pickerColor
	Lib.ColorPicker = {
		new = function()
			return {
				OnSelect = pickerSelection,
				SetColor = function(_, color) pickerColor = color end,
				Show = function() end,
				Window = { Close = function() end, Gui = Instance.new("Frame") },
			}
		end,
	}
	swatch.MouseButton1Click:Fire()
	assert(pickerColor.G == 1, "the swatch opens the picker with the active call's color")
	pickerSelection:Fire(Color3.fromRGB(15, 20, 25))
	assert(cf:GetText() == "Color3.fromRGB(255, 0, 0)\n\nColor3.fromRGB(15, 20, 25)")
	Lib.ColorPicker = previousPicker
	move(#"Color3.fromRGB(", 0)
	down()
	move(#"Color3.fromRGB(255, 0", 0)
	user.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement })
	up()
	flushTasks()
	assert(not editor.SignatureHelp.Visible and not swatch.Visible, "drag selection leaves signature help closed")
	local previousScroll = cf.ScrollH
	cf.ScrollH = { Index = 5, ScrollTo = function(self, index) self.Index = index end }
	cf.ViewX = 5
	clickAt(0, 1)
	assert(cf.CursorY == 1 and cf.CursorX == 0 and cf.ViewX == 0, "clicking a blank line reveals its caret after horizontal scrolling")
	cf.ScrollH = previousScroll
	cf:SetText("local café_name = 1\nreturn café_name")
	cf.ViewX, cf.ViewY = 0, 0
	local createDocument = Apps.EditorDocument.Create
	local rebuilt = 0
	Apps.EditorDocument.Create = function(text)
		rebuilt += 1
		return createDocument(text)
	end
	move(8, 0)
	down()
	up()
	assert(editor.CaptureClipboardPacket().WholeLines[1], "single click only moves the caret")
	down()
	up()
	assert(editor.CaptureClipboardPacket().Text == "café_name" and box.Text == "café_name")
	down()
	up()
	assert(editor.CaptureClipboardPacket().Text == "local café_name = 1\n")
	down()
	up()
	assert(editor.CaptureClipboardPacket().WholeLines[1], "the click sequence restarts after selecting a line")
	down()
	move(2, 1)
	user.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement })
	up()
	assert(editor.CaptureClipboardPacket().Text == "café_name = 1\nreturn", "double-click drag extends by words")
	assert(cf:GetText() == "local café_name = 1\nreturn café_name", "selection never edits the document")
	keys.LeftShift = true
	move(6 + #"café", 0)
	down()
	up()
	assert(editor.CaptureClipboardPacket().Text == "café", "Shift-click keeps the existing anchor")
	move(2, 0)
	down()
	up()
	assert(editor.CaptureClipboardPacket().Text == "cal ", "Shift-click can reverse an existing selection")
	move(6, 0)
	down()
	move(2, 1)
	user.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement })
	up()
	keys.LeftShift = false
	assert(editor.CaptureClipboardPacket().Text == "café_name = 1\nre", "Shift-drag continues extending the same anchor")
	assert(rebuilt == 0, "moving or extending the caret reuses the document line index")
	Apps.EditorDocument.Create = createDocument
	service.RunService = oldRun
	cf.GuiElems.LinesFrame = oldLines
	Main.Mouse.X, Main.Mouse.Y = oldX, oldY
end
do
	local repetitions = 1200
	cf:SetText(("needle "):rep(repetitions))
	select(0, 6)
	assert(editor.AddMatchingCursors(true))
	local matching = editor.GetSelections()
	assert(#matching == repetitions and matching[#matching].First == (repetitions - 1) * 7 + 1)
	assert(editor.AddMatchingCursors(true) and #editor.GetSelections() == repetitions, "existing matches are not duplicated")
end
deps.env.setclipboard = oldWrite
deps.env.getclipboard = oldRead
cf:DisconnectEditBoxEvent()
setmetatable(box, oldMetatable)
for name, method in pairs(saved) do
	cf[name] = method
end
print(
	"PASS: actual CodeFrame focus and Text bridge, Ctrl+X/V/Z/Y, native clipboard fallback, both event orders, duplicate suppression, atomic history and read-only guards"
)

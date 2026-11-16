--!strict

Apps.ScriptViewer.Init(true)
local lazyWindow = Apps.ScriptViewer.Window
assert(
	rawget(Apps.ScriptViewer, "CodeFrame") == nil and rawget(Apps.ScriptViewer, "Documents") == nil,
	"startup defers all editor content and documents"
)
local shellInstances = #lazyWindow.GuiElems.Content:GetDescendants()
lazyWindow.OnActivate:Fire()
assert(rawget(Apps.ScriptViewer, "CodeFrame") ~= nil, "first window activation builds the editor")
assert(
	#lazyWindow.GuiElems.Content:GetDescendants() > shellInstances,
	"editor controls are created only after activation"
)
print(
	"PASS: deferred startup avoids creating "
		.. (#lazyWindow.GuiElems.Content:GetDescendants() - shellInstances)
		.. " editor UI instances until first use"
)
local firstCodeFrame = Apps.ScriptViewer.CodeFrame
Apps.ScriptViewer.EnsureEditor()
assert(
	Apps.ScriptViewer.CodeFrame == firstCodeFrame and Apps.ScriptViewer.Window == lazyWindow,
	"editor initialization is idempotent and retains window identity"
)
Apps.ScriptViewer.Init()
local editor = Apps.ScriptViewer
local cf = editor.CodeFrame
local initial = editor.Documents[1]
assert(editor.Window.Closed, "editor starts closed")
local doc = editor.OpenDocument("first", "First", "if true then")
cf:MoveCursor(12, 0)
cf:AppendText("\n")
assert(cf:GetText() == "if true then\n    \nend" and cf.CursorY == 1 and cf.CursorX == 4, "newline completes and indents the block")
cf:AppendText("print(1)")
local source = cf:GetText()
local count = cf.HighlightCount
cf:SetText(source)
assert(cf.HighlightCount == count, "same source skips expensive highlighting")
editor.Undo(false)
assert(cf:GetText() ~= source, "undo changes source")
editor.Undo(true)
assert(cf:GetText() == source, "redo restores text")
cf:MoveCursor(3, 1)
local other = editor.OpenDocument("second", "Second", "alpha Alpha alpha\nline two")
editor.SelectDocument(doc)
assert(cf:GetText() == source and cf.CursorX == 3 and cf.CursorY == 1, "switching tabs keeps text and caret")
editor.SelectDocument(other)
local function named(name)
	for _, gui in ipairs(editor.Window.GuiElems.Content:GetDescendants()) do
		if gui.Name == name then
			return gui
		end
	end
end
local find = named("Find")
local replace = named("Replace")
find.Text = "alpha"
cf.AdditionalSelections = { { { 0, 1 }, { 0, 1 } } }
assert(editor.FindNext() and cf.SelectionRange[1][1] == 0, "find selects first exact range")
assert(#cf.AdditionalSelections == 0, "Find clears unrelated extra carets")
assert(editor.FindNext() and cf.SelectionRange[1][1] == 6, "default search ignores case")
replace.Text = "%1!"
cf.AdditionalSelections = { { { 0, 1 }, { 0, 1 } } }
editor.Replace(true)
assert(#cf.AdditionalSelections == 0, "Replace clears stale extra carets")
assert(cf:GetText() == "%1! %1! %1!\nline two", "replace all treats replacement literally")
editor.Undo(false)
assert(cf:GetText() == "alpha Alpha alpha\nline two", "replace all is one undo step")
editor.Undo(true)
assert(cf:GetText() == "%1! %1! %1!\nline two", "replace redo")
find.Text = "%1!"
editor.FindNext()
replace.Text = "one"
editor.Replace(false)
assert(cf:GetText() == "one %1! %1!\nline two", "single replace preserves other matches")
cf:SetText("a\r\nb\r\nc\n")
assert(#cf.Lines == 4, "CRLF files preserve line count and trailing newline")
local line = named("GoToLine")
cf.AdditionalSelections = { { { 0, 0 }, { 0, 0 } } }
line.Text = "999"
line.FocusLost:Fire(true)
assert(cf.CursorY == 3, "go-to-line clamps to final line")
assert(
	#cf.AdditionalSelections == 0 and cf.SelectionRange[1][2] == 3,
	"go-to-line resets the complete selection at the destination"
)
editor.CloseDocument(other)
assert(not table.find(editor.Documents, other), "close removes tab")
cf.GuiElems.EditBox:CaptureFocus()
keys.LeftControl = true
keys.LeftShift = true
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.T })
keys.LeftControl = false
keys.LeftShift = false
assert(
	editor.Documents[#editor.Documents] == other and cf:GetText() == "a\nb\nc\n",
	"closed tab restores edited contents"
)
local run
for _, gui in ipairs(editor.Window.GuiElems.Content:GetDescendants()) do
	if gui.Text == "Run" then
		run = gui
	end
end
deps.env.loadstring = function()
	return nil, "bad syntax"
end
run.MouseButton1Click:Fire()
assert(named("Status").Text == "Compile error: bad syntax", "compile error stays in editor status")
deps.env.loadstring = function()
	return function()
		error("bad runtime")
	end
end
run.MouseButton1Click:Fire()
assert(named("Status").Text:find("Runtime error:", 1, true), "runtime errors captured")
deps.env.loadstring = function()
	return function() end
end
run.MouseButton1Click:Fire()
assert(named("Status").Text == "Execution completed", "successful run status")
print(
	"PASS: actual editor tabs, caret retention, undo/redo, find, literal replacements, CRLF, go-to-line, closed-tab recovery and execution errors"
)

-- Layout constraints run on actual editor frames and event handlers.
local root = editor.Window.GuiElems.Main
local content = editor.Window.GuiElems.Content
local toolbar = named("EditorToolbar")
local tabs = named("Documents")
local findPanel = named("FindReplace")
assert(
	tabs.Position.Y.Offset == 0 and tabs.Size.Y.Offset == 26 and not toolbar.Parent.Visible,
	"compact native document row replaces permanent toolbar"
)
assert(named("DocumentCommands"), "commands remain accessible from document menu")
assert(root.Position.X.Offset == 100 and root.Position.Y.Offset == 80, "initial window is centered and fits viewport")
local function shortcut(key, shift)
	cf.GuiElems.EditBox:CaptureFocus()
	keys.LeftControl = true
	keys.LeftShift = shift == true
	service.UserInputService.InputBegan:Fire({ KeyCode = key })
	keys.LeftControl = false
	keys.LeftShift = false
end
shortcut(Enum.KeyCode.F)
assert(
	findPanel.Visible and findPanel.Size.Y.Offset == 51 and not replace.Visible,
	"find opens native search and matching-option rows"
)
assert(cf.Frame.Position.Y.Offset == 26, "find overlays code without shifting its rows")
shortcut(Enum.KeyCode.H)
assert(
	replace.Visible and findPanel.Size.Y.Offset == 73 and cf.Frame.Position.Y.Offset == 26,
	"replace expands over code without reflow"
)
service.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.Escape })
assert(not findPanel.Visible and cf.Frame.Position.Y.Offset == 26, "closing search preserves code position")
editor.Window.Gui.ViewportSize = Vector2.new(400, 340)
editor.Window.Gui:GetPropertyChangedSignal("AbsoluteSize"):Fire()
assert(root.Size.X.Offset <= 400 and root.Size.Y.Offset <= 340, "editor fits small screen")
assert(root.Position.X.Offset >= 0 and root.Position.Y.Offset >= 0, "editor stays on screen")
assert(findPanel.Position.X.Scale == 1 and findPanel.Size.X.Offset == 280, "search is a narrow right-anchored overlay")
assert(
	cf.GutterWidthMinimum == 54
		and cf.Frame.BackgroundColor3.R == 37 / 255
		and cf.Frame.BackgroundColor3.G == 37 / 255
		and cf.Frame.BackgroundColor3.B == 37 / 255,
	"native reference editor surface and gutter"
)
assert(
	cf.Frame.AbsolutePosition.Y + cf.Frame.AbsoluteSize.Y <= named("EditorFooter").AbsolutePosition.Y,
	"code never overlaps status bar"
)
print(
	"PASS: actual editor centering, small-screen fit, tab/toolbar order, compact find/replace expansion, clipping and status-bar separation"
)

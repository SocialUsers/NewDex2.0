--!strict

local actualCursorUpdate = funcs.UpdateCursor
do
	local styled = {
		Frame = Instance.new("Frame"),
		Colors = {},
		ScrollV = Lib.ScrollBar.new(),
		ScrollH = Lib.ScrollBar.new(true),
		MakeRichTemplates = function() end,
	}
	Apps.StudioEditorSkin.Apply(styled)
	for _, bar in ipairs({ styled.ScrollV, styled.ScrollH }) do
		bar.TotalSpace = 100
		bar.VisibleSpace = 10
		bar.Gui.Size = UDim2.fromOffset(100, 100)
		bar:Update()
		assert(bar.Gui.BackgroundTransparency == 0, "editor scrollbar track is opaque")
		assert(
			bar.GuiElems.ScrollThumb.Visible and bar.GuiElems.ScrollThumb.BackgroundTransparency == 0,
			"overflow thumb remains visible"
		)
		assert(
			bar.GuiElems.ScrollThumbFrame.ZIndex > bar.Gui.ZIndex
				and bar.GuiElems.ScrollThumb.ZIndex > bar.GuiElems.ScrollThumbFrame.ZIndex,
			"opaque track cannot cover the thumb in Global ZIndex mode"
		)
		assert(bar.GuiElems.MarkerFrame.ZIndex > bar.Gui.ZIndex, "markers remain above the track")
	end
end
local frame = Instance.new("Frame")
local lines = Instance.new("Frame", frame)
lines.Name = "Lines"
local numbers = Instance.new("TextLabel", frame)
numbers.Name = "LineNumbers"
local corner = Instance.new("Frame", frame)
local cf = setmetatable({
	Frame = frame,
	FontSize = 14,
	Lines = {},
	MaxTextCols = 200,
	ScrollV = Lib.ScrollBar.new(),
	ScrollH = Lib.ScrollBar.new(true),
	ViewX = 9999,
	ViewY = 9999,
	GuiElems = { ScrollCorner = corner },
}, { __index = funcs })
for i = 1, 125 do
	cf.Lines[i] = "line"
end
cf.ScrollV.Gui.Parent = frame
cf.ScrollH.Gui.Parent = frame
for _, width in ipairs({ 340, 520, 900 }) do
	frame.Size = UDim2.fromOffset(width, 317)
	cf:UpdateView()
	assert(cf.ViewX % 1 == 0 and cf.ViewY % 1 == 0, "scroll offsets stay whole rows/columns at bottom edge")
	assert(lines.Position.X.Offset == 42, "gutter sized for three-digit line numbers")
	assert(
		lines.AbsolutePosition.X + lines.AbsoluteSize.X == cf.ScrollV.Gui.AbsolutePosition.X,
		"code stops at vertical track"
	)
	assert(
		lines.AbsolutePosition.Y + lines.AbsoluteSize.Y == cf.ScrollH.Gui.AbsolutePosition.Y,
		"code stops at horizontal track"
	)
	assert(
		cf.ScrollH.Gui.AbsolutePosition.X == lines.AbsolutePosition.X,
		"horizontal track aligns with code, not gutter"
	)
	assert(
		cf.ScrollV.Gui.Size.X.Offset == 10 and cf.ScrollH.Gui.Size.Y.Offset == 10,
		"editor uses shared scrollbar thickness"
	)
end
cf.Lines = { "short" }
cf.MaxTextCols = 5
cf:UpdateView()
assert(not cf.ScrollV.Gui.Visible and not cf.ScrollH.Gui.Visible, "short document has no unnecessary tracks")
assert(lines.Size.Y.Offset == 0 and lines.Size.X.Offset == -28, "hidden tracks return their space to code")
print(
	"PASS: actual code viewport geometry at three widths, gutter alignment, scrollbar bounds, integer scroll endpoints and short-document track removal"
)

-- Exercise actual renderer, including reused labels and explicit row gutters.
cf.Colors = {
	Text = Color3.fromRGB(220, 220, 220),
	SelectionBack = Color3.fromRGB(40, 80, 130),
	CurrentLine = Color3.fromRGB(35, 35, 35),
}
cf.RichTemplates = { Text = "", Selection = '<font color="rgb(255,255,255)">' }
cf.SelectionRange = { { -1, -1 }, { -1, -1 } }
cf.CursorY = 1
cf.CursorX = 0
cf.LineFrames = {}
cf.HighlightLine = function()
	return {}
end
cf.UpdateCursor = function() end
cf.Lines = {}
for i = 1, 100 do
	cf.Lines[i] = "local value = " .. i
end
cf.MaxTextCols = 30
frame.Size = UDim2.fromOffset(340, 98)
cf.ViewX = 0
cf.ViewY = 0
cf:UpdateView()
local syntax = {
	typeMap = {},
	richReplace = { ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;", ['"'] = "&quot;", ["'"] = "&apos;" },
}
funcs.Refresh(cf, syntax)
local retained = cf.LineFrames[2]
local retainedLabel = retained.Label
funcs.SetDefinitionLink(cf, { Row = 1, First = 6, Last = 11 })
assert(retainedLabel.Text == "local <u>value</u> = 2", "definition underline belongs to the rendered glyphs")
assert(cf.LineFrames[1].Label.Text == "local value = 1", "neighboring rows remain untouched")
funcs.SetDefinitionLink(cf, nil)
assert(retainedLabel.Text == "local value = 2", "clearing the definition restores the row label")
assert(
	retained.ActiveLine.Visible and not cf.LineFrames[1].ActiveLine.Visible,
	"active line background tracks current row"
)
assert(
	cf.NumberFrames[retained].Text == "2" and cf.NumberFrames[retained].Position.Y.Offset == 14,
	"gutter uses independent exactly aligned line labels"
)
cf.ViewY = 1
funcs.Refresh(cf, syntax)
assert(
	cf.LineFrames[1] == retained and retained.Label == retainedLabel,
	"scroll keeps still-visible document labels and recycles departing rows only"
)
assert(
	cf.NumberFrames[retained].Position.Y.Offset == 0 and retained.ActiveLine.Visible,
	"active line and gutter move with retained document row"
)
cf.SelectionRange = { { 0, 1 }, { 2, 1 } }
cf.ViewX = 10
funcs.Refresh(cf, syntax)
assert(
	retained.SelectionHighlight.Size.X.Offset == 0 and retained.SelectionHighlight.Position.X.Offset >= 0,
	"offscreen selection cannot create negative rectangle sizes"
)
cf.ViewX = 0
cf.SelectionRange = { { -1, -1 }, { -1, -1 } }
cf.Lines[2] = "a < b & c"
funcs.Refresh(cf, syntax)
assert(retained.Label.Text == "a &lt; b &amp; c", "syntax output escapes markup")
do
	local highlightLine = cf.HighlightLine
	local highlights = { 1 }
	cf.HighlightLine = function()
		return highlights
	end
	local reads = 0
	local typeMap = setmetatable({}, {
		__index = function()
			reads += 1
		end,
	})
	local cachedSyntax = { typeMap = typeMap, richReplace = syntax.richReplace }
	funcs.Refresh(cf, cachedSyntax)
	assert(reads > 0, "first paint visits the visible text")
	reads = 0
	funcs.Refresh(cf, cachedSyntax)
	assert(reads == 0, "unchanged rows reuse formatted text")
	cf.SelectionRange = { { 0, 1 }, { 1, 1 } }
	funcs.Refresh(cf, cachedSyntax)
	assert(reads > 0 and retained.Label.Text:find("<font", 1, true), "selection invalidates unchanged row text")
	cf.SelectionRange = { { -1, -1 }, { -1, -1 } }
	funcs.Refresh(cf, cachedSyntax)
	assert(retained.Label.Text == "a &lt; b &amp; c", "clearing selection restores unformatted text")
	cf.HighlightLine = highlightLine
end
local allocated = #cf.LineFrames
frame.Size = UDim2.fromOffset(340, 42)
cf:UpdateView()
funcs.Refresh(cf, syntax)
assert(
	#cf.LineFrames < allocated and #numbers:GetChildren() == #cf.LineFrames,
	"shrinking viewport retires row and gutter widgets together"
)
assert(
	#cf.LineFrames <= math.ceil(lines.AbsoluteSize.Y / cf.FontSize),
	"renderer work stays bounded by visible rows rather than document size"
)
print(
	"PASS: actual modular code renderer, stable document rows, current line, pixel-aligned gutter, clipped selection and escaped syntax"
)

local inputBox = Instance.new("TextBox", frame)
cf.GuiElems.EditBox = inputBox
local previousFocus = service.UserInputService.Focus
service.UserInputService.Focus = inputBox
local intercepted = 0
cf.HandleEditorInput = function()
	intercepted += 1
	return true
end
cf:ConnectEditBoxEvent()
local oldY = cf.CursorY
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
	false
)
assert(
	intercepted == 1 and cf.CursorY == oldY,
	"editor extension consumes navigation before legacy movement and key repeat"
)
service.UserInputService.Focus = nil
service.UserInputService.InputBegan:Fire(
	{ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Down },
	false
)
assert(intercepted == 1, "extension only receives input while its own editor is focused")
cf.EditBoxEvent:Disconnect()
service.UserInputService.Focus = previousFocus
print("PASS: actual focused editor input interception prevents duplicate legacy navigation")

local folding = Apps.EditorFolding
assert(folding.SameStructure("    count = total + 1", "    count = total + amount"))
assert(folding.SameStructure("    if count then", "    if total then"))
assert(folding.SameStructure("    return { mode = 'left' }", "    return { mode = 'right' }"))
assert(not folding.SameStructure("    if count then", "    if count do"))
assert(not folding.SameStructure("    count = total", "    if total then"))
assert(not folding.SameStructure("    count = total", "    count = [=[total"))
local foldLines = {
	"local function outer()",
	'    local ignored = "end function do" -- if then',
	"    if ready then",
	"        local data = {",
	"            1, 2, 3",
	"        }",
	"    end",
	"end",
	'print("after")',
}
local ranges = folding.Ranges(table.concat(foldLines, "\n"))
assert(
	ranges[1] == 8 and ranges[3] == 7 and ranges[4] == 6,
	"structural scanner matches nested functions, blocks and table braces while ignoring strings/comments"
)
local commentRanges =
	folding.Ranges("--[=[ function fake()\nend ]=]\nwhile ready do\n repeat\n task.wait()\n until done\nend")
assert(
	commentRanges[1] == nil and commentRanges[3] == 7 and commentRanges[4] == 6,
	"multiline comments do not introduce blocks and repeat/loop pairs have real ranges"
)
local unfinishedQuote = folding.Ranges("local s = 'open\nlocal function valid()\n return true\nend")
assert(unfinishedQuote[2] == 4, "unfinished short strings recover at the next line")
cf.Lines = foldLines
cf.Text = table.concat(foldLines, "\n")
cf.ViewX = 0
cf.ViewY = 0
cf.CursorY = 4
cf.CursorX = 0
cf.GutterWidthMinimum = 54
cf.GutterColor = Color3.fromRGB(39, 42, 49)
cf.Refresh = function(self)
	funcs.Refresh(self, syntax)
end
cf:ResetFolds()
cf:UpdateView()
cf:Refresh()
local originalSource = cf.Text
assert(
	cf.GutterFrame.Size.X.Offset == 54 and lines.Position.X.Offset == 54,
	"configured native gutter includes a separate functional fold column"
)
assert(
	cf.GutterFrame.ZIndex >= cf.Frame.ZIndex and cf.Frame.LineNumbers.ZIndex > cf.GutterFrame.ZIndex,
	"opaque code surface does not hide gutter under global Z ordering"
)
local header = cf.LineFrames[1]
assert(cf.FoldButtons[header].Visible, "foldable source header has a clickable gutter control")
cf.FoldButtons[header].MouseButton1Click:Fire()
assert(
	#cf.FoldModel.display == 2 and cf.FoldModel.display[2] == 9,
	"clicking fold hides the complete source body in display mapping"
)
assert(
	cf.CursorY == 0 and cf.Text == originalSource and #cf.Lines == 9,
	"folding safely places hidden caret on header without changing source"
)
assert(
	cf:DisplayToSource(1) == 8 and cf:SourceToDisplay(8) == 1 and cf:SourceToDisplay(4) == nil,
	"mouse/display coordinates map to real source rows across hidden blocks"
)
cf:RevealSourceLine(4)
assert(
	cf:SourceToDisplay(4) == 4 and #cf.FoldModel.display == 9,
	"navigating to hidden source reveals the containing block"
)
cf:ToggleFold(2)
cf:ToggleFold(0)
cf:ToggleFold(0)
assert(
	cf.FoldModel.collapsed[3] and cf:SourceToDisplay(4) == nil,
	"nested folds survive collapse and expansion of their outer block"
)
cf:RevealSourceLine(4)
assert(not cf.FoldModel.collapsed[3], "revealing a nested destination expands each containing fold")
cf:ToggleFold(0)
local collapsed = funcs.GetCollapsedFolds(cf)
cf:ResetFolds()
funcs.RestoreFolds(cf, collapsed)
assert(cf.FoldModel.collapsed[1], "collapsed line headers can be restored after a document switch")
table.insert(cf.Lines, 1, "-- header")
cf:UpdateFolds(table.concat(cf.Lines, "\n"))
assert(cf.FoldModel.collapsed[2], "inserting lines above the fold moves its header")
cf.Lines[3] = "    local added = true"
cf:UpdateFolds(table.concat(cf.Lines, "\n"))
assert(cf.FoldModel.collapsed[2] and cf:SourceToDisplay(4) == nil, "edits remap an intact collapsed range")
cf.Lines[2] = 'print("changed")'
cf:UpdateFolds(table.concat(cf.Lines, "\n"))
assert(not cf.FoldModel.collapsed[2], "changing a fold boundary invalidates that fold")
table.remove(cf.Lines, 1)
cf.Lines[2] = '    local ignored = "end function do" -- if then'
cf.Lines[1] = 'print("changed")'
cf:ResetFolds()
cf:UpdateView()
cf:Refresh()
assert(not cf.FoldModel.collapsed[1], "source edits invalidate stale fold state")
print(
	"PASS: real fold gutter clicks, nested structural ranges, source/display coordinates, source preservation and reveal/reset behavior"
)

foldLines[1] = "local function outer()"
cf:ResetFolds()
cf.ViewY = 0
cf.CursorY = 0
cf:UpdateView()
cf:Refresh()
cf:ToggleFold(0)
cf.GuiElems.LinesFrame = lines
cf.GuiElems.Cursor = Instance.new("Frame", frame)
cf.CursorAnim = function() end
cf.TabAdjust = function()
	return 0
end
actualCursorUpdate(cf, { Position = Vector2.new(lines.AbsolutePosition.X, lines.AbsolutePosition.Y + cf.FontSize) })
assert(
	cf.CursorY == 8 and cf.GuiElems.Cursor.Position.Y.Offset == cf.FontSize,
	"actual mouse cursor maps the first row after a collapsed body to its source coordinate"
)
assert(
	cf.GuiElems.Cursor.Visible and cf.GuiElems.Cursor.Position.X.Offset == cf.GutterWidth,
	"the first-column caret is visible inside the text viewport"
)
local actualLine = cf.Lines[9]
cf.Lines[9] = "x"
local lineEnd = math.round(Apps.CodeViewport.GetColumnPixelX(cf, 1, 8))
local previousViewportSize = lines.Size
lines.Size = UDim2.fromOffset(lineEnd, lines.AbsoluteSize.Y)
cf.CursorX = 1
actualCursorUpdate(cf)
assert(cf.GuiElems.Cursor.Visible and cf.GuiElems.Cursor.Position.X.Offset == cf.GutterWidth + lineEnd - 1)
lines.Size = previousViewportSize
cf.Lines[9] = actualLine
cf.CursorY = 4
actualCursorUpdate(cf)
assert(
	cf:SourceToDisplay(4) ~= nil,
	"actual keyboard cursor positioning reveals hidden destination rather than placing an invisible caret"
)
print("PASS: actual CodeFrame mouse/caret conversion across folded source and configured gutter")

cf.CursorY = 4
cf.CursorX = 3
funcs.SetAllFolds(cf, true)
assert(
	#cf.FoldModel.display == 2 and cf.CursorY == 0,
	"collapse all folds moves hidden caret onto visible outer header"
)
funcs.SetAllFolds(cf, false)
assert(
	#cf.FoldModel.display == 9 and next(cf.FoldModel.collapsed) == nil,
	"expand all folds clears nested collapse state"
)
print("PASS: documented expand/collapse-all semantics preserve visible caret")

-- Additional editor transactions share the primary renderer's measured layout.
cf:ResetFolds()
cf.Lines = { "alpha beta", "next" }
cf.ViewX = 0
cf.ViewY = 0
cf.CursorY = 0
cf.CursorX = 0
cf.SelectionRange = { { 0, 0 }, { 2, 0 } }
cf.AdditionalSelections = { { { 6, 0 }, { 9, 0 }, Caret = { 6, 0 } } }
cf:UpdateView()
funcs.Refresh(cf, syntax)
local multiRow = cf.LineFrames[1]
local secondary = multiRow.ExtraSelections:FindFirstChild("2")
assert(
	secondary and secondary.Visible and secondary.Position.X.Offset == 42 and secondary.Size.X.Offset == 21,
	"secondary selection uses the same font insertion geometry"
)
assert(
	multiRow.ExtraCarets:FindFirstChild("1").Position.X.Offset == 42,
	"backwards secondary selection keeps its explicit caret endpoint"
)
cf.AdditionalSelections = {}
funcs.Refresh(cf, syntax)
assert(
	not secondary.Visible and not multiRow.ExtraCarets:FindFirstChild("1").Visible,
	"recycled selection/caret widgets hide after cursor removal"
)
cf.OverwriteMode = true
actualCursorUpdate(cf)
assert(cf.GuiElems.Cursor.Size.X.Offset == 7, "overwrite cursor spans one measured glyph")
cf.OverwriteMode = false
print("PASS: measured secondary selections, explicit reverse caret, recycled decoration cleanup and overwrite cursor")
cf.Lines = { "if true then", "        local a=1", "", "        return a", "    inside()", "", " ", "    done()", "end" }
cf.ViewX = 0
cf.ViewY = 0
cf.ShowIndentGuides = true
cf.MaxTextCols = 30
frame.Size = UDim2.fromOffset(340, 140)
cf:UpdateView()
funcs.Refresh(cf, syntax)
local blank = cf.LineFrames[3]:FindFirstChild("IndentGuides")
assert(
	blank and blank:FindFirstChild("1") and blank["1"].Visible,
	"indent guides bridge blank lines inside an indented block"
)
assert(
	blank:FindFirstChild("2") and blank["2"].Visible and blank["2"].Position.X.Offset > blank["1"].Position.X.Offset,
	"empty rows retain distinct inherited guide columns instead of clamping all to zero"
)
assert(
	blank["2"].Position.X.Offset == cf.LineFrames[2].IndentGuides["2"].Position.X.Offset
		and blank["2"].Position.X.Offset == cf.LineFrames[4].IndentGuides["2"].Position.X.Offset,
	"nested guide connects at identical x across an empty row"
)
assert(blank["1"].ZIndex > cf.LineFrames[3].ActiveLine.ZIndex, "active line backgrounds cannot obscure indent guides")
for _, index in ipairs({ 6, 7 }) do
	local guides = cf.LineFrames[index].IndentGuides
	local second = guides:FindFirstChild("2")
	assert(guides["1"].Visible and (not second or not second.Visible), "separate blank ranges inherit their own indent")
end
assert(cf.FoldButtons[cf.LineFrames[1]].Size.X.Offset == 20, "fold target has a usable gutter width")
local foldIcon = cf.FoldButtons[cf.LineFrames[1]]:FindFirstChild("StudioFold")
if foldIcon then
	assert(foldIcon.Size.X.Offset >= 18, "fold glyph is not shrunk into a twelve pixel canvas")
end

-- Large documents retain complete numbers rather than clipping leading digits.
do
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(520, 98)
	local lines = Instance.new("Frame", frame)
	lines.Name = "Lines"
	local numbers = Instance.new("TextLabel", frame)
	numbers.Name = "LineNumbers"
	local corner = Instance.new("Frame", frame)
	local large = setmetatable({
		Frame = frame,
		FontSize = 14,
		Lines = {},
		MaxTextCols = 1,
		ScrollV = Lib.ScrollBar.new(),
		ScrollH = Lib.ScrollBar.new(true),
		ViewX = 0,
		ViewY = 0,
		GuiElems = { ScrollCorner = corner },
		GutterWidthMinimum = 54,
		Colors = cf.Colors,
		RichTemplates = cf.RichTemplates,
		SelectionRange = { { -1, -1 }, { -1, -1 } },
		CursorY = 0,
		CursorX = 0,
		LineFrames = {},
		HighlightLine = function()
			return {}
		end,
		UpdateCursor = function() end,
	}, { __index = funcs })
	large.ScrollV.Gui.Parent = frame
	large.ScrollH.Gui.Parent = frame
	local previousWidth = 0
	for _, count in ipairs({ 999, 1000, 9999, 10000, 10001, 99999, 100000, 100001 }) do
		large.Lines = table.create(count, "x")
		large.ViewY = count - 4
		large:UpdateView()
		funcs.Refresh(large, syntax)
		local width = service.TextService:GetTextSize(tostring(count), 14, Enum.Font.Code, Vector2.new(10000, 28)).X
		assert(numbers.AbsoluteSize.X >= width, "every digit fits at line " .. count)
		assert(large.GutterWidth >= previousWidth, "gutter grows across digit boundaries")
		previousWidth = large.GutterWidth
		assert(
			numbers.AbsolutePosition.X + numbers.AbsoluteSize.X <= frame.AbsolutePosition.X + large.GutterWidth - 20,
			"numbers do not overlap folding controls"
		)
		for row, lineFrame in ipairs(large.LineFrames) do
			local source = large.ViewY + row
			if source <= count then
				assert(large.NumberFrames[lineFrame].Text == tostring(source), "source line number never wraps")
			end
		end
		assert(
			#large.LineFrames <= math.ceil(lines.AbsoluteSize.Y / large.FontSize),
			"large document still renders only visible rows"
		)
	end
	for _, fontSize in ipairs({ 12, 24, 32 }) do
		large.FontSize = fontSize
		large:UpdateView()
		funcs.Refresh(large, syntax)
		local width =
			service.TextService:GetTextSize("100001", fontSize, Enum.Font.Code, Vector2.new(10000, fontSize * 2)).X
		assert(numbers.AbsoluteSize.X >= width, "all digits fit after changing font size")
	end
	frame:Destroy()
	print(
		"PASS: full gutter numbering through 100001 lines, digit transitions, font changes, separate fold controls and bounded visible rows"
	)
end

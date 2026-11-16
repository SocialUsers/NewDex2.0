--!strict

do
	cf.Lines = { "alpha alpha alpha" }
	for index = 2, 100 do
		cf.Lines[index] = "alpha"
	end
	cf.Text = table.concat(cf.Lines, "\n")
	cf.MaxTextCols = 17
	cf.ViewX = 0
	cf.ViewY = 0
	cf.CursorX = 0
	cf.CursorY = 0
	cf.SelectionRange = { { 0, 0 }, { 5, 0 } }
	cf.AdditionalSelections = {}
	frame.Size = UDim2.fromOffset(340, 98)
	cf:ResetFolds()
	cf:UpdateView()
	cf.SearchVisible = true
	cf.SearchActiveIndex = 1
	cf.SearchMatches = {
		{ Start = 1, Finish = 6 },
		{ Start = 7, Finish = 12 },
		{ Start = 13, Finish = 18 },
		{
			Start = 19,
			Finish = 24,
		},
	}
	funcs.Refresh(cf, syntax)
	local first = cf.LineFrames[1]
	local label = first.Label
	local spans = first:FindFirstChild("SearchMatches")
	assert(spans and #spans:GetChildren() == 2, "secondary matches render while active match keeps ordinary selection")
	local span = spans:FindFirstChild("1")
	assert(span.Position.X.Offset == cf:GetColumnPixelX(6, 0), "match spans use measured insertion geometry")
	assert(
		span.Size.X.Offset == cf:GetColumnPixelX(11, 0) - cf:GetColumnPixelX(6, 0),
		"exclusive match end paints exact matching bytes"
	)
	assert(
		span.ZIndex < first.SelectionHighlight.ZIndex and first.SelectionHighlight.ZIndex < label.ZIndex,
		"selection and glyphs paint above gold matches"
	)
	local markers = cf.SearchMarkerHost
	assert(markers.Visible and #markers:GetChildren() > 0, "search adds overview marks to scrollbar")
	local all = Apps.EditorFindModel.Search(cf.Text, "alpha").Matches
	cf.SearchMatches = all
	funcs.Refresh(cf, syntax)
	local expected = {}
	local height = math.floor(cf.ScrollV.Gui.AbsoluteSize.Y)
	for line = 1, #cf.Lines do
		expected[(line - 1) * height // #cf.Lines] = true
	end
	for _, marker in markers:GetChildren() do
		assert(expected[marker.Position.Y.Offset], "each occupied scrollbar pixel has one marker")
		expected[marker.Position.Y.Offset] = nil
	end
	assert(not next(expected), "dense results retain every occupied scrollbar pixel")
	cf.SearchMatches = table.move(all, 1, 4, 1, {})
	funcs.Refresh(cf, syntax)
	funcs.Refresh(cf, syntax)
	assert(first.Label == label and spans:FindFirstChild("1") == span, "unchanged search retains text and span widgets")
	cf.SelectionRange = { { 1, 0 }, { 1, 0 } }
	funcs.Refresh(cf, syntax)
	assert(#spans:GetChildren() == 3, "moving away from the active result restores its gold match highlight")
	cf.SelectionRange = { { 5, 0 }, { 0, 0 } }
	funcs.Refresh(cf, syntax)
	assert(#spans:GetChildren() == 2, "reverse selection of the active match also preserves the blue selection")
	cf.SearchVisible = false
	funcs.Refresh(cf, syntax)
	assert(
		#spans:GetChildren() == 0 and not markers.Visible and #markers:GetChildren() == 0,
		"closing Find clears spans and overview marks"
	)
	cf.SearchVisible = true
	cf.SearchActiveIndex = 0
	cf.SearchMatches = { { Start = 2, Finish = 2 } }
	funcs.Refresh(cf, syntax)
	assert(
		#spans:GetChildren() == 1 and spans:FindFirstChild("1").Size.X.Offset == 1,
		"zero-width matches receive a one-pixel span"
	)
	cf.SearchMatches = {}
	funcs.Refresh(cf, syntax)
	assert(#spans:GetChildren() == 0 and not markers.Visible, "empty query results remove previous match decorations")
	cf.SearchVisible = false
	cf.SearchActiveIndex = nil
	cf.HighlightOccurrences = true
	cf.Colors.MatchingWord = Color3.fromRGB(85, 85, 85)
	cf.Lines = { "alpha alphaBeta alpha", "ALPHA alpha", "   " }
	cf.Text = table.concat(cf.Lines, "\n")
	cf.CursorX, cf.CursorY = 2, 0
	cf.ViewX, cf.ViewY = 0, 0
	cf.SelectionRange = { { 2, 0 }, { 2, 0 } }
	cf:ResetFolds()
	cf:UpdateView()
	funcs.Refresh(cf, syntax)
	local firstRow = cf.LineFrames[1]:FindFirstChild("WordMatches")
	local secondRow = cf.LineFrames[2]:FindFirstChild("WordMatches")
	assert(
		#firstRow:GetChildren() == 2 and #secondRow:GetChildren() == 1,
		"caret highlights case-sensitive whole words only"
	)
	local lastWord = firstRow:FindFirstChild("2")
	assert(lastWord.Position.X.Offset == cf:GetColumnPixelX(16, 0), "word box follows glyph geometry")
	cf.CursorX, cf.CursorY = 1, 2
	funcs.Refresh(cf, syntax)
	assert(not lastWord.Visible, "moving to whitespace clears occurrence highlights")
	cf.CursorX, cf.CursorY = 5, 0
	cf.SelectionRange = { { 0, 0 }, { 5, 0 } }
	funcs.Refresh(cf, syntax)
	assert(lastWord.Visible, "selecting one complete word still highlights its other occurrences")
	cf.SearchVisible = true
	funcs.Refresh(cf, syntax)
	assert(not lastWord.Visible, "Find highlights take precedence over caret occurrences")
	cf.HighlightOccurrences = false
	cf.SearchVisible = false
end
print(
	"PASS: visible search spans, measured byte ranges, active selection layering, retained widgets and scrollbar marker cleanup"
)

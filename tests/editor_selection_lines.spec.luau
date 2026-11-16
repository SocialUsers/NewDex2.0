--!strict

do
	local set = Apps.EditorSelectionSet
	local function carets(...)
		local ranges = {}
		for index, position in ipairs({ ... }) do
			ranges[#ranges + 1] = { Anchor = position, Caret = position, Id = index }
		end
		return ranges
	end
	local source = "abcdef\nsecond\nthird"
	local same = carets(2, 5)
	assert(
		set.Apply(source, same, "DeleteLines", { Indent = "    " }).Text == "second\nthird",
		"two carets on one line delete only that original line"
	)
	local commented = set.Apply(source, same, "ToggleComment", { Indent = "    " })
	assert(commented.Text == "-- abcdef\nsecond\nthird", "same-line carets toggle comments exactly once")
	assert(
		commented.Ranges[1].Caret == 5 and commented.Ranges[2].Caret == 8,
		"comment insertion maps all original caret columns"
	)
	local indented = set.Apply(source, same, "Indent", { Indent = "    ", WholeLines = true })
	assert(
		indented.Text == "    abcdef\nsecond\nthird" and indented.Ranges[2].Caret == 9,
		"whole-line indent applies once and preserves distinct caret columns"
	)
	assert(
		set.Apply(indented.Text, indented.Ranges, "Outdent", { Indent = "    " }).Text == source,
		"same-line outdent reverses one indent"
	)
	local blocks = { { Anchor = 2, Caret = 10, Id = 1 }, { Anchor = 11, Caret = 15, Id = 2 } }
	assert(
		set.Apply("abc\ndef\nghi\njkl\nmno", blocks, "DeleteLines", { Indent = "    " }).Text == "mno",
		"partly overlapping line blocks delete their union once"
	)
	local duplicate = set.Apply("one\ntwo", carets(2, 3), "DuplicateLines", { Indent = "    " })
	assert(
		duplicate.Text == "one\none\ntwo" and duplicate.Ranges[1].Caret == 6 and duplicate.Ranges[2].Caret == 7,
		"duplicate once and move all original carets into the copied line"
	)
	local moved = set.Apply("aa\nbb\ncc\ndd", carets(4, 7), "MoveLinesUp", { Indent = "    " })
	assert(
		moved.Text == "bb\ncc\naa\ndd" and moved.Ranges[1].Caret == 1 and moved.Ranges[2].Caret == 4,
		"adjacent multicursor line moves preserve the block order and relative carets"
	)
	local disjoint = set.Apply("aa\nbb\ncc\ndd", carets(1, 7), "DeleteLines", { Indent = "    " })
	assert(disjoint.Text == "bb\ndd", "disjoint line blocks preserve intervening content")
	local mixed = set.Apply(
		"abcd\nefgh",
		{ { Anchor = 1, Caret = 2, Id = 1 }, { Anchor = 3, Caret = 4, Id = 2 }, { Anchor = 8, Caret = 8, Id = 3 } },
		"Indent",
		{ Indent = "  " }
	)
	assert(
		mixed.Text == "  abcd\nef  gh",
		"selected Tab unions overlapping line scopes while a separate empty caret still inserts at its own column"
	)
	local separate = set.Apply(
		"abcd\nefgh",
		{ { Anchor = 1, Caret = 2, Id = 1 }, { Anchor = 7, Caret = 7, Id = 2 }, { Anchor = 9, Caret = 9, Id = 3 } },
		"Indent",
		{ Indent = "  " }
	)
	assert(
		separate.Text == "  abcd\ne  fg  h",
		"multiple empty Tab carets on the same unaffected line remain independent"
	)
	local headers = "if one then\n\nwhile two do"
	local expanded = set.Apply(headers, carets(#"if one then" + 1, #headers + 1), "Newline", { Indent = "  " })
	assert(expanded.Text == "if one then\n  \nend\n\nwhile two do\n  \nend", "Enter completes blocks at both carets")
	local document = Apps.EditorDocument.Create(expanded.Text)
	local line1, col1 = document:PositionToLineColumn(expanded.Ranges[1].Caret)
	local line2, col2 = document:PositionToLineColumn(expanded.Ranges[2].Caret)
	assert(line1 == 2 and col1 == 3 and line2 == 6 and col2 == 3, "both carets remain on their new indented lines")
	local mixedEndings = Apps.EditorDocument.Create("a\r\n\r\né\n")
	assert(mixedEndings:AdjacentPosition(2, 1) == 4 and mixedEndings:AdjacentPosition(4, -1) == 2)
	assert(mixedEndings:AdjacentPosition(4, 1) == 6 and mixedEndings:AdjacentPosition(6, -1) == 4)
	assert(mixedEndings:AdjacentPosition(6, 1) == 8 and mixedEndings:AdjacentPosition(8, -1) == 6)
	print(
		"PASS: multicursor line command unions, single toggle/indent/delete, mapped caret columns, copied and adjacent moved blocks"
	)
end

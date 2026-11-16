--!strict

local Editor = require("../src/Apps/ScriptViewer/Util/EditorDocument").Main()
local function apply(text, command, anchor, caret, options)
	return Editor.Apply(text, anchor or 1, caret or anchor or 1, command, options)
end
local function expect(text, command, anchor, caret, expected, options)
	local result = apply(text, command, anchor, caret, options)
	assert(
		result.Text == expected,
		command .. ": expected " .. string.format("%q", expected) .. ", got " .. string.format("%q", result.Text)
	)
	assert(
		result.Anchor >= 1
			and result.Anchor <= #result.Text + 1
			and result.Caret >= 1
			and result.Caret <= #result.Text + 1
	)
	return result
end

do
	local doc = Editor.Create("one\r\ntwo\r\n")
	assert(doc:GetLineCount() == 3 and doc:GetLine(2) == "two" and doc:GetLine(3) == "")
	local line, column = doc:PositionToLineColumn(7)
	assert(line == 2 and column == 2)
	assert(doc:LineColumnToPosition(2, 100) == 9)
	assert(doc:LineColumnToPosition(100, 100) == 11)
	assert(not doc:SetText(doc:GetText()), "unchanged source reuses the index")
	assert(doc:SelectedLines(1, 6) == 1)
	local first, last = doc:SelectedLines(6, 1)
	assert(
		first == 1 and last == 1,
		"selection ending at the next line's start excludes it, including reversed selection"
	)
	local huge = Editor.Create(string.rep("x\n", 100000))
	assert(huge:GetLineCount() == 100001 and huge:LineColumnToPosition(100001, 1) == 200001)
	assert(huge:PositionToLineColumn(199999) == 100000)
end

do
	expect("a\nb\nc", "Indent", 1, 5, "\ta\n\tb\nc")
	expect("a\nb", "Indent", 2, 2, "a\t\nb")
	expect("\ta\n  b\nc", "Outdent", 1, 8, "a\nb\nc")
	expect(" a\n    b", "Outdent", 1, 8, "a\n  b", { Indent = "  " })
	local reverse = expect("a\nb", "Indent", 4, 1, "  a\n  b", { Indent = "  " })
	assert(reverse.Anchor > reverse.Caret, "line commands preserve selection direction")
	expect("  a\n\n\tb", "ToggleComment", 1, 8, "  -- a\n\n\t-- b")
	expect("  -- a\n\n\t-- b", "ToggleComment", 1, 14, "  a\n\n\tb")
	expect("--a\nb", "ToggleComment", 1, 6, "-- --a\n-- b")
	expect("--a\n-- b", "ToggleComment", 1, 9, "a\nb")
	expect("\n  ", "ToggleComment", 1, 4, "\n  ")
	expect("a\r\nb", "Indent", 1, 5, "\ta\r\n\tb")
end

do
	expect("a\nb\nc", "DuplicateLines", 3, 3, "a\nb\nb\nc")
	expect("a\nb\nc", "DuplicateLines", 1, 5, "a\nb\na\nb\nc")
	expect("a", "DuplicateLines", 1, 1, "a\na")
	expect("a\r\nb", "DuplicateLines", 1, 1, "a\r\na\r\nb")
	expect("a\nb\nc", "MoveLinesUp", 3, 3, "b\na\nc")
	expect("a\nb\nc", "MoveLinesDown", 3, 3, "a\nc\nb")
	expect("a\nb\nc\nd", "MoveLinesUp", 3, 7, "b\nc\na\nd")
	expect("a\nb\nc\nd", "MoveLinesDown", 3, 7, "a\nd\nb\nc")
	assert(not apply("a\nb", "MoveLinesUp", 1).Changed)
	assert(not apply("a\nb", "MoveLinesDown", 3).Changed)
	expect("a\r\nb\r\nc", "MoveLinesDown", 1, 1, "b\r\na\r\nc")
	expect("a\nb\nc", "DeleteLines", 3, 3, "a\nc")
	expect("a\nb\nc", "DeleteLines", 5, 5, "a\nb")
	expect("a\nb\n", "DeleteLines", 3, 3, "a\n")
	expect("a", "DeleteLines", 1, 1, "")
	expect("a\r\nb", "DeleteLines", 4, 4, "a")
end

do
	local function context(text, expected)
		assert(Editor.Create(text):ContextAt(#text + 1) == expected, text .. " context")
	end
	context("local a = ", "Code")
	context("-- hello (", "LineComment")
	context("-- hello\n(", "Code")
	context("'hello\\' (", "String")
	context("'hello' (", "Code")
	context("[==[ hello ]] [=[ ", "LongString")
	context("[==[ hello ]==] ", "Code")
	context("--[=[ hello ]] ", "LongComment")
	context("--[=[ hello ]=] ", "Code")
	context("`hi {value}", "InterpolatedString")
	expect("", "PairCharacter", 1, 1, "()", { Text = "(" })
	expect("foo", "PairCharacter", 1, 4, "(foo)", { Text = "(" })
	expect("-- hi ", "PairCharacter", 7, 7, "-- hi (", { Text = "(" })
	local skip = expect('"hi "', "PairCharacter", 5, 5, '"hi "', { Text = '"' })
	assert(skip.Caret == 6 and not skip.Changed, "typing a present closing quote advances the caret")
	expect('"hi "', "PairCharacter", 4, 4, '"hi( "', { Text = "(" })
	expect("name", "PairCharacter", 1, 1, "(name", { Text = "(" })
	expect("()", "Backspace", 2, 2, "")
	expect("-- ()", "Backspace", 5, 5, "-- )")
	expect("'()'", "Backspace", 3, 3, "')'")
	expect("-- )", "PairCharacter", 4, 4, "-- ))", { Text = ")" })
	expect("'a)'", "PairCharacter", 3, 3, "'a))'", { Text = ")" })
	expect("'a\"b'", "PairCharacter", 3, 3, "'a\"\"b'", { Text = '"' })
	expect("'a\\'", "PairCharacter", 4, 4, "'a\\''", { Text = "'" })
	expect("hello", "InsertText", 2, 5, "hio", { Text = "i" })
	expect("hello", "Backspace", 2, 5, "ho")
	expect("hello", "Delete", 2, 2, "hllo")
	expect("Étage", "Backspace", 3, 3, "tage")
	expect("Étage", "Delete", 1, 1, "tage")
	expect("a\r\nb", "Backspace", 4, 4, "ab")
	expect("a\r\nb", "Delete", 2, 2, "ab")
	assert(Editor.Create("Étage"):LineColumnToPosition(1, 2) == 1, "stale byte columns never split UTF-8")
	assert(not pcall(function()
		apply("", "PairCharacter", 1, 1, { Text = "many" })
	end))
end

do
	local result = expect("{}", "Newline", 2, 2, "{\n\t\n}")
	assert(result.Caret == 4 and result.Anchor == 4)
	local function enter(text, expected, at, options)
		return expect(text, "Newline", at or #text + 1, at or #text + 1, expected, options)
	end
	local branch = enter("  if ready then", "  if ready then\n  \t\n  end")
	assert(branch.Caret == 20 and branch.Anchor == 20)
	local completed = enter("if ex", "if ex then\n\t\nend")
	assert(completed.Caret == #"if ex then\n\t" + 1)
	enter("while player.Parent", "while player.Parent do\n\t\nend")
	enter("for index = 1, 10", "for index = 1, 10 do\n\t\nend")
	enter("for key, value in pairs(items)", "for key, value in pairs(items) do\n\t\nend")
	enter("if name == 'Dex' -- note", "if name == 'Dex' then -- note\n\t\nend")
	enter("if ex  ", "if ex then\n\t\nend")
	enter("if ex\r\n\treturn\r\nend", "if ex then\r\n\t\r\n\treturn\r\nend", #"if ex" + 1)
	enter("if ex\nelseif other\nend", "if ex\nelseif other then\n\t\nend", #"if ex\nelseif other" + 1)
	enter("if ex then\nelseif other end", "if ex then\nelseif other then\n\t\nend", #"if ex then\nelseif other" + 1)
	enter("if ex\nthen\nend", "if ex\n\nthen\nend", #"if ex" + 1)
	enter("if ex and", "if ex and\n")
	enter("if ready()", "if ready() then\n\t\nend")
	enter("if outer then\n\tif inner\nend", "if outer then\n\tif inner then\n\t\t\n\tend\nend", #"if outer then\n\tif inner" + 1)
	enter("while", "while\n")
	enter("for index = 1", "for index = 1\n")
	enter("for index = 1,", "for index = 1,\n")
	enter("local result = if ex", "local result = if ex\n")
	enter("function run()", "function run()\n\t\nend")
	enter("local function run(): number", "local function run(): number\n\t\nend")
	enter("local function run(): {number}", "local function run(): {number}\n\t\nend")
	enter("signal:Connect(function())", "signal:Connect(function()\n\t\nend)", #"signal:Connect(function()" + 1)
	enter("while ready do", "while ready do\n\t\nend")
	enter("repeat", "repeat\n\t\nuntil ")
	enter("if ready then -- note", "if ready then -- note\n\t\nend")
	enter("if ready then end", "if ready then\n\t\nend", #"if ready then" + 1)
	enter("if ready then\n\treturn\nend", "if ready then\n\t\n\treturn\nend", #"if ready then" + 1)
	enter("if ready then\r\n\treturn\r\nend", "if ready then\r\n\t\r\n\treturn\r\nend", #"if ready then" + 1)
	enter("if a then if b then", "if a then if b then\n\t\t\n\tend\nend")
	enter("local result = if ready then", "local result = if ready then\n")
	enter("local result =\n-- note\nif ready then", "local result =\n-- note\nif ready then\n")
	enter("if ready then\nelse\nend", "if ready then\nelse\n\t\nend", #"if ready then\nelse" + 1)
	enter("if ready then\nelseif other then\nend", "if ready then\nelseif other then\n\t\nend", #"if ready then\nelseif other then" + 1)
	expect("-- if ready then", "Newline", 17, 17, "-- if ready then\n")
	expect("  local x = 1", "Newline", 14, 14, "  local x = 1\n  ")
	expect("  {}", "Newline", 4, 4, "  {\n  \t\n  }")
	expect("a\r\n  b", "Newline", 7, 7, "a\r\n  b\r\n  ")
	local doc = Editor.Create("one\ntwo")
	local first = doc:Apply("InsertText", 1, 1, { Text = "x" })
	local second = doc:Apply("Newline", 2, 2)
	assert(first.Text == "xone\ntwo" and second.Text == "x\none\ntwo" and doc:GetLineCount() == 3)
end
print(
	"PASS: indexed editor documents, UTF-8 offsets, line commands, CRLF, indentation, comment toggles and context-aware pairs"
)

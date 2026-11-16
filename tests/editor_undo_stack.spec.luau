--!strict

local History = require("../src/Apps/ScriptViewer/Services/EditorUndoStack").Main()
local function state(text, x, y, range)
	return { text = text, x = x or 0, y = y or 0, selection = range }
end
local function bytes(stack)
	local count = 0
	for _, entry in ipairs(stack._entries) do
		count += #entry.text
	end
	if stack._pending then
		count += #stack._pending.text
	end
	assert(stack:bytes() == count, "incremental byte count agrees after every branch/eviction")
end
do
	local stack = History.new(state("original"))
	assert(not stack:canUndo() and not stack:canRedo())
	stack:push(state("one"))
	stack:push(state("two"))
	assert(stack:undo().text == "one" and stack:undo().text == "original" and stack:undo() == nil)
	assert(stack:redo().text == "one")
	stack:push(state("branch"))
	assert(
		not stack:canRedo() and stack:redo() == nil and stack:undo().text == "one",
		"new push discards the old redo branch"
	)
	bytes(stack)
	stack:reset(state("reset"))
	assert(
		stack._pointer == 1 and stack:count() == 1 and not stack:canUndo() and not stack:canRedo(),
		"reset preserves exactly its one supplied baseline"
	)
	bytes(stack)
end
do
	local stack = History.new(state(""))
	stack:record(state("a", 1), 0)
	stack:record(state("ab", 2), 0.49)
	stack:record(state("abc", 3), 0.98)
	assert(stack:count() == 2 and stack:canUndo(), "0.5 second inactivity window coalesces a continuously typed run")
	stack:record(state("abcd", 4), 1.48)
	assert(stack:undo().text == "abc" and stack:undo().text == "", "exactly 0.5 second idle begins a new group")
	assert(stack:redo().text == "abc" and stack:redo().text == "abcd")
	stack:undo()
	stack:record(state("rebranched"), 2)
	assert(
		not stack:canRedo() and stack:undo().text == "abc",
		"pending edit invalidates redo immediately and undo flushes it"
	)
	bytes(stack)
end
do
	local range = { { 0, 0 }, { #"é🙂", 0 } }
	local stack = History.new(state("é🙂\ntext", #"é🙂", 0, range))
	range[1][1] = 99
	stack:record(state("replaced\ntext", 8, 0, { { 8, 0 }, { 8, 0 } }), 0)
	local prior = stack:undo()
	assert(
		prior.text == "é🙂\ntext"
			and prior.x == #"é🙂"
			and prior.selection[1][1] == 0
			and prior.selection[2][1] == #"é🙂",
		"UTF-8 byte caret and anchor restore from a detached snapshot"
	)
	stack:updateSelection(state(prior.text, 0, 0, { { #"é🙂", 0 }, { 0, 0 } }))
	stack:redo()
	prior = stack:undo()
	assert(
		prior.x == 0 and prior.selection[1][1] == #"é🙂" and prior.selection[2][1] == 0,
		"reversed selection endpoints survive redo and undo"
	)
	bytes(stack)
end
do
	local stack = History.new(state("0"), { MaxSize = 3, MaxBytes = 1000 })
	for i = 1, 20 do
		stack:push(state(tostring(i)))
		bytes(stack)
		assert(stack:count() <= 3)
	end
	assert(
		stack:undo().text == "19" and stack:undo().text == "18" and stack:undo() == nil,
		"oldest snapshots evict while current and recent states remain"
	)
	stack = History.new(state("aaaa"), { MaxBytes = 10 })
	stack:push(state("bbbb"))
	stack:record(state("cccc"), 0)
	assert(stack:bytes() == 8 and stack:count() == 2, "pending snapshot participates in byte bound")
	assert(stack:undo().text == "bbbb" and stack:undo() == nil)
	stack:push(state(string.rep("x", 20)))
	assert(stack:count() == 2, "a single large document keeps its previous/current pair, matching Dex policy")
	bytes(stack)
end
do
	-- Source-derived push/undo/redo/reset compared with a minimal model over
	-- many branches. This checks states, not the adapter's private instructions.
	local stack = History.new(state("0"), { MaxSize = 7, MaxBytes = 100000 })
	local model, index = { "0" }, 1
	for i = 1, 200 do
		local action = i % 5
		if action == 0 or action == 1 then
			local redo = action == 1
			local expected = redo and index + 1 or index - 1
			local actual
			if redo then
				actual = stack:redo()
			else
				actual = stack:undo()
			end
			if model[expected] then
				index = expected
				assert(actual.text == model[index])
			else
				assert(actual == nil)
			end
		else
			while #model > index do
				table.remove(model)
			end
			table.insert(model, tostring(i))
			index = #model
			while #model > 7 do
				table.remove(model, 1)
				index -= 1
			end
			stack:push(state(tostring(i)))
		end
		assert(stack._pointer == index and #stack._entries == #model)
		bytes(stack)
	end
end
print(
	"PASS: recovered Blox UndoStack state transitions, redo branching, verified 0.5s grouping, detached UTF-8 selections and incremental limits"
)

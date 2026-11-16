--!strict

-- Fixture records action IDs from native instructions independently of the runtime definition.
local definition = Apps.StudioMenuDefinition
local function identity(action)
	return type(action) == "string" and action or action.id
end
assert(#definition.Groups == #nativeMenuFixture.groups, "native group count")
for index, expected in ipairs(nativeMenuFixture.groups) do
	local actual = definition.Groups[index]
	assert(#actual == #expected, "native action count in group " .. index)
	for i, action in ipairs(expected) do
		assert(actual[i].Id == identity(action), "native action order in group " .. index)
		if type(action) == "table" then
			assert(#actual[i].Submenu == #action.children, "native submenu count")
			for j, id in ipairs(action.children) do
				assert(actual[i].Submenu[j].Id == id, "native submenu order")
			end
		end
	end
end
editor.OpenDocument("native-menu-contract", "Native Menu Contract", "local selected = 1")
cf.SelectionRange = { { 0, 0 }, { 5, 0 } }
cf:MoveCursor(5, 0)
assert(editor.OpenEditorContextMenu(nil, nil, true), "native menu opens")
local actualGroups = { {} }
local byId = {}
for _, entry in ipairs(editor.EditorContextMenu.Items) do
	if entry.Divider then
		assert(#actualGroups[#actualGroups] > 0, "no empty groups or consecutive dividers")
		actualGroups[#actualGroups + 1] = {}
	else
		assert(
			entry.NativeActionId and not nativeMenuFixture.excluded[entry.NativeActionId],
			"only bound native actions appear"
		)
		actualGroups[#actualGroups][#actualGroups[#actualGroups] + 1] = entry
		byId[entry.NativeActionId] = entry
	end
end
local retained = {}
for _, group in ipairs(nativeMenuFixture.groups) do
	local expected = {}
	for _, action in ipairs(group) do
		if not nativeMenuFixture.excluded[identity(action)] then
			expected[#expected + 1] = action
		end
	end
	if #expected > 0 then
		retained[#retained + 1] = expected
	end
end
assert(#actualGroups == #retained, "bound menu preserves native separators")
for i, group in ipairs(retained) do
	assert(#group == #actualGroups[i], "bound native group action count")
	for j, action in ipairs(group) do
		local row = actualGroups[i][j]
		assert(row.NativeActionId == identity(action), "rendered menu uses native order")
		if type(action) == "table" then
			local expected = {}
			for _, id in ipairs(action.children) do
				if not nativeMenuFixture.excluded[id] then
					expected[#expected + 1] = id
				end
			end
			assert(#row.Submenu == #expected, "native format commands are available")
			for k, id in ipairs(expected) do
				assert(row.Submenu[k].NativeActionId == id, "bound submenu keeps native identities")
			end
			assert(
				row.Icon == "mockasset://native/editor/format",
				"native Format action resolves original embedded asset"
			)
		else
			assert(not row.Icon, "do not invent icons for native actions without assigned icons")
		end
	end
end
cf.Editable = false
editor.OpenEditorContextMenu(nil, nil, true)
for _, entry in ipairs(editor.EditorContextMenu.Items) do
	if entry.NativeActionId == "formatContextMenuAction" then
		for _, child in ipairs(entry.Submenu) do
			assert(child.Disabled, "native Format mutation binding preserves read-only state")
		end
	end
end
cf.Editable = true
editor.CloseEditorContextMenu()
-- Capability pruning cannot leave empty submenus or stray separators.
local sparse = definition.Build({ copyAction = { Callback = function() end, Disabled = true } }, function(callback)
	return callback
end, function()
	error("unbound submenu cannot resolve assets")
end)
assert(
	#sparse == 1 and sparse[1].NativeActionId == "copyAction" and sparse[1].Disabled,
	"unbound actions prune whole empty groups and preserve disabled state"
)
print(
	"PASS: source-bound native editor QAction order, separators, submenu IDs, capability pruning and original icon binding"
)

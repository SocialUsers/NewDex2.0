--!strict

do
	local viewer = Apps.ScriptViewer
	local previous = viewer.ActiveDocument
	local object = Instance.new("LocalScript", workspace)
	object.Name = "ReferenceScript"
	local editable = viewer.OpenDocument(object, object.Name, "-- unsaved changes", object)
	local snapshot = viewer.OpenReferenceResult({
		Object = object,
		DocumentId = {},
		Source = "local Door = 1\nprint(Door)",
		TargetName = "Door",
		Line = 2,
		Column = 7,
	})
	assert(
		snapshot ~= editable and snapshot.script == nil and editable.text == "-- unsaved changes",
		"reference snapshots preserve existing edits and do not bind to source writes"
	)
	assert(
		viewer.CodeFrame.CursorY == 1 and viewer.CodeFrame.CursorX == 10,
		"reference results reveal the matching line and name using Find selection semantics"
	)
	assert(
		viewer.CodeFrame.SearchVisible
			and #viewer.CodeFrame.SearchMatches == 2
			and viewer.CodeFrame.SearchActiveIndex == 2
			and viewer.FindWidget.Find.Text == "Door",
		"reference navigation uses the production Find/Replace match highlighting"
	)
	local normalOpen = viewer.ViewScript
	local requested
	viewer.ViewScript = function(script)
		requested = script
		viewer.OpenDocument(
			{},
			"Bytecode navigation",
			"-- Script Path: Workspace.Door.Test\n-- Took 0s\n-- Executor: Tests\n\nlocal Doorbell = 0\nreturn workspace.Door",
			object
		)
	end
	local before = #viewer.Documents
	viewer.OpenReferenceResult({ Object = object, Kind = "Bytecode", TargetName = "Door" })
	assert(requested == object, "bytecode candidates use normal script opening without fabricated source lines")
	local bytecodeDoc = viewer.ActiveDocument
	assert(
		viewer.CodeFrame.CursorY == 5
			and viewer.CodeFrame.SearchActiveIndex == 1
			and #viewer.CodeFrame.SearchMatches == 1,
		"bytecode navigation finds code after the header and rejects name-prefix matches"
	)
	assert(
		viewer.CodeFrame.SelectionRange[1][1] == 17 and viewer.CodeFrame.SelectionRange[2][1] == 21,
		"actual code occurrence receives the active match selection"
	)
	viewer.ViewScript = normalOpen
	viewer.SelectDocument(previous)
	viewer.CloseDocument(bytecodeDoc)
	viewer.CloseDocument(snapshot)
	viewer.CloseDocument(editable)
	object:Destroy()
	print("PASS: reference result editor navigation and snapshot isolation from edited documents")
end

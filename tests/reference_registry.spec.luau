--!strict

do
	-- Exercise the actual Explorer/controller contract, rather than inventing a
	-- public field in a test double as the original finder tests did.
	local explorer = Apps.Explorer
	local finder = Apps.ReferenceFinder
	assert(rawget(explorer, "Nodes") == nil, "production Explorer does not expose Nodes")
	local objects = explorer.GetNodes()
	assert(type(objects) == "table" and next(objects) ~= nil, "real Explorer index is initialized")
	assert(finder.GetObjects() == objects, "finder must use the real Explorer index accessor")
	local inspected = Apps.ReferenceScan.Run({ Target = workspace, Objects = finder.GetObjects(), MaxResults = 1 })
	assert(inspected.Stats.Objects > 0, "real Explorer objects are discovered by the reference scanner")
	print("PASS: reference finder binds the real private Explorer registry through its public accessor")
end

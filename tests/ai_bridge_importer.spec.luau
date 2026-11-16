--!strict

do
	local originalGetService = game.GetService
	game.GetService = function(_, name)
		return assert(service[name], "fixture service missing")
	end
	local destination = Instance.new("Folder", workspace)
	destination.Name = "Import destination"
	local document = {
		format = "dex-plus-capture",
		version = 1,
		name = "Shop",
		nodes = {
			{ id = "root", name = "Shop", className = "Folder", properties = {}, attributes = {}, tags = {} },
			{
				id = "left",
				parentId = "root",
				name = "Same",
				className = "Part",
				properties = { Anchored = false, Transparency = 0.4 },
				attributes = { Flag = false },
				tags = { "Imported" },
			},
			{
				id = "right",
				parentId = "root",
				name = "Same",
				className = "Part",
				properties = { Anchored = true },
				attributes = {},
				tags = {},
			},
			{
				id = "link",
				parentId = "root",
				name = "Target",
				className = "ObjectValue",
				properties = { Value = { type = "Instance", id = "right" } },
				attributes = {},
				tags = {},
			},
			{
				id = "outside",
				parentId = "root",
				name = "External",
				className = "ObjectValue",
				properties = { Value = { type = "Instance", id = "missing" } },
				attributes = {},
				tags = {},
			},
		},
		scripts = {},
	}
	local container, report, objects = StudioImporter.Import(document, destination)
	assert(
		container.Parent == destination
			and objects.left.Parent == objects.root
			and objects.right.Name == objects.left.Name
	)
	assert(
		objects.link.Value == objects.right and objects.link.Value ~= objects.left,
		"round-trip internal links do not confuse duplicate names"
	)
	assert(
		objects.left.Anchored == false
			and objects.left:GetAttribute("Flag") == false
			and service.CollectionService:HasTag(objects.left, "Imported"),
		"typed properties/attributes/tags restored"
	)
	assert(
		report.links == 1 and #report.externalLinks == 1 and not objects.outside.Value,
		"external identity is never guessed by name"
	)
	container:Destroy()
	local originalSetter = instMT.__newindex
	instMT.__newindex = function(object, key, value)
		assert(key ~= "ProtectedFixture", "protected setter must never be attempted")
		return originalSetter(object, key, value)
	end
	local capturedContainer, capturedReport, capturedObjects = StudioImporter.Import(capturedRoundTrip, destination)
	instMT.__newindex = originalSetter
	assert(capturedReport.propertiesSkipped > 0, "protected properties are intentionally skipped, not import errors")
	assert(#capturedReport.errors == 0, "capture round-trip does not report protected setters as warnings")
	local foundLink = false
	for _, row in ipairs(capturedRoundTrip.nodes) do
		if row.className == "ObjectValue" then
			foundLink = capturedObjects[row.id].Value == capturedObjects[row.properties.Value.id]
		end
	end
	assert(
		foundLink and capturedReport.links == 1,
		"production capture passes through the real Studio importer without losing instance links"
	)
	capturedContainer:Destroy()
	local originalContent = Content
	local originalAssetService = service.AssetService
	local meshCalls = 0
	Content = {
		fromUri = function(uri)
			return { Uri = uri, __bridgeType = "Content" }
		end,
		none = { Uri = "", __bridgeType = "Content" },
	}
	local decodedContent = router.Codec:Decode({ type = "Content", uri = "rbxassetid://456" })
	assert(router.Codec:Encode(decodedContent).uri == "rbxassetid://456", "modern URI Content values round-trip")
	service.AssetService = {
		CreateMeshPartAsync = function(_, content)
			meshCalls += 1
			local mesh = Instance.new("MeshPart")
			mesh.LoadedMeshUri = content.Uri
			return mesh
		end,
	}
	local meshDocument = {
		format = "dex-plus-capture",
		version = 1,
		name = "Meshes",
		nodes = {
			{
				id = "mesh1",
				name = "One",
				className = "MeshPart",
				properties = { MeshContent = { type = "Content", uri = "rbxassetid://456" } },
				attributes = {},
				tags = {},
			},
			{
				id = "mesh2",
				name = "Two",
				className = "MeshPart",
				properties = { MeshId = "rbxassetid://456" },
				attributes = {},
				tags = {},
			},
		},
		scripts = {},
	}
	local meshContainer, meshReport, meshObjects =
		StudioImporter.Import(meshDocument, destination, { loadMeshes = true })
	assert(
		meshCalls == 1
			and meshReport.meshesLoaded == 2
			and meshObjects.mesh1.LoadedMeshUri == "rbxassetid://456"
			and meshObjects.mesh2.LoadedMeshUri == "rbxassetid://456",
		"mesh importer uses permitted asset creation and reuses geometry for matching IDs"
	)
	meshContainer:Destroy()
	Content = originalContent
	service.AssetService = originalAssetService
	document.nodes[1].parentId = "left"
	local before = #destination:GetChildren()
	local ok = pcall(StudioImporter.Import, document, destination)
	assert(not ok and #destination:GetChildren() == before, "parent cycles rejected before allocation")
	destination:Destroy()
	game.GetService = originalGetService
	print(
		"PASS: Studio importer reconstructs hierarchy, false values/tags and exact internal links, reports external links, rejects cycles"
	)
end

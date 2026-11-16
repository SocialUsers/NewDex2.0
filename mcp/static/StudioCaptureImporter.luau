--!strict

local Importer = {}
local skip = {
	Parent = true,
	ClassName = true,
	Source = true,
	UniqueId = true,
	HistoryId = true,
	ScriptGuid = true,
	RobloxLocked = true,
	Capabilities = true,
	Sandboxed = true,
}
function Importer.Import(document, parent, options)
	options = options or {}
	assert(
		type(document) == "table" and document.format == "dex-plus-capture" and document.version == 1,
		"Unsupported capture format"
	)
	assert(typeof(parent) == "Instance", "Choose an explicit destination Instance")
	assert(type(document.nodes) == "table" and #document.nodes <= 5000, "Capture exceeds 5000 nodes")
	local objects, rows, meshes = {}, {}, {}
	local meshCount = 0
	local report = {
		created = 0,
		skipped = 0,
		properties = 0,
		links = 0,
		sourceScripts = 0,
		meshesLoaded = 0,
		propertiesSkipped = 0,
		errors = {},
		errorsDropped = 0,
		externalLinks = {},
	}
	local function issue(id, property, problem)
		if #report.errors < 200 then
			report.errors[#report.errors + 1] = { id = id, property = property, error = tostring(problem):sub(1, 300) }
		else
			report.errorsDropped += 1
		end
	end
	for _, row in ipairs(document.nodes) do
		assert(
			type(row.id) == "string"
				and not rows[row.id]
				and type(row.name) == "string"
				and type(row.className) == "string",
			"Invalid/duplicate node identity"
		)
		rows[row.id] = row
	end
	local visited, active = {}, {}
	local function validate(id, depth)
		assert(depth <= 512, "Hierarchy depth exceeds 512")
		if visited[id] then
			return
		end
		assert(not active[id], "Capture contains a parent cycle")
		active[id] = true
		local row = rows[id]
		if row.parentId and rows[row.parentId] then
			validate(row.parentId, depth + 1)
		end
		active[id] = nil
		visited[id] = true
	end
	for id in pairs(rows) do
		validate(id, 0)
	end
	local function decode(value, depth)
		depth = depth or 0
		assert(depth <= 8, "Value nesting limit")
		if type(value) ~= "table" then
			assert(type(value) ~= "number" or value == value and math.abs(value) < math.huge, "Non-finite value")
			return value
		end
		local t = value.type
		if t == "nil" then
			return nil
		end
		if t == "Instance" then
			local object = objects[value.id] or options.externalMap and options.externalMap[value.id]
			assert(typeof(object) == "Instance", "Unresolved instance link: " .. tostring(value.id))
			return object
		end
		if t == "Vector2" then
			return Vector2.new(value.x, value.y)
		end
		if t == "Vector3" then
			return Vector3.new(value.x, value.y, value.z)
		end
		if t == "Color3" then
			return Color3.new(value.r, value.g, value.b)
		end
		if t == "CFrame" then
			assert(#value.components == 12, "CFrame requires 12 components")
			return CFrame.new(table.unpack(value.components))
		end
		if t == "UDim" then
			return UDim.new(value.scale, value.offset)
		end
		if t == "UDim2" then
			return UDim2.new(value.xScale, value.xOffset, value.yScale, value.yOffset)
		end
		if t == "EnumItem" then
			return Enum[value.enum][value.name]
		end
		if t == "BrickColor" then
			return BrickColor.new(value.number)
		end
		if t == "Content" then
			return value.uri == "" and Content.none or Content.fromUri(value.uri)
		end
		if t == "NumberRange" then
			return NumberRange.new(value.min, value.max)
		end
		if t == "Rect" then
			return Rect.new(value.minX, value.minY, value.maxX, value.maxY)
		end
		if t == "Font" then
			return Font.new(value.family, decode(value.weight, depth + 1), decode(value.style, depth + 1))
		end
		if t == "PhysicalProperties" then
			return PhysicalProperties.new(
				value.density,
				value.friction,
				value.elasticity,
				value.frictionWeight,
				value.elasticityWeight
			)
		end
		if t == "NumberSequence" or t == "ColorSequence" then
			local points = {}
			for _, point in ipairs(value.keypoints) do
				if t == "NumberSequence" then
					points[#points + 1] = NumberSequenceKeypoint.new(point.time, point.value, point.envelope or 0)
				else
					points[#points + 1] = ColorSequenceKeypoint.new(point.time, decode(point.value, depth + 1))
				end
			end
			return t == "NumberSequence" and NumberSequence.new(points) or ColorSequence.new(points)
		end
		error("Unsupported captured value: " .. tostring(t), 0)
	end
	local function createNode(row)
		if row.className == "MeshPart" then
			local props = row.properties or {}
			local uri = props.MeshId
			if type(props.MeshContent) == "table" and props.MeshContent.type == "Content" then
				uri = props.MeshContent.uri
			end
			if type(uri) == "string" and uri ~= "" and options.loadMeshes == true then
				local loadOptions = {}
				for _, key in ipairs({ "CollisionFidelity", "RenderFidelity" }) do
					if props[key] then
						loadOptions[key] = decode(props[key])
					end
				end
				local cacheKey = uri
					.. "|"
					.. tostring(loadOptions.CollisionFidelity)
					.. "|"
					.. tostring(loadOptions.RenderFidelity)
				if meshes[cacheKey] == nil and meshCount < 64 then
					meshCount += 1
					local good, template = pcall(function()
						return game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(uri), loadOptions)
					end)
					meshes[cacheKey] = good and template or false
					if not good then
						issue(row.id, "MeshContent", template)
					end
				end
				if meshes[cacheKey] then
					report.meshesLoaded += 1
					return meshes[cacheKey]:Clone()
				end
				issue(row.id, "MeshContent", "Mesh not loaded; asset unavailable or 64-unique-mesh limit reached")
			else
				issue(
					row.id,
					"MeshContent",
					"Mesh geometry not embedded; use loadMeshes=true to load its asset URI where permitted"
				)
			end
		end
		if row.className == "UnionOperation" or row.className == "NegateOperation" then
			issue(row.id, nil, "CSG geometry is not contained in this property capture")
		end
		return Instance.new(row.isService and "Folder" or row.className)
	end
	local container = Instance.new("Folder")
	container.Name = options.name or document.name or "Dex reference"
	local ok, problem = pcall(function()
		for index, row in ipairs(document.nodes) do
			if row.provenance == "reconstructed" and not options.includeReconstructed then
				report.skipped += 1
				issue(row.id, nil, "Reconstructed entry omitted")
			else
				local created, object = pcall(createNode, row)
				if created then
					object.Name = row.name
					objects[row.id] = object
					report.created += 1
					if row.isService then
						issue(
							row.id,
							nil,
							"Service captured as a Folder under the import container; move children to the intended service"
						)
					end
					if object:IsA("BaseScript") then
						object.Enabled = false
					end
				else
					report.skipped += 1
					issue(row.id, nil, object)
				end
			end
			if index % 100 == 0 then
				task.wait()
			end
		end
		local deferred = {}
		for index, row in ipairs(document.nodes) do
			local object = objects[row.id]
			if object then
				local keys = {}
				for key in pairs(row.properties or {}) do
					keys[#keys + 1] = key
				end
				table.sort(keys, function(a, b)
					local priority = {
						Font = 1,
						FontFace = 2,
						Position = 3,
						Orientation = 4,
						Rotation = 5,
						CFrame = 6,
						WorldPivot = 7,
					}
					local first, last = priority[a] or 0, priority[b] or 0
					return first == last and a < b or first < last
				end)
				for _, key in ipairs(keys) do
					local value = row.properties[key]
					local restricted = row.writeRestricted and row.writeRestricted[key]
					if
						skip[key]
						or row.readOnly and row.readOnly[key]
						or restricted
						or row.isService
						or row.className == "MeshPart" and (key == "MeshId" or key == "MeshContent" or key == "CollisionFidelity" or key == "RenderFidelity")
						or object:IsA("BaseScript") and (key == "Enabled" or key == "Disabled")
					then
						report.propertiesSkipped += 1
					else
						if type(value) == "table" and value.type == "Instance" then
							deferred[#deferred + 1] = { object = object, id = row.id, key = key, value = value }
						else
							local good, why = pcall(function()
								object[key] = decode(value)
							end)
							if good then
								report.properties += 1
							else
								issue(row.id, key, why)
							end
						end
					end
				end
				for key, value in pairs(row.attributes or {}) do
					local good, why = pcall(function()
						object:SetAttribute(key, decode(value))
					end)
					if not good then
						issue(row.id, "attribute:" .. key, why)
					end
				end
				for _, tag in ipairs(row.tags or {}) do
					local good, why = pcall(function()
						game:GetService("CollectionService"):AddTag(object, tag)
					end)
					if not good then
						issue(row.id, "tag", why)
					end
				end
			end
			if index % 100 == 0 then
				task.wait()
			end
		end
		for _, link in ipairs(deferred) do
			local good, why = pcall(function()
				link.object[link.key] = decode(link.value)
			end)
			if good then
				report.links += 1
			else
				issue(link.id, link.key, why)
				if #report.externalLinks < 200 then
					report.externalLinks[#report.externalLinks + 1] =
						{ fromId = link.id, property = link.key, toId = link.value.id }
				end
			end
		end
		if options.includeSource == true then
			local chunks = {}
			for _, part in ipairs(document.scripts or {}) do
				chunks[part.instanceId] = chunks[part.instanceId] or {}
				table.insert(chunks[part.instanceId], part)
			end
			for id, parts in pairs(chunks) do
				local object = objects[id]
				if object and object:IsA("LuaSourceContainer") then
					table.sort(parts, function(a, b)
						return a.offset < b.offset
					end)
					local text = {}
					local nextByte = 1
					local expected = parts[1].totalBytes
					for _, part in ipairs(parts) do
						assert(part.offset == nextByte and part.totalBytes == expected, "Incomplete source chunks")
						nextByte += #part.source
						text[#text + 1] = part.source
					end
					assert(nextByte - 1 == expected, "Incomplete source")
					local good, why = pcall(function()
						object.Source = table.concat(text)
					end)
					if good then
						report.sourceScripts += 1
					else
						issue(id, "Source", why)
					end
				end
			end
		end
		for _, row in ipairs(document.nodes) do
			local object = objects[row.id]
			if object then
				local target = objects[row.parentId] or container
				local good, why = pcall(function()
					object.Parent = target
				end)
				if not good then
					issue(row.id, "Parent", why)
					object.Parent = container
				end
			end
		end
		container.Parent = parent
	end)
	for _, template in pairs(meshes) do
		if template then
			pcall(template.Destroy, template)
		end
	end
	if not ok then
		for _, object in pairs(objects) do
			pcall(object.Destroy, object)
		end
		container:Destroy()
		error(problem, 0)
	end
	return container, report, objects
end
function Importer.FromJson(json, parent, options)
	assert(type(json) == "string" and #json <= 16 * 1024 * 1024, "Capture JSON exceeds 16 MiB")
	return Importer.Import(game:GetService("HttpService"):JSONDecode(json), parent, options)
end
return Importer

--!strict

------------------------------ Module ------------------------------

local function Main()
	local Graph = {}
	local function key(path)
		local parts = {}
		for _, name in ipairs(path) do
			parts[#parts + 1] = #name .. ":" .. name
		end
		return table.concat(parts)
	end

	function Graph.Create()
		local self = { Nodes = {}, Edges = 0 }
		function self:Node(path)
			local id = key(path)
			local node = self.Nodes[id]
			if not node then
				node = {
					Id = id,
					Path = table.clone(path),
					Requires = {},
					RequiredBy = {},
					Members = {},
					Calls = 0,
				}
				self.Nodes[id] = node
			end
			return node
		end
		function self:RecordRequire(fromPath, toPath)
			if type(fromPath) ~= "table" or type(toPath) ~= "table" or #toPath == 0 then
				return
			end
			local from, to = self:Node(fromPath), self:Node(toPath)
			if not from.Requires[to.Id] then
				from.Requires[to.Id] = to
				to.RequiredBy[from.Id] = from
				self.Edges += 1
			end
			to.Calls += 1
		end
		function self:RecordMember(path, member)
			if type(member) ~= "table" or (type(member.Name) ~= "string" and type(member.Name) ~= "number") then
				return
			end
			local node = self:Node(path)
			local id = key(member.Path or { member.Name })
			local record = node.Members[id]
			if not record then
				record = {
					Name = member.Name,
					Path = member.Path or { member.Name },
					Types = {},
					Count = 0,
				}
				node.Members[id] = record
			end
			if type(member.Count) == "number" and member.Count > record.Count then
				record.Count = member.Count
			end
			for index = 1, math.min(member.Count or 0, 32) do
				local kind = (member.Arguments or {})[index] or "unknown"
				if not record.Types[index] then
					record.Types[index] = {}
				end
				record.Types[index][kind] = true
			end
		end
		-- Entry points are nodes nobody requires but that require others.
		function self:Roots()
			local out = {}
			for _, node in pairs(self.Nodes) do
				local required = false
				for _ in pairs(node.RequiredBy) do
					required = true
					break
				end
				if not required and next(node.Requires) ~= nil then
					out[#out + 1] = node
				end
			end
			table.sort(out, function(a, b)
				return table.concat(a.Path, ".") < table.concat(b.Path, ".")
			end)
			return out
		end
		function self:Export()
			local rows = {}
			for _, node in pairs(self.Nodes) do
				local members = {}
				for _, record in pairs(node.Members) do
					local argumentSets = {}
					for index, kinds in pairs(record.Types) do
						local names = {}
						for kind in pairs(kinds) do
							names[#names + 1] = kind
						end
						table.sort(names)
						argumentSets[index] = table.concat(names, " | ")
					end
					members[#members + 1] = {
						Name = record.Name,
						Path = record.Path,
						MaxArity = record.Count,
						ArgumentTypes = argumentSets,
					}
				end
				table.sort(members, function(a, b)
					return table.concat(a.Path, ".") < table.concat(b.Path, ".")
				end)
				local requiredBy = {}
				for id in pairs(node.RequiredBy) do
					requiredBy[#requiredBy + 1] = self.Nodes[id].Path
				end
				table.sort(requiredBy, function(a, b)
					return table.concat(a, ".") < table.concat(b, ".")
				end)
				rows[#rows + 1] = {
					Path = node.Path,
					Members = members,
					RequiredBy = requiredBy,
					Observations = node.Calls,
				}
			end
			table.sort(rows, function(a, b)
				return table.concat(a.Path, ".") < table.concat(b.Path, ".")
			end)
			return { Schema = 1, Kind = "module-graph", Nodes = rows, Edges = self.Edges }
		end
		return self
	end

	return Graph
end
return { InitDeps = function() end, InitAfterMain = function() end, Main = Main }

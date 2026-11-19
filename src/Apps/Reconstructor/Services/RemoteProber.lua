--!strict

local Apps, world, scheduler

------------------------------ Initialization ------------------------------

local function InitDeps(d)
	Apps, world = d.Apps, d.Game or game
	scheduler = d.Task or task
end
------------------------------ Module ------------------------------

local function CreateModule()
	local Prober = {}
	local MAX_ARGS = 16
	local RESPONSE_BUDGET = 64
	local TIMEOUT = 10

	function Prober.Create(onEmit, onChange)
		local self = {
			Armed = false,
			Pending = nil,
			Queue = {},
			Results = {}, -- remote full name -> {Calls, Errors, Returns}
			Calls = 0,
		}
		local destroyed = false

		-- Synthesize one probe argument set from the observed schema: reuse
		-- seen key positions with non-destructive defaults; unseen slots stay
		-- nil. Schemas come from RuntimeEvidence's passive payload capture.
		function Prober.Synthesize(schema)
			local arguments = {}
			if type(schema) ~= "table" or type(schema.Keys) ~= "table" then
				return arguments, 0
			end
			local count = 0
			for _, slot in pairs(schema.Keys) do
				if count >= MAX_ARGS then
					break
				end
				count += 1
				local kind = next(slot.Types or {}) or "nil"
				if kind == "number" then
					arguments[count] = 0
				elseif kind == "boolean" then
					arguments[count] = false
				elseif kind == "string" then
					arguments[count] = ""
				elseif kind == "table" then
					arguments[count] = {}
				else
					arguments[count] = nil
				end
			end
			return arguments, count
		end

		function Prober.QueueProbe(remote, arguments, attempt)
			if destroyed or not self.Armed then
				return false, "Prober is disarmed"
			end
			local ok, class = pcall(function()
				return remote.ClassName
			end)
			if not ok or class ~= "RemoteFunction" then
				return false, "Only RemoteFunction probes are queued"
			end
			if type(arguments) ~= "table" or #arguments > MAX_ARGS then
				return false, "Argument set invalid"
			end
			self.Queue[#self.Queue + 1] = {
				Remote = remote,
				Arguments = table.clone(arguments),
				Attempt = attempt or "schema",
			}
			onChange(("Queued probe %d for %s"):format(#self.Queue, remote.Name))
			return true
		end

		function Prober.Step()
			if destroyed or not self.Armed or self.Pending then
				return false
			end
			local job = table.remove(self.Queue, 1)
			if not job then
				return false
			end
			self.Pending = job
			self.Calls += 1
			onChange("Probing " .. job.Remote.Name .. " (" .. job.Attempt .. ") — server state may change")
			scheduler.spawn(function()
				local finished = false
				scheduler.delay(TIMEOUT, function()
					if not finished and not destroyed then
						onChange("Probe timed out; the server call may still complete. Queue halted until it returns.")
					end
				end)
				local ok, result = pcall(function()
					return job.Remote:InvokeServer(table.unpack(job.Arguments))
				end)
				finished = true
				if destroyed then
					return
				end
				self.Pending = nil
				local okName, name = pcall(function()
					return job.Remote:GetFullName()
				end)
				local record = self.Results[okName and name or tostring(job.Remote)]
				if not record then
					record = { Calls = 0, Errors = 0, Returns = {} }
					self.Results[okName and name or tostring(job.Remote)] = record
				end
				record.Calls += 1
				local label = (okName and name or job.Remote.Name)
					.. (ok and " probe response" or " probe error")
				if ok then
					-- Returned strings often name the server modules that built
					-- them; the shared extractor claims what it recognizes.
					if Apps.ServerReferenceAnalysis then
						local visited, budget = {}, RESPONSE_BUDGET
						local function collect(value, depth)
							if budget <= 0 or depth > 4 then
								return
							end
							budget -= 1
							if type(value) == "string" and #value <= 65536 then
								Apps.ServerReferenceAnalysis.Log(value, label, onEmit)
							elseif type(value) == "table" and not visited[value] then
								visited[value] = true
								for _, child in pairs(value) do
									collect(child, depth + 1)
									if budget <= 0 then
										break
									end
								end
							end
						end
						collect(result, 0)
					end
					record.Returns[#record.Returns + 1] = typeof(result)
				else
					record.Errors += 1
					-- InvokeServer errors carry server-side stack traces.
					if Apps.ServerReferenceAnalysis then
						Apps.ServerReferenceAnalysis.Log(tostring(result):sub(1, 65536), label, onEmit)
					end
				end
				onChange(
					ok and "Probe returned; response mined for evidence"
						or "Probe errored: " .. tostring(result):sub(1, 160)
				)
			end)
			return true
		end

		function Prober.SetArmed(value)
			self.Armed = value == true
			if not self.Armed then
				table.clear(self.Queue)
			end
			onChange(
				self.Armed and "Prober ARMED — queued probes may change server state"
					or "Prober disarmed; queue cleared"
			)
			return self.Armed
		end

		function Prober.Stats()
			return { Calls = self.Calls, Queued = #self.Queue, Pending = self.Pending ~= nil, Results = self.Results }
		end

		function Prober.Destroy()
			destroyed = true
			self.Armed = false
			table.clear(self.Queue)
		end

		if Main.AddCleanup then
			Main.AddCleanup(function()
				Prober.Destroy()
			end)
		end
		return self
	end

	return Prober
end
return { InitDeps = InitDeps, InitAfterMain = function() end, Main = CreateModule }

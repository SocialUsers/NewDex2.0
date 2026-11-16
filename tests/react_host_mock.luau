--!strict

warn = print
task.spawn = function() end
task.cancel = function() end
task.wait = function() end
local nativeTypeof = typeof
typeof = function(value)
	if type(value) == "table" and rawget(value, "_props") then
		return "Instance"
	end
	return nativeTypeof(value)
end
service.HttpService = {
	UrlEncode = function(_, s)
		return s
	end,
}
service.RunService = {
	IsClient = function()
		return true
	end,
	IsStudio = function()
		return false
	end,
	Heartbeat = signal(),
}
service.CollectionService.AddTag = function() end
service.CollectionService.RemoveTag = function() end
service.CollectionService.GetTags = function()
	return {}
end
function methods:GetService(name)
	return service[name]
end
function methods:ResetPropertyToDefault(name)
	self[name] = nil
end
function methods:GetDebugId()
	return self.Name
end
function methods:GetTags()
	return {}
end
Lib.StudioFont = Enum.Font.BuilderSans

--!strict

local errorSource = "print('start')\nerror('failed')"
local errorEntry = {
	Sequence = 2,
	Timestamp = 1700000000,
	Level = "Error",
	Message = "failed",
	Traceback = "stack test",
	Line = 2,
	Source = errorSource,
}
local infoEntry = { Sequence = 1, Timestamp = 1700000000, Level = "Info", Message = "started" }
local logs = { example = { infoEntry, errorEntry }, other = {} }
local plugins = { example = { Name = "Example" }, other = { Name = "Other" } }
local outputChanged = signal()
local reads = 0
Apps.PluginRuntime = {
	Get = function(id)
		return plugins[id]
	end,
	GetOutput = function(id)
		reads += 1
		return logs[id]
	end,
	ClearOutput = function(id)
		logs[id] = {}
		outputChanged:Fire(id)
		return true
	end,
	OutputChanged = outputChanged,
}

local oldNew = Lib.Window.new
Lib.Window.new = function()
	local window = oldNew()
	window.OnRestore = signal()
	function window:Resize() end
	function window:SetResizeHandleStyle() end
	function window:SetTitle(title)
		self.Title = title
	end
	function window:Show()
		self.Closed = false
	end
	function window:Focus() end
	function window:IsContentVisible()
		return not self.Closed
	end
	function window:Destroy()
		self.Gui:Destroy()
	end
	return window
end

local viewer = { Documents = {}, CodeFrame = { ScrollV = {} } }
local frame = viewer.CodeFrame
function frame.ScrollV:ScrollTo() end
function frame:MoveCursor(column, row)
	self.CursorX, self.CursorY = column, row
end
function frame:SourceToDisplay(row)
	return row
end
function frame:SetCopyableSelection() end
function frame:Refresh() end
function frame:GetText()
	return self.Text
end
function viewer.OpenDocument(identity, title, text)
	for _, document in ipairs(viewer.Documents) do
		if document.id == identity then
			viewer.ActiveDocument, frame.Text, frame.Lines = document, document.text, document.text:split("\n")
			return document
		end
	end
	local document = { id = identity, title = title, text = text }
	table.insert(viewer.Documents, document)
	viewer.ActiveDocument, frame.Text, frame.Lines = document, text, text:split("\n")
	return document
end
Apps.ScriptViewer = viewer
local copied
local deps = {
	Apps = Apps,
	Lib = Lib,
	Main = Main,
	Settings = Settings,
	createSimple = createSimple,
	env = {
		setclipboard = function(text)
			copied = text
		end,
	},
}
BridgeUIControl.InitDeps(deps)
Apps.BridgeUI = BridgeUIControl.Main()
PluginOutputControl.InitDeps(deps)
local output = PluginOutputControl.Main()

output.Open("example")
local window = output.Window
local content = window.GuiElems.Content
assert(window.Title == "Example - Plugin Output")
assert(content.EntryCount.Text == "2 entries" and not content.Entries.Empty.Visible)
local retained = content.Entries.Output1
content.Entries.Output2.Message.Activated:Fire()
assert(content.Details.Visible and content.Details:FindFirstChild("Text").Message.Text == "failed\n\nstack test")
content.Details.Copy.Activated:Fire()
assert(copied == "failed\n\nstack test")
content.Entries.Output2.Source.Activated:Fire()
assert(frame:GetText() == errorSource and frame.CursorY == 1)
content.Entries.Output2.Source.Activated:Fire()
assert(#viewer.Documents == 1, "source links reuse matching tabs")
frame.Text = "edited"
content.Entries.Output2.Source.Activated:Fire()
assert(#viewer.Documents == 2 and frame:GetText() == errorSource, "source links preserve the recorded revision")

logs.example[3] = { Sequence = 3, Timestamp = 1700000000, Level = "Warning", Message = "third" }
local before = reads
outputChanged:Fire("example")
outputChanged:Fire("example")
flushTasks()
assert(content.Entries.Output3 and content.Entries.Output1 == retained and reads == before + 1)
output.Open("other")
assert(content.Entries.Empty.Visible and not content.Details.Visible and not content.Entries:FindFirstChild("Output1"))
output.Open("example")
content.Clear.Activated:Fire()
flushTasks()
assert(content.Entries.Empty.Visible and logs.other and #logs.example == 0 and not content.Clear.Selectable)
window.Closed = true
before = reads
outputChanged:Fire("example")
flushTasks()
assert(reads == before, "hidden output doesn't redraw")
print(
	"PASS: Plugin Output isolation, incremental rows, trace details, source snapshot navigation, clear and hidden refresh"
)

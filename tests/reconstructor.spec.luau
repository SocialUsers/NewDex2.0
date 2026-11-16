--!strict

local Analysis = require("../src/Apps/Reconstructor/Services/ServerReferenceAnalysis").Main()
local Evidence = require("../src/Apps/Reconstructor/Services/ReconstructorEvidence").Main()
local tree = Evidence.Create()
local function add(path, evidence)
	tree:Add(path, evidence)
end
local function analyze(source)
	assert(Analysis.Source(source, "fixture", add))
end
local function node(...)
	return tree.Nodes[Evidence.Key({ ... })]
end
analyze([=[
-- game.ServerStorage.CommentIsNotEvidence
local unrelated = "game.ServerStorage.StringIsNotCode"
--[==[ game.ServerStorage.LongComment ]==]
local ss = game:GetService("ServerStorage")
local modules = ss:WaitForChild("Modules")
local value = require(modules["A.B"])
modules:FindFirstChild("MaybeFolder"):IsA("Folder")
game.ServerScriptService.Controllers.Main.ClassName == "Script"
game["ServerStorage"]:WaitForChild("With Space").Value
]=])
assert(not node("ServerStorage", "CommentIsNotEvidence"))
assert(not node("ServerStorage", "StringIsNotCode"))
assert(not node("ServerStorage", "LongComment"))
assert(node("ServerStorage", "Modules", "A.B").Classes.ModuleScript)
assert(node("ServerStorage", "Modules", "MaybeFolder").Classes.Folder)
assert(node("ServerScriptService", "Controllers", "Main").Classes.Script)
assert(node("ServerStorage", "With Space") and not node("ServerStorage", "With Space", "Value"))
assert(
	tree:ClassLabel(node("ServerStorage", "Modules")) == "Unknown",
	"intermediate nodes are not assumed to be folders"
)
local count = tree.Count
analyze("local ss = game.ServerStorage\nss = workspace\nlocal obj = ss.FalsePath")
assert(not node("ServerStorage", "FalsePath"), "reassigned aliases cannot fabricate hierarchy")
analyze("local ss = game.ServerStorage\nlocal function callback(ss) return ss.Shadowed end")
assert(not node("ServerStorage", "Shadowed"), "shadowed parameters invalidate aliases")
analyze(
	"local function f()\nlocal hiddenAlias = game.ServerStorage\nlocal a = hiddenAlias.InScope\nend\nlocal b = hiddenAlias.OutOfScope"
)
assert(
	node("ServerStorage", "InScope") and not node("ServerStorage", "OutOfScope"),
	"function-local aliases cannot leak out of their scope"
)
analyze(
	"if condition then\nlocal branchAlias = game.ServerStorage\nlocal a = branchAlias.Branch\nelse\nlocal b = branchAlias.OtherBranch\nend"
)
assert(
	node("ServerStorage", "Branch") and not node("ServerStorage", "OtherBranch"),
	"branch-local aliases do not leak into alternatives"
)
analyze("local ss = game.ServerStorage or workspace\nlocal obj = ss.Alternative")
assert(not node("ServerStorage", "Alternative"), "boolean expressions are not direct path aliases")
analyze('game.ServerStorage:FindFirstChild("Recursive", true)')
assert(not node("ServerStorage", "Recursive"), "recursive lookups do not establish direct ancestry")
analyze('game.ServerStorage:WaitForChild("Timed", 3)')
assert(node("ServerStorage", "Timed"))
analyze('game.ServerStorage["Hex\\x41"]["Decimal\\066"]')
assert(node("ServerStorage", "HexA", "DecimalB"))
analyze("game.ServerStorage[ [==[Long Name]==] ]")
assert(node("ServerStorage", "Long Name"))
Analysis.Log(
	"Script 'ServerScriptService.A Folder.Entry', Line 17\nServerStorage.Assets.Template:8: bad argument",
	"remote fixture",
	add
)
assert(node("ServerScriptService", "A Folder", "Entry"))
assert(node("ServerStorage", "Assets", "Template"))
Analysis.Log('Missing is not a valid member of Folder "ServerStorage.Assets"', "typed error", add)
assert(node("ServerStorage", "Assets").Classes.Folder)
assert(not node("ServerStorage", "Assets", "Missing"), "a missing member is not invented as an existing child")
assert(
	tree:ClassLabel(node("ServerScriptService", "A Folder", "Entry")) == "Unknown",
	"stack Script prefix does not establish Script versus ModuleScript"
)
tree:Add(
	{ "ServerStorage", "Modules", "A.B" },
	{ Source = "other", Kind = "conditional IsA constraint", Class = "Folder" }
)
assert(
	tree:ClassLabel(node("ServerStorage", "Modules", "A.B")) == "Folder / ModuleScript?",
	"retain conflicting class hints"
)
assert(
	tree:ResolveClass(node("ServerStorage", "Modules", "A.B")) == "ModuleScript",
	"require target outranks conditional class guesses"
)
local ambiguous = tree:Add(
	{ "ServerStorage", "Ambiguous" },
	{ Source = "one", Kind = "conditional IsA constraint", Class = "Model" }
)
tree:Add({ "ServerStorage", "Ambiguous" }, { Source = "two", Kind = "conditional IsA constraint", Class = "Folder" })
local resolved, status = tree:ResolveClass(ambiguous)
assert(
	resolved == "Folder" and status:find("Conflicting", 1, true),
	"equal conflicting evidence uses an explicitly tentative fallback"
)
tree:Add(
	{ "ServerStorage", "Ambiguous" },
	{ Source = "error", Kind = "error-reported container class", Class = "Model" }
)
assert(tree:ResolveClass(ambiguous) == "Model", "error-reported runtime class outranks conditional constraints")
assert(
	Evidence.Key({ "ServerStorage", "a.b" }) ~= Evidence.Key({ "ServerStorage", "a", "b" }),
	"literal dots cannot merge different paths"
)
local limited = Evidence.Create(3)
limited:Add({ "ServerStorage", "A", "B" }, { Source = "fixture", Kind = "reference" })
assert(limited.Count == 3 and limited.Dropped == 1)
assert(not Analysis.Source(string.rep("x", 2 * 1024 * 1024 + 1), "too large", add))
assert(not Analysis.Source(string.rep("game.ServerStorage.Test\n", 1000), "cancel", add, function()
	return false
end))
local export = tree:Export()
local revision = tree.Revision
tree:Add(
	{ "ServerStorage", "Modules", "A.B" },
	{ Source = "other", Kind = "conditional IsA constraint", Class = "Folder" }
)
assert(tree.Revision == revision, "duplicate evidence cannot trigger repeated tree updates")
assert(export.Inferred and not export.Complete and export.Schema == 1)
print(
	"PASS: server path literals, aliases, comments, shadowing, reassignment, class conflicts, log evidence and bounds"
)

analyze([=[
local serviceName = "Server" .. "Storage"
local section = "Mod" .. "ules"
local ss = game:GetService(serviceName)
require(ss:WaitForChild(section)["In" .. "ventory"])
require(game[("Server" .. "ScriptService")].Controllers.Config)
local dynamic = "ServerStorage"
dynamic = "Workspace"
game:GetService(dynamic).MustNotAppear
]=])
assert(node("ServerStorage", "Modules", "Inventory").Classes.ModuleScript)
assert(node("ServerScriptService", "Controllers", "Config").Classes.ModuleScript)
assert(not node("ServerStorage", "MustNotAppear"), "reassigned string bindings cannot establish paths")
print("PASS: bounded constant folding, scoped string aliases and computed literal child paths")
local lineEvidence
assert(
	Analysis.Source(
		" \t\r\n--[=[ comment\ncomment ]=]\n\v\frequire(game.ServerStorage.LineMarker)",
		"line fixture",
		function(path, evidence)
			if path[#path] == "LineMarker" then
				lineEvidence = evidence
			end
		end
	)
)
assert(
	lineEvidence and lineEvidence.Line == 4,
	"byte-based tokenizer preserves source lines through CRLF, multiline comments and all ASCII whitespace"
)

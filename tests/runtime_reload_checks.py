"""Run the real bootstrap against isolated replacement/startup fixtures."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import zlib
import random

ROOT=Path(__file__).resolve().parents[1]
sources={
    'assets.lua':'return {}',
    'Lib.lua':'return {InitDeps=function(deps) assert(deps.Main) end}',
    'entry.lua':'''local current={Alive=true,Stops=0}
current.Shutdown=function() current.Stops+=1 current.Alive=false end
EmbeddedModules.Lib().InitDeps({Main=current})
getgenv().LastFixtureMain=current
if getgenv().Failure=="startup" then error("simulated startup failure") end
local namespace={Main=current,Apps={ScriptViewer=MakeViewer()}}
getgenv().FixtureRuntime=DexRuntime
getgenv().DexPlus=namespace
assert(ActualGlobal().DexPlus~=namespace,"new runtime publication must remain staged")
getgenv().ForwardedWrite="kept"
return "started"''',
}
def table(value):
    if isinstance(value,dict):return '{'+','.join('['+json.dumps(key)+']='+table(item) for key,item in value.items())+'}'
    if isinstance(value,str):return json.dumps(value)
    return str(value)
manifest={'schema':1,'release':'reload-fixture','modules':{'Lib':'Lib.lua'},'entry':'entry.lua','assets':'assets.lua',
          'files':{name:{'bytes':len(source.encode()),'checksum':zlib.adler32(source.encode()),'sha256':hashlib.sha256(source.encode()).hexdigest()} for name,source in sources.items()}}
program='local run=(function()\n'+(ROOT/'src/Runtime/Bootstrap.luau').read_text(encoding='utf-8')+'\nend)()\n'
program+='local manifest='+table(manifest)+'\nlocal sources='+table(sources)+'\n'
program+='''
local shared={}
getgenv=function() return shared end
ActualGlobal=function() return shared end
workspace={Parent={}}
game={GetService=function() return {JSONDecode=function() return manifest end} end}
task={spawn=function(callback) callback() end,wait=function() error("unexpected yield") end}
local normalTypeof=typeof
typeof=function(value) return type(value)=="table" and value.FixtureInstance and "Instance" or normalTypeof(value) end
local function point(value) return {value[1],value[2]} end
local function range(value)
 local copied={point(value[1]),point(value[2])}
 if value.Caret then copied.Caret=point(value.Caret) end
 return copied
end
function MakeViewer()
 local viewer={Documents={}}
 local frame={Text="",CursorX=0,CursorY=0,SelectionRange={{0,0},{0,0}},AdditionalSelections={}}
 viewer.CodeFrame=frame
 function frame:GetText() return self.Text end
 function frame:MoveCursor(x,y) self.CursorX=x self.CursorY=y end
 function frame:SetCopyableSelection() end
 function frame:Refresh() end
 frame.ScrollH={ScrollTo=function(_,value) frame.ViewX=value end}
 frame.ScrollV={ScrollTo=function(_,value) frame.ViewY=value end}
 local visible=true
 viewer.Window={IsVisible=function() return visible end,Hide=function() visible=false end}
 local function remember()
  local doc=viewer.ActiveDocument
  if not doc then return end
  doc.text=frame.Text doc.x=frame.CursorX doc.y=frame.CursorY
  doc.selection=range(frame.SelectionRange) doc.additional=frame.AdditionalSelections
  doc.overwrite=frame.OverwriteMode doc.vx=frame.ViewX doc.vy=frame.ViewY
 end
 function viewer.SelectDocument(doc)
  if viewer.ActiveDocument==doc then return end
  remember() viewer.ActiveDocument=doc frame.Text=doc.text
  frame.CursorX=doc.x or 0 frame.CursorY=doc.y or 0
  frame.SelectionRange=doc.selection or {{0,0},{0,0}}
  frame.AdditionalSelections=doc.additional or {}
  frame.ViewX=doc.vx or 0 frame.ViewY=doc.vy or 0
  frame.OverwriteMode=doc.overwrite or false
 end
 function viewer.OpenDocument(id,title,text,scriptObject)
  if shared.Failure=="restore" and title=="Unsaved edits" then error("simulated restore failure") end
  local doc={id=id,title=title,text=text,script=scriptObject,dirty=false,undoStack={NewHistory=true}}
  viewer.Documents[#viewer.Documents+1]=doc viewer.SelectDocument(doc) return doc
 end
 function viewer.CloseDocument(doc)
  for index,item in ipairs(viewer.Documents) do if item==doc then table.remove(viewer.Documents,index) break end end
  if viewer.ActiveDocument==doc then viewer.ActiveDocument=nil viewer.SelectDocument(viewer.Documents[1]) end
 end
 viewer.TabStrip={Update=function() end}
 viewer.OpenDocument({},"Untitled 1","")
 return viewer
end
local function fetch(path)
 if shared.Failure=="download" and path=="Lib.lua" then error("simulated HTTP failure") end
 return path=="manifest.json" and "manifest" or assert(sources[path],path)
end
local old=MakeViewer()
old.CloseDocument(old.Documents[1])
local scriptObject={FixtureInstance=true}
local tableId={Callback=function() error("old object must not survive reload") end}
local first=old.OpenDocument(tableId,"Unsaved edits","cached old text",scriptObject)
first.dirty=true first.undoStack={OldHistory=true}
old.CodeFrame.Text="print('unsaved live text')"
old.CodeFrame.SelectionRange={{1,0},{7,0}}
old.CodeFrame.CursorX=7 old.CodeFrame.CursorY=0
old.CodeFrame.AdditionalSelections={{{2,0},{4,0},Caret={2,0}}}
old.CodeFrame.OverwriteMode=true old.CodeFrame.ViewX=3 old.CodeFrame.ViewY=4
local second=old.OpenDocument("scratch","Second tab","second source")
old.SelectDocument(first)
old.Window:Hide()
local original={Alive=true,Stops=0}
original.Shutdown=function() original.Stops+=1 original.Alive=false end
shared.DexPlus={Main=original,Apps={ScriptViewer=old}}
local previous=shared.DexPlus
assert(run("fixture/",{Fetch=fetch})=="started")
local current=shared.DexPlus
assert(current~=previous and original.Stops==1 and not original.Alive,"successful reload shuts down only the old runtime once")
assert(current.Main.Alive and shared.ForwardedWrite=="kept","staged getgenv forwards unrelated global writes")
local restored=current.Apps.ScriptViewer
assert(#restored.Documents==2 and restored.Documents[1].title=="Unsaved edits","only original editor tabs survive replacement")
assert(restored.Documents[1].text=="print('unsaved live text')" and restored.Documents[2].text=="second source","active live source and inactive source survive reload")
assert(restored.Documents[1].script==scriptObject and restored.Documents[1].id~=tableId,"game instances survive while old table identity/callbacks do not")
assert(restored.Documents[1].dirty and restored.Documents[1].undoStack.NewHistory and not restored.Documents[1].undoStack.OldHistory,"dirty flags survive with entirely new history")
assert(restored.ActiveDocument==restored.Documents[1] and restored.CodeFrame.CursorX==7 and restored.CodeFrame.AdditionalSelections[1].Caret[1]==2,"active tab, caret and reversed secondary selection survive")
assert(restored.CodeFrame.OverwriteMode and restored.CodeFrame.ViewX==3 and restored.CodeFrame.ViewY==4 and not restored.Window:IsVisible(),"overwrite, scroll and visibility survive")
first.selection[1][1]=99
assert(restored.CodeFrame.SelectionRange[1][1]==1,"selection snapshots share no old mutable selection tables")
assert(shared.DexPlusRuntimeStats.RestoredEditorDocuments==2 and shared.DexPlusRuntimeStats.EditorHistoryRestored==false,"replacement stats explicitly describe history reset")
assert(run("fixture/",{Fetch=fetch})=="started" and current.Main.Stops==1 and original.Stops==1,"each subsequent replacement shuts down its predecessor exactly once")
local good=shared.DexPlus
for _,failure in ipairs({"download","startup","restore"}) do
 shared.Failure=failure
 local ok=pcall(run,"fixture/",{Fetch=fetch})
 assert(not ok and shared.DexPlus==good and good.Main.Alive and good.Main.Stops==0,"failed "..failure.." keeps the existing runtime alive")
 if failure~="download" then assert(shared.LastFixtureMain.Stops==1 and not shared.LastFixtureMain.Alive,"failed new startup is cleaned without touching prior runtime") end
end
shared.Failure=nil
local originalSource=sources["entry.lua"]
sources["entry.lua"]="this is not valid luau"
local originalEntry=manifest.files["entry.lua"]
manifest.files["entry.lua"]={bytes=#sources["entry.lua"],checksum=0,sha256="invalid"}
local function checksum(data)
 local a,b=1,0 for index=1,#data do a=(a+data:byte(index))%65521 b=(b+a)%65521 end return b*65536+a
end
manifest.files["entry.lua"].checksum=checksum(sources["entry.lua"])
local ok=pcall(run,"fixture/",{Fetch=fetch})
assert(not ok and shared.DexPlus==good and good.Main.Alive and good.Main.Stops==0,"compile failure never shuts down the working runtime")
sources["entry.lua"]=originalSource manifest.files["entry.lua"]=originalEntry
local disk,reads={},{}
readfile=function(path) reads[path]=(reads[path] or 0)+1 if disk[path] then return disk[path] end error("missing") end
writefile=function(path,text) disk[path]=text end
assert(run("fixture/",{Fetch=fetch})=="started")
local fileCount=0 for _,count in pairs(reads) do fileCount+=1 assert(count==1,"cold startup probes each missing cache file only once") end
assert(fileCount==3)
local runtime=shared.FixtureRuntime local cachedLib=runtime.Require("Lib.lua")
assert(runtime.Require("Lib.lua")==cachedLib,"module values stay cached after releasing source/chunk buffers")
reads={}
assert(run("fixture/",{Fetch=fetch})=="started" and shared.DexPlusRuntimeStats.CacheHits==3,"warm cache retains complete integrity-validated module coverage")
for _,count in pairs(reads) do assert(count==1,"warm startup reads each valid cache file once") end
for path in pairs(disk) do disk[path]="corrupt" end
assert(run("fixture/",{Fetch=fetch})=="started" and shared.DexPlusRuntimeStats.CacheHits==0,"corrupted cached modules are still rejected and downloaded again")
print("PASS: real bootstrap replacement, isolated publication, old-listener shutdown, plain editor migration and failed startup/download/compile/restore retention")
'''
bootstrap=(ROOT/'src/Runtime/Bootstrap.luau').read_text(encoding='utf-8')
program+='\ndo\n'+bootstrap[bootstrap.index('local function checksum(data)'):bootstrap.index('if type(makefolder)')]
rng=random.Random(741)
for length in [0,1,7,8,9,15,16,17,4095,4096,4097,8191,8192,8193,65536]:
    payload=bytes(rng.randrange(256) for _ in range(length))
    literal='"'+''.join('\\%03d'%byte for byte in payload)+'"'
    program+='assert(checksum('+literal+')=='+str(zlib.adler32(payload))+',"unrolled checksum matches zlib across block/tail boundaries")\n'
program+='end\n'
with tempfile.TemporaryDirectory(prefix='dex-runtime-reload-') as directory:
    fixture=Path(directory)/'reload.luau'
    fixture.write_text(program,encoding='utf-8')
    subprocess.run([str(ROOT/'.tools/bin/luau.exe'),str(fixture)],check=True)

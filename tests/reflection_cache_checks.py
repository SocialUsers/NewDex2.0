from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'main.lua').read_text();a=s.index('\tMain.FetchRMD = function(');b=s.index('\n\tMain.ShowGui',a)
source=s[a:b]
lib_source=(ROOT/'src/Shared/Lib.lua').read_text(encoding='utf-8')
parser=lib_source[lib_source.index('Lib.ParseXML ='):lib_source.index('Lib.FastWait =')]
fixture="""local shared={} local getgenv=function() return shared end
local Main={Elevated=true,RobloxVersion="v1",DepsVersionData={"v1"},LocalDepsUpToDate=function() return true end}
local raw="xml1" local parses=0
local game={HttpGet=function() return "downloaded-xml" end}
local Lib={ReadFile=function() return raw end}
function Lib.ParseXML()
 parses+=1
 local props={tag="Properties",children={{attrs={name="Name"},children={{text="Folder"}}}}}
 return {children={{children={{children={{children={props}}}},{children={}}}}}}
end
"""+source+"""
local a=Main.FetchRMD() local b=Main.FetchRMD()
assert(parses==1 and a.Classes.Folder and b.Classes.Folder)
a.Classes.Folder.Name="mutated" a.Classes.Folder.Properties.test={Name="bad"}
local c=Main.FetchRMD() assert(c.Classes.Folder.Name=="Folder" and not c.Classes.Folder.Properties.test,"cached snapshot stays isolated")
raw="xml2" Main.FetchRMD() assert(parses==2,"raw XML change invalidates cache")
Main.RobloxVersion="v2" Main.FetchRMD() assert(parses==3,"engine version change invalidates cache")
shared.DexReflectionMetadataCache.Schema=0 Main.FetchRMD() assert(parses==4,"parser schema change invalidates cache")
local progress={}
Main.FetchRMD(function(message) progress[#progress+1]=message end)
assert(table.concat(progress,"|")=="Reading dex-explorer/rbx_rmd.dat|Reading ReflectionMetadata.xml","cached reflection status names the file")
raw=nil progress={}
Main.FetchRMD(function(message) progress[#progress+1]=message end)
assert(table.concat(progress,"|")=="Reading dex-explorer/rbx_rmd.dat|Downloading ReflectionMetadata.xml|Reading ReflectionMetadata.xml","missing cache reports the actual download")
print("PASS: reflection cache isolation, exact XML, engine version and parser schema invalidation")
"""+parser+"""
local document = Lib.ParseXML([[
<?xml version="1.0"?>
<roblox>
    <!-- This comment must not create a text node. -->
    <Item class="Metadata"><string name="Name">  Text &amp; value  </string></Item>
    <Empty />
    Tail text
</roblox>
]])
local root = document.children[1]
assert(root.tag == "roblox" and #root.children == 3)
local first = root.children[1]
assert(first.tag == "Item" and first.attrs.class == "Metadata")
local field = first.children[1]
assert(field.tag == "string" and field.attrs.name == "Name")
assert(field.children[1].text == "Text &amp; value" and #field.children == 1)
assert(root.children[2].tag == "Empty" and #root.children[2].children == 0)
assert(root.children[3].text == "Tail text")
print("PASS: reflection XML tree, comments, escaping, attribute values and significant whitespace")
"""
with tempfile.TemporaryDirectory() as d:
 p=Path(d)/'check.luau';p.write_text(fixture)
 subprocess.run([str(ROOT/'.tools/bin/luau.exe'),str(p)],check=True)

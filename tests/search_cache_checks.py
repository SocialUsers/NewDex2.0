from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[1]
source=(root/'src/Apps/Explorer/Services/SearchNameIndex.lua').read_text()
code='local Factory=(function()\n'+source+'\nend)().Main()\n'+r'''
local root={} for i=1,20000 do root[i]={Obj={Name="Object"..i},Parent=root} end
local index=Factory.Create() local revision=1
local function scan(term)
 local matches={} assert(index.Scan({root},term,revision,{},matches,{},nil,true))
 local count=0 for _ in matches do count+=1 end return matches,count
end
local _,count=scan("object1999") assert(count==11)
for i=1,100 do
 root[i].Obj.Name="Other"..i index.MarkDirty(root[i],false) revision+=1
 local _,n=scan("object1999") assert(n==11 and index.Stats.Candidates==11,"churn must not rescan all names")
end
local removed=root[300] removed.Del=true index.MarkDirty(removed,false) revision+=1
local matched,n=scan("object20000") assert(n==1 and matched[root[20000]],"swap removal preserves cached positions")
local last=root[20000] last.Del=true index.MarkDirty(last,false) revision+=1
matched,n=scan("object20000") assert(n==0 and not matched[last],"cached removal clears the final match")
local added={Obj={Name="Object20000New"},Parent=root} root[#root+1]=added index.MarkDirty(added,true) revision+=1
matched,n=scan("object20000") assert(n==1 and matched[added],"cached empty queries see newly inserted matches")
local first,many=scan("object") assert(many>8192)
root[12000].Obj.Name="OtherChanged" index.MarkDirty(root[12000],false) revision+=1
local broad,total=scan("object") assert(total==many-1 and not broad[root[12000]],"broad queries preserve coverage with bounded cache maintenance memory")
-- Duplicate groups must survive singleton conversion, renames and swap removal.
local groupedRoot={}
for i=1,2400 do groupedRoot[i]={Obj={Name="Repeated"..(i%12)},Parent=groupedRoot} end
local grouped=Factory.Create()
local function verify(term)
 local actual={} assert(grouped.Scan({groupedRoot},term,1,{},actual,{},nil,true))
 for _,node in ipairs(groupedRoot) do
  local expected=not node.Del and node.Obj.Name:lower():find(term,1,true)~=nil
  assert(not not actual[node]==not not expected,"group membership differs from current names")
 end
end
verify("repeated")
for i=1,500 do
 local node=groupedRoot[i]
 if i%3==0 then node.Del=true else node.Obj.Name="Changed"..i end
 grouped.MarkDirty(node,false)
 if i%50==0 then verify("changed") verify("repeated") verify("not-present") end
end
grouped.Clear() verify("changed")
index.Clear() assert(scan("object1999"))
print("PASS: selective query caches survive churn, swap removal, empty-to-match insertion, broad-query fallback and reset")
'''
with tempfile.TemporaryDirectory() as temp:
    path=Path(temp)/'cache.luau';path.write_text(code)
    subprocess.run([str(root/'.tools/bin/luau.exe'),str(path)],check=True)

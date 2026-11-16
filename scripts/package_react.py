"""Emit pinned React dependencies as package-sized source modules, not one bundle."""
from pathlib import Path
import json
import shutil
from vendor_react import ROOT, VENDOR, bundle, fetch_packages


def generate():
    if not (VENDOR/"lock.json").exists(): fetch_packages()
    bundle()  # Also maintains the optional offline build and license notices.
    packages=json.loads((VENDOR/'lock.json').read_text())
    output=ROOT/'src/Packages/React'
    output.mkdir(parents=True,exist_ok=True)
    paths,aliases={},{}
    for name,info in sorted(packages.items()):
        folder=VENDOR/name.replace('/','__')
        project=json.loads((folder/'default.project.json').read_text()) if (folder/'default.project.json').exists() else None
        source_root=folder/project['tree']['$path'] if project else folder
        if not any(source_root.rglob('*.lua')) and not any(source_root.rglob('*.luau')) and (folder/'init.lua').exists():
            source_root=folder
        package_id=name.split('/')[-1]
        packet='src/Packages/React/'+package_id+'.luau'
        lines=['-- '+name+'@'+info['version']+'; see THIRD_PARTY_NOTICES.md\nreturn {\n']
        for source in sorted(source_root.rglob('*')):
            if source.suffix not in ('.lua','.luau') or '.spec.' in source.name: continue
            components=list(source.relative_to(source_root).parts)
            components[-1]=source.stem
            if source.stem=='init': components.pop()
            module_id='/'.join([package_id,*components])
            paths[module_id]=packet
            lines += ['['+json.dumps(module_id)+']=function()\n',source.read_text(encoding='utf-8-sig'),'\nend,\n']
        lines.append('}\n')
        (ROOT/packet).write_text(''.join(lines),encoding='utf-8')
        for alias,spec in info['dependencies'].items():
            actual=spec.split('@')[0].split('/')[-1]
            if alias!=actual: aliases[alias]=actual
    driver='''-- Pinned virtual ModuleScript graph. Factories execute once, on require.
local packets,cache,loading,nodes={},{},{},{}
local paths={
'''+''.join('['+json.dumps(k)+']='+json.dumps(v)+',\n' for k,v in sorted(paths.items()))+'''}
local methods={}
function methods:WaitForChild(name) return assert(self[name],"Missing React module: "..self.Path.."/"..name) end
function methods:FindFirstChild(name) return rawget(self,name) end
function methods:GetFullName() return self.Path end
local function node(path)
 if nodes[path] then return nodes[path] end
 local parentPath,name=path:match("^(.*)/([^/]+)$")
 name=name or path
 local value=setmetatable({Name=name,Path=path},{__index=methods}) nodes[path]=value
 if parentPath then value.Parent=node(parentPath) value.Parent[name]=value
 elseif path~="" then value.Parent=node("") value.Parent[name]=value end
 return value
end
for path in pairs(paths) do node(path) end
'''+''.join('node("")['+json.dumps(k)+']=node('+json.dumps(v)+')\n' for k,v in aliases.items())+'''
local function bundledRequire(module)
 if type(module)=="string" then module=node(module) end
 local path=module.Path
 if cache[path]~=nil then return cache[path] end
 assert(not loading[path],"Circular React dependency: "..path)
 local packet=assert(paths[path],"Missing React source: "..path)
 if not packets[packet] then packets[packet]=DexRuntime.Require(packet) end
 local factory=assert(packets[packet][path],"Missing React factory: "..path)
 loading[path]=true
 setfenv(factory,setmetatable({script=module,require=bundledRequire},{__index=getfenv()}))
 local ok,result=pcall(factory) loading[path]=nil
 if not ok then error(result,2) end
 cache[path]=result
 return result
end
return {require=bundledRequire,versions={React="17.2.1",ReactRoblox="17.2.1"}}
'''
    (output/'Loader.luau').write_text(driver,encoding='utf-8')
    shutil.copyfile(VENDOR/'THIRD_PARTY_NOTICES.md',output/'THIRD_PARTY_NOTICES.md')
    shutil.copyfile(VENDOR/'lock.json',output/'lock.json')
    print(f'Packaged {len(paths)} React sources into {len(packages)} separately cached packages')


if __name__=='__main__': generate()

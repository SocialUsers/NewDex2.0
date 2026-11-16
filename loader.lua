--!strict

local ref="5c7f8afa5a3e4f365f747a4c41af77f3566b994c"
local base="https://raw.githubusercontent.com/wooxps/dex-explorer/"..ref.."/"
local path="dex/runtime/"..ref..".lua"
local chunk
if type(readfile)=="function" then
 local ok,data=pcall(readfile,path)
 if ok and type(data)=="string" and #data>0 then
  local compiled,value=pcall(loadstring,data,"@DexExplorer/Bootstrap")
  if compiled and type(value)=="function" then chunk=value end
 end
end
if not chunk then
 local data=game:HttpGet(base.."src/Runtime/Bootstrap.luau")
 assert(type(data)=="string" and #data>0,"Dex Explorer bootstrap download returned no source")
 local problem
 chunk,problem=loadstring(data,"@DexExplorer/Bootstrap")
 assert(chunk,"Dex Explorer bootstrap failed: "..tostring(problem))
 if type(makefolder)=="function" then pcall(makefolder,"dex") pcall(makefolder,"dex/runtime") end
 if type(writefile)=="function" then pcall(writefile,path,data) end
end
return chunk()(base)

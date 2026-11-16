"""Validate symbolic paths against actual official compiler output, never execute fixtures."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser=argparse.ArgumentParser()
parser.add_argument('--luau',required=True)
parser.add_argument('--compiler',required=True)
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
fixtures={
 'direct': ('local ss=game:GetService("ServerStorage")\nlocal modules=ss:WaitForChild("Modules")\nrequire(modules.Inventory)\nrequire(game.ServerScriptService.Controllers.Config)', {'ServerStorage.Modules.Inventory':'ModuleScript','ServerScriptService.Controllers.Config':'ModuleScript'}, []),
 'bracket': ('require(game["ServerStorage"]["Assets"]["A.B"])', {'ServerStorage.Assets.A.B':'ModuleScript'}, []),
 'unused_strings': ('local a="ServerStorage"; local b="Secret"; print(a,b)', {}, ['ServerStorage.Secret']),
 'branch': ('local s=workspace; if flag then s=game.ServerStorage end; require(s.MustNotExist)', {}, ['ServerStorage.MustNotExist']),
 'capture': ('local ss=game:GetService("ServerStorage"); return function() return require(ss.Modules.Captured) end', {'ServerStorage.Modules.Captured':'ModuleScript'}, []),
 'nested_capture': ('local ss=game.ServerScriptService; return function() return function() return require(ss.Nested.Module) end end', {'ServerScriptService.Nested.Module':'ModuleScript'}, []),
 'mutable_capture': ('local ss=game.ServerStorage; local f=function() return require(ss.Fake) end; ss=workspace; return f', {}, ['ServerStorage.Fake']),
 'class': ('local item=game:GetService("ServerStorage"):FindFirstChild("Assets"); return item:IsA("Folder")', {'ServerStorage.Assets':'Folder'}, []),
 'recursive': ('game.ServerStorage:FindFirstChild("NotDirect",true)', {}, ['ServerStorage.NotDirect']),
 'unknown_call': ('local ss=game.ServerStorage; unknown(); return require(ss.Unproven)', {}, ['ServerStorage.Unproven']),
 'large': ('local values={'+','.join(str(i) for i in range(2500))+'}\nreturn require(game:GetService("ServerStorage").Large.Module)', {'ServerStorage.Large.Module':'ModuleScript'}, []),
}
def literal(data): return '"'+''.join('\\'+str(b).zfill(3) for b in data)+'"'
def encode_varint(value):
 result=bytearray()
 while value>=128:result.append((value&127)|128);value>>=7
 result.append(value)
 return bytes(result)

def legacy_v5(raw):
 # Translate only the carrier layout; keep compiler-produced code/constants.
 pos=2
 def varint():
  nonlocal pos
  value=0;shift=0
  while True:
   b=raw[pos];pos+=1;value|=(b&127)<<shift
   if b<128:return value
   shift+=7
 strings_start=pos
 for _ in range(varint()):
  size=varint();pos+=size
 strings=raw[strings_start:pos]
 if raw[1]==3:
  while raw[pos]!=0:pos+=1;varint()
  pos+=1
 count=varint();records=[]
 for _ in range(count):
  size=varint();finish=pos+size
  header=raw[pos:pos+4];pos+=5
  types=varint();pos+=types
  begin=pos
  instructions=varint();pos+=instructions*4
  constants=varint()
  for _ in range(constants):
   tag=raw[pos];pos+=1
   if tag==0:pass
   elif tag==1:pos+=1
   elif tag==2:pos+=8
   elif tag in (3,6):varint()
   elif tag==4:pos+=4
   elif tag in (5,8):
    for _ in range(varint()):
     varint()
     if tag==8:pos+=4
   elif tag==7:pos+=16
   elif tag==9:
    pos+=1
    while raw[pos]&128:pos+=1
    pos+=1
   elif tag==10:
    varint();members=varint()+varint()
    for _ in range(members):varint()
   elif tag==11:pos+=32
   else:raise AssertionError(tag)
  for _ in range(varint()):varint()
  body=raw[begin:pos]
  tail=pos
  varint();varint()
  lineinfo=raw[pos];pos+=1
  if lineinfo:
   gap=raw[pos];pos+=1;pos+=instructions+(((instructions-1)>>gap)+1)*4
  debug=raw[pos];pos+=1
  if debug:
   for _ in range(varint()):varint();varint();varint();pos+=1
   for _ in range(varint()):varint()
  records.append(header+b'\x00\x00'+body+raw[tail:pos])
  assert pos<=finish
  pos=finish
 entry=varint()
 return bytes([5,2])+strings+encode_varint(count)+b''.join(records)+encode_varint(entry)

harness=['local P=require("../src/Apps/Reconstructor/Services/BytecodePaths").Main()']
with tempfile.TemporaryDirectory() as temp:
 for name,(source,expected,excluded) in fixtures.items():
  path=Path(temp)/(name+'.luau')
  path.write_text(source,encoding='utf-8')
  for optimize in [0,1,2]:
   raw=subprocess.check_output([args.compiler,'--binary','-g2','-O'+str(optimize),str(path)])
   code=['do local bytes='+literal(raw), 'local claims={} local ok,info=P.Analyze(bytes,"fixture",function(path,e) local key=table.concat(path,"."); claims[key]=e.Class or claims[key] or true end)', 'assert(ok,tostring(info))']
   for key,cls in expected.items(): code.append('assert(claims["'+key+'"]=="'+cls+'","'+name+' O'+str(optimize)+': '+key+'")')
   for key in excluded: code.append('assert(not claims["'+key+'"],"fabricated '+key+'")')
   code.extend(['local trailer=string.rep(\"x\",24); local accepted,details=P.Analyze(bytes..trailer,\"trailer\",function() end); assert(accepted and details.TrailerBytes==24)', 'local emitted=0; assert(not P.Analyze(bytes:sub(1,-2),\"truncated\",function() emitted+=1 end)); assert(emitted==0)', 'end'])
   harness.extend(code)
   if name=='direct' and optimize==1:
    harness.extend(['do local bytes='+literal(raw),
     'local calls=0;local ok,info=P.Analyze(bytes,"second owner",function(path,e) calls+=1;assert(e.Source=="second owner");path[1]="mutated";e.Class="mutated" end);assert(ok and info.CacheHit and calls>0)',
     'local count=0;assert(P.Analyze(bytes,"third owner",function(path,e) count+=1;assert(path[1]~="mutated" and e.Class~="mutated" and e.Source=="third owner") end));assert(count==calls)',
     'local emitted=0;local accepted,why=P.Analyze(bytes,"cancelled cached",function() emitted+=1 end,function() return false end);assert(not accepted and why=="Cancelled" and emitted==0)',
     'for n=1,600 do assert(P.Analyze(bytes..tostring(n),"eviction",function() end)) end;local valid,again=P.Analyze(bytes,"evicted owner",function(path,e) assert(e.Source=="evicted owner") end);assert(valid and not again.CacheHit,"evicted bytes are fully reanalyzed, not omitted") end'])
   old=legacy_v5(raw)
   legacy_code=['do local claims={} local ok,info=P.Analyze('+literal(old)+',"v5 fixture",function(path,e) local key=table.concat(path,".");claims[key]=e.Class or claims[key] or true end);assert(ok,tostring(info))']
   for key,cls in expected.items():legacy_code.append('assert(claims["'+key+'"]=="'+cls+'","v5 '+name+': '+key+'")')
   for key in excluded:legacy_code.append('assert(not claims["'+key+'"],"v5 fabricated '+key+'")')
   legacy_code.append('end');harness.extend(legacy_code)
   if name=='large' and optimize==1:
    assert len(raw)>4096
    harness.extend([
     'do local Reader=require("../src/Apps/Reconstructor/Services/ScriptEvidenceReader"); local Strings=require("../src/Apps/Reconstructor/Services/BytecodeStrings").Main(); local native=0; local claims={}; local raw='+literal(raw),
     'Reader.InitDeps({Apps={BytecodeStrings=Strings},env={getscriptbytecode=function() return raw end,decompile=function() native+=1 error("large native call") end}})',
     'local reader=Reader.Main().Create({Wait=function() end,Paths=function(_,bytes,checkpoint) return P.Analyze(bytes,"reader",function(path,e) if e.Class then claims[table.concat(path,".")]=e.Class end end,checkpoint) end})',
     'local obj={};assert(reader:Read(obj).Status=="Deferred" and native==0 and claims["ServerStorage.Large.Module"]=="ModuleScript");local parsed=reader.Stats.PathAnalyses;reader:Read(obj);assert(reader.Stats.PathAnalyses==parsed,"completed bytecode paths reuse the bounded cache") end'
    ])
    harness.extend(['do local emitted=0; local ok,why=P.Analyze('+literal(raw)+',"cancel",function() emitted+=1 end,function() return false end); assert(not ok and why=="Cancelled" and emitted==0) end'])
 # Re-encode opcodes using the public instruction lengths, preserving AUX words.
 source='return require(game:GetService("ServerStorage").Encoded.Module)'
 path=Path(temp)/'encoded.luau';path.write_text(source)
 raw=bytearray(subprocess.check_output([args.compiler,'--binary','-O1',str(path)]))
 pos=0
 def byte():
  global pos
  value=raw[pos];pos+=1;return value
 def varint():
  value=0;shift=0
  while True:
   b=byte();value|=(b&127)<<shift
   if b<128:return value
   shift+=7
 version=byte();types=byte()
 for _ in range(varint()):
  n=varint();pos+=n
 if types==3:
  while byte()!=0:varint()
 proto_count=varint()
 aux={7,8,12,15,16,20,27,28,29,30,31,32,53,55,58,60,66,74,75,77,78,79,80,83,84,85,86,87,88,90,91}
 for _ in range(proto_count):
  size=varint();end=pos+size;pos+=5;n=varint();pos+=n
  count=varint();pc=0
  while pc<count:
   op=raw[pos+pc*4];raw[pos+pc*4]=(op*227)%256
   pc+=2 if op in aux else 1
  pos=end
 harness.extend(['do local claims={} local ok,info=P.Analyze('+literal(raw)+',"encoded",function(path,e) if e.Class then claims[table.concat(path,".")]=e.Class end end);assert(ok,tostring(info));assert(info.Encoding=="roblox" and claims["ServerStorage.Encoded.Module"]=="ModuleScript") end'])
 # A serialized retained closure can have upvalues at its selected entry.
 source='local ss=game.ServerStorage; return function() return require(ss.Seeded.Module) end'
 path=Path(temp)/'seeded.luau';path.write_text(source)
 raw=bytearray(subprocess.check_output([args.compiler,'--binary','-O1',str(path)]))
 assert raw[-1]==1
 raw[-1]=0
 harness.append('do local claims={} local ok,info=P.Analyze('+literal(raw)+',"seeded closure",function(path,e) if e.Class then claims[table.concat(path,".")]=e.Class end end,nil,{[1]={Path={"ServerStorage"}}});assert(ok,tostring(info));assert(claims["ServerStorage.Seeded.Module"]=="ModuleScript") end')
 # Private on-device samples are optional and never committed into the tests.
 import json
 private=root/'.private/research/bytecode'
 if (private/'format.json').exists():
  for index,sample in enumerate(json.loads((private/'format.json').read_text())['Samples'],1):
   raw=(private/f'sample-{index}.bin').read_bytes()
   harness.append('do local ok,info=P.Analyze('+literal(raw)+',"device sample",function() end);assert(ok,tostring(info));assert(info.TrailerBytes==24 and info.Claims>='+str(sample['Claims'])+') end')
 harness.append('print("PASS: compiled paths, captures/seeds, branch rejection, encoded opcodes, trailers, actual private samples and cancellation")')
 target=root/'.build/bytecode-path-checks.luau';target.parent.mkdir(exist_ok=True);target.write_text('\n'.join(harness),encoding='utf-8')
 subprocess.run([args.luau,str(target)],check=True)

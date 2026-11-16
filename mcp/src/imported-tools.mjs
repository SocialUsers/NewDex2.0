import {setTimeout as delay} from 'node:timers/promises';
import * as z from 'zod/v4';
import {BridgeError,validateJson} from './protocol.mjs';
import {createImportedContext} from './imported-context.mjs';
import inventory from '../third-party/executor-mcp/catalog.json' with {type:'json'};
import {importedTools} from '../third-party/executor-mcp/tools.mjs';

const EncodeResult = `
local bytes, nodes = 0, 0
local seen = {}
local function safeText(text, cap)
 local count = math.min(#text, cap, 48000 - bytes)
 local result = string.sub(text, 1, count)
 while #result > 0 and not utf8.len(result) and #result > count - 4 do
  result = string.sub(result, 1, -2)
 end
 if not utf8.len(result) then return "<invalid UTF-8>" end
 bytes += #result
 return result
end
local function encode(value, depth)
 nodes += 1
 if depth > 6 or nodes > 3500 or bytes >= 48000 then return "<truncated>" end
 local kind = typeof(value)
 if kind == "nil" then return nil end
 if kind == "boolean" then return value end
 if kind == "number" and value == value and math.abs(value) < math.huge then return value end
 if kind == "string" then return safeText(value, 16000) end
 if kind == "Instance" then return safeText("Instance: " .. value:GetFullName(), 1000) end
 if kind ~= "table" then return safeText(tostring(value), 1000) end
 if seen[value] then return "<cycle>" end
 seen[value] = true
 local result, count = {}, 0
 local length = #value
 local array = length > 0
 if array then
  local checked = 0
  for key in pairs(value) do
   checked += 1
   if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > length or checked > 500 then
    array = false
    break
   end
  end
 end
 for key, child in pairs(value) do
  if count >= 500 or nodes > 3500 or bytes >= 48000 then break end
  count += 1
  local index = if array then key else safeText(tostring(key), 256)
  result[index] = encode(child, depth + 1)
 end
 seen[value] = nil
 return result
end
local serialized = game:GetService("HttpService"):JSONEncode({ value = encode(runImported(), 0) })
assert(#serialized <= 60000, "VALUE_LIMIT: imported result exceeds 60000 bytes")
return serialized
`;

function failure(message,code='imported_tool_failed'){return new BridgeError(code,message);}
function complete(response){
 if(response?.state!=='completed'||!response.result)throw failure('Dex did not return a confirmed command result',response?.error?.code||'outcome_unknown');
 return response.result;
}

export async function runImported(broker,sessionId,source,options={},signal){
 const timeout=Math.min(120000,Math.max(100,Number(options.timeoutMs)||20000));
 const deadline=Date.now()+timeout;
 const identity=options.threadContext;
 const setup=Number.isInteger(identity)&&identity>=0&&identity<=8
  ? `local setter = setthreadidentity or setidentity\nif type(setter) == "function" then pcall(setter, ${identity}) end\n` : '';
 const vm=options.env==='vm'?'persistent':options.env==='vm-reset'?'reset':undefined;
 const prelude=options.scriptPrelude||'';
 const body=vm==='persistent'?`
local scope = assert(dex.vm, "UNSUPPORTED: update the Dex client for persistent scripts")
scope.print, scope.warn, scope.dex, scope.mcp = print, warn, dex, mcp
local chunk, problem = loadstring(${JSON.stringify(source).replace(/\\u([0-9a-f]{4})/gi,'\\u{$1}')}, "@Dex/Script")
assert(chunk, problem)
setfenv(chunk, scope)
return chunk()
`:source;
 const wrapped=vm==='reset'?'return true':`${prelude}\nlocal function runImported()\n${setup}${body}\nend\n${EncodeResult}`;
 let run=complete(await broker.execute('dex_run_luau',{sessionId,source:wrapped,...(vm?{vm,vmKey:options.vmKey||'default'}:{})},signal));
 try{
  let interval=80;
  while(run.status==='running'){
   const remaining=deadline-Date.now();
   if(remaining<=0)throw failure('The imported tool exceeded its time budget','deadline_exceeded');
   await delay(Math.min(interval,remaining),undefined,{signal});
   interval=Math.min(500,interval*2);
   run=complete(await broker.execute('dex_get_run',{sessionId,runId:run.runId},signal));
  }
  if(run.status!=='completed')throw failure(run.error||`Dex Luau run ended with status ${run.status}`);
  if(typeof run.returns?.[0]!=='string')throw failure('Executor returned an invalid imported-tool result');
  const value=JSON.parse(run.returns[0]).value;
  return options.scriptToken?{result:value,output:run.output||[],outputDropped:run.outputDropped||0}:value;
 }catch(error){
  if(run.status==='running'&&(signal?.aborted||error.code==='deadline_exceeded')){
   await broker.execute('dex_cancel_run',{sessionId,runId:run.runId}).catch(()=>{});
  }
  throw error;
 }
}

export function registerImportedTools(register,broker,catalog=new Map(),options={}){
 const host=createImportedContext(broker,catalog,inventory,runImported,options);
 const orchestrators=new Set(['agent-run','smart-task','session-replay','script','script-fanout','playbook-run']);
 for(const tool of importedTools){
  const name='dex_'+tool.name.replaceAll('-','_');
  const original=tool.input.shape;
  const schema=original.sessionId
   ?tool.input.safeExtend({targetSessionId:z.uuid().optional()})
   :tool.input.safeExtend({sessionId:z.uuid().optional()});
  const grant=tool.requiresClient||tool.mutatesState||orchestrators.has(tool.name)?'execute':'inspect';
  const callback=async(args,ctx)=>{
   const input={...args};
   const target=original.sessionId?input.targetSessionId:input.sessionId;
   delete input[original.sessionId?'targetSessionId':'sessionId'];
   if(tool.name==='teach-mode')input.includeRemoteSpy=false;
   if(tool.name==='semantic-search-scripts'){
    if(input.query.length>500)throw failure('Semantic query exceeds 500 characters','invalid_arguments');
    input.limit=Math.max(1,Math.min(input.limit,50));
    input.maxScripts=Math.max(1,Math.min(input.maxScripts,400));
   }

   if(tool.name==='session-replay'){
    if(input.dryRun===false&&!target)throw failure('Live replay needs an explicit targetSessionId','session_required');
    if(input.dryRun===false&&target!==input.sessionId)throw failure('Replay target must match the recorded Dex session','wrong_session');
   }
   validateJson(input);
   const signal=ctx.mcpReq.signal;
   const context=host.context(tool,input,target,signal);
   if(tool.requiresClient){
    if(!context.client)throw failure('Select a connected Dex client','session_required');
    if(!broker.resolve(context.client.id).grants.execute)throw failure('Enable Run code in Dex to use this tool','permission_denied');
   }
   let outcome;
   try{outcome=await tool.execute(input,context);}
   catch(error){
    if(error instanceof BridgeError)throw error;
    throw failure(error instanceof Error?error.message.slice(0,800):'Imported Dex command failed');
   }
   return {result:outcome.data,summary:outcome.summary,...(outcome.isError||outcome.data?.error?{state:'failed'}:{})};
  };
  register(name,tool.description,schema,grant,callback,tool.category);
  const entry=catalog.get(name);
  if(entry)Object.assign(entry,{requiresClient:tool.requiresClient,mutatesState:tool.mutatesState,ai:tool.ai,quality:tool.quality});
 }
 return host;
}

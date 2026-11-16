import {createHash,randomUUID} from 'node:crypto';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {homedir} from 'node:os';
import {join} from 'node:path';
import {BridgeError,validateJson} from './protocol.mjs';
import {FsSavedScriptsStore,InMemorySemanticIndex,HttpEmbeddingsProvider} from '../third-party/executor-mcp/tools.mjs';

const digest=key=>createHash('sha256').update(key).digest('hex');
const luaString=value=>JSON.stringify(value).replace(/\\u([0-9a-f]{4})/gi,'\\u{$1}');
const internal=new Set(['dex_create_pairing','dex_script','dex_script_fanout','dex_playbook_run','dex_agent_run','dex_smart_task','dex_session_replay','dex_select_client','dex_clear_selection']);
const denied=(message,code='permission_denied')=>new BridgeError(code,message,403);

export function scriptPrelude(url,token){
 return `
local Http = game:GetService("HttpService")
local send = request or http_request or (syn and syn.request) or (http and http.request)
local mcp = {}
function mcp.call(name, args)
 assert(type(send) == "function", "UNSUPPORTED: executor HTTP requests unavailable")
 assert(args == nil or type(args) == "table", "Expected a table of tool arguments")
 local payload = {name = name}
 if args and next(args) ~= nil then
  payload.args = args
 end
 local response = send({
  Url = ${luaString(url + '/bridge/script-call')}, Method = "POST",
  Headers = {Authorization = ${luaString('Bearer '+token)}, ["Content-Type"] = "application/json"},
  Body = Http:JSONEncode(payload),
 })
 assert(type(response) == "table", "No response from Dex")
 local result = Http:JSONDecode(response.Body)
 assert(result.ok, result.error and result.error.message or "Dex nested tool failed")
 return result.data
end
function mcp.all(calls)
 local results, batch = {}, {}
 for key, call in calls do
  assert(#batch < 64, "Too many parallel tool calls")
  batch[#batch + 1] = {key, call}
 end
 for i = 1, #batch, 2 do
  local pending = math.min(2, #batch - i + 1)
  for j = i, math.min(i + 1, #batch) do
   local key, call = batch[j][1], batch[j][2]
   task.spawn(function()
    local ok, data = pcall(mcp.call, call[1], call[2])
    results[key] = if ok then data else {error = tostring(data)}
    pending -= 1
   end)
  end
  while pending > 0 do task.wait() end
 end
 return results
end
mcp.parallel = mcp.all
function mcp.help(name)
 return if name then mcp.call("tool-schema", {name = name}) else mcp.call("list-tools")
end
setmetatable(mcp, {__index = function(_, name)
 return function(args)
  return mcp.call((string.gsub(name, "%u", function(c) return "-" .. string.lower(c) end)), args)
 end
end})
`;
}

export function createImportedContext(broker,catalog,inventory,run,options={}){
 const aliases=new Map(inventory.tools.filter(item=>item.dex).map(item=>[item.upstream,item.dex]));
 const resolveName=name=>aliases.get(name)||('dex_'+String(name).replaceAll('-','_').replace(/^dex_/,''));
 const traces=new Map(),tickets=new Map();
 const playbooks=options.playbooks||new FsSavedScriptsStore(join(homedir(),'.dex-explorer','playbooks'));
 const semantic=options.semantic||new InMemorySemanticIndex({embeddings:new HttpEmbeddingsProvider({embeddingsUrl:null,embeddingsModel:'local-hash'})});
 let selection={};

 const project=session=>({
  id:session.sessionId,userId:session.info?.userId==null?null:Number(session.info.userId),placeId:session.info?.placeId==null?null:Number(session.info.placeId),
  username:session.info?.username||session.info?.displayName||null,displayName:session.info?.displayName||null,
  executor:null,connectedAt:session.connectedAt||Date.now(),capabilities:session.capabilities?.commands||[],
 });
 const clients={list:()=>broker.summaries().filter(item=>item.connected).map(project),get:id=>clients.list().find(client=>client.id===id)};
 const resolveClient=target=>{
  const available=clients.list();
  const exact=target&&available.find(client=>client.id===target);
  if(exact)return {status:'resolved',client:exact};
  if(!target&&selection.clientId){
   const pinned=available.find(client=>client.id===selection.clientId);
   if(pinned)return {status:'resolved',client:pinned};
  }
  if(!target&&selection.userId!=null){
   const account=available.filter(client=>client.userId===selection.userId);
   if(account.length===1){broker.defaultSessionId=account[0].id;return {status:'resolved',client:account[0]};}
   if(account.length>1)return {status:'ambiguous',candidates:account};
  }
  if(target||selection.clientId||selection.username)return {status:'none',reason:'selection-offline'};
  if(available.length===1)return {status:'resolved',client:available[0]};
  return available.length>1?{status:'ambiguous',candidates:available}:{status:'none',reason:'no-clients'};
 };
 const directory=()=>[...catalog.values()].map(tool=>({
  name:tool.name,title:tool.name,description:tool.description,category:tool.category,input:tool.inputSchema,
  requiresClient:tool.requiresClient??true,mutatesState:tool.mutatesState??tool.grant!=='inspect',ai:tool.ai,quality:tool.quality,
 }));
 const lookup=name=>directory().find(tool=>tool.name===resolveName(name));
 const tools={list:directory,find:lookup};
 const sessionLogger={
  async read(id,{from=0,to=Infinity}={}){
   return (traces.get(id)?.records||[]).filter(record=>record.seq>=from&&record.seq<=to);
  },
 };
 const keep=(value,max)=>{
  const json=JSON.stringify(value);
  return json&&Buffer.byteLength(json)<=max?JSON.parse(json):{truncated:true};
 };
 const redact=value=>{
  if(Array.isArray(value))return value.map(redact);
  if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([key,item])=>[
   key,/token|password|credential|secret|authorization|^key$/i.test(key)?'[redacted]':redact(item),
  ]));
  return value;
 };
 function trace(name,args,result,started,error){
  const id=args?.sessionId||broker.defaultSessionId||resolveClient().client?.id;
  if(!id||internal.has(name)||name==='dex_session_show')return;
  if(!traces.has(id)){
   if(traces.size>=16)traces.delete(traces.keys().next().value);
   traces.set(id,{seq:0,records:[]});
  }
  const log=traces.get(id);
  const input=keep(redact(args),8192);
  delete input.sessionId;
  delete input.commandId;
  const failure=error||result?.error||result?.state&&result.state!=='completed'&&{message:'Command failed'};
  log.records.push({seq:++log.seq,at:Date.now(),tool:name,input,elapsedMs:Date.now()-started,clientId:id,sessionId:id,
   ...(failure?{error:{message:String(failure.message||failure).slice(0,800)}}:{result:keep(redact(result),8192)})});
  if(log.records.length>64)log.records.shift();
 }
 async function invoke(name,args,target,signal,allowMutations=false,script=false){
  const actual=resolveName(name),tool=catalog.get(actual);
  if(!tool||internal.has(actual)||actual==='dex_teach_mode'&&script)throw denied('This tool cannot be called from another Dex tool');
  if((tool.mutatesState??tool.grant!=='inspect')&&!allowMutations)throw denied('This workflow does not allow mutations');
  if(script&&!target)throw denied('Script callback has no paired client');
  if(broker.assertToolEnabled)broker.assertToolEnabled(actual,target?[broker.resolve(target)]:broker.policyTargets());
  validateJson(args);
  if(script&&actual==='dex_tool_schema'&&typeof args.name==='string')args={...args,name:resolveName(args.name)};
  if(args.sessionId&&args.sessionId!==target||args.targetSessionId&&args.targetSessionId!==target)throw denied('Nested tools cannot change their paired session');
  const shape=tool.inputSchema.shape;
  const scoped=target&&(shape?.targetSessionId||shape?.sessionId)?{...args,[shape.targetSessionId?'targetSessionId':'sessionId']:target}:args;
  const parsed=tool.inputSchema.safeParse(scoped);
  if(!parsed.success)throw new BridgeError('invalid_arguments',parsed.error.issues[0]?.message||'Invalid tool input');
  const value=await tool.callback(parsed.data,{mcpReq:{signal},nested:true});
  const failed=value?.state&&value.state!=='completed'||Boolean(value?.error);
  return {data:value?.result??value,isError:Boolean(failed),summary:value?.summary};
 }
 const host={shell:{async run(command,args){
  if(process.platform!=='win32')throw new BridgeError('unsupported_platform','Roblox window listing requires Windows');
  if(command!=='powershell')throw denied('Unsupported window listing program');
  const {stdout,stderr}=await promisify(execFile)('powershell.exe',args,{windowsHide:true,timeout:15000,maxBuffer:65536});
  return {stdout,stderr,code:0};
 }}};
 broker.resolveDefaultSession=()=>resolveClient().client?.id;
 broker.scriptCall=async(key,read)=>{
  const ticket=key&&tickets.get(digest(key));
  if(!ticket||ticket.deadline<=Date.now()||ticket.signal?.aborted||ticket.remaining<=0)throw denied('Script callback token is invalid, expired, or exhausted');
  const current=broker.resolve(ticket.target);
  if(!current.socket||current.connectionId!==ticket.connectionId||!current.grants.execute)throw denied('Script callback connection or Run code grant ended');
  ticket.remaining--;
  const {name,args={}}=await read()||{};
  if(typeof name!=='string'||name.length>128||!args||typeof args!=='object'||Array.isArray(args))throw new BridgeError('invalid_arguments','Invalid script callback');
  const active=broker.resolve(ticket.target);
  if(!active.socket||active.connectionId!==ticket.connectionId||!active.grants.execute)throw denied('Script callback connection or Run code grant ended');
  if(ticket.inFlight>=2)throw denied('Too many simultaneous script callbacks','busy');
  if(tickets.get(digest(key))!==ticket||ticket.signal?.aborted)throw denied('Script callback expired');
  ticket.inFlight++;
  try{
   const result=await invoke(name,args,ticket.target,ticket.signal,true,true);
   return result.isError?{ok:false,error:{message:result.data?.error?.message||result.data?.error||'Dex tool failed'}}:{ok:true,data:result.data};
  }finally{ticket.inFlight--;}
 };
 function context(tool,input,target,signal){
  const resolution=()=>resolveClient(target||(input.client?(clients.list().find(client=>client.id===input.client||client.username?.toLowerCase()===input.client.toLowerCase())?.id||input.client):undefined));
  const client=resolution().client;
  const id=client?.id;
  const allowMutations=input.allowMutations===true||input.includeMutating===true;
  const attempted=new Set();
  const invokeStep=(name,args)=>{
   const actual=resolveName(name),entry=catalog.get(actual);
   if(entry&&(entry.mutatesState??entry.grant!=='inspect')&&allowMutations){
    const sort=(key,value)=>value&&typeof value==='object'&&!Array.isArray(value)?Object.fromEntries(Object.keys(value).sort().map(field=>[field,value[field]])):value;
    const fingerprint=JSON.stringify([actual,args],sort);
    if(attempted.has(fingerprint))throw denied('Workflow already attempted this mutation','duplicate_mutation');
    attempted.add(fingerprint);
   }
   return invoke(name,args,id,signal,allowMutations);
  };
  const agent=String(input.agent||'default').slice(0,96);
  if(input.client&&target&&input.client!==target&&input.client!==client?.username)throw denied('client and sessionId target different clients');
  const runOn=(sessionId,source,settings={})=>{
   if(broker.assertToolEnabled)broker.assertToolEnabled(resolveName(tool.name),[broker.resolve(sessionId)]);
   const ticket=settings.scriptToken&&tickets.get(digest(settings.scriptToken));
   if(settings.scriptToken&&ticket?.target!==sessionId)throw denied('Script token belongs to a different client');
   if(tool.name==='teach-mode')source=source.replaceAll('genv.__mcp_teachMode','dex.teach.State');
   return run(broker,sessionId,source,{...settings,vmKey:agent,...(ticket?{scriptPrelude:scriptPrelude(broker.url,settings.scriptToken)}:{})},signal);
  };
  return {
   signal,client,clients,tools:tool.name==='smart-task'?{
    find:lookup,list:()=>[...directory(),...['assert-state','explain-failure'].flatMap(name=>{
     const item=lookup(name);
     return item?[{...item,name}]:[];
    })],
   }:tools,sessionLogger,playbooks,semantic,host,
   session:{id:id||'unpaired',label:'Dex MCP',get selection(){return selection;},resolve:resolution,
    select(value){selection=value;broker.defaultSessionId=resolveClient(value.clientId).client?.id||resolveClient().client?.id;},
    clear(){selection={};broker.defaultSessionId=undefined;}},
   runLuau:(source,settings)=>{if(!id)throw denied('Select a connected Dex client','session_required');return runOn(id,source,settings);},
   runLuauOn:runOn,
   invokeTool:invokeStep,
   scripting:{knownTools:[...new Set([
    ...inventory.tools.filter(item=>item.dex&&!internal.has(item.dex)).map(item=>item.upstream),
    ...[...catalog.keys()].filter(name=>!internal.has(name)).flatMap(name=>[name,name.slice(4).replaceAll('_','-')]),
   ])],
    mint({budget=100,clientId=id}={}){
     const current=broker.resolve(clientId);
     if(!current.socket||!current.grants.execute)throw denied('Enable Run code on the connected Dex client');
     if(tickets.size>=16)throw denied('Too many active script callbacks','busy');
     const token=randomUUID()+randomUUID(),key=digest(token);
     tickets.set(key,{target:current.id,connectionId:current.connectionId,deadline:Date.now()+120000,signal,remaining:Math.min(budget,200),inFlight:0});
     return {token,dispose:()=>tickets.delete(key)};
    }},
  };
 }
 return {context,trace,close(){tickets.clear();broker.scriptCall=undefined;broker.resolveDefaultSession=undefined;broker.defaultSessionId=undefined;}};
}

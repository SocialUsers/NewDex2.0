import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {registerImportedTools,runImported} from '../src/imported-tools.mjs';
import {TOOLS} from '../src/protocol.mjs';

test('imported commands use unique Dex names and enforce the paired session grant',async()=>{
 const inventory=JSON.parse(await readFile(new URL('../third-party/executor-mcp/catalog.json',import.meta.url)));
 const tools=new Map(TOOLS.map(tool=>[tool.name,tool]));
 let execute=false;
 const calls=[];
 const broker={
  summaries(){return [{sessionId:'test-session',connected:true,info:{}}];},
  resolve(id){assert.equal(id,'test-session');return {id,grants:{execute}};},
  async execute(name,args){
   calls.push({name,args});
   return {state:'completed',result:{status:'completed',returns:['{"value":{"hash":"abc"}}']}};
  },
 };
 registerImportedTools((name,description,schema,grant,callback)=>{
  assert.ok(!tools.has(name),name);
  tools.set(name,{schema,grant,callback});
 },broker);
 for(const entry of inventory.tools.filter(tool=>tool.status==='imported'))assert.ok(tools.has(entry.dex),entry.dex);
 const tool=tools.get('dex_get_script_hash');
 assert.equal(tool.grant,'execute');
 const ctx={mcpReq:{signal:new AbortController().signal}};
 const args={sessionId:'test-session',scriptPath:'game.Workspace.Test'};
 await assert.rejects(tool.callback(args,ctx),{code:'permission_denied'});
 assert.equal(calls.length,0);
 execute=true;
 const output=await tool.callback(args,ctx);
 assert.deepEqual(output.result,{hash:'abc'});
 assert.equal(calls[0].name,'dex_run_luau');
 assert.equal(calls[0].args.sessionId,'test-session');
 assert.match(calls[0].args.source,/JSONEncode/);
});

test('Dex run polling decodes the executor result and cancels timed-out runs',async()=>{
 const calls=[];
 const broker={async execute(name,args){
  calls.push({name,args});
  if(name==='dex_get_run')return {state:'completed',result:{status:'completed',returns:['{"value":{"ok":false}}']}};
  return {state:'completed',result:{status:'running',runId:'r1'}};
 }};
 assert.deepEqual(await runImported(broker,'target','return {}'),{ok:false});
 assert.deepEqual(calls.map(call=>call.name),['dex_run_luau','dex_get_run']);
 const timeoutCalls=[];
 const stalled={async execute(name,args){
  timeoutCalls.push({name,args});
  return {state:'completed',result:{status:'running',runId:'r2'}};
 }};
 await assert.rejects(runImported(stalled,'target','return {}',{timeoutMs:100}),{code:'deadline_exceeded'});
 assert.equal(timeoutCalls.at(-1).name,'dex_cancel_run');
 assert.equal(timeoutCalls.at(-1).args.runId,'r2');
});

test('host-backed tools select clients, persist playbooks, plan workflows, and index scripts',async t=>{
 const {mkdtemp,rm}=await import('node:fs/promises');
 const {tmpdir}=await import('node:os');
 const {join}=await import('node:path');
 const {randomUUID}=await import('node:crypto');
 const {FsSavedScriptsStore}=await import('../third-party/executor-mcp/tools.mjs');
 const temp=await mkdtemp(join(tmpdir(),'dex-playbooks-'));
 t.after(()=>rm(temp,{recursive:true,force:true}));
 const first=randomUUID(),second=randomUUID();
 const sessions=[{sessionId:first,connected:true,info:{displayName:'First',userId:1}},{sessionId:second,connected:true,info:{displayName:'Second',userId:2}}];
 const broker={
  summaries:()=>sessions,
  resolve(id){return {id,grants:{inspect:true,execute:true,edit:false}};},
  async execute(name,args){
   assert.equal(name,'dex_run_luau');
   assert.equal(args.sessionId,second);
   return {state:'completed',result:{status:'completed',returns:[JSON.stringify({value:[
    {path:'Workspace.Inventory',text:'inventory equip backpack'},
    {path:'Workspace.Clouds',text:'weather lightning sky'},
   ]})]}};
  },
 };
 const catalog=new Map();
 const host=registerImportedTools((name,description,inputSchema,grant,callback,category)=>{
  catalog.set(name,{name,description,inputSchema,grant,callback,category});
 },broker,catalog,{playbooks:new FsSavedScriptsStore(temp)});
 t.after(()=>host.close());
 const ctx={mcpReq:{signal:new AbortController().signal}};
 const call=async(name,args={})=>{
  const entry=catalog.get('dex_'+name);
  const output=await entry.callback(entry.inputSchema.parse(args),ctx);
  assert.notEqual(output.state,'failed',JSON.stringify(output));
  return output.result;
 };
 assert.equal((await call('get_active_client')).resolution.status,'ambiguous');
 assert.equal((await call('select_client',{clientId:second})).resolution.client.clientId,second);
 assert.equal(broker.defaultSessionId,second);
 const selected=await call('get_active_client');
 assert.equal(selected.resolution.client.clientId,second);
 await call('playbook_save',{name:'smoke',source:'return 10',tags:['qa']});
 assert.equal((await call('playbook_list',{tag:'qa'})).playbooks[0].name,'smoke');
 await call('playbook_delete',{name:'smoke'});
 assert.equal((await call('playbook_list')).total,0);
 await call('agent_memory',{operation:'remember',key:'smoke',text:'Checked fixture'});
 await call('agent_memory',{operation:'recall'});
 await call('agent_memory',{operation:'forget',key:'smoke'});
 const search=await call('semantic_search_scripts',{query:'inventory equip',limit:1});
 assert.equal(search.hits[0].path,'Workspace.Inventory');
 assert.equal(search.model,'local-hash');
 const stats=await call('get_semantic_index_stats');
 assert.equal(stats.documentCount,2);
 await call('clear_semantic_index');
 assert.equal((await call('get_semantic_index_stats')).documentCount,0);
 await call('tool_plan',{goal:'find an actor'});
 await call('tool_quality_audit',{limit:4});
 await call('agent_context',{includeGameInfo:false,includeExecutorInfo:false,includeCapabilities:false});
 const dryRun=await call('agent_run',{goal:'inspect actor',steps:[{id:'actors',tool:'dex_list_actors'}],dryRun:true});
 assert.equal(dryRun.status,'dry-run');
 const trace=await call('session_show',{sessionId:second});
 assert.deepEqual(trace.records,[]);
 host.trace('dex_list_actors',{sessionId:second},{state:'completed'},Date.now());
 host.trace('dex_send_packet',{sessionId:second},{state:'completed'},Date.now());
 const replay=await call('session_replay',{sessionId:second});
 assert.equal(replay.mode,'plan');
 assert.deepEqual(replay.steps.map(step=>step.tool),['dex_list_actors']);
 const withMutations=await call('session_replay',{sessionId:second,includeMutating:true});
 assert.deepEqual(withMutations.steps.map(({tool,wouldRun,blockedByDefault})=>[tool,wouldRun,blockedByDefault]),[
  ['dex_list_actors',true,undefined],
  ['dex_send_packet',true,true],
 ]);
 await call('clear_selection');
 assert.equal(broker.defaultSessionId,undefined);
 assert.equal((await call('get_active_client')).resolution.status,'ambiguous');
});

import test from 'node:test';
import assert from 'node:assert/strict';
import {once} from 'node:events';
import {request as httpRequest} from 'node:http';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {randomUUID} from 'node:crypto';
import {WebSocket} from 'ws';
import {Client} from '@modelcontextprotocol/client';
import {StdioClientTransport} from '@modelcontextprotocol/client/stdio';
import {Broker} from '../src/broker.mjs';
import {registerImportedTools} from '../src/imported-tools.mjs';
import {TOOLS,validateArgs} from '../src/protocol.mjs';

const grants={inspect:true,edit:false,execute:false};
async function register(broker,levels=grants){
 const pair=broker.createPairing(),code=pair.pairingCode.split('.').slice(1).join('.');
 const response=await fetch(broker.url+'/bridge/sessions',{method:'POST',headers:{Authorization:'Bearer '+code,'Content-Type':'application/json'},body:JSON.stringify({grants:levels,info:{placeId:123,userId:456,displayName:'Test'}})});
 assert.equal(response.status,201);return {pair,code,...await response.json()};
}
async function connect(url,session,reply,features={}){
 const ticket=await (await fetch(url+'/bridge/ticket',{method:'POST',headers:{Authorization:'Bearer '+session.agentToken}})).json();
 const socket=new WebSocket(url.replace('http:','ws:')+'/bridge/ws?ticket='+ticket.ticket,{origin:'http://native-executor'});
 const commands=[],messages=[];let readyResolve;const ready=new Promise(r=>{readyResolve=r;});
 socket.on('message',data=>{const message=JSON.parse(data);messages.push(message);if(message.type==='ready')readyResolve(message);if(message.type==='ping')socket.send(JSON.stringify({type:'pong'}));if(message.type==='command'){commands.push(message);reply?.(message,socket);}});
 await once(socket,'open');socket.send(JSON.stringify({type:'hello',version:1,sessionId:session.sessionId,token:session.agentToken,capabilities:{commands:TOOLS.map(t=>({name:t.name,grant:t.grant}))},...features}));
 return {ready:await ready,socket,commands,messages};
}
const answer=(command,socket)=>socket.send(JSON.stringify({type:'result',id:command.id,ok:true,result:{name:command.name,values:[false,{type:'nil'},0]}}));
async function raw(url,headers={},path){return new Promise((resolve,reject)=>{const r=httpRequest(url,{headers,...(path===undefined?{}:{path})},res=>{let body='';res.on('data',v=>body+=v);res.on('end',()=>resolve({status:res.statusCode,body}));});r.on('error',reject);r.end();});}
async function rejectedUpgrade(url,options={}){return new Promise((resolve,reject)=>{const socket=new WebSocket(url,options);socket.on('error',()=>{});socket.on('open',()=>{socket.terminate();reject(Error('Unexpected successful upgrade'));});socket.on('unexpected-response',(_request,response)=>{response.resume();socket.terminate();resolve(response.statusCode);});});}

test('single-use pairing, expiry, grants, exact loopback Host/Origin, no secret health data',async t=>{
 let clock=Date.now();const broker=await new Broker({clock:()=>clock}).start({port:0});t.after(()=>broker.close());
 const health=await (await fetch(broker.url+'/health')).json();assert.deepEqual(health,{service:'dex-plus-bridge',protocol:1});
 assert.equal((await raw(broker.url+'/health',{Host:'evil.example'})).status,403);
 assert.equal((await raw(broker.url+'/health',{Origin:'https://evil.example'})).status,403);
 const session=await register(broker);
 const replay=await fetch(broker.url+'/bridge/sessions',{method:'POST',headers:{Authorization:'Bearer '+session.code},body:'{}'});assert.equal(replay.status,401);
 assert.equal((await fetch(broker.url+'/bridge/session')).status,401);
 assert.ok(!JSON.stringify(broker.summaries()).includes(session.agentToken));
 const late=broker.createPairing();clock+=120001;
 const response=await fetch(broker.url+'/bridge/sessions',{method:'POST',headers:{Authorization:'Bearer '+late.pairingCode.split('.').slice(1).join('.')},body:'{}'});assert.equal(response.status,401);
});

test('exact session routing, permission checks, typed result fidelity and no automatic duplicate execution',async t=>{
 const broker=await new Broker().start({port:0});t.after(()=>broker.close());
 const session=await register(broker,{inspect:true,edit:true,execute:false});const peer=await connect(broker.url,session,answer);
 const commandId=randomUUID(),args={sessionId:session.sessionId,commandId};
 const first=await broker.execute('dex_get_selection',args),second=await broker.execute('dex_get_selection',args);
 assert.deepEqual(first.result.values,[false,{type:'nil'},0]);assert.deepEqual(second,first);assert.equal(peer.commands.length,1);
 await assert.rejects(broker.execute('dex_get_instance',{...args,instanceId:'different'}),e=>e.code==='command_conflict');
 await assert.rejects(broker.execute('dex_run_luau',{sessionId:session.sessionId,source:'return 1'}),e=>e.code==='permission_denied');
 const other=await register(broker);await assert.rejects(broker.execute('dex_get_selection',{}),e=>e.code==='session_required');
 assert.throws(()=>validateArgs('dex_get_selection',{sessionId:other.sessionId},session.sessionId),e=>e.code==='wrong_session');
 assert.equal(peer.commands.length,1);
});

test('a concurrent registration cannot spend a one-time pairing code twice',async t=>{
 const broker=await new Broker().start({port:0});t.after(()=>broker.close());
 const pairing=broker.createPairing(),secret=pairing.pairingCode.split('.').slice(1).join('.');
 const options={method:'POST',headers:{Authorization:'Bearer '+secret,'Content-Type':'application/json'},body:JSON.stringify({grants,info:{}})};
 const responses=await Promise.all([fetch(broker.url+'/bridge/sessions',options),fetch(broker.url+'/bridge/sessions',options)]);
 assert.deepEqual(responses.map(r=>r.status).sort(),[201,401]);assert.equal(broker.summaries().length,1);
});

test('private MCP diagnostics classify upgrades without exposing credentials, URLs or headers',async t=>{
 const broker=await new Broker().start({port:0});t.after(()=>broker.close());
 const session=await register(broker),url=broker.url.replace('http:','ws:')+'/bridge/ws';
 assert.equal(await rejectedUpgrade(url,{headers:{Host:'secret-host.example'}}),403);
 assert.equal(await rejectedUpgrade(url,{origin:'https://secret-origin.example/?token=sensitive'}),403);
 assert.equal(await rejectedUpgrade(url+'?token=secret-query'),403);
 const diagnostics=broker.getDiagnostics();
 assert.equal(diagnostics.upgradeAttempts,3);assert.equal(diagnostics.rejectedHost,1);assert.equal(diagnostics.rejectedOrigin,0);assert.equal(diagnostics.rejectedPath,0);assert.equal(diagnostics.pendingConnections,0);assert.equal(diagnostics.registrations,1);assert.equal(diagnostics.lastIssue.code,'upgrade_ticket_rejected');
 const exposed=JSON.stringify(diagnostics);for(const secret of [session.agentToken,session.code,'secret-host','secret-origin','secret-query','sensitive'])assert.ok(!exposed.includes(secret));
 const pendingTicket=await (await fetch(broker.url+'/bridge/ticket',{method:'POST',headers:{Authorization:'Bearer '+session.agentToken}})).json();
 const pending=new WebSocket(url+'?ticket='+pendingTicket.ticket);pending.on('error',()=>{});await once(pending,'open');assert.equal(broker.getDiagnostics().pendingConnections,1);pending.terminate();await new Promise(r=>setTimeout(r,5));
 const peer=await connect(broker.url,session,answer);assert.equal(broker.getDiagnostics().authenticatedConnections,1);assert.equal(broker.getDiagnostics().activeConnections,1);assert.equal(broker.getDiagnostics().pendingConnections,0);peer.socket.terminate();
 assert.equal((await raw(broker.url+'/bridge/ws')).status,404);assert.equal(broker.getDiagnostics().plainWebSocketRequests,1);
 const malformedTicket=await (await fetch(broker.url+'/bridge/ticket',{method:'POST',headers:{Authorization:'Bearer '+session.agentToken}})).json();
 const malformed=await raw(broker.url+'/bridge/ws?ticket='+malformedTicket.ticket,{Connection:'Upgrade',Upgrade:'websocket','Sec-WebSocket-Key':'invalid','Sec-WebSocket-Version':'13'});assert.equal(malformed.status,400);assert.equal(broker.getDiagnostics().rejectedProtocol,1);assert.equal(broker.getDiagnostics().lastIssue.code,'upgrade_protocol_rejected');
 const health=await (await fetch(broker.url+'/health')).json();assert.equal(health.diagnostics,undefined);
});

test('malformed upgrade targets leave the local MCP server running',async t=>{
 const broker=await new Broker().start({port:0});t.after(()=>broker.close());
 const response=await raw(broker.url,{Connection:'Upgrade',Upgrade:'websocket'},'//[');
 assert.equal(response.status,400);
 assert.equal(broker.getDiagnostics().lastIssue.code,'upgrade_protocol_rejected');
 assert.equal((await raw(broker.url+'/health')).status,200);
});

test('disconnect yields unknown outcome, cancels queued edits and does not replay to reconnect',async t=>{
 const broker=await new Broker().start({port:0});t.after(()=>broker.close());const session=await register(broker,{inspect:true,edit:true,execute:false});const peer=await connect(broker.url,session);
 const one=broker.execute('dex_set_properties',{sessionId:session.sessionId,instanceIds:['p'],properties:{Name:'Edited'}});
 const two=broker.execute('dex_get_selection',{sessionId:session.sessionId});
 await new Promise(r=>setTimeout(r,10));assert.equal(peer.commands.length,1);peer.socket.terminate();
 assert.equal((await one).state,'outcome_unknown');assert.equal((await two).state,'cancelled');
 const next=await connect(broker.url,session,answer);await new Promise(r=>setTimeout(r,10));assert.equal(next.commands.length,0);
});

test('grant revocation cancels queued mutation and history schema requires revision head',async t=>{
 const broker=await new Broker().start({port:0});t.after(()=>broker.close());const session=await register(broker,{inspect:true,edit:true,execute:false});const peer=await connect(broker.url,session);
 const one=broker.execute('dex_get_selection',{sessionId:session.sessionId});const two=broker.execute('dex_delete_instances',{sessionId:session.sessionId,instanceIds:['p']});
 const response=await fetch(broker.url+'/bridge/session',{method:'PATCH',headers:{Authorization:'Bearer '+session.agentToken,'Content-Type':'application/json'},body:JSON.stringify({grants})});assert.equal(response.status,200);
 assert.equal((await two).state,'cancelled');
 peer.socket.send(JSON.stringify({type:'result',id:peer.commands[0].id,ok:true,result:{selected:[]}}));await one;assert.equal(peer.commands.length,1);
 assert.throws(()=>validateArgs('dex_undo',{expectedIndex:100},session.sessionId),e=>e.code==='invalid_arguments');
});

test('claimed deadline blocks subsequent sends until late result resolves uncertainty',async t=>{
 const broker=await new Broker({commandMs:45}).start({port:0});t.after(()=>broker.close());const session=await register(broker);const peer=await connect(broker.url,session);
 const first=await broker.execute('dex_get_selection',{sessionId:session.sessionId});assert.equal(first.state,'outcome_unknown');
 await assert.rejects(broker.execute('dex_get_selection',{sessionId:session.sessionId}),e=>e.code==='outcome_unknown');
 peer.socket.send(JSON.stringify({type:'result',id:first.commandId,ok:true,result:{late:true}}));await new Promise(r=>setTimeout(r,10));
 assert.equal(broker.getCommand(session.sessionId,first.commandId).state,'completed');assert.equal(broker.summaries()[0].blocked,false);
});

test('official MCP client exercises stdio -> pairing HTTP -> WebSocket -> typed tool result',async t=>{
 const entry=fileURLToPath(new URL('../dist/dex-mcp.mjs',import.meta.url));
 const transport=new StdioClientTransport({command:process.execPath,args:[entry],stderr:'pipe'});const client=new Client({name:'dex-bridge-test',version:'1.0.0'});t.after(()=>client.close());
 await client.connect(transport);
 const listed=await client.listTools();assert.ok(listed.tools.some(t=>t.name==='dex_create_pairing'));assert.ok(listed.tools.some(t=>t.name==='dex_set_properties'));assert.equal(listed.tools.length,361);assert.ok(listed.tools.some(t=>t.name==='dex_find_references'));assert.ok(listed.tools.some(t=>t.name==='dex_watch_instance'));assert.ok(listed.tools.some(t=>t.name==='dex_export_capture'));assert.ok(listed.tools.some(t=>t.name==='dex_capture_system'));
 const listedNames=new Set(listed.tools.map(tool=>tool.name));
 assert.equal(listedNames.size,361);
 for(const name of ['dex_script','dex_script_fanout','dex_playbook_run','dex_session_replay','dex_semantic_search_scripts','dex_smart_task','dex_teach_mode','dex_assert_state'])assert.ok(listedNames.has(name),name);
 for(const name of ['dex_ensure_remote_spy','dex_remote_spy','dex_configure_remote_spy','dex_block_remote','dex_ignore_remote','dex_get_remote_spy_logs','dex_clear_remote_spy_logs'])assert.ok(!listedNames.has(name),name);
 const logTool=listed.tools.find(t=>t.name==='dex_get_logs'),clearTool=listed.tools.find(t=>t.name==='dex_clear_logs');
 assert.ok(logTool);assert.ok(clearTool);assert.equal(logTool.annotations.readOnlyHint,true);assert.equal(clearTool.annotations.readOnlyHint,false);
 assert.equal(clearTool.annotations.idempotentHint,false);
 const pairing=(await client.callTool({name:'dex_create_pairing',arguments:{}})).structuredContent;
 const diagnosticResult=(await client.callTool({name:'dex_list_sessions',arguments:{}})).structuredContent;assert.equal(diagnosticResult.diagnostics.upgradeAttempts,0);assert.equal(diagnosticResult.diagnostics.pendingConnections,0);
 const [port,code]=pairing.pairingCode.split('.');const url=`http://127.0.0.1:${port}`;
 const session=await (await fetch(url+'/bridge/sessions',{method:'POST',headers:{Authorization:'Bearer '+code,'Content-Type':'application/json'},body:JSON.stringify({grants,info:{placeId:123}})})).json();
 const peer=await connect(url,session,(command,socket)=>{
  if(command.name!=='dex_get_instance')return answer(command,socket);
  const error=command.args.instanceId==='stale'
   ?{code:'STALE_INSTANCE',message:'Stale instance handle'}
   :'Legacy failure';
  socket.send(JSON.stringify({type:'result',id:command.id,ok:false,error}));
 });t.after(()=>peer.socket.terminate());
 const result=await client.callTool({name:'dex_get_selection',arguments:{sessionId:session.sessionId}});
 assert.equal(result.isError,undefined);assert.deepEqual(result.structuredContent.result.values,[false,{type:'nil'},0]);
 const failed=await client.callTool({name:'dex_get_instance',arguments:{sessionId:session.sessionId,instanceId:'stale'}});
 assert.equal(failed.isError,true);
 assert.equal(failed.structuredContent.state,'failed');
 assert.deepEqual(failed.structuredContent.error,{code:'stale_instance',message:'Stale instance handle'});
 const legacy=await client.callTool({name:'dex_get_instance',arguments:{sessionId:session.sessionId,instanceId:'legacy'}});
 assert.deepEqual(legacy.structuredContent.error,{code:'dex_error',message:'Legacy failure'});
 const denied=await client.callTool({name:'dex_delete_instances',arguments:{sessionId:session.sessionId,instanceIds:['p']}});assert.equal(denied.isError,true);assert.equal(denied.structuredContent.error.code,'permission_denied');
 const remoteDenied=await client.callTool({name:'dex_fire_remote',arguments:{sessionId:session.sessionId,instanceId:'p',arguments:[false,{type:'nil'}]}});assert.equal(remoteDenied.isError,true);assert.equal(remoteDenied.structuredContent.error.code,'permission_denied');
 assert.equal(peer.commands.length,3);
});

test('Dex MCP advertises every command and records blocked and completed calls without leaking credentials',async t=>{
 const entry=fileURLToPath(new URL('../dist/dex-mcp.mjs',import.meta.url));
 const transport=new StdioClientTransport({command:process.execPath,args:[entry],stderr:'pipe'});
 const client=new Client({name:'dex-policy-test',version:'1.0.0'});
 t.after(()=>client.close());
 await client.connect(transport);
 const call=async(name,args={})=>(await client.callTool({name,arguments:args})).structuredContent;
 const pairing=(await call('dex_create_pairing')).pairingCode;
 const [port,code]=pairing.split('.');
 const url='http://127.0.0.1:'+port;
 const session=await (await fetch(url+'/bridge/sessions',{method:'POST',headers:{Authorization:'Bearer '+code,'Content-Type':'application/json'},body:JSON.stringify({grants,info:{}})})).json();
 const peer=await connect(url,session,(command,socket)=>socket.send(JSON.stringify({
  type:'result',id:command.id,ok:true,result:{value:false,password:'private-test-value'},
 })),{toolControls:true,disabledTools:['dex_capture_screenshot','dex_tool_plan']});
 t.after(()=>peer.socket.terminate());
 const names=(await client.listTools()).tools.map(tool=>tool.name).sort();
 assert.deepEqual(peer.ready.tools.map(tool=>tool.name).sort(),names);
 const scope={sessionId:session.sessionId};
 assert.equal((await call('dex_capture_screenshot',scope)).error.code,'command_disabled');
 assert.equal((await call('dex_tool_plan',{...scope,goal:'show actors'})).error.code,'command_disabled');
 assert.equal((await call('dex_get_selection',scope)).result.value,false);
 const ack=once(peer.socket,'message');
 peer.socket.send(JSON.stringify({type:'tool_policy',revision:1,disabledTools:['dex_get_selection']}));
 assert.deepEqual(JSON.parse((await ack)[0]),{type:'tool_policy_ack',revision:1});
 assert.equal((await call('dex_get_selection',scope)).error.code,'command_disabled');
 const clear=once(peer.socket,'message');
 peer.socket.send(JSON.stringify({type:'tool_policy',revision:2,disabledTools:[]}));
 await clear;
 assert.equal((await call('dex_get_selection',scope)).state,'completed');
 assert.equal(peer.commands.length,2);
 const paused=once(peer.socket,'message');
 peer.socket.send(JSON.stringify({type:'tool_policy',revision:3,disabledTools:[],paused:true}));
 assert.deepEqual(JSON.parse((await paused)[0]),{type:'tool_policy_ack',revision:3});
 assert.equal((await call('dex_tool_plan',{...scope,goal:'show actors'})).error.code,'bridge_paused');
 assert.equal((await call('dex_get_selection',scope)).error.code,'bridge_paused');
 assert.equal((await call('dex_list_sessions')).sessions.length,1);
 const resumed=once(peer.socket,'message');
 peer.socket.send(JSON.stringify({type:'tool_policy',revision:4,disabledTools:[],paused:false}));
 await resumed;
 assert.equal((await call('dex_get_selection',scope)).state,'completed');
 await new Promise(resolve=>setTimeout(resolve,20));
 const activity=peer.messages.filter(message=>message.type==='tool_activity');
 assert.ok(activity.some(message=>message.name==='dex_capture_screenshot'&&message.state==='blocked'));
 const completed=activity.find(message=>message.name==='dex_get_selection'&&message.state==='completed');
 assert.ok(activity.some(message=>message.id===completed.id&&message.state==='running'));
 assert.equal(JSON.parse(completed.result).result.value,false);
 assert.equal(JSON.parse(completed.result).result.password,'[redacted]');
 assert.ok(!JSON.stringify(activity).includes('private-test-value'));
});

test('policy updates cancel queued commands and preserve per-session settings across reconnect',async t=>{
 const broker=await new Broker().start({port:0});
 t.after(()=>broker.close());
 const session=await register(broker);
 const peer=await connect(broker.url,session,undefined,{toolControls:true});
 const scope={sessionId:session.sessionId};
 const claimed=broker.execute('dex_get_session',scope);
 const queued=broker.execute('dex_get_selection',scope);
 peer.socket.send(JSON.stringify({type:'tool_policy',revision:1,disabledTools:['dex_get_selection']}));
 assert.equal((await queued).error.code,'command_disabled');
 const other=await register(broker);
 const otherPeer=await connect(broker.url,other,answer,{toolControls:true});
 assert.equal((await broker.execute('dex_get_selection',{sessionId:other.sessionId})).state,'completed');
 const closed=once(peer.socket,'close');
 peer.socket.terminate();
 await closed;
 await claimed;
 const reconnected=await connect(broker.url,session,answer,{toolControls:true,disabledTools:['dex_get_selection']});
 await assert.rejects(broker.execute('dex_get_selection',scope),{code:'command_disabled'});
 assert.equal(reconnected.commands.length,0);
 otherPeer.socket.terminate();
});

test('stdio EOF exits promptly without an orphan broker',async()=>{
 const entry=fileURLToPath(new URL('../dist/dex-mcp.mjs',import.meta.url));const child=spawn(process.execPath,[entry],{stdio:['pipe','pipe','pipe'],windowsHide:true});
 let stderr='';child.stderr.on('data',d=>stderr+=d);await new Promise((resolve,reject)=>{const end=Date.now()+5000;const poll=()=>{if(stderr.includes('Ready.'))resolve();else if(Date.now()>end)reject(Error('Bridge did not start'));else setTimeout(poll,10);};poll();});
 child.stdin.end();const exit=await Promise.race([once(child,'exit'),new Promise((_,reject)=>setTimeout(()=>{child.kill();reject(Error('Broker survived stdin EOF'));},3000).unref())]);assert.equal(exit[0],0);
});

 test('WebSocket tickets are authenticated, session-bound, one-use and expire',async t=>{
  let clock=Date.now();const broker=await new Broker({clock:()=>clock}).start({port:0});t.after(()=>broker.close());
  const a=await register(broker),b=await register(broker);
  const mint=async session=>await (await fetch(broker.url+'/bridge/ticket',{method:'POST',headers:{Authorization:'Bearer '+session.agentToken}})).json();
  assert.equal((await fetch(broker.url+'/bridge/ticket',{method:'POST'})).status,401);
  assert.equal((await fetch(broker.url+'/bridge/ticket',{method:'POST',headers:{Authorization:'Bearer '+a.agentToken,Origin:'https://evil.test'}})).status,403);
  const old=await mint(a);clock+=20001;
  assert.equal(await rejectedUpgrade(broker.url.replace('http:','ws:')+'/bridge/ws?ticket='+old.ticket,{origin:'http://native-executor'}),403);
  const ticket=await mint(a),url=broker.url.replace('http:','ws:')+'/bridge/ws?ticket='+ticket.ticket;
  const socket=new WebSocket(url,{origin:'http://native-executor'});await once(socket,'open');
  const response=once(socket,'message');socket.send(JSON.stringify({type:'hello',version:1,sessionId:b.sessionId,token:b.agentToken,capabilities:{commands:[]}}));
  assert.equal(JSON.parse((await response)[0]).error.code,'wrong_ticket');socket.terminate();
  assert.equal(await rejectedUpgrade(url),403);
 });


test('script callback is scoped to one paired client, checks grants, and expires with the script',async t=>{
 const broker=await new Broker().start({port:0});
 t.after(()=>broker.close());
 const owner=await register(broker,{inspect:true,edit:false,execute:true});
 const other=await register(broker,{inspect:true,edit:true,execute:true});
 const catalog=new Map();
 const registered=new Map();
 catalog.set('dex_get_selection',{name:'dex_get_selection',grant:'inspect',inputSchema:TOOLS.find(tool=>tool.name==='dex_get_selection').schema,callback:args=>broker.execute('dex_get_selection',args)});
 catalog.set('dex_set_properties',{name:'dex_set_properties',grant:'edit',inputSchema:TOOLS.find(tool=>tool.name==='dex_set_properties').schema,callback:args=>broker.execute('dex_set_properties',args)});
 const host=registerImportedTools((name,description,inputSchema,grant,callback)=>{
  registered.set(name,{inputSchema,callback});
  catalog.set(name,{name,description,inputSchema,grant,callback});
 },broker,catalog,{playbooks:{}});
 t.after(()=>host.close());
 let token, runArgs;
 const ready=await connect(broker.url,owner,(command,socket)=>{
  if(command.name==='dex_run_luau'){
   runArgs=command.args;
   token=command.args.source.match(/Bearer ([a-z0-9-]{72})/i)?.[1];
   socket.send(JSON.stringify({type:'result',id:command.id,ok:true,result:{runId:'r1',status:'running'}}));
  }else if(command.name==='dex_get_run'){
   socket.send(JSON.stringify({type:'result',id:command.id,ok:true,result:runDone?{runId:'r1',status:'completed',returns:['{"value":7}']}:{runId:'r1',status:'running'}}));
  }else answer(command,socket);
 });
 const second=await connect(broker.url,other,answer);
 const rpc=(key,name,args)=>fetch(broker.url+'/bridge/script-call',{
  method:'POST',headers:{Authorization:'Bearer '+key,'Content-Type':'application/json'},body:JSON.stringify({name,args}),
 });
 let runDone=false;
 const script=registered.get('dex_script');
 const input=script.inputSchema.parse({source:'return mcp.call("dex_get_selection"), mcp.help("get-selection"), mcp.all({}), mcp.parallel({})',sessionId:owner.sessionId});
 const run=script.callback(input,{mcpReq:{signal:new AbortController().signal}});
 for(let i=0;!token&&i<30;i++)await new Promise(resolve=>setTimeout(resolve,10));
 assert.ok(token);
 assert.equal(runArgs.vm,'persistent');
 assert.equal((await rpc('x'.repeat(72),'get-selection',{})).status,403);
 assert.equal((await rpc(token,'get-selection',{sessionId:other.sessionId})).status,403);
 assert.equal((await rpc(token,'dex_set_properties',{instanceIds:['i1'],properties:{Name:'bad'}})).status,403);
 const nested=await (await rpc(token,'dex_get_selection')).json();
 assert.equal(nested.ok,true);
 assert.equal(nested.data.name,'dex_get_selection');
 broker.setToolPolicy(broker.resolve(owner.sessionId),['dex_get_selection']);
 const blocked=await rpc(token,'dex_get_selection');
 assert.equal(blocked.status,403);
 assert.equal((await blocked.json()).error.code,'command_disabled');
 assert.equal(second.commands.length,0);
 assert.ok(ready.commands.some(command=>command.name==='dex_get_selection'));
 runDone=true;
 assert.equal((await run).result.result,7);
 assert.equal((await rpc(token,'get-selection',{})).status,403);
});

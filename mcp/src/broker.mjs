import {createServer} from 'node:http';
import {randomUUID,timingSafeEqual} from 'node:crypto';
import {WebSocketServer,WebSocket} from 'ws';
import {BridgeError,LIMITS,VERSION,bearer,digest,token,grantsSchema,registrationSchema,validateArgs,validateJson,json,readJson,fail,toolByName} from './protocol.mjs';

const terminal=new Set(['completed','failed','cancelled','outcome_unknown']);
const pauseExempt=new Set(['dex_create_pairing','dex_list_sessions','dex_get_command']);
const closeError={code:'outcome_unknown',message:'Dex disconnected after dispatch; this action may have executed. Do not replay it automatically.'};
const sameHash=(a,b)=>timingSafeEqual(Buffer.from(a),Buffer.from(b));

function resultError(error) {
 const reportedCode=error?.code;
 const code=typeof reportedCode==='string'&&/^[a-z][a-z0-9_]{0,63}$/i.test(reportedCode)
  ?reportedCode.toLowerCase():'dex_error';
 const detail=typeof error==='object'?error?.message||reportedCode:error;
 return {code:code==='paused'?'bridge_paused':code,message:String(detail||'Dex command failed').slice(0,2000)};
}

// One trusted stdio host owns this loopback broker. There is no background
// daemon, database, cloud relay, persistent credential or session auto-replay.
export class Broker {
 constructor(options={}){
  this.clock=options.clock||Date.now;this.commandMs=options.commandMs||LIMITS.commandMs;
  this.tickets=new Map();this.sessions=new Map();this.pairings=new Map();this.sockets=new Set();this.closed=false;
  this.registrationAttempts=[];
  this.pendingSockets=new Set();
  this.rawSockets=new Set();this.ownedSockets=new WeakSet();
  this.diagnostics={upgradeAttempts:0,rejectedHost:0,rejectedOrigin:0,rejectedPath:0,rejectedCapacity:0,rejectedProtocol:0,acceptedUpgrades:0,authenticatedConnections:0,failedHellos:0,httpRequests:0,plainWebSocketRequests:0,registrations:0,socketErrors:0,httpClientErrors:0,lastIssue:null};
  this.server=createServer((req,res)=>{void this.http(req,res);});
  // HTTP removes its parser/error ownership when upgrading a connection. Own
  // every raw socket from connection onward, including rejected upgrades, so
  // an abrupt peer reset cannot become an unhandled EventEmitter error.
  this.server.on('connection',socket=>this.ownSocket(socket));
  this.server.on('clientError',(_error,socket)=>{this.diagnostics.httpClientErrors++;this.issue('http_protocol_rejected');this.rejectRaw(socket,400);});
  this.server.requestTimeout=10000;this.server.headersTimeout=10000;
  this.wss=new WebSocketServer({noServer:true,maxPayload:LIMITS.result,perMessageDeflate:false});
  this.wss.on('wsClientError',(_error,socket)=>{this.diagnostics.rejectedProtocol++;this.issue('upgrade_protocol_rejected');this.rejectRaw(socket,400);});
  this.server.on('upgrade',(req,socket,head)=>{
   this.ownSocket(socket);
   this.diagnostics.upgradeAttempts++;
   if(req.headers.host!==`127.0.0.1:${this.port}`){
    this.diagnostics.rejectedHost++;this.issue('upgrade_host_rejected');this.rejectRaw(socket,403);return;
   }
   let endpoint;
   try{endpoint=new URL(req.url,this.url);}catch{
    this.diagnostics.rejectedProtocol++;this.issue('upgrade_protocol_rejected');this.rejectRaw(socket,400);return;
   }
   if(endpoint.pathname!=='/bridge/ws'){
    this.diagnostics.rejectedPath++;this.issue('upgrade_path_rejected');this.rejectRaw(socket,403);return;
   }
   if(this.sockets.size>=LIMITS.sessions+4){
    this.diagnostics.rejectedCapacity++;this.issue('upgrade_capacity_rejected');this.rejectRaw(socket,403);return;
   }
   const secret=endpoint.searchParams.get('ticket');
   const key=secret&&digest(secret),ticket=key&&this.tickets.get(key);
   if(!ticket||ticket.expiresAt<=this.clock()) {this.issue('upgrade_ticket_rejected');this.rejectRaw(socket,403);return;}
   this.tickets.delete(key);
   let owner;try{owner=this.resolve(ticket.sessionId);}catch{this.rejectRaw(socket,403);return;}
   this.wss.handleUpgrade(req,socket,head,ws=>this.attach(ws,owner.id));
  });
 }
 ownSocket(socket){
  if(this.ownedSockets.has(socket))return;
  this.ownedSockets.add(socket);this.rawSockets.add(socket);
  socket.on('error',()=>{this.diagnostics.socketErrors++;this.issue('socket_error');socket.destroy();});
  socket.once('close',()=>this.rawSockets.delete(socket));
 }
 rejectRaw(socket,status){
  this.ownSocket(socket);
  if(socket.destroyed||!socket.writable){socket.destroy();return;}
  // Do not wait indefinitely for a rejected peer to consume a response.
  socket.setTimeout(1000,()=>socket.destroy());
  socket.end(`HTTP/1.1 ${status} ${status===403?'Forbidden':'Bad Request'}\r\nConnection: close\r\nContent-Length: 0\r\n\r\n`,()=>socket.destroy());
 }
 issue(code){this.diagnostics.lastIssue={code,time:new Date(this.clock()).toISOString()};}
 getDiagnostics(){return {...this.diagnostics,pendingConnections:this.pendingSockets.size,activeConnections:this.sockets.size-this.pendingSockets.size};}
 validOrigin(req){return req.headers.host===`127.0.0.1:${this.port}`&&!req.headers.origin;}
 async start({port=37429,lastPort=37449}={}){
  for(let candidate=port;candidate<=(port===0?0:lastPort);candidate++){
   try{
    await new Promise((resolve,reject)=>{
     const bad=e=>{this.server.off('listening',good);reject(e);};
     const good=()=>{this.server.off('error',bad);resolve();};
     this.server.once('error',bad);this.server.once('listening',good);this.server.listen(candidate,'127.0.0.1');
    });
    this.port=this.server.address().port;this.url=`http://127.0.0.1:${this.port}`;return this;
   }catch(error){if(error.code!=='EADDRINUSE'||candidate===(port===0?0:lastPort))throw error;}
  }
 }
 createPairing(){
  if(this.closed)fail('closed','Bridge is shutting down',503);
  for(const [key,pair]of this.pairings)if(pair.expiresAt<=this.clock())this.pairings.delete(key);
  if(this.pairings.size>=8)this.pairings.delete(this.pairings.keys().next().value);
  const secret=token('dxpair_'),expiresAt=this.clock()+120000;
  this.pairings.set(digest(secret),{expiresAt});
  return {pairingCode:`${this.port}.${secret}`,expiresAt:new Date(expiresAt).toISOString(),instructions:'Paste this one-time code into Dex > Dex MCP, then choose permissions in Dex. The code pairs only with this AI host.'};
 }
 summary(s){return {sessionId:s.id,info:s.info,grants:s.grants,connected:!!s.socket,blocked:!!s.blocked,expiresAt:new Date(s.expiresAt).toISOString(),connectedAt:s.connectedAt,capabilities:s.capabilities};}
 summaries(){return [...this.sessions.values()].filter(s=>!s.revoked&&s.expiresAt>this.clock()).map(s=>this.summary(s));}
 policyTargets(args={}){
  const sessions=[...this.sessions.values()].filter(s=>!s.revoked&&s.expiresAt>this.clock());
  const ids=[args.targetSessionId,args.sessionId,args.clientId,args.client].filter(id=>typeof id==='string');
  if(ids.length){
   return sessions.filter(s=>ids.some(id=>s.id===id||[s.info?.username,s.info?.displayName].some(name=>name?.toLowerCase()===id.toLowerCase())));
  }
  if(this.defaultSessionId){
   const selected=sessions.find(s=>s.id===(this.resolveDefaultSession?.()||this.defaultSessionId));
   if(selected)return [selected];
  }
  return sessions;
 }
 assertToolEnabled(name,sessions){
  if(sessions.some(s=>s.disabledTools?.has(name)))fail('command_disabled',name+' is disabled in Dex MCP',403);
  if(!pauseExempt.has(name)&&sessions.some(s=>s.paused))fail('bridge_paused','Dex MCP is paused in Dex',403);
 }
 setToolPolicy(session,names,paused=false){
  if(!Array.isArray(names)||names.length>512||names.some(name=>typeof name!=='string'||!/^dex_[a-z0-9_]{1,100}$/.test(name)))fail('invalid_tool_policy','Invalid Dex command settings');
  if(typeof paused!=='boolean')fail('invalid_tool_policy','Invalid Dex pause state');
  session.disabledTools=new Set(names);
  session.paused=paused;
  for(const command of session.queue){
   if(command.state!=='queued')continue;
   if(session.disabledTools.has(command.name))this.finish(session,command,'cancelled',null,{code:'command_disabled',message:'Command was disabled before dispatch'});
   else if(paused)this.finish(session,command,'cancelled',null,{code:'bridge_paused',message:'Dex MCP was paused before dispatch'});
  }
  session.queue=session.queue.filter(command=>command.state==='queued');
 }
 resolve(sessionId){
  if(!sessionId&&this.defaultSessionId)sessionId=this.resolveDefaultSession?.()||this.defaultSessionId;
  if(!sessionId){const values=[...this.sessions.values()].filter(s=>!s.revoked&&s.expiresAt>this.clock());if(values.length!==1)fail('session_required',values.length?'Supply sessionId from dex_list_sessions when several sessions are paired.':'No Dex session is paired. Call dex_create_pairing and connect in Dex.');return values[0];}
  const session=this.sessions.get(sessionId);
  if(!session||session.revoked||session.expiresAt<=this.clock())fail('session_expired','Dex session is missing or expired',401);
  return session;
 }
 authenticate(secret){
  if(!secret||!secret.startsWith('dxb_'))fail('unauthorized','A valid Dex connection token is required',401);
  const hash=digest(secret);
  for(const session of this.sessions.values())if(sameHash(session.agentHash,hash))return this.resolve(session.id);
  fail('unauthorized','A valid Dex connection token is required',401);
 }
 async http(req,res){
  req.on('error',()=>{this.issue('http_request_error');});
  res.on('error',()=>{this.issue('http_response_error');res.destroy();});
  try{
   this.diagnostics.httpRequests++;
   if(req.url==='/bridge/ws'){this.diagnostics.plainWebSocketRequests++;this.issue('missing_websocket_upgrade');}
   if(!this.validOrigin(req))fail('forbidden_origin','Use the exact loopback endpoint without a browser Origin',403);
   if(req.url==='/health'&&req.method==='GET'){await this.respond(res,json({service:'dex-plus-bridge',protocol:VERSION}));return;}
   if(req.url==='/bridge/script-call'&&req.method==='POST'&&this.scriptCall){
    const request=this.toRequest(req),key=bearer(request);
    await this.respond(res,json(await this.scriptCall(key,()=>readJson(request))));return;
   }
   if(req.url==='/bridge/sessions'&&req.method==='POST'){
    this.registrationAttempts=this.registrationAttempts.filter(t=>this.clock()-t<60000);
    if(this.registrationAttempts.length>=20)fail('rate_limit','Too many pairing attempts; try again in a minute',429);
    this.registrationAttempts.push(this.clock());
    const request=this.toRequest(req),code=bearer(request),pair=code&&this.pairings.get(digest(code));
    if(!pair||pair.expiresAt<=this.clock())fail('invalid_pairing','Pairing code is invalid, used or expired. Create another code in the AI client.',401);
    const parsed=registrationSchema.safeParse(await readJson(request));
    if(!parsed.success)fail('invalid_registration','Invalid Dex registration metadata or grants');
    // Body parsing yields. Recheck and consume synchronously so two concurrent
    // requests cannot both spend the same one-time code.
    if(this.pairings.get(digest(code))!==pair||pair.expiresAt<=this.clock())fail('invalid_pairing','Pairing code is already used or expired',401);
    for(const [id,s]of this.sessions)if(s.expiresAt<=this.clock()){this.revoke(s);this.sessions.delete(id);}
    if(this.sessions.size>=LIMITS.sessions)fail('session_limit','This AI host has reached its active Dex session limit',429);
    this.pairings.delete(digest(code));
    const agentToken=token('dxb_'),session={id:randomUUID(),agentHash:digest(agentToken),grants:parsed.data.grants,info:parsed.data.info,capabilities:{},commands:new Map(),queue:[],socket:null,connectionId:null,expiresAt:this.clock()+LIMITS.sessionHours*3600000,revoked:false,blocked:false,retained:[]};
    session.connectedAt=this.clock();
    this.sessions.set(session.id,session);
    this.diagnostics.registrations++;
    await this.respond(res,json({sessionId:session.id,agentToken,expiresAt:new Date(session.expiresAt).toISOString()},201));return;
   }
   if(req.url==='/bridge/ticket'&&req.method==='POST'){
    const session=this.authenticate(bearer(this.toRequest(req)));
    for(const [key,value]of this.tickets)if(value.expiresAt<=this.clock()||value.sessionId===session.id)this.tickets.delete(key);
    const ticket=token('dxwt_'),expiresAt=this.clock()+20000;
    this.tickets.set(digest(ticket),{sessionId:session.id,expiresAt});
    await this.respond(res,json({ticket,expiresAt:new Date(expiresAt).toISOString()}));return;
   }
   if(req.url==='/bridge/session'&&['PATCH','DELETE','GET'].includes(req.method)){
    const request=this.toRequest(req),session=this.authenticate(bearer(request));
    if(req.method==='DELETE'){this.revoke(session);this.sessions.delete(session.id);await this.respond(res,json({revoked:true}));return;}
    if(req.method==='PATCH'){
     const body=await readJson(request),grants=grantsSchema.safeParse(body?.grants);
     if(!grants.success)fail('invalid_grants','Inspect, Edit and Run code grants must be explicit booleans');
     session.grants=grants.data;
     for(const command of session.queue)if(!session.grants[command.grant])this.finish(session,command,'cancelled',null,{code:'permission_denied',message:'Permission was disabled before execution'});
     session.queue=session.queue.filter(c=>c.state==='queued');
     this.send(session.socket,{type:'grants',grants:session.grants});
    }
    await this.respond(res,json(this.summary(session)));return;
   }
   fail('not_found','Unknown bridge endpoint',404);
  }catch(error){const known=error instanceof BridgeError;await this.respond(res,json({error:{code:known?error.code:'internal_error',message:known?error.message:'The local bridge could not complete this request'}},known?error.status:500));}
 }
 toRequest(req){return new Request(this.url+req.url,{method:req.method,headers:req.headers,...(!['GET','HEAD'].includes(req.method)?{body:req,duplex:'half'}:{})});}
 async respond(res,response){if(res.destroyed)return;res.writeHead(response.status,Object.fromEntries(response.headers));res.end(Buffer.from(await response.arrayBuffer()));}
 send(socket,value){if(socket?.readyState===WebSocket.OPEN)socket.send(JSON.stringify(value));}
 attach(socket,ticketSessionId){
  this.diagnostics.acceptedUpgrades++;
  this.sockets.add(socket);this.pendingSockets.add(socket);let session,connectionId;let received=this.clock();
  const timeout=setTimeout(()=>{if(!session){this.issue('hello_timeout');socket.close(1008,'Authentication required');}},5000);timeout.unref?.();
  const heartbeat=setInterval(()=>{
   if(!session)return;
   if(this.clock()-received>45000||session.expiresAt<=this.clock()||session.revoked){socket.close(1008,'Connection expired');return;}
   this.send(socket,{type:'ping',time:this.clock()});
  },15000);heartbeat.unref?.();
  socket.on('message',data=>{
   try{
    const message=JSON.parse(data.toString('utf8'));validateJson(message);received=this.clock();
    if(!session){
     if(message.type!=='hello'||message.version!==VERSION)fail('unauthorized','Expected bridge hello',401);
     const candidate=this.authenticate(message.token);
     if(candidate.id!==ticketSessionId)fail('wrong_ticket','WebSocket ticket belongs to another session',403);
     if(candidate.id!==message.sessionId)fail('wrong_session','Agent token belongs to another session',403);
     if(candidate.socket)fail('already_connected','This Dex session already has an active connection',409);
     const commands=Array.isArray(message.capabilities)?message.capabilities:message.capabilities?.commands;
     if(!Array.isArray(commands)||commands.length>200)fail('invalid_capabilities','Dex must advertise a bounded command catalogue');
     const names=commands.map(c=>typeof c==='string'?c:c?.name).filter(name=>toolByName.has(name));
     candidate.capabilities={protocol:VERSION,commands:names,scope:'client',hardExecutionTimeout:false};
     candidate.toolControls=message.toolControls===true;
     if(candidate.toolControls)this.setToolPolicy(candidate,message.disabledTools??[],message.paused);
     session=candidate;connectionId=randomUUID();session.connectionId=connectionId;session.socket=socket;session.blocked=false;clearTimeout(timeout);
     this.pendingSockets.delete(socket);this.diagnostics.authenticatedConnections++;
     this.send(socket,{type:'ready',version:VERSION,sessionId:session.id,grants:session.grants,expiresAt:new Date(session.expiresAt).toISOString(),...(session.toolControls?{tools:this.toolCatalog?.()||[]}: {})});this.pump(session);return;
    }
    if(session.socket!==socket||session.connectionId!==connectionId||session.revoked)fail('stale_connection','This connection is no longer active',401);
    if(message.type==='pong')return;
    if(message.type==='ping'){this.send(socket,{type:'pong'});return;}
    if(message.type==='tool_policy'&&session.toolControls){
     if(!Number.isSafeInteger(message.revision)||message.revision<1)fail('invalid_tool_policy','Invalid command settings revision');
     this.setToolPolicy(session,message.disabledTools,message.paused);
     this.send(socket,{type:'tool_policy_ack',revision:message.revision});return;
    }
    if(message.type!=='result'||typeof message.id!=='string'||typeof message.ok!=='boolean')fail('invalid_message','Expected a command result');
    const command=session.commands.get(message.id);
    if(!command||!['claimed','outcome_unknown'].includes(command.state)||command.connectionId!==connectionId)return;
    if(Buffer.byteLength(JSON.stringify(message))>LIMITS.result)fail('result_limit','Dex result is too large');
    // A late answer resolves uncertainty, without re-executing the command.
    if(command.state==='outcome_unknown')command.state='claimed';
    const error=message.ok?null:resultError(message.error);
    this.finish(session,command,message.ok?'completed':'failed',message.result??null,error);session.blocked=false;this.pump(session);
   }catch(error){if(!session)this.diagnostics.failedHellos++;this.issue(error instanceof BridgeError?'message_'+error.code:'malformed_message');this.send(socket,{type:'error',error:{code:error instanceof BridgeError?error.code:'invalid_message',message:error instanceof BridgeError?error.message:'Malformed bridge message'}});socket.close(1008,'Invalid bridge message');}
  });
  const closed=()=>{
   clearTimeout(timeout);clearInterval(heartbeat);this.sockets.delete(socket);this.pendingSockets.delete(socket);
   if(session&&session.socket===socket&&session.connectionId===connectionId){
    session.socket=null;session.connectionId=null;
    for(const command of session.commands.values())if(command.state==='claimed')this.finish(session,command,'outcome_unknown',null,closeError);
    for(const command of session.queue)this.finish(session,command,'cancelled',null,{code:'disconnected',message:'Dex disconnected before dispatch'});
    session.queue=[];
   }
  };
  socket.on('close',closed);socket.on('error',()=>socket.close());
 }
 revoke(session){
  session.revoked=true;
  for(const [key,value]of this.tickets)if(value.sessionId===session.id)this.tickets.delete(key);
  for(const command of session.commands.values())if(!terminal.has(command.state))this.finish(session,command,command.state==='claimed'?'outcome_unknown':'cancelled',null,command.state==='claimed'?closeError:{code:'revoked',message:'Dex disconnected before execution'});
  session.queue=[];session.socket?.close(1000,'Dex disconnected');session.socket=null;
 }
 pump(session){
  if(!session.socket||session.blocked||[...session.commands.values()].some(c=>c.state==='claimed'))return;
  while(session.queue.length){
   const command=session.queue.shift();if(command.state!=='queued')continue;
   if(!session.grants[command.grant]){this.finish(session,command,'cancelled',null,{code:'permission_denied',message:'Permission is disabled in Dex'});continue;}
   if(command.deadline<=this.clock()){this.finish(session,command,'cancelled',null,{code:'deadline_exceeded',message:'Command expired before execution'});continue;}
   command.state='claimed';command.connectionId=session.connectionId;
   this.send(session.socket,{type:'command',id:command.id,name:command.name,args:command.args,grants:session.grants,deadline:command.deadline});return;
  }
 }
 finish(session,command,state,result,error){
  if(terminal.has(command.state))return;
  command.state=state;command.result=result;command.error=error;command.finishedAt=this.clock();clearTimeout(command.timer);
  if(state==='outcome_unknown'&&command.connectionId)session.blocked=true;
  command.resolve?.(this.commandResult(command));command.resolve=null;command.promise=null;
  delete command.args;
  session.retained.push(command);
  while(session.retained.length>32){const old=session.retained.shift();old.result=null;old.resultExpired=true;}
 }
 commandResult(c){return {commandId:c.id,state:c.state,...(c.state==='completed'?{result:c.result,...(c.resultExpired?{resultExpired:true}:{})}:{}),...(c.error?{error:c.error}:{})};}
 getCommand(sessionId,id){const session=this.resolve(sessionId),command=session.commands.get(id);if(!command)fail('unknown_command','Command is unavailable in this session');return this.commandResult(command);}
 async execute(name,args={},signal){
  const session=this.resolve(args.sessionId),{tool,args:payload,commandId}=validateArgs(name,args,session.id);
  this.assertToolEnabled(name,[session]);
  if(Buffer.byteLength(JSON.stringify(payload))>LIMITS.body)fail('payload_limit','Command arguments are too large',413);
  if(!session.grants[tool.grant])fail('permission_denied',`Enable ${tool.grant==='execute'?'Run code':tool.grant==='edit'?'Edit':'Inspect'} in Dex first`,403);
  if(!session.capabilities.commands?.includes(name))fail('unsupported_command','This Dex build does not advertise that command');
  const identifier=commandId||randomUUID(),existing=session.commands.get(identifier),fingerprint=digest(JSON.stringify({name,args:payload}));
  if(existing){if(existing.fingerprint!==fingerprint)fail('command_conflict','This commandId was used for different arguments',409);return terminal.has(existing.state)?this.commandResult(existing):existing.promise;}
  if(!session.socket)fail('not_connected','Dex is paired but its connection is offline',503);
  if(session.blocked)fail('outcome_unknown','A previous dispatched command has no confirmed result; reconnect Dex before sending another command');
  if(signal?.aborted)fail('cancelled','Tool call was cancelled before execution');
  if(session.commands.size>=1024)fail('session_capacity','The bounded command history is full. Pair a new Dex session.');
  if(session.queue.length>=LIMITS.queue)fail('queue_full','Dex command queue is full',429);
  const command={id:identifier,name,args:payload,grant:tool.grant,state:'queued',fingerprint,deadline:this.clock()+this.commandMs,result:null,error:null};
  command.promise=new Promise(resolve=>{command.resolve=resolve;});
  const promise=command.promise;
  command.timer=setTimeout(()=>{
   this.finish(session,command,command.state==='claimed'?'outcome_unknown':'cancelled',null,{code:command.state==='claimed'?'outcome_unknown':'deadline_exceeded',message:command.state==='claimed'?'No result arrived before the deadline. The action may still have executed; inspect before retrying.':'Command expired before dispatch'});this.pump(session);
  },this.commandMs);command.timer.unref?.();
  session.commands.set(identifier,command);session.queue.push(command);this.pump(session);
  const abort=()=>{this.finish(session,command,command.state==='claimed'?'outcome_unknown':'cancelled',null,{code:command.state==='claimed'?'outcome_unknown':'cancelled',message:command.state==='claimed'?'AI stopped waiting after dispatch. The action may have executed.':'AI cancelled the queued command'});this.pump(session);};
  signal?.addEventListener('abort',abort,{once:true});
  try{return await promise;}finally{signal?.removeEventListener('abort',abort);}
 }
 async close(){
  if(this.closed)return;this.closed=true;
  for(const session of this.sessions.values())this.revoke(session);
  for(const socket of this.sockets)socket.terminate();this.sockets.clear();this.pendingSockets.clear();this.pairings.clear();
  for(const socket of this.rawSockets)socket.destroy();this.rawSockets.clear();
  await new Promise(resolve=>this.wss.close(()=>resolve()));
  this.server.closeAllConnections?.();await new Promise(resolve=>this.server.close(()=>resolve()));
 }
}

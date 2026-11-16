import {randomUUID,createHash} from 'node:crypto';
import {mkdir,mkdtemp,writeFile,open,rm,stat} from 'node:fs/promises';
import {createReadStream} from 'node:fs';
import {join} from 'node:path';
import {homedir} from 'node:os';
import {BridgeError} from './protocol.mjs';
import {MjpegAvi,jpegDimensions} from './mjpeg-avi.mjs';
import {recordForegroundPlayer,recordingScript} from './screen-recording-source.mjs';
const CLIP_BYTES=64*1024*1024,TOTAL_BYTES=256*1024*1024,MAX_FRAME=1048576;
const hash=data=>createHash('sha256').update(data).digest('hex');
const checkAbort=signal=>{if(signal?.aborted)throw new BridgeError('cancelled','Screen recording start was cancelled');};
const message=error=>String(error?.message||error).split(/\r?\n/)[0].slice(0,240);
const deferred=()=>{let resolve,reject;const promise=new Promise((a,b)=>{resolve=a;reject=b;});promise.catch(()=>{});return {promise,resolve,reject};};
const digestFile=async(path,bytes)=>{const value=createHash('sha256');let read=0;for await(const part of createReadStream(path,{start:0,end:bytes-1})){read+=part.length;value.update(part);}if(read!==bytes||(await stat(path)).size!==bytes)throw new BridgeError('recording_changed','Video changed during finalization');return value.digest('hex');};
const readFrame=async frame=>{
 const file=await open(frame.path,'r');
 try{
  if((await file.stat()).size!==frame.bytes||frame.bytes>MAX_FRAME)throw new BridgeError('recording_changed','Saved frame size changed');
  const data=Buffer.alloc(frame.bytes);let read=0;
  while(read<data.length){const value=await file.read(data,read,data.length-read,read);if(!value.bytesRead)break;read+=value.bytesRead;}
  if(read!==frame.bytes||(await file.stat()).size!==frame.bytes||hash(data)!==frame.sha256)throw new BridgeError('recording_changed','Saved frame no longer matches its recording');
  return data;
 }finally{await file.close();}
};
export class ScreenRecordingHost{
 constructor(broker,{directory,source=recordForegroundPlayer,monitorMs=250,startupMs=12000}={}){
  this.broker=broker;this.directory=directory||process.env.DEX_PLUS_RECORDINGS_DIR||join(homedir(),'Documents','Dex Explorer Recordings');this.source=source;this.monitorMs=monitorMs;this.startupMs=startupMs;this.records=new Map();this.active=null;this.usedBytes=0;this.closed=false;
 }
 authorize(sessionId){const session=this.broker.resolve(sessionId);if(!session.grants.inspect||!session.socket)throw new BridgeError('not_connected','Connect Dex with Inspect access before recording');return session;}
 lookup(args){const r=this.records.get(args.recordingId);if(!r)throw new BridgeError('recording_unavailable','Choose a screen recording created by this Dex MCP server');if(args.sessionId&&args.sessionId!==r.sessionId)throw new BridgeError('wrong_session','This recording belongs to another Dex session');return r;}
 summary(r){return {recordingId:r.id,sessionId:r.sessionId,status:r.status,createdAt:r.createdAt,captureStartedAt:r.frames[0]?.capturedAt,finishedAt:r.finishedAt,requested:r.options,processId:r.pin?.processId,windowId:r.pin?.windowId,frameCount:r.frames.length,videoFrameCount:r.writer?.frames||0,duplicatedVideoFrames:r.duplicates||0,videoSamplesOmitted:r.samplesOmitted||0,durationMs:r.frames.at(-1)?.offsetMs||0,actualSampleFps:r.frames.length>1?(r.frames.length-1)*1000/r.frames.at(-1).offsetMs:0,stopReason:r.stopReason,error:r.error,files:r.files||[],directory:r.directory,video:r.video||{available:false,reason:'not_finalized'},camera:r.camera,scope:'client',audio:false,nonAtomic:true,sessionProcessIdentityVerified:false,limits:{maxDurationSeconds:20,maxFps:10,maxDimension:1280,maxFrames:200,maxClipBytes:CLIP_BYTES,maxCompanionBytes:TOTAL_BYTES,maxRecordings:8},note:'Visible foreground Roblox Player client area only; overlays may appear. Camera is a separate initial observation. Process identity is not cryptographically bound to the Dex session. Video duplicates sampled frames across timing gaps; timestamped images preserve actual capture times.'};}
 requestStop(r,reason){if(!r.stopReason)r.stopReason=reason;if(['starting','recording'].includes(r.status))r.status='stopping';r.controller.abort();}
 async start(args={},signal){
  if(this.closed)throw new BridgeError('closed','Dex MCP is shutting down');
  if(this.active)throw new BridgeError('recording_busy','One screen recording is already active');
  if(this.records.size>=8||this.usedBytes>=TOTAL_BYTES-131072)throw new BridgeError('recording_limit','Dex MCP reached its recording or storage limit. Saved files are still on disk.');
  const options={processId:args.processId??0,durationSeconds:args.durationSeconds??8,fps:args.fps??5,maxDimension:args.maxDimension??960};recordingScript(options);checkAbort(signal);
  const session=this.authorize(args.sessionId);
  if(this.broker.summaries().filter(s=>s.connected).length>1&&!args.processId)throw new BridgeError('ambiguous_player','Multiple Dex sessions are connected; supply the foreground Roblox Player processId');
  const r={id:randomUUID(),sessionId:session.id,options,status:'starting',createdAt:new Date().toISOString(),frames:[],controller:new AbortController(),ready:deferred(),startupFinished:deferred(),frameWork:Promise.resolve(),storedBytes:0,duplicates:0,samplesOmitted:0};
  this.records.set(r.id,r);this.active=r;
  const abort=()=>this.requestStop(r,'start_cancelled');signal?.addEventListener('abort',abort,{once:true});let startupTimer;
  try{
   await mkdir(this.directory,{recursive:true});r.directory=await mkdtemp(join(this.directory,'recording-'));
   const cameraSignal=AbortSignal.any([r.controller.signal,AbortSignal.timeout(5000),...(signal?[signal]:[])]);
   const camera=await this.broker.execute('dex_get_camera',{sessionId:r.sessionId},cameraSignal);
   if(camera.state!=='completed')throw new BridgeError('recording_unavailable',camera.error?.message||'Could not read the client camera');
   if(Buffer.byteLength(JSON.stringify(camera.result))>16384)throw new BridgeError('recording_unavailable','Camera context exceeded its size limit');
   r.camera=camera.result;checkAbort(signal);checkAbort(r.controller.signal);this.authorize(r.sessionId);
   r.monitor=setInterval(()=>{try{this.authorize(r.sessionId);}catch{this.requestStop(r,'session_disconnected');}},this.monitorMs);r.monitor.unref?.();
   r.done=this.run(r);
   startupTimer=setTimeout(()=>{this.requestStop(r,'startup_timeout');r.ready.reject(new BridgeError('recording_unavailable','Capture helper did not produce a frame before the startup deadline'));},this.startupMs);startupTimer.unref?.();
   await r.ready.promise;checkAbort(signal);
   return this.summary(r);
  }catch(error){
   this.requestStop(r,r.stopReason||'start_failed');if(r.done)await r.done;
   else if(r.directory)await rm(r.directory,{recursive:true,force:true});
   if(!r.frames.length){this.records.delete(r.id);if(this.active===r)this.active=null;}
   throw error instanceof BridgeError?error:new BridgeError('recording_unavailable',message(error));
  }finally{clearTimeout(startupTimer);signal?.removeEventListener('abort',abort);r.startupFinished.resolve();}
 }
 async appendFrame(r,item){
  if(r.controller.signal.aborted)return;
  this.authorize(r.sessionId);
  if(typeof item.data!=='string'||item.data.length>1400000||!Number.isSafeInteger(item.processId)||item.processId<1||typeof item.windowId!=='string'||item.windowId.length<1||item.windowId.length>32||!Number.isFinite(item.elapsedMs)||item.elapsedMs<0||!Number.isFinite(Date.parse(item.capturedAt)))throw new BridgeError('invalid_frame','Capture returned invalid process/timestamp metadata');
  const data=Buffer.from(item.data,'base64');if(data.length>MAX_FRAME)throw new BridgeError('invalid_frame','JPEG frame exceeds its byte limit');
  const shape=jpegDimensions(data);
  if(shape.width!==item.width||shape.height!==item.height||Math.max(shape.width,shape.height)>r.options.maxDimension||![item.clientWidth,item.clientHeight].every(v=>Number.isSafeInteger(v)&&v>0&&v<=8192)||item.clientWidth*item.clientHeight>34000000)throw new BridgeError('invalid_frame','Capture dimensions exceed limits');
  if(r.options.processId&&item.processId!==r.options.processId)throw new BridgeError('wrong_player','Capture process does not match the requested player');
  if(!r.pin){
   r.pin={processId:item.processId,windowId:item.windowId,width:item.width,height:item.height,clientWidth:item.clientWidth,clientHeight:item.clientHeight};r.firstElapsed=item.elapsedMs;
   r.writer=await MjpegAvi.create(join(r.directory,'clip.avi'),{...shape,fps:r.options.fps,maxFrames:r.options.durationSeconds*r.options.fps,maxBytes:32*1024*1024});this.usedBytes+=r.writer.bytes;r.storedBytes+=r.writer.bytes;
  }else if(Object.keys(r.pin).some(key=>r.pin[key]!==item[key]))throw new BridgeError('window_changed','Player identity or capture dimensions changed');
  const offsetMs=item.elapsedMs-r.firstElapsed;
  if(offsetMs<0||r.frames.length&&offsetMs<=r.frames.at(-1).offsetMs||offsetMs>r.options.durationSeconds*1000+1000)throw new BridgeError('invalid_frame','Capture timestamps are outside the recording range');
  const maxFrames=r.options.durationSeconds*r.options.fps;
  if(r.frames.length>=maxFrames){this.requestStop(r,'frame_limit');return;}
  const slot=Math.min(maxFrames-1,Math.round(offsetMs*r.options.fps/1000));
  const copies=Math.max(0,slot-r.writer.frames);const newVideo=r.writer.frames<=slot?data.length+9:0;
  const reserve=data.length+newVideo+copies*((r.lastData?.length||data.length)+9)+131072;
  if(r.storedBytes+reserve>CLIP_BYTES||this.usedBytes+reserve>TOTAL_BYTES){this.requestStop(r,'byte_limit');return;}
  const index=r.frames.length,name=`frame-${String(index).padStart(4,'0')}.jpg`,path=join(r.directory,name);const before=r.writer.bytes;
  try{
   await writeFile(path,data,{flag:'wx'});
   while(r.writer.frames<slot){await r.writer.append(r.lastData||data);r.duplicates++;}
   if(r.writer.frames===slot)await r.writer.append(data);else r.samplesOmitted++;
  }catch(error){await rm(path,{force:true}).catch(()=>{});throw error;}
  finally{const delta=r.writer.bytes-before;this.usedBytes+=delta;r.storedBytes+=delta;}
  this.usedBytes+=data.length;r.storedBytes+=data.length;r.lastData=data;
  r.frames.push({index,file:name,path,bytes:data.length,sha256:hash(data),offsetMs,capturedAt:item.capturedAt,width:item.width,height:item.height,clientWidth:item.clientWidth,clientHeight:item.clientHeight});
  if(r.status==='starting')r.status='recording';r.ready.resolve();
 }
 async run(r){
  try{
   const ended=await this.source(r.options,{signal:r.controller.signal,onFrame:item=>{r.frameWork=r.frameWork.then(()=>this.appendFrame(r,item));return r.frameWork;}});
   await r.frameWork;if(!r.stopReason)r.stopReason=ended?.reason||'helper_ended';
  }catch(error){r.error={code:error instanceof BridgeError?error.code:'recording_failed',message:message(error)};if(!r.stopReason)r.stopReason='capture_failed';}
  finally{
   clearInterval(r.monitor);r.status='finalizing';await r.frameWork.catch(()=>{});
   try{
    if(r.writer){await r.writer.finish();if(r.writer.frames){const path=join(r.directory,'clip.avi'),info=await stat(path);r.video={available:true,path,file:'clip.avi',bytes:info.size,sha256:await digestFile(path,info.size),mimeType:'video/x-msvideo',codec:'MJPG',fps:r.options.fps,frames:r.writer.frames,durationMs:r.writer.frames*1000/r.options.fps};}}
   }catch(error){r.error={code:'finalize_failed',message:message(error)};r.video={available:false,reason:'finalization_failed'};}
   r.lastData=null;r.finishedAt=new Date().toISOString();
   r.status=!r.frames.length?'failed':!r.error&&['duration','user_stopped','stop_requested'].includes(r.stopReason)?'completed':'partial';
   if(!r.frames.length){r.ready.reject(new BridgeError('recording_unavailable',r.error?.message||`Recording ended without frames (${r.stopReason})`));if(r.directory)await rm(r.directory,{recursive:true,force:true}).catch(()=>{});this.usedBytes-=r.storedBytes;r.storedBytes=0;}
   else{
    const manifest={...this.summary(r),frames:r.frames.map(({path,...frame})=>frame)};
    try{const data=JSON.stringify(manifest,null,2),path=join(r.directory,'recording.json');await writeFile(path,data,{flag:'wx'});this.usedBytes+=Buffer.byteLength(data);r.storedBytes+=Buffer.byteLength(data);r.files=[{name:'recording.json',path,bytes:Buffer.byteLength(data),sha256:hash(data)},...(r.video?.available?[{name:'clip.avi',...r.video}]:[])];}
    catch(error){r.error={code:'manifest_failed',message:message(error)};r.status='partial';}
   }
   if(this.active===r)this.active=null;
  }
 }
 async stop(args){const r=this.lookup(args);if(['starting','recording','stopping','finalizing'].includes(r.status)){if(r.status!=='finalizing')this.requestStop(r,'user_stopped');await r.startupFinished.promise;if(r.done)await r.done;}return this.summary(r);}
 async get(args){
  const r=this.lookup(args);const summary=this.summary(r);let indices=[];
  const count=r.frames.length,limit=args.frameLimit??3;
  if(!Number.isInteger(limit)||limit<1||limit>4||args.frameOffset!==undefined&&(!Number.isInteger(args.frameOffset)||args.frameOffset<0||args.frameOffset>199)||args.frameStep!==undefined&&(!Number.isInteger(args.frameStep)||args.frameStep<1||args.frameStep>200)||args.includeFrames!==undefined&&typeof args.includeFrames!=='boolean')throw new BridgeError('invalid_arguments','Invalid frame selection');
  const paged=args.frameOffset!==undefined||args.frameStep!==undefined;
  if(args.includeFrames!==false&&count){if(paged){for(let index=args.frameOffset??0;index<count&&indices.length<limit;index+=args.frameStep??1)indices.push(index);}else for(let i=0;i<Math.min(limit,count);i++)indices.push(limit===1?count-1:Math.round(i*(count-1)/(Math.min(limit,count)-1||1)));}
  const content=[],frames=[];let bytes=0;
  for(const index of indices){const frame=r.frames[index];const data=await readFrame(frame);bytes+=data.length;if(bytes>4*MAX_FRAME)break;frames.push({...frame});content.push({type:'text',text:`Frame ${index}, ${Math.round(frame.offsetMs)} ms after first capture (${frame.capturedAt})`},{type:'image',data:data.toString('base64'),mimeType:'image/jpeg'});}
  const next=paged&&indices.length?indices.at(-1)+(args.frameStep??1):undefined;
  const metadata={...summary,frames,sampled:!paged,nextFrameOffset:next!==undefined&&next<count?next:undefined};
  return {metadata,content};
 }
 async close(){if(this.closed)return;this.closed=true;if(this.active){const r=this.active;this.requestStop(r,'companion_closed');await r.startupFinished.promise;if(r.done)await r.done;}}
}

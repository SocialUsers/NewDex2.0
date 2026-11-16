import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,readdir,rm,writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {spawn} from 'node:child_process';
import {join} from 'node:path';
import {ScreenRecordingHost} from '../src/screen-recording-host.mjs';
import {MjpegAvi,jpegDimensions} from '../src/mjpeg-avi.mjs';
import {recordingScript,recordForegroundPlayer,powershellFailureMessage} from '../src/screen-recording-source.mjs';
import {HOST_SCREEN_RECORDING_TOOLS} from '../src/screen-recording-tools.mjs';
import {BridgeError} from '../src/protocol.mjs';
import {createMcpServer} from '../src/server.mjs';
const red=await readFile(new URL('fixtures/screen-red.jpg',import.meta.url)),blue=await readFile(new URL('fixtures/screen-blue.jpg',import.meta.url));
const sid='11111111-1111-4111-8111-111111111111',other='22222222-2222-4222-8222-222222222222';
const waitFor=async check=>{const end=Date.now()+3000;while(!check()){if(Date.now()>end)throw Error('Fixture timed out');await new Promise(r=>setTimeout(r,5));}};
const frame=(index,data=red,overrides={})=>({type:'frame',data:data.toString('base64'),width:4,height:4,clientWidth:800,clientHeight:600,processId:123,windowId:'321',elapsedMs:index*200,capturedAt:new Date(1700000000000+index*200).toISOString(),...overrides});
async function fixture(t,source,options={}){
 const directory=await mkdtemp(join(tmpdir(),'dex-recording-'));const session={id:sid,grants:{inspect:true},socket:{}};let calls=0;
 const broker={resolve(id){assert.ok(!id||id===sid);return session;},summaries(){return [{connected:true}];},async execute(name,args){calls++;assert.equal(name,'dex_get_camera');assert.equal(args.sessionId,sid);return {state:'completed',result:{scope:'client',properties:{FieldOfView:70}}};}};
 const host=new ScreenRecordingHost(broker,{directory,source,monitorMs:10,startupMs:1000,...options});t.after(async()=>{await host.close();await rm(directory,{recursive:true,force:true});});
 return {host,broker,session,directory,get calls(){return calls;}};
}
const held=async(args,{signal,onFrame})=>{await onFrame(frame(0));if(!signal.aborted)await new Promise(r=>signal.addEventListener('abort',r,{once:true}));return {reason:'stop_requested'};};

test('MJPEG AVI contains real JPEG frames, valid RIFF sizes, headers and keyframe index',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'dex-avi-'));t.after(()=>rm(directory,{recursive:true,force:true}));
 assert.deepEqual(jpegDimensions(red),{width:4,height:4});
 const path=join(directory,'clip.avi'),avi=await MjpegAvi.create(path,{width:4,height:4,fps:5,maxFrames:3});
 await avi.append(red);await avi.append(blue);await avi.append(red);await assert.rejects(avi.append(blue),/budget/);await avi.finish();await avi.finish();
 const data=await readFile(path);assert.equal(data.toString('ascii',0,4),'RIFF');assert.equal(data.toString('ascii',8,12),'AVI ');assert.equal(data.readUInt32LE(4),data.length-8);assert.equal(data.length,avi.bytes);
 const avih=data.indexOf('avih');assert.equal(data.readUInt32LE(avih+8+16),3);
 const idx=data.length-8-3*16;assert.equal(data.toString('ascii',idx,idx+4),'idx1');assert.equal(data.readUInt32LE(idx+4),48);
 const movi=data.indexOf('movi');for(let i=0;i<3;i++){const entry=idx+8+i*16;const offset=data.readUInt32LE(entry+8);assert.equal(data.toString('ascii',movi+offset,movi+offset+4),'00dc');assert.equal(data.readUInt32LE(movi+offset+4),data.readUInt32LE(entry+12));}
 await assert.rejects(avi.append(red),/finalized/);assert.throws(()=>jpegDimensions(Buffer.from('not a jpeg')),/JPEG/);
 const small=await MjpegAvi.create(join(directory,'small.avi'),{width:4,height:4,fps:1,maxBytes:300});await assert.rejects(small.append(red),/budget/);await small.finish();
});

test('recording saves AVI/manifest with timestamps, timing gaps and uniform/paged MCP images',async t=>{
 const {host}=await fixture(t,async(args,{onFrame})=>{await onFrame(frame(0));await onFrame(frame(1,blue));await onFrame(frame(5));return {reason:'duration'};});
 const started=await host.start({sessionId:sid,durationSeconds:2,fps:5});const r=host.records.get(started.recordingId);await r.done;
 const result=await host.get({recordingId:r.id});assert.equal(result.metadata.status,'completed');assert.equal(result.metadata.frameCount,3);assert.equal(result.metadata.video.frames,6);assert.equal(result.metadata.duplicatedVideoFrames,3);assert.equal(result.metadata.audio,false);assert.equal(result.metadata.sessionProcessIdentityVerified,false);
 assert.equal(result.metadata.video.mimeType,'video/x-msvideo');assert.equal(result.content.filter(c=>c.type==='image').length,3);assert.deepEqual(result.metadata.frames.map(f=>f.offsetMs),[0,200,1000]);assert.ok(result.content.every(c=>c.type==='image'||c.type==='text'));assert.ok(!JSON.stringify(result.metadata).includes(red.toString('base64')));
 const manifest=JSON.parse(await readFile(join(r.directory,'recording.json'),'utf8'));assert.equal(manifest.frames[2].offsetMs,1000);assert.ok(manifest.video.available);assert.ok(manifest.frames.every(f=>!Object.hasOwn(f,'path')));
 const page=await host.get({recordingId:r.id,frameOffset:0,frameLimit:1,frameStep:2});assert.equal(page.metadata.nextFrameOffset,2);assert.equal(page.metadata.frames[0].index,0);
 const next=await host.get({recordingId:r.id,frameOffset:page.metadata.nextFrameOffset,frameLimit:1});assert.equal(next.metadata.frames[0].index,2);assert.equal(next.metadata.nextFrameOffset,undefined);
 assert.equal((await host.get({recordingId:r.id,includeFrames:false})).content.length,0);assert.equal((await host.get({recordingId:r.id,frameLimit:1})).metadata.frames[0].index,2);
 assert.equal((await host.stop({recordingId:r.id})).status,'completed');await assert.rejects(host.get({recordingId:r.id,sessionId:other}),/another Dex session/);
 await writeFile(r.frames[0].path,Buffer.alloc(2*1024*1024));await assert.rejects(host.get({recordingId:r.id}),/size changed/);
});

test('stop, disconnect, and server shutdown stop the owned source and finalize partial recordings',async t=>{
 const a=await fixture(t,held);const s=await a.host.start({});await assert.rejects(a.host.start({}),/already active/);const stopped=await a.host.stop({recordingId:s.recordingId});assert.equal(stopped.status,'completed');assert.equal(stopped.stopReason,'user_stopped');assert.ok(stopped.video.available);
 const b=await fixture(t,held);const d=await b.host.start({});b.session.socket=null;await waitFor(()=>b.host.active===null);const partial=await b.host.get({recordingId:d.recordingId});assert.equal(partial.metadata.status,'partial');assert.equal(partial.metadata.stopReason,'session_disconnected');assert.ok(partial.metadata.video.available,'saved partial clip stays readable after disconnect');
 const c=await fixture(t,held);const x=await c.host.start({});await c.host.close();assert.equal(c.host.records.get(x.recordingId).status,'partial');assert.equal(c.host.active,null);await assert.rejects(c.host.start({}),/shutting down/);
});

test('initial authorization, ambiguity, cancellation and startup errors release every reservation',async t=>{
 const a=await fixture(t,held);a.session.grants.inspect=false;await assert.rejects(a.host.start({}),/Inspect/);assert.equal(a.calls,0);a.session.grants.inspect=true;
 a.broker.summaries=()=>[{connected:true},{connected:true}];await assert.rejects(a.host.start({}),/Multiple/);assert.equal(a.calls,0);
 const started=await a.host.start({processId:123});await a.host.stop({recordingId:started.recordingId});
 await assert.rejects(a.host.start({},AbortSignal.abort()),/cancelled/);
 const b=await fixture(t,async()=>{throw new BridgeError('recording_unavailable','not foreground');});await assert.rejects(b.host.start({}),/not foreground/);assert.equal(b.host.active,null);assert.equal(b.host.records.size,0);assert.equal(b.host.usedBytes,0);assert.deepEqual(await readdir(b.directory),[]);
 let sourceStarted=false;
 const c=await fixture(t,async(args,{signal})=>{sourceStarted=true;if(!signal.aborted)await new Promise(r=>signal.addEventListener('abort',r,{once:true}));return {reason:'stop_requested'};});
 const pending=c.host.start({}).catch(e=>e);await waitFor(()=>sourceStarted);await c.host.close();assert.ok((await pending) instanceof BridgeError);assert.equal(c.host.active,null);assert.deepEqual(await readdir(c.directory),[]);
 const d=await fixture(t,held);for(let i=0;i<8;i++)d.host.records.set('fixture'+i,{});await assert.rejects(d.host.start({}),{code:'recording_limit'});assert.equal(d.calls,0);
});

test('focus/identity/dimension/byte/frame failures preserve only verified frames',async t=>{
 const a=await fixture(t,async(args,{onFrame})=>{await onFrame(frame(0));return {reason:'foreground_changed'};});const start=await a.host.start({});await a.host.records.get(start.recordingId).done;assert.equal((await a.host.get({recordingId:start.recordingId})).metadata.stopReason,'foreground_changed');
 for(const extra of [{processId:999},{windowId:'other'},{width:5},{elapsedMs:0}]){
  const b=await fixture(t,async(args,{onFrame})=>{await onFrame(frame(0));await onFrame(frame(1,blue,extra));return {reason:'duration'};});const s=await b.host.start({processId:123});await b.host.records.get(s.recordingId).done;const out=await b.host.get({recordingId:s.recordingId});assert.equal(out.metadata.status,'partial');assert.equal(out.metadata.frameCount,1);assert.ok(out.metadata.error);
 }
 const f=await fixture(t,async(args,{onFrame})=>{await onFrame(frame(0));await onFrame(frame(1));return {reason:'duration'};});const one=await f.host.start({durationSeconds:1,fps:1});await f.host.records.get(one.recordingId).done;assert.equal(f.host.records.get(one.recordingId).frames.length,1);assert.equal(f.host.records.get(one.recordingId).stopReason,'frame_limit');
 const q=await fixture(t,held);const qs=await q.host.start({});const r=q.host.records.get(qs.recordingId);r.storedBytes=64*1024*1024-1000;await q.host.appendFrame(r,frame(1));await r.done;assert.equal(r.stopReason,'byte_limit');assert.equal(r.frames.length,1);
});

test('strict schemas, numeric-only capture script and MCP close lifecycle',async()=>{
 assert.equal(HOST_SCREEN_RECORDING_TOOLS.length,3);const byName=new Map(HOST_SCREEN_RECORDING_TOOLS.map(t=>[t.name,t]));
 assert.ok(byName.get('dex_start_screen_recording').schema.safeParse({durationSeconds:20,fps:10,maxDimension:1280,processId:123}).success);
 for(const args of [{durationSeconds:21},{fps:11},{maxDimension:2048},{processId:'1;exit'},{audio:true}])assert.equal(byName.get('dex_start_screen_recording').schema.safeParse(args).success,false);
 assert.equal(byName.get('dex_get_screen_recording').schema.safeParse({recordingId:sid,frameLimit:5}).success,false);assert.equal(byName.get('dex_get_screen_recording').schema.safeParse({recordingId:sid,file:'../other'}).success,false);
 assert.throws(()=>recordingScript({processId:'1;exit'}),/parameters/);const script=recordingScript({processId:123});assert.match(script,/RobloxPlayerBeta/);assert.match(script,/foreground_changed/);assert.match(script,/window_changed_during_frame/);assert.match(script,/StartControl/);assert.match(script,/thread.IsBackground=true/);assert.doesNotMatch(script,/SetForegroundWindow|Start-Process|RobloxStudioBeta|VirtualScreen|ffmpeg/i);
 let closed=0;const server=createMcpServer({}, {recordings:{async close(){closed++;}}});await server.close();await server.close();assert.equal(closed,1,'closing the MCP server always owns recorder cleanup');
});


// Substitute only window/process reads and the screen copy. Exercise the real
// PowerShell invocation, NDJSON parser, error propagation and control pipe.
function ownedCaptureScript(script,{loseFocus=false,focusLate=false,missingPlayer=false,wrongPlayer=false,failureStage}={}){
 const stub=`using System; public static class DexRecordingWindow {
  public struct Rect { public int Left,Top,Right,Bottom; } public struct Point { public int X,Y; }
  public static volatile bool StopRequested; private static int calls;
  public static void StartControl(){var t=new System.Threading.Thread(()=>{try{Console.ReadLine();}catch{}StopRequested=true;});t.IsBackground=true;t.Start();}
  public static IntPtr GetForegroundWindow(){calls++;return new IntPtr(${loseFocus?'calls>=5?999:123':focusLate?'calls<=2?999:123':'123'});}
  public static uint GetWindowThreadProcessId(IntPtr h,out uint p){p=(uint)h.ToInt32();return 1;}
  public static bool GetClientRect(IntPtr h,out Rect r){r=new Rect{Right=64,Bottom=48};return true;}
  public static bool ClientToScreen(IntPtr h,ref Point p){p.X=0;p.Y=0;return true;}
  public static bool IsIconic(IntPtr h){return false;} public static bool SetProcessDpiAwarenessContext(IntPtr v){return true;}
 }`;
 script=script.replace(/Add-Type -TypeDefinition @'\r?\n[\s\S]*?\r?\n'@/,"Add-Type -TypeDefinition @'\n"+stub+"\n'@");
 const process=missingPlayer?"[pscustomobject]@{ProcessName='AnotherApp'}":focusLate?"[pscustomobject]@{ProcessName=$(if($playerId -eq 123){'RobloxPlayerBeta'}else{'AnotherApp'})}":"[pscustomobject]@{ProcessName='RobloxPlayerBeta'}";
 script=script.replace('$player=Get-Process -Id $playerId -ErrorAction SilentlyContinue','$player='+process)
  .replace('$graphics.CopyFromScreen($before.X,$before.Y,0,0,$bitmap.Size)','$graphics.Clear([System.Drawing.Color]::Red)');
 if(missingPlayer||wrongPlayer)script=script.replace('UtcNow.AddSeconds(8)','UtcNow.AddMilliseconds(1)');
 if(failureStage==='native_setup')script=script.replace('Add-Type -AssemblyName System.Drawing',"throw 'Fixture native setup failure'");
 if(failureStage==='capture_setup')script=script.replace('$bitmap=New-Object',"throw 'Fixture bitmap setup failure'\n$bitmap=New-Object");
 if(failureStage==='capture')script=script.replace('$graphics.Clear([System.Drawing.Color]::Red)',"throw 'Fixture copy failure'");
 assert.ok(!script.includes('CopyFromScreen')&&!script.includes('Get-Process -Id'));
 return script;
}
async function runOwnedCapture({stopEarly=false,options={},...fixtureOptions}={}){
 const controller=new AbortController(),frames=[];
 const result=await recordForegroundPlayer({durationSeconds:stopEarly?20:1,fps:3,...options},{signal:controller.signal,
  onFrame(item){frames.push(item);if(stopEarly)controller.abort();},
  spawnHelper(command,args,config){
   assert.equal(command,'powershell.exe');assert.ok(args.includes('-OutputFormat')&&args.includes('Text'));
   const actual=[...args],index=actual.indexOf('-EncodedCommand')+1;
   actual[index]=Buffer.from(ownedCaptureScript(Buffer.from(actual[index],'base64').toString('utf16le'),fixtureOptions),'utf16le').toString('base64');
   return spawn(command,actual,config);
  }
 });
 return {...result,frames};
}
test('Windows capture loop encodes owned bitmap frames and stops through its real control pipe', {skip:process.platform!=='win32'}, async()=>{
 const normal=await runOwnedCapture();assert.equal(normal.frames.length,3);assert.equal(normal.reason,'duration');assert.deepEqual(jpegDimensions(Buffer.from(normal.frames[0].data,'base64')),{width:64,height:48});assert.ok(normal.frames[2].elapsedMs>normal.frames[0].elapsedMs);
 const stopped=await runOwnedCapture({stopEarly:true});assert.equal(stopped.reason,'stop_requested');assert.equal(stopped.frames.length,1);
 const lost=await runOwnedCapture({loseFocus:true});assert.equal(lost.reason,'foreground_changed');assert.equal(lost.frames.length,1);
 const late=await runOwnedCapture({focusLate:true});assert.equal(late.reason,'duration');assert.equal(late.frames.length,3,'wait for player focus without capturing another app');
});

test('PowerShell startup/setup/capture failures retain their actual stage and message', {skip:process.platform!=='win32'}, async()=>{
 for(const [options,expected] of [
  [{failureStage:'native_setup'},/native_setup: Fixture native setup failure/],
  [{missingPlayer:true},/window_check: Bring Roblox Player to the foreground/],
  [{wrongPlayer:true,options:{processId:456}},/window_check: Foreground Roblox Player does not match/],
  [{failureStage:'capture_setup'},/capture_setup: Fixture bitmap setup failure/],
  [{failureStage:'capture'},/capture: Fixture copy failure/],
 ])await assert.rejects(runOwnedCapture(options),error=>error.code==='recording_unavailable'&&expected.test(error.message)&&!error.message.includes('CLIXML'));
 // A parser failure occurs before try/catch, so it must use stderr fallback.
 await assert.rejects(recordForegroundPlayer({durationSeconds:1},{spawnHelper(command,args,config){
  const actual=[...args];actual[actual.indexOf('-EncodedCommand')+1]=Buffer.from("if ( {",'utf16le').toString('base64');return spawn(command,actual,config);
 }}),error=>error.code==='recording_unavailable'&&/Missing|Unexpected/i.test(error.message)&&!error.message.includes('CLIXML'));
});

test('legacy CLIXML errors ignore progress, decode escaped text and remain bounded',()=>{
 const xml='#< CLIXML\r\n<Objs><Obj S="progress"><AV>Preparing modules for first use.</AV></Obj><S S="Error">At line:2 char:4_x000D__x000A_</S><S S="Error">+ throw bad_x000D__x000A_</S><S S="Error">Access denied &amp; unsupported &lt;window&gt; &#x41;_x000D__x000A_</S></Objs>';
 assert.equal(powershellFailureMessage(xml),'Access denied & unsupported <window> A');
 assert.equal(powershellFailureMessage('plain error\r\nstack detail'),'plain error');
 assert.equal(powershellFailureMessage('#< CLIXML\n<Objs><Obj S="progress"/></Objs>'),'Capture helper failed without a readable error');
 assert.equal(powershellFailureMessage('x'.repeat(1000)).length,240);
});

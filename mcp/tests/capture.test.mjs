import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,readFile,readdir,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {CaptureHost,screenshotScript} from '../src/capture-host.mjs';
import {STUDIO_IMPORTER} from '../src/studio-importer.mjs';
import {TOOLS,validateArgs,BATCH_READ_TOOLS} from '../src/protocol.mjs';
import {HOST_CAPTURE_TOOLS} from '../src/capture-tools.mjs';
const sessionId='11111111-1111-4111-8111-111111111111';
const source='local text = "â˜ƒðŸ¦€"\nreturn text';
function fixture(){
 const session={id:sessionId,grants:{inspect:true,edit:false,execute:false},socket:{}};
 const content={nodes:Array.from({length:29},(_,i)=>({id:'i'+i,name:'Same',className:'Folder',properties:{}})),scripts:[{instanceId:'i0',offset:1,sourceKind:'readable',source,totalBytes:Buffer.byteLength(source)}],assets:[{instanceId:'i0',property:'Image',value:'rbxassetid://123'}]};
 const calls=[];const broker={resolve(id){assert.ok(!id||id===sessionId);return session;},summaries(){return [{connected:true}];},async execute(name,args){
  calls.push({name,args});
  if(name==='dex_get_camera')return {state:'completed',result:{properties:{FieldOfView:70},scope:'client'}};
  if(name==='dex_get_capture')return {state:'completed',result:{captureId:'capture1',name:'Shop',kind:'system',roots:['i0'],counts:{nodes:29}}};
  assert.equal(name,'dex_read_capture');const items=content[args.section]||[];const end=Math.min(items.length,args.offset-1+args.limit);
  return {state:'completed',result:{captureId:'capture1',section:args.section,items:items.slice(args.offset-1,end),offset:args.offset,total:items.length,nextOffset:end<items.length?end+1:undefined}};
 }};return {broker,content,calls,session};
}
test('exports page all capture sections, preserve UTF-8 source and provide portable importer with hashes',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'dex-capture-test-'));t.after(()=>rm(directory,{recursive:true,force:true}));
 const {broker,calls}=fixture();const host=new CaptureHost(broker,{directory});
 const exported=await host.exportCapture({sessionId,captureId:'capture1'});
 const capture=JSON.parse(await readFile(join(exported.directory,'capture.json'),'utf8'));
 assert.equal(capture.format,'dex-plus-capture');assert.equal(capture.nodes.length,29);assert.equal(capture.scripts[0].source,source);
 assert.equal(await readFile(join(exported.directory,'script-i0.luau'),'utf8'),source);
 assert.equal(await readFile(join(exported.directory,'StudioCaptureImporter.luau'),'utf8'),STUDIO_IMPORTER);
 assert.ok(calls.some(c=>c.args.section==='nodes'&&c.args.offset===26));
 assert.ok(exported.files.every(f=>/^[a-f0-9]{64}$/.test(f.sha256)));
 let offset=0,collected='';const script=exported.files.find(f=>f.name==='script-i0.luau');
 while(offset!==undefined){const chunk=await host.read({exportId:exported.exportId,file:script.name,offset,bytes:7});collected+=chunk.text;offset=chunk.nextOffset;}
 assert.equal(collected,source);assert.equal(host.list().exports.length,1);
 await assert.rejects(host.read({exportId:exported.exportId,file:'../capture.json'}),/exact filename/);
 await assert.rejects(host.read({exportId:exported.exportId,file:script.name,offset:999999}),/beyond/);
});
test('incomplete source export is cleaned up and non-advancing pages are rejected',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'dex-capture-errors-'));t.after(()=>rm(directory,{recursive:true,force:true}));
 const {broker,content}=fixture();const host=new CaptureHost(broker,{directory});content.scripts[0].offset=2;
 await assert.rejects(host.exportCapture({captureId:'capture1'}),/missing or overlap/);assert.deepEqual(await readdir(directory),[]);assert.equal(host.list().exports.length,0);
 const original=broker.execute;broker.execute=async(name,args)=>name==='dex_read_capture'?{state:'completed',result:{items:[{}],offset:args.offset,total:2,nextOffset:args.offset}}:original(name,args);
 await assert.rejects(host.exportCapture({captureId:'capture1'}),/cursor/);
 const signal=AbortSignal.abort();await assert.rejects(host.exportCapture({captureId:'capture1'},signal),/cancelled/);
});
test('optional image export saves PNG bytes and separate non-atomic camera metadata',async t=>{
 const directory=await mkdtemp(join(tmpdir(),'dex-capture-image-'));t.after(()=>rm(directory,{recursive:true,force:true}));
 const {broker}=fixture();const png='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==';
 const host=new CaptureHost(broker,{directory,screen:async()=>({data:png,width:1,height:1,processId:123})});
 const exported=await host.exportCapture({captureId:'capture1',includeScreenshot:true});
 assert.deepEqual(await readFile(join(exported.directory,'reference.png')),Buffer.from(png,'base64'));
 const metadata=JSON.parse(await readFile(join(exported.directory,'reference-camera.json'),'utf8'));assert.equal(metadata.nonAtomic,true);assert.equal(metadata.camera.properties.FieldOfView,70);
 await assert.rejects(host.read({exportId:exported.exportId,file:'reference.png'}),/PNG path/);
});
test('screenshots require connected Inspect session, reject ambiguous clients and return image separately from metadata',async()=>{
 const {broker,session}=fixture();let called=0;
 const host=new CaptureHost(broker,{screen:async args=>{called++;assert.equal(args.processId,123);return {data:'iVBORw0KGgoFAKE',width:800,height:600,processId:123};}});
 session.socket=null;await assert.rejects(host.screenshot({}),/Connect Dex/);session.socket={};
 broker.summaries=()=>[{connected:true},{connected:true}];await assert.rejects(host.screenshot({}),/Multiple/);assert.equal(called,0);
 const picture=await host.screenshot({processId:123});assert.equal(picture.image.type,'image');assert.equal(picture.image.mimeType,'image/png');assert.ok(!JSON.stringify(picture.metadata).includes('iVBOR'));assert.equal(picture.metadata.camera.properties.FieldOfView,70);assert.equal(picture.metadata.sessionProcessIdentityVerified,false);
 assert.throws(()=>screenshotScript({processId:'1;exit'}),/parameters/);
 const script=screenshotScript({processId:123});assert.match(script,/RobloxPlayerBeta/);assert.doesNotMatch(script,/SetForegroundWindow|Start-Process|RobloxStudioBeta|VirtualScreen/);
});
test('capture tools have strict bounded schemas and importer bundle matches the shipped source',async()=>{
 assert.equal(TOOLS.length,136);assert.equal(HOST_CAPTURE_TOOLS.length,4);
 validateArgs('dex_capture_system',{instanceIds:['i1'],maxNodes:5000},sessionId);
 assert.throws(()=>validateArgs('dex_capture_system',{maxNodes:5001},sessionId),/5000/);
 assert.throws(()=>validateArgs('dex_read_capture',{captureId:'c',section:'anything'},sessionId));
 const source=await readFile(new URL('../static/StudioCaptureImporter.luau',import.meta.url),'utf8');assert.equal(STUDIO_IMPORTER,source);
});

 test('client log tools use inspect, normal session targeting and strict bounded literal filters',()=>{
  assert.equal(TOOLS.find(t=>t.name==='dex_get_logs').grant,'inspect');
  assert.equal(TOOLS.find(t=>t.name==='dex_clear_logs').grant,'inspect');
  validateArgs('dex_get_logs',{afterSequence:0,limit:200,level:'warning',text:'a.b'},sessionId);
  validateArgs('dex_clear_logs',{},sessionId);
  for(const args of [{afterSequence:-1},{afterSequence:1.5},{afterSequence:Number.MAX_SAFE_INTEGER+1},{limit:201},{level:'server'},{text:'x'.repeat(1025)},{regex:'.*'}])assert.throws(()=>validateArgs('dex_get_logs',args,sessionId));
  assert.throws(()=>validateArgs('dex_clear_logs',{clearOutput:true},sessionId));
 });

test('inspection tools are Inspect-only with bounded schemas and normal session targets',()=>{
 const names=['dex_inspect_instances','dex_query_instances','dex_get_ui_at_point','dex_world_to_screen','dex_screen_to_ray','dex_query_parts','dex_get_assembly','dex_get_playing_animations','dex_get_sound_state','dex_get_lighting'];
 for(const name of names)assert.equal(TOOLS.find(t=>t.name===name).grant,'inspect');
 validateArgs('dex_inspect_instances',{instanceIds:['i1'],properties:['Anchored'],includeTags:true},sessionId);
 validateArgs('dex_query_instances',{rootId:'i1',tags:['A'],attributes:{Ready:false},properties:{Anchored:false},maxNodes:5000},sessionId);
 validateArgs('dex_get_ui_at_point',{x:10,y:20},sessionId);
 validateArgs('dex_world_to_screen',{positions:[{type:'Vector3',x:0,y:1,z:2}],coordinateSpace:'viewport'},sessionId);
 validateArgs('dex_query_parts',{shape:'radius',center:{type:'Vector3',x:0,y:0,z:0},radius:20},sessionId);
 for(const [name,args]of [['dex_inspect_instances',{instanceIds:Array(21).fill('i1')}],['dex_query_instances',{maxNodes:5001}],['dex_get_ui_at_point',{x:Infinity,y:0}],['dex_world_to_screen',{positions:[]}],['dex_screen_to_ray',{x:0,y:0,coordinateSpace:'desktop'}],['dex_query_parts',{shape:'radius',radius:-1}],['dex_get_assembly',{instanceId:'i1',limit:101}],['dex_get_playing_animations',{instanceId:'i1',limit:51}],['dex_get_sound_state',{rootId:'i1',playingOnly:'yes'}],['dex_get_lighting',{unknown:true}]])assert.throws(()=>validateArgs(name,args,sessionId));
 assert.throws(()=>validateArgs('dex_get_lighting',{sessionId:'22222222-2222-4222-8222-222222222222'},sessionId),/another Dex session/);
});

test('comparison and diagnostics tools preserve Inspect grants and strict bounds/session schemas',()=>{
 for(const name of ['dex_compare_instances','dex_summarize_hierarchy','dex_validate_references','dex_get_ui_diagnostics','dex_get_text_metrics','dex_get_character_state','dex_get_input_state','dex_get_runtime_stats'])assert.equal(TOOLS.find(t=>t.name===name).grant,'inspect');
 validateArgs('dex_compare_instances',{leftId:'i1',rightId:'i2',properties:['Name'],includeAttributes:false},sessionId);
 validateArgs('dex_summarize_hierarchy',{rootId:'i1',maxNodes:10000,topClasses:50},sessionId);
 validateArgs('dex_validate_references',{rootId:'i1',limit:100},sessionId);
 validateArgs('dex_get_ui_diagnostics',{instanceId:'i1'},sessionId);
 validateArgs('dex_get_text_metrics',{instanceId:'i1'},sessionId);
 validateArgs('dex_get_character_state',{userId:0},sessionId);
 validateArgs('dex_get_input_state',{},sessionId);validateArgs('dex_get_runtime_stats',{},sessionId);
 for(const [name,args]of [['dex_compare_instances',{leftId:'i1',rightId:'i2',properties:Array(33).fill('Name')}],['dex_summarize_hierarchy',{rootId:'i1',maxNodes:10001}],['dex_validate_references',{rootId:'i1',limit:101}],['dex_get_ui_diagnostics',{}],['dex_get_text_metrics',{instanceId:'i1',text:'mutate'}],['dex_get_character_state',{userId:-1}],['dex_get_input_state',{record:true}],['dex_get_runtime_stats',{server:true}]])assert.throws(()=>validateArgs(name,args,sessionId));
 assert.throws(()=>validateArgs('dex_get_runtime_stats',{sessionId:'22222222-2222-4222-8222-222222222222'},sessionId),/another Dex session/);
});

test('testing tools validate declarative predicates and every nested read before dispatch',async()=>{
 assert.equal(TOOLS.length,136);
 const target={instanceId:'i1'};
 validateArgs('dex_wait_for_condition',{condition:{kind:'property',target,name:'Anchored',expected:false},timeoutSeconds:20},sessionId);
 validateArgs('dex_wait_for_condition',{condition:{kind:'exists',target:{rootId:'i1',path:['A','B']}}},sessionId);
 validateArgs('dex_assert_conditions',{checks:[{label:'absent',condition:{kind:'attribute',target,name:'Missing',expected:{type:'nil'}}}]},sessionId);
 validateArgs('dex_batch_read',{requests:[{command:'dex_get_properties',args:{instanceId:'i1',properties:['Name']}},{command:'dex_get_logs',args:{limit:10}}]},sessionId);
 for(const [name,args]of [['dex_wait_for_condition',{condition:{kind:'exists',target},timeoutSeconds:21}],['dex_wait_for_condition',{condition:{kind:'exists',target},pollIntervalSeconds:.01}],['dex_wait_for_condition',{condition:{kind:'property',target,name:'X'}}],['dex_wait_for_condition',{condition:{kind:'property',target,name:'X',expected:null}}],['dex_wait_for_condition',{condition:{kind:'exists',target:{rootId:'i1',path:Array(17).fill('x')}}}],['dex_assert_conditions',{checks:Array(33).fill({condition:{kind:'exists',target}})}],['dex_batch_read',{requests:[{command:'dex_get_properties',args:{instanceId:'i1',properties:'invalid'}}]}],['dex_batch_read',{requests:[{command:'dex_get_instance',args:{instanceId:'i1',sessionId}}]}],['dex_batch_read',{requests:[{command:'dex_get_instance',args:{instanceId:'i1',commandId:'11111111-1111-4111-8111-111111111111'}}]}],['dex_batch_read',{requests:Array(9).fill({command:'dex_get_session'})}]])assert.throws(()=>validateArgs(name,args,sessionId));
 for(const command of ['dex_set_properties','dex_run_luau','dex_invoke_remote','dex_batch_read','dex_wait_for_condition','dex_clear_logs','dex_watch_instance','dex_read_script','dex_capture_system'])assert.throws(()=>validateArgs('dex_batch_read',{requests:[{command,args:{}}]},sessionId));
 for(const name of BATCH_READ_TOOLS)assert.equal(TOOLS.find(t=>t.name===name)?.grant,'inspect');
 const runtime=await readFile(new URL('../../src/Apps/AIBridge/Services/BridgeTestCommands.lua',import.meta.url),'utf8');
 const declaration=runtime.match(/local readable\s*=\s*\{([^}]+)\}/)[1];
 const names=[...declaration.matchAll(/\["(dex_[a-z_]+)"\]\s*=\s*true/g)].map(m=>m[1]);
 assert.deepEqual(names.sort(),[...BATCH_READ_TOOLS].sort(),'MCP and runtime must enforce the same batch allowlist');
});

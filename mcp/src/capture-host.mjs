import {randomUUID,createHash} from 'node:crypto';
import {mkdir,mkdtemp,writeFile,open,rm} from 'node:fs/promises';
import {homedir} from 'node:os';
import {join} from 'node:path';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {BridgeError} from './protocol.mjs';
import {STUDIO_IMPORTER} from './studio-importer.mjs';

const runFile=promisify(execFile);
const sections=['nodes','scripts','assets','relationships','changes','events','markers'];
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const safeId=id=>String(id).replace(/[^a-zA-Z0-9_-]/g,'_').slice(0,80);
const checkAbort=signal=>{if(signal?.aborted)throw new BridgeError('cancelled','Capture operation cancelled');};

export class CaptureHost{
 constructor(broker,{directory,screen=captureForegroundPlayer}={}){
  this.broker=broker;this.directory=directory||process.env.DEX_PLUS_EXPORT_DIR||join(homedir(),'Documents','Dex Explorer Captures');this.exports=new Map();this.screen=screen;this.busy=false;
 }
 async request(name,args,signal){
  checkAbort(signal);const response=await this.broker.execute(name,args,signal);
  if(response.state!=='completed')throw new BridgeError('capture_read_failed',response.error?.message||'Dex could not read the capture');
  return response.result;
 }
 async exportCapture(args,signal){
  if(this.busy)throw new BridgeError('busy','Another export is being written');
  if(this.exports.size>=32)throw new BridgeError('export_limit','Dex MCP keeps at most 32 export records; files already saved remain on disk');
  this.busy=true;let folder;
  try{
   const session=this.broker.resolve(args.sessionId);const context={sessionId:session.id,captureId:args.captureId};
   const metadata=await this.request('dex_get_capture',context,signal);
   const document={format:'dex-plus-capture',version:1,...metadata};
   let totalBytes=0;
   for(const section of sections){
    const items=[];let offset=1;let expected;
    do{
     const page=await this.request('dex_read_capture',{...context,section,offset,limit:25},signal);
     if(!Array.isArray(page.items)||page.offset!==offset||!Number.isSafeInteger(page.total)||page.total<0||page.total>100000)throw new BridgeError('invalid_capture','Invalid capture page');
     if(expected!==undefined&&expected!==page.total)throw new BridgeError('capture_changed','Capture changed during export');expected=page.total;
     totalBytes+=Buffer.byteLength(JSON.stringify(page.items));
     if(totalBytes>16*1024*1024)throw new BridgeError('export_limit','Export exceeds 16 MiB');
     items.push(...page.items);
     const next=page.nextOffset;
     if(next!==undefined&&next!==null&&(!Number.isSafeInteger(next)||next!==offset+page.items.length||next<=offset))throw new BridgeError('invalid_capture','Invalid capture cursor');
     offset=next;
    }while(offset!==undefined&&offset!==null);
    if(items.length!==expected)throw new BridgeError('incomplete_capture','Capture page count did not match');
    document[section]=items;
   }
   const picture=args.includeScreenshot?await this.screenshot({...args,sessionId:session.id},signal):null;
   checkAbort(signal);
   await mkdir(this.directory,{recursive:true});folder=await mkdtemp(join(this.directory,'capture-'));
   const files=[];
   const put=async(name,content)=>{
    const bytes=Buffer.from(content,'utf8');await writeFile(join(folder,name),bytes,{flag:'wx'});files.push({name,path:join(folder,name),bytes:bytes.length,sha256:hash(bytes)});
   };
   await put('capture.json',JSON.stringify(document,null,2));await put('StudioCaptureImporter.luau',STUDIO_IMPORTER);
   await put('assets.json',JSON.stringify(document.assets,null,2));
   if(picture){await put('reference.png',Buffer.from(picture.image.data,'base64'));await put('reference-camera.json',JSON.stringify(picture.metadata,null,2));}
   const byScript=new Map();
   for(const part of document.scripts){
    if(typeof part.instanceId!=='string'||typeof part.source!=='string'||!Number.isSafeInteger(part.offset)||!Number.isSafeInteger(part.totalBytes))throw new BridgeError('invalid_capture','Invalid source chunk');
    const chunks=byScript.get(part.instanceId)||[];chunks.push(part);byScript.set(part.instanceId,chunks);
   }
   for(const [id,chunks]of byScript){
    checkAbort(signal);chunks.sort((a,b)=>a.offset-b.offset);let offset=1;const source=[];
    for(const chunk of chunks){if(chunk.offset!==offset||chunk.totalBytes!==chunks[0].totalBytes)throw new BridgeError('incomplete_source','Source chunks are missing or overlap');source.push(chunk.source);offset+=Buffer.byteLength(chunk.source);}
    if(offset-1!==chunks[0].totalBytes)throw new BridgeError('incomplete_source','Source length does not match');
    await put(`script-${safeId(id)}.luau`,source.join(''));
   }
   await put('README.txt',`Dex Explorer reference capture: ${metadata.name}\n\nThis contains client-visible evidence, not a complete server or asset export.\nRead coverage in capture.json before relying on completeness.\n\nStudio import (performed explicitly by you or your Studio MCP):\n1. Load StudioCaptureImporter.luau as a ModuleScript, or evaluate its contents to obtain Importer.\n2. Call Importer.FromJson(captureJson, explicitDestinationInstance, {includeSource=false}).\n3. Inspect the returned container and report. Internal Instance links are restored by captured ID.\n4. External links need an explicit options.externalMap[capturedId]=studioInstance.\n5. Services become named Folders inside the import container. Move their children to the appropriate services.\n6. Set includeSource=true only when you intend to copy the captured code; BaseScripts stay disabled.\n\nNo Studio window was opened, and no import/source execution was performed during export.\nAsset IDs are references; their availability and permissions may differ in another place.\n`);
   const exportId=randomUUID();const record={exportId,sessionId:session.id,captureId:args.captureId,name:metadata.name,createdAt:new Date().toISOString(),directory:folder,files};
   await put('manifest.json',JSON.stringify({...record,files:[...files]},null,2));
   this.exports.set(exportId,record);return record;
  }catch(error){if(folder)await rm(folder,{recursive:true,force:true});throw error;}finally{this.busy=false;}
 }
 list(){return {exports:[...this.exports.values()]};}
 async read(args){
  const item=this.exports.get(args.exportId);const file=item?.files.find(f=>f.name===args.file);
  if(!file)throw new BridgeError('export_unavailable','Choose an exact filename from the Dex MCP export list');
  if(file.name.endsWith('.png'))throw new BridgeError('binary_file','Use the exported PNG path to view this image; dex_read_export reads text files');
  const offset=args.offset||0,maximum=args.bytes||24000;
  if(offset>file.bytes)throw new BridgeError('invalid_offset','Offset is beyond the file');
  const handle=await open(file.path,'r');
  try{
   const buffer=Buffer.alloc(Math.min(maximum+4,file.bytes-offset));const {bytesRead}=await handle.read(buffer,0,buffer.length,offset);
   let end=Math.min(maximum,bytesRead);
   while(end<bytesRead&&end>0&&(buffer[end]&0xc0)===0x80)end--;
   if(end===0&&bytesRead>0)throw new BridgeError('invalid_offset','Offset splits a UTF-8 character');
   if(bytesRead>0&&(buffer[0]&0xc0)===0x80)throw new BridgeError('invalid_offset','Offset splits a UTF-8 character');
   return {exportId:item.exportId,file:file.name,offset,bytes:end,totalBytes:file.bytes,text:buffer.subarray(0,end).toString('utf8'),nextOffset:offset+end<file.bytes?offset+end:undefined};
  }finally{await handle.close();}
 }
 async screenshot(args,signal){
  const session=this.broker.resolve(args.sessionId);
  if(!session.grants.inspect||!session.socket)throw new BridgeError('not_connected','Connect Dex with Inspect access first');
  if(this.broker.summaries().filter(s=>s.connected).length>1&&!args.processId)throw new BridgeError('ambiguous_player','Multiple Dex sessions are connected; provide the foreground Roblox Player processId');
  const camera=await this.request('dex_get_camera',{sessionId:session.id},signal);checkAbort(signal);
  const screen=await this.screen(args);checkAbort(signal);
  if(!screen||typeof screen.data!=='string'||screen.data.length>16*1024*1024||!screen.data.startsWith('iVBORw0KGgo'))throw new BridgeError('capture_failed','Screenshot did not produce a bounded PNG');
  const {data,...metadata}=screen;
  return {image:{type:'image',data,mimeType:'image/png'},metadata:{...metadata,sessionId:session.id,camera,nonAtomic:true,sessionProcessIdentityVerified:false,note:'Visible foreground Roblox Player client area. Camera and pixels are captured separately; this process is not cryptographically bound to the Dex session.'}};
 }
}

// Constant script with numeric-only parameters. No shell interpolation of game data.
export function screenshotScript({processId=0,maxDimension=1600}={}){
 if(!Number.isSafeInteger(processId)||processId<0||!Number.isSafeInteger(maxDimension)||maxDimension<320||maxDimension>2048)throw new BridgeError('invalid_arguments','Invalid screenshot parameters');
 return `$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class DexCaptureWindow {
 [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left,Top,Right,Bottom; }
 [StructLayout(LayoutKind.Sequential)] public struct Point { public int X,Y; }
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h,out Rect r);
 [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h,ref Point p);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr v);
}
'@
[void][DexCaptureWindow]::SetProcessDpiAwarenessContext([IntPtr](-4))
$window=[DexCaptureWindow]::GetForegroundWindow()
$playerId=[uint32]0
[void][DexCaptureWindow]::GetWindowThreadProcessId($window,[ref]$playerId)
$player=Get-Process -Id $playerId
if($player.ProcessName -ne 'RobloxPlayerBeta'){throw 'Bring the Roblox Player window to the foreground before capturing'}
if(${processId} -ne 0 -and $playerId -ne ${processId}){throw 'Foreground player does not match the requested processId'}
if([DexCaptureWindow]::IsIconic($window)){throw 'Roblox Player is minimized'}
$rect=New-Object DexCaptureWindow+Rect
$origin=New-Object DexCaptureWindow+Point
if(-not [DexCaptureWindow]::GetClientRect($window,[ref]$rect) -or -not [DexCaptureWindow]::ClientToScreen($window,[ref]$origin)){throw 'Could not read player client bounds'}
$width=$rect.Right; $height=$rect.Bottom
if($width -lt 1 -or $height -lt 1 -or $width -gt 8192 -or $height -gt 8192 -or [long]$width*$height -gt 34000000){throw 'Unsupported client dimensions'}
$bitmap=New-Object System.Drawing.Bitmap($width,$height)
$graphics=[System.Drawing.Graphics]::FromImage($bitmap)
$output=$null; $stream=New-Object System.IO.MemoryStream
try {
 if([DexCaptureWindow]::GetForegroundWindow() -ne $window){throw 'Foreground window changed; capture was cancelled'}
 $graphics.CopyFromScreen($origin.X,$origin.Y,0,0,$bitmap.Size)
 if([DexCaptureWindow]::GetForegroundWindow() -ne $window){throw 'Foreground window changed during capture'}
 $ratio=[Math]::Min(1.0,${maxDimension}/[double][Math]::Max($width,$height))
 $outWidth=[Math]::Max(1,[int]($width*$ratio)); $outHeight=[Math]::Max(1,[int]($height*$ratio))
 $output=New-Object System.Drawing.Bitmap($outWidth,$outHeight)
 $scaled=[System.Drawing.Graphics]::FromImage($output)
 try {$scaled.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $scaled.DrawImage($bitmap,0,0,$outWidth,$outHeight)} finally {$scaled.Dispose()}
 $output.Save($stream,[System.Drawing.Imaging.ImageFormat]::Png)
 @{data=[Convert]::ToBase64String($stream.ToArray());processId=$playerId;width=$outWidth;height=$outHeight;clientWidth=$width;clientHeight=$height;scale=$ratio;capturedAt=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json -Compress
} finally {$graphics.Dispose();$bitmap.Dispose();if($output){$output.Dispose()};$stream.Dispose()}
`;
}
export async function captureForegroundPlayer(args){
 if(process.platform!=='win32')throw new BridgeError('unsupported_platform','Foreground Roblox screenshots currently require Windows');
 try{
  const encoded=Buffer.from(screenshotScript(args),'utf16le').toString('base64');
  const {stdout}=await runFile('powershell.exe',['-NoProfile','-NonInteractive','-EncodedCommand',encoded],{windowsHide:true,encoding:'utf8',timeout:15000,maxBuffer:24*1024*1024});return JSON.parse(stdout);
 }catch(error){throw new BridgeError('capture_unavailable',String(error.stderr||error.message).replace(/\r?\n[\s\S]*/,'').slice(0,300));}
}

// Foreground-only Windows client capture. Only numeric parameters enter the generated script.
import {spawn} from 'node:child_process';
import {BridgeError} from './protocol.mjs';
export function recordingScript({processId=0,durationSeconds=8,fps=5,maxDimension=960}={}){
 if(!Number.isSafeInteger(processId)||processId<0||processId>2147483647||!Number.isSafeInteger(durationSeconds)||durationSeconds<1||durationSeconds>20||!Number.isSafeInteger(fps)||fps<1||fps>10||!Number.isSafeInteger(maxDimension)||maxDimension<320||maxDimension>1280)throw new BridgeError('invalid_arguments','Invalid screen recording parameters');
 return `$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$stage='native_setup'
$bitmap=$null;$output=$null;$graphics=$null;$scaled=$null;$stream=$null;$parameters=$null;$watch=$null
try {
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class DexRecordingWindow {
 public static volatile bool StopRequested;
 public static void StartControl() {
  var thread=new System.Threading.Thread(()=>{try { Console.ReadLine(); } catch {} StopRequested=true;});
  thread.IsBackground=true; thread.Start();
 }
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
[void][DexRecordingWindow]::SetProcessDpiAwarenessContext([IntPtr](-4))
$stage='window_check'
[DexRecordingWindow]::StartControl()
$focusDeadline=[DateTime]::UtcNow.AddSeconds(8)
while($true){
 if([DexRecordingWindow]::StopRequested){throw 'Recording cancelled before capture started'}
 $window=[DexRecordingWindow]::GetForegroundWindow()
 $playerId=[uint32]0
 [void][DexRecordingWindow]::GetWindowThreadProcessId($window,[ref]$playerId)
 $player=$null
 if($playerId -gt 0){$player=Get-Process -Id $playerId -ErrorAction SilentlyContinue}
 if($null -ne $player -and $player.ProcessName -eq 'RobloxPlayerBeta' -and (${processId} -eq 0 -or $playerId -eq ${processId})){break}
 if([DateTime]::UtcNow -ge $focusDeadline){
  if($null -ne $player -and $player.ProcessName -eq 'RobloxPlayerBeta'){throw 'Foreground Roblox Player does not match the requested processId'}
  throw 'Bring Roblox Player to the foreground within 8 seconds of starting a recording, then retry'
 }
 Start-Sleep -Milliseconds 100
}
if([DexRecordingWindow]::IsIconic($window)){throw 'Roblox Player is minimized'}
$rect=New-Object DexRecordingWindow+Rect
$origin=New-Object DexRecordingWindow+Point
if(-not [DexRecordingWindow]::GetClientRect($window,[ref]$rect) -or -not [DexRecordingWindow]::ClientToScreen($window,[ref]$origin)){throw 'Could not read player client bounds'}
$width=$rect.Right; $height=$rect.Bottom
if($width -lt 1 -or $height -lt 1 -or $width -gt 8192 -or $height -gt 8192 -or [long]$width*$height -gt 34000000){throw 'Unsupported client dimensions'}
$ratio=[Math]::Min(1.0,${maxDimension}/[double][Math]::Max($width,$height))
$outWidth=[Math]::Max(1,[int][Math]::Floor($width*$ratio)); $outHeight=[Math]::Max(1,[int][Math]::Floor($height*$ratio))
$stage='capture_setup'
$bitmap=New-Object System.Drawing.Bitmap($width,$height)
$output=New-Object System.Drawing.Bitmap($outWidth,$outHeight)
$graphics=[System.Drawing.Graphics]::FromImage($bitmap)
$scaled=[System.Drawing.Graphics]::FromImage($output)
$scaled.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
$stream=New-Object System.IO.MemoryStream
$encoder=[System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.MimeType -eq 'image/jpeg'} | Select-Object -First 1
$parameters=New-Object System.Drawing.Imaging.EncoderParameters(1)
$parameters.Param[0]=New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality,[long]65)
$watch=[System.Diagnostics.Stopwatch]::StartNew()
$reason='duration'; $count=0
$stage='capture'
 while($watch.Elapsed.TotalSeconds -lt ${durationSeconds} -and $count -lt ${durationSeconds*fps}){
  if([DexRecordingWindow]::StopRequested){$reason='stop_requested';break}
  if([DexRecordingWindow]::GetForegroundWindow() -ne $window){$reason='foreground_changed';break}
  if([DexRecordingWindow]::IsIconic($window)){$reason='window_minimized';break}
  $currentId=[uint32]0
  [void][DexRecordingWindow]::GetWindowThreadProcessId($window,[ref]$currentId)
  if($currentId -ne $playerId){$reason='process_changed';break}
  $before=New-Object DexRecordingWindow+Point; $bounds=New-Object DexRecordingWindow+Rect
  if(-not [DexRecordingWindow]::GetClientRect($window,[ref]$bounds) -or -not [DexRecordingWindow]::ClientToScreen($window,[ref]$before)){$reason='window_unavailable';break}
  if($bounds.Right -ne $width -or $bounds.Bottom -ne $height){$reason='window_resized';break}
  $graphics.CopyFromScreen($before.X,$before.Y,0,0,$bitmap.Size)
  $after=New-Object DexRecordingWindow+Point; $afterBounds=New-Object DexRecordingWindow+Rect
  if([DexRecordingWindow]::GetForegroundWindow() -ne $window){$reason='foreground_changed';break}
  if(-not [DexRecordingWindow]::GetClientRect($window,[ref]$afterBounds) -or -not [DexRecordingWindow]::ClientToScreen($window,[ref]$after)){$reason='window_unavailable';break}
  if($after.X -ne $before.X -or $after.Y -ne $before.Y -or $afterBounds.Right -ne $width -or $afterBounds.Bottom -ne $height){$reason='window_changed_during_frame';break}
  $scaled.DrawImage($bitmap,0,0,$outWidth,$outHeight)
  $stream.SetLength(0);$stream.Position=0
  $output.Save($stream,$encoder,$parameters)
  if($stream.Length -gt 1048576){$reason='frame_byte_limit';break}
  if([DexRecordingWindow]::StopRequested){$reason='stop_requested';break}
  if([DexRecordingWindow]::GetForegroundWindow() -ne $window){$reason='foreground_changed';break}
  $finalId=[uint32]0
  [void][DexRecordingWindow]::GetWindowThreadProcessId($window,[ref]$finalId)
  if($finalId -ne $playerId){$reason='process_changed';break}
  $record=@{type='frame';data=[Convert]::ToBase64String($stream.ToArray());processId=[int]$playerId;windowId=$window.ToInt64().ToString();width=$outWidth;height=$outHeight;clientWidth=$width;clientHeight=$height;scale=$ratio;elapsedMs=$watch.Elapsed.TotalMilliseconds;capturedAt=[DateTime]::UtcNow.ToString('o')}
  [Console]::Out.WriteLine(($record|ConvertTo-Json -Compress));[Console]::Out.Flush()
  $count++
  $due=$count*1000.0/${fps};$delay=[Math]::Max(0,[int]($due-$watch.Elapsed.TotalMilliseconds))
  if($delay -gt 0){Start-Sleep -Milliseconds $delay}
 }
 [Console]::Out.WriteLine((@{type='ended';reason=$reason;frames=$count}|ConvertTo-Json -Compress));[Console]::Out.Flush()
} catch {
 [Console]::Out.WriteLine((@{type='error';stage=$stage;message=$_.Exception.Message.Substring(0,[Math]::Min(1024,$_.Exception.Message.Length))}|ConvertTo-Json -Compress));[Console]::Out.Flush()
 exit 1
} finally {
 if($null -ne $watch){$watch.Stop()}
 foreach($resource in @($parameters,$stream,$scaled,$graphics,$output,$bitmap)){if($null -ne $resource){try{$resource.Dispose()}catch{}}}
}
`;
}
// Legacy/parse-time PowerShell failures can still arrive as CLIXML. Only read its
// error strings; progress records and formatting headers are not error messages.
export function powershellFailureMessage(stderr){
 const value=String(stderr||'');
 const xmlError=/<S\b(?=[^>]*\bS=["']Error["'])[^>]*>([\s\S]*?)<\/S>/gi;
 const entries=[...value.matchAll(xmlError)].map(match=>match[1]
  .replace(/&(?:lt|gt|quot|apos|amp);|&#(?:x[0-9a-f]+|[0-9]+);/gi,entity=>{
   const known={'&lt;':'<','&gt;':'>','&quot;':'"','&apos;':"'",'&amp;':'&'};
   if(known[entity.toLowerCase()])return known[entity.toLowerCase()];
   const hex=entity[2]?.toLowerCase()==='x',code=Number.parseInt(entity.slice(hex?3:2,-1),hex?16:10);
   return code<=0x10ffff?String.fromCodePoint(code):'?';
  }).replace(/_x([0-9a-f]{4})_/gi,(_,hex)=>String.fromCharCode(parseInt(hex,16))));
 const lines=(entries.length?entries.join('\n'):value.includes('#< CLIXML')?'':value).split(/\r?\n/);
 return (lines.map(line=>line.trim()).find(line=>line&&!/^#< CLIXML|^<\/?(?:Objs|Obj)\b|^At line:|^\s*[+~]/i.test(line))||'Capture helper failed without a readable error').slice(0,240);
}
export async function recordForegroundPlayer(args,{signal,onFrame,spawnHelper=spawn}={}){
 if(process.platform!=='win32')throw new BridgeError('unsupported_platform','Screen recording currently requires Windows');
 const encoded=Buffer.from(recordingScript(args),'utf16le').toString('base64');
 const child=spawnHelper('powershell.exe',['-NoProfile','-NonInteractive','-InputFormat','Text','-OutputFormat','Text','-EncodedCommand',encoded],{windowsHide:true,stdio:['pipe','pipe','pipe']});
 let stderr='',pending='',ended,helperError,stopSent=false,killTimer,deadlineExpired=false;
 const stop=()=>{if(stopSent)return;stopSent=true;if(child.stdin.writable)child.stdin.end('stop\n');killTimer=setTimeout(()=>child.kill(),1500);killTimer.unref?.();};
 const abort=()=>stop();signal?.addEventListener('abort',abort,{once:true});if(signal?.aborted)stop();
 child.stdin.on('error',()=>{});child.stderr.on('data',chunk=>{if(stderr.length<65536)stderr+=chunk.toString('utf8').slice(0,65536-stderr.length);});
 const closed=new Promise(resolve=>{child.once('error',error=>resolve({error}));child.once('close',code=>resolve({code}));});
 const deadline=setTimeout(()=>{deadlineExpired=true;stop();},(args.durationSeconds??8)*1000+12000);deadline.unref?.();
 async function consume(line){
  if(!line.trim())return;let item;try{item=JSON.parse(line);}catch{throw new BridgeError('recording_failed','Capture helper returned invalid frame metadata');}
  if(item.type==='error'){
   if(typeof item.message!=='string'||!item.message.trim()||item.message.length>1024||!['native_setup','window_check','capture_setup','capture'].includes(item.stage))throw new BridgeError('recording_failed','Capture helper returned invalid error metadata');
   helperError=new BridgeError('recording_unavailable',`${item.stage}: ${item.message.replace(/\s+/g,' ').trim()}`.slice(0,240));return;
  }
  if(item.type==='ended'){ended=item.reason;return;}
  if(item.type!=='frame'||typeof item.data!=='string'||item.data.length>1400000)throw new BridgeError('invalid_frame','Capture helper returned an invalid or oversized frame');
  if(!signal?.aborted)await onFrame(item);
 }
 try{
  for await(const chunk of child.stdout){
   pending+=chunk.toString('utf8');
   let boundary;while((boundary=pending.indexOf('\n'))>=0){const line=pending.slice(0,boundary);pending=pending.slice(boundary+1);if(line.length>1500000)throw new BridgeError('invalid_frame','Capture helper frame exceeds its limit');await consume(line);}
   if(pending.length>1500000)throw new BridgeError('invalid_frame','Capture helper output exceeds its limit');
  }
  if(pending.trim())await consume(pending);
  const exit=await closed;
  if(helperError&&!signal?.aborted)throw helperError;
  if(exit.error||exit.code!==0&&!signal?.aborted)throw new BridgeError('recording_unavailable',powershellFailureMessage(stderr||exit.error?.message));
  return {reason:deadlineExpired?'helper_timeout':signal?.aborted?'stop_requested':ended||'helper_ended'};
 }catch(error){stop();await closed;throw error;}
 finally{clearTimeout(deadline);clearTimeout(killTimer);signal?.removeEventListener('abort',abort);child.stdin.destroy();if(child.exitCode===null)child.kill();}
}

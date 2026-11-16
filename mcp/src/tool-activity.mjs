import {randomUUID} from 'node:crypto';

const sensitiveKey=/token|password|credential|secret|authorization|^(api|access|pairing)?key$|pairingcode/i;
const secretText=/(?:\d{4,5}\.)?dx(?:pair|wt|p|b|a)_[\w-]{16,}|\bBearer\s+[\w.+=/-]{16,}/gi;

function cleanText(value,limit){
 return value.slice(0,limit+256).replace(secretText,'[redacted]').slice(0,limit).toWellFormed();
}

export function activityPreview(value){
 let remaining=5500;
 function preview(item,depth){
  if(remaining<=0)return '[more omitted]';
  if(typeof item==='string'){
   const limit=Math.min(2000,remaining);
   remaining-=Math.min(item.length,limit);
   return cleanText(item,limit)+(item.length>limit?'…':'');
  }
  if(!item||typeof item!=='object'){remaining-=8;return item;}
  if(depth>=4)return Array.isArray(item)?'[list omitted]':'[object omitted]';
  const array=Array.isArray(item),out=array?[]:Object.create(null);
  let count=0;
  for(const key in item){
   if(count++===24||remaining<=0){
    if(array)out.push('[more omitted]');else out['…']='[more omitted]';
    break;
   }
   const label=cleanText(key,120);
   remaining-=label.length+4;
   const field=sensitiveKey.test(key.replaceAll(/[_-]/g,''))?'[redacted]':preview(item[key],depth+1);
   if(array)out.push(field);else out[label]=field;
  }
  return out;
 }
 return value===undefined?undefined:JSON.stringify(preview(value,0),null,2);
}

export function createToolActivity(broker){
 return async function track(name,args,invoke,owner){
  const targets=broker.policyTargets(owner?{sessionId:owner}:args);
  const session=targets.length===1&&targets[0].toolControls?targets[0]:undefined;
  const socket=session?.socket;
  const id=socket&&randomUUID(),time=Date.now();
  const emit=(state,details)=>{
   if(socket&&session.socket===socket)broker.send(socket,{type:'tool_activity',id,name,state,time,...details});
  };
  try{
   broker.assertToolEnabled(name,targets);
   if(socket)emit('running',{request:activityPreview(args)});
   const response=await invoke();
   if(socket){
    const data=response.structuredContent;
    const problem=data?.error??(response.isError?data?.result?.error:undefined);
    emit(response.isError?'failed':'completed',{
     duration:Date.now()-time,result:activityPreview(data),
     error:typeof problem==='string'?cleanText(problem,350):typeof problem?.message==='string'?cleanText(problem.message,350):undefined,
     commandId:data?.commandId,
    });
   }
   return response;
  }catch(error){
   if(socket)emit(['command_disabled','bridge_paused'].includes(error.code)?'blocked':'failed',{
    duration:Date.now()-time,request:activityPreview(args),
    error:cleanText(String(error.message||'Command failed'),350),
   });
   throw error;
  }
 };
}

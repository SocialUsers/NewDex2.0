// Minimal indexed AVI 1.0 / Motion-JPEG writer; no external encoder dependency.
import {open} from 'node:fs/promises';
import {BridgeError} from './protocol.mjs';
const four=value=>Buffer.from(value,'ascii');
const chunk=(name,data)=>Buffer.concat([four(name),u32(data.length),data,...(data.length%2?[Buffer.alloc(1)]:[])]);
const u32=value=>{const b=Buffer.alloc(4);b.writeUInt32LE(value);return b;};
const list=(name,parts)=>chunk('LIST',Buffer.concat([four(name),...parts]));
function header(width,height,fps,count,maxFrame,moviBytes){
 const avih=Buffer.alloc(56);avih.writeUInt32LE(Math.round(1000000/fps),0);avih.writeUInt32LE(maxFrame*fps,4);avih.writeUInt32LE(0x10,12);avih.writeUInt32LE(count,16);avih.writeUInt32LE(1,24);avih.writeUInt32LE(maxFrame,28);avih.writeUInt32LE(width,32);avih.writeUInt32LE(height,36);
 const strh=Buffer.alloc(56);four('vids').copy(strh);four('MJPG').copy(strh,4);strh.writeUInt32LE(1,20);strh.writeUInt32LE(fps,24);strh.writeUInt32LE(count,32);strh.writeUInt32LE(maxFrame,36);strh.writeUInt32LE(0xffffffff,40);strh.writeInt16LE(width,52);strh.writeInt16LE(height,54);
 const strf=Buffer.alloc(40);strf.writeUInt32LE(40);strf.writeInt32LE(width,4);strf.writeInt32LE(height,8);strf.writeUInt16LE(1,12);strf.writeUInt16LE(24,14);four('MJPG').copy(strf,16);strf.writeUInt32LE(width*height*3,20);
 const hdrl=list('hdrl',[chunk('avih',avih),list('strl',[chunk('strh',strh),chunk('strf',strf)])]);
 const movi=Buffer.concat([four('LIST'),u32(4+moviBytes),four('movi')]);
 const idxBytes=8+count*16;
 return Buffer.concat([four('RIFF'),u32(4+hdrl.length+movi.length+moviBytes+idxBytes),four('AVI '),hdrl,movi]);
}
export function jpegDimensions(data){
 if(!Buffer.isBuffer(data)||data.length<4||data[0]!==255||data[1]!==216||data.at(-2)!==255||data.at(-1)!==217)throw new BridgeError('invalid_frame','Invalid JPEG frame');
 let pos=2;
 while(pos<data.length-2){
  if(data[pos++]!==255)throw new BridgeError('invalid_frame','Invalid JPEG marker');
  while(data[pos]===255)pos++;
  const marker=data[pos++];if(marker===0xda||marker===0xd9)break;
  if(marker===0x01||marker>=0xd0&&marker<=0xd7)continue;
  if(pos+2>data.length)break;const length=data.readUInt16BE(pos);if(length<2||pos+length>data.length)break;
  if([0xc0,0xc1,0xc2].includes(marker)&&length>=8){const height=data.readUInt16BE(pos+3),width=data.readUInt16BE(pos+5);if(width&&height)return {width,height};}
  pos+=length;
 }
 throw new BridgeError('invalid_frame','JPEG dimensions are unavailable');
}
export class MjpegAvi{
 static async create(path,{width,height,fps,maxFrames=200,maxBytes=32*1024*1024}){
  if(![width,height,fps,maxFrames].every(Number.isSafeInteger)||width<1||height<1||Math.max(width,height)>1280||fps<1||fps>10||maxFrames<1||maxFrames>200)throw new BridgeError('invalid_arguments','Invalid AVI dimensions or limits');
  const writer=new MjpegAvi();Object.assign(writer,{width,height,fps,maxFrames,maxBytes,index:[],moviBytes:0,maxFrame:0,closed:false,frames:0});
  writer.initial=header(width,height,fps,0,0,0);writer.position=writer.initial.length;
  writer.file=await open(path,'wx');try{await writer.write(writer.initial);}catch(error){await writer.file.close();throw error;}return writer;
 }
 async write(data,position){let used=0;while(used<data.length){const value=await this.file.write(data,used,data.length-used,position===undefined?null:position+used);if(!value.bytesWritten)throw new Error('AVI write stalled');used+=value.bytesWritten;}}
 async append(data){
  if(this.closed)throw new BridgeError('recording_closed','AVI is finalized');
  const shape=jpegDimensions(data);if(shape.width!==this.width||shape.height!==this.height)throw new BridgeError('invalid_frame','Frame dimensions changed');
  const bytes=8+data.length+(data.length%2);
  if(this.frames>=this.maxFrames||this.position+bytes+8+(this.frames+1)*16>this.maxBytes)throw new BridgeError('recording_limit','Video frame or byte budget reached');
  await this.write(chunk('00dc',data),this.position);this.index.push({offset:4+this.moviBytes,size:data.length});this.moviBytes+=bytes;this.position+=bytes;this.maxFrame=Math.max(this.maxFrame,data.length);this.frames++;
 }
 async finish(){
  if(this.closed)return;this.closed=true;
  try{
   const index=Buffer.alloc(this.frames*16);for(let i=0;i<this.index.length;i++){const p=i*16;four('00dc').copy(index,p);index.writeUInt32LE(0x10,p+4);index.writeUInt32LE(this.index[i].offset,p+8);index.writeUInt32LE(this.index[i].size,p+12);}
   await this.file.truncate(this.position);await this.write(chunk('idx1',index),this.position);await this.write(header(this.width,this.height,this.fps,this.frames,this.maxFrame,this.moviBytes),0);await this.file.sync();
  }finally{await this.file.close();}
 }
 get bytes(){return this.position+8+this.frames*16;}
}

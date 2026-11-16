import {serveStdio} from '@modelcontextprotocol/server/stdio';
import {Broker} from './broker.mjs';
import {createMcpServer} from './server.mjs';

const broker=await new Broker().start();
const handle=serveStdio(()=>createMcpServer(broker),{onerror:()=>console.error('[Dex MCP] MCP transport error')});
let stopping=false;
async function stop(){if(stopping)return;stopping=true;await broker.close();await handle.close();}
process.stdin.once('end',()=>{void stop();});
process.once('SIGINT',()=>{void stop();});
process.once('SIGTERM',()=>{void stop();});
// stdout is reserved exclusively for JSON-RPC. No pairing keys are logged.
console.error('[Dex MCP] Ready. Ask the AI to call dex_create_pairing.');

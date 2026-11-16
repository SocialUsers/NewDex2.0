import {build} from 'esbuild';
import {readdir,readFile,mkdir,writeFile} from 'node:fs/promises';
import {resolve,join,basename} from 'node:path';
import {pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {TOOLS} from '../src/protocol.mjs';

const revision='367e5e15a0661b2309088cc77377bff47254c939';
if(!process.argv[2])throw new Error('Pass the pinned, built upstream checkout');
const upstream=resolve(process.argv[2]);
if(execFileSync('git',['-C',upstream,'rev-parse','HEAD'],{encoding:'utf8'}).trim()!==revision)throw new Error('Unexpected upstream revision');
const root=join(upstream,'dist','tools');
const {allTools}=await import(pathToFileURL(join(root,'index.js')));
const existing=new Set(TOOLS.map(tool=>tool.name));
const nameOf=tool=>'dex_'+tool.name.replaceAll('-','_');
const equivalents=new Map(Object.entries({
 'get-players':'dex_list_players','get-local-player-info':'dex_get_character_state','discover-character':'dex_get_character_state',
 'get-place-details':'dex_get_session','get-game-info':'dex_get_session','get-instance-tree':'dex_get_tree',
 'get-instance-properties':'dex_get_properties','get-script-content':'dex_read_script','get-console-output':'dex_get_logs',
 'search-instances':'dex_find_instances','list-attributes':'dex_get_attributes','watch-instance-property':'dex_watch_instance',
 'diff-instance-snapshot':'dex_compare_instances','compare-instances':'dex_compare_instances',
 'set-instance-property':'dex_set_properties','set-attribute':'dex_set_attributes','set-properties-bulk':'dex_set_properties',
 'create-instance':'dex_create_instances','clone-instance':'dex_duplicate_instances','destroy-instance':'dex_delete_instances',
 'camera-control':'dex_set_camera','capture-log-output':'dex_get_logs','watch-property-changes':'dex_watch_instance',
 'get-memory-stats':'dex_get_runtime_stats','get-render-stats':'dex_get_runtime_stats','execute':'dex_run_luau',
 'execute-and-wait':'dex_run_luau','execute-file':'dex_load_file',
 'list-clients':'dex_list_sessions','bridge-status':'dex_list_sessions','session-list':'dex_list_sessions',
 'monitor-remote':'dex_watch_remote','trace-remote-traffic':'dex_get_remote_events','screenshot-window':'dex_capture_screenshot',
}));
const catalog=allTools();
const hostNames=new Map([['list-tools','dex_list_tools'],['suggest-tools','dex_suggest_tools'],['tool-schema','dex_tool_schema']]);
const excluded=new Set(['ensure-remote-spy','get-remote-spy-logs','clear-remote-spy-logs','block-remote','ignore-remote','remote-spy','configure-remote-spy']);
const selected=new Map(catalog.filter(tool=>!existing.has(nameOf(tool))&&!equivalents.has(tool.name)&&!hostNames.has(tool.name)&&!excluded.has(tool.name)).map(tool=>[tool.name,tool]));
const imports=[];
const values=[];
const candidates=(await readdir(root,{recursive:true})).filter(name=>name.endsWith('.js')&&!['index.js'].includes(basename(name)));
for(const name of candidates.sort((a,b)=>Number(basename(a).startsWith('_'))-Number(basename(b).startsWith('_')))){
 const url=pathToFileURL(join(root,name));
 const exports=await import(url);
 for(const [key,value] of Object.entries(exports)){
  const tools=Array.isArray(value)?value:[value];
  const found=tools.map((tool,index)=>({tool,index})).filter(({tool})=>tool&&selected.get(tool.name)===tool);
  if(!found.length)continue;
  const local='module'+imports.length;
  imports.push(`import { ${key} as ${local} } from ${JSON.stringify(join(root,name))};`);
  for(const {tool,index} of found){
   values.push(Array.isArray(value)?`${local}[${index}]`:local);
   selected.delete(tool.name);
  }
 }
}
if(selected.size)throw new Error('Unresolved imported tools: '+[...selected.keys()].join(', '));
await mkdir('third-party/executor-mcp',{recursive:true});
await build({stdin:{contents:imports.join('\n')+'\nexport const importedTools=['+values.join(',')+'];\nexport {FsSavedScriptsStore} from '+JSON.stringify(join(upstream,'dist/infrastructure/playbooks/fs-saved-scripts.js'))+';\nexport {InMemorySemanticIndex} from '+JSON.stringify(join(upstream,'dist/infrastructure/semantic/in-memory-semantic-index.js'))+';\nexport {HttpEmbeddingsProvider} from '+JSON.stringify(join(upstream,'dist/infrastructure/semantic/http-embeddings-provider.js'))+';',resolveDir:process.cwd()},outfile:'third-party/executor-mcp/tools.mjs',bundle:true,platform:'node',format:'esm',minify:true,external:['zod','zod/*'],plugins:[{name:'dex-luau-compat',setup(builder){
 builder.onLoad({filter:/send-packet[.]js$/},async ({path})=>{
  const source=await readFile(path,'utf8');
  const before='local hex = ${q(dataHex)}:gsub("%s", "")';
  if(!source.includes(before))throw new Error('Upstream packet source changed');
  return {contents:source.replace(before,'local hex = string.gsub(${q(dataHex)}, "%s", "")'),loader:'js'};
 });
 builder.onLoad({filter:/session-replay[.]js$/},async ({path})=>{
  const source=await readFile(path,'utf8');
  const before='const blocked = MUTATING_GUARD.has(r.tool);';
  if(!source.includes(before))throw new Error('Upstream replay guard changed');
  return {contents:source
   .replace(before,'const blocked = ctx.tools.find(r.tool)?.mutatesState ?? true;')
   .replace('wouldRun: !blocked,','wouldRun: !blocked || includeMutating === true,'),loader:'js'};
 });
 builder.onLoad({filter:/script-preflight[.]js$/},async ({path})=>{
  const source=await readFile(path,'utf8');
  const before='if (written === "call")';
  if(!source.includes(before))throw new Error('Upstream script preflight changed');
  return {contents:source.replace(before,'if (["call", "all", "parallel", "help"].includes(written))'),loader:'js'};
 });
}}]});
await writeFile('third-party/executor-mcp/LICENSE',await readFile(join(upstream,'LICENSE')));
const inventory=catalog.map(tool=>{
 const dex=existing.has(nameOf(tool))?nameOf(tool):equivalents.get(tool.name)||hostNames.get(tool.name);
 return {upstream:tool.name,dex:dex||(excluded.has(tool.name)?null:nameOf(tool)),status:dex?'native':excluded.has(tool.name)?'excluded':'imported'};
});
for(const [upstream,dex] of hostNames)if(!inventory.some(tool=>tool.upstream===upstream))inventory.push({upstream,dex,status:'native'});
await writeFile('third-party/executor-mcp/catalog.json',JSON.stringify({revision,registered:inventory.length,tools:inventory},null,2)+'\n');
console.log('Imported',values.length,'of',catalog.length);

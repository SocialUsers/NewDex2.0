import {createHash,randomBytes} from 'node:crypto';
import * as z from 'zod/v4';
import {captureTools} from './capture-tools.mjs';

export const VERSION=1;
export const LIMITS=Object.freeze({body:128*1024,result:256*1024,queue:16,sessionHours:4,sessions:8,commandMs:30000});
export const digest=value=>createHash('sha256').update(value).digest('hex');
export const token=prefix=>prefix+randomBytes(32).toString('base64url');
export class BridgeError extends Error { constructor(code,message,status=400){super(message);this.code=code;this.status=status;} }
export const fail=(code,message,status=400)=>{throw new BridgeError(code,message,status);};
export const json=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'}});
export const bearer=request=>{const value=request.headers.get('authorization')||'';return /^Bearer [A-Za-z0-9_-]{20,200}$/.test(value)?value.slice(7):null;};
export const id=z.string().min(1).max(160);
const ids=z.array(id).min(1).max(100);
const strings=z.array(z.string().min(1).max(200)).max(64);
const map=z.record(z.string().min(1).max(200),z.unknown());
const empty={};
const definition=(name,description,grant,shape)=>({name,description,grant,schema:z.strictObject({...shape,sessionId:z.uuid().optional(),commandId:z.uuid().optional()})});
export const BATCH_READ_TOOLS=Object.freeze(["dex_get_session","dex_get_capabilities","dex_get_tree","dex_find_instances","dex_get_instance","dex_get_selection","dex_get_properties","dex_get_attributes","dex_get_tags","dex_get_history","dex_list_players","dex_get_player","dex_get_camera","dex_get_run","dex_resolve_path","dex_get_ancestors","dex_get_class_schema","dex_get_bounds","dex_get_ui_layout","dex_raycast","dex_get_job","dex_list_watches","dex_get_remote_info","dex_list_remotes","dex_get_call","dex_list_calls","dex_list_remote_watches","dex_list_captures","dex_get_capture","dex_read_capture","dex_get_capture_assets","dex_get_capture_relationships","dex_inspect_instances","dex_get_ui_at_point","dex_world_to_screen","dex_screen_to_ray","dex_query_parts","dex_get_lighting","dex_compare_instances","dex_get_ui_diagnostics","dex_get_text_metrics","dex_get_character_state","dex_get_input_state","dex_get_runtime_stats","dex_get_logs"]);
const conditionTarget=z.union([z.strictObject({instanceId:id}),z.strictObject({rootId:id,path:z.array(z.string().min(1).max(128)).max(16)})]);
const comparisonOp=z.enum(['eq','ne','lt','lte','gt','gte','contains']);
const expectedValue=z.unknown().refine(value=>value!==undefined&&value!==null,'Expected is required; use {type:"nil"} for nil');
const condition=z.discriminatedUnion('kind',[
 z.strictObject({kind:z.literal('exists'),target:conditionTarget,expected:z.boolean().optional()}),
 z.strictObject({kind:z.literal('property'),target:conditionTarget,name:z.string().min(1).max(128),expected:expectedValue,op:comparisonOp.optional(),tolerance:z.number().finite().min(0).max(1000000).optional()}),
 z.strictObject({kind:z.literal('attribute'),target:conditionTarget,name:z.string().min(1).max(128),expected:expectedValue,op:comparisonOp.optional(),tolerance:z.number().finite().min(0).max(1000000).optional()}),
 z.strictObject({kind:z.literal('tag'),target:conditionTarget,name:z.string().min(1).max(128),expected:z.boolean().optional()}),
 z.strictObject({kind:z.literal('class'),target:conditionTarget,className:z.string().min(1).max(128)}),
 z.strictObject({kind:z.literal('child_count'),target:conditionTarget,expected:z.number().int().min(0).max(10000),op:z.enum(['eq','ne','lt','lte','gt','gte']).optional(),tolerance:z.number().finite().min(0).max(1000000).optional()}),
]);
export const TOOLS=[
 definition('dex_wait_for_condition','Start a cancellable client condition wait job; poll dex_get_job. Supports exact handle or unambiguous root/path, existence, property/attribute, tag, class and direct-child count. Typed values, literal contains, numeric tolerance. Timeout default5/max20 seconds, polling default0.1/min0.05 seconds; zero timeout makes one immediate check. No scripts/listeners.','inspect',{condition,timeoutSeconds:z.number().finite().min(0).max(20).optional(),pollIntervalSeconds:z.number().finite().min(.05).max(1).optional()}),
 definition('dex_assert_conditions','Evaluate 1–32 declarative client assertions now, returning passed/failed/unavailable, expected vs actual and aggregate counts. Unavailable does not pass; typed nil/false preserved. Non-atomic bounded snapshot, no code execution.','inspect',{checks:z.array(z.strictObject({label:z.string().max(100).optional(),condition})).min(1).max(32)}),
 definition('dex_batch_read','Run 1–8 allowlisted read commands in this session, with individual results/errors. No edits, remotes, code, job creation, clearing/cancelling, nested batches or nested session/command IDs. Sequential/non-atomic; 48KiB conservative response budget, default5/max10 second cooperative budget. Oversized results omitted explicitly; native calls cannot be forcibly timed out.','inspect',{requests:z.array(z.strictObject({command:z.enum(BATCH_READ_TOOLS),args:map.optional()})).min(1).max(8),stopOnError:z.boolean().optional(),timeoutSeconds:z.number().finite().min(.05).max(10).optional()}),
 definition('dex_compare_instances','Compare two client-visible objects with typed property/attribute/tag differences. Default properties are canonical metadata intersection (Source excluded). Unavailable reads are explicit, not equal; false/nil preserved, output bounded.','inspect',{leftId:id,rightId:id,properties:z.array(z.string().min(1).max(128)).min(1).max(32).optional(),includeAttributes:z.boolean().optional(),includeTags:z.boolean().optional()}),
 definition('dex_summarize_hierarchy','Start a bounded hierarchy summary job (dex_get_job): class counts, scripts/geometry, depth and duplicate sibling-name groups with exact parent IDs. Includes root and reports partial coverage; no exhaustive GetDescendants scan.','inspect',{rootId:id,maxNodes:z.number().int().min(1).max(10000).optional(),topClasses:z.number().int().min(1).max(50).optional()}),
 definition('dex_validate_references','Start a bounded structural-reference inspection job (dex_get_job) for values, primary parts, joints, attachments and adornments. Nil/outside-root links are informational candidates, not automatically errors. No script execution/decompilation.','inspect',{rootId:id,maxNodes:z.number().int().min(1).max(5000).optional(),limit:z.number().int().min(1).max(100).optional()}),
 definition('dex_get_ui_diagnostics','Explain one game GuiObject layout/visibility with ancestor state, clipping intersections and relevant layout/constraint components. Bounded per-field evidence with warnings; rotated clipping is approximate and no semantic clickability guarantee is made.','inspect',{instanceId:id}),
 definition('dex_get_text_metrics','Read actual engine TextBounds/TextFits and font/wrapping/scaling state for one text GUI. Plain legacy-font measurement only where supported; custom-font/rich/scaled limitations and property errors are explicit. Does not modify text.','inspect',{instanceId:id}),
 definition('dex_get_character_state','Read a client-visible player character, Humanoid movement/health/state, root physics and equipped tools. Defaults to LocalPlayer. Missing/unreplicated character reported explicitly; no manipulation or server authority.','inspect',{userId:z.number().int().min(0).max(Number.MAX_SAFE_INTEGER).optional()}),
 definition('dex_get_input_state','Read current client input capabilities, mouse position, up to64 pressed keys, and allowed focused game textbox identity. No textbox content, synthetic input, recording or listeners.','inspect',empty),
 definition('dex_get_runtime_stats','Read client memory totals/categories, run flags and Workspace physics/streaming state with timestamps and individual errors. Optional physics FPS is not rendered-frame FPS; no server statistics or background sampling.','inspect',empty),
 definition('dex_inspect_instances','Read 1–20 exact objects with up to 16 properties each, optional attributes/tags, individual errors and bounded output. Typed nil/false preserved; no decompilation. Client-visible only.','inspect',{instanceIds:z.array(id).min(1).max(20),properties:z.array(z.string().min(1).max(128)).min(1).max(16).optional(),includeAttributes:z.boolean().optional(),includeTags:z.boolean().optional()}),
 definition('dex_query_instances','Start a bounded client hierarchy query job (dex_get_job). Root is included; class uses IsA, name is literal substring, all tags/typed attribute/property equality predicates are ANDed. Default 2000/max5000 visited nodes, max100 matches, explicit truncation; no evaluated code.','inspect',{rootId:id.optional(),className:z.string().min(1).max(128).optional(),name:z.string().min(1).max(256).optional(),caseSensitive:z.boolean().optional(),tags:z.array(z.string().min(1).max(128)).max(8).optional(),attributes:map.optional(),properties:map.optional(),limit:z.number().int().min(1).max(100).optional(),maxNodes:z.number().int().min(1).max(5000).optional()}),
 definition('dex_get_ui_at_point','Read native game GUI hit stacks at client screen pixels x/y, excluding Dex UI. Returns inset-adjusted query point and container-specific order, not guaranteed cross-container order or semantic clickability. CoreGui is opt-in; access errors reported.','inspect',{x:z.number().finite().min(-100000).max(100000),y:z.number().finite().min(-100000).max(100000),includeCoreGui:z.boolean().optional(),limit:z.number().int().min(1).max(50).optional()}),
 definition('dex_world_to_screen','Project 1–64 typed Vector3 world positions with the current client camera. Returns pixel coordinates, depth and on-screen flags; coordinateSpace selects native screen (default, GUI inset) or viewport convention.','inspect',{positions:z.array(map).min(1).max(64),coordinateSpace:z.enum(['screen','viewport']).optional()}),
 definition('dex_screen_to_ray','Convert current client camera screen/viewport pixel coordinates to a typed world ray. Does not select or raycast; use dex_raycast with its origin/direction.','inspect',{x:z.number().finite().min(-100000).max(100000),y:z.number().finite().min(-100000).max(100000),coordinateSpace:z.enum(['screen','viewport']).optional()}),
 definition('dex_query_parts','Query client Workspace bounding-volume overlap candidates, not exact mesh collision. Shape box requires typed CFrame cframe and Vector3 size; radius requires Vector3 center and positive radius<=10000. Per-axis size<=20000, exclusions<=100, native results capped.','inspect',{shape:z.enum(['box','radius']),cframe:map.optional(),size:map.optional(),center:map.optional(),radius:z.number().finite().positive().max(10000).optional(),excludeIds:z.array(id).max(100).optional(),limit:z.number().int().min(1).max(100).optional()}),
 definition('dex_get_assembly','Start a client physics inspection job (dex_get_job) from one BasePart. Bounded direct-neighbor graph walk, assembly state and joints, with truncation and per-field errors; no recursive whole-assembly query or mutations.','inspect',{instanceId:id,limit:z.number().int().min(1).max(100).optional()}),
 definition('dex_get_playing_animations','Start a job inspecting client-visible playing animation tracks under an Animator/character root. Returns bounded track descriptors and asset IDs, not invented track handles. Does not play/load animations; get results with dex_get_job.','inspect',{instanceId:id,limit:z.number().int().min(1).max(50).optional(),maxNodes:z.number().int().min(1).max(5000).optional()}),
 definition('dex_get_sound_state','Start a client audio-state query job under rootId. Reads asset references, playback/loading/time/volume and spatial settings without playing/loading audio. Use dex_get_job; scanning and output are capped.','inspect',{rootId:id,playingOnly:z.boolean().optional(),limit:z.number().int().min(1).max(100).optional(),maxNodes:z.number().int().min(1).max(5000).optional()}),
 definition('dex_get_lighting','Read a bounded snapshot of client Lighting and immediate Sky/Atmosphere/post-effects with typed values and per-property errors. Does not change environment or imply server state.','inspect',empty),
 definition('dex_get_logs','Read bounded client-only output, warnings and errors captured while Dex MCP is connected; no server logs. Poll afterSequence using the previous nextSequence (last examined entry). Filters: exact level and case-sensitive literal text. timestamp is Unix milliseconds; droppedSinceCursor reports lost entries, droppedMessages is cumulative across overflow/clear/teardown. Large messages/pages are capped.','inspect',{afterSequence:z.number().int().min(0).max(Number.MAX_SAFE_INTEGER).optional(),limit:z.number().int().min(1).max(200).optional(),level:z.enum(['output','info','warning','error']).optional(),text:z.string().max(1024).optional()}),
 definition('dex_clear_logs',"Clear only Dex MCP's client log buffer, never Roblox Output. Sequence IDs keep increasing. Returns the cleared count and a new polling cursor.",'inspect',empty),
 definition('dex_get_session','Inspect the connected Dex game/client session. Data is client-visible, not server authority.','inspect',empty),
 definition('dex_get_capabilities','Get the live Dex command names and runtime capabilities.','inspect',empty),
 definition('dex_get_tree','Read a bounded hierarchy page; instance IDs survive rename and reparent.','inspect',{rootId:id.optional(),cursor:z.string().max(300).optional(),limit:z.number().int().min(1).max(200).optional(),depth:z.number().int().min(1).max(8).optional()}),
 definition('dex_find_instances','Search client-visible instance names/classes without changing Explorer search.','inspect',{name:z.string().max(200).optional(),className:z.string().max(100).optional(),rootId:id.optional(),cursor:z.string().max(300).optional(),limit:z.number().int().min(1).max(200).optional()}),
 definition('dex_get_instance','Read one instance summary, identity and provenance.','inspect',{instanceId:id}),
 definition('dex_get_selection','Read the actual Explorer selection.','inspect',empty),
 definition('dex_set_selection','Set, add or remove Explorer selection using exact instance IDs.','edit',{instanceIds:z.array(id).max(100),mode:z.enum(['set','add','remove']).optional()}),
 definition('dex_get_properties','Read properties with typed Roblox values and per-property errors.','inspect',{instanceId:id,properties:strings.optional()}),
 definition('dex_set_properties','Edit supported instance properties in Dex history.','edit',{instanceIds:ids,properties:map}),
 definition('dex_get_attributes','Read instance attributes.','inspect',{instanceId:id}),
 definition('dex_set_attributes','Edit attributes; use {type:"nil"} to remove an attribute.','edit',{instanceIds:ids,attributes:map}),
 definition('dex_get_tags','Read CollectionService tags.','inspect',{instanceId:id}),
 definition('dex_set_tags','Add/remove/replace instance tags through Dex history.','edit',{instanceIds:ids,tags:strings,mode:z.enum(['add','remove','replace']).optional()}),
 definition('dex_create_instances','Create an insertable class under an exact parent, with optional initial properties.','edit',{className:z.string().min(1).max(100),parentId:id,name:z.string().min(1).max(200).optional(),properties:map.optional()}),
 definition('dex_reparent_instances','Move instances to an exact parent; parent cycles are rejected.','edit',{instanceIds:ids,parentId:id}),
 definition('dex_delete_instances','Remove instances using reversible Dex history where supported.','edit',{instanceIds:ids}),
 definition('dex_transform_instances','Move/rotate/scale selected geometry through Dex transforms. Vector3: {type:"Vector3",x,y,z}; rotate units are degrees.','edit',{instanceIds:ids,operation:z.enum(['move','rotate','scale']),value:z.union([z.number().finite(),map]),space:z.enum(['World','Local']).optional()}),
 definition('dex_get_history','Read undo/redo position and transaction names.','inspect',empty),
 definition('dex_undo','Undo an existing Dex history transaction using the exact index and head returned by dex_get_history.','edit',{expectedIndex:z.number().int().min(0),expectedHead:id}),
 definition('dex_redo','Redo an existing Dex history transaction using the exact index and head returned by dex_get_history.','edit',{expectedIndex:z.number().int().min(0),expectedHead:id}),
 definition('dex_list_players','List client-visible players.','inspect',empty),
 definition('dex_get_player','Inspect a player and their locally visible character.','inspect',{userId:z.number().int().min(0).optional()}),
 definition('dex_move_local_player','Request a local character position. Server/physics may override it.','edit',{position:map}),
 definition('dex_get_camera','Inspect the local client camera.','inspect',empty),
 definition('dex_set_camera','Set supported local camera properties using typed values.','edit',{properties:map}),
 definition('dex_run_luau','Execute explicit Luau in the client/executor context. Not sandboxed or generally undoable; blocking native calls cannot be guaranteed cancellable.','execute',{source:z.string().min(1).max(64000),vm:z.enum(['persistent','reset']).optional(),vmKey:z.string().min(1).max(96).optional()}),
 definition('dex_get_run','Read a Luau run result and bounded output.','inspect',{runId:id}),
 definition('dex_resolve_path','Resolve exact child-name path segments; returns every duplicate-name match.','inspect',{rootId:id.optional(),segments:z.array(z.string().min(1).max(512)).max(32)}),
 definition('dex_get_ancestors','Read the parent chain of an exact object.','inspect',{instanceId:id}),
 definition('dex_get_class_schema','Read inherited property names/types and read-only flags for a Roblox class.','inspect',{className:z.string().min(1).max(128)}),
 definition('dex_rename_instance','Rename one exact object through Dex history.','edit',{instanceId:id,name:z.string().min(1).max(512)}),
 definition('dex_duplicate_instances','Clone up to 20 independent roots (2000 total instances), with undoable parenting.','edit',{instanceIds:z.array(id).min(1).max(20),parentId:id.optional()}),
 definition('dex_get_bounds','Read combined bounds and pivot for Workspace parts/models.','inspect',{instanceIds:ids,space:z.enum(['World','Local']).optional()}),
 definition('dex_set_pivot','Set an unlocked part/model pivot to an absolute typed CFrame with undo.','edit',{instanceId:id,pivot:map}),
 definition('dex_get_ui_layout','Read GuiObject layout and resolved pixel bounds.','inspect',{instanceId:id}),
 definition('dex_set_ui_layout','Edit supported GuiObject Position/Size/Rotation/AnchorPoint/Visible/ZIndex/LayoutOrder properties. Layout constraints may override values.','edit',{instanceIds:ids,properties:map}),
 definition('dex_raycast','Cast a client-visible Workspace ray. Direction includes distance, at most15000 studs.','inspect',{origin:map,direction:map,excludeIds:z.array(id).max(100).optional(),ignoreWater:z.boolean().optional()}),
 definition('dex_save_camera','Save a session-local camera snapshot for later restoration.','inspect',empty),
 definition('dex_restore_camera','Restore a saved camera snapshot if the camera instance is unchanged.','edit',{snapshotId:id}),
 definition('dex_focus_camera','Frame the supplied Workspace geometry with the local camera; changes use history.','edit',{instanceIds:ids}),
 definition('dex_check_luau','Compile Luau and return syntax errors without executing it.','inspect',{source:z.string().min(1).max(64000)}),
 definition('dex_read_script','Start a job reading script lines. Decompiled source is approximate; decompile=true explicitly permits a potentially blocking native call. Use dex_get_job for results.','inspect',{instanceId:id,startLine:z.number().int().min(1).max(1000000).optional(),lineCount:z.number().int().min(1).max(400).optional(),decompile:z.boolean().optional()}),
 definition('dex_find_references','Start a bounded reference-search job; direct links are confirmed, script text/constants are candidates. bytecode=true opts into native bytecode reads.','inspect',{instanceId:id,bytecode:z.boolean().optional()}),
 definition('dex_get_job','Read a session-local analysis job status/result.','inspect',{jobId:id}),
 definition('dex_cancel_job','Cancel a cooperative analysis job. Blocking native calls cannot be guaranteed cancellable.','inspect',{jobId:id}),
 definition('dex_watch_instance','Start one of at most two bounded activity watches for an object and its descendants.','inspect',{instanceId:id}),
 definition('dex_list_watches','List active activity watches and event coverage.','inspect',empty),
 definition('dex_get_events','Read bounded property/attribute/ancestry events after a sequence ID. Dropped reports ring-buffer loss.','inspect',{watchId:id,afterId:z.number().int().min(0).optional(),limit:z.number().int().min(1).max(100).optional()}),
 definition('dex_stop_watch','Stop and release an activity watch.','inspect',{watchId:id}),
 definition('dex_draw_create','Create a session-owned Drawing overlay with typed Dex properties.','execute',{kind:z.enum(['Line','Text','Circle','Square','Quad','Triangle','Image']),properties:map.optional()}),
 definition('dex_draw_update','Update typed properties on one session-owned Drawing overlay.','execute',{drawingId:id,properties:map}),
 definition('dex_draw_remove','Remove one session-owned Drawing overlay.','execute',{drawingId:id}),
 definition('dex_draw_clear','Remove all Drawing overlays owned by this Dex session.','execute',empty),
 definition('dex_list_drawings','List Drawing overlay IDs owned by this Dex session.','inspect',empty),
 definition('dex_crypt_base64_encode','Base64 encode text using the client executor.','inspect',{data:z.string().max(8192)}),
 definition('dex_crypt_base64_decode','Decode Base64 and return text or a Base64 representation of binary output.','inspect',{data:z.string().max(8192)}),
 definition('dex_crypt_hash','Hash text using the client executor.','inspect',{data:z.string().max(8192),algorithm:z.enum(['sha1','sha256','sha384','sha512','md5']).optional()}),
 definition('dex_crypt_generate_bytes','Generate Base64 random bytes using the client executor.','inspect',{size:z.number().int().min(1).max(1024).optional()}),
 definition('dex_crypt_generate_key','Generate a symmetric key using the client executor.','inspect',empty),
 definition('dex_crypt_encrypt','Encrypt with the client executor using a supplied key and optional IV.','inspect',{data:z.string().max(8192),key:z.string().min(1).max(8192),iv:z.string().max(8192).optional(),mode:z.enum(['CBC','CTR']).optional()}),
 definition('dex_crypt_decrypt','Decrypt with the client executor using a supplied key and IV.','inspect',{data:z.string().max(8192),key:z.string().min(1).max(8192),iv:z.string().min(1).max(8192),mode:z.enum(['CBC','CTR']).optional()}),
 definition('dex_file_exists','Check whether a relative path in the Dex AI workspace is a file or folder.','execute',{path:z.string().min(1).max(180)}),
 definition('dex_list_files','List up to 200 entries in a Dex AI workspace folder.','execute',{path:z.string().min(1).max(180).optional()}),
 definition('dex_read_file','Read a UTF-8 text file from the Dex AI workspace.','execute',{path:z.string().min(1).max(180)}),
 definition('dex_write_file','Write or replace a UTF-8 text file in the Dex AI workspace.','execute',{path:z.string().min(1).max(180),text:z.string().max(64000)}),
 definition('dex_append_file','Append UTF-8 text to a file in the Dex AI workspace.','execute',{path:z.string().min(1).max(180),text:z.string().max(64000)}),
 definition('dex_make_folder','Create a folder in the Dex AI workspace.','execute',{path:z.string().min(1).max(180)}),
 definition('dex_delete_file','Delete one file in the Dex AI workspace.','execute',{path:z.string().min(1).max(180)}),
 definition('dex_delete_folder','Delete an empty folder in the Dex AI workspace.','execute',{path:z.string().min(1).max(180)}),
 definition('dex_get_custom_asset','Get an executor asset URI for a Dex AI workspace file.','execute',{path:z.string().min(1).max(180)}),
 definition('dex_load_file','Run a Luau text file from the Dex AI workspace. Use dex_get_run for the result.','execute',{path:z.string().min(1).max(180)}),
 definition('dex_get_gui_text','Read up to 2,048 characters from a text label, button, or input.','inspect',{instanceId:id}),
 definition('dex_set_gui_text','Set Text on a text label, button, or input as an undoable edit.','edit',{instanceId:id,text:z.string().max(2048)}),
 definition('dex_click_button','Fire a GUI button’s left or right click signal. Requires executor signal support and Run code.','execute',{instanceId:id,button:z.enum(['left','right']).optional()}),
 definition('dex_fire_click_detector','Trigger a ClickDetector with a left or right click. Requires Run code.','execute',{instanceId:id,button:z.enum(['left','right']).optional()}),
 definition('dex_fire_proximity_prompt','Trigger one ProximityPrompt. Requires Run code.','execute',{instanceId:id}),
 definition('dex_type_text_box','Focus a TextBox and replace its text. Set submit=true to release focus as Enter. Requires Run code.','execute',{instanceId:id,text:z.string().max(2048),submit:z.boolean().optional()}),
 definition('dex_get_executor_info','Report which optional executor APIs the new GUI and client tools can use.','inspect',empty),
 definition('dex_get_fps_cap','Read the executor’s local FPS cap.','inspect',empty),
 definition('dex_set_fps_cap','Set the executor’s local FPS cap. Use 0 to request uncapped. Requires Run code.','execute',{fpsCap:z.number().int().min(0).max(1000)}),
 definition('dex_set_clipboard','Copy text to the Roblox client’s system clipboard. Requires Run code.','execute',{text:z.string().max(2048)}),
 definition('dex_preview_instance','Open a part/model in the existing Dex 3D preview.','edit',{instanceId:id}),
 definition('dex_reveal_instance','Reveal an object in the Explorer without changing selection.','edit',{instanceId:id}),
 definition('dex_list_remotes','Discover RemoteEvents/Functions and optionally Bindables without invoking anything. Refine root/name if truncated.','inspect',{rootId:id.optional(),name:z.string().max(200).optional(),includeBindables:z.boolean().optional(),limit:z.number().int().min(1).max(200).optional()}),
 definition('dex_get_remote_info','Inspect endpoint class, exact identity and available operation. Argument contracts cannot be inferred from engine metadata.','inspect',{instanceId:id}),
 definition('dex_fire_remote','Explicitly call FireServer on one RemoteEvent/UnreliableRemoteEvent. Requires Run code. arguments is a positional tuple; use {type:"nil"} for nil slots and {type:"Table",entries:[{key:"x",value:1}]} for tables. Sent does not mean server accepted it. Never automatically retry.','execute',{instanceId:id,arguments:z.array(z.unknown()).max(64).optional()}),
 definition('dex_invoke_remote','Explicitly invoke one RemoteFunction on the server with typed positional arguments. Returns a callId immediately; use dex_get_call. Pending/slow does not mean cancelled or safe to retry. Requires Run code.','execute',{instanceId:id,arguments:z.array(z.unknown()).max(64).optional()}),
 definition('dex_fire_bindable','Fire one client-visible BindableEvent with typed positional arguments. Requires Run code; effects are not undoable.','execute',{instanceId:id,arguments:z.array(z.unknown()).max(64).optional()}),
 definition('dex_invoke_bindable','Invoke one client-visible BindableFunction; returns a callId for async result retrieval. Requires Run code.','execute',{instanceId:id,arguments:z.array(z.unknown()).max(64).optional()}),
 definition('dex_get_call','Get explicit remote/bindable call status, preserved nil/false returns and serialization errors. No replay.','inspect',{callId:id}),
 definition('dex_list_calls','List bounded metadata for calls made through this bridge. Use dex_get_call for full returns.','inspect',empty),
 definition('dex_watch_remote','Subscribe to incoming OnClientEvent or BindableEvent.Event. Does not hook outgoing game calls or replace function callbacks.','inspect',{instanceId:id}),
 definition('dex_get_remote_events','Retrieve bounded incoming event tuples and dropped count after a sequence cursor.','inspect',{watchId:id,afterId:z.number().int().min(0).optional(),limit:z.number().int().min(1).max(50).optional()}),
 definition('dex_stop_remote_watch','Disconnect one incoming-event subscription.','inspect',{watchId:id}),
 definition('dex_list_remote_watches','List bridge-owned incoming event subscriptions.','inspect',empty),
 definition('dex_apply_changes','Apply 1–16 tracked object edits as one history transaction with rollback on failure. Supports set_properties, set_attributes, set_tags, reparent_instances, rename_instance, set_pivot and set_ui_layout (full dex_ command names). No remotes or arbitrary code.','edit',{changes:z.array(z.strictObject({command:z.enum(['dex_set_properties','dex_set_attributes','dex_set_tags','dex_reparent_instances','dex_rename_instance','dex_set_pivot','dex_set_ui_layout']),args:map})).min(1).max(16)}),
 definition('dex_cancel_run','Request cancellation of an owned Luau run; cancellation is best effort.','execute',{runId:id}),
 ...captureTools(definition,id),
];
export const toolByName=new Map(TOOLS.map(t=>[t.name,t]));
// Validate nested reads with their existing strict schemas before dispatching a batch.
const batchTool=toolByName.get('dex_batch_read');
batchTool.schema=batchTool.schema.superRefine((value,ctx)=>{
 for(const [index,item]of value.requests.entries()){
  const args=item.args||{};
  if(Object.hasOwn(args,'sessionId')||Object.hasOwn(args,'commandId')){
   ctx.addIssue({code:'custom',path:['requests',index,'args'],message:'Nested sessionId/commandId are not supported'});continue;
  }
  const parsed=toolByName.get(item.command).schema.safeParse(args);
  if(!parsed.success)ctx.addIssue({code:'custom',path:['requests',index,'args'],message:parsed.error.issues.map(i=>i.path.join('.')+': '+i.message).join('; ').slice(0,400)});
 }
});
export const grantsSchema=z.strictObject({inspect:z.literal(true),edit:z.boolean(),execute:z.boolean()});
export const registrationSchema=z.strictObject({grants:grantsSchema,info:z.strictObject({placeId:z.union([z.string().max(30),z.number().finite()]).optional(),jobId:z.string().max(100).optional(),userId:z.union([z.string().max(30),z.number().finite()]).optional(),displayName:z.string().max(120).optional(),release:z.string().max(120).optional()})});
export function validateArgs(name,args,sessionId){
 const tool=toolByName.get(name);if(!tool)fail('unknown_tool','Unknown Dex command');
 const parsed=tool.schema.safeParse(args||{});if(!parsed.success)fail('invalid_arguments',parsed.error.issues.map(i=>i.path.join('.')+': '+i.message).join('; ').slice(0,800));
 const {sessionId:requested,commandId,...payload}=parsed.data;
 if(requested&&requested!==sessionId)fail('wrong_session','This connection key belongs to another Dex session',403);
 validateJson(payload);
 return {tool,args:payload,commandId};
}
export function validateJson(value,depth=0,count={n:0}){
 if(depth>16||++count.n>10000)fail('value_limit','Value exceeds depth or collection limits');
 if(typeof value==='number'&&!Number.isFinite(value))fail('invalid_value','Numbers must be finite');
 if(value&&typeof value==='object')for(const [key,item]of Object.entries(value)){
  if(['__proto__','prototype','constructor'].includes(key))fail('invalid_value','Reserved object key');
  validateJson(item,depth+1,count);
 }
}
export async function readJson(request,limit=LIMITS.body){
 if(Number(request.headers.get('content-length'))>limit)fail('payload_limit','Request body is too large',413);
 const reader=request.body?.getReader();let size=0;const chunks=[];
 if(reader)try{for(;;){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>limit){await reader.cancel();fail('payload_limit','Request body is too large',413);}chunks.push(value);}}finally{reader.releaseLock();}
 try {const value=JSON.parse(Buffer.concat(chunks).toString('utf8'));validateJson(value);return value;}catch(error){if(error instanceof BridgeError)throw error;fail('invalid_json','Expected a JSON body');}
}

import * as z from 'zod/v4';

export function captureTools(definition,id){
 const page={captureId:id,offset:z.number().int().min(1).max(1000000).optional(),limit:z.number().int().min(1).max(100).optional()};
 const roots={instanceIds:z.array(id).min(1).max(20).optional()};
 const scan={rootId:id.optional(),decompile:z.boolean().optional(),maxScripts:z.number().int().min(1).max(10000).optional(),limit:z.number().int().min(1).max(200).optional()};
 return [
  definition('dex_capture_system','Start a retained reference capture of selected roots or instanceIds: hierarchy, typed properties, attributes/tags, resolved UI/bounds, camera, asset IDs, internal/external links and readable/cached source. Use dex_get_job, then dex_read_capture. decompile=true explicitly permits up to eight potentially blocking native calls. Capture is client-visible and non-atomic.','inspect',{...roots,name:z.string().min(1).max(120).optional(),maxNodes:z.number().int().min(1).max(5000).optional(),includeSource:z.boolean().optional(),decompile:z.boolean().optional()}),
  definition('dex_list_captures','List up to eight retained system/comparison captures and coverage; oldest captures can be evicted by the 16 MiB memory bound. Export captures to keep them across reloads.','inspect',{}),
  definition('dex_get_capture','Read capture metadata, counts, camera/game context and explicit coverage limits.','inspect',{captureId:id}),
  definition('dex_read_capture','Read a deterministic offset page from a retained capture. scripts are UTF-8 chunks with one-based byte offsets. Follow nextOffset until absent.','inspect',{...page,section:z.enum(['nodes','scripts','assets','relationships','changes','events','markers'])}),
  definition('dex_get_capture_assets','Page asset IDs and original property values from a capture. This inventories references; it does not download or grant access to assets.','inspect',page),
  definition('dex_get_capture_relationships','Page confirmed instance-property links, including welds/attachments/ObjectValues. internal identifies targets contained in the captured selection.','inspect',page),
  definition('dex_delete_capture','Release a retained capture; exported local files are unaffected.','inspect',{captureId:id}),
  definition('dex_compare_captures','Start a property/attribute/hierarchy/UI-layout diff between two captures of the same roots in this paired session. Read changes from the resulting comparison capture.','inspect',{beforeId:id,afterId:id,name:z.string().min(1).max(120).optional()}),
  definition('dex_measure_instances','Read precise resolved GUI pixel/layout values and part/model bounds/pivots with projected viewport corners, camera/FOV and GUI inset. Uses selection if IDs omitted.','inspect',roots),
  definition('dex_search_scripts','Start literal source search with exact byte line/column offsets. Uses readable/cached source; decompile=true explicitly opts into up to eight native decompiles. No script or remote execution. Use dex_get_job.','inspect',{...scan,query:z.string().min(1).max(200),caseSensitive:z.boolean().optional()}),
  definition('dex_trace_scripts','Start bounded textual dependency tracing: require expressions, services, child lookups and remote-call sites. Labels candidates; does not execute requires, remotes or functions, or claim a complete call graph.','inspect',scan),
  definition('dex_start_recording','Record one object subtree while the user interacts: begins an activity watch and asynchronous before capture. Wait for the returned job before interacting. At most two watches, 1000 descendants each.','inspect',{instanceId:id,name:z.string().min(1).max(120).optional()}),
  definition('dex_get_recording','Read recording status, before/after/comparison capture IDs and user markers.','inspect',{recordingId:id}),
  definition('dex_mark_recording','Add a named elapsed-time marker to an active interaction recording, for example Shop opened. Does not interact with the game.','inspect',{recordingId:id,label:z.string().min(1).max(120)}),
  definition('dex_stop_recording','Finish an interaction recording with an asynchronous after capture and diff; retain up to 200 activity events with drop/coverage information. Watch is released on success, failure or cancellation.','inspect',{recordingId:id}),
  definition('dex_cancel_recording','Stop/release a recording without making a final capture. Existing captures remain available.','inspect',{recordingId:id}),
 ];
}

const session={sessionId:z.uuid().optional()};
export const HOST_CAPTURE_TOOLS=[
 {name:'dex_export_capture',description:'Save a completed capture as portable JSON, per-script source files, an asset list and a reusable Studio importer in a new local folder. Optionally include a current foreground Roblox Player screenshot with camera context; it is taken after the retained capture, not at the same instant. Returns paths and SHA-256. No Studio launch/import. Imported scripts stay disabled; source import is opt-in.',schema:z.strictObject({...session,captureId:z.string().min(1).max(160),includeScreenshot:z.boolean().optional(),processId:z.number().int().positive().optional(),maxDimension:z.number().int().min(320).max(2048).optional()})},
 {name:'dex_list_exports',description:'List local Dex MCP exports with file paths and metadata.',schema:z.strictObject({})},
 {name:'dex_read_export',description:'Read a bounded UTF-8 chunk of a local exported capture/importer/script by exportId and exact filename from dex_export_capture. No arbitrary filesystem paths. Offset is zero-based bytes.',schema:z.strictObject({exportId:z.uuid(),file:z.string().min(1).max(200),offset:z.number().int().min(0).optional(),bytes:z.number().int().min(1).max(48000).optional()})},
 {name:'dex_capture_screenshot',description:'Capture the visible foreground Roblox Player client area on this Windows PC and return an MCP image with camera context. Never captures Studio or the whole desktop, changes focus or opens a window. Foreground player must match processId if supplied; multiple paired sessions require explicit processId. Visible overlays may appear. Screenshot and camera read are not atomic.',schema:z.strictObject({...session,processId:z.number().int().positive().optional(),maxDimension:z.number().int().min(320).max(2048).optional()})},
];

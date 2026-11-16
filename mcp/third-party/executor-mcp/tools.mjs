import{z as Pt}from"zod";import{z as kc}from"zod";var He=e=>[...new Set(e.filter(Boolean))];function xc(e){return e instanceof kc.ZodObject?Object.keys(e.shape):[]}function _c(e){let t=e.toLowerCase();return t==="clientid"||t==="username"?"client-selection":t.includes("function")&&(t.includes("path")||t.includes("expression"))?"function-reference":t.includes("script")||t.includes("module")?"script-or-module-reference":t.includes("path")?"validated-target-path":t==="source"||t==="code"?"Luau-source":t.includes("query")||t==="search"||t==="keyword"?"search-intent":t==="arguments"||t==="args"||t.includes("value")?"typed-values":t.includes("state")?"state-reference":t==="action"||t==="operation"?"requested-operation":t==="confirm"?"mutation-approval":t==="limit"||t.startsWith("max")||t.includes("timeout")?"execution-budget":t.startsWith("include")||t.startsWith("filter")?"filter-options":t.endsWith("id")||t==="key"||t==="name"?"stable-identifier":"validated-input"}function wc(e,t){let n=[];return/plan|suggest|schema|agent-context|explain/.test(e)&&n.push("agent-guidance"),/monitor|watch|spy|trace/.test(e)&&n.push("bounded-event-snapshot"),/search|find|discover|list|scan|tree/.test(e)&&n.push("bounded-candidates"),/get|read|inspect|dump|decompile|disassemble|lookup|compare|check|is-/.test(e)&&n.push("structured-observation"),/create|clone|new-|connect/.test(e)&&n.push("created-handle"),/set|write|append|delete|destroy|clear|block|fire|invoke|call|execute|run|send/.test(e)&&n.push("operation-receipt"),t==="Diagnostics"&&n.push("diagnostic-report"),t==="Intelligence"&&n.push("grounded-evidence"),He(n.length>0?n:["structured-result"])}function Sc(e){let t=[];return/virtual-input|press-key|type-text-box/.test(e)&&t.push("VirtualInputManager"),e.includes("actor")&&t.push("getactors"),e.includes("lua-state")&&t.push("getluastate"),e.includes("comm-channel")&&t.push("create_comm_channel"),/decompile|get-module-source|get-script-content/.test(e)&&t.push("decompile"),e.includes("bytecode")&&t.push("getscriptbytecode"),/gc-|getgc|closures-by|filter-gc/.test(e)&&t.push("getgc"),/closure|function-hash|function-proto|upvalue|constant/.test(e)&&t.push("debug closure primitives"),/metatable|metamethod/.test(e)&&t.push("getrawmetatable"),/connection|signal/.test(e)&&t.push("getconnections"),(e==="click-button"||/fire-signal|replicate-signal/.test(e))&&t.push("firesignal"),e.includes("fire-click-detector")&&t.push("fireclickdetector"),e.includes("fire-proximity-prompt")&&t.push("fireproximityprompt"),/^read-file|^load-file|file-exists|list-files/.test(e)&&t.push("readfile"),/write-file|append-file|make-folder|delete-file|delete-folder/.test(e)&&t.push("executor filesystem"),/^draw-|list-drawings/.test(e)&&t.push("Drawing"),e.startsWith("ws-")&&t.push("WebSocket"),e.includes("http-request")&&t.push("request"),e.includes("packet")&&t.push("RakNet packet APIs"),He(t)}function Ec(e,t){let n=[];return/set-instance-property|set-attribute|set-properties-bulk|create-instance|clone-instance/.test(e)&&n.push("get-instance-properties"),e.includes("destroy-instance")&&n.push("verify-path-exists"),/set-gui-text|type-text-box|click-button/.test(e)&&n.push("get-gui-text"),/write-file|append-file|make-folder|delete-file|delete-folder/.test(e)&&n.push("file-exists"),e.includes("draw-")&&n.push("list-drawings"),/hook|restore-function|set-stack-hidden/.test(e)&&n.push("is-function-hooked"),/ws-connect|ws-close/.test(e)&&n.push("ws-list"),/run-on-actor|execute-lua-state/.test(e)&&n.push("get-lua-state"),t&&n.length===0&&n.push("assert-state"),He(n)}function Cc(e){return e==="click-button"?["virtual-input","fire-signal"]:e==="virtual-input"||e==="press-key"?["click-button","type-text-box"]:/decompile|get-module-source/.test(e)?["get-script-bytecode","disassemble-function"]:e.includes("search-instances")?["observe-world","get-instance-tree"]:e.includes("get-local-player-info")?["discover-character","get-players"]:/run-luau|^execute$/.test(e)?["script","eval-expression"]:e.includes("monitor-remote")?["ensure-remote-spy","trace-remote-traffic"]:[]}function Ic(e){if(!e.mutatesState)return[];let t=e.name.toLowerCase();return/file|folder|custom-asset/.test(t)?["writes executor workspace filesystem"]:/http|ws-|packet/.test(t)?["performs external network or socket I/O"]:t.includes("draw-")?["changes executor drawing overlay state"]:/monitor|watch|spy|hook|capture/.test(t)?["changes persistent executor-side observer or hook state"]:/playbook|session|agent-memory/.test(t)?["changes server-side persisted/session state"]:/run|execute|call-closure|invoke/.test(t)?["executes caller-selected behavior in the live client"]:["writes live game/client state"]}function Gn(e){let t=e.name.toLowerCase(),n=xc(e.input),r=`${t} ${e.title??""} ${e.description??""}`.toLowerCase(),a=/script|playbook|batch|fanout|agent-run|smart-task|teach-mode|transaction/.test(t),o=/(^|-)verify|diff|snapshot|diagnostic|capabilities|assert|audit/.test(t),i=a?"orchestrate":o?"verify":e.mutatesState?"act":"observe",l=e.requiresClient===!1?[]:["active-client"];n.some(m=>m.toLowerCase().includes("path"))&&l.push("resolved-target"),e.mutatesState&&l.push("explicit-mutation-approval"),n.some(m=>m==="source"||m==="code")&&l.push("validated-source");let c=He(n.map(_c));c.length===0&&c.push(e.requiresClient===!1?"server-session-context":"current-live-client-state");let d=wc(t,e.category),p=Ec(t,e.mutatesState===!0),f=Cc(t),h=Sc(t),g=Ic(e),b=["inspect tool-schema for exact fields, defaults, constraints, and an invocation example",...e.requiresClient===!1?[]:["confirm agent-context reports readyForClientTools=true and re-resolve stale targets"],...h.length>0?["run test-capabilities and choose a listed alternative when a primitive is unavailable"]:[],...n.some(m=>/limit|max|timeout/i.test(m))||/scan|search|list|tree/.test(r)?["reduce limits or scope when the result is truncated, slow, or bridge-constrained"]:[],...e.mutatesState?["do not repeat the same mutation blindly; verify the postcondition or use explain-failure"]:["treat missing fields and capability warnings as unknown evidence, not success"],...p.length>0?[`verify success with ${p.join(" or ")}`]:[]];return{phase:i,prerequisites:He(l),consumes:c,produces:d,verifiesWith:p,alternatives:f,requiresCapabilities:h,sideEffects:g,failureRecovery:He(b)}}function Pe(e,t){return He([...e,...t??[]])}function Wa(e,t){return t?{phase:t.phase??e.phase,prerequisites:Pe(e.prerequisites,t.prerequisites),consumes:Pe(e.consumes,t.consumes),produces:Pe(e.produces,t.produces),verifiesWith:Pe(e.verifiesWith,t.verifiesWith),alternatives:Pe(e.alternatives,t.alternatives),requiresCapabilities:Pe(e.requiresCapabilities,t.requiresCapabilities),sideEffects:Pe(e.sideEffects,t.sideEffects),failureRecovery:Pe(e.failureRecovery,t.failureRecovery)}:e}import{z as Y}from"zod";import{z as ae}from"zod";function Tc(e){return e instanceof ae.ZodOptional?{inner:e.unwrap(),optional:!0}:e instanceof ae.ZodDefault?{inner:e._def.innerType,optional:!0}:e instanceof ae.ZodNullable?{inner:e._def.innerType,optional:!0}:{inner:e,optional:!1}}function Va(e){return e.replace(/\\/g,"\\\\").replace(/"/g,'\\"')}function Gr(e){try{return Mt(e)}catch{return"any"}}function Mt(e){let{inner:t,optional:n}=Tc(e),r=Rc(t);return n?`${r}?`:r}function Rc(e){if(e instanceof ae.ZodString)return"string";if(e instanceof ae.ZodNumber)return"number";if(e instanceof ae.ZodBoolean)return"boolean";if(e instanceof ae.ZodBigInt)return"number";if(e instanceof ae.ZodLiteral){let t=e._def.value;return typeof t=="string"?`"${Va(t)}"`:typeof t=="number"||typeof t=="boolean"?String(t):"any"}if(e instanceof ae.ZodEnum){let t=e,n=t.options??t._def?.values??(t._def?.entries?Object.values(t._def.entries):[]);return n.length?n.map(r=>`"${Va(r)}"`).join(" | "):"string"}if(e instanceof ae.ZodArray){let t=e,n=t.element??t._def?.element??t._def?.type;return n?`{${Mt(n)}}`:"{any}"}if(e instanceof ae.ZodObject){let t=e.shape,n=Object.entries(t);return n.length?`{ ${n.map(([a,o])=>{let i=Mt(o);return`${a}: ${i}`}).join(", ")} }`:"{}"}if(e instanceof ae.ZodUnion)return e._def.options.map(n=>Mt(n)).join(" | ");if(e instanceof ae.ZodRecord){let t=e._def;return`{[string]: ${t.valueType?Mt(t.valueType):"any"}}`}return e instanceof ae.ZodNull?"nil":"any"}function Mc(e){if(e===null||["string","number","boolean"].includes(typeof e))return e;if(Array.isArray(e)&&e.length<=20)try{return JSON.stringify(e),e}catch{return}if(e&&typeof e=="object")try{if(JSON.stringify(e).length<=500)return e}catch{return}}function At(e){let t=e,n=!1,r=!1,a;for(let o=0;o<12;o++){if(t instanceof Y.ZodOptional){n=!0,t=t.unwrap();continue}if(t instanceof Y.ZodDefault){n=!0;let i=t._def;try{let l=i.defaultValue;a=Mc(typeof l=="function"?l():l)}catch{a=void 0}t=i.innerType;continue}if(t instanceof Y.ZodNullable){r=!0,t=t._def.innerType;continue}break}return{inner:t,optional:n,nullable:r,...a!==void 0?{defaultValue:a}:{}}}function za(e){let t=e.description;if(typeof t=="string"&&t.length>0)return t;let r=e.meta?.()?.description;if(typeof r=="string"&&r.length>0)return r;let o=e._def?.description;if(typeof o=="string"&&o.length>0)return o;let{inner:i}=At(e);return i===e?null:za(i)}function Lt(e){return e.replace(/([a-z0-9])([A-Z])/g,"$1 $2").replace(/[_-]+/g," ").trim().toLowerCase()}function Lc(e,t,n){let r=e.toLowerCase(),a=n?"Optional ":"";return r==="threadcontext"?"Optional Roblox thread identity for this call; omit it to use the server default.":r==="timeoutms"?"Optional per-call deadline in milliseconds; omit it to use the tool or server default.":r==="confirm"?"Explicit safety acknowledgement; must be true before this state-changing operation runs.":r==="clientid"?`${a}connected Roblox client id returned by list-clients.`:r==="username"?`${a}Roblox username used to resolve a connected client.`:r.includes("functionpath")||r==="functionexpression"?`${a}Luau expression resolving to the target function without invoking it.`:r.includes("scriptpath")||r.includes("modulepath")?`${a}Luau expression or dotted path resolving to the target script/module.`:r.includes("instancepath")||r==="path"||r.endsWith("path")?`${a}dotted Roblox instance/value path resolved in the active client.`:r==="source"||r.endsWith("source")||r==="code"?`${a}Luau source text processed by this tool; it is never inferred or guessed.`:r==="arguments"||r==="args"?`${a}ordered typed arguments forwarded to the selected operation.`:r==="query"||r.endsWith("query")||r==="search"||r==="keyword"?`${a}search text used to filter and rank bounded results.`:r==="limit"||r.startsWith("max")||r.endsWith("limit")?`${a}hard result/work budget used to keep output and runtime bounded.`:r==="action"||r==="operation"?`${a}operation selector; use one of the schema's allowed values.`:r==="value"||r.endsWith("value")?`${a}typed value consumed by this operation.`:r==="state"||r.endsWith("state")?`${a}state selector or reusable state reference returned by a discovery tool.`:r.startsWith("include")?`Whether to include ${Lt(e.slice(7))} in the bounded result.`:t.includes("boolean")?`Whether to enable ${Lt(e)}.`:t.includes("number")?`${a}numeric value for ${Lt(e)}.`:t.includes("string")?`${a}text value for ${Lt(e)}.`:`${a}validated input for ${Lt(e)}.`}function Ka(e){let t=e._def?.checks;return Array.isArray(t)?t.flatMap(n=>{if(!n||typeof n!="object")return[];let r=n,a=r._zod?.def??r.def??r._def;return a?[a]:[]}):[]}function Ac(e){let t=e,n=[],r=Ka(e);t.isInt===!0&&n.push("integer");let a=!1,o=!1;for(let i of r)i.check==="greater_than"&&typeof i.value=="number"?(n.push(i.inclusive===!1?`greater than ${i.value}`:`minimum ${i.value}`),a=!0):i.check==="less_than"&&typeof i.value=="number"?(n.push(i.inclusive===!1?`less than ${i.value}`:`maximum ${i.value}`),o=!0):i.check==="min_length"&&typeof i.minimum=="number"?n.push(`minimum length ${i.minimum}`):i.check==="max_length"&&typeof i.maximum=="number"?n.push(`maximum length ${i.maximum}`):i.check==="string_format"&&typeof i.format=="string"&&(i.format==="regex"&&i.pattern instanceof RegExp?n.push(`must match ${String(i.pattern).slice(0,160)}`):n.push(`format ${i.format}`));return!a&&typeof t.minValue=="number"&&Number.isFinite(t.minValue)&&!(t.isInt===!0&&t.minValue===Number.MIN_SAFE_INTEGER)&&n.push(`minimum ${t.minValue}`),!o&&typeof t.maxValue=="number"&&Number.isFinite(t.maxValue)&&!(t.isInt===!0&&t.maxValue===Number.MAX_SAFE_INTEGER)&&n.push(`maximum ${t.maxValue}`),typeof t.minLength=="number"&&n.push(`minimum length ${t.minLength}`),typeof t.maxLength=="number"&&n.push(`maximum length ${t.maxLength}`),e instanceof Y.ZodEnum&&Array.isArray(t.options)&&t.options.length>0&&n.push(`one of: ${t.options.map(String).join(", ")}`),e instanceof Y.ZodLiteral&&t.values instanceof Set&&n.push(`literal: ${[...t.values].map(String).join(", ")}`),[...new Set(n)]}function $e(e,t){try{return e.safeParse(t).success}catch{return!1}}function Dn(e,t){let n=Ka(e).find(a=>a.check===t),r=t==="min_length"?n?.minimum:n?.maximum;return typeof r=="number"&&Number.isFinite(r)?r:null}function Ba(e){let t=e.toLowerCase();return t==="threadcontext"?"2":t.includes("functionpath")||t==="functionexpression"?"getgenv().handler":t.includes("path")?"game.Workspace.Target":t==="source"||t==="code"||t.includes("snippet")?"return true":t.includes("query")||t==="search"||t==="keyword"?"target":t.includes("url")?"https://example.com":t.includes("uuid")?"00000000-0000-4000-8000-000000000000":t.includes("classname")?"Part":t.endsWith("id")?"example-id":"example"}function rt(e,t,n){let r=e;return t!==null&&r.length<t&&(r+="x".repeat(t-r.length)),n!==null&&r.length>n&&(r=r.slice(0,n)),r}function Nc(e,t){let n=e.shape,r=Object.fromEntries(Object.entries(n).filter(([,i])=>!At(i).optional).map(([i,l])=>[i,at(i,l,t+1)]));if($e(e,r))return r;let a=Object.entries(n).filter(([,i])=>At(i).optional);for(let[i,l]of a){let c={...r,[i]:at(i,l,t+1)};if($e(e,c))return c}let o={...r};for(let[i,l]of a)if(o[i]=at(i,l,t+1),$e(e,o))return o;return r}function at(e,t,n=0){let{inner:r,defaultValue:a}=At(t);if(a!==void 0)return a;if(n>6)return null;if(r instanceof Y.ZodEnum)return r.options[0]??"example";if(r instanceof Y.ZodLiteral){let i=r.values;return i instanceof Set?[...i][0]??null:null}if(r instanceof Y.ZodUnion){for(let i of r.options){let l=at(e,i,n+1);if($e(r,l))return l}return null}if(r instanceof Y.ZodObject)return Nc(r,n);if(r instanceof Y.ZodArray){let i=Dn(r,"min_length")??0,c=Dn(r,"max_length")===0?0:Math.max(1,i),d=at(e.replace(/s$/i,""),r.element,n+1),p=Array.from({length:c},()=>d);return $e(r,p)?p:$e(r,[])?[]:p}if(r instanceof Y.ZodRecord)return{};if(r instanceof Y.ZodBoolean)return e.toLowerCase()==="confirm";if(r instanceof Y.ZodNumber){let i=r,l=[];return e.toLowerCase()==="threadcontext"&&l.push(2),e.toLowerCase()==="timeoutms"&&l.push(2e4),(e.toLowerCase()==="limit"||e.toLowerCase().startsWith("max"))&&l.push(10),typeof i.minValue=="number"&&Number.isFinite(i.minValue)&&!(i.isInt===!0&&i.minValue===Number.MIN_SAFE_INTEGER)&&l.push(i.minValue,i.minValue+(i.isInt===!0?1:.1)),typeof i.maxValue=="number"&&Number.isFinite(i.maxValue)&&!(i.isInt===!0&&i.maxValue===Number.MAX_SAFE_INTEGER)&&l.push(i.maxValue,i.maxValue-(i.isInt===!0?1:.1)),l.push(0,1,-1),l.find(c=>$e(r,c))??0}if(r instanceof Y.ZodString){let i=typeof r.minLength=="number"?r.minLength:Dn(r,"min_length"),l=typeof r.maxLength=="number"?r.maxLength:Dn(r,"max_length"),c=rt(Ba(e),i,l);return[c,rt("example",i,l),rt("EXAMPLE",i,l),rt("target",i,l),rt("00000000-0000-4000-8000-000000000000",i,l),rt("https://example.com",i,l)].find(p=>$e(r,p))??c}if(r instanceof Y.ZodUnknown||r instanceof Y.ZodAny)return null;let o=(()=>{try{return Gr(r)}catch{return"any"}})();return o.includes("boolean")?!1:o.includes("number")?0:o.includes("string")?Ba(e):o.startsWith("{")?{}:null}function de(e){if(!(e instanceof Y.ZodObject))return[];let t=e.shape,n=[];for(let[r,a]of Object.entries(t)){let{inner:o,optional:i,nullable:l,defaultValue:c}=At(a),d;try{d=Gr(a)}catch{d="any"}let p=za(a);n.push({name:r,type:d,optional:i,nullable:l,description:p??Lc(r,d,i),descriptionSource:p?"explicit":"inferred",...c!==void 0?{defaultValue:c}:{},constraints:Ac(o),example:at(r,a)})}return n}function fe(e){let t=de(e);return t.length===0?"{}":`{ ${t.map(n=>`${n.name}: ${n.type}`).join(", ")} }`}function Ha(e){return e.ai??Gn({name:e.name,title:e.title,description:e.description,category:e.category,input:e.input,requiresClient:e.requiresClient,mutatesState:e.mutatesState})}function Pc(e){return e>=90?"A":e>=80?"B":e>=70?"C":e>=60?"D":"F"}function Nt(e){let t=de(e.input),n=Ha(e),r=t.filter(d=>d.descriptionSource==="explicit").length,a=t.length-r,o=[],i=[],l=100,c=e.description.replace(/\s+/g," ").trim().length;return c<40?(l-=20,o.push("base description is too short to explain behavior and boundaries")):c<120?(l-=6,o.push("base description is concise; compiled guidance supplies missing operational detail")):i.push("detailed base description"),!e.title.trim()||e.title===e.name?(l-=12,o.push("title does not add human-readable intent beyond the tool name")):i.push("human-readable title"),a>0?(l-=Math.min(8,Math.ceil(a/5)),o.push(`${a} input field description(s) are centrally inferred`)):t.length>0&&i.push("all input fields explicitly documented"),n.consumes.length===0||n.produces.length===0?(l-=15,o.push("AI data-flow contract is incomplete")):i.push("complete AI data-flow contract"),n.failureRecovery.length===0?(l-=15,o.push("no failure recovery guidance")):i.push("structured recovery guidance"),e.requiresClient!==!1&&!n.prerequisites.includes("active-client")&&(l-=18,o.push("client-bound tool does not declare active-client prerequisite")),e.mutatesState&&n.sideEffects.length===0&&(l-=20,o.push("mutating tool does not declare side effects")),e.mutatesState&&n.verifiesWith.length===0&&(l-=12,o.push("mutating tool has no verification recommendation")),e.mutatesState&&n.sideEffects.length>0&&n.verifiesWith.length>0&&i.push("mutation, side-effect, and verification metadata aligned"),l=Math.max(0,Math.min(100,l)),{score:l,grade:Pc(l),explicitFieldDescriptions:r,inferredFieldDescriptions:a,issues:o,strengths:i}}function Ur(e,t=0){return t>6?"nil":typeof e=="string"?JSON.stringify(e):typeof e=="number"&&Number.isFinite(e)?String(e):typeof e=="boolean"?e?"true":"false":Array.isArray(e)?`{ ${e.slice(0,20).map(n=>Ur(n,t+1)).join(", ")} }`:e&&typeof e=="object"?`{ ${Object.entries(e).slice(0,30).map(([r,a])=>`${/^[A-Za-z_][A-Za-z0-9_]*$/.test(r)?r:`[${JSON.stringify(r)}]`} = ${Ur(a,t+1)}`).join(", ")} }`:"nil"}function Dr(e,t){try{return e.safeParse(t).success}catch{return!1}}function Xa(e,t){let n=Object.fromEntries(t.filter(o=>!o.optional).map(o=>[o.name,o.example]));if(Dr(e,n))return n;let r=t.filter(o=>o.optional);for(let o of r){let i={...n,[o.name]:o.example};if(Dr(e,i))return i}let a={...n};for(let o of r)if(a[o.name]=o.example,Dr(e,a))return a;return n}function $c(e,t,n){let r=e.replace(/-([a-z])/g,(i,l)=>l.toUpperCase()),a=Xa(t,n);if(Object.keys(a).length===0)return`mcp.${r}()`;let o=Object.entries(a).map(([i,l])=>`${i} = ${Ur(l)}`).join(", ");return`mcp.${r}({ ${o} })`}function Fc(e){let t=e.name.toLowerCase();return/fanout|getgc|scan|decompile|disassemble|tree|loop|profile|memory|bytecode/.test(t)?"high":e.requiresClient!==!1||de(e.input).length>=5?"medium":"low"}function Oc(e){return e.mutatesState?/^set-|replace|clear-|block-|ignore-|select-client/.test(e.name)?"idempotent-write":"contextual-write":"read-only"}function Ya(e){let t=de(e.input),n=Ha(e),r=Xa(e.input,t),a=t.filter(d=>!d.optional).map(d=>d.name),o=t.filter(d=>d.optional).map(d=>d.name),i=e.requiresClient!==!1,l=e.mutatesState===!0,c=[...i?["No active client is selected or the bridge is disconnected."]:[],...n.requiresCapabilities.length>0?["A required executor capability is absent; use a listed alternative."]:[],...l?["The target, arguments, approval, or postcondition is still ambiguous."]:[]];return{signature:fe(e.input),requiredInputs:a,optionalInputs:o,fields:t,exampleInput:r,example:$c(e.name,e.input,t),callWhen:[`The goal matches: ${e.title.replace(/[.]+$/,"").toLowerCase()}.`,`The ${n.phase} phase needs ${n.produces.join(" or ")}.`],avoidWhen:c,safety:{readOnly:!l,mutatesState:l,requiresClient:i,sideEffects:n.sideEffects},execution:{phase:n.phase,estimatedCost:Fc(e),idempotency:Oc(e),prerequisites:n.prerequisites,capabilities:n.requiresCapabilities},success:{produces:n.produces,verifiesWith:n.verifiesWith},alternatives:n.alternatives,recovery:n.failureRecovery,quality:e.quality??Nt(e)}}function u(e){let t={name:e.name,title:e.title??e.name,description:e.description,category:e.category,input:e.input,requiresClient:e.requiresClient??!0,mutatesState:e.mutatesState??!1,execute:e.execute},n=Gn({...t,input:t.input}),r=Wa(n,e.ai),a=Nt({...t,input:t.input,ai:r});return{...t,ai:r,quality:a}}function s(e){return JSON.stringify(e).replace(/\\u([0-9a-fA-F]{4})/g,"\\u{$1}")}var _e=`
local function __encode(value, depth)
  depth = depth or 0
  local t = typeof(value)
  if t == "nil" or t == "boolean" or t == "number" or t == "string" then
    return value
  elseif t == "Instance" then
    local ok, full = pcall(function() return value:GetFullName() end)
    return { __type = "Instance", className = value.ClassName, path = ok and full or tostring(value) }
  elseif t == "EnumItem" then
    return { __type = "EnumItem", value = tostring(value) }
  elseif t == "table" then
    if depth >= 5 then return "<table:max-depth>" end
    local out = {}
    local okIter = pcall(function()
      for k, v in pairs(value) do
        out[tostring(k)] = __encode(v, depth + 1)
      end
    end)
    if not okIter then return "<table:unreadable>" end
    return out
  else
    local ok, s = pcall(function() return tostring(value) end)
    return { __type = t, value = ok and s or "<unprintable>" }
  end
end
`,Za=`
local function __resolve(p)
  local segments = {}
  for seg in string.gmatch(p, "[^%.]+") do
    segments[#segments + 1] = seg
  end
  if #segments == 0 then return nil, "Empty path" end

  local first = segments[1]
  local current
  if first == "game" or first == "Game" then
    current = game
  elseif first == "workspace" or first == "Workspace" then
    current = workspace
  else
    local ok, svc = pcall(function() return game:GetService(first) end)
    if ok and svc then
      current = svc
    else
      local ok2, child = pcall(function() return game:FindFirstChild(first) end)
      if ok2 and child then current = child end
    end
  end
  if not current then
    return nil, "Could not resolve root segment '" .. tostring(first) .. "'"
  end

  for i = 2, #segments do
    local name = segments[i]
    local ok, nxt = pcall(function() return (current :: any)[name] end)
    if not ok or nxt == nil then
      local ok2, child = pcall(function() return current:FindFirstChild(name) end)
      if ok2 and child then
        nxt = child
      else
        return nil, "Path segment '" .. tostring(name) .. "' not found under '" .. tostring(current) .. "'"
      end
    end
    current = nxt
  end
  return current
end
`;var F=`
local __d = (type(debug) == "table") and debug or {}
local __getinfo = (type(getinfo) == "function" and getinfo) or __d.getinfo or __d.info
local __getconstants = getconstants or __d.getconstants
local __getupvalues = getupvalues or __d.getupvalues
local __getprotos = getprotos or __d.getprotos

local function __fnInfo(f)
  local r = { ptr = tostring(f), name = "", source = "", line = -1, nparams = -1, nups = -1 }
  if type(__getinfo) == "function" then
    local ok, info = pcall(__getinfo, f, "nSlu")
    if ok and type(info) == "table" then
      r.name = info.name or ""
      r.source = info.source or ""
      r.line = info.linedefined or -1
      r.nparams = info.nparams or -1
      r.nups = info.nups or -1
    else
      local oks, s = pcall(__getinfo, f, "s"); if oks and type(s) ~= "table" and s ~= nil then r.source = tostring(s) end
      local okl, l = pcall(__getinfo, f, "l"); if okl and type(l) == "number" then r.line = l end
      local okn, n = pcall(__getinfo, f, "n"); if okn and n ~= nil and type(n) ~= "table" then r.name = tostring(n) end
    end
  end
  return r
end

local function __consts(f)
  if type(__getconstants) ~= "function" then return {} end
  local ok, c = pcall(__getconstants, f)
  if ok and type(c) == "table" then return c end
  return {}
end
local function __ups(f)
  if type(__getupvalues) ~= "function" then return {} end
  local ok, u = pcall(__getupvalues, f)
  if ok and type(u) == "table" then return u end
  return {}
end
local function __protos(f)
  if type(__getprotos) ~= "function" then return {} end
  local ok, p = pcall(__getprotos, f)
  if ok and type(p) == "table" then return p end
  return {}
end

-- Walk GC functions up to 'cap'; call cb(fn) for each. Returns (truncated, scanned).
local function __eachFn(cap, cb)
  local ok, gc = pcall(getgc, true)
  if not ok or type(gc) ~= "table" then
    ok, gc = pcall(getgc)
    if not ok or type(gc) ~= "table" then return false, 0 end
  end
  local n = 0
  for _, o in gc do
    if type(o) == "function" then
      n = n + 1
      if n > cap then return true, n end
      pcall(cb, o)
    end
  end
  return false, n
end
`;var Qa=u({name:"build-call-graph",title:"Build call graph / function tree (IDA call graph)",description:'Build an IDA-style call graph (function tree) rooted at a target Luau function. Each Luau function carries its nested protos \u2014 the functions it can construct and call \u2014 so this recurses through getprotos breadth-first to map the callee tree. Returns a FLATTENED node list (each node knows its parentIndex and depth) so you can reconstruct the tree, plus per-node proto/upvalue counts and source/line from debug.info. Use it to understand how a closure fans out into helpers, spot deeply nested logic, and pick disassembly targets. Resolve the root via a Luau expression (e.g. "getrenv().game.PlayerScripts.Main.someFunc" or a global). Requires getprotos; caps depth and node count.',category:"Disassembly & Xrefs",input:Pt.object({functionPath:Pt.string().describe('Luau expression that resolves to the ROOT function (e.g. "getgenv().myFunc" or "require(game.ReplicatedStorage.Mod).start"). Evaluated as `return <expr>`; must yield a function.'),maxDepth:Pt.number().int().describe("How many proto levels deep to recurse from the root (default 3, max 6). Root is depth 0.").optional().default(3),maxNodes:Pt.number().int().describe("Hard cap on total nodes (including the root) to keep the graph bounded (default 120).").optional().default(120),threadContext:Pt.number().int().optional()}),async execute({functionPath:e,maxDepth:t,maxNodes:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),0),6),i=Math.min(Math.max(Math.floor(n),1),2e3),l=`
${F}
local ok, root = pcall(function() return (loadstring("return " .. ${s(e)}))() end)
if not ok or type(root) ~= "function" then
  return { error = "functionPath did not resolve to a function: " .. ${s(e)} }
end

local maxDepth = ${o}
local maxNodes = ${i}
local graph = {}
local truncated = false

-- Node holds the actual function plus tree metadata; we emit a sanitized copy.
local nodes = { { fn = root, parentIndex = -1, depth = 0 } }
local head = 1
while head <= #nodes do
  local node = nodes[head]
  local fn = node.fn
  local info = __fnInfo(fn)
  local protos = __protos(fn)
  local ups = __ups(fn)
  graph[#graph + 1] = {
    index = head,
    parentIndex = node.parentIndex,
    depth = node.depth,
    name = info.name,
    source = info.source,
    line = info.line,
    protoCount = #protos,
    upvalueCount = #ups,
  }
  if node.depth < maxDepth then
    for _, child in protos do
      if type(child) == "function" then
        if #nodes >= maxNodes then truncated = true break end
        nodes[#nodes + 1] = { fn = child, parentIndex = head, depth = node.depth + 1 }
      end
    end
  end
  head = head + 1
end

return { root = __fnInfo(root), nodeCount = #graph, truncated = truncated, graph = graph }
`;return{data:await a.runLuau(l,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as $t}from"zod";var Ja=u({name:"disassemble-function",title:"Disassemble function (IDA-style function view)",description:"Produce a full IDA-style dump of a single Luau function in one call: debug.info (name/source/line/params/ups), whether it is a Lua or C closure (islclosure/iscclosure), constant/upvalue/proto counts, the executor function hash (getfunctionhash) for duplicate-detection, and \u2014 optionally \u2014 the full constant and upvalue tables with their typeof and a string value (Instances become GetFullName, functions become tostring). Complements inspect-closure by bundling the hash and the structural counts into one reverse-engineering-focused view. Resolve the target via a Luau expression that yields a function; each list is capped at 200 entries.",category:"Disassembly & Xrefs",input:$t.object({functionPath:$t.string().describe('Luau expression that resolves to the function to disassemble (e.g. "getgenv().myFunc" or "require(game.ReplicatedStorage.Mod).start"). Evaluated as `return <expr>`; must yield a function.'),includeConstants:$t.boolean().describe("Include the full constants table (capped at 200) with Index/Type/Value. Default true.").optional().default(!0),includeUpvalues:$t.boolean().describe("Include the full upvalues table (capped at 200) with Index/Type/Value. Default true.").optional().default(!0),threadContext:$t.number().int().optional()}),async execute({functionPath:e,includeConstants:t,includeUpvalues:n,threadContext:r},a){let o=`
${F}
local ok, fn = pcall(function() return (loadstring("return " .. ${s(e)}))() end)
if not ok or type(fn) ~= "function" then
  return { error = "functionPath did not resolve to a function: " .. ${s(e)} }
end

local function __valStr(v)
  local t = typeof(v)
  if t == "Instance" then
    local okn, n = pcall(function() return v:GetFullName() end)
    if okn then return n end
    return tostring(v)
  end
  local oks, s = pcall(tostring, v)
  if oks then return s end
  return "<unprintable>"
end

local function __dumpList(list)
  local out = {}
  for i = 1, math.min(#list, 200) do
    local v = list[i]
    out[i] = { Index = i, Type = typeof(v), Value = __valStr(v) }
  end
  return out
end

local consts = __consts(fn)
local ups = __ups(fn)
local protos = __protos(fn)

local isLua = nil
if type(islclosure) == "function" then
  local oki, r = pcall(islclosure, fn); if oki then isLua = r end
end
local isC = nil
if type(iscclosure) == "function" then
  local okc, r = pcall(iscclosure, fn); if okc then isC = r end
end

local hash = nil
if type(getfunctionhash) == "function" then
  local okh, h = pcall(getfunctionhash, fn); if okh then hash = tostring(h) end
end

local result = {
  Info = __fnInfo(fn),
  IsLua = isLua,
  IsC = isC,
  ConstantCount = #consts,
  UpvalueCount = #ups,
  ProtoCount = #protos,
  FunctionHash = hash,
}

if ${t?"true":"false"} then result.Constants = __dumpList(consts) end
if ${n?"true":"false"} then result.Upvalues = __dumpList(ups) end

return result
`;return{data:await a.runLuau(o,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as Ft}from"zod";var eo=u({name:"find-duplicate-functions",title:"Find identical / duplicated functions (IDA find-identical)",description:"Walk every Luau function in the GC, hash each one with getfunctionhash, and group functions that share the exact same hash \u2014 the runtime equivalent of IDA's 'find identical functions'. Reveals clones and copy-pasted code (duplicated module logic, repeated handlers, library functions instantiated many times). Each group reports the shared hash, how many functions carry it, and a few sample functions (ptr/name/source/line). Requires getgc + getfunctionhash; caps the scan and flags truncation.",category:"Disassembly & Xrefs",input:Ft.object({minGroup:Ft.number().int().describe("Only report hash groups shared by at least this many functions (default 2 = any duplicate).").optional().default(2),limit:Ft.number().int().describe("Max duplicate groups to return, largest groups first (default 50).").optional().default(50),maxScan:Ft.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:Ft.number().int().optional()}),async execute({minGroup:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.max(2,Math.floor(e)),i=Math.min(Math.max(Math.floor(t),1),1e3),l=Math.min(Math.max(Math.floor(n),100),3e4),c=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end
if type(getfunctionhash) ~= "function" then return { error = "getfunctionhash is not available in this executor." } end

local groups = {}
local minG = ${o}
local trunc, scanned = __eachFn(${l}, function(fn)
  local ok, h = pcall(getfunctionhash, fn)
  if ok and type(h) == "string" and #h > 0 then
    local e = groups[h]
    if not e then e = { count = 0, samples = {} }; groups[h] = e end
    e.count = e.count + 1
    if #e.samples < 5 then e.samples[#e.samples + 1] = __fnInfo(fn) end
  end
end)

local arr = {}
for h, e in groups do
  if e.count >= minG then
    arr[#arr + 1] = { hash = h, count = e.count, samples = e.samples }
  end
end
table.sort(arr, function(a, b) return a.count > b.count end)
local out = {}
for i = 1, math.min(#arr, ${i}) do out[i] = arr[i] end
return {
  duplicateGroups = out,
  totalDuplicateGroups = #arr,
  functionsScanned = scanned,
  truncatedScan = trunc,
}
`;return{data:await a.runLuau(c,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as Ot}from"zod";var to=u({name:"find-function-xrefs",title:"Find xrefs TO a function (IDA 'xrefs to')",description:`Resolve a target Luau FUNCTION from an expression, then walk every function in the GC and report which ones REFERENCE it \u2014 the runtime equivalent of IDA's 'cross references to' on a sub. A referrer references the target if the target appears in its upvalues (closures that captured it) OR among its nested protos (functions that embed it as an inner function). Each xref reports __fnInfo (ptr/name/source/line/nparams/nups) plus 'via' ("upvalue" or "proto"). The target itself is skipped. Requires getgc + getupvalues/getprotos; caps the scan and flags truncation. Pivot from list-gc-functions or lookup-function to get an expression that resolves here.`,category:"Disassembly & Xrefs",input:Ot.object({functionPath:Ot.string().describe("Luau expression that resolves to the TARGET function, e.g. 'getrenv().game.ReplicatedStorage.Modules.Combat.attack' or 'require(path).onHit'. Evaluated as `(loadstring('return '..expr))()`; must yield type=='function' or the tool errors."),limit:Ot.number().int().describe("Max referrer functions (xrefs) to return (default 100).").optional().default(100),maxScan:Ot.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:Ot.number().int().optional()}),async execute({functionPath:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),1e3),i=Math.min(Math.max(Math.floor(n),100),3e4),l=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local expr = ${s(e)}
local loader = loadstring or load
if type(loader) ~= "function" then return { error = "loadstring/load is not available in this executor." } end
local okc, chunk = pcall(loader, "return " .. expr)
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, target = pcall(chunk)
if not okr then return { error = "Error evaluating expression: " .. tostring(target) } end
if type(target) ~= "function" then
  return { error = "Expression did not resolve to a function (got " .. typeof(target) .. ")." }
end

local xrefs = {}
local count = 0
local capped = false
local trunc, scanned = __eachFn(${i}, function(fn)
  if fn == target then return end
  local via = nil
  for _, u in __ups(fn) do
    if u == target then via = "upvalue"; break end
  end
  if not via then
    for _, p in __protos(fn) do
      if p == target then via = "proto"; break end
    end
  end
  if via then
    count = count + 1
    if #xrefs < ${o} then
      local info = __fnInfo(fn)
      info.via = via
      xrefs[#xrefs + 1] = info
    else
      capped = true
    end
  end
end)

return {
  target = __fnInfo(target),
  xrefCount = count,
  functionsScanned = scanned,
  truncatedScan = trunc,
  truncatedOutput = capped,
  xrefs = xrefs,
}
`;return{data:await a.runLuau(l,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as qt}from"zod";var no=u({name:"find-functions-by-complexity",title:"Find the most complex functions (RE starting points)",description:"Rank every Luau function in the GC by complexity so you know where to start reverse-engineering \u2014 the biggest, most interesting functions usually carry the core logic. For each function it counts the number of constants, upvalues, and nested protos, then returns the top `limit` by the chosen metric (sortBy), heaviest first. Each entry reports the owning script source, line, function name and pointer, plus the three counts. Pivot from here with get-closure-constants / find-string-xrefs / call-graph tools. Requires getgc + getconstants/getupvalues/getprotos; caps the scan and flags truncation.",category:"Disassembly & Xrefs",input:qt.object({sortBy:qt.enum(["constants","upvalues","protos"]).describe("Which complexity metric to rank by: 'constants' (literals/strings/numbers used, default), 'upvalues' (captured variables), or 'protos' (nested child functions).").optional().default("constants"),limit:qt.number().int().describe("Max functions to return, heaviest first (default 50).").optional().default(50),maxScan:qt.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:qt.number().int().optional()}),async execute({sortBy:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),1e3),i=Math.min(Math.max(Math.floor(n),100),3e4),l=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local sortBy = ${JSON.stringify(e)}
local lim = ${o}
local arr = {}
local trunc, scanned = __eachFn(${i}, function(fn)
  local info = __fnInfo(fn)
  arr[#arr + 1] = {
    source = info.source,
    line = info.line,
    name = info.name,
    ptr = info.ptr,
    constants = #__consts(fn),
    upvalues = #__ups(fn),
    protos = #__protos(fn),
  }
end)

table.sort(arr, function(a, b) return a[sortBy] > b[sortBy] end)
local out = {}
for i = 1, math.min(#arr, lim) do out[i] = arr[i] end
return { sortBy = sortBy, functionsScanned = scanned, truncatedScan = trunc, functions = out }
`;return{data:await a.runLuau(l,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as Gt}from"zod";var ro=u({name:"find-global-xrefs",title:"Find functions that reference a global or method by name",description:"Find functions that likely call or reference this global or method by name. Luau bytecode stores global lookups and method names (e.g. FireServer, require, loadstring, HttpGet, GetService) as string constants, so this walks every function in the GC and reports each one whose constants contain the exact name string. This is the IDA xref-to-import equivalent: pivot from a sensitive API to all the code that uses it. Each hit reports the owning script source, line, function name and pointer. Requires getgc + getconstants; caps the scan and flags truncation.",category:"Disassembly & Xrefs",input:Gt.object({name:Gt.string().describe("The exact global or method name to look for (e.g. FireServer, require, loadstring, HttpGet, GetService)."),limit:Gt.number().int().describe("Max matching functions to return (default 100).").optional().default(100),maxScan:Gt.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:Gt.number().int().optional()}),async execute({name:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),1e3),i=Math.min(Math.max(Math.floor(n),100),3e4),l=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local name = ${s(e)}
local lim = ${o}
local matches = {}
local matchCount = 0
local trunc, scanned = __eachFn(${i}, function(fn)
  local matched = false
  for _, c in __consts(fn) do
    if type(c) == "string" and c == name then
      matched = true
      break
    end
  end
  if matched then
    matchCount = matchCount + 1
    if #matches < lim then
      local info = __fnInfo(fn)
      matches[#matches + 1] = {
        source = info.source,
        line = info.line,
        name = info.name,
        ptr = info.ptr,
      }
    end
  end
end)

return { name = name, matchCount = matchCount, functionsScanned = scanned, truncatedScan = trunc, matches = matches }
`;return{data:await a.runLuau(l,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as Dt}from"zod";var ao=u({name:"find-instance-xrefs",title:"Find functions that reference an Instance (IDA data xrefs)",description:`Resolve a target Instance from a Luau expression, then walk every function in the GC and report which ones hold a reference to it \u2014 the runtime equivalent of IDA's data cross-references on a global object. A referrer references the instance if it appears in the function's upvalues OR constants. Answers 'which functions read, manipulate, or watch this object?'. Each xref reports __fnInfo (ptr/name/source/line/nparams/nups) plus 'via' ("upvalue" or "constant"). Requires getgc + getupvalues/getconstants; caps the scan and flags truncation.`,category:"Disassembly & Xrefs",input:Dt.object({instancePath:Dt.string().describe("Luau expression that resolves to the target Instance, e.g. 'game.Workspace.Boss' or 'game:GetService(\"Players\").LocalPlayer.Character'. Evaluated as `(loadstring('return '..expr))()`; must yield typeof=='Instance' or the tool errors."),limit:Dt.number().int().describe("Max referrer functions (xrefs) to return (default 100).").optional().default(100),maxScan:Dt.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:Dt.number().int().optional()}),async execute({instancePath:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),1e3),i=Math.min(Math.max(Math.floor(n),100),3e4),l=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local expr = ${s(e)}
local loader = loadstring or load
if type(loader) ~= "function" then return { error = "loadstring/load is not available in this executor." } end
local okc, chunk = pcall(loader, "return " .. expr)
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, target = pcall(chunk)
if not okr then return { error = "Error evaluating expression: " .. tostring(target) } end
if typeof(target) ~= "Instance" then
  return { error = "Expression did not resolve to an Instance (got " .. typeof(target) .. ")." }
end

local fullName = target:GetFullName()
local okfn, fn2 = pcall(function() return target:GetFullName() end)
if okfn then fullName = fn2 end

local xrefs = {}
local count = 0
local capped = false
local trunc, scanned = __eachFn(${i}, function(fn)
  local via = nil
  for _, u in __ups(fn) do
    if u == target then via = "upvalue"; break end
  end
  if not via then
    for _, c in __consts(fn) do
      if c == target then via = "constant"; break end
    end
  end
  if via then
    count = count + 1
    if #xrefs < ${o} then
      local info = __fnInfo(fn)
      info.via = via
      xrefs[#xrefs + 1] = info
    else
      capped = true
    end
  end
end)

return {
  instance = fullName,
  className = target.ClassName,
  xrefCount = count,
  functionsScanned = scanned,
  truncatedScan = trunc,
  truncatedOutput = capped,
  xrefs = xrefs,
}
`;return{data:await a.runLuau(l,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as Ut}from"zod";var oo=u({name:"find-remote-xrefs",title:"Find functions that fire/handle a remote (IDA xrefs)",description:`Resolve a RemoteEvent / RemoteFunction / BindableEvent / BindableFunction from a Luau expression, then walk every function in the GC and report which ones reference it \u2014 the runtime equivalent of cross-referencing a network endpoint. A referrer references the remote if it appears in the function's upvalues OR constants, which surfaces the closures that FireServer/InvokeServer/OnClientEvent-connect this remote. Each xref reports __fnInfo (ptr/name/source/line/nparams/nups) plus 'via' ("upvalue" or "constant"); the response includes the remote's ClassName. Requires getgc + getupvalues/getconstants; caps the scan and flags truncation.`,category:"Disassembly & Xrefs",input:Ut.object({remotePath:Ut.string().describe("Luau expression resolving to a RemoteEvent/RemoteFunction/Bindable, e.g. 'game.ReplicatedStorage.Remotes.AttackEvent' or 'getrenv().game.ReplicatedStorage.Net.RF'. Evaluated as `(loadstring('return '..expr))()`; must yield typeof=='Instance' or the tool errors."),limit:Ut.number().int().describe("Max referrer functions (xrefs) to return (default 100).").optional().default(100),maxScan:Ut.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:Ut.number().int().optional()}),async execute({remotePath:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),1e3),i=Math.min(Math.max(Math.floor(n),100),3e4),l=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local expr = ${s(e)}
local loader = loadstring or load
if type(loader) ~= "function" then return { error = "loadstring/load is not available in this executor." } end
local okc, chunk = pcall(loader, "return " .. expr)
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, target = pcall(chunk)
if not okr then return { error = "Error evaluating expression: " .. tostring(target) } end
if typeof(target) ~= "Instance" then
  return { error = "Expression did not resolve to an Instance (got " .. typeof(target) .. ")." }
end

local class = target.ClassName
local fullName = target:GetFullName()
local okfn, fn2 = pcall(function() return target:GetFullName() end)
if okfn then fullName = fn2 end

local xrefs = {}
local count = 0
local capped = false
local trunc, scanned = __eachFn(${i}, function(fn)
  local via = nil
  for _, u in __ups(fn) do
    if u == target then via = "upvalue"; break end
  end
  if not via then
    for _, c in __consts(fn) do
      if c == target then via = "constant"; break end
    end
  end
  if via then
    count = count + 1
    if #xrefs < ${o} then
      local info = __fnInfo(fn)
      info.via = via
      xrefs[#xrefs + 1] = info
    else
      capped = true
    end
  end
end)

return {
  remote = fullName,
  class = class,
  xrefCount = count,
  functionsScanned = scanned,
  truncatedScan = trunc,
  truncatedOutput = capped,
  xrefs = xrefs,
}
`;return{data:await a.runLuau(l,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as ot}from"zod";var io=u({name:"find-string-xrefs",title:"Find xrefs to a string (IDA xref-to-string)",description:"Cross-reference a string the way IDA jumps from a string literal to every place it is used. Walks every Luau function in the GC and reports each function that has the query as a string constant in its bytecode \u2014 i.e. each function that likely produces or compares against that text. Use exact=true for an exact match, otherwise it does a plain substring search (case-sensitive). Each hit reports the owning script source, line, function name and pointer, plus the first matching constant. Great for pivoting from list-strings to the code that references a remote name, URL, error message, or anti-cheat tag. Requires getgc + getconstants; caps the scan and flags truncation.",category:"Disassembly & Xrefs",input:ot.object({query:ot.string().describe("The string to cross-reference (e.g. a remote name, URL, or error message)."),exact:ot.boolean().describe("If true, only match constants that equal the query exactly. If false (default), match any constant that contains the query as a substring (case-sensitive).").optional().default(!1),limit:ot.number().int().describe("Max matching functions to return (default 100).").optional().default(100),maxScan:ot.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:ot.number().int().optional()}),async execute({query:e,exact:t,limit:n,maxScan:r,threadContext:a},o){let i=Math.min(Math.max(Math.floor(n),1),1e3),l=Math.min(Math.max(Math.floor(r),100),3e4),c=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local query = ${s(e)}
local exact = ${t?"true":"false"}
local lim = ${i}
local matches = {}
local matchCount = 0
local trunc, scanned = __eachFn(${l}, function(fn)
  local matched = nil
  for _, c in __consts(fn) do
    if type(c) == "string" and ((exact and c == query) or (not exact and string.find(c, query, 1, true))) then
      matched = c
      break
    end
  end
  if matched ~= nil then
    matchCount = matchCount + 1
    if #matches < lim then
      local info = __fnInfo(fn)
      matches[#matches + 1] = {
        source = info.source,
        line = info.line,
        name = info.name,
        ptr = info.ptr,
        matchedConstant = matched,
      }
    end
  end
end)

return { query = query, exact = exact, matchCount = matchCount, functionsScanned = scanned, truncatedScan = trunc, matches = matches }
`;return{data:await o.runLuau(c,{timeoutMs:45e3,...a!==void 0?{threadContext:a}:{}})}}});import{z as jt}from"zod";var so=u({name:"find-upvalue-sharing",title:"Find functions sharing the same upvalue table (closure clusters)",description:"Walk every Luau function in the GC and, for each function, inspect its upvalues. Whenever an upvalue is a TABLE, record the owning function under that table's identity. After scanning, report tables that are shared as an upvalue by several distinct functions \u2014 these are typically the shared state / private module table of a single closure family, so the functions that share it belong to the same module or factory. This is how you cluster functions that were defined together (a module's methods all close over the same private table). Each entry reports the table identity, how many functions share it, and a few sample functions. Requires getgc + getupvalues; caps the scan and flags truncation.",category:"Disassembly & Xrefs",input:jt.object({minGroup:jt.number().int().describe("Only report tables shared as an upvalue by at least this many distinct functions (default 3).").optional().default(3),limit:jt.number().int().describe("Max shared tables to return, most-shared first (default 40).").optional().default(40),maxScan:jt.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:jt.number().int().optional()}),async execute({minGroup:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.max(2,Math.floor(e)),i=Math.min(Math.max(Math.floor(t),1),1e3),l=Math.min(Math.max(Math.floor(n),100),3e4),c=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end
if type(__getupvalues) ~= "function" then return { error = "getupvalues is not available in this executor." } end

local shared = {}
local minG = ${o}
local trunc, scanned = __eachFn(${l}, function(fn)
  local seen = {}
  for _, uv in __ups(fn) do
    if type(uv) == "table" then
      local key = tostring(uv)
      -- Count each function once per distinct table, even if it has the table
      -- in multiple upvalue slots.
      if not seen[key] then
        seen[key] = true
        local e = shared[key]
        if not e then e = { count = 0, samples = {} }; shared[key] = e end
        e.count = e.count + 1
        if #e.samples < 4 then e.samples[#e.samples + 1] = __fnInfo(fn) end
      end
    end
  end
end)

local arr = {}
for key, e in shared do
  if e.count >= minG then
    arr[#arr + 1] = { table = key, sharedBy = e.count, sampleFns = e.samples }
  end
end
table.sort(arr, function(a, b) return a.sharedBy > b.sharedBy end)
local out = {}
for i = 1, math.min(#arr, ${i}) do out[i] = arr[i] end
return {
  sharedTables = out,
  totalSharedTables = #arr,
  functionsScanned = scanned,
  truncatedScan = trunc,
}
`;return{data:await a.runLuau(c,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as it}from"zod";var lo=u({name:"list-strings",title:"List all string constants (IDA Strings window)",description:"Walk every Luau function in the GC and collect their string constants \u2014 the runtime equivalent of IDA's Strings window. Reports each unique string, how many functions reference it (xref count), and a sample owning script, sorted by frequency. Filter by substring and minimum length to cut noise. Great for finding interesting literals (remote names, URLs, error messages, anti-cheat tags) and then pivoting with find-string-xrefs. Requires getgc + getconstants; caps the scan and flags truncation.",category:"Disassembly & Xrefs",input:it.object({filter:it.string().describe("Only include strings containing this substring (case-sensitive). Empty = all strings.").optional().default(""),minLength:it.number().int().describe("Ignore strings shorter than this (default 4) to cut noise.").optional().default(4),limit:it.number().int().describe("Max unique strings to return, most-referenced first (default 200).").optional().default(200),maxScan:it.number().int().describe("Max GC functions to scan (default 9000).").optional().default(9e3),threadContext:it.number().int().optional()}),async execute({filter:e,minLength:t,limit:n,maxScan:r,threadContext:a},o){let i=Math.max(1,Math.floor(t)),l=Math.min(Math.max(Math.floor(n),1),1e3),c=Math.min(Math.max(Math.floor(r),100),3e4),d=`
${F}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local strings = {}
local filter = ${s(e)}
local minLen = ${i}
local trunc, scanned = __eachFn(${c}, function(fn)
  for _, c in __consts(fn) do
    if type(c) == "string" and #c >= minLen and (filter == "" or string.find(c, filter, 1, true)) then
      local e = strings[c]
      if not e then e = { count = 0, sample = __fnInfo(fn).source }; strings[c] = e end
      e.count = e.count + 1
    end
  end
end)

local arr = {}
for s, e in strings do arr[#arr + 1] = { value = s, xrefs = e.count, sampleSource = e.sample } end
table.sort(arr, function(a, b) return a.xrefs > b.xrefs end)
local out = {}
for i = 1, math.min(#arr, ${l}) do out[i] = arr[i] end
return { uniqueStrings = #arr, functionsScanned = scanned, truncatedScan = trunc, strings = out }
`;return{data:await o.runLuau(d,{timeoutMs:45e3,...a!==void 0?{threadContext:a}:{}})}}});import{z as Wt}from"zod";var co=u({name:"search-bytecode",title:"Search compiled bytecode for a signature (IDA byte search)",description:"Scan every script returned by getscripts(), dump each one's compiled bytecode with getscriptbytecode, and find scripts whose bytecode contains a given hex byte pattern \u2014 the runtime equivalent of an IDA binary/byte search. Use it to locate scripts carrying a known opcode signature, constant blob, or fingerprint. Provide the pattern as a hex byte string (e.g. '1a2b3c' or '1a 2b 3c'); it is normalized (spaces stripped, lowercased) and must be an even number of hex digits. Each match reports the script's full name, class, and the byte offset of the first hit. Requires getscripts + getscriptbytecode; caps the scan and flags truncation.",category:"Disassembly & Xrefs",input:Wt.object({hexPattern:Wt.string().describe("Hex byte pattern to search for in compiled bytecode, e.g. '1a2b3c' or '1a 2b 3c'. Spaces are stripped and it is lowercased; must contain an even number of hex digits."),limit:Wt.number().int().describe("Max matching scripts to return (default 50).").optional().default(50),maxScan:Wt.number().int().describe("Max scripts to scan (default 6000).").optional().default(6e3),threadContext:Wt.number().int().optional()}),async execute({hexPattern:e,limit:t,maxScan:n,threadContext:r},a){let o=e.replace(/\s+/g,"").toLowerCase();if(o.length===0||o.length%2!==0||!/^[0-9a-f]+$/.test(o))return{data:{error:"Invalid hexPattern: must be a non-empty, even-length string of hex bytes (e.g. '1a2b3c'). Got: "+JSON.stringify(e)},isError:!0};let i=Math.min(Math.max(Math.floor(t),1),1e3),l=Math.min(Math.max(Math.floor(n),50),3e4),c=`
${F}
if type(getscripts) ~= "function" then return { error = "getscripts is not available in this executor." } end
if type(getscriptbytecode) ~= "function" then return { error = "getscriptbytecode is not available in this executor." } end

local pattern = ${s(o)}
local limit = ${i}
local cap = ${l}

local okScripts, scripts = pcall(getscripts)
if not okScripts or type(scripts) ~= "table" then
  return { error = "getscripts() failed or returned no list." }
end

local hexmap = "0123456789abcdef"
local matches = {}
local matchCount = 0
local scanned = 0
local trunc = false

for _, scr in scripts do
  if scanned >= cap then trunc = true break end
  scanned = scanned + 1
  local okBc, bc = pcall(getscriptbytecode, scr)
  if okBc and type(bc) == "string" and #bc > 0 then
    -- Convert raw bytes to a lowercase hex string for substring search.
    local parts = {}
    for i = 1, #bc do
      local b = string.byte(bc, i)
      local hi = math.floor(b / 16) + 1
      local lo = (b % 16) + 1
      parts[i] = string.sub(hexmap, hi, hi) .. string.sub(hexmap, lo, lo)
    end
    local hex = table.concat(parts)
    local hitAt = string.find(hex, pattern, 1, true)
    if hitAt then
      matchCount = matchCount + 1
      if #matches < limit then
        local okName, name = pcall(function() return scr:GetFullName() end)
        local class = ""
        local okClass, cn = pcall(function() return scr.ClassName end)
        if okClass and type(cn) == "string" then class = cn end
        -- hitAt is a 1-based char index into the hex string (2 chars per byte).
        local byteOffset = math.floor((hitAt - 1) / 2)
        matches[#matches + 1] = {
          script = (okName and type(name) == "string") and name or tostring(scr),
          class = class,
          byteOffset = byteOffset,
        }
      end
    end
  end
end

return {
  hexPattern = pattern,
  matchCount = matchCount,
  scriptsScanned = scanned,
  truncatedScan = trunc,
  matches = matches,
}
`;return{data:await a.runLuau(c,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as qc}from"zod";var Gc=`
$procs = Get-Process -Name 'RobloxPlayerBeta' -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowTitle -ne '' } |
  ForEach-Object { [PSCustomObject]@{ pid = $_.Id; title = $_.MainWindowTitle } }
@($procs) | ConvertTo-Json -Compress
`.trim(),uo=u({name:"list-roblox-windows",title:"List Roblox OS windows",description:"List the Roblox player processes on the SERVER host that own a visible OS window, with their process id and window title. Windows-only: runs a PowerShell `Get-Process RobloxPlayerBeta` query and returns the windows that have a non-empty MainWindowTitle. Use this before screenshot-window when more than one Roblox window may be open, to pick the right processId. Returns { windows: [{ pid, title }] } (empty if none are open).",category:"Windows",requiresClient:!1,input:qc.object({}),async execute(e,t){let{stdout:n,stderr:r,code:a}=await t.host.shell.run("powershell",["-NoProfile","-NonInteractive","-Command",Gc],{timeoutMs:15e3});if(a!==0)return{data:{error:`Window enumeration failed (exit ${a??"killed"}).`,stderr:r.trim()},isError:!0};let o=n.trim();if(!o||o==="null")return{data:{windows:[]},summary:"No Roblox windows found."};let i;try{i=JSON.parse(o)}catch(d){return{data:{error:`Could not parse window list: ${d instanceof Error?d.message:String(d)}`,raw:o},isError:!0}}let c=(Array.isArray(i)?i:[i]).filter(d=>d!=null&&typeof d.pid=="number").map(d=>({pid:d.pid,title:String(d.title??"")}));return{data:{windows:c},summary:c.length===0?"No Roblox windows found.":`${c.length} Roblox window(s) found.`}}});import{z as Un}from"zod";var po=u({name:"cache-invalidate",title:"cache.invalidate \u2014 drop an instance from the executor's instance cache",description:"Invalidate the executor's cached reference to a single Instance via cache.invalidate(inst). After invalidation the next time the game indexes that instance it receives a FRESH reference rather than the cached one \u2014 the classic technique for de-syncing a server-trusted object so your subsequent edits to the cached copy go unnoticed, or for forcing the executor to re-wrap a part you have been tampering with. The target is resolved from a Luau path/expression via loadstring('return ' .. expr). Requires the cache library (type(cache)=='table') with cache.invalidate \u2014 both are type-guarded and the call is pcall-wrapped, returning { error } when missing or on failure. Mutates live executor state. Returns { ok } or { error }.",category:"Memory Scan",mutatesState:!0,input:Un.object({instancePath:Un.string().describe("Luau path/expression resolving to the Instance to invalidate, e.g. 'game.Workspace.Boss' or 'game.Players.LocalPlayer.Character.HumanoidRootPart'. Evaluated as `return <expression>`."),threadContext:Un.number().int().optional(),timeoutMs:Un.number().int().optional()}),async execute({instancePath:e,threadContext:t,timeoutMs:n},r){let a=`
if type(cache) ~= "table" then
  return { error = "cache is not available in this executor." }
end
if type(cache.invalidate) ~= "function" then
  return { error = "cache.invalidate is not available in this executor." }
end

local loader = loadstring or load
if type(loader) ~= "function" then
  return { error = "loadstring/load is not available in this executor." }
end
local okc, chunk = pcall(loader, "return " .. ${s(e)})
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, inst = pcall(chunk)
if not okr then
  return { error = "Error evaluating expression: " .. tostring(inst) }
end
if typeof(inst) ~= "Instance" then
  return { error = "Expression did not resolve to an Instance (got " .. typeof(inst) .. ")." }
end

local ok, err = pcall(cache.invalidate, inst)
if not ok then
  return { error = "cache.invalidate failed: " .. tostring(err) }
end
return { ok = true }
`;return{data:await r.runLuau(a,{threadContext:t,timeoutMs:n??15e3})}}});import{z as jn}from"zod";var fo=u({name:"cache-is-cached",title:"cache.iscached \u2014 check whether an instance is in the executor cache",description:"Report whether the executor currently holds a cached reference for a single Instance via cache.iscached(inst). Pairs with cache-invalidate / cache-replace: use it to confirm an instance is cached before invalidating it, or to verify that an invalidate actually dropped the cached reference. The target is resolved from a Luau path/expression via loadstring('return ' .. expr). Read-only. Requires the cache library (type(cache)=='table') with cache.iscached \u2014 both are type-guarded and the call is pcall-wrapped, returning { error } when missing or on failure. Returns { cached } or { error }.",category:"Memory Scan",input:jn.object({instancePath:jn.string().describe("Luau path/expression resolving to the Instance to check, e.g. 'game.Workspace.Boss'. Evaluated as `return <expression>`."),threadContext:jn.number().int().optional(),timeoutMs:jn.number().int().optional()}),async execute({instancePath:e,threadContext:t,timeoutMs:n},r){let a=`
if type(cache) ~= "table" then
  return { error = "cache is not available in this executor." }
end
if type(cache.iscached) ~= "function" then
  return { error = "cache.iscached is not available in this executor." }
end

local loader = loadstring or load
if type(loader) ~= "function" then
  return { error = "loadstring/load is not available in this executor." }
end
local okc, chunk = pcall(loader, "return " .. ${s(e)})
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, inst = pcall(chunk)
if not okr then
  return { error = "Error evaluating expression: " .. tostring(inst) }
end
if typeof(inst) ~= "Instance" then
  return { error = "Expression did not resolve to an Instance (got " .. typeof(inst) .. ")." }
end

local ok, cached = pcall(cache.iscached, inst)
if not ok then
  return { error = "cache.iscached failed: " .. tostring(cached) }
end
return { cached = cached == true }
`;return{data:await r.runLuau(a,{threadContext:t,timeoutMs:n??15e3})}}});import{z as Vt}from"zod";var mo=u({name:"cache-replace",title:"cache.replace \u2014 swap one instance for another in the executor cache",description:"Replace the executor's cached reference for one Instance with another via cache.replace(a, b). After the swap, every script that indexes instance A through the cache transparently receives instance B instead \u2014 a powerful redirection primitive for impersonating one object with another (e.g. pointing a checkpoint, hitbox, or remote wrapper at a substitute you control). Both targets are resolved from Luau path/expressions via loadstring('return ' .. expr). Requires the cache library (type(cache)=='table') with cache.replace \u2014 both are type-guarded and the call is pcall-wrapped, returning { error } when missing or on failure. Mutates live executor state. Returns { ok } or { error }.",category:"Memory Scan",mutatesState:!0,input:Vt.object({instancePath:Vt.string().describe("Luau path/expression resolving to the Instance whose cached reference is replaced (A). Evaluated as `return <expression>`."),replacementPath:Vt.string().describe("Luau path/expression resolving to the Instance to substitute in (B). Evaluated as `return <expression>`."),threadContext:Vt.number().int().optional(),timeoutMs:Vt.number().int().optional()}),async execute({instancePath:e,replacementPath:t,threadContext:n,timeoutMs:r},a){let o=`
if type(cache) ~= "table" then
  return { error = "cache is not available in this executor." }
end
if type(cache.replace) ~= "function" then
  return { error = "cache.replace is not available in this executor." }
end

local loader = loadstring or load
if type(loader) ~= "function" then
  return { error = "loadstring/load is not available in this executor." }
end

local function __resolveInstance(expr)
  local okc, chunk = pcall(loader, "return " .. expr)
  if not okc or type(chunk) ~= "function" then
    return nil, "Failed to compile expression: " .. tostring(chunk)
  end
  local okr, inst = pcall(chunk)
  if not okr then
    return nil, "Error evaluating expression: " .. tostring(inst)
  end
  if typeof(inst) ~= "Instance" then
    return nil, "Expression did not resolve to an Instance (got " .. typeof(inst) .. ")."
  end
  return inst
end

local a, errA = __resolveInstance(${s(e)})
if not a then return { error = "instancePath: " .. errA } end
local b, errB = __resolveInstance(${s(t)})
if not b then return { error = "replacementPath: " .. errB } end

local ok, err = pcall(cache.replace, a, b)
if not ok then
  return { error = "cache.replace failed: " .. tostring(err) }
end
return { ok = true }
`;return{data:await a.runLuau(o,{threadContext:n,timeoutMs:r??15e3})}}});import{z as B}from"zod";function Bt(e){return typeof e=="string"?s(e):typeof e=="number"?Number.isFinite(e)?String(e):"nil":typeof e=="boolean"?e?"true":"false":"nil"}function Wn(e){return`{ ${e.map(t=>Bt(t)).join(", ")} }`}function Dc(e){return`{ ${Object.entries(e).map(([n,r])=>`[${s(n)}] = ${Bt(r)}`).join(", ")} }`}var st=B.union([B.string(),B.number(),B.boolean()]),ho=u({name:"filter-gc",title:"filtergc \u2014 query the GC heap for functions or tables by structural criteria",description:"The headline reflection tool: run the executor's UNC filtergc(filterType, options) against the entire live garbage collector to find Lua closures or tables that match a structural fingerprint, without writing any Luau by hand. Far more targeted than a raw getgc() sweep \u2014 you describe WHAT you are looking for and the executor returns only the objects that match. For filterType='function' the options are { Name?, Hash?, IgnoreExecutor? (default true), Constants? (array of constants the closure must reference), Upvalues? (array of upvalue values the closure must hold) } \u2014 e.g. find the closure that owns the string 'FireServer' and the upvalue 1337. For filterType='table' the options are { Keys? (array of keys that must be present), Values? (array of values that must be present), KeyValuePairs? (record of exact key=value pairs), Metatable? } \u2014 e.g. find the player-data table that has a 'Coins' key. Each match is encoded to a compact summary: functions report { source, line, name } (via debug.info) and tables report { address, keyCount }. Output is capped by 'limit'. Requires filtergc (type-guarded; returns { error } where it is unavailable) and every call is pcall-wrapped so a locked object can never abort the query. Returns { filterType, matchCount, truncated, matches } or { error }.",category:"Reverse Engineering",input:B.object({filterType:B.enum(["function","table"]).describe("What kind of GC object to search for: 'function' (Lua closures) or 'table'. This selects which option set below is meaningful."),options:B.object({Name:B.string().optional().describe("function only: the closure's name (debug.info name) must equal this."),Hash:B.string().optional().describe("function only: the closure's getfunctionhash() must equal this."),IgnoreExecutor:B.boolean().optional().describe("function only: exclude closures that belong to the executor's own VM (default true). Set false to also match executor-internal closures."),Constants:B.array(st).optional().describe("function only: an array of constants (strings/numbers/bools) the closure must reference in its constant table \u2014 e.g. ['FireServer']."),Upvalues:B.array(st).optional().describe("function only: an array of upvalue values the closure must currently hold \u2014 e.g. [1337, true]."),Keys:B.array(st).optional().describe("table only: an array of keys that must all be present in the table \u2014 e.g. ['Coins','Level']."),Values:B.array(st).optional().describe("table only: an array of values that must all be present in the table."),KeyValuePairs:B.record(B.string(),st).optional().describe("table only: a record of exact key=value pairs the table must contain \u2014 e.g. { GodMode = true }."),Metatable:st.optional().describe("table only: the table's metatable must equal this value (rarely used; usually supplied as a previously found reference is not possible here, so prefer Keys/Values).")}).describe("The UNC filtergc criteria. Only the fields relevant to filterType are emitted into the Luau."),limit:B.number().int().default(100).describe("Maximum number of matches to encode and return (default 100). Hitting this sets truncated=true."),threadContext:B.number().int().optional(),timeoutMs:B.number().int().optional()}),async execute({filterType:e,options:t,limit:n,threadContext:r,timeoutMs:a},o){let i=Math.min(Math.max(Math.floor(n),1),2e3),l=[];if(e==="function"){t.Name!==void 0&&l.push(`Name = ${Bt(t.Name)}`),t.Hash!==void 0&&l.push(`Hash = ${Bt(t.Hash)}`);let f=t.IgnoreExecutor!==!1;l.push(`IgnoreExecutor = ${f?"true":"false"}`),t.Constants&&t.Constants.length>0&&l.push(`Constants = ${Wn(t.Constants)}`),t.Upvalues&&t.Upvalues.length>0&&l.push(`Upvalues = ${Wn(t.Upvalues)}`)}else t.Keys&&t.Keys.length>0&&l.push(`Keys = ${Wn(t.Keys)}`),t.Values&&t.Values.length>0&&l.push(`Values = ${Wn(t.Values)}`),t.KeyValuePairs&&Object.keys(t.KeyValuePairs).length>0&&l.push(`KeyValuePairs = ${Dc(t.KeyValuePairs)}`),t.Metatable!==void 0&&l.push(`Metatable = ${Bt(t.Metatable)}`);let d=`
if type(filtergc) ~= "function" then
  return { error = "filtergc is not available in this executor." }
end

local __getinfo = (type(debug) == "table" and (debug.info or debug.getinfo)) or nil

local opts = ${`{ ${l.join(", ")} }`}

-- Run filtergc with returnOne=false so we get the full match list.
local ok, matches = pcall(filtergc, ${s(e)}, opts, false)
if not ok then
  return { error = "filtergc failed: " .. tostring(matches) }
end
if type(matches) ~= "table" then
  -- filtergc may return a single object when returnOne is honoured oddly; wrap it.
  if matches == nil then
    matches = {}
  else
    matches = { matches }
  end
end

local LIMIT = ${i}
local out = {}
local total = 0
local truncated = false

local function fnSummary(fn)
  local src, line, name = "?", -1, nil
  if type(__getinfo) == "function" then
    local oks, s = pcall(__getinfo, fn, "s"); if oks and type(s) == "string" then src = s end
    local okl, l = pcall(__getinfo, fn, "l"); if okl and type(l) == "number" then line = l end
    local okn, n = pcall(__getinfo, fn, "n"); if okn and type(n) == "string" and n ~= "" then name = n end
  end
  return { kind = "function", source = src, line = line, name = name }
end

local function tableSummary(t)
  local addr = tostring(t)
  local keyCount = 0
  pcall(function()
    for _ in pairs(t) do keyCount = keyCount + 1 end
  end)
  return { kind = "table", address = addr, keyCount = keyCount }
end

for _, obj in matches do
  total = total + 1
  if #out < LIMIT then
    local ot = type(obj)
    if ot == "function" then
      out[#out + 1] = fnSummary(obj)
    elseif ot == "table" then
      out[#out + 1] = tableSummary(obj)
    else
      out[#out + 1] = { kind = ot, value = tostring(obj) }
    end
  else
    truncated = true
  end
end

return {
  filterType = ${s(e)},
  matchCount = total,
  truncated = truncated,
  matches = out,
}
`;return{data:await o.runLuau(d,{threadContext:r,timeoutMs:a??45e3})}}});import{z as Vn}from"zod";var go=u({name:"get-call-stack",title:"Walk the current Luau call stack (debug.info frames)",description:"Unwind the current Luau call stack from the executing thread and return one frame per level: { level, name, source, line }. Walks debug.info(level, 'nsl') (name / source / currentline) from level 1 outward, stopping at the first level that yields nil or after maxLevels frames. Use it to see who is calling the code you just ran \u2014 the chain of functions leading into the current execution \u2014 which is invaluable when reasoning about a hook callback or a deferred task's origin. Requires debug.info (or debug.getinfo) \u2014 type-guarded and pcall-wrapped, returning { error } on an executor that lacks it. Returns { frames } or { error }.",category:"Reverse Engineering",input:Vn.object({maxLevels:Vn.number().int().default(20).describe("Maximum number of stack frames to walk before stopping (default 20)."),threadContext:Vn.number().int().optional(),timeoutMs:Vn.number().int().optional()}),async execute({maxLevels:e,threadContext:t,timeoutMs:n},r){let o=`
local __info = (type(debug) == "table" and (debug.info or debug.getinfo)) or nil
if type(__info) ~= "function" then
  return { error = "debug.info is not available in this executor." }
end

local MAX = ${Math.min(Math.max(Math.floor(e),1),200)}
local frames = {}

for level = 1, MAX do
  -- debug.info accepts (level, "nsl") and returns name, source, line in that order.
  local ok, a, b, c = pcall(__info, level, "nsl")
  if not ok then
    break
  end
  -- A level past the top of the stack returns no values (a is nil with nothing set).
  if a == nil and b == nil and c == nil then
    break
  end
  -- debug.getinfo returns a single table; debug.info returns multiple values.
  if type(a) == "table" then
    frames[#frames + 1] = {
      level = level,
      name = a.name,
      source = a.short_src or a.source,
      line = a.currentline or a.linedefined,
    }
  else
    frames[#frames + 1] = {
      level = level,
      name = (type(a) == "string" and a ~= "" and a) or nil,
      source = b,
      line = c,
    }
  end
end

return { frames = frames }
`;return{data:await r.runLuau(o,{threadContext:t,timeoutMs:n??15e3})}}});import{z as Bn}from"zod";var bo=u({name:"get-hidden-ui",title:"gethui \u2014 inspect the executor's hidden protected UI container",description:"Return a shallow tree of the executor's hidden, protected GUI container via gethui(). This is the parent that executors hand back for ScreenGuis they want kept away from CoreGui/PlayerGui and shielded from the game's anti-cheat \u2014 the usual home of cheat menus, ESP layers, and overlays. The tool walks gethui():GetChildren() and returns a { name, class, children } tree capped at depth 3 with a per-node child cap, reporting how many children were truncated. Requires gethui \u2014 type-guarded and pcall-wrapped, returning { error } when missing or on failure. Returns { root: { name, class, childCount, children } } or { error }.",category:"Inspection",input:Bn.object({maxChildren:Bn.number().int().default(50).describe("Maximum children shown per node (default 50). Extra children are counted in truncatedChildren."),threadContext:Bn.number().int().optional(),timeoutMs:Bn.number().int().optional()}),async execute({maxChildren:e,threadContext:t,timeoutMs:n},r){let o=`
if type(gethui) ~= "function" then
  return { error = "gethui is not available in this executor." }
end

local okHui, hui = pcall(gethui)
if not okHui or hui == nil then
  return { error = "gethui failed: " .. tostring(hui) }
end

local MAX_DEPTH = 3
local MAX_CHILDREN = ${Math.min(Math.max(Math.floor(e),1),500)}

local function build(inst, depth)
  local node = {}
  pcall(function() node.name = inst.Name end)
  pcall(function() node.class = inst.ClassName end)

  local ok, kids = pcall(function() return inst:GetChildren() end)
  if not ok or type(kids) ~= "table" then
    return node
  end
  node.childCount = #kids
  if depth >= MAX_DEPTH then
    if #kids > 0 then node.truncatedChildren = #kids end
    return node
  end
  local shown = math.min(#kids, MAX_CHILDREN)
  local children = {}
  for i = 1, shown do
    children[#children + 1] = build(kids[i], depth + 1)
  end
  node.children = children
  if #kids > shown then node.truncatedChildren = #kids - shown end
  return node
end

return { root = build(hui, 0) }
`;return{data:await r.runLuau(o,{threadContext:t,timeoutMs:n??15e3})}}});import{z as zn}from"zod";var yo=u({name:"get-script-bytecode",title:"getscriptbytecode \u2014 dump a script's compiled bytecode",description:"Retrieve the compiled Luau bytecode for a script via the executor's getscriptbytecode. The script is resolved from a Luau expression (typically a path to a LuaSourceContainer, e.g. 'game.ReplicatedStorage.Module') via loadstring('return ' .. expr). Returns the total byte count and a hex preview of the first `previewBytes` bytes (the full bytecode is not shipped across the bridge). Requires getscriptbytecode \u2014 type-guarded and pcall-wrapped, returning { error } when missing or on failure. Returns { byteCount, hexPreview } or { error }.",category:"Reverse Engineering",input:zn.object({scriptPath:zn.string().describe("Luau expression resolving to a LuaSourceContainer, e.g. 'game.ReplicatedStorage.Module'. Evaluated as `return <expression>`."),previewBytes:zn.number().int().describe("How many leading bytecode bytes to include as a hex preview (default 64).").optional().default(64),threadContext:zn.number().int().optional()}),async execute({scriptPath:e,previewBytes:t,threadContext:n},r){let a=Math.min(Math.max(Math.floor(t),0),4096),o=`
if type(getscriptbytecode) ~= "function" then
  return { error = "getscriptbytecode is not available in this executor." }
end

local loader = loadstring or load
if type(loader) ~= "function" then
  return { error = "loadstring/load is not available in this executor." }
end
local okc, chunk = pcall(loader, "return " .. ${s(e)})
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, script = pcall(chunk)
if not okr then
  return { error = "Error evaluating expression: " .. tostring(script) }
end
if typeof(script) ~= "Instance" then
  return { error = "Expression did not resolve to an Instance (got " .. typeof(script) .. ")." }
end

local ok, bytecode = pcall(getscriptbytecode, script)
if not ok then
  return { error = "getscriptbytecode failed: " .. tostring(bytecode) }
end
if type(bytecode) ~= "string" then
  return { error = "getscriptbytecode did not return a string (got " .. type(bytecode) .. ")." }
end

local n = math.min(#bytecode, ${a})
local hex = {}
for i = 1, n do hex[i] = string.format("%02x", string.byte(bytecode, i)) end
return { byteCount = #bytecode, hexPreview = table.concat(hex) }
`;return{data:await r.runLuau(o,{threadContext:n,timeoutMs:2e4})}}});import{z as jr}from"zod";var vo=u({name:"get-script-hash",title:"getscripthash \u2014 content hash of a script",description:"Compute the content hash of a script via the executor's getscripthash. The script is resolved from a Luau expression (typically a path to a LuaSourceContainer, e.g. 'game.ReplicatedStorage.Module') via loadstring('return ' .. expr). Handy for detecting when a script's bytecode/source changes between two checks. Requires getscripthash \u2014 type-guarded and pcall-wrapped, returning { error } when missing or on failure. Returns { hash } or { error }.",category:"Reverse Engineering",input:jr.object({scriptPath:jr.string().describe("Luau expression resolving to a LuaSourceContainer, e.g. 'game.ReplicatedStorage.Module'. Evaluated as `return <expression>`."),threadContext:jr.number().int().optional()}),async execute({scriptPath:e,threadContext:t},n){let r=`
if type(getscripthash) ~= "function" then
  return { error = "getscripthash is not available in this executor." }
end

local loader = loadstring or load
if type(loader) ~= "function" then
  return { error = "loadstring/load is not available in this executor." }
end
local okc, chunk = pcall(loader, "return " .. ${s(e)})
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, script = pcall(chunk)
if not okr then
  return { error = "Error evaluating expression: " .. tostring(script) }
end
if typeof(script) ~= "Instance" then
  return { error = "Expression did not resolve to an Instance (got " .. typeof(script) .. ")." }
end

local ok, hash = pcall(getscripthash, script)
if not ok then
  return { error = "getscripthash failed: " .. tostring(hash) }
end
return { hash = hash }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as zt}from"zod";var ko=u({name:"get-stack",title:"debug.getstack \u2014 read live Luau stack slots at a level",description:"Read the raw values currently sitting on the Luau stack at a given call level via the executor's debug.getstack. Without 'index' it returns every live stack slot at that level as an encoded list (Instances/EnumItems/tables are flattened to a JSON-friendly shape); with 'index' it returns just that one slot's encoded value. This exposes the in-flight locals and temporaries of a running function \u2014 the values a frame is actively working with \u2014 letting you snapshot what a callback or hooked function holds at the moment your code runs. Requires debug.getstack \u2014 type-guarded and pcall-wrapped, returning { error } when missing or on failure. Returns { level, index?, value } / { level, count, values } or { error }.",category:"Reverse Engineering",input:zt.object({level:zt.number().int().describe("The call-stack level to read (1 = the function calling getstack, i.e. the executing chunk; higher = further up the stack)."),index:zt.number().int().optional().describe("Optional 1-based stack slot index. When given, only that single slot is read and returned; when omitted, the whole stack table at 'level' is returned."),threadContext:zt.number().int().optional(),timeoutMs:zt.number().int().optional()}),async execute({level:e,index:t,threadContext:n,timeoutMs:r},a){let o=Math.floor(e),i=typeof t=="number"&&Number.isFinite(t),l=i?Math.floor(t):void 0,c=`
${_e}
if type(debug) ~= "table" or type(debug.getstack) ~= "function" then
  return { error = "debug.getstack is not available in this executor." }
end

local LEVEL = ${o}
${i?`local INDEX = ${l}
local ok, value = pcall(debug.getstack, LEVEL, INDEX)
if not ok then
  return { error = "debug.getstack failed: " .. tostring(value) }
end
return { level = LEVEL, index = INDEX, value = __encode(value) }`:`local ok, stack = pcall(debug.getstack, LEVEL)
if not ok then
  return { error = "debug.getstack failed: " .. tostring(stack) }
end
if type(stack) ~= "table" then
  return { level = LEVEL, count = 0, values = {} }
end
local values = {}
local count = 0
for i, v in pairs(stack) do
  count = count + 1
  values[#values + 1] = { index = i, value = __encode(v) }
end
return { level = LEVEL, count = count, values = values }`}
`;return{data:await a.runLuau(c,{threadContext:n,timeoutMs:r??15e3})}}});import{z as Kn}from"zod";var xo=u({name:"list-rendered-instances",title:"getrendered \u2014 list instances currently being rendered",description:"Enumerate the instances the engine is currently rendering via getrendered() and return { count, samples }, where each sample is { class, name, path }. This is the set of objects actually on screen this frame \u2014 useful for ESP/render auditing, spotting which parts/GUIs are visible, or correlating a render spike with specific instances. The full count is reported even though only a capped sample of entries is returned. Requires getrendered \u2014 type-guarded and pcall-wrapped, returning { error } when missing or on failure. Returns { count, truncated, samples } or { error }.",category:"Inspection",input:Kn.object({limit:Kn.number().int().default(100).describe("Maximum number of sample entries to return (default 100). The full count is always reported."),threadContext:Kn.number().int().optional(),timeoutMs:Kn.number().int().optional()}),async execute({limit:e,threadContext:t,timeoutMs:n},r){let o=`
if type(getrendered) ~= "function" then
  return { error = "getrendered is not available in this executor." }
end

local ok, rendered = pcall(getrendered)
if not ok then
  return { error = "getrendered failed: " .. tostring(rendered) }
end
if type(rendered) ~= "table" then
  return { count = 0, truncated = false, samples = {} }
end

local LIMIT = ${Math.min(Math.max(Math.floor(e),1),2e3)}
local samples = {}
local count = 0
local truncated = false

for _, inst in rendered do
  count = count + 1
  if #samples < LIMIT then
    local entry = {}
    pcall(function() entry.class = inst.ClassName end)
    pcall(function() entry.name = inst.Name end)
    local okp, full = pcall(function() return inst:GetFullName() end)
    entry.path = okp and full or tostring(inst)
    samples[#samples + 1] = entry
  else
    truncated = true
  end
end

return { count = count, truncated = truncated, samples = samples }
`;return{data:await r.runLuau(o,{threadContext:t,timeoutMs:n??15e3})}}});import{z as Fe}from"zod";function Xe(e){return{clientId:e.id,username:e.username,displayName:e.displayName,userId:e.userId,placeId:e.placeId,executor:e.executor,connectedAt:new Date(e.connectedAt).toISOString()}}function Re(e){switch(e.status){case"resolved":return{status:"resolved",client:Xe(e.client)};case"none":return{status:"none",reason:e.reason};case"ambiguous":return{status:"ambiguous",candidates:e.candidates.map(Xe)}}}var _o=u({name:"agent-context",title:"Build a live context brief for the AI agent",description:"READ-ONLY. Bootstrap an AI agent with the current MCP/session/game context in one call. Returns connected clients, this session's active selection resolution, game identity, executor identity/capabilities, and actionable next steps. Use this at the start of a task or after a reconnect instead of separately guessing which client, place, executor, or capability set is active. If multiple clients are connected, the brief tells you to select one; it never silently chooses between distinct accounts. Optional capability probing is safe but slower. The tool never mutates game state.",category:"Utility",requiresClient:!1,input:Fe.object({includeGameInfo:Fe.boolean().optional().default(!0).describe("Include PlaceId/JobId/game metadata when this session resolves to a client."),includeExecutorInfo:Fe.boolean().optional().default(!0).describe("Include executor identity and headline capability flags when a client is active."),includeCapabilities:Fe.boolean().optional().default(!1).describe("Run the larger side-effect-free capability matrix probe; slower but useful for planning advanced tools."),includeHistory:Fe.boolean().optional().default(!0).describe("Include a compact tail of this session's successful/failed tool history."),historyLimit:Fe.number().int().positive().max(50).optional().default(12),includeMemory:Fe.boolean().optional().default(!0).describe("Include recent persistent agent-memory entries for continuity across tasks."),memoryLimit:Fe.number().int().positive().max(50).optional().default(8)}),async execute({includeGameInfo:e,includeExecutorInfo:t,includeCapabilities:n,includeHistory:r,historyLimit:a,includeMemory:o,memoryLimit:i},l){let c=l.clients.list().map(Xe),d=Re(l.session.resolve()),p={},f=[];if(r){let h=await l.sessionLogger.read(l.session.id);p.history=h.slice(-a).map(g=>({seq:g.seq,tool:g.tool,elapsedMs:g.elapsedMs,clientId:g.clientId,outcome:g.error?"error":"ok",...g.error?{error:g.error}:{}}))}if(o){let h=await l.playbooks.list({tag:"agent-memory"});p.memory=h.slice(0,i).map(g=>({name:g.name,description:g.description,tags:g.tags,updatedAt:g.updatedAt}))}if(c.length===0)f.push("Connect a Roblox executor client by running the connector loader, then call agent-context again.");else if(d.status==="ambiguous")f.push("Call select-client with the intended client/account before using client-bound tools.");else if(d.status==="none")f.push("The pinned client is offline; refresh with list-clients and select a connected client.");else{f.push("The session has an active client. Confirm game identity before place-specific actions.");let h=async b=>{try{let m=await l.invokeTool(b,{});return{data:m.data,...m.summary?{summary:m.summary}:{}}}catch(m){return{error:m instanceof Error?m.message:String(m)}}},g=[];e&&g.push(h("get-game-info").then(b=>{p.game=b})),t&&g.push(h("get-executor-info").then(b=>{p.executor=b})),n&&g.push(h("test-capabilities").then(b=>{p.capabilities=b})),await Promise.all(g),f.push("For uncertain game state, call observe-world and resolve semantic targets before acting."),f.push("Use smart-task in plan or preview mode, then execute with explicit assertions and mutation approval."),f.push("Use tool-schema on any selected tool whose required fields are not already obvious.")}return{data:{session:{id:l.session.id,label:l.session.label},clients:c,active:d,observations:p,recommendations:f,readyForClientTools:d.status==="resolved"},summary:c.length===0?"No Roblox clients connected.":d.status==="resolved"?`Context loaded for ${d.client.username??d.client.clientId}.`:`Context loaded; client selection is ${d.status}.`}}});import{z as me}from"zod";var Wr="agent-memory";function Vr(e){return`memory_${e.replace(/[^a-zA-Z0-9_-]/g,"_").slice(0,56)||"unnamed"}`}function Uc(e){try{let t=JSON.parse(e);return t.kind!=="agent-memory"||typeof t.key!="string"?null:t}catch{return null}}var wo=u({name:"agent-memory",title:"Remember and recall successful agent facts/workflows",description:"PERSISTENT AGENT MEMORY. Store, recall, or forget compact facts and successful workflow notes across tasks. Memory is scoped optionally by game/place/executor and stored in the existing local playbook store, never in the Roblox game. Use remember after a verified discovery or successful workflow; use recall before planning a similar task. The learn-session operation summarizes the current session's successful tool sequence into a reusable episodic memory. Do not store secrets or tokens.",category:"Utility",requiresClient:!1,mutatesState:!1,input:me.object({operation:me.enum(["remember","recall","forget","learn-session"]).describe("Memory operation."),key:me.string().min(1).max(120).optional().describe("Stable memory key, such as 'shop-button-path'."),text:me.string().max(1e4).optional().describe("Human-readable fact or workflow note to remember."),facts:me.record(me.string(),me.unknown()).optional().describe("Structured facts to store alongside the note."),scope:me.string().max(200).optional().describe("Optional game/place/executor scope label."),query:me.string().max(200).optional().describe("Recall filter matched against key, text, facts, and scope."),limit:me.number().int().positive().max(100).optional().default(10).describe("Maximum memories to return."),fromSeq:me.number().int().positive().optional().describe("For learn-session, only use trace records from this sequence onward.")}),async execute({operation:e,key:t,text:n,facts:r,scope:a,query:o,limit:i,fromSeq:l},c){if(e==="remember"){if(!t)return{data:{ok:!1,error:"remember requires key"},isError:!0};if(!n&&!r)return{data:{ok:!1,error:"remember requires text or facts"},isError:!0};let h={kind:"agent-memory",key:t,...n?{text:n}:{},...r?{facts:r}:{},...a?{scope:a}:{},createdAt:Date.now(),sourceSession:c.session.id},g=await c.playbooks.save({name:Vr(t),source:JSON.stringify(h),description:n?.slice(0,180)??`Facts for ${t}`,tags:[Wr,...a?[a]:[]]});return{data:{ok:!0,key:t,name:g.name,scope:a},summary:`Remembered "${t}".`}}if(e==="forget"){if(!t)return{data:{ok:!1,error:"forget requires key"},isError:!0};let h=await c.playbooks.delete(Vr(t));return{data:{ok:h,key:t,deleted:h},summary:h?`Forgot "${t}".`:`No memory found for "${t}".`}}if(e==="learn-session"){let h=(await c.sessionLogger.read(c.session.id,{from:l})).filter(y=>y.result!==void 0),g=h.map(y=>y.tool),b=t??`workflow_${Date.now()}`,m={kind:"agent-memory",key:b,text:n??`Successful session workflow: ${g.join(" \u2192 ")||"no successful tools"}`,facts:{tools:g,count:h.length,...r??{}},...a?{scope:a}:{},createdAt:Date.now(),sourceSession:c.session.id};return await c.playbooks.save({name:Vr(b),source:JSON.stringify(m),description:m.text,tags:[Wr,"workflow",...a?[a]:[]]}),{data:{ok:!0,key:b,tools:g,count:h.length},summary:`Learned ${h.length}-step session workflow.`}}let d=await c.playbooks.list({tag:Wr}),p=o?.toLowerCase(),f=d.map(h=>Uc(h.source)).filter(h=>h!==null).filter(h=>!a||h.scope===a).filter(h=>p?JSON.stringify(h).toLowerCase().includes(p):!0).sort((h,g)=>g.createdAt-h.createdAt).slice(0,i);return{data:{ok:!0,count:f.length,memories:f},summary:`Recalled ${f.length} memory item(s).`}}});import{z as j}from"zod";var jc=new Set(["a","an","and","are","can","do","for","from","how","i","in","into","is","it","me","my","of","on","or","please","the","this","to","with","you"]),Wc=[["inspect","examine","look","read","check","show"],["find","search","locate","where","discover"],["instance","object","part","model","component"],["gui","ui","interface","button","menu","screen"],["click","tap","press","input","mouse","keyboard","touch"],["camera","view","aim","lookat","fov"],["script","source","code","module","bytecode","decompile"],["remote","remotes","network","event","fire","invoke","rpc"],["player","character","user","account"],["money","cash","coins","currency","score","xp","value","stats"],["hook","trace","monitor","log","spy","connection","signal"],["memory","gc","garbage","closure","upvalue","constant"],["actor","parallel","luastate","state","channel","thread"],["performance","fps","latency","lag","render","diagnostic","health"],["detect","detected","detection","footprint","exposure","leak","fingerprint","provenance"],["set","change","write","edit","modify","update","create","destroy"],["observe","perceive","scan","world","scene","nearby","visible"],["verify","assert","prove","confirm","validate"],["recover","fallback","repair","failure","error"],["teach","record","demonstrate","learn","playbook","macro"]],So=new Map;for(let e of Wc)for(let t of e)So.set(t,e);function Kt(e){return e.toLowerCase().split(/[^a-z0-9]+/).filter(t=>t.length>1&&!jc.has(t))}function Vc(e){return{name:e.name.toLowerCase(),title:e.title.toLowerCase(),category:e.category.toLowerCase(),description:e.description.toLowerCase()}}function Oe(e,t,n){return n.includes(e)||t.includes(e)}function qe(e,t,n=10){let r=[...new Set(Kt(e))],a=e.toLowerCase();return t.map(o=>{let i=Vc(o),l=Kt(i.name.replace(/-/g," ")),c=Kt(i.title),d=Kt(i.category.replace(/&/g," ")),p=Kt(i.description),f=new Set,h=0;a.includes(i.name)&&(h+=80);for(let m of r){Oe(m,i.name,l)?(h+=28,f.add(m)):Oe(m,i.title,c)?(h+=18,f.add(m)):Oe(m,i.category,d)?(h+=12,f.add(m)):Oe(m,i.description,p)&&(h+=7,f.add(m));let y=So.get(m);if(y){let w=y.find(C=>Oe(C,i.name,l)||Oe(C,i.title,c)||Oe(C,i.category,d)||Oe(C,i.description,p));w&&!f.has(m)&&(h+=4,f.add(`${m}\u2192${w}`))}}let g=[...f],b=g.length?`Matched ${g.slice(0,5).join(", ")}.`:"Broad catalog candidate; inspect its schema before calling.";return{tool:o,score:h,matchedTerms:g,why:b}}).filter(o=>o.score>0).sort((o,i)=>i.score-o.score||o.tool.name.localeCompare(i.tool.name)).slice(0,Math.max(1,Math.min(n,50)))}var Bc=[{id:"inspect-instance",title:"Find and understand an in-game object",description:"Locate the target first, inspect its properties, then verify the exact path or subtree before editing it.",patterns:[/\b(inspect|examine|find|locate|where|property|properties|instance|object|part|model)\b/i],steps:[{tool:"observe-world",phase:"discover",why:"Build one compact world, character, camera, GUI, and interactable snapshot."},{tool:"search-instances",phase:"discover",why:"Find likely instances by class/name/property."},{tool:"get-instance-properties",phase:"discover",why:"Read the target's common properties and attributes."},{tool:"get-instance-tree",phase:"verify",why:"Confirm surrounding structure and child paths."}]},{id:"interact-with-client",title:"Drive the local game like a player",description:"Discover UI targets, use the most specific interaction, then verify the resulting state.",patterns:[/\b(click|tap|press|type|input|mouse|keyboard|touch|camera|gui|ui|menu|button|move)\b/i],steps:[{tool:"observe-world",phase:"discover",why:"Ground the task in visible GUI, nearby 3D targets, and the current custom character."},{tool:"list-gui-elements",phase:"discover",why:"Enumerate visible GUI targets and paths."},{tool:"click-button",phase:"act",why:"Use semantic button activation when the target is a GuiButton."},{tool:"virtual-input",phase:"act",why:"Use low-level keyboard, mouse, touch, or gamepad input when needed."},{tool:"camera-control",phase:"act",why:"Read or move the local camera when the task involves view or aim."},{tool:"assert-state",phase:"verify",why:"Prove the intended game or UI state changed after the interaction."}]},{id:"adaptive-goal",title:"Run a bounded, self-correcting game task",description:"Observe current state, execute an approved adaptive plan, prove the outcome, and classify failures instead of retrying blindly.",patterns:[/\b(goal|task|workflow|autopilot|automatic|adapt|replan|recover|verify|assert|prove)\b/i],steps:[{tool:"observe-world",phase:"discover",why:"Create grounded semantic targets and a compact state baseline."},{tool:"smart-task",phase:"act",why:"Execute explicit steps under call, time, mutation, and loop budgets."},{tool:"assert-state",phase:"verify",why:"Evaluate actual success predicates rather than tool-return status."},{tool:"explain-failure",phase:"recover",why:"Classify failed evidence and select a non-repeating fallback."}]},{id:"teach-workflow",title:"Learn a reusable workflow from a demonstration",description:"Record bounded input and game events, then generate a conservative semantic playbook for review.",patterns:[/\b(teach|record|demonstrate|demonstration|learn|macro|repeat what i do|playback)\b/i],steps:[{tool:"teach-mode",phase:"discover",why:"Capture the demonstration and infer guarded semantic actions."},{tool:"assert-state",phase:"verify",why:"Attach explicit success checks before replaying the learned playbook."}]},{id:"understand-remote",title:"Understand or safely exercise a remote",description:"Inventory remotes, infer the signature, observe traffic, and only then invoke the remote if necessary.",patterns:[/\b(remote|remotes|network|rpc|fire|invoke|spy|traffic|listener)\b/i],steps:[{tool:"list-remotes",phase:"discover",why:"Inventory RemoteEvent and RemoteFunction targets."},{tool:"get-remote-signature",phase:"discover",why:"Inspect callback/signature clues before constructing arguments."},{tool:"monitor-remote",phase:"discover",why:"Capture live calls when the signature is unclear."},{tool:"fire-remote",phase:"act",why:"Invoke the selected remote only after the target and arguments are understood."}]},{id:"audit-execution-footprint",title:"Audit a script or closure for runtime detection exposure",description:"Run one bounded read-only Luau audit for virtual-input provenance, environment leaks, closure identity, hooks, and executor fingerprints, then optionally compare ambient anti-cheat surfaces.",patterns:[/\b(script detected|detection risk|execution footprint|executor fingerprint|environment leak|getfenv leak|virtual input provenance|input provenance|closure exposure)\b/i],steps:[{tool:"execution-footprint-audit",phase:"discover",why:"Collect bounded target-specific evidence and distinguish confirmed exposure from heuristic risk."},{tool:"get-anticheat-surfaces",phase:"verify",why:"Cross-check lightweight ambient watcher surfaces without executing or concealing anything."}]},{id:"inspect-actor-state",title:"Inspect or execute an Actor Lua state",description:"Probe Actor/state support, identify the target state, inspect its actors, then execute or monitor only when requested.",patterns:[/\b(actor|actors|parallel|lua ?state|luastate|state proxy|comm(?:unication)? channel)\b/i],steps:[{tool:"actor-capabilities",phase:"discover",why:"Confirm which Actor, LuaStateProxy, channel, and event primitives exist."},{tool:"list-actors",phase:"discover",why:"Inventory Actor targets before resolving a state or scheduling code."},{tool:"list-lua-states",phase:"discover",why:"Map active state IDs to their associated Actors."},{tool:"get-lua-state",phase:"verify",why:"Resolve and verify the exact Actor/script state before acting."},{tool:"run-on-actor",phase:"act",why:"Schedule confirmed code on the selected Actor state."}]},{id:"inspect-closure",title:"Inspect, classify, or manipulate a closure",description:"Probe closure support, inspect metadata and pools, then clone/hook/restore only through explicit confirmed operations.",patterns:[/\b(closure|upvalue|proto|constant pool|function hash|newcclosure|hooked function)\b/i],steps:[{tool:"closure-capabilities",phase:"discover",why:"Confirm exact closure primitives and executor aliases before choosing an operation."},{tool:"inspect-closure",phase:"discover",why:"Read type, source, constants, upvalues, protos, and hash in one bounded call."},{tool:"is-function-hooked",phase:"verify",why:"Check hook state before installing or restoring a function hook."}]},{id:"reverse-engineer",title:"Trace code from a behavior or symbol",description:"Search source/instances first, then inspect module source, bytecode, closures, or cross-references as needed.",patterns:[/\b(script|source|code|module|bytecode|decompile|function|constant|upvalue|closure|reverse|trace)\b/i],steps:[{tool:"search-instances",phase:"discover",why:"Locate candidate scripts or modules."},{tool:"script-grep",phase:"discover",why:"Search script text for names, strings, or behavior."},{tool:"get-script-content",phase:"discover",why:"Read the relevant source or recovered content."},{tool:"search-bytecode",phase:"verify",why:"Use bytecode/xref analysis when source is absent or misleading."}]},{id:"find-player-value",title:"Find a player's money, score, XP, or similar value",description:"Use the value-discovery heuristic, inspect the winning path, then read or write only the confirmed value.",patterns:[/\b(money|cash|coins|currency|score|xp|experience|health|stats|value|player|character)\b/i],steps:[{tool:"discover-player-values",phase:"discover",why:"Rank likely player-value paths using a live heuristic walk."},{tool:"get-instance-properties",phase:"verify",why:"Confirm the winning path and its current type/value."},{tool:"read-path-value",phase:"verify",why:"Read the exact path in a compact, auditable form."},{tool:"write-path-value",phase:"act",why:"Only use after confirming the target and intended mutation."}]}];function lt(e,t){let n=/\b(money|cash|coins|currency|score|xp|experience|stats)\b/i.test(e);return Bc.filter(r=>n&&r.id==="find-player-value"?!0:r.patterns.some(a=>a.test(e))).map(r=>({id:r.id,title:r.title,description:r.description,steps:r.steps.filter(a=>t.has(a.tool))})).filter(r=>r.steps.length>0)}var zc=j.object({id:j.string().min(1).max(64).describe("Stable step identifier used by later $steps.<id> references."),tool:j.string().min(1).describe("Registered kebab-case tool name."),input:j.record(j.string(),j.unknown()).optional().default({}).describe("Tool arguments; values may use $steps references."),verifyWith:j.string().optional().describe("Optional read-only verifier tool; defaults to the tool contract's verifier."),verifyInput:j.record(j.string(),j.unknown()).optional().describe("Verifier arguments; defaults to the resolved action input."),retries:j.number().int().nonnegative().max(3).optional().default(0).describe("Retries for read-only failures; mutations are not retried unless retryMutations=true.")});function Kc(e,t){let n=e;for(let r of t.split(".").filter(Boolean)){if(n==null||typeof n!="object")return;Array.isArray(n)&&/^\d+$/.test(r)?n=n[Number(r)]:n=n[r]}return n}function Hn(e,t){if(typeof e=="string"){let n=/^\$(?:steps|result)\.([A-Za-z0-9_-]+)(?:\.(.*))?$/.exec(e);if(!n)return e;let r=t.get(n[1]);if(r===void 0)throw new Error(`Unknown step reference "${e}".`);return n[2]?Kc(r,n[2]):r}return Array.isArray(e)?e.map(n=>Hn(n,t)):e&&typeof e=="object"?Object.fromEntries(Object.entries(e).map(([n,r])=>[n,Hn(r,t)])):e}function Co(e){return e.ai??{phase:e.mutatesState?"act":"observe",prerequisites:[],consumes:[],produces:[],verifiesWith:[],alternatives:[],requiresCapabilities:[],sideEffects:e.mutatesState?["writes live game/client state"]:[],failureRecovery:[]}}function Eo(e){let t=Co(e);return{name:e.name,title:e.title,category:e.category,signature:fe(e.input),args:de(e.input),mutatesState:e.mutatesState,requiresClient:e.requiresClient,ai:t}}var Io=u({name:"agent-run",title:"Execute a verified multi-tool AI workflow",description:"ORCHESTRATES LIVE TOOLS. Execute an explicit discover\u2192act\u2192verify workflow with step IDs, result references, dry-run planning, mutation approval, retries, and automatic contract-based verification. Use `agent-context` and `tool-plan` first when the goal is vague, then pass concrete `steps`. Each later input can reference earlier data with `$steps.stepId.data.field` or `$result.stepId.data.field`. By default mutations are blocked and only read-only steps run; set allowMutations=true only when the user authorized state changes. Mutating steps are never retried unless retryMutations=true. If `steps` is omitted, this returns a schema-aware plan instead of guessing required arguments. This is the main closed-loop execution surface for AI agents.",category:"Utility",requiresClient:!1,mutatesState:!0,ai:{phase:"orchestrate",prerequisites:[],consumes:["natural-language goal","explicit tool steps"],produces:["step results","verification results","next actions"],verifiesWith:[],alternatives:["script","tool-plan"],requiresCapabilities:[],sideEffects:["may execute multiple tools; mutations require allowMutations=true"],failureRecovery:["inspect failed step and retry with corrected references or schema"]},input:j.object({goal:j.string().min(3).describe("Human-readable goal used for planning, summaries, and audit output."),steps:j.array(zc).max(50).optional().describe("Explicit ordered steps. Omit to receive a plan only."),dryRun:j.boolean().optional().default(!1).describe("Validate and return the workflow without executing anything."),allowMutations:j.boolean().optional().default(!1).describe("Permit tools marked mutatesState=true to execute."),retryMutations:j.boolean().optional().default(!1).describe("Permit retries for mutating steps; disabled by default to avoid duplicate side effects."),verify:j.boolean().optional().default(!0).describe("Run each step's contract verifier when available."),stopOnError:j.boolean().optional().default(!0).describe("Stop after the first failed or blocked step."),maxSteps:j.number().int().positive().max(50).optional().default(20).describe("Hard execution cap for this run.")}),async execute({goal:e,steps:t,dryRun:n,allowMutations:r,retryMutations:a,verify:o,stopOnError:i,maxSteps:l},c){let d=c.tools.list(),p=new Map(d.map(y=>[y.name,y]));if(!t||t.length===0){let y=lt(e,new Set(d.map(C=>C.name))),w=qe(e,d,10).map(C=>({...Eo(C.tool),score:C.score,why:C.why}));return{data:{status:"plan-only",goal:e,workflows:y,alternatives:w,next:"Provide explicit steps to agent-run after choosing arguments from tool-schema."},summary:`Plan generated; no steps executed for "${e}".`}}let f=t.slice(0,Math.min(l,50)),h=f.map(y=>{let w=p.get(y.tool);return{id:y.id,tool:y.tool,input:y.input,known:w!==void 0,blocked:w?.mutatesState===!0&&!r,...w?Eo(w):{}}});if(n)return{data:{status:"dry-run",goal:e,allowMutations:r,plan:h,next:"Set dryRun=false to execute this validated plan."},summary:`Dry-run validated ${h.length} workflow step(s).`};let g=new Map,b=[],m=!1;for(let y of f){let w=p.get(y.tool);if(!w){if(b.push({id:y.id,tool:y.tool,status:"failed",error:`Unknown tool "${y.tool}".`}),m=!0,i)break;continue}if(w.mutatesState&&!r){if(b.push({id:y.id,tool:y.tool,status:"blocked",reason:"Mutation not approved; set allowMutations=true."}),m=!0,i)break;continue}let C;try{C=Hn(y.input,g)}catch(x){if(b.push({id:y.id,tool:y.tool,status:"failed",error:x instanceof Error?x.message:String(x)}),m=!0,i)break;continue}let I=Math.min(y.retries+1,w.mutatesState&&!a?1:y.retries+1),N,O;for(let x=1;x<=I;x+=1)try{if(N=await c.invokeTool(w.name,C),!N.isError||x===I)break}catch(E){if(O=E,x===I)break}if(!N&&O){if(b.push({id:y.id,tool:y.tool,status:"failed",error:O instanceof Error?O.message:JSON.stringify(O)}),m=!0,i)break;continue}let q=N?.data;g.set(y.id,{data:q,result:q,summary:N?.summary});let S={id:y.id,tool:y.tool,status:N?.isError?"failed":"ok",data:q,...N?.summary?{summary:N.summary}:{}};if(N?.isError)m=!0,S.error="Tool returned a handled error.";else if(o){let x=Co(w),E=y.verifyWith??x.verifiesWith[0];if(E){let G=p.get(E);if(!G)S.verification={status:"unavailable",error:`Verifier "${E}" is not registered.`};else if(G.mutatesState)S.verification={status:"unavailable",error:"Verifier must be read-only."};else try{let X=Hn(y.verifyInput??C,g),ee=await c.invokeTool(E,X);S.verification={status:ee.isError?"failed":"ok",data:ee.data},ee.isError&&(m=!0)}catch(X){S.verification={status:"failed",error:X instanceof Error?X.message:JSON.stringify(X)},m=!0}}}if(b.push(S),m&&i)break}return{data:{status:m?"failed":"completed",goal:e,results:b,references:Object.fromEntries(g),next:m?"Inspect the failed step, correct its input or capability assumption, then retry.":"Goal workflow completed; use the verification fields as proof."},summary:`${b.length}/${f.length} workflow step(s) executed${m?" with failures":" successfully"}.`,isError:m}}});import{z as Br}from"zod";var To=u({name:"clear-queue-on-teleport",title:"Clear teleport-queued code (sUNC clearqueueonteleport)",description:"WRITES EXECUTOR STATE \u2014 clears any code previously queued with queueonteleport, via clearqueueonteleport(). After this, nothing will auto-run on the next teleport. Requires clearqueueonteleport. The call is type-guarded and pcall-wrapped: if clearqueueonteleport is missing you get { error = 'clearqueueonteleport is not available in this executor.' }. Returns { cleared } or { error }.",category:"Utility",mutatesState:!0,input:Br.object({threadContext:Br.number().int().optional(),timeoutMs:Br.number().int().optional()}),async execute({threadContext:e,timeoutMs:t},n){return{data:await n.runLuau(`
if type(clearqueueonteleport) ~= "function" then
  return { error = "clearqueueonteleport is not available in this executor." }
end
local ok, err = pcall(clearqueueonteleport)
if not ok then return { error = tostring(err) } end
return { cleared = true }
`,{threadContext:e,timeoutMs:t})}}});import{z as Xn}from"zod";var Ro=u({name:"get-fast-flag",title:"Read a Roblox FastFlag value (sUNC getfflag)",description:"Read the current value of a Roblox engine FastFlag by name via the executor's getfflag(name). FastFlags (FFlag/DFFlag/FInt/etc.) are the runtime feature toggles the Roblox client reads at startup; getfflag returns the current value as a string, or nil when the flag is unknown. Requires getfflag. The call is type-guarded and pcall-wrapped: if getfflag is missing you get { error = 'getfflag is not available in this executor.' }. Returns { name, value } or { error }.",category:"Utility",input:Xn.object({name:Xn.string().describe("The FastFlag name, e.g. 'DFIntTaskSchedulerTargetFps' or 'FFlagDebugDisplayFPS'."),threadContext:Xn.number().int().optional(),timeoutMs:Xn.number().int().optional()}),async execute({name:e,threadContext:t,timeoutMs:n},r){let a=`
if type(getfflag) ~= "function" then
  return { error = "getfflag is not available in this executor." }
end
local ok, value = pcall(getfflag, ${s(e)})
if not ok then return { error = tostring(value) } end
return { name = ${s(e)}, value = value }
`;return{data:await r.runLuau(a,{threadContext:t,timeoutMs:n})}}});import{z as zr}from"zod";var Mo=u({name:"get-hwid",title:"Read the host hardware ID (sUNC gethwid)",description:"Read the host machine's hardware identifier (HWID) via the executor's gethwid(). This is the stable per-machine fingerprint executors commonly use for key-system/license binding. Requires gethwid. The call is type-guarded and pcall-wrapped: if gethwid is missing you get { error = 'gethwid is not available in this executor.' }. Returns { hwid } or { error }.",category:"Utility",input:zr.object({threadContext:zr.number().int().optional(),timeoutMs:zr.number().int().optional()}),async execute({threadContext:e,timeoutMs:t},n){return{data:await n.runLuau(`
if type(gethwid) ~= "function" then
  return { error = "gethwid is not available in this executor." }
end
local ok, hwid = pcall(gethwid)
if not ok then return { error = tostring(hwid) } end
return { hwid = hwid }
`,{threadContext:e,timeoutMs:t})}}});import{z as ct}from"zod";var Lo=u({name:"message-box",title:"Show a native host message box (sUNC messagebox)",description:"WRITES HOST STATE \u2014 pops up a NATIVE OS dialog on the host machine via messagebox(text, caption, flags). The flags select the dialog's button/icon style (the same bitfield as the Win32 MessageBox), and the call blocks until the user dismisses it, returning the numeric code of the button pressed. Requires messagebox. The call is type-guarded and pcall-wrapped: if messagebox is missing you get { error = 'messagebox is not available in this executor.' }. Returns { result } or { error }.",category:"Utility",mutatesState:!0,input:ct.object({text:ct.string().describe("The body text shown in the dialog."),caption:ct.string().optional().default("MCP").describe("The dialog title/caption (default 'MCP')."),flags:ct.number().int().optional().default(0).describe("The dialog style bitfield (default 0 = OK button only)."),threadContext:ct.number().int().optional(),timeoutMs:ct.number().int().optional()}),async execute({text:e,caption:t,flags:n,threadContext:r,timeoutMs:a},o){let i=`
if type(messagebox) ~= "function" then
  return { error = "messagebox is not available in this executor." }
end
local ok, result = pcall(messagebox, ${s(e)}, ${s(t)}, ${Math.floor(n)})
if not ok then return { error = tostring(result) } end
return { result = result }
`;return{data:await o.runLuau(i,{threadContext:r,timeoutMs:a})}}});import{z as Yn}from"zod";var Ao=u({name:"queue-on-teleport",title:"Queue code to run after the next teleport (sUNC queueonteleport)",description:"WRITES EXECUTOR STATE \u2014 queues a chunk of Luau source via queueonteleport(code) so it runs automatically after the NEXT teleport completes, in the destination place. This is how scripts survive a Roblox teleport: the queued code persists across the place change and executes once the new place loads. Requires queueonteleport. The call is type-guarded and pcall-wrapped: if queueonteleport is missing you get { error = 'queueonteleport is not available in this executor.' }. Returns { queued } or { error }.",category:"Utility",mutatesState:!0,input:Yn.object({code:Yn.string().describe("The Luau source to run automatically after the next teleport."),threadContext:Yn.number().int().optional(),timeoutMs:Yn.number().int().optional()}),async execute({code:e,threadContext:t,timeoutMs:n},r){let a=`
if type(queueonteleport) ~= "function" then
  return { error = "queueonteleport is not available in this executor." }
end
local ok, err = pcall(queueonteleport, ${s(e)})
if not ok then return { error = tostring(err) } end
return { queued = true }
`;return{data:await r.runLuau(a,{threadContext:t,timeoutMs:n})}}});import{z as Ht}from"zod";var No=u({name:"save-instance",title:"Dump the game or a subtree to the workspace (sUNC saveinstance)",description:"WRITES HOST FILES \u2014 serializes the entire game (or a chosen instance subtree) to a file in the executor's workspace folder via saveinstance. By default it dumps the whole DataModel; pass instancePath to dump just that subtree. This is a heavy operation that can take a while and produce a large file. Because executors differ on the exact signature, this tries several forms in order: saveinstance({ FilePath = fileName }), then saveinstance(instance, fileName) / saveinstance(instance), then saveinstance(). Requires saveinstance. The call is type-guarded and pcall-wrapped: if saveinstance is missing you get { error = 'saveinstance is not available in this executor.' }. Returns { saved, note } or { error }.",category:"Utility",mutatesState:!0,input:Ht.object({fileName:Ht.string().optional().describe("Optional output file name within the executor workspace (e.g. 'place.rbxm'). Omit to let the executor pick a default."),instancePath:Ht.string().optional().describe("Optional Luau expression for the instance to dump (e.g. 'game.Workspace'). Defaults to the whole game."),threadContext:Ht.number().int().optional(),timeoutMs:Ht.number().int().optional()}),async execute({fileName:e,instancePath:t,threadContext:n,timeoutMs:r},a){let l=`
if type(saveinstance) ~= "function" then
  return { error = "saveinstance is not available in this executor." }
end
local fileName = ${e===void 0?"nil":s(e)}
local instance = ${t??"game"}

-- Try the several signatures executors use, in best-effort order.
local function attempt()
  if fileName ~= nil then
    local ok = pcall(saveinstance, { FilePath = fileName, path = fileName })
    if ok then return "saveinstance({ FilePath = fileName })" end
    ok = pcall(saveinstance, instance, fileName)
    if ok then return "saveinstance(instance, fileName)" end
  end
  local ok = pcall(saveinstance, instance)
  if ok then return "saveinstance(instance)" end
  ok = pcall(saveinstance)
  if ok then return "saveinstance()" end
  return nil
end

local ok, note = pcall(attempt)
if not ok then return { error = tostring(note) } end
if note == nil then return { error = "saveinstance failed for every attempted signature." } end
return { saved = true, note = note }
`;return{data:await a.runLuau(l,{threadContext:n,timeoutMs:r??12e4})}}});import{z as Xt}from"zod";var Po=u({name:"set-fast-flag",title:"Override a Roblox FastFlag value (sUNC setfflag)",description:"WRITES CLIENT STATE \u2014 overrides a Roblox engine FastFlag for the running client via setfflag(name, value). The value is supplied as a string and coerced by the executor to the flag's native type (bool/int/string). This changes engine behavior at runtime and can destabilize the client if a flag is set to an invalid value. Requires setfflag. The call is type-guarded and pcall-wrapped: if setfflag is missing you get { error = 'setfflag is not available in this executor.' }. Returns { name, value, ok } or { error }.",category:"Utility",mutatesState:!0,input:Xt.object({name:Xt.string().describe("The FastFlag name to override, e.g. 'DFIntTaskSchedulerTargetFps'."),value:Xt.string().describe("The new value as a string (e.g. '120', 'true', or a text value)."),threadContext:Xt.number().int().optional(),timeoutMs:Xt.number().int().optional()}),async execute({name:e,value:t,threadContext:n,timeoutMs:r},a){let o=`
if type(setfflag) ~= "function" then
  return { error = "setfflag is not available in this executor." }
end
local ok, err = pcall(setfflag, ${s(e)}, ${s(t)})
if not ok then return { error = tostring(err) } end
return { name = ${s(e)}, value = ${s(t)}, ok = true }
`;return{data:await a.runLuau(o,{threadContext:n,timeoutMs:r})}}});import{z as Yt}from"zod";var $o=u({name:"tool-plan",title:"Turn a natural-language goal into a tool workflow",description:"READ-ONLY. Convert a vague Roblox goal into a ranked, schema-aware workflow. Give this tool the user's natural-language objective, not a guessed tool name. It combines intent aliases, the live tool catalog, available schemas, mutation flags, and curated discover\u2192act\u2192verify recipes. Use the returned workflow as a starting point, then inspect the exact schema of the selected tool before calling it. This is especially useful for goals involving UI/input, remotes, player values, instance inspection, or reverse engineering.",category:"Utility",requiresClient:!1,input:Yt.object({goal:Yt.string().min(3).describe("Natural-language objective, e.g. 'find the player's cash and verify its current value'."),limit:Yt.number().int().positive().max(20).optional().default(8).describe("Maximum ranked alternatives to return."),includeMutating:Yt.boolean().optional().default(!0).describe("Include tools that write game state in the ranked alternatives and workflow."),capabilityAware:Yt.boolean().optional().default(!0).describe("Use the active client's advertised executor capabilities to annotate and rank candidates.")}),async execute({goal:e,limit:t,includeMutating:n,capabilityAware:r},a){let o=a.tools.list(),i=n?o:o.filter(m=>!m.mutatesState),l=a.session?.resolve?.()??{status:"none",reason:"no-clients"},c=r&&l.status==="resolved"?new Set(l.client.capabilities):null,d=qe(e,i,t).map(m=>{let y=m.tool.ai?.requiresCapabilities??[],w=y.length===0||!c?0:y.every(C=>c.has(C))?20:-20;return{...m,score:m.score+w}}).sort((m,y)=>y.score-m.score||m.tool.name.localeCompare(y.tool.name)),p=new Set(i.map(m=>m.name)),f=lt(e,p),h=f[0]??null,g=m=>({name:m.name,title:m.title,category:m.category,signature:fe(m.input),args:de(m.input),mutatesState:m.mutatesState,requiresClient:m.requiresClient,ai:m.ai,capabilityStatus:!m.ai?.requiresCapabilities?.length||!r?"not-required":c?m.ai.requiresCapabilities.every(y=>c.has(y))?"supported":"missing":"unknown"}),b=m=>({id:m.id,title:m.title,description:m.description,steps:m.steps.flatMap((y,w)=>{let C=o.find(I=>I.name===y.tool);return C?[{step:w+1,...y,...g(C)}]:[]})});return{data:{goal:e,interpretation:h?.title??"No curated recipe matched; use the ranked candidates as an exploratory shortlist.",clientCapabilities:c?[...c]:l.status==="resolved"?[]:null,workflow:h?b(h):null,workflows:f.map(b),alternatives:d.map(m=>({...g(m.tool),score:Math.round(m.score*10)/10,matchedTerms:m.matchedTerms,why:m.why})),guidance:["Prefer discover/read-only steps before mutation.","Call tool-schema with the selected name if any required argument is unclear.","Use script when several steps depend on earlier results; use mcp.parallel for independent reads.",...n?[]:["Mutating tools were excluded; set includeMutating=true when you are ready to act."]]},summary:`${d.length} candidate tools${h?`; recommended recipe: ${h.title}`:""}.`}}});import{z as ut}from"zod";var Fo=u({name:"tool-quality-audit",title:"Audit definition quality across the complete tool catalog",description:"Read-only catalog self-audit for tool titles, descriptions, input documentation, schema examples/defaults/constraints, AI data-flow contracts, prerequisites, capability requirements, mutation side effects, verification paths, and recovery guidance. It evaluates the same centrally compiled metadata exposed to MCP clients, so every current and future tool can be checked against one measurable standard. Filter by exact name/category or return only entries below a score threshold; no Roblox client is required.",category:"Utility",requiresClient:!1,input:ut.object({name:ut.string().optional().describe("Optional exact kebab-case tool name to audit."),category:ut.string().optional().describe("Optional exact category name to audit."),minimumScore:ut.number().int().min(0).max(100).optional().default(85).describe("Score below which a definition is reported as needing attention."),includePassing:ut.boolean().optional().default(!1).describe("Include definitions meeting or exceeding minimumScore."),limit:ut.number().int().min(1).max(500).optional().default(100).describe("Maximum detailed tool reports returned; aggregate counts always cover the full filter.")}),async execute({name:e,category:t,minimumScore:n,includePassing:r,limit:a},o){let l=o.tools.list().filter(b=>e?b.name===e:!0).filter(b=>t?b.category===t:!0).map(b=>{let m=b.quality??Nt(b),y=Ya(b);return{name:b.name,title:b.title,category:b.category,score:m.score,grade:m.grade,issues:m.issues,strengths:m.strengths,explicitFieldDescriptions:m.explicitFieldDescriptions,inferredFieldDescriptions:m.inferredFieldDescriptions,signature:y.signature,requiredInputs:y.requiredInputs,phase:y.execution.phase,estimatedCost:y.execution.estimatedCost,mutatesState:y.safety.mutatesState,sideEffects:y.safety.sideEffects,verifiesWith:y.success.verifiesWith,recoverySteps:y.recovery.length}}),c={A:0,B:0,C:0,D:0,F:0},d=new Map,p=0,f=0,h=0;for(let b of l){c[b.grade]=(c[b.grade]??0)+1,p+=b.score,f+=b.explicitFieldDescriptions,h+=b.inferredFieldDescriptions;let m=d.get(b.category)??{count:0,scoreTotal:0,belowThreshold:0};m.count+=1,m.scoreTotal+=b.score,b.score<n&&(m.belowThreshold+=1),d.set(b.category,m)}let g=l.filter(b=>r||b.score<n).sort((b,m)=>b.score-m.score||b.name.localeCompare(m.name)).slice(0,a);return{data:{filter:{name:e??null,category:t??null},threshold:n,aggregate:{tools:l.length,averageScore:l.length>0?Math.round(p/l.length*10)/10:0,passing:l.filter(b=>b.score>=n).length,belowThreshold:l.filter(b=>b.score<n).length,byGrade:c,explicitFieldDescriptions:f,inferredFieldDescriptions:h,effectiveUndocumentedFields:0},categories:[...d.entries()].map(([b,m])=>({category:b,count:m.count,averageScore:Math.round(m.scoreTotal/m.count*10)/10,belowThreshold:m.belowThreshold})).sort((b,m)=>b.category.localeCompare(m.category)),count:g.length,truncated:g.length<l.filter(b=>r||b.score<n).length,tools:g,note:"Inferred descriptions are exposed to clients immediately and remain visible as authoring debt until replaced with explicit field docs."},summary:`Audited ${l.length} tool definition(s); ${l.filter(b=>b.score<n).length} below ${n}.`}}});import{z as Zn}from"zod";var L=`
local __getconnectionsFn = getconnections
local __hasDebug = type(debug) == "table"
local __debugInfoFn = __hasDebug and (debug.info or debug.getinfo) or nil

local function __encVal(v)
  local t = typeof(v)
  if t == "Instance" then local ok,n = pcall(function() return v:GetFullName() end); return ok and n or "<Instance>" end
  if t == "string" or t == "number" or t == "boolean" then return v end
  if t == "nil" then return "nil" end
  local ok, s = pcall(tostring, v); return ok and (t .. ": " .. tostring(s)) or ("<" .. t .. ">")
end

local function __describeFunction(f)
  if type(f) ~= "function" then return nil end
  local result = { Name = "<anonymous>", Source = "", ShortSource = "", LineDefined = -1, NumParams = -1, IsVararg = false, What = "?", Pointer = tostring(f) }
  if type(__debugInfoFn) ~= "function" then return result end
  local okTbl, infoTbl = pcall(__debugInfoFn, f, "nSlu")
  if okTbl and type(infoTbl) == "table" then
    result.Name = infoTbl.name or result.Name
    result.Source = infoTbl.source or result.Source
    result.ShortSource = infoTbl.short_src or result.ShortSource
    result.LineDefined = infoTbl.linedefined or result.LineDefined
    result.NumParams = infoTbl.nparams or result.NumParams
    result.IsVararg = infoTbl.isvararg == true
    result.What = infoTbl.what or result.What
    return result
  end
  local okN, n = pcall(__debugInfoFn, f, "n"); if okN and type(n) ~= "table" and n ~= nil then result.Name = tostring(n) end
  local okS, s = pcall(__debugInfoFn, f, "s"); if okS and type(s) ~= "table" and s ~= nil then result.Source = tostring(s) end
  local okL, l = pcall(__debugInfoFn, f, "l"); if okL and type(l) == "number" then result.LineDefined = l end
  local okA, a = pcall(__debugInfoFn, f, "a"); if okA and type(a) == "number" then result.NumParams = a end
  return result
end

local function __resolveInstance(expr)
  local ok, inst = pcall(function() return (loadstring("return " .. expr))() end)
  if not ok then return nil, "Failed to evaluate path: " .. tostring(inst) end
  if typeof(inst) ~= "Instance" then return nil, "Path did not resolve to an Instance (got " .. typeof(inst) .. "): " .. expr end
  return inst, nil
end

-- Resolve a signal. If signalName is nil/"" the expr itself must be the RBXScriptSignal.
local function __resolveSignal(expr, signalName)
  if signalName == nil or signalName == "" then
    local ok, sig = pcall(function() return (loadstring("return " .. expr))() end)
    if not ok then return nil, nil, "Failed to evaluate signal expression: " .. tostring(sig) end
    if typeof(sig) ~= "RBXScriptSignal" then return nil, nil, "Expression is not an RBXScriptSignal (got " .. typeof(sig) .. "): " .. expr end
    return sig, nil, nil
  end
  local inst, err = __resolveInstance(expr)
  if not inst then return nil, nil, err end
  local okSig, sig = pcall(function() return inst[signalName] end)
  if not okSig then return nil, inst, "Failed to access member '" .. signalName .. "' on " .. inst:GetFullName() .. ": " .. tostring(sig) end
  if typeof(sig) ~= "RBXScriptSignal" then return nil, inst, "Member '" .. signalName .. "' is not an RBXScriptSignal (got " .. typeof(sig) .. ")." end
  return sig, inst, nil
end

local function __getConns(sig)
  if type(__getconnectionsFn) ~= "function" then return nil, "getconnections is not available in this executor." end
  local ok, conns = pcall(__getconnectionsFn, sig)
  if not ok or type(conns) ~= "table" then return nil, "getconnections failed: " .. tostring(conns) end
  return conns, nil
end

local function __connInfo(conn, index, withFn)
  local info = { Index = index }
  local function g(k) local ok, v = pcall(function() return conn[k] end); if ok then return v end return nil end
  info.Enabled = g("Enabled")
  info.LuaConnection = g("LuaConnection")
  info.ForeignState = g("ForeignState")
  local fn = g("Function")
  info.HasFunction = type(fn) == "function"
  local th = g("Thread")
  info.HasThread = th ~= nil
  if th ~= nil then
    local okS, st = pcall(function() return coroutine.status(th) end)
    if okS then info.ThreadStatus = st end
  end
  if withFn and type(fn) == "function" then
    info.Function = __describeFunction(fn)
  end
  return info, fn
end
`;function dt(e){if(!e||e.length===0)return{preamble:"",argExpr:""};let t=[],n=[];return e.forEach((r,a)=>{let o=`__arg${a}`;switch(n.push(o),r.kind){case"string":t.push(`local ${o} = ${s(String(r.value??""))}`);break;case"number":t.push(`local ${o} = ${Number(r.value??0)}`);break;case"boolean":t.push(`local ${o} = ${r.value?"true":"false"}`);break;case"nil":t.push(`local ${o} = nil`);break;case"instance":t.push(`local ${o} = (loadstring("return " .. ${s(String(r.value??""))}))()`);break;case"raw":t.push(`local ${o} = (loadstring("return " .. ${s(String(r.value??"nil"))}))()`);break;default:t.push(`local ${o} = nil`)}}),{preamble:t.join(`
`),argExpr:n.join(", ")}}var Oo=u({name:"can-signal-replicate",title:"Check whether a signal can be replicated to the server",description:"Query whether an RBXScriptSignal is one the Roblox engine permits to be replicated to the server, using the executor's cansignalreplicate. When CanReplicate is true, the replicate-signal tool can fire this signal so the server receives it as if the game client raised it natively \u2014 the basis for driving server-side logic that is normally gated behind engine-internal signals. When false, replicate-signal will be rejected and you must use a different vector. Use this to pre-flight a signal before attempting replication. Pass the instance that owns the signal plus the signal member name (or leave signalName empty if instancePath already resolves to the signal). Requires the cansignalreplicate executor function; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, CanReplicate, Note }.",category:"Signals & Connections",input:Zn.object({instancePath:Zn.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.ReplicatedStorage.MyRemote', 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:Zn.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'OnClientEvent', 'Touched', 'Changed'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),threadContext:Zn.number().int().optional()}),async execute({instancePath:e,signalName:t,threadContext:n},r){let a=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

if type(cansignalreplicate) ~= "function" then
  return { error = "cansignalreplicate is not available in this executor." }
end

local ok, res = pcall(cansignalreplicate, sig)
if not ok then return { error = "cansignalreplicate failed: " .. tostring(res) } end

local canRep = res and true or false

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  CanReplicate = canRep,
  Note = canRep
    and "The engine allows this signal to be replicated; replicate-signal can fire it to the server."
    or "The engine does NOT allow this signal to be replicated; replicate-signal will reject it.",
}
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}});import{z as Qn}from"zod";var qo=u({name:"count-signal-connections",title:"Count connections on a signal (breakdown)",description:`Resolve an RBXScriptSignal and return a fast numeric breakdown of everything connected to it: Total connections, how many are Lua vs Foreign (engine/C-side), how many are currently Enabled vs Disabled, and how many carry a Lua Function. Use this as a lightweight first pass before list-signal-connections when you only need counts (e.g. "how many handlers are on this RemoteEvent?", "are any of this signal's connections disabled?"). Does NOT describe each function, so it is much cheaper than the full listing. Requires the executor's getconnections; degrades to a clear { error } if unavailable. Returns { Signal, Instance?, Total, Lua, Foreign, Enabled, Disabled, WithFunction }.`,category:"Signals & Connections",input:Qn.object({instancePath:Qn.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door', 'game.ReplicatedStorage.RemoteEvent'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:Qn.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed', 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),threadContext:Qn.number().int().optional()}),async execute({instancePath:e,signalName:t,threadContext:n},r){let a=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local total, lua, foreign, enabled, disabled, withFn = 0, 0, 0, 0, 0, 0
for i = 1, #conns do
  local info = __connInfo(conns[i], i - 1, false)
  total = total + 1
  if info.LuaConnection then lua = lua + 1 else foreign = foreign + 1 end
  if info.Enabled then enabled = enabled + 1 else disabled = disabled + 1 end
  if info.HasFunction then withFn = withFn + 1 end
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  Total = total,
  Lua = lua,
  Foreign = foreign,
  Enabled = enabled,
  Disabled = disabled,
  WithFunction = withFn,
}
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}});import{z as Zt}from"zod";var Go=u({name:"find-instances-with-connections",title:"Find instances that have connections on a named signal",description:'Walk every descendant of a root instance and report which ones have an active handler on a specific signal. For each descendant it reads inst[signalName]; if that member is an RBXScriptSignal with at least one connection (per getconnections), it records { Path, ClassName, ConnectionCount }. Results are sorted by ConnectionCount descending. This answers questions like "which Parts in Workspace have a Touched handler?", "which GuiButtons are wired to Activated?", or "who is listening to Changed under this model?". Requires the executor\'s getconnections; degrades to a clear { error } if unavailable. Scanning is capped at `limit` instances to stay responsive on huge games. Returns { Signal, Root, ScannedInstances, Truncated, MatchCount, Instances: [...] }.',category:"Signals & Connections",input:Zt.object({root:Zt.string().describe("Lua expression for the root instance whose descendants are scanned (e.g. 'game', 'game.Workspace', 'game.Workspace.Map'). Evaluated as `return <root>`. Defaults to 'game' (scans the whole DataModel up to the limit). Narrow this for faster, more focused scans.").optional().default("game"),signalName:Zt.string().describe("REQUIRED name of the signal member to probe on each descendant (e.g. 'Touched', 'Changed', 'ChildAdded', 'Activated', 'OnClientEvent'). Only instances exposing this member as an RBXScriptSignal with >0 connections are reported."),limit:Zt.number().int().positive().describe("Maximum number of descendant instances to SCAN (not match) before stopping. Defaults to 1000. Increase to cover larger hierarchies (slower); decrease for a quick sample. If the scan stops early because this cap was hit, Truncated is true.").optional().default(1e3),threadContext:Zt.number().int().optional()}),async execute({root:e,signalName:t,limit:n,threadContext:r},a){let o=`
${L}
local rootInst, rerr = __resolveInstance(${s(e)})
if not rootInst then return { error = rerr } end
if type(__getconnectionsFn) ~= "function" then return { error = "getconnections is not available in this executor." } end

local signalName = ${s(t)}
local limit = ${Math.trunc(n)}
local scanned = 0
local truncated = false
local matches = {}

local okDesc, descendants = pcall(function() return rootInst:GetDescendants() end)
if not okDesc or type(descendants) ~= "table" then
  return { error = "Failed to enumerate descendants of " .. rootInst:GetFullName() .. "." }
end

for i = 1, #descendants do
  if scanned >= limit then truncated = true break end
  local inst = descendants[i]
  scanned = scanned + 1
  local okSig, sig = pcall(function() return inst[signalName] end)
  if okSig and typeof(sig) == "RBXScriptSignal" then
    local okC, conns = pcall(__getconnectionsFn, sig)
    if okC and type(conns) == "table" and #conns > 0 then
      local path, cls = "?", "?"
      local okP, p = pcall(function() return inst:GetFullName() end); if okP then path = p end
      local okCl, c = pcall(function() return inst.ClassName end); if okCl then cls = c end
      matches[#matches + 1] = { Path = path, ClassName = cls, ConnectionCount = #conns }
    end
  end
end

table.sort(matches, function(a, b) return a.ConnectionCount > b.ConnectionCount end)

return {
  Signal = signalName,
  Root = rootInst:GetFullName(),
  ScannedInstances = scanned,
  Truncated = truncated,
  MatchCount = #matches,
  Instances = matches,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:3e4})}}});import{z as le}from"zod";var Hc=le.array(le.object({kind:le.enum(["string","number","boolean","nil","instance","raw"]).describe("How to interpret `value`: 'string'/'number'/'boolean' = a literal of that type; 'nil' = a Lua nil (value ignored); 'instance' = `value` is a Lua path like 'game.Players.LocalPlayer' resolved to an Instance at runtime; 'raw' = `value` is a raw Luau expression like 'Vector3.new(1,2,3)' evaluated at runtime."),value:le.union([le.string(),le.number(),le.boolean()]).describe("The argument payload. Omit for kind='nil'. For kind='instance' pass a Lua path string; for kind='raw' pass a Luau expression string.").optional()})).describe("Ordered list of arguments to pass to the targeted connection's handler. Omit or pass [] to fire with no arguments.").optional(),Do=u({name:"fire-connection",title:"Fire one specific connection on a signal",description:"MUTATES CLIENT STATE. Invokes a single connection's :Fire(...) (or :Defer(...) when defer=true) so that ONLY the one targeted handler runs with the supplied arguments \u2014 unlike fire-signal, which triggers every connection. Identify the connection by its index within getconnections(signal) (use list-signal-connections to find indices). This is client-side only and does not reach the server. Useful for isolating and testing a single suspected handler. The connection's Fire/Defer methods may be absent on foreign/C connections, so the call is pcall-guarded. Requires getconnections; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, ConnectionIndex, Fired, Deferred } or { error }.",category:"Signals & Connections",mutatesState:!0,input:le.object({instancePath:le.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the signal itself."),signalName:le.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),connectionIndex:le.number().int().min(0).describe("Zero-based index of the target connection within getconnections(signal), matching the Index reported by list-signal-connections. Defaults to 0 (the first connection).").optional().default(0),defer:le.boolean().describe("When true, call connection:Defer(...) to schedule the handler on the next resumption cycle instead of running it synchronously. When false (default), call connection:Fire(...) to run it immediately.").optional().default(!1),args:Hc,threadContext:le.number().int().optional()}),async execute({instancePath:e,signalName:t,connectionIndex:n,defer:r,args:a,threadContext:o},i){let{preamble:l,argExpr:c}=dt(a),d=r?"Defer":"Fire",p=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local idx = ${n}
if idx < 0 or idx >= #conns then
  return { error = "connectionIndex " .. idx .. " out of range (signal has " .. #conns .. " connection(s); valid 0.." .. (#conns - 1) .. ")." }
end
local conn = conns[idx + 1]
if conn == nil then return { error = "No connection at index " .. idx .. "." } end

${l}
local okFire, fireErr = pcall(function() conn:${d}(${c}) end)
if not okFire then return { error = "connection:${d} failed: " .. tostring(fireErr) } end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  ConnectionIndex = idx,
  Fired = true,
  Deferred = ${r?"true":"false"},
}
`;return{data:await i.runLuau(p,{threadContext:o,timeoutMs:2e4})}}});import{z as he}from"zod";var Xc=he.array(he.object({kind:he.enum(["string","number","boolean","nil","instance","raw"]).describe("How to interpret `value`: 'string'/'number'/'boolean' = a literal of that type; 'nil' = a Lua nil (value ignored); 'instance' = `value` is a Lua path like 'game.Players.LocalPlayer' resolved to an Instance at runtime; 'raw' = `value` is a raw Luau expression like 'Vector3.new(1,2,3)' evaluated at runtime."),value:he.union([he.string(),he.number(),he.boolean()]).describe("The argument payload. Omit for kind='nil'. For kind='instance' pass a Lua path string; for kind='raw' pass a Luau expression string.").optional()})).describe("Ordered list of arguments to pass to the connection handlers, mirroring the real arguments the event would normally fire with. Omit or pass [] to fire with no arguments.").optional(),Uo=u({name:"fire-signal",title:"Fire all local connections of a signal",description:"MUTATES CLIENT STATE. Invokes firesignal(signal, ...) to synchronously fire EVERY local Lua connection currently attached to an RBXScriptSignal, passing the supplied arguments. This is client-side only: it runs the handlers in your own client and does NOT send anything to the server or other players. Useful for exercising a game's own event handlers (e.g. simulating a 'Touched' or a custom BindableEvent) while debugging UI/gameplay logic, without performing the real physical action. NOTE: firesignal invokes the connection functions directly and does NOT respect a connection's Disabled state \u2014 disabled connections still run. (A real event, or set-connection-state, does respect Enabled/Disabled.) Requires the executor's firesignal; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, Fired, ArgCount } or { error }.",category:"Signals & Connections",mutatesState:!0,input:he.object({instancePath:he.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the signal itself."),signalName:he.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed', 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),args:Xc,threadContext:he.number().int().optional()}),async execute({instancePath:e,signalName:t,args:n,threadContext:r},a){let{preamble:o,argExpr:i}=dt(n),l=n?.length??0,c=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

if type(firesignal) ~= "function" then return { error = "firesignal is not available in this executor." } end

${o}
local okFire, fireErr = pcall(function() firesignal(sig${i?", "+i:""}) end)
if not okFire then return { error = "firesignal failed: " .. tostring(fireErr) } end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  Fired = true,
  ArgCount = ${l},
}
`;return{data:await a.runLuau(c,{threadContext:r,timeoutMs:2e4})}}});import{z as Qt}from"zod";var jo=u({name:"get-connection-constants",title:"Dump the constants of a connection's handler function",description:"Disassemble the Lua function bound to ONE connection on an RBXScriptSignal (selected by zero-based index) and return its constant pool via debug.getconstants. Constants include the literal strings, numbers and referenced globals/methods baked into the closure \u2014 invaluable for reverse-engineering what a hidden event handler does (e.g. which RemoteEvent names or HTTP endpoints it touches). Each constant is passed through a value encoder so tables/functions/instances render as readable descriptors instead of raw pointers. Requires getconnections and debug.getconstants; returns a clear { error } if either is missing or the connection has no Lua Function. Returns { Signal, Instance?, ConnectionIndex, Function, Constants: [...], Count }.",category:"Signals & Connections",input:Qt.object({instancePath:Qt.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:Qt.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed', 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),connectionIndex:Qt.number().int().min(0).describe("Zero-based index of the connection whose handler function to disassemble, as reported by list-signal-connections. 0 is the first connection. Must be < ConnectionCount or a clear { error } is returned.").optional().default(0),threadContext:Qt.number().int().optional()}),async execute({instancePath:e,signalName:t,connectionIndex:n,threadContext:r},a){let o=`
${L}
local __getconstantsFn = (type(debug) == "table") and debug.getconstants or nil
if type(__getconstantsFn) ~= "function" then return { error = "debug.getconstants is not available in this executor." } end

local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local idx = ${n}
if idx < 0 or idx >= #conns then
  return { error = "connectionIndex " .. tostring(idx) .. " is out of range (signal has " .. tostring(#conns) .. " connection(s); valid 0.." .. tostring(#conns - 1) .. ")." }
end

local conn = conns[idx + 1]
local okFn, fn = pcall(function() return conn.Function end)
if not okFn or type(fn) ~= "function" then
  return { error = "Connection " .. tostring(idx) .. " has no Lua Function (it may be a C/foreign or thread connection)." }
end

local okC, consts = pcall(__getconstantsFn, fn)
if not okC then return { error = "debug.getconstants failed: " .. tostring(consts) } end
if type(consts) ~= "table" then return { error = "debug.getconstants returned a non-table value." } end

local out = {}
for i = 1, #consts do
  out[i] = { Index = i - 1, Type = typeof(consts[i]), Value = __encVal(consts[i]) }
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  ConnectionIndex = idx,
  Function = __describeFunction(fn),
  Constants = out,
  Count = #out,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as Jt}from"zod";var Wo=u({name:"get-connection-info",title:"Inspect a single signal connection in detail",description:"Return the full Connection metadata for ONE connection on an RBXScriptSignal, selected by zero-based index. Reports Index, Enabled, LuaConnection, ForeignState, whether it has a Function/Thread, the connected thread's status (when present), and \u2014 for Lua connections \u2014 the handler function's Source script, Name, LineDefined, NumParams, IsVararg and What. Use this to zoom in on a specific listener after list-signal-connections shows you the index of interest. Requires getconnections; degrades with a clear { error } if unavailable or if the index is out of range. Returns { Signal, Instance?, ConnectionCount, Connection: {...} }.",category:"Signals & Connections",input:Jt.object({instancePath:Jt.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:Jt.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed', 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),connectionIndex:Jt.number().int().min(0).describe("Zero-based index of the connection to inspect, as reported by list-signal-connections. 0 is the first connection. Must be < ConnectionCount or a clear { error } is returned.").optional().default(0),threadContext:Jt.number().int().optional()}),async execute({instancePath:e,signalName:t,connectionIndex:n,threadContext:r},a){let o=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local idx = ${n}
if idx < 0 or idx >= #conns then
  return { error = "connectionIndex " .. tostring(idx) .. " is out of range (signal has " .. tostring(#conns) .. " connection(s); valid 0.." .. tostring(#conns - 1) .. ")." }
end

local conn = conns[idx + 1]
local info = __connInfo(conn, idx, true)

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  ConnectionCount = #conns,
  Connection = info,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as en}from"zod";var Vo=u({name:"get-connection-protos",title:"List the nested child functions of a connection's handler",description:"Enumerate the inner (proto) functions defined inside the Lua function bound to ONE connection on an RBXScriptSignal (selected by zero-based index) via debug.getprotos. Protos are the nested closures a handler creates \u2014 callbacks, deferred tasks, helper lambdas \u2014 so this maps out the sub-functions you may want to hook or inspect next. Each proto is reported via the standard function descriptor (Source, Name, LineDefined, NumParams, IsVararg, What, Pointer). Requires getconnections and debug.getprotos; returns a clear { error } if either is missing or the connection has no Lua Function. Returns { Signal, Instance?, ConnectionIndex, Function, Protos: [...], Count }.",category:"Signals & Connections",input:en.object({instancePath:en.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:en.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed', 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),connectionIndex:en.number().int().min(0).describe("Zero-based index of the connection whose handler protos to enumerate, as reported by list-signal-connections. 0 is the first connection. Must be < ConnectionCount or a clear { error } is returned.").optional().default(0),threadContext:en.number().int().optional()}),async execute({instancePath:e,signalName:t,connectionIndex:n,threadContext:r},a){let o=`
${L}
local __getprotosFn = (type(debug) == "table") and debug.getprotos or nil
if type(__getprotosFn) ~= "function" then return { error = "debug.getprotos is not available in this executor." } end

local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local idx = ${n}
if idx < 0 or idx >= #conns then
  return { error = "connectionIndex " .. tostring(idx) .. " is out of range (signal has " .. tostring(#conns) .. " connection(s); valid 0.." .. tostring(#conns - 1) .. ")." }
end

local conn = conns[idx + 1]
local okFn, fn = pcall(function() return conn.Function end)
if not okFn or type(fn) ~= "function" then
  return { error = "Connection " .. tostring(idx) .. " has no Lua Function (it may be a C/foreign or thread connection)." }
end

local okP, protos = pcall(__getprotosFn, fn)
if not okP then return { error = "debug.getprotos failed: " .. tostring(protos) } end
if type(protos) ~= "table" then return { error = "debug.getprotos returned a non-table value." } end

local out = {}
for i = 1, #protos do
  local desc = __describeFunction(protos[i])
  if desc then desc.Index = i - 1 end
  out[i] = desc
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  ConnectionIndex = idx,
  Function = __describeFunction(fn),
  Protos = out,
  Count = #out,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as tn}from"zod";var Bo=u({name:"get-connection-upvalues",title:"Dump the upvalues of a connection's handler function",description:"Read the captured upvalues of the Lua function bound to ONE connection on an RBXScriptSignal (selected by zero-based index) via debug.getupvalues. Upvalues are the variables a closure captured from its enclosing scope \u2014 typically shared state, config tables, cached services or other functions \u2014 so this reveals the live context a hidden event handler operates on. Each upvalue is reported with its typeof and a readable encoded value (instances become full names, tables/functions become descriptors). Requires getconnections and debug.getupvalues; returns a clear { error } if either is missing or the connection has no Lua Function. Returns { Signal, Instance?, ConnectionIndex, Function, Upvalues: [...], Count }.",category:"Signals & Connections",input:tn.object({instancePath:tn.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:tn.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed', 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),connectionIndex:tn.number().int().min(0).describe("Zero-based index of the connection whose handler upvalues to read, as reported by list-signal-connections. 0 is the first connection. Must be < ConnectionCount or a clear { error } is returned.").optional().default(0),threadContext:tn.number().int().optional()}),async execute({instancePath:e,signalName:t,connectionIndex:n,threadContext:r},a){let o=`
${L}
local __getupvaluesFn = (type(debug) == "table") and debug.getupvalues or nil
if type(__getupvaluesFn) ~= "function" then return { error = "debug.getupvalues is not available in this executor." } end

local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local idx = ${n}
if idx < 0 or idx >= #conns then
  return { error = "connectionIndex " .. tostring(idx) .. " is out of range (signal has " .. tostring(#conns) .. " connection(s); valid 0.." .. tostring(#conns - 1) .. ")." }
end

local conn = conns[idx + 1]
local okFn, fn = pcall(function() return conn.Function end)
if not okFn or type(fn) ~= "function" then
  return { error = "Connection " .. tostring(idx) .. " has no Lua Function (it may be a C/foreign or thread connection)." }
end

local okU, ups = pcall(__getupvaluesFn, fn)
if not okU then return { error = "debug.getupvalues failed: " .. tostring(ups) } end
if type(ups) ~= "table" then return { error = "debug.getupvalues returned a non-table value." } end

local out = {}
for i = 1, #ups do
  out[i] = { Index = i - 1, Type = typeof(ups[i]), Value = __encVal(ups[i]) }
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  ConnectionIndex = idx,
  Function = __describeFunction(fn),
  Upvalues = out,
  Count = #out,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as Jn}from"zod";var zo=u({name:"get-signal-arguments-info",title:"Get detailed per-argument info for a signal",description:"Report RICH, per-argument metadata about what an RBXScriptSignal fires with, using the executor's getsignalargumentsinfo. This is the more detailed companion to get-signal-arguments: where that tool reports just the argument types/values, this returns the executor's fuller per-argument descriptor table (e.g. type tags, optionality, and per-entry detail) so you can precisely reconstruct a signal's payload when crafting a fire-signal / replicate-signal call. Pass the instance that owns the signal plus the signal member name (or leave signalName empty if instancePath already resolves to the signal). Requires the getsignalargumentsinfo executor function; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, ArgumentsInfo } with nested values mapped through a safe serializer.",category:"Signals & Connections",input:Jn.object({instancePath:Jn.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.ReplicatedStorage.MyRemote', 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:Jn.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'OnClientEvent', 'Touched', 'Changed'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),threadContext:Jn.number().int().optional()}),async execute({instancePath:e,signalName:t,threadContext:n},r){let a=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

if type(getsignalargumentsinfo) ~= "function" then
  return { error = "getsignalargumentsinfo is not available in this executor." }
end

local ok, res = pcall(getsignalargumentsinfo, sig)
if not ok then return { error = "getsignalargumentsinfo failed: " .. tostring(res) } end

-- Deeply map any nested tables through __encVal so the (potentially rich) info is serializable.
local function __mapDeep(v, depth)
  if type(v) ~= "table" or depth > 6 then return __encVal(v) end
  local out = {}
  for k, val in pairs(v) do
    if type(val) == "table" then
      out[k] = __mapDeep(val, depth + 1)
    else
      out[k] = __encVal(val)
    end
  end
  return out
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  ArgumentsInfo = __mapDeep(res, 0),
}
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}});import{z as er}from"zod";var Ko=u({name:"get-signal-arguments",title:"Get the argument types a signal fires with",description:`Report the value TYPES that an RBXScriptSignal fires its connected handlers with, using the executor's getsignalarguments. This answers "what shape is the payload of this event?" without having to connect a handler and wait for a fire \u2014 invaluable when reverse-engineering a remote-driven or engine signal so you know how to construct a fire-signal / replicate-signal call. Pass the instance that owns the signal plus the signal member name (or leave signalName empty if instancePath already resolves to the signal). Requires the getsignalarguments executor function; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, Arguments } where Arguments is the type/scalar info mapped through a safe serializer.`,category:"Signals & Connections",input:er.object({instancePath:er.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.ReplicatedStorage.MyRemote', 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the RBXScriptSignal itself."),signalName:er.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'OnClientEvent', 'Touched', 'Changed'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),threadContext:er.number().int().optional()}),async execute({instancePath:e,signalName:t,threadContext:n},r){let a=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

if type(getsignalarguments) ~= "function" then
  return { error = "getsignalarguments is not available in this executor." }
end

local ok, res = pcall(getsignalarguments, sig)
if not ok then return { error = "getsignalarguments failed: " .. tostring(res) } end

local function __mapArgs(v)
  if type(v) == "table" then
    local out = {}
    for k, val in pairs(v) do
      if type(val) == "table" then
        local inner = {}
        for ik, iv in pairs(val) do inner[ik] = __encVal(iv) end
        out[k] = inner
      else
        out[k] = __encVal(val)
      end
    end
    return out
  end
  return __encVal(v)
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  Arguments = __mapArgs(res),
}
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}});import{z as Kr}from"zod";var Ho=u({name:"get-signal-whitelist",title:"List the engine's replicatable-signal whitelist",description:'Enumerate the full set of signals the Roblox engine allows to be replicated to the server, using the executor\'s getsignalwhitelist. This is the global allow-list that can-signal-replicate / replicate-signal check against, so it answers "which signals can I drive server-side?" up front, without probing them one at a time. The whitelist is typically large (180+ entries), so each entry is mapped through a safe serializer and the output is capped at `limit`. Requires the getsignalwhitelist executor function; degrades with a clear { error } if unavailable. Returns { Count, Truncated, Signals }.',category:"Signals & Connections",input:Kr.object({limit:Kr.number().int().positive().describe("Maximum number of whitelist entries to return (default 300). The list can be large, so this caps the response; Count always reflects the true total and Truncated indicates whether entries were dropped.").optional().default(300),threadContext:Kr.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=`
${L}
if type(getsignalwhitelist) ~= "function" then
  return { error = "getsignalwhitelist is not available in this executor." }
end

local ok, res = pcall(getsignalwhitelist)
if not ok or type(res) ~= "table" then
  return { error = "getsignalwhitelist failed: " .. tostring(res) }
end

local limit = ${Math.max(1,Math.floor(e))}

-- Whitelist entries are tables describing a signal, e.g. { Parent = "Seat",
-- Event = "RemoteCreateSeatWeld" }. Encode each field so the output is readable
-- instead of an opaque "table: 0x..." pointer.
local function encEntry(entry)
  if type(entry) == "table" then
    local t = {}
    for k, v in pairs(entry) do t[tostring(k)] = __encVal(v) end
    return t
  end
  return __encVal(entry)
end

local list = {}
local total = 0
for _, entry in pairs(res) do
  total = total + 1
  if #list < limit then
    list[#list + 1] = encEntry(entry)
  end
end

return {
  Count = total,
  Truncated = total > #list,
  Signals = list,
}
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as nn}from"zod";var Xo=u({name:"list-signal-connections",title:"List all connections on a signal",description:`Enumerate every connection on an RBXScriptSignal and, for each, report its full Connection metadata: Index, Enabled, LuaConnection, ForeignState, whether it has a Function/Thread, and (for Lua connections) the connected function's Source script, Name, LineDefined and NumParams. This is the main tool for answering "what is listening to this event and where is each handler defined?". Requires getconnections; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, ConnectionCount, Connections: [...] }.`,category:"Signals & Connections",input:nn.object({instancePath:nn.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door', 'game.Players.PlayerAdded' parent). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the signal itself."),signalName:nn.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed', 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),includeFunctionInfo:nn.boolean().describe("When true (default), resolve each Lua connection's function source/line/name via debug.info. Set false for a faster summary that only reports counts and connection flags.").optional().default(!0),threadContext:nn.number().int().optional()}),async execute({instancePath:e,signalName:t,includeFunctionInfo:n,threadContext:r},a){let o=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local withFn = ${n?"true":"false"}
local list = {}
local luaCount, foreignCount, enabledCount = 0, 0, 0
for i = 1, #conns do
  local info = __connInfo(conns[i], i - 1, withFn)
  if info.LuaConnection then luaCount = luaCount + 1 else foreignCount = foreignCount + 1 end
  if info.Enabled then enabledCount = enabledCount + 1 end
  list[#list + 1] = info
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  ConnectionCount = #conns,
  LuaConnections = luaCount,
  ForeignConnections = foreignCount,
  EnabledConnections = enabledCount,
  Connections = list,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as ge}from"zod";var Yc=ge.array(ge.object({kind:ge.enum(["string","number","boolean","nil","instance","raw"]).describe("How to interpret `value`: 'string'/'number'/'boolean' = a literal of that type; 'nil' = a Lua nil (value ignored); 'instance' = `value` is a Lua path like 'game.Players.LocalPlayer' resolved to an Instance at runtime; 'raw' = `value` is a raw Luau expression like 'Vector3.new(1,2,3)' evaluated at runtime."),value:ge.union([ge.string(),ge.number(),ge.boolean()]).describe("The argument payload. Omit for kind='nil'. For kind='instance' pass a Lua path string; for kind='raw' pass a Luau expression string.").optional()})).describe("Ordered list of arguments to replicate with the event, mirroring the real arguments the server expects for this signal. Omit or pass [] to replicate with no arguments.").optional(),Yo=u({name:"replicate-signal",title:"Replicate a signal to the SERVER",description:"MUTATES SERVER STATE \u2014 DANGEROUS. Invokes replicatesignal(signal, ...) to fire the event with full network REPLICATION, so the event is delivered to the SERVER and can have real, authoritative server-side effects (unlike fire-signal, which is local only). Only some signals are replicable; this tool first checks cansignalreplicate(signal) and refuses to fire if it returns false. Use this ONLY for authorized testing of a game you own/control \u2014 firing replicated signals on other games may violate their rules. Requires the executor's replicatesignal; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, Replicated, ArgCount } or { error }.",category:"Signals & Connections",mutatesState:!0,input:ge.object({instancePath:ge.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.ReplicatedStorage.RemoteEvent'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the signal itself."),signalName:ge.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'OnClientEvent'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),args:Yc,threadContext:ge.number().int().optional()}),async execute({instancePath:e,signalName:t,args:n,threadContext:r},a){let{preamble:o,argExpr:i}=dt(n),l=n?.length??0,c=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

if type(replicatesignal) ~= "function" then return { error = "replicatesignal is not available in this executor." } end

if type(cansignalreplicate) == "function" then
  local okCan, can = pcall(cansignalreplicate, sig)
  if not okCan then return { error = "cansignalreplicate failed: " .. tostring(can) } end
  if can == false then return { error = "Signal cannot be replicated (cansignalreplicate=false)." } end
end

${o}
local okRep, repErr = pcall(function() replicatesignal(sig${i?", "+i:""}) end)
if not okRep then return { error = "replicatesignal failed: " .. tostring(repErr) } end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  Replicated = true,
  ArgCount = ${l},
}
`;return{data:await a.runLuau(c,{threadContext:r,timeoutMs:2e4})}}});import{z as Ge}from"zod";var Zo=["Touched","TouchEnded","Changed","ChildAdded","ChildRemoved","DescendantAdded","AncestryChanged","Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up","InputBegan","InputChanged","InputEnded","OnClientEvent","OnServerEvent","Event","Heartbeat","RenderStepped","Stepped"],Qo=u({name:"scan-connections-by-source",title:"Scan connection handlers by defining script source",description:'Sweep a hierarchy for event handlers and pinpoint which script each handler is defined in. Walks descendants of `root`, probes a set of signal names on each instance, and for every Lua connection describes its Function via debug.info. If the function\'s Source contains `sourcePattern` (case-insensitive substring; empty matches ALL handlers) it records { Instance, Signal, ConnectionIndex, Source, LineDefined, Name }. This answers "find every event handler defined in <script>", "where are all the handlers backed by this module?", or simply "enumerate all connected handlers under here and tell me their source". Requires the executor\'s getconnections and debug.info; degrades to a clear { error } if getconnections is unavailable (a missing debug.info merely leaves Source blank). Bounded by maxScan (instances) and maxResults (matches). Returns { Matches, MatchCount, ScannedInstances, Truncated }.',category:"Signals & Connections",input:Ge.object({root:Ge.string().describe("Lua expression for the root instance whose descendants are scanned (e.g. 'game', 'game.Workspace', 'game.StarterGui'). Evaluated as `return <root>`. Defaults to 'game'. Narrow this to speed up the scan and reduce noise.").optional().default("game"),sourcePattern:Ge.string().describe("Case-insensitive substring matched against each Lua connection's function Source (the chunk/script path reported by debug.info, e.g. a script name or asset path). When empty (default), EVERY Lua handler is matched, giving a full inventory. Set it to a script name to find only handlers defined in that script.").optional().default(""),signalNames:Ge.array(Ge.string()).describe("Signal member names to probe on each instance. When omitted, a sensible default list of commonly connected signals is used (Touched, Changed, ChildAdded, Activated, InputBegan, OnClientEvent, Heartbeat, etc.). Provide your own list to target specific events and make the scan faster.").optional().default(Zo),maxResults:Ge.number().int().positive().describe("Maximum number of matching connections to collect before stopping the scan. Defaults to 200. If this cap is hit, Truncated is true.").optional().default(200),maxScan:Ge.number().int().positive().describe("Maximum number of descendant instances to examine. Defaults to 4000. Raise to cover larger games (slower); lower for a quick sample. If this cap is hit, Truncated is true.").optional().default(4e3),threadContext:Ge.number().int().optional()}),async execute({root:e,sourcePattern:t,signalNames:n,maxResults:r,maxScan:a,threadContext:o},i){let c="{ "+(n&&n.length>0?n:Zo).map(f=>s(f)).join(", ")+" }",d=`
${L}
local rootInst, rerr = __resolveInstance(${s(e)})
if not rootInst then return { error = rerr } end
if type(__getconnectionsFn) ~= "function" then return { error = "getconnections is not available in this executor." } end

local signalNames = ${c}
local pattern = ${s(t)}
local patternLower = string.lower(pattern)
local hasPattern = pattern ~= ""
local maxResults = ${Math.trunc(r)}
local maxScan = ${Math.trunc(a)}

local scanned = 0
local truncated = false
local matches = {}

local okDesc, descendants = pcall(function() return rootInst:GetDescendants() end)
if not okDesc or type(descendants) ~= "table" then
  return { error = "Failed to enumerate descendants of " .. rootInst:GetFullName() .. "." }
end

local function matchesPattern(src)
  if not hasPattern then return true end
  if type(src) ~= "string" then return false end
  return string.find(string.lower(src), patternLower, 1, true) ~= nil
end

for i = 1, #descendants do
  if scanned >= maxScan then truncated = true break end
  if #matches >= maxResults then truncated = true break end
  local inst = descendants[i]
  scanned = scanned + 1
  local instPath = nil
  for s = 1, #signalNames do
    if #matches >= maxResults then truncated = true break end
    local sname = signalNames[s]
    local okSig, sig = pcall(function() return inst[sname] end)
    if okSig and typeof(sig) == "RBXScriptSignal" then
      local okC, conns = pcall(__getconnectionsFn, sig)
      if okC and type(conns) == "table" then
        for ci = 1, #conns do
          if #matches >= maxResults then truncated = true break end
          local okFn, fn = pcall(function() return conns[ci].Function end)
          if okFn and type(fn) == "function" then
            local desc = __describeFunction(fn)
            local src = desc and desc.Source or ""
            if matchesPattern(src) then
              if instPath == nil then
                local okP, p = pcall(function() return inst:GetFullName() end)
                instPath = okP and p or "?"
              end
              matches[#matches + 1] = {
                Instance = instPath,
                Signal = sname,
                ConnectionIndex = ci - 1,
                Source = src,
                LineDefined = desc and desc.LineDefined or -1,
                Name = desc and desc.Name or "<anonymous>",
              }
            end
          end
        end
      end
    end
  end
end

return {
  Matches = matches,
  MatchCount = #matches,
  ScannedInstances = scanned,
  Truncated = truncated,
}
`;return{data:await i.runLuau(d,{threadContext:o,timeoutMs:45e3})}}});import{z as De}from"zod";var Jo=u({name:"set-connection-state",title:"Disable / enable / disconnect signal connections",description:"MUTATES CLIENT STATE. Toggles or removes connections on an RBXScriptSignal: 'disable' temporarily stops a connection from firing (reversible with 'enable'), 'enable' re-activates a disabled connection, and 'disconnect' permanently removes it \u2014 IRREVERSIBLE for that connection (you would have to recreate it). scope='one' targets a single connection by index; scope='all' applies to every connection on the signal. Because they are destructive, scope='all' and action='disconnect' BOTH require confirm=true or the tool refuses without changing anything. Useful for silencing or surgically removing event handlers (e.g. anti-cheat or input listeners) while debugging. Requires getconnections plus the connection's Disable/Enable/Disconnect methods; degrades with a clear { error } if unavailable. Returns { Signal, Instance?, Action, Scope, Affected } or { error }.",category:"Signals & Connections",mutatesState:!0,input:De.object({instancePath:De.string().describe("Lua expression resolving to the Instance that owns the signal (e.g. 'game.Workspace.Door'). Evaluated as `return <instancePath>`. Leave signalName empty if this expression already resolves to the signal itself."),signalName:De.string().describe("Name of the RBXScriptSignal member on the instance (e.g. 'Touched', 'Changed'). Leave empty/omit if instancePath already evaluates to the signal.").optional().default(""),action:De.enum(["disable","enable","disconnect"]).describe("What to do to the matched connection(s): 'disable' = stop firing but keep it (reversible via 'enable'); 'enable' = re-activate a disabled connection; 'disconnect' = permanently remove it (IRREVERSIBLE, requires confirm=true)."),scope:De.enum(["one","all"]).describe("'one' (default) affects only the single connection at connectionIndex; 'all' affects every connection on the signal and REQUIRES confirm=true.").optional().default("one"),connectionIndex:De.number().int().min(0).describe("Zero-based index of the target connection within getconnections(signal) when scope='one', matching the Index from list-signal-connections. Ignored when scope='all'. Defaults to 0.").optional().default(0),confirm:De.boolean().describe("Safety gate for destructive operations. Must be true to run when scope='all' OR action='disconnect'; otherwise the tool refuses without making changes. Not required for disable/enable on a single connection.").optional().default(!1),threadContext:De.number().int().optional()}),async execute({instancePath:e,signalName:t,action:n,scope:r,connectionIndex:a,confirm:o,threadContext:i},l){if((r==="all"||n==="disconnect")&&o!==!0)return{data:{error:`Refusing to ${n} ${r}; pass confirm=true.`},summary:`Refusing to ${n} ${r}; pass confirm=true.`,isError:!0};let d=n==="disconnect"?"Disconnect":n==="enable"?"Enable":"Disable",p=`
${L}
local sig, inst, err = __resolveSignal(${s(e)}, ${s(t)})
if not sig then return { error = err } end

local conns, cerr = __getConns(sig)
if not conns then return { error = cerr } end

local scope = ${s(r)}
local affected = 0

local function apply(conn)
  if conn == nil then return false end
  local ok = pcall(function() conn:${d}() end)
  return ok
end

if scope == "all" then
  for i = 1, #conns do
    if apply(conns[i]) then affected = affected + 1 end
  end
else
  local idx = ${a}
  if idx < 0 or idx >= #conns then
    return { error = "connectionIndex " .. idx .. " out of range (signal has " .. #conns .. " connection(s); valid 0.." .. (#conns - 1) .. ")." }
  end
  if apply(conns[idx + 1]) then affected = affected + 1 end
end

return {
  Signal = ${t?s(t):"tostring(sig)"},
  Instance = inst and inst:GetFullName() or nil,
  Action = ${s(n)},
  Scope = scope,
  Affected = affected,
}
`;return{data:await l.runLuau(p,{threadContext:i,timeoutMs:2e4})}}});import{z as Zc}from"zod";var ei=u({name:"clear-selection",title:"Clear this session's client selection",description:"Drop THIS session's client binding so it no longer pins a specific client or account. Afterwards tools auto-resolve: with exactly one client connected they use it; with several different accounts you must select-client again. Use this to reset routing before re-selecting, or to hand control back to auto-resolution.",category:"Session & Client",input:Zc.object({}),requiresClient:!1,async execute(e,t){return t.session.clear(),{data:{cleared:!0,resolution:Re(t.session.resolve())},summary:"Selection cleared."}}});import{z as Qc}from"zod";var ti=u({name:"get-active-client",title:"Show which Roblox client this session targets",description:"Report which live Roblox client THIS session currently resolves to (read-only), including its current selection and whether resolution is ambiguous or offline. Use it to confirm routing before running code, especially when multiple games are connected or after a rejoin.",category:"Session & Client",input:Qc.object({}),requiresClient:!1,async execute(e,t){let n=Re(t.session.resolve()),r=n.status==="resolved"?`Targeting ${n.client.username??n.client.clientId}.`:n.status==="ambiguous"?`Ambiguous \u2014 ${n.candidates.length} accounts connected; run select-client.`:n.reason==="no-clients"?"No clients connected.":"Selected client is offline.";return{data:{selection:t.session.selection,resolution:n},summary:r}}});import{z as Yr}from"zod";var rn=class extends Error{details;retryable=!1;constructor(t,n,r){super(t,r),this.details=n,this.name=new.target.name}toJSON(){return{code:this.code,message:this.message,...this.details?{details:{...this.details}}:{}}}},Ue=class extends rn{code="VALIDATION"};var Hr=class extends rn{code="INTERNAL"};function ni(e){if(e instanceof rn)return e;let t=e instanceof Error?e.message:String(e);return new Hr(t,void 0,{cause:e})}function ri(e,t){return e.userId!==null&&t.userId!==null?e.userId===t.userId:e.username!==null&&t.username!==null?e.username.toLowerCase()===t.username.toLowerCase():e.id===t.id}var tr=e=>e;var Xr=e=>e;var ai=u({name:"select-client",title:"Bind this session to a Roblox client (account-sticky)",description:"Bind a connected Roblox client to THIS session so your tool calls target that game. Select by clientId OR by username \u2014 selecting by username is recommended because it is account-sticky: a client gets a new clientId every reconnect, but a username binding follows the account across rejoins without re-selecting. Each session keeps its own selection, so two sessions can drive two games at once. If several agents SHARE one session, don't fight over this binding \u2014 instead pass `client` (clientId or username) directly to script/execute/run-luau to target a game for a single call without changing anyone's selection. Provide exactly one of clientId or username; the value must match a currently-connected client.",category:"Session & Client",input:Yr.object({clientId:Yr.string().min(1).optional(),username:Yr.string().min(1).optional()}).refine(e=>e.clientId!==void 0||e.username!==void 0,{message:"Provide a clientId or a username."}),requiresClient:!1,async execute({clientId:e,username:t},n){let r=n.clients.list();if(r.length===0)throw new Ue("No Roblox clients are connected. Run the loader in your executor first.");if(e!==void 0){let d=r.find(f=>f.id===e);if(!d)throw new Ue(`No connected client has clientId "${e}".`,{connected:r.map(f=>f.id)});n.session.select({clientId:tr(d.id),...d.userId!==null?{userId:Xr(d.userId)}:{},...d.username!==null?{username:d.username}:{}});let p=Re(n.session.resolve());return{data:{selected:Xe(d),resolution:p},summary:`Session bound to ${d.username??d.id} (account-sticky).`}}let a=t.toLowerCase(),o=r.filter(d=>d.username!==null&&d.username.toLowerCase()===a);if(o.length===0)throw new Ue(`No connected client matched username "${t}".`,{connected:r.map(d=>d.username).filter(d=>d!==null)});let i=o.reduce((d,p)=>p.connectedAt>d.connectedAt?p:d);n.session.select({...i.userId!==null?{userId:Xr(i.userId)}:{},username:i.username??t});let l=Re(n.session.resolve()),c=o.filter((d,p)=>o.findIndex(f=>ri(f,d))===p).length;return{data:{selected:Xe(i),resolution:l},summary:`Session bound to ${i.username??t} (account-sticky${c>1||o.length>1?`, ${o.length} matching window(s)`:""}).`}}});import{z as Jc}from"zod";var oi=u({name:"clear-semantic-index",title:"Clear the semantic script index",description:"Drop the cached semantic index for THIS session's active client. This clears a SERVER-SIDE embedding cache only \u2014 it does not touch the game or any live script. Resolves the active client from this session's selection; if one is resolved its index is cleared, otherwise nothing happens. Use it to force the next semantic-search-scripts call to re-harvest and re-embed from scratch (e.g. after the game's scripts changed).",category:"Semantic Search",input:Jc.object({}),requiresClient:!1,mutatesState:!1,async execute(e,t){let n=t.session.resolve();return n.status!=="resolved"?{data:{cleared:!1},summary:"No active client \u2014 nothing to clear."}:(t.semantic.clear(n.client.id),{data:{cleared:!0},summary:"Semantic index cleared for the active client."})}});import{z as eu}from"zod";var ii=u({name:"get-semantic-index-stats",title:"Semantic index statistics",description:"Report the semantic script index for THIS session's active client WITHOUT touching the game: whether anything is indexed, how many documents are cached, and the embedding model + dimensions in use. Resolves the active client from this session's selection; if no client is resolved it returns an empty, not-indexed summary. Use it to confirm an index exists before searching, or to see which embeddings backend is active.",category:"Semantic Search",input:eu.object({}),requiresClient:!1,async execute(e,t){let n=t.session.resolve();if(n.status!=="resolved")return{data:{indexed:!1,documentCount:0,model:null,dimensions:null},summary:"No active client \u2014 nothing indexed."};let r=t.semantic.stats(n.client.id),a=r.indexed?`Indexed ${r.documentCount} script(s) with ${r.model??"unknown"}.`:"No scripts indexed yet for the active client.";return{data:r,summary:a}}});import{z as nr}from"zod";function tu(e){return`
local __ok, __result = pcall(function()
  local docs = {}
  local seen = {}
  local maxScripts = ${e}
  local maxConstChars = 4000

  local getscripts = rawget(getfenv(), "getscripts") or getscripts
  local getgc = rawget(getfenv(), "getgc") or getgc
  local getscriptclosure = rawget(getfenv(), "getscriptclosure")
    or rawget(getfenv(), "getscriptfunction")

  local function collectConstants(closure)
    if type(closure) ~= "function" then return "" end
    local okC, consts = pcall(function()
      return debug.getconstants(closure)
    end)
    if not okC or type(consts) ~= "table" then return "" end
    local parts = {}
    local total = 0
    for _, value in pairs(consts) do
      if type(value) == "string" and #value > 1 then
        parts[#parts + 1] = value
        total = total + #value
        if total >= maxConstChars then break end
      end
    end
    return table.concat(parts, " ")
  end

  local function addScript(inst)
    if typeof(inst) ~= "Instance" then return end
    if not inst:IsA("LuaSourceContainer") then return end
    if seen[inst] then return end
    seen[inst] = true
    if #docs >= maxScripts then return end

    local okPath, path = pcall(function() return inst:GetFullName() end)
    if not okPath then path = tostring(inst) end
    local className = inst.ClassName
    local name = inst.Name

    local constants = ""
    if getscriptclosure then
      local okClosure, closure = pcall(getscriptclosure, inst)
      if okClosure then
        constants = collectConstants(closure)
      end
    end

    local text = path .. " " .. name .. " " .. className
    if #constants > 0 then
      text = text .. " " .. constants
    end
    docs[#docs + 1] = { path = path, text = text }
  end

  if type(getscripts) == "function" then
    local okS, scripts = pcall(getscripts)
    if okS and type(scripts) == "table" then
      for _, inst in ipairs(scripts) do
        addScript(inst)
        if #docs >= maxScripts then break end
      end
    end
  end

  if #docs < maxScripts and type(getgc) == "function" then
    local okG, objects = pcall(getgc, false)
    if okG and type(objects) == "table" then
      for _, obj in ipairs(objects) do
        if #docs >= maxScripts then break end
        addScript(obj)
      end
    end
  end

  return docs
end)

if __ok then
  return __result
end
return {}
`}var si=u({name:"semantic-search-scripts",title:"Semantic search over loaded scripts",description:"Rank the active client's loaded/GC scripts by semantic relevance to a natural-language query. NOTE: full decompiled source is NOT available in the clean protocol, so each script is indexed over its GetFullName() path + Name + ClassName + the string constants reachable from its closure (capped per script) \u2014 think of it as 'find the script most likely about X', not a full-text code search. The first call embeds and caches every script (locally or via the configured embeddings endpoint); later calls reuse the cache for unchanged scripts. Returns { hits: [{ path, score, snippet }], model } sorted by descending cosine similarity.",category:"Semantic Search",input:nr.object({query:nr.string().min(1).describe("Natural-language description of the script you are looking for."),limit:nr.number().int().optional().default(10).describe("Maximum number of ranked hits to return."),maxScripts:nr.number().int().optional().default(400).describe("Cap on how many scripts to harvest and index from the client.")}),requiresClient:!0,async execute({query:e,limit:t,maxScripts:n},r){let a=await r.runLuau(tu(n)),o=nu(a),i=r.client.id,l=await r.semantic.search(i,e,t,o),c=r.semantic.stats(i).model;return{data:{hits:l,model:c},summary:`${l.length} hit(s) over ${o.length} indexed script(s).`}}});function nu(e){if(!Array.isArray(e))return[];let t=[];for(let n of e){if(typeof n!="object"||n===null)continue;let r=n;typeof r.path!="string"||typeof r.text!="string"||t.push({path:r.path,text:r.text})}return t}import{z as rr}from"zod";var li=2e5,Zr=4e3,ci=u({name:"compare-gc-snapshots",title:"Capture / compare GC snapshots",description:`Take a census of the garbage collector (getgc) and diff it over time to find what was allocated or freed between two points - a leak-hunting / behaviour-attribution tool.

Workflow: call with action='capture' (a baseline), perform some action in-game (open a menu, fire a remote, etc.), then call with action='compare' (same snapshotName) to see what changed.

Snapshots are stored CLIENT-SIDE in getgenv().__mcp_gc_snapshots[name], so they live in the target game and are naturally isolated per game / per session.

capture returns: { action='capture', name, ts, counts={ function, table, thread, total }, fnSampled, truncated }.
compare returns: { action='compare', name, baselineTs, nowTs, countDeltas={ function, table, thread, total }, newFunctions=[..pointers..], newFunctionCount, freedApprox (functions no longer present), sampledOnly, truncated }.

Caps: at most `+li+" GC objects are walked per pass and at most "+Zr+" function pointers are remembered; results note when truncation occurred, so treat large freed/new counts near the cap as approximate.",category:"Reverse Engineering",input:rr.object({action:rr.enum(["capture","compare"]).describe("'capture' stores a baseline census of the GC under snapshotName. 'compare' diffs the current GC against the previously stored snapshot of that name and reports new/freed functions and per-type count deltas."),snapshotName:rr.string().describe("Name/slot for the snapshot (default 'default'). Use distinct names to keep several independent baselines around at once.").optional().default("default"),threadContext:rr.number().int().optional()}),async execute({action:e,snapshotName:t,threadContext:n},r){let a=e==="capture",o=`
local result = {}

local function censusGc()
  local getgcFn = getgc
  if type(getgcFn) ~= "function" then
    return nil, "getgc is not available in this executor."
  end

  -- Prefer the deep walk getgc(true); fall back to getgc() if it errors.
  local ok, objs = pcall(getgcFn, true)
  if not ok or type(objs) ~= "table" then
    ok, objs = pcall(getgcFn)
  end
  if not ok or type(objs) ~= "table" then
    return nil, "getgc() failed: " .. tostring(objs)
  end

  local counts = { ["function"] = 0, table = 0, thread = 0, other = 0, total = 0 }
  local fnSet = {}
  local fnSampled = false
  local truncated = false
  local seen = 0

  for _, obj in ipairs(objs) do
    seen = seen + 1
    if seen > ${li} then
      truncated = true
      break
    end
    local t = type(obj)
    counts.total = counts.total + 1
    if t == "function" then
      counts["function"] = counts["function"] + 1
      if counts["function"] <= ${Zr} then
        local okPtr, ptr = pcall(tostring, obj)
        if okPtr then fnSet[ptr] = true end
      else
        fnSampled = true
      end
    elseif t == "table" then
      counts.table = counts.table + 1
    elseif t == "thread" then
      counts.thread = counts.thread + 1
    else
      counts.other = counts.other + 1
    end
  end

  return { counts = counts, fnSet = fnSet, fnSampled = fnSampled, truncated = truncated }, nil
end

local function getStore()
  if type(getgenv) ~= "function" then return nil end
  local env = getgenv()
  if type(env) ~= "table" then return nil end
  if type(env.__mcp_gc_snapshots) ~= "table" then
    env.__mcp_gc_snapshots = {}
  end
  return env.__mcp_gc_snapshots
end

local function run()
  local NAME = ${s(t)}
  local store = getStore()
  if not store then
    return { error = "getgenv() is unavailable; cannot persist GC snapshots client-side." }
  end

  local census, err = censusGc()
  if not census then
    return { error = err }
  end

  ${a?`
  -- CAPTURE: store the census under NAME and return a summary.
  store[NAME] = {
    ts = os.time(),
    counts = census.counts,
    fnSet = census.fnSet,
    fnSampled = census.fnSampled,
    truncated = census.truncated,
  }
  return {
    action = "capture",
    name = NAME,
    ts = store[NAME].ts,
    counts = census.counts,
    fnSampled = census.fnSampled,
    truncated = census.truncated,
  }`:`
  -- COMPARE: diff the current census against the stored baseline.
  local base = store[NAME]
  if type(base) ~= "table" then
    return { error = "No snapshot named '" .. NAME .. "' to compare against. Run action='capture' first." }
  end

  local baseCounts = base.counts or {}
  local nowCounts = census.counts
  local function delta(key) return (nowCounts[key] or 0) - (baseCounts[key] or 0) end

  local countDeltas = {
    ["function"] = delta("function"),
    table = delta("table"),
    thread = delta("thread"),
    other = delta("other"),
    total = delta("total"),
  }

  -- Function pointer diff (sampled / capped sets).
  local baseFns = base.fnSet or {}
  local nowFns = census.fnSet
  local newFunctions = {}
  local newFunctionCount = 0
  for ptr in pairs(nowFns) do
    if not baseFns[ptr] then
      newFunctionCount = newFunctionCount + 1
      if #newFunctions < ${Zr} then
        table.insert(newFunctions, ptr)
      end
    end
  end

  local freedApprox = 0
  for ptr in pairs(baseFns) do
    if not nowFns[ptr] then
      freedApprox = freedApprox + 1
    end
  end

  return {
    action = "compare",
    name = NAME,
    baselineTs = base.ts,
    nowTs = os.time(),
    countDeltas = countDeltas,
    baselineCounts = baseCounts,
    currentCounts = nowCounts,
    newFunctions = newFunctions,
    newFunctionCount = newFunctionCount,
    freedApprox = freedApprox,
    sampledOnly = (base.fnSampled == true) or (census.fnSampled == true),
    truncated = (base.truncated == true) or (census.truncated == true),
  }`}
end

local ok, res = pcall(run)
if ok then
  result = res
else
  result = { error = "compare-gc-snapshots failed: " .. tostring(res) }
end
return result`;return{data:await r.runLuau(o,{timeoutMs:3e4,...n!==void 0?{threadContext:n}:{}})}}});import{z as ar}from"zod";var ui=u({name:"dump-function-env",title:"Dump function env",description:"Find function by query and inspect environment table keys/values.",category:"Reverse Engineering",input:ar.object({query:ar.string(),limit:ar.number().optional().default(120),threadContext:ar.number().int().optional()}),async execute({query:e,limit:t,threadContext:n},r){let a=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getinfo) == "function", "debug.getinfo unavailable")
local q = string.lower(${s(e)})
local cap = math.max(1, math.min(1000, ${Math.floor(t)}))
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okInfo, info = pcall(debug.getinfo, fn, "nSlu")
    if okInfo and info then
      local name = string.lower(tostring(info.name or ""))
      local src = string.lower(tostring(info.source or ""))
      if string.find(name, q, 1, true) or string.find(src, q, 1, true) then
        local env = getfenv(fn)
        local out = {}
        local i = 0
        for k, v in pairs(env) do
          i = i + 1
          if #out >= cap then break end
          out[#out + 1] = { Key = tostring(k), Type = typeof and typeof(v) or type(v), Value = tostring(v) }
        end
        return {
          Function = { Name = info.name or "<anonymous>", Source = info.source or "", LineDefined = info.linedefined or -1, Pointer = tostring(fn) },
          EnvCount = i,
          Env = out,
        }
      end
    end
  end
end
return { error = "No matching function found." }`;return{data:await r.runLuau(a,{timeoutMs:3e4,...n!==void 0?{threadContext:n}:{}})}}});import{z as an}from"zod";var di=u({name:"find-bytecode-size-outliers",title:"Find bytecode size outliers",description:"Scan scripts and rank by getscriptbytecode size to find complex/high-value targets quickly.",category:"Reverse Engineering",input:an.object({limit:an.number().optional().default(100),includeModules:an.boolean().optional().default(!0),includeLocalScripts:an.boolean().optional().default(!0),threadContext:an.number().int().optional()}),async execute({limit:e,includeModules:t,includeLocalScripts:n,threadContext:r},a){let o=`
assert(type(getscriptbytecode) == "function", "getscriptbytecode unavailable")
local cap = math.max(1, math.min(2000, ${Math.floor(e)}))
local includeModules = ${t?"true":"false"}
local includeLocalScripts = ${n?"true":"false"}
local out = {}
for _, v in ipairs(game:GetDescendants()) do
  local okType = (includeModules and v:IsA("ModuleScript")) or (includeLocalScripts and v:IsA("LocalScript"))
  if okType then
    local ok, bc = pcall(getscriptbytecode, v)
    if ok and type(bc) == "string" then
      out[#out+1] = { Path = v:GetFullName(), ClassName = v.ClassName, BytecodeSize = #bc, DebugId = v:GetDebugId() }
    end
  end
end
table.sort(out, function(a,b) return a.BytecodeSize > b.BytecodeSize end)
local trimmed = {}
for i = 1, math.min(cap, #out) do trimmed[i] = out[i] end
return { count = #trimmed, results = trimmed }`;return{data:await a.runLuau(o,{timeoutMs:6e4,...r!==void 0?{threadContext:r}:{}})}}});import{z as or}from"zod";var pi=u({name:"find-constants-xref",title:"Find constants xref",description:"Find getgc functions containing a target constant and return compact xrefs.",category:"Reverse Engineering",input:or.object({constantQuery:or.string(),limit:or.number().optional().default(120),threadContext:or.number().int().optional()}),async execute({constantQuery:e,limit:t,threadContext:n},r){let a=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getinfo) == "function", "debug.getinfo unavailable")
assert(type(debug.getconstants) == "function", "debug.getconstants unavailable")
local q = string.lower(${s(e)})
local max = math.max(1, math.min(2000, ${Math.floor(t)}))
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okc, constants = pcall(debug.getconstants, fn)
    if okc and type(constants) == "table" then
      local hits = 0
      for _, c in ipairs(constants) do
        if string.find(string.lower(tostring(c)), q, 1, true) then hits = hits + 1 end
      end
      if hits > 0 then
        local oki, info = pcall(debug.getinfo, fn, "nSlu")
        table.insert(out, {
          Name = (oki and info and info.name) or "<anonymous>",
          Source = (oki and info and info.source) or "",
          LineDefined = (oki and info and info.linedefined) or -1,
          HitCount = hits,
          Pointer = tostring(fn)
        })
        if #out >= max then break end
      end
    end
  end
end
table.sort(out, function(a,b) return a.HitCount > b.HitCount end)
return { query = q, count = #out, results = out }`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:45e3})}}});import{z as on}from"zod";var fi=u({name:"find-event-connections",title:"Find event connections",description:"Inspect RBXScriptSignal connections by instance path + signal name.",category:"Reverse Engineering",input:on.object({instancePath:on.string(),signalName:on.string(),limit:on.number().optional().default(100),threadContext:on.number().int().optional()}),async execute({instancePath:e,signalName:t,limit:n,threadContext:r},a){let o=`
assert(type(getconnections) == "function", "getconnections unavailable")
local inst = loadstring("return " .. ${s(e)})()
assert(typeof(inst) == "Instance", "instancePath did not resolve to Instance")
local okSignal, signal = pcall(function() return inst[${s(t)}] end)
if not okSignal then return { error = "Signal " .. ${s(t)} .. " not found on instance " .. inst:GetFullName() } end
if typeof(signal) ~= "RBXScriptSignal" then return { error = "signalName " .. ${s(t)} .. " did not resolve to RBXScriptSignal (got " .. (typeof(signal)) .. ")" } end
local limit = math.max(1, math.min(1000, ${Math.floor(n)}))
local out = {}
for _, conn in ipairs(getconnections(signal)) do
  if #out >= limit then break end
  table.insert(out, {
    Enabled = conn.Enabled,
    ForeignState = conn.ForeignState,
    LuaConnection = conn.LuaConnection,
    Function = tostring(conn.Function),
    Thread = tostring(conn.Thread),
  })
end
return { instance = inst:GetFullName(), signal = ${s(t)}, count = #out, results = out }`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:3e4})}}});import{z as sn}from"zod";var mi=u({name:"find-functions-by-constant",title:"Find functions by constant",description:"Scan getgc() and find closures whose constants contain a target string/number. Useful for locating handlers and hidden logic by magic constants.",category:"Reverse Engineering",input:sn.object({constantQuery:sn.string().describe("Case-insensitive constant substring to search for."),limit:sn.number().describe("Maximum number of matched functions to return (default: 30).").optional().default(30),includeCClosures:sn.boolean().describe("Include C closures (default: false).").optional().default(!1),threadContext:sn.number().int().optional()}),async execute({constantQuery:e,limit:t,includeCClosures:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),300),i=`
local function contains(haystack, needle)
  haystack = string.lower(tostring(haystack or ""))
  needle = string.lower(needle)
  return string.find(haystack, needle, 1, true) ~= nil
end

local getgcFn = getgc
if type(getgcFn) ~= "function" then
  return { error = "getgc is not available in this executor." }
end
if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
  return { error = "debug.getinfo is not available in this executor." }
end
if type(debug.getconstants) ~= "function" then
  return { error = "debug.getconstants is not available in this executor." }
end

local needle = ${s(e)}
local maxResults = ${o}
local includeC = ${n?"true":"false"}

local scanned = 0
local results = {}
for _, obj in ipairs(getgcFn(true)) do
  if type(obj) == "function" then
    scanned = scanned + 1
    local okInfo, info = pcall(debug.getinfo, obj, "nSlu")
    if okInfo and info and (includeC or info.what ~= "C") then
      local okConsts, constants = pcall(debug.getconstants, obj)
      if okConsts and type(constants) == "table" then
        local hit = false
        local hitCount = 0
        local preview = {}
        for i, c in ipairs(constants) do
          local text = tostring(c)
          if contains(text, needle) then
            hit = true
            hitCount = hitCount + 1
          end
          if #preview < 12 then preview[#preview + 1] = text end
          if i >= 512 then break end
        end
        if hit then
          table.insert(results, {
            Name = info.name or "<anonymous>",
            Source = info.source or "",
            ShortSource = info.short_src or "",
            LineDefined = info.linedefined or -1,
            ConstantHits = hitCount,
            ConstantsPreview = preview,
            FunctionPointer = tostring(obj),
          })
          if #results >= maxResults then break end
        end
      end
    end
  end
end

table.sort(results, function(a, b)
  if a.ConstantHits == b.ConstantHits then
    return tostring(a.Source) < tostring(b.Source)
  end
  return a.ConstantHits > b.ConstantHits
end)

return {
  constantQuery = needle,
  scanned = scanned,
  returned = #results,
  results = results,
}
`;return{data:await a.runLuau(i,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as ir}from"zod";var hi=u({name:"find-module-scripts",title:"Find module scripts",description:"Search ModuleScripts by substring against name/full path.",category:"Reverse Engineering",input:ir.object({query:ir.string(),limit:ir.number().optional().default(200),threadContext:ir.number().int().optional()}),async execute({query:e,limit:t,threadContext:n},r){let a=`
local q = string.lower(${s(e)})
local limit = math.max(1, math.min(2000, ${Math.floor(t)}))
local out = {}
for _, v in ipairs(game:GetDescendants()) do
  if v:IsA("ModuleScript") then
    local n = string.lower(v.Name)
    local p = string.lower(v:GetFullName())
    if string.find(n, q, 1, true) or string.find(p, q, 1, true) then
      table.insert(out, { Name = v.Name, Path = v:GetFullName(), DebugId = v:GetDebugId() })
      if #out >= limit then break end
    end
  end
end
return { count = #out, query = q, results = out }`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:3e4})}}});import{z as sr}from"zod";var gi=u({name:"find-path-references",title:"Find path references",description:"Find constants containing instance path fragments like ReplicatedStorage/Workspace.",category:"Reverse Engineering",input:sr.object({query:sr.string(),limit:sr.number().optional().default(150),threadContext:sr.number().int().optional()}),async execute({query:e,limit:t,threadContext:n},r){let a=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getconstants) == "function" and type(debug.getinfo) == "function", "required debug APIs unavailable")
local q = string.lower(${s(e)})
local cap = math.max(1, math.min(2000, ${Math.floor(t)}))
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okC, constants = pcall(debug.getconstants, fn)
    if okC and type(constants) == "table" then
      local hits = 0
      local firstMatch = nil
      for _, c in ipairs(constants) do
        local s = string.lower(tostring(c))
        if string.find(s, q, 1, true) then
          hits = hits + 1
          if firstMatch == nil then firstMatch = tostring(c) end
        end
      end
      if hits > 0 then
        local okI, info = pcall(debug.getinfo, fn, "nSlu")
        out[#out+1] = {
          Match = firstMatch,
          HitCount = hits,
          Function = (okI and info and info.name) or "<anonymous>",
          Source = (okI and info and info.source) or "",
          LineDefined = (okI and info and info.linedefined) or -1,
        }
        if #out >= cap then break end
      end
    end
  end
end
table.sort(out, function(a,b) return a.HitCount > b.HitCount end)
return { query = q, count = #out, results = out }`;return{data:await r.runLuau(a,{timeoutMs:45e3,...n!==void 0?{threadContext:n}:{}})}}});import{z as lr}from"zod";var bi=u({name:"find-upvalue-xref",title:"Find upvalue xref",description:"Find functions whose upvalue names or values match a query.",category:"Reverse Engineering",input:lr.object({query:lr.string(),limit:lr.number().optional().default(80),threadContext:lr.number().int().optional()}),async execute({query:e,limit:t,threadContext:n},r){let a=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and (type(debug.getupvalue) == "function" or type(debug.getupvalues) == "function"), "debug upvalue APIs unavailable")
assert(type(debug.getinfo) == "function", "debug.getinfo unavailable")
local q = string.lower(${s(e)})
local max = math.max(1, math.min(1000, ${Math.floor(t)}))
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local matched = false
    local preview = {}
    if type(debug.getupvalue) == "function" then
      for i = 1, 100 do
        local ok, n, v = pcall(debug.getupvalue, fn, i)
        if not ok or n == nil then break end
        local ns = string.lower(tostring(n))
        local vs = string.lower(tostring(v))
        if string.find(ns, q, 1, true) or string.find(vs, q, 1, true) then matched = true end
        if #preview < 10 then preview[#preview+1] = { Index = i, Name = tostring(n), Value = tostring(v) } end
      end
    end
    if matched then
      local okInfo, info = pcall(debug.getinfo, fn, "nSlu")
      table.insert(out, {
        Name = (okInfo and info and info.name) or "<anonymous>",
        Source = (okInfo and info and info.source) or "",
        LineDefined = (okInfo and info and info.linedefined) or -1,
        Upvalues = preview,
        Pointer = tostring(fn),
      })
      if #out >= max then break end
    end
  end
end
return { query = q, count = #out, results = out }`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:45e3})}}});import{z as cr}from"zod";var yi=u({name:"get-function-protos",title:"Get function protos",description:"Find a function by query and dump nested proto debug info.",category:"Reverse Engineering",input:cr.object({query:cr.string(),maxProtos:cr.number().optional().default(30),threadContext:cr.number().int().optional()}),async execute({query:e,maxProtos:t,threadContext:n},r){let a=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getinfo) == "function", "debug.getinfo unavailable")
assert(type(debug.getprotos) == "function", "debug.getprotos unavailable")
local q = string.lower(${s(e)})
local cap = math.max(1, math.min(500, ${Math.floor(t)}))
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okInfo, info = pcall(debug.getinfo, fn, "nSlu")
    if okInfo and info then
      local name = string.lower(tostring(info.name or ""))
      local src = string.lower(tostring(info.source or ""))
      if string.find(name, q, 1, true) or string.find(src, q, 1, true) then
        local okP, protos = pcall(debug.getprotos, fn)
        if okP and type(protos) == "table" then
          local out = {}
          for i, p in ipairs(protos) do
            if i > cap then break end
            local okPi, pi = pcall(debug.getinfo, p, "nSlu")
            table.insert(out, {
              Index = i,
              Name = (okPi and pi and pi.name) or "<anonymous>",
              Source = (okPi and pi and pi.source) or "",
              LineDefined = (okPi and pi and pi.linedefined) or -1,
              Pointer = tostring(p),
            })
          end
          return {
            Parent = { Name = info.name or "<anonymous>", Source = info.source or "", LineDefined = info.linedefined or -1, Pointer = tostring(fn) },
            ProtoCount = #protos,
            Protos = out,
          }
        end
      end
    end
  end
end
return { error = "No matching function with protos found." }`;return{data:await r.runLuau(a,{timeoutMs:45e3,...n!==void 0?{threadContext:n}:{}})}}});import{z as Ye}from"zod";var vi=u({name:"get-function-upvalues",title:"Get function upvalues",description:"Find matching functions in getgc() and dump their upvalues for live reverse engineering.",category:"Reverse Engineering",input:Ye.object({query:Ye.string().describe("Case-insensitive match against function name/source."),sourceQuery:Ye.string().describe("Optional additional source filter.").optional(),maxFunctions:Ye.number().describe("Maximum number of matched functions to inspect (default: 5).").optional().default(5),maxUpvalues:Ye.number().describe("Maximum upvalues per function (default: 30).").optional().default(30),includeCClosures:Ye.boolean().describe("Include C closures (default: false).").optional().default(!1),threadContext:Ye.number().int().optional()}),async execute({query:e,sourceQuery:t,maxFunctions:n,maxUpvalues:r,includeCClosures:a,threadContext:o},i){let l=Math.min(Math.max(Math.floor(n),1),50),c=Math.min(Math.max(Math.floor(r),1),200),d=`
local function contains(haystack, needle)
  if needle == "" then return true end
  haystack = string.lower(tostring(haystack or ""))
  needle = string.lower(needle)
  return string.find(haystack, needle, 1, true) ~= nil
end

local getgcFn = getgc
if type(getgcFn) ~= "function" then
  return { error = "getgc is not available in this executor." }
end
if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
  return { error = "debug.getinfo is not available in this executor." }
end

local query = ${s(e)}
local sourceNeedle = ${s(t??"")}
local maxFunctions = ${l}
local maxUpvalues = ${c}
local includeC = ${a?"true":"false"}

local inspected = {}
for _, obj in ipairs(getgcFn(true)) do
  if type(obj) == "function" then
    local okInfo, info = pcall(debug.getinfo, obj, "nSlu")
    if okInfo and info then
      if includeC or info.what ~= "C" then
        local fnName = info.name or "<anonymous>"
        local src = info.source or ""
        local shortSrc = info.short_src or ""
        if contains(fnName, query) or contains(src, query) or contains(shortSrc, query) then
          if contains(src, sourceNeedle) or contains(shortSrc, sourceNeedle) then
            local entry = {
              Name = fnName,
              Source = src,
              ShortSource = shortSrc,
              LineDefined = info.linedefined or -1,
              FunctionPointer = tostring(obj),
              Upvalues = {},
            }

            local loaded = false
            if type(debug.getupvalue) == "function" then
              loaded = true
              for i = 1, maxUpvalues do
                local okUp, upName, upValue = pcall(debug.getupvalue, obj, i)
                if not okUp or upName == nil then break end
                entry.Upvalues[#entry.Upvalues + 1] = {
                  Index = i,
                  Name = tostring(upName),
                  Type = typeof and typeof(upValue) or type(upValue),
                  Preview = tostring(upValue),
                }
              end
            elseif type(debug.getupvalues) == "function" then
              loaded = true
              local okUps, ups = pcall(debug.getupvalues, obj)
              if okUps and type(ups) == "table" then
                for i, upValue in ipairs(ups) do
                  if i > maxUpvalues then break end
                  entry.Upvalues[#entry.Upvalues + 1] = {
                    Index = i,
                    Name = "<unknown>",
                    Type = typeof and typeof(upValue) or type(upValue),
                    Preview = tostring(upValue),
                  }
                end
              end
            end

            if not loaded then
              entry.Upvalues = { { Index = 0, Name = "<unsupported>", Type = "none", Preview = "debug upvalue APIs unavailable" } }
            end

            table.insert(inspected, entry)
            if #inspected >= maxFunctions then break end
          end
        end
      end
    end
  end
end

return {
  query = query,
  sourceQuery = sourceNeedle,
  matchedFunctions = #inspected,
  results = inspected,
}
`;return{data:await i.runLuau(d,{timeoutMs:45e3,...o!==void 0?{threadContext:o}:{}})}}});import{z as Qr}from"zod";var ki=u({name:"get-module-source",title:"Get module source",description:"Decompile a specific ModuleScript by path.",category:"Reverse Engineering",input:Qr.object({modulePath:Qr.string(),threadContext:Qr.number().int().optional()}),async execute({modulePath:e,threadContext:t},n){let r=`
local mod = loadstring("return " .. ${s(e)})()
assert(typeof(mod) == "Instance" and mod:IsA("ModuleScript"), "modulePath must resolve to ModuleScript")
local ok, src = pcall(function() return decompile(mod) end)
if not ok then return { error = tostring(src) } end
return { path = mod:GetFullName(), source = src }`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:6e4})}}});import{z as Jr}from"zod";var xi=u({name:"inspect-instance-metatable",title:"Inspect instance metatable",description:"Get metatable keys from a target Instance path (e.g., game.Players.LocalPlayer).",category:"Reverse Engineering",input:Jr.object({instancePath:Jr.string(),threadContext:Jr.number().int().optional()}),async execute({instancePath:e,threadContext:t},n){let r=`
local inst = loadstring("return " .. ${s(e)})()
assert(typeof(inst) == "Instance", "instancePath did not resolve to Instance")
local okMt, mt = pcall(function() return getrawmetatable and getrawmetatable(inst) or getmetatable(inst) end)
if not okMt then return { error = "Failed to read metatable: " .. tostring(mt) } end
if type(mt) ~= "table" then return { error = "Metatable is not a table (got " .. type(mt) .. "); it may be protected/locked." } end
local keys = {}
for k, v in pairs(mt) do
  if #keys >= 300 then break end
  table.insert(keys, { Key = tostring(k), Type = typeof and typeof(v) or type(v), Value = tostring(v) })
end
return { Instance = inst:GetFullName(), KeyCount = #keys, Keys = keys }`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:3e4})}}});import{z as pt}from"zod";var _i=u({name:"list-gc-functions",title:"List GC functions",description:"Enumerate live Lua closures from getgc() and return debug metadata (name/source/line/upvalues). Useful for live reversing when script paths are unknown.",category:"Reverse Engineering",input:pt.object({nameQuery:pt.string().describe("Optional case-insensitive substring match against function names.").optional(),sourceQuery:pt.string().describe("Optional case-insensitive substring match against debug source/short_src.").optional(),includeCClosures:pt.boolean().describe("Include C closures from getgc (default: false).").optional().default(!1),limit:pt.number().describe("Maximum number of functions to return (default: 100).").optional().default(100),threadContext:pt.number().int().optional()}),async execute({nameQuery:e,sourceQuery:t,includeCClosures:n,limit:r,threadContext:a},o){let i=Math.min(Math.max(Math.floor(r),1),1e3),l=`
local function contains(haystack, needle)
  if needle == "" then return true end
  haystack = string.lower(tostring(haystack or ""))
  needle = string.lower(needle)
  return string.find(haystack, needle, 1, true) ~= nil
end

local getgcFn = getgc
if type(getgcFn) ~= "function" then
  return { error = "getgc is not available in this executor." }
end
if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
  return { error = "debug.getinfo is not available in this executor." }
end

local nameNeedle = ${s(e??"")}
local sourceNeedle = ${s(t??"")}
local includeC = ${n?"true":"false"}
local maxResults = ${i}

local scanned = 0
local results = {}
for _, obj in ipairs(getgcFn(true)) do
  if type(obj) == "function" then
    scanned = scanned + 1
    local okInfo, info = pcall(debug.getinfo, obj, "nSlu")
    if okInfo and info then
      if includeC or info.what ~= "C" then
        local fnName = info.name or "<anonymous>"
        local src = info.source or ""
        local shortSrc = info.short_src or ""
        if contains(fnName, nameNeedle) and (contains(src, sourceNeedle) or contains(shortSrc, sourceNeedle)) then
          local upCount = 0
          if type(debug.getupvalues) == "function" then
            local okUps, ups = pcall(debug.getupvalues, obj)
            if okUps and type(ups) == "table" then
              upCount = #ups
            end
          elseif type(debug.getupvalue) == "function" then
            local i = 1
            while true do
              local okUp, upName = pcall(debug.getupvalue, obj, i)
              if not okUp or upName == nil then break end
              upCount = upCount + 1
              i = i + 1
              if i > 2000 then break end
            end
          end

          table.insert(results, {
            Name = fnName,
            Source = src,
            ShortSource = shortSrc,
            LineDefined = info.linedefined or -1,
            LastLineDefined = info.lastlinedefined or -1,
            What = info.what or "?",
            NumParams = info.nparams or -1,
            IsVararg = info.isvararg == true,
            UpvalueCount = upCount,
            FunctionPointer = tostring(obj),
          })
          if #results >= maxResults then break end
        end
      end
    end
  end
end

return {
  scanned = scanned,
  returned = #results,
  limit = maxResults,
  filters = { nameQuery = nameNeedle, sourceQuery = sourceNeedle, includeCClosures = includeC },
  results = results,
}
`;return{data:await o.runLuau(l,{timeoutMs:3e4,...a!==void 0?{threadContext:a}:{}})}}});import{z as ur}from"zod";var wi=u({name:"list-gc-tables",title:"List GC tables",description:"Enumerate table objects from getgc(true) with optional key/value query matching.",category:"Reverse Engineering",input:ur.object({query:ur.string().optional().default(""),limit:ur.number().optional().default(100),threadContext:ur.number().int().optional()}),async execute({query:e,limit:t,threadContext:n},r){let a=`
local getgcFn = getgc
if type(getgcFn) ~= "function" then return { error = "getgc unavailable" } end
local query = string.lower(${s(e)})
local limit = math.max(1, math.min(1000, ${Math.floor(t)}))
local out = {}
for _, obj in ipairs(getgcFn(true)) do
  if type(obj) == "table" then
    if #out >= limit then break end
    local keyCount = 0
    local matched = (query == "")
    for k, v in pairs(obj) do
      keyCount = keyCount + 1
      if query ~= "" then
        local ks, vs = string.lower(tostring(k)), string.lower(tostring(v))
        if string.find(ks, query, 1, true) or string.find(vs, query, 1, true) then matched = true end
      end
      if keyCount > 2000 then break end
    end
    if matched then
      table.insert(out, { TablePointer = tostring(obj), KeyCount = keyCount })
    end
  end
end
return { count = #out, results = out }`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:3e4})}}});import{z as ea}from"zod";var Si=u({name:"list-gc-threads",title:"List GC threads",description:"Enumerate thread objects from getgc(true), including coroutine status where available.",category:"Reverse Engineering",input:ea.object({limit:ea.number().optional().default(150),threadContext:ea.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=`
local getgcFn = getgc
if type(getgcFn) ~= "function" then return { error = "getgc unavailable" } end
local limit = math.max(1, math.min(1000, ${Math.floor(e)}))
local out = {}
for _, obj in ipairs(getgcFn(true)) do
  if type(obj) == "thread" then
    if #out >= limit then break end
    local ok, status = pcall(coroutine.status, obj)
    table.insert(out, { ThreadPointer = tostring(obj), Status = ok and status or "unknown" })
  end
end
return { count = #out, results = out }`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:3e4})}}});import{z as dr}from"zod";var Ei=u({name:"list-global-env-keys",title:"List global env keys",description:"List keys from getgenv/_G with type/value previews.",category:"Reverse Engineering",input:dr.object({query:dr.string().optional().default(""),limit:dr.number().optional().default(300),threadContext:dr.number().int().optional()}),async execute({query:e,limit:t,threadContext:n},r){let a=`
local env = (getgenv and getgenv()) or _G
local q = string.lower(${s(e)})
local cap = math.max(1, math.min(5000, ${Math.floor(t)}))
local out = {}
for k, v in pairs(env) do
  if #out >= cap then break end
  local ks = string.lower(tostring(k))
  if q == "" or string.find(ks, q, 1, true) then
    out[#out+1] = { Key = tostring(k), Type = typeof and typeof(v) or type(v), Value = tostring(v) }
  end
end
return { count = #out, results = out }`;return{data:await r.runLuau(a,{timeoutMs:3e4,...n!==void 0?{threadContext:n}:{}})}}});import{z as Ci}from"zod";var Ii=u({name:"list-registry-objects",title:"List registry objects",description:"Inspect debug.getregistry() and summarize object types for runtime reversing.",category:"Reverse Engineering",input:Ci.object({threadContext:Ci.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
if type(debug) ~= "table" or type(debug.getregistry) ~= "function" then return { error = "debug.getregistry unavailable" } end
local reg = debug.getregistry()
local counts = {}
local sample = {}
local i = 0
for k, v in pairs(reg) do
  i = i + 1
  local t = typeof and typeof(v) or type(v)
  counts[t] = (counts[t] or 0) + 1
  if #sample < 80 then
    table.insert(sample, { Key = tostring(k), Type = t, Value = tostring(v) })
  end
  if i > 50000 then break end
end
return { totalScanned = i, typeCounts = counts, sample = sample }`,{threadContext:e,timeoutMs:3e4})}}});import{z as pr}from"zod";var Ti=u({name:"list-runtime-modules",title:"List runtime modules",description:"Find ModuleScripts in game + nil instances and report metadata for reversing.",category:"Reverse Engineering",input:pr.object({includeNil:pr.boolean().optional().default(!0),limit:pr.number().optional().default(300),threadContext:pr.number().int().optional()}),async execute({includeNil:e,limit:t,threadContext:n},r){let a=`
local limit = math.max(1, math.min(5000, ${Math.floor(t)}))
local includeNil = ${e?"true":"false"}
local out = {}
for _, v in ipairs(game:GetDescendants()) do
  if v:IsA("ModuleScript") then
    table.insert(out, { Name = v.Name, Path = v:GetFullName(), DebugId = v:GetDebugId() })
    if #out >= limit then return { count = #out, results = out } end
  end
end
if includeNil and type(getnilinstances) == "function" then
  for _, v in ipairs(getnilinstances()) do
    if typeof(v) == "Instance" and v:IsA("ModuleScript") then
      table.insert(out, { Name = v.Name, Path = "<nil>." .. v.Name, DebugId = v:GetDebugId() })
      if #out >= limit then break end
    end
  end
end
return { count = #out, results = out }`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:45e3})}}});import{z as ta}from"zod";var Ri=u({name:"list-script-actors",title:"List script actors",description:"List Actor instances and contained LuaSourceContainer scripts for actor-based reverse analysis.",category:"Reverse Engineering",input:ta.object({limit:ta.number().optional().default(250),threadContext:ta.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=`
local cap = math.max(1, math.min(5000, ${Math.floor(e)}))
local out = {}
for _, actor in ipairs(game:GetDescendants()) do
  if actor:IsA("Actor") then
    local scripts = {}
    for _, d in ipairs(actor:GetDescendants()) do
      if d:IsA("LuaSourceContainer") then
        scripts[#scripts+1] = d:GetFullName()
        if #scripts >= 40 then break end
      end
    end
    out[#out+1] = { ActorPath = actor:GetFullName(), ScriptCount = #scripts, Scripts = scripts }
    if #out >= cap then break end
  end
end
return { count = #out, results = out }`;return{data:await n.runLuau(r,{timeoutMs:45e3,...t!==void 0?{threadContext:t}:{}})}}});import{z as Ze}from"zod";var Mi=u({name:"lookup-function",title:"Lookup function in getgc",description:"Search live functions by name/source/constant text and return enriched debug metadata for reverse engineering.",category:"Reverse Engineering",input:Ze.object({query:Ze.string().describe("Case-insensitive query to match against name/source/constants."),mode:Ze.enum(["name","source","constants","both"]).describe("Where to match the query (default: both).").optional().default("both"),limit:Ze.number().describe("Maximum number of functions to return (default: 25).").optional().default(25),includeCClosures:Ze.boolean().describe("Include C closures from getgc (default: false).").optional().default(!1),includeConstantsPreview:Ze.boolean().describe("Include a small constants preview if available (default: true).").optional().default(!0),threadContext:Ze.number().int().optional()}),async execute({query:e,mode:t,limit:n,includeCClosures:r,includeConstantsPreview:a,threadContext:o},i){let l=Math.min(Math.max(Math.floor(n),1),250),c=`
local function contains(haystack, needle)
  haystack = string.lower(tostring(haystack or ""))
  needle = string.lower(needle)
  return string.find(haystack, needle, 1, true) ~= nil
end

local getgcFn = getgc
if type(getgcFn) ~= "function" then
  return { error = "getgc is not available in this executor." }
end
if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
  return { error = "debug.getinfo is not available in this executor." }
end

local query = ${s(e)}
local mode = ${s(t)}
local includeC = ${r?"true":"false"}
local includeConstantsPreview = ${a?"true":"false"}
local maxResults = ${l}

local function constantMatches(fn)
  if type(debug.getconstants) ~= "function" then
    return false, {}
  end
  local ok, constants = pcall(debug.getconstants, fn)
  if not ok or type(constants) ~= "table" then
    return false, {}
  end
  local matched = false
  local preview = {}
  for i, c in ipairs(constants) do
    local text = tostring(c)
    if contains(text, query) then matched = true end
    if includeConstantsPreview and #preview < 12 then
      preview[#preview + 1] = text
    end
    if i >= 256 then break end
  end
  return matched, preview
end

local scanned = 0
local results = {}
for _, obj in ipairs(getgcFn(true)) do
  if type(obj) == "function" then
    scanned = scanned + 1
    local okInfo, info = pcall(debug.getinfo, obj, "nSlu")
    if okInfo and info then
      if includeC or info.what ~= "C" then
        local fnName = info.name or "<anonymous>"
        local src = info.source or ""
        local shortSrc = info.short_src or ""
        local matchName = contains(fnName, query)
        local matchSource = contains(src, query) or contains(shortSrc, query)
        local matchConst, preview = constantMatches(obj)
        local isMatch = false
        if mode == "name" then isMatch = matchName
        elseif mode == "source" then isMatch = matchSource
        elseif mode == "constants" then isMatch = matchConst
        else isMatch = matchName or matchSource or matchConst end

        if isMatch then
          local upCount = 0
          if type(debug.getupvalues) == "function" then
            local okUps, ups = pcall(debug.getupvalues, obj)
            if okUps and type(ups) == "table" then upCount = #ups end
          end

          table.insert(results, {
            Name = fnName,
            Source = src,
            ShortSource = shortSrc,
            LineDefined = info.linedefined or -1,
            LastLineDefined = info.lastlinedefined or -1,
            What = info.what or "?",
            NumParams = info.nparams or -1,
            IsVararg = info.isvararg == true,
            UpvalueCount = upCount,
            ConstantQueryMatched = matchConst,
            ConstantsPreview = preview,
            FunctionPointer = tostring(obj),
          })
          if #results >= maxResults then break end
        end
      end
    end
  end
end

return {
  query = query,
  mode = mode,
  scanned = scanned,
  returned = #results,
  results = results,
}
`;return{data:await i.runLuau(c,{timeoutMs:45e3,...o!==void 0?{threadContext:o}:{}})}}});import{z as ln}from"zod";var Li=u({name:"scan-closures-by-name",title:"Scan closures by name",description:"Find getgc closures whose debug name contains a target substring.",category:"Reverse Engineering",input:ln.object({nameQuery:ln.string(),limit:ln.number().optional().default(200),includeCClosures:ln.boolean().optional().default(!1),threadContext:ln.number().int().optional()}),async execute({nameQuery:e,limit:t,includeCClosures:n,threadContext:r},a){let o=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getinfo) == "function", "debug.getinfo unavailable")
local q = string.lower(${s(e)})
local cap = math.max(1, math.min(3000, ${Math.floor(t)}))
local includeC = ${n?"true":"false"}
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okI, info = pcall(debug.getinfo, fn, "nSlu")
    if okI and info and (includeC or info.what ~= "C") then
      local nm = string.lower(tostring(info.name or ""))
      if string.find(nm, q, 1, true) then
        out[#out+1] = {
          Name = info.name or "<anonymous>",
          Source = info.source or "",
          LineDefined = info.linedefined or -1,
          Pointer = tostring(fn),
        }
        if #out >= cap then break end
      end
    end
  end
end
return { query = q, count = #out, results = out }`;return{data:await a.runLuau(o,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as cn}from"zod";var Ai=u({name:"scan-closures-by-source",title:"Scan closures by source",description:"Find getgc closures whose debug source contains a target substring.",category:"Reverse Engineering",input:cn.object({sourceQuery:cn.string(),limit:cn.number().optional().default(200),includeCClosures:cn.boolean().optional().default(!1),threadContext:cn.number().int().optional()}),async execute({sourceQuery:e,limit:t,includeCClosures:n,threadContext:r},a){let o=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getinfo) == "function", "debug.getinfo unavailable")
local q = string.lower(${s(e)})
local cap = math.max(1, math.min(3000, ${Math.floor(t)}))
local includeC = ${n?"true":"false"}
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okI, info = pcall(debug.getinfo, fn, "nSlu")
    if okI and info and (includeC or info.what ~= "C") then
      local src = string.lower(tostring(info.source or ""))
      if string.find(src, q, 1, true) then
        out[#out+1] = {
          Name = info.name or "<anonymous>",
          Source = info.source or "",
          LineDefined = info.linedefined or -1,
          Pointer = tostring(fn),
        }
        if #out >= cap then break end
      end
    end
  end
end
return { query = q, count = #out, results = out }`;return{data:await a.runLuau(o,{timeoutMs:45e3,...r!==void 0?{threadContext:r}:{}})}}});import{z as Ni}from"zod";var Pi=u({name:"scan-hook-surfaces",title:"Scan hook surfaces",description:"Check availability of common exploit/debug hook APIs and return capability map.",category:"Reverse Engineering",input:Ni.object({threadContext:Ni.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
local names = {
  "hookfunction","hookmetamethod","getrawmetatable","setreadonly","islclosure","iscclosure",
  "getgc","getreg","getregistry","getconnections","getupvalues","getupvalue","getconstants",
  "getprotos","getfenv","setfenv","decompile","getscriptbytecode"
}
local out = {}
for _, n in ipairs(names) do
  local v = _G[n]
  out[#out+1] = { Name = n, Available = type(v) == "function", Type = type(v) }
end
return { count = #out, results = out }`,{timeoutMs:3e4,...e!==void 0?{threadContext:e}:{}})}}});import{z as na}from"zod";var $i=u({name:"scan-network-endpoints",title:"Scan network endpoints",description:"Find URL-like strings in function constants across getgc closures.",category:"Reverse Engineering",input:na.object({limit:na.number().optional().default(200),threadContext:na.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getconstants) == "function" and type(debug.getinfo) == "function", "required debug APIs unavailable")
local cap = math.max(1, math.min(2000, ${Math.floor(e)}))
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okC, constants = pcall(debug.getconstants, fn)
    if okC and type(constants) == "table" then
      for _, c in ipairs(constants) do
        local s = tostring(c)
        local url = string.match(s, "https?://[%w%.%-_/%%?=&:#]+")
        if url then
          local okI, info = pcall(debug.getinfo, fn, "nSlu")
          out[#out+1] = {
            Url = url,
            Function = (okI and info and info.name) or "<anonymous>",
            Source = (okI and info and info.source) or "",
            LineDefined = (okI and info and info.linedefined) or -1,
          }
          if #out >= cap then
            return { count = #out, results = out }
          end
        end
      end
    end
  end
end
return { count = #out, results = out }`;return{data:await n.runLuau(r,{timeoutMs:45e3,...t!==void 0?{threadContext:t}:{}})}}});import{z as fr}from"zod";var Fi=u({name:"scan-proto-functions",title:"Scan proto functions",description:"Use debug.getprotos over matched functions and return proto summaries.",category:"Reverse Engineering",input:fr.object({query:fr.string().optional().default(""),limit:fr.number().optional().default(100),threadContext:fr.number().int().optional()}),async execute({query:e,limit:t,threadContext:n},r){let a=`
assert(type(getgc) == "function", "getgc unavailable")
assert(type(debug) == "table" and type(debug.getinfo) == "function", "debug.getinfo unavailable")
assert(type(debug.getprotos) == "function", "debug.getprotos unavailable")
local q = string.lower(${s(e)})
local max = math.max(1, math.min(1000, ${Math.floor(t)}))
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okInfo, info = pcall(debug.getinfo, fn, "nSlu")
    if okInfo and info and info.what ~= "C" then
      local name = string.lower(tostring(info.name or ""))
      local src = string.lower(tostring(info.source or ""))
      if q == "" or string.find(name, q, 1, true) or string.find(src, q, 1, true) then
        local okP, protos = pcall(debug.getprotos, fn)
        if okP and type(protos) == "table" and #protos > 0 then
          table.insert(out, {
            Name = info.name or "<anonymous>",
            Source = info.source or "",
            LineDefined = info.linedefined or -1,
            ProtoCount = #protos,
            Pointer = tostring(fn),
          })
          if #out >= max then break end
        end
      end
    end
  end
end
table.sort(out, function(a,b) return a.ProtoCount > b.ProtoCount end)
return { query = q, count = #out, results = out }`;return{data:await r.runLuau(a,{timeoutMs:45e3,...n!==void 0?{threadContext:n}:{}})}}});import{z as ra}from"zod";var Oi=u({name:"scan-remote-listeners",title:"Scan remote listeners",description:"List RemoteEvent/RemoteFunction objects and listener counts from connection APIs.",category:"Reverse Engineering",input:ra.object({limit:ra.number().optional().default(300),threadContext:ra.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=`
assert(type(getconnections) == "function", "getconnections unavailable")
local max = math.max(1, math.min(5000, ${Math.floor(e)}))
local out = {}
for _, v in ipairs(game:GetDescendants()) do
  local isEvt = v:IsA("RemoteEvent")
  local isFn = v:IsA("RemoteFunction")
  if isEvt or isFn then
    local c1, c2 = 0, 0
    if isEvt then
      pcall(function() c1 = #(getconnections(v.OnClientEvent) or {}) end)
    else
      pcall(function() c1 = #(getconnections(v.RemoteOnInvokeClient) or {}) end)
    end
    table.insert(out, { Name = v.Name, Path = v:GetFullName(), ClassName = v.ClassName, ListenerCount = c1, DebugId = v:GetDebugId() })
    if #out >= max then break end
  end
end
return { count = #out, results = out }`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:45e3})}}});import{z as qi}from"zod";var Gi=u({name:"summarize-runtime-surfaces",title:"Summarize runtime surfaces",description:"Quick high-level reverse summary: counts for scripts/modules/remotes/actors/functions/tables/threads.",category:"Reverse Engineering",input:qi.object({threadContext:qi.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
local summary = {
  modules = 0,
  localscripts = 0,
  scripts = 0,
  remotes = 0,
  actors = 0,
  gcFunctions = 0,
  gcTables = 0,
  gcThreads = 0,
}
for _, v in ipairs(game:GetDescendants()) do
  if v:IsA("ModuleScript") then summary.modules = summary.modules + 1 end
  if v:IsA("LocalScript") then summary.localscripts = summary.localscripts + 1 end
  if v:IsA("Script") then summary.scripts = summary.scripts + 1 end
  if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then summary.remotes = summary.remotes + 1 end
  if v:IsA("Actor") then summary.actors = summary.actors + 1 end
end
if type(getgc) == "function" then
  for _, obj in ipairs(getgc(true)) do
    local t = type(obj)
    if t == "function" then summary.gcFunctions = summary.gcFunctions + 1
    elseif t == "table" then summary.gcTables = summary.gcTables + 1
    elseif t == "thread" then summary.gcThreads = summary.gcThreads + 1
    end
  end
end
return summary`,{timeoutMs:45e3,...e!==void 0?{threadContext:e}:{}})}}});import{z as aa}from"zod";var Di=u({name:"trace-require-callers",title:"Trace require callers",description:"Find functions that reference 'require' in constants/source via getgc scan.",category:"Reverse Engineering",input:aa.object({limit:aa.number().optional().default(80),threadContext:aa.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=`
if type(getgc) ~= "function" then return { error = "getgc unavailable" } end
if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then return { error = "debug.getinfo unavailable" } end
local max = math.max(1, math.min(500, ${Math.floor(e)}))
local out = {}
for _, fn in ipairs(getgc(true)) do
  if type(fn) == "function" then
    local okInfo, info = pcall(debug.getinfo, fn, "nSlu")
    if okInfo and info and info.what ~= "C" then
      local matched = false
      if string.find(string.lower(tostring(info.source or "")), "require", 1, true) then matched = true end
      if not matched and type(debug.getconstants) == "function" then
        local okC, c = pcall(debug.getconstants, fn)
        if okC and type(c) == "table" then
          for _, v in ipairs(c) do
            if string.find(string.lower(tostring(v)), "require", 1, true) then matched = true break end
          end
        end
      end
      if matched then
        table.insert(out, { Name = info.name or "<anonymous>", Source = info.source or "", LineDefined = info.linedefined or -1, Pointer = tostring(fn) })
        if #out >= max then break end
      end
    end
  end
end
return { count = #out, results = out }`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:3e4})}}});import{z as oa}from"zod";import{z as ft}from"zod";var k=`
local __hasDebug = type(debug) == "table"
local __d = __hasDebug and debug or {}
local __getrawmt = getrawmetatable
local __getinfo = (type(getinfo) == "function" and getinfo) or __d.getinfo or __d.info
local __getconstants = getconstants or __d.getconstants
local __getupvalues = getupvalues or __d.getupvalues
local __getprotos = getprotos or __d.getprotos
local __islclosure = islclosure
local __iscclosure = iscclosure

local function __encVal(v)
  local t = typeof(v)
  if t == "Instance" then local ok,n = pcall(function() return v:GetFullName() end); return ok and ("Instance: " .. n) or "<Instance>" end
  if t == "string" or t == "number" or t == "boolean" then return v end
  if t == "nil" then return "nil" end
  if t == "function" then return "function: " .. tostring(v) end
  if t == "table" then return "table: " .. tostring(v) end
  local ok, s = pcall(tostring, v); return ok and (t .. ": " .. tostring(s)) or ("<" .. t .. ">")
end

local function __eval(expr)
  local fn, cerr = loadstring("return " .. expr)
  if not fn then return nil, "compile error in expression: " .. tostring(cerr) end
  local ok, val = pcall(fn)
  if not ok then return nil, "error evaluating expression: " .. tostring(val) end
  return val, nil
end

local function __evalFn(expr)
  local val, err = __eval(expr)
  if err then return nil, err end
  if type(val) ~= "function" then return nil, "expression did not resolve to a function (got " .. typeof(val) .. "): " .. expr end
  return val, nil
end

local function __fnInfo(f)
  if type(f) ~= "function" then return nil end
  local r = {
    Pointer = tostring(f),
    IsLua = (type(__islclosure) == "function") and (pcall(__islclosure, f) and __islclosure(f)) or nil,
    IsC = (type(__iscclosure) == "function") and (pcall(__iscclosure, f) and __iscclosure(f)) or nil,
    Name = "", Source = "", ShortSource = "", LineDefined = -1, NumParams = -1, IsVararg = false, NumUpvalues = -1,
  }
  if type(__getinfo) == "function" then
    local okT, info = pcall(__getinfo, f, "nSlu")
    if okT and type(info) == "table" then
      r.Name = info.name or r.Name
      r.Source = info.source or r.Source
      r.ShortSource = info.short_src or r.ShortSource
      r.LineDefined = info.linedefined or r.LineDefined
      r.NumParams = info.nparams or r.NumParams
      r.IsVararg = info.isvararg == true
      r.NumUpvalues = info.nups or r.NumUpvalues
    else
      local okS, s = pcall(__getinfo, f, "s"); if okS and type(s) ~= "table" and s ~= nil then r.Source = tostring(s) end
      local okL, l = pcall(__getinfo, f, "l"); if okL and type(l) == "number" then r.LineDefined = l end
      local okA, a = pcall(__getinfo, f, "a"); if okA and type(a) == "number" then r.NumParams = a end
      local okN, n = pcall(__getinfo, f, "n"); if okN and type(n) ~= "table" and n ~= nil then r.Name = tostring(n) end
    end
  end
  return r
end
`;function te(e){switch(e.kind){case"string":return s(String(e.value??""));case"number":return String(Number(e.value??0));case"boolean":return e.value?"true":"false";case"nil":return"nil";case"raw":return`(loadstring("return " .. ${s(String(e.value??"nil"))}))()`;default:return"nil"}}var we=ft.object({kind:ft.enum(["string","number","boolean","nil","raw"]),value:ft.union([ft.string(),ft.number(),ft.boolean()]).optional()});var Ui=u({name:"get-remote-signature",title:"Probe a single remote/bindable's shape (arg types, listeners, callback)",description:`Read-only inspection of ONE remote or bindable to learn how it is used WITHOUT firing it or installing any hook. Resolves \`remotePath\` to an Instance, reports its ClassName, then probes class-appropriately:
  - RemoteEvent / UnreliableRemoteEvent: reads getsignalarguments(remote.OnClientEvent) to surface the recent argument types the server sent to the client, and getconnections(remote.OnClientEvent) to count how many local listeners are attached (both guarded).
  - RemoteFunction: reads getcallbackvalue(remote, 'OnClientInvoke') and, if it is a function, reports its debug.info (source/line/name/params) so you can locate the handler the client registered.
  - BindableEvent: same OnClientEvent-style getsignalarguments + getconnections probe but on .Event.
  - BindableFunction: getcallbackvalue(remote, 'OnInvoke') -> function info.
Use this after list-remotes to understand a specific remote before firing it (fire-remote) or before spying it (monitor-remote). It tells you the argument shape and whether anything is listening, which is exactly what you need to craft a valid call. Each probe is optional and pcall-guarded: a field is omitted (with a *Error note) when the executor lacks the capability or the read fails \u2014 the tool never throws. Requires (optionally) getsignalarguments, getconnections, getcallbackvalue, and debug.info; missing ones simply skip that field. Returns { ok, path, class, signalArguments?, connectionCount?, callback?, notes }, or { error }.`,category:"Remote Spy",input:oa.object({remotePath:oa.string().describe(`Luau expression resolving to the RemoteEvent / RemoteFunction / UnreliableRemoteEvent / BindableEvent / BindableFunction to inspect, e.g. 'game:GetService("ReplicatedStorage").Remotes.BuyItem' or 'game.ReplicatedStorage:WaitForChild("DataRemote")'. Evaluated as \`return <remotePath>\` and must resolve to an Instance of one of those classes.`),threadContext:oa.number().int().optional()}),async execute({remotePath:e,threadContext:t},n){let r=`
${k}
local remote, err = __eval(${s(e)})
if err then return { error = err } end
if typeof(remote) ~= "Instance" then return { error = "expression did not resolve to an Instance (got " .. typeof(remote) .. "): " .. ${s(e)} } end

local okClass, cls = pcall(function() return remote.ClassName end)
if not okClass then return { error = "failed to read ClassName: " .. tostring(cls) } end

local KNOWN = {
  RemoteEvent = true, RemoteFunction = true, UnreliableRemoteEvent = true,
  BindableEvent = true, BindableFunction = true,
}

local path
local okName, full = pcall(function() return remote:GetFullName() end)
if okName then path = full else path = ${s(e)} end

local __getsignalarguments = getsignalarguments
local __getconnections = getconnections
local __getcallbackvalue = getcallbackvalue

local result = { ok = true, path = path, class = cls, notes = {} }
local notes = result.notes

if not KNOWN[cls] then
  notes[#notes + 1] = "ClassName '" .. tostring(cls) .. "' is not a known remote/bindable class; probing skipped."
  return result
end

-- Probe the signal that carries inbound traffic for this class.
-- RemoteEvent/Unreliable -> OnClientEvent ; BindableEvent -> Event ; (RemoteFunction/BindableFunction use a callback).
local function probeSignal(signalName)
  local okSig, signal = pcall(function() return remote[signalName] end)
  if not okSig or signal == nil then
    notes[#notes + 1] = "could not read signal '" .. signalName .. "': " .. tostring(signal)
    return
  end

  if type(__getsignalarguments) == "function" then
    local okA, args = pcall(__getsignalarguments, signal)
    if okA and type(args) == "table" then
      -- getsignalarguments may return a list of fire-records (each a table of the
      -- real args) OR a flat arg list. Encode one level deep so a fire-record
      -- yields its per-argument types instead of just {"table","table",...}.
      local enc = {}
      for i = 1, #args do
        local a = args[i]
        if type(a) == "table" then
          local inner = {}
          for k, v in pairs(a) do
            local okT, t = pcall(typeof, v)
            if okT then inner[k] = t else inner[k] = __encVal(v) end
          end
          enc[i] = inner
        else
          local okT, t = pcall(typeof, a)
          if okT then enc[i] = t else enc[i] = __encVal(a) end
        end
      end
      result.signalArguments = enc
      result.signalArgumentsFrom = signalName
    else
      notes[#notes + 1] = "getsignalarguments(" .. signalName .. ") failed or returned no recent args."
    end
  else
    notes[#notes + 1] = "getsignalarguments is not available in this executor."
  end

  if type(__getconnections) == "function" then
    local okC, conns = pcall(__getconnections, signal)
    if okC and type(conns) == "table" then
      result.connectionCount = #conns
    else
      notes[#notes + 1] = "getconnections(" .. signalName .. ") failed."
    end
  else
    notes[#notes + 1] = "getconnections is not available in this executor."
  end
end

-- Probe a callback property (RemoteFunction.OnClientInvoke / BindableFunction.OnInvoke).
local function probeCallback(propName)
  if type(__getcallbackvalue) ~= "function" then
    notes[#notes + 1] = "getcallbackvalue is not available in this executor; cannot read " .. propName .. "."
    return
  end
  local okCb, cb = pcall(__getcallbackvalue, remote, propName)
  if not okCb then
    notes[#notes + 1] = "getcallbackvalue(" .. propName .. ") failed: " .. tostring(cb)
    return
  end
  if type(cb) ~= "function" then
    result.callback = { property = propName, present = false }
    notes[#notes + 1] = propName .. " is not set (no callback registered on this client)."
    return
  end
  local info = __fnInfo(cb)
  result.callback = { property = propName, present = true, info = info }
end

if cls == "RemoteEvent" or cls == "UnreliableRemoteEvent" then
  probeSignal("OnClientEvent")
elseif cls == "BindableEvent" then
  probeSignal("Event")
elseif cls == "RemoteFunction" then
  probeCallback("OnClientInvoke")
elseif cls == "BindableFunction" then
  probeCallback("OnInvoke")
end

return result
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as un}from"zod";var ji=u({name:"inspect-callbacks",title:"Inspect RemoteFunction / BindableFunction invoke callbacks",description:"Find and disassemble the invoke callbacks bound to RemoteFunctions and BindableFunctions \u2014 these are where a game's request/response logic lives (the server-authoritative answer to a client question, or a cross-script RPC), so they are frequently the single most valuable functions to reverse. Unlike signal events (OnClientEvent/OnServerEvent), invoke callbacks are stored as a hidden property on the instance and are NOT visible to getconnections; the ONLY way to retrieve them is getcallbackvalue. This tool walks a subtree (default the whole DataModel), and for every RemoteFunction reads its OnClientInvoke and OnServerInvoke slots, and for every BindableFunction reads its OnInvoke slot. For each slot that actually holds a function it captures debug.info (source / line-defined / name) so you can immediately pivot to inspect-closure, get-closure-constants, get-closure-upvalues, scan-proto-functions, or hook-function on the exact callback. Use the source/line to locate the defining script and the name to understand intent. Requires getcallbackvalue (returns a clean { error } if the executor lacks it). The scan is fully pcall-guarded (locked/parented-out/dead instances never abort it), capped by maxScan, and the output is capped by limit with a `truncated` flag. Read-only: it inspects callbacks but never invokes or modifies them. Returns { count, scanned, truncated, root, callbacks } where each entry is { remote, class, slot, callback = { source, line, name, pointer, isC } }.",category:"Remote Spy",input:un.object({root:un.string().describe("Luau expression for the subtree root whose descendants are scanned, evaluated as `return <root>`. Defaults to 'game' (the whole DataModel). Narrow it to cut scan time and noise, e.g. 'game.ReplicatedStorage', 'game:GetService(\"ReplicatedStorage\").Remotes', or 'game.Players.LocalPlayer.PlayerGui'.").optional().default("game"),limit:un.number().int().describe("Maximum number of callback entries to return (default 150). Once reached the scan stops early and `truncated` is set true.").optional().default(150),maxScan:un.number().int().describe("Maximum number of descendant instances to visit while scanning (default 8000). Caps cost on huge DataModels; if hit, `truncated` is set true. Clamped to 100..60000.").optional().default(8e3),threadContext:un.number().int().optional()}),async execute({root:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),2e3),i=Math.min(Math.max(Math.floor(n),100),6e4),l=`
local __gcv = getcallbackvalue or (type(debug) == "table" and (debug.getcallbackvalue or debug.getcallback)) or nil
if type(__gcv) ~= "function" then return { error = "getcallbackvalue not available" } end

local __d = (type(debug) == "table") and debug or {}
local __getinfo = (type(getinfo) == "function" and getinfo) or __d.getinfo or __d.info
local __iscclosure = iscclosure or __d.iscclosure

local function __fullName(inst)
  local ok, n = pcall(function() return inst:GetFullName() end)
  if ok and type(n) == "string" then return n end
  local ok2, n2 = pcall(function() return inst.Name end)
  if ok2 and n2 ~= nil then return tostring(n2) end
  return "<instance>"
end

local function __fnInfo(f)
  local r = { source = "", line = -1, name = "", pointer = tostring(f) }
  if type(__iscclosure) == "function" then
    local ok, isc = pcall(__iscclosure, f)
    if ok then r.isC = isc == true end
  end
  if type(__getinfo) == "function" then
    local ok, info = pcall(__getinfo, f, "nSl")
    if ok and type(info) == "table" then
      r.source = info.source or info.short_src or ""
      r.line = info.linedefined or info.currentline or -1
      r.name = info.name or ""
    else
      local oks, s = pcall(__getinfo, f, "s"); if oks and type(s) ~= "table" and s ~= nil then r.source = tostring(s) end
      local okl, l = pcall(__getinfo, f, "l"); if okl and type(l) == "number" then r.line = l end
      local okn, n = pcall(__getinfo, f, "n"); if okn and n ~= nil and type(n) ~= "table" then r.name = tostring(n) end
    end
  end
  return r
end

-- Resolve the root expression to an Instance.
local __root
do
  local f, cerr = loadstring("return " .. ${s(e)})
  if not f then return { error = "compile error in root expression: " .. tostring(cerr) } end
  local ok, val = pcall(f)
  if not ok then return { error = "error evaluating root expression: " .. tostring(val) } end
  if typeof(val) ~= "Instance" then
    return { error = "root expression did not resolve to an Instance (got " .. typeof(val) .. ")" }
  end
  __root = val
end

local descendants
do
  local ok, d = pcall(function() return __root:GetDescendants() end)
  if not ok or type(d) ~= "table" then return { error = "failed to enumerate descendants of root" } end
  descendants = d
end

-- (class, slot) pairs to probe per ClassName.
local SLOTS = {
  RemoteFunction = { "OnClientInvoke", "OnServerInvoke" },
  BindableFunction = { "OnInvoke" },
}

local callbacks = {}
local count = 0
local scanned = 0
local truncated = false

for _, inst in ipairs(descendants) do
  scanned = scanned + 1
  if scanned > ${i} then truncated = true; break end

  local className
  do
    local okc, c = pcall(function() return inst.ClassName end)
    if okc then className = c end
  end

  local slots = className and SLOTS[className] or nil
  if slots then
    for _, slot in ipairs(slots) do
      local okcb, cb = pcall(__gcv, inst, slot)
      if okcb and type(cb) == "function" then
        count = count + 1
        callbacks[count] = {
          remote = __fullName(inst),
          class = className,
          slot = slot,
          callback = __fnInfo(cb),
        }
        if count >= ${o} then truncated = true; break end
      end
    end
  end

  if count >= ${o} then break end
end

return {
  count = count,
  scanned = scanned,
  truncated = truncated,
  root = __fullName(__root),
  callbacks = callbacks,
}
`;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:45e3})}}});import{z as dn}from"zod";var Wi=u({name:"block-packets",title:"Block outgoing RakNet packets by criteria",description:"WRITES LIVE GAME STATE \u2014 installs a RakNet send hook that DROPS matching outgoing packets. A packet is blocked when its Size >= minSize (if set) and/or its payload contains containsHex (if set); with neither criterion every outgoing packet is blocked (dangerous). action='start' installs the hook, 'stop' removes it. Requires the `raknet` library. WARNING: blocking outgoing traffic can break the game, freeze replication, or disconnect the client \u2014 use narrow criteria and stop promptly.",category:"Network",mutatesState:!0,input:dn.object({action:dn.enum(["start","stop"]).describe("'start' installs the blocking hook; 'stop' removes it."),minSize:dn.number().int().describe("Block packets whose Size is at least this many bytes. Omit to not filter by size.").optional(),containsHex:dn.string().describe("Block packets whose payload contains this hex byte sequence (e.g. '1a2b'). Omit to not filter by content.").optional(),threadContext:dn.number().int().optional()}),async execute({action:e,minSize:t,containsHex:n,threadContext:r},a){let o=t===void 0?"nil":String(Math.floor(t)),i=n===void 0?"nil":s(n.replace(/\s+/g,"").toLowerCase()),l=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available; cannot maintain the packet blocker." } end
local __g = getgenv()
if type(raknet) ~= "table" or type(raknet.add_send_hook) ~= "function" then
  return { error = "raknet.add_send_hook is not available in this executor." }
end

if "${e}" == "start" then
  if __g.__mcp_packetBlock and __g.__mcp_packetBlock.active then
    return { started = false, alreadyActive = true }
  end
  local state = { active = true, minSize = ${o}, contains = ${i}, blocked = 0 }
  local function toHex(s)
    local hex = {}
    for i = 1, #s do hex[i] = string.format("%02x", string.byte(s, i)) end
    return table.concat(hex)
  end
  local function hook(packet)
    pcall(function()
      local s = __g.__mcp_packetBlock
      if not (s and s.active) then return end
      local match = true
      if s.minSize ~= nil then
        if not (packet.Size and packet.Size >= s.minSize) then match = false end
      end
      if match and s.contains ~= nil then
        local okStr, str = pcall(function() return packet.AsString end)
        if okStr and type(str) == "string" then
          if not string.find(toHex(str), s.contains, 1, true) then match = false end
        else
          match = false
        end
      end
      if match then
        s.blocked = s.blocked + 1
        packet:Block()
      end
    end)
  end
  state.hook = hook
  __g.__mcp_packetBlock = state
  local ok, err = pcall(raknet.add_send_hook, hook)
  if not ok then __g.__mcp_packetBlock = nil; return { error = "add_send_hook failed: " .. tostring(err) } end
  return { started = true, minSize = ${o}, contains = ${i} }
else
  local s = __g.__mcp_packetBlock
  if not s then return { stopped = true, wasActive = false } end
  local removed = false
  if type(raknet.remove_send_hook) == "function" and s.hook then
    removed = pcall(raknet.remove_send_hook, s.hook)
  end
  s.active = false
  local blocked = s.blocked or 0
  __g.__mcp_packetBlock = nil
  return { stopped = true, hookRemoved = removed, totalBlocked = blocked }
end
`;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:2e4})}}});import{z as Me}from"zod";var Vi=100*1024,Bi=u({name:"http-request",title:"Make an outbound HTTP request from the client (sUNC request)",description:"SENDS A REAL OUTBOUND HTTP REQUEST from the Roblox client via the executor's request({ Url, Method, Headers, Body }) (falling back to http_request, then syn.request). Unlike Roblox's HttpService this can hit arbitrary hosts and set custom headers. The response body is capped at ~100 KB. Requires one of these functions to be available. The call is type-guarded and pcall-wrapped: if none is present you get { error = 'request is not available in this executor.' }, and a transport failure returns { error }. Returns { statusCode, success, headers, body, statusMessage } or { error }.",category:"Network",mutatesState:!0,input:Me.object({url:Me.string().describe("The absolute request URL, e.g. 'https://api.example.com/v1/thing'."),method:Me.enum(["GET","POST","PUT","DELETE","PATCH","HEAD"]).optional().default("GET").describe("HTTP method (default GET)."),headers:Me.record(Me.string(),Me.string()).optional().describe("Optional request headers as a string->string map."),body:Me.string().optional().describe("Optional request body (for POST/PUT/PATCH)."),threadContext:Me.number().int().optional(),timeoutMs:Me.number().int().optional()}),async execute({url:e,method:t,headers:n,body:r,threadContext:a,timeoutMs:o},i){let l=n?Object.entries(n).map(([f,h])=>`  [${s(f)}] = ${s(h)},`).join(`
`):"",c=r===void 0?"":`  Body = ${s(r)},`,d=`
local fn = nil
if type(request) == "function" then
  fn = request
elseif type(http_request) == "function" then
  fn = http_request
elseif type(syn) == "table" and type(syn.request) == "function" then
  fn = syn.request
end
if type(fn) ~= "function" then
  return { error = "request is not available in this executor." }
end

local opts = {
  Url = ${s(e)},
  Method = ${s(t)},
  Headers = {
${l}
  },
${c}
}

local ok, response = pcall(fn, opts)
if not ok then return { error = "request failed: " .. tostring(response) } end
if type(response) ~= "table" then return { error = "request returned a non-table response." } end

local body = response.Body
if type(body) == "string" and #body > ${Vi} then
  body = body:sub(1, ${Vi})
end

return {
  statusCode = response.StatusCode,
  success = response.Success,
  headers = response.Headers,
  body = body,
  statusMessage = response.StatusMessage,
}
`;return{data:await i.runLuau(d,{threadContext:a,timeoutMs:o??3e4})}}});import{z as pn}from"zod";var zi=u({name:"packet-spy",title:"Spy on outgoing RakNet packets",description:"WRITES LIVE GAME STATE \u2014 installs a RakNet send hook. Captures every OUTGOING low-level packet the client sends (RakNet only exposes outgoing traffic). For each packet it records Size, Priority, Reliability, OrderingChannel, and a hex preview of the payload. action='start' installs the hook (idempotent), 'fetch' returns the captured packets newest-first without stopping, 'stop' removes the hook and clears the buffer. Requires the `raknet` library. WARNING: packet-level interception is risky and can disconnect or flag the client \u2014 stop when done.",category:"Network",mutatesState:!0,input:pn.object({action:pn.enum(["start","fetch","stop"]).describe("'start' installs the send hook; 'fetch' returns captured packets; 'stop' removes the hook."),limit:pn.number().int().describe("Max packets to return on fetch (default 100, newest-first).").optional().default(100),previewBytes:pn.number().int().describe("How many payload bytes to include as a hex preview per packet (default 64).").optional().default(64),threadContext:pn.number().int().optional()}),async execute({action:e,limit:t,previewBytes:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),500),i=Math.min(Math.max(Math.floor(n),0),256),l=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available; cannot maintain the packet spy." } end
local __g = getgenv()
if type(raknet) ~= "table" or type(raknet.add_send_hook) ~= "function" then
  return { error = "raknet.add_send_hook is not available in this executor." }
end

local ACTION = "${e}"

if ACTION == "start" then
  if __g.__mcp_packetSpy and __g.__mcp_packetSpy.active then
    return { started = false, alreadyActive = true, captured = #(__g.__mcp_packetSpy.logs or {}) }
  end
  local state = { active = true, logs = {}, max = 500, preview = ${i} }
  local function hook(packet)
    pcall(function()
      local s = __g.__mcp_packetSpy
      if not (s and s.active) then return end
      local rec = {
        size = packet.Size,
        priority = packet.Priority,
        reliability = packet.Reliability,
        orderingChannel = packet.OrderingChannel,
      }
      local okStr, str = pcall(function() return packet.AsString end)
      if okStr and type(str) == "string" then
        local n = math.min(#str, s.preview)
        local hex = {}
        for i = 1, n do hex[i] = string.format("%02x", string.byte(str, i)) end
        rec.preview = table.concat(hex)
      end
      local logs = s.logs
      logs[#logs + 1] = rec
      if #logs > s.max then table.remove(logs, 1) end
    end)
  end
  state.hook = hook
  __g.__mcp_packetSpy = state
  local ok, err = pcall(raknet.add_send_hook, hook)
  if not ok then __g.__mcp_packetSpy = nil; return { error = "add_send_hook failed: " .. tostring(err) } end
  return { started = true }
elseif ACTION == "fetch" then
  local s = __g.__mcp_packetSpy
  if not (s and s.logs) then return { error = "Packet spy is not active. Start it first.", active = false } end
  local logs, out = s.logs, {}
  for i = #logs, math.max(1, #logs - ${o} + 1), -1 do out[#out + 1] = logs[i] end
  return { active = s.active == true, captured = #logs, packets = out }
else
  local s = __g.__mcp_packetSpy
  if not s then return { stopped = true, wasActive = false } end
  local removed = false
  if type(raknet.remove_send_hook) == "function" and s.hook then
    removed = pcall(raknet.remove_send_hook, s.hook)
  end
  s.active = false
  __g.__mcp_packetSpy = nil
  return { stopped = true, hookRemoved = removed }
end
`;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:2e4})}}});import{z as mt}from"zod";var Ki=u({name:"send-packet",title:"Send a custom RakNet packet",description:"WRITES LIVE GAME STATE \u2014 transmits a raw packet. Sends a custom OUTGOING low-level packet via raknet.send with the given payload (a hex string, converted to a byte array), priority, reliability, and ordering channel. Requires the `raknet` library. WARNING: malformed packets or wrong metadata can disconnect the client or break protocol behavior \u2014 only send payloads you understand.",category:"Network",mutatesState:!0,input:mt.object({dataHex:mt.string().describe("Payload as a hex string (e.g. '01020304' or '01 02 03 04'); whitespace is ignored. Must be an even number of hex digits."),priority:mt.number().int().describe("RakNet send priority (default 0).").optional().default(0),reliability:mt.number().int().describe("RakNet reliability mode (default 0).").optional().default(0),orderingChannel:mt.number().int().describe("Ordering channel for ordered traffic (default 0).").optional().default(0),threadContext:mt.number().int().optional()}),async execute({dataHex:e,priority:t,reliability:n,orderingChannel:r,threadContext:a},o){let i=`
if type(raknet) ~= "table" or type(raknet.send) ~= "function" then
  return { error = "raknet.send is not available in this executor." }
end
local hex = string.gsub(${s(e)}, "%s", "")
if #hex == 0 then return { error = "dataHex is empty." } end
if #hex % 2 ~= 0 then return { error = "dataHex must have an even number of hex digits." } end
local bytes = {}
for i = 1, #hex, 2 do
  local b = tonumber(hex:sub(i, i + 1), 16)
  if not b then return { error = "invalid hex near position " .. i } end
  bytes[#bytes + 1] = b
end
local ok, err = pcall(raknet.send, bytes, ${Math.floor(t)}, ${Math.floor(n)}, ${Math.floor(r)})
if not ok then return { error = "raknet.send failed: " .. tostring(err) } end
return { sent = true, byteCount = #bytes }
`;return{data:await o.runLuau(i,{threadContext:a,timeoutMs:2e4})}}});import{z as ia}from"zod";var Hi=u({name:"ws-close",title:"ws:Close \u2014 close a WebSocket and free its slot",description:"WRITES LIVE GAME STATE \u2014 closes a WebSocket previously opened with ws-connect, addressed by its registry id. Calls socket:Close() (pcall-wrapped), marks the entry closed, and removes it from the getgenv registry so the id no longer appears in ws-list. Requires getgenv and the entry from ws-connect \u2014 guarded, returning { error } when the id is unknown. Returns { id, closed = true } or { error }.",category:"Network",mutatesState:!0,input:ia.object({id:ia.number().int().describe("The WebSocket registry id returned by ws-connect."),threadContext:ia.number().int().optional()}),async execute({id:e,threadContext:t},n){let r=`
if type(getgenv) ~= "function" then
  return { error = "getgenv is not available; cannot access the WebSocket registry." }
end
local __g = getgenv()
if type(__g.__mcp_ws) ~= "table" then
  return { error = "No WebSocket registry exists. Open a socket with ws-connect first." }
end

local id = ${Math.floor(e)}
local entry = __g.__mcp_ws[id]
if not entry then
  return { error = "No WebSocket with id " .. tostring(id) .. "." }
end

pcall(function()
  if entry.socket and type(entry.socket.Close) == "function" then
    entry.socket:Close()
  end
end)
entry.open = false
__g.__mcp_ws[id] = nil
return { id = id, closed = true }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as sa}from"zod";var Xi=u({name:"ws-connect",title:"WebSocket.connect \u2014 open a live WebSocket",description:"WRITES LIVE GAME STATE \u2014 opens a real outbound WebSocket from the client via WebSocket.connect(url). The live socket is parked in a getgenv registry keyed by an integer id (returned as `id`); use that id with ws-send, ws-receive, ws-close, and ws-list. On connect, ws.OnMessage is wired into a capped (200-frame) ring buffer and ws.OnClose flips the entry's open flag to false, so inbound frames accumulate server-side until you fetch them. Requires the WebSocket library (type(WebSocket)=='table' with WebSocket.connect) \u2014 both are type-guarded and the connect is pcall-wrapped, returning { error } when missing or on failure. Returns { id, url } or { error }.",category:"Network",mutatesState:!0,input:sa.object({url:sa.string().describe("The WebSocket URL to connect to, e.g. 'ws://127.0.0.1:8080' or 'wss://example.com/socket'."),threadContext:sa.number().int().optional()}),async execute({url:e,threadContext:t},n){let r=`
if type(getgenv) ~= "function" then
  return { error = "getgenv is not available; cannot maintain the WebSocket registry." }
end
if type(WebSocket) ~= "table" or type(WebSocket.connect) ~= "function" then
  return { error = "WebSocket.connect is not available in this executor." }
end

local __g = getgenv()
if type(__g.__mcp_ws) ~= "table" then __g.__mcp_ws = {} end
if type(__g.__mcp_ws_counter) ~= "number" then __g.__mcp_ws_counter = 0 end

local ok, socket = pcall(WebSocket.connect, ${s(e)})
if not ok or socket == nil then
  return { error = "WebSocket.connect failed: " .. tostring(socket) }
end

__g.__mcp_ws_counter = __g.__mcp_ws_counter + 1
local id = __g.__mcp_ws_counter
local entry = { socket = socket, url = ${s(e)}, messages = {}, open = true, max = 200 }
__g.__mcp_ws[id] = entry

pcall(function()
  socket.OnMessage:Connect(function(message)
    local e = __g.__mcp_ws[id]
    if not e then return end
    local ring = e.messages
    ring[#ring + 1] = { text = tostring(message), t = os.clock() }
    if #ring > e.max then table.remove(ring, 1) end
  end)
end)
pcall(function()
  socket.OnClose:Connect(function()
    local e = __g.__mcp_ws[id]
    if e then e.open = false end
  end)
end)

return { id = id, url = ${s(e)} }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as Yi}from"zod";var Zi=u({name:"ws-list",title:"List open WebSockets",description:"List every WebSocket currently parked in the getgenv registry by ws-connect. For each entry it reports { id, url, open, messageCount } so you can see which sockets are still live and how many inbound frames are buffered. Read-only. Requires getgenv \u2014 guarded; when no registry exists it simply returns an empty list. Returns { count, sockets } or { error }.",category:"Network",input:Yi.object({threadContext:Yi.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
if type(getgenv) ~= "function" then
  return { error = "getgenv is not available; cannot access the WebSocket registry." }
end
local __g = getgenv()
local reg = __g.__mcp_ws
if type(reg) ~= "table" then
  return { count = 0, sockets = {} }
end

local out = {}
for id, entry in pairs(reg) do
  out[#out + 1] = {
    id = id,
    url = entry.url,
    open = entry.open == true,
    messageCount = #(entry.messages or {}),
  }
end
table.sort(out, function(a, b) return a.id < b.id end)
return { count = #out, sockets = out }
`,{threadContext:e,timeoutMs:2e4})}}});import{z as fn}from"zod";var Qi=u({name:"ws-receive",title:"Read buffered WebSocket frames",description:"Read the inbound frames buffered for a WebSocket opened with ws-connect, addressed by its registry id. Returns the captured { text, t } records newest-first, capped at `limit`, plus whether the socket is still open and the total buffered count. With clear=true the ring is emptied after the snapshot is taken, so the next call only sees newer frames. Requires getgenv and the entry from ws-connect \u2014 guarded, returning { error } when the id is unknown. Returns { id, open, messageCount, messages } or { error }.",category:"Network",input:fn.object({id:fn.number().int().describe("The WebSocket registry id returned by ws-connect."),limit:fn.number().int().describe("Max frames to return, newest-first (default 100).").optional().default(100),clear:fn.boolean().describe("When true, empty the buffered frames after returning them (default false).").optional().default(!1),threadContext:fn.number().int().optional()}),async execute({id:e,limit:t,clear:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),200),i=`
if type(getgenv) ~= "function" then
  return { error = "getgenv is not available; cannot access the WebSocket registry." }
end
local __g = getgenv()
if type(__g.__mcp_ws) ~= "table" then
  return { error = "No WebSocket registry exists. Open a socket with ws-connect first." }
end

local id = ${Math.floor(e)}
local entry = __g.__mcp_ws[id]
if not entry then
  return { error = "No WebSocket with id " .. tostring(id) .. ". Open one with ws-connect first." }
end

local ring = entry.messages or {}
local total = #ring
local out = {}
for i = total, math.max(1, total - ${o} + 1), -1 do
  out[#out + 1] = ring[i]
end
if ${n?"true":"false"} then
  entry.messages = {}
end
return { id = id, open = entry.open == true, messageCount = total, messages = out }
`;return{data:await a.runLuau(i,{threadContext:r,timeoutMs:2e4})}}});import{z as mr}from"zod";var Ji=u({name:"ws-send",title:"ws:Send \u2014 send a frame over an open WebSocket",description:"WRITES LIVE GAME STATE \u2014 sends a text frame over a WebSocket previously opened with ws-connect, addressed by its registry id. Looks up getgenv().__mcp_ws[id], verifies the socket is still open, and calls socket:Send(message). Requires getgenv and the live socket from ws-connect \u2014 both are guarded and the send is pcall-wrapped, returning { error } when the id is unknown, the socket is closed, or Send fails. Returns { id, sent = true } or { error }.",category:"Network",mutatesState:!0,input:mr.object({id:mr.number().int().describe("The WebSocket registry id returned by ws-connect."),message:mr.string().describe("The text frame to send over the socket."),threadContext:mr.number().int().optional()}),async execute({id:e,message:t,threadContext:n},r){let a=`
if type(getgenv) ~= "function" then
  return { error = "getgenv is not available; cannot access the WebSocket registry." }
end
local __g = getgenv()
if type(__g.__mcp_ws) ~= "table" then
  return { error = "No WebSocket registry exists. Open a socket with ws-connect first." }
end

local id = ${Math.floor(e)}
local entry = __g.__mcp_ws[id]
if not entry then
  return { error = "No WebSocket with id " .. tostring(id) .. ". Open one with ws-connect first." }
end
if not entry.open then
  return { error = "WebSocket " .. tostring(id) .. " is closed." }
end
if type(entry.socket) ~= "userdata" and type(entry.socket) ~= "table" then
  return { error = "WebSocket " .. tostring(id) .. " has no live socket." }
end

local ok, err = pcall(function() entry.socket:Send(${s(t)}) end)
if not ok then
  return { error = "ws:Send failed: " .. tostring(err) }
end
return { id = id, sent = true }
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}});import{z as D}from"zod";var ce="Metatables & Closures",Qe=D.object({functionPath:D.string().min(1).describe("Luau expression resolving to the target function."),threadContext:D.number().int().optional()}),la=Qe.extend({key:D.string().max(96).optional().default("").describe("Optional stable key for getgenv().__mcp_closure_refs. Generated when omitted.")}),ca=`
local function __closureRegistry()
  if type(getgenv) ~= "function" then
    return nil, "getgenv is not available; closure references cannot be retained."
  end
  local ok, genv = pcall(getgenv)
  if not ok or type(genv) ~= "table" then return nil, "getgenv failed." end
  if type(genv.__mcp_closure_refs) ~= "table" then genv.__mcp_closure_refs = {} end
  return genv.__mcp_closure_refs, nil
end

local function __storeClosure(fn, requestedKey)
  if type(fn) ~= "function" then return nil, "value to store is not a function" end
  local registry, err = __closureRegistry()
  if err then return nil, err end
  local key = tostring(requestedKey or "")
  if key == "" then
    local seed = tostring(fn):gsub("[^%w]+", "-")
    key = "closure-" .. seed
    local suffix = 1
    local base = key
    while registry[key] ~= nil and registry[key] ~= fn do
      suffix = suffix + 1
      key = base .. "-" .. tostring(suffix)
    end
  elseif registry[key] ~= nil and registry[key] ~= fn then
    return nil, "closure reference key already exists: " .. key
  end
  registry[key] = fn
  return {
    Key = key,
    Reference = "getgenv().__mcp_closure_refs[" .. string.format("%q", key) .. "]",
    Info = __fnInfo(fn),
  }, nil
end
`;function mn(e){return{data:{error:`Refusing to ${e} (may mutate live behavior); pass confirm=true.`},isError:!0}}var ru=u({name:"closure-capabilities",title:"Probe the complete closure/reflection primitive surface",description:"Read-only capability matrix for the official Volt closure library plus the MCP's useful debug closure operations. Reports the selected alias for every primitive without calling it.",category:ce,input:D.object({threadContext:D.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
local function alias(...)
  local names = {...}
  local hosts = {}
  if type(getgenv) == "function" then local ok, value = pcall(getgenv); if ok and type(value) == "table" then hosts[#hosts + 1] = value end end
  if type(getfenv) == "function" then local ok, value = pcall(getfenv, 0); if ok and type(value) == "table" then hosts[#hosts + 1] = value end end
  if type(_G) == "table" then hosts[#hosts + 1] = _G end
  for _, name in ipairs(names) do
    for _, host in ipairs(hosts) do
      local ok, value = pcall(function() return host[name] end)
      if ok and type(value) == "function" then return true, name end
    end
    if type(loadstring) == "function" then
      local okLoader, loader = pcall(loadstring, "return " .. name)
      if okLoader and type(loader) == "function" then
        local okValue, value = pcall(loader)
        if okValue and type(value) == "function" then return true, name end
      end
    end
  end
  return false, nil
end
local functions = {}
local function add(name, ...)
  local ok, selected = alias(...)
  functions[name] = { available = ok, selectedAlias = selected }
end
add("checkcaller", "checkcaller")
add("clonefunction", "clonefunction", "clonefunc")
add("getfunctionhash", "getfunctionhash")
add("hookfunction", "hookfunction")
add("hookmetamethod", "hookmetamethod")
add("iscclosure", "iscclosure")
add("isexecutorclosure", "isexecutorclosure", "checkclosure", "isourclosure")
add("isfunctionhooked", "isfunctionhooked")
add("islclosure", "islclosure")
add("isnewcclosure", "isnewcclosure", "iscustomcclosure")
add("newcclosure", "newcclosure")
add("newlclosure", "newlclosure")
add("restorefunction", "restorefunction", "restorefunc")
add("setstackhidden", "setstackhidden")
add("getconstants", "getconstants", "debug.getconstants")
add("getupvalues", "getupvalues", "debug.getupvalues")
add("getprotos", "getprotos", "debug.getprotos")
add("getinfo", "getinfo", "debug.getinfo")
add("setconstant", "setconstant", "debug.setconstant")
add("setupvalue", "setupvalue", "debug.setupvalue")
add("getfenv", "getfenv")
add("setfenv", "setfenv")
local count, availableCount = 0, 0
for _, entry in pairs(functions) do
  count = count + 1
  if entry.available then availableCount = availableCount + 1 end
end
return { ok = true, total = count, availableCount = availableCount, missingCount = count - availableCount, functions = functions }
`,{threadContext:e,timeoutMs:15e3})}}}),au=u({name:"check-caller",title:"Check whether the current call originates from the executor",description:"Call Volt checkcaller in the active executor thread. This normally reports true for a direct MCP call and is most useful as a capability/behavior probe before installing a hook.",category:ce,input:D.object({threadContext:D.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
if type(checkcaller) ~= "function" then return { error = "checkcaller is not available in this executor." } end
local ok, value = pcall(checkcaller)
if not ok then return { error = "checkcaller failed: " .. tostring(value) } end
return { ok = true, calledByExecutor = value == true }
`,{threadContext:e,timeoutMs:1e4})}}}),ou=u({name:"clone-function",title:"Clone a function and retain a reusable closure reference",description:"Clone a function with clonefunction/clonefunc. The function result is retained in getgenv().__mcp_closure_refs and returned as a reusable Reference expression because functions cannot cross JSON.",category:ce,input:la,async execute({functionPath:e,key:t,threadContext:n},r){let a=`
${k}
${ca}
local clone = (type(clonefunction) == "function" and clonefunction) or (type(clonefunc) == "function" and clonefunc)
if type(clone) ~= "function" then return { error = "clonefunction/clonefunc is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local ok, cloned = pcall(clone, fn)
if not ok or type(cloned) ~= "function" then return { error = "clonefunction failed: " .. tostring(cloned) } end
local stored, storeErr = __storeClosure(cloned, ${s(t)})
if storeErr then return { error = storeErr } end
stored.Target = ${s(e)}
stored.SharedUpvalues = true
return stored
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}}),iu=u({name:"get-function-hash",title:"Hash a Luau closure's bytecode",description:"Resolve a function and return getfunctionhash(fn), useful for stable comparison and change detection. Volt only supports bytecode hashing for Luau closures; C closures return a clean executor error.",category:ce,input:Qe,async execute({functionPath:e,threadContext:t},n){let r=`
${k}
if type(getfunctionhash) ~= "function" then return { error = "getfunctionhash is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local ok, hash = pcall(getfunctionhash, fn)
if not ok then return { error = "getfunctionhash failed: " .. tostring(hash) } end
return { ok = true, Target = ${s(e)}, Hash = tostring(hash), Info = __fnInfo(fn) }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:15e3})}}});function hn(e){return u({name:e.name,title:e.title,description:e.description,category:ce,input:Qe,async execute({functionPath:t,threadContext:n},r){let a=`
${k}
local predicate = ${e.predicateExpression}
if type(predicate) ~= "function" then return { error = ${s(e.unavailable)} } end
local fn, err = __evalFn(${s(t)})
if err then return { error = err } end
local ok, result = pcall(predicate, fn)
if not ok then return { error = ${s(e.predicateLabel+" failed: ")} .. tostring(result) } end
return { ok = true, Target = ${s(t)}, Result = result == true, Predicate = ${s(e.predicateLabel)}, Info = __fnInfo(fn) }
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:1e4})}}})}var su=hn({name:"is-c-closure",title:"Check whether a function is a native or wrapped C closure",description:"Resolve a function and call iscclosure with guarded metadata.",predicateExpression:"iscclosure",unavailable:"iscclosure is not available in this executor.",predicateLabel:"iscclosure"}),lu=hn({name:"is-l-closure",title:"Check whether a function is a Luau closure",description:"Resolve a function and call islclosure with guarded metadata.",predicateExpression:"islclosure",unavailable:"islclosure is not available in this executor.",predicateLabel:"islclosure"}),cu=hn({name:"is-executor-closure",title:"Check whether a closure originates from the executor",description:"Call isexecutorclosure with checkclosure/isourclosure aliases to distinguish executor-created closures from game closures.",predicateExpression:'(type(isexecutorclosure) == "function" and isexecutorclosure) or (type(checkclosure) == "function" and checkclosure) or (type(isourclosure) == "function" and isourclosure)',unavailable:"isexecutorclosure/checkclosure/isourclosure is not available in this executor.",predicateLabel:"isexecutorclosure"}),uu=hn({name:"is-function-hooked",title:"Check whether a function currently has an executor hook",description:"Resolve a function and call isfunctionhooked before hooking/restoring it.",predicateExpression:"isfunctionhooked",unavailable:"isfunctionhooked is not available in this executor.",predicateLabel:"isfunctionhooked"}),du=hn({name:"is-new-c-closure",title:"Distinguish newcclosure wrappers from native C closures",description:"Call isnewcclosure with the iscustomcclosure alias when available.",predicateExpression:'(type(isnewcclosure) == "function" and isnewcclosure) or (type(iscustomcclosure) == "function" and iscustomcclosure)',unavailable:"isnewcclosure/iscustomcclosure is not available in this executor.",predicateLabel:"isnewcclosure"}),pu=u({name:"new-c-closure",title:"Wrap a Luau function as a C closure and retain it",description:"Call newcclosure(function, debugName?) and store the wrapper under getgenv().__mcp_closure_refs, returning a reusable Reference expression and closure metadata.",category:ce,input:la.extend({debugName:D.string().max(128).optional().default("")}),async execute({functionPath:e,key:t,debugName:n,threadContext:r},a){let o=`
${k}
${ca}
if type(newcclosure) ~= "function" then return { error = "newcclosure is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local debugName = ${s(n)}
local ok, wrapped
if debugName ~= "" then ok, wrapped = pcall(newcclosure, fn, debugName) else ok, wrapped = pcall(newcclosure, fn) end
if not ok or type(wrapped) ~= "function" then return { error = "newcclosure failed: " .. tostring(wrapped) } end
local stored, storeErr = __storeClosure(wrapped, ${s(t)})
if storeErr then return { error = storeErr } end
stored.Target = ${s(e)}
stored.Wrapper = "C"
stored.DebugName = debugName ~= "" and debugName or nil
return stored
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}}),fu=u({name:"new-l-closure",title:"Wrap a C closure as a Luau closure and retain it",description:"Call newlclosure(function) and store the wrapper under getgenv().__mcp_closure_refs, returning a reusable Reference expression and closure metadata.",category:ce,input:la,async execute({functionPath:e,key:t,threadContext:n},r){let a=`
${k}
${ca}
if type(newlclosure) ~= "function" then return { error = "newlclosure is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local ok, wrapped = pcall(newlclosure, fn)
if not ok or type(wrapped) ~= "function" then return { error = "newlclosure failed: " .. tostring(wrapped) } end
local stored, storeErr = __storeClosure(wrapped, ${s(t)})
if storeErr then return { error = storeErr } end
stored.Target = ${s(e)}
stored.Wrapper = "Luau"
return stored
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}}),mu=u({name:"restore-function",title:"Restore any currently hooked function",description:"WRITES LIVE GAME STATE. Resolve a target and call restorefunction/restorefunc directly. Unlike restore-hook, this also restores hooks not installed through the MCP registry. Requires confirm=true.",category:ce,mutatesState:!0,input:Qe.extend({confirm:D.boolean().default(!1)}),async execute({functionPath:e,confirm:t,threadContext:n},r){if(t!==!0)return mn("restore a function");let a=`
${k}
local restore = (type(restorefunction) == "function" and restorefunction) or (type(restorefunc) == "function" and restorefunc)
if type(restore) ~= "function" then return { error = "restorefunction/restorefunc is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local ok, failure = pcall(restore, fn)
if not ok then return { error = "restorefunction failed: " .. tostring(failure) } end
return { ok = true, Restored = ${s(e)}, Info = __fnInfo(fn) }
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:15e3})}}}),hu=u({name:"set-stack-hidden",title:"Set a closure's stack-trace visibility",description:"WRITES LIVE GAME STATE. Call setstackhidden(function, hidden) to alter runtime stack/debug visibility. This can make diagnostics incomplete, so it is confirmation-gated and should be restored with hidden=false after use.",category:ce,mutatesState:!0,input:Qe.extend({hidden:D.boolean().describe("True hides the function; false restores normal visibility."),confirm:D.boolean().default(!1)}),async execute({functionPath:e,hidden:t,confirm:n,threadContext:r},a){if(n!==!0)return mn("change stack visibility");let o=`
${k}
if type(setstackhidden) ~= "function" then return { error = "setstackhidden is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local ok, failure = pcall(setstackhidden, fn, ${t?"true":"false"})
if not ok then return { error = "setstackhidden failed: " .. tostring(failure) } end
return { ok = true, Target = ${s(e)}, Hidden = ${t?"true":"false"}, Info = __fnInfo(fn) }
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:15e3})}}}),gu=u({name:"invoke-closure",title:"Invoke a closure by reference with typed arguments",description:"WRITES LIVE GAME STATE. Invoke an arbitrary live function expression with up to 24 typed arguments and return up to 20 encoded results. Function calls may have side effects, so confirm=true is mandatory.",category:ce,mutatesState:!0,input:Qe.extend({arguments:D.array(we).max(24).optional().default([]),confirm:D.boolean().default(!1)}),async execute({functionPath:e,arguments:t,confirm:n,threadContext:r},a){if(n!==!0)return mn("invoke a live closure");let o=t.map(te).join(", "),i=`
${k}
${_e}
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local args = { ${o} }
local packed = table.pack(pcall(fn, table.unpack(args, 1, #args)))
if not packed[1] then return { error = "closure invocation failed: " .. tostring(packed[2]) } end
local results = {}
for i = 2, math.min(packed.n, 21) do results[#results + 1] = __encode(packed[i]) end
return { ok = true, Target = ${s(e)}, ResultCount = math.max(0, packed.n - 1), Results = results, Truncated = packed.n > 21 }
`;return{data:await a.runLuau(i,{threadContext:r,timeoutMs:3e4})}}}),bu=u({name:"set-function-env",title:"Replace a closure's environment table",description:"WRITES LIVE GAME STATE. Resolve a function and an environment-table expression, then call setfenv. This changes global lookup behavior for the live closure and requires confirm=true.",category:ce,mutatesState:!0,input:Qe.extend({environmentExpression:D.string().min(1),confirm:D.boolean().default(!1)}),async execute({functionPath:e,environmentExpression:t,confirm:n,threadContext:r},a){if(n!==!0)return mn("replace a function environment");let o=`
${k}
if type(setfenv) ~= "function" then return { error = "setfenv is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end
local env, envErr = __eval(${s(t)})
if envErr then return { error = envErr } end
if type(env) ~= "table" then return { error = "environmentExpression did not resolve to a table." } end
local ok, result = pcall(setfenv, fn, env)
if not ok then return { error = "setfenv failed: " .. tostring(result) } end
return { ok = true, Target = ${s(e)}, Environment = ${s(t)}, Info = __fnInfo(fn) }
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:15e3})}}}),yu=u({name:"list-closure-references",title:"List retained clone/newclosure handles",description:"Read the bounded getgenv().__mcp_closure_refs registry created by clone-function/new-c-closure/new-l-closure and return reusable expressions plus function metadata.",category:ce,input:D.object({limit:D.number().int().min(1).max(200).optional().default(100),threadContext:D.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=`
${k}
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor." } end
local ok, genv = pcall(getgenv)
if not ok or type(genv) ~= "table" then return { error = "getgenv failed." } end
local registry = genv.__mcp_closure_refs
if type(registry) ~= "table" then return { ok = true, Count = 0, References = {} } end
local keys = {}
for key in pairs(registry) do keys[#keys + 1] = tostring(key) end
table.sort(keys)
local out = {}
for i = 1, math.min(#keys, ${e}) do
  local key = keys[i]
  local value = registry[key]
  out[#out + 1] = {
    Key = key,
    Reference = "getgenv().__mcp_closure_refs[" .. string.format("%q", key) .. "]",
    Info = type(value) == "function" and __fnInfo(value) or nil,
    Type = typeof(value),
  }
end
return { ok = true, Count = #keys, Returned = #out, Truncated = #keys > #out, References = out }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:15e3})}}}),vu=u({name:"release-closure-reference",title:"Release a retained closure handle",description:"WRITES LIVE GAME STATE. Remove one key from getgenv().__mcp_closure_refs so cloned/wrapped closures can be garbage-collected. This invalidates its returned Reference and requires confirm=true.",category:ce,mutatesState:!0,input:D.object({key:D.string().min(1).max(96),confirm:D.boolean().default(!1),threadContext:D.number().int().optional()}),async execute({key:e,confirm:t,threadContext:n},r){if(t!==!0)return mn("release a closure reference");let a=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor." } end
local ok, genv = pcall(getgenv)
if not ok or type(genv) ~= "table" then return { error = "getgenv failed." } end
local registry = genv.__mcp_closure_refs
if type(registry) ~= "table" or registry[${s(e)}] == nil then return { error = "closure reference key was not found." } end
registry[${s(e)}] = nil
return { ok = true, Released = ${s(e)} }
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:1e4})}}}),H=[ru,au,ou,iu,su,lu,cu,uu,du,pu,fu,mu,hu,gu,bu,yu,vu];import{z as ua}from"zod";var es=u({name:"get-closure-constants",title:"Read a closure's constant pool",description:"Resolve a Luau expression to a function and dump its constant pool via getconstants. Constants are the literal values the bytecode references \u2014 strings, numbers, table keys, global names, and embedded function/method names \u2014 so they are the fastest way to fingerprint what a closure does (e.g. spotting a 'FireServer' literal, a remote name, a damage value, or a URL) without reading its source. This is the by-reference companion to the GC-wide scanners (find-functions-by-constant / find-constants-xref): use it once you already hold the function (a remote handler, a metamethod, getsenv(script).fn, etc.). Each entry reports its 1-based Index, Luau Type, and an encoded Value. Requires the executor's getconstants (debug.getconstants); if unavailable a clean { error } is returned. Returns { Target, Info, Constants:[{Index,Type,Value}], Count } or { error }.",category:"Metatables & Closures",input:ua.object({functionPath:ua.string().describe("Luau expression resolving to a function whose constants you want, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).update', 'getrawmetatable(game).__namecall', or 'getconnections(game.ReplicatedStorage.Remote.OnClientEvent)[1].Function'. Evaluated as `return <functionPath>`."),threadContext:ua.number().int().optional()}),async execute({functionPath:e,threadContext:t},n){let r=`
${k}
if type(__getconstants) ~= "function" then return { error = "getconstants is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end

local ok, c = pcall(__getconstants, fn)
if not ok then return { error = "getconstants failed: " .. tostring(c) } end
if type(c) ~= "table" then return { error = "getconstants did not return a table (got " .. typeof(c) .. ")." } end

local list = {}
for i, v in ipairs(c) do
  list[i] = { Index = i, Type = typeof(v), Value = __encVal(v) }
end

return {
  Target = ${s(e)},
  Info = __fnInfo(fn),
  Constants = list,
  Count = #list,
}
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as da}from"zod";var ts=u({name:"get-closure-protos",title:"List a closure's nested function prototypes",description:"Resolve a Luau expression to a function and enumerate its nested prototypes (protos) via getprotos. Protos are the inner functions defined inside a closure \u2014 closures it creates, callbacks it registers, helper functions in its body. Walking protos lets you drill into a top-level script function to reach the exact inner handler you care about (e.g. an anonymous OnClientEvent callback) without scanning the whole GC, and to map a script's internal call structure. For each proto this returns the full __fnInfo (IsLua/IsC, Name, Source, ShortSource, LineDefined, NumParams, IsVararg, NumUpvalues, Pointer) so you can immediately feed a Pointer/path back into the other closure tools. Requires the executor's getprotos (debug.getprotos); if unavailable a clean { error } is returned. Returns { Target, Info, Protos:[__fnInfo...], Count } or { error }.",category:"Metatables & Closures",input:da.object({functionPath:da.string().describe("Luau expression resolving to a function whose nested prototypes you want, e.g. 'getscriptclosure(game.Players.LocalPlayer.PlayerScripts.Main)', 'getsenv(script).init', or 'getrawmetatable(game).__namecall'. Evaluated as `return <functionPath>`."),threadContext:da.number().int().optional()}),async execute({functionPath:e,threadContext:t},n){let r=`
${k}
if type(__getprotos) ~= "function" then return { error = "getprotos is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end

local ok, p = pcall(__getprotos, fn)
if not ok then return { error = "getprotos failed: " .. tostring(p) } end
if type(p) ~= "table" then return { error = "getprotos did not return a table (got " .. typeof(p) .. ")." } end

local list = {}
for i, child in ipairs(p) do
  list[i] = (type(child) == "function") and __fnInfo(child) or { Index = i, Type = typeof(child), Value = __encVal(child) }
end

return {
  Target = ${s(e)},
  Info = __fnInfo(fn),
  Protos = list,
  Count = #list,
}
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as pa}from"zod";var ns=u({name:"get-closure-upvalues",title:"Read a closure's upvalues (captured variables)",description:"Resolve a Luau expression to a function and dump its upvalues via getupvalues. Upvalues are the variables a closure captured from its enclosing scope \u2014 the live state a function carries with it (config tables, cached remotes, counters, references to other functions, flags). Inspecting them reveals hidden state that source code alone does not show, which is invaluable when reverse-engineering a handler or locating a kill-switch/flag to flip. This is the by-reference companion to find-upvalue-xref. Each entry reports its 1-based Index, Luau Type, and an encoded Value; the same Index is what set-closure-upvalue mutates. Requires the executor's getupvalues (debug.getupvalues); if unavailable a clean { error } is returned. Returns { Target, Info, Upvalues:[{Index,Type,Value}], Count } or { error }.",category:"Metatables & Closures",input:pa.object({functionPath:pa.string().describe("Luau expression resolving to a function whose upvalues you want, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).step', 'getrawmetatable(game).__index', or 'getconnections(workspace.Part.Touched)[1].Function'. Evaluated as `return <functionPath>`. Captured variables are editable by Index via set-closure-upvalue."),threadContext:pa.number().int().optional()}),async execute({functionPath:e,threadContext:t},n){let r=`
${k}
if type(__getupvalues) ~= "function" then return { error = "getupvalues is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end

local ok, u = pcall(__getupvalues, fn)
if not ok then return { error = "getupvalues failed: " .. tostring(u) } end
if type(u) ~= "table" then return { error = "getupvalues did not return a table (got " .. typeof(u) .. ")." } end

local list = {}
for i, v in ipairs(u) do
  list[i] = { Index = i, Type = typeof(v), Value = __encVal(v) }
end

return {
  Target = ${s(e)},
  Info = __fnInfo(fn),
  Upvalues = list,
  Count = #list,
}
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as gn}from"zod";var rs=u({name:"get-function-env",title:"Dump a function's environment (getfenv)",description:"Resolve a Luau expression to a function and dump its function environment table via getfenv. This is the _ENV the function reads its globals from: the global table the closure sees (often the script's environment, or a sandboxed proxy). Use it to learn what globals a handler can reach, to spot a sandbox/proxy environment, or to discover sibling functions you can then inspect or hook by reference. Read-only. Requires getfenv. Returns { Target, KeyCount, Truncated, Keys } (keysOnly) or { Target, KeyCount, Truncated, Entries } or { error }.",category:"Metatables & Closures",input:gn.object({functionPath:gn.string().describe("Luau expression resolving to a function, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).update', 'getrawmetatable(game).__namecall', or a function found via the gc-scan tools. Evaluated as `return <functionPath>`."),keysOnly:gn.boolean().describe("When true (default) return only the environment key names \u2014 cheap and safe. When false also serialize each value's type and a scalar/string preview via __encVal.").optional().default(!0),maxKeys:gn.number().int().min(1).describe("Maximum number of environment keys/entries to return before truncating (default 200).").optional().default(200),threadContext:gn.number().int().optional()}),async execute({functionPath:e,keysOnly:t,maxKeys:n,threadContext:r},a){let o=`
${k}
if type(getfenv) ~= "function" then return { error = "getfenv is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end

local okEnv, env = pcall(getfenv, fn)
if not okEnv then return { error = "getfenv failed: " .. tostring(env) } end
if type(env) ~= "table" then return { error = "getfenv did not return an environment table (got " .. typeof(env) .. ")." } end

local cap = ${n}
local count = 0
local kept = 0
local keysOnly = ${t?"true":"false"}
local keys = {}
local entries = {}

pcall(function()
  for k, v in pairs(env) do
    count = count + 1
    if kept < cap then
      kept = kept + 1
      if keysOnly then
        keys[#keys + 1] = tostring(k)
      else
        entries[#entries + 1] = { Key = tostring(k), Type = typeof(v), Value = __encVal(v) }
      end
    end
  end
end)

local result = { Target = ${s(e)}, KeyCount = count, Truncated = count > cap }
if keysOnly then result.Keys = keys else result.Entries = entries end
return result
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as hr}from"zod";var as=u({name:"get-metamethod",title:"Read a single metamethod off an object's raw metatable",description:"Resolve a Luau expression to ANY value (table, Instance, userdata, etc.), grab its raw metatable via getrawmetatable (bypassing __metatable locks), and read ONE named metamethod from it (e.g. __index, __namecall, __newindex, __call, __tostring). When the metamethod is a function this deep-dumps it: its info (Lua/C, source, line, params, upvalue count via getinfo) PLUS its constants (getconstants) and upvalues (getupvalues). This is the targeted counterpart to get-metatable: use it to drill into the exact function Roblox's security layer routes through \u2014 for example reading __namecall off getrawmetatable(game) to find the C closure that backs FireServer/InvokeServer, then inspecting its constants for method-name strings. For non-function metamethods (locked __metatable strings, __index tables, etc.) it returns the encoded value. Requires getrawmetatable; getconstants/getupvalues are best-effort (omitted if the executor lacks them or the metamethod is a C closure). Returns { Target, Method, Type, Function?, Constants?, Upvalues?, Value? } or { error } when there is no metatable, the method is absent, or getrawmetatable is missing.",category:"Metatables & Closures",input:hr.object({objectPath:hr.string().describe("Luau expression resolving to the object whose metatable holds the metamethod, e.g. 'game', 'game.Players.LocalPlayer', 'getrawmetatable(game)', or 'getgenv().SomeProxy'. Evaluated as `return <objectPath>`."),method:hr.string().describe("Name of the metamethod key to read from the raw metatable, e.g. '__index', '__namecall', '__newindex', '__call', '__tostring', '__metatable'. Read off the metatable as mt[method] (does NOT invoke it)."),threadContext:hr.number().int().optional()}),async execute({objectPath:e,method:t,threadContext:n},r){let a=`
${k}
if type(__getrawmt) ~= "function" then return { error = "getrawmetatable is not available in this executor." } end
local obj, err = __eval(${s(e)})
if err then return { error = err } end

local okMt, mt = pcall(__getrawmt, obj)
if not okMt then return { error = "getrawmetatable failed: " .. tostring(mt) } end
if mt == nil then return { error = "object has no metatable: " .. ${s(e)} } end
if type(mt) ~= "table" then return { error = "raw metatable is not a table (got " .. typeof(mt) .. ")" } end

local okV, value = pcall(function() return mt[${s(t)}] end)
if not okV then return { error = "failed to read metamethod " .. ${s(t)} .. ": " .. tostring(value) } end
if value == nil then return { error = "metamethod " .. ${s(t)} .. " is not present on the metatable of " .. ${s(e)} } end

local result = {
  Target = ${s(e)},
  Method = ${s(t)},
  Type = typeof(value),
}

if type(value) == "function" then
  result.Function = __fnInfo(value)

  if type(__getconstants) == "function" then
    local okC, c = pcall(__getconstants, value)
    if okC and type(c) == "table" then
      local list = {}
      for i, v in ipairs(c) do list[i] = { Index = i, Type = typeof(v), Value = __encVal(v) } end
      result.Constants = list
      result.ConstantCount = #c
    end
  end

  if type(__getupvalues) == "function" then
    local okU, u = pcall(__getupvalues, value)
    if okU and type(u) == "table" then
      local list = {}
      for i, v in ipairs(u) do list[i] = { Index = i, Type = typeof(v), Value = __encVal(v) } end
      result.Upvalues = list
      result.UpvalueCount = #u
    end
  end
else
  result.Value = __encVal(value)
end

return result
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}});import{z as fa}from"zod";var os=u({name:"get-metatable",title:"Get an object's raw metatable",description:"Resolve a Luau expression to ANY value (table, Instance, userdata, etc.) and dump its raw metatable via getrawmetatable (bypassing __metatable locks). For each metamethod it reports the key, value type, and \u2014 for function metamethods like __index/__namecall/__newindex \u2014 the connected function's source/line/params. Also reports whether the metatable is read-only and whether getmetatable is locked (a string __metatable). Use this to understand how a table/instance is protected or proxied, or to find the __namecall/__index that game security routes through. Unlike inspect-instance-metatable this works on any value, not just Instances. Requires getrawmetatable; returns { Target, TargetType, HasMetatable, ReadOnly, LockedMetatableValue, Metamethods } or { error }.",category:"Metatables & Closures",input:fa.object({objectPath:fa.string().describe("Luau expression resolving to the object whose metatable you want, e.g. 'game', 'game.Players.LocalPlayer', 'getrawmetatable(game)', or 'getgenv().SomeTable'. Evaluated as `return <objectPath>`."),threadContext:fa.number().int().optional()}),async execute({objectPath:e,threadContext:t},n){let r=`
${k}
if type(__getrawmt) ~= "function" then return { error = "getrawmetatable is not available in this executor." } end
local obj, err = __eval(${s(e)})
if err then return { error = err } end

local okMt, mt = pcall(__getrawmt, obj)
if not okMt then return { error = "getrawmetatable failed: " .. tostring(mt) } end
if mt == nil then return { Target = ${s(e)}, TargetType = typeof(obj), HasMetatable = false } end

local readonly = nil
if type(isreadonly) == "function" then local okR, r = pcall(isreadonly, mt); if okR then readonly = r end end
local locked = nil
if type(getmetatable) == "function" then
  local okG, g = pcall(getmetatable, obj)
  if okG and type(g) == "string" then locked = g end
end

local fields = {}
pcall(function()
  for k, v in pairs(mt) do
    local entry = { Key = tostring(k), Type = typeof(v) }
    if type(v) == "function" then entry.Function = __fnInfo(v) else entry.Value = __encVal(v) end
    fields[#fields + 1] = entry
  end
end)

return {
  Target = ${s(e)},
  TargetType = typeof(obj),
  HasMetatable = true,
  ReadOnly = readonly,
  LockedMetatableValue = locked,
  MetamethodCount = #fields,
  Metamethods = fields,
}
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as ma}from"zod";var is=u({name:"get-script-closure",title:"Get a script's main closure (LocalScript/ModuleScript)",description:"Resolve a Luau expression to a LocalScript or ModuleScript Instance and retrieve its compiled main function via getscriptclosure (falling back to getscriptfunction if the executor exposes that name instead). The returned closure is the script's top-level chunk WITHOUT running it \u2014 so you can statically analyse a script's bytecode (its constants, upvalues, and nested protos) even when it is protected, never executed, or you don't want its side effects. This is the entry point for static RE of a single script: feed the resulting function into get-closure-constants / get-closure-upvalues / get-closure-protos to drill in. Requires the executor's getscriptclosure (or getscriptfunction); if neither exists a clean { error } is returned. Returns { Script, Function:__fnInfo, ConstantCount, UpvalueCount } or { error }.",category:"Metatables & Closures",input:ma.object({scriptPath:ma.string().describe("Luau expression resolving to a LocalScript or ModuleScript Instance, e.g. 'game.Players.LocalPlayer.PlayerScripts.Main', 'game.ReplicatedStorage.Modules.Settings', or 'game:GetService(\"ReplicatedFirst\").Loader'. Evaluated as `return <scriptPath>`; the value must be an Instance."),threadContext:ma.number().int().optional()}),async execute({scriptPath:e,threadContext:t},n){let r=`
${k}
local __getScriptClosure = getscriptclosure or getscriptfunction
if type(__getScriptClosure) ~= "function" then
  return { error = "getscriptclosure (and getscriptfunction) are not available in this executor." }
end

local scr, err = __eval(${s(e)})
if err then return { error = err } end
if typeof(scr) ~= "Instance" then
  return { error = "scriptPath did not resolve to an Instance (got " .. typeof(scr) .. "). Provide a LocalScript or ModuleScript." }
end

local scriptName
local okName, n = pcall(function() return scr:GetFullName() end)
scriptName = okName and n or tostring(scr)

local ok, fn = pcall(__getScriptClosure, scr)
if not ok then return { error = "getscriptclosure failed: " .. tostring(fn) } end
if type(fn) ~= "function" then
  return { error = "getscriptclosure did not return a function (got " .. typeof(fn) .. ") for " .. scriptName .. "." }
end

local result = {
  Script = scriptName,
  ScriptClassName = scr.ClassName,
  Function = __fnInfo(fn),
}

if type(__getconstants) == "function" then
  local okC, c = pcall(__getconstants, fn)
  if okC and type(c) == "table" then result.ConstantCount = #c end
end

if type(__getupvalues) == "function" then
  local okU, u = pcall(__getupvalues, fn)
  if okU and type(u) == "table" then result.UpvalueCount = #u end
end

return result
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as bn}from"zod";var ss=u({name:"get-script-env",title:"Dump a script's environment (getsenv)",description:"Resolve an instance path to a running LocalScript/ModuleScript and dump its script environment table via getsenv. This is the live _ENV of that script: its globals, every top-level local it exposed as a global, and the functions/values it defined. Use it to discover what a script holds (config flags, references, handler functions) so you can then inspect or hook them by reference (e.g. feed getsenv(script).someFunc into inspect-closure or hook-function). The script must be currently running for getsenv to succeed. Requires getsenv. Returns { Script, KeyCount, Truncated, Keys } (keysOnly) or { Script, KeyCount, Truncated, Entries } or { error }.",category:"Metatables & Closures",input:bn.object({scriptPath:bn.string().describe("Luau expression resolving to the LocalScript/ModuleScript instance, e.g. 'game.Players.LocalPlayer.PlayerScripts.Main' or 'game:GetService(\"ReplicatedStorage\").Modules.Net'. Evaluated as `return <scriptPath>`; must yield a running script instance."),keysOnly:bn.boolean().describe("When true (default) return only the environment key names \u2014 cheap and safe. When false also serialize each value's type and a scalar/string preview via __encVal.").optional().default(!0),maxKeys:bn.number().int().min(1).describe("Maximum number of environment keys/entries to return before truncating (default 200).").optional().default(200),threadContext:bn.number().int().optional()}),async execute({scriptPath:e,keysOnly:t,maxKeys:n,threadContext:r},a){let o=`
${k}
if type(getsenv) ~= "function" then return { error = "getsenv is not available in this executor." } end
local script, err = __eval(${s(e)})
if err then return { error = err } end
if typeof(script) ~= "Instance" then return { error = "expression did not resolve to an Instance (got " .. typeof(script) .. ")." } end

local okEnv, env = pcall(getsenv, script)
if not okEnv then return { error = "getsenv failed (is the script running?): " .. tostring(env) } end
if type(env) ~= "table" then return { error = "getsenv did not return an environment table (got " .. typeof(env) .. ")." } end

local cap = ${n}
local count = 0
local kept = 0
local keysOnly = ${t?"true":"false"}
local keys = {}
local entries = {}

pcall(function()
  for k, v in pairs(env) do
    count = count + 1
    if kept < cap then
      kept = kept + 1
      if keysOnly then
        keys[#keys + 1] = tostring(k)
      else
        entries[#entries + 1] = { Key = tostring(k), Type = typeof(v), Value = __encVal(v) }
      end
    end
  end
end)

local result = { Script = ${s(e)}, KeyCount = count, Truncated = count > cap }
if keysOnly then result.Keys = keys else result.Entries = entries end
return result
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as yn}from"zod";var ls=u({name:"hook-function",title:"Hook a live function with a replacement (MUTATES STATE)",description:"WRITES LIVE GAME STATE. DANGER \u2014 MUTATES STATE PERSISTENTLY. Resolve a target function and replace it with your own function via hookfunction. After hooking, every call to the target \u2014 from anywhere in the game \u2014 runs your replacement instead. This is the core primitive for intercepting/altering game behavior: log or rewrite arguments, spoof return values, or no-op a check. The hook is GLOBAL and PERSISTS until undone, so it can easily destabilize the game or trip anticheat. The original function is captured and stored in getgenv().__mcp_hooks keyed by the target expression so you can recover it; you (or your replacement) can call the original, and you can fully undo the hook with restorefunction(target). Requires hookfunction. Pass confirm=true to proceed. Returns { Target, Hooked, OriginalStored } or { error }.",category:"Metatables & Closures",mutatesState:!0,input:yn.object({targetPath:yn.string().describe("Luau expression resolving to the function to hook (the one whose calls you want to intercept), e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).validate' or 'getrawmetatable(game).__namecall'. Evaluated as `return <targetPath>`."),hookFunction:yn.string().describe("Raw Luau expression that evaluates to the REPLACEMENT function. Typically a function literal, e.g. 'function(...) print(\"called\", ...) return getgenv().__mcp_hooks[<target>](...) end' or 'newcclosure(function(...) return true end)'. To call the original from inside your hook, read it from getgenv().__mcp_hooks. Evaluated as `return <hookFunction>` and must resolve to a function."),confirm:yn.boolean().describe("Must be true to actually install the hook (global, persistent mutation). When omitted or false, the tool refuses and changes nothing."),threadContext:yn.number().int().optional()}),async execute({targetPath:e,hookFunction:t,confirm:n,threadContext:r},a){if(n!==!0)return{data:{error:"Refusing to hook function (global persistent mutation of live state); pass confirm=true."},isError:!0};let o=`
${k}
if type(hookfunction) ~= "function" then return { error = "hookfunction is not available in this executor." } end
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor; cannot store the original for restoration." } end

local target, terr = __evalFn(${s(e)})
if terr then return { error = "target: " .. terr } end
local hookFn, herr = __evalFn(${s(t)})
if herr then return { error = "hookFunction: " .. herr } end

local genv = getgenv()
if type(genv.__mcp_hooks) ~= "table" then genv.__mcp_hooks = {} end

local key = ${s(e)}
local stored = false
local ok, original = pcall(hookfunction, target, hookFn)
if not ok then return { error = "hookfunction failed: " .. tostring(original) } end
if type(original) == "function" then
  -- Only store the first original so re-hooking does not clobber the true original.
  if genv.__mcp_hooks[key] == nil then genv.__mcp_hooks[key] = original end
  -- Parallel metadata registry so list-hooks / restore-hook can find + undo it.
  if type(genv.__mcp_hook_meta) ~= "table" then genv.__mcp_hook_meta = {} end
  if genv.__mcp_hook_meta[key] == nil then
    genv.__mcp_hook_meta[key] = { kind = "function", targetExpr = ${s(e)} }
  end
  stored = true
end

return { Target = key, Hooked = true, OriginalStored = stored }
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as ht}from"zod";var cs=u({name:"hook-metamethod",title:"Hook a metamethod on an object (MUTATES live state)",description:"WRITES LIVE GAME STATE. DANGER \u2014 MUTATES STATE PERSISTENTLY. Resolve a Luau expression to an object and replace one of its metamethods (e.g. __namecall, __index, __newindex) with your own function via hookmetamethod. The hook stays active and INTERCEPTS EVERY call routed through that metamethod (for __namecall that is essentially every method call in the game), so a slow, throwing, or mis-behaving hook can hang or crash the client and is a strong anticheat signal. The original metamethod is stored in getgenv().__mcp_hooks under a descriptive key so you can later restore it with restorefunction or by re-hooking the saved original. Your hook function typically wraps the stored original (call it for unhandled cases) and should be a C closure (wrap it in newcclosure) to look native. Requires hookmetamethod. Because it mutates state you MUST pass confirm=true; otherwise the tool refuses and does nothing. Returns { Target, Method, Hooked, OriginalStored } or { error }.",category:"Metatables & Closures",mutatesState:!0,input:ht.object({objectPath:ht.string().describe("Luau expression resolving to the object whose metamethod you want to hook, e.g. 'game', 'game.Players.LocalPlayer', or 'getgenv().SomeTable'. Evaluated as `return <objectPath>`."),method:ht.string().describe("The metamethod name to hook, e.g. '__namecall', '__index', '__newindex'. __namecall is the usual target for intercepting method calls (RemoteEvent:FireServer, etc.)."),hookFunction:ht.string().describe('Raw Luau expression evaluating to the replacement function, MUST resolve to a function. Usually wrapped in newcclosure so it appears as a native C closure, e.g. \'newcclosure(function(self, ...) local m = getnamecallmethod(); if m == "FireServer" then return end; return getgenv().__mcp_hooks["..."](self, ...) end)\'. Evaluated as `return <hookFunction>`.'),confirm:ht.boolean().describe("Safety gate. Must be exactly true to apply the hook. If omitted or false the tool refuses and does nothing, because a persistent metamethod hook intercepts every call through it and can crash the game or trip anticheat."),threadContext:ht.number().int().optional()}),async execute({objectPath:e,method:t,hookFunction:n,confirm:r,threadContext:a},o){if(r!==!0)return{data:{error:"Refusing to hook a live metamethod; pass confirm=true."},isError:!0};let i=`
${k}
if type(hookmetamethod) ~= "function" then return { error = "hookmetamethod is not available in this executor." } end
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor; cannot store the original for restoration." } end

local obj, objErr = __eval(${s(e)})
if objErr then return { error = objErr } end

local hookFn, hookErr = __eval(${s(n)})
if hookErr then return { error = "hookFunction: " .. hookErr } end
if type(hookFn) ~= "function" then return { error = "hookFunction did not resolve to a function (got " .. typeof(hookFn) .. ")." } end

local genv = getgenv()
if type(genv.__mcp_hooks) ~= "table" then genv.__mcp_hooks = {} end
local method = ${s(t)}
local hookKey = "metamethod:" .. tostring(obj) .. ":" .. method

local okHook, original = pcall(hookmetamethod, obj, method, hookFn)
if not okHook then return { error = "hookmetamethod failed: " .. tostring(original) } end

local stored = false
if type(original) == "function" then
  genv.__mcp_hooks[hookKey] = original
  -- Parallel metadata registry so list-hooks / restore-hook can find + undo it.
  if type(genv.__mcp_hook_meta) ~= "table" then genv.__mcp_hook_meta = {} end
  genv.__mcp_hook_meta[hookKey] = { kind = "metamethod", targetExpr = ${s(e)}, method = method }
  stored = true
end

return {
  Target = ${s(e)},
  Method = method,
  Hooked = true,
  OriginalStored = stored,
  HookKey = hookKey,
}
`;return{data:await o.runLuau(i,{threadContext:a,timeoutMs:2e4})}}});import{z as vn}from"zod";var us=u({name:"inspect-closure",title:"Inspect a function/closure by reference",description:"Resolve a Luau expression to a function and dump everything about it in one call: whether it's a Lua or C closure, its name/source/line/param count/upvalue count (via getinfo), its constants, its upvalues (captured values), its nested-proto count, and its function hash. This is the by-reference counterpart to the gc-scan tools (scan-closures-by-*) \u2014 use it when you already have a handle on the function (e.g. a remote's OnClientEvent handler, a metamethod, or `getsenv(script).someFunc`). Requires getinfo/getconstants/getupvalues as available; missing capabilities are simply omitted. Returns { Target, Info, Constants, Upvalues, ProtoCount, FunctionHash } or { error }.",category:"Metatables & Closures",input:vn.object({functionPath:vn.string().describe("Luau expression resolving to a function, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).update', 'getrawmetatable(game).__namecall', or 'getconnections(game.Workspace.Part.Touched)[1].Function'. Evaluated as `return <functionPath>`."),includeConstants:vn.boolean().describe("Include the function's constants table (default true).").optional().default(!0),includeUpvalues:vn.boolean().describe("Include the function's upvalues \u2014 its captured variables (default true).").optional().default(!0),threadContext:vn.number().int().optional()}),async execute({functionPath:e,includeConstants:t,includeUpvalues:n,threadContext:r},a){let o=`
${k}
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end

local result = { Target = ${s(e)}, Info = __fnInfo(fn) }

if ${t?"true":"false"} and type(__getconstants) == "function" then
  local ok, c = pcall(__getconstants, fn)
  if ok and type(c) == "table" then
    local list = {}
    for i, v in ipairs(c) do list[i] = { Index = i, Type = typeof(v), Value = __encVal(v) } end
    result.Constants = list
    result.ConstantCount = #c
  end
end

if ${n?"true":"false"} and type(__getupvalues) == "function" then
  local ok, u = pcall(__getupvalues, fn)
  if ok and type(u) == "table" then
    local list = {}
    for i, v in ipairs(u) do list[i] = { Index = i, Type = typeof(v), Value = __encVal(v) } end
    result.Upvalues = list
    result.UpvalueCount = #u
  end
end

if type(__getprotos) == "function" then
  local ok, p = pcall(__getprotos, fn)
  if ok and type(p) == "table" then result.ProtoCount = #p end
end

if type(getfunctionhash) == "function" then
  local ok, h = pcall(getfunctionhash, fn)
  if ok then result.FunctionHash = tostring(h) end
end

return result
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as ha}from"zod";var ds=u({name:"is-readonly",title:"Check whether a table/metatable is read-only",description:"Resolve a Luau expression to a table (or a metatable expression) and report whether it is locked read-only via isreadonly. Roblox marks core metatables (e.g. getrawmetatable(game)) and many security tables read-only so __index/__namecall can't be swapped; this tells you whether you'd need setreadonly(t, false) before any mutation would take effect. Use it as a safe, non-mutating pre-check before attempting metatable hooks or constant/upvalue edits \u2014 it changes nothing. Typical targets: a plain table from getgenv(), or 'getrawmetatable(game)' to confirm the global instance metatable is frozen. Requires isreadonly; returns { Target, TargetType, ReadOnly } or { error } when the value isn't a table or isreadonly is unavailable.",category:"Metatables & Closures",input:ha.object({targetPath:ha.string().describe("Luau expression resolving to the table or metatable to test, e.g. 'getgenv().SomeTable', 'getrawmetatable(game)', or 'getrawmetatable(game.Players.LocalPlayer)'. Evaluated as `return <targetPath>`. isreadonly only applies to tables \u2014 userdata/Instances will report an error."),threadContext:ha.number().int().optional()}),async execute({targetPath:e,threadContext:t},n){let r=`
${k}
if type(isreadonly) ~= "function" then return { error = "isreadonly is not available in this executor." } end
local target, err = __eval(${s(e)})
if err then return { error = err } end
if type(target) ~= "table" then return { error = "isreadonly only works on tables; expression resolved to " .. typeof(target) .. ": " .. ${s(e)} } end

local okR, ro = pcall(isreadonly, target)
if not okR then return { error = "isreadonly failed: " .. tostring(ro) } end

return {
  Target = ${s(e)},
  TargetType = typeof(target),
  ReadOnly = ro,
}
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as ps}from"zod";var fs=u({name:"list-hooks",title:"List active hooks installed via this MCP",description:"List every function/metamethod hook installed through hook-function / hook-metamethod in this session. Each entry shows the key (pass it to restore-hook to undo), the kind (function or metamethod), the target expression, the metamethod name (if any), and the type of the stored original. Use this to audit what you've hooked before restoring \u2014 important because hooks are global and persistent. Reads getgenv().__mcp_hooks.",category:"Metatables & Closures",input:ps.object({threadContext:ps.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor." } end
local genv = getgenv()
local hooks = genv.__mcp_hooks or {}
local meta = genv.__mcp_hook_meta or {}
local list = {}
for k, v in pairs(hooks) do
  local m = meta[k] or {}
  list[#list + 1] = {
    Key = tostring(k),
    Kind = m.kind or "unknown",
    TargetExpr = m.targetExpr,
    Method = m.method,
    OriginalType = typeof(v),
  }
end
return { Count = #list, Hooks = list }
`,{threadContext:e,timeoutMs:15e3})}}});import{z as gr}from"zod";var ms=u({name:"restore-hook",title:"Restore (undo) a hook installed via this MCP",description:"WRITES LIVE GAME STATE. Undo a hook created by hook-function / hook-metamethod, restoring the captured original. Pass a `key` from list-hooks to restore one, or `all: true` to restore every tracked hook. For function hooks it re-resolves the target and calls restorefunction (falling back to re-hooking with the original); for metamethod hooks it re-installs the original metamethod. Successfully restored hooks are removed from the registry. Use this to clean up after debugging so your hooks don't linger and destabilize the game.",category:"Metatables & Closures",mutatesState:!0,input:gr.object({key:gr.string().describe("The hook key to restore (from list-hooks). Ignored when all=true.").optional().default(""),all:gr.boolean().describe("Restore ALL tracked hooks (ignores key). Default false.").optional().default(!1),threadContext:gr.number().int().optional()}),async execute({key:e,all:t,threadContext:n},r){let a=`
${k}
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor." } end
local genv = getgenv()
local hooks = genv.__mcp_hooks or {}
local meta = genv.__mcp_hook_meta or {}

local function restoreOne(k)
  local original = hooks[k]
  local m = meta[k]
  if original == nil then return false, "no stored original for this key" end
  if not m then return false, "no metadata for this key (cannot determine how to restore)" end
  if m.kind == "function" then
    local target, terr = __eval(m.targetExpr)
    if terr then return false, "could not re-resolve target: " .. terr end
    local ok, err = pcall(function()
      if type(restorefunction) == "function" then restorefunction(target)
      elseif type(hookfunction) == "function" then hookfunction(target, original)
      else error("no restorefunction/hookfunction available") end
    end)
    if not ok then return false, "restore failed: " .. tostring(err) end
  elseif m.kind == "metamethod" then
    if type(hookmetamethod) ~= "function" then return false, "hookmetamethod is not available" end
    local obj, oerr = __eval(m.targetExpr)
    if oerr then return false, "could not re-resolve object: " .. oerr end
    local ok, err = pcall(hookmetamethod, obj, m.method, original)
    if not ok then return false, "restore failed: " .. tostring(err) end
  else
    return false, "unknown hook kind: " .. tostring(m.kind)
  end
  hooks[k] = nil
  meta[k] = nil
  return true, nil
end

if ${t?"true":"false"} then
  local keys = {}
  for k in pairs(hooks) do keys[#keys + 1] = k end
  local results = {}
  for _, k in ipairs(keys) do
    local ok, err = restoreOne(k)
    results[#results + 1] = { Key = tostring(k), Restored = ok, Error = err }
  end
  return { RestoredAll = true, Count = #results, Results = results }
end

local key = ${s(e??"")}
if key == "" then return { error = "Provide a key (from list-hooks), or pass all=true." } end
local ok, err = restoreOne(key)
if not ok then return { error = err, Key = key } end
return { Restored = key, ok = true }
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:15e3})}}});import{z as kn}from"zod";var hs=u({name:"set-closure-constant",title:"Set a constant of a live function (MUTATES STATE)",description:"WRITES LIVE GAME STATE. DANGER \u2014 Resolve a Luau expression to a function and overwrite one of its bytecode constants via setconstant. Constants are the literal values baked into a function's bytecode (numbers, strings, the names of globals/methods it calls). Patching one changes the function's behavior the next time it runs \u2014 e.g. rewrite a magic number, swap a hardcoded string, or redirect a method call by changing its name constant. This persists for the exact closure and can destabilize the game or trip anticheat; some executors only allow same-type replacement. Index is 1-based and must be within the function's constant count (inspect-closure reports ConstantCount). Requires setconstant. Pass confirm=true to proceed. Returns { Target, Index, ok } or { error }.",category:"Metatables & Closures",mutatesState:!0,input:kn.object({functionPath:kn.string().describe("Luau expression resolving to the function whose constant you want to change, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).fire' or a function found via scan-closures-by-source. Evaluated as `return <functionPath>`."),index:kn.number().int().min(1).describe("1-based index of the constant to overwrite. Must be within the function's constant count (see ConstantCount from inspect-closure)."),value:we.describe("New value for the constant. kind 'string'|'number'|'boolean' uses value literally; kind 'nil' sets nil; kind 'raw' treats value as a Luau expression evaluated for its result. Note: many executors require the replacement to be the same type as the original constant."),confirm:kn.boolean().describe("Must be true to actually mutate the live function. When omitted or false, the tool refuses and changes nothing."),threadContext:kn.number().int().optional()}),async execute({functionPath:e,index:t,value:n,confirm:r,threadContext:a},o){if(r!==!0)return{data:{error:"Refusing to set closure constant (mutates live state); pass confirm=true."},isError:!0};let i=te(n),l=`
${k}
local __setconstant = setconstant or (type(debug) == "table" and debug.setconstant) or nil
if type(__setconstant) ~= "function" then return { error = "setconstant is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end

local ok, serr = pcall(__setconstant, fn, ${t}, ${i})
if not ok then return { error = "setconstant failed: " .. tostring(serr) } end

return { Target = ${s(e)}, Index = ${t}, ok = true }
`;return{data:await o.runLuau(l,{threadContext:a,timeoutMs:2e4})}}});import{z as xn}from"zod";var gs=u({name:"set-closure-upvalue",title:"Set an upvalue of a live function (MUTATES STATE)",description:"WRITES LIVE GAME STATE. DANGER \u2014 Resolve a Luau expression to a function and overwrite one of its upvalues (a variable captured by the closure) via setupvalue. Use this to patch a function's behavior in place without rehooking it \u2014 e.g. flip a captured `enabled` boolean, swap a captured config table, or zero out a captured cooldown. The change persists for every future call of that exact closure and is shared by all closures that captured the same upvalue, so it can destabilize the game or trip anticheat. Index is 1-based and must be within the function's upvalue count (inspect-closure reports UpvalueCount). Requires setupvalue. Pass confirm=true to proceed. Returns { Target, Index, ok } or { error }.",category:"Metatables & Closures",mutatesState:!0,input:xn.object({functionPath:xn.string().describe("Luau expression resolving to the function whose upvalue you want to change, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).update' or 'getrawmetatable(game).__namecall'. Evaluated as `return <functionPath>`."),index:xn.number().int().min(1).describe("1-based index of the upvalue to overwrite. Must be within the function's upvalue count (see UpvalueCount from inspect-closure)."),value:we.describe("New value for the upvalue. kind 'string'|'number'|'boolean' uses value literally; kind 'nil' sets nil; kind 'raw' treats value as a Luau expression evaluated for its result (e.g. value='Vector3.new(0,0,0)' or 'game.Workspace')."),confirm:xn.boolean().describe("Must be true to actually mutate the live function. When omitted or false, the tool refuses and changes nothing."),threadContext:xn.number().int().optional()}),async execute({functionPath:e,index:t,value:n,confirm:r,threadContext:a},o){if(r!==!0)return{data:{error:"Refusing to set closure upvalue (mutates live state); pass confirm=true."},isError:!0};let i=te(n),l=`
${k}
local __setupvalue = setupvalue or (type(debug) == "table" and debug.setupvalue) or nil
if type(__setupvalue) ~= "function" then return { error = "setupvalue is not available in this executor." } end
local fn, err = __evalFn(${s(e)})
if err then return { error = err } end

local ok, serr = pcall(__setupvalue, fn, ${t}, ${i})
if not ok then return { error = "setupvalue failed: " .. tostring(serr) } end

return { Target = ${s(e)}, Index = ${t}, ok = true }
`;return{data:await o.runLuau(l,{threadContext:a,timeoutMs:2e4})}}});import{z as _n}from"zod";var bs=u({name:"set-metatable-readonly",title:"Toggle a metatable's read-only flag (MUTATES live state)",description:"WRITES LIVE GAME STATE. DANGER \u2014 Resolve a Luau expression to a metatable (usually getrawmetatable(obj)) and flip its read-only flag via setreadonly. Most game metatables (e.g. getrawmetatable(game)) are locked read-only so __index/__namecall cannot be overwritten. Pass readonly=false to temporarily unlock a metatable so you can edit a metamethod (or run hook-metamethod), then call this again with readonly=true to RE-LOCK it \u2014 leaving a core metatable writable is a classic anticheat tripwire and can crash or destabilize the game. This changes the live runtime; it does not create a copy. Requires setreadonly. Because it mutates state you MUST pass confirm=true; otherwise the tool refuses and does nothing. Returns { Target, ReadOnly, ok } or { error }.",category:"Metatables & Closures",mutatesState:!0,input:_n.object({targetPath:_n.string().describe("Luau expression resolving to the metatable (a table) whose read-only flag you want to change, e.g. 'getrawmetatable(game)', 'getrawmetatable(game.Players.LocalPlayer)', or 'getgenv().SomeLockedTable'. Evaluated as `return <targetPath>`. Should resolve to a table \u2014 non-tables will error."),readonly:_n.boolean().describe("The new read-only state. false = unlock the metatable so its metamethods can be edited/hooked; true = re-lock it. Always re-lock when you are done to avoid leaving the game in an unprotected, anticheat-suspicious state."),confirm:_n.boolean().describe("Safety gate. Must be exactly true to apply the change. If omitted or false the tool refuses and does nothing, because toggling read-only on a live metatable can destabilize the game or trip anticheat."),threadContext:_n.number().int().optional()}),async execute({targetPath:e,readonly:t,confirm:n,threadContext:r},a){if(n!==!0)return{data:{error:"Refusing to change a live metatable's read-only flag; pass confirm=true."},isError:!0};let o=`
${k}
if type(setreadonly) ~= "function" then return { error = "setreadonly is not available in this executor." } end
local target, err = __eval(${s(e)})
if err then return { error = err } end
if type(target) ~= "table" then return { error = "targetPath did not resolve to a table (got " .. typeof(target) .. "); pass a metatable, e.g. getrawmetatable(game)." } end

local desired = ${t?"true":"false"}
local okSet, setErr = pcall(setreadonly, target, desired)
if not okSet then return { error = "setreadonly failed: " .. tostring(setErr) } end

local nowReadOnly = desired
if type(isreadonly) == "function" then
  local okR, r = pcall(isreadonly, target)
  if okR then nowReadOnly = r end
end

return {
  Target = ${s(e)},
  ReadOnly = nowReadOnly,
  ok = true,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as wn}from"zod";var ys=u({name:"set-rawmetatable",title:"Replace an object's raw metatable (MUTATES live state)",description:"WRITES LIVE GAME STATE. DANGER \u2014 Resolve a Luau expression to an object (table/Instance/userdata) and REPLACE its entire metatable via setrawmetatable, bypassing any __metatable lock. This swaps out __index/__namecall/__newindex etc. wholesale, so it can completely change how the object behaves \u2014 overwriting the game's core metatable can break the client, sever security routing, and is a strong anticheat signal. Typical RE use: clone the existing metatable, modify a metamethod, then set it back. Note the target metatable may need to be writable (see set-metatable-readonly) before this succeeds. This changes the live runtime in place. Requires setrawmetatable. Because it mutates state you MUST pass confirm=true; otherwise the tool refuses and does nothing. Returns { Target, ok } or { error }.",category:"Metatables & Closures",mutatesState:!0,input:wn.object({objectPath:wn.string().describe("Luau expression resolving to the object whose metatable you want to replace, e.g. 'game', 'game.Players.LocalPlayer', or 'getgenv().SomeProxy'. Evaluated as `return <objectPath>`."),metatableExpr:wn.string().describe("Raw Luau expression evaluating to the NEW metatable (a table) to install, e.g. '{ __index = function() return nil end }', 'setmetatable({}, nil)', or a previously cloned/edited table referenced from getgenv(). Evaluated as `return <metatableExpr>`; must resolve to a table or nil."),confirm:wn.boolean().describe("Safety gate. Must be exactly true to apply the change. If omitted or false the tool refuses and does nothing, because replacing a live object's metatable can break the game or trip anticheat."),threadContext:wn.number().int().optional()}),async execute({objectPath:e,metatableExpr:t,confirm:n,threadContext:r},a){if(n!==!0)return{data:{error:"Refusing to replace a live object's raw metatable; pass confirm=true."},isError:!0};let o=`
${k}
if type(setrawmetatable) ~= "function" then return { error = "setrawmetatable is not available in this executor." } end
local obj, objErr = __eval(${s(e)})
if objErr then return { error = objErr } end

local mt, mtErr = __eval(${s(t)})
if mtErr then return { error = "metatableExpr: " .. mtErr } end
if mt ~= nil and type(mt) ~= "table" then return { error = "metatableExpr did not resolve to a table or nil (got " .. typeof(mt) .. ")." } end

local okSet, setErr = pcall(setrawmetatable, obj, mt)
if not okSet then return { error = "setrawmetatable failed: " .. tostring(setErr) } end

return {
  Target = ${s(e)},
  ok = true,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as gt}from"zod";var vs=u({name:"find-string-in-tables",title:"Find string VALUES stored in GC tables (runtime string data scan)",description:"Walk every live Luau GC table and report each string VALUE that matches `query`. This is the runtime-DATA complement to find-string-xrefs (which scans closures' bytecode constants): it finds strings that exist as actual table data at this moment \u2014 server responses, built-up chat/UI text, dynamically constructed remote names, cached config strings, decoded tokens \u2014 which may never appear as a source literal. By default contains=true performs a plain (non-pattern) substring search; set contains=false for exact equality. Each hit is recorded as { table, key, value } where 'table' is the container address (tostring), 'key' is the field (tostring), and 'value' is the matched string truncated to its first 200 characters. Pivot from a hit with read-path-value / write-path-value (or find-table-references to see who owns the container). Each table's pairs() iteration is pcall-guarded so locked/proxy tables never abort the scan; GC objects examined are capped by maxScan and results by limit, with a 'truncated' flag. Requires getgc (falls back from getgc(true) to getgc()). Returns { query, contains, matchCount, scannedObjects, truncated, matches } or { error }.",category:"Memory Scan",input:gt.object({query:gt.string().describe("The string to search for among table VALUES, e.g. 'GodMode', 'http', 'BuyItem', a token prefix, or any substring of runtime text. With contains=true (default) any string value containing this matches; with contains=false only string values exactly equal to this match. Case-sensitive, plain text (not a Lua pattern)."),contains:gt.boolean().describe("When true (default), match any string value that CONTAINS `query` as a plain substring (string.find with plain=true). When false, require exact string equality. Use exact to pin one specific value.").optional().default(!0),limit:gt.number().int().describe("Maximum number of matching strings to return (default 150). Hitting this sets truncated=true.").optional().default(150),maxScan:gt.number().int().describe("Maximum number of GC objects to examine before stopping (default 40000). Hitting this sets truncated=true. Raise for a deeper sweep at the cost of time; lower if scans are slow.").optional().default(4e4),threadContext:gt.number().int().optional()}),async execute({query:e,contains:t,limit:n,maxScan:r,threadContext:a},o){let i=Math.min(Math.max(Math.floor(n),1),5e3),l=Math.min(Math.max(Math.floor(r),100),2e5),c=t!==!1,d=`
${k}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local needle = ${s(e)}
local useContains = ${c?"true":"false"}

local function valHit(v)
  if type(v) ~= "string" then return false end
  if useContains then
    local ok, found = pcall(string.find, v, needle, 1, true)
    return ok and found ~= nil
  end
  return v == needle
end

local okGc, gc = pcall(getgc, true)
if not okGc or type(gc) ~= "table" then
  okGc, gc = pcall(getgc)
  if not okGc or type(gc) ~= "table" then return { error = "getgc returned no table." } end
end

local matches = {}
local matchCount = 0
local truncated = false
local scanned = 0

for _, obj in gc do
  scanned = scanned + 1
  if scanned > ${l} then truncated = true break end

  if type(obj) == "table" then
    pcall(function()
      local label = nil
      for k, v in pairs(obj) do
        if valHit(v) then
          if not label then label = tostring(obj) end
          matchCount = matchCount + 1
          if #matches < ${i} then
            local s = v
            if #s > 200 then s = string.sub(s, 1, 200) .. "..." end
            matches[#matches + 1] = { table = label, key = tostring(k), value = s }
          else
            truncated = true
          end
        end
        if #matches >= ${i} then break end
      end
    end)
  end

  if #matches >= ${i} then truncated = true break end
end

return {
  query = needle,
  contains = useContains,
  matchCount = matchCount,
  scannedObjects = scanned,
  truncated = truncated,
  matches = matches,
}
`;return{data:await o.runLuau(d,{threadContext:a,timeoutMs:45e3})}}});import{z as Sn}from"zod";var ks=u({name:"find-table-references",title:"Find all GC references to a specific table (reverse ownership scan)",description:"Answer 'who holds this table alive / who can reach it?' Resolve a Luau expression to a target TABLE, then walk the entire GC and record every OTHER object that references it: (1) for each GC TABLE, pcall-iterate pairs() and if any VALUE is the target, record { container, via='value', key } (the surrounding key text); (2) for each Lua CLOSURE, scan its upvalues (getupvalues, guarded) and if any UPVALUE is the target, record { container, via='upvalue', key } where container is the function's source:line (via debug.info / getinfo). The target table itself is skipped so it never lists itself. This is the inverse of the look-down tools (read-path-value, dump-table): use it to find the owner of a shared state/config table, to discover which closures captured it (so you can hook or inspect them), or to understand why a table is not being collected. Every access is pcall-guarded so locked objects never abort the scan; GC objects examined are capped by maxScan and results by limit, with a 'truncated' flag. Requires getgc; upvalue scanning additionally needs getupvalues (type-guarded \u2014 skipped if absent). Returns { target, referenceCount, scannedObjects, truncated, references } or { error }.",category:"Memory Scan",input:Sn.object({tableExpr:Sn.string().describe("Luau expression resolving to the target TABLE whose references you want to find, e.g. 'getgenv().PlayerData', 'require(game.ReplicatedStorage.Config)', '_G.Settings', or any table reference from a prior scan. Evaluated as `return <tableExpr>` and must resolve to a table."),limit:Sn.number().int().describe("Maximum number of references to return (default 100). Hitting this sets truncated=true.").optional().default(100),maxScan:Sn.number().int().describe("Maximum number of GC objects to examine before stopping (default 40000). Hitting this sets truncated=true. Raise for a deeper sweep at the cost of time; lower if scans are slow.").optional().default(4e4),threadContext:Sn.number().int().optional()}),async execute({tableExpr:e,limit:t,maxScan:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(t),1),5e3),i=Math.min(Math.max(Math.floor(n),100),2e5),l=`
${k}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local target, err = __eval(${s(e)})
if err then return { error = err } end
if type(target) ~= "table" then
  return { error = "tableExpr did not resolve to a table (got " .. typeof(target) .. "): " .. ${s(e)} }
end

local canUps = (type(__getupvalues) == "function")

local function fnLabel(fn)
  local info = __fnInfo(fn)
  local src = (info and info.ShortSource ~= "" and info.ShortSource) or (info and info.Source) or "?"
  local line = (info and info.LineDefined) or -1
  return tostring(src) .. ":" .. tostring(line)
end

local function safeKey(k)
  local ok, s = pcall(tostring, k)
  if not ok then return "<unprintable>" end
  if #s > 120 then s = string.sub(s, 1, 120) .. "..." end
  return s
end

local okGc, gc = pcall(getgc, true)
if not okGc or type(gc) ~= "table" then
  okGc, gc = pcall(getgc)
  if not okGc or type(gc) ~= "table" then return { error = "getgc returned no table." } end
end

local references = {}
local referenceCount = 0
local truncated = false
local scanned = 0

local function addRef(entry)
  referenceCount = referenceCount + 1
  if #references < ${o} then
    references[#references + 1] = entry
  else
    truncated = true
  end
end

for _, obj in gc do
  scanned = scanned + 1
  if scanned > ${i} then truncated = true break end

  local ot = type(obj)
  if ot == "table" then
    if obj ~= target then
      pcall(function()
        local label = nil
        for k, v in pairs(obj) do
          local ok, isHit = pcall(function() return v == target end)
          if ok and isHit then
            if not label then label = tostring(obj) end
            addRef({ container = label, via = "value", key = safeKey(k) })
          end
          if #references >= ${o} then break end
        end
      end)
    end
  elseif ot == "function" and canUps then
    local oku, ups = pcall(__getupvalues, obj)
    if oku and type(ups) == "table" then
      local label = nil
      for idx, u in pairs(ups) do
        local ok, isHit = pcall(function() return u == target end)
        if ok and isHit then
          if not label then label = fnLabel(obj) end
          addRef({ container = label, via = "upvalue", key = "upvalue#" .. tostring(idx) })
        end
        if #references >= ${o} then break end
      end
    end
  end

  if #references >= ${o} then truncated = true break end
end

return {
  target = tostring(target),
  referenceCount = referenceCount,
  scannedObjects = scanned,
  truncated = truncated,
  references = references,
}
`;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:45e3})}}});import{z as bt}from"zod";var xs=u({name:"find-tables-by-key",title:"Find GC tables that contain a named string key (structure scan)",description:"Cheat-Engine-style STRUCTURE scan: walk every live Luau GC table and report each one that contains a string key matching `key`. This is the complement to search-gc-value (which matches by stored VALUE) \u2014 here you match by the NAME of a field, which is ideal when you know a stat/config table exposes a field like 'Coins', 'WalkSpeed', 'GodMode' or 'Config' but you don't yet know the value or the container. For every matching key the tool records { table, matchedKey, sampleValue } where 'table' is the table's address (tostring), 'matchedKey' is the exact key string found, and 'sampleValue' is the encoded current value at that key \u2014 so you can immediately see what the field holds. Set contains=true for a substring match on key names (string.find with plain=true). Iteration of each table is pcall-guarded so locked/proxy tables never abort the scan; the number of GC objects examined is capped by maxScan and the result list by limit, with a 'truncated' flag when either cap is hit. Pivot from a hit with read-path-value / write-path-value (using a Luau expression that reaches the container) to read or flip the field. Requires getgc (falls back from getgc(true) to getgc()). Returns { matchCount, scannedObjects, truncated, matches } or { error }.",category:"Memory Scan",input:bt.object({key:bt.string().describe("The field name to look for as a KEY in GC tables, e.g. 'Coins', 'Health', 'WalkSpeed', 'GodMode', 'Config'. With contains=false (default) only string keys exactly equal to this are matched; with contains=true any string key whose text includes this substring matches (case-sensitive, plain text)."),contains:bt.boolean().describe("When true, match any string key that CONTAINS `key` as a plain substring (string.find with plain=true) instead of requiring exact equality. Default false (exact match). Use for fuzzy field discovery.").optional().default(!1),limit:bt.number().int().describe("Maximum number of matched keys to return (default 100). Hitting this sets truncated=true.").optional().default(100),maxScan:bt.number().int().describe("Maximum number of GC objects to examine before stopping (default 40000). Hitting this sets truncated=true. Raise for a deeper sweep at the cost of time; lower if scans are slow.").optional().default(4e4),threadContext:bt.number().int().optional()}),async execute({key:e,contains:t,limit:n,maxScan:r,threadContext:a},o){let i=Math.min(Math.max(Math.floor(n),1),5e3),l=Math.min(Math.max(Math.floor(r),100),2e5),c=t===!0,d=`
${k}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local needle = ${s(e)}
local useContains = ${c?"true":"false"}

local function keyHit(k)
  if type(k) ~= "string" then return false end
  if useContains then
    local ok, found = pcall(string.find, k, needle, 1, true)
    return ok and found ~= nil
  end
  return k == needle
end

local okGc, gc = pcall(getgc, true)
if not okGc or type(gc) ~= "table" then
  okGc, gc = pcall(getgc)
  if not okGc or type(gc) ~= "table" then return { error = "getgc returned no table." } end
end

local matches = {}
local matchCount = 0
local truncated = false
local scanned = 0

for _, obj in gc do
  scanned = scanned + 1
  if scanned > ${l} then truncated = true break end

  if type(obj) == "table" then
    pcall(function()
      local label = nil
      for k, v in pairs(obj) do
        if keyHit(k) then
          if not label then label = tostring(obj) end
          matchCount = matchCount + 1
          if #matches < ${i} then
            local okEnc, enc = pcall(__encVal, v)
            matches[#matches + 1] = { table = label, matchedKey = k, sampleValue = okEnc and enc or "<unprintable>" }
          else
            truncated = true
          end
        end
        if #matches >= ${i} then break end
      end
    end)
  end

  if #matches >= ${i} then truncated = true break end
end

return {
  matchCount = matchCount,
  scannedObjects = scanned,
  truncated = truncated,
  matches = matches,
}
`;return{data:await o.runLuau(d,{threadContext:a,timeoutMs:45e3})}}});import{z as ga}from"zod";var _s=u({name:"read-path-value",title:"Read the value at a Luau path/expression (precise slot read)",description:"Evaluate a single Luau expression and report exactly what lives at that slot \u2014 without mutating anything. Use it to read a precise location after a heap scan points you at it (e.g. 'getgenv().PlayerData.Coins', 'game.Players.LocalPlayer.leaderstats.Cash.Value', 'require(game.ReplicatedStorage.Config).GodMode', 'getrawmetatable(game).__namecall'), or to spot-check any value/global/field during analysis. The expression is evaluated as `return <expression>` under a pcall, so a bad path returns a clean { error } instead of throwing. The result reports { type } (Roblox typeof), { value } (a safe encoded scalar \u2014 Instances become 'Instance: <FullName>', tables/functions become their address), and { isTable }. When the value is a table it also returns { length } (the array-part length via #) and { keys } (up to 50 string keys, so you can see the shape and pick the next field to read). Reading the keys/length is pcall-guarded. This is read-only and is the counterpart to write-path-value. Requires loadstring/load. Returns { type, value, isTable, length?, keys?, keysTruncated? } or { error }.",category:"Memory Scan",input:ga.object({expression:ga.string().describe("Luau expression resolving to the value to read, e.g. 'getgenv().PlayerData.Coins', 'game.Players.LocalPlayer.leaderstats.Cash.Value', 'require(game.ReplicatedStorage.Config)', '_G.Settings', or any table slot / global / call result. Evaluated as `return <expression>`."),threadContext:ga.number().int().optional()}),async execute({expression:e,threadContext:t},n){let r=`
${k}
local val, err = __eval(${s(e)})
if err then return { error = err } end

local okT, t = pcall(typeof, val)
local vtype = okT and t or type(val)

local enc
local okEnc, e = pcall(__encVal, val)
enc = okEnc and e or "<unprintable>"

local isTable = (type(val) == "table")
local result = { type = vtype, value = enc, isTable = isTable }

if isTable then
  local okLen, len = pcall(function() return #val end)
  result.length = okLen and len or 0

  local keys = {}
  local keysTruncated = false
  pcall(function()
    local count = 0
    for k, _ in pairs(val) do
      if type(k) == "string" then
        count = count + 1
        if #keys < 50 then
          keys[#keys + 1] = k
        else
          keysTruncated = true
          break
        end
      end
    end
  end)
  result.keys = keys
  result.keysTruncated = keysTruncated
end

return result
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as yt}from"zod";var ws=u({name:"scan-number-range",title:"Scan GC tables for numeric values in a [min, max] range (CE range scan)",description:"Cheat-Engine-style RANGE scan: walk every live Luau GC table and report each numeric value v where min <= v <= max. Use this when you know a stat is within a window but not its exact value \u2014 e.g. coins between 100 and 200, health under 50, a timer in [0, 10], a damage multiplier in [1, 5]. It is the inexact complement to search-gc-value (which needs the precise number). Each hit is recorded as { table, key, value } where 'table' is the container address (tostring), 'key' is the field the number sits under (tostring), and 'value' is the raw number. To narrow many hits down to one, run successive scans with tightening bounds after the stat changes in-game (the Cheat-Engine 'next scan' technique), then read or flip the survivor with read-path-value / write-path-value. Each table's pairs() iteration is pcall-guarded so a locked/proxy table never aborts the scan; GC objects examined are capped by maxScan and results by limit, with a 'truncated' flag. NaN values are skipped. Requires getgc (falls back from getgc(true) to getgc()). Returns { min, max, matchCount, scannedObjects, truncated, matches } or { error }.",category:"Memory Scan",input:yt.object({min:yt.number().describe("Inclusive lower bound of the numeric window to match (e.g. 100 to find a coin total at least 100). Values v with v >= min and v <= max are recorded."),max:yt.number().describe("Inclusive upper bound of the numeric window to match (e.g. 200). Must be >= min for any hits. Combine with min to bracket a stat you don't know exactly (e.g. min=100, max=200)."),limit:yt.number().int().describe("Maximum number of matching numbers to return (default 150). Hitting this sets truncated=true.").optional().default(150),maxScan:yt.number().int().describe("Maximum number of GC objects to examine before stopping (default 40000). Hitting this sets truncated=true. Raise for a deeper sweep at the cost of time; lower if scans are slow.").optional().default(4e4),threadContext:yt.number().int().optional()}),async execute({min:e,max:t,limit:n,maxScan:r,threadContext:a},o){let i=Math.min(Math.max(Math.floor(n),1),5e3),l=Math.min(Math.max(Math.floor(r),100),2e5),c=Number.isFinite(e)?e:-1/0,d=Number.isFinite(t)?t:1/0,p=Number.isFinite(c)?String(c):"-math.huge",f=Number.isFinite(d)?String(d):"math.huge",h=`
${k}
if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

local lo = ${p}
local hi = ${f}

local okGc, gc = pcall(getgc, true)
if not okGc or type(gc) ~= "table" then
  okGc, gc = pcall(getgc)
  if not okGc or type(gc) ~= "table" then return { error = "getgc returned no table." } end
end

local matches = {}
local matchCount = 0
local truncated = false
local scanned = 0

for _, obj in gc do
  scanned = scanned + 1
  if scanned > ${l} then truncated = true break end

  if type(obj) == "table" then
    pcall(function()
      local label = nil
      for k, v in pairs(obj) do
        -- guard against NaN (v == v is false for NaN) and bound-check
        if type(v) == "number" and v == v and v >= lo and v <= hi then
          if not label then label = tostring(obj) end
          matchCount = matchCount + 1
          if #matches < ${i} then
            matches[#matches + 1] = { table = label, key = tostring(k), value = v }
          else
            truncated = true
          end
        end
        if #matches >= ${i} then break end
      end
    end)
  end

  if #matches >= ${i} then truncated = true break end
end

return {
  min = lo,
  max = hi,
  matchCount = matchCount,
  scannedObjects = scanned,
  truncated = truncated,
  matches = matches,
}
`;return{data:await o.runLuau(h,{threadContext:a,timeoutMs:45e3})}}});import{z as be}from"zod";var Ss=u({name:"search-gc-value",title:"Search the GC heap for where a value is stored (Cheat-Engine scan)",description:"Cheat-Engine-style heap scanner: find WHERE a specific value lives across the entire Luau garbage collector. Resolve a target from one of five value types, then walk every live object via getgc(true) and report each place that holds it. For GC TABLES the tool pcall-iterates pairs() and records a hit when a KEY or a VALUE matches (string matches support exact OR 'contains' substring search). For Lua CLOSURES (when scanFunctions is on) it scans the function's constants and upvalues. Each match reports { container, where, keyText? } where 'where' is one of value/key/constant/upvalue and 'container' is the table address or the closure's source:line. Use it to locate a coin/HP total, a remote or flag name, a boolean toggle, or a Part/Instance reference, then pivot with inspect-closure / dump-table / set-closure-upvalue to read or mutate it. Requires getgc; closure scanning additionally requires getconstants/getupvalues (each is type-guarded and simply skipped if the executor lacks it). Everything is pcall-guarded so locked/dead objects never abort the scan; the object count is capped by maxScan and the result list by limit, with a 'truncated' flag. Returns { valueType, matchCount, truncated, matches } or { error }.",category:"Memory Scan",input:be.object({valueType:be.enum(["number","string","boolean","instance","raw"]).describe(`How to interpret 'value' and what to search for:
- 'number': search for a numeric value (e.g. a coin/HP total).
- 'string': search for a string (supports match='contains' for substrings \u2014 e.g. a remote name).
- 'boolean': search for true/false (e.g. a god-mode flag).
- 'instance': 'value' is a Luau path/expression resolving to an Instance (e.g. 'game.Workspace.Boss').
- 'raw': 'value' is an arbitrary Luau expression; the tool searches for whatever it evaluates to (e.g. 'Enum.KeyCode.E', 'Vector3.new(0,0,0)', 'game:GetService("Players").LocalPlayer').`),value:be.union([be.string(),be.number(),be.boolean()]).describe("The value to search for. For number/string/boolean this is the literal value. For 'instance' it is a Luau path expression resolving to an Instance. For 'raw' it is a Luau expression that is evaluated and whose result is the search target. Required for instance/raw; for number/string/boolean it may be omitted only if you really mean to search for the empty string / 0 / false (prefer always supplying it).").optional(),match:be.enum(["exact","contains"]).describe("Match mode (default 'exact'). 'contains' performs a plain (non-pattern) substring search and applies ONLY to string searches; for every other value type it is ignored and exact equality is used.").optional().default("exact"),scanFunctions:be.boolean().describe("Also scan Lua closures' constants and upvalues for the target (default true). Disable to scan tables only, which is faster and avoids getconstants/getupvalues overhead.").optional().default(!0),limit:be.number().int().describe("Max number of match locations to return (default 150). Hitting this sets truncated=true.").optional().default(150),maxScan:be.number().int().describe("Max number of GC objects (tables + functions) to examine before stopping (default 40000). Hitting this sets truncated=true. Raise for a more thorough sweep at the cost of time; lower it if scans are slow.").optional().default(4e4),threadContext:be.number().int().optional()}),async execute({valueType:e,value:t,match:n,scanFunctions:r,limit:a,maxScan:o,threadContext:i},l){let c=Math.min(Math.max(Math.floor(a),1),5e3),d=Math.min(Math.max(Math.floor(o),100),2e5),p=n==="contains"?"contains":"exact",f=r!==!1,h,g=!1;if(e==="number"){let y=typeof t=="number"?t:Number(t??0);h=Number.isFinite(y)?String(y):"0/0"}else e==="boolean"?h=t===!0||t==="true"||t===1?"true":"false":e==="string"?h=s(String(t??"")):(g=!0,h=s(String(t??"nil")));let b=`
local __getconstants = getconstants or (type(debug) == "table" and (debug.getconstants or debug.getconstant))
local __getupvalues = getupvalues or (type(debug) == "table" and (debug.getupvalues or debug.getupvalue))
local __getinfo = (type(getinfo) == "function" and getinfo) or (type(debug) == "table" and (debug.getinfo or debug.info))

if type(getgc) ~= "function" then return { error = "getgc is not available in this executor." } end

-- ----- resolve the search target -----------------------------------------
local target
${g?`local loader = loadstring or load
if type(loader) ~= "function" then return { error = "loadstring/load is not available in this executor." } end
local okc, chunk = pcall(loader, "return " .. ${h})
if not okc or type(chunk) ~= "function" then
  return { error = "Failed to compile expression: " .. tostring(chunk) }
end
local okr, val = pcall(chunk)
if not okr then return { error = "Error evaluating expression: " .. tostring(val) } end
target = val
${e==="instance"?`if typeof(target) ~= "Instance" then
  return { error = "Expression did not resolve to an Instance (got " .. typeof(target) .. ")." }
end`:""}`:`target = ${h}`}

local matchMode = ${s(p)}
local targetIsString = (type(target) == "string")
local useContains = (matchMode == "contains") and targetIsString

-- equality test (plain substring for string 'contains', else identity/==)
local function isHit(x)
  if useContains then
    if type(x) ~= "string" then return false end
    local ok, found = pcall(string.find, x, target, 1, true)
    return ok and found ~= nil
  end
  -- raw equality; pcall-guarded because comparing exotic userdata can error
  local ok, eq = pcall(function() return x == target end)
  return ok and eq == true
end

-- short, safe label for a function container: "source:line"
local function fnLabel(fn)
  local src, line = "?", -1
  if type(__getinfo) == "function" then
    local ok, info = pcall(__getinfo, fn, "sl")
    if ok and type(info) == "table" then
      src = info.short_src or info.source or src
      line = info.linedefined or info.currentline or line
    else
      local oks, s = pcall(__getinfo, fn, "s"); if oks and s ~= nil and type(s) ~= "table" then src = tostring(s) end
      local okl, l = pcall(__getinfo, fn, "l"); if okl and type(l) == "number" then line = l end
    end
  end
  return tostring(src) .. ":" .. tostring(line)
end

-- safe tostring for a key/container label, capped in length
local function safeText(v)
  local ok, s = pcall(function()
    local t = typeof(v)
    if t == "Instance" then
      local okn, n = pcall(function() return v:GetFullName() end)
      return okn and ("Instance: " .. n) or "<Instance>"
    end
    return tostring(v)
  end)
  if not ok then return "<unprintable>" end
  if #s > 200 then s = string.sub(s, 1, 200) .. "..." end
  return s
end

-- ----- walk the GC -------------------------------------------------------
local okGc, gc = pcall(getgc, true)
if not okGc or type(gc) ~= "table" then
  okGc, gc = pcall(getgc)
  if not okGc or type(gc) ~= "table" then
    return { error = "getgc returned no table." }
  end
end

local matches = {}
local matchCount = 0
local truncated = false
local scanned = 0
local scanFns = ${f?"true":"false"}
local canConsts = scanFns and (type(__getconstants) == "function")
local canUps = scanFns and (type(__getupvalues) == "function")

local function addMatch(entry)
  matchCount = matchCount + 1
  if #matches < ${c} then
    matches[#matches + 1] = entry
  else
    truncated = true
  end
end

for _, obj in gc do
  scanned = scanned + 1
  if scanned > ${d} then
    truncated = true
    break
  end

  local ot = type(obj)
  if ot == "table" then
    -- iterate keys + values; pcall the whole loop so locked/proxy tables can't abort the scan
    pcall(function()
      local label = nil
      for k, v in pairs(obj) do
        if isHit(v) then
          if not label then label = tostring(obj) end
          addMatch({ container = label, where = "value", keyText = safeText(k) })
        end
        if isHit(k) then
          if not label then label = tostring(obj) end
          addMatch({ container = label, where = "key", keyText = safeText(k) })
        end
        if #matches >= ${c} then break end
      end
    end)
  elseif ot == "function" and scanFns then
    if canConsts then
      local okc, consts = pcall(__getconstants, obj)
      if okc and type(consts) == "table" then
        local label = nil
        for _, c in pairs(consts) do
          if isHit(c) then
            if not label then label = fnLabel(obj) end
            addMatch({ container = label, where = "constant" })
          end
        end
      end
    end
    if canUps then
      local oku, ups = pcall(__getupvalues, obj)
      if oku and type(ups) == "table" then
        local label = nil
        for _, u in pairs(ups) do
          if isHit(u) then
            if not label then label = fnLabel(obj) end
            addMatch({ container = label, where = "upvalue" })
          end
        end
      end
    end
  end

  if #matches >= ${c} then
    -- keep scanning only to count? No \u2014 stop early once output is full to stay fast.
    truncated = true
    break
  end
end

return {
  valueType = ${s(e)},
  matchMode = matchMode,
  scannedObjects = scanned,
  matchCount = matchCount,
  truncated = truncated,
  matches = matches,
}
`;return{data:await l.runLuau(b,{threadContext:i,timeoutMs:45e3})}}});import{z as En}from"zod";var Es=u({name:"watch-value",title:"Watch any Luau expression over time (live value monitor)",description:"Sample ANY Luau expression repeatedly over a bounded window and report every value it took plus exactly when it changed \u2014 a live memory/state monitor for reverse-engineering and debugging. Give an expression that returns a value (no `return` keyword needed) and the tool compiles it once with loadstring, then polls it on a fixed interval until the duration elapses, recording the first sample and every subsequent change. Use it to confirm a value actually mutates when you trigger an action (watch leaderstats coins tick up, a Humanoid's Health drop, an anti-cheat flag flip, a getgenv() speed multiplier, a remote-cooldown timer, or a metatable hook's hit counter), to time how fast something updates, or to prove a suspected variable is the one that drives a behavior. EXAMPLES: 'game.Players.LocalPlayer.leaderstats.Coins.Value', 'getgenv().speed', 'workspace.CurrentCamera.CFrame.Position', '#getconnections(game.Workspace.Part.Touched)', 'tostring(getgenv().__mcp_remotespy and #getgenv().__mcp_remotespy.logs)'. The expression is evaluated as `return <expression>`, so it can be any value-producing Luau (indexing, function calls, arithmetic, concatenation). Each sample is stringified for transport (Instances become GetFullName()). Change detection compares the live value with the previous one via `~=`, so it catches identity changes for tables/Instances and equality changes for scalars. IMPORTANT: this call BLOCKS in-client for roughly `durationMs` while it samples (it is inherently synchronous), so keep durations short and perform the triggering action shortly before or during the watch. Everything is fully pcall-guarded: a compile error returns { error } immediately, and a per-tick evaluation error is recorded as a sample value rather than aborting the loop. Returns { expression, intervalMs, durationMs, sampleCount, changeCount, truncated, samples = [{ t, value, changed, ok }] }.",category:"Memory Scan",input:En.object({expression:En.string().describe("Any Luau expression that returns a value (do NOT prefix with `return` \u2014 the tool adds it). Examples: 'game.Players.LocalPlayer.leaderstats.Coins.Value', 'getgenv().speed', 'workspace.CurrentCamera.FieldOfView', '#getconnections(game.Workspace.Part.Touched)'."),intervalMs:En.number().describe("Polling interval in milliseconds between samples (default: 200, clamped 20..5000). Smaller catches fast transitions but produces more samples and more in-client overhead.").optional().default(200),durationMs:En.number().describe("Total time to watch in milliseconds (default: 5000, clamped 50..30000). The call blocks in-client for about this long; the network timeout is set to durationMs + 10000 so the loop finishes before the round-trip times out.").optional().default(5e3),threadContext:En.number().int().optional()}),async execute({expression:e,intervalMs:t,durationMs:n,threadContext:r},a){let o=Math.max(20,Math.min(5e3,Math.floor(t))),i=Math.max(50,Math.min(3e4,Math.floor(n))),l=`
local expression = ${s(e)}
local intervalSec = ${o} / 1000
local durationSec = ${i} / 1000
local MAX_SAMPLES = 300

-- Compile the getter once. A compile failure is a hard error.
local fn, cerr = loadstring("return " .. expression)
if not fn then
  return { error = "compile error: " .. tostring(cerr), expression = expression }
end

-- Encode any value into a transport-safe string. Instances become their full
-- path; everything else is tostring'd. Fully guarded so a weird __tostring
-- metamethod or a dead Instance can never abort the loop.
local function encode(v)
  local ok, t = pcall(typeof, v)
  if not ok then t = type(v) end
  if t == "Instance" then
    local okF, full = pcall(function() return v:GetFullName() end)
    if okF then return "Instance: " .. tostring(full) end
    return "<Instance>"
  end
  if t == "nil" then return "nil" end
  local okS, s = pcall(tostring, v)
  if okS then return s end
  return "<" .. tostring(t) .. ">"
end

local samples = {}
local changeCount = 0
local truncated = false
local startClock = os.clock()
local last
local haveLast = false
local first = true

while true do
  local elapsed = os.clock() - startClock
  local ok, v = pcall(fn)

  -- changed = first sample OR the value differs from the previous live value.
  -- Compare raw values (not encoded strings) so identity changes on
  -- tables/Instances are caught too. Errors are treated as changes vs a value.
  local changed
  if first then
    changed = true
  elseif not haveLast then
    changed = true
  else
    changed = (v ~= last)
  end

  -- Only record the first sample and any change, per spec, to keep output tight.
  if changed then
    if #samples >= MAX_SAMPLES then
      truncated = true
    else
      changeCount = changeCount + 1
      samples[#samples + 1] = {
        t = math.floor(elapsed * 1000 + 0.5),
        value = ok and encode(v) or ("<error> " .. encode(v)),
        changed = (not first),
        ok = ok,
      }
    end
  end

  last = v
  haveLast = true
  first = false

  if elapsed >= durationSec then break end
  if truncated then break end
  task.wait(intervalSec)
end

return {
  expression = expression,
  intervalMs = math.floor(intervalSec * 1000 + 0.5),
  durationMs = math.floor(durationSec * 1000 + 0.5),
  sampleCount = #samples,
  changeCount = changeCount,
  truncated = truncated,
  samples = samples,
}`,c=i+1e4;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:c})}}});import{z as br}from"zod";var Cs=u({name:"write-path-value",title:"Write a value into a live GC table slot (direct heap write, MUTATES STATE)",description:"WRITES LIVE GAME STATE. Direct heap write into one slot of a Luau table: resolve a Luau expression to a TABLE container, then assign container[key] = <value>, returning BOTH the OLD and NEW value so the change is auditable. This is the write counterpart to read-path-value and the natural action after a memscan locates a field \u2014 e.g. flip a config flag ('require(game.ReplicatedStorage.Config)', key='GodMode', value true), bump a cached stat ('getgenv().PlayerData', key='Coins', value=9999), or clear a slot (kind='nil'). The container expression is evaluated as `return <containerExpr>` and MUST resolve to a table (anything else returns a clean { error }). For non-primitive values (Vector3, Color3, Enum, an Instance, a table, \u2026) use kind='raw' and pass a Luau expression. The read of the old value and the write are each pcall-guarded. WARNING: this mutates running client memory immediately; writing through a metatable-protected/readonly table may error (returned as { error }) and some game state replicates or is server-authoritative. Requires loadstring/load. Returns { Container, Key, OldValue, NewValue, ok } or { error }.",category:"Memory Scan",mutatesState:!0,input:br.object({containerExpr:br.string().describe("Luau expression resolving to the TABLE whose slot you want to write, e.g. 'getgenv().PlayerData', 'require(game.ReplicatedStorage.Config)', '_G.Settings', or any table reference found via a heap scan. Evaluated as `return <containerExpr>` and must resolve to a table."),key:br.string().describe("The string key (field name) within the container table to write, e.g. 'Coins', 'GodMode', 'WalkSpeed'. Indexed as container[key]. (String keys only \u2014 for non-string keys, write via a raw containerExpr that already indexes to the parent.)"),value:we,threadContext:br.number().int().optional()}),async execute({containerExpr:e,key:t,value:n,threadContext:r},a){let o=te(n),i=`
${k}
local container, err = __eval(${s(e)})
if err then return { error = err } end
if type(container) ~= "table" then
  return { error = "containerExpr did not resolve to a table (got " .. typeof(container) .. "): " .. ${s(e)} }
end

local key = ${s(t)}

local oldEnc = nil
local okRead, oldVal = pcall(function() return container[key] end)
if okRead then
  local okE, e = pcall(__encVal, oldVal)
  oldEnc = okE and e or "<unprintable>"
end

local okSet, setErr = pcall(function() container[key] = ${o} end)
if not okSet then return { error = "failed to write key '" .. key .. "': " .. tostring(setErr) } end

local newEnc = nil
local okRead2, newVal = pcall(function() return container[key] end)
if okRead2 then
  local okE2, e2 = pcall(__encVal, newVal)
  newEnc = okE2 and e2 or "<unprintable>"
end

return {
  Container = tostring(container),
  Key = key,
  OldValue = oldEnc,
  NewValue = newEnc,
  ok = true,
}
`;return{data:await a.runLuau(i,{threadContext:r,timeoutMs:2e4})}}});import{z as _}from"zod";function vt(e,t,n){return Math.min(n,Math.max(t,e))}function Is(e,t=4){let n=10**t;return Math.round(e*n)/n}function ya(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)}function ba(e,t){return Object.prototype.hasOwnProperty.call(e,t)}function ku(e){switch(e.kind){case"path-exists":return!0;case"path-not-exists":return!1;case"property-equals":case"property-not-equals":case"property-contains":case"property-greater":case"property-less":case"attribute-equals":return e.expected;case"gui-visible":case"gui-enabled":case"descendant-exists":return e.expected??!0;case"character-distance":return{operator:e.operator,distance:e.distance};case"camera-facing":return{atMostDegrees:e.maxAngleDegrees};case"collection-count":return{operator:e.operator,count:e.count}}}function xu(e){return e.passed===!0&&e.errors.length===0&&e.evidence.readSucceeded}function Ts(e){return e.evidence.readSucceeded?e.errors.length>0?Math.min(vt(e.confidence,0,.95),.5):vt(e.confidence,0,.95):0}function _u(e){let t=e.length,n=e.filter(xu).length,r=e.filter(i=>!i.evidence.readSucceeded).length,a=t===0?0:Is(n/t),o=t===0?0:Is(Math.min(...e.map(i=>Ts(i))),3);return{passed:t>0&&n===t&&r===0,total:t,passedCount:n,failedCount:t-n,readFailureCount:r,passRatio:a,confidence:o}}function wu(e){return Array.isArray(e)?e.map(t=>typeof t=="string"?t:String(t)):[]}function Su(e){return ya(e)?{...e,readSucceeded:e.readSucceeded===!0,confidence:typeof e.confidence=="number"?vt(e.confidence,0,.95):e.readSucceeded===!0?.9:0}:{readSucceeded:!1,confidence:0}}function Rs(e,t){let n=ya(e)?e:{},r=Array.isArray(n.results)?n.results:[],a=t.map((i,l)=>{let c=ya(r[l])?r[l]:void 0,d=wu(c?.errors);c||d.push("The live assertion returned no result."),c&&typeof c.passed!="boolean"&&d.push("The live assertion returned no boolean pass state.");let p=Su(c?.evidence);p.readSucceeded||d.push("A required live read failed or did not complete."),(!c||!ba(c,"actual"))&&d.push("The live assertion returned no actual value.");let h=c?.passed===!0&&d.length===0&&p.readSucceeded,g=Ts({evidence:p,errors:d,confidence:typeof c?.confidence=="number"?vt(c.confidence,0,.95):p.confidence??0});return{id:i.id,kind:i.kind,status:h?"passed":"failed",passed:h,expected:c&&ba(c,"expected")?c.expected:ku(i),actual:c&&ba(c,"actual")?c.actual:"<unavailable>",evidence:p,errors:d,confidence:g}}),o=_u(a);return{results:a,aggregate:o,passed:o.passed,passRatio:o.passRatio,confidence:o.confidence}}function Eu(e){return JSON.stringify(e).replace(/\\u([0-9a-fA-F]{4})/g,"\\u{$1}")}function Ms(e,t){let n=Eu(JSON.stringify(e)),r=Math.floor(vt(t.scanLimit,1,5e3)),a=Math.floor(vt(t.readBudget,1,5e4));return`
local HttpService = game:GetService("HttpService")
local assertions = HttpService:JSONDecode(${n})
local scanLimit = ${r}
local readBudget = ${a}
local readCount = 0

local function consumeRead(amount)
  amount = amount or 1
  if readCount + amount > readBudget then return false end
  readCount = readCount + amount
  return true
end

local function encode(value, depth)
  depth = depth or 0
  local valueType = typeof(value)
  if value == nil then return "<nil>" end
  if valueType == "boolean" or valueType == "number" or valueType == "string" then return value end
  if valueType == "Instance" then
    local ok, fullName = pcall(function() return value:GetFullName() end)
    return { type = "Instance", className = value.ClassName, path = ok and fullName or tostring(value) }
  end
  if valueType == "table" then
    if depth >= 4 then return "<table:max-depth>" end
    local output = {}
    local ok = pcall(function()
      for key, entry in pairs(value) do output[tostring(key)] = encode(entry, depth + 1) end
    end)
    return ok and output or "<table:unreadable>"
  end
  local ok, text = pcall(function() return tostring(value) end)
  return { type = valueType, value = ok and text or "<unprintable>" }
end

local function fullName(instance)
  local ok, value = pcall(function() return instance:GetFullName() end)
  return ok and value or tostring(instance)
end

local function makeEvidence(fields)
  fields = fields or {}
  if fields.readSucceeded == nil then fields.readSucceeded = false end
  if fields.complete == nil then fields.complete = false end
  if fields.confidence == nil then fields.confidence = 0 end
  return fields
end

local function makeResult(assertion, passed, expected, actual, evidence, errors)
  errors = errors or {}
  evidence = makeEvidence(evidence)
  local safePassed = passed == true and evidence.readSucceeded == true and #errors == 0
  return {
    id = assertion.id,
    kind = assertion.kind,
    passed = safePassed,
    expected = encode(expected),
    actual = encode(actual),
    evidence = encode(evidence),
    errors = errors,
    confidence = math.min(0.95, tonumber(evidence.confidence) or 0),
  }
end

local function resolve(path)
  if type(path) ~= "string" or path == "" then
    return nil, "error", "Path must be a non-empty string."
  end
  local segments = {}
  for segment in string.gmatch(path, "[^%.]+") do segments[#segments + 1] = segment end
  if #segments == 0 then return nil, "error", "Path has no resolvable segments." end

  local current
  local first = segments[1]
  if first == "game" or first == "Game" then
    current = game
  elseif first == "workspace" or first == "Workspace" then
    current = workspace
  else
    if not consumeRead() then return nil, "error", "Read budget exhausted while resolving root." end
    local okService, service = pcall(function() return game:GetService(first) end)
    if okService and service then
      current = service
    else
      if not consumeRead() then return nil, "error", "Read budget exhausted while resolving root." end
      local okChild, child = pcall(function() return game:FindFirstChild(first) end)
      if not okChild then return nil, "error", "Failed to read game root: " .. tostring(child) end
      if child == nil then return nil, "missing", "Root segment '" .. first .. "' was not found." end
      current = child
    end
  end

  for index = 2, #segments do
    local name = segments[index]
    if not consumeRead() then return nil, "error", "Read budget exhausted while resolving path." end
    local okProperty, nextValue = pcall(function() return (current :: any)[name] end)
    if not okProperty or nextValue == nil then
      if typeof(current) ~= "Instance" then
        return nil, "error", "Cannot resolve segment '" .. name .. "' through a non-Instance value."
      end
      if not consumeRead() then return nil, "error", "Read budget exhausted while resolving path." end
      local okChild, child = pcall(function() return current:FindFirstChild(name) end)
      if not okChild then return nil, "error", "Failed to read segment '" .. name .. "': " .. tostring(child) end
      if child == nil then
        return nil, "missing", "Segment '" .. name .. "' was not found under '" .. fullName(current) .. "'."
      end
      nextValue = child
    end
    current = nextValue
  end
  if typeof(current) ~= "Instance" then
    return nil, "error", "Resolved path does not identify an Instance."
  end
  return current, "found", fullName(current)
end

local function readProperty(instance, property)
  if not consumeRead() then return false, nil, "Read budget exhausted before property read." end
  local ok, value = pcall(function() return (instance :: any)[property] end)
  if not ok then return false, nil, "Property '" .. tostring(property) .. "' could not be read: " .. tostring(value) end
  return true, value, nil
end

local function valuesEqual(actual, expected)
  if typeof(actual) == typeof(expected) then return actual == expected end
  if type(expected) == "string" then
    local actualType = typeof(actual)
    if actualType == "EnumItem" or actualType == "BrickColor" then
      local ok, text = pcall(function() return tostring(actual) end)
      return ok and text == expected
    end
  end
  return false
end

local function compareText(actual, expected, mode, caseSensitive)
  if type(actual) ~= "string" then return false, "Actual value is not text." end
  local left, right = actual, expected
  if caseSensitive == false then left, right = string.lower(left), string.lower(right) end
  if mode == "contains" then return string.find(left, right, 1, true) ~= nil, nil end
  return left == right, nil
end

local function compareCount(actual, expected, operator)
  if operator == "equals" then return actual == expected end
  if operator == "not-equals" then return actual ~= expected end
  if operator == "greater" then return actual > expected end
  if operator == "less" then return actual < expected end
  if operator == "at-least" then return actual >= expected end
  if operator == "at-most" then return actual <= expected end
  return false
end

local function selectorMatches(instance, selector)
  if selector == nil then return true, true, nil end
  if selector.by == "class" then
    if not consumeRead() then return false, false, "Read budget exhausted during class match." end
    local ok, matched = pcall(function() return instance:IsA(selector.value) end)
    if not ok then return false, false, "Class match failed: " .. tostring(matched) end
    return true, matched, nil
  end
  if selector.by == "name" then
    local ok, name, err = readProperty(instance, "Name")
    if not ok then return false, false, err end
    local matched, compareError = compareText(name, selector.value, selector.match or "equals", selector.caseSensitive)
    return compareError == nil, matched, compareError
  end
  if selector.by == "text" then
    if not consumeRead() then return false, false, "Read budget exhausted during text class check." end
    local okClass, isText = pcall(function()
      return instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")
    end)
    if not okClass then return false, false, "Text class check failed: " .. tostring(isText) end
    if not isText then return true, false, nil end
    local ok, textValue, err = readProperty(instance, "Text")
    if not ok then return false, false, err end
    local matched, compareError = compareText(textValue, selector.value, selector.match or "contains", selector.caseSensitive)
    return compareError == nil, matched, compareError
  end
  return false, false, "Unknown descendant selector."
end

local function initialChildren(root)
  if not consumeRead() then return nil, "Read budget exhausted before descendant scan." end
  local ok, children = pcall(function() return root:GetChildren() end)
  if not ok then return nil, "Could not enumerate children: " .. tostring(children) end
  return children, nil
end

local function scanDescendants(root, selector, stopAtFirst)
  local queue, queueError = initialChildren(root)
  if queue == nil then return nil, 0, false, nil, queueError end
  local head, scanned, count, firstMatch = 1, 0, 0, nil
  while head <= #queue and scanned < scanLimit do
    if not consumeRead() then
      return nil, scanned, false, firstMatch, "Read budget exhausted during descendant scan."
    end
    local instance = queue[head]
    head = head + 1
    scanned = scanned + 1
    local okMatch, matched, matchError = selectorMatches(instance, selector)
    if not okMatch then return nil, scanned, false, firstMatch, matchError end
    if matched then
      count = count + 1
      if firstMatch == nil then firstMatch = instance end
      if stopAtFirst then return count, scanned, true, firstMatch, nil end
    end
    local children, childError = initialChildren(instance)
    if children == nil then return nil, scanned, false, firstMatch, childError end
    for _, child in ipairs(children) do queue[#queue + 1] = child end
  end
  if head <= #queue then
    return count, scanned, false, firstMatch, "Scan limit reached before all descendants were read."
  end
  return count, scanned, true, firstMatch, nil
end

local rootNames = {
  HumanoidRootPart = 7,
  RootPart = 6,
  LowerTorso = 5,
  Torso = 4,
  UpperTorso = 3,
  Root = 2,
}
local rootNamePriority = { "HumanoidRootPart", "RootPart", "LowerTorso", "Torso", "UpperTorso", "Root" }

local function isBasePart(instance)
  if not consumeRead() then return false, "Read budget exhausted during BasePart check." end
  local ok, value = pcall(function() return instance:IsA("BasePart") end)
  if not ok then return false, "BasePart check failed: " .. tostring(value) end
  return value, nil
end

local function directModelRoot(model)
  for _, name in ipairs(rootNamePriority) do
    if not consumeRead() then return nil, nil, "Read budget exhausted during root discovery." end
    local ok, candidate = pcall(function() return model:FindFirstChild(name) end)
    if not ok then return nil, nil, "Character child read failed: " .. tostring(candidate) end
    if candidate then
      local base, baseError = isBasePart(candidate)
      if baseError then return nil, nil, baseError end
      if base then return candidate, name, nil end
    end
  end
  if not consumeRead() then return nil, nil, "Read budget exhausted during PrimaryPart read." end
  local okPrimary, primary = pcall(function() return model.PrimaryPart end)
  if okPrimary and primary then
    local base, baseError = isBasePart(primary)
    if baseError then return nil, nil, baseError end
    if base then return primary, "PrimaryPart", nil end
  end
  return nil, nil, nil
end

local function findRootInModel(model)
  local base, baseError = isBasePart(model)
  if baseError then return nil, nil, false, baseError end
  if base then return model, "explicit BasePart", true, nil end
  local direct, method, directError = directModelRoot(model)
  if directError then return nil, nil, false, directError end
  if direct then return direct, method, true, nil end

  local queue, queueError = initialChildren(model)
  if queue == nil then return nil, nil, false, queueError end
  local head, scanned, best, bestRank = 1, 0, nil, -1
  while head <= #queue and scanned < scanLimit do
    local instance = queue[head]
    head = head + 1
    scanned = scanned + 1
    local okName, name, nameError = readProperty(instance, "Name")
    if not okName then return nil, nil, false, nameError end
    local rank = rootNames[name]
    if rank then
      local candidateIsBase, candidateError = isBasePart(instance)
      if candidateError then return nil, nil, false, candidateError end
      if candidateIsBase and rank > bestRank then best, bestRank = instance, rank end
    end
    local children, childError = initialChildren(instance)
    if children == nil then return nil, nil, false, childError end
    for _, child in ipairs(children) do queue[#queue + 1] = child end
  end
  if best then return best, "custom named root", true, nil end
  if head <= #queue then return nil, nil, false, "Character root scan reached its limit." end
  return nil, nil, true, nil
end

local function playerFor(name)
  if not consumeRead() then return nil, "Read budget exhausted before Players read." end
  local okPlayers, Players = pcall(function() return game:GetService("Players") end)
  if not okPlayers then return nil, "Players service read failed: " .. tostring(Players) end
  if name then
    if not consumeRead() then return nil, "Read budget exhausted before player lookup." end
    local okPlayer, player = pcall(function() return Players:FindFirstChild(name) end)
    if not okPlayer then return nil, "Player lookup failed: " .. tostring(player) end
    if not player then return nil, "Player '" .. name .. "' was not found." end
    return player, nil
  end
  local okLocal, localPlayer, localError = readProperty(Players, "LocalPlayer")
  if not okLocal then return nil, localError end
  if not localPlayer then return nil, "LocalPlayer is unavailable." end
  return localPlayer, nil
end

local function modelScore(model, player)
  local score = 0
  local okModelName, modelName = readProperty(model, "Name")
  if okModelName then
    local okPlayerName, playerName = readProperty(player, "Name")
    if okPlayerName and modelName == playerName then score = score + 100 end
  end
  if consumeRead() then
    local okAttribute, attribute = pcall(function() return model:GetAttribute("PlayerName") end)
    local okPlayerName, playerName = readProperty(player, "Name")
    if okAttribute and okPlayerName and attribute == playerName then score = score + 80 end
  end
  if consumeRead() then
    local okAttribute, attribute = pcall(function() return model:GetAttribute("UserId") end)
    local okUserId, userId = readProperty(player, "UserId")
    if okAttribute and okUserId and tonumber(attribute) == tonumber(userId) then score = score + 80 end
  end
  return score
end

local function searchCustomRoot(player)
  local queue, queueError = initialChildren(workspace)
  if queue == nil then return nil, nil, false, queueError end
  local head, scanned, bestRoot, bestScore, bestMethod = 1, 0, nil, 0, nil
  while head <= #queue and scanned < scanLimit do
    local instance = queue[head]
    head = head + 1
    scanned = scanned + 1
    if not consumeRead() then return nil, nil, false, "Read budget exhausted during custom character scan." end
    local okModel, isModel = pcall(function() return instance:IsA("Model") end)
    if not okModel then return nil, nil, false, "Model check failed: " .. tostring(isModel) end
    if isModel then
      local score = modelScore(instance, player)
      if score > bestScore then
        local root, method, _, rootError = findRootInModel(instance)
        if rootError then return nil, nil, false, rootError end
        if root then bestRoot, bestScore, bestMethod = root, score, method end
      end
    end
    local children, childError = initialChildren(instance)
    if children == nil then return nil, nil, false, childError end
    for _, child in ipairs(children) do queue[#queue + 1] = child end
  end
  if bestRoot then return bestRoot, "Workspace custom model (" .. tostring(bestMethod) .. ")", true, nil end
  if head <= #queue then return nil, nil, false, "Custom character scan reached its limit." end
  return nil, nil, true, nil
end

local function characterRoot(assertion)
  if assertion.rootPath then
    local explicit, state, detail = resolve(assertion.rootPath)
    if state ~= "found" then return nil, nil, 0, "Explicit root path failed: " .. detail end
    local base, baseError = isBasePart(explicit)
    if baseError then return nil, nil, 0, baseError end
    if not base then return nil, nil, 0, "Explicit root path is not a BasePart." end
    return explicit, "explicit rootPath", 0.95, nil
  end
  if assertion.characterPath then
    local character, state, detail = resolve(assertion.characterPath)
    if state ~= "found" then return nil, nil, 0, "Explicit character path failed: " .. detail end
    local root, method, _, rootError = findRootInModel(character)
    if rootError then return nil, nil, 0, rootError end
    if not root then return nil, nil, 0, "No root part was found in the explicit character model." end
    return root, "explicit characterPath (" .. tostring(method) .. ")", 0.92, nil
  end

  local player, playerError = playerFor(assertion.playerName)
  if not player then return nil, nil, 0, playerError end
  local okCharacter, character, characterError = readProperty(player, "Character")
  if not okCharacter then return nil, nil, 0, characterError end
  if character then
    local root, method, _, rootError = findRootInModel(character)
    if rootError then return nil, nil, 0, rootError end
    if root then return root, "Player.Character (" .. tostring(method) .. ")", 0.95, nil end
  end
  local customRoot, method, _, customError = searchCustomRoot(player)
  if customError then return nil, nil, 0, customError end
  if customRoot then return customRoot, method, 0.8, nil end
  return nil, nil, 0, "No standard or confidently matched custom character root was found."
end

local function positionOf(instance)
  if not consumeRead() then return nil, "Read budget exhausted before position read." end
  local okBase, isPart = pcall(function() return instance:IsA("BasePart") end)
  if not okBase then return nil, "BasePart check failed: " .. tostring(isPart) end
  if isPart then
    local ok, position, err = readProperty(instance, "Position")
    if not ok then return nil, err end
    if typeof(position) ~= "Vector3" then return nil, "BasePart Position was not a Vector3." end
    return position, nil
  end
  if not consumeRead() then return nil, "Read budget exhausted before attachment check." end
  local okAttachment, isAttachment = pcall(function() return instance:IsA("Attachment") end)
  if not okAttachment then return nil, "Attachment check failed: " .. tostring(isAttachment) end
  if isAttachment then
    local ok, position, err = readProperty(instance, "WorldPosition")
    if not ok then return nil, err end
    if typeof(position) ~= "Vector3" then return nil, "Attachment WorldPosition was not a Vector3." end
    return position, nil
  end
  if not consumeRead() then return nil, "Read budget exhausted before model check." end
  local okModel, isModel = pcall(function() return instance:IsA("Model") end)
  if not okModel then return nil, "Model check failed: " .. tostring(isModel) end
  if isModel then
    if not consumeRead() then return nil, "Read budget exhausted before model pivot read." end
    local okPivot, pivot = pcall(function() return instance:GetPivot() end)
    if not okPivot or typeof(pivot) ~= "CFrame" then return nil, "Model pivot could not be read." end
    return pivot.Position, nil
  end
  return nil, "Target must be a BasePart, Attachment, or Model."
end

local function evaluatePath(assertion)
  local instance, state, detail = resolve(assertion.path)
  local expected = assertion.kind == "path-exists"
  if state == "error" then
    return makeResult(assertion, false, expected, "<unavailable>", {
      path = assertion.path, readSucceeded = false, complete = false, confidence = 0,
    }, { detail })
  end
  local actual = instance ~= nil
  return makeResult(assertion, actual == expected, expected, actual, {
    path = assertion.path,
    resolvedPath = instance and fullName(instance) or nil,
    detail = detail,
    readSucceeded = true,
    complete = true,
    confidence = 0.95,
  }, {})
end

local function evaluateProperty(assertion)
  local instance, state, detail = resolve(assertion.path)
  if state ~= "found" then
    return makeResult(assertion, false, assertion.expected, "<unavailable>", {
      path = assertion.path, property = assertion.property, readSucceeded = false, confidence = 0,
    }, { "Property target could not be resolved: " .. detail })
  end
  local ok, actual, readError = readProperty(instance, assertion.property)
  if not ok then
    return makeResult(assertion, false, assertion.expected, "<unavailable>", {
      path = assertion.path, resolvedPath = fullName(instance), property = assertion.property,
      readSucceeded = false, confidence = 0,
    }, { readError })
  end

  local passed, compareError = false, nil
  if assertion.kind == "property-equals" then passed = valuesEqual(actual, assertion.expected)
  elseif assertion.kind == "property-not-equals" then passed = not valuesEqual(actual, assertion.expected)
  elseif assertion.kind == "property-contains" then
    passed, compareError = compareText(actual, assertion.expected, "contains", assertion.caseSensitive)
  elseif assertion.kind == "property-greater" then
    if type(actual) ~= "number" then compareError = "Actual property is not numeric."
    else passed = actual > assertion.expected end
  elseif assertion.kind == "property-less" then
    if type(actual) ~= "number" then compareError = "Actual property is not numeric."
    else passed = actual < assertion.expected end
  end
  local errors = {}
  if compareError then errors[#errors + 1] = compareError end
  return makeResult(assertion, passed, assertion.expected, actual, {
    path = assertion.path, resolvedPath = fullName(instance), property = assertion.property,
    actualType = typeof(actual), readSucceeded = true, complete = true, confidence = compareError and 0.5 or 0.95,
  }, errors)
end

local function evaluateAttribute(assertion)
  local instance, state, detail = resolve(assertion.path)
  if state ~= "found" then
    return makeResult(assertion, false, assertion.expected, "<unavailable>", {
      path = assertion.path, attribute = assertion.attribute, readSucceeded = false, confidence = 0,
    }, { "Attribute target could not be resolved: " .. detail })
  end
  if not consumeRead() then
    return makeResult(assertion, false, assertion.expected, "<unavailable>", {
      path = assertion.path, attribute = assertion.attribute, readSucceeded = false, confidence = 0,
    }, { "Read budget exhausted before attribute read." })
  end
  local ok, actual = pcall(function() return instance:GetAttribute(assertion.attribute) end)
  if not ok then
    return makeResult(assertion, false, assertion.expected, "<unavailable>", {
      path = assertion.path, attribute = assertion.attribute, readSucceeded = false, confidence = 0,
    }, { "Attribute could not be read: " .. tostring(actual) })
  end
  return makeResult(assertion, valuesEqual(actual, assertion.expected), assertion.expected, actual, {
    path = assertion.path, resolvedPath = fullName(instance), attribute = assertion.attribute,
    actualType = typeof(actual), readSucceeded = true, complete = true, confidence = 0.95,
  }, {})
end

local function evaluateGui(assertion)
  local instance, state, detail = resolve(assertion.path)
  local expected = assertion.expected
  if expected == nil then expected = true end
  if state ~= "found" then
    return makeResult(assertion, false, expected, "<unavailable>", {
      path = assertion.path, readSucceeded = false, confidence = 0,
    }, { "GUI target could not be resolved: " .. detail })
  end
  local property = assertion.kind == "gui-visible" and "Visible" or "Enabled"
  if assertion.kind == "gui-visible" then
    if not consumeRead() then
      return makeResult(assertion, false, expected, "<unavailable>", { readSucceeded = false }, { "Read budget exhausted before GUI class check." })
    end
    local okClass, isGui = pcall(function() return instance:IsA("GuiObject") end)
    if not okClass or not isGui then
      return makeResult(assertion, false, expected, "<unavailable>", {
        path = assertion.path, readSucceeded = okClass, confidence = okClass and 0.5 or 0,
      }, { okClass and "Target is not a GuiObject." or "GuiObject class check failed." })
    end
  end
  local ok, direct, readError = readProperty(instance, property)
  if not ok or type(direct) ~= "boolean" then
    return makeResult(assertion, false, expected, "<unavailable>", {
      path = assertion.path, property = property, readSucceeded = false, confidence = 0,
    }, { readError or (property .. " did not return a boolean.") })
  end

  local actual, blocker = direct, nil
  if assertion.kind == "gui-visible" and assertion.effective ~= false and direct then
    local current = instance
    for _ = 1, 64 do
      local okParent, parent, parentError = readProperty(current, "Parent")
      if not okParent then
        return makeResult(assertion, false, expected, "<unavailable>", {
          path = assertion.path, property = property, readSucceeded = false, confidence = 0,
        }, { parentError })
      end
      current = parent
      if current == nil or current == game then break end
      if not consumeRead() then
        return makeResult(assertion, false, expected, "<unavailable>", { readSucceeded = false }, { "Read budget exhausted during effective visibility check." })
      end
      local okGui, isGui = pcall(function() return current:IsA("GuiObject") end)
      if not okGui then
        return makeResult(assertion, false, expected, "<unavailable>", { readSucceeded = false }, { "Ancestor GUI class check failed." })
      end
      if isGui then
        local visibleOk, visible, visibleError = readProperty(current, "Visible")
        if not visibleOk then
          return makeResult(assertion, false, expected, "<unavailable>", { readSucceeded = false }, { visibleError })
        end
        if not visible then actual, blocker = false, fullName(current) .. ".Visible"; break end
      end
      if not consumeRead() then
        return makeResult(assertion, false, expected, "<unavailable>", { readSucceeded = false }, { "Read budget exhausted during LayerCollector check." })
      end
      local okLayer, isLayer = pcall(function() return current:IsA("LayerCollector") end)
      if not okLayer then
        return makeResult(assertion, false, expected, "<unavailable>", { readSucceeded = false }, { "LayerCollector class check failed." })
      end
      if isLayer then
        local enabledOk, enabled, enabledError = readProperty(current, "Enabled")
        if not enabledOk then
          return makeResult(assertion, false, expected, "<unavailable>", { readSucceeded = false }, { enabledError })
        end
        if not enabled then actual, blocker = false, fullName(current) .. ".Enabled"; break end
      end
    end
  end
  return makeResult(assertion, actual == expected, expected, actual, {
    path = assertion.path, resolvedPath = fullName(instance), property = property,
    direct = direct, effective = assertion.kind == "gui-visible" and assertion.effective ~= false,
    blocker = blocker, readSucceeded = true, complete = true, confidence = 0.95,
  }, {})
end

local function evaluateDescendant(assertion)
  local root, state, detail = resolve(assertion.path)
  local expected = assertion.expected
  if expected == nil then expected = true end
  if state ~= "found" then
    return makeResult(assertion, false, expected, "<unavailable>", {
      path = assertion.path, readSucceeded = false, confidence = 0,
    }, { "Descendant root could not be resolved: " .. detail })
  end
  local count, scanned, complete, match, scanError = scanDescendants(root, assertion.selector, true)
  if count == nil then
    return makeResult(assertion, false, expected, "<unavailable>", {
      path = assertion.path, scanned = scanned, readSucceeded = false, complete = false, confidence = 0,
    }, { scanError })
  end
  local exists = count > 0
  local proofComplete = exists or complete
  local errors = {}
  if not proofComplete then errors[#errors + 1] = scanError or "Descendant scan was incomplete." end
  return makeResult(assertion, proofComplete and exists == expected, expected, exists, {
    path = assertion.path, resolvedPath = fullName(root), selector = assertion.selector,
    match = match and fullName(match) or nil, scanned = scanned, readSucceeded = proofComplete,
    complete = proofComplete, confidence = proofComplete and 0.9 or 0,
  }, errors)
end

local function evaluateDistance(assertion)
  local target, state, detail = resolve(assertion.targetPath)
  if state ~= "found" then
    return makeResult(assertion, false, { operator = assertion.operator, distance = assertion.distance }, "<unavailable>", {
      targetPath = assertion.targetPath, readSucceeded = false, confidence = 0,
    }, { "Distance target could not be resolved: " .. detail })
  end
  local root, method, rootConfidence, rootError = characterRoot(assertion)
  if not root then
    return makeResult(assertion, false, { operator = assertion.operator, distance = assertion.distance }, "<unavailable>", {
      targetPath = assertion.targetPath, readSucceeded = false, confidence = 0,
    }, { rootError })
  end
  local rootPosition, rootPositionError = positionOf(root)
  local targetPosition, targetPositionError = positionOf(target)
  if not rootPosition or not targetPosition then
    return makeResult(assertion, false, { operator = assertion.operator, distance = assertion.distance }, "<unavailable>", {
      targetPath = assertion.targetPath, rootPath = fullName(root), readSucceeded = false, confidence = 0,
    }, { rootPositionError or targetPositionError })
  end
  local distance = (rootPosition - targetPosition).Magnitude
  local passed = assertion.operator == "at-most" and distance <= assertion.distance or distance >= assertion.distance
  return makeResult(assertion, passed, { operator = assertion.operator, distance = assertion.distance }, math.floor(distance * 1000 + 0.5) / 1000, {
    targetPath = fullName(target), rootPath = fullName(root), rootMethod = method,
    readSucceeded = true, complete = true, confidence = rootConfidence,
  }, {})
end

local function evaluateCamera(assertion)
  local target, state, detail = resolve(assertion.targetPath)
  if state ~= "found" then
    return makeResult(assertion, false, { atMostDegrees = assertion.maxAngleDegrees }, "<unavailable>", {
      targetPath = assertion.targetPath, readSucceeded = false, confidence = 0,
    }, { "Camera target could not be resolved: " .. detail })
  end
  local camera
  if assertion.cameraPath then
    local cameraState, cameraDetail
    camera, cameraState, cameraDetail = resolve(assertion.cameraPath)
    if cameraState ~= "found" then
      return makeResult(assertion, false, { atMostDegrees = assertion.maxAngleDegrees }, "<unavailable>", {
        cameraPath = assertion.cameraPath, readSucceeded = false, confidence = 0,
      }, { "Camera path could not be resolved: " .. cameraDetail })
    end
  else
    local ok, current, cameraError = readProperty(workspace, "CurrentCamera")
    if not ok or current == nil then
      return makeResult(assertion, false, { atMostDegrees = assertion.maxAngleDegrees }, "<unavailable>", {
        cameraPath = "workspace.CurrentCamera", readSucceeded = false, confidence = 0,
      }, { cameraError or "CurrentCamera is unavailable." })
    end
    camera = current
  end
  local targetPosition, targetError = positionOf(target)
  local okCFrame, cameraCFrame, cframeError = readProperty(camera, "CFrame")
  if not targetPosition or not okCFrame or typeof(cameraCFrame) ~= "CFrame" then
    return makeResult(assertion, false, { atMostDegrees = assertion.maxAngleDegrees }, "<unavailable>", {
      cameraPath = fullName(camera), targetPath = fullName(target), readSucceeded = false, confidence = 0,
    }, { targetError or cframeError or "Camera CFrame is unavailable." })
  end
  local delta = targetPosition - cameraCFrame.Position
  local angle = 0
  if delta.Magnitude > 0.0001 then
    local dot = math.clamp(cameraCFrame.LookVector:Dot(delta.Unit), -1, 1)
    angle = math.deg(math.acos(dot))
  end
  angle = math.floor(angle * 1000 + 0.5) / 1000
  return makeResult(assertion, angle <= assertion.maxAngleDegrees, { atMostDegrees = assertion.maxAngleDegrees }, angle, {
    cameraPath = fullName(camera), targetPath = fullName(target), readSucceeded = true,
    complete = true, confidence = 0.95,
  }, {})
end

local function evaluateCollection(assertion)
  local root, state, detail = resolve(assertion.path)
  local expected = { operator = assertion.operator, count = assertion.count }
  if state ~= "found" then
    return makeResult(assertion, false, expected, "<unavailable>", {
      path = assertion.path, readSucceeded = false, confidence = 0,
    }, { "Collection root could not be resolved: " .. detail })
  end
  local count, scanned, complete, firstMatch, scanError = 0, 0, true, nil, nil
  if (assertion.scope or "children") == "descendants" then
    count, scanned, complete, firstMatch, scanError = scanDescendants(root, assertion.selector, false)
    if count == nil then complete = false end
  else
    local children, childError = initialChildren(root)
    if children == nil then
      count, complete, scanError = nil, false, childError
    else
      scanned = #children
      for _, child in ipairs(children) do
        local okMatch, matched, matchError = selectorMatches(child, assertion.selector)
        if not okMatch then count, complete, scanError = nil, false, matchError; break end
        if matched then count = count + 1 end
      end
    end
  end
  if count == nil or not complete then
    return makeResult(assertion, false, expected, count or "<unavailable>", {
      path = assertion.path, scope = assertion.scope or "children", scanned = scanned,
      readSucceeded = false, complete = false, confidence = 0,
    }, { scanError or "Collection scan was incomplete." })
  end
  return makeResult(assertion, compareCount(count, assertion.count, assertion.operator), expected, count, {
    path = assertion.path, resolvedPath = fullName(root), scope = assertion.scope or "children",
    selector = assertion.selector, scanned = scanned, readSucceeded = true, complete = true, confidence = 0.9,
  }, {})
end

local function evaluate(assertion)
  if assertion.kind == "path-exists" or assertion.kind == "path-not-exists" then return evaluatePath(assertion) end
  if string.sub(assertion.kind, 1, 9) == "property-" then return evaluateProperty(assertion) end
  if assertion.kind == "attribute-equals" then return evaluateAttribute(assertion) end
  if assertion.kind == "gui-visible" or assertion.kind == "gui-enabled" then return evaluateGui(assertion) end
  if assertion.kind == "descendant-exists" then return evaluateDescendant(assertion) end
  if assertion.kind == "character-distance" then return evaluateDistance(assertion) end
  if assertion.kind == "camera-facing" then return evaluateCamera(assertion) end
  if assertion.kind == "collection-count" then return evaluateCollection(assertion) end
  return makeResult(assertion, false, "known assertion kind", assertion.kind, {
    readSucceeded = false, complete = false, confidence = 0,
  }, { "Unknown assertion kind." })
end

local results = {}
for index, assertion in ipairs(assertions) do
  local ok, result = pcall(function() return evaluate(assertion) end)
  if ok then
    results[index] = result
  else
    results[index] = makeResult(assertion, false, "successful live read", "<unavailable>", {
      readSucceeded = false, complete = false, confidence = 0,
    }, { "Assertion execution failed: " .. tostring(result) })
  end
end

return { results = results, reads = readCount, readBudget = readBudget, scanLimit = scanLimit }
`}var oe=_.string().min(1).max(64).regex(/^[A-Za-z0-9][A-Za-z0-9_-]*$/).describe("Stable assertion ID used to identify this result."),Z=_.string().min(1).max(500).describe("Dotted live Instance path beginning at game, workspace, or a service name."),kt=_.string().min(1).max(128),va=_.union([_.string(),_.number().finite(),_.boolean()]),Ls=_.discriminatedUnion("by",[_.object({by:_.literal("class"),value:_.string().min(1).max(128).describe("Roblox class name accepted by Instance:IsA, such as BasePart.")}),_.object({by:_.literal("name"),value:_.string().min(1).max(256),match:_.enum(["equals","contains"]).optional().default("equals"),caseSensitive:_.boolean().optional().default(!1)}),_.object({by:_.literal("text"),value:_.string().min(1).max(1e3),match:_.enum(["equals","contains"]).optional().default("contains"),caseSensitive:_.boolean().optional().default(!1)})]),Cu=_.discriminatedUnion("kind",[_.object({id:oe,kind:_.literal("path-exists"),path:Z}),_.object({id:oe,kind:_.literal("path-not-exists"),path:Z}),_.object({id:oe,kind:_.literal("property-equals"),path:Z,property:kt,expected:va}),_.object({id:oe,kind:_.literal("property-not-equals"),path:Z,property:kt,expected:va}),_.object({id:oe,kind:_.literal("property-contains"),path:Z,property:kt,expected:_.string().max(2e3),caseSensitive:_.boolean().optional().default(!1)}),_.object({id:oe,kind:_.literal("property-greater"),path:Z,property:kt,expected:_.number().finite()}),_.object({id:oe,kind:_.literal("property-less"),path:Z,property:kt,expected:_.number().finite()}),_.object({id:oe,kind:_.literal("attribute-equals"),path:Z,attribute:kt,expected:va}),_.object({id:oe,kind:_.literal("gui-visible"),path:Z,expected:_.boolean().optional().default(!0),effective:_.boolean().optional().default(!0).describe("Include hidden GuiObject ancestors and disabled LayerCollectors.")}),_.object({id:oe,kind:_.literal("gui-enabled"),path:Z,expected:_.boolean().optional().default(!0)}),_.object({id:oe,kind:_.literal("descendant-exists"),path:Z,selector:Ls,expected:_.boolean().optional().default(!0)}),_.object({id:oe,kind:_.literal("character-distance"),targetPath:Z,operator:_.enum(["at-most","at-least"]),distance:_.number().finite().nonnegative().max(1e6),playerName:_.string().min(1).max(64).optional(),characterPath:Z.optional(),rootPath:Z.optional()}),_.object({id:oe,kind:_.literal("camera-facing"),targetPath:Z,maxAngleDegrees:_.number().finite().min(0).max(180).optional().default(10),cameraPath:Z.optional()}),_.object({id:oe,kind:_.literal("collection-count"),path:Z,scope:_.enum(["children","descendants"]).optional().default("children"),operator:_.enum(["equals","not-equals","greater","less","at-least","at-most"]),count:_.number().int().nonnegative().max(1e6),selector:Ls.optional()})]),Iu=_.object({assertions:_.array(Cu).min(1).max(50).describe("Predicates evaluated together against one live-game snapshot."),scanLimit:_.number().int().positive().max(5e3).optional().default(1500).describe("Maximum descendants examined by any bounded search."),readBudget:_.number().int().positive().max(5e4).optional().default(15e3).describe("Maximum guarded live reads shared by the whole assertion batch."),timeoutMs:_.number().int().min(1e3).max(3e4).optional().default(2e4),threadContext:_.number().int().optional()}).superRefine(({assertions:e},t)=>{let n=new Set;for(let r of e)n.has(r.id)&&t.addIssue({code:"custom",path:["assertions"],message:`Assertion ID '${r.id}' is duplicated.`}),n.add(r.id)}),As=u({name:"assert-state",title:"Assert live game state",description:"VERIFY LIVE OUTCOMES in one bounded, read-only execution. Evaluate path existence, property and attribute values, effective GUI state, bounded descendant searches, custom-character distance, camera facing angle, and collection counts. Every result includes expected/actual evidence and errors. Missing, unreadable, or incomplete state always fails instead of being mistaken for success. Use this after actions and consume aggregate.passed, passRatio, and confidence as proof of the real outcome.",category:"Intelligence",mutatesState:!1,ai:{phase:"verify",prerequisites:["active-client"],consumes:["assertion predicates","live instance paths"],produces:["per-assertion evidence","aggregate verification result"],verifiesWith:[],alternatives:["verify-path-exists","get-instance-properties","script"],requiresCapabilities:[],sideEffects:[],failureRecovery:["inspect result errors and evidence","rediscover stale paths before retrying","provide rootPath or characterPath for game-specific avatars"]},input:Iu,async execute({assertions:e,scanLimit:t,readBudget:n,timeoutMs:r,threadContext:a},o){let i=e,l=Ms(i,{scanLimit:t,readBudget:n}),c=await o.runLuau(l,{timeoutMs:r,...a!==void 0?{threadContext:a}:{}}),d=Rs(c,i);return{data:d,summary:`${d.aggregate.passedCount}/${d.aggregate.total} live assertion(s) passed; confidence ${d.confidence.toFixed(2)}.`,isError:d.results.some(p=>p.errors.length>0)}}});import{z as je}from"zod";var Tu=[{cause:"transport-disconnected",message:"The bridge transport closed or the selected client disconnected during the call.",confidence:.96,recoverable:!0,patterns:[/\bclient_disconnected\b/i,/transport (?:is )?closed/i,/bridge (?:transport )?(?:is )?(?:closed|disconnected|lost)/i,/client (?:was )?disconnected/i,/websocket.*(?:closed|disconnect)/i,/socket hang up|broken pipe|econnreset|econnrefused/i]},{cause:"ambiguous-client-selection",message:"Several Roblox clients match this session and no unique target was selected.",confidence:.97,recoverable:!0,patterns:[/\bambiguous_client\b/i,/(?:client|selection).*ambiguous|ambiguous.*(?:client|selection)/i,/multiple (?:roblox )?(?:clients|accounts)/i,/status=ambiguous/i,/select-client.*(?:first|required)/i]},{cause:"no-client-selection",message:"No connected Roblox client is currently selected for this session.",confidence:.96,recoverable:!0,patterns:[/\bno_client_selected\b|\bclient_not_found\b/i,/no (?:roblox )?clients? (?:are )?connected/i,/no[- ]clients|no active client|client (?:is )?not selected/i,/active client.*required|requires? (?:an )?active client/i,/pinned client is offline|reason=no-clients/i]},{cause:"invalid-schema-or-input",message:"The attempted arguments do not satisfy the selected tool's input contract.",confidence:.95,recoverable:!0,patterns:[/\bvalidation\b/i,/invalid (?:arguments?|input|schema)/i,/schema validation|zod/i,/unrecognized key|unknown field|missing required (?:field|argument)/i,/expected .{1,80}(?:received|got)|required at /i]},{cause:"permission-or-mutation-blocked",message:"The operation was blocked by mutation approval, permission, or read-only policy.",confidence:.94,recoverable:!0,patterns:[/mutation (?:is )?not approved|mutation.*blocked/i,/allowmutations|permission denied|write access.*denied/i,/\bforbidden\b|\bunauthorized\b|not permitted/i,/read[- ]only (?:mode|policy|operation)|requires?.*authorization/i]},{cause:"custom-character-hierarchy",message:"The game uses a missing, delayed, or custom character hierarchy instead of the standard Character/Humanoid/HumanoidRootPart layout.",confidence:.95,recoverable:!0,patterns:[/characterrecovery|missing-or-custom/i,/custom character/i,/standard character (?:hierarchy|path).*(?:missing|incomplete|unavailable)/i,/humanoidrootpart.*(?:missing|not found|nil|unavailable)/i,/(?:missing|custom).*(?:humanoid|root part)/i]},{cause:"missing-executor-capability",message:"The active executor does not expose a capability required by the attempted tool.",confidence:.94,recoverable:!0,patterns:[/capabilit(?:y|ies).*(?:missing|unavailable|unsupported|required)/i,/(?:missing|required) executor (?:capability|function)/i,/not available in (?:this|the) executor/i,/executor (?:does not|doesn't) support/i,/(?:getgc|getgenv|hookfunction|newcclosure|firesignal|fireclickdetector|fireproximityprompt|virtualinputmanager).*(?:unavailable|not available|missing|unsupported)/i]},{cause:"bridge-overloaded",message:"The shared Roblox bridge reached a bounded concurrency, queue, or memory budget and rejected work to protect the game.",confidence:.98,recoverable:!0,patterns:[/\bbridge_overloaded\b/i,/bridge.*(?:overloaded|queue.*full|capacity)/i,/(?:eval|rpc).*queue.*(?:full|capacity|saturated)/i,/too many (?:queued|concurrent).*(?:eval|operation|request|tool call)/i]},{cause:"timeout",message:"The operation exceeded its execution or transport deadline.",confidence:.96,recoverable:!0,patterns:[/\bexecution_timeout\b/i,/timed out|timeout|deadline exceeded/i,/did not (?:answer|respond|complete).*(?:deadline|within)/i]},{cause:"stale-or-missing-instance-path",message:"The referenced instance path is missing, stale, renamed, or no longer resolves in the live game.",confidence:.92,recoverable:!0,patterns:[/path segment.{0,120}not found/i,/(?:instance|object|target|gui|remote) path.*(?:not found|missing|stale|invalid)/i,/(?:could not|unable to|failed to) resolve.*(?:path|instance|target|object)/i,/instance.{0,100}not found|target.*no longer exists/i,/stale (?:instance|path|reference)/i,/attempt to index nil.*(?:workspace|player|character)/i]},{cause:"unsupported-operation",message:"The requested tool or operation is not implemented or supported by this surface.",confidence:.91,recoverable:!0,patterns:[/\btool_not_found\b|no tool named .{1,100} registered|unknown tool/i,/unsupported operation|operation.*not supported/i,/not implemented|unsupported (?:action|method|type|mode)/i,/does not implement/i]},{cause:"lua-runtime-error",message:"Luau execution reached the client but failed while compiling or running the script.",confidence:.9,recoverable:!0,patterns:[/\bexecution_failed\b/i,/lua(?:u)? runtime|runtime error|stack traceback/i,/attempt to (?:index|call|perform arithmetic|concatenate)/i,/syntax error|compile error|loadstring.*failed/i]}],Ru={"transport-disconnected":["bridge-status","agent-context","list-clients"],"no-client-selection":["agent-context","list-clients","select-client","get-active-client"],"ambiguous-client-selection":["list-clients","select-client","get-active-client"],"stale-or-missing-instance-path":["search-instances","verify-path-exists","get-instance-tree","tool-schema"],"missing-executor-capability":["test-capabilities","get-executor-info","tool-plan","script"],"custom-character-hierarchy":["discover-character","search-instances","get-local-player-info","script"],"bridge-overloaded":["bridge-status","agent-context","tool-plan"],timeout:["bridge-status","agent-context","tool-schema","tool-plan"],"invalid-schema-or-input":["tool-schema","tool-plan"],"permission-or-mutation-blocked":["tool-schema","agent-run","agent-context"],"lua-runtime-error":["tool-schema","script","get-console-output","agent-context"],"unsupported-operation":["tool-plan","tool-schema","test-capabilities"],unknown:["agent-context","tool-schema","tool-plan","bridge-status"]},Mu={"transport-disconnected":"inspect bridge transport connection health and connected clients","no-client-selection":"list select inspect active Roblox client","ambiguous-client-selection":"list and select one active Roblox client","stale-or-missing-instance-path":"search resolve verify live instance path and tree","missing-executor-capability":"test executor capabilities and find supported alternative","custom-character-hierarchy":"discover custom player character humanoid root model","bridge-overloaded":"inspect bridge queue load and reduce parallel Roblox work",timeout:"diagnose timeout bridge state and reduce operation scope","invalid-schema-or-input":"inspect tool schema arguments and plan valid input","permission-or-mutation-blocked":"inspect mutation approval and read-only state","lua-runtime-error":"inspect Luau script runtime error and console output","unsupported-operation":"find a supported alternative tool for the goal",unknown:"inspect agent context tool schema and bridge diagnostics"},Lu=`local Players = game:GetService("Players")
local player = Players.LocalPlayer
local standard = player and player.Character
local function pathOf(value)
  local ok, path = pcall(function() return value:GetFullName() end)
  return ok and path or tostring(value)
end
local function inspect(model)
  if not model or not model:IsA("Model") then return nil end
  local humanoid = model:FindFirstChildOfClass("Humanoid")
  local root = model:FindFirstChild("HumanoidRootPart", true)
    or model:FindFirstChild("RootPart", true)
    or model:FindFirstChild("LowerTorso", true)
    or model:FindFirstChild("Torso", true)
    or model.PrimaryPart
  if not humanoid and not root then return nil end
  return {
    model = pathOf(model),
    humanoid = humanoid and pathOf(humanoid) or nil,
    rootPart = root and pathOf(root) or nil,
  }
end
local found = inspect(standard)
if found and found.humanoid and found.rootPart then return found end
local queue, head, scanned = workspace:GetChildren(), 1, 0
while head <= #queue and scanned < 1000 do
  local item = queue[head]
  head += 1
  scanned += 1
  local candidate = inspect(item)
  if candidate and candidate.humanoid and candidate.rootPart then return candidate end
  for _, child in ipairs(item:GetChildren()) do
    if #queue >= 1000 then break end
    queue[#queue + 1] = child
  end
end
return { error = "No standard or custom character candidate found in the bounded scan." }`;function Au(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)}function ka(e){let t=e.replace(/\s+/g," ").trim();return t.length>420?`${t.slice(0,417)}...`:t}function Je(e,t,n,r,a){if(n.length>=48||a>5||e===void 0)return;if(e instanceof Error){n.push(`${t}.name=${ka(e.name)}`),n.push(`${t}.message=${ka(e.message)}`);let i=e;i.code!==void 0&&Je(i.code,`${t}.code`,n,r,a+1),i.details!==void 0&&Je(i.details,`${t}.details`,n,r,a+1);return}if(typeof e=="string"){e.trim()&&n.push(`${t}=${ka(e)}`);return}if(typeof e=="number"||typeof e=="boolean"||typeof e=="bigint"){n.push(`${t}=${String(e)}`);return}if(e===null){n.push(`${t}=null`);return}if(typeof e!="object"||r.has(e))return;if(r.add(e),Array.isArray(e)){e.slice(0,12).forEach((i,l)=>{Je(i,`${t}[${l}]`,n,r,a+1)});return}let o=e;for(let i of Object.keys(o).sort().slice(0,24))Je(o[i],`${t}.${i}`,n,r,a+1)}function Nu(e){let t=[],n=new WeakSet;return Je(e.error,"error",t,n,0),Je(e.result,"result",t,n,0),Je(e.context,"context",t,n,0),t}function Pu(e){for(let t of Tu){let n=e.filter(r=>t.patterns.some(a=>a.test(r)));if(n.length>0)return{rule:t,evidence:n.slice(0,6)}}return{rule:null,evidence:e.slice(0,6)}}function $u(e){return e?Array.isArray(e)?e:e.list():[]}function yr(e,t=new WeakSet){return e===null||typeof e!="object"?JSON.stringify(e)??String(e):t.has(e)?'"[Circular]"':(t.add(e),Array.isArray(e)?`[${e.map(n=>yr(n,t)).join(",")}]`:`{${Object.keys(e).sort().map(n=>`${JSON.stringify(n)}:${yr(e[n],t)}`).join(",")}}`)}function Ps(e,t){return yr(e)!==yr(t)}function xt(e,t,n,r=0,a=new WeakSet){if(!(r>4||e===null||typeof e!="object"||a.has(e))){if(a.add(e),Array.isArray(e)){for(let o of e.slice(0,20))xt(o,t,n,r+1,a);return}for(let[o,i]of Object.entries(e))t.has(o.toLowerCase())&&n.push(i),xt(i,t,n,r+1,a)}}function Ns(e,t,n){if(!n||e===void 0||!Ps(e,t))return;let r=n.input.safeParse(e);return r.success?r.data:void 0}function Fu(e,t){if(!t||e.attemptedInput===void 0)return;let n=[],r=new Set(["correctedinput","resolvedinput"]);xt(e.context,r,n),xt(e.result,r,n);for(let g of n){let b=Ns(g,e.attemptedInput,t);if(b!==void 0)return b}let a=t.input.safeParse(e.attemptedInput);if(a.success&&Ps(a.data,e.attemptedInput))return a.data;if(!Au(e.attemptedInput))return;let o=e.attemptedInput,i=Object.keys(o).filter(g=>typeof o[g]=="string"&&/(?:^|_)(?:path|instancepath|targetpath|guipath|remotepath|characterpath|rootpartpath)$/i.test(g));if(i.length!==1)return;let l=i[0],c=l.toLowerCase(),d=new Set(c.includes("root")?["correctedpath","resolvedpath","actualpath","rootpart"]:c.includes("character")?["correctedpath","resolvedpath","actualpath","character","model"]:["correctedpath","resolvedpath","actualpath"]),p=[];xt(e.context,d,p),xt(e.result,d,p);let f=o[l],h=[...new Set(p.filter(g=>typeof g=="string"&&g!==f))];if(h.length===1)return Ns({...o,[l]:h[0]},o,t)}function Ou(e,t,n,r,a){let o=new Map,i=a.join(`
`).toLowerCase(),l=new Set(["transport-disconnected","no-client-selection","ambiguous-client-selection"]),c=(p,f,h)=>{let g=n.find(y=>y.name===p);if(!g||g.name===t.toolName||g.name==="explain-failure"||l.has(e)&&g.requiresClient||e==="permission-or-mutation-blocked"&&g.mutatesState)return;let b=g.ai?.requiresCapabilities??[];if(e==="missing-executor-capability"&&b.some(y=>i.includes(y.toLowerCase())))return;let m=o.get(p);m?(m.score=Math.max(m.score,f),m.reasons.add(h)):o.set(p,{tool:g,score:f,reasons:new Set([h])})};for(let p of r?.ai?.alternatives??[])c(p,100,`Declared by ${t.toolName}'s AI contract as an alternative.`);for(let p of r?.ai?.failureRecovery??[]){let f=p.toLowerCase();for(let h of n)f.includes(h.name.toLowerCase())&&c(h.name,96,`Named by ${t.toolName}'s failureRecovery contract.`)}Ru[e].forEach((p,f)=>{c(p,92-f*3,`Preferred recovery tool for ${e}.`)});let d=[Mu[e],r?.title,r?.description,...r?.ai?.failureRecovery??[]].filter(p=>typeof p=="string"&&p.length>0).join(" ");for(let p of qe(d,n,30)){let f=Math.min(78,38+Math.round(p.score/3));c(p.tool.name,f,p.matchedTerms.length>0?`Live discovery matched ${p.matchedTerms.slice(0,4).join(", ")}.`:p.why)}return[...o.values()].map(({tool:p,score:f,reasons:h})=>({name:p.name,title:p.title,score:Math.max(0,Math.min(100,f+(p.mutatesState?0:2))),reason:[...h].slice(0,3).join(" "),mutatesState:p.mutatesState,requiresClient:p.requiresClient,requiresCapabilities:p.ai?.requiresCapabilities??[]})).sort((p,f)=>f.score-p.score||p.name.localeCompare(f.name)).slice(0,6)}function qu(e,t,n){if(t){let r=n&&e==="invalid-schema-or-input";return{strategy:r?"with-corrected-input":"after-state-check",maxAttempts:r?1:0,retrySameInput:!1,conditions:["First verify whether the original mutation changed live state.","Never repeat the identical mutation input.",...r?["A single retry is allowed only with the schema-validated correctedInput."]:["Create a corrected plan or input before any later mutation."]]}}return e==="invalid-schema-or-input"?{strategy:n?"with-corrected-input":"manual-review",maxAttempts:n?1:0,retrySameInput:!1,conditions:[n?"Retry once with the schema-validated correctedInput.":"Inspect the live tool schema and construct different valid input first."]}:e==="unsupported-operation"?{strategy:"do-not-retry",maxAttempts:0,retrySameInput:!1,conditions:["Choose a supported fallback tool or operation."]}:e==="bridge-overloaded"?{strategy:"after-state-check",maxAttempts:1,retrySameInput:!0,conditions:["Wait for bridge-status to report a drained queue, then retry once with lower parallel fan-out and jitter."]}:e==="permission-or-mutation-blocked"||e==="unknown"?{strategy:"manual-review",maxAttempts:0,retrySameInput:!1,conditions:["Resolve authorization or gather stronger evidence before another call."]}:{strategy:n?"with-corrected-input":"after-recovery",maxAttempts:1,retrySameInput:!n&&(e==="transport-disconnected"||e==="timeout"),conditions:[n?"Apply the recovery step, then retry once with correctedInput.":"Apply the listed recovery step and confirm the prerequisite now holds before retrying once."]}}function Gu(e,t,n,r,a){let o=new Set(r.map(p=>p.name)),i=[],l=p=>{i.includes(p)||i.push(p)},c=(p,f)=>{o.has(p)&&l(f)};switch(n?.mutatesState&&l(`Do not repeat ${t.toolName} with the same input; first verify whether the original call already changed state.`),e){case"transport-disconnected":c("bridge-status","Call bridge-status to inspect the current bridge and client state."),l("Wait for transport recovery or reconnect the client before any client-bound operation.");break;case"no-client-selection":c("list-clients","Call list-clients to enumerate connected Roblox clients."),c("select-client","Call select-client with one exact connected client or account.");break;case"ambiguous-client-selection":c("list-clients","Call list-clients and compare account, place, and job identity."),c("select-client","Call select-client with the intended unique client before continuing.");break;case"stale-or-missing-instance-path":c("search-instances","Call search-instances to resolve the target against the live hierarchy."),c("verify-path-exists","Call verify-path-exists on the newly resolved path."),l("Replace the stale reference in attemptedInput before another operation.");break;case"missing-executor-capability":c("test-capabilities","Call test-capabilities and confirm the exact missing executor primitive."),l("Choose the highest-ranked fallback that does not require the missing capability.");break;case"custom-character-hierarchy":c("discover-character","Call discover-character and consume its resolved model, Humanoid, and root-part paths."),l("Use the bounded recoveryScript only when game-specific discovery needs custom adaptation.");break;case"bridge-overloaded":c("bridge-status","Call bridge-status and wait until queuedEvals is low before retrying."),l("Reduce mcp.parallel/script-fanout width; the bridge will preserve queued work fairly."),l("Retry once after a short randomized delay instead of launching an immediate retry storm.");break;case"timeout":l("Check bridge/client health and reduce the operation's scope before a single later attempt."),n?.mutatesState&&l("Verify the intended postcondition because a timed-out mutation may still have completed.");break;case"invalid-schema-or-input":c("tool-schema",`Call tool-schema for ${t.toolName} and compare every required field.`),l(a===void 0?"Construct new input that passes the live schema before calling the tool again.":"Use only the returned schema-validated correctedInput for a later call.");break;case"permission-or-mutation-blocked":l("Obtain explicit mutation authorization and keep the operation blocked until that approval exists."),l("Use a read-only observation or dry run to confirm the intended target and effect first.");break;case"lua-runtime-error":l("Inspect the reported Luau error/line and correct the script or resolved values before executing again."),c("get-console-output","Call get-console-output when the game log contains the missing runtime detail.");break;case"unsupported-operation":c("tool-plan","Call tool-plan with the original goal to find a supported workflow."),c("tool-schema","Inspect the selected fallback's live schema before calling it.");break;case"unknown":c("agent-context","Call agent-context to collect client, capability, and recent failure context."),l("Capture the complete error code/message and handled result before choosing another action.");break}for(let p of n?.ai?.failureRecovery??[])n?.mutatesState&&/retry|repeat/i.test(p)||l(`Tool contract guidance: ${p}`);let d=r.find(p=>!p.mutatesState);return d&&!i.some(p=>p.includes(d.name))&&l(`Use ${d.name} as the highest-ranked read-only fallback: ${d.reason}`),i}function $s(e,t){let n=$u(t),r=n.find(g=>g.name===e.toolName),a=Nu(e),o=Pu(a),i=o.rule?.cause??"unknown",l=Fu(e,r),c=Ou(i,e,n,r,a),d=r?.mutatesState===!0,p=o.rule?Math.min(1,o.rule.confidence+Math.min(.03,(o.evidence.length-1)*.01)):.2,f=o.rule?.recoverable??!1,h=o.evidence.length>0?o.evidence:["No error, handled result, or contextual failure evidence was supplied."];return{cause:i,message:o.rule?.message??"The supplied evidence does not match a known deterministic failure signature.",evidence:h,confidence:p,recoverable:f,retryPolicy:qu(i,d,l!==void 0),...l!==void 0?{correctedInput:l}:{},fallbackTools:c,...i==="custom-character-hierarchy"?{recoveryScript:Lu}:{},nextActions:Gu(i,e,r,c,l)}}var Fs=u({name:"explain-failure",title:"Explain and recover from a failed tool call",description:"READ-ONLY AND NO CLIENT REQUIRED. Deterministically classify a failed MCP/Roblox tool call from its error, handled result, attempted input, and optional context. Returns a standard recovery envelope with cause, exact evidence, confidence, retry safety, a schema-validated correctedInput only when safely derivable, live-registry fallback tools ranked using AI contracts and discovery, an optional useful recovery script, and concrete next actions. Use this after any failed or blocked call. It never invokes a fallback and never recommends repeating an identical failed mutation.",category:"Intelligence",requiresClient:!1,mutatesState:!1,ai:{phase:"observe",prerequisites:[],consumes:["failed tool name","error or handled result","attempted input"],produces:["failure classification","safe retry policy","ranked recovery plan"],verifiesWith:[],alternatives:["agent-context","tool-plan","tool-schema"],requiresCapabilities:[],sideEffects:[],failureRecovery:["provide the complete error code/message and handled result when classification is unknown"]},input:je.object({toolName:je.string().min(1).describe("Exact name of the tool that failed or returned a handled error."),error:je.unknown().optional().describe("Thrown error, transport error, domain error object, or error message."),result:je.unknown().optional().describe("Handled tool result or partial result associated with the failure."),attemptedInput:je.unknown().optional().describe("The exact input passed to the failed tool; used for mutation safety and corrections."),context:je.record(je.string(),je.unknown()).optional().describe("Optional structured facts such as selection state, resolvedPath, correctedInput, capability results, or recent observations.")}),async execute(e,t){let n=$s(e,t.tools);return{data:n,summary:`Classified ${e.toolName} as ${n.cause} (${Math.round(n.confidence*100)}% confidence).`}}});import{z as Le}from"zod";var Os=["workspace","playerGui","backpack","character"],qs=["character","camera","gui","nearby","interactables","tools"];function Gs(e){return"{ "+e.map(t=>s(t)).join(", ")+" }"}function Cn(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)?e:void 0}function Du(e){let t=Cn(e);if(!t)return"World observation completed.";if(typeof t.error=="string")return"World observation could not complete: "+t.error;let n=Cn(t.scanned),r=Cn(t.returned),a=Cn(t.truncated),o=Cn(t.character),i=typeof n?.instances=="number"?n.instances:0,l=typeof r?.entities=="number"?r.entities:0,c=a?.instances===!0||a?.results===!0,d=typeof o?.status=="string"?o.status:"unknown";return"Observed "+l+" semantic entities from "+i+" bounded instance reads; character="+d+(c?"; output was truncated by caller limits.":".")}var Ds=u({name:"observe-world",title:"Observe the live world and build semantic entity handles",description:"Perform one bounded, read-only Luau observation that fuses the active or custom character rig, current camera, visible PlayerGui objects, nearby 3D parts, ClickDetectors, ProximityPrompts, TouchTransmitters, and Tool instances in the Backpack or character. It returns compact evidence, exact GetFullName paths plus executable bracket-safe Luau expressions, screen position and distance where available, exact scanned/truncation counts, and stable session-local handles. Handles are retained in getgenv().__mcp_world_brain using weak references when supported and structural fingerprints for later resolve-entity calls. The walk uses GetChildren with hard instance/result caps; it never starts frame loops or performs an unbounded GetDescendants scan.",category:"Intelligence",mutatesState:!1,ai:{phase:"observe",prerequisites:["active-client"],consumes:["goal","optional spatial scope","optional feature selection"],produces:["bounded-world-model","semantic-entity-handles","actionable-instance-expressions","custom-character-resolution","camera-state","visible-gui","nearby-3d-entities","interaction-targets","inventory-tools"],verifiesWith:["resolve-entity"],alternatives:["discover-character","search-instances","list-gui-elements","get-instance-tree"],requiresCapabilities:[],sideEffects:[],failureRecovery:["If handle storage is unavailable, use each entity.expression directly.","If character.status is missing, inspect character.reason and widen roots to include workspace and character.","If truncated.instances is true, narrow roots or radius before increasing maxInstances.","Resolve a handle immediately before a mutating action when the world may have changed."]},input:Le.object({radius:Le.number().finite().positive().max(1e4).optional().default(250).describe("Maximum distance in studs for nearby 3D objects and interactables. Distance uses the resolved character root, then the character pivot, then the camera position."),roots:Le.array(Le.enum(Os)).min(1).max(Os.length).optional().default(["workspace","playerGui","backpack","character"]).describe("Bounded traversal roots. Omit a root to avoid scanning that domain; custom rigs generally require workspace."),features:Le.array(Le.enum(qs)).min(1).max(qs.length).optional().default(["character","camera","gui","nearby","interactables","tools"]).describe("Observation features to include. Character and camera probes are cheap; GUI, nearby, interactables, and tools are collected only from the selected bounded roots."),maxInstances:Le.number().int().positive().max(1e4).optional().default(2500).describe("Hard maximum number of unique Instances examined across all selected roots."),maxResults:Le.number().int().positive().max(1e3).optional().default(250).describe("Maximum ranked semantic entities returned. Exact candidate counts and result truncation are still reported."),threadContext:Le.number().int().optional()}),async execute({radius:e,roots:t,features:n,maxInstances:r,maxResults:a,threadContext:o},i){let l=Math.min(Math.max(e,1),1e4),c=Math.min(Math.max(Math.floor(r),1),1e4),d=Math.min(Math.max(Math.floor(a),1),1e3),p=String(i.session.id),f=`
local RADIUS = ${l}
local MAX_INSTANCES = ${c}
local MAX_RESULTS = ${d}
local SESSION_KEY = ${s(p)}
local ROOT_LIST = ${Gs([...new Set(t)])}
local FEATURE_LIST = ${Gs([...new Set(n)])}
local NOW = os.clock()

local ROOTS = {}
for _, name in ipairs(ROOT_LIST) do ROOTS[name] = true end
local FEATURES = {}
for _, name in ipairs(FEATURE_LIST) do FEATURES[name] = true end

local function safeService(name)
  local ok, value = pcall(function() return game:GetService(name) end)
  if ok and typeof(value) == "Instance" then return value end
  return nil
end

local function safeName(instance)
  local ok, value = pcall(function() return instance.Name end)
  return ok and tostring(value) or "<unknown>"
end

local function safeClass(instance)
  local ok, value = pcall(function() return instance.ClassName end)
  return ok and tostring(value) or "<unknown>"
end

local function safeParent(instance)
  local ok, value = pcall(function() return instance.Parent end)
  return ok and value or nil
end

local function pathOf(instance)
  local ok, value = pcall(function() return instance:GetFullName() end)
  return ok and tostring(value) or tostring(instance)
end

local function quoted(value)
  local ok, encoded = pcall(string.format, "%q", tostring(value))
  return ok and encoded or [["<unquotable>"]]
end

-- Produces an expression that remains valid for names containing spaces, dots,
-- quotes, or Lua keywords. This is the path follow-up tools should consume.
local function expressionOf(instance)
  if instance == game then return "game" end
  local chain = {}
  local current = instance
  for _ = 1, 128 do
    if current == nil or current == game then break end
    chain[#chain + 1] = current
    current = safeParent(current)
  end
  if current ~= game or #chain == 0 then return nil end

  local top = chain[#chain]
  local topClass = safeClass(top)
  local expression = nil
  local okService, service = pcall(function() return game:GetService(topClass) end)
  if okService and service == top then
    expression = "game:GetService(" .. quoted(topClass) .. ")"
  else
    expression = "game[" .. quoted(safeName(top)) .. "]"
  end
  for index = #chain - 1, 1, -1 do
    expression = expression .. "[" .. quoted(safeName(chain[index])) .. "]"
  end
  return expression
end

local function isA(instance, className)
  local ok, value = pcall(function() return instance:IsA(className) end)
  return ok and value == true
end

local function numberProperty(instance, property)
  local ok, value = pcall(function() return instance[property] end)
  return ok and type(value) == "number" and value or nil
end

local function stringProperty(instance, property)
  local ok, value = pcall(function() return instance[property] end)
  return ok and type(value) == "string" and value or nil
end

local function booleanProperty(instance, property)
  local ok, value = pcall(function() return instance[property] end)
  return ok and type(value) == "boolean" and value or nil
end

local function vector3(value)
  if typeof(value) ~= "Vector3" then return nil end
  return {
    x = math.floor(value.X * 100 + 0.5) / 100,
    y = math.floor(value.Y * 100 + 0.5) / 100,
    z = math.floor(value.Z * 100 + 0.5) / 100,
  }
end

local function vector2(value)
  if typeof(value) ~= "Vector2" then return nil end
  return {
    x = math.floor(value.X * 100 + 0.5) / 100,
    y = math.floor(value.Y * 100 + 0.5) / 100,
  }
end

local function ancestorModel(instance)
  local current = instance
  for _ = 1, 12 do
    if current == nil then return nil end
    if isA(current, "Model") then return current end
    current = safeParent(current)
  end
  return nil
end

local function ancestorBasePart(instance)
  local current = instance
  for _ = 1, 12 do
    if current == nil then return nil end
    if isA(current, "BasePart") then return current end
    current = safeParent(current)
  end
  return nil
end

local function positionOf(instance)
  if instance == nil then return nil end
  if isA(instance, "BasePart") then
    local ok, value = pcall(function() return instance.Position end)
    if ok and typeof(value) == "Vector3" then return value end
  end
  if isA(instance, "Attachment") then
    local ok, value = pcall(function() return instance.WorldPosition end)
    if ok and typeof(value) == "Vector3" then return value end
  end
  if isA(instance, "Model") then
    local ok, value = pcall(function() return instance:GetPivot().Position end)
    if ok and typeof(value) == "Vector3" then return value end
  end
  local part = ancestorBasePart(instance)
  if part and part ~= instance then return positionOf(part) end
  return nil
end

local function fingerprintOf(instance, rootLabel)
  local parent = safeParent(instance)
  local grandparent = parent and safeParent(parent) or nil
  local className = safeClass(instance)
  local name = safeName(instance)
  local parentClass = parent and safeClass(parent) or nil
  local parentName = parent and safeName(parent) or nil
  local grandparentClass = grandparent and safeClass(grandparent) or nil
  local grandparentName = grandparent and safeName(grandparent) or nil
  local path = pathOf(instance)
  local expression = expressionOf(instance)
  return {
    class = className,
    name = name,
    parentClass = parentClass,
    parentName = parentName,
    grandparentClass = grandparentClass,
    grandparentName = grandparentName,
    root = rootLabel,
    path = path,
    expression = expression,
    signature = table.concat({
      className,
      name,
      tostring(parentClass),
      tostring(parentName),
      tostring(grandparentClass),
      tostring(grandparentName),
    }, "|"),
  }
end

local function ensureBrain()
  if type(getgenv) ~= "function" then
    return nil, "getgenv is unavailable; semantic handles are disabled."
  end
  local okEnv, env = pcall(getgenv)
  if not okEnv or type(env) ~= "table" then
    return nil, "getgenv did not return a writable table; semantic handles are disabled."
  end

  local store = env.__mcp_world_brain
  if type(store) ~= "table" or store.version ~= 1 then
    store = { version = 1, sessions = {} }
    env.__mcp_world_brain = store
  end
  if type(store.sessions) ~= "table" then store.sessions = {} end

  -- Expire other inactive MCP sessions so getgenv never grows forever.
  for key, session in pairs(store.sessions) do
    if key ~= SESSION_KEY and type(session) == "table" then
      local lastTouched = tonumber(session.lastTouched) or NOW
      if NOW - lastTouched > 3600 then store.sessions[key] = nil end
    end
  end

  local brain = store.sessions[SESSION_KEY]
  if type(brain) ~= "table" then
    brain = {
      nextId = 0,
      refs = {},
      reverse = {},
      meta = {},
      createdAt = NOW,
    }
    store.sessions[SESSION_KEY] = brain
  end
  if type(brain.refs) ~= "table" then brain.refs = {} end
  if type(brain.reverse) ~= "table" then brain.reverse = {} end
  if type(brain.meta) ~= "table" then brain.meta = {} end

  local weakValues = pcall(function() setmetatable(brain.refs, { __mode = "v" }) end)
  local weakKeys = pcall(function() setmetatable(brain.reverse, { __mode = "k" }) end)
  brain.weakReferences = weakValues and weakKeys
  brain.lastTouched = NOW

  -- Keep fingerprints briefly after an Instance dies so resolve-entity can
  -- rediscover replacements, then prune old stale metadata safely.
  local stale = {}
  for handle, meta in pairs(brain.meta) do
    if brain.refs[handle] == nil then
      local lastSeen = type(meta) == "table" and tonumber(meta.lastSeen) or 0
      if NOW - lastSeen > 900 then
        stale[#stale + 1] = { handle = handle, lastSeen = lastSeen }
      end
    end
  end
  table.sort(stale, function(a, b) return a.lastSeen < b.lastSeen end)
  for _, entry in ipairs(stale) do
    brain.meta[entry.handle] = nil
    brain.refs[entry.handle] = nil
  end
  return brain, nil
end

local brain, brainError = ensureBrain()

local function registerHandle(instance, rootLabel, confidence)
  if brain == nil or instance == nil then return nil, fingerprintOf(instance, rootLabel) end
  local handle = brain.reverse[instance]
  if type(handle) ~= "string" or type(brain.meta[handle]) ~= "table" then
    brain.nextId = (tonumber(brain.nextId) or 0) + 1
    handle = "wb:" .. tostring(brain.nextId)
  end
  local fingerprint = fingerprintOf(instance, rootLabel)
  brain.refs[handle] = instance
  brain.reverse[instance] = handle
  brain.meta[handle] = {
    fingerprint = fingerprint,
    confidence = confidence,
    firstSeen = brain.meta[handle] and brain.meta[handle].firstSeen or NOW,
    lastSeen = NOW,
  }
  return handle, fingerprint
end

local Players = safeService("Players")
local Workspace = safeService("Workspace")
local localPlayer = nil
if Players then pcall(function() localPlayer = Players.LocalPlayer end) end

local standardCharacter = nil
local playerGui = nil
local backpack = nil
if localPlayer then
  pcall(function() standardCharacter = localPlayer.Character end)
  pcall(function() playerGui = localPlayer:FindFirstChildOfClass("PlayerGui") end)
  pcall(function() backpack = localPlayer:FindFirstChildOfClass("Backpack") end)
end

local camera = nil
if Workspace then pcall(function() camera = Workspace.CurrentCamera end) end
local cameraSubject = nil
if camera then pcall(function() cameraSubject = camera.CameraSubject end) end
local cameraModel = cameraSubject and ancestorModel(cameraSubject) or nil

local missing = {}
local function missingValue(name, reason)
  missing[#missing + 1] = { name = name, reason = reason }
end
if not Players then missingValue("Players", "service unavailable") end
if not localPlayer then missingValue("LocalPlayer", "not available") end
if not Workspace then missingValue("Workspace", "service unavailable") end
if FEATURES.camera and not camera then missingValue("CurrentCamera", "not available") end
if FEATURES.gui and not playerGui then missingValue("PlayerGui", "not available") end
if FEATURES.tools and not backpack then missingValue("Backpack", "not available") end

local queue = {}
local queueRoots = setmetatable({}, { __mode = "k" })
local function addRoot(instance, label)
  if instance == nil or queueRoots[instance] then return end
  queueRoots[instance] = true
  queue[#queue + 1] = { instance = instance, root = label }
end
if ROOTS.workspace then addRoot(Workspace, "workspace") end
if ROOTS.playerGui then addRoot(playerGui, "playerGui") end
if ROOTS.backpack then addRoot(backpack, "backpack") end
if ROOTS.character then addRoot(standardCharacter, "character") end

local rigList = {}
local rigByModel = setmetatable({}, { __mode = "k" })
local function rigFor(model)
  if model == nil then return nil end
  local rig = rigByModel[model]
  if rig == nil then
    rig = { model = model }
    rigByModel[model] = rig
    rigList[#rigList + 1] = rig
  end
  return rig
end
if standardCharacter then rigFor(standardCharacter).standard = true end
if cameraModel then rigFor(cameraModel).cameraSubject = true end

local guiInstances = {}
local spatialInstances = {}
local interactableInstances = {}
local toolInstances = {}
local seenScan = setmetatable({}, { __mode = "k" })
local scannedByRoot = {}
local scanned = 0
local queueTruncated = false

local function rootLikeName(name)
  return name == "HumanoidRootPart" or name == "RootPart" or name == "LowerTorso" or name == "Torso"
end

local head = 1
while head <= #queue and scanned < MAX_INSTANCES do
  local entry = queue[head]
  head = head + 1
  local instance = entry.instance
  if instance ~= nil and not seenScan[instance] then
    seenScan[instance] = true
    scanned = scanned + 1
    scannedByRoot[entry.root] = (scannedByRoot[entry.root] or 0) + 1

    if isA(instance, "Model") then
      local name = safeName(instance)
      if instance == standardCharacter or instance == cameraModel or (localPlayer and name == safeName(localPlayer)) then
        rigFor(instance)
      end
    end

    if isA(instance, "Humanoid") then
      local model = ancestorModel(instance)
      local rig = rigFor(model)
      if rig then rig.humanoid = instance end
    elseif isA(instance, "BasePart") then
      spatialInstances[#spatialInstances + 1] = { instance = instance, root = entry.root }
      local model = ancestorModel(instance)
      local rig = rigByModel[model]
      local name = safeName(instance)
      if rig == nil and rootLikeName(name) then rig = rigFor(model) end
      if rig then
        if rig.firstPart == nil then rig.firstPart = instance end
        if rootLikeName(name) then rig.rootPart = instance end
        local okPrimary, primary = pcall(function() return model.PrimaryPart end)
        if okPrimary and primary == instance and rig.rootPart == nil then rig.primaryPart = instance end
      end
    end

    if FEATURES.gui and entry.root == "playerGui" and isA(instance, "GuiObject") then
      guiInstances[#guiInstances + 1] = { instance = instance, root = entry.root }
    end
    if FEATURES.interactables and (
      isA(instance, "ClickDetector") or
      isA(instance, "ProximityPrompt") or
      isA(instance, "TouchTransmitter")
    ) then
      interactableInstances[#interactableInstances + 1] = { instance = instance, root = entry.root }
    end
    if FEATURES.tools and isA(instance, "Tool") then
      toolInstances[#toolInstances + 1] = { instance = instance, root = entry.root }
    end

    local okChildren, children = pcall(function() return instance:GetChildren() end)
    if okChildren and type(children) == "table" then
      for _, child in ipairs(children) do
        if #queue >= MAX_INSTANCES then
          queueTruncated = true
          break
        end
        queue[#queue + 1] = { instance = child, root = entry.root }
      end
    end
  end
end
if head <= #queue then queueTruncated = true end

local bestRig = nil
local bestRigScore = -1
for _, rig in ipairs(rigList) do
  if rig.rootPart == nil then rig.rootPart = rig.primaryPart or rig.firstPart end
  local score = 0
  if rig.standard then score = score + 100 end
  if rig.cameraSubject then score = score + 85 end
  if localPlayer and safeName(rig.model) == safeName(localPlayer) then score = score + 45 end
  if rig.humanoid then score = score + 35 end
  if rig.rootPart then score = score + 25 end
  if score > bestRigScore then
    bestRig = rig
    bestRigScore = score
  end
end

local characterModel = bestRig and bestRig.model or standardCharacter
local humanoid = bestRig and bestRig.humanoid or nil
local rootPart = bestRig and bestRig.rootPart or nil
local characterConfidence = 0
local characterSource = nil
if bestRig then
  if bestRig.standard then
    characterConfidence = (humanoid and rootPart) and 1 or 0.82
    characterSource = "Players.LocalPlayer.Character"
  elseif bestRig.cameraSubject then
    characterConfidence = (humanoid and rootPart) and 0.94 or 0.78
    characterSource = "CurrentCamera.CameraSubject"
  else
    characterConfidence = math.min(0.9, math.max(0.45, bestRigScore / 180))
    characterSource = "bounded structural rig search"
  end
end

local cameraPosition = nil
local cameraLookVector = nil
if camera then
  pcall(function()
    cameraPosition = camera.CFrame.Position
    cameraLookVector = camera.CFrame.LookVector
  end)
end
local origin = positionOf(rootPart) or positionOf(characterModel) or cameraPosition
local originSource = rootPart and "character-root" or (characterModel and "character-pivot" or (cameraPosition and "camera" or nil))

local function distanceFromOrigin(instance)
  if origin == nil then return nil end
  local position = positionOf(instance)
  if position == nil then return nil end
  return (position - origin).Magnitude
end

local function guiVisible(instance)
  local current = instance
  for _ = 1, 32 do
    if current == nil or current == playerGui then break end
    if isA(current, "GuiObject") then
      local visible = booleanProperty(current, "Visible")
      if visible == false then return false end
    elseif isA(current, "LayerCollector") then
      local enabled = booleanProperty(current, "Enabled")
      if enabled == false then return false end
    end
    current = safeParent(current)
  end
  return true
end

local function screenEvidence(instance)
  if isA(instance, "GuiObject") then
    local okPosition, absolutePosition = pcall(function() return instance.AbsolutePosition end)
    local okSize, absoluteSize = pcall(function() return instance.AbsoluteSize end)
    if okPosition and okSize and typeof(absolutePosition) == "Vector2" and typeof(absoluteSize) == "Vector2" then
      return {
        x = math.floor((absolutePosition.X + absoluteSize.X / 2) * 10 + 0.5) / 10,
        y = math.floor((absolutePosition.Y + absoluteSize.Y / 2) * 10 + 0.5) / 10,
        size = vector2(absoluteSize),
        onScreen = guiVisible(instance),
      }
    end
  elseif camera then
    local position = positionOf(instance)
    if position then
      local okProjection, projected, onScreen = pcall(function()
        local point, visible = camera:WorldToViewportPoint(position)
        return point, visible
      end)
      if okProjection and typeof(projected) == "Vector3" then
        return {
          x = math.floor(projected.X * 10 + 0.5) / 10,
          y = math.floor(projected.Y * 10 + 0.5) / 10,
          depth = math.floor(projected.Z * 100 + 0.5) / 100,
          onScreen = onScreen == true,
        }
      end
    end
  end
  return nil
end

local candidates = {}
local candidateByInstance = setmetatable({}, { __mode = "k" })
local roleCounts = {}
local function consider(instance, role, score, rootLabel, detail)
  if instance == nil then return end
  local candidate = candidateByInstance[instance]
  if candidate == nil then
    candidate = {
      instance = instance,
      roles = {},
      details = {},
      score = score,
      root = rootLabel,
    }
    candidateByInstance[instance] = candidate
    candidates[#candidates + 1] = candidate
  end
  if not candidate.roles[role] then
    candidate.roles[role] = true
    roleCounts[role] = (roleCounts[role] or 0) + 1
  end
  candidate.details[role] = detail
  if score > candidate.score then
    candidate.score = score
    candidate.root = rootLabel
  end
end

if FEATURES.camera and camera then
  consider(camera, "camera", 1000, "workspace", {
    fieldOfView = numberProperty(camera, "FieldOfView"),
    viewportSize = (function()
      local ok, value = pcall(function() return camera.ViewportSize end)
      return ok and vector2(value) or nil
    end)(),
    subjectPath = cameraSubject and pathOf(cameraSubject) or nil,
  })
end

if FEATURES.character and characterModel then
  consider(characterModel, "character", 990, "character", {
    source = characterSource,
    custom = characterModel ~= standardCharacter,
    complete = humanoid ~= nil and rootPart ~= nil,
  })
  if humanoid then
    consider(humanoid, "humanoid", 985, "character", {
      health = numberProperty(humanoid, "Health"),
      maxHealth = numberProperty(humanoid, "MaxHealth"),
    })
  end
  if rootPart then
    consider(rootPart, "character-root", 980, "character", {
      position = vector3(positionOf(rootPart)),
    })
  end
end

if FEATURES.gui then
  for _, entry in ipairs(guiInstances) do
    local instance = entry.instance
    if guiVisible(instance) then
      local detail = {
        text = stringProperty(instance, "Text"),
        active = booleanProperty(instance, "Active"),
        selectable = booleanProperty(instance, "Selectable"),
      }
      if isA(instance, "GuiButton") then
        detail.action = { tool = "click-button", input = { path = expressionOf(instance) } }
      elseif isA(instance, "TextBox") then
        detail.action = { tool = "type-text-box", input = { path = expressionOf(instance) } }
      end
      local priority = detail.action and 830 or (detail.text and 760 or 700)
      consider(instance, "visible-gui", priority, entry.root, detail)
    end
  end
end

if FEATURES.interactables then
  for _, entry in ipairs(interactableInstances) do
    local instance = entry.instance
    local distance = distanceFromOrigin(instance)
    if distance == nil or distance <= RADIUS then
      local detail = { distance = distance }
      if isA(instance, "ClickDetector") then
        detail.action = { tool = "fire-click-detector", input = { path = expressionOf(instance) } }
        detail.maxActivationDistance = numberProperty(instance, "MaxActivationDistance")
      elseif isA(instance, "ProximityPrompt") then
        detail.action = { tool = "fire-proximity-prompt", input = { path = expressionOf(instance) } }
        detail.actionText = stringProperty(instance, "ActionText")
        detail.objectText = stringProperty(instance, "ObjectText")
        detail.enabled = booleanProperty(instance, "Enabled")
        detail.holdDuration = numberProperty(instance, "HoldDuration")
        detail.maxActivationDistance = numberProperty(instance, "MaxActivationDistance")
      else
        detail.action = {
          tool = "script",
          note = "Resolve the handle, find a local character part, then use firetouchinterest if supported.",
        }
      end
      consider(instance, "interactable", 930 - math.min(distance or 0, RADIUS) / math.max(RADIUS, 1) * 40, entry.root, detail)
    end
  end
end

if FEATURES.tools then
  for _, entry in ipairs(toolInstances) do
    local instance = entry.instance
    local parent = safeParent(instance)
    consider(instance, "tool", 880, entry.root, {
      equipped = characterModel ~= nil and parent == characterModel,
      toolTip = stringProperty(instance, "ToolTip"),
      enabled = booleanProperty(instance, "Enabled"),
      canBeDropped = booleanProperty(instance, "CanBeDropped"),
    })
  end
end

if FEATURES.nearby then
  for _, entry in ipairs(spatialInstances) do
    local instance = entry.instance
    local distance = distanceFromOrigin(instance)
    if distance == nil or distance <= RADIUS then
      consider(instance, "nearby-3d", 600 - math.min(distance or 0, RADIUS) / math.max(RADIUS, 1) * 100, entry.root, {
        distance = distance,
        position = vector3(positionOf(instance)),
        anchored = booleanProperty(instance, "Anchored"),
        canCollide = booleanProperty(instance, "CanCollide"),
      })
    end
  end
end

table.sort(candidates, function(a, b)
  if a.score ~= b.score then return a.score > b.score end
  return pathOf(a.instance) < pathOf(b.instance)
end)

local function describe(instance, candidate, confidenceOverride)
  local roles = {}
  for role in pairs(candidate.roles or {}) do roles[#roles + 1] = role end
  table.sort(roles)
  local confidence = confidenceOverride or math.min(0.99, math.max(0.45, candidate.score / 1000))
  local handle, fingerprint = registerHandle(instance, candidate.root, confidence)
  local distance = distanceFromOrigin(instance)
  local screen = screenEvidence(instance)
  local visible = nil
  if isA(instance, "GuiObject") then
    visible = guiVisible(instance)
  elseif screen then
    visible = screen.onScreen
  end
  return {
    handle = handle,
    path = fingerprint.path,
    expression = fingerprint.expression,
    class = fingerprint.class,
    name = fingerprint.name,
    roles = roles,
    confidence = confidence,
    fingerprint = fingerprint.signature,
    distance = distance and math.floor(distance * 100 + 0.5) / 100 or nil,
    visible = visible,
    screenPosition = screen,
    evidence = {
      root = candidate.root,
      details = candidate.details,
    },
  }
end

local entities = {}
for index = 1, math.min(MAX_RESULTS, #candidates) do
  entities[index] = describe(candidates[index].instance, candidates[index], nil)
end

local function directDescription(instance, role, rootLabel, confidence, detail)
  if instance == nil then return nil end
  return describe(instance, {
    roles = { [role] = true },
    details = { [role] = detail or {} },
    root = rootLabel,
    score = confidence * 1000,
  }, confidence)
end

local characterResult = {
  status = characterModel and ((humanoid and rootPart) and "resolved" or "partial") or "missing",
  player = localPlayer and safeName(localPlayer) or nil,
  source = characterSource,
  confidence = characterConfidence,
  custom = characterModel ~= nil and characterModel ~= standardCharacter or false,
  standardPath = standardCharacter and pathOf(standardCharacter) or nil,
  reason = characterModel and nil or "No standard, camera-subject, or bounded structural rig candidate was found.",
  model = directDescription(characterModel, "character", "character", characterConfidence, {
    source = characterSource,
  }),
  humanoid = directDescription(humanoid, "humanoid", "character", characterConfidence, nil),
  rootPart = directDescription(rootPart, "character-root", "character", characterConfidence, nil),
}

local cameraResult = {
  status = camera and "resolved" or "missing",
  entity = directDescription(camera, "camera", "workspace", camera and 1 or 0, nil),
  position = vector3(cameraPosition),
  lookVector = vector3(cameraLookVector),
  fieldOfView = camera and numberProperty(camera, "FieldOfView") or nil,
  subjectPath = cameraSubject and pathOf(cameraSubject) or nil,
}

local storedHandles = 0
if brain then
  for _ in pairs(brain.meta) do storedHandles = storedHandles + 1 end
end

return {
  ok = true,
  observedAt = NOW,
  limits = {
    radius = RADIUS,
    maxInstances = MAX_INSTANCES,
    maxResults = MAX_RESULTS,
    roots = ROOT_LIST,
    features = FEATURE_LIST,
  },
  origin = {
    source = originSource,
    position = vector3(origin),
  },
  character = characterResult,
  camera = cameraResult,
  entities = entities,
  scanned = {
    instances = scanned,
    queued = #queue,
    roots = #ROOT_LIST,
    byRoot = scannedByRoot,
  },
  returned = {
    entities = #entities,
    candidates = #candidates,
    byRole = roleCounts,
  },
  truncated = {
    instances = queueTruncated,
    results = #candidates > MAX_RESULTS,
  },
  handles = {
    enabled = brain ~= nil,
    session = SESSION_KEY,
    stored = storedHandles,
    weakReferences = brain and brain.weakReferences == true or false,
    error = brainError,
  },
  missing = missing,
}
`,h=await i.runLuau(f,{timeoutMs:3e4,...o!==void 0?{threadContext:o}:{}});return{data:h,summary:Du(h)}}});import{z as We}from"zod";var Us=["workspace","playerGui","backpack","character"];function Uu(e){return"{ "+e.map(t=>s(t)).join(", ")+" }"}function ju(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)?e:void 0}function Wu(e,t){let n=ju(t);if(!n)return"Entity resolution completed for "+e+".";let r=typeof n.status=="string"?n.status:"unknown",a=typeof n.path=="string"?n.path:void 0,o=typeof n.confidence=="number"?" at confidence "+n.confidence.toFixed(2):"";return a?"Entity "+e+" is "+r+" at "+a+o+".":"Entity "+e+" is "+r+o+"; no live path was resolved."}var js=u({name:"resolve-entity",title:"Resolve or rediscover a semantic world handle",description:"Resolve a session-local handle returned by observe-world back to its live Roblox Instance. A live weak reference resolves immediately. If it is stale or destroyed, optional bounded rediscovery scores candidates against the stored structural fingerprint (class, name, parent, grandparent, original path, and root) and reattaches the same handle when confidence clears the requested threshold. Returns an exact path and executable bracket-safe expression, class, confidence, staleness state, match evidence, runner-up ambiguity, scan counts, and truncation. Read-only; uses GetChildren with a hard cap and never performs GetDescendants or a frame loop.",category:"Intelligence",mutatesState:!1,ai:{phase:"verify",prerequisites:["active-client","semantic handle previously returned by observe-world"],consumes:["semantic-entity-handle","optional rediscovery scope"],produces:["live-instance-path","actionable-instance-expression","staleness-status","structural-match-confidence","resolution-evidence"],verifiesWith:[],alternatives:["observe-world","search-instances","verify-path-exists"],requiresCapabilities:[],sideEffects:[],failureRecovery:["If status is unknown-handle or brain-unavailable, call observe-world in the same MCP session.","If status is stale, widen roots or maxInstances and retry rediscovery once.","If evidence reports ambiguity, call observe-world with a narrower root or use search-instances before acting.","Use expression rather than path for follow-up tools when names contain punctuation or spaces."]},input:We.object({handle:We.string().min(1).max(200).describe("Session-local entity handle returned by observe-world, for example 'wb:12'."),rediscover:We.boolean().optional().default(!0).describe("When true, a stale weak reference triggers bounded structural rediscovery. False only reports staleness."),roots:We.array(We.enum(Us)).min(1).max(Us.length).optional().default(["workspace","playerGui","backpack","character"]).describe("Roots searched when rediscovering a stale handle."),maxInstances:We.number().int().positive().max(1e4).optional().default(2500).describe("Hard maximum number of unique instances examined during rediscovery."),minConfidence:We.number().finite().min(0).max(1).optional().default(.45).describe("Minimum adjusted fingerprint confidence required to reattach a stale handle. Ambiguous runner-up matches reduce confidence."),threadContext:We.number().int().optional()}),async execute({handle:e,rediscover:t,roots:n,maxInstances:r,minConfidence:a,threadContext:o},i){let l=Math.min(Math.max(Math.floor(r),1),1e4),c=Math.min(Math.max(a,0),1),d=String(i.session.id),p=`
local HANDLE = ${s(e)}
local SESSION_KEY = ${s(d)}
local REDISCOVER = ${t?"true":"false"}
local MAX_INSTANCES = ${l}
local MIN_CONFIDENCE = ${c}
local ROOT_LIST = ${Uu([...new Set(n)])}
local NOW = os.clock()

local function safeService(name)
  local ok, value = pcall(function() return game:GetService(name) end)
  if ok and typeof(value) == "Instance" then return value end
  return nil
end

local function safeName(instance)
  local ok, value = pcall(function() return instance.Name end)
  return ok and tostring(value) or "<unknown>"
end

local function safeClass(instance)
  local ok, value = pcall(function() return instance.ClassName end)
  return ok and tostring(value) or "<unknown>"
end

local function safeParent(instance)
  local ok, value = pcall(function() return instance.Parent end)
  return ok and value or nil
end

local function pathOf(instance)
  local ok, value = pcall(function() return instance:GetFullName() end)
  return ok and tostring(value) or tostring(instance)
end

local function quoted(value)
  local ok, encoded = pcall(string.format, "%q", tostring(value))
  return ok and encoded or [["<unquotable>"]]
end

local function expressionOf(instance)
  if instance == game then return "game" end
  local chain = {}
  local current = instance
  for _ = 1, 128 do
    if current == nil or current == game then break end
    chain[#chain + 1] = current
    current = safeParent(current)
  end
  if current ~= game or #chain == 0 then return nil end

  local top = chain[#chain]
  local topClass = safeClass(top)
  local expression = nil
  local okService, service = pcall(function() return game:GetService(topClass) end)
  if okService and service == top then
    expression = "game:GetService(" .. quoted(topClass) .. ")"
  else
    expression = "game[" .. quoted(safeName(top)) .. "]"
  end
  for index = #chain - 1, 1, -1 do
    expression = expression .. "[" .. quoted(safeName(chain[index])) .. "]"
  end
  return expression
end

local function fingerprintOf(instance, rootLabel)
  local parent = safeParent(instance)
  local grandparent = parent and safeParent(parent) or nil
  local className = safeClass(instance)
  local name = safeName(instance)
  local parentClass = parent and safeClass(parent) or nil
  local parentName = parent and safeName(parent) or nil
  local grandparentClass = grandparent and safeClass(grandparent) or nil
  local grandparentName = grandparent and safeName(grandparent) or nil
  return {
    class = className,
    name = name,
    parentClass = parentClass,
    parentName = parentName,
    grandparentClass = grandparentClass,
    grandparentName = grandparentName,
    root = rootLabel,
    path = pathOf(instance),
    expression = expressionOf(instance),
    signature = table.concat({
      className,
      name,
      tostring(parentClass),
      tostring(parentName),
      tostring(grandparentClass),
      tostring(grandparentName),
    }, "|"),
  }
end

local function liveInstance(value)
  if typeof(value) ~= "Instance" then return false end
  if value == game then return true end
  local ok, parent = pcall(function() return value.Parent end)
  return ok and parent ~= nil
end

local function getBrain()
  if type(getgenv) ~= "function" then
    return nil, "getgenv is unavailable."
  end
  local okEnv, env = pcall(getgenv)
  if not okEnv or type(env) ~= "table" then
    return nil, "getgenv did not return a table."
  end
  local store = env.__mcp_world_brain
  if type(store) ~= "table" or store.version ~= 1 or type(store.sessions) ~= "table" then
    return nil, "No world brain exists. Run observe-world in this session first."
  end
  local brain = store.sessions[SESSION_KEY]
  if type(brain) ~= "table" or type(brain.meta) ~= "table" or type(brain.refs) ~= "table" then
    return nil, "No world brain exists for this MCP session. Run observe-world first."
  end
  if type(brain.reverse) ~= "table" then brain.reverse = {} end
  brain.lastTouched = NOW
  return brain, nil
end

local brain, brainError = getBrain()
if brain == nil then
  return {
    ok = false,
    status = "brain-unavailable",
    handle = HANDLE,
    stale = true,
    confidence = 0,
    path = nil,
    class = nil,
    evidence = { reason = brainError },
    scanned = { instances = 0, roots = 0 },
    truncated = false,
  }
end

local metadata = brain.meta[HANDLE]
if type(metadata) ~= "table" or type(metadata.fingerprint) ~= "table" then
  return {
    ok = false,
    status = "unknown-handle",
    handle = HANDLE,
    stale = true,
    confidence = 0,
    path = nil,
    class = nil,
    evidence = { reason = "The handle is not registered in this MCP session." },
    scanned = { instances = 0, roots = 0 },
    truncated = false,
  }
end

local stored = metadata.fingerprint
local referenced = brain.refs[HANDLE]
if liveInstance(referenced) then
  local current = fingerprintOf(referenced, stored.root)
  metadata.fingerprint = current
  metadata.lastSeen = NOW
  metadata.confidence = 1
  brain.refs[HANDLE] = referenced
  brain.reverse[referenced] = HANDLE
  return {
    ok = true,
    status = "resolved-live",
    handle = HANDLE,
    stale = false,
    rediscovered = false,
    path = current.path,
    expression = current.expression,
    class = current.class,
    name = current.name,
    confidence = 1,
    evidence = {
      weakReference = "live",
      pathChanged = stored.path ~= current.path,
      previousPath = stored.path,
      fingerprint = current.signature,
    },
    scanned = { instances = 0, roots = 0 },
    truncated = false,
  }
end

if not REDISCOVER then
  return {
    ok = false,
    status = "stale",
    handle = HANDLE,
    stale = true,
    rediscovered = false,
    path = stored.path,
    expression = stored.expression,
    class = stored.class,
    name = stored.name,
    confidence = 0,
    evidence = {
      reason = "The weak reference is gone or destroyed and rediscovery was disabled.",
      fingerprint = stored.signature,
      lastSeen = metadata.lastSeen,
    },
    scanned = { instances = 0, roots = 0 },
    truncated = false,
  }
end

local Players = safeService("Players")
local Workspace = safeService("Workspace")
local localPlayer = nil
if Players then pcall(function() localPlayer = Players.LocalPlayer end) end
local character = nil
local playerGui = nil
local backpack = nil
if localPlayer then
  pcall(function() character = localPlayer.Character end)
  pcall(function() playerGui = localPlayer:FindFirstChildOfClass("PlayerGui") end)
  pcall(function() backpack = localPlayer:FindFirstChildOfClass("Backpack") end)
end

local requestedRoots = {}
for _, name in ipairs(ROOT_LIST) do requestedRoots[name] = true end
local queue = {}
local rootSeen = setmetatable({}, { __mode = "k" })
local function addRoot(instance, label)
  if instance == nil or rootSeen[instance] then return end
  rootSeen[instance] = true
  queue[#queue + 1] = { instance = instance, root = label }
end
if requestedRoots.workspace then addRoot(Workspace, "workspace") end
if requestedRoots.playerGui then addRoot(playerGui, "playerGui") end
if requestedRoots.backpack then addRoot(backpack, "backpack") end
if requestedRoots.character then addRoot(character, "character") end

local function addReason(reasons, condition, label)
  if condition then reasons[#reasons + 1] = label end
end

local function scoreCandidate(instance, rootLabel)
  local className = safeClass(instance)
  if stored.class ~= nil and className ~= stored.class then return 0, {} end

  local parent = safeParent(instance)
  local grandparent = parent and safeParent(parent) or nil
  local name = safeName(instance)
  local parentClass = parent and safeClass(parent) or nil
  local parentName = parent and safeName(parent) or nil
  local grandparentClass = grandparent and safeClass(grandparent) or nil
  local grandparentName = grandparent and safeName(grandparent) or nil
  local path = pathOf(instance)
  local score = stored.class == className and 0.24 or 0
  local reasons = {}
  addReason(reasons, stored.class == className, "class")
  if stored.name == name then score = score + 0.25; reasons[#reasons + 1] = "name" end
  if stored.parentClass == parentClass then score = score + 0.08; reasons[#reasons + 1] = "parent-class" end
  if stored.parentName == parentName then score = score + 0.12; reasons[#reasons + 1] = "parent-name" end
  if stored.grandparentClass == grandparentClass then score = score + 0.05; reasons[#reasons + 1] = "grandparent-class" end
  if stored.grandparentName == grandparentName then score = score + 0.08; reasons[#reasons + 1] = "grandparent-name" end
  if stored.root == rootLabel then score = score + 0.05; reasons[#reasons + 1] = "root" end
  if stored.path == path then score = 1; reasons[#reasons + 1] = "exact-path" end
  return math.min(score, 1), reasons
end

local best = nil
local second = nil
local seen = setmetatable({}, { __mode = "k" })
local scanned = 0
local head = 1
local queueTruncated = false
while head <= #queue and scanned < MAX_INSTANCES do
  local entry = queue[head]
  head = head + 1
  local instance = entry.instance
  if instance ~= nil and not seen[instance] then
    seen[instance] = true
    scanned = scanned + 1
    local score, reasons = scoreCandidate(instance, entry.root)
    if score > 0 then
      local candidate = {
        instance = instance,
        root = entry.root,
        score = score,
        reasons = reasons,
      }
      if best == nil or score > best.score then
        second = best
        best = candidate
      elseif second == nil or score > second.score then
        second = candidate
      end
    end

    local okChildren, children = pcall(function() return instance:GetChildren() end)
    if okChildren and type(children) == "table" then
      for _, child in ipairs(children) do
        if #queue >= MAX_INSTANCES then
          queueTruncated = true
          break
        end
        queue[#queue + 1] = { instance = child, root = entry.root }
      end
    end
  end
end
if head <= #queue then queueTruncated = true end

local rawConfidence = best and best.score or 0
local runnerUpConfidence = second and second.score or 0
local margin = rawConfidence - runnerUpConfidence
local adjustedConfidence = rawConfidence
local ambiguous = second ~= nil and margin < 0.08
if ambiguous then adjustedConfidence = adjustedConfidence * 0.72 end

if best and adjustedConfidence >= MIN_CONFIDENCE then
  local current = fingerprintOf(best.instance, best.root)
  brain.refs[HANDLE] = best.instance
  brain.reverse[best.instance] = HANDLE
  metadata.fingerprint = current
  metadata.lastSeen = NOW
  metadata.confidence = adjustedConfidence
  return {
    ok = true,
    status = "rediscovered",
    handle = HANDLE,
    stale = false,
    rediscovered = true,
    path = current.path,
    expression = current.expression,
    class = current.class,
    name = current.name,
    confidence = adjustedConfidence,
    evidence = {
      matched = best.reasons,
      previousPath = stored.path,
      fingerprint = current.signature,
      rawConfidence = rawConfidence,
      runnerUpConfidence = runnerUpConfidence,
      margin = margin,
      ambiguous = ambiguous,
    },
    scanned = { instances = scanned, roots = #ROOT_LIST },
    truncated = queueTruncated,
  }
end

local bestFingerprint = best and fingerprintOf(best.instance, best.root) or nil
return {
  ok = false,
  status = "stale",
  handle = HANDLE,
  stale = true,
  rediscovered = false,
  path = stored.path,
  expression = stored.expression,
  class = stored.class,
  name = stored.name,
  confidence = adjustedConfidence,
  evidence = {
    reason = best and "Best structural match did not clear minConfidence." or "No same-class candidate was found.",
    fingerprint = stored.signature,
    bestCandidate = bestFingerprint and {
      path = bestFingerprint.path,
      expression = bestFingerprint.expression,
      class = bestFingerprint.class,
      name = bestFingerprint.name,
    } or nil,
    matched = best and best.reasons or {},
    rawConfidence = rawConfidence,
    runnerUpConfidence = runnerUpConfidence,
    margin = margin,
    ambiguous = ambiguous,
    minConfidence = MIN_CONFIDENCE,
  },
  scanned = { instances = scanned, roots = #ROOT_LIST },
  truncated = queueTruncated,
}
`,f=await i.runLuau(p,{timeoutMs:3e4,...o!==void 0?{threadContext:o}:{}});return{data:f,summary:Wu(e,f)}}});import{z as v}from"zod";var z=v.string().min(1).max(64).regex(/^[A-Za-z][A-Za-z0-9_-]*$/,"Use a letter followed by letters, digits, _ or -."),Q=v.string().min(1).max(500).describe("Live Instance path or an exact $steps reference resolving to one."),_t=v.string().min(1).max(128),xa=v.union([v.string(),v.number().finite(),v.boolean()]),Ws=v.discriminatedUnion("by",[v.object({by:v.literal("class"),value:v.string().min(1).max(128)}),v.object({by:v.literal("name"),value:v.string().min(1).max(256),match:v.enum(["equals","contains"]).optional().default("equals"),caseSensitive:v.boolean().optional().default(!1)}),v.object({by:v.literal("text"),value:v.string().min(1).max(1e3),match:v.enum(["equals","contains"]).optional().default("contains"),caseSensitive:v.boolean().optional().default(!1)})]),Bs=v.discriminatedUnion("kind",[v.object({id:z,kind:v.literal("path-exists"),path:Q}),v.object({id:z,kind:v.literal("path-not-exists"),path:Q}),v.object({id:z,kind:v.literal("property-equals"),path:Q,property:_t,expected:xa}),v.object({id:z,kind:v.literal("property-not-equals"),path:Q,property:_t,expected:xa}),v.object({id:z,kind:v.literal("property-contains"),path:Q,property:_t,expected:v.string().max(2e3),caseSensitive:v.boolean().optional().default(!1)}),v.object({id:z,kind:v.literal("property-greater"),path:Q,property:_t,expected:v.number().finite()}),v.object({id:z,kind:v.literal("property-less"),path:Q,property:_t,expected:v.number().finite()}),v.object({id:z,kind:v.literal("attribute-equals"),path:Q,attribute:_t,expected:xa}),v.object({id:z,kind:v.literal("gui-visible"),path:Q,expected:v.boolean().optional().default(!0),effective:v.boolean().optional().default(!0)}),v.object({id:z,kind:v.literal("gui-enabled"),path:Q,expected:v.boolean().optional().default(!0)}),v.object({id:z,kind:v.literal("descendant-exists"),path:Q,selector:Ws,expected:v.boolean().optional().default(!0)}),v.object({id:z,kind:v.literal("character-distance"),targetPath:Q,operator:v.enum(["at-most","at-least"]),distance:v.number().finite().nonnegative().max(1e6),playerName:v.string().min(1).max(64).optional(),characterPath:Q.optional(),rootPath:Q.optional()}),v.object({id:z,kind:v.literal("camera-facing"),targetPath:Q,maxAngleDegrees:v.number().finite().min(0).max(180).optional().default(10),cameraPath:Q.optional()}),v.object({id:z,kind:v.literal("collection-count"),path:Q,scope:v.enum(["children","descendants"]).optional().default("children"),operator:v.enum(["equals","not-equals","greater","less","at-least","at-most"]),count:v.number().int().nonnegative().max(1e6),selector:Ws.optional()})]),zs=v.object({type:v.literal("tool").optional().default("tool").describe("Typed step discriminator; smart-task currently executes registered tools."),id:z.describe("Globally unique step identifier for $steps references."),phase:v.enum(["observe","act","verify"]).optional().describe("Declared intent used for preview auditing; the live tool contract remains authoritative."),tool:v.string().min(1).max(128).describe("Exact registered tool name."),input:v.record(v.string(),v.unknown()).optional().default({}).describe("Typed tool input; exact values may reference prior results with $steps.<id>.<path>."),assertions:v.array(Bs).max(20).optional().default([]).describe("Semantic postconditions verified by the read-only assert-state tool."),recoverWith:v.array(z).max(8).optional().default([]).describe("Ordered, explicitly declared fallback branch IDs. No implicit retry occurs."),onFailure:v.enum(["stop","continue"]).optional().default("stop").describe("Behavior after declared recovery branches are exhausted.")}),Vu=v.object({id:z.describe("Unique branch identifier referenced by recoverWith."),when:v.enum(["tool-error","assertion-failed","blocked","any"]).optional().default("any").describe("Failure class this branch is allowed to handle."),steps:v.array(zs).min(1).max(30).describe("Explicit alternative steps; branches are used at most once per run."),resolvesAssertions:v.array(z).max(20).optional().default([]).describe("Failed assertion IDs to re-run after this branch succeeds."),resume:v.enum(["next","stop"]).optional().default("next").describe("Resume the interrupted sequence or intentionally stop after recovery.")}),Bu=v.object({maxSteps:v.number().int().positive().max(100).optional().default(20).describe("Hard cap across main and fallback steps."),maxToolCalls:v.number().int().positive().max(250).optional().default(40).describe("Hard cap including actions, assert-state, and explain-failure calls."),timeoutMs:v.number().int().min(100).max(6e5).optional().default(6e4).describe("Hard wall-clock budget for the complete task.")}),Ks=v.object({goal:v.string().min(3).max(2e3).describe("Concrete outcome the workflow must prove."),mode:v.enum(["plan","preview","execute"]).optional().default("plan").describe("Plan ranks tools, preview validates explicit steps, and execute invokes tools."),steps:v.array(zs).max(100).optional().describe("Explicit ordered workflow. Omit it for deterministic schema-aware planning."),fallbacks:v.array(Vu).max(30).optional().default([]).describe("Named recovery branches; only a step's recoverWith list can activate one."),successAssertions:v.array(Bs).max(30).optional().default([]).describe("Goal-level assertions evaluated after the main workflow."),finalRecoverWith:v.array(z).max(8).optional().default([]).describe("Explicit branches available if goal-level assertions fail."),allowMutations:v.boolean().optional().default(!1).describe("User approval gate for every tool whose contract mutates state."),budgets:Bu.optional().default({maxSteps:20,maxToolCalls:40,timeoutMs:6e4})}),ye=class extends Error{budget;constructor(t){super(`Adaptive workflow ${t} budget exhausted.`),this.budget=t}},Hs=new Set(["__proto__","prototype","constructor"]),zu=/^\$steps\.([A-Za-z][A-Za-z0-9_-]*)(?:\.([A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*))?$/;function wt(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)}function vr(e,t=new WeakSet){return typeof e=="string"?e.startsWith("$steps."):e===null||typeof e!="object"||t.has(e)?!1:(t.add(e),Array.isArray(e)?e.some(n=>vr(n,t)):Object.values(e).some(n=>vr(n,t)))}function Ku(e,t,n){if(!t)return e;let r=e;for(let a of t.split(".")){if(Hs.has(a))throw new Error(`Unsafe step reference path in "${n}".`);if(Array.isArray(r)&&/^\d+$/.test(a)){let o=Number(a);if(o>=r.length)throw new Error(`Missing step reference "${n}".`);r=r[o];continue}if(!wt(r)||!Object.prototype.hasOwnProperty.call(r,a))throw new Error(`Missing step reference "${n}".`);r=r[a]}if(r===void 0)throw new Error(`Missing step reference "${n}".`);return r}function Xs(e,t){let n=new WeakSet,r={nodes:0},a=(o,i)=>{if(r.nodes+=1,i>40||r.nodes>2e4)throw new Error("Step reference input exceeds the safe traversal limit.");if(typeof o=="string"){if(!o.startsWith("$steps."))return o;let c=zu.exec(o);if(!c)throw new Error(`Malformed step reference "${o}".`);let d=t.get(c[1]);if(d===void 0)throw new Error(`Unknown or not-yet-executed step "${c[1]}".`);return Ku(d,c[2],o)}if(o===null||typeof o!="object")return o;if(n.has(o))throw new Error("Cyclic values are not valid workflow inputs.");n.add(o);let l;if(Array.isArray(o))l=o.map(c=>a(c,i+1));else{let c={};for(let[d,p]of Object.entries(o)){if(Hs.has(d))throw new Error(`Unsafe input key "${d}".`);c[d]=a(p,i+1)}l=c}return n.delete(o),l};return a(e,0)}function _a(e,t=new WeakSet){return e===void 0?"[undefined]":e===null||typeof e!="object"?e:t.has(e)?"[cycle]":(t.add(e),Array.isArray(e)?e.map(n=>_a(n,t)):Object.fromEntries(Object.entries(e).sort(([n],[r])=>n.localeCompare(r)).map(([n,r])=>[n,_a(r,t)])))}function Hu(e,t){return`${e}:${JSON.stringify(_a(t))}`}function St(e,t=0,n=new WeakSet){return typeof e=="string"?e.length>500?`${e.slice(0,500)}...`:e:e===null||typeof e!="object"?e:t>=4?"[truncated]":n.has(e)?"[cycle]":(n.add(e),Array.isArray(e)?e.slice(0,20).map(r=>St(r,t+1,n)):Object.fromEntries(Object.entries(e).slice(0,30).map(([r,a])=>[r,St(a,t+1,n)])))}function ie(e,t){e.evidence.push({sequence:e.evidence.length+1,elapsedMs:Math.max(0,Date.now()-e.startedAt),...t})}function Et(e,t){let n=t.trim();n&&!e.recoveryRecommendations.includes(n)&&e.recoveryRecommendations.push(n)}function Vs(e){let t=de(e.input),n=t.filter(r=>!r.optional).map(r=>r.name);return{name:e.name,title:e.title,category:e.category,signature:fe(e.input),arguments:t,requiredArguments:n,input:n.length===0?{}:null,readyWithoutArguments:n.length===0,mutatesState:e.mutatesState,requiresClient:e.requiresClient,ai:e.ai}}function Xu(e,t,n){let r=new Set(t.map(l=>l.name)),a=lt(e,r).map(l=>({id:l.id,title:l.title,description:l.description,steps:l.steps.flatMap((c,d)=>{let p=t.find(f=>f.name===c.tool);return p?[{order:d+1,phase:c.phase,why:c.why,...Vs(p),blocked:p.mutatesState&&!n}]:[]})})),o=qe(e,t,12).map(l=>({...Vs(l.tool),score:Math.round(l.score*10)/10,matchedTerms:l.matchedTerms,why:l.why,blocked:l.tool.mutatesState&&!n})),i=[...a.flatMap(l=>l.steps),...o].filter(l=>l.requiredArguments.length>0).map(l=>({tool:l.name,requiredArguments:l.requiredArguments}));return{strategy:"Deterministic lexical ranking plus curated workflows; no LLM or argument invention.",workflows:a,alternatives:o,missingRequiredArguments:i,continuationPlan:i.length?["Choose a workflow or ranked tool.","Resolve every listed required argument from observation output or tool-schema.","Submit explicit typed steps in preview mode before execute mode."]:["Choose a workflow or ranked tool, then submit explicit typed steps in preview mode."]}}function Ys(e){return e.issues.slice(0,5).map(t=>`${t.path.join(".")||"input"}: ${t.message}`).join("; ")}function Yu(e,t){let n=[],r=new Set;for(let c of e.fallbacks)r.has(c.id)&&n.push({severity:"error",code:"duplicate-branch-id",branchId:c.id,message:`Fallback branch "${c.id}" is declared more than once.`}),r.add(c.id);let a=[...(e.steps??[]).map(c=>({step:c,branchId:void 0})),...e.fallbacks.flatMap(c=>c.steps.map(d=>({step:d,branchId:c.id})))],o=new Set,i=new Set;for(let{step:c,branchId:d}of a){o.has(c.id)&&n.push({severity:"error",code:"duplicate-step-id",stepId:c.id,branchId:d,message:`Step "${c.id}" must be globally unique, including fallback branches.`}),o.add(c.id);let p=t.get(c.tool);if(!p)n.push({severity:"error",code:"unknown-tool",stepId:c.id,branchId:d,message:`Tool "${c.tool}" is not registered.`});else if(p.mutatesState&&!e.allowMutations&&n.push({severity:"warning",code:"mutation-not-approved",stepId:c.id,branchId:d,message:`Step "${c.id}" is blocked until allowMutations=true.`}),c.phase&&p.ai?.phase&&c.phase!==p.ai.phase&&n.push({severity:"warning",code:"phase-mismatch",stepId:c.id,branchId:d,message:`Declared phase "${c.phase}" differs from ${c.tool}'s "${p.ai.phase}" contract.`}),!vr(c.input)){let f=p.input.safeParse(c.input);f.success||n.push({severity:"error",code:"invalid-input",stepId:c.id,branchId:d,message:Ys(f.error)})}for(let f of c.recoverWith)r.has(f)||n.push({severity:"error",code:"unknown-fallback",stepId:c.id,branchId:d,message:`recoverWith references undeclared branch "${f}".`});for(let f of c.assertions)i.has(f.id)&&n.push({severity:"error",code:"duplicate-assertion-id",stepId:c.id,branchId:d,message:`Assertion "${f.id}" must be globally unique.`}),i.add(f.id)}for(let c of e.successAssertions)i.has(c.id)&&n.push({severity:"error",code:"duplicate-assertion-id",message:`Assertion "${c.id}" must be globally unique.`}),i.add(c.id);for(let c of e.finalRecoverWith)r.has(c)||n.push({severity:"error",code:"unknown-fallback",message:`finalRecoverWith references undeclared branch "${c}".`});for(let c of e.fallbacks)for(let d of c.resolvesAssertions)i.has(d)||n.push({severity:"error",code:"unknown-assertion",branchId:c.id,message:`Branch "${c.id}" cannot recheck unknown assertion "${d}".`});if(e.successAssertions.length+a.reduce((c,d)=>c+d.step.assertions.length,0)>0){let c=t.get("assert-state");c?c.mutatesState&&n.push({severity:"error",code:"assert-state-mutates",message:"assert-state must be read-only and cannot be used as registered."}):n.push({severity:"error",code:"assert-state-unavailable",message:"Assertions require the registered read-only assert-state tool before execution."})}return(e.steps?.length??0)>e.budgets.maxSteps&&n.push({severity:"warning",code:"main-plan-exceeds-step-budget",message:`The main plan has ${e.steps?.length??0} steps but maxSteps is ${e.budgets.maxSteps}.`}),n}function Zu(e,t){let n=r=>{let a=t.get(r.tool),o=vr(r.input);return{id:r.id,type:r.type,phase:r.phase??a?.ai?.phase??(a?.mutatesState?"act":"observe"),tool:r.tool,known:a!==void 0,mutatesState:a?.mutatesState??null,mutationApproved:!a?.mutatesState||e.allowMutations,signature:a?fe(a.input):null,arguments:a?de(a.input):[],schemaValidation:o?"deferred-until-references-resolve":"checked",assertions:r.assertions.map(i=>i.id),recoverWith:r.recoverWith,onFailure:r.onFailure}};return{main:(e.steps??[]).map(n),fallbacks:e.fallbacks.map(r=>({id:r.id,when:r.when,resume:r.resume,resolvesAssertions:r.resolvesAssertions,steps:r.steps.map(n)}))}}function Zs(e){if(e.ctx.signal.aborted)throw e.budgetStop="aborted",new ye("aborted");if(Date.now()>=e.deadlineAt)throw e.budgetStop="time",new ye("time")}function Qu(e){if(Zs(e),e.stepsUsed>=e.input.budgets.maxSteps)throw e.budgetStop="steps",new ye("steps");e.stepsUsed+=1}async function Sa(e,t,n){if(Zs(e),e.toolCallsUsed>=e.input.budgets.maxToolCalls)throw e.budgetStop="tool-calls",new ye("tool-calls");e.toolCallsUsed+=1;let r=e.deadlineAt-Date.now(),a=e.ctx.invokeTool(t,n),o;try{return await Promise.race([a,new Promise((i,l)=>{o=setTimeout(()=>{e.budgetStop="time",l(new ye("time"))},Math.max(1,r))})])}finally{o&&clearTimeout(o)}}function Ju(e){if(!wt(e))return null;for(let t of["passed","satisfied","truth"])if(typeof e[t]=="boolean")return e[t];return null}function ed(e,t){let n=wt(e)?e:null,r=n&&typeof n.allPassed=="boolean"?n.allPassed:n&&typeof n.passed=="boolean"?n.passed:n&&wt(n.aggregate)&&typeof n.aggregate.passed=="boolean"?n.aggregate.passed:n&&typeof n.satisfied=="boolean"?n.satisfied:n&&typeof n.truth=="boolean"?n.truth:null,a=n?["assertions","results","checks"].map(o=>n[o]).find(o=>Array.isArray(o)):void 0;return t.map((o,i)=>{let c=a?.find(d=>wt(d)&&d.id===o.id)??a?.[i];return{id:o.id,passed:Ju(c)??r,...c===void 0?{}:{evidence:St(c)}}})}async function kr(e,t,n,r){if(n.length===0)return null;let a;try{a=n.map(d=>Xs(d,e.outputs))}catch(d){let p=d instanceof Error?d.message:String(d);for(let f of n)e.assertions.set(f.id,{id:f.id,stepId:t,assertion:f,passed:null,reason:p});return ie(e,{kind:"assertion",status:"unresolved",stepId:t,message:p}),{kind:"assertion-failed",message:p,assertionIds:n.map(({id:f})=>f)}}for(let d of a)e.resolvedAssertions.set(d.id,d);let o=e.catalog.get("assert-state");if(!o||o.mutatesState){let d=o?"assert-state is marked mutating and was refused as a verifier.":"Read-only assert-state is not registered; call success cannot verify semantic truth.";for(let p of a)e.assertions.set(p.id,{id:p.id,stepId:t,assertion:p,passed:null,reason:d});return ie(e,{kind:"assertion",status:"unavailable",stepId:t,tool:"assert-state",message:d}),Et(e,d),{kind:"assertion-failed",message:d,assertionIds:a.map(({id:p})=>p)}}let i;try{i=await Sa(e,"assert-state",{goal:e.input.goal,reason:r,stepId:t,assertions:a,references:Object.fromEntries(e.outputs)})}catch(d){let p=d instanceof Error?d.message:String(d),f=d instanceof ye?"budget":"assertion-failed";for(let h of a)e.assertions.set(h.id,{id:h.id,stepId:t,assertion:h,passed:null,reason:p});return ie(e,{kind:d instanceof ye?"budget":"assertion",status:"failed",stepId:t,tool:"assert-state",message:p}),{kind:f,message:p,assertionIds:a.map(({id:h})=>h)}}let l=ed(i.data,a),c=[];for(let d of l){let p=a.find(g=>g.id===d.id),f=d.passed,h=i.isError?"assert-state returned a handled error.":f===null?"assert-state returned no explicit boolean truth; tool-call success is not verification.":f?"assert-state explicitly reported true.":"assert-state explicitly reported false.";e.assertions.set(d.id,{id:d.id,stepId:t,assertion:p,passed:f,reason:h,...d.evidence===void 0?{}:{evidence:d.evidence}}),f!==!0&&c.push(d.id)}return ie(e,{kind:"assertion",status:c.length===0?"passed":"failed",stepId:t,tool:"assert-state",message:c.length===0?`${a.length} semantic assertion(s) explicitly passed.`:`${c.length}/${a.length} semantic assertion(s) are false or unresolved.`,evidence:St(i.data)}),c.length===0?null:{kind:"assertion-failed",message:`Semantic assertions failed or were indeterminate: ${c.join(", ")}.`,assertionIds:c,result:i.data}}function td(e){if(!wt(e))return[];let t=[];for(let n of["recommendations","recoveryRecommendations","nextActions"]){let r=e[n];if(Array.isArray(r))for(let a of r)typeof a=="string"&&t.push(a)}for(let n of["recommendation","next"]){let r=e[n];typeof r=="string"&&t.push(r)}return t}async function Qs(e,t,n,r){let a=e.catalog.get("explain-failure");if(a){if(a.mutatesState){Et(e,"explain-failure is registered as mutating and was not invoked.");return}try{let o=await Sa(e,"explain-failure",{toolName:t.tool,error:n.message,result:n.result,attemptedInput:r,context:{goal:e.input.goal,stepId:t.id,failureKind:n.kind,assertionIds:n.assertionIds,recoverWith:t.recoverWith}});ie(e,{kind:"diagnosis",status:o.isError?"failed":"explained",stepId:t.id,tool:"explain-failure",evidence:St(o.data)});for(let i of td(o.data))Et(e,i);return o.data}catch(o){ie(e,{kind:o instanceof ye?"budget":"diagnosis",status:"failed",stepId:t.id,tool:"explain-failure",message:o instanceof Error?o.message:String(o)});return}}}function nd(e,t){return e.when==="any"?!0:e.when==="blocked"?t==="blocked"||t==="loop":e.when===t}function Js(e,t,n){for(let r of t.recoverWith){let a=e.branches.get(r);if(a&&!e.usedBranches.has(r)&&nd(a,n))return a}return null}async function rd(e,t,n){try{Qu(e)}catch(p){let f=p instanceof Error?p.message:String(p);return ie(e,{kind:"budget",status:"exhausted",stepId:t.id,branchId:n,message:f}),{ok:!1,failure:{kind:"budget",message:f,assertionIds:[]}}}e.executedStepIds.add(t.id);let r=e.catalog.get(t.tool);if(!r)return{ok:!1,failure:{kind:"tool-error",message:`Unknown tool "${t.tool}".`,assertionIds:[]}};if(r.mutatesState&&!e.input.allowMutations){let p="Mutation approval is absent; set allowMutations=true only with user authorization.";return ie(e,{kind:"step",status:"blocked",stepId:t.id,branchId:n,tool:t.tool,message:p}),{ok:!1,failure:{kind:"blocked",message:p,assertionIds:[]}}}let a;try{a=Xs(t.input,e.outputs)}catch(p){return{ok:!1,failure:{kind:"tool-error",message:p instanceof Error?p.message:String(p),assertionIds:[]}}}let o=r.input.safeParse(a);if(!o.success)return{ok:!1,resolvedInput:a,failure:{kind:"tool-error",message:`Input does not match ${t.tool}: ${Ys(o.error)}`,assertionIds:[]}};a=o.data;let i=Hu(t.tool,a),l=e.signatures.get(i)??0;if(r.mutatesState&&l>=1||!r.mutatesState&&l>=2){let p=r.mutatesState?"Refused an identical mutating action; smart-task never blindly repeats a mutation.":"Repeated action and input signature indicates a loop.";return ie(e,{kind:"loop",status:"blocked",stepId:t.id,branchId:n,tool:t.tool,message:p,evidence:{signature:i,previousCalls:l}}),Et(e,p),{ok:!1,resolvedInput:a,failure:{kind:"loop",message:p,assertionIds:[]}}}e.signatures.set(i,l+1);let c;try{c=await Sa(e,t.tool,a)}catch(p){let f=p instanceof ye,h=p instanceof Error?p.message:String(p);return f&&r.mutatesState&&Et(e,`Verify ${t.tool}'s intended postcondition before any later action; a timed-out mutation may still complete.`),ie(e,{kind:f?"budget":"step",status:f?"exhausted":"threw",stepId:t.id,branchId:n,tool:t.tool,message:h}),{ok:!1,resolvedInput:a,failure:{kind:f?"budget":"tool-error",message:h,assertionIds:[]}}}if(e.outputs.set(t.id,{data:c.data,result:c.data,summary:c.summary,isError:c.isError??!1}),ie(e,{kind:"step",status:c.isError?"handled-error":"succeeded",stepId:t.id,branchId:n,tool:t.tool,...c.summary?{message:c.summary}:{},evidence:St(c.data)}),c.isError)return{ok:!1,resolvedInput:a,failure:{kind:"tool-error",message:c.summary??`${t.tool} returned a handled error.`,assertionIds:[],result:c.data}};let d=await kr(e,t.id,t.assertions,"post-step");return d?{ok:!1,resolvedInput:a,failure:d}:(e.successfulSteps+=1,{ok:!0,resolvedInput:a})}async function wa(e,t,n){let r=!1;for(let a of t){let o=await rd(e,a,n);if(o.ok)continue;let i=o.failure,l={stepId:a.id,tool:a.tool,kind:i.kind,message:i.message,assertionIds:i.assertionIds,recovered:!1};e.failures.push(l);let c=e.catalog.get(a.tool);for(let p of c?.ai?.failureRecovery??[])Et(e,p);(i.kind==="tool-error"||i.kind==="assertion-failed")&&(l.explanation=await Qs(e,a,i,o.resolvedInput));let d=Js(e,a,i.kind);if(d&&!e.budgetStop){e.usedBranches.add(d.id),l.recoveryBranch=d.id,ie(e,{kind:"fallback",status:"selected",stepId:a.id,branchId:d.id,message:`Selected explicit ${d.when} recovery branch.`});let p=await wa(e,d.steps,d.id),f=i.assertionIds.length===0;if(p.reachedEnd&&!p.hadUnrecoveredFailure&&i.assertionIds.length>0){let g=i.assertionIds.filter(b=>d.resolvesAssertions.includes(b)).flatMap(b=>{let m=e.resolvedAssertions.get(b);return m?[m]:[]});g.length===i.assertionIds.length&&(f=await kr(e,a.id,g,"recovery-recheck")===null)}if(p.reachedEnd&&!p.hadUnrecoveredFailure&&f){if(l.recovered=!0,ie(e,{kind:"fallback",status:"recovered",stepId:a.id,branchId:d.id,message:"Fallback completed and required assertions were explicitly rechecked."}),d.resume==="stop"||p.stopRequested)return e.intentionallyStopped=!0,{reachedEnd:!1,hadUnrecoveredFailure:r,stopRequested:!0};continue}r=!0}else r=!0;if(e.budgetStop||a.onFailure==="stop")return{reachedEnd:!1,hadUnrecoveredFailure:!0,stopRequested:!0}}return{reachedEnd:!0,hadUnrecoveredFailure:r,stopRequested:!1}}function ad(e,t){let n=[...e.assertions.values()],r=n.length,a=n.filter(d=>d.passed===!0).length,o=r===0?null:a/r,i=e.stepsUsed===0?0:e.successfulSteps/e.stepsUsed,l;t==="completed"&&r>0&&a===r?l=.98:t==="completed"?l=.65:o===null?l=Math.min(.5,i*.5):l=Math.min(.85,o*.65+i*.2);let c=Math.round(l*100)/100;return{score:c,level:c>=.9?"high":c>=.6?"medium":"low",basis:r===0?"No semantic assertions were supplied; successful calls alone cap confidence at 0.65.":`${a}/${r} assertions explicitly reported true; ${e.successfulSteps}/${e.stepsUsed} steps succeeded.`}}function od(e){let t=Math.max(0,Date.now()-e.startedAt);return{steps:{used:e.stepsUsed,limit:e.input.budgets.maxSteps,remaining:Math.max(0,e.input.budgets.maxSteps-e.stepsUsed)},toolCalls:{used:e.toolCallsUsed,limit:e.input.budgets.maxToolCalls,remaining:Math.max(0,e.input.budgets.maxToolCalls-e.toolCallsUsed)},timeMs:{used:Math.min(t,e.input.budgets.timeoutMs),limit:e.input.budgets.timeoutMs,remaining:Math.max(0,e.input.budgets.timeoutMs-t)},exhausted:e.budgetStop}}function id(e,t,n){let r=t.filter(l=>!e.executedStepIds.has(l.id)).map(l=>({id:l.id,tool:l.tool})),a=e.failures.filter(l=>!l.recovered).map(l=>({id:l.stepId,tool:l.tool,kind:l.kind,message:l.message})),o=[...e.branches.keys()].filter(l=>!e.usedBranches.has(l)),i=[];return e.budgetStop&&i.push(`Build a continuation from failedSteps and pendingSteps with a fresh explicit budget; ${e.budgetStop} was exhausted.`),n.length>0&&i.push("Correct observation inputs or add an explicit recovery branch, then re-run unresolved assertions."),e.failures.some(l=>l.kind==="blocked"&&!l.recovered)&&i.push("Obtain mutation authorization before setting allowMutations=true."),e.failures.some(l=>l.kind==="loop"&&!l.recovered)&&i.push("Change the action input or choose a different tool; identical mutation retries stay blocked."),i.length===0&&r.length===0&&i.push("No continuation is required; preserve the evidence timeline as proof."),{failedSteps:a,pendingSteps:r,unusedFallbacks:o,nextActions:i}}async function el(e,t){let n=t.tools.list(),r=new Map(n.map(m=>[m.name,m]));if(!e.steps||e.steps.length===0){let m=Xu(e.goal,n,e.allowMutations);return{data:{status:"plan-only",requestedMode:e.mode,goal:e.goal,...m,budgets:e.budgets},summary:`Generated a deterministic schema-aware plan for "${e.goal}"; nothing executed.`}}let a=Yu(e,r),o=Zu(e,r);if(e.mode!=="execute")return{data:{status:e.mode,goal:e.goal,allowMutations:e.allowMutations,budgets:e.budgets,validation:a,canExecute:!a.some(m=>m.severity==="error"),plan:o,continuationPlan:["Fix every validation error.","Review mutation warnings and semantic assertions.","Switch mode to execute without changing validated inputs."]},summary:`${e.mode==="preview"?"Previewed":"Planned"} ${e.steps.length} explicit step(s); nothing executed.`};let i=a.filter(m=>m.severity==="error");if(i.length>0)return{data:{status:"blocked",goal:e.goal,validation:a,plan:o,evidenceTimeline:[],budgetsConsumed:{steps:{used:0,limit:e.budgets.maxSteps,remaining:e.budgets.maxSteps},toolCalls:{used:0,limit:e.budgets.maxToolCalls,remaining:e.budgets.maxToolCalls},timeMs:{used:0,limit:e.budgets.timeoutMs,remaining:e.budgets.timeoutMs},exhausted:null},completionConfidence:{score:0,level:"low",basis:"Structural validation failed before execution."},unresolvedAssertions:[],recoveryRecommendations:i.map(m=>m.message),continuationPlan:{failedSteps:[],pendingSteps:e.steps.map(m=>({id:m.id,tool:m.tool})),unusedFallbacks:e.fallbacks.map(m=>m.id),nextActions:["Correct structural validation errors, then preview again."]}},summary:`Execution blocked by ${i.length} structural validation error(s).`,isError:!0};let l=Date.now(),c={input:e,ctx:t,catalog:r,branches:new Map(e.fallbacks.map(m=>[m.id,m])),startedAt:l,deadlineAt:l+e.budgets.timeoutMs,outputs:new Map,evidence:[],failures:[],assertions:new Map,resolvedAssertions:new Map,signatures:new Map,usedBranches:new Set,executedStepIds:new Set,recoveryRecommendations:[],stepsUsed:0,successfulSteps:0,toolCallsUsed:0,budgetStop:null,intentionallyStopped:!1};if((await wa(c,e.steps)).reachedEnd&&!c.budgetStop&&!c.intentionallyStopped){let m=await kr(c,"goal",e.successAssertions,"goal");if(m){let y={type:"tool",id:"goal-assertions",tool:"assert-state",input:{},assertions:[],recoverWith:e.finalRecoverWith,onFailure:"stop"},w={stepId:y.id,tool:y.tool,kind:m.kind,message:m.message,assertionIds:m.assertionIds,recovered:!1};c.failures.push(w),w.explanation=await Qs(c,y,m,{});let C=Js(c,y,m.kind);if(C&&!c.budgetStop){c.usedBranches.add(C.id),w.recoveryBranch=C.id,ie(c,{kind:"fallback",status:"selected",stepId:y.id,branchId:C.id});let I=await wa(c,C.steps,C.id),O=m.assertionIds.filter(q=>C.resolvesAssertions.includes(q)).flatMap(q=>{let S=c.resolvedAssertions.get(q);return S?[S]:[]});I.reachedEnd&&!I.hadUnrecoveredFailure&&O.length===m.assertionIds.length&&(w.recovered=await kr(c,"goal",O,"recovery-recheck")===null)}}}let p=[...c.assertions.values()].filter(m=>m.passed!==!0),f=c.failures.filter(m=>!m.recovered),h=e.steps.filter(m=>!c.executedStepIds.has(m.id)),g=c.budgetStop?"budget-exhausted":c.intentionallyStopped?"partial":f.length===0&&p.length===0&&h.length===0?"completed":c.successfulSteps>0?"partial":f.some(m=>m.kind==="blocked")?"blocked":"failed",b=id(c,e.steps,p);return{data:{status:g,goal:e.goal,evidenceTimeline:c.evidence,references:Object.fromEntries(c.outputs),failures:c.failures,budgetsConsumed:od(c),completionConfidence:ad(c,g),unresolvedAssertions:p,recoveryRecommendations:c.recoveryRecommendations,continuationPlan:b},summary:`${c.successfulSteps}/${c.stepsUsed} step(s) succeeded; status ${g}.`,isError:g!=="completed"}}var tl=u({name:"smart-task",title:"Plan or execute an adaptive verified task",description:"DETERMINISTIC ADAPTIVE ORCHESTRATOR. Turn a goal into a schema-aware plan, preview an explicit typed workflow, or execute it one tool at a time under hard step, tool-call, and wall-clock budgets. Inputs may safely reference prior outputs with exact $steps.<id>.<path> references. Mutations require allowMutations=true and an identical mutating action is never retried. Semantic postconditions are delegated to the read-only assert-state tool and count as verified only when it returns explicit boolean truth. Handled failures may be diagnosed by the read-only explain-failure tool and can activate only named recoverWith branches supplied by the caller. The result includes an evidence timeline, consumed budgets, confidence, unresolved assertions, recovery advice, and a continuation plan. This tool contains no LLM: omitted steps produce deterministic rankTools/matchWorkflows suggestions and leave required arguments blank instead of guessing them.",category:"Intelligence",requiresClient:!1,mutatesState:!0,ai:{phase:"orchestrate",prerequisites:[],consumes:["goal","explicit typed steps","semantic success assertions","mutation approval","hard execution budgets"],produces:["schema-aware plan","evidence timeline","assertion truth","completion confidence","continuation plan"],verifiesWith:["assert-state"],alternatives:["agent-run","tool-plan","script"],requiresCapabilities:[],sideEffects:["may invoke multiple registered tools","mutating nested tools require allowMutations=true"],failureRecovery:["inspect unresolvedAssertions and evidenceTimeline","use only explicitly declared recoverWith branches","resume pending steps with a fresh hard budget"]},input:Ks,execute(e,t){return el(e,t)}});import{z as R}from"zod";var sd=["begin","capture","status","commit","rollback","cleanup"],nl=32,et=256,rl=128,al=900,ld=512,ol=R.string().min(1).max(100).describe("Exact Instance property or attribute name."),cd=R.object({path:R.string().min(1).max(512).describe("Dotted Instance path resolved without evaluating arbitrary Luau."),properties:R.array(ol).max(32).optional().default([]).describe("Explicit Instance properties to snapshot. No implicit property sweep is performed."),attributes:R.array(ol).max(32).optional().default([]).describe("Explicit attributes to snapshot, including whether each attribute was absent.")}),ud=R.discriminatedUnion("kind",[R.object({kind:R.literal("drawing"),id:R.number().int().nonnegative().max(2147483647).describe("Drawing id from draw-create/list-drawings to remove during rollback.")}),R.object({kind:R.literal("virtual-input"),inputType:R.enum(["key","mouse-button","touch","gamepad-button"]).describe("Held input type that must receive its matching release/end event."),key:R.string().min(1).max(100).optional().describe("Enum.KeyCode member for key or gamepad-button cleanup."),button:R.enum(["Left","Right","Middle"]).optional().default("Left"),x:R.number().finite().optional(),y:R.number().finite().optional(),touchId:R.number().int().nonnegative().max(1e6).optional().default(0),gamepad:R.enum(["Gamepad1","Gamepad2","Gamepad3","Gamepad4"]).optional().default("Gamepad1")}),R.object({kind:R.literal("connection"),expression:R.string().min(1).max(1e3).describe("Luau expression resolving to an RBXScriptConnection. The object reference is captured immediately."),rollbackAction:R.enum(["restore-state","disconnect"]).optional().default("disconnect").describe("restore-state re-applies the captured Enabled state; disconnect is cleanup-only and cannot recreate a connection.")}),R.object({kind:R.literal("hook"),key:R.string().min(1).max(1e3).describe("Exact key in the canonical __mcp_hooks/__mcp_hook_meta registries.")})]);function il(e){return`{ ${e.map(t=>s(t)).join(", ")} }`}function dd(e){return`{ ${e.map(t=>`{ path = ${s(t.path)}, properties = ${il(t.properties)}, attributes = ${il(t.attributes)} }`).join(", ")} }`}function pd(e){return`{ ${e.map(t=>t.kind==="drawing"?`{ kind = "drawing", id = ${String(t.id)} }`:t.kind==="virtual-input"?`{ kind = "virtual-input", inputType = ${s(t.inputType)}, key = ${s(t.key??"")}, button = ${s(t.button)}, x = ${t.x===void 0?"nil":String(t.x)}, y = ${t.y===void 0?"nil":String(t.y)}, touchId = ${String(t.touchId)}, gamepad = ${s(t.gamepad)} }`:t.kind==="connection"?`{ kind = "connection", expression = ${s(t.expression)}, rollbackAction = ${s(t.rollbackAction)} }`:`{ kind = "hook", key = ${s(t.key)} }`).join(", ")} }`}function xr(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)?e:null}function ve(e,t){let n=e?.[t];return typeof n=="number"&&Number.isFinite(n)?n:0}function fd(e,t){let n=xr(t);if(typeof n?.error=="string")return`State transaction failed: ${n.error}`;let r=typeof n?.transactionId=="string"?n.transactionId:"transaction";if(e==="begin")return`Started ${r} with a bounded reversible-state journal.`;if(e==="capture"){let a=xr(n?.capture);return`Captured ${ve(a,"captured")} item(s) and reported ${ve(a,"failed")+ve(a,"unsupported")} issue(s) for ${r}.`}return e==="status"?`Reported ${ve(n,"count")||(n?.transactionId?1:0)} state transaction(s).`:e==="commit"?`Committed ${r}; ${ve(n,"discardedItems")} journal item(s) were discarded without restoration.`:e==="rollback"?`Rolled back ${r}: ${ve(n,"restored")} restored, ${ve(n,"cleaned")} cleaned, ${ve(n,"failed")} failed, ${ve(n,"unsupported")} unsupported.`:`Cleanup processed ${ve(n,"processed")} expired/orphaned transaction(s); ${ve(n,"remaining")} remain.`}var sl=u({name:"state-transaction",title:"Capture, rollback, and clean up bounded live state transactions",description:"STATE TRANSACTION JOURNAL. Begin a bounded getgenv-backed transaction, capture explicitly requested Instance properties/attributes and camera fields, register known cleanup resources, inspect status, commit without restoration, or rollback in reverse journal order with pcall-isolated per-item results. Cleanup can rollback or explicitly discard expired and cross-place/job orphaned transactions. Registered resources support MCP Drawing ids, held virtual input releases, connection state restoration or cleanup-only disconnection, and canonical __mcp_hooks/__mcp_hook_meta entries when their metadata is safely understood. This is a best-effort client-state journal, not a general undo system: destroyed Instances, fired remotes, server-side changes, arbitrary script side effects, and connections destroyed before capture cannot be reconstructed. Commit intentionally discards all snapshots and does not clean registered resources.",category:"Intelligence",mutatesState:!0,ai:{phase:"act",prerequisites:["begin a transaction before mutating reversible client state","capture every property/attribute before changing it"],consumes:["transaction id or unique name","explicit Instance fields and cleanup resource handles"],produces:["bounded state journal","per-item rollback evidence","expired/orphaned cleanup report"],verifiesWith:[],alternatives:["set-instance-property","set-attribute","camera-control","restore-hook"],requiresCapabilities:["getgenv"],sideEffects:["capture stores raw client references in getgenv until commit, rollback, cleanup, expiry, or executor shutdown","rollback writes captured values and runs registered cleanup actions in reverse order","connection disconnect cleanup is irreversible and is reported separately from reversible restoration"],failureRecovery:["inspect every failed or unsupported rollback item and use its dedicated cleanup tool","never assume destroyed Instances, remotes, server state, or arbitrary side effects were restored","run cleanup again after reconnect only when the original client registry still exists"]},input:R.object({action:R.enum(sd).describe("Transaction lifecycle action."),transactionId:R.string().min(1).max(96).optional().describe("Stable transaction id. Optional for begin (one is generated); required by id for unambiguous later actions."),name:R.string().min(1).max(120).optional().describe("Human label; later actions may use it only when exactly one active transaction matches."),targets:R.array(cd).max(16).optional().default([]).describe("Explicit property/attribute snapshot targets for begin or capture."),captureCamera:R.boolean().optional().default(!1).describe("Snapshot CurrentCamera CameraType, CameraSubject, CFrame, Focus, and FieldOfView."),cleanupItems:R.array(ud).max(64).optional().default([]).describe("Resources to release/restore during reverse-order rollback."),maxItems:R.number().int().positive().max(et).optional().describe(`Per-transaction journal cap (default ${rl}, hard maximum ${et}); for capture it may only lower the call cap.`),expirySeconds:R.number().int().min(10).max(86400).optional().describe(`Seconds until cleanup considers the transaction expired (default ${al} on begin). Capture may refresh it.`),limit:R.number().int().positive().max(nl).optional().default(16).describe("Maximum transactions listed or processed by status/cleanup."),cleanupMode:R.enum(["rollback","discard"]).optional().default("rollback").describe("For cleanup, rollback attempts every journal item first; discard explicitly removes journals without restoration."),includeOrphans:R.boolean().optional().default(!0).describe("For cleanup, include transactions created in another PlaceId/JobId, not only expired ones."),threadContext:R.number().int().optional()}),async execute({action:e,transactionId:t,name:n,targets:r,captureCamera:a,cleanupItems:o,maxItems:i,expirySeconds:l,limit:c,cleanupMode:d,includeOrphans:p,threadContext:f},h){if(["capture","commit","rollback"].includes(e)&&!t&&!n)return{data:{error:`${e} requires transactionId or a unique name.`},summary:`${e} requires transactionId or a unique name.`,isError:!0};for(let I of o){if(I.kind==="virtual-input"&&(I.inputType==="key"||I.inputType==="gamepad-button")&&!I.key)return{data:{error:`${I.inputType} cleanup requires key.`},summary:`${I.inputType} cleanup requires key.`,isError:!0};if(I.kind==="virtual-input"&&(I.inputType==="mouse-button"||I.inputType==="touch")&&(I.x===void 0||I.y===void 0))return{data:{error:`${I.inputType} cleanup requires x and y.`},summary:`${I.inputType} cleanup requires x and y.`,isError:!0}}let g=r.reduce((I,N)=>I+N.properties.length+N.attributes.length,0)+(a?5:0)+o.length;if(g>et)return{data:{error:`Capture requests ${g} items; hard per-call maximum is ${et}.`,requestedItems:g,maxItems:et},summary:`Capture request exceeds the ${et}-item safety cap.`,isError:!0};let b=`
${_e}
${Za}
local ACTION = ${s(e)}
local REQUESTED_ID = ${s(t??"")}
local REQUESTED_NAME = ${s(n??"")}
local CAPTURE_TARGETS = ${dd(r)}
local CAPTURE_CAMERA = ${a?"true":"false"}
local CLEANUP_ITEMS = ${pd(o)}
local REQUESTED_MAX_ITEMS = ${i===void 0?"nil":String(i)}
local REQUESTED_EXPIRY = ${l===void 0?"nil":String(l)}
local TRANSACTION_LIMIT = ${String(c)}
local CLEANUP_MODE = ${s(d)}
local INCLUDE_ORPHANS = ${p?"true":"false"}
local MAX_TRANSACTIONS = ${nl}
local HARD_MAX_ITEMS = ${et}
local DEFAULT_MAX_ITEMS = ${rl}
local DEFAULT_EXPIRY = ${al}
local MAX_CLEANUP_WORK = ${ld}

local LIMITATIONS = {
  "Only explicitly captured properties, attributes, camera fields, and registered cleanup resources are handled.",
  "Destroyed Instances, fired remotes, server-side changes, arbitrary script effects, and already-destroyed connections cannot be reconstructed.",
  "Drawing removal and registered connection disconnection are cleanup-only operations, not reversible snapshots.",
}

if type(getgenv) ~= "function" then
  return { error = "getgenv is unavailable; persistent state transactions are unsupported.", limitations = LIMITATIONS }
end
local okEnv, genv = pcall(getgenv)
if not okEnv or type(genv) ~= "table" then
  return { error = "getgenv did not return a writable table.", limitations = LIMITATIONS }
end

local REGISTRY_KEY = "__mcp_state_transactions"
local registry = genv[REGISTRY_KEY]
if registry == nil then
  registry = { version = 1, counter = 0, transactions = {} }
  genv[REGISTRY_KEY] = registry
elseif type(registry) ~= "table" then
  return { error = REGISTRY_KEY .. " exists but is not a table; refusing to overwrite unknown state.", limitations = LIMITATIONS }
elseif registry.version ~= 1 then
  return { error = "Unsupported state transaction registry version: " .. tostring(registry.version), limitations = LIMITATIONS }
end
if type(registry.transactions) ~= "table" then
  return { error = "State transaction registry is corrupt (transactions is not a table).", limitations = LIMITATIONS }
end
if type(registry.counter) ~= "number" then registry.counter = 0 end

local function now()
  local ok, value = pcall(function() return os.time() end)
  if ok and type(value) == "number" then return value end
  local okClock, clock = pcall(function() return os.clock() end)
  return okClock and math.floor(clock) or 0
end

local function currentOwner()
  local placeId = 0
  local jobId = ""
  pcall(function() placeId = game.PlaceId end)
  pcall(function() jobId = game.JobId end)
  return placeId, jobId
end

local function countTransactions()
  local count = 0
  for _ in pairs(registry.transactions) do count = count + 1 end
  return count
end

local function isOrphaned(tx)
  if type(tx) ~= "table" then return true, "invalid-entry" end
  local placeId, jobId = currentOwner()
  if type(tx.ownerPlaceId) == "number" and tx.ownerPlaceId ~= 0 and placeId ~= 0 and tx.ownerPlaceId ~= placeId then
    return true, "place-changed"
  end
  if type(tx.ownerJobId) == "string" and tx.ownerJobId ~= "" and jobId ~= "" and tx.ownerJobId ~= jobId then
    return true, "job-changed"
  end
  return false, nil
end

local function isExpired(tx, timestamp)
  return type(tx) == "table" and type(tx.expiresAt) == "number" and tx.expiresAt <= timestamp
end

local function resolveTransaction()
  if REQUESTED_ID ~= "" then
    local tx = registry.transactions[REQUESTED_ID]
    if type(tx) ~= "table" then return nil, nil, "Unknown transaction id '" .. REQUESTED_ID .. "'." end
    return tx, REQUESTED_ID, nil
  end
  if REQUESTED_NAME == "" then return nil, nil, "Provide transactionId or name." end
  local match, matchId, matches = nil, nil, 0
  for id, tx in pairs(registry.transactions) do
    if type(tx) == "table" and tx.name == REQUESTED_NAME then
      match, matchId, matches = tx, tostring(id), matches + 1
    end
  end
  if matches == 0 then return nil, nil, "No transaction named '" .. REQUESTED_NAME .. "'." end
  if matches > 1 then return nil, nil, "Transaction name '" .. REQUESTED_NAME .. "' is ambiguous; use transactionId." end
  return match, matchId, nil
end

local function evaluate(expression)
  local loader = loadstring or load
  if type(loader) ~= "function" then return nil, "loadstring/load is unavailable" end
  local okCompile, chunkOrErr = pcall(loader, "return " .. expression)
  if not okCompile or type(chunkOrErr) ~= "function" then
    return nil, "compile failed: " .. tostring(chunkOrErr)
  end
  local okRun, value = pcall(chunkOrErr)
  if not okRun then return nil, "evaluation failed: " .. tostring(value) end
  return value, nil
end

local function pathOf(instance)
  local ok, value = pcall(function() return instance:GetFullName() end)
  return ok and value or tostring(instance)
end

local function describeItem(item, index)
  local out = {
    index = index,
    kind = type(item) == "table" and item.kind or "invalid",
    reversible = type(item) == "table" and item.reversible == true or false,
    operation = type(item) == "table" and item.operation or "unknown",
  }
  if type(item) ~= "table" then return out end
  out.path = item.path
  out.property = item.property
  out.attribute = item.attribute
  out.cameraProperty = item.cameraProperty
  out.drawingId = item.drawingId
  out.inputType = item.inputType
  out.connectionAction = item.connectionAction
  out.hookKey = item.hookKey
  return out
end

local function itemResult(index, item, status, message)
  local out = describeItem(item, index)
  out.status = status
  out.message = message
  return out
end

local function invokeNative(fn)
  local callable = fn
  if type(newcclosure) == "function" then
    local okWrap, wrapped = pcall(newcclosure, fn)
    if okWrap and type(wrapped) == "function" then callable = wrapped end
  end
  return pcall(callable)
end

local function enumItem(enumType, name)
  local ok, item = pcall(function() return enumType[name] end)
  if not ok or typeof(item) ~= "EnumItem" then return nil end
  return item
end

local function restoreHook(item, index)
  if type(item.original) ~= "function" then
    return itemResult(index, item, "unsupported", "Captured hook original is unavailable.")
  end
  if item.hookKind == "function" then
    local target, targetErr = evaluate(item.targetExpression)
    if targetErr or type(target) ~= "function" then
      return itemResult(index, item, "failed", "Could not re-resolve hooked function: " .. tostring(targetErr or typeof(target)))
    end
    local restored, restoreErr = false, nil
    if type(restorefunction) == "function" then
      restored, restoreErr = pcall(restorefunction, target)
    end
    if not restored and type(hookfunction) == "function" then
      restored, restoreErr = pcall(hookfunction, target, item.original)
    end
    if not restored then
      local status = type(restorefunction) ~= "function" and type(hookfunction) ~= "function" and "unsupported" or "failed"
      return itemResult(index, item, status, "Hook restoration failed: " .. tostring(restoreErr or "no restoration API"))
    end
  elseif item.hookKind == "metamethod" then
    if type(hookmetamethod) ~= "function" then
      return itemResult(index, item, "unsupported", "hookmetamethod is unavailable.")
    end
    local object, objectErr = evaluate(item.targetExpression)
    if objectErr or object == nil then
      return itemResult(index, item, "failed", "Could not re-resolve metamethod object: " .. tostring(objectErr))
    end
    local ok, err = pcall(hookmetamethod, object, item.method, item.original)
    if not ok then return itemResult(index, item, "failed", "Metamethod restoration failed: " .. tostring(err)) end
  else
    return itemResult(index, item, "unsupported", "Unknown canonical MCP hook metadata kind.")
  end

  local hooks = genv.__mcp_hooks
  local metadata = genv.__mcp_hook_meta
  if type(hooks) == "table" and hooks[item.hookKey] == item.original then hooks[item.hookKey] = nil end
  if type(metadata) == "table" then metadata[item.hookKey] = nil end
  return itemResult(index, item, "restored", "Canonical MCP hook restored.")
end

local function releaseVirtualInput(item, index)
  local okService, vim = pcall(function() return game:GetService("VirtualInputManager") end)
  if not okService or typeof(vim) ~= "Instance" then vim = nil end
  local kind = item.inputType
  local ok, err
  if kind == "key" then
    local keyCode = enumItem(Enum.KeyCode, item.key)
    if not keyCode then return itemResult(index, item, "unsupported", "Unknown Enum.KeyCode '" .. tostring(item.key) .. "'.") end
    if vim then
      ok, err = invokeNative(function() vim:SendKeyEvent(false, keyCode, false, game) end)
    elseif #item.key == 1 and type(keyrelease) == "function" then
      ok, err = invokeNative(function() keyrelease(string.byte(string.upper(item.key))) end)
    else
      return itemResult(index, item, "unsupported", "No compatible key-release API is available.")
    end
  elseif kind == "mouse-button" then
    local ids = { Left = 0, Right = 1, Middle = 2 }
    local id = ids[item.button]
    if id == nil then return itemResult(index, item, "unsupported", "Unknown mouse button.") end
    if vim then
      ok, err = invokeNative(function() vim:SendMouseButtonEvent(item.x, item.y, id, false, game, 0) end)
    else
      local fallback = ({ Left = mouse1release, Right = mouse2release, Middle = mouse3release })[item.button]
      if type(fallback) ~= "function" then
        return itemResult(index, item, "unsupported", "No compatible mouse-release API is available.")
      end
      ok, err = invokeNative(fallback)
    end
  elseif kind == "touch" then
    if not vim then return itemResult(index, item, "unsupported", "Touch release requires VirtualInputManager.") end
    ok, err = invokeNative(function() vim:SendTouchEvent(item.touchId, Enum.UserInputState.End, item.x, item.y, game) end)
  elseif kind == "gamepad-button" then
    if not vim then return itemResult(index, item, "unsupported", "Gamepad release requires VirtualInputManager.") end
    local inputType = enumItem(Enum.UserInputType, item.gamepad)
    local keyCode = enumItem(Enum.KeyCode, item.key)
    if not inputType or not keyCode then
      return itemResult(index, item, "unsupported", "Unknown gamepad or Enum.KeyCode value.")
    end
    ok, err = invokeNative(function() vim:SendGamepadButtonEvent(inputType, keyCode, false, game) end)
  else
    return itemResult(index, item, "unsupported", "Unknown virtual input cleanup type.")
  end
  if not ok then return itemResult(index, item, "failed", "Input release failed: " .. tostring(err)) end
  return itemResult(index, item, "cleaned", "Held virtual input released.")
end

local function restoreItem(item, index)
  if type(item) ~= "table" then return itemResult(index, item, "unsupported", "Invalid journal item.") end
  if item.kind == "instance-property" then
    if typeof(item.instance) ~= "Instance" then return itemResult(index, item, "failed", "Captured Instance reference is no longer valid.") end
    local ok, err = pcall(function() item.instance[item.property] = item.value end)
    if not ok then return itemResult(index, item, "failed", "Property restore failed: " .. tostring(err)) end
    return itemResult(index, item, "restored", "Instance property restored.")
  elseif item.kind == "instance-attribute" then
    if typeof(item.instance) ~= "Instance" then return itemResult(index, item, "failed", "Captured Instance reference is no longer valid.") end
    local ok, err = pcall(function()
      item.instance:SetAttribute(item.attribute, item.hadValue and item.value or nil)
    end)
    if not ok then return itemResult(index, item, "failed", "Attribute restore failed: " .. tostring(err)) end
    return itemResult(index, item, "restored", item.hadValue and "Attribute value restored." or "Attribute absence restored.")
  elseif item.kind == "camera-property" then
    if typeof(item.camera) ~= "Instance" then return itemResult(index, item, "failed", "Captured Camera reference is no longer valid.") end
    local ok, err = pcall(function() item.camera[item.cameraProperty] = item.value end)
    if not ok then return itemResult(index, item, "failed", "Camera field restore failed: " .. tostring(err)) end
    return itemResult(index, item, "restored", "Camera field restored.")
  elseif item.kind == "drawing" then
    local handle = item.handle
    local drawings = genv.__mcp_drawings
    if handle == nil and type(drawings) == "table" and type(drawings[item.drawingId]) == "table" then
      handle = drawings[item.drawingId].handle
    end
    if handle == nil then return itemResult(index, item, "unsupported", "Drawing handle is absent from the MCP registry.") end
    local ok, err = pcall(function() handle:Remove() end)
    if not ok then return itemResult(index, item, "failed", "Drawing Remove() failed: " .. tostring(err)) end
    if type(drawings) == "table" and type(drawings[item.drawingId]) == "table" and drawings[item.drawingId].handle == handle then
      drawings[item.drawingId] = nil
    end
    return itemResult(index, item, "cleaned", "Registered Drawing removed; this cleanup item is not a reversible snapshot.")
  elseif item.kind == "virtual-input" then
    return releaseVirtualInput(item, index)
  elseif item.kind == "connection" then
    if item.connection == nil then return itemResult(index, item, "failed", "Captured connection reference is unavailable.") end
    if item.connectionAction == "restore-state" then
      local ok, err = pcall(function()
        if item.wasEnabled then item.connection:Enable() else item.connection:Disable() end
      end)
      if not ok then return itemResult(index, item, "failed", "Connection state restore failed: " .. tostring(err)) end
      return itemResult(index, item, "restored", "Connection Enabled state restored.")
    elseif item.connectionAction == "disconnect" then
      local ok, err = pcall(function() item.connection:Disconnect() end)
      if not ok then return itemResult(index, item, "failed", "Registered connection disconnect failed: " .. tostring(err)) end
      return itemResult(index, item, "cleaned", "Registered connection disconnected; disconnected connections cannot be recreated.")
    end
    return itemResult(index, item, "unsupported", "Unknown connection rollback action.")
  elseif item.kind == "mcp-hook" then
    return restoreHook(item, index)
  end
  return itemResult(index, item, "unsupported", "Unknown journal item kind '" .. tostring(item.kind) .. "'.")
end

local function rollbackTransaction(id, tx, reason)
  local results = {}
  local restored, cleaned, failed, unsupported = 0, 0, 0, 0
  local items = type(tx.items) == "table" and tx.items or {}
  for index = #items, 1, -1 do
    local ok, result = pcall(restoreItem, items[index], index)
    if not ok then
      result = itemResult(index, items[index], "failed", "Rollback handler threw: " .. tostring(result))
    end
    results[#results + 1] = result
    if result.status == "restored" then restored = restored + 1
    elseif result.status == "cleaned" then cleaned = cleaned + 1
    elseif result.status == "unsupported" then unsupported = unsupported + 1
    else failed = failed + 1 end
  end
  registry.transactions[id] = nil
  return {
    status = (failed + unsupported > 0) and "rollback-incomplete" or "rolled-back",
    transactionId = id,
    name = tx.name,
    reason = reason,
    reverseOrder = true,
    restored = restored,
    cleaned = cleaned,
    failed = failed,
    unsupported = unsupported,
    results = results,
    transactionRemoved = true,
    limitations = LIMITATIONS,
  }
end

local function registerCapture(tx)
  local report = { requested = 0, captured = 0, failed = 0, unsupported = 0, results = {}, truncated = false }
  local transactionCap = math.min(tonumber(tx.maxItems) or DEFAULT_MAX_ITEMS, HARD_MAX_ITEMS)
  local callCap = REQUESTED_MAX_ITEMS and math.min(REQUESTED_MAX_ITEMS, transactionCap) or transactionCap
  if type(tx.items) ~= "table" then tx.items = {} end

  local function reportResult(status, descriptor, message, value)
    local result = descriptor
    result.status = status
    result.message = message
    if value ~= nil then result.value = __encode(value) end
    report.results[#report.results + 1] = result
    if status == "captured" then report.captured = report.captured + 1
    elseif status == "unsupported" then report.unsupported = report.unsupported + 1
    else report.failed = report.failed + 1 end
  end

  local function add(item, descriptor, value)
    report.requested = report.requested + 1
    if #tx.items >= callCap then
      report.truncated = true
      reportResult("unsupported", descriptor, "Journal item cap reached; request was not captured.")
      return false
    end
    tx.items[#tx.items + 1] = item
    reportResult("captured", descriptor, "Captured.", value)
    return true
  end

  for _, target in ipairs(CAPTURE_TARGETS) do
    local instance, resolveErr = __resolve(target.path)
    if not instance then
      report.requested = report.requested + #target.properties + #target.attributes
      report.failed = report.failed + #target.properties + #target.attributes
      report.results[#report.results + 1] = {
        kind = "target",
        path = target.path,
        status = "failed",
        requestedFields = #target.properties + #target.attributes,
        message = "Target resolution failed: " .. tostring(resolveErr),
      }
    else
      for _, property in ipairs(target.properties) do
        local descriptor = { kind = "instance-property", path = target.path, property = property, reversible = true }
        local ok, value = pcall(function() return instance[property] end)
        if not ok then
          report.requested = report.requested + 1
          reportResult("failed", descriptor, "Property read failed: " .. tostring(value))
        else
          add({
            kind = "instance-property",
            reversible = true,
            operation = "restore",
            instance = instance,
            path = target.path,
            property = property,
            value = value,
          }, descriptor, value)
        end
      end
      for _, attribute in ipairs(target.attributes) do
        local descriptor = { kind = "instance-attribute", path = target.path, attribute = attribute, reversible = true }
        local ok, value = pcall(function() return instance:GetAttribute(attribute) end)
        if not ok then
          report.requested = report.requested + 1
          reportResult("failed", descriptor, "Attribute read failed: " .. tostring(value))
        else
          add({
            kind = "instance-attribute",
            reversible = true,
            operation = "restore",
            instance = instance,
            path = target.path,
            attribute = attribute,
            hadValue = value ~= nil,
            value = value,
          }, descriptor, value)
        end
      end
    end
  end

  if CAPTURE_CAMERA then
    local camera = nil
    pcall(function() camera = workspace.CurrentCamera end)
    if typeof(camera) ~= "Instance" then
      report.requested = report.requested + 5
      report.failed = report.failed + 5
      report.results[#report.results + 1] = { kind = "camera", status = "failed", requestedFields = 5, message = "workspace.CurrentCamera is unavailable." }
    else
      local cameraFields = { "CameraType", "CameraSubject", "CFrame", "Focus", "FieldOfView" }
      for _, property in ipairs(cameraFields) do
        local descriptor = { kind = "camera-property", cameraProperty = property, reversible = true }
        local ok, value = pcall(function() return camera[property] end)
        if not ok then
          report.requested = report.requested + 1
          reportResult("failed", descriptor, "Camera field read failed: " .. tostring(value))
        else
          add({
            kind = "camera-property",
            reversible = true,
            operation = "restore",
            camera = camera,
            cameraProperty = property,
            value = value,
          }, descriptor, value)
        end
      end
    end
  end

  for _, cleanup in ipairs(CLEANUP_ITEMS) do
    if cleanup.kind == "drawing" then
      local drawings = genv.__mcp_drawings
      local entry = type(drawings) == "table" and drawings[cleanup.id] or nil
      local descriptor = { kind = "drawing", drawingId = cleanup.id, reversible = false, operation = "cleanup" }
      if type(entry) ~= "table" or entry.handle == nil then
        report.requested = report.requested + 1
        reportResult("unsupported", descriptor, "Drawing id is absent from __mcp_drawings.")
      else
        add({ kind = "drawing", reversible = false, operation = "cleanup", drawingId = cleanup.id, handle = entry.handle }, descriptor)
      end
    elseif cleanup.kind == "virtual-input" then
      local descriptor = { kind = "virtual-input", inputType = cleanup.inputType, reversible = false, operation = "cleanup" }
      add({
        kind = "virtual-input",
        reversible = false,
        operation = "cleanup",
        inputType = cleanup.inputType,
        key = cleanup.key,
        button = cleanup.button,
        x = cleanup.x,
        y = cleanup.y,
        touchId = cleanup.touchId,
        gamepad = cleanup.gamepad,
      }, descriptor)
    elseif cleanup.kind == "connection" then
      local descriptor = { kind = "connection", connectionAction = cleanup.rollbackAction, reversible = cleanup.rollbackAction == "restore-state", operation = cleanup.rollbackAction == "restore-state" and "restore" or "cleanup" }
      local connection, connectionErr = evaluate(cleanup.expression)
      if connectionErr or connection == nil then
        report.requested = report.requested + 1
        reportResult("failed", descriptor, "Connection resolution failed: " .. tostring(connectionErr))
      elseif cleanup.rollbackAction == "restore-state" then
        local okEnabled, enabled = pcall(function() return connection.Enabled end)
        local okMethod, method = pcall(function() return enabled and connection.Enable or connection.Disable end)
        if not okEnabled or type(enabled) ~= "boolean" or not okMethod or type(method) ~= "function" then
          report.requested = report.requested + 1
          reportResult("unsupported", descriptor, "Connection does not expose readable Enabled plus Enable/Disable methods.")
        else
          add({ kind = "connection", reversible = true, operation = "restore", connection = connection, connectionAction = "restore-state", wasEnabled = enabled }, descriptor, enabled)
        end
      else
        local okMethod, method = pcall(function() return connection.Disconnect end)
        if not okMethod or type(method) ~= "function" then
          report.requested = report.requested + 1
          reportResult("unsupported", descriptor, "Connection does not expose Disconnect().")
        else
          add({ kind = "connection", reversible = false, operation = "cleanup", connection = connection, connectionAction = "disconnect" }, descriptor)
        end
      end
    elseif cleanup.kind == "hook" then
      local descriptor = { kind = "mcp-hook", hookKey = cleanup.key, reversible = true, operation = "restore" }
      local hooks, metadata = genv.__mcp_hooks, genv.__mcp_hook_meta
      local original = type(hooks) == "table" and hooks[cleanup.key] or nil
      local meta = type(metadata) == "table" and metadata[cleanup.key] or nil
      if type(original) ~= "function" or type(meta) ~= "table" then
        report.requested = report.requested + 1
        reportResult("unsupported", descriptor, "Canonical MCP hook original/metadata was not safely detectable.")
      elseif meta.kind ~= "function" and meta.kind ~= "metamethod" then
        report.requested = report.requested + 1
        reportResult("unsupported", descriptor, "Canonical MCP hook metadata kind is unknown.")
      elseif type(meta.targetExpr) ~= "string" or (meta.kind == "metamethod" and type(meta.method) ~= "string") then
        report.requested = report.requested + 1
        reportResult("unsupported", descriptor, "Canonical MCP hook metadata is incomplete.")
      else
        add({
          kind = "mcp-hook",
          reversible = true,
          operation = "restore",
          hookKey = cleanup.key,
          hookKind = meta.kind,
          targetExpression = meta.targetExpr,
          method = meta.method,
          original = original,
        }, descriptor)
      end
    end
  end

  tx.updatedAt = now()
  return report
end

if ACTION == "begin" then
  if countTransactions() >= MAX_TRANSACTIONS then
    return { error = "Transaction registry is full (" .. MAX_TRANSACTIONS .. "); commit/rollback one or run cleanup.", maxTransactions = MAX_TRANSACTIONS, limitations = LIMITATIONS }
  end
  registry.counter = registry.counter + 1
  local id = REQUESTED_ID
  if id == "" then id = "tx-" .. tostring(now()) .. "-" .. tostring(registry.counter) end
  if registry.transactions[id] ~= nil then
    return { error = "Transaction id '" .. id .. "' already exists; refusing to overwrite snapshots.", limitations = LIMITATIONS }
  end
  local timestamp = now()
  local placeId, jobId = currentOwner()
  local tx = {
    id = id,
    name = REQUESTED_NAME ~= "" and REQUESTED_NAME or id,
    state = "active",
    createdAt = timestamp,
    updatedAt = timestamp,
    expiresAt = timestamp + (REQUESTED_EXPIRY or DEFAULT_EXPIRY),
    ownerPlaceId = placeId,
    ownerJobId = jobId,
    maxItems = math.min(REQUESTED_MAX_ITEMS or DEFAULT_MAX_ITEMS, HARD_MAX_ITEMS),
    items = {},
  }
  registry.transactions[id] = tx
  local capture = registerCapture(tx)
  return {
    status = "active",
    transactionId = id,
    name = tx.name,
    createdAt = tx.createdAt,
    expiresAt = tx.expiresAt,
    maxItems = tx.maxItems,
    capture = capture,
    registryCount = countTransactions(),
    limitations = LIMITATIONS,
  }
end

if ACTION == "status" then
  if REQUESTED_ID ~= "" or REQUESTED_NAME ~= "" then
    local tx, id, resolveErr = resolveTransaction()
    if not tx then return { error = resolveErr, limitations = LIMITATIONS } end
    local orphaned, orphanReason = isOrphaned(tx)
    local descriptions = {}
    for index, item in ipairs(tx.items) do descriptions[#descriptions + 1] = describeItem(item, index) end
    return {
      status = tx.state,
      transactionId = id,
      name = tx.name,
      createdAt = tx.createdAt,
      updatedAt = tx.updatedAt,
      expiresAt = tx.expiresAt,
      expired = isExpired(tx, now()),
      orphaned = orphaned,
      orphanReason = orphanReason,
      maxItems = tx.maxItems,
      itemCount = #tx.items,
      items = descriptions,
      count = 1,
      limitations = LIMITATIONS,
    }
  end
  local ids = {}
  for id in pairs(registry.transactions) do ids[#ids + 1] = tostring(id) end
  table.sort(ids)
  local transactions = {}
  local timestamp = now()
  for _, id in ipairs(ids) do
    if #transactions >= TRANSACTION_LIMIT then break end
    local tx = registry.transactions[id]
    if type(tx) == "table" then
      local orphaned, orphanReason = isOrphaned(tx)
      transactions[#transactions + 1] = {
        transactionId = id,
        name = tx.name,
        state = tx.state,
        createdAt = tx.createdAt,
        expiresAt = tx.expiresAt,
        expired = isExpired(tx, timestamp),
        orphaned = orphaned,
        orphanReason = orphanReason,
        itemCount = type(tx.items) == "table" and #tx.items or 0,
      }
    else
      transactions[#transactions + 1] = { transactionId = id, state = "invalid", orphaned = true }
    end
  end
  return { status = "registry", count = #ids, returned = #transactions, truncated = #transactions < #ids, transactions = transactions, maxTransactions = MAX_TRANSACTIONS, limitations = LIMITATIONS }
end

if ACTION == "capture" then
  local tx, id, resolveErr = resolveTransaction()
  if not tx then return { error = resolveErr, limitations = LIMITATIONS } end
  if isExpired(tx, now()) then
    return { error = "Transaction is expired; rollback it or run cleanup instead of adding snapshots.", transactionId = id, limitations = LIMITATIONS }
  end
  local orphaned, orphanReason = isOrphaned(tx)
  if orphaned then
    return { error = "Transaction is orphaned (" .. tostring(orphanReason) .. "); rollback/cleanup it instead of adding snapshots.", transactionId = id, limitations = LIMITATIONS }
  end
  if REQUESTED_EXPIRY then tx.expiresAt = now() + REQUESTED_EXPIRY end
  local capture = registerCapture(tx)
  return { status = "active", transactionId = id, name = tx.name, expiresAt = tx.expiresAt, itemCount = #tx.items, capture = capture, limitations = LIMITATIONS }
end

if ACTION == "commit" then
  local tx, id, resolveErr = resolveTransaction()
  if not tx then return { error = resolveErr, limitations = LIMITATIONS } end
  local discarded = type(tx.items) == "table" and #tx.items or 0
  registry.transactions[id] = nil
  return {
    status = "committed",
    transactionId = id,
    name = tx.name,
    discardedItems = discarded,
    restorationAttempted = false,
    warning = "Commit discarded snapshots and cleanup registrations without restoring or releasing them.",
    remaining = countTransactions(),
    limitations = LIMITATIONS,
  }
end

if ACTION == "rollback" then
  local tx, id, resolveErr = resolveTransaction()
  if not tx then return { error = resolveErr, limitations = LIMITATIONS } end
  return rollbackTransaction(id, tx, "explicit")
end

if ACTION == "cleanup" then
  local ids = {}
  if REQUESTED_ID ~= "" or REQUESTED_NAME ~= "" then
    local tx, id, resolveErr = resolveTransaction()
    if not tx then return { error = resolveErr, limitations = LIMITATIONS } end
    ids[1] = id
  else
    for id in pairs(registry.transactions) do ids[#ids + 1] = tostring(id) end
    table.sort(ids)
  end

  local timestamp = now()
  local processed, eligible, work = 0, 0, 0
  local results = {}
  local truncated = false
  for _, id in ipairs(ids) do
    local tx = registry.transactions[id]
    local expired = isExpired(tx, timestamp)
    local orphaned, orphanReason = isOrphaned(tx)
    if expired or (INCLUDE_ORPHANS and orphaned) then
      eligible = eligible + 1
      local itemCount = type(tx) == "table" and type(tx.items) == "table" and #tx.items or 0
      if processed >= TRANSACTION_LIMIT or work + itemCount > MAX_CLEANUP_WORK then
        truncated = true
      else
        processed = processed + 1
        work = work + itemCount
        local reason = expired and "expired" or (orphanReason or "orphaned")
        if CLEANUP_MODE == "rollback" and type(tx) == "table" then
          results[#results + 1] = rollbackTransaction(id, tx, reason)
        else
          registry.transactions[id] = nil
          results[#results + 1] = {
            status = "discarded",
            transactionId = id,
            reason = reason,
            discardedItems = itemCount,
            restorationAttempted = false,
          }
        end
      end
    end
  end
  return {
    status = "cleanup-complete",
    mode = CLEANUP_MODE,
    processed = processed,
    eligible = eligible,
    workItems = work,
    workLimit = MAX_CLEANUP_WORK,
    truncated = truncated,
    results = results,
    remaining = countTransactions(),
    limitations = LIMITATIONS,
  }
end

return { error = "Unknown transaction action.", limitations = LIMITATIONS }
`,m=await h.runLuau(b,{threadContext:f,timeoutMs:3e4}),y=xr(m),w=typeof y?.error=="string",C=y?.status==="rollback-incomplete"||e==="cleanup"&&Array.isArray(y?.results)&&y.results.some(I=>xr(I)?.status==="rollback-incomplete");return{data:m,summary:fd(e,m),...w||C?{isError:!0}:{}}}});import{z as ue}from"zod";var tt="trace-remote-traffic";function U(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)?e:null}function P(e,t=0){return typeof e=="number"&&Number.isFinite(e)?e:t}function A(e){return typeof e=="string"&&e.length>0?e:void 0}function md(e){return[...new Set(e)]}function wr(e,t){try{return e.tools?.find(t)!=null}catch{return!1}}async function hd(e,t,n,r){if(!e)return{requested:!1,available:wr(r,tt),enabled:!1,owned:!1,status:"disabled"};if(!wr(r,tt))return{requested:!0,available:!1,enabled:!1,owned:!1,status:"unavailable",detail:"trace-remote-traffic is not registered; core teach-mode recording remains active."};try{let a=await r.invokeTool(tt,{action:"start",limit:t,...n!==void 0?{threadContext:n}:{}}),o=U(a.data),i=A(o?.error);if(a.isError===!0||i)return{requested:!0,available:!0,enabled:!1,owned:!1,status:"failed",detail:i??a.data};let l=o?.started===!0,c=o?.alreadyRunning===!0;return{requested:!0,available:!0,enabled:l||c,owned:l,status:l?"started":c?"shared-existing":"unknown-response",detail:a.data}}catch(a){return{requested:!0,available:!0,enabled:!1,owned:!1,status:"failed",detail:a instanceof Error?a.message:String(a)}}}var gd=`
if type(getgenv) ~= "function" then return { restored = false, error = "getgenv unavailable" } end
local state = getgenv().__mcp_remoteTrace
if type(state) ~= "table" then return { restored = true, notRunning = true } end
local restored = false
local restoreError = nil
if type(state.orig) == "function" and type(hookmetamethod) == "function" then
  local ok, err = pcall(hookmetamethod, game, "__namecall", state.orig)
  restored = ok
  if not ok then restoreError = tostring(err) end
end
if (not restored) and type(state.hook) == "function" and type(restorefunction) == "function" then
  local ok, err = pcall(restorefunction, state.hook)
  restored = ok
  if not ok then restoreError = tostring(err) end
end
if restored then getgenv().__mcp_remoteTrace = nil end
return { restored = restored, restoreError = restoreError, fallback = true }
`;async function _r(e,t,n){if(!e)return{released:!1,reason:"not-owned"};if(wr(n,tt))try{let r=await n.invokeTool(tt,{action:"stop",limit:1,...t!==void 0?{threadContext:t}:{}}),a=U(r.data);if(r.isError!==!0&&!A(a?.error))return{released:!0,method:"invokeTool",detail:r.data}}catch{}try{return{released:!0,method:"direct-fallback",detail:await n.runLuau(gd,{threadContext:t,timeoutMs:15e3})}}catch(r){return{released:!1,method:"direct-fallback",error:r instanceof Error?r.message:String(r)}}}function bd(e){let t=e.split(".").filter(Boolean);if(t.length===0)return e;let n=`game:GetService(${s(t[0])})`;for(let r of t.slice(1))n+=`:FindFirstChild(${s(r)})`;return n}function yd(e,t,n){let r=U(e),a=Array.isArray(r?.entries)?r.entries:Array.isArray(r?.logs)?r.logs:[],o=[];for(let i of a){let l=U(i);if(!l)continue;let c=P(l.t,-1);if(c<0)continue;let d=Math.max(0,c-t);if(c<t||d<=n)continue;let p=A(l.remote)??"<unknown remote>",f=A(l.method)??"Unknown";o.push({kind:"remote_call",source:"remote-spy",t:d,remoteId:`remote:${c}:${f}:${p}`,target:{path:p,expression:bd(p),className:A(l.class),name:p.split(".").at(-1)},method:f,args:Array.isArray(l.args)?l.args:[],argCount:P(l.argCount),argsTruncated:l.argsTruncated===!0,blocked:l.blocked===!0})}return o.sort((i,l)=>P(i.t)-P(l.t))}async function vd(e,t,n,r,a){let o=U(e)??{raw:e};if(o.remoteSpyEnabled!==!0)return o;if(!wr(a,tt))return{...o,remoteSpyIntegration:{status:"unavailable-during-read"}};try{let i=await a.invokeTool(tt,{action:"fetch",limit:t,...r!==void 0?{threadContext:r}:{}}),l=A(U(i.data)?.error);if(i.isError===!0||l)return{...o,remoteSpyIntegration:{status:"read-failed",error:l??i.data}};let c=Array.isArray(o.events)?o.events.filter(h=>U(h)!==null):[],d=P(o.startedAt),p=yd(i.data,d,n),f=[...c,...p].sort((h,g)=>P(U(h)?.t)-P(U(g)?.t));return{...o,events:f,remoteSpyIntegration:{status:"captured",returned:p.length,duplicateKey:"remoteId",note:"Polls can repeat remote entries; de-duplicate by remoteId or pass sinceRemoteTime."}}}catch(i){return{...o,remoteSpyIntegration:{status:"read-failed",error:i instanceof Error?i.message:String(i)}}}}function Tn(e){return U(e.target)}function In(e){let t=Tn(e);return A(t?.expression)??A(t?.path)??`${A(e.inputType)??"event"}:${A(e.keyCode)??""}`}function Sr(e,t){if(e==null)return"nil";if(typeof e=="string"){let r=/^\$\{([^}]+)\}$/.exec(e);return r?t.get(r[1])==="number"?e:`[=[${e}]=]`:s(e)}if(typeof e=="boolean")return e?"true":"false";if(typeof e=="number")return Number.isFinite(e)?String(e):"0";if(Array.isArray(e))return`{ ${e.map(r=>Sr(r,t)).join(", ")} }`;let n=U(e);return n?`{ ${Object.entries(n).map(([r,a])=>`[${s(r)}] = ${Sr(a,t)}`).join(", ")} }`:"nil"}function kd(e,t){let n=new Map(t.map(a=>[String(a.name),String(a.type)])),r=["-- REVIEW REQUIRED: teach-mode inferred correlation and ordering, not the user's intent.","-- Validate selectors, timing, guards, and all server-reaching operations before saving or running.","local results = {}","local function guardTarget(expression, expectedClass)",'  local loader, loadErr = loadstring("return " .. expression)',"  if not loader then return false, loadErr end","  local ok, target = pcall(loader)",'  if not ok or typeof(target) ~= "Instance" then return false, tostring(target) end','  if expectedClass and expectedClass ~= "" and not target:IsA(expectedClass) then','    return false, "expected " .. expectedClass .. ", got " .. target.ClassName',"  end","  return true","end"];for(let a of e){let o=U(a),i=A(o.id)??`step-${r.length}`,l=Math.max(0,Math.min(5e3,Math.round(P(o.waitBeforeMs)))),c=U(o.candidate),d=A(c?.tool),p=U(c?.inputTemplate)??{},f=U(o.selector),h=A(o.pathPlaceholder),g=A(f?.className);if(r.push(`-- ${i}: ${d??"manual observation"}`),l>0&&r.push(`task.wait(${(l/1e3).toFixed(3)})`),h&&g&&r.push(`do local ok, err = guardTarget(${Sr(h,n)}, ${s(g)}); if not ok then error(${s(`${i} guard failed: `)} .. tostring(err)) end end`),!!d){if(d==="fire-remote"){r.push(`-- OMITTED ${i}: fire-remote can affect the server and its captured arguments may be lossy; insert only after manual review.`);continue}r.push(`results[${s(i)}] = mcp.call(${s(d)}, ${Sr(p,n)})`)}}return r.push("return { draft = true, results = results }"),r.join(`
`)}function xd(e){let t=(Array.isArray(e.events)?e.events:[]).map(U).filter(S=>S!==null).sort((S,x)=>P(S.t)-P(x.t)),n=[],r=new Map,a=[],o=["Intent is not inferred perfectly: the draft preserves observed correlation and order only."],i=new Set,l=t.filter(S=>S.kind==="gui_activated").map(S=>P(S.t)),c=new Map,d=null,p=new Set,f=0,h=0,g=(S,x,E,G,X)=>{let ee=`${x}:${String(E)}`,K=r.get(ee);if(K)return`\${${K}}`;let M=`${S.replace(/[^a-zA-Z0-9_]/g,"_").replace(/^_+/,"")||"value"}_${n.length+1}`;return r.set(ee,M),n.push({name:M,type:x,default:E,evidence:G,description:X}),`\${${M}}`},b=(S,x)=>{let E=[];if(x){E.push({type:"target-exists",selector:x,reason:"The demonstrated action referenced this live instance."});let G=c.get(In(S));G&&E.push({type:"target-visible",evidenceSeq:G.seq,reason:"The target appeared before the action in the demonstration."})}return d&&E.push({type:"character-ready",evidenceSeq:d.seq,reason:"A character-ready/respawn event preceded this action."}),p.size>0&&E.push({type:"tool-equipped",names:[...p],reason:"These tools were equipped at this point in the observed ordering."}),E},m=(S,x,E,G,X,ee)=>{let K=P(S.t),re=Tn(S),M=Math.max(0,K-f),Ne=Math.min(5e3,Math.max(0,Math.round(M*1e3-50)));f=K,a.push({id:`step-${a.length+1}`,observedAtSec:K,waitBeforeMs:Ne,waitEvidence:{observedGapMs:Math.round(M*1e3),note:"Capped ordering delay; user think-time is not treated as required timing."},guards:b(S,re),candidate:{tool:x,inputTemplate:E},selector:re,...ee?{pathPlaceholder:ee}:{},confidence:G,uncertainty:X,manualReview:X.length>0,evidence:{eventKind:S.kind,seq:S.seq,remoteId:S.remoteId}}),o.push(...X)},y=(S,x)=>{let E=Tn(S),G=A(E?.expression)??A(E?.path);if(!(!G||!E))return g(x,"LuauInstanceExpression",G,E,"Re-resolve this semantic target in the current game before execution.")},w=(S,x)=>{let E=P(x.inputId,-1),G=A(x.inputType),X=A(x.keyCode),ee=P(x.t);for(let K=S+1;K<t.length;K+=1){let re=t[K];if(P(re.t)-ee>10||re.kind==="input_began"&&In(re)===In(x))break;if(re.kind!=="input_ended")continue;let M=E>=0&&P(re.inputId,-2)===E,Ne=A(re.inputType)===G&&A(re.keyCode)===X;if((M||Ne)&&!i.has(K))return K}};for(let S=0;S<t.length;S+=1){let x=t[S],E=A(x.kind)??"unknown";if(E==="character_ready"||E==="character_respawned"){d=x;continue}if(E==="character_removing"){d=null,p.clear();continue}if(E==="gui_appeared"){c.set(In(x),x);continue}if(E==="gui_disappeared"){c.delete(In(x));continue}if(E==="tool_equipped"){let M=A(Tn(x)?.name);M&&p.add(M);continue}if(E==="tool_unequipped"){let M=A(Tn(x)?.name);M&&p.delete(M);continue}if(E==="gui_activated"){let M=y(x,"button_path");M&&m(x,"click-button",{path:M,action:"Activated"},"medium",["Activated proves the button fired, but does not prove why the user chose it."],M);continue}if(E==="proximity_triggered"){let M=y(x,"prompt_path");M&&m(x,"fire-proximity-prompt",{path:M},"medium",["Prompt triggering may have distance, hold-duration, or server-side consequences."],M);continue}if(E==="remote_call"){let M=y(x,"remote_path");if(!M)continue;let qr=(Array.isArray(x.args)?x.args:[]).map((Te,yc)=>{if(typeof Te=="string")return{kind:"string",value:Te};if(typeof Te=="number")return{kind:"number",value:Te};if(typeof Te=="boolean")return{kind:"boolean",value:Te};if(Te===null)return{kind:"nil"};let ja=U(Te),vc=ja?.path??ja?.value??Te;return{kind:"raw",value:g(`remote_arg_${yc+1}`,"LuauExpression","nil",vc,"Non-primitive remote argument was shallow-captured and must be reconstructed manually.")}}),qn=["Remote replay can mutate server state and is intentionally omitted from the executable source draft.","Remote arguments are shallow observations and may not preserve identity or nested table structure."];x.argsTruncated===!0&&qn.push("The remote argument list was truncated."),m(x,"fire-remote",{remotePath:M,mode:A(x.method)??"FireServer",args:qr},"low",qn,M);continue}if(E==="input_changed"&&x.inputType==="MouseMovement"){h+=1;continue}if(E==="input_ended"&&i.has(S)||E!=="input_began"&&E!=="input_changed"&&E!=="input_ended")continue;let G=A(x.inputType)??"Unknown",X=A(x.keyCode),ee=E==="input_began"?w(S,x):void 0,K=ee!==void 0?t[ee]:void 0;ee!==void 0&&i.add(ee);let re=K?Math.max(0,Math.min(10,P(K.t)-P(x.t))):0;if(G==="Keyboard"&&X&&X!=="Unknown"&&E==="input_began"){let M=g("key","Enum.KeyCodeName",X,x,"Observed keyboard key.");m(x,"virtual-input",{action:K?"keyPress":"keyDown",key:M,holdSec:re},"medium",K?[]:["No matching key-up was retained; review for a potentially held key."]);continue}if((G==="MouseButton1"||G==="MouseButton2"||G==="MouseButton3")&&E==="input_began"){let M=P(x.t);if(l.some(qn=>Math.abs(qn-M)<=.35))continue;let Ne=g("mouse_x","number",P(x.x),x,"Observed viewport X coordinate."),qr=g("mouse_y","number",P(x.y),x,"Observed viewport Y coordinate.");m(x,"virtual-input",{action:"mouseButton",x:Ne,y:qr,button:G==="MouseButton2"?"Right":G==="MouseButton3"?"Middle":"Left",buttonAction:K?"click":"down",holdSec:re},"low",["Screen coordinates are resolution/layout dependent; prefer a semantic GUI selector when possible."]);continue}if(G==="Touch"){let M=g("touch_x","number",P(x.x),x,"Observed touch X coordinate."),Ne=g("touch_y","number",P(x.y),x,"Observed touch Y coordinate.");m(x,"virtual-input",{action:"touch",x:M,y:Ne,touchId:P(x.inputId),touchState:E==="input_ended"?"End":E==="input_changed"?"Change":"Begin"},"low",["Touch identifiers and coordinates may differ on another device or viewport."]);continue}G==="MouseWheel"&&E==="input_changed"&&m(x,"virtual-input",{action:"mouseWheel",delta:P(x.wheelDelta)},"medium",["Wheel delta interpretation can vary with platform and UI focus."])}h>0&&o.push(`${h} throttled mouse-movement event(s) were retained as evidence but omitted from the draft to avoid fragile cursor choreography.`);let C=P(e.dropped);C>0&&o.push(`${C} oldest event(s) were overwritten by the bounded ring buffer.`);let I=U(e.stats);I?.guiWatchTruncated===!0&&o.push("The bounded GUI watcher cap was reached; some UI transitions may be absent."),I?.connectionLimitReached===!0&&o.push("The listener cap was reached; later dynamic objects may not have been observed."),a.length===0&&o.push("No replay candidate was inferred from the retained events.");let N=md(o),O=Object.fromEntries(n.map(S=>[String(S.name),S.default])),q=a.some(S=>U(S.candidate)?.tool==="fire-remote"||S.confidence==="low");return{version:1,kind:"teach-mode-conservative-draft",sourceSessionId:e.sessionId,reusable:!0,autoExecutable:!1,disclaimer:"This is a conservative reconstruction of observed events. It does not claim perfect intent inference and must be reviewed before execution.",parameters:n,defaultParams:O,steps:a,sourceDraft:kd(a,n),saveCandidate:{tool:"playbook-save",inputTemplate:{name:"reviewed-teach-mode-demo",source:"<sourceDraft after review>",params:n.map(S=>S.name),tags:["teach-mode","generated","review-required"]}},uncertainty:{overall:q||C>0?"high":"medium",reasons:N},manualReviewRequired:!0,manualReviewFlags:N}}function _d(e){let t=e.requestedSessionId?s(e.requestedSessionId):"nil";return`
if type(getgenv) ~= "function" then return { error = "getgenv is required for persistent teach-mode sessions" } end
local genv = getgenv()
local function clock() return os.clock() end

local state = genv.__mcp_teachMode
if type(state) ~= "table" or state.version ~= 1 or type(state.sessions) ~= "table" then
  if type(state) == "table" and type(state.sessions) == "table" then
    for _, oldSession in pairs(state.sessions) do
      if type(oldSession) == "table" and type(oldSession.connections) == "table" then
        for _, connection in ipairs(oldSession.connections) do pcall(function() connection:Disconnect() end) end
      end
    end
  end
  state = { version = 1, sessions = {}, current = nil, serial = 0 }
  genv.__mcp_teachMode = state
end

local function restoreRemoteTrace()
  local trace = genv.__mcp_remoteTrace
  if type(trace) ~= "table" then return true end
  local restored = false
  if type(trace.orig) == "function" and type(hookmetamethod) == "function" then
    restored = pcall(hookmetamethod, game, "__namecall", trace.orig)
  end
  if (not restored) and type(trace.hook) == "function" and type(restorefunction) == "function" then
    restored = pcall(restorefunction, trace.hook)
  end
  if restored then genv.__mcp_remoteTrace = nil end
  return restored
end

local function transferOrRestoreRemote(session)
  if not session.remoteSpyOwned then return false end
  for _, candidate in pairs(state.sessions) do
    if candidate ~= session and candidate.active and candidate.remoteSpyEnabled then
      candidate.remoteSpyOwned = true
      session.remoteSpyOwned = false
      return false
    end
  end
  session.remoteSpyOwned = false
  restoreRemoteTrace()
  return true
end

local function disconnectSession(session, reason, releaseRemote)
  if type(session) ~= "table" then return 0, 0 end
  session.active = false
  session.stopReason = reason
  session.stoppedAt = clock()
  local disconnected, errors = 0, 0
  for _, connection in ipairs(session.connections or {}) do
    local ok = pcall(function() connection:Disconnect() end)
    if ok then disconnected = disconnected + 1 else errors = errors + 1 end
  end
  session.connections = {}
  if releaseRemote then transferOrRestoreRemote(session) end
  return disconnected, errors
end

local expiredSessions = {}
for id, session in pairs(state.sessions) do
  local expiry = tonumber(session.expirySeconds) or ${e.expirySeconds}
  if (not session.active) or (clock() - (session.lastTouched or session.startedAt or 0) >= expiry) then
    disconnectSession(session, "expired", true)
    state.sessions[id] = nil
    if state.current == id then state.current = nil end
    expiredSessions[#expiredSessions + 1] = id
  end
end

local requestedId = ${t}
if requestedId and state.sessions[requestedId] and state.sessions[requestedId].active then
  return { error = "teach-mode session already exists", sessionId = requestedId, active = true }
end

local activeCount = 0
local oldestId, oldestSession = nil, nil
for id, session in pairs(state.sessions) do
  if session.active then
    activeCount = activeCount + 1
    if not oldestSession or session.startedAt < oldestSession.startedAt then oldestId, oldestSession = id, session end
  end
end
local inheritedRemoteOwnership = false
if activeCount >= 3 and oldestSession then
  if oldestSession.remoteSpyOwned and ${e.remoteSpyEnabled?"true":"false"} then
    local hasOtherRemoteSession = false
    for _, candidate in pairs(state.sessions) do
      if candidate ~= oldestSession and candidate.active and candidate.remoteSpyEnabled then
        hasOtherRemoteSession = true
        break
      end
    end
    if not hasOtherRemoteSession then
      oldestSession.remoteSpyOwned = false
      inheritedRemoteOwnership = true
    end
  end
  disconnectSession(oldestSession, "evicted-by-session-cap", true)
  state.sessions[oldestId] = nil
  expiredSessions[#expiredSessions + 1] = oldestId
end

state.serial = (state.serial or 0) + 1
local sessionId = requestedId or ("teach-" .. tostring(math.floor(clock() * 1000)) .. "-" .. tostring(state.serial))
local session = {
  id = sessionId,
  active = true,
  startedAt = clock(),
  lastTouched = clock(),
  expirySeconds = ${e.expirySeconds},
  maxEvents = ${e.maxEvents},
  buffer = {},
  head = 1,
  size = 0,
  seq = 0,
  dropped = 0,
  connections = {},
  connectionCap = math.min(${e.maxGuiWatch} * 2 + 96, 2200),
  movementThrottleSeconds = ${e.movementThrottleMs} / 1000,
  movementLast = {},
  inputIds = setmetatable({}, { __mode = "k" }),
  nextInputId = 0,
  watchedGui = setmetatable({}, { __mode = "k" }),
  maxGuiWatch = ${e.maxGuiWatch},
  guiWatchCount = 0,
  remoteSpyEnabled = ${e.remoteSpyEnabled?"true":"false"},
  remoteSpyOwned = ${e.remoteSpyOwned?"true":"false"} or inheritedRemoteOwnership,
  stats = { kindCounts = {}, guiWatchTruncated = false, connectionLimitReached = false },
}
state.sessions[sessionId] = session
state.current = sessionId

local function push(event)
  if not session.active then return end
  local at = clock()
  session.lastTouched = at
  session.seq = session.seq + 1
  event.seq = session.seq
  event.t = math.max(0, at - session.startedAt)
  local index
  if session.size < session.maxEvents then
    index = ((session.head + session.size - 1) % session.maxEvents) + 1
    session.size = session.size + 1
  else
    index = session.head
    session.head = (session.head % session.maxEvents) + 1
    session.dropped = session.dropped + 1
  end
  session.buffer[index] = event
  local kind = tostring(event.kind or "unknown")
  session.stats.kindCounts[kind] = (session.stats.kindCounts[kind] or 0) + 1
end

local function connect(signal, callback)
  if not session.active then return nil end
  if #session.connections >= session.connectionCap then
    if not session.stats.connectionLimitReached then
      session.stats.connectionLimitReached = true
      push({ kind = "listener_limit_reached", cap = session.connectionCap })
    end
    return nil
  end
  local ok, connection = pcall(function() return signal:Connect(callback) end)
  if ok and connection then
    session.connections[#session.connections + 1] = connection
    return connection
  end
  return nil
end

local function selector(instance)
  if typeof(instance) ~= "Instance" then return nil end
  local result = {}
  pcall(function() result.name = instance.Name end)
  pcall(function() result.className = instance.ClassName end)
  pcall(function() result.path = instance:GetFullName() end)

  local hierarchy = {}
  local current = instance
  local truncated = false
  while current and current ~= game do
    if #hierarchy >= 32 then truncated = true break end
    local segment = { name = current.Name, className = current.ClassName }
    table.insert(hierarchy, 1, segment)
    current = current.Parent
  end
  result.hierarchy = hierarchy
  result.hierarchyTruncated = truncated

  if not truncated and current == game and #hierarchy > 0 then
    local root = hierarchy[1]
    local expression
    local okService, service = pcall(function() return game:GetService(root.className) end)
    if okService and service and service.Name == root.name then
      expression = "game:GetService(" .. string.format("%q", root.className) .. ")"
    else
      expression = "game:FindFirstChild(" .. string.format("%q", root.name) .. ")"
    end
    for index = 2, #hierarchy do
      expression = expression .. ":FindFirstChild(" .. string.format("%q", hierarchy[index].name) .. ")"
    end
    result.expression = expression
  end

  pcall(function()
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
      result.text = string.sub(instance.Text or "", 1, 160)
    end
  end)
  pcall(function()
    if instance:IsA("GuiObject") then
      result.visible = instance.Visible
      result.absolutePosition = { x = instance.AbsolutePosition.X, y = instance.AbsolutePosition.Y }
      result.absoluteSize = { x = instance.AbsoluteSize.X, y = instance.AbsoluteSize.Y }
    elseif instance:IsA("ScreenGui") then
      result.visible = instance.Enabled
    end
  end)
  pcall(function()
    local collection = game:GetService("CollectionService")
    local tags = collection:GetTags(instance)
    result.tags = {}
    for index = 1, math.min(#tags, 8) do result.tags[index] = tags[index] end
  end)
  pcall(function()
    local all = instance:GetAttributes()
    local attributes, count = {}, 0
    for key, value in pairs(all) do
      local valueType = typeof(value)
      if valueType == "string" or valueType == "number" or valueType == "boolean" then
        attributes[key] = value
        count = count + 1
        if count >= 8 then break end
      end
    end
    result.attributes = attributes
  end)
  return result
end

local function inputSnapshot(input, gameProcessed)
  local inputType, keyCode = "Unknown", "Unknown"
  pcall(function() inputType = input.UserInputType.Name end)
  pcall(function() keyCode = input.KeyCode.Name end)
  local inputId = session.inputIds[input]
  if not inputId then
    session.nextInputId = session.nextInputId + 1
    inputId = session.nextInputId
    session.inputIds[input] = inputId
  end
  local event = {
    inputId = inputId,
    inputType = inputType,
    keyCode = keyCode,
    gameProcessed = gameProcessed == true,
  }
  pcall(function()
    event.x = input.Position.X
    event.y = input.Position.Y
    event.z = input.Position.Z
    if inputType == "MouseWheel" then event.wheelDelta = input.Position.Z end
  end)
  pcall(function()
    event.deltaX = input.Delta.X
    event.deltaY = input.Delta.Y
    event.deltaZ = input.Delta.Z
  end)
  return event
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = Players.LocalPlayer

push({
  kind = "session_started",
  character = localPlayer and selector(localPlayer.Character) or nil,
  maxEvents = session.maxEvents,
  movementThrottleMs = ${e.movementThrottleMs},
})

connect(UserInputService.InputBegan, function(input, gameProcessed)
  local event = inputSnapshot(input, gameProcessed)
  event.kind = "input_began"
  push(event)
end)
connect(UserInputService.InputEnded, function(input, gameProcessed)
  local event = inputSnapshot(input, gameProcessed)
  event.kind = "input_ended"
  push(event)
end)
connect(UserInputService.InputChanged, function(input)
  local event = inputSnapshot(input, false)
  local moving = event.inputType == "MouseMovement" or event.inputType == "Touch" or string.find(event.inputType, "Gamepad", 1, true) ~= nil
  if moving then
    local last = session.movementLast[event.inputType] or 0
    local at = clock()
    if at - last < session.movementThrottleSeconds then return end
    session.movementLast[event.inputType] = at
  end
  event.kind = "input_changed"
  push(event)
end)

connect(ProximityPromptService.PromptTriggered, function(prompt, playerWhoTriggered)
  push({
    kind = "proximity_triggered",
    target = selector(prompt),
    player = playerWhoTriggered and playerWhoTriggered.Name or nil,
  })
end)

local function relevantGui(instance)
  return instance:IsA("ScreenGui") or instance:IsA("GuiObject")
end

local watchGui
watchGui = function(instance)
  if not session.active or session.watchedGui[instance] or not relevantGui(instance) then return end
  if session.guiWatchCount >= session.maxGuiWatch then
    session.stats.guiWatchTruncated = true
    return
  end
  session.watchedGui[instance] = true
  session.guiWatchCount = session.guiWatchCount + 1

  if instance:IsA("ScreenGui") then
    connect(instance:GetPropertyChangedSignal("Enabled"), function()
      push({ kind = instance.Enabled and "gui_appeared" or "gui_disappeared", target = selector(instance), reason = "Enabled changed" })
    end)
  elseif instance:IsA("GuiObject") then
    connect(instance:GetPropertyChangedSignal("Visible"), function()
      push({ kind = instance.Visible and "gui_appeared" or "gui_disappeared", target = selector(instance), reason = "Visible changed" })
    end)
  end
  if instance:IsA("GuiButton") then
    connect(instance.Activated, function(input)
      local inputType = nil
      pcall(function() inputType = input and input.UserInputType.Name or nil end)
      push({ kind = "gui_activated", target = selector(instance), inputType = inputType })
    end)
  end
end

if localPlayer then
  local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5)
  if playerGui then
    local queue, queueIndex = { playerGui }, 1
    local scanned, scanCap = 0, session.maxGuiWatch * 4
    while queueIndex <= #queue and scanned < scanCap and session.guiWatchCount < session.maxGuiWatch do
      local parent = queue[queueIndex]
      queueIndex = queueIndex + 1
      local children = parent:GetChildren()
      for _, descendant in ipairs(children) do
        scanned = scanned + 1
        if relevantGui(descendant) then watchGui(descendant) end
        if scanned < scanCap and session.guiWatchCount < session.maxGuiWatch then
          queue[#queue + 1] = descendant
        end
        if scanned >= scanCap or session.guiWatchCount >= session.maxGuiWatch then break end
      end
    end
    if queueIndex <= #queue or scanned >= scanCap or session.guiWatchCount >= session.maxGuiWatch then
      session.stats.guiWatchTruncated = true
    end
    connect(playerGui.DescendantAdded, function(descendant)
      if relevantGui(descendant) then
        push({ kind = "gui_appeared", target = selector(descendant), reason = "DescendantAdded" })
        watchGui(descendant)
      end
    end)
    connect(playerGui.DescendantRemoving, function(descendant)
      if session.watchedGui[descendant] then
        push({ kind = "gui_disappeared", target = selector(descendant), reason = "DescendantRemoving" })
      end
    end)
  end
end

local function watchCharacter(character, reason)
  if not character then return end
  push({ kind = reason == "initial" and "character_ready" or "character_respawned", target = selector(character), reason = reason })
  connect(character.ChildAdded, function(child)
    if child:IsA("Tool") then push({ kind = "tool_equipped", target = selector(child) }) end
  end)
  connect(character.ChildRemoved, function(child)
    if child:IsA("Tool") then push({ kind = "tool_unequipped", target = selector(child) }) end
  end)
  for _, child in ipairs(character:GetChildren()) do
    if child:IsA("Tool") then push({ kind = "tool_equipped", target = selector(child), reason = "initial" }) end
  end
end

if localPlayer then
  connect(localPlayer.CharacterAdded, function(character) watchCharacter(character, "CharacterAdded") end)
  connect(localPlayer.CharacterRemoving, function(character)
    push({ kind = "character_removing", target = selector(character) })
  end)
  watchCharacter(localPlayer.Character, "initial")
  local backpack = localPlayer:FindFirstChildOfClass("Backpack") or localPlayer:FindFirstChild("Backpack")
  if backpack then
    connect(backpack.ChildAdded, function(child)
      if child:IsA("Tool") then push({ kind = "tool_backpack_added", target = selector(child) }) end
    end)
    connect(backpack.ChildRemoved, function(child)
      if child:IsA("Tool") then push({ kind = "tool_backpack_removed", target = selector(child) }) end
    end)
  end
end

local scheduleExpiry
scheduleExpiry = function(delaySeconds)
  task.delay(math.max(1, delaySeconds), function()
    if state.sessions[sessionId] ~= session or not session.active then return end
    local idle = clock() - session.lastTouched
    local remaining = session.expirySeconds - idle
    if remaining <= 0 then
      disconnectSession(session, "expired", true)
      state.sessions[sessionId] = nil
      if state.current == sessionId then state.current = nil end
    else
      scheduleExpiry(remaining)
    end
  end)
end
scheduleExpiry(session.expirySeconds)

return {
  ok = true,
  action = "start",
  sessionId = sessionId,
  active = true,
  startedAt = session.startedAt,
  expiresAfterIdleSeconds = session.expirySeconds,
  maxEvents = session.maxEvents,
  movementThrottleMs = ${e.movementThrottleMs},
  maxGuiWatch = session.maxGuiWatch,
  connectionCap = session.connectionCap,
  connections = #session.connections,
  eventCount = session.size,
  cursor = session.seq,
  expiredSessions = expiredSessions,
  remoteSpyEnabled = session.remoteSpyEnabled,
  remoteSpyOwned = session.remoteSpyOwned,
  stats = session.stats,
}
`}function wd(e){return`
if type(getgenv) ~= "function" then return { error = "getgenv is required for persistent teach-mode sessions" } end
local genv = getgenv()
local state = genv.__mcp_teachMode
if type(state) ~= "table" or type(state.sessions) ~= "table" then
  return { error = "no teach-mode session is running", active = false }
end
local function clock() return os.clock() end

local function restoreRemoteTrace()
  local trace = genv.__mcp_remoteTrace
  if type(trace) ~= "table" then return true end
  local restored = false
  if type(trace.orig) == "function" and type(hookmetamethod) == "function" then
    restored = pcall(hookmetamethod, game, "__namecall", trace.orig)
  end
  if (not restored) and type(trace.hook) == "function" and type(restorefunction) == "function" then
    restored = pcall(restorefunction, trace.hook)
  end
  if restored then genv.__mcp_remoteTrace = nil end
  return restored
end

local function transferOrRestoreRemote(session)
  if not session.remoteSpyOwned then return false end
  for _, candidate in pairs(state.sessions) do
    if candidate ~= session and candidate.active and candidate.remoteSpyEnabled then
      candidate.remoteSpyOwned = true
      session.remoteSpyOwned = false
      return false
    end
  end
  session.remoteSpyOwned = false
  restoreRemoteTrace()
  return true
end

local function disconnectSession(session, reason, releaseRemote)
  session.active = false
  session.stopReason = reason
  session.stoppedAt = clock()
  local disconnected, errors = 0, 0
  for _, connection in ipairs(session.connections or {}) do
    local ok = pcall(function() connection:Disconnect() end)
    if ok then disconnected = disconnected + 1 else errors = errors + 1 end
  end
  session.connections = {}
  if releaseRemote then transferOrRestoreRemote(session) end
  return disconnected, errors
end

local expiredSessions = {}
for id, session in pairs(state.sessions) do
  local expiry = tonumber(session.expirySeconds) or 600
  if (not session.active) or (clock() - (session.lastTouched or session.startedAt or 0) >= expiry) then
    disconnectSession(session, "expired", true)
    state.sessions[id] = nil
    if state.current == id then state.current = nil end
    expiredSessions[#expiredSessions + 1] = id
  end
end

local requestedId = ${e.requestedSessionId?s(e.requestedSessionId):"nil"}
local sessionId = requestedId or state.current
local session = sessionId and state.sessions[sessionId] or nil
if type(session) ~= "table" or not session.active then
  return { error = "teach-mode session not found or expired", sessionId = sessionId, active = false, expiredSessions = expiredSessions }
end

local function push(event)
  if not session.active then return end
  local at = clock()
  session.lastTouched = at
  session.seq = session.seq + 1
  event.seq = session.seq
  event.t = math.max(0, at - session.startedAt)
  local index
  if session.size < session.maxEvents then
    index = ((session.head + session.size - 1) % session.maxEvents) + 1
    session.size = session.size + 1
  else
    index = session.head
    session.head = (session.head % session.maxEvents) + 1
    session.dropped = session.dropped + 1
  end
  session.buffer[index] = event
  local kind = tostring(event.kind or "unknown")
  session.stats.kindCounts[kind] = (session.stats.kindCounts[kind] or 0) + 1
end

local function snapshot(sinceSeq, limit)
  local events, eligible, returned, cursor = {}, 0, 0, sinceSeq
  for offset = 0, session.size - 1 do
    local index = ((session.head + offset - 1) % session.maxEvents) + 1
    local event = session.buffer[index]
    if event and (event.seq or 0) > sinceSeq then
      eligible = eligible + 1
      if returned < limit then
        returned = returned + 1
        events[returned] = event
        cursor = math.max(cursor, event.seq or cursor)
      end
    end
  end
  return events, cursor, eligible > returned, eligible
end

local action = ${s(e.action)}
if action == "poll" then
  session.lastTouched = clock()
  local events, cursor, hasMore, eligible = snapshot(${e.sinceSeq}, ${e.limit})
  return {
    ok = true,
    action = action,
    sessionId = sessionId,
    active = true,
    startedAt = session.startedAt,
    elapsedSeconds = clock() - session.startedAt,
    events = events,
    cursor = cursor,
    newestSeq = session.seq,
    hasMore = hasMore,
    eligible = eligible,
    retained = session.size,
    dropped = session.dropped,
    maxEvents = session.maxEvents,
    connections = #session.connections,
    expiredSessions = expiredSessions,
    remoteSpyEnabled = session.remoteSpyEnabled,
    remoteSpyOwned = session.remoteSpyOwned,
    stats = session.stats,
  }
end

local releaseRemote = session.remoteSpyOwned == true
if releaseRemote then
  for _, candidate in pairs(state.sessions) do
    if candidate ~= session and candidate.active and candidate.remoteSpyEnabled then
      candidate.remoteSpyOwned = true
      releaseRemote = false
      break
    end
  end
end
session.remoteSpyOwned = false

if action == "cancel" then
  local discarded = session.size
  local disconnected, disconnectErrors = disconnectSession(session, "cancelled", false)
  state.sessions[sessionId] = nil
  if state.current == sessionId then state.current = nil end
  return {
    ok = true,
    action = action,
    sessionId = sessionId,
    active = false,
    cancelled = true,
    discarded = discarded,
    connectionsDisconnected = disconnected,
    disconnectErrors = disconnectErrors,
    remoteSpyEnabled = session.remoteSpyEnabled,
    remoteSpyOwned = releaseRemote,
    expiredSessions = expiredSessions,
  }
end

push({ kind = "session_stopped", reason = "stop" })
local events, cursor, hasMore, eligible = snapshot(0, session.maxEvents)
local disconnected, disconnectErrors = disconnectSession(session, "stopped", false)
state.sessions[sessionId] = nil
if state.current == sessionId then state.current = nil end
return {
  ok = true,
  action = "stop",
  sessionId = sessionId,
  active = false,
  stopped = true,
  startedAt = session.startedAt,
  elapsedSeconds = clock() - session.startedAt,
  events = events,
  cursor = cursor,
  eligible = eligible,
  retained = session.size,
  dropped = session.dropped,
  timelineTruncated = session.dropped > 0 or hasMore,
  maxEvents = session.maxEvents,
  connectionsDisconnected = disconnected,
  disconnectErrors = disconnectErrors,
  remoteSpyEnabled = session.remoteSpyEnabled,
  remoteSpyOwned = releaseRemote,
  expiredSessions = expiredSessions,
  stats = session.stats,
}
`}var ll=u({name:"teach-mode",title:"Record a user demonstration and draft a reusable playbook",description:"Event-driven demonstration recorder with start, poll, stop, and cancel actions. It uses bounded client-side ring buffers and temporary Roblox signal connections to observe keyboard, mouse, touch, throttled movement, GuiButton activation, meaningful GUI appearance/disappearance, ProximityPrompt triggers, character respawns, and Tool equip/backpack transitions. Optional remote capture is started and read through trace-remote-traffic via the normal nested-tool invoker when that tool and executor capabilities are available. stop disconnects every owned listener, returns the retained chronological timeline, and builds a conservative review-required playbook draft with semantic selectors, path evidence, virtual-input/click-button/fire-proximity-prompt and remote candidates, inferred waits/guards, placeholders, uncertainty, and manual-review flags. It does not claim perfect intent inference. cancel disconnects and discards. Idle sessions self-expire and a three-session cap evicts the oldest recorder to prevent leaked listeners.",category:"Intelligence",mutatesState:!0,ai:{phase:"orchestrate",prerequisites:["An active Roblox client","The user is ready to demonstrate the workflow after action=start"],consumes:["User demonstration events","Optional outgoing remote-spy observations","A teach-mode sessionId for poll/stop/cancel"],produces:["Bounded chronological event timeline","Semantic instance selectors and path evidence","Conservative reusable playbook draft with uncertainty and review flags"],verifiesWith:["teach-mode action=poll to confirm events are arriving","Manual review of selectors, guards, timing, and server-reaching candidates","Run the reviewed playbook in a disposable/test game state and verify outcomes"],alternatives:["observe-world for a point-in-time world snapshot","trace-remote-traffic for remote-only capture","script for a manually authored workflow"],requiresCapabilities:["UserInputService and Roblox RBXScriptSignal connections","getgenv for state across calls","Optional hookmetamethod/getnamecallmethod/newcclosure for remote capture"],sideEffects:["Temporarily installs bounded signal listeners in the active client","May temporarily install a remote-spy metamethod hook when explicitly requested","Does not execute the generated playbook automatically"],failureRecovery:["Call teach-mode action=cancel with the sessionId to disconnect and discard","stop/cancel restores an owned remote-spy hook; a direct restoration is used if nested cleanup fails","Idle sessions disconnect automatically and the oldest session is evicted beyond the three-session cap"]},input:ue.object({action:ue.enum(["start","poll","stop","cancel"]).describe("start creates the recorder; poll returns retained events after sinceSeq; stop disconnects and returns the timeline plus a conservative playbook draft; cancel disconnects and discards the recording."),sessionId:ue.string().min(1).max(128).optional().describe("Optional stable recording id. start generates one when omitted; later actions default to the newest active session."),maxEvents:ue.number().int().min(50).max(5e3).optional().default(1e3).describe("start only: circular timeline capacity; oldest events are overwritten and counted."),movementThrottleMs:ue.number().int().min(25).max(1e3).optional().default(100).describe("start only: minimum interval for mouse/touch/gamepad movement observations."),expirySeconds:ue.number().int().min(30).max(3600).optional().default(600).describe("start only: idle time before automatic disconnection and session removal."),maxGuiWatch:ue.number().int().min(25).max(1e3).optional().default(350).describe("start only: cap on watched GuiObjects/ScreenGuis to keep listener overhead bounded."),sinceSeq:ue.number().int().nonnegative().optional().default(0).describe("poll only: return retained local events whose sequence is greater than this cursor."),limit:ue.number().int().min(1).max(2e3).optional().default(250).describe("poll only: maximum local timeline events returned in this page."),includeRemoteSpy:ue.boolean().optional().default(!1).describe("start only: request outgoing remote capture through trace-remote-traffic. Failure is non-fatal and reported."),remoteLimit:ue.number().int().min(1).max(500).optional().default(250).describe("Maximum remote-spy entries merged into poll/stop results."),sinceRemoteTime:ue.number().nonnegative().optional().default(0).describe("poll only: omit remote events at or before this many seconds since recording start."),threadContext:ue.number().int().optional()}),async execute({action:e,sessionId:t,maxEvents:n,movementThrottleMs:r,expirySeconds:a,maxGuiWatch:o,sinceSeq:i,limit:l,includeRemoteSpy:c,remoteLimit:d,sinceRemoteTime:p,threadContext:f},h){if(e==="start"){let I=await hd(c,d,f,h),N=_d({...t?{requestedSessionId:t}:{},maxEvents:n,movementThrottleMs:r,expirySeconds:a,maxGuiWatch:o,remoteSpyEnabled:I.enabled,remoteSpyOwned:I.owned}),O;try{O=await h.runLuau(N,{threadContext:f,timeoutMs:3e4})}catch(S){throw I.owned&&await _r(!0,f,h),S}let q=U(O);if(A(q?.error)){let S=await _r(I.owned,f,h);return{data:{...q,remoteSpyIntegration:I,remoteSpyCleanup:S},isError:!0,summary:"Teach-mode did not start; any newly owned remote-spy hook was cleaned up."}}return{data:{...q??{raw:O},remoteSpyIntegration:I},summary:"Teach-mode is recording. Demonstrate the workflow, poll with the returned sessionId, then stop to generate the review-required playbook draft."}}let g=wd({action:e,...t?{requestedSessionId:t}:{},sinceSeq:i,limit:l}),b=await h.runLuau(g,{threadContext:f,timeoutMs:e==="poll"?15e3:2e4}),m=U(b);if(A(m?.error))return{data:b,isError:!0,summary:A(m?.error)};if(e==="cancel"){let I=await _r(m?.remoteSpyOwned===!0,f,h);return{data:{...m??{raw:b},remoteSpyCleanup:I},summary:"Teach-mode recording cancelled; retained events were discarded and owned listeners were disconnected."}}let y=await vd(b,d,p,f,h);if(e==="poll")return{data:y,summary:"Teach-mode poll returned bounded event evidence. Continue from cursor/sinceRemoteTime or stop when the demonstration is complete."};let w=await _r(y.remoteSpyOwned===!0,f,h),C=xd(y);return{data:{...y,playbook:C,remoteSpyCleanup:w},summary:"Teach-mode stopped and disconnected its listeners. The returned playbook is a conservative review-required draft, not a claim of perfect intent inference."}}});import{z as $}from"zod";var Ca=["workspace","playerGui","character","camera","backpack","watched"],cl=["workspace-descendant-added","workspace-descendant-removing","player-gui-descendant-added","player-gui-descendant-removing","player-gui-replaced","character-added","character-removing","character-tool-added","character-tool-removing","camera-replaced","camera-property-changed","backpack-replaced","backpack-tool-added","backpack-tool-removing","watched-property-changed"],Sd=["CameraType","CameraSubject","FieldOfView","ViewportSize"];function Rn(e){return`{ ${e.map(s).join(", ")} }`}function Ea(e){return`{ ${e.map(t=>`[${s(t)}] = true`).join(", ")} }`}function Ed(e){return e.length===0?"{}":`{
`+e.map(t=>`  { expression = ${s(t.instancePath)}, properties = ${Rn([...new Set(t.properties)])} },`).join(`
`)+`
}`}function Cd(e){return e!==null&&typeof e=="object"&&!Array.isArray(e)?e:void 0}function Id(e,t){let n=Cd(t);if(!n)return{summary:`World-delta ${e} completed.`};if(typeof n.error=="string")return{summary:`World-delta ${e} failed: ${n.error}`,isError:!0};let r=typeof n.observerId=="string"?n.observerId:"observer";if(e==="start"){let i=typeof n.connections=="number"?n.connections:0;return{summary:`${r} is observing live world deltas through ${i} connections.`}}if(e==="poll"){let i=Array.isArray(n.events)?n.events.length:0,l=typeof n.nextCursor=="number"?n.nextCursor:"unknown",c=n.cursorGap===!0?" A buffer gap was reported.":"";return{summary:`${r} returned ${i} delta event(s); nextCursor=${l}.${c}`}}if(e==="stop"){let i=typeof n.disconnectedConnections=="number"?n.disconnectedConnections:0;return{summary:`${r} stopped and disconnected ${i} observer connection(s).`}}let a=typeof n.status=="string"?n.status:"inactive",o=n.active===!0?"active":a;return{summary:`${r} is ${o}.`}}var Td=$.object({instancePath:$.string().min(1).max(2048).describe("Explicit Luau expression resolving to an Instance, such as game.Workspace.Door or game.Players.LocalPlayer.PlayerGui.HUD. Expressions are evaluated only when action='start'."),properties:$.array($.string().min(1).max(128)).min(1).max(16).describe("Instance properties to subscribe to through GetPropertyChangedSignal.")}),Rd=$.object({action:$.enum(["start","poll","status","stop"]).describe("start installs a bounded observer, poll reads events after cursor, status reports health without consuming events, and stop disconnects every observer connection."),observerId:$.string().min(1).max(64).optional().describe("Observer id returned by start. For poll/status/stop, omission selects the newest active observer owned by this MCP session."),cursor:$.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER).optional().default(0).describe("Poll returns events whose monotonically increasing cursor is greater than this value. Always persist the returned nextCursor for the next poll."),limit:$.number().int().min(1).max(500).optional().default(100).describe("Maximum events returned by one poll; hasMore indicates another page."),maxEvents:$.number().int().min(16).max(2e3).optional().default(500).describe("Start-only ring-buffer capacity. Older events are evicted at the cap and reported through droppedEvents, droppedThrough, and cursorGap."),ttlSeconds:$.number().int().min(5).max(3600).optional().default(300).describe("Start-only fixed lifetime. A delayed cleanup retires the observer and disconnects every connection even if the AI never calls stop."),throttleMs:$.number().int().min(0).max(5e3).optional().default(50).describe("Minimum interval for storing repeated events with the same semantic key after their coalescing window."),coalesceWindowMs:$.number().int().min(0).max(5e3).optional().default(100).describe("Window in which identical source/kind/path/property events update one record and increment repeatCount."),filters:$.object({sources:$.array($.enum(Ca)).min(1).max(Ca.length).optional().describe("Event domains to subscribe to. Omit for all domains."),eventKinds:$.array($.enum(cl)).min(1).max(cl.length).optional().describe("Optional allow-list of event kinds; omitted means every kind in selected sources."),classes:$.array($.string().min(1).max(128)).min(1).max(32).optional().describe("Optional exact ClassName allow-list."),nameContains:$.string().min(1).max(128).optional().describe("Optional case-insensitive plain substring required in the changed Instance name."),pathContains:$.string().min(1).max(512).optional().describe("Optional case-insensitive plain substring required in the full Instance path.")}).optional().default({}).describe("Start-only server-side filters, applied before an event consumes buffer capacity."),cameraProperties:$.array($.string().min(1).max(128)).min(1).max(16).optional().default([...Sd]).describe("Camera properties watched with GetPropertyChangedSignal. Add CFrame or Focus only when needed; throttling protects high-frequency properties."),watchedProperties:$.array(Td).max(16).optional().default([]).describe("Additional explicit Instance/property subscriptions. At most 16 targets and 64 aggregate property connections are allowed."),threadContext:$.number().int().optional()}).superRefine((e,t)=>{e.watchedProperties.reduce((r,a)=>r+new Set(a.properties).size,0)>64&&t.addIssue({code:"custom",path:["watchedProperties"],message:"watchedProperties may request at most 64 unique target/property connections"})}),ul=u({name:"world-delta",title:"Stream bounded event-driven world changes",description:"WRITES LIVE CLIENT OBSERVER STATE \u2014 installs RBXScriptConnections and a bounded getgenv registry, but never modifies gameplay Instances. action='start' subscribes to Workspace and PlayerGui descendant additions/removals, character spawn/removal and equipped Tool changes, CurrentCamera replacement and selected camera properties, Backpack Tool changes, plus explicitly requested Instance properties. action='poll' returns cursor-ordered deltas; action='status' reports observer health; action='stop' disconnects every connection. Events are filtered before storage, repeated noise is coalesced/throttled, the ring buffer reports every capacity eviction, and a fixed TTL runs the same cleanup path automatically. It uses Roblox signals only: no RenderStepped, per-frame polling, or world scans.",category:"Intelligence",mutatesState:!0,ai:{phase:"observe",prerequisites:["active-client","getgenv capability","a bounded observation goal and relevant source filters"],consumes:["world-change observation goal","optional Instance/property expressions","previous nextCursor"],produces:["event-driven-world-deltas","monotonic-cursor","buffer-gap-and-drop-accounting","observer-health-and-expiry","coalescing-and-throttle-statistics"],verifiesWith:["observe-world"],alternatives:["observe-world","watch-property-changes","watch-instance-property"],requiresCapabilities:["getgenv"],sideEffects:["installs bounded RBXScriptConnections in the active client","stores bounded observer metadata and events in getgenv.__mcp_world_delta","schedules one TTL cleanup callback; no gameplay Instance is written"],failureRecovery:["If start reports watchErrors, correct only those expressions/properties and start a replacement observer.","If poll reports cursorGap, treat droppedSinceCursor as missing history and call observe-world for a fresh snapshot.","Persist nextCursor after every poll; never invent or advance a cursor beyond latestCursor.","If noise is high, narrow filters or raise throttleMs before increasing maxEvents.","Always call stop when the task ends; TTL is a leak guard, not the normal lifecycle.","After a transport reconnect, call status before trusting an old observer id."]},input:Rd,async execute({action:e,observerId:t,cursor:n,limit:r,maxEvents:a,ttlSeconds:o,throttleMs:i,coalesceWindowMs:l,filters:c,cameraProperties:d,watchedProperties:p,threadContext:f},h){if(e==="start"&&t!==void 0)return{data:{error:"observerId is assigned by world-delta start; omit it when starting."},summary:"World-delta start failed: omit observerId and use the id returned by start.",isError:!0};let g=[...new Set(c.sources??Ca)],b=[...new Set(c.eventKinds??[])],m=[...new Set(c.classes??[])],y=[...new Set(d)],w=Math.min(Math.max(Math.floor(a),16),2e3),C=Math.min(Math.max(Math.floor(r),1),500),I=Math.min(Math.max(Math.floor(o),5),3600),N=Math.min(Math.max(Math.floor(i),0),5e3),O=Math.min(Math.max(Math.floor(l),0),5e3),q=String(h.session.id),S=`
local ACTION = ${s(e)}
local REQUESTED_ID = ${t===void 0?"nil":s(t)}
local SESSION_KEY = ${s(q)}
local REQUEST_CURSOR = ${Math.floor(n)}
local POLL_LIMIT = ${C}
local MAX_EVENTS = ${w}
local TTL_SECONDS = ${I}
local THROTTLE_MS = ${N}
local COALESCE_WINDOW_MS = ${O}
local SOURCE_LIST = ${Rn(g)}
local SOURCE_FILTER = ${Ea(g)}
local EVENT_KIND_LIST = ${Rn(b)}
local EVENT_KIND_FILTER = ${Ea(b)}
local CLASS_LIST = ${Rn(m)}
local CLASS_FILTER = ${Ea(m)}
local NAME_CONTAINS = ${c.nameContains===void 0?"nil":s(c.nameContains.toLowerCase())}
local PATH_CONTAINS = ${c.pathContains===void 0?"nil":s(c.pathContains.toLowerCase())}
local CAMERA_PROPERTIES = ${Rn(y)}
local WATCHES = ${Ed(p)}

local REGISTRY_KEY = "__mcp_world_delta"
local REGISTRY_VERSION = 1
local HARD_MAX_OBSERVERS = 8
local HARD_MAX_SESSION_OBSERVERS = 4
local HARD_MAX_TOMBSTONES = 16
local HARD_MAX_EVENTS = 2000
local HARD_MAX_WATCH_TARGETS = 16
local HARD_MAX_WATCH_PROPERTIES = 64
local HARD_MAX_WARNINGS = 32

local function now()
  return os.clock()
end

local function safeService(name)
  local ok, value = pcall(function() return game:GetService(name) end)
  if ok and typeof(value) == "Instance" then return value end
  return nil
end

local function safeClass(instance)
  if typeof(instance) ~= "Instance" then return nil end
  local ok, value = pcall(function() return instance.ClassName end)
  return ok and tostring(value) or nil
end

local function safeName(instance)
  if typeof(instance) ~= "Instance" then return nil end
  local ok, value = pcall(function() return instance.Name end)
  return ok and tostring(value) or nil
end

local function safePath(instance)
  if typeof(instance) ~= "Instance" then return nil end
  local ok, value = pcall(function() return instance:GetFullName() end)
  return ok and tostring(value) or tostring(instance)
end

local function isA(instance, className)
  if typeof(instance) ~= "Instance" then return false end
  local ok, value = pcall(function() return instance:IsA(className) end)
  return ok and value == true
end

local function limitedString(value)
  local text = tostring(value)
  if #text > 512 then return string.sub(text, 1, 512) .. "\u2026" end
  return text
end

local function encodeValue(value)
  local kind = typeof(value)
  if kind == "nil" or kind == "boolean" or kind == "number" then return value end
  if kind == "string" then return limitedString(value) end
  if kind == "Instance" then
    return { type = "Instance", path = safePath(value), className = safeClass(value) }
  end
  local ok, text = pcall(tostring, value)
  return { type = kind, value = ok and limitedString(text) or "<unprintable>" }
end

local function readProperty(instance, property)
  local ok, value = pcall(function() return instance[property] end)
  if not ok then return { unreadable = true, error = limitedString(value) } end
  return encodeValue(value)
end

if type(getgenv) ~= "function" then
  return { error = "getgenv is not available; world-delta cannot preserve observer connections across calls." }
end
local okEnv, env = pcall(getgenv)
if not okEnv or type(env) ~= "table" then
  return { error = "getgenv did not return a usable table; world-delta cannot create its bounded registry." }
end

local registry = env[REGISTRY_KEY]
if registry == nil then
  registry = {
    version = REGISTRY_VERSION,
    nextObserverId = 0,
    observers = {},
    tombstones = {},
    tombstoneOrder = {},
  }
  env[REGISTRY_KEY] = registry
elseif type(registry) ~= "table" or registry.version ~= REGISTRY_VERSION
  or type(registry.observers) ~= "table" or type(registry.tombstones) ~= "table" then
  return { error = "Refusing to overwrite unknown or corrupt getgenv.__mcp_world_delta state." }
end

local function addWarning(state, message)
  if #state.warnings < HARD_MAX_WARNINGS then
    state.warnings[#state.warnings + 1] = limitedString(message)
  else
    state.droppedWarnings = state.droppedWarnings + 1
  end
end

local function disconnectGroup(state, groupName)
  local group = state.groups[groupName]
  if type(group) ~= "table" then
    state.groups[groupName] = {}
    return 0
  end
  local disconnected = 0
  for _, connection in ipairs(group) do
    if connection ~= nil then
      local ok = pcall(function() connection:Disconnect() end)
      if ok then disconnected = disconnected + 1 end
    end
  end
  state.groups[groupName] = {}
  return disconnected
end

local function disconnectState(state, reason)
  if state.cleanupReason ~= nil then return state.disconnectedConnections or 0 end
  state.active = false
  if reason ~= "expired" and state.expiryThread ~= nil and type(task.cancel) == "function" then
    pcall(task.cancel, state.expiryThread)
  end
  state.expiryThread = nil
  local disconnected = 0
  for groupName in pairs(state.groups) do
    disconnected = disconnected + disconnectGroup(state, groupName)
  end
  state.cleanupReason = reason
  state.disconnectedConnections = disconnected
  state.coalesce = {}
  state.lastEmitted = {}
  state.boundCamera = nil
  state.boundCharacter = nil
  state.boundPlayerGui = nil
  state.boundBackpack = nil
  return disconnected
end

local function recordTombstone(state, reason)
  local tombstone = {
    observerId = state.id,
    ownerSession = state.ownerSession,
    active = false,
    status = reason,
    stoppedAt = now(),
    latestCursor = state.cursor,
    nextCursor = state.cursor,
    droppedEvents = state.droppedEvents,
    coalescedEvents = state.coalescedEvents,
    throttledEvents = state.throttledEvents,
    disconnectedConnections = state.disconnectedConnections or 0,
  }
  registry.tombstones[state.id] = tombstone
  registry.tombstoneOrder[#registry.tombstoneOrder + 1] = state.id
  while #registry.tombstoneOrder > HARD_MAX_TOMBSTONES do
    local oldest = table.remove(registry.tombstoneOrder, 1)
    if oldest ~= state.id then registry.tombstones[oldest] = nil end
  end
  return tombstone
end

local function retireState(state, reason)
  local disconnected = disconnectState(state, reason)
  if registry.observers[state.id] == state then registry.observers[state.id] = nil end
  local tombstone = recordTombstone(state, reason)
  state.events = {}
  state.eventHead = 1
  state.eventTail = 0
  state.eventCount = 0
  return tombstone, disconnected
end

local function cleanupExpired()
  local timestamp = now()
  local expired = {}
  for _, state in pairs(registry.observers) do
    if state.active == true and state.expiresAt <= timestamp then
      expired[#expired + 1] = state
    end
  end
  for _, state in ipairs(expired) do retireState(state, "expired") end
end

cleanupExpired()

local function findState()
  if REQUESTED_ID ~= nil then
    local state = registry.observers[REQUESTED_ID]
    if state ~= nil and state.ownerSession == SESSION_KEY then return state, nil end
    local tombstone = registry.tombstones[REQUESTED_ID]
    if tombstone ~= nil and tombstone.ownerSession == SESSION_KEY then return nil, tombstone end
    return nil, nil
  end

  local newest = nil
  for _, state in pairs(registry.observers) do
    if state.ownerSession == SESSION_KEY and state.active == true
      and (newest == nil or state.sequence > newest.sequence) then
      newest = state
    end
  end
  return newest, nil
end

local function connectionCount(state)
  local total = 0
  for _, group in pairs(state.groups) do
    if type(group) == "table" then total = total + #group end
  end
  return total
end

local function statusOf(state)
  return {
    observerId = state.id,
    active = state.active == true,
    status = state.active == true and "active" or (state.cleanupReason or "inactive"),
    ageMs = math.max(0, math.floor((now() - state.createdAt) * 1000)),
    expiresInMs = math.max(0, math.floor((state.expiresAt - now()) * 1000)),
    connections = connectionCount(state),
    maxEvents = state.maxEvents,
    bufferedEvents = state.eventCount,
    latestCursor = state.cursor,
    nextCursor = state.cursor,
    droppedEvents = state.droppedEvents,
    droppedThrough = state.droppedThrough,
    coalescedEvents = state.coalescedEvents,
    throttledEvents = state.throttledEvents,
    filteredEvents = state.filteredEvents,
    rawEvents = state.rawEvents,
    sourceCounts = state.sourceCounts,
    warnings = state.warnings,
    droppedWarnings = state.droppedWarnings,
    filters = state.filterSummary,
    watchedPropertyConnections = state.watchedPropertyConnections,
  }
end

local function publicEvent(event)
  return {
    cursor = event.cursor,
    source = event.source,
    kind = event.kind,
    elapsedMs = event.elapsedMs,
    lastElapsedMs = event.lastElapsedMs,
    repeatCount = event.repeatCount,
    path = event.path,
    name = event.name,
    className = event.className,
    property = event.property,
    detail = event.detail,
  }
end

if ACTION ~= "start" then
  local state, tombstone = findState()
  if state == nil then
    if tombstone ~= nil then
      if ACTION == "stop" then
        return {
          observerId = tombstone.observerId,
          stopped = true,
          alreadyStopped = true,
          status = tombstone.status,
          latestCursor = tombstone.latestCursor,
          droppedEvents = tombstone.droppedEvents,
          disconnectedConnections = tombstone.disconnectedConnections,
        }
      end
      return tombstone
    end
    return { error = "No active world-delta observer owned by this MCP session. Start one first." }
  end

  if ACTION == "status" then return statusOf(state) end

  if ACTION == "stop" then
    local final = statusOf(state)
    local tombstone, disconnected = retireState(state, "stopped")
    return {
      observerId = state.id,
      stopped = true,
      alreadyStopped = false,
      status = tombstone.status,
      latestCursor = final.latestCursor,
      bufferedEvents = final.bufferedEvents,
      droppedEvents = final.droppedEvents,
      coalescedEvents = final.coalescedEvents,
      throttledEvents = final.throttledEvents,
      disconnectedConnections = disconnected,
    }
  end

  if ACTION ~= "poll" then return { error = "Unsupported world-delta action: " .. tostring(ACTION) } end
  if REQUEST_CURSOR > state.cursor then
    return {
      error = "cursor is ahead of the observer's latestCursor; reuse the last nextCursor returned by poll.",
      observerId = state.id,
      requestedCursor = REQUEST_CURSOR,
      latestCursor = state.cursor,
      nextCursor = state.cursor,
    }
  end

  local effectiveCursor = REQUEST_CURSOR
  local cursorGap = effectiveCursor < state.droppedThrough
  local droppedSinceCursor = 0
  if cursorGap then
    droppedSinceCursor = state.droppedThrough - effectiveCursor
    effectiveCursor = state.droppedThrough
  end

  local events = {}
  local nextCursor = effectiveCursor
  local hasMore = false
  for index = state.eventHead, state.eventTail do
    local event = state.events[index]
    if event ~= nil and event.active == true and event.cursor > effectiveCursor then
      if #events < POLL_LIMIT then
        events[#events + 1] = publicEvent(event)
        nextCursor = event.cursor
      else
        hasMore = true
        break
      end
    end
  end

  return {
    observerId = state.id,
    active = true,
    events = events,
    returned = #events,
    requestedCursor = REQUEST_CURSOR,
    nextCursor = nextCursor,
    latestCursor = state.cursor,
    hasMore = hasMore,
    cursorGap = cursorGap,
    droppedSinceCursor = droppedSinceCursor,
    droppedEvents = state.droppedEvents,
    droppedThrough = state.droppedThrough,
    coalescedEvents = state.coalescedEvents,
    throttledEvents = state.throttledEvents,
    expiresInMs = math.max(0, math.floor((state.expiresAt - now()) * 1000)),
  }
end

if MAX_EVENTS > HARD_MAX_EVENTS then return { error = "maxEvents exceeds the hard safety cap." } end
if #WATCHES > HARD_MAX_WATCH_TARGETS then return { error = "Too many watched Instance targets." } end
local requestedWatchProperties = 0
for _, watch in ipairs(WATCHES) do requestedWatchProperties = requestedWatchProperties + #watch.properties end
if requestedWatchProperties > HARD_MAX_WATCH_PROPERTIES then
  return { error = "Too many watched target/property connections." }
end

local observerCount = 0
local sessionObserverCount = 0
for _, state in pairs(registry.observers) do
  observerCount = observerCount + 1
  if state.ownerSession == SESSION_KEY then sessionObserverCount = sessionObserverCount + 1 end
end
if observerCount >= HARD_MAX_OBSERVERS then
  return { error = "The bounded world-delta registry is full; stop an observer before starting another." }
end
if sessionObserverCount >= HARD_MAX_SESSION_OBSERVERS then
  return { error = "This MCP session already owns the maximum number of world-delta observers." }
end

registry.nextObserverId = (tonumber(registry.nextObserverId) or 0) + 1
local observerId = "wd:" .. tostring(registry.nextObserverId)
local createdAt = now()
local state = {
  id = observerId,
  sequence = registry.nextObserverId,
  ownerSession = SESSION_KEY,
  active = true,
  createdAt = createdAt,
  expiresAt = createdAt + TTL_SECONDS,
  maxEvents = MAX_EVENTS,
  events = {},
  eventHead = 1,
  eventTail = 0,
  eventCount = 0,
  cursor = 0,
  droppedEvents = 0,
  droppedThrough = 0,
  coalescedEvents = 0,
  throttledEvents = 0,
  filteredEvents = 0,
  rawEvents = 0,
  groups = { static = {}, camera = {}, character = {}, playerGui = {}, backpack = {}, watched = {} },
  coalesce = {},
  lastEmitted = {},
  sourceCounts = {},
  warnings = {},
  droppedWarnings = 0,
  watchedPropertyConnections = 0,
  filterSummary = {
    sources = SOURCE_LIST,
    eventKinds = EVENT_KIND_LIST,
    classes = CLASS_LIST,
    nameContains = NAME_CONTAINS,
    pathContains = PATH_CONTAINS,
    throttleMs = THROTTLE_MS,
    coalesceWindowMs = COALESCE_WINDOW_MS,
  },
}
registry.observers[observerId] = state

local HAS_EVENT_KIND_FILTER = next(EVENT_KIND_FILTER) ~= nil
local HAS_CLASS_FILTER = next(CLASS_FILTER) ~= nil

local function passesFilters(sourceName, kind, instance, name, path)
  if SOURCE_FILTER[sourceName] ~= true then return false end
  if HAS_EVENT_KIND_FILTER and EVENT_KIND_FILTER[kind] ~= true then return false end
  if HAS_CLASS_FILTER then
    local className = safeClass(instance)
    if className == nil or CLASS_FILTER[className] ~= true then return false end
  end
  if NAME_CONTAINS ~= nil then
    if name == nil or string.find(string.lower(name), NAME_CONTAINS, 1, true) == nil then return false end
  end
  if PATH_CONTAINS ~= nil then
    if path == nil or string.find(string.lower(path), PATH_CONTAINS, 1, true) == nil then return false end
  end
  return true
end

local function compactEvents()
  if state.eventHead <= 4096 or state.eventHead <= math.floor(state.eventTail / 2) then return end
  local compacted = {}
  local count = 0
  for index = state.eventHead, state.eventTail do
    local event = state.events[index]
    if event ~= nil then
      count = count + 1
      compacted[count] = event
    end
  end
  state.events = compacted
  state.eventHead = 1
  state.eventTail = count
end

local function appendEvent(event, key, timestamp)
  state.eventTail = state.eventTail + 1
  state.events[state.eventTail] = event
  state.eventCount = state.eventCount + 1
  state.coalesce[key] = { event = event, firstAt = timestamp }
  state.lastEmitted[key] = { event = event, at = timestamp }

  while state.eventCount > state.maxEvents do
    local removed = state.events[state.eventHead]
    state.events[state.eventHead] = nil
    state.eventHead = state.eventHead + 1
    state.eventCount = state.eventCount - 1
    if removed ~= nil then
      removed.active = false
      state.droppedEvents = state.droppedEvents + 1
      state.droppedThrough = math.max(state.droppedThrough, removed.cursor or 0)
      local removedKey = removed.key
      local bucket = removedKey and state.coalesce[removedKey] or nil
      if bucket ~= nil and bucket.event == removed then state.coalesce[removedKey] = nil end
      local last = removedKey and state.lastEmitted[removedKey] or nil
      if last ~= nil and last.event == removed then state.lastEmitted[removedKey] = nil end
    end
  end
  compactEvents()
end

local function emit(sourceName, kind, instance, property, detail)
  if state.active ~= true then return end
  state.rawEvents = state.rawEvents + 1
  local name = safeName(instance)
  local path = safePath(instance)
  if not passesFilters(sourceName, kind, instance, name, path) then
    state.filteredEvents = state.filteredEvents + 1
    return
  end

  local timestamp = now()
  local elapsedMs = math.max(0, math.floor((timestamp - state.createdAt) * 1000))
  local key = sourceName .. "|" .. kind .. "|" .. tostring(path or "<none>") .. "|" .. tostring(property or "")
  local bucket = state.coalesce[key]
  if bucket ~= nil and bucket.event ~= nil and bucket.event.active == true
    and (timestamp - bucket.firstAt) * 1000 <= COALESCE_WINDOW_MS then
    local event = bucket.event
    event.repeatCount = event.repeatCount + 1
    event.lastElapsedMs = elapsedMs
    if detail ~= nil then event.detail = detail end
    state.coalescedEvents = state.coalescedEvents + 1
    return
  end

  local last = state.lastEmitted[key]
  if last ~= nil and (timestamp - last.at) * 1000 < THROTTLE_MS then
    state.throttledEvents = state.throttledEvents + 1
    return
  end

  state.cursor = state.cursor + 1
  local event = {
    cursor = state.cursor,
    source = sourceName,
    kind = kind,
    elapsedMs = elapsedMs,
    lastElapsedMs = elapsedMs,
    repeatCount = 1,
    path = path,
    name = name,
    className = safeClass(instance),
    property = property,
    detail = detail,
    key = key,
    active = true,
  }
  state.sourceCounts[sourceName] = (state.sourceCounts[sourceName] or 0) + 1
  appendEvent(event, key, timestamp)
end

local function connectSignal(groupName, signal, label, callback)
  if state.active ~= true then return nil end
  if typeof(signal) ~= "RBXScriptSignal" then
    addWarning(state, label .. " is not an RBXScriptSignal")
    return nil
  end
  local ok, connection = pcall(function()
    return signal:Connect(function(...)
      if state.active ~= true then return end
      local callbackOk, callbackError = pcall(callback, ...)
      if not callbackOk then addWarning(state, label .. " callback failed: " .. tostring(callbackError)) end
    end)
  end)
  if not ok or connection == nil then
    addWarning(state, "Could not connect " .. label .. ": " .. tostring(connection))
    return nil
  end
  local group = state.groups[groupName]
  group[#group + 1] = connection
  return connection
end

local function propertySignal(instance, property)
  local ok, signal = pcall(function() return instance:GetPropertyChangedSignal(property) end)
  if ok then return signal, nil end
  return nil, signal
end

local Workspace = safeService("Workspace") or workspace
local Players = safeService("Players")
local LocalPlayer = Players and Players.LocalPlayer or nil

local bindCamera
local bindCharacter
local bindPlayerGui
local bindBackpack

bindCamera = function(camera)
  disconnectGroup(state, "camera")
  state.boundCamera = camera
  if typeof(camera) ~= "Instance" then return end
  for _, property in ipairs(CAMERA_PROPERTIES) do
    local cameraInstance = camera
    local cameraProperty = property
    local signal, signalError = propertySignal(cameraInstance, cameraProperty)
    if signal ~= nil then
      connectSignal("camera", signal, "camera." .. cameraProperty, function()
        emit("camera", "camera-property-changed", cameraInstance, cameraProperty, {
          value = readProperty(cameraInstance, cameraProperty),
        })
      end)
    else
      addWarning(state, "Camera property " .. cameraProperty .. " is unavailable: " .. tostring(signalError))
    end
  end
end

bindCharacter = function(character)
  disconnectGroup(state, "character")
  state.boundCharacter = character
  if typeof(character) ~= "Instance" or SOURCE_FILTER.character ~= true then return end
  connectSignal("character", character.DescendantAdded, "Character.DescendantAdded", function(instance)
    if isA(instance, "Tool") then emit("character", "character-tool-added", instance, nil, nil) end
  end)
  connectSignal("character", character.DescendantRemoving, "Character.DescendantRemoving", function(instance)
    if isA(instance, "Tool") then emit("character", "character-tool-removing", instance, nil, nil) end
  end)
end

bindPlayerGui = function(playerGui)
  disconnectGroup(state, "playerGui")
  state.boundPlayerGui = playerGui
  if typeof(playerGui) ~= "Instance" or SOURCE_FILTER.playerGui ~= true then return end
  connectSignal("playerGui", playerGui.DescendantAdded, "PlayerGui.DescendantAdded", function(instance)
    emit("playerGui", "player-gui-descendant-added", instance, nil, nil)
  end)
  connectSignal("playerGui", playerGui.DescendantRemoving, "PlayerGui.DescendantRemoving", function(instance)
    emit("playerGui", "player-gui-descendant-removing", instance, nil, nil)
  end)
end

bindBackpack = function(backpack)
  disconnectGroup(state, "backpack")
  state.boundBackpack = backpack
  if typeof(backpack) ~= "Instance" or SOURCE_FILTER.backpack ~= true then return end
  connectSignal("backpack", backpack.DescendantAdded, "Backpack.DescendantAdded", function(instance)
    if isA(instance, "Tool") then emit("backpack", "backpack-tool-added", instance, nil, nil) end
  end)
  connectSignal("backpack", backpack.DescendantRemoving, "Backpack.DescendantRemoving", function(instance)
    if isA(instance, "Tool") then emit("backpack", "backpack-tool-removing", instance, nil, nil) end
  end)
end

if typeof(Workspace) == "Instance" and SOURCE_FILTER.workspace == true then
  connectSignal("static", Workspace.DescendantAdded, "Workspace.DescendantAdded", function(instance)
    emit("workspace", "workspace-descendant-added", instance, nil, nil)
  end)
  connectSignal("static", Workspace.DescendantRemoving, "Workspace.DescendantRemoving", function(instance)
    emit("workspace", "workspace-descendant-removing", instance, nil, nil)
  end)
elseif SOURCE_FILTER.workspace == true then
  addWarning(state, "Workspace is unavailable")
end

if typeof(Workspace) == "Instance" and SOURCE_FILTER.camera == true then
  local currentCameraSignal, currentCameraError = propertySignal(Workspace, "CurrentCamera")
  if currentCameraSignal ~= nil then
    connectSignal("static", currentCameraSignal, "Workspace.CurrentCamera", function()
      local previous = state.boundCamera
      local ok, current = pcall(function() return Workspace.CurrentCamera end)
      if not ok then current = nil end
      bindCamera(current)
      emit("camera", "camera-replaced", current or previous, "CurrentCamera", {
        previousPath = safePath(previous),
        currentPath = safePath(current),
      })
    end)
  else
    addWarning(state, "CurrentCamera signal is unavailable: " .. tostring(currentCameraError))
  end
  local ok, current = pcall(function() return Workspace.CurrentCamera end)
  bindCamera(ok and current or nil)
end

if typeof(LocalPlayer) == "Instance" then
  if SOURCE_FILTER.character == true then
    connectSignal("static", LocalPlayer.CharacterAdded, "LocalPlayer.CharacterAdded", function(character)
      emit("character", "character-added", character, nil, nil)
      bindCharacter(character)
    end)
    connectSignal("static", LocalPlayer.CharacterRemoving, "LocalPlayer.CharacterRemoving", function(character)
      emit("character", "character-removing", character, nil, nil)
      if state.boundCharacter == character then bindCharacter(nil) end
    end)
    local ok, character = pcall(function() return LocalPlayer.Character end)
    bindCharacter(ok and character or nil)
  end

  if SOURCE_FILTER.playerGui == true or SOURCE_FILTER.backpack == true then
    connectSignal("static", LocalPlayer.ChildAdded, "LocalPlayer.ChildAdded", function(child)
      if SOURCE_FILTER.playerGui == true and isA(child, "PlayerGui") then
        local previous = state.boundPlayerGui
        bindPlayerGui(child)
        emit("playerGui", "player-gui-replaced", child, nil, { previousPath = safePath(previous) })
      elseif SOURCE_FILTER.backpack == true and isA(child, "Backpack") then
        local previous = state.boundBackpack
        bindBackpack(child)
        emit("backpack", "backpack-replaced", child, nil, { previousPath = safePath(previous) })
      end
    end)
    connectSignal("static", LocalPlayer.ChildRemoved, "LocalPlayer.ChildRemoved", function(child)
      if child == state.boundPlayerGui then
        emit("playerGui", "player-gui-replaced", child, nil, { removed = true })
        bindPlayerGui(nil)
      elseif child == state.boundBackpack then
        emit("backpack", "backpack-replaced", child, nil, { removed = true })
        bindBackpack(nil)
      end
    end)
  end

  if SOURCE_FILTER.playerGui == true then
    local ok, playerGui = pcall(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
    bindPlayerGui(ok and playerGui or nil)
    if state.boundPlayerGui == nil then addWarning(state, "PlayerGui is unavailable at observer start") end
  end
  if SOURCE_FILTER.backpack == true then
    local ok, backpack = pcall(function() return LocalPlayer:FindFirstChildOfClass("Backpack") end)
    bindBackpack(ok and backpack or nil)
    if state.boundBackpack == nil then addWarning(state, "Backpack is unavailable at observer start") end
  end
elseif SOURCE_FILTER.character == true or SOURCE_FILTER.playerGui == true or SOURCE_FILTER.backpack == true then
  addWarning(state, "Players.LocalPlayer is unavailable; player-owned sources were not connected")
end

local function evaluateInstance(expression)
  if type(loadstring) ~= "function" then return nil, "loadstring is unavailable" end
  local fn, compileError = loadstring("return " .. expression)
  if fn == nil then return nil, "compile error: " .. tostring(compileError) end
  local ok, value = pcall(fn)
  if not ok then return nil, "evaluation error: " .. tostring(value) end
  if typeof(value) ~= "Instance" then return nil, "expression resolved to " .. typeof(value) .. ", not Instance" end
  return value, nil
end

if SOURCE_FILTER.watched == true then
  for _, watch in ipairs(WATCHES) do
    local watchExpression = watch.expression
    local instance, watchError = evaluateInstance(watchExpression)
    if instance == nil then
      addWarning(state, "Watch " .. watchExpression .. " failed: " .. tostring(watchError))
    else
      for _, property in ipairs(watch.properties) do
        local watchedInstance = instance
        local watchedProperty = property
        local signal, signalError = propertySignal(watchedInstance, watchedProperty)
        if signal ~= nil then
          local connected = connectSignal("watched", signal, "watch " .. watchExpression .. "." .. watchedProperty, function()
            emit("watched", "watched-property-changed", watchedInstance, watchedProperty, {
              expression = watchExpression,
              value = readProperty(watchedInstance, watchedProperty),
            })
          end)
          if connected ~= nil then state.watchedPropertyConnections = state.watchedPropertyConnections + 1 end
        else
          addWarning(state, "Watch " .. watchExpression .. "." .. watchedProperty .. " failed: " .. tostring(signalError))
        end
      end
    end
  end
end

local scheduled, expiryThreadOrError = pcall(function()
  return task.delay(TTL_SECONDS, function()
    pcall(function()
      local current = registry.observers[observerId]
      if current == state and state.active == true then
        retireState(state, "expired")
      end
    end)
  end)
end)
if not scheduled then
  retireState(state, "start-failed")
  return { error = "Could not schedule mandatory TTL cleanup: " .. tostring(expiryThreadOrError) }
end
state.expiryThread = expiryThreadOrError

local result = statusOf(state)
result.started = true
result.nextCursor = 0
return result
`,x=await h.runLuau(S,{threadContext:f,timeoutMs:2e4}),E=Id(e,x);return{data:x,...E}}});import{z as Er}from"zod";var dl=u({name:"block-function",title:"Neutralize a function so it does nothing (MUTATES STATE via hookfunction)",description:`WRITES LIVE GAME STATE \u2014 INSTALLS A PERSISTENT GLOBAL HOOK. Replaces a target function with a no-op that ignores its arguments, returns nothing, and NEVER calls the original. Use this to disable a behavior outright: silence an anticheat heartbeat/tick, stop a function that kicks the player, neutralize a telemetry reporter, or freeze a damage routine. Distinct from spoof-function-return (which forces a specific return value) \u2014 block-function simply makes the call a complete no-op (returns nil/nothing).

WORKFLOW (stateful \u2014 survives across tool calls via getgenv().__mcp_blockedFns, keyed by functionPath):
  1. action='start' with functionPath \u2014 resolves the target, captures the original, installs the no-op stub. Returns { started, key }.
  2. action='stop' with the same functionPath \u2014 restores the original function. Returns { stopped }.

CAVEATS: the hook is GLOBAL and PERSISTS until you stop it (or the client restarts). Because the original never runs, blocking a function the game depends on can break gameplay, and a live function hook CAN TRIP ANTICHEAT. Always stop when done. Requires hookfunction, newcclosure, and getgenv; restoration uses hookfunction(target, original) with a restorefunction fallback. Returns { error } if a capability is missing, the target cannot be resolved, or there is already an active block for fetch/stop.`,category:"Instrumentation",mutatesState:!0,input:Er.object({action:Er.enum(["start","stop"]).describe("'start' installs the no-op stub on functionPath; 'stop' restores the original function. Use the SAME functionPath for both so they address the same registry entry."),functionPath:Er.string().describe("Luau expression resolving to the function to neutralize, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.AntiCheat).tick' or 'getconnections(game.Players.LocalPlayer.Idled)[1].Function'. Evaluated as `return <functionPath>` and must resolve to a function. REQUIRED for 'start'. For 'stop' it is the registry key identifying which block to restore, so it must match the string used at start.").optional(),threadContext:Er.number().int().optional()}),async execute({action:e,functionPath:t,threadContext:n},r){if(e==="start"&&!t)return{data:{error:"functionPath is required for action='start' (the Luau expression resolving to the target function)."},isError:!0};if(!t)return{data:{error:"functionPath is required to identify which block to "+e+" (use the same expression you passed to start)."},isError:!0};let o=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor; cannot maintain the block registry." } end
local __genv = getgenv()
if type(__genv.__mcp_blockedFns) ~= "table" then __genv.__mcp_blockedFns = {} end
local __KEY = ${s(t)}

local function __resolveTarget()
  local okc, fn = pcall(loadstring, "return " .. __KEY)
  if not okc or type(fn) ~= "function" then return nil, "compile error resolving target expression" end
  local oke, val = pcall(fn)
  if not oke then return nil, "error evaluating target expression: " .. tostring(val) end
  if type(val) ~= "function" then return nil, "expression did not resolve to a function (got " .. tostring(typeof(val)) .. ")" end
  return val, nil
end
`,i;e==="start"?i=`
if type(hookfunction) ~= "function" then return { error = "hookfunction is not available in this executor." } end
if type(newcclosure) ~= "function" then return { error = "newcclosure is not available in this executor." } end

local existing = __genv.__mcp_blockedFns[__KEY]
if existing and existing.active then
  return { error = "A block is already active for this functionPath. Stop it before starting again.", key = __KEY }
end

local target, terr = __resolveTarget()
if not target then return { error = "target: " .. tostring(terr) } end

-- Refuse to stack on a function another instrument tool already hooked. Owner map
-- is keyed by the target object with weak keys so it never leaks.
if type(__genv.__mcp_hookOwners) ~= "table" then __genv.__mcp_hookOwners = setmetatable({}, { __mode = "k" }) end
local __OWNERTAG = "block:" .. __KEY
local __owner = __genv.__mcp_hookOwners[target]
if __owner and __owner ~= __OWNERTAG then
  return { error = "This function is already instrumented by another tool ('" .. tostring(__owner) .. "'). Stop that one first to avoid stacking hooks.", key = __KEY }
end

-- Keep the resolved target object so stop restores the EXACT closure we hooked.
local entry = { orig = nil, target = target, active = true, startedAt = (type(os) == "table" and os.clock and os.clock()) or 0 }
__genv.__mcp_blockedFns[__KEY] = entry

local hook = newcclosure(function(...)
  local e = __genv.__mcp_blockedFns[__KEY]
  if e and e.active then
    return
  end
  -- Block was cleared but hook still installed: fall back to the original.
  if e and type(e.orig) == "function" then return e.orig(...) end
  return
end)

local okh, orig = pcall(hookfunction, target, hook)
if not okh then
  __genv.__mcp_blockedFns[__KEY] = nil
  return { error = "hookfunction failed: " .. tostring(orig) }
end
if type(orig) ~= "function" then
  __genv.__mcp_blockedFns[__KEY] = nil
  return { error = "hookfunction did not return the original function; aborting to keep state clean." }
end
entry.orig = orig
__genv.__mcp_hookOwners[target] = __OWNERTAG

return { started = true, key = __KEY }
`:i=`
local entry = __genv.__mcp_blockedFns[__KEY]
if type(entry) ~= "table" then
  return { error = "No active block for this functionPath; nothing to stop.", key = __KEY }
end

local restored = false
local restoreErr = nil
-- Restore against the EXACT object that was hooked, not a re-resolution of the
-- expression (which may now yield a different closure and clobber it).
local target = entry.target
local terr = nil
if type(target) ~= "function" then target, terr = __resolveTarget() end

if type(entry.orig) == "function" and target and type(hookfunction) == "function" then
  local okr = pcall(hookfunction, target, entry.orig)
  if okr then restored = true else restoreErr = "hookfunction restore failed" end
end

if not restored and type(restorefunction) == "function" and target then
  local okrf = pcall(restorefunction, target)
  if okrf then restored = true else restoreErr = (restoreErr or "") .. " restorefunction failed" end
end

if not restored and terr then restoreErr = (restoreErr and (restoreErr .. "; ") or "") .. terr end

entry.active = false
-- Only drop the entry once restoration is confirmed; otherwise keep it (and
-- entry.orig) so the still-installed stub falls back to e.orig(...) \u2014 gameplay
-- keeps working \u2014 and a later stop can retry instead of permanently no-op'ing.
if restored then
  __genv.__mcp_blockedFns[__KEY] = nil
  if type(__genv.__mcp_hookOwners) == "table" and target then __genv.__mcp_hookOwners[target] = nil end
end

return {
  stopped = true,
  key = __KEY,
  restored = restored,
  warning = restored and nil or ("Could not confirm restoration of the original function" .. (restoreErr and (": " .. restoreErr) or "") .. ". The hook may still be active."),
}
`;let l=o+i;return{data:await r.runLuau(l,{threadContext:n,timeoutMs:2e4})}}});import{z as Se}from"zod";var Md=Se.object({kind:Se.enum(["string","number","boolean","nil","raw"]).describe("How to interpret `value`. 'string'/'number'/'boolean' pass that literal scalar. 'nil' passes a nil argument (ignores `value`). 'raw' treats `value` as a Luau expression that is evaluated at call time \u2014 use it for any non-primitive argument such as Vector3.new(1,2,3), Color3.fromRGB(255,0,0), Enum.KeyCode.E, CFrame.new(), a table like {1,2,3}, or an Instance reference like game.Workspace.Part."),value:Se.union([Se.string(),Se.number(),Se.boolean()]).describe("The literal value for kind='string'/'number'/'boolean'; OR, when kind='raw', a Luau expression string such as 'Vector3.new(0,50,0)', 'Enum.Material.Neon', 'game.Players.LocalPlayer', or '{ a = 1, b = 2 }'. Omit entirely when kind='nil'.").optional()}).describe("A single positional argument to pass to the function, expressed as a typed value."),pl=u({name:"call-closure",title:"Call any function directly with arguments and capture its result",description:"ACTS ON LIVE GAME STATE \u2014 EXECUTES THE FUNCTION. Resolve a Luau expression to a function and CALL it with an ordered list of typed arguments, returning every value it produces. This lets you invoke internal, hidden, or anonymous functions on demand: a remote's OnClientEvent handler (getconnections(remote.OnClientEvent)[1].Function), a metamethod (getrawmetatable(game).__namecall), a member pulled from a script env (getsenv(script).someFunc), a constant/upvalue you extracted, or any closure found in the GC. Each argument is a typed value; use kind='raw' for non-primitive arguments (Vector3, Color3, Enum, CFrame, tables, Instance references, ...). The call is fully pcall-guarded, so a function that errors reports its message instead of aborting. WARNING: this genuinely runs the target function with the arguments you supply \u2014 it MAY cause side effects, mutate game state, fire remotes to the server, or trip anti-cheat. Only call functions you understand. Returns { Target, ok, returns, returnCount, truncated, argCount } on success, or { Target, ok=false, error, argCount } when the function raised.",category:"Instrumentation",mutatesState:!0,input:Se.object({functionPath:Se.string().describe("Luau expression resolving to the function to call, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).update', 'getrawmetatable(game).__namecall', 'getconnections(game.Workspace.Part.Touched)[1].Function', or 'getgenv().myGlobalFn'. Evaluated as `return <functionPath>`; the result must be a function."),args:Se.array(Md).describe("Ordered list of positional arguments to pass to the function. Omit or pass [] to call it with no arguments. Each entry is a typed value; use kind='raw' for anything that isn't a plain string/number/boolean/nil.").optional(),threadContext:Se.number().int().optional()}),async execute({functionPath:e,args:t,threadContext:n},r){let o=(t??[]).map(te),i=o.length,l=o.join(", "),c=`
local function __encVal(v)
  local t = typeof(v)
  if t == "Instance" then
    local ok, n = pcall(function() return v:GetFullName() end)
    return ok and ("Instance: " .. n) or "<Instance>"
  end
  if t == "string" or t == "number" or t == "boolean" then return v end
  if t == "nil" then return "nil" end
  local ok, s = pcall(tostring, v)
  return ok and (t .. ": " .. tostring(s)) or ("<" .. t .. ">")
end

-- Resolve the target function.
local __chunk, __cerr = loadstring("return " .. ${s(e)})
if not __chunk then
  return { Target = ${s(e)}, ok = false, error = "compile error in functionPath: " .. tostring(__cerr), argCount = ${i} }
end
local __rok, __fn = pcall(__chunk)
if not __rok then
  return { Target = ${s(e)}, ok = false, error = "error evaluating functionPath: " .. tostring(__fn), argCount = ${i} }
end
if type(__fn) ~= "function" then
  return { Target = ${s(e)}, ok = false, error = "functionPath did not resolve to a function (got " .. typeof(__fn) .. ")", argCount = ${i} }
end

-- Call it, capturing all results (incl. the leading pcall ok flag) safely with nils preserved.
local res = table.pack(pcall(__fn${l?", "+l:""}))
local ok = res[1]

if not ok then
  return { Target = ${s(e)}, ok = false, error = tostring(res[2]), argCount = ${i} }
end

-- Encode return values 2..n, capping at 12.
local cap = 12
local returns = {}
local total = res.n - 1
if total < 0 then total = 0 end
local emit = math.min(total, cap)
for i = 1, emit do
  returns[i] = { Index = i, Type = typeof(res[i + 1]), Value = __encVal(res[i + 1]) }
end

return {
  Target = ${s(e)},
  ok = true,
  returns = returns,
  returnCount = total,
  truncated = total > cap,
  argCount = ${i},
}
`;return{data:await r.runLuau(c,{threadContext:n,timeoutMs:3e4})}}});import{z as Cr}from"zod";var fl=u({name:"count-function-calls",title:"Count how many times a function is called (MUTATES STATE via hookfunction)",description:`WRITES LIVE GAME STATE \u2014 INSTALLS A PERSISTENT GLOBAL HOOK. Lightweight call-frequency counter for any function: hook a target so that every invocation bumps an integer counter, then read the counter, then restore the original. Unlike hook-and-log-function (which records full args/returns), this captures ONLY a count, so it is the cheapest way to answer 'is this function actually being called, and how often?' \u2014 ideal for confirming an anticheat tick fires, measuring how hot a code path is, or verifying a remote handler runs.

WORKFLOW (stateful \u2014 survives across tool calls via getgenv().__mcp_callCounts, keyed by functionPath):
  1. action='start' with functionPath \u2014 resolves the target, captures the original, installs a counting hook that transparently calls the original and increments a counter. Returns { started, key }.
  2. action='fetch' with the same functionPath \u2014 returns { calls } captured so far WITHOUT stopping. Poll to watch live.
  3. action='stop' with the same functionPath \u2014 restores the original and clears the entry. Returns { stopped, calls }.

CAVEATS: the hook is GLOBAL and PERSISTS until you stop it (or the client restarts), adds (small) overhead on every call, and a live function hook CAN TRIP ANTICHEAT \u2014 always stop when done. The counting work is pcall-isolated and the hook always calls through to the original, so behavior is unchanged. Requires hookfunction, newcclosure, and getgenv; restoration uses hookfunction(target, original) with a restorefunction fallback. Returns { error } if a capability is missing, the target cannot be resolved, or there is no active counter for fetch/stop.`,category:"Instrumentation",mutatesState:!0,input:Cr.object({action:Cr.enum(["start","fetch","stop"]).describe("'start' installs the counting hook on functionPath; 'fetch' returns the call count so far (hook stays live); 'stop' restores the original function and clears the counter. Use the SAME functionPath for all three so they address the same registry entry."),functionPath:Cr.string().describe("Luau expression resolving to the function to count, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).heartbeat', 'getrawmetatable(game).__namecall', or 'getconnections(game.Workspace.Part.Touched)[1].Function'. Evaluated as `return <functionPath>` and must resolve to a function. REQUIRED for 'start'. For 'fetch'/'stop' it is the registry key identifying which running counter to act on, so it must match the string used at start.").optional(),threadContext:Cr.number().int().optional()}),async execute({action:e,functionPath:t,threadContext:n},r){if(e==="start"&&!t)return{data:{error:"functionPath is required for action='start' (the Luau expression resolving to the target function)."},isError:!0};if(!t)return{data:{error:"functionPath is required to identify which running counter to "+e+" (use the same expression you passed to start)."},isError:!0};let o=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor; cannot maintain the counter registry." } end
local __genv = getgenv()
if type(__genv.__mcp_callCounts) ~= "table" then __genv.__mcp_callCounts = {} end
local __KEY = ${s(t)}

local function __resolveTarget()
  local okc, fn = pcall(loadstring, "return " .. __KEY)
  if not okc or type(fn) ~= "function" then return nil, "compile error resolving target expression" end
  local oke, val = pcall(fn)
  if not oke then return nil, "error evaluating target expression: " .. tostring(val) end
  if type(val) ~= "function" then return nil, "expression did not resolve to a function (got " .. tostring(typeof(val)) .. ")" end
  return val, nil
end
`,i;e==="start"?i=`
if type(hookfunction) ~= "function" then return { error = "hookfunction is not available in this executor." } end
if type(newcclosure) ~= "function" then return { error = "newcclosure is not available in this executor." } end

local existing = __genv.__mcp_callCounts[__KEY]
if existing and existing.active then
  return { error = "A counter is already active for this functionPath. Fetch it or stop it before starting again.", key = __KEY }
end

local target, terr = __resolveTarget()
if not target then return { error = "target: " .. tostring(terr) } end

-- Refuse to stack on a function another instrument tool already hooked (stacking
-- strands hooks whose "original" is another tool's wrapper). Owner map is keyed
-- by the target object with weak keys so it never leaks.
if type(__genv.__mcp_hookOwners) ~= "table" then __genv.__mcp_hookOwners = setmetatable({}, { __mode = "k" }) end
local __OWNERTAG = "count:" .. __KEY
local __owner = __genv.__mcp_hookOwners[target]
if __owner and __owner ~= __OWNERTAG then
  return { error = "This function is already instrumented by another tool ('" .. tostring(__owner) .. "'). Stop that one first to avoid stacking hooks.", key = __KEY }
end

-- Register the entry BEFORE hooking so the hook closure can find it immediately.
-- Keep the resolved target object so stop restores the EXACT closure we hooked.
local entry = { calls = 0, orig = nil, target = target, active = true, startedAt = (type(os) == "table" and os.clock and os.clock()) or 0 }
__genv.__mcp_callCounts[__KEY] = entry

local hook = newcclosure(function(...)
  local e = __genv.__mcp_callCounts[__KEY]
  if e and e.active then
    pcall(function() e.calls = (e.calls or 0) + 1 end)
  end
  if e and type(e.orig) == "function" then
    return e.orig(...)
  end
  return ...
end)

local okh, orig = pcall(hookfunction, target, hook)
if not okh then
  __genv.__mcp_callCounts[__KEY] = nil
  return { error = "hookfunction failed: " .. tostring(orig) }
end
if type(orig) ~= "function" then
  __genv.__mcp_callCounts[__KEY] = nil
  return { error = "hookfunction did not return the original function; aborting to keep state clean." }
end
entry.orig = orig
__genv.__mcp_hookOwners[target] = __OWNERTAG

return { started = true, key = __KEY }
`:e==="fetch"?i=`
local entry = __genv.__mcp_callCounts[__KEY]
if type(entry) ~= "table" then
  return { error = "No active counter for this functionPath. Did you start it (with the same expression)?", key = __KEY }
end
return { key = __KEY, active = entry.active == true, calls = entry.calls or 0 }
`:i=`
local entry = __genv.__mcp_callCounts[__KEY]
if type(entry) ~= "table" then
  return { error = "No active counter for this functionPath; nothing to stop.", key = __KEY }
end

local restored = false
local restoreErr = nil
-- Restore against the EXACT object that was hooked, not a re-resolution of the
-- expression (which may now yield a different closure and clobber it).
local target = entry.target
local terr = nil
if type(target) ~= "function" then target, terr = __resolveTarget() end

if type(entry.orig) == "function" and target and type(hookfunction) == "function" then
  local okr = pcall(hookfunction, target, entry.orig)
  if okr then restored = true else restoreErr = "hookfunction restore failed" end
end

if not restored and type(restorefunction) == "function" and target then
  local okrf = pcall(restorefunction, target)
  if okrf then restored = true else restoreErr = (restoreErr or "") .. " restorefunction failed" end
end

if not restored and terr then restoreErr = (restoreErr and (restoreErr .. "; ") or "") .. terr end

local total = entry.calls or 0
entry.active = false
-- Only drop the entry once restoration is confirmed; otherwise keep it (and
-- entry.orig) so the still-installed hook keeps calling through to the original
-- and a later stop can retry instead of stranding the function.
if restored then
  __genv.__mcp_callCounts[__KEY] = nil
  if type(__genv.__mcp_hookOwners) == "table" and target then __genv.__mcp_hookOwners[target] = nil end
end

return {
  stopped = true,
  key = __KEY,
  calls = total,
  restored = restored,
  warning = restored and nil or ("Could not confirm restoration of the original function" .. (restoreErr and (": " .. restoreErr) or "") .. ". The hook may still be active."),
}
`;let l=o+i;return{data:await r.runLuau(l,{threadContext:n,timeoutMs:2e4})}}});import{z as Mn}from"zod";var ml=u({name:"hook-and-log-function",title:"Hook a function and log every call (turnkey instrumentation, MUTATES STATE)",description:`DANGER \u2014 INSTALLS A PERSISTENT GLOBAL HOOK. Turnkey call-tracing for any function: hook a target, automatically record every invocation (stringified arguments + return values + a timestamp), then fetch the captured call log and restore the original \u2014 all from three actions of this one tool. This is the fastest way to answer 'what is this function actually called with, how often, and what does it return?' without hand-writing a hook.

WORKFLOW (stateful \u2014 survives across tool calls via getgenv().__mcp_fnlogs, keyed by functionPath):
  1. action='start' with functionPath \u2014 resolves the target, captures the original, installs a logging hook that transparently calls the original and records up to maxCalls invocations. Returns { started, key }.
  2. action='fetch' with the same functionPath \u2014 reads the accumulated call log so far WITHOUT stopping it. Returns { count, max, calls } where each call is { args[], returns[], t }. Call repeatedly to watch live.
  3. action='stop' with the same functionPath \u2014 restores the original function and removes the registry entry. Returns { stopped }. ALWAYS stop when done.

CAVEATS: The hook is GLOBAL and PERSISTS until you stop it (or the client restarts). It adds overhead on every call to the target and CAN TRIP ANTICHEAT or destabilize the game, especially on hot paths \u2014 prefer specific, low-frequency targets and keep maxCalls modest. Arguments/returns are captured by tostring (Instances become GetFullName()) and both arrays are capped at 8 entries each. Logging stops accumulating once maxCalls is reached, but the hook stays installed (and keeps calling the original) until you stop it. Requires hookfunction, newcclosure, and getgenv; restoration uses hookfunction(target, original) with a restorefunction fallback. Returns { error } with a clear message if a capability is missing, the target cannot be resolved, or there is no active log for fetch/stop.`,category:"Instrumentation",mutatesState:!0,input:Mn.object({action:Mn.enum(["start","fetch","stop"]).describe("What to do: 'start' installs the logging hook on functionPath; 'fetch' returns the call log captured so far (hook stays live); 'stop' restores the original function and clears the log. Use the SAME functionPath for all three so they address the same registry entry."),functionPath:Mn.string().describe("Luau expression resolving to the function to instrument, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).validate', 'getrawmetatable(game).__namecall', or 'getconnections(game.Workspace.Part.Touched)[1].Function'. Evaluated as `return <functionPath>` and must resolve to a function. REQUIRED for 'start'. For 'fetch'/'stop' it is the registry key identifying which running log to act on, so it must match the string used at start (defaults to the start expression).").optional(),maxCalls:Mn.number().int().describe("Maximum number of calls to record before logging stops accumulating (default 100). On 'start' this sizes the ring of captured calls; on 'fetch' it caps how many entries are returned in this response. Keep modest on hot paths to limit overhead and output size.").optional().default(100),threadContext:Mn.number().int().optional()}),async execute({action:e,functionPath:t,maxCalls:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(n??100),1),5e3);if((e==="start"||t===void 0)&&!t)return{data:{error:e==="start"?"functionPath is required for action='start' (the Luau expression resolving to the target function).":"functionPath is required to identify which running log to "+e+" (use the same expression you passed to start)."},isError:!0};let l=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor; cannot maintain the call-log registry." } end
local __genv = getgenv()
if type(__genv.__mcp_fnlogs) ~= "table" then __genv.__mcp_fnlogs = {} end
local __KEY = ${s(t)}

local function __enc(v)
  local ok, t = pcall(typeof, v)
  if not ok then t = type(v) end
  if t == "Instance" then
    local okn, n = pcall(function() return v:GetFullName() end)
    return okn and ("Instance: " .. tostring(n)) or "<Instance>"
  end
  local oks, s = pcall(tostring, v)
  if not oks then return "<" .. tostring(t) .. ">" end
  if t == "string" or t == "number" or t == "boolean" or t == "nil" then return s end
  return tostring(t) .. ": " .. s
end

local function __resolveTarget()
  local okc, fn = pcall(loadstring, "return " .. __KEY)
  if not okc or type(fn) ~= "function" then return nil, "compile error resolving target expression" end
  local oke, val = pcall(fn)
  if not oke then return nil, "error evaluating target expression: " .. tostring(val) end
  if type(val) ~= "function" then return nil, "expression did not resolve to a function (got " .. tostring(typeof(val)) .. ")" end
  return val, nil
end
`,c;e==="start"?c=`
if type(hookfunction) ~= "function" then return { error = "hookfunction is not available in this executor." } end
if type(newcclosure) ~= "function" then return { error = "newcclosure is not available in this executor." } end

local existing = __genv.__mcp_fnlogs[__KEY]
if existing and existing.active then
  return { error = "A log is already active for this functionPath. Fetch it or stop it before starting again.", key = __KEY }
end

local target, terr = __resolveTarget()
if not target then return { error = "target: " .. tostring(terr) } end

-- Create + register the entry BEFORE hooking so the hook closure can find it immediately.
local entry = { log = {}, max = ${o}, orig = nil, active = true, startedAt = (type(os) == "table" and os.clock and os.clock()) or 0 }
__genv.__mcp_fnlogs[__KEY] = entry

local hook = newcclosure(function(...)
  local e = __genv.__mcp_fnlogs[__KEY]
  -- Always call the original first so behavior is unchanged even if logging errors.
  local packed = table.pack(...)
  local results
  if e and type(e.orig) == "function" then
    results = table.pack(e.orig(...))
  else
    results = table.pack(...)
  end
  if e and e.active and #e.log < e.max then
    pcall(function()
      local a = {}
      for i = 1, math.min(packed.n or #packed, 8) do
        local ok, v = pcall(__enc, packed[i])
        a[i] = ok and v or "?"
      end
      local r = {}
      for i = 1, math.min(results.n or #results, 8) do
        local ok, v = pcall(__enc, results[i])
        r[i] = ok and v or "?"
      end
      table.insert(e.log, {
        args = a,
        argc = packed.n or #packed,
        returns = r,
        retc = results.n or #results,
        t = (type(os) == "table" and os.clock and os.clock()) or 0,
      })
    end)
  end
  return table.unpack(results, 1, results.n or #results)
end)

local okh, orig = pcall(hookfunction, target, hook)
if not okh then
  -- Roll back the registry entry so a failed start does not leave a dangling log.
  __genv.__mcp_fnlogs[__KEY] = nil
  return { error = "hookfunction failed: " .. tostring(orig) }
end
if type(orig) ~= "function" then
  __genv.__mcp_fnlogs[__KEY] = nil
  return { error = "hookfunction did not return the original function; aborting to keep state clean." }
end
entry.orig = orig

return { started = true, key = __KEY, max = entry.max }
`:e==="fetch"?c=`
local entry = __genv.__mcp_fnlogs[__KEY]
if type(entry) ~= "table" then
  return { error = "No active log for this functionPath. Did you start it (with the same expression)?", key = __KEY }
end

local log = entry.log or {}
local limit = math.min(#log, ${o})
local out = {}
for i = 1, limit do out[i] = log[i] end

return {
  key = __KEY,
  active = entry.active == true,
  count = #log,
  max = entry.max,
  reachedMax = (#log >= (entry.max or 0)),
  returnedCount = limit,
  truncated = limit < #log,
  calls = out,
}
`:c=`
local entry = __genv.__mcp_fnlogs[__KEY]
if type(entry) ~= "table" then
  return { error = "No active log for this functionPath; nothing to stop.", key = __KEY }
end

local restored = false
local restoreErr = nil
local target, terr = __resolveTarget()

if type(entry.orig) == "function" and target and type(hookfunction) == "function" then
  -- Re-hook the (current) target back to the captured original.
  local okr = pcall(hookfunction, target, entry.orig)
  if okr then restored = true else restoreErr = "hookfunction restore failed" end
end

if not restored and type(restorefunction) == "function" and target then
  local okrf = pcall(restorefunction, target)
  if okrf then restored = true else restoreErr = (restoreErr or "") .. " restorefunction failed" end
end

if not restored and terr then restoreErr = (restoreErr and (restoreErr .. "; ") or "") .. terr end

local captured = entry.log and #entry.log or 0
entry.active = false
__genv.__mcp_fnlogs[__KEY] = nil

return {
  stopped = true,
  key = __KEY,
  restored = restored,
  capturedCalls = captured,
  warning = restored and nil or ("Could not confirm restoration of the original function" .. (restoreErr and (": " .. restoreErr) or "") .. ". The hook may still be active."),
}
`;let d=l+c;return{data:await a.runLuau(d,{threadContext:r,timeoutMs:2e4})}}});import{z as Ee}from"zod";var Ld=Ee.object({kind:Ee.enum(["string","number","boolean","nil","raw"]).describe("How to interpret `value`. 'string'/'number'/'boolean' force that literal scalar to be returned. 'nil' makes the function return nil. 'raw' treats `value` as a Luau expression \u2014 REQUIRED for any non-primitive return type (Vector3, CFrame, Color3, a table, an Instance reference, etc.)."),value:Ee.union([Ee.string(),Ee.number(),Ee.boolean()]).describe("The literal value (for string/number/boolean) or, when kind='raw', a Luau expression string such as 'true', '100', '{ valid = true }', 'Vector3.new(0,50,0)', or 'game.Workspace'. Omit entirely when kind='nil'.").optional()}).describe("The value the spoofed function should always return, expressed as a typed argument."),hl=u({name:"spoof-function-return",title:"Force a function to always return a chosen value (MUTATES STATE via hookfunction)",description:`WRITES LIVE GAME STATE \u2014 INSTALLS A PERSISTENT GLOBAL HOOK. Replaces a target function with a stub that IGNORES its arguments and ALWAYS returns a value you choose, without ever calling the original. This is the canonical anticheat/validation bypass: make a check like \`isValid()\` return true, force a server-config getter to return your value, or stub a paywall test to return false. Distinct from block-function (which makes the target a no-op returning nothing) because here you control the exact return value.

WORKFLOW (stateful \u2014 survives across tool calls via getgenv().__mcp_spoofReturns, keyed by functionPath):
  1. action='start' with functionPath + returnValue \u2014 resolves the target, captures the original, installs a stub that returns your value. Returns { started, key, returns }.
  2. action='stop' with the same functionPath \u2014 restores the original function. Returns { stopped }.

CAVEATS: the hook is GLOBAL and PERSISTS until you stop it (or the client restarts). The original is NEVER called while spoofed, so any side effects the real function had will not happen \u2014 this can desync state or destabilize the game, and a live function hook CAN TRIP ANTICHEAT. Always stop when done. Requires hookfunction, newcclosure, and getgenv; restoration uses hookfunction(target, original) with a restorefunction fallback. Returns { error } if a capability is missing, the target cannot be resolved, or there is already an active spoof for fetch/stop.`,category:"Instrumentation",mutatesState:!0,input:Ee.object({action:Ee.enum(["start","stop"]).describe("'start' installs the return-spoofing stub on functionPath (requires returnValue); 'stop' restores the original function. Use the SAME functionPath for both so they address the same registry entry."),functionPath:Ee.string().describe("Luau expression resolving to the function to spoof, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.AntiCheat).isValid' or 'getrawmetatable(game).__index'. Evaluated as `return <functionPath>` and must resolve to a function. REQUIRED for 'start'. For 'stop' it is the registry key identifying which spoof to restore, so it must match the string used at start.").optional(),returnValue:Ld.optional(),threadContext:Ee.number().int().optional()}),async execute({action:e,functionPath:t,returnValue:n,threadContext:r},a){if(e==="start"&&!t)return{data:{error:"functionPath is required for action='start' (the Luau expression resolving to the target function)."},isError:!0};if(!t)return{data:{error:"functionPath is required to identify which spoof to "+e+" (use the same expression you passed to start)."},isError:!0};if(e==="start"&&!n)return{data:{error:"returnValue is required for action='start' (the typed value the function should always return)."},isError:!0};let o=s(t),i=e==="start"?te(n):"nil",l=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor; cannot maintain the spoof registry." } end
local __genv = getgenv()
if type(__genv.__mcp_spoofReturns) ~= "table" then __genv.__mcp_spoofReturns = {} end
local __KEY = ${o}

local function __resolveTarget()
  local okc, fn = pcall(loadstring, "return " .. __KEY)
  if not okc or type(fn) ~= "function" then return nil, "compile error resolving target expression" end
  local oke, val = pcall(fn)
  if not oke then return nil, "error evaluating target expression: " .. tostring(val) end
  if type(val) ~= "function" then return nil, "expression did not resolve to a function (got " .. tostring(typeof(val)) .. ")" end
  return val, nil
end
`,c;e==="start"?c=`
if type(hookfunction) ~= "function" then return { error = "hookfunction is not available in this executor." } end
if type(newcclosure) ~= "function" then return { error = "newcclosure is not available in this executor." } end

local existing = __genv.__mcp_spoofReturns[__KEY]
if existing and existing.active then
  return { error = "A spoof is already active for this functionPath. Stop it before starting again.", key = __KEY }
end

-- Evaluate the chosen return value ONCE up front so a bad expression fails the start cleanly.
local okv, spoofVal = pcall(function() return ${i} end)
if not okv then return { error = "failed to evaluate returnValue: " .. tostring(spoofVal) } end

local target, terr = __resolveTarget()
if not target then return { error = "target: " .. tostring(terr) } end

-- Refuse to stack on a function another instrument tool already hooked. Owner map
-- is keyed by the target object with weak keys so it never leaks.
if type(__genv.__mcp_hookOwners) ~= "table" then __genv.__mcp_hookOwners = setmetatable({}, { __mode = "k" }) end
local __OWNERTAG = "spoof:" .. __KEY
local __owner = __genv.__mcp_hookOwners[target]
if __owner and __owner ~= __OWNERTAG then
  return { error = "This function is already instrumented by another tool ('" .. tostring(__owner) .. "'). Stop that one first to avoid stacking hooks.", key = __KEY }
end

-- Keep the resolved target object so stop restores the EXACT closure we hooked.
local entry = { orig = nil, target = target, active = true, value = spoofVal, startedAt = (type(os) == "table" and os.clock and os.clock()) or 0 }
__genv.__mcp_spoofReturns[__KEY] = entry

local hook = newcclosure(function(...)
  local e = __genv.__mcp_spoofReturns[__KEY]
  if e and e.active then
    return e.value
  end
  -- Spoof was cleared but hook still installed: fall back to the original.
  if e and type(e.orig) == "function" then return e.orig(...) end
  return ...
end)

local okh, orig = pcall(hookfunction, target, hook)
if not okh then
  __genv.__mcp_spoofReturns[__KEY] = nil
  return { error = "hookfunction failed: " .. tostring(orig) }
end
if type(orig) ~= "function" then
  __genv.__mcp_spoofReturns[__KEY] = nil
  return { error = "hookfunction did not return the original function; aborting to keep state clean." }
end
entry.orig = orig
__genv.__mcp_hookOwners[target] = __OWNERTAG

local enc = nil
pcall(function()
  local t = typeof(spoofVal)
  if t == "Instance" then local ok,n = pcall(function() return spoofVal:GetFullName() end); enc = ok and ("Instance: " .. n) or "<Instance>"
  else enc = tostring(spoofVal) end
end)

return { started = true, key = __KEY, returns = enc }
`:c=`
local entry = __genv.__mcp_spoofReturns[__KEY]
if type(entry) ~= "table" then
  return { error = "No active spoof for this functionPath; nothing to stop.", key = __KEY }
end

local restored = false
local restoreErr = nil
-- Restore against the EXACT object that was hooked, not a re-resolution of the
-- expression (which may now yield a different closure and clobber it).
local target = entry.target
local terr = nil
if type(target) ~= "function" then target, terr = __resolveTarget() end

if type(entry.orig) == "function" and target and type(hookfunction) == "function" then
  local okr = pcall(hookfunction, target, entry.orig)
  if okr then restored = true else restoreErr = "hookfunction restore failed" end
end

if not restored and type(restorefunction) == "function" and target then
  local okrf = pcall(restorefunction, target)
  if okrf then restored = true else restoreErr = (restoreErr or "") .. " restorefunction failed" end
end

if not restored and terr then restoreErr = (restoreErr and (restoreErr .. "; ") or "") .. terr end

entry.active = false
-- Only drop the entry once restoration is confirmed; otherwise keep it (and
-- entry.orig) so the still-installed stub falls back to e.orig(...) and a later
-- stop can retry instead of leaving the function spoofed forever.
if restored then
  __genv.__mcp_spoofReturns[__KEY] = nil
  if type(__genv.__mcp_hookOwners) == "table" and target then __genv.__mcp_hookOwners[target] = nil end
end

return {
  stopped = true,
  key = __KEY,
  restored = restored,
  warning = restored and nil or ("Could not confirm restoration of the original function" .. (restoreErr and (": " .. restoreErr) or "") .. ". The hook may still be active."),
}
`;let d=l+c;return{data:await a.runLuau(d,{threadContext:r,timeoutMs:2e4})}}});import{z as Ir}from"zod";var gl=u({name:"trace-call-durations",title:"Profile how long a function takes per call (MUTATES STATE via hookfunction)",description:`WRITES LIVE GAME STATE \u2014 INSTALLS A PERSISTENT GLOBAL HOOK. Per-function profiler: hook a target so that every invocation is timed with os.clock(), accumulating call count plus total/min/max time, then read the aggregated stats, then restore the original. This is the fastest way to answer 'how expensive is this function and how often does it run?' \u2014 ideal for finding the hot path in an anticheat loop, a render step, or a remote handler. Unlike count-function-calls (count only) it also measures duration; unlike hook-and-log-function it stores only aggregates (no per-call args), so it is cheap enough for hot paths.

WORKFLOW (stateful \u2014 survives across tool calls via getgenv().__mcp_callTimings, keyed by functionPath):
  1. action='start' with functionPath \u2014 resolves the target, captures the original, installs a timing wrapper that transparently calls the original and records elapsed time. Returns { started, key }.
  2. action='fetch' with the same functionPath \u2014 returns { count, totalMs, avgMs, minMs, maxMs } so far WITHOUT stopping. Poll to watch live.
  3. action='stop' with the same functionPath \u2014 restores the original and clears the entry. Returns final stats.

CAVEATS: the hook is GLOBAL and PERSISTS until you stop it (or the client restarts), adds (small) timing overhead on every call, and a live function hook CAN TRIP ANTICHEAT \u2014 always stop when done. The original is called through real-time (its return values are passed back unchanged); timing/aggregation is pcall-isolated. Requires hookfunction, newcclosure, and getgenv; restoration uses hookfunction(target, original) with a restorefunction fallback. Returns { error } if a capability is missing, the target cannot be resolved, or there is no active profile for fetch/stop.`,category:"Instrumentation",mutatesState:!0,input:Ir.object({action:Ir.enum(["start","fetch","stop"]).describe("'start' installs the timing wrapper on functionPath; 'fetch' returns the aggregated timing stats so far (hook stays live); 'stop' restores the original function and clears the stats. Use the SAME functionPath for all three so they address the same registry entry."),functionPath:Ir.string().describe("Luau expression resolving to the function to profile, e.g. 'getsenv(game.Players.LocalPlayer.PlayerScripts.Main).update' or 'getrawmetatable(game).__namecall'. Evaluated as `return <functionPath>` and must resolve to a function. REQUIRED for 'start'. For 'fetch'/'stop' it is the registry key identifying which running profile to act on, so it must match the string used at start.").optional(),threadContext:Ir.number().int().optional()}),async execute({action:e,functionPath:t,threadContext:n},r){if(e==="start"&&!t)return{data:{error:"functionPath is required for action='start' (the Luau expression resolving to the target function)."},isError:!0};if(!t)return{data:{error:"functionPath is required to identify which profile to "+e+" (use the same expression you passed to start)."},isError:!0};let o=`
if type(getgenv) ~= "function" then return { error = "getgenv is not available in this executor; cannot maintain the timing registry." } end
local __genv = getgenv()
if type(__genv.__mcp_callTimings) ~= "table" then __genv.__mcp_callTimings = {} end
local __KEY = ${s(t)}

local function __resolveTarget()
  local okc, fn = pcall(loadstring, "return " .. __KEY)
  if not okc or type(fn) ~= "function" then return nil, "compile error resolving target expression" end
  local oke, val = pcall(fn)
  if not oke then return nil, "error evaluating target expression: " .. tostring(val) end
  if type(val) ~= "function" then return nil, "expression did not resolve to a function (got " .. tostring(typeof(val)) .. ")" end
  return val, nil
end

-- Build a {count,totalMs,avgMs,minMs,maxMs} report from an entry, guarding the no-call case.
local function __report(e)
  local count = e.count or 0
  local totalSec = e.total or 0
  local totalMs = totalSec * 1000
  return {
    count = count,
    totalMs = totalMs,
    avgMs = (count > 0) and (totalMs / count) or 0,
    minMs = (count > 0 and e.min ~= nil) and (e.min * 1000) or 0,
    maxMs = (count > 0 and e.max ~= nil) and (e.max * 1000) or 0,
  }
end
`,i;e==="start"?i=`
if type(hookfunction) ~= "function" then return { error = "hookfunction is not available in this executor." } end
if type(newcclosure) ~= "function" then return { error = "newcclosure is not available in this executor." } end
if type(os) ~= "table" or type(os.clock) ~= "function" then return { error = "os.clock is not available; cannot time calls." } end

local existing = __genv.__mcp_callTimings[__KEY]
if existing and existing.active then
  return { error = "A profile is already active for this functionPath. Fetch it or stop it before starting again.", key = __KEY }
end

local target, terr = __resolveTarget()
if not target then return { error = "target: " .. tostring(terr) } end

-- Refuse to stack on a function another instrument tool already hooked. Owner map
-- is keyed by the target object with weak keys so it never leaks.
if type(__genv.__mcp_hookOwners) ~= "table" then __genv.__mcp_hookOwners = setmetatable({}, { __mode = "k" }) end
local __OWNERTAG = "trace:" .. __KEY
local __owner = __genv.__mcp_hookOwners[target]
if __owner and __owner ~= __OWNERTAG then
  return { error = "This function is already instrumented by another tool ('" .. tostring(__owner) .. "'). Stop that one first to avoid stacking hooks.", key = __KEY }
end

-- Keep the resolved target object so stop restores the EXACT closure we hooked.
local entry = { count = 0, total = 0, min = nil, max = nil, orig = nil, target = target, active = true, startedAt = os.clock() }
__genv.__mcp_callTimings[__KEY] = entry

local hook = newcclosure(function(...)
  local e = __genv.__mcp_callTimings[__KEY]
  local orig = e and e.orig
  if type(orig) ~= "function" then return ... end
  local t0 = os.clock()
  local results = table.pack(orig(...))
  local dt = os.clock() - t0
  if e and e.active then
    pcall(function()
      e.count = (e.count or 0) + 1
      e.total = (e.total or 0) + dt
      if e.min == nil or dt < e.min then e.min = dt end
      if e.max == nil or dt > e.max then e.max = dt end
    end)
  end
  return table.unpack(results, 1, results.n or #results)
end)

local okh, orig = pcall(hookfunction, target, hook)
if not okh then
  __genv.__mcp_callTimings[__KEY] = nil
  return { error = "hookfunction failed: " .. tostring(orig) }
end
if type(orig) ~= "function" then
  __genv.__mcp_callTimings[__KEY] = nil
  return { error = "hookfunction did not return the original function; aborting to keep state clean." }
end
entry.orig = orig
__genv.__mcp_hookOwners[target] = __OWNERTAG

return { started = true, key = __KEY }
`:e==="fetch"?i=`
local entry = __genv.__mcp_callTimings[__KEY]
if type(entry) ~= "table" then
  return { error = "No active profile for this functionPath. Did you start it (with the same expression)?", key = __KEY }
end
local r = __report(entry)
r.key = __KEY
r.active = entry.active == true
return r
`:i=`
local entry = __genv.__mcp_callTimings[__KEY]
if type(entry) ~= "table" then
  return { error = "No active profile for this functionPath; nothing to stop.", key = __KEY }
end

local restored = false
local restoreErr = nil
-- Restore against the EXACT object that was hooked, not a re-resolution of the
-- expression (which may now yield a different closure and clobber it).
local target = entry.target
local terr = nil
if type(target) ~= "function" then target, terr = __resolveTarget() end

if type(entry.orig) == "function" and target and type(hookfunction) == "function" then
  local okr = pcall(hookfunction, target, entry.orig)
  if okr then restored = true else restoreErr = "hookfunction restore failed" end
end

if not restored and type(restorefunction) == "function" and target then
  local okrf = pcall(restorefunction, target)
  if okrf then restored = true else restoreErr = (restoreErr or "") .. " restorefunction failed" end
end

if not restored and terr then restoreErr = (restoreErr and (restoreErr .. "; ") or "") .. terr end

local r = __report(entry)
entry.active = false
-- Only drop the entry once restoration is confirmed; otherwise keep it (and
-- entry.orig) so the still-installed wrapper keeps calling through to the
-- original and a later stop can retry.
if restored then
  __genv.__mcp_callTimings[__KEY] = nil
  if type(__genv.__mcp_hookOwners) == "table" and target then __genv.__mcp_hookOwners[target] = nil end
end

r.stopped = true
r.key = __KEY
r.restored = restored
if not restored then
  r.warning = "Could not confirm restoration of the original function" .. (restoreErr and (": " .. restoreErr) or "") .. ". The hook may still be active."
end
return r
`;let l=o+i;return{data:await r.runLuau(l,{threadContext:n,timeoutMs:2e4})}}});import{z as Ln}from"zod";var bl=u({name:"discover-player-values",title:"Discover Candidate Money / Score / Level Value Paths",description:"Auto-discovery for 'where's the money/score/XP path?'. Walks LocalPlayer (esp. leaderstats), PlayerGui, ReplicatedStorage and ReplicatedFirst for IntValue/NumberValue/StringValue/BoolValue/Folder-of-values, scores each by name keywords (money/coin/cash/gold/score/xp/level/exp/kills/wins/...), container weight (leaderstats >> everything else), kind (numeric > string > bool), and magnitude. Returns a single ranked list of { path, class, name, value, score, reasons[] } so the AI doesn't have to grind through the tree. Pure read; no remotes fired, no state mutated. Use this as the first probe on any unfamiliar game.",category:"Inspection",mutatesState:!1,input:Ln.object({limit:Ln.number().int().positive().max(200).optional().describe("Maximum candidates to return, ranked by score (default 50)."),minScore:Ln.number().optional().describe("Drop candidates below this score; default 0 returns everything."),extraRoots:Ln.array(Ln.string()).optional().describe("Additional Luau path expressions to scan, e.g. ['game.Workspace.GameValues']. Defaults already cover LocalPlayer/leaderstats/PlayerGui/ReplicatedStorage/ReplicatedFirst.")}),async execute({limit:e,minScore:t,extraRoots:n},r){let a=e??50,o=t??0,i=(n??[]).filter(p=>typeof p=="string"&&p.length>0),c=`
local Players = game:GetService("Players")
local local_player = Players.LocalPlayer

-- Roots to walk, each with a static weight applied to all descendants below it.
local roots = {}
local function add(root, weight, label)
  if root then roots[#roots + 1] = { inst = root, weight = weight, label = label } end
end
if local_player then
  pcall(function() add(local_player:FindFirstChild("leaderstats"), 200, "leaderstats") end)
  pcall(function() add(local_player, 60, "Player") end)
  pcall(function() add(local_player:FindFirstChild("PlayerGui"), 25, "PlayerGui") end)
  pcall(function() add(local_player:FindFirstChild("PlayerScripts"), 10, "PlayerScripts") end)
end
pcall(function() add(game:GetService("ReplicatedStorage"), 40, "ReplicatedStorage") end)
pcall(function() add(game:GetService("ReplicatedFirst"), 30, "ReplicatedFirst") end)

-- Caller-supplied extras (Luau path expressions, loadstring'd).
for _, extra in ipairs(${i.length?"{"+i.map(p=>`"${p.replace(/"/g,'\\"')}"`).join(",")+"}":"{}"}) do
  local fn, _ = loadstring("return " .. extra)
  if fn then
    local ok, v = pcall(fn)
    if ok and typeof(v) == "Instance" then add(v, 35, extra) end
  end
end

-- Keyword buckets with weights.
local KEYWORDS = {
  { 100, "money" }, { 100, "coin" }, { 100, "cash" }, { 95, "gold" }, { 90, "gem" },
  { 95, "score" }, { 90, "xp" }, { 90, "exp" }, { 85, "level" }, { 80, "rank" },
  { 80, "kill" }, { 70, "death" }, { 75, "win" }, { 60, "loss" }, { 65, "rebirth" },
  { 65, "diamond" }, { 60, "token" }, { 55, "stat" }, { 50, "point" }, { 60, "credit" },
}
local function keywordScore(name)
  local low = string.lower(name or "")
  local best, reasons = 0, {}
  for _, e in ipairs(KEYWORDS) do
    if string.find(low, e[2], 1, true) then
      if e[1] > best then best = e[1] end
      reasons[#reasons + 1] = "name:" .. e[2]
    end
  end
  return best, reasons
end

local VALUE_KINDS = {
  IntValue = 1, NumberValue = 1, BoolValue = 0.5, StringValue = 0.5,
  CFrameValue = 0.4, Vector3Value = 0.4, Color3Value = 0.3, BrickColorValue = 0.3,
  ObjectValue = 0.5, RayValue = 0.3,
}

local out, seenPath = {}, {}
local function visit(inst, rootWeight, rootLabel, depth)
  if depth > 8 then return end
  local children
  local okc, c = pcall(function() return inst:GetChildren() end)
  if not okc then return end
  children = c
  for _, child in ipairs(children) do
    pcall(function()
      local cls = child.ClassName
      local kindWeight = VALUE_KINDS[cls]
      if kindWeight then
        local nm = child.Name or ""
        local kwScore, reasons = keywordScore(nm)
        local val, magnitude = nil, 0
        local okv, raw = pcall(function() return child.Value end)
        if okv then
          val = raw
          if type(raw) == "number" then magnitude = math.log(math.abs(raw) + 2) * 4 end
        end
        local score = rootWeight + kwScore + kindWeight * 30 + magnitude
        local fullName
        local okn, n = pcall(function() return child:GetFullName() end)
        fullName = okn and n or (rootLabel .. "." .. nm)
        if not seenPath[fullName] and score >= ${o} then
          seenPath[fullName] = true
          if rootLabel == "leaderstats" then reasons[#reasons + 1] = "leaderstats" end
          out[#out + 1] = {
            path = fullName,
            name = nm,
            class = cls,
            value = (type(val) == "number" or type(val) == "string" or type(val) == "boolean") and val or tostring(val),
            score = math.floor(score),
            reasons = reasons,
            root = rootLabel,
          }
        end
      end
      -- Recurse into Folder/Configuration/etc. to find nested value bundles.
      visit(child, rootWeight, rootLabel, depth + 1)
    end)
  end
end

for _, r in ipairs(roots) do
  visit(r.inst, r.weight, r.label, 0)
end

-- Sort by score descending; cap to limit.
table.sort(out, function(a, b) return a.score > b.score end)
local capped = {}
for i = 1, math.min(${a}, #out) do capped[i] = out[i] end
return { ok = true, total = #out, returned = #capped, candidates = capped }
`;return{data:await r.runLuau(c,{timeoutMs:15e3})}}});import{z as Ia}from"zod";var yl=u({name:"list-instance-signals",title:"List instance signals",description:"Enumerate the RBXScriptSignal members (events) of a Roblox Instance and report how many connections each has. Connection counts require an executor exposing getconnections(signal); if it is unavailable the signals are still listed but ConnectionCount is reported as null with a note. Returns { Instance, GetConnectionsAvailable, Signals: [{ SignalName, ConnectionCount, Note? }] } or { error } when the instance cannot be resolved.",category:"Inspection",input:Ia.object({instancePath:Ia.string().describe("Lua expression resolving to the target Instance, e.g. 'game.Players.LocalPlayer' or 'game.Workspace.Part'. Evaluated as `return <instancePath>`."),threadContext:Ia.number().int().optional()}),async execute({instancePath:e,threadContext:t},n){let r=`
local okInst, inst = pcall(function() return (loadstring("return " .. ${s(e)}))() end)
if not okInst or typeof(inst) ~= "Instance" then
  return { error = "instancePath did not resolve to an Instance: " .. tostring(${s(e)}) }
end

local getconnectionsFn = getconnections
local hasGetConnections = type(getconnectionsFn) == "function"

local signals = {}
local seen = {}

-- RBXScriptSignal members are not enumerable via pairs on Instances, so probe known + reflected names.
-- Use a property-name probe: attempt to read each candidate and check its typeof.
local function probe(name)
  if seen[name] then return end
  local okGet, value = pcall(function() return inst[name] end)
  if okGet and typeof(value) == "RBXScriptSignal" then
    seen[name] = true
    local count = nil
    local note = nil
    if hasGetConnections then
      local okC, conns = pcall(getconnectionsFn, value)
      if okC and type(conns) == "table" then
        count = #conns
      else
        note = "getconnections failed for this signal: " .. tostring(conns)
      end
    else
      note = "getconnections unavailable in this executor"
    end
    signals[#signals + 1] = { SignalName = name, ConnectionCount = count, Note = note }
  end
end

-- Discover candidate member names via getproperties / API dump if available, else fall back to common signals.
local discovered = false
if type(getproperties) == "function" then
  local okP, props = pcall(getproperties, inst)
  if okP and type(props) == "table" then
    discovered = true
    for _, name in ipairs(props) do probe(tostring(name)) end
  end
end

-- Reflect over the instance's class members through a pcall loop on common + discovered names.
local commonSignals = {
  "Changed","ChildAdded","ChildRemoved","DescendantAdded","DescendantRemoving","AncestryChanged","Destroying",
  "AttributeChanged","Touched","TouchEnded","Activated","Deactivated","MouseButton1Click","MouseButton2Click",
  "MouseButton1Down","MouseButton1Up","MouseButton2Down","MouseButton2Up","MouseEnter","MouseLeave","MouseMoved",
  "InputBegan","InputChanged","InputEnded","Triggered","Died","Running","Jumping","Climbing","Seated","StateChanged",
  "HealthChanged","CharacterAdded","CharacterRemoving","PlayerAdded","PlayerRemoving","OnClientEvent","OnServerEvent",
  "Heartbeat","Stepped","RenderStepped","Completed","Paused","Resumed","Stopped","Play","Loaded","Ended",
  "FocusLost","FocusGained","SelectionChanged","Equipped","Unequipped","ProximityPromptShown","PromptShown",
}
for _, name in ipairs(commonSignals) do probe(name) end

-- Attempt to enumerate attribute-change and property-change signals are dynamic; covered above where applicable.

return {
  Instance = inst:GetFullName(),
  ClassName = inst.ClassName,
  GetConnectionsAvailable = hasGetConnections,
  DiscoveredViaReflection = discovered,
  SignalCount = #signals,
  Signals = signals,
}
`;return{data:await n.runLuau(r,{timeoutMs:2e4,...t!==void 0?{threadContext:t}:{}})}}});import{z as Ce}from"zod";var vl=u({name:"script-grep",title:"Grep across all scripts in the game",description:"Search decompiled Roblox scripts for a pattern, line by line, with surrounding context. Enumerates every client-readable LuaSourceContainer reachable from the active client (via QueryDescendants plus nil-parented scripts), decompiles each, and reports matching lines grouped per script. Matching uses Luau string.find: with literal=true the query is matched as a plain substring; otherwise it is treated as a Luau string pattern (note: Luau patterns, not JavaScript regex). Use exact identifiers or simple patterns; use semantic-search-scripts when behavior is known but names are not. Decompilation is best-effort and can be slow on large places, so the scan is capped by maxScripts.",category:"Inspection",input:Ce.object({query:Ce.string().describe("The search pattern. With literal=false it is interpreted as a Luau string pattern (%d, %w, %s, character classes [a-z], anchors, etc.). Use the literal flag for exact substring matching."),root:Ce.string().describe("Root instance to enumerate scripts under (e.g. 'game', 'game.ReplicatedStorage'). Defaults to 'game'. Narrow this to keep the scan fast.").optional().default("game"),limit:Ce.number().int().describe("Maximum number of scripts to return results from (default: 50).").optional().default(50),contextLines:Ce.number().int().describe("Number of lines of context to show before and after each match (default: 2).").optional().default(2),maxMatchesPerScript:Ce.number().int().describe("Maximum number of matches to return per script (default: 20).").optional().default(20),maxScripts:Ce.number().int().describe("Maximum number of scripts to decompile and scan before stopping (default: 400).").optional().default(400),literal:Ce.boolean().describe("When true, treats the query as a plain literal substring - no pattern interpretation (string.find with plain=true). (default: false)").optional().default(!1),caseSensitive:Ce.boolean().describe("When false, matches case-insensitively. (default: true)").optional().default(!0),threadContext:Ce.number().int().optional()}),async execute({query:e,root:t,limit:n,contextLines:r,maxMatchesPerScript:a,maxScripts:o,literal:i,caseSensitive:l,threadContext:c},d){let p=Math.max(1,Math.floor(n)),f=Math.max(0,Math.floor(r)),h=Math.max(1,Math.floor(a)),g=Math.max(1,Math.min(5e3,Math.floor(o))),b=`
if type(decompile) ~= "function" then
  return { error = "decompile is not available in this executor." }
end

local query = ${s(e)}
local scriptLimit = ${p}
local ctxLines = ${f}
local perScript = ${h}
local scanCap = ${g}
local literal = ${i?"true":"false"}
local caseSensitive = ${l?"true":"false"}

local needle = caseSensitive and query or string.lower(query)

local rootFn, rootErr = loadstring("return " .. ${s(t)})
if not rootFn then
  return { error = "Invalid root expression '" .. ${s(t)} .. "': " .. tostring(rootErr) }
end
local okRoot, rootInstance = pcall(rootFn)
if not okRoot or typeof(rootInstance) ~= "Instance" then
  return { error = "Root path did not resolve to an Instance: " .. ${s(t)} }
end

-- Collect candidate scripts: descendants of root + nil-parented LuaSourceContainers.
local candidates = {}
local seen = {}
local function add(inst)
  if not inst:IsA("LuaSourceContainer") then return end
  if inst:IsA("Script") and inst.RunContext == Enum.RunContext.Server then return end
  if seen[inst] then return end
  seen[inst] = true
  candidates[#candidates + 1] = inst
end

local okQuery, found = pcall(function() return rootInstance:QueryDescendants("LuaSourceContainer") end)
if okQuery and type(found) == "table" then
  for _, inst in ipairs(found) do add(inst) end
end
if type(getnilinstances) == "function" then
  local okNil, nils = pcall(getnilinstances)
  if okNil and type(nils) == "table" then
    for _, inst in ipairs(nils) do
      if typeof(inst) == "Instance" then add(inst) end
    end
  end
end

local function lineMatches(line)
  local hay = caseSensitive and line or string.lower(line)
  return string.find(hay, needle, 1, literal) ~= nil
end

local results = {}
local totalMatches = 0
local scanned = 0
local truncatedScan = false

for _, inst in ipairs(candidates) do
  if #results >= scriptLimit then break end
  if scanned >= scanCap then truncatedScan = true; break end
  scanned = scanned + 1

  local okSrc, src = pcall(function() return decompile(inst) end)
  if okSrc and type(src) == "string" then
    local lines = {}
    for line in (src .. "\\n"):gmatch("(.-)\\n") do lines[#lines + 1] = line end

    local blocks = {}
    for i = 1, #lines do
      if #blocks >= perScript then break end
      if lineMatches(lines[i]) then
        local startI = math.max(1, i - ctxLines)
        local endI = math.min(#lines, i + ctxLines)
        local block = {}
        for j = startI, endI do
          local marker = (j == i) and ">" or " "
          block[#block + 1] = marker .. " " .. j .. ": " .. lines[j]
        end
        blocks[#blocks + 1] = table.concat(block, "\\n")
      end
    end

    if #blocks > 0 then
      totalMatches = totalMatches + #blocks
      local okFull, full = pcall(function() return inst:GetFullName() end)
      results[#results + 1] = {
        Path = okFull and full or tostring(inst),
        ClassName = inst.ClassName,
        MatchCount = #blocks,
        Blocks = blocks,
      }
    end
  end
end

return {
  Query = query,
  TotalMatches = totalMatches,
  ScriptsMatched = #results,
  ScriptsScanned = scanned,
  TruncatedScan = truncatedScan,
  Results = results,
}
`;return{data:await d.runLuau(b,{timeoutMs:12e4,...c!==void 0?{threadContext:c}:{}})}}});import{z as An}from"zod";var kl=u({name:"trace-connection-function",title:"Trace connection function",description:"Inspect a single connection on an Instance's RBXScriptSignal and return debug metadata about the connected Luau function. Uses getconnections(inst[signalName]) to enumerate connections and debug.info/debug.getinfo to resolve the function's name, source, line and parameter count. REQUIRES an executor exposing getconnections and debug.info (or debug.getinfo); if either capability is missing, or the signal/connection/function cannot be resolved, returns a clear { error } describing the missing capability. Returns { Signal, ConnectionIndex, ConnectionCount, Function: { Name, Source, ShortSource, LineDefined, NumParams, IsVararg, What, Pointer } }.",category:"Inspection",input:An.object({instancePath:An.string().describe("Lua expression resolving to the target Instance, e.g. 'game.Players.LocalPlayer.Character.Humanoid'. Evaluated as `return <instancePath>`."),signalName:An.string().describe("Name of the RBXScriptSignal member on the instance to inspect, e.g. 'Touched', 'Changed', 'OnClientEvent'."),connectionIndex:An.number().int().describe("Zero-based index of the connection to trace within getconnections() results (default: 0 = first connection).").optional().default(0),threadContext:An.number().int().optional()}),async execute({instancePath:e,signalName:t,connectionIndex:n,threadContext:r},a){let o=Math.max(0,Math.floor(n)),i=`
local getconnectionsFn = getconnections
if type(getconnectionsFn) ~= "function" then
  return { error = "getconnections is not available in this executor; cannot enumerate signal connections." }
end

local hasDebug = type(debug) == "table"
local debugInfoFn = hasDebug and (debug.info or debug.getinfo) or nil
if type(debugInfoFn) ~= "function" then
  return { error = "debug.info / debug.getinfo is not available in this executor; cannot inspect the connected function." }
end

local okInst, inst = pcall(function() return (loadstring("return " .. ${s(e)}))() end)
if not okInst or typeof(inst) ~= "Instance" then
  return { error = "instancePath did not resolve to an Instance: " .. tostring(${s(e)}) }
end

local okSig, signal = pcall(function() return inst[${s(t)}] end)
if not okSig then
  return { error = "Failed to access member '" .. ${s(t)} .. "' on " .. inst:GetFullName() .. ": " .. tostring(signal) }
end
if typeof(signal) ~= "RBXScriptSignal" then
  return { error = "Member '" .. ${s(t)} .. "' on " .. inst:GetFullName() .. " is not an RBXScriptSignal (got " .. typeof(signal) .. ")." }
end

local okConns, conns = pcall(getconnectionsFn, signal)
if not okConns or type(conns) ~= "table" then
  return { error = "getconnections failed for signal '" .. ${s(t)} .. "': " .. tostring(conns) }
end

local connectionCount = #conns
if connectionCount == 0 then
  return { error = "Signal '" .. ${s(t)} .. "' has no connections.", ConnectionCount = 0 }
end

local idx = ${o} + 1 -- Lua arrays are 1-based; input is 0-based.
if idx < 1 or idx > connectionCount then
  return { error = "connectionIndex out of range (have " .. connectionCount .. " connections).", ConnectionCount = connectionCount }
end

local conn = conns[idx]
local okFn, fn = pcall(function() return conn.Function end)
if not okFn or type(fn) ~= "function" then
  return {
    error = "Connection at index " .. ${o} .. " has no inspectable .Function (it may be a foreign/C connection). Got: " .. tostring(okFn and typeof(fn) or fn),
    ConnectionCount = connectionCount,
    ConnectionIndex = ${o},
  }
end

-- debug.info supports both the (fn, "options") string form and individual fields.
-- Try the rich getinfo-style call first, then fall back to field-by-field debug.info.
local function describeFunction(f)
  local result = {
    Name = "<anonymous>",
    Source = "",
    ShortSource = "",
    LineDefined = -1,
    NumParams = -1,
    IsVararg = false,
    What = "?",
    Pointer = tostring(f),
  }

  local okTbl, infoTbl = pcall(debugInfoFn, f, "nSlu")
  if okTbl and type(infoTbl) == "table" then
    result.Name = infoTbl.name or result.Name
    result.Source = infoTbl.source or result.Source
    result.ShortSource = infoTbl.short_src or result.ShortSource
    result.LineDefined = infoTbl.linedefined or result.LineDefined
    result.NumParams = infoTbl.nparams or result.NumParams
    result.IsVararg = infoTbl.isvararg == true
    result.What = infoTbl.what or result.What
    return result
  end

  -- Fall back to debug.info(f, "s") style returning multiple scalar values per option char.
  local okName, nameVal = pcall(debugInfoFn, f, "n")
  if okName and nameVal ~= nil and type(nameVal) ~= "table" then result.Name = tostring(nameVal) end
  local okSrc, srcVal = pcall(debugInfoFn, f, "s")
  if okSrc and srcVal ~= nil and type(srcVal) ~= "table" then result.Source = tostring(srcVal) end
  local okLine, lineVal = pcall(debugInfoFn, f, "l")
  if okLine and type(lineVal) == "number" then result.LineDefined = lineVal end
  local okParams, paramVal = pcall(debugInfoFn, f, "a")
  if okParams and type(paramVal) == "number" then result.NumParams = paramVal end
  return result
end

local okDesc, fnInfo = pcall(describeFunction, fn)
if not okDesc then
  return { error = "Failed to read debug info for the connected function: " .. tostring(fnInfo), ConnectionCount = connectionCount }
end

return {
  Signal = ${s(t)},
  Instance = inst:GetFullName(),
  ConnectionIndex = ${o},
  ConnectionCount = connectionCount,
  Function = fnInfo,
}
`;return{data:await a.runLuau(i,{timeoutMs:2e4,...r!==void 0?{threadContext:r}:{}})}}});import{z as Ta}from"zod";var xl=u({name:"verify-path-exists",title:"Verify an instance path resolves",description:"Cheaply check whether a dotted instance path currently resolves to a real Instance, without reading any properties. Use this as a pre-flight check before click-button / type-text-box / get-instance-properties so you fail fast with a clear message instead of acting on a stale or wrong path (UI gets created/destroyed dynamically). Returns { exists, className?, fullName? } \u2014 when exists is false, className/fullName are omitted.",category:"Inspection",input:Ta.object({path:Ta.string().describe("Dotted path to verify, starting at 'game' (e.g. 'game.Players.LocalPlayer.PlayerGui.Shop.BuyButton'). Resolution walks each '.'-separated segment via direct indexing then FindFirstChild."),threadContext:Ta.number().int().optional()}),async execute({path:e,threadContext:t},n){let r=`
local path = ${s(e)}

local function resolve(p)
  local segments = {}
  for seg in string.gmatch(p, "[^%.]+") do table.insert(segments, seg) end
  if #segments == 0 then return nil end
  local first = segments[1]
  local current
  if first == "game" or first == "Game" then
    current = game
  elseif first == "workspace" or first == "Workspace" then
    current = workspace
  else
    local ok, svc = pcall(function() return game:GetService(first) end)
    if ok and svc then
      current = svc
    else
      local ok2, child = pcall(function() return game:FindFirstChild(first) end)
      if ok2 and child then current = child end
    end
  end
  if not current then return nil end
  for i = 2, #segments do
    local name = segments[i]
    local ok, nxt = pcall(function() return (current :: any)[name] end)
    if not ok or nxt == nil then
      local ok2, child = pcall(function() return current:FindFirstChild(name) end)
      if ok2 and child then nxt = child else return nil end
    end
    current = nxt
  end
  return current
end

local inst = resolve(path)
if inst == nil or typeof(inst) ~= "Instance" then
  return { exists = false, Path = path }
end

local className
local fullName
local okC, c = pcall(function() return inst.ClassName end)
if okC then className = c end
local okF, f = pcall(function() return inst:GetFullName() end)
if okF then fullName = f end

return { exists = true, Path = path, className = className, fullName = fullName }`;return{data:await n.runLuau(r,{timeoutMs:15e3,...t!==void 0?{threadContext:t}:{}})}}});import{z as Nn}from"zod";var _l=u({name:"list-gui-elements",title:"List GUI elements under a root",description:"Enumerate the live GUI tree under a root Instance (defaults to the LocalPlayer's PlayerGui) and return a flat list of every GuiObject it contains. This is the fastest way to discover what UI is actually on screen \u2014 the exact paths, classes and current Text \u2014 so you can then read or drive a specific element with get-gui-text, set-gui-text, click-button or type-text-box. Walks root:GetDescendants() with each property access pcall-guarded so a single hostile element never aborts the scan. For every descendant that is (or, with classFilter, exactly matches) a GuiObject it records { path = GetFullName(), class = ClassName, name = Name, Visible, Text } where Visible and Text are only present when readable. Output is capped at `limit`; when more elements exist than the cap, `truncated` is true. Returns { count, truncated, elements } or { error }.",category:"GUI",input:Nn.object({root:Nn.string().describe(`Luau expression resolving to the Instance whose descendant GUI tree to list. Defaults to 'game:GetService("Players").LocalPlayer.PlayerGui'. Pass a deeper expression such as 'game:GetService("CoreGui")' or 'game.Players.LocalPlayer.PlayerGui.MainMenu' to scope the walk. Evaluated as \`return <root>\`.`).optional().default('game:GetService("Players").LocalPlayer.PlayerGui'),classFilter:Nn.string().describe("Optional exact ClassName to keep, e.g. 'TextButton', 'TextLabel', 'TextBox', 'ImageButton', 'Frame'. When set, only descendants whose ClassName equals this string are returned. When omitted, every GuiObject (IsA('GuiObject')) is returned. Case-sensitive.").optional(),limit:Nn.number().int().describe("Maximum number of elements to return (default 200). The walk stops adding once this many matches are collected and sets `truncated` to true so you know to scope the root or filter more tightly.").optional().default(200),threadContext:Nn.number().int().optional()}),async execute({root:e,classFilter:t,limit:n,threadContext:r},a){let o=Math.min(Math.max(Math.floor(n??200),1),5e3),i=t?s(t):"nil",l=`
${k}
local rootInst, err = __eval(${s(e)})
if err then return { error = err } end
if typeof(rootInst) ~= "Instance" then return { error = "root did not resolve to an Instance (got " .. typeof(rootInst) .. "): " .. ${s(e)} } end

local classFilter = ${i}
local cap = ${o}

local okDesc, descendants = pcall(function() return rootInst:GetDescendants() end)
if not okDesc or type(descendants) ~= "table" then return { error = "failed to read GetDescendants() of root: " .. tostring(descendants) } end

local elements = {}
local count = 0
local truncated = false

for _, inst in ipairs(descendants) do
  local keep = false
  if classFilter ~= nil then
    local okC, cn = pcall(function() return inst.ClassName end)
    keep = okC and (cn == classFilter)
  else
    local okIs, isGui = pcall(function() return inst:IsA("GuiObject") end)
    keep = okIs and isGui == true
  end

  if keep then
    if count >= cap then truncated = true break end
    count = count + 1

    local rec = {}
    local okPath, full = pcall(function() return inst:GetFullName() end)
    rec.path = okPath and full or tostring(inst)
    local okClass, cn = pcall(function() return inst.ClassName end)
    if okClass then rec.class = cn end
    local okName, nm = pcall(function() return inst.Name end)
    if okName then rec.name = nm end
    local okVis, vis = pcall(function() return inst.Visible end)
    if okVis and type(vis) == "boolean" then rec.Visible = vis end
    local okText, txt = pcall(function() return inst.Text end)
    if okText and type(txt) == "string" then rec.Text = txt end

    elements[count] = rec
  end
end

return { count = count, truncated = truncated, elements = elements }
`;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:2e4})}}});import{z as Tr}from"zod";var wl=u({name:"press-key",title:"Simulate a keyboard key press",description:"WRITES LIVE GAME STATE. Simulate a real keyboard key press/release in the running client via VirtualInputManager, so anything listening for keyboard input runs: UserInputService.InputBegan/InputEnded, ContextActionService bindings, default movement, and keybound abilities. The key string is resolved against Enum.KeyCode (e.g. 'E', 'Space', 'W', 'LeftShift', 'F'); an unknown name returns a clean error listing what you passed. Sends KeyDown immediately, optionally holds for holdSec seconds (via task.wait) to emulate a held key, then sends KeyUp. NOTE: VirtualInputManager:SendKeyEvent only works from an exploit/elevated context (injected executor thread) \u2014 in an ordinary game script it is locked and will error. Getting the service and each SendKeyEvent are pcall-guarded. WARNING: this drives real input into the game and may move the character or trigger abilities. Returns { key, ok, error? }.",category:"GUI",mutatesState:!0,input:Tr.object({key:Tr.string().describe("The Enum.KeyCode name to press, e.g. 'E', 'Space', 'W', 'A', 'S', 'D', 'LeftShift', 'F', 'Return', 'One'. Case-sensitive and must match an Enum.KeyCode member exactly. Resolved as Enum.KeyCode[key]."),holdSec:Tr.number().describe("How long (seconds) to hold the key down before releasing it. Default 0 = a quick tap (KeyDown then immediate KeyUp). Use a small positive value (e.g. 0.5) to emulate a held key for charge/hold mechanics. Capped at 10 seconds to avoid blocking the executor thread.").optional().default(0),threadContext:Tr.number().int().optional()}),async execute({key:e,holdSec:t,threadContext:n},r){let a=Math.min(Math.max(Number.isFinite(t)?t:0,0),10),o=`
${k}
local keyName = ${s(e)}

local okKc, kc = pcall(function() return Enum.KeyCode[keyName] end)
if not okKc or typeof(kc) ~= "EnumItem" then
  return { key = keyName, ok = false, error = "unknown KeyCode '" .. keyName .. "' (must be an exact Enum.KeyCode member name, e.g. 'E', 'Space', 'LeftShift')." }
end

local okSvc, vim = pcall(function() return game:GetService("VirtualInputManager") end)
if not okSvc or typeof(vim) ~= "Instance" then
  return { key = keyName, ok = false, error = "could not get VirtualInputManager: " .. tostring(vim) }
end

local function invokeNative(fn)
  if type(newcclosure) == "function" then
    local okWrap, wrapped = pcall(newcclosure, fn)
    if okWrap and type(wrapped) == "function" then fn = wrapped end
  end
  return pcall(fn)
end

local okDown, downErr = invokeNative(function() vim:SendKeyEvent(true, kc, false, game) end)
if not okDown then
  return { key = keyName, ok = false, error = "SendKeyEvent (down) failed (VirtualInputManager requires an exploit/elevated context): " .. tostring(downErr) }
end

if ${a} > 0 and type(task) == "table" and type(task.wait) == "function" then
  pcall(task.wait, ${a})
end

local okUp, upErr = invokeNative(function() vim:SendKeyEvent(false, kc, false, game) end)
if not okUp then
  return { key = keyName, ok = false, error = "SendKeyEvent (up) failed; key may be stuck down: " .. tostring(upErr) }
end

return { key = keyName, ok = true }
`;return{data:await r.runLuau(o,{threadContext:n,timeoutMs:2e4})}}});import{z as W}from"zod";var Ad=["keyDown","keyUp","keyPress","mouseMove","mouseButton","mouseWheel","touch","gamepadButton","gamepadAxis"],Sl=u({name:"virtual-input",title:"Send a low-level virtual input event",description:"WRITES LIVE GAME STATE. Send keyboard, mouse, touch, or gamepad input into the active Roblox client. This is the broad low-level input surface: keyDown/keyUp/keyPress use Enum.KeyCode, mouseMove supports absolute or relative movement, mouseButton supports down/up/click, mouseWheel sends a wheel delta, touch sends Begin/Change/End, and gamepadButton/gamepadAxis target a gamepad. VirtualInputManager is preferred; common executor mouse/key fallbacks are used when available. Calls into VirtualInputManager are wrapped with newcclosure when the executor provides it. Unsupported executor APIs return a structured error rather than silently claiming success. Use press-key for the simpler keyboard-only case.",category:"GUI",mutatesState:!0,input:W.object({action:W.enum(Ad).describe("The virtual input operation to perform."),key:W.string().optional().describe("Exact Enum.KeyCode member name for keyDown, keyUp, or keyPress, such as W, Space, or LeftShift."),x:W.number().finite().optional().describe("Screen X coordinate, or horizontal relative delta for mouseMove."),y:W.number().finite().optional().describe("Screen Y coordinate, or vertical relative delta for mouseMove."),relative:W.boolean().optional().default(!1).describe("For mouseMove, use executor relative movement when true; otherwise use absolute screen coordinates."),button:W.enum(["Left","Right","Middle"]).optional().default("Left").describe("Mouse button for mouseButton."),buttonAction:W.enum(["down","up","click"]).optional().default("click").describe("Whether mouseButton sends down, up, or a down/up click."),delta:W.number().finite().optional().default(0).describe("Wheel delta for mouseWheel."),holdSec:W.number().finite().nonnegative().optional().default(0).describe("Seconds to hold keyPress or a mouse click between down and up, capped at 10 seconds."),touchId:W.number().int().nonnegative().optional().default(0).describe("Touch identifier for touch."),touchState:W.enum(["Begin","Change","End"]).optional().default("Begin").describe("Touch phase."),gamepad:W.enum(["Gamepad1","Gamepad2","Gamepad3","Gamepad4"]).optional().default("Gamepad1").describe("Gamepad input device."),gamepadButton:W.string().optional().describe("Exact Enum.KeyCode member name for a gamepad button, such as ButtonA or ButtonStart."),gamepadDown:W.boolean().optional().default(!0).describe("Pressed state for gamepadButton."),axis:W.string().optional().describe("Exact Enum.KeyCode member name for a gamepad axis, such as Thumbstick1 or ButtonL2."),axisX:W.number().finite().optional().default(0).describe("Gamepad axis X/value component."),axisY:W.number().finite().optional().default(0).describe("Gamepad axis Y/value component."),axisZ:W.number().finite().optional().default(0).describe("Gamepad axis Z/value component."),threadContext:W.number().int().optional()}),async execute({action:e,key:t,x:n,y:r,relative:a,button:o,buttonAction:i,delta:l,holdSec:c,touchId:d,touchState:p,gamepad:f,gamepadButton:h,gamepadDown:g,axis:b,axisX:m,axisY:y,axisZ:w,threadContext:C},I){let N=Math.min(c,10),O=`
local action = ${s(e)}
local keyName = ${s(t??"")}
local x = ${n===void 0?"nil":String(n)}
local y = ${r===void 0?"nil":String(r)}
local relative = ${a?"true":"false"}
local buttonName = ${s(o)}
local buttonAction = ${s(i)}
local delta = ${String(l)}
local holdSec = ${String(N)}
local touchId = ${String(d)}
local touchStateName = ${s(p)}
local gamepadName = ${s(f)}
local gamepadButtonName = ${s(h??"")}
local gamepadDown = ${g?"true":"false"}
local axisName = ${s(b??"")}
local axisX = ${String(m)}
local axisY = ${String(y)}
local axisZ = ${String(w)}

local function waitFor(seconds)
  if seconds > 0 and type(task) == "table" and type(task.wait) == "function" then
    pcall(task.wait, seconds)
  end
end

-- Some executors reject calls originating from a normal Lua closure. Wrap the
-- actual native call in newcclosure when available, while keeping a portable
-- identity fallback for executors that do not expose it.
local function invokeNative(fn)
  local callable = fn
  if type(newcclosure) == "function" then
    local okWrap, wrapped = pcall(newcclosure, fn)
    if okWrap and type(wrapped) == "function" then callable = wrapped end
  end
  return pcall(callable)
end

local okService, vim = pcall(function() return game:GetService("VirtualInputManager") end)
if not okService or typeof(vim) ~= "Instance" then vim = nil end

local function enumItem(enumType, name)
  local ok, item = pcall(function() return enumType[name] end)
  if not ok or typeof(item) ~= "EnumItem" then return nil end
  return item
end

local function fail(message)
  return { ok = false, action = action, error = message }
end

local function sendKey(isDown)
  local keyCode = enumItem(Enum.KeyCode, keyName)
  if not keyCode then return false, "unknown Enum.KeyCode '" .. keyName .. "'" end
  if vim then
    local ok, err = invokeNative(function() vim:SendKeyEvent(isDown, keyCode, false, game) end)
    if ok then return true end
    return false, "VirtualInputManager:SendKeyEvent failed: " .. tostring(err)
  end
  if #keyName == 1 and type(keypress) == "function" and type(keyrelease) == "function" then
    local byte = string.byte(keyName:upper())
    local ok, err = invokeNative(function()
      if isDown then keypress(byte) else keyrelease(byte) end
    end)
    if ok then return true end
    return false, "keypress/keyrelease failed: " .. tostring(err)
  end
  return false, "VirtualInputManager is unavailable and no compatible key fallback exists"
end

local mouseButtonId = { Left = 0, Right = 1, Middle = 2 }
local function sendMouseButton(isDown)
  if x == nil or y == nil then return false, "mouseButton requires x and y" end
  local id = mouseButtonId[buttonName]
  if id == nil then return false, "unknown mouse button '" .. buttonName .. "'" end
  if vim then
    local ok, err = invokeNative(function() vim:SendMouseButtonEvent(x, y, id, isDown, game, 0) end)
    if ok then return true end
    return false, "VirtualInputManager:SendMouseButtonEvent failed: " .. tostring(err)
  end
  local fallback = ({ Left = isDown and mouse1press or mouse1release, Right = isDown and mouse2press or mouse2release, Middle = isDown and mouse3press or mouse3release })
  if type(fallback) == "function" then
    local ok, err = invokeNative(fallback)
    if ok then return true end
    return false, "mouse button fallback failed: " .. tostring(err)
  end
  return false, "VirtualInputManager is unavailable and no compatible mouse-button fallback exists"
end

if action == "keyDown" or action == "keyUp" then
  local ok, err = sendKey(action == "keyDown")
  if not ok then return fail(err) end
elseif action == "keyPress" then
  local ok, err = sendKey(true)
  if not ok then return fail(err) end
  waitFor(holdSec)
  ok, err = sendKey(false)
  if not ok then return fail(err .. " (key may be stuck down)") end
elseif action == "mouseMove" then
  if x == nil or y == nil then return fail("mouseMove requires x and y") end
  local ok, err
  if relative and type(mousemoverel) == "function" then
    ok, err = invokeNative(function() mousemoverel(x, y) end)
  elseif not relative and type(mousemoveabs) == "function" then
    ok, err = invokeNative(function() mousemoveabs(x, y) end)
  elseif vim and not relative then
    ok, err = invokeNative(function() vim:SendMouseMoveEvent(x, y, game) end)
  else
    return fail(relative and "relative mouse movement requires mousemoverel in this executor" or "VirtualInputManager is unavailable and no absolute mouse fallback exists")
  end
  if not ok then return fail("mouse movement failed: " .. tostring(err)) end
elseif action == "mouseButton" then
  if buttonAction == "down" or buttonAction == "click" then
    local ok, err = sendMouseButton(true)
    if not ok then return fail(err) end
  end
  if buttonAction == "click" then waitFor(holdSec) end
  if buttonAction == "up" or buttonAction == "click" then
    local ok, err = sendMouseButton(false)
    if not ok then return fail(err .. " (mouse button may be stuck down)") end
  end
elseif action == "mouseWheel" then
  if x == nil or y == nil then return fail("mouseWheel requires x and y") end
  if not vim then return fail("mouseWheel requires VirtualInputManager in this executor") end
  local ok, err = invokeNative(function() vim:SendMouseWheelEvent(x, y, delta, game) end)
  if not ok then return fail("VirtualInputManager:SendMouseWheelEvent failed: " .. tostring(err)) end
elseif action == "touch" then
  if x == nil or y == nil then return fail("touch requires x and y") end
  if not vim then return fail("touch requires VirtualInputManager in this executor") end
  local state = enumItem(Enum.UserInputState, touchStateName)
  if not state then return fail("unknown Enum.UserInputState '" .. touchStateName .. "'") end
  local ok, err = invokeNative(function() vim:SendTouchEvent(touchId, state, x, y, game) end)
  if not ok then return fail("VirtualInputManager:SendTouchEvent failed: " .. tostring(err)) end
elseif action == "gamepadButton" then
  if gamepadButtonName == "" then return fail("gamepadButton requires gamepadButton") end
  if not vim then return fail("gamepadButton requires VirtualInputManager in this executor") end
  local inputType = enumItem(Enum.UserInputType, gamepadName)
  local keyCode = enumItem(Enum.KeyCode, gamepadButtonName)
  if not inputType then return fail("unknown Enum.UserInputType '" .. gamepadName .. "'") end
  if not keyCode then return fail("unknown Enum.KeyCode '" .. gamepadButtonName .. "'") end
  local ok, err = invokeNative(function() vim:SendGamepadButtonEvent(inputType, keyCode, gamepadDown, game) end)
  if not ok then return fail("VirtualInputManager:SendGamepadButtonEvent failed: " .. tostring(err)) end
elseif action == "gamepadAxis" then
  if axis == nil or axis == "" then return fail("gamepadAxis requires axis") end
  if not vim then return fail("gamepadAxis requires VirtualInputManager in this executor") end
  local inputType = enumItem(Enum.UserInputType, gamepadName)
  local keyCode = enumItem(Enum.KeyCode, axisName)
  if not inputType then return fail("unknown Enum.UserInputType '" .. gamepadName .. "'") end
  if not keyCode then return fail("unknown Enum.KeyCode '" .. axisName .. "'") end
  local ok, err = invokeNative(function() vim:SendGamepadAxisEvent(inputType, keyCode, axisX, axisY, axisZ, game) end)
  if not ok then return fail("VirtualInputManager:SendGamepadAxisEvent failed: " .. tostring(err)) end
end

return { ok = true, action = action, usedVirtualInputManager = vim ~= nil, usedNewcclosure = type(newcclosure) == "function" }
`;return{data:await I.runLuau(O,{threadContext:C,timeoutMs:2e4})}}});import{z as nt}from"zod";var El=u({name:"batch-execute",title:"Run many Luau snippets in order in one call",description:"Run several independent Luau snippets in sequence in a single round trip, collecting every result without paying a separate tool call per snippet. Each snippet is COMPILED with loadstring and run under its own pcall, in input order; a compile or runtime error in one snippet is recorded for that snippet only and never aborts the others. For each snippet you get { index, ok, value? , error? } \u2014 `value` is the FIRST return value, encoded so Instances/Vector3/etc. survive serialization; `error` carries the compile or runtime message when ok is false. Use this to read several instances, probe multiple remotes, or run a short script of steps in one shot. Requires loadstring (guarded). Returns { results = [{ index, ok, value?, error? }] } in input order.",category:"Execution",mutatesState:!0,input:nt.object({snippets:nt.array(nt.string()).min(1).describe("The Luau snippets to run, in order. Each is compiled and pcall-guarded independently; to capture a value, `return` it (only the first return value is collected)."),client:nt.string().min(1).optional().describe("Optional. Run on a specific connected client \u2014 its clientId OR username \u2014 for THIS call only, overriding your session's select-client binding without changing it. Lets multiple agents drive different games at the same time; omit to use your session's selected client."),agent:nt.string().min(1).optional().describe("Optional. A stable label for WHICH agent is calling when several share this MCP session (e.g. 'researcher'). Gives that agent its own fair scheduling lane, its own persistent VM on each game, and its own queue budget, so co-tenant agents don't starve or clobber each other."),threadContext:nt.number().int().optional(),timeoutMs:nt.number().int().positive().optional()}),async execute({snippets:e,threadContext:t,timeoutMs:n},r){let a=e.map((l,c)=>`__snippets[${c+1}] = ${s(l)}`).join(`
`),o=`
${_e}
if type(loadstring) ~= "function" then return { error = "loadstring is not available in this executor." } end

local __snippets = {}
${a}

local __results = {}
for __i = 1, #__snippets do
  local __src = __snippets[__i]
  local __fn, __cerr = loadstring(__src, "=batch-execute[" .. tostring(__i) .. "]")
  if not __fn then
    __results[__i] = { index = __i, ok = false, error = "compile error: " .. tostring(__cerr) }
  else
    local __packed = table.pack(pcall(__fn))
    if __packed[1] then
      local __okEnc, __enc = pcall(__encode, __packed[2])
      __results[__i] = { index = __i, ok = true, value = __okEnc and __enc or nil }
    else
      __results[__i] = { index = __i, ok = false, error = "runtime error: " .. tostring(__packed[2]) }
    end
  end
end

return { results = __results }
`;return{data:await r.runLuau(o,{threadContext:t,timeoutMs:n})}}});import{z as Cl}from"zod";var Il=u({name:"eval-expression",title:"Evaluate a single Luau expression",description:"Evaluate ONE Luau expression on the active client and return its typeof plus an encoded value. Convenience wrapper over run-luau for quick reads like 'workspace.Gravity', '#game.Players:GetPlayers()', or 'game.PlaceId'. The expression is pcall-guarded, so a runtime error is reported as { ok = false, error } instead of failing the call. Pass an expression, not statements (no 'return', no ';'). Note: this is PURE Luau \u2014 to compose with other server tools (e.g. `mcp.getPlayers()`, `mcp.searchInstances({...})`) use the `script` tool instead.",category:"Execution",input:Cl.object({expression:Cl.string().min(1).describe("A single Luau expression to evaluate (e.g. 'workspace.Gravity', 'game.PlaceId').")}),async execute({expression:e},t){let n=`
${_e}
local ok, value = pcall(function() return (${e}) end)
if not ok then
  return { ok = false, error = tostring(value) }
end
return { ok = true, type = typeof(value), value = __encode(value) }
`,r=await t.runLuau(n);return r?.ok===!1?{data:{error:r.error},summary:`Expression errored: ${r.error}`,isError:!0}:{data:{type:r?.type,value:r?.value},summary:r?.type?`=> ${r.type}`:void 0}}});import{z as Ra}from"zod";var Tl=u({name:"measure-memory",title:"Measure Lua heap growth caused by running a snippet",description:"Measure how much Lua heap memory a snippet allocates: read gcinfo() (the live Lua heap size in KB) immediately before running your code, run it once (compiled via loadstring, executed inside a pcall), then read gcinfo() again and report the delta. Use this to spot leaks or unexpectedly heavy allocations \u2014 e.g. confirm a function frees what it creates, see how big a table a constructor builds, or detect a snippet that balloons the heap. Caveats: gcinfo reports the WHOLE Lua heap, so concurrent game activity and garbage collection between the two samples add noise; a negative deltaKB means a GC cycle ran (it does NOT mean your code freed memory). For a cleaner reading, allocate enough to dwarf the noise or run a tight loop inside `code`. A compile error or a runtime error is reported in `error` with ok=false (the before/after samples are still returned). Requires gcinfo and loadstring (both guarded). Returns { beforeKB, afterKB, deltaKB, ok, error? } or { error }.",category:"Execution",mutatesState:!0,input:Ra.object({code:Ra.string().describe("The Luau snippet to measure. Compiled with loadstring and run once between two gcinfo() samples. Whatever it returns is ignored; only the change in heap size is reported. Allocate enough (or loop) so the delta stands out above background GC noise."),threadContext:Ra.number().int().optional()}),async execute({code:e,threadContext:t},n){let r=`
if type(gcinfo) ~= "function" then return { error = "gcinfo is not available in this executor; cannot measure heap." } end
if type(loadstring) ~= "function" then return { error = "loadstring is not available in this executor." } end

local __okBefore, __before = pcall(gcinfo)
if not __okBefore or type(__before) ~= "number" then return { error = "gcinfo() did not return a number before run." } end

local __fn, __cerr = loadstring(${s(e)}, "=measure-memory")
if not __fn then
  return { beforeKB = __before, afterKB = __before, deltaKB = 0, ok = false, error = "compile error: " .. tostring(__cerr) }
end

local __ok, __err = pcall(__fn)

local __okAfter, __after = pcall(gcinfo)
if not __okAfter or type(__after) ~= "number" then __after = __before end

return {
  beforeKB = __before,
  afterKB = __after,
  deltaKB = __after - __before,
  ok = __ok == true,
  error = (not __ok) and ("runtime error: " .. tostring(__err)) or nil,
}
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}});import{z as Rl}from"zod";var Ml=u({name:"playbook-delete",title:"Delete a Saved Luau Playbook",description:"Remove a persisted playbook from ~/.executor-mcp/playbooks/. Returns { ok: true, removed: true } when the file was deleted, or { ok: true, removed: false } when it didn't exist. Does not touch any running scripts that loaded this playbook earlier.",category:"Execution",mutatesState:!0,requiresClient:!1,input:Rl.object({name:Rl.string().min(1).describe("Playbook name to delete.")}),async execute({name:e},t){let n=await t.playbooks.delete(e);return{data:{ok:!0,removed:n},summary:n?`Deleted playbook "${e}".`:`No playbook named "${e}".`}}});import{z as Ma}from"zod";var Ll=u({name:"playbook-list",title:"List Saved Luau Playbooks",description:"List every persisted playbook in ~/.executor-mcp/playbooks/, optionally filtered to one tag. Returns summary metadata only (name, description, tags, params, timestamps) \u2014 fetch the source via `playbook-run` or by reading the file. Newest-first by updatedAt.",category:"Execution",mutatesState:!1,requiresClient:!1,input:Ma.object({tag:Ma.string().optional().describe("Restrict to playbooks carrying this tag."),includeSource:Ma.boolean().optional().describe("When true, include the full Luau source per entry (default false: metadata only).")}),async execute({tag:e,includeSource:t},n){let r=await n.playbooks.list(e?{tag:e}:void 0);return{data:{total:r.length,playbooks:r.map(a=>({name:a.name,description:a.description??null,tags:a.tags??[],params:a.params??[],createdAt:a.createdAt??null,updatedAt:a.updatedAt??null,...t?{source:a.source}:{}}))}}}});import{z as Ae}from"zod";var Nd=/[A-Z]/g;function Pd(e){return e.includes("-")?e:e.replace(Nd,(t,n)=>n===0?t.toLowerCase():"-"+t.toLowerCase())}var Al=/\bmcp\.([a-zA-Z_][a-zA-Z0-9_]*)\s*\(/g,Nl=/\bmcp\.call\s*\(\s*["']([a-zA-Z_][a-zA-Z0-9_-]*)["']/g;function $d(e,t,n){if(Math.abs(e.length-t.length)>n)return n+1;let r=e.length,a=t.length;if(r===0)return a;if(a===0)return r;let o=new Array(a+1),i=new Array(a+1);for(let l=0;l<=a;l++)o[l]=l;for(let l=1;l<=r;l++){i[0]=l;let c=l;for(let d=1;d<=a;d++){let p=e.charCodeAt(l-1)===t.charCodeAt(d-1)?0:1,f=Math.min(i[d-1]+1,o[d]+1,o[d-1]+p);i[d]=f,f<c&&(c=f)}if(c>n)return n+1;[o,i]=[i,o]}return o[a]}function Pl(e,t,n=3){let r=Math.max(2,Math.floor(e.length/2)),a=[];for(let o of t){let i=$d(e,o,r);i<=r&&a.push({name:o,d:i})}return a.sort((o,i)=>o.d-i.d||o.name.localeCompare(i.name)),a.slice(0,n).map(o=>o.name)}function Ct(e,t){let n=new Set(t),r=[...n],a=new Map,o=0,i;for(Al.lastIndex=0;(i=Al.exec(e))!==null;){let l=i[1];if(["call","all","parallel","help"].includes(l))continue;o+=1;let c=Pd(l);if(n.has(c))continue;let d=`dot:${c}`,p=a.get(d);a.set(d,p?{...p,occurrences:p.occurrences+1}:{name:c,written:l,occurrences:1,suggestions:Pl(c,r)})}for(Nl.lastIndex=0;(i=Nl.exec(e))!==null;){o+=1;let l=i[1].toLowerCase();if(n.has(l))continue;let c=`call:${l}`,d=a.get(c);a.set(c,d?{...d,occurrences:d.occurrences+1}:{name:l,written:l,occurrences:1,suggestions:Pl(l,r)})}return{errors:[...a.values()],callCount:o}}var $l=u({name:"playbook-run",title:"Run a Saved Luau Playbook by Name",description:"Load a saved playbook from ~/.executor-mcp/playbooks/<name>.json, replace any ${param} placeholders with the values from `params`, then run through the same scripting surface as the `script` tool \u2014 `mcp.*` calls, `mcp.all()`, the persistent VM, per-script RPC budget, output capture, and pre-flight ALL apply identically. Returns `{ result, output }` or `{ error, output }` from the run.",category:"Execution",mutatesState:!0,input:Ae.object({name:Ae.string().min(1).describe("The saved playbook's name."),params:Ae.record(Ae.string(),Ae.string()).optional().describe("Key/value substitutions for ${param} placeholders in the source."),persistent:Ae.boolean().optional().describe("Use the persistent VM (default true). Same semantics as script.persistent."),timeoutMs:Ae.number().int().positive().optional(),rpcBudget:Ae.number().int().positive().max(1e4).optional(),threadContext:Ae.number().int().optional()}),async execute({name:e,params:t,persistent:n,timeoutMs:r,rpcBudget:a,threadContext:o},i){let l=await i.playbooks.get(e);if(!l)return{data:{error:`No playbook named "${e}".`},isError:!0};if(!i.scripting)return{data:{error:"The scripting bridge is not available on this server."},isError:!0};let c=l.source.replace(/\$\$|\$\{([^}]+)\}/g,(h,g)=>h==="$$"?"$":t&&Object.hasOwn(t,g)?String(t[g]):h),d=Ct(c,i.scripting.knownTools);if(d.errors.length>0)return{data:{error:"preflight: "+d.errors.length+" unknown mcp.* tool"+(d.errors.length===1?"":"s")+' in playbook "'+e+'" \u2014 fix the playbook source.',unknownTools:d.errors.map(h=>({name:h.name,writtenAs:h.written,occurrences:h.occurrences,didYouMean:h.suggestions}))},isError:!0};let{token:p,dispose:f}=i.scripting.mint(a!==void 0?{budget:a}:void 0);try{return{data:await i.runLuau(c,{timeoutMs:r??12e4,env:n===!1?"fresh":"vm",scriptToken:p,...o!==void 0?{threadContext:o}:{}})}}finally{f()}}});import{z as Ve}from"zod";var Fd=/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$/,Fl=u({name:"playbook-save",title:"Save a Named Reusable Luau Playbook",description:"Persist a named, optionally parameterized Luau snippet to ~/.executor-mcp/playbooks/<name>.json so it can be re-run later via `playbook-run`. Names must match /^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$/. The source is stored verbatim; ${param} placeholders are replaced at run-time by `playbook-run`. Use tags to group related playbooks (e.g. 'recon', 'farming'). Upserts on existing names.",category:"Execution",mutatesState:!1,requiresClient:!1,input:Ve.object({name:Ve.string().regex(Fd,"name must be 1\u201364 chars of letters/digits/_/-, starting with alphanumeric").describe("Filename-safe identifier (used as the JSON file basename)."),source:Ve.string().min(1).describe("The Luau source to save. Use ${param} placeholders for runtime substitution."),description:Ve.string().optional().describe("One-line summary of what this playbook does."),tags:Ve.array(Ve.string()).optional().describe("Free-form tags for grouping (e.g. ['recon','farming'])."),params:Ve.array(Ve.string()).optional().describe("Names of ${param} placeholders the source uses (for documentation + UI hints).")}),async execute(e,t){let n=await t.playbooks.save(e);return{data:{ok:!0,name:n.name,updatedAt:n.updatedAt,createdAt:n.createdAt},summary:`Saved playbook "${n.name}".`}}});import{z as Rr}from"zod";var Ol=u({name:"profile-code",title:"Time a Luau snippet over repeated runs (micro-benchmark)",description:"Micro-benchmark a Luau snippet by running it `runs` times and timing each run with os.clock(), returning the wall-clock statistics so you can measure how fast (or how variable) a piece of code is. Use this to compare two implementations, to find out how expensive a function call / loop / property access really is, or to confirm a fix actually made something faster. The code is COMPILED ONCE via loadstring (a syntax error is returned cleanly as { error } and nothing is run); then each of the `runs` invocations is timed individually inside its own pcall so a runtime error in one run is counted but does not abort the benchmark. Timing measures the run only \u2014 compile time is excluded. Note os.clock() resolution is coarse, so for very cheap snippets raise `runs` or wrap a loop inside your code. Requires loadstring and os.clock (both guarded). Returns { runs, totalMs, avgMs, minMs, maxMs, errorCount, firstError? } or { error }.",category:"Execution",mutatesState:!0,input:Rr.object({code:Rr.string().describe("The Luau snippet to benchmark. Compiled once with loadstring, then executed `runs` times. It may do anything (call a function, run a loop, read properties); any value it returns is ignored \u2014 only the elapsed time per run is measured. Wrap an inner loop here if a single execution is too cheap to time accurately."),runs:Rr.number().int().describe("How many times to execute the compiled snippet (default 1, clamped 1..100000). More runs give a more stable average for cheap code but take longer. Each run is timed and pcall-guarded independently.").optional().default(1),threadContext:Rr.number().int().optional()}),async execute({code:e,runs:t,threadContext:n},r){let a=Math.min(Math.max(Math.floor(t??1),1),1e5),o=`
if type(loadstring) ~= "function" then return { error = "loadstring is not available in this executor." } end
if type(os) ~= "table" or type(os.clock) ~= "function" then return { error = "os.clock is not available in this executor." } end

local __fn, __cerr = loadstring(${s(e)}, "=profile-code")
if not __fn then return { error = "compile error: " .. tostring(__cerr) } end

local __runs = ${a}
local __total = 0
local __min = nil
local __max = nil
local __errorCount = 0
local __firstError = nil

for __i = 1, __runs do
  local __t0 = os.clock()
  local __ok, __err = pcall(__fn)
  local __dt = os.clock() - __t0
  if __dt < 0 then __dt = 0 end
  __total = __total + __dt
  if __min == nil or __dt < __min then __min = __dt end
  if __max == nil or __dt > __max then __max = __dt end
  if not __ok then
    __errorCount = __errorCount + 1
    if __firstError == nil then __firstError = tostring(__err) end
  end
end

local __toMs = function(s) return s * 1000 end
return {
  runs = __runs,
  totalMs = __toMs(__total),
  avgMs = __toMs(__total / __runs),
  minMs = __toMs(__min or 0),
  maxMs = __toMs(__max or 0),
  errorCount = __errorCount,
  firstError = __firstError,
}
`;return{data:await r.runLuau(o,{threadContext:n,timeoutMs:2e4})}}});import{z as Pn}from"zod";var ql=u({name:"run-deferred",title:"Schedule a Luau snippet to run in the background (fire-and-forget)",description:`Schedule a Luau snippet to run on its OWN thread and return immediately WITHOUT waiting for it to finish. Use this to start something that runs in the background while you keep issuing other tool calls \u2014 e.g. kick off a long watcher loop, an auto-farm, a background poller, or any snippet you want to run later or off the current thread so it cannot block the round trip. The code is COMPILED FIRST via loadstring; a syntax error is returned cleanly as { error } and nothing is scheduled. On success the compiled function is handed to the chosen scheduler and the tool returns at once.

Modes (Luau task library):
  - 'spawn'  -> task.spawn(fn): start running on a fresh thread immediately.
  - 'defer'  -> task.defer(fn): run on a fresh thread at the end of the current resumption cycle.
  - 'delay'  -> task.delay(delaySec, fn): run on a fresh thread after delaySec seconds.

IMPORTANT: because this does not wait, you will NOT see the snippet's return value, errors, or print output here \u2014 the scheduled thread runs independently and any error inside it is swallowed by task. If the snippet installs state or a loop, YOU are responsible for stopping it (e.g. have it watch a getgenv() flag). Requires loadstring and the task library (both guarded). Returns { scheduled = true, mode, delaySec? } or { error }.`,category:"Execution",mutatesState:!0,input:Pn.object({code:Pn.string().describe("The Luau snippet to run in the background. Compiled with loadstring, then scheduled on its own thread. Since nothing is awaited, build in your own stop condition for long loops (e.g. `while getgenv().__myFlag do ... task.wait() end`) so you can shut it down later."),mode:Pn.enum(["spawn","defer","delay"]).describe("How to schedule the thread: 'spawn' starts it immediately on a new thread; 'defer' runs it at the end of the current resumption cycle; 'delay' runs it after `delaySec` seconds. Default 'spawn'.").optional().default("spawn"),delaySec:Pn.number().describe("Seconds to wait before the snippet runs. Only used when mode='delay' (ignored for spawn/defer). Default 0.").optional().default(0),threadContext:Pn.number().int().optional()}),async execute({code:e,mode:t,delaySec:n,threadContext:r},a){let o=t??"spawn",i=Math.max(n??0,0),l=`
if type(loadstring) ~= "function" then return { error = "loadstring is not available in this executor." } end
if type(task) ~= "table" then return { error = "the task library is not available in this executor." } end

local __fn, __cerr = loadstring(${s(e)}, "=run-deferred")
if not __fn then return { error = "compile error: " .. tostring(__cerr) } end

-- Wrap so a runtime error inside the background thread can never bubble up and
-- destabilize the scheduler; the snippet runs detached and unobserved.
local __wrapped = function() pcall(__fn) end

local __mode = ${s(o)}
local __delay = ${i}
local __scheduled = false

if __mode == "spawn" then
  if type(task.spawn) ~= "function" then return { error = "task.spawn is not available in this executor." } end
  local __ok, __err = pcall(task.spawn, __wrapped)
  if not __ok then return { error = "task.spawn failed: " .. tostring(__err) } end
  __scheduled = true
elseif __mode == "defer" then
  if type(task.defer) ~= "function" then return { error = "task.defer is not available in this executor." } end
  local __ok, __err = pcall(task.defer, __wrapped)
  if not __ok then return { error = "task.defer failed: " .. tostring(__err) } end
  __scheduled = true
elseif __mode == "delay" then
  if type(task.delay) ~= "function" then return { error = "task.delay is not available in this executor." } end
  local __ok, __err = pcall(task.delay, __delay, __wrapped)
  if not __ok then return { error = "task.delay failed: " .. tostring(__err) } end
  __scheduled = true
else
  return { error = "unknown mode: " .. tostring(__mode) }
end

return { scheduled = __scheduled, mode = __mode, delaySec = (__mode == "delay") and __delay or nil }
`;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:2e4})}}});import{z as It}from"zod";var Gl=u({name:"run-loop",title:"Run a Luau snippet repeatedly with a delay, collecting results",description:"Run a Luau snippet `iterations` times in a single round trip, waiting `delayMs` between iterations, and collect what each run produced. Use this to poll a value over time (e.g. read a Humanoid's Health every 200ms for 20 iterations to watch it change), to retry a flaky operation, or to drive a short repeated action and see the outcome of each pass \u2014 all without paying a tool round trip per iteration. The code is COMPILED ONCE (a syntax error returns { error } and nothing runs); each iteration is executed inside its own pcall so a runtime error in one pass is recorded and the loop continues. When collectReturns is true the FIRST return value of each run is captured via __encVal (Instances become their full path, tables/functions become a stable string), giving an ordered series you can compare across iterations. The whole loop runs synchronously in-client, so total time is roughly iterations * delayMs \u2014 keep that under the tool timeout. Requires loadstring; uses task.wait for the delay (falls back to wait). Returns { iterations, results, errorCount, errors } or { error }.",category:"Execution",mutatesState:!0,input:It.object({code:It.string().describe("The Luau snippet to run each iteration. Compiled once, then executed every pass. To capture a value per iteration, `return` it (only the first return value is collected when collectReturns is true)."),iterations:It.number().int().describe("How many times to run the snippet (default 5, clamped 1..1000). Combined with delayMs this determines total wall-clock time, so keep iterations * delayMs comfortably under the request timeout.").optional().default(5),delayMs:It.number().describe("Milliseconds to wait between iterations via task.wait (default 0 = yield minimally each pass). Use e.g. 200 to sample a value five times a second. There is no wait after the final iteration.").optional().default(0),collectReturns:It.boolean().describe("When true (default), capture the FIRST return value of each iteration into `results` (encoded as a serializable scalar/string). Set false to skip capture when the snippet returns nothing useful or large values you do not want echoed back.").optional().default(!0),threadContext:It.number().int().optional()}),async execute({code:e,iterations:t,delayMs:n,collectReturns:r,threadContext:a},o){let i=Math.min(Math.max(Math.floor(t??5),1),1e3),l=(Math.max(n??0,0)/1e3).toFixed(6),c=r!==!1,d=`
${k}
if type(loadstring) ~= "function" then return { error = "loadstring is not available in this executor." } end

local __fn, __cerr = loadstring(${s(e)}, "=run-loop")
if not __fn then return { error = "compile error: " .. tostring(__cerr) } end

local __waiter = (type(task) == "table" and type(task.wait) == "function") and task.wait or wait
local __iters = ${i}
local __delay = ${l}
local __collect = ${c?"true":"false"}
local __results = {}
local __errors = {}
local __errorCount = 0

for __i = 1, __iters do
  local __packed = table.pack(pcall(__fn))
  local __ok = __packed[1]
  if __ok then
    if __collect then
      local __v = __packed[2]
      local __okEnc, __enc = pcall(__encVal, __v)
      if __okEnc then __results[__i] = __enc else __results[__i] = "nil" end
    end
  else
    __errorCount = __errorCount + 1
    __errors[__i] = tostring(__packed[2])
    if __collect then __results[__i] = "nil" end
  end
  if __i < __iters and __delay >= 0 and type(__waiter) == "function" then
    pcall(__waiter, __delay)
  end
end

return {
  iterations = __iters,
  results = __results,
  errorCount = __errorCount,
  errors = __errors,
}
`,p=12e4,f=i*Math.max(n??0,0)+8e3;if(f>p)return{data:{error:`Estimated worst-case in-game time (~${Math.round(f/1e3)}s for ${i} iterations at ${Math.max(n??0,0)}ms each) exceeds the ${p/1e3}s connector ceiling. Lower iterations or delayMs so iterations*delayMs stays under ~112000ms.`},isError:!0};let h=Math.min(Math.max(f,2e4),p);return{data:await o.runLuau(d,{threadContext:a,timeoutMs:h})}}});import{z as Mr}from"zod";var Dl=u({name:"run-with-timeout",title:"Run a Luau snippet with a watchdog timeout",description:"Run a Luau snippet under a WATCHDOG: it executes on its own thread and this tool polls a done flag against an os.clock() deadline, so a snippet that hangs on a YIELD (a yield that never resumes, a :Wait() on a signal that never fires) cannot block the round trip forever \u2014 after timeoutSec you get a clean { timedOut = true } instead of waiting out the whole connector timeout. Use this any time you are about to run code that MIGHT hang or take an unknown amount of time. The snippet is COMPILED FIRST via loadstring (a syntax error returns { error } and nothing runs), then started with task.spawn; the watchdog waits with task.wait until either the thread sets its done flag or the deadline passes.\n\nLIMITATION: Luau is cooperatively scheduled, so the watchdog can only fire when the snippet YIELDS. A snippet that never yields (e.g. `while true do end` or a tight CPU loop with no task.wait) runs synchronously inside task.spawn, so the watchdog loop never gets to run and the round trip still blocks until the connector timeout. Put a task.wait() inside long loops if you want the watchdog to be able to interrupt them.\n\nIMPORTANT: a timeout REPORTS that the snippet did not finish in time, but it does NOT kill the runaway thread \u2014 the executor keeps running it in the background (and it may keep consuming CPU). Prefer snippets that can finish, and keep timeoutSec sane. If the snippet completes in time, its FIRST return value is encoded via __encVal and returned; a runtime error inside it is captured in `error`. Requires loadstring, the task library, and os.clock (all guarded). Returns { completed, timedOut, elapsedMs, result?, error? } or { error }.",category:"Execution",mutatesState:!0,input:Mr.object({code:Mr.string().describe("The Luau snippet to run under the watchdog. Compiled with loadstring and run on its own thread. To report a value back, `return` it (only the first return value is captured, encoded as a serializable scalar/string)."),timeoutSec:Mr.number().describe("How long to let the snippet run before giving up and reporting timedOut, in seconds (default 5, clamped 0.1..60). On timeout the snippet is NOT killed \u2014 it keeps running in the background; this only stops THIS tool from waiting.").optional().default(5),threadContext:Mr.number().int().optional()}),async execute({code:e,timeoutSec:t,threadContext:n},r){let a=Math.min(Math.max(t??5,.1),60),o=a.toFixed(6),i=`
${k}
if type(loadstring) ~= "function" then return { error = "loadstring is not available in this executor." } end
if type(task) ~= "table" or type(task.spawn) ~= "function" or type(task.wait) ~= "function" then
  return { error = "the task library (task.spawn/task.wait) is not available in this executor." }
end
if type(os) ~= "table" or type(os.clock) ~= "function" then return { error = "os.clock is not available in this executor." } end

local __fn, __cerr = loadstring(${s(e)}, "=run-with-timeout")
if not __fn then return { error = "compile error: " .. tostring(__cerr) } end

local __state = { done = false, ok = nil, value = nil, err = nil }

task.spawn(function()
  local __packed = table.pack(pcall(__fn))
  __state.ok = __packed[1]
  if __packed[1] then
    __state.value = __packed[2]
  else
    __state.err = tostring(__packed[2])
  end
  __state.done = true
end)

local __t0 = os.clock()
local __deadline = __t0 + ${o}
while (not __state.done) and (os.clock() < __deadline) do
  task.wait()
end
local __elapsedMs = (os.clock() - __t0) * 1000

if not __state.done then
  return { completed = false, timedOut = true, elapsedMs = __elapsedMs }
end

if __state.ok then
  local __okEnc, __enc = pcall(__encVal, __state.value)
  local __r
  if __okEnc then __r = __enc else __r = "nil" end
  return { completed = true, timedOut = false, elapsedMs = __elapsedMs, result = __r }
else
  return { completed = true, timedOut = false, elapsedMs = __elapsedMs, error = "runtime error: " .. tostring(__state.err) }
end
`,l=Math.min(Math.ceil(a*1e3)+8e3,12e4);return{data:await r.runLuau(i,{threadContext:n,timeoutMs:l})}}});import{z as Ie}from"zod";var Ul=8,jl=u({name:"script-fanout",title:"Run a Luau script on N clients in parallel",description:"Run ONE Luau program across multiple connected clients in parallel and return per-client results. Targets are chosen by either passing `clients: ['<clientId>', ...]` (explicit ids from list-clients) or `clients: 'all'` (every connected client). Each client gets its own scriptToken / RPC budget, and the same `mcp.*` surface (including `mcp.all()`) is available inside. Concurrency is capped to "+Ul+" in flight so a 50-client fanout doesn't saturate the bridge. Returns { results: [{ clientId, displayName, ok, result?, error?, output, durationMs }], summary: { total, ok, failed, totalMs } }. Pre-flight catches typo'd mcp.* calls before dispatch, so a typo doesn't fail N times.",category:"Execution",mutatesState:!0,requiresClient:!1,input:Ie.object({clients:Ie.union([Ie.array(Ie.string()).min(1),Ie.literal("all")]).describe("Either an array of clientIds (from list-clients) or the string 'all'."),source:Ie.string().describe("The Luau script to run on every target client. Has the same `mcp.*` surface as the regular script tool."),persistent:Ie.boolean().optional().describe("Each client's persistent VM is independent (default true = use VM env)."),timeoutMs:Ie.number().int().positive().optional().describe("Per-client timeout in ms (default 60000)."),rpcBudget:Ie.number().int().positive().max(1e4).optional().describe("Per-client mcp.* RPC cap (default 500)."),threadContext:Ie.number().int().optional()}),async execute({clients:e,source:t,persistent:n,timeoutMs:r,rpcBudget:a,threadContext:o},i){if(!i.scripting)return{data:{error:"The scripting bridge is not available on this server."},isError:!0};let l=Ct(t,i.scripting.knownTools);if(l.errors.length>0)return{data:{error:"preflight: "+l.errors.length+" unknown mcp.* tool"+(l.errors.length===1?"":"s")+" \u2014 fix names before fanout.",unknownTools:l.errors.map(w=>({name:w.name,writtenAs:w.written,occurrences:w.occurrences,didYouMean:w.suggestions}))},isError:!0};let c=i.clients.list(),d=e==="all"?c.map(w=>w.id):e.map(w=>tr(w)),p=d.filter(w=>!c.some(C=>C.id===w));if(d.length===0)return{data:{results:[],summary:{total:0,ok:0,failed:0,totalMs:0}}};let f=Date.now(),h=async w=>{let C=i.clients.get(w),I=C?.displayName??C?.username??null,N=Date.now(),O=i.scripting,{token:q,dispose:S}=O.mint({clientId:w,...a!==void 0?{budget:a}:{}});try{let x=await i.runLuauOn(w,t,{timeoutMs:r??6e4,env:n===!1?"fresh":"vm",scriptToken:q,...o!==void 0?{threadContext:o}:{}});return{clientId:w,displayName:I,ok:!0,result:x,durationMs:Date.now()-N}}catch(x){let E=ni(x);return{clientId:w,displayName:I,ok:!1,error:E.message,durationMs:Date.now()-N}}finally{S()}},g=[],b=0,m=Array.from({length:Math.min(Ul,d.length)},async()=>{for(;b<d.length;){let w=b++,C=d[w];g[w]=await h(C)}});await Promise.all(m);let y=g.filter(w=>w.ok).length;return{data:{results:g,summary:{total:g.length,ok:y,failed:g.length-y,totalMs:Date.now()-f,...p.length?{unknownClients:p}:{}}}}}});import{z as Be}from"zod";var Wl=u({name:"script",title:"Run a Luau Script with the Whole Tool Surface (mcp.*) + Persistent VM",description:"Run a Luau program in the active Roblox client that can ALSO call any other tool inline through a live `mcp` table, and use the results in the same script \u2014 one call instead of dozens of round-trips. Inside the script: `game`, `workspace`, and all in-game globals are available, PLUS `mcp.<tool>(args)` invokes any of this server's tools and RETURNS its data. Tool names are camelCase of the tool id (e.g. `mcp.getPlayers()`, `mcp.searchInstances({ className = 'RemoteEvent' })`, `mcp.findFunctionsByName({ name = 'buy' })`), or use `mcp.call('kebab-tool-name', { ... })`. For N independent calls use `mcp.all({ players = { 'get-players' }, remotes = { 'search-instances', { className = 'RemoteEvent' } } })` \u2014 runs them all in parallel server-side with a single round-trip and returns a table keyed identically. `print`/`warn` are captured and returned as `output` (and still stream to the dashboard Output console). By default the script runs in a PERSISTENT VM: globals and functions you define survive across `script` calls (a REPL-like session) \u2014 set persistent:false for a clean one-shot, or call `vm-reset` to wipe the VM. Returns `{ result = <return value>, output = [lines] }` or `{ error, output }`. mcp.script is disabled (no recursion).",category:"Execution",mutatesState:!0,input:Be.object({source:Be.string().describe("The Luau script to run. Has `game`/`workspace`/all in-game globals, plus `mcp.<tool>(args)` to call any tool and use its returned data inline. `print`/`warn` are captured. `return <value>` to hand a value back."),client:Be.string().min(1).optional().describe("Optional. Run on a specific connected client \u2014 its clientId OR username \u2014 for THIS call only, overriding your session's select-client binding WITHOUT changing it. Lets multiple agents drive different games at the same time; omit to use your session's selected client."),agent:Be.string().min(1).optional().describe("Optional. A stable label for WHICH agent is calling when several share this MCP session (e.g. 'researcher'). Gives that agent its own fair scheduling lane, its own persistent VM on each game, and its own queue budget, so co-tenant agents don't starve or clobber each other."),persistent:Be.boolean().optional().describe("Run in the persistent VM so defined globals/functions survive across calls (default true). false = a fresh, isolated environment each run."),timeoutMs:Be.number().int().positive().optional().describe("Overall timeout for the whole script including nested tool calls (default 120000)."),rpcBudget:Be.number().int().positive().max(1e4).optional().describe("Max number of `mcp.*` tool calls this script can make through the bridge (default 500). Further calls reject with BUDGET_EXCEEDED so a runaway loop can't saturate the connection."),threadContext:Be.number().int().optional()}),async execute({source:e,persistent:t,timeoutMs:n,rpcBudget:r,threadContext:a},o){if(!o.scripting)return{data:{error:"The scripting bridge is not available on this server."},isError:!0};let i=Ct(e,o.scripting.knownTools);if(i.errors.length>0){let d=o.tools,p=f=>f.map(h=>{let g=d.find(h);return g?{name:h,signature:fe(g.input),title:g.title}:{name:h,signature:"{}",title:""}});return{data:{error:"preflight: "+i.errors.length+" unknown mcp.* tool"+(i.errors.length===1?"":"s")+" detected \u2014 fix the names and retry.",unknownTools:i.errors.map(f=>({name:f.name,writtenAs:f.written,occurrences:f.occurrences,didYouMean:p(f.suggestions)})),callsScanned:i.callCount,hint:"Tool names are kebab-case on the wire; mcp.getPlayers() resolves to get-players. Use mcp.help('tool-name') from inside the script to look up signatures, or call list-tools / tool-schema to discover them."},isError:!0}}let{token:l,dispose:c}=o.scripting.mint(r!==void 0?{budget:r}:void 0);try{return{data:await o.runLuau(e,{timeoutMs:n??12e4,env:t===!1?"fresh":"vm",scriptToken:l,...a!==void 0?{threadContext:a}:{}})}}finally{c()}}});import{z as La}from"zod";var Vl=u({name:"vm-reset",title:"Reset the Persistent Script VM",description:"Wipe the persistent VM environment used by the `script` tool. Every global, function, and value defined by previous persistent `script` runs is discarded, giving you a clean session. This does NOT touch the game itself \u2014 only the VM's own sandboxed environment. Wipes ONLY your own scope: pass the same `agent` label (and `client`) you run scripts under so it clears that agent's VM on that game, never a co-tenant's. Returns { reset = true }.",category:"Execution",mutatesState:!1,input:La.object({client:La.string().min(1).optional().describe("Optional. Reset the VM on a specific connected client (its clientId or username) for THIS call, instead of your session's selected client."),agent:La.string().min(1).optional().describe("Optional. Reset the persistent VM belonging to this agent lane \u2014 pass the SAME label you run your `script`/`execute` calls under, so you clear your own VM and not a co-tenant agent's.")}),async execute(e,t){return{data:await t.runLuau("",{env:"vm-reset",timeoutMs:1e4}),summary:"Persistent VM environment reset."}}});import{z as pe}from"zod";var Od=pe.object({scriptPath:pe.string().min(1).max(2048).optional().describe("Optional Luau expression resolving to the LocalScript or ModuleScript to audit."),functionPath:pe.string().min(1).max(4096).optional().describe("Optional Luau expression resolving to a function/closure to audit without invoking it."),includeSourceScan:pe.boolean().optional().default(!0).describe("Read and scan a bounded script.Source prefix when the property is accessible."),includeStackEnvironments:pe.boolean().optional().default(!0).describe("Inspect key names from a bounded number of the auditor's current getfenv stack frames."),maxStackFrames:pe.number().int().min(0).max(32).optional().default(8).describe("Maximum current auditor stack levels inspected with getfenv (0 disables stack probing)."),maxEvidence:pe.number().int().min(10).max(250).optional().default(100).describe("Hard cap for findings and source/constant evidence records."),maxEnvironmentKeys:pe.number().int().min(10).max(400).optional().default(120).describe("Maximum key names retained from each unique environment."),maxSourceChars:pe.number().int().min(1e3).max(2e5).optional().default(6e4).describe("Maximum script.Source characters scanned; the report says when this truncates."),maxConstants:pe.number().int().min(0).max(256).optional().default(96).describe("Maximum target-closure constants inspected internally."),maxUpvalues:pe.number().int().min(0).max(128).optional().default(64).describe("Maximum target-closure upvalues classified without returning captured values."),threadContext:pe.number().int().optional()});function Tt(e,t,n,r){return Math.max(n,Math.min(r,Math.trunc(e??t)))}var Bl=u({name:"execution-footprint-audit",title:"Audit script execution footprint and local detection exposure",description:"READ-ONLY, one-shot Luau auditor for local execution exposure. It resolves an optional script and/or closure without invoking it; inventories virtual-input globals and VirtualInputManager/VirtualUser references; distinguishes direct Instance references from cloneref-like alternate references when compareinstances exists; compares input functions with retained MCP closure handles; audits bounded getsenv/getfenv key-name leaks; classifies closure origin/hash/hook state; scans bounded source/constants for input, environment, debug, and hook indicators; and returns findings, unknown checks, confidence, risk score, privacy-safe evidence, and truncation telemetry. It never sends input, calls the target closure, walks getgc/descendants, installs hooks, or writes to game objects or script values. A clean result does NOT prove that server-side or external detection did not occur, and cloneref/clone matches are provenance only\u2014not an undetectability guarantee.",category:"Diagnostics",input:Od,async execute({scriptPath:e,functionPath:t,includeSourceScan:n,includeStackEnvironments:r,maxStackFrames:a,maxEvidence:o,maxEnvironmentKeys:i,maxSourceChars:l,maxConstants:c,maxUpvalues:d,threadContext:p},f){let h=Tt(a,8,0,32),g=Tt(o,100,10,250),b=Tt(i,120,10,400),m=Tt(l,6e4,1e3,2e5),y=Tt(c,96,0,256),w=Tt(d,64,0,128),C=n!==!1,I=r!==!1&&h>0,N=`
local CONFIG = {
  scriptExpression = ${s(e??"")},
  functionExpression = ${s(t??"")},
  includeSourceScan = ${C?"true":"false"},
  includeStackEnvironments = ${I?"true":"false"},
  maxStackFrames = ${h},
  maxEvidence = ${g},
  maxEnvironmentKeys = ${b},
  maxSourceChars = ${m},
  maxConstants = ${y},
  maxUpvalues = ${w},
  maxRetainedRefs = ${Math.min(b,160)},
  maxUnknownChecks = ${Math.min(g,100)},
}

local function now()
  local ok, value = pcall(function() return os.clock() end)
  return ok and type(value) == "number" and value or 0
end

local startedAt = now()
local report = {
  version = "1.0",
  kind = "execution-footprint-audit",
  disclaimer = "Local read-only exposure audit only; this cannot prove server-side or external detection.",
  assessment = {
    localExposureOnly = true,
    detectionProven = false,
    cleanReportGuaranteesUndetected = false,
    cloneOrClonerefGuaranteesSafety = false,
  },
  target = {
    scriptExpression = CONFIG.scriptExpression ~= "" and CONFIG.scriptExpression or nil,
    functionExpression = CONFIG.functionExpression ~= "" and CONFIG.functionExpression or nil,
    script = nil,
    explicitFunction = nil,
    selectedClosure = nil,
  },
  capabilities = {},
  virtualInput = {
    globals = {},
    services = {},
    targetReferences = {},
    retainedRegistry = { available = false, scanned = 0, truncated = false },
    note = "Reference matches are provenance only and never prove undetectability.",
  },
  environments = {
    targetScript = nil,
    targetFunction = nil,
    currentStack = {},
    uniqueCurrent = {},
    note = "getfenv stack entries describe this auditor's current stack, not an uninvoked target closure.",
  },
  closure = nil,
  sourceIndicators = {},
  findings = {},
  unknownChecks = {},
  notes = {
    "No target function is invoked.",
    "No virtual input is sent.",
    "No hook or persistent connection is installed.",
    "Environment and upvalue values are never serialized.",
  },
  telemetry = {
    oneLuauCall = true,
    noTargetInvocation = true,
    noInputSent = true,
    noHooksInstalled = true,
    noGcScan = true,
    noDescendantScan = true,
    getfenvUsed = false,
    scanned = {
      inputGlobals = 0,
      retainedRefs = 0,
      environmentKeys = 0,
      stackFrames = 0,
      sourceChars = 0,
      sourceLines = 0,
      constants = 0,
      upvalues = 0,
    },
    limits = {
      evidence = CONFIG.maxEvidence,
      environmentKeysPerEnvironment = CONFIG.maxEnvironmentKeys,
      stackFrames = CONFIG.maxStackFrames,
      sourceChars = CONFIG.maxSourceChars,
      constants = CONFIG.maxConstants,
      upvalues = CONFIG.maxUpvalues,
      retainedRefs = CONFIG.maxRetainedRefs,
    },
    truncation = {
      evidence = false,
      environments = false,
      source = false,
      constants = false,
      upvalues = false,
      retainedRefs = false,
      unknownChecks = false,
    },
  },
}

local riskPoints = 0
local confirmedFindingCount = 0
local heuristicFindingCount = 0
local findingKeys = {}
local unknownKeys = {}
local evidenceCount = 0
local sourceEvidenceLimit = math.max(1, math.floor(CONFIG.maxEvidence / 2))

local function text(value, limit)
  local ok, rendered = pcall(tostring, value)
  rendered = ok and rendered or "<unprintable>"
  limit = limit or 180
  if #rendered > limit then return string.sub(rendered, 1, limit) .. "\u2026" end
  return rendered
end

local function lower(value)
  return string.lower(text(value, 256))
end

local function sensitiveName(name)
  local value = lower(name)
  local terms = { "password", "passwd", "secret", "cookie", "authorization", "bearer", "access_token", "refresh_token", "api_key", "apikey", "private_key" }
  for _, term in ipairs(terms) do
    if string.find(value, term, 1, true) then return true end
  end
  return false
end

local function safeKeyName(name)
  if sensitiveName(name) then return "<redacted-sensitive-key-name>" end
  return text(name, 96)
end

local function redactSnippet(value)
  local snippet = text(value, 240)
  snippet = string.gsub(snippet, "https?://%S+", "<url:redacted>")
  snippet = string.gsub(snippet, '"(.-)"', '"<redacted:string>"')
  snippet = string.gsub(snippet, "'(.-)'", "'<redacted:string>'")
  return snippet
end

local function addUnknown(check, reason)
  local key = tostring(check)
  if unknownKeys[key] then return end
  if #report.unknownChecks >= CONFIG.maxUnknownChecks then
    report.telemetry.truncation.unknownChecks = true
    return
  end
  unknownKeys[key] = true
  report.unknownChecks[#report.unknownChecks + 1] = {
    check = text(check, 80),
    reason = text(reason, 220),
  }
end

local function addFinding(id, category, severity, confidence, confirmed, title, evidence, points)
  local key = tostring(id)
  if findingKeys[key] then return end
  if evidenceCount >= CONFIG.maxEvidence then
    report.telemetry.truncation.evidence = true
    return
  end
  findingKeys[key] = true
  report.findings[#report.findings + 1] = {
    id = key,
    category = category,
    severity = severity,
    confidence = confidence,
    confirmed = confirmed == true,
    title = text(title, 180),
    evidence = text(evidence, 300),
    points = math.max(0, math.floor(tonumber(points) or 0)),
  }
  evidenceCount = evidenceCount + 1
  riskPoints = riskPoints + math.max(0, math.floor(tonumber(points) or 0))
  if confirmed == true then confirmedFindingCount = confirmedFindingCount + 1 else heuristicFindingCount = heuristicFindingCount + 1 end
end

local function instanceInfo(value)
  if typeof(value) ~= "Instance" then return nil end
  local path = nil
  local okPath, fullPath = pcall(function() return value:GetFullName() end)
  if okPath then path = text(fullPath, 240) end
  local className = nil
  local okClass, classValue = pcall(function() return value.ClassName end)
  if okClass then className = text(classValue, 80) end
  return { className = className, path = path }
end

local hosts = {}
local genvEnvironment = nil
local renvEnvironment = nil
local function addHost(label, value)
  if type(value) ~= "table" then return end
  for _, host in ipairs(hosts) do if host.value == value then return end end
  hosts[#hosts + 1] = { label = label, value = value }
end

if type(getgenv) == "function" then
  local ok, value = pcall(getgenv)
  if ok and type(value) == "table" then genvEnvironment = value; addHost("getgenv", value) end
end
if type(getrenv) == "function" then
  local ok, value = pcall(getrenv)
  if ok and type(value) == "table" then renvEnvironment = value; addHost("getrenv", value) end
end
addHost("_G", _G)

local function resolveName(name)
  local parts = {}
  for part in string.gmatch(name, "[^%.]+") do parts[#parts + 1] = part end
  for _, host in ipairs(hosts) do
    local current = host.value
    local valid = true
    for _, part in ipairs(parts) do
      if type(current) ~= "table" then valid = false; break end
      local ok, nextValue = pcall(function() return current[part] end)
      if not ok then valid = false; break end
      current = nextValue
    end
    if valid and current ~= nil then return current, host.label end
  end
  if type(loadstring) == "function" then
    local okCompile, loader = pcall(loadstring, "return " .. name)
    if okCompile and type(loader) == "function" then
      local okValue, value = pcall(loader)
      if okValue and value ~= nil then return value, "loadstring" end
    end
  end
  return nil, nil
end

local function firstFunction(names)
  for _, name in ipairs(names) do
    local value, host = resolveName(name)
    if type(value) == "function" then return value, name, host end
  end
  return nil, nil, nil
end

local CAPABILITY_SPECS = {
  getgenv = { "getgenv" },
  getrenv = { "getrenv" },
  getfenv = { "getfenv" },
  getsenv = { "getsenv" },
  getcallingscript = { "getcallingscript" },
  getscriptclosure = { "getscriptclosure" },
  getscripthash = { "getscripthash" },
  cloneref = { "cloneref" },
  compareinstances = { "compareinstances" },
  getinfo = { "getinfo", "debug.getinfo", "debug.info" },
  getconstants = { "getconstants", "debug.getconstants" },
  getupvalues = { "getupvalues", "debug.getupvalues" },
  iscclosure = { "iscclosure" },
  islclosure = { "islclosure" },
  isexecutorclosure = { "isexecutorclosure", "checkclosure", "isourclosure" },
  isnewcclosure = { "isnewcclosure", "iscustomcclosure" },
  isfunctionhooked = { "isfunctionhooked" },
  getfunctionhash = { "getfunctionhash" },
  loadstring = { "loadstring" },
}

local F = {}
local capabilityNames = {}
for name in pairs(CAPABILITY_SPECS) do capabilityNames[#capabilityNames + 1] = name end
table.sort(capabilityNames)
for _, name in ipairs(capabilityNames) do
  local fn, alias, host = firstFunction(CAPABILITY_SPECS[name])
  F[name] = fn
  report.capabilities[name] = { available = type(fn) == "function", alias = alias, host = host }
end

local function safePredicate(fn, value)
  if type(fn) ~= "function" then return nil end
  local ok, result = pcall(fn, value)
  if not ok then return nil end
  return result == true
end

local function safeHash(fn)
  if type(F.getfunctionhash) ~= "function" or type(fn) ~= "function" then return nil end
  local ok, value = pcall(F.getfunctionhash, fn)
  return ok and value ~= nil and text(value, 160) or nil
end

local function functionInfo(fn)
  if type(fn) ~= "function" then return nil end
  local info = {
    pointer = text(fn, 100),
    isCClosure = safePredicate(F.iscclosure, fn),
    isLClosure = safePredicate(F.islclosure, fn),
    isExecutorClosure = safePredicate(F.isexecutorclosure, fn),
    isNewCClosure = safePredicate(F.isnewcclosure, fn),
    isFunctionHooked = safePredicate(F.isfunctionhooked, fn),
    hash = safeHash(fn),
  }
  if type(F.getinfo) == "function" then
    local ok, value = pcall(F.getinfo, fn, "nSlu")
    if ok and type(value) == "table" then
      info.name = text(value.name or "", 100)
      info.source = text(value.source or "", 220)
      info.shortSource = text(value.short_src or "", 160)
      info.lineDefined = tonumber(value.linedefined)
      info.lastLineDefined = tonumber(value.lastlinedefined)
      info.numberOfParameters = tonumber(value.nparams)
      info.numberOfUpvalues = tonumber(value.nups)
      info.isVararg = value.isvararg == true
    else
      local okSource, source = pcall(F.getinfo, fn, "s")
      if okSource and source ~= nil and type(source) ~= "table" then info.source = text(source, 220) end
      local okLine, line = pcall(F.getinfo, fn, "l")
      if okLine and type(line) == "number" then info.lineDefined = line end
      local okName, name = pcall(F.getinfo, fn, "n")
      if okName and name ~= nil and type(name) ~= "table" then info.name = text(name, 100) end
      local okArity, parameters, isVararg = pcall(F.getinfo, fn, "a")
      if okArity and type(parameters) == "number" then
        info.numberOfParameters = parameters
        info.isVararg = isVararg == true
      end
      if info.source == nil and info.lineDefined == nil and info.name == nil then
        addUnknown("closure-debug-info", "getinfo/debug.info exists but returned no usable metadata")
      end
    end
  else
    addUnknown("closure-debug-info", "getinfo/debug.getinfo unavailable")
  end
  return info
end

local function evaluateExpression(expression, expectedType)
  if expression == "" then return nil, "not requested" end
  if type(F.loadstring) ~= "function" then return nil, "loadstring unavailable" end
  local okCompile, loaderOrError = pcall(F.loadstring, "return " .. expression)
  if not okCompile or type(loaderOrError) ~= "function" then
    return nil, "expression compile failed: " .. text(loaderOrError, 180)
  end
  local okValue, value = pcall(loaderOrError)
  if not okValue then return nil, "expression evaluation failed: " .. text(value, 180) end
  if expectedType and typeof(value) ~= expectedType then
    return nil, "expression resolved to " .. typeof(value) .. ", expected " .. expectedType
  end
  return value, nil
end

local function sameInstanceKind(value, rawService)
  if typeof(value) ~= "Instance" or typeof(rawService) ~= "Instance" then return nil end
  if value == rawService then return "direct" end
  if type(F.compareinstances) == "function" then
    local ok, same = pcall(F.compareinstances, value, rawService)
    if ok and same == true then return "cloned-or-alternate" end
  end
  return nil
end

local services = {}
for _, serviceName in ipairs({ "VirtualInputManager", "VirtualUser", "UserInputService" }) do
  local ok, service = pcall(function() return game:GetService(serviceName) end)
  if ok and typeof(service) == "Instance" then
    services[serviceName] = service
    local info = instanceInfo(service) or {}
    info.name = serviceName
    info.available = true
    if serviceName == "UserInputService" then
      local okMember, member = pcall(function() return service.CreateVirtualInput end)
      info.createVirtualInputMemberAvailable = okMember and type(member) == "function"
    end
    report.virtualInput.services[#report.virtualInput.services + 1] = info
  else
    report.virtualInput.services[#report.virtualInput.services + 1] = { name = serviceName, available = false }
  end
end

if type(F.compareinstances) ~= "function" then
  addUnknown("cloneref-instance-provenance", "compareinstances unavailable; alternate Instance references cannot be distinguished reliably")
end

local retainedRegistry = nil
if type(F.getgenv) == "function" then
  local ok, genv = pcall(F.getgenv)
  if ok and type(genv) == "table" then
    local okRegistry, registry = pcall(function() return genv.__mcp_closure_refs end)
    if okRegistry and type(registry) == "table" then
      retainedRegistry = registry
      report.virtualInput.retainedRegistry.available = true
    end
  end
end

local retainedEntries = {}
if type(retainedRegistry) == "table" then
  local scanned = 0
  local okIter, iterError = pcall(function()
    for _, candidate in pairs(retainedRegistry) do
      if scanned >= CONFIG.maxRetainedRefs then
        report.telemetry.truncation.retainedRefs = true
        report.virtualInput.retainedRegistry.truncated = true
        break
      end
      scanned = scanned + 1
      if type(candidate) == "function" then
        retainedEntries[#retainedEntries + 1] = {
          fn = candidate,
          hash = safeHash(candidate),
          ordinal = scanned,
        }
      end
    end
  end)
  report.telemetry.scanned.retainedRefs = scanned
  report.virtualInput.retainedRegistry.scanned = scanned
  if not okIter then report.virtualInput.retainedRegistry.error = "registry enumeration failed: " .. text(iterError, 120) end
end

local function retainedFunctionMatch(fn, hash)
  if type(retainedRegistry) ~= "table" then
    return { available = false, matched = false, note = "retained closure registry unavailable" }
  end
  local result = { available = true, matched = false, matchKind = nil, ordinal = nil }
  for _, candidate in ipairs(retainedEntries) do
    if candidate.fn == fn then
      result.matched = true
      result.matchKind = "identity"
      result.ordinal = candidate.ordinal
      break
    elseif hash ~= nil and candidate.hash == hash then
      result.matched = true
      result.matchKind = "hash"
      result.ordinal = candidate.ordinal
      break
    end
  end
  return result
end

local INPUT_NAMES = {
  "iswindowactive",
  "keypress", "keyrelease", "keyclick",
  "mouse1press", "mouse1release", "mouse1click",
  "mouse2press", "mouse2release", "mouse2click",
  "mousescroll", "mousemoverel", "mousemoveabs",
}

local inputByName = {}
for _, name in ipairs(INPUT_NAMES) do
  report.telemetry.scanned.inputGlobals = report.telemetry.scanned.inputGlobals + 1
  local value, host = resolveName(name)
  local entry = { name = name, available = type(value) == "function", host = host }
  if type(value) == "function" then
    entry.functionInfo = functionInfo(value)
    entry.retainedReference = retainedFunctionMatch(value, entry.functionInfo and entry.functionInfo.hash or nil)
    inputByName[name] = { fn = value, report = entry }
    if entry.functionInfo and entry.functionInfo.isFunctionHooked == true then
      addFinding(
        "input-global-hooked-" .. name,
        "virtual-input",
        "medium",
        "confirmed-local",
        true,
        "Virtual-input global reports as hooked",
        name .. " returned true from isfunctionhooked; the function was not called.",
        12
      )
    end
  end
  report.virtualInput.globals[#report.virtualInput.globals + 1] = entry
end

local usedInputNames = {}
local environmentIds = {}
local environmentSequence = 0

local PRIVILEGED_NAMES = {
  getgenv = true, getrenv = true, getfenv = true, getsenv = true, getgc = true,
  hookfunction = true, hookmetamethod = true, newcclosure = true, getrawmetatable = true,
  getcallingscript = true, getscriptclosure = true, request = true, http_request = true,
  cloneref = true, compareinstances = true, shared = true, identifyexecutor = true,
  getexecutorname = true, getexecutorinfo = true, gethui = true, syn = true, fluxus = true,
  krnl = true, websocket = true,
}
for _, inputName in ipairs(INPUT_NAMES) do PRIVILEGED_NAMES[inputName] = true end

local function environmentId(environment)
  if type(environment) ~= "table" then return nil end
  for _, pair in ipairs(environmentIds) do
    if pair.value == environment then return pair.id end
  end
  environmentSequence = environmentSequence + 1
  local id = "env-" .. tostring(environmentSequence)
  environmentIds[#environmentIds + 1] = { value = environment, id = id }
  return id
end

local function inspectEnvironment(label, environment, targetScoped)
  if type(environment) ~= "table" then return nil end
  local output = {
    label = label,
    environmentId = environmentId(environment),
    sameAsGetgenv = genvEnvironment ~= nil and environment == genvEnvironment,
    sameAsGetrenv = renvEnvironment ~= nil and environment == renvEnvironment,
    sameAsGlobalG = type(_G) == "table" and environment == _G,
    keyCount = 0,
    keys = {},
    privilegedKeys = {},
    inputBindings = {},
    serviceReferences = {},
    redactedSensitiveKeyNames = 0,
    truncated = false,
  }
  local privilegedSeen = {}
  local inputSeen = {}
  local okIter, iterError = pcall(function()
    for key, value in pairs(environment) do
      if output.keyCount >= CONFIG.maxEnvironmentKeys then
        output.truncated = true
        report.telemetry.truncation.environments = true
        break
      end
      output.keyCount = output.keyCount + 1
      report.telemetry.scanned.environmentKeys = report.telemetry.scanned.environmentKeys + 1
      if type(key) == "string" then
        local renderedKey = safeKeyName(key)
        if renderedKey == "<redacted-sensitive-key-name>" then output.redactedSensitiveKeyNames = output.redactedSensitiveKeyNames + 1 end
        output.keys[#output.keys + 1] = renderedKey
        local normalized = string.lower(key)
        if (PRIVILEGED_NAMES[normalized] or string.sub(normalized, 1, 6) == "__mcp_") and not privilegedSeen[normalized] then
          privilegedSeen[normalized] = true
          output.privilegedKeys[#output.privilegedKeys + 1] = safeKeyName(key)
        end
        if inputByName[normalized] and type(value) == "function" and not inputSeen[normalized] then
          inputSeen[normalized] = true
          local sameFunction = value == inputByName[normalized].fn
          output.inputBindings[#output.inputBindings + 1] = { name = normalized, sameAsResolvedGlobal = sameFunction }
        end
      end
      if typeof(value) == "Instance" then
        for serviceName, service in pairs(services) do
          local kind = sameInstanceKind(value, service)
          if kind then
            output.serviceReferences[#output.serviceReferences + 1] = {
              key = type(key) == "string" and safeKeyName(key) or "<non-string-key>",
              service = serviceName,
              referenceKind = kind,
            }
            if targetScoped then
              report.virtualInput.targetReferences[#report.virtualInput.targetReferences + 1] = {
                origin = label,
                location = type(key) == "string" and safeKeyName(key) or "<non-string-key>",
                service = serviceName,
                referenceKind = kind,
              }
            end
            if targetScoped and (serviceName == "VirtualInputManager" or serviceName == "VirtualUser") and kind == "direct" then
              addFinding(
                "direct-virtual-service-env-" .. serviceName .. "-" .. tostring(output.environmentId),
                "virtual-input",
                "medium",
                "confirmed-local",
                true,
                "Target environment retains a direct " .. serviceName .. " reference",
                "Environment " .. tostring(output.environmentId) .. " exposes the raw service reference under a key name; no value was returned.",
                12
              )
            end
          end
        end
      end
    end
  end)
  table.sort(output.keys)
  table.sort(output.privilegedKeys)
  if not okIter then output.error = "environment enumeration failed: " .. text(iterError, 160) end
  if targetScoped and #output.privilegedKeys > 0 then
    addFinding(
      "target-environment-privileged-" .. tostring(output.environmentId),
      "environment",
      "medium",
      "heuristic",
      false,
      "Target environment exposes privileged executor-facing names",
      tostring(#output.privilegedKeys) .. " bounded key names were visible, including " .. table.concat(output.privilegedKeys, ", "),
      8
    )
  end
  if targetScoped and output.sameAsGetgenv then
    addFinding(
      "target-environment-is-getgenv-" .. tostring(output.environmentId),
      "environment",
      "medium",
      "confirmed-local",
      true,
      "Target environment is the executor global environment",
      "The target environment has direct table identity with getgenv(); only bounded key names were returned.",
      14
    )
  end
  return output
end

local scriptTarget = nil
if CONFIG.scriptExpression ~= "" then
  local value, err = evaluateExpression(CONFIG.scriptExpression, "Instance")
  if err then
    report.target.script = { resolved = false, error = err }
    addUnknown("script-target", err)
  else
    scriptTarget = value
    report.target.script = instanceInfo(value) or { resolved = true }
    report.target.script.resolved = true
    local okLuaSource, isLuaSource = pcall(function() return value:IsA("LuaSourceContainer") end)
    report.target.script.isLuaSourceContainer = okLuaSource and isLuaSource == true
    if not report.target.script.isLuaSourceContainer then addUnknown("script-target-type", "resolved Instance is not a LuaSourceContainer") end
  end
end

local explicitFunction = nil
if CONFIG.functionExpression ~= "" then
  local value, err = evaluateExpression(CONFIG.functionExpression, "function")
  if err then
    report.target.explicitFunction = { resolved = false, error = err }
    addUnknown("function-target", err)
  else
    explicitFunction = value
    report.target.explicitFunction = { resolved = true, info = functionInfo(value) }
  end
end

local scriptClosure = nil
if scriptTarget ~= nil then
  if type(F.getscripthash) == "function" then
    local ok, value = pcall(F.getscripthash, scriptTarget)
    if ok and value ~= nil then report.target.script.scriptHash = text(value, 180) else addUnknown("script-hash", "getscripthash failed") end
  else
    addUnknown("script-hash", "getscripthash unavailable")
  end
  if type(F.getsenv) == "function" then
    local ok, environment = pcall(F.getsenv, scriptTarget)
    if ok and type(environment) == "table" then
      report.environments.targetScript = inspectEnvironment("target-script-getsenv", environment, true)
    else
      addUnknown("script-environment", "getsenv failed or returned no table")
    end
  else
    addUnknown("script-environment", "getsenv unavailable")
  end
  if type(F.getscriptclosure) == "function" then
    local ok, closure = pcall(F.getscriptclosure, scriptTarget)
    if ok and type(closure) == "function" then scriptClosure = closure else addUnknown("script-closure", "getscriptclosure failed or returned no function") end
  else
    addUnknown("script-closure", "getscriptclosure unavailable")
  end
end

local selectedClosure = explicitFunction or scriptClosure
if selectedClosure ~= nil then
  report.target.selectedClosure = explicitFunction and "explicit-function" or "script-closure"
  report.closure = functionInfo(selectedClosure)
  if report.closure and report.closure.isFunctionHooked == true then
    addFinding(
      "target-function-hooked",
      "closure",
      "high",
      "confirmed-local",
      true,
      "The selected target closure reports as hooked",
      "isfunctionhooked returned true for the selected closure.",
      24
    )
  end
  if report.closure and report.closure.isExecutorClosure == true and report.closure.source and report.closure.source ~= "" then
    addFinding(
      "executor-closure-debug-identity",
      "closure",
      "low",
      "heuristic",
      false,
      "Executor closure identity is visible through debug metadata",
      "The selected closure is classified as executor-origin and exposes bounded source metadata.",
      5
    )
  end
else
  addUnknown("selected-closure", "no function target or readable script closure was available")
end

if type(F.getcallingscript) == "function" then
  local ok, caller = pcall(F.getcallingscript)
  if ok and typeof(caller) == "Instance" then
    report.target.currentCallingScript = instanceInfo(caller)
    if scriptTarget ~= nil then
      local relation = sameInstanceKind(caller, scriptTarget)
      report.target.currentCallingScriptRelation = relation
      if relation then
        addFinding(
          "current-caller-matches-target",
          "script-identity",
          "medium",
          "confirmed-local",
          true,
          "Current calling-script identity matches the selected target",
          "getcallingscript exposed a reference matching the target during the audit call.",
          10
        )
      end
    end
  elseif not ok then
    addUnknown("calling-script", "getcallingscript raised an error")
  else
    report.target.currentCallingScript = nil
  end
else
  addUnknown("calling-script", "getcallingscript unavailable")
end

local INDICATORS = {
  { id = "virtual-input-manager", category = "virtual-input", terms = { "virtualinputmanager", "virtualuser", "createvirtualinput" }, points = 12 },
  { id = "mouse-input", category = "virtual-input", terms = { "mouse1click", "mouse1press", "mouse1release", "mouse2click", "mouse2press", "mouse2release", "mousemoverel", "mousemoveabs", "mousescroll" }, points = 10 },
  { id = "keyboard-input", category = "virtual-input", terms = { "keypress", "keyrelease", "keyclick" }, points = 10 },
  { id = "environment-access", category = "environment", terms = { "getfenv", "setfenv", "getgenv", "getrenv", "getsenv", "shared" }, points = 6 },
  { id = "hooking", category = "closure", terms = { "hookfunction", "hookmetamethod", "restorefunction", "newcclosure", "setstackhidden" }, points = 10 },
  { id = "debug-reflection", category = "reflection", terms = { "getconstants", "getupvalues", "getprotos", "debug.get", "getgc" }, points = 6 },
  { id = "script-identity", category = "script-identity", terms = { "getcallingscript", "getscriptclosure", "getscripthash" }, points = 7 },
  { id = "executor-fingerprint", category = "environment", terms = { "identifyexecutor", "getexecutorname", "getexecutorinfo", "syn.", "fluxus", "krnl", "__mcp_", "gethui" }, points = 7 },
}

local function scanIndicatorText(origin, lineNumber, rawText, sink)
  local normalized = string.lower(rawText)
  for _, indicator in ipairs(INDICATORS) do
    for _, term in ipairs(indicator.terms) do
      if string.find(normalized, term, 1, true) then
        if evidenceCount < CONFIG.maxEvidence and #report.sourceIndicators < sourceEvidenceLimit then
          report.sourceIndicators[#report.sourceIndicators + 1] = {
            origin = origin,
            line = lineNumber,
            indicator = indicator.id,
            term = term,
            snippet = origin == "closure-constant" and "<redacted:matching-string-constant>" or redactSnippet(rawText),
          }
          evidenceCount = evidenceCount + 1
        else
          report.telemetry.truncation.evidence = true
        end
        if inputByName[term] then usedInputNames[term] = true end
        if term == "virtualinputmanager" or term == "virtualuser" or term == "createvirtualinput" then
          usedInputNames.__virtualService = true
        end
        sink[indicator.id] = sink[indicator.id] or { indicator = indicator, terms = {} }
        sink[indicator.id].terms[term] = true
        break
      end
    end
  end
end

local indicatorEvidence = {}
if scriptTarget ~= nil and CONFIG.includeSourceScan then
  local ok, sourceText = pcall(function() return scriptTarget.Source end)
  if ok and type(sourceText) == "string" then
    local originalLength = #sourceText
    if originalLength > CONFIG.maxSourceChars then
      sourceText = string.sub(sourceText, 1, CONFIG.maxSourceChars)
      report.telemetry.truncation.source = true
    end
    report.telemetry.scanned.sourceChars = #sourceText
    report.target.script.sourceAccessible = true
    report.target.script.sourceLength = originalLength
    report.target.script.sourceScannedChars = #sourceText
    local lineNumber = 0
    for line in string.gmatch(sourceText .. "\\n", "([^\\r\\n]*)\\r?\\n") do
      lineNumber = lineNumber + 1
      report.telemetry.scanned.sourceLines = lineNumber
      scanIndicatorText("script-source", lineNumber, line, indicatorEvidence)
    end
  else
    if report.target.script then report.target.script.sourceAccessible = false end
    addUnknown("script-source", "script.Source was unavailable; the tool does not decompile as a fallback")
  end
elseif scriptTarget ~= nil then
  addUnknown("script-source", "source scan disabled by input")
end

local constantSummary = { scanned = 0, types = {}, indicators = {}, truncated = false }
if selectedClosure ~= nil and CONFIG.maxConstants > 0 then
  if type(F.getconstants) == "function" then
    local ok, constants = pcall(F.getconstants, selectedClosure)
    if ok and type(constants) == "table" then
      local seen = 0
      for _, value in pairs(constants) do
        if seen >= CONFIG.maxConstants then
          constantSummary.truncated = true
          report.telemetry.truncation.constants = true
          break
        end
        seen = seen + 1
        constantSummary.scanned = seen
        report.telemetry.scanned.constants = seen
        local valueType = typeof(value)
        constantSummary.types[valueType] = (constantSummary.types[valueType] or 0) + 1
        if type(value) == "string" then scanIndicatorText("closure-constant", nil, value, indicatorEvidence) end
      end
    else
      addUnknown("closure-constants", "getconstants failed or returned no table")
    end
  else
    addUnknown("closure-constants", "getconstants/debug.getconstants unavailable")
  end
end
if report.closure then report.closure.constantSummary = constantSummary end

local upvalueSummary = { scanned = 0, entries = {}, serviceReferences = {}, truncated = false }
if selectedClosure ~= nil and CONFIG.maxUpvalues > 0 then
  if type(F.getupvalues) == "function" then
    local ok, upvalues = pcall(F.getupvalues, selectedClosure)
    if ok and type(upvalues) == "table" then
      local scanned = 0
      for key, value in pairs(upvalues) do
        if scanned >= CONFIG.maxUpvalues then
          upvalueSummary.truncated = true
          report.telemetry.truncation.upvalues = true
          break
        end
        scanned = scanned + 1
        report.telemetry.scanned.upvalues = scanned
        local entry = {
          index = type(key) == "number" and key or nil,
          name = type(key) == "string" and safeKeyName(key) or nil,
          valueType = typeof(value),
        }
        if type(key) == "string" and inputByName[string.lower(key)] then usedInputNames[string.lower(key)] = true end
        if typeof(value) == "Instance" then
          for serviceName, service in pairs(services) do
            local kind = sameInstanceKind(value, service)
            if kind then
              local reference = {
                location = entry.name or ("upvalue-" .. tostring(scanned)),
                service = serviceName,
                referenceKind = kind,
              }
              entry.serviceReference = reference
              upvalueSummary.serviceReferences[#upvalueSummary.serviceReferences + 1] = reference
              report.virtualInput.targetReferences[#report.virtualInput.targetReferences + 1] = {
                origin = "target-closure-upvalue",
                location = reference.location,
                service = serviceName,
                referenceKind = kind,
              }
              if (serviceName == "VirtualInputManager" or serviceName == "VirtualUser") and kind == "direct" then
                addFinding(
                  "direct-virtual-service-upvalue-" .. serviceName .. "-" .. tostring(scanned),
                  "virtual-input",
                  "medium",
                  "confirmed-local",
                  true,
                  "Target closure captures a direct " .. serviceName .. " reference",
                  "A bounded upvalue classification matched the raw service reference; the captured value was not returned.",
                  14
                )
              end
            end
          end
        end
        upvalueSummary.entries[#upvalueSummary.entries + 1] = entry
      end
      upvalueSummary.scanned = scanned
    else
      addUnknown("closure-upvalues", "getupvalues failed or returned no table")
    end
  else
    addUnknown("closure-upvalues", "getupvalues/debug.getupvalues unavailable")
  end
end
if report.closure then report.closure.upvalueSummary = upvalueSummary end

if selectedClosure ~= nil and type(F.getfenv) == "function" then
  report.telemetry.getfenvUsed = true
  local ok, environment = pcall(F.getfenv, selectedClosure)
  if ok and type(environment) == "table" then
    report.environments.targetFunction = inspectEnvironment("target-function-getfenv", environment, true)
  else
    addUnknown("function-environment", "getfenv(target) failed or returned no table")
  end
elseif selectedClosure ~= nil then
  addUnknown("function-environment", "getfenv unavailable")
end

if report.environments.targetScript and report.environments.targetFunction then
  report.environments.targetRelation = {
    sameEnvironment = report.environments.targetScript.environmentId == report.environments.targetFunction.environmentId,
    scriptEnvironmentId = report.environments.targetScript.environmentId,
    functionEnvironmentId = report.environments.targetFunction.environmentId,
  }
end

if CONFIG.includeStackEnvironments then
  if type(F.getfenv) == "function" then
    report.telemetry.getfenvUsed = true
    local unique = {}
    local previousId = nil
    local reuseCount = 0
    for level = 0, CONFIG.maxStackFrames - 1 do
      local ok, environment = pcall(F.getfenv, level)
      report.telemetry.scanned.stackFrames = report.telemetry.scanned.stackFrames + 1
      if ok and type(environment) == "table" then
        local id = environmentId(environment)
        local reused = unique[id] == true
        if reused then reuseCount = reuseCount + 1 end
        report.environments.currentStack[#report.environments.currentStack + 1] = {
          level = level,
          accessible = true,
          environmentId = id,
          sameAsPrevious = previousId == id,
          reusedAcrossFrames = reused,
        }
        if not unique[id] then
          unique[id] = true
          report.environments.uniqueCurrent[#report.environments.uniqueCurrent + 1] = inspectEnvironment("current-stack-level-" .. tostring(level), environment, false)
        end
        previousId = id
      else
        report.environments.currentStack[#report.environments.currentStack + 1] = { level = level, accessible = false }
        if level > 1 then break end
      end
    end
    report.environments.currentStackReuseCount = reuseCount
  else
    addUnknown("stack-environments", "getfenv unavailable")
  end
end

if report.telemetry.getfenvUsed then
  report.notes[#report.notes + 1] = "Luau deprecates getfenv/setfenv; getfenv reads can deoptimize the inspected environment."
end

for indicatorId, record in pairs(indicatorEvidence) do
  local terms = {}
  for term in pairs(record.terms) do terms[#terms + 1] = term end
  table.sort(terms)
  addFinding(
    "target-indicator-" .. indicatorId,
    record.indicator.category,
    record.indicator.category == "virtual-input" and "medium" or "low",
    "heuristic",
    false,
    "Target material contains " .. indicatorId .. " indicators",
    "Bounded source/constant inspection matched: " .. table.concat(terms, ", "),
    record.indicator.points
  )
end

for inputName in pairs(usedInputNames) do
  if inputName ~= "__virtualService" then
    local input = inputByName[inputName]
    local retained = input and input.report and input.report.retainedReference or nil
    if retained and retained.available == true and retained.matched ~= true then
      addFinding(
        "input-provenance-no-retained-match-" .. inputName,
        "virtual-input",
        "low",
        "heuristic",
        false,
        "Used input primitive has no retained MCP closure match",
        inputName .. " was referenced by target evidence, but no bounded identity/hash match was found. This is provenance only; cloning is not a safety recommendation.",
        4
      )
    elseif retained and retained.available ~= true then
      addUnknown("input-retained-reference-" .. inputName, "retained MCP closure registry unavailable; provenance match is unknown")
    end
  end
end

local availableCapabilityCount = 0
local totalCapabilityCount = 0
for _, entry in pairs(report.capabilities) do
  totalCapabilityCount = totalCapabilityCount + 1
  if entry.available == true then availableCapabilityCount = availableCapabilityCount + 1 end
end
local coverage = totalCapabilityCount > 0 and (availableCapabilityCount / totalCapabilityCount) or 0
local score = math.min(100, riskPoints)
local band = "minimal"
if score >= 75 then band = "severe"
elseif score >= 50 then band = "high"
elseif score >= 25 then band = "moderate"
elseif score >= 10 then band = "low" end
local confidence = "low"
if confirmedFindingCount > 0 and coverage >= 0.7 then confidence = "high"
elseif confirmedFindingCount > 0 or coverage >= 0.5 then confidence = "medium" end

report.risk = {
  score = score,
  band = band,
  confidence = confidence,
  confirmedFindings = confirmedFindingCount,
  heuristicFindings = heuristicFindingCount,
  capabilityCoverage = math.floor(coverage * 1000 + 0.5) / 1000,
  interpretation = "Local observable exposure only; not a detection verdict.",
}

report.telemetry.findingCount = #report.findings
report.telemetry.evidenceCount = evidenceCount
report.telemetry.unknownCheckCount = #report.unknownChecks
report.telemetry.sourceIndicatorCount = #report.sourceIndicators
report.telemetry.durationMs = math.max(0, math.floor((now() - startedAt) * 1000 + 0.5))
report.telemetry.truncated = report.telemetry.truncation.evidence
  or report.telemetry.truncation.environments
  or report.telemetry.truncation.source
  or report.telemetry.truncation.constants
  or report.telemetry.truncation.upvalues
  or report.telemetry.truncation.retainedRefs
  or report.telemetry.truncation.unknownChecks
report.ok = true
return report
`,O=await f.runLuau(N,{threadContext:p,timeoutMs:3e4}),q=O?.risk;return{data:O,summary:q?`Local exposure risk ${q.score??"?"}/100 (${q.band??"unknown"}, ${q.confidence??"unknown"} confidence); not a detection verdict.`:"Execution-footprint audit completed; inspect the structured report."}}});import{z as zl}from"zod";var Kl=u({name:"get-anticheat-surfaces",title:"Lightweight anti-cheat surface summary",description:"Fast, lightweight defensive recon that summarizes the most common anti-cheat surfaces WITHOUT a heavy GC walk (complements, and does not duplicate, the deeper scan-hook-surfaces tool). It checks: (1) how many connections are attached to RunService's Heartbeat, Stepped, and RenderStepped \u2014 the signals anti-cheats most often use for per-frame validation loops \u2014 via getconnections; (2) whether game's raw metatable is locked (isreadonly on getrawmetatable(game)), which gates __index/__namecall hooking; (3) the count of nil-parented instances (getnilinstances), where detached watchdog scripts/objects often hide; and (4) any getgenv() global names that look anti-cheat-related (matching detect/ban/kick/anticheat/flag/cheat, case-insensitive), which can reveal an exploit's own loader or a leaked server-side guard name. Use this only as lightweight ambient context after `execution-footprint-audit`; it reports observable surfaces and does not prove detection or provide concealment. Each probe degrades gracefully and is pcall-guarded; missing executor functions are reported as unavailable rather than failing the call. Returns { runServiceConnections, gameMetatableReadonly, nilInstanceCount, suspiciousGlobals, notes } or { error }.",category:"Diagnostics",input:zl.object({threadContext:zl.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
local out = {
  runServiceConnections = nil,
  gameMetatableReadonly = nil,
  nilInstanceCount = nil,
  suspiciousGlobals = {},
  notes = {},
}

-- (1) Connection counts on the hot RunService signals.
if type(getconnections) ~= "function" then
  out.notes[#out.notes + 1] = "getconnections unavailable; cannot count RunService connections."
else
  local okR, rs = pcall(function() return game:GetService("RunService") end)
  if okR and rs then
    local rsc = {}
    local signals = { "Heartbeat", "Stepped", "RenderStepped" }
    for _, sig in ipairs(signals) do
      local okS, signal = pcall(function() return rs[sig] end)
      if okS and signal then
        local okC, conns = pcall(getconnections, signal)
        if okC and type(conns) == "table" then
          rsc[sig] = #conns
        else
          rsc[sig] = "unavailable"
        end
      else
        rsc[sig] = "no-signal"
      end
    end
    out.runServiceConnections = rsc
  else
    out.notes[#out.notes + 1] = "Could not resolve RunService."
  end
end

-- (2) Is game's raw metatable locked?
if type(getrawmetatable) ~= "function" then
  out.notes[#out.notes + 1] = "getrawmetatable unavailable; cannot inspect game metatable lock."
else
  local okM, mt = pcall(getrawmetatable, game)
  if okM and type(mt) == "table" then
    if type(isreadonly) == "function" then
      local okRO, ro = pcall(isreadonly, mt)
      if okRO then out.gameMetatableReadonly = (ro == true) end
    else
      out.notes[#out.notes + 1] = "isreadonly unavailable; metatable lock state unknown."
    end
  else
    out.notes[#out.notes + 1] = "getrawmetatable(game) returned no table."
  end
end

-- (3) Nil-parented instance count.
if type(getnilinstances) == "function" then
  local okN, nils = pcall(getnilinstances)
  if okN and type(nils) == "table" then out.nilInstanceCount = #nils end
else
  out.notes[#out.notes + 1] = "getnilinstances unavailable; cannot count nil instances."
end

-- (4) Suspicious global names in getgenv().
if type(getgenv) == "function" then
  local okG, genv = pcall(getgenv)
  if okG and type(genv) == "table" then
    local patterns = { "detect", "ban", "kick", "anticheat", "anti%-cheat", "flag", "cheat", "exploit" }
    local seen = {}
    local cap = 30
    local count = 0
    -- A proxy/locked env can throw inside pairs() (e.g. a hostile __iter), so the
    -- whole enumeration is pcall-isolated; probes 1-3 still return on failure.
    local okEnum = pcall(function()
      for k, _ in pairs(genv) do
        if type(k) == "string" then
          local lk = string.lower(k)
          for _, p in ipairs(patterns) do
            if string.find(lk, p) then
              if not seen[k] then
                seen[k] = true
                out.suspiciousGlobals[#out.suspiciousGlobals + 1] = k
                count = count + 1
              end
              break
            end
          end
        end
        if count >= cap then break end
      end
    end)
    if not okEnum then out.notes[#out.notes + 1] = "could not enumerate getgenv()." end
    table.sort(out.suspiciousGlobals)
  end
else
  out.notes[#out.notes + 1] = "getgenv unavailable; cannot scan globals."
end

out.ok = true
return out
`,{threadContext:e,timeoutMs:2e4})}}});import{z as Hl}from"zod";var Xl=u({name:"get-connector-diagnostics",title:"Connector and runtime self-report",description:"Probe the live connector/runtime from inside the Roblox client and return a self-report describing the execution environment. Every read is pcall-guarded, so an unavailable function is reported as null rather than failing the call. Returns { threadIdentity, executor={ name, version }, hasWebSocket, gcInfoKB, genvKeyCount, hasReg, hasRenv, capabilities={ getgc, hookfunction, getnilinstances, getactors, getluastate, run_on_actor, clonefunction, newcclosure, cloneref, compareinstances, getcallingscript, getscriptclosure, getsenv, getfenv, mouse1click, keypress, getcallbackvalue, firesignal, getconnections } }. Use this to confirm what the connector can do before relying on reflection/hooking tools, or to diagnose why a client is behaving unexpectedly.",category:"Diagnostics",input:Hl.object({threadContext:Hl.number().int().optional()}),async execute({threadContext:e},t){return{data:await t.runLuau(`
local function safe(fn)
  local ok, v = pcall(fn)
  if ok then return v end
  return nil
end

-- Headline capability booleans: each is true only when the named global resolves
-- to a function in the thread environment (getgenv() first, then _G).
local function hasGlobal(name)
  local hosts = {}
  local function addHost(host)
    if type(host) ~= "table" then return end
    for _, current in ipairs(hosts) do if current == host then return end end
    hosts[#hosts + 1] = host
  end
  if type(getgenv) == "function" then local ok, value = pcall(getgenv); if ok then addHost(value) end end
  if type(getfenv) == "function" then local ok, value = pcall(getfenv, 0); if ok then addHost(value) end end
  addHost(_G)
  for _, host in ipairs(hosts) do
    local okIdx, val = pcall(function() return host[name] end)
    if okIdx and type(val) == "function" then return true end
  end
  return false
end

-- Thread identity (executor scheduler level).
local threadIdentity = safe(function()
  if type(getthreadidentity) == "function" then return getthreadidentity() end
  return nil
end)

-- Executor name + version (guarded; identifyexecutor returns name, version).
local executorName, executorVersion = nil, nil
if type(identifyexecutor) == "function" then
  local ok, n, v = pcall(identifyexecutor)
  if ok then
    executorName = n
    executorVersion = v
  end
end

-- WebSocket availability: a table-typed global named WebSocket.
local hasWebSocket = safe(function()
  return type(WebSocket) == "table"
end) == true

-- GC info in KB (Lua's collectgarbage("count") style number).
local gcInfoKB = safe(function()
  if type(gcinfo) == "function" then return gcinfo() end
  return nil
end)

-- Count of keys in getgenv() (guarded \u2014 getgenv may be absent).
local genvKeyCount = nil
if type(getgenv) == "function" then
  local ok, env = pcall(getgenv)
  if ok and type(env) == "table" then
    local n = 0
    local okIter = pcall(function()
      for _ in pairs(env) do n = n + 1 end
    end)
    if okIter then genvKeyCount = n end
  end
end

-- Registry / thread-environment availability flags.
local hasReg = type(getreg) == "function"
local hasRenv = type(getrenv) == "function"

local capabilities = {
  getgc = hasGlobal("getgc"),
  hookfunction = hasGlobal("hookfunction"),
  getnilinstances = hasGlobal("getnilinstances"),
  getactors = hasGlobal("getactors"),
  getluastate = hasGlobal("getluastate"),
  getactorstates = hasGlobal("getactorstates"),
  run_on_actor = hasGlobal("run_on_actor"),
  create_comm_channel = hasGlobal("create_comm_channel"),
  clonefunction = hasGlobal("clonefunction"),
  newcclosure = hasGlobal("newcclosure"),
  restorefunction = hasGlobal("restorefunction"),
  cloneref = hasGlobal("cloneref"),
  compareinstances = hasGlobal("compareinstances"),
  getcallingscript = hasGlobal("getcallingscript"),
  getscriptclosure = hasGlobal("getscriptclosure"),
  getsenv = hasGlobal("getsenv"),
  getfenv = hasGlobal("getfenv"),
  mouse1click = hasGlobal("mouse1click"),
  keypress = hasGlobal("keypress"),
  getcallbackvalue = hasGlobal("getcallbackvalue"),
  firesignal = hasGlobal("firesignal"),
  getconnections = hasGlobal("getconnections"),
}

return {
  threadIdentity = threadIdentity,
  executor = { name = executorName, version = executorVersion },
  hasWebSocket = hasWebSocket,
  gcInfoKB = gcInfoKB,
  genvKeyCount = genvKeyCount,
  hasReg = hasReg,
  hasRenv = hasRenv,
  capabilities = capabilities,
  ok = true,
}
`,{threadContext:e,timeoutMs:2e4})}}});import{z as Lr}from"zod";var Yl=u({name:"get-instance-counts",title:"Game-size profile: instance counts by ClassName",description:"In-game shape/size profile. Walks game:GetDescendants() once (pcall-guarded, capped) and tallies every Instance by its ClassName, returning the heaviest classes first. This is the quickest way to understand how big and how 'shaped' a place is \u2014 e.g. tens of thousands of Parts, a forest of UI Frames, a swarm of scripts, or an unusual pile of a single odd class. The descendant walk is capped (maxScan, default 200000) and sets truncated=true if it hits the cap (the counts then reflect only what was scanned). The returned class list is capped to topN entries. Requires nothing beyond a live game; everything is guarded. Returns { totalInstances, scanned, truncated, distinctClasses, topClasses: [{ class, count }] } (sorted by count desc) or { error }.",category:"Diagnostics",input:Lr.object({topN:Lr.number().int().describe("How many of the heaviest ClassName buckets to return, sorted by count descending (default 25). The full distinctClasses count is always reported even when the list is trimmed to topN.").optional().default(25),maxScan:Lr.number().int().describe("Maximum number of descendants to visit (default 200000). The walk stops at this cap and sets truncated=true; raise it for a huge place if you need exact totals, lower it to bound cost.").optional().default(2e5),threadContext:Lr.number().int().optional()}),async execute({topN:e,maxScan:t,threadContext:n},r){let a=Math.min(Math.max(Math.floor(e??25),1),500),i=`
local okDesc, descendants = pcall(function() return game:GetDescendants() end)
if not okDesc or type(descendants) ~= "table" then
  return { error = "Failed to enumerate game:GetDescendants()." }
end

local counts = {}
local distinct = 0
local scanned = 0
local truncated = false
for i = 1, #descendants do
  scanned = scanned + 1
  if scanned > ${Math.min(Math.max(Math.floor(t??2e5),1e3),2e6)} then truncated = true; scanned = scanned - 1; break end
  local inst = descendants[i]
  local okC, cls = pcall(function() return inst.ClassName end)
  if okC and type(cls) == "string" then
    if counts[cls] == nil then counts[cls] = 0; distinct = distinct + 1 end
    counts[cls] = counts[cls] + 1
  else
    counts["<unknown>"] = (counts["<unknown>"] or 0) + 1
  end
end

-- Sort classes by count descending.
local arr = {}
for cls, c in pairs(counts) do arr[#arr + 1] = { class = cls, count = c } end
table.sort(arr, function(a, b) return a.count > b.count end)

local top = {}
for i = 1, math.min(#arr, ${a}) do top[i] = arr[i] end

return {
  totalInstances = scanned,
  scanned = scanned,
  truncated = truncated,
  distinctClasses = distinct,
  topClasses = top,
  ok = true,
}
`;return{data:await r.runLuau(i,{threadContext:n,timeoutMs:45e3})}}});import{z as Rt}from"zod";var Zl=u({name:"session-replay",title:"Plan or Replay a Recorded Session's Tool Calls",description:"Read one session's recorded trace and (by default) return a structured plan; pass `dryRun: false` to actually re-issue each plannable step through the invoker. Tools that mutate game/host state are flagged `blockedByDefault: true` and are SKIPPED unless `includeMutating: true` is also set. Steps that originally failed are never replayed. The replayed steps themselves get recorded into the CURRENT session's trace, so you can chain saves into a playbook via `playbook-save`. session-replay refuses to call itself.",category:"Diagnostics",mutatesState:!0,requiresClient:!1,input:Rt.object({sessionId:Rt.string().min(1).describe("Session UUID from session-list."),from:Rt.number().int().positive().optional(),to:Rt.number().int().positive().optional(),includeMutating:Rt.boolean().optional().describe("Allow flagged-mutating tools to be planned/executed. Default false."),dryRun:Rt.boolean().optional().describe("When true (default) only returns the plan. False actually re-issues each step in order.")}),async execute({sessionId:e,from:t,to:n,includeMutating:r,dryRun:a},o){let i={};t!==void 0&&(i.from=t),n!==void 0&&(i.to=n);let l=await o.sessionLogger.read(e,i),c=l.filter(b=>b.error).length,d=[];for(let b of l){if(b.error||b.tool==="session-replay")continue;let m=o.tools.find(b.tool)?.mutatesState??!0;m&&!r||d.push({seq:b.seq,tool:b.tool,input:b.input,originalElapsedMs:b.elapsedMs,wouldRun:!m||r===!0,...m?{blockedByDefault:!0}:{}})}if(a!==!1)return{data:{sessionId:e,mode:"plan",steps:d,summary:{total:l.length,plannable:d.length,skippedErrors:c}}};let p=Date.now(),f=[],h=0,g=0;for(let b of d){let m=Date.now();try{let y=await o.invokeTool(b.tool,b.input);f.push({seq:b.seq,tool:b.tool,ok:!y.isError,data:y.data,elapsedMs:Date.now()-m}),y.isError?g+=1:h+=1}catch(y){f.push({seq:b.seq,tool:b.tool,ok:!1,error:y.message,elapsedMs:Date.now()-m}),g+=1}}return{data:{sessionId:e,mode:"replay",results:f,summary:{total:l.length,replayed:f.length,ok:h,failed:g,skippedErrors:c,totalMs:Date.now()-p}}}}});import{z as $n}from"zod";var Ql=u({name:"session-show",title:"Read Recorded Tool Calls from a Session",description:"Read a window of recorded tool calls from one session's JSONL trace. Pass `sessionId` (from `session-list`) and optional `from`/`to` to bound the seq range (1-indexed, inclusive). Each record has { seq, at, tool, input, result?|error?, elapsedMs, clientId?, sessionId } \u2014 exactly what the invoker saw. Useful for auditing what was run and feeding `session-replay`.",category:"Diagnostics",mutatesState:!1,requiresClient:!1,input:$n.object({sessionId:$n.string().min(1).describe("Session UUID from session-list."),from:$n.number().int().positive().optional().describe("Start at this seq (default 1)."),to:$n.number().int().positive().optional().describe("Stop at this seq (default end-of-file)."),limit:$n.number().int().positive().max(1e3).optional().describe("Cap returned records (default 200).")}),async execute({sessionId:e,from:t,to:n,limit:r},a){let o={};t!==void 0&&(o.from=t),n!==void 0&&(o.to=n);let i=await a.sessionLogger.read(e,o),l=i.slice(0,r??200);return{data:{sessionId:e,returned:l.length,total:i.length,records:l}}}});import{z as Jl}from"zod";var qd=["getgc","getconstants","getupvalues","getprotos","getinfo","debug.getinfo","debug.getconstants","debug.getupvalues","debug.getprotos","getfunctionhash","checkcaller","clonefunction","clonefunc","iscclosure","islclosure","isexecutorclosure","checkclosure","isourclosure","isfunctionhooked","isnewcclosure","iscustomcclosure","newlclosure","setstackhidden","getconstant","getupvalue","getproto","setconstant","setupvalue","setfenv","getscriptbytecode","getscriptclosure","getcallingscript","getscriptfromthread","getscripthash","getscripts","getrunningscripts","getloadedmodules","getsenv","getfenv","getactors","run_on_actor","getluastate","getgamestate","getactorstates","isparallel","is_parallel","create_comm_channel","get_comm_channel","LuaStateProxy.new","getnilinstances","getinstances","cloneref","compareinstances","getgenv","getrenv","getreg","hookfunction","hookmetamethod","restorefunction","newcclosure","getrawmetatable","setrawmetatable","setreadonly","isreadonly","getnamecallmethod","getconnections","firesignal","replicatesignal","getcallbackvalue","getsignalarguments","setthreadidentity","getthreadidentity","loadstring","fireproximityprompt","fireclickdetector","firetouchinterest","getcustomasset","request","http_request","mouse1click","mouse1press","mouse1release","mouse2click","mouse2press","mouse2release","mousemoveabs","mousemoverel","mousescroll","keypress","keyrelease","keyclick","iswindowactive"],ec=u({name:"test-capabilities",title:"Executor capability matrix (closure, Actor/state, and core primitives)",description:"In-game capability matrix: probes a curated executor/runtime function list and reports which are present (callable) versus missing. For each name it checks the global environment (getgenv() first, then the thread's environment / _G) and, for dotted names like 'debug.getinfo', walks the parent table \u2014 classifying the leaf as available only when it is type=='function'. The probe NEVER calls the functions, so it is completely safe and side-effect-free. Covers reflection/closures (getgc, constants/upvalues/protos, clone/wrapper/type/hook/hash functions), script access (getscriptbytecode/closure/caller/hash, getscripts, getrunningscripts, getloadedmodules, getsenv/getfenv), instance/actor discovery (getactors, Actor Lua-state execution, communication channels, getnilinstances, getinstances), environments (getgenv, getrenv, getreg), hooking (hookfunction, hookmetamethod, restorefunction, newcclosure), metatables (getrawmetatable, setrawmetatable, setreadonly, isreadonly), namecall/signals (getnamecallmethod, getconnections, firesignal, replicatesignal, getcallbackvalue, getsignalarguments), threads (setthreadidentity, getthreadidentity), and IO/misc (loadstring, fireproximityprompt, fireclickdetector, firetouchinterest, virtual-input globals, getcustomasset, request/http_request). Use this to decide up-front whether a workflow is supported, or to compare two executors. Returns { total, availableCount, missingCount, available[], missing[] } (both lists sorted) or { error }.",category:"Diagnostics",input:Jl.object({threadContext:Jl.number().int().optional()}),async execute({threadContext:e},t){let r=`
local NAMES = { ${qd.map(o=>JSON.stringify(o)).join(", ")} }

-- Build a list of candidate host tables to look a name up in.
local hosts = {}
local function __pushHost(t) if type(t) == "table" then hosts[#hosts + 1] = t end end
if type(getgenv) == "function" then local ok, g = pcall(getgenv); if ok then __pushHost(g) end end
if type(getfenv) == "function" then local ok, f = pcall(getfenv, 0); if ok then __pushHost(f) end end
if type(getrenv) == "function" then local ok, r = pcall(getrenv); if ok then __pushHost(r) end end
__pushHost(_G)

-- Resolve a possibly-dotted name to a value across all hosts; returns the value or nil.
local function __resolve(name)
  -- Split on '.'
  local parts = {}
  for p in string.gmatch(name, "[^%.]+") do parts[#parts + 1] = p end
  for _, host in ipairs(hosts) do
    local cur = host
    local okWalk = true
    for i = 1, #parts do
      if type(cur) ~= "table" then okWalk = false; break end
      local nxt = nil
      local okIdx = pcall(function() nxt = cur[parts[i]] end)
      if not okIdx then okWalk = false; break end
      cur = nxt
    end
    if okWalk and type(cur) == "function" then return cur end
  end
  return nil
end

local available = {}
local missing = {}
for _, name in ipairs(NAMES) do
  local fn = __resolve(name)
  if type(fn) == "function" then
    available[#available + 1] = name
  else
    missing[#missing + 1] = name
  end
end

table.sort(available)
table.sort(missing)

return {
  total = #NAMES,
  availableCount = #available,
  missingCount = #missing,
  available = available,
  missing = missing,
  ok = true,
}
`;return{data:await t.runLuau(r,{threadContext:e,timeoutMs:2e4})}}});import{z as T}from"zod";var ne="Actors & Hidden",ze=200,se={threadContext:T.number().int().optional()},Ar={arguments:T.array(we).max(24).optional().default([])},Nr={state:T.enum(["current","game","expression"]).optional().default("current"),stateExpression:T.string().optional().default("").describe("For state='expression', a Luau expression resolving to a LuaStateProxy, Actor, or BaseScript.")},ke=`
local function __evalActorExpression(expression)
  local chunk, compileError = loadstring("return " .. expression)
  if not chunk then return nil, "compile error in expression: " .. tostring(compileError) end
  local ok, value = pcall(chunk)
  if not ok then return nil, "error evaluating expression: " .. tostring(value) end
  return value, nil
end

local function __instanceInfo(instance)
  if typeof(instance) ~= "Instance" then return nil end
  local result = { name = instance.Name, class = instance.ClassName }
  local ok, fullName = pcall(function() return instance:GetFullName() end)
  if ok then result.fullName = fullName end
  return result
end

local function __eventValue(value, depth)
  depth = depth or 0
  local kind = typeof(value)
  if kind == "nil" or kind == "string" or kind == "number" or kind == "boolean" then return value end
  if kind == "Instance" then return { __type = "Instance", value = __instanceInfo(value) } end
  if kind == "table" and depth < 2 then
    local result = {}
    local count = 0
    local ok = pcall(function()
      for key, child in pairs(value) do
        count = count + 1
        if count > 30 then result.__truncated = true; break end
        result[tostring(key)] = __eventValue(child, depth + 1)
      end
    end)
    if ok then return result end
  end
  local ok, text = pcall(tostring, value)
  return { __type = kind, value = ok and text or "<unprintable>" }
end

local function __stateRegistry()
  if type(getgenv) ~= "function" then return nil end
  local ok, genv = pcall(getgenv)
  if not ok or type(genv) ~= "table" then return nil end
  if type(genv.__mcp_lua_states) ~= "table" then genv.__mcp_lua_states = {} end
  return genv.__mcp_lua_states
end

local function __stateInfo(state, includeActors)
  if state == nil then return nil, "LuaStateProxy is nil" end
  local result = { proxyType = typeof(state), actors = {} }
  local okId, id = pcall(function() return state.Id end)
  if not okId then return nil, "value does not expose LuaStateProxy.Id: " .. tostring(id) end
  result.id = id
  local okActor, isActorState = pcall(function() return state.IsActorState end)
  if okActor then result.isActorState = isActorState == true end
  local okEvent, event = pcall(function() return state.Event end)
  if okEvent and event ~= nil then result.eventType = typeof(event) end
  if includeActors ~= false then
    local okActors, actors = pcall(function() return state:GetActors() end)
    if okActors and type(actors) == "table" then
      result.actorCount = #actors
      for i = 1, math.min(#actors, 200) do result.actors[#result.actors + 1] = __instanceInfo(actors[i]) end
      result.actorsTruncated = #actors > 200
    end
  end
  local registry = __stateRegistry()
  if registry then
    local key = tostring(id)
    registry[key] = state
    result.reference = "getgenv().__mcp_lua_states[" .. string.format("%q", key) .. "]"
  end
  return result, nil
end

local function __resolveState(mode, expression)
  if mode == "current" then
    if type(getluastate) ~= "function" then return nil, "getluastate is not available in this executor." end
    local ok, state = pcall(getluastate)
    if not ok then return nil, "getluastate failed: " .. tostring(state) end
    return state, nil
  end
  if mode == "game" then
    if type(getgamestate) ~= "function" then return nil, "getgamestate is not available in this executor." end
    local ok, state = pcall(getgamestate)
    if not ok then return nil, "getgamestate failed: " .. tostring(state) end
    return state, nil
  end
  if expression == "" then return nil, "stateExpression is required when state='expression'." end
  local value, evalError = __evalActorExpression(expression)
  if evalError then return nil, evalError end
  local okId = pcall(function() return value.Id end)
  if okId then return value, nil end
  if type(getluastate) ~= "function" then return nil, "expression is not a LuaStateProxy and getluastate is unavailable." end
  local ok, state = pcall(getluastate, value)
  if not ok then return nil, "getluastate(target) failed: " .. tostring(state) end
  return state, nil
end

local function __pushBounded(buffer, value)
  buffer[#buffer + 1] = value
  if #buffer > ${ze} then table.remove(buffer, 1) end
end

local function __readMonitor(monitor, limit, clear)
  local result = {}
  local first = math.max(1, #monitor.events - limit + 1)
  for i = first, #monitor.events do result[#result + 1] = monitor.events[i] end
  if clear then monitor.events = {} end
  return result
end

local function __disconnect(connection)
  if connection == nil then return end
  pcall(function()
    if type(connection.Disconnect) == "function" then connection:Disconnect()
    elseif type(connection.disconnect) == "function" then connection:disconnect() end
  end)
end
`;function Pr(e){return e.map(te).join(", ")}function Ke(e){return{data:{error:`Refusing to ${e} (writes executor/game state); pass confirm=true.`},isError:!0}}var Gd=u({name:"actor-capabilities",title:"Probe Actors, LuaStateProxy, channels, and actor events",description:"Read-only matrix for Volt's complete Actors and LuaStateProxy surface, including event objects and aliases.",category:ne,input:T.object(se),async execute({threadContext:e},t){return{data:await t.runLuau(`
local functions = {
  getactors = type(getactors) == "function" or type(get_actors) == "function",
  run_on_actor = type(run_on_actor) == "function",
  getluastate = type(getluastate) == "function",
  getgamestate = type(getgamestate) == "function",
  getactorstates = type(getactorstates) == "function",
  isparallel = type(isparallel) == "function" or type(is_parallel) == "function",
  create_comm_channel = type(create_comm_channel) == "function",
  get_comm_channel = type(get_comm_channel) == "function",
  LuaStateProxy_new = type(LuaStateProxy) == "table" and type(LuaStateProxy.new) == "function",
}
local function eventInfo(value)
  if value == nil then return { available = false } end
  local ok, event = pcall(function() return value.Event end)
  local signal = (ok and event ~= nil) and event or value
  local okConnect, connect = pcall(function() return signal.Connect end)
  return {
    available = okConnect and type(connect) == "function",
    objectType = typeof(value),
    signalType = typeof(signal),
    wrappedEvent = ok and event ~= nil,
  }
end
local total, available = 0, 0
for _, value in pairs(functions) do total = total + 1; if value then available = available + 1 end end
local events = {
  on_actor_added = eventInfo(on_actor_added),
  on_actor_state_created = eventInfo(on_actor_state_created),
}
return { ok = true, total = total, availableCount = available, missingCount = total - available, functions = functions, events = events }
`,{threadContext:e,timeoutMs:15e3})}}}),Dd=u({name:"run-on-actor",title:"Schedule Luau source on an Actor's isolated state",description:"WRITES LIVE GAME STATE. Resolve an Actor expression and call run_on_actor(actor, source, ...arguments). The operation is asynchronous and returns scheduling metadata, not the actor script's return value. Requires confirm=true.",category:ne,mutatesState:!0,input:T.object({actorPath:T.string().min(1),source:T.string().min(1).max(5e5),...Ar,confirm:T.boolean().default(!1),...se}),async execute({actorPath:e,source:t,arguments:n,confirm:r,threadContext:a},o){if(r!==!0)return Ke("run code on an Actor");let i=`
${ke}
if type(run_on_actor) ~= "function" then return { error = "run_on_actor is not available in this executor." } end
local actor, err = __evalActorExpression(${s(e)})
if err then return { error = err } end
if typeof(actor) ~= "Instance" or not actor:IsA("Actor") then return { error = "actorPath did not resolve to an Actor." } end
local args = { ${Pr(n)} }
local sourceText = ${s(t)}
local ok, failure = pcall(run_on_actor, actor, sourceText, table.unpack(args, 1, #args))
if not ok then return { error = "run_on_actor failed: " .. tostring(failure) } end
return { ok = true, scheduled = true, actor = __instanceInfo(actor), argumentCount = #args, sourceBytes = #sourceText }
`;return{data:await o.runLuau(i,{threadContext:a,timeoutMs:3e4})}}}),Ud=u({name:"get-lua-state",title:"Get the current, Actor, or script LuaStateProxy",description:"Call getluastate() for the current state, or getluastate(target) for an Actor/BaseScript expression. Returns serializable Id/IsActorState/Event/Actors metadata plus a reusable registry Reference.",category:ne,input:T.object({targetExpression:T.string().optional().default(""),...se}),async execute({targetExpression:e,threadContext:t},n){let r=`
${ke}
if type(getluastate) ~= "function" then return { error = "getluastate is not available in this executor." } end
local ok, state
if ${s(e)} == "" then
  ok, state = pcall(getluastate)
else
  local target, err = __evalActorExpression(${s(e)})
  if err then return { error = err } end
  ok, state = pcall(getluastate, target)
end
if not ok then return { error = "getluastate failed: " .. tostring(state) } end
local info, infoError = __stateInfo(state, true)
if infoError then return { error = infoError } end
info.ok = true
info.targetExpression = ${s(e)} ~= "" and ${s(e)} or nil
return info
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:2e4})}}}),jd=u({name:"get-game-state",title:"Get the default game LuaStateProxy",description:"Call getgamestate() and return Id/IsActorState/Event/Actors metadata plus a reusable registry Reference.",category:ne,input:T.object(se),async execute({threadContext:e},t){let n=`
${ke}
if type(getgamestate) ~= "function" then return { error = "getgamestate is not available in this executor." } end
local ok, state = pcall(getgamestate)
if not ok then return { error = "getgamestate failed: " .. tostring(state) } end
local info, infoError = __stateInfo(state, true)
if infoError then return { error = infoError } end
info.ok = true
info.gameState = true
return info
`;return{data:await t.runLuau(n,{threadContext:e,timeoutMs:2e4})}}}),Wd=u({name:"list-lua-states",title:"List every active LuaStateProxy",description:"Call getactorstates(), cap output at 256 states, and return compact state/actor metadata plus reusable References.",category:ne,input:T.object({includeActors:T.boolean().optional().default(!0),...se}),async execute({includeActors:e,threadContext:t},n){let r=`
${ke}
if type(getactorstates) ~= "function" then return { error = "getactorstates is not available in this executor." } end
local ok, states = pcall(getactorstates)
if not ok or type(states) ~= "table" then return { error = "getactorstates failed or did not return a table." } end
local out = {}
for i = 1, math.min(#states, 256) do
  local info = __stateInfo(states[i], ${e?"true":"false"})
  if info then out[#out + 1] = info end
end
return { ok = true, count = #states, returned = #out, truncated = #states > #out, states = out }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:3e4})}}}),Vd=u({name:"new-lua-state-proxy",title:"Construct a LuaStateProxy for the current state",description:"Call LuaStateProxy.new() and return serializable state metadata plus a retained Reference; no raw proxy crosses JSON.",category:ne,input:T.object(se),async execute({threadContext:e},t){let n=`
${ke}
if type(LuaStateProxy) ~= "table" or type(LuaStateProxy.new) ~= "function" then
  return { error = "LuaStateProxy.new is not available in this executor." }
end
local ok, state = pcall(LuaStateProxy.new)
if not ok then return { error = "LuaStateProxy.new failed: " .. tostring(state) } end
local info, infoError = __stateInfo(state, true)
if infoError then return { error = infoError } end
info.ok = true
info.constructed = true
return info
`;return{data:await t.runLuau(n,{threadContext:e,timeoutMs:2e4})}}}),Bd=u({name:"get-lua-state-actors",title:"List Actors associated with one LuaStateProxy",description:"Resolve current/game/expression state, call LuaStateProxy:GetActors(), and return at most 200 Actor paths.",category:ne,input:T.object({...Nr,...se}),async execute({state:e,stateExpression:t,threadContext:n},r){let a=`
${ke}
local proxy, err = __resolveState(${s(e)}, ${s(t)})
if err then return { error = err } end
local ok, actors = pcall(function() return proxy:GetActors() end)
if not ok or type(actors) ~= "table" then return { error = "LuaStateProxy:GetActors failed: " .. tostring(actors) } end
local out = {}
for i = 1, math.min(#actors, 200) do out[#out + 1] = __instanceInfo(actors[i]) end
local info = __stateInfo(proxy, false)
return { ok = true, state = info, count = #actors, returned = #out, truncated = #actors > #out, actors = out }
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:2e4})}}}),zd=u({name:"execute-lua-state",title:"Schedule source on a LuaStateProxy",description:"WRITES LIVE GAME STATE. Resolve current/game/expression state and call LuaStateProxy:Execute(source, ...args). Execution is asynchronous and confirmation-gated.",category:ne,mutatesState:!0,input:T.object({...Nr,source:T.string().min(1).max(5e5),...Ar,confirm:T.boolean().default(!1),...se}),async execute({state:e,stateExpression:t,source:n,arguments:r,confirm:a,threadContext:o},i){if(a!==!0)return Ke("execute code on a Lua state");let l=`
${ke}
local proxy, err = __resolveState(${s(e)}, ${s(t)})
if err then return { error = err } end
local args = { ${Pr(r)} }
local sourceText = ${s(n)}
local ok, failure = pcall(function() proxy:Execute(sourceText, table.unpack(args, 1, #args)) end)
if not ok then return { error = "LuaStateProxy:Execute failed: " .. tostring(failure) } end
return { ok = true, scheduled = true, state = __stateInfo(proxy, false), argumentCount = #args, sourceBytes = #sourceText }
`;return{data:await i.runLuau(l,{threadContext:o,timeoutMs:3e4})}}}),Kd=u({name:"fire-lua-state-event",title:"Fire a LuaStateProxy's cross-state Event",description:"WRITES LIVE GAME STATE. Resolve current/game/expression state and call state.Event:Fire(...typed arguments). Requires confirm=true because listeners may mutate live behavior.",category:ne,mutatesState:!0,input:T.object({...Nr,...Ar,confirm:T.boolean().default(!1),...se}),async execute({state:e,stateExpression:t,arguments:n,confirm:r,threadContext:a},o){if(r!==!0)return Ke("fire a Lua-state event");let i=`
${ke}
local proxy, err = __resolveState(${s(e)}, ${s(t)})
if err then return { error = err } end
local okEvent, event = pcall(function() return proxy.Event end)
if not okEvent or event == nil then return { error = "LuaStateProxy.Event is unavailable." } end
local args = { ${Pr(n)} }
local ok, failure = pcall(function() event:Fire(table.unpack(args, 1, #args)) end)
if not ok then return { error = "LuaStateProxy.Event:Fire failed: " .. tostring(failure) } end
return { ok = true, fired = true, state = __stateInfo(proxy, false), argumentCount = #args }
`;return{data:await o.runLuau(i,{threadContext:a,timeoutMs:2e4})}}}),Hd=u({name:"is-parallel-context",title:"Check whether the current executor thread is parallel",description:"Call isparallel/is_parallel and return a boolean without changing scheduler state.",category:ne,input:T.object(se),async execute({threadContext:e},t){return{data:await t.runLuau(`
local predicate = (type(isparallel) == "function" and isparallel) or (type(is_parallel) == "function" and is_parallel)
if type(predicate) ~= "function" then return { error = "isparallel/is_parallel is not available in this executor." } end
local ok, value = pcall(predicate)
if not ok then return { error = "isparallel failed: " .. tostring(value) } end
return { ok = true, isParallel = value == true }
`,{threadContext:e,timeoutMs:1e4})}}}),Xd=u({name:"create-comm-channel",title:"Create and retain an Actor communication channel",description:"WRITES LIVE GAME STATE. Call create_comm_channel(name?), retain the Channel in getgenv().__mcp_comm_channels, and return only its serializable identifier/metadata. Requires confirm=true.",category:ne,mutatesState:!0,input:T.object({name:T.string().max(96).optional().default(""),confirm:T.boolean().default(!1),...se}),async execute({name:e,confirm:t,threadContext:n},r){if(t!==!0)return Ke("create a communication channel");let a=`
if type(create_comm_channel) ~= "function" then return { error = "create_comm_channel is not available in this executor." } end
local name = ${s(e)}
local ok, id, channel
if name ~= "" then ok, id, channel = pcall(create_comm_channel, name) else ok, id, channel = pcall(create_comm_channel) end
if not ok then return { error = "create_comm_channel failed: " .. tostring(id) } end
if id == nil or channel == nil then return { error = "create_comm_channel did not return both id and channel." } end
if type(getgenv) == "function" then
  local okEnv, genv = pcall(getgenv)
  if okEnv and type(genv) == "table" then
    if type(genv.__mcp_comm_channels) ~= "table" then genv.__mcp_comm_channels = {} end
    genv.__mcp_comm_channels[tostring(id)] = channel
  end
end
local okEvent, event = pcall(function() return channel.Event end)
return { ok = true, id = tostring(id), name = name ~= "" and name or nil, channelType = typeof(channel), eventType = okEvent and typeof(event) or nil }
`;return{data:await r.runLuau(a,{threadContext:n,timeoutMs:15e3})}}}),Yd=u({name:"get-comm-channel",title:"Resolve an existing Actor communication channel",description:"Call get_comm_channel(id), falling back to the MCP channel registry, and return serializable channel/Event metadata.",category:ne,input:T.object({id:T.string().min(1).max(256),...se}),async execute({id:e,threadContext:t},n){let r=`
local id = ${s(e)}
local channel = nil
if type(get_comm_channel) == "function" then local ok, value = pcall(get_comm_channel, id); if ok then channel = value end end
if channel == nil and type(getgenv) == "function" then
  local ok, genv = pcall(getgenv)
  if ok and type(genv) == "table" and type(genv.__mcp_comm_channels) == "table" then channel = genv.__mcp_comm_channels[id] end
end
if channel == nil then return { error = "communication channel was not found." } end
local okEvent, event = pcall(function() return channel.Event end)
return { ok = true, id = id, channelType = typeof(channel), eventType = okEvent and typeof(event) or nil, hasEvent = okEvent and event ~= nil }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:1e4})}}}),Zd=u({name:"fire-comm-channel",title:"Send typed values through an Actor communication channel",description:"WRITES LIVE GAME STATE. Resolve get_comm_channel(id) and call Channel:Fire(...typed arguments). Requires confirm=true because channel listeners may execute arbitrary live behavior.",category:ne,mutatesState:!0,input:T.object({id:T.string().min(1).max(256),...Ar,confirm:T.boolean().default(!1),...se}),async execute({id:e,arguments:t,confirm:n,threadContext:r},a){if(n!==!0)return Ke("fire a communication channel");let o=`
local id = ${s(e)}
local channel = nil
if type(get_comm_channel) == "function" then local ok, value = pcall(get_comm_channel, id); if ok then channel = value end end
if channel == nil and type(getgenv) == "function" then
  local ok, genv = pcall(getgenv)
  if ok and type(genv) == "table" and type(genv.__mcp_comm_channels) == "table" then channel = genv.__mcp_comm_channels[id] end
end
if channel == nil then return { error = "communication channel was not found." } end
local args = { ${Pr(t)} }
local ok, failure = pcall(function() channel:Fire(table.unpack(args, 1, #args)) end)
if not ok then return { error = "Channel:Fire failed: " .. tostring(failure) } end
return { ok = true, id = id, fired = true, argumentCount = #args }
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:15e3})}}}),Aa={action:T.enum(["start","poll","stop"]),key:T.string().min(1).max(96).optional().default("default"),limit:T.number().int().min(1).max(ze).optional().default(100),clear:T.boolean().optional().default(!0),confirm:T.boolean().optional().default(!1),...se},Qd=u({name:"actor-event-monitor",title:"Monitor actor-ready and actor-state-created events",description:`WRITES LIVE GAME STATE when starting/stopping. Connect to on_actor_added and/or on_actor_state_created, retain a bounded ${ze}-event buffer, and poll it without repeated game-tree scans. Start/stop require confirm=true.`,category:ne,mutatesState:!0,input:T.object({...Aa,events:T.enum(["both","added","state-created"]).optional().default("both")}),async execute({action:e,key:t,limit:n,clear:r,confirm:a,events:o,threadContext:i},l){if(e!=="poll"&&a!==!0)return Ke(`${e} an actor event monitor`);let c=`
${ke}
if type(getgenv) ~= "function" then return { error = "getgenv is required for persistent actor monitors." } end
local okEnv, genv = pcall(getgenv)
if not okEnv or type(genv) ~= "table" then return { error = "getgenv failed." } end
if type(genv.__mcp_actor_event_monitors) ~= "table" then genv.__mcp_actor_event_monitors = {} end
local registry = genv.__mcp_actor_event_monitors
local key = ${s(t)}
local action = ${s(e)}
if action == "poll" then
  local monitor = registry[key]
  if not monitor then return { error = "actor event monitor key was not found." } end
  local values = __readMonitor(monitor, ${n}, ${r?"true":"false"})
  return { ok = true, key = key, running = true, buffered = #monitor.events, events = values }
end
if action == "stop" then
  local monitor = registry[key]
  if not monitor then return { error = "actor event monitor key was not found." } end
  for _, connection in ipairs(monitor.connections or {}) do __disconnect(connection) end
  local buffered = #monitor.events
  registry[key] = nil
  return { ok = true, key = key, stopped = true, buffered = buffered }
end
local previous = registry[key]
if previous then for _, connection in ipairs(previous.connections or {}) do __disconnect(connection) end end
local monitor = { events = {}, connections = {}, kinds = ${s(o)} }
local function record(kind, actor)
  local entry = { kind = kind, actor = __instanceInfo(actor), at = os.clock() }
  if kind == "state-created" and type(getluastate) == "function" then
    local okState, state = pcall(getluastate, actor)
    if okState then entry.state = __stateInfo(state, false) end
  end
  __pushBounded(monitor.events, entry)
end
local function connect(container, kind)
  if container == nil then return false end
  local okEvent, event = pcall(function() return container.Event end)
  local signal = (okEvent and event ~= nil) and event or container
  local okConnect, connection = pcall(function() return signal:Connect(function(actor) record(kind, actor) end) end)
  if okConnect and connection then monitor.connections[#monitor.connections + 1] = connection; return true end
  return false
end
local selected = ${s(o)}
local added = (selected == "both" or selected == "added") and connect(on_actor_added, "added") or false
local created = (selected == "both" or selected == "state-created") and connect(on_actor_state_created, "state-created") or false
if not added and not created then return { error = "requested actor event objects are unavailable." } end
registry[key] = monitor
return { ok = true, key = key, started = true, added = added, stateCreated = created, bufferLimit = ${ze} }
`;return{data:await l.runLuau(c,{threadContext:i,timeoutMs:2e4,env:"vm"})}}}),Jd=u({name:"comm-channel-monitor",title:"Monitor messages on an Actor communication channel",description:`WRITES LIVE GAME STATE when starting/stopping. Connect to Channel.Event, retain a bounded ${ze}-message buffer, and poll by monitor key. Start/stop require confirm=true.`,category:ne,mutatesState:!0,input:T.object({...Aa,id:T.string().max(256).optional().default("")}),async execute({action:e,key:t,id:n,limit:r,clear:a,confirm:o,threadContext:i},l){if(e!=="poll"&&o!==!0)return Ke(`${e} a channel monitor`);let c=`
${ke}
if type(getgenv) ~= "function" then return { error = "getgenv is required for persistent channel monitors." } end
local okEnv, genv = pcall(getgenv)
if not okEnv or type(genv) ~= "table" then return { error = "getgenv failed." } end
if type(genv.__mcp_comm_channel_monitors) ~= "table" then genv.__mcp_comm_channel_monitors = {} end
local registry = genv.__mcp_comm_channel_monitors
local key = ${s(t)}
local action = ${s(e)}
if action == "poll" then
  local monitor = registry[key]
  if not monitor then return { error = "channel monitor key was not found." } end
  local values = __readMonitor(monitor, ${r}, ${a?"true":"false"})
  return { ok = true, key = key, id = monitor.id, running = true, buffered = #monitor.events, events = values }
end
if action == "stop" then
  local monitor = registry[key]
  if not monitor then return { error = "channel monitor key was not found." } end
  __disconnect(monitor.connection)
  local buffered = #monitor.events
  registry[key] = nil
  return { ok = true, key = key, id = monitor.id, stopped = true, buffered = buffered }
end
local id = ${s(n)}
if id == "" then return { error = "id is required when starting a channel monitor." } end
local channel = nil
if type(get_comm_channel) == "function" then local ok, value = pcall(get_comm_channel, id); if ok then channel = value end end
if channel == nil and type(genv.__mcp_comm_channels) == "table" then channel = genv.__mcp_comm_channels[id] end
if channel == nil then return { error = "communication channel was not found." } end
local previous = registry[key]
if previous then __disconnect(previous.connection) end
local monitor = { id = id, events = {} }
local okEvent, event = pcall(function() return channel.Event end)
if not okEvent or event == nil then return { error = "Channel.Event is unavailable." } end
local okConnect, connection = pcall(function()
  return event:Connect(function(...)
    local packed = table.pack(...)
    local args = {}
    for i = 1, math.min(packed.n, 16) do args[i] = __eventValue(packed[i]) end
    __pushBounded(monitor.events, { at = os.clock(), argumentCount = packed.n, arguments = args, truncated = packed.n > 16 })
  end)
end)
if not okConnect or not connection then return { error = "Channel.Event:Connect failed: " .. tostring(connection) } end
monitor.connection = connection
registry[key] = monitor
return { ok = true, key = key, id = id, started = true, bufferLimit = ${ze} }
`;return{data:await l.runLuau(c,{threadContext:i,timeoutMs:2e4,env:"vm"})}}}),ep=u({name:"lua-state-event-monitor",title:"Monitor a LuaStateProxy's generic cross-state Event",description:`WRITES LIVE GAME STATE when starting/stopping. Connect to LuaStateProxy.Event, retain a bounded ${ze}-event buffer, and poll it by key. Start/stop require confirm=true.`,category:ne,mutatesState:!0,input:T.object({...Aa,...Nr}),async execute({action:e,key:t,limit:n,clear:r,confirm:a,state:o,stateExpression:i,threadContext:l},c){if(e!=="poll"&&a!==!0)return Ke(`${e} a Lua-state event monitor`);let d=o??"current",p=i??"",f=`
${ke}
if type(getgenv) ~= "function" then return { error = "getgenv is required for persistent state monitors." } end
local okEnv, genv = pcall(getgenv)
if not okEnv or type(genv) ~= "table" then return { error = "getgenv failed." } end
if type(genv.__mcp_lua_state_event_monitors) ~= "table" then genv.__mcp_lua_state_event_monitors = {} end
local registry = genv.__mcp_lua_state_event_monitors
local key = ${s(t)}
local action = ${s(e)}
if action == "poll" then
  local monitor = registry[key]
  if not monitor then return { error = "Lua-state event monitor key was not found." } end
  local values = __readMonitor(monitor, ${n}, ${r?"true":"false"})
  return { ok = true, key = key, state = monitor.stateInfo, running = true, buffered = #monitor.events, events = values }
end
if action == "stop" then
  local monitor = registry[key]
  if not monitor then return { error = "Lua-state event monitor key was not found." } end
  __disconnect(monitor.connection)
  local buffered = #monitor.events
  registry[key] = nil
  return { ok = true, key = key, stopped = true, buffered = buffered }
end
local proxy, err = __resolveState(${s(d)}, ${s(p)})
if err then return { error = err } end
local okEvent, event = pcall(function() return proxy.Event end)
if not okEvent or event == nil then return { error = "LuaStateProxy.Event is unavailable." } end
local previous = registry[key]
if previous then __disconnect(previous.connection) end
local monitor = { events = {}, stateInfo = __stateInfo(proxy, false) }
local okConnect, connection = pcall(function()
  return event:Connect(function(...)
    local packed = table.pack(...)
    local args = {}
    for i = 1, math.min(packed.n, 16) do args[i] = __eventValue(packed[i]) end
    __pushBounded(monitor.events, { at = os.clock(), argumentCount = packed.n, arguments = args, truncated = packed.n > 16 })
  end)
end)
if not okConnect or not connection then return { error = "LuaStateProxy.Event:Connect failed: " .. tostring(connection) } end
monitor.connection = connection
registry[key] = monitor
return { ok = true, key = key, state = monitor.stateInfo, started = true, bufferLimit = ${ze} }
`;return{data:await c.runLuau(f,{threadContext:l,timeoutMs:2e4,env:"vm"})}}}),J=[Gd,Dd,Ud,jd,Wd,Vd,Bd,zd,Kd,Hd,Xd,Yd,Zd,Qd,Jd,ep];import{z as Fn}from"zod";var V=`
local __H = game:GetService("HttpService")

local function __name(inst)
  local ok, n = pcall(function() return inst.Name end)
  return ok and tostring(n) or "?"
end
local function __class(inst)
  local ok, c = pcall(function() return inst.ClassName end)
  return ok and c or "?"
end
local function __parent(inst)
  local ok, p = pcall(function() return inst.Parent end)
  if ok then return p end
  return nil
end
local function __fullName(inst)
  local ok, n = pcall(function() return inst:GetFullName() end)
  if ok then return n end
  return "<" .. __class(inst) .. " " .. __name(inst) .. ">"
end
-- Reachable from the DataModel (game)? If not, it is detached / hidden.
local function __inTree(inst)
  local cur = inst
  for _ = 1, 128 do
    if cur == game then return true end
    local p = __parent(cur)
    if p == nil then return false end
    cur = p
  end
  return false
end
local function __isA(inst, cls)
  local ok, r = pcall(function() return inst:IsA(cls) end)
  return ok and r
end
local function __ancestorActor(inst)
  local ok, a = pcall(function() return inst:FindFirstAncestorOfClass("Actor") end)
  if ok and a then return a end
  return nil
end
-- Where does this instance "live"? Used to explain how something is hidden.
local function __location(inst)
  local par = __parent(inst)
  if par == nil then return "nil-parented" end
  if not __inTree(inst) then return "detached (not under game)" end
  local actor = __ancestorActor(inst)
  if actor then return "inside Actor: " .. __fullName(actor) end
  local okCore, cg = pcall(function() return game:GetService("CoreGui") end)
  if okCore and cg and __isA(inst, "Instance") then
    local cur = inst
    for _ = 1, 64 do if cur == cg then return "CoreGui" end; cur = __parent(cur); if cur == nil then break end end
  end
  return "in tree"
end
`;var tc=u({name:"find-detached-instances",title:"Find detached instances (in registry, off the DataModel)",description:"Walk every instance the executor can see (getinstances) and report the ones that are DETACHED from the running game \u2014 i.e. they exist in the executor's instance registry but pcall(inst.IsDescendantOf, inst, game) returns false, so they are not reachable from the DataModel. This catches objects that were Destroy()'d or reparented to nil yet kept alive by a lingering reference, plus anything an anti-detection script has stashed off the hierarchy. An optional className filter narrows the walk to a single ClassName (matched via IsA so subclasses are included). Unlike find-hidden-instances (which uses an ancestor-walk to test reachability), this tool uses IsDescendantOf against game directly, supports a class filter, and always reports a full byClass breakdown across ALL detached instances. Returns { totalDetached, byClass, truncated, samples: [{ class, name }] }. Requires getinstances; degrades with a clear error otherwise.",category:"Actors & Hidden",input:Fn.object({className:Fn.string().describe("Optional ClassName to filter to, e.g. 'RemoteEvent', 'LocalScript', 'ScreenGui', 'Part'. Matched with inst:IsA(className) so subclasses are included. Omit to report detached instances of every class.").optional(),limit:Fn.number().int().describe("Max number of detailed sample instances to return in the samples list (default 200, clamped to 2000). The totalDetached count and byClass tally always cover every detached instance found regardless of this limit.").optional().default(200),maxScan:Fn.number().int().describe("Max number of instances to examine from getinstances() before stopping (default 60000, clamped to 500000). Protects against huge games; if hit, `truncated` is set true.").optional().default(6e4),threadContext:Fn.number().int().optional()}),async execute({className:e,limit:t,maxScan:n,threadContext:r},a){let o=typeof e=="string"&&e.trim().length>0,i=Math.min(Math.max(Math.floor(t),1),2e3),l=Math.min(Math.max(Math.floor(n),1),5e5),c=`
${V}
if type(getinstances) ~= "function" then
  return { error = "getinstances is not available in this executor." }
end

local okI, all = pcall(getinstances)
if not okI or type(all) ~= "table" then
  return { error = "getinstances() call failed or returned no table." }
end

local SAMPLE_CAP = ${i}
local SCAN_CAP = ${l}
local hasFilter = ${o?"true":"false"}
local filterClass = ${o?s(e??""):"nil"}

local totalDetached = 0
local scanned = 0
local truncated = false
local byClass = {}
local samples = {}

-- Detached = exists in the registry but not a descendant of game.
local function isDetached(inst)
  local ok, res = pcall(function() return inst:IsDescendantOf(game) end)
  if not ok then
    -- Could not even test it; treat as detached/suspect rather than dropping it.
    return true
  end
  return res == false
end

for _, inst in all do
  scanned = scanned + 1
  if scanned > SCAN_CAP then
    truncated = true
    break
  end
  if hasFilter and not __isA(inst, filterClass) then
    -- skip; not the class we are filtering for
  else
    if isDetached(inst) then
      totalDetached = totalDetached + 1
      local cls = __class(inst)
      byClass[cls] = (byClass[cls] or 0) + 1
      if #samples < SAMPLE_CAP then
        samples[#samples + 1] = {
          class = cls,
          name = __name(inst),
        }
      end
    end
  end
end

if totalDetached > #samples then truncated = true end

return {
  totalDetached = totalDetached,
  scannedApprox = scanned,
  byClass = byClass,
  truncated = truncated,
  samples = samples,
}
`;return{data:await a.runLuau(c,{threadContext:r,timeoutMs:45e3})}}});import{z as nc}from"zod";var rc=u({name:"find-hidden-guis",title:"Find hidden GUI containers",description:"Surface GUI overlays/menus that are hidden away from the normal PlayerGui hierarchy \u2014 the classic home of cheat menus, ESP overlays, and anti-detection UIs. Scans every nil-parented instance (getnilinstances) and the children of CoreGui, keeping anything that is a GUI container (LayerCollector / ScreenGui / BillboardGui / SurfaceGui / any GuiBase2d). Each hit reports its name, class, full path, and where it is hidden (location: nil-parented, CoreGui, detached, inside an Actor, etc.). Results are deduped. Requires getnilinstances for the nil sweep; the CoreGui sweep still runs even if getnilinstances is missing.",category:"Actors & Hidden",input:nc.object({threadContext:nc.number().int().optional()}),async execute({threadContext:e},t){let n=`
${V}
local GUI_CLASSES = { "LayerCollector", "ScreenGui", "BillboardGui", "SurfaceGui", "GuiBase2d" }
local function __isGui(inst)
  for _, cls in GUI_CLASSES do
    if __isA(inst, cls) then return true end
  end
  return false
end

local guis = {}
local seen = {}
local truncated = false
local CAP = 200

local function consider(inst)
  if inst == nil or seen[inst] then return end
  seen[inst] = true
  if not __isGui(inst) then return end
  if #guis >= CAP then
    truncated = true
    return
  end
  guis[#guis + 1] = {
    name = __name(inst),
    class = __class(inst),
    location = __location(inst),
    fullName = __fullName(inst),
  }
end

-- 1) Nil-parented instances (guarded; may be unavailable).
if type(getnilinstances) == "function" then
  local okN, nils = pcall(getnilinstances)
  if okN and type(nils) == "table" then
    for _, inst in nils do consider(inst) end
  end
end

-- 2) Children of CoreGui (always attempted; pcall-guarded).
local okCore, cg = pcall(function() return game:GetService("CoreGui") end)
if okCore and cg then
  local okKids, kids = pcall(function() return cg:GetDescendants() end)
  if okKids and type(kids) == "table" then
    for _, inst in kids do consider(inst) end
  end
end

return { count = #guis, truncated = truncated, guis = guis }
`;return{data:await t.runLuau(n,{threadContext:e,timeoutMs:3e4})}}});import{z as $r}from"zod";var ac=u({name:"find-hidden-instances",title:"Find hidden / detached instances",description:"Enumerate EVERY instance the executor can see (getinstances \u2014 this includes objects that are not reachable from the game DataModel) and report the ones that are hidden: nil-parented, detached from the game tree, or buried inside an Actor / CoreGui. An instance is considered hidden when it is not reachable from `game` (__inTree is false). Returns a per-class tally (byClass) plus a capped list of samples, each describing the instance's class, name, full path, and exactly how it is hidden (location). This is the broadest sweep for anything an exploit/anti-detection script has stashed off the normal hierarchy. Requires getinstances; degrades with a clear error otherwise.",category:"Actors & Hidden",input:$r.object({limit:$r.number().int().describe("Max number of detailed sample instances to return (default 500, clamped to 3000). The byClass tally always counts every hidden instance found regardless of this limit.").optional().default(500),maxScan:$r.number().int().describe("Max number of instances to examine from getinstances before stopping (default 60000). Protects against huge games; if hit, `truncated` is set true and scannedApprox reflects how many were inspected.").optional().default(6e4),threadContext:$r.number().int().optional()}),async execute({limit:e,maxScan:t,threadContext:n},r){let a=Math.min(Math.max(Math.floor(e),1),3e3),o=Math.min(Math.max(Math.floor(t),1),5e5),i=`
${V}
if type(getinstances) ~= "function" then
  return { error = "getinstances is not available in this executor." }
end

local okI, all = pcall(getinstances)
if not okI or type(all) ~= "table" then
  return { error = "getinstances() call failed or returned no table." }
end

local SAMPLE_CAP = ${a}
local SCAN_CAP = ${o}

local hiddenCount = 0
local scanned = 0
local truncated = false
local byClass = {}
local samples = {}

for _, inst in all do
  scanned = scanned + 1
  if scanned > SCAN_CAP then
    truncated = true
    break
  end
  local okHidden, isHidden = pcall(function() return not __inTree(inst) end)
  if okHidden and isHidden then
    hiddenCount = hiddenCount + 1
    local cls = __class(inst)
    byClass[cls] = (byClass[cls] or 0) + 1
    if #samples < SAMPLE_CAP then
      samples[#samples + 1] = {
        class = cls,
        name = __name(inst),
        fullName = __fullName(inst),
        location = __location(inst),
      }
    end
  end
end

if hiddenCount > #samples then truncated = true end

return {
  hiddenCount = hiddenCount,
  scannedApprox = scanned,
  truncated = truncated,
  byClass = byClass,
  samples = samples,
}
`;return{data:await r.runLuau(i,{threadContext:n,timeoutMs:45e3})}}});import{z as Fr}from"zod";var oc=u({name:"find-hidden-remotes",title:"Find hidden Remote / Bindable channels",description:"Find RemoteEvent / RemoteFunction / UnreliableRemoteEvent / BindableEvent / BindableFunction instances that are NOT in the normal game tree \u2014 i.e. nil-parented or detached from the DataModel. A remote/bindable kept alive by a reference but hidden off the hierarchy is a classic backdoor / data-exfiltration channel: an exploit or malicious script fires it to phone home or to receive commands without the object ever appearing in the Explorer. This tool pulls getnilinstances() (the primary source of nil-parented objects) and, when getinstances() is available, also includes any remote/bindable that is not a descendant of `game`, deduping across both sources. It complements get-nil-instances / find-hidden-instances by narrowing to just the communication-channel classes and giving a ready-to-inspect list. Returns { count, byClass, truncated, samples: [{ class, name, location }] }, capped. Requires getnilinstances; getinstances is used additionally when present. Degrades with a clear error if neither is available.",category:"Actors & Hidden",input:Fr.object({limit:Fr.number().int().describe("Max number of detailed sample remotes/bindables to return in the samples list (default 200, clamped to 2000). The count and byClass tally always cover every hidden remote/bindable found regardless of this limit.").optional().default(200),maxScan:Fr.number().int().describe("Max number of instances to examine from getinstances() before stopping the getinstances pass (default 60000, clamped to 500000). Protects against huge games; if hit, `truncated` is set true. The getnilinstances pass is always fully scanned.").optional().default(6e4),threadContext:Fr.number().int().optional()}),async execute({limit:e,maxScan:t,threadContext:n},r){let a=Math.min(Math.max(Math.floor(e),1),2e3),o=Math.min(Math.max(Math.floor(t),1),5e5),i=`
${V}
local hasNil = type(getnilinstances) == "function"
local hasAll = type(getinstances) == "function"
if not hasNil and not hasAll then
  return { error = "Neither getnilinstances nor getinstances is available in this executor." }
end

local SAMPLE_CAP = ${a}
local SCAN_CAP = ${o}

-- Communication-channel classes we care about.
local WANT = {
  RemoteEvent = true,
  RemoteFunction = true,
  UnreliableRemoteEvent = true,
  BindableEvent = true,
  BindableFunction = true,
}

local function isWanted(inst)
  local cls = __class(inst)
  if WANT[cls] then return true, cls end
  -- Fall back to IsA so subclasses / odd ClassName reads are still caught.
  for c, _ in WANT do
    if __isA(inst, c) then return true, c end
  end
  return false, cls
end

local count = 0
local truncated = false
local byClass = {}
local samples = {}
local seen = {}

local function consider(inst)
  if inst == nil then return end
  if seen[inst] then return end
  seen[inst] = true
  -- Only count a remote/bindable as "hidden" if it is actually off the tree.
  local okHidden, hidden = pcall(function() return not __inTree(inst) end)
  if not okHidden or not hidden then return end
  local wanted, cls = isWanted(inst)
  if not wanted then return end
  count = count + 1
  byClass[cls] = (byClass[cls] or 0) + 1
  if #samples < SAMPLE_CAP then
    samples[#samples + 1] = {
      class = cls,
      name = __name(inst),
      location = __location(inst),
    }
  end
end

-- Pass 1: nil-parented instances (always fully scanned).
if hasNil then
  local okN, nils = pcall(getnilinstances)
  if okN and type(nils) == "table" then
    for _, inst in nils do
      consider(inst)
    end
  end
end

-- Pass 2: any remote/bindable in getinstances() that is not under game.
if hasAll then
  local okI, all = pcall(getinstances)
  if okI and type(all) == "table" then
    local scanned = 0
    for _, inst in all do
      scanned = scanned + 1
      if scanned > SCAN_CAP then
        truncated = true
        break
      end
      consider(inst)
    end
  end
end

if count > #samples then truncated = true end

return {
  count = count,
  byClass = byClass,
  truncated = truncated,
  samples = samples,
}
`;return{data:await r.runLuau(i,{threadContext:n,timeoutMs:45e3})}}});import{z as Na}from"zod";var ic=u({name:"find-hidden-scripts",title:"Find scripts that are hiding",description:"Scan ALL scripts (getscripts) and currently-running scripts (getrunningscripts) and report the ones that are trying to hide \u2014 i.e. not sitting normally in the game tree: nil-parented, detached from the DataModel, running inside an Actor (parallel-Luau VM), living in CoreGui, or destroyed-but-still-executing. Each result gives the script's name, class, where it actually lives, and whether it is currently running. This is the go-to tool for finding malicious/obfuscated/anti-detection scripts that hide outside the normal hierarchy. Requires getscripts/getrunningscripts; degrades with a clear error otherwise.",category:"Actors & Hidden",input:Na.object({maxScan:Na.number().int().describe("Max scripts to examine from getscripts (default 6000). Running scripts are always checked first.").optional().default(6e3),threadContext:Na.number().int().optional()}),async execute({maxScan:e,threadContext:t},n){let r=Math.min(Math.max(Math.floor(e),1),2e4),a=`
${V}
if type(getscripts) ~= "function" and type(getrunningscripts) ~= "function" then
  return { error = "getscripts/getrunningscripts are not available in this executor." }
end

local results = {}
local seen = {}
local running = {}
local okR, rs = pcall(getrunningscripts)
if okR and type(rs) == "table" then for _, s in rs do running[s] = true end end

local function consider(s)
  if seen[s] then return end
  seen[s] = true
  if not __isA(s, "LuaSourceContainer") then return end
  local loc = __location(s)
  local isRunning = running[s] == true
  -- "hiding" = not a normal in-tree script, OR a running script with no live parent.
  if loc ~= "in tree" or (isRunning and __parent(s) == nil) then
    results[#results + 1] = {
      name = __name(s),
      class = __class(s),
      location = loc,
      running = isRunning,
      fullName = __fullName(s),
    }
  end
end

if okR and type(rs) == "table" then for _, s in rs do consider(s) end end
local okS, all = pcall(getscripts)
if okS and type(all) == "table" then
  local n = 0
  for _, s in all do
    n = n + 1
    if n > ${r} then break end
    consider(s)
  end
end

local out = {}
for i = 1, math.min(#results, 300) do out[i] = results[i] end
return { hiddenCount = #results, truncated = #results > 300, scripts = out }
`;return{data:await n.runLuau(a,{threadContext:t,timeoutMs:3e4})}}});import{z as sc}from"zod";var lc=u({name:"find-running-scripts",title:"List currently-running scripts",description:"List every script that is currently executing (getrunningscripts), including ones that are not visible in the normal hierarchy \u2014 nil-parented, detached from the DataModel, running inside an Actor, or living in CoreGui. For each running script this returns its name, class, full path, where it actually lives (location), and whether it is still reachable from the game tree (inTree). This surfaces active anti-detection / obfuscated logic that is running but hidden from the Explorer. Requires getrunningscripts; degrades with a clear error otherwise. Output is capped at 300 scripts with a truncated flag.",category:"Actors & Hidden",input:sc.object({threadContext:sc.number().int().optional()}),async execute({threadContext:e},t){let n=`
${V}
if type(getrunningscripts) ~= "function" then
  return { error = "getrunningscripts is not available in this executor." }
end

local okR, running = pcall(getrunningscripts)
if not okR or type(running) ~= "table" then
  return { error = "getrunningscripts() failed or returned no table." }
end

local out = {}
local total = 0
for _, s in running do
  total = total + 1
  if #out < 300 then
    out[#out + 1] = {
      name = __name(s),
      class = __class(s),
      fullName = __fullName(s),
      location = __location(s),
      inTree = __inTree(s),
    }
  end
end

return { runningCount = total, truncated = total > #out, scripts = out }
`;return{data:await t.runLuau(n,{threadContext:e,timeoutMs:3e4})}}});import{z as Pa}from"zod";var cc=u({name:"get-actor-details",title:"Inspect Actor(s) and their scripts",description:"Drill into Actor instances (parallel-Luau VMs) and report their contents. Actors run code in isolated VMs outside the normal serial scheduler, so they are a common place to hide logic. Give an actorPath to inspect ONE Actor in detail, or omit it to summarize EVERY Actor (getactors). For each Actor this returns its name, where it lives (in tree / nil-parented / detached / inside CoreGui), how many descendants it has, and a list (capped at 30 per Actor) of the LuaSourceContainer scripts inside it \u2014 each with name, class, full path, and whether the script is currently executing (running, determined by membership in getrunningscripts). This complements list-actors by adding the running flag, the descendant count, and single-target resolution from a Luau expression. Requires getactors; getrunningscripts is used additionally when present (running falls back to false if it is unavailable). Returns a single Actor object when actorPath is given, otherwise { actorCount, truncated, actors: [...] }. Degrades with a clear error if getactors is missing or actorPath does not resolve to an Actor.",category:"Actors & Hidden",input:Pa.object({actorPath:Pa.string().describe("Optional Luau expression resolving to a single Actor to inspect, e.g. 'workspace.MyModel.Actor' or 'getactors()[1]'. Evaluated as `return <actorPath>` and validated to be an Instance that IsA('Actor'). If omitted, ALL actors from getactors() are summarized.").optional(),threadContext:Pa.number().int().optional()}),async execute({actorPath:e,threadContext:t},n){let r=typeof e=="string"&&e.trim().length>0,a=`
${k}
${V}
if type(getactors) ~= "function" then
  return { error = "getactors is not available in this executor." }
end

-- Build a fast lookup set of currently-running scripts (if available).
local runningSet = {}
if type(getrunningscripts) == "function" then
  local okR, rs = pcall(getrunningscripts)
  if okR and type(rs) == "table" then
    for _, s in rs do runningSet[s] = true end
  end
end

local SCRIPT_CAP = 30

local function describeActor(actor)
  local entry = {
    name = __name(actor),
    location = __location(actor),
    descendantCount = 0,
    scripts = {},
  }
  local okD, descendants = pcall(function() return actor:GetDescendants() end)
  if okD and type(descendants) == "table" then
    local scriptCount = 0
    for _, d in descendants do
      entry.descendantCount = entry.descendantCount + 1
      if __isA(d, "LuaSourceContainer") then
        scriptCount = scriptCount + 1
        if #entry.scripts < SCRIPT_CAP then
          entry.scripts[#entry.scripts + 1] = {
            name = __name(d),
            class = __class(d),
            path = __fullName(d),
            running = runningSet[d] == true,
          }
        end
      end
    end
    entry.scriptCount = scriptCount
    entry.scriptsTruncated = scriptCount > #entry.scripts
  end
  return entry
end

local single = ${r?"true":"false"}
if single then
  local actor, err = __eval(${s(e??"")})
  if err then return { error = err } end
  if typeof(actor) ~= "Instance" then
    return { error = "actorPath did not resolve to an Instance (got " .. typeof(actor) .. ")." }
  end
  if not __isA(actor, "Actor") then
    return { error = "actorPath resolved to a " .. __class(actor) .. ", not an Actor." }
  end
  return describeActor(actor)
end

local okA, actors = pcall(getactors)
if not okA or type(actors) ~= "table" then
  return { error = "getactors() failed or returned no table." }
end

local out = {}
local total = 0
for _, actor in actors do
  total = total + 1
  if #out < 200 then
    out[#out + 1] = describeActor(actor)
  end
end

return { actorCount = total, truncated = total > #out, actors = out }
`;return{data:await n.runLuau(a,{threadContext:t,timeoutMs:3e4})}}});import{z as $a}from"zod";var uc=u({name:"get-nil-instances",title:"List nil-parented (hidden) instances",description:"Enumerate instances whose Parent is nil (getnilinstances). Nil-parenting is a classic hiding spot: a remote, script, GUI, or other object is kept alive by a reference but is unreachable from the game tree, so it never shows up in the Explorer or normal descendant scans. This returns the total count, a byClass breakdown (ClassName -> count) computed across ALL nil instances, and a capped samples list (each with class, name, and full path) for inspection. Requires getnilinstances; degrades with a clear error otherwise.",category:"Actors & Hidden",input:$a.object({limit:$a.number().int().describe("Max number of sample instances to return in the samples list (default 500, max 3000). The byClass counts and total always cover every nil instance regardless of this limit.").optional().default(500),threadContext:$a.number().int().optional()}),async execute({limit:e,threadContext:t},n){let r=Math.min(Math.max(Math.floor(e),1),3e3),a=`
${V}
if type(getnilinstances) ~= "function" then
  return { error = "getnilinstances is not available in this executor." }
end

local okN, nils = pcall(getnilinstances)
if not okN or type(nils) ~= "table" then
  return { error = "getnilinstances() failed or returned no table." }
end

local byClass = {}
local samples = {}
local total = 0
for _, inst in nils do
  total = total + 1
  local cls = __class(inst)
  byClass[cls] = (byClass[cls] or 0) + 1
  if #samples < ${r} then
    samples[#samples + 1] = {
      class = cls,
      name = __name(inst),
      fullName = __fullName(inst),
    }
  end
end

return { total = total, byClass = byClass, truncated = total > #samples, samples = samples }
`;return{data:await n.runLuau(a,{threadContext:t,timeoutMs:3e4})}}});import{z as Fa}from"zod";var dc=u({name:"list-actors",title:"List Actor scripts (parallel-Luau VMs)",description:"Enumerate every Actor instance in the game (getactors). Actors run code in isolated parallel-Luau VMs, so scripts inside them execute outside the normal serial scheduler and are a common place to hide logic. For each Actor this returns its name, full path, where it lives (in tree / nil-parented / detached / CoreGui), how many LuaSourceContainer descendants it has, and \u2014 when includeScripts is true \u2014 a capped list (30 per Actor) of those scripts with their name, class, and full path. Requires getactors; degrades with a clear error otherwise. Output is capped at 200 actors with a truncated flag.",category:"Actors & Hidden",input:Fa.object({includeScripts:Fa.boolean().describe("If true (default), list each Actor's descendant LuaSourceContainers (scripts), capped at 30 per actor. Set false for a lighter scan that only reports counts.").optional().default(!0),threadContext:Fa.number().int().optional()}),async execute({includeScripts:e,threadContext:t},n){let r=`
${V}
if type(getactors) ~= "function" then
  return { error = "getactors is not available in this executor." }
end

local includeScripts = ${e?"true":"false"}
local okA, actors = pcall(getactors)
if not okA or type(actors) ~= "table" then
  return { error = "getactors() failed or returned no table." }
end

local out = {}
local total = 0
for _, actor in actors do
  total = total + 1
  if #out < 200 then
    local entry = {
      name = __name(actor),
      fullName = __fullName(actor),
      location = __location(actor),
      scriptCount = 0,
    }
    local scripts = {}
    local okD, descendants = pcall(function() return actor:GetDescendants() end)
    if okD and type(descendants) == "table" then
      for _, d in descendants do
        if __isA(d, "LuaSourceContainer") then
          entry.scriptCount = entry.scriptCount + 1
          if includeScripts and #scripts < 30 then
            scripts[#scripts + 1] = {
              name = __name(d),
              class = __class(d),
              fullName = __fullName(d),
            }
          end
        end
      end
    end
    if includeScripts then entry.scripts = scripts end
    out[#out + 1] = entry
  end
end

return { actorCount = total, truncated = total > #out, actors = out }
`;return{data:await n.runLuau(r,{threadContext:t,timeoutMs:3e4})}}});import{z as pc}from"zod";var fc=u({name:"summarize-hidden-surfaces",title:"Summarize hidden surfaces (what is hiding)",description:"One-call high-level overview answering 'what is hiding in this game?'. Safely (each executor call guarded + pcall'd) counts: Actors (parallel-Luau VMs), nil-parented instances (with a small top-classes breakdown), currently-running scripts, loaded modules, and a quick count of scripts that are NOT sitting normally in the tree (hiddenScripts). Any executor function that is unavailable in this executor is listed under `unavailable` instead of aborting the whole summary. Use this first to decide which deeper hidden-* tool to run next.",category:"Actors & Hidden",input:pc.object({threadContext:pc.number().int().optional()}),async execute({threadContext:e},t){let n=`
${V}
local unavailable = {}

-- Generic guarded counter: returns count or nil (and records unavailability).
local function safeCount(fnName, fn)
  if type(fn) ~= "function" then
    unavailable[#unavailable + 1] = fnName
    return nil
  end
  local ok, res = pcall(fn)
  if not ok or type(res) ~= "table" then return nil end
  return #res, res
end

-- Actors.
local actors = safeCount("getactors", getactors)

-- Nil-parented instances + top-classes breakdown.
local nilInstances, nilTopClasses
do
  if type(getnilinstances) ~= "function" then
    unavailable[#unavailable + 1] = "getnilinstances"
  else
    local ok, res = pcall(getnilinstances)
    if ok and type(res) == "table" then
      nilInstances = #res
      local counts = {}
      for _, inst in res do
        local cls = __class(inst)
        counts[cls] = (counts[cls] or 0) + 1
      end
      -- Reduce to a small sorted top-list.
      local arr = {}
      for cls, n in counts do arr[#arr + 1] = { class = cls, count = n } end
      table.sort(arr, function(a, b) return a.count > b.count end)
      nilTopClasses = {}
      for i = 1, math.min(#arr, 8) do nilTopClasses[i] = arr[i] end
    end
  end
end

-- Running scripts (also reused for the hidden-script scan).
local runningScripts, runningList
do
  local c, res = safeCount("getrunningscripts", getrunningscripts)
  runningScripts = c
  runningList = res
end

-- Loaded modules.
local loadedModules = safeCount("getloadedmodules", getloadedmodules)

-- Quick hidden-script count: any script not living "in tree".
local hiddenScripts = nil
do
  local available = (type(getrunningscripts) == "function") or (type(getscripts) == "function")
  if available then
    local count = 0
    local seen = {}
    local function consider(s)
      if s == nil or seen[s] then return end
      seen[s] = true
      if not __isA(s, "LuaSourceContainer") then return end
      local okLoc, loc = pcall(__location, s)
      if okLoc and loc ~= "in tree" then count = count + 1 end
    end
    if type(runningList) == "table" then
      for _, s in runningList do consider(s) end
    end
    if type(getscripts) == "function" then
      local okS, all = pcall(getscripts)
      if okS and type(all) == "table" then
        local n = 0
        for _, s in all do
          n = n + 1
          if n > 6000 then break end
          consider(s)
        end
      end
    end
    hiddenScripts = count
  else
    unavailable[#unavailable + 1] = "getscripts"
  end
end

return {
  actors = actors,
  nilInstances = nilInstances,
  nilTopClasses = nilTopClasses,
  runningScripts = runningScripts,
  loadedModules = loadedModules,
  hiddenScripts = hiddenScripts,
  unavailable = unavailable,
}
`;return{data:await t.runLuau(n,{threadContext:e,timeoutMs:3e4})}}});import{z as On}from"zod";var mc=u({name:"dump-table",title:"Recursively dump a Luau table",description:"Resolve a Luau expression to a TABLE and recursively encode its contents to a chosen depth. Scalar, Instance and function values are encoded via the shared encoder; nested tables are recursed into until maxDepth, after which they collapse to 'table: <addr> (truncated)'. Each level is capped at maxKeys (the cap is noted via a per-level Truncated flag), and cycles are detected so self-referential tables won't loop forever. Ideal for reading config tables, getgenv()/getrenv() subtables, a ModuleScript's return value, or any captured upvalue table you already have a handle on. WARNING: this ACTS ON THE LIVE GAME \u2014 it evaluates your expression in the running client, which may trigger __index metamethods or other side effects while iterating. Returns { Target, Depth, Table:<nested>, Truncated } or { error }.",category:"Actions",input:On.object({tablePath:On.string().describe("Luau expression resolving to a table, e.g. 'getgenv()', 'getrenv()._G', 'require(game.ReplicatedStorage.Config)', 'getrawmetatable(game)', or 'debug.getupvalues(someFn)[1]'. Evaluated as `return <tablePath>` and must yield a table."),maxDepth:On.number().int().min(1).max(5).describe("How many levels of nested tables to recurse into (default 2, max 5). Beyond this depth, nested tables are rendered as 'table: <addr> (truncated)' rather than expanded.").optional().default(2),maxKeys:On.number().int().min(1).max(500).describe("Maximum number of keys to encode PER table level (default 100, max 500). When a level has more keys than this, the extras are dropped and that level is flagged Truncated = true.").optional().default(100),threadContext:On.number().int().optional()}),async execute({tablePath:e,maxDepth:t,maxKeys:n,threadContext:r},a){let o=`
${k}
local __maxDepth = ${t}
local __maxKeys = ${n}
local __truncatedAny = false

local function __dump(tbl, depth, seen)
  if type(tbl) ~= "table" then return __encVal(tbl) end
  if seen[tbl] then return "table: " .. tostring(tbl) .. " (cycle)" end
  if depth > __maxDepth then
    __truncatedAny = true
    return "table: " .. tostring(tbl) .. " (truncated)"
  end
  seen[tbl] = true
  local out = {}
  local count = 0
  local levelTruncated = false
  local okIter = pcall(function()
    for k, v in pairs(tbl) do
      count = count + 1
      if count > __maxKeys then
        levelTruncated = true
        __truncatedAny = true
        break
      end
      local key = tostring(k)
      if type(v) == "table" then
        out[key] = __dump(v, depth + 1, seen)
      else
        out[key] = __encVal(v)
      end
    end
  end)
  if not okIter then out.__iterError = "failed to iterate table" end
  if levelTruncated then out.__truncated = true end
  seen[tbl] = nil
  return out
end

local target, err = __eval(${s(e)})
if err then return { error = err } end
if type(target) ~= "table" then
  return { error = "expression did not resolve to a table (got " .. typeof(target) .. "): " .. ${s(e)} }
end

local okDump, dumped = pcall(__dump, target, 1, {})
if not okDump then return { error = "failed to dump table: " .. tostring(dumped) } end

return {
  Target = ${s(e)},
  Depth = __maxDepth,
  Table = dumped,
  Truncated = __truncatedAny,
}
`;return{data:await a.runLuau(o,{threadContext:r,timeoutMs:2e4})}}});import{z as Or}from"zod";var hc=u({name:"get-thread-stack",title:"Walk a thread/coroutine's call stack",description:"Walk the call stack of a Luau thread/coroutine frame-by-frame using debug.info. For each level it reports the function Name, Source, and Line (debug.info(thread, level, 'nsl')), stopping when the stack is exhausted. If threadPath is omitted it traces the CURRENT injected thread instead, using debug.info(level, 'nsl'). A debug.traceback() string is also included when available. Use this to see exactly where a suspended coroutine or an event handler's thread is currently executing \u2014 e.g. pass a connection's .Thread, a stored coroutine, or leave it blank to inspect your own execution context. WARNING: this ACTS ON THE LIVE GAME \u2014 it evaluates your threadPath expression and introspects live thread state in the running client. Returns { Thread?, FrameCount, Frames:[{ Level, Name, Source, Line }], Traceback? } or { error }.",category:"Actions",input:Or.object({threadPath:Or.string().describe("Optional Luau expression resolving to a thread/coroutine, e.g. 'getconnections(game.Workspace.Part.Touched)[1].Thread', 'getgenv().myCoroutine', or 'coroutine.running()'. Evaluated as `return <threadPath>`. If omitted, the current injected thread is traced instead.").optional(),maxLevels:Or.number().int().min(1).max(60).describe("Maximum number of stack levels to walk before stopping (default 20, max 60). Walking stops early once debug.info returns nil for a level (top of stack reached).").optional().default(20),threadContext:Or.number().int().optional()}),async execute({threadPath:e,maxLevels:t,threadContext:n},r){let a=typeof e=="string"&&e.length>0,o=`
${k}
local __maxLevels = ${t}

if not __hasDebug or type(__d.info) ~= "function" then
  return { error = "debug.info is not available in this executor; cannot walk thread stacks." }
end

local __thread = nil
local __hasThreadArg = ${a?"true":"false"}
if __hasThreadArg then
  local t, err = __eval(${a?s(e):'""'})
  if err then return { error = err } end
  if typeof(t) ~= "thread" then
    return { error = "expression did not resolve to a thread (got " .. typeof(t) .. "): " .. ${a?s(e):'""'} }
  end
  __thread = t
end

local frames = {}
for level = 1, __maxLevels do
  local ok, name, source, line
  if __thread ~= nil then
    ok, name, source, line = pcall(__d.info, __thread, level, "nsl")
  else
    ok, name, source, line = pcall(__d.info, level, "nsl")
  end
  if not ok then break end
  if name == nil and source == nil and line == nil then break end
  frames[#frames + 1] = {
    Level = level,
    Name = (name ~= nil and tostring(name)) or "",
    Source = (source ~= nil and tostring(source)) or "",
    Line = (type(line) == "number" and line) or -1,
  }
end

local traceback = nil
if type(debug) == "table" and type(debug.traceback) == "function" then
  local okTb, tb = pcall(function()
    if __thread ~= nil then return debug.traceback(__thread) end
    return debug.traceback()
  end)
  if okTb and tb ~= nil then traceback = tostring(tb) end
end

return {
  Thread = __hasThreadArg and ${a?s(e):'"<current>"'} or "<current>",
  FrameCount = #frames,
  Frames = frames,
  Traceback = traceback,
}
`;return{data:await r.runLuau(o,{threadContext:n,timeoutMs:2e4})}}});import{z as xe}from"zod";var tp=xe.object({kind:xe.enum(["string","number","boolean","nil","raw"]).describe("How to interpret `value`. 'string'/'number'/'boolean' pass that literal scalar. 'nil' passes nil (ignores `value`). 'raw' treats `value` as a Luau expression \u2014 use for non-primitive arguments (Vector3, Color3, Enum, Instance references, etc.)."),value:xe.union([xe.string(),xe.number(),xe.boolean()]).describe("The literal value (for string/number/boolean) or, when kind='raw', a Luau expression string such as 'Vector3.new(0,50,0)', 'Enum.Material.Neon', or 'game.Workspace.Part'. Omit entirely when kind='nil'.").optional()}).describe("A single method argument, expressed as a typed value."),gc=u({name:"invoke-method",title:"Call a method on a live Instance",description:"ACTS ON LIVE GAME STATE. Resolve a Luau expression to an Instance and call one of its methods as a colon-call (inst:Method(args...)), returning whatever the method returns. Useful while debugging for :Destroy(), :GetChildren(), :FindFirstChild(name), :Clone(), :GetAttribute(name), :SetAttribute(name, value), :WaitForChild(name), Humanoid:TakeDamage(n), Humanoid:MoveTo(pos), Tool:Activate(), etc. Each argument is a typed value; use kind='raw' for non-primitive arguments (Vector3, Enum, Instance, ...). The call is pcall-guarded. WARNING: many methods MUTATE the game (e.g. :Destroy(), :SetAttribute, :TakeDamage) and the effect is immediate and may replicate \u2014 only call methods you understand. Returns { Path, Method, ok, ReturnValues } or { error }.",category:"Actions",mutatesState:!0,input:xe.object({instancePath:xe.string().describe("Luau expression resolving to the Instance to call the method on, e.g. 'game.Workspace.Part', 'game.Players.LocalPlayer.Character.Humanoid', or 'game:GetService(\"Lighting\")'. Evaluated as `return <instancePath>`."),methodName:xe.string().describe("The exact method name to call (case-sensitive), e.g. 'Destroy', 'GetChildren', 'FindFirstChild', 'Clone', 'GetAttribute', 'SetAttribute', 'TakeDamage'. Invoked as a colon-call so `self` is the instance."),args:xe.array(tp).describe("Ordered list of arguments passed to the method after `self`. Omit or pass [] for a no-argument call like :Destroy() or :GetChildren().").optional(),threadContext:xe.number().int().optional()}),async execute({instancePath:e,methodName:t,args:n,threadContext:r},a){let i=(n??[]).map(te).join(", "),l=`
${k}
local inst, err = __eval(${s(e)})
if err then return { error = err } end
if typeof(inst) ~= "Instance" then return { error = "expression did not resolve to an Instance (got " .. typeof(inst) .. "): " .. ${s(e)} } end

local method = ${s(t)}
local fn = inst[method]
if type(fn) ~= "function" then return { error = "'" .. method .. "' is not a callable method on this Instance (got " .. typeof(fn) .. ")." } end

local path = ${s(e)}
local okName, full = pcall(function() return inst:GetFullName() end)
if okName then path = full end

local results = table.pack(pcall(function() return inst[method](inst${i?", "+i:""}) end))
local okCall = results[1]
if not okCall then return { error = "method '" .. method .. "' raised an error: " .. tostring(results[2]) } end

local returns = {}
for i = 2, results.n do returns[#returns + 1] = __encVal(results[i]) end

return {
  Path = path,
  Method = method,
  ok = true,
  ReturnValues = returns,
}
`;return{data:await a.runLuau(l,{threadContext:r,timeoutMs:2e4})}}});import{mkdirSync as np,readFileSync as rp,readdirSync as ap,statSync as op,unlinkSync as ip,writeFileSync as sp,existsSync as Oa}from"node:fs";import{homedir as lp}from"node:os";import{join as qa,resolve as cp}from"node:path";var up=/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$/,Ga=class{dir;constructor(t){this.dir=cp(t??qa(lp(),".executor-mcp","playbooks"));try{np(this.dir,{recursive:!0})}catch{}}pathFor(t){if(!up.test(t))throw new Ue(`Invalid playbook name "${t}". Use letters, digits, _ and -; 1\u201364 chars.`);return qa(this.dir,t+".json")}async save(t){let n=this.pathFor(t.name),r=Date.now(),a=Oa(n)?this.readOne(n):null,o={name:t.name,source:t.source,...t.description!==void 0?{description:t.description}:{},...t.tags!==void 0?{tags:t.tags}:{},...t.params!==void 0?{params:t.params}:{},createdAt:a?.createdAt??r,updatedAt:r};return sp(n,JSON.stringify(o,null,2),"utf8"),o}get(t){let n;try{n=this.pathFor(t)}catch{return Promise.resolve(null)}return Oa(n)?Promise.resolve(this.readOne(n)):Promise.resolve(null)}list(t){let n;try{n=ap(this.dir)}catch{return Promise.resolve([])}let r=[];for(let a of n)if(a.endsWith(".json"))try{let o=this.readOne(qa(this.dir,a));if(t?.tag&&!(o.tags??[]).includes(t.tag))continue;r.push(o)}catch{}return r.sort((a,o)=>(o.updatedAt??0)-(a.updatedAt??0)),Promise.resolve(r)}delete(t){let n;try{n=this.pathFor(t)}catch{return Promise.resolve(!1)}if(!Oa(n))return Promise.resolve(!1);try{return ip(n),Promise.resolve(!0)}catch{return Promise.resolve(!1)}}readOne(t){let n=rp(t,"utf8"),r=JSON.parse(n);if(r.updatedAt===void 0){let a=op(t);return{...r,updatedAt:a.mtimeMs,createdAt:r.createdAt??a.ctimeMs}}return r}};var Da=class{#e;#t=new Map;constructor(t){this.#e=t.embeddings}async search(t,n,r,a){let o=this.#n(t),i=new Map;for(let p of a)i.set(fp(p.text),p);for(let p of[...o.keys()])i.has(p)||o.delete(p);let l=[];for(let[p,f]of i)o.has(p)||l.push({hash:p,document:f});if(l.length>0)try{let p=await this.#e.embed(l.map(f=>f.document.text));l.forEach((f,h)=>{let g=p[h];g!==void 0&&o.set(f.hash,{path:f.document.path,vector:g,snippet:dp(f.document.text)})})}catch{return[]}if(o.size===0)return[];let c;try{let f=(await this.#e.embed([n]))[0];if(f===void 0)return[];c=f}catch{return[]}let d=[];for(let p of o.values())d.push({path:p.path,score:pp(c,p.vector),snippet:p.snippet});return d.sort((p,f)=>f.score-p.score),d.slice(0,Math.max(0,r))}stats(t){let r=this.#t.get(t)?.size??0;return{indexed:r>0,documentCount:r,model:this.#e.model,dimensions:this.#e.dimensions}}clear(t){this.#t.delete(t)}#n(t){let n=this.#t.get(t);return n===void 0&&(n=new Map,this.#t.set(t,n)),n}};function dp(e){return e.slice(0,200)}function pp(e,t){let n=Math.min(e.length,t.length),r=0,a=0,o=0;for(let i=0;i<n;i++){let l=e[i]??0,c=t[i]??0;r+=l*c,a+=l*l,o+=c*c}return a===0||o===0?0:r/(Math.sqrt(a)*Math.sqrt(o))}function fp(e){let t=2166136261;for(let n=0;n<e.length;n++)t^=e.charCodeAt(n),t=Math.imul(t,16777619);return(t>>>0).toString(16)}var mp="local-hash",Ua=class{model;#e;#t;constructor(t){this.#t=t.embeddingsUrl,t.embeddingsUrl===null?(this.model=mp,this.#e=256):(this.model=t.embeddingsModel,this.#e=null)}get dimensions(){return this.#e}async embed(t){if(t.length===0)return[];if(this.#t===null)return t.map(o=>hp(o,256));let n=this.#t,r=n.endsWith("/api/embeddings"),a=[];for(let o of t){let i=r?await this.#n(n,o):await this.#r(n,o);a.push(i)}if(a.length>0){let o=a[0];o!==void 0&&(this.#e=o.length)}return a}async#n(t,n){let r=await fetch(t,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({model:this.model,prompt:n})});if(!r.ok)throw new Error(`Embeddings request failed: ${r.status} ${r.statusText}`);let a=await r.json();return bc(a.embedding)}async#r(t,n){let r=await fetch(t,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({model:this.model,input:n})});if(!r.ok)throw new Error(`Embeddings request failed: ${r.status} ${r.statusText}`);let o=(await r.json()).data?.[0];return bc(o?.embedding)}};function bc(e){if(!Array.isArray(e))throw new Error("Embeddings response did not contain a numeric vector.");return e.map(n=>{if(typeof n!="number"||!Number.isFinite(n))throw new Error("Embeddings response vector contained a non-finite value.");return n})}function hp(e,t){let n=new Array(t).fill(0),r=e.toLowerCase().match(/[a-z0-9_]+/g);if(r!==null)for(let o of r){let i=gp(o)%t;n[i]=(n[i]??0)+1}let a=0;for(let o of n)a+=o*o;return a=Math.sqrt(a),a===0?n:n.map(o=>o/a)}function gp(e){let t=2166136261;for(let n=0;n<e.length;n++)t^=e.charCodeAt(n),t=Math.imul(t,16777619);return t>>>0}var wT=[Qa,Ja,eo,to,no,ro,ao,oo,io,so,lo,co,uo,po,fo,mo,ho,go,bo,yo,vo,ko,xo,_o,wo,Io,To,Ro,Mo,Lo,Ao,No,Po,$o,Fo,Oo,qo,Go,Do,Uo,jo,Wo,Vo,Bo,zo,Ko,Ho,Xo,Yo,Qo,Jo,ei,ti,ai,oi,ii,si,ci,ui,di,pi,fi,mi,hi,gi,bi,yi,vi,ki,xi,_i,wi,Si,Ei,Ii,Ti,Ri,Mi,Li,Ai,Pi,$i,Fi,Oi,Gi,Di,Ui,ji,Wi,Bi,zi,Ki,Hi,Xi,Zi,Qi,Ji,H[0],H[1],H[2],H[3],H[4],H[5],H[6],H[7],H[8],H[9],H[10],H[11],H[12],H[13],H[14],H[15],H[16],es,ts,ns,rs,as,os,is,ss,ls,cs,us,ds,fs,ms,hs,gs,bs,ys,vs,ks,xs,_s,ws,Ss,Es,Cs,As,Fs,Ds,js,tl,sl,ll,ul,dl,pl,fl,ml,hl,gl,bl,yl,vl,kl,xl,_l,wl,Sl,El,Il,Tl,Ml,Ll,$l,Fl,Ol,ql,Gl,Dl,jl,Wl,Vl,Bl,Kl,Xl,Yl,Zl,Ql,ec,J[0],J[1],J[2],J[3],J[4],J[5],J[6],J[7],J[8],J[9],J[10],J[11],J[12],J[13],J[14],J[15],tc,rc,ac,oc,ic,lc,cc,uc,dc,fc,mc,hc,gc];export{Ga as FsSavedScriptsStore,Ua as HttpEmbeddingsProvider,Da as InMemorySemanticIndex,wT as importedTools};

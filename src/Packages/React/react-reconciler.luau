-- jsdotlua/react-reconciler@17.2.1; see THIRD_PARTY_NOTICES.md
return {
["react-reconciler/DebugTracing"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/43363e2795393a00fd77312a16d6b80e626c29de/packages/react-reconciler/src/DebugTracing.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

type Array<T> = { [number]: T }
type Map<K, V> = { [K]: V }
type Object = { [string]: any }
type Function = (any) -> any?
local Shared = require(script.Parent.Parent:WaitForChild('shared'))
local console = Shared.console
local exports = {}

-- ROBLOX deviation: hoist log so it's visible
local log
-- ROBLOX deviation: the nucelus emoji `(%c\u{269B}\u{FE0F}%c)` has been replaced with `*`

local ReactFiberLaneModule = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lane = ReactFiberLaneModule.Lane
type Lanes = ReactFiberLaneModule.Lanes
type Wakeable = Shared.Wakeable

local enableDebugTracing =
	require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.enableDebugTracing

local nativeConsole: Object = console
local nativeConsoleLog: nil | Function 

local pendingGroupArgs: Array<any> = {}
-- ROBLOX deviation: adjust starting indea for Lua 1-based arrays
local printedGroupIndex: number = 0

-- ROBLOX deviation: Luau has no built-in way to convert decimal number to binary string
function decimalToBinaryString(decimal: number): string
	local result = ""
	repeat
		local divres = decimal / 2
		local int, frac = math.modf(divres)
		decimal = int
		result = math.ceil(frac) .. result
	until decimal == 0

	local nbZero = 31 - string.len(result)
	return string.rep("0", nbZero) .. result
end

local function formatLanes(laneOrLanes: Lane | Lanes): string
	return "0b"
		-- ROBLOX deviation: Luau has no built-in way to convert decimal number to binary string
		.. decimalToBinaryString(laneOrLanes)
end

local function group(...): ()
	for _, groupArg in { ... } do
		table.insert(pendingGroupArgs, groupArg)
	end
	if nativeConsoleLog == nil then
		nativeConsoleLog = nativeConsole.log
		nativeConsole.log = log
	end
end

local function groupEnd(): ()
	table.remove(pendingGroupArgs, 1)
	while printedGroupIndex > #pendingGroupArgs do
		nativeConsole.groupEnd()
		printedGroupIndex -= 1
	end
	if #pendingGroupArgs == 0 then
		nativeConsole.log = nativeConsoleLog
		nativeConsoleLog = nil
	end
end

function log(...): ()
	if printedGroupIndex < #pendingGroupArgs then
		for i = printedGroupIndex + 1, #pendingGroupArgs do
			local groupArgs = pendingGroupArgs[i]
			nativeConsole.group(groupArgs)
		end
		printedGroupIndex = #pendingGroupArgs
	end
	if typeof(nativeConsoleLog) == "function" then
		(nativeConsoleLog :: any)(...)
	else
		nativeConsole.log(...)
	end
end

-- ROBLOX deviation: remove color styling
local REACT_LOGO_STYLE = ""

local function logCommitStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* commit (%s)", formatLanes(lanes)),
				REACT_LOGO_STYLE,
				"",
				-- ROBLOX deviation: remove style
				""
			)
		end
	end
end
exports.logCommitStarted = logCommitStarted

local function logCommitStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logCommitStopped = logCommitStopped

-- ROBLOX deviation: use raw Lua table
-- const PossiblyWeakMap = typeof WeakMap === 'function' ? WeakMap : Map;
-- $FlowFixMe: Flow cannot handle polymorphic WeakMaps

-- ROBLOX TODO: restore the color message formatting from upstream
-- local wakeableIDs: Map<Wakeable, number> = {}
-- local wakeableID: number = 0
-- local function getWakeableID(wakeable: Wakeable): number
-- 	if not wakeableIDs[wakeable] ~= nil then
-- 		wakeableIDs[wakeable] =
-- 			(function()
-- 				local result = wakeableID
-- 				wakeableID += 1
-- 				return result
-- 			end)()
-- 	end
-- 	return wakeableIDs[wakeable]
-- end

local function logComponentSuspended(componentName: string, wakeable: Wakeable): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			-- local _id = getWakeableID(wakeable)
			-- ROBLOX deviation: our Wakeable can be a function or a callable table
			-- local _display = wakeable.displayName or wakeable
			log(
				string.format("* %s suspended", componentName)
				-- REACT_LOGO_STYLE,
				-- ROBLOX deviation: remove color styling
				-- "",
				-- id,
				-- display
			)
			wakeable:andThen(function()
				log(
					string.format("* %s resolved", componentName)
					-- REACT_LOGO_STYLE,
					-- ROBLOX deviation: remove color styling
					-- "",
					-- id,
					-- display
				)
			end, function()
				log(
					string.format("* %s rejected", componentName)
					-- REACT_LOGO_STYLE,
					-- ROBLOX deviation: remove color styling
					-- "",
					-- id,
					-- display
				)
			end)
		end
	end
end
exports.logComponentSuspended = logComponentSuspended

local function logLayoutEffectsStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* layout effects (%s)", formatLanes(lanes))
				-- REACT_LOGO_STYLE,
				-- "",
				-- ROBLOX deviation: strip color styling
				-- ""
			)
		end
	end
end
exports.logLayoutEffectsStarted = logLayoutEffectsStarted

local function logLayoutEffectsStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logLayoutEffectsStopped = logLayoutEffectsStopped

local function logPassiveEffectsStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* passive effects (%s)", formatLanes(lanes))
				-- REACT_LOGO_STYLE,
				-- "",
				-- ROBLOX deviation: strip color styling
				-- ""
			)
		end
	end
end
exports.logPassiveEffectsStarted = logPassiveEffectsStarted

local function logPassiveEffectsStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logPassiveEffectsStopped = logPassiveEffectsStopped

local function logRenderStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* render (%s)", formatLanes(lanes))
				-- REACT_LOGO_STYLE,
				-- "",
				-- ROBLOX deviation: strip color styling
				-- ""
			)
		end
	end
end
exports.logRenderStarted = logRenderStarted

local function logRenderStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logRenderStopped = logRenderStopped

local function logForceUpdateScheduled(componentName: string, lane: Lane): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			log(
				string.format("* %s forced update (%s)", componentName, formatLanes(lane))
				-- REACT_LOGO_STYLE,
				-- ROBLOX deviation: strip color styling
				-- "",
				-- ""
			)
		end
	end
end
exports.logForceUpdateScheduled = logForceUpdateScheduled

local function logStateUpdateScheduled(
	componentName: string,
	lane: Lane,
	payloadOrAction: any
): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			log(
				string.format("* %s updated state (%s)", componentName, formatLanes(lane))
				-- REACT_LOGO_STYLE,
				-- ROBLOX deviation: strip color styling
				-- "",
				-- "",
				-- payloadOrAction
			)
		end
	end
end
exports.logStateUpdateScheduled = logStateUpdateScheduled
return exports

end,
["react-reconciler/forks/ReactFiberHostConfig.test"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/b87aabdfe1b7461e7331abb3601d9e6bb27544bc/packages/react-reconciler/src/forks/ReactFiberHostConfig.test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

return require("@pkg/@jsdotlua/react-test-renderer")

end,
["react-reconciler"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/43363e2795393a00fd77312a16d6b80e626c29de/packages/react-reconciler/src/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

--!strict
local ReactInternalTypes = require(script:WaitForChild('ReactInternalTypes'))
local ReactRootTags = require(script:WaitForChild('ReactRootTags'))

export type Dispatcher = ReactInternalTypes.Dispatcher
export type Fiber = ReactInternalTypes.Fiber
export type FiberRoot = ReactInternalTypes.FiberRoot

-- ROBLOX deviation: explicit export for use in createReactNoop
export type UpdateQueue<T> = ReactInternalTypes.UpdateQueue<T>

export type RootTag = ReactRootTags.RootTag

-- ROBLOX deviation: In order to allow host config to be spliced in, we export
-- this top-level package as an initializer function that returns the configured
-- reconciler module
-- ROBLOX TODO: this effectively disconnects type checking from above to reconciler to below
local function initialize(config): { [string]: any }
	local ReactFiberHostConfig = require(script:WaitForChild('ReactFiberHostConfig'))	
for name, implementation in config do
		ReactFiberHostConfig[name] = implementation
	end

	return require(script:WaitForChild('ReactFiberReconciler'))
end

return initialize

end,
["react-reconciler/MaxInts"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/MaxInts.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

-- // Max 31 bit integer. The max integer size in V8 for 32-bit systems.
-- // Math.pow(2, 30) - 1
-- // 0b111111111111111111111111111111
return { MAX_SIGNED_31_BIT_INT = 1073741823 }

end,
["react-reconciler/ReactCapturedValue"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactCapturedValue.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber

local getStackByFiberInDevAndProd =
	require(script.Parent:WaitForChild('ReactFiberComponentStack')).getStackByFiberInDevAndProd

export type CapturedValue<T> = {
	value: T,
	source: Fiber | nil,
	stack: string | nil
}

local exports = {}

exports.createCapturedValue = function<T>(value: T, source: Fiber | nil): CapturedValue<T>
	-- If the value is an error, call this function immediately after it is thrown
	-- so the stack is accurate.
	return {
		value = value,
		source = source,
		stack = getStackByFiberInDevAndProd(source),
	}
end

return exports

end,
["react-reconciler/ReactChildFiber.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactChildFiber.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local __DEV__ = _G.__DEV__ :: boolean
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
type Array<T> = { [number]: T }
type Set<T> = { [T]: boolean }
type Object = { [any]: any }
type Map<K, V> = { [K]: V }
-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes

type ReactElement = ReactTypes.ReactElement<any, any>
type ReactPortal = ReactTypes.ReactPortal

local React = require(script.Parent.Parent:WaitForChild('react'))
type LazyComponent<T, P> = React.LazyComponent<T, P>

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type RoactStableKey = ReactInternalTypes.RoactStableKey
local ReactFiberLanes = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLanes.Lanes

local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local Placement = ReactFiberFlags.Placement
local Deletion = ReactFiberFlags.Deletion
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local getIteratorFn = ReactSymbols.getIteratorFn
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_PORTAL_TYPE = ReactSymbols.REACT_PORTAL_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local Block = ReactWorkTags.Block
local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
-- ROBLOX deviation: we do not support string refs
-- local warnAboutStringRefs = ReactFeatureFlags.warnAboutStringRefs
local enableLazyElements = ReactFeatureFlags.enableLazyElements
local enableBlocksAPI = ReactFeatureFlags.enableBlocksAPI

local ReactFiber = require(script.Parent:WaitForChild('ReactFiber.new'))
local createWorkInProgress = ReactFiber.createWorkInProgress
local resetWorkInProgress = ReactFiber.resetWorkInProgress
local createFiberFromElement = ReactFiber.createFiberFromElement
local createFiberFromFragment = ReactFiber.createFiberFromFragment
local createFiberFromText = ReactFiber.createFiberFromText
local createFiberFromPortal = ReactFiber.createFiberFromPortal
-- ROBLOX deviation: we do not support string refs
-- local emptyRefsObject =
-- 	require("./ReactFiberClassComponent.new.luau").emptyRefsObject
-- local ReactFiberHotReloading = require("./ReactFiberHotReloading.new.luau")
-- local isCompatibleFamilyForHotReloading =
-- 	ReactFiberHotReloading.isCompatibleFamilyForHotReloading
-- ROBLOX deviation: we do not support string refs, which removes our use of StrictMode
-- local StrictMode = require("./ReactTypeOfMode").StrictMode

local exports = {}

local didWarnAboutMaps
-- ROBLOX deviation: Lua doesn't have built-in generators
-- local didWarnAboutGenerators
-- ROBLOX deviation: we do not support string refs
-- local didWarnAboutStringRefs
local ownerHasKeyUseWarning
local ownerHasFunctionTypeWarning
local warnForMissingKey = function(child: any, returnFiber: Fiber) end

if __DEV__ then
	didWarnAboutMaps = false
	-- ROBLOX deviation: Lua doesn't have built-in generators
	--   didWarnAboutGenerators = false

	-- ROBLOX deviation: we do not support string refs
	-- didWarnAboutStringRefs = {}

	--[[
	Warn if there's no key explicitly set on dynamic arrays of children or
	object keys are not valid. This allows us to keep track of children between
	updates.
  ]]
	ownerHasKeyUseWarning = {}
	ownerHasFunctionTypeWarning = {}

	-- ROBLOX FIXME: This may need to change depending on how we want children to
	-- be passed. Current Roact accepts a table (keys are built-in) and leaves
	-- ordering up to users via LayoutOrder, but if we accept arrays (and attempt
	-- to somehow map them to LayoutOrder??) we'll need keys for stability
	warnForMissingKey = function(child: any, returnFiber: Fiber)
		if child == nil or type(child) ~= "table" then
			return
		end
		if not child._store or child._store.validated or child.key ~= nil then
			return
		end
		invariant(
			child._store ~= nil and type(child._store) == "table",
[[React Component in warnForMissingKey should have a _store. This error is likely caused by a bug in React. Please file an issue.]]		

)
		child._store.validated = true

		local componentName = getComponentName(returnFiber.type) or "Component"

		if ownerHasKeyUseWarning[componentName] then
			return
		end
		ownerHasKeyUseWarning[componentName] = true

		console.error(
[[Each child in a list should have a unique "key" prop. See https://reactjs.org/link/warning-keys for more information.]]		


)
	end
end

local isArray = Array.isArray

function coerceRef(returnFiber: Fiber, current: Fiber | nil, element: ReactElement)
	local mixedRef = element.ref
	if mixedRef ~= nil and type(mixedRef) == "string" then
		-- ROBLOX deviation: we do not support string refs, and will not coerce
		if
			not element._owner
			or not element._self
			or element._owner.stateNode == element._self
		then
			-- ROBLOX performance: don't get component name unless we have to use it
			local componentName
			if __DEV__ then
				componentName = getComponentName(returnFiber.type) or "Component"
			else
				componentName = "<enable __DEV__ mode for component names>"
			end
			error(
				Error.new(
					string.format(
[[Component "%s" contains the string ref "%s". Support for string refs has been removed. We recommend using useRef() or createRef() instead. Learn more about using refs safely here: https://reactjs.org/link/strict-mode-string-ref]]




,
						componentName,
						tostring(mixedRef)
					)
				)
			)
		end

		if not element._owner then
			error(
				"Expected ref to be a function or an object returned by React.createRef(), or nil."
			)
		end

		-- if __DEV__ then
		-- 	-- TODO: Clean this up once we turn on the string ref warning for
		-- 	-- everyone, because the strict mode case will no longer be relevant
		-- 	if
		-- 		(bit32.band(returnFiber.mode, StrictMode) ~= 0 or warnAboutStringRefs)
		-- 		-- We warn in ReactElement.js if owner and self are equal for string refs
		-- 		-- because these cannot be automatically converted to an arrow function
		-- 		-- using a codemod. Therefore, we don't have to warn about string refs again.
		-- 		and not (
		-- 			element._owner
		-- 			and element._self
		-- 			and element._owner.stateNode ~= element._self
		-- 		)
		-- 	then
		-- 		local componentName = getComponentName(returnFiber.type) or "Component"
		-- 		if not didWarnAboutStringRefs[componentName] then
		-- 			if warnAboutStringRefs then
		-- 				console.error(
		-- 					'Component "%s" contains the string ref "%s". Support for string refs '
		-- 						.. "will be removed in a future major release. We recommend using "
		-- 						.. "useRef() or createRef() instead. "
		-- 						.. "Learn more about using refs safely here: "
		-- 						.. "https://reactjs.org/link/strict-mode-string-ref",
		-- 					componentName,
		-- 					mixedRef
		-- 				)
		-- 			else
		-- 				console.error(
		-- 					'A string ref, "%s", has been found within a strict mode tree. '
		-- 						.. "String refs are a source of potential bugs and should be avoided. "
		-- 						.. "We recommend using useRef() or createRef() instead. "
		-- 						.. "Learn more about using refs safely here: "
		-- 						.. "https://reactjs.org/link/strict-mode-string-ref",
		-- 					mixedRef
		-- 				)
		-- 			end
		-- 			didWarnAboutStringRefs[componentName] = true
		-- 		end
		-- 	end
		-- end

		-- if element._owner then
		-- 	local owner: Fiber? = element._owner
		-- 	local inst
		-- 	if owner then
		-- 		local ownerFiber = owner
		-- 		invariant(
		-- 			ownerFiber.tag == ClassComponent,
		-- 			"Function components cannot have string refs. "
		-- 				.. "We recommend using useRef() instead. "
		-- 				.. "Learn more about using refs safely here: "
		-- 				.. "https://reactjs.org/link/strict-mode-string-ref"
		-- 		)
		-- 		inst = ownerFiber.stateNode
		-- 	end
		-- 	invariant(
		-- 		inst,
		-- 		"Missing owner for string ref %s. This error is likely caused by a "
		-- 			.. "bug in React. Please file an issue.",
		-- 		mixedRef
		-- 	)

		-- 	-- ROBLOX deviation: explicitly convert to string
		-- 	local stringRef = tostring(mixedRef)
		-- 	-- Check if previous string ref matches new string ref
		-- 	if
		-- 		current ~= nil
		-- 		and (current :: Fiber).ref ~= nil
		-- 		-- ROBLOX deviation: Lua doesn't support fields on functions, so invert this check
		-- 		-- typeof((current :: Fiber).ref) == 'function' and
		-- 		and typeof((current :: Fiber).ref) ~= "function"
		-- 		-- ROBLOX deviation: this partially inlines the ref type from Fiber to workaround Luau refinement issues
		-- 		and ((current :: Fiber).ref :: { _stringRef: string? })._stringRef
		-- 			== stringRef
		-- 	then
		-- 		return (current :: Fiber).ref
		-- 	end
		-- 	-- ROBLOX deviation: make ref a callable table rather than a function
		-- 	local callableRef = function(value)
		-- 		local refs = inst.__refs
		-- 		if refs == emptyRefsObject then
		-- 			-- This is a lazy pooled frozen object, so we need to initialize.
		-- 			inst.__refs = {}
		-- 			refs = inst.__refs
		-- 		end
		-- 		if value == nil then
		-- 			refs[stringRef] = nil
		-- 		else
		-- 			refs[stringRef] = value
		-- 		end
		-- 	end
		-- 	local ref = setmetatable({}, { __call = callableRef })
		-- 	ref._stringRef = stringRef
		-- 	return ref
		-- else
		-- 	invariant(
		-- 		typeof(mixedRef) == "string",
		-- 		"Expected ref to be a function, a string, an object returned by React.createRef(), or nil."
		-- 	)
		-- 	invariant(
		-- 		element._owner,
		-- 		"Element ref was specified as a string (%s) but no owner was set. This could happen for one of"
		-- 			.. " the following reasons:\n"
		-- 			.. "1. You may be adding a ref to a function component\n"
		-- 			.. "2. You may be adding a ref to a component that was not created inside a component's render method\n"
		-- 			.. "3. You have multiple copies of React loaded\n"
		-- 			.. "See https://reactjs.org/link/refs-must-have-owner for more information.",
		-- 		mixedRef
		-- 	)
		-- end
	end
	return mixedRef
end

-- ROBLOX performance: all uses commented out
-- local function throwOnInvalidObjectType(returnFiber: Fiber, newChild: { [any]: any })
-- 	if returnFiber.type ~= "textarea" then
-- ROBLOX FIXME: Need to adjust this to check for "table: <address>" instead
-- and print appropriately
-- unimplemented("throwOnInvalidObjectType textarea")

-- ROBLOX TODO: This is likely a bigger deviation; in Roact today, we allow
-- tables and use the keys as equivalents to the `key` prop
-- invariant(
--   false,
--   "Objects are not valid as a React child (found: %s). " ..
--     "If you meant to render a collection of children, use an array " ..
--     "instead.",
--   tostring(newChild) == "[object Object]"
--     ? "object with keys {" + Object.keys(newChild).join(", ") + "}"
--     : newChild,
-- )
-- 	end
-- end

local function warnOnFunctionType(returnFiber: Fiber)
	if __DEV__ then
		local componentName = getComponentName(returnFiber.type) or "Component"

		if ownerHasFunctionTypeWarning[componentName] then
			return
		end
		ownerHasFunctionTypeWarning[componentName] = true

		console.error(
[[Functions are not valid as a React child. This may happen if you return a Component instead of <Component /> from render. Or maybe you meant to call this function rather than return it.]]		


)
	end
end

-- // We avoid inlining this to avoid potential deopts from using try/catch.
-- /** @noinline */
function resolveLazyType<T, P>(lazyComponent: LazyComponent<T, P>): LazyComponent<T, P> | T
	-- ROBLOX performance: hoist non-throwable lines so we eliminate an anon function for the pcall
	-- If we can, let's peek at the resulting type.
	local payload = lazyComponent._payload
	local init = lazyComponent._init
	local ok, result = xpcall(init, describeError, payload)
	if not ok then
		-- Leave it in place and let it throw again in the begin phase.
		return lazyComponent
	end

	return result
end

-- This wrapper function exists because I expect to clone the code in each path
-- to be able to optimize each path individually by branching early. This needs
-- a compiler or we can do it manually. Helpers that don't need this branching
-- live outside of this function.
local function ChildReconciler(shouldTrackSideEffects)
	local function deleteChild(returnFiber: Fiber, childToDelete: Fiber)
		if not shouldTrackSideEffects then
			-- Noop.
			return
		end
		local deletions = returnFiber.deletions
		if deletions == nil then
			returnFiber.deletions = { childToDelete }
			returnFiber.flags = bit32.bor(returnFiber.flags, Deletion)
		else
			table.insert(deletions, childToDelete)
		end
	end

	local function deleteRemainingChildren(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil
	)
		if not shouldTrackSideEffects then
			-- Noop.
			return nil
		end

		-- TODO: For the shouldClone case, this could be micro-optimized a bit by
		-- assuming that after the first child we've already added everything.
		local childToDelete = currentFirstChild
		while childToDelete ~= nil do
			deleteChild(returnFiber, childToDelete)
			childToDelete = childToDelete.sibling
		end
		return nil
	end

	local function mapRemainingChildren(
		returnFiber: Fiber,
		currentFirstChild: Fiber
	): { [string | number]: Fiber }
		-- Add the remaining children to a temporary map so that we can find them by
		-- keys quickly. Implicit (null) keys get added to this set with their index
		-- instead.
		local existingChildren: { [string | number]: Fiber } = {}

		-- ROBLOX FIXME Luau: Luau doesn't correctly infer in repeat until nil scenarios
		local existingChild: Fiber? = currentFirstChild
		while existingChild ~= nil do
			if existingChild.key ~= nil then
				existingChildren[existingChild.key] = existingChild
			else
				existingChildren[existingChild.index] = existingChild
			end
			existingChild = existingChild.sibling
		end
		return existingChildren
	end

	local function useFiber(fiber: Fiber, pendingProps: any): Fiber
		-- We currently set sibling to nil and index to 0 here because it is easy
		-- to forget to do before returning it. E.g. for the single child case.
		local clone = createWorkInProgress(fiber, pendingProps)
		-- ROBLOX deviation: set index to 1 for 1-indexing
		clone.index = 1
		clone.sibling = nil
		return clone
	end

	local function placeChild(
		newFiber: Fiber,
		lastPlacedIndex: number,
		newIndex: number
	): number
		newFiber.index = newIndex
		if not shouldTrackSideEffects then
			-- Noop.
			return lastPlacedIndex
		end
		local current = newFiber.alternate
		if current ~= nil then
			local oldIndex = current.index
			if oldIndex < lastPlacedIndex then
				-- This is a move.
				newFiber.flags = bit32.bor(newFiber.flags, Placement)
				return lastPlacedIndex
			else
				-- This item can stay in place.
				return oldIndex
			end
		else
			-- This is an insertion.
			newFiber.flags = bit32.bor(newFiber.flags, Placement)
			return lastPlacedIndex
		end
	end

	local function placeSingleChild(newFiber: Fiber): Fiber
		-- This is simpler for the single child case. We only need to do a
		-- placement for inserting new children.
		if shouldTrackSideEffects and newFiber.alternate == nil then
			newFiber.flags = bit32.bor(newFiber.flags, Placement)
		end
		return newFiber
	end

	local function updateTextNode(
		returnFiber: Fiber,
		current: Fiber | nil,
		textContent: string,
		lanes: Lanes
	)
		-- ROBLOX FIXME: Luau narrowing issue
		if current == nil or (current :: Fiber).tag ~= HostText then
			-- Insert
			local created = createFiberFromText(textContent, returnFiber.mode, lanes)
			created.return_ = returnFiber
			return created
		else
			-- Update
			local existing = useFiber(current :: Fiber, textContent)
			existing.return_ = returnFiber
			return existing
		end
	end

	local function updateElement(
		returnFiber: Fiber,
		current: Fiber | nil,
		element: ReactElement,
		lanes: Lanes
	): Fiber
		if current ~= nil then
			if
				(current :: Fiber).elementType == element.type
				-- ROBLOX performance: avoid always-false cmp, hot reloading isn't enabled in Roblox yet
				-- Keep this check inline so it only runs on the false path:
				-- or (__DEV__ and isCompatibleFamilyForHotReloading(current, element))
			then
				-- Move based on index
				local existing = useFiber(current :: Fiber, element.props)
				existing.ref = coerceRef(returnFiber, current, element)
				existing.return_ = returnFiber
				if __DEV__ then
					existing._debugSource = element._source
					existing._debugOwner = element._owner
				end
				return existing
			elseif enableBlocksAPI and (current :: Fiber).tag == Block then
				-- The new Block might not be initialized yet. We need to initialize
				-- it in case initializing it turns out it would match.
				-- ROBLOX FIXME Luau: Luau should analyze closure and create union of assignments
				local type_: any = element.type
				if type(type_) == "table" and type_["$$typeof"] == REACT_LAZY_TYPE then
					type_ = resolveLazyType(type_) :: LazyComponent<any, any>
				end
				if
					type_["$$typeof"] == REACT_BLOCK_TYPE
					and type_._render == (current :: Fiber).type._render
				then
					-- Same as above but also update the .type field.
					local existing = useFiber(current :: Fiber, element.props)
					existing.return_ = returnFiber
					existing.type = type_
					if __DEV__ then
						existing._debugSource = element._source
						existing._debugOwner = element._owner
					end
					return existing
				end
			end
		end
		-- Insert
		local created = createFiberFromElement(element, returnFiber.mode, lanes)
		created.ref = coerceRef(returnFiber, current, element)
		created.return_ = returnFiber
		return created
	end

	local function updatePortal(
		returnFiber: Fiber,
		current: Fiber | nil,
		portal: ReactPortal,
		lanes: Lanes
	): Fiber
		-- ROBLOX FIXME: type narrowing.
		if
			current == nil
			or (current :: Fiber).tag ~= HostPortal
			or (current :: Fiber).stateNode.containerInfo ~= portal.containerInfo
			or (current :: Fiber).stateNode.implementation ~= portal.implementation
		then
			-- Insert
			local created = createFiberFromPortal(portal, returnFiber.mode, lanes)
			created.return_ = returnFiber
			return created
		else
			-- Update
			local existing = useFiber(current :: Fiber, portal.children or {})
			existing.return_ = returnFiber
			return existing
		end
	end

	local function updateFragment(
		returnFiber: Fiber,
		current: Fiber | nil,
		-- ROBLOX TODO: figure out how we should define our Iterable type
		--   fragment: Iterable<*>,
		fragment: any,
		lanes: Lanes,
		key: nil | string
	): Fiber
		if current == nil or (current :: Fiber).tag ~= Fragment then
			-- Insert
			local created =
				createFiberFromFragment(fragment, returnFiber.mode, lanes, key)
			created.return_ = returnFiber
			return created
		else
			-- Update
			local existing = useFiber(current :: Fiber, fragment)
			existing.return_ = returnFiber
			return existing
		end
	end

	-- ROBLOX deviation: Roact stable keys - Support Roact's implementation of
	-- stable keys, wherein the key used in the `children` table is used as if it
	-- were a `key` prop. Child order doesn't matter in Roblox, so a vast majority
	-- of existing Roact code used table keys in this way.
	local function assignStableKey(tableKey: any?, newChild: Object): ()
		-- If there's no assigned key in the element, and the table key is valid,
		-- assign it as the element's key.
		-- If the key is a table, convert it to a string.

		-- ROBLOX TODO: Investigate if this is safe; maybe we need to shallow-copy
		-- the object if we have a new key, to preserve immutability, but that cost
		-- may be severe
		if newChild.key == nil then
			-- ROBLOX performance? only call typeof once, and only if first condition is true
			local typeOfTableKey = type(tableKey)
			if typeOfTableKey == "string" or typeOfTableKey == "number" then
				newChild.key = tableKey
			elseif typeOfTableKey == "table" then
				newChild.key = tostring(tableKey)
			end
		end
	end

	local function createChild(
		returnFiber: Fiber,
		newChild: any,
		lanes: Lanes,
		-- ROBLOX deviation: children table key for compat with Roact's stable keys
		tableKey: any?
	): Fiber | nil
		-- ROBLOX performance: early exit for nil newChild since no actions will be taken
		if newChild == nil then
			return nil
		end

		-- ROBLOX performance: avoid repeated calls to typeof, since Luau doesn't optimize
		local typeOfNewChild = type(newChild)

		-- ROBLOX performance: hoist more common ROblox case (non-string/number) first to reduce cmp in hot path
		if typeOfNewChild == "table" then
			-- ROBLOX deviation: Roact stable keys - forward children table key to
			-- child if applicable
			assignStableKey(tableKey, newChild)
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				local created = createFiberFromElement(newChild, returnFiber.mode, lanes)
				created.ref = coerceRef(returnFiber, nil, newChild)
				created.return_ = returnFiber
				return created
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				local created = createFiberFromPortal(newChild, returnFiber.mode, lanes)
				created.return_ = returnFiber
				return created
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- ROBLOX deviation: Roact stable keys - Since the table key was
					-- already applied to `newChild` above, we don't need to pass it along
					return createChild(returnFiber, init(payload), lanes)
				end
			end

			-- ROBLOX deviation peformance: this is the equiv of checking for a table, and we already know typeof(newChild) is a table in this branch
			-- if isArray(newChild) or getIteratorFn(newChild) then
			local created =
				createFiberFromFragment(newChild, returnFiber.mode, lanes, nil)
			created.return_ = returnFiber
			return created

			-- ROBLOX performance deviation: unreachable with the above table check
			-- throwOnInvalidObjectType(returnFiber, newChild)
		end

		if typeOfNewChild == "string" or typeOfNewChild == "number" then
			-- Text nodes don't have keys. If the previous node is implicitly keyed
			-- we can continue to replace it without aborting even if it is not a text
			-- node.
			local created =
				createFiberFromText(tostring(newChild), returnFiber.mode, lanes)
			created.return_ = returnFiber
			return created
		end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end

		return nil
	end

	local function updateSlot(
		returnFiber: Fiber,
		oldFiber: Fiber | nil,
		newChild: any,
		lanes: Lanes,
		-- ROBLOX deviation: children table key for compat with Roact's stable keys
		tableKey: any?
	): Fiber | nil
		-- ROBLOX performance: early exit for nil newChild since no actions will be taken
		if newChild == nil then
			return nil
		end

		-- Update the fiber if the keys match, otherwise return nil.

		local key = if oldFiber ~= nil then oldFiber.key else nil
		-- ROBLOX performance: avoid repeated calls to typeof since Luau doesn't cache
		local typeOfNewChild = type(newChild)

		if typeOfNewChild == "table" then
			-- ROBLOX deviation: Roact stable keys - forward children table key to
			-- child if applicable
			assignStableKey(tableKey, newChild)
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				if newChild.key == key then
					if newChild.type == REACT_FRAGMENT_TYPE then
						return updateFragment(
							returnFiber,
							oldFiber,
							newChild.props.children,
							lanes,
							key :: string?
						)
					end
					return updateElement(returnFiber, oldFiber, newChild, lanes)
				else
					return nil
				end
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				if newChild.key == key then
					return updatePortal(returnFiber, oldFiber, newChild, lanes)
				else
					return nil
				end
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- ROBLOX deviation: Roact stable keys - Since the table key was
					-- already applied to `newChild` above, we don't need to pass it along
					return updateSlot(returnFiber, oldFiber, init(payload), lanes)
				end
			end

			-- ROBLOX deviation peformance: this is the equiv of checking for a table, and we already know typeof(newChild) is a table in this branch
			-- if isArray(newChild) or getIteratorFn(newChild) then
			if key ~= nil then
				return nil
			end

			return updateFragment(returnFiber, oldFiber, newChild, lanes)

			-- ROBLOX performance deviation: unreachable with the above table check
			-- throwOnInvalidObjectType(returnFiber, newChild)
		end

		-- ROBLOX performance: do this compare last to save 2 string cmp in typical Roblox hot path
		if typeOfNewChild == "string" or typeOfNewChild == "number" then
			-- Text nodes don't have keys. If the previous node is implicitly keyed
			-- we can continue to replace it without aborting even if it is not a text
			-- node.
			if key ~= nil then
				return nil
			end
			return updateTextNode(returnFiber, oldFiber, tostring(newChild), lanes)
		end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end

		return nil
	end

	local function updateFromMap(
		existingChildren: Map<string | number, Fiber>,
		returnFiber: Fiber,
		newIdx: number,
		newChild: any,
		lanes: Lanes,
		-- ROBLOX deviation: children table key for compat with Roact's stable keys
		tableKey: any?
	): Fiber | nil
		-- ROBLOX performance: early exit for nil newChild since no actions will be taken
		if newChild == nil then
			return nil
		end

		-- ROBLOX performance: avoid repeated calls to typeof since Luau doesn't cache
		local typeOfNewChild = type(newChild)

		if typeOfNewChild == "table" then
			-- ROBLOX deviation: Roact stable keys - forward children table key to
			-- child if applicable
			assignStableKey(tableKey, newChild)
			local existingChildrenKey
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				if newChild.key == nil then
					existingChildrenKey = newIdx
				else
					existingChildrenKey = newChild.key
				end
				local matchedFiber = existingChildren[existingChildrenKey]
				if newChild.type == REACT_FRAGMENT_TYPE then
					return updateFragment(
						returnFiber,
						matchedFiber,
						newChild.props.children,
						lanes,
						newChild.key
					)
				end
				return updateElement(returnFiber, matchedFiber, newChild, lanes)
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				if newChild.key == nil then
					existingChildrenKey = newIdx
				else
					existingChildrenKey = newChild.key
				end
				local matchedFiber = existingChildren[existingChildrenKey]
				return updatePortal(returnFiber, matchedFiber, newChild, lanes)
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- ROBLOX deviation: Roact stable keys - Since the table key was
					-- already applied to `newChild` above, we don't need to pass it along
					return updateFromMap(
						existingChildren,
						returnFiber,
						newIdx,
						init(payload),
						lanes
					)
				end
			end

			-- ROBLOX deviation peformance: this is the equiv of checking for a table, and we already know typeof(newChild) is a table in this branch
			-- if isArray(newChild) or getIteratorFn(newChild) then
			local matchedFiber = existingChildren[newIdx]
			return updateFragment(returnFiber, matchedFiber, newChild, lanes)

			-- ROBLOX performance deviation: unreachable with the above table check
			-- throwOnInvalidObjectType(returnFiber, newChild)
		end

		-- ROBLOX performance: do this compare last, as Roblox won't really support text nodes directly
		if typeOfNewChild == "string" or typeOfNewChild == "number" then
			-- Text nodes don't have keys, so we neither have to check the old nor
			-- new node for the key. If both are text nodes, they match.
			local matchedFiber = existingChildren[newIdx] or nil
			return updateTextNode(returnFiber, matchedFiber, tostring(newChild), lanes)
		end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end

		return nil
	end

	--[[
	Warns if there is a duplicate or missing key
  ]]
	local function warnOnInvalidKey(
		child: any,
		knownKeys: Set<string> | nil,
		returnFiber: Fiber
	): Set<string> | nil
		if __DEV__ then
			if child == nil or type(child) ~= "table" then
				return knownKeys
			end
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local childTypeof = child["$$typeof"]
			if childTypeof == REACT_ELEMENT_TYPE or childTypeof == REACT_PORTAL_TYPE then
				warnForMissingKey(child, returnFiber)
				local key = child.key
				if type(key) ~= "string" then
					-- break
				elseif knownKeys == nil then
					knownKeys = {};
					(knownKeys :: Set<string>)[key] = true
				elseif not (knownKeys :: Set<string>)[key] then
					(knownKeys :: Set<string>)[key] = true
				else
					console.error(
'Encountered two children with the same key, `%s`. Keys should be unique so that components maintain their identity across updates. Non-unique keys may cause children to be duplicated and/or omitted \u{2014} the behavior is unsupported and could change in a future version.'



,
						key
					)
				end
			elseif childTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = child._payload
					local init = child._init
					warnOnInvalidKey(init(payload), knownKeys, returnFiber)
				end
			end
		end
		return knownKeys
	end

	local function reconcileChildrenArray(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		newChildren: Array<any>,
		lanes: Lanes
	): Fiber | nil
		-- This algorithm can't optimize by searching from both ends since we
		-- don't have backpointers on fibers. I'm trying to see how far we can get
		-- with that model. If it ends up not being worth the tradeoffs, we can
		-- add it later.

		-- Even with a two ended optimization, we'd want to optimize for the case
		-- where there are few changes and brute force the comparison instead of
		-- going for the Map. It'd like to explore hitting that path first in
		-- forward-only mode and only go for the Map once we notice that we need
		-- lots of look ahead. This doesn't handle reversal as well as two ended
		-- search but that's unusual. Besides, for the two ended optimization to
		-- work on Iterables, we'd need to copy the whole set.

		-- In this first iteration, we'll just live with hitting the bad case
		-- (adding everything to a Map) in for every insert/move.

		-- If you change this code, also update reconcileChildrenIterator() which
		-- uses the same algorithm.

		if __DEV__ then
			-- First, validate keys.
			local knownKeys 			
for i, child in newChildren do
				knownKeys = warnOnInvalidKey(child, knownKeys, returnFiber)
			end
		end

		local resultingFirstChild: Fiber | nil 		
local previousNewFiber: Fiber | nil 
		
local oldFiber: Fiber | nil = currentFirstChild
		local lastPlacedIndex = 1
		local newIdx = 1
		local nextOldFiber: Fiber | nil 		-- ROBLOX performance: don't re-evaluate length of newChildren on each iteration through the loop
		
local newChildrenCount = #newChildren
		-- ROBLOX deviation: use while loop in place of modified for loop
		while oldFiber ~= nil and newIdx <= newChildrenCount do
			if oldFiber.index > newIdx then
				nextOldFiber = oldFiber
				oldFiber = nil
			else
				nextOldFiber = oldFiber.sibling
			end
			--[[
				ROBLOX DEVIATION: We pass newIdx to createChild to ensure that children are
				assigned a key, assuming the child is not an array itself. We only need to
				pass newIdx if the child is actually a React element. If the child is a
				string or number, a key is never assigned, so we do not pass newIdx as a key.
			]]
			local newFiber
			-- ROBLOX performance: avoid repeated indexing of newChildren to newIdx
			local newChildNewIdx = newChildren[newIdx]
			if
				newChildNewIdx ~= nil
				and type(newChildNewIdx) == "table"
				and newChildNewIdx["$$typeof"] ~= nil
			then
				newFiber =
					updateSlot(returnFiber, oldFiber, newChildNewIdx, lanes, newIdx)
			else
				newFiber = updateSlot(returnFiber, oldFiber, newChildNewIdx, lanes)
			end
			if newFiber == nil then
				-- TODO: This breaks on empty slots like nil children. That's
				-- unfortunate because it triggers the slow path all the time. We need
				-- a better way to communicate whether this was a miss or nil,
				-- boolean, undefined, etc.
				if oldFiber == nil then
					oldFiber = nextOldFiber
				end
				break
			end
			if shouldTrackSideEffects then
				-- ROBLOX FIXME Luau: needs type states to understand the continue above
				if oldFiber and (newFiber :: Fiber).alternate == nil then
					-- We matched the slot, but we didn't reuse the existing fiber, so we
					-- need to delete the existing child.
					-- ROBLOX FIXME Luau: needs type states to understand the break above
					deleteChild(returnFiber, oldFiber :: Fiber)
				end
			end
			lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
			if previousNewFiber == nil then
				-- TODO: Move out of the loop. This only happens for the first run.
				resultingFirstChild = newFiber
			else
				-- TODO: Defer siblings if we're not at the right index for this slot.
				-- I.e. if we had nil values before, then we want to defer this
				-- for each nil value. However, we also don't want to call updateSlot
				-- with the previous one.
				(previousNewFiber :: Fiber).sibling = newFiber
			end
			previousNewFiber = newFiber
			oldFiber = nextOldFiber
			-- deviation: increment manually since we're not using a modified for loop
			newIdx += 1
		end

		if newIdx > newChildrenCount then
			-- We've reached the end of the new children. We can delete the rest.
			deleteRemainingChildren(returnFiber, oldFiber)
			return resultingFirstChild
		end

		if oldFiber == nil then
			-- If we don't have any more existing children we can choose a fast path
			-- since the rest will all be insertions.
			-- deviation: use while loop in place of modified for loop
			while newIdx <= newChildrenCount do
				--[[
					ROBLOX DEVIATION: We pass newIdx to createChild to ensure that children are
					assigned a key, assuming the child is not an array itself. We only need to
					pass newIdx if the child is actually a React element. If the child is a
					string or number, a key is never assigned, so we do not pass newIdx as a key.
				]]
				local newFiber
				-- ROBLOX performance: avoid repeated indexing of newChildren to newIdx
				local newChildNewIdx = newChildren[newIdx]
				if
					newChildNewIdx ~= nil
					and type(newChildNewIdx) == "table"
					and newChildNewIdx["$$typeof"] ~= nil
				then
					newFiber = createChild(returnFiber, newChildNewIdx, lanes, newIdx)
				else
					newFiber = createChild(returnFiber, newChildNewIdx, lanes)
				end
				if newFiber == nil then
					-- ROBLOX deviation: increment manually since we're not using a modified for loop
					newIdx += 1
					continue
				end
				-- ROBLOX FIXME Luau: needs type state to understand the continue above
				lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					-- TODO: Move out of the loop. This only happens for the first run.
					resultingFirstChild = newFiber
				else
					(previousNewFiber :: Fiber).sibling = newFiber
				end
				previousNewFiber = newFiber
				-- deviation: increment manually since we're not using a modified for loop
				newIdx += 1
			end
			return resultingFirstChild
		end

		-- Add all children to a key map for quick lookups.
		-- ROBLOX FIXME Luau: need type state to understand the if/return above
		local existingChildren = mapRemainingChildren(returnFiber, oldFiber :: Fiber)

		-- Keep scanning and use the map to restore deleted items as moves.
		-- ROBLOX deviation: use while loop in place of modified for loop
		while newIdx <= newChildrenCount do
			local newFiber = updateFromMap(
				existingChildren,
				returnFiber,
				newIdx,
				newChildren[newIdx],
				lanes,
				-- ROBLOX deviation: pass newIdx to be used as the key of the element
				newIdx
			)
			if newFiber ~= nil then
				if shouldTrackSideEffects then
					if newFiber.alternate ~= nil then
						-- The new fiber is a work in progress, but if there exists a
						-- current, that means that we reused the fiber. We need to delete
						-- it from the child list so that we don't add it to the deletion
						-- list.
						existingChildren[if newFiber.key == nil
							then newIdx
							else newFiber.key] =
							nil
					end
				end
				lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					resultingFirstChild = newFiber
				else
					(previousNewFiber :: Fiber).sibling = newFiber
				end
				previousNewFiber = newFiber
			end
			-- deviation: increment manually since we're not using a modified for loop
			newIdx += 1
		end

		if shouldTrackSideEffects then
			-- Any existing children that weren't consumed above were deleted. We need
			-- to add them to the deletion list.
			for _, child in existingChildren do
				deleteChild(returnFiber, child)
			end
		end

		return resultingFirstChild
	end

	-- ROBLOX TODO: LUAFDN-254
	local function reconcileChildrenIterator(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		-- ROBLOX TODO: figure out our Iterable<> interface
		--   newChildrenIterable: Iterable<*>,
		newChildrenIterable: any,
		lanes: Lanes,
		-- ROBLOX performance? pass in iteratorFn to avoid two calls to getIteratorFn
		iteratorFn: (...any) -> any
	): Fiber | nil
		-- This is the same implementation as reconcileChildrenArray(),
		-- but using the iterator instead.

		-- local iteratorFn = getIteratorFn(newChildrenIterable)
		-- ROBLOX performance? eliminate 'nice to have' strcmp in hot path
		-- invariant(
		-- 	typeof(iteratorFn) == "function",
		-- 	"An object is not an iterable. This error is likely caused by a bug in "
		-- 		.. "React. Please file an issue."
		-- )

		if __DEV__ then
			-- We don't support rendering Generators because it's a mutation.
			-- See https://github.com/facebook/react/issues/12995
			-- ROBLOX deviation: Lua doesn't have built-in generators
			-- if
			--   typeof(Symbol) == 'function' and
			--   -- $FlowFixMe Flow doesn't know about toStringTag
			--   newChildrenIterable[Symbol.toStringTag] == 'Generator'
			-- then
			--   if not didWarnAboutGenerators then
			--     console.error(
			--       'Using Generators as children is unsupported and will likely yield ' ..
			--         'unexpected results because enumerating a generator mutates it. ' ..
			--         'You may convert it to an array with `Array.from()` or the ' ..
			--         '`[...spread]` operator before rendering. Keep in mind ' ..
			--         'you might need to polyfill these features for older browsers.'
			--     )
			--   end
			--   didWarnAboutGenerators = true
			-- end

			-- Warn about using Maps as children
			if newChildrenIterable.entries == iteratorFn then
				if not didWarnAboutMaps then
					console.error(
[[Using Maps as children is not supported. Use an array of keyed ReactElements instead.]]					

)
				end
				didWarnAboutMaps = true
			end

			-- First, validate keys.
			-- We'll get a different iterator later for the main pass.
			local newChildren = iteratorFn(newChildrenIterable)
			if newChildren then
				local knownKeys 				
local step = newChildren.next()
				while not step.done do
					step = newChildren.next()
					local child = step.value
					knownKeys = warnOnInvalidKey(child, knownKeys, returnFiber)
				end
			end
		end

		local newChildren = iteratorFn(newChildrenIterable)
		-- ROBLOX performance? eliminate 'nice to have' cmp in hot path
		-- invariant(newChildren ~= nil, "An iterable object provided no iterator.")

		local resultingFirstChild: Fiber | nil 		
local previousNewFiber: Fiber 
		
local oldFiber = currentFirstChild
		local lastPlacedIndex = 1
		local newIdx = 1
		local nextOldFiber: Fiber | nil 
		
local step = newChildren.next()
		while oldFiber ~= nil and not step.done do
			if oldFiber.index > newIdx then
				nextOldFiber = oldFiber
				oldFiber = nil
			else
				nextOldFiber = oldFiber.sibling
			end
			local newFiber =
				updateSlot(returnFiber, oldFiber, step.value, lanes, step.key)
			if newFiber == nil then
				-- TODO: This breaks on empty slots like nil children. That's
				-- unfortunate because it triggers the slow path all the time. We need
				-- a better way to communicate whether this was a miss or nil,
				-- boolean, undefined, etc.
				if oldFiber == nil then
					oldFiber = nextOldFiber
				end
				break
			end
			if shouldTrackSideEffects then
				-- ROBLOX FIXME Luau: need type states to understand the break above
				if oldFiber and (newFiber :: Fiber).alternate == nil then
					-- We matched the slot, but we didn't reuse the existing fiber, so we
					-- need to delete the existing child.
					deleteChild(returnFiber, oldFiber)
				end
			end
			lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
			if previousNewFiber == nil then
				-- TODO: Move out of the loop. This only happens for the first run.
				resultingFirstChild = newFiber
			else
				-- TODO: Defer siblings if we're not at the right index for this slot.
				-- I.e. if we had nil values before, then we want to defer this
				-- for each nil value. However, we also don't want to call updateSlot
				-- with the previous one.
				previousNewFiber.sibling = newFiber :: Fiber
			end
			previousNewFiber = newFiber :: Fiber
			oldFiber = nextOldFiber

			newIdx += 1
			step = newChildren.next()
		end

		if step.done then
			-- We've reached the end of the new children. We can delete the rest.
			deleteRemainingChildren(returnFiber, oldFiber)
			return resultingFirstChild
		end

		if oldFiber == nil then
			-- If we don't have any more existing children we can choose a fast path
			-- since the rest will all be insertions.
			while not step.done do
				local newFiber = createChild(returnFiber, step.value, lanes, step.key)
				if newFiber == nil then
					newIdx += 1
					step = newChildren.next()
					continue
				end
				-- ROBLOX FIXME Luau: need type states to understand the continue above
				lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					-- TODO: Move out of the loop. This only happens for the first run.
					resultingFirstChild = newFiber
				else
					previousNewFiber.sibling = newFiber
				end
				previousNewFiber = newFiber :: Fiber

				newIdx += 1
				step = newChildren.next()
			end
			return resultingFirstChild
		end

		-- Add all children to a key map for quick lookups.
		-- ROBLOX performance? defer initialization into the loop. extra cmp per loop iter, but avoid call if no loop iter
		local existingChildren

		-- Keep scanning and use the map to restore deleted items as moves.
		while not step.done do
			if not existingChildren then
				-- ROBLOX FIXME LUau: need type states to understand the guard+return above
				existingChildren = mapRemainingChildren(returnFiber, oldFiber :: Fiber)
			end
			local newFiber = updateFromMap(
				existingChildren,
				returnFiber,
				newIdx,
				step.value,
				lanes,
				step.key
			)
			if newFiber ~= nil then
				if shouldTrackSideEffects then
					if newFiber.alternate ~= nil then
						-- The new fiber is a work in progress, but if there exists a
						-- current, that means that we reused the fiber. We need to delete
						-- it from the child list so that we don't add it to the deletion
						-- list.
						if newFiber.key == nil then
							existingChildren[newIdx] = nil
						else
							existingChildren[newFiber.key] = nil
						end
					end
				end
				lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					resultingFirstChild = newFiber
				else
					previousNewFiber.sibling = newFiber
				end
				previousNewFiber = newFiber
			end

			newIdx += 1
			step = newChildren.next()
		end

		if shouldTrackSideEffects then
			-- Any existing children that weren't consumed above were deleted. We need
			-- to add them to the deletion list.
			for _, child in existingChildren do
				deleteChild(returnFiber, child)
			end
		end

		return resultingFirstChild
	end

	local function reconcileSingleTextNode(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		textContent: string,
		lanes: Lanes
	): Fiber
		-- There's no need to check for keys on text nodes since we don't have a
		-- way to define them.
		-- ROBLOX FIXME: Luau narrowing issue
		if currentFirstChild ~= nil and (currentFirstChild :: Fiber).tag == HostText then
			-- We already have an existing node so let's just update it and delete
			-- the rest.
			deleteRemainingChildren(returnFiber, (currentFirstChild :: Fiber).sibling)
			local existing = useFiber(currentFirstChild :: Fiber, textContent)
			existing.return_ = returnFiber
			return existing
		end
		-- The existing first child is not a text node so we need to create one
		-- and delete the existing ones.
		deleteRemainingChildren(returnFiber, currentFirstChild)
		local created = createFiberFromText(textContent, returnFiber.mode, lanes)
		created.return_ = returnFiber
		return created
	end

	local function reconcileSingleElement(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		element: ReactElement,
		lanes: Lanes
	): Fiber
		local key = element.key
		local child = currentFirstChild
		while child ~= nil do
			-- TODO: If key == nil and child.key == nil, then this only applies to
			-- the first item in the list.
			if child.key == key then
				if child.tag == Fragment then
					if element.type == REACT_FRAGMENT_TYPE then
						deleteRemainingChildren(returnFiber, child.sibling)
						local existing = useFiber(child, element.props.children)
						existing.return_ = returnFiber
						if __DEV__ then
							existing._debugSource = element._source
							existing._debugOwner = element._owner
						end
						return existing
					end
					-- ROBLOX performance: avoid always-false cmp in hot path
					-- elseif child.tag == Block then
					-- 	unimplemented("reconcileSingleElement: Block")
					-- if (enableBlocksAPI) {
					--   let type = element.type;
					--   if (type.$$typeof === REACT_LAZY_TYPE) {
					--     type = resolveLazyType(type);
					--   }
					--   if (type.$$typeof === REACT_BLOCK_TYPE) {
					--     // The new Block might not be initialized yet. We need to initialize
					--     // it in case initializing it turns out it would match.
					--     if (
					--       ((type: any): BlockComponent<any, any>)._render ===
					--       (child.type: BlockComponent<any, any>)._render
					--     ) {
					--       deleteRemainingChildren(returnFiber, child.sibling);
					--       const existing = useFiber(child, element.props);
					--       existing.type = type;
					--       existing.return = returnFiber;
					--       if (__DEV__) {
					--         existing._debugSource = element._source;
					--         existing._debugOwner = element._owner;
					--       }
					--       return existing;
					--     }
					--   }
					-- }
					-- // We intentionally fallthrough here if enableBlocksAPI is not on.
					-- // eslint-disable-next-lined no-fallthrough
				else
					if
						child.elementType == element.type
						-- ROBLOX performance: avoid always-false cmp, hot reloading isn't enabled in Roblox yet
						-- Keep this check inline so it only runs on the false path:
						-- or (
						-- 	__DEV__
						-- 	and isCompatibleFamilyForHotReloading(child, element)
						-- )
					then
						deleteRemainingChildren(returnFiber, child.sibling)
						local existing = useFiber(child, element.props)
						existing.ref = coerceRef(returnFiber, child, element)
						existing.return_ = returnFiber
						if __DEV__ then
							existing._debugSource = element._source
							existing._debugOwner = element._owner
						end
						return existing
					end
				end
				-- Didn't match.
				deleteRemainingChildren(returnFiber, child)
				break
			else
				deleteChild(returnFiber, child)
			end
			child = child.sibling
		end

		if element.type == REACT_FRAGMENT_TYPE then
			local created = createFiberFromFragment(
				element.props.children,
				returnFiber.mode,
				lanes,
				-- ROBLOX FIXME Luau: needs normalization: TypeError: Type '(number | string)?' could not be converted into 'string?'
				element.key :: string
			)
			created.return_ = returnFiber
			return created
		else
			local created = createFiberFromElement(element, returnFiber.mode, lanes)
			created.ref = coerceRef(returnFiber, currentFirstChild, element)
			created.return_ = returnFiber
			return created
		end
	end

	local function reconcileSinglePortal(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		portal: ReactPortal,
		lanes: Lanes
	): Fiber
		local key = portal.key
		local child = currentFirstChild
		while child ~= nil do
			-- TODO: If key == nil and child.key == nil, then this only applies to
			-- the first item in the list.
			if child.key == key then
				if
					child.tag == HostPortal
					and child.stateNode.containerInfo == portal.containerInfo
					and child.stateNode.implementation == portal.implementation
				then
					deleteRemainingChildren(returnFiber, child.sibling)
					local existing = useFiber(child, portal.children or {})
					existing.return_ = returnFiber
					return existing
				else
					deleteRemainingChildren(returnFiber, child)
					break
				end
			else
				deleteChild(returnFiber, child)
			end
			child = child.sibling
		end

		local created = createFiberFromPortal(portal, returnFiber.mode, lanes)
		created.return_ = returnFiber
		return created
	end

	-- This API will tag the children with the side-effect of the reconciliation
	-- itself. They will be added to the side-effect list as we pass through the
	-- children and the parent.
	local function reconcileChildFibers(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		newChild: any,
		lanes: Lanes
	): Fiber | nil
		-- This function is not recursive.
		-- If the top level item is an array, we treat it as a set of children,
		-- not as a fragment. Nested arrays on the other hand will be treated as
		-- fragment nodes. Recursion happens at the normal flow.

		-- ROBLOX performance: avoid repeated calls to typeof since Luau doesn't cache
		local typeOfNewChild = type(newChild)

		-- Handle top level unkeyed fragments as if they were arrays.
		-- This leads to an ambiguity between <>{[...]}</> and <>...</>.
		-- We treat the ambiguous cases above the same.
		local isUnkeyedTopLevelFragment = newChild ~= nil
			and typeOfNewChild == "table"
			and newChild.type == REACT_FRAGMENT_TYPE
			and newChild.key == nil
		if isUnkeyedTopLevelFragment then
			newChild = newChild.props.children
			typeOfNewChild = type(newChild)
		end
		local newChildIsArray = isArray(newChild)

		-- Handle object types
		-- ROBLOX deviation: upstream checks for `object`, but we need to manually exclude array
		local isObject = newChild ~= nil
			and typeOfNewChild == "table"
			and not newChildIsArray

		if isObject then
			-- ROBLOX performance: avoid repeated indexing of $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				return placeSingleChild(
					reconcileSingleElement(
						returnFiber,
						currentFirstChild,
						newChild,
						lanes
					)
				)
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				return placeSingleChild(
					reconcileSinglePortal(returnFiber, currentFirstChild, newChild, lanes)
				)
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- TODO: This function is supposed to be non-recursive.
					return reconcileChildFibers(
						returnFiber,
						currentFirstChild,
						init(payload),
						lanes
					)
				end
			end
		-- ROBLOX performance: make these next blocks `elseif`, as they're mutually exclusive to `isObject` above
		elseif newChildIsArray then
			return reconcileChildrenArray(returnFiber, currentFirstChild, newChild, lanes)
		elseif typeOfNewChild == "string" or typeOfNewChild == "number" then
			return placeSingleChild(
				reconcileSingleTextNode(
					returnFiber,
					currentFirstChild,
					tostring(newChild),
					lanes
				)
			)
		end

		-- ROBLOX performance? only call getIteratorFn once, pass in the value
		local newChildIteratorFn = getIteratorFn(newChild)
		if newChildIteratorFn then
			return reconcileChildrenIterator(
				returnFiber,
				currentFirstChild,
				newChild,
				lanes,
				newChildIteratorFn
			)
		end

		-- ROBLOX performance? eliminate a cmp in hot path for something unimplemented anyway
		-- if isObject then
		-- 	unimplemented("throwOnInvalidObjectType")
		-- 	-- throwOnInvalidObjectType(returnFiber, newChild)
		-- end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end
		if newChild == nil and not isUnkeyedTopLevelFragment then
			-- deviation: need a flag here to simulate switch/case fallthrough + break
			local shouldFallThrough = false
			-- If the new child is undefined, and the return fiber is a composite
			-- component, throw an error. If Fiber return types are disabled,
			-- we already threw above.
			-- ROBLOX deviation: With coercion of no returns to `nil`, it
			-- if returnFiber.tag == ClassComponent then
			--   if __DEV__ then
			-- isn't necessary to special case this scenario
			-- local instance = returnFiber.stateNode
			-- if instance.render._isMockFunction then
			--   -- We allow auto-mocks to proceed as if they're returning nil.
			--   shouldFallThrough = true
			-- end
			--   end
			-- end
			-- Intentionally fall through to the next case, which handles both
			-- functions and classes
			-- eslint-disable-next-lined no-fallthrough
			if
				shouldFallThrough
				and (
					returnFiber.tag == ClassComponent
					or returnFiber.tag == FunctionComponent
					or returnFiber.tag == ForwardRef
					or returnFiber.tag == SimpleMemoComponent
				)
			then
				invariant(
					false,
[[%s(...): Nothing was returned from render. This usually means a return statement is missing. Or, to render nothing, return nil.]]

,
					getComponentName(returnFiber.type) or "Component"
				)
			end
		end

		-- Remaining cases are all treated as empty.
		return deleteRemainingChildren(returnFiber, currentFirstChild)
	end

	return reconcileChildFibers
end

exports.reconcileChildFibers = ChildReconciler(true)
exports.mountChildFibers = ChildReconciler(false)

exports.cloneChildFibers = function(current: Fiber | nil, workInProgress: Fiber)
	-- ROBLOX deviation: This message isn't tested upstream, remove for hot path optimization
	-- invariant(
	-- 	current == nil or workInProgress.child == (current :: Fiber).child,
	-- 	"Resuming work not yet implemented."
	-- )

	if workInProgress.child == nil then
		return
	end

	local currentChild = workInProgress.child :: Fiber
	local newChild = createWorkInProgress(currentChild, currentChild.pendingProps)
	workInProgress.child = newChild

	newChild.return_ = workInProgress
	while currentChild.sibling ~= nil do
		currentChild = currentChild.sibling
		newChild.sibling = createWorkInProgress(currentChild, currentChild.pendingProps)
		-- ROBLOX FIXME Luau: luau doesn't track/narrow the direct assignment on the line above
		newChild = newChild.sibling :: Fiber
		newChild.return_ = workInProgress
	end
	newChild.sibling = nil
end

-- Reset a workInProgress child set to prepare it for a second pass.
exports.resetChildFibers = function(workInProgress: Fiber, lanes: Lanes): ()
	local child = workInProgress.child
	while child ~= nil do
		resetWorkInProgress(child, lanes)
		child = child.sibling
	end
end

return exports

end,
["react-reconciler/ReactCurrentFiber"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/b0cb137bcbd3a11d8eff3c2229cd6b8379d29785/packages/react-reconciler/src/ReactCurrentFiber.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local __DEV__ = _G.__DEV__ :: boolean

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber

local ReactSharedInternals = require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals
local ReactFiberComponentStack = require(script.Parent:WaitForChild('ReactFiberComponentStack'))
local getStackByFiberInDevAndProd = ReactFiberComponentStack.getStackByFiberInDevAndProd
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName

local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame

-- deviation: Pre-declare type of exports, including values we'll initialize
type Exports = {
	current: Fiber | nil,
	isRendering: boolean,
	-- remaining functions declare their own types
	[string]: any
}

local exports: Exports = {
	current = nil,
	isRendering = false,
}

exports.getCurrentFiberOwnerNameInDevOrNull = function(): string?
	if __DEV__ then
		if exports.current == nil then
			return nil
		end
		-- ROBLOX FIXME Luau: Luau doesn't understand guard above
		local owner = (exports.current :: Fiber)._debugOwner
		if owner then
			return getComponentName(owner.type)
		end
	end
	return nil
end

local function getCurrentFiberStackInDev(): string
	if __DEV__ then
		if exports.current == nil then
			return ""
		end
		-- Safe because if current fiber exists, we are reconciling,
		-- and it is guaranteed to be the work-in-progress version.
		-- ROBLOX FIXME Luau: Luau doesn't understand guard above
		return getStackByFiberInDevAndProd(exports.current :: Fiber)
	end
	return ""
end

exports.resetCurrentFiber = function(): ()
	if __DEV__ then
		-- ROBLOX FIXME Luau: Expected type table, got 'ReactDebugCurrentFrame | { setExtraStackFrame: () -> () }' instead
		(ReactDebugCurrentFrame :: any).getCurrentStack = nil
		exports.current = nil
		exports.isRendering = false
	end
end

exports.setCurrentFiber = function(fiber: Fiber): ()
	if __DEV__ then
		-- ROBLOX FIXME Luau: Expected type table, got 'ReactDebugCurrentFrame | { setExtraStackFrame: () -> () }' instead
		(ReactDebugCurrentFrame :: any).getCurrentStack = getCurrentFiberStackInDev
		exports.current = fiber
		exports.isRendering = false
	end
end

exports.setIsRendering = function(rendering: boolean): ()
	if __DEV__ then
		exports.isRendering = rendering
	end
end

exports.getIsRendering = function(): boolean
	if __DEV__ then
		return exports.isRendering
	end
	return false
end

return exports

end,
["react-reconciler/ReactFiber.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiber.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local __DEV__ = _G.__DEV__
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local inspect = LuauPolyfill.util.inspect

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes

type ReactElement = ReactTypes.ReactElement<any, any>
type ReactFragment = ReactTypes.ReactFragment
type ReactPortal = ReactTypes.ReactPortal
type ReactFundamentalComponent<T, U> = ReactTypes.ReactFundamentalComponent<T, U>
type ReactScope = ReactTypes.ReactScope
local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
export type Fiber = ReactInternalTypes.Fiber

-- ROBLOX deviation: Allow number keys for sparse arrays
type RoactStableKey = ReactInternalTypes.RoactStableKey
local ReactRootTags = require(script.Parent:WaitForChild('ReactRootTags'))
type RootTag = ReactRootTags.RootTag
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
type WorkTag = ReactWorkTags.WorkTag
local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
type TypeOfMode = ReactTypeOfMode.TypeOfMode
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
local ReactFiberOffscreenComponent = require(script.Parent:WaitForChild('ReactFiberOffscreenComponent'))
type OffscreenProps = ReactFiberOffscreenComponent.OffscreenProps

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
-- local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local NoFlags = ReactFiberFlags.NoFlags
local Placement = ReactFiberFlags.Placement
local StaticMask = ReactFiberFlags.StaticMask
local ConcurrentRoot = ReactRootTags.ConcurrentRoot
local BlockingRoot = ReactRootTags.BlockingRoot
local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local Mode = ReactWorkTags.Mode
local ContextProvider = ReactWorkTags.ContextProvider
local ContextConsumer = ReactWorkTags.ContextConsumer
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local DehydratedFragment = ReactWorkTags.DehydratedFragment
local FunctionComponent = ReactWorkTags.FunctionComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local LazyComponent = ReactWorkTags.LazyComponent
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ScopeComponent = ReactWorkTags.ScopeComponent
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName

local ReactFiberDevToolsHook = require(script.Parent:WaitForChild('ReactFiberDevToolsHook.new'))
local isDevToolsPresent = ReactFiberDevToolsHook.isDevToolsPresent
local ReactFiberHotReloading = require(script.Parent:WaitForChild('ReactFiberHotReloading.new'))
local resolveClassForHotReloading = ReactFiberHotReloading.resolveClassForHotReloading
local resolveFunctionForHotReloading =
	ReactFiberHotReloading.resolveFunctionForHotReloading
local resolveForwardRefForHotReloading =
	ReactFiberHotReloading.resolveForwardRefForHotReloading
local NoLanes = ReactFiberLane.NoLanes
local NoMode = ReactTypeOfMode.NoMode
local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
local DebugTracingMode = ReactTypeOfMode.DebugTracingMode
local ProfileMode = ReactTypeOfMode.ProfileMode
local StrictMode = ReactTypeOfMode.StrictMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_DEBUG_TRACING_MODE_TYPE = ReactSymbols.REACT_DEBUG_TRACING_MODE_TYPE
local REACT_STRICT_MODE_TYPE = ReactSymbols.REACT_STRICT_MODE_TYPE
local REACT_PROFILER_TYPE = ReactSymbols.REACT_PROFILER_TYPE
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
-- local REACT_FUNDAMENTAL_TYPE = ReactSymbols.REACT_FUNDAMENTAL_TYPE
-- local REACT_SCOPE_TYPE = ReactSymbols.REACT_SCOPE_TYPE
local REACT_OFFSCREEN_TYPE = ReactSymbols.REACT_OFFSCREEN_TYPE
local REACT_LEGACY_HIDDEN_TYPE = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE

-- deviation: We probably don't have to worry about this scenario, since we use
-- simple tables as maps

-- local hasBadMapPolyfill

-- if __DEV__ then
-- 	hasBadMapPolyfill = false
-- 	try {
-- 		local nonExtensibleObject = Object.preventExtensions({})
-- 		--[[ eslint-disable no-new ]]
-- 		new Map([[nonExtensibleObject, nil]])
-- 		new Set([nonExtensibleObject])
-- 		--[[ eslint-enable no-new ]]
-- 	} catch (e)
-- 		-- TODO: Consider warning about bad polyfills
-- 		hasBadMapPolyfill = true
-- 	end
-- end

local createFiberFromScope, createFiberFromProfiler, createFiberFromFragment, createFiberFromFundamental, createFiberFromSuspense, createFiberFromOffscreen, createFiberFromLegacyHidden, createFiberFromSuspenseList

local debugCounter = 1

-- ROBLOX deviation START: inline this into its only caller to save hot path performance
-- function FiberNode(
-- 	tag: WorkTag,
-- 	pendingProps: any,
-- 	key: RoactStableKey?,
-- 	mode: TypeOfMode
-- ): Fiber
-- 	return {} :: any
-- end
-- ROBLOX deviation END

-- This is a constructor function, rather than a POJO constructor, still
-- please ensure we do the following:
-- 1) Nobody should add any instance methods on this. Instance methods can be
--    more difficult to predict when they get optimized and they are almost
--    never inlined properly in static compilers.
-- 2) Nobody should rely on `instanceof Fiber` for type testing. We should
--    always know when it is a fiber.
-- 3) We might want to experiment with using numeric keys since they are easier
--    to optimize in a non-JIT environment.
-- 4) We can easily go from a constructor to a createFiber object literal if that
--    is faster.
-- 5) It should be easy to port this to a C struct and keep a C implementation
--    compatible.
-- ROBLOX deviation START: add elementType, type, and lanes arguments so the table is created in a one-shot to avoid rehashing
local function createFiber(
	tag: WorkTag,
	pendingProps: any,
	key: RoactStableKey?,
	mode: TypeOfMode,
	elementType: any?,
	type_: any?,
	stateNode: any?,
	lanes: Lanes?
): Fiber
	-- $FlowFixMe: the shapes are exact here but Flow doesn't like constructors
	-- ROBLOX deviation START: inline FiberNode(), do the table as a one-shot and avoid initializing nil fields for hot-path performance
	local node: Fiber = {
		-- Instance
		tag = tag,
		key = key,
		elementType = elementType,
		type = type_,
		stateNode = stateNode,

		-- Fiber
		-- node.return_ = nil
		-- node.child = nil
		-- node.sibling = nil
		index = 1,

		-- node.ref = nil

		pendingProps = pendingProps,
		-- memoizedProps = nil
		-- updateQueue = nil
		-- memoizedState = nil
		-- dependencies = nil

		mode = mode,

		-- Effects
		flags = NoFlags,
		subtreeFlags = NoFlags,
		-- deletions = nil

		lanes = if lanes then lanes else NoLanes,
		childLanes = NoLanes,

		-- alternate = nil
	} :: any

	if enableProfilerTimer then
		-- deviation: Unlikely that we have this same performance problem
		--[[
			-- Note: The following is done to avoid a v8 performance cliff.
			--
			-- Initializing the fields below to smis and later updating them with
			-- double values will cause Fibers to end up having separate shapes.
			-- This behavior/bug has something to do with Object.preventExtension().
			-- Fortunately this only impacts DEV builds.
			-- Unfortunately it makes React unusably slow for some applications.
			-- To work around this, initialize the fields below with doubles.
			--
			-- Learn more about this here:
			-- https://github.com/facebook/react/issues/14365
			-- https://bugs.chromium.org/p/v8/issues/detail?id=8538
			node.actualDuration = Number.NaN
			node.actualStartTime = Number.NaN
			node.selfBaseDuration = Number.NaN
			node.treeBaseDuration = Number.NaN

			-- It's okay to replace the initial doubles with smis after initialization.
			-- This won't trigger the performance cliff mentioned above,
			-- and it simplifies other profiler code (including DevTools).
		]]
		node.actualDuration = 0
		node.actualStartTime = -1		
node.selfBaseDuration = 0
		node.treeBaseDuration = 0
	end

	if __DEV__ then
		-- This isn't directly used but is handy for debugging internals:
		node._debugID = debugCounter
		debugCounter += 1
		node._debugSource = nil
		node._debugOwner = nil
		node._debugNeedsRemount = false
		node._debugHookTypes = nil
		-- deviation: We can just make sure this is always valid
		-- if not hasBadMapPolyfill and typeof(Object.preventExtensions) == "function"

		-- deviation: FIXME - we can't actually distinguish between 'nil' and
		-- absent, so if we do this here, we won't be able to initialize fields
		-- that start out as 'nil'
		-- Object.preventExtensions(node)

		-- end
	end
	return node
	-- ROBLOX deviation END
end

-- ROBLOX deviation START: we inline all uses of this function for performance in hot path
function _shouldConstruct(Component)
	-- deviation: With Lua metatables, members of the "prototype" can be
	-- accessed directly. so we don't need to check for a prototype separately
	return type(Component) ~= "function" and not not Component.isReactComponent
end
-- ROBLOX deviation END

local function isSimpleFunctionComponent(type_: any)
	-- ROBLOX deviation START: inline shouldConstruct logic for hot path performance
	return type(type_) == "function"
	-- deviation: function components don't support this anyway
	-- type.defaultProps == undefined
	-- ROBLOX deviation END: inline shouldConstruct logic for hot path performance
end

local function resolveLazyComponentTag(Component: any): WorkTag
	local typeofComponent = typeof(Component)
	if typeofComponent == "function" then
		return FunctionComponent
	end

	if typeofComponent == "table" then
		if Component.isReactComponent then
			return ClassComponent
		end
		local __typeof = Component["$$typeof"]
		if __typeof == REACT_FORWARD_REF_TYPE then
			return ForwardRef
		end
		if __typeof == REACT_MEMO_TYPE then
			return MemoComponent
		end
	end

	return IndeterminateComponent
end

-- This is used to create an alternate fiber to do work on.
local function createWorkInProgress(current: Fiber, pendingProps: any): Fiber
	-- ROBLOX FIXME Luau: Luau doesn't understand if nil then create pattern
	local workInProgress = current.alternate :: Fiber
	if workInProgress == nil then
		-- We use a double buffering pooling technique because we know that we'll
		-- only ever need at most two versions of a tree. We pool the "other" unused
		-- node that we're free to reuse. This is lazily created to avoid allocating
		-- extra objects for things that are never updated. It also allow us to
		-- reclaim the extra memory if needed.
		workInProgress = createFiber(
			current.tag,
			pendingProps,
			current.key,
			current.mode,
			current.elementType,
			current.type,
			current.stateNode
		)

		if __DEV__ then
			-- DEV-only fields
			workInProgress._debugID = current._debugID
			workInProgress._debugSource = current._debugSource
			workInProgress._debugOwner = current._debugOwner
			workInProgress._debugHookTypes = current._debugHookTypes
		end

		workInProgress.alternate = current
		current.alternate = workInProgress
	else
		workInProgress.pendingProps = pendingProps
		-- Needed because Blocks store data on type.
		workInProgress.type = current.type

		-- We already have an alternate.
		-- Reset the effect tag.
		workInProgress.flags = NoFlags

		-- The current effects are no longer valid
		workInProgress.subtreeFlags = NoFlags
		workInProgress.deletions = nil

		if enableProfilerTimer then
			-- We intentionally reset, rather than copy, actualDuration & actualStartTime.
			-- This prevents time from endlessly accumulating in new commits.
			-- This has the downside of resetting values for different priority renders,
			-- But works for yielding (the common case) and should support resuming.
			workInProgress.actualDuration = 0
			workInProgress.actualStartTime = -1		
end
	end

	-- Reset all effects except static ones.
	-- Static effects are not specific to a render.
	workInProgress.flags = bit32.band(current.flags, StaticMask)
	workInProgress.childLanes = current.childLanes
	workInProgress.lanes = current.lanes

	workInProgress.child = current.child
	workInProgress.memoizedProps = current.memoizedProps
	workInProgress.memoizedState = current.memoizedState
	workInProgress.updateQueue = current.updateQueue

	-- Clone the dependencies object. This is mutated during the render phase, so
	-- it cannot be shared with the current fiber.
	local currentDependencies = current.dependencies
	if currentDependencies == nil then
		workInProgress.dependencies = nil
	else
		workInProgress.dependencies = {
			lanes = currentDependencies.lanes,
			firstContext = currentDependencies.firstContext,
		}
	end

	-- These will be overridden during the parent's reconciliation
	workInProgress.sibling = current.sibling
	workInProgress.index = current.index
	workInProgress.ref = current.ref

	if enableProfilerTimer then
		workInProgress.selfBaseDuration = current.selfBaseDuration
		workInProgress.treeBaseDuration = current.treeBaseDuration
	end

	if __DEV__ then
		workInProgress._debugNeedsRemount = current._debugNeedsRemount
		if
			workInProgress.tag == IndeterminateComponent
			or workInProgress.tag == FunctionComponent
			or workInProgress.tag == SimpleMemoComponent
		then
			workInProgress.type = resolveFunctionForHotReloading(current.type)
		elseif workInProgress.tag == ClassComponent then
			workInProgress.type = resolveClassForHotReloading(current.type)
		elseif workInProgress.tag == ForwardRef then
			workInProgress.type = resolveForwardRefForHotReloading(current.type)
		end
	end

	return workInProgress
end

-- Used to reuse a Fiber for a second pass.
local function resetWorkInProgress(workInProgress: Fiber, renderLanes: Lanes)
	-- This resets the Fiber to what createFiber or createWorkInProgress would
	-- have set the values to before during the first pass. Ideally this wouldn't
	-- be necessary but unfortunately many code paths reads from the workInProgress
	-- when they should be reading from current and writing to workInProgress.

	-- We assume pendingProps, index, key, ref, return are still untouched to
	-- avoid doing another reconciliation.

	-- Reset the effect tag but keep any Placement tags, since that's something
	-- that child fiber is setting, not the reconciliation.
	workInProgress.flags =
		bit32.band(workInProgress.flags, bit32.bor(StaticMask, Placement))

	-- The effects are no longer valid

	local current = workInProgress.alternate
	if current == nil then
		-- Reset to createFiber's initial values.
		workInProgress.childLanes = NoLanes
		workInProgress.lanes = renderLanes

		workInProgress.child = nil
		workInProgress.subtreeFlags = NoFlags
		workInProgress.memoizedProps = nil
		workInProgress.memoizedState = nil
		workInProgress.updateQueue = nil

		workInProgress.dependencies = nil

		workInProgress.stateNode = nil

		if enableProfilerTimer then
			-- Note: We don't reset the actualTime counts. It's useful to accumulate
			-- actual time across multiple render passes.
			workInProgress.selfBaseDuration = 0
			workInProgress.treeBaseDuration = 0
		end
	else
		-- Reset to the cloned values that createWorkInProgress would've.
		workInProgress.childLanes = current.childLanes
		workInProgress.lanes = current.lanes

		workInProgress.child = current.child
		workInProgress.subtreeFlags = current.subtreeFlags
		workInProgress.deletions = nil
		workInProgress.memoizedProps = current.memoizedProps
		workInProgress.memoizedState = current.memoizedState
		workInProgress.updateQueue = current.updateQueue
		-- Needed because Blocks store data on type.
		workInProgress.type = current.type

		-- Clone the dependencies object. This is mutated during the render phase, so
		-- it cannot be shared with the current fiber.
		local currentDependencies = current.dependencies
		if currentDependencies == nil then
			workInProgress.dependencies = nil
		else
			workInProgress.dependencies = {
				lanes = currentDependencies.lanes,
				firstContext = currentDependencies.firstContext,
			}
		end

		if enableProfilerTimer then
			-- Note: We don't reset the actualTime counts. It's useful to accumulate
			-- actual time across multiple render passes.
			workInProgress.selfBaseDuration = current.selfBaseDuration
			workInProgress.treeBaseDuration = current.treeBaseDuration
		end
	end

	return workInProgress
end

local function createHostRootFiber(tag: RootTag): Fiber
	local mode
	if tag == ConcurrentRoot then
		mode = bit32.bor(ConcurrentMode, BlockingMode, StrictMode)
	elseif tag == BlockingRoot then
		mode = bit32.bor(BlockingMode, StrictMode)
	else
		mode = NoMode
	end

	-- ROBLOX deviation: We use a function for isDevtoolsPresent to handle the hook being changed at runtime
	if enableProfilerTimer and isDevToolsPresent() then
		-- Always collect profile timings when DevTools are present.
		-- This enables DevTools to start capturing timing at any point–
		-- Without some nodes in the tree having empty base times.
		mode = bit32.bor(mode, ProfileMode)
	end

	return createFiber(HostRoot, nil, nil, mode)
end

local function createFiberFromTypeAndProps(
	type_: any, -- React$ElementType
	key: string?,
	pendingProps: any,
	owner: nil | Fiber,
	mode: TypeOfMode,
	lanes: Lanes
): Fiber
	local fiberTag = IndeterminateComponent
	-- The resolved type is set if we know what the final type will be. I.e. it's not lazy.
	-- deviation: FIXME: Account for deviated class v. function component type logic
	local resolvedType = type_
	local typeOfType_ = type(type_)
	-- deviation: since our class components aren't functions, we have to look
	-- for them more explicitly (inlines logic from `shouldConstruct`)
	if typeOfType_ == "function" then
		if __DEV__ then
			resolvedType = resolveFunctionForHotReloading(resolvedType)
		end
	elseif typeOfType_ == "table" and not not type_.isReactComponent then
		fiberTag = ClassComponent
		if __DEV__ then
			resolvedType = resolveClassForHotReloading(resolvedType)
		end
	elseif typeOfType_ == "string" then
		fiberTag = HostComponent
	else
		if type_ == REACT_FRAGMENT_TYPE then
			return createFiberFromFragment(pendingProps.children, mode, lanes, key)
		elseif type_ == REACT_DEBUG_TRACING_MODE_TYPE then
			fiberTag = Mode
			mode = bit32.bor(mode, DebugTracingMode)
		elseif type_ == REACT_STRICT_MODE_TYPE then
			fiberTag = Mode
			mode = bit32.bor(mode, StrictMode)
		elseif type_ == REACT_PROFILER_TYPE then
			return createFiberFromProfiler(pendingProps, mode, lanes, key)
		elseif type_ == REACT_SUSPENSE_TYPE then
			return createFiberFromSuspense(pendingProps, mode, lanes, key)
			-- elseif type_ == REACT_SUSPENSE_LIST_TYPE then
			-- 	return createFiberFromSuspenseList(pendingProps, mode, lanes, key)
		elseif type_ == REACT_OFFSCREEN_TYPE then
			return createFiberFromOffscreen(pendingProps, mode, lanes, key)
		elseif type_ == REACT_LEGACY_HIDDEN_TYPE then
			return createFiberFromLegacyHidden(pendingProps, mode, lanes, key)
			-- elseif type_ == REACT_SCOPE_TYPE then
			-- 	if enableScopeAPI then
			-- 		return createFiberFromScope(type_, pendingProps, mode, lanes, key)
			-- 	end
		else
			local shouldBreak = false
			local type_typeof
			if typeOfType_ == "table" then
				type_typeof = type_["$$typeof"]
				if type_typeof == REACT_PROVIDER_TYPE then
					fiberTag = ContextProvider
					shouldBreak = true
				elseif type_typeof == REACT_CONTEXT_TYPE then
					-- This is a consumer
					fiberTag = ContextConsumer
					shouldBreak = true
				elseif type_typeof == REACT_FORWARD_REF_TYPE then
					fiberTag = ForwardRef
					if __DEV__ then
						resolvedType = resolveForwardRefForHotReloading(resolvedType)
					end
					shouldBreak = true
				elseif type_typeof == REACT_MEMO_TYPE then
					fiberTag = MemoComponent
					shouldBreak = true
				elseif type_typeof == REACT_LAZY_TYPE then
					fiberTag = LazyComponent
					resolvedType = nil
					shouldBreak = true
					-- elseif type_typeof == REACT_FUNDAMENTAL_TYPE then
					-- 	if enableFundamentalAPI then
					-- 		return createFiberFromFundamental(
					-- 			type_,
					-- 			pendingProps,
					-- 			mode,
					-- 			lanes,
					-- 			key
					-- 		)
					-- 	end
				end
			end
			if not shouldBreak then
				local info = ""
				if __DEV__ then
					if
						type_ == nil
						or (typeOfType_ == "table" and #Object.keys(type_) == 0)
					then
						info ..= [[ You likely forgot to export your component from the file it's defined in, or you might have mixed up default and named imports.]]					
elseif type_ ~= nil and typeOfType_ == "table" then
						-- ROBLOX deviation: print the table/string in readable form to give a clue, if no other info was gathered
						info ..= "\n" .. inspect(type_)
					end
					local ownerName
					if owner then
						ownerName = getComponentName(owner.type)
					end
					if ownerName ~= nil and ownerName ~= "" then
						info ..= "\n\nCheck the render method of `" .. ownerName .. "`."
					elseif owner then
						-- ROBLOX deviation: print the raw table in readable
						-- form to give a clue, if no other info was gathered
						info ..= "\n" .. inspect(owner)
					end
				end

				-- ROBLOX deviation: make output logic consistent across ReactFiber, ElementValidator, Memo, Context, and Lazy
				local typeString
				if type_ == nil then
					typeString = "nil"
				elseif Array.isArray(type_) then
					typeString = "array"
				elseif typeOfType_ == "table" and type_typeof == REACT_ELEMENT_TYPE then
					typeString =
						string.format("<%s />", getComponentName(type_.type) or "Unknown")
					info =
						" Did you accidentally export a JSX literal or Element instead of a component?"
				else
					typeString = typeOfType_
				end

				invariant(
					false,
[[Element type is invalid: expected a string (for built-in components) or a class/function (for composite components) but got: %s.%s]]

,
					typeString,
					info
				)
			end
		end
	end

	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber =
		createFiber(fiberTag, pendingProps, key, mode, type_, resolvedType, nil, lanes)

	-- fiber.elementType = type_
	-- fiber.type = resolvedType
	-- fiber.lanes = lanes
	-- ROBLOX deviation END

	if __DEV__ then
		fiber._debugOwner = owner
	end

	return fiber
end

local function createFiberFromElement(
	element: ReactElement,
	mode: TypeOfMode,
	lanes: Lanes
): Fiber
	local owner 	
if __DEV__ then
		owner = element._owner
	end
	local type = element.type
	local key = element.key
	local pendingProps = element.props
	local fiber = createFiberFromTypeAndProps(
		type,
		-- ROBLOX FIXME: according to upstream types, key can only be string?, but RoactStableKey deviation also says number
		key :: string,
		pendingProps,
		owner,
		mode,
		lanes
	)
	if __DEV__ then
		fiber._debugSource = element._source
		fiber._debugOwner = element._owner
	end
	return fiber
end

function createFiberFromFragment(
	elements: ReactFragment,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(Fragment, elements, key, mode, nil, nil, nil, lanes)
	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

function createFiberFromFundamental(
	fundamentalComponent: ReactFundamentalComponent<any, any>,
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(
		FundamentalComponent,
		pendingProps,
		key,
		mode,
		fundamentalComponent,
		fundamentalComponent,
		nil,
		lanes
	)
	-- fiber.elementType = fundamentalComponent
	-- fiber.type = fundamentalComponent
	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

function createFiberFromScope(
	scope: ReactScope,
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber =
		createFiber(ScopeComponent, pendingProps, key, mode, scope, scope, nil, lanes)
	-- fiber.type = scope
	-- fiber.elementType = scope
	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

function createFiberFromProfiler(
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	if __DEV__ then
		if typeof(pendingProps.id) ~= "string" then
			console.error('Profiler must specify an "id" as a prop')
		end
	end

	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(
		Profiler,
		pendingProps,
		key,
		bit32.bor(mode, ProfileMode),
		REACT_PROFILER_TYPE,
		REACT_PROFILER_TYPE,
		if enableProfilerTimer
			then {
				effectDuration = 0,
				passiveEffectDuration = 0,
			}
			else nil,
		lanes
	)
	-- TODO: The Profiler fiber shouldn't have a type. It has a tag.
	-- fiber.elementType = REACT_PROFILER_TYPE
	-- fiber.type = REACT_PROFILER_TYPE
	-- fiber.lanes = lanes
	-- ROBLOX deviation END

	-- if enableProfilerTimer then
	-- 	fiber.stateNode = {
	-- 		effectDuration = 0,
	-- 		passiveEffectDuration = 0,
	-- 	}
	-- end

	return fiber
end

function createFiberFromSuspense(
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(
		SuspenseComponent,
		pendingProps,
		key,
		mode,
		REACT_SUSPENSE_TYPE,
		REACT_SUSPENSE_TYPE,
		nil,
		lanes
	)

	-- TODO: The SuspenseComponent fiber shouldn't have a type. It has a tag.
	-- This needs to be fixed in getComponentName so that it relies on the tag
	-- instead.
	-- fiber.type = REACT_SUSPENSE_TYPE
	-- fiber.elementType = REACT_SUSPENSE_TYPE

	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

function createFiberFromSuspenseList(
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(
		SuspenseListComponent,
		pendingProps,
		key,
		mode,
		REACT_SUSPENSE_LIST_TYPE,
		if __DEV__ then REACT_SUSPENSE_LIST_TYPE else nil,
		nil,
		lanes
	)
	-- if __DEV__ then
	-- 	-- TODO: The SuspenseListComponent fiber shouldn't have a type. It has a tag.
	-- 	-- This needs to be fixed in getComponentName so that it relies on the tag
	-- 	-- instead.
	-- 	fiber.type = REACT_SUSPENSE_LIST_TYPE
	-- end
	-- fiber.elementType = REACT_SUSPENSE_LIST_TYPE
	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

function createFiberFromOffscreen(
	pendingProps: OffscreenProps,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(
		OffscreenComponent,
		pendingProps,
		key,
		mode,
		REACT_OFFSCREEN_TYPE,
		if __DEV__ then REACT_OFFSCREEN_TYPE else nil,
		nil,
		lanes
	)
	-- TODO: The OffscreenComponent fiber shouldn't have a type. It has a tag.
	-- This needs to be fixed in getComponentName so that it relies on the tag
	-- instead.
	-- if __DEV__ then
	-- 	fiber.type = REACT_OFFSCREEN_TYPE
	-- end
	-- fiber.elementType = REACT_OFFSCREEN_TYPE
	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

function createFiberFromLegacyHidden(
	pendingProps: OffscreenProps,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(
		LegacyHiddenComponent,
		pendingProps,
		key,
		mode,
		REACT_LEGACY_HIDDEN_TYPE,
		if __DEV__ then REACT_LEGACY_HIDDEN_TYPE else nil,
		nil,
		lanes
	)
	-- TODO: The LegacyHidden fiber shouldn't have a type. It has a tag.
	-- This needs to be fixed in getComponentName so that it relies on the tag
	-- instead.
	-- if __DEV__ then
	-- 	fiber.type = REACT_LEGACY_HIDDEN_TYPE
	-- end
	-- fiber.elementType = REACT_LEGACY_HIDDEN_TYPE
	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

local function createFiberFromText(content: string, mode: TypeOfMode, lanes: Lanes): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(HostText, content, nil, mode, nil, nil, nil, lanes)
	-- fiber.lanes = lanes
	-- ROBLOX deviation END
	return fiber
end

local function createFiberFromHostInstanceForDeletion(): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(HostComponent, nil, nil, NoMode, "DELETED", "DELETED")
	-- TODO: These should not need a type.
	-- fiber.elementType = "DELETED"
	-- fiber.type = "DELETED"
	-- ROBLOX deviation END
	return fiber
end

local function createFiberFromDehydratedFragment(dehydratedNode: SuspenseInstance): Fiber
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber =
		createFiber(DehydratedFragment, nil, nil, NoMode, nil, nil, dehydratedNode)
	-- fiber.stateNode = dehydratedNode
	-- ROBLOX deviation END
	return fiber
end

local function createFiberFromPortal(
	portal: ReactPortal,
	mode: TypeOfMode,
	lanes: Lanes
): Fiber
	local pendingProps = if portal.children ~= nil then portal.children else {}
	-- ROBLOX deviation START: we pass in all needed values so the table creation+field assignment is a one-shot
	local fiber = createFiber(HostPortal, pendingProps, portal.key, mode, nil, nil, {
		containerInfo = portal.containerInfo,
		pendingChildren = nil, -- Used by persistent updates
		implementation = portal.implementation,
	}, lanes)
	-- fiber.lanes = lanes
	-- fiber.stateNode = {
	-- 	containerInfo = portal.containerInfo,
	-- 	pendingChildren = nil, -- Used by persistent updates
	-- 	implementation = portal.implementation,
	-- }
	-- ROBLOX deviation END
	return fiber
end

-- Used for stashing WIP properties to replay failed work in DEV.
-- ROBLOX FIXME: `target: Fiber | nil` - Narrowing doesn't work even with nil check
local function assignFiberPropertiesInDEV(target: Fiber, source: Fiber): Fiber
	if target == nil then
		-- This Fiber's initial properties will always be overwritten.
		-- We only use a Fiber to ensure the same hidden class so DEV isn't slow.
		target = createFiber(IndeterminateComponent, nil, nil, NoMode)
	end

	-- This is intentionally written as a list of all properties.
	-- We tried to use Object.assign() instead but this is called in
	-- the hottest path, and Object.assign() was too slow:
	-- https://github.com/facebook/react/issues/12502
	-- This code is DEV-only so size is not a concern.

	target.tag = source.tag
	target.key = source.key
	target.elementType = source.elementType
	target.type = source.type
	target.stateNode = source.stateNode
	target.return_ = source.return_
	target.child = source.child
	target.sibling = source.sibling
	target.index = source.index
	target.ref = source.ref
	target.pendingProps = source.pendingProps
	target.memoizedProps = source.memoizedProps
	target.updateQueue = source.updateQueue
	target.memoizedState = source.memoizedState
	target.dependencies = source.dependencies
	target.mode = source.mode
	target.flags = source.flags
	target.subtreeFlags = source.subtreeFlags
	target.deletions = source.deletions
	target.lanes = source.lanes
	target.childLanes = source.childLanes
	target.alternate = source.alternate
	if enableProfilerTimer then
		target.actualDuration = source.actualDuration
		target.actualStartTime = source.actualStartTime
		target.selfBaseDuration = source.selfBaseDuration
		target.treeBaseDuration = source.treeBaseDuration
	end
	target._debugID = source._debugID
	target._debugSource = source._debugSource
	target._debugOwner = source._debugOwner
	target._debugNeedsRemount = source._debugNeedsRemount
	target._debugHookTypes = source._debugHookTypes
	return target
end

-- deviation: more convenient to export entire interface at the end
return {
	isSimpleFunctionComponent = isSimpleFunctionComponent,
	resolveLazyComponentTag = resolveLazyComponentTag,
	createWorkInProgress = createWorkInProgress,
	resetWorkInProgress = resetWorkInProgress,
	createHostRootFiber = createHostRootFiber,
	createFiberFromTypeAndProps = createFiberFromTypeAndProps,
	createFiberFromElement = createFiberFromElement,
	createFiberFromFragment = createFiberFromFragment,
	createFiberFromFundamental = createFiberFromFundamental,
	createFiberFromSuspense = createFiberFromSuspense,
	createFiberFromSuspenseList = createFiberFromSuspenseList,
	createFiberFromOffscreen = createFiberFromOffscreen,
	createFiberFromLegacyHidden = createFiberFromLegacyHidden,
	createFiberFromText = createFiberFromText,
	createFiberFromHostInstanceForDeletion = createFiberFromHostInstanceForDeletion,
	createFiberFromDehydratedFragment = createFiberFromDehydratedFragment,
	createFiberFromPortal = createFiberFromPortal,
	assignFiberPropertiesInDEV = assignFiberPropertiesInDEV,
}

end,
["react-reconciler/ReactFiberBeginWork.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/1faf9e3dd5d6492f3607d5c721055819e4106bc6/packages/react-reconciler/src/ReactFiberBeginWork.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- ROBLOX TODO remove this when CLI-38793 lands
--!nolint LocalShadow
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. tostring(message))
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local __DEV__ = _G.__DEV__ :: boolean
local __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ =
	_G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ :: boolean
local __COMPAT_WARNINGS__ = _G.__COMPAT_WARNINGS__ :: boolean

-- ROBLOX: use patched console from Shared
local Shared = require(script.Parent.Parent:WaitForChild('shared'))
local console = Shared.console
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local inspect = LuauPolyfill.util.inspect

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
type ReactContext<T> = ReactTypes.ReactContext<T>
type React_Component<Props, State> = ReactTypes.React_Component<Props, State>

local React = require(script.Parent.Parent:WaitForChild('react'))
type LazyComponentType<T, P> = React.LazyComponent<T, P>

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
-- type Lane = ReactFiberLane.Lane;
-- local type {MutableSource} = require(Packages.Shared.ReactTypes)

local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState
type SuspenseListRenderState = ReactFiberSuspenseComponent.SuspenseListRenderState
type SuspenseListTailMode = ReactFiberSuspenseComponent.SuspenseListTailMode
local ReactFiberSuspenseContext = require(script.Parent:WaitForChild('ReactFiberSuspenseContext.new'))
type SuspenseContext = ReactFiberSuspenseContext.SuspenseContext

local ReactFiberOffscreenComponent = require(script.Parent:WaitForChild('ReactFiberOffscreenComponent'))
type OffscreenProps = ReactFiberOffscreenComponent.OffscreenProps
type OffscreenState = ReactFiberOffscreenComponent.OffscreenState

local checkPropTypes = require(script.Parent.Parent:WaitForChild('shared')).checkPropTypes

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))-- local IndeterminateComponent = ReactWorkTags.IndeterminateComponent

local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local Mode = ReactWorkTags.Mode
local ContextProvider = ReactWorkTags.ContextProvider
local ContextConsumer = ReactWorkTags.ContextConsumer
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local LazyComponent = ReactWorkTags.LazyComponent
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent
-- local FundamentalComponent = ReactWorkTags.FundamentalComponent
-- local ScopeComponent = ReactWorkTags.ScopeComponent
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local NoFlags = ReactFiberFlags.NoFlags
local StaticMask = ReactFiberFlags.StaticMask
local PerformedWork = ReactFiberFlags.PerformedWork
local Placement = ReactFiberFlags.Placement
local Hydrating = ReactFiberFlags.Hydrating
local ContentReset = ReactFiberFlags.ContentReset
local DidCapture = ReactFiberFlags.DidCapture
-- local Update = ReactFiberFlags.Update
local Ref = ReactFiberFlags.Ref
local Deletion = ReactFiberFlags.Deletion
local ForceUpdateForLegacySuspense = ReactFiberFlags.ForceUpdateForLegacySuspense
local ReactSharedInternals = require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local debugRenderPhaseSideEffectsForStrictMode =
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode
local disableLegacyContext = ReactFeatureFlags.disableLegacyContext
local disableModulePatternComponents = ReactFeatureFlags.disableModulePatternComponents
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
local warnAboutDefaultPropsOnFunctionComponents =
	ReactFeatureFlags.warnAboutDefaultPropsOnFunctionComponents
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError
local shallowEqual = require(script.Parent.Parent:WaitForChild('shared')).shallowEqual
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local _getIteratorFn = ReactSymbols.getIteratorFn
local ReactStrictModeWarnings = require(script.Parent:WaitForChild('ReactStrictModeWarnings.new'))
local ReactCurrentFiber = require(script.Parent:WaitForChild('ReactCurrentFiber'))
local getCurrentFiberOwnerNameInDevOrNull =
	ReactCurrentFiber.getCurrentFiberOwnerNameInDevOrNull
local setIsRendering = ReactCurrentFiber.setIsRendering
local ReactFiberHotReloadingModule = require(script.Parent:WaitForChild('ReactFiberHotReloading.new'))
local resolveFunctionForHotReloading =
	ReactFiberHotReloadingModule.resolveFunctionForHotReloading
local resolveForwardRefForHotReloading =
	ReactFiberHotReloadingModule.resolveForwardRefForHotReloading
local resolveClassForHotReloading =
	ReactFiberHotReloadingModule.resolveClassForHotReloading

local ReactChildFiber = require(script.Parent:WaitForChild('ReactChildFiber.new')):: any
local mountChildFibers = ReactChildFiber.mountChildFibers
local reconcileChildFibers = ReactChildFiber.reconcileChildFibers
local cloneChildFibers = ReactChildFiber.cloneChildFibers
local ReactUpdateQueue = require(script.Parent:WaitForChild('ReactUpdateQueue.new'))
local processUpdateQueue = ReactUpdateQueue.processUpdateQueue
local cloneUpdateQueue = ReactUpdateQueue.cloneUpdateQueue
local initializeUpdateQueue = ReactUpdateQueue.initializeUpdateQueue
local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
local NoMode = ReactTypeOfMode.NoMode
local ProfileMode = ReactTypeOfMode.ProfileMode
local StrictMode = ReactTypeOfMode.StrictMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
local shouldSetTextContent = ReactFiberHostConfig.shouldSetTextContent
local isSuspenseInstancePending = ReactFiberHostConfig.isSuspenseInstancePending
local isSuspenseInstanceFallback = ReactFiberHostConfig.isSuspenseInstanceFallback
local registerSuspenseInstanceRetry = ReactFiberHostConfig.registerSuspenseInstanceRetry
local supportsHydration = ReactFiberHostConfig.supportsHydration
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance

local ReactFiberHostContext = require(script.Parent:WaitForChild('ReactFiberHostContext.new'))
local pushHostContext = ReactFiberHostContext.pushHostContext
local pushHostContainer = ReactFiberHostContext.pushHostContainer
local suspenseStackCursor = ReactFiberSuspenseContext.suspenseStackCursor
local hasSuspenseContext = ReactFiberSuspenseContext.hasSuspenseContext
local ForceSuspenseFallback = ReactFiberSuspenseContext.ForceSuspenseFallback
local addSubtreeSuspenseContext = ReactFiberSuspenseContext.addSubtreeSuspenseContext
local InvisibleParentSuspenseContext =
	ReactFiberSuspenseContext.InvisibleParentSuspenseContext
local pushSuspenseContext = ReactFiberSuspenseContext.pushSuspenseContext
-- local setShallowSuspenseContext = ReactFiberSuspenseContext.setShallowSuspenseContext
local setDefaultShallowSuspenseContext =
	ReactFiberSuspenseContext.setDefaultShallowSuspenseContext
-- local {findFirstSuspended} = require("./ReactFiberSuspenseComponent/new")
-- local {
--   ,
local ReactFiberNewContext = require(script.Parent:WaitForChild('ReactFiberNewContext.new'))
local propagateContextChange = ReactFiberNewContext.propagateContextChange
local readContext = ReactFiberNewContext.readContext
local calculateChangedBits = ReactFiberNewContext.calculateChangedBits
-- local scheduleWorkOnParentPath = ReactFiberNewContext.scheduleWorkOnParentPath
local prepareToReadContext = ReactFiberNewContext.prepareToReadContext
local pushProvider = ReactFiberNewContext.pushProvider

-- ROBLOX deviation: Lazy init all methods from ReactFiberHooks
local lazyRefs = {
	renderWithHooksRef = nil :: any,
	bailoutHooksRef = nil :: any,
	shouldSuspendRef = nil :: any,
}

local function shouldSuspend(fiber: Fiber): boolean
	if not lazyRefs.shouldSuspendRef then
		lazyRefs.shouldSuspendRef = require(script.Parent:WaitForChild('ReactFiberReconciler')).shouldSuspend
	end
	return lazyRefs.shouldSuspendRef(fiber)
end

-- ROBLOX deviation: collective lazy init methods from ReactFiberHooks
local function initReactFiberHooks()
	local ReactFiberHooks = require(script.Parent:WaitForChild('ReactFiberHooks.new'))	
lazyRefs.renderWithHooksRef = ReactFiberHooks.renderWithHooks
	lazyRefs.bailoutHooksRef = ReactFiberHooks.bailoutHooks
end

-- ROBLOX deviation: Lazy init renderWithHooks from ReactFiberHooks
local function renderWithHooks(...)
	if not lazyRefs.renderWithHooksRef then
		initReactFiberHooks()
	end
	return lazyRefs.renderWithHooksRef(...)
end

-- ROBLOX deviation: Lazy init bailoutHooks from ReactFiberHooks
local function bailoutHooks(...)
	if not lazyRefs.bailoutHooksRef then
		initReactFiberHooks()
	end
	return lazyRefs.bailoutHooksRef(...)
end

local stopProfilerTimerIfRunning =
	require(script.Parent:WaitForChild('ReactProfilerTimer.new')).stopProfilerTimerIfRunning
local ReactFiberContext = require(script.Parent:WaitForChild('ReactFiberContext.new'))
local getMaskedContext = ReactFiberContext.getMaskedContext
local getUnmaskedContext = ReactFiberContext.getUnmaskedContext
local hasLegacyContextChanged = ReactFiberContext.hasContextChanged
local pushLegacyContextProvider = ReactFiberContext.pushContextProvider
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local pushTopLevelContextObject = ReactFiberContext.pushTopLevelContextObject
local invalidateContextProvider = ReactFiberContext.invalidateContextProvider

local ReactFiberHydrationContext = require(script.Parent:WaitForChild('ReactFiberHydrationContext.new'))
local resetHydrationState = ReactFiberHydrationContext.resetHydrationState
local enterHydrationState = ReactFiberHydrationContext.enterHydrationState
local reenterHydrationStateFromDehydratedSuspenseInstance =
	ReactFiberHydrationContext.reenterHydrationStateFromDehydratedSuspenseInstance
local tryToClaimNextHydratableInstance =
	ReactFiberHydrationContext.tryToClaimNextHydratableInstance
local warnIfHydrating = ReactFiberHydrationContext.warnIfHydrating
local ReactFiberClassComponent = require(script.Parent:WaitForChild('ReactFiberClassComponent.new')):: any
local adoptClassInstance = ReactFiberClassComponent.adoptClassInstance
local applyDerivedStateFromProps = ReactFiberClassComponent.applyDerivedStateFromProps
local constructClassInstance = ReactFiberClassComponent.constructClassInstance
local mountClassInstance = ReactFiberClassComponent.mountClassInstance
local resumeMountClassInstance = ReactFiberClassComponent.resumeMountClassInstance
local updateClassInstance = ReactFiberClassComponent.updateClassInstance

local resolveDefaultProps =
	require(script.Parent:WaitForChild('ReactFiberLazyComponent.new')).resolveDefaultProps
local ReactFiber = require(script.Parent:WaitForChild('ReactFiber.new'))
local resolveLazyComponentTag = ReactFiber.resolveLazyComponentTag
local createFiberFromFragment = ReactFiber.createFiberFromFragment
local createFiberFromOffscreen = ReactFiber.createFiberFromOffscreen

local createFiberFromTypeAndProps = ReactFiber.createFiberFromTypeAndProps
local isSimpleFunctionComponent = ReactFiber.isSimpleFunctionComponent
local createWorkInProgress = ReactFiber.createWorkInProgress
local ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new')):: any
local pushRenderLanes = ReactFiberWorkLoop.pushRenderLanes
local markSpawnedWork = ReactFiberWorkLoop.markSpawnedWork
local retryDehydratedSuspenseBoundary = ReactFiberWorkLoop.retryDehydratedSuspenseBoundary
local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local renderDidSuspendDelayIfPossible = ReactFiberWorkLoop.renderDidSuspendDelayIfPossible
local getWorkInProgressRoot = ReactFiberWorkLoop.getWorkInProgressRoot
local getExecutionContext = ReactFiberWorkLoop.getExecutionContext
local RetryAfterError = ReactFiberWorkLoop.RetryAfterError
local NoContext = ReactFiberWorkLoop.NoContext

local Schedule_tracing_wrap
local setWorkInProgressVersion =
	require(script.Parent:WaitForChild('ReactMutableSource.new')).setWorkInProgressVersion
local markSkippedUpdateLanes =
	require(script.Parent:WaitForChild('ReactFiberWorkInProgress')).markSkippedUpdateLanes
local ConsolePatchingDev = require(script.Parent.Parent:WaitForChild('shared')).ConsolePatchingDev
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

local ReactCurrentOwner = ReactSharedInternals.ReactCurrentOwner

local exports: { [string]: any } = {}

-- ROBLOX deviation: Pre-declare functions
local bailoutOnAlreadyFinishedWork, updateFunctionComponent

local didReceiveUpdate: boolean = false

-- ROBLOX deviation: put didWarns in table to reduce number of local variables
local DidWarn = {
	didWarnAboutBadClass = {} :: { [string]: boolean },
	didWarnAboutModulePatternComponent = {} :: { [string]: boolean },
	didWarnAboutContextTypeOnFunctionComponent = {} :: { [string]: boolean },
	didWarnAboutGetDerivedStateOnFunctionComponent = {} :: { [string]: boolean },
	didWarnAboutFunctionRefs = {} :: { [string]: boolean },
	didWarnAboutDefaultPropsOnFunctionComponent = {} :: { [string]: boolean },
}
-- export local didWarnAboutReassigningProps
-- local didWarnAboutRevealOrder
-- local didWarnAboutTailOptions
local updateSimpleMemoComponent

if __DEV__ then
	DidWarn.didWarnAboutBadClass = {}
	DidWarn.didWarnAboutModulePatternComponent = {}
	DidWarn.didWarnAboutContextTypeOnFunctionComponent = {}
	DidWarn.didWarnAboutGetDerivedStateOnFunctionComponent = {}
	DidWarn.didWarnAboutFunctionRefs = {}
	exports.didWarnAboutReassigningProps = false
	--   didWarnAboutRevealOrder = {}
	--   didWarnAboutTailOptions = {}
	DidWarn.didWarnAboutDefaultPropsOnFunctionComponent = {}
end

local function reconcileChildren(
	current: Fiber | nil,
	workInProgress: Fiber,
	nextChildren: any,
	renderLanes: Lanes
)
	if current == nil then
		-- If this is a fresh new component that hasn't been rendered yet, we
		-- won't update its child set by applying minimal side-effects. Instead,
		-- we will add them all to the child before it gets rendered. That means
		-- we can optimize this reconciliation pass by not tracking side-effects.
		workInProgress.child =
			mountChildFibers(workInProgress, nil, nextChildren, renderLanes)
	else
		-- If the current child is the same as the work in progress, it means that
		-- we haven't yet started any work on these children. Therefore, we use
		-- the clone algorithm to create a copy of all the current children.

		-- If we had any progressed work already, that is invalid at this point so
		-- let's throw it out.
		workInProgress.child = reconcileChildFibers(
			workInProgress,
			(current :: Fiber).child,
			nextChildren,
			renderLanes
		)
	end
end

local function forceUnmountCurrentAndReconcile(
	current: Fiber,
	workInProgress: Fiber,
	nextChildren: any,
	renderLanes: Lanes
)
	-- This function is fork of reconcileChildren. It's used in cases where we
	-- want to reconcile without matching against the existing set. This has the
	-- effect of all current children being unmounted; even if the type and key
	-- are the same, the old child is unmounted and a new child is created.
	--
	-- To do this, we're going to go through the reconcile algorithm twice. In
	-- the first pass, we schedule a deletion for all the current children by
	-- passing nil.
	workInProgress.child =
		reconcileChildFibers(workInProgress, current.child, nil, renderLanes)
	-- In the second pass, we mount the new children. The trick here is that we
	-- pass nil in place of where we usually pass the current child set. This has
	-- the effect of remounting all children regardless of whether their
	-- identities match.
	workInProgress.child =
		reconcileChildFibers(workInProgress, nil, nextChildren, renderLanes)
end

local function updateForwardRef(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	renderLanes: Lanes
)
	-- TODO: current can be non-null here even if the component
	-- hasn't yet mounted. This happens after the first render suspends.
	-- We'll need to figure out if this is fine or can cause issues.

	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if workInProgress.type ~= workInProgress.elementType then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes = Component.propTypes
			local validateProps = Component.validateProps
			if innerPropTypes or validateProps then
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(Component)
				)
			end
		end
	end

	local render = Component.render
	local ref = workInProgress.ref

	-- The rest is a fork of updateFunctionComponent
	local nextChildren
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	if __DEV__ then
		ReactCurrentOwner.current = workInProgress
		setIsRendering(true)
		nextChildren =
			renderWithHooks(current, workInProgress, render, nextProps, ref, renderLanes)
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			local ok, result = xpcall(
				renderWithHooks,
				describeError,
				current,
				workInProgress,
				render,
				nextProps,
				ref,
				renderLanes
			)
			if ok then
				nextChildren = result
			end
			-- finally
			reenableLogs()

			if not ok then
				error(result)
			end
		end
		setIsRendering(false)
	else
		nextChildren =
			renderWithHooks(current, workInProgress, render, nextProps, ref, renderLanes)
	end

	if current ~= nil and not didReceiveUpdate then
		bailoutHooks(current, workInProgress, renderLanes)
		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

local function updateMemoComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	updateLanes: Lanes,
	renderLanes: Lanes
): nil | Fiber
	if current == nil then
		local type_ = Component.type
		if
			isSimpleFunctionComponent(type_)
			and Component.compare == nil
			-- SimpleMemoComponent codepath doesn't resolve outer props either.
			and Component.defaultProps == nil
		then
			local resolvedType = type_
			if __DEV__ then
				resolvedType = resolveFunctionForHotReloading(type_)
			end
			-- If this is a plain function component without default props,
			-- and with only the default shallow comparison, we upgrade it
			-- to a SimpleMemoComponent to allow fast path updates.
			workInProgress.tag = SimpleMemoComponent
			workInProgress.type = resolvedType
			if __DEV__ then
				validateFunctionComponentInDev(workInProgress, type_)
			end
			return updateSimpleMemoComponent(
				current,
				workInProgress,
				resolvedType,
				nextProps,
				updateLanes,
				renderLanes
			)
		end
		if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes
			local validateProps
			-- ROBLOX deviation: avoid accessing propTypes on a function, Lua doesn't support fields on functions
			if type(type_) == "table" then
				innerPropTypes = type_.propTypes
				validateProps = type_.validateProps
			end

			if innerPropTypes or validateProps then
				-- Inner memo component props aren't currently validated in createElement.
				-- We could move it there, but we'd still need this for lazy code path.
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(type_)
				)
			end
		end
		local child = createFiberFromTypeAndProps(
			Component.type,
			nil,
			nextProps,
			workInProgress,
			workInProgress.mode,
			renderLanes
		)
		child.ref = workInProgress.ref
		child.return_ = workInProgress
		workInProgress.child = child
		return child
	end
	-- ROBLOX TODO Deviation: remove redefinition + typecast when this lands: CLI-38793
	-- ROBLOX the if clause above returns early if current is nil
	local current = current :: Fiber
	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		local type_ = Component.type
		-- ROBLOX deviation: adds support for legacy Roact's validateProps()
		local innerPropTypes
		local validateProps
		-- ROBLOX deviation: only check for propTypes on class components, Lua doesn't support fields on functions
		if type(type_) == "table" then
			innerPropTypes = type_.propTypes
			validateProps = type_.validateProps
		end

		if innerPropTypes or validateProps then
			-- Inner memo component props aren't currently validated in createElement.
			-- We could move it there, but we'd still need this for lazy code path.
			checkPropTypes(
				innerPropTypes,
				validateProps,
				nextProps, -- Resolved props
				"prop",
				getComponentName(type_)
			)
		end
	end
	local currentChild = (current.child :: any) :: Fiber -- This is always exactly one child
	if not ReactFiberLane.includesSomeLane(updateLanes, renderLanes) then
		-- This will be the props with resolved defaultProps,
		-- unlike current.memoizedProps which will be the unresolved ones.
		local prevProps = currentChild.memoizedProps
		-- Default to shallow comparison
		local compare = Component.compare
		if compare == nil then
			compare = shallowEqual
		end
		if compare(prevProps, nextProps) and current.ref == workInProgress.ref then
			return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
		end
	end
	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	local newChild = createWorkInProgress(currentChild, nextProps)
	newChild.ref = workInProgress.ref
	newChild.return_ = workInProgress
	workInProgress.child = newChild
	return newChild
end

function updateSimpleMemoComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	updateLanes: Lanes,
	renderLanes: Lanes
): nil | Fiber
	-- TODO: current can be non-null here even if the component
	-- hasn't yet mounted. This happens when the inner render suspends.
	-- We'll need to figure out if this is fine or can cause issues.

	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if workInProgress.type ~= workInProgress.elementType then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			local outerMemoType = workInProgress.elementType
			if outerMemoType["$$typeof"] == REACT_LAZY_TYPE then
				-- We warn when you define propTypes on lazy()
				-- so let's just skip over it to find memo() outer wrapper.
				-- Inner props for memo are validated later.
				local lazyComponent: LazyComponentType<any, any> = outerMemoType
				local payload = lazyComponent._payload
				local init = lazyComponent._init
				local ok, result = xpcall(init, describeError, payload)
				if ok then
					outerMemoType = result
				else
					outerMemoType = nil
				end
				-- Inner propTypes will be validated in the function component path.
				-- ROBLOX deviation: adds support for legacy Roact's validateProps()
				local outerPropTypes
				local validateProps
				-- ROBLOX deviation: avoid accessing propTypes on a function, Lua doesn't support fields on functions
				if outerMemoType ~= nil and type(outerMemoType) == "table" then
					outerPropTypes = (outerMemoType :: any).propTypes
					-- ROBLOX deviation: support legacy Roact's equivalent of propTypes
					validateProps = (outerMemoType :: any).validateProps
				end

				if outerPropTypes or validateProps then
					checkPropTypes(
						outerPropTypes,
						validateProps,
						nextProps, -- Resolved (SimpleMemoComponent has no defaultProps)
						"prop",
						getComponentName(outerMemoType)
					)
				end
			end
		end
	end
	if current ~= nil then
		-- ROBLOX TODO Deviation: remove redefinition + typecast when this lands: CLI-38793
		-- This unfortunately breaks if current gets reassigned somewhere in this if clause
		local current = current :: Fiber
		local prevProps = current.memoizedProps
		-- ROBLOX Deviation: replacing ternary operator
		local preventBailout = true
		if __DEV__ then
			preventBailout = workInProgress.type == current.type
		end
		if
			shallowEqual(prevProps, nextProps)
			and current.ref == workInProgress.ref
			-- Prevent bailout if the implementation changed due to hot reload.
			and preventBailout
		then
			didReceiveUpdate = false
			if not ReactFiberLane.includesSomeLane(renderLanes, updateLanes) then
				-- The pending lanes were cleared at the beginning of beginWork. We're
				-- about to bail out, but there might be other lanes that weren't
				-- included in the current render. Usually, the priority level of the
				-- remaining updates is accumlated during the evaluation of the
				-- component (i.e. when processing the update queue). But since since
				-- we're bailing out early *without* evaluating the component, we need
				-- to account for it here, too. Reset to the value of the current fiber.
				-- NOTE: This only applies to SimpleMemoComponent, not MemoComponent,
				-- because a MemoComponent fiber does not have hooks or an update queue
				-- rather, it wraps around an inner component, which may or may not
				-- contains hooks.
				-- TODO: Move the reset at in beginWork out of the common path so that
				-- this is no longer necessary.
				workInProgress.lanes = current.lanes
				return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
			elseif bit32.band(current.flags, ForceUpdateForLegacySuspense) ~= NoFlags then
				-- This is a special case that only exists for legacy mode.
				-- See https://github.com/facebook/react/pull/19216.
				didReceiveUpdate = true
			end
		end
	end
	return updateFunctionComponent(
		current,
		workInProgress,
		Component,
		nextProps,
		renderLanes
	)
end

local function updateOffscreenComponent(
	current: Fiber?,
	workInProgress: Fiber,
	renderLanes: Lanes
): Fiber | nil
	local nextProps: OffscreenProps = workInProgress.pendingProps
	local nextChildren = nextProps.children

	local prevState: OffscreenState?
	if current ~= nil then
		-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil checks
		prevState = (current :: Fiber).memoizedState
	end

	if
		nextProps.mode == "hidden"
		or nextProps.mode == "unstable-defer-without-hiding"
	then
		if bit32.band(workInProgress.mode, ConcurrentMode) == NoMode then
			-- In legacy sync mode, don't defer the subtree. Render it now.
			-- TODO: Figure out what we should do in Blocking mode.
			local nextState: OffscreenState = {
				baseLanes = ReactFiberLane.NoLanes,
			}
			workInProgress.memoizedState = nextState
			pushRenderLanes(workInProgress, renderLanes)
		-- ROBLOX TODO: recast ReactFiberLane.OffscreenLane to type Lane
		elseif
			not ReactFiberLane.includesSomeLane(renderLanes, ReactFiberLane.OffscreenLane)
		then
			local nextBaseLanes
			if prevState ~= nil then
				-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil check
				local prevBaseLanes = (prevState :: OffscreenState).baseLanes
				nextBaseLanes = ReactFiberLane.mergeLanes(prevBaseLanes, renderLanes)
			else
				nextBaseLanes = renderLanes
			end

			-- Schedule this fiber to re-render at offscreen priority. Then bailout.
			if enableSchedulerTracing then
				markSpawnedWork(ReactFiberLane.OffscreenLane)
			end

			-- deviation: unchain multiple assignment into two discrete assignments.
			workInProgress.childLanes =
				ReactFiberLane.laneToLanes(ReactFiberLane.OffscreenLane)
			workInProgress.lanes = workInProgress.childLanes

			local nextState: OffscreenState = {
				baseLanes = nextBaseLanes,
			}
			workInProgress.memoizedState = nextState
			-- We're about to bail out, but we need to push this to the stack anyway
			-- to avoid a push/pop misalignment.
			pushRenderLanes(workInProgress, nextBaseLanes)
			return nil
		else
			-- Rendering at offscreen, so we can clear the base lanes.
			local nextState: OffscreenState = {
				baseLanes = ReactFiberLane.NoLanes,
			}
			workInProgress.memoizedState = nextState
			-- Push the lanes that were skipped when we bailed out.
			local subtreeRenderLanes = renderLanes

			-- deviation: ternary converted to if statement
			if prevState ~= nil then
				-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil check
				subtreeRenderLanes = (prevState :: OffscreenState).baseLanes
			end

			pushRenderLanes(workInProgress, subtreeRenderLanes)
		end
	else
		local subtreeRenderLanes
		if prevState ~= nil then
			-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil check
			subtreeRenderLanes = ReactFiberLane.mergeLanes(
				(prevState :: OffscreenState).baseLanes,
				renderLanes
			)
			-- Since we're not hidden anymore, reset the state
			workInProgress.memoizedState = nil
		else
			-- We weren't previously hidden, and we still aren't, so there's nothing
			-- special to do. Need to push to the stack regardless, though, to avoid
			-- a push/pop misalignment.
			subtreeRenderLanes = renderLanes
		end
		pushRenderLanes(workInProgress, subtreeRenderLanes)
	end

	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

-- Note: These happen to have identical begin phases, for now. We shouldn't hold
-- ourselves to this constraint, though. If the behavior diverges, we should
-- fork the function.
local updateLegacyHiddenComponent = updateOffscreenComponent

function updateFragment(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes)
	local nextChildren = workInProgress.pendingProps
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

function updateMode(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes)
	local nextChildren = workInProgress.pendingProps.children
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

function updateProfiler(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes)
	if enableProfilerTimer then
		-- Reset effect durations for the next eventual effect phase.
		-- These are reset during render to allow the DevTools commit hook a chance to read them,
		local stateNode = workInProgress.stateNode
		stateNode.effectDuration = 0
		stateNode.passiveEffectDuration = 0
	end
	local nextProps = workInProgress.pendingProps
	local nextChildren = nextProps.children
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

local function markRef(current: Fiber | nil, workInProgress: Fiber)
	local ref = workInProgress.ref
	if
		(current == nil and ref ~= nil)
		or (current ~= nil and (current :: Fiber).ref ~= ref)
	then
		-- Schedule a Ref effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Ref)
	end
end

function updateFunctionComponent(
	current,
	workInProgress,
	Component,
	nextProps: any,
	renderLanes
)
	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		-- ROBLOX deviation: function components can't have props in Lua
		if
			type(Component) ~= "function"
			and (workInProgress.type ~= workInProgress.elementType)
		then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes
			local validateProps
			-- ROBLOX deviation: Roact won't support propTypes on functional components
			if type(Component) == "table" then
				innerPropTypes = (Component :: any).propTypes
				validateProps = (Component :: any).validateProps
			end

			if innerPropTypes or validateProps then
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(Component)
				)
			end
		end
	end

	local context
	if not disableLegacyContext then
		local unmaskedContext = getUnmaskedContext(workInProgress, Component, true)
		context = getMaskedContext(workInProgress, unmaskedContext)
	end

	local nextChildren
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	if __DEV__ then
		ReactCurrentOwner.current = workInProgress
		setIsRendering(true)
		nextChildren = renderWithHooks(
			current,
			workInProgress,
			Component,
			nextProps,
			context,
			renderLanes
		)
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			local ok, result = xpcall(
				renderWithHooks,
				describeError,
				current,
				workInProgress,
				Component,
				nextProps,
				context,
				renderLanes
			)
			-- finally
			reenableLogs()
			if ok then
				nextChildren = result
			else
				error(result)
			end
		end
		setIsRendering(false)
	else
		nextChildren = renderWithHooks(
			current,
			workInProgress,
			Component,
			nextProps,
			context,
			renderLanes
		)
	end

	if current ~= nil and not didReceiveUpdate then
		bailoutHooks(current, workInProgress, renderLanes)
		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

-- function updateBlock<Props, Data>(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   block: BlockComponent<Props, Data>,
--   nextProps: any,
--   renderLanes: Lanes,
-- )
--   -- TODO: current can be non-null here even if the component
--   -- hasn't yet mounted. This happens after the first render suspends.
--   -- We'll need to figure out if this is fine or can cause issues.

--   local render = block._render
--   local data = block._data

--   -- The rest is a fork of updateFunctionComponent
--   local nextChildren
--   prepareToReadContext(workInProgress, renderLanes, exports.markWorkInProgressReceivedUpdate)
--   if  __DEV__ then
--     ReactCurrentOwner.current = workInProgress
--     setIsRendering(true)
--     nextChildren = renderWithHooks(
--       current,
--       workInProgress,
--       render,
--       nextProps,
--       data,
--       renderLanes,
--     )
--     if
--       debugRenderPhaseSideEffectsForStrictMode and
--       workInProgress.mode & StrictMode
--     )
--       disableLogs()
--       try {
--         nextChildren = renderWithHooks(
--           current,
--           workInProgress,
--           render,
--           nextProps,
--           data,
--           renderLanes,
--         )
--       } finally {
--         reenableLogs()
--       end
--     end
--     setIsRendering(false)
--   else
--     nextChildren = renderWithHooks(
--       current,
--       workInProgress,
--       render,
--       nextProps,
--       data,
--       renderLanes,
--     )
--   end

--   if current ~= nil and !didReceiveUpdate)
--     bailoutHooks(current, workInProgress, renderLanes)
--     return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
--   end

--   -- React DevTools reads this flag.
--   workInProgress.flags |= PerformedWork
--   reconcileChildren(current, workInProgress, nextChildren, renderLanes)
--   return workInProgress.child
-- end

-- ROBLOX FIXME: type refinement
-- local function updateClassComponent(
--   current: Fiber | nil,
--   ...
-- )
local function updateClassComponent(
	current: any,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	renderLanes: Lanes
)
	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if workInProgress.type ~= workInProgress.elementType then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes = Component.propTypes
			local validateProps = Component.validateProps
			if innerPropTypes or validateProps then
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(Component)
				)
			end
		end
	end

	-- Push context providers early to prevent context stack mismatches.
	-- During mounting we don't know the child context yet as the instance doesn't exist.
	-- We will invalidate the child context in finishClassComponent() right after rendering.
	local hasContext
	if isLegacyContextProvider(Component) then
		hasContext = true
		pushLegacyContextProvider(workInProgress)
	else
		hasContext = false
	end
	-- ROBLOX deviation: pass in function to break cyclic require dependency
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)

	local instance = workInProgress.stateNode
	local shouldUpdate
	if instance == nil then
		if current ~= nil then
			-- A class component without an instance only mounts if it suspended
			-- inside a non-concurrent tree, in an inconsistent state. We want to
			-- treat it like a new mount, even though an empty version of it already
			-- committed. Disconnect the alternate pointers.
			current.alternate = nil
			workInProgress.alternate = nil
			-- Since this is conceptually a new fiber, schedule a Placement effect
			workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
		end
		-- In the initial pass we might need to construct the instance.
		constructClassInstance(workInProgress, Component, nextProps)
		mountClassInstance(workInProgress, Component, nextProps, renderLanes)
		shouldUpdate = true
	elseif current == nil then
		-- In a resume, we'll already have an instance we can reuse.
		shouldUpdate =
			resumeMountClassInstance(workInProgress, Component, nextProps, renderLanes)
	else
		shouldUpdate = updateClassInstance(
			current,
			workInProgress,
			Component,
			nextProps,
			renderLanes
		)
	end
	local nextUnitOfWork = finishClassComponent(
		current,
		workInProgress,
		Component,
		shouldUpdate,
		hasContext,
		renderLanes
	)
	if __DEV__ then
		local inst = workInProgress.stateNode
		if shouldUpdate and inst.props ~= nextProps then
			if not exports.didWarnAboutReassigningProps then
				console.error(
[[It looks like %s is reassigning its own `this.props` while rendering. This is not supported and can lead to confusing bugs.]]
,
					getComponentName(workInProgress.type) or "a component"
				)
			end
			exports.didWarnAboutReassigningProps = true
		end
	end
	return nextUnitOfWork
end

function finishClassComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	shouldUpdate: boolean,
	hasContext: boolean,
	renderLanes: Lanes
)
	-- Refs should update even if shouldComponentUpdate returns false
	markRef(current, workInProgress)

	local didCaptureError = bit32.band(workInProgress.flags, DidCapture) ~= NoFlags

	if not shouldUpdate and not didCaptureError then
		-- Context providers should defer to sCU for rendering
		if hasContext then
			invalidateContextProvider(workInProgress, Component, false)
		end

		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end

	local instance = workInProgress.stateNode

	-- Rerender
	ReactCurrentOwner.current = workInProgress
	local nextChildren
	if
		didCaptureError
		and (
			Component.getDerivedStateFromError == nil
			or type(Component.getDerivedStateFromError) ~= "function"
		)
	then
		-- If we captured an error, but getDerivedStateFromError is not defined,
		-- unmount all the children. componentDidCatch will schedule an update to
		-- re-render a fallback. This is temporary until we migrate everyone to
		-- the new API.
		-- TODO: Warn in a future release.
		nextChildren = nil

		if enableProfilerTimer then
			stopProfilerTimerIfRunning(workInProgress)
		end
	else
		if __DEV__ then
			setIsRendering(true)
			-- deviation: Call with ':' instead of '.' so that render can access self
			nextChildren = instance:render()
			if
				debugRenderPhaseSideEffectsForStrictMode
				and bit32.band(workInProgress.mode, StrictMode) ~= 0
			then
				disableLogs()
				-- deviation: Pass instance so that render can access self
				local ok, result = xpcall(instance.render, describeError, instance)
				-- finally
				reenableLogs()
				if not ok then
					error(result)
				end
			end
			setIsRendering(false)
		else
			-- deviation: Call with ':' instead of '.' so that render can access self
			nextChildren = instance:render()
		end
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	if current ~= nil and didCaptureError then
		-- If we're recovering from an error, reconcile without reusing any of
		-- the existing children. Conceptually, the normal children and the children
		-- that are shown on error are two different sets, so we shouldn't reuse
		-- normal children even if their identities match.
		forceUnmountCurrentAndReconcile(
			current :: Fiber,
			workInProgress,
			nextChildren,
			renderLanes
		)
	else
		reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	end

	-- Memoize state using the values we just used to render.
	-- TODO: Restructure so we never read values from the instance.
	workInProgress.memoizedState = instance.state

	-- The context might have changed so we need to recalculate it.
	if hasContext then
		invalidateContextProvider(workInProgress, Component, true)
	end

	return workInProgress.child
end

local function pushHostRootContext(workInProgress)
	-- FIXME (roblox): type refinement '(workInProgress.stateNode: FiberRoot)'
	local root = workInProgress.stateNode
	if root.pendingContext then
		pushTopLevelContextObject(
			workInProgress,
			root.pendingContext,
			root.pendingContext ~= root.context
		)
	elseif root.context then
		-- Should always be set
		pushTopLevelContextObject(workInProgress, root.context, false)
	end
	pushHostContainer(workInProgress, root.containerInfo)
end

local function updateHostRoot(current, workInProgress, renderLanes)
	pushHostRootContext(workInProgress)
	local updateQueue = workInProgress.updateQueue
	invariant(
		current ~= nil and updateQueue ~= nil,
[[If the root does not have an updateQueue, we should have already bailed out. This error is likely caused by a bug in React. Please file an issue.]]	


)
	local nextProps = workInProgress.pendingProps
	local prevState = workInProgress.memoizedState
	local prevChildren
	if prevState ~= nil then
		prevChildren = prevState.element
	end
	cloneUpdateQueue(current, workInProgress)
	processUpdateQueue(workInProgress, nextProps, nil, renderLanes)
	local nextState = workInProgress.memoizedState
	-- Caution: React DevTools currently depends on this property
	-- being called "element".
	local nextChildren = nextState.element
	if nextChildren == prevChildren then
		resetHydrationState()
		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end
	local root: FiberRoot = workInProgress.stateNode
	if root.hydrate and enterHydrationState(workInProgress) then
		-- If we don't have any current children this might be the first pass.
		-- We always try to hydrate. If this isn't a hydration pass there won't
		-- be any children to hydrate which is effectively the same thing as
		-- not hydrating.

		if supportsHydration then
			local mutableSourceEagerHydrationData = root.mutableSourceEagerHydrationData
			if mutableSourceEagerHydrationData ~= nil then
				for i = 1, #mutableSourceEagerHydrationData, 2 do
					-- FIXME (roblox): type refinement
					-- local mutableSource = ((mutableSourceEagerHydrationData[
					--   i
					-- ]: any): MutableSource<any>)
					local mutableSource = mutableSourceEagerHydrationData[i]
					local version = mutableSourceEagerHydrationData[i + 1]
					setWorkInProgressVersion(mutableSource, version)
				end
			end
		end

		local child = mountChildFibers(workInProgress, nil, nextChildren, renderLanes)
		workInProgress.child = child

		local node = child
		while node do
			-- Mark each child as hydrating. This is a fast path to know whether this
			-- tree is part of a hydrating tree. This is used to determine if a child
			-- node has fully mounted yet, and for scheduling event replaying.
			-- Conceptually this is similar to Placement in that a new subtree is
			-- inserted into the React tree here. It just happens to not need DOM
			-- mutations because it already exists.
			node.flags =
				bit32.bor(bit32.band(node.flags, bit32.bnot(Placement)), Hydrating)
			node = node.sibling
		end
	else
		-- Otherwise reset hydration state in case we aborted and resumed another
		-- root.
		reconcileChildren(current, workInProgress, nextChildren, renderLanes)
		resetHydrationState()
	end
	return workInProgress.child
end

-- FIXME (roblox): type refinement
-- local function updateHostComponent(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   renderLanes: Lanes
-- )
local function updateHostComponent(
	current: any,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	pushHostContext(workInProgress)

	if current == nil then
		tryToClaimNextHydratableInstance(workInProgress)
	end

	local type_ = workInProgress.type
	local nextProps = workInProgress.pendingProps
	local prevProps
	if current ~= nil then
		prevProps = current.memoizedProps
	end

	local nextChildren = nextProps.children
	local isDirectTextChild = shouldSetTextContent(type_, nextProps)

	if isDirectTextChild then
		-- We special case a direct text child of a host node. This is a common
		-- case. We won't handle it as a reified child. We will instead handle
		-- this in the host environment that also has access to this prop. That
		-- avoids allocating another HostText fiber and traversing it.
		nextChildren = nil
	elseif prevProps ~= nil and shouldSetTextContent(type_, prevProps) then
		-- If we're switching from a direct text child to a normal child, or to
		-- empty, we need to schedule the text content to be reset.
		workInProgress.flags = bit32.bor(workInProgress.flags, ContentReset)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)

	markRef(current, workInProgress)
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

local function updateHostText(current, workInProgress)
	if current == nil then
		tryToClaimNextHydratableInstance(workInProgress)
	end
	-- Nothing to do here. This is terminal. We'll do the completion step
	-- immediately after.
	return nil
end

local function mountLazyComponent(
	_current,
	workInProgress,
	elementType,
	updateLanes,
	renderLanes
)
	if _current ~= nil then
		-- A lazy component only mounts if it suspended inside a non-
		-- concurrent tree, in an inconsistent state. We want to treat it like
		-- a new mount, even though an empty version of it already committed.
		-- Disconnect the alternate pointers.
		_current.alternate = nil
		workInProgress.alternate = nil
		-- Since this is conceptually a new fiber, schedule a Placement effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
	end

	local props = workInProgress.pendingProps
	local lazyComponent: LazyComponentType<any, any> = elementType
	local payload = lazyComponent._payload
	local init = lazyComponent._init
	local Component = init(payload)
	-- Store the unwrapped component in the type.
	workInProgress.type = Component
	workInProgress.tag = resolveLazyComponentTag(Component)
	local resolvedTag = workInProgress.tag
	local resolvedProps = resolveDefaultProps(Component, props)
	local child
	if resolvedTag == FunctionComponent then
		if __DEV__ then
			validateFunctionComponentInDev(workInProgress, Component)
			Component = resolveFunctionForHotReloading(Component)
			workInProgress.type = Component
		end
		child = updateFunctionComponent(
			nil,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
		return child
	elseif resolvedTag == ClassComponent then
		if __DEV__ then
			Component = resolveClassForHotReloading(Component)
			workInProgress.type = Component
		end
		child = updateClassComponent(
			nil,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
		return child
	elseif resolvedTag == ForwardRef then
		if __DEV__ then
			Component = resolveForwardRefForHotReloading(Component)
			workInProgress.type = Component
		end
		child =
			updateForwardRef(nil, workInProgress, Component, resolvedProps, renderLanes)
		return child
	elseif resolvedTag == MemoComponent then
		if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
			if workInProgress.type ~= workInProgress.elementType then
				-- ROBLOX deviation: adds support for legacy Roact's validateProps()
				local outerPropTypes = Component.propTypes
				local validateProps = Component.validateProps
				if outerPropTypes or validateProps then
					checkPropTypes(
						outerPropTypes,
						validateProps,
						resolvedProps, -- Resolved for outer only
						"prop",
						getComponentName(Component)
					)
				end
			end
		end
		child = updateMemoComponent(
			nil,
			workInProgress,
			Component,
			resolveDefaultProps(Component.type, resolvedProps), -- The inner type can have defaults too
			updateLanes,
			renderLanes
		)
		return child
		-- elseif resolvedTag == Block then
		--   unimplemented("Blocks API")
		--   if enableBlocksAPI then
		--     -- TODO: Resolve for Hot Reloading.
		--     child = updateBlock(
		--       nil,
		--       workInProgress,
		--       Component,
		--       props,
		--       renderLanes,
		--     )
		--     return child
		--   end
		--   -- ROBLOX deviation: break
	end
	local hint = ""
	if __DEV__ then
		if
			Component ~= nil
			and type(Component) == "table"
			and Component["$$typeof"] == REACT_LAZY_TYPE
		then
			hint = " Did you wrap a component in React.lazy() more than once?"
		elseif type(Component) == "table" and Component["$$typeof"] == nil then
			hint = "\n" .. inspect(Component)
		end
	end
	-- This message intentionally doesn't mention ForwardRef or MemoComponent
	-- because the fact that it's a separate type of work is an
	-- implementation detail.
	invariant(
		false,
[[Element type is invalid. Received a promise that resolves to: %s. Lazy element type must resolve to a class or function.%s]]
,
		tostring(Component),
		hint
	)
	-- ROBLOX deviation: add nil to satisfy Luau, which doesn't doesn't bubble up the unconditional error() inside invariant
	return nil
end

function mountIncompleteClassComponent(
	_current,
	workInProgress,
	Component,
	nextProps,
	renderLanes
)
	if _current ~= nil then
		-- An incomplete component only mounts if it suspended inside a non-
		-- concurrent tree, in an inconsistent state. We want to treat it like
		-- a new mount, even though an empty version of it already committed.
		-- Disconnect the alternate pointers.
		_current.alternate = nil
		workInProgress.alternate = nil
		-- Since this is conceptually a new fiber, schedule a Placement effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
	end

	-- Promote the fiber to a class and try rendering again.
	workInProgress.tag = ClassComponent

	-- The rest of this function is a fork of `updateClassComponent`

	-- Push context providers early to prevent context stack mismatches.
	-- During mounting we don't know the child context yet as the instance doesn't exist.
	-- We will invalidate the child context in finishClassComponent() right after rendering.
	local hasContext
	if isLegacyContextProvider(Component) then
		hasContext = true
		pushLegacyContextProvider(workInProgress)
	else
		hasContext = false
	end
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)

	constructClassInstance(workInProgress, Component, nextProps)
	mountClassInstance(workInProgress, Component, nextProps, renderLanes)

	return finishClassComponent(
		nil,
		workInProgress,
		Component,
		true,
		hasContext,
		renderLanes
	)
end

local function mountIndeterminateComponent(
	current,
	workInProgress,
	Component,
	renderLanes
)
	if current ~= nil then
		-- An indeterminate component only mounts if it suspended inside a non-
		-- concurrent tree, in an inconsistent state. We want to treat it like
		-- a new mount, even though an empty version of it already committed.
		-- Disconnect the alternate pointers.
		current.alternate = nil
		workInProgress.alternate = nil
		-- Since this is conceptually a new fiber, schedule a Placement effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
	end

	local props = workInProgress.pendingProps
	local context
	if not disableLegacyContext then
		local unmaskedContext = getUnmaskedContext(workInProgress, Component, false)
		context = getMaskedContext(workInProgress, unmaskedContext)
	end

	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	local value

	if __DEV__ then
		if
			-- deviation: Instead of checking for the prototype, see if Component is a
			-- table with a render function
			type(Component) == "table" and type(Component.render) == "function"
		then
			local componentName = getComponentName(Component) or "Unknown"

			if not DidWarn.didWarnAboutBadClass[componentName] then
				console.error(
[[The <%s /> component appears to have a render method, but doesn't extend React.Component. This is likely to cause errors. Change %s to extend React.Component instead.]]
,
					componentName,
					componentName
				)
				DidWarn.didWarnAboutBadClass[componentName] = true
			end
		end

		if bit32.band(workInProgress.mode, StrictMode) ~= 0 then
			ReactStrictModeWarnings.recordLegacyContextWarning(workInProgress)
		end

		setIsRendering(true)
		ReactCurrentOwner.current = workInProgress
		value =
			renderWithHooks(nil, workInProgress, Component, props, context, renderLanes)
		setIsRendering(false)
	else
		value =
			renderWithHooks(nil, workInProgress, Component, props, context, renderLanes)
	end
	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	-- ROBLOX deviation START: cache type(value)
	local typeofValue = type(value)
	-- ROBLOX deviation END

	if __DEV__ then
		-- Support for module components is deprecated and is removed behind a flag.
		-- Whether or not it would crash later, we want to show a good message in DEV first.
		if
			value ~= nil
			and typeofValue == "table"
			and type(value.render) == "function"
			and value["$$typeof"] == nil
		then
			local componentName = getComponentName(Component) or "Unknown"
			if not DidWarn.didWarnAboutModulePatternComponent[componentName] then
				console.error(
[[The <%s /> component appears to be a function component that returns a class instance. Change %s to a class that extends React.Component instead. ]]
,
					-- ROBLOX deviation: Don't print JS-specific remediation advice
					-- "If you can't use a class try assigning the prototype on the function as a workaround. " ..
					-- "`%s.prototype = React.Component.prototype`. Don't use an arrow function since it " ..
					-- "cannot be called with `new` by React.",
					componentName,
					componentName
					-- componentName
				)
				DidWarn.didWarnAboutModulePatternComponent[componentName] = true
			end
		end
	end

	if
		-- Run these checks in production only if the flag is off.
		-- Eventually we'll delete this branch altogether.
		not disableModulePatternComponents
		and value ~= nil
		and typeofValue == "table"
		and type(value.render) == "function"
		and value["$$typeof"] == nil
	then
		if __DEV__ then
			local componentName = getComponentName(Component) or "Unknown"
			if not DidWarn.didWarnAboutModulePatternComponent[componentName] then
				console.error(
					"The <%s /> component appears to be a function component that returns a class instance. "
						.. "Change %s to a class that extends React.Component instead. "
						-- ROBLOX deviation: Don't print JS-specific remediation advice
						-- "If you can't use a class try assigning the prototype on the function as a workaround. " ..
						-- "`%s.prototype = React.Component.prototype`. Don't use an arrow function since it " ..
						-- "cannot be called with `new` by React.",
						.. componentName,
					componentName
					-- componentName
				)
				DidWarn.didWarnAboutModulePatternComponent[componentName] = true
			end
		end

		-- Proceed under the assumption that this is a class instance
		workInProgress.tag = ClassComponent

		-- Throw out any hooks that were used.
		workInProgress.memoizedState = nil
		workInProgress.updateQueue = nil

		-- Push context providers early to prevent context stack mismatches.
		-- During mounting we don't know the child context yet as the instance doesn't exist.
		-- We will invalidate the child context in finishClassComponent() right after rendering.
		local hasContext = false
		if isLegacyContextProvider(Component) then
			hasContext = true
			pushLegacyContextProvider(workInProgress)
		else
			hasContext = false
		end

		-- deviation: Lua doesn't need to coerce `T | null | undefined` to `T | null`
		workInProgress.memoizedState = value.state

		initializeUpdateQueue(workInProgress)

		-- ROBLOX deviation: don't access field on function
		local getDerivedStateFromProps
		if type(Component) ~= "function" then
			getDerivedStateFromProps = (Component :: React_Component<any, any>).getDerivedStateFromProps
		end
		if
			getDerivedStateFromProps ~= nil
			and type(getDerivedStateFromProps) == "function"
		then
			applyDerivedStateFromProps(
				workInProgress,
				Component,
				getDerivedStateFromProps,
				props
			)
		end

		adoptClassInstance(workInProgress, value)
		mountClassInstance(workInProgress, Component, props, renderLanes)
		return finishClassComponent(
			nil,
			workInProgress,
			Component,
			true,
			hasContext,
			renderLanes
		)
	else
		-- Proceed under the assumption that this is a function component
		workInProgress.tag = FunctionComponent
		if __DEV__ then
			if disableLegacyContext and Component.contextTypes then
				console.error(
[[%s uses the legacy contextTypes API which is no longer supported. Use React.createContext() with React.useContext() instead.]]
,
					getComponentName(Component) or "Unknown"
				)
			end

			if
				debugRenderPhaseSideEffectsForStrictMode
				and bit32.band(workInProgress.mode, StrictMode) ~= 0
			then
				disableLogs()
				local ok, result = xpcall(
					renderWithHooks,
					describeError,
					nil,
					workInProgress,
					Component,
					props,
					context,
					renderLanes
				)
				-- finally
				reenableLogs()
				if ok then
					value = result
				else
					error(result)
				end
			end
		end
		reconcileChildren(nil, workInProgress, value, renderLanes)
		if __DEV__ then
			validateFunctionComponentInDev(workInProgress, Component)
		end
		return workInProgress.child
	end
end

function validateFunctionComponentInDev(workInProgress: Fiber, Component: any)
	if __DEV__ then
		-- ROBLOX deviation: Lua doesn't allow fields on functions, so this never happens
		-- if Component then
		--   if Component.childContextTypes then
		--     console.error(
		--       '%s(...): childContextTypes cannot be defined on a function component.',
		--       Component.displayName or Component.name or 'Component'
		--     )
		--   end
		-- end
		if workInProgress.ref ~= nil then
			local info = ""
			local ownerName = getCurrentFiberOwnerNameInDevOrNull()
			if ownerName then
				info ..= "\n\nCheck the render method of `" .. ownerName .. "`."
			end

			local warningKey = ownerName or workInProgress._debugID or ""
			local debugSource = workInProgress._debugSource
			if debugSource then
				warningKey = debugSource.fileName .. ":" .. debugSource.lineNumber
			end
			if not DidWarn.didWarnAboutFunctionRefs[warningKey] then
				DidWarn.didWarnAboutFunctionRefs[warningKey] = true
				console.error(
[[Function components cannot be given refs. Attempts to access this ref will fail. Did you mean to use React.forwardRef()?%s]]

,
					info
				)
			end
		end

		if
			warnAboutDefaultPropsOnFunctionComponents
			-- ROBLOX deviation: functions can't have fields in Lua
			and type(Component) ~= "function"
			and Component.defaultProps ~= nil
		then
			local componentName = getComponentName(Component) or "Unknown"

			if not DidWarn.didWarnAboutDefaultPropsOnFunctionComponent[componentName] then
				console.error(
[[%s: Support for defaultProps will be removed from function components in a future major release.]]

, -- Use JavaScript default parameters instead.',
					componentName
				)
				DidWarn.didWarnAboutDefaultPropsOnFunctionComponent[componentName] = true
			end
		end

		-- ROBLOX deviation: Lua functions can't have fields
		if
			type(Component) ~= "function"
			and Component.getDerivedStateFromProps ~= nil
			and type(Component.getDerivedStateFromProps) == "function"
		then
			local componentName = getComponentName(Component) or "Unknown"

			if
				not DidWarn.didWarnAboutGetDerivedStateOnFunctionComponent[componentName]
			then
				console.error(
					"%s: Function components do not support getDerivedStateFromProps.",
					componentName
				)
				DidWarn.didWarnAboutGetDerivedStateOnFunctionComponent[componentName] =
					true
			end
		end

		-- ROBLOX deviation: Lua functions can't have fields
		if
			type(Component) ~= "function"
			and Component.contextType ~= nil
			and type(Component.contextType) == "table"
		then
			local componentName = getComponentName(Component) or "Unknown"

			if not DidWarn.didWarnAboutContextTypeOnFunctionComponent[componentName] then
				console.error(
					"%s: Function components do not support contextType.",
					componentName
				)
				DidWarn.didWarnAboutContextTypeOnFunctionComponent[componentName] = true
			end
		end
	end
end

local SUSPENDED_MARKER: SuspenseState = {
	dehydrated = nil,
	retryLane = ReactFiberLane.NoLane,
}

local function mountSuspenseOffscreenState(renderLanes: Lanes): OffscreenState
	return {
		baseLanes = renderLanes,
	}
end

local function updateSuspenseOffscreenState(
	prevOffscreenState: OffscreenState,
	renderLanes: Lanes
): OffscreenState
	return {
		baseLanes = ReactFiberLane.mergeLanes(prevOffscreenState.baseLanes, renderLanes),
	}
end

-- TODO: Probably should inline this back
local function shouldRemainOnFallback(
	suspenseContext: SuspenseContext,
	current: nil | Fiber,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	-- If we're already showing a fallback, there are cases where we need to
	-- remain on that fallback regardless of whether the content has resolved.
	-- For example, SuspenseList coordinates when nested content appears.
	if current ~= nil then
		local suspenseState: SuspenseState = (current :: Fiber).memoizedState
		if suspenseState == nil then
			-- Currently showing content. Don't hide it, even if ForceSuspenseFallack
			-- is true. More precise name might be "ForceRemainSuspenseFallback".
			-- Note: This is a factoring smell. Can't remain on a fallback if there's
			-- no fallback to remain on.
			return false
		end
	end

	-- Not currently showing content. Consult the Suspense context.
	return hasSuspenseContext(suspenseContext, ForceSuspenseFallback)
end

local function getRemainingWorkInPrimaryTree(current: Fiber, renderLanes)
	-- TODO: Should not remove render lanes that were pinged during this render
	return ReactFiberLane.removeLanes(current.childLanes, renderLanes)
end

-- ROBLOX deviation: predeclare these methods to resolve method declaration ordering
local updateSuspensePrimaryChildren
local mountDehydratedSuspenseComponent
local mountSuspensePrimaryChildren
local updateSuspenseFallbackChildren
local updateDehydratedSuspenseComponent

local function updateSuspenseComponent(current, workInProgress, renderLanes)
	local nextProps = workInProgress.pendingProps

	-- This is used by DevTools to force a boundary to suspend.
	if __DEV__ then
		if shouldSuspend(workInProgress) then
			workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
		end
	end

	local suspenseContext: SuspenseContext = suspenseStackCursor.current

	local showFallback = false
	local didSuspend = bit32.band(workInProgress.flags, DidCapture) ~= NoFlags

	if
		didSuspend
		or shouldRemainOnFallback(suspenseContext, current, workInProgress, renderLanes)
	then
		-- Something in this boundary's subtree already suspended. Switch to
		-- rendering the fallback children.
		showFallback = true
		workInProgress.flags = bit32.band(workInProgress.flags, bit32.bnot(DidCapture))
	else
		-- Attempting the main content
		if current == nil or current.memoizedState ~= nil then
			-- This is a new mount or this boundary is already showing a fallback state.
			-- Mark this subtree context as having at least one invisible parent that could
			-- handle the fallback state.
			-- Boundaries without fallbacks or should be avoided are not considered since
			-- they cannot handle preferred fallback states.
			if
				nextProps.fallback ~= nil
				and nextProps.unstable_avoidThisFallback ~= true
			then
				suspenseContext = addSubtreeSuspenseContext(
					suspenseContext,
					InvisibleParentSuspenseContext
				)
			end
		end
	end

	suspenseContext = setDefaultShallowSuspenseContext(suspenseContext)

	pushSuspenseContext(workInProgress, suspenseContext)

	-- OK, the next part is confusing. We're about to reconcile the Suspense
	-- boundary's children. This involves some custom reconcilation logic. Two
	-- main reasons this is so complicated.
	--
	-- First, Legacy Mode has different semantics for backwards compatibility. The
	-- primary tree will commit in an inconsistent state, so when we do the
	-- second pass to render the fallback, we do some exceedingly, uh, clever
	-- hacks to make that not totally break. Like transferring effects and
	-- deletions from hidden tree. In Concurrent Mode, it's much simpler,
	-- because we bailout on the primary tree completely and leave it in its old
	-- state, no effects. Same as what we do for Offscreen (except that
	-- Offscreen doesn't have the first render pass).
	--
	-- Second is hydration. During hydration, the Suspense fiber has a slightly
	-- different layout, where the child points to a dehydrated fragment, which
	-- contains the DOM rendered by the server.
	--
	-- Third, even if you set all that aside, Suspense is like error boundaries in
	-- that we first we try to render one tree, and if that fails, we render again
	-- and switch to a different tree. Like a try/catch block. So we have to track
	-- which branch we're currently rendering. Ideally we would model this using
	-- a stack.
	if current == nil then
		-- Initial mount
		-- If we're currently hydrating, try to hydrate this boundary.
		-- But only if this has a fallback.
		if nextProps.fallback ~= nil then
			tryToClaimNextHydratableInstance(workInProgress)
			-- This could've been a dehydrated suspense component.
			if enableSuspenseServerRenderer then
				local suspenseState: nil | SuspenseState = workInProgress.memoizedState
				if suspenseState ~= nil then
					local dehydrated = (suspenseState :: SuspenseState).dehydrated
					if dehydrated ~= nil then
						return mountDehydratedSuspenseComponent(
							workInProgress,
							dehydrated,
							renderLanes
						)
					end
				end
			end
		end

		local nextPrimaryChildren = nextProps.children
		local nextFallbackChildren = nextProps.fallback
		if showFallback then
			local fallbackFragment = mountSuspenseFallbackChildren(
				workInProgress,
				nextPrimaryChildren,
				nextFallbackChildren,
				renderLanes
			)
			local primaryChildFragment: Fiber = workInProgress.child :: any
			primaryChildFragment.memoizedState = mountSuspenseOffscreenState(renderLanes)
			workInProgress.memoizedState = SUSPENDED_MARKER
			return fallbackFragment
		elseif
			nextProps.unstable_expectedLoadTime ~= nil
			and type(nextProps.unstable_expectedLoadTime) == "number"
		then
			-- This is a CPU-bound tree. Skip this tree and show a placeholder to
			-- unblock the surrounding content. Then immediately retry after the
			-- initial commit.
			local fallbackFragment = mountSuspenseFallbackChildren(
				workInProgress,
				nextPrimaryChildren,
				nextFallbackChildren,
				renderLanes
			)
			local primaryChildFragment: Fiber = workInProgress.child :: any
			primaryChildFragment.memoizedState = mountSuspenseOffscreenState(renderLanes)
			workInProgress.memoizedState = SUSPENDED_MARKER

			-- Since nothing actually suspended, there will nothing to ping this to
			-- get it started back up to attempt the next item. While in terms of
			-- priority this work has the same priority as this current render, it's
			-- not part of the same transition once the transition has committed. If
			-- it's sync, we still want to yield so that it can be painted.
			-- Conceptually, this is really the same as pinging. We can use any
			-- RetryLane even if it's the one currently rendering since we're leaving
			-- it behind on this node.
			workInProgress.lanes = ReactFiberLane.SomeRetryLane
			if enableSchedulerTracing then
				markSpawnedWork(ReactFiberLane.SomeRetryLane)
			end
			return fallbackFragment
		else
			return mountSuspensePrimaryChildren(
				workInProgress,
				nextPrimaryChildren,
				renderLanes
			)
		end
	else
		-- This is an update.

		-- If the current fiber has a SuspenseState, that means it's already showing
		-- a fallback.
		local prevState: nil | SuspenseState = current.memoizedState
		if prevState ~= nil then
			-- The current tree is already showing a fallback

			-- Special path for hydration
			if enableSuspenseServerRenderer then
				-- ROBLOX FIXME: remove :: when Luau understands ~= nil
				local dehydrated = (prevState :: SuspenseState).dehydrated

				if dehydrated ~= nil then
					if not didSuspend then
						return updateDehydratedSuspenseComponent(
							current,
							workInProgress,
							dehydrated,
							prevState,
							renderLanes
						)
					elseif workInProgress.memoizedState ~= nil then
						-- Something suspended and we should still be in dehydrated mode.
						-- Leave the existing child in place.
						workInProgress.child = current.child
						-- The dehydrated completion pass expects this flag to be there
						-- but the normal suspense pass doesn't.
						workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
						return nil
					else
						-- Suspended but we should no longer be in dehydrated mode.
						-- Therefore we now have to render the fallback.
						local nextPrimaryChildren = nextProps.children
						local nextFallbackChildren = nextProps.fallback
						local fallbackChildFragment =
							mountSuspenseFallbackAfterRetryWithoutHydrating(
								current,
								workInProgress,
								nextPrimaryChildren,
								nextFallbackChildren,
								renderLanes
							)
						local primaryChildFragment: Fiber = workInProgress.child :: any
						primaryChildFragment.memoizedState =
							mountSuspenseOffscreenState(renderLanes)
						workInProgress.memoizedState = SUSPENDED_MARKER
						return fallbackChildFragment
					end
				end
			end

			if showFallback then
				local nextFallbackChildren = nextProps.fallback
				local nextPrimaryChildren = nextProps.children
				local fallbackChildFragment = updateSuspenseFallbackChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					nextFallbackChildren,
					renderLanes
				)
				local primaryChildFragment: Fiber = workInProgress.child :: any
				local prevOffscreenState: OffscreenState | nil = (current.child :: any).memoizedState

				-- ROBLOX deviation: if/else in place of ternary
				if prevOffscreenState == nil then
					primaryChildFragment.memoizedState =
						mountSuspenseOffscreenState(renderLanes)
				else
					-- ROBLOX FIXME: remove :: when Luau understands ~= nil
					primaryChildFragment.memoizedState = updateSuspenseOffscreenState(
						prevOffscreenState :: OffscreenState,
						renderLanes
					)
				end

				primaryChildFragment.childLanes =
					getRemainingWorkInPrimaryTree(current, renderLanes)
				workInProgress.memoizedState = SUSPENDED_MARKER
				return fallbackChildFragment
			else
				local nextPrimaryChildren = nextProps.children
				local primaryChildFragment = updateSuspensePrimaryChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					renderLanes
				)
				workInProgress.memoizedState = nil
				return primaryChildFragment
			end
		else
			-- The current tree is not already showing a fallback.
			if showFallback then
				-- Timed out.
				local nextFallbackChildren = nextProps.fallback
				local nextPrimaryChildren = nextProps.children
				local fallbackChildFragment = updateSuspenseFallbackChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					nextFallbackChildren,
					renderLanes
				)
				local primaryChildFragment: Fiber = workInProgress.child :: any
				local prevOffscreenState: OffscreenState | nil = (current.child :: any).memoizedState

				-- ROBLOX deviation: if/else in place of ternary
				if prevOffscreenState == nil then
					primaryChildFragment.memoizedState =
						mountSuspenseOffscreenState(renderLanes)
				else
					-- ROBLOX FIXME: remove :: once Luau understands nil check
					primaryChildFragment.memoizedState = updateSuspenseOffscreenState(
						prevOffscreenState :: OffscreenState,
						renderLanes
					)
				end

				primaryChildFragment.childLanes =
					getRemainingWorkInPrimaryTree(current, renderLanes)
				-- Skip the primary children, and continue working on the
				-- fallback children.
				workInProgress.memoizedState = SUSPENDED_MARKER
				return fallbackChildFragment
			else
				-- Still haven't timed out. Continue rendering the children, like we
				-- normally do.
				local nextPrimaryChildren = nextProps.children
				local primaryChildFragment = updateSuspensePrimaryChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					renderLanes
				)
				workInProgress.memoizedState = nil
				return primaryChildFragment
			end
		end
	end
end

function mountSuspensePrimaryChildren(workInProgress, primaryChildren, renderLanes)
	local mode = workInProgress.mode
	local primaryChildProps: OffscreenProps = {
		mode = "visible",
		children = primaryChildren,
	}
	local primaryChildFragment =
		createFiberFromOffscreen(primaryChildProps, mode, renderLanes, nil)
	primaryChildFragment.return_ = workInProgress
	workInProgress.child = primaryChildFragment
	return primaryChildFragment
end

function mountSuspenseFallbackChildren(
	workInProgress,
	primaryChildren,
	fallbackChildren,
	renderLanes
)
	local mode = workInProgress.mode
	local progressedPrimaryFragment: Fiber | nil = workInProgress.child

	local primaryChildProps: OffscreenProps = {
		mode = "hidden",
		children = primaryChildren,
	}

	local primaryChildFragment
	local fallbackChildFragment
	if bit32.band(mode, BlockingMode) == NoMode and progressedPrimaryFragment ~= nil then
		-- In legacy mode, we commit the primary tree as if it successfully
		-- completed, even though it's in an inconsistent state.
		primaryChildFragment = progressedPrimaryFragment
		primaryChildFragment.childLanes = ReactFiberLane.NoLanes
		primaryChildFragment.pendingProps = primaryChildProps

		if enableProfilerTimer and bit32.band(workInProgress.mode, ProfileMode) ~= 0 then
			-- Reset the durations from the first pass so they aren't included in the
			-- final amounts. This seems counterintuitive, since we're intentionally
			-- not measuring part of the render phase, but this makes it match what we
			-- do in Concurrent Mode.
			primaryChildFragment.actualDuration = 0
			primaryChildFragment.actualStartTime = -1			
primaryChildFragment.selfBaseDuration = 0
			primaryChildFragment.treeBaseDuration = 0
		end

		fallbackChildFragment =
			createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
	else
		primaryChildFragment =
			createFiberFromOffscreen(primaryChildProps, mode, ReactFiberLane.NoLanes, nil)
		fallbackChildFragment =
			createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
	end

	primaryChildFragment.return_ = workInProgress
	fallbackChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = fallbackChildFragment
	workInProgress.child = primaryChildFragment
	return fallbackChildFragment
end

local function createWorkInProgressOffscreenFiber(
	current: Fiber,
	offscreenProps: OffscreenProps
)
	-- The props argument to `createWorkInProgress` is `any` typed, so we use this
	-- wrapper function to constrain it.
	return createWorkInProgress(current, offscreenProps)
end

function updateSuspensePrimaryChildren(
	current,
	workInProgress,
	primaryChildren,
	renderLanes
)
	local currentPrimaryChildFragment: Fiber = current.child :: any
	local currentFallbackChildFragment: Fiber | nil = currentPrimaryChildFragment.sibling

	local primaryChildFragment =
		createWorkInProgressOffscreenFiber(currentPrimaryChildFragment, {
			mode = "visible",
			children = primaryChildren,
		})
	if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
		primaryChildFragment.lanes = renderLanes
	end
	primaryChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = nil
	if currentFallbackChildFragment ~= nil then
		-- Delete the fallback child fragment
		local deletions = workInProgress.deletions
		if deletions == nil then
			workInProgress.deletions = { currentFallbackChildFragment }
			-- TODO (effects) Rename this to better reflect its new usage (e.g. ChildDeletions)
			workInProgress.flags = bit32.bor(workInProgress.flags, Deletion)
		else
			table.insert(deletions, currentFallbackChildFragment)
		end
	end

	workInProgress.child = primaryChildFragment
	return primaryChildFragment
end

function updateSuspenseFallbackChildren(
	current,
	workInProgress,
	primaryChildren,
	fallbackChildren,
	renderLanes
)
	local mode = workInProgress.mode
	local currentPrimaryChildFragment: Fiber = current.child :: any
	local currentFallbackChildFragment: Fiber | nil = currentPrimaryChildFragment.sibling

	local primaryChildProps: OffscreenProps = {
		mode = "hidden",
		children = primaryChildren,
	}

	local primaryChildFragment
	if
		-- In legacy mode, we commit the primary tree as if it successfully
		-- completed, even though it's in an inconsistent state.
		bit32.band(mode, BlockingMode) == NoMode
		-- Make sure we're on the second pass, i.e. the primary child fragment was
		-- already cloned. In legacy mode, the only case where this isn't true is
		-- when DevTools forces us to display a fallback; we skip the first render
		-- pass entirely and go straight to rendering the fallback. (In Concurrent
		-- Mode, SuspenseList can also trigger this scenario, but this is a legacy-
		-- only codepath.)
		and workInProgress.child ~= currentPrimaryChildFragment
	then
		local progressedPrimaryFragment: Fiber = workInProgress.child
		primaryChildFragment = progressedPrimaryFragment
		primaryChildFragment.childLanes = ReactFiberLane.NoLanes
		primaryChildFragment.pendingProps = primaryChildProps

		if enableProfilerTimer and bit32.band(workInProgress.mode, ProfileMode) ~= 0 then
			-- Reset the durations from the first pass so they aren't included in the
			-- final amounts. This seems counterintuitive, since we're intentionally
			-- not measuring part of the render phase, but this makes it match what we
			-- do in Concurrent Mode.
			primaryChildFragment.actualDuration = 0
			primaryChildFragment.actualStartTime = -1			
primaryChildFragment.selfBaseDuration =
				currentPrimaryChildFragment.selfBaseDuration
			primaryChildFragment.treeBaseDuration =
				currentPrimaryChildFragment.treeBaseDuration
		end

		-- The fallback fiber was added as a deletion effect during the first pass.
		-- However, since we're going to remain on the fallback, we no longer want
		-- to delete it.
		workInProgress.deletions = nil
	else
		primaryChildFragment = createWorkInProgressOffscreenFiber(
			currentPrimaryChildFragment,
			primaryChildProps
		)

		-- Since we're reusing a current tree, we need to reuse the flags, too.
		-- (We don't do this in legacy mode, because in legacy mode we don't re-use
		-- the current tree; see previous branch.)
		primaryChildFragment.subtreeFlags =
			bit32.band(currentPrimaryChildFragment.subtreeFlags, StaticMask)
	end
	local fallbackChildFragment
	if currentFallbackChildFragment ~= nil then
		fallbackChildFragment =
			createWorkInProgress(currentFallbackChildFragment, fallbackChildren)
	else
		fallbackChildFragment =
			createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
		-- Needs a placement effect because the parent (the Suspense boundary) already
		-- mounted but this is a new fiber.
		fallbackChildFragment.flags = bit32.bor(fallbackChildFragment.flags, Placement)
	end

	fallbackChildFragment.return_ = workInProgress
	primaryChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = fallbackChildFragment
	workInProgress.child = primaryChildFragment

	return fallbackChildFragment
end

local function retrySuspenseComponentWithoutHydrating(
	current: Fiber,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	-- This will add the old fiber to the deletion list
	reconcileChildFibers(workInProgress, current.child, nil, renderLanes)

	-- We're now not suspended nor dehydrated.
	local nextProps = workInProgress.pendingProps
	local primaryChildren = nextProps.children
	local primaryChildFragment =
		mountSuspensePrimaryChildren(workInProgress, primaryChildren, renderLanes)
	-- Needs a placement effect because the parent (the Suspense boundary) already
	-- mounted but this is a new fiber.
	primaryChildFragment.flags = bit32.bor(primaryChildFragment.flags, Placement)
	workInProgress.memoizedState = nil

	return primaryChildFragment
end

function mountSuspenseFallbackAfterRetryWithoutHydrating(
	current,
	workInProgress,
	primaryChildren,
	fallbackChildren,
	renderLanes
)
	local mode = workInProgress.mode
	local primaryChildFragment =
		createFiberFromOffscreen(primaryChildren, mode, ReactFiberLane.NoLanes, nil)
	local fallbackChildFragment =
		createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
	-- Needs a placement effect because the parent (the Suspense
	-- boundary) already mounted but this is a new fiber.
	fallbackChildFragment.flags = bit32.bor(fallbackChildFragment.flags, Placement)

	primaryChildFragment.return_ = workInProgress
	fallbackChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = fallbackChildFragment
	workInProgress.child = primaryChildFragment

	if bit32.band(workInProgress.mode, BlockingMode) ~= NoMode then
		-- We will have dropped the effect list which contains the
		-- deletion. We need to reconcile to delete the current child.
		reconcileChildFibers(workInProgress, current.child, nil, renderLanes)
	end

	return fallbackChildFragment
end

function mountDehydratedSuspenseComponent(
	workInProgress: Fiber,
	suspenseInstance: SuspenseInstance,
	renderLanes: Lanes
): nil | Fiber
	-- During the first pass, we'll bail out and not drill into the children.
	-- Instead, we'll leave the content in place and try to hydrate it later.
	if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
		if __DEV__ then
			console.error(
[[Cannot hydrate Suspense in legacy mode. Switch fromReactDOM.hydrate(element, container) to ReactDOM.createBlockingRoot(container, { hydrate: true }).render(element) or remove the Suspense componentsthe server rendered components.]]			




)
		end
		workInProgress.lanes = ReactFiberLane.laneToLanes(ReactFiberLane.SyncLane)
	elseif isSuspenseInstanceFallback(suspenseInstance) then
		-- This is a client-only boundary. Since we won't get any content from the server
		-- for this, we need to schedule that at a higher priority based on when it would
		-- have timed out. In theory we could render it in this pass but it would have the
		-- wrong priority associated with it and will prevent hydration of parent path.
		-- Instead, we'll leave work left on it to render it in a separate commit.

		-- TODO This time should be the time at which the server rendered response that is
		-- a parent to this boundary was displayed. However, since we currently don't have
		-- a protocol to transfer that time, we'll just estimate it by using the current
		-- time. This will mean that Suspense timeouts are slightly shifted to later than
		-- they should be.
		-- Schedule a normal pri update to render this content.
		if enableSchedulerTracing then
			markSpawnedWork(ReactFiberLane.DefaultHydrationLane)
		end
		workInProgress.lanes =
			ReactFiberLane.laneToLanes(ReactFiberLane.DefaultHydrationLane)
	else
		-- We'll continue hydrating the rest at offscreen priority since we'll already
		-- be showing the right content coming from the server, it is no rush.
		workInProgress.lanes = ReactFiberLane.laneToLanes(ReactFiberLane.OffscreenLane)
		if enableSchedulerTracing then
			markSpawnedWork(ReactFiberLane.OffscreenLane)
		end
	end
	return nil
end

function updateDehydratedSuspenseComponent(
	current: Fiber,
	workInProgress: Fiber,
	suspenseInstance: SuspenseInstance,
	suspenseState: SuspenseState,
	renderLanes: Lanes
): nil | Fiber
	-- We should never be hydrating at this point because it is the first pass,
	-- but after we've already committed once.
	warnIfHydrating()

	if bit32.band(getExecutionContext(), RetryAfterError) ~= NoContext then
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	end

	if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	end

	if isSuspenseInstanceFallback(suspenseInstance) then
		-- This boundary is in a permanent fallback state. In this case, we'll never
		-- get an update and we'll never be able to hydrate the final content. Let's just try the
		-- client side render instead.
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	end
	-- We use lanes to indicate that a child might depend on context, so if
	-- any context has changed, we need to treat is as if the input might have changed.
	local hasContextChanged =
		ReactFiberLane.includesSomeLane(renderLanes, current.childLanes)
	if didReceiveUpdate or hasContextChanged then
		-- This boundary has changed since the first render. This means that we are now unable to
		-- hydrate it. We might still be able to hydrate it using a higher priority lane.
		local root = getWorkInProgressRoot()
		if root ~= nil then
			local attemptHydrationAtLane =
				ReactFiberLane.getBumpedLaneForHydration(root, renderLanes)
			if
				attemptHydrationAtLane ~= ReactFiberLane.NoLane
				and attemptHydrationAtLane ~= suspenseState.retryLane
			then
				-- Intentionally mutating since this render will get interrupted. This
				-- is one of the very rare times where we mutate the current tree
				-- during the render phase.
				suspenseState.retryLane = attemptHydrationAtLane
				-- TODO: Ideally this would inherit the event time of the current render
				local eventTime = ReactFiberLane.NoTimestamp
				scheduleUpdateOnFiber(current, attemptHydrationAtLane, eventTime)
				-- We have already tried to ping at a higher priority than we're rendering with
				-- so if we got here, we must have failed to hydrate at those levels. We must
				-- now give up. Instead, we're going to delete the whole subtree and instead inject
				-- a new real Suspense boundary to take its place, which may render content
				-- or fallback. This might suspend for a while and if it does we might still have
				-- an opportunity to hydrate before this pass commits.
			
end
		end

		-- If we have scheduled higher pri work above, this will probably just abort the render
		-- since we now have higher priority work, but in case it doesn't, we need to prepare to
		-- render something, if we time out. Even if that requires us to delete everything and
		-- skip hydration.
		-- Delay having to do this as long as the suspense timeout allows us.
		renderDidSuspendDelayIfPossible()
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	elseif isSuspenseInstancePending(suspenseInstance) then
		-- This component is still pending more data from the server, so we can't hydrate its
		-- content. We treat it as if this component suspended itself. It might seem as if
		-- we could just try to render it client-side instead. However, this will perform a
		-- lot of unnecessary work and is unlikely to complete since it often will suspend
		-- on missing data anyway. Additionally, the server might be able to render more
		-- than we can on the client yet. In that case we'd end up with more fallback states
		-- on the client than if we just leave it alone. If the server times out or errors
		-- these should update this boundary to the permanent Fallback state instead.
		-- Mark it as having captured (i.e. suspended).
		workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
		-- Leave the child in place. I.e. the dehydrated fragment.
		workInProgress.child = current.child

		-- Register a callback to retry this boundary once the server has sent the result.
		-- ROBLOX deviation: wrapper function in place of bind
		local retry = function()
			return retryDehydratedSuspenseBoundary(current)
		end

		if enableSchedulerTracing then
			if Schedule_tracing_wrap == nil then
				Schedule_tracing_wrap =
					require(script.Parent.Parent:WaitForChild('scheduler')).tracing.unstable_wrap
			end
			retry = Schedule_tracing_wrap(retry)
		end

		registerSuspenseInstanceRetry(suspenseInstance, retry)
		return nil
	else
		-- This is the first attempt.
		reenterHydrationStateFromDehydratedSuspenseInstance(
			workInProgress,
			suspenseInstance
		)
		local nextProps = workInProgress.pendingProps
		local primaryChildren = nextProps.children
		local primaryChildFragment =
			mountSuspensePrimaryChildren(workInProgress, primaryChildren, renderLanes)
		-- Mark the children as hydrating. This is a fast path to know whether this
		-- tree is part of a hydrating tree. This is used to determine if a child
		-- node has fully mounted yet, and for scheduling event replaying.
		-- Conceptually this is similar to Placement in that a new subtree is
		-- inserted into the React tree here. It just happens to not need DOM
		-- mutations because it already exists.
		primaryChildFragment.flags = bit32.bor(primaryChildFragment.flags, Hydrating)
		return primaryChildFragment
	end
end

-- function scheduleWorkOnFiber(fiber: Fiber, renderLanes: Lanes)
--   fiber.lanes = ReactFiberLane.mergeLanes(fiber.lanes, renderLanes)
--   local alternate = fiber.alternate
--   if alternate ~= nil)
--     alternate.lanes = ReactFiberLane.mergeLanes(alternate.lanes, renderLanes)
--   end
--   scheduleWorkOnParentPath(fiber.return, renderLanes)
-- end

-- function propagateSuspenseContextChange(
--   workInProgress: Fiber,
--   firstChild: nil | Fiber,
--   renderLanes: Lanes,
-- ): void {
--   -- Mark any Suspense boundaries with fallbacks as having work to do.
--   -- If they were previously forced into fallbacks, they may now be able
--   -- to unblock.
--   local node = firstChild
--   while (node ~= nil)
--     if node.tag == SuspenseComponent)
--       local state: SuspenseState | nil = node.memoizedState
--       if state ~= nil)
--         scheduleWorkOnFiber(node, renderLanes)
--       end
--     } elseif node.tag == SuspenseListComponent)
--       -- If the tail is hidden there might not be an Suspense boundaries
--       -- to schedule work on. In this case we have to schedule it on the
--       -- list itself.
--       -- We don't have to traverse to the children of the list since
--       -- the list will propagate the change when it rerenders.
--       scheduleWorkOnFiber(node, renderLanes)
--     } elseif node.child ~= nil)
--       node.child.return = node
--       node = node.child
--       continue
--     end
--     if node == workInProgress)
--       return
--     end
--     while (node.sibling == nil)
--       if node.return == nil or node.return == workInProgress)
--         return
--       end
--       node = node.return
--     end
--     node.sibling.return = node.return
--     node = node.sibling
--   end
-- end

-- function findLastContentRow(firstChild: nil | Fiber): nil | Fiber {
--   -- This is going to find the last row among these children that is already
--   -- showing content on the screen, as opposed to being in fallback state or
--   -- new. If a row has multiple Suspense boundaries, any of them being in the
--   -- fallback state, counts as the whole row being in a fallback state.
--   -- Note that the "rows" will be workInProgress, but any nested children
--   -- will still be current since we haven't rendered them yet. The mounted
--   -- order may not be the same as the new order. We use the new order.
--   local row = firstChild
--   local lastContentRow: nil | Fiber = nil
--   while (row ~= nil)
--     local currentRow = row.alternate
--     -- New rows can't be content rows.
--     if currentRow ~= nil and findFirstSuspended(currentRow) == nil)
--       lastContentRow = row
--     end
--     row = row.sibling
--   end
--   return lastContentRow
-- end

-- type SuspenseListRevealOrder = 'forwards' | 'backwards' | 'together' | void

-- function validateRevealOrder(revealOrder: SuspenseListRevealOrder)
--   if  __DEV__ then
--     if
--       revealOrder ~= undefined and
--       revealOrder ~= 'forwards' and
--       revealOrder ~= 'backwards' and
--       revealOrder ~= 'together' and
--       !didWarnAboutRevealOrder[revealOrder]
--     )
--       didWarnAboutRevealOrder[revealOrder] = true
--       if typeof revealOrder == 'string')
--         switch (revealOrder.toLowerCase())
--           case 'together':
--           case 'forwards':
--           case 'backwards': {
--             console.error(
--               '"%s" is not a valid value for revealOrder on <SuspenseList />. ' +
--                 'Use lowercase "%s" instead.',
--               revealOrder,
--               revealOrder.toLowerCase(),
--             )
--             break
--           end
--           case 'forward':
--           case 'backward': {
--             console.error(
--               '"%s" is not a valid value for revealOrder on <SuspenseList />. ' +
--                 'React uses the -s suffix in the spelling. Use "%ss" instead.',
--               revealOrder,
--               revealOrder.toLowerCase(),
--             )
--             break
--           end
--           default:
--             console.error(
--               '"%s" is not a supported revealOrder on <SuspenseList />. ' +
--                 'Did you mean "together", "forwards" or "backwards"?',
--               revealOrder,
--             )
--             break
--         end
--       else
--         console.error(
--           '%s is not a supported value for revealOrder on <SuspenseList />. ' +
--             'Did you mean "together", "forwards" or "backwards"?',
--           revealOrder,
--         )
--       end
--     end
--   end
-- end

-- function validateTailOptions(
--   tailMode: SuspenseListTailMode,
--   revealOrder: SuspenseListRevealOrder,
-- )
--   if  __DEV__ then
--     if tailMode ~= undefined and !didWarnAboutTailOptions[tailMode])
--       if tailMode ~= 'collapsed' and tailMode ~= 'hidden')
--         didWarnAboutTailOptions[tailMode] = true
--         console.error(
--           '"%s" is not a supported value for tail on <SuspenseList />. ' +
--             'Did you mean "collapsed" or "hidden"?',
--           tailMode,
--         )
--       } elseif revealOrder ~= 'forwards' and revealOrder ~= 'backwards')
--         didWarnAboutTailOptions[tailMode] = true
--         console.error(
--           '<SuspenseList tail="%s" /> is only valid if revealOrder is ' +
--             '"forwards" or "backwards". ' +
--             'Did you mean to specify revealOrder="forwards"?',
--           tailMode,
--         )
--       end
--     end
--   end
-- end

-- function validateSuspenseListNestedChild(childSlot: mixed, index: number)
--   if  __DEV__ then
--     local isArray = Array.isArray(childSlot)
--     local isIterable =
--       !isArray and typeof getIteratorFn(childSlot) == 'function'
--     if isArray or isIterable)
--       local type = isArray ? 'array' : 'iterable'
--       console.error(
--         'A nested %s was passed to row #%s in <SuspenseList />. Wrap it in ' +
--           'an additional SuspenseList to configure its revealOrder: ' +
--           '<SuspenseList revealOrder=...> ... ' +
--           '<SuspenseList revealOrder=...>{%s}</SuspenseList> ... ' +
--           '</SuspenseList>',
--         type,
--         index,
--         type,
--       )
--       return false
--     end
--   end
--   return true
-- end

-- function validateSuspenseListChildren(
--   children: mixed,
--   revealOrder: SuspenseListRevealOrder,
-- )
--   if  __DEV__ then
--     if
--       (revealOrder == 'forwards' or revealOrder == 'backwards') and
--       children ~= undefined and
--       children ~= nil and
--       children ~= false
--     )
--       if Array.isArray(children))
--         for (local i = 0; i < children.length; i++)
--           if not validateSuspenseListNestedChild(children[i], i))
--             return
--           end
--         end
--       else
--         local iteratorFn = getIteratorFn(children)
--         if typeof iteratorFn == 'function')
--           local childrenIterator = iteratorFn.call(children)
--           if childrenIterator)
--             local step = childrenIterator.next()
--             local i = 0
--             for (; !step.done; step = childrenIterator.next())
--               if not validateSuspenseListNestedChild(step.value, i))
--                 return
--               end
--               i++
--             end
--           end
--         else
--           console.error(
--             'A single row was passed to a <SuspenseList revealOrder="%s" />. ' +
--               'This is not useful since it needs multiple rows. ' +
--               'Did you mean to pass multiple children or an array?',
--             revealOrder,
--           )
--         end
--       end
--     end
--   end
-- end

-- function initSuspenseListRenderState(
--   workInProgress: Fiber,
--   isBackwards: boolean,
--   tail: nil | Fiber,
--   lastContentRow: nil | Fiber,
--   tailMode: SuspenseListTailMode,
-- ): void {
--   local renderState: nil | SuspenseListRenderState =
--     workInProgress.memoizedState
--   if renderState == nil)
--     workInProgress.memoizedState = ({
--       isBackwards: isBackwards,
--       rendering: nil,
--       renderingStartTime: 0,
--       last: lastContentRow,
--       tail: tail,
--       tailMode: tailMode,
--     }: SuspenseListRenderState)
--   else
--     -- We can reuse the existing object from previous renders.
--     renderState.isBackwards = isBackwards
--     renderState.rendering = nil
--     renderState.renderingStartTime = 0
--     renderState.last = lastContentRow
--     renderState.tail = tail
--     renderState.tailMode = tailMode
--   end
-- end

-- -- This can end up rendering this component multiple passes.
-- -- The first pass splits the children fibers into two sets. A head and tail.
-- -- We first render the head. If anything is in fallback state, we do another
-- -- pass through beginWork to rerender all children (including the tail) with
-- -- the force suspend context. If the first render didn't have anything in
-- -- in fallback state. Then we render each row in the tail one-by-one.
-- -- That happens in the completeWork phase without going back to beginWork.
-- function updateSuspenseListComponent(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   renderLanes: Lanes,
-- )
--   local nextProps = workInProgress.pendingProps
--   local revealOrder: SuspenseListRevealOrder = nextProps.revealOrder
--   local tailMode: SuspenseListTailMode = nextProps.tail
--   local newChildren = nextProps.children

--   validateRevealOrder(revealOrder)
--   validateTailOptions(tailMode, revealOrder)
--   validateSuspenseListChildren(newChildren, revealOrder)

--   reconcileChildren(current, workInProgress, newChildren, renderLanes)

--   local suspenseContext: SuspenseContext = suspenseStackCursor.current

--   local shouldForceFallback = hasSuspenseContext(
--     suspenseContext,
--     (ForceSuspenseFallback: SuspenseContext),
--   )
--   if shouldForceFallback)
--     suspenseContext = setShallowSuspenseContext(
--       suspenseContext,
--       ForceSuspenseFallback,
--     )
--     workInProgress.flags |= DidCapture
--   else
--     local didSuspendBefore =
--       current ~= nil and (current.flags & DidCapture) ~= NoFlags
--     if didSuspendBefore)
--       -- If we previously forced a fallback, we need to schedule work
--       -- on any nested boundaries to local them know to try to render
--       -- again. This is the same as context updating.
--       propagateSuspenseContextChange(
--         workInProgress,
--         workInProgress.child,
--         renderLanes,
--       )
--     end
--     suspenseContext = setDefaultShallowSuspenseContext(suspenseContext)
--   end
--   pushSuspenseContext(workInProgress, suspenseContext)

--   if (workInProgress.mode & BlockingMode) == NoMode)
--     -- In legacy mode, SuspenseList doesn't work so we just
--     -- use make it a noop by treating it as the default revealOrder.
--     workInProgress.memoizedState = nil
--   else
--     switch (revealOrder)
--       case 'forwards': {
--         local lastContentRow = findLastContentRow(workInProgress.child)
--         local tail
--         if lastContentRow == nil)
--           -- The whole list is part of the tail.
--           -- TODO: We could fast path by just rendering the tail now.
--           tail = workInProgress.child
--           workInProgress.child = nil
--         else
--           -- Disconnect the tail rows after the content row.
--           -- We're going to render them separately later.
--           tail = lastContentRow.sibling
--           lastContentRow.sibling = nil
--         end
--         initSuspenseListRenderState(
--           workInProgress,
--           false, -- isBackwards
--           tail,
--           lastContentRow,
--           tailMode,
--         )
--         break
--       end
--       case 'backwards': {
--         -- We're going to find the first row that has existing content.
--         -- At the same time we're going to reverse the list of everything
--         -- we pass in the meantime. That's going to be our tail in reverse
--         -- order.
--         local tail = nil
--         local row = workInProgress.child
--         workInProgress.child = nil
--         while (row ~= nil)
--           local currentRow = row.alternate
--           -- New rows can't be content rows.
--           if currentRow ~= nil and findFirstSuspended(currentRow) == nil)
--             -- This is the beginning of the main content.
--             workInProgress.child = row
--             break
--           end
--           local nextRow = row.sibling
--           row.sibling = tail
--           tail = row
--           row = nextRow
--         end
--         -- TODO: If workInProgress.child is nil, we can continue on the tail immediately.
--         initSuspenseListRenderState(
--           workInProgress,
--           true, -- isBackwards
--           tail,
--           nil, -- last
--           tailMode,
--         )
--         break
--       end
--       case 'together': {
--         initSuspenseListRenderState(
--           workInProgress,
--           false, -- isBackwards
--           nil, -- tail
--           nil, -- last
--           undefined,
--         )
--         break
--       end
--       default: {
--         -- The default reveal order is the same as not having
--         -- a boundary.
--         workInProgress.memoizedState = nil
--       end
--     end
--   end
--   return workInProgress.child
-- end

function updatePortalComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	pushHostContainer(workInProgress, workInProgress.stateNode.containerInfo)
	local nextChildren = workInProgress.pendingProps
	if current == nil then
		-- Portals are special because we don't append the children during mount
		-- but at commit. Therefore we need to track insertions which the normal
		-- flow doesn't do during mount. This doesn't happen at the root because
		-- the root always starts with a "current" with a nil child.
		-- TODO: Consider unifying this with how the root works.
		workInProgress.child =
			reconcileChildFibers(workInProgress, nil, nextChildren, renderLanes)
	else
		reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	end
	return workInProgress.child
end

local hasWarnedAboutUsingNoValuePropOnContextProvider = false

local function updateContextProvider(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	local providerType: ReactProviderType<any> = workInProgress.type
	local context: ReactContext<any> = providerType._context

	local newProps = workInProgress.pendingProps
	local oldProps = workInProgress.memoizedProps

	local newValue = newProps.value

	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if Array.indexOf(Object.keys(newProps), "value") < 1 then
			if not hasWarnedAboutUsingNoValuePropOnContextProvider then
				hasWarnedAboutUsingNoValuePropOnContextProvider = true
				console.error(
					"The `value` prop is required for the `<Context.Provider>`. Did you misspell it or forget to pass it?"
				)
			end
		end
		-- ROBLOX deviation: adds support for legacy Roact's validateProps()
		local providerPropTypes = workInProgress.type.propTypes
		local validateProps = workInProgress.type.validateProps

		if providerPropTypes or validateProps then
			checkPropTypes(
				providerPropTypes,
				validateProps,
				newProps,
				"prop",
				"Context.Provider"
			)
		end
	end

	pushProvider(workInProgress, newValue)

	if oldProps ~= nil then
		local oldValue = oldProps.value
		local changedBits = calculateChangedBits(context, newValue, oldValue)
		if changedBits == 0 then
			-- No change. Bailout early if children are the same.
			if
				oldProps.children == newProps.children
				and not hasLegacyContextChanged()
			then
				return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
			end
		else
			-- The context value changed. Search for matching consumers and schedule
			-- them to update.
			propagateContextChange(workInProgress, context, changedBits, renderLanes)
		end
	end

	local newChildren = newProps.children
	reconcileChildren(current, workInProgress, newChildren, renderLanes)
	return workInProgress.child
end

-- ROBLOX deviation: combine two warning flags to dodge the registers limit
local hasWarnedAbout = {
	usingContextAsConsumer = false,
	usingLegacyConsumer = false,
}

function updateContextConsumer(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	local context: ReactContext<any> = workInProgress.type
	-- The logic below for Context differs depending on PROD or DEV mode. In
	-- DEV mode, we create a separate object for Context.Consumer that acts
	-- like a proxy to Context. This proxy object adds unnecessary code in PROD
	-- so we use the old behaviour (Context.Consumer references Context) to
	-- reduce size and overhead. The separate object references context via
	-- a property called "_context", which also gives us the ability to check
	-- in DEV mode if this property exists or not and warn if it does not.
	if __DEV__ then
		if (context :: any)._context == nil then
			-- This may be because it's a Context (rather than a Consumer).
			-- Or it may be because it's older React where they're the same thing.
			-- We only want to warn if we're sure it's a new React.
			if context ~= context.Consumer then
				if not hasWarnedAbout.usingContextAsConsumer then
					hasWarnedAbout.usingContextAsConsumer = true
					console.error(
[[Rendering <Context> directly is not supported and will be removed in a future major release. Did you mean to render <Context.Consumer> instead?]]					

)
				end
			end
		else
			context = (context :: any)._context
		end
	end
	local newProps = workInProgress.pendingProps

	-- ROBLOX deviation: compatibility for old Roact's context consumer API
	local render
	if newProps.render then
		if __DEV__ and __COMPAT_WARNINGS__ then
			if not hasWarnedAbout.usingLegacyConsumer then
				hasWarnedAbout.usingLegacyConsumer = true
				console.warn(
[[Your Context.Consumer component is using legacy Roact syntax, which won't be supported in future versions of Roact. 
Please provide no props and supply the 'render' function as a child (the 3rd argument of createElement). For example: 
       createElement(ContextConsumer, {render = function(...) end})
becomes:
       createElement(ContextConsumer, nil, function(...) end)
For more info, reference the React documentation here: 
https://reactjs.org/docs/context.html#contextconsumer]]				
)
			end
		end
		render = newProps.render
	else
		render = newProps.children
	end

	if __DEV__ then
		if type(render) ~= "function" then
			console.error(
[[A context consumer was rendered with multiple children, or a child that isn't a function. A context consumer expects a single child that is a function. If you did pass a function, make sure there is no trailing or leading whitespace around it.]]			



)
		end
	end

	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	local newValue = readContext(context, newProps.unstable_observedBits)
	local newChildren
	if __DEV__ then
		ReactCurrentOwner.current = workInProgress
		setIsRendering(true)
		newChildren = render(newValue)
		setIsRendering(false)
	else
		newChildren = render(newValue)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	reconcileChildren(current, workInProgress, newChildren, renderLanes)
	return workInProgress.child
end

-- ROBLOX TODO: fundamental component is removed in React 18, clean up all traces when we upgrade
-- function updateFundamentalComponent(current, workInProgress, renderLanes)
--   local fundamentalImpl = workInProgress.type.impl
--   if fundamentalImpl.reconcileChildren == false then
--     return nil
--   end
--   local nextProps = workInProgress.pendingProps
--   local nextChildren = nextProps.children

--   reconcileChildren(current, workInProgress, nextChildren, renderLanes)
--   return workInProgress.child
-- end

-- ROBLOX TODO: scope component is disabled in our FeatureFlags, uncomment when we enable it
-- function updateScopeComponent(current, workInProgress, renderLanes)
--   local nextProps = workInProgress.pendingProps
--   local nextChildren = nextProps.children

--   reconcileChildren(current, workInProgress, nextChildren, renderLanes)
--   return workInProgress.child
-- end

exports.markWorkInProgressReceivedUpdate = function()
	didReceiveUpdate = true
end

function bailoutOnAlreadyFinishedWork(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
): Fiber | nil
	if current then
		-- Reuse previous dependencies
		workInProgress.dependencies = current.dependencies
	end

	if enableProfilerTimer then
		-- Don't update "base" render times for bailouts.
		stopProfilerTimerIfRunning(workInProgress)
	end

	markSkippedUpdateLanes(workInProgress.lanes)

	-- Check if the children have any pending work.
	if not ReactFiberLane.includesSomeLane(renderLanes, workInProgress.childLanes) then
		-- The children don't have any work either. We can skip them.
		-- TODO: Once we add back resuming, we should check if the children are
		-- a work-in-progress set. If so, we need to transfer their effects.
		return nil
	else
		-- This fiber doesn't have work, but its subtree does. Clone the child
		-- fibers and continue.
		cloneChildFibers(current, workInProgress)
		return workInProgress.child
	end
end

function remountFiber(
	current: Fiber,
	oldWorkInProgress: Fiber,
	newWorkInProgress: Fiber
): Fiber | nil
	if __DEV__ then
		local returnFiber = oldWorkInProgress.return_
		if returnFiber == nil then
			error("Cannot swap the root fiber.")
		end
		-- ROBLOX FIXME Luau: remove this assert when Luau type states understands the above guard
		assert(returnFiber ~= nil, "returnFiber was nil in remountFiber")

		-- Disconnect from the old current.
		-- It will get deleted.
		current.alternate = nil
		oldWorkInProgress.alternate = nil

		-- Connect to the new tree.
		newWorkInProgress.index = oldWorkInProgress.index
		newWorkInProgress.sibling = oldWorkInProgress.sibling
		newWorkInProgress.return_ = oldWorkInProgress.return_
		newWorkInProgress.ref = oldWorkInProgress.ref

		-- Replace the child/sibling pointers above it.
		if oldWorkInProgress == returnFiber.child then
			returnFiber.child = newWorkInProgress
		else
			local prevSibling = returnFiber.child
			if prevSibling == nil then
				error("Expected parent to have a child.")
			end
			-- ROBLOX FIXME Luau: remove this assert when Luau type states understands the above guard
			assert(prevSibling ~= nil, "prevSibling was nil in remountFiber")

			while prevSibling.sibling ~= oldWorkInProgress do
				prevSibling = prevSibling.sibling
				if prevSibling == nil then
					error("Expected to find the previous sibling.")
				end
			end
			prevSibling.sibling = newWorkInProgress
		end

		-- Delete the old fiber and place the new one.
		-- Since the old fiber is disconnected, we have to schedule it manually.
		local deletions = returnFiber.deletions
		if deletions == nil then
			returnFiber.deletions = { current }
			-- TODO (effects) Rename this to better reflect its new usage (e.g. ChildDeletions)
			returnFiber.flags = bit32.bor(returnFiber.flags, Deletion)
		else
			table.insert(deletions, current)
		end

		newWorkInProgress.flags = bit32.bor(newWorkInProgress.flags, Placement)

		-- Restart work from the new fiber.
		return newWorkInProgress
	else
		error(
[[Did not expect this call in production. This is a bug in React. Please file an issue.]]		

)
	end
end

-- FIXME (roblox): restore types when refinement is better:
-- current: Fiber | nil,
local function beginWork(current: any, workInProgress: Fiber, renderLanes: Lanes): Fiber?
	local updateLanes = workInProgress.lanes

	if __DEV__ then
		if workInProgress._debugNeedsRemount and current ~= nil then
			-- This will restart the begin phase with a new fiber.
			return remountFiber(
				current,
				workInProgress,
				createFiberFromTypeAndProps(
					workInProgress.type,
					-- ROBLOX FIXME: we widen this to be number|string for Roact compatibility
					workInProgress.key :: string?,
					workInProgress.pendingProps,
					workInProgress._debugOwner or nil,
					workInProgress.mode,
					workInProgress.lanes
				)
			)
		end
	end

	if current ~= nil then
		local oldProps = current.memoizedProps
		local newProps = workInProgress.pendingProps

		if
			oldProps ~= newProps
			or hasLegacyContextChanged()
			-- Force a re-render if the implementation changed due to hot reload:
			or if __DEV__ then workInProgress.type ~= current.type else false
		then
			-- If props or context changed, mark the fiber as having performed work.
			-- This may be unset if the props are determined to be equal later (memo).
			didReceiveUpdate = true
		elseif not ReactFiberLane.includesSomeLane(renderLanes, updateLanes) then
			didReceiveUpdate = false
			-- This fiber does not have any pending work. Bailout without entering
			-- the begin phase. There's still some bookkeeping we that needs to be done
			-- in this optimized path, mostly pushing stuff onto the stack.
			if workInProgress.tag == HostRoot then
				pushHostRootContext(workInProgress)
				resetHydrationState()
			elseif workInProgress.tag == HostComponent then
				pushHostContext(workInProgress)
			elseif workInProgress.tag == ClassComponent then
				local Component = workInProgress.type
				if isLegacyContextProvider(Component) then
					pushLegacyContextProvider(workInProgress)
				end
			elseif workInProgress.tag == HostPortal then
				pushHostContainer(workInProgress, workInProgress.stateNode.containerInfo)
			elseif workInProgress.tag == ContextProvider then
				local newValue = workInProgress.memoizedProps.value
				pushProvider(workInProgress, newValue)
			elseif workInProgress.tag == Profiler then
				if enableProfilerTimer then
					-- Reset effect durations for the next eventual effect phase.
					-- These are reset during render to allow the DevTools commit hook a chance to read them,
					local stateNode = workInProgress.stateNode
					stateNode.effectDuration = 0
					stateNode.passiveEffectDuration = 0
				end
			elseif workInProgress.tag == SuspenseComponent then
				local state: SuspenseState | nil = workInProgress.memoizedState
				if state ~= nil then
					if enableSuspenseServerRenderer then
						if (state :: SuspenseState).dehydrated ~= nil then
							pushSuspenseContext(
								workInProgress,
								setDefaultShallowSuspenseContext(
									suspenseStackCursor.current
								)
							)
							-- We know that this component will suspend again because if it has
							-- been unsuspended it has committed as a resolved Suspense component.
							-- If it needs to be retried, it should have work scheduled on it.
							workInProgress.flags =
								bit32.bor(workInProgress.flags, DidCapture)
							-- We should never render the children of a dehydrated boundary until we
							-- upgrade it. We return nil instead of bailoutOnAlreadyFinishedWork.
							return nil
						end
					end

					-- If this boundary is currently timed out, we need to decide
					-- whether to retry the primary children, or to skip over it and
					-- go straight to the fallback. Check the priority of the primary
					-- child fragment.
					local primaryChildFragment: Fiber = workInProgress.child :: any
					local primaryChildLanes = primaryChildFragment.childLanes
					if
						ReactFiberLane.includesSomeLane(renderLanes, primaryChildLanes)
					then
						-- The primary children have pending work. Use the normal path
						-- to attempt to render the primary children again.
						return updateSuspenseComponent(
							current,
							workInProgress,
							renderLanes
						)
					else
						-- The primary child fragment does not have pending work marked
						-- on it
						pushSuspenseContext(
							workInProgress,
							setDefaultShallowSuspenseContext(suspenseStackCursor.current)
						)
						-- The primary children do not have pending work with sufficient
						-- priority. Bailout.
						local child = bailoutOnAlreadyFinishedWork(
							current,
							workInProgress,
							renderLanes
						)
						if child ~= nil then
							-- The fallback children have pending work. Skip over the
							-- primary children and work on the fallback.
							return child.sibling
						else
							return nil
						end
					end
				else
					pushSuspenseContext(
						workInProgress,
						setDefaultShallowSuspenseContext(suspenseStackCursor.current)
					)
				end
			elseif workInProgress.tag == SuspenseListComponent then
				unimplemented("beginWork: SuspenseListComponent")
			-- local didSuspendBefore = bit32.band(current.flags, DidCapture) ~= NoFlags

			-- local hasChildWork = ReactFiberLane.includesSomeLane(
			--   renderLanes,
			--   workInProgress.childLanes
			-- )

			-- if didSuspendBefore then
			--   if hasChildWork then
			--     -- If something was in fallback state last time, and we have all the
			--     -- same children then we're still in progressive loading state.
			--     -- Something might get unblocked by state updates or retries in the
			--     -- tree which will affect the tail. So we need to use the normal
			--     -- path to compute the correct tail.
			--     return updateSuspenseListComponent(
			--       current,
			--       workInProgress,
			--       renderLanes
			--     )
			--   end
			--   -- If none of the children had any work, that means that none of
			--   -- them got retried so they'll still be blocked in the same way
			--   -- as before. We can fast bail out.
			--   workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
			-- end

			-- -- If nothing suspended before and we're rendering the same children,
			-- -- then the tail doesn't matter. Anything new that suspends will work
			-- -- in the "together" mode, so we can continue from the state we had.
			-- local renderState = workInProgress.memoizedState
			-- if renderState ~= nil then
			--   -- Reset to the "together" mode in case we've started a different
			--   -- update in the past but didn't complete it.
			--   renderState.rendering = nil
			--   renderState.tail = nil
			-- end
			-- pushSuspenseContext(workInProgress, suspenseStackCursor.current)

			-- if not hasChildWork then
			--   -- If none of the children had any work, that means that none of
			--   -- them got retried so they'll still be blocked in the same way
			--   -- as before. We can fast bail out.
			--   return nil
			-- end
			elseif
				workInProgress.tag == OffscreenComponent
				or workInProgress.tag == LegacyHiddenComponent
			then
				-- Need to check if the tree still needs to be deferred. This is
				-- almost identical to the logic used in the normal update path,
				-- so we'll just enter that. The only difference is we'll bail out
				-- at the next level instead of this one, because the child props
				-- have not changed. Which is fine.
				-- TODO: Probably should refactor `beginWork` to split the bailout
				-- path from the normal path. I'm tempted to do a labeled break here
				-- but I won't :)
				workInProgress.lanes = ReactFiberLane.NoLanes
				return updateOffscreenComponent(current, workInProgress, renderLanes)
			end
			return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
		else
			if bit32.band(current.flags, ForceUpdateForLegacySuspense) ~= NoFlags then
				-- This is a special case that only exists for legacy mode.
				-- See https://github.com/facebook/react/pull/19216.
				didReceiveUpdate = true
			else
				-- An update was scheduled on this fiber, but there are no new props
				-- nor legacy context. Set this to false. If an update queue or context
				-- consumer produces a changed value, it will set this to true. Otherwise,
				-- the component will assume the children have not changed and bail out.
				didReceiveUpdate = false
			end
		end
	else
		didReceiveUpdate = false
	end

	-- Before entering the begin phase, clear pending update priority.
	-- TODO: This assumes that we're about to evaluate the component and process
	-- the update queue. However, there's an exception: SimpleMemoComponent
	-- sometimes bails out later in the begin phase. This indicates that we should
	-- move this assignment out of the common path and into each branch.
	workInProgress.lanes = ReactFiberLane.NoLanes

	if workInProgress.tag == ReactWorkTags.IndeterminateComponent then
		return mountIndeterminateComponent(
			current,
			workInProgress,
			workInProgress.type,
			renderLanes
		)
	elseif workInProgress.tag == LazyComponent then
		local elementType = workInProgress.elementType
		return mountLazyComponent(
			current,
			workInProgress,
			elementType,
			updateLanes,
			renderLanes
		)
	elseif workInProgress.tag == FunctionComponent then
		local Component = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps
		if workInProgress.elementType == Component then
			resolvedProps = unresolvedProps
		else
			resolvedProps = resolveDefaultProps(Component, unresolvedProps)
		end
		return updateFunctionComponent(
			current,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
	elseif workInProgress.tag == ClassComponent then
		local Component = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps = workInProgress.elementType == Component and unresolvedProps
			or resolveDefaultProps(Component, unresolvedProps)
		return updateClassComponent(
			current,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
	elseif workInProgress.tag == HostRoot then
		return updateHostRoot(current, workInProgress, renderLanes)
	elseif workInProgress.tag == HostComponent then
		return updateHostComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == HostText then
		return updateHostText(current, workInProgress)
	elseif workInProgress.tag == SuspenseComponent then
		return updateSuspenseComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == HostPortal then
		return updatePortalComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == ForwardRef then
		local type = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps = unresolvedProps
		if workInProgress.elementType ~= type then
			resolvedProps = resolveDefaultProps(type, unresolvedProps)
		end
		return updateForwardRef(current, workInProgress, type, resolvedProps, renderLanes)
	elseif workInProgress.tag == Fragment then
		return updateFragment(current, workInProgress, renderLanes)
	elseif workInProgress.tag == Mode then
		return updateMode(current, workInProgress, renderLanes)
	elseif workInProgress.tag == Profiler then
		return updateProfiler(current, workInProgress, renderLanes)
	elseif workInProgress.tag == ContextProvider then
		return updateContextProvider(current, workInProgress, renderLanes)
	elseif workInProgress.tag == ContextConsumer then
		return updateContextConsumer(current, workInProgress, renderLanes)
	elseif workInProgress.tag == MemoComponent then
		local type_ = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		-- Resolve outer props first, then resolve inner props.
		local resolvedProps = resolveDefaultProps(type_, unresolvedProps)
		if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
			if workInProgress.type ~= workInProgress.elementType then
				-- ROBLOX deviation: adds support for legacy Roact's validateProps()
				local outerPropTypes
				local validateProps
				-- ROBLOX deviation: only get propTypes from class components, Lua doesn't support fields on functions
				if type(type_) == "table" then
					outerPropTypes = type_.propTypes
					validateProps = type_.validateProps
				end
				if outerPropTypes or validateProps then
					checkPropTypes(
						outerPropTypes,
						validateProps,
						resolvedProps, -- Resolved for outer only
						"prop",
						getComponentName(type_)
					)
				end
			end
		end
		resolvedProps = resolveDefaultProps(type_.type, resolvedProps)
		return updateMemoComponent(
			current,
			workInProgress,
			type_,
			resolvedProps,
			updateLanes,
			renderLanes
		)
	elseif workInProgress.tag == SimpleMemoComponent then
		return updateSimpleMemoComponent(
			current,
			workInProgress,
			workInProgress.type,
			workInProgress.pendingProps,
			updateLanes,
			renderLanes
		)
	elseif workInProgress.tag == IncompleteClassComponent then
		local Component = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps = workInProgress.elementType == Component and unresolvedProps
			or resolveDefaultProps(Component, unresolvedProps)
		return mountIncompleteClassComponent(
			current,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
	-- elseif workInProgress.tag == SuspenseListComponent then
	--   unimplemented("beginWork: SuspenseListComponent")
	-- return updateSuspenseListComponent(current, workInProgress, renderLanes)
	-- elseif workInProgress.tag == FundamentalComponent then
	--   if enableFundamentalAPI then
	--     return updateFundamentalComponent(current, workInProgress, renderLanes)
	--   end
	-- elseif workInProgress.tag == ScopeComponent then
	--   if enableScopeAPI then
	--     return updateScopeComponent(current, workInProgress, renderLanes)
	--   end
	elseif workInProgress.tag == OffscreenComponent then
		return updateOffscreenComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == LegacyHiddenComponent then
		return updateLegacyHiddenComponent(current, workInProgress, renderLanes)
	end
	invariant(
		false,
[[Unknown unit of work tag (%s). This error is likely caused by a bug in React. Please file an issue.]]
,
		tostring(workInProgress.tag)
	)
	return nil
end
exports.beginWork = beginWork

return exports

end,
["react-reconciler/ReactFiberClassComponent.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/c63741fb3daef6c1e8746cbe7d7b07ecb281a9fd/packages/react-reconciler/src/ReactFiberClassComponent.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local __DEV__ = _G.__DEV__ :: boolean
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
local ReactUpdateQueue = require(script.Parent:WaitForChild('ReactUpdateQueue.new'))
type UpdateQueue<State> = ReactInternalTypes.UpdateQueue<State>

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type React_Component<Props, State> = ReactTypes.React_Component<Props, State>

local React = require(script.Parent.Parent:WaitForChild('react'))

local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local Update = ReactFiberFlags.Update
local Snapshot = ReactFiberFlags.Snapshot
local MountLayoutDev = ReactFiberFlags.MountLayoutDev

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local debugRenderPhaseSideEffectsForStrictMode =
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode
local disableLegacyContext = ReactFeatureFlags.disableLegacyContext
local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local warnAboutDeprecatedLifecycles = ReactFeatureFlags.warnAboutDeprecatedLifecycles
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects

local ReactStrictModeWarnings = require(script.Parent:WaitForChild('ReactStrictModeWarnings.new'))
local isMounted = require(script.Parent:WaitForChild('ReactFiberTreeReflection')).isMounted
local ReactInstanceMap = require(script.Parent.Parent:WaitForChild('shared')).ReactInstanceMap
local getInstance = ReactInstanceMap.get
local setInstance = ReactInstanceMap.set
local shallowEqual = require(script.Parent.Parent:WaitForChild('shared')).shallowEqual
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local UninitializedState = require(script.Parent.Parent:WaitForChild('shared')).UninitializedState
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError
-- local invariant = require("@pkg/@jsdotlua/shared").invariant
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE

local resolveDefaultProps =
	require(script.Parent:WaitForChild('ReactFiberLazyComponent.new')).resolveDefaultProps
local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
local DebugTracingMode = ReactTypeOfMode.DebugTracingMode
local StrictMode = ReactTypeOfMode.StrictMode

local enqueueUpdate = ReactUpdateQueue.enqueueUpdate
local processUpdateQueue = ReactUpdateQueue.processUpdateQueue
local checkHasForceUpdateAfterProcessing =
	ReactUpdateQueue.checkHasForceUpdateAfterProcessing
local resetHasForceUpdateBeforeProcessing =
	ReactUpdateQueue.resetHasForceUpdateBeforeProcessing
local createUpdate = ReactUpdateQueue.createUpdate
local ReplaceState = ReactUpdateQueue.ReplaceState
local ForceUpdate = ReactUpdateQueue.ForceUpdate
local initializeUpdateQueue = ReactUpdateQueue.initializeUpdateQueue
local cloneUpdateQueue = ReactUpdateQueue.cloneUpdateQueue
local NoLanes = ReactFiberLane.NoLanes

local ReactFiberContext = require(script.Parent:WaitForChild('ReactFiberContext.new'))
local cacheContext = ReactFiberContext.cacheContext
local getMaskedContext = ReactFiberContext.getMaskedContext
local getUnmaskedContext = ReactFiberContext.getUnmaskedContext
local hasContextChanged = ReactFiberContext.hasContextChanged
local emptyContextObject = ReactFiberContext.emptyContextObject

local ReactFiberNewContext = require(script.Parent:WaitForChild('ReactFiberNewContext.new'))
local readContext = ReactFiberNewContext.readContext

-- local ReactFiberWorkLoop = require("./ReactFiberWorkLoop.new.luau")
-- local requestEventTime = ReactFiberWorkLoop.requestEventTime
-- local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
-- local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local DebugTracing = require(script.Parent:WaitForChild('DebugTracing'))
local logForceUpdateScheduled = DebugTracing.logForceUpdateScheduled
local logStateUpdateScheduled = DebugTracing.logStateUpdateScheduled

local ConsolePatchingDev = require(script.Parent.Parent:WaitForChild('shared')).ConsolePatchingDev
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

local SchedulingProfiler = require(script.Parent:WaitForChild('SchedulingProfiler'))
local markForceUpdateScheduled = SchedulingProfiler.markForceUpdateScheduled
local markStateUpdateScheduled = SchedulingProfiler.markStateUpdateScheduled

local fakeInternalInstance = {}
-- ROBLOX TODO: If this is being localized, it might be for a hot path; that's
-- concerning, since our version of `isArray` is much more complex
-- local isArray = Array.isArray

-- React.Component uses a shared frozen object by default.
-- We'll use it to determine whether we need to initialize legacy refs.
-- ROBLOX deviation: Uses __refs instead of refs to avoid conflicts
-- local emptyRefsObject = React.Component:extend("").refs
local emptyRefsObject = React.Component:extend("").__refs

local didWarnAboutStateAssignmentForComponent
local didWarnAboutUninitializedState
local didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate
local didWarnAboutLegacyLifecyclesAndDerivedState
local _didWarnAboutUndefinedDerivedState
local warnOnUndefinedDerivedState
local warnOnInvalidCallback
local didWarnAboutDirectlyAssigningPropsToState
local didWarnAboutContextTypeAndContextTypes
local didWarnAboutInvalidateContextType

if __DEV__ then
	didWarnAboutStateAssignmentForComponent = {}
	didWarnAboutUninitializedState = {}
	didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate = {}
	didWarnAboutLegacyLifecyclesAndDerivedState = {}
	didWarnAboutDirectlyAssigningPropsToState = {}
	_didWarnAboutUndefinedDerivedState = {}
	didWarnAboutContextTypeAndContextTypes = {}
	didWarnAboutInvalidateContextType = {}

	local didWarnOnInvalidCallback = {}

	function warnOnInvalidCallback(callback: any, callerName: string)
		if callback == nil or type(callback) == "function" then
			return
		end
		local key = callerName .. "_" .. tostring(callback)
		if not didWarnOnInvalidCallback[key] then
			didWarnOnInvalidCallback[key] = true
			console.error(
[[%s(...): Expected the last optional `callback` argument to be a function. Instead received: %s.]]
,
				callerName,
				tostring(callback)
			)
		end
	end

	function warnOnUndefinedDerivedState(type_, partialState)
		-- ROBLOX deviation: `nil` is a valid return for getDerivedStateFromProps, but
		-- `undefined` is not possible for us to return; we could try to detect
		-- returning zero values, but that's likely not possible without tracking it
		-- differently at the original callsite (e.g. the value we save to
		-- `partialState` would still be nil)

		-- if partialState == nil then
		--   local componentName = getComponentName(type_) or "Component"
		--   if not didWarnAboutUndefinedDerivedState[componentName] then
		--     didWarnAboutUndefinedDerivedState[componentName] = true
		--     console.error(
		--       "%s.getDerivedStateFromProps(): A valid state object (or nil) must be returned. " ..
		--         "You have returned undefined.",
		--       componentName
		--     )
		--   end
		-- end
	end

	--   -- ROBLOX FIXME: I'm not sure this applies, need to revisit it
	--   -- -- This is so gross but it's at least non-critical and can be removed if
	--   -- -- it causes problems. This is meant to give a nicer error message for
	--   -- -- ReactDOM15.unstable_renderSubtreeIntoContainer(reactDOM16Component,
	--   -- -- ...)) which otherwise throws a "_processChildContext is not a function"
	--   -- -- exception.
	--   -- Object.defineProperty(fakeInternalInstance, '_processChildContext', {
	--   --   enumerable: false,
	--   --   value: function()
	--   --     invariant(
	--   --       false,
	--   --       '_processChildContext is not available in React 16+. This likely ' +
	--   --         'means you have multiple copies of React and are attempting to nest ' +
	--   --         'a React 15 tree inside a React 16 tree using ' +
	--   --         "unstable_renderSubtreeIntoContainer, which isn't supported. Try " +
	--   --         'to make sure you have only one copy of React (and ideally, switch ' +
	--   --         'to ReactDOM.createPortal).',
	--   --     )
	--   --   },
	--   -- })
	--   Object.freeze(fakeInternalInstance)
end

local function applyDerivedStateFromProps<Props, State>(
	workInProgress: Fiber,
	ctor: React_Component<Props, State>,
	getDerivedStateFromProps: (Props, State) -> State?,
	nextProps: Props
)
	local prevState = workInProgress.memoizedState

	if __DEV__ then
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			-- Invoke the function an extra time to help detect side-effects.
			local ok, result =
				xpcall(getDerivedStateFromProps, describeError, nextProps, prevState)

			reenableLogs()

			if not ok then
				error(result)
			end
		end
	end

	local partialState = getDerivedStateFromProps(nextProps, prevState)

	if __DEV__ then
		warnOnUndefinedDerivedState(ctor, partialState)
	end
	-- Merge the partial state and the previous state.
	local memoizedState = if partialState == nil
		then prevState
		else Object.assign({}, prevState, partialState)
	workInProgress.memoizedState = memoizedState

	-- Once the update queue is empty, persist the derived state onto the
	-- base state.
	if workInProgress.lanes == NoLanes then
		-- Queue is always non-null for classes
		local updateQueue: UpdateQueue<any> = workInProgress.updateQueue
		updateQueue.baseState = memoizedState
	end
end

-- deviation: lazy initialize this to avoid cycles
local classComponentUpdater 
local function initializeClassComponentUpdater()
	local ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new'))	
local requestEventTime = ReactFiberWorkLoop.requestEventTime
	local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
	local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber

	classComponentUpdater = {
		isMounted = isMounted,
		enqueueSetState = function(inst, payload, callback: (() -> (...any))?)
			local fiber = getInstance(inst)
			local eventTime = requestEventTime()
			local lane = requestUpdateLane(fiber)

			local update = createUpdate(eventTime, lane, payload, callback)
			-- update.payload = payload
			if callback ~= nil then
				if __DEV__ then
					warnOnInvalidCallback(callback, "setState")
				end
				-- update.callback = callback
			end

			enqueueUpdate(fiber, update)
			scheduleUpdateOnFiber(fiber, lane, eventTime)

			if __DEV__ then
				if enableDebugTracing then
					if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
						local name = getComponentName(fiber.type) or "Unknown"
						logStateUpdateScheduled(name, lane, payload)
					end
				end
			end

			if enableSchedulingProfiler then
				markStateUpdateScheduled(fiber, lane)
			end
		end,
		enqueueReplaceState = function(inst, payload, callback)
			local fiber = getInstance(inst)
			local eventTime = requestEventTime()
			local lane = requestUpdateLane(fiber)

			local update = createUpdate(eventTime, lane, payload, callback)
			update.tag = ReplaceState
			-- update.payload = payload

			if callback ~= nil then
				if __DEV__ then
					warnOnInvalidCallback(callback, "replaceState")
				end
				-- update.callback = callback
			end

			enqueueUpdate(fiber, update)
			scheduleUpdateOnFiber(fiber, lane, eventTime)

			if __DEV__ then
				if enableDebugTracing then
					if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
						local name = getComponentName(fiber.type) or "Unknown"
						logStateUpdateScheduled(name, lane, payload)
					end
				end
			end

			if enableSchedulingProfiler then
				markStateUpdateScheduled(fiber, lane)
			end
		end,
		enqueueForceUpdate = function(inst, callback)
			local fiber = getInstance(inst)
			local eventTime = requestEventTime()
			local lane = requestUpdateLane(fiber)

			local update = createUpdate(eventTime, lane, nil, callback)
			update.tag = ForceUpdate

			if callback ~= nil then
				if __DEV__ then
					warnOnInvalidCallback(callback, "forceUpdate")
				end
				-- update.callback = callback
			end

			enqueueUpdate(fiber, update)
			scheduleUpdateOnFiber(fiber, lane, eventTime)

			if __DEV__ then
				if enableDebugTracing then
					if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
						local name = getComponentName(fiber.type) or "Unknown"
						logForceUpdateScheduled(name, lane)
					end
				end
			end

			if enableSchedulingProfiler then
				markForceUpdateScheduled(fiber, lane)
			end
		end,
	}
end

local function getClassComponentUpdater()
	if classComponentUpdater == nil then
		initializeClassComponentUpdater()
	end
	return classComponentUpdater
end

function checkShouldComponentUpdate(
	workInProgress,
	ctor,
	oldProps,
	newProps,
	oldState,
	newState,
	nextContext
)
	local instance = workInProgress.stateNode
	if
		instance.shouldComponentUpdate ~= nil
		and type(instance.shouldComponentUpdate) == "function"
	then
		if __DEV__ then
			if
				debugRenderPhaseSideEffectsForStrictMode
				and bit32.band(workInProgress.mode, StrictMode) ~= 0
			then
				disableLogs()
				-- deviation: Pass instance so that the method receives self
				-- Invoke the function an extra time to help detect side-effects.
				local ok, result = xpcall(
					instance.shouldComponentUpdate,
					describeError,
					instance,
					newProps,
					newState,
					nextContext
				)
				-- finally
				reenableLogs()
				if not ok then
					error(result)
				end
			end
		end
		-- deviation: Call with ":" so that the method receives self
		local shouldUpdate =
			instance:shouldComponentUpdate(newProps, newState, nextContext)

		if __DEV__ then
			if shouldUpdate == nil then
				console.error(
[[%s.shouldComponentUpdate(): Returned nil instead of a boolean value. Make sure to return true or false.]]
,
					getComponentName(ctor) or "Component"
				)
			end
		end

		return shouldUpdate
	end

	-- ROBLOX deviation: for us, the isPureReactComponent flag will be visible as a
	-- direct member of the 'ctor', which in reality is the component definition
	if type(ctor) == "table" and ctor.isPureReactComponent then
		return (
			not shallowEqual(oldProps, newProps) or not shallowEqual(oldState, newState)
		)
	end

	return true
end

local function checkClassInstance(workInProgress: Fiber, ctor: any, newProps: any)
	local instance = workInProgress.stateNode
	if __DEV__ then
		local name = getComponentName(ctor) or "Component"
		local renderPresent = instance.render

		if not renderPresent then
			-- ROBLOX deviation: for us, the render function will be visible as a direct
			-- member of the 'ctor', which in reality is the component definition
			if type(ctor.render) == "function" then
				console.error(
[[%s(...): No `render` method found on the returned component instance: did you accidentally return an object from the constructor?]]
,
					name
				)
			else
				console.error(
[[%s(...): No `render` method found on the returned component instance: you may have forgotten to define `render`.]]
,
					name
				)
			end
		end

		if
			instance.getInitialState
			and not instance.getInitialState.isReactClassApproved
			and not instance.state
		then
			console.error(
[[getInitialState was defined on %s, a plain JavaScript class. This is only supported for classes created using React.createClass. Did you mean to define a state property instead?]]

,
				name
			)
		end
		if
			instance.getDefaultProps
			and not instance.getDefaultProps.isReactClassApproved
		then
			console.error(
[[getDefaultProps was defined on %s, a plain JavaScript class. This is only supported for classes created using React.createClass. Use a static property to define defaultProps instead.]]

,
				name
			)
		end
		-- ROBLOX TODO? the original check causes false positives, this adjustment should live up to the intention
		if instance.propTypes and not ctor.propTypes then
			console.error(
[[propTypes was defined as an instance property on %s. Use a static property to define propTypes instead.]]
,
				name
			)
		end
		-- ROBLOX TODO? the original check causes false positives, this adjustment should live up to the intention
		if instance.contextType and not ctor.contextType then
			console.error(
[[contextType was defined as an instance property on %s. Use a static property to define contextType instead.]]
,
				name
			)
		end

		if disableLegacyContext then
			if ctor.childContextTypes then
				console.error(
[[%s uses the legacy childContextTypes API which is no longer supported. Use React.createContext() instead.]]
,
					name
				)
			end
			if ctor.contextTypes then
				console.error(
[[%s uses the legacy contextTypes API which is no longer supported. Use React.createContext() with static contextType instead.]]
,
					name
				)
			end
		else
			-- ROBLOX TODO? the original check causes false positives, this adjustment should live up to the intention
			if instance.contextTypes and not ctor.contextTypes then
				console.error(
[[contextTypes was defined as an instance property on %s. Use a static property to define contextTypes instead.]]
,
					name
				)
			end

			-- ROBLOX deviation: don't access fields on a function
			if
				type(ctor) == "table"
				and ctor.contextType
				and ctor.contextTypes
				and not didWarnAboutContextTypeAndContextTypes[ctor]
			then
				didWarnAboutContextTypeAndContextTypes[ctor] = true
				console.error(
[[%s declares both contextTypes and contextType static properties. The legacy contextTypes property will be ignored.]]
,
					name
				)
			end
		end

		if type(instance.componentShouldUpdate) == "function" then
			console.error(
[[%s has a method called componentShouldUpdate(). Did you mean shouldComponentUpdate()? The name is phrased as a question because the function is expected to return a value.]]


,
				name
			)
		end
		-- ROBLOX deviation: don't access fields on a function
		if
			type(ctor) == "table"
			and ctor.isPureReactComponent
			and instance.shouldComponentUpdate ~= nil
		then
			console.error(
[[%s has a method called shouldComponentUpdate(). shouldComponentUpdate should not be used when extending React.PureComponent. Please extend React.Component if shouldComponentUpdate is used.]]

,
				getComponentName(ctor) or "A pure component"
			)
		end
		if type(instance.componentDidUnmount) == "function" then
			console.error(
[[%s has a method called componentDidUnmount(). But there is no such lifecycle method. Did you mean componentWillUnmount()?]]

,
				name
			)
		end
		if type(instance.componentDidReceiveProps) == "function" then
			console.error(
[[%s has a method called componentDidReceiveProps(). But there is no such lifecycle method. If you meant to update the state in response to changing props, use componentWillReceiveProps(). If you meant to fetch data or run side-effects or mutations after React has updated the UI, use componentDidUpdate().]]



,
				name
			)
		end
		if type(instance.componentWillRecieveProps) == "function" then
			console.error(
[[%s has a method called componentWillRecieveProps(). Did you mean componentWillReceiveProps()?]]
,
				name
			)
		end
		if type(instance.UNSAFE_componentWillRecieveProps) == "function" then
			console.error(
[[%s has a method called UNSAFE_componentWillRecieveProps(). Did you mean UNSAFE_componentWillReceiveProps()?]]
,
				name
			)
		end
		local hasMutatedProps = instance.props ~= newProps
		if instance.props ~= nil and hasMutatedProps then
			console.error(
[[%s(...): When calling super() in `%s`, make sure to pass up the same props that your component's constructor was passed.]]
,
				name,
				name
			)
		end
		if rawget(instance, "defaultProps") then
			console.error(
[[Setting defaultProps as an instance property on %s is not supported and will be ignored. Instead, define defaultProps as a static property on %s.]]
,
				name,
				name
			)
		end

		if
			type(instance.getSnapshotBeforeUpdate) == "function"
			and type(instance.componentDidUpdate) ~= "function"
			and not didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate[ctor]
		then
			didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate[ctor] = true
			console.error(
[[%s: getSnapshotBeforeUpdate() should be used with componentDidUpdate(). This component defines getSnapshotBeforeUpdate() only.]]
,
				getComponentName(ctor)
			)
		end

		-- ROBLOX TODO: get function arity to see if it takes >0 arguments. if it takes 1, assume it's self, and warn
		-- if type(instance.getDerivedStateFromProps) == "function" then
		--   console.error(
		--     "%s: getDerivedStateFromProps() is defined as an instance method " ..
		--       "and will be ignored. Instead, declare it as a static method.",
		--     name
		--   )
		-- end
		-- if type(instance.getDerivedStateFromError) == "function" then
		--   console.error(
		--     "%s: getDerivedStateFromError() is defined as an instance method " ..
		--       "and will be ignored. Instead, declare it as a static method.",
		--     name
		--   )
		-- end
		-- if type(ctor.getSnapshotBeforeUpdate) == "function" then
		--   console.error(
		--     "%s: getSnapshotBeforeUpdate() is defined as a static method " ..
		--       "and will be ignored. Instead, declare it as an instance method.",
		--     name
		--   )
		-- end
		local state = instance.state
		-- deviation: It's not useful for us to try to distinguish an array from an
		-- object in this case
		-- if state and (type(state) ~= "table" or Array.isArray(state)) then
		if state ~= nil and type(state) ~= "table" then
			console.error("%s.state: must be set to an object or nil", name)
		end
		-- ROBLOX deviation: don't access fields on a function
		if
			type(ctor) == "table"
			and type(instance.getChildContext) == "function"
			and type(ctor.childContextTypes) ~= "table"
		then
			console.error(
[[%s.getChildContext(): childContextTypes must be defined in order to use getChildContext().]]
,
				name
			)
		end
	end
end

local function adoptClassInstance(workInProgress: Fiber, instance: any)
	-- ROBLOX performance? it looks like this lazy init is a perf problem in tab switching hot path
	instance.__updater = getClassComponentUpdater()
	workInProgress.stateNode = instance
	-- The instance needs access to the fiber so that it can schedule updates
	setInstance(instance, workInProgress)
	if __DEV__ then
		instance._reactInternalInstance = fakeInternalInstance
	end
end

local function constructClassInstance(workInProgress: Fiber, ctor: any, props: any): any
	local isLegacyContextConsumer = false
	local unmaskedContext = emptyContextObject
	local context = emptyContextObject
	local contextType = ctor.contextType

	if __DEV__ then
		-- deviation: `ctor` is actually a table, in our case; use normal indexing
		if ctor["contextType"] ~= nil then
			-- ROBLOX TODO: Double-check this boolean for accuracy
			local isValid =
				-- Allow nil for conditional declaration
				contextType == nil or (contextType["$$typeof"] == REACT_CONTEXT_TYPE and contextType._context == nil) -- Not a <Context.Consumer>

			if not isValid and not didWarnAboutInvalidateContextType[ctor] then
				didWarnAboutInvalidateContextType[ctor] = true

				local addendum = ""
				if contextType == nil then
					addendum =
[[ However, it is set to nil. This can be caused by a typo or by mixing up named and default imports. This can also happen due to a circular dependency, so try moving the createContext() call to a separate file.]]				

elseif type(contextType) ~= "table" then
					addendum = " However, it is set to a " .. type(contextType) .. "."
				elseif contextType["$$typeof"] == REACT_PROVIDER_TYPE then
					addendum = " Did you accidentally pass the Context.Provider instead?"
				elseif contextType._context ~= nil then
					-- <Context.Consumer>
					addendum = " Did you accidentally pass the Context.Consumer instead?"
				else
					addendum ..= " However, it is set to an object with keys {"
					for key, _ in contextType do
						addendum ..= key .. ", "
					end
					addendum ..= "}."
				end
				console.error(
[[%s defines an invalid contextType. contextType should point to the Context object returned by React.createContext().%s]]
,
					getComponentName(ctor) or "Component",
					addendum
				)
			end
		end
	end

	-- ROBLOX performance: check for nil first to avoid typeof when possible
	if contextType ~= nil and type(contextType) == "table" then
		context = readContext(contextType)
	elseif not disableLegacyContext then
		unmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		local contextTypes = ctor.contextTypes
		isLegacyContextConsumer = contextTypes ~= nil
		context = isLegacyContextConsumer
				and getMaskedContext(workInProgress, unmaskedContext)
			or emptyContextObject
	end

	-- Instantiate twice to help detect side-effects.
	if __DEV__ then
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			-- deviation: ctor will actually refer to a class component, we use the
			-- `__ctor` function that it exposes
			local ok, result = xpcall(ctor.__ctor, describeError, props, context) -- eslint-disable-line no-new
			-- finally
			reenableLogs()

			if not ok then
				error(result)
			end
		end
	end

	-- deviation: ctor will actually refer to a class component, we use the
	-- `__ctor` function that it exposes
	local instance = ctor.__ctor(props, context)
	-- deviation: no need to worry about undefined
	-- local state = (workInProgress.memoizedState =
	--   instance.state ~= nil and instance.state ~= undefined
	--     ? instance.state
	--     : nil)
	workInProgress.memoizedState = instance.state
	local state = workInProgress.memoizedState
	adoptClassInstance(workInProgress, instance)

	if __DEV__ then
		-- ROBLOX deviation: Instead of checking if state is nil, we check if it is our
		-- UninitializedState singleton.
		if
			type(ctor.getDerivedStateFromProps) == "function"
			and state == UninitializedState
		then
			local componentName = getComponentName(ctor) or "Component"
			if not didWarnAboutUninitializedState[componentName] then
				didWarnAboutUninitializedState[componentName] = true
				-- ROBLOX deviation: message adjusted for accuracy with Lua "class" components
				console.error(
[[`%s` uses `getDerivedStateFromProps` but its initial state has not been initialized. This is not recommended. Instead, define the initial state by passing an object to `self:setState` in the `init` method of `%s`. This ensures that `getDerivedStateFromProps` arguments have a consistent shape.]]


,
					componentName,
					-- deviation: no need to worry about undefined
					-- instance.state == nil and 'nil' or 'undefined',
					componentName
				)
			end
		end

		-- If new component APIs are defined, "unsafe" lifecycles won't be called.
		-- Warn about these lifecycles if they are present.
		-- Don't warn about react-lifecycles-compat polyfilled methods though.
		if
			type(ctor.getDerivedStateFromProps) == "function"
			or type(instance.getSnapshotBeforeUpdate) == "function"
		then
			local foundWillMountName 			
local foundWillReceivePropsName 			
local foundWillUpdateName 			
if
				-- ROBLOX FIXME: This won't work! Lua functions can't have properties
				type(instance.componentWillMount) == "function" -- and
				-- instance.componentWillMount.__suppressDeprecationWarning ~= true
			then
				foundWillMountName = "componentWillMount"
			elseif type(instance.UNSAFE_componentWillMount) == "function" then
				foundWillMountName = "UNSAFE_componentWillMount"
			end
			if
				-- ROBLOX FIXME: This won't work! Lua functions can't have properties
				type(instance.componentWillReceiveProps) == "function" -- and
				-- instance.componentWillReceiveProps.__suppressDeprecationWarning ~= true
			then
				foundWillReceivePropsName = "componentWillReceiveProps"
			elseif type(instance.UNSAFE_componentWillReceiveProps) == "function" then
				foundWillReceivePropsName = "UNSAFE_componentWillReceiveProps"
			end
			if
				-- ROBLOX FIXME: This won't work! Lua functions can't have properties
				type(instance.componentWillUpdate) == "function" -- and
				-- instance.componentWillUpdate.__suppressDeprecationWarning ~= true
			then
				foundWillUpdateName = "componentWillUpdate"
			elseif type(instance.UNSAFE_componentWillUpdate) == "function" then
				foundWillUpdateName = "UNSAFE_componentWillUpdate"
			end
			if
				foundWillMountName ~= nil
				or foundWillReceivePropsName ~= nil
				or foundWillUpdateName ~= nil
			then
				local componentName = getComponentName(ctor) or "Component"
				local newApiName
				if type(ctor.getDerivedStateFromProps) == "function" then
					newApiName = "getDerivedStateFromProps()"
				else
					newApiName = "getSnapshotBeforeUpdate()"
				end

				local willMountName
				if foundWillMountName ~= nil then
					willMountName = ("\n  " .. tostring(foundWillMountName))
				else
					willMountName = ""
				end

				local willReceievePropsName
				if foundWillReceivePropsName ~= nil then
					willReceievePropsName = (
						"\n  " .. tostring(foundWillReceivePropsName)
					)
				else
					willReceievePropsName = ""
				end

				local willUpdateName
				if foundWillUpdateName ~= nil then
					willUpdateName = "\n  " .. tostring(foundWillUpdateName)
				else
					willUpdateName = ""
				end

				if not didWarnAboutLegacyLifecyclesAndDerivedState[componentName] then
					didWarnAboutLegacyLifecyclesAndDerivedState[componentName] = true
					console.error(
[[Unsafe legacy lifecycles will not be called for components using new component APIs.

%s uses %s but also contains the following legacy lifecycles:%s%s%s

The above lifecycles should be removed. Learn more about this warning here:
https://reactjs.org/link/unsafe-component-lifecycles]],
						componentName,
						newApiName,
						willMountName,
						willReceievePropsName,
						willUpdateName
					)
				end
			end
		end
	end

	-- Cache unmasked context so we can avoid recreating masked context unless necessary.
	-- ReactFiberContext usually updates this cache but can't for newly-created instances.
	if isLegacyContextConsumer then
		cacheContext(workInProgress, unmaskedContext, context)
	end

	return instance
end

local function callComponentWillMount(workInProgress, instance)
	local oldState = instance.state

	if
		instance.componentWillMount ~= nil
		and type(instance.componentWillMount) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:componentWillMount()
	end
	-- ROBLOX TODO: Should we really run both of these?
	if
		instance.UNSAFE_componentWillMount ~= nil
		and type(instance.UNSAFE_componentWillMount) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:UNSAFE_componentWillMount()
	end

	if oldState ~= instance.state then
		if __DEV__ then
			console.error(
[[%s.componentWillMount(): Assigning directly to this.state is deprecated (except inside a component's constructor). Use setState instead.]],
				getComponentName(workInProgress.type) or "Component"
			)
		end
		getClassComponentUpdater().enqueueReplaceState(instance, instance.state)
	end
end

function callComponentWillReceiveProps(workInProgress, instance, newProps, nextContext)
	local oldState = instance.state
	if
		instance.componentWillReceiveProps ~= nil
		and type(instance.componentWillReceiveProps) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:componentWillReceiveProps(newProps, nextContext)
	end
	if
		instance.UNSAFE_componentWillReceiveProps ~= nil
		and type(instance.UNSAFE_componentWillReceiveProps) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:UNSAFE_componentWillReceiveProps(newProps, nextContext)
	end

	if instance.state ~= oldState then
		if __DEV__ then
			local componentName = getComponentName(workInProgress.type) or "Component"
			if not didWarnAboutStateAssignmentForComponent[componentName] then
				didWarnAboutStateAssignmentForComponent[componentName] = true
				console.error(
[[%s.componentWillReceiveProps(): Assigning directly to this.state is deprecated (except inside a component's constructor). Use setState instead.]]

,
					componentName
				)
			end
		end
		getClassComponentUpdater().enqueueReplaceState(instance, instance.state)
	end
end

-- Invokes the mount life-cycles on a previously never rendered instance.
local function mountClassInstance(
	workInProgress: Fiber,
	ctor: any,
	newProps: any,
	renderLanes: Lanes
)
	if __DEV__ then
		checkClassInstance(workInProgress, ctor, newProps)
	end

	local instance = workInProgress.stateNode
	instance.props = newProps
	instance.state = workInProgress.memoizedState
	-- ROBLOX deviation: Uses __refs instead of refs to avoid conflicts
	-- instance.refs = emptyRefsObject
	instance.__refs = emptyRefsObject

	initializeUpdateQueue(workInProgress)

	-- ROBLOX deviation: don't access field on a function
	local contextType
	if type(ctor) == "table" then
		contextType = ctor.contextType
	end
	-- ROBLOX deviation: nil check first so we don't call typeof() unnecessarily
	if contextType ~= nil and type(contextType) == "table" then
		instance.context = readContext(contextType)
	elseif disableLegacyContext then
		instance.context = emptyContextObject
	else
		local unmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		instance.context = getMaskedContext(workInProgress, unmaskedContext)
	end

	if __DEV__ then
		if instance.state == newProps then
			local componentName = getComponentName(ctor) or "Component"
			if not didWarnAboutDirectlyAssigningPropsToState[componentName] then
				didWarnAboutDirectlyAssigningPropsToState[componentName] = true
				console.error(
[[%s: It is not recommended to assign props directly to state because updates to props won't be reflected in state. In most cases, it is better to use props directly.]]

,
					componentName
				)
			end
		end

		if bit32.band(workInProgress.mode, StrictMode) ~= 0 then
			ReactStrictModeWarnings.recordLegacyContextWarning(workInProgress, instance)
		end

		if warnAboutDeprecatedLifecycles then
			ReactStrictModeWarnings.recordUnsafeLifecycleWarnings(
				workInProgress,
				instance
			)
		end
	end

	processUpdateQueue(workInProgress, newProps, instance, renderLanes)
	instance.state = workInProgress.memoizedState

	-- ROBLOX deviation START: don't access field on a function, cache typeofCtor
	local typeofCtor = type(ctor)
	local getDerivedStateFromProps
	if type(ctor) == "table" then
		getDerivedStateFromProps = ctor.getDerivedStateFromProps
	end
	if
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	then
		applyDerivedStateFromProps(
			workInProgress,
			ctor,
			getDerivedStateFromProps,
			newProps
		)
		instance.state = workInProgress.memoizedState
	end

	-- In order to support react-lifecycles-compat polyfilled components,
	-- Unsafe lifecycles should not be invoked for components using the new APIs.
	-- ROBLOX deviation: don't access fields on a function
	if
		typeofCtor == "table"
		and type(ctor.getDerivedStateFromProps) ~= "function"
		and type(instance.getSnapshotBeforeUpdate) ~= "function"
		and (
			type(instance.UNSAFE_componentWillMount) == "function"
			or type(instance.componentWillMount) == "function"
		)
	then
		callComponentWillMount(workInProgress, instance)
		-- If we had additional state updates during this life-cycle, let's
		-- process them now.
		processUpdateQueue(workInProgress, newProps, instance, renderLanes)
		instance.state = workInProgress.memoizedState
	end

	if type(instance.componentDidMount) == "function" then
		if __DEV__ and enableDoubleInvokingEffects then
			workInProgress.flags =
				bit32.bor(workInProgress.flags, bit32.bor(MountLayoutDev, Update))
		else
			workInProgress.flags = bit32.bor(workInProgress.flags, Update)
		end
	end
end

function resumeMountClassInstance(
	workInProgress: Fiber,
	ctor: any,
	newProps: any,
	renderLanes: Lanes
): boolean
	local instance = workInProgress.stateNode

	local oldProps = workInProgress.memoizedProps
	instance.props = oldProps

	local oldContext = instance.context
	local contextType = ctor.contextType
	local nextContext = emptyContextObject

	-- ROBLOX performance: check for nil first to avoid typeof when possible
	if contextType ~= nil and type(contextType) == "table" then
		nextContext = readContext(contextType)
	elseif not disableLegacyContext then
		local nextLegacyUnmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		nextContext = getMaskedContext(workInProgress, nextLegacyUnmaskedContext)
	end

	local getDerivedStateFromProps = ctor.getDerivedStateFromProps
	local hasNewLifecycles = type(getDerivedStateFromProps) == "function"
		or type(instance.getSnapshotBeforeUpdate) == "function"

	-- Note: During these life-cycles, instance.props/instance.state are what
	-- ever the previously attempted to render - not the "current". However,
	-- during componentDidUpdate we pass the "current" props.

	-- In order to support react-lifecycles-compat polyfilled components,
	-- Unsafe lifecycles should not be invoked for components using the new APIs.
	if
		not hasNewLifecycles
		and (
			type(instance.UNSAFE_componentWillReceiveProps) == "function"
			or type(instance.componentWillReceiveProps) == "function"
		)
	then
		if oldProps ~= newProps or oldContext ~= nextContext then
			callComponentWillReceiveProps(workInProgress, instance, newProps, nextContext)
		end
	end

	resetHasForceUpdateBeforeProcessing()

	local oldState = workInProgress.memoizedState
	instance.state = oldState
	local newState = oldState
	processUpdateQueue(workInProgress, newProps, instance, renderLanes)
	newState = workInProgress.memoizedState
	if
		oldProps == newProps
		and oldState == newState
		and not hasContextChanged()
		and not checkHasForceUpdateAfterProcessing()
	then
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if type(instance.componentDidMount) == "function" then
			if __DEV__ and enableDoubleInvokingEffects then
				workInProgress.flags =
					bit32.bor(workInProgress.flags, MountLayoutDev, Update)
			else
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		return false
	end

	if
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	then
		applyDerivedStateFromProps(
			workInProgress,
			ctor,
			getDerivedStateFromProps,
			newProps
		)
		newState = workInProgress.memoizedState
	end

	local shouldUpdate = checkHasForceUpdateAfterProcessing()
		or checkShouldComponentUpdate(
			workInProgress,
			ctor,
			oldProps,
			newProps,
			oldState,
			newState,
			nextContext
		)

	if shouldUpdate then
		-- In order to support react-lifecycles-compat polyfilled components,
		-- Unsafe lifecycles should not be invoked for components using the new APIs.
		if
			not hasNewLifecycles
			and (
				type(instance.UNSAFE_componentWillMount) == "function"
				or type(instance.componentWillMount) == "function"
			)
		then
			if type(instance.componentWillMount) == "function" then
				instance:componentWillMount()
			end
			if type(instance.UNSAFE_componentWillMount) == "function" then
				instance:UNSAFE_componentWillMount()
			end
		end
		if type(instance.componentDidMount) == "function" then
			if __DEV__ and enableDoubleInvokingEffects then
				workInProgress.flags =
					bit32.bor(workInProgress.flags, MountLayoutDev, Update)
			else
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
	else
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if type(instance.componentDidMount) == "function" then
			if __DEV__ and enableDoubleInvokingEffects then
				workInProgress.flags =
					bit32.bor(workInProgress.flags, MountLayoutDev, Update)
			else
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end

		-- If shouldComponentUpdate returned false, we should still update the
		-- memoized state to indicate that this work can be reused.
		workInProgress.memoizedProps = newProps
		workInProgress.memoizedState = newState
	end

	-- Update the existing instance's state, props, and context pointers even
	-- if shouldComponentUpdate returns false.
	instance.props = newProps
	instance.state = newState
	instance.context = nextContext

	return shouldUpdate
end

-- Invokes the update life-cycles and returns false if it shouldn't rerender.
local function updateClassInstance(
	current: Fiber,
	workInProgress: Fiber,
	ctor: any,
	newProps: any,
	renderLanes: Lanes
): boolean
	local instance = workInProgress.stateNode

	cloneUpdateQueue(current, workInProgress)

	local unresolvedOldProps = workInProgress.memoizedProps
	local oldProps = if workInProgress.type == workInProgress.elementType
		then unresolvedOldProps
		else resolveDefaultProps(workInProgress.type, unresolvedOldProps)
	instance.props = oldProps
	local unresolvedNewProps = workInProgress.pendingProps

	local oldContext = instance.context
	local contextType
	local getDerivedStateFromProps
	-- ROBLOX deviation: don't access fields on a function
	if type(ctor) == "table" then
		contextType = ctor.contextType
		getDerivedStateFromProps = ctor.getDerivedStateFromProps
	end
	local nextContext = emptyContextObject
	if type(contextType) == "table" then
		nextContext = readContext(contextType)
	elseif not disableLegacyContext then
		local nextUnmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		nextContext = getMaskedContext(workInProgress, nextUnmaskedContext)
	end

	local hasNewLifecycles = (
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	)
		or (
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		)

	-- Note: During these life-cycles, instance.props/instance.state are what
	-- ever the previously attempted to render - not the "current". However,
	-- during componentDidUpdate we pass the "current" props.

	-- In order to support react-lifecycles-compat polyfilled components,
	-- Unsafe lifecycles should not be invoked for components using the new APIs.
	if
		not hasNewLifecycles
		and (
			(
				instance.UNSAFE_componentWillReceiveProps ~= nil
				and type(instance.UNSAFE_componentWillReceiveProps) == "function"
			)
			or (
				instance.componentWillReceiveProps ~= nil
				and type(instance.componentWillReceiveProps) == "function"
			)
		)
	then
		if unresolvedOldProps ~= unresolvedNewProps or oldContext ~= nextContext then
			callComponentWillReceiveProps(workInProgress, instance, newProps, nextContext)
		end
	end

	resetHasForceUpdateBeforeProcessing()

	local oldState = workInProgress.memoizedState
	instance.state = oldState
	local newState = instance.state
	processUpdateQueue(workInProgress, newProps, instance, renderLanes)
	newState = workInProgress.memoizedState

	if
		unresolvedOldProps == unresolvedNewProps
		and oldState == newState
		and not hasContextChanged()
		and not checkHasForceUpdateAfterProcessing()
	then
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if
			instance.componentDidUpdate ~= nil
			and type(instance.componentDidUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
			end
		end
		return false
	end

	if
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	then
		applyDerivedStateFromProps(
			workInProgress,
			ctor,
			getDerivedStateFromProps,
			newProps
		)
		newState = workInProgress.memoizedState
	end

	local shouldUpdate = checkHasForceUpdateAfterProcessing()
		or checkShouldComponentUpdate(
			workInProgress,
			ctor,
			oldProps,
			newProps,
			oldState,
			newState,
			nextContext
		)

	if shouldUpdate then
		-- In order to support react-lifecycles-compat polyfilled components,
		-- Unsafe lifecycles should not be invoked for components using the new APIs.
		if
			not hasNewLifecycles
			and (
				(
					instance.UNSAFE_componentWillUpdate ~= nil
					and type(instance.UNSAFE_componentWillUpdate) == "function"
				)
				or (
					instance.componentWillUpdate ~= nil
					and type(instance.componentWillUpdate) == "function"
				)
			)
		then
			if
				instance.componentWillUpdate ~= nil
				and type(instance.componentWillUpdate) == "function"
			then
				-- deviation: Call with ":" so that the method receives self
				instance:componentWillUpdate(newProps, newState, nextContext)
			end
			if
				instance.UNSAFE_componentWillUpdate ~= nil
				and type(instance.UNSAFE_componentWillUpdate) == "function"
			then
				-- deviation: Call with ":" so that the method receives self
				instance:UNSAFE_componentWillUpdate(newProps, newState, nextContext)
			end
		end
		if
			instance.componentDidUpdate ~= nil
			and type(instance.componentDidUpdate) == "function"
		then
			workInProgress.flags = bit32.bor(workInProgress.flags, Update)
		end
		if
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		then
			workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
		end
	else
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if
			instance.componentDidUpdate ~= nil
			and type(instance.componentDidUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
			end
		end

		-- If shouldComponentUpdate returned false, we should still update the
		-- memoized props/state to indicate that this work can be reused.
		workInProgress.memoizedProps = newProps
		workInProgress.memoizedState = newState
	end

	-- Update the existing instance's state, props, and context pointers even
	-- if shouldComponentUpdate returns false.
	instance.props = newProps
	instance.state = newState
	instance.context = nextContext

	return shouldUpdate
end

return {
	adoptClassInstance = adoptClassInstance,
	constructClassInstance = constructClassInstance,
	mountClassInstance = mountClassInstance,
	resumeMountClassInstance = resumeMountClassInstance,
	updateClassInstance = updateClassInstance,

	applyDerivedStateFromProps = applyDerivedStateFromProps,
	-- deviation: this should be safe to export, since it gets assigned only once
	emptyRefsObject = emptyRefsObject,
}

end,
["react-reconciler/ReactFiberCommitWork.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/7f08e908b10a58cda902611378ec053003d371ed/packages/react-reconciler/src/ReactFiberCommitWork.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. tostring(message))
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local __DEV__ = _G.__DEV__ :: boolean
local __YOLO__ = _G.__YOLO__ :: boolean
-- ROBLOX DEVIATION: keep track of the pcall run depth and stop wrapping pcalls after we hit MAX_RUN_DEPTH.
-- ROBLOX note: if this number is raised to 195, the test in RoactRecursiveLayoutPcallDepth will fail
local runDepth = 0
local MAX_RUN_DEPTH = 20

local function isCallable(value)
	if typeof(value) == "function" then
		return true
	end
	if typeof(value) == "table" then
		local mt = getmetatable(value)
		if mt and rawget(mt, "__call") then
			return true
		end
		if value._isMockFunction then
			return true
		end
	end
	return false
end

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Error = LuauPolyfill.Error
local Set = LuauPolyfill.Set
type Array<T> = { [number]: T }

local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type Instance = ReactFiberHostConfig.Instance
type Container = ReactFiberHostConfig.Container
type TextInstance = ReactFiberHostConfig.TextInstance
-- ROBLOX deviation START: we have to inline, because type imports don't work across dynamic requires like HostConfig
-- local type {
--   SuspenseInstance,
--   ChildSet,
--   UpdatePayload,
type UpdatePayload = Array<any>
-- } = require("./ReactFiberHostConfig")
-- ROBLOX deviation END
local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local ReactUpdateQueueModule = require(script.Parent:WaitForChild('ReactUpdateQueue.new'))
type UpdateQueue<T> = ReactInternalTypes.UpdateQueue<T>

-- local ReactFiberHooks = require("./ReactFiberHooks.new.luau")
-- type FunctionComponentUpdateQueue = ReactFiberHooks.FunctionComponentUpdateQueue
-- ROBLOX deviation: inline the typedef here to avoid circular dependency
type Effect = {
	tag: HookFlags,
	create: () -> (() -> ())?,
	destroy: (() -> ())?,
	deps: Array<any>?,
	next: Effect
}
type FunctionComponentUpdateQueue = {
	lastEffect: Effect?
}

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type Wakeable = ReactTypes.Wakeable

type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactFiberOffscreenComponent = require(script.Parent:WaitForChild('ReactFiberOffscreenComponent'))
type OffscreenState = ReactFiberOffscreenComponent.OffscreenState
local ReactHookEffectTags = require(script.Parent:WaitForChild('ReactHookEffectTags'))
type HookFlags = ReactHookEffectTags.HookFlags

-- ROBLOX deviation: import tracing as a top-level export to avoid direct file access
local Schedule_tracing_wrap = require(script.Parent.Parent:WaitForChild('scheduler')).tracing.unstable_wrap
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
local enableProfilerCommitHooks = ReactFeatureFlags.enableProfilerCommitHooks
-- local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
local enableSuspenseCallback = ReactFeatureFlags.enableSuspenseCallback
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local FunctionComponent = ReactWorkTags.FunctionComponent
local ForwardRef = ReactWorkTags.ForwardRef
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local DehydratedFragment = ReactWorkTags.DehydratedFragment
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ScopeComponent = ReactWorkTags.ScopeComponent
local Block = ReactWorkTags.Block
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local ReactErrorUtils = require(script.Parent.Parent:WaitForChild('shared')).ReactErrorUtils
local invokeGuardedCallback = ReactErrorUtils.invokeGuardedCallback
local hasCaughtError = ReactErrorUtils.hasCaughtError
local clearCaughtError = ReactErrorUtils.clearCaughtError
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local NoFlags = ReactFiberFlags.NoFlags
local ContentReset = ReactFiberFlags.ContentReset
local Placement = ReactFiberFlags.Placement
local Snapshot = ReactFiberFlags.Snapshot
local Update = ReactFiberFlags.Update
local Callback = ReactFiberFlags.Callback
local LayoutMask = ReactFiberFlags.LayoutMask
local PassiveMask = ReactFiberFlags.PassiveMask
local Ref = ReactFiberFlags.Ref
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError
local ReactCurrentFiber = require(script.Parent:WaitForChild('ReactCurrentFiber'))--  ROBLOX deviation: this property would be captured as values instead of bound

local currentDebugFiberInDEV = ReactCurrentFiber.current
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local onCommitUnmount = require(script.Parent:WaitForChild('ReactFiberDevToolsHook.new')).onCommitUnmount
local resolveDefaultProps =
	require(script.Parent:WaitForChild('ReactFiberLazyComponent.new')).resolveDefaultProps
local ReactProfilerTimer = require(script.Parent:WaitForChild('ReactProfilerTimer.new'))
local startLayoutEffectTimer = ReactProfilerTimer.startLayoutEffectTimer
local recordPassiveEffectDuration = ReactProfilerTimer.recordPassiveEffectDuration
local recordLayoutEffectDuration = ReactProfilerTimer.recordLayoutEffectDuration
local startPassiveEffectTimer = ReactProfilerTimer.startPassiveEffectTimer
local getCommitTime = ReactProfilerTimer.getCommitTime
local ProfileMode = require(script.Parent:WaitForChild('ReactTypeOfMode')).ProfileMode
local commitUpdateQueue = ReactUpdateQueueModule.commitUpdateQueue
local getPublicInstance = ReactFiberHostConfig.getPublicInstance
local supportsMutation = ReactFiberHostConfig.supportsMutation
local supportsPersistence = ReactFiberHostConfig.supportsPersistence
local supportsHydration = ReactFiberHostConfig.supportsHydration
local commitMount = ReactFiberHostConfig.commitMount
local commitUpdate = ReactFiberHostConfig.commitUpdate
local resetTextContent = ReactFiberHostConfig.resetTextContent
local commitTextUpdate = ReactFiberHostConfig.commitTextUpdate
local appendChild = ReactFiberHostConfig.appendChild
local appendChildToContainer = ReactFiberHostConfig.appendChildToContainer
local insertBefore = ReactFiberHostConfig.insertBefore
local insertInContainerBefore = ReactFiberHostConfig.insertInContainerBefore
local removeChild = ReactFiberHostConfig.removeChild
local removeChildFromContainer = ReactFiberHostConfig.removeChildFromContainer
-- local clearSuspenseBoundary = ReactFiberHostConfig.clearSuspenseBoundary
-- local clearSuspenseBoundaryFromContainer = ReactFiberHostConfig.clearSuspenseBoundaryFromContainer
-- local replaceContainerChildren = ReactFiberHostConfig.replaceContainerChildren
-- local createContainerChildSet = ReactFiberHostConfig.createContainerChildSet
local hideInstance = ReactFiberHostConfig.hideInstance
local hideTextInstance = ReactFiberHostConfig.hideTextInstance
local unhideInstance = ReactFiberHostConfig.unhideInstance
local unhideTextInstance = ReactFiberHostConfig.unhideTextInstance
-- local unmountFundamentalComponent = ReactFiberHostConfig.unmountFundamentalComponent
-- local updateFundamentalComponent = ReactFiberHostConfig.updateFundamentalComponent
-- local commitHydratedContainer = ReactFiberHostConfig.commitHydratedContainer
local commitHydratedSuspenseInstance = ReactFiberHostConfig.commitHydratedSuspenseInstance
local clearContainer = ReactFiberHostConfig.clearContainer
-- local prepareScopeUpdate = ReactFiberHostConfig.prepareScopeUpdate

-- ROBLOX deviation: Lazy init to avoid circular dependencies
local ReactFiberWorkLoop

local function resolveRetryWakeable(boundaryFiber: Fiber, wakeable: Wakeable): ()
	if not ReactFiberWorkLoop then
		ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new')):: any
	end
	ReactFiberWorkLoop.resolveRetryWakeable(boundaryFiber, wakeable)
end

local function markCommitTimeOfFallback(): ()
	if not ReactFiberWorkLoop then
		ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new')):: any
	end
	ReactFiberWorkLoop.markCommitTimeOfFallback()
end

-- deviation: stub to allow dependency injection that breaks circular dependency
local function schedulePassiveEffectCallback(): ()
	console.warn(
		"ReactFiberCommitWork: schedulePassiveEffectCallback causes a dependency cycle\n"
			.. debug.traceback()
	)
end

-- deviation: stub to allow dependency injection that breaks circular dependency
local function captureCommitPhaseError(
	rootFiber: Fiber,
	sourceFiber: Fiber | nil,
	error_: any?
): ()
	console.warn(
		"ReactFiberCommitWork: captureCommitPhaseError causes a dependency cycle"
	)
	error(error_)
end

local NoHookEffect = ReactHookEffectTags.NoFlags
local HookHasEffect = ReactHookEffectTags.HasEffect
local HookLayout = ReactHookEffectTags.Layout
local HookPassive = ReactHookEffectTags.Passive

-- ROBLOX deviation: lazy init to break cyclic dependency
local didWarnAboutReassigningPropsRef
local didWarnAboutReassigningProps = function()
	if not didWarnAboutReassigningPropsRef then
		didWarnAboutReassigningPropsRef =
			require(script.Parent:WaitForChild('ReactFiberBeginWork.new')).didWarnAboutReassigningProps
	end
	return didWarnAboutReassigningPropsRef
end

-- deviation: Common types
type Set<T> = { [T]: boolean }

-- deviation: pre-declare functions when necessary
local isHostParent, getHostSibling, insertOrAppendPlacementNode, insertOrAppendPlacementNodeIntoContainer, commitLayoutEffectsForHostRoot, commitLayoutEffectsForHostComponent, commitLayoutEffectsForClassComponent, unmountHostComponents, commitNestedUnmounts, commitUnmount

-- Used to avoid traversing the return path to find the nearest Profiler ancestor during commit.
local nearestProfilerOnStack: Fiber | nil 
-- deviation: Not possible to return `undefined` in lua
-- local didWarnAboutUndefinedSnapshotBeforeUpdate: Set<any>? = nil
-- if __DEV__ then
--   didWarnAboutUndefinedSnapshotBeforeUpdate = {}
-- end

-- local PossiblyWeakSet = typeof WeakSet == 'function' ? WeakSet : Set


local function callComponentWillUnmountWithTimer(current, instance)
	instance.props = current.memoizedProps
	instance.state = current.memoizedState
	if
		enableProfilerTimer
		and enableProfilerCommitHooks
		and bit32.band(current.mode, ProfileMode) ~= 0
	then
		-- ROBLOX performance? we could hoist start...Timer() out and eliminate the anon function, but then the timer would incldue the pcall overhead
		local ok, exception = xpcall(function()
			startLayoutEffectTimer()
			-- ROBLOX deviation: Call with ":" so that the method receives self
			instance:componentWillUnmount()
		end, describeError)

		recordLayoutEffectDuration(current)

		if not ok then
			error(exception)
		end
	else
		-- ROBLOX deviation: Call with ":" so that the method receives self
		instance:componentWillUnmount()
	end
end

-- Capture errors so they don't interrupt unmounting.
function safelyCallComponentWillUnmount(
	current: Fiber,
	instance: any,
	nearestMountedAncestor
): ()
	-- ROBLOX performance: eliminate the __DEV__ and invokeGuardedCallback, like React 18 has done
	local ok, error_ =
		xpcall(callComponentWillUnmountWithTimer, describeError, current, instance)

	if not ok then
		captureCommitPhaseError(current, nearestMountedAncestor, error_)
	end
end

local function safelyDetachRef(current: Fiber, nearestMountedAncestor: Fiber): ()
	local ref = current.ref
	if ref ~= nil then
		if typeof(ref) == "function" then
			-- ROBLOX performance: eliminate the __DEV__ and invokeGuardedCallback, like React 18 has done
			local ok, error_ = xpcall(ref, describeError)
			if not ok then
				captureCommitPhaseError(current, nearestMountedAncestor, error_)
			end
		else
			-- ROBLOX FIXME Luau: next line gets Expected type table, got 'RefObject | {| [string]: any, _stringRef: string? |}' instead
			ref.current = nil
		end
	end
end

local function safelyCallDestroy(
	current: Fiber,
	nearestMountedAncestor: Fiber | nil,
	destroy: () -> ()
): ()
	-- ROBLOX performance: eliminate the __DEV__ and invokeGuardedCallback, like React 18 has done
	local ok, error_ = xpcall(destroy, describeError)
	if not ok then
		captureCommitPhaseError(current, nearestMountedAncestor, error_)
	end
end

local function commitBeforeMutationLifeCycles(
	current: Fiber | nil,
	finishedWork: Fiber
): ()
	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		return
	elseif finishedWork.tag == ClassComponent then
		if bit32.band(finishedWork.flags, Snapshot) ~= 0 then
			if current ~= nil then
				local prevProps = (current :: Fiber).memoizedProps
				local prevState = (current :: Fiber).memoizedState
				local instance = finishedWork.stateNode
				-- We could update instance props and state here,
				-- but instead we rely on them being set during last render.
				-- TODO: revisit this when we implement resuming.
				if __DEV__ then
					if
						finishedWork.type == finishedWork.elementType
						and not didWarnAboutReassigningProps
					then
						if instance.props ~= finishedWork.memoizedProps then
							console.error(
[[Expected %s props to match memoized props before getSnapshotBeforeUpdate. This might either be because of a bug in React, or because a component reassigns its own `this.props`. Please file an issue.]]



,
								getComponentName(finishedWork.type) or "instance"
							)
						end
						if instance.state ~= finishedWork.memoizedState then
							console.error(
[[Expected %s state to match memoized state before getSnapshotBeforeUpdate. This might either be because of a bug in React, or because a component reassigns its own `this.state`. Please file an issue.]]



,
								getComponentName(finishedWork.type) or "instance"
							)
						end
					end
				end
				-- deviation: Call with ':' instead of '.' so that self is available
				local snapshot = instance:getSnapshotBeforeUpdate(
					finishedWork.elementType == finishedWork.type and prevProps
						or resolveDefaultProps(finishedWork.type, prevProps),
					prevState
				)
				if __DEV__ then
					-- ROBLOX deviation: not possible to return `undefined` in Lua
					-- local didWarnSet = ((didWarnAboutUndefinedSnapshotBeforeUpdate: any): Set<mixed>)
					-- if snapshot == nil and not didWarnSet[finishedWork.type] then
					--   didWarnSet[finishedWork.type] = true
					--   console.error(
					--     "%s.getSnapshotBeforeUpdate(): A snapshot value (or nil) " ..
					--       "must be returned. You have returned undefined.",
					--     getComponentName(finishedWork.type)
					--   )
					-- end
				end
				instance.__reactInternalSnapshotBeforeUpdate = snapshot
			end
		end
		return
	elseif finishedWork.tag == HostRoot then
		if supportsMutation then
			if bit32.band(finishedWork.flags, Snapshot) ~= 0 then
				local root = finishedWork.stateNode
				clearContainer(root.containerInfo)
			end
		end
		return
	elseif
		finishedWork.tag == HostComponent
		or finishedWork.tag == HostText
		or finishedWork.tag == HostPortal
		or finishedWork.tag == IncompleteClassComponent
	then
		-- Nothing to do for these component types
		return
	end
	invariant(
		false,
[[This unit of work tag should not have side-effects. This error is likely caused by a bug in React. Please file an issue.]]	

)
end

local function commitHookEffectListUnmount(
	flags: HookFlags,
	finishedWork: Fiber,
	nearestMountedAncestor: Fiber?
)
	local updateQueue: FunctionComponentUpdateQueue | nil = finishedWork.updateQueue
	local lastEffect
	if updateQueue ~= nil then
		lastEffect = (updateQueue :: FunctionComponentUpdateQueue).lastEffect
	end

	if lastEffect ~= nil then
		local firstEffect = lastEffect.next
		local effect = firstEffect
		repeat
			if bit32.band(effect.tag, flags) == flags then
				-- Unmount
				local destroy = effect.destroy
				effect.destroy = nil
				if destroy ~= nil then
					safelyCallDestroy(finishedWork, nearestMountedAncestor, destroy)
				end
			end
			effect = effect.next
		until effect == firstEffect
	end
end

local function commitHookEffectListMount(flags: HookFlags, finishedWork: Fiber)
	local updateQueue: FunctionComponentUpdateQueue | nil =
		finishedWork.updateQueue :: any
	local lastEffect = if updateQueue ~= nil then updateQueue.lastEffect else nil
	if lastEffect ~= nil then
		local firstEffect = lastEffect.next
		local effect = firstEffect
		repeat
			if bit32.band(effect.tag, flags) == flags then
				-- Mount
				local create = effect.create
				effect.destroy = create()

				if __DEV__ then
					local destroy = effect.destroy
					if destroy ~= nil and typeof(destroy) ~= "function" then
						local addendum
						if destroy == nil then
							addendum = [[ You returned nil. If your effect does not require clean up, return nil (or nothing).]]						

elseif typeof(destroy.andThen) == "function" then
							addendum =
[=[


It looks like you wrote useEffect(Promise.new(function() --[[...]] end) or returned a Promise. Instead, write the async function inside your effect and call it immediately:

useEffect(function()
  function fetchData()
    -- You can await here
    local response = MyAPI.getData(someId):await()
    -- ...
  end
  fetchData()
end, {someId}) -- Or {} if effect doesn't need props or state

Learn more about data fetching with Hooks: https://reactjs.org/link/hooks-data-fetching]=]						else
							addendum = " You returned: " .. destroy
						end
						console.error(
[[An effect function must not return anything besides a function, which is used for clean-up.%s]],
							addendum
						)
					end
				end
			end
			effect = effect.next
		until effect == firstEffect
	end
end

function commitProfilerPassiveEffect(finishedRoot: FiberRoot, finishedWork: Fiber): ()
	if enableProfilerTimer and enableProfilerCommitHooks then
		if finishedWork.tag == Profiler then
			local passiveEffectDuration = finishedWork.stateNode.passiveEffectDuration
			local id, onPostCommit =
				finishedWork.memoizedProps.id, finishedWork.memoizedProps.onPostCommit

			-- This value will still reflect the previous commit phase.
			-- It does not get reset until the start of the next commit phase.
			local commitTime = getCommitTime()

			if typeof(onPostCommit) == "function" then
				if enableSchedulerTracing then
					onPostCommit(
						id,
						if finishedWork.alternate == nil then "mount" else "update",
						passiveEffectDuration,
						commitTime,
						finishedRoot.memoizedInteractions
					)
				else
					onPostCommit(
						id,
						if finishedWork.alternate == nil then "mount" else "update",
						passiveEffectDuration,
						commitTime
					)
				end
			end
		end
	end
end

local function recursivelyCommitLayoutEffects(
	finishedWork: Fiber,
	finishedRoot: FiberRoot,
	-- ROBLOX deviation: pass in these functions to avoid dependency cycle
	_captureCommitPhaseError: (
		sourceFiber: Fiber,
		nearestMountedAncestor: Fiber?,
		error: any
	) -> (),
	_schedulePassiveEffectCallback: () -> ()
)
	if _captureCommitPhaseError ~= nil then
		captureCommitPhaseError = _captureCommitPhaseError
	end
	if _schedulePassiveEffectCallback ~= nil then
		schedulePassiveEffectCallback = _schedulePassiveEffectCallback
	end
	local flags = finishedWork.flags
	local tag = finishedWork.tag
	if tag == Profiler then
		local prevProfilerOnStack 		if enableProfilerTimer and enableProfilerCommitHooks then
			prevProfilerOnStack = nearestProfilerOnStack
			nearestProfilerOnStack = finishedWork
		end

		local child = finishedWork.child
		while child ~= nil do
			local primarySubtreeFlags = bit32.band(finishedWork.subtreeFlags, LayoutMask)
			if primarySubtreeFlags ~= NoFlags then
				if __DEV__ then
					local prevCurrentFiberInDEV = currentDebugFiberInDEV
					setCurrentDebugFiberInDEV(child)
					invokeGuardedCallback(
						nil,
						recursivelyCommitLayoutEffects,
						nil,
						child,
						finishedRoot,
						-- ROBLOX deviation: pass in these functions to avoid dependency cycle
						captureCommitPhaseError,
						schedulePassiveEffectCallback
					)
					if hasCaughtError() then
						local error_ = clearCaughtError()
						captureCommitPhaseError(child, finishedWork, error_)
					end
					if prevCurrentFiberInDEV ~= nil then
						setCurrentDebugFiberInDEV(prevCurrentFiberInDEV)
					else
						resetCurrentDebugFiberInDEV()
					end
				else
					local ok, error_ = xpcall(
						-- ROBLOX deviation: pass in captureCommitPhaseError function to avoid dependency cycle
						recursivelyCommitLayoutEffects,
						describeError,
						child,
						finishedRoot,
						captureCommitPhaseError,
						schedulePassiveEffectCallback
					)
					if not ok then
						captureCommitPhaseError(child, finishedWork, error_)
					end
				end
			end
			child = child.sibling
		end

		local primaryFlags = bit32.band(flags, bit32.bor(Update, Callback))
		if primaryFlags ~= NoFlags then
			if enableProfilerTimer then
				if __DEV__ then
					local prevCurrentFiberInDEV = currentDebugFiberInDEV
					setCurrentDebugFiberInDEV(finishedWork)
					invokeGuardedCallback(
						nil,
						commitLayoutEffectsForProfiler,
						nil,
						finishedWork,
						finishedRoot
					)
					if hasCaughtError() then
						local error_ = clearCaughtError()
						captureCommitPhaseError(
							finishedWork,
							finishedWork.return_,
							error_
						)
					end
					if prevCurrentFiberInDEV ~= nil then
						setCurrentDebugFiberInDEV(prevCurrentFiberInDEV)
					else
						resetCurrentDebugFiberInDEV()
					end
				else
					-- ROBLOX TODO? pass in captureCommitPhaseError?
					local ok, error_ = xpcall(
						commitLayoutEffectsForProfiler,
						describeError,
						finishedWork,
						finishedRoot
					)
					if not ok then
						captureCommitPhaseError(
							finishedWork,
							finishedWork.return_,
							error_
						)
					end
				end
			end
		end

		if enableProfilerTimer and enableProfilerCommitHooks then
			-- Propagate layout effect durations to the next nearest Profiler ancestor.
			-- Do not reset these values until the next render so DevTools has a chance to read them first.
			if prevProfilerOnStack ~= nil then
				prevProfilerOnStack.stateNode.effectDuration += finishedWork.stateNode.effectDuration
			end

			nearestProfilerOnStack = prevProfilerOnStack
		end
	-- elseif tag == Offscreen then
	-- TODO: Fast path to invoke all nested layout effects when Offscren goes from hidden to visible.
	else
		local child = finishedWork.child
		while child ~= nil do
			local primarySubtreeFlags = bit32.band(finishedWork.subtreeFlags, LayoutMask)
			if primarySubtreeFlags ~= NoFlags then
				if __DEV__ then
					local prevCurrentFiberInDEV = ReactCurrentFiber.current
					setCurrentDebugFiberInDEV(child)
					--[[
              ROBLOX DEVIATION: In DEV, After MAX_RUN_DEPTH pcalls, do not wrap recursive calls in pcall. Otherwise,
              we hit the stack limit and get a stack overflow error.
            ]]
					if runDepth < MAX_RUN_DEPTH then
						runDepth += 1
						invokeGuardedCallback(
							nil,
							recursivelyCommitLayoutEffects,
							nil,
							child,
							finishedRoot,
							-- ROBLOX deviation: pass in this function to avoid dependency cycle
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)
						runDepth -= 1

						if hasCaughtError() then
							local error_ = clearCaughtError()
							captureCommitPhaseError(child, finishedWork, error_)
						end
					else
						recursivelyCommitLayoutEffects(
							child,
							finishedRoot,
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)
					end
					if prevCurrentFiberInDEV ~= nil then
						setCurrentDebugFiberInDEV(prevCurrentFiberInDEV)
					else
						resetCurrentDebugFiberInDEV()
					end
				else
					-- ROBLOX deviation: YOLO flag for disabling pcall
					local ok, error_
					if not __YOLO__ and runDepth < MAX_RUN_DEPTH then
						--[[
              ROBLOX DEVIATION: After MAX_RUN_DEPTH pcalls, do not wrap recursive calls in pcall. Otherwise, we hit the
              stack limit and get a stack overflow error.
            ]]
						runDepth += 1

						ok, error_ = xpcall(
							-- ROBLOX deviation: pass in this function to avoid dependency cycle
							recursivelyCommitLayoutEffects,
							describeError,
							child,
							finishedRoot,
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)

						runDepth -= 1
					else
						ok = true
						recursivelyCommitLayoutEffects(
							child,
							finishedRoot,
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)
					end

					if not ok then
						captureCommitPhaseError(child, finishedWork, error_)
					end
				end
			end
			child = child.sibling
		end

		local primaryFlags = bit32.band(flags, bit32.bor(Update, Callback))
		if primaryFlags ~= NoFlags then
			if
				tag == FunctionComponent
				or tag == ForwardRef
				or tag == SimpleMemoComponent
				or tag == Block
			then
				if
					enableProfilerTimer
					and enableProfilerCommitHooks
					and bit32.band(finishedWork.mode, ProfileMode) ~= 0
				then
					-- ROBLOX try
					local ok, error_ = xpcall(function()
						startLayoutEffectTimer()
						commitHookEffectListMount(
							bit32.bor(HookLayout, HookHasEffect),
							finishedWork
						)
					end, describeError)
					-- ROBLOX finally
					recordLayoutEffectDuration(finishedWork)
					if not ok then
						error(error_)
					end
				else
					commitHookEffectListMount(
						bit32.bor(HookLayout, HookHasEffect),
						finishedWork
					)
				end

				if bit32.band(finishedWork.subtreeFlags, PassiveMask) ~= NoFlags then
					schedulePassiveEffectCallback()
				end
			elseif tag == ClassComponent then
				-- NOTE: Layout effect durations are measured within this function.
				commitLayoutEffectsForClassComponent(finishedWork)
			elseif tag == HostRoot then
				commitLayoutEffectsForHostRoot(finishedWork)
			elseif tag == HostComponent then
				commitLayoutEffectsForHostComponent(finishedWork)
			elseif tag == SuspenseComponent then
				commitSuspenseHydrationCallbacks(finishedRoot, finishedWork)
			elseif
				tag == FundamentalComponent
				or tag == HostPortal
				or tag == HostText
				or tag == IncompleteClassComponent
				or tag == LegacyHiddenComponent
				or tag == OffscreenComponent
				or tag == ScopeComponent
				or tag == SuspenseListComponent
			then
			-- break
			else
				invariant(
					false,
[[This unit of work tag should not have side-effects. This error is likely caused by a bug in React. Please file an issue.]]				)
			end
		end

		-- ROBLOX performance: avoid cmp on always-false value
		-- if enableScopeAPI then
		--   -- TODO: This is a temporary solution that allowed us to transition away from React Flare on www.
		--   if bit32.band(flags, Ref) ~= 0 and tag ~= ScopeComponent then
		--     commitAttachRef(finishedWork)
		--   end
		-- else
		if bit32.band(flags, Ref) ~= 0 then
			commitAttachRef(finishedWork)
		end
		-- end
	end
end

function commitLayoutEffectsForProfiler(finishedWork: Fiber, finishedRoot: FiberRoot)
	if enableProfilerTimer then
		local flags = finishedWork.flags
		local current = finishedWork.alternate

		local onCommit, onRender =
			finishedWork.memoizedProps.onCommit, finishedWork.memoizedProps.onRender
		local effectDuration = finishedWork.stateNode.effectDuration

		local commitTime = getCommitTime()

		local OnRenderFlag = Update
		local OnCommitFlag = Callback

		if
			bit32.band(flags, OnRenderFlag) ~= NoFlags
			-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
			and isCallable(onRender)
		then
			if enableSchedulerTracing then
				onRender(
					finishedWork.memoizedProps.id,
					if current == nil then "mount" else "update",
					finishedWork.actualDuration,
					finishedWork.treeBaseDuration,
					finishedWork.actualStartTime,
					commitTime,
					finishedRoot.memoizedInteractions
				)
			else
				onRender(
					finishedWork.memoizedProps.id,
					if current == nil then "mount" else "update",
					finishedWork.actualDuration,
					finishedWork.treeBaseDuration,
					finishedWork.actualStartTime,
					commitTime
				)
			end
		end

		if enableProfilerCommitHooks then
			if
				bit32.band(flags, OnCommitFlag) ~= NoFlags
				-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
				and isCallable(onCommit)
			then
				if enableSchedulerTracing then
					onCommit(
						finishedWork.memoizedProps.id,
						if current == nil then "mount" else "update",
						effectDuration,
						commitTime,
						finishedRoot.memoizedInteractions
					)
				else
					onCommit(
						finishedWork.memoizedProps.id,
						if current == nil then "mount" else "update",
						effectDuration,
						commitTime
					)
				end
			end
		end
	end
end

function commitLayoutEffectsForClassComponent(finishedWork: Fiber)
	local instance = finishedWork.stateNode
	local current = finishedWork.alternate
	if bit32.band(finishedWork.flags, Update) ~= 0 then
		if current == nil then
			-- We could update instance props and state here,
			-- but instead we rely on them being set during last render.
			-- TODO: revisit this when we implement resuming.
			if __DEV__ then
				if
					finishedWork.type == finishedWork.elementType
					and not didWarnAboutReassigningProps
				then
					if instance.props ~= finishedWork.memoizedProps then
						console.error(
[[Expected %s props to match memoized props before componentDidMount. This might either be because of a bug in React, or because a component reassigns its own `this.props`. Please file an issue.]],
							getComponentName(finishedWork.type) or "instance"
						)
					end
					if instance.state ~= finishedWork.memoizedState then
						console.error(
[[Expected %s state to match memoized state before componentDidMount. This might either be because of a bug in React, or because a component reassigns its own `this.state`. Please file an issue.]],
							getComponentName(finishedWork.type) or "instance"
						)
					end
				end
			end
			if
				enableProfilerTimer
				and enableProfilerCommitHooks
				and bit32.band(finishedWork.mode, ProfileMode) ~= 0
			then
				local ok, result = xpcall(function()
					startLayoutEffectTimer()
					-- ROBLOX deviation: Call with ":" so that the method receives self
					instance:componentDidMount()
				end, describeError)
				-- finally
				recordLayoutEffectDuration(finishedWork)
				if not ok then
					error(result)
				end
			else
				-- ROBLOX deviation: Call with ":" so that the method receives self
				instance:componentDidMount()
			end
		else
			local prevProps = finishedWork.elementType == finishedWork.type
					and current.memoizedProps
				or resolveDefaultProps(finishedWork.type, current.memoizedProps)
			local prevState = current.memoizedState
			-- We could update instance props and state here,
			-- but instead we rely on them being set during last render.
			-- TODO: revisit this when we implement resuming.
			if __DEV__ then
				if
					finishedWork.type == finishedWork.elementType
					and not didWarnAboutReassigningProps
				then
					if instance.props ~= finishedWork.memoizedProps then
						console.error(
[[Expected %s props to match memoized props before componentDidUpdate. This might either be because of a bug in React, or because a component reassigns its own `this.props`. Please file an issue.]]



,
							getComponentName(finishedWork.type) or "instance"
						)
					end
					if instance.state ~= finishedWork.memoizedState then
						console.error(
[[Expected %s state to match memoized state before componentDidUpdate. This might either be because of a bug in React, or because a component reassigns its own `this.state`. Please file an issue.]]



,
							getComponentName(finishedWork.type) or "instance"
						)
					end
				end
			end
			if
				enableProfilerTimer
				and enableProfilerCommitHooks
				and bit32.band(finishedWork.mode, ProfileMode) ~= 0
			then
				local ok, result = xpcall(function()
					startLayoutEffectTimer()
					-- deviation: Call with ":" so that the method receives self
					instance:componentDidUpdate(
						prevProps,
						prevState,
						instance.__reactInternalSnapshotBeforeUpdate
					)
				end, describeError)
				-- finally
				recordLayoutEffectDuration(finishedWork)
				if not ok then
					error(result)
				end
			else
				-- deviation: Call with ":" so that the method receives self
				instance:componentDidUpdate(
					prevProps,
					prevState,
					instance.__reactInternalSnapshotBeforeUpdate
				)
			end
		end
	end

	-- TODO: I think this is now always non-null by the time it reaches the
	-- commit phase. Consider removing the type check.
	local updateQueue: UpdateQueue<any> | nil = finishedWork.updateQueue
	if updateQueue ~= nil then
		if __DEV__ then
			if
				finishedWork.type == finishedWork.elementType
				and not didWarnAboutReassigningProps
			then
				if instance.props ~= finishedWork.memoizedProps then
					console.error(
[[Expected %s props to match memoized props before processing the update queue. This might either be because of a bug in React, or because a component reassigns its own `this.props`. Please file an issue.]]



,
						getComponentName(finishedWork.type) or "instance"
					)
				end
				if instance.state ~= finishedWork.memoizedState then
					console.error(
[[Expected %s state to match memoized state before processing the update queue. This might either be because of a bug in React, or because a component reassigns its own `this.state`. Please file an issue.]]



,
						getComponentName(finishedWork.type) or "instance"
					)
				end
			end
		end
		-- We could update instance props and state here,
		-- but instead we rely on them being set during last render.
		-- TODO: revisit this when we implement resuming.
		commitUpdateQueue(finishedWork, updateQueue, instance)
	end
end

function commitLayoutEffectsForHostRoot(finishedWork: Fiber)
	-- TODO: I think this is now always non-null by the time it reaches the
	-- commit phase. Consider removing the type check.
	local updateQueue: UpdateQueue<any> | nil = finishedWork.updateQueue
	if updateQueue ~= nil then
		local instance 		
if finishedWork.child ~= nil then
			-- ROBLOX TODO: localize child, workaround Luau type refinement shortcomings
			local child = finishedWork.child
			if child.tag == HostComponent then
				instance = getPublicInstance(child.stateNode)
			elseif child.tag == ClassComponent then
				instance = child.stateNode
			end
		end
		commitUpdateQueue(finishedWork, updateQueue, instance)
	end
end

function commitLayoutEffectsForHostComponent(finishedWork: Fiber)
	local instance: Instance = finishedWork.stateNode
	local current = finishedWork.alternate

	-- Renderers may schedule work to be done after host components are mounted
	-- (eg DOM renderer may schedule auto-focus for inputs and form controls).
	-- These effects should only be committed when components are first mounted,
	-- aka when there is no current/alternate.
	if current == nil and bit32.band(finishedWork.flags, Update) ~= 0 then
		local type = finishedWork.type
		local props = finishedWork.memoizedProps
		commitMount(instance, type, props, finishedWork)
	end
end

local function hideOrUnhideAllChildren(finishedWork, isHidden)
	if supportsMutation then
		-- We only have the top Fiber that was inserted but we need to recurse down its
		-- children to find all the terminal nodes.
		local node: Fiber = finishedWork
		while true do
			if node.tag == HostComponent then
				local instance = node.stateNode
				if isHidden then
					hideInstance(instance)
				else
					unhideInstance(node.stateNode, node.memoizedProps)
				end
			elseif node.tag == HostText then
				local instance = node.stateNode
				if isHidden then
					hideTextInstance(instance)
				else
					unhideTextInstance(instance, node.memoizedProps)
				end
			elseif
				(node.tag == OffscreenComponent or node.tag == LegacyHiddenComponent)
				and (node.memoizedState :: OffscreenState) ~= nil
				and node ~= finishedWork
			then
			-- Found a nested Offscreen component that is hidden. Don't search
			-- any deeper. This tree should remain hidden.
			elseif node.child ~= nil then
				-- ROBLOX FIXME: type casts to silence analyze, Luau doesn't understand nil check
				(node.child :: Fiber).return_ = node
				node = node.child :: Fiber
				continue
			end
			if node == finishedWork then
				return
			end
			while node.sibling == nil do
				if node.return_ == nil or node.return_ == finishedWork then
					return
				end
				node = node.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
			end
			-- ROBLOX FIXME: cast to any to silence analyze
			(node.sibling :: Fiber).return_ = node.return_
			-- ROBLOX FIXME: recast to silence analyze while Luau doesn't understand nil check
			node = node.sibling :: Fiber
		end
	end
end

function commitAttachRef(finishedWork: Fiber)
	local ref = finishedWork.ref
	if ref ~= nil then
		local instance = finishedWork.stateNode
		local instanceToUse
		if finishedWork.tag == HostComponent then
			instanceToUse = getPublicInstance(instance)
		else
			instanceToUse = instance
		end
		-- Moved outside to ensure DCE works with this flag
		-- ROBLOX performance: avoid cmp on always-false value
		-- if enableScopeAPI and finishedWork.tag == ScopeComponent then
		--   instanceToUse = instance
		-- end
		if typeof(ref) == "function" then
			ref(instanceToUse)
		else
			if __DEV__ then
				-- ROBLOX FIXME: We won't be able to recognize a ref object by checking
				-- for the existence of the `current` key, since it won't be initialized
				-- at this point. We might consider using a symbol to uniquely identify
				-- ref objects, or relying more heavily on Luau types
				-- if not ref.current then
				if typeof(ref) ~= "table" then
					console.error(
[[Unexpected ref object provided for %s. Use either a ref-setter function or React.createRef().]]
,
						getComponentName(finishedWork.type) or "instance"
					)
					return
				end
			end

			ref.current = instanceToUse
		end
	end
end

function commitDetachRef(current: Fiber)
	local currentRef = current.ref
	if currentRef ~= nil then
		if typeof(currentRef) == "function" then
			currentRef(nil)
		else
			currentRef.current = nil
		end
	end
end

-- User-originating errors (lifecycles and refs) should not interrupt
-- deletion, so don't local them throw. Host-originating errors should
-- interrupt deletion, so it's okay
function commitUnmount(
	finishedRoot: FiberRoot,
	current: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
): ()
	onCommitUnmount(current)

	if
		current.tag == FunctionComponent
		or current.tag == ForwardRef
		or current.tag == MemoComponent
		or current.tag == SimpleMemoComponent
		or current.tag == Block
	then
		local updateQueue: FunctionComponentUpdateQueue | nil = current.updateQueue
		if updateQueue ~= nil then
			local lastEffect = (updateQueue :: FunctionComponentUpdateQueue).lastEffect
			if lastEffect ~= nil then
				local firstEffect = lastEffect.next

				local effect = firstEffect
				repeat
					if effect.destroy ~= nil then
						if bit32.band(effect.tag, HookLayout) ~= NoHookEffect then
							if
								enableProfilerTimer
								and enableProfilerCommitHooks
								and bit32.band(current.mode, ProfileMode) ~= 0
							then
								startLayoutEffectTimer()
								safelyCallDestroy(
									current,
									nearestMountedAncestor,
									effect.destroy
								)
								recordLayoutEffectDuration(current)
							else
								safelyCallDestroy(
									current,
									nearestMountedAncestor,
									effect.destroy
								)
							end
						end
					end
					effect = effect.next
				until effect == firstEffect
			end
		end
		return
	elseif current.tag == ClassComponent then
		safelyDetachRef(current, nearestMountedAncestor)
		local instance = current.stateNode
		if typeof(instance.componentWillUnmount) == "function" then
			safelyCallComponentWillUnmount(current, instance, nearestMountedAncestor)
		end
		return
	elseif current.tag == HostComponent then
		safelyDetachRef(current, nearestMountedAncestor)
		return
	elseif current.tag == HostPortal then
		-- TODO: this is recursive.
		-- We are also not using this parent because
		-- the portal will get pushed immediately.
		if supportsMutation then
			unmountHostComponents(
				finishedRoot,
				current,
				nearestMountedAncestor,
				renderPriorityLevel
			)
		elseif supportsPersistence then
			unimplemented("emptyPortalContainer")
			-- emptyPortalContainer(current)
		end
		return
		-- elseif current.tag == FundamentalComponent then
		--   unimplemented("commitUnmount - FundamentalComponent")
		-- if enableFundamentalAPI then
		--   local fundamentalInstance = current.stateNode
		--   if fundamentalInstance ~= nil then
		--     unmountFundamentalComponent(fundamentalInstance)
		--     current.stateNode = nil
		--   end
		-- end
		-- return
		-- elseif current.tag == DehydratedFragment then
		--   unimplemented("commitUnmount - DehydratedFragment")
		-- if enableSuspenseCallback then
		--   local hydrationCallbacks = finishedRoot.hydrationCallbacks
		--   if hydrationCallbacks ~= nil then
		--     local onDeleted = hydrationCallbacks.onDeleted
		--     if onDeleted then
		--       onDeleted((current.stateNode: SuspenseInstance))
		--     end
		--   end
		-- end
		-- return
		-- elseif current.tag == ScopeComponent then
		--   if enableScopeAPI then
		--     safelyDetachRef(current, nearestMountedAncestor)
		--   end
		--   return
	end
end

function commitNestedUnmounts(
	finishedRoot: FiberRoot,
	root: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
)
	-- While we're inside a removed host node we don't want to call
	-- removeChild on the inner nodes because they're removed by the top
	-- call anyway. We also want to call componentWillUnmount on all
	-- composites before this host node is removed from the tree. Therefore
	-- we do an inner loop while we're still inside the host node.
	local node: Fiber = root
	while true do
		commitUnmount(finishedRoot, node, nearestMountedAncestor, renderPriorityLevel)
		-- Visit children because they may contain more composite or host nodes.
		-- Skip portals because commitUnmount() currently visits them recursively.
		if
			node.child ~= nil
			-- If we use mutation we drill down into portals using commitUnmount above.
			-- If we don't use mutation we drill down into portals here instead.
			and (not supportsMutation or node.tag ~= HostPortal)
		then
			(node.child :: Fiber).return_ = node
			node = node.child :: Fiber
			continue
		end
		if node == root then
			return
		end
		while node.sibling == nil do
			if node.return_ == nil or node.return_ == root then
				return
			end
			node = node.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
		end
		(node.sibling :: Fiber).return_ = node.return_
		node = node.sibling :: Fiber
	end
end

local function detachFiberMutation(fiber: Fiber)
	-- Cut off the return pointer to disconnect it from the tree.
	-- This enables us to detect and warn against state updates on an unmounted component.
	-- It also prevents events from bubbling from within disconnected components.
	--
	-- Ideally, we should also clear the child pointer of the parent alternate to local this
	-- get GC:ed but we don't know which for sure which parent is the current
	-- one so we'll settle for GC:ing the subtree of this child.
	-- This child itself will be GC:ed when the parent updates the next time.
	--
	-- Note that we can't clear child or sibling pointers yet.
	-- They're needed for passive effects and for findDOMNode.
	-- We defer those fields, and all other cleanup, to the passive phase (see detachFiberAfterEffects).
	local alternate = fiber.alternate
	if alternate ~= nil then
		alternate.return_ = nil
		fiber.alternate = nil
	end
	fiber.return_ = nil
end

-- function emptyPortalContainer(current: Fiber)
--   if !supportsPersistence)
--     return
--   end

--   local portal: {
--     containerInfo: Container,
--     pendingChildren: ChildSet,
--     ...
--   } = current.stateNode
--   local {containerInfo} = portal
--   local emptyChildSet = createContainerChildSet(containerInfo)
--   replaceContainerChildren(containerInfo, emptyChildSet)
-- end

-- function commitContainer(finishedWork: Fiber)
--   if !supportsPersistence)
--     return
--   end

--   switch (finishedWork.tag)
--     case ClassComponent:
--     case HostComponent:
--     case HostText:
--     case FundamentalComponent: {
--       return
--     end
--     case HostRoot:
--     case HostPortal: {
--       local portalOrRoot: {
--         containerInfo: Container,
--         pendingChildren: ChildSet,
--         ...
--       } = finishedWork.stateNode
--       local {containerInfo, pendingChildren} = portalOrRoot
--       replaceContainerChildren(containerInfo, pendingChildren)
--       return
--     end
--   end
--   invariant(
--     false,
--     'This unit of work tag should not have side-effects. This error is ' +
--       'likely caused by a bug in React. Please file an issue.',
--   )
-- end

local function getHostParentFiber(fiber: Fiber): Fiber
	local parent = fiber.return_
	while parent ~= nil do
		if isHostParent(parent) then
			return parent
		end
		parent = parent.return_
	end
	-- ROBLOX deviation START: use React 18 approach, which Luau understands better than invariant
	error(
		Error.new(
[[Expected to find a host parent. This error is likely caused by a bug in React. Please file an issue.]]		

)
	)
	-- ROBLOX deviation END
end

function isHostParent(fiber: Fiber): boolean
	return fiber.tag == HostComponent or fiber.tag == HostRoot or fiber.tag == HostPortal
end

function getHostSibling(fiber: Fiber): Instance?
	-- We're going to search forward into the tree until we find a sibling host
	-- node. Unfortunately, if multiple insertions are done in a row we have to
	-- search past them. This leads to exponential search for the next sibling.
	-- TODO: Find a more efficient way to do this.
	local node: Fiber = fiber
	while true do
		-- ROBLOX deviation: we can't `continue` with labels in luau, so some variable
		-- juggling is used instead
		local continueOuter = false
		-- If we didn't find anything, let's try the next sibling.
		while node.sibling == nil do
			if node.return_ == nil or isHostParent(node.return_) then
				-- If we pop out of the root or hit the parent the fiber we are the
				-- last sibling.
				return nil
			end
			node = node.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
		end
		(node.sibling :: Fiber).return_ = node.return_ :: Fiber
		node = node.sibling :: Fiber
		while
			node.tag ~= HostComponent
			and node.tag ~= HostText
			and node.tag ~= DehydratedFragment
		do
			-- If it is not host node and, we might have a host node inside it.
			-- Try to search down until we find one.
			if bit32.band(node.flags, Placement) ~= 0 then
				-- If we don't have a child, try the siblings instead.
				continueOuter = true
				break
			end
			-- If we don't have a child, try the siblings instead.
			-- We also skip portals because they are not part of this host tree.
			if node.child == nil or node.tag == HostPortal then
				continueOuter = true
				break
			else
				(node.child :: Fiber).return_ = node
				node = node.child :: Fiber
			end
		end
		if continueOuter then
			continue
		end
		-- Check if this host node is stable or about to be placed.
		if bit32.band(node.flags, Placement) == 0 then
			-- Found it!
			return node.stateNode
		end
	end
end

local function commitPlacement(finishedWork: Fiber)
	if not supportsMutation then
		return
	end

	-- Recursively insert all host nodes into the parent.
	local parentFiber = getHostParentFiber(finishedWork)

	-- Note: these two variables *must* always be updated together.
	local parent
	local isContainer
	local parentStateNode = parentFiber.stateNode
	if parentFiber.tag == HostComponent then
		parent = parentStateNode
		isContainer = false
	elseif parentFiber.tag == HostRoot then
		parent = parentStateNode.containerInfo
		isContainer = true
	elseif parentFiber.tag == HostPortal then
		parent = parentStateNode.containerInfo
		isContainer = true
	-- elseif parentFiber.tag == FundamentalComponent then
	--   if enableFundamentalAPI then
	--     parent = parentStateNode.instance
	--     isContainer = false
	--   end
	else
		-- eslint-disable-next-line-no-fallthrough
		invariant(
			false,
[[Invalid host parent fiber. This error is likely caused by a bug in React. Please file an issue.]]		

)
	end
	if bit32.band(parentFiber.flags, ContentReset) ~= 0 then
		-- Reset the text content of the parent before doing any insertions
		resetTextContent(parent)
		-- Clear ContentReset from the effect tag
		parentFiber.flags = bit32.band(parentFiber.flags, bit32.bnot(ContentReset))
	end

	local before = getHostSibling(finishedWork)
	-- We only have the top Fiber that was inserted but we need to recurse down its
	-- children to find all the terminal nodes.
	if isContainer then
		insertOrAppendPlacementNodeIntoContainer(finishedWork, before, parent)
	else
		insertOrAppendPlacementNode(finishedWork, before, parent)
	end
end

function insertOrAppendPlacementNodeIntoContainer(
	node: Fiber,
	before: Instance?,
	parent: Container
)
	local tag = node.tag
	local isHost = tag == HostComponent or tag == HostText
	-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
	if isHost then -- or (enableFundamentalAPI and tag == FundamentalComponent) then
		local stateNode = node.stateNode
		if before then
			insertInContainerBefore(parent, stateNode, before)
		else
			appendChildToContainer(parent, stateNode)
		end
	elseif tag == HostPortal then
	-- If the insertion itself is a portal, then we don't want to traverse
	-- down its children. Instead, we'll get insertions from each child in
	-- the portal directly.
	else
		local child = node.child
		if child ~= nil then
			insertOrAppendPlacementNodeIntoContainer(child, before, parent)
			local sibling = child.sibling
			while sibling ~= nil do
				insertOrAppendPlacementNodeIntoContainer(sibling, before, parent)
				sibling = sibling.sibling
			end
		end
	end
end

function insertOrAppendPlacementNode(node: Fiber, before: Instance?, parent: Instance): ()
	local tag = node.tag
	local isHost = tag == HostComponent or tag == HostText
	-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
	if isHost then -- or (enableFundamentalAPI and tag == FundamentalComponent) then
		local stateNode = node.stateNode
		if before then
			insertBefore(parent, stateNode, before)
		else
			appendChild(parent, stateNode)
		end
	elseif tag == HostPortal then
	-- If the insertion itself is a portal, then we don't want to traverse
	-- down its children. Instead, we'll get insertions from each child in
	-- the portal directly.
	else
		local child = node.child
		if child ~= nil then
			insertOrAppendPlacementNode(child, before, parent)
			local sibling = child.sibling
			while sibling ~= nil do
				insertOrAppendPlacementNode(sibling, before, parent)
				sibling = sibling.sibling
			end
		end
	end
end

function unmountHostComponents(
	finishedRoot: FiberRoot,
	current: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
): ()
	-- We only have the top Fiber that was deleted but we need to recurse down its
	-- children to find all the terminal nodes.
	local node: Fiber = current

	-- Each iteration, currentParent is populated with node's host parent if not
	-- currentParentIsValid.
	local currentParentIsValid = false

	-- Note: these two variables *must* always be updated together.
	local currentParent
	local currentParentIsContainer

	while true do
		if not currentParentIsValid then
			-- ROBLOX FIXME Luau: Luau doesn't understand the nil guard at the top of the loop
			local parent = node.return_ :: Fiber
			while true do
				-- ROBLOX deviation START: use React 18 approach so Luau understands control flow better
				if parent == nil then
					error(
						Error.new(
[[Expected to find a host parent. This error is likely caused by a bug in React. Please file an issue.]]						

)
					)
				end
				-- ROBLOX deviation END
				local parentStateNode = parent.stateNode
				if parent.tag == HostComponent then
					currentParent = parentStateNode
					currentParentIsContainer = false
					break
				elseif parent.tag == HostRoot then
					currentParent = parentStateNode.containerInfo
					currentParentIsContainer = true
					break
				elseif parent.tag == HostPortal then
					currentParent = parentStateNode.containerInfo
					currentParentIsContainer = true
					break
					-- ROBLOX performance: eliminate always-false compare for Roblox in hot path
					-- elseif parent.tag == FundamentalComponent then
					--   if enableFundamentalAPI then
					--     currentParent = parentStateNode.instance
					--     currentParentIsContainer = false
					--   end
				end
				-- ROBLOX FIXME Luau: Luau doesn't understand the nil guard at the top of the loop
				parent = parent.return_ :: Fiber
			end
			currentParentIsValid = true
		end

		if node.tag == HostComponent or node.tag == HostText then
			commitNestedUnmounts(
				finishedRoot,
				node,
				nearestMountedAncestor,
				renderPriorityLevel
			)
			-- After all the children have unmounted, it is now safe to remove the
			-- node from the tree.
			if currentParentIsContainer then
				-- removeChildFromContainer(
				--   ((currentParent: any): Container),
				--   (fundamentalNode: Instance),
				-- )
				-- ROBLOX FIXME: type coercion
				removeChildFromContainer(currentParent, node.stateNode)
			else
				-- removeChild(
				--   ((currentParent: any): Instance),
				--   (fundamentalNode: Instance),
				-- )
				-- ROBLOX FIXME: type coercion
				removeChild(currentParent, node.stateNode)
			end
		-- Don't visit children because we already visited them.
		-- ROBLOX performance? fundamentalAPI  and suspenseServerRender are always false for Roblox. avoid unnecessary cmp in hot path
		-- elseif enableFundamentalAPI and node.tag == FundamentalComponent then
		--   local fundamentalNode = node.stateNode.instance
		--   commitNestedUnmounts(
		--     finishedRoot,
		--     node,
		--     nearestMountedAncestor,
		--     renderPriorityLevel
		--   )
		--   -- After all the children have unmounted, it is now safe to remove the
		--   -- node from the tree.
		--   if currentParentIsContainer then
		--     -- removeChildFromContainer(
		--     --   ((currentParent: any): Container),
		--     --   (fundamentalNode: Instance),
		--     -- )
		--     -- ROBLOX FIXME: type coercion
		--     removeChildFromContainer(currentParent, fundamentalNode)
		--   else
		--     -- removeChild(
		--     --   ((currentParent: any): Instance),
		--     --   (fundamentalNode: Instance),
		--     -- )
		--     -- ROBLOX FIXME: type coercion
		--     removeChild(currentParent, fundamentalNode)
		--   end
		-- elseif
		--   enableSuspenseServerRenderer and
		--   node.tag == DehydratedFragment
		-- then
		--   unimplemented("clearSuspenseBoundary")
		--   -- if enableSuspenseCallback then
		--   --   local hydrationCallbacks = finishedRoot.hydrationCallbacks
		--   --   if hydrationCallbacks ~= nil)
		--   --     local onDeleted = hydrationCallbacks.onDeleted
		--   --     if onDeleted)
		--   --       onDeleted((node.stateNode: SuspenseInstance))
		--   --     end
		--   --   end
		--   -- end

		--   -- -- Delete the dehydrated suspense boundary and all of its content.
		--   -- if currentParentIsContainer)
		--   --   clearSuspenseBoundaryFromContainer(
		--   --     ((currentParent: any): Container),
		--   --     (node.stateNode: SuspenseInstance),
		--   --   )
		--   -- } else {
		--   --   clearSuspenseBoundary(
		--   --     ((currentParent: any): Instance),
		--   --     (node.stateNode: SuspenseInstance),
		--   --   )
		--   -- end
		elseif node.tag == HostPortal then
			if node.child ~= nil then
				-- When we go into a portal, it becomes the parent to remove from.
				-- We will reassign it back when we pop the portal on the way up.
				currentParent = node.stateNode.containerInfo
				currentParentIsContainer = true
				-- Visit children because portals might contain host components.
				node.child.return_ = node
				node = node.child
				continue
			end
		else
			commitUnmount(finishedRoot, node, nearestMountedAncestor, renderPriorityLevel)
			-- Visit children because we may find more host components below.
			if node.child ~= nil then
				node.child.return_ = node
				node = node.child
				continue
			end
		end
		if node == current then
			return
		end
		while node.sibling == nil do
			if node.return_ == nil or node.return_ == current then
				return
			end
			-- ROBLOX FIXME Luau: Luau doesn't understand narrowing by guard above
			node = node.return_ :: Fiber
			if node.tag == HostPortal then
				-- When we go out of the portal, we need to restore the parent.
				-- Since we don't keep a stack of them, we will search for it.
				currentParentIsValid = false
			end
		end
		-- ROBLOX TODO: flowtype makes an impossible leap here, contribute this annotation upstream
		(node.sibling :: Fiber).return_ = node.return_
		node = node.sibling :: Fiber
	end
end

local function commitDeletion(
	finishedRoot: FiberRoot,
	current: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
): ()
	-- ROBLOX performance? supportsMutation always true, eliminate cmp on hot path
	-- if supportsMutation then
	-- Recursively delete all host nodes from the parent.
	-- Detach refs and call componentWillUnmount() on the whole subtree.
	unmountHostComponents(
		finishedRoot,
		current,
		nearestMountedAncestor,
		renderPriorityLevel
	)
	-- else
	--   -- Detach refs and call componentWillUnmount() on the whole subtree.
	--   commitNestedUnmounts(
	--     finishedRoot,
	--     current,
	--     nearestMountedAncestor,
	--     renderPriorityLevel
	--   )
	-- end
	local alternate = current.alternate
	detachFiberMutation(current)
	if alternate ~= nil then
		detachFiberMutation(alternate)
	end
end

local function commitWork(current: Fiber | nil, finishedWork: Fiber)
	-- if not supportsMutation then
	--   unimplemented("commitWork: non-mutation branch")
	-- switch (finishedWork.tag)
	--   case FunctionComponent:
	--   case ForwardRef:
	--   case MemoComponent:
	--   case SimpleMemoComponent:
	--   case Block: {
	--     -- Layout effects are destroyed during the mutation phase so that all
	--     -- destroy functions for all fibers are called before any create functions.
	--     -- This prevents sibling component effects from interfering with each other,
	--     -- e.g. a destroy function in one component should never override a ref set
	--     -- by a create function in another component during the same commit.
	--     if
	--       enableProfilerTimer and
	--       enableProfilerCommitHooks and
	--       finishedWork.mode & ProfileMode
	--     )
	--       try {
	--         startLayoutEffectTimer()
	--         commitHookEffectListUnmount(
	--           HookLayout | HookHasEffect,
	--           finishedWork,
	--           finishedWork.return_,
	--         )
	--       } finally {
	--         recordLayoutEffectDuration(finishedWork)
	--       end
	--     } else {
	--       commitHookEffectListUnmount(
	--         HookLayout | HookHasEffect,
	--         finishedWork,
	--         finishedWork.return_,
	--       )
	--     end
	--     return
	--   end
	--   case Profiler: {
	--     return
	--   end
	--   case SuspenseComponent: {
	--     commitSuspenseComponent(finishedWork)
	--     attachSuspenseRetryListeners(finishedWork)
	--     return
	--   end
	--   case SuspenseListComponent: {
	--     attachSuspenseRetryListeners(finishedWork)
	--     return
	--   end
	--   case HostRoot: {
	--     if supportsHydration)
	--       local root: FiberRoot = finishedWork.stateNode
	--       if root.hydrate)
	--         -- We've just hydrated. No need to hydrate again.
	--         root.hydrate = false
	--         commitHydratedContainer(root.containerInfo)
	--       end
	--     end
	--     break
	--   end
	--   case OffscreenComponent:
	--   case LegacyHiddenComponent: {
	--     return
	--   end
	-- end

	-- commitContainer(finishedWork)
	-- return
	-- end

	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == MemoComponent
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		-- Layout effects are destroyed during the mutation phase so that all
		-- destroy functions for all fibers are called before any create functions.
		-- This prevents sibling component effects from interfering with each other,
		-- e.g. a destroy function in one component should never override a ref set
		-- by a create function in another component during the same commit.
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(finishedWork.mode, ProfileMode) ~= 0
		then
			-- ROBLOX try
			local ok, result = xpcall(function()
				startLayoutEffectTimer()
				commitHookEffectListUnmount(
					bit32.bor(HookLayout, HookHasEffect),
					finishedWork,
					finishedWork.return_
				)
			end, describeError)
			-- ROBLOX finally
			recordLayoutEffectDuration(finishedWork)
			if not ok then
				error(result)
			end
		else
			commitHookEffectListUnmount(
				bit32.bor(HookLayout, HookHasEffect),
				finishedWork,
				finishedWork.return_
			)
		end
		return
	elseif finishedWork.tag == ClassComponent then
		return
	elseif finishedWork.tag == HostComponent then
		local instance: Instance = finishedWork.stateNode
		if instance ~= nil then
			-- Commit the work prepared earlier.
			local newProps = finishedWork.memoizedProps
			-- For hydration we reuse the update path but we treat the oldProps
			-- as the newProps. The updatePayload will contain the real change in
			-- this case.
			local oldProps
			if current then
				oldProps = current.memoizedProps
			else
				oldProps = newProps
			end
			local type = finishedWork.type
			-- TODO: Type the updateQueue to be specific to host components.
			local updatePayload: nil | UpdatePayload = finishedWork.updateQueue :: any
			finishedWork.updateQueue = nil
			if updatePayload ~= nil then
				commitUpdate(
					instance,
					updatePayload,
					type,
					oldProps,
					newProps,
					finishedWork
				)
			end
		end
		return
	elseif finishedWork.tag == HostText then
		invariant(
			finishedWork.stateNode ~= nil,
[[This should have a text node initialized. This error is likely caused by a bug in React. Please file an issue.]]		

)
		local textInstance: TextInstance = finishedWork.stateNode
		local newText: string = finishedWork.memoizedProps
		-- For hydration we reuse the update path but we treat the oldProps
		-- as the newProps. The updatePayload will contain the real change in
		-- this case.
		local oldText: string
		if current ~= nil then
			oldText = (current :: Fiber).memoizedProps
			oldText = newText
		end
		commitTextUpdate(textInstance, oldText, newText)
		return
	elseif finishedWork.tag == HostRoot then
		if supportsHydration then
			local root: FiberRoot = finishedWork.stateNode
			if root.hydrate then
				-- We've just hydrated. No need to hydrate again.
				root.hydrate = false
				unimplemented("commitWork: HostRoot: commitHydratedContainer")
				-- commitHydratedContainer(root.containerInfo)
			end
		end
		return
	elseif finishedWork.tag == Profiler then
		return
	elseif finishedWork.tag == SuspenseComponent then
		commitSuspenseComponent(finishedWork)
		attachSuspenseRetryListeners(finishedWork)
		return
	elseif finishedWork.tag == SuspenseListComponent then
		unimplemented("commitWork: SuspenseListComponent")
	-- attachSuspenseRetryListeners(finishedWork)
	-- return
	elseif finishedWork.tag == IncompleteClassComponent then
		return
	-- elseif finishedWork.tag == FundamentalComponent then
	--   unimplemented("commitWork: FundamentalComponent")
	-- if enableFundamentalAPI)
	--   local fundamentalInstance = finishedWork.stateNode
	--   updateFundamentalComponent(fundamentalInstance)
	--   return
	-- end
	-- break
	-- elseif finishedWork.tag == ScopeComponent then
	--   unimplemented("commitWork: ScopeComponent")
	-- if enableScopeAPI)
	--   local scopeInstance = finishedWork.stateNode
	--   prepareScopeUpdate(scopeInstance, finishedWork)
	--   return
	-- end
	-- break
	elseif
		finishedWork.tag == OffscreenComponent
		or finishedWork.tag == LegacyHiddenComponent
	then
		local newState: OffscreenState | nil = finishedWork.memoizedState
		local isHidden = newState ~= nil
		hideOrUnhideAllChildren(finishedWork, isHidden)
		return
	end
	invariant(
		false,
[[This unit of work tag should not have side-effects. This error is likely caused by a bug in React. Please file an issue.]]	

)
end

function commitSuspenseComponent(finishedWork: Fiber)
	local newState: SuspenseState | nil = finishedWork.memoizedState

	if newState ~= nil then
		markCommitTimeOfFallback()

		if supportsMutation then
			-- Hide the Offscreen component that contains the primary children. TODO:
			-- Ideally, this effect would have been scheduled on the Offscreen fiber
			-- itself. That's how unhiding works: the Offscreen component schedules an
			-- effect on itself. However, in this case, the component didn't complete,
			-- so the fiber was never added to the effect list in the normal path. We
			-- could have appended it to the effect list in the Suspense component's
			-- second pass, but doing it this way is less complicated. This would be
			-- simpler if we got rid of the effect list and traversed the tree, like
			-- we're planning to do.
			local primaryChildParent: Fiber = finishedWork.child :: any
			hideOrUnhideAllChildren(primaryChildParent, true)
		end
	end

	if enableSuspenseCallback and newState ~= nil then
		local suspenseCallback = finishedWork.memoizedProps.suspenseCallback
		if typeof(suspenseCallback) == "function" then
			local wakeables: Set<Wakeable> | nil = finishedWork.updateQueue :: any
			if wakeables ~= nil then
				suspenseCallback(table.clone(wakeables))
			end
		elseif __DEV__ then
			if suspenseCallback ~= nil then
				console.error(
					"Unexpected type for suspenseCallback: %s",
					tostring(suspenseCallback)
				)
			end
		end
	end
end

function commitSuspenseHydrationCallbacks(finishedRoot: FiberRoot, finishedWork: Fiber)
	if not supportsHydration then
		return
	end
	local newState: SuspenseState | nil = finishedWork.memoizedState
	if newState == nil then
		local current = finishedWork.alternate
		if current ~= nil then
			local prevState: SuspenseState | nil = current.memoizedState
			if prevState ~= nil then
				local suspenseInstance = prevState.dehydrated
				if suspenseInstance ~= nil then
					commitHydratedSuspenseInstance(suspenseInstance)
					if enableSuspenseCallback then
						local hydrationCallbacks = finishedRoot.hydrationCallbacks
						if hydrationCallbacks ~= nil then
							local onHydrated = hydrationCallbacks.onHydrated
							if onHydrated then
								onHydrated(suspenseInstance)
							end
						end
					end
				end
			end
		end
	end
end

function attachSuspenseRetryListeners(finishedWork: Fiber)
	-- If this boundary just timed out, then it will have a set of wakeables.
	-- For each wakeable, attach a listener so that when it resolves, React
	-- attempts to re-render the boundary in the primary (pre-timeout) state.
	local wakeables: Set<Wakeable> | nil = finishedWork.updateQueue :: any
	if wakeables ~= nil then
		finishedWork.updateQueue = nil
		local retryCache = finishedWork.stateNode
		if retryCache == nil then
			finishedWork.stateNode = Set.new()
			retryCache = finishedWork.stateNode
		end
		for wakeable, _ in wakeables :: Set<Wakeable> do
			-- Memoize using the boundary fiber to prevent redundant listeners.
			local retry = function()
				return resolveRetryWakeable(finishedWork, wakeable)
			end

			if not retryCache:has(wakeable) then
				if enableSchedulerTracing then
					if wakeable.__reactDoNotTraceInteractions ~= true then
						retry = Schedule_tracing_wrap(retry)
					end
				end
				retryCache:add(wakeable)
				wakeable:andThen(function()
					return retry()
				end, function()
					return retry()
				end)
			end
		end
	end
end

-- This function detects when a Suspense boundary goes from visible to hidden.
-- It returns false if the boundary is already hidden.
-- TODO: Use an effect tag.
function isSuspenseBoundaryBeingHidden(current: Fiber | nil, finishedWork: Fiber): boolean
	if current ~= nil then
		-- ROBLOX TODO: remove typechecks when narrowing works better
		local oldState: SuspenseState | nil = (current :: Fiber).memoizedState
		if oldState == nil or (oldState :: SuspenseState).dehydrated ~= nil then
			local newState: SuspenseState | nil = finishedWork.memoizedState
			return newState ~= nil and (newState :: SuspenseState).dehydrated == nil
		end
	end
	return false
end

function commitResetTextContent(current: Fiber): ()
	if not supportsMutation then
		return
	end
	resetTextContent(current.stateNode)
end

local function commitPassiveUnmount(finishedWork: Fiber): ()
	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(finishedWork.mode, ProfileMode) ~= 0
		then
			startPassiveEffectTimer()
			commitHookEffectListUnmount(
				bit32.bor(HookPassive, HookHasEffect),
				finishedWork,
				finishedWork.return_
			)
			recordPassiveEffectDuration(finishedWork)
		else
			commitHookEffectListUnmount(
				bit32.bor(HookPassive, HookHasEffect),
				finishedWork,
				finishedWork.return_
			)
		end
	end
end

local function commitPassiveUnmountInsideDeletedTree(
	current: Fiber,
	nearestMountedAncestor: Fiber | nil
): ()
	if
		current.tag == FunctionComponent
		or current.tag == ForwardRef
		or current.tag == SimpleMemoComponent
		or current.tag == Block
	then
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(current.mode, ProfileMode) ~= 0
		then
			startPassiveEffectTimer()
			commitHookEffectListUnmount(HookPassive, current, nearestMountedAncestor)
			recordPassiveEffectDuration(current)
		else
			commitHookEffectListUnmount(HookPassive, current, nearestMountedAncestor)
		end
	end
end

local function commitPassiveMount(finishedRoot: FiberRoot, finishedWork: Fiber): ()
	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(finishedWork.mode, ProfileMode) ~= 0
		then
			startPassiveEffectTimer()
			-- ROBLOX try
			local ok, error_ = xpcall(
				commitHookEffectListMount,
				describeError,
				bit32.bor(HookPassive, HookHasEffect),
				finishedWork
			)
			-- ROBLOX finally
			recordPassiveEffectDuration(finishedWork)
			if not ok then
				error(error_)
			end
		else
			commitHookEffectListMount(bit32.bor(HookPassive, HookHasEffect), finishedWork)
		end
	elseif finishedWork.tag == Profiler then
		commitProfilerPassiveEffect(finishedRoot, finishedWork)
	end
end

function invokeLayoutEffectMountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListMount,
				nil,
				bit32.bor(HookLayout, HookHasEffect),
				fiber
			)
			if hasCaughtError() then
				local mountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, mountError)
			end
			return
		end
	elseif fiber.tag == ClassComponent then
		local instance = fiber.stateNode
		invokeGuardedCallback(nil, instance.componentDidMount, instance)
		if hasCaughtError() then
			local mountError = clearCaughtError()
			captureCommitPhaseError(fiber, fiber.return_, mountError)
		end
		return
	end
end

function invokePassiveEffectMountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListMount,
				nil,
				bit32.bor(HookPassive, HookHasEffect),
				fiber
			)
			if hasCaughtError() then
				local mountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, mountError)
			end
			return
		end
	end
end

function invokeLayoutEffectUnmountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListUnmount,
				nil,
				bit32.bor(HookLayout, HookHasEffect),
				fiber,
				fiber.return_
			)
			if hasCaughtError() then
				local unmountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, unmountError)
			end
			return
		end
	elseif fiber.tag == ClassComponent then
		local instance = fiber.stateNode
		if typeof(instance.componentWillUnmount) == "function" then
			safelyCallComponentWillUnmount(fiber, instance, fiber.return_)
		end
		return
	end
end

function invokePassiveEffectUnmountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListUnmount,
				nil,
				bit32.bor(HookPassive, HookHasEffect),
				fiber,
				fiber.return_
			)
			if hasCaughtError() then
				local unmountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, unmountError)
			end
			return
		end
	end
end

return {
	safelyCallDestroy = safelyCallDestroy,

	commitBeforeMutationLifeCycles = commitBeforeMutationLifeCycles,
	commitResetTextContent = commitResetTextContent,
	commitPlacement = commitPlacement,
	commitDeletion = commitDeletion,
	commitWork = commitWork,
	commitAttachRef = commitAttachRef,
	commitDetachRef = commitDetachRef,
	commitPassiveUnmount = commitPassiveUnmount,
	commitPassiveUnmountInsideDeletedTree = commitPassiveUnmountInsideDeletedTree,
	commitPassiveMount = commitPassiveMount,
	invokeLayoutEffectMountInDEV = invokeLayoutEffectMountInDEV,
	invokeLayoutEffectUnmountInDEV = invokeLayoutEffectUnmountInDEV,
	invokePassiveEffectMountInDEV = invokePassiveEffectMountInDEV,
	invokePassiveEffectUnmountInDEV = invokePassiveEffectUnmountInDEV,
	isSuspenseBoundaryBeingHidden = isSuspenseBoundaryBeingHidden,
	recursivelyCommitLayoutEffects = recursivelyCommitLayoutEffects,
}

end,
["react-reconciler/ReactFiberCompleteWork.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/87c023b1c1b00d6776b7031f6e105913ead355da/packages/react-reconciler/src/ReactFiberCompleteWork.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. tostring(message))
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane
local OffscreenLane = ReactFiberLane.OffscreenLane
-- local type {
--   ReactFundamentalComponentInstance,
--   ReactScopeInstance,
-- } = require("@pkg/@jsdotlua/shared").ReactTypes
-- local type {FiberRoot} = require("./ReactInternalTypes")
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type Instance = ReactFiberHostConfig.Instance
type Type = ReactFiberHostConfig.Type
type Props = ReactFiberHostConfig.Props
type Container = ReactFiberHostConfig.Container
type ChildSet = ReactFiberHostConfig.ChildSet
-- local type {
--   SuspenseState,
--   SuspenseListRenderState,
-- } = require("./ReactFiberSuspenseComponent/new")
local ReactFiberOffscreenComponent = require(script.Parent:WaitForChild('ReactFiberOffscreenComponent'))
type OffscreenState = ReactFiberOffscreenComponent.OffscreenState

local ReactMutableSource = require(script.Parent:WaitForChild('ReactMutableSource.new'))
local resetMutableSourceWorkInProgressVersions =
	ReactMutableSource.resetWorkInProgressVersions

-- local {now} = require("./SchedulerWithReactIntegration/new")

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ContextProvider = ReactWorkTags.ContextProvider
local ContextConsumer = ReactWorkTags.ContextConsumer
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local Mode = ReactWorkTags.Mode
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local LazyComponent = ReactWorkTags.LazyComponent
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ScopeComponent = ReactWorkTags.ScopeComponent
local Block = ReactWorkTags.Block
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState
type SuspenseListRenderState = ReactFiberSuspenseComponent.SuspenseState

local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
local NoMode = ReactTypeOfMode.NoMode
local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local ProfileMode = ReactTypeOfMode.ProfileMode

local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local Ref = ReactFiberFlags.Ref
local Update = ReactFiberFlags.Update
local Callback = ReactFiberFlags.Callback
local Passive = ReactFiberFlags.Passive
local Deletion = ReactFiberFlags.Deletion
local NoFlags = ReactFiberFlags.NoFlags
local DidCapture = ReactFiberFlags.DidCapture
local Snapshot = ReactFiberFlags.Snapshot
local MutationMask = ReactFiberFlags.MutationMask
local LayoutMask = ReactFiberFlags.LayoutMask
local PassiveMask = ReactFiberFlags.PassiveMask
local StaticMask = ReactFiberFlags.StaticMask
local PerformedWork = ReactFiberFlags.PerformedWork

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant

local createInstance = ReactFiberHostConfig.createInstance
local createTextInstance = ReactFiberHostConfig.createTextInstance
local appendInitialChild = ReactFiberHostConfig.appendInitialChild
local finalizeInitialChildren = ReactFiberHostConfig.finalizeInitialChildren
local prepareUpdate = ReactFiberHostConfig.prepareUpdate
local supportsMutation = ReactFiberHostConfig.supportsMutation
local supportsPersistence = ReactFiberHostConfig.supportsPersistence
-- local cloneInstance = ReactFiberHostConfig.cloneInstance
-- local cloneHiddenInstance = ReactFiberHostConfig.cloneHiddenInstance
-- local cloneHiddenTextInstance = ReactFiberHostConfig.cloneHiddenTextInstance
local createContainerChildSet = ReactFiberHostConfig.createContainerChildSet
-- local appendChildToContainerChildSet = ReactFiberHostConfig.appendChildToContainerChildSet
local finalizeContainerChildren = ReactFiberHostConfig.finalizeContainerChildren
-- local getFundamentalComponentInstance = ReactFiberHostConfig.getFundamentalComponentInstance
-- local mountFundamentalComponent = ReactFiberHostConfig.mountFundamentalComponent
-- local cloneFundamentalInstance = ReactFiberHostConfig.cloneFundamentalInstance
-- local shouldUpdateFundamentalComponent = ReactFiberHostConfig.shouldUpdateFundamentalComponent
local preparePortalMount = ReactFiberHostConfig.preparePortalMount
-- local prepareScopeUpdate = ReactFiberHostConfig.prepareScopeUpdate
local ReactFiberHostContext = require(script.Parent:WaitForChild('ReactFiberHostContext.new'))
local getRootHostContainer = ReactFiberHostContext.getRootHostContainer
local popHostContext = ReactFiberHostContext.popHostContext
local getHostContext = ReactFiberHostContext.getHostContext
local popHostContainer = ReactFiberHostContext.popHostContainer

local ReactFiberSuspenseContext = require(script.Parent:WaitForChild('ReactFiberSuspenseContext.new'))
local popSuspenseContext = ReactFiberSuspenseContext.popSuspenseContext
local suspenseStackCursor = ReactFiberSuspenseContext.suspenseStackCursor
local InvisibleParentSuspenseContext =
	ReactFiberSuspenseContext.InvisibleParentSuspenseContext
local hasSuspenseContext = ReactFiberSuspenseContext.hasSuspenseContext
type SuspenseContext = ReactFiberSuspenseContext.SuspenseContext
-- local pushSuspenseContext = ReactFiberSuspenseContext.pushSuspenseContext
-- local setShallowSuspenseContext = ReactFiberSuspenseContext.setShallowSuspenseContext
-- local ForceSuspenseFallback = ReactFiberSuspenseContext.ForceSuspenseFallback
-- local setDefaultShallowSuspenseContext = ReactFiberSuspenseContext.setDefaultShallowSuspenseContext

-- local {findFirstSuspended} = require("./ReactFiberSuspenseComponent/new")
local ReactFiberContext = require(script.Parent:WaitForChild('ReactFiberContext.new'))
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local popLegacyContext = ReactFiberContext.popContext
local popTopLevelLegacyContextObject = ReactFiberContext.popTopLevelContextObject
local popProvider = require(script.Parent:WaitForChild('ReactFiberNewContext.new')).popProvider

local ReactFiberHydrationContext = require(script.Parent:WaitForChild('ReactFiberHydrationContext.new'))
local prepareToHydrateHostSuspenseInstance =
	ReactFiberHydrationContext.prepareToHydrateHostSuspenseInstance
local popHydrationState = ReactFiberHydrationContext.popHydrationState
local resetHydrationState = ReactFiberHydrationContext.resetHydrationState
-- local getIsHydrating = ReactFiberHydrationContext.getIsHydrating
local prepareToHydrateHostInstance =
	ReactFiberHydrationContext.prepareToHydrateHostInstance
local prepareToHydrateHostTextInstance =
	ReactFiberHydrationContext.prepareToHydrateHostTextInstance
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableSuspenseCallback = ReactFeatureFlags.enableSuspenseCallback
local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer

local ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new')):: any

local popRenderLanes = ReactFiberWorkLoop.popRenderLanes
-- ROBLOX deviation: this is a live value in WorkLoop's module state, so it must be accessed directly and not 'cached'
-- local subtreeRenderLanes = ReactFiberWorkLoop.subtreeRenderLanes
local markSpawnedWork = ReactFiberWorkLoop.markSpawnedWork
local renderDidSuspend = ReactFiberWorkLoop.renderDidSuspend
local renderDidSuspendDelayIfPossible = ReactFiberWorkLoop.renderDidSuspendDelayIfPossible
-- local renderHasNotSuspendedYet = ReactFiberWorkLoop.renderHasNotSuspendedYet
-- local getRenderTargetTime = ReactFiberWorkLoop.getRenderTargetTime

-- local {createFundamentalStateInstance} = require("./ReactFiberFundamental/new")

-- local OffscreenLane = ReactFiberLane.OffscreenLane
-- local SomeRetryLane = ReactFiberLane.SomeRetryLane
local NoLanes = ReactFiberLane.NoLanes
local includesSomeLane = ReactFiberLane.includesSomeLane
local mergeLanes = ReactFiberLane.mergeLanes
-- local {resetChildFibers} = require("./ReactChildFiber/new")
-- local {createScopeInstance} = require("./ReactFiberScope/new")
local ReactProfilerTimer = require(script.Parent:WaitForChild('ReactProfilerTimer.new'))
local transferActualDuration = ReactProfilerTimer.transferActualDuration

local function markUpdate(workInProgress: Fiber)
	-- Tag the fiber with an update effect. This turns a Placement into
	-- a PlacementAndUpdate.
	workInProgress.flags = bit32.bor(workInProgress.flags, Update)
end

local function markRef(workInProgress: Fiber)
	workInProgress.flags = bit32.bor(workInProgress.flags, Ref)
end

-- ROBLOX FIXME: type refinement
-- local function hadNoMutationsEffects(current: nil | Fiber, completedWork: Fiber)
local function hadNoMutationsEffects(current, completedWork: Fiber)
	local didBailout = current ~= nil and current.child == completedWork.child
	if didBailout then
		return true
	end

	local child = completedWork.child
	while child ~= nil do
		if bit32.band(child.flags, MutationMask) ~= NoFlags then
			return false
		end
		if bit32.band(child.subtreeFlags, MutationMask) ~= NoFlags then
			return false
		end
		child = child.sibling
	end
	return true
end

local appendAllChildren
local updateHostContainer
local updateHostComponent
local updateHostText
if supportsMutation then
	-- Mutation mode

	appendAllChildren = function(
		parent: Instance,
		workInProgress: Fiber,
		needsVisibilityToggle: boolean,
		isHidden: boolean
	)
		-- We only have the top Fiber that was created but we need recurse down its
		-- children to find all the terminal nodes.
		local node = workInProgress.child
		while node ~= nil do
			if node.tag == HostComponent or node.tag == HostText then
				appendInitialChild(parent, node.stateNode)
			elseif enableFundamentalAPI and node.tag == FundamentalComponent then
				appendInitialChild(parent, node.stateNode.instance)
			elseif node.tag == HostPortal then
			-- If we have a portal child, then we don't want to traverse
			-- down its children. Instead, we'll get insertions from each child in
			-- the portal directly.
			elseif node.child ~= nil then
				node.child.return_ = node
				node = node.child
				continue
			end
			if node == workInProgress then
				return
			end
			while node.sibling == nil do
				if node.return_ == nil or node.return_ == workInProgress then
					return
				end
				node = node.return_
			end
			-- ROBLOX FIXME Luau: Luau doesn't understand loop predicates above results in node.sibling ~= nil
			(node.sibling :: Fiber).return_ = node.return_
			node = node.sibling
		end
	end

	updateHostContainer = function(current: nil | Fiber, workInProgress: Fiber)
		-- Noop
	end
	function updateHostComponent(
		current: Fiber,
		workInProgress: Fiber,
		type: Type,
		newProps: Props,
		rootContainerInstance: Container
	)
		-- If we have an alternate, that means this is an update and we need to
		-- schedule a side-effect to do the updates.
		local oldProps = current.memoizedProps
		if oldProps == newProps then
			-- In mutation mode, this is sufficient for a bailout because
			-- we won't touch this node even if children changed.
			return
		end

		-- If we get updated because one of our children updated, we don't
		-- have newProps so we'll have to reuse them.
		-- TODO: Split the update API as separate for the props vs. children.
		-- Even better would be if children weren't special cased at all tho.
		local instance: Instance = workInProgress.stateNode
		local currentHostContext = getHostContext()
		-- TODO: Experiencing an error where oldProps is nil. Suggests a host
		-- component is hitting the resume path. Figure out why. Possibly
		-- related to `hidden`.
		local updatePayload = prepareUpdate(
			instance,
			type,
			oldProps,
			newProps,
			rootContainerInstance,
			currentHostContext
		)
		-- TODO: Type this specific to this type of component.
		workInProgress.updateQueue = updatePayload
		-- If the update payload indicates that there is a change or if there
		-- is a new ref we mark this as an update. All the work is done in commitWork.
		if updatePayload then
			markUpdate(workInProgress)
		end
	end
	function updateHostText(
		current: Fiber,
		workInProgress: Fiber,
		oldText: string,
		newText: string
	)
		-- If the text differs, mark it as an update. All the work in done in commitWork.
		if oldText ~= newText then
			markUpdate(workInProgress)
		end
	end
elseif supportsPersistence then
	-- Persistent host tree mode
	appendAllChildren = function(
		parent: Instance,
		workInProgress: Fiber,
		needsVisibilityToggle: boolean,
		isHidden: boolean
	)
		unimplemented("appendAllChildren")
		--     -- We only have the top Fiber that was created but we need recurse down its
		--     -- children to find all the terminal nodes.
		--     local node = workInProgress.child
		--     while (node ~= nil)
		--       -- eslint-disable-next-line no-labels
		--       branches: if node.tag == HostComponent)
		--         local instance = node.stateNode
		--         if needsVisibilityToggle and isHidden)
		--           -- This child is inside a timed out tree. Hide it.
		--           local props = node.memoizedProps
		--           local type = node.type
		--           instance = cloneHiddenInstance(instance, type, props, node)
		--         end
		--         appendInitialChild(parent, instance)
		--       } else if node.tag == HostText)
		--         local instance = node.stateNode
		--         if needsVisibilityToggle and isHidden)
		--           -- This child is inside a timed out tree. Hide it.
		--           local text = node.memoizedProps
		--           instance = cloneHiddenTextInstance(instance, text, node)
		--         end
		--         appendInitialChild(parent, instance)
		--       } else if enableFundamentalAPI and node.tag == FundamentalComponent)
		--         local instance = node.stateNode.instance
		--         if needsVisibilityToggle and isHidden)
		--           -- This child is inside a timed out tree. Hide it.
		--           local props = node.memoizedProps
		--           local type = node.type
		--           instance = cloneHiddenInstance(instance, type, props, node)
		--         end
		--         appendInitialChild(parent, instance)
		--       } else if node.tag == HostPortal)
		--         -- If we have a portal child, then we don't want to traverse
		--         -- down its children. Instead, we'll get insertions from each child in
		--         -- the portal directly.
		--       } else if node.tag == SuspenseComponent)
		--         if (node.flags & Update) ~= NoFlags)
		--           -- Need to toggle the visibility of the primary children.
		--           local newIsHidden = node.memoizedState ~= nil
		--           if newIsHidden)
		--             local primaryChildParent = node.child
		--             if primaryChildParent ~= nil)
		--               if primaryChildParent.child ~= nil)
		--                 primaryChildParent.child.return = primaryChildParent
		--                 appendAllChildren(
		--                   parent,
		--                   primaryChildParent,
		--                   true,
		--                   newIsHidden,
		--                 )
		--               end
		--               local fallbackChildParent = primaryChildParent.sibling
		--               if fallbackChildParent ~= nil)
		--                 fallbackChildParent.return = node
		--                 node = fallbackChildParent
		--                 continue
		--               end
		--             end
		--           end
		--         end
		--         if node.child ~= nil)
		--           -- Continue traversing like normal
		--           node.child.return = node
		--           node = node.child
		--           continue
		--         end
		--       } else if node.child ~= nil)
		--         node.child.return = node
		--         node = node.child
		--         continue
		--       end
		--       -- $FlowFixMe This is correct but Flow is confused by the labeled break.
		--       node = (node: Fiber)
		--       if node == workInProgress)
		--         return
		--       end
		--       while (node.sibling == nil)
		--         if node.return == nil or node.return == workInProgress)
		--           return
		--         end
		--         node = node.return
		--       end
		--       node.sibling.return = node.return
		--       node = node.sibling
		--     end
	end

	-- An unfortunate fork of appendAllChildren because we have two different parent types.
	local function appendAllChildrenToContainer(
		containerChildSet: ChildSet,
		workInProgress: Fiber,
		needsVisibilityToggle: boolean,
		isHidden: boolean
	)
		unimplemented("appendAllChildrenToContainer")
		-- -- We only have the top Fiber that was created but we need recurse down its
		-- -- children to find all the terminal nodes.
		-- local node = workInProgress.child
		-- while node ~= nil do
		--   -- eslint-disable-next-line no-labels
		--   if node.tag == HostComponent then
		--     local instance = node.stateNode
		--     if needsVisibilityToggle and isHidden then
		--       -- This child is inside a timed out tree. Hide it.
		--       local props = node.memoizedProps
		--       local type = node.type
		--       instance = cloneHiddenInstance(instance, type, props, node)
		--     end
		--     appendChildToContainerChildSet(containerChildSet, instance)
		--   elseif node.tag == HostText then
		--     local instance = node.stateNode
		--     if needsVisibilityToggle and isHidden then
		--       -- This child is inside a timed out tree. Hide it.
		--       local text = node.memoizedProps
		--       instance = cloneHiddenTextInstance(instance, text, node)
		--     end
		--     appendChildToContainerChildSet(containerChildSet, instance)
		--   elseif enableFundamentalAPI and node.tag == FundamentalComponent then
		--     local instance = node.stateNode.instance
		--     if needsVisibilityToggle and isHidden then
		--       -- This child is inside a timed out tree. Hide it.
		--       local props = node.memoizedProps
		--       local type = node.type
		--       instance = cloneHiddenInstance(instance, type, props, node)
		--     end
		--     appendChildToContainerChildSet(containerChildSet, instance)
		--   elseif node.tag == HostPortal then
		--     -- If we have a portal child, then we don't want to traverse
		--     -- down its children. Instead, we'll get insertions from each child in
		--     -- the portal directly.
		--   elseif node.tag == SuspenseComponent then
		--     if bit32.band(node.flags, Update) ~= NoFlags then
		--       -- Need to toggle the visibility of the primary children.
		--       local newIsHidden = node.memoizedState ~= nil
		--       if newIsHidden then
		--         local primaryChildParent = node.child
		--         if primaryChildParent ~= nil then
		--           if primaryChildParent.child ~= nil then
		--             primaryChildParent.child.return_ = primaryChildParent
		--             appendAllChildrenToContainer(
		--               containerChildSet,
		--               primaryChildParent,
		--               true,
		--               newIsHidden
		--             )
		--           end
		--           local fallbackChildParent = primaryChildParent.sibling
		--           if fallbackChildParent ~= nil then
		--             fallbackChildParent.return_ = node
		--             node = fallbackChildParent
		--             continue
		--           end
		--         end
		--       end
		--     end
		--     if node.child ~= nil then
		--       -- Continue traversing like normal
		--       node.child.return_ = node
		--       node = node.child
		--       continue
		--     end
		--   elseif node.child ~= nil then
		--     node.child.return_ = node
		--     node = node.child
		--     continue
		--   end
		--   -- $FlowFixMe This is correct but Flow is confused by the labeled break.
		--   -- node = (node: Fiber)
		--   if node == workInProgress then
		--     return
		--   end
		--   while node.sibling == nil do
		--     if node.return_ == nil or node.return_ == workInProgress then
		--       return
		--     end
		--     node = node.return_
		--   end
		--   node.sibling.return_ = node.return_
		--   node = node.sibling
		-- end
	end

	function updateHostContainer(current: nil | Fiber, workInProgress: Fiber)
		local portalOrRoot: {
			containerInfo: Container,
			pendingChildren: ChildSet,
			-- ...
			[any]: any		
} =
			workInProgress.stateNode
		local childrenUnchanged = hadNoMutationsEffects(current, workInProgress)
		if childrenUnchanged then
		-- No changes, just reuse the existing instance.
		else
			local container = portalOrRoot.containerInfo
			local newChildSet = createContainerChildSet(container)
			-- If children might have changed, we have to add them all to the set.
			appendAllChildrenToContainer(newChildSet, workInProgress, false, false)
			portalOrRoot.pendingChildren = newChildSet
			-- Schedule an update on the container to swap out the container.
			markUpdate(workInProgress)
			finalizeContainerChildren(container, newChildSet)
		end
	end
--   updateHostComponent = function(
--     current: Fiber,
--     workInProgress: Fiber,
--     type: Type,
--     newProps: Props,
--     rootContainerInstance: Container,
--   )
--     local currentInstance = current.stateNode
--     local oldProps = current.memoizedProps
--     -- If there are no effects associated with this node, then none of our children had any updates.
--     -- This guarantees that we can reuse all of them.
--     local childrenUnchanged = workInProgress.firstEffect == nil
--     if childrenUnchanged and oldProps == newProps)
--       -- No changes, just reuse the existing instance.
--       -- Note that this might release a previous clone.
--       workInProgress.stateNode = currentInstance
--       return
--     end
--     local recyclableInstance: Instance = workInProgress.stateNode
--     local currentHostContext = getHostContext()
--     local updatePayload = nil
--     if oldProps ~= newProps)
--       updatePayload = prepareUpdate(
--         recyclableInstance,
--         type,
--         oldProps,
--         newProps,
--         rootContainerInstance,
--         currentHostContext,
--       )
--     end
--     if childrenUnchanged and updatePayload == nil)
--       -- No changes, just reuse the existing instance.
--       -- Note that this might release a previous clone.
--       workInProgress.stateNode = currentInstance
--       return
--     end
--     local newInstance = cloneInstance(
--       currentInstance,
--       updatePayload,
--       type,
--       oldProps,
--       newProps,
--       workInProgress,
--       childrenUnchanged,
--       recyclableInstance,
--     )
--     if
--       finalizeInitialChildren(
--         newInstance,
--         type,
--         newProps,
--         rootContainerInstance,
--         currentHostContext,
--       )
--     )
--       markUpdate(workInProgress)
--     end
--     workInProgress.stateNode = newInstance
--     if childrenUnchanged)
--       -- If there are no other effects in this tree, we need to flag this node as having one.
--       -- Even though we're not going to use it for anything.
--       -- Otherwise parents won't know that there are new children to propagate upwards.
--       markUpdate(workInProgress)
--     else
--       -- If children might have changed, we have to add them all to the set.
--       appendAllChildren(newInstance, workInProgress, false, false)
--     end
--   end
--   updateHostText = function(
--     current: Fiber,
--     workInProgress: Fiber,
--     oldText: string,
--     newText: string,
--   )
--     if oldText ~= newText)
--       -- If the text content differs, we'll create a new text instance for it.
--       local rootContainerInstance = getRootHostContainer()
--       local currentHostContext = getHostContext()
--       workInProgress.stateNode = createTextInstance(
--         newText,
--         rootContainerInstance,
--         currentHostContext,
--         workInProgress,
--       )
--       -- We'll have to mark it as having an effect, even though we won't use the effect for anything.
--       -- This lets the parents know that at least one of their children has changed.
--       markUpdate(workInProgress)
--     else
--       workInProgress.stateNode = current.stateNode
--     end
--   end
else
	-- No host operations
	updateHostContainer = function(current: nil | Fiber, workInProgress: Fiber)
		-- Noop
	end
	--   updateHostComponent = function(
	--     current: Fiber,
	--     workInProgress: Fiber,
	--     type: Type,
	--     newProps: Props,
	--     rootContainerInstance: Container,
	--   )
	--     -- Noop
	--   end
	--   updateHostText = function(
	--     current: Fiber,
	--     workInProgress: Fiber,
	--     oldText: string,
	--     newText: string,
	--   )
	--     -- Noop
	--   end
	-- end

	-- function cutOffTailIfNeeded(
	--   renderState: SuspenseListRenderState,
	--   hasRenderedATailFallback: boolean,
	-- )
	--   if getIsHydrating())
	--     -- If we're hydrating, we should consume as many items as we can
	--     -- so we don't leave any behind.
	--     return
	--   end
	--   switch (renderState.tailMode)
	--     case 'hidden': {
	--       -- Any insertions at the end of the tail list after this point
	--       -- should be invisible. If there are already mounted boundaries
	--       -- anything before them are not considered for collapsing.
	--       -- Therefore we need to go through the whole tail to find if
	--       -- there are any.
	--       local tailNode = renderState.tail
	--       local lastTailNode = nil
	--       while (tailNode ~= nil)
	--         if tailNode.alternate ~= nil)
	--           lastTailNode = tailNode
	--         end
	--         tailNode = tailNode.sibling
	--       end
	--       -- Next we're simply going to delete all insertions after the
	--       -- last rendered item.
	--       if lastTailNode == nil)
	--         -- All remaining items in the tail are insertions.
	--         renderState.tail = nil
	--       else
	--         -- Detach the insertion after the last node that was already
	--         -- inserted.
	--         lastTailNode.sibling = nil
	--       end
	--       break
	--     end
	--     case 'collapsed': {
	--       -- Any insertions at the end of the tail list after this point
	--       -- should be invisible. If there are already mounted boundaries
	--       -- anything before them are not considered for collapsing.
	--       -- Therefore we need to go through the whole tail to find if
	--       -- there are any.
	--       local tailNode = renderState.tail
	--       local lastTailNode = nil
	--       while (tailNode ~= nil)
	--         if tailNode.alternate ~= nil)
	--           lastTailNode = tailNode
	--         end
	--         tailNode = tailNode.sibling
	--       end
	--       -- Next we're simply going to delete all insertions after the
	--       -- last rendered item.
	--       if lastTailNode == nil)
	--         -- All remaining items in the tail are insertions.
	--         if !hasRenderedATailFallback and renderState.tail ~= nil)
	--           -- We suspended during the head. We want to show at least one
	--           -- row at the tail. So we'll keep on and cut off the rest.
	--           renderState.tail.sibling = nil
	--         else
	--           renderState.tail = nil
	--         end
	--       else
	--         -- Detach the insertion after the last node that was already
	--         -- inserted.
	--         lastTailNode.sibling = nil
	--       end
	--       break
	--     end
	--   end
end

local function bubbleProperties(completedWork: Fiber)
	local didBailout = completedWork.alternate ~= nil
		and (completedWork.alternate :: Fiber).child == completedWork.child

	local newChildLanes = NoLanes
	local subtreeFlags = NoFlags

	if not didBailout then
		-- Bubble up the earliest expiration time.
		if
			enableProfilerTimer
			and bit32.band(completedWork.mode, ProfileMode) ~= NoMode
		then
			-- In profiling mode, resetChildExpirationTime is also used to reset
			-- profiler durations.
			local actualDuration = completedWork.actualDuration
			local treeBaseDuration = completedWork.selfBaseDuration

			local child = completedWork.child
			while child ~= nil do
				newChildLanes =
					mergeLanes(newChildLanes, mergeLanes(child.lanes, child.childLanes))

				subtreeFlags = bit32.bor(subtreeFlags, child.subtreeFlags)
				subtreeFlags = bit32.bor(subtreeFlags, child.flags)

				-- When a fiber is cloned, its actualDuration is reset to 0. This value will
				-- only be updated if work is done on the fiber (i.e. it doesn't bailout).
				-- When work is done, it should bubble to the parent's actualDuration. If
				-- the fiber has not been cloned though, (meaning no work was done), then
				-- this value will reflect the amount of time spent working on a previous
				-- render. In that case it should not bubble. We determine whether it was
				-- cloned by comparing the child pointer.
				actualDuration += child.actualDuration

				treeBaseDuration += child.treeBaseDuration
				child = child.sibling
			end

			completedWork.actualDuration = actualDuration
			completedWork.treeBaseDuration = treeBaseDuration
		else
			local child = completedWork.child
			while child ~= nil do
				-- ROBLOX performance: inline mergeLanes
				-- newChildLanes = mergeLanes(
				--   newChildLanes,
				--   mergeLanes(child.lanes, child.childLanes)
				-- )
				newChildLanes =
					bit32.bor(newChildLanes, bit32.bor(child.lanes, child.childLanes))

				subtreeFlags = bit32.bor(subtreeFlags, child.subtreeFlags)
				subtreeFlags = bit32.bor(subtreeFlags, child.flags)

				-- ROBLOX note: this was missed in the "new" version of the file in React 17, but is fixed in React 18
				-- Update the return pointer so the tree is consistent. This is a code
				-- smell because it assumes the commit phase is never concurrent with
				-- the render phase. Will address during refactor to alternate model.
				child.return_ = completedWork

				child = child.sibling
			end
		end

		completedWork.subtreeFlags = bit32.bor(completedWork.subtreeFlags, subtreeFlags)
	else
		-- Bubble up the earliest expiration time.
		if
			enableProfilerTimer
			and bit32.band(completedWork.mode, ProfileMode) ~= NoMode
		then
			-- In profiling mode, resetChildExpirationTime is also used to reset
			-- profiler durations.
			local treeBaseDuration = completedWork.selfBaseDuration

			local child = completedWork.child
			while child ~= nil do
				newChildLanes =
					mergeLanes(newChildLanes, mergeLanes(child.lanes, child.childLanes))

				-- "Static" flags share the lifetime of the fiber/hook they belong to,
				-- so we should bubble those up even during a bailout. All the other
				-- flags have a lifetime only of a single render + commit, so we should
				-- ignore them.
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.subtreeFlags, StaticMask))
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.flags, StaticMask))

				treeBaseDuration += child.treeBaseDuration
				child = child.sibling
			end

			completedWork.treeBaseDuration = treeBaseDuration
		else
			local child = completedWork.child
			while child ~= nil do
				-- ROBLOX performance: inline mergeLanes
				-- newChildLanes = mergeLanes(
				--   newChildLanes,
				--   mergeLanes(child.lanes, child.childLanes)
				-- )
				newChildLanes =
					bit32.bor(newChildLanes, bit32.bor(child.lanes, child.childLanes))

				-- "Static" flags share the lifetime of the fiber/hook they belong to,
				-- so we should bubble those up even during a bailout. All the other
				-- flags have a lifetime only of a single render + commit, so we should
				-- ignore them.
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.subtreeFlags, StaticMask))
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.flags, StaticMask))

				-- ROBLOX note: this was missed in the "new" version of the file in React 17, but is fixed in React 18
				-- Update the return pointer so the tree is consistent. This is a code
				-- smell because it assumes the commit phase is never concurrent with
				-- the render phase. Will address during refactor to alternate model.
				child.return_ = completedWork

				child = child.sibling
			end
		end

		completedWork.subtreeFlags = bit32.bor(completedWork.subtreeFlags, subtreeFlags)
	end

	completedWork.childLanes = newChildLanes

	return didBailout
end

-- FIXME (roblox): type refinement
-- local function completeWork(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   renderLanes: Lanes
-- ): Fiber | nil
local function completeWork(
	current,
	workInProgress: Fiber,
	renderLanes: Lanes
): Fiber | nil
	local newProps = workInProgress.pendingProps

	if
		workInProgress.tag == IndeterminateComponent
		or workInProgress.tag == LazyComponent
		or workInProgress.tag == SimpleMemoComponent
		or workInProgress.tag == FunctionComponent
		or workInProgress.tag == ForwardRef
		or workInProgress.tag == Fragment
		or workInProgress.tag == Mode
		or workInProgress.tag == ContextConsumer
		or workInProgress.tag == MemoComponent
	then
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == ClassComponent then
		local Component = workInProgress.type
		if isLegacyContextProvider(Component) then
			popLegacyContext(workInProgress)
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == HostRoot then
		popHostContainer(workInProgress)
		popTopLevelLegacyContextObject(workInProgress)
		resetMutableSourceWorkInProgressVersions()
		-- ROBLOX FIXME: type coercion
		-- local fiberRoot = (workInProgress.stateNode: FiberRoot)
		local fiberRoot = workInProgress.stateNode
		if fiberRoot.pendingContext then
			fiberRoot.context = fiberRoot.pendingContext
			fiberRoot.pendingContext = nil
		end
		if current == nil or current.child == nil then
			-- If we hydrated, pop so that we can delete any remaining children
			-- that weren't hydrated.
			local wasHydrated = popHydrationState(workInProgress)
			if wasHydrated then
				-- If we hydrated, then we'll need to schedule an update for
				-- the commit side-effects on the root.
				markUpdate(workInProgress)
			elseif not fiberRoot.hydrate then
				-- Schedule an effect to clear this container at the start of the next commit.
				-- This handles the case of React rendering into a container with previous children.
				-- It's also safe to do for updates too, because current.child would only be nil
				-- if the previous render was nil (so the the container would already be empty).
				workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
			end
		end
		updateHostContainer(current, workInProgress)
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == HostComponent then
		popHostContext(workInProgress)
		local rootContainerInstance = getRootHostContainer()
		local type = workInProgress.type
		if current ~= nil and workInProgress.stateNode ~= nil then
			updateHostComponent(
				current,
				workInProgress,
				type,
				newProps,
				rootContainerInstance
			)

			if current.ref ~= workInProgress.ref then
				markRef(workInProgress)
			end
		else
			if not newProps then
				invariant(
					workInProgress.stateNode ~= nil,
[[We must have new props for new mounts. This error is likely caused by a bug in React. Please file an issue.]]				

)
				-- This can happen when we abort work.
				bubbleProperties(workInProgress)
				return nil
			end

			local currentHostContext = getHostContext()
			-- TODO: Move createInstance to beginWork and keep it on a context
			-- "stack" as the parent. Then append children as we go in beginWork
			-- or completeWork depending on whether we want to add them top->down or
			-- bottom->up. Top->down is faster in IE11.
			local wasHydrated = popHydrationState(workInProgress)
			if wasHydrated then
				-- TODO: Move this and createInstance step into the beginPhase
				-- to consolidate.
				if
					prepareToHydrateHostInstance(
						workInProgress,
						rootContainerInstance,
						currentHostContext
					)
				then
					-- If changes to the hydrated node need to be applied at the
					-- commit-phase we mark this as such.
					markUpdate(workInProgress)
				end
			else
				local instance = createInstance(
					type,
					newProps,
					rootContainerInstance,
					currentHostContext,
					workInProgress
				)

				appendAllChildren(instance, workInProgress, false, false)

				workInProgress.stateNode = instance

				-- Certain renderers require commit-time effects for initial mount.
				-- (eg DOM renderer supports auto-focus for certain elements).
				-- Make sure such renderers get scheduled for later work.
				if
					finalizeInitialChildren(
						instance,
						type,
						newProps,
						rootContainerInstance,
						currentHostContext
					)
				then
					markUpdate(workInProgress)
				end
			end

			if workInProgress.ref ~= nil then
				-- If there is a ref on a host node we need to schedule a callback
				markRef(workInProgress)
			end
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == HostText then
		local newText = newProps
		if current and workInProgress.stateNode ~= nil then
			local oldText = current.memoizedProps
			-- If we have an alternate, that means this is an update and we need
			-- to schedule a side-effect to do the updates.
			updateHostText(current, workInProgress, oldText, newText)
		else
			if typeof(newText) ~= "string" then
				invariant(
					workInProgress.stateNode ~= nil,
[[We must have new props for new mounts. This error is likely caused by a bug in React. Please file an issue.]]				

)
				-- This can happen when we abort work.
			end
			local rootContainerInstance = getRootHostContainer()
			local currentHostContext = getHostContext()
			local wasHydrated = popHydrationState(workInProgress)
			if wasHydrated then
				if prepareToHydrateHostTextInstance(workInProgress) then
					markUpdate(workInProgress)
				end
			else
				workInProgress.stateNode = createTextInstance(
					newText,
					rootContainerInstance,
					currentHostContext,
					workInProgress
				)
			end
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == Profiler then
		local didBailout = bubbleProperties(workInProgress)
		if not didBailout then
			-- Use subtreeFlags to determine which commit callbacks should fire.
			-- TODO: Move this logic to the commit phase, since we already check if
			-- a fiber's subtree contains effects. Refactor the commit phase's
			-- depth-first traversal so that we can put work tag-specific logic
			-- before or after committing a subtree's effects.
			local OnRenderFlag = Update
			local OnCommitFlag = Callback
			local OnPostCommitFlag = Passive
			local subtreeFlags = workInProgress.subtreeFlags
			local flags = workInProgress.flags
			local newFlags = flags

			-- Call onRender any time this fiber or its subtree are worked on.
			if
				bit32.band(flags, PerformedWork) ~= NoFlags
				or bit32.band(subtreeFlags, PerformedWork) ~= NoFlags
			then
				newFlags = bit32.bor(newFlags, OnRenderFlag)
			end

			-- Call onCommit only if the subtree contains layout work, or if it
			-- contains deletions, since those might result in unmount work, which
			-- we include in the same measure.
			-- TODO: Can optimize by using a static flag to track whether a tree
			-- contains layout effects, like we do for passive effects.
			if
				bit32.band(flags, bit32.bor(LayoutMask, Deletion)) ~= NoFlags
				or bit32.band(subtreeFlags, bit32.bor(LayoutMask, Deletion))
					~= NoFlags
			then
				newFlags = bit32.bor(newFlags, OnCommitFlag)
			end

			-- Call onPostCommit only if the subtree contains passive work.
			-- Don't have to check for deletions, because Deletion is already
			-- a passive flag.
			if
				bit32.band(flags, PassiveMask) ~= NoFlags
				or bit32.band(subtreeFlags, PassiveMask) ~= NoFlags
			then
				newFlags = bit32.bor(newFlags, OnPostCommitFlag)
			end
			workInProgress.flags = newFlags
			-- This fiber and its subtree bailed out, so don't fire any callbacks.
		
end

		return nil
	elseif workInProgress.tag == SuspenseComponent then
		popSuspenseContext(workInProgress)
		local nextState: nil | SuspenseState = workInProgress.memoizedState

		if enableSuspenseServerRenderer then
			-- ROBLOX FIXME: remove :: recast once Luau understands if statement nil check
			if nextState ~= nil and (nextState :: SuspenseState).dehydrated ~= nil then
				if current == nil then
					local wasHydrated = popHydrationState(workInProgress)
					invariant(
						wasHydrated,
[[A dehydrated suspense component was completed without a hydrated node. This is probably a bug in React.]]					

)
					prepareToHydrateHostSuspenseInstance(workInProgress)
					if enableSchedulerTracing then
						markSpawnedWork(OffscreenLane)
					end
					bubbleProperties(workInProgress)
					if enableProfilerTimer then
						if bit32.band(workInProgress.mode, ProfileMode) ~= NoMode then
							local isTimedOutSuspense = nextState ~= nil
							if isTimedOutSuspense then
								-- Don't count time spent in a timed out Suspense subtree as part of the base duration.
								local primaryChildFragment = workInProgress.child
								if primaryChildFragment ~= nil then
									-- $FlowFixMe Flow doens't support type casting in combiation with the -= operator
									workInProgress.treeBaseDuration = (
										primaryChildFragment.treeBaseDuration :: any
									) :: number
								end
							end
						end
					end
					return nil
				else
					-- We should never have been in a hydration state if we didn't have a current.
					-- However, in some of those paths, we might have reentered a hydration state
					-- and then we might be inside a hydration state. In that case, we'll need to exit out of it.
					resetHydrationState()
					if bit32.band(workInProgress.flags, DidCapture) == NoFlags then
						-- This boundary did not suspend so it's now hydrated and unsuspended.
						workInProgress.memoizedState = nil
					end
					-- If nothing suspended, we need to schedule an effect to mark this boundary
					-- as having hydrated so events know that they're free to be invoked.
					-- It's also a signal to replay events and the suspense callback.
					-- If something suspended, schedule an effect to attach retry listeners.
					-- So we might as well always mark this.
					workInProgress.flags = bit32.bor(workInProgress.flags, Update)
					bubbleProperties(workInProgress)
					if enableProfilerTimer then
						if bit32.band(workInProgress.mode, ProfileMode) ~= NoMode then
							local isTimedOutSuspense = nextState ~= nil
							if isTimedOutSuspense then
								-- Don't count time spent in a timed out Suspense subtree as part of the base duration.
								local primaryChildFragment = workInProgress.child
								if primaryChildFragment ~= nil then
									-- $FlowFixMe Flow doens't support type casting in combiation with the -= operator
									-- ROBLOX deviation: remove recast to silence analyze
									workInProgress.treeBaseDuration -= primaryChildFragment.treeBaseDuration
								end
							end
						end
					end
					return nil
				end
			end
		end

		if bit32.band(workInProgress.flags, DidCapture) ~= NoFlags then
			-- Something suspended. Re-render with the fallback children.
			workInProgress.lanes = renderLanes
			-- Do not reset the effect list.
			if
				enableProfilerTimer
				and bit32.band(workInProgress.mode, ProfileMode) ~= NoMode
			then
				transferActualDuration(workInProgress)
			end
			-- Don't bubble properties in this case.
			return workInProgress
		end

		local nextDidTimeout = nextState ~= nil
		local prevDidTimeout = false
		if current == nil then
			if workInProgress.memoizedProps.fallback ~= nil then
				popHydrationState(workInProgress)
			end
		else
			local prevState: nil | SuspenseState = current.memoizedState
			prevDidTimeout = prevState ~= nil
		end

		if nextDidTimeout and not prevDidTimeout then
			-- If this subtreee is running in blocking mode we can suspend,
			-- otherwise we won't suspend.
			-- TODO: This will still suspend a synchronous tree if anything
			-- in the concurrent tree already suspended during this render.
			-- This is a known bug.
			if bit32.band(workInProgress.mode, BlockingMode) ~= NoMode then
				-- TODO: Move this back to throwException because this is too late
				-- if this is a large tree which is common for initial loads. We
				-- don't know if we should restart a render or not until we get
				-- this marker, and this is too late.
				-- If this render already had a ping or lower pri updates,
				-- and this is the first time we know we're going to suspend we
				-- should be able to immediately restart from within throwException.
				local hasInvisibleChildContext = current == nil
					and workInProgress.memoizedProps.unstable_avoidThisFallback
						~= true
				if
					hasInvisibleChildContext
					or hasSuspenseContext(
						suspenseStackCursor.current,
						InvisibleParentSuspenseContext :: SuspenseContext
					)
				then
					-- If this was in an invisible tree or a new render, then showing
					-- this boundary is ok.
					renderDidSuspend()
				else
					-- Otherwise, we're going to have to hide content so we should
					-- suspend for longer if possible.
					renderDidSuspendDelayIfPossible()
				end
			end
		end

		if supportsPersistence then
			-- TODO: Only schedule updates if not prevDidTimeout.
			if nextDidTimeout then
				-- If this boundary just timed out, schedule an effect to attach a
				-- retry listener to the promise. This flag is also used to hide the
				-- primary children.
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if supportsMutation then
			-- TODO: Only schedule updates if these values are non equal, i.e. it changed.
			if nextDidTimeout or prevDidTimeout then
				-- If this boundary just timed out, schedule an effect to attach a
				-- retry listener to the promise. This flag is also used to hide the
				-- primary children. In mutation mode, we also need the flag to
				-- *unhide* children that were previously hidden, so check if this
				-- is currently timed out, too.
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if
			enableSuspenseCallback
			and workInProgress.updateQueue ~= nil
			and workInProgress.memoizedProps.suspenseCallback ~= nil
		then
			-- Always notify the callback
			workInProgress.flags = bit32.bor(workInProgress.flags, Update)
		end
		bubbleProperties(workInProgress)
		if enableProfilerTimer then
			if bit32.band(workInProgress.mode, ProfileMode) ~= NoMode then
				if nextDidTimeout then
					-- Don't count time spent in a timed out Suspense subtree as part of the base duration.
					local primaryChildFragment = workInProgress.child
					if primaryChildFragment ~= nil then
						-- $FlowFixMe Flow doens't support type casting in combiation with the -= operator
						-- ROBLOX deviation: remove recast to silence analyze
						workInProgress.treeBaseDuration -= primaryChildFragment.treeBaseDuration
					end
				end
			end
		end
		return nil
	elseif workInProgress.tag == HostPortal then
		popHostContainer(workInProgress)
		updateHostContainer(current, workInProgress)
		if current == nil then
			preparePortalMount(workInProgress.stateNode.containerInfo)
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == ContextProvider then
		-- Pop provider fiber
		popProvider(workInProgress)
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == IncompleteClassComponent then
		-- Same as class component case. I put it down here so that the tags are
		-- sequential to ensure this switch is compiled to a jump table.
		local Component = workInProgress.type
		if isLegacyContextProvider(Component) then
			popLegacyContext(workInProgress)
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == SuspenseListComponent then
		unimplemented("SuspenseListComponent")
	-- popSuspenseContext(workInProgress)

	-- local renderState: nil | SuspenseListRenderState =
	--   workInProgress.memoizedState

	-- if renderState == nil)
	--   -- We're running in the default, "independent" mode.
	--   -- We don't do anything in this mode.
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end

	-- local didSuspendAlready = (workInProgress.flags & DidCapture) ~= NoFlags

	-- local renderedTail = renderState.rendering
	-- if renderedTail == nil)
	--   -- We just rendered the head.
	--   if !didSuspendAlready)
	--     -- This is the first pass. We need to figure out if anything is still
	--     -- suspended in the rendered set.

	--     -- If new content unsuspended, but there's still some content that
	--     -- didn't. Then we need to do a second pass that forces everything
	--     -- to keep showing their fallbacks.

	--     -- We might be suspended if something in this render pass suspended, or
	--     -- something in the previous committed pass suspended. Otherwise,
	--     -- there's no chance so we can skip the expensive call to
	--     -- findFirstSuspended.
	--     local cannotBeSuspended =
	--       renderHasNotSuspendedYet() and
	--       (current == nil or (current.flags & DidCapture) == NoFlags)
	--     if !cannotBeSuspended)
	--       local row = workInProgress.child
	--       while (row ~= nil)
	--         local suspended = findFirstSuspended(row)
	--         if suspended ~= nil)
	--           didSuspendAlready = true
	--           workInProgress.flags |= DidCapture
	--           cutOffTailIfNeeded(renderState, false)

	--           -- If this is a newly suspended tree, it might not get committed as
	--           -- part of the second pass. In that case nothing will subscribe to
	--           -- its thennables. Instead, we'll transfer its thennables to the
	--           -- SuspenseList so that it can retry if they resolve.
	--           -- There might be multiple of these in the list but since we're
	--           -- going to wait for all of them anyway, it doesn't really matter
	--           -- which ones gets to ping. In theory we could get clever and keep
	--           -- track of how many dependencies remain but it gets tricky because
	--           -- in the meantime, we can add/remove/change items and dependencies.
	--           -- We might bail out of the loop before finding any but that
	--           -- doesn't matter since that means that the other boundaries that
	--           -- we did find already has their listeners attached.
	--           local newThennables = suspended.updateQueue
	--           if newThennables ~= nil)
	--             workInProgress.updateQueue = newThennables
	--             workInProgress.flags |= Update
	--           end

	--           -- Rerender the whole list, but this time, we'll force fallbacks
	--           -- to stay in place.
	--           -- Reset the child fibers to their original state.
	--           workInProgress.subtreeFlags = NoFlags
	--           resetChildFibers(workInProgress, renderLanes)

	--           -- Set up the Suspense Context to force suspense and immediately
	--           -- rerender the children.
	--           pushSuspenseContext(
	--             workInProgress,
	--             setShallowSuspenseContext(
	--               suspenseStackCursor.current,
	--               ForceSuspenseFallback,
	--             ),
	--           )
	--           -- Don't bubble properties in this case.
	--           return workInProgress.child
	--         end
	--         row = row.sibling
	--       end
	--     end

	--     if renderState.tail ~= nil and now() > getRenderTargetTime())
	--       -- We have already passed our CPU deadline but we still have rows
	--       -- left in the tail. We'll just give up further attempts to render
	--       -- the main content and only render fallbacks.
	--       workInProgress.flags |= DidCapture
	--       didSuspendAlready = true

	--       cutOffTailIfNeeded(renderState, false)

	--       -- Since nothing actually suspended, there will nothing to ping this
	--       -- to get it started back up to attempt the next item. While in terms
	--       -- of priority this work has the same priority as this current render,
	--       -- it's not part of the same transition once the transition has
	--       -- committed. If it's sync, we still want to yield so that it can be
	--       -- painted. Conceptually, this is really the same as pinging.
	--       -- We can use any RetryLane even if it's the one currently rendering
	--       -- since we're leaving it behind on this node.
	--       workInProgress.lanes = SomeRetryLane
	--       if enableSchedulerTracing)
	--         markSpawnedWork(SomeRetryLane)
	--       end
	--     end
	--   else
	--     cutOffTailIfNeeded(renderState, false)
	--   end
	--   -- Next we're going to render the tail.
	-- else
	--   -- Append the rendered row to the child list.
	--   if !didSuspendAlready)
	--     local suspended = findFirstSuspended(renderedTail)
	--     if suspended ~= nil)
	--       workInProgress.flags |= DidCapture
	--       didSuspendAlready = true

	--       -- Ensure we transfer the update queue to the parent so that it doesn't
	--       -- get lost if this row ends up dropped during a second pass.
	--       local newThennables = suspended.updateQueue
	--       if newThennables ~= nil)
	--         workInProgress.updateQueue = newThennables
	--         workInProgress.flags |= Update
	--       end

	--       cutOffTailIfNeeded(renderState, true)
	--       -- This might have been modified.
	--       if
	--         renderState.tail == nil and
	--         renderState.tailMode == 'hidden' and
	--         !renderedTail.alternate and
	--         !getIsHydrating() -- We don't cut it if we're hydrating.
	--       )
	--         -- We're done.
	--         bubbleProperties(workInProgress)
	--         return nil
	--       end
	--     } else if
	--       -- The time it took to render last row is greater than the remaining
	--       -- time we have to render. So rendering one more row would likely
	--       -- exceed it.
	--       now() * 2 - renderState.renderingStartTime >
	--         getRenderTargetTime() and
	--       renderLanes ~= OffscreenLane
	--     )
	--       -- We have now passed our CPU deadline and we'll just give up further
	--       -- attempts to render the main content and only render fallbacks.
	--       -- The assumption is that this is usually faster.
	--       workInProgress.flags |= DidCapture
	--       didSuspendAlready = true

	--       cutOffTailIfNeeded(renderState, false)

	--       -- Since nothing actually suspended, there will nothing to ping this
	--       -- to get it started back up to attempt the next item. If we can show
	--       -- them, then they really have the same priority as this render.
	--       -- So we'll pick it back up the very next render pass once we've had
	--       -- an opportunity to yield for paint.
	--       workInProgress.lanes = SomeRetryLane
	--       if enableSchedulerTracing)
	--         markSpawnedWork(SomeRetryLane)
	--       end
	--     end
	--   end
	--   if renderState.isBackwards)
	--     -- The effect list of the backwards tail will have been added
	--     -- to the end. This breaks the guarantee that life-cycles fire in
	--     -- sibling order but that isn't a strong guarantee promised by React.
	--     -- Especially since these might also just pop in during future commits.
	--     -- Append to the beginning of the list.
	--     renderedTail.sibling = workInProgress.child
	--     workInProgress.child = renderedTail
	--   else
	--     local previousSibling = renderState.last
	--     if previousSibling ~= nil)
	--       previousSibling.sibling = renderedTail
	--     else
	--       workInProgress.child = renderedTail
	--     end
	--     renderState.last = renderedTail
	--   end
	-- end

	-- if renderState.tail ~= nil)
	--   -- We still have tail rows to render.
	--   -- Pop a row.
	--   local next = renderState.tail
	--   renderState.rendering = next
	--   renderState.tail = next.sibling
	--   renderState.renderingStartTime = now()
	--   next.sibling = nil

	--   -- Restore the context.
	--   -- TODO: We can probably just avoid popping it instead and only
	--   -- setting it the first time we go from not suspended to suspended.
	--   local suspenseContext = suspenseStackCursor.current
	--   if didSuspendAlready)
	--     suspenseContext = setShallowSuspenseContext(
	--       suspenseContext,
	--       ForceSuspenseFallback,
	--     )
	--   else
	--     suspenseContext = setDefaultShallowSuspenseContext(suspenseContext)
	--   end
	--   pushSuspenseContext(workInProgress, suspenseContext)
	--   -- Do a pass over the next row.
	--   -- Don't bubble properties in this case.
	--   return next
	-- end
	-- bubbleProperties(workInProgress)
	-- return nil
	-- end
	elseif workInProgress.tag == FundamentalComponent then
		unimplemented("FundamentalComponent")
	--   if enableFundamentalAPI)
	--   local fundamentalImpl = workInProgress.type.impl
	--   local fundamentalInstance: ReactFundamentalComponentInstance<
	--     any,
	--     any,
	--   > | nil = workInProgress.stateNode

	--   if fundamentalInstance == nil)
	--     local getInitialState = fundamentalImpl.getInitialState
	--     local fundamentalState
	--     if getInitialState ~= undefined)
	--       fundamentalState = getInitialState(newProps)
	--     end
	--     fundamentalInstance = workInProgress.stateNode = createFundamentalStateInstance(
	--       workInProgress,
	--       newProps,
	--       fundamentalImpl,
	--       fundamentalState or {},
	--     )
	--     local instance = ((getFundamentalComponentInstance(
	--       fundamentalInstance,
	--     ): any): Instance)
	--     fundamentalInstance.instance = instance
	--     if fundamentalImpl.reconcileChildren == false)
	--       bubbleProperties(workInProgress)
	--       return nil
	--     end
	--     appendAllChildren(instance, workInProgress, false, false)
	--     mountFundamentalComponent(fundamentalInstance)
	--   else
	--     -- We fire update in commit phase
	--     local prevProps = fundamentalInstance.props
	--     fundamentalInstance.prevProps = prevProps
	--     fundamentalInstance.props = newProps
	--     fundamentalInstance.currentFiber = workInProgress
	--     if supportsPersistence)
	--       local instance = cloneFundamentalInstance(fundamentalInstance)
	--       fundamentalInstance.instance = instance
	--       appendAllChildren(instance, workInProgress, false, false)
	--     end
	--     local shouldUpdate = shouldUpdateFundamentalComponent(
	--       fundamentalInstance,
	--     )
	--     if shouldUpdate)
	--       markUpdate(workInProgress)
	--     end
	--   end
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end
	elseif workInProgress.tag == ScopeComponent then
		unimplemented("ScopeComponent")
	-- if enableScopeAPI)
	--   if current == nil)
	--     local scopeInstance: ReactScopeInstance = createScopeInstance()
	--     workInProgress.stateNode = scopeInstance
	--     prepareScopeUpdate(scopeInstance, workInProgress)
	--     if workInProgress.ref ~= nil)
	--       markRef(workInProgress)
	--       markUpdate(workInProgress)
	--     end
	--   else
	--     if workInProgress.ref ~= nil)
	--       markUpdate(workInProgress)
	--     end
	--     if current.ref ~= workInProgress.ref)
	--       markRef(workInProgress)
	--     end
	--   end
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end
	elseif workInProgress.tag == Block then
		unimplemented("Block")
	-- if enableBlocksAPI)
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end
	elseif
		workInProgress.tag == OffscreenComponent
		or workInProgress.tag == LegacyHiddenComponent
	then
		popRenderLanes(workInProgress)
		local nextState: OffscreenState | nil = workInProgress.memoizedState
		local nextIsHidden = nextState ~= nil

		if current ~= nil then
			local prevState: OffscreenState | nil = current.memoizedState

			local prevIsHidden = prevState ~= nil
			if
				prevIsHidden ~= nextIsHidden
				and newProps.mode ~= "unstable-defer-without-hiding"
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end

		-- Don't bubble properties for hidden children.
		if
			not nextIsHidden
			or includesSomeLane(
				ReactFiberWorkLoop.subtreeRenderLanes,
				OffscreenLane :: Lane
			)
			or bit32.band(workInProgress.mode, ConcurrentMode) == NoMode
		then
			bubbleProperties(workInProgress)
		end

		return nil
	end
	invariant(
		false,
[[Unknown unit of work tag (%s). This error is likely caused by a bug in React. Please file an issue.]]
,
		tostring(workInProgress.tag)
	)
	return nil
end

return {
	completeWork = completeWork,
}

end,
["react-reconciler/ReactFiberComponentStack"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/72d00ab623502983ebd7ac0756cf2787df109811/packages/react-reconciler/src/ReactFiberComponentStack.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Function = (...any) -> ...any
type Error = LuauPolyfill.Error

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local HostComponent = ReactWorkTags.HostComponent
local LazyComponent = ReactWorkTags.LazyComponent
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local FunctionComponent = ReactWorkTags.FunctionComponent
local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
local ForwardRef = ReactWorkTags.ForwardRef
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local ClassComponent = ReactWorkTags.ClassComponent

local ReactComponentStackFrame = require(script.Parent.Parent:WaitForChild('shared')).ReactComponentStackFrame
local describeBuiltInComponentFrame =
	ReactComponentStackFrame.describeBuiltInComponentFrame
local describeFunctionComponentFrame =
	ReactComponentStackFrame.describeFunctionComponentFrame
local describeClassComponentFrame = ReactComponentStackFrame.describeClassComponentFrame

local function describeFiber(fiber: Fiber): string
	-- deviation: untangling some nested ternaries to use more idiomatic if/else
	local owner: nil | Function 	
if _G.__DEV__ then
		-- FIXME (roblox): Luau's limited narrowing necessitates this local
		local debugOwner = fiber._debugOwner
		if debugOwner then
			owner = debugOwner.type
		end
	end
	local source 	
if _G.__DEV__ then
		source = fiber._debugSource
	end
	if fiber.tag == HostComponent then
		return describeBuiltInComponentFrame(fiber.type, source, owner)
	elseif fiber.tag == LazyComponent then
		return describeBuiltInComponentFrame("Lazy", source, owner)
	elseif fiber.tag == SuspenseComponent then
		return describeBuiltInComponentFrame("Suspense", source, owner)
	elseif fiber.tag == SuspenseListComponent then
		return describeBuiltInComponentFrame("SuspenseList", source, owner)
	elseif
		fiber.tag == FunctionComponent
		or fiber.tag == IndeterminateComponent
		or fiber.tag == SimpleMemoComponent
	then
		return describeFunctionComponentFrame(fiber.type, source, owner)
	elseif fiber.tag == ForwardRef then
		return describeFunctionComponentFrame(fiber.type.render, source, owner)
	elseif fiber.tag == ClassComponent then
		return describeClassComponentFrame(fiber.type, source, owner)
	else
		return ""
	end
end

return {
	getStackByFiberInDevAndProd = function(workInProgress: Fiber?): string
		local ok: boolean, result: Error | string = pcall(function()
			local info = ""
			local node = workInProgress
			repeat
				info ..= describeFiber(node :: Fiber)
				node = (node :: Fiber).return_
			until node == nil
			return info
		end)

		if not ok then
			local message = "\nError generating stack: "
			if
				typeof(result) == "table"
				and (result :: Error).message
				and (result :: Error).stack
			then
				return message
					.. (result :: Error).message
					.. "\n"
					.. tostring((result :: Error).stack)
			end
			return message .. tostring(result)
		end

		return result :: string
	end,
}

end,
["react-reconciler/ReactFiberContext.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/a724a3b578dce77d427bef313102a4d0e978d9b4/packages/react-reconciler/src/ReactFiberContext.new.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local __DEV__ = _G.__DEV__ :: boolean
local __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ =
	_G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ :: boolean

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object
local Error = LuauPolyfill.Error

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberStack = require(script.Parent:WaitForChild('ReactFiberStack.new'))
type StackCursor<T> = ReactFiberStack.StackCursor<T>

local isFiberMounted = require(script.Parent:WaitForChild('ReactFiberTreeReflection')).isFiberMounted
local disableLegacyContext =
	require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.disableLegacyContext
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local checkPropTypes = require(script.Parent.Parent:WaitForChild('shared')).checkPropTypes

local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop

local warnedAboutMissingGetChildContext

if __DEV__ then
	warnedAboutMissingGetChildContext = {}
end

local emptyContextObject = {}
if __DEV__ then
	Object.freeze(emptyContextObject)
end

-- deviation: Common types
type Object = { [any]: any }

-- A cursor to the current merged context object on the stack.
local contextStackCursor: StackCursor<Object> = createCursor(emptyContextObject)
-- A cursor to a boolean indicating whether the context has changed.
local didPerformWorkStackCursor: StackCursor<boolean> = createCursor(false)
-- Keep track of the previous context object that was on the stack.
-- We use this to get access to the parent context after we have already
-- pushed the next context provider, and now need to merge their contexts.
local previousContext: Object = emptyContextObject

-- deviation: Pre-declare function
local isContextProvider

-- deviation: FIXME: `Component: Function` - lock down component type def
local function getUnmaskedContext(
	workInProgress: Fiber,
	Component: any,
	didPushOwnContextIfProvider: boolean
): Object
	-- ROBLOX performance: skip always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return emptyContextObject
	-- else
	if didPushOwnContextIfProvider and isContextProvider(Component) then
		-- If the fiber is a context provider itself, when we read its context
		-- we may have already pushed its own child context on the stack. A context
		-- provider should not "see" its own child context. Therefore we read the
		-- previous (parent) context instead for a context provider.
		return previousContext
	end
	return contextStackCursor.current
	-- end
end

local function cacheContext(
	workInProgress: Fiber,
	unmaskedContext: Object,
	maskedContext: Object
): ()
	-- ROBLOX performance: skip always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return
	-- else
	local instance = workInProgress.stateNode
	instance.__reactInternalMemoizedUnmaskedChildContext = unmaskedContext
	instance.__reactInternalMemoizedMaskedChildContext = maskedContext
	-- end
end

local function getMaskedContext(workInProgress: Fiber, unmaskedContext: Object): Object
	-- ROBLOX performance: skip always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return emptyContextObject
	-- else
	local type_ = workInProgress.type
	-- deviation: For function components, we can't support `contextTypes`;
	-- instead, just return unmaskedContext
	if type(type_) == "function" then
		return unmaskedContext
	end

	local contextTypes = type_.contextTypes
	if not contextTypes then
		return emptyContextObject
	end

	-- Avoid recreating masked context unless unmasked context has changed.
	-- Failing to do this will result in unnecessary calls to componentWillReceiveProps.
	-- This may trigger infinite loops if componentWillReceiveProps calls setState.
	local instance = workInProgress.stateNode
	if
		instance
		and instance.__reactInternalMemoizedUnmaskedChildContext == unmaskedContext
	then
		return instance.__reactInternalMemoizedMaskedChildContext
	end

	local context = {}
	for key, _ in contextTypes do
		context[key] = unmaskedContext[key]
	end

	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		local name = getComponentName(type_) or "Unknown"
		-- ROBLOX deviation: nil as second argument for validateProps compatibility
		checkPropTypes(contextTypes, nil, context, "context", name)
	end

	-- Cache unmasked context so we can avoid recreating masked context unless necessary.
	-- Context is created before the class component is instantiated so check for instance.
	if instance then
		cacheContext(workInProgress, unmaskedContext, context)
	end

	return context
	-- end
end

local function hasContextChanged(): boolean
	if disableLegacyContext then
		return false
	else
		return didPerformWorkStackCursor.current
	end
end

-- deviation: `type: Function` - lock down component type def
function isContextProvider(type_): boolean
	-- ROBLOX performance: skip always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return false
	-- else
	-- ROBLOX deviation: context types only valid for class components
	-- ROBLOX performance: type is already guarded as being a ClassComponent and/or typeof == 'table' in all call sites
	if type(type_) == "function" then
		return false
	end
	local childContextTypes = type_.childContextTypes
	return childContextTypes ~= nil
	-- end
end

local function popContext(fiber: Fiber): ()
	-- ROBLOX performance: skip always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return
	-- else
	pop(didPerformWorkStackCursor, fiber)
	pop(contextStackCursor, fiber)
	-- end
end

local function popTopLevelContextObject(fiber: Fiber): ()
	-- ROBLOX performance: skip always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return
	-- else
	pop(didPerformWorkStackCursor, fiber)
	pop(contextStackCursor, fiber)
	-- end
end

local function pushTopLevelContextObject(
	fiber: Fiber,
	context: Object,
	didChange: boolean
): ()
	-- ROBLOX performance: disable always-false cmp in hot path
	-- if disableLegacyContext then
	-- 	return
	-- else
	if contextStackCursor.current ~= emptyContextObject then
		error(
			Error.new(
[[Unexpected context found on stack. This error is likely caused by a bug in React. Please file an issue.]]			

)
		)
	end

	push(contextStackCursor, context, fiber)
	push(didPerformWorkStackCursor, didChange, fiber)
	-- end
end

local function processChildContext(
	fiber: Fiber,
	type_: any,
	parentContext: Object
): Object
	-- ROBLOX performance: eliminate always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return parentContext
	-- else
	local instance = fiber.stateNode
	local childContextTypes = type_.childContextTypes

	-- TODO (bvaughn) Replace this behavior with an invariant() in the future.
	-- It has only been added in Fiber to match the (unintentional) behavior in Stack.
	if
		instance.getChildContext == nil
		or type(instance.getChildContext) ~= "function"
	then
		if __DEV__ then
			local componentName = getComponentName(type_) or "Unknown"

			if not warnedAboutMissingGetChildContext[componentName] then
				warnedAboutMissingGetChildContext[componentName] = true
				console.error(
[[%s.childContextTypes is specified but there is no getChildContext() method on the instance. You can either define getChildContext() on %s or remove childContextTypes from it.]]

,
					componentName,
					componentName
				)
			end
		end
		return parentContext
	end

	local childContext = instance:getChildContext()
	for contextKey, _ in childContext do
		if childContextTypes[contextKey] == nil then
			local name = getComponentName(type_) or "Unknown"
			error(
				Error.new(
					string.format(
						'%s.getChildContext(): key "%s" is not defined in childContextTypes.',
						name,
						contextKey
					)
				)
			)
		end
	end
	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		local name = getComponentName(type_) or "Unknown"
		-- ROBLOX deviation: nil as second argument for validateProps compatibility
		checkPropTypes(childContextTypes, nil, childContext, "child context", name)
	end

	return Object.assign({}, parentContext, childContext)
	-- end
end

local function pushContextProvider(workInProgress: Fiber): boolean
	-- ROBLOX performance: eliminate always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return false
	-- else
	local instance = workInProgress.stateNode
	-- We push the context as early as possible to ensure stack integrity.
	-- If the instance does not exist yet, we will push nil at first,
	-- and replace it on the stack later when invalidating the context.
	local memoizedMergedChildContext = (
		instance and instance.__reactInternalMemoizedMergedChildContext
	) or emptyContextObject

	-- Remember the parent context so we can merge with it later.
	-- Inherit the parent's did-perform-work value to avoid inadvertently blocking updates.
	previousContext = contextStackCursor.current
	push(contextStackCursor, memoizedMergedChildContext, workInProgress)
	push(didPerformWorkStackCursor, didPerformWorkStackCursor.current, workInProgress)

	return true
	-- end
end

local function invalidateContextProvider(
	workInProgress: Fiber,
	type_: any,
	didChange: boolean
): ()
	-- ROBLOX performance: eliminate always-false compare in hot path
	-- if disableLegacyContext then
	-- 	return
	-- else
	local instance = workInProgress.stateNode

	if not instance then
		error(
			Error.new(
[[Expected to have an instance by this point. This error is likely caused by a bug in React. Please file an issue.]]			

)
		)
	end

	if didChange then
		-- Merge parent and own context.
		-- Skip this if we're not updating due to sCU.
		-- This avoids unnecessarily recomputing memoized values.
		local mergedContext = processChildContext(workInProgress, type_, previousContext)
		instance.__reactInternalMemoizedMergedChildContext = mergedContext

		-- Replace the old (or empty) context with the new one.
		-- It is important to unwind the context in the reverse order.
		pop(didPerformWorkStackCursor, workInProgress)
		pop(contextStackCursor, workInProgress)
		-- Now push the new context and mark that it has changed.
		push(contextStackCursor, mergedContext, workInProgress)
		push(didPerformWorkStackCursor, didChange, workInProgress)
	else
		pop(didPerformWorkStackCursor, workInProgress)
		push(didPerformWorkStackCursor, didChange, workInProgress)
	end
	-- end
end

local function findCurrentUnmaskedContext(fiber: Fiber): Object
	-- ROBLOX performance: eliminate always-false in hot path
	-- if disableLegacyContext then
	-- 	return emptyContextObject
	-- else
	-- Currently this is only used with renderSubtreeIntoContainer; not sure if it
	-- makes sense elsewhere
	if fiber.tag ~= ClassComponent or not isFiberMounted(fiber) then
		error(
			Error.new(
[[Expected subtree parent to be a mounted class component. This error is likely caused by a bug in React. Please file an issue.]]			

)
		)
	end

	-- ROBLOX TODO: Luau analyze can't accommodate the 'repeat until (not) nil' pattern
	local node: any = fiber
	repeat
		if node.tag == HostRoot then
			return node.stateNode.context
		elseif node.tag == ClassComponent then
			local Component = node.type
			-- ROBLOX deviation: inline specialized check for isContextProvider since we know it's a class
			if Component.childContextTypes ~= nil then
				return node.stateNode.__reactInternalMemoizedMergedChildContext
			end
		end

		node = node.return_
	until node == nil

	error(
		Error.new(
[[Found unexpected detached subtree parent. This error is likely caused by a bug in React. Please file an issue.]]		

)
	)
	-- end
end

return {
	emptyContextObject = emptyContextObject,
	getUnmaskedContext = getUnmaskedContext,
	cacheContext = cacheContext,
	getMaskedContext = getMaskedContext,
	hasContextChanged = hasContextChanged,
	popContext = popContext,
	popTopLevelContextObject = popTopLevelContextObject,
	pushTopLevelContextObject = pushTopLevelContextObject,
	processChildContext = processChildContext,
	isContextProvider = isContextProvider,
	pushContextProvider = pushContextProvider,
	invalidateContextProvider = invalidateContextProvider,
	findCurrentUnmaskedContext = findCurrentUnmaskedContext,
}

end,
["react-reconciler/ReactFiberDevToolsHook.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberDevToolsHook.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Object = LuauPolyfill.Object
local exports = {}

-- ROBLOX deviation: subset copied here from devtools-shared/backend/types, to have stronger enforcement than 'Object' without circular dep
type DevToolsHook = {
	-- ROBLOX TODO: ideally, ReactRenderer type would be importable from this file so we could use it here
	inject: (Object) -> number | nil,
	supportsFiber: boolean,
	isDisabled: boolean	--   ...

}

-- ROBLOX deviation: we use callable tables instead of functions sometimes, so typeof() == "function" isn't enough
local function isCallable(value)
	if typeof(value) == "function" then
		return true
	end
	if typeof(value) == "table" then
		local mt = getmetatable(value)
		if mt and rawget(mt, "__call") then
			return true
		end
		if value._isMockFunction then
			return true
		end
	end
	return false
end

local enableProfilerTimer =
	require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.enableProfilerTimer

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactNodeList = ReactTypes.ReactNodeList

local DidCapture = require(script.Parent:WaitForChild('ReactFiberFlags')).DidCapture

-- ROBLOX deviation: we'll inject this a different way
-- declare var __REACT_DEVTOOLS_GLOBAL_HOOK__: Object | void

local rendererID 
local injectedHook 
local hasLoggedError = false

-- ROBLOX deviation: We use a function to handle the hook being changed at runtime
exports.isDevToolsPresent = function()
	return _G.__REACT_DEVTOOLS_GLOBAL_HOOK__ ~= nil
end

exports.injectInternals = function(internals: Object): boolean
	if _G.__REACT_DEVTOOLS_GLOBAL_HOOK__ == nil then
		-- No DevTools
		return false
	end
	local hook: DevToolsHook = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__
	if hook.isDisabled then
		-- This isn't a real property on the hook, but it can be set to opt out
		-- of DevTools integration and associated warnings and logs.
		-- http://github.com/facebook/react/issues/3877
		return true
	end
	if not hook.supportsFiber then
		if _G.__DEV__ then
			console.error(
[[The installed version of React DevTools is too old and will not work with the current version of React. Please update React DevTools. https://reactjs.org/link/react-devtools]]			


)
		end
		-- DevTools exists, even though it doesn't support Fiber.
		return true
	end
	local ok, err = pcall(function()
		rendererID = hook.inject(internals)
		-- We have successfully injected, so now it is safe to set up hooks.
		injectedHook = hook
	end)

	if not ok then
		-- Catch all errors because it is unsafe to throw during initialization.
		if _G.__DEV__ then
			console.error("React instrumentation encountered an error: %s.", err)
		end
	end
	-- DevTools exists
	return true
end

exports.onScheduleRoot = function(root: FiberRoot, children: ReactNodeList)
	if _G.__DEV__ then
		if
			injectedHook
			-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
			and isCallable(injectedHook.onScheduleFiberRoot)
		then
			local ok, err =
				pcall(injectedHook.onScheduleFiberRoot, rendererID, root, children)

			if not ok then
				if _G.__DEV__ and not hasLoggedError then
					hasLoggedError = true
					console.error("React instrumentation encountered an error: %s", err)
				end
			end
		end
	end
end

exports.onCommitRoot = function(root: FiberRoot, priorityLevel: ReactPriorityLevel)
	if
		injectedHook
		-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
		and isCallable(injectedHook.onCommitFiberRoot)
	then
		local ok, err = pcall(function()
			local didError = bit32.band(root.current.flags, DidCapture) == DidCapture
			if enableProfilerTimer then
				injectedHook.onCommitFiberRoot(rendererID, root, priorityLevel, didError)
			else
				injectedHook.onCommitFiberRoot(rendererID, root, nil, didError)
			end
		end)
		if not ok then
			if _G.__DEV__ then
				if not hasLoggedError then
					hasLoggedError = true
					console.error("React instrumentation encountered an error: %s", err)
				end
			end
		end
	end
end

exports.onCommitUnmount = function(fiber: Fiber)
	if
		injectedHook
		-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
		and isCallable(injectedHook.onCommitFiberUnmount)
	then
		local ok, err = pcall(injectedHook.onCommitFiberUnmount, rendererID, fiber)
		if not ok then
			if _G.__DEV__ then
				if not hasLoggedError then
					hasLoggedError = true
					console.error("React instrumentation encountered an error: %s", err)
				end
			end
		end
	end
end

return exports

end,
["react-reconciler/ReactFiberErrorDialog"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberErrorDialog.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- This module is forked in different environments.
-- By default, return `true` to log errors to the console.
-- Forks can return `false` if this isn't desirable.
local exports = {}

exports.showErrorDialog = function(boundary, errorInfo): boolean
	-- ROBLOX TODO: we may replace this with something that sends telemetry LUAFDN-222
	return true
end

return exports

end,
["react-reconciler/ReactFiberErrorLogger"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react-reconciler/src/ReactFiberErrorLogger.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect
local setTimeout = LuauPolyfill.setTimeout

local Shared = require(script.Parent.Parent:WaitForChild('shared'))
local console = Shared.console
local errorToString = Shared.errorToString

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactCapturedValue = require(script.Parent:WaitForChild('ReactCapturedValue'))
type CapturedValue<T> = ReactCapturedValue.CapturedValue<T>

local showErrorDialog = require(script.Parent:WaitForChild('ReactFiberErrorDialog')).showErrorDialog
local ClassComponent = require(script.Parent:WaitForChild('ReactWorkTags')).ClassComponent
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName

local exports = {}

exports.logCapturedError = function(boundary: Fiber, errorInfo: CapturedValue<any>)
	local ok, e = pcall(function()
		local logError = showErrorDialog(boundary, errorInfo)

		-- Allow injected showErrorDialog() to prevent default console.error logging.
		-- This enables renderers like ReactNative to better manage redbox behavior.
		if logError == false then
			-- ROBLOX Luau FIXME: needs void return Luau bugfix
			return nil
		end

		local error_ = errorInfo.value
		if _G.__DEV__ then
			local source = errorInfo.source
			local stack = errorInfo.stack
			local componentStack = stack or ""
			-- Browsers support silencing uncaught errors by calling
			-- `preventDefault()` in window `error` handler.
			-- We record this information as an expando on the error.
			if error_ ~= nil and error_._suppressLogging then
				if boundary.tag == ClassComponent then
					-- The error is recoverable and was silenced.
					-- Ignore it and don't print the stack addendum.
					-- This is handy for testing error boundaries without noise.
					return
				end
				-- The error is fatal. Since the silencing might have
				-- been accidental, we'll surface it anyway.
				-- However, the browser would have silenced the original error
				-- so we'll print it first, and then print the stack addendum.
				console["error"](error_) -- Don't transform to our wrapper
				-- For a more detailed description of this block, see:
				-- https://github.com/facebook/react/pull/13384
			end

			local componentName
			if source ~= nil then
				componentName = getComponentName(source.type)
			else
				componentName = nil
			end

			local componentNameMessage
			if componentName then
				componentNameMessage = "The above error occurred in the <"
					.. tostring(componentName)
					.. "> component:"
			else
				componentNameMessage =
					"The above error occurred in one of your React components:"
			end

			local errorBoundaryMessage
			local errorBoundaryName = getComponentName(boundary.type)
			if errorBoundaryName then
				errorBoundaryMessage = "React will try to recreate this component tree from scratch "
					.. "using the error boundary you provided, "
					.. errorBoundaryName
					.. "."
			else
				errorBoundaryMessage = [[Consider adding an error boundary to your tree to customize error handling behavior.
Visit https://reactjs.org/link/error-boundaries to learn more about error boundaries.]]			
end
			local combinedMessage = componentNameMessage
				.. "\n"
				.. componentStack
				.. "\n\n"
				.. errorBoundaryMessage

			-- In development, we provide our own message with just the component stack.
			-- We don't include the original error message and JS stack because the browser
			-- has already printed it. Even if the application swallows the error, it is still
			-- displayed by the browser thanks to the DEV-only fake event trick in ReactErrorUtils.
			console["error"](combinedMessage) -- Don't transform to our wrapper
		else
			-- In production, we print the error directly.
			-- This will include the message, the JS stack, and anything the browser wants to show.
			-- We pass the error object instead of custom message so that the browser displays the error natively.
			console["error"](inspect(error_)) -- Don't transform to our wrapper
		end

		-- ROBLOX Luau FIXME: needs void return Luau bugfix
		return nil
	end)

	if not ok then
		warn("failed to error with error: " .. inspect(e))
		-- ROBLOX TODO: we may need to think about this more deeply and do something different
		-- This method must not throw, or React internal state will get messed up.
		-- If console.error is overridden, or logCapturedError() shows a dialog that throws,
		-- we want to report this error outside of the normal stack as a last resort.
		-- https://github.com/facebook/react/issues/13188
		setTimeout(function()
			-- ROBLOX FIXME: the top-level Luau VM handler doesn't deal with non-string errors, so massage it until VM support lands
			error(errorToString(e :: any))
		end)
	end
end

return exports

end,
["react-reconciler/ReactFiberFlags"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/37cb732c59863297e48f69ac1f6e2ba1aa1886f0/packages/react-reconciler/src/ReactFiberFlags.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

export type Flags = number

local exports = {}

-- Don't change these two values. They're used by React Dev Tools.
exports.NoFlags = --[[                      ]]
	0b000000000000000000
exports.PerformedWork = --[[                ]]
	0b000000000000000001

-- You can change the rest (and add more).
exports.Placement = --[[                    ]]
	0b000000000000000010
exports.Update = --[[                       ]]
	0b000000000000000100
exports.PlacementAndUpdate = --[[           ]]
	0b000000000000000110
exports.Deletion = --[[                     ]]
	0b000000000000001000
exports.ContentReset = --[[                 ]]
	0b000000000000010000
exports.Callback = --[[                     ]]
	0b000000000000100000
exports.DidCapture = --[[                   ]]
	0b000000000001000000
exports.Ref = --[[                          ]]
	0b000000000010000000
exports.Snapshot = --[[                     ]]
	0b000000000100000000
exports.Passive = --[[                      ]]
	0b000000001000000000
-- TODO (effects) Remove this bit once the new reconciler is synced to the old.
exports.PassiveUnmountPendingDev = --[[     ]]
	0b000010000000000000
exports.Hydrating = --[[                    ]]
	0b000000010000000000
exports.HydratingAndUpdate = --[[           ]]
	0b000000010000000100

-- Passive & Update & Callback & Ref & Snapshot
exports.LifecycleEffectMask = --[[          ]]
	0b000000001110100100

-- Union of all host effects
exports.HostEffectMask = --[[               ]]
	0b000000011111111111

-- These are not really side effects, but we still reuse this field.
exports.Incomplete = --[[                   ]]
	0b000000100000000000
exports.ShouldCapture = --[[                ]]
	0b000001000000000000
exports.ForceUpdateForLegacySuspense = --[[ ]]
	0b000100000000000000

-- Static tags describe aspects of a fiber that are not specific to a render,
-- e.g. a fiber uses a passive effect (even if there are no updates on this particular render).
-- This enables us to defer more work in the unmount case,
-- since we can defer traversing the tree during layout to look for Passive effects,
-- and instead rely on the static flag as a signal that there may be cleanup work.
exports.PassiveStatic = --[[                ]]
	0b001000000000000000

-- Union of side effect groupings as pertains to subtreeFlags
exports.BeforeMutationMask = --[[           ]]
	0b000000001100001010
exports.MutationMask = --[[                 ]]
	0b000000010010011110
exports.LayoutMask = --[[                   ]]
	0b000000000010100100
exports.PassiveMask = --[[                  ]]
	0b000000001000001000

-- Union of tags that don't get reset on clones.
-- This allows certain concepts to persist without recalculting them,
-- e.g. whether a subtree contains passive effects or portals.
exports.StaticMask = --[[                   ]]
	0b001000000000000000

-- These flags allow us to traverse to fibers that have effects on mount
-- without traversing the entire tree after every commit for
-- double invoking
exports.MountLayoutDev = --[[               ]]
	0b010000000000000000
exports.MountPassiveDev = --[[              ]]
	0b100000000000000000

return exports

end,
["react-reconciler/ReactFiberHooks.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/43363e2795393a00fd77312a16d6b80e626c29de/packages/react-reconciler/src/ReactFiberHooks.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. message)
	error("FIXME (roblox): " .. message .. " is unimplemented")
end
local __DEV__ = _G.__DEV__ :: boolean
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object

-- ROBLOX: use Bindings to implement useRef
local createRef = require(script.Parent.Parent:WaitForChild('react')).createRef
local createBinding = require(script.Parent.Parent:WaitForChild('react')).createBinding

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactContext<T> = ReactTypes.ReactContext<T>
type ReactBinding<T> = ReactTypes.ReactBinding<T>
type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
type MutableSource<T> = ReactTypes.MutableSource<T>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<
	Source,
	Snapshot
>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type Dispatcher = ReactInternalTypes.Dispatcher
type HookType = ReactInternalTypes.HookType
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane
local ReactHookEffectTags = require(script.Parent:WaitForChild('ReactHookEffectTags'))
type HookFlags = ReactHookEffectTags.HookFlags
type FiberRoot = ReactInternalTypes.FiberRoot
-- ROBLOX TODO: figure out how to expose types through dynamic exports
-- local type {OpaqueIDType} = require("./ReactFiberHostConfig")
type OpaqueIDType = any

local ReactSharedInternals = require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableDebugTracing: boolean? = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler: boolean? = ReactFeatureFlags.enableSchedulingProfiler
local enableNewReconciler: boolean? = ReactFeatureFlags.enableNewReconciler
-- local decoupleUpdatePriorityFromScheduler = ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects

-- local ReactTypeOfMode = require("./ReactTypeOfMode")
local DebugTracingMode = require(script.Parent:WaitForChild('ReactTypeOfMode')).DebugTracingMode
local NoLane = ReactFiberLane.NoLane
local NoLanes = ReactFiberLane.NoLanes
-- local InputContinuousLanePriority = ReactFiberLane.InputContinuousLanePriority
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local mergeLanes = ReactFiberLane.mergeLanes
local removeLanes = ReactFiberLane.removeLanes
local markRootEntangled = ReactFiberLane.markRootEntangled
local markRootMutableRead = ReactFiberLane.markRootMutableRead
-- local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
-- local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
-- local higherLanePriority = ReactFiberLane.higherLanePriority
-- local DefaultLanePriority = ReactFiberLane.DefaultLanePriority
local ReactFiberNewContext = require(script.Parent:WaitForChild('ReactFiberNewContext.new'))
local readContext = ReactFiberNewContext.readContext
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local UpdateEffect = ReactFiberFlags.Update
local PassiveEffect = ReactFiberFlags.Passive
local PassiveStaticEffect = ReactFiberFlags.PassiveStatic
local MountLayoutDevEffect = ReactFiberFlags.MountLayoutDev
local MountPassiveDevEffect = ReactFiberFlags.MountPassiveDev
local HookHasEffect = ReactHookEffectTags.HasEffect
local HookLayout = ReactHookEffectTags.Layout
local HookPassive = ReactHookEffectTags.Passive
local ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new')):: any
local warnIfNotCurrentlyActingUpdatesInDEV =
	ReactFiberWorkLoop.warnIfNotCurrentlyActingUpdatesInDEV
local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local warnIfNotScopedWithMatchingAct = ReactFiberWorkLoop.warnIfNotScopedWithMatchingAct
local requestEventTime = ReactFiberWorkLoop.requestEventTime
local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
local markSkippedUpdateLanes = ReactFiberWorkLoop.markSkippedUpdateLanes
local getWorkInProgressRoot = ReactFiberWorkLoop.getWorkInProgressRoot
local warnIfNotCurrentlyActingEffectsInDEV =
	ReactFiberWorkLoop.warnIfNotCurrentlyActingEffectsInDEV
-- local {
--   getWorkInProgressRoot,
--   requestUpdateLane,
--   requestEventTime,
--   warnIfNotCurrentlyActingEffectsInDEV,
-- } = require("./ReactFiberWorkLoop/new")

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
-- local is = require("@pkg/@jsdotlua/shared").objectIs
local function is(x: any, y: any)
	return x == y and (x ~= 0 or 1 / x == 1 / y) or x ~= x and y ~= y -- eslint-disable-line no-self-compare
end
local markWorkInProgressReceivedUpdate =
	require(script.Parent:WaitForChild('ReactFiberBeginWork.new')).markWorkInProgressReceivedUpdate :: any
-- local {
--   UserBlockingPriority,
--   NormalPriority,
--   runWithPriority,
--   getCurrentPriorityLevel,
-- } = require("./SchedulerWithReactIntegration/new")
local getIsHydrating = require(script.Parent:WaitForChild('ReactFiberHydrationContext.new')).getIsHydrating
-- local {
--   makeClientId,
--   makeClientIdInDEV,
--   makeOpaqueHydratingObject,
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
local makeClientId = ReactFiberHostConfig.makeClientId
-- local makeOpaqueHydratingObject = ReactFiberHostConfig.makeOpaqueHydratingObject
-- local makeClientIdInDEV = ReactFiberHostConfig.makeClientIdInDEV

local ReactMutableSource = require(script.Parent:WaitForChild('ReactMutableSource.new'))
local warnAboutMultipleRenderersDEV = ReactMutableSource.warnAboutMultipleRenderersDEV
local getWorkInProgressVersion = ReactMutableSource.getWorkInProgressVersion
local setWorkInProgressVersion = ReactMutableSource.setWorkInProgressVersion
local markSourceAsDirty = ReactMutableSource.markSourceAsDirty

-- local getIsRendering = require("./ReactCurrentFiber").getIsRendering
local logStateUpdateScheduled = require(script.Parent:WaitForChild('DebugTracing')).logStateUpdateScheduled
local markStateUpdateScheduled = require(script.Parent:WaitForChild('SchedulingProfiler')).markStateUpdateScheduled

local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
-- local ReactCurrentBatchConfig = ReactSharedInternals.ReactCurrentBatchConfig

-- deviation: common types
type Array<T> = { [number]: T }

type Update<S, A> = {
	lane: Lane,
	action: A,
	eagerReducer: ((S, A) -> S) | nil,
	eagerState: S | nil,
	next: Update<S, A>,
	priority: ReactPriorityLevel?
}

type UpdateQueue<S, A> = {
	pending: Update<S, A> | nil,
	dispatch: ((A) -> ...any) | nil,
	lastRenderedReducer: ((S, A) -> S) | nil,
	lastRenderedState: S | nil
}

local didWarnAboutMismatchedHooksForComponent
local _didWarnAboutUseOpaqueIdentifier
if __DEV__ then
	_didWarnAboutUseOpaqueIdentifier = {}
	didWarnAboutMismatchedHooksForComponent = {}
end

export type Hook = {
	memoizedState: any,
	baseState: any,
	baseQueue: Update<any, any> | nil,
	queue: UpdateQueue<any, any> | nil,
	next: Hook?
}

export type Effect = {
	tag: HookFlags,
	-- ROBLOX TODO: this needs Luau type pack support to express accurately
	create: (() -> (() -> ())) | () -> (),
	destroy: (() -> ())?,
	deps: Array<any> | nil,
	next: Effect
}

export type FunctionComponentUpdateQueue = {
	lastEffect: Effect?
}

type BasicStateAction<S> = ((S) -> S) | S

type Dispatch<A> = (A) -> ()

local exports: any = {}

-- These are set right before calling the component.
local renderLanes: Lanes = NoLanes
-- The work-in-progress fiber. I've named it differently to distinguish it from
-- the work-in-progress hook.
local currentlyRenderingFiber: Fiber = nil :: any

-- Hooks are stored as a linked list on the fiber's memoizedState field. The
-- current hook list is the list that belongs to the current fiber. The
-- work-in-progress hook list is a new list that will be added to the
-- work-in-progress fiber.
-- FIXME (roblox): type refinement
-- local currentHook: Hook | nil = nil
local currentHook: any -- FIXME (roblox): type refinement
-- local workInProgressHook: Hook | nil = nil

local workInProgressHook: any 
-- Whether an update was scheduled at any point during the render phase. This
-- does not get reset if we do another render pass; only when we're completely
-- finished evaluating this component. This is an optimization so we know
-- whether we need to clear render phase updates after a throw.

local didScheduleRenderPhaseUpdate: boolean = false
-- Where an update was scheduled only during the current render pass. This
-- gets reset after each attempt.
-- TODO: Maybe there's some way to consolidate this with
-- `didScheduleRenderPhaseUpdate`. Or with `numberOfReRenders`.
local didScheduleRenderPhaseUpdateDuringThisPass: boolean = false

local RE_RENDER_LIMIT = 25

-- In DEV, this is the name of the currently executing primitive hook
local currentHookNameInDev: HookType? 
-- In DEV, this list ensures that hooks are called in the same order between renders.
-- The list stores the order of hooks used during the initial render (mount).
-- Subsequent renders (updates) reference this list.

local hookTypesDev: Array<HookType> | nil 
local hookTypesUpdateIndexDev: number = 0

-- In DEV, this tracks whether currently rendering component needs to ignore
-- the dependencies for Hooks that need them (e.g. useEffect or useMemo).
-- When true, such Hooks will always be "remounted". Only used during hot reload.
-- ROBLOX performance: eliminate unuseful cmp in hot path, we don't currently support hot reloading
local ignorePreviousDependencies: boolean = false

-- Deviation: move to top so below function can reference
local HooksDispatcherOnMountInDEV: Dispatcher | nil 
local HooksDispatcherOnMountWithHookTypesInDEV: Dispatcher | nil 
local HooksDispatcherOnUpdateInDEV: Dispatcher | nil 
local HooksDispatcherOnRerenderInDEV: Dispatcher | nil 
local InvalidNestedHooksDispatcherOnMountInDEV: Dispatcher | nil 
local InvalidNestedHooksDispatcherOnUpdateInDEV: Dispatcher | nil 
local InvalidNestedHooksDispatcherOnRerenderInDEV: Dispatcher | nil 
-- ROBLOX deviation: Used to better compare dependency arrays with gaps

local function getHighestIndex(array: Array<any>)
	local highestIndex = 0
	for k, v in array do
		highestIndex = if k > highestIndex then k else highestIndex
	end
	return highestIndex
end

-- ROBLOX deviation: Used to better detect dependency arrays with gaps, to be
-- used in place of Array.isArray
local function isArrayOrSparseArray(deps: any)
	if type(deps) ~= "table" then
		return false
	end
	for k, _v in deps do
		if type(k) ~= "number" then
			return false
		end
	end
	return true
end

local function mountHookTypesDev()
	if __DEV__ then
		local hookName = (currentHookNameInDev :: any) :: HookType

		if hookTypesDev == nil then
			-- ROBLOX FIXME Luau: needs normalization (I think)
			hookTypesDev = ({ hookName } :: any) :: Array<HookType>
		else
			table.insert(hookTypesDev, hookName)
		end
	end
end

function updateHookTypesDev()
	if __DEV__ then
		-- ROBLOX FIXME Luau: needs normalization (I think) to avoid duplicate type declaration
		local hookName: HookType = (currentHookNameInDev :: any) :: HookType

		if hookTypesDev ~= nil then
			hookTypesUpdateIndexDev += 1
			if hookTypesDev[hookTypesUpdateIndexDev] ~= hookName then
				warnOnHookMismatchInDev(hookName)
			end
		end
	end
end

local function checkDepsAreArrayDev(deps: any)
	if __DEV__ then
		if deps ~= nil and not isArrayOrSparseArray(deps) then
			-- Verify deps, but only on mount to avoid extra checks.
			-- It's unlikely their type would change as usually you define them inline.
			console.error(
[[%s received a final argument that is not an array (instead, received `%s`). When specified, the final argument must be an array.]]
,
				currentHookNameInDev,
				type(deps)
			)
		end
	end
end

function warnOnHookMismatchInDev(currentHookName: HookType)
	if __DEV__ then
		-- ROBLOX deviation: getComponentName will return nil in most Hook cases, use same fallback as elsewhere
		local componentName = getComponentName(currentlyRenderingFiber.type)
			or "Component"
		if not didWarnAboutMismatchedHooksForComponent[componentName] then
			didWarnAboutMismatchedHooksForComponent[componentName] = true

			if hookTypesDev ~= nil then
				local table_ = ""

				local secondColumnStart = 30

				for i = 1, hookTypesUpdateIndexDev do
					local oldHookName = (hookTypesDev :: any)[i]
					local newHookName
					if i == hookTypesUpdateIndexDev then
						newHookName = currentHookName
					else
						newHookName = oldHookName
					end

					-- ROBLOX note: upstream lets this be void and string concat coerces it to 'undefined'
					local row = tostring(i) .. ". " .. (oldHookName or "undefined")

					-- Extra space so second column lines up
					-- lol @ IE not supporting String#repeat
					while string.len(row) < secondColumnStart do
						row ..= " "
					end

					row ..= newHookName .. "\n"

					table_ ..= row
				end

				console.error(
[[React has detected a change in the order of Hooks called by %s. This will lead to bugs and errors if not fixed. For more information, read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks

   Previous render            Next render
   ------------------------------------------------------
%s   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
]]
,
					componentName,
					table_
				)
			end
		end
	end
end

local function throwInvalidHookError(): ()
	error(
		Error.new(
[[Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for one of the following reasons:
1. You might have mismatching versions of React and the renderer (such as React DOM)
2. You might be breaking the Rules of Hooks
3. You might have more than one copy of React in the same app
See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.]]		

)
	)
end

-- FIXME (roblox): type refinement
-- prevDeps: Array<any>?
local function areHookInputsEqual(nextDeps: Array<any>, prevDeps: Array<any>)
	if __DEV__ then
		if ignorePreviousDependencies then
			-- Only true when this component is being hot reloaded.
			return false
		end
	end

	if prevDeps == nil then
		if __DEV__ then
			-- ROBLOX TODO: no unit tests in upstream for this, we should add some
			console.error(
[[%s received a final argument during this render, but not during the previous render. Even though the final argument is optional, its type cannot change between renders.]]

,
				currentHookNameInDev
			)
		end
		return false
	end

	-- ROBLOX deviation START: calculate lengths with iteration instead of # to
	-- accommodate nil values and disable warning for differing lengths
	local nextDepsLength = getHighestIndex(nextDeps)
	local prevDepsLength = getHighestIndex(prevDeps)

	-- ROBLOX note: In upstream, lengths aren't even compared unless dev mode is
	-- enabled because they _always_ indicate a misuse of dependency arrays. In
	-- luau, since trailing `nil`s effectively change the length of the array,
	-- it's possible to trigger this scenario with a valid use of the dependencies
	-- array (e.g. `{1, 2, 3}` -> `{1, 2, nil}`)
	if nextDepsLength ~= prevDepsLength then
		-- ROBLOX TODO: linting like upstream does would make this warning less
		-- necessary, and would help justify our exclusion of the warning.

		-- https://jira.rbx.com/browse/LUAFDN-1175
		-- if __DEV__ then
		--   console.error(
		--     "The final argument passed to %s changed size between renders. The " ..
		--       "order and size of this array must remain constant.\n\n" ..
		--       "Previous: %s\n" ..
		--       "Incoming: %s",
		--     currentHookNameInDev,
		--     inspect(prevDeps),
		--     inspect(nextDeps)
		--   )
		-- end

		-- Short-circuit here since we know that different lengths means a change in
		-- values, even if it's due to trailing nil values
		return false
	end
	-- ROBLOX deviation END

	local minDependencyCount = math.min(prevDepsLength, nextDepsLength)
	for i = 1, minDependencyCount do
		if is(nextDeps[i], prevDeps[i]) then
			continue
		end
		return false
	end
	return true
end

exports.bailoutHooks = function(current: Fiber, workInProgress: Fiber, lanes: Lanes)
	-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
	workInProgress.updateQueue = current.updateQueue
	if __DEV__ and enableDoubleInvokingEffects then
		workInProgress.flags = bit32.band(
			workInProgress.flags,
			bit32.bnot(
				bit32.bor(
					MountPassiveDevEffect,
					PassiveEffect,
					MountLayoutDevEffect,
					UpdateEffect
				)
			)
		)
	else
		workInProgress.flags = bit32.band(
			workInProgress.flags,
			bit32.bnot(bit32.bor(PassiveEffect, UpdateEffect))
		)
	end
	current.lanes = removeLanes(current.lanes, lanes)
end

local _isUpdatingOpaqueValueInRenderPhase = false
exports.resetHooksAfterThrow = function(): ()
	-- We can assume the previous dispatcher is always this one, since we set it
	-- at the beginning of the render phase and there's no re-entrancy.
	ReactCurrentDispatcher.current = exports.ContextOnlyDispatcher

	if didScheduleRenderPhaseUpdate then
		-- There were render phase updates. These are only valid for this render
		-- phase, which we are now aborting. Remove the updates from the queues so
		-- they do not persist to the next render. Do not remove updates from hooks
		-- that weren't processed.
		--
		-- Only reset the updates from the queue if it has a clone. If it does
		-- not have a clone, that means it wasn't processed, and the updates were
		-- scheduled before we entered the render phase.
		-- FIXME (roblox): Better type refinement
		-- local hook: Hook | nil = currentlyRenderingFiber.memoizedState
		local hook: any = currentlyRenderingFiber.memoizedState
		while hook ~= nil do
			local queue = hook.queue
			if queue ~= nil then
				queue.pending = nil
			end
			hook = hook.next
		end
		didScheduleRenderPhaseUpdate = false
	end

	renderLanes = NoLanes
	currentlyRenderingFiber = nil :: any

	currentHook = nil
	workInProgressHook = nil

	if __DEV__ then
		hookTypesDev = nil
		hookTypesUpdateIndexDev = 0

		currentHookNameInDev = nil

		_isUpdatingOpaqueValueInRenderPhase = false
	end

	didScheduleRenderPhaseUpdateDuringThisPass = false
end

local function mountWorkInProgressHook(): Hook
	local hook: Hook = {
		memoizedState = nil,

		baseState = nil,
		baseQueue = nil,
		queue = nil,

		next = nil,
	}

	if workInProgressHook == nil then
		-- This is the first hook in the list
		currentlyRenderingFiber.memoizedState = hook
		workInProgressHook = hook
	else
		-- Append to the end of the list
		workInProgressHook.next = hook
		workInProgressHook = hook
	end
	return workInProgressHook
end

local function updateWorkInProgressHook(): Hook
	-- This function is used both for updates and for re-renders triggered by a
	-- render phase update. It assumes there is either a current hook we can
	-- clone, or a work-in-progress hook from a previous render pass that we can
	-- use as a base. When we reach the end of the base list, we must switch to
	-- the dispatcher used for mounts.
	-- FIXME (roblox): type refinement
	-- local nextCurrentHook: Hook?
	local nextCurrentHook
	if currentHook == nil then
		local current = currentlyRenderingFiber.alternate
		if current ~= nil then
			nextCurrentHook = current.memoizedState
		else
			nextCurrentHook = nil
		end
	else
		nextCurrentHook = currentHook.next
	end

	-- FIXME (roblox): type refinement
	-- local nextWorkInProgressHook: Hook?
	local nextWorkInProgressHook: Hook
	if workInProgressHook == nil then
		nextWorkInProgressHook = currentlyRenderingFiber.memoizedState
	else
		nextWorkInProgressHook = workInProgressHook.next
	end

	if nextWorkInProgressHook ~= nil then
		-- There's already a work-in-progress. Reuse it.
		workInProgressHook = nextWorkInProgressHook
		nextWorkInProgressHook = workInProgressHook.next

		currentHook = nextCurrentHook
	else
		-- Clone from the current hook.

		-- ROBLOX performance: use React 18 check to avoid function call overhead
		if nextCurrentHook == nil then
			error(Error.new("Rendered more hooks than during the previous render."))
		end

		currentHook = nextCurrentHook

		local newHook: Hook = {
			memoizedState = currentHook.memoizedState,

			baseState = currentHook.baseState,
			baseQueue = currentHook.baseQueue,
			queue = currentHook.queue,

			next = nil,
		}

		if workInProgressHook == nil then
			-- This is the first hook in the list.
			workInProgressHook = newHook
			currentlyRenderingFiber.memoizedState = newHook
		else
			-- Append to the end of the list.
			workInProgressHook.next = newHook
			workInProgressHook = newHook
		end
	end
	return workInProgressHook
end

-- ROBLOX performance: inlined in hot path
-- local function createFunctionComponentUpdateQueue(): FunctionComponentUpdateQueue
--   return {
--     lastEffect = nil,
--   }
-- end

function basicStateReducer<S>(state: S, action: BasicStateAction<S>): S
	-- $FlowFixMe: Flow doesn't like mixed types
	if type(action) == "function" then
		return action(state)
	else
		return action
	end
end

function mountReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local hook = mountWorkInProgressHook()
	local initialState
	if init ~= nil then
		initialState = init(initialArg)
	else
		initialState = (initialArg :: any) :: S
	end
	hook.baseState = initialState
	hook.memoizedState = hook.baseState

	local queue: UpdateQueue<S, A> = {
		pending = nil,
		dispatch = nil,
		lastRenderedReducer = reducer,
		lastRenderedState = initialState :: any,
	}
	hook.queue = queue

	-- deviation: set currentlyRenderingFiber to a local varible so it doesn't change
	-- by call time
	local cRF = currentlyRenderingFiber
	-- ROBLOX FIXME? we pass in action here, but is that what really happens upstream?
	local dispatch: Dispatch<A> = function(action, ...)
		-- ROBLOX Luau FIXME: relies on normalization
		dispatchAction(cRF, queue :: UpdateQueue<any, any>, action, ...)
	end :: any
	queue.dispatch = dispatch :: any
	-- ROBLOX deviation START: Lua version of useState and useReducer return two items, not list like upstream
	return hook.memoizedState, dispatch
	-- ROBLOX deviation END: Lua version of useState and useReducer return two items, not list like upstream
end

function updateReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local hook = updateWorkInProgressHook()
	local queue = hook.queue
	-- ROBLOX deviation: change from invariant to avoid funtion call in hot path
	assert(
		queue ~= nil,
		"Should have a queue. This is likely a bug in React. Please file an issue."
	)

	queue.lastRenderedReducer = reducer

	local current: Hook = currentHook

	-- The last rebase update that is NOT part of the base state.
	local baseQueue = current.baseQueue

	-- The last pending update that hasn't been processed yet.
	local pendingQueue = queue.pending
	if pendingQueue ~= nil then
		-- We have new updates that haven't been processed yet.
		-- We'll add them to the base queue.
		if baseQueue ~= nil then
			-- Merge the pending queue and the base queue.
			local baseFirst = baseQueue.next
			local pendingFirst = pendingQueue.next
			baseQueue.next = pendingFirst
			pendingQueue.next = baseFirst
		end
		-- ROBLOX performance: elimiante cmp in hot path
		-- if __DEV__ then
		--   if current.baseQueue ~= baseQueue then
		--     -- Internal invariant that should never happen, but feasibly could in
		--     -- the future if we implement resuming, or some form of that.
		--     console.error(
		--       'Internal error: Expected work-in-progress queue to be a clone. ' ..
		--         'This is a bug in React.'
		--     )
		--   end
		-- end
		baseQueue = pendingQueue
		current.baseQueue = baseQueue
		queue.pending = nil
	end

	if baseQueue ~= nil then
		-- We have a queue to process.
		local first = baseQueue.next
		local newState = current.baseState

		local newBaseState 		
local newBaseQueueFirst 		
local newBaseQueueLast 		
local update = first
		repeat
			local updateLane = update.lane
			-- ROBLOX performance: inline isSubsetOfLanes for hot path
			-- if not isSubsetOfLanes(renderLanes, updateLane) then
			if bit32.band(renderLanes, updateLane) ~= updateLane then
				-- Priority is insufficient. Skip this update. If this is the first
				-- skipped update, the previous update/state is the new base
				-- update/state.
				local clone: Update<S, A> = {
					lane = updateLane,
					action = update.action,
					eagerReducer = update.eagerReducer,
					eagerState = update.eagerState,
					next = nil :: any,
				}
				if newBaseQueueLast == nil then
					newBaseQueueLast = clone
					newBaseQueueFirst = newBaseQueueLast
					newBaseState = newState
				else
					newBaseQueueLast.next = clone
					newBaseQueueLast = newBaseQueueLast.next
				end
				-- Update the remaining priority in the queue.
				-- TODO: Don't need to accumulate this. Instead, we can remove
				-- renderLanes from the original lanes.
				currentlyRenderingFiber.lanes =
					mergeLanes(currentlyRenderingFiber.lanes, updateLane)
				markSkippedUpdateLanes(updateLane)
			else
				-- This update does have sufficient priority.

				if newBaseQueueLast ~= nil then
					local clone: Update<S, A> = {
						-- This update is going to be committed so we never want uncommit
						-- it. Using NoLane works because 0 is a subset of all bitmasks, so
						-- this will never be skipped by the check above.
						lane = NoLane,
						action = update.action,
						eagerReducer = update.eagerReducer,
						eagerState = update.eagerState,
						next = nil :: any,
					}
					newBaseQueueLast.next = clone
					newBaseQueueLast = newBaseQueueLast.next
				end

				-- Process this update.
				if update.eagerReducer == reducer then
					-- If this update was processed eagerly, and its reducer matches the
					-- current reducer, we can use the eagerly computed state.
					newState = update.eagerState
				else
					local action = update.action
					newState = reducer(newState, action)
				end
			end
			update = update.next
		until update == nil or update == first

		if newBaseQueueLast == nil then
			newBaseState = newState
		else
			newBaseQueueLast.next = newBaseQueueFirst
		end

		-- Mark that the fiber performed work, but only if the new state is
		-- different from the current state.
		if not is(newState, hook.memoizedState) then
			markWorkInProgressReceivedUpdate()
		end

		hook.memoizedState = newState
		hook.baseState = newBaseState
		hook.baseQueue = newBaseQueueLast

		queue.lastRenderedState = newState
	end

	local dispatch: Dispatch<A> = queue.dispatch :: any
	-- deviation: Lua version of useState and useReducer return two items, not list like upstream
	return hook.memoizedState, dispatch
end

function rerenderReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local hook = updateWorkInProgressHook()
	local queue = hook.queue
	-- ROBLOX performance: changed from invariant to avoid function call in hot path
	assert(
		queue ~= nil,
		"Should have a queue. This is likely a bug in React. Please file an issue."
	)

	queue.lastRenderedReducer = reducer

	-- This is a re-render. Apply the new render phase updates to the previous
	-- work-in-progress hook.
	local dispatch: Dispatch<A> = queue.dispatch :: Dispatch<A>
	local lastRenderPhaseUpdate = queue.pending
	local newState = hook.memoizedState
	if lastRenderPhaseUpdate ~= nil then
		-- The queue doesn't persist past this render pass.
		queue.pending = nil

		local firstRenderPhaseUpdate = lastRenderPhaseUpdate.next
		local update = firstRenderPhaseUpdate
		repeat
			-- Process this render phase update. We don't have to check the
			-- priority because it will always be the same as the current
			-- render's.
			local action = update.action
			newState = reducer(newState, action)
			update = update.next
		until update == firstRenderPhaseUpdate

		-- Mark that the fiber performed work, but only if the new state is
		-- different from the current state.
		if not is(newState, hook.memoizedState) then
			markWorkInProgressReceivedUpdate()
		end

		hook.memoizedState = newState
		-- Don't persist the state accumulated from the render phase updates to
		-- the base state unless the queue is empty.
		-- TODO: Not sure if this is the desired semantics, but it's what we
		-- do for gDSFP. I can't remember why.
		if hook.baseQueue == nil then
			hook.baseState = newState
		end

		queue.lastRenderedState = newState
	end
	-- ROBLOX deviation: Lua version returns two values instead of an array
	return newState, dispatch
end

type MutableSourceMemoizedState<Source, Snapshot> = {
	refs: {
		getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
		setSnapshot: (Snapshot) -> ()	
},
	source: MutableSource<any>,
	subscribe: MutableSourceSubscribeFn<Source, Snapshot>
}

function readFromUnsubcribedMutableSource<Source, Snapshot>(
	root: FiberRoot,
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>
): Snapshot
	if __DEV__ then
		warnAboutMultipleRenderersDEV(source)
	end

	local getVersion = source._getVersion
	local version_ = getVersion(source._source)

	-- Is it safe for this component to read from this source during the current render?
	local isSafeToReadFromSource = false

	-- Check the version first.
	-- If this render has already been started with a specific version,
	-- we can use it alone to determine if we can safely read from the source.
	local currentRenderVersion = getWorkInProgressVersion(source)
	if currentRenderVersion ~= nil then
		-- It's safe to read if the store hasn't been mutated since the last time
		-- we read something.
		isSafeToReadFromSource = currentRenderVersion == version_
	else
		-- If there's no version, then this is the first time we've read from the
		-- source during the current render pass, so we need to do a bit more work.
		-- What we need to determine is if there are any hooks that already
		-- subscribed to the source, and if so, whether there are any pending
		-- mutations that haven't been synchronized yet.
		--
		-- If there are no pending mutations, then `root.mutableReadLanes` will be
		-- empty, and we know we can safely read.
		--
		-- If there *are* pending mutations, we may still be able to safely read
		-- if the currently rendering lanes are inclusive of the pending mutation
		-- lanes, since that guarantees that the value we're about to read from
		-- the source is consistent with the values that we read during the most
		-- recent mutation.
		isSafeToReadFromSource = isSubsetOfLanes(renderLanes, root.mutableReadLanes)

		if isSafeToReadFromSource then
			-- If it's safe to read from this source during the current render,
			-- store the version in case other components read from it.
			-- A changed version number will local those components know to throw and restart the render.
			setWorkInProgressVersion(source, version_)
		end
	end

	if isSafeToReadFromSource then
		local snapshot = getSnapshot(source._source)
		if __DEV__ then
			-- ROBLOX deviation: the Snapshot generic isn't constrained upstream, but it as to be for this typeof() to work
			if type(snapshot :: any) == "function" then
				console.error(
[[Mutable source should not return a function as the snapshot value. Functions may close over mutable values and cause tearing.]]				

)
			end
		end
		return snapshot
	else
		-- This handles the special case of a mutable source being shared between renderers.
		-- In that case, if the source is mutated between the first and second renderer,
		-- The second renderer don't know that it needs to reset the WIP version during unwind,
		-- (because the hook only marks sources as dirty if it's written to their WIP version).
		-- That would cause this tear check to throw again and eventually be visible to the user.
		-- We can avoid this infinite loop by explicitly marking the source as dirty.
		--
		-- This can lead to tearing in the first renderer when it resumes,
		-- but there's nothing we can do about that (short of throwing here and refusing to continue the render).
		markSourceAsDirty(source)

		error(
			Error.new(
				"Cannot read from mutable source during the current render without tearing. This is a bug in React. Please file an issue."
			)
		)
	end
end

function useMutableSource<Source, Snapshot>(
	hook: Hook,
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>,
	subscribe: MutableSourceSubscribeFn<
		Source,
		Snapshot
	>
): Snapshot
	local root: FiberRoot = getWorkInProgressRoot()
	invariant(
		root ~= nil,
		"Expected a work-in-progress root. This is a bug in React. Please file an issue."
	)

	local getVersion = source._getVersion
	local version_ = getVersion(source._source)

	local dispatcher = ReactCurrentDispatcher.current
	-- ROBLOX deviation: upstream doesn't assert non-nil, but we have to for type soundness
	assert(dispatcher ~= nil, "dispatcher was nil, this is a bug in React")
	-- eslint-disable-next-line prefer-const
	local currentSnapshot, setSnapshot = dispatcher.useState(function()
		return readFromUnsubcribedMutableSource(root, source, getSnapshot)
	end)
	local snapshot = currentSnapshot

	-- Grab a handle to the state hook as well.
	-- We use it to clear the pending update queue if we have a new source.

	-- ROBLOX TODO: recast local stateHook = ((workInProgressHook: any): Hook)
	local stateHook = workInProgressHook

	local memoizedState: MutableSourceMemoizedState<any, any> = hook.memoizedState
	if memoizedState.refs == nil then
		error(tostring(debug.traceback()))
	end
	local refs = memoizedState.refs
	local prevGetSnapshot = refs.getSnapshot
	local prevSource = memoizedState.source
	local prevSubscribe = memoizedState.subscribe

	local fiber = currentlyRenderingFiber

	hook.memoizedState = {
		refs = refs,
		source = source,
		subscribe = subscribe,
	}

	-- Sync the values needed by our subscription handler after each commit.
	dispatcher.useEffect(function()
		refs.getSnapshot = getSnapshot

		-- Normally the dispatch function for a state hook never changes,
		-- but this hook recreates the queue in certain cases  to avoid updates from stale sources.
		-- handleChange() below needs to reference the dispatch function without re-subscribing,
		-- so we use a ref to ensure that it always has the latest version.
		refs.setSnapshot = setSnapshot

		-- Check for a possible change between when we last rendered now.
		local maybeNewVersion = getVersion(source._source)
		if not is(version_, maybeNewVersion) then
			local maybeNewSnapshot = getSnapshot(source._source)
			if __DEV__ then
				-- ROBLOX deviation: the Snapshot generic isn't constrained upstream, but it as to be for this typeof() to work
				if type(maybeNewSnapshot :: any) == "function" then
					console.error(
[[Mutable source should not return a function as the snapshot value. Functions may close over mutable values and cause tearing.]]					

)
				end
			end

			if not is(snapshot, maybeNewSnapshot) then
				setSnapshot(maybeNewSnapshot)

				local lane = requestUpdateLane(fiber)
				markRootMutableRead(root, lane)
			end
			-- If the source mutated between render and now,
			-- there may be state updates already scheduled from the old source.
			-- Entangle the updates so that they render in the same batch.
			markRootEntangled(root, root.mutableReadLanes)
		end
		-- ROBLOX Luau FIXME: Luau doesn't support mixed arrays
	end, { getSnapshot, source, subscribe } :: Array<any>)

	-- If we got a new source or subscribe function, re-subscribe in a passive effect.
	dispatcher.useEffect(function()
		local handleChange = function()
			local latestGetSnapshot = refs.getSnapshot
			local latestSetSnapshot = refs.setSnapshot

			-- ROBLOX performance? only latestGet..() is throwable. hoist the rest out to eliminate anon func overhead?
			local ok, result = pcall(function()
				latestSetSnapshot(latestGetSnapshot(source._source))

				-- Record a pending mutable source update with the same expiration time.
				local lane = requestUpdateLane(fiber)

				markRootMutableRead(root, lane)
			end)

			if not ok then
				-- A selector might throw after a source mutation.
				-- e.g. it might try to read from a part of the store that no longer exists.
				-- In this case we should still schedule an update with React.
				-- Worst case the selector will throw again and then an error boundary will handle it.
				latestSetSnapshot(function()
					error(result)
				end)
			end
		end

		local unsubscribe = subscribe(source._source, handleChange)
		if __DEV__ then
			if type(unsubscribe) ~= "function" then
				console.error(
					"Mutable source subscribe function must return an unsubscribe function."
				)
			end
		end

		return unsubscribe
		-- ROBLOX Luau FIXME: Luau doesn't support mixed arrays
	end, { source, subscribe } :: Array<any>)

	-- If any of the inputs to useMutableSource change, reading is potentially unsafe.
	--
	-- If either the source or the subscription have changed we can't can't trust the update queue.
	-- Maybe the source changed in a way that the old subscription ignored but the new one depends on.
	--
	-- If the getSnapshot function changed, we also shouldn't rely on the update queue.
	-- It's possible that the underlying source was mutated between the when the last "change" event fired,
	-- and when the current render (with the new getSnapshot function) is processed.
	--
	-- In both cases, we need to throw away pending updates (since they are no longer relevant)
	-- and treat reading from the source as we do in the mount case.
	if
		not is(prevGetSnapshot, getSnapshot)
		or not is(prevSource, source)
		or not is(prevSubscribe, subscribe)
	then
		-- Create a new queue and setState method,
		-- So if there are interleaved updates, they get pushed to the older queue.
		-- When this becomes current, the previous queue and dispatch method will be discarded,
		-- including any interleaving updates that occur.
		local newQueue = {
			pending = nil,
			dispatch = nil,
			lastRenderedReducer = basicStateReducer,
			lastRenderedState = snapshot,
		}

		-- ROBLOX deviation: keep local pointer so if global changes we maintain correct reference.
		local cRF = currentlyRenderingFiber

		setSnapshot = function(...)
			dispatchAction(cRF, newQueue, ...)
		end :: any
		newQueue.dispatch = setSnapshot :: any
		stateHook.queue = newQueue
		stateHook.baseQueue = nil
		snapshot = readFromUnsubcribedMutableSource(root, source, getSnapshot)
		stateHook.baseState = snapshot
		stateHook.memoizedState = stateHook.baseState
	end

	return snapshot
end

function mountMutableSource<Source, Snapshot>(
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>,
	subscribe: MutableSourceSubscribeFn<
		Source,
		Snapshot
	>
): Snapshot
	local hook = mountWorkInProgressHook()
	hook.memoizedState = {
		refs = {
			getSnapshot = getSnapshot,
			setSnapshot = nil,
		},
		source = source,
		subscribe = subscribe,
	}
	return useMutableSource(hook, source, getSnapshot, subscribe)
end

function updateMutableSource<Source, Snapshot>(
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>,
	subscribe: MutableSourceSubscribeFn<
		Source,
		Snapshot
	>
): Snapshot
	local hook = updateWorkInProgressHook()
	return useMutableSource(hook, source, getSnapshot, subscribe)
end

function mountState<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
	local hook = mountWorkInProgressHook()
	if type(initialState) == "function" then
		-- $FlowFixMe: Flow doesn't like mixed types
		-- deviation: workaround to silence cli analyze not understanding that we've already verified initialState is a function
		local initialStateAsFunction: () -> S = initialState
		initialState = initialStateAsFunction()
	end
	hook.baseState = initialState
	hook.memoizedState = hook.baseState
	local queue: UpdateQueue<S, BasicStateAction<S>> = {
		pending = nil,
		dispatch = nil,
		lastRenderedReducer = nil, --basicStateReducer,
		lastRenderedState = initialState :: any,
	}
	-- ROBLOX Luau FIXME: work around a toposorting issue in Luau: CLI-48752
	queue.lastRenderedReducer = basicStateReducer
	hook.queue = queue

	-- ROBLOX deviation: set currentlyRenderingFiber to a local varible so it doesn't change by call time
	local cRF = currentlyRenderingFiber
	local dispatch: Dispatch<BasicStateAction<S>> = function(action, ...)
		-- ROBLOX FIXME? we pass in action here, but is that what really happens upstream?
		dispatchAction(cRF, queue :: UpdateQueue<any, any>, action, ...)
	end :: any
	queue.dispatch = dispatch
	-- deviation: Lua version of useState and useReducer return two items, not list like upstream
	return hook.memoizedState, dispatch
end

function updateState<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
	return updateReducer(basicStateReducer, initialState)
end

function rerenderState<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
	return rerenderReducer(basicStateReducer, initialState)
end

local function pushEffect(tag, create, destroy, deps)
	local effect: Effect = {
		tag = tag,
		create = create,
		destroy = destroy,
		deps = deps,
		-- Circular
		next = nil :: any,
	}
	local componentUpdateQueue: FunctionComponentUpdateQueue =
		currentlyRenderingFiber.updateQueue :: any
	if componentUpdateQueue == nil then
		-- ROBLOX performance: inline simple function in hot path
		-- componentUpdateQueue = createFunctionComponentUpdateQueue()
		componentUpdateQueue = {
			lastEffect = nil,
		}
		currentlyRenderingFiber.updateQueue = componentUpdateQueue
		effect.next = effect
		componentUpdateQueue.lastEffect = effect
	else
		local lastEffect = componentUpdateQueue.lastEffect
		if lastEffect == nil then
			componentUpdateQueue.lastEffect = effect
			effect.next = effect
		else
			local firstEffect = lastEffect.next
			lastEffect.next = effect
			effect.next = firstEffect
			componentUpdateQueue.lastEffect = effect
		end
	end
	return effect
end

-- ROBLOX deviation: Bindings are a feature unique to Roact
function mountBinding<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
	local hook = mountWorkInProgressHook()
	local value, updateValue = createBinding(initialValue)

	-- ROBLOX Luau FIXME: Luau doesn't allow mixed arrays, forcing us to use any here
	hook.memoizedState = { value :: any, updateValue :: any }
	return value, updateValue
end

function updateBinding<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
	local hook = updateWorkInProgressHook()
	return unpack(hook.memoizedState)
end

function mountRef<T>(initialValue: T): { current: T }
	local hook = mountWorkInProgressHook()
	-- ROBLOX DEVIATION: Implement useRef with bindings
	local ref: any = createRef()
	ref.current = initialValue
	-- if (__DEV__) then
	--   Object.seal(ref)
	-- end
	hook.memoizedState = ref
	return ref
end

function updateRef<T>(initialValue: T): { current: T }
	local hook = updateWorkInProgressHook()
	return hook.memoizedState
end

local function mountEffectImpl(fiberFlags, hookFlags, create, deps): ()
	local hook = mountWorkInProgressHook()
	-- deviation: no need to account for undefined
	-- local nextDeps = deps == undefined ? nil : deps
	local nextDeps = deps
	currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags, fiberFlags)

	hook.memoizedState =
		pushEffect(bit32.bor(HookHasEffect, hookFlags), create, nil, nextDeps)
end

-- ROBLOX deviation START: must explicitly mark deps argument as optional/nil-able
function updateEffectImpl(fiberFlags, hookFlags, create, deps: Array<any>?): ()
	-- ROBLOX deviation END
	local hook = updateWorkInProgressHook()
	-- ROBLOX deviation: no need to account for undefined
	-- local nextDeps = deps == undefined ? nil : deps
	local nextDeps = deps
	local destroy

	if currentHook ~= nil then
		local prevEffect = currentHook.memoizedState
		destroy = prevEffect.destroy
		if nextDeps ~= nil then
			local prevDeps = prevEffect.deps
			if areHookInputsEqual(nextDeps, prevDeps) then
				hook.memoizedState = pushEffect(hookFlags, create, destroy, nextDeps)
				return
			end
		end
	end

	currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags, fiberFlags)

	hook.memoizedState =
		pushEffect(bit32.bor(HookHasEffect, hookFlags), create, destroy, nextDeps)
end

local function mountEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	if __DEV__ then
		-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ as well as jest
		-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
		if type(_G.jest) ~= "nil" or _G.__TESTEZ_RUNNING_TEST__ then
			warnIfNotCurrentlyActingEffectsInDEV(currentlyRenderingFiber)
		end
	end

	if __DEV__ and enableDoubleInvokingEffects then
		mountEffectImpl(
			bit32.bor(MountPassiveDevEffect, PassiveEffect, PassiveStaticEffect),
			HookPassive,
			create,
			deps
		)
	else
		mountEffectImpl(
			bit32.bor(PassiveEffect, PassiveStaticEffect),
			HookPassive,
			create,
			deps
		)
	end
end

local function updateEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	if __DEV__ then
		-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ in addition to jest
		-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
		if type(_G.jest) ~= "nil" or _G.__TESTEZ_RUNNING_TEST__ then
			warnIfNotCurrentlyActingEffectsInDEV(currentlyRenderingFiber)
		end
	end
	updateEffectImpl(PassiveEffect, HookPassive, create, deps)
end

local function mountLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	if __DEV__ and enableDoubleInvokingEffects then
		mountEffectImpl(
			bit32.bor(MountLayoutDevEffect, UpdateEffect),
			HookLayout,
			create,
			deps
		)
	else
		mountEffectImpl(UpdateEffect, HookLayout, create, deps)
	end
end

local function updateLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	updateEffectImpl(UpdateEffect, HookLayout, create, deps)
end

function imperativeHandleEffect<T>(
	create: () -> T,
	ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil
	-- ROBLOX deviation: explicit type annotation needed due to mixed return
): nil | () -> ...any
	if ref ~= nil and type(ref) == "function" then
		local refCallback = ref
		local inst = create()
		refCallback(inst)
		return function()
			return refCallback(nil)
		end
	elseif ref ~= nil then
		local refObject = ref :: any
		-- ROBLOX deviation: can't check for key presence because nil is a legitimate value.
		if __DEV__ then
			-- ROBLOX FIXME: This is a clumsy approximation, since we don't have any
			-- explicit way to know that something is a ref object; instead, we check
			-- that it's an empty object with a metatable, which is what Roact refs
			-- look like since they indirect to bindings via their metatable
			local isRefObject = getmetatable(refObject) ~= nil
				and #Object.keys(refObject) == 0
			if not isRefObject then
				console.error(
[[Expected useImperativeHandle() first argument to either be a ref callback or React.createRef() object. Instead received: %s.]]
,
					"an object with keys {"
						.. Array.join(Object.keys(refObject), ", ")
						.. "}"
				)
			end
		end
		local inst = create()
		refObject.current = inst
		return function()
			refObject.current = nil
		end
	-- deviation: explicit return to silence analyze
	else
		return nil
	end
end

function mountImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
	create: () -> T,
	deps: Array<any> | nil
): ()
	if __DEV__ then
		if type(create) ~= "function" then
			console.error(
[[Expected useImperativeHandle() second argument to be a function that creates a handle. Instead received: %s.]]
,
				-- ROBLOX deviation START: nil instead of null
				if create ~= nil then type(create) else "nil"
				-- ROBLOX deviation END
			)
		end
	end
	-- TODO: If deps are provided, should we skip comparing the ref itself?
	local effectDeps = if deps ~= nil then Array.concat(deps, { ref }) else nil

	if __DEV__ and enableDoubleInvokingEffects then
		return mountEffectImpl(
			bit32.bor(MountLayoutDevEffect, UpdateEffect),
			HookLayout,
			function()
				return imperativeHandleEffect(create, ref)
			end,
			effectDeps
		)
	else
		return mountEffectImpl(UpdateEffect, HookLayout, function()
			return imperativeHandleEffect(create, ref)
		end, effectDeps)
	end
end

function updateImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
	create: () -> T,
	deps: Array<any> | nil
): ()
	if __DEV__ then
		if type(create) ~= "function" then
			local errorArg = "nil"
			if create then
				errorArg = type(create)
			end
			console.error(
[[Expected useImperativeHandle() second argument to be a function that creates a handle. Instead received: %s.]]
,
				errorArg
			)
		end
	end

	-- TODO: If deps are provided, should we skip comparing the ref itself?
	-- ROBLOX deviation: ternary turned to explicit if/else
	local effectDeps
	if deps ~= nil then
		effectDeps = table.clone(deps)
		table.insert(effectDeps, ref)
	end

	return updateEffectImpl(UpdateEffect, HookLayout, function()
		return imperativeHandleEffect(create, ref)
	end, effectDeps)
end

function mountDebugValue<T>(value: T, formatterFn: nil | (T) -> any): ()
	-- This hook is normally a no-op.
	-- The react-debug-hooks package injects its own implementation
	-- so that e.g. DevTools can display custom hook values.
end

local updateDebugValue = mountDebugValue

function mountCallback<T>(callback: T, deps: Array<any> | nil): T
	local hook = mountWorkInProgressHook()
	local nextDeps = deps
	-- ROBLOX Luau FIXME: Luau doesn't allow mixed arrays, forcing us to use any here
	hook.memoizedState = { callback :: any, nextDeps :: any }
	return callback
end

function updateCallback<T>(callback: T, deps: Array<any> | nil): T
	local hook = updateWorkInProgressHook()
	local nextDeps = deps
	local prevState = hook.memoizedState
	if prevState ~= nil then
		if nextDeps ~= nil then
			-- ROBLOX TODO: Luau false positive when this is `Array<any>?` (E001) Type 'Array<any>?' could not be converted into 'Array<any>'
			local prevDeps: Array<any> = prevState[2]
			if areHookInputsEqual(nextDeps, prevDeps) then
				return prevState[1]
			end
		end
	end
	-- ROBLOX Luau FIXME: Luau doesn't allow mixed arrays, forcing us to use any here
	hook.memoizedState = { callback :: any, nextDeps :: any }
	return callback
end

-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
function mountMemo<T...>(nextCreate: () -> T..., deps: Array<any> | nil): ...any
	local hook = mountWorkInProgressHook()

	-- deviation: equivilant to upstream ternary logic
	local nextDeps = deps
	-- ROBLOX DEVIATION: Wrap memoized values in a table and unpack to allow for multiple return values
	local nextValue = { nextCreate() }
	hook.memoizedState = { nextValue :: any, nextDeps }
	return unpack(nextValue)
end

-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
function updateMemo<T...>(nextCreate: () -> T..., deps: Array<any> | nil): ...any
	local hook = updateWorkInProgressHook()
	-- deviation: equivilant to upstream ternary logic
	local nextDeps = deps
	local prevState = hook.memoizedState
	if prevState ~= nil then
		-- Assume these are defined. If they're not, areHookInputsEqual will warn.
		if nextDeps ~= nil then
			local prevDeps: Array<any> = prevState[2]
			if areHookInputsEqual(nextDeps, prevDeps) then
				return unpack(prevState[1])
			end
		end
	end
	-- ROBLOX DEVIATION: Wrap memoized values in a table and unpack to allow for multiple return values
	local nextValue = { nextCreate() }
	hook.memoizedState = { nextValue :: any, nextDeps }
	return unpack(nextValue)
end

-- function mountDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = mountState(value)
--   mountEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function updateDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = updateState(value)
--   updateEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function rerenderDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = rerenderState(value)
--   updateEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function startTransition(setPending, callback)
--   local priorityLevel = getCurrentPriorityLevel()
--   if decoupleUpdatePriorityFromScheduler)
--     local previousLanePriority = getCurrentUpdateLanePriority()
--     setCurrentUpdateLanePriority(
--       higherLanePriority(previousLanePriority, InputContinuousLanePriority),
--     )

--     runWithPriority(
--       priorityLevel < UserBlockingPriority
--         ? UserBlockingPriority
--         : priorityLevel,
--       () => {
--         setPending(true)
--       },
--     )

--     -- TODO: Can remove this. Was only necessary because we used to give
--     -- different behavior to transitions without a config object. Now they are
--     -- all treated the same.
--     setCurrentUpdateLanePriority(DefaultLanePriority)

--     runWithPriority(
--       priorityLevel > NormalPriority ? NormalPriority : priorityLevel,
--       () => {
--         local prevTransition = ReactCurrentBatchConfig.transition
--         ReactCurrentBatchConfig.transition = 1
--         try {
--           setPending(false)
--           callback()
--         } finally {
--           if decoupleUpdatePriorityFromScheduler)
--             setCurrentUpdateLanePriority(previousLanePriority)
--           end
--           ReactCurrentBatchConfig.transition = prevTransition
--         end
--       },
--     )
--   } else {
--     runWithPriority(
--       priorityLevel < UserBlockingPriority
--         ? UserBlockingPriority
--         : priorityLevel,
--       () => {
--         setPending(true)
--       },
--     )

--     runWithPriority(
--       priorityLevel > NormalPriority ? NormalPriority : priorityLevel,
--       () => {
--         local prevTransition = ReactCurrentBatchConfig.transition
--         ReactCurrentBatchConfig.transition = 1
--         try {
--           setPending(false)
--           callback()
--         } finally {
--           ReactCurrentBatchConfig.transition = prevTransition
--         end
--       },
--     )
--   end
-- end

-- function mountTransition(): [(() => void) => void, boolean] {
--   local [isPending, setPending] = mountState(false)
--   -- The `start` method can be stored on a ref, since `setPending`
--   -- never changes.
--   local start = startTransition.bind(null, setPending)
--   mountRef(start)
--   return [start, isPending]
-- end

-- function updateTransition(): [(() => void) => void, boolean] {
--   local [isPending] = updateState(false)
--   local startRef = updateRef()
--   local start: (() => void) => void = (startRef.current: any)
--   return [start, isPending]
-- end

-- function rerenderTransition(): [(() => void) => void, boolean] {
--   local [isPending] = rerenderState(false)
--   local startRef = updateRef()
--   local start: (() => void) => void = (startRef.current: any)
--   return [start, isPending]
-- end

local isUpdatingOpaqueValueInRenderPhase = false
exports.getIsUpdatingOpaqueValueInRenderPhaseInDEV = function(): boolean?
	if __DEV__ then
		return isUpdatingOpaqueValueInRenderPhase
	end
	return nil
end

-- function warnOnOpaqueIdentifierAccessInDEV(fiber)
--   if __DEV__ then
--     -- TODO: Should warn in effects and callbacks, too
--     local name = getComponentName(fiber.type) or 'Unknown'
--     if getIsRendering() and not didWarnAboutUseOpaqueIdentifier[name] then
--       console.error(
--         'The object passed back from useOpaqueIdentifier is meant to be ' ..
--           'passed through to attributes only. Do not read the ' ..
--           'value directly.'
--       )
--       didWarnAboutUseOpaqueIdentifier[name] = true
--     end
--   end
-- end

function mountOpaqueIdentifier()
	local makeId
	if __DEV__ then
		console.warn("!!! unimplemented: warnOnOpaqueIdentifierAccessInDEV")
	-- makeId = makeClientIdInDEV.bind(
	--     nil,
	--     warnOnOpaqueIdentifierAccessInDEV.bind(null, currentlyRenderingFiber),
	--   )
	else
		makeId = makeClientId
	end

	if getIsHydrating() then
		unimplemented("ReactFiberHooks: getIsHydrating() true")
		return nil
	--   local didUpgrade = false
	--   local fiber = currentlyRenderingFiber
	--   local readValue = function()
	--     if not didUpgrade then
	--       -- Only upgrade once. This works even inside the render phase because
	--       -- the update is added to a shared queue, which outlasts the
	--       -- in-progress render.
	--       didUpgrade = true
	--       if __DEV__ then
	--         isUpdatingOpaqueValueInRenderPhase = true
	--         setId(makeId())
	--         isUpdatingOpaqueValueInRenderPhase = false
	--         warnOnOpaqueIdentifierAccessInDEV(fiber)
	--       else
	--         setId(makeId())
	--       end
	--     end
	--     invariant(
	--       false,
	--       'The object passed back from useOpaqueIdentifier is meant to be ' ..
	--         'passed through to attributes only. Do not read the value directly.'
	--     )
	--   end
	--   local id = makeOpaqueHydratingObject(readValue)

	--   local setId = mountState(id)[1]

	--   if bit32.band(currentlyRenderingFiber.mode, ReactTypeOfMode.BlockingMode) == ReactTypeOfMode.NoMode then
	--     if __DEV__ and enableDoubleInvokingEffects then
	--       currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags,
	--         MountPassiveDevEffect, PassiveEffect, PassiveStaticEffect)
	--     else
	--       currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags,
	-- 				PassiveEffect, PassiveStaticEffect)
	--     end
	--     pushEffect(
	--       bit32.bor(HookHasEffect, HookPassive),
	--       function()
	--         setId(makeId())
	-- 			end,
	--       nil,
	--       nil
	--     )
	--   end
	--   return id
	else
		local id = makeId()
		mountState(id)
		return id
	end
end

function updateOpaqueIdentifier(): OpaqueIDType
	local id, _ = updateState(nil)
	return id
end

function rerenderOpaqueIdentifier(): OpaqueIDType
	local id, _ = rerenderState(nil)
	return id
end

function dispatchAction<S, A>(fiber: Fiber, queue: UpdateQueue<S, A>, action: A, ...): ()
	if __DEV__ then
		local childrenLength = select("#", ...)
		local extraArg
		if childrenLength == 1 then
			extraArg = select(1, ...)
		end
		if type(extraArg) == "function" then
			console.error(
[[State updates from the useState() and useReducer() Hooks don't support the second callback argument. To execute a side effect after rendering, declare it in the component body with useEffect().]]			


)
		end
	end

	local eventTime = requestEventTime()
	local lane = requestUpdateLane(fiber)

	local update: Update<S, A> = {
		lane = lane,
		action = action,
		eagerReducer = nil,
		eagerState = nil,
		next = nil :: any,
	}

	-- Append the update to the end of the list.
	local pending = queue.pending
	if pending == nil then
		-- This is the first update. Create a circular list.
		update.next = update
	else
		update.next = pending.next
		pending.next = update
	end
	queue.pending = update

	local alternate = fiber.alternate
	if
		fiber == currentlyRenderingFiber
		or (alternate ~= nil and alternate == currentlyRenderingFiber)
	then
		-- This is a render phase update. Stash it in a lazily-created map of
		-- queue -> linked list of updates. After this render pass, we'll restart
		-- and apply the stashed updates on top of the work-in-progress hook.
		didScheduleRenderPhaseUpdate = true
		didScheduleRenderPhaseUpdateDuringThisPass = true
	else
		if
			fiber.lanes == NoLanes and (alternate == nil or alternate.lanes == NoLanes)
		then
			-- The queue is currently empty, which means we can eagerly compute the
			-- next state before entering the render phase. If the new state is the
			-- same as the current state, we may be able to bail out entirely.
			local lastRenderedReducer = queue.lastRenderedReducer
			if lastRenderedReducer ~= nil then
				local prevDispatcher
				if __DEV__ then
					prevDispatcher = ReactCurrentDispatcher.current
					ReactCurrentDispatcher.current =
						InvalidNestedHooksDispatcherOnUpdateInDEV
				end
				-- ROBLOX try
				local currentState: S = queue.lastRenderedState :: any
				-- ROBLOX performance: only wrap the thing that can throw in a pcall to elimiante anon function creation overhead
				local ok, eagerState = pcall(lastRenderedReducer, currentState, action)
				-- Stash the eagerly computed state, and the reducer used to compute
				-- it, on the update object. If the reducer hasn't changed by the
				-- time we enter the render phase, then the eager state can be used
				-- without calling the reducer again.
				if ok then
					update.eagerReducer = lastRenderedReducer
					update.eagerState = eagerState
				end

				-- ROBLOX finally
				if __DEV__ then
					ReactCurrentDispatcher.current = prevDispatcher
				end

				if is(eagerState, currentState) then
					-- Fast path. We can bail out without scheduling React to re-render.
					-- It's still possible that we'll need to rebase this update later,
					-- if the component re-renders for a different reason and by that
					-- time the reducer has changed.
					return
				end
				-- ROBLOX catch
				if not ok then
					-- Suppress the error. It will throw again in the render phase.
				end
			end
		end
		if __DEV__ then
			-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
			-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ as well as jest
			if type(_G.jest) ~= "nil" or _G.__TESTEZ_RUNNING_TEST__ then
				warnIfNotScopedWithMatchingAct(fiber)
				warnIfNotCurrentlyActingUpdatesInDEV(fiber)
			end
		end
		scheduleUpdateOnFiber(fiber, lane, eventTime)
	end

	if __DEV__ then
		if enableDebugTracing then
			if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
				local name = getComponentName(fiber.type) or "Unknown"
				logStateUpdateScheduled(name, lane, action)
			end
		end
	end

	if enableSchedulingProfiler then
		markStateUpdateScheduled(fiber, lane)
	end

	return
end

-- deviation: Move these to the top so they're in scope for above functions
local ContextOnlyDispatcher: Dispatcher = {
	readContext = readContext,

	useCallback = throwInvalidHookError :: any,
	useContext = throwInvalidHookError :: any,
	useEffect = throwInvalidHookError :: any,
	useImperativeHandle = throwInvalidHookError :: any,
	useLayoutEffect = throwInvalidHookError :: any,
	useMemo = throwInvalidHookError :: any,
	useReducer = throwInvalidHookError :: any,
	useRef = throwInvalidHookError :: any,
	useBinding = throwInvalidHookError :: any,
	useState = throwInvalidHookError :: any,
	useDebugValue = throwInvalidHookError :: any,
	-- useDeferredValue = throwInvalidHookError,
	-- useTransition = throwInvalidHookError,
	useMutableSource = throwInvalidHookError :: any,
	useOpaqueIdentifier = throwInvalidHookError :: any,

	unstable_isNewReconciler = enableNewReconciler,
}
exports.ContextOnlyDispatcher = ContextOnlyDispatcher

local HooksDispatcherOnMount: Dispatcher = {
	readContext = readContext,

	useCallback = mountCallback,
	useContext = readContext,
	useEffect = mountEffect,
	useImperativeHandle = mountImperativeHandle,
	useLayoutEffect = mountLayoutEffect,
	-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
	useMemo = mountMemo :: any,
	useReducer = mountReducer,
	useRef = mountRef,
	useBinding = mountBinding,
	useState = mountState,
	useDebugValue = mountDebugValue,
	-- useDeferredValue = mountDeferredValue,
	-- useTransition = mountTransition,
	useMutableSource = mountMutableSource,
	useOpaqueIdentifier = mountOpaqueIdentifier,

	unstable_isNewReconciler = enableNewReconciler,
}

local HooksDispatcherOnUpdate: Dispatcher = {
	readContext = readContext,

	useCallback = updateCallback,
	useContext = readContext,
	useEffect = updateEffect,
	useImperativeHandle = updateImperativeHandle,
	useLayoutEffect = updateLayoutEffect,
	-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
	useMemo = updateMemo :: any,
	useReducer = updateReducer,
	useRef = updateRef,
	useBinding = updateBinding,
	useState = updateState,
	useDebugValue = updateDebugValue,
	-- useDeferredValue = updateDeferredValue,
	-- useTransition = updateTransition,
	useMutableSource = updateMutableSource,
	useOpaqueIdentifier = updateOpaqueIdentifier,

	unstable_isNewReconciler = enableNewReconciler,
}

local HooksDispatcherOnRerender: Dispatcher = {
	readContext = readContext,

	useCallback = updateCallback,
	useContext = readContext,
	useEffect = updateEffect,
	useImperativeHandle = updateImperativeHandle,
	useLayoutEffect = updateLayoutEffect,
	-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
	useMemo = updateMemo :: any,
	useReducer = rerenderReducer,
	useRef = updateRef,
	useBinding = updateBinding,
	useState = rerenderState,
	useDebugValue = updateDebugValue,
	-- useDeferredValue = rerenderDeferredValue,
	-- useTransition = rerenderTransition,
	useMutableSource = updateMutableSource,
	useOpaqueIdentifier = rerenderOpaqueIdentifier,

	unstable_isNewReconciler = enableNewReconciler,
}

if __DEV__ then
	local warnInvalidContextAccess = function()
		console.error(
[[Context can only be read while React is rendering. In classes, you can read it in the render method or getDerivedStateFromProps. In function components, you can read it directly in the function body, but not inside Hooks like useReducer() or useMemo().]]		



)
	end

	local warnInvalidHookAccess = function()
		console.error(
[[Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks. You can only call Hooks at the top level of your React function. For more information, see https://reactjs.org/link/rules-of-hooks]]		



)
	end

	HooksDispatcherOnMountInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			mountHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useEffect"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(mountMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			-- ROBLOX FIXME Luau: TypeError: Type 'boolean' could not be converted into 'T'
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			local ok, result, setResult = pcall(mountReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useRef = function<T>(initialValue: T): { current: T }
			currentHookNameInDev = "useRef"
			mountHookTypesDev()
			return mountRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			mountHookTypesDev()
			return mountBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			-- deviation: Lua version of mountState return two items, not list like upstream.
			local ok, result, setResult = pcall(mountState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- ROBLOX deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			mountHookTypesDev()
			return mountDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       mountHookTypesDev()
		--       return mountDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       mountHookTypesDev()
		--       return mountTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			mountHookTypesDev()
			return mountMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function()
			currentHookNameInDev = "useOpaqueIdentifier"
			mountHookTypesDev()
			return mountOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	HooksDispatcherOnMountWithHookTypesInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			updateHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useEffect"
			updateHookTypesDev()
			return mountEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			updateHookTypesDev()
			return mountImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			updateHookTypesDev()
			return mountLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(mountMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			local ok, result, setResult = pcall(mountReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useRef = function<T>(initialValue: T): { current: T }
			currentHookNameInDev = "useRef"
			updateHookTypesDev()
			return mountRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			updateHookTypesDev()
			return mountBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			-- deviation: Lua version of mountState return two items, not list like upstream
			local ok, result, setResult = pcall(mountState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of mountState return two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			updateHookTypesDev()
			return mountDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       updateHookTypesDev()
		--       return mountDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       updateHookTypesDev()
		--       return mountTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			updateHookTypesDev()
			return mountMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function()
			currentHookNameInDev = "useOpaqueIdentifier"
			updateHookTypesDev()
			return mountOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	HooksDispatcherOnUpdateInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			updateHookTypesDev()
			return updateCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useEffect"
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			local ok, result, setResult = pcall(updateReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useRef = function<T>(initialValue: T): { current: T }
			currentHookNameInDev = "useRef"
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			-- deviation: Lua version of updateState returns two items, not list like upstream
			local ok, result, setResult = pcall(updateState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       updateHookTypesDev()
		--       return updateDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       updateHookTypesDev()
		--       return updateTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			updateHookTypesDev()
			return updateOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	HooksDispatcherOnRerenderInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			updateHookTypesDev()
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
			local ok, result, setResult =
				pcall(rerenderReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- ROBLOX deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useRef = function<T>(initialValue: T): { current: T }
			currentHookNameInDev = "useRef"
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(rerenderState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       updateHookTypesDev()
		--       return rerenderDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       updateHookTypesDev()
		--       return rerenderTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			updateHookTypesDev()
			return rerenderOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	InvalidNestedHooksDispatcherOnMountInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			warnInvalidContextAccess()
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useLayoutEffect"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			warnInvalidHookAccess()
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(mountMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			warnInvalidHookAccess()
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			local ok, result, setResult = pcall(mountReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useRef = function<T>(initialValue: T): { current: T }
			currentHookNameInDev = "useRef"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			warnInvalidHookAccess()
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(mountState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountDebugValue(value, formatterFn)
		end,
		-- useDeferredValue<T>(value: T): T {
		--   currentHookNameInDev = 'useDeferredValue'
		--   warnInvalidHookAccess()
		--   mountHookTypesDev()
		--   return mountDeferredValue(value)
		-- },
		-- useTransition(): [(() => void) => void, boolean] {
		--   currentHookNameInDev = 'useTransition'
		--   warnInvalidHookAccess()
		--   mountHookTypesDev()
		--   return mountTransition()
		-- },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	InvalidNestedHooksDispatcherOnUpdateInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			warnInvalidContextAccess()
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			local ok, result, setResult = pcall(updateReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher

			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useRef = function<T>(initialValue: T): { current: T }
			currentHookNameInDev = "useRef"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(updateState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return updateDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return updateTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	InvalidNestedHooksDispatcherOnRerenderInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			warnInvalidContextAccess()
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			local ok, result, setResult =
				pcall(rerenderReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useRef = function<T>(initialValue: T): { current: T }
			currentHookNameInDev = "useRef"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(rerenderState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return rerenderDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return rerenderTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return rerenderOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}
end

local function renderWithHooks<Props, SecondArg>(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: (p: Props, arg: SecondArg) -> any,
	props: Props,
	secondArg: SecondArg,
	nextRenderLanes: Lanes
): any
	renderLanes = nextRenderLanes
	currentlyRenderingFiber = workInProgress

	if __DEV__ then
		hookTypesDev = if current ~= nil
			then (current._debugHookTypes :: any) :: Array<HookType>
			else nil
		-- ROBLOX deviation START: index variable offset by one for Lua
		hookTypesUpdateIndexDev = 0
		-- ROBLOX deviation END
		-- Used for hot reloading:
		-- ROBLOX performance: eliminate unuseful cmp in hot path, we don't currently support hot reloading
		-- ignorePreviousDependencies =
		--   current ~= nil and current.type ~= workInProgress.type
	end

	workInProgress.memoizedState = nil
	-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
	workInProgress.updateQueue = nil
	workInProgress.lanes = NoLanes

	-- The following should have already been reset
	-- currentHook = nil
	-- workInProgressHook = nil

	-- didScheduleRenderPhaseUpdate = false

	-- TODO Warn if no hooks are used at all during mount, then some are used during update.
	-- Currently we will identify the update render as a mount because memoizedState == nil.
	-- This is tricky because it's valid for certain types of components (e.g. React.lazy)

	-- Using memoizedState to differentiate between mount/update only works if at least one stateful hook is used.
	-- Non-stateful hooks (e.g. context) don't get added to memoizedState,
	-- so memoizedState would be nil during updates and mounts.
	if __DEV__ then
		if current ~= nil and current.memoizedState ~= nil then
			ReactCurrentDispatcher.current = HooksDispatcherOnUpdateInDEV
		elseif hookTypesDev ~= nil then
			-- This dispatcher handles an edge case where a component is updating,
			-- but no stateful hooks have been used.
			-- We want to match the production code behavior (which will use HooksDispatcherOnMount),
			-- but with the extra DEV validation to ensure hooks ordering hasn't changed.
			-- This dispatcher does that.
			ReactCurrentDispatcher.current = HooksDispatcherOnMountWithHookTypesInDEV
		else
			ReactCurrentDispatcher.current = HooksDispatcherOnMountInDEV
		end
	else
		ReactCurrentDispatcher.current = (current == nil or current.memoizedState == nil)
				and HooksDispatcherOnMount
			or HooksDispatcherOnUpdate
	end

	local children = Component(props, secondArg)

	-- Check if there was a render phase update
	if didScheduleRenderPhaseUpdateDuringThisPass then
		-- Keep rendering in a loop for as long as render phase updates continue to
		-- be scheduled. Use a counter to prevent infinite loops.
		local numberOfReRenders: number = 0
		repeat
			didScheduleRenderPhaseUpdateDuringThisPass = false
			-- ROBLOX performance: use React 18 approach to avoid invariant in hot path
			if numberOfReRenders >= RE_RENDER_LIMIT then
				error(
					Error.new(
[[Too many re-renders. React limits the number of renders to prevent an infinite loop.]]					

)
				)
			end

			numberOfReRenders += 1
			-- ROBLOX performance: eliminate unuseful cmp in hot path, we don't currently support hot reloading
			-- if __DEV__ then
			-- Even when hot reloading, allow dependencies to stabilize
			-- after first render to prevent infinite render phase updates.
			-- ignorePreviousDependencies = false
			-- end

			-- Start over from the beginning of the list
			currentHook = nil
			workInProgressHook = nil

			-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
			workInProgress.updateQueue = nil

			if __DEV__ then
				-- Also validate hook order for cascading updates.
				hookTypesUpdateIndexDev = 0
			end

			ReactCurrentDispatcher.current = __DEV__ and HooksDispatcherOnRerenderInDEV
				or HooksDispatcherOnRerender

			children = Component(props, secondArg)
		until not didScheduleRenderPhaseUpdateDuringThisPass
	end

	-- We can assume the previous dispatcher is always this one, since we set it
	-- at the beginning of the render phase and there's no re-entrancy.
	ReactCurrentDispatcher.current = ContextOnlyDispatcher

	if __DEV__ then
		workInProgress._debugHookTypes = hookTypesDev
	end

	-- This check uses currentHook so that it works the same in DEV and prod bundles.
	-- hookTypesDev could catch more cases (e.g. context) but only in DEV bundles.
	local didRenderTooFewHooks = currentHook ~= nil and currentHook.next ~= nil

	renderLanes = NoLanes
	currentlyRenderingFiber = nil :: any

	currentHook = nil
	workInProgressHook = nil

	if __DEV__ then
		currentHookNameInDev = nil
		hookTypesDev = nil
		hookTypesUpdateIndexDev = 0
	end

	didScheduleRenderPhaseUpdate = false

	-- ROBLOX performance: use React 18 approach that avoid invariant in hot paths
	if didRenderTooFewHooks then
		error(
			Error.new(
[[Rendered fewer hooks than expected. This may be caused by an accidental early return statement.]]			

)
		)
	end

	return children
end
exports.renderWithHooks = renderWithHooks

return exports

end,
["react-reconciler/ReactFiberHostConfig"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/9ac42dd074c42b66ecc0334b75200b1d2989f892/packages/react-reconciler/src/ReactFiberHostConfig.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[ eslint-disable react-internal/invariant-args ]]

-- ROBLOX FIXME: Cannot carry types over via the module overriding that's in use
-- here; this is a particularly tricky case of cross-dependency type definitions
-- Use a common set of typedefs across ReactTestHostConfig and ReactRobloxHostTypes
type Object = { [string]: any }

export type Instance = Object
export type HostInstance = Instance
export type TextInstance = Instance
export type Container = Object
export type HostContext = Object
export type HydratableInstance = Instance | SuspenseInstance
export type SuspenseInstance = Object
export type PublicInstance = HostInstance

export type Type = string
export type Props = Object
export type ChildSet = {} -- void, unused
export type RendererInspectionConfig = Object

-- if _G.__NO_LOADMODULE__ then
local exports: { [string]: any } = {}
return exports
-- end

-- -- We expect that our Rollup, Jest, and Flow configurations
-- -- always shim this module with the corresponding host config
-- -- (either provided by a renderer, or a generic shim for npm).
-- --
-- -- We should never resolve to this file, but it exists to make
-- -- sure that if we *do* accidentally break the configuration,
-- -- the failure isn't silent.

-- -- deviation: FIXME (roblox): is there a way to configure luau to account for this module
-- -- being shimmed?
-- error('This module must be shimmed by a specific renderer.')

end,
["react-reconciler/ReactFiberHostContext.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberHostContext.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberStack = require(script.Parent:WaitForChild('ReactFiberStack.new'))
type StackCursor<T> = ReactFiberStack.StackCursor<T>
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type Container = ReactFiberHostConfig.Container
type HostContext = ReactFiberHostConfig.HostContext

-- local invariant = require("@pkg/@jsdotlua/shared").invariant

local getChildHostContext = ReactFiberHostConfig.getChildHostContext
local getRootHostContext = ReactFiberHostConfig.getRootHostContext
local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop

-- FIXME (roblox): The upstream code here should be guaranteeing that the type
-- is always this exact object, but I think ours will match against any empty
-- table
-- declare class NoContextT {}
type NoContextT = {}
local NO_CONTEXT: NoContextT = {}

local contextStackCursor: StackCursor<HostContext | NoContextT> = createCursor(NO_CONTEXT)
local contextFiberStackCursor: StackCursor<Fiber | NoContextT> = createCursor(NO_CONTEXT)
local rootInstanceStackCursor: StackCursor<Container | NoContextT> =
	createCursor(NO_CONTEXT)

function requiredContext<Value>(c: Value | NoContextT): Value
	-- ROBLOX performance: eliminate expensive optional cmp in hot path
	-- invariant(
	--   c ~= NO_CONTEXT,
	--   "Expected host context to exist. This error is likely caused by a bug " ..
	--     "in React. Please file an issue."
	-- )
	return c :: any
end

function getRootHostContainer(): Container
	-- ROBLOX performance: inline requiredContext impl for hot path
	-- local rootInstance = requiredContext(rootInstanceStackCursor.current)
	-- return rootInstance
	return rootInstanceStackCursor.current
end

function pushHostContainer(fiber: Fiber, nextRootInstance: Container)
	-- Push current root instance onto the stack
	-- This allows us to reset root when portals are popped.
	push(rootInstanceStackCursor, nextRootInstance, fiber)
	-- Track the context and the Fiber that provided it.
	-- This enables us to pop only Fibers that provide unique contexts.
	push(contextFiberStackCursor, fiber, fiber)

	-- Finally, we need to push the host context to the stack.
	-- However, we can't just call getRootHostContext() and push it because
	-- we'd have a different number of entries on the stack depending on
	-- whether getRootHostContext() throws somewhere in renderer code or not.
	-- So we push an empty value first. This lets us safely unwind on errors.
	push(contextStackCursor, NO_CONTEXT, fiber)
	local nextRootContext = getRootHostContext(nextRootInstance)
	-- Now that we know this function doesn't throw, replace it.
	pop(contextStackCursor, fiber)
	push(contextStackCursor, nextRootContext, fiber)
end

function popHostContainer(fiber: Fiber)
	pop(contextStackCursor, fiber)
	pop(contextFiberStackCursor, fiber)
	pop(rootInstanceStackCursor, fiber)
end

function getHostContext(): HostContext
	-- ROBLOX performance: inline requiredContext impl for hot path
	-- local context = requiredContext(contextStackCursor.current)
	-- return context
	return contextStackCursor.current
end

function pushHostContext(fiber: Fiber)
	local rootInstance: Container = requiredContext(rootInstanceStackCursor.current)
	local context: HostContext = requiredContext(contextStackCursor.current)
	local nextContext = getChildHostContext(context, fiber.type, rootInstance)

	-- Don't push this Fiber's context unless it's unique.
	if context == nextContext then
		return
	end

	-- Track the context and the Fiber that provided it.
	-- This enables us to pop only Fibers that provide unique contexts.
	push(contextFiberStackCursor, fiber, fiber)
	push(contextStackCursor, nextContext, fiber)
end

function popHostContext(fiber: Fiber)
	-- Do not pop unless this Fiber provided the current context.
	-- pushHostContext() only pushes Fibers that provide unique contexts.
	if contextFiberStackCursor.current ~= fiber then
		return
	end

	pop(contextStackCursor, fiber)
	pop(contextFiberStackCursor, fiber)
end

return {
	getHostContext = getHostContext,
	getRootHostContainer = getRootHostContainer,
	popHostContainer = popHostContainer,
	popHostContext = popHostContext,
	pushHostContainer = pushHostContainer,
	pushHostContext = pushHostContext,
}

end,
["react-reconciler/ReactFiberHotReloading.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/6edaf6f764f23043f0cd1c2da355b42f641afd8b/packages/react-reconciler/src/ReactFiberHotReloading.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactElementType = require(script.Parent.Parent:WaitForChild('shared'))-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes

type ReactElement = ReactElementType.ReactElement<any, any>

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
-- local type {FiberRoot} = require("./ReactInternalTypes")
-- local type {Instance} = require("./ReactFiberHostConfig")
-- local type {ReactNodeList} = require("@pkg/@jsdotlua/shared").ReactTypes

-- local {
-- 	flushSync,
-- 	scheduleUpdateOnFiber,
-- 	flushPassiveEffects,
-- } = require("./ReactFiberWorkLoop/new")
-- local {updateContainer} = require("./ReactFiberReconciler/new")
-- local {emptyContextObject} = require("./ReactFiberContext/new")
-- local {SyncLane, NoTimestamp} = require("./ReactFiberLane")
-- local {
-- 	ClassComponent,
-- 	FunctionComponent,
-- 	ForwardRef,
-- 	HostComponent,
-- 	HostPortal,
-- 	HostRoot,
-- 	MemoComponent,
-- 	SimpleMemoComponent,
-- } = require("./ReactWorkTags")
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
-- 	REACT_MEMO_TYPE,
-- 	REACT_LAZY_TYPE,

export type Family = {
	current: any
}

-- export type RefreshUpdate = {|
-- 	staleFamilies: Set<Family>,
-- 	updatedFamilies: Set<Family>,
-- |}

-- Resolves type to a family.
type RefreshHandler = (any) -> (Family?)

-- -- Used by React Refresh runtime through DevTools Global Hook.
-- export type SetRefreshHandler = (handler: RefreshHandler | nil) => void
-- export type ScheduleRefresh = (root: FiberRoot, update: RefreshUpdate) => void
-- export type ScheduleRoot = (root: FiberRoot, element: ReactNodeList) => void
-- export type FindHostInstancesForRefresh = (
-- 	root: FiberRoot,
-- 	families: Array<Family>,
-- ) => Set<Instance>

-- FIXME (roblox): restore type 'resolveFamily: RefreshHandler?' when type
-- refinement in Luau works better
local resolveFamily -- $FlowFixMe Flow gets confused by a WeakSet feature check below.
-- ROBLOX deviation: Using table instead of WeakSet

local failedBoundaries: { [number]: Fiber } | nil 

local exports = {}

-- export local setRefreshHandler = (handler: RefreshHandler | nil): void => {
-- 	if _G.__DEV__)
-- 		resolveFamily = handler
-- 	end
-- end

local function resolveFunctionForHotReloading(type: any): any
	if _G.__DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return type
		end
		local family = resolveFamily(type)
		if family == nil then
			return type
		end
		-- Use the latest known implementation.
		return family.current
	else
		return type
	end
end
exports.resolveFunctionForHotReloading = resolveFunctionForHotReloading

local function resolveClassForHotReloading(type: any): any
	-- No implementation differences.
	return resolveFunctionForHotReloading(type)
end
exports.resolveClassForHotReloading = resolveClassForHotReloading

local function resolveForwardRefForHotReloading(type: any): any
	if _G.__DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return type
		end
		local family = resolveFamily(type)
		if family == nil then
			-- Check if we're dealing with a real forwardRef. Don't want to crash early.
			if type ~= nil and typeof(type.render) == "function" then
				-- ForwardRef is special because its resolved .type is an object,
				-- but it's possible that we only have its inner render function in the map.
				-- If that inner render function is different, we'll build a new forwardRef type.
				local currentRender = resolveFunctionForHotReloading(type.render)
				if type.render ~= currentRender then
					local syntheticType = {
						["$$typeof"] = REACT_FORWARD_REF_TYPE,
						render = currentRender,
						-- ROBLOX deviation: Luau needs table initializers to be complete
						displayName = nil,
					}
					if type.displayName ~= nil then
						syntheticType.displayName = type.displayName
					end
					return syntheticType
				end
			end
			return type
		end
		-- Use the latest known implementation.
		return family.current
	else
		return type
	end
end
exports.resolveForwardRefForHotReloading = resolveForwardRefForHotReloading

exports.isCompatibleFamilyForHotReloading =
	function(fiber: Fiber, element: ReactElement): boolean
		warn("isCompatibleFamilyForHotReloading is stubbed (returns false)")
		return false
		-- if _G.__DEV__ then
		-- 	if resolveFamily == nil then
		-- 		-- Hot reloading is disabled.
		-- 		return false
		-- 	end

		-- 	local prevType = fiber.elementType
		-- 	local nextType = element.type

		-- 	-- If we got here, we know types aren't == equal.
		-- 	local needsCompareFamilies = false

		-- 	local $$typeofNextType =
		-- 		typeof nextType == 'table’' and nextType ~= nil
		-- 			? nextType.$$typeof
		-- 			: nil

		-- 	switch (fiber.tag)
		-- 		case ClassComponent: {
		-- 			if typeof nextType == 'function')
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		case FunctionComponent: {
		-- 			if typeof nextType == 'function')
		-- 				needsCompareFamilies = true
		-- 			} else if $$typeofNextType == REACT_LAZY_TYPE)
		-- 				-- We don't know the inner type yet.
		-- 				-- We're going to assume that the lazy inner type is stable,
		-- 				-- and so it is sufficient to avoid reconciling it away.
		-- 				-- We're not going to unwrap or actually use the new lazy type.
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		case ForwardRef: {
		-- 			if $$typeofNextType == REACT_FORWARD_REF_TYPE)
		-- 				needsCompareFamilies = true
		-- 			} else if $$typeofNextType == REACT_LAZY_TYPE)
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		case MemoComponent:
		-- 		case SimpleMemoComponent: {
		-- 			if $$typeofNextType == REACT_MEMO_TYPE)
		-- 				-- TODO: if it was but can no longer be simple,
		-- 				-- we shouldn't set this.
		-- 				needsCompareFamilies = true
		-- 			} else if $$typeofNextType == REACT_LAZY_TYPE)
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		default:
		-- 			return false
		-- 	end

		-- 	-- Check if both types have a family and it's the same one.
		-- 	if needsCompareFamilies)
		-- 		-- Note: memo() and forwardRef() we'll compare outer rather than inner type.
		-- 		-- This means both of them need to be registered to preserve state.
		-- 		-- If we unwrapped and compared the inner types for wrappers instead,
		-- 		-- then we would risk falsely saying two separate memo(Foo)
		-- 		-- calls are equivalent because they wrap the same Foo function.
		-- 		local prevFamily = resolveFamily(prevType)
		-- 		if prevFamily ~= undefined and prevFamily == resolveFamily(nextType))
		-- 			return true
		-- 		end
		-- 	end
		-- 	return false
		-- } else {
		-- 	return false
		-- end
	end

exports.markFailedErrorBoundaryForHotReloading = function(fiber: Fiber)
	if _G.__DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return
		end
		-- if typeof(WeakSet) ~= 'function' then
		-- 	return
		-- end
		-- ROBLOX deviation: {} in place of WeakSet
		if failedBoundaries == nil then
			failedBoundaries = {}
		end
		-- ROBLOX FIXME: remove :: once Luau understands nil check
		table.insert(failedBoundaries :: { [number]: Fiber }, fiber)
	end
end

-- export local scheduleRefresh: ScheduleRefresh = (
-- 	root: FiberRoot,
-- 	update: RefreshUpdate,
-- ): void => {
-- 	if _G.__DEV__)
-- 		if resolveFamily == nil)
-- 			-- Hot reloading is disabled.
-- 			return
-- 		end
-- 		local {staleFamilies, updatedFamilies} = update
-- 		flushPassiveEffects()
-- 		flushSync(() => {
-- 			scheduleFibersWithFamiliesRecursively(
-- 				root.current,
-- 				updatedFamilies,
-- 				staleFamilies,
-- 			)
-- 		})
-- 	end
-- end

-- export local scheduleRoot: ScheduleRoot = (
-- 	root: FiberRoot,
-- 	element: ReactNodeList,
-- ): void => {
-- 	if _G.__DEV__)
-- 		if root.context ~= emptyContextObject)
-- 			-- Super edge case: root has a legacy _renderSubtree context
-- 			-- but we don't know the parentComponent so we can't pass it.
-- 			-- Just ignore. We'll delete this with _renderSubtree code path later.
-- 			return
-- 		end
-- 		flushPassiveEffects()
-- 		flushSync(() => {
-- 			updateContainer(element, root, nil, nil)
-- 		})
-- 	end
-- end

-- function scheduleFibersWithFamiliesRecursively(
-- 	fiber: Fiber,
-- 	updatedFamilies: Set<Family>,
-- 	staleFamilies: Set<Family>,
-- )
-- 	if _G.__DEV__)
-- 		local {alternate, child, sibling, tag, type} = fiber

-- 		local candidateType = nil
-- 		switch (tag)
-- 			case FunctionComponent:
-- 			case SimpleMemoComponent:
-- 			case ClassComponent:
-- 				candidateType = type
-- 				break
-- 			case ForwardRef:
-- 				candidateType = type.render
-- 				break
-- 			default:
-- 				break
-- 		end

-- 		if resolveFamily == nil)
-- 			throw new Error('Expected resolveFamily to be set during hot reload.')
-- 		end

-- 		local needsRender = false
-- 		local needsRemount = false
-- 		if candidateType ~= nil)
-- 			local family = resolveFamily(candidateType)
-- 			if family ~= undefined)
-- 				if staleFamilies.has(family))
-- 					needsRemount = true
-- 				} else if updatedFamilies.has(family))
-- 					if tag == ClassComponent)
-- 						needsRemount = true
-- 					} else {
-- 						needsRender = true
-- 					end
-- 				end
-- 			end
-- 		end
-- 		if failedBoundaries ~= nil)
-- 			if
-- 				failedBoundaries.has(fiber) or
-- 				(alternate ~= nil and failedBoundaries.has(alternate))
-- 			)
-- 				needsRemount = true
-- 			end
-- 		end

-- 		if needsRemount)
-- 			fiber._debugNeedsRemount = true
-- 		end
-- 		if needsRemount or needsRender)
-- 			scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
-- 		end
-- 		if child ~= nil and !needsRemount)
-- 			scheduleFibersWithFamiliesRecursively(
-- 				child,
-- 				updatedFamilies,
-- 				staleFamilies,
-- 			)
-- 		end
-- 		if sibling ~= nil)
-- 			scheduleFibersWithFamiliesRecursively(
-- 				sibling,
-- 				updatedFamilies,
-- 				staleFamilies,
-- 			)
-- 		end
-- 	end
-- end

-- export local findHostInstancesForRefresh: FindHostInstancesForRefresh = (
-- 	root: FiberRoot,
-- 	families: Array<Family>,
-- ): Set<Instance> => {
-- 	if _G.__DEV__)
-- 		local hostInstances = new Set()
-- 		local types = new Set(families.map(family => family.current))
-- 		findHostInstancesForMatchingFibersRecursively(
-- 			root.current,
-- 			types,
-- 			hostInstances,
-- 		)
-- 		return hostInstances
-- 	} else {
-- 		throw new Error(
-- 			'Did not expect findHostInstancesForRefresh to be called in production.',
-- 		)
-- 	end
-- end

-- function findHostInstancesForMatchingFibersRecursively(
-- 	fiber: Fiber,
-- 	types: Set<any>,
-- 	hostInstances: Set<Instance>,
-- )
-- 	if _G.__DEV__)
-- 		local {child, sibling, tag, type} = fiber

-- 		local candidateType = nil
-- 		switch (tag)
-- 			case FunctionComponent:
-- 			case SimpleMemoComponent:
-- 			case ClassComponent:
-- 				candidateType = type
-- 				break
-- 			case ForwardRef:
-- 				candidateType = type.render
-- 				break
-- 			default:
-- 				break
-- 		end

-- 		local didMatch = false
-- 		if candidateType ~= nil)
-- 			if types.has(candidateType))
-- 				didMatch = true
-- 			end
-- 		end

-- 		if didMatch)
-- 			-- We have a match. This only drills down to the closest host components.
-- 			-- There's no need to search deeper because for the purpose of giving
-- 			-- visual feedback, "flashing" outermost parent rectangles is sufficient.
-- 			findHostInstancesForFiberShallowly(fiber, hostInstances)
-- 		} else {
-- 			-- If there's no match, maybe there will be one further down in the child tree.
-- 			if child ~= nil)
-- 				findHostInstancesForMatchingFibersRecursively(
-- 					child,
-- 					types,
-- 					hostInstances,
-- 				)
-- 			end
-- 		end

-- 		if sibling ~= nil)
-- 			findHostInstancesForMatchingFibersRecursively(
-- 				sibling,
-- 				types,
-- 				hostInstances,
-- 			)
-- 		end
-- 	end
-- end

-- function findHostInstancesForFiberShallowly(
-- 	fiber: Fiber,
-- 	hostInstances: Set<Instance>,
-- ): void {
-- 	if _G.__DEV__)
-- 		local foundHostInstances = findChildHostInstancesForFiberShallowly(
-- 			fiber,
-- 			hostInstances,
-- 		)
-- 		if foundHostInstances)
-- 			return
-- 		end
-- 		-- If we didn't find any host children, fallback to closest host parent.
-- 		local node = fiber
-- 		while (true)
-- 			switch (node.tag)
-- 				case HostComponent:
-- 					hostInstances.add(node.stateNode)
-- 					return
-- 				case HostPortal:
-- 					hostInstances.add(node.stateNode.containerInfo)
-- 					return
-- 				case HostRoot:
-- 					hostInstances.add(node.stateNode.containerInfo)
-- 					return
-- 			end
-- 			if node.return == nil)
-- 				throw new Error('Expected to reach root first.')
-- 			end
-- 			node = node.return
-- 		end
-- 	end
-- end

-- function findChildHostInstancesForFiberShallowly(
-- 	fiber: Fiber,
-- 	hostInstances: Set<Instance>,
-- ): boolean {
-- 	if _G.__DEV__)
-- 		local node: Fiber = fiber
-- 		local foundHostInstances = false
-- 		while (true)
-- 			if node.tag == HostComponent)
-- 				-- We got a match.
-- 				foundHostInstances = true
-- 				hostInstances.add(node.stateNode)
-- 				-- There may still be more, so keep searching.
-- 			} else if node.child ~= nil)
-- 				node.child.return = node
-- 				node = node.child
-- 				continue
-- 			end
-- 			if node == fiber)
-- 				return foundHostInstances
-- 			end
-- 			while (node.sibling == nil)
-- 				if node.return == nil or node.return == fiber)
-- 					return foundHostInstances
-- 				end
-- 				node = node.return
-- 			end
-- 			node.sibling.return = node.return
-- 			node = node.sibling
-- 		end
-- 	end
-- 	return false
-- end

return exports

end,
["react-reconciler/ReactFiberHydrationContext.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberHydrationContext.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. message)
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type Instance = ReactFiberHostConfig.Instance
type TextInstance = ReactFiberHostConfig.TextInstance
type HydratableInstance = ReactFiberHostConfig.HydratableInstance
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
type Container = ReactFiberHostConfig.Container
type HostContext = ReactFiberHostConfig.HostContext

local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostRoot = ReactWorkTags.HostRoot
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local Placement = ReactFiberFlags.Placement
local Hydrating = ReactFiberFlags.Hydrating
-- local Deletion = ReactFiberFlags.Deletion

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant

local ReactFiber = require(script.Parent:WaitForChild('ReactFiber.new'))-- local createFiberFromHostInstanceForDeletion = ReactFiber.createFiberFromHostInstanceForDeletion

local createFiberFromDehydratedFragment = ReactFiber.createFiberFromDehydratedFragment

local supportsHydration = ReactFiberHostConfig.supportsHydration
local getNextHydratableSibling = ReactFiberHostConfig.getNextHydratableSibling
local getFirstHydratableChild = ReactFiberHostConfig.getFirstHydratableChild
local canHydrateInstance = ReactFiberHostConfig.canHydrateInstance
local canHydrateTextInstance = ReactFiberHostConfig.canHydrateTextInstance
local canHydrateSuspenseInstance = ReactFiberHostConfig.canHydrateSuspenseInstance
local hydrateInstance = ReactFiberHostConfig.hydrateInstance
local hydrateTextInstance = ReactFiberHostConfig.hydrateTextInstance
local hydrateSuspenseInstance = ReactFiberHostConfig.hydrateSuspenseInstance
local getNextHydratableInstanceAfterSuspenseInstance =
	ReactFiberHostConfig.getNextHydratableInstanceAfterSuspenseInstance
local didNotMatchHydratedContainerTextInstance =
	ReactFiberHostConfig.didNotMatchHydratedContainerTextInstance
local didNotMatchHydratedTextInstance =
	ReactFiberHostConfig.didNotMatchHydratedTextInstance
local shouldSetTextContent = ReactFiberHostConfig.shouldSetTextContent

-- local {
--   didNotHydrateContainerInstance,
--   didNotHydrateInstance,
--   didNotFindHydratableContainerInstance,
--   didNotFindHydratableContainerTextInstance,
--   didNotFindHydratableContainerSuspenseInstance,
--   didNotFindHydratableInstance,
--   didNotFindHydratableTextInstance,
--   didNotFindHydratableSuspenseInstance,
-- } = require(Packages../ReactFiberHostConfig'
local enableSuspenseServerRenderer =
	require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.enableSuspenseServerRenderer
local OffscreenLane = require(script.Parent:WaitForChild('ReactFiberLane')).OffscreenLane

-- The deepest Fiber on the stack involved in a hydration context.
-- This may have been an insertion or a hydration.
local hydrationParentFiber: Fiber? 
local nextHydratableInstance: nil | HydratableInstance 
local isHydrating: boolean = false

function warnIfHydrating()
	if _G.__DEV__ then
		if isHydrating then
			console.error(
				"We should not be hydrating here. This is a bug in React. Please file a bug."
			)
		end
	end
end

function enterHydrationState(fiber: Fiber): boolean
	if not supportsHydration then
		return false
	end

	local parentInstance = fiber.stateNode.containerInfo
	nextHydratableInstance = getFirstHydratableChild(parentInstance)
	hydrationParentFiber = fiber
	isHydrating = true
	return true
end

function reenterHydrationStateFromDehydratedSuspenseInstance(
	fiber: Fiber,
	suspenseInstance: SuspenseInstance
): boolean
	if not supportsHydration then
		return false
	end

	nextHydratableInstance = getNextHydratableSibling(suspenseInstance)
	popToNextHostParent(fiber)
	isHydrating = true
	return true
end

function deleteHydratableInstance(returnFiber: Fiber?, instance: HydratableInstance)
	unimplemented("deleteHydratableInstance")
	-- if _G.__DEV__ then
	--   switch (returnFiber.tag)
	--     case HostRoot:
	--       didNotHydrateContainerInstance(
	--         returnFiber.stateNode.containerInfo,
	--         instance,
	--       )
	--       break
	--     case HostComponent:
	--       didNotHydrateInstance(
	--         returnFiber.type,
	--         returnFiber.memoizedProps,
	--         returnFiber.stateNode,
	--         instance,
	--       )
	--       break
	-- 		end
	-- 	end

	-- local childToDelete = createFiberFromHostInstanceForDeletion()
	-- childToDelete.stateNode = instance
	-- childToDelete.return = returnFiber

	-- local deletions = returnFiber.deletions
	-- if deletions == nil)
	--   returnFiber.deletions = [childToDelete]
	--   -- TODO (effects) Rename this to better reflect its new usage (e.g. ChildDeletions)
	--   returnFiber.flags |= Deletion
	-- } else {
	--   deletions.push(childToDelete)
	-- }
end

function insertNonHydratedInstance(returnFiber: Fiber?, fiber: Fiber)
	unimplemented("insertNonHydratedInstance")
	fiber.flags = bit32.bor(bit32.band(fiber.flags, bit32.bnot(Hydrating)), Placement)
	if _G.__DEV__ then
		-- switch (returnFiber.tag)
		--   case HostRoot: {
		--     local parentContainer = returnFiber.stateNode.containerInfo
		--     switch (fiber.tag)
		--       case HostComponent:
		--         local type = fiber.type
		--         local props = fiber.pendingProps
		--         didNotFindHydratableContainerInstance(parentContainer, type, props)
		--         break
		--       case HostText:
		--         local text = fiber.pendingProps
		--         didNotFindHydratableContainerTextInstance(parentContainer, text)
		--         break
		--       case SuspenseComponent:
		--         didNotFindHydratableContainerSuspenseInstance(parentContainer)
		--         break
		--     }
		--     break
		--   }
		--   case HostComponent: {
		--     local parentType = returnFiber.type
		--     local parentProps = returnFiber.memoizedProps
		--     local parentInstance = returnFiber.stateNode
		--     switch (fiber.tag)
		--       case HostComponent:
		--         local type = fiber.type
		--         local props = fiber.pendingProps
		--         didNotFindHydratableInstance(
		--           parentType,
		--           parentProps,
		--           parentInstance,
		--           type,
		--           props,
		--         )
		--         break
		--       case HostText:
		--         local text = fiber.pendingProps
		--         didNotFindHydratableTextInstance(
		--           parentType,
		--           parentProps,
		--           parentInstance,
		--           text,
		--         )
		--         break
		--       case SuspenseComponent:
		--         didNotFindHydratableSuspenseInstance(
		--           parentType,
		--           parentProps,
		--           parentInstance,
		--         )
		--         break
		--     }
		--     break
		--   }
		--   default:
		--     return
		-- end
	end
end

function tryHydrate(fiber, nextInstance)
	if fiber.tag == HostComponent then
		local type_ = fiber.type
		local props = fiber.pendingProps
		local instance = canHydrateInstance(nextInstance, type_, props)
		if instance ~= nil then
			fiber.stateNode = instance
			return true
		end
		return false
	elseif fiber.tag == HostText then
		local text = fiber.pendingProps
		local textInstance = canHydrateTextInstance(nextInstance, text)
		if textInstance ~= nil then
			fiber.stateNode = textInstance
			return true
		end
		return false
	elseif fiber.tag == SuspenseComponent then
		if enableSuspenseServerRenderer then
			local suspenseInstance: nil | SuspenseInstance =
				canHydrateSuspenseInstance(nextInstance)
			if suspenseInstance ~= nil then
				local suspenseState: SuspenseState = {
					dehydrated = suspenseInstance,
					retryLane = OffscreenLane,
				}
				fiber.memoizedState = suspenseState
				-- Store the dehydrated fragment as a child fiber.
				-- This simplifies the code for getHostSibling and deleting nodes,
				-- since it doesn't have to consider all Suspense boundaries and
				-- check if they're dehydrated ones or not.
				local dehydratedFragment =
					createFiberFromDehydratedFragment(suspenseInstance)
				dehydratedFragment.return_ = fiber
				fiber.child = dehydratedFragment
				return true
			end
		end
		return false
	else
		return false
	end
end

function tryToClaimNextHydratableInstance(fiber: Fiber)
	if not isHydrating then
		return
	end
	local nextInstance = nextHydratableInstance
	if not nextInstance then
		-- Nothing to hydrate. Make it an insertion.
		insertNonHydratedInstance(hydrationParentFiber, fiber)
		isHydrating = false
		hydrationParentFiber = fiber
		return
	end
	-- ROBLOX FIXME Luau: Luau doesn't narrow based on the guard above
	local firstAttemptedInstance = nextInstance :: HydratableInstance
	if not tryHydrate(fiber, nextInstance) then
		-- If we can't hydrate this instance let's try the next one.
		-- We use this as a heuristic. It's based on intuition and not data so it
		-- might be flawed or unnecessary.
		nextInstance = getNextHydratableSibling(firstAttemptedInstance)
		if not nextInstance or not tryHydrate(fiber, nextInstance) then
			-- Nothing to hydrate. Make it an insertion.
			insertNonHydratedInstance(hydrationParentFiber, fiber)
			isHydrating = false
			hydrationParentFiber = fiber
			return
		end
		-- We matched the next one, we'll now assume that the first one was
		-- superfluous and we'll delete it. Since we can't eagerly delete it
		-- we'll have to schedule a deletion. To do that, this node needs a dummy
		-- fiber associated with it.
		deleteHydratableInstance(hydrationParentFiber, firstAttemptedInstance)
	end
	hydrationParentFiber = fiber
	nextHydratableInstance = getFirstHydratableChild(nextInstance)
end

function prepareToHydrateHostInstance(
	fiber: Fiber,
	rootContainerInstance: Container,
	hostContext: HostContext
): boolean
	if not supportsHydration then
		invariant(
			false,
[[Expected prepareToHydrateHostInstance() to never be called. This error is likely caused by a bug in React. Please file an issue.]]		

)
	end

	local instance: Instance = fiber.stateNode
	local updatePayload = hydrateInstance(
		instance,
		fiber.type,
		fiber.memoizedProps,
		rootContainerInstance,
		hostContext,
		fiber
	)
	-- TODO: Type this specific to this type of component.
	fiber.updateQueue = updatePayload
	-- If the update payload indicates that there is a change or if there
	-- is a new ref we mark this as an update.
	if updatePayload ~= nil then
		return true
	end
	return false
end

function prepareToHydrateHostTextInstance(fiber: Fiber): boolean
	if not supportsHydration then
		invariant(
			false,
[[Expected prepareToHydrateHostTextInstance() to never be called. This error is likely caused by a bug in React. Please file an issue.]]		

)
	end

	local textInstance: TextInstance = fiber.stateNode
	local textContent: string = fiber.memoizedProps
	local shouldUpdate = hydrateTextInstance(textInstance, textContent, fiber)
	if _G.__DEV__ then
		if shouldUpdate then
			-- We assume that prepareToHydrateHostTextInstance is called in a context where the
			-- hydration parent is the parent host component of this host text.
			local returnFiber = hydrationParentFiber
			if returnFiber ~= nil then
				if returnFiber.tag == HostRoot then
					local parentContainer = returnFiber.stateNode.containerInfo
					didNotMatchHydratedContainerTextInstance(
						parentContainer,
						textInstance,
						textContent
					)
				elseif returnFiber.tag == HostComponent then
					local parentType = returnFiber.type
					local parentProps = returnFiber.memoizedProps
					local parentInstance = returnFiber.stateNode
					didNotMatchHydratedTextInstance(
						parentType,
						parentProps,
						parentInstance,
						textInstance,
						textContent
					)
				end
			end
		end
	end
	return shouldUpdate
end

function prepareToHydrateHostSuspenseInstance(fiber: Fiber)
	if not supportsHydration then
		invariant(
			false,
[[Expected prepareToHydrateHostSuspenseInstance() to never be called. This error is likely caused by a bug in React. Please file an issue.]]		

)
	end

	local suspenseState: SuspenseState = fiber.memoizedState
	local suspenseInstance: nil | SuspenseInstance
	if suspenseState ~= nil then
		suspenseInstance = suspenseState.dehydrated
	else
		suspenseInstance = nil
	end

	invariant(
		suspenseInstance,
[[Expected to have a hydrated suspense instance. This error is likely caused by a bug in React. Please file an issue.]]	

)
	hydrateSuspenseInstance(suspenseInstance, fiber)
end

function skipPastDehydratedSuspenseInstance(fiber: Fiber): nil | HydratableInstance
	if not supportsHydration then
		invariant(
			false,
[[Expected skipPastDehydratedSuspenseInstance() to never be called. This error is likely caused by a bug in React. Please file an issue.]]		

)
	end
	local suspenseState: SuspenseState = fiber.memoizedState
	local suspenseInstance: nil | SuspenseInstance
	if suspenseState ~= nil then
		suspenseInstance = suspenseState.dehydrated
	else
		suspenseInstance = nil
	end
	invariant(
		suspenseInstance,
[[Expected to have a hydrated suspense instance. This error is likely caused by a bug in React. Please file an issue.]]	

)
	return getNextHydratableInstanceAfterSuspenseInstance(suspenseInstance)
end

function popToNextHostParent(fiber: Fiber)
	local parent = fiber.return_
	while
		parent ~= nil
		and parent.tag ~= HostComponent
		and parent.tag ~= HostRoot
		and parent.tag ~= SuspenseComponent
	do
		parent = parent.return_
	end
	hydrationParentFiber = parent
end

function popHydrationState(fiber: Fiber): boolean
	if not supportsHydration then
		return false
	end
	if fiber ~= hydrationParentFiber then
		-- We're deeper than the current hydration context, inside an inserted
		-- tree.
		return false
	end
	if not isHydrating then
		-- If we're not currently hydrating but we're in a hydration context, then
		-- we were an insertion and now need to pop up reenter hydration of our
		-- siblings.
		popToNextHostParent(fiber)
		isHydrating = true
		return false
	end

	local type_ = fiber.type

	-- If we have any remaining hydratable nodes, we need to delete them now.
	-- We only do this deeper than head and body since they tend to have random
	-- other nodes in them. We also ignore components with pure text content in
	-- side of them.
	-- TODO: Better heuristic.
	if
		fiber.tag ~= HostComponent
		or (
			type_ ~= "head"
			and type_ ~= "body"
			and not shouldSetTextContent(type_, fiber.memoizedProps)
		)
	then
		local nextInstance = nextHydratableInstance
		while nextInstance do
			deleteHydratableInstance(fiber, nextInstance)
			nextInstance = getNextHydratableSibling(nextInstance)
		end
	end

	popToNextHostParent(fiber)
	if fiber.tag == SuspenseComponent then
		nextHydratableInstance = skipPastDehydratedSuspenseInstance(fiber)
	else
		if hydrationParentFiber then
			nextHydratableInstance = getNextHydratableSibling(fiber.stateNode)
		else
			nextHydratableInstance = nil
		end
	end
	return true
end

function resetHydrationState()
	if not supportsHydration then
		return
	end

	hydrationParentFiber = nil
	nextHydratableInstance = nil
	isHydrating = false
end

function getIsHydrating(): boolean
	return isHydrating
end

return {
	warnIfHydrating = warnIfHydrating,
	enterHydrationState = enterHydrationState,
	getIsHydrating = getIsHydrating,
	reenterHydrationStateFromDehydratedSuspenseInstance = reenterHydrationStateFromDehydratedSuspenseInstance,
	resetHydrationState = resetHydrationState,
	tryToClaimNextHydratableInstance = tryToClaimNextHydratableInstance,
	prepareToHydrateHostInstance = prepareToHydrateHostInstance,
	prepareToHydrateHostTextInstance = prepareToHydrateHostTextInstance,
	prepareToHydrateHostSuspenseInstance = prepareToHydrateHostSuspenseInstance,
	popHydrationState = popHydrationState,
}

end,
["react-reconciler/ReactFiberLane"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/6f62abb58ae46d9c88525635f1790487285666e6/packages/react-reconciler/src/ReactFiberLane.js
--!strict
--[[
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactFiberSchedulerPriorities =
	require(script.Parent:WaitForChild('ReactFiberSchedulerPriorities.roblox'))
-- deviation: Instead of defining these here, and and re-exporting in
-- `ReactInternalTypes`, we depend on and re-export them here to avoid cyclical
-- require issues

export type LanePriority = ReactInternalTypes.LanePriority
export type Lane = ReactInternalTypes.Lane
export type Lanes = ReactInternalTypes.Lanes
export type LaneMap<T> = ReactInternalTypes.LaneMap<T>

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant

local ImmediateSchedulerPriority = ReactFiberSchedulerPriorities.ImmediatePriority
local UserBlockingSchedulerPriority = ReactFiberSchedulerPriorities.UserBlockingPriority
local NormalSchedulerPriority = ReactFiberSchedulerPriorities.NormalPriority
local LowSchedulerPriority = ReactFiberSchedulerPriorities.LowPriority
local IdleSchedulerPriority = ReactFiberSchedulerPriorities.IdlePriority
local NoSchedulerPriority = ReactFiberSchedulerPriorities.NoPriority

local exports = {}

local SyncLanePriority: LanePriority = 15
exports.SyncLanePriority = SyncLanePriority
local SyncBatchedLanePriority: LanePriority = 14
exports.SyncBatchedLanePriority = SyncBatchedLanePriority

local InputDiscreteHydrationLanePriority: LanePriority = 13
local InputDiscreteLanePriority: LanePriority = 12
exports.InputDiscreteLanePriority = InputDiscreteLanePriority

local InputContinuousHydrationLanePriority: LanePriority = 11
local InputContinuousLanePriority: LanePriority = 10
exports.InputContinuousLanePriority = InputContinuousLanePriority

local DefaultHydrationLanePriority: LanePriority = 9
local DefaultLanePriority: LanePriority = 8
exports.DefaultLanePriority = DefaultLanePriority

local TransitionHydrationPriority: LanePriority = 7
local TransitionPriority: LanePriority = 6
exports.TransitionPriority = TransitionPriority

local RetryLanePriority: LanePriority = 5

local SelectiveHydrationLanePriority: LanePriority = 4

local IdleHydrationLanePriority: LanePriority = 3
local IdleLanePriority: LanePriority = 2

local OffscreenLanePriority: LanePriority = 1

local NoLanePriority: LanePriority = 0
exports.NoLanePriority = NoLanePriority

-- ROBLOX performance: only use was for loop that was manually unrolled
-- local TotalLanes = 31

local NoLanes: Lanes = --[[                             ]]
	0b0000000000000000000000000000000
exports.NoLanes = NoLanes
local NoLane: Lane = --[[                               ]]
	0b0000000000000000000000000000000
exports.NoLane = NoLane

local SyncLane: Lane = --[[                             ]]
	0b0000000000000000000000000000001
exports.SyncLane = SyncLane
local SyncBatchedLane: Lanes = --[[                     ]]
	0b0000000000000000000000000000010
exports.SyncBatchedLane = SyncBatchedLane

local InputDiscreteHydrationLane: Lane = --[[           ]]
	0b0000000000000000000000000000100
exports.InputDiscreteHydrationLane = InputDiscreteHydrationLane
local InputDiscreteLanes: Lanes = --[[                  ]]
	0b0000000000000000000000000011000

local InputContinuousHydrationLane: Lane = --[[         ]]
	0b0000000000000000000000000100000
local InputContinuousLanes: Lanes = --[[                ]]
	0b0000000000000000000000011000000

local DefaultHydrationLane: Lane = --[[                 ]]
	0b0000000000000000000000100000000
exports.DefaultHydrationLane = DefaultHydrationLane
local DefaultLanes: Lanes = --[[                        ]]
	0b0000000000000000000111000000000
exports.DefaultLanes = DefaultLanes

local TransitionHydrationLane: Lane = --[[              ]]
	0b0000000000000000001000000000000
local TransitionLanes: Lanes = --[[                     ]]
	0b0000000001111111110000000000000

local RetryLanes: Lanes = --[[                          ]]
	0b0000011110000000000000000000000
-- ROBLOX deviation: we expose this symbol from the module for ReactUpdateQueue.roblox tests, we don't re-export outside the package
exports.RetryLanes = RetryLanes
local SomeRetryLane: Lanes = --[[                       ]]
	0b0000010000000000000000000000000
exports.SomeRetryLane = SomeRetryLane

local SelectiveHydrationLane: Lane = --[[               ]]
	0b0000100000000000000000000000000
exports.SelectiveHydrationLane = SelectiveHydrationLane

local NonIdleLanes = --[[                               ]]
	0b0000111111111111111111111111111

local IdleHydrationLane: Lane = --[[                    ]]
	0b0001000000000000000000000000000
exports.IdleHydrationLane = IdleHydrationLane
local IdleLanes: Lanes = --[[                           ]]
	0b0110000000000000000000000000000

local OffscreenLane: Lane = --[[                        ]]
	0b1000000000000000000000000000000
exports.OffscreenLane = OffscreenLane

local NoTimestamp = -1
exports.NoTimestamp = NoTimestamp

local currentUpdateLanePriority: LanePriority = exports.NoLanePriority

exports.getCurrentUpdateLanePriority = function(): LanePriority
	return currentUpdateLanePriority
end

exports.setCurrentUpdateLanePriority = function(newLanePriority: LanePriority)
	currentUpdateLanePriority = newLanePriority
end

-- // "Registers" used to "return" multiple values
-- // Used by getHighestPriorityLanes and getNextLanes:
local return_highestLanePriority: LanePriority = exports.DefaultLanePriority

local function getHighestPriorityLanes(lanes: Lanes | Lane): Lanes
	if bit32.band(SyncLane, lanes) ~= NoLanes then
		return_highestLanePriority = SyncLanePriority
		return SyncLane
	end
	if bit32.band(SyncBatchedLane, lanes) ~= NoLanes then
		return_highestLanePriority = SyncBatchedLanePriority
		return SyncBatchedLane
	end
	if bit32.band(InputDiscreteHydrationLane, lanes) ~= NoLanes then
		return_highestLanePriority = InputDiscreteHydrationLanePriority
		return InputDiscreteHydrationLane
	end
	local inputDiscreteLanes = bit32.band(InputDiscreteLanes, lanes)
	if inputDiscreteLanes ~= NoLanes then
		return_highestLanePriority = InputDiscreteLanePriority
		return inputDiscreteLanes
	end
	if bit32.band(lanes, InputContinuousHydrationLane) ~= NoLanes then
		return_highestLanePriority = InputContinuousHydrationLanePriority
		return InputContinuousHydrationLane
	end
	local inputContinuousLanes = bit32.band(InputContinuousLanes, lanes)
	if inputContinuousLanes ~= NoLanes then
		return_highestLanePriority = InputContinuousLanePriority
		return inputContinuousLanes
	end
	if bit32.band(lanes, DefaultHydrationLane) ~= NoLanes then
		return_highestLanePriority = DefaultHydrationLanePriority
		return DefaultHydrationLane
	end
	local defaultLanes = bit32.band(DefaultLanes, lanes)
	if defaultLanes ~= NoLanes then
		return_highestLanePriority = DefaultLanePriority
		return defaultLanes
	end
	if bit32.band(lanes, TransitionHydrationLane) ~= NoLanes then
		return_highestLanePriority = TransitionHydrationPriority
		return TransitionHydrationLane
	end
	local transitionLanes = bit32.band(TransitionLanes, lanes)
	if transitionLanes ~= NoLanes then
		return_highestLanePriority = TransitionPriority
		return transitionLanes
	end
	local retryLanes = bit32.band(RetryLanes, lanes)
	if retryLanes ~= NoLanes then
		return_highestLanePriority = RetryLanePriority
		return retryLanes
	end
	if bit32.band(lanes, SelectiveHydrationLane) ~= 0 then
		return_highestLanePriority = SelectiveHydrationLanePriority
		return SelectiveHydrationLane
	end
	if bit32.band(lanes, IdleHydrationLane) ~= NoLanes then
		return_highestLanePriority = IdleHydrationLanePriority
		return IdleHydrationLane
	end
	local idleLanes = bit32.band(IdleLanes, lanes)
	if idleLanes ~= NoLanes then
		return_highestLanePriority = IdleLanePriority
		return idleLanes
	end
	if bit32.band(OffscreenLane, lanes) ~= NoLanes then
		return_highestLanePriority = OffscreenLanePriority
		return OffscreenLane
	end
	if _G.__DEV__ then
		console.error("Should have found matching lanes. This is a bug in React.")
	end
	-- // This shouldn't be reachable, but as a fallback, return the entire bitmask.
	return_highestLanePriority = DefaultLanePriority
	return lanes
end

local function schedulerPriorityToLanePriority(
	schedulerPriorityLevel: ReactPriorityLevel
): LanePriority
	if schedulerPriorityLevel == ImmediateSchedulerPriority then
		return SyncLanePriority
	elseif schedulerPriorityLevel == UserBlockingSchedulerPriority then
		return InputContinuousLanePriority
	elseif
		schedulerPriorityLevel == NormalSchedulerPriority
		or schedulerPriorityLevel == LowSchedulerPriority
	then
		-- // TODO: Handle LowSchedulerPriority, somehow. Maybe the same lane as hydration.
		return DefaultLanePriority
	elseif schedulerPriorityLevel == IdleSchedulerPriority then
		return IdleLanePriority
	else
		return NoLanePriority
	end
end
exports.schedulerPriorityToLanePriority = schedulerPriorityToLanePriority

local function lanePriorityToSchedulerPriority(
	lanePriority: LanePriority
): ReactPriorityLevel
	if lanePriority == SyncLanePriority or lanePriority == SyncBatchedLanePriority then
		return ImmediateSchedulerPriority
	elseif
		lanePriority == InputDiscreteHydrationLanePriority
		or lanePriority == InputDiscreteLanePriority
		or lanePriority == InputContinuousHydrationLanePriority
		or lanePriority == InputContinuousLanePriority
	then
		return UserBlockingSchedulerPriority
	elseif
		lanePriority == DefaultHydrationLanePriority
		or lanePriority == DefaultLanePriority
		or lanePriority == TransitionHydrationPriority
		or lanePriority == TransitionPriority
		or lanePriority == SelectiveHydrationLanePriority
		or lanePriority == RetryLanePriority
	then
		return NormalSchedulerPriority
	elseif
		lanePriority == IdleHydrationLanePriority
		or lanePriority == IdleLanePriority
		or lanePriority == OffscreenLanePriority
	then
		return IdleSchedulerPriority
	elseif lanePriority == NoLanePriority then
		return NoSchedulerPriority
	else
		invariant(
			false,
			"Invalid update priority: %s. This is a bug in React.",
			lanePriority
		)
		-- deviation: luau doesn't know that invariant throws, so we error
		error("unreachable")
	end
end
exports.lanePriorityToSchedulerPriority = lanePriorityToSchedulerPriority

-- deviation: pre-declare pickArbitraryLaneIndex to keep ordering
local pickArbitraryLaneIndex, getLowestPriorityLane, getEqualOrHigherPriorityLanes

local function getNextLanes(root: FiberRoot, wipLanes: Lanes): Lanes
	-- // Early bailout if there's no pending work left.
	local pendingLanes = root.pendingLanes
	if pendingLanes == NoLanes then
		return_highestLanePriority = NoLanePriority
		return NoLanes
	end

	local nextLanes = NoLanes
	local nextLanePriority = NoLanePriority

	local expiredLanes = root.expiredLanes
	local suspendedLanes = root.suspendedLanes
	local pingedLanes = root.pingedLanes

	-- // Check if any work has expired.
	if expiredLanes ~= NoLanes then
		nextLanes = expiredLanes
		return_highestLanePriority = SyncLanePriority
		nextLanePriority = SyncLanePriority
	else
		-- // Do not work on any idle work until all the non-idle work has finished,
		-- // even if the work is suspended.
		local nonIdlePendingLanes = bit32.band(pendingLanes, NonIdleLanes)
		if nonIdlePendingLanes ~= NoLanes then
			local nonIdleUnblockedLanes =
				bit32.band(nonIdlePendingLanes, bit32.bnot(suspendedLanes))
			if nonIdleUnblockedLanes ~= NoLanes then
				nextLanes = getHighestPriorityLanes(nonIdleUnblockedLanes)
				nextLanePriority = return_highestLanePriority
			else
				local nonIdlePingedLanes = bit32.band(nonIdlePendingLanes, pingedLanes)
				if nonIdlePingedLanes ~= NoLanes then
					nextLanes = getHighestPriorityLanes(nonIdlePingedLanes)
					nextLanePriority = return_highestLanePriority
				end
			end
		else
			-- // The only remaining work is Idle.
			local unblockedLanes = bit32.band(pendingLanes, bit32.bnot(suspendedLanes))
			if unblockedLanes ~= NoLanes then
				nextLanes = getHighestPriorityLanes(unblockedLanes)
				nextLanePriority = return_highestLanePriority
			else
				if pingedLanes ~= NoLanes then
					nextLanes = getHighestPriorityLanes(pingedLanes)
					nextLanePriority = return_highestLanePriority
				end
			end
		end
	end

	if nextLanes == NoLanes then
		-- // This should only be reachable if we're suspended
		-- // TODO: Consider warning in this path if a fallback timer is not scheduled.
		return NoLanes
	end

	-- // If there are higher priority lanes, we'll include them even if they
	-- // are suspended.
	-- ROBLOX performance: inline getEqualOrHigherPriorityLanes to avoid function call overhead in hot path
	-- nextLanes = bit32.band(pendingLanes, getEqualOrHigherPriorityLanes(nextLanes))
	nextLanes =
		bit32.band(pendingLanes, bit32.lshift(getLowestPriorityLane(nextLanes), 1) - 1)

	-- // If we're already in the middle of a render, switching lanes will interrupt
	-- // it and we'll lose our progress. We should only do this if the new lanes are
	-- // higher priority.
	if
		wipLanes ~= NoLanes
		and wipLanes ~= nextLanes
		-- // If we already suspended with a delay, then interrupting is fine. Don't
		-- // bother waiting until the root is complocale.
		and bit32.band(wipLanes, suspendedLanes) == NoLanes
	then
		getHighestPriorityLanes(wipLanes)
		local wipLanePriority = return_highestLanePriority
		if nextLanePriority <= wipLanePriority then
			return wipLanes
		else
			return_highestLanePriority = nextLanePriority
		end
	end

	-- // Check for entangled lanes and add them to the batch.
	-- //
	-- // A lane is said to be entangled with another when it's not allowed to render
	-- // in a batch that does not also include the other lane. Typically we do this
	-- // when multiple updates have the same source, and we only want to respond to
	-- // the most recent event from that source.
	-- //
	-- // Note that we apply entanglements *after* checking for partial work above.
	-- // This means that if a lane is entangled during an interleaved event while
	-- // it's already rendering, we won't interrupt it. This is intentional, since
	-- // entanglement is usually "best effort": we'll try our best to render the
	-- // lanes in the same batch, but it's not worth throwing out partially
	-- // complocaled work in order to do it.
	-- //
	-- // For those exceptions where entanglement is semantically important, like
	-- // useMutableSource, we should ensure that there is no partial work at the
	-- // time we apply the entanglement.
	local entangledLanes = root.entangledLanes
	if entangledLanes ~= NoLanes then
		local entanglements = root.entanglements
		local lanes = bit32.band(nextLanes, entangledLanes)
		while lanes > 0 do
			local index = pickArbitraryLaneIndex(lanes)
			local lane = bit32.lshift(1, index)

			nextLanes = bit32.bor(nextLanes, entanglements[index])

			lanes = bit32.band(lanes, bit32.bnot(lane))
		end
	end

	return nextLanes
end
exports.getNextLanes = getNextLanes

local function getMostRecentEventTime(root: FiberRoot, lanes: Lanes): number
	local eventTimes = root.eventTimes

	local mostRecentEventTime = NoTimestamp
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		local eventTime = eventTimes[index]
		if eventTime > mostRecentEventTime then
			mostRecentEventTime = eventTime
		end

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end

	return mostRecentEventTime
end
exports.getMostRecentEventTime = getMostRecentEventTime

local function computeExpirationTime(lane: Lane, currentTime: number)
	-- // TODO: Expiration heuristic is constant per lane, so could use a map.
	getHighestPriorityLanes(lane)
	local priority = return_highestLanePriority
	if priority >= InputContinuousLanePriority then
		-- // User interactions should expire slightly more quickly.
		-- //
		-- // NOTE: This is set to the corresponding constant as in Scheduler.js. When
		-- // we made it larger, a product metric in www regressed, suggesting there's
		-- // a user interaction that's being starved by a series of synchronous
		-- // updates. If that theory is correct, the proper solution is to fix the
		-- // starvation. However, this scenario supports the idea that expiration
		-- // times are an important safeguard when starvation does happen.
		-- //
		-- // Also note that, in the case of user input specifically, this will soon no
		-- // longer be an issue because we plan to make user input synchronous by
		-- // default (until you enter `startTransition`, of course.)
		-- //
		-- // If weren't planning to make these updates synchronous soon anyway, I
		-- // would probably make this number a configurable parameter.
		return currentTime + 250
	elseif priority >= TransitionPriority then
		return currentTime + 5000
	else
		-- // Anything idle priority or lower should never expire.
		return NoTimestamp
	end
end
exports.computeExpirationTime = computeExpirationTime

local function markStarvedLanesAsExpired(root: FiberRoot, currentTime: number)
	-- // TODO: This gets called every time we yield. We can optimize by storing
	-- // the earliest expiration time on the root. Then use that to quickly bail out
	-- // of this function.

	local pendingLanes = root.pendingLanes
	local suspendedLanes = root.suspendedLanes
	local pingedLanes = root.pingedLanes
	local expirationTimes = root.expirationTimes

	-- // Iterate through the pending lanes and check if we've reached their
	-- // expiration time. If so, we'll assume the update is being starved and mark
	-- // it as expired to force it to finish.
	local lanes = pendingLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		local expirationTime = expirationTimes[index]
		if expirationTime == NoTimestamp then
			-- // Found a pending lane with no expiration time. If it's not suspended, or
			-- // if it's pinged, assume it's CPU-bound. Compute a new expiration time
			-- // using the current time.
			if
				bit32.band(lane, suspendedLanes) == NoLanes
				or bit32.band(lane, pingedLanes) ~= NoLanes
			then
				-- // Assumes timestamps are monotonically increasing.
				expirationTimes[index] = computeExpirationTime(lane, currentTime)
			end
		elseif expirationTime <= currentTime then
			-- // This lane expired
			root.expiredLanes = bit32.bor(root.expiredLanes, lane)
		end

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markStarvedLanesAsExpired = markStarvedLanesAsExpired

-- // This returns the highest priority pending lanes regardless of whether they
-- // are suspended.
local function getHighestPriorityPendingLanes(root: FiberRoot)
	return getHighestPriorityLanes(root.pendingLanes)
end
exports.getHighestPriorityPendingLanes = getHighestPriorityPendingLanes

local function getLanesToRetrySynchronouslyOnError(root: FiberRoot): Lanes
	local everythingButOffscreen =
		bit32.band(root.pendingLanes, bit32.bnot(OffscreenLane))
	if everythingButOffscreen ~= NoLanes then
		return everythingButOffscreen
	end
	if bit32.band(everythingButOffscreen, OffscreenLane) ~= 0 then
		return OffscreenLane
	end
	return NoLanes
end
exports.getLanesToRetrySynchronouslyOnError = getLanesToRetrySynchronouslyOnError

local function returnNextLanesPriority()
	return return_highestLanePriority
end
exports.returnNextLanesPriority = returnNextLanesPriority

local function includesNonIdleWork(lanes: Lanes)
	return bit32.band(lanes, NonIdleLanes) ~= NoLanes
end
exports.includesNonIdleWork = includesNonIdleWork

local function includesOnlyRetries(lanes: Lanes)
	return bit32.band(lanes, RetryLanes) == lanes
end
exports.includesOnlyRetries = includesOnlyRetries

local function includesOnlyTransitions(lanes: Lanes)
	return bit32.band(lanes, TransitionLanes) == lanes
end
exports.includesOnlyTransitions = includesOnlyTransitions

-- deviation: pre-declare pickArbitraryLane to keep ordering
local pickArbitraryLane

-- // To ensure consistency across multiple updates in the same event, this should
-- // be a pure function, so that it always returns the same lane for given inputs.
local function findUpdateLane(lanePriority: LanePriority, wipLanes: Lanes): Lane
	if lanePriority == NoLanePriority then
		-- break
	elseif lanePriority == SyncLanePriority then
		return SyncLane
	elseif lanePriority == SyncBatchedLanePriority then
		return SyncBatchedLane
	elseif lanePriority == InputDiscreteLanePriority then
		local lane =
			pickArbitraryLane(bit32.band(InputDiscreteLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // Shift to the next priority level
			return findUpdateLane(InputContinuousLanePriority, wipLanes)
		end
		return lane
	elseif lanePriority == InputContinuousLanePriority then
		local lane =
			pickArbitraryLane(bit32.band(InputContinuousLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // Shift to the next priority level
			return findUpdateLane(DefaultLanePriority, wipLanes)
		end
		return lane
	elseif lanePriority == DefaultLanePriority then
		local lane = pickArbitraryLane(bit32.band(DefaultLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // If all the default lanes are already being worked on, look for a
			-- // lane in the transition range.
			lane = pickArbitraryLane(bit32.band(TransitionLanes, bit32.bnot(wipLanes)))
			if lane == NoLane then
				-- // All the transition lanes are taken, too. This should be very
				-- // rare, but as a last resort, pick a default lane. This will have
				-- // the effect of interrupting the current work-in-progress render.
				lane = pickArbitraryLane(DefaultLanes)
			end
		end
		return lane
	elseif
		lanePriority == TransitionPriority -- // Should be handled by findTransitionLane instead
		or lanePriority == RetryLanePriority -- // Should be handled by findRetryLane instead
	then
		-- break
	elseif lanePriority == IdleLanePriority then
		local lane = pickArbitraryLane(bit32.band(IdleLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			lane = pickArbitraryLane(IdleLanes)
		end
		return lane
		-- // The remaining priorities are not valid for updates
	
end
	invariant(false, "Invalid update priority: %s. This is a bug in React.", lanePriority)
	-- deviation: luau doesn't know that invariant throws, so we error
	error("unreachable")
end
exports.findUpdateLane = findUpdateLane

-- // To ensure consistency across multiple updates in the same event, this should
-- // be pure function, so that it always returns the same lane for given inputs.
local function findTransitionLane(wipLanes: Lanes, pendingLanes: Lanes): Lane
	-- // First look for lanes that are completely unclaimed, i.e. have no
	-- // pending work.
	local lane = pickArbitraryLane(bit32.band(TransitionLanes, bit32.bnot(pendingLanes)))
	if lane == NoLane then
		-- // If all lanes have pending work, look for a lane that isn't currently
		-- // being worked on.
		lane = pickArbitraryLane(bit32.band(TransitionLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // If everything is being worked on, pick any lane. This has the
			-- // effect of interrupting the current work-in-progress.
			lane = pickArbitraryLane(TransitionLanes)
		end
	end
	return lane
end
exports.findTransitionLane = findTransitionLane

-- // To ensure consistency across multiple updates in the same event, this should
-- // be pure function, so that it always returns the same lane for given inputs.
local function findRetryLane(wipLanes: Lanes): Lane
	-- // This is a fork of `findUpdateLane` designed specifically for Suspense
	-- // "retries" — a special update that attempts to flip a Suspense boundary
	-- // from its placeholder state to its primary/resolved state.
	local lane = pickArbitraryLane(bit32.band(RetryLanes, bit32.bnot(wipLanes)))
	if lane == NoLane then
		lane = pickArbitraryLane(RetryLanes)
	end
	return lane
end
exports.findRetryLane = findRetryLane

local function getHighestPriorityLane(lanes: Lanes)
	return bit32.band(lanes, -lanes)
end

function getLowestPriorityLane(lanes: Lanes): Lane
	-- // This finds the most significant non-zero bit.
	local index = 31 - bit32.countlz(lanes)
	if index < 0 then
		return NoLanes
	else
		return bit32.lshift(1, index)
	end
end

function getEqualOrHigherPriorityLanes(lanes: Lanes | Lane): Lanes
	return bit32.lshift(getLowestPriorityLane(lanes), 1) - 1
end

function pickArbitraryLane(lanes: Lanes): Lane
	-- // This wrapper function gets inlined. Only exists so to communicate that it
	-- // doesn't matter which bit is selected; you can pick any bit without
	-- // affecting the algorithms where its used. Here I'm using
	-- // getHighestPriorityLane because it requires the fewest operations.
	return getHighestPriorityLane(lanes)
end
exports.pickArbitraryLane = pickArbitraryLane

function pickArbitraryLaneIndex(lanes: Lanes)
	return 31 - bit32.countlz(lanes)
end

-- ROBLOX performance: all uses have been inlined
-- local function laneToIndex(lane: Lane)
-- 	return pickArbitraryLaneIndex(lane)
-- end

local function includesSomeLane(a: Lanes | Lane, b: Lanes | Lane)
	return bit32.band(a, b) ~= NoLanes
end
exports.includesSomeLane = includesSomeLane

local function isSubsetOfLanes(set: Lanes, subset: Lanes | Lane)
	return bit32.band(set, subset) == subset
end
exports.isSubsetOfLanes = isSubsetOfLanes

local function mergeLanes(a: Lanes | Lane, b: Lanes | Lane): Lanes
	return bit32.bor(a, b)
end
exports.mergeLanes = mergeLanes

local function removeLanes(set: Lanes, subset: Lanes | Lane): Lanes
	return bit32.band(set, bit32.bnot(subset))
end
exports.removeLanes = removeLanes

-- // Seems redundant, but it changes the type from a single lane (used for
-- // updates) to a group of lanes (used for flushing work).
local function laneToLanes(lane: Lane): Lanes
	return lane
end
exports.laneToLanes = laneToLanes

local function higherPriorityLane(a: Lane, b: Lane)
	-- // This works because the bit ranges decrease in priority as you go left.
	if a ~= NoLane and b ~= NoLane then
		if a < b then
			return a
		end
		return b
	else
		if a ~= NoLane then
			return a
		end
		return b
	end
end
exports.higherPriorityLane = higherPriorityLane

local function higherLanePriority(a: LanePriority, b: LanePriority): LanePriority
	if a ~= NoLanePriority and a > b then
		return a
	else
		return b
	end
end
exports.higherLanePriority = higherLanePriority

-- deviation: luau does not support generic functions yet
-- local function createLaneMap<T>(initial: T): LaneMap<T>
local function createLaneMap(initial): LaneMap<any>
	-- // Intentionally pushing one by one.
	-- // https://v8.dev/blog/elements-kinds#avoid-creating-holes
	-- ROBLOX performance: manually unroll this loop so the table creation is a one-shot
	--for i = 0, TotalLanes do
	local laneMap = {
		[0] = initial,
		[1] = initial,
		[2] = initial,
		[3] = initial,
		[4] = initial,
		[5] = initial,
		[6] = initial,
		[7] = initial,
		[8] = initial,
		[9] = initial,
		[10] = initial,
		[11] = initial,
		[12] = initial,
		[13] = initial,
		[14] = initial,
		[15] = initial,
		[16] = initial,
		[17] = initial,
		[18] = initial,
		[19] = initial,
		[20] = initial,
		[21] = initial,
		[22] = initial,
		[23] = initial,
		[24] = initial,
		[25] = initial,
		[26] = initial,
		[27] = initial,
		[28] = initial,
		[29] = initial,
		[30] = initial,
		[31] = initial,
		-- ROBLOX TODO: must be updated when TotalLanes is updated!
	}
	return laneMap
end
exports.createLaneMap = createLaneMap

local function markRootUpdated(root: FiberRoot, updateLane: Lane, eventTime: number)
	root.pendingLanes = bit32.bor(root.pendingLanes, updateLane)

	-- // TODO: Theoretically, any update to any lane can unblock any other lane. But
	-- // it's not practical to try every single possible combination. We need a
	-- // heuristic to decide which lanes to attempt to render, and in which batches.
	-- // For now, we use the same heuristic as in the old ExpirationTimes model:
	-- // retry any lane at equal or lower priority, but don't try updates at higher
	-- // priority without also including the lower priority updates. This works well
	-- // when considering updates across different priority levels, but isn't
	-- // sufficient for updates within the same priority, since we want to treat
	-- // those updates as parallel.

	-- // Unsuspend any update at equal or lower priority.
	local higherPriorityLanes = updateLane - 1 -- // Turns 0b1000 into 0b0111

	root.suspendedLanes = bit32.band(root.suspendedLanes, higherPriorityLanes)
	root.pingedLanes = bit32.band(root.pingedLanes, higherPriorityLanes)

	local eventTimes = root.eventTimes
	-- ROBLOX performance: inline laneToIndex in hot path
	-- local index = laneToIndex(updateLane)
	local index = 31 - bit32.countlz(updateLane)
	-- // We can always overwrite an existing timestamp because we prefer the most
	-- // recent event, and we assume time is monotonically increasing.
	eventTimes[index] = eventTime
end
exports.markRootUpdated = markRootUpdated

local function markRootSuspended(root: FiberRoot, suspendedLanes: Lanes)
	root.suspendedLanes = bit32.bor(root.suspendedLanes, suspendedLanes)
	root.pingedLanes = bit32.band(root.pingedLanes, bit32.bnot(suspendedLanes))

	-- // The suspended lanes are no longer CPU-bound. Clear their expiration times.
	local expirationTimes = root.expirationTimes
	local lanes = suspendedLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		expirationTimes[index] = NoTimestamp

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markRootSuspended = markRootSuspended

local function markRootPinged(root: FiberRoot, pingedLanes: Lanes, eventTime: number)
	root.pingedLanes =
		bit32.bor(root.pingedLanes, bit32.band(root.suspendedLanes, pingedLanes))
end
exports.markRootPinged = markRootPinged

local function markRootExpired(root: FiberRoot, expiredLanes: Lanes)
	root.expiredLanes =
		bit32.bor(root.expiredLanes, bit32.band(expiredLanes, root.pendingLanes))
end
exports.markRootExpired = markRootExpired

local function markDiscreteUpdatesExpired(root: FiberRoot)
	root.expiredLanes =
		bit32.bor(root.expiredLanes, bit32.band(InputDiscreteLanes, root.pendingLanes))
end
exports.markDiscreteUpdatesExpired = markDiscreteUpdatesExpired

local function hasDiscreteLanes(lanes: Lanes)
	return bit32.band(lanes, InputDiscreteLanes) ~= NoLanes
end
exports.hasDiscreteLanes = hasDiscreteLanes

local function markRootMutableRead(root: FiberRoot, updateLane: Lane)
	root.mutableReadLanes =
		bit32.bor(root.mutableReadLanes, bit32.band(updateLane, root.pendingLanes))
end
exports.markRootMutableRead = markRootMutableRead

local function markRootFinished(root: FiberRoot, remainingLanes: Lanes)
	local noLongerPendingLanes = bit32.band(root.pendingLanes, bit32.bnot(remainingLanes))

	root.pendingLanes = remainingLanes

	-- // Let's try everything again
	root.suspendedLanes = 0
	root.pingedLanes = 0

	root.expiredLanes = bit32.band(root.expiredLanes, remainingLanes)
	root.mutableReadLanes = bit32.band(root.mutableReadLanes, remainingLanes)

	root.entangledLanes = bit32.band(root.entangledLanes, remainingLanes)

	local entanglements = root.entanglements
	local eventTimes = root.eventTimes
	local expirationTimes = root.expirationTimes

	-- // Clear the lanes that no longer have pending work
	local lanes = noLongerPendingLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		entanglements[index] = NoLanes
		eventTimes[index] = NoTimestamp
		expirationTimes[index] = NoTimestamp

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markRootFinished = markRootFinished

local function markRootEntangled(root: FiberRoot, entangledLanes: Lanes)
	root.entangledLanes = bit32.bor(root.entangledLanes, entangledLanes)

	local entanglements = root.entanglements
	local lanes = entangledLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		entanglements[index] = bit32.bor(entanglements[index], entangledLanes)

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markRootEntangled = markRootEntangled

local function getBumpedLaneForHydration(root: FiberRoot, renderLanes: Lanes): Lane
	getHighestPriorityLanes(renderLanes)
	local highestLanePriority = return_highestLanePriority

	local lane

	if
		highestLanePriority == SyncLanePriority
		or highestLanePriority == SyncBatchedLanePriority
	then
		lane = NoLane
	elseif
		highestLanePriority == InputDiscreteHydrationLanePriority
		or highestLanePriority == InputDiscreteLanePriority
	then
		lane = InputDiscreteHydrationLane
	elseif
		highestLanePriority == InputContinuousHydrationLanePriority
		or highestLanePriority == InputContinuousLanePriority
	then
		lane = InputContinuousHydrationLane
	elseif
		highestLanePriority == DefaultHydrationLanePriority
		or highestLanePriority == DefaultLanePriority
	then
		lane = DefaultHydrationLane
	elseif
		highestLanePriority == TransitionHydrationPriority
		or highestLanePriority == TransitionPriority
	then
		lane = TransitionHydrationLane
	elseif highestLanePriority == RetryLanePriority then
		-- // Shouldn't be reachable under normal circumstances, so there's no
		-- // dedicated lane for retry priority. Use the one for long transitions.
		lane = TransitionHydrationLane
	elseif highestLanePriority == SelectiveHydrationLanePriority then
		lane = SelectiveHydrationLane
	elseif
		highestLanePriority == IdleHydrationLanePriority
		or highestLanePriority == IdleLanePriority
	then
		lane = IdleHydrationLane
	elseif
		highestLanePriority == OffscreenLanePriority
		or highestLanePriority == NoLanePriority
	then
		lane = NoLane
	else
		invariant(false, "Invalid lane: %s. This is a bug in React.", tostring(lane))
	end

	-- // Check if the lane we chose is suspended. If so, that indicates that we
	-- // already attempted and failed to hydrate at that level. Also check if we're
	-- // already rendering that lane, which is rare but could happen.
	if bit32.band(lane, bit32.bor(root.suspendedLanes, renderLanes)) ~= NoLane then
		-- // Give up trying to hydrate and fall back to client render.
		return NoLane
	end

	return lane
end
exports.getBumpedLaneForHydration = getBumpedLaneForHydration

return exports

end,
["react-reconciler/ReactFiberLazyComponent.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberLazyComponent.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

type Object = { [any]: any }

local function resolveDefaultProps(Component: any, baseProps: Object): Object
	-- ROBLOX deviation: check if type is table before checking defaultProps to prevent non-table index
	if Component and typeof(Component) == "table" and Component.defaultProps then
		-- Resolve default props. Taken from ReactElement
		-- ROBLOX FIXME Luau: hard cast to object until we can model this better in Luau. avoids Expected type table, got 'Object & any & any & { [any]: any }' instead
		local props = table.clone(baseProps) :: Object
		local defaultProps = Component.defaultProps
		for propName, _ in defaultProps do
			if props[propName] == nil then
				props[propName] = defaultProps[propName]
			end
		end
		return props
	end
	return baseProps
end

return {
	resolveDefaultProps = resolveDefaultProps,
}

end,
["react-reconciler/ReactFiberNewContext.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/1eaafc9ade46ba708b2361b324dd907d019e3939/packages/react-reconciler/src/ReactFiberNewContext.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Number = LuauPolyfill.Number
local Error = LuauPolyfill.Error

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactContext<T> = ReactTypes.ReactContext<T>
local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type ContextDependency<T> = ReactInternalTypes.ContextDependency<T>

local ReactFiberStack = require(script.Parent:WaitForChild('ReactFiberStack.new'))
type StackCursor<T> = ReactFiberStack.StackCursor<T>
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
local ReactUpdateQueue = require(script.Parent:WaitForChild('ReactUpdateQueue.new'))
type SharedQueue<T> = ReactUpdateQueue.SharedQueue<T>

local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
local isPrimaryRenderer = ReactFiberHostConfig.isPrimaryRenderer
local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop
local MAX_SIGNED_31_BIT_INT = require(script.Parent:WaitForChild('MaxInts')).MAX_SIGNED_31_BIT_INT
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local ContextProvider = ReactWorkTags.ContextProvider
local ClassComponent = ReactWorkTags.ClassComponent
-- local DehydratedFragment = ReactWorkTags.DehydratedFragment
local NoLanes = ReactFiberLane.NoLanes
local NoTimestamp = ReactFiberLane.NoTimestamp
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local includesSomeLane = ReactFiberLane.includesSomeLane
local mergeLanes = ReactFiberLane.mergeLanes
local pickArbitraryLane = ReactFiberLane.pickArbitraryLane

local is = require(script.Parent.Parent:WaitForChild('shared')).objectIs
local createUpdate = ReactUpdateQueue.createUpdate
local ForceUpdate = ReactUpdateQueue.ForceUpdate
-- deviation: passed in as an arg to eliminate cycle
-- local markWorkInProgressReceivedUpdate = require("./ReactFiberBeginWork.new.luau").markWorkInProgressReceivedUpdate
-- local enableSuspenseServerRenderer = require("@pkg/@jsdotlua/shared").ReactFeatureFlags.enableSuspenseServerRenderer

local exports = {}

local valueCursor: StackCursor<any> = createCursor(nil)

local rendererSigil
if _G.__DEV__ then
	-- Use this to detect multiple renderers using the same context
	rendererSigil = {}
end

local currentlyRenderingFiber: Fiber | nil 
local lastContextDependency: ContextDependency<any> | nil 
local lastContextWithAllBitsObserved: ReactContext<any> | nil 

local isDisallowedContextReadInDEV: boolean = false

exports.resetContextDependencies = function(): ()
	-- This is called right before React yields execution, to ensure `readContext`
	-- cannot be called outside the render phase.
	currentlyRenderingFiber = nil
	lastContextDependency = nil
	lastContextWithAllBitsObserved = nil
	if _G.__DEV__ then
		isDisallowedContextReadInDEV = false
	end
end

exports.enterDisallowedContextReadInDEV = function(): ()
	if _G.__DEV__ then
		isDisallowedContextReadInDEV = true
	end
end

exports.exitDisallowedContextReadInDEV = function(): ()
	if _G.__DEV__ then
		isDisallowedContextReadInDEV = false
	end
end

exports.pushProvider = function<T>(providerFiber: Fiber, nextValue: T): ()
	local context: ReactContext<T> = providerFiber.type._context

	if isPrimaryRenderer then
		push(valueCursor, context._currentValue, providerFiber)

		context._currentValue = nextValue
		if _G.__DEV__ then
			if
				context._currentRenderer ~= nil
				and context._currentRenderer ~= rendererSigil
			then
				console.error(
[[Detected multiple renderers concurrently rendering the same context provider. This is currently unsupported.]]				

)
			end
			context._currentRenderer = rendererSigil
		end
	else
		push(valueCursor, context._currentValue2, providerFiber)

		context._currentValue2 = nextValue
		if _G.__DEV__ then
			if
				context._currentRenderer2 ~= nil
				and context._currentRenderer2 ~= rendererSigil
			then
				console.error(
[[Detected multiple renderers concurrently rendering the same context provider. This is currently unsupported.]]				

)
			end
			context._currentRenderer2 = rendererSigil
		end
	end
end

exports.popProvider = function(providerFiber: Fiber)
	local currentValue = valueCursor.current

	pop(valueCursor, providerFiber)

	local context: ReactContext<any> = providerFiber.type._context
	if isPrimaryRenderer then
		context._currentValue = currentValue
	else
		context._currentValue2 = currentValue
	end
end

exports.calculateChangedBits =
	function<T>(context: ReactContext<T>, newValue: T, oldValue: T)
		if is(oldValue, newValue) then
			-- No change
			return 0
		else
			-- deviation: unravel ternary that's unsafe to translate
			local changedBits = MAX_SIGNED_31_BIT_INT
			if typeof(context._calculateChangedBits) == "function" then
				changedBits = context._calculateChangedBits(oldValue, newValue)
			end

			-- ROBLOX performance: eliminate nice-to-have compare in hot path that's removed in React 18
			-- if _G.__DEV__ then
			--   if bit32.band(changedBits, MAX_SIGNED_31_BIT_INT) ~= changedBits then
			--     console.error(
			--       "calculateChangedBits: Expected the return value to be a " ..
			--         "31-bit integer. Instead received: %s",
			--       changedBits
			--     )
			--   end
			-- end
			-- deviation: JS does a bitwise OR with 0 presumably to floor the value and
			-- coerce to an int; we just use math.floor
			return math.floor(changedBits)
		end
	end

exports.scheduleWorkOnParentPath = function(parent: Fiber | nil, renderLanes: Lanes)
	-- Update the child lanes of all the ancestors, including the alternates.
	local node = parent
	while node ~= nil do
		local alternate = node.alternate
		if not isSubsetOfLanes(node.childLanes, renderLanes) then
			node.childLanes = mergeLanes(node.childLanes, renderLanes)
			if alternate ~= nil then
				alternate.childLanes = mergeLanes(alternate.childLanes, renderLanes)
			end
		elseif
			alternate ~= nil and not isSubsetOfLanes(alternate.childLanes, renderLanes)
		then
			alternate.childLanes = mergeLanes(alternate.childLanes, renderLanes)
		else
			-- Neither alternate was updated, which means the rest of the
			-- ancestor path already has sufficient priority.
			break
		end
		node = node.return_
	end
end

exports.propagateContextChange = function<T>(
	workInProgress: Fiber,
	context: ReactContext<T>,
	changedBits: number,
	renderLanes: Lanes
): ()
	local fiber = workInProgress.child
	if fiber ~= nil then
		-- Set the return pointer of the child to the work-in-progress fiber.
		fiber.return_ = workInProgress
	end
	while fiber ~= nil do
		local nextFiber

		-- Visit this fiber.
		local list = fiber.dependencies
		if list ~= nil then
			nextFiber = fiber.child

			local dependency = list.firstContext
			while dependency ~= nil do
				-- Check if the context matches.
				if
					dependency.context == context
					-- ROBLOX performance: unstable observedBits is removed in React 18
					and bit32.band(dependency.observedBits, changedBits) ~= 0
				then
					-- Match! Schedule an update on this fiber.

					if fiber.tag == ClassComponent then
						-- Schedule a force update on the work-in-progress.
						local update =
							createUpdate(NoTimestamp, pickArbitraryLane(renderLanes))
						update.tag = ForceUpdate
						-- TODO: Because we don't have a work-in-progress, this will add the
						-- update to the current fiber, too, which means it will persist even if
						-- this render is thrown away. Since it's a race condition, not sure it's
						-- worth fixing.

						-- Inlined `enqueueUpdate` to remove interleaved update check
						local updateQueue = fiber.updateQueue
						if updateQueue == nil then
						-- Only occurs if the fiber has been unmounted.
						else
							local sharedQueue: SharedQueue<any> = (updateQueue :: any).shared
							local pending = sharedQueue.pending
							if pending == nil then
								-- This is the first update. Create a circular list.
								update.next = update
							else
								update.next = pending.next
								pending.next = update
							end
							sharedQueue.pending = update
						end
					end

					-- ROBLOX performance: inline mergeLanes(fiber.lanes, renderLanes)
					fiber.lanes = bit32.bor(fiber.lanes, renderLanes)
					local alternate = fiber.alternate
					if alternate ~= nil then
						-- ROBLOX performance: inline mergeLanes(alternate.lanes, renderLanes)
						alternate.lanes = bit32.bor(alternate.lanes, renderLanes)
					end
					exports.scheduleWorkOnParentPath(fiber.return_, renderLanes)

					-- Mark the updated lanes on the list, too.
					-- ROBLOX performance: inline mergeLanes(list.lanes, renderLanes)
					list.lanes = bit32.bor(list.lanes, renderLanes)

					-- Since we already found a match, we can stop traversing the
					-- dependency list.
					break
				end
				dependency = dependency.next
			end
		elseif fiber.tag == ContextProvider then
			-- Don't scan deeper if this is a matching provider
			if fiber.type == workInProgress.type then
				nextFiber = nil
			else
				nextFiber = fiber.child
			end
		-- ROBLOX performance: eliminate always-false compare in tab switching hot path
		-- elseif
		--   enableSuspenseServerRenderer and
		--   fiber.tag == DehydratedFragment
		-- then
		--   -- If a dehydrated suspense boundary is in this subtree, we don't know
		--   -- if it will have any context consumers in it. The best we can do is
		--   -- mark it as having updates.
		--   local parentSuspense = fiber.return_
		--   if parentSuspense == nil then
		--     error("We just came from a parent so we must have had a parent. This is a bug in React.")
		--   end
		--   parentSuspense.lanes = mergeLanes(parentSuspense.lanes, renderLanes)
		--   local alternate = parentSuspense.alternate
		--   if alternate ~= nil then
		--     alternate.lanes = mergeLanes(alternate.lanes, renderLanes)
		--   end
		--   -- This is intentionally passing this fiber as the parent
		--   -- because we want to schedule this fiber as having work
		--   -- on its children. We'll use the childLanes on
		--   -- this fiber to indicate that a context has changed.
		--   exports.scheduleWorkOnParentPath(parentSuspense, renderLanes)
		--   nextFiber = fiber.sibling
		else
			-- Traverse down.
			nextFiber = fiber.child
		end

		if nextFiber ~= nil then
			-- Set the return pointer of the child to the work-in-progress fiber.
			nextFiber.return_ = fiber
		else
			-- No child. Traverse to next sibling.
			nextFiber = fiber
			while nextFiber ~= nil do
				if nextFiber == workInProgress then
					-- We're back to the root of this subtree. Exit.
					nextFiber = nil
					break
				end
				local sibling = nextFiber.sibling
				if sibling ~= nil then
					-- Set the return pointer of the sibling to the work-in-progress fiber.
					sibling.return_ = nextFiber.return_
					nextFiber = sibling
					break
				end
				-- No more siblings. Traverse up.
				nextFiber = nextFiber.return_
			end
		end
		fiber = nextFiber
	end
end

-- deviation: third argument added to eliminate cycle
exports.prepareToReadContext = function(
	workInProgress: Fiber,
	renderLanes: Lanes,
	markWorkInProgressReceivedUpdate: () -> ()
): ()
	currentlyRenderingFiber = workInProgress
	lastContextDependency = nil
	lastContextWithAllBitsObserved = nil

	local dependencies = workInProgress.dependencies
	if dependencies ~= nil then
		local firstContext = dependencies.firstContext
		if firstContext ~= nil then
			if includesSomeLane(dependencies.lanes, renderLanes) then
				-- Context list has a pending update. Mark that this fiber performed work.
				markWorkInProgressReceivedUpdate()
			end
			-- Reset the work-in-progress list
			dependencies.firstContext = nil
		end
	end
end

exports.readContext =
	function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
		if _G.__DEV__ then
			-- This warning would fire if you read context inside a Hook like useMemo.
			-- Unlike the class check below, it's not enforced in production for perf.
			if isDisallowedContextReadInDEV then
				console.error(
[[Context can only be read while React is rendering. In classes, you can read it in the render method or getDerivedStateFromProps. In function components, you can read it directly in the function body, but not inside Hooks like useReducer() or useMemo().]]				



)
			end
		end

		if lastContextWithAllBitsObserved == context then
		-- Nothing to do. We already observe everything in this context.
		elseif observedBits == false or observedBits == 0 then
		-- Do not observe any updates.
		else
			local resolvedObservedBits -- Avoid deopting on observable arguments or heterogeneous types.
			if
				typeof(observedBits) ~= "number"
				or observedBits == Number.MAX_SAFE_INTEGER
			then
				-- Observe all updates.
				-- lastContextWithAllBitsObserved = ((context: any): ReactContext<mixed>)
				lastContextWithAllBitsObserved = context
				resolvedObservedBits = Number.MAX_SAFE_INTEGER
			else
				resolvedObservedBits = observedBits
			end

			local contextItem = {
				-- context: ((context: any): ReactContext<mixed>),
				context = context,
				observedBits = resolvedObservedBits,
				next = nil,
			}

			if lastContextDependency == nil then
				if currentlyRenderingFiber == nil then
					error(
						Error.new(
[[Context can only be read while React is rendering. In classes, you can read it in the render method or getDerivedStateFromProps. In function components, you can read it directly in the function body, but not inside Hooks like useReducer() or useMemo().]]						



)
					)
				end

				-- This is the first dependency for this component. Create a new list.
				lastContextDependency = contextItem;
				(currentlyRenderingFiber :: Fiber).dependencies = {
					lanes = NoLanes,
					firstContext = contextItem,
					responders = nil,
				}
			else
				-- Append a new context item.
				(lastContextDependency :: any).next = contextItem
				lastContextDependency = contextItem
			end
		end
		return if isPrimaryRenderer then context._currentValue else context._currentValue2
	end

return exports

end,
["react-reconciler/ReactFiberOffscreenComponent"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/1faf9e3dd5d6492f3607d5c721055819e4106bc6/packages/react-reconciler/src/ReactFiberOffscreenComponent.js
--!strict
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactNodeList = ReactTypes.ReactNodeList

local ReactFiberLanes = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLanes.Lanes

export type OffscreenProps = {
	-- TODO: Pick an API before exposing the Offscreen type. I've chosen an enum
	-- for now, since we might have multiple variants. For example, hiding the
	-- content without changing the layout.
	--
	-- Default mode is visible. Kind of a weird default for a component
	-- called "Offscreen." Possible alt: <Visibility />?
	mode: string | nil,
	children: ReactNodeList
}

-- We use the existence of the state object as an indicator that the component
-- is hidden.
export type OffscreenState = {
	-- TODO: This doesn't do anything, yet. It's always NoLanes. But eventually it
	-- will represent the pending work that must be included in the render in
	-- order to unhide the component.
	baseLanes: Lanes
}

return {}

end,
["react-reconciler/ReactFiberReconciler"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/faa697f4f9afe9f1c98e315b2a9e70f5a74a7a74/packages/react-reconciler/src/ReactFiberReconciler.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- deviation: old version of reconciler not ported
return require(script.Parent:WaitForChild('ReactFiberReconciler.new'))
end,
["react-reconciler/ReactFiberReconciler.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/50d9451f320a9aaf94304209193562cc385567d8/packages/react-reconciler/src/ReactFiberReconciler.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local __DEV__ = _G.__DEV__ :: boolean
local flowtypes = require(script.Parent.Parent:WaitForChild('shared'))
type React_Component<Props, State> = flowtypes.React_Component<Props, State>
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
type Function = (...any) -> ...any

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

type Object = { [string]: any }
type Array<T> = { [number]: T }

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type SuspenseHydrationCallbacks = ReactInternalTypes.SuspenseHydrationCallbacks
type FiberRoot = ReactInternalTypes.FiberRoot

local ReactRootTags = require(script.Parent:WaitForChild('ReactRootTags'))
type RootTag = ReactRootTags.RootTag

local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))

local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type Instance = ReactFiberHostConfig.Instance
type TextInstance = ReactFiberHostConfig.TextInstance
type Container = ReactFiberHostConfig.Container
type PublicInstance = ReactFiberHostConfig.PublicInstance
type RendererInspectionConfig = ReactFiberHostConfig.RendererInspectionConfig

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactNodeList = ReactTypes.ReactNodeList

local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lane = ReactFiberLane.Lane
type LanePriority = ReactFiberLane.LanePriority
local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local ReactFiberTreeReflection = require(script.Parent:WaitForChild('ReactFiberTreeReflection'))
local findCurrentHostFiber = ReactFiberTreeReflection.findCurrentHostFiber
local findCurrentHostFiberWithNoPortals =
	ReactFiberTreeReflection.findCurrentHostFiberWithNoPortals
local getInstance = require(script.Parent.Parent:WaitForChild('shared')).ReactInstanceMap.get
local HostComponent = ReactWorkTags.HostComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError
local enableSchedulingProfiler =
	require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.enableSchedulingProfiler
local ReactSharedInternals = require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals
local getPublicInstance = require(script.Parent:WaitForChild('ReactFiberHostConfig')).getPublicInstance
local ReactFiberContext = require(script.Parent:WaitForChild('ReactFiberContext.new'))
local findCurrentUnmaskedContext = ReactFiberContext.findCurrentUnmaskedContext
local processChildContext = ReactFiberContext.processChildContext
local emptyContextObject = ReactFiberContext.emptyContextObject
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local ReactFiberRoot = require(script.Parent:WaitForChild('ReactFiberRoot.new'))
local createFiberRoot = ReactFiberRoot.createFiberRoot
local ReactFiberDevToolsHook = require(script.Parent:WaitForChild('ReactFiberDevToolsHook.new'))
local injectInternals = ReactFiberDevToolsHook.injectInternals
local onScheduleRoot = ReactFiberDevToolsHook.onScheduleRoot
local ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new')):: any
local requestEventTime = ReactFiberWorkLoop.requestEventTime
local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local flushRoot = ReactFiberWorkLoop.flushRoot
local batchedEventUpdates = ReactFiberWorkLoop.batchedEventUpdates
local batchedUpdates = ReactFiberWorkLoop.batchedUpdates
local unbatchedUpdates = ReactFiberWorkLoop.unbatchedUpdates
local flushSync = ReactFiberWorkLoop.flushSync
local flushControlled = ReactFiberWorkLoop.flushControlled
local deferredUpdates = ReactFiberWorkLoop.deferredUpdates
local discreteUpdates = ReactFiberWorkLoop.discreteUpdates
local flushDiscreteUpdates = ReactFiberWorkLoop.flushDiscreteUpdates
local flushPassiveEffects = ReactFiberWorkLoop.flushPassiveEffects
local warnIfNotScopedWithMatchingAct = ReactFiberWorkLoop.warnIfNotScopedWithMatchingAct
local warnIfUnmockedScheduler = ReactFiberWorkLoop.warnIfUnmockedScheduler
local IsThisRendererActing = ReactFiberWorkLoop.IsThisRendererActing
local act = ReactFiberWorkLoop.act :: (() -> ()) -> ()
local ReactUpdateQueue = require(script.Parent:WaitForChild('ReactUpdateQueue.new'))
local createUpdate = ReactUpdateQueue.createUpdate
local enqueueUpdate = ReactUpdateQueue.enqueueUpdate
local ReactCurrentFiber = require(script.Parent:WaitForChild('ReactCurrentFiber'))
local ReactCurrentFiberIsRendering = ReactCurrentFiber.isRendering
-- deviation: this property would be captured as values instead of bound
-- local ReactCurrentFiber.current = ReactCurrentFiber.current
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
local StrictMode = ReactTypeOfMode.StrictMode
local SyncLane = ReactFiberLane.SyncLane
local InputDiscreteHydrationLane = ReactFiberLane.InputDiscreteHydrationLane
local SelectiveHydrationLane = ReactFiberLane.SelectiveHydrationLane
local NoTimestamp = ReactFiberLane.NoTimestamp
local getHighestPriorityPendingLanes = ReactFiberLane.getHighestPriorityPendingLanes
local higherPriorityLane = ReactFiberLane.higherPriorityLane
local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
-- local ReactFiberHotReloading = require("./ReactFiberHotReloading.new.luau")
-- local scheduleRefresh = ReactFiberHotReloading.scheduleRefresh
-- local scheduleRoot = ReactFiberHotReloading.scheduleRoot
-- local setRefreshHandler = ReactFiberHotReloading.setRefreshHandler
-- local findHostInstancesForRefresh = ReactFiberHotReloading.findHostInstancesForRefresh
local markRenderScheduled = require(script.Parent:WaitForChild('SchedulingProfiler')).markRenderScheduled

local exports = {}

-- ROBLOX deviation: explicitly export internal type definitions used by the noop and test renderers
exports.ReactRootTags = ReactRootTags
-- ROBLOX deviation: explicitly export internal type definitions used by the test renderer
exports.ReactWorkTags = ReactWorkTags

-- ROBLOX deviation: explicitly export internal type definitions used by the dev tools
exports.ReactTypeOfMode = ReactTypeOfMode
exports.ReactFiberFlags = ReactFiberFlags
exports.getNearestMountedFiber = ReactFiberTreeReflection.getNearestMountedFiber
exports.findCurrentFiberUsingSlowPath =
	ReactFiberTreeReflection.findCurrentFiberUsingSlowPath

-- exports.registerMutableSourceForHydration = require("./ReactMutableSource.new.luau").registerMutableSourceForHydration
exports.createPortal = require(script.Parent:WaitForChild('ReactPortal')).createPortal
-- local ReactTestSelectors = require("./ReactTestSelectors")
-- exports.createComponentSelector = ReactTestSelectors.createComponentSelector
-- ROBLOX FIXME: Should we deviate and fix this typo?
-- exports.createHasPsuedoClassSelector = ReactTestSelectors.createHasPsuedoClassSelector
-- exports.createRoleSelector = ReactTestSelectors.createRoleSelector
-- exports.createTestNameSelector = ReactTestSelectors.createTestNameSelector
-- exports.createTextSelector = ReactTestSelectors.createTextSelector
-- exports.getFindAllNodesFailureDescription = ReactTestSelectors.getFindAllNodesFailureDescription
-- exports.findAllNodes = ReactTestSelectors.findAllNodes
-- exports.findBoundingRects = ReactTestSelectors.findBoundingRects
-- exports.focusWithin = ReactTestSelectors.focusWithin
-- exports.observeVisibleRects = ReactTestSelectors.observeVisibleRects

type OpaqueRoot = FiberRoot

-- 0 is PROD, 1 is DEV.
-- Might add PROFILE later.
type BundleType = number

type DevToolsConfig = {
	bundleType: BundleType,
	version: string,
	rendererPackageName: string,
	-- Note: this actually *does* depend on Fiber internal fields.
	-- Used by "inspect clicked DOM element" in React DevTools.
	findFiberByHostInstance: ((Instance | TextInstance) -> Fiber)?,
	rendererConfig: RendererInspectionConfig?
}

local didWarnAboutNestedUpdates
local didWarnAboutFindNodeInStrictMode

if __DEV__ then
	didWarnAboutNestedUpdates = false
	didWarnAboutFindNodeInStrictMode = {}
end

local function getContextForSubtree(parentComponent: any?): Object
	if not parentComponent then
		return emptyContextObject
	end

	local fiber = getInstance(parentComponent)
	local parentContext = findCurrentUnmaskedContext(fiber)

	if fiber.tag == ClassComponent then
		local Component = fiber.type
		if isLegacyContextProvider(Component) then
			return processChildContext(fiber, Component, parentContext)
		end
	end

	return parentContext
end

local function findHostInstance(component: Object): PublicInstance | nil
	local fiber = getInstance(component)
	if fiber == nil then
		if typeof(component.render) == "function" then
			invariant(false, "Unable to find node on an unmounted component.")
		else
			invariant(
				false,
				"Argument appears to not be a ReactComponent. Keys: %s",
				-- ROBLOX deviation: explicitly coerce the array of strings into a string
				table.concat(Object.keys(component))
			)
		end
	end
	local hostFiber = findCurrentHostFiber(fiber)
	if hostFiber == nil then
		return nil
	end
	return hostFiber.stateNode
end

local function findHostInstanceWithWarning(
	component: Object,
	methodName: string
): PublicInstance | nil
	if __DEV__ then
		local fiber = getInstance(component)
		if fiber == nil then
			if typeof(component.render) == "function" then
				invariant(false, "Unable to find node on an unmounted component.")
			else
				invariant(
					false,
					"Argument appears to not be a ReactComponent. Keys: %s",
					-- ROBLOX deviation: explicitly convert array into string
					table.concat(Object.keys(component))
				)
			end
		end
		local hostFiber = findCurrentHostFiber(fiber)
		if hostFiber == nil then
			return nil
		end
		if bit32.band(hostFiber.mode, StrictMode) ~= 0 then
			local componentName = getComponentName(fiber.type) or "Component"
			if not didWarnAboutFindNodeInStrictMode[componentName] then
				didWarnAboutFindNodeInStrictMode[componentName] = true

				local previousFiber = ReactCurrentFiber.current
				local ok, result = xpcall(function()
					setCurrentDebugFiberInDEV(hostFiber)
					if bit32.band(fiber.mode, StrictMode) ~= 0 then
						console.error(
[[%s is deprecated in StrictMode. %s was passed an instance of %s which is inside StrictMode. Instead, add a ref directly to the element you want to reference. Learn more about using refs safely here: https://reactjs.org/link/strict-mode-find-node]]



,
							methodName,
							methodName,
							componentName
						)
					else
						console.error(
[[%s is deprecated in StrictMode. %s was passed an instance of %s which renders StrictMode children. Instead, add a ref directly to the element you want to reference. Learn more about using refs safely here: https://reactjs.org/link/strict-mode-find-node]]



,
							methodName,
							methodName,
							componentName
						)
					end
				end, describeError)

				-- Ideally this should reset to previous but this shouldn't be called in
				-- render and there's another warning for that anyway.
				if previousFiber then
					setCurrentDebugFiberInDEV(previousFiber)
				else
					resetCurrentDebugFiberInDEV()
				end

				if not ok then
					error(result)
				end
			end
		end
		return hostFiber.stateNode
	end
	return findHostInstance(component)
end

exports.createContainer = function(
	containerInfo: Container,
	tag: RootTag,
	hydrate: boolean,
	hydrationCallbacks: nil | SuspenseHydrationCallbacks
): OpaqueRoot
	return createFiberRoot(containerInfo, tag, hydrate, hydrationCallbacks)
end

exports.updateContainer = function(
	element: ReactNodeList,
	container: OpaqueRoot,
	parentComponent,
	callback: Function?
): Lane
	if __DEV__ then
		onScheduleRoot(container, element)
	end
	local current = container.current
	local eventTime = requestEventTime()
	if __DEV__ then
		-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ (no jest global)
		-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
		if _G.__TESTEZ_RUNNING_TEST__ then
			warnIfUnmockedScheduler(current)
			warnIfNotScopedWithMatchingAct(current)
		end
	end
	local lane = requestUpdateLane(current)

	if enableSchedulingProfiler then
		markRenderScheduled(lane)
	end

	local context = getContextForSubtree(parentComponent)
	if container.context == nil then
		container.context = context
	else
		container.pendingContext = context
	end

	if __DEV__ then
		if
			ReactCurrentFiberIsRendering
			and ReactCurrentFiber.current ~= nil
			and not didWarnAboutNestedUpdates
		then
			didWarnAboutNestedUpdates = true
			console.error(
[[Render methods should be a pure function of props and state; triggering nested component updates from render is not allowed. If necessary, trigger nested updates in componentDidUpdate.

Check the render method of %s.]]
,
				getComponentName((ReactCurrentFiber.current :: any).type) or "Unknown"
			)
		end
	end

	local update = createUpdate(eventTime, lane)
	-- deviation: We need to set element to a placeholder so that it gets
	-- removed from previous state when merging tables
	if element == nil then
		element = Object.None
	end
	-- Caution: React DevTools currently depends on this property
	-- being called "element".
	update.payload = {
		element = element,
	}

	-- deviation: no undefined, so not needed
	-- callback = callback == undefined ? nil : callback
	if callback ~= nil then
		if __DEV__ then
			if typeof(callback) ~= "function" then
				console.error(
[[render(...): Expected the last optional `callback` argument to be a function. Instead received: %s.]]
,
					tostring(callback)
				)
			end
		end
		update.callback = callback
	end

	enqueueUpdate(current, update)
	scheduleUpdateOnFiber(current, lane, eventTime)

	return lane
end

-- FIXME: WIP
exports.batchedEventUpdates = batchedEventUpdates
exports.batchedUpdates = batchedUpdates
exports.unbatchedUpdates = unbatchedUpdates
exports.deferredUpdates = deferredUpdates
exports.discreteUpdates = discreteUpdates
exports.flushDiscreteUpdates = flushDiscreteUpdates
exports.flushControlled = flushControlled
exports.flushSync = flushSync
exports.flushPassiveEffects = flushPassiveEffects
exports.IsThisRendererActing = IsThisRendererActing
exports.act = act

exports.getPublicRootInstance =
	function(container: OpaqueRoot): React_Component<any, any> | PublicInstance | nil
		local containerFiber = container.current
		if not containerFiber.child then
			return nil
		end
		if containerFiber.child.tag == HostComponent then
			return getPublicInstance(containerFiber.child.stateNode)
		else
			return containerFiber.child.stateNode
		end
	end

-- deviation: Declare function ahead of use
local markRetryLaneIfNotHydrated

exports.attemptSynchronousHydration = function(fiber: Fiber)
	if fiber.tag == HostRoot then
		local root: FiberRoot = fiber.stateNode
		if root.hydrate then
			-- Flush the first scheduled "update".
			local lanes = getHighestPriorityPendingLanes(root)
			flushRoot(root, lanes)
		end
	elseif fiber.tag == SuspenseComponent then
		local eventTime = requestEventTime()
		flushSync(function()
			return scheduleUpdateOnFiber(fiber, SyncLane, eventTime)
		end)
		-- If we're still blocked after this, we need to increase
		-- the priority of any promises resolving within this
		-- boundary so that they next attempt also has higher pri.
		local retryLane = InputDiscreteHydrationLane
		markRetryLaneIfNotHydrated(fiber, retryLane)
	end
end

local function markRetryLaneImpl(fiber: Fiber, retryLane: Lane)
	local suspenseState: SuspenseState? = fiber.memoizedState
	if suspenseState then
		if suspenseState ~= nil and suspenseState.dehydrated ~= nil then
			suspenseState.retryLane =
				higherPriorityLane(suspenseState.retryLane, retryLane)
		end
	end
end

-- Increases the priority of thennables when they resolve within this boundary.
markRetryLaneIfNotHydrated = function(fiber: Fiber, retryLane: Lane)
	markRetryLaneImpl(fiber, retryLane)
	-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
	local alternate = fiber.alternate
	if alternate then
		markRetryLaneImpl(alternate, retryLane)
	end
end

exports.attemptUserBlockingHydration = function(fiber: Fiber)
	if fiber.tag ~= SuspenseComponent then
		-- We ignore HostRoots here because we can't increase
		-- their priority and they should not suspend on I/O,
		-- since you have to wrap anything that might suspend in
		-- Suspense.
		return
	end
	local eventTime = requestEventTime()
	local lane = InputDiscreteHydrationLane
	scheduleUpdateOnFiber(fiber, lane, eventTime)
	markRetryLaneIfNotHydrated(fiber, lane)
end

exports.attemptContinuousHydration = function(fiber: Fiber)
	if fiber.tag ~= SuspenseComponent then
		-- We ignore HostRoots here because we can't increase
		-- their priority and they should not suspend on I/O,
		-- since you have to wrap anything that might suspend in
		-- Suspense.
		return
	end
	local eventTime = requestEventTime()
	local lane = SelectiveHydrationLane
	scheduleUpdateOnFiber(fiber, lane, eventTime)
	markRetryLaneIfNotHydrated(fiber, lane)
end

exports.attemptHydrationAtCurrentPriority = function(fiber: Fiber)
	if fiber.tag ~= SuspenseComponent then
		-- We ignore HostRoots here because we can't increase
		-- their priority other than synchronously flush it.
		return
	end
	local eventTime = requestEventTime()
	local lane = requestUpdateLane(fiber)
	scheduleUpdateOnFiber(fiber, lane, eventTime)
	markRetryLaneIfNotHydrated(fiber, lane)
end

exports.runWithPriority = function<T>(priority: LanePriority, fn: () -> T): T
	local previousPriority = getCurrentUpdateLanePriority()
	-- ROBLOX performance: hoist non-throwable out of try{} to eliminate anon function
	setCurrentUpdateLanePriority(priority)
	local ok, result = xpcall(fn, describeError)
	setCurrentUpdateLanePriority(previousPriority)
	if not ok then
		error(result)
	end
	return result
end

exports.getCurrentUpdateLanePriority = getCurrentUpdateLanePriority

exports.findHostInstance = findHostInstance

exports.findHostInstanceWithWarning = findHostInstanceWithWarning

exports.findHostInstanceWithNoPortals = function(fiber: Fiber): PublicInstance?
	local hostFiber = findCurrentHostFiberWithNoPortals(fiber)
	if hostFiber == nil then
		return nil
	end
	if hostFiber.tag == FundamentalComponent then
		return hostFiber.stateNode.instance
	end
	return hostFiber.stateNode
end

local function shouldSuspendImpl(fiber)
	return false
end

exports.shouldSuspend = function(fiber: Fiber): boolean
	return shouldSuspendImpl(fiber)
end

local overrideHookState 
local overrideHookStateDeletePath 
local overrideHookStateRenamePath 
local overrideProps 
local overridePropsDeletePath 
local overridePropsRenamePath 
local scheduleUpdate 
local setSuspenseHandler 

if __DEV__ then
	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithDeleteImpl(
		obj: Object,
		path: Array<string | number>,
		index: number
	)
		local key = path[index]
		local updated
		if Array.isArray(obj) then
			updated = Array.slice(obj)
		else
			updated = table.clone(obj)
		end
		if index + 1 == #path then
			if Array.isArray(updated) then
				-- Narrow type
				local updatedIndex: number = key
				Array.splice(updated, updatedIndex, 1)
			else
				updated[key] = nil
			end
			return updated
		end
		-- $FlowFixMe number or string is fine here
		updated[key] = copyWithDeleteImpl(obj[key], path, index + 1)
		return updated
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithDelete(
		obj: Object,
		path: Array<string | number>
	): Object | Array<any>
		return copyWithDeleteImpl(obj, path, 0)
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithRenameImpl(
		obj: Object,
		oldPath: Array<string | number>,
		newPath: Array<string | number>,
		index: number
	)
		local oldKey = oldPath[index]
		local updated
		if Array.isArray(obj) then
			updated = Array.slice(obj)
		else
			updated = table.clone(obj)
		end
		if index + 1 == #oldPath then
			local newKey = newPath[index]
			-- $FlowFixMe number or string is fine here
			updated[newKey] = updated[oldKey]
			if Array.isArray(updated) then
				Array.splice(updated, oldKey, 1)
			else
				updated[oldKey] = nil
			end
		else
			-- $FlowFixMe number or string is fine here
			updated[oldKey] = copyWithRenameImpl(
				-- $FlowFixMe number or string is fine here
				obj[oldKey],
				oldPath,
				newPath,
				index + 1
			)
		end
		return updated
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithRename(
		obj: Object,
		oldPath: Array<string | number>,
		newPath: Array<string | number>
	): Object | Array<any> | nil
		if #oldPath ~= #newPath then
			console.warn("copyWithRename() expects paths of the same length")
			return nil
		else
			for i = 1, #newPath do
				if oldPath[i] ~= newPath[i] then
					console.warn(
						"copyWithRename() expects paths to be the same except for the deepest key"
					)
					return nil
				end
			end
		end
		return copyWithRenameImpl(obj, oldPath, newPath, 0)
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithSetImpl(
		obj: Object,
		path: Array<string | number>,
		index: number,
		value: any
	)
		if index >= (#path + 1) then
			return value
		end
		local key = path[index]
		local updated
		if Array.isArray(obj) then
			updated = Array.slice(obj)
		else
			updated = table.clone(obj)
		end
		-- $FlowFixMe number or string is fine here
		updated[key] = copyWithSetImpl(obj[key], path, index + 2, value)
		return updated
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithSet(
		obj: Object,
		path: Array<string | number>,
		value: any
	): Object | Array<any>
		return copyWithSetImpl(obj, path, 1, value)
	end

	local function findHook(fiber: Fiber, id: number)
		-- For now, the "id" of stateful hooks is just the stateful hook index.
		-- This may change in the future with e.g. nested hooks.
		local currentHook = fiber.memoizedState
		while currentHook ~= nil and id > 1 do
			currentHook = currentHook.next
			id -= 1
		end
		return currentHook
	end

	-- Support DevTools editable values for useState and useReducer.
	overrideHookState =
		function(fiber: Fiber, id: number, path: Array<string | number>, value: any)
			local hook = findHook(fiber, id)
			if hook ~= nil then
				local newState = copyWithSet(hook.memoizedState, path, value)
				hook.memoizedState = newState
				hook.baseState = newState

				-- We aren't actually adding an update to the queue,
				-- because there is no update we can add for useReducer hooks that won't trigger an error.
				-- (There's no appropriate action type for DevTools overrides.)
				-- As a result though, React will see the scheduled update as a noop and bailout.
				-- Shallow cloning props works as a workaround for now to bypass the bailout check.
				fiber.memoizedProps = table.clone(fiber.memoizedProps)

				scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
			end
		end
	overrideHookStateDeletePath =
		function(fiber: Fiber, id: number, path: Array<string | number>)
			local hook = findHook(fiber, id)
			if hook ~= nil then
				local newState = copyWithDelete(hook.memoizedState, path)
				hook.memoizedState = newState
				hook.baseState = newState

				-- We aren't actually adding an update to the queue,
				-- because there is no update we can add for useReducer hooks that won't trigger an error.
				-- (There's no appropriate action type for DevTools overrides.)
				-- As a result though, React will see the scheduled update as a noop and bailout.
				-- Shallow cloning props works as a workaround for now to bypass the bailout check.
				fiber.memoizedProps = table.clone(fiber.memoizedProps)

				scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
			end
		end
	overrideHookStateRenamePath = function(
		fiber: Fiber,
		id: number,
		oldPath: Array<string | number>,
		newPath: Array<string | number>
	)
		local hook = findHook(fiber, id)
		if hook ~= nil then
			local newState = copyWithRename(hook.memoizedState, oldPath, newPath)
			hook.memoizedState = newState
			hook.baseState = newState

			-- We aren't actually adding an update to the queue,
			-- because there is no update we can add for useReducer hooks that won't trigger an error.
			-- (There's no appropriate action type for DevTools overrides.)
			-- As a result though, React will see the scheduled update as a noop and bailout.
			-- Shallow cloning props works as a workaround for now to bypass the bailout check.
			fiber.memoizedProps = table.clone(fiber.memoizedProps)

			scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
		end
	end

	-- Support DevTools props for function components, forwardRef, memo, host components, etc.
	overrideProps = function(fiber: Fiber, path: Array<string | number>, value: any)
		fiber.pendingProps = copyWithSet(fiber.memoizedProps, path, value)
		-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
		local alternate = fiber.alternate
		if alternate then
			alternate.pendingProps = fiber.pendingProps
		end
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end
	overridePropsDeletePath = function(fiber: Fiber, path: Array<string | number>)
		fiber.pendingProps = copyWithDelete(fiber.memoizedProps, path)
		-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
		local alternate = fiber.alternate
		if alternate then
			alternate.pendingProps = fiber.pendingProps
		end
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end
	overridePropsRenamePath = function(
		fiber: Fiber,
		oldPath: Array<string | number>,
		newPath: Array<string | number>
	)
		fiber.pendingProps = copyWithRename(fiber.memoizedProps, oldPath, newPath)
		-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
		local alternate = fiber.alternate
		if alternate then
			alternate.pendingProps = fiber.pendingProps
		end
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end

	scheduleUpdate = function(fiber: Fiber)
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end

	setSuspenseHandler = function(newShouldSuspendImpl: (Fiber) -> (boolean))
		shouldSuspendImpl = newShouldSuspendImpl
	end
end

function findHostInstanceByFiber(fiber: Fiber): Instance | TextInstance | nil
	local hostFiber = findCurrentHostFiber(fiber)
	if hostFiber == nil then
		return nil
	end
	return hostFiber.stateNode
end

function emptyFindFiberByHostInstance(instance: Instance | TextInstance): Fiber | nil
	return nil
end

function getCurrentFiberForDevTools()
	return ReactCurrentFiber.current
end

exports.injectIntoDevTools = function(devToolsConfig: DevToolsConfig): boolean
	local findFiberByHostInstance = devToolsConfig.findFiberByHostInstance
	local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
	local getCurrentFiber 	
if __DEV__ then
		getCurrentFiber = getCurrentFiberForDevTools
	end
	return injectInternals({
		bundleType = devToolsConfig.bundleType,
		version = devToolsConfig.version,
		rendererPackageName = devToolsConfig.rendererPackageName,
		rendererConfig = devToolsConfig.rendererConfig,
		overrideHookState = overrideHookState,
		overrideHookStateDeletePath = overrideHookStateDeletePath,
		overrideHookStateRenamePath = overrideHookStateRenamePath,
		overrideProps = overrideProps,
		overridePropsDeletePath = overridePropsDeletePath,
		overridePropsRenamePath = overridePropsRenamePath,
		setSuspenseHandler = setSuspenseHandler,
		scheduleUpdate = scheduleUpdate,
		currentDispatcherRef = ReactCurrentDispatcher,
		findHostInstanceByFiber = findHostInstanceByFiber,
		findFiberByHostInstance = findFiberByHostInstance or emptyFindFiberByHostInstance,
		-- FIXME: WIP
		-- React Refresh
		-- findHostInstancesForRefresh = __DEV__ and findHostInstancesForRefresh or nil,
		-- scheduleRefresh = __DEV__ and scheduleRefresh or nil,
		-- scheduleRoot = __DEV__ and scheduleRoot or nil,
		-- setRefreshHandler = __DEV__ and setRefreshHandler or nil,
		-- Enables DevTools to append owner stacks to error messages in DEV mode.
		getCurrentFiber = getCurrentFiber,
	})
end

exports.robloxReactProfiling = require(script.Parent.RobloxReactProfiling)

return exports

end,
["react-reconciler/ReactFiberRoot.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/96ac799eace5d989de3b4f80e6414e94a08ff77a/packages/react-reconciler/src/ReactFiberRoot.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Set = LuauPolyfill.Set
local Map = LuauPolyfill.Map

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type SuspenseHydrationCallbacks = ReactInternalTypes.SuspenseHydrationCallbacks
local ReactRootTags = require(script.Parent:WaitForChild('ReactRootTags'))
type RootTag = ReactRootTags.RootTag

local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
local noTimeout = ReactFiberHostConfig.noTimeout
local supportsHydration = ReactFiberHostConfig.supportsHydration
local ReactFiber = require(script.Parent:WaitForChild('ReactFiber.new'))
local createHostRootFiber = ReactFiber.createHostRootFiber
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
local NoLanes = ReactFiberLane.NoLanes
local NoLanePriority = ReactFiberLane.NoLanePriority
local NoTimestamp = ReactFiberLane.NoTimestamp
local createLaneMap = ReactFiberLane.createLaneMap
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableSuspenseCallback = ReactFeatureFlags.enableSuspenseCallback
-- ROBLOX deviation: import from tracing from Scheduler export to avoid direct file access
local Scheduler = require(script.Parent.Parent:WaitForChild('scheduler')).tracing
local unstable_getThreadID = Scheduler.unstable_getThreadID
local ReactUpdateQueue = require(script.Parent:WaitForChild('ReactUpdateQueue.new'))
local initializeUpdateQueue = ReactUpdateQueue.initializeUpdateQueue
local LegacyRoot = ReactRootTags.LegacyRoot
local BlockingRoot = ReactRootTags.BlockingRoot
local ConcurrentRoot = ReactRootTags.ConcurrentRoot

local exports = {}

local function FiberRootNode(containerInfo, tag, hydrate)
	-- ROBLOX performance: See if this kind of object init is faster in Luau
	local rootNode = {
		tag = tag,
		containerInfo = containerInfo,
		pendingChildren = nil,
		-- ROBLOX TODO: this isn't typesafe upstream
		current = (nil :: any) :: Fiber,
		pingCache = nil,
		finishedWork = nil,
		timeoutHandle = noTimeout,
		context = nil,
		pendingContext = nil,
		hydrate = hydrate,
		callbackNode = nil,
		callbackPriority = NoLanePriority,
		eventTimes = createLaneMap(NoLanes),
		expirationTimes = createLaneMap(NoTimestamp),

		pendingLanes = NoLanes,
		suspendedLanes = NoLanes,
		pingedLanes = NoLanes,
		expiredLanes = NoLanes,
		mutableReadLanes = NoLanes,
		finishedLanes = NoLanes,

		entangledLanes = NoLanes,
		entanglements = createLaneMap(NoLanes),
	}

	if supportsHydration then
		rootNode.mutableSourceEagerHydrationData = nil
	end

	if enableSchedulerTracing then
		rootNode.interactionThreadID = unstable_getThreadID()
		rootNode.memoizedInteractions = Set.new()
		rootNode.pendingInteractionMap = Map.new()
	end
	if enableSuspenseCallback then
		rootNode.hydrationCallbacks = nil
	end

	if _G.__DEV__ then
		if tag == BlockingRoot then
			rootNode._debugRootType = "createBlockingRoot()"
		elseif tag == ConcurrentRoot then
			rootNode._debugRootType = "createRoot()"
		elseif tag == LegacyRoot then
			rootNode._debugRootType = "createLegacyRoot()"
		end
	end

	return rootNode
end

exports.createFiberRoot = function(
	containerInfo: any,
	tag: RootTag,
	hydrate: boolean,
	hydrationCallbacks: SuspenseHydrationCallbacks?
): FiberRoot
	local root: FiberRoot = FiberRootNode(containerInfo, tag, hydrate)
	if enableSuspenseCallback then
		root.hydrationCallbacks = hydrationCallbacks
	end

	-- Cyclic construction. This cheats the type system right now because
	-- stateNode is any.
	local uninitializedFiber = createHostRootFiber(tag)
	root.current = uninitializedFiber
	uninitializedFiber.stateNode = root

	initializeUpdateQueue(uninitializedFiber)

	return root
end

return exports

end,
["react-reconciler/ReactFiberSchedulerPriorities.roblox"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/SchedulerWithReactIntegration.new.js
--[[
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- deviation: Type definition and values extracted from
-- SchedulerWithReactIntegration.new. This helps avoid a cyclic dependency that
-- can occur between SchedulerWithReactIntegration.new, ReactFiberLanes, and
-- various files that depend upon them

export type ReactPriorityLevel = number

local exports: { [string]: ReactPriorityLevel } = {
	-- // Except for NoPriority, these correspond to Scheduler priorities. We use
	-- // ascending numbers so we can compare them like numbers. They start at 90 to
	-- // avoid clashing with Scheduler's priorities.
	ImmediatePriority = 99,
	UserBlockingPriority = 98,
	NormalPriority = 97,
	LowPriority = 96,
	IdlePriority = 95,
	-- // NoPriority is the absence of priority. Also React-only.
	NoPriority = 90,
}

return exports

end,
["react-reconciler/ReactFiberStack.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberStack.new.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber

type Array<T> = { [number]: T }
-- deviation: use this table when pushing nil values
type null = {}
local NULL: null = {}

export type StackCursor<T> = { current: T }

local valueStack: Array<any> = {}

local fiberStack: Array<Fiber | null>

if _G.__DEV__ then
	fiberStack = {}
end

local index = 0

local function createCursor<T>(defaultValue: T): StackCursor<T>
	return {
		current = defaultValue,
	}
end

local function isEmpty(): boolean
	return index == 0
end

local function pop<T>(cursor: StackCursor<T>, fiber: Fiber): ()
	if index < 1 then
		if _G.__DEV__ then
			console.error("Unexpected pop.")
		end
		return
	end

	if _G.__DEV__ then
		-- ROBLOX TODO: workaround for Luau analysis bug
		if fiber ~= fiberStack[index] :: Fiber then
			console.error("Unexpected Fiber popped.")
		end
	end

	local value = valueStack[index]
	if value == NULL then
		-- ROBLOX TODO: this is a sort of incorrect typing in upstream
		cursor.current = nil :: any
	else
		cursor.current = value
	end

	valueStack[index] = nil

	if _G.__DEV__ then
		fiberStack[index] = nil
	end

	index -= 1
end

local function push<T>(cursor: StackCursor<T>, value: T, fiber: Fiber): ()
	index += 1

	local stackValue = cursor.current
	if stackValue == nil then
		valueStack[index] = NULL
	else
		valueStack[index] = stackValue
	end

	if _G.__DEV__ then
		fiberStack[index] = fiber
	end

	cursor.current = value
end

local function checkThatStackIsEmpty()
	if _G.__DEV__ then
		if index ~= 0 then
			console.error("Expected an empty stack. Something was not reset properly.")
		end
	end
end

local function resetStackAfterFatalErrorInDev()
	if _G.__DEV__ then
		index = 0
		-- ROBLOX deviation: Original js simply sets `length`
		table.clear(valueStack)
		table.clear(fiberStack)
	end
end

return {
	createCursor = createCursor,
	isEmpty = isEmpty,
	pop = pop,
	push = push,
	-- DEV only:
	checkThatStackIsEmpty = checkThatStackIsEmpty,
	resetStackAfterFatalErrorInDev = resetStackAfterFatalErrorInDev,
}

end,
["react-reconciler/ReactFiberSuspenseComponent.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/1faf9e3dd5d6492f3607d5c721055819e4106bc6/packages/react-reconciler/src/ReactFiberSuspenseComponent.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactNodeList = ReactTypes.ReactNodeList
type Wakeable = ReactTypes.Wakeable

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lane = ReactFiberLane.Lane
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local NoFlags = ReactFiberFlags.NoFlags
local DidCapture = ReactFiberFlags.DidCapture
local isSuspenseInstancePending = ReactFiberHostConfig.isSuspenseInstancePending
local isSuspenseInstanceFallback = ReactFiberHostConfig.isSuspenseInstanceFallback

-- deviation: Common types
type Set<T> = { [T]: boolean }

export type SuspenseProps = {
	children: ReactNodeList?,
	fallback: ReactNodeList?,

	-- TODO: Add "unstable_" prefix?
	suspenseCallback: (Set<Wakeable>?) -> any,

	unstable_expectedLoadTime: number?
}

-- A nil SuspenseState represents an unsuspended normal Suspense boundary.
-- A non-null SuspenseState means that it is blocked for one reason or another.
-- - A non-null dehydrated field means it's blocked pending hydration.
--   - A non-null dehydrated field can use isSuspenseInstancePending or
--     isSuspenseInstanceFallback to query the reason for being dehydrated.
-- - A nil dehydrated field means it's blocked by something suspending and
--   we're currently showing a fallback instead.
export type SuspenseState = {
	-- If this boundary is still dehydrated, we store the SuspenseInstance
	-- here to indicate that it is dehydrated (flag) and for quick access
	-- to check things like isSuspenseInstancePending.
	dehydrated: SuspenseInstance?,
	-- Represents the lane we should attempt to hydrate a dehydrated boundary at.
	-- OffscreenLane is the default for dehydrated boundaries.
	-- NoLane is the default for normal boundaries, which turns into "normal" pri.
	retryLane: Lane
}

-- deviation: Can't use literals for types
-- export type SuspenseListTailMode = 'collapsed' | 'hidden' | void
export type SuspenseListTailMode = string?

export type SuspenseListRenderState = {
	isBackwards: boolean,
	-- The currently rendering tail row.
	rendering: Fiber?,
	-- The absolute time when we started rendering the most recent tail row.
	renderingStartTime: number,
	-- The last of the already rendered children.
	last: Fiber?,
	-- Remaining rows on the tail of the list.
	tail: Fiber?,
	-- Tail insertions setting.
	tailMode: SuspenseListTailMode
}

local exports = {}

exports.shouldCaptureSuspense =
	function(workInProgress: Fiber, hasInvisibleParent: boolean): boolean
		-- If it was the primary children that just suspended, capture and render the
		-- fallback. Otherwise, don't capture and bubble to the next boundary.
		local nextState: SuspenseState? = workInProgress.memoizedState
		if nextState then
			if nextState.dehydrated ~= nil then
				-- A dehydrated boundary always captures.
				return true
			end
			return false
		end
		local props = workInProgress.memoizedProps
		-- In order to capture, the Suspense component must have a fallback prop.
		if props.fallback == nil then
			return false
		end
		-- Regular boundaries always capture.
		if props.unstable_avoidThisFallback ~= true then
			return true
		end
		-- If it's a boundary we should avoid, then we prefer to bubble up to the
		-- parent boundary if it is currently invisible.
		if hasInvisibleParent then
			return false
		end
		-- If the parent is not able to handle it, we must handle it.
		return true
	end

exports.findFirstSuspended = function(row: Fiber): Fiber?
	local node = row
	while node ~= nil do
		if node.tag == SuspenseComponent then
			local state: SuspenseState? = node.memoizedState
			if state then
				local dehydrated: SuspenseInstance? = state.dehydrated
				if
					dehydrated == nil
					or isSuspenseInstancePending(dehydrated)
					or isSuspenseInstanceFallback(dehydrated)
				then
					return node
				end
			end
		elseif
			node.tag == SuspenseListComponent
			-- revealOrder undefined can't be trusted because it don't
			-- keep track of whether it suspended or not.
			and node.memoizedProps.revealOrder ~= nil
		then
			local didSuspend = bit32.band(node.flags, DidCapture) ~= NoFlags
			if didSuspend then
				return node
			end
		elseif node.child ~= nil then
			node.child.return_ = node
			node = node.child
			continue
		end
		if node == row then
			return nil
		end
		while node.sibling == nil do
			if node.return_ == nil or node.return_ == row then
				return nil
			end
			-- ROBLOX FIXME Luau: Luau narrowing doesn't understand this loop until nil pattern
			node = node.return_ :: Fiber
		end
		-- ROBLOX FIXME Luau: Luau narrowing doesn't understand this loop until nil pattern
		(node.sibling :: Fiber).return_ = node.return_
		node = node.sibling :: Fiber
	end
	return nil
end

return exports

end,
["react-reconciler/ReactFiberSuspenseContext.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberSuspenseContext.new.js
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberSuspenseContext.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber

local ReactFiberStack = require(script.Parent:WaitForChild('ReactFiberStack.new'))
type StackCursor<T> = ReactFiberStack.StackCursor<T>

local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop

export type SuspenseContext = number
export type SubtreeSuspenseContext = SuspenseContext
export type ShallowSuspenseContext = SuspenseContext

local exports = {}

local DefaultSuspenseContext: SuspenseContext = 0b00

-- // The Suspense Context is split into two parts. The lower bits is
-- // inherited deeply down the subtree. The upper bits only affect
-- // this immediate suspense boundary and gets reset each new
-- // boundary or suspense list.
local SubtreeSuspenseContextMask: SuspenseContext = 0b01

-- // Subtree Flags:

-- // InvisibleParentSuspenseContext indicates that one of our parent Suspense
-- // boundaries is not currently showing visible main content.
-- // Either because it is already showing a fallback or is not mounted at all.
-- // We can use this to determine if it is desirable to trigger a fallback at
-- // the parent. If not, then we might need to trigger undesirable boundaries
-- // and/or suspend the commit to avoid hiding the parent content.
local InvisibleParentSuspenseContext: SubtreeSuspenseContext = 0b01
exports.InvisibleParentSuspenseContext = InvisibleParentSuspenseContext

-- // Shallow Flags:

-- // ForceSuspenseFallback can be used by SuspenseList to force newly added
-- // items into their fallback state during one of the render passes.
local ForceSuspenseFallback: ShallowSuspenseContext = 0b10
exports.ForceSuspenseFallback = ForceSuspenseFallback

local suspenseStackCursor: StackCursor<SuspenseContext> =
	createCursor(DefaultSuspenseContext)
exports.suspenseStackCursor = suspenseStackCursor

function exports.hasSuspenseContext(
	parentContext: SuspenseContext,
	flag: SuspenseContext
): boolean
	return bit32.band(parentContext, flag) ~= 0
end

function exports.setDefaultShallowSuspenseContext(
	parentContext: SuspenseContext
): SuspenseContext
	return bit32.band(parentContext, SubtreeSuspenseContextMask)
end

function exports.setShallowSuspenseContext(
	parentContext: SuspenseContext,
	shallowContext: ShallowSuspenseContext
): SuspenseContext
	return bit32.bor(
		bit32.band(parentContext, SubtreeSuspenseContextMask),
		shallowContext
	)
end

function exports.addSubtreeSuspenseContext(
	parentContext: SuspenseContext,
	subtreeContext: SubtreeSuspenseContext
): SuspenseContext
	return bit32.bor(parentContext, subtreeContext)
end

function exports.pushSuspenseContext(fiber: Fiber, newContext: SuspenseContext)
	push(suspenseStackCursor, newContext, fiber)
end

function exports.popSuspenseContext(fiber: Fiber)
	pop(suspenseStackCursor, fiber)
end

return exports

end,
["react-reconciler/ReactFiberThrow.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberThrow.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object
-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
type Error = LuauPolyfill.Error
type Map<K, V> = { [K]: V }
type Object = { [string]: any }
type Set<T> = { [T]: boolean }

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane
local ReactCapturedValue = require(script.Parent:WaitForChild('ReactCapturedValue'))
type CapturedValue<T> = ReactCapturedValue.CapturedValue<T>
local ReactUpdateQueue = require(script.Parent:WaitForChild('ReactUpdateQueue.new'))
type Update<T> = ReactInternalTypes.Update<T>

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type React_Component<Props, State> = ReactTypes.React_Component<Props, State>
type Thenable<T> = ReactTypes.Thenable<T>
type Wakeable = ReactTypes.Wakeable

local ReactFiberSuspenseContext = require(script.Parent:WaitForChild('ReactFiberSuspenseContext.new'))
type SuspenseContext = ReactFiberSuspenseContext.SuspenseContext

local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent

local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local DidCapture = ReactFiberFlags.DidCapture
local Incomplete = ReactFiberFlags.Incomplete
local NoFlags = ReactFiberFlags.NoFlags
local ShouldCapture = ReactFiberFlags.ShouldCapture
local LifecycleEffectMask = ReactFiberFlags.LifecycleEffectMask
local ForceUpdateForLegacySuspense = ReactFiberFlags.ForceUpdateForLegacySuspense
local shouldCaptureSuspense =
	require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new')).shouldCaptureSuspense
local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
local NoMode = ReactTypeOfMode.NoMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local DebugTracingMode = ReactTypeOfMode.DebugTracingMode
local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local createCapturedValue = require(script.Parent:WaitForChild('ReactCapturedValue')).createCapturedValue

local enqueueCapturedUpdate = ReactUpdateQueue.enqueueCapturedUpdate
local createUpdate = ReactUpdateQueue.createUpdate
local CaptureUpdate = ReactUpdateQueue.CaptureUpdate
local ForceUpdate = ReactUpdateQueue.ForceUpdate
local enqueueUpdate = ReactUpdateQueue.enqueueUpdate
local markFailedErrorBoundaryForHotReloading = require(
	script.Parent["ReactFiberHotReloading.new"]
).markFailedErrorBoundaryForHotReloading

local hasSuspenseContext = ReactFiberSuspenseContext.hasSuspenseContext
local InvisibleParentSuspenseContext =
	ReactFiberSuspenseContext.InvisibleParentSuspenseContext
local suspenseStackCursor = ReactFiberSuspenseContext.suspenseStackCursor

-- ROBLOX FIXME: these will incur a dependency cycle
-- onUncaughtError would be very easy to extract out, or to transplant into this file
local ReactFiberWorkLoop
local markLegacyErrorBoundaryAsFailedRef, isAlreadyFailedLegacyErrorBoundaryRef, pingSuspendedRootRef

-- ROBLOX deviation: lazy initialize ReactFiberWorkLoop to prevent cyclic module dependency
local markLegacyErrorBoundaryAsFailed = function(...)
	if not markLegacyErrorBoundaryAsFailedRef then
		ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new'))		
markLegacyErrorBoundaryAsFailedRef =
			ReactFiberWorkLoop.markLegacyErrorBoundaryAsFailed
	end
	return markLegacyErrorBoundaryAsFailedRef(...)
end
-- local {
--   renderDidError,
--   onUncaughtError,
--   markLegacyErrorBoundaryAsFailed,
--   isAlreadyFailedLegacyErrorBoundary,
--   pingSuspendedRoot,
-- } = require(Packages../ReactFiberWorkLoop.new'
local pingSuspendedRoot = function(...)
	if ReactFiberWorkLoop == nil then
		ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new'))	
end
	pingSuspendedRootRef = ReactFiberWorkLoop.pingSuspendedRoot
	return pingSuspendedRootRef(...)
end
local isAlreadyFailedLegacyErrorBoundary = function(...)
	if ReactFiberWorkLoop == nil then
		ReactFiberWorkLoop = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new'))	
end
	isAlreadyFailedLegacyErrorBoundaryRef =
		ReactFiberWorkLoop.isAlreadyFailedLegacyErrorBoundary
	return isAlreadyFailedLegacyErrorBoundaryRef(...)
end

local logCapturedError = require(script.Parent:WaitForChild('ReactFiberErrorLogger')).logCapturedError
local logComponentSuspended = require(script.Parent:WaitForChild('DebugTracing')).logComponentSuspended
local markComponentSuspended = require(script.Parent:WaitForChild('SchedulingProfiler')).markComponentSuspended

local SyncLane = ReactFiberLane.SyncLane
local NoTimestamp = ReactFiberLane.NoTimestamp
local includesSomeLane = ReactFiberLane.includesSomeLane
local mergeLanes = ReactFiberLane.mergeLanes
local pickArbitraryLane = ReactFiberLane.pickArbitraryLane

-- local PossiblyWeakMap = typeof WeakMap == 'function' ? WeakMap : Map

function createRootErrorUpdate(
	fiber: Fiber,
	errorInfo: CapturedValue<Error>,
	lane: Lane,
	-- ROBLOX deviation: parameterize method to avoid circular dependency
	onUncaughtError
): Update<any>
	local update = createUpdate(NoTimestamp, lane)
	-- Unmount the root by rendering nil.
	update.tag = CaptureUpdate
	-- Caution: React DevTools currently depends on this property
	-- being called "element".
	update.payload = { element = Object.None }
	local _error = errorInfo.value
	update.callback = function()
		if onUncaughtError ~= nil then
			onUncaughtError(_error)
		end
		logCapturedError(fiber, errorInfo)
	end
	return update
end

function createClassErrorUpdate(
	fiber: Fiber,
	errorInfo: CapturedValue<Error>,
	lane: Lane
): Update<any>
	local update = createUpdate(NoTimestamp, lane)
	update.tag = CaptureUpdate
	local getDerivedStateFromError = (fiber.type :: React_Component<any, any>).getDerivedStateFromError
	if typeof(getDerivedStateFromError) == "function" then
		local error_ = errorInfo.value
		update.payload = function()
			logCapturedError(fiber, errorInfo)
			return getDerivedStateFromError(error_)
		end
	end

	local inst = fiber.stateNode
	if inst ~= nil and typeof(inst.componentDidCatch) == "function" then
		update.callback = function()
			if _G.__DEV__ then
				markFailedErrorBoundaryForHotReloading(fiber)
			end
			if typeof(getDerivedStateFromError) ~= "function" then
				-- To preserve the preexisting retry behavior of error boundaries,
				-- we keep track of which ones already failed during this batch.
				-- This gets reset before we yield back to the browser.
				-- TODO: Warn in strict mode if getDerivedStateFromError is
				-- not defined.
				-- ROBLOX FIXME: used to be `this` upstream, needs verification by ReactIncremental unwinding test
				markLegacyErrorBoundaryAsFailed(inst)

				-- Only log here if componentDidCatch is the only error boundary method defined
				logCapturedError(fiber, errorInfo)
			end
			local error_ = errorInfo.value
			local stack = errorInfo.stack
			-- ROBLOX FIXME: used to be `this` upstream, needs verification by ReactIncremental unwinding test
			inst:componentDidCatch(error_, {
				componentStack = stack or "",
			})
			if _G.__DEV__ then
				if typeof(getDerivedStateFromError) ~= "function" then
					-- If componentDidCatch is the only error boundary method defined,
					-- then it needs to call setState to recover from errors.
					-- If no state update is scheduled then the boundary will swallow the error.
					if not includesSomeLane(fiber.lanes, SyncLane) then
						console.error(
[[%s: Error boundaries should implement getDerivedStateFromError(). In that method, return a state update to display an error message or fallback UI.]]
,
							getComponentName(fiber.type) or "Unknown"
						)
					end
				end
			end
		end
	elseif _G.__DEV__ then
		update.callback = function()
			markFailedErrorBoundaryForHotReloading(fiber)
		end
	end
	return update
end

local function attachPingListener(root: FiberRoot, wakeable: Wakeable, lanes: Lanes)
	-- Attach a listener to the promise to "ping" the root and retry. But only if
	-- one does not already exist for the lanes we're currently rendering (which
	-- acts like a "thread ID" here).
	local pingCache: Map<Wakeable, (Set<any> | Map<Wakeable, Set<any>>)> | nil =
		root.pingCache
	local threadIDs
	if pingCache == nil then
		-- ROBLOX deviation: use table in place of WeakMap
		-- ROBLOX performance: slight re-ordering so we initialize the table in one shot
		threadIDs = {} :: Set<any>
		root.pingCache = {
			[wakeable] = threadIDs,
		} :: Map<Wakeable, (Set<any> | Map<Wakeable, Set<any>>)>
		pingCache = root.pingCache :: Map<Wakeable, (Set<any> | Map<Wakeable, Set<any>>)>
	else
		threadIDs = (
			pingCache :: Map<Wakeable, (Set<any> | Map<Wakeable, Set<any>>)>
		)[wakeable] :: Set<any>
		if threadIDs == nil then
			threadIDs = {} :: Set<any>;
			(pingCache :: Map<Wakeable, (Set<any> | Map<Wakeable, Set<any>>)>)[wakeable] =
				threadIDs
		end
	end
	if not threadIDs[lanes] then
		-- Memoize using the thread ID to prevent redundant listeners.
		threadIDs[lanes] = true
		local ping = function()
			return pingSuspendedRoot(root, wakeable, lanes)
		end
		wakeable:andThen(ping, ping)
	end
end

function throwException(
	root: FiberRoot,
	returnFiber: Fiber,
	sourceFiber: Fiber,
	value: any,
	rootRenderLanes: Lanes,
	onUncaughtError,
	renderDidError
)
	-- The source fiber did not complete.
	sourceFiber.flags = bit32.bor(sourceFiber.flags, Incomplete)

	if
		value ~= nil
		and typeof(value) == "table"
		and typeof(value.andThen) == "function"
	then
		-- This is a wakeable.
		local wakeable: Wakeable = value

		if _G.__DEV__ then
			if enableDebugTracing then
				if bit32.band(sourceFiber.mode, DebugTracingMode) ~= 0 then
					local name = getComponentName(sourceFiber.type) or "Unknown"
					logComponentSuspended(name, wakeable)
				end
			end
		end

		if enableSchedulingProfiler then
			markComponentSuspended(sourceFiber, wakeable)
		end

		if bit32.band(sourceFiber.mode, BlockingMode) == NoMode then
			-- Reset the memoizedState to what it was before we attempted
			-- to render it.
			local currentSource = sourceFiber.alternate
			if currentSource then
				-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
				sourceFiber.updateQueue = currentSource.updateQueue
				sourceFiber.memoizedState = currentSource.memoizedState
				sourceFiber.lanes = currentSource.lanes
			else
				-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
				sourceFiber.updateQueue = nil
				sourceFiber.memoizedState = nil
			end
		end

		local hasInvisibleParentBoundary = hasSuspenseContext(
			suspenseStackCursor.current,
			InvisibleParentSuspenseContext :: SuspenseContext
		)

		-- Schedule the nearest Suspense to re-render the timed out view.
		local workInProgress = returnFiber
		repeat
			if
				workInProgress.tag == SuspenseComponent
				and shouldCaptureSuspense(workInProgress, hasInvisibleParentBoundary)
			then
				-- Found the nearest boundary.

				-- Stash the promise on the boundary fiber. If the boundary times out, we'll
				-- attach another listener to flip the boundary back to its normal state.
				local wakeables: Set<Wakeable> = workInProgress.updateQueue
				if wakeables == nil then
					local updateQueue = {
						[wakeable] = true,
					}
					-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
					workInProgress.updateQueue = updateQueue
				else
					wakeables[wakeable] = true
				end

				-- If the boundary is outside of blocking mode, we should *not*
				-- suspend the commit. Pretend as if the suspended component rendered
				-- nil and keep rendering. In the commit phase, we'll schedule a
				-- subsequent synchronous update to re-render the Suspense.
				--
				-- Note: It doesn't matter whether the component that suspended was
				-- inside a blocking mode tree. If the Suspense is outside of it, we
				-- should *not* suspend the commit.
				if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
					workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
					sourceFiber.flags =
						bit32.bor(sourceFiber.flags, ForceUpdateForLegacySuspense)

					-- We're going to commit this fiber even though it didn't complete.
					-- But we shouldn't call any lifecycle methods or callbacks. Remove
					-- all lifecycle effect tags.
					sourceFiber.flags = bit32.band(
						sourceFiber.flags,
						bit32.bnot(bit32.bor(LifecycleEffectMask, Incomplete))
					)

					if sourceFiber.tag == ClassComponent then
						local currentSourceFiber = sourceFiber.alternate
						if currentSourceFiber == nil then
							-- This is a new mount. Change the tag so it's not mistaken for a
							-- completed class component. For example, we should not call
							-- componentWillUnmount if it is deleted.
							sourceFiber.tag = IncompleteClassComponent
						else
							-- When we try rendering again, we should not reuse the current fiber,
							-- since it's known to be in an inconsistent state. Use a force update to
							-- prevent a bail out.
							local update = createUpdate(NoTimestamp, SyncLane)
							update.tag = ForceUpdate
							enqueueUpdate(sourceFiber, update)
						end
					end

					-- The source fiber did not complete. Mark it with Sync priority to
					-- indicate that it still has pending work.
					sourceFiber.lanes = mergeLanes(sourceFiber.lanes, SyncLane)

					-- Exit without suspending.
					return
				end

				-- Confirmed that the boundary is in a concurrent mode tree. Continue
				-- with the normal suspend path.
				--
				-- After this we'll use a set of heuristics to determine whether this
				-- render pass will run to completion or restart or "suspend" the commit.
				-- The actual logic for this is spread out in different places.
				--
				-- This first principle is that if we're going to suspend when we complete
				-- a root, then we should also restart if we get an update or ping that
				-- might unsuspend it, and vice versa. The only reason to suspend is
				-- because you think you might want to restart before committing. However,
				-- it doesn't make sense to restart only while in the period we're suspended.
				--
				-- Restarting too aggressively is also not good because it starves out any
				-- intermediate loading state. So we use heuristics to determine when.

				-- Suspense Heuristics
				--
				-- If nothing threw a Promise or all the same fallbacks are already showing,
				-- then don't suspend/restart.
				--
				-- If this is an initial render of a new tree of Suspense boundaries and
				-- those trigger a fallback, then don't suspend/restart. We want to ensure
				-- that we can show the initial loading state as quickly as possible.
				--
				-- If we hit a "Delayed" case, such as when we'd switch from content back into
				-- a fallback, then we should always suspend/restart. Transitions apply
				-- to this case. If none is defined, JND is used instead.
				--
				-- If we're already showing a fallback and it gets "retried", allowing us to show
				-- another level, but there's still an inner boundary that would show a fallback,
				-- then we suspend/restart for 500ms since the last time we showed a fallback
				-- anywhere in the tree. This effectively throttles progressive loading into a
				-- consistent train of commits. This also gives us an opportunity to restart to
				-- get to the completed state slightly earlier.
				--
				-- If there's ambiguity due to batching it's resolved in preference of:
				-- 1) "delayed", 2) "initial render", 3) "retry".
				--
				-- We want to ensure that a "busy" state doesn't get force committed. We want to
				-- ensure that new initial loading states can commit as soon as possible.

				attachPingListener(root, wakeable, rootRenderLanes)

				workInProgress.flags = bit32.bor(workInProgress.flags, ShouldCapture)
				workInProgress.lanes = rootRenderLanes

				return
			end
			-- This boundary already captured during this render. Continue to the next
			-- boundary.
			workInProgress = workInProgress.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
		until workInProgress == nil

		-- No boundary was found. Fallthrough to error mode.
		-- TODO: Use invariant so the message is stripped in prod?
		value = (getComponentName(sourceFiber.type) or "A React component")
			.. [[ suspended while rendering, but no fallback UI was specified.

Add a <Suspense fallback=...> component higher in the tree to provide a loading indicator or placeholder to display.]]	

end

	-- We didn't find a boundary that could handle this type of exception. Start
	-- over and traverse parent path again, this time treating the exception
	-- as an error.
	renderDidError()

	value = createCapturedValue(value, sourceFiber)
	local workInProgress = returnFiber
	repeat
		if workInProgress.tag == HostRoot then
			local errorInfo = value
			workInProgress.flags = bit32.bor(workInProgress.flags, ShouldCapture)
			local lane = pickArbitraryLane(rootRenderLanes)
			workInProgress.lanes = mergeLanes(workInProgress.lanes, lane)
			-- ROBLOX deviation: parameterize method onUncaughtError to avoid circular dependency
			local update =
				createRootErrorUpdate(workInProgress, errorInfo, lane, onUncaughtError)
			enqueueCapturedUpdate(workInProgress, update)
			return
		elseif workInProgress.tag == ClassComponent then
			-- Capture and retry
			local errorInfo = value
			local ctor = workInProgress.type
			local instance = workInProgress.stateNode
			if
				bit32.band(workInProgress.flags, DidCapture) == NoFlags
				and (
					typeof(ctor.getDerivedStateFromError) == "function"
					or (
						instance ~= nil
						and typeof(instance.componentDidCatch) == "function"
						and not isAlreadyFailedLegacyErrorBoundary(instance)
					)
				)
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, ShouldCapture)
				local lane = pickArbitraryLane(rootRenderLanes)
				workInProgress.lanes = mergeLanes(workInProgress.lanes, lane)
				-- Schedule the error boundary to re-render using updated state
				local update = createClassErrorUpdate(workInProgress, errorInfo, lane)
				enqueueCapturedUpdate(workInProgress, update)
				return
			end
		end
		workInProgress = workInProgress.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
	until workInProgress == nil
end

return {
	throwException = throwException,
	createRootErrorUpdate = createRootErrorUpdate,
	createClassErrorUpdate = createClassErrorUpdate,
}

end,
["react-reconciler/ReactFiberTransition"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ddd1faa1972b614dfbfae205f2aa4a6c0b39a759/packages/react-reconciler/src/ReactFiberTransition.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactSharedInternals = require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals

local ReactCurrentBatchConfig = ReactSharedInternals.ReactCurrentBatchConfig

return {
	NoTransition = 0,
	requestCurrentTransition = function(): number
		return ReactCurrentBatchConfig.transition
	end,
}

end,
["react-reconciler/ReactFiberTreeReflection"]=function()
--!nonstrict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberTreeReflection.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
type Container = ReactFiberHostConfig.Container
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant

local getInstance = require(script.Parent.Parent:WaitForChild('shared')).ReactInstanceMap.get
local ReactSharedInternals = require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local ClassComponent = ReactWorkTags.ClassComponent
local HostComponent = ReactWorkTags.HostComponent
local HostRoot = ReactWorkTags.HostRoot
local HostPortal = ReactWorkTags.HostPortal
local HostText = ReactWorkTags.HostText
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local NoFlags = ReactFiberFlags.NoFlags
local Placement = ReactFiberFlags.Placement
local Hydrating = ReactFiberFlags.Hydrating
local enableFundamentalAPI =
	require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.enableFundamentalAPI

local ReactCurrentOwner = ReactSharedInternals.ReactCurrentOwner

local exports = {}

local function getNearestMountedFiber(fiber: Fiber): Fiber?
	local node = fiber
	-- ROBLOX FIXME Luau: Luau should infer this annotation
	local nearestMounted: Fiber | nil = fiber
	if not fiber.alternate then
		-- If there is no alternate, this might be a new tree that isn't inserted
		-- yet. If it is, then it will have a pending insertion effect on it.
		local nextNode = node
		repeat
			node = nextNode
			if bit32.band(node.flags, bit32.bor(Placement, Hydrating)) ~= NoFlags then
				-- This is an insertion or in-progress hydration. The nearest possible
				-- mounted fiber is the parent but we need to continue to figure out
				-- if that one is still mounted.
				nearestMounted = node.return_
			end
			nextNode = node.return_
		until not nextNode
	else
		while node.return_ do
			node = node.return_
		end
	end
	if node.tag == HostRoot then
		-- TODO: Check if this was a nested HostRoot when used with
		-- renderContainerIntoSubtree.
		return nearestMounted
	end
	-- If we didn't hit the root, that means that we're in an disconnected tree
	-- that has been unmounted.
	return nil
end
exports.getNearestMountedFiber = getNearestMountedFiber

exports.getSuspenseInstanceFromFiber = function(fiber: Fiber): SuspenseInstance?
	if fiber.tag == SuspenseComponent then
		local suspenseState: SuspenseState? = fiber.memoizedState
		if suspenseState == nil then
			local current = fiber.alternate
			if current ~= nil then
				suspenseState = current.memoizedState
			end
		end
		if suspenseState then
			return suspenseState.dehydrated
		end
	end
	return nil
end

exports.getContainerFromFiber = function(fiber: Fiber): Container?
	return if fiber.tag == HostRoot then fiber.stateNode.containerInfo else nil
end

exports.isFiberMounted = function(fiber: Fiber): boolean
	return getNearestMountedFiber(fiber) == fiber
end

-- ROBLOX TODO: Missing React$ internal flow types
-- exports.isMounted = function(component: React$Component<any, any>): boolean
exports.isMounted = function(component): boolean
	if _G.__DEV__ then
		local owner: any = ReactCurrentOwner.current
		if owner ~= nil and owner.tag == ClassComponent then
			local ownerFiber: Fiber = owner
			local instance = ownerFiber.stateNode
			if not instance._warnedAboutRefsInRender then
				console.error(
[[%s is accessing isMounted inside its render() function. render() should be a pure function of props and state. It should never access something that requires stale data from the previous render, such as refs. Move this logic to componentDidMount and componentDidUpdate instead.]]



,
					getComponentName(ownerFiber.type) or "A component"
				)
			end
			instance._warnedAboutRefsInRender = true
		end
	end

	local fiber: Fiber? = getInstance(component)
	if not fiber then
		return false
	else
		-- ROBLOX FIXME: remove any cast once Luau understands if-statement nil check
		local fiberNonNil: any = fiber
		return getNearestMountedFiber(fiberNonNil) == fiber
	end
end

local function assertIsMounted(fiber)
	invariant(
		getNearestMountedFiber(fiber) == fiber,
		"Unable to find node on an unmounted component."
	)
end

local function findCurrentFiberUsingSlowPath(fiber: Fiber): Fiber?
	local alternate = fiber.alternate
	if not alternate then
		-- If there is no alternate, then we only need to check if it is mounted.
		local nearestMounted = getNearestMountedFiber(fiber)
		invariant(nearestMounted ~= nil, "Unable to find node on an unmounted component.")
		if nearestMounted ~= fiber then
			return nil
		end
		return fiber
	end
	-- If we have two possible branches, we'll walk backwards up to the root
	-- to see what path the root points to. On the way we may hit one of the
	-- special cases and we'll deal with them.
	local a: Fiber = fiber
	local b: Fiber = alternate
	while true do
		local parentA = a.return_
		if parentA == nil then
			-- We're at the root.
			break
		end
		local parentB = parentA.alternate
		if parentB == nil then
			-- There is no alternate. This is an unusual case. Currently, it only
			-- happens when a Suspense component is hidden. An extra fragment fiber
			-- is inserted in between the Suspense fiber and its children. Skip
			-- over this extra fragment fiber and proceed to the next parent.
			local nextParent = parentA.return_
			if nextParent ~= nil then
				a = nextParent
				b = nextParent
				continue
			end
			-- If there's no parent, we're at the root.
			break
		end

		-- If both copies of the parent fiber point to the same child, we can
		-- assume that the child is current. This happens when we bailout on low
		-- priority: the bailed out fiber's child reuses the current child.
		if parentA.child == parentB.child then
			local child = parentA.child
			while child do
				if child == a then
					-- We've determined that A is the current branch.
					assertIsMounted(parentA)
					return fiber
				end
				if child == b then
					-- We've determined that B is the current branch.
					assertIsMounted(parentA)
					return alternate
				end
				child = child.sibling
			end
			-- We should never have an alternate for any mounting node. So the only
			-- way this could possibly happen is if this was unmounted, if at all.
			invariant(false, "Unable to find node on an unmounted component.")
		end

		if a.return_ ~= b.return_ then
			-- The return pointer of A and the return pointer of B point to different
			-- fibers. We assume that return pointers never criss-cross, so A must
			-- belong to the child set of A.return, and B must belong to the child
			-- set of B.return.
			a = parentA
			b = parentB
		else
			-- The return pointers point to the same fiber. We'll have to use the
			-- default, slow path: scan the child sets of each parent alternate to see
			-- which child belongs to which set.
			--
			-- Search parent A's child set
			local didFindChild = false
			local child = parentA.child
			while child do
				if child == a then
					didFindChild = true
					a = parentA
					b = parentB
					break
				end
				if child == b then
					didFindChild = true
					b = parentA
					a = parentB
					break
				end
				child = child.sibling
			end
			if not didFindChild then
				-- Search parent B's child set
				child = parentB.child
				while child do
					if child == a then
						didFindChild = true
						a = parentB
						b = parentA
						break
					end
					if child == b then
						didFindChild = true
						b = parentB
						a = parentA
						break
					end
					child = child.sibling
				end
				invariant(
					didFindChild,
[[Child was not found in either parent set. This indicates a bug in React related to the return pointer. Please file an issue.]]				

)
			end
		end

		invariant(
			a.alternate == b,
[[Return fibers should always be each others' alternates. This error is likely caused by a bug in React. Please file an issue.]]		

)
	end
	-- If the root is not a host container, we're in a disconnected tree. I.e.
	-- unmounted.
	invariant(a.tag == HostRoot, "Unable to find node on an unmounted component.")
	if a.stateNode.current == a then
		-- We've determined that A is the current branch.
		return fiber
	end
	-- Otherwise B has to be current branch.
	return alternate
end
exports.findCurrentFiberUsingSlowPath = findCurrentFiberUsingSlowPath

exports.findCurrentHostFiber = function(parent: Fiber): Fiber?
	local currentParent = findCurrentFiberUsingSlowPath(parent)
	if not currentParent then
		return nil
	end

	-- Next we'll drill down this component to find the first HostComponent/Text.
	-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
	local node: Fiber = currentParent :: Fiber
	while true do
		local child = node.child
		if node.tag == HostComponent or node.tag == HostText then
			return node
		elseif child then
			child.return_ = node
			node = child
			continue
		end
		if node == currentParent then
			return nil
		end
		local return_ = node.return_
		local sibling = node.sibling
		while not sibling do
			if not return_ or return_ == currentParent then
				return nil
			end
			-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
			node = return_ :: Fiber
		end
		-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
		(sibling :: Fiber).return_ = return_ :: Fiber
		node = sibling :: Fiber
	end
	-- Flow needs the return nil here, but ESLint complains about it.
	-- eslint-disable-next-line no-unreachable
	return nil
end

exports.findCurrentHostFiberWithNoPortals = function(parent: Fiber): Fiber?
	local currentParent = findCurrentFiberUsingSlowPath(parent)
	if not currentParent then
		return nil
	end

	-- Next we'll drill down this component to find the first HostComponent/Text.
	local node: Fiber = currentParent :: Fiber
	while true do
		local child = node.child
		if
			node.tag == HostComponent
			or node.tag == HostText
			or (enableFundamentalAPI and node.tag == FundamentalComponent)
		then
			return node
		elseif child and node.tag ~= HostPortal then
			child.return_ = node
			node = child
			continue
		end
		if node == currentParent then
			return nil
		end
		local return_ = node.return_
		local sibling = node.sibling
		while not sibling do
			if not return_ or return_ == currentParent then
				return nil
			end
			-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
			node = return_ :: Fiber
		end
		-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
		(sibling :: Fiber).return_ = return_ :: Fiber
		node = sibling :: Fiber
	end
	-- Flow needs the return nil here, but ESLint complains about it.
	-- eslint-disable-next-line no-unreachable
	return nil
end

exports.isFiberSuspenseAndTimedOut = function(fiber: Fiber): boolean
	local memoizedState = fiber.memoizedState
	return fiber.tag == SuspenseComponent
		and memoizedState ~= nil
		and memoizedState.dehydrated == nil
end

exports.doesFiberContain = function(parentFiber: Fiber, childFiber: Fiber): boolean
	local node = childFiber
	local parentFiberAlternate = parentFiber.alternate
	while node ~= nil do
		if node == parentFiber or node == parentFiberAlternate then
			return true
		end
		-- ROBLOX FIXME Luau: Luau doesn't understand loop until not nil pattern
		node = node.return_ :: Fiber
	end
	return false
end

return exports

end,
["react-reconciler/ReactFiberUnwindWork.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberUnwindWork.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local resetMutableSourceWorkInProgressVersions =
	require(script.Parent:WaitForChild('ReactMutableSource.new')).resetWorkInProgressVersions
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))-- local {ReactFiberFlags.DidCapture, ReactFiberFlags.NoFlags, ReactFiberFlags.ShouldCapture} = require("./ReactFiberFlags")

local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer

local ReactFiberHostContext = require(script.Parent:WaitForChild('ReactFiberHostContext.new'))
local popHostContainer = ReactFiberHostContext.popHostContainer
local popHostContext = ReactFiberHostContext.popHostContext
local popSuspenseContext =
	require(script.Parent:WaitForChild('ReactFiberSuspenseContext.new')).popSuspenseContext
local resetHydrationState =
	require(script.Parent:WaitForChild('ReactFiberHydrationContext.new')).resetHydrationState
local ReactFiberContext = require(script.Parent:WaitForChild('ReactFiberContext.new'))
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local popLegacyContext = ReactFiberContext.popContext
local popTopLevelLegacyContextObject = ReactFiberContext.popTopLevelContextObject
local popProvider = require(script.Parent:WaitForChild('ReactFiberNewContext.new')).popProvider
-- ROBLOX FIXME: this causes a circular require
local popRenderLanesRef
local popRenderLanes = function(...)
	if not popRenderLanesRef then
		popRenderLanesRef = require(script.Parent:WaitForChild('ReactFiberWorkLoop.new')).popRenderLanes
	end
	return popRenderLanesRef(...)
end
local transferActualDuration =
	require(script.Parent:WaitForChild('ReactProfilerTimer.new')).transferActualDuration

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant

local function unwindWork(workInProgress: Fiber, renderLanes: Lanes): Fiber?
	if workInProgress.tag == ReactWorkTags.ClassComponent then
		local Component = workInProgress.type
		if isLegacyContextProvider(Component) then
			popLegacyContext(workInProgress)
		end
		local flags = workInProgress.flags
		if bit32.band(flags, ReactFiberFlags.ShouldCapture) ~= 0 then
			workInProgress.flags = bit32.bor(
				bit32.band(flags, bit32.bnot(ReactFiberFlags.ShouldCapture)),
				ReactFiberFlags.DidCapture
			)
			if
				enableProfilerTimer
				and bit32.band(workInProgress.mode, ReactTypeOfMode.ProfileMode)
					~= ReactTypeOfMode.NoMode
			then
				transferActualDuration(workInProgress)
			end
			return workInProgress
		end
		return nil
	elseif workInProgress.tag == ReactWorkTags.HostRoot then
		popHostContainer(workInProgress)
		popTopLevelLegacyContextObject(workInProgress)
		resetMutableSourceWorkInProgressVersions()
		local flags = workInProgress.flags
		invariant(
			bit32.band(flags, ReactFiberFlags.DidCapture) == ReactFiberFlags.NoFlags,
[[The root failed to unmount after an error. This is likely a bug in React. Please file an issue.]]		

)
		workInProgress.flags = bit32.bor(
			bit32.band(flags, bit32.bnot(ReactFiberFlags.ShouldCapture)),
			ReactFiberFlags.DidCapture
		)
		return workInProgress
	elseif workInProgress.tag == ReactWorkTags.HostComponent then
		-- TODO: popHydrationState
		popHostContext(workInProgress)
		return nil
	elseif workInProgress.tag == ReactWorkTags.SuspenseComponent then
		popSuspenseContext(workInProgress)
		if enableSuspenseServerRenderer then
			local suspenseState = workInProgress.memoizedState
			if suspenseState ~= nil and suspenseState.dehydrated ~= nil then
				invariant(
					workInProgress.alternate ~= nil,
[[Threw in newly mounted dehydrated component. This is likely a bug in React. Please file an issue.]]				

)
				resetHydrationState()
			end
		end
		local flags = workInProgress.flags
		if bit32.band(flags, ReactFiberFlags.ShouldCapture) ~= 0 then
			workInProgress.flags = bit32.bor(
				bit32.band(flags, bit32.bnot(ReactFiberFlags.ShouldCapture)),
				ReactFiberFlags.DidCapture
			)
			-- Captured a suspense effect. Re-render the boundary.
			if
				enableProfilerTimer
				and (
					bit32.band(workInProgress.mode, ReactTypeOfMode.ProfileMode)
					~= ReactTypeOfMode.NoMode
				)
			then
				transferActualDuration(workInProgress)
			end
			return workInProgress
		end
		return nil
	elseif workInProgress.tag == ReactWorkTags.SuspenseListComponent then
		popSuspenseContext(workInProgress)
		-- SuspenseList doesn't actually catch anything. It should've been
		-- caught by a nested boundary. If not, it should bubble through.
		return nil
	elseif workInProgress.tag == ReactWorkTags.HostPortal then
		popHostContainer(workInProgress)
		return nil
	elseif workInProgress.tag == ReactWorkTags.ContextProvider then
		popProvider(workInProgress)
		return nil
	elseif
		workInProgress.tag == ReactWorkTags.OffscreenComponent
		or workInProgress.tag == ReactWorkTags.LegacyHiddenComponent
	then
		popRenderLanes(workInProgress)
		return nil
	else
		return nil
	end
end

function unwindInterruptedWork(interruptedWork: Fiber)
	if interruptedWork.tag == ReactWorkTags.ClassComponent then
		-- ROBLOX deviation: Lua doesn't support properties on functions
		local childContextTypes
		if typeof(interruptedWork.type) == "table" then
			childContextTypes = interruptedWork.type.childContextTypes
		end
		if childContextTypes ~= nil then
			popLegacyContext(interruptedWork)
		end
	elseif interruptedWork.tag == ReactWorkTags.HostRoot then
		popHostContainer(interruptedWork)
		popTopLevelLegacyContextObject(interruptedWork)
		resetMutableSourceWorkInProgressVersions()
	elseif interruptedWork.tag == ReactWorkTags.HostComponent then
		popHostContext(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.HostPortal then
		popHostContainer(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.SuspenseComponent then
		popSuspenseContext(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.SuspenseListComponent then
		popSuspenseContext(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.ContextProvider then
		popProvider(interruptedWork)
	elseif
		interruptedWork.tag == ReactWorkTags.OffscreenComponent
		or interruptedWork.tag == ReactWorkTags.LegacyHiddenComponent
	then
		popRenderLanes(interruptedWork)
		return
	else -- default
		return
	end
end

return {
	unwindWork = unwindWork,
	unwindInterruptedWork = unwindInterruptedWork,
}

end,
["react-reconciler/ReactFiberWorkInProgress"]=function()
--!strict
-- ROBLOX deviation: this is an extraction of a single state field
-- (and associated mutation/getters) from ReactFiberWorkLooop.new
-- which allows us to break dependency cycles involving that module
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberWorkLoop.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
local _workInProgressRootSkippedLanes: Lanes = ReactFiberLane.NoLanes
local mergeLanes = ReactFiberLane.mergeLanes
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane

local exports = {}

-- ROBLOX TODO: turn this into newindex property accessor
exports.workInProgressRootSkippedLanes = function(value: Lanes?): Lanes
	if value == nil then
		return _workInProgressRootSkippedLanes
	end

	-- ROBLOX FIXME Luau: Luau should narrow based on guard above
	_workInProgressRootSkippedLanes = value :: Lanes
	return _workInProgressRootSkippedLanes
end

exports.markSkippedUpdateLanes = function(lane: Lane | Lanes): ()
	_workInProgressRootSkippedLanes = mergeLanes(lane, _workInProgressRootSkippedLanes)
end

return exports

end,
["react-reconciler/ReactFiberWorkLoop.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberWorkLoop.new.js
--!nonstrict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local __DEV__ = _G.__DEV__
local __YOLO__ = _G.__YOLO__

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Set = LuauPolyfill.Set
type Set<T> = LuauPolyfill.Set<T>
type Array<T> = LuauPolyfill.Array<T>

local exports: any = {}

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type Thenable<T> = ReactTypes.Thenable<T>
type Wakeable = ReactTypes.Wakeable

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane
-- The scheduler is imported here *only* to detect whether it's been mocked
local Scheduler = require(script.Parent.Parent:WaitForChild('scheduler'))-- ROBLOX deviation: we import from top-level Scheduler exports to avoid direct file access


type Interaction = Scheduler.Interaction

local ReactFiberSuspenseComponent = require(script.Parent:WaitForChild('ReactFiberSuspenseComponent.new'))
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState
local ReactFiberStack = require(script.Parent:WaitForChild('ReactFiberStack.new'))
type StackCursor<T> = ReactFiberStack.StackCursor<T>

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
-- deviation: Use some properties directly instead of localizing to avoid 200 limit
-- local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local replayFailedUnitOfWorkWithInvokeGuardedCallback = ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback
-- local warnAboutUnmockedScheduler = ReactFeatureFlags.warnAboutUnmockedScheduler
-- local deferRenderPhaseUpdateToNextBatch = ReactFeatureFlags.ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch
-- local decoupleUpdatePriorityFromScheduler = ReactFeatureFlags.ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local skipUnmountedBoundaries = ReactFeatureFlags.skipUnmountedBoundaries
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects
local ReactShared = require(script.Parent.Parent:WaitForChild('shared'))-- ROBLOX deviation: we pull in Dispatcher type because we need it for our lazy loading deviations to typecheck

type Dispatcher = ReactShared.Dispatcher
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError
local ReactSharedInternals = ReactShared.ReactSharedInternals
local invariant = ReactShared.invariant

local SchedulerWithReactIntegration = require(script.Parent:WaitForChild('SchedulerWithReactIntegration.new'))
local scheduleCallback = SchedulerWithReactIntegration.scheduleCallback
local cancelCallback = SchedulerWithReactIntegration.cancelCallback
local getCurrentPriorityLevel = SchedulerWithReactIntegration.getCurrentPriorityLevel
local runWithPriority = SchedulerWithReactIntegration.runWithPriority
local shouldYield = SchedulerWithReactIntegration.shouldYield
local requestPaint = SchedulerWithReactIntegration.requestPaint
local now = SchedulerWithReactIntegration.now
local NoSchedulerPriority = SchedulerWithReactIntegration.NoPriority
local ImmediateSchedulerPriority = SchedulerWithReactIntegration.ImmediatePriority
local UserBlockingSchedulerPriority = SchedulerWithReactIntegration.UserBlockingPriority
local NormalSchedulerPriority = SchedulerWithReactIntegration.NormalPriority
local flushSyncCallbackQueue = SchedulerWithReactIntegration.flushSyncCallbackQueue
local scheduleSyncCallback = SchedulerWithReactIntegration.scheduleSyncCallback
-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local {
--   DebugTracing.logCommitStarted,
--   DebugTracing.logCommitStopped,
--   DebugTracing.logLayoutEffectsStarted,
--   DebugTracing.logLayoutEffectsStopped,
--   logPassiveEffectsStarted,
--   DebugTracing.logPassiveEffectsStopped,
--   DebugTracing.logRenderStarted,
--   DebugTracing.logRenderStopped,
local DebugTracing = require(script.Parent:WaitForChild('DebugTracing'))-- local {
--   SchedulingProfiler.markCommitStarted,
--   SchedulingProfiler.markCommitStopped,
--   SchedulingProfiler.markLayoutEffectsStarted,
--   SchedulingProfiler.markLayoutEffectsStopped,
--   SchedulingProfiler.markPassiveEffectsStarted,
--   SchedulingProfiler.markPassiveEffectsStopped,
--   SchedulingProfiler.markRenderStarted,
--   SchedulingProfiler.markRenderYielded,
--   SchedulingProfiler.markRenderStopped,

local SchedulingProfiler = require(script.Parent:WaitForChild('SchedulingProfiler'))

local SchedulerTracing = require(script.Parent.Parent:WaitForChild('scheduler')).tracing
local __interactionsRef, __subscriberRef =
	SchedulerTracing.__interactionsRef, SchedulerTracing.__subscriberRef

local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local prepareForCommit = ReactFiberHostConfig.prepareForCommit
-- local resetAfterCommit = ReactFiberHostConfig.resetAfterCommit
-- local scheduleTimeout = ReactFiberHostConfig.scheduleTimeout
-- local cancelTimeout = ReactFiberHostConfig.cancelTimeout
-- local noTimeout = ReactFiberHostConfig.noTimeout
-- local warnsIfNotActing = ReactFiberHostConfig.warnsIfNotActing
-- local beforeActiveInstanceBlur = ReactFiberHostConfig.beforeActiveInstanceBlur
-- local afterActiveInstanceBlur = ReactFiberHostConfig.afterActiveInstanceBlur
-- local clearContainer = ReactFiberHostConfig.clearContainer


local ReactFiber = require(script.Parent:WaitForChild('ReactFiber.new'))-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local createWorkInProgress = ReactFiber.createWorkInProgress
-- local assignFiberPropertiesInDEV = ReactFiber.assignFiberPropertiesInDEV

local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local NoMode = ReactTypeOfMode.NoMode
-- local StrictMode = ReactTypeOfMode.StrictMode
-- local ProfileMode = ReactTypeOfMode.ProfileMode
-- local BlockingMode = ReactTypeOfMode.BlockingMode
-- local ConcurrentMode = ReactTypeOfMode.ConcurrentMode

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local HostRoot = ReactWorkTags.HostRoot
-- local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
-- local ClassComponent = ReactWorkTags.ClassComponent
-- local SuspenseComponent = ReactWorkTags.SuspenseComponent
-- local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
-- local FunctionComponent = ReactWorkTags.FunctionComponent
-- local ForwardRef = ReactWorkTags.ForwardRef
-- local MemoComponent = ReactWorkTags.MemoComponent
-- local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent

local LegacyRoot = require(script.Parent:WaitForChild('ReactRootTags')).LegacyRoot
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
type Flags = ReactFiberFlags.Flags
-- ROBLOX deviation: Use properties directly instead of localizing to avoid 200 limit
-- local NoFlags = ReactFiberFlags.NoFlags
-- local Placement = ReactFiberFlags.Placement
-- local Incomplete = ReactFiberFlags.Incomplete
-- local HostEffectMask = ReactFiberFlags.HostEffectMask
-- local Hydrating = ReactFiberFlags.Hydrating
-- local BeforeMutationMask = ReactFiberFlags.BeforeMutationMask
-- local MutationMask = ReactFiberFlags.MutationMask
-- local LayoutMask = ReactFiberFlags.LayoutMask
-- local PassiveMask = ReactFiberFlags.PassiveMask
-- local NoLane = ReactFiberLane.NoLane
local SyncLane = ReactFiberLane.SyncLane
local SyncBatchedLane = ReactFiberLane.SyncBatchedLane
local NoTimestamp = ReactFiberLane.NoTimestamp
local findUpdateLane = ReactFiberLane.findUpdateLane
local findTransitionLane = ReactFiberLane.findTransitionLane
local findRetryLane = ReactFiberLane.findRetryLane
local includesSomeLane = ReactFiberLane.includesSomeLane
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local mergeLanes = ReactFiberLane.mergeLanes
local removeLanes = ReactFiberLane.removeLanes
local pickArbitraryLane = ReactFiberLane.pickArbitraryLane
local hasDiscreteLanes = ReactFiberLane.hasDiscreteLanes
local includesNonIdleWork = ReactFiberLane.includesNonIdleWork
local includesOnlyRetries = ReactFiberLane.includesOnlyRetries
local includesOnlyTransitions = ReactFiberLane.includesOnlyTransitions
local getNextLanes = ReactFiberLane.getNextLanes
local returnNextLanesPriority = ReactFiberLane.returnNextLanesPriority
local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
local markStarvedLanesAsExpired = ReactFiberLane.markStarvedLanesAsExpired
local getLanesToRetrySynchronouslyOnError =
	ReactFiberLane.getLanesToRetrySynchronouslyOnError
local getMostRecentEventTime = ReactFiberLane.getMostRecentEventTime
local markRootUpdated = ReactFiberLane.markRootUpdated
local markRootSuspended_dontCallThisOneDirectly = ReactFiberLane.markRootSuspended
local markRootPinged = ReactFiberLane.markRootPinged
local markRootExpired = ReactFiberLane.markRootExpired
local markDiscreteUpdatesExpired = ReactFiberLane.markDiscreteUpdatesExpired
local markRootFinished = ReactFiberLane.markRootFinished
local schedulerPriorityToLanePriority = ReactFiberLane.schedulerPriorityToLanePriority
local lanePriorityToSchedulerPriority = ReactFiberLane.lanePriorityToSchedulerPriority
local ReactFiberTransition = require(script.Parent:WaitForChild('ReactFiberTransition'))-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local requestCurrentTransition = ReactFiberTransition.requestCurrentTransition
-- local NoTransition = ReactFiberTransition.NoTransition


local ReactFiberUnwindWork = require(script.Parent:WaitForChild('ReactFiberUnwindWork.new')):: any
local unwindWork = ReactFiberUnwindWork.unwindWork
local unwindInterruptedWork = ReactFiberUnwindWork.unwindInterruptedWork
local ReactFiberThrow = require(script.Parent:WaitForChild('ReactFiberThrow.new')):: any
local throwException = ReactFiberThrow.throwException
local createRootErrorUpdate = ReactFiberThrow.createRootErrorUpdate
local createClassErrorUpdate = ReactFiberThrow.createClassErrorUpdate
local ReactFiberCommitWork = require(script.Parent:WaitForChild('ReactFiberCommitWork.new'))
local commitBeforeMutationEffectOnFiber =
	ReactFiberCommitWork.commitBeforeMutationLifeCycles
local commitPlacement = ReactFiberCommitWork.commitPlacement
local commitWork = ReactFiberCommitWork.commitWork
local commitDeletion = ReactFiberCommitWork.commitDeletion
local commitPassiveUnmountOnFiber = ReactFiberCommitWork.commitPassiveUnmount
local commitPassiveUnmountInsideDeletedTreeOnFiber =
	ReactFiberCommitWork.commitPassiveUnmountInsideDeletedTree
local commitPassiveMountOnFiber = ReactFiberCommitWork.commitPassiveMount
local commitDetachRef = ReactFiberCommitWork.commitDetachRef
-- local commitAttachRef = ReactFiberCommitWork.commitAttachRef
-- local commitResetTextContent = ReactFiberCommitWork.commitResetTextContent
-- local isSuspenseBoundaryBeingHidden = ReactFiberCommitWork.isSuspenseBoundaryBeingHidden
local invokeLayoutEffectMountInDEV = ReactFiberCommitWork.invokeLayoutEffectMountInDEV
local invokePassiveEffectMountInDEV = ReactFiberCommitWork.invokePassiveEffectMountInDEV
local invokeLayoutEffectUnmountInDEV = ReactFiberCommitWork.invokeLayoutEffectUnmountInDEV
local invokePassiveEffectUnmountInDEV =
	ReactFiberCommitWork.invokePassiveEffectUnmountInDEV
local recursivelyCommitLayoutEffects = ReactFiberCommitWork.recursivelyCommitLayoutEffects

local Promise = require(script.Parent.Parent:WaitForChild('promise'))

local enqueueUpdate = require(script.Parent:WaitForChild('ReactUpdateQueue.new')).enqueueUpdate

local resetContextDependencies =
	require(script.Parent:WaitForChild('ReactFiberNewContext.new')).resetContextDependencies

-- ROBLOX deviation: RobloxReactProfiling
local RobloxReactProfiling = require(script.Parent.RobloxReactProfiling)

-- ROBLOX deviation: Pre-declare function
local ensureRootIsScheduled

-- deviation: lazy init for functions from ReactFiberHooks, put in table b/c local var limit
local lazyInitRefs = {
	resetHooksAfterThrowRef = (nil :: any) :: (...any) -> ...any,
	ContextOnlyDispatcherRef = (nil :: any) :: Dispatcher,
	getIsUpdatingOpaqueValueInRenderPhaseInDEVRef = (nil :: any) :: (...any) -> ...any,
	originalBeginWorkRef = (nil :: any) :: (...any) -> ...any,
	completeWorkRef = (nil :: any) :: (...any) -> ...any,
}

-- ROBLOX deviation: lazy initialize beginwork to break cyclic dependencies
local originalBeginWork =
	function(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes): Fiber | nil
		if not lazyInitRefs.originalBeginWorkRef then
			lazyInitRefs.originalBeginWorkRef =
				require(script.Parent:WaitForChild('ReactFiberBeginWork.new')).beginWork
		end
		return lazyInitRefs.originalBeginWorkRef(current, workInProgress, renderLanes)
	end

local completeWork =
	function(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes): Fiber | nil
		if not lazyInitRefs.completeWorkRef then
			lazyInitRefs.completeWorkRef =
				require(script.Parent:WaitForChild('ReactFiberCompleteWork.new')).completeWork
		end
		return (lazyInitRefs.completeWorkRef :: any)(current, workInProgress, renderLanes)
	end

local ReactFiberHooks
-- ROBLOX deviation: lazy init for functions from ReactFiberHooks
local function initReactFiberHooks()
	ReactFiberHooks = require(script.Parent:WaitForChild('ReactFiberHooks.new'))	
lazyInitRefs.resetHooksAfterThrowRef = ReactFiberHooks.resetHooksAfterThrow
	lazyInitRefs.ContextOnlyDispatcherRef = ReactFiberHooks.ContextOnlyDispatcher
	lazyInitRefs.getIsUpdatingOpaqueValueInRenderPhaseInDEVRef =
		ReactFiberHooks.getIsUpdatingOpaqueValueInRenderPhaseInDEV
end

-- ROBLOX deviation: lazy init for resetHooksAfterThrow from ReactFiberHooks
local resetHooksAfterThrow = function(): ()
	if not lazyInitRefs.resetHooksAfterThrowRef then
		initReactFiberHooks()
	end
	return lazyInitRefs.resetHooksAfterThrowRef()
end

-- ROBLOX deviation: lazy init for ContextOnlyDispatcher from ReactFiberHooks
local ContextOnlyDispatcher = function(): Dispatcher
	if not lazyInitRefs.ContextOnlyDispatcherRef then
		initReactFiberHooks()
	end
	return lazyInitRefs.ContextOnlyDispatcherRef
end

-- ROBLOX deviation: lazy init for getIsUpdatingOpaqueValueInRenderPhaseInDEV from ReactFiberHooks
local getIsUpdatingOpaqueValueInRenderPhaseInDEV = function(): boolean?
	if not lazyInitRefs.getIsUpdatingOpaqueValueInRenderPhaseInDEVRef then
		initReactFiberHooks()
	end
	return lazyInitRefs.getIsUpdatingOpaqueValueInRenderPhaseInDEVRef()
end

local createCapturedValue = require(script.Parent:WaitForChild('ReactCapturedValue')).createCapturedValue
local pushToStack = ReactFiberStack.push
local popFromStack = ReactFiberStack.pop
local createCursor = ReactFiberStack.createCursor

local ReactProfilerTimer = require(script.Parent:WaitForChild('ReactProfilerTimer.new'))
-- DEV stuff

local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local ReactStrictModeWarnings = require(script.Parent:WaitForChild('ReactStrictModeWarnings.new'))
local ReactCurrentFiber = require(script.Parent:WaitForChild('ReactCurrentFiber'))-- deviation: these two properties would be captured as values instead of bound
-- local ReactCurrentDebugFiberIsRenderingInDEV = ReactCurrentFiber.isRendering

local ReactCurrentFiberCurrent = ReactCurrentFiber.current
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local ReactErrorUtils = require(script.Parent.Parent:WaitForChild('shared')).ReactErrorUtils
local invokeGuardedCallback = ReactErrorUtils.invokeGuardedCallback
local hasCaughtError = ReactErrorUtils.hasCaughtError
local clearCaughtError = ReactErrorUtils.clearCaughtError
local onCommitRootDevTools = require(script.Parent:WaitForChild('ReactFiberDevToolsHook.new')).onCommitRoot
local onCommitRootTestSelector = require(script.Parent:WaitForChild('ReactTestSelectors')).onCommitRoot

-- Used by `act`
local enqueueTask = require(script.Parent.Parent:WaitForChild('shared')).enqueueTask
local doesFiberContain = require(script.Parent:WaitForChild('ReactFiberTreeReflection')).doesFiberContain

local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
local ReactCurrentOwner = ReactSharedInternals.ReactCurrentOwner
local IsSomeRendererActing = ReactSharedInternals.IsSomeRendererActing
local captureCommitPhaseErrorOnRoot, flushPassiveMountEffects

-- local ceil = math.ceil

-- ROBLOX deviation: Pre-declare functions
local mod: { [string]: any } = {}

type ExecutionContext = number

local NoContext = --[[                    ]]
	0b0000000
local BatchedContext = --[[               ]]
	0b0000001
local EventContext = --[[                 ]]
	0b0000010
local DiscreteEventContext = --[[         ]]
	0b0000100
local LegacyUnbatchedContext = --[[       ]]
	0b0001000
local RenderContext = --[[                ]]
	0b0010000
local CommitContext = --[[                ]]
	0b0100000
local RetryAfterError = --[[              ]]
	0b1000000

exports.NoContext = NoContext
exports.RetryAfterError = RetryAfterError

-- ROBLOX deviation: Luau doesn't yet support literal types
-- type RootExitStatus = 0 | 1 | 2 | 3 | 4 | 5
type RootExitStatus = number
-- ROBLOX deviation: Define constants in a table instead of locals to avoid 200 limit
local RootExitStatus: { [string]: RootExitStatus } = {
	Incomplete = 0,
	FatalErrored = 1,
	Errored = 2,
	Suspended = 3,
	SuspendedWithDelay = 4,
	Completed = 5,
}

-- Describes where we are in the React execution stack
local executionContext: ExecutionContext = NoContext
-- The root we're working on
local workInProgressRoot: FiberRoot? -- The fiber we're working on

local workInProgress: Fiber? -- The lanes we're rendering

local workInProgressRootRenderLanes: Lanes = ReactFiberLane.NoLanes

-- Stack that allows components to change the render lanes for its subtree
-- This is a superset of the lanes we started working on at the root. The only
-- case where it's different from `workInProgressRootRenderLanes` is when we
-- enter a subtree that is hidden and needs to be unhidden: Suspense and
-- Offscreen component.
--
-- Most things in the work loop should deal with workInProgressRootRenderLanes.
-- Most things in begin/complete phases should deal with exports.subtreeRenderLanes.
exports.subtreeRenderLanes = ReactFiberLane.NoLanes
local subtreeRenderLanesCursor: StackCursor<Lanes> = createCursor(ReactFiberLane.NoLanes)

-- Whether to root completed, errored, suspended, etc.
local workInProgressRootExitStatus: RootExitStatus = RootExitStatus.Incomplete
-- A fatal error, if one is thrown
local workInProgressRootFatalError: any -- "Included" lanes refer to lanes that were worked on during this render. It's
-- slightly different than `renderLanes` because `renderLanes` can change as you
-- enter and exit an Offscreen tree. This value is the combination of all render
-- lanes for the entire render phase.

local workInProgressRootIncludedLanes: Lanes = ReactFiberLane.NoLanes
-- The work left over by components that were visited during this render. Only
-- includes unprocessed updates, not work in bailed out children.
local ReactFiberWorkInProgress = require(script.Parent:WaitForChild('ReactFiberWorkInProgress'))
local workInProgressRootSkippedLanes: (value: Lanes?) -> Lanes =
	ReactFiberWorkInProgress.workInProgressRootSkippedLanes --: Lanes = ReactFiberLane.NoLanes
-- Lanes that were updated (in an interleaved event) during this render.
local workInProgressRootUpdatedLanes: Lanes = ReactFiberLane.NoLanes
-- Lanes that were pinged (in an interleaved event) during this render.
local workInProgressRootPingedLanes: Lanes = ReactFiberLane.NoLanes

local mostRecentlyUpdatedRoot: FiberRoot | nil 
-- The most recent time we committed a fallback. This lets us ensure a train
-- model where we don't commit new loading states in too quick succession.

local globalMostRecentFallbackTime: number = 0
local FALLBACK_THROTTLE_MS: number = 500

-- The absolute time for when we should start giving up on rendering
-- more and prefer CPU suspense heuristics instead.
local workInProgressRootRenderTargetTime: number = math.huge
-- How long a render is supposed to take before we start following CPU
-- suspense heuristics and opt out of rendering more content.
local RENDER_TIMEOUT_MS = 500

-- Used to avoid traversing the return path to find the nearest Profiler ancestor during commit.
local nearestProfilerOnStack: Fiber | nil 

local function resetRenderTimer()
	workInProgressRootRenderTargetTime = now() + RENDER_TIMEOUT_MS
end

exports.getRenderTargetTime = function(): number
	return workInProgressRootRenderTargetTime
end

local hasUncaughtError = false
local firstUncaughtError 
local legacyErrorBoundariesThatAlreadyFailed: Set<any> | nil 

local rootDoesHavePassiveEffects: boolean = false
local rootWithPendingPassiveEffects: FiberRoot? 
local pendingPassiveEffectsRenderPriority: ReactPriorityLevel = NoSchedulerPriority
local pendingPassiveEffectsLanes: Lanes = ReactFiberLane.NoLanes

local rootsWithPendingDiscreteUpdates: Set<ReactInternalTypes.FiberRoot> | nil 
-- Use these to prevent an infinite loop of nested updates

local NESTED_UPDATE_LIMIT = 50
local nestedUpdateCount: number = 0
local rootWithNestedUpdates: FiberRoot | nil 

local NESTED_PASSIVE_UPDATE_LIMIT = 50
local nestedPassiveUpdateCount: number = 0

-- Marks the need to reschedule pending interactions at these lanes
-- during the commit phase. This enables them to be traced across components
-- that spawn new work during render. E.g. hidden boundaries, suspended SSR
-- hydration or SuspenseList.
-- TODO: Can use a bitmask instead of an array
local spawnedWorkDuringRender: nil | Array<Lane | Lanes> 
-- If two updates are scheduled within the same event, we should treat their
-- event times as simultaneous, even if the actual clock time has advanced
-- between the first and second call.

local currentEventTime: number = NoTimestamp
local currentEventWipLanes: Lanes = ReactFiberLane.NoLanes
local currentEventPendingLanes: Lanes = ReactFiberLane.NoLanes

local focusedInstanceHandle: nil | Fiber 
local shouldFireAfterActiveInstanceBlur: boolean = false

exports.getWorkInProgressRoot = function(): FiberRoot?
	return workInProgressRoot
end

exports.requestEventTime = function()
	if
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext))
		~= NoContext
	then
		-- We're inside React, so it's fine to read the actual time.
		return now()
	end
	-- We're not inside React, so we may be in the middle of a browser event.
	if currentEventTime ~= NoTimestamp then
		-- Use the same start time for all updates until we enter React again.
		return currentEventTime
	end
	-- This is the first update since React yielded. Compute a new start time.
	currentEventTime = now()
	return currentEventTime
end

-- exports.getCurrentTime()
--   return now()
-- end

exports.requestUpdateLane = function(fiber: Fiber): Lane
	-- Special cases
	local mode = fiber.mode
	if bit32.band(mode, ReactTypeOfMode.BlockingMode) == ReactTypeOfMode.NoMode then
		return SyncLane :: Lane
	elseif bit32.band(mode, ReactTypeOfMode.ConcurrentMode) == ReactTypeOfMode.NoMode then
		return if getCurrentPriorityLevel() == ImmediateSchedulerPriority
			then SyncLane :: Lane
			else SyncBatchedLane :: Lane
	elseif
		not ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch
		and bit32.band(executionContext, RenderContext) ~= NoContext
		and workInProgressRootRenderLanes ~= ReactFiberLane.NoLanes
	then
		-- This is a render phase update. These are not officially supported. The
		-- old behavior is to give this the same "thread" (expiration time) as
		-- whatever is currently rendering. So if you call `setState` on a component
		-- that happens later in the same render, it will flush. Ideally, we want to
		-- remove the special case and treat them as if they came from an
		-- interleaved event. Regardless, this pattern is not officially supported.
		-- This behavior is only a fallback. The flag only exists until we can roll
		-- out the setState warning, since existing code might accidentally rely on
		-- the current behavior.
		return pickArbitraryLane(workInProgressRootRenderLanes)
	end

	-- The algorithm for assigning an update to a lane should be stable for all
	-- updates at the same priority within the same event. To do this, the inputs
	-- to the algorithm must be the same. For example, we use the `renderLanes`
	-- to avoid choosing a lane that is already in the middle of rendering.
	--
	-- However, the "included" lanes could be mutated in between updates in the
	-- same event, like if you perform an update inside `flushSync`. Or any other
	-- code path that might call `prepareFreshStack`.
	--
	-- The trick we use is to cache the first of each of these inputs within an
	-- event. Then reset the cached values once we can be sure the event is over.
	-- Our heuristic for that is whenever we enter a concurrent work loop.
	--
	-- We'll do the same for `currentEventPendingLanes` below.
	if currentEventWipLanes == ReactFiberLane.NoLanes then
		currentEventWipLanes = workInProgressRootIncludedLanes
	end

	local isTransition = ReactFiberTransition.requestCurrentTransition()
		~= ReactFiberTransition.NoTransition
	if isTransition then
		if currentEventPendingLanes ~= ReactFiberLane.NoLanes then
			if mostRecentlyUpdatedRoot ~= nil then
				currentEventPendingLanes = mostRecentlyUpdatedRoot.pendingLanes
			else
				currentEventPendingLanes = ReactFiberLane.NoLanes
			end
		end
		return findTransitionLane(currentEventWipLanes, currentEventPendingLanes)
	end

	-- TODO: Remove this dependency on the Scheduler priority.
	-- To do that, we're replacing it with an update lane priority.
	local schedulerPriority = getCurrentPriorityLevel()

	-- The old behavior was using the priority level of the Scheduler.
	-- This couples React to the Scheduler internals, so we're replacing it
	-- with the currentUpdateLanePriority above. As an example of how this
	-- could be problematic, if we're not inside `Scheduler.runWithPriority`,
	-- then we'll get the priority of the current running Scheduler task,
	-- which is probably not what we want.
	local lane
	if
		-- TODO: Temporary. We're removing the concept of discrete updates.
		bit32.band(executionContext, DiscreteEventContext) ~= NoContext
		and schedulerPriority == UserBlockingSchedulerPriority
	then
		lane =
			findUpdateLane(ReactFiberLane.InputDiscreteLanePriority, currentEventWipLanes)
	else
		local schedulerLanePriority = schedulerPriorityToLanePriority(schedulerPriority)

		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			-- In the new strategy, we will track the current update lane priority
			-- inside React and use that priority to select a lane for this update.
			-- For now, we're just logging when they're different so we can assess.
			local currentUpdateLanePriority = getCurrentUpdateLanePriority()

			if
				schedulerLanePriority ~= currentUpdateLanePriority
				and currentUpdateLanePriority ~= ReactFiberLane.NoLanePriority
			then
				if __DEV__ then
					console.error(
						"Expected current scheduler lane priority %s to match current update lane priority %s",
						tostring(schedulerLanePriority),
						tostring(currentUpdateLanePriority)
					)
				end
			end
		end

		lane = findUpdateLane(schedulerLanePriority, currentEventWipLanes)
	end

	return lane
end

function requestRetryLane(fiber: Fiber): Lane
	-- This is a fork of `requestUpdateLane` designed specifically for Suspense
	-- "retries" — a special update that attempts to flip a Suspense boundary
	-- from its placeholder state to its primary/resolved state.

	-- Special cases
	local mode = fiber.mode
	if bit32.band(mode, ReactTypeOfMode.BlockingMode) == ReactTypeOfMode.NoMode then
		return SyncLane :: Lane
	elseif bit32.band(mode, ReactTypeOfMode.ConcurrentMode) == ReactTypeOfMode.NoMode then
		return if getCurrentPriorityLevel() == ImmediateSchedulerPriority
			then SyncLane :: Lane
			else SyncBatchedLane :: Lane
	end

	-- See `requestUpdateLane` for explanation of `currentEventWipLanes`
	if currentEventWipLanes == ReactFiberLane.NoLanes then
		currentEventWipLanes = workInProgressRootIncludedLanes
	end
	return findRetryLane(currentEventWipLanes)
end

exports.scheduleUpdateOnFiber = function(
	fiber: Fiber,
	lane: Lane,
	eventTime: number
): FiberRoot | nil
	mod.checkForNestedUpdates()

	local root = mod.markUpdateLaneFromFiberToRoot(fiber, lane)
	if root == nil then
		return nil
	end

	-- Mark that the root has a pending update.
	markRootUpdated(root, lane, eventTime)

	if root == workInProgressRoot then
		-- Received an update to a tree that's in the middle of rendering. Mark
		-- that there was an interleaved update work on this root. Unless the
		-- `ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch` flag is off and this is a render
		-- phase update. In that case, we don't treat render phase updates as if
		-- they were interleaved, for backwards compat reasons.
		mod.warnAboutRenderPhaseUpdatesInDEV(fiber)

		if
			ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch
			or bit32.band(executionContext, RenderContext) == NoContext
		then
			workInProgressRootUpdatedLanes =
				mergeLanes(workInProgressRootUpdatedLanes, lane)
		end
		if workInProgressRootExitStatus == RootExitStatus.SuspendedWithDelay then
			-- The root already suspended with a delay, which means this render
			-- definitely won't finish. Since we have a new update, let's mark it as
			-- suspended now, right before marking the incoming update. This has the
			-- effect of interrupting the current render and switching to the update.
			-- TODO: Make sure this doesn't override pings that happen while we've
			-- already started rendering.
			mod.markRootSuspended(root, workInProgressRootRenderLanes)
		end
	end

	-- TODO: requestUpdateLanePriority also reads the priority. Pass the
	-- priority as an argument to that function and this one.
	local priorityLevel = getCurrentPriorityLevel()

	if lane == SyncLane then
		if
			-- Check if we're inside unbatchedUpdates
			bit32.band(executionContext, LegacyUnbatchedContext) ~= NoContext
			-- Check if we're not already rendering
			and bit32.band(executionContext, bit32.bor(RenderContext, CommitContext))
				== NoContext
		then
			-- Register pending interactions on the root to avoid losing traced interaction data.
			mod.schedulePendingInteractions(root, lane)

			-- This is a legacy edge case. The initial mount of a ReactDOM.render-ed
			-- root inside of batchedUpdates should be synchronous, but layout updates
			-- should be deferred until the end of the batch.
			mod.performSyncWorkOnRoot(root)
		else
			ensureRootIsScheduled(root, eventTime)
			mod.schedulePendingInteractions(root, lane)
			if executionContext == NoContext then
				-- Flush the synchronous work now, unless we're already working or inside
				-- a batch. This is intentionally inside scheduleUpdateOnFiber instead of
				-- scheduleCallbackForFiber to preserve the ability to schedule a callback
				-- without immediately flushing it. We only do this for user-initiated
				-- updates, to preserve historical behavior of legacy mode.
				resetRenderTimer()
				flushSyncCallbackQueue()
			end
		end
	else
		-- Schedule a discrete update but only if it's not Sync.
		if
			bit32.band(executionContext, DiscreteEventContext) ~= NoContext
			-- Only updates at user-blocking priority or greater are considered
			-- discrete, even inside a discrete event.
			and (
				priorityLevel == UserBlockingSchedulerPriority
				or priorityLevel == ImmediateSchedulerPriority
			)
		then
			-- This is the result of a discrete event. Track the lowest priority
			-- discrete update per root so we can flush them early, if needed.
			if rootsWithPendingDiscreteUpdates == nil then
				rootsWithPendingDiscreteUpdates = Set.new({ root })
			else
				rootsWithPendingDiscreteUpdates:add(root)
			end
		end
		-- Schedule other updates after in case the callback is sync.
		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, lane)
	end

	-- We use this when assigning a lane for a transition inside
	-- `requestUpdateLane`. We assume it's the same as the root being updated,
	-- since in the common case of a single root app it probably is. If it's not
	-- the same root, then it's not a huge deal, we just might batch more stuff
	-- together more than necessary.
	mostRecentlyUpdatedRoot = root
	return root
end

-- This is split into a separate function so we can mark a fiber with pending
-- work without treating it as a typical update that originates from an event
-- e.g. retrying a Suspense boundary isn't an update, but it does schedule work
-- on a fiber.
mod.markUpdateLaneFromFiberToRoot = function(sourceFiber: Fiber, lane: Lane): FiberRoot?
	-- Update the source fiber's lanes
	sourceFiber.lanes = mergeLanes(sourceFiber.lanes, lane)
	local alternate = sourceFiber.alternate
	if alternate ~= nil then
		alternate.lanes = mergeLanes(alternate.lanes, lane)
	end
	if __DEV__ then
		if
			alternate == nil
			and bit32.band(
					sourceFiber.flags,
					bit32.bor(ReactFiberFlags.Placement, ReactFiberFlags.Hydrating)
				)
				~= ReactFiberFlags.NoFlags
		then
			mod.warnAboutUpdateOnNotYetMountedFiberInDEV(sourceFiber)
		end
	end
	-- Walk the parent path to the root and update the child expiration time.
	local node = sourceFiber
	local parent = sourceFiber.return_
	while parent ~= nil do
		parent.childLanes = mergeLanes(parent.childLanes, lane)
		alternate = parent.alternate
		if alternate ~= nil then
			alternate.childLanes = mergeLanes(alternate.childLanes, lane)
		else
			if __DEV__ then
				if
					bit32.band(
						parent.flags,
						bit32.bor(ReactFiberFlags.Placement, ReactFiberFlags.Hydrating)
					) ~= ReactFiberFlags.NoFlags
				then
					mod.warnAboutUpdateOnNotYetMountedFiberInDEV(sourceFiber)
				end
			end
		end
		node = parent
		parent = parent.return_
	end
	if node.tag == ReactWorkTags.HostRoot then
		local root: FiberRoot = node.stateNode
		return root
	else
		return nil
	end
end

-- Use this function to schedule a task for a root. There's only one task per
-- root; if a task was already scheduled, we'll check to make sure the priority
-- of the existing task is the same as the priority of the next level that the
-- root has work on. This function is called on every update, and right before
-- exiting a task.
ensureRootIsScheduled = function(root: FiberRoot, currentTime: number)
	local existingCallbackNode = root.callbackNode

	-- Check if any lanes are being starved by other work. If so, mark them as
	-- expired so we know to work on those next.
	markStarvedLanesAsExpired(root, currentTime)

	-- Determine the next lanes to work on, and their priority.
	local lanes
	if root == workInProgressRoot then
		lanes = workInProgressRootRenderLanes
	else
		lanes = ReactFiberLane.NoLanes
	end
	local nextLanes = getNextLanes(root, lanes)
	-- This returns the priority level computed during the `getNextLanes` call.
	local newCallbackPriority = returnNextLanesPriority()

	if nextLanes == ReactFiberLane.NoLanes then
		-- Special case: There's nothing to work on.
		if existingCallbackNode ~= nil then
			cancelCallback(existingCallbackNode)
			root.callbackNode = nil
			root.callbackPriority = ReactFiberLane.NoLanePriority
		end
		return
	end

	-- Check if there's an existing task. We may be able to reuse it.
	if existingCallbackNode ~= nil then
		local existingCallbackPriority = root.callbackPriority
		if existingCallbackPriority == newCallbackPriority then
			-- The priority hasn't changed. We can reuse the existing task. Exit.
			return
		end
		-- The priority changed. Cancel the existing callback. We'll schedule a new
		-- one below.
		cancelCallback(existingCallbackNode)
	end

	-- Schedule a new callback.
	local newCallbackNode
	if newCallbackPriority == ReactFiberLane.SyncLanePriority then
		-- Special case: Sync React callbacks are scheduled on a special
		-- internal queue
		newCallbackNode = scheduleSyncCallback(function()
			-- ROBLOX deviation: RobloxReactProfiling
			local profileRunning = RobloxReactProfiling.profileRootBeforeUnitOfWork(root)
			local ret = mod.performSyncWorkOnRoot(root)
			RobloxReactProfiling.profileRootAfterYielding(profileRunning)
			return ret
		end)
	elseif newCallbackPriority == ReactFiberLane.SyncBatchedLanePriority then
		newCallbackNode = scheduleCallback(ImmediateSchedulerPriority, function()
			-- ROBLOX deviation: RobloxReactProfiling
			local profileRunning = RobloxReactProfiling.profileRootBeforeUnitOfWork(root)
			local ret = mod.performSyncWorkOnRoot(root)
			RobloxReactProfiling.profileRootAfterYielding(profileRunning)
			return ret
		end)
	else
		local schedulerPriorityLevel =
			lanePriorityToSchedulerPriority(newCallbackPriority)
		newCallbackNode = scheduleCallback(schedulerPriorityLevel, function()
			-- ROBLOX deviation: RobloxReactProfiling
			local profileRunning = RobloxReactProfiling.profileRootBeforeUnitOfWork(root)
			local ret = mod.performConcurrentWorkOnRoot(root)
			RobloxReactProfiling.profileRootAfterYielding(profileRunning)
			return ret
		end)
	end

	root.callbackPriority = newCallbackPriority
	root.callbackNode = newCallbackNode
end

-- This is the entry point for every concurrent task, i.e. anything that
-- goes through Scheduler.
-- ROBLOX Luau FIXME: Luau needs explicit annotation with nil-able returns
mod.performConcurrentWorkOnRoot = function(root): (() -> ...any) | nil
	-- Since we know we're in a React event, we can clear the current
	-- event time. The next update will compute a new event time.
	currentEventTime = NoTimestamp
	currentEventWipLanes = ReactFiberLane.NoLanes
	currentEventPendingLanes = ReactFiberLane.NoLanes

	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Should not already be working."
	)

	-- Flush any pending passive effects before deciding which lanes to work on,
	-- in case they schedule additional work.
	local originalCallbackNode = root.callbackNode
	local didFlushPassiveEffects = exports.flushPassiveEffects()
	if didFlushPassiveEffects then
		-- Something in the passive effect phase may have canceled the current task.
		-- Check if the task node for this root was changed.
		if root.callbackNode ~= originalCallbackNode then
			-- The current task was canceled. Exit. We don't need to call
			-- `ensureRootIsScheduled` because the check above implies either that
			-- there's a new task, or that there's no remaining work on this root.
			return nil
			-- Current task was not canceled. Continue.
		
end
	end

	-- Determine the next expiration time to work on, using the fields stored
	-- on the root.
	local lanes = getNextLanes(
		root,
		if root == workInProgressRoot
			then workInProgressRootRenderLanes
			else ReactFiberLane.NoLanes
	)
	if lanes == ReactFiberLane.NoLanes then
		-- Defensive coding. This is never expected to happen.
		return nil
	end

	local exitStatus = mod.renderRootConcurrent(root, lanes)

	if
		includesSomeLane(workInProgressRootIncludedLanes, workInProgressRootUpdatedLanes)
	then
		-- The render included lanes that were updated during the render phase.
		-- For example, when unhiding a hidden tree, we include all the lanes
		-- that were previously skipped when the tree was hidden. That set of
		-- lanes is a superset of the lanes we started rendering with.
		--
		-- So we'll throw out the current work and restart.
		mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
	elseif exitStatus ~= RootExitStatus.Incomplete then
		if exitStatus == RootExitStatus.Errored then
			executionContext = bit32.bor(executionContext, RetryAfterError)

			-- If an error occurred during hydration,
			-- discard server response and fall back to client side render.
			if root.hydrate then
				root.hydrate = false
				ReactFiberHostConfig.clearContainer(root.containerInfo)
			end

			-- If something threw an error, try rendering one more time. We'll render
			-- synchronously to block concurrent data mutations, and we'll includes
			-- all pending updates are included. If it still fails after the second
			-- attempt, we'll give up and commit the resulting tree.
			lanes = getLanesToRetrySynchronouslyOnError(root)
			if lanes ~= ReactFiberLane.NoLanes then
				exitStatus = mod.renderRootSync(root, lanes)
			end
		end

		if exitStatus == RootExitStatus.FatalErrored then
			local fatalError = workInProgressRootFatalError
			mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
			mod.markRootSuspended(root, lanes)
			ensureRootIsScheduled(root, now())
			error(fatalError)
		end

		-- We now have a consistent tree. The next step is either to commit it,
		-- or, if something suspended, wait to commit it after a timeout.
		local finishedWork: Fiber = root.current.alternate :: any
		root.finishedWork = finishedWork
		root.finishedLanes = lanes
		mod.finishConcurrentRender(root, exitStatus, lanes)
	end

	ensureRootIsScheduled(root, now())
	if root.callbackNode == originalCallbackNode then
		-- The task node scheduled for this root is the same one that's
		-- currently executed. Need to return a continuation.
		return function()
			return mod.performConcurrentWorkOnRoot(root)
		end
	end
	-- ROBLOX Luau FIXME: Luau shouldn't error on nil-able returns
	return nil :: any
end

-- we track the 'depth' of the act() calls with this counter,
-- so we can tell if any async act() calls try to run in parallel.
local actingUpdatesScopeDepth = 0
local didWarnAboutUsingActInProd = false

function shouldForceFlushFallbacksInDEV()
	-- Never force flush in production. This function should get stripped out.
	return __DEV__ and actingUpdatesScopeDepth > 0
end

mod.finishConcurrentRender = function(root, exitStatus, lanes)
	if
		exitStatus == RootExitStatus.Incomplete
		or exitStatus == RootExitStatus.FatalErrored
	then
		invariant(false, "Root did not complete. This is a bug in React.")
	-- Flow knows about invariant, so it complains if I add a break
	-- if I do. eslint-disable-next-line no-fallthrough
	-- statement, but eslint doesn't know about invariant, so it complains
	elseif exitStatus == RootExitStatus.Errored then
		-- We should have already attempted to retry this tree. If we reached
		-- this point, it errored again. Commit it.
		mod.commitRoot(root)
	elseif exitStatus == RootExitStatus.Suspended then
		mod.markRootSuspended(root, lanes)

		-- We have an acceptable loading state. We need to figure out if we
		-- should immediately commit it or wait a bit.
		if
			includesOnlyRetries(lanes)
			-- do not delay if we're inside an act() scope
			and not shouldForceFlushFallbacksInDEV()
		then
			-- This render only included retries, no updates. Throttle committing
			-- retries so that we don't show too many loading states too quickly.
			local msUntilTimeout = globalMostRecentFallbackTime
				+ FALLBACK_THROTTLE_MS
				- now()
			-- Don't bother with a very short suspense time.
			if msUntilTimeout > 10 then
				local nextLanes = getNextLanes(root, ReactFiberLane.NoLanes)
				if nextLanes ~= ReactFiberLane.NoLanes then
					-- There's additional work on this root.
					return
				end
				local suspendedLanes = root.suspendedLanes
				if not isSubsetOfLanes(suspendedLanes, lanes) then
					-- We should prefer to render the fallback of at the last
					-- suspended level. Ping the last suspended level to try
					-- rendering it again.
					-- FIXME: What if the suspended lanes are Idle? Should not restart.
					local eventTime = exports.requestEventTime()
					markRootPinged(root, suspendedLanes, eventTime)
					return
				end

				-- The render is suspended, it hasn't timed out, and there's no
				-- lower priority work to do. Instead of committing the fallback
				-- immediately, wait for more data to arrive.
				root.timeoutHandle = ReactFiberHostConfig.scheduleTimeout(function()
					return mod.commitRoot(root)
				end, msUntilTimeout)
				return
			end
		end
		-- The work expired. Commit immediately.
		mod.commitRoot(root)
	elseif exitStatus == RootExitStatus.SuspendedWithDelay then
		mod.markRootSuspended(root, lanes)

		if includesOnlyTransitions(lanes) then
			-- This is a transition, so we should exit without committing a
			-- placeholder and without scheduling a timeout. Delay indefinitely
			-- until we receive more data.
			return
		end

		if not shouldForceFlushFallbacksInDEV() then
			-- This is not a transition, but we did trigger an avoided state.
			-- Schedule a placeholder to display after a short delay, using the Just
			-- Noticeable Difference.
			-- TODO: Is the JND optimization worth the added complexity? If this is
			-- the only reason we track the event time, then probably not.
			-- Consider removing.

			local mostRecentEventTime = getMostRecentEventTime(root, lanes)
			local eventTimeMs = mostRecentEventTime
			local timeElapsedMs = now() - eventTimeMs
			local msUntilTimeout = jnd(timeElapsedMs) - timeElapsedMs

			-- Don't bother with a very short suspense time.
			if msUntilTimeout > 10 then
				-- Instead of committing the fallback immediately, wait for more data
				-- to arrive.
				root.timeoutHandle = ReactFiberHostConfig.scheduleTimeout(function()
					return mod.commitRoot(root)
				end, msUntilTimeout)
				return
			end
		end
		-- Commit the placeholder.
		mod.commitRoot(root)
	elseif exitStatus == RootExitStatus.Completed then
		-- The work completed. Ready to commit.
		mod.commitRoot(root)
	else
		invariant(false, "Unknown root exit status.")
	end
end

mod.markRootSuspended = function(root, suspendedLanes)
	-- When suspending, we should always exclude lanes that were pinged or (more
	-- rarely, since we try to avoid it) updated during the render phase.
	-- TODO: Lol maybe there's a better way to factor this besides this
	-- obnoxiously named function :)
	suspendedLanes = removeLanes(suspendedLanes, workInProgressRootPingedLanes)
	suspendedLanes = removeLanes(suspendedLanes, workInProgressRootUpdatedLanes)
	markRootSuspended_dontCallThisOneDirectly(root, suspendedLanes)
end

-- This is the entry point for synchronous tasks that don't go
-- through Scheduler
mod.performSyncWorkOnRoot = function(root)
	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Should not already be working."
	)

	exports.flushPassiveEffects()

	local lanes
	local exitStatus
	if
		root == workInProgressRoot
		and includesSomeLane(root.expiredLanes, workInProgressRootRenderLanes)
	then
		-- There's a partial tree, and at least one of its lanes has expired. Finish
		-- rendering it before rendering the rest of the expired work.
		lanes = workInProgressRootRenderLanes
		exitStatus = mod.renderRootSync(root, lanes)
		if
			includesSomeLane(
				workInProgressRootIncludedLanes,
				workInProgressRootUpdatedLanes
			)
		then
			-- The render included lanes that were updated during the render phase.
			-- For example, when unhiding a hidden tree, we include all the lanes
			-- that were previously skipped when the tree was hidden. That set of
			-- lanes is a superset of the lanes we started rendering with.
			--
			-- Note that this only happens when part of the tree is rendered
			-- concurrently. If the whole tree is rendered synchronously, then there
			-- are no interleaved events.
			lanes = getNextLanes(root, lanes)
			exitStatus = mod.renderRootSync(root, lanes)
		end
	else
		lanes = getNextLanes(root, ReactFiberLane.NoLanes)
		exitStatus = mod.renderRootSync(root, lanes)
	end

	if root.tag ~= LegacyRoot and exitStatus == RootExitStatus.Errored then
		executionContext = bit32.bor(executionContext, RetryAfterError)

		-- If an error occurred during hydration,
		-- discard server response and fall back to client side render.
		if root.hydrate then
			root.hydrate = false
			ReactFiberHostConfig.clearContainer(root.containerInfo)
		end

		-- If something threw an error, try rendering one more time. We'll render
		-- synchronously to block concurrent data mutations, and we'll includes
		-- all pending updates are included. If it still fails after the second
		-- attempt, we'll give up and commit the resulting tree.
		lanes = getLanesToRetrySynchronouslyOnError(root)
		if lanes ~= ReactFiberLane.NoLanes then
			exitStatus = mod.renderRootSync(root, lanes)
		end
	end

	if exitStatus == RootExitStatus.FatalErrored then
		local fatalError = workInProgressRootFatalError
		mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
		mod.markRootSuspended(root, lanes)
		ensureRootIsScheduled(root, now())
		error(fatalError)
	end

	-- We now have a consistent tree. Because this is a sync render, we
	-- will commit it even if something suspended.
	local finishedWork: Fiber = root.current.alternate :: any
	root.finishedWork = finishedWork
	root.finishedLanes = lanes
	mod.commitRoot(root)

	-- Before exiting, make sure there's a callback scheduled for the next
	-- pending level.
	ensureRootIsScheduled(root, now())

	return nil
end

exports.flushRoot = function(root: FiberRoot, lanes: Lanes)
	markRootExpired(root, lanes)
	ensureRootIsScheduled(root, now())
	if
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext))
		== NoContext
	then
		resetRenderTimer()
		flushSyncCallbackQueue()
	end
end

exports.getExecutionContext = function(): ExecutionContext
	return executionContext
end

exports.flushDiscreteUpdates = function()
	-- TODO: Should be able to flush inside batchedUpdates, but not inside `act`.
	-- However, `act` uses `batchedUpdates`, so there's no way to distinguish
	-- those two cases. Need to fix this before exposing flushDiscreteUpdates
	-- as a public API.
	if
		bit32.band(
			executionContext,
			bit32.bor(BatchedContext, RenderContext, CommitContext)
		) ~= NoContext
	then
		if __DEV__ then
			if bit32.band(executionContext, RenderContext) ~= NoContext then
				console.error(
[[unstable_flushDiscreteUpdates: Cannot flush updates when React is already rendering.]]				

)
			end
		end
		-- We're already rendering, so we can't synchronously flush pending work.s
		-- This is probably a nested event dispatch triggered by a lifecycle/effect,
		-- like `el.focus()`. Exit.
		return
	end
	mod.flushPendingDiscreteUpdates()
	-- If the discrete updates scheduled passive effects, flush them now so that
	-- they fire before the next serial event.
	exports.flushPassiveEffects()
end

exports.deferredUpdates = function<A>(fn: () -> A): A
	if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
		local previousLanePriority = getCurrentUpdateLanePriority()
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not __YOLO__ then
			-- ROBLOX performance: hoist non-throwable out of try{} to eliminate anon function
			setCurrentUpdateLanePriority(ReactFiberLane.DefaultLanePriority)
			ok, result =
				xpcall(runWithPriority, describeError, NormalSchedulerPriority, fn)
		else
			ok = true
			setCurrentUpdateLanePriority(ReactFiberLane.DefaultLanePriority)
			result = runWithPriority(NormalSchedulerPriority, fn)
		end

		-- finally
		setCurrentUpdateLanePriority(previousLanePriority)

		if ok then
			return result
		else
			error(result)
		end
	else
		return runWithPriority(NormalSchedulerPriority, fn)
	end
end

mod.flushPendingDiscreteUpdates = function()
	if rootsWithPendingDiscreteUpdates ~= nil then
		-- For each root with pending discrete updates, schedule a callback to
		-- immediately flush them.
		local roots = rootsWithPendingDiscreteUpdates
		rootsWithPendingDiscreteUpdates = nil
		roots:forEach(function(root)
			markDiscreteUpdatesExpired(root)
			ensureRootIsScheduled(root, now())
		end)
	end
	-- Now flush the immediate queue.
	flushSyncCallbackQueue()
end

exports.batchedUpdates = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, BatchedContext)

	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not __YOLO__ then
		ok, result = xpcall(fn, describeError, a)
	else
		ok = true
		result = fn(a)
	end

	-- finally
	executionContext = prevExecutionContext
	if executionContext == NoContext then
		-- Flush the immediate callbacks that were scheduled during this batch
		resetRenderTimer()
		flushSyncCallbackQueue()
	end

	if ok then
		return result
	else
		error(result)
	end
end

exports.batchedEventUpdates = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, EventContext)

	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not __YOLO__ then
		ok, result = xpcall(fn, describeError, a)
	else
		ok = true
		result = fn(a)
	end

	-- finally
	executionContext = prevExecutionContext
	if executionContext == NoContext then
		-- Flush the immediate callbacks that were scheduled during this batch
		resetRenderTimer()
		flushSyncCallbackQueue()
	end

	if ok then
		return result
	else
		error(result)
	end
end

exports.discreteUpdates =
	function<A, B, C, D, R>(fn: (A, B, C, D) -> R, a: A, b: B, c: C, d: D): R
		local prevExecutionContext = executionContext
		executionContext = bit32.bor(executionContext, DiscreteEventContext)

		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			local previousLanePriority = getCurrentUpdateLanePriority()
			-- ROBLOX performance: extract non-throwable fn call out of try{} so we can remove an anon function
			setCurrentUpdateLanePriority(ReactFiberLane.InputDiscreteLanePriority)
			local ok, result = xpcall(
				runWithPriority,
				describeError,
				UserBlockingSchedulerPriority,
				function()
					return fn(a, b, c, d)
				end
			)

			-- finally
			setCurrentUpdateLanePriority(previousLanePriority)
			executionContext = prevExecutionContext
			if executionContext == NoContext then
				-- Flush the immediate callbacks that were scheduled during this batch
				resetRenderTimer()
				flushSyncCallbackQueue()
			end

			if ok then
				return result
			else
				error(result)
			end
		else
			local ok, result = xpcall(
				runWithPriority,
				describeError,
				UserBlockingSchedulerPriority,
				function()
					return fn(a, b, c, d)
				end
			)

			-- finally
			executionContext = prevExecutionContext
			if executionContext == NoContext then
				-- Flush the immediate callbacks that were scheduled during this batch
				resetRenderTimer()
				flushSyncCallbackQueue()
			end

			if ok then
				return result
			else
				error(result)
			end
		end
	end

exports.unbatchedUpdates = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	executionContext = bit32.band(executionContext, bit32.bnot(BatchedContext))
	executionContext = bit32.bor(executionContext, LegacyUnbatchedContext)
	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not __YOLO__ then
		ok, result = xpcall(fn, describeError, a)
	else
		ok = true
		result = fn(a)
	end

	-- finally
	executionContext = prevExecutionContext
	if executionContext == NoContext then
		-- Flush the immediate callbacks that were scheduled during this batch
		resetRenderTimer()
		flushSyncCallbackQueue()
	end

	if ok then
		return result
	else
		error(result)
	end
end

exports.flushSync = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	if
		(bit32.band(prevExecutionContext, bit32.bor(RenderContext, CommitContext)))
		~= NoContext
	then
		if __DEV__ then
			console.error(
[[flushSync was called from inside a lifecycle method. React cannot flush when React is already rendering. Consider moving this call to a scheduler task or micro task.]]			


)
		end
		return fn(a)
	end
	executionContext = bit32.bor(executionContext, BatchedContext)

	if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
		local previousLanePriority = getCurrentUpdateLanePriority()

		-- ROBLOX performance: extract non-throwable call out of try{} to eliminate an anon function
		setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not __YOLO__ then
			if fn then
				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediateSchedulerPriority,
					function()
						return fn(a)
					end
				)
			else
				ok = true
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		else
			ok = true
			setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
			if fn then
				result = runWithPriority(ImmediateSchedulerPriority, function()
					return fn(a)
				end)
			else
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		end

		-- ROBLOX finally
		setCurrentUpdateLanePriority(previousLanePriority)
		executionContext = prevExecutionContext
		-- Flush the immediate callbacks that were scheduled during this batch.
		-- Note that this will happen even if batchedUpdates is higher up
		-- the stack.
		flushSyncCallbackQueue()

		if not ok then
			error(result)
		end
		return result
	else
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not __YOLO__ then
			if fn then
				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediateSchedulerPriority,
					function()
						return fn(a)
					end
				)
			else
				ok = true
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		else
			ok = true
			if fn then
				result = runWithPriority(ImmediateSchedulerPriority, function()
					return fn(a)
				end)
			else
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		end
		-- ROBLOX: finally
		executionContext = prevExecutionContext
		-- Flush the immediate callbacks that were scheduled during this batch.
		-- Note that this will happen even if batchedUpdates is higher up
		-- the stack.
		flushSyncCallbackQueue()
		if not ok then
			error(result)
		end
		return result
	end
end

exports.flushControlled = function(fn: () -> any)
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, BatchedContext)
	if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
		local previousLanePriority = getCurrentUpdateLanePriority()
		-- ROBLOX performance: extract non-throwable call out of try{} to eliminate an anon function
		setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
		local ok, result =
			xpcall(runWithPriority, describeError, ImmediateSchedulerPriority, fn)

		-- finally
		setCurrentUpdateLanePriority(previousLanePriority)

		executionContext = prevExecutionContext
		if executionContext == NoContext then
			-- Flush the immediate callbacks that were scheduled during this batch
			resetRenderTimer()
			flushSyncCallbackQueue()
		end

		if not ok then
			error(result)
		end
	else
		local ok, result =
			xpcall(runWithPriority, describeError, ImmediateSchedulerPriority, fn)
		-- finally
		executionContext = prevExecutionContext
		if executionContext == NoContext then
			-- Flush the immediate callbacks that were scheduled during this batch
			resetRenderTimer()
			flushSyncCallbackQueue()
		end

		if not ok then
			error(result)
		end
	end
end

exports.pushRenderLanes = function(fiber: Fiber, lanes: Lanes)
	pushToStack(subtreeRenderLanesCursor, exports.subtreeRenderLanes, fiber)
	exports.subtreeRenderLanes = mergeLanes(exports.subtreeRenderLanes, lanes)
	workInProgressRootIncludedLanes = mergeLanes(workInProgressRootIncludedLanes, lanes)
end

exports.popRenderLanes = function(fiber: Fiber)
	exports.subtreeRenderLanes = subtreeRenderLanesCursor.current
	popFromStack(subtreeRenderLanesCursor, fiber)
end

mod.prepareFreshStack = function(root: FiberRoot, lanes: Lanes)
	root.finishedWork = nil
	root.finishedLanes = ReactFiberLane.NoLanes

	local timeoutHandle = root.timeoutHandle
	if timeoutHandle ~= ReactFiberHostConfig.noTimeout then
		-- The root previous suspended and scheduled a timeout to commit a fallback
		-- state. Now that we have additional work, cancel the timeout.
		root.timeoutHandle = ReactFiberHostConfig.noTimeout
		-- $FlowFixMe Complains noTimeout is not a TimeoutID, despite the check above
		ReactFiberHostConfig.cancelTimeout(timeoutHandle)
	end

	if workInProgress ~= nil then
		local interruptedWork = workInProgress.return_
		while interruptedWork ~= nil do
			unwindInterruptedWork(interruptedWork)
			interruptedWork = interruptedWork.return_
		end
	end
	workInProgressRoot = root
	workInProgress = ReactFiber.createWorkInProgress(root.current, nil)
	workInProgressRootRenderLanes = lanes
	exports.subtreeRenderLanes = lanes
	workInProgressRootIncludedLanes = lanes
	workInProgressRootExitStatus = RootExitStatus.Incomplete
	workInProgressRootFatalError = nil
	workInProgressRootSkippedLanes(ReactFiberLane.NoLanes)
	workInProgressRootUpdatedLanes = ReactFiberLane.NoLanes
	workInProgressRootPingedLanes = ReactFiberLane.NoLanes

	if ReactFeatureFlags.enableSchedulerTracing then
		spawnedWorkDuringRender = nil
	end

	if __DEV__ then
		ReactStrictModeWarnings.discardPendingWarnings()
	end
end

mod.handleError = function(root, thrownValue): ()
	while true do
		local erroredWork = workInProgress
		-- ROBLOX FIXME Luau: CLI-49835, "Function only returns 1 value, 2 are required"
		local ok, yetAnotherThrownValue = pcall(function()
			-- Reset module-level state that was set during the render phase.
			resetContextDependencies()
			resetHooksAfterThrow()
			resetCurrentDebugFiberInDEV()
			-- TODO: I found and added this missing line while investigating a
			-- separate issue. Write a regression test using string refs.
			ReactCurrentOwner.current = nil

			if erroredWork == nil or erroredWork.return_ == nil then
				-- Expected to be working on a non-root fiber. This is a fatal error
				-- because there's no ancestor that can handle it; the root is
				-- supposed to capture all errors that weren't caught by an error
				-- boundary.
				workInProgressRootExitStatus = RootExitStatus.FatalErrored
				workInProgressRootFatalError = thrownValue
				-- Set `workInProgress` to nil. This represents advancing to the next
				-- sibling, or the parent if there are no siblings. But since the root
				-- has no siblings nor a parent, we set it to nil. Usually this is
				-- handled by `completeUnitOfWork` or `unwindWork`, but since we're
				-- intentionally not calling those, we need set it here.
				-- TODO: Consider calling `unwindWork` to pop the contexts.
				workInProgress = nil
				-- ROBLOX FIXME: THIS IS A BUG, WE SHOULD BAIL ON THE OUTER FUNCTION -- NOT THE PCALL!
				return
			end

			-- ROBLOX Luau FIXME: Luau doesn't narrow based on the erroredWork == nil then return above
			if
				ReactFeatureFlags.enableProfilerTimer
				and bit32.band(
						(erroredWork :: Fiber).mode,
						ReactTypeOfMode.ProfileMode
					)
					~= 0
			then
				-- Record the time spent rendering before an error was thrown. This
				-- avoids inaccurate Profiler durations in the case of a
				-- suspended render.
				ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(
					erroredWork :: Fiber,
					true
				)
			end

			-- ROBLOX deviation, we pass in onUncaughtError and renderDidError here since throwException can't call them due to a require cycle
			throwException(
				root,
				(erroredWork :: Fiber).return_,
				erroredWork :: Fiber,
				thrownValue,
				workInProgressRootRenderLanes,
				exports.onUncaughtError,
				exports.renderDidError
			)
			mod.completeUnitOfWork(erroredWork)
		end)
		if not ok then
			-- Something in the return path also threw.
			thrownValue = yetAnotherThrownValue
			if workInProgress == erroredWork and erroredWork ~= nil then
				-- If this boundary has already errored, then we had trouble processing
				-- the error. Bubble it to the next boundary.
				erroredWork = erroredWork.return_
				workInProgress = erroredWork
			else
				erroredWork = workInProgress
			end
			continue
		end
		-- Return to the normal work loop.
		return
	end
end

mod.pushDispatcher = function()
	local prevDispatcher = ReactCurrentDispatcher.current

	-- ROBLOX deviation: lazy init of ContextOnlyDispatcher wrapped in a function
	ReactCurrentDispatcher.current = ContextOnlyDispatcher()
	if prevDispatcher == nil then
		-- The React isomorphic package does not include a default dispatcher.
		-- Instead the first renderer will lazily attach one, in order to give
		-- nicer error messages.

		-- ROBLOX deviation: lazy init of ContextOnlyDispatcher wrapped in a function
		return ContextOnlyDispatcher()
	else
		return prevDispatcher
	end
end

mod.popDispatcher = function(prevDispatcher)
	ReactCurrentDispatcher.current = prevDispatcher
end

mod.pushInteractions = function(root)
	if ReactFeatureFlags.enableSchedulerTracing then
		local prevInteractions: Set<Interaction>? = __interactionsRef.current
		__interactionsRef.current = root.memoizedInteractions
		return prevInteractions
	end
	return nil
end

mod.popInteractions = function(prevInteractions)
	if ReactFeatureFlags.enableSchedulerTracing then
		__interactionsRef.current = prevInteractions
	end
end

exports.markCommitTimeOfFallback = function(): ()
	globalMostRecentFallbackTime = now()
end

exports.markSkippedUpdateLanes = function(lane: Lane | Lanes): ()
	ReactFiberWorkInProgress.markSkippedUpdateLanes(lane)
end

exports.renderDidSuspend = function(): ()
	if workInProgressRootExitStatus == RootExitStatus.Incomplete then
		workInProgressRootExitStatus = RootExitStatus.Suspended
	end
end

exports.renderDidSuspendDelayIfPossible = function(): ()
	if
		workInProgressRootExitStatus == RootExitStatus.Incomplete
		or workInProgressRootExitStatus == RootExitStatus.Suspended
	then
		workInProgressRootExitStatus = RootExitStatus.SuspendedWithDelay
	end

	-- Check if there are updates that we skipped tree that might have unblocked
	-- this render.
	if
		workInProgressRoot ~= nil
		and (
			includesNonIdleWork(workInProgressRootSkippedLanes())
			or includesNonIdleWork(workInProgressRootUpdatedLanes)
		)
	then
		-- Mark the current render as suspended so that we switch to working on
		-- the updates that were skipped. Usually we only suspend at the end of
		-- the render phase.
		-- TODO: We should probably always mark the root as suspended immediately
		-- (inside this function), since by suspending at the end of the render
		-- phase introduces a potential mistake where we suspend lanes that were
		-- pinged or updated while we were rendering.
		mod.markRootSuspended(workInProgressRoot, workInProgressRootRenderLanes)
	end
end

exports.renderDidError = function()
	if workInProgressRootExitStatus ~= RootExitStatus.Completed then
		workInProgressRootExitStatus = RootExitStatus.Errored
	end
end

-- Called during render to determine if anything has suspended.
-- Returns false if we're not sure.
exports.renderHasNotSuspendedYet = function(): boolean
	-- If something errored or completed, we can't really be sure,
	-- so those are false.
	return workInProgressRootExitStatus == RootExitStatus.Incomplete
end

mod.renderRootSync = function(root: FiberRoot, lanes: Lanes)
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, RenderContext)
	local prevDispatcher = mod.pushDispatcher()

	-- If the root or lanes have changed, throw out the existing stack
	-- and prepare a fresh one. Otherwise we'll continue where we left off.
	if workInProgressRoot ~= root or workInProgressRootRenderLanes ~= lanes then
		mod.prepareFreshStack(root, lanes)
		mod.startWorkOnPendingInteractions(root, lanes)
	end

	local prevInteractions = mod.pushInteractions(root)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markRenderStarted(lanes)
	end

	while true do
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, thrownValue
		if not __YOLO__ then
			ok, thrownValue = xpcall(mod.workLoopSync, describeError)
		else
			ok = true
			mod.workLoopSync()
		end

		if not ok then
			mod.handleError(root, thrownValue)
		else
			break
		end
	end
	resetContextDependencies()
	if ReactFeatureFlags.enableSchedulerTracing then
		mod.popInteractions(prevInteractions)
	end

	executionContext = prevExecutionContext
	mod.popDispatcher(prevDispatcher)

	if workInProgress ~= nil then
		-- This is a sync render, so we should have finished the whole tree.
		invariant(
			false,
[[Cannot commit an incomplete root. This error is likely caused by a bug in React. Please file an issue.]]		

)
	end

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStopped()
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markRenderStopped()
	end

	-- Set this to nil to indicate there's no in-progress render.
	workInProgressRoot = nil
	workInProgressRootRenderLanes = ReactFiberLane.NoLanes

	return workInProgressRootExitStatus
end

-- The work loop is an extremely hot path. Tell Closure not to inline it.
--[[* @noinline ]]
mod.workLoopSync = function()
	-- Already timed out, so perform work without checking if we need to yield.
	while workInProgress ~= nil do
		mod.performUnitOfWork(workInProgress)
	end
end

mod.renderRootConcurrent = function(root: FiberRoot, lanes: Lanes)
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, RenderContext)
	local prevDispatcher = mod.pushDispatcher()

	-- If the root or lanes have changed, throw out the existing stack
	-- and prepare a fresh one. Otherwise we'll continue where we left off.
	if workInProgressRoot ~= root or workInProgressRootRenderLanes ~= lanes then
		resetRenderTimer()
		mod.prepareFreshStack(root, lanes)
		mod.startWorkOnPendingInteractions(root, lanes)
	end

	local prevInteractions = mod.pushInteractions(root)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markRenderStarted(lanes)
	end

	while true do
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, thrownValue
		if not __YOLO__ then
			-- ROBLOX deviation: when converting `try` to `pcall`, we can't use break inside it
			ok, thrownValue = xpcall(mod.workLoopConcurrent, describeError)
			if ok then
				thrownValue = "break"
			end
		else
			ok = true
			thrownValue = "break"
			mod.workLoopConcurrent()
		end

		if thrownValue == "break" then
			break
		end
		if not ok then
			mod.handleError(root, thrownValue)
		end
	end
	resetContextDependencies()
	if ReactFeatureFlags.enableSchedulerTracing then
		mod.popInteractions(prevInteractions)
	end

	mod.popDispatcher(prevDispatcher)
	executionContext = prevExecutionContext

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStopped()
		end
	end

	-- Check if the tree has completed.
	if workInProgress ~= nil then
		-- Still work remaining.
		if enableSchedulingProfiler then
			SchedulingProfiler.markRenderYielded()
		end
		return RootExitStatus.Incomplete
	else
		-- Completed the tree.
		if enableSchedulingProfiler then
			SchedulingProfiler.markRenderStopped()
		end

		-- Set this to nil to indicate there's no in-progress render.
		workInProgressRoot = nil
		workInProgressRootRenderLanes = ReactFiberLane.NoLanes

		-- Return the final exit status.
		return workInProgressRootExitStatus
	end
end

--[[* @noinline ]]
mod.workLoopConcurrent = function()
	-- Perform work until Scheduler asks us to yield
	while workInProgress ~= nil and not shouldYield() do
		mod.performUnitOfWork(workInProgress)
	end
end

mod.performUnitOfWork = function(unitOfWork: Fiber): ()
	-- ROBLOX deviation: RobloxReactProfiling
	local profileRunning = RobloxReactProfiling.profileUnitOfWorkBefore(unitOfWork)

	-- The current, flushed, state of this fiber is the alternate. Ideally
	-- nothing should rely on this, but relying on it here means that we don't
	-- need an additional field on the work in progress.
	local current = unitOfWork.alternate
	setCurrentDebugFiberInDEV(unitOfWork)

	local next_
	if
		ReactFeatureFlags.enableProfilerTimer
		and bit32.band(unitOfWork.mode, ReactTypeOfMode.ProfileMode)
			~= ReactTypeOfMode.NoMode
	then
		ReactProfilerTimer.startProfilerTimer(unitOfWork)
		next_ = mod.beginWork(current, unitOfWork, exports.subtreeRenderLanes)
		ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(unitOfWork, true)
	else
		next_ = mod.beginWork(current, unitOfWork, exports.subtreeRenderLanes)
	end

	resetCurrentDebugFiberInDEV()
	unitOfWork.memoizedProps = unitOfWork.pendingProps
	if next_ == nil then
		-- If this doesn't spawn new work, complete the current work.
		mod.completeUnitOfWork(unitOfWork)
	else
		workInProgress = next_
	end

	ReactCurrentOwner.current = nil

	-- ROBLOX deviation: RobloxReactProfiling
	RobloxReactProfiling.profileUnitOfWorkAfter(profileRunning)
end

mod.completeUnitOfWork = function(unitOfWork: Fiber)
	-- Attempt to complete the current unit of work, then move to the next
	-- sibling. If there are no more siblings, return to the parent fiber.
	local completedWork = unitOfWork
	repeat
		-- The current, flushed, state of this fiber is the alternate. Ideally
		-- nothing should rely on this, but relying on it here means that we don't
		-- need an additional field on the work in progress.
		local current = completedWork.alternate
		local returnFiber = completedWork.return_

		-- Check if the work completed or if something threw.
		if
			bit32.band(completedWork.flags, ReactFiberFlags.Incomplete)
			== ReactFiberFlags.NoFlags
		then
			setCurrentDebugFiberInDEV(completedWork)
			local next_
			if
				not ReactFeatureFlags.enableProfilerTimer
				or bit32.band(completedWork.mode, ReactTypeOfMode.ProfileMode)
					== ReactTypeOfMode.NoMode
			then
				next_ = completeWork(current, completedWork, exports.subtreeRenderLanes)
			else
				ReactProfilerTimer.startProfilerTimer(completedWork)
				next_ = completeWork(current, completedWork, exports.subtreeRenderLanes)
				-- Update render duration assuming we didn't error.
				ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(
					completedWork,
					false
				)
			end
			resetCurrentDebugFiberInDEV()

			if next_ ~= nil then
				-- Completing this fiber spawned new work. Work on that next.
				workInProgress = next_
				return
			end
		else
			-- This fiber did not complete because something threw. Pop values off
			-- the stack without entering the complete phase. If this is a boundary,
			-- capture values if possible.
			local next_ = unwindWork(completedWork, exports.subtreeRenderLanes)

			-- Because this fiber did not complete, don't reset its expiration time.

			if next_ ~= nil then
				-- If completing this work spawned new work, do that next. We'll come
				-- back here again.
				-- Since we're restarting, remove anything that is not a host effect
				-- from the effect tag.
				next_.flags = bit32.band(next_.flags, ReactFiberFlags.HostEffectMask)
				workInProgress = next_
				return
			end

			if
				ReactFeatureFlags.enableProfilerTimer
				and bit32.band(completedWork.mode, ReactTypeOfMode.ProfileMode)
					~= ReactTypeOfMode.NoMode
			then
				-- Record the render duration for the fiber that errored.
				ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(
					completedWork,
					false
				)

				-- Include the time spent working on failed children before continuing.
				-- ROBLOX TODO: actualDuration is nil-able and only populated with enableProfilerTimer. contribute default value upstream.
				local actualDuration = completedWork.actualDuration or 0
				local child = completedWork.child
				while child ~= nil do
					actualDuration += child.actualDuration or 0
					child = child.sibling
				end
				completedWork.actualDuration = actualDuration
			end

			if returnFiber ~= nil then
				-- Mark the parent fiber as incomplete
				returnFiber.flags =
					bit32.bor(returnFiber.flags, ReactFiberFlags.Incomplete)
				returnFiber.subtreeFlags = ReactFiberFlags.NoFlags
				returnFiber.deletions = nil
			end
		end

		local siblingFiber = completedWork.sibling
		if siblingFiber ~= nil then
			-- If there is more work to do in this returnFiber, do that next.
			workInProgress = siblingFiber
			return
		end
		-- Otherwise, return to the parent
		-- ROBLOX Luau FIXME: Luau doesn't understand that completedWork is only nil-able at this point in the control flow
		completedWork = returnFiber :: any
		-- Update the next thing we're working on in case something throws.
		workInProgress = completedWork
	until completedWork == nil

	-- We've reached the root.
	if workInProgressRootExitStatus == RootExitStatus.Incomplete then
		workInProgressRootExitStatus = RootExitStatus.Completed
	end
end

mod.commitRoot = function(root)
	local renderPriorityLevel = getCurrentPriorityLevel()
	runWithPriority(ImmediateSchedulerPriority, function()
		-- ROBLOX deviation: RobloxReactProfiling
		RobloxReactProfiling.profileCommitBefore()
		local ret = mod.commitRootImpl(root, renderPriorityLevel)
		RobloxReactProfiling.profileCommitAfter()
		return ret
	end)
	return nil
end

-- ROBLOX Luau FIXME: Luau doesn't infer root as FiberRoot via the callgraph from ensureRootIsScheduled(root: FiberRoot)
mod.commitRootImpl = function(root: FiberRoot, renderPriorityLevel)
	repeat
		-- `flushPassiveEffects` will call `flushSyncUpdateQueue` at the end, which
		-- means `flushPassiveEffects` will sometimes result in additional
		-- passive effects. So we need to keep flushing in a loop until there are
		-- no more pending effects.
		-- TODO: Might be better if `flushPassiveEffects` did not automatically
		-- flush synchronous work at the end, to avoid factoring hazards like this.
		exports.flushPassiveEffects()
	until rootWithPendingPassiveEffects == nil
	flushRenderPhaseStrictModeWarningsInDEV()

	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Should not already be working."
	)

	-- ROBLOX Luau FIXME: Luau doesn't narrow finishedWork based on the nil guard below
	local finishedWork = root.finishedWork :: Fiber
	local lanes = root.finishedLanes

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logCommitStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markCommitStarted(lanes)
	end

	if finishedWork == nil then
		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logCommitStopped()
			end
		end

		if enableSchedulingProfiler then
			SchedulingProfiler.markCommitStopped()
		end

		return nil
	end
	root.finishedWork = nil
	root.finishedLanes = ReactFiberLane.NoLanes

	invariant(
		finishedWork ~= root.current,
[[Cannot commit the same tree as before. This error is likely caused by a bug in React. Please file an issue.]]	

)

	-- commitRoot never returns a continuation; it always finishes synchronously.
	-- So we can clear these now to allow a new callback to be scheduled.
	root.callbackNode = nil

	-- Update the first and last pending times on this root. The new first
	-- pending time is whatever is left on the root fiber.
	local remainingLanes = mergeLanes(finishedWork.lanes, finishedWork.childLanes)
	markRootFinished(root, remainingLanes)

	-- Clear already finished discrete updates in case that a later call of
	-- `flushDiscreteUpdates` starts a useless render pass which may cancels
	-- a scheduled timeout.
	if rootsWithPendingDiscreteUpdates ~= nil then
		if
			not hasDiscreteLanes(remainingLanes)
			and rootsWithPendingDiscreteUpdates:has(root)
		then
			rootsWithPendingDiscreteUpdates:delete(root)
		end
	end

	if root == workInProgressRoot then
		-- We can reset these now that they are finished.
		workInProgressRoot = nil
		workInProgress = nil
		workInProgressRootRenderLanes = ReactFiberLane.NoLanes
		-- This indicates that the last root we worked on is not the same one that
		-- we're committing now. This most commonly happens when a suspended root
		-- times out.
	
end

	-- Check if there are any effects in the whole tree.
	-- TODO: This is left over from the effect list implementation, where we had
	-- to check for the existence of `firstEffect` to satsify Flow. I think the
	-- only other reason this optimization exists is because it affects profiling.
	-- Reconsider whether this is necessary.
	local subtreeHasEffects = bit32.band(
		finishedWork.subtreeFlags,
		bit32.bor(
			ReactFiberFlags.BeforeMutationMask,
			ReactFiberFlags.MutationMask,
			ReactFiberFlags.LayoutMask,
			ReactFiberFlags.PassiveMask
		)
	) ~= ReactFiberFlags.NoFlags
	local rootHasEffect = bit32.band(
		finishedWork.flags,
		bit32.bor(
			ReactFiberFlags.BeforeMutationMask,
			ReactFiberFlags.MutationMask,
			ReactFiberFlags.LayoutMask,
			ReactFiberFlags.PassiveMask
		)
	) ~= ReactFiberFlags.NoFlags

	if subtreeHasEffects or rootHasEffect then
		local previousLanePriority
		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			previousLanePriority = getCurrentUpdateLanePriority()
			setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
		end

		local prevExecutionContext = executionContext
		executionContext = bit32.bor(executionContext, CommitContext)
		local prevInteractions = mod.pushInteractions(root)

		-- Reset this to nil before calling lifecycles
		ReactCurrentOwner.current = nil

		-- The commit phase is broken into several sub-phases. We do a separate pass
		-- of the effect list for each phase: all mutation effects come before all
		-- layout effects, and so on.

		-- The first phase a "before mutation" phase. We use this phase to read the
		-- state of the host tree right before we mutate it. This is where
		-- getSnapshotBeforeUpdate is called.
		focusedInstanceHandle = ReactFiberHostConfig.prepareForCommit(root.containerInfo)
		shouldFireAfterActiveInstanceBlur = false

		mod.commitBeforeMutationEffects(finishedWork)

		-- We no longer need to track the active instance fiber
		focusedInstanceHandle = nil

		if ReactFeatureFlags.enableProfilerTimer then
			-- Mark the current commit time to be shared by all Profilers in this
			-- batch. This enables them to be grouped later.
			ReactProfilerTimer.recordCommitTime()
		end

		-- The next phase is the mutation phase, where we mutate the host tree.
		mod.commitMutationEffects(finishedWork, root, renderPriorityLevel)

		if shouldFireAfterActiveInstanceBlur then
			ReactFiberHostConfig.afterActiveInstanceBlur()
		end
		ReactFiberHostConfig.resetAfterCommit(root.containerInfo)

		-- The work-in-progress tree is now the current tree. This must come after
		-- the mutation phase, so that the previous tree is still current during
		-- componentWillUnmount, but before the layout phase, so that the finished
		-- work is current during componentDidMount/Update.
		root.current = finishedWork

		-- The next phase is the layout phase, where we call effects that read
		-- the host tree after it's been mutated. The idiomatic use case for this is
		-- layout, but class component lifecycles also fire here for legacy reasons.
		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logLayoutEffectsStarted(lanes)
			end
		end
		if enableSchedulingProfiler then
			SchedulingProfiler.markLayoutEffectsStarted(lanes)
		end

		if __DEV__ then
			setCurrentDebugFiberInDEV(finishedWork)
			invokeGuardedCallback(
				nil,
				recursivelyCommitLayoutEffects,
				nil,
				finishedWork,
				root,
				-- ROBLOX deviation: pass in this function to avoid dependency cycle
				exports.captureCommitPhaseError,
				exports.schedulePassiveEffectCallback
			)
			if hasCaughtError() then
				local err = clearCaughtError()
				captureCommitPhaseErrorOnRoot(finishedWork, finishedWork, err)
			end
			resetCurrentDebugFiberInDEV()
		else
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not __YOLO__ then
				-- ROBLOX deviation: pass in captureCommitPhaseError and schedulePassiveEffectCallback to avoid dependency cycle
				ok, result = xpcall(
					recursivelyCommitLayoutEffects,
					describeError,
					finishedWork,
					root,
					exports.captureCommitPhaseError,
					exports.schedulePassiveEffectCallback
				)
			else
				ok = true
				recursivelyCommitLayoutEffects(
					finishedWork,
					root,
					exports.captureCommitPhaseError,
					exports.schedulePassiveEffectCallback
				)
			end

			if not ok then
				captureCommitPhaseErrorOnRoot(finishedWork, finishedWork, result)
			end
		end

		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logLayoutEffectsStopped()
			end
		end
		if enableSchedulingProfiler then
			SchedulingProfiler.markLayoutEffectsStopped()
		end

		-- If there are pending passive effects, schedule a callback to process them.
		if
			bit32.band(finishedWork.subtreeFlags, ReactFiberFlags.PassiveMask)
				~= ReactFiberFlags.NoFlags
			or bit32.band(finishedWork.flags, ReactFiberFlags.PassiveMask)
				~= ReactFiberFlags.NoFlags
		then
			if not rootDoesHavePassiveEffects then
				rootDoesHavePassiveEffects = true
				scheduleCallback(NormalSchedulerPriority, function()
					exports.flushPassiveEffects()
					return nil
				end)
			end
		end

		-- Tell Scheduler to yield at the end of the frame, so the browser has an
		-- opportunity to paint.
		requestPaint()

		if ReactFeatureFlags.enableSchedulerTracing then
			mod.popInteractions(prevInteractions)
		end
		executionContext = prevExecutionContext

		if
			ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
			and previousLanePriority ~= nil
		then
			-- Reset the priority to the previous non-sync value.
			setCurrentUpdateLanePriority(previousLanePriority)
		end
	else
		-- No effects.
		root.current = finishedWork
		-- Measure these anyway so the flamegraph explicitly shows that there were
		-- no effects.
		-- TODO: Maybe there's a better way to report this.
		if ReactFeatureFlags.enableProfilerTimer then
			ReactProfilerTimer.recordCommitTime()
		end
	end

	local rootDidHavePassiveEffects = rootDoesHavePassiveEffects

	if rootDoesHavePassiveEffects then
		-- This commit has passive effects. Stash a reference to them. But don't
		-- schedule a callback until after flushing layout work.
		rootDoesHavePassiveEffects = false
		rootWithPendingPassiveEffects = root
		pendingPassiveEffectsLanes = lanes
		pendingPassiveEffectsRenderPriority = renderPriorityLevel
	end

	-- Read this again, since an effect might have updated it
	remainingLanes = root.pendingLanes

	-- Check if there's remaining work on this root
	if remainingLanes ~= ReactFiberLane.NoLanes then
		if ReactFeatureFlags.enableSchedulerTracing then
			if spawnedWorkDuringRender ~= nil then
				local expirationTimes = spawnedWorkDuringRender
				spawnedWorkDuringRender = nil
				for i = 1, #expirationTimes do
					scheduleInteractions(
						root,
						expirationTimes[i],
						root.memoizedInteractions
					)
				end
			end
			mod.schedulePendingInteractions(root, remainingLanes)
		end
	else
		-- If there's no remaining work, we can clear the set of already failed
		-- error boundaries.
		legacyErrorBoundariesThatAlreadyFailed = nil
	end

	if __DEV__ and enableDoubleInvokingEffects then
		if not rootDidHavePassiveEffects then
			commitDoubleInvokeEffectsInDEV(root.current, false)
		end
	end

	if ReactFeatureFlags.enableSchedulerTracing then
		if not rootDidHavePassiveEffects then
			-- If there are no passive effects, then we can complete the pending interactions.
			-- Otherwise, we'll wait until after the passive effects are flushed.
			-- Wait to do this until after remaining work has been scheduled,
			-- so that we don't prematurely signal complete for interactions when there's e.g. hidden work.
			mod.finishPendingInteractions(root, lanes)
		end
	end

	if remainingLanes == SyncLane then
		-- Count the number of times the root synchronously re-renders without
		-- finishing. If there are too many, it indicates an infinite update loop.
		if root == rootWithNestedUpdates then
			nestedUpdateCount += 1
		else
			nestedUpdateCount = 0
			rootWithNestedUpdates = root
		end
	else
		nestedUpdateCount = 0
	end

	onCommitRootDevTools(finishedWork.stateNode, renderPriorityLevel)

	if __DEV__ then
		onCommitRootTestSelector()
	end

	-- Always call this before exiting `commitRoot`, to ensure that any
	-- additional work on this root is scheduled.
	ensureRootIsScheduled(root, now())

	if hasUncaughtError then
		hasUncaughtError = false
		local error_ = firstUncaughtError
		firstUncaughtError = nil
		-- ROBLOX FIXME: we lose the original stack trace when we re-throw this way
		error(error_)
	end

	if bit32.band(executionContext, LegacyUnbatchedContext) ~= NoContext then
		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logCommitStopped()
			end
		end

		if enableSchedulingProfiler then
			SchedulingProfiler.markCommitStopped()
		end

		-- This is a legacy edge case. We just committed the initial mount of
		-- a ReactDOM.render-ed root inside of batchedUpdates. The commit fired
		-- synchronously, but layout updates should be deferred until the end
		-- of the batch.
		return nil
	end

	-- If layout work was scheduled, flush it now.
	flushSyncCallbackQueue()

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logCommitStopped()
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markCommitStopped()
	end

	return nil
end

mod.commitBeforeMutationEffects = function(firstChild: Fiber)
	local fiber = firstChild
	while fiber ~= nil do
		if fiber.deletions ~= nil then
			mod.commitBeforeMutationEffectsDeletions(fiber.deletions)
		end

		if fiber.child ~= nil then
			local primarySubtreeFlags =
				bit32.band(fiber.subtreeFlags, ReactFiberFlags.BeforeMutationMask)
			if primarySubtreeFlags ~= ReactFiberFlags.NoFlags then
				mod.commitBeforeMutationEffects(fiber.child)
			end
		end

		if __DEV__ then
			setCurrentDebugFiberInDEV(fiber)
			invokeGuardedCallback(nil, mod.commitBeforeMutationEffectsImpl, nil, fiber)
			if hasCaughtError() then
				local error_ = clearCaughtError()
				exports.captureCommitPhaseError(fiber, fiber.return_, error_)
			end
			resetCurrentDebugFiberInDEV()
		else
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, error_
			if not __YOLO__ then
				ok, error_ =
					xpcall(mod.commitBeforeMutationEffectsImpl, describeError, fiber)
			else
				ok = true
				mod.commitBeforeMutationEffectsImpl(fiber)
			end

			if not ok then
				exports.captureCommitPhaseError(fiber, fiber.return_, error_)
			end
		end
		-- ROBLOX Luau FIXME: Luau doesn't narrow correctly for the while ~= nil pattern
		fiber = fiber.sibling :: Fiber
	end
end

mod.commitBeforeMutationEffectsImpl = function(fiber: Fiber)
	local current = fiber.alternate
	local flags = fiber.flags

	if not shouldFireAfterActiveInstanceBlur and focusedInstanceHandle ~= nil then
		-- Check to see if the focused element was inside of a hidden (Suspense) subtree.
		-- TODO: Move this out of the hot path using a dedicated effect tag.
		if
			fiber.tag == ReactWorkTags.SuspenseComponent
			and ReactFiberCommitWork.isSuspenseBoundaryBeingHidden(current, fiber)
			and doesFiberContain(fiber, focusedInstanceHandle)
		then
			shouldFireAfterActiveInstanceBlur = true
			ReactFiberHostConfig.beforeActiveInstanceBlur()
		end
	end

	if bit32.band(flags, ReactFiberFlags.Snapshot) ~= ReactFiberFlags.NoFlags then
		setCurrentDebugFiberInDEV(fiber)
		commitBeforeMutationEffectOnFiber(current, fiber)
		resetCurrentDebugFiberInDEV()
	end

	if bit32.band(flags, ReactFiberFlags.Passive) ~= ReactFiberFlags.NoFlags then
		-- If there are passive effects, schedule a callback to flush at
		-- the earliest opportunity.
		if not rootDoesHavePassiveEffects then
			rootDoesHavePassiveEffects = true
			scheduleCallback(NormalSchedulerPriority, function()
				exports.flushPassiveEffects()
				return nil
			end)
		end
	end
end

mod.commitBeforeMutationEffectsDeletions = function(deletions: Array<Fiber>)
	for i = 1, #deletions do
		local fiber = deletions[i]

		-- TODO (effects) It would be nice to avoid calling doesFiberContain()
		-- Maybe we can repurpose one of the subtreeFlags positions for this instead?
		-- Use it to store which part of the tree the focused instance is in?
		-- This assumes we can safely determine that instance during the "render" phase.
		if doesFiberContain(fiber, (focusedInstanceHandle :: any) :: Fiber) then
			shouldFireAfterActiveInstanceBlur = true
			ReactFiberHostConfig.beforeActiveInstanceBlur()
		end
	end
end

mod.commitMutationEffects =
	function(firstChild: Fiber, root: FiberRoot, renderPriorityLevel: ReactPriorityLevel)
		local fiber = firstChild
		while fiber ~= nil do
			local deletions = fiber.deletions
			if deletions ~= nil then
				-- ROBLOX performance: React 18 inlines commitMutationEffectsDeletions, pulling that in based on tab switching hot path
				for _, childToDelete in deletions do
					-- ROBLOX FIXME Luau: CLI-49835, "Function only returns 1 value, 2 are required"
					local ok, error_ = xpcall(
						commitDeletion,
						describeError,
						root,
						childToDelete,
						fiber,
						renderPriorityLevel
					)
					if not ok then
						exports.captureCommitPhaseError(childToDelete, fiber, error_)
					end
				end
			end

			if fiber.child ~= nil then
				local mutationFlags =
					bit32.band(fiber.subtreeFlags, ReactFiberFlags.MutationMask)
				if mutationFlags ~= ReactFiberFlags.NoFlags then
					mod.commitMutationEffects(fiber.child, root, renderPriorityLevel)
				end
			end

			if __DEV__ then
				setCurrentDebugFiberInDEV(fiber)
				invokeGuardedCallback(
					nil,
					mod.commitMutationEffectsImpl,
					nil,
					fiber,
					root,
					renderPriorityLevel
				)
				if hasCaughtError() then
					local error_ = clearCaughtError()
					exports.captureCommitPhaseError(fiber, fiber.return_, error_)
				end
				resetCurrentDebugFiberInDEV()
			else
				-- ROBLOX deviation: YOLO flag for disabling pcall
				local ok, result
				if not __YOLO__ then
					ok, result = xpcall(
						mod.commitMutationEffectsImpl,
						describeError,
						fiber,
						root,
						renderPriorityLevel
					)
				else
					ok = true
					mod.commitMutationEffectsImpl(fiber, root, renderPriorityLevel)
				end
				if not ok then
					exports.captureCommitPhaseError(fiber, fiber.return_, result)
				end
			end
			-- ROBLOX Luau FIXME: Luau doesn't understand the while ~= nil construct
			fiber = fiber.sibling :: Fiber
		end
	end

mod.commitMutationEffectsImpl =
	function(fiber: Fiber, root: FiberRoot, renderPriorityLevel)
		local flags = fiber.flags
		-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
		-- if bit32.band(flags, ReactFiberFlags.ContentReset) ~= 0 then
		--   unimplemented("commitResetTextContent")
		-- commitResetTextContent(fiber)
		-- end

		if bit32.band(flags, ReactFiberFlags.Ref) ~= 0 then
			local current = fiber.alternate
			if current ~= nil then
				commitDetachRef(current)
			end
			-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
			-- if ReactFeatureFlags.enableScopeAPI then
			--   -- TODO: This is a temporary solution that allowed us to transition away from React Flare on www.
			--   if fiber.tag == ReactWorkTags.ScopeComponent then
			--     commitAttachRef(fiber)
			--   end
			-- end
		end

		-- The following switch statement is only concerned about placement,
		-- updates, and deletions. To avoid needing to add a case for every possible
		-- bitmap value, we remove the secondary effects from the effect tag and
		-- switch on that value.
		local primaryFlags = bit32.band(
			flags,
			bit32.bor(
				ReactFiberFlags.Placement,
				ReactFiberFlags.Update,
				ReactFiberFlags.Hydrating
			)
		)
		if primaryFlags == ReactFiberFlags.Placement then
			commitPlacement(fiber)
			-- Clear the "placement" from effect tag so that we know that this is
			-- inserted, before any life-cycles like componentDidMount gets called.
			-- TODO: findDOMNode doesn't rely on this any more but isMounted does
			-- and isMounted is deprecated anyway so we should be able to kill this.
			fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Placement))
		elseif primaryFlags == ReactFiberFlags.PlacementAndUpdate then
			-- Placement
			commitPlacement(fiber)
			-- Clear the "placement" from effect tag so that we know that this is
			-- inserted, before any life-cycles like componentDidMount gets called.
			fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Placement))

			-- Update
			local current = fiber.alternate
			commitWork(current, fiber)
		-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
		-- elseif primaryFlags == ReactFiberFlags.Hydrating then
		--   fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Hydrating))
		-- elseif primaryFlags == ReactFiberFlags.HydratingAndUpdate then
		--   fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Hydrating))
		--   -- Update
		--   local current = fiber.alternate
		--   commitWork(current, fiber)
		elseif primaryFlags == ReactFiberFlags.Update then
			local current = fiber.alternate
			commitWork(current, fiber)
		end
	end

mod.commitMutationEffectsDeletions =
	function(deletions: Array<Fiber>, fiber: Fiber, root: FiberRoot, renderPriorityLevel)
		-- ROBLOX performance: align to React 18, which ditches the __DEV__ branch and use of invokeGuardedCallback
		for _, childToDelete in deletions do
			-- ROBLOX FIXME Luau: CLI-49835, "Function only returns 1 value, 2 are required"
			local ok, error_ = xpcall(
				commitDeletion,
				describeError,
				root,
				childToDelete,
				fiber,
				renderPriorityLevel
			)
			if not ok then
				exports.captureCommitPhaseError(childToDelete, fiber, error_)
			end
		end
	end

exports.schedulePassiveEffectCallback = function()
	if not rootDoesHavePassiveEffects then
		rootDoesHavePassiveEffects = true
		scheduleCallback(NormalSchedulerPriority, function()
			exports.flushPassiveEffects()
			return nil
		end)
	end
end

-- deviation: Pre-declare functions
local flushPassiveEffectsImpl
exports.flushPassiveEffects = function(): boolean
	-- Returns whether passive effects were flushed.
	if pendingPassiveEffectsRenderPriority ~= NoSchedulerPriority then
		local priorityLevel = if pendingPassiveEffectsRenderPriority
				> NormalSchedulerPriority
			then NormalSchedulerPriority
			else pendingPassiveEffectsRenderPriority
		pendingPassiveEffectsRenderPriority = NoSchedulerPriority
		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			local previousLanePriority = getCurrentUpdateLanePriority()

			-- ROBLOX performance: extract non-throwable function from try{} to remove need for anon function
			setCurrentUpdateLanePriority(schedulerPriorityToLanePriority(priorityLevel))
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not __YOLO__ then
				ok, result = xpcall(
					runWithPriority,
					describeError,
					priorityLevel,
					flushPassiveEffectsImpl
				)
			else
				ok = true
				setCurrentUpdateLanePriority(
					schedulerPriorityToLanePriority(priorityLevel)
				)
				result = runWithPriority(priorityLevel, flushPassiveEffectsImpl)
			end

			-- finally
			setCurrentUpdateLanePriority(previousLanePriority)

			if not ok then
				error(result)
			end
			return result
		else
			return runWithPriority(priorityLevel, flushPassiveEffectsImpl)
		end
	end
	return false
end

flushPassiveMountEffects = function(root, firstChild: Fiber): ()
	local fiber = firstChild
	while fiber ~= nil do
		local prevProfilerOnStack 		
if
			ReactFeatureFlags.enableProfilerTimer
			and ReactFeatureFlags.enableProfilerCommitHooks
		then
			if fiber.tag == ReactWorkTags.Profiler then
				prevProfilerOnStack = nearestProfilerOnStack
				nearestProfilerOnStack = fiber
			end
		end

		local primarySubtreeFlags =
			bit32.band(fiber.subtreeFlags, ReactFiberFlags.PassiveMask)

		if fiber.child ~= nil and primarySubtreeFlags ~= ReactFiberFlags.NoFlags then
			flushPassiveMountEffects(root, fiber.child)
		end

		if
			bit32.band(fiber.flags, ReactFiberFlags.Passive) ~= ReactFiberFlags.NoFlags
		then
			if __DEV__ then
				setCurrentDebugFiberInDEV(fiber)
				invokeGuardedCallback(nil, commitPassiveMountOnFiber, nil, root, fiber)
				if hasCaughtError() then
					local error_ = clearCaughtError()
					exports.captureCommitPhaseError(fiber, fiber.return_, error_)
				end
				resetCurrentDebugFiberInDEV()
			else
				-- ROBLOX deviation: YOLO flag for disabling pcall
				local ok, error_
				if not __YOLO__ then
					ok, error_ =
						xpcall(commitPassiveMountOnFiber, describeError, root, fiber)
				else
					ok = true
					commitPassiveMountOnFiber(root, fiber)
				end

				if not ok then
					exports.captureCommitPhaseError(fiber, fiber.return_, error_)
				end
			end
		end

		if
			ReactFeatureFlags.enableProfilerTimer
			and ReactFeatureFlags.enableProfilerCommitHooks
		then
			if fiber.tag == ReactWorkTags.Profiler then
				-- Bubble times to the next nearest ancestor Profiler.
				-- After we process that Profiler, we'll bubble further up.
				if prevProfilerOnStack ~= nil then
					prevProfilerOnStack.stateNode.passiveEffectDuration += fiber.stateNode.passiveEffectDuration
				end

				nearestProfilerOnStack = prevProfilerOnStack
			end
		end

		-- ROBLOX Luau FIXME: Luau doesn't understand the loop ~= nil construct
		fiber = fiber.sibling :: Fiber
	end
end

local function flushPassiveUnmountEffects(firstChild: Fiber): ()
	local fiber = firstChild
	while fiber ~= nil do
		local deletions = fiber.deletions
		if deletions ~= nil then
			for i = 1, #deletions do
				local fiberToDelete = deletions[i]
				mod.flushPassiveUnmountEffectsInsideOfDeletedTree(fiberToDelete, fiber)

				-- Now that passive effects have been processed, it's safe to detach lingering pointers.
				mod.detachFiberAfterEffects(fiberToDelete)
			end
		end

		local child = fiber.child
		if child ~= nil then
			-- If any children have passive effects then traverse the subtree.
			-- Note that this requires checking subtreeFlags of the current Fiber,
			-- rather than the subtreeFlags/effectsTag of the first child,
			-- since that would not cover passive effects in siblings.
			local passiveFlags =
				bit32.band(fiber.subtreeFlags, ReactFiberFlags.PassiveMask)
			if passiveFlags ~= ReactFiberFlags.NoFlags then
				flushPassiveUnmountEffects(child)
			end
		end

		local primaryFlags = bit32.band(fiber.flags, ReactFiberFlags.Passive)
		if primaryFlags ~= ReactFiberFlags.NoFlags then
			setCurrentDebugFiberInDEV(fiber)
			commitPassiveUnmountOnFiber(fiber)
			resetCurrentDebugFiberInDEV()
		end

		-- ROBLOX FIXME Luau: Luau doesn't understand the loop ~= nil construct
		fiber = fiber.sibling :: Fiber
	end
end

mod.flushPassiveUnmountEffectsInsideOfDeletedTree =
	function(fiberToDelete: Fiber, nearestMountedAncestor: Fiber)
		if
			bit32.band(fiberToDelete.subtreeFlags, ReactFiberFlags.PassiveStatic)
			~= ReactFiberFlags.NoFlags
		then
			-- If any children have passive effects then traverse the subtree.
			-- Note that this requires checking subtreeFlags of the current Fiber,
			-- rather than the subtreeFlags/effectsTag of the first child,
			-- since that would not cover passive effects in siblings.
			local child = fiberToDelete.child
			while child ~= nil do
				mod.flushPassiveUnmountEffectsInsideOfDeletedTree(
					child,
					nearestMountedAncestor
				)
				child = child.sibling
			end
		end

		if
			bit32.band(fiberToDelete.flags, ReactFiberFlags.PassiveStatic)
			~= ReactFiberFlags.NoFlags
		then
			setCurrentDebugFiberInDEV(fiberToDelete)
			commitPassiveUnmountInsideDeletedTreeOnFiber(
				fiberToDelete,
				nearestMountedAncestor
			)
			resetCurrentDebugFiberInDEV()
		end
	end

flushPassiveEffectsImpl = function()
	if rootWithPendingPassiveEffects == nil then
		return false
	end

	-- ROBLOX Luau FIXME: Luau doesn't narrow to non-nil with the guard above
	local root = rootWithPendingPassiveEffects :: FiberRoot
	local lanes = pendingPassiveEffectsLanes
	rootWithPendingPassiveEffects = nil
	pendingPassiveEffectsLanes = ReactFiberLane.NoLanes

	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Cannot flush passive effects while already rendering."
	)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logPassiveEffectsStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markPassiveEffectsStarted(lanes)
	end

	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, CommitContext)
	local prevInteractions = mod.pushInteractions(root)

	-- It's important that ALL pending passive effect destroy functions are called
	-- before ANY passive effect create functions are called.
	-- Otherwise effects in sibling components might interfere with each other.
	-- e.g. a destroy function in one component may unintentionally override a ref
	-- value set by a create function in another component.
	-- Layout effects have the same constraint.
	flushPassiveUnmountEffects(root.current)
	flushPassiveMountEffects(root, root.current)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logPassiveEffectsStopped()
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markPassiveEffectsStopped()
	end

	if __DEV__ and enableDoubleInvokingEffects then
		commitDoubleInvokeEffectsInDEV(root.current, true)
	end

	if ReactFeatureFlags.enableSchedulerTracing then
		mod.popInteractions(prevInteractions)
		mod.finishPendingInteractions(root, lanes)
	end

	executionContext = prevExecutionContext

	flushSyncCallbackQueue()

	-- If additional passive effects were scheduled, increment a counter. If this
	-- exceeds the limit, we'll fire a warning.
	if rootWithPendingPassiveEffects == nil then
		nestedPassiveUpdateCount = 0
	else
		nestedPassiveUpdateCount = nestedPassiveUpdateCount + 1
	end

	return true
end

exports.isAlreadyFailedLegacyErrorBoundary = function(instance): boolean
	return
		legacyErrorBoundariesThatAlreadyFailed ~= nil
			and legacyErrorBoundariesThatAlreadyFailed:has(instance)
end

exports.markLegacyErrorBoundaryAsFailed = function(instance)
	if legacyErrorBoundariesThatAlreadyFailed == nil then
		legacyErrorBoundariesThatAlreadyFailed = Set.new({ instance })
	else
		legacyErrorBoundariesThatAlreadyFailed:add(instance)
	end
end

-- ROBLOX TODO: this function and the related fields should be extracted/relocated to break a cycle
local function prepareToThrowUncaughtError(error_)
	if not hasUncaughtError then
		hasUncaughtError = true
		firstUncaughtError = error_
	end
end
exports.onUncaughtError = prepareToThrowUncaughtError

captureCommitPhaseErrorOnRoot = function(rootFiber: Fiber, sourceFiber: Fiber, error_)
	local errorInfo = createCapturedValue(error_, sourceFiber)
	-- ROBLOX deviation: parameterize method onUncaughtError to avoid circular dependency
	local update =
		createRootErrorUpdate(rootFiber, errorInfo, SyncLane, exports.onUncaughtError)
	enqueueUpdate(rootFiber, update)
	local eventTime = exports.requestEventTime()
	local root = mod.markUpdateLaneFromFiberToRoot(rootFiber, SyncLane)
	if root ~= nil then
		markRootUpdated(root, SyncLane, eventTime)
		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, SyncLane)
	end
end

-- exports.captureCommitPhaseError(
--   sourceFiber: Fiber,
--   nearestMountedAncestor: Fiber | nil,
--   error: mixed
-- )
exports.captureCommitPhaseError =
	function(sourceFiber: Fiber, nearestMountedAncestor, error_)
		if sourceFiber.tag == ReactWorkTags.HostRoot then
			-- Error was thrown at the root. There is no parent, so the root
			-- itself should capture it.
			captureCommitPhaseErrorOnRoot(sourceFiber, sourceFiber, error_)
			return
		end

		local fiber 		
if skipUnmountedBoundaries then
			fiber = nearestMountedAncestor
		else
			fiber = sourceFiber.return_
		end

		while fiber ~= nil do
			if fiber.tag == ReactWorkTags.HostRoot then
				captureCommitPhaseErrorOnRoot(fiber, sourceFiber, error_)
				return
			else
				if fiber.tag == ReactWorkTags.ClassComponent then
					local ctor = fiber.type
					local instance = fiber.stateNode
					if
						typeof(ctor.getDerivedStateFromError) == "function"
						or (
							typeof(instance.componentDidCatch) == "function"
							and not exports.isAlreadyFailedLegacyErrorBoundary(instance)
						)
					then
						local errorInfo = createCapturedValue(error_, sourceFiber)
						local update = createClassErrorUpdate(fiber, errorInfo, SyncLane)
						enqueueUpdate(fiber, update)
						local eventTime = exports.requestEventTime()
						local root = mod.markUpdateLaneFromFiberToRoot(fiber, SyncLane)
						if root ~= nil then
							markRootUpdated(root, SyncLane, eventTime)
							ensureRootIsScheduled(root, eventTime)
							mod.schedulePendingInteractions(root, SyncLane)
						end
						return
					end
				end
				fiber = fiber.return_
			end
		end
	end

exports.pingSuspendedRoot =
	function(root: FiberRoot, wakeable: Wakeable, pingedLanes: Lanes)
		local pingCache = root.pingCache
		if pingCache ~= nil then
			-- The wakeable resolved, so we no longer need to memoize, because it will
			-- never be thrown again.
			pingCache[wakeable] = nil
		end

		local eventTime = exports.requestEventTime()
		markRootPinged(root, pingedLanes, eventTime)

		if
			workInProgressRoot == root
			and isSubsetOfLanes(workInProgressRootRenderLanes, pingedLanes)
		then
			-- Received a ping at the same priority level at which we're currently
			-- rendering. We might want to restart this render. This should mirror
			-- the logic of whether or not a root suspends once it completes.

			-- TODO: If we're rendering sync either due to Sync, Batched or expired,
			-- we should probably never restart.

			-- If we're suspended with delay, or if it's a retry, we'll always suspend
			-- so we can always restart.
			if
				workInProgressRootExitStatus == RootExitStatus.SuspendedWithDelay
				or workInProgressRootExitStatus == RootExitStatus.Suspended
					and includesOnlyRetries(workInProgressRootRenderLanes)
					and now() - globalMostRecentFallbackTime < FALLBACK_THROTTLE_MS
			then
				-- Restart from the root.
				mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
			else
				-- Even though we can't restart right now, we might get an
				-- opportunity later. So we mark this render as having a ping.
				workInProgressRootPingedLanes =
					mergeLanes(workInProgressRootPingedLanes, pingedLanes)
			end
		end

		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, pingedLanes)
	end

function retryTimedOutBoundary(boundaryFiber: Fiber, retryLane: Lane)
	-- The boundary fiber (a Suspense component or SuspenseList component)
	-- previously was rendered in its fallback state. One of the promises that
	-- suspended it has resolved, which means at least part of the tree was
	-- likely unblocked. Try rendering again, at a new expiration time.
	if retryLane == ReactFiberLane.NoLane then
		retryLane = requestRetryLane(boundaryFiber)
	end
	-- TODO: Special case idle priority?
	local eventTime = exports.requestEventTime()
	local root = mod.markUpdateLaneFromFiberToRoot(boundaryFiber, retryLane)
	if root ~= nil then
		markRootUpdated(root, retryLane, eventTime)
		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, retryLane)
	end
end

-- exports.retryDehydratedSuspenseBoundary(boundaryFiber: Fiber)
--   local suspenseState: nil | SuspenseState = boundaryFiber.memoizedState
--   local retryLane = NoLane
--   if suspenseState ~= nil)
--     retryLane = suspenseState.retryLane
--   end
--   retryTimedOutBoundary(boundaryFiber, retryLane)
-- end

exports.resolveRetryWakeable = function(boundaryFiber: Fiber, wakeable: Wakeable)
	local retryLane = ReactFiberLane.NoLane -- Default
	local retryCache -- : WeakSet<Wakeable> | Set<Wakeable> | nil
	-- ROBLOX performance: avoid always-false comapare
	-- if ReactFeatureFlags.enableSuspenseServerRenderer then
	--   if boundaryFiber.tag == ReactWorkTags.SuspenseComponent then
	--       retryCache = boundaryFiber.stateNode
	--       local suspenseState: nil | SuspenseState = boundaryFiber.memoizedState
	--       if suspenseState ~= nil then
	--         -- ROBLOX TODO: Remove Luau narrowing workaround
	--         retryLane = (suspenseState :: SuspenseState).retryLane
	--       end
	--     elseif boundaryFiber.tag == ReactWorkTags.SuspenseListComponent then
	--       retryCache = boundaryFiber.stateNode
	--     else
	--       invariant(
	--         false,
	--         'Pinged unknown suspense boundary type. ' ..
	--           'This is probably a bug in React.'
	--       )
	--   end
	-- else
	retryCache = boundaryFiber.stateNode
	-- end

	if retryCache ~= nil then
		-- The wakeable resolved, so we no longer need to memoize, because it will
		-- never be thrown again.
		retryCache:delete(wakeable)
	end

	retryTimedOutBoundary(boundaryFiber, retryLane)
end

-- Computes the next Just Noticeable Difference (JND) boundary.
-- The theory is that a person can't tell the difference between small differences in time.
-- Therefore, if we wait a bit longer than necessary that won't translate to a noticeable
-- difference in the experience. However, waiting for longer might mean that we can avoid
-- showing an intermediate loading state. The longer we have already waited, the harder it
-- is to tell small differences in time. Therefore, the longer we've already waited,
-- the longer we can wait additionally. At some point we have to give up though.
-- We pick a train model where the next boundary commits at a consistent schedule.
-- These particular numbers are vague estimates. We expect to adjust them based on research.
-- ROBLOX Luau FIXME: Luau needs an explicit number annotation here, but should infer: CLI-49832
function jnd(timeElapsed: number): number
	if timeElapsed < 120 then
		return 120
	elseif timeElapsed < 480 then
		return 480
	elseif timeElapsed < 1080 then
		return 1080
	elseif timeElapsed < 1920 then
		return 1920
	elseif timeElapsed < 3000 then
		return 3000
	elseif timeElapsed < 4320 then
		return 4320
	else
		return math.ceil(timeElapsed / 1960) * 1960
	end
end

mod.checkForNestedUpdates = function()
	if nestedUpdateCount > NESTED_UPDATE_LIMIT then
		nestedUpdateCount = 0
		rootWithNestedUpdates = nil
		invariant(
			false,
[[Maximum update depth exceeded. This can happen when a component repeatedly calls setState inside componentWillUpdate or componentDidUpdate. React limits the number of nested updates to prevent infinite loops.]]		



)
	end

	if __DEV__ then
		if nestedPassiveUpdateCount > NESTED_PASSIVE_UPDATE_LIMIT then
			nestedPassiveUpdateCount = 0
			console.error(
[[Maximum update depth exceeded. This can happen when a component calls setState inside useEffect, but useEffect either doesn't have a dependency array, or one of the dependencies changes on every render.]]			



)
		end
	end
end

function flushRenderPhaseStrictModeWarningsInDEV()
	if __DEV__ then
		ReactStrictModeWarnings.flushLegacyContextWarning()

		if ReactFeatureFlags.warnAboutDeprecatedLifecycles then
			ReactStrictModeWarnings.flushPendingUnsafeLifecycleWarnings()
		end
	end
end

function commitDoubleInvokeEffectsInDEV(fiber: Fiber, hasPassiveEffects: boolean)
	if __DEV__ and enableDoubleInvokingEffects then
		setCurrentDebugFiberInDEV(fiber)
		invokeEffectsInDev(
			fiber,
			ReactFiberFlags.MountLayoutDev,
			invokeLayoutEffectUnmountInDEV
		)
		if hasPassiveEffects then
			invokeEffectsInDev(
				fiber,
				ReactFiberFlags.MountPassiveDev,
				invokePassiveEffectUnmountInDEV
			)
		end

		invokeEffectsInDev(
			fiber,
			ReactFiberFlags.MountLayoutDev,
			invokeLayoutEffectMountInDEV
		)
		if hasPassiveEffects then
			invokeEffectsInDev(
				fiber,
				ReactFiberFlags.MountPassiveDev,
				invokePassiveEffectMountInDEV
			)
		end
		resetCurrentDebugFiberInDEV()
	end
end

function invokeEffectsInDev(
	firstChild: Fiber,
	fiberFlags: Flags,
	invokeEffectFn: (fiber: Fiber) -> ()
): ()
	if __DEV__ and enableDoubleInvokingEffects then
		local fiber = firstChild
		while fiber ~= nil do
			if fiber.child ~= nil then
				local primarySubtreeFlag = bit32.band(fiber.subtreeFlags, fiberFlags)
				if primarySubtreeFlag ~= ReactFiberFlags.NoFlags then
					invokeEffectsInDev(fiber.child, fiberFlags, invokeEffectFn)
				end
			end

			if bit32.band(fiber.flags, fiberFlags) ~= ReactFiberFlags.NoFlags then
				invokeEffectFn(fiber)
			end
			-- ROBLOX FIXME Luau: Luau doesn't understand the loop ~= nil construct
			fiber = fiber.sibling :: Fiber
		end
	end
end

-- deviation: FIXME restore type Set<string>?, has trouble with narrowing
local didWarnStateUpdateForNotYetMountedComponent: any 
mod.warnAboutUpdateOnNotYetMountedFiberInDEV = function(fiber)
	if __DEV__ then
		if bit32.band(executionContext, RenderContext) ~= NoContext then
			-- We local the other warning about render phase updates deal with this one.
			return
		end

		if
			bit32.band(
				fiber.mode,
				bit32.bor(ReactTypeOfMode.BlockingMode, ReactTypeOfMode.ConcurrentMode)
			) == 0
		then
			return
		end

		local tag = fiber.tag
		if
			tag ~= ReactWorkTags.IndeterminateComponent
			and tag ~= ReactWorkTags.HostRoot
			and tag ~= ReactWorkTags.ClassComponent
			and tag ~= ReactWorkTags.FunctionComponent
			and tag ~= ReactWorkTags.ForwardRef
			and tag ~= ReactWorkTags.MemoComponent
			and tag ~= ReactWorkTags.SimpleMemoComponent
			and tag ~= ReactWorkTags.Block
		then
			-- Only warn for user-defined components, not internal ones like Suspense.
			return
		end

		-- We show the whole stack but dedupe on the top component's name because
		-- the problematic code almost always lies inside that component.
		local componentName = getComponentName(fiber.type) or "ReactComponent"
		if didWarnStateUpdateForNotYetMountedComponent ~= nil then
			if didWarnStateUpdateForNotYetMountedComponent[componentName] then
				return
			end
			didWarnStateUpdateForNotYetMountedComponent[componentName] = true
		else
			-- ROBLOX FIXME? not sure this translation is correct
			didWarnStateUpdateForNotYetMountedComponent = { [componentName] = true }
		end

		local previousFiber = ReactCurrentFiber.current
		local ok, result = pcall(function()
			setCurrentDebugFiberInDEV(fiber)
			console.error(
[[Can't perform a React state update on a component that hasn't mounted yet. This indicates that you have a side-effect in your render function that asynchronously later calls tries to update the component. Move this work to useEffect instead.]]			



)
		end)

		-- finally
		if previousFiber then
			setCurrentDebugFiberInDEV(fiber)
		else
			resetCurrentDebugFiberInDEV()
		end

		if not ok then
			error(result)
		end
	end
end

-- deviation: Declared on the mod table instead of as a local
if __DEV__ and ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback then
	local dummyFiber 	
mod.beginWork = function(current, unitOfWork, lanes)
		-- If a component throws an error, we replay it again in a synchronously
		-- dispatched event, so that the debugger will treat it as an uncaught
		-- error See ReactErrorUtils for more information.

		-- Before entering the begin phase, copy the work-in-progress onto a dummy
		-- fiber. If beginWork throws, we'll use this to reset the state.
		local originalWorkInProgressCopy =
			ReactFiber.assignFiberPropertiesInDEV(dummyFiber, unitOfWork)
		local ok, result =
			xpcall(originalBeginWork, describeError, current, unitOfWork, lanes)
		if not ok then
			local originalError = result

			if
				originalError ~= nil
				and typeof(originalError) == "table"
				and typeof(originalError.andThen) == "function"
			then
				-- Don't replay promises. Treat everything else like an error.
				error(originalError)
			end

			-- Keep this code in sync with handleError; any changes here must have
			-- corresponding changes there.
			resetContextDependencies()
			resetHooksAfterThrow()
			-- Don't reset current debug fiber, since we're about to work on the
			-- same fiber again.

			-- Unwind the failed stack frame
			unwindInterruptedWork(unitOfWork)

			-- Restore the original properties of the fiber.
			ReactFiber.assignFiberPropertiesInDEV(unitOfWork, originalWorkInProgressCopy)

			if
				ReactFeatureFlags.enableProfilerTimer
				and bit32.band(unitOfWork.mode, ReactTypeOfMode.ProfileMode) ~= 0
			then
				-- Reset the profiler timer.
				ReactProfilerTimer.startProfilerTimer(unitOfWork)
			end

			-- Run beginWork again.
			invokeGuardedCallback(nil, originalBeginWork, nil, current, unitOfWork, lanes)

			if hasCaughtError() then
				local replayError = clearCaughtError()
				-- `invokeGuardedCallback` sometimes sets an expando `_suppressLogging`.
				-- Rethrow this error instead of the original one.
				error(replayError)
			else
				-- This branch is reachable if the render phase is impure.
				error(originalError)
			end
		end

		return result
	end
else
	mod.beginWork = originalBeginWork
end

local didWarnAboutUpdateInRender = false
local didWarnAboutUpdateInRenderForAnotherComponent
if __DEV__ then
	didWarnAboutUpdateInRenderForAnotherComponent = {}
end

mod.warnAboutRenderPhaseUpdatesInDEV = function(fiber: Fiber): ()
	if __DEV__ then
		if
			ReactCurrentFiber.isRendering
			and bit32.band(executionContext, RenderContext) ~= NoContext
			and not getIsUpdatingOpaqueValueInRenderPhaseInDEV()
		then
			if
				fiber.tag == ReactWorkTags.FunctionComponent
				or fiber.tag == ReactWorkTags.ForwardRef
				or fiber.tag == ReactWorkTags.SimpleMemoComponent
			then
				local renderingComponentName = (function()
					if workInProgress ~= nil then
						return getComponentName((workInProgress :: Fiber).type)
					end
					return "Unknown"
				end)()
				-- Dedupe by the rendering component because it's the one that needs to be fixed.
				local dedupeKey = renderingComponentName
				-- ROBLOX deviation:
				-- if !didWarnAboutUpdateInRenderForAnotherComponent.has(dedupeKey))
				if didWarnAboutUpdateInRenderForAnotherComponent[dedupeKey] == nil then
					didWarnAboutUpdateInRenderForAnotherComponent[dedupeKey] = true
					local setStateComponentName = getComponentName(fiber.type)
						or "Unknown"
					console.error(
[[Cannot update a component (`%s`) while rendering a different component (`%s`). To locate the bad setState() call inside `%s`, follow the stack trace as described in https://reactjs.org/link/setstate-in-render]]

,
						setStateComponentName,
						renderingComponentName,
						renderingComponentName
					)
				end
			elseif fiber.tag == ReactWorkTags.ClassComponent then
				if not didWarnAboutUpdateInRender then
					console.error(
[[Cannot update during an existing state transition (such as within `render`). Render methods should be a pure function of props and state.]]					


)
					didWarnAboutUpdateInRender = true
				end
			end
		end
	end
end

-- a 'shared' variable that changes when act() opens/closes in tests.
exports.IsThisRendererActing = { current = false }

exports.warnIfNotScopedWithMatchingAct = function(fiber: Fiber)
	if __DEV__ then
		if
			ReactFiberHostConfig.warnsIfNotActing == true
			and IsSomeRendererActing.current == true
			and exports.IsThisRendererActing.current ~= true
		then
			local previousFiber = ReactCurrentFiber.current
			local ok, result = pcall(function()
				setCurrentDebugFiberInDEV(fiber)
				-- deviation: error modified to suggest proper lua instead of JS

				-- FIXME (roblox): return to this when we have a better idea of what it
				-- looks like; in React, this string is broken up oddly to avoid
				-- confusing tools, but we don't have any reason to do that right now
				console.error(
[[It looks like you're using the wrong act() around your test interactions.
Be sure to use the matching version of act() corresponding to your renderer:

-- for react-roblox:
local React = require(Packages.React)
-- ...
React.TestUtils.act(function() ... end)

-- for react-test-renderer:
local TestRenderer = require(Packages.ReactTestRenderer)
-- ...
TestRenderer.act(function() ... end)]]				)
			end)

			-- finally
			if previousFiber then
				setCurrentDebugFiberInDEV(fiber)
			else
				resetCurrentDebugFiberInDEV()
			end

			if not ok then
				error(result)
			end
		end
	end
end

exports.warnIfNotCurrentlyActingEffectsInDEV = function(fiber: Fiber): ()
	if __DEV__ then
		if
			ReactFiberHostConfig.warnsIfNotActing == true
			and bit32.band(fiber.mode, ReactTypeOfMode.StrictMode) ~= ReactTypeOfMode.NoMode
			and IsSomeRendererActing.current == false
			and exports.IsThisRendererActing.current == false
		then
			-- ROBLOX deviation: Use Lua syntax for example fix
			console.error(
[=[An update to %s ran an effect, but was not wrapped in act(...).

When testing, code that causes React state updates should be wrapped into act(...):

act(function()
  --[[ fire events that update state ]]
end)
--[[ assert on the output ]]

This ensures that you're testing the behavior the user would see in the real client. Learn more at https://reactjs.org/link/wrap-tests-with-act]=],
				getComponentName(fiber.type)
			)
		end
	end
end

exports.warnIfNotCurrentlyActingUpdatesInDEV = function(fiber: Fiber): ()
	if __DEV__ then
		if
			ReactFiberHostConfig.warnsIfNotActing == true
			and executionContext == NoContext
			and IsSomeRendererActing.current == false
			and exports.IsThisRendererActing.current == false
		then
			local previousFiber = ReactCurrentFiberCurrent
			local ok, result = pcall(function()
				setCurrentDebugFiberInDEV(fiber)
				-- ROBLOX deviation: Use Lua syntax for example fix
				console.error(
[=[An update to %s inside a test was not wrapped in act(...).

When testing, code that causes React state updates should be wrapped into act(...):

act(function()
  --[[ fire events that update state ]]
end)
--[[ assert on the output ]]

This ensures that you're testing the behavior the user would see in the client application. Learn more at https://reactjs.org/link/wrap-tests-with-act]=],
					getComponentName(fiber.type)
				)
			end)

			-- Finally
			if previousFiber then
				setCurrentDebugFiberInDEV(fiber)
			else
				resetCurrentDebugFiberInDEV()
			end

			if ok then
				return result
			end
		end
	end
	-- ROBLOX deviation: explicit return to silence analyze
	return
end

-- In tests, we want to enforce a mocked scheduler.
local didWarnAboutUnmockedScheduler = false
-- TODO Before we release concurrent mode, revisit this and decide whether a mocked
-- scheduler is the actual recommendation. The alternative could be a testing build,
-- a new lib, or whatever; we dunno just yet. This message is for early adopters
-- to get their tests right.

exports.warnIfUnmockedScheduler = function(fiber: Fiber)
	if __DEV__ then
		if
			didWarnAboutUnmockedScheduler == false
			and Scheduler.unstable_flushAllWithoutAsserting == nil
		then
			if
				bit32.band(fiber.mode, ReactTypeOfMode.BlockingMode) ~= 0
				or bit32.band(fiber.mode, ReactTypeOfMode.ConcurrentMode) ~= 0
			then
				didWarnAboutUnmockedScheduler = true
				-- deviation: error modified to suggest proper lua instead of JS

				-- FIXME (roblox): return to this when jest-roblox is in use; in React,
				-- this string is broken up oddly to avoid confusing tools, but we don't
				-- have any reason to do that right now
				console.error(
[[In Concurrent or Sync modes, the 'scheduler' module needs to be mocked to guarantee consistent behaviour across tests and client application. For example, with Jest: 
jest.mock('scheduler', function() return require(@pkg/scheduler).unstable_mock end)

For more info, visit https://reactjs.org/link/mock-scheduler]]				

)
			elseif ReactFeatureFlags.warnAboutUnmockedScheduler == true then
				didWarnAboutUnmockedScheduler = true
				-- deviation: error modified to suggest proper lua instead of JS

				-- FIXME (roblox): return to this when jest-roblox is in use; in React,
				-- this string is broken up oddly to avoid confusing tools, but we don't
				-- have any reason to do that right now
				console.error(
[[Starting from React v18, the 'scheduler' module will need to be mocked to guarantee consistent behaviour across tests and client applications. For example, with Jest: 
jest.mock('scheduler', function() return require(@pkg/scheduler).unstable_mock end)

For more info, visit https://reactjs.org/link/mock-scheduler]]				


)
			end
		end
	end
end

function computeThreadID(root: FiberRoot, lane: Lane | Lanes)
	-- Interaction threads are unique per root and expiration time.
	-- NOTE: Intentionally unsound cast. All that matters is that it's a number
	-- and it represents a batch of work. Could make a helper function instead,
	-- but meh this is fine for now.
	return lane * 1000 + root.interactionThreadID
end

exports.markSpawnedWork = function(lane: Lane | Lanes)
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end
	if spawnedWorkDuringRender == nil then
		spawnedWorkDuringRender = { lane }
	else
		-- ROBLOX FIXME Luau: depends on Luau type states
		table.insert(spawnedWorkDuringRender :: Array<number>, lane)
	end
end

function scheduleInteractions(
	root: FiberRoot,
	lane: Lane | Lanes,
	interactions: Set<Interaction>
)
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	if interactions.size > 0 then
		local pendingInteractionMap = root.pendingInteractionMap
		local pendingInteractions = pendingInteractionMap:get(lane)
		if pendingInteractions ~= nil then
			interactions:forEach(function(interaction)
				if not pendingInteractions:has(interaction) then
					-- Update the pending async work count for previously unscheduled interaction.
					interaction.__count += 1
				end

				pendingInteractions:add(interaction)
			end)
		else
			pendingInteractionMap:set(lane, Set.new(interactions))

			-- Update the pending async work count for the current interactions.
			for _, interaction in interactions do
				interaction.__count += 1
			end
		end

		local subscriber = __subscriberRef.current
		if subscriber ~= nil then
			local threadID = computeThreadID(root, lane)
			subscriber.onWorkScheduled(interactions, threadID)
		end
	end
end

mod.schedulePendingInteractions = function(root: FiberRoot, lane: Lane | Lanes)
	-- This is called when work is scheduled on a root.
	-- It associates the current interactions with the newly-scheduled expiration.
	-- They will be restored when that expiration is later committed.
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	scheduleInteractions(root, lane, __interactionsRef.current)
end

mod.startWorkOnPendingInteractions = function(root: FiberRoot, lanes: Lanes)
	-- This is called when new work is started on a root.
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	-- Determine which interactions this batch of work currently includes, So that
	-- we can accurately attribute time spent working on it, And so that cascading
	-- work triggered during the render phase will be associated with it.
	local interactions: Set<Interaction> = Set.new()
	root.pendingInteractionMap:forEach(function(scheduledInteractions, scheduledLane)
		if includesSomeLane(lanes, scheduledLane) then
			scheduledInteractions:forEach(function(interaction)
				interactions:add(interaction)
			end)
		end
	end)

	-- Store the current set of interactions on the ReactInternalTypes.FiberRoot for a few reasons:
	-- We can re-use it in hot functions like performConcurrentWorkOnRoot()
	-- without having to recalculate it. We will also use it in commitWork() to
	-- pass to any Profiler onRender() hooks. This also provides DevTools with a
	-- way to access it when the onCommitRoot() hook is called.
	-- ROBLOX FIXME: manual type check to workaround Luau analyze bug "Type 'Set<Interaction>' could not be converted into 'Set<Interaction>'"
	root.memoizedInteractions = interactions :: any

	if interactions.size > 0 then
		local subscriber = __subscriberRef.current
		if subscriber ~= nil then
			local threadID = computeThreadID(root, lanes)
			local ok, error_ =
				xpcall(subscriber.onWorkStarted, describeError, interactions, threadID)
			if not ok then
				-- If the subscriber throws, rethrow it in a separate task
				scheduleCallback(ImmediateSchedulerPriority, function()
					error(error_)
				end)
			end
		end
	end
end

mod.finishPendingInteractions = function(root: FiberRoot, committedLanes)
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	local remainingLanesAfterCommit = root.pendingLanes

	local subscriber

	-- ROBLOX try
	local ok = true
	local error_
	if subscriber ~= nil and root.memoizedInteractions.size > 0 then
		-- FIXME: More than one lane can finish in a single commit.
		-- ROBLOX peformance: hoist non-throwable things out of the pcall() so we can remove an anon function
		local threadID = computeThreadID(root, committedLanes)
		subscriber = __subscriberRef.current
		-- ROBLOX deviation: helper for raw table set/map size > 0
		ok, error_ = xpcall(
			subscriber.onWorkStopped,
			describeError,
			root.memoizedInteractions,
			threadID
		)
	end

	-- ROBLOX finally
	-- Clear completed interactions from the pending Map.
	-- Unless the render was suspended or cascading work was scheduled,
	-- In which case– leave pending interactions until the subsequent render.
	local pendingInteractionMap = root.pendingInteractionMap
	pendingInteractionMap:forEach(function(scheduledInteractions, lane)
		-- Only decrement the pending interaction count if we're done.
		-- If there's still work at the current priority,
		-- That indicates that we are waiting for suspense data.
		if not includesSomeLane(remainingLanesAfterCommit, lane) then
			pendingInteractionMap:delete(lane)
			scheduledInteractions:forEach(function(interaction)
				interaction.__count -= 1

				if subscriber ~= nil and interaction.__count == 0 then
					local ok_, error__ = xpcall(
						subscriber.onInteractionScheduledWorkCompleted,
						describeError,
						interaction
					)
					if not ok_ then
						-- If the subscriber throws, rethrow it in a separate task
						scheduleCallback(ImmediateSchedulerPriority, function()
							error(error__)
						end)
					end
				end
			end)
		end
	end)

	-- ROBLOX catch
	if not ok then
		-- If the subscriber throws, rethrow it in a separate task
		scheduleCallback(ImmediateSchedulerPriority, function()
			error(error_)
		end)
	end
end

-- `act` testing API
--
-- TODO: This is mostly a copy-paste from the legacy `act`, which does not have
-- access to the same internals that we do here. Some trade offs in the
-- implementation no longer make sense.
local isFlushingAct = false
local isInsideThisAct = false

local flushMockScheduler = Scheduler.unstable_flushAllWithoutAsserting
local isSchedulerMocked = typeof(flushMockScheduler) == "function"

-- Returns whether additional work was scheduled. Caller should keep flushing
-- until there's no work left.
local function flushActWork(): boolean
	if flushMockScheduler ~= nil then
		local prevIsFlushing = isFlushingAct
		isFlushingAct = true
		local ok, result = xpcall(flushMockScheduler, describeError)

		-- finally
		isFlushingAct = prevIsFlushing

		if not ok then
			error(result)
		else
			return result
		end
	else
		-- No mock scheduler available. However, the only type of pending work is
		-- passive effects, which we control. So we can flush that.
		local prevIsFlushing = isFlushingAct
		isFlushingAct = true
		-- ROBLOX performance? rewrite this loop to eliminate anon function?
		local ok, result = xpcall(function()
			local didFlushWork = false
			while exports.flushPassiveEffects() do
				didFlushWork = true
			end
			return didFlushWork
		end, describeError)

		-- finally
		isFlushingAct = prevIsFlushing

		if not ok then
			error(result)
		else
			return result
		end
	end
end

local function flushWorkAndMicroTasks(onDone: (any?) -> ())
	-- ROBLOX performance: split into two pcall to eliminate anonymous func allocation per call
	local ok, result = xpcall(flushActWork, describeError)
	if ok then
		ok, result = xpcall(enqueueTask, describeError, function()
			if flushActWork() then
				flushWorkAndMicroTasks(onDone)
			else
				onDone()
			end
		end)
	end

	if not ok then
		onDone(result)
	end
end

exports.act = function(callback: () -> Thenable<any>): Thenable<any>
	-- It's only viable to export `act` when we're using mocked scheduling logic.
	-- Since there are numerous testing scenarios in which we call `require` on
	-- the Roact library _before_ we bootstrap tests, we expose a global to toggle
	-- this explicilty
	if not (__DEV__ or _G.__ROACT_17_MOCK_SCHEDULER__) then
		if didWarnAboutUsingActInProd == false then
			didWarnAboutUsingActInProd = true
			-- eslint-disable-next-line react-internal/no-production-logging
			console.error(
				"act(...) is not supported in production builds of React, and might not behave as expected."
			)
		end
	end

	local previousActingUpdatesScopeDepth = actingUpdatesScopeDepth
	actingUpdatesScopeDepth += 1

	local previousIsSomeRendererActing = IsSomeRendererActing.current
	local previousIsThisRendererActing = exports.IsThisRendererActing.current
	local previousIsInsideThisAct = isInsideThisAct
	IsSomeRendererActing.current = true
	exports.IsThisRendererActing.current = true
	isInsideThisAct = true

	local function onDone()
		actingUpdatesScopeDepth -= 1
		IsSomeRendererActing.current = previousIsSomeRendererActing
		exports.IsThisRendererActing.current = previousIsThisRendererActing
		isInsideThisAct = previousIsInsideThisAct
		if __DEV__ then
			if actingUpdatesScopeDepth > previousActingUpdatesScopeDepth then
				-- if it's _less than_ previousActingUpdatesScopeDepth, then we can assume the 'other' one has warned
				console.error(
[[You seem to have overlapping act() calls, this is not supported. Be sure to await previous act() calls before making a new one. ]]				

)
			end
		end
	end

	local ok, result = xpcall(exports.batchedUpdates, describeError, callback)
	if not ok then
		onDone()
		error(result)
	end

	if
		result ~= nil
		and typeof(result) == "table"
		and typeof(result.andThen) == "function"
	then
		-- setup a boolean that gets set to true only
		-- once this act() call is await-ed
		local called = false
		if __DEV__ then
			if typeof(Promise) ~= nil then
				--eslint-disable-next-line no-undef
				Promise.resolve():andThen(function() end):andThen(function()
					if called == false then
						-- FIXME (roblox): We should replace this with proper Lua promise
						-- logic
						console.error(
[=[You called act(Promise.new(function() --[[ ... ]] end)) without :await() or :expect(). This could lead to unexpected testing behaviour, interleaving multiple act calls and mixing their scopes. You should - act(function() Promise.new(function() --[[ ... ]] end):await() end);]=]						


)
					end
				end)
			end
		end

		-- in the async case, the returned thenable runs the callback, flushes
		-- effects and microtasks in a loop until flushPassiveEffects() == false,
		-- and cleans up
		return {
			-- ROBLOX FIXME Luau: have to explicitly annotate the unused generic arg: CLI-49996
			andThen = function<U>(self, resolve, reject)
				called = true
				return result:andThen(function()
					if
						actingUpdatesScopeDepth > 1
						or (
							isSchedulerMocked == true
							and previousIsSomeRendererActing == true
						)
					then
						onDone()
						resolve()
						return
					end
					-- we're about to exit the act() scope,
					-- now's the time to flush tasks/effects
					flushWorkAndMicroTasks(function(err: any?)
						onDone()
						if err then
							reject(err)
						else
							resolve()
						end
					end)
				end, function(err)
					onDone()
					reject(err)
				end)
			end,
		}
	else
		if __DEV__ then
			if result ~= nil then
				-- ROBLOX deviation: use Lua syntax
				console.error(
[[The callback passed to act(...) function must return nil, or a Promise. You returned %s]]
,
					tostring(result)
				)
			end
		end

		-- flush effects until none remain, and cleanup
		local flushOk, flushResult = xpcall(function()
			if
				actingUpdatesScopeDepth == 1
				and (isSchedulerMocked == false or previousIsSomeRendererActing == false)
			then
				-- we're about to exit the act() scope,
				-- now's the time to flush effects
				flushActWork()
			end
			onDone()
		end, describeError)

		if not flushOk then
			onDone()
			error(flushResult)
		end

		-- in the sync case, the returned thenable only warns *if* await-ed
		return {
			-- ROBLOX FIXME Luau: have to explicitly annotate the unused generic arg: CLI-49996
			andThen = function<U>(self, resolve, reject_)
				if __DEV__ then
					console.error(
						"Do not await the result of calling act(...) with sync logic, it is not a Promise."
					)
				end
				resolve()
			end,
		}
	end
end

mod.detachFiberAfterEffects = function(fiber: Fiber)
	-- Null out fields to improve GC for references that may be lingering (e.g. DevTools).
	-- Note that we already cleared the return pointer in detachFiberMutation().
	fiber.child = nil
	fiber.deletions = nil
	fiber.dependencies = nil
	fiber.memoizedProps = nil
	fiber.memoizedState = nil
	fiber.pendingProps = nil
	fiber.sibling = nil
	fiber.stateNode = nil
	fiber.updateQueue = nil

	if __DEV__ then
		fiber._debugOwner = nil
	end
end

return exports

end,
["react-reconciler/ReactHookEffectTags"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactHookEffectTags.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type HookFlags = number

return {
	--[[  ]]
	NoFlags = 0b000,

	-- Represents whether effect should fire.
	--[[ ]]
	HasEffect = 0b001,

	-- Represents the phase in which the effect (not the clean-up) fires.
	--[[    ]]
	Layout = 0b010,
	--[[   ]]
	Passive = 0b100,
}

end,
["react-reconciler/ReactInternalTypes"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/7baf9d4128d41903de125527b50285ea9862cf9a/packages/react-reconciler/src/ReactInternalTypes.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Array<T> = LuauPolyfill.Array<T>
type Map<K, V> = LuauPolyfill.Map<K, V>
type Object = { [string]: any }
type SimpleSet<T> = { [T]: boolean }
type SimpleMap<K, V> = { [K]: V }
type Set<T> = LuauPolyfill.Set<T>

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes

type Source = ReactTypes.Source
type RefObject = ReactTypes.RefObject
type ReactContext<T> = ReactTypes.ReactContext<T>
type MutableSourceVersion = ReactTypes.MutableSourceVersion
type MutableSource<Source> = ReactTypes.MutableSource<Source>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<
	Source,
	Snapshot
>

-- ROBLOX deviation START: These are 'mixed' by default, and specialized by the renderer, need complicated dynamic resolution to do this properly
-- local ReactFiberHostConfig = require("./ReactFiberHostConfig")
-- type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
type SuspenseInstance = any
-- ROBLOX deviation END
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
type WorkTag = ReactWorkTags.WorkTag
local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
type TypeOfMode = ReactTypeOfMode.TypeOfMode
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
type Flags = ReactFiberFlags.Flags
-- deviation: FiberLane types are defined and exported from here to avoid
-- cyclical requires
export type LanePriority = number
export type Lanes = number
export type Lane = number
export type LaneMap<T> = { [number]: T }

-- ROBLOX deviation: Update<>, SharedQueue<>, UpdateQueue<> transplanted from ReactUpdateQueue for use by createReactNoop
export type Update<State> = {
	-- TODO: Temporary field. Will remove this by storing a map of
	-- transition -> event time on the root.
	eventTime: number,
	lane: Lane,

	-- ROBLOX FIXME Luau: revert when luau supports singleton integers
	-- tag: 0 | 1 | 2 | 3,
	tag: number,
	payload: any,
	callback: (() -> ...any)?,

	next: Update<State>?
}

export type SharedQueue<State> = {
	pending: Update<State>?
}

export type UpdateQueue<State> = {
	baseState: State,
	firstBaseUpdate: Update<State>?,
	lastBaseUpdate: Update<State>?,
	shared: SharedQueue<State>,
	effects: Array<Update<State>>?
}

export type HookType =
	"useState"
	| "useReducer"
	| "useContext"
	| "useRef"
	-- ROBLOX deviation: Bindings are a feature unique to Roact
	| "useBinding"
	| "useEffect"
	| "useLayoutEffect"
	| "useCallback"
	| "useMemo"
	| "useImperativeHandle"
	| "useDebugValue"
	| "useDeferredValue"
	| "useTransition"
	| "useMutableSource"
	| "useOpaqueIdentifier"
local ReactRootTags = require(script.Parent:WaitForChild('ReactRootTags'))
type RootTag = ReactRootTags.RootTag
-- ROBLOX deviation: we can't import types for dynamic imports like HostConfig files
-- type TimeoutHandle = ReactFiberHostConfig.TimeoutHandle;
-- type NoTimeout = ReactFiberHostConfig.NoTimeout;
type TimeoutHandle = any
type NoTimeout = any
-- ROBLOX deviation: type forwarded to top-level export
local Shared = require(script.Parent.Parent:WaitForChild('shared'))
type Wakeable = Shared.Wakeable
-- ROBLOX deviation: Interaction type forwarded to top-level export
local Scheduler = require(script.Parent.Parent:WaitForChild('scheduler'))
type Interaction = Scheduler.Interaction

-- ROBLOX deciation: Luau doesn't support type literals:  99 | 98 | 97 | 96 | 95 | 90
export type ReactPriorityLevel = number

export type ContextDependency<T> = {
	context: ReactContext<T>,
	observedBits: number,
	-- ROBLOX TODO: upstream only parameterizes this type with `mixed`, so avoid Luau recursive type constraint. upstream this change later.
	next: ContextDependency<T> | nil	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END

}

export type Dependencies = {
	lanes: Lanes,
	firstContext: ContextDependency<any> | nil	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END

}

-- ROBLOX deviation: Roact stable keys - slightly widen the type definition of a
-- stable key so that it's likely to work with existing Roact code. Includes
-- numbers for mixed/sparse tables
export type RoactStableKey = string | number

-- A Fiber is work on a Component that needs to be done or was done. There can
-- be more than one per component.
export type Fiber = {
	-- These first fields are conceptually members of an Instance. This used to
	-- be split into a separate type and intersected with the other Fiber fields,
	-- but until Flow fixes its intersection bugs, we've merged them into a
	-- single type.

	-- An Instance is shared between all versions of a component. We can easily
	-- break this out into a separate object to avoid copying so much to the
	-- alternate versions of the tree. We put this on a single object for now to
	-- minimize the number of objects created during the initial render.

	-- Tag identifying the type of fiber.
	tag: WorkTag,

	-- ROBLOX deviation: Use a slightly more permissive key type to allow for
	-- sparse arrays, which will still be distinct from actual arrays.
	-- Unique identifier of this child.
	key: RoactStableKey?,

	-- The value of element.type which is used to preserve the identity during
	-- reconciliation of this child.
	elementType: any,

	-- The resolved function/class/ associated with this fiber.
	type: any,

	-- The local state associated with this fiber.
	stateNode: any,

	-- Conceptual aliases
	-- parent : Instance -> return The parent happens to be the same as the
	-- return fiber since we've merged the fiber and instance.

	-- Remaining fields belong to Fiber

	-- The Fiber to return to after finishing processing this one.
	-- This is effectively the parent, but there can be multiple parents (two)
	-- so this is only the parent of the thing we're currently processing.
	-- It is conceptually the same as the return address of a stack frame.
	return_: Fiber | nil,

	-- Singly Linked List Tree Structure.
	child: Fiber?,
	sibling: Fiber?,
	index: number,

	-- The ref last used to attach this node.
	-- I'll avoid adding an owner field for prod and model that as functions.
	-- ROBLOX deviation: Lua doesn't allow fields on functions
	-- ref: (((any) -> ()) & {_stringRef: string?, [string]: any}) | RefObject,
	ref: nil | ((handle: any) -> ()) | { _stringRef: string?, [string]: any } | RefObject,

	-- Input is the data coming into process this fiber. Arguments. Props.
	pendingProps: any, -- This type will be more specific once we overload the tag.
	memoizedProps: any, -- The props used to create the output.

	-- A queue of state updates and callbacks.
	updateQueue: any,

	-- The state used to create the output
	memoizedState: any,

	-- Dependencies (contexts, events) for this fiber, if it has any
	dependencies: Dependencies?,

	-- Bitfield that describes properties about the fiber and its subtree. E.g.
	-- the ConcurrentMode flag indicates whether the subtree should be async-by-
	-- default. When a fiber is created, it inherits the mode of its
	-- parent. Additional flags can be set at creation time, but after that the
	-- value should remain unchanged throughout the fiber's lifetime, particularly
	-- before its child fibers are created.
	mode: TypeOfMode,

	-- Effect
	flags: Flags,
	subtreeFlags: Flags,
	deletions: Array<Fiber>?,

	-- Singly linked list fast path to the next fiber with side-effects.
	nextEffect: Fiber?,

	-- The first and last fiber with side-effect within this subtree. This allows
	-- us to reuse a slice of the linked list when we reuse the work done within
	-- this fiber.
	firstEffect: Fiber?,
	lastEffect: Fiber?,

	lanes: Lanes,
	childLanes: Lanes,

	-- This is a pooled version of a Fiber. Every fiber that gets updated will
	-- eventually have a pair. There are cases when we can clean up pairs to save
	-- memory if we need to.
	alternate: Fiber?,

	-- Time spent rendering this Fiber and its descendants for the current update.
	-- This tells us how well the tree makes use of sCU for memoization.
	-- It is reset to 0 each time we render and only updated when we don't bailout.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	actualDuration: number?,

	-- If the Fiber is currently active in the "render" phase,
	-- This marks the time at which the work began.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	actualStartTime: number?,

	-- Duration of the most recent render time for this Fiber.
	-- This value is not updated when we bailout for memoization purposes.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	selfBaseDuration: number?,

	-- Sum of base times for all descendants of this Fiber.
	-- This value bubbles up during the "complete" phase.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	treeBaseDuration: number?,

	-- Conceptual aliases
	-- workInProgress : Fiber ->  alternate The alternate used for reuse happens
	-- to be the same as work in progress.
	-- _G.__DEV__ only
	_debugID: number?,
	_debugSource: Source?,
	_debugOwner: Fiber?,
	_debugIsCurrentlyTiming: boolean?,
	_debugNeedsRemount: boolean?,

	-- Used to verify that the order of hooks does not change between renders.
	_debugHookTypes: Array<HookType>?
}

export type SuspenseHydrationCallbacks = {
	onHydrated: ((SuspenseInstance) -> ())?,
	onDeleted: ((SuspenseInstance) -> ())?	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END

}

-- deviation: Instead of combining all these props after the fact, we define
-- them all in one to allow Luau's syntax

-- Exported FiberRoot type includes all properties,
-- To avoid requiring potentially error-prone :any casts throughout the project.
-- Profiling properties are only safe to access in profiling builds (when enableSchedulerTracing is true).
-- The types are defined separately within this file to ensure they stay in sync.
-- (We don't have to use an inline :any cast when enableSchedulerTracing is disabled.)
export type FiberRoot = {
	-- ...BaseFiberRootProperties,
	-- The type of root (legacy, batched, concurrent, etc.)
	tag: RootTag,

	-- Any additional information from the host associated with this root.
	containerInfo: any,
	-- Used only by persistent updates.
	pendingChildren: any,
	-- The currently active root fiber. This is the mutable root of the tree.
	current: Fiber,

	-- ROBLOX deviation START: we use a lightweight unordered set for performance
	pingCache: SimpleMap<
		Wakeable,
		(SimpleSet<any> | SimpleMap<Wakeable, SimpleSet<any>>)
	> | nil,
	-- ROBLOX deviation END

	-- A finished work-in-progress HostRoot that's ready to be committed.
	finishedWork: Fiber?,
	-- Timeout handle returned by setTimeout. Used to cancel a pending timeout, if
	-- it's superseded by a new one.
	timeoutHandle: TimeoutHandle | NoTimeout,
	-- Top context object, used by renderSubtreeIntoContainer
	context: Object?,
	pendingContext: Object?,
	-- Determines if we should attempt to hydrate on the initial mount
	hydrate: boolean,

	-- Used by useMutableSource hook to avoid tearing during hydration.
	mutableSourceEagerHydrationData: Array<MutableSource<any> | MutableSourceVersion>?,

	-- Node returned by Scheduler.scheduleCallback. Represents the next rendering
	-- task that the root will work on.
	callbackNode: any,
	callbackPriority: LanePriority,
	eventTimes: LaneMap<number>,
	expirationTimes: LaneMap<number>,

	pendingLanes: Lanes,
	suspendedLanes: Lanes,
	pingedLanes: Lanes,
	expiredLanes: Lanes,
	mutableReadLanes: Lanes,

	finishedLanes: Lanes,

	entangledLanes: Lanes,
	entanglements: LaneMap<Lanes>,

	-- ...ProfilingOnlyFiberRootProperties,
	-- The following attributes are only used by interaction tracing builds.
	-- They enable interactions to be associated with their async work,
	-- And expose interaction metadata to the React DevTools Profiler plugin.
	-- Note that these attributes are only defined when the enableSchedulerTracing flag is enabled.
	interactionThreadID: number,
	memoizedInteractions: Set<Interaction>,
	pendingInteractionMap: Map<Lane | Lanes, Set<Interaction>>,

	-- ...SuspenseCallbackOnlyFiberRootProperties,
	-- The follow fields are only used by enableSuspenseCallback for hydration.
	hydrationCallbacks: SuspenseHydrationCallbacks?
	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END

}

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()

-- ROBLOX deviation: Dispatcher is defined in Shared to avoid circular deps
export type Dispatcher = Shared.Dispatcher

-- deviation: Return something so that the module system is happy
return {}

end,
["react-reconciler/ReactMutableSource.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react-reconciler/src/ReactMutableSource.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

type Array<T> = { [number]: T }
local exports = {}

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type MutableSource<T> = ReactTypes.MutableSource<T>
type MutableSourceVersion = ReactTypes.MutableSourceVersion

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type FiberRoot = ReactInternalTypes.FiberRoot

local isPrimaryRenderer = require(script.Parent:WaitForChild('ReactFiberHostConfig')).isPrimaryRenderer

-- Work in progress version_ numbers only apply to a single render,
-- and should be reset before starting a new render.
-- This tracks which mutable sources need to be reset after a render.
local workInProgressSources: Array<MutableSource<any>> = {}

local rendererSigil
if _G.__DEV__ then
	-- Used to detect multiple renderers using the same mutable source.
	rendererSigil = {}
end

exports.markSourceAsDirty = function(mutableSource: MutableSource<any>)
	table.insert(workInProgressSources, mutableSource)
end

exports.resetWorkInProgressVersions = function()
	for i, mutableSource in workInProgressSources do
		if isPrimaryRenderer then
			mutableSource._workInProgressVersionPrimary = nil
		else
			mutableSource._workInProgressVersionSecondary = nil
		end
	end
	table.clear(workInProgressSources)
end

exports.getWorkInProgressVersion =
	function(mutableSource: MutableSource<any>): nil | MutableSourceVersion
		if isPrimaryRenderer then
			return mutableSource._workInProgressVersionPrimary
		else
			return mutableSource._workInProgressVersionSecondary
		end
	end

exports.setWorkInProgressVersion =
	function(mutableSource: MutableSource<any>, version_: MutableSourceVersion)
		if isPrimaryRenderer then
			mutableSource._workInProgressVersionPrimary = version_
		else
			mutableSource._workInProgressVersionSecondary = version_
		end
		table.insert(workInProgressSources, mutableSource)
	end

exports.warnAboutMultipleRenderersDEV = function(mutableSource: MutableSource<any>)
	if _G.__DEV__ then
		if isPrimaryRenderer then
			if mutableSource._currentPrimaryRenderer == nil then
				mutableSource._currentPrimaryRenderer = rendererSigil
			elseif mutableSource._currentPrimaryRenderer ~= rendererSigil then
				console.error(
[[Detected multiple renderers concurrently rendering the same mutable source. This is currently unsupported.]]				

)
			end
		else
			if mutableSource._currentSecondaryRenderer == nil then
				mutableSource._currentSecondaryRenderer = rendererSigil
			elseif mutableSource._currentSecondaryRenderer ~= rendererSigil then
				console.error(
[[Detected multiple renderers concurrently rendering the same mutable source. This is currently unsupported.]]				

)
			end
		end
	end
end

-- Eager reads the version of a mutable source and stores it on the root.
-- This ensures that the version used for server rendering matches the one
-- that is eventually read during hydration.
-- If they don't match there's a potential tear and a full deopt render is required.
exports.registerMutableSourceForHydration =
	function(root: FiberRoot, mutableSource: MutableSource<any>)
		local getVersion = mutableSource._getVersion
		local version_ = getVersion(mutableSource._source)

		-- TODO Clear this data once all pending hydration work is finished.
		-- Retaining it forever may interfere with GC.
		if root.mutableSourceEagerHydrationData == nil then
			root.mutableSourceEagerHydrationData = { mutableSource, version_ }
			-- ROBLOX FIXME: having trouble with type coercion in this case
			-- table.insert(root.mutableSourceEagerHydrationData, mutableSource)
			-- table.insert(root.mutableSourceEagerHydrationData, version_)
		
end
	end

return exports

end,
["react-reconciler/ReactPortal"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react-reconciler/src/ReactPortal.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local REACT_PORTAL_TYPE = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols.REACT_PORTAL_TYPE

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type ReactNodeList = ReactTypes.ReactNodeList
type ReactPortal = ReactTypes.ReactPortal

local function createPortal(
	children: ReactNodeList,
	containerInfo: any,
	-- TODO: figure out the API for cross-renderer implementation.
	implementation: any,
	key: string?
): ReactPortal
	if key ~= nil then
		key = tostring(key)
	end
	return {
		-- This tag allow us to uniquely identify this as a React Portal
		["$$typeof"] = REACT_PORTAL_TYPE,
		key = key,
		children = children,
		containerInfo = containerInfo,
		implementation = implementation,
	}
end

return {
	createPortal = createPortal,
}

end,
["react-reconciler/ReactProfilerTimer.new"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react-reconciler/src/ReactProfilerTimer.new.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
local enableProfilerCommitHooks = ReactFeatureFlags.enableProfilerCommitHooks

local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))
local Profiler = ReactWorkTags.Profiler

-- Intentionally not named imports because Rollup would use dynamic dispatch for
-- CommonJS interop named imports.
local Scheduler = require(script.Parent.Parent:WaitForChild('scheduler'))

local now = Scheduler.unstable_now

export type ProfilerTimer = {
	getCommitTime: () -> number,
	recordCommitTime: () -> (),
	startProfilerTimer: (Fiber) -> (),
	stopProfilerTimerIfRunning: (Fiber) -> (),
	stopProfilerTimerIfRunningAndRecordDelta: (Fiber) -> ()	-- ...

}

local commitTime: number = 0
local layoutEffectStartTime: number = -1
local profilerStartTime: number = -1
local passiveEffectStartTime: number = -1

function getCommitTime(): number
	return commitTime
end

function recordCommitTime(): ()
	if not enableProfilerTimer then
		return
	end
	commitTime = now()
end

function startProfilerTimer(fiber: Fiber): ()
	if not enableProfilerTimer then
		return
	end

	profilerStartTime = now()

	-- ROBLOX deviation: JS can compare null/undefined to 0, but Lua can't
	if fiber.actualStartTime ~= nil and (fiber.actualStartTime :: number) < 0 then
		fiber.actualStartTime = now()
	end
end

function stopProfilerTimerIfRunning(fiber: Fiber): ()
	if not enableProfilerTimer then
		return
	end
	profilerStartTime = -1
end

function stopProfilerTimerIfRunningAndRecordDelta(
	fiber: Fiber,
	overrideBaseTime: boolean
): ()
	if not enableProfilerTimer then
		return
	end

	if profilerStartTime >= 0 then
		local elapsedTime_ = now() - profilerStartTime
		fiber.actualDuration += elapsedTime_
		if overrideBaseTime then
			fiber.selfBaseDuration = elapsedTime_
		end
		profilerStartTime = -1	
end
end

function recordLayoutEffectDuration(fiber: Fiber): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end

	if layoutEffectStartTime >= 0 then
		local elapsedTime_ = now() - layoutEffectStartTime

		layoutEffectStartTime = -1
		-- Store duration on the next nearest Profiler ancestor.
		
local parentFiber = fiber.return_
		while parentFiber ~= nil do
			if parentFiber.tag == Profiler then
				local parentStateNode = parentFiber.stateNode
				parentStateNode.effectDuration += elapsedTime_
				break
			end
			parentFiber = parentFiber.return_
		end
	end
end

function recordPassiveEffectDuration(fiber: Fiber): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end

	if passiveEffectStartTime >= 0 then
		local elapsedTime_ = now() - passiveEffectStartTime

		passiveEffectStartTime = -1
		-- Store duration on the next nearest Profiler ancestor.
		
local parentFiber = fiber.return_
		while parentFiber ~= nil do
			if parentFiber.tag == Profiler then
				local parentStateNode = parentFiber.stateNode
				if parentStateNode ~= nil then
					-- Detached fibers have their state node cleared out.
					-- In this case, the return pointer is also cleared out,
					-- so we won't be able to report the time spent in this Profiler's subtree.
					parentStateNode.passiveEffectDuration += elapsedTime_
				end
				break
			end
			parentFiber = parentFiber.return_
		end
	end
end

function startLayoutEffectTimer(): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end
	layoutEffectStartTime = now()
end

function startPassiveEffectTimer(): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end
	passiveEffectStartTime = now()
end

function transferActualDuration(fiber: Fiber): ()
	-- Transfer time spent rendering these children so we don't lose it
	-- after we rerender. This is used as a helper in special cases
	-- where we should count the work of multiple passes.
	local child = fiber.child
	while child do
		fiber.actualDuration += child.actualDuration
		child = child.sibling
	end
end

return {
	getCommitTime = getCommitTime,
	recordCommitTime = recordCommitTime,
	recordLayoutEffectDuration = recordLayoutEffectDuration,
	recordPassiveEffectDuration = recordPassiveEffectDuration,
	startLayoutEffectTimer = startLayoutEffectTimer,
	startPassiveEffectTimer = startPassiveEffectTimer,
	startProfilerTimer = startProfilerTimer,
	stopProfilerTimerIfRunning = stopProfilerTimerIfRunning,
	stopProfilerTimerIfRunningAndRecordDelta = stopProfilerTimerIfRunningAndRecordDelta,
	transferActualDuration = transferActualDuration,
}

end,
["react-reconciler/ReactRootTags"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/ReactRootTags.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type RootTag = number

return {
	LegacyRoot = 0,
	BlockingRoot = 1,
	ConcurrentRoot = 2,
}

end,
["react-reconciler/ReactStrictModeWarnings.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react-reconciler/src/ReactStrictModeWarnings.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
local ReactCurrentFiber = require(script.Parent:WaitForChild('ReactCurrentFiber'))
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local StrictMode = require(script.Parent:WaitForChild('ReactTypeOfMode')).StrictMode

type Set<T> = { [T]: boolean }
type Array<T> = { [number]: T }
type Map<K, V> = { [K]: V }
type FiberArray = Array<Fiber>
type FiberToFiberComponentsMap = Map<Fiber, FiberArray>

local ReactStrictModeWarnings = {
	recordUnsafeLifecycleWarnings = function(fiber: Fiber, instance: any) end,
	flushPendingUnsafeLifecycleWarnings = function() end,
	recordLegacyContextWarning = function(fiber: Fiber, instance: any) end,
	flushLegacyContextWarning = function() end,
	discardPendingWarnings = function() end,
}

if _G.__DEV__ then
	local findStrictRoot = function(fiber: Fiber): Fiber | nil
		local maybeStrictRoot 
		-- ROBLOX FIXME Luau: Luau needs to understand while not nil loops
		
local node: Fiber? = fiber
		while node ~= nil do
			if bit32.band(node.mode, StrictMode) ~= 0 then
				maybeStrictRoot = node
			end
			node = node.return_
		end

		return maybeStrictRoot
	end

	local setToSortedString = function(set): string
		local array = {}
		for key, value in set do
			table.insert(array, key)
		end
		table.sort(array)
		return table.concat(array, ", ")
	end

	local pendingComponentWillMountWarnings: Array<Fiber> = {}
	local pendingUNSAFE_ComponentWillMountWarnings: Array<Fiber> = {}
	local pendingComponentWillReceivePropsWarnings: Array<Fiber> = {}
	local pendingUNSAFE_ComponentWillReceivePropsWarnings: Array<Fiber> = {}
	local pendingComponentWillUpdateWarnings: Array<Fiber> = {}
	local pendingUNSAFE_ComponentWillUpdateWarnings: Array<Fiber> = {}

	-- Tracks components we have already warned about.
	local didWarnAboutUnsafeLifecycles = {}

	ReactStrictModeWarnings.recordUnsafeLifecycleWarnings =
		function(fiber: Fiber, instance: any)
			-- Dedupe strategy: Warn once per component.
			if didWarnAboutUnsafeLifecycles[fiber.type] then
				return
			end

			if
				typeof(instance.componentWillMount) == "function"
				-- Don't warn about react-lifecycles-compat polyfilled components.
				-- ROBLOX deviation: Lua doesn't allow fields on function
				-- instance.componentWillMount.__suppressDeprecationWarning ~= true
			then
				table.insert(pendingComponentWillMountWarnings, fiber)
			end

			if
				bit32.band(fiber.mode, StrictMode) ~= 0
				and typeof(instance.UNSAFE_componentWillMount) == "function"
			then
				table.insert(pendingUNSAFE_ComponentWillMountWarnings, fiber)
			end

			if
				typeof(instance.componentWillReceiveProps) == "function"
				-- ROBLOX deviation: Lua doesn't allow fields on function
				-- instance.componentWillReceiveProps.__suppressDeprecationWarning ~= true
			then
				table.insert(pendingComponentWillReceivePropsWarnings, fiber)
			end

			if
				bit32.band(fiber.mode, StrictMode) ~= 0
				and typeof(instance.UNSAFE_componentWillReceiveProps) == "function"
			then
				table.insert(pendingUNSAFE_ComponentWillReceivePropsWarnings, fiber)
			end

			if
				typeof(instance.componentWillUpdate) == "function"
				-- ROBLOX deviation: Lua doesn't allow fields on function
				-- instance.componentWillUpdate.__suppressDeprecationWarning ~= true
			then
				table.insert(pendingComponentWillUpdateWarnings, fiber)
			end

			if
				bit32.band(fiber.mode, StrictMode) ~= 0
				and typeof(instance.UNSAFE_componentWillUpdate) == "function"
			then
				table.insert(pendingUNSAFE_ComponentWillUpdateWarnings, fiber)
			end
		end

	ReactStrictModeWarnings.flushPendingUnsafeLifecycleWarnings = function()
		-- We do an initial pass to gather component names
		local componentWillMountUniqueNames = {}
		if #pendingComponentWillMountWarnings > 0 then
			for i, fiber in pendingComponentWillMountWarnings do
				componentWillMountUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end
			table.clear(pendingComponentWillMountWarnings)
		end

		local UNSAFE_componentWillMountUniqueNames = {}
		if #pendingUNSAFE_ComponentWillMountWarnings > 0 then
			for i, fiber in pendingUNSAFE_ComponentWillMountWarnings do
				UNSAFE_componentWillMountUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end
			table.clear(pendingUNSAFE_ComponentWillMountWarnings)
		end

		local componentWillReceivePropsUniqueNames = {}
		if #pendingComponentWillReceivePropsWarnings > 0 then
			for i, fiber in pendingComponentWillReceivePropsWarnings do
				componentWillReceivePropsUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingComponentWillReceivePropsWarnings)
		end

		local UNSAFE_componentWillReceivePropsUniqueNames = {}
		if #pendingUNSAFE_ComponentWillReceivePropsWarnings > 0 then
			for i, fiber in pendingUNSAFE_ComponentWillReceivePropsWarnings do
				UNSAFE_componentWillReceivePropsUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingUNSAFE_ComponentWillReceivePropsWarnings)
		end

		local componentWillUpdateUniqueNames = {}
		if #pendingComponentWillUpdateWarnings > 0 then
			for i, fiber in pendingComponentWillUpdateWarnings do
				componentWillUpdateUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingComponentWillUpdateWarnings)
		end

		local UNSAFE_componentWillUpdateUniqueNames = {}
		if #pendingUNSAFE_ComponentWillUpdateWarnings > 0 then
			for i, fiber in pendingUNSAFE_ComponentWillUpdateWarnings do
				UNSAFE_componentWillUpdateUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingUNSAFE_ComponentWillUpdateWarnings)
		end

		-- Finally, we flush all the warnings
		-- UNSAFE_ ones before the deprecated ones, since they'll be 'louder'
		-- deviation: use `next` to determine whether set is empty
		if next(UNSAFE_componentWillMountUniqueNames) ~= nil then
			local sortedNames = setToSortedString(UNSAFE_componentWillMountUniqueNames)
			console.error(
[[Using UNSAFE_componentWillMount in strict mode is not recommended and may indicate bugs in your code. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move code with side effects to componentDidMount, and set initial state in the constructor.

Please update the following components: %s]],
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(UNSAFE_componentWillReceivePropsUniqueNames) ~= nil then
			local sortedNames =
				setToSortedString(UNSAFE_componentWillReceivePropsUniqueNames)
			console.error(
[[Using UNSAFE_componentWillReceiveProps in strict mode is not recommended and may indicate bugs in your code. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move data fetching code or side effects to componentDidUpdate.
* If you're updating state whenever props change, refactor your code to use memoization techniques or move it to static getDerivedStateFromProps. Learn more at: https://reactjs.org/link/derived-state

Please update the following components: %s]]
,
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(UNSAFE_componentWillUpdateUniqueNames) ~= nil then
			local sortedNames = setToSortedString(UNSAFE_componentWillUpdateUniqueNames)
			console.error(
[[Using UNSAFE_componentWillUpdate in strict mode is not recommended and may indicate bugs in your code. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move data fetching code or side effects to componentDidUpdate.

Please update the following components: %s]],
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(componentWillMountUniqueNames) ~= nil then
			local sortedNames = setToSortedString(componentWillMountUniqueNames)

			-- ROBLOX TODO: Make decisions about whether or not we'll support these
			-- methods in the first place
			-- deviation: Remove some non-applicable information
			console.warn(
[[componentWillMount has been renamed, and is not recommended for use. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move code with side effects to componentDidMount, and set initial state in the constructor.
* Rename componentWillMount to UNSAFE_componentWillMount to suppress this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.

Please update the following components: %s]],
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(componentWillReceivePropsUniqueNames) ~= nil then
			local sortedNames = setToSortedString(componentWillReceivePropsUniqueNames)

			-- ROBLOX TODO: Make decisions about whether or not we'll support these
			-- methods in the first place
			-- deviation: Remove some non-applicable information
			console.warn(
[[componentWillReceiveProps has been renamed, and is not recommended for use. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move data fetching code or side effects to componentDidUpdate.
* If you're updating state whenever props change, refactor your code to use memoization techniques or move it to static getDerivedStateFromProps. Learn more at: https://reactjs.org/link/derived-state
* Rename componentWillReceiveProps to UNSAFE_componentWillReceiveProps to suppress this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.

Please update the following components: %s]]

,
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(componentWillUpdateUniqueNames) ~= nil then
			local sortedNames = setToSortedString(componentWillUpdateUniqueNames)

			-- ROBLOX TODO: Make decisions about whether or not we'll support these
			-- methods in the first place
			-- deviation: Remove some non-applicable information
			console.warn(
[[componentWillUpdate has been renamed, and is not recommended for use. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move data fetching code or side effects to componentDidUpdate.
* Rename componentWillUpdate to UNSAFE_componentWillUpdate to suppress this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.

Please update the following components: %s]],
				sortedNames
			)
		end
	end

	local pendingLegacyContextWarning: FiberToFiberComponentsMap = {}

	-- Tracks components we have already warned about.
	local didWarnAboutLegacyContext = {}

	ReactStrictModeWarnings.recordLegacyContextWarning =
		function(fiber: Fiber, instance: any)
			local strictRoot = findStrictRoot(fiber)
			if strictRoot == nil then
				console.error(
[[Expected to find a StrictMode component in a strict mode tree. This error is likely caused by a bug in React. Please file an issue.]]				

)
				return
			end

			-- Dedup strategy: Warn once per component.
			if didWarnAboutLegacyContext[fiber.type] then
				return
			end

			-- ROBLOX FIXME Luau: Luau should narrow based on the nil guard
			local warningsForRoot = pendingLegacyContextWarning[strictRoot :: Fiber]

			-- ROBLOX deviation: Lua can't have fields on functions
			if
				typeof(fiber.type) ~= "function"
				and (
					fiber.type.contextTypes ~= nil
					or fiber.type.childContextTypes ~= nil
					or (
						instance ~= nil
						and typeof(instance.getChildContext) == "function"
					)
				)
			then
				if warningsForRoot == nil then
					warningsForRoot = {}
					-- ROBLOX FIXME Luau: Luau should narrow based on the nil guard
					pendingLegacyContextWarning[strictRoot :: Fiber] = warningsForRoot
				end
				table.insert(warningsForRoot, fiber)
			end
		end

	ReactStrictModeWarnings.flushLegacyContextWarning = function()
		for strictRoot, fiberArray in pendingLegacyContextWarning do
			if #fiberArray == 0 then
				return
			end
			local firstFiber = fiberArray[1]

			local uniqueNames = {}
			for i, fiber in fiberArray do
				uniqueNames[getComponentName(fiber.type) or "Component"] = true
				didWarnAboutLegacyContext[fiber.type] = true
			end

			local sortedNames = setToSortedString(uniqueNames)

			local ok, error_ = pcall(function()
				setCurrentDebugFiberInDEV(firstFiber)
				console.error(
[[Legacy context API has been detected within a strict-mode tree.

The old API will be supported in all 16.x releases, but applications using it should migrate to the new version.

Please update the following components: %s

Learn more about this warning here: https://reactjs.org/link/legacy-context]],
					sortedNames
				)
			end)

			-- finally
			resetCurrentDebugFiberInDEV()

			if not ok then
				error(error_)
			end
		end
	end

	ReactStrictModeWarnings.discardPendingWarnings = function()
		-- ROBLOX performance? use table.clear instead of assigning new array
		table.clear(pendingComponentWillMountWarnings)
		table.clear(pendingUNSAFE_ComponentWillMountWarnings)
		table.clear(pendingComponentWillReceivePropsWarnings)
		table.clear(pendingUNSAFE_ComponentWillReceivePropsWarnings)
		table.clear(pendingComponentWillUpdateWarnings)
		table.clear(pendingUNSAFE_ComponentWillUpdateWarnings)
		table.clear(pendingLegacyContextWarning)
	end
end

return ReactStrictModeWarnings

end,
["react-reconciler/ReactTestSelectors"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/3cde22a84e246fc5361f038bf0c23405b2572c22/packages/react-reconciler/src/ReactTestSelectors.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Set<T> = { [T]: boolean }
type Array<T> = LuauPolyfill.Array<T>
type Function = (...any) -> ...any
type Object = LuauPolyfill.Object

-- local type {Fiber} = require(Packages.react-reconciler/src/ReactInternalTypes')
-- local type {Instance} = require(Packages../ReactFiberHostConfig')

-- local invariant = require(Packages.shared/invariant')
-- local {HostComponent, HostText} = require(Packages.react-reconciler/src/ReactWorkTags')
-- local getComponentName = require(Packages.shared/getComponentName')

local ReactFiberHostConfig = require(script.Parent:WaitForChild('ReactFiberHostConfig'))
local supportsTestSelectors = ReactFiberHostConfig.supportsTestSelectors
-- local {
--   findFiberRoot,
--   getBoundingRect,
--   getInstanceFromNode,
--   getTextContent,
--   isHiddenSubtree,
--   matchAccessibilityRole,
--   setFocusIfFocusable,
--   setupIntersectionObserver,
--   ,
-- } = require(Packages../ReactFiberHostConfig')

-- local COMPONENT_TYPE = 0b000
-- local HAS_PSEUDO_CLASS_TYPE = 0b001
-- local ROLE_TYPE = 0b010
-- local TEST_NAME_TYPE = 0b011
-- local TEXT_TYPE = 0b100

-- if typeof Symbol == 'function' and Symbol.for)
--   local symbolFor = Symbol.for
--   COMPONENT_TYPE = symbolFor('selector.component')
--   HAS_PSEUDO_CLASS_TYPE = symbolFor('selector.has_pseudo_class')
--   ROLE_TYPE = symbolFor('selector.role')
--   TEST_NAME_TYPE = symbolFor('selector.test_id')
--   TEXT_TYPE = symbolFor('selector.text')
-- end

-- type Type = Symbol | number

-- type ComponentSelector = {|
--   $$typeof: Type,
--   value: React$AbstractComponent<empty, mixed>,
-- |}

-- type HasPsuedoClassSelector = {|
--   $$typeof: Type,
--   value: Array<Selector>,
-- |}

-- type RoleSelector = {|
--   $$typeof: Type,
--   value: string,
-- |}

-- type TextSelector = {|
--   $$typeof: Type,
--   value: string,
-- |}

-- type TestNameSelector = {|
--   $$typeof: Type,
--   value: string,
-- |}

-- type Selector =
--   | ComponentSelector
--   | HasPsuedoClassSelector
--   | RoleSelector
--   | TextSelector
--   | TestNameSelector

local exports = {}

-- exports.createComponentSelector(
--   component: React$AbstractComponent<empty, mixed>,
-- ): ComponentSelector {
--   return {
--     $$typeof: COMPONENT_TYPE,
--     value: component,
--   }
-- end

-- exports.createHasPsuedoClassSelector(
--   selectors: Array<Selector>,
-- ): HasPsuedoClassSelector {
--   return {
--     $$typeof: HAS_PSEUDO_CLASS_TYPE,
--     value: selectors,
--   }
-- end

-- exports.createRoleSelector(role: string): RoleSelector {
--   return {
--     $$typeof: ROLE_TYPE,
--     value: role,
--   }
-- end

-- exports.createTextSelector(text: string): TextSelector {
--   return {
--     $$typeof: TEXT_TYPE,
--     value: text,
--   }
-- end

-- exports.createTestNameSelector(id: string): TestNameSelector {
--   return {
--     $$typeof: TEST_NAME_TYPE,
--     value: id,
--   }
-- end

-- function findFiberRootForHostRoot(hostRoot: Instance): Fiber {
--   local maybeFiber = getInstanceFromNode((hostRoot: any))
--   if maybeFiber ~= nil)
--     invariant(
--       typeof maybeFiber.memoizedProps['data-testname'] == 'string',
--       'Invalid host root specified. Should be either a React container or a node with a testname attribute.',
--     )
--     return ((maybeFiber: any): Fiber)
--   } else {
--     local fiberRoot = findFiberRoot(hostRoot)
--     invariant(
--       fiberRoot ~= nil,
--       'Could not find React container within specified host subtree.',
--     )
--     -- The Flow type for FiberRoot is a little funky.
--     -- createFiberRoot() cheats this by treating the root as :any and adding stateNode lazily.
--     return ((fiberRoot: any).stateNode.current: Fiber)
--   }
-- end

-- function matchSelector(fiber: Fiber, selector: Selector): boolean {
--   switch (selector.$$typeof)
--     case COMPONENT_TYPE:
--       if fiber.type == selector.value)
--         return true
--       }
--       break
--     case HAS_PSEUDO_CLASS_TYPE:
--       return hasMatchingPaths(
--         fiber,
--         ((selector: any): HasPsuedoClassSelector).value,
--       )
--     case ROLE_TYPE:
--       if fiber.tag == HostComponent)
--         local node = fiber.stateNode
--         if
--           matchAccessibilityRole(node, ((selector: any): RoleSelector).value)
--         )
--           return true
--         }
--       }
--       break
--     case TEXT_TYPE:
--       if fiber.tag == HostComponent or fiber.tag == HostText)
--         local textContent = getTextContent(fiber)
--         if
--           textContent ~= nil and
--           textContent.indexOf(((selector: any): TextSelector).value) >= 0
--         )
--           return true
--         }
--       }
--       break
--     case TEST_NAME_TYPE:
--       if fiber.tag == HostComponent)
--         local dataTestID = fiber.memoizedProps['data-testname']
--         if
--           typeof dataTestID == 'string' and
--           dataTestID.toLowerCase() ==
--             ((selector: any): TestNameSelector).value.toLowerCase()
--         )
--           return true
--         }
--       }
--       break
--     default:
--       invariant(null, 'Invalid selector type %s specified.', selector)
--       break
--   }

--   return false
-- end

-- function selectorToString(selector: Selector): string | nil {
--   switch (selector.$$typeof)
--     case COMPONENT_TYPE:
--       local displayName = getComponentName(selector.value) or 'Unknown'
--       return `<${displayName}>`
--     case HAS_PSEUDO_CLASS_TYPE:
--       return `:has(${selectorToString(selector) or ''})`
--     case ROLE_TYPE:
--       return `[role="${((selector: any): RoleSelector).value}"]`
--     case TEXT_TYPE:
--       return `"${((selector: any): TextSelector).value}"`
--     case TEST_NAME_TYPE:
--       return `[data-testname="${((selector: any): TestNameSelector).value}"]`
--     default:
--       invariant(null, 'Invalid selector type %s specified.', selector)
--       break
--   }

--   return nil
-- end

-- function findPaths(root: Fiber, selectors: Array<Selector>): Array<Fiber> {
--   local matchingFibers: Array<Fiber> = []

--   local stack = [root, 0]
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     local selectorIndex = ((stack[index++]: any): number)
--     local selector = selectors[selectorIndex]

--     if fiber.tag == HostComponent and isHiddenSubtree(fiber))
--       continue
--     } else {
--       while (selector ~= nil and matchSelector(fiber, selector))
--         selectorIndex++
--         selector = selectors[selectorIndex]
--       }
--     }

--     if selectorIndex == selectors.length)
--       matchingFibers.push(fiber)
--     } else {
--       local child = fiber.child
--       while (child ~= nil)
--         stack.push(child, selectorIndex)
--         child = child.sibling
--       }
--     }
--   }

--   return matchingFibers
-- end

-- -- Same as findPaths but with eager bailout on first match
-- function hasMatchingPaths(root: Fiber, selectors: Array<Selector>): boolean {
--   local stack = [root, 0]
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     local selectorIndex = ((stack[index++]: any): number)
--     local selector = selectors[selectorIndex]

--     if fiber.tag == HostComponent and isHiddenSubtree(fiber))
--       continue
--     } else {
--       while (selector ~= nil and matchSelector(fiber, selector))
--         selectorIndex++
--         selector = selectors[selectorIndex]
--       }
--     }

--     if selectorIndex == selectors.length)
--       return true
--     } else {
--       local child = fiber.child
--       while (child ~= nil)
--         stack.push(child, selectorIndex)
--         child = child.sibling
--       }
--     }
--   }

--   return false
-- end

-- exports.findAllNodes(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): Array<Instance> {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local root = findFiberRootForHostRoot(hostRoot)
--   local matchingFibers = findPaths(root, selectors)

--   local instanceRoots: Array<Instance> = []

--   local stack = Array.from(matchingFibers)
--   local index = 0
--   while (index < stack.length)
--     local node = ((stack[index++]: any): Fiber)
--     if node.tag == HostComponent)
--       if isHiddenSubtree(node))
--         continue
--       }
--       instanceRoots.push(node.stateNode)
--     } else {
--       local child = node.child
--       while (child ~= nil)
--         stack.push(child)
--         child = child.sibling
--       }
--     }
--   }

--   return instanceRoots
-- end

-- exports.getFindAllNodesFailureDescription(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): string | nil {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local root = findFiberRootForHostRoot(hostRoot)

--   local maxSelectorIndex: number = 0
--   local matchedNames = []

--   -- The logic of this loop should be kept in sync with findPaths()
--   local stack = [root, 0]
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     local selectorIndex = ((stack[index++]: any): number)
--     local selector = selectors[selectorIndex]

--     if fiber.tag == HostComponent and isHiddenSubtree(fiber))
--       continue
--     } else if matchSelector(fiber, selector))
--       matchedNames.push(selectorToString(selector))
--       selectorIndex++

--       if selectorIndex > maxSelectorIndex)
--         maxSelectorIndex = selectorIndex
--       }
--     }

--     if selectorIndex < selectors.length)
--       local child = fiber.child
--       while (child ~= nil)
--         stack.push(child, selectorIndex)
--         child = child.sibling
--       }
--     }
--   }

--   if maxSelectorIndex < selectors.length)
--     local unmatchedNames = []
--     for (local i = maxSelectorIndex; i < selectors.length; i++)
--       unmatchedNames.push(selectorToString(selectors[i]))
--     }

--     return (
--       'findAllNodes was able to match part of the selector:\n' +
--       `  ${matchedNames.join(' > ')}\n\n` +
--       'No matching component was found for:\n' +
--       `  ${unmatchedNames.join(' > ')}`
--     )
--   }

--   return nil
-- end

export type BoundingRect = {
	x: number,
	y: number,
	width: number,
	height: number
}

-- exports.findBoundingRects(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): Array<BoundingRect> {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local instanceRoots = findAllNodes(hostRoot, selectors)

--   local boundingRects: Array<BoundingRect> = []
--   for (local i = 0; i < instanceRoots.length; i++)
--     boundingRects.push(getBoundingRect(instanceRoots[i]))
--   }

--   for (local i = boundingRects.length - 1; i > 0; i--)
--     local targetRect = boundingRects[i]
--     local targetLeft = targetRect.x
--     local targetRight = targetLeft + targetRect.width
--     local targetTop = targetRect.y
--     local targetBottom = targetTop + targetRect.height

--     for (local j = i - 1; j >= 0; j--)
--       if i ~= j)
--         local otherRect = boundingRects[j]
--         local otherLeft = otherRect.x
--         local otherRight = otherLeft + otherRect.width
--         local otherTop = otherRect.y
--         local otherBottom = otherTop + otherRect.height

--         -- Merging all rects to the minimums set would be complicated,
--         -- but we can handle the most common cases:
--         -- 1. completely overlapping rects
--         -- 2. adjacent rects that are the same width or height (e.g. items in a list)
--         --
--         -- Even given the above constraints,
--         -- we still won't end up with the fewest possible rects without doing multiple passes,
--         -- but it's good enough for this purpose.

--         if
--           targetLeft >= otherLeft and
--           targetTop >= otherTop and
--           targetRight <= otherRight and
--           targetBottom <= otherBottom
--         )
--           -- Complete overlapping rects; remove the inner one.
--           boundingRects.splice(i, 1)
--           break
--         } else if
--           targetLeft == otherLeft and
--           targetRect.width == otherRect.width and
--           !(otherBottom < targetTop) and
--           !(otherTop > targetBottom)
--         )
--           -- Adjacent vertical rects; merge them.
--           if otherTop > targetTop)
--             otherRect.height += otherTop - targetTop
--             otherRect.y = targetTop
--           }
--           if otherBottom < targetBottom)
--             otherRect.height = targetBottom - otherTop
--           }

--           boundingRects.splice(i, 1)
--           break
--         } else if
--           targetTop == otherTop and
--           targetRect.height == otherRect.height and
--           !(otherRight < targetLeft) and
--           !(otherLeft > targetRight)
--         )
--           -- Adjacent horizontal rects; merge them.
--           if otherLeft > targetLeft)
--             otherRect.width += otherLeft - targetLeft
--             otherRect.x = targetLeft
--           }
--           if otherRight < targetRight)
--             otherRect.width = targetRight - otherLeft
--           }

--           boundingRects.splice(i, 1)
--           break
--         }
--       }
--     }
--   }

--   return boundingRects
-- end

-- exports.focusWithin(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): boolean {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local root = findFiberRootForHostRoot(hostRoot)
--   local matchingFibers = findPaths(root, selectors)

--   local stack = Array.from(matchingFibers)
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     if isHiddenSubtree(fiber))
--       continue
--     }
--     if fiber.tag == HostComponent)
--       local node = fiber.stateNode
--       if setFocusIfFocusable(node))
--         return true
--       }
--     }
--     local child = fiber.child
--     while (child ~= nil)
--       stack.push(child)
--       child = child.sibling
--     }
--   }

--   return false
-- end

local commitHooks: Array<Function> = {}

exports.onCommitRoot = function(): ()
	if supportsTestSelectors then
		for i, commitHook in commitHooks do
			commitHook()
		end
	end
end

export type IntersectionObserverOptions = Object

export type ObserveVisibleRectsCallback = (
	intersections: Array<{ ratio: number, rect: BoundingRect }>
) -> ()

-- exports.observeVisibleRects(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
--   callback: (intersections: Array<{ratio: number, rect: BoundingRect}>) => void,
--   options?: IntersectionObserverOptions,
-- ): {|disconnect: () => void|} {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local instanceRoots = findAllNodes(hostRoot, selectors)

--   local {disconnect, observe, unobserve} = setupIntersectionObserver(
--     instanceRoots,
--     callback,
--     options,
--   )

--   -- When React mutates the host environment, we may need to change what we're listening to.
--   local commitHook = () => {
--     local nextInstanceRoots = findAllNodes(hostRoot, selectors)

--     instanceRoots.forEach(target => {
--       if nextInstanceRoots.indexOf(target) < 0)
--         unobserve(target)
--       }
--     })

--     nextInstanceRoots.forEach(target => {
--       if instanceRoots.indexOf(target) < 0)
--         observe(target)
--       }
--     })
--   }

--   commitHooks.push(commitHook)

--   return {
--     disconnect: () => {
--       -- Stop listening for React mutations:
--       local index = commitHooks.indexOf(commitHook)
--       if index >= 0)
--         commitHooks.splice(index, 1)
--       }

--       -- Disconnect the host observer:
--       disconnect()
--     },
--   }
-- end

return exports

end,
["react-reconciler/ReactTypeOfMode"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/22dc2e42bdc00d87fc19c5e75fc7c0b3fdcdc572/packages/react-reconciler/src/ReactTypeOfMode.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type TypeOfMode = number

return {
	NoMode = 0b00000,
	StrictMode = 0b00001,
	-- TODO: Remove BlockingMode and ConcurrentMode by reading from the root
	-- tag instead
	BlockingMode = 0b00010,
	ConcurrentMode = 0b00100,
	ProfileMode = 0b01000,
	DebugTracingMode = 0b10000,
}

end,
["react-reconciler/ReactUpdateQueue.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactUpdateQueue.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- UpdateQueue is a linked list of prioritized updates.
--
-- Like fibers, update queues come in pairs: a current queue, which represents
-- the visible state of the screen, and a work-in-progress queue, which can be
-- mutated and processed asynchronously before it is committed — a form of
-- double buffering. If a work-in-progress render is discarded before finishing,
-- we create a new work-in-progress by cloning the current queue.
--
-- Both queues share a persistent, singly-linked list structure. To schedule an
-- update, we append it to the end of both queues. Each queue maintains a
-- pointer to first update in the persistent list that hasn't been processed.
-- The work-in-progress pointer always has a position equal to or greater than
-- the current queue, since we always work on that one. The current queue's
-- pointer is only updated during the commit phase, when we swap in the
-- work-in-progress.
--
-- For example:
--
--   Current pointer:           A - B - C - D - E - F
--   Work-in-progress pointer:              D - E - F
--                                          ^
--                                          The work-in-progress queue has
--                                          processed more updates than current.
--
-- The reason we append to both queues is because otherwise we might drop
-- updates without ever processing them. For example, if we only add updates to
-- the work-in-progress queue, some updates could be lost whenever a work-in
-- -progress render restarts by cloning from current. Similarly, if we only add
-- updates to the current queue, the updates will be lost whenever an already
-- in-progress queue commits and swaps with the current queue. However, by
-- adding to both queues, we guarantee that the update will be part of the next
-- work-in-progress. (And because the work-in-progress queue becomes the
-- current queue once it commits, there's no danger of applying the same
-- update twice.)
--
-- Prioritization
-- --------------
--
-- Updates are not sorted by priority, but by insertion; new updates are always
-- appended to the end of the list.
--
-- The priority is still important, though. When processing the update queue
-- during the render phase, only the updates with sufficient priority are
-- included in the result. If we skip an update because it has insufficient
-- priority, it remains in the queue to be processed later, during a lower
-- priority render. Crucially, all updates subsequent to a skipped update also
-- remain in the queue *regardless of their priority*. That means high priority
-- updates are sometimes processed twice, at two separate priorities. We also
-- keep track of a base state, that represents the state before the first
-- update in the queue is applied.
--
-- For example:
--
--   Given a base state of '', and the following queue of updates
--
--     A1 - B2 - C1 - D2
--
--   where the number indicates the priority, and the update is applied to the
--   previous state by appending a letter, React will process these updates as
--   two separate renders, one per distinct priority level:
--
--   First render, at priority 1:
--     Base state: ''
--     Updates: [A1, C1]
--     Result state: 'AC'
--
--   Second render, at priority 2:
--     Base state: 'A'            <-  The base state does not include C1,
--                                    because B2 was skipped.
--     Updates: [B2, C1, D2]      <-  C1 was rebased on top of B2
--     Result state: 'ABCD'
--
-- Because we process updates in insertion order, and rebase high priority
-- updates when preceding updates are skipped, the final result is deterministic
-- regardless of priority. Intermediate state may vary according to system
-- resources, but the final state is always the same.

local __DEV__ = _G.__DEV__
local __YOLO__ = _G.__YOLO__

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type Lane = ReactInternalTypes.Lane
type Lanes = ReactInternalTypes.Lanes

local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
local NoLane = ReactFiberLane.NoLane
local NoLanes = ReactFiberLane.NoLanes
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local mergeLanes = ReactFiberLane.mergeLanes

-- ROBLOX deviation: lazy instantiate to avoid circular require
local ReactFiberNewContext --= require("./ReactFiberNewContext.new.luau")
-- local enterDisallowedContextReadInDEV = ReactFiberNewContext.enterDisallowedContextReadInDEV
-- local exitDisallowedContextReadInDEV = ReactFiberNewContext.exitDisallowedContextReadInDEV
local function enterDisallowedContextReadInDEV()
	if not ReactFiberNewContext then
		ReactFiberNewContext = require(script.Parent:WaitForChild('ReactFiberNewContext.new')):: any
	end
	ReactFiberNewContext.enterDisallowedContextReadInDEV()
end
local function exitDisallowedContextReadInDEV()
	if not ReactFiberNewContext then
		ReactFiberNewContext = require(script.Parent:WaitForChild('ReactFiberNewContext.new')):: any
	end
	ReactFiberNewContext.exitDisallowedContextReadInDEV()
end
local ReactFiberFlags = require(script.Parent:WaitForChild('ReactFiberFlags'))
local Callback = ReactFiberFlags.Callback
local ShouldCapture = ReactFiberFlags.ShouldCapture
local DidCapture = ReactFiberFlags.DidCapture

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local debugRenderPhaseSideEffectsForStrictMode =
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode

local ReactTypeOfMode = require(script.Parent:WaitForChild('ReactTypeOfMode'))
local StrictMode = ReactTypeOfMode.StrictMode
-- local ReactFiberWorkLoop = require("./ReactFiberWorkLoop.new.luau")
local markSkippedUpdateLanes =
	require(script.Parent:WaitForChild('ReactFiberWorkInProgress')).markSkippedUpdateLanes

-- ROBLOX deviation START: use if-then-error, which avoid string format and function call overhead, as in React 18
-- local invariant = require("@pkg/@jsdotlua/shared").invariant
-- ROBLOX deviation END
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError

local ConsolePatchingDev = require(script.Parent.Parent:WaitForChild('shared')).ConsolePatchingDev
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

-- deviation: Common types
type Array<T> = { [number]: T }

-- ROBLOX deviation: transplants UpdateQueue<> and SharedState<> types to ReactInternalTypes for export to createReactNoop
type Update<T> = ReactInternalTypes.Update<T>
type UpdateQueue<T> = ReactInternalTypes.UpdateQueue<T>
export type SharedQueue<T> = ReactInternalTypes.SharedQueue<T>

local exports = {}

local UpdateState = 0
exports.UpdateState = UpdateState
local ReplaceState = 1
exports.ReplaceState = ReplaceState
local ForceUpdate = 2
exports.ForceUpdate = ForceUpdate
local CaptureUpdate = 3
exports.CaptureUpdate = CaptureUpdate

-- Global state that is reset at the beginning of calling `processUpdateQueue`.
-- It should only be read right after calling `processUpdateQueue`, via
-- `checkHasForceUpdateAfterProcessing`.
local hasForceUpdate = false

local didWarnUpdateInsideUpdate
local currentlyProcessingQueue: SharedQueue<any>?
-- export local resetCurrentlyProcessingQueue
if __DEV__ then
	didWarnUpdateInsideUpdate = false
	currentlyProcessingQueue = nil
	exports.resetCurrentlyProcessingQueue = function()
		currentlyProcessingQueue = nil
	end
end

-- ROBLOX performance: use a recycle pool for update tables
local poolInitSize = 210 -- TODO: Tune to LuaApps
-- local poolAdditionalSize = 0
local updatePool = table.create(poolInitSize)
local updatePoolIndex = poolInitSize
for i = 1, poolInitSize do
	updatePool[i] = {
		eventTime = -1,
		lane = -1,
		tag = -1,
		payload = nil,
		callback = nil,
		next = nil,
	}
end

local function initializeUpdateQueue<State>(fiber: Fiber): ()
	local queue: UpdateQueue<State> = {
		baseState = fiber.memoizedState,
		firstBaseUpdate = nil,
		lastBaseUpdate = nil,
		shared = {
			pending = nil,
		},
		effects = nil,
	}
	fiber.updateQueue = queue
end
exports.initializeUpdateQueue = initializeUpdateQueue

local function cloneUpdateQueue<State>(current: Fiber, workInProgress: Fiber): ()
	-- Clone the update queue from current. Unless it's already a clone.
	local queue: UpdateQueue<State> = workInProgress.updateQueue :: any
	local currentQueue: UpdateQueue<State> = current.updateQueue :: any
	if queue == currentQueue then
		-- ROBLOX deviation START: use our queue method for hot path optimizations
		local clone: UpdateQueue<State> = table.clone(currentQueue)
		-- ROBLOX deviation END
		workInProgress.updateQueue = clone
	end
end
exports.cloneUpdateQueue = cloneUpdateQueue

-- ROBLOX deviation START: add extra parameters here so updates can be create in single table ctor
local function createUpdate(
	eventTime: number,
	lane: Lane,
	payload: any?,
	callback: (() -> ...any)?
): Update<any>
	-- ROBLOX performance: Use pooled update object when available
	if updatePoolIndex > 0 then
		local update = updatePool[updatePoolIndex]
		updatePool[updatePoolIndex] = nil
		updatePoolIndex -= 1

		update.eventTime = eventTime
		update.lane = lane
		update.tag = UpdateState
		update.payload = payload
		update.callback = callback :: any

		return update :: Update<any>
	end
	-- ROBLOX deviation END

	-- ROBLOX performance FIXME: This warning is very noisy in practice and not
	-- actionable by Roact developers in any way. We should re-establish the
	-- warning once we've done some tuning and thought more about what messaging
	-- we want to convey to Roact users

	-- if __DEV__ then
	-- 	poolAdditionalSize += 1
	-- 	console.warn(
	-- 		"ReactUpdateQueue createUpdate's object pool exhausted, allocating fresh table."
	-- 			.. "\nConsider setting poolInitSize to " .. poolInitSize + poolAdditionalSize
	-- 			.. " to avoid this occurring in the future."
	-- 	)
	-- end

	local update = {
		eventTime = eventTime,
		lane = lane,

		tag = UpdateState,
		payload = payload,
		callback = callback :: any,

		next = nil,
	}
	return update :: Update<any>
end
exports.createUpdate = createUpdate

local function enqueueUpdate<State>(fiber: Fiber, update: Update<State>)
	local updateQueue = fiber.updateQueue
	if updateQueue == nil then
		-- Only occurs if the fiber has been unmounted.
		return
	end

	local sharedQueue: SharedQueue<State> = (updateQueue :: any).shared
	local pending = sharedQueue.pending
	if pending == nil then
		-- This is the first update. Create a circular list.
		update.next = update
	else
		update.next = pending.next
		pending.next = update
	end
	sharedQueue.pending = update

	if __DEV__ then
		if currentlyProcessingQueue == sharedQueue and not didWarnUpdateInsideUpdate then
			console.error(
[[An update (setState, replaceState, or forceUpdate) was scheduled from inside an update function. Update functions should be pure, with zero side-effects. Consider using componentDidUpdate or a callback.]]			



)
			didWarnUpdateInsideUpdate = true
		end
	end
end
exports.enqueueUpdate = enqueueUpdate

local function enqueueCapturedUpdate<State>(workInProgress: Fiber, capturedUpdate: Update<State>)
	-- Captured updates are updates that are thrown by a child during the render
	-- phase. They should be discarded if the render is aborted. Therefore,
	-- we should only put them on the work-in-progress queue, not the current one.
	local queue: UpdateQueue<State> = workInProgress.updateQueue :: any

	-- Check if the work-in-progress queue is a clone.
	local current = workInProgress.alternate
	if current ~= nil then
		local currentQueue: UpdateQueue<State> = current.updateQueue :: any
		if queue == currentQueue then
			-- The work-in-progress queue is the same as current. This happens when
			-- we bail out on a parent fiber that then captures an error thrown by
			-- a child. Since we want to append the update only to the work-in
			-- -progress queue, we need to clone the updates. We usually clone during
			-- processUpdateQueue, but that didn't happen in this case because we
			-- skipped over the parent when we bailed out.
			local newFirst 			
local newLast 			
local firstBaseUpdate = queue.firstBaseUpdate
			if firstBaseUpdate ~= nil then
				-- Loop through the updates and clone them.
				local update = firstBaseUpdate
				repeat
					local clone: Update<State> = {
						eventTime = update.eventTime,
						lane = update.lane,

						tag = update.tag,
						payload = update.payload,
						callback = update.callback,

						next = nil,
					}
					if newLast == nil then
						newLast = clone
						newFirst = clone
					else
						newLast.next = clone
						newLast = clone
					end
					-- ROBLOX FIXME Luau: Luau needs to support repeat until nil pattern
					update = update.next :: Update<State>
				until update == nil

				-- Append the captured update the end of the cloned list.
				if newLast == nil then
					newLast = capturedUpdate
					newFirst = capturedUpdate
				else
					newLast.next = capturedUpdate
					newLast = capturedUpdate
				end
			else
				-- There are no base updates.
				newLast = capturedUpdate
				newFirst = capturedUpdate
			end
			queue = {
				baseState = currentQueue.baseState,
				firstBaseUpdate = newFirst,
				lastBaseUpdate = newLast,
				shared = currentQueue.shared,
				effects = currentQueue.effects,
			}
			workInProgress.updateQueue = queue
			return
		end
	end

	-- Append the update to the end of the list.
	local lastBaseUpdate = queue.lastBaseUpdate
	if lastBaseUpdate == nil then
		queue.firstBaseUpdate = capturedUpdate
	else
		lastBaseUpdate.next = capturedUpdate
	end
	queue.lastBaseUpdate = capturedUpdate
end
exports.enqueueCapturedUpdate = enqueueCapturedUpdate

local function getStateFromUpdate<State>(
	workInProgress: Fiber,
	queue: UpdateQueue<State>,
	update: Update<State>,
	prevState: State,
	nextProps: any,
	instance: any
): any
	local updateTag = update.tag
	if updateTag == ReplaceState then
		local payload = update.payload
		if type(payload) == "function" then
			-- Updater function
			if __DEV__ then
				enterDisallowedContextReadInDEV()
			end
			-- ROBLOX deviation: Upstream binds this callback to the instance;
			-- in order for us to get the same behavior, we'd need to change the
			-- signature of the updater, which doesn't make sense for our case
			local nextState = payload(prevState, nextProps)
			if __DEV__ then
				if
					debugRenderPhaseSideEffectsForStrictMode
					and bit32.band(workInProgress.mode, StrictMode) ~= 0
				then
					disableLogs()
					-- ROBLOX deviation: YOLO flag for disabling pcall
					local ok, result
					if not __YOLO__ then
						ok, result = xpcall(payload, describeError, prevState, nextProps)
					else
						ok = true
						payload(prevState, nextProps)
					end
					-- finally
					reenableLogs()

					if not ok then
						error(result)
					end
				end
				exitDisallowedContextReadInDEV()
			end
			return nextState
		end
		-- State object
		return payload
	elseif updateTag == CaptureUpdate or updateTag == UpdateState then
		if updateTag == CaptureUpdate then
			workInProgress.flags = bit32.bor(
				bit32.band(workInProgress.flags, bit32.bnot(ShouldCapture)),
				DidCapture
			)
		end
		-- Intentional fallthrough
		local payload = update.payload
		local partialState
		if type(payload) == "function" then
			-- Updater function
			if __DEV__ then
				enterDisallowedContextReadInDEV()
			end
			-- ROBLOX deviation: Upstream binds this callback to the instance;
			-- in order for us to get the same behavior, we'd need to change the
			-- signature of the updater, which doesn't make sense for our case
			partialState = payload(prevState, nextProps)
			if __DEV__ then
				if
					debugRenderPhaseSideEffectsForStrictMode
					and bit32.band(workInProgress.mode, StrictMode) ~= 0
				then
					disableLogs()
					-- ROBLOX deviation: YOLO flag for disabling pcall
					local ok, result
					if not __YOLO__ then
						ok, result = xpcall(payload, describeError, prevState, nextProps)
					else
						ok = true
						payload(prevState, nextProps)
					end
					-- finally
					reenableLogs()

					if not ok then
						error(result)
					end
				end
				exitDisallowedContextReadInDEV()
			end
		else
			-- Partial state object
			partialState = payload
		end
		if partialState == nil then
			-- Null and undefined are treated as no-ops.
			return prevState
		end
		-- Merge the partial state and the previous state.
		-- ROBLOX TODO: the below optimziation doesn't work because: invalid argument #1 to 'clone' (table has a protected metatable)
		-- local newState = if prevState ~= nil then table.clone(prevState :: any) else {}
		return Object.assign({}, prevState, partialState)
	elseif updateTag == ForceUpdate then
		hasForceUpdate = true
		return prevState
	end
	return prevState
end
exports.getStateFromUpdate = getStateFromUpdate

local function processUpdateQueue<State>(
	workInProgress: Fiber,
	props: any,
	instance: any,
	renderLanes: Lanes
): ()
	-- This is always non-null on a ClassComponent or HostRoot
	local queue: UpdateQueue<State> = workInProgress.updateQueue :: any

	hasForceUpdate = false

	if __DEV__ then
		currentlyProcessingQueue = queue.shared
	end

	local firstBaseUpdate = queue.firstBaseUpdate
	local lastBaseUpdate = queue.lastBaseUpdate

	-- Check if there are pending updates. If so, transfer them to the base queue.
	local pendingQueue = queue.shared.pending
	if pendingQueue ~= nil then
		queue.shared.pending = nil

		-- The pending queue is circular. Disconnect the pointer between first
		-- and last so that it's non-circular.
		local lastPendingUpdate = pendingQueue
		local firstPendingUpdate = lastPendingUpdate.next
		lastPendingUpdate.next = nil
		-- Append pending updates to base queue
		if lastBaseUpdate == nil then
			firstBaseUpdate = firstPendingUpdate
		else
			lastBaseUpdate.next = firstPendingUpdate
		end
		lastBaseUpdate = lastPendingUpdate

		-- If there's a current queue, and it's different from the base queue, then
		-- we need to transfer the updates to that queue, too. Because the base
		-- queue is a singly-linked list with no cycles, we can append to both
		-- lists and take advantage of structural sharing.
		-- TODO: Pass `current` as argument
		local current = workInProgress.alternate
		if current ~= nil then
			-- This is always non-null on a ClassComponent or HostRoot
			local currentQueue: UpdateQueue<State> = current.updateQueue :: any
			local currentLastBaseUpdate = currentQueue.lastBaseUpdate
			if currentLastBaseUpdate ~= lastBaseUpdate then
				if currentLastBaseUpdate == nil then
					currentQueue.firstBaseUpdate = firstPendingUpdate
				else
					currentLastBaseUpdate.next = firstPendingUpdate
				end
				currentQueue.lastBaseUpdate = lastPendingUpdate
			end
		end
	end

	-- These values may change as we process the queue.
	if firstBaseUpdate ~= nil then
		-- Iterate through the list of updates to compute the result.
		local newState = queue.baseState
		-- TODO: Don't need to accumulate this. Instead, we can remove renderLanes
		-- from the original lanes.
		local newLanes = NoLanes

		local newBaseState 		
local newFirstBaseUpdate 		
local newLastBaseUpdate 
		
local update = firstBaseUpdate
		while true do
			local updateLane = update.lane
			local updateEventTime = update.eventTime
			if not isSubsetOfLanes(renderLanes, updateLane) then
				-- Priority is insufficient. Skip this update. If this is the first
				-- skipped update, the previous update/state is the new base
				-- update/state.
				local clone: Update<State> = {
					eventTime = updateEventTime,
					lane = updateLane,

					tag = update.tag,
					payload = update.payload,
					callback = update.callback,

					next = nil,
				}
				if newLastBaseUpdate == nil then
					newFirstBaseUpdate = clone
					newLastBaseUpdate = clone
					newBaseState = newState
				else
					newLastBaseUpdate.next = clone
					newLastBaseUpdate = clone
				end
				-- Update the remaining priority in the queue.
				newLanes = mergeLanes(newLanes, updateLane)
			else
				-- This update does have sufficient priority.

				if newLastBaseUpdate ~= nil then
					local clone: Update<State> = {
						eventTime = updateEventTime,
						-- This update is going to be committed so we never want uncommit
						-- it. Using NoLane works because 0 is a subset of all bitmasks, so
						-- this will never be skipped by the check above.
						lane = NoLane,

						tag = update.tag,
						payload = update.payload,
						callback = update.callback,

						next = nil,
					}
					newLastBaseUpdate.next = clone
					newLastBaseUpdate = clone
				end

				-- Process this update.
				newState = getStateFromUpdate(
					workInProgress,
					queue,
					update,
					newState,
					props,
					instance
				)
				local callback = update.callback
				if
					callback ~= nil
					-- If the update was already committed, we should not queue its
					-- callback again.
					and update.lane ~= NoLane
				then
					workInProgress.flags = bit32.bor(workInProgress.flags, Callback)
					local effects = queue.effects
					if effects == nil then
						queue.effects = { update }
					else
						table.insert(effects, update)
					end
				end
			end
			-- ROBLOX FIXME Luau: Luau needs to support repeat until nil pattern
			update = update.next :: Update<State>
			if update == nil then
				pendingQueue = queue.shared.pending
				if pendingQueue == nil then
					break
				else
					-- An update was scheduled from inside a reducer. Add the new
					-- pending updates to the end of the list and keep processing.
					local lastPendingUpdate = pendingQueue
					-- Intentionally unsound. Pending updates form a circular list, but we
					-- unravel them when transferring them to the base queue.
					local firstPendingUpdate = (
						lastPendingUpdate.next :: any
					) :: Update<State>
					lastPendingUpdate.next = nil
					update = firstPendingUpdate
					queue.lastBaseUpdate = lastPendingUpdate
					queue.shared.pending = nil
				end
			end
		end

		if newLastBaseUpdate == nil then
			newBaseState = newState
		end

		queue.baseState = (newBaseState :: any) :: State
		queue.firstBaseUpdate = newFirstBaseUpdate
		queue.lastBaseUpdate = newLastBaseUpdate

		-- Set the remaining expiration time to be whatever is remaining in the queue.
		-- This should be fine because the only two other things that contribute to
		-- expiration time are props and context. We're already in the middle of the
		-- begin phase by the time we start processing the queue, so we've already
		-- dealt with the props. Context in components that specify
		-- shouldComponentUpdate is tricky; but we'll have to account for
		-- that regardless.
		markSkippedUpdateLanes(newLanes)
		workInProgress.lanes = newLanes
		workInProgress.memoizedState = newState
	end

	if __DEV__ then
		currentlyProcessingQueue = nil
	end
end
exports.processUpdateQueue = processUpdateQueue

local function callCallback(callback, context)
	-- ROBLOX deviation START: use if-then-error, which avoid string format and function call overhead, as in React 18
	if type(callback) ~= "function" then
		error(
			string.format(
[[Invalid argument passed as callback. Expected a function. Instead received: %s]]
,
				tostring(callback)
			)
		)
		-- ROBLOX deviation END
	end
	callback(context)
end

exports.resetHasForceUpdateBeforeProcessing = function()
	hasForceUpdate = false
end

exports.checkHasForceUpdateAfterProcessing = function(): boolean
	return hasForceUpdate
end

local function commitUpdateQueue<State>(
	finishedWork: Fiber,
	finishedQueue: UpdateQueue<State>,
	instance: any
): ()
	-- Commit the effects
	local effects = finishedQueue.effects
	finishedQueue.effects = nil
	if effects ~= nil then
		for _, effect in effects do
			local callback = effect.callback
			if callback ~= nil then
				callCallback(callback, instance)
			end

			-- ROBLOX performance: return this object to the pool
			table.clear(effect)
			table.insert(updatePool, effect :: any)
			updatePoolIndex += 1
		end
	end
end
exports.commitUpdateQueue = commitUpdateQueue

return exports

end,
["react-reconciler/ReactWorkTags"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactWorkTags.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type WorkTag = number

return {
	FunctionComponent = 0,
	ClassComponent = 1,
	IndeterminateComponent = 2, -- Before we know whether it is function or class
	HostRoot = 3, -- Root of a host tree. Could be nested inside another node.
	HostPortal = 4, -- A subtree. Could be an entry point to a different renderer.
	HostComponent = 5,
	HostText = 6,
	Fragment = 7,
	Mode = 8,
	ContextConsumer = 9,
	ContextProvider = 10,
	ForwardRef = 11,
	Profiler = 12,
	SuspenseComponent = 13,
	MemoComponent = 14,
	SimpleMemoComponent = 15,
	LazyComponent = 16,
	IncompleteClassComponent = 17,
	DehydratedFragment = 18,
	SuspenseListComponent = 19,
	FundamentalComponent = 20,
	ScopeComponent = 21,
	Block = 22,
	OffscreenComponent = 23,
	LegacyHiddenComponent = 24,
}

end,
["react-reconciler/RobloxReactProfiling"]=function()
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

-- Targeted performance insights for Roblox Microprofiler

local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local ReactWorkTags = require(script.Parent:WaitForChild('ReactWorkTags'))

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot

-- ReactMicroprofilerLevel Levels --
local LEVEL_ROOTS = 1 -- Level 1: Roots + Commit time
local LEVEL_FIBERS = 10 -- Level 10: Individual Fiber "units of work"

local ReactMicroprofilerLevel = _G.__REACT_MICROPROFILER_LEVEL or 0

export type Marker = {
	id: string,
	startTime: number,
	endTime: number
}

export type SamplerCallback = (Marker) -> ()

local enableRootSampling = false
local timerSamplingCallback: SamplerCallback | nil 

function startTimerSampling(timerSamplingCallbackFn: SamplerCallback)
	if enableRootSampling then
		warn("RobloxReactProfiling Timer Sampling already running.")
	end
	enableRootSampling = true
	timerSamplingCallback = timerSamplingCallbackFn
end

function endTimerSampling()
	enableRootSampling = false
	timerSamplingCallback = nil
end

function getFirstStringKey(t: { any: any })
	for key, _ in t do
		if type(key) == "string" then
			return key
		end
	end
	return nil
end

function startTimer(marker: Marker)
	if enableRootSampling then
		marker.startTime = os.clock()
	end
end
function endTimer(marker: Marker)
	if enableRootSampling then
		marker.endTime = os.clock()
		if timerSamplingCallback then
			timerSamplingCallback(marker)
		end
	end
end

function profileRootBeforeUnitOfWork(root: FiberRoot): Marker?
	local rootFiber = root.current
	local profileId 
	
if rootFiber then
		if rootFiber.memoizedProps then
			-- expecting props table with single item
			profileId = getFirstStringKey(rootFiber.memoizedProps)
		end

		if
			profileId == nil
			and rootFiber.stateNode
			and rootFiber.stateNode.containerInfo
		then
			profileId = rootFiber.stateNode.containerInfo.Name
		end
	end

	-- note: investigate HostRoot vs HostPortal for this condition
	if profileId == "Folder" and rootFiber.child then
		local fiber = rootFiber.child
		local folderProfileId 		
if fiber.memoizedProps then
			-- expecting props table with single item
			folderProfileId = getFirstStringKey(fiber.memoizedProps)
		end

		if
			folderProfileId == nil
			and fiber.stateNode
			and fiber.stateNode.containerInfo
		then
			folderProfileId = fiber.stateNode.containerInfo.Name
		end
		if folderProfileId ~= nil then
			profileId = folderProfileId
		end
	end

	if profileId ~= nil then
		local marker = {
			id = profileId,
			startTime = 0,
			endTime = 0,
		}
		startTimer(marker)
		debug.profilebegin(profileId)
		return marker
	end

	return nil
end

function profileRootAfterYielding(marker: Marker?)
	if marker then
		endTimer(marker)
		debug.profileend()
	end
end

function profileUnitOfWorkBefore(unitOfWork: Fiber)
	local profileId = getComponentName(unitOfWork.type)

	if unitOfWork.key then
		profileId = tostring(unitOfWork.key) .. "=" .. (profileId or "?")
	end

	local rootName 	
if unitOfWork.stateNode then
		if
			unitOfWork.tag == ReactWorkTags.HostComponent
			or unitOfWork.tag == ReactWorkTags.HostText
		then
			local layerCollector =
				unitOfWork.stateNode:FindFirstAncestorWhichIsA("LayerCollector")
			if layerCollector then
				rootName = "[" .. layerCollector:GetFullName() .. "] "
			end
		end
	end

	if rootName then
		profileId = rootName .. " : " .. (profileId or "?")
	end

	if profileId ~= nil then
		debug.profilebegin(profileId)
		return true
	end

	return false
end

function profileUnitOfWorkAfter(profileRunning: boolean)
	if profileRunning then
		debug.profileend()
	end
end

function profileCommitBefore()
	debug.profilebegin("Commit")
end
function profileCommitAfter()
	debug.profileend()
end

function noop(...: unknown) end

return {
	startTimerSampling = startTimerSampling,
	endTimerSampling = endTimerSampling,
	profileRootBeforeUnitOfWork = if ReactMicroprofilerLevel >= LEVEL_ROOTS
		then profileRootBeforeUnitOfWork
		else noop,
	profileRootAfterYielding = if ReactMicroprofilerLevel >= LEVEL_ROOTS
		then profileRootAfterYielding
		else noop,
	profileUnitOfWorkBefore = if ReactMicroprofilerLevel >= LEVEL_FIBERS
		then profileUnitOfWorkBefore
		else noop,
	profileUnitOfWorkAfter = if ReactMicroprofilerLevel >= LEVEL_FIBERS
		then profileUnitOfWorkAfter
		else noop,
	profileCommitBefore = if ReactMicroprofilerLevel >= LEVEL_ROOTS
		then profileCommitBefore
		else noop,
	profileCommitAfter = if ReactMicroprofilerLevel >= LEVEL_ROOTS
		then profileCommitAfter
		else noop,
}

end,
["react-reconciler/SchedulerWithReactIntegration.new"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/SchedulerWithReactIntegration.new.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
export type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel

-- Intentionally not named imports because Rollup would use dynamic dispatch for
-- CommonJS interop named imports.
local Scheduler = require(script.Parent.Parent:WaitForChild('scheduler'))-- local __interactionsRef = require(Packages.Scheduler.tracing).__interactionsRef

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
-- local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local decoupleUpdatePriorityFromScheduler =
	ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant
local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError
local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
local SyncLanePriority = ReactFiberLane.SyncLanePriority
local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority

local Scheduler_runWithPriority = Scheduler.unstable_runWithPriority
local Scheduler_scheduleCallback = Scheduler.unstable_scheduleCallback
local Scheduler_cancelCallback = Scheduler.unstable_cancelCallback
local Scheduler_shouldYield = Scheduler.unstable_shouldYield
local Scheduler_requestPaint = Scheduler.unstable_requestPaint
local Scheduler_now = Scheduler.unstable_now
local Scheduler_getCurrentPriorityLevel = Scheduler.unstable_getCurrentPriorityLevel
local Scheduler_ImmediatePriority = Scheduler.unstable_ImmediatePriority
local Scheduler_UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
local Scheduler_NormalPriority = Scheduler.unstable_NormalPriority
local Scheduler_LowPriority = Scheduler.unstable_LowPriority
local Scheduler_IdlePriority = Scheduler.unstable_IdlePriority

-- deviation: Instead of defining these here, we require them from a small file
-- with _just_ these constant definitions; it helps us avoid a circular require
-- issue with `ReactFiberLanes`
local ReactFiberSchedulerPriorities =
	require(script.Parent:WaitForChild('ReactFiberSchedulerPriorities.roblox'))
local ImmediatePriority = ReactFiberSchedulerPriorities.ImmediatePriority
local UserBlockingPriority = ReactFiberSchedulerPriorities.UserBlockingPriority
local NormalPriority = ReactFiberSchedulerPriorities.NormalPriority
local LowPriority = ReactFiberSchedulerPriorities.LowPriority
local IdlePriority = ReactFiberSchedulerPriorities.IdlePriority
local NoPriority = ReactFiberSchedulerPriorities.NoPriority

-- deviation: common types
type Array<T> = { [number]: T }

-- deviation: pre-declare functions
local flushSyncCallbackQueueImpl

-- if enableSchedulerTracing)
--   -- Provide explicit error message when production+profiling bundle of e.g.
--   -- react-dom is used with production (non-profiling) bundle of
--   -- scheduler/tracing
--   invariant(
--     __interactionsRef ~= nil and __interactionsRef.current ~= nil,
--     'It is not supported to run the profiling version of a renderer (for ' +
--       'example, `react-dom/profiling`) without also replacing the ' +
--       '`scheduler/tracing` module with `scheduler/tracing-profiling`. Your ' +
--       'bundler might have a setting for aliasing both modules. Learn more at ' +
--       'https://reactjs.org/link/profiling',
--   )
-- end

export type SchedulerCallback = (isSync: boolean) -> SchedulerCallback | nil

-- ROBLOX deviation START: don't allow extension unless we need to
-- type SchedulerCallbackOptions = { timeout: number?, ... };
type SchedulerCallbackOptions = { timeout: number? }
-- ROBLOX deviation END
local fakeCallbackNode = {}

local shouldYield = Scheduler_shouldYield
local requestPaint
-- Fall back gracefully if we're running an older version of Scheduler.
if Scheduler_requestPaint ~= nil then
	requestPaint = Scheduler_requestPaint
else
	requestPaint = function() end
end

local syncQueue: Array<SchedulerCallback>? 
local immediateQueueCallbackNode: any? 
local isFlushingSyncQueue: boolean = false
local initialTimeMs: number = Scheduler_now()

-- -- If the initial timestamp is reasonably small, use Scheduler's `now` directly.
-- -- This will be the case for modern browsers that support `performance.now`. In
-- -- older browsers, Scheduler falls back to `Date.now`, which returns a Unix
-- -- timestamp. In that case, subtract the module initialization time to simulate
-- -- the behavior of performance.now and keep our times small enough to fit
-- -- within 32 bits.
-- -- TODO: Consider lifting this into Scheduler.
-- ROBLOX FIXME: properly account for ms vs s from tick
-- local now = initialTimeMs < 10000
--   and Scheduler_now
--   or function()
--     return Scheduler_now() - initialTimeMs
--   end

-- deviation: Roblox uses `tick` under the hood, which is more like the unix
-- timestamp behavior referenced above
local function now(): number
	return Scheduler_now() - initialTimeMs
end

local function getCurrentPriorityLevel(): ReactPriorityLevel
	local currentPriorityLevel = Scheduler_getCurrentPriorityLevel()
	if currentPriorityLevel == Scheduler_ImmediatePriority then
		return ImmediatePriority
	elseif currentPriorityLevel == Scheduler_UserBlockingPriority then
		return UserBlockingPriority
	elseif currentPriorityLevel == Scheduler_NormalPriority then
		return NormalPriority
	elseif currentPriorityLevel == Scheduler_LowPriority then
		return LowPriority
	elseif currentPriorityLevel == Scheduler_IdlePriority then
		return IdlePriority
	else
		invariant(false, "Unknown priority level.")
		-- deviation: FIXME: Luau needs explicit return here
		return NoPriority
	end
end

function reactPriorityToSchedulerPriority(reactPriorityLevel)
	if reactPriorityLevel == ImmediatePriority then
		return Scheduler_ImmediatePriority
	elseif reactPriorityLevel == UserBlockingPriority then
		return Scheduler_UserBlockingPriority
	elseif reactPriorityLevel == NormalPriority then
		return Scheduler_NormalPriority
	elseif reactPriorityLevel == LowPriority then
		return Scheduler_LowPriority
	elseif reactPriorityLevel == IdlePriority then
		return Scheduler_IdlePriority
	else
		invariant(false, "Unknown priority level.")
		-- deviation: return appeases Luau
		return nil
	end
end

-- ROBLOX FIXME Luau: should be T... but hits CLI-50289: failure to unify
local function runWithPriority<T...>(
	reactPriorityLevel: ReactPriorityLevel,
	fn: () -> T...
): ...any
	local priorityLevel = reactPriorityToSchedulerPriority(reactPriorityLevel)
	return Scheduler_runWithPriority(priorityLevel, fn)
end

local function scheduleCallback(
	reactPriorityLevel: ReactPriorityLevel,
	callback: SchedulerCallback,
	options: SchedulerCallbackOptions | nil
)
	local priorityLevel = reactPriorityToSchedulerPriority(reactPriorityLevel)
	return Scheduler_scheduleCallback(priorityLevel, callback, options)
end

local function scheduleSyncCallback(callback: SchedulerCallback)
	-- Push this callback into an internal queue. We'll flush these either in
	-- the next tick, or earlier if something calls `flushSyncCallbackQueue`.
	if syncQueue == nil then
		syncQueue = { callback }
		-- Flush the queue in the next tick, at the earliest.
		immediateQueueCallbackNode = Scheduler_scheduleCallback(
			Scheduler_ImmediatePriority,
			flushSyncCallbackQueueImpl
		)
	else
		-- Push onto existing queue. Don't need to schedule a callback because
		-- we already scheduled one when we created the queue.
		local coercedSyncQueue = syncQueue
		table.insert(coercedSyncQueue, callback)
	end
	return fakeCallbackNode
end

local function cancelCallback(callbackNode: any)
	if callbackNode ~= fakeCallbackNode then
		Scheduler_cancelCallback(callbackNode)
	end
end

local function flushSyncCallbackQueue(): boolean
	if immediateQueueCallbackNode ~= nil then
		local node = immediateQueueCallbackNode
		immediateQueueCallbackNode = nil
		Scheduler_cancelCallback(node)
	end
	return flushSyncCallbackQueueImpl()
end

flushSyncCallbackQueueImpl = function()
	if not isFlushingSyncQueue and syncQueue ~= nil then
		-- Prevent re-entrancy.
		isFlushingSyncQueue = true
		local i = 1
		if decoupleUpdatePriorityFromScheduler then
			local previousLanePriority = getCurrentUpdateLanePriority()
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok = true
			local result
			if not _G.__YOLO__ then
				-- ROBLOX performance: hoist non-throwables out of try{} to eliminate anon function
				local isSync = true
				local queue = syncQueue

				setCurrentUpdateLanePriority(SyncLanePriority)
				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediatePriority,
					-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
					function(): ...any
						for index, callback in queue do
							i = index
							repeat
								-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
								callback = callback(isSync) :: any
							until callback == nil
						end
					end
				)
				syncQueue = nil
			else
				ok = true
				local isSync = true
				local queue = syncQueue

				setCurrentUpdateLanePriority(SyncLanePriority)
				-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
				runWithPriority(ImmediatePriority, function(): ...any
					for index, callback in queue do
						i = index
						repeat
							-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
							callback = callback(isSync) :: any
						until callback == nil
						i += 1
					end
				end)
				syncQueue = nil
			end

			-- finally
			setCurrentUpdateLanePriority(previousLanePriority)
			isFlushingSyncQueue = false

			if not ok then
				-- If something throws, leave the remaining callbacks on the queue.
				if syncQueue ~= nil then
					syncQueue = Array.slice(syncQueue, i + 1)
				end
				-- Resume flushing in the next tick
				Scheduler_scheduleCallback(
					Scheduler_ImmediatePriority,
					flushSyncCallbackQueue
				)
				error(result)
			end
		else
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not _G.__YOLO__ then
				-- ROBLOX performance: hoist non-throwables out of try{} to eliminate anon function
				local isSync = true
				local queue = syncQueue

				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediatePriority,
					-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
					function(): ...any
						for index, callback in queue do
							i = index
							repeat
								-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
								callback = callback(isSync) :: any
							until callback == nil
						end
					end
				)
				syncQueue = nil
			else
				ok = true
				local isSync = true
				local queue = syncQueue
				-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
				runWithPriority(ImmediatePriority, function(): ...any
					for index, callback in queue do
						i = index
						repeat
							-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
							callback = callback(isSync) :: any
						until callback == nil
					end
				end)
				syncQueue = nil
			end

			-- finally
			isFlushingSyncQueue = false

			if not ok then
				-- If something throws, leave the remaining callbacks on the queue.
				if syncQueue ~= nil then
					syncQueue = Array.slice(syncQueue, i + 1)
				end
				-- Resume flushing in the next tick
				Scheduler_scheduleCallback(
					Scheduler_ImmediatePriority,
					flushSyncCallbackQueue
				)
				error(result)
			end
		end
		return true
	else
		return false
	end
end

return {
	ImmediatePriority = ImmediatePriority,
	UserBlockingPriority = UserBlockingPriority,
	NormalPriority = NormalPriority,
	LowPriority = LowPriority,
	IdlePriority = IdlePriority,
	NoPriority = NoPriority,

	getCurrentPriorityLevel = getCurrentPriorityLevel,
	flushSyncCallbackQueue = flushSyncCallbackQueue,
	runWithPriority = runWithPriority,
	scheduleCallback = scheduleCallback,
	scheduleSyncCallback = scheduleSyncCallback,
	cancelCallback = cancelCallback,
	now = now,
	requestPaint = requestPaint,
	shouldYield = shouldYield,
}

end,
["react-reconciler/SchedulingProfiler"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/SchedulingProfiler.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local exports = {}
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local WeakMap = LuauPolyfill.WeakMap
type WeakMap<K, V> = LuauPolyfill.WeakMap<K, V>

local ReactFiberLane = require(script.Parent:WaitForChild('ReactFiberLane'))
type Lane = ReactFiberLane.Lane
type Lanes = ReactFiberLane.Lanes

local ReactInternalTypes = require(script.Parent:WaitForChild('ReactInternalTypes'))
type Fiber = ReactInternalTypes.Fiber

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type Wakeable = ReactTypes.Wakeable

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local ReactVersion = require(script.Parent.Parent:WaitForChild('shared')).ReactVersion
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName

-- /**
--  * If performance exists and supports the subset of the User Timing API that we
--  * require.
--  */
local supportsUserTiming = _G.performance ~= nil
local performance = _G.performance
	or {
		mark = function(str)
			debug.profilebegin(str)
			debug.profileend()
		end,
	}

function formatLanes(laneOrLanes: Lane | Lanes): string
	return tostring(laneOrLanes)
end

-- Create a mark on React initialization
if enableSchedulingProfiler then
	if supportsUserTiming then
		performance.mark("--react-init-" .. tostring(ReactVersion))
	end
end

exports.markCommitStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--commit-start-" .. formatLanes(lanes))
		end
	end
end

exports.markCommitStopped = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--commit-stop")
		end
	end
end

-- ROBLOX deviation: we use our custom Map
-- local PossiblyWeakMap = typeof WeakMap === 'function' ? WeakMap : Map

-- $FlowFixMe: Flow cannot handle polymorphic WeakMaps
local wakeableIDs: WeakMap<Wakeable, number> = WeakMap.new()
local wakeableID: number = 0
function getWakeableID(wakeable: Wakeable): number
	if not wakeableIDs:has(wakeable) then
		wakeableIDs:set(wakeable, wakeableID)
		wakeableID += 1
	end
	return wakeableIDs:get(wakeable)
end

exports.markComponentSuspended = function(fiber: Fiber, wakeable: Wakeable): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			local id = getWakeableID(wakeable)
			local componentName = getComponentName(fiber.type) or "Unknown"
			-- TODO Add component stack id
			performance.mark(
				"--suspense-suspend-" .. tostring(id) .. "-" .. componentName
			)
			wakeable:andThen(function()
				performance.mark(
					"--suspense-resolved-" .. tostring(id) .. "-" .. componentName
				)
			end, function()
				performance.mark(
					"--suspense-rejected-" .. tostring(id) .. "-" .. componentName
				)
			end)
		end
	end
end

exports.markLayoutEffectsStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--layout-effects-start-" .. formatLanes(lanes))
		end
	end
end

exports.markLayoutEffectsStopped = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--layout-effects-stop")
		end
	end
end

exports.markPassiveEffectsStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--passive-effects-start-" .. formatLanes(lanes))
		end
	end
end

exports.markPassiveEffectsStopped = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--passive-effects-stop")
		end
	end
end

exports.markRenderStarted = function(lanes: Lanes): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--render-start-" .. formatLanes(lanes))
		end
	end
end

exports.markRenderYielded = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--render-yield")
		end
	end
end

exports.markRenderStopped = function(): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--render-stop")
		end
	end
end

exports.markRenderScheduled = function(lane: Lane): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			performance.mark("--schedule-render-" .. formatLanes(lane))
		end
	end
end

exports.markForceUpdateScheduled = function(fiber: Fiber, lane: Lane): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			local componentName = getComponentName(fiber.type) or "Unknown"
			-- TODO Add component stack id
			performance.mark(
				"--schedule-forced-update-" .. formatLanes(lane) .. "-" .. componentName
			)
		end
	end
end

exports.markStateUpdateScheduled = function(fiber: Fiber, lane: Lane): ()
	if enableSchedulingProfiler then
		if supportsUserTiming then
			local componentName = getComponentName(fiber.type) or "Unknown"
			-- TODO Add component stack id
			performance.mark(
				"--schedule-state-update-" .. formatLanes(lane) .. "-" .. componentName
			)
		end
	end
end

return exports

end,
}

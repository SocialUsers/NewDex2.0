-- jsdotlua/react-roblox@17.2.1; see THIRD_PARTY_NOTICES.md
return {
["react-roblox/client/ReactRoblox"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOM.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local ReactTypes = require(script.Parent.Parent.Parent:WaitForChild('shared'))
type ReactNodeList = ReactTypes.ReactNodeList
local ReactRobloxHostTypes = require(script.Parent:WaitForChild('ReactRobloxHostTypes.roblox'))
type Container = ReactRobloxHostTypes.Container

-- local '../shared/checkReact'
-- local ReactRobloxLegacy = require("./ReactRobloxLegacy")
-- local findDOMNode = ReactRobloxLegacy.findDOMNode
-- local render = ReactRobloxLegacy.render
-- local hydrate = ReactRobloxLegacy.hydrate
-- local unstable_renderSubtreeIntoContainer = ReactRobloxLegacy.unstable_renderSubtreeIntoContainer
-- local unmountComponentAtNode = ReactRobloxLegacy.unmountComponentAtNode

local ReactRobloxRoot
ReactRobloxRoot = require(script.Parent:WaitForChild('ReactRobloxRoot'))
local createRoot = ReactRobloxRoot.createRoot
local createBlockingRoot = ReactRobloxRoot.createBlockingRoot
local createLegacyRoot = ReactRobloxRoot.createLegacyRoot
local isValidContainer = ReactRobloxRoot.isValidContainer
-- local createEventHandle = require("./ReactDOMEventHandle").createEventHandle

-- ROBLOX deviation: Use the config-injecting entry point for the reconciler
local ReactReconciler = require(script.Parent.Parent:WaitForChild('ReactReconciler.roblox'))-- local batchedEventUpdates = ReactReconciler.batchedEventUpdates

local batchedUpdates = ReactReconciler.batchedUpdates
-- local discreteUpdates = ReactReconciler.discreteUpdates
-- local flushDiscreteUpdates = ReactReconciler.flushDiscreteUpdates
local flushSync = ReactReconciler.flushSync
-- local flushControlled = ReactReconciler.flushControlled
local injectIntoDevTools = ReactReconciler.injectIntoDevTools
local flushPassiveEffects = ReactReconciler.flushPassiveEffects
local IsThisRendererActing = ReactReconciler.IsThisRendererActing
-- local attemptSynchronousHydration = ReactReconciler.attemptSynchronousHydration
-- local attemptUserBlockingHydration = ReactReconciler.attemptUserBlockingHydration
-- local attemptContinuousHydration = ReactReconciler.attemptContinuousHydration
-- local attemptHydrationAtCurrentPriority = ReactReconciler.attemptHydrationAtCurrentPriority
-- local runWithPriority = ReactReconciler.runWithPriority
-- local getCurrentUpdateLanePriority = ReactReconciler.getCurrentUpdateLanePriority

local createPortalImpl = ReactReconciler.createPortal
-- local canUseDOM = require("@pkg/@jsdotlua/shared").ExecutionEnvironment.canUseDOM
local ReactVersion = require(script.Parent.Parent.Parent:WaitForChild('shared')).ReactVersion
local invariant = require(script.Parent.Parent.Parent:WaitForChild('shared')).invariant
local ReactFeatureFlags = require(script.Parent.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
-- local warnUnstableRenderSubtreeIntoContainer = ReactFeatureFlags.warnUnstableRenderSubtreeIntoContainer
local enableNewReconciler = ReactFeatureFlags.enableNewReconciler

local ReactRobloxComponentTree = require(script.Parent:WaitForChild('ReactRobloxComponentTree'))
local getInstanceFromNode = ReactRobloxComponentTree.getInstanceFromNode
local getNodeFromInstance = ReactRobloxComponentTree.getNodeFromInstance
local getFiberCurrentPropsFromNode = ReactRobloxComponentTree.getFiberCurrentPropsFromNode
local getClosestInstanceFromNode = ReactRobloxComponentTree.getClosestInstanceFromNode
-- local restoreControlledState = require("./ReactRobloxComponent").restoreControlledState

-- local ReactDOMEventReplaying = require(Packages.Parent.Parent.events.ReactDOMEventReplaying)
-- local setAttemptSynchronousHydration = ReactDOMEventReplaying.setAttemptSynchronousHydration
-- local setAttemptUserBlockingHydration = ReactDOMEventReplaying.setAttemptUserBlockingHydration
-- local setAttemptContinuousHydration = ReactDOMEventReplaying.setAttemptContinuousHydration
-- local setAttemptHydrationAtCurrentPriority = ReactDOMEventReplaying.setAttemptHydrationAtCurrentPriority
-- local queueExplicitHydrationTarget = ReactDOMEventReplaying.queueExplicitHydrationTarget
-- local setGetCurrentUpdatePriority = ReactDOMEventReplaying.setGetCurrentUpdatePriority
-- local setAttemptHydrationAtPriority = ReactDOMEventReplaying.setAttemptHydrationAtPriority

-- local setBatchingImplementation = require(Packages.Parent.Parent.events.ReactDOMUpdateBatching).setBatchingImplementation
-- local ReactDOMControlledComponent = require("./events/ReactDOMControlledComponent")
-- local setRestoreImplementation = ReactDOMControlledComponent.setRestoreImplementation
-- local enqueueStateRestore = ReactDOMControlledComponent.enqueueStateRestore
-- local restoreStateIfNeeded = ReactDOMControlledComponent.restoreStateIfNeeded

local Event = require(script.Parent.Parent.Parent:WaitForChild('shared')).Event
local Change = require(script.Parent.Parent.Parent:WaitForChild('shared')).Change
local Tag = require(script.Parent.Parent.Parent:WaitForChild('shared')).Tag

-- setAttemptSynchronousHydration(attemptSynchronousHydration)
-- setAttemptUserBlockingHydration(attemptUserBlockingHydration)
-- setAttemptContinuousHydration(attemptContinuousHydration)
-- setAttemptHydrationAtCurrentPriority(attemptHydrationAtCurrentPriority)
-- setGetCurrentUpdatePriority(getCurrentUpdateLanePriority)
-- setAttemptHydrationAtPriority(runWithPriority)

-- local didWarnAboutUnstableCreatePortal = false
-- local didWarnAboutUnstableRenderSubtreeIntoContainer = false

-- deviation: Built-ins for maps and sets are not required
-- if _G.__DEV__ then
--   if
--     typeof Map ~= 'function' or
--     -- $FlowIssue Flow incorrectly thinks Map has no prototype
--     Map.prototype == nil or
--     typeof Map.prototype.forEach ~= 'function' or
--     typeof Set ~= 'function' or
--     -- $FlowIssue Flow incorrectly thinks Set has no prototype
--     Set.prototype == nil or
--     typeof Set.prototype.clear ~= 'function' or
--     typeof Set.prototype.forEach ~= 'function'
--   )
--     console.error(
--       'React depends on Map and Set built-in types. Make sure that you load a ' +
--         'polyfill in older browsers. https://reactjs.org/link/react-polyfills',
--     )
--   end
-- end

-- setRestoreImplementation(restoreControlledState)
-- setBatchingImplementation(
--   batchedUpdates,
--   discreteUpdates,
--   flushDiscreteUpdates,
--   batchedEventUpdates
-- )

local function createPortal(
	children: ReactNodeList,
	container: Container,
	key: string?
): any
	-- ): React$Portal
	invariant(
		isValidContainer(container),
		-- ROBLOX deviation: Use roblox engine terminology
		"Target container is not a Roblox Instance."
	)
	-- TODO: pass ReactDOM portal implementation as third argument
	-- $FlowFixMe The Flow type is opaque but there's no way to actually create it.
	-- ROBLOX FIXME: luau doesn't realize that this function errors, and it's
	-- expecting us to return something. Can be removed when implementation is
	-- done.
	return createPortalImpl(children, container, nil, key)
end

-- local function scheduleHydration(target: any)
--   if target then
--     queueExplicitHydrationTarget(target)
--   end
-- end

-- local function renderSubtreeIntoContainer(
--   parentComponent: React$Component<any, any>,
--   element: React$Element<any>,
--   containerNode: Container,
--   callback: ?Function,
-- )
-- local function renderSubtreeIntoContainer(
--   parentComponent: any,
--   element: any,
--   containerNode: Container,
--   callback: any
-- )
--   if _G.__DEV__ then
--     if
--       warnUnstableRenderSubtreeIntoContainer and
--       not didWarnAboutUnstableRenderSubtreeIntoContainer
--     then
--       didWarnAboutUnstableRenderSubtreeIntoContainer = true
--       console.warn(
--         "ReactDOM.unstable_renderSubtreeIntoContainer() is deprecated " ..
--           "and will be removed in a future major release. Consider using " ..
--           "React Portals instead."
--       )
--     end
--   end
--   return unstable_renderSubtreeIntoContainer(
--     parentComponent,
--     element,
--     containerNode,
--     callback
--   )
-- end

-- local function unstable_createPortal(
--   children: ReactNodeList,
--   container: Container,
--   key: string?
-- )
--   if _G.__DEV__ then
--     if not didWarnAboutUnstableCreatePortal then
--       didWarnAboutUnstableCreatePortal = true
--       console.warn(
--         "The ReactDOM.unstable_createPortal() alias has been deprecated, " ..
--           "and will be removed in React 18+. Update your code to use " ..
--           "ReactDOM.createPortal() instead. It has the exact same API, " ..
--           "but without the \"unstable_\" prefix."
--       )
--     end
--   end
--   return createPortal(children, container, key)
-- end

local Internals = {
	-- Keep in sync with ReactTestUtils.js, and ReactTestUtilsAct.js.
	-- This is an array for better minification.
	Events = {
		getInstanceFromNode = getInstanceFromNode,
		getNodeFromInstance = getNodeFromInstance,
		getFiberCurrentPropsFromNode = getFiberCurrentPropsFromNode,
		-- enqueueStateRestore = enqueueStateRestore,
		-- restoreStateIfNeeded = restoreStateIfNeeded,
		flushPassiveEffects = flushPassiveEffects,
		-- TODO: This is related to `act`, not events. Move to separate key?
		IsThisRendererActing = IsThisRendererActing,
	},
}

local exports = {
	createPortal = createPortal,
	unstable_batchedUpdates = batchedUpdates,
	flushSync = flushSync,
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = Internals,
	version = ReactVersion,
	-- Disabled behind disableLegacyReactDOMAPIs
	-- findDOMNode = findDOMNode,
	-- hydrate = hydrate,
	-- render = render,
	-- unmountComponentAtNode = unmountComponentAtNode,
	-- exposeConcurrentModeAPIs
	createRoot = createRoot,
	createBlockingRoot = createBlockingRoot,
	createLegacyRoot = createLegacyRoot,
	-- unstable_flushControlled = flushControlled,
	-- unstable_scheduleHydration = scheduleHydration,
	-- Disabled behind disableUnstableRenderSubtreeIntoContainer
	-- unstable_renderSubtreeIntoContainer = renderSubtreeIntoContainer,
	-- Disabled behind disableUnstableCreatePortal
	-- Temporary alias since we already shipped React 16 RC with it.
	-- TODO: remove in React 18.
	-- unstable_createPortal = unstable_createPortal,
	-- enableCreateEventHandleAPI
	-- unstable_createEventHandle = createEventHandle,
	-- TODO: Remove this once callers migrate to alternatives.
	-- This should only be used by React internals.
	-- unstable_runWithPriority = runWithPriority,

	-- ROBLOX deviation: Export logic attached from Roact

	-- ROBLOX FIXME: Is there a better way to provide this? Exposing these here
	-- means that a large number of react components that wouldn't otherwise need
	-- to import `ReactRoblox` will need to do so in order to set events/change
	Event = Event,
	Change = Change,
	Tag = Tag,
	unstable_isNewReconciler = enableNewReconciler,

	-- ROBLOX deviation: Export `act` function for testing purposes; in
	-- production (a.k.a. scheduler isn't mocked), give an instructive error
	act = function(_: () -> ()): ()
		error(
[[ReactRoblox.act is only available in testing environments, not production. Enable the `__ROACT_17_MOCK_SCHEDULER__` global in your test configuration in order to use `act`.]]		


)
	end,
}

if _G.__ROACT_17_MOCK_SCHEDULER__ then
	-- ROBLOX deviation: When the __ROACT_17_MOCK_SCHEDULER__ is enabled, we
	-- re-export the `act` function from ReactReconciler. The global will
	-- additionally force the scheduler to use the mock interface
	exports.act = ReactReconciler.act
end

-- ROBLOX deviation: we don't currently implement the logic below that uses this
-- value
local _foundDevTools = injectIntoDevTools({
	findFiberByHostInstance = getClosestInstanceFromNode,
	bundleType = if _G.__DEV__ then 1 else 0,
	version = ReactVersion,
	rendererPackageName = "ReactRoblox",
})

if _G.__DEV__ then
	-- if not foundDevTools and canUseDOM and window.top == window.self then
	--   If we're in Chrome or Firefox, provide a download link if not installed.
	--   if
	--     (navigator.userAgent.indexOf('Chrome') > -1 and
	--       navigator.userAgent.indexOf('Edge') == -1) or
	--     navigator.userAgent.indexOf('Firefox') > -1
	--   )
	--     local protocol = window.location.protocol
	--     -- Don't warn in exotic cases like chrome-extension://.
	--     if /^(https?|file):$/.test(protocol))
	--       -- eslint-disable-next-line react-internal/no-production-logging
	--       console.info(
	--         '%cDownload the React DevTools ' +
	--           'for a better development experience: ' +
	--           'https://reactjs.org/link/react-devtools' +
	--           (protocol == 'file:'
	--             ? '\nYou might need to use a local HTTP server (instead of file://): ' +
	--               'https://reactjs.org/link/react-devtools-faq'
	--             : ''),
	--         'font-weight:bold',
	--       )
	--     end
	--   end
	-- end
end

exports.robloxReactProfiling = ReactReconciler.robloxReactProfiling

return exports

end,
["react-roblox/client/ReactRobloxComponent"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOMComponent.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local LuauPolyfill = require(script.Parent.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object

local RobloxComponentProps = require(script.Parent:WaitForChild('roblox'):WaitForChild('RobloxComponentProps'))

local ReactRobloxHostTypes = require(script.Parent:WaitForChild('ReactRobloxHostTypes.roblox'))
type HostInstance = ReactRobloxHostTypes.HostInstance

-- deviation: Essentially a placeholder for dom-specific logic, taking the place
-- of ReactDOMComponent. Most of the logic will differ pretty dramatically

type Array<T> = { [number]: T }
type Object = { [any]: any }

local exports: { [string]: any } = {}

exports.setInitialProperties = RobloxComponentProps.setInitialProperties

-- Calculate the diff between the two objects.
local function diffProperties(
	domElement: HostInstance,
	tag: string,
	lastRawProps: Object,
	nextRawProps: Object,
	rootContainerElement: HostInstance
): (nil | Array<any>)
	-- if _G.__DEV__ then
	--   validatePropertiesInDevelopment(tag, nextRawProps)
	-- end

	-- ROBLOX FIXME: Type refinement
	-- local updatePayload: nil | Array<any> = nil
	local updatePayload 
	
local lastProps = lastRawProps
	local nextProps = nextRawProps
	-- local lastProps: Object
	-- local nextProps: Object
	-- switch (tag) {
	--   case 'input':
	--     lastProps = ReactDOMInputGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMInputGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   case 'option':
	--     lastProps = ReactDOMOptionGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMOptionGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   case 'select':
	--     lastProps = ReactDOMSelectGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMSelectGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   case 'textarea':
	--     lastProps = ReactDOMTextareaGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMTextareaGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   default:
	--     lastProps = lastRawProps;
	--     nextProps = nextRawProps;
	--     if (
	--       typeof lastProps.onClick !== 'function' &&
	--       typeof nextProps.onClick === 'function'
	--     ) {
	--       // TODO: This cast may not be sound for SVG, MathML or custom elements.
	--       trapClickOnNonInteractiveElement(((domElement: any): HTMLElement));
	--     }
	--     break;
	-- }

	-- assertValidProps(tag, nextProps);

	-- let propKey;
	-- let styleName;
	-- let styleUpdates = null;
	for propKey, _ in lastProps do
		if nextProps[propKey] ~= nil then
			continue
		end
		-- if (propKey === STYLE) {
		--   const lastStyle = lastProps[propKey];
		--   for (styleName in lastStyle) {
		--     if (lastStyle.hasOwnProperty(styleName)) {
		--       if (!styleUpdates) {
		--         styleUpdates = {};
		--       }
		--       styleUpdates[styleName] = '';
		--     }
		--   }
		-- } else if (propKey === DANGEROUSLY_SET_INNER_HTML || propKey === CHILDREN) {
		--   // Noop. This is handled by the clear text mechanism.
		-- } else if (
		--   propKey === SUPPRESS_CONTENT_EDITABLE_WARNING ||
		--   propKey === SUPPRESS_HYDRATION_WARNING
		-- ) {
		--   // Noop
		-- } else if (propKey === AUTOFOCUS) {
		--   // Noop. It doesn't work on updates anyway.
		-- } else if (registrationNameDependencies.hasOwnProperty(propKey)) {
		--   // This is a special case. If any listener updates we need to ensure
		--   // that the "current" fiber pointer gets updated so we need a commit
		--   // to update this element.
		--   if (!updatePayload) {
		--     updatePayload = [];
		--   }
		-- } else {
		-- For all other deleted properties we add it to the queue. We use
		-- the allowed property list in the commit phase instead.
		-- ROBLOX performance: prealloc table size 2 for these 2 items at least
		updatePayload = updatePayload or table.create(2)
		table.insert(updatePayload, propKey)
		table.insert(updatePayload, Object.None)
		-- }
	end
	for propKey, nextProp in nextProps do
		local lastProp = if lastProps ~= nil then lastProps[propKey] else nil
		if nextProp == lastProp then
			continue
		end
		-- if (propKey === STYLE) {
		--   if (__DEV__) {
		--     if (nextProp) {
		--       // Freeze the next style object so that we can assume it won't be
		--       // mutated. We have already warned for this in the past.
		--       Object.freeze(nextProp);
		--     }
		--   }
		--   if (lastProp) {
		--     // Unset styles on `lastProp` but not on `nextProp`.
		--     for (styleName in lastProp) {
		--       if (
		--         lastProp.hasOwnProperty(styleName) &&
		--         (!nextProp || !nextProp.hasOwnProperty(styleName))
		--       ) {
		--         if (!styleUpdates) {
		--           styleUpdates = {};
		--         }
		--         styleUpdates[styleName] = '';
		--       }
		--     }
		--     // Update styles that changed since `lastProp`.
		--     for (styleName in nextProp) {
		--       if (
		--         nextProp.hasOwnProperty(styleName) &&
		--         lastProp[styleName] !== nextProp[styleName]
		--       ) {
		--         if (!styleUpdates) {
		--           styleUpdates = {};
		--         }
		--         styleUpdates[styleName] = nextProp[styleName];
		--       }
		--     }
		--   } else {
		--     // Relies on `updateStylesByID` not mutating `styleUpdates`.
		--     if (!styleUpdates) {
		--       if (!updatePayload) {
		--         updatePayload = [];
		--       }
		--       updatePayload.push(propKey, styleUpdates);
		--     }
		--     styleUpdates = nextProp;
		--   }
		-- } else if (propKey === DANGEROUSLY_SET_INNER_HTML) {
		--   const nextHtml = nextProp ? nextProp[HTML] : undefined;
		--   const lastHtml = lastProp ? lastProp[HTML] : undefined;
		--   if (nextHtml != null) {
		--     if (lastHtml !== nextHtml) {
		--       (updatePayload = updatePayload || []).push(propKey, nextHtml);
		--     }
		--   } else {
		--     // TODO: It might be too late to clear this if we have children
		--     // inserted already.
		--   }
		-- } else if (propKey === CHILDREN) {
		--   if (typeof nextProp === 'string' || typeof nextProp === 'number') {
		--     (updatePayload = updatePayload || []).push(propKey, '' + nextProp);
		--   }
		-- } else if (
		--   propKey === SUPPRESS_CONTENT_EDITABLE_WARNING ||
		--   propKey === SUPPRESS_HYDRATION_WARNING
		-- ) {
		--   // Noop
		-- } else if (registrationNameDependencies.hasOwnProperty(propKey)) {
		--   if (nextProp != null) {
		--     // We eagerly listen to this even though we haven't committed yet.
		--     if (__DEV__ && typeof nextProp !== 'function') {
		--       warnForInvalidEventListener(propKey, nextProp);
		--     }
		--     if (!enableEagerRootListeners) {
		--       ensureListeningTo(rootContainerElement, propKey, domElement);
		--     } else if (propKey === 'onScroll') {
		--       listenToNonDelegatedEvent('scroll', domElement);
		--     }
		--   }
		--   if (!updatePayload && lastProp !== nextProp) {
		--     // This is a special case. If any listener updates we need to ensure
		--     // that the "current" props pointer gets updated so we need a commit
		--     // to update this element.
		--     updatePayload = [];
		--   }
		-- } else if (
		--   typeof nextProp === 'object' &&
		--   nextProp !== null &&
		--   nextProp.$$typeof === REACT_OPAQUE_ID_TYPE
		-- ) {
		--   // If we encounter useOpaqueReference's opaque object, this means we are hydrating.
		--   // In this case, call the opaque object's toString function which generates a new client
		--   // ID so client and server IDs match and throws to rerender.
		--   nextProp.toString();
		-- } else {
		-- For any other property we always add it to the queue and then we
		-- filter it out using the allowed property list during the commit.
		-- ROBLOX performance: prealloc table size 2 for these 2 items at least
		-- ROBLOX performance TODO: don't create a table here, return multiple values!
		updatePayload = updatePayload or table.create(2)
		table.insert(updatePayload, propKey)
		table.insert(updatePayload, nextProp)
		-- }
	end
	-- if (styleUpdates) {
	--   if (__DEV__) {
	--     validateShorthandPropertyCollisionInDev(styleUpdates, nextProps[STYLE]);
	--   }
	--   (updatePayload = updatePayload || []).push(STYLE, styleUpdates);
	-- }
	return updatePayload
end
exports.diffProperties = diffProperties
exports.updateProperties = RobloxComponentProps.updateProperties
exports.cleanupHostComponent = RobloxComponentProps.cleanupHostComponent

return exports

end,
["react-roblox/client/ReactRobloxComponentTree"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOMComponentTree.js
-- ROBLOX upstream: https://github.com/facebook/react/blob/efd8f6442d1aa7c4566fe812cba03e7e83aaccc3/packages/react-native-renderer/src/ReactNativeComponentTree.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactRobloxHostTypes = require(script.Parent:WaitForChild('ReactRobloxHostTypes.roblox'))
type HostInstance = ReactRobloxHostTypes.HostInstance
type TextInstance = ReactRobloxHostTypes.TextInstance
type SuspenseInstance = ReactRobloxHostTypes.SuspenseInstance
type Container = ReactRobloxHostTypes.Container
type Props = ReactRobloxHostTypes.Props

local ReactInternalTypes = require(script.Parent.Parent.Parent:WaitForChild('react-reconciler'))
type Fiber = ReactInternalTypes.Fiber
local Shared = require(script.Parent.Parent.Parent:WaitForChild('shared'))
type ReactScopeInstance = Shared.ReactScopeInstance
-- local type {
--   ReactDOMEventHandle,
--   ReactDOMEventHandleListener,
-- } = require(Packages.../shared/ReactDOMTypes'
-- local type {
--   Container,
--   TextInstance,
--   Instance,
--   SuspenseInstance,
--   Props,
-- } = require(Packages../ReactDOMHostConfig'

local ReactWorkTags
local HostComponent
local HostText
local HostRoot
local SuspenseComponent

local getParentSuspenseInstance
local invariant = Shared.invariant
-- local {enableScopeAPI} = require(Packages.shared/ReactFeatureFlags'

local exports: { [any]: any } = {}

-- ROBLOX deviation: Use internal maps, since we can't set properties on Containers
-- (which are Instances). We might consider using the Attributes feature for
-- this when it releases
local containerToRoot: { [Container]: Fiber } = {}
local instanceToFiber: { [HostInstance | SuspenseInstance | ReactScopeInstance]: Fiber } =
	{}
local instanceToProps: { [HostInstance | SuspenseInstance]: Props } = {}

local randomKey = string.sub(tostring(math.random()), 3)
local internalInstanceKey = "__reactFiber$" .. randomKey
local internalContainerInstanceKey = "__reactContainer$" .. randomKey
-- local internalPropsKey = "__reactProps$" .. randomKey
-- local internalEventHandlersKey = '__reactEvents$' + randomKey
-- local internalEventHandlerListenersKey = '__reactListeners$' + randomKey
-- local internalEventHandlesSetKey = '__reactHandles$' + randomKey

exports.precacheFiberNode =
	function(hostInst: Fiber, node: HostInstance | SuspenseInstance | ReactScopeInstance)
		instanceToFiber[node] = hostInst
	end

exports.uncacheFiberNode =
	function(node: HostInstance | SuspenseInstance | ReactScopeInstance)
		instanceToFiber[node] = nil
		instanceToProps[node] = nil
	end

exports.markContainerAsRoot = function(hostRoot: Fiber, node: Container)
	-- deviation: Use our module-level map
	containerToRoot[node] = hostRoot
	-- node[internalContianerInstanceKey] = hostRoot
end

exports.unmarkContainerAsRoot = function(node: Container)
	-- deviation: Use our module-level map
	containerToRoot[node] = nil
	-- node[internalContainerInstanceKey] = nil
end

exports.isContainerMarkedAsRoot = function(node: Container): boolean
	-- deviation: Use our module-level map
	return not not containerToRoot[node]
	-- return not not node[internalContainerInstanceKey]
end

-- Given a Roblox node, return the closest HostComponent or HostText fiber ancestor.
-- If the target node is part of a hydrated or not yet rendered subtree, then
-- this may also return a SuspenseComponent or HostRoot to indicate that.
-- Conceptually the HostRoot fiber is a child of the Container node. So if you
-- pass the Container node as the targetNode, you will not actually get the
-- HostRoot back. To get to the HostRoot, you need to pass a child of it.
-- The same thing applies to Suspense boundaries.
-- ROBLOX TODO: This function is untested and may not work!
exports.getClosestInstanceFromNode = function(targetNode: Instance): Fiber?
	-- ROBLOX deviation: Use internal maps since we can't set properties on Containers
	local targetInst = instanceToFiber[targetNode]
	if targetInst then
		-- Don't return HostRoot or SuspenseComponent here.
		return targetInst
	end
	-- If the direct event target isn't a React owned DOM node, we need to look
	-- to see if one of its parents is a React owned DOM node.
	local parentNode = targetNode.Parent
	while parentNode do
		-- We'll check if this is a container root that could include
		-- React nodes in the future. We need to check this first because
		-- if we're a child of a dehydrated container, we need to first
		-- find that inner container before moving on to finding the parent
		-- instance. Note that we don't check this field on  the targetNode
		-- itself because the fibers are conceptually between the container
		-- node and the first child. It isn't surrounding the container node.
		-- If it's not a container, we check if it's an instance.
		targetInst = instanceToFiber[parentNode]
		if targetInst then
			-- Since this wasn't the direct target of the event, we might have
			-- stepped past dehydrated DOM nodes to get here. However they could
			-- also have been non-React nodes. We need to answer which one.
			-- If we the instance doesn't have any children, then there can't be
			-- a nested suspense boundary within it. So we can use this as a fast
			-- bailout. Most of the time, when people add non-React children to
			-- the tree, it is using a ref to a child-less DOM node.
			-- Normally we'd only need to check one of the fibers because if it
			-- has ever gone from having children to deleting them or vice versa
			-- it would have deleted the dehydrated boundary nested inside already.
			-- However, since the HostRoot starts out with an alternate it might
			-- have one on the alternate so we need to check in case this was a
			-- root.
			local alternate = targetInst.alternate
			if
				targetInst.child ~= nil
				or (alternate ~= nil and alternate.child ~= nil)
			then
				-- ROBLOX deviation: lazy initialize to work around circular dependency
				if getParentSuspenseInstance == nil then
					getParentSuspenseInstance = (require(
						script.Parent.ReactRobloxHostConfig
					) :: any).getParentSuspenseInstance
				end

				-- Next we need to figure out if the node that skipped past is
				-- nested within a dehydrated boundary and if so, which one.
				local suspenseInstance = getParentSuspenseInstance(targetNode)
				while suspenseInstance ~= nil do
					-- We found a suspense instance. That means that we haven't
					-- hydrated it yet. Even though we leave the comments in the
					-- DOM after hydrating, and there are boundaries in the DOM
					-- that could already be hydrated, we wouldn't have found them
					-- through this pass since if the target is hydrated it would
					-- have had an internalInstanceKey on it.
					-- Let's get the fiber associated with the SuspenseComponent
					-- as the deepest instance.
					local targetSuspenseInst = instanceToFiber[suspenseInstance]
					if targetSuspenseInst then
						return targetSuspenseInst
					end
					-- If we don't find a Fiber on the comment, it might be because
					-- we haven't gotten to hydrate it yet. There might still be a
					-- parent boundary that hasn't above this one so we need to find
					-- the outer most that is known.
					suspenseInstance = getParentSuspenseInstance(suspenseInstance)
					-- If we don't find one, then that should mean that the parent
					-- host component also hasn't hydrated yet. We can return it
					-- below since it will bail out on the isMounted check later.
				end
			end
			return targetInst
		end
		targetNode = parentNode
		parentNode = targetNode.Parent
	end
	return nil
end

--[[*
 * Given a Roblox node, return the Roblox Component
 * instance, or nil if the node was not rendered by this React.
 ]]
exports.getInstanceFromNode = function(node): Fiber?
	-- ROBLOX deviation: lazy initialize to avoid circular dependency
	if ReactWorkTags == nil then
		local ReactReconciler = require(script.Parent.Parent:WaitForChild('ReactReconciler.roblox')):: any
		ReactWorkTags = ReactReconciler.ReactWorkTags

		HostComponent = ReactWorkTags.HostComponent
		HostText = ReactWorkTags.HostComponent
		HostRoot = ReactWorkTags.HostComponent
		SuspenseComponent = ReactWorkTags.HostComponent
	end

	local inst = (node :: any)[internalInstanceKey]
		or (node :: any)[internalContainerInstanceKey]
	if inst then
		if
			inst.tag == HostComponent
			or inst.tag == HostText
			or inst.tag == SuspenseComponent
			or inst.tag == HostRoot
		then
			return inst
		else
			return nil
		end
	end
	return nil
end

--[[*
 * Given a ReactDOMComponent or ReactDOMTextComponent, return the corresponding
 * DOM node.
 ]]
exports.getNodeFromInstance = function(inst: Fiber): Instance | TextInstance
	if inst.tag == HostComponent or inst.tag == HostText then
		-- In Fiber this, is just the state node right now. We assume it will be
		-- a host component or host text.
		return inst.stateNode
	end

	-- Without this first invariant, passing a non-DOM-component triggers the next
	-- invariant for a missing parent, which is super confusing.
	invariant(false, "getNodeFromInstance: Invalid argument.")
	-- ROBLOX deviation: Luau analysis doesn't understand that invariant(false,...) is always-throw
	error("getNodeFromInstance: Invalid argument.")
end

exports.getFiberCurrentPropsFromNode =
	function(node: Instance | TextInstance | SuspenseInstance): Props
		return instanceToProps[node]
	end

exports.updateFiberProps = function(node: Instance | SuspenseInstance, props: Props)
	instanceToProps[node] = props
end

-- exports.getEventListenerSet(node: EventTarget): Set<string> {
--   local elementListenerSet = (node: any)[internalEventHandlersKey]
--   if elementListenerSet == undefined)
--     elementListenerSet = (node: any)[internalEventHandlersKey] = new Set()
--   end
--   return elementListenerSet
-- end

-- exports.getFiberFromScopeInstance(
--   scope: ReactScopeInstance,
-- ): nil | Fiber {
--   if enableScopeAPI)
--     return (scope: any)[internalInstanceKey] or nil
--   end
--   return nil
-- end

-- exports.setEventHandlerListeners(
--   scope: EventTarget | ReactScopeInstance,
--   listeners: Set<ReactDOMEventHandleListener>,
-- ): void {
--   (scope: any)[internalEventHandlerListenersKey] = listeners
-- end

-- exports.getEventHandlerListeners(
--   scope: EventTarget | ReactScopeInstance,
-- ): nil | Set<ReactDOMEventHandleListener> {
--   return (scope: any)[internalEventHandlerListenersKey] or nil
-- end

-- exports.addEventHandleToTarget(
--   target: EventTarget | ReactScopeInstance,
--   eventHandle: ReactDOMEventHandle,
-- ): void {
--   local eventHandles = (target: any)[internalEventHandlesSetKey]
--   if eventHandles == undefined)
--     eventHandles = (target: any)[internalEventHandlesSetKey] = new Set()
--   end
--   eventHandles.add(eventHandle)
-- end

-- exports.doesTargetHaveEventHandle(
--   target: EventTarget | ReactScopeInstance,
--   eventHandle: ReactDOMEventHandle,
-- ): boolean {
--   local eventHandles = (target: any)[internalEventHandlesSetKey]
--   if eventHandles == undefined)
--     return false
--   end
--   return eventHandles.has(eventHandle)
-- end

return exports

end,
["react-roblox/client/ReactRobloxHostConfig"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOMHostConfig.js
-- ROBLOX upstream: https://github.com/facebook/react/blob/efd8f6442d1aa7c4566fe812cba03e7e83aaccc3/packages/react-native-renderer/src/ReactNativeHostConfig.js
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

local CollectionService = game:GetService("CollectionService")
local LuauPolyfill = require(script.Parent.Parent.Parent:WaitForChild('luau-polyfill'))
local inspect = LuauPolyfill.util.inspect
local console = require(script.Parent.Parent.Parent:WaitForChild('shared')).console
local Object = LuauPolyfill.Object
local setTimeout = LuauPolyfill.setTimeout
local clearTimeout = LuauPolyfill.clearTimeout

-- local type {DOMEventName} = require(Packages.../events/DOMEventNames')
-- local type {Fiber, FiberRoot} = require(Packages.react-reconciler/src/ReactInternalTypes')
-- local type {
--   BoundingRect,
--   IntersectionObserverOptions,
--   ObserveVisibleRectsCallback,
-- } = require(Packages.react-reconciler/src/ReactTestSelectors')
local ReactRobloxHostTypes = require(script.Parent:WaitForChild('ReactRobloxHostTypes.roblox'))
type RootType = ReactRobloxHostTypes.RootType
type Container = ReactRobloxHostTypes.Container
type HostInstance = ReactRobloxHostTypes.HostInstance
type SuspenseInstance = ReactRobloxHostTypes.SuspenseInstance
type TextInstance = ReactRobloxHostTypes.TextInstance
type Props = ReactRobloxHostTypes.Props
type Type = ReactRobloxHostTypes.Type
type HostContext = ReactRobloxHostTypes.HostContext

-- local type {ReactScopeInstance} = require(Packages.shared/ReactTypes')
-- local type {ReactDOMFundamentalComponentInstance} = require(Packages.../shared/ReactDOMTypes')

local ReactRobloxComponentTree = require(script.Parent:WaitForChild('ReactRobloxComponentTree'))
local precacheFiberNode = ReactRobloxComponentTree.precacheFiberNode
local uncacheFiberNode = ReactRobloxComponentTree.uncacheFiberNode
local updateFiberProps = ReactRobloxComponentTree.updateFiberProps
-- local getClosestInstanceFromNode = ReactRobloxComponentTree.getClosestInstanceFromNode
-- local getFiberFromScopeInstance = ReactRobloxComponentTree.getFiberFromScopeInstance
-- local getInstanceFromNodeDOMTree = ReactRobloxComponentTree.getInstanceFromNode
-- local isContainerMarkedAsRoot = ReactRobloxComponentTree.isContainerMarkedAsRoot

-- local {hasRole} = require(Packages../DOMAccessibilityRoles')
local ReactRobloxComponent = require(script.Parent:WaitForChild('ReactRobloxComponent'))-- local createElement = ReactRobloxComponent.createElement
-- local createTextNode = ReactRobloxComponent.createTextNode

local setInitialProperties = ReactRobloxComponent.setInitialProperties
local diffProperties = ReactRobloxComponent.diffProperties
local updateProperties = ReactRobloxComponent.updateProperties
local cleanupHostComponent = ReactRobloxComponent.cleanupHostComponent
-- local diffHydratedProperties = ReactRobloxComponent.diffHydratedProperties
-- local diffHydratedText = ReactRobloxComponent.diffHydratedText
-- local trapClickOnNonInteractiveElement = ReactRobloxComponent.trapClickOnNonInteractiveElement
-- local warnForUnmatchedText = ReactRobloxComponent.warnForUnmatchedText
-- local warnForDeletedHydratableElement = ReactRobloxComponent.warnForDeletedHydratableElement
-- local warnForDeletedHydratableText = ReactRobloxComponent.warnForDeletedHydratableText
-- local warnForInsertedHydratedElement = ReactRobloxComponent.warnForInsertedHydratedElement
-- local warnForInsertedHydratedText = ReactRobloxComponent.warnForInsertedHydratedText
-- local {getSelectionInformation, restoreSelection} = require(Packages../ReactInputSelection')
-- local setTextContent = require(Packages../setTextContent')
-- local {validateDOMNesting, updatedAncestorInfo} = require(Packages../validateDOMNesting')
-- local {
--   isEnabled as ReactBrowserEventEmitterIsEnabled,
--   setEnabled as ReactBrowserEventEmitterSetEnabled,
-- } = require(Packages.../events/ReactDOMEventListener')
-- local {getChildNamespace} = require(Packages.../shared/DOMNamespaces')
-- local {
--   ELEMENT_NODE,
--   TEXT_NODE,
--   COMMENT_NODE,
--   DOCUMENT_NODE,
--   DOCUMENT_FRAGMENT_NODE,
-- } = require(Packages.../shared/HTMLNodeType')
-- local dangerousStyleValue = require(Packages.../shared/dangerousStyleValue')

-- local {REACT_OPAQUE_ID_TYPE} = require(Packages.shared/ReactSymbols')
-- local {retryIfBlockedOn} = require(Packages.../events/ReactDOMEventReplaying')

local ReactFeatureFlags = require(script.Parent.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
-- local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
local enableCreateEventHandleAPI = ReactFeatureFlags.enableCreateEventHandleAPI
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
-- local enableEagerRootListeners = ReactFeatureFlags.enableEagerRootListeners

-- local {HostComponent, HostText} = require(Packages.react-reconciler/src/ReactWorkTags')
-- local {
--   listenToReactEvent,
--   listenToAllSupportedEvents,
-- } = require(Packages.../events/DOMPluginEventSystem')

type Array<T> = { [number]: T }
type Object = { [any]: any }

-- ROBLOX deviation: Moved to ReactRobloxHostTypes
-- export type Type = string;
-- export type Props = {
--   autoFocus: boolean?,
--   children: any,
--   disabled: boolean?,
--   hidden: boolean?,
--   suppressHydrationWarning: boolean?,
--   dangerouslySetInnerHTML: any,
--   style: { display: string, [any]: any }?,
--   bottom: number?,
--   left: number?,
--   right: number?,
--   top: number?,
--   -- ...
--   [any]: any,
-- };
-- export type EventTargetChildElement = {
--   type: string,
--   props: nil | {
--     style?: {
--       position?: string,
--       zIndex?: number,
--       bottom?: string,
--       left?: string,
--       right?: string,
--       top?: string,
--       ...
--     },
--     ...
--   },
--   ...
-- end

-- ROBLOX deviation: Moved to ReactRobloxHostTypes
-- export type SuspenseInstance = Comment & {_reactRetry?: () => void, ...}
-- export type HydratableInstance = Instance | TextInstance | SuspenseInstance

-- ROBLOX deviation: Moved to ReactRobloxHostTypes
-- export type PublicInstance = Element | Text
-- type HostContextDev = {
--   namespace: string,
--   ancestorInfo: any,
--   -- ...
--   [any]: any,
-- }
-- type HostContextProd = string
-- export type HostContext = HostContextDev | HostContextProd

-- export type UpdatePayload = Array<mixed>
-- ROBLOX FIXME: cannot create type equal to void
-- export type ChildSet = void; -- Unused
-- export type TimeoutHandle = TimeoutID
-- export type NoTimeout = -1
-- export type RendererInspectionConfig = $ReadOnly<{or}>

-- export opaque type OpaqueIDType =
--   | string
--   | {
--       toString: () => string | void,
--       valueOf: () => string | void,
--     end

-- type SelectionInformation = {|
--   focusedElem: nil | HTMLElement,
--   selectionRange: mixed,
-- |}

-- local SUPPRESS_HYDRATION_WARNING
-- if __DEV__)
--   SUPPRESS_HYDRATION_WARNING = 'suppressHydrationWarning'
-- end

-- local SUSPENSE_START_DATA = '$'
-- local SUSPENSE_END_DATA = '/$'
-- local SUSPENSE_PENDING_START_DATA = '$?'
-- local SUSPENSE_FALLBACK_START_DATA = '$!'

-- local STYLE = 'style'

-- local eventsEnabled: boolean? = nil
-- local selectionInformation: nil | SelectionInformation = nil

-- function shouldAutoFocusHostComponent(type: string, props: Props): boolean {
--   switch (type)
--     case 'button':
--     case 'input':
--     case 'select':
--     case 'textarea':
--       return !!props.autoFocus
--   end
--   return false
-- end

-- ROBLOX deviation: Use GetDescendants rather than recursion
local function recursivelyUncacheFiberNode(node: HostInstance)
	-- ROBLOX https://jira.rbx.com/browse/LUAFDN-713: Tables are somehow ending up
	-- in this function that expects Instances. In that case, we won't be able to
	-- iterate through its descendants.
	if typeof(node :: any) ~= "Instance" then
		return
	end

	uncacheFiberNode(node)

	for _, child in node:GetDescendants() do
		uncacheFiberNode(child)
	end
end

local exports: { [any]: any } = {}
Object.assign(
	exports,
	require(script.Parent.Parent.Parent:WaitForChild('shared')).ReactFiberHostConfig.WithNoPersistence
)

exports.getRootHostContext = function(rootContainerInstance: Container): HostContext
	-- ROBLOX deviation: This is a lot of HTML-DOM specific logic; I'm not clear on
	-- whether there'll be an equivalent of `namespaceURI` for our use cases, but
	-- we may want to provide other kinds of context for host objects.

	-- For now, as a guess, we'll return the kind of instance we're attached to
	return rootContainerInstance.ClassName

	-- local type
	-- local namespace
	-- local nodeType = rootContainerInstance.nodeType
	-- switch (nodeType)
	--   case DOCUMENT_NODE:
	--   case DOCUMENT_FRAGMENT_NODE: {
	--     type = nodeType == DOCUMENT_NODE ? '#document' : '#fragment'
	--     local root = (rootContainerInstance: any).documentElement
	--     namespace = root ? root.namespaceURI : getChildNamespace(null, '')
	--     break
	--   end
	--   default: {
	--     local container: any =
	--       nodeType == COMMENT_NODE
	--         ? rootContainerInstance.parentNode
	--         : rootContainerInstance
	--     local ownNamespace = container.namespaceURI or nil
	--     type = container.tagName
	--     namespace = getChildNamespace(ownNamespace, type)
	--     break
	--   end
	-- end
	-- if _G.__DEV__ then
	--   local validatedTag = type.toLowerCase()
	--   local ancestorInfo = updatedAncestorInfo(null, validatedTag)
	--   return {namespace, ancestorInfo}
	-- end
	-- return namespace
end

exports.getChildHostContext = function(
	parentHostContext: HostContext,
	type: string,
	rootContainerInstance: Container
): HostContext
	-- ROBLOX deviation: unclear on the purpose here just yet, might be fine to
	-- just return parent's hostContext for now
	return parentHostContext
	-- if _G.__DEV__ then
	--   local parentHostContextDev = ((parentHostContext: any): HostContextDev)
	--   local namespace = getChildNamespace(parentHostContextDev.namespace, type)
	--   local ancestorInfo = updatedAncestorInfo(
	--     parentHostContextDev.ancestorInfo,
	--     type,
	--   )
	--   return {namespace, ancestorInfo}
	-- end
	-- local parentNamespace = ((parentHostContext: any): HostContextProd)
	-- return getChildNamespace(parentNamespace, type)
end

exports.getPublicInstance = function(instance: Instance): any
	return instance
end

exports.prepareForCommit = function(containerInfo: Container): Object?
	-- eventsEnabled = ReactBrowserEventEmitterIsEnabled()
	-- selectionInformation = getSelectionInformation()
	local activeInstance 	
if enableCreateEventHandleAPI then
		unimplemented("enableCreateEventHandleAPI")
		--   local focusedElem = selectionInformation.focusedElem
		--   if focusedElem ~= nil then
		--     activeInstance = getClosestInstanceFromNode(focusedElem)
		--   end
	end
	-- ReactBrowserEventEmitterSetEnabled(false)
	return activeInstance
end

exports.beforeActiveInstanceBlur = function()
	if enableCreateEventHandleAPI then
		unimplemented("enableCreateEventHandleAPI")
		-- ReactBrowserEventEmitterSetEnabled(true)
		-- dispatchBeforeDetachedBlur((selectionInformation: any).focusedElem)
		-- ReactBrowserEventEmitterSetEnabled(false)
	end
end

exports.afterActiveInstanceBlur = function()
	if enableCreateEventHandleAPI then
		unimplemented("enableCreateEventHandleAPI")
		-- ReactBrowserEventEmitterSetEnabled(true)
		-- dispatchAfterDetachedBlur((selectionInformation: any).focusedElem)
		-- ReactBrowserEventEmitterSetEnabled(false)
	end
end

exports.resetAfterCommit = function(containerInfo: Container)
	-- warn("Skip unimplemented: resetAfterCommit")
	-- restoreSelection(selectionInformation)
	-- ReactBrowserEventEmitterSetEnabled(eventsEnabled)
	-- eventsEnabled = nil
	-- selectionInformation = nil
end

exports.createInstance = function(
	type_: string,
	props: Props,
	rootContainerInstance: Container,
	hostContext: HostContext,
	internalInstanceHandle: Object
): HostInstance
	-- local hostKey = virtualNode.hostKey

	local domElement = Instance.new(type_)
	-- ROBLOX deviation: compatibility with old Roact where instances have their name
	-- set to the key value
	if internalInstanceHandle.key then
		domElement.Name = internalInstanceHandle.key
	else
		local currentHandle = internalInstanceHandle.return_
		while currentHandle do
			if currentHandle.key then
				domElement.Name = currentHandle.key
				break
			end
			currentHandle = currentHandle.return_
		end
	end

	precacheFiberNode(internalInstanceHandle, domElement)
	updateFiberProps(domElement, props)

	-- TODO: Support refs (does that actually happen here, or later?)
	-- applyRef(element.props[Ref], instance)

	-- Will have to be managed outside of createInstance
	-- if virtualNode.eventManager ~= nil then
	--   virtualNode.eventManager:resume()
	-- end

	return domElement

	-- return Instance.new("Frame")
	-- local parentNamespace: string
	-- if __DEV__)
	--   -- TODO: take namespace into account when validating.
	--   local hostContextDev = ((hostContext: any): HostContextDev)
	--   validateDOMNesting(type, nil, hostContextDev.ancestorInfo)
	--   if
	--     typeof props.children == 'string' or
	--     typeof props.children == 'number'
	--   )
	--     local string = '' + props.children
	--     local ownAncestorInfo = updatedAncestorInfo(
	--       hostContextDev.ancestorInfo,
	--       type,
	--     )
	--     validateDOMNesting(null, string, ownAncestorInfo)
	--   end
	--   parentNamespace = hostContextDev.namespace
	-- } else {
	--   parentNamespace = ((hostContext: any): HostContextProd)
	-- end
	-- local domElement: Instance = createElement(
	--   type,
	--   props,
	--   rootContainerInstance,
	--   parentNamespace,
	-- )
end

exports.appendInitialChild = function(parentInstance: Instance, child: Instance)
	-- ROBLOX deviation: Establish hierarchy with Parent property
	child.Parent = parentInstance
end

exports.finalizeInitialChildren = function(
	domElement: HostInstance,
	type_: string,
	props: Props,
	rootContainerInstance: Container,
	hostContext: HostContext
): boolean
	setInitialProperties(domElement, type_, props, rootContainerInstance)
	return false
	-- return shouldAutoFocusHostComponent(type_, props)
end

local function prepareUpdate(
	domElement: Instance,
	type_: string,
	oldProps: Props,
	newProps: Props,
	rootContainerInstance: Container,
	hostContext: HostContext
): nil | Array<any>
	-- if _G.__DEV__ then
	--   local hostContextDev = ((hostContext: any): HostContextDev)
	--   if
	--     typeof newProps.children ~= typeof oldProps.children and
	--     (typeof newProps.children == 'string' or
	--       typeof newProps.children == 'number')
	--   )
	--     local string = '' + newProps.children
	--     local ownAncestorInfo = updatedAncestorInfo(
	--       hostContextDev.ancestorInfo,
	--       type,
	--     )
	--     validateDOMNesting(null, string, ownAncestorInfo)
	--   end
	-- end
	return diffProperties(domElement, type_, oldProps, newProps, rootContainerInstance)
end
exports.prepareUpdate = prepareUpdate

exports.shouldSetTextContent = function(_type: string, _props: Props): boolean
	-- ROBLOX deviation: Ignore TextInstance logic, which isn't applicable to Roblox
	return false
	--   return (
	--     type == 'textarea' or
	--     type == 'option' or
	--     type == 'noscript' or
	--     typeof props.children == 'string' or
	--     typeof props.children == 'number' or
	--     (typeof props.dangerouslySetInnerHTML == 'table’' and
	--       props.dangerouslySetInnerHTML ~= nil and
	--       props.dangerouslySetInnerHTML.__html ~= nil)
	--   )
end

-- ROBLOX deviation: Text nodes aren't supported in Roblox renderer, so error so that tests fail immediately
exports.createTextInstance = function(
	text: string,
	rootContainerInstance: Container,
	hostContext: HostContext,
	internalInstanceHandle: Object
): any
	unimplemented("createTextInstance")
	return nil
end

exports.isPrimaryRenderer = true
exports.warnsIfNotActing = true
-- This initialization code may run even on server environments
-- if a component just imports ReactDOM (e.g. for findDOMNode).
-- Some environments might not have setTimeout or clearTimeout.
-- ROBLOX deviation: We're only dealing with client right now, so these always populate
exports.scheduleTimeout = setTimeout
exports.cancelTimeout = clearTimeout
exports.noTimeout = -1
-- -------------------
--     Mutation
-- -------------------


exports.supportsMutation = true

exports.commitMount = function(
	domElement: Instance,
	type: string,
	newProps: Props,
	internalInstanceHandle: Object
)
	unimplemented("commitMount")
	-- -- Despite the naming that might imply otherwise, this method only
	-- -- fires if there is an `Update` effect scheduled during mounting.
	-- -- This happens if `finalizeInitialChildren` returns `true` (which it
	-- -- does to implement the `autoFocus` attribute on the client). But
	-- -- there are also other cases when this might happen (such as patching
	-- -- up text content during hydration mismatch). So we'll check this again.
	-- if shouldAutoFocusHostComponent(type, newProps))
	--   ((domElement: any):
	--     | HTMLButtonElement
	--     | HTMLInputElement
	--     | HTMLSelectElement
	--     | HTMLTextAreaElement).focus()
	-- end
end

exports.commitUpdate = function(
	domElement: Instance,
	updatePayload: Array<any>,
	type_: string,
	oldProps: Props,
	newProps: Props,
	internalInstanceHandle: Object
)
	-- Update the props handle so that we know which props are the ones with
	-- with current event handlers.
	updateFiberProps(domElement, newProps)
	-- Apply the diff to the DOM node.
	updateProperties(domElement, updatePayload, oldProps)
end

-- ROBLOX deviation: Ignore TextInstance logic, which isn't applicable to Roblox
-- exports.resetTextContent(domElement: Instance): void {
--   setTextContent(domElement, '')
-- end

-- ROBLOX deviation: Ignore TextInstance logic, which isn't applicable to Roblox
-- exports.commitTextUpdate(
--   textInstance: TextInstance,
--   oldText: string,
--   newText: string,
-- ): void {
--   textInstance.nodeValue = newText
-- end

local function checkTags(instance: Instance)
	if typeof(instance :: any) ~= "Instance" then
		console.warn("Could not check tags on non-instance %s.", inspect(instance))
		return
	end
	if not instance:IsDescendantOf(game) then
		if #CollectionService:GetTags(instance) > 0 then
			console.warn(
[[Tags applied to orphaned %s "%s" cannot be accessed via CollectionService:GetTagged. If you're relying on tag behavior in a unit test, consider mounting your test root into the DataModel.]]


,
				instance.ClassName,
				instance.Name
			)
		end
	end
end

exports.appendChild = function(parentInstance: Instance, child: Instance)
	-- ROBLOX deviation: Roblox's DOM is based on child->parent references
	child.Parent = parentInstance
	-- parentInstance.appendChild(child)
	if _G.__DEV__ then
		checkTags(child)
	end
end

exports.appendChildToContainer = function(container: Container, child: Instance)
	-- ROBLOX TODO: Some of this logic may come back; for now, keep it simple
	local parentNode = container
	exports.appendChild(parentNode, child)

	-- if container.nodeType == COMMENT_NODE)
	--   parentNode = (container.parentNode: any)
	--   parentNode.insertBefore(child, container)
	-- } else {
	--   parentNode = container
	--   parentNode.appendChild(child)
	-- end
	-- -- This container might be used for a portal.
	-- -- If something inside a portal is clicked, that click should bubble
	-- -- through the React tree. However, on Mobile Safari the click would
	-- -- never bubble through the *DOM* tree unless an ancestor with onclick
	-- -- event exists. So we wouldn't see it and dispatch it.
	-- -- This is why we ensure that non React root containers have inline onclick
	-- -- defined.
	-- -- https://github.com/facebook/react/issues/11918
	-- local reactRootContainer = container._reactRootContainer
	-- if
	--   reactRootContainer == nil and parentNode.onclick == nil
	-- then
	--   -- TODO: This cast may not be sound for SVG, MathML or custom elements.
	--   trapClickOnNonInteractiveElement(((parentNode: any): HTMLElement))
	-- end
end

exports.insertBefore =
	function(parentInstance: Instance, child: Instance, _beforeChild: Instance)
		-- ROBLOX deviation: Roblox's DOM is based on child->parent references
		child.Parent = parentInstance
		-- parentInstance.insertBefore(child, beforeChild)
		if _G.__DEV__ then
			checkTags(child)
		end
	end

exports.insertInContainerBefore =
	function(container: Container, child: Instance, beforeChild: Instance)
		-- ROBLOX deviation: use our container definition
		local parentNode = container
		exports.insertBefore(parentNode, child, beforeChild)
		-- if container.nodeType == COMMENT_NODE)
		--   (container.parentNode: any).insertBefore(child, beforeChild)
		-- } else {
		--   container.insertBefore(child, beforeChild)
		-- end
	end

-- function createEvent(type: DOMEventName, bubbles: boolean): Event {
--   local event = document.createEvent('Event')
--   event.initEvent(((type: any): string), bubbles, false)
--   return event
-- end

-- function dispatchBeforeDetachedBlur(target: HTMLElement): void {
--   if enableCreateEventHandleAPI)
--     local event = createEvent('beforeblur', true)
--     -- Dispatch "beforeblur" directly on the target,
--     -- so it gets picked up by the event system and
--     -- can propagate through the React internal tree.
--     target.dispatchEvent(event)
--   end
-- end

-- function dispatchAfterDetachedBlur(target: HTMLElement): void {
--   if enableCreateEventHandleAPI)
--     local event = createEvent('afterblur', false)
--     -- So we know what was detached, make the relatedTarget the
--     -- detached target on the "afterblur" event.
--     (event: any).relatedTarget = target
--     -- Dispatch the event on the document.
--     document.dispatchEvent(event)
--   end
-- end

exports.removeChild = function(_parentInstance: Instance, child: Instance)
	recursivelyUncacheFiberNode(child)
	-- ROBLOX deviation: The roblox renderer tracks bindings and event managers
	-- for instances, so make sure we clean those up when we remove the instance
	cleanupHostComponent(child)
	-- ROBLOX deviation: Roblox's DOM is based on child->parent references
	child.Parent = nil
	-- parentInstance.removeChild(child)
	-- ROBLOX deviation: Guard against misuse by locking parent and forcing external cleanup via Destroy
	child:Destroy()
end

exports.removeChildFromContainer = function(_container: Container, child: Instance)
	-- ROBLOX deviation: Containers don't have special behavior and comment nodes
	-- have no datamodel equivalent, so just forward to the removeChild logic
	exports.removeChild(_container, child)
	-- if container.nodeType == COMMENT_NODE)
	--   (container.parentNode: any).removeChild(child)
	-- } else {
	--   container.removeChild(child)
	-- end
end

exports.clearSuspenseBoundary =
	function(parentInstance: Instance, suspenseInstance: SuspenseInstance)
		-- ROBLOX FIXME: this is a major thing we need to fix for Suspense to work as a feature
		unimplemented("clearSuspenseBoundary")
		--   local node = suspenseInstance
		--   -- Delete all nodes within this suspense boundary.
		--   -- There might be nested nodes so we need to keep track of how
		--   -- deep we are and only break out when we're back on top.
		--   local depth = 0
		--   do {
		--     local nextNode = node.nextSibling
		--     parentInstance.removeChild(node)
		--     if nextNode and nextNode.nodeType == COMMENT_NODE)
		--       local data = ((nextNode: any).data: string)
		--       if data == SUSPENSE_END_DATA)
		--         if depth == 0)
		--           parentInstance.removeChild(nextNode)
		--           -- Retry if any event replaying was blocked on this.
		--           retryIfBlockedOn(suspenseInstance)
		--           return
		--         } else {
		--           depth--
		--         end
		--       } else if
		--         data == SUSPENSE_START_DATA or
		--         data == SUSPENSE_PENDING_START_DATA or
		--         data == SUSPENSE_FALLBACK_START_DATA
		--       )
		--         depth++
		--       end
		--     end
		--     node = nextNode
		--   } while (node)
		--   -- TODO: Warn, we didn't find the end comment boundary.
		--   -- Retry if any event replaying was blocked on this.
		--   retryIfBlockedOn(suspenseInstance)
	end

exports.clearSuspenseBoundaryFromContainer =
	function(container: Container, suspenseInstance: SuspenseInstance)
		-- ROBLOX FIXME: this is a major thing we need to fix for Suspense to work as a feature
		unimplemented("clearSuspenseBoundaryFromContainer")
		--   if container.nodeType == COMMENT_NODE)
		--     clearSuspenseBoundary((container.parentNode: any), suspenseInstance)
		--   } else if container.nodeType == ELEMENT_NODE)
		--     clearSuspenseBoundary((container: any), suspenseInstance)
		--   } else {
		--     -- Document nodes should never contain suspense boundaries.
		--   end
		--   -- Retry if any event replaying was blocked on this.
		--   retryIfBlockedOn(container)
	end

exports.hideInstance = function(instance: Instance)
	unimplemented("hideInstance")
	-- -- TODO: Does this work for all element types? What about MathML? Should we
	-- -- pass host context to this method?
	-- instance = ((instance: any): HTMLElement)
	-- local style = instance.style
	-- if typeof style.setProperty == 'function')
	--   style.setProperty('display', 'none', 'important')
	-- } else {
	--   style.display = 'none'
	-- end
end

-- ROBLOX deviation: error on TextInstance logic, which isn't applicable to Roblox
exports.hideTextInstance = function(textInstance: TextInstance): ()
	unimplemented("hideTextInstance")
	--   textInstance.nodeValue = ''
end

exports.unhideInstance = function(instance: Instance, props: Props)
	unimplemented("unhideInstance")
	-- instance = ((instance: any): HTMLElement)
	-- local styleProp = props[STYLE]
	-- local display =
	--   styleProp ~= undefined and
	--   styleProp ~= nil and
	--   styleProp.hasOwnProperty('display')
	--     ? styleProp.display
	--     : nil
	-- instance.style.display = dangerousStyleValue('display', display)
end

-- ROBLOX deviation: error on TextInstance logic, which isn't applicable to Roblox
exports.unhideTextInstance = function(textInstance: TextInstance, text: string): ()
	unimplemented("unhideTextInstance")
	--   textInstance.nodeValue = text
end

exports.clearContainer = function(container: Container)
	-- ROBLOX deviation: with Roblox, we can simply enumerate and remove the children
	local parentInstance = container
	for _, child in parentInstance:GetChildren() do
		exports.removeChild(parentInstance, child)
	end
	-- if container.nodeType == ELEMENT_NODE)
	--   ((container: any): Element).textContent = ''
	-- } else if container.nodeType == DOCUMENT_NODE)
	--   local body = ((container: any): Document).body
	--   if body ~= nil)
	--     body.textContent = ''
	--   end
	-- end
end

-- -- -------------------
-- --     Hydration
-- -- -------------------

-- export local supportsHydration = true

-- exports.canHydrateInstance(
--   instance: HydratableInstance,
--   type: string,
--   props: Props,
-- ): nil | Instance {
--   if
--     instance.nodeType ~= ELEMENT_NODE or
--     type.toLowerCase() ~= instance.nodeName.toLowerCase()
--   )
--     return nil
--   end
--   -- This has now been refined to an element node.
--   return ((instance: any): Instance)
-- end

-- exports.canHydrateTextInstance(
--   instance: HydratableInstance,
--   text: string,
-- ): nil | TextInstance {
--   if text == '' or instance.nodeType ~= TEXT_NODE)
--     -- Empty strings are not parsed by HTML so there won't be a correct match here.
--     return nil
--   end
--   -- This has now been refined to a text node.
--   return ((instance: any): TextInstance)
-- end

-- exports.canHydrateSuspenseInstance(
--   instance: HydratableInstance,
-- ): nil | SuspenseInstance {
--   if instance.nodeType ~= COMMENT_NODE)
--     -- Empty strings are not parsed by HTML so there won't be a correct match here.
--     return nil
--   end
--   -- This has now been refined to a suspense node.
--   return ((instance: any): SuspenseInstance)
-- end

-- exports.isSuspenseInstanceFallback(instance: SuspenseInstance)
--   return instance.data == SUSPENSE_FALLBACK_START_DATA
-- end

-- exports.registerSuspenseInstanceRetry(
--   instance: SuspenseInstance,
--   callback: () => void,
-- )
--   instance._reactRetry = callback
-- end

-- function getNextHydratable(node)
--   -- Skip non-hydratable nodes.
--   for (; node ~= nil; node = node.nextSibling)
--     local nodeType = node.nodeType
--     if nodeType == ELEMENT_NODE or nodeType == TEXT_NODE)
--       break
--     end
--     if enableSuspenseServerRenderer)
--       if nodeType == COMMENT_NODE)
--         local nodeData = (node: any).data
--         if
--           nodeData == SUSPENSE_START_DATA or
--           nodeData == SUSPENSE_FALLBACK_START_DATA or
--           nodeData == SUSPENSE_PENDING_START_DATA
--         )
--           break
--         end
--       end
--     end
--   end
--   return (node: any)
-- end

-- exports.getNextHydratableSibling(
--   instance: HydratableInstance,
-- ): nil | HydratableInstance {
--   return getNextHydratable(instance.nextSibling)
-- end

-- exports.getFirstHydratableChild(
--   parentInstance: Container | Instance,
-- ): nil | HydratableInstance {
--   return getNextHydratable(parentInstance.firstChild)
-- end

-- exports.hydrateInstance(
--   instance: Instance,
--   type: string,
--   props: Props,
--   rootContainerInstance: Container,
--   hostContext: HostContext,
--   internalInstanceHandle: Object,
-- ): nil | Array<mixed> {
--   precacheFiberNode(internalInstanceHandle, instance)
--   -- TODO: Possibly defer this until the commit phase where all the events
--   -- get attached.
--   updateFiberProps(instance, props)
--   local parentNamespace: string
--   if __DEV__)
--     local hostContextDev = ((hostContext: any): HostContextDev)
--     parentNamespace = hostContextDev.namespace
--   } else {
--     parentNamespace = ((hostContext: any): HostContextProd)
--   end
--   return diffHydratedProperties(
--     instance,
--     type,
--     props,
--     parentNamespace,
--     rootContainerInstance,
--   )
-- end

-- exports.hydrateTextInstance(
--   textInstance: TextInstance,
--   text: string,
--   internalInstanceHandle: Object,
-- ): boolean {
--   precacheFiberNode(internalInstanceHandle, textInstance)
--   return diffHydratedText(textInstance, text)
-- end

-- exports.hydrateSuspenseInstance(
--   suspenseInstance: SuspenseInstance,
--   internalInstanceHandle: Object,
-- )
--   precacheFiberNode(internalInstanceHandle, suspenseInstance)
-- end

-- exports.getNextHydratableInstanceAfterSuspenseInstance(
--   suspenseInstance: SuspenseInstance,
-- ): nil | HydratableInstance {
--   local node = suspenseInstance.nextSibling
--   -- Skip past all nodes within this suspense boundary.
--   -- There might be nested nodes so we need to keep track of how
--   -- deep we are and only break out when we're back on top.
--   local depth = 0
--   while (node)
--     if node.nodeType == COMMENT_NODE)
--       local data = ((node: any).data: string)
--       if data == SUSPENSE_END_DATA)
--         if depth == 0)
--           return getNextHydratableSibling((node: any))
--         } else {
--           depth--
--         end
--       } else if
--         data == SUSPENSE_START_DATA or
--         data == SUSPENSE_FALLBACK_START_DATA or
--         data == SUSPENSE_PENDING_START_DATA
--       )
--         depth++
--       end
--     end
--     node = node.nextSibling
--   end
--   -- TODO: Warn, we didn't find the end comment boundary.
--   return nil
-- end

-- -- Returns the SuspenseInstance if this node is a direct child of a
-- -- SuspenseInstance. I.e. if its previous sibling is a Comment with
-- -- SUSPENSE_x_START_DATA. Otherwise, nil.
-- exports.getParentSuspenseInstance(
--   targetInstance: Node,
-- ): nil | SuspenseInstance {
--   local node = targetInstance.previousSibling
--   -- Skip past all nodes within this suspense boundary.
--   -- There might be nested nodes so we need to keep track of how
--   -- deep we are and only break out when we're back on top.
--   local depth = 0
--   while (node)
--     if node.nodeType == COMMENT_NODE)
--       local data = ((node: any).data: string)
--       if
--         data == SUSPENSE_START_DATA or
--         data == SUSPENSE_FALLBACK_START_DATA or
--         data == SUSPENSE_PENDING_START_DATA
--       )
--         if depth == 0)
--           return ((node: any): SuspenseInstance)
--         } else {
--           depth--
--         end
--       } else if data == SUSPENSE_END_DATA)
--         depth++
--       end
--     end
--     node = node.previousSibling
--   end
--   return nil
-- end

-- exports.commitHydratedContainer(container: Container): void {
--   -- Retry if any event replaying was blocked on this.
--   retryIfBlockedOn(container)
-- end

-- exports.commitHydratedSuspenseInstance(
--   suspenseInstance: SuspenseInstance,
-- ): void {
--   -- Retry if any event replaying was blocked on this.
--   retryIfBlockedOn(suspenseInstance)
-- end

-- exports.didNotMatchHydratedContainerTextInstance(
--   parentContainer: Container,
--   textInstance: TextInstance,
--   text: string,
-- )
--   if __DEV__)
--     warnForUnmatchedText(textInstance, text)
--   end
-- end

-- exports.didNotMatchHydratedTextInstance(
--   parentType: string,
--   parentProps: Props,
--   parentInstance: Instance,
--   textInstance: TextInstance,
--   text: string,
-- )
--   if __DEV__ and parentProps[SUPPRESS_HYDRATION_WARNING] ~= true)
--     warnForUnmatchedText(textInstance, text)
--   end
-- end

-- exports.didNotHydrateContainerInstance(
--   parentContainer: Container,
--   instance: HydratableInstance,
-- )
--   if __DEV__)
--     if instance.nodeType == ELEMENT_NODE)
--       warnForDeletedHydratableElement(parentContainer, (instance: any))
--     } else if instance.nodeType == COMMENT_NODE)
--       -- TODO: warnForDeletedHydratableSuspenseBoundary
--     } else {
--       warnForDeletedHydratableText(parentContainer, (instance: any))
--     end
--   end
-- end

-- exports.didNotHydrateInstance(
--   parentType: string,
--   parentProps: Props,
--   parentInstance: Instance,
--   instance: HydratableInstance,
-- )
--   if __DEV__ and parentProps[SUPPRESS_HYDRATION_WARNING] ~= true)
--     if instance.nodeType == ELEMENT_NODE)
--       warnForDeletedHydratableElement(parentInstance, (instance: any))
--     } else if instance.nodeType == COMMENT_NODE)
--       -- TODO: warnForDeletedHydratableSuspenseBoundary
--     } else {
--       warnForDeletedHydratableText(parentInstance, (instance: any))
--     end
--   end
-- end

-- exports.didNotFindHydratableContainerInstance(
--   parentContainer: Container,
--   type: string,
--   props: Props,
-- )
--   if __DEV__)
--     warnForInsertedHydratedElement(parentContainer, type, props)
--   end
-- end

-- exports.didNotFindHydratableContainerTextInstance(
--   parentContainer: Container,
--   text: string,
-- )
--   if __DEV__)
--     warnForInsertedHydratedText(parentContainer, text)
--   end
-- end

-- exports.didNotFindHydratableContainerSuspenseInstance(
--   parentContainer: Container,
-- )
--   if __DEV__)
--     -- TODO: warnForInsertedHydratedSuspense(parentContainer)
--   end
-- end

-- exports.didNotFindHydratableInstance(
--   parentType: string,
--   parentProps: Props,
--   parentInstance: Instance,
--   type: string,
--   props: Props,
-- )
--   if __DEV__ and parentProps[SUPPRESS_HYDRATION_WARNING] ~= true)
--     warnForInsertedHydratedElement(parentInstance, type, props)
--   end
-- end

-- exports.didNotFindHydratableTextInstance(
--   parentType: string,
--   parentProps: Props,
--   parentInstance: Instance,
--   text: string,
-- )
--   if __DEV__ and parentProps[SUPPRESS_HYDRATION_WARNING] ~= true)
--     warnForInsertedHydratedText(parentInstance, text)
--   end
-- end

-- exports.didNotFindHydratableSuspenseInstance(
--   parentType: string,
--   parentProps: Props,
--   parentInstance: Instance,
-- )
--   if __DEV__ and parentProps[SUPPRESS_HYDRATION_WARNING] ~= true)
--     -- TODO: warnForInsertedHydratedSuspense(parentInstance)
--   end
-- end

-- exports.getFundamentalComponentInstance(
--   fundamentalInstance: ReactDOMFundamentalComponentInstance,
-- ): Instance {
--   if enableFundamentalAPI)
--     local {currentFiber, impl, props, state} = fundamentalInstance
--     local instance = impl.getInstance(null, props, state)
--     precacheFiberNode(currentFiber, instance)
--     return instance
--   end
--   -- Because of the flag above, this gets around the Flow error
--   return (null: any)
-- end

-- exports.mountFundamentalComponent(
--   fundamentalInstance: ReactDOMFundamentalComponentInstance,
-- ): void {
--   if enableFundamentalAPI)
--     local {impl, instance, props, state} = fundamentalInstance
--     local onMount = impl.onMount
--     if onMount ~= undefined)
--       onMount(null, instance, props, state)
--     end
--   end
-- end

-- exports.shouldUpdateFundamentalComponent(
--   fundamentalInstance: ReactDOMFundamentalComponentInstance,
-- ): boolean {
--   if enableFundamentalAPI)
--     local {impl, prevProps, props, state} = fundamentalInstance
--     local shouldUpdate = impl.shouldUpdate
--     if shouldUpdate ~= undefined)
--       return shouldUpdate(null, prevProps, props, state)
--     end
--   end
--   return true
-- end

-- exports.updateFundamentalComponent(
--   fundamentalInstance: ReactDOMFundamentalComponentInstance,
-- ): void {
--   if enableFundamentalAPI)
--     local {impl, instance, prevProps, props, state} = fundamentalInstance
--     local onUpdate = impl.onUpdate
--     if onUpdate ~= undefined)
--       onUpdate(null, instance, prevProps, props, state)
--     end
--   end
-- end

-- exports.unmountFundamentalComponent(
--   fundamentalInstance: ReactDOMFundamentalComponentInstance,
-- ): void {
--   if enableFundamentalAPI)
--     local {impl, instance, props, state} = fundamentalInstance
--     local onUnmount = impl.onUnmount
--     if onUnmount ~= undefined)
--       onUnmount(null, instance, props, state)
--     end
--   end
-- end

-- exports.getInstanceFromNode(node: HTMLElement): nil | Object {
--   return getClosestInstanceFromNode(node) or nil
-- end

-- local clientId: number = 0
-- exports.makeClientId(): OpaqueIDType {
--   return 'r:' + (clientId++).toString(36)
-- end

-- exports.makeClientIdInDEV(warnOnAccessInDEV: () => void): OpaqueIDType {
--   local id = 'r:' + (clientId++).toString(36)
--   return {
--     toString()
--       warnOnAccessInDEV()
--       return id
--     },
--     valueOf()
--       warnOnAccessInDEV()
--       return id
--     },
--   end
-- end

-- exports.isOpaqueHydratingObject(value: mixed): boolean {
--   return (
--     value ~= nil and
--     typeof value == 'table’' and
--     value.$$typeof == REACT_OPAQUE_ID_TYPE
--   )
-- end

-- exports.makeOpaqueHydratingObject(
--   attemptToReadValue: () => void,
-- ): OpaqueIDType {
--   return {
--     $$typeof: REACT_OPAQUE_ID_TYPE,
--     toString: attemptToReadValue,
--     valueOf: attemptToReadValue,
--   end
-- end

exports.preparePortalMount = function(portalInstance: Instance): ()
	-- ROBLOX TODO: Revisit this logic and see if any of it applies
	-- if enableEagerRootListeners then
	--   listenToAllSupportedEvents(portalInstance)
	-- else
	--   listenToReactEvent('onMouseEnter', portalInstance)
	-- end
end

-- exports.prepareScopeUpdate(
--   scopeInstance: ReactScopeInstance,
--   internalInstanceHandle: Object,
-- ): void {
--   if enableScopeAPI)
--     precacheFiberNode(internalInstanceHandle, scopeInstance)
--   end
-- end

-- exports.getInstanceFromScope(
--   scopeInstance: ReactScopeInstance,
-- ): nil | Object {
--   if enableScopeAPI)
--     return getFiberFromScopeInstance(scopeInstance)
--   end
--   return nil
-- end

-- export local supportsTestSelectors = true

-- exports.findFiberRoot(node: Instance): nil | FiberRoot {
--   local stack = [node]
--   local index = 0
--   while (index < stack.length)
--     local current = stack[index++]
--     if isContainerMarkedAsRoot(current))
--       return ((getInstanceFromNodeDOMTree(current): any): FiberRoot)
--     end
--     stack.push(...current.children)
--   end
--   return nil
-- end

-- exports.getBoundingRect(node: Instance): BoundingRect {
--   local rect = node.getBoundingClientRect()
--   return {
--     x: rect.left,
--     y: rect.top,
--     width: rect.width,
--     height: rect.height,
--   end
-- end

-- exports.matchAccessibilityRole(node: Instance, role: string): boolean {
--   if hasRole(node, role))
--     return true
--   end

--   return false
-- end

-- exports.getTextContent(fiber: Fiber): string | nil {
--   switch (fiber.tag)
--     case HostComponent:
--       local textContent = ''
--       local childNodes = fiber.stateNode.childNodes
--       for (local i = 0; i < childNodes.length; i++)
--         local childNode = childNodes[i]
--         if childNode.nodeType == Node.TEXT_NODE)
--           textContent += childNode.textContent
--         end
--       end
--       return textContent
--     case HostText:
--       return fiber.stateNode.textContent
--   end

--   return nil
-- end

-- exports.isHiddenSubtree(fiber: Fiber): boolean {
--   return fiber.tag == HostComponent and fiber.memoizedProps.hidden == true
-- end

-- exports.setFocusIfFocusable(node: Instance): boolean {
--   -- The logic for determining if an element is focusable is kind of complex,
--   -- and since we want to actually change focus anyway- we can just skip it.
--   -- Instead we'll just listen for a "focus" event to verify that focus was set.
--   --
--   -- We could compare the node to document.activeElement after focus,
--   -- but this would not handle the case where application code managed focus to automatically blur.
--   local didFocus = false
--   local handleFocus = () => {
--     didFocus = true
--   end

--   local element = ((node: any): HTMLElement)
--   try {
--     element.addEventListener('focus', handleFocus)
--     (element.focus or HTMLElement.prototype.focus).call(element)
--   } finally {
--     element.removeEventListener('focus', handleFocus)
--   end

--   return didFocus
-- end

-- type RectRatio = {
--   ratio: number,
--   rect: BoundingRect,
-- end

-- exports.setupIntersectionObserver(
--   targets: Array<Instance>,
--   callback: ObserveVisibleRectsCallback,
--   options?: IntersectionObserverOptions,
-- ): {|
--   disconnect: () => void,
--   observe: (instance: Instance) => void,
--   unobserve: (instance: Instance) => void,
-- |} {
--   local rectRatioCache: Map<Instance, RectRatio> = new Map()
--   targets.forEach(target => {
--     rectRatioCache.set(target, {
--       rect: getBoundingRect(target),
--       ratio: 0,
--     })
--   })

--   local handleIntersection = (entries: Array<IntersectionObserverEntry>) => {
--     entries.forEach(entry => {
--       local {boundingClientRect, intersectionRatio, target} = entry
--       rectRatioCache.set(target, {
--         rect: {
--           x: boundingClientRect.left,
--           y: boundingClientRect.top,
--           width: boundingClientRect.width,
--           height: boundingClientRect.height,
--         },
--         ratio: intersectionRatio,
--       })
--     })

--     callback(Array.from(rectRatioCache.values()))
--   end

--   local observer = new IntersectionObserver(handleIntersection, options)
--   targets.forEach(target => {
--     observer.observe((target: any))
--   })

--   return {
--     disconnect: () => observer.disconnect(),
--     observe: target => {
--       rectRatioCache.set(target, {
--         rect: getBoundingRect(target),
--         ratio: 0,
--       })
--       observer.observe((target: any))
--     },
--     unobserve: target => {
--       rectRatioCache.delete(target)
--       observer.unobserve((target: any))
--     },
--   end
-- end

return exports

end,
["react-roblox/client/ReactRobloxHostTypes.roblox"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOMHostConfig.js
-- ROBLOX upstream: https://github.com/facebook/react/blob/efd8f6442d1aa7c4566fe812cba03e7e83aaccc3/packages/react-native-renderer/src/ReactNativeHostConfig.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local ReactReconciler = require(script.Parent.Parent.Parent:WaitForChild('react-reconciler'))
type FiberRoot = ReactReconciler.FiberRoot

local ReactTypes = require(script.Parent.Parent.Parent:WaitForChild('shared'))
type MutableSource<T> = ReactTypes.MutableSource<T>
type ReactNodeList = ReactTypes.ReactNodeList

type Array<T> = { [number]: T }

-- deviation: Containers should also be instances; at some point, we may
-- restrict which _kinds_ of instances, but that's not necessary right now
export type Container = Instance
-- export type Container =
--   | (Element & {_reactRootContainer?: RootType, ...})
--   | (Document & {_reactRootContainer?: RootType, ...})

-- deviation: We can't export this as `Instance`; luau gets upset!
export type HostInstance = Instance

export type TextInstance = Instance

-- ROBLOX TODO: Revisit this type for suspense
-- export type SuspenseInstance = Comment & {_reactRetry?: () => void, ...}
export type SuspenseInstance = any

export type Type = string
export type Props = {
	autoFocus: boolean?,
	children: any,
	disabled: boolean?,
	hidden: boolean?,
	suppressHydrationWarning: boolean?,
	dangerouslySetInnerHTML: any,
	style: { display: string, [any]: any }?,
	bottom: number?,
	left: number?,
	right: number?,
	top: number?,
	-- ...
	[any]: any
}

-- ROBLOX TODO: Revisit this type for hydration
-- export type HydratableInstance = Instance | TextInstance | SuspenseInstance
export type HydratableInstance = Instance | SuspenseInstance

-- ROBLOX TODO: Revisit this to make sure it makes sense
-- export type PublicInstance = Element | Text
export type PublicInstance = HostInstance

-- ROBLOX TODO: See if these actually make sense
type HostContextDev = {
	namespace: string,
	ancestorInfo: any,
	-- ...
	[any]: any
}
type HostContextProd = string
export type HostContext = HostContextDev | HostContextProd

export type RootType = {
	render: (self: RootType, children: ReactNodeList) -> (),
	unmount: (self: RootType) -> (),
	_internalRoot: any,
	-- _internalRoot: FiberRoot,
	-- ...
	[any]: any
}

export type RootOptions = {
	hydrate: boolean?,
	hydrationOptions: {
		onHydrated: ((suspenseNode: any) -> ())?,
		onDeleted: ((suspenseNode: any) -> ())?,
		mutableSources: Array<MutableSource<any>>?,
		-- ...
		[any]: any	
}?,
	-- ...
	[any]: any
}

return {}

end,
["react-roblox/client/ReactRobloxRoot"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOMRoot.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactRobloxHostTypes = require(script.Parent:WaitForChild('ReactRobloxHostTypes.roblox'))
type Container = ReactRobloxHostTypes.Container
type RootType = ReactRobloxHostTypes.RootType
type RootOptions = ReactRobloxHostTypes.RootOptions

local ReconcilerTypes = require(script.Parent.Parent.Parent:WaitForChild('react-reconciler'))
type RootTag = ReconcilerTypes.RootTag
local ReactTypes = require(script.Parent.Parent.Parent:WaitForChild('shared'))
type MutableSource<T> = ReactTypes.MutableSource<T>
type ReactNodeList = ReactTypes.ReactNodeList
local ReactInternalTypes = require(script.Parent.Parent.Parent:WaitForChild('react-reconciler'))
type FiberRoot = ReactInternalTypes.FiberRoot

type Array<T> = { [number]: T }

local ReactRobloxComponentTree = require(script.Parent:WaitForChild('ReactRobloxComponentTree'))-- local isContainerMarkedAsRoot = ReactRobloxComponentTree.isContainerMarkedAsRoot

local markContainerAsRoot = ReactRobloxComponentTree.markContainerAsRoot
local unmarkContainerAsRoot = ReactRobloxComponentTree.unmarkContainerAsRoot
-- local listenToAllSupportedEvents = require("./events/DOMPluginEventSystem").listenToAllSupportedEvents
-- local eagerlyTrapReplayableEvents = require("./events/ReactDOMEventReplaying").eagerlyTrapReplayableEvents
-- local HTMLNodeType = require("./shared/HTMLNodeType")
-- local ELEMENT_NODE = HTMLNodeType.ELEMENT_NODE
-- local COMMENT_NODE = HTMLNodeType.COMMENT_NODE
-- local DOCUMENT_NODE = HTMLNodeType.DOCUMENT_NODE
-- local DOCUMENT_FRAGMENT_NODE = HTMLNodeType.DOCUMENT_FRAGMENT_NODE
-- local ensureListeningTo = require("@pkg/ReactDOMComponent").ensureListeningTo

-- ROBLOX deviation: Use the config-injecting entry point for the reconciler
local ReactFiberReconciler = require(script.Parent.Parent:WaitForChild('ReactReconciler.roblox'))
local createContainer = ReactFiberReconciler.createContainer
local updateContainer = ReactFiberReconciler.updateContainer
-- local findHostInstanceWithNoPortals = ReactFiberReconciler.findHostInstanceWithNoPortals
-- local registerMutableSourceForHydration = ReactFiberReconciler.registerMutableSourceForHydration
local invariant = require(script.Parent.Parent.Parent:WaitForChild('shared')).invariant
local enableEagerRootListeners =
	require(script.Parent.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.enableEagerRootListeners

-- ROBLOX deviation: Used to fix unmount not being synchronous
local flushSync = ReactFiberReconciler.flushSync
local flushPassiveEffects = ReactFiberReconciler.flushPassiveEffects

local BlockingRoot = ReactFiberReconciler.ReactRootTags.BlockingRoot
local ConcurrentRoot = ReactFiberReconciler.ReactRootTags.ConcurrentRoot
local LegacyRoot = ReactFiberReconciler.ReactRootTags.LegacyRoot

local createRootImpl

local ReactRobloxRoot = {}
ReactRobloxRoot.__index = ReactRobloxRoot

function ReactRobloxRoot.new(container: Container, options: RootOptions?): RootType
	local root: RootType = (setmetatable({}, ReactRobloxRoot) :: any) :: RootType
	root._internalRoot = createRootImpl(container, ConcurrentRoot, options)

	return root
end

local function createBlockingRoot(
	container: Container,
	tag: RootTag,
	options: RootOptions?
): RootType
	-- deviation: We can just share the logic here via metatables
	local root: RootType = (setmetatable({}, ReactRobloxRoot) :: any) :: RootType
	root._internalRoot = createRootImpl(container, tag, options)

	return root
end

function ReactRobloxRoot:render(children: ReactNodeList)
	local root = self._internalRoot
	-- if _G.__DEV__ then
	--   if typeof (arguments[1] == 'function')
	--     console.error(
	--       'render(...): does not support the second callback argument. ' +
	--         'To execute a side effect after rendering, declare it in a component body with useEffect().',
	--     )
	--   end
	--   local container = root.containerInfo

	--   if container.nodeType ~= COMMENT_NODE)
	--     local hostInstance = findHostInstanceWithNoPortals(root.current)
	--     if hostInstance)
	--       if hostInstance.parentNode ~= container)
	--         console.error(
	--           'render(...): It looks like the React-rendered content of the ' +
	--             'root container was removed without using React. This is not ' +
	--             'supported and will cause errors. Instead, call ' +
	--             "root.unmount() to empty a root's container.",
	--         )
	--       end
	--     end
	--   end
	-- end
	updateContainer(children, root, nil)
end

function ReactRobloxRoot:unmount()
	-- if _G.__DEV__ then
	--   if typeof arguments[0] == 'function')
	--     console.error(
	--       'unmount(...): does not support a callback argument. ' +
	--         'To execute a side effect after rendering, declare it in a component body with useEffect().',
	--     )
	--   end
	-- end
	local root = self._internalRoot
	local container = root.containerInfo

	-- ROBLOX deviation: unmount() is synchronous in upstream, at least in modern versions
	flushSync(function()
		updateContainer(nil, root, nil, function()
			unmarkContainerAsRoot(container)
		end)
	end)

	flushPassiveEffects()
end

-- ROBLOX TODO: add Options type
-- createRootImpl = function(
--   container: Container,
--   tag: RootTag,
--   options: RootOptions
-- )
createRootImpl = function(container: Container, tag: RootTag, options: any)
	-- Tag is either LegacyRoot or Concurrent Root
	local hydrate = options ~= nil and options.hydrate == true
	local hydrationCallbacks = if options ~= nil then options.hydrationOptions else nil
	local mutableSources = (
		options ~= nil
		and options.hydrationOptions ~= nil
		and options.hydrationOptions.mutableSources
	) or nil
	local root = createContainer(container, tag, hydrate, hydrationCallbacks)
	markContainerAsRoot(root.current, container)
	-- local containerNodeType = container.nodeType

	if enableEagerRootListeners then
		--   local rootContainerElement =
		--     container.nodeType == COMMENT_NODE and container.parentNode or container
		--   listenToAllSupportedEvents(rootContainerElement)
		-- } else {
		--   if hydrate and tag ~= LegacyRoot)
		--     local doc =
		--       containerNodeType == DOCUMENT_NODE
		--         ? container
		--         : container.ownerDocument
		--     -- We need to cast this because Flow doesn't work
		--     -- with the hoisted containerNodeType. If we inline
		--     -- it, then Flow doesn't complain. We intentionally
		--     -- hoist it to reduce code-size.
		--     eagerlyTrapReplayableEvents(container, ((doc: any): Document))
		--   } else if
		--     containerNodeType ~= DOCUMENT_FRAGMENT_NODE and
		--     containerNodeType ~= DOCUMENT_NODE
		--   )
		--     ensureListeningTo(container, 'onMouseEnter')
		--   end
	end

	if mutableSources then
		-- for (local i = 0; i < mutableSources.length; i++)
		--   local mutableSource = mutableSources[i]
		--   registerMutableSourceForHydration(root, mutableSource)
		-- end
	end

	return root
end

local exports = {}

local function isValidContainer(node: any): boolean
	-- ROBLOX TODO: This behavior will deviate, for now just check that it's an
	-- instance, which should be good enough
	return typeof(node) == "Instance"
	-- return not not (
	--   node and
	--   (node.nodeType == ELEMENT_NODE or
	--     node.nodeType == DOCUMENT_NODE or
	--     node.nodeType == DOCUMENT_FRAGMENT_NODE or
	--     (node.nodeType == COMMENT_NODE and
	--       node.nodeValue == ' react-mount-point-unstable '))
	-- )
end

exports.isValidContainer = isValidContainer

-- deviation: Create `Container` from instance
exports.createRoot = function(container: Container, options: RootOptions?): RootType
	invariant(
		isValidContainer(container),
		-- ROBLOX deviation: Use roblox engine terminology
		"createRoot(...): Target container is not a Roblox Instance."
	)
	warnIfReactDOMContainerInDEV(container)
	return ReactRobloxRoot.new(container, options)
end

exports.createBlockingRoot =
	function(container: Container, options: RootOptions?): RootType
		invariant(
			isValidContainer(container),
			-- ROBLOX deviation: Use roblox engine terminology
			"createRoot(...): Target container is not a Roblox Instance."
		)
		warnIfReactDOMContainerInDEV(container)
		return createBlockingRoot(container, BlockingRoot, options)
	end

exports.createLegacyRoot = function(container: Container, options: RootOptions?): RootType
	return createBlockingRoot(container, LegacyRoot, options)
end

function warnIfReactDOMContainerInDEV(container)
	if _G.__DEV__ then
		-- ROBLOX TODO: This behavior will deviate; should we validate that the
		-- container is not a PlayerGui of any sort?

		-- if
		--   container.nodeType == ELEMENT_NODE and
		--   container.tagName and
		--   container.tagName.toUpperCase() == 'BODY'
		-- then
		--   console.error(
		--     'createRoot(): Creating roots directly with document.body is ' ..
		--       'discouraged, since its children are often manipulated by third-party ' ..
		--       'scripts and browser extensions. This may lead to subtle ' ..
		--       'reconciliation issues. Try using a container element created ' ..
		--       'for your app.'
		--   )
		-- end
		-- if isContainerMarkedAsRoot(container) then
		--   if container._reactRootContainer then
		--     console.error(
		--       'You are calling ReactDOM.createRoot() on a container that was previously ' ..
		--         'passed to ReactDOM.render(). This is not supported.'
		--     )
		--   else
		--     console.error(
		--       'You are calling ReactDOM.createRoot() on a container that ' ..
		--         'has already been passed to createRoot() before. Instead, call ' ..
		--         'root.render() on the existing root instead if you want to update it.'
		--     )
		--   end
		-- end
	end
end

return exports

end,
["react-roblox/client/roblox/getDefaultInstanceProperty"]=function()
-- ROBLOX upstream: https://github.com/Roblox/roact/blob/b2ba9cf4c219c2654e6572219a68d0bf1b541418/src/getDefaultInstanceProperty.lua
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the Apache License, Version 2.0 (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     http://www.apache.org/licenses/LICENSE-2.0
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

--[[
	Attempts to get the default value of a given property on a Roblox instance.

	This is used by the reconciler in cases where a prop was previously set on a
	primitive component, but is no longer present in a component's new props.

	Eventually, Roblox might provide a nicer API to query the default property
	of an object without constructing an instance of it.
]]

local Symbol = require(script.Parent.Parent.Parent.Parent:WaitForChild('shared')).Symbol

local Nil = Symbol.named("Nil")
local _cachedPropertyValues = {}

local function tryPropertyName(instance, propertyName)
	return instance[propertyName]
end

local function getDefaultInstanceProperty(className, propertyName)
	local classCache = _cachedPropertyValues[className]

	if classCache then
		local propValue = classCache[propertyName]

		-- We have to use a marker here, because Lua doesn't distinguish
		-- between 'nil' and 'not in a table'
		if propValue == Nil then
			return true, nil
		end

		if propValue ~= nil then
			return true, propValue
		end
	else
		classCache = {}
		_cachedPropertyValues[className] = classCache
	end

	local created = Instance.new(className)
	local ok, defaultValue = pcall(tryPropertyName, created, propertyName)

	created:Destroy()

	if ok then
		if defaultValue == nil then
			classCache[propertyName] = Nil
		else
			classCache[propertyName] = defaultValue
		end
	end

	return ok, defaultValue
end

return getDefaultInstanceProperty

end,
["react-roblox/client/roblox/RobloxComponentProps"]=function()
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
local __DEV__ = _G.__DEV__ :: boolean
local CollectionService = game:GetService("CollectionService")
local LuauPolyfill = require(script.Parent.Parent.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object
local inspect = LuauPolyfill.util.inspect

local console = require(script.Parent.Parent.Parent.Parent:WaitForChild('shared')).console

local React = require(script.Parent.Parent.Parent.Parent:WaitForChild('react'))
local ReactSymbols = require(script.Parent.Parent.Parent.Parent:WaitForChild('shared')).ReactSymbols
local SingleEventManager = require(script.Parent:WaitForChild('SingleEventManager'))
type EventManager = SingleEventManager.EventManager
local Type = require(script.Parent.Parent.Parent.Parent:WaitForChild('shared')).Type
local getDefaultInstanceProperty = require(script.Parent:WaitForChild('getDefaultInstanceProperty'))
local ReactRobloxHostTypes = require(script.Parent.Parent:WaitForChild('ReactRobloxHostTypes.roblox'))
type HostInstance = ReactRobloxHostTypes.HostInstance
local Tag = require(script.Parent.Parent.Parent.Parent:WaitForChild('react')).Tag

-- ROBLOX deviation: Essentially a placeholder for dom-specific logic, taking the place
-- of ReactDOMComponent. Most of the logic will differ pretty dramatically

type Array<T> = { [number]: T }
type Object = { [any]: any }

-- deviation: Can't assign attributes to Roblox instances, so we use maps to
-- store associated data for host instance features like binding and event
-- management
-- ROBLOX FIXME: Stronger typing for EventManager

local instanceToEventManager: { [HostInstance]: EventManager } = {}
local instanceToBindings: { [HostInstance]: { [string]: any } } = {}

local applyPropsError = [[
Error applying initial props to Roblox Instance '%s' (%s):
  %s
]]

local updatePropsError = [[
Error updating props on Roblox Instance '%s' (%s):
  %s
]]

local updateBindingError = [[
Error updating binding or ref assigned to key %s of '%s' (%s).

Updated value:
  %s

Error:
  %s

%s
]]

local function identity(...)
	return ...
end

local function setRobloxInstanceProperty(hostInstance, key, newValue): ()
	if newValue == nil then
		local success, _ = pcall(hostInstance.ResetPropertyToDefault, hostInstance, key)
		if success then
			return
		end

		local hostClass = hostInstance.ClassName
		local _, defaultValue = getDefaultInstanceProperty(hostClass, key)
		newValue = defaultValue
	end

	-- Assign the new value to the object
	hostInstance[key] = newValue
end

local function removeBinding(hostInstance, key)
	local bindings = instanceToBindings[hostInstance]
	if bindings ~= nil then
		local disconnect = bindings[key]
		disconnect()
		bindings[key] = nil
	end
end

local function attachBinding(hostInstance, key, newBinding): ()
	local function updateBoundProperty(newValue)
		local success, errorMessage =
			xpcall(setRobloxInstanceProperty, identity, hostInstance, key, newValue)

		if not success then
			local source = newBinding._source or "<enable DEV mode for stack>"
			local fullMessage = string.format(
				updateBindingError,
				key,
				hostInstance.Name,
				hostInstance.ClassName,
				tostring(newValue),
				errorMessage,
				source
			)
			console.error(fullMessage)
			-- FIXME: Until console.error can be instrumented to send telemetry, we
			-- need to keep the hard error here
			error(fullMessage, 0)
		end
	end

	if instanceToBindings[hostInstance] == nil then
		instanceToBindings[hostInstance] = {}
	end

	instanceToBindings[hostInstance][key] =
		React.__subscribeToBinding(newBinding, updateBoundProperty)

	updateBoundProperty(newBinding:getValue())
end

local function applyTags(hostInstance: Instance, oldTags: string?, newTags: string?)
	if __DEV__ then
		if newTags ~= nil and typeof(newTags) ~= "string" then
			console.error(
[[Type provided for ReactRoblox.Tag is invalid - tags should be specified as a single string, with individual tags delimited by spaces. Instead received:
%s]]
,
				inspect(newTags)
			)
			return
		end
	end

	local oldTagSet = {}
	for str in string.gmatch(oldTags or "", "%S+") do
		oldTagSet[str] = true
	end
	local newTagSet = {}
	for str in string.gmatch(newTags or "", "%S+") do
		newTagSet[str] = true
	end

	for tag, _ in oldTagSet do
		if not newTagSet[tag] then
			CollectionService:RemoveTag(hostInstance, tag)
		end
	end
	for tag, _ in newTagSet do
		if not oldTagSet[tag] then
			CollectionService:AddTag(hostInstance, tag)
		end
	end
end

local function removeAllTags(hostInstance: Instance)
	for _, tag in CollectionService:GetTags(hostInstance) do
		CollectionService:RemoveTag(hostInstance, tag)
	end
end

local function applyProp(hostInstance: Instance, key, newValue, oldValue): ()
	-- ROBLOX performance: gets checked in applyProps so we can assume the key is valid
	-- if key == "ref" or key == "children" then
	--   return
	-- end

	local internalKeyType = Type.of(key)

	if internalKeyType == Type.HostEvent or internalKeyType == Type.HostChangeEvent then
		local eventManager = instanceToEventManager[hostInstance]
		if eventManager == nil then
			eventManager = (SingleEventManager.new(hostInstance) :: any) :: EventManager
			instanceToEventManager[hostInstance] = eventManager
		end

		local eventName = key.name

		if internalKeyType == Type.HostChangeEvent then
			eventManager:connectPropertyChange(eventName, newValue)
		else
			eventManager:connectEvent(eventName, newValue)
		end

		return
	end

	-- Handle bindings
	local newIsBinding = typeof(newValue) == "table"
		and newValue["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE
	local oldIsBinding = oldValue ~= nil
		and typeof(oldValue) == "table"
		and oldValue["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE
	if oldIsBinding then
		removeBinding(hostInstance, key)
	end

	if newIsBinding then
		attachBinding(hostInstance, key, newValue)
	elseif key == Tag then
		applyTags(hostInstance, oldValue, newValue)
	else
		setRobloxInstanceProperty(hostInstance, key, newValue)
	end
end

local function applyProps(hostInstance: Instance, props: Object): ()
	for propKey, value in props do
		-- ROBLOX performance: avoid the function call by inlining check here
		if propKey == "ref" or propKey == "children" then
			continue
		end

		applyProp(hostInstance, propKey, value)
	end
end

local function setInitialProperties(
	domElement: HostInstance,
	_tag: string,
	rawProps: Object,
	_rootContainerElement: HostInstance
): ()
	-- deviation: Use Roact's prop application logic
	local success, errorMessage = xpcall(applyProps, identity, domElement, rawProps)
	-- ROBLOX deviation: Roblox renderer doesn't currently track where instances
	-- were created the way that legacy Roact did, but DEV mode should include
	-- component stack traces as a separate warning
	if not success then
		local fullMessage = string.format(
			applyPropsError,
			domElement.Name,
			domElement.ClassName,
			errorMessage
		)
		console.error(fullMessage)
		-- FIXME: Until console.error can be instrumented to send telemetry, we need
		-- to keep the hard error here
		error(fullMessage, 0)
	end

	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement]:resume()
	end
end

local function safelyApplyProperties(
	domElement: HostInstance,
	updatePayload: Array<any>,
	lastProps: Object
): ()
	local updatePayloadCount = #updatePayload
	for i = 1, updatePayloadCount, 2 do
		local propKey = updatePayload[i]
		local value = updatePayload[i + 1]
		if value == Object.None then
			value = nil
		end
		-- ROBLOX performance: avoid the function call by inlining check here
		if propKey ~= "ref" and propKey ~= "children" then
			applyProp(domElement, propKey, value, lastProps[propKey])
		end
	end
end

local function updateProperties(
	domElement: HostInstance,
	updatePayload: Array<any>,
	lastProps: Object
): ()
	-- deviation: Use Roact's prop application logic
	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement]:suspend()
	end

	local success, errorMessage =
		xpcall(safelyApplyProperties, identity, domElement, updatePayload, lastProps)

	if not success then
		-- ROBLOX deviation: Roblox renderer doesn't currently track where instances
		-- were created the way that legacy Roact did, but DEV mode should include
		-- component stack traces as a separate warning
		local fullMessage = string.format(
			updatePropsError,
			domElement.Name,
			domElement.ClassName,
			errorMessage
		)
		console.error(fullMessage)
		-- FIXME: Until console.error can be instrumented to send telemetry, we need
		-- to keep the hard error here
		error(fullMessage, 0)
	end

	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement]:resume()
	end
end

local function cleanupBindings(domElement: HostInstance)
	local instanceBindings = instanceToBindings[domElement]
	if instanceBindings ~= nil then
		for _, disconnectBinding in instanceBindings do
			disconnectBinding()
		end
		instanceToBindings[domElement] = nil
	end
end

-- ROBLOX deviation: Clear out references to components when they unmount so we
-- avoid leaking memory when they're removed
local function cleanupHostComponent(domElement: HostInstance)
	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement] = nil
	end

	cleanupBindings(domElement)

	-- ROBLOX https://jira.rbx.com/browse/LUAFDN-718: Tables are somehow ending up
	-- in this function that expects Instances. In that case, we won't be able to
	-- iterate through its descendants.
	if typeof(domElement :: any) ~= "Instance" then
		return
	end

	removeAllTags(domElement)
	for _, descElement in domElement:GetDescendants() do
		if instanceToEventManager[descElement] ~= nil then
			instanceToEventManager[descElement] = nil
		end
		
		cleanupBindings(descElement)
		removeAllTags(domElement)
	end
end

return {
	setInitialProperties = setInitialProperties,
	updateProperties = updateProperties,
	cleanupHostComponent = cleanupHostComponent,

	-- ROBLOX deviation: expose maps to test for Instance cleanups
	_instanceToEventManager = instanceToEventManager,
	_instanceToBindings = instanceToBindings,
}

end,
["react-roblox/client/roblox/SingleEventManager"]=function()
-- ROBLOX upstream: https://github.com/Roblox/roact/blob/b2ba9cf4c219c2654e6572219a68d0bf1b541418/src/SingleEventManager.lua
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the Apache License, Version 2.0 (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     http://www.apache.org/licenses/LICENSE-2.0
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

--[[
	A manager for a single host virtual node's connected events.
]]

local console = require(script.Parent.Parent.Parent.Parent:WaitForChild('shared')).console
type Function = (...any) -> ...any

local CHANGE_PREFIX = "Change."

local EventStatus = {
	-- No events are processed at all; they're silently discarded
	Disabled = "Disabled",

	-- Events are stored in a queue; listeners are invoked when the manager is resumed
	Suspended = "Suspended",

	-- Event listeners are invoked as the events fire
	Enabled = "Enabled",
}

export type EventManager = {
	connectPropertyChange: (self: any, eventName: string, newValue: any) -> (),
	connectEvent: (self: any, eventName: string, newValue: any) -> (),
	resume: (self: any) -> (),
	suspend: (self: any) -> ()
}

local SingleEventManager = {}
SingleEventManager.__index = SingleEventManager

function SingleEventManager.new(instance: Instance): EventManager
	local self = setmetatable({
		-- The queue of suspended events
		_suspendedEventQueue = {},

		-- All the event connections being managed
		-- Events are indexed by a string key
		_connections = {},

		-- All the listeners being managed
		-- These are stored distinctly from the connections
		-- Connections can have their listeners replaced at runtime
		_listeners = {},

		-- The suspension status of the manager
		-- Managers start disabled and are "resumed" after the initial render
		_status = EventStatus.Disabled,

		-- If true, the manager is processing queued events right now.
		_isResuming = false,

		-- The Roblox instance the manager is managing
		_instance = instance,
	}, SingleEventManager)

	return (self :: any) :: EventManager
end

function SingleEventManager:connectEvent(key, listener)
	self:_connect(key, self._instance[key], listener)
end

function SingleEventManager:connectPropertyChange(key, listener)
	local success, event =
		pcall(self._instance.GetPropertyChangedSignal, self._instance, key)

	if not success then
		error(
			string.format(
				"Cannot get changed signal on property %q: %s",
				tostring(key),
				event
			),
			0
		)
	end

	self:_connect(CHANGE_PREFIX .. key, event, listener)
end

function SingleEventManager:_connect(eventKey, event, listener)
	-- If the listener doesn't exist we can just disconnect the existing connection
	if listener == nil then
		if self._connections[eventKey] ~= nil then
			self._connections[eventKey]:Disconnect()
			self._connections[eventKey] = nil
		end

		self._listeners[eventKey] = nil
	else
		if self._connections[eventKey] == nil then
			self._connections[eventKey] = event:Connect(function(...)
				if self._status == EventStatus.Enabled then
					self._listeners[eventKey](self._instance, ...)
				elseif self._status == EventStatus.Suspended then
					-- Store this event invocation to be fired when resume is
					-- called.

					local argumentCount = select("#", ...)
					table.insert(
						self._suspendedEventQueue,
						{ eventKey, argumentCount, ... }
					)
				end
			end)
		end

		self._listeners[eventKey] = listener
	end
end

function SingleEventManager:suspend()
	self._status = EventStatus.Suspended
end

function SingleEventManager:resume()
	-- If we're already resuming events for this instance, trying to resume
	-- again would cause a disaster.
	if self._isResuming then
		return
	end

	self._isResuming = true

	-- More events might be added to the queue when evaluating events, so we
	-- need to be careful in order to preserve correct evaluation order.
	for _, eventInvocation in self._suspendedEventQueue do
		local listener = self._listeners[eventInvocation[1] ]
		local argumentCount = eventInvocation[2]

		-- The event might have been disconnected since suspension started; in
		-- this case, we drop the event.
		if listener ~= nil then
			-- Wrap the listener in a coroutine to catch errors and handle
			-- yielding correctly.
			local listenerCo = coroutine.create(listener)
			local success, result = coroutine.resume(
				listenerCo,
				self._instance,
				unpack(eventInvocation, 3, 2 + argumentCount)
			)

			-- If the listener threw an error, we log it as a warning, since
			-- there's no way to write error text in Roblox Lua without killing
			-- our thread!
			if not success then
				console.warn("%s", result)
			end
		end
	end

	self._isResuming = false
	self._status = EventStatus.Enabled
	table.clear(self._suspendedEventQueue)
end

return SingleEventManager

end,
["react-roblox"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/efd8f6442d1aa7c4566fe812cba03e7e83aaccc3/packages/react-native-renderer/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local HostTypes = require(script:WaitForChild('client'):WaitForChild('ReactRobloxHostTypes.roblox'))
export type RootType = HostTypes.RootType
return require(script:WaitForChild('client'):WaitForChild('ReactRoblox'))
end,
["react-roblox/ReactReconciler.roblox"]=function()
--!strict
-- ROBLOX deviation: Initializes the reconciler with this package's host
-- config and returns the resulting module

local initializeReconciler = require(script.Parent.Parent:WaitForChild('react-reconciler'))

local ReactRobloxHostConfig = require(script.Parent:WaitForChild('client'):WaitForChild('ReactRobloxHostConfig'))

return initializeReconciler(ReactRobloxHostConfig)

end,
}

-- jsdotlua/react@17.2.1; see THIRD_PARTY_NOTICES.md
return {
["react/createSignal.roblox"]=function()
--!strict
-- ROBLOX upstream: https://github.com/Roblox/roact/blob/master/src/createSignal.lua
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

type Function = (...any) -> ...any
--[[
	This is a simple signal implementation that has a dead-simple API.

		local signal = createSignal()

		local disconnect = signal:subscribe(function(foo)
			print("Cool foo:", foo)
		end)

		signal:fire("something")

		disconnect()
]]

type Connection = { callback: Function, disconnected: boolean }
type Map<K, V> = { [K]: V }

local function createSignal(): ((Function) -> (() -> ()), (...any) -> ())
	local connections: Map<Function, Connection> = {}
	local suspendedConnections = {}
	local firing = false

	local function subscribe(callback)
		assert(
			typeof(callback) == "function",
			"Can only subscribe to signals with a function."
		)

		local connection = {
			callback = callback,
			disconnected = false,
		}

		-- If the callback is already registered, don't add to the suspendedConnection. Otherwise, this will disable
		-- the existing one.
		if firing and not connections[callback] then
			suspendedConnections[callback] = connection
		end

		connections[callback] = connection

		local function disconnect()
			assert(
				not connection.disconnected,
				"Listeners can only be disconnected once."
			)

			connection.disconnected = true
			connections[callback] = nil
			suspendedConnections[callback] = nil
		end

		return disconnect
	end

	local function fire(...)
		firing = true
		for callback, connection in connections do
			if not connection.disconnected and not suspendedConnections[callback] then
				callback(...)
			end
		end

		firing = false

		-- ROBLOX performance: use table.clear
		table.clear(suspendedConnections)
	end

	return subscribe, fire
end

return createSignal

end,
["react"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react/src/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 *]]

-- ROBLOX deviation: simulates `index.js` and exports React's public interface
local LuauPolyfill = require(script.Parent:WaitForChild('luau-polyfill'))
export type Object = LuauPolyfill.Object

local React = require(script:WaitForChild('React'))-- ROBLOX deviation START: bindings support

export type Binding<T> = React.ReactBinding<T>
export type BindingUpdater<T> = React.ReactBindingUpdater<T>
-- ROBLOX deviation END

local ReactLazy = require(script:WaitForChild('ReactLazy'))
export type LazyComponent<T, P> = ReactLazy.LazyComponent<T, P>

local SharedModule = require(script.Parent:WaitForChild('shared'))
export type StatelessFunctionalComponent<P> =
	SharedModule.React_StatelessFunctionalComponent<P>
-- ROBLOX deviation START: we use the definitely-typed version of this, which appears to work for flowtype in VirtualizedList, etc
export type ComponentType<P> = ComponentClass<P> | FC<P>
-- ROBLOX deviation END
export type AbstractComponent<Config, Instance> = SharedModule.React_AbstractComponent<
	Config,
	Instance
>
export type ElementType = SharedModule.React_ElementType
export type Element<C> = SharedModule.React_Element<C>
export type Key = SharedModule.React_Key
export type Ref<ElementType> = SharedModule.React_Ref<ElementType>
export type Node = SharedModule.React_Node
export type Context<T> = SharedModule.ReactContext<T>
-- ROBLOX TODO: Portal
export type ElementProps<C> = SharedModule.React_ElementProps<C>
export type ElementConfig<T> = SharedModule.React_ElementConfig<T>
export type ElementRef<C> = SharedModule.React_ElementRef<C>
-- ROBLOX TODO: Config
-- ROBLOX TODO: ChildrenArray

-- ROBLOX deviation START: manual type exports since that's not free with 'return React'
export type ComponentClass<P> = SharedModule.React_ComponentType<P>
export type PureComponent<Props, State = nil> = React.PureComponent<Props, State>
-- ROBLOX deviation END

-- ROBLOX deviation START: definitelytyped typescript exports
export type ReactElement<Props = Object, ElementType = any> = SharedModule.ReactElement<
	Props,
	ElementType
>
-- we don't include ReactText in ReactChild since roblox renderer doesn't support raw text nodes
export type ReactChild = SharedModule.ReactElement<any, string> | string | number
export type FC<P> = SharedModule.React_StatelessFunctionalComponent<P>
export type ReactNode = SharedModule.React_Node
-- ROBLOX deviation END

-- ROBLOX deviation START: export React types that are flowtype built-ins and used by VirtualizedList, etc
export type React_AbstractComponent<Props, Instance> = SharedModule.React_Component<
	Props,
	Instance
>
export type React_FowardRefComponent<Props, Instance> =
	SharedModule.React_ForwardRefComponent<Props, Instance>
export type React_MemoComponent<Config, T> = SharedModule.React_MemoComponent<Config, T>
export type React_Component<Props, State> = SharedModule.React_Component<Props, State>
export type React_ComponentType<P> = SharedModule.React_ComponentType<P>
export type React_Context<T> = SharedModule.React_Context<T>
export type React_Element<ElementType> = SharedModule.React_Element<ElementType>
export type React_ElementType = SharedModule.React_ElementType
export type React_Node = SharedModule.React_Node

-- ROBLOX deviation END

return React

end,
["react/None.roblox"]=function()
--!strict
-- code derived from https://github.com/Roblox/roact/blob/master/src/None.lua
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

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
-- Roact uses `Object.assign` internally to assign new state values; the same
-- None value should give us the proper semantics. We can re-export this value
-- as React.None for easy use, and to mirror Roact.None in legacy Roact.

return LuauPolyfill.Object.None

end,
["react/React"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react/src/React.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 *]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Object = LuauPolyfill.Object

local createMutableSource = require(script.Parent:WaitForChild('ReactMutableSource'))
local ReactSharedInternals = require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals
local ReactBaseClasses = require(script.Parent:WaitForChild('ReactBaseClasses'))
local ReactChildren = require(script.Parent:WaitForChild('ReactChildren'))
local ReactElementValidator = require(script.Parent:WaitForChild('ReactElementValidator'))
local ReactElement = require(script.Parent:WaitForChild('ReactElement'))
local ReactCreateRef = require(script.Parent:WaitForChild('ReactCreateRef'))
local ReactForwardRef = require(script.Parent:WaitForChild('ReactForwardRef'))
local ReactHooks = require(script.Parent:WaitForChild('ReactHooks'))
local ReactMemo = require(script.Parent:WaitForChild('ReactMemo'))
local ReactContext = require(script.Parent:WaitForChild('ReactContext'))
local ReactLazy = require(script.Parent:WaitForChild('ReactLazy'))
type LazyComponent<T, P> = ReactLazy.LazyComponent<T, P>

-- ROBLOX DEVIATION: Bindings
local ReactBinding = require(script.Parent:WaitForChild('ReactBinding.roblox'))-- ROBLOX DEVIATION: Re-export `None` marker

local ReactNone = require(script.Parent:WaitForChild('None.roblox'))

local SharedModule = require(script.Parent.Parent:WaitForChild('shared'))
local ReactSymbols = SharedModule.ReactSymbols

local shouldValidate = _G.__DEV__ or _G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__
local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
export type React_StatelessFunctionalComponent<P> =
	ReactTypes.React_StatelessFunctionalComponent<P>
export type React_ComponentType<P> = ReactTypes.React_ComponentType<P>
type React_AbstractComponent<P, T> = ReactTypes.React_AbstractComponent<P, T>
export type React_ElementProps<ElementType> = ReactTypes.React_ElementProps<ElementType>
export type ReactElement<P = Object, T = any> = ReactTypes.ReactElement<P, T>
export type ReactContext<T> = ReactTypes.ReactContext<T>
export type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
export type React_Node = ReactTypes.React_Node
export type PureComponent<Props, State = nil> = ReactTypes.React_PureComponent<
	Props,
	State
>
-- ROBLOX deviation START: bindings support
export type ReactBinding<T> = ReactTypes.ReactBinding<T>
export type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
-- ROBLOX deviation END

type createElementFn = <P, T>(
	type_: React_StatelessFunctionalComponent<P>
		| React_ComponentType<P>
		| React_AbstractComponent<P, T>
		| string
		| ReactContext<any>
		| ReactProviderType<any>
		| LazyComponent<T, P>,
	props: P?,...
(React_Node | (...any) -> React_Node)
) -> ReactElement<P, T>

type cloneElementFn = <P, T>(
	element: ReactElement<P, T>,
	config: P?,...
React_Node
) -> ReactElement<P, T>
-- ROBLOX FIXME Luau: these yield Cannot call non-function because the identical unions don't collapse
-- ROBLOX FIXME Luau: the next step is to add createElementFn here and work through issues, AFTER normalization and type packs work
local createElement = if shouldValidate
	then ReactElementValidator.createElementWithValidation :: createElementFn
	else ReactElement.createElement :: createElementFn
local cloneElement: cloneElementFn = if shouldValidate
	then ReactElementValidator.cloneElementWithValidation :: cloneElementFn
	else ReactElement.cloneElement :: cloneElementFn

return {
	Children = ReactChildren,
	createMutableSource = createMutableSource,
	createRef = ReactCreateRef.createRef,
	Component = ReactBaseClasses.Component,
	PureComponent = ReactBaseClasses.PureComponent,
	createContext = ReactContext.createContext,
	forwardRef = ReactForwardRef.forwardRef,
	lazy = ReactLazy.lazy,
	memo = ReactMemo.memo,
	useCallback = ReactHooks.useCallback,
	useContext = ReactHooks.useContext,
	useEffect = ReactHooks.useEffect,
	useImperativeHandle = ReactHooks.useImperativeHandle,
	useDebugValue = ReactHooks.useDebugValue,
	useLayoutEffect = ReactHooks.useLayoutEffect,
	useMemo = ReactHooks.useMemo,
	useMutableSource = ReactHooks.useMutableSource,
	useReducer = ReactHooks.useReducer,
	useRef = ReactHooks.useRef,
	-- ROBLOX deviation: bindings support
	useBinding = ReactHooks.useBinding,
	useState = ReactHooks.useState,
	Fragment = ReactSymbols.REACT_FRAGMENT_TYPE,
	Profiler = ReactSymbols.REACT_PROFILER_TYPE,
	StrictMode = ReactSymbols.REACT_STRICT_MODE_TYPE,
	unstable_DebugTracingMode = ReactSymbols.REACT_DEBUG_TRACING_MODE_TYPE,
	Suspense = ReactSymbols.REACT_SUSPENSE_TYPE,
	createElement = createElement,
	cloneElement = cloneElement,
	isValidElement = ReactElement.isValidElement,
	-- ROBLOX TODO: ReactVersion
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = ReactSharedInternals,
	-- Deprecated behind disableCreateFactory
	-- ROBLOX TODO: createFactory,
	-- Concurrent Mode
	-- ROBLOX TODO: useTransition,
	-- ROBLOX TODO: startTransition,
	-- ROBLOX TODO: useDeferredValue,
	-- ROBLOX TODO: REACT_SUSPENSE_LIST_TYPE as SuspenseList,
	unstable_LegacyHidden = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE,
	-- enableBlocksAPI
	-- ROBLOX TODO: block,
	-- enableFundamentalAPI
	-- ROBLOX TODO: createFundamental as unstable_createFundamental,
	-- enableScopeAPI
	-- ROBLOX TODO: REACT_SCOPE_TYPE as unstable_Scope,
	-- ROBLOX TODO: useOpaqueIdentifier as unstable_useOpaqueIdentifier,

	-- ROBLOX deviation START: bindings support
	createBinding = ReactBinding.create,
	joinBindings = ReactBinding.join,
	-- ROBLOX deviation END

	-- ROBLOX DEVIATION: export the `None` placeholder for use with setState
	None = ReactNone,

	-- ROBLOX FIXME: These aren't supposed to be exposed, but they're needed by
	-- the renderer in order to update properly
	__subscribeToBinding = ReactBinding.subscribe,

	-- ROBLOX DEVIATION: export Change, Event, and Tag from React
	Event = require(script.Parent.Parent:WaitForChild('shared')).Event,
	Change = require(script.Parent.Parent:WaitForChild('shared')).Change,
	Tag = require(script.Parent.Parent:WaitForChild('shared')).Tag,

	-- ROBLOX DEVIATION: used by error reporters to parse caught errors. React
	-- stringifies at its boundaries to maintain compatibility with
	-- ScriptContext signals that may ultimately catch them
	unstable_parseReactError = require(script.Parent.Parent:WaitForChild('shared')).parseReactError,
}

end,
["react/ReactBaseClasses"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/0cf22a56a18790ef34c71bef14f64695c0498619/packages/react/src/ReactBaseClasses.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]
local __DEV__ = _G.__DEV__ :: boolean
local __COMPAT_WARNINGS__ = _G.__COMPAT_WARNINGS__ :: boolean
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Object = LuauPolyfill.Object
type Object = LuauPolyfill.Object
-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local SharedModule = require(script.Parent.Parent:WaitForChild('shared'))-- ROBLOX deviation START: we do boolean checks and error() like React 18 does to save functional call in hot path
-- local invariant = SharedModule.invariant
-- ROBLOX deviation END

type React_Component<Props, State = nil> = SharedModule.React_Component<Props, State>
local ReactNoopUpdateQueue = require(script.Parent:WaitForChild('ReactNoopUpdateQueue'))
local emptyObject = {}

if __DEV__ then
	Object.freeze(emptyObject)
end

-- ROBLOX DEVIATION: Initialize state to a singleton that warns on access and
-- errors on assignment
local UninitializedState = require(script.Parent.Parent:WaitForChild('shared')).UninitializedState

--[[*
 * Base class helpers for the updating state of a component.
]]
-- FIXME: Due to metatable inheritance, this field will be accessible and true
-- on class component _instances_ as well as class component definitions; this
-- is probably not correct
local componentClassPrototype = {
	isReactComponent = true,
}

-- ROBLOX deviation: logic to support old Roact lifecycle method names
-- ROBLOX FIXME: remove below table and function once we've formally stopped
-- supporting old Roact lifecycle method names.

-- ROBLOX FIXME Luau: have to annotate this function manually to suppress ReactBaseClasses.lua:55:3-13: (E001) TypeError: Expected to return 2 values, but 1 is returned here
local function trimPath(path: string): string
	-- ROBLOX TODO: The path splits files by . but file names can
	-- have . in them, so we use best guess heuristics to determine
	-- the file name breaks.
	-- Works for our codebase, but is pretty brittle.

	local pascalFile = string.match(path, "%.%u[%.%w]-$")
	if pascalFile then
		return string.gsub(pascalFile, "^%.", "")
	end

	return path
end

local function warnAboutExistingLifecycle(componentName, newName, existingName)
	console.warn(
		"%s already defined '%s', but it also defining the deprecated Roact method '%s'. %s should only implement one of these methods, preferably using the non-deprecated name.",
		componentName,
		existingName,
		newName,
		componentName
	)
end

local function warnAboutDeprecatedLifecycleName(componentName, newName, existingName)
	if __DEV__ and __COMPAT_WARNINGS__ then
		local path, linenum = debug.info(3, "sln")
		console.warn(
			"%s is using method '%s', which is no longer supported and should be updated to '%s'\nFile: %s:%s",
			componentName,
			newName,
			existingName,
			trimPath(path),
			tostring(linenum)
		)
	end
end

local lifecycleNames = {
	didMount = "componentDidMount",
	shouldUpdate = "shouldComponentUpdate",
	willUpdate = "UNSAFE_componentWillUpdate",
	didUpdate = "componentDidUpdate",
	willUnmount = "componentWillUnmount",
}

local function handleNewLifecycle(self, key, value)
	-- if we're defining a new lifecycle method using old naming convention
	if lifecycleNames[key] ~= nil then
		-- if the method we're defining was already defined under a different name
		if self[lifecycleNames[key] ] ~= nil then
			warnAboutExistingLifecycle(self.__componentName, key, lifecycleNames[key])
		-- special case for willUpdate which can be defined properly with 2 different names
		elseif key == "willUpdate" and self["componentWillUpdate"] then
			warnAboutExistingLifecycle(
				self.__componentName,
				key,
				"UNSAFE_componentWillUpdate"
			)
		-- otherwise if not previously defined, just warn about deprecated name
		else
			warnAboutDeprecatedLifecycleName(
				self.__componentName,
				key,
				lifecycleNames[key]
			)
		end
		-- update key to proper name
		key = lifecycleNames[key]
	end
	rawset(self, key, value)
end

local componentClassMetatable = {
	__newindex = handleNewLifecycle,
	__index = componentClassPrototype,
	__tostring = function(self)
		return self.__componentName
	end,
}

-- ROBLOX deviation: Extend needs to be a table field for our top-level interface
type React_BaseComponent = React_Component<any, any> & {
	extend: (self: React_BaseComponent, name: string) -> React_Component<any, any>
}

local Component = (
	setmetatable({ __componentName = "Component" }, componentClassMetatable) :: any
) :: React_BaseComponent

-- ROBLOX deviation: Lua doesn't expose inheritance in a class-syntax way
--[[
  A method called by consumers of Roact to create a new component class.
  Components can not be extended beyond this point, with the exception of
  PureComponent.
]]

-- ROBLOX performance: pool size tuned for benchmarks
local InstancePoolSize = if not _G.__TESTEZ_RUNNING_TEST__ then 900 else 0
local InstancePoolIndex = 1
local InstancePool = table.create(InstancePoolSize)
for i = 1, InstancePoolSize do
	table.insert(InstancePool, {
		-- pre-initialize instance fields with known static values
		props = nil,
		context = nil,
		state = UninitializedState,
		__refs = emptyObject,
		__updater = ReactNoopUpdateQueue,
	})
end

local function setStateInInit(
	componentInstance: React_Component<any, any>,
	statePayload: any,
	callback: nil
): ()
	if __DEV__ and (callback :: any) ~= nil then
		console.warn(
[[Received a `callback` argument to `setState` during initialization of "%s". The callback behavior is not supported when using `setState` in `init`.

Consider defining similar behavior in a `compontentDidMount` method instead.]]
,
			componentInstance.__componentName
		)
	end

	-- Use the same warning as in the "real" `setState` below
	local typeStatePayload = statePayload and type(statePayload)
	if
		statePayload == nil
		or (typeStatePayload ~= "table" and typeStatePayload ~= "function")
	then
		error(
[[setState(...): takes an object of state variables to update or a function which returns an object of state variables.]]		

)
	end
	local prevState = componentInstance.state
	local partialState
	if typeStatePayload == "function" then
		-- Updater function
		partialState = statePayload(prevState, componentInstance.props)
	else
		-- Partial state object
		partialState = statePayload
	end
	-- ROBLOX TODO: can't use table.clone optimization here: invalid argument #1 to 'clone' (table has a protected metatable)
	-- local newState = if prevState then table.clone(prevState) else {}
	componentInstance.state = Object.assign({}, prevState, partialState)
end

function Component:extend(name): React_Component<any, any>
	-- ROBLOX note: legacy Roact will accept nil here and default to empty string
	-- ROBLOX TODO: if name in "" in ReactComponentStack frame, we should try and get the variable name it was assigned to
	if name == nil then
		if __COMPAT_WARNINGS__ then
			console.warn(
[[Component:extend() accepting no arguments is deprecated, and will not be supported in a future version of Roact. Please provide an explicit name.]]			

)
		end
		name = ""
	elseif type(name) ~= "string" then
		error("Component class name must be a string")
	end

	-- ROBLOX performance? do table literal in one shot instead a field at a time in a pairs() loop
	local class = {
		__componentName = name,
		setState = self.setState,
		forceUpdate = self.forceUpdate,
		init = nil, -- ROBLOX note: required to make Luau analyze happy, should be removed by bytecode compiler
	}
	-- for key, value in self do
	--   -- Roact opts to make consumers use composition over inheritance, which
	--   -- lines up with React.
	--   -- https://reactjs.org/docs/composition-vs-inheritance.html
	--   if key ~= "extend" then
	--     class[key] = value
	--   end
	-- end

	class.__index = class
	-- class.__componentName = name

	function class.__ctor<P>(props: P, context, updater): React_Component<P, any>
		local instance
		-- ROBLOX performance: use a pooled object
		if InstancePoolIndex <= InstancePoolSize then
			instance = InstancePool[InstancePoolIndex]
			-- fill in the dynamic fields
			-- ROBLOX FIXME Luau: TypeError: Type 'P' could not be converted into 'nil'
			instance.props = props :: any
			instance.context = context
			-- release the premade object from the pool -- we aren't recycling objects right now
			InstancePool[InstancePoolIndex] = nil
			InstancePoolIndex += 1
		else
			-- ROBLOX note: uncomment to tune pool size for lua-apps
			-- print("!!!!! hit ReactBaseClass instance pool limit")
			instance = {
				-- ROBLOX FIXME Luau: TypeError: Type 'P' could not be converted into 'nil'
				props = props :: any,
				context = context,
				state = UninitializedState,
				__refs = emptyObject,
				__updater = updater or ReactNoopUpdateQueue,
			}

			-- instance.props = props
			-- instance.context = context
			-- ROBLOX DEVIATION: Initialize state to a singleton that warns on attempts
			-- to access this pseudo-uninitialized state and errors on attempts to directly mutate
			-- state.
			-- instance.state = UninitializedState
			-- If a component has string refs, we will assign a different object later.
			-- ROBLOX deviation: Uses __refs instead of refs to avoid conflicts
			-- instance.refs = emptyObject
			-- instance.__refs = emptyObject
			-- We initialize the default updater but the real one gets injected by the
			-- renderer.
			-- instance.__updater = updater or ReactNoopUpdateQueue
		end

		-- ROBLOX TODO: We should consider using a more idiomatic Lua approach for
		-- warning/blocking lifecycle calls during initialization. For now,
		-- ReactNoopUpdateQueue accomplishes this, but we might be able to be more
		-- thorough if we use a dummy metamethod that warns precisely on all sorts
		-- of misbehavior
		instance = setmetatable(instance, class)

		-- ROBLOX performance: only do typeof if it's non-nil to begin with
		if class.init and type(class.init) == "function" then
			-- ROBLOX deviation: Override setState to allow it to be used in init.
			-- This maintains legacy Roact behavior and allows more consistent
			-- adherance to the "never assign directly to state" rule
			instance.setState = setStateInInit

			class.init(instance, props, context)

			-- ROBLOX devition: Unbind specialized version of setState used in init
			instance.setState = nil :: any
		end

		return (instance :: any) :: React_Component<P, any>
	end

	setmetatable(class, getmetatable(self :: any))

	return (class :: any) :: React_Component<any, any>
end

--[[*
 * Sets a subset of the state. Always use this to mutate
 * state. You should treat `self.state` as immutable.
 *
 * There is no guarantee that `self.state` will be immediately updated, so
 * accessing `self.state` after calling this method may return the old value.
 *
 * There is no guarantee that calls to `setState` will run synchronously,
 * as they may eventually be batched together.  You can provide an optional
 * callback that will be executed when the call to setState is actually
 * completed.
 *
 * When a function is provided to setState, it will be called at some point in
 * the future (not synchronously). It will be called with the up to date
 * component arguments (state, props, context). These values can be different
 * from self.* because your function may be called after receiveProps but before
 * shouldComponentUpdate, and this new state, props, and context will not yet be
 * assigned to self.
 *
 * @param {object|function} partialState Next partial state or function to
 *        produce next partial state to be merged with current state.
 * @param {?function} callback Called after state is updated.
 * @final
 * @protected
 ]]
function Component:setState(partialState, callback)
	if
		partialState ~= nil
		and type(partialState) ~= "table"
		and type(partialState) ~= "function"
	then
		error(
[[setState(...): takes an object of state variables to update or a function which returns an object of state variables.]]		

)
	end
	self.__updater.enqueueSetState(self, partialState, callback, "setState")
end

--[[*
 * Forces an update. This should only be invoked when it is known with
 * certainty that we are **not** in a DOM transaction.
 *
 * You may want to call this when you know that some deeper aspect of the
 * component's state has changed but `setState` was not called.
 *
 * This will not invoke `shouldComponentUpdate`, but it will invoke
 * `componentWillUpdate` and `componentDidUpdate`.
 *
 * @param {?function} callback Called after update is complete.
 * @final
 * @protected
 ]]

function Component:forceUpdate(callback)
	self.__updater.enqueueForceUpdate(self, callback, "forceUpdate")
end
--[[*
 * Deprecated APIs. These APIs used to exist on classic React classes but since
 * we would like to deprecate them, we're not going to move them over to this
 * modern base class. Instead, we define a getter that warns if it's accessed.
 ]]

if __DEV__ then
	-- ROBLOX FIXME Luau: need CLI-53569 to remove the any cast
	local deprecatedAPIs = {
		isMounted = {
			"isMounted",
[[Instead, make sure to clean up subscriptions and pending requests in componentWillUnmount to prevent memory leaks.]]
,
		},
		replaceState = {
			"replaceState",
[[Refactor your code to use setState instead (see https://github.com/facebook/react/issues/3236).]]
,
		},
	} :: any

	local defineDeprecationWarning = function(methodName, info)
		(Component :: any)[methodName] = function()
			console.warn(
				"%s(...) is deprecated in plain JavaScript React classes. %s",
				info[1],
				info[2]
			)
			return nil
		end
	end

	for fnName, _ in deprecatedAPIs do
		if deprecatedAPIs[fnName] ~= nil then
			defineDeprecationWarning(fnName, deprecatedAPIs[fnName])
		end
	end
end

--[[*
 * Convenience component with default shallow equality check for sCU.
 ]]
-- ROBLOX deviation START: work within the `extend` framework defined above to emulate JS's
-- class inheritance

-- ROBLOX FIXME Luau: this is so we get *some* type checking despite the FIXME Luau above
local PureComponent = Component:extend("PureComponent") :: React_BaseComponent;

-- When extend()ing a component, you don't get an extend method.
-- This is to promote composition over inheritance.
-- PureComponent is an exception to this rule.
-- ROBLOX FIXME Luau: this is so we get *some* type checking despite the FIXME Luau above
(PureComponent :: any).extend = Component.extend

-- ROBLOX note: We copy members directly from the Component prototype above; we
-- don't need to redefine the constructor or do dummy function trickery to apply
-- it without jumping around
-- ROBLOX performance? inline (duplicate) explicit assignments to avoid loop overhead in hot path
-- Object.assign(pureComponentClassPrototype, componentClassPrototype)
local pureComponentClassPrototype = {
	isReactComponent = true,
	isPureReactComponent = true,
}

-- ROBLOX: FIXME: we should clean this up and align the implementations of
-- Component and PureComponent more clearly and explicitly
setmetatable(PureComponent, {
	__newindex = handleNewLifecycle,
	__index = pureComponentClassPrototype,
	__tostring = function(self)
		return self.__componentName
	end,
})
-- ROBLOX deviation END

return {
	Component = Component,
	PureComponent = PureComponent :: typeof(Component),
}

end,
["react/ReactBinding.roblox"]=function()
--!strict
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

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type Binding<T> = ReactTypes.ReactBinding<T>
type BindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>

local Symbol = LuauPolyfill.Symbol
local createSignal = require(script.Parent:WaitForChild('createSignal.roblox'))

local BindingImpl = Symbol("BindingImpl")

type BindingInternal<T> = {
	["$$typeof"]: typeof(ReactSymbols.REACT_BINDING_TYPE),
	value: T,

	getValue: (BindingInternal<T>) -> T,
	-- FIXME Luau: can't define recursive types with different parameters
	map: <U>(BindingInternal<T>, (T) -> U) -> any,

	update: (T) -> (),
	subscribe: ((T) -> ()) -> (() -> ())
}

local BindingInternalApi = {}

local bindingPrototype = {}

function bindingPrototype.getValue<T>(binding: BindingInternal<T>): T
	return BindingInternalApi.getValue(binding)
end

function bindingPrototype.map<T, U>(
	binding: BindingInternal<T>,
	predicate: (T) -> U
): Binding<U>
	return BindingInternalApi.map(binding, predicate)
end

local BindingPublicMeta = {
	__index = bindingPrototype,
	__tostring = function(self)
		return string.format("RoactBinding(%s)", tostring(self:getValue()))
	end,
}

function BindingInternalApi.update<T>(binding: any, newValue: T)
	return (binding[BindingImpl] :: BindingInternal<T>).update(newValue)
end

function BindingInternalApi.subscribe<T>(binding: any, callback: (T) -> ())
	return (binding[BindingImpl] :: BindingInternal<T>).subscribe(callback)
end

function BindingInternalApi.getValue<T>(binding: any): T
	return (binding[BindingImpl] :: BindingInternal<T>):getValue()
end

function BindingInternalApi.create<T>(initialValue: T): (Binding<T>, BindingUpdater<T>)
	local subscribe, fire = createSignal()
	local impl = {
		value = initialValue,
		subscribe = subscribe,
	}

	function impl.update(newValue: T)
		impl.value = newValue
		fire(newValue)
	end

	function impl.getValue()
		return impl.value
	end

	local source
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
		source = debug.traceback("Binding created at:", 3)
	end

	return (setmetatable({
		["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
		[BindingImpl] = impl,
		_source = source,
	}, BindingPublicMeta) :: any) :: Binding<T>,
		impl.update
end

function BindingInternalApi.map<T, U>(
	upstreamBinding: BindingInternal<T>,
	predicate: (T) -> U
): Binding<U>
	if _G.__DEV__ then
		-- ROBLOX TODO: More informative error messages here
		assert(
			typeof(upstreamBinding) == "table"
				and upstreamBinding["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE,
			"Expected `self` to be a binding"
		)
		assert(typeof(predicate) == "function", "Expected arg #1 to be a function")
	end

	local impl = {}

	function impl.subscribe(callback)
		return BindingInternalApi.subscribe(upstreamBinding, function(newValue)
			callback(predicate(newValue))
		end)
	end

	function impl.update(newValue)
		error("Bindings created by Binding:map(fn) cannot be updated directly", 2)
	end

	function impl.getValue()
		return predicate(upstreamBinding:getValue())
	end

	local source
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
		source = debug.traceback("Mapped binding created at:", 3)
	end

	return (
		setmetatable({
			["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
			[BindingImpl] = impl,
			_source = source,
		}, BindingPublicMeta) :: any
	) :: Binding<U>
end

-- The `join` API is used statically, so the input will be a table with values
-- typed as the public Binding type
function BindingInternalApi.join<T>(
	upstreamBindings: { [string | number]: Binding<any> }
): Binding<T>
	if _G.__DEV__ then
		assert(typeof(upstreamBindings) == "table", "Expected arg #1 to be of type table")

		for key, value in upstreamBindings do
			if
				typeof(value) ~= "table"
				or (value :: any)["$$typeof"] ~= ReactSymbols.REACT_BINDING_TYPE
			then
				local message = ("Expected arg #1 to contain only bindings, but key %q had a non-binding value"):format(
					tostring(key)
				)
				error(message, 2)
			end
		end
	end

	local impl = {}

	local function getValue()
		local value = {}

		-- ROBLOX FIXME Luau: needs CLI-56711 resolved to eliminate ipairs()
		for key, upstream in pairs(upstreamBindings) do
			value[key] = upstream:getValue()
		end

		return value
	end

	function impl.subscribe(callback)
		-- ROBLOX FIXME: type refinements
		local disconnects: any = {}

		for key, upstream in upstreamBindings do
			disconnects[key] = BindingInternalApi.subscribe(upstream, function(newValue)
				callback(getValue())
			end)
		end

		return function()
			if disconnects == nil then
				return
			end

			for _, disconnect in disconnects do
				disconnect()
			end

			disconnects = nil
		end
	end

	function impl.update(newValue)
		error("Bindings created by joinBindings(...) cannot be updated directly", 2)
	end

	function impl.getValue()
		return getValue()
	end

	local source
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
		source = debug.traceback("Joined binding created at:", 2)
	end

	return (
		setmetatable({
			["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
			[BindingImpl] = impl,
			_source = source,
		}, BindingPublicMeta) :: any
	) :: Binding<T>
end

return BindingInternalApi

end,
["react/ReactChildren"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/7516bdfce3f0f8c675494b5c5d0e7ae441bef1d9/packages/react/src/ReactChildren.js
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
type React_Node = ReactTypes.React_Node
type ReactElement<P, T> = ReactTypes.ReactElement<P, T>

local invariant = require(script.Parent.Parent:WaitForChild('shared')).invariant

local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local getIteratorFn = ReactSymbols.getIteratorFn
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_PORTAL_TYPE = ReactSymbols.REACT_PORTAL_TYPE

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
-- local console = LuauPolyfill.console
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local ReactElement = require(script.Parent:WaitForChild('ReactElement'))
local isValidElement = ReactElement.isValidElement
local cloneAndReplaceKey = ReactElement.cloneAndReplaceKey

local SEPARATOR = "."
local SUBSEPARATOR = ":"

-- --[[*
--  * Escape and wrap key so it is safe to use as a reactid
--  *
--  * @param {string} key to be escaped.
--  * @return {string} the escaped key.
--  ]]
--ROBLOX DEVIATION: use gsub instead of RegEx
local function escape(key: string): string
	local escapedString = string.gsub(key, "=", "=0")
	escapedString = string.gsub(escapedString, ":", "=2")
	return "$" .. escapedString
end

-- --[[*
--  * TODO: Test that a single child and an array with one item have the same key
--  * pattern.
--  ]]

-- ROBLOX DEVIATION: There is currently no good way to warn about maps
-- local didWarnAboutMaps = false

-- local userProvidedKeyEscapeRegex = '/\\/+/g'
local function escapeUserProvidedKey(text: string): string
	-- ROBLOX DEVIATION: just return the original string
	-- return text.replace(userProvidedKeyEscapeRegex, '$&/')
	return text
end

-- --[[*
--  * Generate a key string that identifies a element within a set.
--  *
--  * @param {*} element A element that could contain a manual key.
--  * @param {number} index Index that is used if a manual key is not provided.
--  * @return {string}
--  ]]
local function getElementKey(element: any, index: number): string
	-- Do some typechecking here since we call this blindly. We want to ensure
	-- that we don't block potential future ES APIs.
	if typeof(element) == "table" and element ~= nil and element.key ~= nil then
		-- Explicit key
		return escape(tostring(element.key))
	end
	-- Implicit key determined by the index in the set
	-- ROBLOX DEVIATION: unsupported radix arg in tostring(number)
	-- return index.toString(36)
	return tostring(index)
end

local function mapIntoArray(
	children: ReactNodeList?,
	array: Array<React_Node>,
	escapedPrefix: string,
	nameSoFar: string,
	callback: (React_Node?) -> ReactNodeList?
): number
	local type = typeof(children)

	--[[
		ROBLOX DEVIATION: userdata type corresponds to React.None, which is perceived as nil. All
		userdata is treated as nil when passed as a child.
	]]
	if type == "nil" or type == "boolean" or type == "userdata" then
		-- All of the above are perceived as nil.
		children = nil
	end

	local invokeCallback = false

	if children == nil then
		invokeCallback = true
	else
		if type == "string" or type == "number" then
			invokeCallback = true
		elseif type == "table" then
			local childrenType = (children :: any)["$$typeof"]
			if
				childrenType == REACT_ELEMENT_TYPE
				or childrenType == REACT_PORTAL_TYPE
			then
				invokeCallback = true
			end
		end
	end

	if invokeCallback then
		local child = children
		local mappedChild = callback(child)
		-- If it's the only child, treat the name as if it was wrapped in an array
		-- so that it's consistent if the number of children grows:
		local childKey = if nameSoFar == ""
			then SEPARATOR .. getElementKey(child, 1)
			else nameSoFar
		if Array.isArray(mappedChild) then
			local escapedChildKey = ""
			if childKey ~= nil then
				escapedChildKey = escapeUserProvidedKey(childKey) .. "/"
			end
			mapIntoArray(mappedChild, array, escapedChildKey, "", function(c)
				return c
			end)
		elseif mappedChild ~= nil then
			if isValidElement(mappedChild :: any) then
				local mappedChildKey = (mappedChild :: ReactElement<Object, any>).key
				mappedChild = cloneAndReplaceKey(
					mappedChild :: ReactElement<Object, any>,
					-- Keep both the (mapped) and old keys if they differ, just as
					-- traverseAllChildren used to do for objects as children
					escapedPrefix
						-- $FlowFixMe Flow incorrectly thinks React.Portal doesn't have a key
						.. (
							if mappedChildKey
									and (
										not child
										or (child :: ReactElement<Object, any>).key
											~= mappedChildKey
									)
								-- $FlowFixMe Flow incorrectly thinks existing element's key can be a number
								then escapeUserProvidedKey(tostring(mappedChildKey)) .. "/"
								else ""
						)
						.. childKey
				)
			end
			table.insert(array, mappedChild)
		end
		return 1
	end

	local child
	local nextName
	local subtreeCount = 0 -- Count of children found in the current subtree.
	local nextNamePrefix = if nameSoFar == ""
		then SEPARATOR
		else nameSoFar .. SUBSEPARATOR

	if Array.isArray(children) then
		-- ROBLOX FIXME: Luau doesn't recognize this as non-nil without the `or {}`
		for i = 1, #(children :: Array<React_Node>) do
			child = (children :: Array<React_Node>)[i]
			nextName = nextNamePrefix .. getElementKey(child, i)
			subtreeCount += mapIntoArray(child, array, escapedPrefix, nextName, callback)
		end
	else
		local iteratorFn = getIteratorFn(children)
		if typeof(iteratorFn) == "function" then
			local iterableChildren: Object & {
				entries: any			
} = children :: any

			-- ROBLOX DEVIATION: No equivalent for checking if iterableChildren is a Map
			-- if _G.__DEV__ then
			-- 	-- Warn about using Maps as children
			-- 	if iteratorFn == iterableChildren.entries then
			-- 		if not didWarnAboutMaps then
			-- 			console.warn(
			-- 				"Using Maps as children is not supported. "
			-- 					.. "Use an array of keyed ReactElements instead."
			-- 			)
			-- 		end
			-- 		didWarnAboutMaps = true
			-- 	end
			-- end

			local iterator = iteratorFn(iterableChildren)
			local step
			local ii = 1
			step = iterator.next()
			while not step.done do
				child = step.value
				nextName = nextNamePrefix .. getElementKey(child, ii)
				ii += 1
				subtreeCount += mapIntoArray(
					child,
					array,
					escapedPrefix,
					nextName,
					callback
				)
				step = iterator.next()
			end
			--[[ ROBLOX DEVIATION: this condition will never be met with Roact iterator logic.
				getIteratorFn will always return a function when "children" is a table
			]]
			-- elseif type == 'table' then
			--   local childrenString = '' .. tostring(children)
			--   invariant(
			--     false,
			--     'Objects are not valid as a React child (found: %s). ' ..
			--       'If you meant to render a collection of children, use an array ' ..
			--       'instead.',
			--        if childrenString == '[object Object]'
			--          then 'object with keys {' .. Object.keys(children :: any).join(', ') .. '}'
			--          else childrenString
			--   )
		end
	end

	return subtreeCount
end

type MapFunc = (child: React_Node?, index: number) -> ReactNodeList?

--[[
	* Maps children that are typically specified as `props.children`.
	*
	* See https://reactjs.org/docs/react-api.html#reactchildrenmap
	*
	* The provided mapFunction(child, index) will be called for each
	* leaf child.
	*
	* @param {?*} children Children tree container.
	* @param {function(*, int)} func The map function.
	* @param {*} context Context for mapFunction.
	* @return {object} Object containing the ordered map of results.
]]
local function mapChildren(
	children: ReactNodeList?,
	func: MapFunc,
	context: any
): Array<React_Node>?
	if children == nil then
		return nil
	end
	local result = {}
	local count = 1
	mapIntoArray(children, result, "", "", function(child)
		-- ROBLOX DEVIATION: don't use context argument
		local mapFuncResult = func(child, count)
		count += 1
		return mapFuncResult
	end)
	return result
end

-- --[[*
--  * Count the number of children that are typically specified as
--  * `props.children`.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrencount
--  *
--  * @param {?*} children Children tree container.
--  * @return {number} The number of children.
--  ]]
local function countChildren(children: ReactNodeList?): number
	local n = 0
	mapChildren(children, function()
		n += 1
		-- Don't return anything
		return
	end)
	return n
end

type ForEachFunc = (child: React_Node?, index: number) -> ()

-- --[[*
--  * Iterates through children that are typically specified as `props.children`.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrenforeach
--  *
--  * The provided forEachFunc(child, index) will be called for each
--  * leaf child.
--  *
--  * @param {?*} children Children tree container.
--  * @param {function(*, int)} forEachFunc
--  * @param {*} forEachContext Context for forEachContext.
--  ]]
local function forEachChildren(
	children: ReactNodeList?,
	forEachFunc: ForEachFunc,
	forEachContext: any
)
	mapChildren(children, function(...)
		-- ROBLOX DEVIATION: Don't use javascript apply
		forEachFunc(...)
		-- Don't return anything.
		return
	end, forEachContext)
end

-- --[[*
--  * Flatten a children object (typically specified as `props.children`) and
--  * return an array with appropriately re-keyed children.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrentoarray
--  ]]
local function toArray(children: ReactNodeList?): Array<React_Node>
	return mapChildren(children, function(child)
		return child
	end) or {}
end

--[[*
 * Returns the first child in a collection of children and verifies that there
 * is only one child in the collection.
 *
 * See https://reactjs.org/docs/react-api.html#reactchildrenonly
 *
 * The current implementation of this function assumes that a single child gets
 * passed without a wrapper, but the purpose of this helper function is to
 * abstract away the particular structure of children.
 *
 * @param {?object} children Child collection structure.
 * @return {ReactElement} The first and only `ReactElement` contained in the
 * structure.
]]
-- ROBLOX deviation START: we skip generics here, because we can't explicitly constrain them. no annotation works as passthrough.
local function onlyChild(children)
	-- ROBLOX deviation END
	invariant(
		isValidElement(children),
		"React.Children.only expected to receive a single React element child."
	)
	return children
end

return {
	forEach = forEachChildren,
	map = mapChildren,
	count = countChildren,
	only = onlyChild,
	toArray = toArray,
}

end,
["react/ReactContext"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/7516bdfce3f0f8c675494b5c5d0e7ae441bef1d9/packages/react/src/ReactContext.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
]]
-- ROBLOX: use patched console from shared
local Shared = require(script.Parent.Parent:WaitForChild('shared'))
local console = Shared.console

local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
type ReactContext<T> = Shared.ReactContext<T>
type ReactProviderType<T> = Shared.ReactProviderType<T>

local exports = {}

exports.createContext = function<T>(
	defaultValue: T,
	calculateChangedBits: ((a: T, b: T) -> number)?
): ReactContext<T>
	local context: ReactContext<any> = {
		["$$typeof"] = REACT_CONTEXT_TYPE,
		_calculateChangedBits = calculateChangedBits,
		-- As a workaround to support multiple concurrent renderers, we categorize
		-- some renderers as primary and others as secondary. We only expect
		-- there to be two concurrent renderers at most: React Native (primary) and
		-- Fabric (secondary); React DOM (primary) and React ART (secondary).
		-- Secondary renderers store their context values on separate fields.
		_currentValue = defaultValue,
		_currentValue2 = defaultValue,
		-- Used to track how many concurrent renderers this context currently
		-- supports within in a single renderer. Such as parallel server rendering.
		_threadCount = 0,
		-- These are circular
		Provider = (nil :: any) :: ReactProviderType<T>,
		Consumer = (nil :: any) :: ReactContext<T>,
		-- ROBLOX deviation: tables declared this way are considered sealed, so define we
		-- displayName as nil for it to be populated later
		displayName = nil,
		-- ROBLOX deviation: have to inline these optional fields to make Luau happy
		_currentRenderer = nil,
		_currentRenderer2 = nil,
	}
	context.Provider = {
		["$$typeof"] = REACT_PROVIDER_TYPE,
		_context = context,
	}

	local hasWarnedAboutDisplayNameOnConsumer = false

	if _G.__DEV__ then
		-- A separate object, but proxies back to the original context object for
		-- backwards compatibility. It has a different $$typeof, so we can properly
		-- warn for the incorrect usage of Context as a Consumer.
		local Consumer = {
			["$$typeof"] = REACT_CONTEXT_TYPE,
			_context = context,
			_calculateChangedBits = context._calculateChangedBits,
		}

		setmetatable(Consumer, {
			__index = function(self, key)
				-- deviation: don't implement already-deprecated things like Consumer.Provider, Consumer.Consumer, etc
				if key == "_currentValue" then
					return context._currentValue
				elseif key == "_currentValue2" then
					return context._currentValue2
				elseif key == "_threadCount" then
					return context._threadCount
				elseif key == "displayName" then
					return context.displayName
				end
				return nil
			end,
			__newindex = function(self, key, value)
				if key == "_currentValue" then
					context._currentValue = value
				elseif key == "_currentValue2" then
					context._currentValue2 = value
				elseif key == "_threadCount" then
					context._threadCount = value
				elseif key == "displayName" then
					if not hasWarnedAboutDisplayNameOnConsumer then
						console.warn(
							"Setting `displayName` on Context.Consumer has no effect. "
								.. "You should set it directly on the context with Context.displayName = "
								.. value
								.. "."
						)
						hasWarnedAboutDisplayNameOnConsumer = true
					end
				end
			end,
		})

		context.Consumer = (Consumer :: any) :: ReactContext<any>
	else
		context.Consumer = context
	end

	if _G.__DEV__ then
		context._currentRenderer = nil
		context._currentRenderer2 = nil
	end

	return context
end

return exports

end,
["react/ReactCreateRef"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/b87aabdfe1b7461e7331abb3601d9e6bb27544bc/packages/react/src/ReactCreateRef.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 * @flow
*]]

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type RefObject = ReactTypes.RefObject

-- ROBLOX DEVIATION: In Roact, refs are implemented in terms of bindings
--[[
  A ref is nothing more than a binding with a special field 'current'
  that maps to the getValue method of the binding
]]
local Binding = require(script.Parent:WaitForChild('ReactBinding.roblox'))

local exports = {}

-- an immutable object with a single mutable value
exports.createRef = function(): RefObject
	local binding, _ = Binding.create(nil)

	local ref = {}

	-- ROBLOX DEVIATION: Since refs are used as bindings, they can often be
	-- assigned to fields of other Instances; we track creation here parallel to
	-- how we do with bindings created via `createBinding` to improve messaging
	-- when something goes wrong
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for refs
		binding._source = debug.traceback("Ref created at:", 1)
	end

	--[[
    A ref is just redirected to a binding via its metatable
  ]]
	setmetatable(ref, {
		__index = function(self, key)
			if key == "current" then
				return binding:getValue()
			else
				return (binding :: any)[key]
			end
		end,
		__newindex = function(self, key, value)
			if key == "current" then
				-- ROBLOX FIXME: Bindings - This is not allowed in Roact, but is okay in
				-- React. Lots of discussion at
				-- https://github.com/DefinitelyTyped/DefinitelyTyped/issues/31065
				-- error("Cannot assign to the 'current' property of refs", 2)
				Binding.update(binding, value)
			end

			(binding :: any)[key] = value
		end,
		__tostring = function(self)
			return string.format("Ref(%s)", tostring(binding:getValue()))
		end,
	})

	return (ref :: any) :: RefObject
end

return exports

end,
["react/ReactElement"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react/src/ReactElement.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]
local __DEV__ = _G.__DEV__ :: boolean
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Error = LuauPolyfill.Error
type Object = LuauPolyfill.Object

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type React_StatelessFunctionalComponent<P> = ReactTypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = ReactTypes.React_ComponentType<P>
type React_AbstractComponent<P, T> = ReactTypes.React_AbstractComponent<P, T>
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
type React_ElementProps<ElementType> = ReactTypes.React_ElementProps<ElementType>
type React_Node = ReactTypes.React_Node
type ReactElement<P = Object, T = any> = ReactTypes.ReactElement<P, T>
type ReactContext<T> = ReactTypes.ReactContext<T>
type Source = ReactTypes.Source

local ReactLazy = require(script.Parent:WaitForChild('ReactLazy'))
type LazyComponent<T, P> = ReactLazy.LazyComponent<T, P>

local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
-- ROBLOX deviation START: we eliminate invariant like in React 18 to avoid string formatting and function call overhead
-- local invariant = require("@pkg/@jsdotlua/shared").invariant
-- ROBLOX deviation END
local REACT_ELEMENT_TYPE =
	require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols.REACT_ELEMENT_TYPE
local ReactCurrentOwner =
	require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals.ReactCurrentOwner
--local hasOwnProperty = Object.prototype.hasOwnProperty
-- ROBLOX deviation START: upstream iterates over this table, but we manually unroll those loops for hot path performance
-- IF THIS TABLE UPDATES, YOU MUST UPDATE THE UNROLLED LOOPS AS WELL
local RESERVED_PROPS = {
	key = true,
	ref = true,
	__self = true,
	__source = true,
}
-- ROBLOX deviation END

local specialPropKeyWarningShown, specialPropRefWarningShown, didWarnAboutStringRefs

if __DEV__ then
	didWarnAboutStringRefs = {}
end

local exports = {}

local function hasValidRef(config)
	if __DEV__ then
		-- ROBLOX DEVIATION: instead of getters, use `__index` metamethod to
		-- detect if it's a warning object
		if config.ref ~= nil and type(config.ref) == "table" then
			if (config.ref :: any).isReactWarning then
				return false
			end
		end
	end

	return config.ref ~= nil
end

local function hasValidKey(config)
	if __DEV__ then
		-- ROBLOX DEVIATION: instead of getters, use `__index` metamethod to
		-- detect if it's a warning object
		if config.key ~= nil and type(config.key) == "table" then
			if (config.key :: any).isReactWarning then
				return false
			end
		end
	end

	return config.key ~= nil
end

local reactWarning = { isReactWarning = true }

-- ROBLOX FIXME: These two warning 'getter' definitions both override the
-- metatable, and won't both work at the same time. The easy solution is to
-- define one metatable that does both instead of overwriting
local function defineKeyPropWarningGetter(props, displayName: string)
	local warnAboutAccessingKey = function()
		if __DEV__ then
			if not specialPropKeyWarningShown then
				specialPropKeyWarningShown = true
				console.error(
[[%s: `key` is not a prop. Trying to access it will result in `nil` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://reactjs.org/link/special-props)]]


,
					displayName
				)
			end
		end
	end

	-- ROBLOX deviation: clear key to ensure metamethod is called,
	-- then set key getter to call warnAboutAccessingKey
	props.key = nil
	setmetatable(props, {
		__index = function(t, k)
			if k == "key" then
				warnAboutAccessingKey()
				-- ROBLOX deviation: returns sentinel object that mimics upstream ability to check isReactWarning field
				return reactWarning
			end
			-- ROBLOX FIXME Luau: needs deferred constraint resolution
			return nil :: any
		end,
	})
end

local function defineRefPropWarningGetter(props, displayName: string)
	-- deviation: Use a __call metamethod here to make this function-like, but
	-- still able to have the `isReactWarning` flag defined on it
	local warnAboutAccessingRef = function()
		if __DEV__ then
			if not specialPropRefWarningShown then
				specialPropRefWarningShown = true
				console.error(
[[%s: `ref` is not a prop. Trying to access it will result in `nil` being returned. If you need to access the same value within the child component, you should pass it as a different prop. (https://reactjs.org/link/special-props)]]


,
					displayName
				)
			end
		end
	end

	-- ROBLOX deviation: clear key to ensure metamethod is called,
	-- then set key getter to call warnAboutAccessingKey
	props.ref = nil
	setmetatable(props :: any, {
		__index = function(t, k)
			if k == "ref" then
				warnAboutAccessingRef()
				-- ROBLOX deviation: returns sentinel object that mimics upstream ability to check isReactWarning field
				return reactWarning
			end
			-- ROBLOX FIXME Luau: needs deferred constraint resolution
			return nil :: any
		end,
	})
end

local function warnIfStringRefCannotBeAutoConverted(config)
	if __DEV__ then
		if
			-- ROBLOX deviation: We removed support for string refs, so all stringrefs cannot be auto-converted regardless
			type(config.ref) == "string" and ReactCurrentOwner.current
			-- and config.__self
			-- and ReactCurrentOwner.current.stateNode ~= config.__self
		then
			local componentName = getComponentName(ReactCurrentOwner.current.type)

			-- ROBLOX deviation: we don't support string refs and hard error instead of warn
			if not didWarnAboutStringRefs[componentName] then
				error(
					string.format(
[[Component "%s" contains the string ref "%s". Support for string refs has been removed. We recommend using useRef() or createRef() instead. Learn more about using refs safely here: https://reactjs.org/link/strict-mode-string-ref]]



,
						componentName or "Unknown",
						config.ref
					)
				)
				-- didWarnAboutStringRefs[componentName] = true
			end
		end
	end
end

--[[*
 * Factory method to create a new React element. This no longer adheres to
 * the class pattern, so do not use new to call it. Also, instanceof check
 * will not work. Instead test $$typeof field against Symbol.for('react.element') to check
 * if something is a React Element.
 *
 * @param *} type
 * @param *} props
 * @param *} key
 * @param string|object} ref
 * @param *} owner
 * @param *} self A *temporary* helper to detect places where `this` is
 * different from the `owner` when React.createElement is called, so that we
 * can warn. We want to get rid of owner and replace string `ref`s with arrow
 * functions, and as long as `this` and owner are the same, there will be no
 * change in behavior.
 * @param *} source An annotation object (added by a transpiler or otherwise)
 * indicating filename, line number, and/or other information.
 * @internal
 ]]

-- ROBLOX deviation BEGIN: extra annotations here inspired by TS and flowtype to facilitate prop checking at analyze-time
local function ReactElement<P, T>(
	type_: T,
	key,
	ref,
	self,
	source: Source?,
	owner,
	props: P
): ReactElement<P, T>
	-- ROBLOX deviation END
	local element = {
		-- Built-in properties that belong on the element
		type = type_,
		key = key,
		ref = ref,
		props = props,
		-- Record the component responsible for creating this element.
		_owner = owner,
	}

	-- This tag allows us to uniquely identify this as a React Element
	element["$$typeof"] = REACT_ELEMENT_TYPE

	if __DEV__ then
		-- The validation flag is currently mutative. We put it on
		-- an external backing store so that we can freeze the whole object.
		-- This can be replaced with a WeakMap once they are implemented in
		-- commonly used development environments.
		local nonEnumerable = {
			validated = false,
		}
		element._store = setmetatable({}, {
			-- To make comparing ReactElements easier for testing purposes, we
			-- make the validation flag non-enumerable (where possible, which
			-- should include every environment we run tests in), so the test
			-- framework ignores it.
			__index = nonEnumerable,
			__newindex = function(table, key, value)
				if key == "validated" then
					nonEnumerable.validated = value
				else
					rawset(table, key, value)
				end
			end,
		})
		-- self and source are DEV only properties.
		setmetatable(element, {
			__index = {
				_self = self,
				-- Two elements created in two different places should be considered
				-- equal for testing purposes and therefore we hide it from enumeration.
				_source = source,
			},
		})
	end

	-- ROBLOX FIXME Luau: this cast is needed until normalization lands
	return element :: any
end

----[[*
-- * https://github.com/reactjs/rfcs/pull/107
-- * @param *} type
-- * @param object} props
-- * @param string} key
-- ]]
--
--
exports.jsx = function(type, config, maybeKey)
	-- ROBLOX deviation START: skipping JSX for now, as it may never apply to Roblox
	error("JSX is currently unsupported")
	--  local propName; -- Reserved names are extracted
	--
	--  local props = }
	--  local key = nil
	--  local ref = nil; -- Currently, key can be spread in as a prop. This causes a potential
	--  -- issue if key is also explicitly declared (ie. <div ...props} key="Hi" />
	--  -- or <div key="Hi" ...props} /> ). We want to deprecate key spread,
	--  -- but as an intermediary step, we will use jsxDEV for everything except
	--  -- <div ...props} key="Hi" />, because we aren't currently able to tell if
	--  -- key is explicitly declared to be nil or not.
	--
	--  if maybeKey ~= nil)
	--    key = '' .. maybeKey
	--  end
	--
	--  if hasValidKey(config))
	--    key = '' .. config.key
	--  end
	--
	--  if hasValidRef(config))
	--    ref = config.ref
	--  } -- Remaining properties are added to a new props object
	--
	--
	--  for (propName in config)
	--    if hasOwnProperty.call(config, propName) and !RESERVED_PROPS.hasOwnProperty(propName))
	--      props[propName] = config[propName]
	--    end
	--  } -- Resolve default props
	--
	--
	--  if type and type.defaultProps)
	--    local defaultProps = type.defaultProps
	--
	--    for (propName in defaultProps)
	--      if props[propName] == nil)
	--        props[propName] = defaultProps[propName]
	--      end
	--    end
	-- end
	--
	--  return ReactElement(type, key, ref, nil, nil, ReactCurrentOwner.current, props)
	-- ROBLOX deviation END
end

--[[*
-- * https://github.com/reactjs/rfcs/pull/107
-- * @param *} type
-- * @param object} props
-- * @param string} key
-- ]]
--
exports.jsxDEV = function(type, config, maybeKey, source, self)
	-- ROBLOX deviation START: we may never support JSX
	error("JSX is currently unsupported")
	--  local propName; -- Reserved names are extracted
	--
	--  local props = }
	--  local key = nil
	--  local ref = nil; -- Currently, key can be spread in as a prop. This causes a potential
	--  -- issue if key is also explicitly declared (ie. <div ...props} key="Hi" />
	--  -- or <div key="Hi" ...props} /> ). We want to deprecate key spread,
	--  -- but as an intermediary step, we will use jsxDEV for everything except
	--  -- <div ...props} key="Hi" />, because we aren't currently able to tell if
	--  -- key is explicitly declared to be nil or not.
	--
	--  if maybeKey ~= nil)
	--    key = '' .. maybeKey
	--  end
	--
	--  if hasValidKey(config))
	--    key = '' .. config.key
	--  end
	--
	--  if hasValidRef(config))
	--    ref = config.ref
	--    warnIfStringRefCannotBeAutoConverted(config)
	--  } -- Remaining properties are added to a new props object
	--
	--
	--  for (propName in config)
	--    if hasOwnProperty.call(config, propName) and !RESERVED_PROPS.hasOwnProperty(propName))
	--      props[propName] = config[propName]
	--    end
	--  } -- Resolve default props
	--
	--
	--  if type and type.defaultProps)
	--    local defaultProps = type.defaultProps
	--
	--    for (propName in defaultProps)
	--      if props[propName] == nil)
	--        props[propName] = defaultProps[propName]
	--      end
	--    end
	--  end
	--
	--  if key or ref)
	--    local displayName = function ()
	--      if typeof type == 'function')
	--        return type.displayName or type.name or 'Unknown'
	--      end
	--
	--      return type
	--    }()
	--
	--    if key)
	--      defineKeyPropWarningGetter(props, displayName)
	--    end
	--
	--    if ref)
	--      defineRefPropWarningGetter(props, displayName)
	--    end
	--
	--  return ReactElement(type, key, ref, self, source, ReactCurrentOwner.current, props)
	return nil
	-- ROBLOX deviation END
end

--[[*
 * Create and return a new ReactElement of the given type.
 * See https://reactjs.org/docs/react-api.html#createelement
 ]]
-- ROBLOX deviation: this is TypeScript-derived annotation, but using flowtypes
--  function createElement<P extends {}>(
-- 	type: FunctionComponent<P> | ComponentClass<P> | string,
-- 	props?: Attributes & P | null,
-- 	...children: ReactNode[]): ReactElement<P>;
local function createElement<P, T>(
	type_: React_StatelessFunctionalComponent<P> | React_ComponentType<P> | React_AbstractComponent<P, T> | ReactContext<any> | LazyComponent<T, P> | ReactProviderType<any> | string,
	config: P?,
	...: React_Node | (...any) -> React_Node
): ReactElement<P, T>
	-- ROBLOX deviation START: extreme hot path, so manually unroll RESERVED_PROPS loop and use table.clone
	local props = if config ~= nil then table.clone(config :: any) :: any else {}
	-- ROBLOX deviation END
	local key: (string | number)? 	
local ref 	
local self 	
local source: Source? 
	
if config ~= nil then
		-- ROBLOX deviation START: inline hasValidRef and hasValidKey success in hot path, still call in error case for warning
		-- ROBLOX FIXME Luau: needs normalization: Type 'P & React_ElementProps<T>' could not be converted into 'React_ElementProps<T>'; none of the intersection parts are compatible
		if hasValidRef(config :: any) then
			ref = ((config :: any) :: React_ElementProps<T>).ref

			if __DEV__ then
				warnIfStringRefCannotBeAutoConverted(
					(config :: any) :: React_ElementProps<T>
				)
			end
		end

		-- ROBLOX FIXME Luau: when configKey is inline: Type 'P & React_ElementProps<T>' could not be converted into 'React_ElementProps<T>'; none of the intersection parts are compatible
		if hasValidKey(config :: any) then
			local configKey = (config :: any).key
			-- ROBLOX deviation: call tostring instead of concatenating with an
			-- empty string, which can throw in luau. If the string is a number,
			-- then do not use tostring
			if type(configKey) == "number" then
				key = configKey
			else
				-- ROBLOX FIXME Luau: narrowing bug: Type 'string' could not be converted into 'number'
				key = tostring(configKey :: any)
			end
		end
		-- ROBLOX deviation END

		-- ROBLOX deviation START: seemingly only used for string ref warnings, which we don't support
		-- self = if config.__self == nil then nil else config.__self
		-- ROBLOX deviation END

		source = if ((config :: any) :: React_ElementProps<T>).__source == nil
			then nil
			else ((config :: any) :: React_ElementProps<T>).__source

		-- Remaining properties are added to a new props object
		-- ROBLOX deviation START: extreme hot path, so manually unroll RESERVED_PROPS loop and use table.clone
		if props.key ~= nil then
			props.key = nil
		end
		if props.ref ~= nil then
			props.ref = nil
		end
		if props.__self ~= nil then
			props.__self = nil
		end
		if props.__source ~= nil then
			props.__source = nil
		end
		-- ROBLOX deviation END
	end

	-- Children can be more than one argument, and those are transferred onto
	-- the newly allocated props object.
	-- ROBLOX deviation START: we have a shortcut for capturing varargs into an array in Lua, which is more performant
	local childrenLength = select("#", ...)

	if childrenLength == 1 then
		props.children = select(1, ...)
	elseif childrenLength > 1 then
		-- ROBLOX TODO: there's a snapshot difference in storeOwners where key is 2 instead of 1 if we do `{...}`. does it matter?
		-- local childArray = {...}
		local childArray = table.create(childrenLength)
		for i = 1, childrenLength do
			local toInsert = select(i, ...)
			table.insert(childArray, toInsert)
		end

		-- ROBLOX deviation END

		if __DEV__ then
			table.freeze(childArray)
		end

		props.children = childArray
	end

	-- Resolve default props
	-- ROBLOX deviation START: Lua can't index defaultProps on a function
	-- ROBLOX FIXME Luau: should know this can be a table due to type_ intersection with React_ComponentType<>. needs normalization?
	if
		type(type_ :: any) == "table"
		and (type_ :: T & React_ComponentType<P>).defaultProps
	then
		-- ROBLOX deviation END
		-- ROBLOX FIXME Luau: defaultProps isn't narrowed by the guard above
		local defaultProps = (type_ :: T & React_ComponentType<P>).defaultProps :: P

		-- ROBLOX Luau TODO: defaultProps isn't known to be a table, since Luau doesn't allow us to do `<P extends {}>` yet
		for propName, _ in (defaultProps :: any) :: Object do
			if props[propName] == nil then
				props[propName] = ((defaultProps :: any) :: Object)[propName]
			end
		end
	end

	if __DEV__ then
		if key or ref then
			-- ROBLOX deviation START: Lua can't store fields like displayName on functions
			local displayName

			if type(type_) == "function" then
				-- displayName = (type_.displayName or type_.name) or "Unknown"
				displayName = debug.info(type_, "n") or "<function>"
			elseif type(type_) == "table" then
				displayName = (
					(type_ :: T & React_ComponentType<P>).displayName
					or (type_ :: T & React_ComponentType<P>).name
				) or "Unknown"
			else
				-- ROBLOX Luau FIXME: Luau should have narrowed type_ to string based on this above branches
				displayName = type_ :: string
			end
			-- ROBLOX deviation END

			if key then
				defineKeyPropWarningGetter(props, displayName)
			end

			if ref then
				defineRefPropWarningGetter(props, displayName)
			end
		end

		-- ROBLOX deviation START: In upstream, JSX transformation is what
		-- produces the `__source` field, so we'll just simulate it here for now
		if source == nil then
			-- go up one more because of ReactElementValidator indirection
			source = {
				fileName = debug.info(3, "s"),
				lineNumber = debug.info(3, "l"),
			}
		end
		-- ROBLOX deviation END
	end

	-- ROBLOX FIXME Luau: this cast is needed until normalization lands
	return ReactElement(
		type_,
		key,
		ref,
		self,
		source,
		ReactCurrentOwner.current,
		props
	) :: any
end
exports.createElement = createElement

----[[*
-- * Return a function that produces ReactElements of a given type.
-- * See https://reactjs.org/docs/react-api.html#createfactory
-- ]]
--
--export function createFactory(type)
--  local factory = createElement.bind(null, type); -- Expose the type on the factory and the prototype so that it can be
--  -- easily accessed on elements. E.g. `<Foo />.type == Foo`.
--  -- This should not be named `constructor` since this may not be the function
--  -- that created the element, and it may not even be a constructor.
--  -- Legacy hook: remove it
--
--  factory.type = type
--  return factory
--end
exports.cloneAndReplaceKey =
	function<P, T>(oldElement: ReactElement<P, T>, newKey: any): ReactElement<P, T>
		local newElement = ReactElement(
			oldElement.type,
			newKey,
			oldElement.ref,
			oldElement._self,
			oldElement._source,
			oldElement._owner,
			oldElement.props
		)
		return newElement
	end

--[[*
* Clone and return a new ReactElement using element as the starting point.
* See https://reactjs.org/docs/react-api.html#cloneelement
]]

exports.cloneElement = function<P, T>(
	element: ReactElement<P, T>,
	config: (P & React_ElementProps<T>)?,
	...: React_Node
): ReactElement<P, T>
	-- ROBLOX deviation START: use if instead of variant to avoid error message formatting even when there's no problem
	if element == nil then
		error(
			Error.new(
				"React.cloneElement(...): The argument must be a React element, but you passed "
					.. tostring(element)
			)
		)
	end

	-- Original props are copied
	local elementProps = element.props
	local props: P & React_ElementProps<T> = if elementProps ~= nil
		then table.clone(elementProps :: P & React_ElementProps<T>) :: any
		else {} :: P & React_ElementProps<T>

	-- Reserved names are extracted
	local key = element.key
	local ref = element.ref

	-- Self is preserved since the owner is preserved.
	-- ROBLOX deviation: _self field only used for string ref checking
	-- local self = element._self

	-- Source is preserved since cloneElement is unlikely to be targeted by a
	-- transpiler, and the original source is probably a better indicator of the
	-- true owner.
	local source = element._source

	-- Owner will be preserved, unless ref is overridden
	local owner = element._owner

	if config ~= nil then
		-- ROBLOX deviation START: inline hasValidRef and hasValidKey success in hot path, still call in error case for warning
		local configRef = config.ref
		if configRef ~= nil then
			-- Silently steal the ref from the parent.
			ref = configRef
			owner = ReactCurrentOwner.current
		else
			hasValidRef(config)
		end

		local configKey = config.key
		-- ROBLOX FIXME Luau: needs normalization, generic subtype escaping scope
		if configKey ~= nil then
			if type(configKey) == "number" then
				key = configKey
			else
				-- ROBLOX FIXME Luau: narrowing bug: Type 'string' could not be converted into 'number'
				key = configKey :: any or "nil"
			end
		else
			hasValidKey((config :: any) :: React_ElementProps<T>)
		end
		-- ROBLOX deviation END
	end

	-- Remaining properties override existing props
	local elementType = element.type
	local defaultProps: P? = if type(elementType) == "table"
		then elementType.defaultProps
		else nil

	-- ROBLOX deviation: cannot call pairs on nil the way you can use `for...in`
	-- on nil in JS, so we check for nil before iterating
	if config ~= nil then
		for propName, _ in config :: any do
			if (config :: any)[propName] ~= nil and not RESERVED_PROPS[propName] then
				if (config :: any)[propName] == nil and defaultProps ~= nil then
					-- Resolve default props
					-- ROBLOX FIXME Luau: force-cast required to avoid TypeError: Expected type table, got 'P' instead
					(props :: any)[propName] = (defaultProps :: any)[propName]
				else
					(props :: any)[propName] = (config :: any)[propName]
				end
			end
		end
	end

	-- Children can be more than one argument, and those are transferred onto
	-- the newly allocated props object.
	-- ROBLOX deviation START: we have a shortcut for capturing varargs into an array in Lua, which is more performant
	local childrenLength = select("#", ...)

	if childrenLength == 1 then
		props.children = select(1, ...)
	elseif childrenLength > 1 then
		(props :: any).children = { ... }
	end
	-- ROBLOX deviation END

	-- ROBLOX FIXME Luau: this cast is needed until normalization lands
	return ReactElement(
		element.type,
		key,
		ref,
		nil,
		source,
		owner,
		(props :: any) :: P & React_ElementProps<T>
	) :: any
end
--[[*
 * Verifies the object is a ReactElement.
 * See https://reactjs.org/docs/react-api.html#isvalidelement
 * @param ?object} object
 * @return boolean} True if `object` is a ReactElement.
 * @final
 ]]

exports.isValidElement = function(object)
	return type(object) == "table" and object["$$typeof"] == REACT_ELEMENT_TYPE
end

return exports

end,
["react/ReactElementValidator"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/bc6b7b6b16f771bfc8048fe15e211ac777253b64/packages/react/src/ReactElementValidator.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 * @flow
*]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>
local Boolean = LuauPolyfill.Boolean
local Object = LuauPolyfill.Object
type Object = LuauPolyfill.Object
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local inspect = LuauPolyfill.util.inspect
type Function = (...any) -> ...any

-- ROBLOX deviation START: import extra types
local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type React_StatelessFunctionalComponent<P> = ReactTypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = ReactTypes.React_ComponentType<P>
type React_Element<ElementType> = ReactTypes.React_Element<ElementType>
type React_ElementProps<ElementType> = ReactTypes.React_ElementProps<ElementType>
type ReactElement<P, T> = ReactTypes.ReactElement<P, T>
type React_Node = ReactTypes.React_Node
type Source = ReactTypes.Source
-- ROBLOX deviation END

local isValidElementType = require(script.Parent.Parent:WaitForChild('shared')).isValidElementType
local getComponentName = require(script.Parent.Parent:WaitForChild('shared')).getComponentName
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local getIteratorFn = ReactSymbols.getIteratorFn
local _REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local _REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE

local warnAboutSpreadingKeyToJSX =
	require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags.warnAboutSpreadingKeyToJSX
local checkPropTypes = require(script.Parent.Parent:WaitForChild('shared')).checkPropTypes
local ReactCurrentOwner =
	require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals.ReactCurrentOwner

local ReactElement = require(script.Parent:WaitForChild('ReactElement'))
local isValidElement = ReactElement.isValidElement
local createElement = ReactElement.createElement
local cloneElement = ReactElement.cloneElement
local jsxDEV = ReactElement.jsxDEV

local setExtraStackFrame =
	require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals.ReactDebugCurrentFrame.setExtraStackFrame
local describeUnknownElementTypeFrameInDEV =
	require(script.Parent.Parent:WaitForChild('shared')).ReactComponentStackFrame.describeUnknownElementTypeFrameInDEV

local exports = {}

-- ROBLOX FIXME Luau: annotation shouldn't be necessary
local function setCurrentlyValidatingElement(element: ReactElement<any, any> | nil)
	if _G.__DEV__ then
		if element then
			local owner = element._owner
			local ownerArgument 			
if owner then
				ownerArgument = owner.type
			end
			local stack = describeUnknownElementTypeFrameInDEV(
				element.type,
				element._source,
				ownerArgument
			);
			-- ROBLOX FIXME Luau: needs normalization: Cannot call non-function (() -> ()) | ((string?) -> (...any))
			(setExtraStackFrame :: (...any) -> ())(stack)
		else
			-- ROBLOX FIXME Luau: needs normalization: Cannot call non-function (() -> ()) | ((string?) -> (...any))
			(setExtraStackFrame :: (...any) -> ())(nil)
		end
	end
end

local propTypesMisspellWarningShown

if _G.__DEV__ then
	propTypesMisspellWarningShown = false
end

local function hasOwnProperty(object, key)
	return object[key] ~= nil
end

local function getDeclarationErrorAddendum(): string
	if ReactCurrentOwner.current then
		local name = getComponentName(ReactCurrentOwner.current.type)
		if name then
			return "\n\nCheck the render method of `" .. name .. "`."
		end
	end
	return ""
end

-- ROBLOX FIXME Luau: annotation shouldn't be necessary
local function getSourceInfoErrorAddendum(source: Source | nil): string
	if source ~= nil then
		local fileName = string.gsub(source.fileName, "^.*[\\/]", "")
		local lineNumber = source.lineNumber
		return "\n\nCheck your code at " .. fileName .. ":" .. lineNumber .. "."
	end
	return ""
end

-- ROBLOX FIXME Luau: needs explicit annotation, even though call site and nil check should be enough
local function getSourceInfoErrorAddendumForProps(
	elementProps: React_ElementProps<any>?
): string
	if elementProps ~= nil then
		return getSourceInfoErrorAddendum(elementProps.__source)
	end
	return ""
end

-- /**
--  * Warn if there's no key explicitly set on dynamic arrays of children or
--  * object keys are not valid. This allows us to keep track of children between
--  * updates.
--  */
local ownerHasKeyUseWarning = {}

-- ROBLOX FIXME Luau: shouldn't need this annotation on parentType
local function getCurrentComponentErrorInfo(
	parentType: React_ComponentType<any> | string | Function
): string
	local info = getDeclarationErrorAddendum()

	if not Boolean.toJSBoolean(info) then
		local parentName = if typeof(parentType) == "string"
			then parentType
			else if typeof(parentType) == "table"
				then parentType.displayName or parentType.name
				else nil

		-- ROBLOX deviation: Lua doesn't store fields on functions, so try and get the name via reflection
		if not parentName and typeof(parentType) == "function" then
			local functionName = debug.info(parentType, "n")
			-- ROBLOX note: unlike other places, upstream doesn't default the component name string in this message
			parentName = if functionName ~= "" then functionName else nil
		end

		if parentName then
			info = string.format(
				"\n\nCheck the top-level render call using <%s>.",
				parentName
			)
		end
	end
	return info
end

-- /**
--  * Warn if the element doesn't have an explicit key assigned to it.
--  * This element is in an array. The array could grow and shrink or be
--  * reordered. All children that haven't already been validated are required to
--  * have a "key" property assigned to it. Error statuses are cached so a warning
--  * will only be shown once.
--  *
--  * @internal
--  * @param {ReactElement} element Element that requires a key.
--  * @param {*} parentType element's parent's type.
--  * @param {*} tableKey ROBLOX deviation: key provided by the children table
--  */
-- ROBLOX deviation START: add explicit optional table key parameter, move key check to after we mark it validated, since we may not have an explicit key (and will use tableKey to validate)
local function validateExplicitKey<P>(
	element: ReactElement<P, any>,
	parentType,
	tableKey: any?
)
	if element._store == nil or element._store.validated then
		return
	end
	-- ROBLOX FIXME Luau: doesn't narrow based on branch above
	(element._store :: any).validated = true
	-- ROBLOX note: Consider this element valid if only _one_ key is
	-- present, otherwise proceed and check for error states
	if (element.key ~= nil) ~= (tableKey ~= nil) then
		return
	end
	-- ROBLOX deviation END
	local currentComponentErrorInfo = getCurrentComponentErrorInfo(parentType)
	if ownerHasKeyUseWarning[currentComponentErrorInfo] then
		return
	end
	ownerHasKeyUseWarning[currentComponentErrorInfo] = true

	-- // Usually the current owner is the offender, but if it accepts children as a
	-- // property, it may be the creator of the child that's responsible for
	-- // assigning it a key.
	local childOwner = ""
	if element and element._owner and element._owner ~= ReactCurrentOwner.current then
		-- // Give the component that originally created this child.
		childOwner = string.format(
			" It was passed a child from %s.",
			tostring(getComponentName(element._owner.type))
		)
	end

	if _G.__DEV__ then
		setCurrentlyValidatingElement(element)
		-- ROBLOX deviation START: Account for conflict between "key" prop and deviated table key behavior (in addition to missing key warnings)
		-- Both forms of key were provided
		if element.key ~= nil and tableKey ~= nil then
			-- ROBLOX TODO: Link to special Roact documentation that accounts
			-- for deviation instead of react docs
			console.error(
[[Child element received a "key" prop ("%s") in addition to a key in the "children" table of its parent ("%s"). Please provide only one key definition. When both are present, the "key" prop will take precedence.%s%s See https://reactjs.org/link/warning-keys for more information.]]



,
				tostring(element.key),
				tostring(tableKey),
				currentComponentErrorInfo,
				childOwner
			)
		-- No key was provided at all
		else
			console.error(
[[Each child in a list should have a unique "key" prop.%s%s See https://reactjs.org/link/warning-keys for more information.]]
,
				currentComponentErrorInfo,
				childOwner
			)
		end
		-- ROBLOX deviation END
		setCurrentlyValidatingElement(nil)
	end
end

-- /**
--  * Ensure that every element either is passed in a static location, in an
--  * array with an explicit keys property defined, or in an object literal
--  * with valid key property.
--  *
--  * @internal
--  * @param {ReactNode} node Statically passed child of any type.
--  * @param {*} parentType node's parent's type.
--  */
local function validateChildKeys(node, parentType)
	if typeof(node) ~= "table" then
		return
	end

	if Array.isArray(node) then
		for i = 1, #node do
			local child = node[i]
			if isValidElement(child) then
				validateExplicitKey(child :: ReactElement<any, any>, parentType)
			end
		end
	elseif isValidElement(node) then
		-- // This element was passed in a valid location.
		if node._store then
			node._store.validated = true
		end
	elseif node then
		local iteratorFn = getIteratorFn(node)
		if typeof(iteratorFn) == "function" then
			-- // Entry iterators used to provide implicit keys,
			-- // but now we print a separate warning for them later.
			if iteratorFn ~= node.entries then
				local iterator = iteratorFn(node)
				local step = iterator.next()
				while not step.done do
					if isValidElement(step.value) then
						validateExplicitKey(step.value, parentType, step.key)
					end

					step = iterator.next()
				end
			end
		end
	end
end

-- /**
--  * Given an element, validate that its props follow the propTypes definition,
--  * provided by the type.
--  *
--  * @param {ReactElement} element
--  */
local function validatePropTypes<P>(element: ReactElement<P, any>)
	if _G.__DEV__ or _G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		local type = element.type
		if type == nil or typeof(type) == "string" then
			return
		end

		local propTypes
		local validateProps
		if typeof(type) == "function" then
			-- deviation: function components can't have propTypes in Lua
			-- propTypes = type.propTypes
			return
		elseif typeof(type) == "table" then
			propTypes = type.propTypes
			validateProps = type.validateProps
		else
			return
		end

		if propTypes or validateProps then
			-- Intentionally inside to avoid triggering lazy initializers:
			local name = getComponentName(type)
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			checkPropTypes(propTypes, validateProps, element.props, "prop", name, element)
			-- ROBLOX TODO: upstream this any, PropTypes is a bogus key check on purpose
		elseif (type :: any).PropTypes ~= nil and not propTypesMisspellWarningShown then
			propTypesMisspellWarningShown = true
			-- Intentionally inside to avoid triggering lazy initializers:
			local name = getComponentName(type)
			console.error(
				"Component %s declared `PropTypes` instead of `propTypes`. Did you misspell the property assignment?",
				name or "Unknown"
			)
		end
		-- ROBLOX TODO: upstream this any, PropTypes is a bogus key check on purpose
		-- ROBLOX deviation: we simplify this check since we never supported this in the first place
		if (type :: any).getDefaultProps ~= nil then
			console.error(
[[getDefaultProps is only used on classic React.createClass definitions. Use a static property named `defaultProps` instead.]]			

)
		end
	end
end

-- /**
--  * Given a fragment, validate that it can only be provided with fragment props
--  * @param {ReactElement} fragment
--  */
local function validateFragmentProps<P>(fragment: ReactElement<P & Object, any>)
	if _G.__DEV__ then
		local keys = Object.keys(fragment.props)
		for i = 1, #keys do
			local key = keys[i]
			if key ~= "children" and key ~= "key" then
				setCurrentlyValidatingElement(fragment)
				console.error(
[[Invalid prop `%s` supplied to `React.Fragment`. React.Fragment can only have `key` and `children` props.]]
,
					key
				)
				setCurrentlyValidatingElement(nil)
				break
			end
		end

		if fragment.ref ~= nil then
			setCurrentlyValidatingElement(fragment)
			console.error("Invalid attribute `ref` supplied to `React.Fragment`.")
			setCurrentlyValidatingElement(nil)
		end
	end
end

-- ROBLOX deviation START: add strong types based on definitely-typed approach on createElement
local function jsxWithValidation<P, T>(
	type: T,
	props: P & React_ElementProps<T>,
	key: string | number,
	isStaticChildren,
	source: Source?,
	self: any?
)
	-- ROBLOX deviation END
	local validType = isValidElementType(type)

	-- // We warn in this case but don't throw. We expect the element creation to
	-- // succeed and there will likely be errors in render.
	if not validType then
		local info = ""
		if type == nil or (typeof(type) == "table" and #Object.keys(type) == 0) then
			info ..= ([[ You likely forgot to export your component from the file it's defined in, or you might have mixed up default and named imports.]])
		end

		local sourceInfo = getSourceInfoErrorAddendum(source)
		if sourceInfo then
			info ..= sourceInfo
		else
			info ..= getDeclarationErrorAddendum()
		end

		local typeString
		if type == nil then
			typeString = "nil"
		elseif Array.isArray(type) then
			typeString = "array"
		elseif typeof(type) == "table" and type["$$typeof"] == REACT_ELEMENT_TYPE then
			typeString = string.format("<%s />", getComponentName(type.type) or "Unknown")
			info ..= " Did you accidentally export a JSX literal or Element instead of a component?"
		else
			typeString = typeof(type)
			info ..= "\n" .. inspect(type)
		end

		if _G.__DEV__ then
			console.error(
[[React.jsx: type is invalid -- expected a string (for built-in components) or a class/function (for composite components) but got: %s.%s]]

,
				typeString,
				info
			)
		end
	end

	local element = jsxDEV(type, props, key, source, self)

	-- // The result can be nullish if a mock or a custom function is used.
	-- // TODO: Drop this when these are no longer allowed as the type argument.
	if element == nil then
		return element
	end

	-- // Skip key warning if the type isn't valid since our key validation logic
	-- // doesn't expect a non-string/function type and can throw confusing errors.
	-- // We don't want exception behavior to differ between dev and prod.
	-- // (Rendering will throw with a helpful message and as soon as the type is
	-- // fixed, the key warnings will appear.)

	if validType then
		local children = props.children
		if children ~= nil then
			if isStaticChildren then
				if Array.isArray(children) then
					for i = 1, #children do
						-- ROBLOX FIXME Luau: needs normalization
						validateChildKeys(children[i], type :: any)
					end

					-- deviation: Object.freeze always exist
					-- if Object.freeze then
					Object.freeze(children)
					-- end
				else
					if _G.__DEV__ then
						console.error(
[[React.jsx: Static children should always be an array. You are likely explicitly calling React.jsxs or React.jsxDEV. Use the Babel transform instead.]]						


)
					end
				end
			else
				-- ROBLOX FIXME Luau: needs normalization
				validateChildKeys(children, type :: any)
			end
		end
	end

	if _G.__DEV__ then
		if warnAboutSpreadingKeyToJSX then
			if hasOwnProperty(props, "key") then
				console.error(
[[React.jsx: Spreading a key to JSX is a deprecated pattern. Explicitly pass a key after spreading props in your JSX call. E.g. <%s {...props} key={key} />]]

,
					getComponentName(type) or "ComponentName"
				)
			end
		end
	end

	if type == REACT_FRAGMENT_TYPE then
		-- ROBLOX FIXME Luau: luau doesn't understand narrowing of above branch
		validateFragmentProps((element :: any) :: ReactElement<any, any>)
	else
		validatePropTypes((element :: any) :: ReactElement<any, any>)
	end

	return element
end
exports.jsxWithValidation = jsxWithValidation

-- // These two functions exist to still get child warnings in dev
-- // even with the prod transform. This means that jsxDEV is purely
-- // opt-in behavior for better messages but that we won't stop
-- // giving you warnings if you use production apis.
exports.jsxWithValidationStatic = function(type, props, key)
	return jsxWithValidation(type, props, key, true)
end

exports.jsxWithValidationDynamic = function(type, props, key)
	return jsxWithValidation(type, props, key, false)
end

-- ROBLOX deviation START: add strong types based on definitely-typed approach on createElement
local function createElementWithValidation<P, T>(
	type_: React_StatelessFunctionalComponent<
		P
	> | React_ComponentType<P> | string,
	props: (P & React_ElementProps<T>)?,
	...: React_Node
): ReactElement<P, T>
	-- ROBLOX deviation END
	local validType = isValidElementType(type_)

	-- // We warn in this case but don't throw. We expect the element creation to
	-- // succeed and there will likely be errors in render.
	if not validType then
		local info = ""
		if type_ == nil or (typeof(type_) == "table" and #Object.keys(type_) == 0) then
			info ..= ([[ You likely forgot to export your component from the file it's defined in, or you might have mixed up default and named imports.]])
		end

		local sourceInfo = getSourceInfoErrorAddendumForProps(props)
		if sourceInfo then
			info ..= sourceInfo
		else
			info ..= getDeclarationErrorAddendum()
		end

		local typeString
		if type_ == nil then
			typeString = "nil"
		elseif Array.isArray(type_) then
			typeString = "array"
		elseif
			type_ ~= nil
			and typeof(type_) == "table"
			and type_["$$typeof"] == REACT_ELEMENT_TYPE
		then
			typeString = string.format(
				"<%s />",
				getComponentName((type_ :: any).type) or "Unknown"
			)
			info ..= " Did you accidentally export a JSX literal or Element instead of a component?"
		else
			typeString = typeof(type_)
			if type_ ~= nil then
				-- ROBLOX deviation: print the table/string in readable form to give a clue, if no other info was gathered
				info ..= "\n" .. inspect(type_)
			end
		end

		if _G.__DEV__ then
			console.error(
[[React.createElement: type is invalid -- expected a string (for built-in components) or a class/function (for composite components) but got: %s.%s]]

,
				typeString,
				info
			)
		end
	end

	-- ROBLOX FIXME Luau: hard cast to any, needs normalization to avoid 'React_ComponentType<P>' could not be converted into 'React_ComponentType<P>'
	local element = createElement(type_ :: any, props, ...)

	-- // The result can be nullish if a mock or a custom function is used.
	-- // TODO: Drop this when these are no longer allowed as the type argument.
	if element == nil then
		return element
	end

	-- // Skip key warning if the type isn't valid since our key validation logic
	-- // doesn't expect a non-string/function type and can throw confusing errors.
	-- // We don't want exception behavior to differ between dev and prod.
	-- // (Rendering will throw with a helpful message and as soon as the type is
	-- // fixed, the key warnings will appear.)
	if validType then
		-- ROBLOX deviation: skips (1) type and (2) props - starts from 3 to the end varargs (iterate through children)
		for i = 1, select("#", ...) do
			-- ROBLOX deviation: selects the ith child from this function's arguments to validate
			-- ROBLOX FIXME Luau: hard cast to any, needs normalization to avoid 'React_ComponentType<P>' could not be converted into 'React_ComponentType<P>'
			validateChildKeys(select(i, ...), type_ :: any)
		end
	end

	if type_ == REACT_FRAGMENT_TYPE then
		validateFragmentProps(element)
	else
		validatePropTypes(element)
	end

	return element
end
exports.createElementWithValidation = createElementWithValidation

-- devitation: createFactory is deprecated and will be removed
-- local didWarnAboutDeprecatedCreateFactory = false

-- exports.createFactoryWithValidation = function(type)
-- 	local validatedFactory = function(...)
-- 		createElementWithValidation(type, ...)
-- 	end
-- 	-- deviation: Lua can't assign fields to functions. The 'type'
-- 	-- property is deprecated so there is no need to port this over.
-- 	-- validatedFactory.type = type

-- 	if _G.__DEV__ then
-- 		if not didWarnAboutDeprecatedCreateFactory then
-- 			didWarnAboutDeprecatedCreateFactory = true
-- 			console.warn(
-- 				"React.createFactory() is deprecated and will be removed in " ..
-- 					"a future major release. Consider using JSX " ..
-- 					"or use React.createElement() directly instead."
-- 			)
-- 		end
-- 		-- // Legacy hook: remove it
-- 		-- deviation: no porting this behavior because it is deprecated
-- 		-- Object.defineProperty(validatedFactory, "type", {
-- 		-- 	enumerable = false,
-- 		-- 	get = function()
-- 		-- 		console.warn(
-- 		-- 			"Factory.type is deprecated. Access the class directly " ..
-- 		-- 				"before passing it to createFactory."
-- 		-- 		)
-- 		-- 		Object.defineProperty(this, "type", {
-- 		-- 			value = type,
-- 		-- 		})
-- 		-- 		return type
-- 		-- 	end,
-- 		-- })
-- 	end

-- 	return validatedFactory
-- end

-- ROBLOX deviation START: add strong types based on definitely-typed approach on createElement
exports.cloneElementWithValidation = function<P, T>(
	element: ReactElement<P, T>,
	props: (P & React_ElementProps<T>)?,
	...: React_Node
): ReactElement<P, T>
	-- ROBLOX deviation END
	local arguments = { element, props, ... } :: Array<any>
	local newElement = cloneElement(element, props, ...)
	for i = 3, #arguments do
		validateChildKeys(arguments[i], newElement.type)
	end
	validatePropTypes(newElement)
	return newElement
end

return exports

end,
["react/ReactForwardRef"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/41694201988c5e651f0c3bc69921d5c9717be88b/packages/react/src/ReactForwardRef.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
*]]

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols
local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type React_Node = ReactTypes.React_Node
type React_Ref<ElementType> = ReactTypes.React_Ref<ElementType>
type React_ForwardRefComponent<Config, Instance> = ReactTypes.React_ForwardRefComponent<
	Config,
	Instance
>
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE

local exports = {}
-- ROBLOX TODO? should return Component's ELementType be REACT_FORWARD_REF_TYPE? probably, right?
exports.forwardRef =
	function<Props, ElementType>(
		render: (props: Props, ref: React_Ref<ElementType>) -> React_Node
	): React_ForwardRefComponent<Props, ElementType>
		if _G.__DEV__ then
			-- ROBLOX deviation START: Lua functions can't have properties given a table (which we can index to see if it's the Memo type)
			if
				typeof(render :: any) == "table"
				and (render :: any)["$$typeof"] == REACT_MEMO_TYPE
			then
				-- ROBLOX deviation END
				console.error(
[[forwardRef requires a render function but received a `memo` component. Instead of forwardRef(memo(...)), use memo(forwardRef(...)).]]				


)
			elseif typeof(render) ~= "function" then
				console.error(
					"forwardRef requires a render function but was given %s.",
					typeof(render)
				)
			else
				local argumentCount, _variadic = debug.info(render, "a")
				if argumentCount ~= 0 and argumentCount ~= 2 then
					console.error(
						"forwardRef render functions accept exactly two parameters: props and ref. %s",
						(function()
							if argumentCount == 1 then
								return "Did you forget to use the ref parameter?"
							end
							return "Any additional parameter will be undefined."
						end)()
					)
				end
			end

			-- deviation: in Luau, functions cannot have fields; for now, we don't
			-- support defaultProps and propTypes on function components anyways, so
			-- this check can safely be a no-op

			-- if render ~= null then
			--   if (render.defaultProps != null || render.propTypes != null) {
			--     console.error(
			--       'forwardRef render functions do not support propTypes or defaultProps. ' +
			--         'Did you accidentally pass a React component?',
			--     );
			--   }
			-- }
		end

		local elementType = {
			["$$typeof"] = REACT_FORWARD_REF_TYPE,
			render = render,
		}
		if _G.__DEV__ then
			local ownName
			-- ROBLOX deviation: use metatables to approximate Object.defineProperty logic
			setmetatable(elementType, {
				__index = function(self, key)
					if key == "displayName" then
						return ownName
					end
					return rawget(self, key)
				end,
				__newindex = function(self, key, value)
					if key == "displayName" then
						ownName = value
					-- ROBLOX deviation: render is a function and cannot have properties
					-- if (render.displayName == null) {
					--   render.displayName = name;
					-- }
					else
						rawset(self, key, value)
					end
				end,
			})
		end

		return elementType
	end

return exports

end,
["react/ReactHooks"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ddd1faa1972b614dfbfae205f2aa4a6c0b39a759/packages/react/src/ReactHooks.js
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
type Array<T> = LuauPolyfill.Array<T>
-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))-- ROBLOX TODO: we only pull in Dispatcher here for the typecheck, remove once Luau narrowing improves

type Dispatcher = ReactTypes.Dispatcher
type MutableSource<T> = ReactTypes.MutableSource<T>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<
	Source,
	Snapshot
>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
type ReactContext<T> = ReactTypes.ReactContext<T>
local ReactFiberHostConfig = require(script.Parent.Parent:WaitForChild('shared'))
type OpaqueIDType = ReactFiberHostConfig.OpaqueIDType

-- local invariant = require("@pkg/@jsdotlua/shared").invariant

local ReactCurrentDispatcher =
	require(script.Parent.Parent:WaitForChild('shared')).ReactSharedInternals.ReactCurrentDispatcher

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()

-- ROBLOX FIXME Luau: we shouldn't need to explicitly annotate this
local function resolveDispatcher(): Dispatcher
	local dispatcher = ReactCurrentDispatcher.current
	-- ROBLOX performance: upstream main only does this check in DEV mode and then not as an invariant
	if _G.__DEV__ then
		if dispatcher == nil then
			console.error(
[[Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for one of the following reasons:
1. You might have mismatching versions of React and the renderer (such as React DOM)
2. You might be breaking the Rules of Hooks
3. You might have more than one copy of React in the same app
See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.]]			

)
		end
	end
	-- Will result in a null access error if accessed outside render phase. We
	-- intentionally don't throw our own error because this is in a hot path.
	-- Also helps ensure this is inlined.
	return dispatcher :: Dispatcher
end

local exports = {}

local function useContext<T>(
	Context: ReactContext<T>,
	unstable_observedBits: number | boolean | nil,
	... -- ROBLOX deviation: Lua must specify ... here to capture additional args
): T
	local dispatcher = resolveDispatcher()
	if _G.__DEV__ then
		if unstable_observedBits ~= nil then
			console.error(
[[useContext() second argument is reserved for future use in React. Passing it is not supported. You passed: %s.%s]]

,
				unstable_observedBits,
				(typeof(unstable_observedBits) == "number" and Array.isArray({ ... }))
						and [[


Did you call Array.map(useContext)? Calling Hooks inside a loop is not supported. Learn more at https://reactjs.org/link/rules-of-hooks]]					or ""
			)
		end

		-- TODO: add a more generic warning for invalid values.
		if (Context :: any)._context ~= nil then
			local realContext = (Context :: any)._context
			-- Don't deduplicate because this legitimately causes bugs
			-- and nobody should be using this in existing code.
			if realContext.Consumer == Context then
				console.error(
[[Calling useContext(Context.Consumer) is not supported, may cause bugs, and will be removed in a future major release. Did you mean to call useContext(Context) instead?]]				)
			elseif realContext.Provider == Context then
				console.error(
[[Calling useContext(Context.Provider) is not supported. Did you mean to call useContext(Context) instead?]]				

)
			end
		end
	end
	return dispatcher.useContext(Context, unstable_observedBits)
end
exports.useContext = useContext

local function useState<S>(
	initialState: (() -> S) | S,
	...
): (S, Dispatch<BasicStateAction<S>>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useState(initialState, ...)
end
exports.useState = useState

local function useReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useReducer(reducer, initialArg, init)
end
exports.useReducer = useReducer

-- ROBLOX TODO: reconciling this with bindings and sharing any relevant Ref types (there may be different ones depending on whether it's just a loose ref, vs one being assigned to the ref prop
local function useRef<T>(initialValue: T): { current: T }
	local dispatcher = resolveDispatcher()
	return dispatcher.useRef(initialValue)
end
exports.useRef = useRef

-- ROBLOX deviation START: Bindings are a feature unique to Roact
local function useBinding<T>(
	initialValue: T
): (
	ReactTypes.ReactBinding<T>,
	ReactTypes.ReactBindingUpdater<T>
)
	local dispatcher = resolveDispatcher()
	return dispatcher.useBinding(initialValue)
end
exports.useBinding = useBinding
-- ROBLOX deviation END

local function useEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useEffect(create, deps)
end
exports.useEffect = useEffect

local function useLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useLayoutEffect(create, deps)
end
exports.useLayoutEffect = useLayoutEffect

local function useCallback<T>(callback: T, deps: Array<any> | nil): T
	local dispatcher = resolveDispatcher()
	return dispatcher.useCallback(callback, deps)
end
exports.useCallback = useCallback

local function useMemo<T...>(create: () -> T..., deps: Array<any> | nil): T...	
local dispatcher = resolveDispatcher()
	return dispatcher.useMemo(create, deps)
end
exports.useMemo = useMemo

local function useImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> any) | nil,
	create: () -> T,
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useImperativeHandle(ref, create, deps)
end
exports.useImperativeHandle = useImperativeHandle

local function useDebugValue<T>(value: T, formatterFn: ((value: T) -> any)?): ()
	if _G.__DEV__ then
		local dispatcher = resolveDispatcher()
		return dispatcher.useDebugValue(value, formatterFn)
	end

	-- deviation: return nil explicitly for safety
	return nil
end
exports.useDebugValue = useDebugValue

exports.emptyObject = {}

-- ROBLOX TODO: enable useTransition later
-- exports.useTransition = function(): ((() -> ()) -> (), boolean)
-- 	local dispatcher = resolveDispatcher()
-- 	return dispatcher.useTransition()
-- end

-- ROBLOX TODO: enable useDeferredValue later
-- exports.useDeferredValue = function<T>(value: T): T
-- 	local dispatcher = resolveDispatcher()
-- 	return dispatcher.useDeferredValue(value)
-- end

exports.useOpaqueIdentifier = function(): OpaqueIDType | nil
	local dispatcher = resolveDispatcher()
	return dispatcher.useOpaqueIdentifier()
end

exports.useMutableSource =
	function<Source, Snapshot>(
		source: MutableSource<Source>,
		getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
		subscribe: MutableSourceSubscribeFn<Source, Snapshot>
	): Snapshot
		local dispatcher = resolveDispatcher()
		return dispatcher.useMutableSource(source, getSnapshot, subscribe)
	end

return exports

end,
["react/ReactLazy"]=function()
--!nonstrict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react/src/ReactLazy.js
--[[
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 *]]

-- ROBLOX: use patched console from shared
local Shared = require(script.Parent.Parent:WaitForChild('shared'))
local console = Shared.console
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local inspect = LuauPolyfill.util.inspect

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type Wakeable = ReactTypes.Wakeable
type Thenable<R> = ReactTypes.Thenable<R>
local ReactSymbols = require(script.Parent.Parent:WaitForChild('shared')).ReactSymbols

local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE

local Uninitialized = -1
local Pending = 0
local Resolved = 1
local Rejected = 2

type UninitializedPayload<T> = {
	-- ROBLOX deviaton: Luau doesn't support literals
	--   _status: -1,
	_status: number,
	_result: () -> Thenable<{ default: T, [string]: any }>
}

type PendingPayload = {
	-- ROBLOX deviaton: Luau doesn't support literals
	-- _status: 0,
	_status: number,
	_result: Wakeable
}

type ResolvedPayload<T> = {
	-- ROBLOX deviaton: Luau doesn't support literals
	-- _status: 1,
	_status: number,
	_result: { default: T, [string]: any }
}

type RejectedPayload = {
	-- ROBLOX deviaton: Luau doesn't support literals
	-- _status: 2,
	_status: number,
	_result: any
}

type Payload<T> =
	UninitializedPayload<T>
	| PendingPayload
	| ResolvedPayload<T>
	| RejectedPayload

export type LazyComponent<T, P> = {
	["$$typeof"]: number,
	_payload: P,
	_init: (payload: P) -> T	--   ...

}

function lazyInitializer<T>(payload: Payload<T>): T
	if payload._status == Uninitialized then
		local ctor = payload._result
		local thenable = ctor()
		-- Transition to the next state.
		local pending: PendingPayload = payload :: any
		pending._status = Pending
		pending._result = thenable
		thenable:andThen(function(moduleObject)
			if payload._status == Pending then
				local defaultExport = moduleObject.default
				if _G.__DEV__ then
					if defaultExport == nil then
						console.error(
[[lazy: Expected the result of a dynamic import() call. Instead received: `%s`

Your code should look like: 
  local MyComponent = lazy(function() return reqquire(script.Parent.MyComponent) end)]]

,
							inspect(moduleObject)
						)
					end
				end
				-- Transition to the next state.
				local resolved: ResolvedPayload<T> = payload :: any
				resolved._status = Resolved
				resolved._result = defaultExport
			end
		end, function(error_)
			if payload._status == Pending then
				-- Transition to the next state.
				local rejected: RejectedPayload = payload :: any
				rejected._status = Rejected
				rejected._result = error_
			end
		end)
	end
	if payload._status == Resolved then
		return payload._result
	else
		error(payload._result)
	end
end

local exports = {}

exports.lazy = function<T>(
	ctor: () -> Thenable<{ default: T, [string]: any }>
): LazyComponent<T, Payload<T>>
	local payload: Payload<T> = {
		-- We use these fields to store the result.
		_status = -1,
		_result = ctor,
	}

	local lazyType: LazyComponent<T, Payload<T>> = {
		["$$typeof"] = REACT_LAZY_TYPE,
		_payload = payload,
		-- ROBLOX FIXME Luau: needs something even beyond normalization to avoid Property '_init' is not compatible. Type '<T>(Payload<T>) -> T?' could not be converted into '(Payload<T>) -> T?'; different number of generic type parameters
		_init = lazyInitializer :: any,
	}

	if _G.__DEV__ then
		-- In production, this would just set it on the object.
		local defaultProps
		local propTypes
		-- $FlowFixMe
		setmetatable(lazyType, {
			__index = function(self, key)
				if key == "defaultProps" then
					return defaultProps
				end
				if key == "propTypes" then
					return propTypes
				end
				return
			end,
			__newindex = function(self, key, value)
				if key == "defaultProps" then
					console.error(
[[React.lazy(...): It is not supported to assign `defaultProps` to a lazy component import. Either specify them where the component is defined, or create a wrapping component around it.]]					


)
					defaultProps = value
					-- Match production behavior more closely:
					-- $FlowFixMe
					setmetatable(self, {
						__index = function() end,
						__newindex = function() end,
					})
				end
				if key == "propTypes" then
					console.error(
[[React.lazy(...): It is not supported to assign `propTypes` to a lazy component import. Either specify them where the component is defined, or create a wrapping component around it.]]					


)
					propTypes = value
					-- Match production behavior more closely:
					-- $FlowFixMe
					setmetatable(self, {
						__index = function() end,
						__newindex = function() end,
					})
				end
			end,
		})
	end

	return lazyType
end

return exports

end,
["react/ReactMemo"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/41694201988c5e651f0c3bc69921d5c9717be88b/packages/react/src/ReactMemo.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

-- ROBLOX: use patched console from shared
local Shared = require(script.Parent.Parent:WaitForChild('shared'))
local console = Shared.console
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local inspect = LuauPolyfill.util.inspect
type React_StatelessFunctionalComponent<Props> = Shared.React_StatelessFunctionalComponent<
	Props
>
type React_ElementType = Shared.React_ElementType
type React_Component<Props, State> = Shared.React_Component<Props, State>
type React_ComponentType<Props> = Shared.React_ComponentType<Props>
type React_MemoComponent<Config, T> = Shared.React_MemoComponent<Config, T>
type React_AbstractComponent<Config, Instance> = Shared.React_AbstractComponent<
	Config,
	Instance
>

local ReactSymbols = Shared.ReactSymbols
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local isValidElementType = Shared.isValidElementType
local getComponentName = Shared.getComponentName

local exports = {}

exports.memo = function<Props, T>(
	-- ROBLOX deviation START: expanded type pulled from definitelytyped, not sure why upstream doesn't accept function component types
	-- ROBLOX TODO Luau: React_Component<Props, any> gave me  Type 'React_Component<any, any>' could not be converted into '((any, any) -> (Array<(Array<<CYCLE>> | React_Element<any> | boolean | number | string)?> | React_Element<any> | boolean | number | string)?) | string'; none of the union options are compatible
	type_: React_StatelessFunctionalComponent<Props> | React_AbstractComponent<Props, T> | string,
	-- ROBLOX deviation END
	compare: ((oldProps: Props, newProps: Props) -> boolean)?
): React_MemoComponent<Props, any>
	if _G.__DEV__ then
		local validType = isValidElementType(type_)

		-- We warn in this case but don't throw. We expect the element creation to
		-- succeed and there will likely be errors in render.
		if not validType then
			local info = ""
			if
				type_ == nil
				or (typeof(type_) == "table" and #Object.keys(type_) == 0)
			then
				info = info
					.. (
[[ You likely forgot to export your component from the file it's defined in, or you might have mixed up default and named imports.]]					

)
			end
			local typeString
			if type_ == nil then
				typeString = "nil"
			elseif Array.isArray(type_) then
				typeString = "array"
			elseif
				type_ ~= nil
				and typeof(type_) == "table"
				and (type_ :: React_MemoComponent<Props, T>)["$$typeof"]
					== REACT_ELEMENT_TYPE
			then
				typeString = string.format(
					"<%s />",
					getComponentName((type_ :: any).type) or "UNKNOWN"
				)
				info =
					" Did you accidentally export a JSX literal or Element instead of a component?"
			else
				typeString = typeof(type_)
				if type_ ~= nil then
					-- ROBLOX deviation: print the table/string in readable form to give a clue, if no other info was gathered
					info = "\n" .. inspect(type_)
				end
			end
			console.error(
				"memo: The first argument must be a component. Instead received: `%s`.%s",
				typeString,
				info
			)
		end
	end

	local elementType = {
		["$$typeof"] = REACT_MEMO_TYPE,
		type = type_,
		compare = compare or nil,
	}

	if _G.__DEV__ then
		local name
		-- ROBLOX deviation: use metatables to approximate Object.defineProperty logic
		setmetatable(elementType, {
			__index = function(self, key)
				if key == "displayName" then
					return name
				end
				return rawget(self, key)
			end,
			__newindex = function(self, key, value)
				if key == "displayName" then
					name = value
					-- ROBLOX deviation: render is a function and cannot have properties
					if
						typeof(type_) == "table"
						and (type_ :: React_AbstractComponent<Props, T>).displayName
							== nil
					then
						(type_ :: React_MemoComponent<Props, T>).displayName = name
					end
				else
					rawset(self, key, value)
				end
			end,
		})
	end

	return elementType :: React_MemoComponent<Props, any>
end

return exports

end,
["react/ReactMutableSource"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react/src/ReactMutableSource.js
-- [[
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
-- ]]

local ReactTypes = require(script.Parent.Parent:WaitForChild('shared'))
type MutableSourceGetVersionFn = ReactTypes.MutableSourceGetVersionFn
type MutableSource<T> = ReactTypes.MutableSource<T>

local function createMutableSource<Source>(
	source: Source,
	getVersion: MutableSourceGetVersionFn
): MutableSource<Source>
	local mutableSource: MutableSource<Source> = {
		_getVersion = getVersion,
		_source = source,
		_workInProgressVersionPrimary = nil,
		_workInProgressVersionSecondary = nil,
	}

	if _G.__DEV__ then
		mutableSource._currentPrimaryRenderer = nil
		mutableSource._currentSecondaryRenderer = nil
	end

	return mutableSource
end

return createMutableSource

end,
["react/ReactNoopUpdateQueue"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/0cf22a56a18790ef34c71bef14f64695c0498619/packages/react/src/ReactNoopUpdateQueue.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console

local didWarnStateUpdateForUnmountedComponent = {}

local function warnNoop(publicInstance: any, callerName: string)
	if _G.__DEV__ then
		-- local constructor = publicInstance.constructor
		-- local componentName = ((constructor and (constructor.displayName or constructor.name)) or 'ReactClass')
		-- deviation: For Lua Class components, the name comes from a property
		-- defined on the metatable
		local componentName = publicInstance.__componentName or "ReactClass"
		local warningKey = componentName .. "." .. callerName
		if didWarnStateUpdateForUnmountedComponent[warningKey] then
			return
		end
		-- ROBLOX deviation: message adjusted for accuracy with Lua class components
		console.error(
[[Can't call %s on a component that is not yet mounted. This is a no-op, but it might indicate a bug in your application. Instead, assign to `self.state` directly with the desired state in the %s component's `init` method.]]


,
			callerName,
			componentName
		)
		didWarnStateUpdateForUnmountedComponent[warningKey] = true
	end
end

--[[*
 * This is the abstract API for an update queue.
 ]]
local ReactNoopUpdateQueue = {
	--[[*
   * Checks whether or not this composite component is mounted.
   * @param {ReactClass} publicInstance The instance we want to test.
   * @return {boolean} True if mounted, false otherwise.
   * @protected
   * @final
   ]]
	isMounted = function(publicInstance)
		return false
	end,
	--[[*
   * Forces an update. This should only be invoked when it is known with
   * certainty that we are **not** in a DOM transaction.
   *
   * You may want to call this when you know that some deeper aspect of the
   * component's state has changed but `setState` was not called.
   *
   * This will not invoke `shouldComponentUpdate`, but it will invoke
   * `componentWillUpdate` and `componentDidUpdate`.
   *
   * @param {ReactClass} publicInstance The instance that should rerender.
   * @param {?function} callback Called after component is updated.
   * @param {?string} callerName name of the calling function in the public API.
   * @internal
   ]]
	enqueueForceUpdate = function(publicInstance, callback, callerName)
		warnNoop(publicInstance, "forceUpdate")
	end,
	--[[*
   * Replaces all of the state. Always use this or `setState` to mutate state.
   * You should treat `this.state` as immutable.
   *
   * There is no guarantee that `this.state` will be immediately updated, so
   * accessing `this.state` after calling this method may return the old value.
   *
   * @param {ReactClass} publicInstance The instance that should rerender.
   * @param {object} completeState Next state.
   * @param {?function} callback Called after component is updated.
   * @param {?string} callerName name of the calling function in the public API.
   * @internal
   ]]
	enqueueReplaceState = function(publicInstance, completeState, callback, callerName)
		warnNoop(publicInstance, "replaceState")
	end,
	--[[*
   * Sets a subset of the state. This only exists because _pendingState is
   * internal. This provides a merging strategy that is not available to deep
   * properties which is confusing. TODO: Expose pendingState or don't use it
   * during the merge.
   *
   * @param {ReactClass} publicInstance The instance that should rerender.
   * @param {object} partialState Next partial state to be merged with state.
   * @param {?function} callback Called after component is updated.
   * @param {?string} Name of the calling function in the public API.
   * @internal
   ]]
	enqueueSetState = function(publicInstance, partialState, callback, callerName)
		warnNoop(publicInstance, "setState")
	end,
}

return ReactNoopUpdateQueue

end,
}

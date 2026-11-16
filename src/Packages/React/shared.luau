-- jsdotlua/shared@17.2.1; see THIRD_PARTY_NOTICES.md
return {
["shared/checkPropTypes"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/55cb0b7eeb0e539d89858b8ed69beabf7fe2fb46/packages/shared/checkPropTypes.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Error = LuauPolyfill.Error
type Object = LuauPolyfill.Object
type Function = (...any) -> ...any

-- ROBLOX: use patched console from shared
local console = require(script.Parent:WaitForChild('console'))

local loggedTypeFailures = {}

local ReactComponentStackFrame = require(script.Parent:WaitForChild('ReactComponentStackFrame'))
local describeUnknownElementTypeFrameInDEV =
	ReactComponentStackFrame.describeUnknownElementTypeFrameInDEV

local ReactSharedInternals = require(script.Parent:WaitForChild('ReactSharedInternals'))

local describeError = require(script.Parent:WaitForChild('ErrorHandling.roblox')).describeError

local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame

-- ROBLOX FIXME Luau: doesn't see `if element` as nilable table, so we get TypeError: Type 'any?' could not be converted into '{| _owner: {| type: nil |}, _source: Source?, type: any |}'
local function setCurrentlyValidatingElement(element: any?)
	if _G.__DEV__ then
		if element then
			local owner = element._owner
			local stack = describeUnknownElementTypeFrameInDEV(
				element.type,
				element._source,
				if owner ~= nil then owner.type else nil
			);
			-- ROBLOX FIXME Luau: Cannot call non-function ((string?) -> ()) | ((string?) -> ())
			(ReactDebugCurrentFrame.setExtraStackFrame :: any)(stack)
		else
			(ReactDebugCurrentFrame.setExtraStackFrame :: any)(nil)
		end
	end
end

local function checkPropTypes<P>(
	-- ROBLOX deviation START: also checks validateProps if present
	propTypes: Object?,
	validateProps: ((P) -> (boolean, string?))?,
	props: P,
	-- ROBLOX deviation END
	location: string,
	componentName: string?,
	element: any?
): ()
	if _G.__DEV__ or _G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		-- deviation: hasOwnProperty shouldn't be relevant to lua objects
		-- $FlowFixMe This is okay but Flow doesn't know it.
		-- local has = Function.call.bind(Object.prototype.hasOwnProperty)

		-- ROBLOX deviation: warns if both propType and validateProps defined.
		if propTypes and validateProps then
			console.warn(
				"You've defined both propTypes and validateProps on "
					.. (componentName or "a component")
			)
		end

		-- ROBLOX deviation: also checks validateProps if present
		if validateProps then
			if typeof(validateProps) ~= "function" then
				console.error(
					("validateProps must be a function, but it is a %s.\nCheck the definition of the component %q."):format(
						typeof(validateProps),
						componentName or ""
					)
				)
			else
				local success, failureReason = validateProps(props)

				if not success then
					failureReason = failureReason
						or "<Validator function did not supply a message>"
					local message = string.format(
						"validateProps failed on a %s type in %s: %s",
						location,
						componentName or "<UNKNOWN Component>",
						tostring(failureReason)
					)
					-- ROBLOX deviation: In legacy Roact, prop validation
					-- failures throw. We replicate that behavior, even though
					-- it differs from propTypes (which only warns)
					-- ROBLOX FIXME: align with upstream behavior during React 18 Lua transition
					error(message)
				end
			end
		end

		if propTypes then
			-- ROBLOX deviation: since we can't constrain the generic, we assert so Luau knows propTypes is a table
			assert(typeof(propTypes) == "table", "propTypes needs to be a table")
			for typeSpecName, _ in propTypes do
				-- deviation: since our loop won't hit metatable members, we don't
				-- need to worry about encountering inherited properties here
				-- if has(propTypes, typeSpecName) then

				-- Prop type validation may throw. In case they do, we don't want to
				-- fail the render phase where it didn't fail before. So we log it.
				-- After these have been cleaned up, we'll local them throw.
				local _, result = xpcall(function()
					-- This is intentionally an invariant that gets caught. It's the same
					-- behavior as without this statement except with a better message.
					if typeof(propTypes[typeSpecName]) ~= "function" then
						local err = Error.new(
							(componentName or "React class")
								.. ": "
								.. location
								.. " type `"
								.. typeSpecName
								.. "` is invalid; "
								.. "it must be a function, usually from the `prop-types` package, but received `"
								.. typeof(propTypes[typeSpecName])
								.. [[`.This often happens because of typos such as `PropTypes.function` instead of `PropTypes.func`.]]						

)
						err.name = "Invariant Violation"
						error(err)
					end

					return (propTypes[typeSpecName] :: Function)(
						props,
						typeSpecName,
						componentName,
						location,
						nil,
						"SECRET_DO_NOT_PASS_THIS_OR_YOU_WILL_BE_FIRED"
					)
				end, describeError)

				-- ROBLOX deviation: FIXME: Can we expose something from JSPolyfill that
				-- will let us verify that this is specifically the Error object
				-- defined there? if we check for result.message ~= nil, ReactNewContext.spec:1368 fails
				local isErrorObject = typeof(result) == "table"
				if result ~= nil and not isErrorObject then
					setCurrentlyValidatingElement(element)
					console.error(string.format(
[[%s: type specification of %s `%s` is invalid; the type checker function must return `nil` or an `Error` but returned a %s. You may have forgotten to pass an argument to the type checker creator (arrayOf, instanceOf, objectOf, oneOf, oneOfType, and shape all require an argument).]]





,
						componentName or "React class",
						location,
						typeSpecName,
						typeof(result)
					))
					setCurrentlyValidatingElement(nil)
				end

				-- ROBLOX FIXME: Luau analyze doesn't understand isErrorObject's effect as a predicate meaning result ~= nil
				if
					isErrorObject
					and loggedTypeFailures[(result :: any).message] == nil
				then
					-- Only monitor this failure once because there tends to be a lot of the
					-- same error.
					loggedTypeFailures[tostring((result :: any).message)] = true
					setCurrentlyValidatingElement(element)
					console.warn(
						string.format(
							"Failed %s type: %s",
							location,
							tostring((result :: any).message)
						)
					)
					setCurrentlyValidatingElement(nil)
				end
			end
		end
	end
end

return checkPropTypes

end,
["shared/console"]=function()
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

-- deviation: this lets us have the same functionality as in React, without
-- having something like Babel to inject a different implementation of
-- console.warn and console.error into the code
-- Instead of using `LuauPolyfill.console`, React internals should use this
-- wrapper to be able to use consoleWithStackDev in dev mode
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local console = LuauPolyfill.console
local consoleWithStackDev = require(script.Parent:WaitForChild('consoleWithStackDev'))

if _G.__DEV__ then
	local newConsole = setmetatable({
		warn = consoleWithStackDev.warn,
		error = consoleWithStackDev.error,
	}, {
		__index = console,
	})
	return newConsole
end

return console

end,
["shared/ConsolePatchingDev.roblox"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/55cb0b7eeb0e539d89858b8ed69beabf7fe2fb46/packages/shared/checkPropTypes.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- deviation: Lua objects don't have any special properties the way that JS
-- Objects do; this has been modified from the JS, which uses
-- `Object.defineProperties` to ensure that properties are modifiable. In Lua,
-- these operations are as simple as assigning to functions.
-- ROBLOX: use patched console from shared
local console = require(script.Parent:WaitForChild('console'))
-- Helpers to patch console.logs to avoid logging during side-effect free
-- replaying on render function. This currently only patches the object
-- lazily which won't cover if the log function was extracted eagerly.
-- We could also eagerly patch the method.

local disabledDepth = 0
local prevLog
local prevInfo
local prevWarn
local prevError
local prevGroup
local prevGroupCollapsed
local prevGroupEnd

local disabledLog = function() end

local exports = {}

-- ROBLOX deviation: console.log's name property is checked in SchedulerHostConfig.
-- But since Lua functions don't carry properties, we export this and import it there
-- for a reference equality.
exports.disabledLog = disabledLog

exports.disableLogs = function()
	if _G.__DEV__ then
		if disabledDepth == 0 then
			prevLog = console.log
			prevInfo = console.info
			prevWarn = console.warn
			prevError = console.error
			prevGroup = console.group
			prevGroupCollapsed = console.groupCollapsed
			prevGroupEnd = console.groupEnd

			console.info = disabledLog
			console.log = disabledLog
			console.warn = disabledLog
			console.error = disabledLog
			console.group = disabledLog
			console.groupCollapsed = disabledLog
			console.groupEnd = disabledLog
		end

		disabledDepth = disabledDepth + 1
	end
end

exports.reenableLogs = function()
	if _G.__DEV__ then
		disabledDepth = disabledDepth - 1

		if disabledDepth == 0 then
			console.log = prevLog
			console.info = prevInfo
			console.warn = prevWarn
			console.error = prevError
			console.group = prevGroup
			console.groupCollapsed = prevGroupCollapsed
			console.groupEnd = prevGroupEnd
		end

		if disabledDepth < 0 then
			console.error(
[[disabledDepth fell below zero. This is a bug in React. Please file an issue.]]			

)
		end
	end
end

return exports

end,
["shared/consoleWithStackDev"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/cb141681750c8221ac799074df09df2bb448c7a4/packages/shared/consoleWithStackDev.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local console = LuauPolyfill.console
local Array = LuauPolyfill.Array

local ReactSharedInternals = require(script.Parent:WaitForChild('ReactSharedInternals'))-- In DEV, calls to console.warn and console.error get replaced
-- by calls to these methods by a Babel plugin.
--
-- In PROD (or in packages without access to React internals),
-- they are left as they are instead.

-- deviation: declare this ahead of time so that `warn` and `error` are able to
-- reference it

local printWarning

local exports = {}
exports.warn = function(format, ...)
	if _G.__DEV__ then
		printWarning("warn", format, { ... })
	end
end
exports.error = function(format, ...)
	if _G.__DEV__ then
		printWarning("error", format, { ... })
	end
end

function printWarning(level, format, args)
	-- When changing this logic, you might want to also
	-- update consoleWithStackDev.www.js as well.
	if _G.__DEV__ then
		local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame
		local stack = ReactDebugCurrentFrame.getStackAddendum()

		if stack ~= "" then
			format ..= "%s"
			-- deviation: no array `concat` function in lua
			args = Array.slice(args, 1)
			table.insert(args, stack)
		end

		local argsWithFormat = Array.map(args, tostring)
		-- Careful: RN currently depends on this prefix
		table.insert(argsWithFormat, 1, "Warning: " .. format)
		-- We intentionally don't use spread (or .apply) directly because it
		-- breaks IE9: https://github.com/facebook/react/issues/13610
		-- eslint-disable-next-line react-internal/no-production-logging
		console[level](unpack(argsWithFormat))
	end
end

return exports

end,
["shared/enqueueTask.roblox"]=function()
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
 ]]
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local setTimeout = LuauPolyfill.setTimeout

return function(task)
	-- deviation: Replace with setImmediate once we create an equivalent polyfill
	return setTimeout(task, 0)
end

end,
["shared/ErrorHandling.roblox"]=function()
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
type Error = LuauPolyfill.Error
type Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
local Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect

local DIVIDER = "\n------ Error caught by React ------\n"

--[[
	React does a lot of catching, retrying, and rethrowing errors that would
	typically result in loss of meaningful stack information.

	We use xpcall combined with this error function to capture and rethrow in a
	way that retains some stack information.
]]
local function describeError(e: string | Error): Error
	if typeof(e) == "string" then
		local _, endOfStackFrame = string.find(e, ":[%d]+: ")
		local message = if endOfStackFrame then string.sub(e, endOfStackFrame + 1) else e

		local err = LuauPolyfill.Error.new(message)
		err.stack = debug.traceback(nil, 2)
		return err
	end
	return e :: Error
end

--[[
	Even though Luau can catch and rethrow arbitrary objects, only string errors
	are supported by the ScriptContext.ErrorDetailed signal (the mechanism used
	to catch unhandled errors at the top level).

	This function turns an arbitrary error object into a detailed string message
	to avoid any loss of information.
]]
local function errorToString(error_: Error | Object | string | Array<any>): string
	local errorString
	if typeof(error_) == "table" then
		if (error_ :: Error).message and (error_ :: Error).stack then
			-- Adding these clear dividers helps us split this error back up
			-- into pieces later. We include one at the beginning so that the
			-- final stack frame added by rethrowing can be carved off
			errorString = DIVIDER
				.. (error_ :: Error).message
				.. DIVIDER
				.. tostring((error_ :: Error).stack)
		else
			errorString = inspect(error_)
		end
	else
		errorString = inspect(error_)
	end

	return errorString
end

--[[
	If an error string was generated from an Error object via the errorToString
	function above, it can be easily split back out into an informative error
	object.
]]
local function parseReactError(error_: string): (Error, string)
	local split = string.split(error_, DIVIDER)

	if #split == 3 then
		local rethrow, message, stack = table.unpack(split)

		local newError = Error.new(message)
		newError.stack = stack

		return newError, rethrow
	else
		-- This error was not in the expected format, so we use the whole string
		-- as the 'message' value and nil out the stack (it would be misleading
		-- if we included the one generated here)
		local newError = Error.new(error_)
		newError.stack = nil

		return newError, ""
	end
end

return {
	describeError = describeError,
	errorToString = errorToString,
	parseReactError = parseReactError,
	-- Used only by tests
	__ERROR_DIVIDER = DIVIDER,
}

end,
["shared/ExecutionEnvironment"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/55cb0b7eeb0e539d89858b8ed69beabf7fe2fb46/packages/shared/ExecutionEnvironment.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local exports = {}

exports.canUseDOM = function()
	-- ROBLOX deviation START
	return false
	-- ROBLOX deviation END
end

return exports

end,
["shared/flowtypes.roblox"]=function()
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
-- built-in flowtypes reverse engineered based on usage and enabling strict type checking on test suites
--!strict
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Error = LuauPolyfill.Error
type Array<T> = LuauPolyfill.Array<T>
type Object = { [string]: any }
-- duplicated from ReactElementType to avoid circular dep
type Source = {
	fileName: string,
	lineNumber: number
}

-- ROBLOX deviation: alias for internal React$ flow types
export type React_Node =
	nil
	| boolean
	| number
	| string
	| React_Element<any>
	-- ROBLOX TODO: only include this once it's more specific than `any`
	-- | React_Portal
	| Array<React_Node?>
	-- ROBLOX TODO Luau: this more closely matches the upstream Iterable<>, hypothetically the UNIQUE_TAG field makes it so we don't unify with other tables and squad field resolution
	| { [string]: React_Node?, UNIQUE_TAG: any? }

export type React_Element<ElementType> = {
	type: ElementType,
	props: React_ElementProps<ElementType>?,
	key: React_Key | nil,
	ref: any
}

export type React_PureComponent<Props, State = nil> = React_Component<Props, State>

export type React_AbstractComponent<Config, T> =
	React_ForwardRefComponent<Config, T>
	| React_MemoComponent<Config, T>

type React_BaseAbstractComponent<Config, T> = {
	["$$typeof"]: number,
	displayName: string?,
	defaultProps: Config?,
	-- not in React flowtype, but is in definitelytyped and is used in ReactElement
	name: string?
}

-- ROBLOX note: this flowtype built-in is derived from the object shape returned by forwardRef
export type React_ForwardRefComponent<Config, Instance> = React_BaseAbstractComponent<
	Config,
	Instance
> & {
	render: (props: Config, ref: React_Ref<Instance>) -> React_Node,
	-- allows methods to be hung on a component, used in forwardRef.spec regression test we added
	[string]: any
}

export type React_MemoComponent<Config, T> = React_BaseAbstractComponent<Config, T> & {
	type: React_StatelessFunctionalComponent<Config>,
	compare: ((oldProps: Config, newProps: Config) -> boolean)?
}

-- ROBLOX TODO: ElementConfig: something like export type React_ElementConfig<React_Component<P>> = P
export type React_ElementConfig<C> = Object

-- ROBLOX deviation: this is a class export upstream, so optional overrides are nil-able, and it's extensible by default
export type React_Component<Props, State = nil> = {
	-- fields
	props: Props,
	state: State,

	-- action methods

	setState: (
		self: React_Component<Props, State>,
		partialState: State | ((State, Props) -> State?),
		callback: (() -> ())?
	) -> (),

	forceUpdate: (self: React_Component<Props, State>, callback: (() -> ())?) -> (),

	-- lifecycle methods

	init: ((
		self: React_Component<Props, State>,
		props: Props,
		context: any?
	) -> ())?,
	render: (self: React_Component<Props, State>) -> React_Node,
	componentWillMount: ((self: React_Component<Props, State>) -> ())?,
	UNSAFE_componentWillMount: ((self: React_Component<Props, State>) -> ())?,
	componentDidMount: ((self: React_Component<Props, State>) -> ())?,
	componentWillReceiveProps: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextContext: any
	) -> ())?,
	UNSAFE_componentWillReceiveProps: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextContext: any
	) -> ())?,
	shouldComponentUpdate: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextState: State,
		nextContext: any
	) -> boolean)?,
	componentWillUpdate: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextState: State,
		nextContext: any
	) -> ())?,
	UNSAFE_componentWillUpdate: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextState: State,
		nextContext: any
	) -> ())?,
	componentDidUpdate: ((
		self: React_Component<Props, State>,
		prevProps: Props,
		prevState: State,
		prevContext: any
	) -> ())?,
	componentWillUnmount: ((self: React_Component<Props, State>) -> ())?,
	componentDidCatch: ((
		self: React_Component<Props, State>,
		error: Error,
		info: {
			componentStack: string		
}
	) -> ())?,
	getDerivedStateFromProps: ((props: Props, state: State) -> State?)?,
	getDerivedStateFromError: ((error: Error) -> State?)?,
	getSnapshotBeforeUpdate: ((props: Props, state: State) -> any)?,

	-- long tail of other stuff not modeled very well

	-- ROBLOX deviation START: these fields are mostly used internally including in ReactBaseClasses
	__refs: Object,
	__updater: any,
	-- ROBLOX deviation END

	-- ROBLOX deviation: this field is only used in relation to string refs, which we do not support
	-- refs: any,
	context: any,
	getChildContext: (self: React_Component<Props, State>) -> any,
	-- statics
	__componentName: string,
	displayName: string?,
	-- ROBLOX deviation: not in React flowtype, but is in definitelytyped and is used in ReactElement
	name: string?,
	childContextTypes: any?,
	contextTypes: any?,
	propTypes: any?,

	-- ROBLOX FIXME: this is a legacy Roact field and should be removed in React 18 Lua
	validateProps: ((Props) -> (boolean, string?))?,

	-- We don't add a type for `defaultProps` so that its type may be entirely
	-- inferred when we diff the type for `defaultProps` with `Props`. Otherwise
	-- the user would need to define a type (which would be redundant) to override
	-- the type we provide here in the base class.
	-- ROBLOX deviation: Luau doesn't do the inference above
	defaultProps: Props?,
	-- ROBLOX deviation: class export allows assigning additional custom instance fields
	[string]: any
}

-- ROBLOX deviation: Lua doesn't allow fields on functions, and we haven't implemented callable tables as "function" components
export type React_StatelessFunctionalComponent<Props> = (
	props: Props,
	context: any
) -> React_Node
export type React_ComponentType<Config> = React_Component<Config, any>

export type React_ElementType = string | React_Component<any, any>

-- This was reverse engineered from usage, no specific flowtype or TS artifact
export type React_ElementProps<ElementType> = {
	ref: React_Ref<ElementType>?,
	key: React_Key?,
	__source: Source?,
	children: any?
}

-- ROBLOX deviation: this is a built-in flow type, and very complex. we fudge this with `any`
-- type ElementRef<
--   C extends keyof JSX.IntrinsicElements
--   | React.ForwardRefExoticComponent<any>
--   | (new (props: any) -> React.Component<any, {}, any>)
--   | ((props: any, context?: any) -> ReactElement | null)
--   > = "ref" extends keyof ComponentPropsWithRef<C>
--     ? NonNullable<ComponentPropsWithRef<C>["ref"]> extends Ref<infer Instance>
--       ? Instance
--       : never
--     : never

-- ROBLOX TODO: Not sure how to model this, upstream: https://github.com/facebook/flow/blob/main/tests/react_instance/class.js#L10
-- ROBLOX FIXME Luau: if I make this Object, we run into normalization issues: '{| current: React_ElementRef<any>? |}' could not be converted into '(((?) -> any) | {| current: ? |})?
export type React_ElementRef<C> = C

export type React_Ref<ElementType> =
	{ current: React_ElementRef<ElementType> | nil }
	| ((React_ElementRef<ElementType> | nil) -> ())
-- ROBLOX deviation: we don't support string refs, and this is unsound flowtype when used with ref param of useImperativeHandle
-- | string

export type React_Context<T> = {
	Provider: React_ComponentType<{ value: T, children: React_Node? }>,
	Consumer: React_ComponentType<{ children: (value: T) -> React_Node? }>
}

-- ROBLOX TODO: declared as an opaque type in flowtype: https://github.com/facebook/flow/blob/422821fd42c09c3ef609c60516fe754b601ea205/lib/react.js#L182
export type React_Portal = any
export type React_Key = string | number

return {}

end,
["shared/formatProdErrorMessage"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/75955bf1d7ff6c2c1f4052f4a84dd2ce6944c62e/packages/shared/formatProdErrorMessage.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 ]]

-- Do not require this module directly! Use normal `invariant` calls with
-- template literal strings. The messages will be replaced with error codes
-- during build.

local HttpService = game:GetService("HttpService")

local function formatProdErrorMessage(code, ...)
	local url = "https://reactjs.org/docs/error-decoder.html?invariant=" .. tostring(code)
	local argsLength = select("#", ...)
	for i = 1, argsLength, 1 do
		-- deviation: UrlEncode should be equivalent to encodeURIComponent
		url = url .. "&args[]=" .. HttpService:UrlEncode(select(i, ...))
	end
	return string.format(
[[Minified React error #%d; visit %s for the full message or use the non-minified dev environment for full errors and additional helpful warnings.]]

,
		code,
		url
	)
end

return formatProdErrorMessage

end,
["shared/getComponentName"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/a774502e0ff2a82e3c0a3102534dbc3f1406e5ea/packages/shared/getComponentName.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]
type Function = (...any) -> ...any
local console = require(script.Parent:WaitForChild('console'))
-- ROBLOX deviation: inline this typedef to avoid upstream's circular dependency

type LazyComponent<T, P> = {
	["$$typeof"]: number,
	_payload: P,
	_init: (payload: P) -> T
}

local ReactSymbols = require(script.Parent:WaitForChild('ReactSymbols'))
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_PORTAL_TYPE = ReactSymbols.REACT_PORTAL_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_PROFILER_TYPE = ReactSymbols.REACT_PROFILER_TYPE
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE
local REACT_STRICT_MODE_TYPE = ReactSymbols.REACT_STRICT_MODE_TYPE
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local ReactTypes = require(script.Parent:WaitForChild('ReactTypes'))
type ReactContext<T> = ReactTypes.ReactContext<T>
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>

local describeError = require(script.Parent:WaitForChild('ErrorHandling.roblox')).describeError

local function getWrappedName(outerType: any, innerType: any, wrapperName: string): string
	-- deviation: Account for indexing into function
	local functionName = "<function>"
	if typeof(innerType) == "table" then
		functionName = innerType.displayName or innerType.name or ""
	end
	return outerType.displayName
		or (
			functionName ~= "" and string.format("%s(%s)", wrapperName, functionName)
			or wrapperName
		)
end

local function getContextName(type: ReactContext<any>): string
	return type.displayName or "Context"
end

local function getComponentName(type: any): string | nil
	if type == nil then
		-- Host root, text node or just invalid type.
		return nil
	end
	local typeofType = typeof(type)

	if _G.__DEV__ then
		if typeofType == "table" and typeof(type.tag) == "number" then
			console.warn(
[[Received an unexpected object in getComponentName(). This is likely a bug in React. Please file an issue.]]			

)
		end
	end

	if typeofType == "function" then
		-- ROBLOX deviation: we can't deref functions in Lua, so get the name of the function and move logic to table section
		-- ROBLOX FIXME Luau: this line gets a bunch of bizarre errors in strict mode
		local name = debug.info((type :: any) :: Function, "n")
		-- ROBLOX deviaton:when name = (null) we want it to be treated as nil, not as an empty (truthy) string
		if name and string.len(name) > 0 then
			return name
		else
			return nil
		end
	end

	if typeofType == "string" then
		return (type :: any) :: string
	end

	if type == REACT_FRAGMENT_TYPE then
		return "Fragment"
	elseif type == REACT_PORTAL_TYPE then
		return "Portal"
	elseif type == REACT_PROFILER_TYPE then
		return "Profiler"
	elseif type == REACT_STRICT_MODE_TYPE then
		return "StrictMode"
	elseif type == REACT_SUSPENSE_TYPE then
		return "Suspense"
	elseif type == REACT_SUSPENSE_LIST_TYPE then
		return "SuspenseList"
	end

	if typeofType == "table" then
		local typeProp = type["$$typeof"]
		if typeProp == REACT_CONTEXT_TYPE then
			local context: ReactContext<any> = type :: any
			return getContextName(context) .. ".Consumer"
		elseif typeProp == REACT_PROVIDER_TYPE then
			local provider: ReactProviderType<any> = type :: any
			return getContextName(provider._context) .. ".Provider"
		elseif typeProp == REACT_FORWARD_REF_TYPE then
			return getWrappedName(type, type.render, "ForwardRef")
		elseif typeProp == REACT_MEMO_TYPE then
			return getComponentName(type.type)
		elseif typeProp == REACT_BLOCK_TYPE then
			return getComponentName(type._render)
		elseif typeProp == REACT_LAZY_TYPE then
			local lazyComponent: LazyComponent<any, any> = type :: any
			local payload = lazyComponent._payload
			local init = lazyComponent._init

			-- ROBLOX performance: getComponentName won't throw, but init() might, extract it out to eliminate an anon function
			local ok, result = xpcall(init, describeError, payload)
			if ok then
				return getComponentName(result)
			else
				return nil
			end
		else
			-- ROBLOX deviation: Normally, the `typeofType == "function"` check would
			-- cover this case, but in Lua, class components are tables. We need
			-- to check for that here and use the name the component was
			-- assigned.
			if type.displayName then
				return type.displayName
			end
			if type.name then
				return type.name
			end
			-- ROBLOX note: only use tostring() if its overridden to avoid "table: 0xabcd9012"
			local mt = getmetatable(type)
			if mt and rawget(mt, "__tostring") then
				return tostring(type)
			end
		end
	end

	return nil
end

return getComponentName

end,
["shared"]=function()
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

-- ROBLOX deviation: Promote `shared` to an actual unpublished package with a
-- real interface instead of just a bag of loose source code
local LuauPolyfill = require(script.Parent:WaitForChild('luau-polyfill'))
type Object = LuauPolyfill.Object

local ReactTypes = require(script:WaitForChild('ReactTypes'))
local flowtypes = require(script:WaitForChild('flowtypes.roblox'))
local ReactElementType = require(script:WaitForChild('ReactElementType'))
local ReactFiberHostConfig = require(script:WaitForChild('ReactFiberHostConfig'))
local ReactSharedInternals = require(script:WaitForChild('ReactSharedInternals'))
local ErrorHandling = require(script:WaitForChild('ErrorHandling.roblox'))
-- Re-export all top-level public types

export type ReactEmpty = ReactTypes.ReactEmpty
export type ReactFragment = ReactTypes.ReactFragment
export type ReactNodeList = ReactTypes.ReactNodeList
export type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
export type ReactConsumer<T> = ReactTypes.ReactConsumer<T>
export type ReactProvider<T> = ReactTypes.ReactProvider<T>
export type ReactContext<T> = ReactTypes.ReactContext<T>
export type ReactPortal = ReactTypes.ReactPortal
export type RefObject = ReactTypes.RefObject
export type EventPriority = ReactTypes.EventPriority
export type ReactFundamentalComponentInstance<C, H> =
	ReactTypes.ReactFundamentalComponentInstance<C, H>
export type ReactFundamentalImpl<C, H> = ReactTypes.ReactFundamentalImpl<C, H>
export type ReactFundamentalComponent<C, H> = ReactTypes.ReactFundamentalComponent<C, H>
export type ReactScope = ReactTypes.ReactScope
export type ReactScopeQuery = ReactTypes.ReactScopeQuery
export type ReactScopeInstance = ReactTypes.ReactScopeInstance
-- ROBLOX deviation START: Re-export bindings types
export type ReactBinding<T> = ReactTypes.ReactBinding<T>
export type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
-- ROBLOX deviation END
export type MutableSourceVersion = ReactTypes.MutableSourceVersion
export type MutableSourceGetSnapshotFn<Source, Snapshot> =
	ReactTypes.MutableSourceGetSnapshotFn<Source, Snapshot>
export type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>
export type MutableSourceGetVersionFn = ReactTypes.MutableSourceGetVersionFn
export type MutableSource<Source> = ReactTypes.MutableSource<Source>
export type Wakeable = ReactTypes.Wakeable
export type Thenable<R> = ReactTypes.Thenable<R>
export type Source = ReactElementType.Source
export type ReactElement<P = Object, T = any> = ReactElementType.ReactElement<P, T>
export type OpaqueIDType = ReactFiberHostConfig.OpaqueIDType
export type Dispatcher = ReactSharedInternals.Dispatcher

-- re-export flowtypes from here. I wonder if this should be a separate 'package'?
export type React_Ref<ElementType> = flowtypes.React_Ref<ElementType>
export type React_Context<T> = flowtypes.React_Context<T>
export type React_AbstractComponent<Config, Instance> = flowtypes.React_AbstractComponent<
	Config,
	Instance
>
export type React_ForwardRefComponent<Config, Instance> =
	flowtypes.React_ForwardRefComponent<Config, Instance>
export type React_MemoComponent<Config, T> = flowtypes.React_MemoComponent<Config, T>
export type React_ComponentType<Config> = flowtypes.React_ComponentType<Config>
export type React_PureComponent<Props, State = nil> = flowtypes.React_PureComponent<
	Props,
	State
>
export type React_Component<Props, State> = flowtypes.React_Component<Props, State>
export type React_ElementProps<ElementType> = flowtypes.React_ElementProps<ElementType>
export type React_StatelessFunctionalComponent<Props> =
	flowtypes.React_StatelessFunctionalComponent<Props>
export type React_Node = flowtypes.React_Node
export type React_Element<ElementType> = flowtypes.React_Element<ElementType>
export type React_ElementType = flowtypes.React_ElementType
export type React_ElementConfig<C> = flowtypes.React_ElementConfig<C>
export type React_ElementRef<C> = flowtypes.React_ElementRef<C>
export type React_Portal = flowtypes.React_Portal
export type React_Key = flowtypes.React_Key

return {
	checkPropTypes = require(script:WaitForChild('checkPropTypes')),
	console = require(script:WaitForChild('console')),
	ConsolePatchingDev = require(script:WaitForChild('ConsolePatchingDev.roblox')),
	consoleWithStackDev = require(script:WaitForChild('consoleWithStackDev')),
	enqueueTask = require(script:WaitForChild('enqueueTask.roblox')),
	ExecutionEnvironment = require(script:WaitForChild('ExecutionEnvironment')),
	formatProdErrorMessage = require(script:WaitForChild('formatProdErrorMessage')),
	getComponentName = require(script:WaitForChild('getComponentName')),
	invariant = require(script:WaitForChild('invariant')),
	invokeGuardedCallbackImpl = require(script:WaitForChild('invokeGuardedCallbackImpl')),
	isValidElementType = require(script:WaitForChild('isValidElementType')),
	objectIs = require(script:WaitForChild('objectIs')),
	ReactComponentStackFrame = require(script:WaitForChild('ReactComponentStackFrame')),
	ReactElementType = require(script:WaitForChild('ReactElementType')),
	ReactErrorUtils = require(script:WaitForChild('ReactErrorUtils')),
	ReactFeatureFlags = require(script:WaitForChild('ReactFeatureFlags')),
	ReactInstanceMap = require(script:WaitForChild('ReactInstanceMap')),
	-- ROBLOX deviation: Instead of re-exporting from here, Shared actually owns
	-- these files itself
	ReactSharedInternals = ReactSharedInternals,
	-- ROBLOX deviation: Instead of extracting these out of the reconciler and
	-- then re-injecting the host config _into_ the reconciler, export these
	-- from shared for easier reuse
	ReactFiberHostConfig = ReactFiberHostConfig,

	ReactSymbols = require(script:WaitForChild('ReactSymbols')),
	ReactVersion = require(script:WaitForChild('ReactVersion')),
	shallowEqual = require(script:WaitForChild('shallowEqual')),
	UninitializedState = require(script:WaitForChild('UninitializedState.roblox')),
	ReactTypes = ReactTypes,

	-- ROBLOX DEVIATION: export error-stack-preserving utilities for use in
	-- scheduler and reconciler, and parsing function for use in public API
	describeError = ErrorHandling.describeError,
	errorToString = ErrorHandling.errorToString,
	parseReactError = ErrorHandling.parseReactError,

	-- ROBLOX DEVIATION: export Symbol and Type from Shared
	Symbol = require(script:WaitForChild('Symbol.roblox')),
	Type = require(script:WaitForChild('Type.roblox')),

	-- ROBLOX DEVIATION: export propmarkers from Shared
	Change = require(script:WaitForChild('PropMarkers'):WaitForChild('Change')),
	Event = require(script:WaitForChild('PropMarkers'):WaitForChild('Event')),
	Tag = require(script:WaitForChild('PropMarkers'):WaitForChild('Tag')),
}

end,
["shared/invariant"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/42c3c967d1e4ca4731b47866f2090bc34caa086c/packages/shared/invariant.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
]]

--[[*
 * Use invariant() to assert state which your program assumes to be true.
 *
 * Provide sprintf-style format (only %s is supported) and arguments
 * to provide information about what broke and what you were
 * expecting.
 *
 * The invariant message will be stripped in production, but the invariant
 * will remain to ensure logic does not differ in production.
]]
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Error = LuauPolyfill.Error

local function invariant(condition, format, ...)
	-- ROBLOX TODO: we should encapsulate all formatting compatibility here,
	-- rather than spreading workarounds throughout the codebase, eg this
	-- should print an array without the need for a table.concat on the consumer side
	if not condition then
		error(Error(string.format(format, ...)))
	end
end

return invariant

end,
["shared/invokeGuardedCallbackImpl"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/shared/invokeGuardedCallbackImpl.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
-- local invariant = require("./invariant")
local describeError = require(script.Parent:WaitForChild('ErrorHandling.roblox')).describeError

-- deviation: with flow types stripped, it's easier to use varargs directly
local function invokeGuardedCallbackProd(reporter, name, func, context, ...)
	-- local funcArgs = Array.prototype.slice.call(arguments, 3)

	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not _G.__YOLO__ then
		-- deviation: Since functions in lua _explicitly_ accept 'self' as a
		-- first argument when they use it, it becomes incorrect for us to call
		-- a function with a nil "context", where context in this case is
		-- analogous to the implicit `self` that we get with a `:` call
		if context == nil then
			ok, result = xpcall(func, describeError, ...)
		else
			ok, result = xpcall(func, describeError, context, ...)
		end
	else
		ok = true
		if context == nil then
			func(...)
		else
			func(context, ...)
		end
	end

	if not ok then
		-- deviation: functions have no notion of "this"/"self", so we expect
		-- the first argument to be the reporter itself, in conjunction with
		-- deviations in `ReactErrorUtils`
		reporter.onError(result)
	end
end

local invokeGuardedCallbackImpl = invokeGuardedCallbackProd

if _G.__DEV__ then
	-- In DEV mode, we swap out invokeGuardedCallback for a special version
	-- that plays more nicely with the browser's DevTools. The idea is to preserve
	-- "Pause on exceptions" behavior. Because React wraps all user-provided
	-- functions in invokeGuardedCallback, and the production version of
	-- invokeGuardedCallback uses a try-catch, all user exceptions are treated
	-- like caught exceptions, and the DevTools won't pause unless the developer
	-- takes the extra step of enabling pause on caught exceptions. This is
	-- unintuitive, though, because even though React has caught the error, from
	-- the developer's perspective, the error is uncaught.
	--
	-- To preserve the expected "Pause on exceptions" behavior, we don't use a
	-- try-catch in DEV. Instead, we synchronously dispatch a fake event to a fake
	-- DOM node, and call the user-provided callback from inside an event handler
	-- for that fake event. If the callback throws, the error is "captured" using
	-- a global event handler. But because the error happens in a different
	-- event loop context, it does not interrupt the normal program flow.
	-- Effectively, this gives us try-catch behavior without actually using
	-- try-catch. Neat!
	-- Check that the browser supports the APIs we need to implement our special
	-- DEV version of invokeGuardedCallback

	-- deviation: `window` is not defined in our environment
	-- deviation: FIXME: should we define our own impl for invokeGuardedCallbackDev?
	--[[
	if typeof window ~= 'undefined' and typeof window.dispatchEvent == 'function' and typeof document ~= 'undefined' and typeof document.createEvent == 'function' then
		local fakeNode = document.createElement('react')

		invokeGuardedCallbackImpl = function invokeGuardedCallbackDev(name, func, context, a, b, c, d, e, f) {
			-- If document doesn't exist we know for sure we will crash in this method
			-- when we call document.createEvent(). However this can cause confusing
			-- errors: https://github.com/facebookincubator/create-react-app/issues/3482
			-- So we preemptively throw with a better message instead.
			invariant(typeof document ~= 'undefined', 'The `document` global was defined when React was initialized, but is not ' + 'defined anymore. This can happen in a test environment if a component ' + 'schedules an update from an asynchronous callback, but the test has already ' + 'finished running. To solve this, you can either unmount the component at ' + 'the end of your test (and ensure that any asynchronous operations get ' + 'canceled in `componentWillUnmount`), or you can change the test itself ' + 'to be asynchronous.')
			local evt = document.createEvent('Event')
			local didCall = false; -- Keeps track of whether the user-provided callback threw an error. We
			-- set this to true at the beginning, then set it to false right after
			-- calling the function. If the function errors, `didError` will never be
			-- set to false. This strategy works even if the browser is flaky and
			-- fails to call our global error handler, because it doesn't rely on
			-- the error event at all.

			local didError = true; -- Keeps track of the value of window.event so that we can reset it
			-- during the callback to local user code access window.event in the
			-- browsers that support it.

			local windowEvent = window.event; -- Keeps track of the descriptor of window.event to restore it after event
			-- dispatching: https://github.com/facebook/react/issues/13688

			local windowEventDescriptor = Object.getOwnPropertyDescriptor(window, 'event')

			function restoreAfterDispatch() {
				-- We immediately remove the callback from event listeners so that
				-- nested `invokeGuardedCallback` calls do not clash. Otherwise, a
				-- nested call would trigger the fake event handlers of any call higher
				-- in the stack.
				fakeNode.removeEventListener(evtType, callCallback, false); -- We check for window.hasOwnProperty('event') to prevent the
				-- window.event assignment in both IE <= 10 as they throw an error
				-- "Member not found" in strict mode, and in Firefox which does not
				-- support window.event.

				if typeof window.event ~= 'undefined' and window.hasOwnProperty('event') then
					window.event = windowEvent
				}
			} -- Create an event handler for our fake event. We will synchronously
			-- dispatch our fake event using `dispatchEvent`. Inside the handler, we
			-- call the user-provided callback.


			local funcArgs = Array.prototype.slice.call(arguments, 3)

			function callCallback() {
				didCall = true
				restoreAfterDispatch()
				func.apply(context, funcArgs)
				didError = false
			} -- Create a global error event handler. We use this to capture the value
			-- that was thrown. It's possible that this error handler will fire more
			-- than once; for example, if non-React code also calls `dispatchEvent`
			-- and a handler for that event throws. We should be resilient to most of
			-- those cases. Even if our error event handler fires more than once, the
			-- last error event is always used. If the callback actually does error,
			-- we know that the last error event is the correct one, because it's not
			-- possible for anything else to have happened in between our callback
			-- erroring and the code that follows the `dispatchEvent` call below. If
			-- the callback doesn't error, but the error event was fired, we know to
			-- ignore it because `didError` will be false, as described above.


			local error; -- Use this to track whether the error event is ever called.

			local didSetError = false
			local isCrossOriginError = false

			function handleWindowError(event) {
				error = event.error
				didSetError = true

				if error == nil and event.colno == 0 and event.lineno == 0 then
					isCrossOriginError = true
				}

				if event.defaultPrevented then
					-- Some other error handler has prevented default.
					-- Browsers silence the error report if this happens.
					-- We'll remember this to later decide whether to log it or not.
					if error ~= nil and typeof error == 'object' then
						try {
							error._suppressLogging = true
						} catch (inner) {-- Ignore.
						}
					}
				}
			} -- Create a fake event type.


			local evtType = `react-${function () {
				if name then
					return name
				}

				return 'invokeguardedcallback'
			}()}`; -- Attach our event handlers

			window.addEventListener('error', handleWindowError)
			fakeNode.addEventListener(evtType, callCallback, false); -- Synchronously dispatch our fake event. If the user-provided function
			-- errors, it will trigger our global error handler.

			evt.initEvent(evtType, false, false)
			fakeNode.dispatchEvent(evt)

			if windowEventDescriptor then
				Object.defineProperty(window, 'event', windowEventDescriptor)
			}

			if didCall and didError then
				if !didSetError then
					-- The callback errored, but the error event never fired.
					error = new Error('An error was thrown inside one of your components, but React ' + "doesn't know what it was. This is likely due to browser " + 'flakiness. React does its best to preserve the "Pause on ' + 'exceptions" behavior of the DevTools, which requires some ' + "DEV-mode only tricks. It's possible that these don't work in " + 'your browser. Try triggering the error in production mode, ' + 'or switching to a modern browser. If you suspect that this is ' + 'actually an issue with React, please file an issue.')
				} else if isCrossOriginError then
					error = new Error("A cross-origin error was thrown. React doesn't have access to " + 'the actual error object in development. ' + 'See https://reactjs.org/link/crossorigin-error for more information.')
				}

				this.onError(error)
			} -- Remove our event listeners


			window.removeEventListener('error', handleWindowError)

			if !didCall then
				-- Something went really wrong, and our event was not dispatched.
				-- https://github.com/facebook/react/issues/16734
				-- https://github.com/facebook/react/issues/16585
				-- Fall back to the production implementation.
				restoreAfterDispatch()
				return invokeGuardedCallbackProd.apply(this, arguments)
			}
		}
	}
]]
end

return invokeGuardedCallbackImpl

end,
["shared/isValidElementType"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/b61174fb7b09580c1ec2a8f55e73204b706d2935/packages/shared/isValidElementType.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
 ]]
local ReactSymbols = require(script.Parent:WaitForChild('ReactSymbols'))
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_PROFILER_TYPE = ReactSymbols.REACT_PROFILER_TYPE
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE
local REACT_DEBUG_TRACING_MODE_TYPE = ReactSymbols.REACT_DEBUG_TRACING_MODE_TYPE
local REACT_STRICT_MODE_TYPE = ReactSymbols.REACT_STRICT_MODE_TYPE
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
-- local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local REACT_FUNDAMENTAL_TYPE = ReactSymbols.REACT_FUNDAMENTAL_TYPE
-- local REACT_SCOPE_TYPE = ReactSymbols.REACT_SCOPE_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local REACT_SERVER_BLOCK_TYPE = ReactSymbols.REACT_SERVER_BLOCK_TYPE
local REACT_LEGACY_HIDDEN_TYPE = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE

-- local ReactFeatureFlags = require("./ReactFeatureFlags")
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI

return function(type)
	local typeofType = typeof(type)
	if typeofType == "string" or typeofType == "function" then
		return true
	end

	-- Note: typeof might be other than 'symbol' or 'number' (e.g. if it's a polyfill).
	if
		type == REACT_FRAGMENT_TYPE
		or type == REACT_PROFILER_TYPE
		or type == REACT_DEBUG_TRACING_MODE_TYPE
		or type == REACT_STRICT_MODE_TYPE
		or type == REACT_SUSPENSE_TYPE
		or type == REACT_LEGACY_HIDDEN_TYPE
		-- ROBLOX performance: eliminate compares that will only be true in React 18
		-- or type == REACT_SUSPENSE_LIST_TYPE
		-- or (enableScopeAPI and type == REACT_SCOPE_TYPE)
	then
		return true
	end

	if typeofType == "table" then
		-- ROBLOX deviation: In React, component classes are of type 'function'; for
		-- us, they're tables with a special value on their metatable
		if type.isReactComponent then
			return true
		end

		if
			type["$$typeof"] == REACT_LAZY_TYPE
			or type["$$typeof"] == REACT_MEMO_TYPE
			or type["$$typeof"] == REACT_PROVIDER_TYPE
			or type["$$typeof"] == REACT_CONTEXT_TYPE
			or type["$$typeof"] == REACT_FORWARD_REF_TYPE
			or type["$$typeof"] == REACT_FUNDAMENTAL_TYPE
			or type["$$typeof"] == REACT_BLOCK_TYPE
			or type[1] == REACT_SERVER_BLOCK_TYPE
		then
			return true
		end
	end

	return false
end

end,
["shared/objectIs"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/6faf6f5eb1705eef39a1d762d6ee381930f36775/packages/shared/objectIs.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

--[[*
 * inlined Object.is polyfill to avoid requiring consumers ship their own
 * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
 ]]
local function is(x: any, y: any): boolean
	return x == y and (x ~= 0 or 1 / x == 1 / y) or x ~= x and y ~= y -- eslint-disable-line no-self-compare
end

-- deviation: Object isn't a global in lua, so `Object.is` will never exist
local objectIs = is

return objectIs

end,
["shared/PropMarkers/Change"]=function()
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
--[[
	Change is used to generate special prop keys that can be used to connect to
	GetPropertyChangedSignal.

	Generally, Change is indexed by a Roblox property name:

		Roact.createElement("TextBox", {
			[Roact.Change.Text] = function(rbx)
				print("The TextBox", rbx, "changed text to", rbx.Text)
			end,
		})
]]

local Type = require(script.Parent.Parent:WaitForChild('Type.roblox'))

local Change = {}

local changeMetatable = {
	__tostring = function(self)
		return string.format("RoactHostChangeEvent(%s)", self.name)
	end,
}

setmetatable(Change, {
	__index = function(self, propertyName)
		local changeListener = {
			[Type] = Type.HostChangeEvent,
			name = propertyName,
		}

		setmetatable(changeListener, changeMetatable)
		Change[propertyName] = changeListener

		return changeListener
	end,
})

return Change

end,
["shared/PropMarkers/Event"]=function()
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
--[[
	Index into `Event` to get a prop key for attaching to an event on a Roblox
	Instance.

	Example:

		Roact.createElement("TextButton", {
			Text = "Hello, world!",

			[Roact.Event.MouseButton1Click] = function(rbx)
				print("Clicked", rbx)
			end
		})
]]

local Type = require(script.Parent.Parent:WaitForChild('Type.roblox'))

local Event = {}

local eventMetatable = {
	__tostring = function(self)
		return string.format("RoactHostEvent(%s)", self.name)
	end,
}

setmetatable(Event, {
	__index = function(self, eventName)
		local event = {
			[Type] = Type.HostEvent,
			name = eventName,
		}

		setmetatable(event, eventMetatable)

		Event[eventName] = event

		return event
	end,
})

return Event

end,
["shared/PropMarkers/Tag"]=function()
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
--[[
	Special value for assigning tags to roblox instances via Roact
]]
local Symbol = require(script.Parent.Parent:WaitForChild('Symbol.roblox'))

local Tag = Symbol.named("RobloxTag")

return Tag

end,
["shared/ReactComponentStackFrame"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/shared/ReactComponentStackFrame.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

type Object = { [string]: any }
type Function = (...any) -> ...any

local ReactElementType = require(script.Parent:WaitForChild('ReactElementType'))
type Source = ReactElementType.Source

-- ROBLOX deviation: Needed to properly type class components
local flowtypes = require(script.Parent:WaitForChild('flowtypes.roblox'))
type React_StatelessFunctionalComponent<P> = flowtypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = flowtypes.React_ComponentType<P>
type ReactComponent<P> = React_StatelessFunctionalComponent<P> | React_ComponentType<P>

-- ROBLOX DEVIATION: Ignore enableComponentStackLocations
-- local ReactFeatureFlags = require("./ReactFeatureFlags")
-- local enableComponentStackLocations = ReactFeatureFlags.enableComponentStackLocations

local ReactSymbols = require(script.Parent:WaitForChild('ReactSymbols'))
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE

local ConsolePatchingDev = require(script.Parent:WaitForChild('ConsolePatchingDev.roblox'))
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

local ReactSharedInternals = require(script.Parent:WaitForChild('ReactSharedInternals'))
local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher

-- ROBLOX deviation: the prefix is constant because the console prints the stack
-- frames the same way on every platform.
local prefix = "    in "

-- ROBLOX deviation: declare these now because of scoping differences between in
-- Lua and JS
local describeComponentFrame
local describeFunctionComponentFrame

-- ROBLOX deviation: since owner could be a function or a class component, we
-- need to do additional handling to get its name. It's easier to make this a
-- reusable function
local function describeOwner(owner: nil | ReactComponent<any>): string?
	if type(owner) == "function" then
		return debug.info(owner :: (any) -> any, "n")
	elseif type(owner) == "table" then
		return tostring(owner)
	end
	return nil
end

local function describeBuiltInComponentFrame(
	name: string,
	source: Source | nil,
	-- ROBLOX deviation: owner could be a class component
	owner: nil | ReactComponent<any>
): string
	-- ROBLOX deviation START: for built-in components, we can provide the full
	-- description regardless of `enableStackLocations` since we don't actually
	-- need to do any callstack trickery to get it

	-- if enableComponentStackLocations then
	-- 	if prefix == nil then
	-- 		-- Extract the VM specific prefix used by each line.
	-- 		local _, x = pcall(error, debug.traceback())

	-- 		local match = x.stack.trim().match("\n00:00:00.000 - ")
	-- 		if match then
	-- 			prefix = match[1]
	-- 		else
	-- 			prefix = ''
	-- 		end
	-- 	end
	-- 	-- We use the prefix to ensure our stacks line up with native stack frames.
	-- 	return "\n" .. prefix .. name
	-- else
	-- 	local ownerName = nil
	-- 	if _G.__DEV__ and owner then
	-- 		ownerName = describeOwner(owner)
	-- 	end

	-- 	return describeComponentFrame(name, source, ownerName)
	-- end
	local ownerName 	
if _G.__DEV__ and owner then
		ownerName = describeOwner(owner)
	end

	return describeComponentFrame(name, source, ownerName)
	-- ROBLOX deviation END
end

local reentry = false
local componentFrameCache 
if _G.__DEV__ then
	componentFrameCache = setmetatable({}, { __mode = "k" })
end

local function describeNativeComponentFrame(
	fn: nil | ReactComponent<any>, -- ROBLOX TODO: only accept tables with __tostring metamethod overridden
	construct: boolean
): string
	-- // If something asked for a stack inside a fake render, it should get ignored.
	if not fn or reentry then
		return ""
	end

	if _G.__DEV__ then
		local frame = componentFrameCache[fn]

		if frame ~= nil then
			return frame
		end
	end

	local control
	reentry = true

	-- deviation: Error.prepareStackTrace is not implemented
	-- local previousPrepareStackTrace = Error.prepareStackTrace
	-- Error.prepareStackTrace = undefined
	local previousDispatcher

	if _G.__DEV__ then
		previousDispatcher = ReactCurrentDispatcher.current
		-- Set the dispatcher in DEV because this might be call in the render
		-- function for warnings.
		ReactCurrentDispatcher.current = nil
		disableLogs()
	end

	-- // This should throw.
	-- deviation: Lua does not have stack traces with errors, so we
	-- use xpcall to convert the error and append a stack trace.
	-- This will change the theorical stack trace we want, because of
	-- the function where we call 'debug.traceback()', but the control
	-- stack will have the same added frame.
	local traceback
	local _, sample = xpcall(function()
		if construct then
			-- deviation: since we can't have a meaningful stack trace when
			-- constructing from a component class (because it does not locate
			-- component definition), we skip this case.
		else
			local _, x = pcall(function()
				traceback = debug.traceback()
				error({
					stack = traceback,
				})
			end)
			control = x;
			-- ROBLOX FIXME: Luau flow analysis bug workaround
			(fn :: (...any) -> ...any)()
		end
	end, function(message)
		return {
			message = message,
			stack = traceback,
		}
	end)

	-- deviation: Lua does not have a structure that works like a try-catch-finally
	-- so we a variable to know if the catch block returns a value. If it returns,
	-- 'earlyOutValue' will be set and we can return its value after running the
	-- instructions in the finally block.
	local earlyOutValue 
	
if sample and control and type(sample.stack) == "string" then
		-- // This extracts the first frame from the sample that isn't also in the control.
		-- // Skipping one frame that we assume is the frame that calls the two.
		local sampleLines = string.split(sample.stack, "\n")
		local controlLines = string.split(control.stack, "\n")
		-- deviation: remove one because our array of lines contains an empty string
		-- at the end
		local sampleIndex = #sampleLines - 1
		local controlIndex = #controlLines - 1

		while
			sampleIndex >= 2
			and controlIndex >= 0
			and sampleLines[sampleIndex] ~= controlLines[controlIndex]
		do
			-- // We expect at least one stack frame to be shared.
			-- // Typically this will be the root most one. However, stack frames may be
			-- // cut off due to maximum stack limits. In this case, one maybe cut off
			-- // earlier than the other. We assume that the sample is longer or the same
			-- // and there for cut off earlier. So we should find the root most frame in
			-- // the sample somewhere in the control.
			controlIndex = controlIndex - 1
		end

		while sampleIndex >= 3 and controlIndex >= 1 do
			sampleIndex = sampleIndex - 1
			controlIndex = controlIndex - 1
			-- // Next we find the first one that isn't the same which should be the
			-- // frame that called our sample function and the control.
			if sampleLines[sampleIndex] ~= controlLines[controlIndex] then
				-- // In V8, the first line is describing the message but other VMs don't.
				-- // If we're about to return the first line, and the control is also on the same
				-- // line, that'sampleIndex a pretty good indicator that our sample threw at same line as
				-- // the control. I.e. before we entered the sample frame. So we ignore this result.
				-- // This can happen if you passed a class to function component, or non-function.
				if sampleIndex ~= 1 or controlIndex ~= 1 then
					repeat
						sampleIndex = sampleIndex - 1
						controlIndex = controlIndex - 1
						-- // We may still have similar intermediate frames from the construct call.
						-- // The next one that isn't the same should be our match though.
						if
							controlIndex < 0
							or sampleLines[sampleIndex] ~= controlLines[controlIndex]
						then
							-- deviation: add the '    in ' prefix to format the component stack
							-- similar to React
							local frame = "\n" .. prefix .. sampleLines[sampleIndex]

							if _G.__DEV__ then
								componentFrameCache[fn] = frame
							end
							-- // Return the line we found.
							-- deviation: to mimic the behavior of the try-catch-finally
							-- we cannot return the value here.
							earlyOutValue = frame
						end
					until not (sampleIndex >= 3 and controlIndex >= 1)
				end

				break
			end
		end
	end

	reentry = false
	if _G.__DEV__ then
		ReactCurrentDispatcher.current = previousDispatcher
		reenableLogs()
	end

	-- deviation: Error.prepareStackTrace is not implemented
	-- Error.prepareStackTrace = previousPrepareStackTrace

	-- deviation: return here to micmic the end of the finally block
	if earlyOutValue ~= nil then
		return earlyOutValue
	end

	-- Fallback to just using the name if we couldn't make it throw.
	-- ROBLOX deviation START: Can't get displayName for functions, since fn can be a class, we can get the class name here
	local name = if type(fn) == "function"
		then debug.info(fn :: Function, "n")
		-- ROBLOX deviation :
		else if type(fn) == "table" then tostring(fn) else ""

	local syntheticFrame = ""
	if name ~= nil and name ~= "" then
		syntheticFrame = describeBuiltInComponentFrame(name)
	end

	if _G.__DEV__ then
		componentFrameCache[fn] = syntheticFrame
	end

	return syntheticFrame
end

-- ROBLOX deviation: Lua's patterns work slightly differently than regexes
local BEFORE_SLASH_PATTERN = "^(.*)[\\/]"

function describeComponentFrame(
	name: string | nil,
	source: Source | nil,
	ownerName: string | nil
): string
	local sourceInfo = ""

	if _G.__DEV__ and source then
		local path = source.fileName
		local fileName = string.gsub(path, BEFORE_SLASH_PATTERN, "")

		-- // In DEV, include code for a common special case:
		-- // prefer "folder/index.js" instead of just "index.js".
		-- ROBLOX deviation: instead of having a special case for 'index.',
		-- we use 'init.'
		if string.match(fileName, "^init%.") then
			-- deviation: finding matching strings works differently in Lua
			local pathBeforeSlash = string.match(path, BEFORE_SLASH_PATTERN)

			if pathBeforeSlash and #pathBeforeSlash ~= 0 then
				local folderName = string.gsub(pathBeforeSlash, BEFORE_SLASH_PATTERN, "")
				fileName = folderName .. "/" .. fileName
			end
		end

		sourceInfo = " (at " .. fileName .. ":" .. source.lineNumber .. ")"
	elseif ownerName then
		sourceInfo = " (created by " .. ownerName .. ")"
	end

	return "\n    in " .. (name or "Unknown") .. sourceInfo
end

local function describeClassComponentFrame(
	-- ROBLOX deviation: React.Component<any>
	ctor: any,
	source: nil | Source,
	-- ROBLOX deviation: this could be a class component OR a function component
	owner: nil | ReactComponent<any>
): string
	-- ROBLOX deviation START: In Roact, class components are tables, so we
	-- jump directly to using the basic component description.

	-- if enableComponentStackLocations then
	-- 	return describeNativeComponentFrame(componentClass, true)
	-- else
	-- 	return describeFunctionComponentFrame(ctor, source, ownerFn);
	-- end
	local name = tostring(ctor)
	local ownerName 	
if _G.__DEV__ and owner then
		ownerName = describeOwner(owner)
	end
	return describeComponentFrame(name, source, ownerName)
	-- ROBLOX deviation END
end

function describeFunctionComponentFrame(
	-- ROBLOX TODO: this annotation is incorrect upstream, we fix it here
	fn: nil | Function,
	source: nil | Source,
	-- ROBLOX deviation: this could be a class component OR a function component
	ownerFn: nil | ReactComponent<any>
): string
	-- ROBLOX DEVIATION Jump directly to using basic component description:
	-- if enableComponentStackLocations then
	-- 	return describeNativeComponentFrame(fn, false)
	-- else
	-- 	if not fn then
	-- 		return ""
	-- 	end
	-- 	-- ROBLOX deviation: use debug.info to discover function names
	-- 	local name = debug.info(fn :: Function, "n")
	-- 	local ownerName = nil
	-- 	if _G.__DEV__ and ownerFn then
	-- 		-- ROBLOX deviation: owner may be a function or a table
	-- 		ownerName = describeOwner(ownerFn)
	-- 	end
	-- 	return describeComponentFrame(name, source, ownerName)
	-- end
	if not fn then
		return ""
	end
	-- ROBLOX deviation: use debug.info to discover function names
	-- ROBLOX FIXME: find out how non-functions are getting into here, they pollute test output
	local name = if type(fn) == "function"
		then debug.info(fn :: Function, "n")
		else tostring(fn)
	local ownerName 	
if _G.__DEV__ and ownerFn then
		-- ROBLOX deviation: owner may be a function or a table
		ownerName = describeOwner(ownerFn)
	end
	return describeComponentFrame(name, source, ownerName)
end

-- ROBLOX deviation: because of deviations in other functions, this function is
-- not needed. If we need to bring it, it should return true if Component is a
-- class component, and false if a function component
-- local function shouldConstruct(Component)
-- 	local prototype = Component.prototype
-- 	return not not (prototype and prototype.isReactComponent)
-- end

local function describeUnknownElementTypeFrameInDEV(
	type_: any,
	source: nil | Source,
	-- ROBLOX deviation: owner could be a class component
	ownerFn: nil | ReactComponent<any>
): string
	if not _G.__DEV__ then
		return ""
	end
	if type_ == nil then
		return ""
	end

	-- ROBLOX deviation: in JavaScript, if `type` contains a class, typeof will
	-- return "function". We need to specifically check for the class.
	if type(type_) == "table" and type(type_.__ctor) == "function" then
		-- ROBLOX deviation: since Roact class components are tables, we can't
		-- count on describeClassComponent being a thin wrapper for
		-- describeFunctionComponent like upstream does implicitly
		return describeClassComponentFrame(type_, source, ownerFn)
	end

	if type(type_) == "function" then
		-- ROBLOX DEVIATION: ignore enableComponentStackLocations
		-- if enableComponentStackLocations then
		-- 	-- ROBLOX deviation: since functions and classes have different
		-- 	-- types in Lua, we already know that shouldConstruct would return
		-- 	-- false
		-- 	return describeNativeComponentFrame(type, false)
		-- else
		-- 	return describeFunctionComponentFrame(type, source, ownerFn)
		-- end
		return describeFunctionComponentFrame(type_, source, ownerFn)
	end

	if type(type_) == "string" then
		return describeBuiltInComponentFrame(type_, source, ownerFn)
	end

	if type_ == REACT_SUSPENSE_TYPE then
		return describeBuiltInComponentFrame("Suspense", source, ownerFn)
	elseif type_ == REACT_SUSPENSE_LIST_TYPE then
		return describeBuiltInComponentFrame("SuspenseList", source, ownerFn)
	end

	if type(type_) == "table" then
		local typeProp = type_["$$typeof"]
		if typeProp == REACT_FORWARD_REF_TYPE then
			return describeFunctionComponentFrame(type_.render, source, ownerFn)
		elseif typeProp == REACT_MEMO_TYPE then
			-- // Memo may contain any component type so we recursively resolve it.
			return describeUnknownElementTypeFrameInDEV(type_.type, source, ownerFn)
		elseif typeProp == REACT_BLOCK_TYPE then
			return describeFunctionComponentFrame(type_._render, source, ownerFn)
		elseif typeProp == REACT_LAZY_TYPE then
			local lazyComponent = type_
			local payload = lazyComponent._payload
			local init = lazyComponent._init

			local ok, result = pcall(function()
				describeUnknownElementTypeFrameInDEV(
					-- // Lazy may contain any component type so we recursively resolve it.
					init(payload),
					source,
					ownerFn
				)
			end)

			if ok then
				return result
			end
		end
	end

	return ""
end

return {
	-- deviation: ReactShallowRenderer depends on this, but the upstream `react`
	-- repo doesn't expose it; instead, the shallow-renderer's copies of shared
	-- modules do so. Since we opted to reuse the shared modules in this repo
	-- instead of duplicating, we need to have them include this field
	describeComponentFrame = describeComponentFrame,

	describeBuiltInComponentFrame = describeBuiltInComponentFrame,
	describeNativeComponentFrame = describeNativeComponentFrame,
	describeClassComponentFrame = describeClassComponentFrame,
	describeFunctionComponentFrame = describeFunctionComponentFrame,
	describeUnknownElementTypeFrameInDEV = describeUnknownElementTypeFrameInDEV,
}

end,
["shared/ReactElementType"]=function()
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Object = LuauPolyfill.Object

local flowtypes = require(script.Parent:WaitForChild('flowtypes.roblox'))
type React_Element<ElementType> = flowtypes.React_Element<ElementType>
type React_StatelessFunctionalComponent<P> = flowtypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = flowtypes.React_ComponentType<P>

export type Source = {
	fileName: string,
	lineNumber: number
}
type Key = string | number
-- ROBLOX deviation: we're using the TypeScript definition here, which is more strict
export type ReactElement<P = Object, T = any> = {
	["$$typeof"]: number,

	-- ROBLOX FIXME Luau: Luau has some trouble and inlining the type param from createElement doesn't help
	type: React_StatelessFunctionalComponent<P> | React_ComponentType<P> | string,
	-- type: T,
	key: Key | nil,
	ref: any,
	props: P,

	-- ROBLOX deviation: upstream has this as interface, which is extensible, Luau types are closed by default
	-- ReactFiber
	_owner: any,

	-- __DEV__
	_store: any?,
	_self: React_Element<any>?,
	_shadowChildren: any?,
	_source: Source?
}

-- deviation: Return something so that the module system is happy
return {}

end,
["shared/ReactErrorUtils"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/b87aabdfe1b7461e7331abb3601d9e6bb27544bc/packages/shared/ReactErrorUtils.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local invariant = require(script.Parent:WaitForChild('invariant'))
local invokeGuardedCallbackImpl = require(script.Parent:WaitForChild('invokeGuardedCallbackImpl'))
-- deviation: preemptively declare function

local clearCaughtError

-- Used by Fiber to simulate a try-catch.
local hasError = false
local caughtError 
-- Used by event system to capture/rethrow the first error.

local hasRethrowError = false
local rethrowError 
local reporter = {
	onError = function(err)
		hasError = true
		caughtError = err
	end,
}
local exports = {}

--[[*
* Call a function while guarding against errors that happens within it.
* Returns an error if it throws, otherwise nil.
*
* In production, this is implemented using a try-catch. The reason we don't
* use a try-catch directly is so that we can swap out a different
* implementation in DEV mode.
*
* @param {String} name of the guard to use for logging or debugging
* @param {Function} func The function to invoke
* @param {*} context The context to use when calling the function
* @param {...*} args Arguments for function
]]
exports.invokeGuardedCallback = function(...)
	hasError = false
	caughtError = nil
	-- deviation: passing in reporter directly
	invokeGuardedCallbackImpl(reporter, ...)
end

--[[*
* Same as invokeGuardedCallback, but instead of returning an error, it stores
* it in a global so it can be rethrown by `rethrowCaughtError` later.
* TODO: See if caughtError and rethrowError can be unified.
*
* @param {String} name of the guard to use for logging or debugging
* @param {Function} func The function to invoke
* @param {*} context The context to use when calling the function
* @param {...*} args Arguments for function
]]
exports.invokeGuardedCallbackAndCatchFirstError = function(...)
	-- deviation: instead of the weird `this` indirection, pass varargs through
	exports.invokeGuardedCallback(...)

	if hasError then
		local err = clearCaughtError()

		if not hasRethrowError then
			hasRethrowError = true
			rethrowError = err
		end
	end
end

--[[*
* During execution of guarded functions we will capture the first error which
* we will rethrow to be handled by the top level error handler.
]]
exports.rethrowCaughtError = function()
	if hasRethrowError then
		local err = rethrowError
		hasRethrowError = false
		rethrowError = nil
		error(err)
	end
end

exports.hasCaughtError = function()
	return hasError
end

clearCaughtError = function()
	if hasError then
		local err = caughtError
		hasError = false
		caughtError = nil
		return err
	else
		invariant(
			false,
[[clearCaughtError was called but no error was captured. This error is likely caused by a bug in React. Please file an issue.]]		

)
		-- deviation: luau doesn't know that invariant throws, so we return nil
		return nil
	end
end
exports.clearCaughtError = clearCaughtError

return exports

end,
["shared/ReactFeatureFlags"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ba82eea3837e4aaeb5a30b7827b664a8c2128d2e/packages/shared/ReactFeatureFlags.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
-- Unknown globals fail type checking (see "Unknown symbols" section of
-- https://roblox.github.io/luau/typecheck.html)
local exports = {}

-- Filter certain DOM attributes (e.g. src, href) if their values are empty strings.
-- This prevents e.g. <img src=""> from making an unnecessary HTTP request for certain browsers.
exports.enableFilterEmptyStringAttributesDOM = true

-- Adds verbose console logging for e.g. state updates, suspense, and work loop stuff.
-- Intended to enable React core members to more easily debug scheduling issues in DEV builds.
exports.enableDebugTracing = false

-- Adds user timing marks for e.g. state updates, suspense, and work loop stuff,
-- for an experimental scheduling profiler tool.
exports.enableSchedulingProfiler = _G.__PROFILE__ and _G.__EXPERIMENTAL__

-- Helps identify side effects in render-phase lifecycle hooks and setState
-- reducers by double invoking them in Strict Mode.
-- ROBLOX TODO: we'll want to enable this for DEV app bundles
exports.debugRenderPhaseSideEffectsForStrictMode = _G.__DEV__

-- To preserve the "Pause on caught exceptions" behavior of the debugger, we
-- replay the begin phase of a failed component inside invokeGuardedCallback.
exports.replayFailedUnitOfWorkWithInvokeGuardedCallback = _G.__DEV__

-- Warn about deprecated, async-unsafe lifecycles; relates to RFC #6:
exports.warnAboutDeprecatedLifecycles = true

-- Gather advanced timing metrics for Profiler subtrees.
exports.enableProfilerTimer = _G.__PROFILE__

-- Record durations for commit and passive effects phases.
exports.enableProfilerCommitHooks = false

-- Trace which interactions trigger each commit.
exports.enableSchedulerTracing = _G.__PROFILE__

-- SSR experiments
exports.enableSuspenseServerRenderer = _G.__EXPERIMENTAL__
exports.enableSelectiveHydration = _G.__EXPERIMENTAL__

-- Flight experiments
exports.enableBlocksAPI = _G.__EXPERIMENTAL__
exports.enableLazyElements = _G.__EXPERIMENTAL__

-- Only used in www builds.
exports.enableSchedulerDebugging = false

-- Disable javascript: URL strings in href for XSS protection.
exports.disableJavaScriptURLs = false

-- Experimental Host Component support.
exports.enableFundamentalAPI = false

-- Experimental Scope support.
exports.enableScopeAPI = false

-- Experimental Create Event Handle API.
exports.enableCreateEventHandleAPI = false

-- New API for JSX transforms to target - https://github.com/reactjs/rfcs/pull/107

-- We will enforce mocking scheduler with scheduler/unstable_mock at some point. (v18?)
-- Till then, we warn about the missing mock, but still fallback to a legacy mode compatible version
exports.warnAboutUnmockedScheduler = false

-- Add a callback property to suspense to notify which promises are currently
-- in the update queue. This allows reporting and tracing of what is causing
-- the user to see a loading state.
-- Also allows hydration callbacks to fire when a dehydrated boundary gets
-- hydrated or deleted.
exports.enableSuspenseCallback = false

-- Part of the simplification of React.createElement so we can eventually move
-- from React.createElement to React.jsx
-- https://github.com/reactjs/rfcs/blob/createlement-rfc/text/0000-create-element-changes.md
exports.warnAboutDefaultPropsOnFunctionComponents = false

exports.disableSchedulerTimeoutBasedOnReactExpirationTime = false

exports.enableTrustedTypesIntegration = false

-- Enables a warning when trying to spread a 'key' to an element
-- a deprecated pattern we want to get rid of in the future
exports.warnAboutSpreadingKeyToJSX = true

exports.enableComponentStackLocations = true

exports.enableNewReconciler = true

-- Errors that are thrown while unmounting (or after in the case of passive effects)
-- should bypass any error boundaries that are also unmounting (or have unmounted)
-- and be handled by the nearest still-mounted boundary.
-- If there are no still-mounted boundaries, the errors should be rethrown.
exports.skipUnmountedBoundaries = true

-- --------------------------
-- Future APIs to be deprecated
-- --------------------------

-- Prevent the value and checked attributes from syncing
-- with their related DOM properties
exports.disableInputAttributeSyncing = true

exports.warnAboutStringRefs = false

exports.disableLegacyContext = false

-- Disables children for <textarea> elements
exports.disableTextareaChildren = false

exports.disableModulePatternComponents = false

-- We should remove this flag once the above flag becomes enabled
exports.warnUnstableRenderSubtreeIntoContainer = false

-- Support legacy Primer support on internal FB www
exports.enableLegacyFBSupport = true

-- Updates that occur in the render phase are not officially supported. But when
-- they do occur, we defer them to a subsequent render by picking a lane that's
-- not currently rendering. We treat them the same as if they came from an
-- interleaved event. Remove this flag once we have migrated to the
-- new behavior.
exports.deferRenderPhaseUpdateToNextBatch = false

-- Replacement for runWithPriority in React internals.
exports.decoupleUpdatePriorityFromScheduler = true

exports.enableDiscreteEventFlushingChange = false

exports.enableEagerRootListeners = false

exports.enableDoubleInvokingEffects = false
return exports

end,
["shared/ReactFiberHostConfig"]=function()
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
--[[
	ROBLOX deviation: ReactFiberHostConfig captures singleton state across the
	whole workspace. This file and the modules it requires were moved from React
	to untangle a cyclic workspace member dependency.

	Before:
	* ReactFiberHostConfig (and the 5 associated modules) lived in React
	* React had a dependency on Shared
	* Shared reached into React source to re-export ReactFiberHostConfig (cycle)

	After:
	* ReactFiberHostConfig (and the 5 associated modules) live in Shared
	* React depends on Shared
	* Shared has no intra-workspace dependencies (no cycles)
]]

-- types that are common across ReactFiberHostConfig files, moved here to avoid circular deps
type Object = { [string]: any }
export type OpaqueIDType = string | Object

return {
	WithNoHydration = require(script:WaitForChild('WithNoHydration')),
	WithNoPersistence = require(script:WaitForChild('WithNoPersistence')),
	WithNoTestSelectors = require(script:WaitForChild('WithNoTestSelectors')),
}

end,
["shared/ReactFiberHostConfig/WithNoHydration"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/ReactFiberHostConfigWithNoHydration.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local invariant = require(script.Parent.Parent:WaitForChild('invariant'))
-- Renderers that don't support hydration
-- can re-export everything from this module.


function shim(...)
	invariant(
		false,
[[The current renderer does not support hydration. This error is likely caused by a bug in React. Please file an issue.]]	


)
end

-- Hydration (when unsupported)
export type SuspenseInstance = any
return {
	supportsHydration = false,
	canHydrateInstance = shim,
	canHydrateTextInstance = shim,
	canHydrateSuspenseInstance = shim,
	isSuspenseInstancePending = shim,
	isSuspenseInstanceFallback = shim,
	registerSuspenseInstanceRetry = shim,
	getNextHydratableSibling = shim,
	getFirstHydratableChild = shim,
	hydrateInstance = shim,
	hydrateTextInstance = shim,
	hydrateSuspenseInstance = shim,
	getNextHydratableInstanceAfterSuspenseInstance = shim,
	commitHydratedContainer = shim,
	commitHydratedSuspenseInstance = shim,
	clearSuspenseBoundary = shim,
	clearSuspenseBoundaryFromContainer = shim,
	didNotMatchHydratedContainerTextInstance = shim,
	didNotMatchHydratedTextInstance = shim,
	didNotHydrateContainerInstance = shim,
	didNotHydrateInstance = shim,
	didNotFindHydratableContainerInstance = shim,
	didNotFindHydratableContainerTextInstance = shim,
	didNotFindHydratableContainerSuspenseInstance = shim,
	didNotFindHydratableInstance = shim,
	didNotFindHydratableTextInstance = shim,
	didNotFindHydratableSuspenseInstance = shim,
}

end,
["shared/ReactFiberHostConfig/WithNoPersistence"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/ReactFiberHostConfigWithNoPersistence.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local invariant = require(script.Parent.Parent:WaitForChild('invariant'))
-- Renderers that don't support persistence
-- can re-export everything from this module.


local function shim(...)
	invariant(
		false,
[[The current renderer does not support persistence. This error is likely caused by a bug in React. Please file an issue.]]	


)
end

-- Persistence (when unsupported)
return {
	supportsPersistence = false,
	cloneInstance = shim,
	cloneFundamentalInstance = shim,
	createContainerChildSet = shim,
	appendChildToContainerChildSet = shim,
	finalizeContainerChildren = shim,
	replaceContainerChildren = shim,
	cloneHiddenInstance = shim,
	cloneHiddenTextInstance = shim,
}

end,
["shared/ReactFiberHostConfig/WithNoTestSelectors"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/3cde22a84e246fc5361f038bf0c23405b2572c22/packages/react-reconciler/src/ReactFiberHostConfigWithNoTestSelectors.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local invariant = require(script.Parent.Parent:WaitForChild('invariant'))
-- Renderers that don't support test selectors
-- can re-export everything from this module.


local function shim(...)
	invariant(
		false,
[[The current renderer does not support test selectors. This error is likely caused by a bug in React. Please file an issue.]]	


)
end

-- Test selectors (when unsupported)
return {
	supportsTestSelectors = false,
	findFiberRoot = shim,
	getBoundingRect = shim,
	getTextContent = shim,
	isHiddenSubtree = shim,
	matchAccessibilityRole = shim,
	setFocusIfFocusable = shim,
	setupIntersectionObserver = shim,
}

end,
["shared/ReactInstanceMap"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/2ba43edc2675380a0f2222f351475bf9d750c6a9/packages/shared/ReactInstanceMap.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

--[[*
 * `ReactInstanceMap` maintains a mapping from a public facing stateful
 * instance (key) and the internal representation (value). This allows public
 * methods to accept the user facing instance as an argument and map them back
 * to internal methods.
 *
 * Note that this module is currently shared and assumed to be stateless.
 * If this becomes an actual Map, that will break.
 ]]

--[[*
 * This API should be called `delete` but we'd have to make sure to always
 * transform these to strings for IE support. When this transform is fully
 * supported we can rename it.
 ]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect
local getComponentName = require(script.Parent:WaitForChild('getComponentName'))

local exports = {}

local function isValidFiber(fiber): boolean
	return fiber.tag ~= nil
		and fiber.subtreeFlags ~= nil
		and fiber.lanes ~= nil
		and fiber.childLanes ~= nil
end

exports.remove = function(key)
	key._reactInternals = nil
end

exports.get = function(key)
	local value = key._reactInternals

	-- ROBLOX deviation: we have a crash in production this will help catch
	-- ROBLOX TODO: wrap this in __DEV__
	if not isValidFiber(value) then
		error(
			Error.new(
				"invalid fiber in "
					.. (getComponentName(key) or "UNNAMED Component")
					.. " during get from ReactInstanceMap! "
					.. inspect(value)
			)
		)
	elseif value.alternate ~= nil and not isValidFiber(value.alternate) then
		error(
			Error.new(
				"invalid alternate fiber ("
					.. (getComponentName(key) or "UNNAMED alternate")
					.. ") in "
					.. (getComponentName(key) or "UNNAMED Component")
					.. " during get from ReactInstanceMap! "
					.. inspect(value.alternate)
			)
		)
	end

	return value
end

exports.has = function(key)
	return key._reactInternals ~= nil
end

exports.set = function(key, value)
	-- ROBLOX deviation: we have a crash in production this will help catch
	-- ROBLOX TODO: wrap this in __DEV__
	local parent = value
	local message
	while parent ~= nil do
		if not isValidFiber(parent) then
			message = "invalid fiber in "
				.. (getComponentName(key) or "UNNAMED Component")
				.. " being set in ReactInstanceMap! "
				.. inspect(parent)
				.. "\n"

			if value ~= parent then
				message ..= " (from original fiber " .. (getComponentName(key) or "UNNAMED Component") .. ")"
			end
			error(Error.new(message))
		elseif
			(parent :: any).alternate ~= nil
			and not isValidFiber((parent :: any).alternate)
		then
			message = "invalid alternate fiber ("
				.. (getComponentName(key) or "UNNAMED alternate")
				.. ") in "
				.. (getComponentName(key) or "UNNAMED Component")
				.. " being set in ReactInstanceMap! "
				.. inspect((parent :: any).alternate)
				.. "\n"

			if value ~= parent then
				message ..= " (from original fiber " .. (getComponentName(key) or "UNNAMED Component") .. ")"
			end
			error(Error.new(message))
		end
		parent = (parent :: any).return_
	end

	(key :: any)._reactInternals = value
end

return exports

end,
["shared/ReactSharedInternals"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/607148673b3156d051d1fed17cd49e83698dce54/packages/react/src/ReactSharedInternals.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

--[[
	ROBLOX deviation: ReactSharedInternals captures singleton state across the
	whole workspace. This file and the modules it requires were moved from React
	to untangle a cyclic workspace member dependency.

	Before:
	* ReactSharedInternals (and the 5 associated modules) lived in React
	* React had a dependency on Shared
	* Shared reached into React source to re-export ReactSharedInternals (cycle)

	After:
	* ReactSharedInternals (and the 5 associated modules) live in Shared
	* React depends on Shared
	* Shared has no intra-workspace dependencies (no cycles)
]]
local console = require(script.Parent.Parent:WaitForChild('luau-polyfill')).console
local function onlyInTestError(functionName: string)
	return function()
		console.error(functionName .. " is only available in tests, not in production")
	end
end

-- import assign from 'object-assign';
local ReactCurrentDispatcher = require(script:WaitForChild('ReactCurrentDispatcher'))
export type Dispatcher = ReactCurrentDispatcher.Dispatcher
local ReactCurrentBatchConfig = require(script:WaitForChild('ReactCurrentBatchConfig'))
local ReactCurrentOwner = require(script:WaitForChild('ReactCurrentOwner'))
local ReactDebugCurrentFrame = require(script:WaitForChild('ReactDebugCurrentFrame'))
local IsSomeRendererActing = require(script:WaitForChild('IsSomeRendererActing'))

local ReactSharedInternals = {
	ReactCurrentDispatcher = ReactCurrentDispatcher,
	ReactCurrentBatchConfig = ReactCurrentBatchConfig,
	ReactCurrentOwner = ReactCurrentOwner,
	IsSomeRendererActing = IsSomeRendererActing,
	-- ROBLOX deviation: Luau type checking requires us to have a consistent export shape regardless of __DEV__
	-- ROBLOX TODO: use if-expressions when all clients are on 503+
	ReactDebugCurrentFrame = if _G.__DEV__
		then ReactDebugCurrentFrame
		else {
			setExtraStackFrame = function(_: string?): ()
				onlyInTestError("setExtraStackFrame")
			end,
		},
	-- deviation: We shouldn't have to worry about duplicate bundling here
	-- Used by renderers to avoid bundling object-assign twice in UMD bundles:
	-- assign,
}

return ReactSharedInternals

end,
["shared/ReactSharedInternals/IsSomeRendererActing"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/a457e02ae3a2d3903fcf8748380b1cc293a2445e/packages/react/src/IsSomeRendererActing.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * Used by act() to track whether you're inside an act() scope.
 ]]

local IsSomeRendererActing = {
	current = false,
}
return IsSomeRendererActing

end,
["shared/ReactSharedInternals/ReactCurrentBatchConfig"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/92fcd46cc79bbf45df4ce86b0678dcef3b91078d/packages/react/src/ReactCurrentBatchConfig.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * Keeps track of the current batch's configuration such as how long an update
 * should suspend for if it needs to.
]]
local ReactCurrentBatchConfig = {
	transition = 0,
}

return ReactCurrentBatchConfig

end,
["shared/ReactSharedInternals/ReactCurrentDispatcher"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/376d5c1b5aa17724c5fea9412f8fcde14a7b23f1/packages/react/src/ReactCurrentDispatcher.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

--[[*
 * Keeps track of the current dispatcher.
]]
local LuauPolyfill = require(script.Parent.Parent.Parent:WaitForChild('luau-polyfill'))
type Array<T> = LuauPolyfill.Array<T>

-- ROBLOX deviation: we duplicate the Dispatcher type here because upstream has a circular dependency between Shared and Reconciler
local ReactElementType = require(script.Parent.Parent:WaitForChild('ReactElementType'))
type Source = ReactElementType.Source
local ReactTypes = require(script.Parent.Parent:WaitForChild('ReactTypes'))
type RefObject = ReactTypes.RefObject
type ReactContext<T> = ReactTypes.ReactContext<T>
-- ROBLOX deviation START: binding support
type ReactBinding<T> = ReactTypes.ReactBinding<T>
type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
-- ROBLOX deviation END: binding support
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

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()

export type Dispatcher = {
	readContext: <T>(
		context: ReactContext<T>,
		observedBits: nil | number | boolean
	) -> T,
	useState: <S>(initialState: (() -> S) | S) -> (S, Dispatch<BasicStateAction<S>>),
	useReducer: <S, I, A>(
		reducer: (S, A) -> S,
		initialArg: I,
		init: ((I) -> S)?
	) -> (S, Dispatch<A>),
	useContext: <T>(
		context: ReactContext<T>,
		observedBits: nil | number | boolean
	) -> T,
	useRef: <T>(initialValue: T) -> { current: T },
	-- ROBLOX deviation START: Bindings are a feature unique to Roact
	useBinding: <T>(initialValue: T) -> (ReactBinding<T>, ReactBindingUpdater<T>),
	-- ROBLOX deviation END
	useEffect: (
		-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
		create: (() -> ()) | (() -> (() -> ())),
		deps: Array<any> | nil
	) -> (),
	useLayoutEffect: (
		-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
		create: (() -> ()) | (() -> (() -> ())),
		deps: Array<any> | nil
	) -> (),
	useCallback: <T>(callback: T, deps: Array<any> | nil) -> T,
	useMemo: <T...>(nextCreate: () -> T..., deps: Array<any> | nil) -> T...,
	useImperativeHandle: <T>(
		ref: { current: T | nil } | ((inst: T | nil) -> any) | nil,
		create: () -> T,
		deps: Array<any> | nil
	) -> (),
	useDebugValue: <T>(value: T, formatterFn: ((value: T) -> any)?) -> (),
	-- ROBLOX TODO: make these non-optional and implement them in the dispatchers
	useDeferredValue: (<T>(value: T) -> T)?,
	useTransition: (() -> ((() -> ()) -> (), boolean))?, -- ROBLOX deviation: Luau doesn't support jagged array types [(() -> ()) -> (), boolean],
	useMutableSource: <Source, Snapshot>(
		source: MutableSource<Source>,
		getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
		subscribe: MutableSourceSubscribeFn<Source, Snapshot>
	) -> Snapshot,
	useOpaqueIdentifier: () -> any,

	unstable_isNewReconciler: boolean?	-- [string]: any,

}

local ReactCurrentDispatcher: { current: nil | Dispatcher } = {
	--[[
		* @internal
		* @type {ReactComponent}
		*/
	]]
	current = nil,
}

return ReactCurrentDispatcher

end,
["shared/ReactSharedInternals/ReactCurrentOwner"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/376d5c1b5aa17724c5fea9412f8fcde14a7b23f1/packages/react/src/ReactCurrentOwner.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * Keeps track of the current owner.
 *
 * The current owner is the component who should own any components that are
 * currently being constructed.
]]
local ReactCurrentOwner = {
	--[[*
   * @internal
   * @type {ReactComponent}
   ]]
	-- ROBLOX deviation START: upstream types this as Fiber, but that would incur a circular dependency between reconciler and shared
	current = nil :: any,
	-- ROBLOX deviation END
}

return ReactCurrentOwner

end,
["shared/ReactSharedInternals/ReactDebugCurrentFrame"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/98d410f5005988644d01c9ec79b7181c3dd6c847/packages/react/src/ReactDebugCurrentFrame.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local ReactDebugCurrentFrame = {}

local currentExtraStackFrame = nil :: nil | string

function ReactDebugCurrentFrame.setExtraStackFrame(stack: string?): ()
	if _G.__DEV__ then
		currentExtraStackFrame = stack
	end
end

if _G.__DEV__ then
	-- deviation: in Lua, the implementation is duplicated
	-- function ReactDebugCurrentFrame.setExtraStackFrame(stack: string?)
	-- 	if _G.__DEV__ then
	-- 		currentExtraStackFrame = stack
	-- 	end
	-- end

	-- Stack implementation injected by the current renderer.
	ReactDebugCurrentFrame.getCurrentStack = nil :: nil | (() -> string)

	function ReactDebugCurrentFrame.getStackAddendum(): string
		local stack = ""

		-- Add an extra top frame while an element is being validated
		if currentExtraStackFrame then
			stack = stack .. currentExtraStackFrame
		end

		-- Delegate to the injected renderer-specific implementation
		local impl = ReactDebugCurrentFrame.getCurrentStack
		if impl then
			stack = stack .. (impl() or "")
		end

		return stack
	end
end

return ReactDebugCurrentFrame

end,
["shared/ReactSymbols"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/b61174fb7b09580c1ec2a8f55e73204b706d2935/packages/shared/ReactSymbols.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

-- ATTENTION
-- When adding new symbols to this file,
-- Please consider also adding to 'react-devtools-shared/src/backend/ReactSymbols'

-- local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
-- local Symbol = LuauPolyfill.Symbol

local exports: { [string]: any } = {}

-- The Symbol used to tag the ReactElement-like types. If there is no native Symbol
-- nor polyfill, then a plain number is used for performance.
exports.REACT_ELEMENT_TYPE = 0xeac7
exports.REACT_PORTAL_TYPE = 0xeaca
exports.REACT_FRAGMENT_TYPE = 0xeacb
exports.REACT_STRICT_MODE_TYPE = 0xeacc
exports.REACT_PROFILER_TYPE = 0xead2
exports.REACT_PROVIDER_TYPE = 0xeacd
exports.REACT_CONTEXT_TYPE = 0xeace
exports.REACT_FORWARD_REF_TYPE = 0xead0
exports.REACT_SUSPENSE_TYPE = 0xead1
exports.REACT_SUSPENSE_LIST_TYPE = 0xead8
exports.REACT_MEMO_TYPE = 0xead3
exports.REACT_LAZY_TYPE = 0xead4
exports.REACT_BLOCK_TYPE = 0xead9
exports.REACT_SERVER_BLOCK_TYPE = 0xeada
exports.REACT_FUNDAMENTAL_TYPE = 0xead5
exports.REACT_SCOPE_TYPE = 0xead7
exports.REACT_OPAQUE_ID_TYPE = 0xeae0
exports.REACT_DEBUG_TRACING_MODE_TYPE = 0xeae1
exports.REACT_OFFSCREEN_TYPE = 0xeae2
exports.REACT_LEGACY_HIDDEN_TYPE = 0xeae3
exports.REACT_BINDING_TYPE = 0xeae4

-- ROBLOX TODO: Use Symbol again once jest-mock knows to exclude the LuauPolyfill module from being reset
-- deviation: In Lua, Symbol will be a callable table, not a function
-- if typeof(Symbol) == "table" and Symbol.for_ ~= nil then
--   local symbolFor = Symbol.for_
--   exports.REACT_ELEMENT_TYPE = symbolFor('react.element')
--   exports.REACT_PORTAL_TYPE = symbolFor('react.portal')
--   exports.REACT_FRAGMENT_TYPE = symbolFor('react.fragment')
--   exports.REACT_STRICT_MODE_TYPE = symbolFor('react.strict_mode')
--   exports.REACT_PROFILER_TYPE = symbolFor('react.profiler')
--   exports.REACT_PROVIDER_TYPE = symbolFor('react.provider')
--   exports.REACT_CONTEXT_TYPE = symbolFor('react.context')
--   exports.REACT_FORWARD_REF_TYPE = symbolFor('react.forward_ref')
--   exports.REACT_SUSPENSE_TYPE = symbolFor('react.suspense')
--   exports.REACT_SUSPENSE_LIST_TYPE = symbolFor('react.suspense_list')
--   exports.REACT_MEMO_TYPE = symbolFor('react.memo')
--   exports.REACT_LAZY_TYPE = symbolFor('react.lazy')
--   exports.REACT_BLOCK_TYPE = symbolFor('react.block')
--   exports.REACT_SERVER_BLOCK_TYPE = symbolFor('react.server.block')
--   exports.REACT_FUNDAMENTAL_TYPE = symbolFor('react.fundamental')
--   exports.REACT_SCOPE_TYPE = symbolFor('react.scope')
--   exports.REACT_OPAQUE_ID_TYPE = symbolFor('react.opaque.id')
--   exports.REACT_DEBUG_TRACING_MODE_TYPE = symbolFor('react.debug_trace_mode')
--   exports.REACT_OFFSCREEN_TYPE = symbolFor('react.offscreen')
--   exports.REACT_LEGACY_HIDDEN_TYPE = symbolFor('react.legacy_hidden')
-- end

-- deviation: short circuit for now
--local MAYBE_ITERATOR_SYMBOL = false -- deviation: typeof(Symbol) == 'function' and Symbol.iterator
--local FAUX_ITERATOR_SYMBOL = '@@iterator'

type Iterator<T> = {
	next: () -> {
		value: T,
		key: any,
		done: boolean	
}
}
-- ROBLOX deviation: upstream type is incorrect, as returned function takes a parameter in reconcileChildrenIterator()
exports.getIteratorFn = function(maybeIterable): nil | (...any) -> Iterator<any>
	if typeof(maybeIterable) == "table" then
		-- ROBLOX deviation: Upstream understands that portal objects are not
		-- iterable; we need to check explicitly
		if maybeIterable["$$typeof"] == exports.REACT_PORTAL_TYPE then
			return nil
		end
		return function()
			local currentKey: any, currentValue: any
			return {
				next = function()
					currentKey, currentValue = next(maybeIterable, currentKey)
					return {
						done = currentValue == nil,
						-- deviation: To support Roact's table-keys-as-stable-keys feature,
						-- we need the iterator to return the key as well
						key = currentKey,
						value = currentValue,
					}
				end,
			}
		end
	end

	return nil
end

return exports

end,
["shared/ReactTypes"]=function()
--!strict
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
type Object = LuauPolyfill.Object
type void = nil
type NonMaybeType<T> = T

local flowtypes = require(script.Parent:WaitForChild('flowtypes.roblox'))
type React_Element<T> = flowtypes.React_Element<T>
type React_Node = flowtypes.React_Node
type SimpleMap<K, V> = { [K]: V }
type Iterable<T> = SimpleMap<string | number, T> | Array<T>

export type ReactNode<T = any> =
	React_Element<T>
	| ReactPortal
	-- | ReactText
	| ReactFragment
	| ReactProvider<T>
	| ReactConsumer<T>

export type ReactEmpty = nil | void | boolean

export type ReactFragment = ReactEmpty | Iterable<React_Node>

export type ReactNodeList = ReactEmpty | React_Node

-- ROBLOX deviation START: Roblox renderer doesn't support TextNode, only use of this type is in this file
-- export type ReactText = string | number;
-- ROBLOX deviation END
export type ReactProvider<T> = {
	["$$typeof"]: number,
	type: ReactProviderType<T>,
	key: nil | string,
	ref: nil,
	props: {
		value: T,
		children: ReactNodeList?		-- ROBLOX deviation START: only make this open to extension if absolutely necessary
		-- ...
		-- ROBLOX deviation END
	
}	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END

}

export type ReactProviderType<T> = {
	["$$typeof"]: number,
	_context: ReactContext<T>	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END

}

export type ReactConsumer<T> = {
	["$$typeof"]: number,
	type: ReactContext<T>, -- ROBLOX FIXME: Luau can't do <T> because:  Recursive type being used with different parameters
	key: nil | string,
	ref: nil,
	props: {
		children: (value: T) -> ReactNodeList,
		unstable_observedBits: number?		-- ROBLOX deviation START: only make this open to extension if absolutely necessary
		-- ...
		-- ROBLOX deviation END
	
}	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END

}

export type ReactContext<T> = {
	["$$typeof"]: number,
	Consumer: ReactContext<T>,
	Provider: ReactProviderType<T>,
	_calculateChangedBits: ((T, T) -> number)?,
	_currentValue: T,
	_currentValue2: T,
	_threadCount: number,
	-- DEV only
	_currentRenderer: Object | nil,
	_currentRenderer2: Object | nil,
	-- This value may be added by application code
	-- to improve DEV tooling display names
	displayName: string?	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END

}

export type ReactPortal = {
	["$$typeof"]: number,
	key: nil | string,
	containerInfo: any,
	children: ReactNodeList,
	-- TODO: figure out the API for cross-renderer implementation.
	implementation: any	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END

}

export type RefObject = { current: any }

-- ROBLOX deviation START: No Luau support for numeric literal types
-- export type EventPriority = 0 | 1 | 2;
export type EventPriority = number
-- ROBLOX deviation END

local exports = {}
exports.DiscreteEvent = 0
exports.UserBlockingEvent = 1
exports.ContinuousEvent = 2

export type ReactFundamentalComponentInstance<C, H> = {
	currentFiber: Object,
	instance: any,
	prevProps: Object?,
	props: Object,
	impl: ReactFundamentalImpl<C, H>,
	state: Object
}

export type ReactFundamentalImpl<C, H> = {
	displayName: string,
	reconcileChildren: boolean,
	getInitialState: nil | (Object) -> (Object),
	getInstance: (C, Object, Object) -> (H),
	getServerSideString: nil | (C, Object) -> (string),
	getServerSideStringClose: nil | (C, Object) -> (string),
	onMount: (C, any, Object, Object) -> (),
	shouldUpdate: nil | (C, Object?, Object, Object) -> (boolean),
	onUpdate: nil | (C, any, Object?, Object, Object) -> (),
	onUnmount: nil | (C, any, Object, Object) -> (),
	onHydrate: nil | (C, Object, Object) -> boolean,
	onFocus: nil | (C, Object, Object) -> boolean
}
export type ReactFundamentalComponent<C, H> = {
	["$$typeof"]: number,
	impl: ReactFundamentalImpl<C, H>
}

export type ReactScope = {
	["$$typeof"]: number
}

export type ReactScopeQuery = (
	type: string,
	-- ROBLOX deviation START: leave closed to extension unless necessary
	props: { [string]: any? },
	-- ROBLOX deviation END
	instance: any
) -> boolean

export type ReactScopeInstance = {
	DO_NOT_USE_queryAllNodes: (ReactScopeQuery) -> nil | Array<Object>,
	DO_NOT_USE_queryFirstNode: (ReactScopeQuery) -> nil | Object,
	containsNode: (Object) -> boolean,
	getChildContextValues: <T>(context: ReactContext<T>) -> Array<T>
}

-- ROBLOX deviation START: Bindings are unique to Roact
-- FIXME Luau: can't create recursive type with different parameters, so we
-- need to split the generic `map` method into a different type and then
-- re-combine those types together
type CoreReactBinding<T> = {
	getValue: (self: CoreReactBinding<T>) -> T,
	_source: string?
}
type ReactBindingMap = {
	map: <T, U>(
		self: CoreReactBinding<T> & ReactBindingMap,
		(T) -> U
	) -> ReactBindingMap & CoreReactBinding<U>
}

export type ReactBinding<T> = CoreReactBinding<T> & ReactBindingMap
export type ReactBindingUpdater<T> = (T) -> ()
-- ROBLOX deviation END

-- Mutable source version can be anything (e.g. number, string, immutable data structure)
-- so long as it changes every time any part of the source changes.
export type MutableSourceVersion = NonMaybeType<any>

export type MutableSourceGetSnapshotFn<Source, Snapshot> = (source: Source) -> Snapshot

export type MutableSourceSubscribeFn<Source, Snapshot> = (
	source: Source,
	callback: (snapshot: Snapshot) -> ()
) -> (() -> ())

export type MutableSourceGetVersionFn = (
	_source: NonMaybeType<any>
) -> MutableSourceVersion

export type MutableSource<Source> = {
	_source: Source,

	_getVersion: MutableSourceGetVersionFn,

	-- Tracks the version of this source at the time it was most recently read.
	-- Used to determine if a source is safe to read from before it has been subscribed to.
	-- Version number is only used during mount,
	-- since the mechanism for determining safety after subscription is expiration time.
	--
	-- As a workaround to support multiple concurrent renderers,
	-- we categorize some renderers as primary and others as secondary.
	-- We only expect there to be two concurrent renderers at most:
	-- React Native (primary) and Fabric (secondary);
	-- React DOM (primary) and React ART (secondary).
	-- Secondary renderers store their context values on separate fields.
	-- We use the same approach for Context.
	_workInProgressVersionPrimary: nil | MutableSourceVersion,
	_workInProgressVersionSecondary: nil | MutableSourceVersion,

	-- DEV only
	-- Used to detect multiple renderers using the same mutable source.
	_currentPrimaryRenderer: Object | nil,
	_currentSecondaryRenderer: Object | nil
}

-- The subset of a Thenable required by things thrown by Suspense.
-- This doesn't require a value to be passed to either handler.
export type Wakeable = {
	andThen: (
		self: Wakeable,
		onFulfill: () -> ...any,
		onReject: () -> ...any
		-- ROBLOX FIXME Luau: needs union type packs to parse () | Wakeable
	) -> nil | Wakeable,
	-- Special flag to opt out of tracing interactions across a Suspense boundary.
	__reactDoNotTraceInteractions: boolean?
}

-- The subset of a Promise that React APIs rely on. This resolves a value.
-- This doesn't require a return value neither from the handler nor the
-- then function.
-- ROBLOX FIXME: workaround for Luau recursive type used with different parameters. delete this copy once that issue is resolved.
export type _Thenable<R> = {
	andThen: <U>(
		self: _Thenable<R>,
		onFulfill: (R) -> ...U,
		onReject: (error: any) -> ...U
	) -> ()
}

export type Thenable<R> = {
	andThen: <U>(
		self: Thenable<R>,
		onFulfill: (R) -> ...(_Thenable<U> | U),
		onReject: (error: any) -> ...(_Thenable<U> | U)
		-- ROBLOX FIXME Luau: need union type packs to parse () | Thenable<U>: CLI-49836
	) -> nil | _Thenable<U>
}

return exports

end,
["shared/ReactVersion"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/a89854bc936668d325cac9a22e2ebfa128c7addf/packages/shared/ReactVersion.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

-- TODO: this is special because it gets imported during build.
return "17.2.1"

end,
["shared/shallowEqual"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/a9b035b0c2b8235405835beca0c4db2cc37f18d0/packages/shared/shallowEqual.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
]]
local is = require(script.Parent:WaitForChild('objectIs'))
--[[*
 * Performs equality by iterating through keys on an object and returning false
 * when any key has values which are not strictly equal between the arguments.
 * Returns true when the values of all keys are strictly equal.
]]

local function shallowEqual(objA, objB)
	if is(objA, objB) then
		return true
	end

	if
		typeof(objA) ~= "table"
		or objA == nil
		or typeof(objB) ~= "table"
		or objB == nil
	then
		return false
	end

	-- deviation: `Object.keys` does not have an equivalent in Lua, so we
	-- iterate through each table instead
	for key, value in objA do
		if not is(objB[key], value) then
			return false
		end
	end

	for key, value in objB do
		if not is(objA[key], value) then
			return false
		end
	end

	return true
end

return shallowEqual

end,
["shared/Symbol.roblox"]=function()
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
--[[
	A 'Symbol' is an opaque marker type.

	Symbols have the type 'userdata', but when printed to the console, the name
	of the symbol is shown.
]]

local Symbol = {}

--[[
	Creates a Symbol with the given name.

	When printed or coerced to a string, the symbol will turn into the string
	given as its name.
]]
function Symbol.named(name)
	assert(type(name) == "string", "Symbols must be created using a string name!")

	local self = newproxy(true)

	local wrappedName = string.format("Symbol(%s)", name)

	getmetatable(self).__tostring = function()
		return wrappedName
	end

	return self
end

return Symbol

end,
["shared/Type.roblox"]=function()
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
--[[
	Contains markers for annotating objects with types.

	To set the type of an object, use `Type` as a key and the actual marker as
	the value:

		local foo = {
			[Type] = Type.Foo,
		}
]]

local Symbol = require(script.Parent:WaitForChild('Symbol.roblox'))

local Type = newproxy(true)

local TypeInternal = {}

local function addType(name)
	TypeInternal[name] = Symbol.named("Roact" .. name)
end

addType("HostChangeEvent")
addType("HostEvent")

function TypeInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[Type]
end

getmetatable(Type).__index = TypeInternal

getmetatable(Type).__tostring = function()
	return "RoactType"
end

return Type

end,
["shared/UninitializedState.roblox"]=function()
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
--!strict
local console = require(script.Parent:WaitForChild('console'))
-- ROBLOX DEVIATION: Initialize state to a singleton that warns on access and errors on assignment
-- initial state singleton

local UninitializedState = {}

setmetatable(UninitializedState, {
	__index = function(table, key)
		if _G.__DEV__ then
			console.warn(
				"Attempted to access uninitialized state. Use setState to initialize state"
			)
		end
		return nil
	end,
	__newindex = function(table, key)
		if _G.__DEV__ then
			console.error(
				"Attempted to directly mutate state. Use setState to assign new values to state."
			)
		end
		return nil
	end,
	__tostring = function(self)
		return "<uninitialized component state>"
	end,
	__metatable = "UninitializedState",
})

return UninitializedState

end,
}

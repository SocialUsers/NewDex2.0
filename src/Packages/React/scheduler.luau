-- jsdotlua/scheduler@17.2.1; see THIRD_PARTY_NOTICES.md
return {
["scheduler/forks/SchedulerHostConfig.default"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/5474a83e258b497584bed9df95de1d554bc53f89/packages/scheduler/src/forks/SchedulerHostConfig.default.js
--!strict
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

local LuauPolyfill = require(script.Parent.Parent.Parent:WaitForChild('luau-polyfill'))
type Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object
local Shared = require(script.Parent.Parent.Parent:WaitForChild('shared'))
local console = Shared.console
local errorToString = Shared.errorToString
local describeError = Shared.describeError

-- ROBLOX deviation: getCurrentTime will always map to `tick` in Luau
local getCurrentTime = function()
	-- Return a result in milliseconds
	return os.clock() * 1000
end

-- ROBLOX deviation: This module in React exports a different implementation if
-- it detects certain APIs from the DOM interface. We instead attempt to
-- approximate that behavior so that we can access features like dividing work
-- according to frame time

-- Capture local references to native APIs, in case a polyfill overrides them.
local setTimeout = LuauPolyfill.setTimeout
local clearTimeout = LuauPolyfill.clearTimeout

local isMessageLoopRunning = false
local scheduledHostCallback: ((boolean, number) -> boolean) | nil 
local taskTimeoutID = Object.None

-- Scheduler periodically yields in case there is other work on the main
-- thread, like user events. By default, it yields multiple times per frame.
-- It does not attempt to align with frame boundaries, since most tasks don't
-- need to be frame aligned; for those that do, use requestAnimationFrame.
local yieldInterval = 15
local deadline = 0

-- ROBLOX deviation: Removed some logic around browser functionality that's not
-- present in the roblox engine
local function shouldYieldToHost()
	return getCurrentTime() >= deadline
end

-- Since we yield every frame regardless, `requestPaint` has no effect.
local function requestPaint() end

local function forceFrameRate(fps)
	if fps < 0 or fps > 125 then
		console.warn(
[[forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported]]		

)
		return
	end
	if fps > 0 then
		yieldInterval = math.floor(1000 / fps)
	else
		-- reset the framerate
		yieldInterval = 5
	end
end

local function performWorkUntilDeadline()
	if scheduledHostCallback ~= nil then
		local currentTime = getCurrentTime()
		-- Yield after `yieldInterval` ms, regardless of where we are in the vsync
		-- cycle. This means there's always time remaining at the beginning of
		-- the message event.
		deadline = currentTime + yieldInterval
		local hasTimeRemaining = true

		local ok, result
		local function doWork()
			local hasMoreWork = (scheduledHostCallback :: any)(
				hasTimeRemaining,
				currentTime
			)
			if not hasMoreWork then
				isMessageLoopRunning = false
				scheduledHostCallback = nil
			else
				-- If there's more work, schedule the next message event at the end
				-- of the preceding one.

				-- ROBLOX deviation: Use task api instead of message channel;
				-- depending on whether or not we still have time to perform
				-- more work, either yield and defer till later this frame, or
				-- delay work till next frame

				-- ROBLOX FIXME: What's the proper combination of task.defer and
				-- task.delay that makes this optimal?
				task.delay(0, performWorkUntilDeadline)
			end
			return nil
		end
		if not _G.__YOLO__ then
			ok, result = xpcall(doWork, describeError)
		else
			result = doWork()
			ok = true
		end

		if not ok then
			-- If a scheduler task throws, exit the current coroutine so the
			-- error can be observed.
			task.delay(0, performWorkUntilDeadline)

			-- ROBLOX FIXME: the top-level Luau VM handler doesn't deal with
			-- non-string errors, so massage it until VM support lands
			error(errorToString(result :: any))
		end
	else
		isMessageLoopRunning = false
	end
end

-- ROBLOX deviation: wrap performWorkUntilDeadline for cleaner MicroProfiler attribution
local function wrapPerformWorkWithCoroutine(performWork)
	local co = coroutine.create(function()
		while true do
			-- We wrap `performWork` with a coroutine so that it can yield internally
			-- but not implicitly yield the entire `co` coroutine
			local wrapped = coroutine.wrap(performWork)
			local ok, result = pcall(wrapped)
			coroutine.yield(ok, result)
		end
	end)

	return function()
		local _, ok, result = coroutine.resume(co)
		-- Propogate errors from `co` so that it always stays alive
		if not ok then
			error(result)
		end
	end
end
performWorkUntilDeadline = wrapPerformWorkWithCoroutine(performWorkUntilDeadline)

local function requestHostCallback(callback)
	scheduledHostCallback = callback
	if not isMessageLoopRunning then
		isMessageLoopRunning = true

		task.delay(0, performWorkUntilDeadline)
	end
end

local function cancelHostCallback()
	scheduledHostCallback = nil
end

local function requestHostTimeout(callback, ms)
	taskTimeoutID = setTimeout(function()
		callback(getCurrentTime())
	end, ms)
end

local function cancelHostTimeout()
	clearTimeout(taskTimeoutID)
	taskTimeoutID = Object.None
end

return {
	requestHostCallback = requestHostCallback,
	cancelHostCallback = cancelHostCallback,
	requestHostTimeout = requestHostTimeout,
	cancelHostTimeout = cancelHostTimeout,
	shouldYieldToHost = shouldYieldToHost,
	requestPaint = requestPaint,
	getCurrentTime = getCurrentTime,
	forceFrameRate = forceFrameRate,
}

end,
["scheduler/forks/SchedulerHostConfig.mock"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/5474a83e258b497584bed9df95de1d554bc53f89/packages/scheduler/src/forks/SchedulerHostConfig.mock.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

local exports = {}

local currentTime: number = 0
local scheduledCallback: ((boolean, number) -> ()) | nil 
local scheduledTimeout: ((number) -> ()) | nil 
local timeoutTime: number = -1
local yieldedValues: { [number]: any } | nil 
local expectedNumberOfYields: number = -1
local didStop: boolean = false
local isFlushing: boolean = false
local needsPaint: boolean = false
local shouldYieldForPaint: boolean = false
local console = require(script.Parent.Parent.Parent:WaitForChild('shared')).console
local ConsolePatchingDev = require(script.Parent.Parent.Parent:WaitForChild('shared')).ConsolePatchingDev
local disabledLog = ConsolePatchingDev.disabledLog

exports.requestHostCallback = function(callback: (boolean) -> ())
	scheduledCallback = callback
end

exports.cancelHostCallback = function()
	scheduledCallback = nil
end

exports.requestHostTimeout = function(callback: (number) -> (), ms: number)
	scheduledTimeout = callback
	timeoutTime = currentTime + ms
end

exports.cancelHostTimeout = function()
	scheduledTimeout = nil
	timeoutTime = -1
end

exports.shouldYieldToHost = function(): boolean
	-- deviation: widening type to workaround Luau shortcomings
	-- https://jira.rbx.com/browse/CLI-35978
	local values: any = yieldedValues
	if
		(
			expectedNumberOfYields ~= -1			
and values ~= nil
			and #values >= expectedNumberOfYields
		) or (shouldYieldForPaint and needsPaint)
	then
		-- We yielded at least as many values as expected. Stop flushing.
		didStop = true
		return true
	end

	return false
end

exports.getCurrentTime = function(): number
	return currentTime
end

exports.forceFrameRate = function()
	-- No-op
end

exports.reset = function()
	if isFlushing then
		error("Cannot reset while already flushing work.")
	end

	currentTime = 0
	scheduledCallback = nil
	scheduledTimeout = nil
	timeoutTime = -1	
yieldedValues = nil
	expectedNumberOfYields = -1	
didStop = false
	isFlushing = false
	needsPaint = false
end

-- Should only be used via an assertion helper that inspects the yielded values.
exports.unstable_flushNumberOfYields = function(count: number)
	if isFlushing then
		error("Already flushing work.")
	end

	if scheduledCallback ~= nil then
		local cb = scheduledCallback
		expectedNumberOfYields = count
		isFlushing = true

		local ok, result = pcall(function()
			local hasMoreWork = true
			repeat
				hasMoreWork = cb(true, currentTime)
			until not hasMoreWork or didStop

			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		expectedNumberOfYields = -1		
didStop = false
		isFlushing = false

		if not ok then
			error(result)
		end
	end
end

exports.unstable_flushUntilNextPaint = function()
	if isFlushing then
		error("Already flushing work.")
	end

	if scheduledCallback ~= nil then
		local cb = scheduledCallback
		shouldYieldForPaint = true
		needsPaint = false
		isFlushing = true
		-- ROBLOX try
		local ok, result = pcall(function()
			local hasMoreWork = true
			repeat
				hasMoreWork = cb(true, currentTime)
			until not hasMoreWork or didStop

			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		-- ROBLOX finally
		shouldYieldForPaint = false
		didStop = false
		isFlushing = false

		if not ok then
			error(result)
		end
	end
end

exports.unstable_flushExpired = function()
	if isFlushing then
		error("Already flushing work.")
	end
	if scheduledCallback ~= nil then
		isFlushing = true
		local ok, result = pcall(function()
			-- deviation: widening type to workaround Luau shortcomings
			-- https://jira.rbx.com/browse/CLI-35978
			local callback: any = scheduledCallback
			local hasMoreWork = callback(false, currentTime)
			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		isFlushing = false

		if not ok then
			error(result)
		end
	end
end

exports.unstable_flushAllWithoutAsserting = function(): boolean
	-- Returns false if no work was flushed.
	if isFlushing then
		error("Already flushing work.")
	end
	if scheduledCallback ~= nil then
		local cb = scheduledCallback
		isFlushing = true
		local ok, result = pcall(function()
			local hasMoreWork = true
			repeat
				hasMoreWork = cb(true, currentTime)
			until not hasMoreWork

			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		isFlushing = false

		if not ok then
			error(result)
		end

		return true
	else
		return false
	end
end

exports.unstable_clearYields = function(): { [number]: any }
	if yieldedValues == nil then
		return {}
	end
	local values = yieldedValues
	yieldedValues = nil
	return values
end

exports.unstable_flushAll = function()
	if yieldedValues ~= nil then
		error(
[[Log is not empty. Assert on the log of yielded values before flushing additional work.]]		

)
	end
	exports.unstable_flushAllWithoutAsserting()
	if yieldedValues ~= nil then
		error(
[[While flushing work, something yielded a value. Use an assertion helper to assert on the log of yielded values, e.g. expect(Scheduler).toFlushAndYield([...])]]		


)
	end
end

exports.unstable_yieldValue = function(value: any)
	-- eslint-disable-next-line react-internal/no-production-logging
	if console.log == disabledLog then
		-- If console.log has been patched, we assume we're in render
		-- replaying and we ignore any values yielding in the second pass.
		return
	end
	if yieldedValues == nil then
		yieldedValues = { value }
	else
		-- deviation: widening type to workaround Luau shortcomings
		-- https://jira.rbx.com/browse/CLI-35978
		local values: any = yieldedValues
		table.insert(values, value)
	end
end

exports.unstable_advanceTime = function(ms: number)
	-- eslint-disable-next-line react-internal/no-production-logging
	if console.log == disabledLog then
		-- If console.log has been patched, we assume we're in render
		-- replaying and we ignore any time advancing in the second pass.
		return
	end
	currentTime += ms

	if scheduledTimeout ~= nil and timeoutTime <= currentTime then
		-- deviation: widening type to workaround Luau shortcomings
		-- https://jira.rbx.com/browse/CLI-35978
		local timeout: any = scheduledTimeout
		timeout(currentTime)
		timeoutTime = -1		
scheduledTimeout = nil
	end
end

exports.requestPaint = function()
	needsPaint = true
end

return exports

end,
["scheduler"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/efd8f6442d1aa7c4566fe812cba03e7e83aaccc3/packages/scheduler/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local initializeScheduler = require(script:WaitForChild('Scheduler'))

local function onlyInTestError(functionName: string)
	return function()
		error(functionName .. " is only available in tests, not in production")
	end
end

local Scheduler = initializeScheduler(nil --[[ no host config, use default ]])
local Tracing = require(script:WaitForChild('Tracing'))
local TracingSubscriptions = require(script:WaitForChild('TracingSubscriptions'))-- ROBLOX deviation export Tracing type from the package exports to avoid direct file access

export type Interaction = Tracing.Interaction

-- Enables `act` to use mock scheduling logic when running tests. Since there
-- are numerous testing scenarios in which we call `require` on the Roact
-- library _before_ we bootstrap tests, we expose an additional global to toggle
-- this explicilty
if _G.__ROACT_17_MOCK_SCHEDULER__ then
	return require(script:WaitForChild('unstable_mock'))
end

local exports = {
	unstable_ImmediatePriority = Scheduler.unstable_ImmediatePriority,
	unstable_UserBlockingPriority = Scheduler.unstable_UserBlockingPriority,
	unstable_NormalPriority = Scheduler.unstable_NormalPriority,
	unstable_IdlePriority = Scheduler.unstable_IdlePriority,
	unstable_LowPriority = Scheduler.unstable_LowPriority,
	unstable_runWithPriority = Scheduler.unstable_runWithPriority,
	unstable_next = Scheduler.unstable_next,
	unstable_scheduleCallback = Scheduler.unstable_scheduleCallback,
	unstable_cancelCallback = Scheduler.unstable_cancelCallback,
	unstable_wrapCallback = Scheduler.unstable_wrapCallback,
	unstable_getCurrentPriorityLevel = Scheduler.unstable_getCurrentPriorityLevel,
	unstable_shouldYield = Scheduler.unstable_shouldYield,
	unstable_requestPaint = Scheduler.unstable_requestPaint,
	unstable_continueExecution = Scheduler.unstable_continueExecution,
	unstable_pauseExecution = Scheduler.unstable_pauseExecution,
	unstable_getFirstCallbackNode = Scheduler.unstable_getFirstCallbackNode,
	unstable_now = Scheduler.unstable_now,
	unstable_forceFrameRate = Scheduler.unstable_forceFrameRate,
	unstable_flushAllWithoutAsserting = onlyInTestError(
		"unstable_flushAllWithoutAsserting"
	) :: any,
	unstable_flushAll = onlyInTestError("unstable_flushAll"),
	unstable_flushNumberOfYields = onlyInTestError("unstable_flushNumberOfYields"),
	unstable_clearYields = onlyInTestError("unstable_clearYields") :: any,
	unstable_flushUntilNextPaint = onlyInTestError("unstable_clearYields"),
	unstable_advanceTime = onlyInTestError("unstable_advanceTime"),
	unstable_flushExpired = onlyInTestError("unstable_flushExpired"),
	unstable_yieldValue = onlyInTestError("unstable_yieldValue"),

	tracing = {
		unstable_wrap = onlyInTestError("unstable_wrap"),
		__interactionsRef = {},
		__subscriberRef = {},
	},
}

-- ROBLOX FIXME Luau: need to fix CLI-56768 to remove any cast
for k, v in Tracing :: any do
	exports.tracing[k] = v
end
for k, v in TracingSubscriptions :: any do
	exports.tracing[k] = v
end

return exports

end,
["scheduler/Scheduler"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/Scheduler.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
]]

-- ROBLOX deviation: return an initializer function instead of the module itself
-- for easier dependency injection with unstable_mock
return function(hostConfig)
	local describeError = require(script.Parent.Parent:WaitForChild('shared')).describeError

	local SchedulerFeatureFlags = require(script.Parent:WaitForChild('SchedulerFeatureFlags'))	
local enableSchedulerDebugging = SchedulerFeatureFlags.enableSchedulerDebugging
	local enableProfiling = SchedulerFeatureFlags.enableProfiling

	local SchedulerHostConfig = hostConfig or require(script.Parent:WaitForChild('SchedulerHostConfig'))	
local requestHostCallback = SchedulerHostConfig.requestHostCallback
	local requestHostTimeout = SchedulerHostConfig.requestHostTimeout
	local cancelHostTimeout = SchedulerHostConfig.cancelHostTimeout
	local shouldYieldToHost = SchedulerHostConfig.shouldYieldToHost
	local getCurrentTime = SchedulerHostConfig.getCurrentTime
	local forceFrameRate = SchedulerHostConfig.forceFrameRate
	local requestPaint = SchedulerHostConfig.requestPaint

	-- ROBLOX deviation? inline the MinHeap to see if the module-level visibility lets Luau optimize better
	-- local SchedulerMinHeap = require("./SchedulerMinHeap")
	-- local push = SchedulerMinHeap.push
	-- local peek = SchedulerMinHeap.peek
	-- local pop = SchedulerMinHeap.pop
	type Heap = { [number]: Node? }
	type Node = {
		id: number,
		sortIndex: number	
}

	-- ROBLOX deviation: This file contains several workarounds for Luau analysis issues by using the `::` operator
	local compare, siftUp, siftDown

	local push = function(heap: Heap, node: Node): ()
		local index = #heap + 1
		heap[index] = node

		siftUp(heap, node, index)
	end

	local peek = function(heap: Heap): Node?
		return heap[1]
	end

	local pop = function(heap: Heap): Node?
		local first = heap[1]
		if first ~= nil then
			local last = heap[#heap]
			heap[#heap] = nil

			if last :: Node ~= first :: Node then
				heap[1] = last
				siftDown(heap, last :: Node, 1)
			end
			return first
		else
			return nil
		end
	end

	siftUp = function(heap: Heap, node: Node, index: number): ()
		while true do
			local parentIndex = math.floor(index / 2)
			local parent = heap[parentIndex]
			if parent ~= nil and compare(parent :: Node, node :: Node) > 0 then
				-- The parent is larger. Swap positions.
				heap[parentIndex] = node
				heap[index] = parent
				index = parentIndex
			else
				-- The parent is smaller. Exit.
				return
			end
		end
	end

	siftDown = function(heap: Heap, node: Node, index: number): ()
		local length = #heap
		while index < length do
			local leftIndex = index * 2
			local left = heap[leftIndex]
			local rightIndex = leftIndex + 1
			local right = heap[rightIndex]

			-- If the left or right node is smaller, swap with the smaller of those.
			if left ~= nil and compare(left :: Node, node) < 0 then
				if right ~= nil and compare(right :: Node, left :: Node) < 0 then
					heap[index] = right
					heap[rightIndex] = node
					index = rightIndex
				else
					heap[index] = left
					heap[leftIndex] = node
					index = leftIndex
				end
			elseif right ~= nil and compare(right :: Node, node :: Node) < 0 then
				heap[index] = right
				heap[rightIndex] = node
				index = rightIndex
			else
				-- Neither child is smaller. Exit.
				return
			end
		end
	end

	compare = function(a: Node, b: Node): number
		-- Compare sort index first, then task id.
		local diff = a.sortIndex - b.sortIndex

		if diff == 0 then
			return a.id - b.id
		end

		return diff
	end

	-- TODO: Use symbols?
	local SchedulerPriorities = require(script.Parent:WaitForChild('SchedulerPriorities'))	
local ImmediatePriority = SchedulerPriorities.ImmediatePriority
	local UserBlockingPriority = SchedulerPriorities.UserBlockingPriority
	local NormalPriority = SchedulerPriorities.NormalPriority
	local LowPriority = SchedulerPriorities.LowPriority
	local IdlePriority = SchedulerPriorities.IdlePriority

	local SchedulerProfiling = require(script.Parent:WaitForChild('SchedulerProfiling'))	
local markTaskRun = SchedulerProfiling.markTaskRun
	local markTaskYield = SchedulerProfiling.markTaskYield
	local markTaskCompleted = SchedulerProfiling.markTaskCompleted
	local markTaskCanceled = SchedulerProfiling.markTaskCanceled
	local markTaskErrored = SchedulerProfiling.markTaskErrored
	local markSchedulerSuspended = SchedulerProfiling.markSchedulerSuspended
	local markSchedulerUnsuspended = SchedulerProfiling.markSchedulerUnsuspended
	local markTaskStart = SchedulerProfiling.markTaskStart
	local stopLoggingProfilingEvents = SchedulerProfiling.stopLoggingProfilingEvents
	local startLoggingProfilingEvents = SchedulerProfiling.startLoggingProfilingEvents

	-- Max 31 bit integer. The max integer size in V8 for 32-bit systems.
	-- Math.pow(2, 30) - 1
	-- 0b111111111111111111111111111111
	local maxSigned31BitInt = 1073741823

	-- Times out immediately
	local IMMEDIATE_PRIORITY_TIMEOUT = -1	-- Eventually times out
	
local USER_BLOCKING_PRIORITY_TIMEOUT = 250
	local NORMAL_PRIORITY_TIMEOUT = 5000
	local LOW_PRIORITY_TIMEOUT = 10000
	-- Never times out
	local IDLE_PRIORITY_TIMEOUT = maxSigned31BitInt

	-- Tasks are stored on a min heap
	local taskQueue = {}
	local timerQueue = {}

	-- Incrementing id counter. Used to maintain insertion order.
	local taskIdCounter = 1

	-- Pausing the scheduler is useful for debugging.
	local isSchedulerPaused = false

	local currentTask 	
local currentPriorityLevel = NormalPriority

	-- This is set while performing work, to prevent re-entrancy.
	local isPerformingWork = false

	local isHostCallbackScheduled = false
	local isHostTimeoutScheduled = false

	-- deviation: Preemptively declare these functions so that Lua understands them
	local handleTimeout, flushWork, workLoop

	local function advanceTimers(currentTime)
		-- Check for tasks that are no longer delayed and add them to the queue.
		local timer = peek(timerQueue)

		while timer ~= nil do
			if timer.callback == nil then
				-- Timer was cancelled, remove from queue
				pop(timerQueue)
			elseif timer.startTime <= currentTime then
				-- Timer fired. Transfer to the task queue.
				pop(timerQueue)
				timer.sortIndex = timer.expirationTime
				push(taskQueue, timer)
				if enableProfiling then
					markTaskStart(timer, currentTime)
					timer.isQueued = true
				end
			else
				-- Remaining timers are pending.
				return
			end

			timer = peek(timerQueue)
		end
	end

	handleTimeout = function(currentTime)
		isHostTimeoutScheduled = false
		advanceTimers(currentTime)

		if not isHostCallbackScheduled then
			if peek(taskQueue) ~= nil then
				isHostCallbackScheduled = true
				requestHostCallback(flushWork)
			else
				local firstTimer = peek(timerQueue)
				if firstTimer ~= nil then
					requestHostTimeout(handleTimeout, firstTimer.startTime - currentTime)
				end
			end
		end
	end

	flushWork = function(hasTimeRemaining, initialTime)
		if enableProfiling then
			markSchedulerUnsuspended(initialTime)
		end

		-- We'll need a host callback the next time work is scheduled.
		isHostCallbackScheduled = false
		if isHostTimeoutScheduled then
			-- We scheduled a timeout but it's no longer needed. Cancel it.
			isHostTimeoutScheduled = false
			cancelHostTimeout()
		end

		isPerformingWork = true
		local previousPriorityLevel = currentPriorityLevel

		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not _G.__YOLO__ then
			-- ROBLOX performance: don't nest try/catch here, Lua can do better, and it eliminated an anon function creation
			if enableProfiling then
				ok, result =
					xpcall(workLoop, describeError, hasTimeRemaining, initialTime)

				if not ok then
					if currentTask ~= nil then
						local currentTime = getCurrentTime()
						markTaskErrored(currentTask, currentTime)
						currentTask.isQueued = false
					end
				end
			else
				-- No catch in prod code path.
				ok = true
				result = workLoop(hasTimeRemaining, initialTime)
			end
		else
			ok = true
			result = workLoop(hasTimeRemaining, initialTime)
		end

		-- ROBLOX: finally
		currentTask = nil
		currentPriorityLevel = previousPriorityLevel
		isPerformingWork = false
		if enableProfiling then
			local currentTime = getCurrentTime()
			markSchedulerSuspended(currentTime)
		end

		if not ok then
			error(result)
		end

		return result
	end

	workLoop = function(hasTimeRemaining, initialTime)
		local currentTime = initialTime
		advanceTimers(currentTime)
		currentTask = peek(taskQueue)
		while
			currentTask ~= nil and not (enableSchedulerDebugging and isSchedulerPaused)
		do
			if
				currentTask.expirationTime > currentTime
				and (not hasTimeRemaining or shouldYieldToHost())
			then
				-- This currentTask hasn't expired, and we've reached the deadline.
				break
			end

			local callback = currentTask.callback
			if typeof(callback) == "function" then
				currentTask.callback = nil
				currentPriorityLevel = currentTask.priorityLevel
				local didUserCallbackTimeout = currentTask.expirationTime <= currentTime
				markTaskRun(currentTask, currentTime)
				local continuationCallback = callback(didUserCallbackTimeout)
				currentTime = getCurrentTime()
				if typeof(continuationCallback) == "function" then
					currentTask.callback = continuationCallback
					markTaskYield(currentTask, currentTime)
				else
					if enableProfiling then
						markTaskCompleted(currentTask, currentTime)
						currentTask.isQueued = false
					end

					if currentTask == peek(taskQueue) then
						pop(taskQueue)
					end
				end
				advanceTimers(currentTime)
			else
				pop(taskQueue)
			end

			currentTask = peek(taskQueue)
		end

		-- Return whether there's additional work
		if currentTask ~= nil then
			return true
		else
			local firstTimer = peek(timerQueue)
			if firstTimer ~= nil then
				requestHostTimeout(handleTimeout, firstTimer.startTime - currentTime)
			end

			return false
		end
	end

	local function unstable_runWithPriority(priorityLevel, eventHandler)
		if
			priorityLevel == ImmediatePriority
			or priorityLevel == UserBlockingPriority
			or priorityLevel == NormalPriority
			or priorityLevel == LowPriority
			or priorityLevel == IdlePriority
		then
			-- Leave priority alone if assigned
		else
			priorityLevel = NormalPriority
		end

		local previousPriorityLevel = currentPriorityLevel
		currentPriorityLevel = priorityLevel

		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not _G.__YOLO__ then
			ok, result = xpcall(eventHandler, describeError)
		else
			ok = true
			result = eventHandler()
		end

		-- ROBLOX: finally
		currentPriorityLevel = previousPriorityLevel

		if not ok then
			error(result)
		end

		return result
	end

	local function unstable_next(eventHandler)
		local priorityLevel
		if
			currentPriorityLevel == ImmediatePriority
			or currentPriorityLevel == UserBlockingPriority
			or currentPriorityLevel == NormalPriority
		then
			-- Shift down to normal priority
			priorityLevel = NormalPriority
		else
			-- Anything lower than normal priority should remain at the current level.
			priorityLevel = currentPriorityLevel
		end

		local previousPriorityLevel = currentPriorityLevel
		currentPriorityLevel = priorityLevel

		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not _G.__YOLO__ then
			ok, result = xpcall(eventHandler, describeError)
		else
			ok = true
			result = eventHandler()
		end

		-- ROBLOX: finally
		currentPriorityLevel = previousPriorityLevel

		if not ok then
			error(result)
		end

		return result
	end

	local function unstable_wrapCallback(callback)
		local parentPriorityLevel = currentPriorityLevel

		return function(...)
			-- This is a fork of runWithPriority, inlined for performance.
			local previousPriorityLevel = currentPriorityLevel
			currentPriorityLevel = parentPriorityLevel

			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not _G.__YOLO__ then
				ok, result = xpcall(callback, describeError, ...)
			else
				ok = true
				result = callback(...)
			end

			-- ROBLOX: finally
			currentPriorityLevel = previousPriorityLevel

			if not ok then
				error(result)
			end

			return result
		end
	end

	local function unstable_scheduleCallback(priorityLevel, callback, options)
		local currentTime = getCurrentTime()

		local startTime

		if typeof(options) == "table" then
			local delay_ = options.delay
			if typeof(delay_) == "number" and delay_ > 0 then
				startTime = currentTime + delay_
			else
				startTime = currentTime
			end
		else
			startTime = currentTime
		end

		local timeout
		if priorityLevel == ImmediatePriority then
			timeout = IMMEDIATE_PRIORITY_TIMEOUT
		elseif priorityLevel == UserBlockingPriority then
			timeout = USER_BLOCKING_PRIORITY_TIMEOUT
		elseif priorityLevel == IdlePriority then
			timeout = IDLE_PRIORITY_TIMEOUT
		elseif priorityLevel == LowPriority then
			timeout = LOW_PRIORITY_TIMEOUT
		else
			timeout = NORMAL_PRIORITY_TIMEOUT
		end

		local expirationTime = startTime + timeout

		local newTask = {
			id = taskIdCounter,
			callback = callback,
			priorityLevel = priorityLevel,
			startTime = startTime,
			expirationTime = expirationTime,
			sortIndex = -1,
		}
		taskIdCounter += 1

		if enableProfiling then
			newTask.isQueued = false
		end

		if startTime > currentTime then
			-- This is a delayed task.
			newTask.sortIndex = startTime
			push(timerQueue, newTask)
			-- TODO(align): VALIDATE conversion from `peek(taskQueue) === null && newTask === peek(timerQueue)`
			if #taskQueue == 0 and newTask == peek(timerQueue) then
				-- All tasks are delayed, and this is the task with the earliest delay.
				if isHostTimeoutScheduled then
					-- Cancel an existing timeout.
					cancelHostTimeout()
				else
					isHostTimeoutScheduled = true
				end
				-- Schedule a timeout.
				requestHostTimeout(handleTimeout, startTime - currentTime)
			end
		else
			newTask.sortIndex = expirationTime
			push(taskQueue, newTask)
			if enableProfiling then
				markTaskStart(newTask, currentTime)
				newTask.isQueued = true
			end

			-- Schedule a host callback, if needed. If we're already performing work,
			-- wait until the next time we yield.
			if not isHostCallbackScheduled and not isPerformingWork then
				isHostCallbackScheduled = true
				requestHostCallback(flushWork)
			end
		end

		return newTask
	end

	local function unstable_pauseExecution()
		isSchedulerPaused = true
	end

	local function unstable_continueExecution()
		isSchedulerPaused = false
		if not isHostCallbackScheduled and not isPerformingWork then
			isHostCallbackScheduled = true
			requestHostCallback(flushWork)
		end
	end

	local function unstable_getFirstCallbackNode()
		return peek(taskQueue)
	end

	local function unstable_cancelCallback(task)
		if enableProfiling then
			if task.isQueued then
				local currentTime = getCurrentTime()
				markTaskCanceled(task, currentTime)
				task.isQueued = false
			end
		end

		-- Null out the callback to indicate the task has been canceled. (Can't
		-- remove from the queue because you can't remove arbitrary nodes from an
		-- array based heap, only the first one.)
		task.callback = nil
	end

	local function unstable_getCurrentPriorityLevel()
		return currentPriorityLevel
	end

	local unstable_requestPaint = requestPaint

	return {
		unstable_ImmediatePriority = ImmediatePriority,
		unstable_UserBlockingPriority = UserBlockingPriority,
		unstable_NormalPriority = NormalPriority,
		unstable_IdlePriority = IdlePriority,
		unstable_LowPriority = LowPriority,
		unstable_runWithPriority = unstable_runWithPriority,
		unstable_next = unstable_next,
		unstable_scheduleCallback = unstable_scheduleCallback,
		unstable_cancelCallback = unstable_cancelCallback,
		unstable_wrapCallback = unstable_wrapCallback,
		unstable_getCurrentPriorityLevel = unstable_getCurrentPriorityLevel,
		unstable_shouldYield = shouldYieldToHost,
		unstable_requestPaint = unstable_requestPaint,
		unstable_continueExecution = unstable_continueExecution,
		unstable_pauseExecution = unstable_pauseExecution,
		unstable_getFirstCallbackNode = unstable_getFirstCallbackNode,
		unstable_now = getCurrentTime,
		unstable_forceFrameRate = forceFrameRate,
		-- ROBLOX TODO: use if-expressions when all clients are on 503+
		unstable_Profiling = (function()
			if enableProfiling then
				return {
					startLoggingProfilingEvents = startLoggingProfilingEvents,
					stopLoggingProfilingEvents = stopLoggingProfilingEvents,
				}
			end
			return nil
		end)(),
	}
end

end,
["scheduler/SchedulerFeatureFlags"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/SchedulerFeatureFlags.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
]]

return {
	enableSchedulerDebugging = false,
	enableIsInputPending = false,
	enableProfiling = _G.__PROFILE__,
}

end,
["scheduler/SchedulerHostConfig"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/00748c53e183952696157088a858352cc77b0010/packages/scheduler/src/SchedulerHostConfig.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

-- deviation: In React, this module throws an error and is expected to be
-- replaced via a bundler. In our case, we mock it explicitly when we need to
-- mock it, and return the "default" here
return require(script.Parent:WaitForChild('forks'):WaitForChild('SchedulerHostConfig.default'))
end,
["scheduler/SchedulerMinHeap"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/e706721490e50d0bd6af2cd933dbf857fd8b61ed/packages/scheduler/src/SchedulerMinHeap.js
--!strict
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

type Heap = { [number]: Node? }
type Node = {
	id: number,
	sortIndex: number
}

local exports = {}
-- ROBLOX deviation: This file contains several workarounds for Luau analysis issues by using the `::` operator
local compare, siftUp, siftDown

exports.push = function(heap: Heap, node: Node): ()
	local index = #heap + 1
	heap[index] = node

	siftUp(heap, node, index)
end

exports.peek = function(heap: Heap): Node?
	return heap[1]
end

exports.pop = function(heap: Heap): Node?
	local first = heap[1]
	if first ~= nil then
		local last = heap[#heap]
		heap[#heap] = nil

		if last :: Node ~= first :: Node then
			heap[1] = last
			siftDown(heap, last :: Node, 1)
		end
		return first
	else
		return nil
	end
end

siftUp = function(heap: Heap, node: Node, index: number): ()
	while true do
		local parentIndex = math.floor(index / 2)
		local parent = heap[parentIndex]
		if parent ~= nil and compare(parent :: Node, node :: Node) > 0 then
			-- The parent is larger. Swap positions.
			heap[parentIndex] = node
			heap[index] = parent
			index = parentIndex
		else
			-- The parent is smaller. Exit.
			return
		end
	end
end

siftDown = function(heap: Heap, node: Node, index: number): ()
	local length = #heap
	while index < length do
		local leftIndex = index * 2
		local left = heap[leftIndex]
		local rightIndex = leftIndex + 1
		local right = heap[rightIndex]

		-- If the left or right node is smaller, swap with the smaller of those.
		if left ~= nil and compare(left :: Node, node) < 0 then
			if right ~= nil and compare(right :: Node, left :: Node) < 0 then
				heap[index] = right
				heap[rightIndex] = node
				index = rightIndex
			else
				heap[index] = left
				heap[leftIndex] = node
				index = leftIndex
			end
		elseif right ~= nil and compare(right :: Node, node :: Node) < 0 then
			heap[index] = right
			heap[rightIndex] = node
			index = rightIndex
		else
			-- Neither child is smaller. Exit.
			return
		end
	end
end

compare = function(a: Node, b: Node): number
	-- Compare sort index first, then task id.
	local diff = a.sortIndex - b.sortIndex

	if diff == 0 then
		return a.id - b.id
	end

	return diff
end

return exports

end,
["scheduler/SchedulerPriorities"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/00748c53e183952696157088a858352cc77b0010/packages/scheduler/src/SchedulerHostConfig.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

export type PriorityLevel = number

-- TODO: Use symbols?
return {
	NoPriority = 0,
	ImmediatePriority = 1,
	UserBlockingPriority = 2,
	NormalPriority = 3,
	LowPriority = 4,
	IdlePriority = 5,
}

end,
["scheduler/SchedulerProfiling"]=function()
--!strict
-- ROBLOX upstream https://github.com/facebook/react/blob/8af27aeedbc6b00bc2ef49729fc84f116c70a27c/packages/scheduler/src/SchedulerProfiling.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
]]
-- ROBLOX NOTE: this file is synced against a post-17.0.1 version that doesn't use SharedArrayBuffer
-- ROBLOX: use patched console from shared
local console = require(script.Parent.Parent:WaitForChild('shared')).console
local exports = {}

local SchedulerPriorities = require(script.Parent:WaitForChild('SchedulerPriorities'))
type PriorityLevel = SchedulerPriorities.PriorityLevel

local ScheduleFeatureFlags = require(script.Parent:WaitForChild('SchedulerFeatureFlags'))
local enableProfiling = ScheduleFeatureFlags.enableProfiling

local runIdCounter: number = 0
local mainThreadIdCounter: number = 0

-- Bytes per element is 4
local INITIAL_EVENT_LOG_SIZE = 131072
local MAX_EVENT_LOG_SIZE = 524288 -- Equivalent to 2 megabytes

-- Strictly speaking, only the first element of an EventLog can be a reference to another EventLog.
type EventLog = { EventLog | { number } }

local eventLogSize = 0
local eventLogBuffer 
local eventLog: EventLog? 
local eventLogIndex = 1

local TaskStartEvent = 1
local TaskCompleteEvent = 2
local TaskErrorEvent = 3
local TaskCancelEvent = 4
local TaskRunEvent = 5
local TaskYieldEvent = 6
local SchedulerSuspendEvent = 7
local SchedulerResumeEvent = 8

local function logEvent(entries)
	if eventLog ~= nil then
		-- ROBLOX deviation: upstream uses a packed array for performance. we do something simpler for now
		eventLogIndex += #entries
		if eventLogIndex + 1 > eventLogSize then
			eventLogSize *= 2
			if eventLogSize > MAX_EVENT_LOG_SIZE then
				-- Using console['error'] to evade Babel and ESLint
				console["error"](
[[Scheduler Profiling: Event log exceeded maximum size. Don't forget to call `stopLoggingProfilingEvents()`.]]				

)
				exports.stopLoggingProfilingEvents()
				return
			end
			local newEventLog = {}
			table.insert(newEventLog, eventLog)
			eventLogBuffer = newEventLog
			eventLog = newEventLog
		end
		table.insert(eventLog, entries)
	end
end

exports.startLoggingProfilingEvents = function()
	eventLogSize = INITIAL_EVENT_LOG_SIZE
	eventLogBuffer = {}
	eventLog = eventLogBuffer
	eventLogIndex = 1
end

exports.stopLoggingProfilingEvents = function()
	local buffer = eventLogBuffer
	eventLogSize = 0
	-- ROBLOX FIXME Luau: needs local inference? Type 'nil' could not be converted into '{|  |}'
	eventLogBuffer = nil :: any
	eventLog = nil :: any
	eventLogIndex = 1
	return buffer
end

exports.markTaskStart = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			-- performance.now returns a float, representing milliseconds. When the
			-- event is logged, it's coerced to an int. Convert to microseconds to
			-- maintain extra degrees of precision.
			logEvent({ TaskStartEvent, ms * 1000, task.id, task.priorityLevel })
		end
	end
end

exports.markTaskCompleted = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			-- performance.now returns a float, representing milliseconds. When the
			-- event is logged, it's coerced to an int. Convert to microseconds to
			-- maintain extra degrees of precision.
			logEvent({ TaskCompleteEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskCanceled = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ TaskCancelEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskErrored = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ TaskErrorEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskRun = function(task, ms: number)
	if enableProfiling then
		runIdCounter += 1

		if eventLog ~= nil then
			logEvent({ TaskRunEvent, ms * 1000, task.id, runIdCounter })
		end
	end
end

exports.markTaskYield = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ TaskYieldEvent, ms * 1000, task.id, runIdCounter })
		end
	end
end

exports.markSchedulerSuspended = function(ms: number)
	if enableProfiling then
		mainThreadIdCounter += 1

		if eventLog ~= nil then
			logEvent({ SchedulerSuspendEvent, ms * 1000, mainThreadIdCounter })
		end
	end
end

exports.markSchedulerUnsuspended = function(ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ SchedulerResumeEvent, ms * 1000, mainThreadIdCounter })
		end
	end
end

return exports

end,
["scheduler/Tracing"]=function()
--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/Tracing.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

type Function = (any) -> any
local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
type Set<T> = LuauPolyfill.Set<T>
local Set = LuauPolyfill.Set
local exports = {}

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing

export type Interaction = {
	__count: number,
	id: number,
	name: string,
	timestamp: number
}

export type Subscriber = {
	-- A new interaction has been created via the trace() method.
	onInteractionTraced: (Interaction) -> (),

	-- All scheduled async work for an interaction has finished.
	onInteractionScheduledWorkCompleted: (Interaction) -> (),

	-- New async work has been scheduled for a set of interactions.
	-- When this work is later run, onWorkStarted/onWorkStopped will be called.
	-- A batch of async/yieldy work may be scheduled multiple times before completing.
	-- In that case, onWorkScheduled may be called more than once before onWorkStopped.
	-- Work is scheduled by a "thread" which is identified by a unique ID.
	onWorkScheduled: (Set<Interaction>, number) -> (),

	-- A batch of scheduled work has been canceled.
	-- Work is done by a "thread" which is identified by a unique ID.
	onWorkCanceled: (Set<Interaction>, number) -> (),

	-- A batch of work has started for a set of interactions.
	-- When this work is complete, onWorkStopped will be called.
	-- Work is not always completed synchronously yielding may occur in between.
	-- A batch of async/yieldy work may also be re-started before completing.
	-- In that case, onWorkStarted may be called more than once before onWorkStopped.
	-- Work is done by a "thread" which is identified by a unique ID.
	onWorkStarted: (Set<Interaction>, number) -> (),

	-- A batch of work has completed for a set of interactions.
	-- Work is done by a "thread" which is identified by a unique ID.
	onWorkStopped: (Set<Interaction>, number) -> ()	-- ...

}

export type InteractionsRef = { current: Set<Interaction> }

export type SubscriberRef = { current: Subscriber | nil }

local DEFAULT_THREAD_ID = 0

-- Counters used to generate unique IDs.
local interactionIDCounter: number = 0
local threadIDCounter: number = 0

-- Set of currently traced interactions.
-- Interactions "stack"–
-- Meaning that newly traced interactions are appended to the previously active set.
-- When an interaction goes out of scope, the previous set (if any) is restored.
local interactionsRef: InteractionsRef

-- Listener(s) to notify when interactions begin and end.
local subscriberRef: SubscriberRef

if enableSchedulerTracing then
	interactionsRef = {
		current = Set.new(),
	}
	subscriberRef = {
		current = nil,
	}
end

exports.__interactionsRef = interactionsRef
exports.__subscriberRef = subscriberRef

exports.unstable_clear = function(callback: Function)
	if not enableSchedulerTracing then
		return callback()
	end

	local prevInteractions = interactionsRef.current
	interactionsRef.current = Set.new()

	-- ROBLOX try
	local ok, result = pcall(callback)
	-- ROBLOX finally
	interactionsRef.current = prevInteractions

	if not ok then
		error(result)
	end

	return result
end

exports.unstable_getCurrent = function(): Set<Interaction> | nil
	if not enableSchedulerTracing then
		return nil
	else
		return interactionsRef.current
	end
end

exports.unstable_getThreadID = function(): number
	threadIDCounter += 1
	return threadIDCounter
end

exports.unstable_trace =
	function(name: string, timestamp: number, callback: Function, threadID_: number?): any
		-- ROBLOX: default argument value
		local threadID = if threadID_ ~= nil then threadID_ else DEFAULT_THREAD_ID

		if not enableSchedulerTracing then
			return callback()
		end

		local interaction: Interaction = {
			__count = 1,
			id = interactionIDCounter,
			name = name,
			timestamp = timestamp,
		}
		interactionIDCounter += 1

		local prevInteractions = interactionsRef.current

		-- Traced interactions should stack/accumulate.
		-- To do that, clone the current interactions.
		-- The previous set will be restored upon completion.
		local interactions = Set.new(prevInteractions)
		interactions:add(interaction)
		interactionsRef.current = interactions

		local subscriber = subscriberRef.current
		local returnValue

		-- ROBLOX try
		local ok, result = pcall(function()
			if subscriber ~= nil then
				subscriber.onInteractionTraced(interaction)
			end
		end)
		-- ROBLOX finally
		-- ROBLOX try 2
		local ok2, result2 = pcall(function()
			if subscriber ~= nil then
				subscriber.onWorkStarted(interactions, threadID)
			end
		end)

		-- ROBLOX finally 2
		-- ROBLOX try 3
		local ok3, result3 = pcall(function()
			returnValue = callback()
		end)
		-- ROBLOX finally 3
		interactionsRef.current = prevInteractions
		-- ROBLOX try 4
		local ok4, result4 = pcall(function()
			if subscriber ~= nil then
				subscriber.onWorkStopped(interactions, threadID)
			end
		end)
		-- ROBLOX finally 4
		interaction.__count -= 1

		-- If no async work was scheduled for this interaction,
		-- Notify subscribers that it's completed.
		if subscriber ~= nil and interaction.__count == 0 then
			subscriber.onInteractionScheduledWorkCompleted(interaction)
		end

		if not ok4 then
			error(result4)
		end

		if not ok3 then
			error(result3)
		end

		if not ok2 then
			error(result2)
		end

		if not ok then
			error(result)
		end

		return returnValue
	end

exports.unstable_wrap = function(
	callback: Function,
	threadID: number
): any -- ROLBOX deviation: any, since __call doesn't map to Function
	-- ROBLOX: default argument value
	if threadID == nil then
		threadID = DEFAULT_THREAD_ID
	end

	if not enableSchedulerTracing then
		return callback
	end

	local wrappedInteractions = interactionsRef.current

	local subscriber = subscriberRef.current
	if subscriber ~= nil then
		subscriber.onWorkScheduled(wrappedInteractions, threadID)
	end

	-- Update the pending async work count for the current interactions.
	-- Update after calling subscribers in case of error.
	for _, interaction in wrappedInteractions do
		interaction.__count += 1
	end

	local hasRun = false

	local function _wrapped(self, ...)
		local prevInteractions = interactionsRef.current
		interactionsRef.current = wrappedInteractions

		subscriber = subscriberRef.current

		-- ROBLOX try
		local ok, result = pcall(function(...)
			local returnValue

			-- ROBLOX try 2
			local ok2, result2 = pcall(function()
				if subscriber ~= nil then
					subscriber.onWorkStarted(wrappedInteractions, threadID)
				end
			end)
			-- ROBLOX finally 2
			-- ROBLOX try 3
			local ok3, result3 = pcall(function(...)
				returnValue = callback(...)
			end, ...)
			-- ROBLOX finally 3
			interactionsRef.current = prevInteractions

			if subscriber ~= nil then
				subscriber.onWorkStopped(wrappedInteractions, threadID)
			end

			if not ok3 then
				error(result3)
			end

			if not ok2 then
				error(result2)
			end

			return returnValue
		end, ...)

		-- ROBLOX finally {
		if not hasRun then
			-- We only expect a wrapped function to be executed once,
			-- But in the event that it's executed more than once–
			-- Only decrement the outstanding interaction counts once.
			hasRun = true

			-- Update pending async counts for all wrapped interactions.
			-- If this was the last scheduled async work for any of them,
			-- Mark them as completed.
			for _, interaction in wrappedInteractions do
				interaction.__count -= 1

				if subscriber ~= nil and interaction.__count == 0 then
					subscriber.onInteractionScheduledWorkCompleted(interaction)
				end
			end
		end

		if not ok then
			error(result)
		end

		return result
	end

	local _cancel = function()
		subscriber = subscriberRef.current

		local ok, result = pcall(function()
			if subscriber ~= nil then
				subscriber.onWorkCanceled(wrappedInteractions, threadID)
			end
		end)
		--ROBLOX finally {
		-- Update pending async counts for all wrapped interactions.
		-- If this was the last scheduled async work for any of them,
		-- Mark them as completed.
		for _, interaction in wrappedInteractions do
			interaction.__count -= 1

			if subscriber ~= nil and interaction.__count == 0 then
				subscriber.onInteractionScheduledWorkCompleted(interaction)
			end
		end

		if not ok then
			error(result)
		end
	end

	local wrapped = {}
	setmetatable(wrapped, {
		__call = _wrapped,
	})
	wrapped.cancel = _cancel

	return wrapped
end

return exports

end,
["scheduler/TracingSubscriptions"]=function()
-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/TracingSubscriptions.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */
type Set<T> = { [T]: boolean? }
type Array<T> = { [number]: T }
local exports = {}
local Object = require(script.Parent.Parent:WaitForChild('luau-polyfill')).Object

local Tracing = require(script.Parent:WaitForChild('Tracing'))
type Interaction = Tracing.Interaction
type Subscriber = Tracing.Subscriber

local ReactFeatureFlags = require(script.Parent.Parent:WaitForChild('shared')).ReactFeatureFlags

local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local __subscriberRef = Tracing.__subscriberRef

local subscribers: Set<Subscriber> = {}
if enableSchedulerTracing then
	subscribers = {}
end

exports.unstable_subscribe = function(subscriber: Subscriber): ()
	if enableSchedulerTracing then
		subscribers[subscriber] = true

		if #Object.keys(subscribers) == 1 then
			__subscriberRef.current = {
				onInteractionScheduledWorkCompleted = onInteractionScheduledWorkCompleted,
				onInteractionTraced = onInteractionTraced,
				onWorkCanceled = onWorkCanceled,
				onWorkScheduled = onWorkScheduled,
				onWorkStarted = onWorkStarted,
				onWorkStopped = onWorkStopped,
			}
		end
	end
end

exports.unstable_unsubscribe = function(subscriber: Subscriber): ()
	if enableSchedulerTracing then
		subscribers[subscriber] = nil

		if #Object.keys(subscribers) == 0 then
			__subscriberRef.current = nil
		end
	end
end

function onInteractionTraced(interaction: Interaction): ()
	local didCatchError = false
	local caughtError 
	
for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onInteractionTraced, interaction)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onInteractionScheduledWorkCompleted(interaction: Interaction): ()
	local didCatchError = false
	local caughtError 
	
for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result =
			pcall(subscriber.onInteractionScheduledWorkCompleted, interaction)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkScheduled(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError 
	
for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkScheduled, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkStarted(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError 
	
for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkStarted, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkStopped(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError 
	
for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkStopped, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkCanceled(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError 
	
for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkCanceled, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

return exports

end,
["scheduler/unstable_mock"]=function()
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
*]]
local Tracing = require(script.Parent:WaitForChild('Tracing'))
local TracingSubscriptions = require(script.Parent:WaitForChild('TracingSubscriptions'))-- ROBLOX deviation: export Tracing type from the package exports to avoid direct file access

export type Interaction = Tracing.Interaction

local initializeScheduler = require(script.Parent:WaitForChild('Scheduler'))
local HostConfig = require(script.Parent:WaitForChild('forks'):WaitForChild('SchedulerHostConfig.mock'))

local Scheduler = initializeScheduler(HostConfig)

local exports = {}
exports.tracing = {}
-- ROBLOX FIXME Luau: need to fix CLI-56768 to remove any casts
for key, value in Scheduler :: any do
	exports[key] = value
end
for key, value in Tracing :: any do
	exports.tracing[key] = value
end
for key, value in TracingSubscriptions :: any do
	exports.tracing[key] = value
end

exports.unstable_flushAllWithoutAsserting = HostConfig.unstable_flushAllWithoutAsserting
exports.unstable_flushNumberOfYields = HostConfig.unstable_flushNumberOfYields
exports.unstable_flushExpired = HostConfig.unstable_flushExpired
exports.unstable_clearYields = HostConfig.unstable_clearYields
exports.unstable_flushUntilNextPaint = HostConfig.unstable_flushUntilNextPaint
exports.unstable_flushAll = HostConfig.unstable_flushAll
exports.unstable_yieldValue = HostConfig.unstable_yieldValue
exports.unstable_advanceTime = HostConfig.unstable_advanceTime
exports.unstable_Profiling = Scheduler.unstable_Profiling

return exports

end,
}

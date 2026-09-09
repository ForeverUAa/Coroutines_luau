local CancellationToken = require(script.cancellationToken)
local Awaitable = require(script.awaitable)

export type Coroutine<T...> = {
	thread: thread,
	resume: (self: Coroutine<T...>, T...) -> (boolean, ...any),
}

local Coroutine = {}
local helperFunctions = {}

function Coroutine.new<T...>(
	fn: (T...) -> ()
): Coroutine<T...>
	local self = {} :: any

	self.thread = coroutine.create(fn)

	function self.resume(self: Coroutine<T...>, ...)
		return coroutine.resume(self.thread, ...)
	end

	return self
end

function Coroutine.yield(...)
	return coroutine.yield(...)
end

local function co_await(awaitable)
    return coroutine.yield(awaitable)
end

local function Coroutine.co_wrap(fn)
    local co = Coroutine.new(fn)

    return function(...)
        local success, ... = co:resume(...)

        if not success then
            error(...)
        end

        return ...
    end
end

function helperFunctions.awaitCancellation()
	local co = coroutine.running()

	if not co then
		error("awaitCancellation must be called from within a coroutine")
	end

	if not coroutine.status(co) == "suspended" then
		error("awaitCancellation must be called from within a suspended coroutine")
	end

	while true do
		local op = coroutine.yield()

		if op == "cancel" then
			return
		end
	end
end

function Coroutine.thread()
    local token = CancellationToken.new()

    while true do
        local operation = coroutine.yield(token)

        if operation == "cancel" then
            token:cancel()
            return
        end
    end
end

return Coroutine
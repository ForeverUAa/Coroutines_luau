local CancellationToken = require(script.cancellationToken)
local Awaitable = require(script.awaitable)

export type Coroutine<T...> = {
	thread: thread,
	resume: (self: Coroutine<T...>, T...) -> (boolean, ...any),
}

local Coroutine = {}

function Coroutine.new<T...>(fn: (T...) -> ()): Coroutine<T...>
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

function Coroutine.co_await(awaitable: Awaitable)
	return coroutine.yield(awaitable)
end

function Coroutine.co_wrap(fn)
	local co = Coroutine.new(fn)

	return function(...)
		local results = table.pack(co:resume(...))

		if not results[1] then
			error(results[2])
		end

		return table.unpack(results, 2, results.n)
	end
end

function Coroutine.awaitCancellation()
	local co = coroutine.running()

	if not co then
		error("awaitCancellation must be called from within a coroutine")
	end

	local token = CancellationToken.new()

	while not token:isCancelled() do
		local operation = Coroutine.co_await(
			Awaitable.new(function()
				return token:isCancelled()
			end)
		)

		if operation == "cancel" then
			token:cancel()
		end
	end
end

function Coroutine.thread()
	local token = CancellationToken.new()

	while not token:isCancelled() do
		local operation = Coroutine.co_await(
			Awaitable.new(function()
				return token:isCancelled()
			end)
		)

		if operation == "cancel" then
			token:cancel()
		end
	end
end

return Coroutine

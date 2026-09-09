local CancellationToken = require(script.cancellationToken)
local Awaitable = require(script.awaitable)
local Promise = require(script.Parent.DevPackages.Promise)

export type Coroutine<T...> = {
	thread: thread,
	resume: (self: Coroutine<T...>, T...) -> (boolean, ...any),
}

local Coroutine = {}

function Coroutine.new<T...>(fn: (T...) -> ()): Coroutine<T...>
	assert(type(fn) == "function", "Coroutine.new expects a function")

	local self: Coroutine<T...> = {
		thread = coroutine.create(fn),

		resume = function(self, ...)
			assert(
				coroutine.status(self.thread) ~= "dead",
				"cannot resume a dead coroutine"
			)

			return coroutine.resume(self.thread, ...)
		end,
	}

	return self
end

function Coroutine.yield(...)
	return coroutine.yield(...)
end

function Coroutine.co_await(awaitable: Awaitable)
	assert(awaitable ~= nil, "Coroutine.co_await expects an Awaitable")

	return coroutine.yield(awaitable)
end

function Coroutine.co_wrap(fn)
	assert(type(fn) == "function", "Coroutine.co_wrap expects a function")

	return function(...)
		local args = table.pack(...)

		return Promise.new(function(resolve, reject)
			local co = Coroutine.new(fn)

			local ok, ... = co:resume(
				table.unpack(args, 1, args.n)
			)

			if not ok then
				reject(...)
				return
			end

			resolve(...)
		end)
	end
end

function Coroutine.awaitCancellation()
    local co = coroutine.running()

    assert(
        co,
        "Coroutine.awaitCancellation must be called from within a coroutine"
    )

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

function Coroutine.thread<T...>(fn: (T...) -> ()): Coroutine<T...>
    assert(type(fn) == "function", "Coroutine.thread expects a function")

    return Coroutine.new(fn)
end

return Coroutine
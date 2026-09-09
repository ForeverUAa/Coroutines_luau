local CancellationToken = require(script.cancellationToken)
local Awaitable = require(script.awaitable)

local Promise = require(script.Parent.DevPackages.Promise)

export type Coroutine<T...> = {
	thread: thread,
	resume: (self: Coroutine<T...>, T...) -> (boolean, ...any),
}

local Coroutine = {}

function Coroutine.new<T...>(fn: (T...) -> ()): Coroutine<T...>
    local thread = coroutine.create(fn)

    local self: Coroutine<T...> = {
        thread = thread,

        resume = function(self, ...)
            return coroutine.resume(self.thread, ...)
        end,
    }

    return self
end

function Coroutine.yield(...)
	return coroutine.yield(...)
end

function Coroutine.co_await(awaitable: Awaitable)
	return coroutine.yield(awaitable)
end

function Coroutine.co_wrap(fn)
    return function(...)
        local args = table.pack(...)

        return Promise.new(function(resolve, reject)
            local co = Coroutine.new(fn)

            local ok, results = xpcall(function()
                return table.pack(co:resume(table.unpack(args, 1, args.n)))
            end, debug.traceback)

            if not ok then
                reject(results)
                return
            end

            if not results[1] then
                reject(results[2])
                return
            end

            resolve(table.unpack(results, 2, results.n))
        end)
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

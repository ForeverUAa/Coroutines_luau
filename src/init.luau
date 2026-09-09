local CancellationToken = require(script.cancellationToken)
local Awaitable = require(script.awaitable)
local Promise = require(script.Parent.DevPackages.Promise)

export type Awaitable<T = any> = Awaitable.Awaitable<T>
export type CancellationToken = CancellationToken.Token

export type Coroutine<T...> = {
	thread: thread,
	resume: (self: Coroutine<T...>, T...) -> (boolean, ...any),
}

local Coroutine = {}

function Coroutine.thread<T...>(fn: (T...) -> ...any): thread
	assert(
		type(fn) == "function",
		"Coroutine.thread expects a function"
	)

	return coroutine.create(fn)
end

function Coroutine.new<T...>(fn: (T...) -> ...any): Coroutine<T...>
	assert(
		type(fn) == "function",
		"Coroutine.new expects a function"
	)

	local self: Coroutine<T...> = {
		thread = Coroutine.thread(fn),

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

function Coroutine.co_await<T>(awaitable: Awaitable.Awaitable<T>): T
	assert(
		awaitable ~= nil,
		"Coroutine.co_await expects an Awaitable"
	)

	return awaitable:await()
end

function Coroutine.co_wrap<T...>(fn: (T...) -> ...any)
	assert(
		type(fn) == "function",
		"Coroutine.co_wrap expects a function"
	)

	return function(...)
		local args = table.pack(...)

		return Promise.new(function(resolve, reject)
			local co = Coroutine.new(fn)

			task.spawn(function()
				local ok, ... = co:resume(
					table.unpack(args, 1, args.n)
				)

				if not ok then
					reject(...)
					return
				end

				if coroutine.status(co.thread) == "dead" then
					resolve(...)
				end
			end)
		end)
	end
end

function Coroutine.awaitCancellation(
	token: CancellationToken.Token
)
	local co = coroutine.running()

	assert(
		co,
		"Coroutine.awaitCancellation must be called from within a coroutine"
	)

	assert(
		token ~= nil,
		"Coroutine.awaitCancellation expects a CancellationToken"
	)

	if token:isCancelled() then
		return
	end

	local awaitable = Awaitable.new()

	local disconnect = token:onCancel(function()
		awaitable:resolve()
	end)

	Coroutine.co_await(awaitable)

	disconnect()
end

return Coroutine
local Awaitable = {}
Awaitable.__index = Awaitable

export type Awaitable<T = any> = typeof(setmetatable({
	completed = false :: boolean,
	result = nil :: T?,
	waiters = {} :: { thread },
}, Awaitable))

function Awaitable.new<T = any>(): Awaitable<T>
	return setmetatable({
		completed = false,
		result = nil,
		waiters = {},
	}, Awaitable)
end

function Awaitable:isCompleted(): boolean
	return self.completed
end

function Awaitable:resolve<TValue>(value: TValue)
	if self.completed then
		return
	end

	self.completed = true
	self.result = value

	local waiters = self.waiters
	self.waiters = {}

	for _, thread in waiters do
		task.spawn(function()
			if coroutine.status(thread) ~= "dead" then
				local ok, err = coroutine.resume(thread, value)

				if not ok then
					warn("Awaitable failed to resume coroutine:", err)
				end
			end
		end)
	end
end

function Awaitable:await(): any
	if self.completed then
		return self.result
	end

	local thread = coroutine.running()

	assert(
		thread,
		"Awaitable:await must be called from within a coroutine"
	)

	table.insert(self.waiters, thread)

	return coroutine.yield()
end

return Awaitable
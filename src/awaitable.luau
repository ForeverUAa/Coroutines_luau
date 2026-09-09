local Awaitable = {}
Awaitable.__index = Awaitable

export type Awaitable<T = any> = typeof(setmetatable({
	completed = false :: boolean,
	result = nil :: T?,
	waiters = {} :: {thread},
}, Awaitable))

function Awaitable.new<T>(executor: ((resolve: (value: T) -> ()) -> ())?): Awaitable<T>
	local self = setmetatable({
		completed = false,
		result = nil,
		waiters = {},
	}, Awaitable)

	if executor then
		task.spawn(function()
			executor(function(value)
				self:resolve(value)
			end)
		end)
	end

	return self
end

function Awaitable:resolve(value)
	if self.completed then
		return
	end

	self.completed = true
	self.result = value

	for _, co in self.waiters do
		task.spawn(function()
			coroutine.resume(co, value)
		end)
	end

	table.clear(self.waiters)
end

function Awaitable:await()
	if self.completed then
		return self.result
	end

	local thread = coroutine.running()
	assert(thread, "Awaitable:await must be called from a coroutine")

	table.insert(self.waiters, thread)

	return coroutine.yield()
end

return Awaitable
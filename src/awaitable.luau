local Awaitable = {}
Awaitable.__index = Awaitable

export type Awaitable<T = any> = typeof(setmetatable({
	completed = false :: boolean,
	result = nil :: T?,
	waiters = {} :: {thread},
}, {
	__index = {} :: {
		resolve: (self: Awaitable<T>, value: T) -> (),
		await: (self: Awaitable<T>) -> T,
	}
}))

function Awaitable.new<T>(initialValue: T?): Awaitable<T>
	return setmetatable({
		completed = false,
		result = initialValue,
		waiters = {},
	}, Awaitable)
end

function Awaitable:resolve(value)
    if self.completed then
        return
    end

    self.completed = true
    self.result = value

    for _, co in self.waiters do
        coroutine.resume(co, value)
    end
end

function Awaitable:await()
    if self.completed then
        return self.result
    end

    table.insert(self.waiters, coroutine.running())

    return coroutine.yield(self)
end

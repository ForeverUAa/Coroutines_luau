local Awaitable = {}
Awaitable.__index = Awaitable

function Awaitable.new()
    return setmetatable({
        completed = false,
        result = nil,
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
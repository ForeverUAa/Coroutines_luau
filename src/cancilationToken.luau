local CancellationToken = {}
CancellationToken.__index = CancellationToken

function CancellationToken.new()
    return setmetatable({
        cancelled = false,
    }, CancellationToken)
end

function CancellationToken:cancel()
    self.cancelled = true
end

function CancellationToken:isCancelled()
    return self.cancelled
end
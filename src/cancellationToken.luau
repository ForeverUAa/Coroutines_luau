local CancellationToken = {}
CancellationToken.__index = CancellationToken

export type Token = typeof(setmetatable({
	cancelled = false :: boolean,
	callbacks = {} :: {() -> ()},
}, CancellationToken))

function CancellationToken.new(): Token
	return setmetatable({
		cancelled = false,
		callbacks = {},
	}, CancellationToken)
end

function CancellationToken:isCancelled(): boolean
	return self.cancelled
end

function CancellationToken:onCancel(callback: () -> ())
	if self.cancelled then
		callback()
		return
	end

	table.insert(self.callbacks, callback)
end

function CancellationToken:cancel()
	if self.cancelled then
		return
	end

	self.cancelled = true

	for _, callback in self.callbacks do
		callback()
	end

	table.clear(self.callbacks)
end

return CancellationToken
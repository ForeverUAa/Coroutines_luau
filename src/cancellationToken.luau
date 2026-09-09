local CancellationToken = {}
CancellationToken.__index = CancellationToken

export type Token = typeof(setmetatable({
	cancelled = false :: boolean,
	callbacks = {} :: { () -> () },
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

function CancellationToken:onCancel(callback: () -> ()): () -> ()
	assert(
		type(callback) == "function",
		"CancellationToken:onCancel expects a function"
	)

	if self.cancelled then
		callback()
		return function() end
	end

	local callbacks = self.callbacks
	table.insert(callbacks, callback)

	local removed = false

	return function()
		if removed then
			return
		end

		removed = true

		for i, registered in callbacks do
			if registered == callback then
				table.remove(callbacks, i)
				break
			end
		end
	end
end

function CancellationToken:cancel()
	if self.cancelled then
		return
	end

	self.cancelled = true

	local callbacks = self.callbacks
	self.callbacks = {}

	for _, callback in callbacks do
		task.spawn(function()
			local ok, err = pcall(callback)

			if not ok then
				warn("Cancellation callback failed:", err)
			end
		end)
	end
end

return CancellationToken
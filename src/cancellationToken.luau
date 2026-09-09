local Promise = require(script.Parent.DevPackages.Promise)

local CancellationToken = {}
CancellationToken.__index = CancellationToken

function CancellationToken.new()
	local self = setmetatable({}, CancellationToken)

	self.promise = Promise.new(function(resolve)
		self._resolve = resolve
	end)

	return self
end

function CancellationToken:cancel()
	if self:isCancelled() then
		return
	end

	self._resolve()
end

function CancellationToken:isCancelled()
	return self.promise:getStatus() == Promise.Status.Resolved
end

function CancellationToken:await()
	return self.promise
end

return CancellationToken
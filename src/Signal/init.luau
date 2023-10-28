local Signal = {}
Signal.ClassName = "Signal"
Signal.__index = Signal

local FastSpawn = require(script.FastSpawn)

local Signals = {}

function Signal.new(root: string)
	if not Signals[root] then
		Signals[root] = setmetatable({
			fn = {},
			root = root,
		}, Signal)
	end
	return Signals[root]
end

function Signal:Connect(callback: (...any) -> ())
	table.insert(self.fn, callback)
end

function Signal:DisconnectAll()
	table.clear(self.fn)
end

function Signal:Destroy()
	setmetatable(self, nil)
end

function Signal:Fire(...)
	if #self.fn > 0 then
		for _, fn in self.fn do
			FastSpawn(fn, ...)
		end
	end
end

function Signal:Wait()
	local t = coroutine.running()
	local c
	c = self:Connect(function(...)
		c:Disconnect()
		task.spawn(t, ...)
	end)
	return coroutine.yield()
end

function Signal:Once(callback: (...any) -> ())
	local c
	c = self:Connect(function(...)
		c:Disconnect()
		task.spawn(callback, ...)
	end)
end

return table.freeze(Signal)
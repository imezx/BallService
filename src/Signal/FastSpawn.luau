--!strict
local FreeThread: thread? = nil

local function FunctionPasser(fn, ...)
	local AquiredThread = FreeThread
	FreeThread = nil
	fn(...)
	FreeThread = AquiredThread
end

local function yielder()
	while true do
		FunctionPasser(coroutine.yield())
	end
end

return function<T...>(callback: (T...) -> (), ...: any)
	if not FreeThread then
		FreeThread = coroutine.create(yielder)
		coroutine.resume(FreeThread :: any)
	end
	task.spawn(FreeThread :: thread, callback, ...)
end
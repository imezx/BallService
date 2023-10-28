--!strict
--!native
--!optimize 2
-- Better RunService Module by Eternity_Devs
-- Note: Parallel not supported here for Bind Service.
-- v1.1

local Service = game:GetService("RunService")
local Assert = require(script:WaitForChild("SafeAssert"))

local RunService = {
	Heartbeat = Service.Heartbeat,
	Stepped = Service.Stepped,
	RenderStepped = Service.RenderStepped,
	PostSimulation = Service.PostSimulation,
	PreAnimation = Service.PreAnimation,
	PreRender = Service.PreRender,
	BindToRenderStep = Service.BindToRenderStep,
	UnbindFromRenderStep = Service.UnbindFromRenderStep,
}

type BindMapType = {
	[string]: {
		[string]: {
			fn: (...any) -> (),
			idx: number,
		},
	},
}

type BindMapPiorityType = {
	[string]: {
		[number]: {string},
	},
}

local BindMap: BindMapType = {}
local BindMapPiority: BindMapPiorityType = {}
local isSilent: boolean = false

function RunService:IsStudio(): boolean
	return Service:IsStudio()
end

function RunService:IsServer(): boolean
	return Service:IsServer()
end

function RunService:IsClient(): boolean
	return Service:IsClient()
end

function RunService:BindToHeartbeat(name: string, piority: number, func: (...any) -> ()): ()
	if not BindMap["Heartbeat"] then
		BindMap["Heartbeat"] = {}
	end
	Assert(typeof(name) ~= "string", `Expected Argument #1 as string got {typeof(name)}`, isSilent)
	Assert(typeof(piority) ~= "number", `Expected Argument #2 as number got {typeof(name)}`, isSilent)
	Assert(piority < 1, `Minimum piority is 1 got {piority}`, isSilent)
	Assert(not func, `Expected Argument #3 as function got {typeof(func)}`, isSilent)
	Assert(BindMap["Heartbeat"][name] ~= nil, `Unable to BindToHeartbeat ({name} is already binded)`, isSilent)
	BindMap["Heartbeat"][name] = {fn = func, idx = piority}
	if not BindMapPiority["Heartbeat"] then
		BindMapPiority["Heartbeat"] = {}
	end
	if not BindMapPiority["Heartbeat"][piority] then
		BindMapPiority["Heartbeat"][piority] = {}
	end
	table.insert(BindMapPiority["Heartbeat"][piority], name)
end

function RunService:BindToPostSimulation(name: string, piority: number, func: (...any) -> ()): ()
	if not BindMap["PostSimulation"] then
		BindMap["PostSimulation"] = {}
	end
	Assert(typeof(name) ~= "string", `Expected Argument #1 as string got {typeof(name)}`, isSilent)
	Assert(typeof(piority) ~= "number", `Expected Argument #2 as number got {typeof(name)}`, isSilent)
	Assert(piority < 1, `Minimum piority is 1 got {piority}`, isSilent)
	Assert(not func, `Expected Argument #3 as function got {typeof(func)}`, isSilent)
	Assert(BindMap["PostSimulation"][name] ~= nil, `Unable to BindToPostSimulation ({name} is already binded)`, isSilent)
	BindMap["PostSimulation"][name] = {fn = func, idx = piority}
	if not BindMapPiority["PostSimulation"] then
		BindMapPiority["PostSimulation"] = {}
	end
	if not BindMapPiority["PostSimulation"][piority] then
		BindMapPiority["PostSimulation"][piority] = {}
	end
	table.insert(BindMapPiority["PostSimulation"][piority], name)
end

function RunService:UnbindFromPostSimulation(name: string): ()
	if BindMap["PostSimulation"] and BindMap["PostSimulation"][name] and BindMapPiority["PostSimulation"][BindMap["PostSimulation"][name].idx] and table.find(BindMapPiority["PostSimulation"][BindMap["PostSimulation"][name].idx], name) then
		BindMapPiority["PostSimulation"][BindMap["PostSimulation"][name].idx][table.find(BindMapPiority["PostSimulation"][BindMap["PostSimulation"][name].idx], name) or 0] = nil
		BindMap["PostSimulation"][name] = nil
	end
end

function RunService:UnbindFromHeartbeat(name: string): ()
	if BindMap["Heartbeat"] and BindMap["Heartbeat"][name] and BindMapPiority["Heartbeat"][BindMap["Heartbeat"][name].idx] and table.find(BindMapPiority["Heartbeat"][BindMap["Heartbeat"][name].idx], name) then
		BindMapPiority["Heartbeat"][BindMap["Heartbeat"][name].idx][table.find(BindMapPiority["Heartbeat"][BindMap["Heartbeat"][name].idx], name) or 0] = nil
		BindMap["Heartbeat"][name] = nil
	end
end

function RunService:Silent(option: boolean): ()
	isSilent = option
end

Service.Heartbeat:Connect(function(delta: number)
	if BindMapPiority["Heartbeat"] and BindMap["Heartbeat"] then
		for idx: number, map in pairs(BindMapPiority["Heartbeat"]) do
			for _, identifier: string in map do
				if BindMap["Heartbeat"][identifier] then task.spawn(BindMap["Heartbeat"][identifier].fn, delta) end
			end
		end
	end
end)

Service.PostSimulation:Connect(function(delta: number)
	if BindMapPiority["PostSimulation"] and BindMap["PostSimulation"] then
		for idx: number, map in pairs(BindMapPiority["PostSimulation"]) do
			for _, identifier: string in map do
				if BindMap["PostSimulation"][identifier] then task.spawn(BindMap["PostSimulation"][identifier].fn, delta) end
			end
		end
	end
end)

return table.freeze(RunService) :: typeof(RunService)
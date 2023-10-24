-- BallService Module by Eternity_Devs
-- version 2.0.1
--!strict
local BallService = {}
BallService.__index = BallService
BallService.Settings = {
	BallPlace = game:GetService("Workspace"), -- default: game:GetService("Workspace")
	BallName = "Ball",
	Massless = false,
	Material = Enum.Material.Neon, -- default: SmoothPlastic
	DefaultColor = Color3.fromRGB(255, 255, 255), -- default: 255,255,255 (use rgb for better accuration color space)
	DefaultSize = Vector3.new(1.75, 1.75, 1.75),
	DefaultPos = Vector3.new(0, 0, 0),
	DefaultSpeed = 1, -- default: 1
	MinTweenSpeed = 0.1, -- default: 0.1
	MaxTweenSpeed = 8, -- default: 8
	ThrottlingSpeed = 1, -- default: 1
	ThrottlingDelta = 5, -- default: 5
	MinimumPlayers = 2, -- Minimum Players (default: 2)
	EasingDirection = Enum.EasingDirection.Out,
	EasingStyle = Enum.EasingStyle.Linear,
	MinMagnitudeToKill = 2.5, -- Minimum Magnitude Distance between Ball Object with Target Object to Kill Target
	DamageToTarget = 100, -- default: 100
	UseCurve = true,
	MaxHeightCurve = 30, -- default: 30
	MinHeightCurve = 0, -- default: 0
	TestDummy = game:GetService("Workspace"), -- change the default with TestMode enabled.
	TestMode = false, -- default: false (dont forget to change TestDummy if this enabled.)
	alpha = 1, -- default: 1
	Silent = false, -- default: false (make warns be silent from RunService Module)
	isPlaying = false, -- DO NOT CHANGE THIS (default: false)
}
BallService._Players = {}
BallService.alpha = BallService.Settings.alpha
BallService.isPlayable = false
BallService.PreviousPos = BallService.Settings.DefaultPos
BallService.CurveCache = {} :: (any)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = require(script:WaitForChild("RunService"))
local Signal = require(script:WaitForChild("Signal"))
local FloatCurve = require(script:WaitForChild("Curve"))

local OnStopSignal = Signal.new("OnStopSignal")
local Rand = Random.new()

BallService.OnStop = OnStopSignal

local BallObject = nil

-- Public

function BallService:init()
	if RunService:IsServer() then
		if not script:FindFirstChild("Ball") then
			-- Create Default Ball Object
			local newBall = Instance.new("Part", script)
			newBall.Name = self.Settings.BallName
			newBall.Size = self.Settings.DefaultSize
			newBall.Massless = self.Settings.Massless
			newBall.CanCollide = false
			newBall.Anchored = true
			newBall.CastShadow = false
			newBall.Color = self.Settings.DefaultColor
			newBall.Material = self.Settings.Material
			newBall.Shape = Enum.PartType.Ball
			newBall.Position = self.Settings.DefaultPos

			-- Create Default Ball Settings Objects
			local Speed = Instance.new("NumberValue", newBall)
			Speed.Name = "Speed"
			Instance.new("ObjectValue", newBall).Name = "Target"
			Instance.new("IntValue", newBall)
			
			Speed.Changed:Connect(function()
				Speed.Value = math.min(2.5e2, Speed.Value)
			end)
			
			BallObject = script:WaitForChild("Ball"):Clone()
			BallObject.Parent = self.Settings.BallPlace
		end
		if BallObject:WaitForChild("Speed").Value <= 0 then BallObject:WaitForChild("Speed").Value = self.Settings.DefaultSpeed end
	elseif not self.Settings.BallPlace:FindFirstChild(self.Settings.BallName) then
		repeat task.wait() until self.Settings.BallPlace:FindFirstChild(self.Settings.BallName) -- wait from server initialize
		BallObject = self.Settings.BallPlace:WaitForChild(self.Settings.BallName, 5) -- timeout 5 seconds
	end
end

function BallService:Set(options: typeof(BallService.Settings))
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	for i,v in pairs(options) do
		if self.Settings[i] ~= nil and i ~= "isPlaying" then
			if typeof(self.Settings[i]) ~= typeof(v) then
				warn(`Unable to set {i}, expected {typeof(self.Settings[i])} got {typeof(v)}.`)
				continue
			end
			self.Settings[i] = v
			if i == "Silent" then
				RunService:Silent(v)
			elseif i == "TestMode" or i == "TestDummy" then
				self:UpdatePlayers()
			elseif i == "alpha" then
				self.alpha = v
			end
		end
	end
end

function BallService:SetTarget(objectTarget: Model)
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not objectTarget then error("Missing argument #1", 2) end
	if not objectTarget:IsA("Model") then error("Expected argument #1 as Model.", 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	if not BallObject:FindFirstChild("Target") then error("Failed to set target.", 2) end
	BallObject:WaitForChild("Target").Value = objectTarget
	self:UpdatePlayers()
end

function BallService:SetEasingDirection(easingDirection: Enum.EasingDirection)
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not easingDirection then error("Missing argument #1", 2) end
	if typeof(easingDirection) ~= "EnumItem" then error(`Expected type of argument #1 as EnumItem got {typeof(easingDirection)}.`, 2) end
	self.Settings.EasingDirection = easingDirection
end

function BallService:SetEasingStyle(easingStyle: Enum.EasingStyle)
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not easingStyle then error("Missing argument #1", 2) end
	if typeof(easingStyle) ~= "EnumItem" then error(`Expected type of argument #1 as EnumItem got {typeof(easingStyle)}.`, 2) end
	self.Settings.EasingStyle = easingStyle
end

function BallService:SetSpeed(speed: number)
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not speed then error("Missing argument #1", 2) end
	if typeof(speed) ~= "number" then error(`Expected type of argument #1 as number got {typeof(speed)}.`, 2) end
	if speed < 0.5 then error(`Expected argument #1 with minimum 0.5 got {speed}`, 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	if not BallObject:FindFirstChild("Speed") then error("Failed to set speed.", 2) end
	BallObject:WaitForChild("Speed").Value = speed
end

function BallService:SetColor(color: Color3)
	if not BallObject then error("Service not initialized yet.", 2) end
	BallObject.Color = color
end

function BallService:UpdatePlayers()
	table.clear(self._Players)
	for _, plr in pairs(Players:GetPlayers()) do
		if plr and plr.Character and not table.find(self._Players, plr.Character) then
			table.insert(self._Players, plr.Character)
		end
	end
	if self.Settings.TestMode and self.Settings.TestDummy and self.Settings.TestDummy:IsA("Model") and self.Settings.TestDummy.Parent ~= nil and not table.find(self._Players, self.Settings.TestDummy) then
		table.insert(self._Players, self.Settings.TestDummy)
	end
	self.isPlayable = (#self._Players >= self.Settings.MinimumPlayers)
end

function BallService:Reset()
	BallObject.Value.Value = 3
	RunService:UnbindFromPostSimulation("PlayBall")
	BallObject.Target.Value = nil
	BallObject.Speed.Value = self.Settings.DefaultSpeed
	self.alpha = self.Settings.alpha
	repeat BallObject.Position = self.Settings.DefaultPos task.wait() until BallObject.Position == self.Settings.DefaultPos
	self:UpdatePlayers()
	BallObject.Value.Value = 0
end

function BallService:Play()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Service not initialized yet.", 2) end
	self:UpdatePlayers()
	if #self._Players < self.Settings.MinimumPlayers then return warn(`Not enough players (require {self.Settings.MinimumPlayers} players)`) end
	self.Settings.isPlaying = true
end

function BallService:Stop()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Service not initialized yet.", 2) end
	self.Settings.isPlaying = false
	OnStopSignal:Fire()
end

function BallService:IsPlaying(): boolean
	return self.Settings.isPlaying
end

function BallService:GetTarget(): Model
	if not BallObject then error("Service not initialized yet.", 2) end
	return BallObject.Target.Value
end

function BallService:IsTargetAlive(object: any): boolean
	if object and object:FindFirstChild("Humanoid") then return (object.Humanoid.Health > 0) end return false
end

if RunService:IsServer() then
	-- Internal
	function getRandom(previousObject): boolean
		if #BallService._Players < BallService.Settings.MinimumPlayers then
			BallService:Reset()
			BallService:Stop()
			return false
		end
		while (BallObject.Target.Value == previousObject) do
			BallObject.Target.Value = BallService._Players[math.random(1, #BallService._Players)]
		end
		return (BallObject.Target.Value and true or false)
	end

	function getTarget(): boolean
		return (BallObject and getRandom(BallObject.Target.Value) or false)
	end
	
	function CurveSimulation(basePos: BasePart, targetPos: BasePart): Vector3?
		if (not basePos) or (not targetPos) then return end
		if (basePos.Position-targetPos.Position).X < 0 and (basePos.Position-targetPos.Position).Z < 0 then
			return ((targetPos.Position-basePos.Position)/(Rand:NextNumber(1, 2)))+Vector3.new(Rand:NextInteger(BallService.Settings.MinHeightCurve, BallService.Settings.MaxHeightCurve), Rand:NextInteger(BallService.Settings.MinHeightCurve, BallService.Settings.MaxHeightCurve), Rand:NextInteger(BallService.Settings.MinHeightCurve, BallService.Settings.MaxHeightCurve))
		else
			return ((basePos.Position-targetPos.Position)/(Rand:NextNumber(1, 2)))+Vector3.new(Rand:NextInteger(BallService.Settings.MinHeightCurve, BallService.Settings.MaxHeightCurve), Rand:NextInteger(BallService.Settings.MinHeightCurve, BallService.Settings.MaxHeightCurve), Rand:NextInteger(BallService.Settings.MinHeightCurve, BallService.Settings.MaxHeightCurve))
		end
	end

	function FollowTarget(delta: number)
		if BallService.Settings.isPlaying and BallObject then
			if BallObject.Target.Value and BallObject.Target.Value.PrimaryPart and BallService:IsTargetAlive(BallObject.Target.Value) then
				if (BallObject.Position-BallObject.Target.Value.PrimaryPart.Position).Magnitude < BallService.Settings.MinMagnitudeToKill then
					BallObject.Target.Value.Humanoid.Health -= BallService.Settings.DamageToTarget
					BallService:Reset()
					return
				end
				if BallService.Settings.UseCurve then
					if BallService.CurveCache and BallService.CurveCache[2] ~= nil then
						if (BallService.CurveCache[2].TotalTime-((tick()-BallService.CurveCache[1]) % BallService.CurveCache[2].TotalTime)) <= 0.01 then
							BallService.PreviousPos = BallObject.Position
							BallService.CurveCache[1] = tick()
						end
						BallService.CurveCache[2]:UpdateCurves()
						local toPos = BallService.CurveCache[2]:Tween((tick()-BallService.CurveCache[1]) % BallService.CurveCache[2].TotalTime, BallService.Settings.EasingStyle, BallService.Settings.EasingDirection) :: Vector3
						if toPos and BallObject.Position ~= toPos then
							BallObject.Position = toPos
						else
							BallObject.Position = BallObject.Target.Value.PrimaryPart.Position
						end
					end
				else
					BallService.alpha += (delta/BallService.Settings.ThrottlingDelta)
					TweenService:Create(BallObject, TweenInfo.new(math.min(BallService.Settings.MaxTweenSpeed, math.max(BallService.Settings.MinTweenSpeed, (BallService.alpha/BallObject.Speed.Value)/BallService.Settings.ThrottlingSpeed)), BallService.Settings.EasingStyle, BallService.Settings.EasingDirection), { Position = BallObject.Target.Value.PrimaryPart.Position }):Play()
				end
			else
				BallService:Reset()
			end
		end
	end
	
	-- PostSimulation is a another version of Heartbeat with static delta or 60
	RunService.PostSimulation:Connect(function()
		if BallService.Settings.isPlaying and BallObject then
			if BallObject.Value.Value == 0 then
				BallObject.Value.Value = 2
				if not getTarget() then
					BallObject.Value.Value = 0
					return
				end
				BallService.PreviousPos = BallObject.Position
				if BallService.Settings.UseCurve then
					BallService.CurveCache[1] = tick()
					BallService.CurveCache[2] = FloatCurve.new({BallObject, CurveSimulation(BallObject, BallObject.Target.Value.PrimaryPart), BallObject.Target.Value.PrimaryPart}, BallObject.Speed.Value*20) :: (any)
				end
				RunService:BindToPostSimulation("PlayBall", 1, FollowTarget)
			elseif BallObject.Value.Value == 1 then
				RunService:UnbindFromPostSimulation("PlayBall")
				BallObject.Value.Value = 0
			end
		end
	end)
end

return BallService :: typeof(BallService)
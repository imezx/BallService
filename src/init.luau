-- BallService Module by Eternity_Devs
-- version 1.1
--!strict
local BallService = {}
BallService.__index = BallService
BallService.Settings = {
	BallPlace = game:GetService("Workspace"), -- default: game:GetService("Workspace")
	BallName = "Ball",
	Massless = false,
	Material = Enum.Material.SmoothPlastic, -- default: SmoothPlastic
	DefaultColor = Color3.fromRGB(255, 255, 255), -- default: 255,255,255 (use rgb for better accuration color space)
	DefaultSize = Vector3.new(1.75, 1.75, 1.75),
	DefaultPos = Vector3.new(0, 0, 0),
	DefaultSpeed = 1, -- default: 1
	MinTweenSpeed = 0.1, -- default: 0.1
	MaxTweenSpeed = 8, -- default: 8
	ThrottlingSpeed = 2.5, -- default: 2.5
	ThrottlingDelta = 4, -- default: 4
	MinimumPlayers = 2, -- Minimum Players (default: 2)
	EasingDirection = Enum.EasingDirection.InOut,
	EasingStyle = Enum.EasingStyle.Linear,
	MinMagnitudeToKill = 2.5, -- Minimum Magnitude Distance between Ball Object with Target Object to Kill Target
	DamageToTarget = 100, -- default: 100
	TestDummy = game:GetService("Workspace"), -- change the default with TestMode enabled.
	TestMode = false, -- default: false (dont forget to change TestDummy if this enabled.)
	alpha = 5, -- default: 5
	Silent = false, -- default: false (make warns be silent from RunService Module)
	isPlaying = false, -- DO NOT CHANGE THIS (default: false)
}
BallService._Players = {}
BallService.alpha = BallService.Settings.alpha
BallService.isPlayable = false

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = require(script:WaitForChild("RunService"))
local Signal = require(script:WaitForChild("Signal"))

local OnStopSignal = Signal.new("OnStopSignal")

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
			Instance.new("NumberValue", newBall).Name = "Speed"
			Instance.new("ObjectValue", newBall).Name = "Target"
			Instance.new("IntValue", newBall)
			
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
	if not objectTarget then error("Missing argument #1", 2) end
	if not objectTarget:IsA("Model") then error("Expected argument #1 as Model.", 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	if not BallObject:FindFirstChild("Target") then error("Failed to set target.", 2) end
	BallObject:WaitForChild("Target").Value = objectTarget
	self:UpdatePlayers()
end

function BallService:SetEasingDirection(easingDirection: Enum.EasingDirection)
	if not easingDirection then error("Missing argument #1", 2) end
	if typeof(easingDirection) ~= "EnumItem" then error(`Expected type of argument #1 as EnumItem got {typeof(easingDirection)}.`, 2) end
	self.Settings.EasingDirection = easingDirection
end

function BallService:SetEasingStyle(easingStyle: Enum.EasingStyle)
	if not easingStyle then error("Missing argument #1", 2) end
	if typeof(easingStyle) ~= "EnumItem" then error(`Expected type of argument #1 as EnumItem got {typeof(easingStyle)}.`, 2) end
	self.Settings.EasingStyle = easingStyle
end

function BallService:SetSpeed(speed: number)
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
	if not BallObject then error("Service not initialized yet.", 2) end
	self:UpdatePlayers()
	if #self._Players < self.Settings.MinimumPlayers then return warn(`Not enough players (require {self.Settings.MinimumPlayers} players)`) end
	self.Settings.isPlaying = true
end

function BallService:Stop()
	if not BallObject then error("Service not initialized yet.", 2) end
	self.Settings.isPlaying = false
	OnStopSignal:Fire()
end

function BallService:IsPlaying(): boolean
	return self.Settings.isPlaying
end

function BallService:GetTarget()
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
		return true
	end

	function getTarget(): boolean
		return (BallObject and getRandom(BallObject.Target.Value) or false)
	end

	function FollowTarget(delta: number)
		if BallService.Settings.isPlaying and BallObject then
			if BallObject.Target.Value and BallObject.Target.Value.PrimaryPart and BallService:IsTargetAlive(BallObject.Target.Value) then
				if (BallObject.Position-BallObject.Target.Value.PrimaryPart.Position).Magnitude < BallService.Settings.MinMagnitudeToKill then
					BallObject.Target.Value.Humanoid.Health -= BallService.Settings.DamageToTarget
					BallService:Reset()
					return
				end
				BallService.alpha += (delta/BallService.Settings.ThrottlingDelta)
				TweenService:Create(BallObject, TweenInfo.new(math.min(BallService.Settings.MaxTweenSpeed, math.max(BallService.Settings.MinTweenSpeed, (BallService.alpha/BallObject.Speed.Value)/BallService.Settings.ThrottlingSpeed)), BallService.Settings.EasingStyle, BallService.Settings.EasingDirection), { Position = BallObject.Target.Value.PrimaryPart.Position }):Play()
			else
				BallService:Reset()
			end
		end
	end
	
	RunService.PostSimulation:Connect(function()
		if BallService.Settings.isPlaying and BallObject then
			if BallObject.Value.Value == 0 then
				BallObject.Value.Value = 2
				getTarget()
				RunService:BindToPostSimulation("PlayBall", 1, FollowTarget)
			elseif BallObject.Value.Value == 1 then
				RunService:UnbindFromPostSimulation("PlayBall")
				BallObject.Value.Value = 0
			end
		end
	end)
end

return BallService :: typeof(BallService)
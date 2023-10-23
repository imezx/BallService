-- BallService Module by Eternity_Devs
-- version 1.0
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
	MaxTweenSpeed = 0.1, -- default: 0.1
	ThrottlingSpeed = 2.5, -- default: 2.5
	ThrottlingDelta = 4, -- default: 4
	MinimumPlayers = 1, -- Minimum Players (default: 1)
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

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = require(script:WaitForChild("RunService"))
local BallObject = nil

-- Public

function BallService:init()
	if RunService:IsServer() then
		if not script:FindFirstChild("Ball") then
			-- Create Default Ball Object
			local newBall = Instance.new("Part", script)
			newBall.Name = BallService.Settings.BallName
			newBall.Size = BallService.Settings.DefaultSize
			newBall.Massless = BallService.Settings.Massless
			newBall.CanCollide = false
			newBall.Anchored = true
			newBall.CastShadow = false
			newBall.Color = BallService.Settings.DefaultColor
			newBall.Material = BallService.Settings.Material
			newBall.Shape = Enum.PartType.Ball
			newBall.Position = BallService.Settings.DefaultPos

			-- Create Default Ball Settings Objects
			Instance.new("NumberValue", newBall).Name = "Speed"
			Instance.new("ObjectValue", newBall).Name = "Target"
			Instance.new("IntValue", newBall)
			
			BallObject = script:WaitForChild("Ball"):Clone()
			BallObject.Parent = BallService.Settings.BallPlace
		end
	elseif not BallService.Settings.BallPlace:FindFirstChild(BallService.Settings.BallName) then
		repeat task.wait() until BallService.Settings.BallPlace:FindFirstChild(BallService.Settings.BallName) -- wait from server initialize
		BallObject = BallService.Settings.BallPlace:WaitForChild(BallService.Settings.BallName, 5) -- timeout 5 seconds
	end
	if BallObject:WaitForChild("Speed").Value <= 0 then BallObject:WaitForChild("Speed").Value = BallService.Settings.DefaultSpeed end
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

function BallService:Reset()
	BallObject.Value.Value = 3
	RunService:UnbindFromPostSimulation("PlayBall")
	BallObject.Position = BallService.Settings.DefaultPos
	BallObject.Target.Value = nil
	BallObject.Speed.Value = BallService.Settings.DefaultSpeed
	BallService.Settings.alpha = 5
	BallObject.Value.Value = 0
end

function BallService:Play()
	if not BallObject then error("Service not initialized yet.", 2) end
	self.Settings.isPlaying = true
end

function BallService:Stop()
	if not BallObject then error("Service not initialized yet.", 2) end
	self.Settings.isPlaying = false
end

function BallService:IsPlaying(): boolean
	return self.Settings.isPlaying
end

function BallService:GetTarget()
	if not BallObject then error("Service not initialized yet.", 2) end
	return BallObject.Target.Value
end

function BallService:IsTargetAlive(object: Model): boolean
	if object and object:FindFirstChild("Humanoid") then return (object.Humanoid.Health > 0) end return false
end

-- Internal

function getTarget()
	if BallObject then
		if #Players:GetPlayers() > BallService.Settings.MinimumPlayers and not BallService.Settings.TestMode then
			return false
		end
		for _,plr in pairs(Players:GetPlayers()) do
			if BallObject and plr and plr.Character and plr.Character.PrimaryPart and BallObject.Target.Value ~= plr.Character and BallService:IsTargetAlive(plr.Character) then
				BallObject.Target.Value = plr.Character
				return true
			end
		end
		if BallService.Settings.TestMode and BallService.Settings.TestDummy and BallService.Settings.TestDummy:IsA("Model") then -- if TestDummy is a Model
			BallObject.Target.Value = BallService.Settings.TestDummy
			return true
		end
	end
	return false
end

function FollowTarget(delta: number)
	if BallService.Settings.isPlaying and BallObject then
		if BallObject.Target.Value and BallObject.Target.Value.PrimaryPart and BallService:IsTargetAlive(BallObject.Target.Value) then
			if (BallObject.Position-BallObject.Target.Value.PrimaryPart.Position).Magnitude < BallService.Settings.MinMagnitudeToKill then
				BallObject.Target.Value.Humanoid.Health -= BallService.Settings.DamageToTarget
				BallService:Reset()
				return
			end
			BallService.Settings.alpha += (delta/BallService.Settings.ThrottlingDelta)
			if BallObject.Target.Value and BallObject.Target.Value.PrimaryPart then -- recheck to prevent error
				TweenService:Create(BallObject, TweenInfo.new(math.max(BallService.Settings.MaxTweenSpeed, (BallService.Settings.alpha/BallObject.Speed.Value)/BallService.Settings.ThrottlingSpeed), BallService.Settings.EasingStyle, BallService.Settings.EasingDirection), { Position = BallObject.Target.Value.PrimaryPart.Position }):Play()
			end
		else
			BallService:Reset()
		end
	end
end

RunService.PostSimulation:Connect(function()
	if BallService.Settings.isPlaying and BallObject then
		if BallObject.Value.Value == 0 then
			BallObject.Value.Value = 2
			repeat task.wait() until getTarget()
			RunService:BindToPostSimulation("PlayBall", 1, FollowTarget)
		end
		if BallObject.Value.Value == 1 then
			RunService:UnbindFromPostSimulation("PlayBall")
			BallObject.Value.Value = 0
		end
	end
end)

return BallService :: typeof(BallService)
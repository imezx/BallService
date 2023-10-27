-- BallService Module by Eternity_Devs
-- version 2.2.0
--!native
--!strict
local BallService = {}
BallService.__index = BallService
BallService.Settings = {
	Locate = game:GetService("Workspace"), -- default: game:GetService("Workspace")
	Name = "Ball", -- default: ball
	Shape = Enum.PartType.Ball, -- default: Ball
	Massless = true, -- default: true
	Material = Enum.Material.Neon, -- default: Neon
	DefaultColor = Color3.fromRGB(255, 255, 255), -- default: 255,255,255 (use rgb for better accuration color space)
	DefaultSize = Vector3.new(1.75, 1.75, 1.75),
	DefaultPos = Vector3.new(0, 0, 0),
	Outline = {
		DefaultOutlineColor = Color3.fromRGB(255, 255, 255), -- default: 255,255,255 (use rgb for better accuration color space)
		DefaultOutlineTransparency = 0, -- default: 0
		DefaultFillColor = Color3.fromRGB(255, 255, 255), -- default: 255,255,255 (use rgb for better accuration color space)
		DefaultFillTransparency = 0.75, -- default: 0.75
	},
	Trail = {
		DefaultTrailColor = {Color3.fromRGB(255, 255, 255)}, -- default: 255,255,255 (use rgb for better accuration color space)
		DefaultTrailTransparency = {0.75}, -- default: 0.75
		DefaultTrailLifetime = 0.2, -- default: 0.2
	},
	Speed = {
		DefaultSpeed = 1, -- default: 1
		MaxSpeed = 50, -- default: 50,
		MinTweenSpeed = 0.1, -- default: 0.1
		MaxTweenSpeed = 8, -- default: 8
		ThrottlingSpeed = 1, -- default: 1
		ThrottlingDelta = 5, -- default: 5
		alpha = 1, -- default: 1
		baseQuadraticAlphaStep = 0.003, -- default: 0.003 (higher = faster)
	},
	Curve = {
		UseCurve = true,
		Vector3Curve = false, -- default: false, if false it use quadratic curve logic
		CubicCurve = false, -- default: false, if false it use quadratic curve else cubic curve.
		CurveBoost = 20, -- default: 20, speed up curve so it dont took long
		MaxHeightCurve = 20, -- default: 20
		MinHeightCurve = 0, -- default: 0
	},
	Test = {
		TestDummy = game:GetService("Workspace"), -- change the default with TestMode enabled.
		TestMode = false, -- default: false (dont forget to change TestDummy if this enabled.)
	},
	EasingDirection = Enum.EasingDirection.Out,
	EasingStyle = Enum.EasingStyle.Linear,
	MinimumPlayers = 2, -- Minimum Players (default: 2)
	MinMagnitudeToKill = 2.5, -- Minimum Magnitude Distance between Ball Object with Target Object to Kill Target
	DamageToTarget = 100, -- default: 100
	Silent = false, -- default: false (make warns be silent from RunService Module)
	isPlaying = false, -- DO NOT CHANGE THIS (default: false)
}
BallService._Players = {} :: (any)
BallService.alpha = BallService.Settings.Speed.alpha :: number
BallService.isPlayable = false :: boolean
BallService.PreviousPos = BallService.Settings.DefaultPos :: Vector3
BallService.CurveCache = {} :: (any)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = require(script:WaitForChild("RunService"))
local Signal = require(script:WaitForChild("Signal"))
local FloatCurve = require(script:WaitForChild("Curve"))

local OnStopSignal = Signal.new("OnStopSignal")
BallService.OnStop = OnStopSignal

local Rand = Random.new()
local past_tick = tick()
local BallObject = nil

-- Public

function BallService:init(): ()
	if RunService:IsServer() then
		if not script:FindFirstChild(self.Settings.Name) then
			-- Create Default Object
			local newBall: Part = Instance.new("Part", script)
			newBall.Name = self.Settings.Name
			newBall.Size = self.Settings.DefaultSize
			newBall.Massless = self.Settings.Massless
			newBall.CanCollide = false
			newBall.Anchored = true
			newBall.CastShadow = false
			newBall.Color = self.Settings.DefaultColor
			newBall.Material = self.Settings.Material
			newBall.Shape = self.Settings.Shape
			newBall.Position = self.Settings.DefaultPos

			-- Create Default Settings Object
			Instance.new("NumberValue", newBall).Name = "Speed"
			Instance.new("ObjectValue", newBall).Name = "Past"
			Instance.new("ObjectValue", newBall).Name = "Target"
			Instance.new("IntValue", newBall)

			local Outline = Instance.new("Highlight", newBall)
			Outline.Name = "Outline"
			Outline.OutlineColor = self.Settings.Outline.DefaultOutlineColor
			Outline.FillColor = self.Settings.Outline.DefaultFillColor
			Outline.OutlineTransparency = self.Settings.Outline.DefaultOutlineTransparency
			Outline.FillTransparency = self.Settings.Outline.DefaultFillTransparency

			local a0 = Instance.new("Attachment", newBall)
			local a1 = Instance.new("Attachment", newBall)
			a0.Position = Vector3.new(0, 1, 0)
			a1.Position = Vector3.new(0, -1, 0)

			local Trail = Instance.new("Trail", newBall)
			Trail.FaceCamera = true
			Trail.Color = ColorSequence.new(table.unpack(self.Settings.Trail.DefaultTrailColor))
			Trail.Transparency = NumberSequence.new(table.unpack(self.Settings.Trail.DefaultTrailTransparency))
			Trail.WidthScale = NumberSequence.new(1, 0)
			Trail.Lifetime = self.Settings.Trail.DefaultTrailLifetime
			Trail.Attachment0 = a0
			Trail.Attachment1 = a1

			self.Settings.Locate.ChildRemoved:Connect(function(child)
				if (child and child:IsA("Part") and child.Name == self.Settings.Name and script:FindFirstChild(self.Settings.Name) and not child:IsDescendantOf(self.Settings.Locate)) or (child == BallObject) then
					BallObject = script:WaitForChild(self.Settings.Name):Clone()
					BallObject.Parent = self.Settings.Locate
				end
			end)

			BallObject = script:WaitForChild(self.Settings.Name):Clone()
			BallObject.Parent = self.Settings.Locate

			BallObject:WaitForChild("Speed"):GetPropertyChangedSignal("Value"):Connect(function()
				BallObject.Speed.Value = math.min(BallService.Settings.Speed.MaxSpeed, BallObject.Speed.Value)
			end)
		end
		if BallService.Settings.Curve.UseCurve then
			self.alpha = 0
		else
			self.alpha = self.Settings.Speed.alpha
		end
		if BallObject:WaitForChild("Speed").Value <= 0 then BallObject:WaitForChild("Speed").Value = self.Settings.Speed.DefaultSpeed end
	elseif self.Settings.Locate and not self.Settings.Locate:FindFirstChild(self.Settings.Name) then
		repeat task.wait() until self.Settings.Locate:FindFirstChild(self.Settings.Name) -- wait from server initialize
		BallObject = self.Settings.Locate:WaitForChild(self.Settings.Name, 5) -- timeout 5 seconds
	end
end

function BallService:Set(options: typeof(BallService.Settings)): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	for i,v: any in pairs(options) do
		if self.Settings[i] ~= nil and i ~= "isPlaying" then
			if typeof(self.Settings[i]) ~= typeof(v) then
				warn(`Unable to set {i}, expected {typeof(self.Settings[i])} got {typeof(v)}.`)
				continue
			end
			if typeof(v) == "table" then
				for k,x in pairs(v) do
					if self.Settings[i][k] ~= nil and k ~= "isPlaying" then
						if typeof(self.Settings[i][k]) ~= typeof(x) then
							warn(`Unable to set {k}, expected {typeof(self.Settings[i][k])} got {typeof(x)}.`)
							continue
						end
						self.Settings[i][k] = x
						if k == "Silent" then
							RunService:Silent(x)
						elseif k == "TestMode" or k == "TestDummy" then
							self:UpdatePlayers()
						elseif k == "alpha" then
							if self.Settings.Curve.UseCurve then
								self.alpha = 0
							else
								self.alpha = x
							end
						end
					end
				end
			else
				self.Settings[i] = v
				if i == "Silent" then
					RunService:Silent(v)
				elseif i == "TestMode" or i == "TestDummy" then
					self:UpdatePlayers()
				elseif i == "alpha" then
					if self.Settings.Curve.UseCurve then
						self.alpha = 0
					else
						self.alpha = v
					end
				end
			end
		end
	end
end

function BallService:SetPast(objectPast: Model): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not objectPast then error("Missing argument #1", 2) end
	if not objectPast:IsA("Model") then error(`Expected argument #1 as Model got {objectPast.ClassName}.`, 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	if not BallObject:FindFirstChild("Target") then error("Failed to set past.", 2) end
	BallObject:WaitForChild("Past").Value = objectPast
end

function BallService:SetTarget(objectTarget: Model): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not objectTarget then error("Missing argument #1", 2) end
	if not objectTarget:IsA("Model") then error(`Expected argument #1 as Model got {objectTarget.ClassName}.`, 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	if not BallObject:FindFirstChild("Target") then error("Failed to set target.", 2) end
	BallObject:WaitForChild("Target").Value = objectTarget
	self:UpdatePlayers()
end

function BallService:SetEasingDirection(easingDirection: Enum.EasingDirection): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not easingDirection then error("Missing argument #1", 2) end
	if typeof(easingDirection) ~= "EnumItem" then error(`Expected type of argument #1 as EnumItem got {typeof(easingDirection)}.`, 2) end
	self.Settings.EasingDirection = easingDirection
end

function BallService:SetEasingStyle(easingStyle: Enum.EasingStyle): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not easingStyle then error("Missing argument #1", 2) end
	if typeof(easingStyle) ~= "EnumItem" then error(`Expected type of argument #1 as EnumItem got {typeof(easingStyle)}.`, 2) end
	self.Settings.EasingStyle = easingStyle
end

function BallService:SetSpeed(speed: number): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not speed then error("Missing argument #1", 2) end
	if typeof(speed) ~= "number" then error(`Expected type of argument #1 as number got {typeof(speed)}.`, 2) end
	if speed < 0.5 then error(`Expected argument #1 with minimum 0.5 got {speed}`, 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	if not BallObject:FindFirstChild("Speed") then error("Failed to set speed.", 2) end
	BallObject:WaitForChild("Speed").Value = speed
end

function BallService:SetColor(color: Color3): ()
	if not BallObject then error("Service not initialized yet.", 2) end
	if not color then error("Missing argument #1", 2) end
	if typeof(color) ~= "Color3" then error(`Expected type of argument #1 as Color3 got {typeof(color)}.`, 2) end
	BallObject.Color = color
end

function BallService:SetOutline(outlineColor: Color3, outlineTransparency: number?): ()
	if not BallObject then error("Service not initialized yet.", 2) end
	if not outlineColor then error("Missing argument #1", 2) end
	if typeof(outlineColor) ~= "Color3" then error(`Expected type of argument #1 as Color3 got {typeof(outlineColor)}.`, 2) end
	BallObject.Outline.OutlineColor = outlineColor
	if outlineTransparency then
		if typeof(outlineTransparency) ~= "number" then error(`Expected type of argument #2 as number got {typeof(outlineTransparency)}.`, 2) end
		BallObject.Outline.OutlineTransparency = outlineTransparency
	end
end

function BallService:SetFill(fillColor: Color3, fillTransparency: number?): ()
	if not BallObject then error("Service not initialized yet.", 2) end
	if not fillColor then error("Missing argument #1", 2) end
	if typeof(fillColor) ~= "Color3" then error(`Expected type of argument #1 as Color3 got {typeof(fillColor)}.`, 2) end
	BallObject.Outline.FillColor = fillColor
	if fillTransparency then
		if typeof(fillTransparency) ~= "number" then error(`Expected type of argument #2 as number got {typeof(fillTransparency)}.`, 2) end
		BallObject.Outline.FillTransparency = fillTransparency
	end
end

function BallService:SetTrail(trailColor: {Color3}, trailTransparency: {number}?): ()
	if not BallObject then error("Service not initialized yet.", 2) end
	if not trailColor then error("Missing argument #1", 2) end
	if typeof(trailColor) ~= "table" then error(`Expected type of argument #1 as table got {typeof(trailColor)}.`, 2) end
	if #trailColor == 0 then error("table can't be empty.", 2) end
	BallObject.Trail.Color = ColorSequence.new(table.unpack(trailColor))
	if trailTransparency then
		if typeof(trailTransparency) ~= "table" then error(`Expected type of argument #2 as table got {typeof(trailTransparency)}.`, 2) end
		if #trailTransparency then error("table can't be empty.", 2) end
		BallObject.Trail.Transparency = NumberSequence.new(table.unpack(trailTransparency))
	end
end

function BallService:ClearEffects(): ()
	if not BallObject then error("Service not initialized yet.", 2) end
	for _, particle in pairs(BallObject:GetDescendants()) do
		if particle and particle:IsA("ParticleEmitter") then
			particle:Destroy()
		end
	end
end

function BallService:SetEffects(particleEmitters: Folder): ()
	if not BallObject then error("Service not initialized yet.", 2) end
	if not particleEmitters then error("Missing argument #1", 2) end
	if not particleEmitters:IsA("Folder") then error(`Expected type of argument #1 as Folder got {particleEmitters.ClassName}.`, 2) end
	if #particleEmitters:GetChildren() == 0 then error("Folder can't be empty.", 2) end
	for _, particle in pairs(particleEmitters:GetChildren()) do
		if particle and particle:IsA("ParticleEmitter") then
			particle:Clone().Parent = BallObject
		end
	end
end

function BallService:SetTest(onTest: boolean, testDummy: Model?)
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Service not initialized yet.", 2) end
	if typeof(onTest) ~= "boolean" then error(`Expected type of argument #1 as boolean got {typeof(onTest)}.`, 2) end
	BallService.Settings.Test.TestMode = onTest
	if testDummy then
		if not testDummy:IsA("Model") then error(`Expected type of argument #2 as Model got {testDummy.ClassName}.`, 2) end
		if not testDummy.PrimaryPart then error("TestDummy Model must have PrimaryPart attached.", 2) end
		BallService.Settings.Test.TestDummy = testDummy
	end
end

function BallService:Anchor(option: boolean)
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	if typeof(option) ~= "boolean" then error(`Expected type of argument #1 as boolean got {typeof(option)}.`, 2) end
	BallObject.Anchored = option
end

function BallService:Freeze()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	self:Stop()
	self:Anchor()
end

function BallService:GetLocate(): Vector3?
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Couldn't find Ball Object.", 2) end
	return BallObject.Position
end

function BallService:UpdatePlayers(): ()
	table.clear(self._Players)
	for _, plr: Player in pairs(Players:GetPlayers()) do
		if plr and plr.Character and self:IsTargetAlive(plr.Character) and not table.find(self._Players, plr.Character) then
			table.insert(self._Players, plr.Character)
		end
	end
	if self.Settings.Test.TestMode and self.Settings.Test.TestDummy and self.Settings.Test.TestDummy:IsA("Model") and self.Settings.Test.TestDummy.Parent ~= nil and self:IsTargetAlive(self.Settings.Test.TestDummy) and not table.find(self._Players, self.Settings.Test.TestDummy) then
		table.insert(self._Players, self.Settings.Test.TestDummy)
	end
	self.isPlayable = (#self._Players >= self.Settings.MinimumPlayers)
end

function BallService:Reset(): ()
	BallObject.Value.Value = 3
	RunService:UnbindFromPostSimulation("PlayBall")
	BallObject.Target.Value = nil
	BallObject.Speed.Value = self.Settings.Speed.DefaultSpeed
	if self.Settings.Curve.UseCurve then
		self.alpha = 0
	else
		self.alpha = self.Settings.Speed.alpha
	end
	repeat BallObject.Position = self.Settings.DefaultPos task.wait() until BallObject.Position == self.Settings.DefaultPos
	self:UpdatePlayers()
	BallObject.Value.Value = 0
end

function BallService:Play(): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Service not initialized yet.", 2) end
	self:UpdatePlayers()
	if #self._Players < self.Settings.MinimumPlayers then return warn(`Not enough players (require {self.Settings.MinimumPlayers} players)`) end
	self.Settings.isPlaying = true
end

function BallService:Stop(): ()
	if not RunService:IsServer() then error("This function only for Server-side", 2) end
	if not BallObject then error("Service not initialized yet.", 2) end
	self.Settings.isPlaying = false
	OnStopSignal:Fire()
end

function BallService:IsPlaying(): boolean
	return self.Settings.isPlaying
end

function BallService:GetPast(): Model
	if not BallObject then error("Service not initialized yet.", 2) end
	return BallObject.Past.Value
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
		return (BallObject.Target.Value and true or false) :: boolean
	end

	function getTarget(): boolean
		return (BallObject and getRandom(BallObject.Target.Value) or false) :: boolean
	end

	function CalcHeight(basePos: BasePart, targetPos: BasePart): number
		local q = (basePos.Position.Y-targetPos.Position.Y)*Rand:NextNumber(0.5, 2)
		if q <= BallService.Settings.Curve.MinHeightCurve then
			q = BallService.Settings.Curve.MaxHeightCurve
		end
		return (q < 0 and Rand:NextInteger(q, -q) or Rand:NextInteger(-q, q))
	end

	-- https://www.gamedeveloper.com/business/how-to-work-with-bezier-curve-in-games-with-unity

	local function QuadraticBezierCurveLogic(p0: Vector3, p1: Vector3, p2: Vector3, step: number): Vector3
		local u = 1 - step
		local tt = step
		local uu = u^2
		local p = uu * p0 -- (1-step)^2 * p0
		p += 2 * u * step * p1 -- 2 * (1-step) * step * p1
		p += tt * p2 -- step^2 * p2
		return p
	end

	function CubicBezierCurveLogic(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, step: number)
		local u = 1 - step
		local tt = step^2
		local uu = u^2
		local uuu = uu * u
		local ttt = tt * step
		local p = uuu * p0
		p += 3 * uu * step * p1
		p += 3 * u * tt * p2
		p += ttt * p3
		return p
	end

	function CurveSimulation(basePos: BasePart, targetPos: BasePart, alpha: number?): Vector3?
		if (not basePos) or (not targetPos) then return end
		if BallService.Settings.Curve.Vector3Curve then
			if (basePos.Position-targetPos.Position).X < 0 and (basePos.Position-targetPos.Position).Z < 0 then
				return ((targetPos.Position-basePos.Position)/(Rand:NextNumber(1, 2)))+Vector3.new(Rand:NextInteger(BallService.Settings.Curve.MinHeightCurve, BallService.Settings.Curve.MaxHeightCurve), Rand:NextInteger(BallService.Settings.Curve.MinHeightCurve, BallService.Settings.Curve.MaxHeightCurve), Rand:NextInteger(BallService.Settings.Curve.MinHeightCurve, BallService.Settings.Curve.MaxHeightCurve))
			else
				return ((basePos.Position-targetPos.Position)/(Rand:NextNumber(1, 2)))+Vector3.new(Rand:NextInteger(BallService.Settings.Curve.MinHeightCurve, BallService.Settings.Curve.MaxHeightCurve), Rand:NextInteger(BallService.Settings.Curve.MinHeightCurve, BallService.Settings.Curve.MaxHeightCurve), Rand:NextInteger(BallService.Settings.Curve.MinHeightCurve, BallService.Settings.Curve.MaxHeightCurve))
			end
		elseif alpha then
			local resultPos: Vector3
			if BallService.Settings.Curve.CubicCurve then
				local controlPoint = Vector3.new(
					(basePos.Position.X + targetPos.Position.X) / 1.5,
					basePos.Position.Y + BallService.CurveCache[2],
					(basePos.Position.Z + targetPos.Position.Z) / 1.5
				)
				local controlPoint2 = Vector3.new(
					(basePos.Position.X + targetPos.Position.X) / 2,
					basePos.Position.Y + (BallService.CurveCache[2]*1.5),
					(basePos.Position.Z + targetPos.Position.Z) / 2
				)
				resultPos = CubicBezierCurveLogic(basePos.Position, controlPoint, controlPoint2, targetPos.Position, alpha)
			else
				if (basePos.Position-targetPos.Position).X < 0 and (basePos.Position-targetPos.Position).Z < 0 then
					resultPos = QuadraticBezierCurveLogic(basePos.Position, ((targetPos.Position-basePos.Position)/BallService.CurveCache[1])+Vector3.new(BallService.CurveCache[2], BallService.CurveCache[3], BallService.CurveCache[4]), targetPos.Position, alpha)
				else
					resultPos = QuadraticBezierCurveLogic(basePos.Position, ((basePos.Position-targetPos.Position)/BallService.CurveCache[1])+Vector3.new(BallService.CurveCache[2], BallService.CurveCache[3], BallService.CurveCache[4]), targetPos.Position, alpha)
				end
			end
			return resultPos
		end
		return
	end

	function FollowTarget(delta: number): ()
		past_tick = tick()
		if BallService.Settings.isPlaying and BallObject then
			if BallObject.Target.Value and BallObject.Target.Value.PrimaryPart and BallService:IsTargetAlive(BallObject.Target.Value) then
				if (BallObject.Position-BallObject.Target.Value.PrimaryPart.Position).Magnitude < BallService.Settings.MinMagnitudeToKill then
					BallObject.Target.Value.Humanoid.Health -= BallService.Settings.DamageToTarget
					BallService:Reset()
					return
				end
				if BallService.Settings.Curve.UseCurve then
					if BallService.CurveCache then
						if BallService.Settings.Curve.Vector3Curve and BallService.CurveCache[2] ~= nil then
							BallService.CurveCache[2]:UpdateCurves()
							if (BallService.CurveCache[2].TotalTime-((past_tick-BallService.CurveCache[1]) % BallService.CurveCache[2].TotalTime)) <= 0.005 then
								TweenService:Create(BallObject, TweenInfo.new(0.05, BallService.Settings.EasingStyle, BallService.Settings.EasingDirection), { Position = BallObject.Target.Value.PrimaryPart.Position }):Play()
								BallService.CurveCache[1] = tick()
								BallService.PreviousPos = BallObject.Past.Value.PrimaryPart
								BallService.CurveCache[2]:SetSpeed(BallService.Settings.Speed.DefaultSpeed*(BallService.Settings.Curve.CurveBoost*2)) -- double the speed
								BallService.CurveCache[2]:UpdateCurves()
							else
								local toPos = BallService.CurveCache[2]:Tween((past_tick-BallService.CurveCache[1]) % BallService.CurveCache[2].TotalTime, BallService.Settings.EasingStyle, BallService.Settings.EasingDirection) :: Vector3
								if toPos and BallObject.Position ~= toPos then
									BallObject.Position = toPos
								else
									BallObject.Position = BallObject.Target.Value.PrimaryPart.Position
								end
							end
						elseif #BallService.CurveCache > 0 then
							BallService.alpha += (BallService.Settings.Speed.baseQuadraticAlphaStep)*(BallObject.Speed.Value/1.25)
							local toPos = CurveSimulation(BallObject, BallObject.Target.Value.PrimaryPart, math.min(1, BallService.alpha)) :: Vector3
							if toPos and BallObject.Position ~= toPos then
								BallObject.Position = toPos
							else
								BallObject.Position = BallObject.Target.Value.PrimaryPart.Position
							end
						end
					end
				else
					BallService.alpha += (delta/BallService.Settings.Speed.ThrottlingDelta)
					TweenService:Create(BallObject, TweenInfo.new(math.min(BallService.Settings.Speed.MaxTweenSpeed, math.max(BallService.Settings.Speed.MinTweenSpeed, (BallService.alpha/BallObject.Speed.Value)/BallService.Settings.Speed.ThrottlingSpeed)), BallService.Settings.EasingStyle, BallService.Settings.EasingDirection), { Position = BallObject.Target.Value.PrimaryPart.Position }):Play()
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
				BallObject.Past.Value = BallObject.Target.Value
				if not getTarget() then
					BallObject.Value.Value = 0
					return
				end
				BallService.PreviousPos = BallObject.Position
				if BallService.Settings.Curve.UseCurve then
					if BallService.Settings.Curve.Vector3Curve then
						BallService.CurveCache[1] = tick()
						BallService.CurveCache[2] = FloatCurve.new({BallObject, CurveSimulation(BallObject, BallObject.Target.Value.PrimaryPart), BallObject.Target.Value.PrimaryPart}, BallObject.Speed.Value*BallService.Settings.Curve.CurveBoost) :: (any)
					else
						BallService.CurveCache[1] = Rand:NextNumber(1, 2)
						BallService.CurveCache[2] = CalcHeight(BallObject, BallObject.Target.Value.PrimaryPart)
						BallService.CurveCache[3] = CalcHeight(BallObject, BallObject.Target.Value.PrimaryPart)
						BallService.CurveCache[4] = CalcHeight(BallObject, BallObject.Target.Value.PrimaryPart)
						BallService.CurveCache[5] = Rand:NextNumber(1.5, 2.5)
					end
				end
				RunService:BindToPostSimulation("PlayBall", 1, FollowTarget)
			elseif BallObject.Value.Value == 1 then
				if BallService.Settings.Curve.UseCurve then
					BallService.alpha = 0
				end
				RunService:UnbindFromPostSimulation("PlayBall")
				BallObject.Value.Value = 0
			end
		end
	end)
end

return BallService :: typeof(BallService)
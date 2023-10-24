--!strict
local FloatCurves = {}
FloatCurves.__index = FloatCurves

local TweenService = game:GetService("TweenService")

function FloatCurves.new(Objects: {any}, Speed: number)
	local self = setmetatable({}, FloatCurves)
	if not Objects or typeof(Objects) ~= "table" then return end
	if not Speed or typeof(Speed) ~= "number" then Speed = 1 end
	
	self.Curve = Instance.new("Vector3Curve")
	self.TotalTime = 0
	self.Objects = Objects
	self.Speed = Speed

	local CurveX, CurveY, CurveZ = self.Curve:X(), self.Curve:Y(), self.Curve:Z()
	for i,v in pairs(Objects) do
		if i > 1 then
			local t = 0
			if typeof(v) == "Vector3" then
				local prev = Objects[i - 1]
				if prev and typeof(prev) ~= "Vector3" and prev:IsA("BasePart") then
					t = ((v - Objects[i - 1].Position).Magnitude / Speed)
				elseif prev then
					t = ((v - Objects[i - 1]).Magnitude / Speed)
				end
			elseif v:IsA("BasePart") then
				local prev = Objects[i - 1]
				if prev and typeof(prev) ~= "Vector3" and prev:IsA("BasePart") then
					t = ((v.Position - Objects[i - 1].Position).Magnitude / Speed)
				elseif prev then
					t = ((v.Position - Objects[i - 1]).Magnitude / Speed)
				end
			end
			self.TotalTime += t
		end
		if typeof(v) == "Vector3" then
			CurveX:InsertKey(FloatCurveKey.new(self.TotalTime, v.X, Enum.KeyInterpolationMode.Linear))
			CurveY:InsertKey(FloatCurveKey.new(self.TotalTime, v.Y, Enum.KeyInterpolationMode.Linear))
			CurveZ:InsertKey(FloatCurveKey.new(self.TotalTime, v.Z, Enum.KeyInterpolationMode.Linear))
		elseif v:IsA("BasePart") then
			CurveX:InsertKey(FloatCurveKey.new(self.TotalTime, v.Position.X, Enum.KeyInterpolationMode.Linear))
			CurveY:InsertKey(FloatCurveKey.new(self.TotalTime, v.Position.Y, Enum.KeyInterpolationMode.Linear))
			CurveZ:InsertKey(FloatCurveKey.new(self.TotalTime, v.Position.Z, Enum.KeyInterpolationMode.Linear))
		end
	end
	return self :: typeof(self)
end

function FloatCurves:SetSpeed(Speed: number)
	self.Speed = Speed
end

function FloatCurves:UpdateCurves()
	local CurveX, CurveY, CurveZ = self.Curve:X(), self.Curve:Y(), self.Curve:Z()
	CurveX:RemoveKeyAtIndex(1, #CurveX:GetKeys())
	CurveY:RemoveKeyAtIndex(1, #CurveX:GetKeys())
	CurveZ:RemoveKeyAtIndex(1, #CurveZ:GetKeys())
	self.TotalTime = 0
	for i,v: any in pairs(self.Objects) do
		if i > 1 then
			local t = 0
			if typeof(v) == "Vector3" then
				local prev = self.Objects[i - 1]
				if prev and typeof(prev) ~= "Vector3" and prev:IsA("BasePart") then
					t = ((v - self.Objects[i - 1].Position).Magnitude / self.Speed)
				elseif prev then
					t = ((v - self.Objects[i - 1]).Magnitude / self.Speed)
				end
			elseif v:IsA("BasePart") then
				local prev = self.Objects[i - 1]
				if prev and typeof(prev) ~= "Vector3" and prev:IsA("BasePart") then
					t = ((v.Position - self.Objects[i - 1].Position).Magnitude / self.Speed)
				elseif prev then
					t = ((v.Position - self.Objects[i - 1]).Magnitude / self.Speed)
				end
			end
			self.TotalTime += t
		end
		if typeof(v) == "Vector3" then
			CurveX:InsertKey(FloatCurveKey.new(self.TotalTime, v.X, Enum.KeyInterpolationMode.Linear))
			CurveY:InsertKey(FloatCurveKey.new(self.TotalTime, v.Y, Enum.KeyInterpolationMode.Linear))
			CurveZ:InsertKey(FloatCurveKey.new(self.TotalTime, v.Z, Enum.KeyInterpolationMode.Linear))
		elseif v:IsA("BasePart") then
			CurveX:InsertKey(FloatCurveKey.new(self.TotalTime, v.Position.X, Enum.KeyInterpolationMode.Linear))
			CurveY:InsertKey(FloatCurveKey.new(self.TotalTime, v.Position.Y, Enum.KeyInterpolationMode.Linear))
			CurveZ:InsertKey(FloatCurveKey.new(self.TotalTime, v.Position.Z, Enum.KeyInterpolationMode.Linear))
		end
	end
end

function FloatCurves:PositionFromTime(CurveTime: number): Vector3?
	if not CurveTime then return end
	return Vector3.new(table.unpack(self.Curve:GetValueAtTime(CurveTime)))
end

function FloatCurves:Tween(CurveTime: number, EasingStyle: Enum.EasingStyle, EasingDirection: Enum.EasingDirection): Vector3?
	if not CurveTime then return end
	local Alpha = CurveTime / self.TotalTime
	local CurveTween = TweenService:GetValue(Alpha, EasingStyle, EasingDirection)
	local ActualCurveTime = CurveTween * self.TotalTime
	return self:PositionFromTime(ActualCurveTime)
end

function FloatCurves:Destroy()
	setmetatable(self, nil)
end

return FloatCurves :: typeof(FloatCurves)
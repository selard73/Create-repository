-- rockfalls1.lua (Oct 22 2026): Shannon, circling a pale blue box on top of the boulders at the head of the Tea Hills stream:
-- "I don't know what this is but it needs to be fixed". It was the old part-built waterfall (TeaHills."Waterfall curtain", a
-- 12 x 24 glass panel, + 5 "Waterfall ribbon" strips) standing inside JP_Waterfall_Rockface, only its top showing.
-- Now: TeaHills."Rock face waterfall" - water pouring from the gap between the two middle boulders (lip y 19.6) in an arc that
-- clears the boulders' bulge, into the stream pool (water y 1.09): three layered flowing Beams like the canal falls
-- (MomijiGarden.CanalFalls3: smoke_main texture scrolling, pale blue-white), a foam patch (CanalFalls3's Fall_Foam, scaled), mist +
-- spray at the foot. The old panel + strips move whole to ServerStorage.HudBackup.FallsPlaceholder_pre_rockfalls1.
-- Re-runnable (the waterfall is rebuilt). "QQ ROCKFALLS1".
local J = workspace.JapanMap
local TH = J.TeaHills
local HB = game:GetService("ServerStorage").HudBackup
local out = {}
local function say(s) table.insert(out, "QQ ROCKFALLS1 " .. s) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before rockfalls1") end)

local bk = HB:FindFirstChild("FallsPlaceholder_pre_rockfalls1")
local moved = 0
for _, d in ipairs(TH:GetChildren()) do
	if d:IsA("BasePart") and (d.Name == "Waterfall curtain" or d.Name == "Waterfall ribbon") and math.abs(d.Position.X - 5764) < 10 then
		if not bk then bk = Instance.new("Folder"); bk.Name = "FallsPlaceholder_pre_rockfalls1"; bk.Parent = HB end
		d:SetAttribute("RockFalls1From", d:GetFullName())
		d.Parent = bk
		moved += 1
	end
end
say(moved .. " placeholder pieces (glass panel + strips) moved to HudBackup.FallsPlaceholder_pre_rockfalls1")
local old = TH:FindFirstChild("Rock face waterfall"); if old then old:Destroy() end

local LIP = Vector3.new(5764, 19.6, -243.2)
local FOOT = Vector3.new(5764, 1.3, -234.6)
local WATER_Y = 1.09
local M = Instance.new("Model"); M.Name = "Rock face waterfall"
local anchor = Instance.new("Part")
anchor.Name = "FallsAnchor"; anchor.Size = Vector3.new(1, 1, 1); anchor.CFrame = CFrame.new(LIP)
anchor.Anchored = true; anchor.Transparency = 1; anchor.CanCollide = false; anchor.CanQuery = false; anchor.CanTouch = false
anchor.CastShadow = false; anchor.Parent = M
-- an attachment's Axis (its X) is the water's direction of travel there: out of the gap at the lip, straight down at the pool
local a0 = Instance.new("Attachment"); a0.Name = "FallsLip"; a0.Parent = anchor
a0.WorldCFrame = CFrame.fromMatrix(LIP, Vector3.new(0, 0, 1), Vector3.new(0, 1, 0))
local a1 = Instance.new("Attachment"); a1.Name = "FallsFoot"; a1.Parent = anchor
a1.WorldCFrame = CFrame.fromMatrix(FOOT, Vector3.new(0, -1, 0), Vector3.new(0, 0, 1))
local function beam(name, w0, w1, t0, t1, speed, len)
	local b = Instance.new("Beam"); b.Name = name
	b.Attachment0 = a0; b.Attachment1 = a1
	b.CurveSize0 = 7; b.CurveSize1 = 8; b.Segments = 24
	b.FaceCamera = true
	b.Texture = "rbxasset://textures/particles/smoke_main.dds"; b.TextureMode = Enum.TextureMode.Wrap
	b.TextureLength = len; b.TextureSpeed = speed
	b.Width0 = w0; b.Width1 = w1
	b.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, t0), NumberSequenceKeypoint.new(1, t1)})
	b.Color = ColorSequence.new(Color3.fromRGB(234, 247, 255))
	b.LightEmission = 0.2; b.LightInfluence = 0.8
	b.Parent = anchor
	return b
end
beam("FallCore", 3.6, 4.6, 0.25, 0.35, 2.2, 4)
beam("FallMain", 6.2, 8.2, 0.40, 0.50, 2.8, 3.5)
beam("FallVeil", 8.0, 10.5, 0.62, 0.72, 3.6, 2.6)
-- foam on the pool where it lands
local foamSrc = J.MomijiGarden:FindFirstChild("CanalFalls3") and J.MomijiGarden.CanalFalls3:FindFirstChild("Fall_Foam")
if foamSrc then
	local foam = foamSrc:Clone()
	foam.Name = "Falls foam"
	foam.Size = Vector3.new(foamSrc.Size.X * 1.9, foamSrc.Size.Y, foamSrc.Size.Z * 1.9)
	foam.CFrame = CFrame.new(FOOT.X, WATER_Y + 0.03, FOOT.Z + 0.4)
	foam.Anchored = true; foam.CanCollide = false; foam.CanQuery = false; foam.CanTouch = false; foam.CastShadow = false
	for _, c in ipairs(foam:GetChildren()) do c:Destroy() end
	foam.Parent = M
	say(string.format("foam patch %.1f x %.1f on the pool", foam.Size.X, foam.Size.Z))
else
	say("no CanalFalls3.Fall_Foam to copy - foam skipped")
end
-- mist + spray at the foot (the canal's emitters, a size up)
local spot = Instance.new("Attachment"); spot.Name = "FallsMist"; spot.Parent = anchor
spot.WorldCFrame = CFrame.new(FOOT.X, WATER_Y + 0.4, FOOT.Z + 0.6)
local function ns(a, b) return NumberSequence.new({NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b)}) end
local spray = Instance.new("ParticleEmitter"); spray.Name = "Spray"
spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
spray.Rate = 70; spray.Lifetime = NumberRange.new(0.5, 0.9); spray.Speed = NumberRange.new(5, 9)
spray.SpreadAngle = Vector2.new(40, 40); spray.Size = ns(0.4, 0.12); spray.Transparency = ns(0.2, 1)
spray.Acceleration = Vector3.new(0, -16, 0); spray.LightEmission = 0.3; spray.EmissionDirection = Enum.NormalId.Top
spray.Parent = spot
local mist = Instance.new("ParticleEmitter"); mist.Name = "Mist"
mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
mist.Rate = 30; mist.Lifetime = NumberRange.new(1.2, 2.2); mist.Speed = NumberRange.new(1.5, 3.5)
mist.SpreadAngle = Vector2.new(70, 70); mist.Size = ns(2, 5.5); mist.Transparency = ns(0.72, 1)
mist.Acceleration = Vector3.new(0, -0.6, 0); mist.LightEmission = 0.1; mist.EmissionDirection = Enum.NormalId.Top
mist.Parent = spot
M:SetAttribute("RockFallsVersion", "rockfalls1")
M.Parent = TH
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after rockfalls1") end)
say("waterfall built: lip (5764, 19.6, -243.2) -> pool (5764, 1.3, -234.6), 3 beams, foam, mist + spray - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")

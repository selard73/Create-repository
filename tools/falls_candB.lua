-- falls_candB v1: CHANGES THE PLACE (scenery only: no scripts, no save data). A/B for the FALL: builds workspace.SouthGorge.FallsB
-- (candidate B) at the real spot and switches OFF the fall part of the live Falls model (A) - its rapids, foam, churn and
-- river mist stay on and are shared. falls_showA / falls_showB flip between them; falls_keepB / falls_dropB settle it.
-- Candidate B, from her references (Skogafoss, the basalt fall, Niagara): NOTHING wider than the notch (every beam exactly
-- corner to corner, 31.6 studs, no plugs, nothing hanging past the rock); a short teal roll at the lip; a translucent pale
-- water body instead of an opaque white sheet; two layers of a NEW high-contrast strand texture scrolling at different
-- speeds plus a sparse wisp layer in front, so the face is bright strands with darker lines between them; falling white
-- "chunks" (stretched sprites) for turbulence; the same splash, foam ring, mist, plume and mist banks at the foot.
-- The two textures come from the Import 3D carrier (workspace.falls2_carrier: Falls2Strands / Falls2Wisps MeshParts); their
-- asset ids are read from it and the carrier is removed. Re-running replaces FallsB.
local ZC, WATER_Y, SEA_Y = -547.5, -0.9, -52.9
local XL = (169.4583 + 201.2856) / 2
local WN = 31.6                                             -- corner to corner is 31.83: stay 0.1 inside each wall
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local G = workspace.SouthGorge
-- textures
local TEX1, TEX2 = "%TEX1%", "%TEX2%"
local car = workspace:FindFirstChild("falls2_carrier")
if car then
	local s, w = car:FindFirstChild("Falls2Strands", true), car:FindFirstChild("Falls2Wisps", true)
	if s and s:IsA("MeshPart") and s.TextureID ~= "" then TEX1 = s.TextureID end
	if w and w:IsA("MeshPart") and w.TextureID ~= "" then TEX2 = w.TextureID end
	car:Destroy()
end
assert(TEX1:find("rbxassetid://") and TEX2:find("rbxassetid://"), "texture ids missing: import italy/falls/falls2_carrier.obj first (TEX1=" .. TEX1 .. ")")
local old = G:FindFirstChild("FallsB"); if old then old:Destroy() end
local F = Instance.new("Model"); F.Name = "FallsB"
pcall(function() F.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
F.Parent = G
local function part(name, size, cf)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Transparency = 1; p.CastShadow = false
	p.Parent = F; return p
end
local rig = part("Rig", Vector3.new(1, 1, 1), CFrame.new(XL, -6, ZC - 3.2))
local function att(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))
	return a
end
local function seq(pts) local k = {} for _, p in ipairs(pts) do k[#k + 1] = NumberSequenceKeypoint.new(p[1], p[2]) end return NumberSequence.new(k) end
local function cseq(pts) local k = {} for _, p in ipairs(pts) do k[#k + 1] = ColorSequenceKeypoint.new(p[1], Color3.fromRGB(p[2], p[3], p[4])) end return ColorSequence.new(k) end
local function beam(o)
	local b = Instance.new("Beam"); b.Name = o.name; b.Attachment0 = o.a0; b.Attachment1 = o.a1
	b.Width0 = o.w0; b.Width1 = o.w1; b.CurveSize0 = o.c0 or 0; b.CurveSize1 = o.c1 or 0
	b.Texture = o.tex or ""; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = o.tlen or 36; b.TextureSpeed = o.speed or 0
	b.Transparency = seq(o.tr); b.Color = o.col or cseq({{0, 244, 250, 255}, {1, 244, 250, 255}})
	b.LightEmission = o.glow or 0.3; b.LightInfluence = o.lightInf or 0.6; b.Brightness = 1
	b.Segments = o.seg or 24; b.ZOffset = o.zoff or 0; b.FaceCamera = o.face or false
	b.Parent = o.a0.Parent; return b
end
-- the lip: a short dark-teal roll (Niagara), exactly the notch's width
local GREEN = cseq({{0, 150, 220, 205}, {0.12, 178, 232, 220}, {0.3, 214, 243, 240}, {0.55, 236, 248, 252}, {1, 242, 250, 255}})
beam({name = "Crest", a0 = att("TopC", Vector3.new(XL, WATER_Y - 0.05, ZC + 0.3)), a1 = att("BottomC", Vector3.new(XL, WATER_Y - 7.0, ZC - 2.6)),
	w0 = WN, w1 = WN, c0 = 3.2, col = GREEN, glow = 0.35, lightInf = 0.8, seg = 12, zoff = 0.2,
	tr = {{0, 0.35}, {0.08, 0.1}, {0.4, 0.08}, {0.75, 0.5}, {1, 1}}})
-- the water body: translucent pale blue, fading before the pool - the strands read against it, the rock shows faintly through
beam({name = "Back", a0 = att("TopK", Vector3.new(XL, WATER_Y - 1.6, ZC - 1.4)), a1 = att("BottomK", Vector3.new(XL, SEA_Y - 1.0, ZC - 6.5)),
	w0 = WN, w1 = WN, c0 = 0.8, col = cseq({{0, 168, 205, 218}, {0.5, 182, 216, 228}, {1, 200, 228, 236}}), glow = 0.15, lightInf = 0.6, zoff = -0.8,
	tr = {{0, 0.45}, {0.1, 0.4}, {0.7, 0.5}, {0.9, 0.85}, {1, 1}}})
-- strands: the new texture, two layers at different speeds (shimmer), a sparse wisp layer in front
beam({name = "Strands1", a0 = att("TopS1", Vector3.new(XL, WATER_Y - 1.2, ZC - 1.3)), a1 = att("BottomS1", Vector3.new(XL, SEA_Y - 1.5, ZC - 7.0)),
	w0 = WN, w1 = WN, c0 = 0.8, tex = TEX1, tlen = 44, speed = 1.1, glow = 0.55, lightInf = 0.5, zoff = 0,
	tr = {{0, 0.3}, {0.1, 0.05}, {0.75, 0.1}, {0.92, 0.6}, {1, 1}}})
beam({name = "Strands2", a0 = att("TopS2", Vector3.new(XL + 0.9, WATER_Y - 1.4, ZC - 1.5)), a1 = att("BottomS2", Vector3.new(XL + 0.9, SEA_Y - 0.5, ZC - 6.0)),
	w0 = WN - 1.8, w1 = WN - 1.8, c0 = 0.8, tex = TEX1, tlen = 32, speed = 1.6, glow = 0.5, lightInf = 0.5, zoff = -0.3,
	tr = {{0, 0.5}, {0.1, 0.3}, {0.75, 0.35}, {0.92, 0.75}, {1, 1}}})
beam({name = "Wisps", a0 = att("TopW", Vector3.new(XL, WATER_Y - 1.0, ZC - 1.1)), a1 = att("BottomW", Vector3.new(XL, SEA_Y - 2.0, ZC - 7.6)),
	w0 = WN, w1 = WN, c0 = 0.9, c1 = 1.5, tex = TEX2, tlen = 56, speed = 0.85, glow = 0.6, lightInf = 0.4, zoff = 0.4,
	tr = {{0, 0.6}, {0.1, 0.2}, {0.7, 0.25}, {0.9, 0.7}, {1, 1}}})
-- particles
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE; e.LightEmission = 0.3; e.LightInfluence = 0.3; e.ZOffset = 0
	e.Color = ColorSequence.new(Color3.fromRGB(242, 249, 255))
	for k, v in pairs(props) do pcall(function() e[k] = v end) end
	e.Parent = parent; return e
end
-- falling chunks: soft white sprites stretched along their fall, the turbulence in her basalt-fall photo
for i, dx in ipairs({-8, 8}) do
	local ch = part("Chunks" .. i, Vector3.new(14, 1, 1), CFrame.new(XL + dx, WATER_Y - 3, ZC - 2.0))
	emitter(ch, {Rate = 26, Lifetime = NumberRange.new(1.3, 1.7), Speed = NumberRange.new(32, 44), SpreadAngle = Vector2.new(6, 3),
		EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = seq({{0, 1.0}, {1, 1.8}}), Squash = seq({{0, 2.2}, {1, 2.8}}), Transparency = seq({{0, 0.35}, {0.6, 0.45}, {1, 1}}),
		LightEmission = 0.55, LightInfluence = 0.3, Acceleration = Vector3.new(0, -8, -1.5), ZOffset = 0.6})
end
-- spray thrown up and out at the lip
local spray = part("Spray", Vector3.new(28, 1, 2), CFrame.new(XL, WATER_Y + 0.6, ZC - 0.6) * CFrame.Angles(math.rad(35), 0, 0))
emitter(spray, {Rate = 14, Lifetime = NumberRange.new(0.5, 1.0), Speed = NumberRange.new(5, 9), SpreadAngle = Vector2.new(25, 25),
	EmissionDirection = Enum.NormalId.Front, Size = seq({{0, 0.8}, {1, 3.5}}), Transparency = seq({{0, 0.55}, {1, 1}}),
	Acceleration = Vector3.new(0, -14, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20)})
-- the foot: splash, foam ring, mist, plume, two mist banks (as the first-round fall)
local splash = part("Splash", Vector3.new(30, 1, 5), CFrame.new(XL, SEA_Y + 0.3, ZC - 6.5))
emitter(splash, {Rate = 28, Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(8, 14), SpreadAngle = Vector2.new(60, 60),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 2}, {1, 6}}), Transparency = seq({{0, 0.45}, {0.6, 0.7}, {1, 1}}),
	LightEmission = 0.4, LightInfluence = 0.2, Acceleration = Vector3.new(0, -20, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30)})
local ring = part("FoamRing", Vector3.new(44, 0.5, 20), CFrame.new(XL, SEA_Y + 0.4, ZC - 12))
emitter(ring, {Rate = 18, Lifetime = NumberRange.new(2.2, 3.2), Speed = NumberRange.new(0.5, 1.0), SpreadAngle = Vector2.new(12, 12),
	EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, ZOffset = 0.5,
	Size = seq({{0, 4}, {1, 8}}), Transparency = seq({{0, 0.5}, {0.6, 0.7}, {1, 1}}), LightEmission = 0.4, LightInfluence = 0.2,
	Acceleration = Vector3.new(0, -0.3, -0.8), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-15, 15)})
local mist = part("Mist", Vector3.new(34, 3, 14), CFrame.new(XL, SEA_Y + 1.5, ZC - 8))
emitter(mist, {Rate = 11, Lifetime = NumberRange.new(2, 3.2), Speed = NumberRange.new(2.5, 5), SpreadAngle = Vector2.new(55, 55),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 5}, {1, 10}}), Transparency = seq({{0, 1}, {0.15, 0.7}, {1, 1}}),
	Acceleration = Vector3.new(0, 1.2, -1.0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-15, 15),
	Color = ColorSequence.new(Color3.fromRGB(230, 241, 247))})
local plume = part("Plume", Vector3.new(26, 2, 10), CFrame.new(XL, SEA_Y + 3, ZC - 7))
emitter(plume, {Rate = 3, Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(40, 40),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 8}, {1, 10}}), Transparency = seq({{0, 1}, {0.3, 0.88}, {1, 1}}),
	Acceleration = Vector3.new(0, 0.9, -0.6), Drag = 0.5, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-6, 6)})
beam({name = "MistBank", a0 = att("MistLo", Vector3.new(XL, SEA_Y + 0.5, ZC - 7)), a1 = att("MistHi", Vector3.new(XL, SEA_Y + 16, ZC - 9)),
	w0 = 36, w1 = 46, tex = SMOKE, tlen = 16, speed = -0.2, face = true, glow = 0.1, seg = 6, zoff = 0.3,
	col = cseq({{0, 240, 247, 252}, {1, 240, 247, 252}}), tr = {{0, 0.7}, {0.5, 0.82}, {1, 1}}})
beam({name = "MistBank2", a0 = att("MistLo2", Vector3.new(XL, SEA_Y + 0.3, ZC - 9)), a1 = att("MistHi2", Vector3.new(XL, SEA_Y + 7, ZC - 11)),
	w0 = 42, w1 = 48, tex = SMOKE, tlen = 14, speed = -0.15, face = true, glow = 0.1, seg = 4, zoff = 0.4,
	col = cseq({{0, 240, 247, 252}, {1, 240, 247, 252}}), tr = {{0, 0.55}, {0.6, 0.75}, {1, 1}}})
-- switch A's fall part off (rapids stay); falls_showA puts it back
local A = G:FindFirstChild("Falls")
local offB, offE = 0, 0
local A_BEAMS = {Crest = 1, Body = 1, Sheet2 = 1, Ribbon1 = 1, Ribbon2 = 1, Ribbon3 = 1, Ribbon4 = 1, MistBank = 1, MistBank2 = 1, PlugE = 1, PlugW = 1}
local A_PARTS = {Spray = 1, Mist = 1, Plume = 1, Splash = 1, FoamRing = 1}
if A then
	for _, d in ipairs(A:GetDescendants()) do
		if d:IsA("Beam") and A_BEAMS[d.Name] then d.Enabled = false; offB += 1
		elseif d:IsA("ParticleEmitter") and A_PARTS[d.Parent.Name] then d.Enabled = false; offE += 1 end
	end
end
local nb, ne = 0, 0
for _, d in ipairs(F:GetDescendants()) do if d:IsA("Beam") then nb += 1 elseif d:IsA("ParticleEmitter") then ne += 1 end end
print(string.format("QQ CB1 FallsB built: %d beams, %d emitters; strands %s wisps %s; width %.1f (corners 169.46..201.29); A fall part off: %d beams, %d emitters", nb, ne, TEX1, TEX2, WN, offB, offE))
print("QQ CB1 DONE")

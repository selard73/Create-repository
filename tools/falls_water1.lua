-- falls_water1: CHANGES THE PLACE (scenery only: no scripts, no save data): the falling water at the gorge's end,
-- in workspace.SouthGorge.Falls. Rapids on the last 38 studs of river, a crest and three water beams from the lip to the plunge pool (a front sheet, a slower back
-- layer, a faint wide veil), spray at the lip and mist and a slow plume at the base (ParticleEmitters with the
-- client's built-in smoke texture). The beams use our own streaky texture (italy/falls/falls.png, uploaded by the
-- importer). The importer's carrier quad is removed. Re-running replaces the folder.
local TEX = "rbxassetid://129457182364461"
local CXE, ZC, WATER_Y, SEA_Y = 183.84, -547.5, -0.9, -52.9
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local G = workspace.SouthGorge
local old = G:FindFirstChild("Falls"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "Falls"; F.Parent = G
local function part(name, size, cf)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Transparency = 1; p.CastShadow = false
	p.Parent = F; return p
end
local rig = part("Rig", Vector3.new(1, 1, 1), CFrame.new(CXE, -20, ZC))
-- attachment frame: Axis (X) points SOUTH (the curve pushes the top of the sheet forward over the sill),
-- SecondaryAxis (Y) points EAST (the beam's width runs across the river)
local function att(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))
	return a
end
local function seq(pts)
	local kps = {}
	for _, p in ipairs(pts) do kps[#kps + 1] = NumberSequenceKeypoint.new(p[1], p[2]) end
	return NumberSequence.new(kps)
end
local function beam(name, a0, a1, w0, w1, c0, c1, speed, tlen, tr, zoff, plain, col)
	local b = Instance.new("Beam"); b.Name = name; b.Attachment0 = a0; b.Attachment1 = a1
	b.Width0 = w0; b.Width1 = w1; b.CurveSize0 = c0; b.CurveSize1 = c1
	b.Texture = plain and "" or TEX; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = tlen; b.TextureSpeed = speed
	b.Transparency = tr
	b.Color = col or ColorSequence.new(Color3.fromRGB(236, 247, 255), Color3.fromRGB(208, 234, 246))
	b.LightEmission = 0.25; b.LightInfluence = 0.9; b.Brightness = 1; b.Segments = 24; b.ZOffset = zoff; b.FaceCamera = false
	b.Parent = rig; return b
end
-- the crest: a short, nearly opaque white fall right at the brink, so the river's cut-off edge (the terrain water's end
-- face, teal) never shows through the sheet's streaks
-- Horseshoe Falls (her photos): dark glossy teal right at the brink, bright mint just over the edge, white below
local GREEN = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 124, 114)), ColorSequenceKeypoint.new(0.07, Color3.fromRGB(96, 186, 170)),
	ColorSequenceKeypoint.new(0.16, Color3.fromRGB(176, 232, 222)), ColorSequenceKeypoint.new(0.3, Color3.fromRGB(230, 247, 250)), ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 250, 255))})
local MINT = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(168, 230, 220)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(226, 246, 250)), ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 249, 255))})
beam("Crest", att("TopC", Vector3.new(CXE, WATER_Y + 0.5, ZC + 0.6)), att("BottomC", Vector3.new(CXE, WATER_Y - 10.5, ZC - 2.8)),
	31.5, 31.5, 3.6, 0, 2.0, 6, seq({{0, 0.12}, {0.3, 0.06}, {0.8, 0.03}, {1, 0.45}}), 0.2, true, GREEN)       -- no texture: solid, so nothing teal shows through at the brink
beam("Sheet", att("Top", Vector3.new(CXE, WATER_Y - 2.0, ZC - 1.4)), att("Bottom", Vector3.new(CXE, SEA_Y - 1.5, ZC - 7.0)),
	31, 33, 0.8, 0, 1.6, 18, seq({{0, 0.12}, {0.12, 0.08}, {0.8, 0.14}, {1, 0.6}}), 0, false, MINT)
beam("Sheet2", att("Top2", Vector3.new(CXE, WATER_Y + 1.0, ZC - 0.2)), att("Bottom2", Vector3.new(CXE, SEA_Y - 1.5, ZC - 5.5)),
	29, 32, 1.5, 0, 1.1, 14, seq({{0, 0.45}, {0.15, 0.25}, {0.8, 0.3}, {1, 0.75}}), -0.5)
beam("Veil", att("Top3", Vector3.new(CXE, WATER_Y + 0.8, ZC - 1.4)), att("Bottom3", Vector3.new(CXE, SEA_Y - 1.0, ZC - 9.5)),
	32, 40, 2.5, 0, 2.4, 10, seq({{0, 0.86}, {0.5, 0.9}, {1, 0.98}}), 0.5)
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE; e.LightEmission = 0.1; e.LightInfluence = 0.8; e.ZOffset = 0
	e.Color = ColorSequence.new(Color3.fromRGB(242, 249, 255))
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent; return e
end
-- spray thrown off the lip
local spray = part("Spray", Vector3.new(28, 1, 2), CFrame.new(CXE, WATER_Y + 0.6, ZC - 0.6))
emitter(spray, {Rate = 24, Lifetime = NumberRange.new(0.8, 1.8), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(35, 35),
	EmissionDirection = Enum.NormalId.Front, Size = seq({{0, 2}, {1, 7}}), Transparency = seq({{0, 0.5}, {1, 1}}),
	Acceleration = Vector3.new(0, -9, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20)})
-- mist boiling up where the water lands
local mist = part("Mist", Vector3.new(34, 3, 14), CFrame.new(CXE, SEA_Y + 1.5, ZC - 8))
emitter(mist, {Rate = 20, Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(90, 90),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 6}, {1, 18}}), Transparency = seq({{0, 0.65}, {0.15, 0.5}, {1, 1}}),
	Acceleration = Vector3.new(0, 1.5, 0), Drag = 1, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-15, 15)})
-- a slow tall plume of haze
local plume = part("Plume", Vector3.new(26, 2, 10), CFrame.new(CXE, SEA_Y + 3, ZC - 7))
emitter(plume, {Rate = 4, Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(40, 40),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 14}, {1, 34}}), Transparency = seq({{0, 0.88}, {0.3, 0.84}, {1, 1}}),
	Acceleration = Vector3.new(0, 1.2, 0), Drag = 0.5, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-6, 6)})
-- the rapids: the river turns white and churning well BEFORE the brink (as at Niagara), building toward the edge.
-- Flat foam beams lie on the water (the attachment frame puts the beam's plane horizontal: width across the river,
-- the texture racing toward the brink), three layers at different speeds so the foam boils rather than slides, all
-- fading to nothing upstream; low foam puffs ride the surface and spray lifts near the edge.
local function flat(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, 1, 0), Vector3.new(1, 0, 0))      -- Axis up, SecondaryAxis east: plane = XZ
	return a
end
local FOAM = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(214, 240, 240)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(236, 248, 252)), ColorSequenceKeypoint.new(1, Color3.fromRGB(246, 252, 255))})
local layers = {
	{name = "Rapids1", start = 38, lift = 0.15, w0 = 20, w1 = 31, speed = 2.6, tlen = 9, tr = {{0, 1}, {0.2, 0.9}, {0.55, 0.6}, {0.85, 0.3}, {1, 0.15}}},
	{name = "Rapids2", start = 30, lift = 0.25, w0 = 24, w1 = 31, speed = 3.4, tlen = 6, tr = {{0, 1}, {0.25, 0.85}, {0.6, 0.5}, {1, 0.2}}},
	{name = "Rapids3", start = 20, lift = 0.35, w0 = 27, w1 = 31.5, speed = 4.4, tlen = 4.5, tr = {{0, 1}, {0.3, 0.7}, {0.7, 0.35}, {1, 0.1}}},
}
for i, L in ipairs(layers) do
	local b = Instance.new("Beam"); b.Name = L.name
	b.Attachment0 = flat(L.name .. "A", Vector3.new(CXE, WATER_Y + L.lift, ZC + L.start))
	b.Attachment1 = flat(L.name .. "B", Vector3.new(CXE, WATER_Y + L.lift, ZC + 0.4))
	b.Width0 = L.w0; b.Width1 = L.w1; b.CurveSize0 = 0; b.CurveSize1 = 0
	b.Texture = TEX; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = L.tlen; b.TextureSpeed = L.speed
	b.Transparency = seq(L.tr); b.Color = FOAM
	b.LightEmission = 0.2; b.LightInfluence = 0.9; b.Brightness = 1; b.Segments = 20; b.ZOffset = 0.1 * i; b.FaceCamera = false
	b.Parent = rig
end
-- foam puffs riding the surface, denser toward the brink
local foam = part("Foam", Vector3.new(29, 0.5, 30), CFrame.new(CXE, WATER_Y + 0.4, ZC + 16))
emitter(foam, {Rate = 36, Lifetime = NumberRange.new(0.7, 1.4), Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(15, 15),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 1.5}, {0.5, 3.5}, {1, 1}}), Transparency = seq({{0, 0.55}, {0.7, 0.75}, {1, 1}}),
	Acceleration = Vector3.new(0, -1.5, -2), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40)})
-- a second, livelier band in the last 10 studs
local churn = part("Churn", Vector3.new(30, 0.5, 10), CFrame.new(CXE, WATER_Y + 0.5, ZC + 5))
emitter(churn, {Rate = 40, Lifetime = NumberRange.new(0.5, 1.1), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(35, 35),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 1.5}, {1, 4.5}}), Transparency = seq({{0, 0.45}, {1, 1}}),
	Acceleration = Vector3.new(0, -6, -3), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60)})
local carrier = workspace:FindFirstChild("falls_carrier"); if carrier then carrier:Destroy() end
local nb, ne = 0, 0
for _, d in ipairs(F:GetDescendants()) do if d:IsA("Beam") then nb += 1 elseif d:IsA("ParticleEmitter") then ne += 1 end end
print(string.format("QQ FW1 Falls built: %d beams, %d emitters, texture %s; carrier removed: %s", nb, ne, TEX, tostring(workspace:FindFirstChild("falls_carrier") == nil)))
print("QQ FW1 DONE")

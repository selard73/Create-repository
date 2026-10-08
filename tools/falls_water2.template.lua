-- falls_water2: CHANGES THE PLACE (scenery only: no scripts, no save data): the falling water at the gorge's end,
-- in workspace.SouthGorge.Falls (an Atomic model, so it streams in as one piece). Built to Shannon's Niagara
-- references (Sep 30 evening) and revised after three independent reviews of the first version:
--   * RAPIDS: the river turns white and churning from the top of the 40-stud straight before the brink, building
--     toward the edge and thinning in the last few studs so the glassy green lip can read: three full-width foam
--     beam chains lying flat on the water along the river's own curve, at staggered speeds (5-12 studs/s, like a boat), foam puffs lying on the surface,
--     two churn bands;
--   * the LIP: a plain (untextured) crest beam that starts in the river water and rolls over the sill: dark glossy
--     teal, mint by a stud down, white by five, dissolving into the sheet with no hard edge;
--   * the FALL: a mid-tone body beam behind two streak layers (our own texture, rbxassetid://%TEX%) so the white
--     streaks read as highlights; spray thrown up at the lip; a modest mist and plume at the foot plus a cheap
--     camera-facing mist bank so low graphics levels still see mist. Particle sizes stay within 10 studs.
-- Re-running replaces the model. The importer's texture-carrier quad is removed if still present.
local TEX = "rbxassetid://%TEX%"
local CXE, ZC, WATER_Y, SEA_Y = 183.84, -547.5, -0.9, -52.9
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local G = workspace.SouthGorge
local old = G:FindFirstChild("Falls"); if old then old:Destroy() end
local F = Instance.new("Model"); F.Name = "Falls"
pcall(function() F.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
F.Parent = G
local function part(name, size, cf)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Transparency = 1; p.CastShadow = false
	p.Parent = F; return p
end
local rig = part("Rig", Vector3.new(1, 1, 1), CFrame.new(CXE, -6, ZC - 3))          -- the fall's beams sort from here (above the pool water)
local rrig = part("RapidsRig", Vector3.new(1, 1, 1), CFrame.new(CXE + 8, WATER_Y + 1.5, ZC + 25))   -- the foam beams sort from here: ABOVE the river, or the water draws over them from any height
-- attachment frames. Beam width runs along the attachment's SecondaryAxis (its Y); the curve's control points along
-- its Axis (X). Vertical fall: X = south (the curve pushes the top forward over the sill), Y = east (width across
-- the river). Flat (on the water): X = up, Y = east, so the beam's plane is horizontal.
local function att(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))
	return a
end
local function flat(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rrig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, 1, 0), Vector3.new(1, 0, 0))
	return a
end
local function seq(pts)
	local kps = {}
	for _, p in ipairs(pts) do kps[#kps + 1] = NumberSequenceKeypoint.new(p[1], p[2]) end
	return NumberSequence.new(kps)
end
local function cseq(pts)
	local kps = {}
	for _, p in ipairs(pts) do kps[#kps + 1] = ColorSequenceKeypoint.new(p[1], Color3.fromRGB(p[2], p[3], p[4])) end
	return ColorSequence.new(kps)
end
-- speed note: Beam.TextureSpeed is texture repeats per second, so studs/s = TextureSpeed * TextureLength
local function beam(o)
	local b = Instance.new("Beam"); b.Name = o.name; b.Attachment0 = o.a0; b.Attachment1 = o.a1
	b.Width0 = o.w0; b.Width1 = o.w1; b.CurveSize0 = o.c0 or 0; b.CurveSize1 = o.c1 or 0
	b.Texture = o.plain and "" or (o.tex or TEX); b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = o.tlen or 36; b.TextureSpeed = o.speed or 0
	b.Transparency = seq(o.tr); b.Color = o.col or cseq({{0, 236, 247, 255}, {1, 208, 234, 246}})
	b.LightEmission = o.glow or 0.25; b.LightInfluence = o.lightInf or 0.9; b.Brightness = 1
	b.Segments = o.seg or 24; b.ZOffset = o.zoff or 0; b.FaceCamera = o.face or false
	b.Parent = o.a0.Parent; return b
end

-- ============================================================ the lip and the fall ============================================================
-- the glossy green roll over the sill (Horseshoe Falls): starts in the river water, dark teal, mint a stud down, white by five
local GREEN = cseq({{0, 150, 220, 205}, {0.1, 178, 232, 220}, {0.25, 214, 243, 240}, {0.45, 236, 248, 252}, {1, 242, 250, 255}})
beam({name = "Crest", a0 = att("TopC", Vector3.new(CXE, WATER_Y + 0.35, ZC + 0.3)), a1 = att("BottomC", Vector3.new(CXE, WATER_Y - 9.0, ZC - 2.8)),
	w0 = 32, w1 = 32, c0 = 3.2, plain = true, col = GREEN, glow = 0.35, seg = 12, zoff = 0.2,
	tr = {{0, 0.35}, {0.06, 0.1}, {0.3, 0.06}, {0.6, 0.12}, {0.85, 0.6}, {1, 1}}})
-- the body of the fall: a plain mid-tone sheet the white streaks can read against
beam({name = "Body", a0 = att("TopB", Vector3.new(CXE, WATER_Y - 2.6, ZC - 1.6)), a1 = att("BottomB", Vector3.new(CXE, SEA_Y - 1.0, ZC - 6.5)),
	w0 = 32, w1 = 33, c0 = 0.8, plain = true, col = cseq({{0, 176, 214, 222}, {1, 206, 232, 240}}), glow = 0.15, zoff = -0.8,
	tr = {{0, 0.12}, {0.1, 0.08}, {0.8, 0.1}, {1, 0.6}}})
-- the streak layers (texture: 512 across x 1024 along; TextureLength ~36 keeps the streaks about as drawn; ~47 studs/s)
local MINT = cseq({{0, 168, 230, 220}, {0.25, 226, 246, 250}, {1, 240, 249, 255}})
beam({name = "Sheet", a0 = att("Top", Vector3.new(CXE, WATER_Y - 2.0, ZC - 1.4)), a1 = att("Bottom", Vector3.new(CXE, SEA_Y - 1.5, ZC - 7.0)),
	w0 = 31, w1 = 32, c0 = 0.8, tlen = 36, speed = 1.3, col = MINT,
	tr = {{0, 0.2}, {0.12, 0.12}, {0.8, 0.18}, {1, 0.7}}})
beam({name = "Sheet2", a0 = att("Top2", Vector3.new(CXE, WATER_Y - 1.5, ZC - 1.5)), a1 = att("Bottom2", Vector3.new(CXE, SEA_Y - 1.5, ZC - 5.5)),
	w0 = 29, w1 = 32, c0 = 0.8, tlen = 30, speed = 1.0, zoff = -0.5,
	tr = {{0, 0.9}, {0.15, 0.3}, {0.8, 0.3}, {1, 0.8}}})

local RIVER = {{-547.10, 184.12, 14.06}, {-543.10, 186.76, 14.36}, {-539.10, 188.95, 14.81}, {-535.10, 190.98, 15.03}, {-531.10, 193.10, 15.15}, {-527.10, 195.14, 15.19}, {-523.10, 196.87, 14.86}, {-519.10, 198.49, 14.18}, {-515.10, 199.97, 13.33}, {-511.10, 200.75, 12.69}, {-507.10, 200.58, 12.44}, {-503.10, 199.80, 12.17}, {-499.10, 198.84, 11.93}, {-495.10, 197.34, 12.27}}
-- the rapids: white water the FULL width of the river from 52 studs above the brink, following the river's own
-- centre line (it swings ~15 studs east upstream of the lip) at the river's own width plus 3 so the foam's edges tuck
-- into the walls' feet. Each layer is a chain of short flat beams between points of the RIVER table; the whiteness is
-- shaped only by transparency: it builds from the top of the run, peaks a boat-length before the lip and thins in the
-- last few studs so the glassy green roll reads. Three layers at staggered speeds so the foam boils rather than slides.
local function river_at(z)                                   -- RIVER runs from the lip (lowest z) upstream (rising z)
	if z <= RIVER[1][1] then return RIVER[1][2], RIVER[1][3] end
	for i = 1, #RIVER - 1 do
		local p, q = RIVER[i], RIVER[i + 1]
		if z >= p[1] and z <= q[1] then
			local t = (z - p[1]) / (q[1] - p[1])
			return p[2] + (q[2] - p[2]) * t, p[3] + (q[3] - p[3]) * t
		end
	end
	return RIVER[#RIVER][2], RIVER[#RIVER][3]
end
local function tr_at(pts, t)
	if t <= pts[1][1] then return pts[1][2] end
	for i = 1, #pts - 1 do
		if t >= pts[i][1] and t <= pts[i + 1][1] then
			local f = (t - pts[i][1]) / (pts[i + 1][1] - pts[i][1])
			return pts[i][2] + (pts[i + 1][2] - pts[i][2]) * f
		end
	end
	return pts[#pts][2]
end
local wave = 0.15
pcall(function() wave = workspace.Terrain.WaterWaveSize end)
local lift0 = math.max(0.3, 2 * wave)
local FOAM = cseq({{0, 236, 248, 250}, {0.5, 246, 252, 255}, {1, 250, 253, 255}})
local START = 56.0
local layers = {
	{name = "Rapids1", lift = lift0, dx = 0, speed = 0.22, tlen = 26, tr = {{0, 1}, {0.1, 0.55}, {0.3, 0.4}, {1, 0.32}}},
	{name = "Rapids2", lift = lift0 + 0.12, dx = 1.5, speed = 0.32, tlen = 26, tr = {{0, 1}, {0.08, 0.55}, {0.4, 0.4}, {1, 0.35}}},
	{name = "Rapids3", lift = lift0 + 0.25, dx = -1.5, speed = 0.45, tlen = 26, tr = {{0, 1}, {0.12, 0.55}, {0.5, 0.4}, {1, 0.38}}},
}
local nseg = 0
for i, L in ipairs(layers) do
	local pts = {}
	for k = #RIVER, 1, -1 do                                     -- upstream end first (that is Attachment0: the texture races toward the lip)
		local z = RIVER[k][1]
		if z <= ZC + START + 0.01 then
			local cx, hw = river_at(z)
			local t = (ZC + START - z) / START
			pts[#pts + 1] = {z = z, cx = cx + L.dx, w = 2 * hw + 3, tr = tr_at(L.tr, math.clamp(t, 0, 1))}
		end
	end
	for k = 1, #pts - 1 do
		local p, q = pts[k], pts[k + 1]
		beam({name = string.format("%s_%02d", L.name, k), a0 = flat(string.format("%s_%02dA", L.name, k), Vector3.new(p.cx, WATER_Y + L.lift, p.z)),
			a1 = flat(string.format("%s_%02dB", L.name, k), Vector3.new(q.cx, WATER_Y + L.lift, q.z)),
			w0 = p.w, w1 = q.w, tlen = L.tlen, speed = L.speed, col = FOAM, glow = 0.35, lightInf = 0.3, seg = 1, zoff = 0.1 * i, tr = {{0, p.tr}, {1, q.tr}}})
		nseg += 1
	end
end

-- ============================================================ particles ============================================================
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE; e.LightEmission = 0.3; e.LightInfluence = 0.3; e.ZOffset = 0
	e.Color = ColorSequence.new(Color3.fromRGB(242, 249, 255))
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent; return e
end
-- foam, churn and haze ride the river too: a box every 12 studs along the run, each the river's width where it sits
local function along(name, z_from, z_to, step, h, fn)
	local z = z_from
	local n = 0
	while z - step > z_to - 0.01 do
		local zm = z - step / 2
		local cx, hw = river_at(zm)
		local p = part(string.format("%s_%02d", name, n + 1), Vector3.new(2 * hw, 0.5, step), CFrame.new(cx, WATER_Y + h, zm))
		fn(p, n)
		z = z - step; n += 1
	end
end
-- foam puffs lying flat on the water over the whole run. These carry the look from ABOVE: Roblox draws the river's
-- water surface over flat (non-camera-facing) beams when seen from above, but particles render after the water
-- (found by test, Sep 30 22:30). The beams still carry the low, boat's-eye angles. Self-lit so the shaded gorge
-- water does not turn them navy.
along("Foam", ZC + START, ZC + 0.4, 12, 0.9, function(p, n)
	emitter(p, {Rate = 32, Lifetime = NumberRange.new(1.0, 1.5), Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(15, 15),
		EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, ZOffset = 0.5,
		Size = seq({{0, 2.5}, {0.5, 5}, {1, 2.5}}), Transparency = seq({{0, 0.4}, {0.7, 0.65}, {1, 1}}),
		LightEmission = 0.4, LightInfluence = 0.2,
		Acceleration = Vector3.new(0, -1.5, -5), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40)})
end)
-- churn: livelier puffs, strongest in the last 16 studs
along("Churn", ZC + 36, ZC + 3, 16.5, 0.9, function(p, n)
	emitter(p, {Rate = (n == 1) and 40 or 20, Lifetime = NumberRange.new(0.5, 1.1), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(35, 35),
		EmissionDirection = Enum.NormalId.Top, Orientation = Enum.ParticleOrientation.VelocityPerpendicular, ZOffset = 0.5,
		Size = seq({{0, 1.5}, {1, 4.5}}), Transparency = seq({{0, 0.45}, {1, 1}}),
		Acceleration = Vector3.new(0, -6, -6), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60)})
end)
-- a low haze drifting over the rapids (she asked for misty water before the edge, not only at the foot)
along("RiverMist", ZC + START, ZC + 0.4, 13, 1.5, function(p, n)
	emitter(p, {Rate = 3, Lifetime = NumberRange.new(2, 3.5), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 4}, {1, 9}}), Transparency = seq({{0, 1}, {0.2, 0.82}, {1, 1}}),
		Acceleration = Vector3.new(0, 0.6, -2.5), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-10, 10),
		Color = ColorSequence.new(Color3.fromRGB(232, 243, 248))})
end)
-- spray thrown up and out at the lip (small, fast wisps)
local spray = part("Spray", Vector3.new(28, 1, 2), CFrame.new(CXE, WATER_Y + 0.6, ZC - 0.6) * CFrame.Angles(math.rad(35), 0, 0))
emitter(spray, {Rate = 14, Lifetime = NumberRange.new(0.5, 1.0), Speed = NumberRange.new(5, 9), SpreadAngle = Vector2.new(25, 25),
	EmissionDirection = Enum.NormalId.Front, Size = seq({{0, 0.8}, {1, 3.5}}), Transparency = seq({{0, 0.55}, {1, 1}}),
	Acceleration = Vector3.new(0, -14, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20)})
-- mist boiling up where the water lands (modest: it must not white out the fall; sizes within 10)
local mist = part("Mist", Vector3.new(34, 3, 14), CFrame.new(CXE, SEA_Y + 1.5, ZC - 8))
emitter(mist, {Rate = 9, Lifetime = NumberRange.new(2, 3.2), Speed = NumberRange.new(2.5, 5), SpreadAngle = Vector2.new(55, 55),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 5}, {1, 10}}), Transparency = seq({{0, 1}, {0.15, 0.7}, {1, 1}}),
	Acceleration = Vector3.new(0, 1.2, -1.0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-15, 15),
	Color = ColorSequence.new(Color3.fromRGB(230, 241, 247))})
local plume = part("Plume", Vector3.new(26, 2, 10), CFrame.new(CXE, SEA_Y + 3, ZC - 7))
emitter(plume, {Rate = 3, Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(40, 40),
	EmissionDirection = Enum.NormalId.Top, Size = seq({{0, 8}, {1, 10}}), Transparency = seq({{0, 1}, {0.3, 0.88}, {1, 1}}),
	Acceleration = Vector3.new(0, 0.9, -0.6), Drag = 0.5, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-6, 6)})
-- a camera-facing mist bank at the foot: the cheap base that survives low graphics levels
beam({name = "MistBank", a0 = att("MistLo", Vector3.new(CXE, SEA_Y + 0.5, ZC - 7)), a1 = att("MistHi", Vector3.new(CXE, SEA_Y + 16, ZC - 9)),
	w0 = 36, w1 = 46, tex = SMOKE, tlen = 16, speed = -0.2, face = true, glow = 0.1, seg = 6, zoff = 0.3,
	col = cseq({{0, 240, 247, 252}, {1, 240, 247, 252}}), tr = {{0, 0.7}, {0.5, 0.82}, {1, 1}}})

local carrier = workspace:FindFirstChild("falls_carrier"); if carrier then carrier:Destroy() end
local nb, ne = 0, 0
for _, d in ipairs(F:GetDescendants()) do if d:IsA("Beam") then nb += 1 elseif d:IsA("ParticleEmitter") then ne += 1 end end
local kp = mist.ParticleEmitter.Size.Keypoints
print(string.format("QQ FW2 Falls built: %d beams (%d rapids segments), %d emitters, texture %s, wave %.2f (rapids lift %.2f); mist size keypoints %.1f..%.1f; streaming %s", nb, nseg, ne, TEX, wave, lift0, kp[1].Value, kp[#kp].Value, tostring(workspace.StreamingEnabled)))
print("QQ FW2 DONE")

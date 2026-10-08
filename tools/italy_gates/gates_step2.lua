-- Oct 8 2026, Porto gates STEP 2 (Via della Piazza -> The Groves), under Shannon's go for "all of the changes we have discussed".
-- Adds to workspace.PortoGates: gates 3-7 (NeedArea porto_borgo: 10 Via della Piazza finds), the second wall line (option A:
-- the strip south of the lemon terraces joins The Groves), the safety-net polygon + back spots, the hide-when-open rope;
-- Zones.porto_borgo_south -> Area groves; the map: The Groves needs 10 Via della Piazza finds, the strip moves to The Groves.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
local root = workspace:FindFirstChild('PortoGates')
if not root then return 'QM@ABORT no PortoGates (run step 1 first)' end
if root.Gates:FindFirstChild('Beach rope') then return 'QM@SKIP step 2 already built' end
local C = Color3.fromRGB
local UP = Vector3.new(0, 1, 0)
local LIME, LIME_HI, LIME_DK, JOINT = C(236, 220, 186), C(244, 232, 204), C(222, 207, 175), C(186, 170, 140)
local DRY = C(198, 186, 160)
local WOOD, WOOD2, IRON = C(124, 80, 48), C(104, 66, 40), C(42, 63, 55)
local BOARD, INK = C(244, 234, 208), C(41, 90, 73)
local ROPE, LEMON, SEA_BLUE, RED = C(196, 166, 110), C(250, 222, 96), C(60, 110, 160), C(150, 40, 30)
local MAT = Enum.Material
local WALL_BOT, WALL_TOP = -70, 120
local wallsM, gatesF = root.Walls, root.Gates
local function part(parent, name, size, cf, color, mat, extra)
	local p = Instance.new('Part')
	p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat or MAT.SmoothPlastic
	p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if extra then for k, v in pairs(extra) do p[k] = v end end
	p.Parent = parent
	return p
end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = {root, workspace:FindFirstChild('Zones'), workspace:FindFirstChild('SquirrelTwins')}
local function groundY(p, up) local r = workspace:Raycast(p + Vector3.new(0, up or 3, 0), Vector3.new(0, -60, 0), rp) return r and r.Position.Y, r and r.Instance end
local function textLabel(sg, text, color, y0, h, font)
	local t = Instance.new('TextLabel') t.Size = UDim2.fromScale(0.9, h) t.Position = UDim2.fromScale(0.05, y0) t.BackgroundTransparency = 1
	t.TextScaled = true t.Text = text t.TextColor3 = color t.FontFace = Font.new(font or 'rbxasset://fonts/families/Guru.json', Enum.FontWeight.Bold) t.Parent = sg
	return t
end
local function signFaces(p, lines)            -- lines = {{text, color, y0, h}, ...}, on both faces
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local sg = Instance.new('SurfaceGui') sg.Face = face sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 80 sg.LightInfluence = 1 sg.Parent = p
		for _, l in ipairs(lines) do textLabel(sg, l[1], l[2], l[3], l[4]) end
	end
end
local noteTemplate
for _, b in ipairs(workspace:GetChildren()) do
	if b.Name == 'Boundary' and b:FindFirstChild('Gates') and b.Gates:FindFirstChild('VillageGate') then noteTemplate = b.Gates.VillageGate:FindFirstChild('Sign', true) end
end
local function note(model, G, pos, offY)
	local post = part(model, 'SignPost', Vector3.new(0.5, 0.5, 0.5), G * CFrame.new(pos), LIME, nil, {Transparency = 1})
	local n = noteTemplate:Clone() n.StudsOffset = Vector3.new(0, offY, 0) n.Adornee = nil n.Parent = post
	local lbl = n:FindFirstChild('SignText', true) if lbl then lbl.Text = '' end
end
local function footing(model, G, x0, x1, z0, z1, color, mat)
	local lowest = 0
	for _, x in ipairs({x0, x1, (x0 + x1) / 2}) do for _, z in ipairs({z0, z1}) do
		local w = G:PointToWorldSpace(Vector3.new(x, 0, z))
		local y = groundY(w)
		local ly = y and (y - G.Position.Y) or -6
		lowest = math.min(lowest, math.max(ly, -14))
	end end
	if lowest < -0.15 then
		local h = -lowest + 0.6
		part(model, 'Footing', Vector3.new(x1 - x0 + 0.3, h, z1 - z0 + 0.3), G * CFrame.new((x0 + x1) / 2, -h / 2 + 0.1, (z0 + z1) / 2), color, mat or MAT.Limestone, {CanCollide = true})
	end
end
local function capWall(G, halfW, localTop, area)
	local yb = G.Position.Y + localTop
	local h = WALL_TOP - yb
	local w = part(wallsM, 'Wall', Vector3.new(2 * halfW + 1, h, 1), G * CFrame.new(0, localTop + h / 2, 0), LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
	w:SetAttribute('NeedArea', area) w:SetAttribute('Cap', true)
end
local function newGate(name, kind)
	local m = Instance.new('Model') m.Name = name m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m:SetAttribute('NeedArea', 'porto_borgo') m:SetAttribute('FromName', 'Via della Piazza') m:SetAttribute('ToName', 'The Groves')
	m:SetAttribute('Kind', kind)
	return m
end
local function railsNear(G, rx, rz)              -- where the existing stair railings run, in the gate's frame
	local xs = {}
	for _, p in ipairs(workspace.PortoNocciola:GetDescendants()) do
		if p:IsA('BasePart') and (p.Name == 'Junction fitted handrail' or p.Name == 'Junction fitted rail post') and (p.Position - G.Position).Magnitude < 14 then
			local l = G:PointToObjectSpace(p.Position)
			if math.abs(l.Z) < rz and math.abs(l.X) < rx then table.insert(xs, string.format('%.2f', l.X)) end
		end
	end
	return table.concat(xs, ' ')
end
-- a low dry-stone wall from local x0 to x1 (along the gate's x axis, at z 0), each stone seated on the ground under it
local function dryWall(model, G, x0, x1, height, seed, color)
	local r = Random.new(seed)
	local x = x0
	local dir = x1 > x0 and 1 or -1
	while (x1 - x) * dir > 0.3 do
		local w = math.min(r:NextNumber(0.9, 1.7), math.abs(x1 - x))
		local cx = x + dir * w / 2
		local gy = groundY(G:PointToWorldSpace(Vector3.new(cx, 2, 0)), 4)
		local base = gy and (gy - G.Position.Y) or 0
		local rows = math.max(2, math.floor(height / 0.8 + 0.5))
		for k = 0, rows - 1 do
			local hh = height / rows
			local dv = r:NextInteger(-14, 8)
			local col = Color3.fromRGB(math.clamp(color.R * 255 + dv, 0, 255), math.clamp(color.G * 255 + dv, 0, 255), math.clamp(color.B * 255 + dv, 0, 255))
			part(model, 'Dry stone', Vector3.new(w - 0.06, hh - 0.05, 1.3 + r:NextNumber(-0.1, 0.1)), G * CFrame.new(cx + r:NextNumber(-0.05, 0.05), base - 0.3 + hh * (k + 0.5), r:NextNumber(-0.06, 0.06)), col, MAT.Slate, {CanCollide = true})
		end
		part(model, 'Coping stone', Vector3.new(w, 0.3, 1.5), G * CFrame.new(cx, base - 0.3 + height + 0.15, 0), LIME_DK, MAT.Limestone, {CanCollide = true})
		x = x + dir * w
	end
end

-- ===================================================================== an iron double gate with an overthrow sign (gates 4, 5)
local function ironGate(name, O, X, signText, stubs)
	local G = CFrame.fromMatrix(O, X, UP)
	local W, PS, PH = 5.5, 1.8, 7.0
	local m = newGate(name, 'iron')
	local fr = Instance.new('Model') fr.Name = 'Posts' fr.Parent = m
	for _, sx in ipairs({-1, 1}) do
		local cx = sx * (W + PS / 2)
		part(fr, 'Stone post', Vector3.new(PS, PH, PS), G * CFrame.new(cx, PH / 2, 0), LIME, MAT.Limestone, {CanCollide = true})
		for k = 1, 4 do part(fr, 'Post joint', Vector3.new(PS + 0.04, 0.1, PS + 0.04), G * CFrame.new(cx, k * 1.4, 0), JOINT, MAT.Limestone) end
		part(fr, 'Post cap', Vector3.new(PS + 0.4, 0.5, PS + 0.4), G * CFrame.new(cx, PH + 0.25, 0), LIME_HI, MAT.Limestone, {CanCollide = true})
		part(fr, 'Finial', Vector3.new(1.2, 1.2, 1.2), G * CFrame.new(cx, PH + 1.1, 0), LIME_HI, MAT.Limestone, {Shape = Enum.PartType.Ball})
		footing(fr, G, cx - PS / 2, cx + PS / 2, -PS / 2, PS / 2, LIME_DK)
		if stubs then dryWall(fr, G, sx * (W + PS), sx * (W + PS + stubs), 2.6, 31 + sx, DRY) end
	end
	local pts = {}
	for i = 0, 12 do local t = -1 + 2 * i / 12 table.insert(pts, Vector3.new(5.8 * t, PH + 0.65 + 1.75 * (1 - t * t), 0)) end
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		part(fr, 'Overthrow', Vector3.new((b - a).Magnitude + 0.05, 0.16, 0.16), G * CFrame.new((a + b) / 2) * CFrame.Angles(0, 0, math.atan2(b.Y - a.Y, b.X - a.X)), IRON, MAT.Metal)
	end
	local board = part(fr, 'Sign board', Vector3.new(6.4, 1.05, 0.12), G * CFrame.new(0, PH + 1.25, 0) * CFrame.Angles(0, math.pi, 0), BOARD, MAT.Wood)
	signFaces(board, {{signText, INK, 0.12, 0.76}})
	for _, sx in ipairs({-1, 1}) do
		local top = PH + 0.65 + 1.75 * (1 - (2.4 / 5.8) ^ 2)
		part(fr, 'Hanger', Vector3.new(0.08, top - (PH + 1.78), 0.08), G * CFrame.new(sx * 2.4, (top + PH + 1.78) / 2, 0), IRON, MAT.Metal)
	end
	for _, side in ipairs({-1, 1}) do
		local leaf = Instance.new('Model') leaf.Name = side < 0 and 'LeafL' or 'LeafR' leaf.Parent = m
		local hinge = G * CFrame.new(side * W, 0, 0)
		for i = 0, 10 do
			local u = i / 10
			local x = side * (W - 0.15 - u * (W - 0.3))
			local top = 5.2 + 0.7 * math.sin(math.pi * u)
			part(leaf, 'Bar', Vector3.new(0.13, top - 0.3, 0.13), G * CFrame.new(x, 0.3 + (top - 0.3) / 2, 0), IRON, MAT.Metal)
			part(leaf, 'Spear tip', Vector3.new(0.24, 0.24, 0.13), G * CFrame.new(x, top + 0.08, 0) * CFrame.Angles(0, 0, math.pi / 4), IRON, MAT.Metal)
		end
		for _, y in ipairs({0.5, 2.3, 4.7}) do part(leaf, 'Rail', Vector3.new(W - 0.1, 0.17, 0.17), G * CFrame.new(side * W / 2, y, 0), IRON, MAT.Metal) end
		for k = 1, 4 do part(leaf, 'Collar', Vector3.new(0.5, 0.5, 0.1), G * CFrame.new(side * (W - k * W / 5), 1.4, 0) * CFrame.Angles(0, math.pi / 2, 0), IRON, MAT.Metal, {Shape = Enum.PartType.Cylinder}) end
		leaf.WorldPivot = hinge
		leaf:SetAttribute('Hinge', hinge)
		leaf:SetAttribute('OpenAngle', side < 0 and -math.rad(80) or math.rad(80))
	end
	part(m, 'Block', Vector3.new(2 * W, PH + 1.9, 0.8), G * CFrame.new(0, (PH + 1.9) / 2, 0), LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
	note(m, G, Vector3.new(0, 6.0, 1.5), 5.4)
	capWall(G, W + PS, PH + 1.9, 'porto_borgo')
	m.Parent = gatesF
	log(name, 'rails at x', railsNear(G, 9, 3))
	return G, W + PS
end

-- ===================================================================== a double five-bar farm gate (gates 6, 7)
local function farmGate(name, O, X, W, stubs)
	local G = CFrame.fromMatrix(O, X, UP)
	local m = newGate(name, 'farm')
	local fr = Instance.new('Model') fr.Name = 'Posts' fr.Parent = m
	local PH = 5.4
	for _, sx in ipairs({-1, 1}) do
		local cx = sx * (W + 0.5)
		part(fr, 'Post', Vector3.new(1.0, PH, 1.0), G * CFrame.new(cx, PH / 2, 0), WOOD2, MAT.Wood, {CanCollide = true})
		part(fr, 'Post cap', Vector3.new(1.15, 0.25, 1.15), G * CFrame.new(cx, PH + 0.12, 0), WOOD, MAT.Wood, {CanCollide = true})
		footing(fr, G, cx - 0.5, cx + 0.5, -0.5, 0.5, WOOD2, MAT.Wood)
		if stubs then dryWall(fr, G, sx * (W + 1.0), sx * (W + 1.0 + stubs), 2.0, 47 + sx, DRY) end
	end
	part(fr, 'Sign stake', Vector3.new(0.25, 0.35, 0.25), G * CFrame.new(W + 0.5, PH + 0.42, 0), WOOD2, MAT.Wood)
	local sign = part(fr, 'Sign', Vector3.new(3.6, 1.1, 0.12), G * CFrame.new(W + 0.5, PH + 1.1, 0) * CFrame.Angles(0, math.pi, 0), LEMON, MAT.Wood)   -- above the post, clear of the leaf's swing
	signFaces(sign, {{'LEMON GROVE', C(60, 90, 40), 0.12, 0.76}})
	for _, side in ipairs({-1, 1}) do
		local leaf = Instance.new('Model') leaf.Name = side < 0 and 'LeafL' or 'LeafR' leaf.Parent = m
		local hinge = G * CFrame.new(side * W, 0, 0)
		local cx = side * W / 2
		for k = 0, 4 do part(leaf, 'Gate rail', Vector3.new(W - 0.15, 0.4, 0.3), G * CFrame.new(cx, 0.8 + k * 0.85, 0), k % 2 == 0 and WOOD or WOOD2, MAT.Wood) end
		for _, xx in ipairs({side * (W - 0.3), side * 0.25}) do part(leaf, 'Stile', Vector3.new(0.4, 4.1, 0.34), G * CFrame.new(xx, 2.5, 0), WOOD2, MAT.Wood) end
		local L = math.sqrt((W - 0.7) ^ 2 + 3.3 ^ 2)
		part(leaf, 'Brace', Vector3.new(L, 0.36, 0.3), G * CFrame.new(cx, 2.5, -0.05) * CFrame.Angles(0, 0, side * math.atan2(3.3, W - 0.7)), WOOD, MAT.Wood)
		part(leaf, 'Hinge strap', Vector3.new(0.9, 0.25, 0.36), G * CFrame.new(side * (W - 0.45), 3.85, 0), IRON, MAT.Metal)
		part(leaf, 'Hinge strap', Vector3.new(0.9, 0.25, 0.36), G * CFrame.new(side * (W - 0.45), 1.25, 0), IRON, MAT.Metal)
		leaf.WorldPivot = hinge
		leaf:SetAttribute('Hinge', hinge)
		leaf:SetAttribute('OpenAngle', side < 0 and -math.rad(80) or math.rad(80))
	end
	part(fr, 'Latch', Vector3.new(0.6, 0.2, 0.4), G * CFrame.new(0, 3.4, 0.25), IRON, MAT.Metal)
	part(m, 'Block', Vector3.new(2 * W, 8, 0.8), G * CFrame.new(0, 4, 0), LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
	note(m, G, Vector3.new(0, 5.0, 1.5), 4.6)
	capWall(G, W + 1.0, 8, 'porto_borgo')
	m.Parent = gatesF
	log(name, 'rails at x', railsNear(G, 8, 3))
	return G, W + 1.0
end

-- ===================================================================== gate 3: the rope across the top of the Beach steps
local G3
do
	local Xb = Vector3.new(0.65, 0, -0.76).Unit
	local O = Vector3.new(383.7, 0.0, -999.6) + Xb:Cross(UP) * 1.0     -- 1 stud up the approach from its middle, toward the coast path
	G3 = CFrame.fromMatrix(O, Xb, UP)
	local m = newGate('Beach rope', 'rope')
	local fr = Instance.new('Model') fr.Name = 'Bollards' fr.Parent = m
	local W = 4.5
	local BX = W + 0.6
	for _, sx in ipairs({-1, 1}) do
		part(fr, 'Bollard', Vector3.new(3.6, 1.1, 1.1), G3 * CFrame.new(sx * BX, 1.8, 0) * CFrame.Angles(0, 0, math.pi / 2), WOOD2, MAT.Wood, {Shape = Enum.PartType.Cylinder, CanCollide = true})
		part(fr, 'Bollard cap', Vector3.new(0.3, 1.3, 1.3), G3 * CFrame.new(sx * BX, 3.75, 0) * CFrame.Angles(0, 0, math.pi / 2), IRON, MAT.Metal, {Shape = Enum.PartType.Cylinder})
		part(fr, 'Hook', Vector3.new(0.12, 0.6, 0.6), G3 * CFrame.new(sx * (BX - 0.62), 3.0, 0) * CFrame.Angles(0, 0, 0), IRON, MAT.Metal, {Shape = Enum.PartType.Cylinder})
		footing(fr, G3, sx * BX - 0.55, sx * BX + 0.55, -0.55, 0.55, WOOD2, MAT.Wood)
	end
	for k = 0, 2 do                                                  -- spare rope coiled on the left bollard
		part(fr, 'Rope coil', Vector3.new(0.2, 1.35 - k * 0.05, 1.35 - k * 0.05), G3 * CFrame.new(-BX, 2.2 + k * 0.22, 0) * CFrame.Angles(0, 0, math.pi / 2), ROPE, MAT.Fabric, {Shape = Enum.PartType.Cylinder})
	end
	local rope = Instance.new('Model') rope.Name = 'Rope' rope.Parent = m
	local a, b = -BX + 0.62, BX - 0.62 - 1.4
	local N = 16
	local pts = {}
	for i = 0, N do local t = i / N table.insert(pts, Vector3.new(a + (b - a) * t, 3.0 - 0.9 * 4 * t * (1 - t), 0)) end
	for i = 1, N do
		local p, q = pts[i], pts[i + 1]
		part(rope, 'Rope', Vector3.new((q - p).Magnitude + 0.06, 0.32, 0.32), G3 * CFrame.new((p + q) / 2) * CFrame.Angles(0, 0, math.atan2(q.Y - p.Y, q.X - p.X)), ROPE, MAT.Fabric, {Shape = Enum.PartType.Cylinder})
	end
	for k = 0, 3 do
		part(rope, 'Chain link', Vector3.new(0.08, 0.36, 0.36), G3 * CFrame.new(b + 0.2 + k * 0.33, 3.0, 0) * CFrame.Angles(k % 2 == 0 and 0 or math.pi / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), IRON, MAT.Metal, {Shape = Enum.PartType.Cylinder})
	end
	local mid = pts[N / 2 + 1]
	local bz = mid.Y - 1.0
	local board = part(rope, 'Sign board', Vector3.new(5.0, 1.5, 0.15), G3 * CFrame.new(-0.4, bz, 0) * CFrame.Angles(0, math.pi, 0), BOARD, MAT.Wood)
	part(rope, 'Sign rim', Vector3.new(5.2, 1.7, 0.1), G3 * CFrame.new(-0.4, bz, 0), SEA_BLUE, MAT.Wood)
	signFaces(board, {{'BEACH CLOSED', RED, 0.08, 0.5}, {'high tide!', SEA_BLUE, 0.56, 0.38}})
	for _, sx in ipairs({-1, 1}) do part(rope, 'Cord', Vector3.new(0.05, 0.85, 0.05), G3 * CFrame.new(-0.4 + sx * 1.9, bz + 1.15, 0), ROPE, MAT.Fabric) end
	rope:SetAttribute('Hide', true)                                  -- unhooked and put away when the gate opens
	part(m, 'Block', Vector3.new(2 * BX, 9, 0.8), G3 * CFrame.new(0, 4.5, 0), LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
	note(m, G3, Vector3.new(0, 4.0, 1.8), 3.6)
	capWall(G3, BX + 0.55, 9, 'porto_borgo')
	m.Parent = gatesF
	log('gate 3 Beach rope; rails at x', railsNear(G3, 8, 3))
end

-- ===================================================================== gates 4-7
local function floorAt(v) local y = groundY(Vector3.new(v.X, 10, v.Z), 10) return y end
local O4 = Vector3.new(420.25, 0, -1027.0) O4 = Vector3.new(O4.X, floorAt(O4) or 0.8, O4.Z)
local G4, H4 = ironGate('To the Lighthouse gate', O4, Vector3.new(0.69, 0, 0.72).Unit, 'TO THE LIGHTHOUSE', nil)
local O5 = Vector3.new(551.55, 12.0, -987.15)
local G5, H5 = ironGate('Flower Meadow gate', O5, Vector3.new(1, 0, -0.06).Unit, 'FLOWER MEADOW', 7)
local O6 = Vector3.new(679.6, 48.0, -758.6)
local G6, H6 = farmGate('Lemon Grove gate (Salita degli Ulivi)', O6, Vector3.new(1, 0, 1).Unit, 3.5, 5)
local O7 = Vector3.new(703.75, 60.0, -757.25)
local G7, H7 = farmGate('Lemon Grove gate (from the Belvedere)', O7, Vector3.new(0.99, 0, -0.12).Unit, 4.5, 5)
log('gate 4 floor y', O4.Y)

-- ===================================================================== the second wall line
local function xz(G, x) local v = G:PointToWorldSpace(Vector3.new(x, 0, 0)) return Vector2.new(v.X, v.Z) end
local function along(o, d, k) return Vector2.new(o.X + d.X * k, o.Y + d.Y * k) end
-- the Beach steps' first flight, NW side (the grassy shelf below the coast path stays in town)
local stairX = Vector2.new(0.65, -0.76).Unit
local flightTop, flightBot = Vector2.new(383.7, -999.6), Vector2.new(362.0, -1018.0)
local nwTop, nwBot = along(flightTop, -stairX, 5.4), along(flightBot, -stairX, 5.4)
-- the coast path's sea-side edge from the beach steps to gate 4
local pathR = Vector2.new(0.69, 0.72).Unit
local LINE2 = {
	Vector2.new(279.0, -1012.0), Vector2.new(330.0, -1013.0), Vector2.new(350.0, -1013.5), nwBot, nwTop, xz(G3, -(5.1 + 0.55)),
	xz(G3, 5.1 + 0.55), along(Vector2.new(401.6, -1009.1), -pathR, 6.8), along(Vector2.new(414.0, -1021.0), -pathR, 6.8), xz(G4, -H4),
	xz(G4, H4), Vector2.new(440.0, -1022.0), Vector2.new(470.0, -1013.0), Vector2.new(520.0, -997.0), xz(G5, -H5),
	xz(G5, H5), Vector2.new(590.0, -988.5), Vector2.new(617.0, -989.0), Vector2.new(617.0, -756.0), xz(G6, -H6),
	xz(G6, H6), xz(G7, -H7),
	xz(G7, H7), Vector2.new(760.0, -757.5), Vector2.new(860.0, -757.5)}
local GATESEG = {}
for i = 1, #LINE2 - 1 do
	-- a segment that a gate closes: both ends are that gate's posts (they are 2*H apart and the midpoint is the gate origin)
	for _, gg in ipairs({{G3, 5.65}, {G4, H4}, {G5, H5}, {G6, H6}, {G7, H7}}) do
		local a, b = LINE2[i], LINE2[i + 1]
		local mid = (a + b) / 2
		if (mid - Vector2.new(gg[1].Position.X, gg[1].Position.Z)).Magnitude < 0.05 and math.abs((b - a).Magnitude - 2 * gg[2]) < 0.05 then GATESEG[i] = true end
	end
end
local nw = 0
for i = 1, #LINE2 - 1 do
	if not GATESEG[i] then
		local a, b = LINE2[i], LINE2[i + 1]
		local len = (b - a).Magnitude
		if len > 0.05 then
			local mid = (a + b) / 2
			local h = WALL_TOP - WALL_BOT
			local w = part(wallsM, 'Wall', Vector3.new(1, h, len + 1), CFrame.lookAt(Vector3.new(mid.X, WALL_BOT + h / 2, mid.Y), Vector3.new(b.X, WALL_BOT + h / 2, b.Y)), LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
			w:SetAttribute('NeedArea', 'porto_borgo') w:SetAttribute('Line', 'groves')
			nw += 1
		end
	end
end
local gs = 0 for _ in pairs(GATESEG) do gs += 1 end
log('groves walls', nw, 'gate gaps', gs)
-- the safety net: The Groves = the polygon from the harbour line's south end along this line to the east and back
local poly = {Vector2.new(266, -1330), Vector2.new(268, -1140)}
for _, v in ipairs(LINE2) do table.insert(poly, v) end
table.insert(poly, Vector2.new(860, -1340))
local t = {}
for _, v in ipairs(poly) do table.insert(t, string.format('%.2f,%.2f', v.X, v.Y)) end
root:SetAttribute('GrovesPolygon', table.concat(t, ';'))
local t2 = {}
for _, v in ipairs(LINE2) do table.insert(t2, string.format('%.2f,%.2f', v.X, v.Y)) end
root:SetAttribute('GrovesLine', table.concat(t2, ';'))
root:SetAttribute('Gate3Back', G3 * CFrame.new(0, 3.5, 6))
root:SetAttribute('Gate4Back', G4 * CFrame.new(0, 3.5, 7))
root:SetAttribute('Gate5Back', G5 * CFrame.new(0, 3.5, 7))
root:SetAttribute('Gate6Back', G6 * CFrame.new(0, 3.5, 6))
root:SetAttribute('Gate7Back', G7 * CFrame.new(0, 3.5, 6))
root:SetAttribute('Built', 'Oct 8 2026 Porto area gates: step 1 the Harbour side + step 2 The Groves side')

-- ===================================================================== the client learns "Hide" (the rope is put away when open)
local client = root.PortoGateClient
local cs = client.Source
local oldLoop = [[			for _, leaf in ipairs(leaves) do
				local a = leaf:GetAttribute("OpenAngle") or 0
				if first then turn(leaf, ok and a or 0) else swing(leaf, ok and 0 or a, ok and a or 0, 1.3) end
			end]]
local newLoop = [[			for _, leaf in ipairs(leaves) do
				local a = leaf:GetAttribute("OpenAngle") or 0
				if first then turn(leaf, ok and a or 0) else swing(leaf, ok and 0 or a, ok and a or 0, 1.3) end
			end
			for _, c in ipairs(g:GetChildren()) do          -- a rope (and its board) is unhooked and put away when the gate opens
				if c:GetAttribute("Hide") then
					for _, d in ipairs(c:GetDescendants()) do
						if d:IsA("BasePart") then d.Transparency = ok and 1 or 0 elseif d:IsA("SurfaceGui") then d.Enabled = not ok end
					end
				end
			end]]
local a1, b1 = cs:find(oldLoop, 1, true)
if a1 then client.Source = cs:sub(1, a1 - 1) .. newLoop .. cs:sub(b1 + 1) log('client: Hide added') else log('CLIENT PATCH MISSING') end

-- ===================================================================== Zones + the map
local strip = workspace.Zones:FindFirstChild('porto_borgo_south')
if strip then strip:SetAttribute('Area', 'groves') log('Zones.porto_borgo_south Area -> groves') end
local hud = workspace.HudBarUI.HudBarClient
local s = hud.Source
local function rep(old, new, label)
	local a, b = s:find(old, 1, true)
	if not a then log('MAP PATCH MISSING', label) return end
	s = s:sub(1, a - 1) .. new .. s:sub(b + 1) log('map patched', label)
end
rep('{id = "porto_groves", porto = "groves", needs = "porto_harbour",', '{id = "porto_groves", porto = "groves", needs = "porto_borgo",', 'groves needs Via della Piazza')
rep('rects = {{355.5, -1000, 617, -540}, {617, -756, 800.5, -540}, {617, -1000, 800.5, -949}, {300, -1000, 355, -880}}},',
	'rects = {{355.5, -1000, 617, -540}, {617, -756, 800.5, -540}, {300, -1000, 355, -880}}},', 'borgo rects without the strip')
rep('rects = {{300, -1300, 800, -1000}, {617, -949, 800.5, -756}}},', 'rects = {{300, -1300, 800, -1000}, {617, -1000, 800.5, -756}}},   -- Oct 8 2026: the strip south of the terraces joined The Groves (option A)', 'groves rects with the strip')
hud.Source = s
for _, scr in ipairs({client, hud}) do
	local mm = Instance.new('ModuleScript') mm.Source = 'if true then return 0 end\n' .. scr.Source mm.Parent = game.ServerStorage
	local ok, err = pcall(require, mm) mm:Destroy()
	log('parse', scr.Name, ok, err)
end
game:GetService('ChangeHistoryService'):SetWaypoint('Porto gates step 2: The Groves gates, wall, map')
return table.concat(LOG, '\n')

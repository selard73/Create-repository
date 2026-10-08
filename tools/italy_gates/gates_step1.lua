-- Oct 8 2026, Porto gates STEP 1 (the Harbour side). Shannon: "ok; go ahead please" + "you have permission to make all of the
-- changes we have discussed; I will inspect it in the morning before we publish it". Builds workspace.PortoGates:
--   Walls (Persistent Model): invisible walls along the harbour line (the old More Squirrels Coming Soon line, re-routed
--     through the two gates), NeedArea = porto_harbour (open per player at 10 Harbour finds, client side)
--   Gates: "Porta del Borgo" (stone town arch + two wooden doors at the foot of the town stairs) and "Lighthouse Path"
--     (iron double gate between ochre pillars where the Sentiero del Faro leaves the quay); Block + leaves + note like France
--   PortoGateServer: Found_porto_<area> counts from FoundIds + the safety net (walked back to the gate, France's message)
--   PortoGateClient: walls/gates per player, swing + creak, the note
-- Also: ComingSoonWall -> ServerStorage, funicular + Tonio 15 -> 10 Harbour finds, map unlock rule for the town.
local LOG = {}
local function log(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end LOG[#LOG + 1] = table.concat(t, ' ') end
if workspace:FindFirstChild('PortoGates') then return 'QM@SKIP PortoGates exists' end
local C = Color3.fromRGB
local UP = Vector3.new(0, 1, 0)
local LIME, LIME_HI, LIME_DK, JOINT = C(236, 220, 186), C(244, 232, 204), C(222, 207, 175), C(186, 170, 140)
local OCHRE, TILE = C(220, 191, 128), C(187, 112, 82)
local WOOD, WOOD2, IRON = C(124, 80, 48), C(104, 66, 40), C(42, 63, 55)
local BOARD, INK = C(244, 234, 208), C(41, 90, 73)
local MAT = Enum.Material
local WALL_BOT, WALL_TOP = -70, 120

local root = Instance.new('Folder') root.Name = 'PortoGates'
root:SetAttribute('Enabled', true) root:SetAttribute('Need', 10)
root:SetAttribute('Built', 'Oct 8 2026 Porto area gates: step 1 the Harbour side')
local wallsM = Instance.new('Model') wallsM.Name = 'Walls' wallsM.ModelStreamingMode = Enum.ModelStreamingMode.Persistent wallsM.Parent = root
local gatesF = Instance.new('Folder') gatesF.Name = 'Gates' gatesF.Parent = root

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
rp.FilterDescendantsInstances = {root, workspace:FindFirstChild('Zones'), workspace:FindFirstChild('ComingSoonWall'), workspace:FindFirstChild('SquirrelTwins')}
local function groundY(p) local r = workspace:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, -40, 0), rp) return r and r.Position.Y end
local function signText(p, face, text)
	local sg = Instance.new('SurfaceGui') sg.Face = face sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 80
	sg.LightInfluence = 1 sg.Parent = p
	local t = Instance.new('TextLabel') t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true t.Text = text
	t.TextColor3 = INK t.FontFace = Font.new('rbxasset://fonts/families/Guru.json', Enum.FontWeight.Bold) t.Parent = sg
	local pad = Instance.new('UIPadding') pad.PaddingLeft = UDim.new(0.05, 0) pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.14, 0) pad.PaddingBottom = UDim.new(0.14, 0) pad.Parent = t
end
-- France's note (the floating panel over a gate), cloned so Porto's looks the same
local noteTemplate
for _, b in ipairs(workspace:GetChildren()) do
	if b.Name == 'Boundary' and b:FindFirstChild('Gates') and b.Gates:FindFirstChild('VillageGate') then noteTemplate = b.Gates.VillageGate:FindFirstChild('Sign', true) end
end
assert(noteTemplate and noteTemplate:IsA('BillboardGui'), 'France note template missing')
local function note(model, G, pos, offY)
	local post = part(model, 'SignPost', Vector3.new(0.5, 0.5, 0.5), G * CFrame.new(pos), LIME, nil, {Transparency = 1})
	local n = noteTemplate:Clone() n.StudsOffset = Vector3.new(0, offY, 0) n.Adornee = nil n.Parent = post
	local lbl = n:FindFirstChild('SignText', true) if lbl then lbl.Text = '' end
	return post
end
local function footing(model, G, x0, x1, z0, z1, color)       -- a stone foot from the gate floor down to the ground below it
	local lowest = 0
	for _, x in ipairs({x0, x1, (x0 + x1) / 2}) do for _, z in ipairs({z0, z1}) do
		local w = G:PointToWorldSpace(Vector3.new(x, 0, z))
		local y = groundY(w)
		local ly = y and (y - G.Position.Y) or -6
		lowest = math.min(lowest, math.max(ly, -14))
	end end
	if lowest < -0.15 then
		local h = -lowest + 0.6
		part(model, 'Footing', Vector3.new(x1 - x0 + 0.5, h, z1 - z0 + 0.5), G * CFrame.new((x0 + x1) / 2, -h / 2 + 0.1, (z0 + z1) / 2), color, MAT.Limestone, {CanCollide = true})
	end
	return lowest
end
local function capWall(G, halfW, localTop, area)                -- the invisible wall above a gate, up to the walls' top
	local yb = G.Position.Y + localTop
	local h = WALL_TOP - yb
	local w = part(wallsM, 'Wall', Vector3.new(2 * halfW + 1, h, 1), G * CFrame.new(0, localTop + h / 2, 0), LIME, nil,
		{Transparency = 1, CanCollide = true, CastShadow = false})
	w:SetAttribute('NeedArea', area) w:SetAttribute('Cap', true)
	return w
end

-- ===================================================================== gate 1: Porta del Borgo
local GS = game:GetService('GeometryService')
do
	local O = Vector3.new(362.2, -46.8, -627.2)
	local G = CFrame.fromMatrix(O, Vector3.new(1, 0, 1).Unit, UP)       -- x across the stairs, y up, z = toward the harbour
	local W, PW, SPR, RAD, D = 5.5, 3.5, 8, 5.5, 3.4
	local HW, HT = W + PW, SPR + RAD + 4.4
	local m = Instance.new('Model') m.Name = 'Porta del Borgo' m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m:SetAttribute('NeedArea', 'porto_harbour') m:SetAttribute('FromName', 'The Harbour') m:SetAttribute('ToName', 'Via della Piazza')
	m:SetAttribute('Kind', 'doors')
	local fr = Instance.new('Model') fr.Name = 'Arch' fr.Parent = m
	-- the wall with its round-arched opening (one solid piece, cut with CSG)
	local slab = part(workspace, 'tmp', Vector3.new(2 * HW, HT, D), G * CFrame.new(0, HT / 2, 0), LIME, MAT.Limestone)
	local cutA = part(workspace, 'tmp', Vector3.new(2 * W, SPR + 1, D + 2), G * CFrame.new(0, SPR / 2 - 0.5, 0), LIME)
	local cutB = part(workspace, 'tmp', Vector3.new(D + 2, 2 * RAD, 2 * RAD), G * CFrame.new(0, SPR, 0) * CFrame.Angles(0, math.pi / 2, 0), LIME, nil, {Shape = Enum.PartType.Cylinder})
	local res = GS:SubtractAsync(slab, {cutA, cutB}, {CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition, RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false})
	local arch = res[1] arch.Name = 'Arch wall' arch.Anchored = true arch.CanCollide = true arch.CanTouch = false arch.CanQuery = true
	arch.UsePartColor = true arch.Color = LIME arch.Material = MAT.Limestone arch.Parent = fr
	-- the raised ring round the arch (half annulus), with voussoir joints
	local o1 = part(workspace, 'tmp', Vector3.new(D + 0.4, 2 * (RAD + 1.6), 2 * (RAD + 1.6)), G * CFrame.new(0, SPR, 0) * CFrame.Angles(0, math.pi / 2, 0), LIME_HI, MAT.Limestone, {Shape = Enum.PartType.Cylinder})
	local i1 = part(workspace, 'tmp', Vector3.new(D + 2, 2 * RAD, 2 * RAD), G * CFrame.new(0, SPR, 0) * CFrame.Angles(0, math.pi / 2, 0), LIME, nil, {Shape = Enum.PartType.Cylinder})
	local b1 = part(workspace, 'tmp', Vector3.new(2 * (RAD + 3), RAD + 3, D + 2), G * CFrame.new(0, SPR - (RAD + 3) / 2, 0), LIME)
	local res2 = GS:SubtractAsync(o1, {i1, b1}, {CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false})
	local ring = res2[1] ring.Name = 'Arch ring' ring.Anchored = true ring.CanCollide = false ring.CanTouch = false ring.CanQuery = false
	ring.UsePartColor = true ring.Color = LIME_HI ring.Material = MAT.Limestone ring.Parent = fr
	for _, p in ipairs({slab, cutA, cutB, o1, i1, b1}) do p:Destroy() end
	for i = 1, 10 do
		local a = math.pi * i / 11
		for _, s in ipairs({1, -1}) do
			part(fr, 'Voussoir joint', Vector3.new(1.62, 0.09, 0.06), G * CFrame.new(math.cos(a) * (RAD + 0.8), SPR + math.sin(a) * (RAD + 0.8), s * (D / 2 + 0.22)) * CFrame.Angles(0, 0, a), JOINT, MAT.Limestone)
		end
	end
	part(fr, 'Keystone', Vector3.new(1.5, 2.4, D + 0.6), G * CFrame.new(0, SPR + RAD + 1.0, 0), LIME_DK, MAT.Limestone)
	for _, sx in ipairs({-1, 1}) do
		local cx = sx * (W + PW / 2)
		part(fr, 'Plinth', Vector3.new(PW + 0.6, 1.0, D + 0.6), G * CFrame.new(cx, 0.5, 0), LIME_DK, MAT.Limestone, {CanCollide = true})
		part(fr, 'Impost', Vector3.new(PW + 0.4, 0.6, D + 0.4), G * CFrame.new(cx, SPR - 0.3, 0), LIME_DK, MAT.Limestone)
		for k = 1, 5 do
			for _, s in ipairs({1, -1}) do
				part(fr, 'Rustication joint', Vector3.new(PW, 0.12, 0.06), G * CFrame.new(cx, 1.0 + k * 1.15, s * (D / 2 + 0.02)), JOINT, MAT.Limestone)
			end
		end
		footing(fr, G, sx > 0 and W or -HW, sx > 0 and HW or -W, -D / 2, D / 2, LIME_DK)
	end
	part(fr, 'Cornice', Vector3.new(2 * HW + 0.8, 0.6, D + 0.6), G * CFrame.new(0, HT + 0.3, 0), LIME_HI, MAT.Limestone)
	local n = math.floor((2 * HW) / 1.6)
	for i = 0, n - 1 do
		local x = -HW + 0.8 + i * (2 * HW - 1.6) / (n - 1)
		part(fr, 'Roof tile', Vector3.new(D + 0.6, 0.64, 0.64), G * CFrame.new(x, HT + 0.92, 0) * CFrame.Angles(0, math.pi / 2, 0), TILE, MAT.Slate, {Shape = Enum.PartType.Cylinder})
	end
	local plaque = part(fr, 'Plaque', Vector3.new(7.0, 1.3, 0.2), G * CFrame.new(0, HT - 1.45, D / 2 + 0.1) * CFrame.Angles(0, math.pi, 0), BOARD, MAT.Limestone)
	signText(plaque, Enum.NormalId.Front, 'PORTA DEL BORGO')
	-- the iron fan in the lunette
	local DZ = D / 2 - 0.35
	part(fr, 'Fan base', Vector3.new(2 * W, 0.25, 0.25), G * CFrame.new(0, SPR + 0.12, DZ), IRON, MAT.Metal)
	for k = 0, 8 do
		local a = math.pi * (k + 0.5) / 9
		local L = RAD - 0.3
		part(fr, 'Fan bar', Vector3.new(L, 0.16, 0.16), G * CFrame.new(math.cos(a) * L / 2, SPR + math.sin(a) * L / 2, DZ) * CFrame.Angles(0, 0, a), IRON, MAT.Metal)
	end
	part(fr, 'Fan hub', Vector3.new(1.1, 1.1, 0.3), G * CFrame.new(0, SPR + 0.1, DZ), IRON, MAT.Metal, {Shape = Enum.PartType.Ball})
	-- the doors (leaves hinged at the opening's edges, swinging out toward the harbour, 80 degrees: inside the stair railings)
	for _, side in ipairs({-1, 1}) do
		local leaf = Instance.new('Model') leaf.Name = side < 0 and 'LeafL' or 'LeafR' leaf.Parent = m
		local hinge = G * CFrame.new(side * W, 0, DZ)
		for k = 0, 5 do
			local x = side * W - side * (k + 0.5) * W / 6
			part(leaf, 'Plank', Vector3.new(W / 6 - 0.05, SPR - 0.1, 0.35), G * CFrame.new(x, (SPR - 0.1) / 2 + 0.03, DZ), k % 2 == 0 and WOOD or WOOD2, MAT.Wood)
		end
		for _, y in ipairs({1.4, 4.0, 6.6}) do
			part(leaf, 'Strap', Vector3.new(W - 0.4, 0.35, 0.1), G * CFrame.new(side * W / 2, y, DZ + 0.22), IRON, MAT.Metal)
			part(leaf, 'Hinge plate', Vector3.new(0.4, 0.5, 0.42), G * CFrame.new(side * (W - 0.15), y, DZ), IRON, MAT.Metal)
		end
		part(leaf, 'Ring', Vector3.new(0.45, 0.45, 0.45), G * CFrame.new(side * 0.7, 4.0, DZ + 0.35), IRON, MAT.Metal, {Shape = Enum.PartType.Ball})
		leaf.WorldPivot = hinge
		leaf:SetAttribute('Hinge', hinge)
		leaf:SetAttribute('OpenAngle', side < 0 and -math.rad(80) or math.rad(80))
	end
	part(m, 'Block', Vector3.new(2 * W, SPR + RAD + 0.2, 0.8), G * CFrame.new(0, (SPR + RAD + 0.2) / 2, 0), LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
	note(m, G, Vector3.new(0, 6.5, D / 2 + 2.2), 3.0)
	capWall(G, HW, HT, 'porto_harbour')
	m.Parent = gatesF
	log('gate 1 Porta del Borgo built; arch parts', #fr:GetChildren())
end

-- ===================================================================== gate 2: Lighthouse Path
do
	local O = Vector3.new(324.0, -46.8, -766.3)
	local G = CFrame.fromMatrix(O, Vector3.new(0.99, 0, -0.14).Unit, UP)  -- z = toward the quay
	local W, PS, PH = 5.5, 1.8, 7.5
	local m = Instance.new('Model') m.Name = 'Lighthouse Path gate' m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m:SetAttribute('NeedArea', 'porto_harbour') m:SetAttribute('FromName', 'The Harbour') m:SetAttribute('ToName', 'Via della Piazza')
	m:SetAttribute('Kind', 'iron')
	local fr = Instance.new('Model') fr.Name = 'Pillars' fr.Parent = m
	for _, sx in ipairs({-1, 1}) do
		local cx = sx * (W + PS / 2)
		part(fr, 'Pillar', Vector3.new(PS, PH, PS), G * CFrame.new(cx, PH / 2, 0), OCHRE, MAT.Plaster, {CanCollide = true})
		part(fr, 'Pillar base', Vector3.new(PS + 0.3, 0.6, PS + 0.3), G * CFrame.new(cx, 0.3, 0), LIME_DK, MAT.Limestone, {CanCollide = true})
		part(fr, 'Pillar cap', Vector3.new(PS + 0.4, 0.5, PS + 0.4), G * CFrame.new(cx, PH + 0.25, 0), LIME_HI, MAT.Limestone, {CanCollide = true})
		part(fr, 'Finial', Vector3.new(1.2, 1.2, 1.2), G * CFrame.new(cx, PH + 1.1, 0), LIME_HI, MAT.Limestone, {Shape = Enum.PartType.Ball})
		footing(fr, G, cx - PS / 2, cx + PS / 2, -PS / 2, PS / 2, LIME_DK)
	end
	-- the overthrow: an iron arc from cap to cap carrying the sign
	local pts = {}
	for i = 0, 12 do local t = -1 + 2 * i / 12 table.insert(pts, Vector3.new(5.8 * t, PH + 0.65 + 1.75 * (1 - t * t), 0)) end
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local mid, len = (a + b) / 2, (b - a).Magnitude
		part(fr, 'Overthrow', Vector3.new(len + 0.05, 0.16, 0.16), G * CFrame.new(mid) * CFrame.Angles(0, 0, math.atan2(b.Y - a.Y, b.X - a.X)), IRON, MAT.Metal)
	end
	local board = part(fr, 'Sign board', Vector3.new(6.0, 1.05, 0.12), G * CFrame.new(0, PH + 1.25, 0) * CFrame.Angles(0, math.pi, 0), BOARD, MAT.Wood)
	signText(board, Enum.NormalId.Front, 'LIGHTHOUSE PATH') signText(board, Enum.NormalId.Back, 'LIGHTHOUSE PATH')
	for _, sx in ipairs({-1, 1}) do
		local top = PH + 0.65 + 1.75 * (1 - (2.4 / 5.8) ^ 2)
		part(fr, 'Hanger', Vector3.new(0.08, top - (PH + 1.78), 0.08), G * CFrame.new(sx * 2.4, (top + PH + 1.78) / 2, 0), IRON, MAT.Metal)
	end
	-- the two leaves: spear-topped bars, gently arched, three rails
	for _, side in ipairs({-1, 1}) do
		local leaf = Instance.new('Model') leaf.Name = side < 0 and 'LeafL' or 'LeafR' leaf.Parent = m
		local hinge = G * CFrame.new(side * W, 0, 0)
		local nb = 10
		for i = 0, nb do
			local u = i / nb                                         -- 0 at the hinge, 1 at the meeting edge
			local x = side * (W - 0.15 - u * (W - 0.3))
			local top = 5.4 + 0.75 * math.sin(math.pi * u)
			part(leaf, 'Bar', Vector3.new(0.13, top - 0.3, 0.13), G * CFrame.new(x, 0.3 + (top - 0.3) / 2, 0), IRON, MAT.Metal)
			part(leaf, 'Spear tip', Vector3.new(0.24, 0.24, 0.13), G * CFrame.new(x, top + 0.08, 0) * CFrame.Angles(0, 0, math.pi / 4), IRON, MAT.Metal)
		end
		for _, y in ipairs({0.5, 2.3, 4.9}) do
			part(leaf, 'Rail', Vector3.new(W - 0.1, 0.17, 0.17), G * CFrame.new(side * W / 2, y, 0), IRON, MAT.Metal)
		end
		for k = 1, 4 do                                             -- a row of little rings between the lower rails
			part(leaf, 'Collar', Vector3.new(0.5, 0.5, 0.1), G * CFrame.new(side * (W - k * W / 5), 1.4, 0) * CFrame.Angles(0, math.pi / 2, 0), IRON, MAT.Metal, {Shape = Enum.PartType.Cylinder})
		end
		leaf.WorldPivot = hinge
		leaf:SetAttribute('Hinge', hinge)
		leaf:SetAttribute('OpenAngle', side < 0 and -math.rad(80) or math.rad(80))
	end
	part(m, 'Block', Vector3.new(2 * W, PH + 1.9, 0.8), G * CFrame.new(0, (PH + 1.9) / 2, 0), LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
	note(m, G, Vector3.new(0, 6.0, 1.5), 5.4)
	capWall(G, W + PS, PH + 1.9, 'porto_harbour')
	m.Parent = gatesF
	log('gate 2 Lighthouse Path built')
end

-- ===================================================================== the harbour wall line
local G1 = CFrame.fromMatrix(Vector3.new(362.2, -46.8, -627.2), Vector3.new(1, 0, 1).Unit, UP)
local G2 = CFrame.fromMatrix(Vector3.new(324.0, -46.8, -766.3), Vector3.new(0.99, 0, -0.14).Unit, UP)
local function xz(v) return Vector2.new(v.X, v.Z) end
local G1S, G1N = xz(G1:PointToWorldSpace(Vector3.new(-9, 0, 0))), xz(G1:PointToWorldSpace(Vector3.new(9, 0, 0)))
local G2W, G2E = xz(G2:PointToWorldSpace(Vector3.new(-7.3, 0, 0))), xz(G2:PointToWorldSpace(Vector3.new(7.3, 0, 0)))
local LINE = {Vector2.new(266, -1330), Vector2.new(268, -1140), Vector2.new(281, -989), Vector2.new(288, -953), Vector2.new(292, -881),
	Vector2.new(300, -855), Vector2.new(309, -828), Vector2.new(314, -794), G2W, G2E, Vector2.new(339, -744), Vector2.new(342, -723),
	Vector2.new(347, -698), Vector2.new(347, -672), Vector2.new(343, -652), G1S, G1N, Vector2.new(358, -591), Vector2.new(358, -540), Vector2.new(358, -500)}
local GAPS = {[9] = true, [16] = true}          -- segments that a gate closes (G2W->G2E, G1S->G1N)
local nw = 0
for i = 1, #LINE - 1 do
	if not GAPS[i] then
		local a, b = LINE[i], LINE[i + 1]
		local len = (b - a).Magnitude
		local mid = (a + b) / 2
		local h = WALL_TOP - WALL_BOT
		local cf = CFrame.lookAt(Vector3.new(mid.X, WALL_BOT + h / 2, mid.Y), Vector3.new(b.X, WALL_BOT + h / 2, b.Y))
		local w = part(wallsM, 'Wall', Vector3.new(1, h, len + 1), cf, LIME, nil, {Transparency = 1, CanCollide = true, CastShadow = false})
		w:SetAttribute('NeedArea', 'porto_harbour')
		nw += 1
	end
end
local lineAttr = {}
for _, v in ipairs(LINE) do table.insert(lineAttr, string.format('%.2f,%.2f', v.X, v.Y)) end
root:SetAttribute('HarbourLine', table.concat(lineAttr, ';'))
root:SetAttribute('Gate1Back', G1 * CFrame.new(0, 3.5, 9) * CFrame.Angles(0, 0, 0))
root:SetAttribute('Gate2Back', G2 * CFrame.new(0, 3.5, 8))
log('harbour walls', nw)

-- ===================================================================== scripts
local server = Instance.new('Script') server.Name = 'PortoGateServer' server.RunContext = Enum.RunContext.Server
server.Source = [==[
-- PortoGateServer (Oct 8 2026): Porto's area gates, server side.
-- (1) Found_porto_harbour / _borgo / _groves: how many squirrels each player has found in each Porto area, kept from the
--     FoundIds list SquirrelSetup publishes, for the gates, the funicular, Tonio and the map.
-- (2) The safety net behind the gates and walls (like France's GateServer): a player standing past a line they have not
--     opened yet is walked back to the nearest gate on the open side, with France's message. The owner passes (testing),
--     unless the folder's NoOwnerBypass attribute is on; GateBypass on a player passes too. Seated players are skipped.
local Players = game:GetService("Players")
local root = script.Parent
local NEED = root:GetAttribute("Need") or 10
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local AREA = {}
for _, e in ipairs(Registry.squirrels) do if e.map == "porto" and e.area then AREA[e.id] = e.area end end
local function recount(player)
	local n = {harbour = 0, borgo = 0, groves = 0}
	for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do
		local a = AREA[id] or AREA[(id:gsub("_2$", ""))]
		if a and n[a] then n[a] += 1 end
	end
	for a, c in pairs(n) do if player:GetAttribute("Found_porto_" .. a) ~= c then player:SetAttribute("Found_porto_" .. a, c) end end
end
local function hook(p) recount(p) p:GetAttributeChangedSignal("FoundIds"):Connect(function() recount(p) end) end
Players.PlayerAdded:Connect(hook)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(hook, p) end

-- the lines, as polygons of the side that is always open
local function parse(s)
	local t = {}
	for x, z in string.gmatch(s or "", "([%-%d%.]+),([%-%d%.]+)") do table.insert(t, Vector2.new(tonumber(x), tonumber(z))) end
	return t
end
local function inside(poly, p)
	local c = false
	local j = #poly
	for i = 1, #poly do
		local a, b = poly[i], poly[j]
		if ((a.Y > p.Y) ~= (b.Y > p.Y)) and (p.X < (b.X - a.X) * (p.Y - a.Y) / (b.Y - a.Y) + a.X) then c = not c end
		j = i
	end
	return c
end
local harbour = parse(root:GetAttribute("HarbourLine"))
table.insert(harbour, Vector2.new(-300, -500)) table.insert(harbour, Vector2.new(-300, -1330))
local groves = parse(root:GetAttribute("GrovesPolygon"))          -- step 2
root:GetAttributeChangedSignal("GrovesPolygon"):Connect(function() groves = parse(root:GetAttribute("GrovesPolygon")) end)
local function inPorto(p) return p.Z < -500 and p.Z > -1340 and p.X > -300 and p.X < 860 and p.Y > -90 and p.Y < 240 end
local function backTo(names, pos)
	local best, bd
	for _, n in ipairs(names) do
		local cf = root:GetAttribute(n)
		if typeof(cf) == "CFrame" then local d = (cf.Position - pos).Magnitude if not bd or d < bd then best, bd = cf, d end end
	end
	return best
end
local function bounce(player, char, cf, need, from, to, n)
	local h = char:FindFirstChildOfClass("Humanoid")
	if h and h.SeatPart then h.Sit = false task.wait(0.2) end
	char:PivotTo(cf)
	player:SetAttribute("GateBounceText", string.format("Find %d squirrels in %s before going on to %s  (%d / %d so far)", need, from, to, n, need))
	player:SetAttribute("GateBounce", os.clock())
end
while true do
	task.wait(0.5)
	if root:GetAttribute("Enabled") ~= false then
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local owner = player.UserId == game.CreatorId and not root:GetAttribute("NoOwnerBypass")
			if hrp and hum and hum.Health > 0 and not hum.SeatPart and not owner and not player:GetAttribute("GateBypass") then
				local p = hrp.Position
				if inPorto(p) then
					local q = Vector2.new(p.X, p.Z)
					local nh = player:GetAttribute("Found_porto_harbour") or 0
					local nb = player:GetAttribute("Found_porto_borgo") or 0
					if not inside(harbour, q) then
						if nh < NEED then
							local cf = backTo({"Gate1Back", "Gate2Back"}, p)
							if cf then bounce(player, char, cf, NEED, "The Harbour", "Via della Piazza", nh) end
						elseif #groves > 2 and inside(groves, q) and nb < NEED then
							local cf = backTo({"Gate3Back", "Gate4Back", "Gate5Back", "Gate6Back", "Gate7Back"}, p)
							if cf then bounce(player, char, cf, NEED, "Via della Piazza", "The Groves", nb) end
						end
					end
				end
			end
		end
	end
end
]==]
server.Parent = root

local client = Instance.new('Script') client.Name = 'PortoGateClient' client.RunContext = Enum.RunContext.Client
client.Source = [==[
-- PortoGateClient (Oct 8 2026): Porto's gates and walls for this player, like France (Boundary GateClient + BoundaryOpen).
-- A gate opens once this player has found Need squirrels in the area it leads out of (NeedArea, e.g. porto_harbour; the
-- server keeps Found_porto_<area>): its Block stops blocking, its leaves swing (or its rope drops) with a creak, and the
-- walls with the same NeedArea stop blocking. Only this player's copy changes, so players at different stages each get
-- the right Porto. The note over a gate says how many are still needed, or (once) that the way is open.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local root = script.Parent
local NEED = root:GetAttribute("Need") or 10
local NL = string.char(10)
local NAMES = {porto_harbour = "The Harbour", porto_borgo = "Via della Piazza", porto_groves = "The Groves"}
local TOTAL = {}
pcall(function()
	local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
	for _, e in ipairs(Registry.squirrels) do if e.map == "porto" and e.area then local k = "porto_" .. e.area TOTAL[k] = (TOTAL[k] or 0) + 1 end end
end)
local function found(area) return player:GetAttribute("Found_" .. area) or 0 end
local function isOpen(area) return root:GetAttribute("Enabled") == false or found(area) >= NEED end

local walls = root:WaitForChild("Walls")
local function applyWall(p)
	local a = p:IsA("BasePart") and p:GetAttribute("NeedArea")
	if a then p.CanCollide = not isOpen(a) end
end
local function refreshWalls() for _, p in ipairs(walls:GetDescendants()) do applyWall(p) end end
walls.DescendantAdded:Connect(applyWall)

local function turn(leaf, ang)
	local hinge = leaf:GetAttribute("Hinge")
	if typeof(hinge) ~= "CFrame" or not leaf.Parent then return end
	leaf:PivotTo(hinge * (leaf:GetAttribute("Axis") == "Z" and CFrame.Angles(0, 0, ang) or CFrame.Angles(0, ang, 0)))
end
local function swing(leaf, from, to, dur)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / dur, 0, 1)
		a = a * a * (3 - 2 * a)
		turn(leaf, from + (to - from) * a)
		if a >= 1 then conn:Disconnect() end
	end)
end

local done = {}
local function setupGate(g)
	if done[g] or not g:GetAttribute("NeedArea") then return end
	done[g] = true
	local area = g:GetAttribute("NeedArea")
	local toName = g:GetAttribute("ToName") or "the next area"
	local fromName = g:GetAttribute("FromName") or NAMES[area] or area
	local block = g:WaitForChild("Block", 10)
	local leaves = {}
	for _, c in ipairs(g:GetChildren()) do if c:IsA("Model") and c:GetAttribute("Hinge") then table.insert(leaves, c) end end
	local label = g:FindFirstChild("SignText", true)
	local panel = g:FindFirstChild("Panel", true)
	local edge = panel and panel:FindFirstChild("Edge")
	local function fade(a, dur)                       -- a = 1 hidden, 0 shown
		local ti = TweenInfo.new(dur)
		if panel then TweenService:Create(panel, ti, {BackgroundTransparency = 0.15 + 0.85 * a}):Play() end
		if edge then TweenService:Create(edge, ti, {Transparency = a}):Play() end
		if label then TweenService:Create(label, ti, {TextTransparency = a}):Play() end
	end
	local open = nil
	local function fancy(t) return '<font face="Antique" size="34" color="#FFD65A"><b>' .. t .. '</b></font>' end
	local function refresh()
		local n = found(area)
		local ok = isOpen(area)
		if label then
			if ok then
				label.Text = "The way to " .. toName .. " is open!" .. NL .. fancy(string.format("%d / %d found in %s", n, TOTAL[area] or n, fromName))
			else
				label.Text = string.format("Find %d squirrels in %s to open this gate", NEED, fromName) .. NL .. string.format("%d / %d found so far", n, NEED)
			end
		end
		if ok ~= open then
			local first = (open == nil)
			open = ok
			if block then block.CanCollide = not ok end
			for _, leaf in ipairs(leaves) do
				local a = leaf:GetAttribute("OpenAngle") or 0
				if first then turn(leaf, ok and a or 0) else swing(leaf, ok and 0 or a, ok and a or 0, 1.3) end
			end
			if ok and not first and block then
				local s = Instance.new("Sound") s.SoundId = "rbxassetid://1845415163" s.Volume = 0.45 s.RollOffMaxDistance = 60 s.Parent = block s:Play() Debris:AddItem(s, 5)
			end
		end
	end
	player:GetAttributeChangedSignal("Found_" .. area):Connect(refresh)
	root:GetAttributeChangedSignal("Enabled"):Connect(refresh)
	refresh()
	-- the note: appears as you come near and fades a few seconds later; once the gate is open it says so once
	if panel then
		local near, shownAt = false, nil
		local told = (open == true)
		task.spawn(function()
			while g.Parent do
				task.wait(0.25)
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local ref = block and block.Position or g:GetPivot().Position
				local d = hrp and (hrp.Position - ref).Magnitude or 1e9
				if near and shownAt and open then told = true end
				if not near and d < 30 then
					near = true
					if not open or not told then
						shownAt = os.clock() fade(0, 0.4)
						if open then told = true end
					end
				elseif near and d > 42 then
					near = false shownAt = nil fade(1, 0.6)
				end
				if near and shownAt and os.clock() - shownAt > 6 then shownAt = nil fade(1, 1.8) end
			end
		end)
	end
end
local gates = root:WaitForChild("Gates")
for _, g in ipairs(gates:GetChildren()) do task.spawn(setupGate, g) end
gates.ChildAdded:Connect(function(g) task.defer(setupGate, g) end)
for _, a in ipairs({"porto_harbour", "porto_borgo"}) do player:GetAttributeChangedSignal("Found_" .. a):Connect(refreshWalls) end
root:GetAttributeChangedSignal("Enabled"):Connect(refreshWalls)
refreshWalls()
player.CharacterAdded:Connect(function() task.delay(0.5, refreshWalls) end)
]==]
client.Parent = root

-- parse checks
for _, s in ipairs({server, client}) do
	local mm = Instance.new('ModuleScript') mm.Source = 'if true then return 0 end\n' .. s.Source mm.Parent = game.ServerStorage
	local ok, err = pcall(require, mm) mm:Destroy()
	if not ok then return 'QM@ABORT parse ' .. s.Name .. ' ' .. tostring(err) end
end
root.Parent = workspace
game:GetService('ChangeHistoryService'):SetWaypoint('Porto gates step 1: walls, Porta del Borgo, Lighthouse Path, scripts')

-- ===================================================================== the old wall, the funicular, Tonio, the map
local csw = workspace:FindFirstChild('ComingSoonWall')
if csw then csw.Name = 'ComingSoonWall_before_gates_oct8' csw.Parent = game.ServerStorage log('ComingSoonWall -> ServerStorage') end
local function patch(scr, old, new, label)
	local s = scr.Source
	local a, b = s:find(old, 1, true)
	if not a then log('PATCH MISSING', label) return end
	scr.Source = s:sub(1, a - 1) .. new .. s:sub(b + 1)
	log('patched', label)
end
local fun = workspace.PortoNocciola['15 Funicolare'].FunicularServer
patch(fun, "-- Oct 4 2026 (Shannon): locked until the player has found all 15 harbour squirrels (Found_porto, set by SquirrelSetup).",
	"-- Oct 4 2026 (Shannon): locked until the player has found all 15 harbour squirrels (Found_porto, set by SquirrelSetup).\n-- Oct 8 2026 (the Porto gates): 10 squirrels found in The Harbour (Found_porto_harbour, kept by PortoGates.PortoGateServer), like the gates.", 'funicular comment')
patch(fun, "local NEED=15", "local NEED=10", 'funicular NEED')
patch(fun, "return (player:GetAttribute('Found_porto') or 0)>=NEED", "return (player:GetAttribute('Found_porto_harbour') or 0)>=NEED", 'funicular rule')
local tonio = game.StarterPlayer.StarterPlayerScripts.TonioTalk
patch(tonio, 'local NEED = 15', 'local NEED = 10                       -- Oct 8 2026: 10 harbour squirrels open the funicular, the town gate and the cliff path', 'Tonio NEED')
patch(tonio, '"Please come back and ride when you have found all 15 squirrels in the harbor."', '"Please come back and ride when you have found 10 squirrels in the harbor."', 'Tonio not yet')
patch(tonio, '"Bravo! All 15 harbour squirrels found. All aboard the funicolare - mind the step!"', '"Bravo! 10 harbour squirrels found. All aboard the funicolare - mind the step!"', 'Tonio ready')
patch(tonio, 'local n = player:GetAttribute("Found_porto") or 0', 'local n = player:GetAttribute("Found_porto_harbour") or 0', 'Tonio count')
local hud = workspace.HudBarUI.HudBarClient
patch(hud, '{id = "porto_borgo", porto = "borgo", needs = "porto_inner",', '{id = "porto_borgo", porto = "borgo", needs = "porto_harbour",', 'map borgo needs')
patch(hud, '{id = "porto_groves", porto = "groves", needs = "porto_inner",', '{id = "porto_groves", porto = "groves", needs = "porto_harbour",', 'map groves needs (step 2: porto_borgo)')
patch(hud, [[	if a.needs == "porto_inner" then                            -- the town and the groves: the More Squirrels Coming Soon wall's rule (ComingSoonServer)
		local w = workspace:FindFirstChild("ComingSoonWall")
		return (player:GetAttribute("Item_porto") or 0) >= 1 and (not w or w:GetAttribute("Enabled") == false
			or player.UserId == game.CreatorId or (player:GetAttribute("Found_porto") or 0) >= 15)
	end]], [[	if a.needs and a.needs:sub(1, 6) == "porto_" then            -- the town and the groves: the Porto gates' rule (10 found in the area before)
		return (player:GetAttribute("Item_porto") or 0) >= 1 and (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED
	end]], 'map rule')
for _, s in ipairs({fun, tonio, hud}) do
	local mm = Instance.new('ModuleScript') mm.Source = 'if true then return 0 end\n' .. s.Source mm.Parent = game.ServerStorage
	local ok, err = pcall(require, mm) mm:Destroy()
	log('parse', s.Name, ok, err)
end
game:GetService('ChangeHistoryService'):SetWaypoint('Porto gates step 1: old wall away, funicular/Tonio/map at 10 harbour finds')
return table.concat(LOG, '\n')

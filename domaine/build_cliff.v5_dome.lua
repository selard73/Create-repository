-- The Sandstone Climb: a honey sandstone cliff at the north edge of the Chateau grounds, behind the toadstool line, with a
-- bell to ring at the top. Shannon (Sep 26 2026): "The climbing wall definitely, keeping with the scenery, I want it light
-- stone like sandstone looking ... pretty against the landscape"; "What if we put the wall ... right next to the line of
-- toadstool jumping mushrooms ... That way you could jump up onto the wall from the mushrooms" - and a toadstool's bounce
-- (Trampolines.Bounce 100 = about 25 studs up) does reach the lower ledges: a secret shortcut for the clever.
--   THE CLIFF: horizontal beds of warm sandstone - honey, deep honey, light sand, thin ochre seams - like the ochre cliffs
--   of Provence, tallest at the west end (the summit, about 70 above the grass), sloping down to the east, with a rough
--   top edge, a few crags, scrub bushes along the top, ivy hanging down, and an umbrella pine beside the bell. Its face
--   looks south, over the garden wall, the cypresses and the toadstools. (First try, Sep 27: big square blocks in pale
--   colours read as grey concrete; the Sandstone material lightens a colour a lot, so these are deeper, warmer tones -
--   picked from a test grid of Sandstone / Slate / Rock / Limestone samples.)
--   THE WAY UP (every jump easy on a phone: gaps of 1.5 - 3.3 studs, rises of 3 - 4 studs; the game's jump is 7.2 high):
--   row one climbs east along the face from the start stone; a wide ledge, then an ivy trellis to climb; row two climbs
--   back west, well above row one (never a ledge overhead to bump into on a jump); a second wide ledge and a second
--   trellis to the summit - a flat top with the bell in a little stone gable. The ledges are pale shelves on a rock
--   support; the trellises are wooden with ivy (the climbable truss inside them is invisible).
--   THE EDGE OF THE MAP: the invisible boundary wall ran along z -250, right in front of the cliff's face. The part of it
--   in front of the way up comes out and walls go round the cliff's sides and back instead (up to y 140), so climbers
--   reach the top but can't go over the edge of the world. (What the wall was is kept in the folder's WallWas attribute.)
-- Phase 1 (this file for now): the cliff, the ledges, the trellises, the summit and bell, the start stone and its sign,
-- the boundary. The clock, the board, the bell's ring and the rewards come next.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("SandstoneClimb")
	local wallWas = old and old:GetAttribute("WallWas")                  -- (kept from the build that opened the map edge)
	if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "SandstoneClimb"
	wallWas = wallWas or opts.wallWas
	if wallWas then F:SetAttribute("WallWas", wallWas) end
	local rng = Random.new(opts.seed or 2609)
	local FACE = opts.faceZ or -253                                      -- the cliff's face (z); it looks toward +z (south)
	-- IN FRONT OF IT (probed Sep 27): the low garden wall (stone_wall_b, z -247.7..-246.3, 2.4 high), the cypress row
	-- (trunks every 16 studs at x 442, 458 ... 586, z -242, foliage down to the grass) and the toadstool line (caps z -233.5).
	-- The ledges stop 0.5 behind the wall; the way up starts in the gap between the cypresses at x 490 and 506.
	local BACK = FACE - 18                                               -- how far back the rock goes
	local XA, XB = 440, 592                                              -- the rock's length (its ends are behind the map edge)
	local CUT0, CUT1 = 468, 566                                          -- where the map edge opens in front of it
	local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {workspace.Terrain}
	local function ground(x, z)
		local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rpT)
		return hit and hit.Position.Y or 5
	end
	local SAND = Enum.Material.Sandstone
	local HONEY, DEEP, OCHRE, LIGHT = C(214, 158, 92), C(196, 136, 72), C(186, 106, 50), C(222, 182, 124)
	local LEDGE, UNDER, TOPC = C(234, 208, 160), C(214, 178, 124), C(228, 198, 146)   -- the way up paler, so it reads
	local WOOD, BARK = C(122, 86, 56), C(112, 80, 58)
	local IVY = {C(70, 112, 58), C(84, 128, 64), C(62, 100, 52)}
	local SCRUB = {C(104, 128, 70), C(90, 116, 64), C(120, 138, 80), C(84, 104, 60)}   -- garrigue: grey-green
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or SAND; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end
	local function soft(p) p.CanCollide = false; p.CanQuery = false; p.CastShadow = false; return p end   -- leaves, twigs

	-- ---------------------------------------------------------------- the way up, worked out first ----
	-- (the cliff is shaped round it: its top at the summit is the summit's floor)
	local RX0 = opts.startX or 498                                      -- the middle of the gap between the cypresses at 490 and 506
	local g0 = ground(RX0, FACE + 8)
	local R = {}                                                         -- {x, top, width, name}
	local rx, ry = RX0, g0 + 4.2                                         -- the first ledge: over the low wall, one easy jump
	for i = 1, 6 do table.insert(R, {rx, ry, 5.5}); if i < 6 then rx += 7.2; ry += 3.8 end end
	local tAy = ry + 3.0
	table.insert(R, {rx + 10.5, tAy, 9, "TurnA"})
	local TA = {rx + 14, tAy, tAy + 13}                                  -- trellis A: x, bottom, top (13 high: row two stays clear)
	local rx2, ry2 = rx + 10, tAy + 12.5                                 -- row two starts beside the top of trellis A
	table.insert(R, {rx2, ry2, 6})
	for _ = 1, 5 do rx2 -= 7; ry2 += 3.6; table.insert(R, {rx2, ry2, 5}) end
	local tBy = ry2 + 3.0
	table.insert(R, {rx2 - 9.5, tBy, 8, "TurnB"})
	local sumY = tBy + 9.5
	local TB = {rx2 - 12.5, tBy, sumY + 0.5}                             -- trellis B, up to the summit
	local SX, SZ = rx2 - 12, FACE - 7                                    -- the summit's middle
	local R0, R1 = RX0 - 6, TA[1] + 6                                    -- the stretch of face the way up uses

	-- ---------------------------------------------------------------- the shape of the rock ----
	-- the skyline: a steep stepped slope at the west end, the summit, the long slope down to the east, a low east end;
	-- never lower than 7 above a ledge or trellis in front of it (nothing sticks out over the top); wobbly, with crags
	local SUMF = sumY - 1.8                                              -- the summit's floor (the top slab sits on it)
	-- (a smooth slope cut into beds read as a stepped pyramid - Sep 27; the ends now drop in a few big uneven steps)
	local WEST = {{-1e9, 12}, {446, 30}, {452, 46}, {460, 57}, {468, SUMF - 6}}   -- {from x, height}
	local EAST = {{556, 44}, {563, 31}, {571, 19}, {580, 10}}
	local function stepFrom(list, x) local h = list[1][2]; for _, s in ipairs(list) do if x >= s[1] then h = s[2] end end; return h end
	local function baseTop(x)
		if x < 476 then return stepFrom(WEST, x) end
		if x <= SX + 13 then return SUMF end
		if x < 556 then return SUMF + (44 - SUMF) * (x - (SX + 13)) / (556 - (SX + 13)) end
		return stepFrom(EAST, x)
	end
	local function clearance(x)
		local h = -1e9
		for _, r in ipairs(R) do if math.abs(r[1] - x) < r[3] / 2 + 6 then h = math.max(h, r[2] + 7) end end
		if math.abs(TA[1] - x) < 7 then h = math.max(h, TA[3] + 7) end
		return h
	end
	local WOB = {}
	for i = 0, 60 do WOB[i] = rng:NextNumber(-2.2, 2.2) end
	local function wobble(x) local u = (x - XA) / 3; local i = math.floor(u); local f = u - i; return (WOB[i] or 0) * (1 - f) + (WOB[i + 1] or 0) * f end
	local function topAt(x)
		if x >= SX - 13 and x <= SX + 13 then return SUMF end
		return math.max(baseTop(x) + wobble(x), clearance(x))
	end
	local function nearRoute(x) return x > R0 and x < R1 end
	local function bulge(x) return (0.9 * math.sin(x / 8.3) + 0.5 * math.sin(x / 3.7 + 1.3)) * (nearRoute(x) and 0.3 or 1) end   -- the face waves a little
	local function smooth(u) u = math.clamp(u, 0, 1); return u * u * (3 - 2 * u) end
	local function recede(x)                                             -- the ends curve back into the hill
		if x < 486 then return 8 * smooth((486 - x) / 42) end
		if x > 556 then return 8 * smooth((x - 556) / 34) end
		return 0
	end
	local function faceAt(x) return FACE + bulge(x) - recede(x) end

	-- ---------------------------------------------------------------- the beds ----
	local cliff = Instance.new("Model"); cliff.Name = "Cliff"; cliff.Parent = F
	local BEDS = {HONEY, DEEP, LIGHT, HONEY, OCHRE, DEEP, HONEY, LIGHT, DEEP, OCHRE, HONEY, LIGHT, DEEP, HONEY, OCHRE, LIGHT, HONEY, DEEP, LIGHT, HONEY}
	local y, k = 0, 0
	local top0 = sumY + 12
	while y < top0 do
		k += 1
		local col = BEDS[(k - 1) % #BEDS + 1]
		local t = (col == OCHRE) and rng:NextNumber(1.8, 2.8) or rng:NextNumber(3.6, 5.4)
		local off = rng:NextNumber(-0.5, 0.5)                            -- the whole bed sits a little in or out
		local x = XA
		while x < XB - 1 do
			local near = y > topAt(x + 4) - 9
			local w = math.min(near and rng:NextNumber(3.5, 7) or rng:NextNumber(12, 22), XB - x)
			local xm = x + w / 2
			local top = topAt(xm)
			if y < top - 0.6 then
				local h = math.min(t, top - y)
				if top - (y + h) < 1.2 then h = top - y end               -- no sliver on top
				local calm = nearRoute(xm) and 0.5 or 1                   -- (near the way up the face stays even: no stray footholds)
				local front = faceAt(xm) + off * calm + rng:NextNumber(-0.5, 0.5) * calm
				local depth = front - BACK
				part("Rock", Vector3.new(w + 0.5, h + 0.2, depth), CFrame.new(xm, y + h / 2, front - depth / 2)
					* CFrame.Angles(0, math.rad(rng:NextNumber(-1.5, 1.5)), math.rad(rng:NextNumber(-1.4, 1.4) * calm)), col, SAND, cliff)
			end
			x += w
		end
		y += t
	end
	-- crags: a few narrow rocks standing up along the top edge (none where the way up arrives)
	for _, cx in ipairs({449, 457, 464, 518, 530, 541, 560, 575}) do
		local base = topAt(cx)
		local hgt = rng:NextNumber(3, 5.5)
		local w, d = rng:NextNumber(3, 4.6), rng:NextNumber(3.5, 5.5)
		local cz = faceAt(cx) - d / 2 - rng:NextNumber(0.5, 3)
		local lower = part("Crag", Vector3.new(w, hgt + 1, d), CFrame.new(cx, base + hgt / 2 - 0.5, cz) * CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), math.rad(rng:NextNumber(-25, 25)), math.rad(rng:NextNumber(-7, 7))),
			BEDS[rng:NextInteger(1, 4)], SAND, cliff)
		local h2 = rng:NextNumber(1.8, 3.2)
		part("Crag", Vector3.new(w * 0.7, h2, d * 0.7), lower.CFrame * CFrame.new(rng:NextNumber(-0.5, 0.5), (hgt + 1) / 2 + h2 / 2 - 0.3, 0) * CFrame.Angles(0, math.rad(rng:NextNumber(-30, 30)), math.rad(rng:NextNumber(-8, 8))),
			BEDS[rng:NextInteger(1, 4)], SAND, cliff)
	end
	-- a few boulders at the foot, where the cliff meets the grass (they soften the line; none under the way up). They sit
	-- behind the garden wall and are small enough, turned any way, never to poke through it (front <= z -248.4).
	for _, bx in ipairs({476, 483, 555, 561}) do
		local s = rng:NextNumber(3.4, 4.4)
		local gy = ground(bx, FACE + 1.5)
		part("Boulder", Vector3.new(s * 1.2, s, s * 0.9), CFrame.new(bx, gy + s * 0.3, FACE + 1.3) * CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-10, 10))), HONEY, SAND, cliff)
	end

	-- ---------------------------------------------------------------- green things ----
	local green = Instance.new("Model"); green.Name = "Green"; green.Parent = F
	local function bush(x, yy, z, s)
		soft(part("Bush", Vector3.new(s, s, s), CFrame.new(x, yy, z), SCRUB[rng:NextInteger(1, #SCRUB)], Enum.Material.Grass, green, Enum.PartType.Ball))
		if rng:NextNumber() < 0.6 then
			local s2 = s * rng:NextNumber(0.55, 0.8)
			soft(part("Bush", Vector3.new(s2, s2, s2), CFrame.new(x + rng:NextNumber(-s * 0.5, s * 0.5), yy - s * 0.1, z + rng:NextNumber(-s * 0.4, s * 0.4)), SCRUB[rng:NextInteger(1, #SCRUB)], Enum.Material.Grass, green, Enum.PartType.Ball))
		end
	end
	-- scrub along the top edge (not on the summit slab, which has its pine)
	for x = XA + 2, XB - 2, 4.5 do
		if (x < SX - 14 or x > SX + 14) and rng:NextNumber() < 0.55 then
			local s = rng:NextNumber(1.8, 3.4)
			bush(x + rng:NextNumber(-1.5, 1.5), topAt(x) + s * 0.25, faceAt(x) - rng:NextNumber(0.8, 4), s)
		end
	end
	for _, sx in ipairs({447, 453, 461, 469, 564, 572, 581}) do                           -- on the big steps at the ends
		local s = rng:NextNumber(2, 3.2)
		bush(sx + rng:NextNumber(0, 2), topAt(sx + 1) + s * 0.25, faceAt(sx) - rng:NextNumber(1, 3), s)
	end
	-- a few at the foot, behind the wall, away from the way up
	for _, fx in ipairs({470, 480, 487, 552, 558, 564}) do bush(fx, ground(fx, FACE + 1.2) + 0.5, FACE + 1.3, rng:NextNumber(1.6, 2.6)) end
	-- ivy hanging down the face, away from the way up
	for _, ix in ipairs({450, 463, 474, 484, 556, 567, 573, 583}) do
		local yy = topAt(ix) - 0.5
		local len = rng:NextNumber(12, 22)
		local xx = ix
		for i = 0, math.floor(len / 1.3) do
			local s = rng:NextNumber(0.9, 1.6)
			soft(part("Ivy", Vector3.new(s, s, s), CFrame.new(xx, yy - i * 1.3, faceAt(xx) + 0.45), IVY[rng:NextInteger(1, #IVY)], Enum.Material.Grass, green, Enum.PartType.Ball))
			xx += rng:NextNumber(-0.6, 0.6)
		end
	end

	-- ---------------------------------------------------------------- the way up ----
	local route = Instance.new("Model"); route.Name = "Route"; route.Parent = F
	local LD = 4.8                                                       -- how far a ledge stands out from the face
	local n = 0
	local function ledge(x, topY, w, name)
		n += 1
		local p = part(name or string.format("Ledge%02d", n), Vector3.new(w, 1.3, LD + 3), CFrame.new(x, topY - 0.65, FACE + LD - (LD + 3) / 2), LEDGE, SAND, route)
		p:SetAttribute("Step", n)
		-- the rock under it, tapering back into the face, so it reads as a shelf of the cliff and not a plank
		local hc = math.min(1.8, 1.2 + w * 0.08)
		local u = Instance.new("WedgePart"); u.Name = "Under"; u.Anchored = true; u.Size = Vector3.new(w - 1.2, hc, LD - 0.4)
		u.CFrame = CFrame.new(x, topY - 1.3 - hc / 2, FACE + (LD - 0.4) / 2) * CFrame.Angles(math.pi, 0, 0)
		u.Color = UNDER; u.Material = SAND; u.TopSurface = Enum.SurfaceType.Smooth; u.BottomSurface = Enum.SurfaceType.Smooth; u.Parent = route
		return p
	end
	local function trellis(x, y0, y1)                                    -- the climbable truss is invisible; you see wood and ivy
		local t = Instance.new("TrussPart"); t.Name = "Trellis"; t.Anchored = true; t.Size = Vector3.new(2, y1 - y0, 2)
		t.CFrame = CFrame.new(x, (y0 + y1) / 2, FACE + 1.0); t.Transparency = 1; t.Parent = route
		local H = y1 - y0
		for _, s in ipairs({-0.95, 0.95}) do soft(part("Rail", Vector3.new(0.3, H + 0.4, 0.3), CFrame.new(x + s, (y0 + y1) / 2, FACE + 1.65), WOOD, Enum.Material.Wood, route)) end
		for yy = y0 + 0.7, y1 - 0.2, 1.25 do soft(part("Rung", Vector3.new(2.2, 0.22, 0.22), CFrame.new(x, yy, FACE + 1.8), WOOD, Enum.Material.Wood, route)) end
		for i = 1, math.floor(H / 1.4) do
			local s = rng:NextNumber(0.7, 1.2)
			soft(part("Leaf", Vector3.new(s, s, s), CFrame.new(x + rng:NextNumber(-1.4, 1.4), y0 + i * 1.4 - rng:NextNumber(0, 0.9), FACE + rng:NextNumber(0.9, 1.9)), IVY[rng:NextInteger(1, #IVY)], Enum.Material.Grass, route, Enum.PartType.Ball))
		end
		return t
	end
	for _, r in ipairs(R) do ledge(r[1], r[2], r[3], r[4]) end
	trellis(TA[1], TA[2], TA[3])
	trellis(TB[1], TB[2], TB[3])
	F:SetAttribute("Steps", n)

	-- ---------------------------------------------------------------- the summit, its bell and its pine ----
	local top = Instance.new("Model"); top.Name = "Summit"; top.Parent = F
	part("Top", Vector3.new(26, 2, 15), CFrame.new(SX, sumY - 1, SZ), TOPC, SAND, top)
	-- the bell gable: two pillars, a lintel, a little roof, and the bronze bell hanging between them
	local BRONZE, STONE = C(176, 124, 58), C(236, 222, 190)
	local gx, gz = SX - 2, SZ - 3
	for _, s in ipairs({-1, 1}) do part("Pillar", Vector3.new(1.4, 7.5, 1.4), CFrame.new(gx + s * 3.2, sumY + 3.75, gz), STONE, Enum.Material.Limestone, top) end
	part("Lintel", Vector3.new(8.2, 1.1, 1.8), CFrame.new(gx, sumY + 8.05, gz), STONE, Enum.Material.Limestone, top)
	local roof = Instance.new("WedgePart"); roof.Name = "Cap"; roof.Anchored = true; roof.Size = Vector3.new(1.8, 1.4, 4.2); roof.Color = C(186, 116, 90)
	roof.Material = Enum.Material.Slate; roof.CFrame = CFrame.new(gx - 2.05, sumY + 9.3, gz) * CFrame.Angles(0, math.pi / 2, 0); roof.Parent = top
	local roof2 = roof:Clone(); roof2.CFrame = CFrame.new(gx + 2.05, sumY + 9.3, gz) * CFrame.Angles(0, -math.pi / 2, 0); roof2.Parent = top
	local bell = Instance.new("Model"); bell.Name = "Bell"; bell.Parent = top
	local hang = CFrame.new(gx, sumY + 7.5, gz)                          -- where it hangs from
	part("Yoke", Vector3.new(0.6, 0.6, 0.6), hang, C(90, 60, 30), Enum.Material.Wood, bell)
	local body = part("Body", Vector3.new(2.4, 2.4, 2.4), hang * CFrame.new(0, -1.9, 0), BRONZE, Enum.Material.Metal, bell, Enum.PartType.Ball)
	body.Size = Vector3.new(2.3, 2.9, 2.3)
	part("Lip", Vector3.new(0.35, 3.0, 3.0), hang * CFrame.new(0, -3.2, 0) * CFrame.Angles(0, 0, math.pi / 2), BRONZE, Enum.Material.Metal, bell, Enum.PartType.Cylinder)
	part("Clapper", Vector3.new(0.7, 0.7, 0.7), hang * CFrame.new(0, -3.4, 0), C(70, 50, 30), Enum.Material.Metal, bell, Enum.PartType.Ball)
	for _, p in ipairs(bell:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
	bell.PrimaryPart = bell:FindFirstChild("Yoke")
	-- where the bell is reached (the clock and the ring come in the next step)
	local zone = part("BellZone", Vector3.new(7, 7, 5), CFrame.new(gx, sumY + 3.5, gz + 0.5), C(255, 255, 255), nil, top)
	zone.Transparency = 1; zone.CanCollide = false; zone.CanQuery = false
	F:SetAttribute("SummitY", sumY)
	-- an umbrella pine at the west end of the top: a leaning trunk and flat green crowns, the Provence skyline tree
	local px, pz = SX - 11, SZ - 5.5
	local lean = CFrame.Angles(0, 0, math.rad(-7))
	local trunkCF = CFrame.new(px, sumY, pz) * lean
	part("Trunk", Vector3.new(9.5, 1.1, 1.1), trunkCF * CFrame.new(0, 4.75, 0) * CFrame.Angles(0, 0, math.pi / 2), BARK, Enum.Material.Wood, top, Enum.PartType.Cylinder)
	local crown = trunkCF * CFrame.new(0, 9.5, 0)
	for _, c in ipairs({{0, 0, 0, 9.5, 1.7}, {1.2, 1.1, -0.6, 6.8, 1.6}, {-1.6, 0.5, 1.0, 5.6, 1.4}}) do
		local d = part("Crown", Vector3.new(c[5], c[4], c[4]), CFrame.new((crown * CFrame.new(c[1], c[2], c[3])).Position) * CFrame.Angles(0, 0, math.pi / 2), IVY[1], Enum.Material.Grass, top, Enum.PartType.Cylinder)
		d.CanCollide = false
	end
	for _, b in ipairs({{SX + 10, SZ + 5}, {SX + 11.5, SZ - 5}, {SX - 11, SZ + 5.5}}) do bush(b[1], sumY + 0.6, b[2], rng:NextNumber(1.6, 2.4)) end

	-- ---------------------------------------------------------------- the start stone and its sign ----
	local start = Instance.new("Model"); start.Name = "Start"; start.Parent = F
	-- in the gap between the cypresses (their foliage reaches x 492.8 and 503.1 and comes down to the grass), just in front
	-- of the garden wall's face (z -246.3); the sign is a slanted board on a little pedestal at the stone's west end
	local stX, stZ = opts.startX or 498, opts.startZ or -243.3
	local sgY = ground(stX, stZ)
	part("StartStone", Vector3.new(8, 1, 5), CFrame.new(stX, sgY + 0.3, stZ), LEDGE, SAND, start)
	local sTop = sgY + 0.8
	local lx = stX - 2.3
	part("Pedestal", Vector3.new(1, 1.7, 0.8), CFrame.new(lx, sTop + 0.85, stZ - 0.4), LEDGE, SAND, start)
	local board = part("Sign", Vector3.new(3.4, 1.9, 0.25), CFrame.new(lx, sTop + 1.95, stZ - 0.1) * CFrame.Angles(math.rad(-50), math.pi, 0), C(244, 232, 204), Enum.Material.Wood, start)
	local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 60; gui.LightInfluence = 0.4; gui.Parent = board
	local l1 = Instance.new("TextLabel"); l1.BackgroundTransparency = 1; l1.Size = UDim2.new(1, -16, 0, 56); l1.Position = UDim2.new(0, 8, 0, 8)
	l1.Font = Enum.Font.FredokaOne; l1.Text = "SANDSTONE CLIMB"; l1.TextScaled = true; l1.TextColor3 = C(62, 40, 26); l1.Parent = gui
	local l2 = Instance.new("TextLabel"); l2.BackgroundTransparency = 1; l2.Size = UDim2.new(1, -16, 0, 40); l2.Position = UDim2.new(0, 8, 0, 66)
	l2.Font = Enum.Font.FredokaOne; l2.Text = "climb to the top and ring the bell"; l2.TextScaled = true; l2.TextColor3 = C(150, 100, 50); l2.Parent = gui
	F:SetAttribute("StartX", stX); F:SetAttribute("StartZ", stZ)

	-- ---------------------------------------------------------------- the edge of the map ----
	-- the invisible wall along z -250 comes out in front of the way up; walls go round the cliff's sides and back instead
	local wallsDone = {}
	for _, b in ipairs(workspace:GetChildren()) do
		local W = b.Name == "Boundary" and b:FindFirstChild("Walls")
		if W then
			for _, w in ipairs(W:GetDescendants()) do
				if w:IsA("BasePart") and w.Name == "Wall" and math.abs(w.Position.Z + 250) < 3 and math.abs(w.Orientation.Y) < 1
					and w.Position.X - w.Size.X / 2 < CUT0 and w.Position.X + w.Size.X / 2 > CUT1 then
					local a0, a1 = w.Position.X - w.Size.X / 2, w.Position.X + w.Size.X / 2
					F:SetAttribute("WallWas", string.format("%.3f,%.3f,%.3f,%.3f,%.3f,%.3f", w.Position.X, w.Position.Y, w.Position.Z, w.Size.X, w.Size.Y, w.Size.Z))
					local west = w:Clone(); west.Size = Vector3.new(CUT0 - a0, w.Size.Y, w.Size.Z); west.Position = Vector3.new((a0 + CUT0) / 2, w.Position.Y, w.Position.Z); west.Parent = w.Parent
					local east = w:Clone(); east.Size = Vector3.new(a1 - CUT1, w.Size.Y, w.Size.Z); east.Position = Vector3.new((CUT1 + a1) / 2, w.Position.Y, w.Position.Z); east.Parent = w.Parent
					w:Destroy()
					table.insert(wallsDone, string.format("split the wall at z %.0f: %.0f..%.0f and %.0f..%.0f", east.Position.Z, a0, CUT0, CUT1, a1))
				end
			end
		end
	end
	local fence = Instance.new("Model"); fence.Name = "Fence"; fence.Parent = F
	local wz0, wz1, WY0, WY1 = -249.4, BACK - 2, -4, 140                 -- (from inside the cut wall's thickness, z -250)
	for _, wx in ipairs({CUT0, CUT1}) do
		local w = part("Wall", Vector3.new(1, WY1 - WY0, wz0 - wz1), CFrame.new(wx, (WY0 + WY1) / 2, (wz0 + wz1) / 2), C(255, 255, 255), nil, fence)
		w.Transparency = 1; w.CanQuery = false
	end
	local wb = part("Wall", Vector3.new(CUT1 - CUT0 + 1, WY1 - WY0, 1), CFrame.new((CUT0 + CUT1) / 2, (WY0 + WY1) / 2, wz1), C(255, 255, 255), nil, fence)
	wb.Transparency = 1; wb.CanQuery = false

	F.Parent = workspace
	print(string.format("SandstoneClimb: %d ledges, summit at y %.1f (%.1f above the start), %d pieces, %s", n, sumY, sumY - sgY, #F:GetDescendants(), #wallsDone > 0 and wallsDone[1] or "boundary wall already opened"))
	return F
end

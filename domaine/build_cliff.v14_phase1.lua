-- The Sandstone Climb: a honey sandstone cliff at the north edge of the Chateau grounds, behind the toadstool line, with a
-- bell to ring at the top. Shannon (Sep 26 2026): "The climbing wall definitely, keeping with the scenery, I want it light
-- stone like sandstone looking ... pretty against the landscape"; "What if we put the wall ... right next to the line of
-- toadstool jumping mushrooms ... That way you could jump up onto the wall from the mushrooms" - and a toadstool's bounce
-- (Trampolines.Bounce 100 = about 25 studs up) does reach the lower ledges: a secret shortcut for the clever.
--   THE CLIFF: horizontal beds of warm sandstone - honey, deep honey, light sand, thin ochre seams - like the ochre cliffs
--   of Provence, tallest at the west end (the summit, about 70 above the grass), sloping down to the east, with a rough
--   top edge; the game's own bushes, boxwood, oleanders, pines and olive trees (kit clones) along the top, on the end
--   steps and round its foot, with sandstone scree and a strip of earth; an olive tree beside the bell. Its face
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
	local LIME = Enum.Material.Limestone                                 -- the way up (Sandstone turned its pale colour a cold grey)
	local HONEY, DEEP, OCHRE, LIGHT = C(214, 158, 92), C(196, 136, 72), C(186, 106, 50), C(222, 182, 124)
	local LEDGE, UNDER, TOPC = C(228, 200, 150), C(208, 174, 124), C(220, 190, 140)   -- the way up a little paler, so it reads (paler still read cold grey)
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
	table.insert(R, {rx + 11, tAy, 10, "TurnA"})
	-- trellis A: x, bottom, top (13 high: row two stays clear). One stud further east than first built (Sep 27 climb test:
	-- at rx + 14 the end of row two's first ledge brushed a climber's shoulder and the climb stalled halfway)
	local TA = {rx + 15, tAy, tAy + 13}
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
	-- A BUTTE, the way sandstone weathers: a high flat top (the bell and the pine on it), a lower shoulder over the east
	-- half of the way up, and ends that drop in a few big uneven steps. (Sep 27: a smooth slope cut into beds read as a
	-- stepped pyramid, and a slope from the summit down to the east as a dome.)
	local SHOULDER = 58                                                  -- (row two's ledges there top out at 57; +7 is kept anyway)
	local PROFILE = {{-1e9, 12}, {446, 30}, {452, 46}, {460, 58}, {468, SUMF - 1}, {526, SHOULDER}, {556, 44}, {563, 31}, {571, 19}, {580, 10}}   -- {from x, height}
	local function baseTop(x)
		local h = PROFILE[1][2]
		for _, s in ipairs(PROFILE) do if x >= s[1] then h = s[2] end end
		return h
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
	local function lipAt(x) return 0.6 end                               -- how far the stone stands out of the face line, at most
	-- THE SCULPTED ROCK (Shannon, Sep 27: "light golden", "sculpted model", after two sandstone photos): opts.cliff is the
	-- data gen_cliff_mesh.py writes - its skyline, face line and lips, a stud apart; where each imported chunk goes; and
	-- the invisible blocks that make the rock solid (the mesh itself doesn't collide)
	local CL = opts.cliff
	if CL then
		local function sample(list, x)
			local u = x - CL.x0 + 1
			local i = math.clamp(math.floor(u), 1, #list - 1)
			local f = math.clamp(u - i, 0, 1)
			return list[i] * (1 - f) + list[i + 1] * f
		end
		topAt = function(x) return sample(CL.top, x) end
		faceAt = function(x) return sample(CL.face, x) end
		lipAt = function(x) return sample(CL.lip, x) end
	end

	-- ---------------------------------------------------------------- the rock ----
	local cliff = Instance.new("Model"); cliff.Name = "Cliff"; cliff.Parent = F
	if CL then
		-- the mesh chunks and boulders (imported once with Import 3D, kept in ServerStorage.SandCliffKit), where they belong
		local kit = game:GetService("ServerStorage"):FindFirstChild("SandCliffKit")
		local placed, missing = 0, {}
		for name, centre in pairs(CL.centres) do
			local src = kit and kit:FindFirstChild(name, true)
			if src and src:IsA("BasePart") then
				local m = src:Clone()
				m.Anchored = true; m.CanCollide = false; m.CanTouch = false; m.CanQuery = true
				m.CFrame = CFrame.new(centre) * (opts.cliffTurn or CFrame.identity)
				m.Parent = cliff
				placed += 1
			else
				table.insert(missing, name)
			end
		end
		F:SetAttribute("MeshPieces", placed)
		if #missing > 0 then F:SetAttribute("MeshMissing", table.concat(missing, ",")) end
		-- the rock's solid shape: 2-stud-wide blocks from underground to its skyline, from its face line back to the edge
		for _, b in ipairs(CL.boxes) do
			local x, topY, front = b[1], b[2], b[3]
			local h, d = topY + 4, front - BACK
			local p = part("Rock", Vector3.new(2.05, h, d), CFrame.new(x, topY - h / 2, front - d / 2), HONEY, SAND, cliff)
			p.Transparency = 1; p.CanQuery = false; p.CastShadow = false
		end
	else
	-- (no sculpted rock: beds of Parts, as first built)
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
	end

	-- ---------------------------------------------------------------- plants, scree and dirt ----
	-- The game's own low-poly plants and rocks, cloned from the kits. (Shannon, Sep 27: the ball bushes and ivy "just looks
	-- like dots of peas", and the foot "should have more bushes and foliage around it and dirt and stuff".) Kit pivots sit
	-- far from their parts (and may be tipped), so everything is turned and set down by its parts' own box.
	local green = Instance.new("Model"); green.Name = "Green"; green.Parent = F
	local KITS = {bush_big = "ForestKit", bush_small = "ForestKit", pine_squat = "ForestKit", rock_big = "ForestKit", rock_cluster = "ForestKit",
		oleander = "DomaineKit", boxwood = "DomaineKit", olive_tree = "DomaineKit"}
	local LEAF = {C(96, 128, 72), C(86, 118, 66), C(108, 138, 80)}                -- garrigue greens for the forest bushes
	local STONES = {C(214, 176, 120), C(224, 190, 138), C(204, 164, 110)}         -- the forest rocks, in the cliff's sandstone
	local BLOOMS = {C(236, 148, 176), C(244, 190, 206), C(250, 248, 240)}         -- oleanders: pink, pale pink, white
	local function colours(name)
		if name == "bush_big" or name == "bush_small" then return {Leaf = LEAF[rng:NextInteger(1, #LEAF)]} end
		if name == "boxwood" then return {Boxwood = C(72, 116, 62)} end
		if name == "oleander" then return {Oleander = C(84, 132, 76), Bloom = BLOOMS[rng:NextInteger(1, #BLOOMS)]} end
		if name == "olive_tree" then return {Olive = C(152, 170, 132), OTrunk = C(108, 88, 66)} end
		if name == "pine_squat" then return {Foliage = C(72, 120, 74), Trunk = C(104, 78, 56)} end
		local s = STONES[rng:NextInteger(1, #STONES)]
		return {Rock1 = s, Rock2 = s, Rock3 = s, Rock4 = s}
	end
	local function aabb(m)
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, q in ipairs(m:GetDescendants()) do
			if q:IsA("BasePart") then
				local cf, s = q.CFrame, q.Size / 2
				local ext = Vector3.new(
					math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
					math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
					math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z)
				lo = lo:Min(cf.Position - ext); hi = hi:Max(cf.Position + ext)
			end
		end
		return lo, hi
	end
	local placedN = 0
	local function kit(name, x, y, z, scale, solid)
		local home = workspace:FindFirstChild(KITS[name])
		local src = home and home:FindFirstChild(name)
		if not src then return nil end
		local m = src:Clone()
		if scale and scale ~= 1 then m:ScaleTo(m:GetScale() * scale) end
		local lo, hi = aabb(m)
		local c = (lo + hi) / 2
		m:PivotTo(CFrame.new(c) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0) * CFrame.new(-c) * m:GetPivot())   -- turned about its middle
		lo, hi = aabb(m)
		m:PivotTo(m:GetPivot() + Vector3.new(x - (lo.X + hi.X) / 2, y - lo.Y, z - (lo.Z + hi.Z) / 2))                  -- its bottom middle on the spot
		local col = colours(name)
		for _, q in ipairs(m:GetDescendants()) do
			if q:IsA("BasePart") then
				q.Anchored = true; q.Transparency = 0; q.CanCollide = solid == true; q.CanQuery = solid == true; q.CanTouch = false   -- (kit templates are hidden)
				if col[q.Name] then q.Color = col[q.Name] end
			end
		end
		m.Parent = green
		placedN += 1
		return m
	end
	local WALLBACK = -248.4                                              -- just behind the garden wall (its back face is at -247.7)
	-- the foot: bushes, boxwood, oleanders and sandstone scree between the garden wall and the rock (the first ledge's
	-- approach stays open)
	local x = XA + 1
	while x < XB - 1 do
		local fz = faceAt(x)
		local room = WALLBACK - fz
		if math.abs(x - RX0) > 6.5 and room > 1.6 then
			local r = rng:NextNumber()
			local z = fz + math.clamp(rng:NextNumber(1.2, 2.8), 1.0, room - 1.0)
			local gy = ground(x, z)
			if r < 0.26 then kit("rock_cluster", x, gy - 0.3, z, rng:NextNumber(0.7, 1.1))
			elseif r < 0.36 then kit("rock_big", x, gy - 0.5, fz + 1.8, rng:NextNumber(0.55, 0.8), true)
			elseif r < 0.64 then kit(room > 5 and "bush_big" or "bush_small", x, gy - 0.2, z, rng:NextNumber(0.75, 1.05))
			elseif r < 0.8 then kit("boxwood", x, gy - 0.1, z, rng:NextNumber(0.9, 1.3))
			else kit("oleander", x, gy - 0.2, fz + math.clamp(2.2, 1.0, room - 2.0), rng:NextNumber(0.6, 0.85)) end
		end
		x += rng:NextNumber(3.2, 5.5)
	end
	-- a few trees at the foot of the two ends (behind the map edge: to look at)
	for _, tr in ipairs({{446, "olive_tree", 0.75}, {457, "olive_tree", 0.65}, {578, "olive_tree", 0.7}, {587, "olive_tree", 0.8}}) do
		local tz = faceAt(tr[1]) + 3.4
		kit(tr[2], tr[1], ground(tr[1], tz) - 0.3, tz, tr[3])
	end
	-- on the big steps at the ends, and along the rim of the top
	for _, sx in ipairs({447, 455, 463, 559, 567, 575, 584}) do
		local name = (sx == 455 or sx == 567) and "olive_tree" or (rng:NextNumber() < 0.5 and "bush_big" or "boxwood")
		kit(name, sx + rng:NextNumber(-1, 1), topAt(sx) - 0.3, faceAt(sx) - rng:NextNumber(2.5, 4.5), name == "olive_tree" and 0.55 or rng:NextNumber(0.8, 1.1))
	end
	for _, tx in ipairs({472, 477, 516, 523, 530, 537, 545, 552}) do
		kit(rng:NextNumber() < 0.5 and "bush_small" or "boxwood", tx + rng:NextNumber(-1, 1), topAt(tx) - 0.2, faceAt(tx) - rng:NextNumber(2, 4), rng:NextNumber(0.9, 1.3))
	end
	-- earth: the lawn behind the garden wall turns to warm earth at the rock's foot, with pale sand where the rock crumbles.
	-- (The map's Ground rendered near-black here and its Sand blue-grey; Sandstone and Limestone terrain are used nowhere
	-- else in the map - checked Sep 27 - so they are tinted and used for the foot alone.)
	pcall(function()
		local T = workspace.Terrain
		T:SetMaterialColor(Enum.Material.Sandstone, C(200, 162, 110))
		T:SetMaterialColor(Enum.Material.Limestone, C(226, 202, 152))
		-- first put back the lawn anywhere an earlier build painted (a rectangle), then paint a band along the foot
		local all = Region3.new(Vector3.new(XA - 8, -16, -268), Vector3.new(XB + 8, 40, -248)):ExpandToGrid(4)
		for _, m in ipairs({Enum.Material.Ground, Enum.Material.Sand, Enum.Material.Sandstone, Enum.Material.Limestone}) do T:ReplaceMaterial(all, 4, m, Enum.Material.Grass) end
		for x0 = XA - 4, XB + 4, 4 do
			local fz = faceAt(math.clamp(x0 + 2, XA, XB))
			local z0, z1 = fz - 3, math.min(fz + 5.5, -248)
			if z1 > z0 then
				local band = Region3.new(Vector3.new(x0, -16, z0), Vector3.new(x0 + 4, 40, z1)):ExpandToGrid(4)
				local pale = (x0 >= 448 and x0 < 456) or (x0 >= 476 and x0 < 484) or (x0 >= 536 and x0 < 544) or (x0 >= 568 and x0 < 576)
				T:ReplaceMaterial(band, 4, Enum.Material.Grass, pale and Enum.Material.Limestone or Enum.Material.Sandstone)
			end
		end
	end)

	-- ---------------------------------------------------------------- the way up ----
	local route = Instance.new("Model"); route.Name = "Route"; route.Parent = F
	local LD = 4.8                                                       -- how far a ledge stands out from the face
	local n = 0
	local function ledge(x, topY, w, name)
		n += 1
		local p = part(name or string.format("Ledge%02d", n), Vector3.new(w, 1.3, LD + 3), CFrame.new(x, topY - 0.65, FACE + LD - (LD + 3) / 2), LEDGE, LIME, route)
		p:SetAttribute("Step", n)
		-- a rounded front, like the rock's own layers (a square edge read as a board stuck on the cliff)
		part("Lip", Vector3.new(w, 1.3, 1.3), CFrame.new(x, topY - 0.65, FACE + LD), LEDGE, LIME, route, Enum.PartType.Cylinder)
		-- the rock under it, tapering back into the face, so it reads as a shelf of the cliff and not a plank
		local hc = math.min(1.8, 1.2 + w * 0.08)
		local u = Instance.new("WedgePart"); u.Name = "Under"; u.Anchored = true; u.Size = Vector3.new(w - 1.2, hc, LD - 0.4)
		u.CFrame = CFrame.new(x, topY - 1.3 - hc / 2, FACE + (LD - 0.4) / 2) * CFrame.Angles(math.pi, 0, 0)
		u.Color = UNDER; u.Material = LIME; u.TopSurface = Enum.SurfaceType.Smooth; u.BottomSurface = Enum.SurfaceType.Smooth; u.Parent = route
		return p
	end
	local function trellis(x, y0, y1)                                    -- the climbable truss is invisible; you see the wood
		local t = Instance.new("TrussPart"); t.Name = "Trellis"; t.Anchored = true; t.Size = Vector3.new(2, y1 - y0, 2)
		t.CFrame = CFrame.new(x, (y0 + y1) / 2, FACE + 1.0); t.Transparency = 1; t.Parent = route
		local H = y1 - y0
		for _, s in ipairs({-0.95, 0.95}) do soft(part("Rail", Vector3.new(0.3, H + 0.4, 0.3), CFrame.new(x + s, (y0 + y1) / 2, FACE + 1.65), WOOD, Enum.Material.Wood, route)) end
		for yy = y0 + 0.7, y1 - 0.2, 1.25 do soft(part("Rung", Vector3.new(2.2, 0.22, 0.22), CFrame.new(x, yy, FACE + 1.8), WOOD, Enum.Material.Wood, route)) end
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
	-- an olive tree at the west end of the top, boxwood by the slab (the disc pine and ball bushes read as "dots of peas")
	kit("olive_tree", SX - 11, sumY - 0.2, SZ - 5.5, 0.8)
	for _, b in ipairs({{SX + 10.5, SZ + 5}, {SX + 11.5, SZ - 5}, {SX - 11.5, SZ + 5.5}}) do kit("boxwood", b[1], sumY - 0.1, b[2], rng:NextNumber(1.0, 1.3)) end
	F:SetAttribute("Plants", placedN)

	-- ---------------------------------------------------------------- the start stone and its sign ----
	local start = Instance.new("Model"); start.Name = "Start"; start.Parent = F
	-- in the gap between the cypresses (their foliage reaches x 492.8 and 503.1 and comes down to the grass), just in front
	-- of the garden wall's face (z -246.3); the sign is a slanted board on a little pedestal at the stone's west end
	local stX, stZ = opts.startX or 498, opts.startZ or -243.3
	local sgY = ground(stX, stZ)
	part("StartStone", Vector3.new(8, 1, 5), CFrame.new(stX, sgY + 0.3, stZ), LEDGE, LIME, start)
	local sTop = sgY + 0.8
	local lx = stX - 2.3
	part("Pedestal", Vector3.new(1, 1.7, 0.8), CFrame.new(lx, sTop + 0.85, stZ - 0.4), LEDGE, LIME, start)
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

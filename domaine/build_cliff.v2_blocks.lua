-- The Sandstone Climb: a honey sandstone cliff at the north edge of the Chateau grounds, behind the toadstool line, with a
-- bell to ring at the top. Shannon (Sep 26 2026): "The climbing wall definitely, keeping with the scenery, I want it light
-- stone like sandstone looking ... pretty against the landscape"; "What if we put the wall ... right next to the line of
-- toadstool jumping mushrooms ... That way you could jump up onto the wall from the mushrooms" - and a toadstool's bounce
-- (Trampolines.Bounce 100 = about 25 studs up) does reach the lower ledges: a secret shortcut for the clever.
--   THE CLIFF: a low-poly outcrop of big faceted sandstone blocks, banded like real sandstone (honey, ochre, cream strata),
--   tallest at the west end (the summit, about 70 above the grass) stepping down to the east. Its face looks south,
--   over the toadstools and the vineyard.
--   THE WAY UP (every jump easy on a phone: gaps of 1.5 - 3.3 studs, rises of 3 - 4 studs; the game's jump is 7.2 high):
--   row one climbs east along the face from the start stone; a wide ledge, then an ivy trellis to climb; row two climbs
--   back west, well above row one (never a ledge overhead to bump into on a jump); a second wide ledge and a second
--   trellis to the summit - a flat top with the bell in a little stone gable.
--   THE EDGE OF THE MAP: the invisible boundary wall ran along z -250, right through the cliff's face. The part of it in
--   front of the cliff comes out and walls go round the cliff's sides and back instead (up to y 140), so climbers reach
--   the top but can't go over the edge of the world.
-- Phase 1 (this file for now): the cliff, the ledges, the trellises, the summit and bell (it swings when touched), the start
-- stone and its sign, the boundary. The clock, the board and the rewards come next.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("SandstoneClimb"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "SandstoneClimb"
	local rng = Random.new(opts.seed or 2609)
	local FACE = opts.faceZ or -253                                      -- the cliff's face (z); it looks toward +z (south)
	-- IN FRONT OF IT (probed Sep 27): the low garden wall (stone_wall_b, z -247.7..-246.3, 2.4 high), the cypress row
	-- (trunks every 16 studs at x 442, 458 ... 586, z -242, foliage down to the grass) and the toadstool line (caps z -233.5).
	-- The ledges stop 0.5 behind the wall; the way up starts in the gap between the cypresses at x 490 and 506.
	local BACK = FACE - 18                                               -- how far back its blocks go
	local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {workspace.Terrain}
	local function ground(x, z)
		local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rpT)
		return hit and hit.Position.Y or 5
	end
	local SAND = Enum.Material.Sandstone
	-- the strata, by height: honey at the foot, an ochre band, pale cream, honey again, a thin ochre seam, cream at the top
	local STRATA = {{0, C(222, 190, 140)}, {14, C(206, 158, 102)}, {19, C(236, 214, 172)}, {33, C(224, 194, 146)},
		{44, C(208, 162, 108)}, {48, C(238, 220, 182)}}
	local function strata(y)
		local col = STRATA[1][2]
		for _, s in ipairs(STRATA) do if y >= s[1] then col = s[2] end end
		return col
	end
	local LEDGE, TRIM = C(242, 226, 190), C(250, 238, 210)               -- the ledges a little paler, so the way up reads
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or SAND; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end

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

	-- ---------------------------------------------------------------- the cliff ----
	-- its outline along the face: the summit's floor at the west end, sloping down eastward (x -> the height of the top),
	-- and always at least 7 above any ledge or trellis in front of it, so nothing sticks out over the top
	local PROFILE = {{470, sumY - 16}, {476, sumY - 1.8}, {SX + 13, sumY - 1.8}, {564, tAy - 12}}
	local function topAt(x)
		local h = PROFILE[#PROFILE][2]
		for i = 1, #PROFILE - 1 do
			local a, b = PROFILE[i], PROFILE[i + 1]
			if x >= a[1] and x <= b[1] then local t = (x - a[1]) / (b[1] - a[1]); h = a[2] + (b[2] - a[2]) * t end
		end
		if x < PROFILE[1][1] then h = PROFILE[1][2] end
		if x <= SX + 13 then return h end                                 -- (the summit's own floor)
		for _, r in ipairs(R) do if math.abs(r[1] - x) < r[3] / 2 + 6 then h = math.max(h, r[2] + 7) end end
		if math.abs(TA[1] - x) < 7 then h = math.max(h, TA[3] + 7) end
		return h
	end
	local cliff = Instance.new("Model"); cliff.Name = "Cliff"; cliff.Parent = F
	local X0, X1, CW = 472, 564, 11                                      -- the face's extent and the width of each column of blocks
	for x = X0, X1, CW - 1.5 do
		local gy = math.min(ground(x, FACE + 1), ground(x, FACE - 8)) - 3
		local topY = topAt(x) + rng:NextNumber(-1.5, 1.5)
		local y = gy
		while y < topY - 0.5 do
			local h = math.min(rng:NextNumber(9, 13), topY - y)
			if topY - (y + h) < 4 then h = topY - y end                  -- no sliver on top
			local jz = rng:NextNumber(-1.2, 1.2)
			local depth = FACE - BACK + jz
			local cf = CFrame.new(x + rng:NextNumber(-0.8, 0.8), y + h / 2, FACE + jz - depth / 2)
				* CFrame.Angles(math.rad(rng:NextNumber(-3, 3)), math.rad(rng:NextNumber(-4, 4)), math.rad(rng:NextNumber(-3, 3)))
			part("Rock", Vector3.new(CW + rng:NextNumber(0, 1.5), h + 0.8, depth), cf, strata(y + h / 2), SAND, cliff)
			y = y + h
		end
	end
	-- a few boulders at the foot, where the cliff meets the grass (they soften the line; none under the way up). They sit
	-- behind the garden wall and are small enough, turned any way, never to poke through it (front <= z -248.4).
	for _, bx in ipairs({476, 483, 555, 561}) do
		local s = rng:NextNumber(3.4, 4.4)
		local gy = ground(bx, FACE + 1.5)
		part("Boulder", Vector3.new(s * 1.2, s, s * 0.9), CFrame.new(bx, gy + s * 0.3, FACE + 1.3) * CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-10, 10))), strata(gy), SAND, cliff)
	end

	-- ---------------------------------------------------------------- the way up ----
	local route = Instance.new("Model"); route.Name = "Route"; route.Parent = F
	local LD = 4.8                                                       -- how far a ledge stands out from the face
	local n = 0
	local function ledge(x, topY, w, name)
		n += 1
		local p = part(name or string.format("Ledge%02d", n), Vector3.new(w, 1.3, LD + 3), CFrame.new(x, topY - 0.65, FACE + LD - (LD + 3) / 2), LEDGE, SAND, route)
		p:SetAttribute("Step", n)
		return p
	end
	local function trellis(x, y0, y1)                                    -- an ivy-green trellis: walk into it to climb
		local t = Instance.new("TrussPart"); t.Name = "Trellis"; t.Anchored = true; t.Size = Vector3.new(2, y1 - y0, 2)
		t.CFrame = CFrame.new(x, (y0 + y1) / 2, FACE + 1.0); t.Color = C(74, 116, 62); t.Material = Enum.Material.Wood
		t.Parent = route
		-- a few leaves on it
		for i = 1, math.floor((y1 - y0) / 2.5) do
			local l = part("Leaf", Vector3.new(1.2, 1.2, 1.2), CFrame.new(x + rng:NextNumber(-1.2, 1.2), y0 + i * 2.5 - 1, FACE + 2.1), C(86, 140, 70), Enum.Material.Grass, route, Enum.PartType.Ball)
			l.CanCollide = false; l.CanQuery = false; l.CastShadow = false
		end
		return t
	end
	-- row one east along the face, the first wide ledge and trellis, row two back west, the second wide ledge and trellis
	for _, r in ipairs(R) do ledge(r[1], r[2], r[3], r[4]) end
	trellis(TA[1], TA[2], TA[3])
	trellis(TB[1], TB[2], TB[3])
	F:SetAttribute("Steps", n)

	-- ---------------------------------------------------------------- the summit and its bell ----
	local top = Instance.new("Model"); top.Name = "Summit"; top.Parent = F
	part("Top", Vector3.new(26, 2, 15), CFrame.new(SX, sumY - 1, SZ), TRIM, SAND, top)
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
	-- ring it: a touch anywhere under the gable swings it (the clock and the sound come in the next step)
	local zone = part("BellZone", Vector3.new(7, 7, 5), CFrame.new(gx, sumY + 3.5, gz + 0.5), C(255, 255, 255), nil, top)
	zone.Transparency = 1; zone.CanCollide = false; zone.CanQuery = false
	F:SetAttribute("SummitY", sumY)

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
	-- the invisible wall along z -250 comes out in front of the cliff; walls go round its sides and back instead
	local wallsDone = {}
	for _, b in ipairs(workspace:GetChildren()) do
		local W = b.Name == "Boundary" and b:FindFirstChild("Walls")
		if W then
			for _, w in ipairs(W:GetDescendants()) do
				if w:IsA("BasePart") and w.Name == "Wall" and math.abs(w.Position.Z - (FACE + 2)) < 3 and math.abs(w.Orientation.Y) < 1
					and w.Position.X - w.Size.X / 2 < X0 and w.Position.X + w.Size.X / 2 > X1 then
					local a0, a1 = w.Position.X - w.Size.X / 2, w.Position.X + w.Size.X / 2
					F:SetAttribute("WallWas", string.format("%.3f,%.3f,%.3f,%.3f,%.3f,%.3f", w.Position.X, w.Position.Y, w.Position.Z, w.Size.X, w.Size.Y, w.Size.Z))
					local cut0, cut1 = X0 - 4, X1 + 2
					local west = w:Clone(); west.Size = Vector3.new(cut0 - a0, w.Size.Y, w.Size.Z); west.Position = Vector3.new((a0 + cut0) / 2, w.Position.Y, w.Position.Z); west.Parent = w.Parent
					local east = w:Clone(); east.Size = Vector3.new(a1 - cut1, w.Size.Y, w.Size.Z); east.Position = Vector3.new((cut1 + a1) / 2, w.Position.Y, w.Position.Z); east.Parent = w.Parent
					w:Destroy()
					table.insert(wallsDone, string.format("split the wall at z %.0f: %.0f..%.0f and %.0f..%.0f", east.Position.Z, a0, cut0, cut1, a1))
				end
			end
		end
	end
	local fence = Instance.new("Model"); fence.Name = "Fence"; fence.Parent = F
	local wz0, wz1, WY0, WY1 = -249.4, BACK - 2, -4, 140                 -- (from inside the cut wall's thickness, z -250)
	for _, wx in ipairs({X0 - 4, X1 + 2}) do
		local w = part("Wall", Vector3.new(1, WY1 - WY0, wz0 - wz1), CFrame.new(wx, (WY0 + WY1) / 2, (wz0 + wz1) / 2), C(255, 255, 255), nil, fence)
		w.Transparency = 1; w.CanQuery = false
	end
	local wb = part("Wall", Vector3.new(X1 - X0 + 8, WY1 - WY0, 1), CFrame.new((X0 + X1) / 2 - 1, (WY0 + WY1) / 2, wz1), C(255, 255, 255), nil, fence)
	wb.Transparency = 1; wb.CanQuery = false

	F.Parent = workspace
	print(string.format("SandstoneClimb: %d ledges, summit at y %.1f (%.1f above the start), %s", n, sumY, sumY - sgY, #wallsDone > 0 and wallsDone[1] or "boundary wall already opened"))
	return F
end

-- Chapel: go INTO the chapel on the ridge of Chateau de l'Acorn. Shannon (Sep 25 2026): "just like we make the inside of
-- the bookstore, next, we are going to make the inside of the church".
-- The chapel is one solid mesh (domaine kit "chapel": nave 14 x 22, walls 12 high, bell tower on the front-right corner),
-- so - as with the Librairie (village/build_bookshop.lua) - the inside is a room built 300 studs straight up over it,
-- turned the same way, still inside the estate's rectangle so the section and the saved area carry on. A prompt on the
-- chapel's front door fades the screen to black and the server moves the character in; the door inside does the same
-- back out. Inside the map music goes quiet (MusicClient checks InChapel) and the chapel plays its own music, softly -
-- Shannon's three picks, one after another.
-- THE ROOM (a little bigger than the outside, as the Librairie is: 16 x 28, walls 13 high, a pitched plank ceiling on
-- beams): stone flags, a red carpet up the aisle, six pews each side that you can sit in, plastered walls over a stone
-- dado, three stained-glass windows down each side (lavender, sunflower, sky, rose - the estate's own colours), the
-- rose window over the door, iron chandeliers, and up two steps the altar - cloth, candles, a vase of lavender and
-- sunflowers - under a tall window whose glass shows an acorn. A lectern with an open book.
-- TWO THINGS TO DO: light a candle on the votive stand (each stays lit a while, for everyone), and pull the bell rope
-- in the tower corner - the bell rings out of the belfry for everyone near the chapel, and in here.
-- Attributes on workspace.Chapel: RoomX/Y/Z, InX/Y/Z, OutX/Y/Z, FadeSeconds, DoorSound, ChapelMusic, MusicVolume,
-- BellSound, BellVolume, CandleSeconds, InsideZoom.
-- Run in edit mode (re-runnable: it rebuilds workspace.Chapel; nothing outside it is touched).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local rng = Random.new(opts.seed or 1717)
	local old = workspace:FindFirstChild("Chapel"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "Chapel"
	local report = {}

	-- ---------------------------------------------------------------- where the chapel is ----
	local chapel
	for _, m in ipairs(workspace.Domaine.Props:GetChildren()) do if m.Name == "chapel" then chapel = m end end
	assert(chapel, "no chapel in workspace.Domaine.Props")
	local walls, door, bell = chapel:FindFirstChild("Walls", true), chapel:FindFirstChild("Door", true), chapel:FindFirstChild("Bell", true)
	assert(walls and door, "the chapel has no Walls/Door piece")
	local floorY = walls.Position.Y - walls.Size.Y / 2                       -- the nave's floor (the tower makes Walls 26 high)
	local centre = Vector3.new(walls.Position.X, floorY, walls.Position.Z)
	local front = Vector3.new(door.Position.X - centre.X, 0, door.Position.Z - centre.Z).Unit   -- out through the door
	local doorAt = Vector3.new(door.Position.X, floorY, door.Position.Z)
	local LIFT = opts.lift or 300
	local R = CFrame.lookAt(centre + Vector3.new(0, LIFT, 0), centre + Vector3.new(0, LIFT, 0) + front)   -- the room: -Z (LookVector) = the door end
	local function at(x, y, z) return R * CFrame.new(x, y, z) end          -- room coordinates: +z runs from the door (z -14, R's look) to the altar (z +14)
	local W, D, H, RIDGE = 16, 28, 13, 19
	local HX, HZ = W / 2, D / 2

	-- ---------------------------------------------------------------- palette ----
	local FLAG, PLASTER, DADO = C(172, 162, 146), C(222, 208, 182), C(178, 162, 136)
	local PLANK, BEAM, PEW = C(122, 86, 56), C(88, 60, 38), C(138, 94, 58)
	local CARPET, GOLD, CLOTH, WAX, FLAME = C(150, 40, 44), C(214, 172, 80), C(248, 246, 240), C(246, 238, 214), C(255, 196, 96)
	local IRON, DOORW, STONE = C(46, 44, 48), C(96, 62, 36), C(222, 212, 190)
	-- deep colours: Neon glows, and pale glass comes out nearly white
	-- and in the game Neon blooms, so they sit a quarter darker than they look in a palette
	local GLASS = {C(90, 52, 150), C(190, 132, 18), C(28, 90, 168), C(158, 34, 66), C(40, 114, 58), C(182, 82, 22)}   -- lavender, sunflower, sky, rose, olive, amber
	local LEAD = C(40, 36, 44)

	local room = Instance.new("Model"); room.Name = "Room"
	pcall(function() room.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end)   -- always there, so nobody arrives in the void
	room.Parent = F
	local function part(name, size, cf, colour, material, shape, parent)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or room
		return p
	end
	local function deco(...) local p = part(...); p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; return p end
	local function light(parent, colour, brightness, range)
		local l = Instance.new("PointLight"); l.Color = colour; l.Brightness = brightness; l.Range = range; l.Shadows = false; l.Parent = parent
		return l
	end
	local CYL = Enum.PartType.Cylinder
	local UP = CFrame.Angles(0, 0, math.rad(90))                         -- stands a cylinder up (its axis is x)

	-- ---------------------------------------------------------------- the shell ----
	part("Floor", Vector3.new(W + 2, 1, D + 2), at(0, -0.5, 0), FLAG, Enum.Material.Slate)
	for _, s in ipairs({-1, 1}) do                                           -- side walls, plaster over a stone dado
		part("Wall", Vector3.new(1, H, D + 2), at(s * (HX + 0.5), H / 2, 0), PLASTER)
		deco("Dado", Vector3.new(0.2, 3, D), at(s * (HX - 0.1), 1.5, 0), DADO, Enum.Material.Limestone)
		deco("DadoCap", Vector3.new(0.35, 0.25, D), at(s * (HX - 0.15), 3.05, 0), STONE, Enum.Material.Limestone)
	end
	for _, e in ipairs({-1, 1}) do                                           -- end walls, up into the gable
		part("EndWall", Vector3.new(W + 2, H, 1), at(0, H / 2, e * (HZ + 0.5)), PLASTER)
		deco("Dado", Vector3.new(W, 3, 0.2), at(0, 1.5, e * (HZ - 0.1)), DADO, Enum.Material.Limestone)
		deco("DadoCap", Vector3.new(W, 0.25, 0.35), at(0, 3.05, e * (HZ - 0.15)), STONE, Enum.Material.Limestone)
		-- the gable: stacked courses narrowing to the ridge
		local steps = 12
		for k = 1, steps do
			local y0 = H + (RIDGE - H) * (k - 1) / steps
			local w = (W + 2) * (1 - (k - 0.5) / steps)
			part("Gable", Vector3.new(w, (RIDGE - H) / steps + 0.02, 1), at(0, y0 + (RIDGE - H) / steps / 2, e * (HZ + 0.5)), PLASTER)
		end
	end
	-- the pitched ceiling: a plank slope each side, meeting at the ridge; beams across under it
	local slope = math.atan2(RIDGE - H, HX + 1)
	local slopeLen = math.sqrt((RIDGE - H) ^ 2 + (HX + 1) ^ 2)
	for _, s in ipairs({-1, 1}) do
		part("Ceiling", Vector3.new(slopeLen + 0.6, 0.5, D + 2), at(s * (HX + 1) / 2, (H + RIDGE) / 2 + 0.25, 0) * CFrame.Angles(0, 0, s * -slope), PLANK, Enum.Material.WoodPlanks)
	end
	deco("Ridge", Vector3.new(0.7, 0.7, D + 2), at(0, RIDGE - 0.1, 0), BEAM, Enum.Material.Wood)
	for z = -HZ + 3, HZ - 3, 5 do
		deco("TieBeam", Vector3.new(W + 0.4, 0.7, 0.8), at(0, H - 0.35, z), BEAM, Enum.Material.Wood)
		for _, s in ipairs({-1, 1}) do
			deco("Rafter", Vector3.new(slopeLen, 0.55, 0.6), at(s * (HX + 1) / 2 - s * 0.2, (H + RIDGE) / 2 - 0.35, z) * CFrame.Angles(0, 0, s * -slope), BEAM, Enum.Material.Wood)
		end
		deco("KingPost", Vector3.new(0.5, RIDGE - H - 0.6, 0.5), at(0, (H + RIDGE) / 2, z), BEAM, Enum.Material.Wood)
	end

	-- ---------------------------------------------------------------- the aisle and the pews ----
	deco("Carpet", Vector3.new(2.6, 0.06, D - 9.5), at(0, 0.03, -HZ + (D - 9.5) / 2 + 0.6), CARPET, Enum.Material.Fabric)
	for _, s in ipairs({-1, 1}) do deco("CarpetEdge", Vector3.new(0.18, 0.07, D - 9.5), at(s * 1.35, 0.035, -HZ + (D - 9.5) / 2 + 0.6), GOLD, Enum.Material.Fabric) end
	local seats = 0
	for row = 0, 5 do
		local z = -HZ + 5.2 + row * 2.9
		for _, s in ipairs({-1, 1}) do
			local x = s * (1.9 + 5.4 / 2)                                    -- from the aisle's edge to the wall, a little short of it
			local pew = Instance.new("Model"); pew.Name = "Pew"; pew.Parent = room
			part("Bench", Vector3.new(5.4, 0.3, 1.3), at(x, 1.75, z), PEW, Enum.Material.Wood, nil, pew)
			-- you sit facing the altar (+z): the back is on the door side, the kneeler out in front
			part("Back", Vector3.new(5.4, 1.5, 0.22), at(x, 2.75, z - 0.62), PEW, Enum.Material.Wood, nil, pew)
			deco("BackRail", Vector3.new(5.5, 0.2, 0.34), at(x, 3.55, z - 0.62), BEAM, Enum.Material.Wood, nil, pew)
			for _, e in ipairs({-1, 1}) do
				part("End", Vector3.new(0.25, 3.1, 1.5), at(x + e * 2.75, 1.55, z - 0.1), BEAM, Enum.Material.Wood, nil, pew)
			end
			part("Kneeler", Vector3.new(5.0, 0.3, 0.45), at(x, 0.5, z + 1.0), BEAM, Enum.Material.Wood, nil, pew).CanCollide = false
			for _, k in ipairs({-1.3, 1.3}) do                              -- two places to sit on every pew, facing the altar
				local seat = Instance.new("Seat"); seat.Name = "PewSeat"; seat.Size = Vector3.new(1.8, 0.2, 1.2)
				seat.CFrame = at(x + k, 1.95, z) * CFrame.Angles(0, math.pi, 0); seat.Transparency = 1; seat.Anchored = true; seat.CanCollide = false
				seat.Parent = pew
				seats += 1
			end
		end
	end
	table.insert(report, seats .. " seats in the pews")

	-- ---------------------------------------------------------------- stained glass ----
	-- a pane group on a wall's inner face: `face` is the CFrame of the window's centre looking into the room
	local function arched(name, face, w, h, colours, parent)
		local m = Instance.new("Model"); m.Name = name; m.Parent = parent or room
		local rect = h - w / 2                                               -- the straight part; the top is a half disc
		local cols, rows = 2, 3
		for i = 0, cols - 1 do
			for j = 0, rows - 1 do
				local pw, ph = w / cols, rect / rows
				local c = colours[(i + j * cols) % #colours + 1]
				deco("Pane", Vector3.new(pw - 0.12, ph - 0.12, 0.08), face * CFrame.new(-w / 2 + pw * (i + 0.5), -h / 2 + ph * (j + 0.5), 0), c, Enum.Material.Neon, nil, m)
			end
		end
		-- the round top: a disc set just behind the panes, so its lower half hides behind the top row
		deco("Arch", Vector3.new(0.08, w - 0.12, w - 0.12), face * CFrame.new(0, -h / 2 + rect, 0.05) * CFrame.Angles(0, math.rad(90), 0), colours[#colours], Enum.Material.Neon, CYL, m)
		deco("ArchLead", Vector3.new(0.06, w + 0.2, w + 0.2), face * CFrame.new(0, -h / 2 + rect, 0.09) * CFrame.Angles(0, math.rad(90), 0), LEAD, nil, CYL, m)
		-- the lead: a frame round it and bars between the panes (the half disc's lower half hides behind the top row)
		deco("Lead", Vector3.new(w + 0.3, 0.16, 0.1), face * CFrame.new(0, -h / 2, -0.02), LEAD, nil, nil, m)
		for _, s in ipairs({-1, 1}) do deco("Lead", Vector3.new(0.16, rect, 0.1), face * CFrame.new(s * w / 2, -h / 2 + rect / 2, -0.02), LEAD, nil, nil, m) end
		for j = 1, rows - 1 do deco("Lead", Vector3.new(w, 0.1, 0.1), face * CFrame.new(0, -h / 2 + rect * j / rows, -0.02), LEAD, nil, nil, m) end
		deco("Lead", Vector3.new(0.1, rect, 0.1), face * CFrame.new(0, -h / 2 + rect / 2, -0.02), LEAD, nil, nil, m)
		-- the stone round it: a sill and two jambs
		deco("Sill", Vector3.new(w + 0.9, 0.3, 0.5), face * CFrame.new(0, -h / 2 - 0.15, 0.1), STONE, Enum.Material.Limestone, nil, m)
		for _, s in ipairs({-1, 1}) do deco("Jamb", Vector3.new(0.35, rect, 0.3), face * CFrame.new(s * (w / 2 + 0.25), -h / 2 + rect / 2, 0.05), STONE, Enum.Material.Limestone, nil, m) end
		local glow = deco("Glow", Vector3.new(0.2, 0.2, 0.2), face * CFrame.new(0, 0, -1.2), colours[1], nil, nil, m); glow.Transparency = 1
		light(glow, colours[(#colours + 1) // 2], 0.35, 9)
		return m
	end
	local SIDE_Z = {-8.5, 0, 8.5}
	for _, s in ipairs({-1, 1}) do
		for k, z in ipairs(SIDE_Z) do
			local face = at(s * (HX - 0.05), 6.6, z) * CFrame.Angles(0, s * math.rad(90), 0)   -- looking into the room
			local cs = {}
			for n = 1, 4 do cs[n] = GLASS[(k * 2 + n + (s > 0 and 3 or 0)) % #GLASS + 1] end
			arched("Window", face, 3.0, 5.8, cs)
		end
	end
	-- the rose window over the door
	do
		local c0 = at(0, 10.2, -HZ + 0.05)                                   -- the door wall's inner face, looking into the room (+z)
		local rose = Instance.new("Model"); rose.Name = "RoseWindow"; rose.Parent = room
		local N = 12
		for i = 0, N - 1 do
			local a = i * 2 * math.pi / N
			local petal = deco("Petal", Vector3.new(0.85, 1.25, 0.08), c0 * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.15, 0), GLASS[i % #GLASS + 1], Enum.Material.Neon, nil, rose)
			petal.Transparency = 0.15
			deco("Lead", Vector3.new(0.1, 1.7, 0.1), c0 * CFrame.Angles(0, 0, a + math.pi / N) * CFrame.new(0, 1.05, 0.03), LEAD, nil, nil, rose)
		end
		deco("Centre", Vector3.new(0.1, 1.0, 1.0), c0 * CFrame.new(0, 0, 0.04) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Neon, CYL, rose)
		for i = 0, 23 do                                                     -- the stone ring round it
			local a = i * 2 * math.pi / 24
			deco("Ring", Vector3.new(0.62, 0.3, 0.3), c0 * CFrame.Angles(0, 0, a) * CFrame.new(0, 2.05, 0.1), STONE, Enum.Material.Limestone, nil, rose)
		end
		light(deco("Glow", Vector3.new(0.2, 0.2, 0.2), c0 * CFrame.new(0, 0, 1.2), GOLD, nil, nil, rose), C(255, 214, 170), 0.35, 9).Parent.Transparency = 1
	end

	-- ---------------------------------------------------------------- the chancel and the altar ----
	local CH = HZ - 7                                                        -- the chancel starts here and runs to the back wall
	part("Step", Vector3.new(W, 0.5, 7), at(0, 0.25, CH + 3.5), STONE, Enum.Material.Limestone)
	part("Step", Vector3.new(W, 0.5, 5.6), at(0, 0.75, CH + 4.2), STONE, Enum.Material.Limestone)
	local altarZ = HZ - 2.6
	local altar = Instance.new("Model"); altar.Name = "Altar"; altar.Parent = room
	part("AltarStone", Vector3.new(5.2, 3.0, 2.0), at(0, 1.0 + 1.5, altarZ), STONE, Enum.Material.Limestone, nil, altar)
	deco("AltarTop", Vector3.new(5.6, 0.25, 2.3), at(0, 4.1, altarZ), STONE, Enum.Material.Limestone, nil, altar)
	deco("Cloth", Vector3.new(5.7, 0.06, 2.4), at(0, 4.25, altarZ), CLOTH, Enum.Material.Fabric, nil, altar)
	deco("ClothFront", Vector3.new(5.7, 1.4, 0.06), at(0, 3.55, altarZ - 1.2), CLOTH, Enum.Material.Fabric, nil, altar)
	deco("Runner", Vector3.new(1.2, 1.45, 0.07), at(0, 3.53, altarZ - 1.22), GOLD, Enum.Material.Fabric, nil, altar)
	local function candle(parent, cf, height, lit)
		local body = deco("Candle", Vector3.new(height, 0.28, 0.28), cf * CFrame.new(0, height / 2, 0) * UP, WAX, nil, CYL, parent)
		local flame = deco("Flame", Vector3.new(0.18, 0.34, 0.18), cf * CFrame.new(0, height + 0.2, 0), FLAME, Enum.Material.Neon, nil, parent)
		local sm = Instance.new("SpecialMesh"); sm.MeshType = Enum.MeshType.Sphere; sm.Parent = flame
		local l = light(flame, C(255, 190, 120), 0.5, 8)
		flame.Transparency = lit and 0 or 1; l.Enabled = lit
		return body, flame, l
	end
	for _, s in ipairs({-1, 1}) do                                         -- tall candlesticks either end of the altar
		deco("Stick", Vector3.new(1.3, 0.2, 0.2), at(s * 2.1, 4.25 + 0.65, altarZ) * UP, GOLD, Enum.Material.Metal, CYL, altar)
		deco("Drip", Vector3.new(0.12, 0.5, 0.5), at(s * 2.1, 4.33, altarZ) * UP, GOLD, Enum.Material.Metal, CYL, altar)
		candle(altar, at(s * 2.1, 5.55, altarZ), 0.9, true)
	end
	-- the vase: lavender and sunflowers
	deco("Vase", Vector3.new(0.9, 0.7, 0.7), at(0, 4.28 + 0.45, altarZ) * UP, C(96, 128, 180), Enum.Material.SmoothPlastic, CYL, altar)
	for i = 1, 9 do
		local a = i * 2.4
		local tilt = CFrame.Angles(math.rad(rng:NextNumber(-14, 14)), 0, math.rad(rng:NextNumber(-18, 18)))
		local base = at(math.cos(a) * 0.15, 5.0, altarZ + math.sin(a) * 0.15) * tilt
		deco("Stem", Vector3.new(0.08, 1.4, 0.08), base * CFrame.new(0, 0.7, 0), C(80, 120, 60), nil, nil, altar)
		if i % 3 == 0 then
			deco("Sunflower", Vector3.new(0.1, 0.62, 0.62), base * CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(70), 0, 0), C(250, 200, 50), nil, CYL, altar)
			deco("Heart", Vector3.new(0.12, 0.26, 0.26), base * CFrame.new(0, 1.45, -0.05) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(70), 0, 0), C(100, 62, 30), nil, CYL, altar)
		else
			deco("Lavender", Vector3.new(0.16, 0.55, 0.16), base * CFrame.new(0, 1.55, 0), GLASS[1], nil, nil, altar)
		end
	end
	-- behind the altar: the tall acorn window
	do
		local face = at(0, 8.2, HZ - 0.05)                                   -- the back wall's inner face; its look (-z) is into the room
		local win = arched("AcornWindow", face, 4.4, 8.0, {GLASS[3], GLASS[1], GLASS[5], GLASS[3], GLASS[1], GLASS[2]})
		-- the acorn in the glass, just in front of the panes: a gold nut under a brown cap with a stalk
		local nut = deco("Nut", Vector3.new(1.7, 2.1, 0.12), face * CFrame.new(0, -0.6, -0.06), C(214, 150, 60), Enum.Material.Neon, nil, win)
		local nm = Instance.new("SpecialMesh"); nm.MeshType = Enum.MeshType.Sphere; nm.Parent = nut
		local cap = deco("Cap", Vector3.new(2.1, 1.0, 0.13), face * CFrame.new(0, 0.45, -0.07), C(120, 74, 36), Enum.Material.Neon, nil, win)
		local cm = Instance.new("SpecialMesh"); cm.MeshType = Enum.MeshType.Sphere; cm.Parent = cap
		deco("Stalk", Vector3.new(0.22, 0.6, 0.12), face * CFrame.new(0.1, 1.1, -0.07) * CFrame.Angles(0, 0, math.rad(-15)), C(100, 62, 30), Enum.Material.Neon, nil, win)
		deco("Cross", Vector3.new(0.18, 1.8, 0.18), at(0, 10.9, HZ - 0.3), GOLD, Enum.Material.Metal, nil, win)
		deco("Cross", Vector3.new(1.1, 0.18, 0.18), at(0, 11.35, HZ - 0.3), GOLD, Enum.Material.Metal, nil, win)
	end
	-- the lectern, with its book open
	do
		local lz, lx = CH + 2.2, -4.6                                       -- on the upper step (its floor is 1.0 up)
		local lec = Instance.new("Model"); lec.Name = "Lectern"; lec.Parent = room
		part("Post", Vector3.new(0.35, 3.4, 0.35), at(lx, 1.0 + 1.7, lz), BEAM, Enum.Material.Wood, nil, lec)
		part("Foot", Vector3.new(1.4, 0.3, 1.4), at(lx, 1.15, lz), BEAM, Enum.Material.Wood, nil, lec)
		local desk = at(lx, 4.5, lz) * CFrame.Angles(math.rad(-28), 0, 0)
		deco("Desk", Vector3.new(1.8, 0.14, 1.3), desk, PEW, Enum.Material.Wood, nil, lec)
		for _, s in ipairs({-1, 1}) do deco("Page", Vector3.new(0.78, 0.05, 1.05), desk * CFrame.new(s * 0.42, 0.1, 0) * CFrame.Angles(0, 0, s * math.rad(-6)), CLOTH, nil, nil, lec) end
		deco("Ribbon", Vector3.new(0.08, 0.02, 1.3), desk * CFrame.new(0, 0.13, 0.15), C(170, 30, 40), nil, nil, lec)
	end

	-- ---------------------------------------------------------------- chandeliers ----
	for _, z in ipairs({-6, 4}) do                                          -- hung from two of the tie beams
		local ch = Instance.new("Model"); ch.Name = "Chandelier"; ch.Parent = room
		local y = H - 3.2
		deco("Chain", Vector3.new(0.1, H - 0.7 - y, 0.1), at(0, (H - 0.7 + y) / 2, z), IRON, Enum.Material.Metal, nil, ch)
		for i = 0, 15 do                                                     -- an open iron ring, not a plate
			local a = i * 2 * math.pi / 16
			deco("Hoop", Vector3.new(0.58, 0.16, 0.16), at(math.cos(a) * 1.45, y, z + math.sin(a) * 1.45) * CFrame.Angles(0, -a + math.pi / 2, 0), IRON, Enum.Material.Metal, nil, ch)
		end
		for i = 0, 2 do                                                      -- three arms from the hub to the ring
			local a = i * 2 * math.pi / 3
			deco("Arm", Vector3.new(0.12, 0.12, 1.45), at(math.cos(a) * 0.72, y, z + math.sin(a) * 0.72) * CFrame.Angles(0, -a + math.pi / 2, 0), IRON, Enum.Material.Metal, nil, ch)
		end
		deco("Hub", Vector3.new(0.5, 0.6, 0.6), at(0, y - 0.3, z) * UP, IRON, Enum.Material.Metal, CYL, ch)
		for i = 0, 5 do
			local a = i * math.pi / 3
			candle(ch, at(math.cos(a) * 1.35, y + 0.1, z + math.sin(a) * 1.35), 0.55, true)
		end
		local lamp = deco("Lamp", Vector3.new(0.2, 0.2, 0.2), at(0, y - 0.6, z), FLAME, nil, nil, ch); lamp.Transparency = 1
		light(lamp, C(255, 204, 150), 0.9, 20)
	end

	-- ---------------------------------------------------------------- the votive stand ----
	local votive = Instance.new("Model"); votive.Name = "Votive"; votive.Parent = room
	local vx, vz = -HX + 1.8, -HZ + 3.2                                      -- front left, between the door and the first pews
	part("Stand", Vector3.new(0.3, 2.6, 0.3), at(vx, 1.3, vz), IRON, Enum.Material.Metal, nil, votive)
	local slots = {}
	for tier = 0, 2 do
		local ty = 2.7 + tier * 0.55
		local tw = 2.4 - tier * 0.6
		deco("Tier", Vector3.new(tw, 0.12, 0.9 - tier * 0.15), at(vx, ty, vz), IRON, Enum.Material.Metal, nil, votive)
		local n = 4 - tier
		for i = 1, n do
			local x = vx - tw / 2 + tw * (i - 0.5) / n
			local cup = deco("Cup", Vector3.new(0.3, 0.34, 0.34), at(x, ty + 0.2, vz) * UP, C(170, 40, 40), Enum.Material.Glass, CYL, votive); cup.Transparency = 0.35
			local _, flame, l = candle(votive, at(x, ty + 0.06, vz), 0.2, false)
			l.Brightness = 0.35; l.Range = 6
			table.insert(slots, flame)
		end
	end
	for i, fl in ipairs(slots) do fl.Name = "VotiveFlame" .. i end
	local vpad = part("VotivePad", Vector3.new(2.6, 3, 1.2), at(vx, 3, vz), CLOTH, nil, nil, votive)
	vpad.Transparency = 1; vpad.CanCollide = false; vpad.CanQuery = false
	local lp = Instance.new("ProximityPrompt"); lp.Name = "CandlePrompt"; lp.ActionText = "Light a candle"; lp.ObjectText = "Votive candles"
	lp.KeyboardKeyCode = Enum.KeyCode.E; lp.HoldDuration = 0.4; lp.MaxActivationDistance = 7; lp.RequiresLineOfSight = false; lp.Parent = vpad
	table.insert(report, #slots .. " votive candles")

	-- ---------------------------------------------------------------- the bell rope (the tower is the front-right corner) ----
	local rope = Instance.new("Model"); rope.Name = "BellRope"; rope.Parent = room
	local rx, rz = HX - 1.6, -HZ + 1.6
	deco("Rope", Vector3.new(0.14, H - 2.4, 0.14), at(rx, (H + 2.4) / 2, rz), C(196, 170, 120), Enum.Material.Fabric, nil, rope)
	local sally = deco("Sally", Vector3.new(0.5, 1.4, 0.5), at(rx, 3.6, rz), C(170, 40, 50), Enum.Material.Fabric, nil, rope)
	for _, dy in ipairs({-0.45, 0, 0.45}) do deco("Stripe", Vector3.new(0.53, 0.12, 0.53), at(rx, 3.6 + dy, rz), CLOTH, Enum.Material.Fabric, nil, rope) end
	deco("Tail", Vector3.new(0.14, 1.3, 0.14), at(rx, 2.25, rz), C(196, 170, 120), Enum.Material.Fabric, nil, rope)
	deco("Hole", Vector3.new(0.9, 0.12, 0.9), at(rx, H - 0.05, rz), IRON, Enum.Material.Metal, nil, rope)
	rope.PrimaryPart = sally
	local rpad = part("RopePad", Vector3.new(1.4, 4, 1.4), at(rx, 3, rz), CLOTH, nil, nil, rope)
	rpad.Transparency = 1; rpad.CanCollide = false; rpad.CanQuery = false
	local bp = Instance.new("ProximityPrompt"); bp.Name = "BellPrompt"; bp.ActionText = "Ring the bell"; bp.ObjectText = "Bell rope"
	bp.KeyboardKeyCode = Enum.KeyCode.E; bp.HoldDuration = 0.25; bp.MaxActivationDistance = 7; bp.RequiresLineOfSight = false; bp.Parent = rpad

	-- ---------------------------------------------------------------- the doors ----
	-- inside: the front wall's door, oak with iron straps under a stone arch, and the way out
	local inner = at(0, 0, -HZ + 0.02)
	part("InnerDoor", Vector3.new(4.2, 6.0, 0.25), inner * CFrame.new(0, 3.0, 0), DOORW, Enum.Material.Wood)
	deco("DoorTop", Vector3.new(0.25, 4.2, 4.2), inner * CFrame.new(0, 6.0, 0) * CFrame.Angles(0, math.rad(90), 0), DOORW, Enum.Material.Wood, CYL)
	deco("DoorSeam", Vector3.new(0.08, 7.9, 0.3), inner * CFrame.new(0, 3.9, 0.02), C(60, 40, 24), Enum.Material.Wood)
	for _, y in ipairs({1.3, 3.2, 5.1}) do deco("Strap", Vector3.new(4.0, 0.22, 0.32), inner * CFrame.new(0, y, 0.04), IRON, Enum.Material.Metal) end
	for _, s in ipairs({-1, 1}) do deco("Ring", Vector3.new(0.08, 0.45, 0.45), inner * CFrame.new(s * 0.5, 3.2, 0.2) * CFrame.Angles(0, math.rad(90), 0), IRON, Enum.Material.Metal, CYL) end
	for i = 0, 12 do                                                         -- the stone arch round it
		local a = math.pi * i / 12
		deco("Voussoir", Vector3.new(0.7, 0.45, 0.4), inner * CFrame.new(math.cos(a) * 2.45, 6.0 + math.sin(a) * 2.45, 0.1) * CFrame.Angles(0, 0, a + math.pi / 2), STONE, Enum.Material.Limestone)
	end
	for _, s in ipairs({-1, 1}) do deco("Jamb", Vector3.new(0.45, 6.0, 0.4), inner * CFrame.new(s * 2.45, 3.0, 0.1), STONE, Enum.Material.Limestone) end
	local exitPad = part("ExitPad", Vector3.new(4, 5.5, 0.6), inner * CFrame.new(0, 2.9, 0.6), CLOTH)
	exitPad.Transparency = 1; exitPad.CanCollide = false; exitPad.CanQuery = false
	local exit = Instance.new("ProximityPrompt"); exit.Name = "ExitPrompt"; exit.ActionText = "Go outside"; exit.ObjectText = "Chateau de l'Acorn"
	exit.KeyboardKeyCode = Enum.KeyCode.E; exit.HoldDuration = 0; exit.MaxActivationDistance = 8; exit.RequiresLineOfSight = false; exit.Parent = exitPad
	-- outside: a prompt on the chapel's own door
	local outFrame = CFrame.lookAt(doorAt, doorAt + front)
	local doorPad = part("DoorPad", Vector3.new(4, 5.5, 0.6), outFrame * CFrame.new(0, 2.9, -0.5), CLOTH, nil, nil, F)
	doorPad.Transparency = 1; doorPad.CanCollide = false; doorPad.CanQuery = false
	local enter = Instance.new("ProximityPrompt"); enter.Name = "EnterPrompt"; enter.ActionText = "Go inside"; enter.ObjectText = "Chapelle"
	enter.KeyboardKeyCode = Enum.KeyCode.E; enter.HoldDuration = 0; enter.MaxActivationDistance = 8; enter.RequiresLineOfSight = false; enter.Parent = doorPad
	-- the bell's voice outside, in the belfry
	local belfry = part("BellVoice", Vector3.new(0.5, 0.5, 0.5), CFrame.new(bell and bell.Position or (doorAt + Vector3.new(0, 22, 0))), CLOTH, nil, nil, F)
	belfry.Transparency = 1; belfry.CanCollide = false; belfry.CanQuery = false; belfry.CanTouch = false

	-- ---------------------------------------------------------------- where you arrive ----
	local rpG = RaycastParams.new(); rpG.FilterType = Enum.RaycastFilterType.Exclude; rpG.FilterDescendantsInstances = {F, chapel}
	local outSpot = doorAt + front * 4.0
	local g = workspace:Raycast(outSpot + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), rpG)
	local outY = (g and g.Position.Y or floorY) + 3.2
	local inSpot = at(0, 3.2, -HZ + 5.2).Position                          -- inside the door, room behind you for the camera
	F:SetAttribute("RoomX", R.Position.X); F:SetAttribute("RoomY", R.Position.Y); F:SetAttribute("RoomZ", R.Position.Z)
	F:SetAttribute("InX", inSpot.X); F:SetAttribute("InY", inSpot.Y); F:SetAttribute("InZ", inSpot.Z)
	F:SetAttribute("InLookX", -front.X); F:SetAttribute("InLookZ", -front.Z)          -- inside, you face the altar
	F:SetAttribute("OutX", outSpot.X); F:SetAttribute("OutY", outY); F:SetAttribute("OutZ", outSpot.Z)
	F:SetAttribute("OutLookX", front.X); F:SetAttribute("OutLookZ", front.Z)          -- outside, you face away from the door
	F:SetAttribute("FadeSeconds", opts.fade or 0.45)
	-- no door sound: "Wood Door Creak 1" (9120838480) ran 12.3 s in SoundService, so it kept groaning after you left -
	-- Shannon heard it as a fart, going in and some way off after coming out. A new id here should be a short one.
	F:SetAttribute("DoorSound", opts.doorSound or ""); F:SetAttribute("DoorVolume", opts.doorVolume or 0.5)
	-- Shannon's picks (Sep 25): three tracks, played one after another round and round - any list of ids works here
	-- (Sep 26: 115237835648277 added as the first track)
	F:SetAttribute("ChapelMusic", opts.music or "rbxassetid://115237835648277, rbxassetid://139084379039051, rbxassetid://124603142001530, rbxassetid://116835734998008")
	F:SetAttribute("MusicVolume", opts.musicVolume or 0.12)
	F:SetAttribute("BellSound", opts.bellSound or "rbxassetid://9113804436"); F:SetAttribute("BellVolume", opts.bellVolume or 0.8)      -- Church Bell Tolling 1
	F:SetAttribute("CandleSeconds", opts.candleSeconds or 120); F:SetAttribute("InsideZoom", opts.insideZoom or 18)

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local F = script.Parent
local ev = F:WaitForChild("ChapelEvent")
local room = F:WaitForChild("Room")
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out through the walls: a short zoom leash, given back at the door (or on respawn)
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = F:GetAttribute("InsideZoom") or 18
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player) player.CharacterAdded:Connect(function() leash(player, false) end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)

-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if hum and hum.SeatPart then hum.Sit = false end
			local p = toInside and v3("In") or v3("Out")
			local look = toInside and Vector3.new(F:GetAttribute("InLookX"), 0, F:GetAttribute("InLookZ")) or Vector3.new(F:GetAttribute("OutLookX"), 0, F:GetAttribute("OutLookZ"))
			char:PivotTo(CFrame.lookAt(p, p + look))
			char:SetAttribute("InChapel", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end

-- the votive candles: each prompt lights the next dark one, for everyone, for CandleSeconds
local votive = room:WaitForChild("Votive")
local flames = {}
for _, d in ipairs(votive:GetChildren()) do if d.Name:match("^VotiveFlame") then flames[#flames + 1] = d end end
table.sort(flames, function(a, b) return tonumber(a.Name:match("%d+")) < tonumber(b.Name:match("%d+")) end)
local litUntil = {}
local function setLit(fl, on)
	fl.Transparency = on and 0 or 1
	local l = fl:FindFirstChildOfClass("PointLight"); if l then l.Enabled = on end
end
local function lightOne(player)
	local now = os.clock()
	local pick
	for _, fl in ipairs(flames) do if (litUntil[fl] or 0) < now then pick = fl break end end
	if not pick then                                                   -- all lit: the one that has burned longest is renewed
		for _, fl in ipairs(flames) do if not pick or litUntil[fl] < litUntil[pick] then pick = fl end end
	end
	local secs = F:GetAttribute("CandleSeconds") or 120
	litUntil[pick] = now + secs
	setLit(pick, true)
	ev:FireClient(player, "candle")
	task.delay(secs + 0.1, function() if (litUntil[pick] or 0) <= os.clock() then setLit(pick, false) end end)
end

-- the bell: out of the belfry for everyone near the chapel, and in here; the rope gives
local bellAt = 0
local rope = room:WaitForChild("BellRope")
local function ring(player)
	if os.clock() - bellAt < 4 then return end
	bellAt = os.clock()
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"church",{}) end
	local id, vol = F:GetAttribute("BellSound") or "rbxassetid://9113804436", F:GetAttribute("BellVolume") or 0.8
	for _, where in ipairs({F:FindFirstChild("BellVoice"), rope:FindFirstChild("Hole")}) do
		if where then
			local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = where.Name == "BellVoice" and 260 or 80
			s.RollOffMinDistance = 12; s.Parent = where; s:Play()
			game:GetService("Debris"):AddItem(s, 12)
		end
	end
	-- the rope and its sally go down a stud and a half and come back
	local parts = {}
	for _, p in ipairs(rope:GetChildren()) do if p:IsA("BasePart") and p.Name ~= "Hole" and p.Name ~= "RopePad" then parts[#parts + 1] = p end end
	for _, p in ipairs(parts) do
		local home = p:GetAttribute("Home") or p.CFrame
		p:SetAttribute("Home", home)
		local tw = TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {CFrame = home * CFrame.new(0, -1.5, 0)})
		tw:Play()
	end
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "CandlePrompt" then lightOne(player)
	elseif prompt.Name == "BellPrompt" then ring(player)
	end
end)
print("ChapelServer: ready")
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = F:WaitForChild("ChapelEvent")
local C = Color3.fromRGB

-- the chapel's sounds: the door as you go through it, and its music, softly, while you are inside (the map music goes
-- quiet in here: MusicClient checks InChapel). ChapelMusic can hold several ids: they play one after another, and
-- round again; coming back in carries on with the next one.
local doorSfx = Instance.new("Sound"); doorSfx.Name = "ChapelDoor"; doorSfx.SoundId = F:GetAttribute("DoorSound") or ""; doorSfx.Volume = F:GetAttribute("DoorVolume") or 0.5; doorSfx.Parent = SoundService
local function tracks()
	local list = {}
	for d in tostring(F:GetAttribute("ChapelMusic") or ""):gmatch("%d+") do table.insert(list, "rbxassetid://" .. d) end
	return list
end
local ti = 1
local music = Instance.new("Sound"); music.Name = "ChapelMusic"; music.SoundId = tracks()[1] or ""; music.Looped = #tracks() <= 1; music.Volume = 0; music.Parent = SoundService
task.spawn(function() pcall(function() ContentProvider:PreloadAsync({doorSfx, music}) end) end)
local inside = false
music.Ended:Connect(function()                                     -- the next track (the list is read again, so it can change)
	local list = tracks()
	if #list == 0 then return end
	ti = ti % #list + 1
	music.SoundId = list[ti]; music.Looped = #list <= 1; music.TimePosition = 0
	if inside then music:Play() end
end)
local tween
local function musicTo(target, secs)
	if tween then tween:Cancel() end
	tween = TweenService:Create(music, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Volume = target}); tween:Play()
end
local function update()
	if inside then
		if not music.IsPlaying then music.Volume = 0; music:Play() end
		musicTo(F:GetAttribute("MusicVolume") or 0.12, 1.4)
	else
		musicTo(0, 0.8)
		task.delay(0.85, function() if not inside and music.Volume <= 0.001 then music:Stop() end end)
	end
end
local function watchChar(char)
	inside = char:GetAttribute("InChapel") == true
	update()
	char:GetAttributeChangedSignal("InChapel"):Connect(function() inside = char:GetAttribute("InChapel") == true; update() end)
end
if player.Character then watchChar(player.Character) end
player.CharacterAdded:Connect(watchChar)

-- the fade to black for the doors, and a line at the foot of the screen
local gui = Instance.new("ScreenGui"); gui.Name = "ChapelFade"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 20; gui.Parent = pg
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.Parent = gui
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -100); note.Size = UDim2.fromOffset(460, 40)
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0; note.Font = Enum.Font.FredokaOne; note.TextSize = 18
note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local shownAt = 0
local function say(text)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(3, function() if shownAt ~= mine then return end; TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
end
ev.OnClientEvent:Connect(function(what, secs, toInside)
	if what == "fade" then
		doorSfx:Play()
		TweenService:Create(black, TweenInfo.new(secs or 0.45), {BackgroundTransparency = 0}):Play()
	elseif what == "unfade" then
		TweenService:Create(black, TweenInfo.new(secs or 0.45), {BackgroundTransparency = 1}):Play()
	elseif what == "candle" then
		say("You lit a candle.")
	end
end)
]==]
	local ev = Instance.new("RemoteEvent"); ev.Name = "ChapelEvent"; ev.Parent = F
	local srv = Instance.new("Script"); srv.Name = "ChapelServer"; srv.RunContext = Enum.RunContext.Server; srv.Source = SERVER; srv.Parent = F
	local cli = Instance.new("Script"); cli.Name = "ChapelClient"; cli.RunContext = Enum.RunContext.Client; cli.Source = CLIENT; cli.Parent = F
	-- the room hangs over the map: RoomHide (village/build_roomhide.lua) keeps it off every screen but the ones inside
	local boxCF, boxSize = room:GetBoundingBox()
	room:SetAttribute("BoxCF", boxCF); room:SetAttribute("BoxSize", boxSize)
	game:GetService("CollectionService"):AddTag(room, "SkyRoom")
	F.Parent = workspace
	table.insert(report, 1, string.format("room at %.1f,%.1f,%.1f facing %.2f,%.2f | door %.1f,%.1f,%.1f | in %.1f,%.1f,%.1f | out %.1f,%.1f,%.1f",
		R.Position.X, R.Position.Y, R.Position.Z, front.X, front.Z, doorAt.X, doorAt.Y, doorAt.Z, inSpot.X, inSpot.Y, inSpot.Z, outSpot.X, outY, outSpot.Z))
	local n = 0
	for _, d in ipairs(room:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	table.insert(report, n .. " parts in the room")
	return table.concat(report, " | ")
end

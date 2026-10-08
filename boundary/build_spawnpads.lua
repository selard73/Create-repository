-- SpawnPads: the acorn dais that used to stand only in the forest, now repeated in Rue de Noisette and at Château de
-- l'Acorn, with a SpawnLocation of its own on each. Same artwork and the same S = 0.35 across the ground, so the three
-- read as one set. The spawn logic that decides which of them a player comes back to lives in build_spawnreturn.lua.
-- Run in edit mode: require(workspace.SpawnPads.PatchModule)()  (packed by village/make_patch.py)
return function()
	local C = Color3.fromRGB
	local S = 0.35                                                -- everything across the ground scales by this
	local CREAM, STONE, RIM = C(238, 230, 208), C(206, 194, 166), C(176, 160, 128)
	local GOLD, NUT, CAP, CAP_DK = C(232, 196, 104), C(208, 148, 84), C(112, 72, 42), C(86, 54, 32)
	local LEAF = C(126, 170, 84)
	local SPOTS = {
		-- `face` is the point the acorn's tip is turned toward; the artwork is painted with the tip along +Z, so a
		-- spot with no `face` keeps that.
		{id = "forest",  x = 3,   z = 1},
		{id = "village", x = 196, z = -36,  face = Vector3.new(196, 0, -80)},   -- the meadow on the far side of the
		                                              -- houses, by the river bank near the painter, tip toward the
		                                              -- backs of the houses
		{id = "domaine", x = 438, z = -36,  face = Vector3.new(456, 0, -165)},   -- the open lawn south of the farmyard,
		                                              -- tip toward the middle of the lavender field
	}

	-- the old single-dais names, from when the forest was the only section with one
	for _, n in ipairs({"SpawnDais", "SpawnPad"}) do local o = workspace:FindFirstChild(n); if o and o:IsA("Model") then o:Destroy() end end
	local firstSpawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)   -- reuse one, so the place always has a spawn

	-- whatever the ground happens to be under each spot: the street's paving, the estate's terrain, the baseplate
	local skip = {}
	for _, n in ipairs({"Boundary", "SquirrelTwins", "Zones", "Camera"}) do local o = workspace:FindFirstChild(n); if o then table.insert(skip, o) end end
	for _, o in ipairs(workspace:GetChildren()) do
		if o:FindFirstChildWhichIsA("Humanoid") or o.Name:sub(1, 9) == "SpawnDais" or o:IsA("SpawnLocation") then table.insert(skip, o) end
	end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = skip

	local function buildOne(spot)
		local cx, cz = spot.x, spot.z
		local yaw = spot.face and math.atan2(spot.face.X - cx, spot.face.Z - cz) or 0
		local old = workspace:FindFirstChild("SpawnDais_" .. spot.id); if old then old:Destroy() end
		local hit = workspace:Raycast(Vector3.new(cx, 160, cz), Vector3.new(0, -260, 0), rp)
		assert(hit, "SpawnPads: no ground under " .. spot.id .. " at " .. cx .. ", " .. cz)
		local groundY = hit.Position.Y
		local model = Instance.new("Model"); model.Name = "SpawnDais_" .. spot.id

		local function part(name, size, cf, col, collide)
			local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = false; p.CanTouch = false; p.Locked = true
			p.Material = Enum.Material.SmoothPlastic; p.Color = col; p.Size = size; p.CFrame = cf; p.CastShadow = true
			p.Parent = model
			return p
		end
		-- a flat ellipse lying on the dais: a Block with a Sphere mesh, squashed (a Cylinder part stays circular)
		local function discAt(name, dx, dz, w, d, y, col, thick, yaw)
			local p = part(name, Vector3.new(w * S, thick or 0.22, d * S), CFrame.new(cx + dx * S, y, cz + dz * S) * CFrame.Angles(0, yaw or 0, 0), col)
			local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
			return p
		end
		local function box(name, w, d, dx, dz, h, y, col, yaw)
			return part(name, Vector3.new(w * S, h, d * S), CFrame.new(cx + dx * S, y, cz + dz * S) * CFrame.Angles(0, yaw or 0, 0), col)
		end

		-- ---- the dais: two steps, a stone top and a gold rim. The bottom step reaches well below the ground so the
		-- estate's uneven terrain cannot open a gap under one corner; only its top 0.44 shows, as in the forest.
		local topY = groundY + 1.0
		part("Step", Vector3.new(30 * S, 1.64, 30 * S), CFrame.new(cx, groundY - 0.38, cz), RIM, true)
		part("Step", Vector3.new(26 * S, 0.4, 26 * S), CFrame.new(cx, groundY + 0.6, cz), STONE, true)
		local top = part("Top", Vector3.new(22 * S, 0.4, 22 * S), CFrame.new(cx, topY - 0.2, cz), CREAM, true)
		top.TopSurface = Enum.SurfaceType.Smooth
		-- ---- the painted acorn: cream slab, gold corners, tan nut, brown cap, green leaves. The nut is a line of
		-- circles down the centre, longer than it is wide and tapering to an off-centre point, with a seam line down it.
		for _, o in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do    -- a gold band round the rim of the top slab
			part("Band", Vector3.new(o[1] ~= 0 and 0.4 or 22.4 * S, 0.16, o[2] ~= 0 and 0.4 or 22.4 * S),
				CFrame.new(cx + o[1] * 11.2 * S, topY - 0.02, cz + o[2] * 11.2 * S), GOLD)
		end
		for _, o in ipairs({{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}) do  -- corner studs
			part("Stud", Vector3.new(1.4 * S, 0.2, 1.4 * S), CFrame.new(cx + o[1] * 10.3 * S, topY, cz + o[2] * 10.3 * S), GOLD)
		end

		local A = topY + 0.06                                         -- the paint layer
		for _, sx in ipairs({-1, 1}) do                               -- two leaves beside the stem
			box("LeafStem", 3.4, 0.5, sx * 3.0, -7.9, 0.14, A, C(96, 132, 62), sx * 0.55)
			discAt("Leaf", sx * 6.4, -9.0, 5.6, 2.4, A + 0.02, LEAF, 0.18)
		end
		local PROFILE = {{0.0, -1.2, 5.0}, {0.0, 0.2, 5.3}, {-0.1, 1.7, 5.2}, {-0.2, 3.1, 4.9}, {-0.3, 4.4, 4.4},
			{-0.4, 5.6, 3.8}, {-0.6, 6.7, 3.1}, {-0.8, 7.7, 2.4}, {-1.0, 8.5, 1.7}, {-1.1, 9.1, 1.1}}
		for i, c in ipairs(PROFILE) do
			discAt("Nut", c[1], c[2], c[3] * 2, c[3] * 2, A + 0.02 + i * 0.004, NUT, 0.24)
		end
		box("NutTip", 1.5, 1.5, -1.3, 9.5, 0.2, A + 0.08, NUT, math.pi / 4)    -- a turned square finishes the point
		local function nutAt(z)
			for i = 1, #PROFILE - 1 do
				local a, b = PROFILE[i], PROFILE[i + 1]
				if z >= a[2] and z <= b[2] then
					local f = (z - a[2]) / (b[2] - a[2])
					return a[1] + (b[1] - a[1]) * f, a[3] + (b[3] - a[3]) * f
				end
			end
			return PROFILE[#PROFILE][1], PROFILE[#PROFILE][3]
		end
		local px, pz                                                  -- short straight pieces, each turned to follow the curve
		for k = 0, 12 do
			local z = 2.1 + k * 0.48
			local dx, r = nutAt(z)
			local x = dx - r * 0.55
			if px then
				local sx, sz = x - px, z - pz
				local len = math.sqrt(sx * sx + sz * sz)
				box("NutAccent", 0.3, len + 0.1, (x + px) / 2, (z + pz) / 2, 0.16, A + 0.1, C(201, 142, 79), math.atan2(sx, sz))
			end
			px, pz = x, z
		end
		discAt("Cap", 0, -2.6, 14.6, 7.6, A + 0.12, CAP, 0.24)
		discAt("CapBrim", 0, 0.2, 14.8, 2.4, A + 0.14, CAP_DK, 0.18)
		for row = 0, 1 do                                             -- the cap's dots, kept inside it
			for i = -2, 2 do
				discAt("Scale", i * 2.6 + (row == 1 and 1.3 or 0), -3.8 + row * 2.0, 1.7, 1.2, A + 0.16, C(94, 60, 34), 0.16)
			end
		end
		box("Stem", 1.6, 3.0, 0, -7.2, 0.14, A + 0.12, CAP_DK)
		discAt("StemTop", 0, -8.7, 2.4, 1.5, A + 0.12, CAP_DK, 0.18)
		if yaw ~= 0 then                                              -- turn the whole slab about its own centre
			local piv = Vector3.new(cx, topY, cz)
			model:PivotTo(CFrame.new(piv) * CFrame.Angles(0, yaw, 0) * CFrame.new(-piv) * model:GetPivot())
		end
		model.Parent = workspace

		-- ---- the spawn point itself: on the dais, invisible, no decal, so only the artwork shows
		local sp = workspace:FindFirstChild("Spawn_" .. spot.id)
		if not sp then
			sp = firstSpawn or Instance.new("SpawnLocation")
			firstSpawn = nil
		end
		sp.Name = "Spawn_" .. spot.id
		for _, d in ipairs(sp:GetChildren()) do if d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end end
		sp.Anchored = true
		sp.Size = Vector3.new(16 * S, 1, 16 * S)
		sp.CFrame = CFrame.new(cx, topY + 0.5, cz) * CFrame.Angles(0, yaw, 0)
		sp.Transparency = 1
		-- NOT COLLIDABLE. Its top sat a full stud above the dais, invisible, and everyone spawned standing on
		-- it - "why is the character floating above the platform?" The dais is the floor; this is only a marker.
		sp.CanCollide = false
		sp.Neutral = true
		sp.Enabled = true
		sp.Duration = 0
		sp.AllowTeamChangeOnTouch = false
		sp.TopSurface = Enum.SurfaceType.Smooth
		sp.Parent = workspace
		sp:SetAttribute("Area", spot.id)

		-- a signpost standing on the dais steps aside, so it reads as standing beside it
		local gates = workspace:FindFirstChild("Boundary") and workspace.Boundary:FindFirstChild("Gates")
		if gates then
			local clear = 15 * S + 3.5
			for _, g in ipairs(gates:GetChildren()) do
				if g:IsA("Model") and g.Name:sub(1, 4) == "Sign" then
					local bb = g:GetBoundingBox()
					local d = Vector3.new(bb.Position.X - cx, 0, bb.Position.Z - cz)
					if d.Magnitude < clear then
						local dir = (d.Magnitude > 0.5) and d.Unit or Vector3.new(1, 0, 0)
						g:PivotTo(g:GetPivot() + dir * (clear - d.Magnitude))
					end
				end
			end
		end
		return string.format("%s at %.0f, %.0f facing %.0f deg on %s (top %.2f)", spot.id, cx, cz, math.deg(yaw), hit.Instance.Name, topY)
	end

	local report = {}
	for _, spot in ipairs(SPOTS) do table.insert(report, buildOne(spot)) end
	if firstSpawn then firstSpawn:Destroy() end                   -- a leftover spawn from before, now unused
	print("SpawnPads: " .. table.concat(report, " | "))
end

-- SpawnPad: the plain grey spawn square becomes a small raised stone dais with a giant acorn painted on it, in the
-- same flat low-poly style as the rest of the game. The SpawnLocation itself stays (invisible, its decal off) on top.
-- S sets how big it is across the ground: the first build was 1.0 (too large), Shannon asked for about a third.
-- Run in edit mode: require(workspace.SpawnPad.PatchModule)()  (packed by village/make_patch.py)
return function()
	local old = workspace:FindFirstChild("SpawnDais"); if old then old:Destroy() end
	local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	assert(sp, "SpawnPad: no SpawnLocation")
	local C = Color3.fromRGB
	local S = 0.35                                                -- everything across the ground scales by this
	local PLAQUE_ID = 117971730440312                             -- the carved acorn plaque, recoloured (marketing/make_plaque.py)
	local CREAM, STONE, RIM = C(238, 230, 208), C(206, 194, 166), C(176, 160, 128)
	local GOLD, NUT, NUT_HI, CAP, CAP_DK = C(232, 196, 104), C(208, 148, 84), C(230, 180, 122), C(112, 72, 42), C(86, 54, 32)
	local LEAF = C(126, 170, 84)

	-- the dais sits on the ground the spawn was standing on, and the spawn moves to its top
	local ground = {workspace.Terrain}
	if workspace:FindFirstChild("Baseplate") then table.insert(ground, workspace.Baseplate) end
	if workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Ground") then table.insert(ground, workspace.Village.Ground) end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = ground
	local hit = workspace:Raycast(sp.Position + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), rp)    -- real ground only, never a stray character
	local groundY = hit and hit.Position.Y or 0
	local cx, cz = sp.Position.X, sp.Position.Z
	local model = Instance.new("Model"); model.Name = "SpawnDais"

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

	-- ---- the dais: two steps, a stone top and a gold rim
	local step1Y = groundY + 0.22
	local step2Y = groundY + 0.6
	local topY = groundY + 1.0
	part("Step", Vector3.new(30 * S, 0.44, 30 * S), CFrame.new(cx, step1Y, cz), RIM, true)
	part("Step", Vector3.new(26 * S, 0.4, 26 * S), CFrame.new(cx, step2Y, cz), STONE, true)
	local top = part("Top", Vector3.new(22 * S, 0.4, 22 * S), CFrame.new(cx, topY - 0.2, cz), CREAM, true)
	top.TopSurface = Enum.SurfaceType.Smooth
	-- ---- the painted acorn, the version Shannon kept: cream slab, gold corners, tan nut, brown cap, green leaves.
	-- The nut is drawn as a line of circles down the centre, longer than it is wide and tapering to an off-centre
	-- point, with a seam line down it, so it reads as an acorn rather than a smooth dome.
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
	box("NutTip", 1.5, 1.5, -1.3, 9.5, 0.2, A + 0.08, NUT, math.pi / 4)    -- a small turned square finishes the point, well inside the gold moulding
	-- a curved accent following the nut's left edge, a little inside it, well clear of the cap
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

	model.Parent = workspace
	-- the spawn point itself: on the dais, invisible, no decal, so only the artwork shows
	for _, d in ipairs(sp:GetChildren()) do if d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end end
	sp.Size = Vector3.new(16 * S, 1, 16 * S)
	sp.Position = Vector3.new(cx, topY + 0.5, cz)
	sp.Transparency = 1
	sp.CanCollide = true
	sp.TopSurface = Enum.SurfaceType.Smooth
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
					print("SpawnPad: " .. g.Name .. " moved clear of the dais")
				end
			end
		end
	end
	print(string.format("SpawnPad: dais at %.0f, %.0f, top %.2f, %.1f studs across (%d parts)", cx, cz, topY, 30 * S, #model:GetChildren()))
end

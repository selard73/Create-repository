-- The croc's lagoon (Shannon, Sep 26 2026, spot "A": the forest's north-east corner, by the river). A sunken pond with a
-- mud bank, an island in the middle where the croc keeps his captured squirrels, lily pads to hop across, reeds, and a
-- warning sign at the path in.
--   THE HOLE: the forest floor is the Baseplate, one flat Part (top at y 0), so a pond needs a hole in it. The Baseplate
--         becomes a Union with a lagoon-shaped hole cut by upright cylinders (one per lobe); the original Part is kept in
--         ServerStorage.LagoonBackup. Terrain fills the hole: a mud bank from the rim (flush with the grass) down into
--         the water, a deep middle, and the island. Cut once: the Baseplate carries LagoonHole = true afterwards.
--   CLEARED: forest props standing where the water goes are moved to ServerStorage.LagoonBackup.Cleared (never
--         destroyed); some pines are planted again round the rim, the big rock and the mushrooms go to the island, the
--         hollow log floats in the west arm.
-- Attributes on workspace.Lagoon (the croc reads them): WaterY, Lobes ("x,z,r;..." the water's outline), Grow (bank
-- width), IslandX/IslandZ/IslandR, ShoreZ (the south shore's line), SignX/SignZ, PadPath ("x,z;..." stepping pads).
-- Run in edit mode.
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local T = workspace.Terrain
	local SS = game:GetService("ServerStorage")
	local WATER_Y = opts.waterY or -1.0
	local GROW = opts.grow or 5
	local LOBES = opts.lobes or {{117, -180, 17}, {103, -166, 9}, {125, -196, 8}, {106, -195, 8}, {127, -164, 7}}
	local ISL = opts.island or {118, -181, 6.5}
	local rnd = Random.new(opts.seed or 26)
	local report = {}
	local function note(s) table.insert(report, s) end

	local function sdfWater(x, z)                                    -- > 0 inside the water's outline
		local best = -math.huge
		for _, l in ipairs(LOBES) do
			local d = l[3] - math.sqrt((x - l[1]) ^ 2 + (z - l[2]) ^ 2)
			if d > best then best = d end
		end
		return best
	end
	local function sdfIsland(x, z) return ISL[3] - math.sqrt((x - ISL[1]) ^ 2 + (z - ISL[2]) ^ 2) end
	local function lerp(a, b, t) return a + (b - a) * math.clamp(t, 0, 1) end
	local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
	-- the ground's height inside the hole (and a little beyond it, hidden under the grass, to seal the edge)
	local function height(x, z)
		local d = sdfWater(x, z)
		local h
		if d <= -GROW + 1.5 then h = -0.1                          -- a hair under the grass: no flicker where they meet
		elseif d <= 0 then h = lerp(-0.1, WATER_Y - 0.15, ease((d + GROW - 1.5) / (GROW - 1.5)))
		elseif d <= 4 then h = lerp(WATER_Y - 0.15, -5, ease(d / 4))
		else h = -5 - math.min(2.5, (d - 4) * 0.5) end
		local di = sdfIsland(x, z)
		local hi
		if di >= 2.5 then hi = 0.7
		elseif di >= 0 then hi = lerp(WATER_Y - 0.15, 0.7, ease(di / 2.5))
		elseif di >= -4 then hi = lerp(-6, WATER_Y - 0.15, ease((di + 4) / 4))
		end
		if hi and hi > h then h = hi end
		return h, d, di
	end

	-- ---------------------------------------------------------------- the lagoon folder ----
	local L = workspace:FindFirstChild("Lagoon")
	if not L then L = Instance.new("Folder"); L.Name = "Lagoon"; L.Parent = workspace end
	local oldProps = L:FindFirstChild("Props"); if oldProps then oldProps:Destroy() end
	local P = Instance.new("Folder"); P.Name = "Props"; P.Parent = L
	local lobeStr = {}
	for _, l in ipairs(LOBES) do table.insert(lobeStr, string.format("%g,%g,%g", l[1], l[2], l[3])) end
	L:SetAttribute("WaterY", WATER_Y); L:SetAttribute("Lobes", table.concat(lobeStr, ";")); L:SetAttribute("Grow", GROW)
	L:SetAttribute("IslandX", ISL[1]); L:SetAttribute("IslandZ", ISL[2]); L:SetAttribute("IslandR", ISL[3])

	local backup = SS:FindFirstChild("LagoonBackup")
	if not backup then backup = Instance.new("Folder"); backup.Name = "LagoonBackup"; backup.Parent = SS end
	local cleared = backup:FindFirstChild("Cleared")
	if not cleared then cleared = Instance.new("Folder"); cleared.Name = "Cleared"; cleared.Parent = backup end

	-- ---------------------------------------------------------------- clear the forest props where the water goes ----
	local F = workspace:FindFirstChild("Forest")
	local moved = {}
	local D = workspace:FindFirstChild("Boundary") and workspace.Boundary:FindFirstChild("Dressing")
	if D then
		for _, m in ipairs(D:GetChildren()) do
			if m:IsA("Model") then
				local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
				if ok and sdfWater(cf.Position.X, cf.Position.Z) > -(GROW + 1.5) then
					table.insert(moved, {m = m, cf = cf, size = size, dressing = true})
				end
			end
		end
	end
	if F then
		for _, m in ipairs(F:GetChildren()) do
			if m:IsA("Model") then
				local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
				if ok and sdfWater(cf.Position.X, cf.Position.Z) > -(GROW + 1.5) then
					table.insert(moved, {m = m, cf = cf, size = size})
				end
			end
		end
		-- hiding-spot markers under the water go too (edit-time builders use them to seat squirrels)
		local hs = F:FindFirstChild("HidingSpots")
		if hs then
			for _, a in ipairs(hs:GetDescendants()) do
				if a:IsA("Attachment") and sdfWater(a.WorldPosition.X, a.WorldPosition.Z) > -GROW then a.Parent = nil end
			end
		end
	end
	local names = {}
	for _, e in ipairs(moved) do table.insert(names, e.m.Name) end
	note(#moved .. " forest props moved out of the water: " .. table.concat(names, ", "))

	-- ---------------------------------------------------------------- the hole in the Baseplate ----
	local bp = workspace:FindFirstChild("Baseplate")
	if bp and not bp:GetAttribute("LagoonHole") then
		local cutters = {}
		for _, l in ipairs(LOBES) do
			local c = Instance.new("Part"); c.Shape = Enum.PartType.Cylinder; c.Anchored = true
			c.Size = Vector3.new(40, (l[3] + GROW) * 2, (l[3] + GROW) * 2)
			c.CFrame = CFrame.new(l[1], -8, l[2]) * CFrame.Angles(0, 0, math.rad(90))
			c.Parent = workspace
			table.insert(cutters, c)
		end
		local ok, u = pcall(function()
			return bp:SubtractAsync(cutters, Enum.CollisionFidelity.PreciseConvexDecomposition, Enum.RenderFidelity.Precise)
		end)
		for _, c in ipairs(cutters) do c:Destroy() end
		if not ok or not u then error("the Baseplate could not be cut: " .. tostring(u)) end
		u.Name = "Baseplate"; u.Anchored = true; u.CanCollide = true; u.Locked = bp.Locked
		u.Material = bp.Material; u.Color = bp.Color; u.UsePartColor = true
		u.CastShadow = bp.CastShadow; u.TopSurface = Enum.SurfaceType.Smooth
		for k, v in pairs(bp:GetAttributes()) do u:SetAttribute(k, v) end
		u:SetAttribute("LagoonHole", true)
		for _, ch in ipairs(bp:GetChildren()) do ch.Parent = u end
		local keep = backup:FindFirstChild("Baseplate"); if keep then keep:Destroy() end
		bp.Parent = backup                                        -- the original, whole
		u.Parent = workspace
		note(string.format("Baseplate cut: %s, %d lobes", u.ClassName, #LOBES))
	else
		note("Baseplate already has the hole (" .. (bp and bp.ClassName or "none") .. ")")
	end

	-- ---------------------------------------------------------------- terrain: bank, bed, island, water ----
	local x0, x1, z0, z1 = 84, 144, -216, -144
	local y0, y1 = -12, 4
	local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
	local nx, ny, nz = (x1 - x0) / 4, (y1 - y0) / 4, (z1 - z0) / 4
	local solidMat, solidOcc, liquid = {}, {}, {}
	local waterCells = 0
	local oldMats, oldOccs = T:ReadVoxels(region, 4)                 -- outside the hole, the terrain stays as it was
	for ix = 1, nx do
		solidMat[ix], solidOcc[ix], liquid[ix] = {}, {}, {}
		for iy = 1, ny do solidMat[ix][iy], solidOcc[ix][iy], liquid[ix][iy] = {}, {}, {} end
		for iz = 1, nz do
			local cx, cz = x0 + (ix - 0.5) * 4, z0 + (iz - 0.5) * 4
			-- four samples per column, so the slopes come out smooth
			local hs, dsum, disum = 0, 0, 0
			for _, o in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
				local h, d, di = height(cx + o[1], cz + o[2])
				hs += h; dsum += d; disum += di
			end
			local h, d, di = hs / 4, dsum / 4, disum / 4
			local inHole = d > -(GROW + 2.5)
			for iy = 1, ny do
				local yb = y0 + (iy - 1) * 4
				local occ = math.clamp((h - yb) / 4, 0, 1)
				local mat = Enum.Material.Mud                            -- the waterline and the bed: dark mud
				if di > 1.6 and h > WATER_Y + 0.2 then mat = Enum.Material.Grass
				elseif di > -0.5 and h > WATER_Y - 0.6 then mat = Enum.Material.Sand
				elseif h > WATER_Y + 0.45 then mat = Enum.Material.Grass     -- the upper bank: grass, like the forest floor
				elseif not inHole then mat = Enum.Material.Ground end
				local lq = 0
				if inHole and d > -1.5 and h < WATER_Y then lq = math.clamp((WATER_Y - yb) / 4, 0, 1) end
				if lq > 0 and occ < 1 then waterCells += 1 end
				if not inHole then
					mat = oldMats[ix][iy][iz]; occ = oldOccs[ix][iy][iz]; lq = 0
					if mat == Enum.Material.Water then lq = occ; mat = Enum.Material.Air; occ = 0 end
				end
				solidMat[ix][iy][iz] = mat; solidOcc[ix][iy][iz] = occ; liquid[ix][iy][iz] = lq
			end
		end
	end
	local okC, errC = pcall(function()
		T:WriteVoxelChannels(region, 4, {SolidMaterial = solidMat, SolidOccupancy = solidOcc, LiquidOccupancy = liquid})
	end)
	if not okC then
		-- older API: one material per cell - water where the cell is mostly not ground
		local mats, occs = {}, {}
		for ix = 1, nx do
			mats[ix], occs[ix] = {}, {}
			for iy = 1, ny do
				mats[ix][iy], occs[ix][iy] = {}, {}
				for iz = 1, nz do
					local so, lq = solidOcc[ix][iy][iz], liquid[ix][iy][iz]
					if so >= 0.5 or lq <= 0 then mats[ix][iy][iz] = (so > 0) and solidMat[ix][iy][iz] or Enum.Material.Air; occs[ix][iy][iz] = so
					else mats[ix][iy][iz] = Enum.Material.Water; occs[ix][iy][iz] = lq end
				end
			end
		end
		T:WriteVoxels(region, 4, mats, occs)
	end
	note(string.format("terrain written (%s): %d x %d x %d cells, %d with water", okC and "channels" or ("voxels: " .. tostring(errC)), nx, ny, nz, waterCells))
	-- the pond's look: murky green, calm; the mud a dark earthy brown (the default Mud reads as grey concrete)
	T:SetMaterialColor(Enum.Material.Mud, opts.mudColor or C(96, 80, 56))
	T.WaterColor = opts.waterColor or C(52, 104, 78)
	T.WaterTransparency = opts.waterTransparency or 0.45
	T.WaterWaveSize = opts.waveSize or 0.06
	T.WaterWaveSpeed = opts.waveSpeed or 5
	T.WaterReflectance = opts.reflectance or 0.55

	-- ---------------------------------------------------------------- props ----
	local function part(name, size, cf, colour, material, shape, parent)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or P
		return p
	end
	local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))                -- a Cylinder's axis is X; this stands it up

	-- LILY PADS: a disc with a slit (the notch every lily pad has). The stepping pads from the south shore to the island
	-- are big and solid; the rest are for looks (solid too - hopping is fun), a few with a pink flower.
	local PAD, PAD_DARK = C(92, 156, 70), C(70, 128, 58)
	local function lily(name, at, dia, turn, flower)
		local disc = part(name, Vector3.new(0.22, dia, dia), CFrame.new(at) * CFrame.Angles(0, turn, 0) * UPRIGHT, PAD, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		local slit = Instance.new("Part"); slit.Anchored = true; slit.Size = Vector3.new(dia * 0.52, 1, 0.34)
		slit.CFrame = CFrame.new(at) * CFrame.Angles(0, turn, 0) * CFrame.new(dia * 0.26, 0, 0); slit.Parent = workspace
		local ok, u = pcall(function() return disc:SubtractAsync({slit}) end)
		slit:Destroy()
		if ok and u then
			u.Name = name; u.Color = PAD; u.UsePartColor = true; u.Anchored = true; u.Material = Enum.Material.SmoothPlastic
			u.Parent = P; disc:Destroy(); disc = u
		end
		local vein = part(name .. "Vein", Vector3.new(0.27, dia * 0.55, dia * 0.55), CFrame.new(at) * UPRIGHT, PAD_DARK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		vein.CanCollide = false
		if flower then
			local base = CFrame.new(at + Vector3.new(-dia * 0.12, 0.12, dia * 0.1))
			for k = 0, 5 do
				local petal = part("Petal", Vector3.new(0.42, 0.14, 0.95), base * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 0.15, -0.38) * CFrame.Angles(math.rad(-28), 0, 0),
					k % 2 == 0 and C(246, 168, 196) or C(236, 138, 176), Enum.Material.SmoothPlastic)
				petal.CanCollide = false
			end
			local mid = part("FlowerHeart", Vector3.new(0.4, 0.4, 0.4), base * CFrame.new(0, 0.28, 0), C(255, 214, 90), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			mid.CanCollide = false
		end
		return disc
	end
	-- the stepping path: from where the water really starts on the south side (the first pads once sat on the mud -
	-- and out of the croc's water) to the island's south beach
	local pathFrom = Vector3.new(opts.pathX or 111, 0, opts.pathZ or -157)
	local islandEdge = Vector3.new(ISL[1] - 1.5, 0, ISL[2] + ISL[3] + 0.5)
	local shoreStart = pathFrom
	for k = 0, 60 do
		local q = pathFrom:Lerp(islandEdge, k / 60)
		if sdfWater(q.X, q.Z) > 1.0 then shoreStart = q break end
	end
	local steps = {}
	local nPads = math.max(3, math.floor((islandEdge - shoreStart).Magnitude / 3.3 + 0.5))
	for k = 1, nPads do
		local t = (k - 1) / math.max(1, nPads - 1) * 0.86
		local p = shoreStart:Lerp(islandEdge, t) + Vector3.new(math.sin(k * 1.7) * 1.0, 0, 0)
		local pad = lily("StepPad", Vector3.new(p.X, WATER_Y + 0.12, p.Z), 4.4, rnd:NextNumber(0, math.pi * 2), k == 2 or k == 4)
		table.insert(steps, string.format("%.1f,%.1f", p.X, p.Z))
	end
	L:SetAttribute("PadPath", table.concat(steps, ";"))
	-- scattered pads (for looks), only where the water is deep enough and away from the island
	local placed = 0
	for tries = 1, 200 do
		if placed >= 14 then break end
		local x, z = rnd:NextNumber(90, 140), rnd:NextNumber(-208, -152)
		local d, di = sdfWater(x, z), sdfIsland(x, z)
		local nearPath = false
		for k = 1, nPads do
			local t = (k - 1) / math.max(1, nPads - 1) * 0.86
			if (shoreStart:Lerp(islandEdge, t) - Vector3.new(x, 0, z)).Magnitude < 5 then nearPath = true end
		end
		if d > 2.2 and di < -2 and not nearPath then
			placed += 1
			lily("LilyPad", Vector3.new(x, WATER_Y + 0.1, z), rnd:NextNumber(1.8, 3.2), rnd:NextNumber(0, math.pi * 2), placed % 5 == 0)
		end
	end

	-- REEDS: clumps of blades along the water's edge, some with cattails
	local REED = {C(84, 120, 58), C(104, 140, 66), C(70, 104, 52)}
	local function reeds(at, n)
		local g = Instance.new("Model"); g.Name = "Reeds"; g.Parent = P
		for k = 1, n do
			local hgt = rnd:NextNumber(2.4, 4.6)
			local off = Vector3.new(rnd:NextNumber(-0.9, 0.9), 0, rnd:NextNumber(-0.9, 0.9))
			local tilt = CFrame.Angles(rnd:NextNumber(-0.18, 0.18), rnd:NextNumber(0, 6.28), rnd:NextNumber(-0.18, 0.18))
			local base = CFrame.new(at + off) * tilt
			local blade = part("Blade", Vector3.new(hgt, 0.16, 0.16), base * CFrame.new(0, hgt / 2 - 0.3, 0) * UPRIGHT, REED[rnd:NextInteger(1, 3)], Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, g)
			blade.CanCollide = false; blade.CastShadow = false
			if k % 3 == 0 then
				local head = part("Cattail", Vector3.new(1.0, 0.34, 0.34), base * CFrame.new(0, hgt - 0.6, 0) * UPRIGHT, C(110, 72, 44), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder, g)
				head.CanCollide = false; head.CastShadow = false
			end
		end
	end
	local reedCount = 0
	for ang = 0, 355, 22 do
		for _, l in ipairs(LOBES) do
			local a = math.rad(ang + rnd:NextNumber(-8, 8))
			local r = l[3] + rnd:NextNumber(-0.4, 0.8)
			local x, z = l[1] + math.cos(a) * r, l[2] + math.sin(a) * r
			local d = sdfWater(x, z)
			local clearOfPath = (Vector3.new(x, 0, z) - shoreStart).Magnitude > 6
			if math.abs(d) < 0.9 and clearOfPath and rnd:NextNumber() < 0.42 and x < 138 then
				local h = height(x, z)
				reeds(Vector3.new(x, h, z), rnd:NextInteger(5, 9)); reedCount += 1
			end
		end
	end
	for k = 0, 3 do                                                  -- a few on the island's beach
		local a = math.rad(k * 90 + 50)
		local x, z = ISL[1] + math.cos(a) * (ISL[3] - 0.6), ISL[2] + math.sin(a) * (ISL[3] - 0.6)
		reeds(Vector3.new(x, height(x, z), z), rnd:NextInteger(4, 7)); reedCount += 1
	end
	note(reedCount .. " reed clumps, " .. placed .. " lily pads + " .. nPads .. " stepping pads")

	-- ---------------------------------------------------------------- the cleared props, placed again ----
	local function baseOf(e) return e.cf.Position - Vector3.new(0, e.size.Y / 2, 0) end
	local function moveTo(e, target, groundY)
		local b = baseOf(e)
		local off = Vector3.new(target.X - b.X, groundY - b.Y, target.Z - b.Z)   -- the base goes TO groundY (it used to be
		-- moved BY groundY, so every rebuild lifted the island props a little more - the floating mushrooms)
		e.m:PivotTo(e.m:GetPivot() + off)
	end
	local used = {}
	local function clearSpot(x, z, need)
		if x < 86 or x > 137 or z < -212 or z > -141 then return false end
		if sdfWater(x, z) > -(GROW + 3) then return false end
		if z > -176 and x > 95 then return false end                      -- the south side stays open: the view from the path in
		for _, u in ipairs(used) do if (u - Vector3.new(x, 0, z)).Magnitude < need then return false end end
		if F then
			for _, m in ipairs(F:GetChildren()) do
				if m:IsA("Model") then
					local ok, cf = pcall(function() return m:GetBoundingBox() end)
					if ok and (Vector3.new(cf.Position.X, 0, cf.Position.Z) - Vector3.new(x, 0, z)).Magnitude < need then return false end
				end
			end
		end
		return true
	end
	local replanted, toIsland, floated, stored = 0, 0, 0, 0
	local rockPlaced = false
	-- round the island's edge, clear of the croc's cages (at 30/150/270 degrees) and of the way in from the pads (south)
	local islandSlots = {{math.cos(math.rad(330)) * 4.8, math.sin(math.rad(330)) * 4.8}, {math.cos(math.rad(210)) * 4.8, math.sin(math.rad(210)) * 4.8}}
	for _, e in ipairs(moved) do
		local n = e.m.Name
		if n:find("pine") and replanted < 6 then
			local done = false
			for ring = 3, 7, 2 do
				for ang = 0, 350, 15 do
					local best = nil
					for _, l in ipairs(LOBES) do
						local a = math.rad(ang)
						local x, z = l[1] + math.cos(a) * (l[3] + GROW + ring), l[2] + math.sin(a) * (l[3] + GROW + ring)
						if clearSpot(x, z, 7) then best = Vector3.new(x, 0, z) break end
					end
					if best then
						moveTo(e, best, 0); table.insert(used, best); replanted += 1; done = true
						e.m:SetAttribute("LagoonReplanted", true)
						break
					end
				end
				if done then break end
			end
			if not done then e.m.Parent = cleared; stored += 1 end
		elseif n:find("mushroom") and toIsland == 0 then
			-- smaller, on the flat top of the island between two cages (Shannon: "the mushrooms are floating")
			toIsland = 1
			e.m:ScaleTo(0.7)
			local okB, cfB, szB = pcall(function() return e.m:GetBoundingBox() end)
			if okB then e.cf, e.size = cfB, szB end
			local a = math.rad(330)
			local x, z = ISL[1] + math.cos(a) * 3.0, ISL[2] + math.sin(a) * 3.0
			moveTo(e, Vector3.new(x, 0, z), height(x, z) - 0.08)
			-- then onto the terrain as it is actually drawn: the smoothed voxel surface stands above the height function,
			-- and the stems were buried in the hill (Shannon: "they need to come up slightly")
			local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include
			rpT.FilterDescendantsInstances = {T}; rpT.IgnoreWater = true
			local gmax = -math.huge
			for _, o in ipairs({{0, 0}, {0.8, 0}, {-0.8, 0}, {0, 0.8}, {0, -0.8}}) do
				local r = workspace:Raycast(Vector3.new(x + o[1], 20, z + o[2]), Vector3.new(0, -40, 0), rpT)
				if r then gmax = math.max(gmax, r.Position.Y) end
			end
			if gmax > -math.huge then
				local low = math.huge
				for _, p in ipairs(e.m:GetDescendants()) do
					if p:IsA("BasePart") then
						for _, cx in ipairs({-0.5, 0.5}) do for _, cy in ipairs({-0.5, 0.5}) do for _, cz in ipairs({-0.5, 0.5}) do
							low = math.min(low, (p.CFrame * Vector3.new(p.Size.X * cx, p.Size.Y * cy, p.Size.Z * cz)).Y)
						end end end
					end
				end
				e.m:PivotTo(e.m:GetPivot() + Vector3.new(0, (gmax - 0.1) - low, 0))
			end
		elseif n:find("rock_big") and not rockPlaced then
			-- off the island ("the rocks on the middle island are awkwardly placed"): the north bank, sunk into the grass
			rockPlaced = true
			moveTo(e, Vector3.new(opts.rockX or 124, 0, opts.rockZ or -212.5), -0.45)
		elseif n:find("log") and floated == 0 then
			floated = 1
			-- FLOATING IN THE WEST ARM, where it first sat (Shannon liked it there better than beached on the bank): lying
			-- roughly east-west, bottom a little under the water. The croc treats its footprint as solid - an oriented
			-- rectangle measured off the log's biggest part (Lagoon LogCenter / LogAxis / LogHalfA / LogHalfB).
			local function worldBox(m)
				local lo, hi = Vector3.new(math.huge, math.huge, math.huge), -Vector3.new(math.huge, math.huge, math.huge)
				for _, p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") then
						for _, cx in ipairs({-0.5, 0.5}) do for _, cy in ipairs({-0.5, 0.5}) do for _, cz in ipairs({-0.5, 0.5}) do
							local w = p.CFrame * Vector3.new(p.Size.X * cx, p.Size.Y * cy, p.Size.Z * cz)
							lo = Vector3.new(math.min(lo.X, w.X), math.min(lo.Y, w.Y), math.min(lo.Z, w.Z))
							hi = Vector3.new(math.max(hi.X, w.X), math.max(hi.Y, w.Y), math.max(hi.Z, w.Z))
						end end end
					end
				end
				return lo, hi
			end
			local main, vol = nil, 0
			for _, p in ipairs(e.m:GetDescendants()) do
				if p:IsA("BasePart") and p.Size.X * p.Size.Y * p.Size.Z > vol then main, vol = p, p.Size.X * p.Size.Y * p.Size.Z end
			end
			local function axes()
				-- the part's three axes by how long they lie on the water: [1] = along the log, [2] = across it
				local list = {}
				for _, pair in ipairs({{main.CFrame.RightVector, main.Size.X}, {main.CFrame.UpVector, main.Size.Y}, {main.CFrame.LookVector, main.Size.Z}}) do
					local h = Vector3.new(pair[1].X, 0, pair[1].Z)
					table.insert(list, {dir = h.Magnitude > 0.05 and h.Unit or Vector3.new(1, 0, 0), len = h.Magnitude * pair[2]})
				end
				table.sort(list, function(p, q) return p.len > q.len end)
				return list
			end
			if main then
				-- turn it back to its first heading: the long axis 10 degrees off east-west, as it lay when it first floated
				local ax = axes()[1].dir
				local want = Vector3.new(math.cos(math.rad(opts.logHeading or 10)), 0, math.sin(math.rad(opts.logHeading or 10)))
				local turn = math.atan2(-want.X, -want.Z) - math.atan2(-ax.X, -ax.Z)
				local lo0, hi0 = worldBox(e.m)
				local c0 = (lo0 + hi0) / 2
				e.m:PivotTo(CFrame.new(c0) * CFrame.Angles(0, turn, 0) * CFrame.new(-c0) * e.m:GetPivot())
			end
			local lo, hi = worldBox(e.m)
			local centre = (lo + hi) / 2
			e.m:PivotTo(e.m:GetPivot() + Vector3.new((opts.logX or 101) - centre.X, (WATER_Y - 0.55) - lo.Y, (opts.logZ or -170) - centre.Z))
			lo, hi = worldBox(e.m)
			if main then
				local ax = axes()
				L:SetAttribute("LogCenter", Vector3.new(main.Position.X, (lo.Y + hi.Y) / 2, main.Position.Z))
				L:SetAttribute("LogAxis", ax[1].dir)
				L:SetAttribute("LogHalfA", ax[1].len / 2); L:SetAttribute("LogHalfB", ax[2].len / 2)
			end
			L:SetAttribute("LogMin", nil); L:SetAttribute("LogMax", nil)
			-- no reeds or lily pads poking through it
			for _, obj in ipairs(P:GetChildren()) do
				local pos
				if obj:IsA("Model") then local okp, cfp = pcall(function() return obj:GetBoundingBox() end); pos = okp and cfp.Position or nil
				elseif obj:IsA("BasePart") or obj:IsA("UnionOperation") then pos = obj.Position end
				local nm = obj.Name
				if pos and (nm == "Reeds" or nm == "LilyPad" or nm:find("Vein") or nm == "Petal" or nm == "FlowerHeart")
					and pos.X > lo.X - 1.2 and pos.X < hi.X + 1.2 and pos.Z > lo.Z - 1.2 and pos.Z < hi.Z + 1.2 then obj:Destroy() end
			end
		else
			e.m.Parent = cleared; stored += 1
		end
	end
	note(string.format("props: %d pines replanted round the rim, %d to the island, %d floating log, %d stored", replanted, toIsland, floated, stored))

	-- ---------------------------------------------------------------- the warning sign on the path in ----
	local signAt = Vector3.new(opts.signX or 104, 0, opts.signZ or -147)
	local face = (Vector3.new(ISL[1], 0, ISL[2]) - signAt).Unit                       -- its back to the lagoon
	local sc = CFrame.lookAt(signAt, signAt - face)
	local WOOD, DARK = C(150, 104, 64), C(96, 66, 42)
	local sign = Instance.new("Model"); sign.Name = "WarningSign"; sign.Parent = P
	-- the post stands BEHIND the board (Sep 27, Shannon: "at a certain angle you can see the sign post through the sign" -
	-- at 0.1 back its front face was flush with the board's)
	part("Post", Vector3.new(0.5, 4.6, 0.5), sc * CFrame.new(0, 2.3, 0.42), DARK, Enum.Material.Wood, nil, sign)
	local board = part("Board", Vector3.new(5.6, 2.9, 0.3), sc * CFrame.new(0, 4.1, 0) * CFrame.Angles(0, 0, math.rad(-3)), WOOD, Enum.Material.Wood, nil, sign)
	part("Trim", Vector3.new(5.9, 0.28, 0.36), board.CFrame * CFrame.new(0, 1.5, 0), DARK, Enum.Material.Wood, nil, sign)
	part("Trim", Vector3.new(5.9, 0.28, 0.36), board.CFrame * CFrame.new(0, -1.5, 0), DARK, Enum.Material.Wood, nil, sign)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 60; sg.LightInfluence = 0.6; sg.Parent = board
	local function line(text, y, h, size, colour, font)
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.new(1, -24, 0, h); t.Position = UDim2.new(0, 12, 0, y)
		t.Text = text; t.TextColor3 = colour; t.TextSize = size; t.TextWrapped = true
		t.FontFace = font or Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold); t.Parent = sg
		return t
	end
	line("ATTENTION !", 16, 44, 40, C(170, 36, 30))
	local nameLine = line(L:GetAttribute("CrocName") or "Crocodile", 58, 40, 32, C(40, 26, 14))
	nameLine.Name = "CrocName"
	line("Rescue the squirrels on his island. Bonk him with your slingshot!", 102, 64, 22, C(40, 26, 14),
		Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold))
	L:SetAttribute("SignX", signAt.X); L:SetAttribute("SignZ", signAt.Z)
	L:SetAttribute("ShoreZ", -146)

	note(string.format("island at %g,%g r %g; water at y %g; sign at %g,%g", ISL[1], ISL[2], ISL[3], WATER_Y, signAt.X, signAt.Z))
	return table.concat(report, " | ")
end

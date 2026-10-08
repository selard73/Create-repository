-- Boundary: invisible walls round the three areas (Forest, Village street, Domaine) with dressed edges, and the two
-- progression gates (bridge to Rue de Noisette, garden gate to Château de l'Acorn) that open per player once they have found
-- Need (10) squirrels in the area they are leaving. Rebuildable: destroys workspace.Boundary and its terrain mounds'
-- twin folder first. Run in edit mode: require(workspace.Boundary.PatchModule)()  (packed by village/make_patch.py)
return function()
	local T = workspace.Terrain
	local C = Color3.fromRGB
	local rng = Random.new(19)
	local old = workspace:FindFirstChild("Boundary"); if old then old:Destroy() end
	local B = Instance.new("Folder"); B.Name = "Boundary"; B:SetAttribute("Enabled", true); B:SetAttribute("Need", 10)
	local walls = Instance.new("Folder"); walls.Name = "Walls"; walls.Parent = B
	local gates = Instance.new("Folder"); gates.Name = "Gates"; gates.Parent = B
	local dress = Instance.new("Folder"); dress.Name = "Dressing"; dress.Parent = B
	B.Parent = workspace
	local report = {}

	-- ---------------------------------------------------------------- geometry ----
	-- the river (village kit "river", centred x 156 with the bridge at z -120): same curve as the village builder's riverAt()
	local RIVER_X, BRIDGE_Z, K = 156, -120, 2 * math.pi / 260
	local function smooth(t) t = math.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
	local function riverEnv(d) return smooth((math.abs(d) - 50) / 120) end
	local function riverWestBank(z)                      -- x of the river's west bank plus a little grass
		local d = z - BRIDGE_Z
		local centre = 45 * riverEnv(d) * math.cos(K * math.abs(d))
		local half = 9 + 3.5 * riverEnv(d) * math.cos(K * math.abs(d) + 1.7) + 1.5 * riverEnv(d)
		return RIVER_X + centre - half - 5
	end
	local F = {x0 = -130, z0 = -215, z1 = 25}            -- forest: west of the river
	local V = {x1 = 352, z0 = -205, z1 = 5}              -- village street: river to the garden fence; north edge takes in the river bend and the painter
	local D = {x0 = 352, x1 = 700, z0 = -250, z1 = 30}   -- the estate past the vegetable garden
	local BRIDGE_GAP = {-126.2, -113.8}                  -- the walkway onto the bridge (z)
	local GARDEN_GAP = {-123.2, -116.8}                  -- the garden's street gate (z), 6 studs + margin

	-- ---------------------------------------------------------------- invisible walls ----
	local WALL_H = 60
	local function wallBetween(ax, az, bx, bz)
		local dx, dz = bx - ax, bz - az
		local len = math.sqrt(dx * dx + dz * dz)
		if len < 0.2 then return end
		local mid = Vector3.new((ax + bx) / 2, WALL_H / 2 - 4, (az + bz) / 2)
		local p = Instance.new("Part"); p.Name = "Wall"; p.Anchored = true; p.CanCollide = true; p.CanQuery = false; p.CanTouch = false
		p.Transparency = 1; p.Locked = true; p.CastShadow = false
		p.Size = Vector3.new(len + 1.2, WALL_H, 1.2)
		p.CFrame = CFrame.lookAt(mid, mid + Vector3.new(-dz, 0, dx))
		p.Parent = walls
	end
	-- a polyline along z between the west bank and the forest, broken at the bridge
	local function dividerFV()
		local pts = {}
		for z = F.z0, F.z1, 5 do table.insert(pts, {riverWestBank(z), z}) end
		if pts[#pts][2] < F.z1 then table.insert(pts, {riverWestBank(F.z1), F.z1}) end
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local lo, hi = math.min(a[2], b[2]), math.max(a[2], b[2])
			if hi <= BRIDGE_GAP[1] or lo >= BRIDGE_GAP[2] then
				wallBetween(a[1], a[2], b[1], b[2])
			else                                                     -- the segment(s) touching the gap: keep the parts outside it
				if lo < BRIDGE_GAP[1] then wallBetween(a[1], a[2], riverWestBank(BRIDGE_GAP[1]), BRIDGE_GAP[1]) end
				if hi > BRIDGE_GAP[2] then wallBetween(riverWestBank(BRIDGE_GAP[2]), BRIDGE_GAP[2], b[1], b[2]) end
			end
		end
		return pts
	end
	local divPts = dividerFV()
	wallBetween(F.x0, F.z0, F.x0, F.z1)                                          -- forest west
	wallBetween(F.x0, F.z1, riverWestBank(F.z1), F.z1)                           -- forest north
	wallBetween(F.x0, F.z0, riverWestBank(F.z0), F.z0)                           -- forest south
	wallBetween(riverWestBank(V.z1), V.z1, V.x1, V.z1)                           -- village north
	wallBetween(riverWestBank(V.z0), V.z0, V.x1, V.z0)                           -- village south
	wallBetween(D.x0, D.z0, D.x0, GARDEN_GAP[1]); wallBetween(D.x0, GARDEN_GAP[2], D.x0, D.z1)   -- village | estate, gap at the garden gate
	wallBetween(D.x0, D.z1, D.x1, D.z1); wallBetween(D.x1, D.z1, D.x1, D.z0); wallBetween(D.x1, D.z0, D.x0, D.z0)
	table.insert(report, #walls:GetChildren() .. " wall segments")

	-- ---------------------------------------------------------------- helpers ----
	local GROUND = {workspace.Terrain}
	if workspace:FindFirstChild("Baseplate") then table.insert(GROUND, workspace.Baseplate) end
	if workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Ground") then table.insert(GROUND, workspace.Village.Ground) end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = GROUND
	local function groundAt(x, z)                      -- only real ground counts: terrain, the baseplate, the street slabs
		local r = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -200, 0), rp)
		return r and r.Position.Y or 0
	end
	local function part(parent, name, size, cf, col, shape)
		local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Locked = true
		p.Material = Enum.Material.SmoothPlastic; p.Color = col; p.Size = size; p.CFrame = cf; p.CastShadow = true
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	-- clone a prop model onto the ground at (x, z), turned by yaw and scaled: every part is transformed about the model's
	-- bounding-box centre (the village props' pivots sit far from their parts, so PivotTo/ScaleTo would fling them away)
	local function cloneAt(template, parent, x, z, yaw, scale)
		local m = template:Clone()
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("Attachment") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") then d:Destroy() end end
		local bb = m:GetBoundingBox()
		local c = bb.Position
		local rot = CFrame.Angles(0, yaw or 0, 0)
		scale = scale or 1
		for _, q in ipairs(m:GetDescendants()) do
			if q:IsA("BasePart") then
				local off = rot:VectorToWorldSpace((q.Position - c) * scale)
				q.Size = q.Size * scale
				q.CFrame = CFrame.new(c + off) * rot * q.CFrame.Rotation
				local sm = q:FindFirstChildOfClass("SpecialMesh"); if sm then sm.Scale = sm.Scale * scale end
			end
		end
		local bb2, sz = m:GetBoundingBox()
		local delta = Vector3.new(x, groundAt(x, z) + sz.Y / 2, z) - bb2.Position
		for _, q in ipairs(m:GetDescendants()) do if q:IsA("BasePart") then q.CFrame = q.CFrame + delta end end
		m.WorldPivot = CFrame.new(bb2.Position + delta)
		m.Parent = parent
		return m
	end
	-- walk a polyline of {x, z} points, calling fn(x, z, tx, tz) every `step` studs (tangent tx,tz)
	local function along(pts, step, fn)
		local carry = 0
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(dx * dx + dz * dz)
			if len > 0 then
				local tx, tz = dx / len, dz / len
				local s = carry
				while s <= len do fn(a[1] + tx * s, a[2] + tz * s, tx, tz); s += step end
				carry = s - len
			end
		end
	end

	-- ---------------------------------------------------------------- rolling hills beyond the walls (terrain) ----
	local nHills = 0
	-- the forest and street stand on the baseplate: any terrain west of the estate is ours, so clear last time's mounds
	T:FillBlock(CFrame.new(50, 0, -100), Vector3.new(600, 140, 520), Enum.Material.Air)
	local function hills(pts, step, side)                -- mounds whose foot starts just beyond the wall line, on the given side
		along(pts, step, function(x, z, tx, tz)
			local nx, nz = -tz * side, tx * side
			local r = rng:NextNumber(19, 27)
			local cx, cz = x + nx * (r + 1.5), z + nz * (r + 1.5)
			T:FillBall(Vector3.new(cx, -r + rng:NextNumber(8, 13), cz), r, Enum.Material.Grass)
			nHills += 1
		end)
	end
	hills({{F.x0, F.z0 - 10}, {F.x0, F.z1 + 10}}, 26, 1)                        -- west of the forest (line runs +z, left normal = -x)
	hills({{F.x0, F.z1}, {95, F.z1}}, 26, 1)                                     -- north of the forest (line runs +x, left normal = +z)
	hills({{F.x0, F.z0}, {115, F.z0}}, 26, -1)                                   -- south of the forest (-z)
	hills({{172, V.z1}, {V.x1 - 12, V.z1}}, 26, 1)                               -- north of the street (+z)
	hills({{172, V.z0}, {V.x1 - 12, V.z0}}, 26, -1)                              -- south of the street (-z)
	table.insert(report, nHills .. " hills")
	task.wait(0.6)                                          -- terrain collision catches up before anything is seated on the new slopes

	-- ---------------------------------------------------------------- dressing: tree lines and hedges ----
	local forestT = {}
	local forest = workspace:FindFirstChild("Forest")
	if forest then for _, m in ipairs(forest:GetChildren()) do if m:IsA("Model") then local n = m.Name:gsub("%d+$", "") if not forestT[n] then forestT[n] = m end end end end
	local PINES = {}
	for _, n in ipairs({"pine_tall", "pine_mid", "pine_squat", "round_tree", "pine_tall", "pine_mid"}) do if forestT[n] then table.insert(PINES, forestT[n]) end end
	local villageT = {}
	for _, m in ipairs(workspace.Village.Props:GetChildren()) do if m:IsA("Model") then local n = m.Name:gsub("%d+$", "") if not villageT[n] then villageT[n] = m end end end
	local nTrees, nHedges = 0, 0
	-- THE STREET'S PLANE TREES stand on the river banks too, one on the forest side (136,-164) with a crown 18 across; the
	-- river-bank pines are kept out of them (Shannon: "this tree by the river should not be sticking through the other tree")
	local bigTrees = {}
	for _, m in ipairs(workspace.Village.Props:GetChildren()) do
		if m:IsA("Model") and m.Name:gsub("%d+$", "") == "plane_tree" then local p = m:GetBoundingBox().Position; table.insert(bigTrees, Vector2.new(p.X, p.Z)) end
	end
	local function inBigTree(x, z) for _, b in ipairs(bigTrees) do if (b - Vector2.new(x, z)).Magnitude < 10.5 then return true end end return false end
	local function treeLine(pts, step, inset)                -- pines centred on the line, jittered, skipping the bridge approach
		if #PINES == 0 then return end
		along(pts, step, function(x, z, tx, tz)
			local nx, nz = -tz, tx                              -- normal (which side is "inside" is set by the caller's inset sign)
			local j = rng:NextNumber(-2.5, 2.5)
			local px, pz = x + nx * (inset + j), z + nz * (inset + j)
			if math.abs(pz - BRIDGE_Z) < 14 and px > 120 then return end
			local tpl, yaw, sc = PINES[rng:NextInteger(1, #PINES)], rng:NextNumber(0, 6.28), rng:NextNumber(0.85, 1.3)
			if inBigTree(px, pz) then return end               -- drawn first, so the rest of the row comes out as it always did
			cloneAt(tpl, dress, px, pz, yaw, sc)
			nTrees += 1
		end)
	end
	-- forest: west, north, south walls and the river side (trees stand on the wall line, half in, half out)
	treeLine({{F.x0, F.z0}, {F.x0, F.z1}}, 8, 0)
	treeLine({{F.x0, F.z1}, {riverWestBank(F.z1), F.z1}}, 8, 0)
	treeLine({{F.x0, F.z0}, {riverWestBank(F.z0), F.z0}}, 8, 0)
	treeLine(divPts, 8.5, 3)                                                   -- on the forest side of the bank line
	-- village: hedges with plane trees along the north and south edges and the estate fence line
	local function hedgeLine(pts, step, inset)
		local hedge, plane = villageT.hedge, villageT.plane_tree
		if not hedge then return end
		local k = 0
		along(pts, step, function(x, z, tx, tz)
			local nx, nz = -tz, tx
			local px, pz = x + nx * inset, z + nz * inset
			k += 1
			local yaw = math.atan2(-tz, tx)
			cloneAt(hedge, dress, px, pz, yaw + rng:NextNumber(-0.15, 0.15), rng:NextNumber(1.25, 1.55))
			nHedges += 1
			if plane and k % 5 == 3 then cloneAt(plane, dress, px + nx * 3, pz + nz * 3, rng:NextNumber(0, 6.28), rng:NextNumber(1.5, 1.9)) nTrees += 1 end
		end)
	end
	hedgeLine({{170, V.z1}, {V.x1 - 3, V.z1}}, 6, -3)                          -- north edge (inside, -z side), clear of the river
	hedgeLine({{riverWestBank(V.z0) + 24, V.z0}, {V.x1 - 3, V.z0}}, 6, 3)      -- south edge (inside, +z side)
	hedgeLine({{V.x1 - 2, V.z0 + 2}, {V.x1 - 2, -143}}, 6, 0)                   -- fence line, south of the garden
	hedgeLine({{V.x1 - 2, -97}, {V.x1 - 2, V.z1 - 2}}, 6, 0)                    -- fence line, north of the garden
	table.insert(report, nTrees .. " trees, " .. nHedges .. " hedges")

	-- ---------------------------------------------------------------- the gates ----
	local WOOD, WHITE = C(150, 110, 70), C(242, 242, 236)
	local function sign(parent, at, needMap, toName)
		local post = part(parent, "SignPost", Vector3.new(0.5, 0.5, 0.5), CFrame.new(at), WOOD)
		post.Transparency = 1
		local gui = Instance.new("BillboardGui"); gui.Name = "Sign"; gui.Size = UDim2.new(0, 380, 0, 124); gui.StudsOffset = Vector3.new(0, 4.6, 0)
		gui.MaxDistance = 80; gui.AlwaysOnTop = false; gui.LightInfluence = 0.3; gui.Parent = post
		local frame = Instance.new("Frame"); frame.Name = "Panel"; frame.Size = UDim2.fromScale(1, 1); frame.BackgroundColor3 = C(38, 30, 52); frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0; frame.Parent = gui
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 14); corner.Parent = frame
		local stroke = Instance.new("UIStroke"); stroke.Name = "Edge"; stroke.Color = C(240, 200, 90); stroke.Thickness = 2; stroke.Transparency = 1; stroke.Parent = frame
		local lbl = Instance.new("TextLabel"); lbl.Name = "SignText"; lbl.Size = UDim2.new(1, -16, 1, -10); lbl.Position = UDim2.new(0, 8, 0, 5); lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne; lbl.TextSize = 20; lbl.TextWrapped = true; lbl.RichText = true; lbl.TextColor3 = C(255, 246, 220); lbl.TextTransparency = 1; lbl.Text = ""; lbl.Parent = frame
		return post
	end
	local function farmGate(name, x, zLo, zHi, hingeAtHi, needMap, toName, openAngle, picket)
		local g = Instance.new("Model"); g.Name = name; g.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		g:SetAttribute("NeedMap", needMap); g:SetAttribute("ToName", toName); g:SetAttribute("OpenAngle", openAngle)
		local gy = groundAt(x, (zLo + zHi) / 2)
		local width = zHi - zLo
		local block = part(g, "Block", Vector3.new(1.4, 30, width + 0.6), CFrame.new(x, gy + 15, (zLo + zHi) / 2), WOOD)
		block.Transparency = 1; block.CanCollide = true; block.CanQuery = true
		local postH = picket and 3.6 or 5.2
		local col = picket and WHITE or WOOD
		for _, z in ipairs({zLo - 0.35, zHi + 0.35}) do
			part(g, "Post", Vector3.new(0.7, postH, 0.7), CFrame.new(x, gy + postH / 2, z), col)
			part(g, "Post", Vector3.new(0.9, 0.3, 0.9), CFrame.new(x, gy + postH + 0.1, z), col)
		end
		-- the leaf, built lying from the hinge post toward the other post, then pivoted at the hinge
		local leaf = Instance.new("Model"); leaf.Name = "Leaf"
		local hz = hingeAtHi and zHi or zLo
		local dir = hingeAtHi and -1 or 1                                     -- leaf runs from the hinge toward the other post
		local hinge = CFrame.new(x, gy, hz)
		leaf:SetAttribute("Dir", dir)
		local L = width - 0.2
		if picket then
			for _, y in ipairs({0.9, 2.2}) do part(leaf, "Rail", Vector3.new(0.12, 0.28, L), CFrame.new(x, gy + y, hz + dir * L / 2), WHITE) end
			local n = math.max(3, math.floor(L / 0.62))
			for i = 0, n - 1 do
				local z = hz + dir * (0.35 + i * (L - 0.7) / (n - 1))
				part(leaf, "Picket", Vector3.new(0.22, 2.8, 0.36), CFrame.new(x + 0.14, gy + 1.5, z), WHITE)
				part(leaf, "Picket", Vector3.new(0.22, 0.36, 0.36), CFrame.new(x + 0.14, gy + 3.05, z) * CFrame.Angles(0, 0, math.pi / 4), WHITE)
			end
		else
			for _, y in ipairs({0.7, 1.75, 2.8, 3.85}) do part(leaf, "Bar", Vector3.new(0.28, 0.32, L), CFrame.new(x, gy + y, hz + dir * L / 2), WOOD) end
			for _, f in ipairs({0.04, 0.5, 0.96}) do part(leaf, "Upright", Vector3.new(0.34, 4.0, 0.34), CFrame.new(x + 0.02, gy + 2.25, hz + dir * L * f), WOOD) end
			local dl = math.sqrt(L * L * 0.25 + 3.2 * 3.2)
			part(leaf, "Brace", Vector3.new(0.24, 0.28, dl), CFrame.new(x - 0.2, gy + 2.25, hz + dir * L * 0.25) * CFrame.Angles(math.atan2(3.2, L * 0.5) * dir, 0, 0), WOOD)
		end
		for _, p in ipairs(leaf:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
		leaf.WorldPivot = hinge
		leaf.Parent = g
		g:SetAttribute("Hinge", hinge)
		sign(g, Vector3.new(x, gy + postH + 1.6, (zLo + zHi) / 2), needMap, toName)
		g.Parent = gates
		return g
	end
	farmGate("VillageGate", 141.6, BRIDGE_GAP[1], BRIDGE_GAP[2], true, "forest", "Rue de Noisette", 1.75, false):SetAttribute("TitleName", "Squirrel Friend")
	farmGate("DomaineGate", D.x0, GARDEN_GAP[1], GARDEN_GAP[2], false, "village", "Château de l'Acorn", 1.75, true):SetAttribute("TitleName", "Squirrel Whisperer")
	-- the Domaine builder's own gate leaf on the street side is replaced by ours
	local dom = workspace:FindFirstChild("Domaine")
	if dom and dom:FindFirstChild("Props") then
		for _, m in ipairs(dom.Props:GetChildren()) do
			if m.Name == "picket_gate" then local bb = m:GetBoundingBox() if math.abs(bb.Position.X - D.x0) < 3 and math.abs(bb.Position.Z + 120) < 4 then m:Destroy() end end
		end
	end
	table.insert(report, "2 gates")
	local zones = workspace:FindFirstChild("Zones")
	local vz = zones and zones:FindFirstChild("village")
	if vz and vz:IsA("BasePart") then
		vz.Size = Vector3.new(vz.Size.X, vz.Size.Y, V.z1 + 5 - V.z0); vz.Position = Vector3.new(vz.Position.X, vz.Position.Y, (V.z0 + V.z1 + 5) / 2)
	end

	-- ---------------------------------------------------------------- signposts ----
	-- a fingerpost: dark post, cream board with an arrow tip along +X (yaw turns it toward the destination), bold text both sides
	local BOARD, INK, POSTC = C(244, 232, 204), C(62, 40, 26), C(96, 66, 44)
	local function signpost(name, x, z, yaw, text)
		local m = Instance.new("Model"); m.Name = name
		local gy = groundAt(x, z)
		part(m, "Post", Vector3.new(0.6, 5.6, 0.6), CFrame.new(x, gy + 2.8, z), POSTC)
		part(m, "Cap", Vector3.new(0.9, 0.3, 0.9), CFrame.new(x, gy + 5.75, z), POSTC)
		local Lb, H, Tk, tip = 8.0, 2.2, 0.32, 1.5
		local base = CFrame.new(x, gy + 4.3, z) * CFrame.Angles(0, yaw, 0)
		local board = part(m, "Board", Vector3.new(Lb, H, Tk), base * CFrame.new(Lb / 2 + 0.35, 0, 0), BOARD)
		local up = Instance.new("WedgePart"); up.Name = "Tip"; up.Anchored = true; up.CanCollide = false; up.CanQuery = false; up.Locked = true
		up.Material = Enum.Material.SmoothPlastic; up.Color = BOARD; up.Size = Vector3.new(Tk, H / 2, tip)
		up.CFrame = base * CFrame.new(Lb + 0.35 + tip / 2, H / 4, 0) * CFrame.Angles(0, -math.pi / 2, 0); up.Parent = m
		local lo = up:Clone(); lo.CFrame = base * CFrame.new(Lb + 0.35 + tip / 2, -H / 4, 0) * CFrame.Angles(math.pi, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0); lo.Parent = m
		for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
			local gui = Instance.new("SurfaceGui"); gui.Face = face; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 50; gui.LightInfluence = 0.5; gui.Parent = board
			local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -70, 1, -14); l.Position = UDim2.new(0, 35, 0, 7); l.BackgroundTransparency = 1
			l.Text = text; l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.TextWrapped = true; l.TextColor3 = INK; l.Parent = gui
		end
		m.Parent = gates
		return m
	end
	signpost("SignForest", 9, -7, math.pi / 2, "The Great Acorn Forest")                                 -- by the spawn, pointing south into the trees
	signpost("SignVillage", 133, -128.5, 0, "Rue de Noisette")   -- beside the walkway, pointing over the bridge
	signpost("SignDomaine", 344.5, -109.5, 0, "Château de l'Acorn")                                 -- at the street end, pointing at the garden gate
	-- the street-end bollard rows (3 posts 4.4 apart, one mesh): precise collision so the gaps are real, and the row slides
	-- 2.2 studs so the street axis runs between two posts instead of into the middle one (done once: attribute Shifted)
	local nBoll = 0
	for _, mm in ipairs(workspace.Village.Props:GetChildren()) do
		if mm.Name:find("bollards") then
			for _, q in ipairs(mm:GetDescendants()) do if q:IsA("MeshPart") then q.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition; nBoll += 1 end end
			if not mm:GetAttribute("Shifted") then
				for _, q in ipairs(mm:GetDescendants()) do if q:IsA("BasePart") then q.CFrame = q.CFrame + Vector3.new(0, 0, 2.2) end end
				mm:SetAttribute("Shifted", true)
			end
		end
	end
	table.insert(report, "3 signposts, " .. nBoll .. " bollard meshes given precise collision")

	-- ---------------------------------------------------------------- scripts ----
	local SERVER = [==[
-- GateServer: the safety net behind the client-side gates. Each area needs Need squirrels found in the area before it;
-- a player standing in an area they have not unlocked is walked back to the gate outside it.
local Players = game:GetService("Players")
local boundary = script.Parent
local NEED = boundary:GetAttribute("Need") or 10
local AREAS = {
	{id = "domaine", x0 = 353, x1 = 700, z0 = -250, z1 = 30, needMap = "village", back = CFrame.new(342, 3.5, -120) * CFrame.Angles(0, math.pi / 2, 0), name = "Château de l'Acorn", prev = "Rue de Noisette"},
	{id = "village", x0 = 150, x1 = 353, z0 = -205, z1 = 5, needMap = "forest", back = CFrame.new(129, 3.5, -120) * CFrame.Angles(0, math.pi / 2, 0), name = "Rue de Noisette", prev = "The Great Acorn Forest"},
}
while true do
	task.wait(1)
	if boundary:GetAttribute("Enabled") then
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and not player:GetAttribute("GateBypass") then
				local p = root.Position
				for _, a in ipairs(AREAS) do
					if p.X >= a.x0 and p.X <= a.x1 and p.Z >= a.z0 and p.Z <= a.z1 then
						local n = player:GetAttribute("Found_" .. a.needMap)
						if n ~= nil and n < NEED then
							local seat = char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").SeatPart
							if seat then char:FindFirstChildOfClass("Humanoid").Sit = false; task.wait(0.2) end
							char:PivotTo(a.back)
							player:SetAttribute("GateBounceText", string.format("Find %d squirrels in %s before going on to %s  (%d / %d so far)", NEED, a.prev, a.name, n, NEED))
							player:SetAttribute("GateBounce", os.clock())
						end
						break
					end
				end
			end
		end
	end
end
]==]
	local CLIENT = [==[
-- GateClient: opens the gates for this player once they have found Need squirrels in the area they are leaving
-- (the block turns walk-through and the leaf swings), keeps the gate signs up to date and shows the bounce message.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local boundary = script.Parent
local NEED = boundary:GetAttribute("Need") or 10
local NAMES = {forest = "The Great Acorn Forest", village = "Rue de Noisette", domaine = "Château de l'Acorn"}
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local TOTAL = {}
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1 end
local function swing(leaf, hinge, from, to, dur)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / dur, 0, 1); a = a * a * (3 - 2 * a)
		if leaf.Parent then leaf:PivotTo(hinge * CFrame.Angles(0, from + (to - from) * a, 0)) end
		if a >= 1 then conn:Disconnect() end
	end)
end
local function setupGate(g)
	local needMap = g:GetAttribute("NeedMap")
	if not needMap then return end
	local toName = g:GetAttribute("ToName") or "the next area"
	local openAngle = g:GetAttribute("OpenAngle") or 1.75
	local hinge = g:GetAttribute("Hinge")
	local block = g:WaitForChild("Block", 10)
	local leaf = g:FindFirstChild("Leaf")
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
	local NL = string.char(10)
	local function fancy(t) return '<font face="Antique" size="34" color="#FFD65A"><b>' .. t .. '</b></font>' end
	local function refresh()
		local n = player:GetAttribute("Found_" .. needMap) or 0
		local ok = n >= NEED
		if label then
			if ok then
				local total, titleName = TOTAL[needMap] or 0, g:GetAttribute("TitleName") or "Squirrel Friend"
				local second = (total > 0 and n >= total) and ("Well done, " .. fancy(titleName) .. "!") or (string.format("Find all %d here to become a", total) .. NL .. fancy(titleName))
				label.Text = "The way to " .. toName .. " is open!" .. NL .. second
			else label.Text = string.format("Find %d squirrels in %s to open this gate", NEED, NAMES[needMap] or needMap) .. NL .. string.format("%d / %d found so far", n, NEED) end
		end
		if ok ~= open then
			local first = (open == nil)
			open = ok
			if block then block.CanCollide = not ok end
			if leaf and hinge then
				if first then leaf:PivotTo(hinge * CFrame.Angles(0, ok and openAngle or 0, 0))
				else swing(leaf, hinge, ok and 0 or openAngle, ok and openAngle or 0, 1.3) end
			end
			if ok and not first and block then
				local s = Instance.new("Sound"); s.SoundId = "rbxassetid://1845415163"; s.Volume = 0.45; s.RollOffMaxDistance = 60; s.Parent = block; s:Play(); Debris:AddItem(s, 5)
			end
		end
	end
	player:GetAttributeChangedSignal("Found_" .. needMap):Connect(refresh)
	refresh()
	-- the note floats above the gate: it appears as you come near, fades a few seconds later, and returns next time
	if panel then
		local near, shownAt = false, nil
		task.spawn(function()
			while g.Parent do
				task.wait(0.25)
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local ref = block and block.Position or g:GetPivot().Position
				local d = root and (root.Position - ref).Magnitude or 1e9
				if not near and d < 30 then
					near = true; shownAt = os.clock(); fade(0, 0.4)
				elseif near and d > 42 then
					near = false; shownAt = nil; fade(1, 0.6)
				end
				if near and shownAt and os.clock() - shownAt > 6 then shownAt = nil; fade(1, 1.8) end
			end
		end)
	end
end
local gates = boundary:WaitForChild("Gates")
for _, g in ipairs(gates:GetChildren()) do task.spawn(setupGate, g) end
gates.ChildAdded:Connect(function(g) task.defer(setupGate, g) end)
-- the bounce message (the server walked this player back out of a locked area)
local gui = Instance.new("ScreenGui"); gui.Name = "GateMessage"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = player:WaitForChild("PlayerGui")
local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0, 560, 0, 64); lbl.Position = UDim2.new(0.5, -280, 0.2, 0); lbl.BackgroundColor3 = Color3.fromRGB(38, 30, 52)
lbl.BackgroundTransparency = 0.15; lbl.TextColor3 = Color3.fromRGB(255, 246, 220); lbl.Font = Enum.Font.FredokaOne; lbl.TextSize = 22; lbl.TextWrapped = true; lbl.Visible = false; lbl.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 14); corner.Parent = lbl
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(240, 200, 90); stroke.Thickness = 2; stroke.Parent = lbl
local shownAt = 0
player:GetAttributeChangedSignal("GateBounce"):Connect(function()
	lbl.Text = player:GetAttribute("GateBounceText") or ""
	lbl.Visible = true
	local t = os.clock(); shownAt = t
	task.delay(4, function() if shownAt == t then lbl.Visible = false end end)
end)
]==]
	local function install(name, ctx, src)
		local s = Instance.new("Script"); s.Name = name; s.RunContext = ctx; s.Source = src; s.Parent = B
	end
	install("GateServer", Enum.RunContext.Server, SERVER)
	install("GateClient", Enum.RunContext.Client, CLIENT)
	print("Boundary: " .. table.concat(report, ", "))
end

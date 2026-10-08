-- ScatterForest: the forest floor was mostly bare grass, so this fills the open ground with more of the same kit the
-- forest was built from - pines, round trees, bushes, stumps, fallen and hollow logs, rocks and mushrooms - leaving a
-- clearing round the spawn dais and a little room round every squirrel so they stay findable.
-- Everything it adds is grounded by its own bounding box (lowest corner just under the grass), never by its pivot,
-- because the kit's pivots sit well off the geometry and dropping by pivot leaves things floating.
-- Re-runnable: it deletes anything it added last time (attribute Scatter) before it starts.
-- Run in edit mode: require(workspace.Scatter.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local DRY = opts.dry == true
	local F = workspace:WaitForChild("Forest")
	local kit = workspace:WaitForChild("ForestKit")
	local rng = Random.new(20260922)

	-- ---------------------------------------------------------------- what to plant ----
	-- w is how often it is picked, r is the footprint radius kept clear around it
	local TEMPLATES = {
		{name = "pine_tall",    w = 20, r = 3.6, sink = 0.30},
		{name = "pine_mid",     w = 18, r = 3.5, sink = 0.30},
		{name = "pine_squat",   w = 12, r = 3.6, sink = 0.30},
		{name = "round_tree",   w = 14, r = 4.4, sink = 0.30},
		{name = "bush_big",     w = 8,  r = 2.9, sink = 0.25},
		{name = "bush_small",   w = 7,  r = 1.6, sink = 0.20},
		{name = "stump",        w = 6,  r = 2.6, sink = 0.25},
		{name = "log_fallen",   w = 4,  r = 5.2, sink = 0.22},
		{name = "log_hollow",   w = 3,  r = 4.2, sink = 0.22},
		{name = "rock_big",     w = 3,  r = 3.1, sink = 0.35},
		{name = "rock_cluster", w = 4,  r = 2.6, sink = 0.30},
		{name = "mushrooms",    w = 7,  r = 2.0, sink = 0.15},
	}
	local total = 0
	for _, t in ipairs(TEMPLATES) do
		t.model = kit:FindFirstChild(t.name)
		assert(t.model, "ScatterForest: ForestKit has no " .. t.name)
		total += t.w
		t.acc = total
	end
	local function pick()
		local n = rng:NextNumber() * total
		for _, t in ipairs(TEMPLATES) do if n <= t.acc then return t end end
		return TEMPLATES[1]
	end

	-- ---------------------------------------------------------------- clear last time's ----
	local removed = 0
	for _, c in ipairs(F:GetChildren()) do
		if c:GetAttribute("Scatter") then c:Destroy(); removed += 1 end
	end

	-- ---------------------------------------------------------------- what is already there ----
	local GAP = opts.gap or 3.0                                   -- clear walking room between footprints
	local taken = {}                                              -- {x, z, r}
	local function claim(x, z, r) table.insert(taken, {x = x, z = z, r = r}) end
	local function free(x, z, r)
		for _, o in ipairs(taken) do
			local dx, dz = x - o.x, z - o.z
			if dx * dx + dz * dz < (r + o.r + GAP) ^ 2 then return false end
		end
		return true
	end
	local function boxOf(m)
		local mn, mx
		for _, p in ipairs(m:IsA("BasePart") and {m} or m:GetDescendants()) do
			if p:IsA("BasePart") then
				for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
					local v = (p.CFrame * CFrame.new(p.Size.X / 2 * sx, p.Size.Y / 2 * sy, p.Size.Z / 2 * sz)).Position
					mn = mn and Vector3.new(math.min(mn.X, v.X), math.min(mn.Y, v.Y), math.min(mn.Z, v.Z)) or v
					mx = mx and Vector3.new(math.max(mx.X, v.X), math.max(mx.Y, v.Y), math.max(mx.Z, v.Z)) or v
				end end end
			end
		end
		return mn, mx
	end
	for _, c in ipairs(F:GetChildren()) do                        -- the trees and rocks already planted
		if c:IsA("Model") or c:IsA("BasePart") then
			local mn, mx = boxOf(c)
			if mn then claim((mn.X + mx.X) / 2, (mn.Z + mx.Z) / 2, math.max(mx.X - mn.X, mx.Z - mn.Z) / 2) end
		end
	end
	local DAIS = workspace:FindFirstChild("SpawnDais_forest")
	if DAIS then
		local mn, mx = boxOf(DAIS)
		-- the clearing Shannon circled. A prop's own radius and the walking gap add to this, so the bare ring ends
		-- up about 20 studs across from the middle of the dais - a clearing, not a field.
		claim((mn.X + mx.X) / 2, (mn.Z + mx.Z) / 2, 13)
	end
	for _, o in ipairs(workspace:GetChildren()) do                -- every squirrel keeps room to be seen and touched
		if o:IsA("Model") and (o.Name:sub(-6) == "_color" or o.Name:sub(-5) == "_gray") then
			local p = o:GetPivot().Position
			if p.X < 145 then claim(p.X, p.Z, 9) end
		end
	end
	local HS = F:FindFirstChild("HidingSpots")
	if HS then for _, h in ipairs(HS:GetDescendants()) do         -- the hiding spots are Attachments, not parts
		local p = h:IsA("Attachment") and h.WorldPosition or (h:IsA("BasePart") and h.Position)
		if p then claim(p.X, p.Z, 8) end
	end end
	local signs = workspace:FindFirstChild("Boundary") and workspace.Boundary:FindFirstChild("Gates")
	if signs then for _, g in ipairs(signs:GetChildren()) do
		local p = g:IsA("BasePart") and g.Position or g:GetPivot().Position
		if p.X < 150 then claim(p.X, p.Z, 9) end
	end end

	-- ---------------------------------------------------------------- the ground ----
	-- only the forest's own flat baseplate counts: that keeps the scatter off the boundary hills, the river banks,
	-- the bridge and the village, without having to describe any of their shapes
	local bp = workspace:FindFirstChild("Baseplate")
	assert(bp, "ScatterForest: no Baseplate")
	local rpG = RaycastParams.new(); rpG.FilterType = Enum.RaycastFilterType.Include; rpG.FilterDescendantsInstances = {bp}
	local rpAny = RaycastParams.new(); rpAny.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {}
	for _, b in ipairs(workspace:GetChildren()) do
		if b.Name == "Boundary" and b:FindFirstChild("Walls") then table.insert(skip, b.Walls) end
	end
	rpAny.FilterDescendantsInstances = skip
	-- Plant ONLY where the bare baseplate is the very top surface. Asking "is the baseplate under here, and is
	-- anything sitting more than a stud above it" was not enough: the cobbled path at the bridge is a thin slab, so it
	-- slipped under that test and a bush grew out of the pavement. The strict version also keeps the scatter off the
	-- bridge, the banks, the hills and anything already standing there, with no list of exceptions to maintain.
	local function bare(x, z)
		local a = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -200, 0), rpAny)
		if not a or a.Instance ~= bp then return nil end
		return a.Position.Y
	end
	local function groundAt(x, z, r)                              -- the whole footprint has to be on bare ground, not
		local y = bare(x, z)                                      -- just the middle, or a bush overhangs the path
		if not y then return nil end
		for _, o in ipairs({{r, 0}, {-r, 0}, {0, r}, {0, -r}, {r * 0.7, r * 0.7}, {-r * 0.7, -r * 0.7}}) do
			if not bare(x + o[1], z + o[2]) then return nil end
		end
		return y
	end

	-- ---------------------------------------------------------------- scatter ----
	local X0, X1, Z0, Z1 = -126, 132, -211, 21
	local STEP = opts.step or 7
	local placed, tried, ground = 0, 0, 0
	local DBG = {}
	for gx = X0, X1, STEP do
		for gz = Z0, Z1, STEP do
			local x = gx + rng:NextNumber(-STEP * 0.42, STEP * 0.42)
			local z = gz + rng:NextNumber(-STEP * 0.42, STEP * 0.42)
			tried += 1
			local t = pick()
			local dbg = opts.debugAt and (x - opts.debugAt.X) ^ 2 + (z - opts.debugAt.Z) ^ 2 < 45 * 45
			if not free(x, z, t.r) then
				if dbg then table.insert(DBG, string.format("%.0f,%.0f %s BLOCKED", x, z, t.name)) end
			else
				local y = groundAt(x, z, t.r)
				if not y then
					if dbg then table.insert(DBG, string.format("%.0f,%.0f %s NOGROUND", x, z, t.name)) end
				else
					if dbg then table.insert(DBG, string.format("%.0f,%.0f %s ok", x, z, t.name)) end
					ground += 1
					if DRY then
						placed += 1
						claim(x, z, t.r)
					else
						local m = t.model:Clone()
						m.Name = t.name .. "_s" .. placed
						m:SetAttribute("Scatter", true)
						-- the ForestKit models are hidden stencils: transparency 1, no collision, not even raycastable.
						-- A clone has to be turned back into a real prop or you plant a forest of ghosts.
						for _, q in ipairs(m:GetDescendants()) do
							if q:IsA("BasePart") then
								q.Transparency = 0; q.CanQuery = true; q.CanCollide = true; q.CanTouch = false; q.Anchored = true
							end
						end
						m.Parent = F
						-- these kit models carry pivots a long way off their own geometry (a log's pivot sits 84 studs
						-- from the log), so turn first and then move by the BOUNDING BOX, never by the pivot
						m:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
						local mn, mx = boxOf(m)
						m:PivotTo(m:GetPivot() + Vector3.new(x - (mn.X + mx.X) / 2, y - t.sink - mn.Y, z - (mn.Z + mx.Z) / 2))
						placed += 1
						claim(x, z, t.r)
					end
				end
			end
		end
	end
	if opts.debugAt then print("@@ DBG " .. table.concat(DBG, " | ")) end
	print(string.format("ScatterForest: %s %d props (%d cells tried, %d had open ground, %d cleared out first)", DRY and "would plant" or "planted", placed, tried, ground, removed))
end

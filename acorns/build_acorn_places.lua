-- AcornPlaces: the hiding places, named rather than derived.
--
-- Two goes at finding these by algorithm both missed. Scoring flat surfaces you could jump to produced acorns
-- perched on rocks at tidy intervals; scoring concealment and taking the best first produced a heap of them round
-- the rim of the spawn dais, which is the most obvious spot in the game. The problem is not the scoring - it is
-- that "a good hiding place" is a judgement about a world someone built by hand, and a raycast has no opinion
-- about it. So this takes Shannon's list instead:
--
--     one among the sunflowers          one on a table                 a few through the vineyard
--     one in the chicken pen            a bunch in the lavender field  one on the windmill steps
--     some under the trees by the house plenty around the outskirts
--
-- Each entry names a landmark, how many acorns belong there, and how far from it they may stray. The spots are
-- still chosen by concealment WITHIN that area - nestled against something, on the ground, never on top - so the
-- list decides WHERE and the scoring decides exactly which nook.
-- Run in edit mode: require(workspace.AcornPlaces.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 424242)

	-- match is a list of lowercase name fragments; radius is how far an acorn may sit from the landmark;
	-- gap is the minimum between two acorns of the same place, so "a bunch" is scattered, not stacked
	local PLACES = {
		{label = "the sunflowers",    match = {"sunflower"},                                  n = 2,  radius = 9,  gap = 6},
		{label = "the chicken pen",   match = {"henfence", "hencollider", "coop"},            n = 2,  radius = 8,  gap = 5},
		{label = "the vineyard",      match = {"vine_row", "vine "},                          n = 5,  radius = 7,  gap = 16},
		{label = "the windmill",      match = {"windmill"},                                   n = 1,  radius = 9,  gap = 5},
		{label = "the lavender field",match = {"lavender"},                                   n = 8,  radius = 11, gap = 9},
		{label = "a table",           match = {"cafe_table", "table_setting", "long_table", "tasting_table"},
		                                                                                      n = 1,  radius = 4,  gap = 5},
		{label = "trees by the house",match = {"townhouse"},                                  n = 3,  radius = 14, gap = 18},
		-- The forest is the biggest map and had four acorns in it, every one out at the edge. It is also the best
		-- hiding ground there is - each pine, bush, stump, log and mushroom clump is somewhere worth looking.
		-- Wide spacing, because scattered through the whole wood is the point; clustered is not.
		{label = "the forest floor",  match = {"pine_", "round_tree", "bush_", "mushroom", "stump", "log_", "rock_"},
		                              section = "forest",                                     n = 26, radius = 7,  gap = 24},
		{label = "the outskirts",     outskirts = true,                                       n = 12, radius = 0,  gap = 34},
	}

	local skipRoot = {}
	for _, n in ipairs({"Boundary", "MapMusic", "SquirrelScripts", "HudBarUI", "Terrain", "Camera", "Baseplate",
		"AcornSpots", "AcornSystem", "Acorns", "AcornPreview", "AcornPlaces"}) do skipRoot[n] = true end

	-- The kits are invisible stencils parked off to one side. They carry the same names as the real props, so
	-- counting them made the sunflowers appear to stretch from x0 to x560. Anything inside one is not in the world.
	local function isTemplate(o)
		while o and o ~= workspace do
			local n = o.Name:lower()
			if n:find("kit") or n:find("template") or n:find("storage") then return true end
			o = o.Parent
		end
		return false
	end
	local function isSquirrel(o)
		while o and o ~= workspace do
			local n = o.Name
			if n:sub(-6) == "_color" or n:sub(-5) == "_gray" or n:lower():find("squirrel") then return true end
			o = o.Parent
		end
		return false
	end
	-- a place may be locked to one section, so the forest floor cannot quietly harvest the Chateau's rocks
	local function inSection(x, want)
		if not want then return true end
		if want == "forest" then return x < 141 end
		if want == "village" then return x >= 171 and x < 351 end
		if want == "domaine" then return x >= 389 end
		return true
	end
	local function isNoGo(n)
		n = n:lower()
		return n:find("spawn") ~= nil or n:find("dais") ~= nil or n:find("gate") ~= nil
	end

	local function centreOf(o)
		local mn, mx
		local parts = o:IsA("BasePart") and {o} or {}
		if not o:IsA("BasePart") then
			for _, q in ipairs(o:GetDescendants()) do if q:IsA("BasePart") then table.insert(parts, q) end end
		end
		if #parts == 0 or #parts > 400 then return nil end
		for _, q in ipairs(parts) do
			for sx = -1, 1, 2 do for sz = -1, 1, 2 do
				local v = (q.CFrame * CFrame.new(q.Size.X / 2 * sx, 0, q.Size.Z / 2 * sz)).Position
				mn = mn and Vector3.new(math.min(mn.X, v.X), 0, math.min(mn.Z, v.Z)) or Vector3.new(v.X, 0, v.Z)
				mx = mx and Vector3.new(math.max(mx.X, v.X), 0, math.max(mx.Z, v.Z)) or Vector3.new(v.X, 0, v.Z)
			end end
		end
		if not mn then return nil end
		local c = (mn + mx) / 2
		return Vector3.new(c.X, parts[1].Position.Y, c.Z)
	end


	-- ---------------------------------------------------------------- the landmarks, as they really are ----
	local found = {}
	for _, p in ipairs(PLACES) do found[p.label] = {} end
	local everything = {}
	for _, root in ipairs(workspace:GetChildren()) do
		if not skipRoot[root.Name] then
			for _, o in ipairs(root:GetDescendants()) do
				if (o:IsA("Model") or o:IsA("BasePart")) and not isTemplate(o) and not isSquirrel(o)
				   and not isNoGo(o.Name) then
					-- BOUNDING BOX, never the pivot. A model's pivot in this project sits wherever the kit left
					-- it: the bridge reports x310 when its timbers are at x141..171, and reading the windmill's
					-- pivot put an acorn at x862, right outside the map.
					local pos = centreOf(o)
					if pos then
						table.insert(everything, pos)
						local low = o.Name:lower()
						for _, p in ipairs(PLACES) do
							if p.match and inSection(pos.X, p.section) then
								for _, frag in ipairs(p.match) do
									if low:find(frag, 1, true) then table.insert(found[p.label], pos) break end
								end
							end
						end
					end
				end
			end
		end
	end

	-- the outskirts: the far edge of the built world, not a place with a name
	local minx, maxx, minz, maxz = math.huge, -math.huge, math.huge, -math.huge
	for _, v in ipairs(everything) do
		if v.X > -200 and v.X < 760 and v.Z > -320 and v.Z < 120 then      -- ignore strays parked far away
			minx = math.min(minx, v.X); maxx = math.max(maxx, v.X)
			minz = math.min(minz, v.Z); maxz = math.max(maxz, v.Z)
		end
	end

	-- ---------------------------------------------------------------- concealment, within the named area ----
	local op = OverlapParams.new()
	local function assess(x, z)
		-- LOOK PAST WHAT IS OVERHEAD. A ray dropped from the sky hits the first thing in its way, and beside the
		-- mime that is a plane tree's canopy twenty-five studs up. Rejecting the canopy threw the mime away
		-- entirely - but "behind the tree" means the ground UNDERNEATH it, which is the next surface down.
		-- So step through the overhead geometry instead of giving up at it.
		--
		-- A surface is not ground if it is tilted, or if it is high up on something tall: the top of a building
		-- is a roof, the bottom of the same building is a doorstep, and both sit the same height above the
		-- baseplate - which is why measuring height alone got this wrong, the Rue being on a raised pad.
		local rpG = RaycastParams.new(); rpG.FilterType = Enum.RaycastFilterType.Exclude
		local above, g, host = {}, nil, nil
		for pass = 1, 14 do
			rpG.FilterDescendantsInstances = above
			local h = workspace:Raycast(Vector3.new(x, 250, z), Vector3.new(0, -500, 0), rpG)
			if not h then break end
			local ground = h.Normal.Y > 0.9
			if ground then
				local m = h.Instance:FindFirstAncestorWhichIsA("Model")
				if m and m ~= workspace then
					local lo, hi = math.huge, -math.huge
					for _, q in ipairs(m:GetDescendants()) do
						if q:IsA("BasePart") then
							lo = math.min(lo, q.Position.Y - q.Size.Y / 2)
							hi = math.max(hi, q.Position.Y + q.Size.Y / 2)
						end
					end
					if hi - lo > 8 and h.Position.Y > lo + (hi - lo) * 0.45 then ground = false end
				end
			end
			-- IS IT THE GROUND, OR THE TOP OF SOMETHING? The top of a bush is flat, faces the sky, and belongs to
			-- a model too short to count as a building - so it passed every test above, and acorns ended up
			-- perched in the foliage looking like they were floating. Ground has ground around it; a perch has a
			-- drop on most sides. Look at the neighbours before believing it.
			if ground and h.Instance ~= workspace.Terrain then
				local lower = 0
				for t = 1, 6 do
					local a = (t / 6) * math.pi * 2
					local n = workspace:Raycast(h.Position + Vector3.new(math.cos(a) * 2.5, 1.2, math.sin(a) * 2.5),
						Vector3.new(0, -14, 0))
					if n and (h.Position.Y - n.Position.Y) > 0.7 then lower += 1 end
				end
				if lower >= 4 then ground = false end
			end
			if ground then g, host = h.Position, h.Instance break end
			table.insert(above, h.Instance)
		end
		if not g then return nil end
		op.FilterType = Enum.RaycastFilterType.Exclude
		op.FilterDescendantsInstances = {host}
		if #workspace:GetPartBoundsInRadius(g + Vector3.new(0, 0.35, 0), 0.32, op) > 0 then return nil end
		local walls, open = 0, 0
		local eye = g + Vector3.new(0, 0.35, 0)
		for t = 1, 12 do
			local a = (t / 12) * math.pi * 2
			if workspace:Raycast(eye, Vector3.new(math.cos(a), 0, math.sin(a)) * 3) then walls += 1 else open += 1 end
		end
		if open < 2 then return nil end                                    -- sealed in, not hidden
		-- Overhead cover counts for more than any wall: it is what "under a tree" means, and until the ground
		-- beneath a canopy could be reached at all there was no way to ask for it.
		local over = workspace:Raycast(g + Vector3.new(0, 0.5, 0), Vector3.new(0, 16, 0))
		return {pos = Vector3.new(g.X, g.Y + 0.02, g.Z), covered = over ~= nil,
			score = walls + (over and 5 or 0) + rng:NextNumber(0, 1.5)}
	end

	local chosen, report = {}, {}
	local function farFrom(list, v, gap)
		for _, o in ipairs(list) do
			if (Vector3.new(o.X, 0, o.Z) - Vector3.new(v.X, 0, v.Z)).Magnitude < gap then return false end
		end
		return true
	end
	local allPos = {}

	for _, p in ipairs(PLACES) do
		local cands = {}
		if p.outskirts then
			-- a ring just inside the edge of the built world
			for i = 1, 900 do
				local t = rng:NextNumber(0, 1)
				local edge = rng:NextInteger(1, 4)
				local x, z
				local inset = rng:NextNumber(4, 26)
				if edge == 1 then x, z = minx + inset, minz + (maxz - minz) * t
				elseif edge == 2 then x, z = maxx - inset, minz + (maxz - minz) * t
				elseif edge == 3 then x, z = minx + (maxx - minx) * t, minz + inset
				else x, z = minx + (maxx - minx) * t, maxz - inset end
				local a = assess(x, z)
				if a then table.insert(cands, a) end
			end
		else
			local anchors = found[p.label]
			for _, base in ipairs(anchors) do
				for i = 1, 10 do
					local ang = rng:NextNumber(0, math.pi * 2)
					local r = p.radius * math.sqrt(rng:NextNumber(0.15, 1))
					local a = assess(base.X + math.cos(ang) * r, base.Z + math.sin(ang) * r)
					if a then table.insert(cands, a) end
				end
			end
		end
		table.sort(cands, function(a, b) return a.score > b.score end)
		local took = {}
		for _, c in ipairs(cands) do
			if #took >= p.n then break end
			if farFrom(took, c.pos, p.gap) and farFrom(allPos, c.pos, 12) then
				table.insert(took, c.pos)
				table.insert(allPos, c.pos)
				table.insert(chosen, {pos = c.pos, label = p.label})
			end
		end
		table.insert(report, string.format("%s %d/%d", p.label, #took, p.n))
	end

	-- ---------------------------------------------------------------- write them down ----
	local old = workspace:FindFirstChild("AcornSpots"); if old then old:Destroy() end
	local anchor = Instance.new("Part")
	anchor.Name = "AcornSpots"; anchor.Size = Vector3.new(1, 1, 1); anchor.CFrame = CFrame.new(0, 0, 0)
	anchor.Anchored = true; anchor.Transparency = 1; anchor.CanCollide = false; anchor.CanQuery = false
	anchor.CanTouch = false; anchor.Locked = true; anchor.Parent = workspace
	anchor:SetAttribute("SurfaceAligned", true)
	local function sectionOf(x)
		if x < 141 then return "forest" elseif x < 351 then return "village" else return "domaine" end
	end
	local per = {}
	for i, c in ipairs(chosen) do
		local sec = sectionOf(c.pos.X)
		per[sec] = (per[sec] or 0) + 1
		local at = Instance.new("Attachment")
		at.Name = string.format("%s_%03d", sec, i)
		at.Position = c.pos
		at:SetAttribute("Section", sec)
		at:SetAttribute("Place", c.label)
		at.Parent = anchor
	end

	print(string.format("AcornPlaces: %d spots - forest %d, village %d, domaine %d | world x %.0f..%.0f z %.0f..%.0f",
		#chosen, per.forest or 0, per.village or 0, per.domaine or 0, minx, maxx, minz, maxz))
	print("AcornPlaces: " .. table.concat(report, ", "))
	return #chosen
end

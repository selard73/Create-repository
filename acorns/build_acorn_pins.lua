-- AcornPins: the spots Shannon pointed at individually, added to whatever AcornSpots already holds.
--
-- Each pin is a point and a small radius. Within that radius the concealment scoring still decides the exact
-- nook, which is what makes "BEHIND the fashion designer" work without anyone having to say which way round
-- that is: the hidden side of a thing is, by definition, the side with the most cover, so the scoring finds it.
--
-- Positions are BOUNDING-BOX centres read out of the map, never pivots. The bridge model's pivot reports x310,
-- eighty studs from the timbers it belongs to.
-- Run in edit mode: require(workspace.AcornPins.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 99120)

	local PINS = {
		{label = "a vegetable bed",           at = Vector3.new(370, 2, -108), radius = 9, near = 5},
		{label = "a vegetable bed (2)",       at = Vector3.new(370, 2, -132), radius = 9, near = 5, optional = true},
		{label = "behind the fashion designer", at = Vector3.new(314, 2, -71), radius = 5},
		{label = "beside the mime",           at = Vector3.new(244, 2, -78),  radius = 9, near = 5},
		-- the tree at the back of the Rue, the last of its row toward the farm; picked off a numbered marker
		-- rather than from a photograph, because one plane tree looks much like another from a screenshot
		{label = "behind the back-row tree", at = Vector3.new(347, 2, -25),  radius = 7, near = 5},
		{label = "behind a bistro table",     at = Vector3.new(216, 2, -104), radius = 5},
		{label = "beside the bridge",         at = Vector3.new(156, 3, -120), radius = 11},
		-- the bicycle is chosen below, by which one stands beside a yellow building
		{label = "by the bicycle",            at = nil,                       radius = 6, bicycle = true},
	}

	-- Three bicycles, and she named the one at the corner of the YELLOW building. Rather than guess, look at what
	-- each one stands next to: the building whose walls are warm and bright is the yellow one.
	local BIKES = {Vector3.new(195, 3, -139), Vector3.new(290, 2, -72), Vector3.new(345, 2, -141)}
	local function yellowness(c)
		-- bright, warm, and clearly not blue
		if c.R < 0.65 or c.G < 0.55 then return 0 end
		if c.B > c.R * 0.85 then return 0 end
		return (c.R + c.G) / 2 - c.B
	end
	local bestBike, bestScore = BIKES[opts.bike or 1], -1
	local report = {}
	if opts.bike then bestScore = math.huge end           -- told which one; do not second-guess it
	for _, b in ipairs(BIKES) do
		local best = 0
		for _, p in ipairs(workspace:GetPartBoundsInRadius(b, 26)) do
			-- a wall, not a flowerpot
			if p:IsA("BasePart") and p.Size.Y > 6 and math.max(p.Size.X, p.Size.Z) > 6 then
				best = math.max(best, yellowness(p.Color))
			end
		end
		table.insert(report, string.format("%.0f,%.0f=%.2f", b.X, b.Z, best))
		if not opts.bike and best > bestScore then bestScore, bestBike = best, b end
	end

	-- ---------------------------------------------------------------- the same concealment test ----
	local op = OverlapParams.new()
	local function assess(x, z, loose)
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
		if open < 2 and not loose then return nil end
		return {pos = Vector3.new(g.X, g.Y + 0.02, g.Z), score = walls + rng:NextNumber(0, 1.2)}
	end

	local anchor = workspace:FindFirstChild("AcornSpots")
	assert(anchor, "AcornPins: run build_acorn_places first")
	-- clear last time's pins first; running this twice otherwise leaves two acorns at every pinned place
	local wiped = 0
	for _, at in ipairs(anchor:GetChildren()) do
		if at.Name:find("_pin", 1, true) then at:Destroy(); wiped += 1 end
	end
	local existing = {}
	for _, at in ipairs(anchor:GetChildren()) do table.insert(existing, at.Position) end

	local function sectionOf(x)
		if x < 141 then return "forest" elseif x < 351 then return "village" else return "domaine" end
	end

	local added, missed = {}, {}
	for _, pin in ipairs(PINS) do
		local centre = pin.bicycle and bestBike or pin.at
		-- A pin was asked for BY NAME, so it must not quietly fail the way a scattered spot may. Try properly
		-- first: nestled, and a respectful distance from its neighbours. Then loosen a notch at a time - allow
		-- it closer to a neighbour, then drop the demand that it be tucked in at all. An acorn beside the mime
		-- that is merely on the ground beside the mime still does what was asked. No acorn does not.
		local placed, how
		for _, try in ipairs({{loose = false, near = pin.near or 8, radius = pin.radius},
		                      {loose = false, near = 4,            radius = pin.radius * 1.5},
		                      {loose = true,  near = 3,            radius = pin.radius * 1.8}}) do
			local cands = {}
			for i = 1, 140 do
				local a = rng:NextNumber(0, math.pi * 2)
				local r = try.radius * math.sqrt(rng:NextNumber(0.08, 1))
				local c = assess(centre.X + math.cos(a) * r, centre.Z + math.sin(a) * r, try.loose)
				if c then table.insert(cands, c) end
			end
			table.sort(cands, function(a, b) return a.score > b.score end)
			for _, c in ipairs(cands) do
				local clash = false
				for _, e in ipairs(existing) do
					if (Vector3.new(e.X, 0, e.Z) - Vector3.new(c.pos.X, 0, c.pos.Z)).Magnitude < try.near then
						clash = true break
					end
				end
				if not clash then placed = c.pos; how = try.loose and "(open ground)" or "(tucked in)" break end
			end
			if placed then break end
		end
		if placed then
			local sec = sectionOf(placed.X)
			local at = Instance.new("Attachment")
			at.Name = string.format("%s_pin%02d", sec, #added + 1)
			at.Position = placed
			at:SetAttribute("Section", sec)
			at:SetAttribute("Place", pin.label)
			at.Parent = anchor
			table.insert(existing, placed)
			table.insert(added, string.format("%s @ %.0f,%.0f %s", pin.label, placed.X, placed.Z, how))
		else
			table.insert(missed, pin.label)
		end
	end

	print(string.format("AcornPins: %d of %d placed | yellow-building test on the bicycles: %s -> chose %.0f,%.0f",
		#added, #PINS, table.concat(report, " "), bestBike.X, bestBike.Z))
	print("AcornPins: " .. table.concat(added, " | "))
	for i = #missed, 1, -1 do
		for _, pin in ipairs(PINS) do
			if pin.label == missed[i] and pin.optional then table.remove(missed, i) break end
		end
	end
	if #missed > 0 then print("AcornPins: NO room found for - " .. table.concat(missed, ", ")) end
	return #added
end

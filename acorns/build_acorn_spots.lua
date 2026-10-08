-- AcornSpots: the pool of places an acorn can appear. They go ON THE GROUND and TUCKED AWAY - at the foot of a
-- tree, under the skirt of a bush, behind a rock, in the crook of a fallen log, in the corner where a wall meets
-- the path. Never perched on top of something in the open.
--
-- The first version of this got it backwards. It looked for flat surfaces you could jump up to and spaced them
-- evenly, which is a fine way to place platforms and a terrible way to hide things: the result was acorns sitting
-- on top of rocks at tidy intervals, visible from across the map.
--
-- So the measure here is CONCEALMENT, not reachability:
--   * Candidates are sampled on the ground AROUND and UNDER props, never on top of them.
--   * Each fires a ring of low horizontal rays. The more that hit something close by, the more the spot is
--     nestled into a corner rather than sitting out in the open.
--   * A ray straight up finds overhead cover - foliage, a table, a stall, an overhang. That is the strongest
--     signal there is, and it is what "under a bush" actually means, so it is weighted far above any wall.
--   * It must still be gettable: a spot walled in on every side is not hidden, it is sealed, so part of the ring
--     has to be open.
-- Spots are then taken BEST FIRST rather than spread out, which is what stops them reading as a grid. Where a
-- thicket offers three good hiding places close together, it gets all three.
--
-- Stored as Attachments on one invisible anchor at the origin, marking the SURFACE; whatever is placed there
-- decides its own resting height. Re-runnable: it rebuilds the anchor from scratch.
-- Run in edit mode: require(workspace.AcornSpots.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local WANT = opts.want or {forest = 30, village = 18, domaine = 18}
	-- Spacing. Taking the best-scoring spots with almost no minimum put five acorns around the rim of the spawn
	-- dais, which is the single most obvious place in the game. "Not spread out evenly" means do not lay a grid,
	-- not pile them up: they still have to be all over the map.
	local MINGAP = opts.minGap or 30
	local PERPROP = opts.perProp or 1                      -- one acorn per bush, tree or stall - never a nest of them
	local rng = Random.new(opts.seed or 20260922)

	local SECTION = {{"forest", -math.huge, 141}, {"village", 171, 351}, {"domaine", 389, math.huge}}
	local function sectionOf(x)
		for _, s in ipairs(SECTION) do if x >= s[2] and x < s[3] then return s[1] end end
		return nil                                         -- a crossing; nothing hides on the bridge
	end

	local skipRoot = {}
	for _, n in ipairs({"Boundary", "MapMusic", "SquirrelScripts", "HudBarUI", "Terrain", "Camera", "Baseplate",
		"AcornSpots", "AcornSystem", "Acorns", "AcornPreview"}) do skipRoot[n] = true end

	-- Nothing hides on a spawn platform. Its raised rim scores as beautiful cover from every side, so it wins on
	-- merit and then hosts a little heap of acorns in the one place every player lands.
	local function isNoGo(name)
		local n = name:lower()
		return n:find("spawn") ~= nil or n:find("dais") ~= nil or n:find("gate") ~= nil
	end

	local function isSquirrel(o)
		while o and o ~= workspace do
			local n = o.Name
			if n:sub(-6) == "_color" or n:sub(-5) == "_gray" or n:lower():find("squirrel") then return true end
			o = o.Parent
		end
		return false
	end

	local op = OverlapParams.new()

	-- ---------------------------------------------------------------- candidates, around and under props ----
	-- What counts as a prop. Taking every container's children blindly went one level too deep and started
	-- treating a barrel's metal Band and a mushroom's Top as separate props to hide behind - which is why the
	-- report was full of names like Band, Top, Leaf and CapBrim. A thing is a prop when it is NOT made of other
	-- models: a Folder or a Model of Models is scenery to descend into, anything else is the prop itself.
	local props = {}
	local function collect(c)
		local hasModelChild = false
		for _, k in ipairs(c:GetChildren()) do
			if k:IsA("Model") then hasModelChild = true break end
		end
		if (c:IsA("Folder") or hasModelChild) and not c:IsA("BasePart") then
			for _, k in ipairs(c:GetChildren()) do
				if k:IsA("Model") or k:IsA("BasePart") then table.insert(props, k) end
			end
		elseif c:IsA("Model") or c:IsA("BasePart") then
			table.insert(props, c)
		end
	end
	for _, root in ipairs(workspace:GetChildren()) do
		if not skipRoot[root.Name] then collect(root) end
	end

	local cand, seen = {}, 0
	do
			for _, prop in ipairs(props) do
				if (prop:IsA("Model") or prop:IsA("BasePart")) and not isSquirrel(prop) and not isNoGo(prop.Name) then
					local centre, ext
					if prop:IsA("BasePart") then
						centre, ext = prop.CFrame, prop.Size
					else
						local ok, c, e = pcall(function() return prop:GetBoundingBox() end)
						if ok then centre, ext = c, e end
					end
					if centre and ext then
						local r = math.max(ext.X, ext.Z) / 2
						local sec = sectionOf(centre.Position.X)
						-- a mushroom or a market stall can both hide an acorn; a whole hillside cannot
						if sec and r >= 0.8 and r <= 14 then
							seen += 1
							-- 0.55 is under the canopy, 1.25 is just outside the drip line
							for _, frac in ipairs({0.55, 0.9, 1.25}) do
								for t = 1, 8 do
									local a = (t / 8) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
									table.insert(cand, {
										x = centre.Position.X + math.cos(a) * r * frac,
										z = centre.Position.Z + math.sin(a) * r * frac,
										sec = sec, near = prop.Name})
								end
							end
						end
					end
				end
			end
	end

	-- ---------------------------------------------------------------- score each for concealment ----
	local scored = {}
	for _, c in ipairs(cand) do
		local down = workspace:Raycast(Vector3.new(c.x, 200, c.z), Vector3.new(0, -400, 0))
		if down and down.Normal.Y > 0.9 then
			local g = down.Position
			-- There has to be room for the acorn itself. The test has to be the SIZE OF THE ACORN and it has to
			-- ignore the ground it rests on: a half-stud sphere half a stud up always touches the ground beneath
			-- it, so the first version rejected every nestled spot and kept only bare open grass.
			op.FilterType = Enum.RaycastFilterType.Exclude
			op.FilterDescendantsInstances = {down.Instance}
			if #workspace:GetPartBoundsInRadius(g + Vector3.new(0, 0.35, 0), 0.32, op) == 0 then
				local walls, open = 0, 0
				local eye = g + Vector3.new(0, 0.35, 0)
				for t = 1, 12 do
					local a = (t / 12) * math.pi * 2
					if workspace:Raycast(eye, Vector3.new(math.cos(a), 0, math.sin(a)) * 3.0) then
						walls += 1
					else
						open += 1
					end
				end
				-- Overhead cover, valued by how LOW it is. A bush skirt a stud above your head is a hiding place;
				-- a tree canopy eight studs up is just shade. Searching only 4.5 studs found nothing at all,
				-- because bush foliage that low also fails the free-space test - the good spots are under things
				-- with legs and overhangs: tables, stalls, benches, trailers, awnings, the tractor.
				local up = workspace:Raycast(g + Vector3.new(0, 0.45, 0), Vector3.new(0, 9, 0))
				local lid = up and (up.Position.Y - g.Y) or 99
				local cover = up and math.max(0, (9 - lid) / 9) * 9 or 0
				local covered = up ~= nil and lid <= 5
				-- properly nestled, but with a way in: walled on every side is sealed, not hidden
				if walls >= 5 and open >= 2 then
					table.insert(scored, {
						pos = Vector3.new(g.X, g.Y + 0.02, g.Z), sec = c.sec, near = c.near,
						walls = walls, covered = covered,
						score = walls * 1.5 + cover + rng:NextNumber(0, 1.2)})
				end
			end
		end
	end

	-- ---------------------------------------------------------------- take the best hiding places ----
	table.sort(scored, function(a, b) return a.score > b.score end)
	local chosen, per, undercover, fromProp = {}, {}, 0, {}
	local function clear(v)
		for _, o in ipairs(chosen) do
			if (Vector3.new(o.pos.X, 0, o.pos.Z) - Vector3.new(v.X, 0, v.Z)).Magnitude < MINGAP then return false end
		end
		return true
	end
	for _, s in ipairs(scored) do
		if (per[s.sec] or 0) < (WANT[s.sec] or 0) and (fromProp[s.near] or 0) < PERPROP and clear(s.pos) then
			fromProp[s.near] = (fromProp[s.near] or 0) + 1
			table.insert(chosen, s)
			per[s.sec] = (per[s.sec] or 0) + 1
			if s.covered then undercover += 1 end
		end
	end

	-- ---------------------------------------------------------------- write them down ----
	local old = workspace:FindFirstChild("AcornSpots"); if old then old:Destroy() end
	local anchor = Instance.new("Part")
	anchor.Name = "AcornSpots"; anchor.Size = Vector3.new(1, 1, 1); anchor.CFrame = CFrame.new(0, 0, 0)
	anchor.Anchored = true; anchor.Transparency = 1; anchor.CanCollide = false; anchor.CanQuery = false
	anchor.CanTouch = false; anchor.Locked = true; anchor.Parent = workspace
	anchor:SetAttribute("SurfaceAligned", true)
	local kinds = {}
	for i, c in ipairs(chosen) do
		local at = Instance.new("Attachment")
		at.Name = string.format("%s_%03d", c.sec, i)
		at.Position = c.pos
		at:SetAttribute("Section", c.sec)
		at:SetAttribute("Near", c.near)
		at:SetAttribute("Cover", c.covered and "under" or "beside")
		at.Parent = anchor
		kinds[c.near] = (kinds[c.near] or 0) + 1
	end

	local list = {}
	for k, n in pairs(kinds) do table.insert(list, {k = k, n = n}) end
	table.sort(list, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.k < b.k end)
	local top = {}
	for i = 1, math.min(#list, 16) do table.insert(top, string.format("%s x%d", list[i].k, list[i].n)) end

	print(string.format("AcornSpots: %d hiding places - forest %d, village %d, domaine %d | %d under cover (%d%%) | from %d props",
		#chosen, per.forest or 0, per.village or 0, per.domaine or 0, undercover,
		#chosen > 0 and math.floor(undercover / #chosen * 100) or 0, seen))
	print("AcornSpots: tucked against - " .. table.concat(top, ", "))
	return #chosen
end

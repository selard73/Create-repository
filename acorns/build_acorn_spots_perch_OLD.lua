-- AcornSpots: the pool of places an acorn can appear. Not a scatter across open ground - the whole point is that
-- they turn up somewhere you would not have looked, so every spot here is the top face of something: a windowsill,
-- a barrel, the fountain rim, a stall counter, the windmill, a hay round, a fallen log.
--
-- Three rules do most of the work:
--   * VARIETY BEATS COUNT. The forest alone offers 136 candidate surfaces, nearly all of them tree tops and stumps,
--     and a hundred identical tree tops is not surprising, it is wallpaper. So each KIND of prop contributes at
--     most a handful of spots, rarest kinds chosen first. That is what promotes the one fountain and the one
--     windmill above the thirtieth round tree.
--   * SPREAD. No two spots within MINGAP studs, so a section never has a cluster and a barren half.
--   * REACHABLE. A surface between 1.2 and 7 studs above the ground under it: high enough to be a hiding place,
--     low enough to jump to. Nothing covered over, nothing tilted, nothing the size of a roof.
--
-- The spots are stored as Attachments on one invisible anchor part at the origin, so they cost almost nothing and
-- can still be seen and nudged in Studio. Re-runnable: it rebuilds the anchor from scratch each time.
-- Run in edit mode: require(workspace.AcornSpots.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	-- One spacing for the whole map gave the Rue only 14 spots. The forest is enormous and the street is compact,
	-- so they cannot want the same number: spread widely where there is room, tightly where there is not.
	local MINGAP = opts.minGap or {forest = 16, village = 9, domaine = 12}
	local MAXPERKIND = opts.maxPerKind or 4
	local rng = Random.new(opts.seed or 20260922)

	-- the same section lines the music and the found-sounds use; the two crossings get no spots at all, so an
	-- acorn never appears on the bridge where it would be picked up by accident on the way past
	local SECTION = {{"forest", -math.huge, 141}, {"village", 171, 351}, {"domaine", 389, math.huge}}
	local function sectionOf(x)
		for _, s in ipairs(SECTION) do if x >= s[2] and x < s[3] then return s[1] end end
		return nil
	end

	local skipRoot = {}
	for _, n in ipairs({"Boundary", "MapMusic", "SquirrelScripts", "HudBarUI", "Terrain", "Camera", "Baseplate",
		"AcornSpots", "AcornSystem", "Acorns"}) do skipRoot[n] = true end

	local function isSquirrel(p)                           -- never perch the currency on the thing you are hunting
		local o = p
		while o and o ~= workspace do
			local n = o.Name
			if n:sub(-6) == "_color" or n:sub(-5) == "_gray" or n:lower():find("squirrel") then return true end
			o = o.Parent
		end
		return false
	end

	-- ---------------------------------------------------------------- gather candidates ----
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local cand = {}                                        -- section -> kind -> {pos, ...}
	for _, root in ipairs(workspace:GetChildren()) do
		if not skipRoot[root.Name] then
			for _, p in ipairs(root:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide and p.Transparency < 0.5 and not isSquirrel(p) then
					local sec = sectionOf(p.Position.X)
					local w, d = p.Size.X, p.Size.Z
					if sec and p.CFrame.UpVector.Y >= 0.9 and w >= 1.6 and d >= 1.6 and w <= 26 and d <= 26 then
						local topY = p.Position.Y + p.Size.Y / 2
						local x, z = p.Position.X, p.Position.Z
						rp.FilterDescendantsInstances = {p}
						local ground = workspace:Raycast(Vector3.new(x, topY + 1, z), Vector3.new(0, -300, 0), rp)
						local rise = ground and (topY - ground.Position.Y) or 0
						if ground and rise >= 1.2 and rise <= 7 then
							local hit = workspace:Raycast(Vector3.new(x, topY + 6, z), Vector3.new(0, -7, 0))
							if hit and hit.Instance == p then
								-- CAN A PLAYER ACTUALLY GET TO IT? Measuring height against the prop's own lower parts
								-- said the top of the windmill was a one-stud step up; measuring against the ground
								-- the whole building stands on threw away every windowsill in the Rue. Neither is
								-- the real question. The real question is whether there is somewhere to STAND next
								-- to it and jump from, so look for that directly: a ring of ground around the spot,
								-- flat enough to stand on, within jumping distance below.
								-- two radii, because a single ring of 5 studs falls in the road outside a Rue doorway but
								-- misses the narrow strip beside a stall; and ONE foothold is enough to jump from
								local standable = 0
								for _, radius in ipairs({3.5, 5.5}) do
									for t = 1, 12 do
										local a = (t / 12) * math.pi * 2
										local sx, sz = x + math.cos(a) * radius, z + math.sin(a) * radius
										local r = workspace:Raycast(Vector3.new(sx, topY + 1, sz), Vector3.new(0, -9, 0), rp)
										if r and r.Normal.Y > 0.9 then
											local below = topY - r.Position.Y
											if below >= 0.5 and below <= 7 then standable += 1 end
										end
									end
								end
								if standable >= 1 then
									local kind = (p.Parent and p.Parent.Name or p.Name):gsub("_s%d+$", ""):gsub("_%d+$", "")
									cand[sec] = cand[sec] or {}
									cand[sec][kind] = cand[sec][kind] or {}
									table.insert(cand[sec][kind], Vector3.new(x, topY + 0.02, z))   -- the SURFACE; the acorn adds its own rest
								end
							end
						end
					end
				end
			end
		end
	end

	-- ---------------------------------------------------------------- choose, rarest kinds first ----
	local chosen, perSection, perKind = {}, {}, {}
	local function farEnough(v, sec)
		local gap = MINGAP[sec] or 12
		for _, o in ipairs(chosen) do
			if (Vector3.new(o.pos.X, 0, o.pos.Z) - Vector3.new(v.X, 0, v.Z)).Magnitude < gap then return false end
		end
		return true
	end
	for _, s in ipairs(SECTION) do
		local sec = s[1]
		local kinds = {}
		for kind, list in pairs(cand[sec] or {}) do table.insert(kinds, {kind = kind, list = list}) end
		-- rarest first: the single fountain gets its spot before the thirtieth round tree takes the room
		table.sort(kinds, function(a, b)
			if #a.list ~= #b.list then return #a.list < #b.list end
			return a.kind < b.kind
		end)
		for _, k in ipairs(kinds) do
			for i = #k.list, 2, -1 do                      -- shuffle, so re-running does not always pick the same one
				local j = rng:NextInteger(1, i)
				k.list[i], k.list[j] = k.list[j], k.list[i]
			end
			local took = 0
			for _, v in ipairs(k.list) do
				if took >= MAXPERKIND then break end
				if farEnough(v, sec) then
					table.insert(chosen, {pos = v, sec = sec, kind = k.kind})
					perSection[sec] = (perSection[sec] or 0) + 1
					perKind[k.kind] = (perKind[k.kind] or 0) + 1
					took += 1
				end
			end
		end
	end

	-- ---------------------------------------------------------------- write them down ----
	local old = workspace:FindFirstChild("AcornSpots"); if old then old:Destroy() end
	local anchor = Instance.new("Part")
	anchor.Name = "AcornSpots"; anchor.Size = Vector3.new(1, 1, 1); anchor.CFrame = CFrame.new(0, 0, 0)
	anchor.Anchored = true; anchor.Transparency = 1; anchor.CanCollide = false; anchor.CanQuery = false
	anchor.CanTouch = false; anchor.Locked = true; anchor.Parent = workspace
	for i, c in ipairs(chosen) do
		local at = Instance.new("Attachment")
		at.Name = string.format("%s_%03d", c.sec, i)       -- the section is readable from the name, so the server
		at.Position = c.pos                                -- can keep the acorns spread across the three maps
		at:SetAttribute("Section", c.sec)
		at:SetAttribute("Kind", c.kind)
		at.Parent = anchor
	end

	local rare = {}
	for kind, n in pairs(perKind) do table.insert(rare, {kind = kind, n = n}) end
	table.sort(rare, function(a, b) if a.n ~= b.n then return a.n < b.n end return a.kind < b.kind end)
	local shown = {}
	for i = 1, math.min(#rare, 14) do table.insert(shown, rare[i].kind) end

	print(string.format("AcornSpots: %d spots - forest %d, village %d, domaine %d (%d kinds, max %d each; spacing f%d/v%d/d%d)",
		#chosen, perSection.forest or 0, perSection.village or 0, perSection.domaine or 0,
		#rare, MAXPERKIND, MINGAP.forest or 0, MINGAP.village or 0, MINGAP.domaine or 0))
	print("AcornSpots: one-offs and rarities - " .. table.concat(shown, ", "))
	return #chosen
end

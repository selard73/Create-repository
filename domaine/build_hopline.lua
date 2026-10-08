-- Hop line: the vineyard's toadstool challenge in Chateau de l'Acorn. Shannon (Sep 25 2026): "please take out the far
-- back row of grapes in the vineyard (the one closest to the wall) and then from the very back of the vineyard all the
-- way to the far side along the tree line and wall, put those toadstools in procession at intervals that makes it
-- possible for the character to jump from one to the next without touching the ground at all; this can be a challenge
-- to see if you can make it all the way down the vineyard without touching the ground."
--   1. THE BACK ROW OF VINES COMES OUT: row 0 of the Domaine builder (z -235.2), the one beside the cypress row and the
--      stone wall - four vine_row models in workspace.Domaine.Props. The strip of bare soil it grew in stays, as the path
--      the toadstools stand along. (domaine/builder.lua no longer plants that row.)
--   2. A LINE OF TRAMPOLINE TOADSTOOLS stands where the row was, from the top of the vineyard (the east end, up by the
--      chapel, a few studs past the end of the vines) all the way down along the cypress row to the far west corner of
--      the estate, next to the Rue (Shannon: "I want the toadstools all the way down to the end of the vineyard", then
--      "extend the toadstools all the way down to the far end of the vineyard next to the rue"). They are the forest's toadstools
--      (forest/build_trampolines.lua) and live in the same workspace.Trampolines folder, so TrampolineClient bounces them
--      and TrampolineServer shows every bounce to the whole server. Each carries Line = "vineyard" and Order (1 = the top
--      end); build_trampolines.lua carries them over when it rebuilds its folder.
-- HOW HARD. Shannon: "I want it to require some skill of the player to not fall off" ... "not too hard". A bounce throws
-- you up at 100 studs/s and gravity (196.2) brings you back to the same height about a second later; a character runs
-- 16 studs/s in the air, so one bounce carries you 15-16 studs if you hold forward all the way. The gaps (centre to
-- centre) alternate long and short, about 10 to 13.5 studs, and the caps are on the small side (5.6-7.3 studs across):
-- a long gap wants forward held nearly the whole bounce, a short one wants you to let go early, so the rhythm keeps
-- changing and holding forward regardless drops you on the grass - but no gap is near the limit, and there is a stud or
-- so either way to land. A gentle zig-zag asks for a little steering. The first and the last are the biggest, low
-- enough to walk into (a small cap bounces you when you run into its brim), so the line can be started from either end.
-- Tested with a bot that steers like a player (scratchpad hop_bot.lua): both directions, no ground touches; holding
-- forward and never letting go falls off.
-- WHERE EXACTLY: midway between the cypress row and the next row of vines, both measured from their parts; every cap is
-- checked clear of everything else and nudged along z (or made a little smaller) if it is not.
-- Run in edit mode (re-runnable: it rebuilds its own toadstools; the vines stay out once they are out).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local F = workspace:FindFirstChild("Trampolines")
	assert(F, "workspace.Trampolines is missing - run forest/build_trampolines.lua first")
	local D = workspace:FindFirstChild("Domaine")
	local props = D and D:FindFirstChild("Props")
	assert(props, "workspace.Domaine.Props is missing")
	local rng = Random.new(opts.seed or 77)
	local report = {}

	-- world-space box round every part of a model (a turned part's box, not its model's)
	local function aabb(model)
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				local cf, s = p.CFrame, p.Size / 2
				local ex = Vector3.new(
					math.abs(cf.XVector.X) * s.X + math.abs(cf.YVector.X) * s.Y + math.abs(cf.ZVector.X) * s.Z,
					math.abs(cf.XVector.Y) * s.X + math.abs(cf.YVector.Y) * s.Y + math.abs(cf.ZVector.Y) * s.Z,
					math.abs(cf.XVector.Z) * s.X + math.abs(cf.YVector.Z) * s.Y + math.abs(cf.ZVector.Z) * s.Z)
				lo = lo:Min(cf.Position - ex); hi = hi:Max(cf.Position + ex)
			end
		end
		return lo, hi
	end
	local function isVine(m) return m:IsA("Model") and (m.Name == "vine_row_a" or m.Name == "vine_row_b") end

	-- ---------------------------------------------------------------- 1. the back row of vines ----
	local ROW0_Z, ROW1_Z = -235.2, -227.2                                -- builder.lua: VINES.z0 + 0.8 + r * 8
	local removed = 0
	for _, m in ipairs(props:GetChildren()) do
		if isVine(m) then
			local cf = m:GetBoundingBox()
			local p = cf.Position
			if p.Z < (ROW0_Z + ROW1_Z) / 2 and p.X > 505 and p.X < 650 then m:Destroy(); removed += 1 end   -- the vineyard is x 528..627
		end
	end
	table.insert(report, removed .. " vine rows taken out")

	-- ---------------------------------------------------------------- 2. where the line runs ----
	-- end to end: from a few studs past the east end of the vines to a few studs past the west end, measured from the vines
	local vMinX, vMaxX = math.huge, -math.huge
	for _, m in ipairs(props:GetChildren()) do
		if isVine(m) then local lo, hi = aabb(m); vMinX = math.min(vMinX, lo.X); vMaxX = math.max(vMaxX, hi.X) end
	end
	if vMinX == math.huge then vMinX, vMaxX = 528, 627 end
	-- the far west end: the cypresses on the estate's fence line by the Rue (x 357), and a cap's width clear of them
	local westFence = -math.huge
	for _, m in ipairs(props:GetChildren()) do
		if m:IsA("Model") and m.Name == "cypress" then
			local lo, hi = aabb(m)
			local cx, cz = (lo.X + hi.X) / 2, (lo.Z + hi.Z) / 2
			if cx < 372 and cz > -250 and cz < -222 then westFence = math.max(westFence, hi.X) end
		end
	end
	local PAST = opts.pastEnd or 3
	local X_TOP = opts.xTop or (vMaxX + PAST)
	local X_BOTTOM = opts.xBottom or ((westFence > -math.huge) and (westFence + 6.5) or 368)
	table.insert(report, string.format("vines run x %.1f..%.1f; the Rue-side cypresses reach x %.1f; the line runs x %.1f..%.1f", vMinX, vMaxX, westFence, X_BOTTOM, X_TOP))
	local cypressEdge, vineEdge = -math.huge, math.huge
	local nCyp, nVine = 0, 0
	for _, m in ipairs(props:GetChildren()) do
		if m:IsA("Model") then
			local lo, hi = aabb(m)
			local cx, cz = (lo.X + hi.X) / 2, (lo.Z + hi.Z) / 2
			if cx > X_BOTTOM - 12 and cx < X_TOP + 12 then
				if m.Name == "cypress" and cz < -238 and cz > -246 then cypressEdge = math.max(cypressEdge, hi.Z); nCyp += 1
				elseif isVine(m) and math.abs(cz - ROW1_Z) < 2 then vineEdge = math.min(vineEdge, lo.Z); nVine += 1 end
			end
		end
	end
	if nCyp == 0 then cypressEdge = -239.3 end                           -- 21-stud cypresses x1.25 on z -242
	if nVine == 0 then vineEdge = -228.0 end
	local zLine = opts.z or (cypressEdge + vineEdge) / 2
	local maxBrim = (vineEdge - cypressEdge) / 2 - 0.5
	table.insert(report, string.format("line z %.2f between the cypresses (edge %.2f, %d trees) and the vines (edge %.2f, %d rows), room for a %.2f brim",
		zLine, cypressEdge, nCyp, vineEdge, nVine, maxBrim))

	-- ---------------------------------------------------------------- is a spot clear? ----
	local rpG = RaycastParams.new(); rpG.FilterType = Enum.RaycastFilterType.Include
	local ground = {workspace.Terrain}
	if workspace:FindFirstChild("Baseplate") then table.insert(ground, workspace.Baseplate) end
	rpG.FilterDescendantsInstances = ground
	local function groundAt(x, z)
		local hit = workspace:Raycast(Vector3.new(x, 160, z), Vector3.new(0, -260, 0), rpG)
		return hit and hit.Position.Y
	end
	local mine = {}                                                      -- this build's own toadstools, never in the way of each other
	local function overlap()
		local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude
		local ex = {workspace.Terrain}
		if workspace:FindFirstChild("Baseplate") then table.insert(ex, workspace.Baseplate) end
		for _, m in ipairs(mine) do table.insert(ex, m) end
		op.FilterDescendantsInstances = ex
		return op
	end
	local function blocker(cf, size)
		for _, p in ipairs(workspace:GetPartBoundsInBox(cf, size, overlap())) do
			local huge = p.Size.X > 150 or p.Size.Y > 150 or p.Size.Z > 150
			local ghost = p.Transparency >= 0.95 and not p.CanCollide           -- an invisible trigger is no obstacle
			if not huge and not ghost then return p end
		end
	end
	local function spotOk(x, z, s)
		local brim, H = 2.8 * s, 5.2 * s
		local g = math.huge
		for k = 0, 6 do                                                  -- the lowest ground under the stalk, so it never floats
			local a = k * math.pi / 3
			local r = (k == 0) and 0 or 0.9 * s
			local gk = groundAt(x + math.cos(a) * r, z + math.sin(a) * r)
			if not gk then return nil, "no ground" end
			g = math.min(g, gk)
		end
		local b = blocker(CFrame.new(x, g + 0.4 + (H + 1) / 2, z), Vector3.new(2 * brim + 0.6, H + 1, 2 * brim + 0.6))
		if b then return nil, b:GetFullName() end
		return g
	end

	-- ---------------------------------------------------------------- 3. the toadstools ----
	for _, m in ipairs(F:GetChildren()) do if m:GetAttribute("Line") == "vineyard" then m:Destroy() end end
	-- from the top of the vineyard (east) down to the bottom (west): the gaps between caps (a long-short pattern, stretched
	-- or squeezed a little so the line ends exactly at X_BOTTOM), each cap's size, and the zig-zag either side of the line
	-- The pattern repeats for as long as the line is; the caps in between cycle through SIZES, the two ends are END_SIZE.
	local PATTERN = opts.pattern or {10.5, 13.0, 10.0, 13.5, 11.0, 13.0, 10.5, 12.5, 11.0}
	local SIZES = opts.sizes or {1.2, 1.1, 1.25, 1.1, 1.2, 1.1, 1.2, 1.15}
	local END_SIZE = opts.endSize or 1.3
	local mean = 0
	for _, g in ipairs(PATTERN) do mean += g / #PATTERN end
	local nGaps = math.max(1, math.floor((X_TOP - X_BOTTOM) / mean + 0.5))
	local GAPS, total = {}, 0
	for k = 1, nGaps do GAPS[k] = PATTERN[(k - 1) % #PATTERN + 1] end
	-- THE FIRST HOP AND THE LAST ARE SHORT ONES. You start a run by walking into an end cap, which bounces you off its
	-- near edge - a brim's width further from the next cap than its centre. The first test from the Rue end met the
	-- pattern's longest gap there, came up short and clipped the next brim from underneath.
	if nGaps >= 3 then
		local short = math.huge
		for _, g in ipairs(PATTERN) do short = math.min(short, g) end
		GAPS[1], GAPS[nGaps] = short, short
	end
	for k = 1, nGaps do total += GAPS[k] end
	for k = 1, nGaps do GAPS[k] = GAPS[k] * (X_TOP - X_BOTTOM) / total end
	local SCALES, ZIG = {}, {}
	for i = 1, nGaps + 1 do
		local ends = (i == 1 or i == nGaps + 1)
		SCALES[i] = ends and END_SIZE or SIZES[(i - 2) % #SIZES + 1]
		ZIG[i] = ends and 0 or ((i % 2 == 0) and 0.8 or -0.8)       -- a gentle zig-zag either side of the line
	end
	local shown = {}
	for _, g in ipairs(GAPS) do table.insert(shown, string.format("%.1f", g)) end
	table.insert(report, "gaps " .. table.concat(shown, ", "))
	local CYL = Enum.PartType.Cylinder
	local UPR = CFrame.Angles(0, 0, math.rad(90))                      -- a cylinder's axis is x; this stands it up
	local RED, STALK, SPOT = C(214, 50, 46), C(246, 236, 210), C(250, 246, 236)
	local TIERS = {{5.6, 0.5}, {5.1, 0.5}, {4.3, 0.5}, {3.2, 0.45}, {1.8, 0.4}}   -- the garden's stepped dome: diameter, thickness
	local function piece(m, name, size, cf, colour, shape)
		local p = Instance.new("Part"); p.Name = name; p.Shape = shape or CYL; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true; p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local x = X_TOP
	local made, nudged, lines = 0, {}, {}
	local prevTop
	for i = 1, #SCALES do
		if i > 1 then x -= GAPS[i - 1] or 11 end
		local z0 = zLine + (ZIG[i] or 0)
		local want = math.min(SCALES[i], maxBrim / 2.8)
		local g, s, z, why
		for sTry = want, 0.95, -0.05 do                                  -- the size asked for, or a little smaller
			for k = 0, 16 do                                                -- here, or up to two studs either side
				local dz = (k == 0) and 0 or ((k % 2 == 1) and 1 or -1) * 0.25 * math.ceil(k / 2)
				local gTry, reason = spotOk(x, z0 + dz, sTry)
				if gTry then g, s, z = gTry, sTry, z0 + dz break end
				why = reason
			end
			if g then break end
		end
		if not g then
			table.insert(nudged, string.format("#%d at x %.1f DID NOT FIT (%s)", i, x, tostring(why)))
		else
			if math.abs(s - SCALES[i]) > 0.01 or math.abs(z - z0) > 0.01 then
				table.insert(nudged, string.format("#%d scale %.2f->%.2f, z %+.2f", i, SCALES[i], s, z - z0))
			end
			local m = Instance.new("Model"); m.Name = string.format("VineHop%02d", i)
			pcall(function() m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)   -- streams in whole, brim and all
			local base = CFrame.new(x, g, z) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0)
			local stalk = piece(m, "Stalk", Vector3.new(2.8 * s + 0.3, 1.8 * s, 1.8 * s), base * CFrame.new(0, 1.4 * s - 0.15, 0) * UPR, STALK)
			for k, d in ipairs(TIERS) do
				local y = (3.05 + (k - 1) * 0.47) * s
				local cap = piece(m, "Cap", Vector3.new(d[2] * s, d[1] * s, d[1] * s), base * CFrame.new(0, y, 0) * UPR, RED)
				cap.CanTouch = true                                             -- the bouncy part
				cap:SetAttribute("Size0", cap.Size)
			end
			for k = 1, 4 do                                                     -- white spots on the edge of each step of the dome
				local r = TIERS[k][1] / 2 - 0.15
				local top = 3.05 + (k - 1) * 0.47 + TIERS[k][2] / 2
				local n = (k <= 2) and 3 or 2
				local turn = rng:NextNumber(0, 2 * math.pi)
				for j = 1, n do
					local a = turn + j * 2 * math.pi / n
					local b = piece(m, "Spot", Vector3.new(0.55 * s, 0.55 * s, 0.55 * s), base * CFrame.new(math.cos(a) * r * s, (top - 0.05) * s, math.sin(a) * r * s), SPOT, Enum.PartType.Ball)
					b.CanCollide = false; b.CanQuery = false
				end
			end
			m.PrimaryPart = stalk
			m:SetAttribute("RimY", g + 3.05 * s); m:SetAttribute("Scale", math.floor(s * 100 + 0.5) / 100)
			m:SetAttribute("Line", "vineyard"); m:SetAttribute("Order", i)
			m.Parent = F
			table.insert(mine, m)
			made += 1
			local top = g + 5.13 * s
			table.insert(lines, string.format("#%d x%.1f z%.2f s%.2f top %.1f%s", i, x, z, s, top, prevTop and string.format(" (%+.1f)", top - prevTop) or ""))
			prevTop = top
		end
	end
	F:SetAttribute("VineyardHops", made)
	table.insert(report, made .. " toadstools: " .. table.concat(lines, ", "))
	if #nudged > 0 then table.insert(report, "adjusted: " .. table.concat(nudged, "; ")) end

	-- acorns that could land under a cap
	local near = {}
	local spots = workspace:FindFirstChild("AcornSpots")
	if spots then
		for _, a in ipairs(spots:GetDescendants()) do
			if a:IsA("Attachment") then
				local p = a.WorldPosition
				for _, m in ipairs(mine) do
					local c = m.PrimaryPart.Position
					if (Vector2.new(p.X, p.Z) - Vector2.new(c.X, c.Z)).Magnitude < 2.8 * m:GetAttribute("Scale") + 1.5 then
						table.insert(near, string.format("%s by %s", a:GetFullName(), m.Name))
					end
				end
			end
		end
	end
	table.insert(report, (#near > 0) and ("acorn spots under caps: " .. table.concat(near, "; ")) or "no acorn spot under a cap")
	local msg = table.concat(report, " | ")
	F:SetAttribute("VineyardReport", msg)
	return msg
end

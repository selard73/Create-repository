-- probe94.lua - READ-ONLY (Studio EDIT mode). Changes nothing. Job 94 siting: for each candidate centre of the belvedere on
-- the Prato dei Fiori, what stands within RADIUS studs - every "thing" (the nearest Model with up to 150 parts, else the
-- part itself) with its box, its part count, how far its nearest part is from the centre, how high its top stands over the
-- terrain, and BIG when a box is over 4 studs across or 3 tall (a tree, a wall, a path slab: the installer refuses to bury
-- those) or small (flowers, grass: the installer sets those aside). Also the terrain under 12 rim points at r 17.5.
-- Prints "QQ PROBE94 ..." lines; send them all unchanged.
local CENTRES = {{500, -1080}, {512, -1066}, {524, -1078}, {538, -1073}, {486, -1060}}
local RADIUS = 22
local out = {}
local function say(fmt, ...) table.insert(out, "QQ PROBE94 " .. string.format(fmt, ...)) end
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {workspace.Terrain}
local function terrainAt(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	if h then return h.Position.Y, h.Material.Name end
	return nil, "none"
end
local countCache = {}
local function partCount(m)
	local n = countCache[m]
	if n == nil then
		n = 0
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1; if n > 150 then break end end end
		countCache[m] = n
	end
	return n
end
local function thingOf(p)
	local m = p.Parent
	while m and m ~= workspace do
		if m:IsA("Model") and partCount(m) <= 150 then return m end
		m = m.Parent
	end
	return p
end
-- every part near any centre, grouped by its thing
local groups = {}                                                      -- thing -> {parts = {...}}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d ~= workspace.Terrain and d.Transparency < 1 then
		local p = d.Position
		local reach = d.Size.Magnitude / 2
		for _, c in ipairs(CENTRES) do
			local dx, dz = p.X - c[1], p.Z - c[2]
			if math.sqrt(dx * dx + dz * dz) - reach <= RADIUS then
				local t = thingOf(d)
				local g = groups[t]; if not g then g = {parts = {}}; groups[t] = g end
				table.insert(g.parts, d)
				break
			end
		end
	end
end
local function box(parts)
	local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(parts) do
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
		end end end
	end
	return lo, hi
end
local function pathOf(o) return o:GetFullName():gsub("^Workspace%.", "") end
for _, c in ipairs(CENTRES) do
	local cx, cz = c[1], c[2]
	local ty, tm = terrainAt(cx, cz)
	local rim, water, lo, hi = {}, 0, math.huge, -math.huge
	for i = 0, 11 do
		local a = i * math.pi / 6
		local y, m = terrainAt(cx + 17.5 * math.sin(a), cz + 17.5 * math.cos(a))
		if y then lo = math.min(lo, y); hi = math.max(hi, y) end
		if m == "Water" or not y then water += 1 end
	end
	say("centre (%d, %d): terrain %s at y %s; rim r 17.5: y %.1f..%.1f, %d of 12 points water/none", cx, cz, tm, ty and string.format("%.1f", ty) or "none", lo, hi, water)
	local rows = {}
	for thing, g in pairs(groups) do
		local blo, bhi = box(g.parts)
		-- the nearest part to this centre
		local near = math.huge
		for _, p in ipairs(g.parts) do
			local dx, dz = p.Position.X - cx, p.Position.Z - cz
			near = math.min(near, math.sqrt(dx * dx + dz * dz) - p.Size.Magnitude / 2)
		end
		if near <= RADIUS then
			local midx, midz = (blo.X + bhi.X) / 2, (blo.Z + bhi.Z) / 2
			local gy = terrainAt(midx, midz) or blo.Y
			local w, dpt, h = bhi.X - blo.X, bhi.Z - blo.Z, bhi.Y - gy
			local big = (w > 4 or dpt > 4 or h > 3)
			table.insert(rows, {near = math.max(0, near), big = big, line = string.format("%s %s (%s, %d parts): x %.0f..%.0f z %.0f..%.0f, top %.1f over the terrain, nearest %.1f studs",
				big and "BIG" or "small", pathOf(thing), thing.ClassName, #g.parts, blo.X, bhi.X, blo.Z, bhi.Z, h, math.max(0, near))})
		end
	end
	table.sort(rows, function(a, b) if a.big ~= b.big then return a.big end return a.near < b.near end)
	local nBig, nSmall, shown = 0, 0, 0
	for _, r in ipairs(rows) do if r.big then nBig += 1 else nSmall += 1 end end
	say("centre (%d, %d): %d BIG things and %d small props within %d studs", cx, cz, nBig, nSmall, RADIUS)
	for _, r in ipairs(rows) do
		if r.big or shown < 6 then say("  %s", r.line); shown += 1 end
		if shown >= 40 then say("  ... and %d more", #rows - shown); break end
	end
end
for _, l in ipairs(out) do print(l) end
print(string.format("QQ PROBE94 END (%d lines)", #out))

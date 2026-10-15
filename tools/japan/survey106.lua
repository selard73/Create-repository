-- survey106.lua - READ-ONLY geometry survey of the Japan map (Studio EDIT; changes nothing). Job 106 (Shannon, Oct 15 2026: "make the
-- visual fixes in the Japan map, especially with the ground, a lot of things are overlapping and a lot of things are floating and the
-- water has places where it is exposed and look weird"). Measures, so the fix installer can act on numbers: (1) every prop (a top-most
-- model of at most 400 parts) and its gap to the ground under five points of its footprint - FLOATING (all five in the air), SUNK (the
-- ground above its bottom), TILTED (one corner floating, one buried = on a slope); (2) flat ground slabs whose top faces sit within
-- 0.15 studs of each other and overlap (z-fighting); (3) the water: a 12-stud grid over the map - where terrain water is VISIBLE, what
-- lies under it (ground or nothing), water over void, water lapping over ground parts, more than one water level - and a coarse ASCII
-- map of the whole island (25-stud cells). Prints "QQ GEO ..." lines; send them all unchanged (the map lines too).
local out, N = {}, 0
local function say(fmt, ...) N += 1; table.insert(out, "QQ GEO " .. string.format(fmt, ...)) end
local function path(o) return (o:GetFullName():gsub("^Workspace%.JapanMap%.", "")) end
local SGN = {-1, 1}
local function extents(list)
	local lo, hi, n = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9), 0
	for _, p in ipairs(list) do
		if p:IsA("BasePart") then
			n += 1
			local h = p.Size / 2
			for _, sx in ipairs(SGN) do for _, sy in ipairs(SGN) do for _, sz in ipairs(SGN) do
				local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
			end end end
		end
	end
	if n == 0 then return nil end
	return lo, hi, n
end
local ok, err = pcall(function()
	local J = workspace:FindFirstChild("JapanMap")
	if not J then say("ABORT - no workspace.JapanMap") return end
	local T = workspace.Terrain
	local all = J:GetDescendants()
	local parts = {}
	for _, d in ipairs(all) do if d:IsA("BasePart") then table.insert(parts, d) end end
	-- parts per model, top-most models of <= 400 parts
	local pc = {}
	for _, p in ipairs(parts) do
		local a = p.Parent
		while a and a ~= J do if a:IsA("Model") then pc[a] = (pc[a] or 0) + 1 end; a = a.Parent end
	end
	local models = {}
	for m, n in pairs(pc) do
		if n <= 400 then
			local par, top = m.Parent, true
			while par and par ~= J do if par:IsA("Model") and (pc[par] or 0) <= 400 then top = false break end; par = par.Parent end
			if top then table.insert(models, m) end
		end
	end
	table.sort(models, function(a, b) return a:GetFullName() < b:GetFullName() end)
	-- ---------- (1) props and the ground ----------
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = true
	local floating, sunk, tilted = {}, {}, {}
	local nF, nS, nT, checked = 0, 0, 0, 0
	local byKind = {}
	for _, m in ipairs(models) do
		local l, h, n = extents(m:GetDescendants())
		if l and l.X > 4500 then
			local w, d = h.X - l.X, h.Z - l.Z
			if w < 80 and d < 80 and (h.Y - l.Y) < 120 then          -- props and buildings, not the sculpted ground itself
				checked += 1
				rp.FilterDescendantsInstances = {m}
				local pts = {Vector3.new((l.X + h.X) / 2, 0, (l.Z + h.Z) / 2)}
				for _, sx in ipairs(SGN) do for _, sz in ipairs(SGN) do table.insert(pts, Vector3.new((l.X + h.X) / 2 + sx * w * 0.4, 0, (l.Z + h.Z) / 2 + sz * d * 0.4)) end end
				local gaps, under, bury = {}, {}, {}
				for i, q in ipairs(pts) do
					-- down from just above the bottom: how far to the ground (gap > 0 = air under this point)
					local r = workspace:Raycast(Vector3.new(q.X, l.Y + 0.25, q.Z), Vector3.new(0, -40, 0), rp)
					gaps[i] = r and (l.Y - r.Position.Y) or 40
					under[i] = r and (r.Instance == T and ("terrain " .. r.Material.Name) or r.Instance.Name) or "nothing"
					-- down from above the top: is the ground higher than the bottom (buried by how much)?
					local r2 = workspace:Raycast(Vector3.new(q.X, h.Y + 30, q.Z), Vector3.new(0, -(h.Y - l.Y + 60), 0), rp)
					bury[i] = r2 and (r2.Position.Y - l.Y) or -99
				end
				local minG, maxG, minB, maxB = 99, -99, 99, -99
				for i = 1, 5 do minG = math.min(minG, gaps[i]); maxG = math.max(maxG, gaps[i]); minB = math.min(minB, bury[i]); maxB = math.max(maxB, bury[i]) end
				local kind = m.Name:gsub("%s*%d+$", "")
				byKind[kind] = byKind[kind] or {n = 0, f = 0, s = 0}
				byKind[kind].n += 1
				if minG > 0.3 and minG < 40 then
					nF += 1; byKind[kind].f += 1
					if #floating < 45 then table.insert(floating, string.format("%s (%d parts) at (%.0f,%.1f,%.0f) gap %.1f..%.1f over %s", path(m), n, (l.X + h.X) / 2, l.Y, (l.Z + h.Z) / 2, minG, math.min(maxG, 40), under[1])) end
				elseif minG >= 40 then
					nF += 1; byKind[kind].f += 1
					if #floating < 45 then table.insert(floating, string.format("%s (%d parts) at (%.0f,%.1f,%.0f) NOTHING within 40 studs under it", path(m), n, (l.X + h.X) / 2, l.Y, (l.Z + h.Z) / 2)) end
				elseif maxB > 0.6 and maxB < 30 and minB > 0.6 then
					nS += 1; byKind[kind].s += 1
					if #sunk < 45 then table.insert(sunk, string.format("%s (%d parts) at (%.0f,%.1f,%.0f) buried %.1f..%.1f in %s", path(m), n, (l.X + h.X) / 2, l.Y, (l.Z + h.Z) / 2, minB, maxB, under[1])) end
				elseif maxG > 1.5 and maxB > 1.0 then
					nT += 1
					if #tilted < 25 then table.insert(tilted, string.format("%s (%d parts) at (%.0f,%.1f,%.0f) on a slope: one corner %.1f up, another %.1f buried", path(m), n, (l.X + h.X) / 2, l.Y, (l.Z + h.Z) / 2, maxG, maxB)) end
				end
			end
		end
	end
	say("props checked (top-most models <= 400 parts, under 80 x 80 studs): %d; FLOATING (air under all five footprint points) %d; SUNK (ground above the bottom at all five) %d; on a slope (one corner up, one buried) %d", checked, nF, nS, nT)
	for _, l in ipairs(floating) do say("  FLOAT %s", l) end
	for _, l in ipairs(sunk) do say("  SUNK %s", l) end
	for _, l in ipairs(tilted) do say("  SLOPE %s", l) end
	local kl = {}
	for k, v in pairs(byKind) do if v.f + v.s >= 3 then table.insert(kl, string.format("%s %d (float %d, sunk %d)", k, v.n, v.f, v.s)) end end
	table.sort(kl)
	say("kinds with 3 or more off the ground: %s", #kl > 0 and table.concat(kl, "; ") or "none")
	-- ---------- (2) flat ground slabs that fight ----------
	local slabs = {}
	for _, p in ipairs(parts) do
		if p.Size.X >= 10 and p.Size.Z >= 10 and p.Size.Y <= 6 and p.CFrame.UpVector.Y > 0.95 and p.Position.X > 4500 and p.Transparency < 1 then
			table.insert(slabs, {p = p, top = p.Position.Y + p.Size.Y / 2, x1 = p.Position.X - p.Size.X / 2, x2 = p.Position.X + p.Size.X / 2, z1 = p.Position.Z - p.Size.Z / 2, z2 = p.Position.Z + p.Size.Z / 2})
		end
	end
	table.sort(slabs, function(a, b) return a.top < b.top end)
	local fights, nFights = {}, 0
	for i = 1, #slabs do
		local a = slabs[i]
		for j = i + 1, #slabs do
			local b = slabs[j]
			if b.top - a.top > 0.15 then break end
			local ox = math.min(a.x2, b.x2) - math.max(a.x1, b.x1)
			local oz = math.min(a.z2, b.z2) - math.max(a.z1, b.z1)
			if ox > 2 and oz > 2 and a.p.Parent ~= b.p.Parent then
				nFights += 1
				if #fights < 30 then table.insert(fights, string.format("%s top %.2f and %s top %.2f overlap %.0f x %.0f at (%.0f,%.0f)", path(a.p), a.top, path(b.p), b.top, ox, oz, (math.max(a.x1, b.x1) + math.min(a.x2, b.x2)) / 2, (math.max(a.z1, b.z1) + math.min(a.z2, b.z2)) / 2)) end
			end
		end
	end
	say("flat slabs (>= 10 x 10, <= 6 tall, level): %d; pairs from different models with top faces within 0.15 studs that overlap (z-fighting): %d", #slabs, nFights)
	for _, l in ipairs(fights) do say("  FIGHT %s", l) end
	-- ---------- (3) the water ----------
	local rpW = RaycastParams.new(); rpW.FilterType = Enum.RaycastFilterType.Exclude; rpW.FilterDescendantsInstances = {}; rpW.IgnoreWater = true
	local X1, X2, Z1, Z2, STEP = 5300, 6750, -520, 480, 12
	local water, levels, overVoid, lapping, visible = 0, {}, {}, {}, 0
	local wx1, wx2, wz1, wz2 = 1e9, -1e9, 1e9, -1e9
	local cells = {}   -- for the ASCII map: 25-stud cells
	local CELL = 25
	local function cellKey(x, z) return math.floor((x - X1) / CELL) .. ":" .. math.floor((z - Z1) / CELL) end
	for x = X1, X2, STEP do
		for z = Z1, Z2, STEP do
			local r = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))         -- water counts
			local g = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpW)     -- water ignored: the ground or the bed
			local key = cellKey(x, z)
			local mark = cells[key]
			if r and r.Instance == T and r.Material == Enum.Material.Water then
				visible += 1
				local lvl = math.floor(r.Position.Y * 2 + 0.5) / 2
				levels[lvl] = (levels[lvl] or 0) + 1
				wx1, wx2, wz1, wz2 = math.min(wx1, x), math.max(wx2, x), math.min(wz1, z), math.max(wz2, z)
				if not g then
					if #overVoid < 25 then table.insert(overVoid, string.format("(%d,%d) level %.1f", x, z, r.Position.Y)) end
					overVoid.n = (overVoid.n or 0) + 1; mark = "v"
				elseif g.Instance ~= T and g.Position.Y < r.Position.Y - 0.3 then
					-- a part (sculpted ground, a path, a floor) lies under the water surface: the water laps over it
					lapping.n = (lapping.n or 0) + 1
					if #lapping < 30 then table.insert(lapping, string.format("(%d,%d) water %.1f over %s top %.1f", x, z, r.Position.Y, g.Instance.Name, g.Position.Y)) end
					mark = "f"
				else mark = (mark == "v" or mark == "f") and mark or "~" end
			elseif r and r.Instance == T then mark = (mark and mark ~= " ") and mark or "."
			elseif r then mark = (mark and mark ~= " " and mark ~= ".") and mark or "#"
			else mark = mark or " " end
			cells[key] = mark
		end
	end
	local ll = {}
	for lvl, n in pairs(levels) do table.insert(ll, {lvl = lvl, n = n}) end
	table.sort(ll, function(a, b) return a.n > b.n end)
	local ls = {}
	for i, e in ipairs(ll) do if i > 8 then break end; table.insert(ls, string.format("y %.1f x%d", e.lvl, e.n)) end
	say("water: %d visible samples on a %d-stud grid (x %d..%d, z %d..%d), levels: %s; over NOTHING %d; lapping over ground parts %d", visible, STEP, wx1, wx2, wz1, wz2, table.concat(ls, ", "), overVoid.n or 0, lapping.n or 0)
	for _, l in ipairs(overVoid) do say("  WATER-VOID %s", l) end
	for _, l in ipairs(lapping) do say("  WATER-LAP %s", l) end
	local wb = J:FindFirstChild("JapanWaterBasins")
	if wb and wb:IsA("StringValue") then say("JapanWaterBasins: %s", (wb.Value:gsub("\n", " "):sub(1, 700))) end
	-- the ASCII map: rows = z from north (Z2) to south (Z1), columns = x west to east; ~ water, v water over nothing, f water over a part, # part ground, . terrain, space = void
	local cols = math.floor((X2 - X1) / CELL)
	local rows = math.floor((Z2 - Z1) / CELL)
	say("MAP %d cols x %d rows, 25-stud cells, x %d..%d west to east, rows from z %d (top) to z %d: ~ water, v water over nothing, f water over a part, # parts, . terrain, blank = nothing", cols + 1, rows + 1, X1, X2, Z2, Z1)
	for rz = rows, 0, -1 do
		local line = {}
		for cx = 0, cols do table.insert(line, cells[cx .. ":" .. rz] or " ") end
		say("MAP|%s| z %d", table.concat(line), Z1 + rz * CELL)
	end
end)
for _, l in ipairs(out) do print(l) end
if ok then print(string.format("QQ GEO END (%d lines)", N)) else print("QQ GEO ERROR after " .. N .. " lines: " .. tostring(err)) end
return table.concat(out, "\n") .. (ok and "" or ("\nQQ GEO ERROR " .. tostring(err)))

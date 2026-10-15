-- japan_geo1.lua (job 106): Studio EDIT mode. The Japan map's visual fixes (Shannon, Oct 15 2026: "a lot of things are overlapping and
-- a lot of things are floating and the water has places where it is exposed"; her choice for the edge: "real sea with a wall farther
-- out"). From survey106 and its pictures. Everything is re-measured here; every move is logged (ServerStorage.HudBackup.JapanGeo1_log,
-- JSON) so it can be undone. No DataStore, no publish. Output "QQ GEO1".
-- (1) PROPS: Landscape bamboo clumps floating on the south ridge's slope (31 flagged) come down onto the ground under their centre; the
--     Blue vending machine comes up out of the market platform; the Raked gravel garden and the Fishing bank come down onto their ground;
--     the Fuji photography lookout gets a stone plinth down to the hillside instead of hovering; any other small prop hovering evenly up
--     to 3 studs comes down. Bridges, the canal boat, the waterwheel, the castle's inner staircase, the market stalls (their foundations are
--     meant to sit in the ground) and the bamboo grove maze are left alone.
-- (2) SLABS: 134 pairs of flat ground pieces whose top faces sit within 0.15 studs and overlap (the dashed seams on the paving) - the
--     higher one of each pair rises until the faces are 0.16 apart; repeated until no pair fights (at most 6 passes, moves of a few
--     hundredths to 0.16 studs).
-- (3) WATER: the lake stair's "Continuous underwater stair support" (a dark slab seen through the water) takes the bed's sand look; each
--     rectangular basin in Codex's JapanWaterBasins manifest is refilled - air inside the basin box up to its level becomes water (the
--     canal no longer stops in a vertical wall short of its north end); a REAL SEA: air below y -6 (the level of the sea basin east of
--     the island) across x 4900..7400, z -1500..900 becomes water, with a sand bed at y -64..-60 so nothing falls through, and an
--     invisible wall 150 studs out from the map's box (JapanMap."Sea wall").
local HttpService = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
if game:GetService("RunService"):IsRunning() then print("QQ GEO1 ABORT - Play mode") return end
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ GEO1 ABORT - no workspace.JapanMap") return end
local T = workspace.Terrain
local log = {moves = {}, slabs = {}, parts = {}, water = {}}
local function say(fmt, ...) print("QQ GEO1 " .. string.format(fmt, ...)) end
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
local all = J:GetDescendants()
local parts = {}
for _, d in ipairs(all) do if d:IsA("BasePart") then table.insert(parts, d) end end
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
-- ---------- (1) props ----------
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = true
local function measure(m)
	local l, h = extents(m:GetDescendants())
	if not l then return nil end
	rp.FilterDescendantsInstances = {m}
	local cx, cz, w, d = (l.X + h.X) / 2, (l.Z + h.Z) / 2, h.X - l.X, h.Z - l.Z
	local pts = {Vector3.new(cx, 0, cz)}
	for _, sx in ipairs(SGN) do for _, sz in ipairs(SGN) do table.insert(pts, Vector3.new(cx + sx * w * 0.4, 0, cz + sz * d * 0.4)) end end
	local gaps, burys, groundY = {}, {}, {}
	for i, q in ipairs(pts) do
		local r = workspace:Raycast(Vector3.new(q.X, l.Y + 0.25, q.Z), Vector3.new(0, -40, 0), rp)
		gaps[i] = r and (l.Y - r.Position.Y) or 40
		groundY[i] = r and r.Position.Y or nil
		local r2 = workspace:Raycast(Vector3.new(q.X, h.Y + 30, q.Z), Vector3.new(0, -(h.Y - l.Y + 60), 0), rp)
		burys[i] = r2 and (r2.Position.Y - l.Y) or -99
	end
	return {l = l, h = h, cx = cx, cz = cz, w = w, d = d, gaps = gaps, burys = burys, groundY = groundY}
end
local function shift(m, dy, why)
	m:PivotTo(m:GetPivot() + Vector3.new(0, dy, 0))
	table.insert(log.moves, {path = path(m), dy = dy})
	return string.format("%s %s %.2f (%s)", path(m), dy < 0 and "down" or "up", math.abs(dy), why)
end
local SKIP = {"footbridge", "Canal boat", "stream bridge", "Waterwheel", "staircase", "Bamboo grove maze", "MountainBackdrop", "Outdoor market revision"}
local function skipped(m)
	local full = m:GetFullName()
	for _, s in ipairs(SKIP) do if full:find(s, 1, true) then return true end end
	return false
end
local moved, lines = 0, {}
for _, m in ipairs(models) do
	if not skipped(m) then
		local e = measure(m)
		if e and e.l.X > 4500 and e.w < 80 and e.d < 80 then
			local name = m.Name
			local gC, bC = e.gaps[1], e.burys[1]
			local minG, maxG = 99, -99
			for i = 1, 5 do minG = math.min(minG, e.gaps[i]); maxG = math.max(maxG, e.gaps[i]) end
			local line
			if name == "Bamboo clump" then
				if minG > 0.3 and gC < 25 then line = shift(m, -(gC - 0.15), "bamboo onto the slope under its centre")
				elseif bC > 0.6 and bC < 6 and e.burys[1] == e.burys[1] then line = shift(m, bC - 0.1, "bamboo up out of the ground") end
			elseif name == "Blue vending machine" then
				if bC > 0.3 and bC < 3 then line = shift(m, bC, "vending machine up onto the platform") end
			elseif name == "Raked gravel garden" or name == "Fishing bank" then
				if minG > 0.3 and gC < 4 then line = shift(m, -(gC - 0.05), "down onto the ground") end
			elseif name == "Fuji photography lookout" then
				local low = math.huge
				for i = 1, 5 do if e.groundY[i] then low = math.min(low, e.groundY[i]) end end
				if low < math.huge and e.l.Y - low > 1 and not J:FindFirstChild("Lookout plinth", true) then
					local p = Instance.new("Part"); p.Name = "Lookout plinth"; p.Anchored = true; p.CanCollide = true
					p.Material = Enum.Material.Slate; p.Color = Color3.fromRGB(128, 126, 118)
					local hgt = e.l.Y - low + 1.5
					p.Size = Vector3.new(e.w * 0.82, hgt, e.d * 0.82)
					p.CFrame = CFrame.new(e.cx, e.l.Y - hgt / 2 + 0.2, e.cz)
					p.Parent = m
					table.insert(log.parts, "Lookout plinth")
					line = string.format("%s: a stone plinth %.0f x %.1f x %.0f down to the hillside", path(m), p.Size.X, hgt, p.Size.Z)
				end
			elseif minG > 0.3 and maxG - minG < 0.6 and gC < 3 then
				line = shift(m, -(gC - 0.05), "a hovering prop down onto its ground")
			end
			if line then moved += 1; if #lines < 60 then table.insert(lines, line) end end
		end
	end
end
say("props moved: %d", moved)
for _, l in ipairs(lines) do say("  MOVE %s", l) end
-- ---------- (2) slabs ----------
local function slabList()
	local s = {}
	for _, p in ipairs(J:GetDescendants()) do
		if p:IsA("BasePart") and p.Size.X >= 10 and p.Size.Z >= 10 and p.Size.Y <= 6 and p.CFrame.UpVector.Y > 0.95 and p.Position.X > 4500 and p.Transparency < 1 then
			table.insert(s, {p = p, top = p.Position.Y + p.Size.Y / 2, x1 = p.Position.X - p.Size.X / 2, x2 = p.Position.X + p.Size.X / 2, z1 = p.Position.Z - p.Size.Z / 2, z2 = p.Position.Z + p.Size.Z / 2, area = p.Size.X * p.Size.Z})
		end
	end
	table.sort(s, function(a, b) return a.top < b.top end)
	return s
end
local slabMoves, passes = 0, 0
for pass = 1, 6 do
	passes = pass
	local s = slabList()
	local fixed = 0
	for i = 1, #s do
		local a = s[i]
		for j = i + 1, #s do
			local b = s[j]
			if b.top - a.top > 0.15 then break end
			local ox = math.min(a.x2, b.x2) - math.max(a.x1, b.x1)
			local oz = math.min(a.z2, b.z2) - math.max(a.z1, b.z1)
			if ox > 2 and oz > 2 and a.p.Parent ~= b.p.Parent then
				-- the higher one rises (the smaller one when level) until the faces are 0.16 apart
				local up = (b.top > a.top) and b or ((b.area < a.area) and b or a)
				local dy = 0.16 - math.abs(b.top - a.top)
				up.p.CFrame = up.p.CFrame + Vector3.new(0, dy, 0); up.top += dy
				table.insert(log.slabs, {path = path(up.p), dy = dy}); fixed += 1; slabMoves += 1
			end
		end
	end
	if fixed == 0 then break end
end
say("slabs raised to stop z-fighting: %d moves in %d passes", slabMoves, passes)
-- ---------- (3) water ----------
local sup = 0
for _, p in ipairs(J:GetDescendants()) do
	if p:IsA("BasePart") and p.Name == "Continuous underwater stair support" then
		p.Material = Enum.Material.Sand; p.Color = Color3.fromRGB(196, 182, 140); sup += 1
	end
end
say("underwater stair supports given the bed's sand look: %d", sup)
local function fillAir(x1, y1, z1, x2, y2, z2, mat, label)
	local chunks = 0
	local step = 400
	for cx = x1, x2 - 0.01, step do
		for cz = z1, z2 - 0.01, step do
			local r = Region3.new(Vector3.new(cx, y1, cz), Vector3.new(math.min(cx + step, x2), y2, math.min(cz + step, z2))):ExpandToGrid(4)
			T:ReplaceMaterial(r, 4, Enum.Material.Air, mat)
			chunks += 1
		end
	end
	table.insert(log.water, {label = label, x1 = x1, y1 = y1, z1 = z1, x2 = x2, y2 = y2, z2 = z2, mat = mat.Name})
	return chunks
end
local origin = J:GetAttribute("Origin") or Vector3.new(6000, 0, 0)
local wb = J:FindFirstChild("JapanWaterBasins")
local basins = 0
if wb and wb:IsA("StringValue") then
	local ok, list = pcall(function() return HttpService:JSONDecode(wb.Value) end)
	if ok and type(list) == "table" then
		for _, b in ipairs(list) do
			if type(b) == "table" and not b.round and b.rx and b.rz and b.level and b.depth then
				local x, z = origin.X + b.x, origin.Z + b.z
				fillAir(x - b.rx, b.level - b.depth, z - b.rz, x + b.rx, b.level, z + b.rz, Enum.Material.Water, "basin " .. tostring(b.name))
				basins += 1
				say("  basin %s refilled: x %.0f..%.0f, z %.0f..%.0f, up to y %.1f", tostring(b.name), x - b.rx, x + b.rx, z - b.rz, z + b.rz, b.level)
			end
		end
	end
end
say("rectangular basins refilled from JapanWaterBasins: %d", basins)
local SEA = -6
local X1, X2, Z1, Z2 = 4900, 7400, -1500, 900
local bedChunks = fillAir(X1, -64, Z1, X2, -60, Z2, Enum.Material.Sand, "sea bed")
local seaChunks = fillAir(X1, -60, Z1, X2, SEA, Z2, Enum.Material.Water, "sea")
say("the sea: air below y %d across x %d..%d, z %d..%d is water now (%d chunks), on a sand bed (%d chunks)", SEA, X1, X2, Z1, Z2, seaChunks, bedChunks)
-- the wall, 150 studs out from the map's box
local lo, hi = extents(parts)
local WX1, WX2, WZ1, WZ2 = lo.X - 150, hi.X + 150, lo.Z - 150, hi.Z + 150
if WX1 < 4700 then WX1 = 4700 end   -- (never west of x 4700: France and Porto are far west of it anyway)
local wallF = J:FindFirstChild("Sea wall") or Instance.new("Folder"); wallF.Name = "Sea wall"; wallF.Parent = J
wallF:ClearAllChildren()
local function wall(cx, cz, sx, sz)
	local p = Instance.new("Part"); p.Name = "JapanSeaWall"; p.Anchored = true; p.CanCollide = true; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.CastShadow = false; p.Size = Vector3.new(sx, 170, sz); p.CFrame = CFrame.new(cx, 15, cz); p.Parent = wallF
end
local function along(fixedAxis, c, from, to)
	local len = to - from
	local n = math.ceil(len / 2000)
	for i = 0, n - 1 do
		local a, b = from + i * len / n, from + (i + 1) * len / n
		if fixedAxis == "x" then wall(c, (a + b) / 2, 2, b - a) else wall((a + b) / 2, c, b - a, 2) end
	end
end
along("x", WX1, WZ1, WZ2); along("x", WX2, WZ1, WZ2); along("z", WZ1, WX1, WX2); along("z", WZ2, WX1, WX2)
say("the wall: invisible, x %.0f and %.0f, z %.0f and %.0f, y -70..100 (%d parts in JapanMap.Sea wall)", WX1, WX2, WZ1, WZ2, #wallF:GetChildren())
-- ---------- the log ----------
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local lv = hb:FindFirstChild("JapanGeo1_log") or Instance.new("StringValue"); lv.Name = "JapanGeo1_log"; lv.Parent = hb
lv.Value = HttpService:JSONEncode(log)
say("DONE: %d props moved, %d slab moves, %d supports recoloured, %d basins refilled, the sea and the wall; log HudBackup.JapanGeo1_log (%d chars)", moved, slabMoves, sup, basins, #lv.Value)

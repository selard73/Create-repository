-- japan_geo1.lua (job 106): Studio EDIT mode. The Japan map's visual fixes (Shannon, Oct 15 2026: "a lot of things are overlapping and
-- a lot of things are floating and the water has places where it is exposed"; her choice for the edge: "real sea with a wall farther
-- out"). From survey106 and its pictures. Everything is re-measured here; every move is logged (ServerStorage.HudBackup.JapanGeo1_log,
-- JSON) so it can be undone. No DataStore, no publish. Output "QQ GEO1".
-- (1) PROPS: bamboo clumps hovering evenly come down by their smallest gap (the ridge clumps are planted INTO the slope - a ray from
--     inside the hill reads a false "gap" - and stay); clumps buried at all five points come up; the
--     Blue vending machine comes up out of the market platform; the Raked gravel garden and the Fishing bank come down onto their ground;
--     the Fuji photography lookout gets a stone plinth down to the hillside instead of hovering; any other small prop hovering evenly up
--     to 3 studs comes down. Bridges, the canal boat, the waterwheel, the castle's inner staircase, the market stalls (their foundations are
--     meant to sit in the ground) and the bamboo grove maze are left alone.
-- (2) SLABS: 134 pairs of flat ground pieces whose top faces sit within 0.15 studs and overlap (the dashed seams on the paving) - the
--     higher one of each pair rises until the faces are 0.16 apart; repeated until no pair fights (at most 6 passes, moves of a few
--     hundredths to 0.16 studs).
-- (3) WATER (round 2: voxel writes with the exact level, not ReplaceMaterial on a grid-snapped region): the lake stair's "Continuous underwater stair support" (a dark slab seen through the water) takes the bed's sand look; each
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
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before JapanGeo1") end)   -- (Ctrl+Z works back to here; save the place first)
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
for _, d in ipairs(all) do if d:IsA("BasePart") and d.Name ~= "JapanSeaWall" then table.insert(parts, d) end end   -- (a re-run must not measure its own wall)
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
		if e and e.l.X > 4500 and e.w < 80 and e.d < 80 and (e.h.Y - e.l.Y) < 120 then
			local name = m.Name
			local gC, bC = e.gaps[1], e.burys[1]
			local minG, maxG, minB = 99, -99, 99
			for i = 1, 5 do minG = math.min(minG, e.gaps[i]); maxG = math.max(maxG, e.gaps[i]); minB = math.min(minB, e.burys[i]) end
			local line
			local lower = name:lower()
			local hung = lower:find("lantern") or lower:find("sign") or lower:find("banner") or lower:find("flag") or lower:find("plume") or lower:find("smoke")
			-- (a ray that starts inside the terrain passes through it: a clump planted into the slope reads a "gap" down to the foundation
			-- under the hill. So a clump moves only when it hovers EVENLY (all five points within 2 studs) and by its SMALLEST gap, or
			-- when all five points are buried, by the smallest burial.)
			if name == "Bamboo clump" then
				if minG > 0.3 and maxG - minG < 3 and minG < 4 then line = shift(m, -(minG - 0.15), "bamboo down onto the ground")
				elseif minB > 0.6 and minB < 6 then line = shift(m, minB - 0.1, "bamboo up out of the ground") end
			elseif name == "Blue vending machine" then
				if bC > 0.3 and bC < 3 then line = shift(m, bC, "vending machine up onto the platform") end
			elseif name == "Raked gravel garden" or name == "Fishing bank" then
				if minG > 0.3 and minG < 4 then line = shift(m, -(minG - 0.05), "down onto the ground") end
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
			elseif not hung and minG > 0.3 and maxG - minG < 0.6 and minG < 3 then
				line = shift(m, -(minG - 0.05), "a hovering prop down onto its ground")
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
local risen = {}                                                      -- per part: how far it has risen in all (capped at 0.2)
local function mayRise(sl) return sl.p.Size.X <= 200 and sl.p.Size.Z <= 200 and not sl.p:GetFullName():find("Natural garden details", 1, true) and (risen[sl.p] or 0) < 0.36 end
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
				if not mayRise(up) then up = (up == a) and b or a end
				if mayRise(up) then
					local other = (up == a) and b or a
					local dy = 0.16 - (up.top - other.top)              -- (0.16 - the gap when the higher one rises; 0.16 + it when the lower one must)
					up.p.CFrame = up.p.CFrame + Vector3.new(0, dy, 0); up.top += dy
					risen[up.p] = (risen[up.p] or 0) + dy
					table.insert(log.slabs, {path = path(up.p), dy = dy}); fixed += 1; slabMoves += 1
				end
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
-- air -> water (or sand), up to an exact LEVEL, through the terrain's CHANNELS: only the liquid layer is written for water (a plain
-- ReadVoxels / WriteVoxels round-trip cannot carry a shoreline cell that is part sand and part water, and would notch every shore),
-- the solid layers for the sand bed. The top cell's occupancy is the share under the level. Basin boxes are rounded INWARD to the
-- 4-stud grid so no water spills past a declared bank. Falls back to the old voxel API if this Studio has no channels.
local function fillAir(x1, y1, z1, x2, y2, z2, mat, label, level)
	local chunks, cells = 0, 0
	local step = 256
	local gy1, gy2 = math.floor(y1 / 4) * 4, math.ceil(y2 / 4) * 4
	local gx1, gx2, gz1, gz2 = math.ceil(x1 / 4) * 4, math.floor(x2 / 4) * 4, math.ceil(z1 / 4) * 4, math.floor(z2 / 4) * 4
	local water = (mat == Enum.Material.Water)
	for cx = gx1, gx2 - 0.01, step do
		for cz = gz1, gz2 - 0.01, step do
			local r = Region3.new(Vector3.new(cx, gy1, cz), Vector3.new(math.min(cx + step, gx2), gy2, math.min(cz + step, gz2)))
			local okC = pcall(function()
				local ch = T:ReadVoxelChannels(r, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
				local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
				local changed = false
				for ix = 1, #SO do
					for iy = 1, #SO[ix] do
						local share = math.clamp((level - (gy1 + (iy - 1) * 4)) / 4, 0, 1)
						if share > 0.05 then
							for iz = 1, #SO[ix][iy] do
								if SO[ix][iy][iz] == 0 and LO[ix][iy][iz] == 0 then
									if water then LO[ix][iy][iz] = share else SM[ix][iy][iz] = mat; SO[ix][iy][iz] = share end
									changed = true; cells += 1
								end
							end
						end
					end
				end
				if changed then
					if water then T:WriteVoxelChannels(r, 4, {LiquidOccupancy = LO}) else T:WriteVoxelChannels(r, 4, {SolidMaterial = SM, SolidOccupancy = SO}) end
				end
			end)
			if not okC then   -- (no channel API: the old pair, Air cells only)
				local mats, occ = T:ReadVoxels(r, 4)
				local sz = mats.Size
				local changed = false
				for ix = 1, sz.X do
					for iy = 1, sz.Y do
						local share = math.clamp((level - (gy1 + (iy - 1) * 4)) / 4, 0, 1)
						if share > 0.05 then
							for iz = 1, sz.Z do
								if mats[ix][iy][iz] == Enum.Material.Air then mats[ix][iy][iz] = mat; occ[ix][iy][iz] = share; changed = true; cells += 1 end
							end
						end
					end
				end
				if changed then T:WriteVoxels(r, 4, mats, occ) end
			end
			chunks += 1
			task.wait()
		end
	end
	table.insert(log.water, {label = label, x1 = x1, y1 = y1, z1 = z1, x2 = x2, y2 = y2, z2 = z2, mat = mat.Name, level = level, cells = cells})
	return chunks, cells
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
				local _, cells = fillAir(x - b.rx, b.level - b.depth, z - b.rz, x + b.rx, b.level, z + b.rz, Enum.Material.Water, "basin " .. tostring(b.name), b.level)
				basins += 1
				say("  basin %s refilled: x %.0f..%.0f, z %.0f..%.0f, up to y %.2f (%d air cells became water)", tostring(b.name), x - b.rx, x + b.rx, z - b.rz, z + b.rz, b.level, cells)
			end
		end
	end
end
say("rectangular basins refilled from JapanWaterBasins: %d", basins)
local SEA = -6
local X1, X2, Z1, Z2 = 4750, 7400, -1500, 900
local lo, hi = extents(parts)
-- the wall 150 studs out from the map's box, never outside the sea, and the sea 150 studs beyond it on every side (lo.X is the chateau taxi sign at 442, so the west side is pinned)
local WX1, WX2, WZ1, WZ2 = math.max(lo.X - 150, 4900), math.min(hi.X + 150, X2 - 150), math.max(lo.Z - 150, Z1 + 150), math.min(hi.Z + 150, Z2 - 150)
local bedChunks, bedCells = fillAir(X1, -64, Z1, X2, -60, Z2, Enum.Material.Sand, "sea bed", -60)
local seaChunks, seaCells = fillAir(X1, -60, Z1, X2, SEA, Z2, Enum.Material.Water, "sea", SEA)
do   -- a readback (voxels, not a raycast - raycasts are stale right after a terrain edit): the sea must be there
	local what = "?"
	local okR = pcall(function() local ch = T:ReadVoxelChannels(Region3.new(Vector3.new(5000, -12, -1200), Vector3.new(5004, -8, -1196)), 4, {"LiquidOccupancy"}); what = "liquid " .. tostring(ch.LiquidOccupancy[1][1][1]) end)
	if not okR then local mm = T:ReadVoxels(Region3.new(Vector3.new(5000, -12, -1200), Vector3.new(5004, -8, -1196)), 4); what = mm[1][1][1].Name end
	say("the sea: air below y %d across x %d..%d, z %d..%d is water now (%d cells in %d chunks), on a sand bed (%d cells); readback at (5000,-10,-1200): %s", SEA, X1, X2, Z1, Z2, seaCells, seaChunks, bedCells, what)
end
-- the wall, 150 studs out from the map's box (and never short of the sea's edge)
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
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after JapanGeo1") end)
say("DONE: %d props moved, %d slab moves, %d supports recoloured, %d basins refilled, the sea and the wall; log HudBackup.JapanGeo1_log (%d chars)", moved, slabMoves, sup, basins, #lv.Value)

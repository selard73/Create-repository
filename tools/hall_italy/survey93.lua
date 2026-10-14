-- survey93.lua - READ-ONLY survey (Studio EDIT mode, execute as one script). Changes nothing, saves nothing.
-- Job 93: the Italian Hall of Fame (a monument of every Guardian of the Harbour). Three things:
--  (1) what the live PortoKeeper holds (attributes, plaque, which patches its server carries) and what a hall can reuse
--      (Champion.MakeStatue / MakeSquirrel, the ChampionAcorn template, the French HallOfFame's own layout);
--  (2) the Porto palette: what the ground is made of at the candidate sites (paving parts or terrain, their colours);
--  (3) five candidate sites measured for room: a 26 x 18 stud footprint (the French pavilion's steps are 22 x 14, its trees
--      a little wider) slid over each site at 2-stud steps; a window is CLEAR when every cell has ground under it, no water,
--      and nothing standing higher than 0.8 studs above the ground (walls, benches, trees, the Guardian's plinth); the
--      flattest clear windows are reported with their centre, the ground's mean height and its rise across the window.
-- Prints "QQ HALL ..." lines; send them all (unchanged) to the cloud session.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local out = {}
local function say(fmt, ...) table.insert(out, "QQ HALL " .. string.format(fmt, ...)) end
local function v3(v) return string.format("(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
local function rgb(c) return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
local function attrs(o) local ok, s = pcall(function() return HttpService:JSONEncode(o:GetAttributes()) end) return ok and s or "?" end
local function srcLen(s) local ok, src = pcall(function() return s.Source end) return (ok and src) and #src or -1 end
local function has(s, needle) local ok, src = pcall(function() return s.Source end) return (ok and src) and src:find(needle, 1, true) ~= nil end
local function extents(o)                                             -- the box round every part under o (world axes)
	local lo, hi, n = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9), 0
	local list = o:GetDescendants(); if o:IsA("BasePart") then table.insert(list, o) end
	for _, p in ipairs(list) do
		if p:IsA("BasePart") then
			n += 1
			local h = p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
			end end end
		end
	end
	if n == 0 then return nil end
	return lo, hi, n
end
local function boxLine(o)
	local lo, hi, n = extents(o)
	if not lo then return "no parts" end
	return string.format("%d parts, x %.1f..%.1f y %.1f..%.1f z %.1f..%.1f", n, lo.X, hi.X, lo.Y, hi.Y, lo.Z, hi.Z)
end
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {workspace.Terrain}
local function terrainAt(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	if h then return h.Position.Y, h.Material.Name end
	return nil, "none"
end
local function anyAt(x, z)                                             -- the first thing a ray from the sky meets
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	if not h then return "nothing" end
	local inst = h.Instance
	if inst == workspace.Terrain then return string.format("Terrain %s at y %.1f", h.Material.Name, h.Position.Y) end
	local top = inst
	while top.Parent and top.Parent ~= workspace do top = top.Parent end
	return string.format("%s (%s, %s, colour %s, size %s) of %s at y %.1f", inst.Name, inst.ClassName, inst.Material.Name, rgb(inst.Color), v3(inst.Size), top.Name, h.Position.Y)
end

-- ---------- (1) the PortoKeeper as it stands, and what a hall can reuse ----------
local K = workspace:FindFirstChild("PortoKeeper")
if K then
	say("PortoKeeper (%s) attrs %s", K.ClassName, attrs(K))
	local kids = {}
	for _, c in ipairs(K:GetChildren()) do table.insert(kids, c.Name .. ":" .. c.ClassName) end
	say("PortoKeeper children: %s", table.concat(kids, ", "))
	local s = K:FindFirstChild("PortoKeeperServer")
	if s then say("PortoKeeperServer %d chars; job 28 patch (portoFound) %s; job 90 patch (statue retry) %s", srcLen(s), tostring(has(s, "local function portoFound")), tostring(has(s, "building it again")))
	else say("PortoKeeperServer MISSING") end
	local c = K:FindFirstChild("PortoKeeperClient"); say("PortoKeeperClient %s", c and (srcLen(c) .. " chars") or "MISSING")
	local plinth = K:FindFirstChild("Plinth")
	if plinth then
		say("Plinth (%s): %s", plinth.ClassName, boxLine(plinth))
		local plaque = plinth:FindFirstChild("Plaque", true)
		local words = plaque and plaque:FindFirstChild("Words")
		if plaque then say("Plaque: %s at %s size %s colour %s %s; facing %s", plaque.ClassName, v3(plaque.Position), v3(plaque.Size), rgb(plaque.Color), plaque.Material.Name, v3(plaque.CFrame.LookVector)) end
		if words then
			local t = {}
			for _, l in ipairs(words:GetChildren()) do if l:IsA("TextLabel") then table.insert(t, l.Name .. '="' .. tostring(l.Text) .. '"') end end
			say("plaque words: %s", table.concat(t, " | "))
		else say("plaque Words: not found under the Plinth") end
	else say("Plinth MISSING under PortoKeeper") end
	for _, n in ipairs({"Key", "Figure", "GiantAcorn", "KeeperDebug"}) do local o = K:FindFirstChild(n); say("PortoKeeper.%s: %s", n, o and (o.ClassName .. " " .. (o:IsA("Model") and boxLine(o) or "")) or "absent") end
else say("workspace.PortoKeeper MISSING") end
say("RS.PortoKeeperEvent: %s", RS:FindFirstChild("PortoKeeperEvent") and "present" or "MISSING")
local CH = workspace:FindFirstChild("Champion")
if CH then
	local kids = {}
	for _, c in ipairs(CH:GetChildren()) do table.insert(kids, c.Name .. ":" .. c.ClassName) end
	say("Champion children: %s", table.concat(kids, ", "))
	say("Champion attrs %s", attrs(CH))
	local cs = CH:FindFirstChild("ChampionServer"); say("ChampionServer %s chars; MakeStatue %s; MakeSquirrel %s", cs and srcLen(cs) or "MISSING", CH:FindFirstChild("MakeStatue") and CH.MakeStatue.ClassName or "MISSING", CH:FindFirstChild("MakeSquirrel") and CH.MakeSquirrel.ClassName or "MISSING")
else say("workspace.Champion MISSING") end
say("ServerStorage.ChampionAcorn (the gilded acorn template): %s", SS:FindFirstChild("ChampionAcorn") and boxLine(SS.ChampionAcorn) or "MISSING")
local H = workspace:FindFirstChild("HallOfFame")
if H then
	local kids = {}
	for _, c in ipairs(H:GetChildren()) do table.insert(kids, c.Name .. ":" .. c.ClassName) end
	say("French HallOfFame children: %s", table.concat(kids, ", "))
	say("French HallOfFame attrs %s", attrs(H))
	for _, n in ipairs({"Pavilion", "Frame", "PlaqueStand", "Setting", "HallSign", "Squirrel"}) do local o = H:FindFirstChild(n); say("HallOfFame.%s: %s", n, o and boxLine(o) or "absent") end
	local hs, hc = H:FindFirstChild("HallServer"), H:FindFirstChild("HallClient")
	say("HallServer %s chars, HallClient %s chars; RS.HallStatues %s", hs and srcLen(hs) or "MISSING", hc and srcLen(hc) or "MISSING", RS:FindFirstChild("HallStatues") and "present" or "absent")
else say("workspace.HallOfFame MISSING (the French hall)") end
-- the squirrels a hall might seat beside the statue (France has the Forest Ranger saluting)
for _, n in ipairs({"officer", "lifeguard", "harbour", "bagnino", "poliz"}) do
	local found = {}
	for _, m in ipairs(workspace:GetChildren()) do
		if (m:IsA("Model") or m:IsA("Folder")) and m.Name:lower():find(n) and #found < 4 then
			local lo, hi = extents(m)
			table.insert(found, m.Name .. (lo and (" at " .. v3((lo + hi) / 2)) or ""))
		end
	end
	if #found > 0 then say("workspace models named like '%s': %s", n, table.concat(found, "; ")) end
end

-- ---------- (2) the ground at the candidate sites (what a ray from the sky meets) ----------
for _, p in ipairs({{"A plinth's west", 476, -1158}, {"A cottage path", 515, -1132}, {"A terrace north", 490, -1125}, {"B piazza west", 440, -790}, {"B piazza east", 490, -775}, {"B piazza south", 465, -820},
	{"C harbour piazza", 285, -655}, {"C by the benches", 250, -690}, {"C lemon trees", 320, -630}, {"D church front", 410, -960}, {"D by the olive", 430, -990}, {"E meadow middle", 520, -1080}, {"E meadow west", 470, -1050}}) do
	say("ground %s (%d,%d): %s", p[1], p[2], p[3], anyAt(p[2], p[3]))
end

-- ---------- (3) the five candidate sites, measured for a 26 x 18 footprint ----------
local SITES = {
	{id = "A", name = "the lighthouse terrace, beside the Guardian's statue", x0 = 450, x1 = 550, z0 = -1180, z1 = -1100},
	{id = "B", name = "Piazza del Limone", x0 = 420, x1 = 510, z0 = -840, z1 = -750},
	{id = "C", name = "the harbour front (benches, lemon trees, the piers)", x0 = 225, x1 = 350, z0 = -730, z1 = -590},
	{id = "D", name = "the church square (Santa Marina, the sailing club)", x0 = 365, x1 = 465, z0 = -1015, z1 = -910},
	{id = "E", name = "Prato dei Fiori, the coastal meadow", x0 = 441, x1 = 599, z0 = -1140, z1 = -1021},
}
local STEP, FW, FD = 2, 26, 18
-- every part standing near any site, with its footprint in world x/z and its top
local standing = {}
local tyCache = {}
local function terrainCached(x, z)
	local k = math.floor(x / 4) .. ":" .. math.floor(z / 4)
	local v = tyCache[k]
	if v == nil then local y = terrainAt(x, z); v = {y = y or false}; tyCache[k] = v end
	return v.y or nil
end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d ~= workspace.Terrain and not (d.Transparency >= 0.95 and not d.CanCollide) then
		local p = d.Position
		local near = false
		for _, s in ipairs(SITES) do if p.X >= s.x0 - 8 and p.X <= s.x1 + 8 and p.Z >= s.z0 - 8 and p.Z <= s.z1 + 8 then near = true break end end
		if near then
			local cf, h = d.CFrame, d.Size / 2
			local ex = math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z
			local ey = math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z
			local ez = math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
			local ty = terrainCached(p.X, p.Z)
			local top = p.Y + ey
			if ty == nil or top > ty + 0.8 then
				local topModel = d
				while topModel.Parent and topModel.Parent ~= workspace do topModel = topModel.Parent end
				table.insert(standing, {x0 = p.X - ex, x1 = p.X + ex, z0 = p.Z - ez, z1 = p.Z + ez, top = top, name = topModel.Name, part = d.Name})
			end
		end
	end
end
say("standing parts near the five sites: %d (anything topping 0.8 above the terrain under it)", #standing)
for _, s in ipairs(SITES) do
	local nx, nz = math.floor((s.x1 - s.x0) / STEP) + 1, math.floor((s.z1 - s.z0) / STEP) + 1
	local ty, mat, blocked = {}, {}, {}
	local mats, nGround, nWater = {}, 0, 0
	for i = 1, nx do
		ty[i], mat[i], blocked[i] = {}, {}, {}
		for j = 1, nz do
			local x, z = s.x0 + (i - 1) * STEP, s.z0 + (j - 1) * STEP
			local y, m = terrainAt(x, z)
			ty[i][j], mat[i][j] = y, m
			if y then nGround += 1; mats[m] = (mats[m] or 0) + 1 end
			if m == "Water" then nWater += 1 end
			blocked[i][j] = (y == nil) or (m == "Water")
		end
	end
	local nBlockedByParts = 0
	for _, b in ipairs(standing) do
		if b.x1 >= s.x0 and b.x0 <= s.x1 and b.z1 >= s.z0 and b.z0 <= s.z1 then
			local i0, i1 = math.max(1, math.ceil((b.x0 - s.x0) / STEP) + 1), math.min(nx, math.floor((b.x1 - s.x0) / STEP) + 1)
			local j0, j1 = math.max(1, math.ceil((b.z0 - s.z0) / STEP) + 1), math.min(nz, math.floor((b.z1 - s.z0) / STEP) + 1)
			for i = i0, i1 do for j = j0, j1 do if not blocked[i][j] then blocked[i][j] = true; nBlockedByParts += 1 end end end
		end
	end
	local ml = {}
	for m, n in pairs(mats) do table.insert(ml, {m, n}) end
	table.sort(ml, function(a, b) return a[2] > b[2] end)
	local mtxt = {}
	for k = 1, math.min(4, #ml) do table.insert(mtxt, string.format("%s %d%%", ml[k][1], math.floor(100 * ml[k][2] / math.max(1, nGround) + 0.5))) end
	say("site %s (%s): x %d..%d z %d..%d, %d cells at %d studs; ground under %d, water %d, blocked by things %d; terrain %s", s.id, s.name, s.x0, s.x1, s.z0, s.z1, nx * nz, STEP, nGround, nWater, nBlockedByParts, table.concat(mtxt, ", "))
	-- the flattest clear windows, both ways round
	local wins = {}
	for _, o in ipairs({{math.floor(FW / STEP) + 1, math.floor(FD / STEP) + 1, "26 wide x 18 deep"}, {math.floor(FD / STEP) + 1, math.floor(FW / STEP) + 1, "18 wide x 26 deep"}}) do
		local w, d = o[1], o[2]
		for i0 = 1, nx - w + 1 do
			for j0 = 1, nz - d + 1 do
				local lo, hi, sum, n, ok = 1e9, -1e9, 0, 0, true
				for i = i0, i0 + w - 1 do
					for j = j0, j0 + d - 1 do
						if blocked[i][j] then ok = false break end
						local y = ty[i][j]; if y < lo then lo = y end; if y > hi then hi = y end; sum += y; n += 1
					end
					if not ok then break end
				end
				if ok then
					table.insert(wins, {cx = s.x0 + (i0 - 1 + (w - 1) / 2) * STEP, cz = s.z0 + (j0 - 1 + (d - 1) / 2) * STEP, rise = hi - lo, mean = sum / n, lo = lo, hi = hi, w = w, d = d, how = o[3], i0 = i0, j0 = j0})
				end
			end
		end
	end
	table.sort(wins, function(a, b) return a.rise < b.rise end)
	local picked = {}
	for _, win in ipairs(wins) do
		local far = true
		for _, p in ipairs(picked) do if math.abs(p.cx - win.cx) < 12 and math.abs(p.cz - win.cz) < 12 then far = false break end end
		if far then table.insert(picked, win) end
		if #picked >= 3 then break end
	end
	if #picked == 0 then
		say("site %s: NO clear 26 x 18 window (every window meets water, a drop, or something standing)", s.id)
	else
		for k, win in ipairs(picked) do
			-- the dominant terrain material inside, and what stands just outside (within 6 studs)
			local inside = {}
			for i = win.i0, win.i0 + win.w - 1 do for j = win.j0, win.j0 + win.d - 1 do local m = mat[i][j]; inside[m] = (inside[m] or 0) + 1 end end
			local best, bn = "?", 0
			for m, n in pairs(inside) do if n > bn then best, bn = m, n end end
			local wx0, wx1 = win.cx - (win.w - 1) * STEP / 2, win.cx + (win.w - 1) * STEP / 2
			local wz0, wz1 = win.cz - (win.d - 1) * STEP / 2, win.cz + (win.d - 1) * STEP / 2
			local seen, names = {}, {}
			for _, b in ipairs(standing) do
				if b.x1 >= wx0 - 6 and b.x0 <= wx1 + 6 and b.z1 >= wz0 - 6 and b.z0 <= wz1 + 6 and not seen[b.name] and #names < 6 then seen[b.name] = true; table.insert(names, b.name) end
			end
			say("site %s window %d: centre (%.0f, %.0f), %s, ground mean y %.1f (%.1f..%.1f, rise %.1f), %s underfoot; standing within 6 studs: %s", s.id, k, win.cx, win.cz, win.how, win.mean, win.lo, win.hi, win.rise, best, #names > 0 and table.concat(names, ", ") or "nothing")
		end
		say("site %s: %d clear windows in all", s.id, #wins)
	end
end

for _, l in ipairs(out) do print(l) end
print(string.format("QQ HALL END (%d lines)", #out))

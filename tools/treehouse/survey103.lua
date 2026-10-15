-- survey103.lua - READ-ONLY survey (Studio EDIT mode). Changes nothing, saves nothing. Job 103: the forest treehouse (Shannon,
-- Oct 15 2026: pieces strewn through the French map, a count of how many more, the treehouse built piece by piece; "that will
-- keep people longer at the start"). What the builder needs: (1) the forest spawn pad and the ground there; (2) the trees near
-- it - every tree-like model within 90 studs of the spawn with its trunk's foot, trunk width, canopy top, and how far it stands
-- from the spawn, so a big one in sight of the spawn can carry the treehouse; (3) the 15 forest squirrels' positions (the path
-- new players walk), and the village's and the chateau's squirrels (where the "beyond the gate" pieces can lie); (4) the gates:
-- the bridge to Rue de Noisette and the garden gate to the chateau; (5) the ground along a ring of spots round the spawn
-- (where the first pieces can lie in plain sight). Prints "QQ TREE ..." lines; send them all unchanged.
local out = {}
local function say(fmt, ...) table.insert(out, "QQ TREE " .. string.format(fmt, ...)) end
local function v3(v) return string.format("(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {workspace.Terrain}
local function groundAt(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	local t = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	return h and h.Position.Y or nil, h and h.Instance and (h.Instance == workspace.Terrain and ("Terrain " .. h.Material.Name) or h.Instance.Name) or "nothing", t and t.Position.Y or nil
end
local function extents(o)
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

-- ---------- (1) the spawn ----------
local SX, SZ = 3, 1                                                   -- boundary/build_spawnpads.lua: {id = "forest", x = 3, z = 1}
local pads = workspace:FindFirstChild("SpawnPads")
if pads then
	for _, p in ipairs(pads:GetDescendants()) do
		if p:IsA("SpawnLocation") or (p:IsA("BasePart") and p:GetAttribute("Area") == "forest") then say("spawn part %s at %s size %s attrs Area=%s", p:GetFullName():gsub("^Workspace%.", ""), v3(p.Position), v3(p.Size), tostring(p:GetAttribute("Area"))) end
	end
else
	for _, p in ipairs(workspace:GetDescendants()) do if p:IsA("SpawnLocation") then say("SpawnLocation %s at %s", p:GetFullName():gsub("^Workspace%.", ""), v3(p.Position)) end end
end
local gy, gwhat, ty = groundAt(SX, SZ)
say("forest spawn (3, 1): ground %s (%s), terrain %s", gy and string.format("%.1f", gy) or "none", gwhat, ty and string.format("%.1f", ty) or "none")

-- ---------- (2) the trees near the spawn ----------
local TREEISH = {"pine", "tree", "oak", "trunk", "canopy", "birch", "fir"}
local seen, trees = {}, {}
for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and not seen[m] then
		local n = m.Name:lower()
		local isTree = false
		for _, w in ipairs(TREEISH) do if n:find(w) then isTree = true break end end
		if isTree then
			local lo, hi, cnt = extents(m)
			if lo then
				local cx, cz = (lo.X + hi.X) / 2, (lo.Z + hi.Z) / 2
				local d = math.sqrt((cx - SX) ^ 2 + (cz - SZ) ^ 2)
				if d <= 90 then
					seen[m] = true
					-- the trunk: the lowest tall part
					local trunk, trunkR
					for _, p in ipairs(m:GetDescendants()) do
						if p:IsA("BasePart") and p.Size.Y > 4 and (not trunk or p.Position.Y - p.Size.Y / 2 < trunk.Position.Y - trunk.Size.Y / 2) then trunk = p end
					end
					if trunk then trunkR = math.max(trunk.Size.X, trunk.Size.Z) / 2 end
					table.insert(trees, {m = m, d = d, lo = lo, hi = hi, cnt = cnt, trunk = trunk, trunkR = trunkR, cx = cx, cz = cz})
				end
			end
		end
	end
end
table.sort(trees, function(a, b) return a.d < b.d end)
say("tree-like models within 90 studs of the spawn: %d", #trees)
for i, t in ipairs(trees) do
	if i > 40 then say("  ... and %d more", #trees - 40) break end
	say("  %s (%d parts): centre (%.0f, %.0f) %.0f studs from the spawn, foot y %.1f, top y %.1f, box %.0f x %.0f; trunk %s", t.m:GetFullName():gsub("^Workspace%.", ""), t.cnt, t.cx, t.cz, t.d, t.lo.Y, t.hi.Y, t.hi.X - t.lo.X, t.hi.Z - t.lo.Z,
		t.trunk and string.format("%s at %s, %.1f wide, %.1f tall", t.trunk.Name, v3(t.trunk.Position), (t.trunkR or 0) * 2, t.trunk.Size.Y) or "none found")
end

-- ---------- (3) the squirrels of the three French maps ----------
local okR, R = pcall(require, workspace.SquirrelScripts.SquirrelRegistry)
if okR and type(R) == "table" and type(R.squirrels) == "table" then
	local byMap = {forest = {}, village = {}, domaine = {}}
	for _, q in ipairs(R.squirrels) do if byMap[q.map] then table.insert(byMap[q.map], q) end end
	for _, mapId in ipairs({"forest", "village", "domaine"}) do
		local lines = {}
		for _, q in ipairs(byMap[mapId]) do
			local m = workspace:FindFirstChild(q.id .. "_color", true) or workspace:FindFirstChild(q.id, true)
			local lo, hi; if m then lo, hi = extents(m) end   -- (runner 7's fix: `m and extents(m)` kept only the first return)
			table.insert(lines, string.format("%s %s", q.id, lo and string.format("(%.0f,%.0f,%.0f)", (lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2) or "(no model)"))
		end
		say("%s squirrels (%d): %s", mapId, #byMap[mapId], table.concat(lines, "; "))
	end
else say("SquirrelRegistry not readable") end

-- ---------- (4) the gates ----------
local B = workspace:FindFirstChild("Boundary")
local gates = B and B:FindFirstChild("Gates")
if gates then
	for _, g in ipairs(gates:GetChildren()) do
		local lo, hi = extents(g)
		say("gate %s: box %s..%s attrs NeedMap=%s To=%s", g.Name, lo and v3(lo) or "-", hi and v3(hi) or "-", tostring(g:GetAttribute("NeedMap")), tostring(g:GetAttribute("ToName")))
	end
else say("Boundary.Gates not found") end
for _, s in ipairs({{"village", 196, -36}, {"domaine", 438, -36}}) do
	local y, what = groundAt(s[2], s[3])
	say("%s spawn (%d, %d): ground %s (%s)", s[1], s[2], s[3], y and string.format("%.1f", y) or "none", what)
end

-- ---------- (5) the ground round the spawn ----------
for _, r in ipairs({12, 24, 40}) do
	local parts = {}
	for i = 0, 7 do
		local a = i * math.pi / 4
		local x, z = SX + r * math.sin(a), SZ + r * math.cos(a)
		local y, what = groundAt(x, z)
		table.insert(parts, string.format("(%.0f,%.0f) %s %s", x, z, y and string.format("%.1f", y) or "none", what))
	end
	say("ring r %d: %s", r, table.concat(parts, " | "))
end
-- paths near the spawn (parts named like a path or trail)
local paths = 0
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") then
		local n = p.Name:lower()
		if (n:find("path") or n:find("trail") or n:find("road")) and (p.Position - Vector3.new(SX, p.Position.Y, SZ)).Magnitude < 60 then
			paths += 1
			if paths <= 12 then say("path part %s at %s size %s", p:GetFullName():gsub("^Workspace%.", ""), v3(p.Position), v3(p.Size)) end
		end
	end
end
say("path-like parts within 60 studs of the spawn: %d", paths)
for _, l in ipairs(out) do print(l) end
print(string.format("QQ TREE END (%d lines)", #out))

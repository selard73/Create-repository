-- survey111.lua - READ-ONLY (Studio EDIT). Job 111 (Shannon, Oct 15 2026: "the treehouse is too close to everything else and it's too
-- crowded; put it in a corner to the left of the zip line tower; clear a space of trees and rocks and mushrooms; an open area clearly
-- designated for the treehouse"). Finds the forest tower, works out "left of it" as seen from the forest spawn, and for three candidate
-- centres reports the ground (flat? terrain material?) and everything within 30 studs that a clearing would remove (kit trees, rocks,
-- mushrooms, bushes - anything with the forest's Scatter attribute or a kit name) and everything it must NOT touch (squirrels, walls,
-- the tower, paths). Prints "QQ SITE ..." lines; send them all unchanged.
local out = {}
local function say(fmt, ...) table.insert(out, "QQ SITE " .. string.format(fmt, ...)) end
local function path(o) return (o:GetFullName():gsub("^Workspace%.", "")) end
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
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {workspace.Terrain}
local function ground(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0))
	local t = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	return h and h.Position.Y or nil, h and (h.Instance == workspace.Terrain and ("terrain " .. h.Material.Name) or h.Instance.Name) or "nothing", t and t.Position.Y or nil
end
local T = workspace:FindFirstChild("ForestTower")
if not T then print("QQ SITE ABORT - no workspace.ForestTower") return end
local tlo, thi = extents(T:GetDescendants())
local tc = Vector3.new((tlo.X + thi.X) / 2, 0, (tlo.Z + thi.Z) / 2)
local spawn = Vector3.new(3, 0, 1)
local f = (tc - spawn); f = Vector3.new(f.X, 0, f.Z).Unit
local left = Vector3.new(f.Z, 0, -f.X)                                -- left of the facing direction, as a player at the spawn sees the tower
say("ForestTower box %s..%s, centre (%.0f, %.0f); the spawn looks at it along (%.2f, %.2f); LEFT of it is (%.2f, %.2f)", tostring(tlo), tostring(thi), tc.X, tc.Z, f.X, f.Z, left.X, left.Z)
-- the forest's bounds: the boundary walls (parts taller than 40 studs) around here
local walls = {}
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and p.Size.Y > 40 and (p.Position - tc).Magnitude < 160 then table.insert(walls, string.format("%s at (%.0f,%.0f) size %.0fx%.0f", p.Name, p.Position.X, p.Position.Z, p.Size.X, p.Size.Z)) end
end
say("tall walls within 160 studs of the tower: %s", #walls > 0 and table.concat(walls, "; ") or "none")
local KIT = {"pine", "tree", "oak", "birch", "fir", "rock", "boulder", "mushroom", "bush", "shrub", "flower", "fern", "grass_tuft", "log", "stump"}
local function isScatter(m)
	if m:GetAttribute("Scatter") ~= nil then return true end
	local n = m.Name:lower()
	for _, w in ipairs(KIT) do if n:find(w, 1, true) then return true end end
	return false
end
local function isSacred(m)
	local n = m.Name:lower()
	return n:find("squirrel") or n:find("_color") or n:find("tower") or n:find("spawn") or n:find("wall") or n:find("gate") or n:find("path") or n:find("bridge") or n:find("race") or n:find("sign")
end
local candidates = {
	{"A: 45 left of the tower", tc + left * 45},
	{"B: 60 left of the tower", tc + left * 60},
	{"C: 45 left, 15 behind", tc + left * 45 - f * 15},
	{"D: 45 left, 15 nearer the spawn", tc + left * 45 + f * 15},
}
local seen = {}
for _, c in ipairs(candidates) do
	local cx, cz = c[2].X, c[2].Z
	local gy, gwhat, ty = ground(cx, cz)
	local lows, highs, mats = 1e9, -1e9, {}
	for r = 0, 24, 8 do
		for i = 0, 7 do
			local a = i * math.pi / 4
			local y, what = ground(cx + r * math.sin(a), cz + r * math.cos(a))
			if y then lows = math.min(lows, y); highs = math.max(highs, y) end
			mats[what] = (mats[what] or 0) + 1
		end
	end
	local ml = {}
	for k, v in pairs(mats) do table.insert(ml, k .. " " .. v) end
	table.sort(ml)
	say("%s: centre (%.0f, %.0f), %.0f studs from the spawn, ground %s (%s); over a 24-stud radius the ground runs y %.1f..%.1f; hits: %s", c[1], cx, cz, (Vector3.new(cx, 0, cz) - spawn).Magnitude, gy and string.format("%.1f", gy) or "none", gwhat, lows, highs, table.concat(ml, ", "))
	local clear, keep = {}, {}
	for _, m in ipairs(workspace:GetDescendants()) do
		if (m:IsA("Model") or (m:IsA("BasePart") and m.Parent and not m.Parent:IsA("Model"))) and not m:IsA("Terrain") then
			local lo, hi = m:IsA("Model") and extents(m:GetDescendants()) or (m.Position - m.Size / 2), (m:IsA("Model") and nil or (m.Position + m.Size / 2))
			if m:IsA("Model") then lo, hi = extents(m:GetDescendants()) end
			if lo and hi then
				local mx, mz = (lo.X + hi.X) / 2, (lo.Z + hi.Z) / 2
				local d = math.sqrt((mx - cx) ^ 2 + (mz - cz) ^ 2)
				if d <= 30 and (hi.Y - lo.Y) > 0.5 and (hi.X - lo.X) < 60 then
					local line = string.format("%s (%.0f,%.0f) %.0fx%.0f, %.0f studs out", path(m), mx, mz, hi.X - lo.X, hi.Z - lo.Z, d)
					if isSacred(m) then table.insert(keep, line) elseif isScatter(m) then table.insert(clear, line) else table.insert(keep, "? " .. line) end
				end
			end
		end
	end
	say("  would clear (%d): %s", #clear, #clear > 0 and table.concat(clear, " | ", 1, math.min(25, #clear)) .. (#clear > 25 and " | ..." or "") or "nothing")
	say("  must keep / unsure (%d): %s", #keep, #keep > 0 and table.concat(keep, " | ", 1, math.min(15, #keep)) .. (#keep > 15 and " | ..." or "") or "nothing")
end
for _, l in ipairs(out) do print(l) end
print(string.format("QQ SITE END (%d lines)", #out))
return table.concat(out, "\n")

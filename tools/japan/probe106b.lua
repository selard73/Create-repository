-- probe106b.lua - READ-ONLY (Studio EDIT). For geo round 2 (runner 7's three findings after japan_geo1): (1) the sea's bed depth where
-- Codex's basin is, versus our fill - the "paler rectangle" is a depth change; (2) the canal's north end - the channel bed beyond the
-- water's end, so the water can continue or end at a weir; (3) the lake stair's parts, for CastShadow; (4) anything standing at the
-- horizon north/east. Prints "QQ GEO2 ..." lines; send them unchanged.
local T = workspace.Terrain
local rpW = RaycastParams.new(); rpW.FilterType = Enum.RaycastFilterType.Exclude; rpW.IgnoreWater = true
local function bed(x, z)
	local w = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0))
	local g = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rpW)
	local water = w and w.Instance == T and w.Material == Enum.Material.Water and w.Position.Y or nil
	return water, g and g.Position.Y or nil, g and (g.Instance == T and ("terrain " .. g.Material.Name) or g.Instance.Name) or "nothing"
end
local out = {}
local function say(fmt, ...) table.insert(out, "QQ GEO2 " .. string.format(fmt, ...)) end
-- (1) the bed, on a 60-stud grid over the sea north and east of the island
local rows = {}
for z = 300, 900, 60 do
	local cells = {}
	for x = 6400, 7400, 60 do
		local w, g, what = bed(x, z)
		table.insert(cells, string.format("%s/%s", w and string.format("%.0f", w) or "-", g and string.format("%.0f", g) or "-"))
	end
	say("bed z %d: %s   (water level / bed y, x 6400..7400 every 60)", z, table.concat(cells, " "))
end
-- (2) the canal's north end: along x 6092 (and 6104) from z -200 to -340
for _, x in ipairs({6092, 6104}) do
	local cells = {}
	for z = -200, -340, -8 do
		local w, g, what = bed(x, z)
		table.insert(cells, string.format("z%d %s/%s %s", z, w and string.format("%.1f", w) or "-", g and string.format("%.1f", g) or "-", what:sub(1, 18)))
	end
	say("canal x %d: %s", x, table.concat(cells, " | "))
end
-- (3) the lake stair
local J = workspace:FindFirstChild("JapanMap")
for _, p in ipairs(J and J:GetDescendants() or {}) do
	if p:IsA("BasePart") and p.Name == "Continuous underwater stair support" then
		local m = p.Parent
		local names = {}
		for _, q in ipairs(m:GetChildren()) do if q:IsA("BasePart") then table.insert(names, q.Name .. (q.CastShadow and "*" or "")) end end
		say("lake stair model %s at %s: parts (* = casts shadow): %s", m:GetFullName(), tostring(p.Position), table.concat(names, ", ", 1, math.min(20, #names)))
		break
	end
end
-- (4) parts at the horizon: anything in JapanMap with x > 7000 or z > 700 (not the wall)
local far = {}
for _, p in ipairs(J and J:GetDescendants() or {}) do
	if p:IsA("BasePart") and p.Name ~= "JapanSeaWall" and (p.Position.X > 7000 or p.Position.Z > 700) then
		if #far < 12 then table.insert(far, string.format("%s at (%.0f,%.0f,%.0f) size (%.0f,%.0f,%.0f)", p:GetFullName():gsub("^Workspace%.JapanMap%.", ""), p.Position.X, p.Position.Y, p.Position.Z, p.Size.X, p.Size.Y, p.Size.Z)) end
	end
end
say("parts out at the horizon (x > 7000 or z > 700): %d%s", #far, #far > 0 and (" - " .. table.concat(far, "; ")) or "")
say("Terrain.WaterColor %s, Lighting FogEnd %.0f", tostring(T.WaterColor), game:GetService("Lighting").FogEnd)
for _, l in ipairs(out) do print(l) end
print("QQ GEO2 END")
return table.concat(out, "\n")

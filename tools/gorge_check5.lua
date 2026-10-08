-- gorge_check5: READ-ONLY. (a) terrain heights (ground and water) at reference points, to compare with the model;
-- (b) terrain standing in front of the CLIFF faces: for each arm, a ray every 2 studs along it and every stud of
-- height, cast from 10 studs in front of the face toward it; a hit more than 1.8 studs short of the face (the
-- relief stands out up to 1.5) is terrain in front of the rock. The sill face under the lip the same way.
local ZC, CXE, XCW, XCE = -547.5, 183.8438, 169.4583, 201.2856
local ARM_L, COVE_A, COVE_L, PLAIN_Y, SEA_Y, RR = 130.0, 40.0, 110.0, -48.0, -52.9, 1.4
local T0 = 40.7189
local function ss(e0, e1, x) local t = math.clamp((x - e0) / (e1 - e0), 0, 1) return t * t * (3 - 2 * t) end
local function cove(a)
	local sc = 4 * math.sin(a / 6.4 + 1.1) * ss(6, 30, a) * (1 - ss(ARM_L - 40, ARM_L - 10, a))
	return COVE_A * ss(0, COVE_L, a) + sc
end
local function arm_lean(a, y)
	local e = 0.44 * ss(ARM_L - 30, ARM_L, a)
	return 0.16 * ss(0, 45, a) * math.max(y, 0) + e * math.max(y - PLAIN_Y, 0)
end
local function cliff_T(a) return T0 + 2.6 * math.sin(a / 23) + 1.1 * math.sin(a / 9.5) + 2 * ss(20, 110, a) end
local solid = RaycastParams.new(); solid.FilterType = Enum.RaycastFilterType.Include; solid.FilterDescendantsInstances = {workspace.Terrain}; solid.IgnoreWater = true
local wet = RaycastParams.new(); wet.FilterType = Enum.RaycastFilterType.Include; wet.FilterDescendantsInstances = {workspace.Terrain}; wet.IgnoreWater = false
-- (a) heights (model: 183.8,-600 -> bed -58.93 water -52.9 | 240,-600 -> -48.73 | 120,-620 -> -47.07 | 400,-700 -> -53.09 water | -300,-650 -> -48.43 | 183.8,-900 -> -61.90 water)
local pts = {{183.8, -600}, {240, -600}, {120, -620}, {400, -700}, {-300, -650}, {183.8, -900}, {60, -575}, {320, -575}, {30, -600}, {340, -600}, {183.8, -552}, {183.8, -620}, {700, -620}, {-700, -620}, {90, -560}, {280, -560}}
local hs = {}
for _, p in ipairs(pts) do
	local g = workspace:Raycast(Vector3.new(p[1], 130, p[2]), Vector3.new(0, -220, 0), solid)
	local w = workspace:Raycast(Vector3.new(p[1], 130, p[2]), Vector3.new(0, -220, 0), wet)
	local gy = g and string.format("%.1f", g.Position.Y) or "none"
	local wy = (w and g and w.Position.Y > g.Position.Y + 0.05) and string.format(" water %.1f", w.Position.Y) or ""
	local mat = g and g.Material.Name or "-"
	hs[#hs + 1] = string.format("%.0f,%.0f: %s %s%s", p[1], p[2], gy, mat, wy)
end
print("QQ C5 H " .. table.concat(hs, " | "))
-- (b) the faces
local n, worst, out, rays = 0, 0, {}, 0
for s = -1, 1, 2 do
	for a = 1, ARM_L - 1, 2 do
		local x = (s < 0 and XCW or XCE) + s * a
		local zc = ZC - cove(a)
		local slope = (cove(a + 0.5) - cove(math.max(a - 0.5, 0))) / (0.5 + math.min(a, 0.5))
		local tx, tz = s, -slope
		local ln = math.sqrt(tx * tx + tz * tz); tx, tz = tx / ln, tz / ln
		local nx, nz = s * tz, -s * tx
		local T = cliff_T(a)
		for y = PLAIN_Y + 1, T - 1, 1 do
			local lean = arm_lean(a, y)
			local origin = Vector3.new(x + nx * 10, y, zc + nz * 10)
			local r = workspace:Raycast(origin, Vector3.new(-nx, 0, -nz) * (10 + lean + 3.5), solid)
			rays += 1
			if r then
				local infront = (10 + lean) - (r.Position - origin).Magnitude
				if infront > 1.8 then
					n += 1; if infront > worst then worst = infront end
					if #out < 14 then out[#out + 1] = string.format("%s a%.0f y%.0f +%.1f", s < 0 and "W" or "E", a, y, infront) end
				end
			end
		end
	end
end
local nl, worstl = 0, 0
for x = XCW + 1, XCE - 1, 2 do
	for y = -57, -4, 1 do
		local origin = Vector3.new(x, y, ZC - 10)
		local r = workspace:Raycast(origin, Vector3.new(0, 0, 12), solid)
		rays += 1
		if r then
			local infront = 10 - (r.Position - origin).Magnitude
			if infront > 1.2 then nl += 1; if infront > worstl then worstl = infront end end
		end
	end
end
print(string.format("QQ C5 faces: %d rays; arms: %d pokes worst %.2f | lip: %d pokes worst %.2f | first: %s", rays, n, worst, nl, worstl, table.concat(out, ", ")))
print("QQ C5 DONE")

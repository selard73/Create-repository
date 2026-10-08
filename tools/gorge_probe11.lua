-- gorge_probe11: READ-ONLY. Where is each tree REALLY (its parts' world bounding box) versus its pivot? And does its
-- lowest point sit on the ground under the box's centre (terrain / rock, water ignored)? Histograms + worst cases.
local F = workspace.SouthGorge.Trees
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = {workspace.Terrain, workspace.SouthGorge.Rock}; rp.IgnoreWater = true
local function box(m)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local cf, s = p.CFrame, p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local q = (cf * CFrame.new(sx * s.X, sy * s.Y, sz * s.Z)).Position
				lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
				hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
			end end end
		end
	end
	return lo, hi
end
local offs = {near = 0, off1 = 0, off5 = 0, far = 0}
local seat = {sunk = 0, low = 0, ok = 0, high = 0, float = 0, air = 0, noground = 0}
local worst, farlist = {}, {}
for _, m in ipairs(F:GetChildren()) do
	local lo, hi = box(m)
	local c = (lo + hi) / 2
	local piv = m:GetPivot().Position
	local d = (Vector3.new(piv.X, 0, piv.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude
	local k = (d < 1) and "near" or (d < 5) and "off1" or (d < 40) and "off5" or "far"
	offs[k] += 1
	if d >= 5 and #farlist < 8 then farlist[#farlist + 1] = string.format("%s box(%.0f,%.0f) pivot(%.0f,%.0f) d %.0f", m.Name, c.X, c.Z, piv.X, piv.Z, d) end
	local r = workspace:Raycast(Vector3.new(c.X, lo.Y + 40, c.Z), Vector3.new(0, -200, 0), rp)
	if not r then seat.noground += 1
	else
		local dy = lo.Y - r.Position.Y
		local kk = (dy < -1.5) and "sunk" or (dy < -0.3) and "low" or (dy <= 0.3) and "ok" or (dy <= 1.5) and "high" or (dy <= 4) and "float" or "air"
		seat[kk] += 1
		if math.abs(dy) > 1.5 and #worst < 10 then worst[#worst + 1] = string.format("%s@(%.0f,%.0f) base %.1f ground %.1f d %+.1f", m.Name, c.X, c.Z, lo.Y, r.Position.Y, dy) end
	end
end
print(string.format("QQ P11 trees %d | pivot vs box: near(<1) %d, 1-5 %d, 5-40 %d, far %d | seating at the box centre: sunk %d low %d ok %d high %d float %d air %d noground %d", #F:GetChildren(), offs.near, offs.off1, offs.off5, offs.far, seat.sunk, seat.low, seat.ok, seat.high, seat.float, seat.air, seat.noground))
print("QQ P11 far pivots: " .. table.concat(farlist, "; "))
print("QQ P11 worst seating: " .. table.concat(worst, "; "))
print("QQ P11 DONE")

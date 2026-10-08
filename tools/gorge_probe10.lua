-- gorge_probe10: READ-ONLY. Are the trees really standing on the ground? For every tree in workspace.SouthGorge.Trees:
-- the lowest world-space corner of any of its parts, the ground under its pivot (terrain or the rock's top), and the
-- difference. Histogram + the worst cases + whether any pivot is tilted (not just turned about y).
local F = workspace.SouthGorge.Trees
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = {workspace.Terrain, workspace.SouthGorge.Rock}; rp.IgnoreWater = true
local function minY(m)
	local best = math.huge
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local cf, s = p.CFrame, p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local y = (cf * CFrame.new(sx * s.X, sy * s.Y, sz * s.Z)).Position.Y
				if y < best then best = y end
			end end end
		end
	end
	return best
end
local bins = {sunk = 0, low = 0, ok = 0, high = 0, float = 0, air = 0, noground = 0}
local worst, tilted = {}, 0
for _, m in ipairs(F:GetChildren()) do
	local piv = m:GetPivot()
	local rx, ry, rz = piv:ToOrientation()
	if math.abs(rx) > 0.05 or math.abs(rz) > 0.05 then tilted += 1 end
	local base = minY(m)
	local r = workspace:Raycast(Vector3.new(piv.Position.X, base + 40, piv.Position.Z), Vector3.new(0, -160, 0), rp)
	if not r then bins.noground += 1
	else
		local d = base - r.Position.Y
		local k = (d < -1.5) and "sunk" or (d < -0.3) and "low" or (d <= 0.3) and "ok" or (d <= 1.5) and "high" or (d <= 4) and "float" or "air"
		bins[k] += 1
		if math.abs(d) > 1.5 and #worst < 12 then worst[#worst + 1] = string.format("%s@(%.0f,%.0f) base %.1f ground %.1f (%s) d %+.1f", m.Name, piv.Position.X, piv.Position.Z, base, r.Position.Y, r.Instance.Name, d) end
	end
end
print(string.format("QQ P10 trees %d: sunk(<-1.5) %d, low %d, ok(+-0.3) %d, high %d, float(1.5..4) %d, air(>4) %d, no ground %d | tilted pivots %d", #F:GetChildren(), bins.sunk, bins.low, bins.ok, bins.high, bins.float, bins.air, bins.noground, tilted))
print("QQ P10 worst: " .. table.concat(worst, "; "))
print("QQ P10 DONE")

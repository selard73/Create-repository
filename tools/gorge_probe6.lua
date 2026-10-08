-- gorge_probe6: READ-ONLY. Fine terrain slice across the west rim's top strip (1 stud) vs the rock strip's own height.
local S = {{-296.0,176.25,25.16,42.99,{42.93,42.99,42.96,42.89,42.76,42.59,42.36,42.09,41.76,41.39,40.96,40.49,40.49,40.49}},{-300.0,173.50,23.82,43.16,{43.10,43.16,43.14,43.06,42.94,42.76,42.54,42.26,41.94,41.56,41.14,40.66,40.66,40.66}},{-304.0,169.50,24.19,43.34,{43.28,43.34,43.31,43.24,43.11,42.94,42.71,42.44,42.11,41.74,41.31,40.84,40.84,40.84}}}
local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {workspace.Terrain}; tp.IgnoreWater = true
for _, r in ipairs(S) do
	local z, cx, rim, T, strip = r[1], r[2], r[3], r[4], r[5]
	local out = {}
	for k, e in ipairs({-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}) do
		local x = cx - (rim + e)
		local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), tp)
		out[#out + 1] = string.format("e%d:g%s/r%s", e, hit and string.format("%.2f", hit.Position.Y) or "-", strip[k])
	end
	print("QQ G6 z " .. z .. " T " .. T .. " | " .. table.concat(out, " "))
end
print("QQ G6 DONE")

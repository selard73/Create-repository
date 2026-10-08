-- gorge_check2: READ-ONLY. Terrain cross-sections across the gorge (top solid surface every stud). Nothing is changed.
local S = {{-236.0,179.62},{-250.0,188.25},{-308.0,164.25},{-372.0,110.34},{-400.0,112.77},{-408.0,119.19},{-524.0,196.50},{-540.0,188.50}}
local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {workspace.Terrain}; tp.IgnoreWater = true
for _, r in ipairs(S) do
	local z, cx = r[1], r[2]
	local hs = {}
	for dx = -46, 46, 1 do
		local hit = workspace:Raycast(Vector3.new(cx + dx, 150, z), Vector3.new(0, -300, 0), tp)
		hs[#hs + 1] = hit and string.format("%.1f", hit.Position.Y) or "-"
	end
	print("QQ C2 XS " .. z .. " " .. cx .. " " .. table.concat(hs, ","))
end
print("QQ C2 DONE")

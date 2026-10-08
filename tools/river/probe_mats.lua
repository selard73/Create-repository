-- v54 read-only: materials + occupancy of the cells across the forest bank at z -98 (x 132..152) and the gallery edge z -8
local T = workspace.Terrain
for _, s in ipairs({{132, -100}, {176, -12}}) do
	local reg = Region3.new(Vector3.new(s[1], -8, s[2]), Vector3.new(s[1] + 24, 4, s[2] + 4))
	local c = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
	for ix = 1, 6 do
		local t = {}
		for iy = 1, 3 do t[#t + 1] = string.format("%s%.2f/L%.2f", c.SolidMaterial[ix][iy][1].Name:sub(1, 4), c.SolidOccupancy[ix][iy][1], c.LiquidOccupancy[ix][iy][1]) end
		print("QQ mc", s[2], s[1] + (ix - 1) * 4, table.concat(t, " "))
	end
end

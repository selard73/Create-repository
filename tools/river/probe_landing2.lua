-- v29 read-only: terrain cells y -4..8 across the bridge's east landing
local T = workspace.Terrain
local reg = Region3.new(Vector3.new(160, -4, -128), Vector3.new(176, 8, -112))
local c = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
for ix = 1, 4 do for iz = 1, 4 do
	local t = {}
	for iy = 1, 3 do t[#t + 1] = string.format("%s%.2f/L%.2f", c.SolidMaterial[ix][iy][iz].Name:sub(1, 4), c.SolidOccupancy[ix][iy][iz], c.LiquidOccupancy[ix][iy][iz]) end
	print("QQ lc", 160 + (ix - 1) * 4, -128 + (iz - 1) * 4, table.concat(t, " "))
end end

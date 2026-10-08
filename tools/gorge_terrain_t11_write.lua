-- gorge_terrain_t11 WRITE: CHANGES THE PLACE (small): in the last terrain row north of the gorge's corners
-- (cells z -548..-544) and only across the lip and its corners (x 159.5..211.3), empties the cells below the river
-- bed (y -16..-8). A full voxel cell's rendered surface reaches ~2 studs past its boundary, so that substrate stood
-- 2.5 studs in front of the sill face under the lip (gorge_check5). The bed's own cell stays; the sill mesh covers it.
local T = workspace.Terrain
local X0, X1 = 159.5, 211.3
local region = Region3.new(Vector3.new(math.floor(X0 / 4) * 4, -16, -548), Vector3.new(math.ceil(X1 / 4) * 4, -8, -544))
local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy", "Material"})
local so, lo = ch.SolidOccupancy, ch.LiquidOccupancy
local n, had = 0, 0
for ix = 1, ch.Size.X do
	local x = math.floor(X0 / 4) * 4 + (ix - 0.5) * 4
	if x > X0 and x < X1 then
		for iy = 1, ch.Size.Y do
			for iz = 1, ch.Size.Z do
				if so[ix][iy][iz] > 0 then had += 1 end
				so[ix][iy][iz] = 0; lo[ix][iy][iz] = 0; n += 1
			end
		end
	end
end
T:WriteVoxelChannels(region, 4, {SolidOccupancy = so, LiquidOccupancy = lo, Material = ch.Material})
print(string.format("QQ T11 WROTE: emptied %d substrate cells (%d were solid) in the row z -548..-544, y -16..-8, x %.1f..%.1f", n, had, X0, X1))
print("QQ T11 DONE")

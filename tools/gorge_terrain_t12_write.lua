-- gorge_terrain_t12 WRITE: CHANGES THE PLACE (small): in the last terrain row before the brink (cells z -548..-544),
-- the river banks' last 4 studs on each side of the corners (x within 12 studs outside each corner, y -8..8) come out.
-- Their rendered surface reached ~2.5 studs south of the corner line, in front of the cliff arms' faces: brown-grey
-- lumps beside the falls when seen from the pool (falls close-up, Sep 30 21:40). Behind the walls' faces they were
-- never visible from the river. Water cells are left as they are.
local T = workspace.Terrain
local XCW, XCE = 169.4583, 201.2856
local ranges = {{XCW - 12, XCW + 0.5}, {XCE - 0.5, XCE + 12}}
local n, had = 0, 0
for _, r in ipairs(ranges) do
	local x0, x1 = math.floor(r[1] / 4) * 4, math.ceil(r[2] / 4) * 4
	local region = Region3.new(Vector3.new(x0, -8, -548), Vector3.new(x1, 8, -544))
	local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "LiquidOccupancy", "Material"})
	local so = ch.SolidOccupancy
	for ix = 1, ch.Size.X do
		local x = x0 + (ix - 0.5) * 4
		if x > r[1] and x < r[2] then
			for iy = 1, ch.Size.Y do
				for iz = 1, ch.Size.Z do
					if so[ix][iy][iz] > 0 then had += 1 end
					so[ix][iy][iz] = 0; n += 1
				end
			end
		end
	end
	T:WriteVoxelChannels(region, 4, {SolidOccupancy = so, LiquidOccupancy = ch.LiquidOccupancy, Material = ch.Material})
end
print(string.format("QQ T12 WROTE: emptied %d bank cells (%d were solid) in the row z -548..-544, y -8..8, beside the corners", n, had))
print("QQ T12 DONE")

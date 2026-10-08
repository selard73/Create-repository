-- gorge_probe7: READ-ONLY. The terrain cells round a few spots where terrain still pokes through the rock face:
-- occupancy and material per 4-stud cell, with the cell centre's distance from the river centre and the rock face there.
local T = workspace.Terrain
local S = {{-466.0,1,175.88,21.94,40.36,{[26]=20.54,[27]=21.46,[28]=20.70,[29]=20.47,[30]=21.54,[31]=21.08,[32]=21.44,[33]=21.20,[34]=21.28,[35]=21.72,[36]=21.76,[37]=24.66,[38]=21.19,[39]=20.51,[40]=21.08}},{-322.0,-1,148.31,22.93,42.81,{[26]=19.77,[27]=20.79,[28]=19.95,[29]=19.70,[30]=20.08,[31]=19.70,[32]=20.15,[33]=20.02,[34]=20.21,[35]=21.33,[36]=21.26,[37]=23.33,[38]=20.76,[39]=21.26,[40]=21.85,[41]=22.07,[42]=24.25}},{-412.0,-1,121.87,23.66,39.80,{[26]=21.28,[27]=22.44,[28]=21.36,[29]=21.02,[30]=21.62,[31]=21.46,[32]=22.22,[33]=22.03,[34]=22.32,[35]=22.88,[36]=23.08,[37]=25.16,[38]=22.52,[39]=21.96}}}
for _, r in ipairs(S) do
	local z, s, cx, rim, top, fd = r[1], r[2], r[3], r[4], r[5], r[6]
	local x0 = math.floor((cx + s * (rim - 8)) / 4) * 4
	local x1 = math.floor((cx + s * (rim + 12)) / 4) * 4
	if x0 > x1 then x0, x1 = x1, x0 end
	local zc = math.floor(z / 4) * 4
	local region = Region3.new(Vector3.new(x0, 24, zc - 4), Vector3.new(x1 + 4, 48, zc + 4))
	local ch = T:ReadVoxelChannels(region, 4, {"SolidOccupancy", "Material"})
	local so, ma = ch.SolidOccupancy, ch.Material
	local out = {}
	for ix = 1, ch.Size.X do
		local x = x0 + (ix - 0.5) * 4
		local d = math.abs(x - cx) * ((x - cx) * s >= 0 and 1 or -1)      -- negative = on the river side of the centre line
		local col = {}
		for iy = 1, ch.Size.Y do
			local yc = 24 + (iy - 0.5) * 4
			local occ = so[ix][iy][2]
			if occ > 0.01 then col[#col + 1] = string.format("y%d:%.2f%s", yc, occ, ma[ix][iy][2].Name:sub(1, 2)) end
		end
		local f37 = fd[37] or -1
		out[#out + 1] = string.format("[d=%.1f rim%+.1f face37%+.1f: %s]", d, d - rim, d - f37, #col > 0 and table.concat(col, " ") or "empty")
	end
	print(string.format("QQ G7 z %.0f side %d cx %.1f rim %.1f T %.1f face@37 %.2f face@33 %.2f | %s", z, s, cx, rim, top, fd[37] or -1, fd[33] or -1, table.concat(out, " ")))
end
print("QQ G7 DONE")

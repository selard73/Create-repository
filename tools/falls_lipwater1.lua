-- falls_lipwater1 v1 (EDIT, temporary): is the stray sheet the river's own terrain water (its side face exposed at the west
-- corner)? Makes the terrain water fully transparent for 2.5 s (then back), and prints the voxel materials around the west
-- corner of the lip at two depths (4-stud cells; W water, S sandstone, . air, other = first letter).
local T = workspace.Terrain
local wt = T.WaterTransparency
print("QQ LW water transparent for 2.5 s (was " .. tostring(wt) .. ")")
T.WaterTransparency = 1
task.wait(2.5)
T.WaterTransparency = wt
print("QQ LW water back")
local region = Region3.new(Vector3.new(152, -14, -560), Vector3.new(184, 2, -536)):ExpandToGrid(4)
local mats, occ = T:ReadVoxels(region, 4)
local size = mats.Size
local function ch(m)
	if m == Enum.Material.Water then return "W" elseif m == Enum.Material.Air then return "." elseif m == Enum.Material.Sandstone then return "S" else return m.Name:sub(1, 1) end
end
local x0, y0, z0 = region.CFrame.Position.X - region.Size.X / 2, region.CFrame.Position.Y - region.Size.Y / 2, region.CFrame.Position.Z - region.Size.Z / 2
print(string.format("QQ LW cells x %d (from %.0f) y %d (from %.0f) z %d (from %.0f)", size.X, x0, size.Y, y0, size.Z, z0))
for y = 1, size.Y do
	local rows = {}
	for z = 1, size.Z do
		local row = {}
		for x = 1, size.X do row[#row + 1] = ch(mats[x][y][z]) end
		rows[#rows + 1] = string.format("z%.0f:%s", z0 + (z - 1) * 4, table.concat(row))
	end
	print(string.format("QQ LW y %.0f | %s", y0 + (y - 1) * 4, table.concat(rows, " ")))
end
print("QQ LW DONE")

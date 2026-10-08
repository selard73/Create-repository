-- v58 test: which materials stick in that column? try each, read back, then leave it Grass as it was
local T = workspace.Terrain
local reg = Region3.new(Vector3.new(140, -8, -100), Vector3.new(144, 0, -96))
local c = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
local o1, o2, l1, l2 = c.SolidOccupancy[1][1][1], c.SolidOccupancy[1][2][1], c.LiquidOccupancy[1][1][1], c.LiquidOccupancy[1][2][1]
local function try(m)
	T:WriteVoxelChannels(reg, 4, {SolidMaterial = {{{m}, {m}}}, SolidOccupancy = {{{o1}, {o2}}}, LiquidOccupancy = {{{l1}, {l2}}}})
	local d = T:ReadVoxelChannels(reg, 4, {"SolidMaterial"})
	return d.SolidMaterial[1][2][1].Name
end
local t = {}
for _, m in ipairs({"Pebble", "Sand", "Mud", "Ground", "Rock", "Slate", "Grass"}) do t[#t + 1] = m .. "->" .. try(Enum.Material[m]) end
print("QQ tries", table.concat(t, " "))
-- and with liquid 0 in the cell
local t2 = {}
for _, m in ipairs({"Pebble", "Sand"}) do
	T:WriteVoxelChannels(reg, 4, {SolidMaterial = {{{Enum.Material[m]}, {Enum.Material[m]}}}, SolidOccupancy = {{{o1}, {o2}}}, LiquidOccupancy = {{{0}, {0}}}})
	t2[#t2 + 1] = m .. "->" .. T:ReadVoxelChannels(reg, 4, {"SolidMaterial"}).SolidMaterial[1][2][1].Name
end
print("QQ tries noWater", table.concat(t2, " "))
T:WriteVoxelChannels(reg, 4, {SolidMaterial = {{{Enum.Material.Grass}, {Enum.Material.Grass}}}, SolidOccupancy = {{{o1}, {o2}}}, LiquidOccupancy = {{{l1}, {l2}}}})

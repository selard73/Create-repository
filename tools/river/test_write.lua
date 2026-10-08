-- v57 test: write Pebble into the one column (140..144, -100..-96) keeping its occupancy, read it back now and 2 s later
local T = workspace.Terrain
local reg = Region3.new(Vector3.new(140, -8, -100), Vector3.new(144, 0, -96))
local c = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
print("QQ before", c.SolidMaterial[1][1][1].Name, c.SolidMaterial[1][2][1].Name, c.SolidOccupancy[1][2][1])
local sm = {{{Enum.Material.Pebble}, {Enum.Material.Pebble}}}
local so = {{{c.SolidOccupancy[1][1][1]}, {c.SolidOccupancy[1][2][1]}}}
local lq = {{{c.LiquidOccupancy[1][1][1]}, {c.LiquidOccupancy[1][2][1]}}}
T:WriteVoxelChannels(reg, 4, {SolidMaterial = sm, SolidOccupancy = so, LiquidOccupancy = lq})
local d = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy"})
print("QQ after", d.SolidMaterial[1][1][1].Name, d.SolidMaterial[1][2][1].Name, d.SolidOccupancy[1][2][1])
task.wait(2)
local e = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy"})
print("QQ later", e.SolidMaterial[1][1][1].Name, e.SolidMaterial[1][2][1].Name, e.SolidOccupancy[1][2][1])

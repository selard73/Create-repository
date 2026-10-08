-- v13 read-only: cross-section of the terrain surface across the east bank at the spy (z -114.5) and at the painter (z -20)
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local T = workspace.Terrain
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {T}; rp.IgnoreWater = true
local rw = RaycastParams.new(); rw.FilterType = Enum.RaycastFilterType.Include; rw.FilterDescendantsInstances = {T}; rw.IgnoreWater = false
for _, z in ipairs({-114.5, -20, -60}) do
	local t = {}
	for x = 140, 200, 2 do
		local h = workspace:Raycast(Vector3.new(x, 10, z), Vector3.new(0, -30, 0), rp)
		local w = workspace:Raycast(Vector3.new(x, 10, z), Vector3.new(0, -30, 0), rw)
		t[#t + 1] = x .. ":" .. (h and string.format("%.1f%s", h.Position.Y, h.Material.Name:sub(1, 2)) or "-") .. (w and w.Material == Enum.Material.Water and string.format("w%.1f", w.Position.Y) or "")
	end
	P("sec", z, table.concat(t, " "))
end
local x, z = 164, -116
local c = T:ReadVoxelChannels(Region3.new(Vector3.new(x - 8, -8, z), Vector3.new(x + 12, 8, z + 4)), 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
for ix = 1, 5 do
	local t = {}
	for iy = 1, 4 do t[#t + 1] = string.format("%s%.2f/L%.2f", c.SolidMaterial[ix][iy][1].Name:sub(1, 2), c.SolidOccupancy[ix][iy][1], c.LiquidOccupancy[ix][iy][1]) end
	P("col", x - 8 + (ix - 1) * 4, table.concat(t, " "))
end
P("DONE13")

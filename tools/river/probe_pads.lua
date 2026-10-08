-- v33 read-only: terrain cells + surface under the fishing squirrel and the rock islet
local T = workspace.Terrain
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {T}; rp.IgnoreWater = true
for _, s in ipairs({{"fish", 160, -60}, {"rocks", 160, -32}}) do
	local reg = Region3.new(Vector3.new(s[2], -12, s[3]), Vector3.new(s[2] + 12, 0, s[3] + 8))
	local c = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy"})
	for ix = 1, 3 do for iz = 1, 2 do
		local t = {}
		for iy = 1, 3 do t[#t + 1] = string.format("%s%.2f", c.SolidMaterial[ix][iy][iz].Name:sub(1, 4), c.SolidOccupancy[ix][iy][iz]) end
		local x, z = s[2] + (ix - 0.5) * 4, s[3] + (iz - 0.5) * 4
		local h = workspace:Raycast(Vector3.new(x, 10, z), Vector3.new(0, -30, 0), rp)
		print("QQ pc", s[1], x, z, table.concat(t, " "), "surf", h and string.format("%.2f", h.Position.Y) or "-")
	end end
end

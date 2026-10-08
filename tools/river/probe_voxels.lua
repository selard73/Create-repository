-- v12 read-only: terrain cells (y -8..8) at a few spots, plus the parts at the bridge's east end
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local T = workspace.Terrain
for _, s in ipairs({{166, -114}, {170, -118}, {187, -20}, {176, -128}, {150, -100}}) do
	local x, z = math.floor(s[1] / 4) * 4, math.floor(s[2] / 4) * 4
	local reg = Region3.new(Vector3.new(x, -8, z), Vector3.new(x + 4, 8, z + 4))
	local c = T:ReadVoxelChannels(reg, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
	local t = {}
	for iy = 1, 4 do t[#t + 1] = (-8 + (iy - 1) * 4) .. ":" .. c.SolidMaterial[1][iy][1].Name .. string.format("%.2f", c.SolidOccupancy[1][iy][1]) end
	P("cell", x, z, table.concat(t, " "))
end
-- what stands on the east approach (x 164..180, z -135..-105)
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d.Size.Y < 30 then
		local p = d.Position
		if p.X > 160 and p.X < 182 and p.Z > -140 and p.Z < -100 and p.Y < 6 and d.Transparency < 1 then
			P("part", d:GetFullName(), string.format("%.1f,%.2f,%.1f", p.X, p.Y, p.Z), string.format("%.1f,%.2f,%.1f", d.Size.X, d.Size.Y, d.Size.Z), "bottom", string.format("%.2f", p.Y - d.Size.Y / 2))
		end
	end
end
P("DONE12")

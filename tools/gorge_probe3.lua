-- gorge_probe3: READ-ONLY. Where the Baseplate is cut away under the river south of the village (the trench water can
-- sit in), every 2 studs from z -204 to -600, plus the Baseplate's own details. Nothing is changed.
local bp = workspace:FindFirstChild("Baseplate")
print("QQ G3 BASEPLATE", bp and bp:GetFullName(), bp and bp.ClassName, bp and tostring(bp.Size), bp and bp:GetAttribute("RiverChannel"))
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {bp}
local out = {}
for z = -204, -600, -2 do
	local x0, x1, deep = nil, nil, 0
	for x = 40, 300, 1 do
		local r = workspace:Raycast(Vector3.new(x, 50, z), Vector3.new(0, -100, 0), rp)
		local top = r and r.Position.Y or -99
		if top < -0.5 then x0 = x0 or x; x1 = x; deep = math.min(deep, top) end
	end
	out[#out + 1] = string.format("%d:%s:%s:%.1f", z, tostring(x0 or "-"), tostring(x1 or "-"), deep)
	if #out == 20 then print("QQ G3 TR " .. table.concat(out, " ")); out = {} end
end
if #out > 0 then print("QQ G3 TR " .. table.concat(out, " ")) end
-- terrain materials in use, and the colours the map's terrain uses for the ones the gorge will write
local T = workspace.Terrain
for _, m in ipairs({Enum.Material.Grass, Enum.Material.Sand, Enum.Material.Mud, Enum.Material.Ground, Enum.Material.Rock, Enum.Material.Sandstone}) do
	print("QQ G3 COLOUR", m.Name, tostring(T:GetMaterialColor(m)))
end
print("QQ G3 WATER", tostring(T.WaterColor), T.WaterTransparency, T.WaterReflectance, T.WaterWaveSize)
print("QQ G3 DONE")

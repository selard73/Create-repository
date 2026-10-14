-- look_undo1.lua (job 99): puts back everything look_pass1.lua changed, from the LookWas_* attributes it left on Lighting / Terrain
-- (water, bloom threshold, the grass colours) and removes the LookGrade ColorCorrectionEffect. Studio EDIT mode. Output "QQ LOOK".
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local n = 0
local function back(obj, prop)
	local was = obj:GetAttribute("LookWas_" .. prop)
	if was ~= nil then obj[prop] = was; obj:SetAttribute("LookWas_" .. prop, nil); n += 1; print(string.format("QQ LOOK %s.%s back to %s", obj.Name, prop, tostring(was))) end
end
back(Terrain, "WaterReflectance"); back(Terrain, "WaterTransparency"); back(Terrain, "WaterWaveSize")
local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
if bloom then back(bloom, "Threshold") end
for _, m in ipairs({Enum.Material.Grass, Enum.Material.LeafyGrass}) do
	local key = "LookWas_" .. m.Name .. "Color"
	local was = Terrain:GetAttribute(key)
	if typeof(was) == "Color3" then Terrain:SetMaterialColor(m, was); Terrain:SetAttribute(key, nil); n += 1; print("QQ LOOK Terrain " .. m.Name .. " colour back") end
end
local cc = Lighting:FindFirstChild("LookGrade")
if cc then cc:Destroy(); n += 1; print("QQ LOOK LookGrade removed") end
print("QQ LOOK UNDO DONE (" .. n .. " put back)")

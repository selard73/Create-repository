-- gorge_probe5: READ-ONLY. How the Sandstone Climb's rock pieces are set up (material, colour, texture, reflectance),
-- to match the gorge's rock to them. Nothing is changed.
local sc = workspace:FindFirstChild("SandstoneClimb")
local n = 0
if sc then
	for _, d in ipairs(sc:GetDescendants()) do
		if d:IsA("MeshPart") and d.Name:find("SandCliff") and n < 4 then
			n += 1
			local sa = d:FindFirstChildWhichIsA("SurfaceAppearance")
			print(string.format("QQ G5 %s material=%s variant=%s color=%s refl=%.2f tex=%s sa=%s render=%s", d.Name, d.Material.Name, d.MaterialVariant,
				tostring(d.Color), d.Reflectance, d.TextureID, sa and "yes" or "no", d.RenderFidelity.Name))
		end
	end
end
local g = workspace:FindFirstChild("SouthGorge")
if g then
	local p = g.Rock:GetChildren()[1]
	print(string.format("QQ G5 GORGE %s material=%s color=%s refl=%.2f tex=%s", p.Name, p.Material.Name, tostring(p.Color), p.Reflectance, p.TextureID))
end
local L = game:GetService("Lighting")
print("QQ G5 LIGHTING", L.Technology and L.Technology.Name, "brightness", L.Brightness, "exposure", L.ExposureCompensation, "ambient", tostring(L.Ambient), "outdoor", tostring(L.OutdoorAmbient), "envspec", L.EnvironmentSpecularScale, "envdiff", L.EnvironmentDiffuseScale)
print("QQ G5 DONE")

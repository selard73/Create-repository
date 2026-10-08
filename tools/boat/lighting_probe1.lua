-- lighting_probe1 v1: READ-ONLY. What post-processing the game runs (it would tint a world-space bubble): every Lighting
-- child with its key values, plus Lighting's own settings.
local L = game:GetService("Lighting")
print(string.format("QQ LP Lighting: Ambient %s OutdoorAmbient %s Brightness %.2f ExposureCompensation %.2f ColorShift_Top %s", tostring(L.Ambient), tostring(L.OutdoorAmbient), L.Brightness, L.ExposureCompensation, tostring(L.ColorShift_Top)))
for _, c in ipairs(L:GetChildren()) do
	if c:IsA("ColorCorrectionEffect") then
		print(string.format("QQ LP %s [ColorCorrection] Enabled=%s TintColor=%s Brightness=%.3f Contrast=%.3f Saturation=%.3f", c.Name, tostring(c.Enabled), tostring(c.TintColor), c.Brightness, c.Contrast, c.Saturation))
	elseif c:IsA("BloomEffect") then
		print(string.format("QQ LP %s [Bloom] Enabled=%s Intensity=%.2f Size=%.1f Threshold=%.2f", c.Name, tostring(c.Enabled), c.Intensity, c.Size, c.Threshold))
	elseif c:IsA("Atmosphere") then
		print(string.format("QQ LP %s [Atmosphere] Density=%.2f Color=%s Decay=%s Glare=%.2f Haze=%.2f", c.Name, c.Density, tostring(c.Color), tostring(c.Decay), c.Glare, c.Haze))
	elseif c:IsA("SunRaysEffect") or c:IsA("BlurEffect") or c:IsA("DepthOfFieldEffect") then
		print(string.format("QQ LP %s [%s] Enabled=%s", c.Name, c.ClassName, tostring(c.Enabled)))
	else
		print(string.format("QQ LP %s [%s]", c.Name, c.ClassName))
	end
end
print("QQ LP DONE")

-- look_pass1.lua (job 99): the look pass, SETTINGS ONLY (Shannon, Oct 12: "they have a better sky and better grass"; her words
-- "just refined", same vibe, no time-of-day or haze change). Runs as a play-test PREVIEW (the body on the test server, discarded on
-- stop) or, on her yes, in Studio EDIT mode (the real change). Every value it changes is remembered first as an attribute
-- LookWas_<name> on Lighting / Terrain, so look_undo1.lua puts everything back in one line. From the Oct 13 survey:
--   water      Reflectance 0.55 -> 0.85, Transparency 0.45 -> 0.65, WaveSize 0.06 -> 0.10 (WaterColor, WaveSpeed untouched)
--   bloom      Threshold 2 -> 1.2 (the lanterns glow; Intensity 1, Size 24 untouched)
--   grading    a ColorCorrectionEffect "LookGrade": Contrast 0.06, Saturation 0.08 (none existed)
--   grass      Terrain's Grass / LeafyGrass colour 96,150,72 -> 86,140,62 (a touch deeper)
-- NOT here (Properties panel only, not scriptable): Terrain.Decoration on + GrassLength ~0.7 (she sets them); the cloud skybox
-- (her pick from the Toolbox). ClockTime, Atmosphere, Fog, the sun: untouched. Output lines "QQ LOOK".
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local mode = game:GetService("RunService"):IsRunning() and "PREVIEW (play test, discarded on stop)" or "EDIT (the real change; undo = look_undo1.lua)"
local changed = {}
local function keep(obj, prop, value)
	local was = obj[prop]
	if obj:GetAttribute("LookWas_" .. prop) == nil then obj:SetAttribute("LookWas_" .. prop, was) end
	obj[prop] = value
	table.insert(changed, string.format("%s.%s %s -> %s", obj.Name, prop, tostring(was), tostring(value)))
end
-- water
keep(Terrain, "WaterReflectance", 0.85)
keep(Terrain, "WaterTransparency", 0.65)
keep(Terrain, "WaterWaveSize", 0.10)
-- bloom
local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
if bloom then keep(bloom, "Threshold", 1.2) else table.insert(changed, "no BloomEffect in Lighting - threshold not changed") end
-- grading
local cc = Lighting:FindFirstChild("LookGrade")
if not cc then cc = Instance.new("ColorCorrectionEffect"); cc.Name = "LookGrade"; cc.Parent = Lighting; table.insert(changed, "LookGrade added") end
cc.Contrast = 0.06; cc.Saturation = 0.08; cc.Brightness = 0; cc.TintColor = Color3.new(1, 1, 1); cc.Enabled = true
-- grass colour
for _, m in ipairs({Enum.Material.Grass, Enum.Material.LeafyGrass}) do
	local was = Terrain:GetMaterialColor(m)
	local key = "LookWas_" .. m.Name .. "Color"
	if Terrain:GetAttribute(key) == nil then Terrain:SetAttribute(key, was) end
	Terrain:SetMaterialColor(m, Color3.fromRGB(86, 140, 62))
	table.insert(changed, string.format("Terrain %s colour %d,%d,%d -> 86,140,62", m.Name, math.floor(was.R * 255 + 0.5), math.floor(was.G * 255 + 0.5), math.floor(was.B * 255 + 0.5)))
end
print("QQ LOOK " .. mode)
for _, l in ipairs(changed) do print("QQ LOOK " .. l) end
print("QQ LOOK DONE (" .. #changed .. " lines). Still hers in the Properties panel: Terrain.Decoration on, GrassLength ~0.7; a cloud skybox from the Toolbox.")

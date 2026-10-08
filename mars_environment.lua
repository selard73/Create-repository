-- Martian environment: run once in Studio's Command Bar (edit mode). Keeps daytime. Safe to run again.
-- 1) every terrain material becomes a rust red/orange (paint hills with the Terrain Editor; they come out red)
-- 2) the Baseplate (if any) becomes red sand
-- 3) warm sunlight with only a light dusty haze at the horizon
local T = workspace.Terrain
local colors = {
	[Enum.Material.Sand] = Color3.fromRGB(176, 78, 44),
	[Enum.Material.Ground] = Color3.fromRGB(150, 64, 38),
	[Enum.Material.Sandstone] = Color3.fromRGB(190, 92, 50),
	[Enum.Material.Rock] = Color3.fromRGB(128, 50, 36),
	[Enum.Material.Slate] = Color3.fromRGB(118, 46, 34),
	[Enum.Material.Basalt] = Color3.fromRGB(100, 40, 32),
	[Enum.Material.Mud] = Color3.fromRGB(132, 56, 38),
	[Enum.Material.Grass] = Color3.fromRGB(168, 76, 44),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(160, 72, 42),
	[Enum.Material.Cobblestone] = Color3.fromRGB(140, 62, 44),
	[Enum.Material.Pavement] = Color3.fromRGB(130, 76, 62),
	[Enum.Material.Asphalt] = Color3.fromRGB(70, 42, 38),
	[Enum.Material.Limestone] = Color3.fromRGB(198, 116, 76),
	[Enum.Material.CrackedLava] = Color3.fromRGB(96, 34, 26),
	[Enum.Material.Snow] = Color3.fromRGB(220, 170, 140),
	[Enum.Material.Glacier] = Color3.fromRGB(214, 160, 130),
	[Enum.Material.Salt] = Color3.fromRGB(226, 186, 160),
	[Enum.Material.Ice] = Color3.fromRGB(214, 160, 130),
}
local applied = 0
for mat, col in pairs(colors) do
	local ok = pcall(function() T:SetMaterialColor(mat, col) end)
	if ok then applied += 1 end
end
T.WaterColor = Color3.fromRGB(70, 150, 140)
local base = workspace:FindFirstChild("Baseplate")
if base and base:IsA("BasePart") then base.Color = Color3.fromRGB(172, 76, 44); base.Material = Enum.Material.Sand end
local L = game:GetService("Lighting")
L.Ambient = Color3.fromRGB(96, 62, 54)
L.OutdoorAmbient = Color3.fromRGB(138, 92, 78)
L.ColorShift_Top = Color3.fromRGB(255, 214, 170)
L.ColorShift_Bottom = Color3.fromRGB(170, 84, 56)
L.Brightness = 2
L.ExposureCompensation = 0
L.FogStart = 100000; L.FogEnd = 100000     -- no legacy fog
local atmo = L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", L)
atmo.Density = 0.12; atmo.Offset = 0
atmo.Color = Color3.fromRGB(232, 170, 130); atmo.Decay = Color3.fromRGB(150, 80, 56)
atmo.Glare = 0.15; atmo.Haze = 0.6
print("Mars environment applied: " .. applied .. " terrain colours, baseplate, warm sky")

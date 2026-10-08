-- Tube light: run in the Command Bar with the imported fixture SELECTED. Safe to run again.
local LIGHT_COLOR = Color3.fromRGB(120, 255, 150)   -- change the glow colour here (green default)
local FLICKER = false                               -- true = occasional old-fixture flicker while the game runs
local model = game.Selection:Get()[1] or workspace:FindFirstChild("tube_light")
assert(model and model:IsA("Model"), "Select the imported tube light model first")
local tube
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		for _, c in ipairs(p:GetChildren()) do if c:IsA("Light") then c:Destroy() end end
		if p.Name == "NeonGreen_Tube" then
			tube = p
			p.Material = Enum.Material.Neon; p.Color = LIGHT_COLOR; p.TextureID = ""; p.Transparency = 0.25; p.CanCollide = false; p.CastShadow = false
		elseif p.Name == "NeonGreen_Filament" then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(235, 255, 240); p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
		else
			p.Material = Enum.Material.SmoothPlastic
		end
	end
end
if tube then
	local l = Instance.new("SurfaceLight"); l.Face = Enum.NormalId.Front; l.Color = LIGHT_COLOR; l.Range = 14; l.Brightness = 1.6; l.Angle = 150; l.Shadows = false; l.Parent = tube
	local p = Instance.new("PointLight"); p.Color = LIGHT_COLOR; p.Range = 8; p.Brightness = 0.6; p.Shadows = false; p.Parent = tube
end
local old = model:FindFirstChild("TubeFlicker"); if old then old:Destroy() end
if FLICKER and tube then
	local s = Instance.new("Script"); s.Name = "TubeFlicker"
	s.Source = [[
local tube = script.Parent:FindFirstChild("NeonGreen_Tube")
local rng = Random.new()
while tube and tube.Parent do
	task.wait(rng:NextNumber(2, 7))
	for i = 1, rng:NextInteger(1, 3) do
		tube.Material = Enum.Material.SmoothPlastic
		for _, l in ipairs(tube:GetChildren()) do if l:IsA("Light") then l.Enabled = false end end
		task.wait(rng:NextNumber(0.04, 0.12))
		tube.Material = Enum.Material.Neon
		for _, l in ipairs(tube:GetChildren()) do if l:IsA("Light") then l.Enabled = true end end
		task.wait(rng:NextNumber(0.05, 0.2))
	end
end
]]
	s.Parent = model
end
model.Name = "TubeLight"
print("Tube light applied")

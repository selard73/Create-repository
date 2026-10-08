-- Satellite dish: run in the Command Bar with the imported model SELECTED (or it finds it in Workspace).
-- Body stays matte dull metal. Only the round lamps glow, blink (while the game runs) and cast light; the doorway casts lime light.
local model = workspace:FindFirstChild("SatelliteDish") or workspace:FindFirstChild("dish") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the dish model first")
local colors = { Lime = Color3.fromRGB(205, 255, 70), Orange = Color3.fromRGB(255, 150, 50), Green = Color3.fromRGB(100, 255, 110), Cyan = Color3.fromRGB(90, 230, 255), Red = Color3.fromRGB(255, 70, 60), Yellow = Color3.fromRGB(255, 225, 70), Magenta = Color3.fromRGB(255, 90, 220) }
local door
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		for _, c in ipairs(p:GetChildren()) do if c:IsA("Light") then c:Destroy() end end
		local tone = p.Name:match("^Neon(%a+)_")
		if tone and colors[tone] then
			p.Material = Enum.Material.Neon; p.Color = colors[tone]; p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
			if p.Name:find("Lamp") then
				local l = Instance.new("PointLight"); l.Color = colors[tone]; l.Range = 5; l.Brightness = 1; l.Shadows = false; l.Parent = p
			end
		else
			p.Material = Enum.Material.SmoothPlastic
		end
		if p.Name == "NeonLime_Door" then door = p end
	end
end
if door then
	local l = Instance.new("PointLight"); l.Color = colors.Lime; l.Range = 12; l.Brightness = 2; l.Shadows = false; l.Parent = door
	local sp = Instance.new("SpotLight"); sp.Color = colors.Lime; sp.Range = 16; sp.Brightness = 2.5; sp.Angle = 110; sp.Face = Enum.NormalId.Front; sp.Shadows = true; sp.Parent = door
	local sp2 = sp:Clone(); sp2.Face = Enum.NormalId.Back; sp2.Parent = door
end
local oldScript = model:FindFirstChild("LampBlinker"); if oldScript then oldScript:Destroy() end
local blinker = Instance.new("Script"); blinker.Name = "LampBlinker"
blinker.Source = [[
local model = script.Parent
local rng = Random.new()
for _, lamp in ipairs(model:GetDescendants()) do
	if lamp:IsA("BasePart") and lamp.Name:find("Lamp") then
		task.spawn(function()
			local onColor = lamp.Color
			local offColor = onColor:Lerp(Color3.new(0, 0, 0), 0.7)
			local light = lamp:FindFirstChildOfClass("PointLight")
			local period = rng:NextNumber(0.6, 2.2)
			task.wait(rng:NextNumber(0, 2))
			while lamp.Parent do
				lamp.Material = Enum.Material.SmoothPlastic; lamp.Color = offColor
				if light then light.Enabled = false end
				task.wait(period * rng:NextNumber(0.3, 0.7))
				lamp.Material = Enum.Material.Neon; lamp.Color = onColor
				if light then light.Enabled = true end
				task.wait(period * rng:NextNumber(0.6, 1.4))
			end
		end)
	end
end
]]
blinker.Parent = model
model.Name = "SatelliteDish"
print("Satellite dish: matte metal, blinking lamps, door light")

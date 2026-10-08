-- Cactus: run once in the Command Bar with the imported model SELECTED (or it finds "cactus" in Workspace).
-- Ridge lines become glowing Neon that fades out toward the bottom, a soft green light sits in the trunk,
-- and the whole cactus gets the faint green daytime aura.
local model = workspace:FindFirstChild("Cactus") or workspace:FindFirstChild("cactus") or game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the imported cactus model first")
local LIME = Color3.fromRGB(170, 245, 120)
local trunk
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		if p.Name:match("^NeonLime_") then
			p.Material = Enum.Material.Neon; p.Color = LIME; p.TextureID = ""; p.CanCollide = false; p.CastShadow = false
			p.Transparency = p.Name:find("Tail") and 0.55 or 0
		elseif p.Name:match("^Petal") then
			p.Material = Enum.Material.SmoothPlastic
		elseif p.Name:match("^FlowerCore") then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 214, 70); p.TextureID = ""
		else
			p.Material = Enum.Material.SmoothPlastic
		end
		if p.Name == "Trunk" then trunk = p end
	end
end
if trunk then
	local old = trunk:FindFirstChildOfClass("PointLight"); if old then old:Destroy() end
	local l = Instance.new("PointLight"); l.Color = LIME; l.Range = 16; l.Brightness = 0.8; l.Shadows = false; l.Parent = trunk
end
local hl = model:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
hl.Name = "CactusGlow"; hl.FillColor = LIME; hl.FillTransparency = 0.92
hl.OutlineColor = LIME; hl.OutlineTransparency = 0.35; hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Parent = model
model.Name = "Cactus"
print("Cactus: glowing ridges, trunk light and aura applied")

-- Area 51 sign: run once in Studio's Command Bar with the imported model SELECTED.
-- 1) Neon* pieces become glowing Neon in their color (Haze pieces become a soft transparent glow)
-- 2) everything is anchored and the neon gets pink/cyan PointLights
-- 3) yellow Highlight aura + spotlight; daytime is kept (restored if an old run set dusk)
local model = game.Selection:Get()[1]
assert(model and model:IsA("Model"), "Select the imported sign model first")
local colors = {
	Pink   = Color3.fromRGB(255, 70, 210),
	Cyan   = Color3.fromRGB(80, 235, 255),
	White  = Color3.fromRGB(245, 250, 255),
	Yellow = Color3.fromRGB(255, 220, 80),
	Ice    = Color3.fromRGB(215, 250, 255),
}
local board, panel
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		p.Anchored = true
		local tone = p.Name:match("^Neon(%a+)_")
		if tone and colors[tone] then
			p.Material = Enum.Material.Neon
			p.Color = colors[tone]
			p.TextureID = ""
			p.CanCollide = false
			p.CastShadow = false
		elseif p.Name == "UfoDome" then
			p.Material = Enum.Material.Glass
			p.Color = Color3.fromRGB(120, 190, 225)
			p.TextureID = ""
			p.Transparency = 0.35
		elseif p.Name:find("^Channel") then
			p.Material = Enum.Material.SmoothPlastic
			p.Color = Color3.fromRGB(14, 14, 18)
			p.TextureID = ""
			p.CanCollide = false
		end
		if p.Name == "Board" then board = p end
		if p.Name == "Panel" then panel = p end
	end
end
-- soft glow slabs: transparent Neon just in front of the panel and the board
local function haze(name, parent, size, offset, color, transparency)
	local old = model:FindFirstChild(name); if old then old:Destroy() end
	local h = Instance.new("Part")
	h.Name = name; h.Anchored = true; h.CanCollide = false; h.CastShadow = false
	h.Material = Enum.Material.Neon; h.Color = color; h.Transparency = transparency
	h.Size = size; h.CFrame = parent.CFrame * CFrame.new(offset)
	h.Parent = model
end
if panel then haze("TextGlow", panel, Vector3.new(panel.Size.X - 0.7, panel.Size.Y - 0.6, 0.04), Vector3.new(0, 0, panel.Size.Z / 2 + 0.03), colors.Cyan, 0.86) end
if board then haze("PinkWash", board, Vector3.new(board.Size.X - 1.6, board.Size.Y - 2.2, 0.03), Vector3.new(0, 0.3, board.Size.Z / 2 + 0.015), colors.Pink, 0.94) end
if board then
	local function light(name, color, offset, range, bright)
		local old = board:FindFirstChild(name); if old then old:Destroy() end
		local a = Instance.new("Attachment"); a.Name = name; a.Position = offset; a.Parent = board
		local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = bright; l.Shadows = false; l.Parent = a
	end
	light("PinkGlow", colors.Pink, Vector3.new(0, 0, 3), 16, 1.4)
	light("CyanGlow", colors.Cyan, Vector3.new(0, -1.6, 2), 10, 1.8)
end
-- eerie yellow aura around the whole sign, visible in daylight (same trick as the cactus)
local hl = model:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
hl.Name = "SignGlow"
hl.FillColor = Color3.fromRGB(255, 236, 140)
hl.FillTransparency = 0.88
hl.OutlineColor = Color3.fromRGB(255, 226, 110)
hl.OutlineTransparency = 0
hl.DepthMode = Enum.HighlightDepthMode.Occluded
hl.Parent = model
-- yellow spotlight shining down onto the sign
if board then
	local old = board:FindFirstChild("Spot"); if old then old:Destroy() end
	local a = Instance.new("Attachment"); a.Name = "Spot"; a.Position = Vector3.new(0, 7, 4); a.Parent = board
	local sp = Instance.new("SpotLight"); sp.Color = Color3.fromRGB(255, 232, 150); sp.Brightness = 3
	sp.Range = 22; sp.Angle = 70; sp.Face = Enum.NormalId.Bottom; sp.Shadows = true; sp.Parent = a
end
-- scene: keep daytime. Put it back if an earlier run of this script set dusk.
local L = game:GetService("Lighting")
if L.ClockTime < 17 and L.ClockTime > 7 then else L.ClockTime = 14 end
L.Brightness = 2
L.EnvironmentDiffuseScale = 1
L.EnvironmentSpecularScale = 1
L.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
pcall(function() L.Technology = Enum.Technology.Future end)
local bloom = L:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", L)
bloom.Enabled = true; bloom.Intensity = 0.6; bloom.Size = 24; bloom.Threshold = 0.95
print("Area 51 sign: neon + lighting applied to", model:GetFullName())

"""Village builder fix 2 (Sep 16): decorative chalk menu boards (title, chalk border, dotted price columns, footer) and a
fountain that reads as water (translucent jet column + fine bright droplets) instead of smoke puffs.
Run: python patch_builder_fix2.py && python make_village_scripts.py"""
import shutil
from pathlib import Path

D = Path(__file__).parent
p = D / "make_village_scripts.py"
shutil.copy2(p, D / "make_village_scripts.before_fix2.py")
s = p.read_text(encoding="utf-8")


def replace_block(start_marker, end_marker, new_block):
    global s
    i = s.index(start_marker); j = s.index(end_marker, i)
    s = s[:i] + new_block + s[j:]


MENU = r'''-- chalkboard: a written, decorated menu on each outer face (chalk border, coloured title, dotted price columns)
local MENUS = {
	{title = "Café de l'Écureuil", sub = "MENU DU JOUR", foot = "Bon appétit !",
	 items = {{"Soupe à l'oignon", "5€"}, {"Croque-monsieur", "6€"}, {"Quiche lorraine", "5€"}, {"Salade niçoise", "7€"}, {"Tarte aux noisettes", "4€"}}},
	{title = "Café de l'Écureuil", sub = "BOISSONS & DOUCEURS", foot = "Merci, à bientôt !",
	 items = {{"Café crème", "2€"}, {"Chocolat chaud", "3€"}, {"Citron pressé", "3€"}, {"Jus de pomme", "2€50"}, {"Croissant", "1€50"}}},
}
local CHALK, CHALK_Y, CHALK_P = C(246, 240, 226), C(250, 226, 140), C(240, 170, 190)
local function chalkLabel(parent, text, size, color, font, xalign, layoutOrder)
	local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, 0, 0, size + 6)
	l.FontFace = Font.new("rbxasset://fonts/families/" .. font .. ".json"); l.TextSize = size; l.TextColor3 = color
	l.TextXAlignment = xalign or Enum.TextXAlignment.Center; l.Text = text; l.LayoutOrder = layoutOrder; l.Parent = parent
	return l
end
local function menuBoard(cb)
	local post = cb:FindFirstChild("Post", true)
	if not post then return end
	for _, p in ipairs(cb:GetDescendants()) do if p:IsA("BasePart") and p.Name == "Trim" then p:Destroy() end end
	local s = cb:GetScale()
	for i, sgn in ipairs({-1, 1}) do
		local m = MENUS[i]
		local out = post.CFrame.LookVector * sgn
		local n = (out * 0.978 + Vector3.yAxis * 0.204).Unit               -- the boards lean 12 degrees, so the faces tilt up
		local c = post.Position + Vector3.new(0, -1.795 * s, 0) + out * (0.453 * s) + n * 0.03
		local part = Instance.new("Part"); part.Name = "MenuText"; part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.Locked = true
		part.Transparency = 1; part.Size = Vector3.new(1.9 * s, 2.6 * s, 0.04)
		part.CFrame = CFrame.lookAt(c, c + n)
		part.Parent = cb
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.LightInfluence = 0; gui.Brightness = 1.15
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 200; gui.Parent = part   -- 380 x 520 px
		local frame = Instance.new("Frame"); frame.BackgroundTransparency = 1; frame.Size = UDim2.new(1, -28, 1, -28); frame.Position = UDim2.fromOffset(14, 14); frame.Parent = gui
		local border = Instance.new("UIStroke"); border.Color = CHALK; border.Thickness = 3; border.Transparency = 0.15; border.Parent = frame
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = frame
		local inner = Instance.new("Frame"); inner.BackgroundTransparency = 1; inner.Size = UDim2.new(1, -12, 1, -12); inner.Position = UDim2.fromOffset(6, 6); inner.Parent = frame
		local border2 = Instance.new("UIStroke"); border2.Color = CHALK; border2.Thickness = 1; border2.Transparency = 0.45; border2.Parent = inner
		local corner2 = Instance.new("UICorner"); corner2.CornerRadius = UDim.new(0, 7); corner2.Parent = inner
		local list = Instance.new("Frame"); list.BackgroundTransparency = 1; list.Size = UDim2.new(1, -36, 1, -30); list.Position = UDim2.fromOffset(18, 16); list.Parent = inner
		local lay = Instance.new("UIListLayout"); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Padding = UDim.new(0, 2); lay.Parent = list
		chalkLabel(list, m.title, 44, CHALK_Y, "PermanentMarker", nil, 1)
		chalkLabel(list, "•   •   •", 18, CHALK, "PatrickHand", nil, 2)
		chalkLabel(list, m.sub, 26, CHALK, "PatrickHand", nil, 3)
		for k, it in ipairs(m.items) do
			local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.Size = UDim2.new(1, 0, 0, 40); row.LayoutOrder = 10 + k; row.Parent = list
			local name = chalkLabel(row, it[1], 30, CHALK, "PatrickHand", Enum.TextXAlignment.Left, 1); name.Size = UDim2.new(0.74, 0, 1, 0)
			local dots = chalkLabel(row, "................................", 22, CHALK, "PatrickHand", Enum.TextXAlignment.Left, 2)
			dots.Size = UDim2.new(1, 0, 1, 0); dots.TextTransparency = 0.5; dots.ClipsDescendants = true; dots.ZIndex = 0
			local price = chalkLabel(row, it[2], 30, CHALK_Y, "PatrickHand", Enum.TextXAlignment.Right, 3); price.Size = UDim2.new(0.26, 0, 1, 0); price.Position = UDim2.fromScale(0.74, 0)
			name.ZIndex = 2; price.ZIndex = 2
			local bg = Instance.new("Frame"); bg.BackgroundColor3 = C(58, 46, 40); bg.BorderSizePixel = 0; bg.Size = UDim2.new(0, 0, 0, 0); bg.Parent = row
		end
		chalkLabel(list, "•   •   •", 18, CHALK, "PatrickHand", nil, 40)
		chalkLabel(list, m.foot, 34, CHALK_P, "PermanentMarker", nil, 41)
	end
end

'''
replace_block("-- chalkboard: the placeholder chalk squiggles", "-- a cafe table with its setting", MENU)

FOUNTAIN = r'''-- fountain: a slim translucent water column rising from the spout, a bright fan of fine droplets falling back into the
-- bowls, and a light mist where they land
local function fountainSpray(model)
	if not model then return model end
	local base = model:FindFirstChildWhichIsA("BasePart", true)
	if not base then return model end
	local bb, size = model:GetBoundingBox()
	local s = model:GetScale()
	local top = Vector3.new(bb.Position.X, bb.Position.Y + size.Y / 2, bb.Position.Z)
	local h = 2.4 * s
	local function water(name, shape, sz, cf)
		local w = Instance.new("Part"); w.Name = name; w.Shape = shape; w.Anchored = true; w.CanCollide = false; w.CanQuery = false; w.Locked = true
		w.Material = Enum.Material.Glass; w.Color = C(150, 205, 240); w.Transparency = 0.3; w.CastShadow = false
		w.Size = sz; w.CFrame = cf; w.Parent = model
		return w
	end
	water("Jet", Enum.PartType.Cylinder, Vector3.new(h, 0.42 * s, 0.42 * s), CFrame.new(top + Vector3.new(0, h / 2 - 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)))
	water("JetTop", Enum.PartType.Ball, Vector3.new(0.75 * s, 0.75 * s, 0.75 * s), CFrame.new(top + Vector3.new(0, h - 0.2, 0)))
	local a = Instance.new("Attachment"); a.Name = "Spout"; a.Parent = base
	a.WorldCFrame = CFrame.new(top + Vector3.new(0, h - 0.2, 0))
	local pe = Instance.new("ParticleEmitter"); pe.Name = "Spray"
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(C(200, 232, 255), C(255, 255, 255))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.22 * s), NumberSequenceKeypoint.new(1, 0.34 * s)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(0.9, 1.2); pe.Rate = 110; pe.Speed = NumberRange.new(6 * s, 9 * s)
	pe.SpreadAngle = Vector2.new(22, 22); pe.Acceleration = Vector3.new(0, -30, 0); pe.Drag = 0.4
	pe.EmissionDirection = Enum.NormalId.Top; pe.LightEmission = 0.75; pe.LightInfluence = 0.3
	pe.Parent = a
	local m = Instance.new("Attachment"); m.Name = "Mist"; m.Parent = base
	m.WorldCFrame = CFrame.new(top + Vector3.new(0, -0.6 * s, 0))
	local mist = Instance.new("ParticleEmitter"); mist.Name = "MistPuff"
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(C(235, 245, 255))
	mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5 * s), NumberSequenceKeypoint.new(1, 1.2 * s)})
	mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1)})
	mist.Lifetime = NumberRange.new(0.6, 0.9); mist.Rate = 14; mist.Speed = NumberRange.new(0.5, 1.2)
	mist.SpreadAngle = Vector2.new(80, 80); mist.LightEmission = 0.4
	mist.Parent = m
	return model
end

'''
replace_block("-- fountain: a water jet from the top of the column", "-- 1. shop-houses along both sides", FOUNTAIN)
p.write_text(s, encoding="utf-8")
print("builder fix 2 applied:", s.count("PermanentMarker"), "PermanentMarker uses;", s.count('water("Jet"'), "jet column")

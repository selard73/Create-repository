from pathlib import Path
p = Path(__file__).parent / "make_squirrel_scripts.py"
s = p.read_text(encoding="utf-8")

# ---- server: default mask attribute ----
old = '''if folder:GetAttribute("NameTagSeconds") == nil then folder:SetAttribute("NameTagSeconds", 3.2) end'''
new = '''if folder:GetAttribute("NameTagSeconds") == nil then folder:SetAttribute("NameTagSeconds", 3.2) end
if folder:GetAttribute("MaskImage") == nil then folder:SetAttribute("MaskImage", "rbxassetid://77268792392056") end   -- white square, transparent circle'''
assert old in s; s = s.replace(old, new)

# ---- HUD panel: opaque so the mask corners disappear into it ----
old = '''	panel.Position = UDim2.new(1, -12, 0, 6); panel.Size = UDim2.fromOffset(330, 0); panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundTransparency = 1; panel.Parent = hud'''
new = '''	panel.Position = UDim2.new(1, -10, 0, 6); panel.Size = UDim2.fromOffset(336, 0); panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = PANEL; panel.BackgroundTransparency = 0; panel.Parent = hud
	local pcorner = Instance.new("UICorner"); pcorner.CornerRadius = UDim.new(0, 14); pcorner.Parent = panel
	local ppad = Instance.new("UIPadding"); ppad.PaddingTop = UDim.new(0, 6); ppad.PaddingBottom = UDim.new(0, 8)
	ppad.PaddingLeft = UDim.new(0, 8); ppad.PaddingRight = UDim.new(0, 8); ppad.Parent = panel
	local pstroke = Instance.new("UIStroke"); pstroke.Thickness = 2; pstroke.Color = Color3.fromRGB(255, 205, 90); pstroke.Transparency = 0.5; pstroke.Parent = panel'''
assert old in s; s = s.replace(old, new)
old = '''local hud, grid, counter
local badges = {}'''
new = '''local hud, grid, counter
local badges = {}
local PANEL = Color3.fromRGB(38, 30, 52)
local function maskId() return script.Parent:GetAttribute("MaskImage") or "rbxassetid://77268792392056" end'''
assert old in s; s = s.replace(old, new)

# ---- badge: square face render, mask overlay tinted to the panel, gold ring on top ----
start = s.index("local CIRCLE = 48")
end_ = s.index("ensureBadges = function()")
new_badges = '''local CIRCLE = 52
faceCamera = function(st)
	-- portrait crop: head and shoulders fill the circle, the rest is hidden by the mask
	local mesh = st.mesh
	local H = mesh.Size.Y
	local fwd = mesh.CFrame:VectorToWorldSpace(st.fwdL)
	local bottom = mesh.Position - Vector3.new(0, H / 2, 0)
	local centre = bottom + Vector3.new(0, 0.70 * H, 0) + fwd * (0.30 * H)
	local cam = Instance.new("Camera"); cam.FieldOfView = 24
	local dist = 1.35 * H
	cam.CFrame = CFrame.lookAt(centre + fwd * dist + Vector3.new(0, 0.05 * H, 0), centre)
	return cam
end
makeViewport = function(parent, st, cam)
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 200); vp.LightColor = Color3.fromRGB(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.ZIndex = parent.ZIndex + 1; vp.Parent = parent
	local copy = st.mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local color = st.mesh:GetAttribute("ColorTexture"); if color then setTex(copy, color) end
	copy.Parent = vp
	cam.Parent = vp; vp.CurrentCamera = cam
	return vp
end
-- a square that shows a circle: backing disc, 3D render, mask (transparent circle, tinted like the panel), ring
local function circleWindow(parent, size, z, discColor)
	local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(size, size); box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 0); box.BackgroundTransparency = 1; box.ZIndex = z; box.Parent = parent
	local disc = Instance.new("Frame"); disc.Size = UDim2.fromScale(1, 1); disc.BackgroundColor3 = discColor; disc.ZIndex = z; disc.Parent = box
	local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = disc
	local mask = Instance.new("ImageLabel"); mask.Size = UDim2.fromScale(1, 1); mask.BackgroundTransparency = 1
	mask.Image = maskId(); mask.ImageColor3 = PANEL; mask.ScaleType = Enum.ScaleType.Fit; mask.ZIndex = z + 3; mask.Parent = box
	local ring = Instance.new("Frame"); ring.Size = UDim2.fromScale(1, 1); ring.BackgroundTransparency = 1; ring.ZIndex = z + 4; ring.Parent = box
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
	local rs = Instance.new("UIStroke"); rs.Thickness = 2; rs.Color = Color3.fromRGB(255, 205, 90); rs.Parent = ring
	return box, disc, mask, rs
end
addBadge = function(model, st)
	ensureHud()
	if badges[model] then return badges[model] end
	badgeOrder += 1
	local cell = Instance.new("Frame"); cell.Name = model.Name; cell.BackgroundTransparency = 1; cell.LayoutOrder = badgeOrder; cell.Parent = grid
	local box, disc, mask, rs = circleWindow(cell, CIRCLE, 2, Color3.fromRGB(60, 58, 70))
	rs.Color = Color3.fromRGB(120, 116, 130)
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Text = "?"
	q.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold); q.TextSize = 30
	q.TextColor3 = Color3.fromRGB(200, 196, 210); q.ZIndex = 4; q.Parent = box
	local name = Instance.new("TextLabel"); name.Size = UDim2.new(1, 0, 0, 22); name.Position = UDim2.new(0, 0, 0, CIRCLE + 1)
	name.BackgroundTransparency = 1; name.Text = ""; name.TextWrapped = true; name.TextScaled = true
	name.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.ZIndex = 3; name.Parent = cell
	local nc = Instance.new("UITextSizeConstraint"); nc.MaxTextSize = 10; nc.MinTextSize = 7; nc.Parent = name
	local b = {cell = cell, box = box, disc = disc, rs = rs, q = q, name = name, filled = false}
	local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.ZIndex = 9; btn.Parent = cell
	btn.MouseButton1Click:Connect(function() if b.filled then openCard(model, st) end end)
	btn.MouseEnter:Connect(function() if b.filled then TweenService:Create(rs, TweenInfo.new(0.15), {Thickness = 3, Color = Color3.fromRGB(255, 240, 180)}):Play() end end)
	btn.MouseLeave:Connect(function() if b.filled then TweenService:Create(rs, TweenInfo.new(0.15), {Thickness = 2, Color = Color3.fromRGB(255, 205, 90)}):Play() end end)
	badges[model] = b
	updateCounter()
	return b
end
fillBadge = function(model, st)
	local b = addBadge(model, st)
	if b.filled then return end
	b.filled = true
	b.q:Destroy()
	b.disc.BackgroundColor3 = Color3.fromRGB(255, 248, 225); b.rs.Color = Color3.fromRGB(255, 205, 90)
	makeViewport(b.box, st, faceCamera(st))          -- sits at ZIndex 3, under the mask (5) and ring (6)
	b.name.Text = prettyName(model)
	local scale = Instance.new("UIScale"); scale.Scale = 0.4; scale.Parent = b.cell
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	updateCounter()
end
'''
s = s[:start] + new_badges + s[end_:]
# the forward-declared names: faceCamera/makeViewport were local functions before; declare them too
old = "local ensureHud, updateCounter, addBadge, fillBadge, ensureBadges, openCard, closeCard, nameTag   -- defined below\n"
new = "local ensureHud, updateCounter, addBadge, fillBadge, ensureBadges, openCard, closeCard, nameTag, faceCamera, makeViewport   -- defined below\n"
assert old in s; s = s.replace(old, new)
# grid cell size for the new circle
old = "gl.CellSize = UDim2.fromOffset(60, 72)"
new = "gl.CellSize = UDim2.fromOffset(62, 76)"
assert old in s; s = s.replace(old, new)

# ---- card: same mask trick on the big circle ----
old = '''	local ring = Instance.new("CanvasGroup"); ring.Size = UDim2.fromOffset(310, 310); ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.new(0.5, 0, 0, 22); ring.BackgroundColor3 = Color3.fromRGB(255, 248, 225); ring.ZIndex = 22; ring.Parent = panel
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
	local rs = Instance.new("UIStroke"); rs.Thickness = 3; rs.Color = Color3.fromRGB(255, 205, 90); rs.Parent = ring
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 200); vp.LightColor = Color3.fromRGB(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.ZIndex = 23; vp.Parent = ring          -- must sit above the ring's own ZIndex or it draws underneath it
	local copy = mesh:Clone()'''
new = '''	local ring = Instance.new("Frame"); ring.Size = UDim2.fromOffset(310, 310); ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.new(0.5, 0, 0, 22); ring.BackgroundTransparency = 1; ring.ZIndex = 22; ring.Parent = panel
	local disc = Instance.new("Frame"); disc.Size = UDim2.fromScale(1, 1); disc.BackgroundColor3 = Color3.fromRGB(255, 248, 225); disc.ZIndex = 22; disc.Parent = ring
	local dcorner = Instance.new("UICorner"); dcorner.CornerRadius = UDim.new(1, 0); dcorner.Parent = disc
	local mask = Instance.new("ImageLabel"); mask.Size = UDim2.fromScale(1, 1); mask.BackgroundTransparency = 1
	mask.Image = maskId(); mask.ImageColor3 = PANEL; mask.ScaleType = Enum.ScaleType.Fit; mask.ZIndex = 25; mask.Parent = ring
	local ringLine = Instance.new("Frame"); ringLine.Size = UDim2.fromScale(1, 1); ringLine.BackgroundTransparency = 1; ringLine.ZIndex = 26; ringLine.Parent = ring
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ringLine
	local rs = Instance.new("UIStroke"); rs.Thickness = 3; rs.Color = Color3.fromRGB(255, 205, 90); rs.Parent = ringLine
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 200); vp.LightColor = Color3.fromRGB(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.ZIndex = 23; vp.Parent = ring
	local copy = mesh:Clone()'''
assert old in s; s = s.replace(old, new)
old = "	local dist = mesh.Size.Magnitude * 1.9         -- far enough"
new = "	local dist = mesh.Size.Magnitude * 1.45        -- close enough to fill the circle; the mask crops whatever spills"
assert old in s; s = s.replace(old, new)
p.write_text(s, encoding="utf-8"); print("patched")

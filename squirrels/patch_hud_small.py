from pathlib import Path
p = Path(__file__).parent / "make_squirrel_scripts.py"
s = p.read_text(encoding="utf-8")

# --- HUD placement: top of the screen, tighter ---
old = '''	hud = Instance.new("ScreenGui"); hud.Name = "SquirrelHUD"; hud.ResetOnSpawn = false; hud.IgnoreGuiInset = false'''
new = '''	hud = Instance.new("ScreenGui"); hud.Name = "SquirrelHUD"; hud.ResetOnSpawn = false; hud.IgnoreGuiInset = true'''
assert old in s; s = s.replace(old, new)
old = '''	panel.Position = UDim2.new(1, -16, 0, 16); panel.Size = UDim2.fromOffset(252, 0); panel.AutomaticSize = Enum.AutomaticSize.Y'''
new = '''	panel.Position = UDim2.new(1, -12, 0, 6); panel.Size = UDim2.fromOffset(330, 0); panel.AutomaticSize = Enum.AutomaticSize.Y'''
assert old in s; s = s.replace(old, new)
old = '''	counter = Instance.new("TextLabel"); counter.Name = "Counter"; counter.Size = UDim2.new(1, 0, 0, 26); counter.BackgroundTransparency = 1
	counter.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); counter.TextSize = 18'''
new = '''	counter = Instance.new("TextLabel"); counter.Name = "Counter"; counter.Size = UDim2.new(1, 0, 0, 20); counter.BackgroundTransparency = 1
	counter.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); counter.TextSize = 15'''
assert old in s; s = s.replace(old, new)
old = '''	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(78, 100); gl.CellPadding = UDim2.fromOffset(6, 4)'''
new = '''	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(60, 72); gl.CellPadding = UDim2.fromOffset(4, 2)'''
assert old in s; s = s.replace(old, new)

# --- badges: one per squirrel from the start, "?" until found; face fills the circle ---
start = s.index("local badgeOrder = 0\nlocal function addBadge(model, st)")
end_ = s.index("local function nameTag(model, mesh)")
new_badges = '''local badgeOrder = 0
local CIRCLE = 48
local function faceCamera(st)
	-- centre of the head, from the Head bone (which sits at the neck) plus a bit up and forward
	local mesh = st.mesh
	local k = mesh.Size.Y / 2.4
	local fwd = mesh.CFrame:VectorToWorldSpace(st.fwdL)
	local base = st.bones.Head and st.bones.Head.WorldPosition or (mesh.Position + Vector3.new(0, mesh.Size.Y * 0.3, 0))
	local centre = base + Vector3.new(0, 0.42 * k, 0) + fwd * 0.12 * k
	local cam = Instance.new("Camera"); cam.FieldOfView = 26
	local dist = 3.0 * k
	cam.CFrame = CFrame.lookAt(centre + fwd * dist + Vector3.new(0, 0.25 * k, 0), centre)
	return cam
end
local function makeViewport(parent, st, cam)
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 200); vp.LightColor = Color3.fromRGB(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.Parent = parent
	local copy = st.mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local color = st.mesh:GetAttribute("ColorTexture"); if color then setTex(copy, color) end
	copy.Parent = vp
	cam.Parent = vp; vp.CurrentCamera = cam
	return vp
end
local function addBadge(model, st)
	ensureHud()
	if badges[model] then return badges[model] end
	badgeOrder += 1
	local cell = Instance.new("Frame"); cell.Name = model.Name; cell.BackgroundTransparency = 1; cell.LayoutOrder = badgeOrder; cell.Parent = grid
	local ring = Instance.new("CanvasGroup"); ring.Size = UDim2.fromOffset(CIRCLE, CIRCLE); ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.new(0.5, 0, 0, 0); ring.BackgroundColor3 = Color3.fromRGB(60, 58, 70); ring.Parent = cell
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
	local rs = Instance.new("UIStroke"); rs.Thickness = 2; rs.Color = Color3.fromRGB(120, 116, 130); rs.Parent = ring
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Text = "?"
	q.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold); q.TextSize = 30
	q.TextColor3 = Color3.fromRGB(200, 196, 210); q.Parent = ring
	local name = Instance.new("TextLabel"); name.Size = UDim2.new(1, 0, 0, 22); name.Position = UDim2.new(0, 0, 0, CIRCLE + 1)
	name.BackgroundTransparency = 1; name.Text = "???"; name.TextWrapped = true; name.TextScaled = true
	name.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); name.TextColor3 = Color3.fromRGB(215, 212, 225)
	name.Parent = cell
	local nc = Instance.new("UITextSizeConstraint"); nc.MaxTextSize = 10; nc.MinTextSize = 7; nc.Parent = name
	local ns = Instance.new("UIStroke"); ns.Thickness = 1.1; ns.Color = Color3.fromRGB(0, 0, 0); ns.LineJoinMode = Enum.LineJoinMode.Round; ns.Parent = name
	local b = {cell = cell, ring = ring, rs = rs, q = q, name = name, filled = false}
	local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.ZIndex = 5; btn.Parent = cell
	btn.MouseButton1Click:Connect(function() if b.filled then openCard(model, st) end end)
	btn.MouseEnter:Connect(function() if b.filled then TweenService:Create(rs, TweenInfo.new(0.15), {Thickness = 3, Color = Color3.fromRGB(255, 240, 180)}):Play() end end)
	btn.MouseLeave:Connect(function() if b.filled then TweenService:Create(rs, TweenInfo.new(0.15), {Thickness = 2, Color = Color3.fromRGB(255, 205, 90)}):Play() end end)
	badges[model] = b
	updateCounter()
	return b
end
local function fillBadge(model, st)
	local b = addBadge(model, st)
	if b.filled then return end
	b.filled = true
	b.q:Destroy()
	b.ring.BackgroundColor3 = Color3.fromRGB(255, 248, 225); b.rs.Color = Color3.fromRGB(255, 205, 90)
	makeViewport(b.ring, st, faceCamera(st))
	b.name.Text = prettyName(model); b.name.TextColor3 = Color3.fromRGB(255, 255, 255)
	local scale = Instance.new("UIScale"); scale.Scale = 0.4; scale.Parent = b.cell
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	updateCounter()
end
local function ensureBadges()
	local list = {}
	for model, st in pairs(squirrels) do table.insert(list, {model = model, st = st}) end
	table.sort(list, function(a, b) return prettyName(a.model) < prettyName(b.model) end)
	for _, e in ipairs(list) do addBadge(e.model, e.st); if e.st.found then fillBadge(e.model, e.st) end end
end

'''
s = s[:start] + new_badges + s[end_:]

# callers: reveal fills, initial sync builds all
old = '''	task.delay(0.6, function() addBadge(model, st) end)'''
new = '''	task.delay(0.6, function() fillBadge(model, st) end)'''
assert old in s; s = s.replace(old, new)
old = '''		if foundSet[id] then st.found = true; if color then setTex(st.mesh, color) end; addBadge(model, st)
		elseif perPlayer and gray then setTex(st.mesh, gray) end
	end
	ensureHud(); updateCounter()
end'''
new = '''		if foundSet[id] then st.found = true; if color then setTex(st.mesh, color) end
		elseif perPlayer and gray then setTex(st.mesh, gray) end
	end
	ensureHud(); ensureBadges(); updateCounter()
end'''
assert old in s; s = s.replace(old, new)

# the card's turntable: centre on the whole body, a touch tighter
old = '''	local centre = mesh.Position
	local dist = mesh.Size.Magnitude * 1.35'''
new = '''	local centre = mesh.Position
	local dist = mesh.Size.Magnitude * 1.2'''
assert old in s; s = s.replace(old, new)
p.write_text(s, encoding="utf-8"); print("patched")

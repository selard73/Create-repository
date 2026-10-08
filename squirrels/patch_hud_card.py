from pathlib import Path
p = Path(__file__).parent / "make_squirrel_scripts.py"
s = p.read_text(encoding="utf-8")

# 1. bios in the server NAMES table + Bio attribute
old = '''local NAMES = {
	{"gordo", "Gordo Squirrel"}, {"acorn", "Gordo Squirrel"}, {"fairy", "Fairy Squirrel"}, {"daisy", "Fairy Squirrel"},'''
new = '''local BIO = {
	["Gordo Squirrel"] = "Gordo has never met an acorn he didn't like. Or two. Or the whole tree. Hobbies include napping, snacking, and napping after snacking.",
	["Fairy Squirrel"] = "Sprinkles glitter wherever she goes, mostly by accident. Grants wishes on Tuesdays, but only small ones, like finding a really good acorn.",
	["El Scientifico"] = "Holds three degrees in Acorn Physics and one in Explosions. Every experiment ends with 'well, THAT was interesting.'",
	["Surfer Dude Squirrel"] = "Rides the gnarliest waves in the forest, which are mostly puddles. Says 'dude' more than any squirrel should.",
	["Nacho Libre Squirrel"] = "Masked defender of the forest and its snacks. Weakness: nachos. Also cheese. Also anything with cheese on it.",
	["Buccaneer Squirrel"] = "Sailed the seven puddles in search of buried acorns. Has a treasure map, but keeps reading it upside down.",
	["Rainy Day Squirrel"] = "Ready for weather at all times, even indoors. Has never once been caught without her umbrella. Or her spare umbrella.",
	["Mr. Holmes Squirrel"] = "Solves mysteries nobody asked him to solve. Currently investigating the Case of the Missing Acorn. He ate it.",
	["Ski-a-roo Squirrel"] = "Skis all year round, snow or no snow. Has yet to make it down a hill without hugging a tree.",
	["Baking Betty Squirrel"] = "Bakes forty cupcakes a day and eats thirty-nine of them for quality control. Her frosting is legendary. So is her sugar rush.",
	["Ballerina Squirrel"] = "Practices pirouettes on tree branches, to the great alarm of the birds. The tutu is very serious business.",
}
local NAMES = {
	{"gordo", "Gordo Squirrel"}, {"acorn", "Gordo Squirrel"}, {"fairy", "Fairy Squirrel"}, {"daisy", "Fairy Squirrel"},'''
assert old in s; s = s.replace(old, new)
old = '''			if low:find(pair[1], 1, true) then model:SetAttribute("DisplayName", pair[2]) break end
		end
	end'''
new = '''			if low:find(pair[1], 1, true) then model:SetAttribute("DisplayName", pair[2]) break end
		end
	end
	if not model:GetAttribute("Bio") then
		local dn = model:GetAttribute("DisplayName")
		model:SetAttribute("Bio", (dn and BIO[dn]) or "A squirrel of mystery. Nobody knows where they came from, least of all them.")
	end'''
assert old in s; s = s.replace(old, new)

# 2. counter above badges
old = '''	list.HorizontalAlignment = Enum.HorizontalAlignment.Right; list.Padding = UDim.new(0, 6); list.Parent = panel'''
new = '''	list.HorizontalAlignment = Enum.HorizontalAlignment.Right; list.Padding = UDim.new(0, 6); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = panel'''
assert old in s; s = s.replace(old, new)

# 3. the card (modal) + badge click
old = '''local badgeOrder = 0
local function addBadge(model, st)'''
new = '''-- ---- the card: full squirrel turning slowly, name, and a bio ----
local card, cardConn
local function closeCard()
	if cardConn then cardConn:Disconnect(); cardConn = nil end
	if card then card:Destroy(); card = nil end
end
local function openCard(model, st)
	closeCard(); ensureHud()
	local mesh = st.mesh
	card = Instance.new("Frame"); card.Name = "Card"; card.Size = UDim2.fromScale(1, 1); card.BackgroundColor3 = Color3.new(0, 0, 0)
	card.BackgroundTransparency = 0.45; card.ZIndex = 20; card.Parent = hud
	local backdrop = Instance.new("TextButton"); backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundTransparency = 1; backdrop.Text = ""
	backdrop.ZIndex = 20; backdrop.Parent = card; backdrop.MouseButton1Click:Connect(closeCard)
	local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(380, 470); panel.BackgroundColor3 = Color3.fromRGB(38, 30, 52); panel.ZIndex = 21; panel.Parent = card
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 22); pc.Parent = panel
	local ps = Instance.new("UIStroke"); ps.Thickness = 3; ps.Color = Color3.fromRGB(255, 205, 90); ps.Parent = panel
	local ring = Instance.new("CanvasGroup"); ring.Size = UDim2.fromOffset(250, 250); ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.new(0.5, 0, 0, 22); ring.BackgroundColor3 = Color3.fromRGB(255, 248, 225); ring.ZIndex = 22; ring.Parent = panel
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
	local rs = Instance.new("UIStroke"); rs.Thickness = 3; rs.Color = Color3.fromRGB(255, 205, 90); rs.Parent = ring
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 200); vp.LightColor = Color3.fromRGB(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.Parent = ring
	local copy = mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local color = mesh:GetAttribute("ColorTexture"); if color then setTex(copy, color) end
	copy.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView = 32; cam.Parent = vp; vp.CurrentCamera = cam
	local centre = mesh.Position
	local dist = mesh.Size.Magnitude * 1.35
	local fwd = mesh.CFrame:VectorToWorldSpace(st.fwdL)
	local ang0 = math.atan2(fwd.X, fwd.Z)
	local t = 0
	cardConn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		local a = ang0 + t * 0.6
		local off = Vector3.new(math.sin(a), 0, math.cos(a)) * dist + Vector3.new(0, dist * 0.22, 0)
		cam.CFrame = CFrame.lookAt(centre + off, centre)
	end)
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -40, 0, 40); title.Position = UDim2.new(0, 20, 0, 284)
	title.BackgroundTransparency = 1; title.Text = prettyName(model); title.TextScaled = true
	title.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold); title.TextColor3 = Color3.fromRGB(255, 232, 170)
	title.ZIndex = 22; title.Parent = panel
	local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 28; tc.Parent = title
	local bio = Instance.new("TextLabel"); bio.Size = UDim2.new(1, -44, 0, 118); bio.Position = UDim2.new(0, 22, 0, 330)
	bio.BackgroundTransparency = 1; bio.Text = model:GetAttribute("Bio") or ""; bio.TextWrapped = true; bio.TextScaled = true
	bio.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); bio.TextColor3 = Color3.fromRGB(245, 240, 250)
	bio.TextYAlignment = Enum.TextYAlignment.Top; bio.ZIndex = 22; bio.Parent = panel
	local bc = Instance.new("UITextSizeConstraint"); bc.MaxTextSize = 17; bc.MinTextSize = 11; bc.Parent = bio
	local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(34, 34); close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10); close.BackgroundColor3 = Color3.fromRGB(255, 205, 90); close.Text = "x"
	close.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold); close.TextSize = 20; close.TextColor3 = Color3.fromRGB(38, 30, 52)
	close.ZIndex = 23; close.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = close
	close.MouseButton1Click:Connect(closeCard)
	local sc = Instance.new("UIScale"); sc.Scale = 0.7; sc.Parent = panel
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local badgeOrder = 0
local function addBadge(model, st)'''
assert old in s; s = s.replace(old, new)
old = '''	badges[model] = cell
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	updateCounter()
end'''
new = '''	-- the whole badge is a button that opens the card
	local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.ZIndex = 5; btn.Parent = cell
	btn.MouseButton1Click:Connect(function() openCard(model, st) end)
	btn.MouseEnter:Connect(function() TweenService:Create(rs, TweenInfo.new(0.15), {Thickness = 4, Color = Color3.fromRGB(255, 240, 180)}):Play() end)
	btn.MouseLeave:Connect(function() TweenService:Create(rs, TweenInfo.new(0.15), {Thickness = 2.5, Color = Color3.fromRGB(255, 205, 90)}):Play() end)
	badges[model] = cell
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	updateCounter()
end'''
assert old in s; s = s.replace(old, new)
p.write_text(s, encoding="utf-8"); print("patched")

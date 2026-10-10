-- SeaGlassClient (workspace.SeaGlass, RunContext Client): Bella's beach finds on your screen (Oct 9 2026). A little toast when
-- you pick something up; Bella's panel (her prompt opens it): your finds in a row, the four things she makes, Make buttons
-- that light up when you have the pieces. One panel in the middle of the screen, sized for a phone (it sets the PlayerGui
-- attribute OpenPanel like the other panels, so the camera and the rest step aside). Bella speaks through SquirrelBubble.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local G = script.Parent
local R = require(G:WaitForChild("Recipes"))
local ev = G:WaitForChild("SeaGlassEvent")
local Bubble
pcall(function() Bubble = require(RS:WaitForChild("SquirrelBubble", 10)) end)
local C = Color3.fromRGB
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local CREAM, INK, GOLD, BROWN, GREEN, GREY = C(255, 246, 220), C(58, 36, 16), C(255, 202, 62), C(58, 36, 16), C(112, 160, 84), C(214, 202, 176)
local function item(id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o end
local function stroke(o, col, th) local s = Instance.new("UIStroke") s.Color = col s.Thickness = th s.Parent = o return s end
local function bella() return workspace:FindFirstChild("seaglass_squirrel_color") end
local open = false
local phoneAnchor   -- a phone: Bella's words pinned to the left of the screen (an invisible part her bubble follows), clear of the panel (Oct 9)
local function phone() local cam = workspace.CurrentCamera; return UIS.TouchEnabled and cam ~= nil and cam.ViewportSize.Y < 560 end
local function say(line, secs)
	local m = bella()
	if not (Bubble and m) then return end
	if open and phone() then
		local cam = workspace.CurrentCamera
		if not (phoneAnchor and phoneAnchor.Parent) then
			phoneAnchor = Instance.new("Part"); phoneAnchor.Name = "BellaWordsAnchor"; phoneAnchor.Anchored = true; phoneAnchor.CanCollide = false; phoneAnchor.CanQuery = false; phoneAnchor.CanTouch = false
			phoneAnchor.Transparency = 1; phoneAnchor.CastShadow = false; phoneAnchor.Size = Vector3.new(0.05, 0.05, 0.05); phoneAnchor.Parent = cam
			local conn; conn = game:GetService("RunService").RenderStepped:Connect(function()
				if not (phoneAnchor and phoneAnchor.Parent) then conn:Disconnect() return end
				local c = workspace.CurrentCamera; if not c then return end
				local v = c.ViewportSize
				local ray = c:ScreenPointToRay(v.X * 0.17, v.Y * 0.3)   -- the bubble's middle: a sixth of the way in, a third of the way down (it sat too low at half - Shannon)
				phoneAnchor.CFrame = CFrame.new(ray.Origin + ray.Direction * 6 - Vector3.new(0, 1.5, 0))
			end)
		end
		pcall(function() Bubble.say(phoneAnchor, line, {secs = secs or 4.5}) end)
		return
	end
	pcall(function() Bubble.say(m, line, {secs = secs or 4.5}) end)
end

local gui = Instance.new("ScreenGui"); gui.Name = "SeaGlassGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 16; gui.Parent = pg

-- ---------- the toast ----------
local toast = Instance.new("TextLabel"); toast.Name = "Toast"; toast.AnchorPoint = Vector2.new(0.5, 1); toast.Size = UDim2.fromOffset(300, 34)
toast.BackgroundColor3 = BROWN; toast.BackgroundTransparency = 0.12; toast.BorderSizePixel = 0; toast.FontFace = FONT; toast.TextSize = 16
toast.TextColor3 = CREAM; toast.TextScaled = true; toast.Visible = false; toast.ZIndex = 8; toast.Parent = gui
corner(toast, 10); stroke(toast, GOLD, 2)
local toastAt = 0
local function showToast(text, secs)
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	toast.Size = UDim2.fromOffset(math.min(320, v.X - 40), 34)
	toast.Position = UDim2.fromOffset(v.X / 2, v.Y - 120)
	toast.Text = text; toast.Visible = true
	toastAt = os.clock(); local t = toastAt
	task.delay(secs or 2.5, function() if toastAt == t then toast.Visible = false end end)
end

-- ---------- the panel ----------
local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(1, 0.5); panel.Position = UDim2.new(1, -14, 0.5, 0)   -- at the right: Bella and her words stay in view (Oct 9)
panel.BackgroundColor3 = BROWN; panel.BackgroundTransparency = 0.06; panel.BorderSizePixel = 0; panel.Visible = false; panel.ZIndex = 8; panel.Parent = gui
corner(panel, 14); stroke(panel, GOLD, 2)
local title = Instance.new("TextLabel"); title.Position = UDim2.fromOffset(14, 8); title.Size = UDim2.new(1, -70, 0, 28); title.BackgroundTransparency = 1
title.FontFace = FONT; title.TextSize = 20; title.TextColor3 = GOLD; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "Bella's beach finds"; title.ZIndex = 9; title.Parent = panel
local closeBtn = Instance.new("TextButton"); closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -8, 0, 6); closeBtn.Size = UDim2.fromOffset(36, 32)
closeBtn.BackgroundColor3 = C(170, 70, 50); closeBtn.BorderSizePixel = 0; closeBtn.FontFace = FONT; closeBtn.TextSize = 18; closeBtn.TextColor3 = CREAM; closeBtn.Text = "X"; closeBtn.ZIndex = 9; closeBtn.Parent = panel
corner(closeBtn, 8)
local findsRow = Instance.new("Frame"); findsRow.Position = UDim2.fromOffset(10, 42); findsRow.Size = UDim2.new(1, -20, 0, 58); findsRow.BackgroundTransparency = 1; findsRow.ZIndex = 9; findsRow.Parent = panel
local dots = {}
for i, k in ipairs(R.kinds) do
	local cell = Instance.new("Frame"); cell.Size = UDim2.new(1 / #R.kinds, 0, 1, 0); cell.Position = UDim2.new((i - 1) / #R.kinds, 0, 0, 0); cell.BackgroundTransparency = 1; cell.ZIndex = 9; cell.Parent = findsRow
	local d = Instance.new("Frame"); d.AnchorPoint = Vector2.new(0.5, 0); d.Position = UDim2.new(0.5, 0, 0, 2); d.Size = UDim2.fromOffset(22, k.glass and 22 or 18); d.BackgroundColor3 = k.colour; d.BorderSizePixel = 0; d.ZIndex = 10; d.Parent = cell
	corner(d, k.glass and 11 or 6); stroke(d, k.rare and GOLD or C(90, 64, 40), 1.5)
	local n = Instance.new("TextLabel"); n.AnchorPoint = Vector2.new(0.5, 0); n.Position = UDim2.new(0.5, 0, 0, 27); n.Size = UDim2.fromOffset(40, 16); n.BackgroundTransparency = 1
	n.FontFace = FONT; n.TextSize = 14; n.TextColor3 = CREAM; n.Text = "0"; n.ZIndex = 10; n.Parent = cell
	local s = Instance.new("TextLabel"); s.AnchorPoint = Vector2.new(0.5, 0); s.Position = UDim2.new(0.5, 0, 0, 42); s.Size = UDim2.fromOffset(46, 14); s.BackgroundTransparency = 1
	s.FontFace = FONT; s.TextSize = 11; s.TextColor3 = C(220, 205, 180); s.Text = k.short; s.ZIndex = 10; s.Parent = cell
	dots[k.id] = n
end
local rows = {}
local ROW_Y, ROW_H = 106, 46
for i, r in ipairs(R.recipes) do
	local row = Instance.new("Frame"); row.Position = UDim2.fromOffset(10, ROW_Y + (i - 1) * ROW_H); row.Size = UDim2.new(1, -20, 0, ROW_H - 6)
	row.BackgroundColor3 = C(78, 52, 28); row.BorderSizePixel = 0; row.ZIndex = 9; row.Parent = panel
	corner(row, 10)
	local nm = Instance.new("TextLabel"); nm.Position = UDim2.fromOffset(10, 3); nm.Size = UDim2.new(1, -130, 0, 18); nm.BackgroundTransparency = 1
	nm.FontFace = FONT; nm.TextSize = 15; nm.TextColor3 = CREAM; nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextTruncate = Enum.TextTruncate.AtEnd; nm.Text = r.name; nm.ZIndex = 10; nm.Parent = row
	local nd = Instance.new("TextLabel"); nd.Position = UDim2.fromOffset(10, 21); nd.Size = UDim2.new(1, -130, 0, 16); nd.BackgroundTransparency = 1
	nd.FontFace = FONT; nd.TextSize = 12; nd.TextColor3 = C(220, 205, 180); nd.TextXAlignment = Enum.TextXAlignment.Left; nd.TextTruncate = Enum.TextTruncate.AtEnd; nd.Text = R.needsText(r); nd.ZIndex = 10; nd.Parent = row
	local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, -8, 0.5, 0); b.Size = UDim2.fromOffset(112, 30)
	b.BackgroundColor3 = GOLD; b.BorderSizePixel = 0; b.FontFace = FONT; b.TextSize = 14; b.TextColor3 = C(84, 48, 18); b.AutoButtonColor = false; b.ZIndex = 10; b.Parent = row
	corner(b, 8)
	b.MouseButton1Click:Connect(function() ev:FireServer("make", r.id) end)
	rows[r.id] = {btn = b, name = nm}
end
local note = Instance.new("TextLabel"); note.Position = UDim2.fromOffset(12, ROW_Y + #R.recipes * ROW_H - 2); note.Size = UDim2.new(1, -24, 0, 22); note.BackgroundTransparency = 1
note.FontFace = FONT; note.TextSize = 13; note.TextColor3 = C(220, 205, 180); note.TextScaled = true; note.Text = ""; note.ZIndex = 9; note.Parent = panel
local function canMake(r)
	if r.keep and item(r.keep) > 0 then return false, "made" end
	for id, n in pairs(r.needs) do if item(id) < n then return false end end
	return true
end
local function refresh()
	for _, k in ipairs(R.kinds) do dots[k.id].Text = tostring(item(k.id)) end
	for _, r in ipairs(R.recipes) do
		local ok, why = canMake(r)
		local b = rows[r.id].btn
		if why == "made" then b.Text = "Yours"; b.BackgroundColor3 = GREEN; b.TextColor3 = CREAM
		else
			b.Text = r.keep and "Make & keep" or ("Make  " .. r.pay .. " acorns")
			b.BackgroundColor3 = ok and GOLD or GREY; b.TextColor3 = ok and C(84, 48, 18) or C(120, 100, 80)
		end
	end
end
-- the panel's face scales as one piece inside it; the panel itself keeps a plain pixel size, so its right edge is where it
-- is anchored (with the scale on the panel a phone cut it off at the right - Shannon, Oct 9)
local inner = Instance.new("Frame"); inner.Name = "Inner"; inner.BackgroundTransparency = 1; inner.ZIndex = 8; inner.Parent = panel
for _, c in ipairs(panel:GetChildren()) do if c ~= inner and c:IsA("GuiObject") then c.Parent = inner end end
local function layout()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local h = ROW_Y + #R.recipes * ROW_H + 24
	local sc = inner:FindFirstChild("PhoneScale") or Instance.new("UIScale"); sc.Name = "PhoneScale"; sc.Parent = inner
	local s = math.clamp((v.Y - 130) / h, 0.6, 1); sc.Scale = s -- a phone keeps the top HUD bar and the jump button clear
	local w, hh = math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s)
	inner.Size = UDim2.fromOffset(w, hh)
	panel.Size = UDim2.fromOffset(w * s, hh * s)
	panel.AnchorPoint = Vector2.new(1, 0.5)   -- anchored by its right edge (the construction line still said the centre; half of it hung off a phone - Oct 9)
	panel.Position = UDim2.new(1, phone() and -14 or -30, 0.5, 0)   -- 14 px off the right edge on a phone ("perfect"), 30 on a desktop ("a little to the left") - Shannon, Oct 9
	task.defer(function()   -- and never past it, whatever the screen does
		local over = panel.AbsolutePosition.X + panel.AbsoluteSize.X - (v.X - 2)
		if over > 0 then panel.Position = panel.Position - UDim2.fromOffset(over, 0) end
	end)
end
local function closePanel()
	if not open then return end
	open = false; panel.Visible = false
	local bp = bella() and bella():FindFirstChild("BellaPrompt", true); if bp then bp.Enabled = true end
	if pg:GetAttribute("OpenPanel") == "seaglass" then pg:SetAttribute("OpenPanel", nil) end
end
local function openPanel()
	if pg:GetAttribute("OpenPanel") ~= nil and pg:GetAttribute("OpenPanel") ~= "seaglass" then return end
	layout(); refresh(); note.Text = ""
	open = true; panel.Visible = true; pg:SetAttribute("OpenPanel", "seaglass")
	local bp = bella() and bella():FindFirstChild("BellaPrompt", true); if bp then bp.Enabled = false end   -- her prompt would draw over the panel (phones)
	local any = false
	for _, k in ipairs(R.kinds) do if item(k.id) > 0 then any = true break end end
	say(any and "Ciao! Let me see what the sea gave you today." or "Ciao, I'm Bella! Bring me pretty things from the sand and we'll make something.", 4.5)
end
closeBtn.MouseButton1Click:Connect(closePanel)
UIS.InputBegan:Connect(function(input, gp)
	if open and not gp and input.KeyCode == Enum.KeyCode.Escape then closePanel() end
end)
-- walked away from Bella: the panel goes
task.spawn(function()
	while true do
		task.wait(0.5)
		if open then
			local m, root = bella(), player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not m or not root or (m:GetPivot().Position - root.Position).Magnitude > 16 then closePanel() end
		end
	end
end)
for _, k in ipairs(R.kinds) do player:GetAttributeChangedSignal("Item_" .. k.id):Connect(function() if open then refresh() end end) end
player:GetAttributeChangedSignal("Item_parfum_bottle"):Connect(function() if open then refresh() end end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if open then layout() end end) end

-- the reveal (Oct 9 2026): what Bella made with you rises and spins in front of you, sparkling, then fades
local Debris = game:GetService("Debris")
-- a phone: the reveal also comes up big on the screen, on top of everything, spinning in a little window, then fades
-- (Shannon: "behind her character, low and small"; "on top of everything ... big and prominent for a moment")
local function screenReveal(src)
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local size = math.floor(math.min(v.Y * (phone() and 0.64 or 0.5), v.X * 0.42))   -- a phone needs most of its height; a desktop half
	local vp = Instance.new("ViewportFrame"); vp.Name = "Reveal"; vp.AnchorPoint = Vector2.new(0.5, 0.5); vp.Position = UDim2.fromScale(0.5, 0.5); vp.Size = UDim2.fromOffset(size * 0.6, size * 0.6)
	vp.BackgroundColor3 = BROWN; vp.BackgroundTransparency = 1; vp.ImageTransparency = 1; vp.ZIndex = 30
	vp.Ambient = Color3.fromRGB(190, 180, 160); vp.LightColor = Color3.fromRGB(255, 240, 210); vp.LightDirection = Vector3.new(-0.6, -1, -0.4)
	corner(vp, 18); local st = stroke(vp, GOLD, 3)
	local cam = Instance.new("Camera"); cam.FieldOfView = 40; cam.Parent = vp; vp.CurrentCamera = cam
	src.Parent = vp
	local cf, sz = src:GetBoundingBox()
	local centre, d = cf.Position, math.max(sz.X, sz.Y, sz.Z, 0.5) * 0.5 / math.tan(math.rad(20)) * 1.3
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(0, d * 0.35, d), centre)
	vp.Parent = gui
	TweenService:Create(vp, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(size, size)}):Play()
	TweenService:Create(vp, TweenInfo.new(0.3), {ImageTransparency = 0, BackgroundTransparency = 0.3}):Play()
	local t0, LIFE = os.clock(), 5.0
	local conn; conn = game:GetService("RunService").RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > LIFE or not vp.Parent then conn:Disconnect(); return end
		local a = t * 1.4
		cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(a) * d, d * 0.35, math.cos(a) * d), centre)
	end)
	task.delay(LIFE - 0.9, function()
		if not vp.Parent then return end
		TweenService:Create(vp, TweenInfo.new(0.9), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
		TweenService:Create(st, TweenInfo.new(0.9), {Transparency = 1}):Play()
	end)
	Debris:AddItem(vp, LIFE + 0.1)
end
local function reveal(id)
	local ok, m = pcall(R.build, id)
	if not ok or not m then return end
	if not UIS.VREnabled then pcall(screenReveal, m:Clone()) end   -- every flat screen (desktop too - Shannon): big and on top; the world one below carries on (and its sound); VR keeps the world one
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	local base = root and (root.CFrame * CFrame.new(-1.7, 0.6, -3.0)) or (cam and cam.CFrame * CFrame.new(-1.2, -0.8, -5)) or CFrame.new()   -- left and low: clear of her bubble (Oct 9)
	if phone() and cam then local bm = bella(); local d = bm and (bm:GetPivot().Position - cam.CFrame.Position).Magnitude or 8; base = cam.CFrame * CFrame.new(0, -0.9, -math.max(3.5, d - 2.5)) end   -- a phone: dead centre, just in front of Bella (Oct 9)
	if UIS.VREnabled and cam then   -- VR: in front of your eyes, where you look at this moment (Shannon: "front and center, even in VR")
		local okc, rcf = pcall(cam.GetRenderCFrame, cam); rcf = okc and rcf or cam.CFrame
		base = rcf * CFrame.new(0, -0.3, -3.3)   -- (a little farther off: "slightly smaller please", Oct 10)
		pcall(m.ScaleTo, m, 1.15)
	end
	local look = cam and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)
	if look.Magnitude > 0.01 then base = CFrame.new(base.Position, base.Position - look.Unit) end
	local core = m.PrimaryPart
	local sp = Instance.new("Sparkles"); sp.SparkleColor = Color3.fromRGB(255, 220, 120); sp.Parent = core
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 230, 170); l.Brightness = 1.5; l.Range = 9; l.Shadows = false; l.Parent = core
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9116394876"; s.Volume = 0.45; s.Parent = core
	m:PivotTo(base); m.Parent = workspace; s:Play()
	local parts = {}
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and p ~= core then table.insert(parts, {p = p, t = p.Transparency}) end end
	local t0 = os.clock(); local LIFE = 5.2
	local conn; conn = game:GetService("RunService").RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > LIFE or not m.Parent then conn:Disconnect(); return end
		local k = math.min(1, t / 1.6); k = k * k * (3 - 2 * k)
		local lift = (UIS.VREnabled and 0.45 or 1.8) * k + 0.15 * math.sin(t * 2.2)   -- (in VR it is already at eye level)
		local spin = t * (3.2 - 1.6 * k) + 0.4 * math.sin(t * 1.1)
		m:PivotTo(base * CFrame.new(0, lift, 0) * CFrame.Angles(0, spin, math.rad(8) * math.sin(t * 1.7)))
		if t > LIFE - 0.9 then
			local f = (t - (LIFE - 0.9)) / 0.9
			for _, e in ipairs(parts) do e.p.Transparency = e.t + (1 - e.t) * f end
			sp.Enabled = false; l.Brightness = 1.5 * (1 - f)
		end
	end)
	Debris:AddItem(m, LIFE + 0.2)
end
ev.OnClientEvent:Connect(function(what, a, b, c, d)
	if what == "open" then openPanel()
	elseif what == "found" then
		local name, count, rare = b, c, d
		showToast(string.format("%s! You have %d.", name, count), rare and 4 or 2.5)
		if rare then say(a == "pearl" and "A pearl! Bring it to me: a pearl deserves a box of shells." or "Is that... the purple one?! Bring it to me!", 5) end
	elseif what == "made" then
		local name, pay, line = b, c, d
		note.Text = pay > 0 and string.format("Bella pays %d acorns for the %s.", pay, name:lower()) or ("The " .. name:lower() .. " is yours to keep.")
		say(line or "Bellissima!", 5)
		refresh()
		reveal(a)
		panel.Visible = false; task.delay(6, function() if open then panel.Visible = true; refresh() end end)   -- the panel would sit on the reveal and her words (Shannon, VR)
	elseif what == "toast" then showToast(tostring(a), 4)
	elseif what == "nope" then
		note.Text = tostring(a)
	end
end)
print("SeaGlassClient: ready")

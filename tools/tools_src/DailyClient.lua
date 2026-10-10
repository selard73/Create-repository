-- FRENCH_ONLY_HUD_20261002_V1
-- Area is the authoritative live destination, not the permanent Item_porto unlock.
local function frenchMapHudAllowed()
    local area = game:GetService("Players").LocalPlayer:GetAttribute("Area")
    return area == "forest" or area == "village" or area == "domaine"
end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local action = RS:WaitForChild("DailyAction")
local ev = RS:WaitForChild("DailyEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18)
local FONT = Enum.Font.FredokaOne
local gui = Instance.new("ScreenGui"); gui.Name = "DailyGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15; gui.Parent = pg
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c end
local function label(parent, text, size, colour, y, h)
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -30, 0, h); l.Position = UDim2.new(0, 15, 0, y); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = text; l.TextWrapped = true; l.Parent = parent
	return l
end

-- the pill under the purse: who is golden today and where to look
local pill = Instance.new("TextLabel"); pill.Name = "GoldPill"; pill.AnchorPoint = Vector2.new(1, 0); pill.Position = UDim2.new(1, -12, 0, 72)
pill.AutomaticSize = Enum.AutomaticSize.X; pill.Size = UDim2.fromOffset(0, 24); pill.BackgroundColor3 = NAVY; pill.BackgroundTransparency = 0.15
pill.Font = FONT; pill.TextSize = 13; pill.TextColor3 = GOLD; pill.Text = ""; pill.Visible = false; pill.Parent = gui
corner(pill, 12)
local pp = Instance.new("UIPadding"); pp.PaddingLeft = UDim.new(0, 10); pp.PaddingRight = UDim.new(0, 10); pp.Parent = pill
local ps = Instance.new("UIStroke"); ps.Color = GOLD; ps.Thickness = 1; ps.Transparency = 0.5; ps.Parent = pill
-- NOT ON A PHONE (Shannon, Sep 26: "on mobile ... it takes up a lot of screen space", then: "you don't even need that
-- announcement. Afterwards, once you collect, it already tells you there that the squirrel's hiding in the chateau. You
-- don't need it again" - the daily card says where the golden squirrel is). Computers keep it all the time.
local UIS = game:GetService("UserInputService")
local phone = UIS.TouchEnabled and not UIS.MouseEnabled
local pillPhase = phone and "gone" or "on"

-- the daily card
local card = Instance.new("Frame"); card.Name = "DailyCard"; card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, -260)
card.Size = UDim2.fromOffset(340, 196); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Visible = false; card.Parent = gui
corner(card, 16)
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local title = label(card, "Daily Acorns", 24, CREAM, 10, 28); title.TextXAlignment = Enum.TextXAlignment.Center
local sub = label(card, "", 16, GOLD, 40, 20); sub.TextXAlignment = Enum.TextXAlignment.Center
local big = label(card, "", 34, GOLD, 62, 40); big.TextXAlignment = Enum.TextXAlignment.Center
local goldLine = label(card, "", 13, CREAM, 104, 34); goldLine.TextXAlignment = Enum.TextXAlignment.Center; goldLine.TextTransparency = 0.15
goldLine.Name = "GoldenSquirrelLine"
local function updateFrenchDailyHud()
    local french = frenchMapHudAllowed()
    goldLine.Visible = french
    pill.Visible = french and pill:GetAttribute("FrenchHudPillEligible") == true
        and pill:GetAttribute("FrenchHudPanelBlocked") ~= true
    if not french then
        local reveal = pg:FindFirstChild("GoldenReveal")
        if reveal then reveal.Enabled = false end
    end
end
player:GetAttributeChangedSignal("Area"):Connect(updateFrenchDailyHud)
pill:GetAttributeChangedSignal("FrenchHudPanelBlocked"):Connect(updateFrenchDailyHud)
updateFrenchDailyHud()

local btn = Instance.new("TextButton"); btn.AnchorPoint = Vector2.new(0.5, 0); btn.Position = UDim2.new(0.5, 0, 0, 148); btn.Size = UDim2.fromOffset(150, 38)
btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0; btn.Font = FONT; btn.TextSize = 19; btn.TextColor3 = DEEP; btn.Text = "Collect"; btn.AutoButtonColor = false; btn.Parent = card
corner(btn, 12)
local shown, busy = false, false
local function slide(y, secs) return TweenService:Create(card, TweenInfo.new(secs, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, y)}) end
local collect, autoToken   -- Collect's action (set below); the auto-collect timer (Shannon, Oct 9 2026, VR) shares it
local function showCard(state)
	sub.Text = state.streak > 1 and string.format("Day %d in a row", state.streak) or "Welcome back"
	big.Text = string.format("+%d acorns", state.reward)
	goldLine.Text = (state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""
	btn.Text = "Collect"; btn.BackgroundColor3 = GOLD
	card.Visible = true; shown = true
	local mine = {}; autoToken = mine
	task.delay(tonumber(script.Parent:GetAttribute("AutoCollect")) or 15, function()
		if autoToken == mine and shown and btn.Text == "Collect" and collect then collect() end   -- nobody pressed it: collect and go
	end)
	local openY = phone and 78 or 62
	slide(openY, 0.6):Play()                           -- phones leave a clear gap below the top icon row; desktop stays unchanged
end
local function hideCard()
	local t = slide(-260, 0.45); t:Play()
	t.Completed:Connect(function() card.Visible = false; shown = false end)
end
collect = function()
	if busy then return end
	busy = true
	local ok, res = action:InvokeServer("claim")
	if ok and type(res) == "table" then
		big.Text = string.format("+%d acorns", res.reward)
		-- the acorns fly from the card into the purse, with the ding (AcornClient shows it). (A gui that ignores the
		-- inset reports AbsolutePosition with the inset taken off, so it goes back on.)
		local sys = workspace:FindFirstChild("AcornSystem")
		local rf = sys and sys:FindFirstChild("RewardFly")
		if rf then
			local inset = game:GetService("GuiService"):GetGuiInset()
			rf:Fire(big.AbsolutePosition + big.AbsoluteSize / 2 + Vector2.new(0, inset.Y), res.reward)
		end
		btn.Text = "Collected!"; btn.BackgroundColor3 = C(150, 210, 120)
		local pop = TweenService:Create(big, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 42}); pop:Play()
		pop.Completed:Connect(function() TweenService:Create(big, TweenInfo.new(0.25), {TextSize = 34}):Play() end)
		task.delay(1.4, hideCard)
	else
		btn.Text = tostring(res or "later")
		task.delay(1.2, hideCard)
	end
	busy = false
end
btn.Activated:Connect(function() collect() end)

-- a small note at the bottom, for the golden find
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -110); note.Size = UDim2.fromOffset(440, 40)
note.BackgroundColor3 = NAVY; note.BackgroundTransparency = 1; note.BorderSizePixel = 0; note.Font = FONT; note.TextSize = 18; note.TextColor3 = GOLD
note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = gui
corner(note, 12)
local noteAt = 0
local function say(text)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); noteAt = mine
	task.delay(3.5, function() if noteAt ~= mine then return end; TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
end

-- once you have found today's golden squirrel it turns solid gold for you (this screen only: others still hunt it)
local function solidGold(burst)
	local daily = workspace:FindFirstChild("Daily")
	local g = daily and daily:FindFirstChild("GoldenSquirrel")
	if not g then return end
	for _, d in ipairs(g:GetDescendants()) do
		if d:IsA("Highlight") then d.Enabled = false
		elseif d:IsA("MeshPart") then d.TextureID = ""; d.Color = C(255, 214, 20); d.Material = Enum.Material.SmoothPlastic; d.Reflectance = 0.35   -- shiny materials go dark chrome in shade; plastic stays gold
		elseif d:IsA("SurfaceAppearance") then d:Destroy()
		elseif d:IsA("ParticleEmitter") and burst then d:Emit(50)
		end
	end
end
-- the reveal: a gold starburst, the golden squirrel rises up into the middle of the screen, turns once round, his
-- name and the acorns under him, then it all shrinks away (same shape as the find reveal; never takes input)
local function stroke(p, colour, th) local s = Instance.new("UIStroke"); s.Color = colour; s.Thickness = th; s.LineJoinMode = Enum.LineJoinMode.Round; s.Parent = p; return s end
local function goldReveal(name, reward)
	if not frenchMapHudAllowed() then return end
	local daily = workspace:FindFirstChild("Daily")
	local g = daily and daily:FindFirstChild("GoldenSquirrel")
	if not g then return end
	local cam0 = workspace.CurrentCamera
	local vpSize = cam0 and cam0.ViewportSize or Vector2.new(1280, 720)
	local S = math.min(vpSize.X, vpSize.Y)
	local rg = Instance.new("ScreenGui"); rg.Name = "GoldenReveal"; rg.ResetOnSpawn = false; rg.IgnoreGuiInset = true; rg.DisplayOrder = 18; rg.Parent = pg
	Debris:AddItem(rg, 9)
	local hold = Instance.new("Frame"); hold.AnchorPoint = Vector2.new(0.5, 0.5); hold.Position = UDim2.fromScale(0.5, 1.35); hold.Size = UDim2.fromOffset(S * 0.5, S * 0.5); hold.BackgroundTransparency = 1; hold.Parent = rg
	local scale = Instance.new("UIScale"); scale.Scale = 0.7; scale.Parent = hold
	for _, band in ipairs({{0.52, 0.3}, {0.68, 0.62}, {0.86, 0.82}, {1.06, 0.92}}) do
		local r = Instance.new("Frame"); r.AnchorPoint = Vector2.new(0.5, 0.5); r.Position = UDim2.fromScale(0.5, 0.5); r.Size = UDim2.fromScale(band[1], band[1])
		r.BackgroundColor3 = GOLD; r.BackgroundTransparency = band[2]; r.BorderSizePixel = 0; r.ZIndex = 2; r.Parent = hold
		corner(r, 9999)
	end
	local rays = Instance.new("Frame"); rays.AnchorPoint = Vector2.new(0.5, 0.5); rays.Position = UDim2.fromScale(0.5, 0.5); rays.Size = UDim2.fromScale(1, 1); rays.BackgroundTransparency = 1; rays.ZIndex = 3; rays.Parent = hold
	for i = 1, 12 do
		local ray = Instance.new("Frame"); ray.AnchorPoint = Vector2.new(0.5, 1); ray.Position = UDim2.fromScale(0.5, 0.5); ray.Size = UDim2.new(0.035, 0, 0.62, 0)
		ray.Rotation = (i - 1) * 30; ray.BackgroundColor3 = C(255, 236, 170); ray.BackgroundTransparency = 0.45; ray.BorderSizePixel = 0; ray.ZIndex = 3; ray.Parent = rays
	end
	local vp = Instance.new("ViewportFrame"); vp.AnchorPoint = Vector2.new(0.5, 0.5); vp.Position = UDim2.fromScale(0.5, 0.5); vp.Size = UDim2.fromScale(0.82, 0.82); vp.BackgroundTransparency = 1
	vp.Ambient = C(188, 186, 196); vp.LightColor = C(255, 251, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.5); vp.ZIndex = 5; vp.Parent = hold
	local copy = g:Clone()
	for _, d in ipairs(copy:GetDescendants()) do
		if d:IsA("Highlight") or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("ClickDetector") or d:IsA("SurfaceAppearance") or (d:IsA("BasePart") and d.Name == "Hitbox") then d:Destroy()
		elseif d:IsA("BasePart") then
			if d:IsA("MeshPart") then d.TextureID = "" end
			d.Color = C(255, 214, 20); d.Material = Enum.Material.SmoothPlastic; d.Reflectance = 0.35   -- shiny materials go dark chrome in shade; plastic stays gold
		end
	end
	copy.Parent = vp
	local cf, size = copy:GetBoundingBox()
	local centre, dist = cf.Position, size.Magnitude * 1.35
	local ang = math.atan2(cf.LookVector.X, cf.LookVector.Z)
	local cam = Instance.new("Camera"); cam.FieldOfView = 28; cam.Parent = vp; vp.CurrentCamera = cam
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(ang), 0.25, math.cos(ang)) * dist, centre)
	local nm = Instance.new("TextLabel"); nm.AnchorPoint = Vector2.new(0.5, 0); nm.Position = UDim2.fromScale(0.5, 0.84); nm.Size = UDim2.new(1.6, 0, 0.14, 0); nm.BackgroundTransparency = 1
	nm.Text = "Golden " .. tostring(name) .. "!"; nm.TextScaled = true; nm.Font = FONT; nm.TextColor3 = C(255, 250, 232); nm.ZIndex = 7; nm.Parent = hold
	local nsc = Instance.new("UITextSizeConstraint"); nsc.MaxTextSize = math.floor(S * 0.07); nsc.Parent = nm
	stroke(nm, C(74, 44, 18), math.max(2, S * 0.005))
	local rw = Instance.new("TextLabel"); rw.AnchorPoint = Vector2.new(0.5, 0); rw.Position = UDim2.fromScale(0.5, 0.98); rw.Size = UDim2.new(1.2, 0, 0.12, 0); rw.BackgroundTransparency = 1
	rw.Text = string.format("+%d acorns", tonumber(reward) or 0); rw.TextScaled = true; rw.Font = FONT; rw.TextColor3 = GOLD; rw.ZIndex = 7; rw.Parent = hold
	local rsc = Instance.new("UITextSizeConstraint"); rsc.MaxTextSize = math.floor(S * 0.06); rsc.Parent = rw
	stroke(rw, C(74, 44, 18), math.max(2, S * 0.005))
	TweenService:Create(hold, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.46)}):Play()
	TweenService:Create(scale, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local HOLD, t = 2.6, 0
	local spin
	spin = RunService.RenderStepped:Connect(function(dt)
		if not rg.Parent then spin:Disconnect() return end
		t = math.min(t + dt, HOLD)
		local k = t / HOLD
		local turn = (k * k * (3 - 2 * k)) * math.pi * 2
		rays.Rotation += dt * 9
		cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(ang + turn), 0.25, math.cos(ang + turn)) * dist, centre)
	end)
	task.delay(HOLD + 0.5, function()
		if not rg.Parent then return end
		local away = TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.05})
		away:Play()
		TweenService:Create(hold, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 0.2)}):Play()
		away.Completed:Connect(function() if spin then spin:Disconnect() end; rg:Destroy() end)
	end)
end
local function setPill(state)
	if not state.goldName or state.goldName == "" then pill:SetAttribute("FrenchHudPillEligible", false); updateFrenchDailyHud(); return end
	pill.Text = state.goldFound and ("Golden Squirrel: found today!") or string.format("Golden Squirrel: %s is hiding in %s", state.goldName, state.goldArea)
	pill:SetAttribute("FrenchHudPillEligible", pillPhase == "on")
	updateFrenchDailyHud()
end
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "state" and type(a) == "table" then
		setPill(a)
		if a.goldFound then task.delay(0.5, function() solidGold(false) end) end
		if a.claimable and not shown then showCard(a) end
	elseif what == "gold" then
		pill.Text = "Golden Squirrel: found today!"
		goldReveal(b, a)
		solidGold(true)
	end
end)

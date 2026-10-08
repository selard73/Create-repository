-- Cheese. Shannon: "you can buy and eat cheese and it gives you noticeable gas."
--
-- A sample stand on the pavement outside the FROMAGERIE sells a wedge (shop item "cheese", repeatable) - press E at
-- the stand; the store panel has no row for it. Buying is eating: the moment Item_cheese rises the
-- CheeseServer eats it (the count goes back down through the ledger) and the eater is gassy for GasSeconds - kept in
-- the ledger as Item_gassy (the moment it ends, server time), so it survives leaving and rejoining, which is only
-- fair. Gassy means: every few seconds a toot from the character's back, heard by everyone nearby, and a green puff
-- that drifts up behind them. Noticeable. The eater gets a toast ("That cheese was ripe. Excuse you.").
-- The toot is whatever sound FartSound names; the default is Shannon's pick from the Creator Store (139820289017229,
-- until Shannon picks a proper one from the Creator Store (set the attribute, no rebuild).
-- Attributes on workspace.Cheese: GasSeconds (90), TootEvery (first gap, 2.5), TootGrow (added per toot, 1.5), FartSound, PuffColour.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local C = Color3.fromRGB
	local F = workspace:FindFirstChild("Cheese")
	if not F then F = Instance.new("Folder"); F.Name = "Cheese"; F.Parent = workspace end
	local function default(name, v) if F:GetAttribute(name) == nil or opts[name] ~= nil then F:SetAttribute(name, opts[name] == nil and v or opts[name]) end end
	default("GasSeconds", 90); default("TootEvery", 2.5); default("TootGrow", 1.5); default("FartSound", "rbxassetid://139820289017229"); default("PuffColour", C(150, 200, 90))
	for _, n in ipairs({"CheeseServer", "CheeseClient", "Stand"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end

	-- ---- the sample stand, on the pavement just east of the FROMAGERIE door (x 200.8, the shop front at z -138.5), facing the street
	local at = opts.at or Vector3.new(204.6, 0.5, -136.8)
	local stand = Instance.new("Model"); stand.Name = "Stand"
	local base = CFrame.lookAt(at, at + Vector3.new(0, 0, 1))                    -- LookVector +z: the front faces the street
	local WOOD, WOOD_DARK, CLOTH, CHEESE, CHEESE_DEEP, HOLE = C(150, 110, 70), C(112, 80, 50), C(250, 246, 236), C(244, 208, 104), C(226, 184, 84), C(196, 150, 60)
	local function sp(name, size, cf, colour, material, class)
		local q = Instance.new(class or "Part"); q.Name = name; q.Size = size; q.CFrame = cf; q.Color = colour; q.Material = material or Enum.Material.Wood
		q.Anchored = true; q.CanCollide = true; q.TopSurface = Enum.SurfaceType.Smooth; q.BottomSurface = Enum.SurfaceType.Smooth; q.Parent = stand
		return q
	end
	local top = sp("Top", Vector3.new(2.6, 0.16, 1.5), base * CFrame.new(0, 2.5, 0), WOOD)
	for _, e in ipairs({{-1.15, -0.6}, {1.15, -0.6}, {-1.15, 0.6}, {1.15, 0.6}}) do sp("Leg", Vector3.new(0.2, 2.42, 0.2), base * CFrame.new(e[1], 1.21, e[2]), WOOD_DARK) end
	local cloth = sp("Cloth", Vector3.new(2.4, 0.06, 1.34), base * CFrame.new(0, 2.61, 0), CLOTH, Enum.Material.Fabric); cloth.CanCollide = false
	local board = sp("Board", Vector3.new(0.08, 1.25, 1.25), base * CFrame.new(-0.6, 2.68, 0) * CFrame.Angles(0, 0, math.rad(90)), WOOD_DARK, Enum.Material.Wood); board.Shape = Enum.PartType.Cylinder; board.CanCollide = false
	local wheel = sp("Wheel", Vector3.new(0.34, 1.05, 1.05), base * CFrame.new(-0.6, 2.89, 0) * CFrame.Angles(0, 0, math.rad(90)), CHEESE, Enum.Material.SmoothPlastic); wheel.Shape = Enum.PartType.Cylinder; wheel.CanCollide = false
	for _, h in ipairs({{-0.75, 3.07, 0.25}, {-0.45, 3.07, -0.3}, {-0.62, 3.07, -0.02}, {-0.3, 3.07, 0.28}}) do local d = sp("Hole", Vector3.new(0.14, 0.05, 0.14), base * CFrame.new(h[1], h[2], h[3]), HOLE, Enum.Material.SmoothPlastic); d.CanCollide = false end
	for i, w in ipairs({{0.45, -0.35, 20}, {0.85, 0.1, -35}, {0.5, 0.42, 70}}) do
		local wedge = sp("Wedge", Vector3.new(0.5, 0.36, 0.72), base * CFrame.new(w[1], 2.82, w[2]) * CFrame.Angles(0, math.rad(w[3]), 0), i == 2 and CHEESE_DEEP or CHEESE, Enum.Material.SmoothPlastic, "WedgePart")
		wedge.CanCollide = false
	end
	-- the little sign at the back: what it is and what it costs (the server keeps the price line current)
	sp("SignPost", Vector3.new(0.12, 1.3, 0.12), base * CFrame.new(1.1, 3.2, 0.62), WOOD_DARK)
	local sign = sp("Sign", Vector3.new(1.5, 0.7, 0.08), base * CFrame.new(0.75, 3.95, 0.62), C(232, 214, 176), Enum.Material.Wood); sign.CanCollide = false   -- faces the street (Shannon: it was turned the wrong way)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 90; sg.Parent = sign
	local st = Instance.new("TextLabel"); st.Name = "Title"; st.Size = UDim2.fromScale(1, 0.55); st.BackgroundTransparency = 1; st.Font = Enum.Font.Antique; st.TextScaled = true; st.TextColor3 = C(64, 42, 22); st.Text = "Degustation"; st.Parent = sg
	local sp2 = Instance.new("TextLabel"); sp2.Name = "Price"; sp2.Size = UDim2.fromScale(1, 0.4); sp2.Position = UDim2.fromScale(0, 0.58); sp2.BackgroundTransparency = 1; sp2.Font = Enum.Font.FredokaOne; sp2.TextScaled = true; sp2.TextColor3 = C(150, 52, 30); sp2.Text = "a wedge - 8 acorns"; sp2.Parent = sg
	-- the prompt: bought through the shop's own prompt path (ShopServer listens for the ShopItem attribute)
	local prompt = Instance.new("ProximityPrompt"); prompt.Name = "TastePrompt"; prompt.ActionText = "Try a wedge"; prompt.ObjectText = "Fromagerie samples"
	prompt.KeyboardKeyCode = Enum.KeyCode.E; prompt.MaxActivationDistance = 8; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0
	prompt:SetAttribute("ShopItem", "cheese"); prompt.Parent = cloth
	stand.PrimaryPart = top
	stand.Parent = F

	local SERVER = [==[
-- CheeseServer: eats what was bought, and makes the eater gassy for everyone to notice
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local F = script.Parent
local awardItems = RS:WaitForChild("AwardItems")
local function now() return workspace:GetServerTimeNow() end
local gassy = {}                                             -- player -> true while their loop runs

local Shop = workspace:WaitForChild("Shop")
local TweenService = game:GetService("TweenService")
-- the stand's sign and prompt follow the shop's price and switch
local function refreshStand()
	local stand = F:FindFirstChild("Stand"); if not stand then return end
	local price = Shop:GetAttribute("Price_cheese")
	local on = Shop:GetAttribute("Selling") == true or Shop:GetAttribute("Sell_cheese") == true
	local sign = stand:FindFirstChild("Sign"); local sg = sign and sign:FindFirstChildOfClass("SurfaceGui"); local pl = sg and sg:FindFirstChild("Price")
	if pl then pl.Text = on and string.format("a wedge - %s acorns", tostring(price)) or "opening soon" end
	local prompt = stand:FindFirstChild("TastePrompt", true)
	if prompt then prompt.ObjectText = on and string.format("Fromagerie samples  -  %s acorns", tostring(price)) or "Fromagerie samples  -  opening soon"; prompt.Enabled = true end
end
refreshStand()
for _, a in ipairs({"Price_cheese", "Sell_cheese", "Selling"}) do Shop:GetAttributeChangedSignal(a):Connect(refreshStand) end
-- eating, for all to see: a wedge at the hand travels to the mouth, three bites, then it is gone
local function eatShow(player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return 0 end
	local wedge = Instance.new("WedgePart"); wedge.Name = "CheeseWedge"; wedge.Size = Vector3.new(0.5, 0.36, 0.72); wedge.Color = Color3.fromRGB(244, 208, 104)
	wedge.Material = Enum.Material.SmoothPlastic; wedge.CanCollide = false; wedge.CanQuery = false; wedge.CanTouch = false; wedge.Massless = true; wedge.Parent = char
	for _, o in ipairs({Vector3.new(0.1, 0.19, 0.1), Vector3.new(-0.12, 0.19, -0.15)}) do
		local d = Instance.new("Part"); d.Shape = Enum.PartType.Ball; d.Size = Vector3.new(0.12, 0.12, 0.12); d.Color = Color3.fromRGB(196, 150, 60); d.Material = Enum.Material.SmoothPlastic
		d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Massless = true; d.Parent = wedge
		local w = Instance.new("Weld"); w.Part0 = wedge; w.Part1 = d; w.C0 = CFrame.new(o); w.Parent = d
	end
	local weld = Instance.new("Weld"); weld.Part0 = head; weld.Part1 = wedge
	weld.C0 = CFrame.new(1.1, -1.4, -0.5) * CFrame.Angles(0, math.rad(-30), math.rad(20))          -- about where the right hand rests
	weld.Parent = wedge
	TweenService:Create(weld, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = CFrame.new(0.05, -0.32, -0.72) * CFrame.Angles(math.rad(20), math.rad(-80), 0)}):Play()
	task.spawn(function()
		task.wait(0.7)
		for bite = 1, 3 do
			if not wedge.Parent then return end
			local snd = Instance.new("Sound"); snd.SoundId = "rbxasset://sounds/snap.mp3"; snd.Volume = 0.9; snd.PlaybackSpeed = 0.75 + bite * 0.08; snd.Parent = head; snd:Play(); Debris:AddItem(snd, 2)
			wedge.Size = wedge.Size * Vector3.new(0.75, 0.85, 0.75)
			local att = Instance.new("Attachment"); att.Parent = head; att.Position = Vector3.new(0, -0.35, -0.7)
			local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(244, 208, 104))
			pe.Size = NumberSequence.new(0.18, 0.08); pe.Lifetime = NumberRange.new(0.5, 0.9); pe.Speed = NumberRange.new(2, 4); pe.SpreadAngle = Vector2.new(50, 50); pe.Acceleration = Vector3.new(0, -25, 0); pe.Rate = 0; pe.LightEmission = 0.2; pe.Parent = att
			pe:Emit(8); Debris:AddItem(att, 1.5)
			task.wait(0.55)
		end
		if wedge.Parent then wedge:Destroy() end
		local bg = Instance.new("BillboardGui"); bg.Size = UDim2.new(0, 120, 0, 44); bg.StudsOffset = Vector3.new(0, 2.2, 0); bg.AlwaysOnTop = true; bg.Parent = head
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.TextColor3 = Color3.fromRGB(255, 240, 200); l.TextStrokeTransparency = 0.3; l.Text = "Mmm!"; l.Parent = bg
		Debris:AddItem(bg, 1.4)
	end)
	return 3.0
end
-- the toot cloud: a cartoon puff of green balls that swells, drifts up and back, and fades - with a Pfft!
local function puff(hrp)
	local cloud = Instance.new("Model"); cloud.Name = "Toot"
	local origin = hrp.CFrame * CFrame.new(0, -0.9, 1.3)
	local col = F:GetAttribute("PuffColour") or Color3.fromRGB(150, 200, 90)
	local pale = Color3.fromRGB(math.min(255, col.R * 255 + 40), math.min(255, col.G * 255 + 25), math.min(255, col.B * 255 + 50))
	local balls = {}
	for i, b in ipairs({{0, 0, 0, 1.3}, {0.55, 0.2, 0.2, 1.0}, {-0.5, 0.25, 0.1, 0.95}, {0.1, 0.55, -0.15, 0.9}, {0.15, -0.35, 0.35, 0.8}, {-0.3, -0.2, 0.4, 0.7}}) do
		local q = Instance.new("Part"); q.Shape = Enum.PartType.Ball; q.Size = Vector3.new(b[4], b[4], b[4]); q.Color = (i % 2 == 0) and pale or col; q.Material = Enum.Material.SmoothPlastic
		q.Anchored = true; q.CanCollide = false; q.CanQuery = false; q.CanTouch = false; q.CastShadow = false; q.Transparency = 0.1
		q.CFrame = origin * CFrame.new(b[1], b[2], b[3]); q.Parent = cloud
		balls[#balls + 1] = {part = q, off = Vector3.new(b[1], b[2], b[3]), size = b[4]}
	end
	cloud.Parent = workspace
	local back = hrp.CFrame.LookVector * -1
	for _, b in ipairs(balls) do
		local goal = origin * CFrame.new(b.off * 1.9) + Vector3.new(0, 1.6, 0) + back * 1.2
		TweenService:Create(b.part, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = goal, Size = Vector3.new(b.size, b.size, b.size) * 1.8, Transparency = 1}):Play()
	end
	Debris:AddItem(cloud, 1.7)
	-- several small, thin, faint "pfft"s trail out behind (Shannon), each one placed behind wherever the player is by then
	task.spawn(function()
		local words = {"pfft", "pff", "pffft", "pft", "pfft"}
		for i = 1, #words do
			local cf = hrp.CFrame
			local b = cf.LookVector * -1
			local side = (i % 2 == 0) and 1 or -1
			local a = Instance.new("Part"); a.Size = Vector3.new(0.2, 0.2, 0.2); a.Transparency = 1; a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false; a.CastShadow = false
			a.Position = cf.Position + Vector3.new(0, -0.4 + i * 0.25, 0) + b * (1.2 + i * 0.5) + cf.RightVector * side * (0.5 + i * 0.12)
			local bg = Instance.new("BillboardGui"); bg.Size = UDim2.new(0, 56, 0, 22); bg.AlwaysOnTop = false; bg.LightInfluence = 0; bg.Parent = a
			local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Font = Enum.Font.SourceSansLight; l.TextScaled = true
			l.TextColor3 = Color3.fromRGB(70, 110, 40); l.TextTransparency = 0.3; l.TextStrokeColor3 = Color3.fromRGB(20, 40, 10); l.TextStrokeTransparency = 0.7; l.Text = words[i]; l.Rotation = side * (6 + i * 2); l.Parent = bg
			a.Parent = workspace
			TweenService:Create(a, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = a.Position + b * 1.3 + Vector3.new(0, 0.8, 0)}):Play()
			TweenService:Create(l, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			Debris:AddItem(a, 1.6)
			task.wait(0.13)
		end
	end)
end
local function puffOld(hrp)
	local att = Instance.new("Attachment"); att.Name = "GasVent"; att.Position = Vector3.new(0, -0.7, 0.9); att.Parent = hrp
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	local col = F:GetAttribute("PuffColour") or Color3.fromRGB(150, 200, 90)
	pe.Color = ColorSequence.new(col, Color3.fromRGB(200, 220, 160)); pe.LightEmission = 0.1; pe.LightInfluence = 0.7
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 3.0)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(1.8, 2.8); pe.Speed = NumberRange.new(3, 6); pe.SpreadAngle = Vector2.new(25, 25)
	pe.Acceleration = Vector3.new(0, 2.5, 0); pe.Drag = 1.5; pe.Rate = 0; pe.EmissionDirection = Enum.NormalId.Back
	pe.Parent = att
	pe:Emit(26)
	Debris:AddItem(att, 3)
end
-- one Toot sound per character, made ahead of the first toot so it is loaded on every client by the time it plays;
-- a fresh Sound per toot had to load first and came in after the cloud (Shannon: "sync them so they occur together")
local function tootSound(hrp)
	local s = hrp:FindFirstChild("Toot")
	if not s then
		local id = F:GetAttribute("FartSound") or "rbxassetid://139820289017229"
		s = Instance.new("Sound"); s.Name = "Toot"; s.SoundId = id; s.Volume = 1.2; s.RollOffMaxDistance = 60; s.RollOffMinDistance = 6; s.Parent = hrp
	end
	return s
end
local function toot(hrp)
	local s = tootSound(hrp)
	s.PlaybackSpeed = 0.85 + math.random() * 0.3
	s.TimePosition = 0
	s:Play()
end
local fresh = {}                                             -- player -> true when a new wedge just went down
local function runGas(player)
	if gassy[player] then return end
	gassy[player] = true
	task.spawn(function()
		-- Shannon: the toots thin out - quick at first, then more and more time between them until the gas is gone.
		-- The gap starts at TootEvery and grows by TootGrow after every toot; a fresh wedge starts it over.
		local start = F:GetAttribute("TootEvery") or 2.5
		local grow = F:GetAttribute("TootGrow") or 1.5
		local gap = start
		while player.Parent and (player:GetAttribute("Item_gassy") or 0) > now() do
			if fresh[player] then fresh[player] = nil; gap = start end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then toot(hrp); puff(hrp) end
			task.wait(gap * (0.85 + math.random() * 0.3))
			gap = gap + grow
		end
		gassy[player] = nil
	end)
end
local function eat(player)
	local n = player:GetAttribute("Item_cheese") or 0
	if n <= 0 then return end
	awardItems:Fire(player, "cheese", -n)                    -- eaten: the count goes back down through the ledger
	local secs = F:GetAttribute("GasSeconds") or 90
	local untilNow = player:GetAttribute("Item_gassy") or 0
	local base = math.max(untilNow, now())                    -- a second wedge extends the sentence
	fresh[player] = true                                      -- a wedge is going down: eat() starts the toots after the chewing, quick again
	awardItems:Fire(player, "gassy", math.floor(base + secs * n) - untilNow)
	print(string.format("Cheese: %s ate %d wedge(s); gassy for %ds", player.Name, n, math.floor(base + secs * n - now())))
	do local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if hrp then tootSound(hrp) end end   -- loads while they chew
	local delay = eatShow(player)                             -- chew first; the consequences follow
	task.delay(delay, function() runGas(player) end)
end
local function watch(player)
	player:GetAttributeChangedSignal("Item_cheese"):Connect(function() eat(player) end)
	player:GetAttributeChangedSignal("Item_gassy"):Connect(function() if not fresh[player] and (player:GetAttribute("Item_gassy") or 0) > now() then runGas(player) end end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function()
		if (player:GetAttribute("Item_cheese") or 0) > 0 then eat(player) end        -- bought and left before eating: eat now
		if (player:GetAttribute("Item_gassy") or 0) > now() then runGas(player) end   -- still ripe from last time
	end)
	if (player:GetAttribute("Item_gassy") or 0) > now() then runGas(player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) gassy[p] = nil end)
print("CheeseServer: ready - " .. tostring(F:GetAttribute("GasSeconds")) .. "s of gas a wedge")
]==]
	local CLIENT = [==[
-- CheeseClient: the eater's toast, and a green tinge at the edges of their screen while it lasts
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local C = Color3.fromRGB
task.spawn(function()                                        -- have the toot loaded before anyone here eats a wedge
	local id = F:GetAttribute("FartSound")
	if id then pcall(function() local s = Instance.new("Sound"); s.SoundId = id; game:GetService("ContentProvider"):PreloadAsync({s}); s:Destroy() end) end
end)
local gui = Instance.new("ScreenGui"); gui.Name = "CheeseGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 6; gui.Parent = pg
local tinge = Instance.new("Frame"); tinge.Size = UDim2.fromScale(1, 1); tinge.BackgroundColor3 = C(120, 190, 60); tinge.BackgroundTransparency = 1; tinge.BorderSizePixel = 0; tinge.Parent = gui
local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.35, 1), NumberSequenceKeypoint.new(0.65, 1), NumberSequenceKeypoint.new(1, 0.55)}); g.Rotation = 90; g.Parent = tinge
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118); toast.Size = UDim2.fromOffset(420, 44)
toast.BackgroundColor3 = C(58, 36, 16); toast.BackgroundTransparency = 0.1; toast.BorderSizePixel = 0; toast.Font = Enum.Font.FredokaOne; toast.TextSize = 20
toast.TextColor3 = C(255, 202, 62); toast.TextWrapped = true; toast.Text = ""; toast.Visible = false; toast.Parent = gui
local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = toast
local toastAt = 0
local function say(text)
	toast.Text = text; toast.Visible = true
	local t = os.clock(); toastAt = t
	task.delay(4, function() if toastAt == t then toast.Visible = false end end)
end
local lastUntil = player:GetAttribute("Item_gassy") or 0
player:GetAttributeChangedSignal("Item_gassy"):Connect(function()
	local u = player:GetAttribute("Item_gassy") or 0
	if u > lastUntil and u > workspace:GetServerTimeNow() then say("That cheese was ripe. Excuse you.") end
	lastUntil = u
end)
task.spawn(function()
	while true do
		local on = (player:GetAttribute("Item_gassy") or 0) > workspace:GetServerTimeNow()
		local want = on and 0.7 or 1
		if math.abs(tinge.BackgroundTransparency - want) > 0.01 then TweenService:Create(tinge, TweenInfo.new(1.2), {BackgroundTransparency = want}):Play() end
		task.wait(1)
	end
end)
]==]
	local function install(name, ctx, src)
		local s = Instance.new("Script"); s.Name = name; s.RunContext = ctx; s.Source = src; s.Parent = F
	end
	install("CheeseServer", Enum.RunContext.Server, SERVER)
	install("CheeseClient", Enum.RunContext.Client, CLIENT)
	print(string.format("Cheese: stand at (%.1f,%.1f,%.1f); %ss of gas a wedge, a toot every ~%ss, sound %s", at.X, at.Y, at.Z, tostring(F:GetAttribute("GasSeconds")), tostring(F:GetAttribute("TootEvery")), tostring(F:GetAttribute("FartSound"))))
end

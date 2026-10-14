-- PortoKeeperClient: a banner and a chat line when someone becomes the Guardian of the Harbour; a quiet note to late finders.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local TextChatService = game:GetService("TextChatService")
local F = script.Parent
local Celebration = require(F:WaitForChild("KeeperCelebration"))
local daily = workspace:FindFirstChild("Daily")
local OFFSET = daily and daily:GetAttribute("DayOffsetHours") or 9
local celebrationGate = Celebration.new(function() return workspace:GetServerTimeNow() end,
    function(at) return math.floor((at - OFFSET * 3600) / 86400) end)
local ev = RS:WaitForChild("PortoKeeperEvent")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local function chat(text)
    task.spawn(function()
        local ok, err = pcall(function()
            local channels = TextChatService:WaitForChild("TextChannels", 5)
            local channel = channels and channels:WaitForChild("RBXGeneral", 5)
            assert(channel, "RBXGeneral unavailable")
            local safe = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
            channel:DisplaySystemMessage(safe)
        end)
        if not ok then warn("PortoKeeper: chat announcement unavailable: " .. tostring(err)) end
    end)
end
local function showBanner(big, small)
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui"); gui.Name = "PortoKeeperBanner"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 26; gui.Parent = pg
	local f = Instance.new("Frame"); f.AnchorPoint = Vector2.new(0.5, 0); f.Position = UDim2.new(0.5, 0, 0, -140); f.Size = UDim2.fromOffset(620, 110)
	f.BackgroundColor3 = C(28, 32, 60); f.BackgroundTransparency = 0.08; f.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 18); corner.Parent = f
	local stroke = Instance.new("UIStroke"); stroke.Color = C(232, 191, 74); stroke.Thickness = 4; stroke.Parent = f
	local t1 = Instance.new("TextLabel"); t1.Size = UDim2.new(1, -30, 0, 54); t1.Position = UDim2.new(0, 15, 0, 10); t1.BackgroundTransparency = 1
	t1.Font = Enum.Font.FredokaOne; t1.TextScaled = true; t1.TextColor3 = C(255, 222, 110); t1.Text = big; t1.Parent = f
	local t2 = Instance.new("TextLabel"); t2.Size = UDim2.new(1, -30, 0, 32); t2.Position = UDim2.new(0, 15, 0, 66); t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.Merriweather; t2.TextScaled = true; t2.TextColor3 = C(255, 246, 220); t2.Text = small; t2.Parent = f
	local sc = Instance.new("UIScale"); sc.Parent = f
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	sc.Scale = math.min(1, (vw - 24) / 620)
	TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 70)}):Play()
	task.delay(9, function()
		TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -140)}):Play()
		task.wait(0.5); gui:Destroy()
	end)
end
local pg = player:WaitForChild("PlayerGui")
local function dailyCardUp()                          -- the daily acorns card is showing (nothing goes on top of it: Shannon)
	local dg = pg:FindFirstChild("DailyGui")
	local dc = dg and dg:FindFirstChild("DailyCard")
	return dc ~= nil and dc:IsA("GuiObject") and dc.Visible and dg.Enabled
end
local function titleBannerUp()                        -- the honours' "You are now a ..." banner (finding all 44 brings both at once)
	local hb = pg:FindFirstChild("HonourBar")
	local b = hb and hb:FindFirstChild("Banner")
	return b ~= nil and b:IsA("GuiObject") and b.Visible
end
local function banner(big, small)
    task.spawn(function()
        local started = os.clock()
        task.wait(0.3)
        while (dailyCardUp() or titleBannerUp()) and os.clock() - started < 90 do task.wait(0.3) end
        showBanner(big, small)
    end)
end

-- France-style fireworks across Italy; cosmetic instances exist only on each client.
-- Surveyed Italy launch sites: {x, z, ground height}; exclude the French maps.
local SITES = {{240,-580,-48.625},{360,-600,-44.0234},{490,-640,-0.8497},
    {250,-800,-52.9219},{370,-810,-40.2748},{490,-840,16.5684},
    {250,-1010,-52.9219},{365,-1070,-52.9219},{490,-1130,1.4023}}
local COLOURS = {C(255, 60, 60), C(255, 150, 40), C(255, 230, 60), C(80, 230, 90), C(60, 220, 255), C(80, 120, 255), C(180, 90, 255), C(255, 90, 200)}
local function sound(id, parent, vol)
	if not id or id == "" then return end
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = 700; s.RollOffMinDistance = 40; s.Parent = parent; pcall(function() s:Play() end)
	Debris:AddItem(s, 6)
end
local function threeColours(first)
	local picks, used = {first}, {[first] = true}
	for _ = 1, 30 do
		if #picks >= 3 then break end
		local c = COLOURS[math.random(1, #COLOURS)]
		if not used[c] then used[c] = true; picks[#picks + 1] = c end
	end
	return picks
end
local function rocket(x, z, groundY)
	local colour = COLOURS[math.random(1, #COLOURS)]
	local topY = groundY + math.random(80, 120)
	-- a bright spark going up with only a short, faint wisp behind it (Shannon: "less of a tail traveling up")
	local r = Instance.new("Part"); r.Name = "ItalyFireworkRocket"; r.Shape = Enum.PartType.Ball; r.Size = Vector3.new(0.45, 0.45, 0.45); r.Anchored = true; r.CanCollide = false; r.CanQuery = false; r.CanTouch = false
	r.CastShadow = false; r.Material = Enum.Material.Neon; r.Color = colour; r.CFrame = CFrame.new(x, groundY + 4, z); r.Parent = workspace; Debris:AddItem(r, 5)
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.08, 0); a0.Parent = r
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.08, 0); a1.Parent = r
	local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.035; tr.LightEmission = 1; tr.FaceCamera = true
	tr.Color = ColorSequence.new(colour); tr.Transparency = NumberSequence.new(0.7, 1); tr.WidthScale = NumberSequence.new(1, 0); tr.Parent = r
	sound(F:GetAttribute("FireworkLaunch"), r, 0.5)
	local up = TweenService:Create(r, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(x + math.random(-6, 6), topY, z + math.random(-6, 6))})
	up:Play()
	up.Completed:Connect(function()
		local at = r.CFrame
		r.Transparency = 1
		local b = Instance.new("Part"); b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.Transparency = 1; b.Size = Vector3.new(1, 1, 1); b.CFrame = at; b.Parent = workspace
		local att = Instance.new("Attachment"); att.Parent = b
		-- three colours in every burst, big bright stars that read against a daytime sky, and a glitter of white
		local picks = threeColours(colour)
		picks[#picks + 1] = C(255, 250, 225)
		for k, col in ipairs(picks) do
			local white = k == #picks
			local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.LightEmission = 1; pe.LightInfluence = 0
			pe.Brightness = 2; pe.Color = ColorSequence.new(col); pe.Speed = NumberRange.new(white and 20 or 34, white and 30 or 52)
			pe.SpreadAngle = Vector2.new(180, 180); pe.Drag = 2.2; pe.Acceleration = Vector3.new(0, -9, 0); pe.Lifetime = NumberRange.new(1.6, 2.6)
			pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, white and 1.4 or 3.2), NumberSequenceKeypoint.new(0.6, white and 1 or 2.2), NumberSequenceKeypoint.new(1, 0)})
			pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.15), NumberSequenceKeypoint.new(1, 1)})
			pe.Rate = 0; pe.Parent = att; pe:Emit(white and 20 or 34)
		end
		-- and a flash of the main colour as it goes
		local ball = Instance.new("Part"); ball.Shape = Enum.PartType.Ball; ball.Material = Enum.Material.Neon; ball.Color = colour; ball.CastShadow = false
		ball.Anchored = true; ball.CanCollide = false; ball.CanQuery = false; ball.CanTouch = false; ball.Size = Vector3.new(2, 2, 2); ball.Transparency = 0.2; ball.CFrame = at; ball.Parent = workspace
		TweenService:Create(ball, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(14, 14, 14), Transparency = 1}):Play()
		Debris:AddItem(ball, 0.6)
		local light = Instance.new("PointLight"); light.Color = colour; light.Brightness = 6; light.Range = 60; light.Parent = b
		TweenService:Create(light, TweenInfo.new(0.5), {Brightness = 0}):Play()
		sound(F:GetAttribute("FireworkPop"), b, 0.8)
		Debris:AddItem(b, 3); Debris:AddItem(r, 0.7)
	end)
end
local showing = false
local function fireworks(secs)
	if showing then return end
	showing = true
	local id = "rbxassetid://9114447178" -- same show audio as France; visuals do not depend on audio
	if id and id ~= "" then
		local s = Instance.new("Sound"); s.Name = "ItalyFireworkShow"; s.SoundId = id; s.Looped = true; s.Volume = F:GetAttribute("FireworkVolume") or 0.6
		s.Parent = game:GetService("SoundService"); pcall(function() s:Play() end)
		task.delay(secs + 1, function()
			local t = TweenService:Create(s, TweenInfo.new(2), {Volume = 0}); t:Play()
			t.Completed:Connect(function() s:Destroy() end)
		end)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < secs do
			-- most of the show goes up over whichever map this screen is looking at; now and then one over a far map
			local cam = workspace.CurrentCamera
			local here = cam and cam.CFrame.Position or Vector3.zero
			local order = {}
			for k, st in ipairs(SITES) do order[k] = {s = st, d = (Vector2.new(st[1], st[2]) - Vector2.new(here.X, here.Z)).Magnitude} end
			table.sort(order, function(a, b) return a.d < b.d end)
			for k, chance in ipairs({1, 0.8, 0.55}) do
				if math.random() < chance then local st = order[k].s; rocket(st[1], st[2], st[3]) end
			end
			if math.random() < 0.25 then local st = order[math.random(4, #order)].s; rocket(st[1], st[2], st[3]) end
			task.wait(0.35 + math.random() * 0.2)
		end
		showing = false
	end)
end


local receipts = {}
ev.OnClientEvent:Connect(function(what, a)
	if what == "crowned" and type(a) == "table" then
        if not celebrationGate.accept(a) then return end
        local showOk, showError = pcall(fireworks, 25)
        if not showOk then warn("PortoKeeper: fireworks unavailable: " .. tostring(showError)) end
		local t = workspace:FindFirstChild("PortoKeeper") and workspace.PortoKeeper:GetAttribute("Title") or "Guardian of the Harbour"
		if a.uid == player.UserId then
			banner("You are the " .. t .. "!", "Your statue stands by the lighthouse, holding the harbour key")
		else
			banner(tostring(a.name) .. " is the " .. t .. "!", "First today to find all " .. tostring(a.total or 44) .. " squirrels of Porto Nocciola")
		end
		chat(string.format("%s found all %d squirrels of Porto Nocciola first today and is the %s. Their statue stands by the lighthouse.", tostring(a.name), tonumber(a.total) or 44, t))
    elseif what == "recovered" and type(a) == "table" then
        if receipts[a.claimId] then return end
        receipts[a.claimId] = true
        chat("Your Guardian award for " .. os.date("!%B %d, %Y", a.day * 86400 + 43200) .. " is confirmed. You keep your title; the lighthouse displays today's winner.")
    elseif what == "late" then
        local record = type(a) == "table" and a or {name=tostring(a)}
        if record.claimId and receipts[record.claimId] then return end
        if record.claimId then receipts[record.claimId] = true end
        local date = record.day and (" for " .. os.date("!%B %d, %Y", record.day * 86400 + 43200)) or " today"
        chat("You found every squirrel in Porto Nocciola! " .. tostring(record.name) .. " holds the award" .. date .. ". To compete on another day, reset your finds and collect all 44 again.")
    elseif what == "reset_needed" then
        chat("To compete on another day, reset your finds and collect all 44 Italy squirrels again.")
    elseif what == "unavailable" then
        chat("Your Guardian result is pending. We will retry automatically and when you rejoin, for the day you completed Italy.")
	elseif what == "already" then
		chat("You already hold the harbour key, Guardian.")
	end
end)


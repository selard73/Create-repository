local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = RS:WaitForChild("ChampionEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220)
local FONT = Enum.Font.FredokaOne
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end

-- ---- the announcement ----
local gui = Instance.new("ScreenGui"); gui.Name = "ChampionGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 17; gui.Parent = pg
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, -120); card.Size = UDim2.new(0.9, 0, 0, 78)
card.BackgroundColor3 = NAVY; card.BackgroundTransparency = 0.05; card.BorderSizePixel = 0; card.Visible = false; card.Parent = gui
local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(560, 78); lim.Parent = card
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 16); cc.Parent = card
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2.5; cs.Parent = card
local l1 = Instance.new("TextLabel"); l1.BackgroundTransparency = 1; l1.Position = UDim2.fromOffset(12, 8); l1.Size = UDim2.new(1, -24, 0, 32)
l1.Font = FONT; l1.TextScaled = true; l1.TextColor3 = GOLD; l1.Text = ""; l1.Parent = card
local l1c = Instance.new("UITextSizeConstraint"); l1c.MaxTextSize = 26; l1c.Parent = l1
local l2 = Instance.new("TextLabel"); l2.BackgroundTransparency = 1; l2.Position = UDim2.fromOffset(12, 42); l2.Size = UDim2.new(1, -24, 0, 26)
l2.Font = FONT; l2.TextScaled = true; l2.TextColor3 = CREAM; l2.Text = ""; l2.Parent = card
local l2c = Instance.new("UITextSizeConstraint"); l2c.MaxTextSize = 17; l2c.Parent = l2
local shownAt = 0
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
local function announce(a, b, secs)
	task.spawn(function()
		local t1 = os.clock()
		task.wait(0.3)                                    -- (the honours banner, fired in the same moment, shows first)
		while (dailyCardUp() or titleBannerUp()) and os.clock() - t1 < 90 do task.wait(0.3) end
		l1.Text = a; l2.Text = b
		card.Visible = true
		local mine = os.clock(); shownAt = mine
		TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 128)}):Play()
		task.delay(secs or 10, function()
			if shownAt ~= mine then return end
			local t = TweenService:Create(card, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, -120)}); t:Play()
			t.Completed:Connect(function() if shownAt == mine then card.Visible = false end end)
		end)
	end)
end
local function chat(text)
	pcall(function()
		local ch = game:GetService("TextChatService"):WaitForChild("TextChannels", 3):WaitForChild("RBXGeneral", 3)
		ch:DisplaySystemMessage(text)
	end)
end

-- ---- fireworks over all three maps (each screen fires its own; nothing is sent over the network) ----
local SITES = {{0, -60}, {-70, -140}, {70, -170}, {205, -50}, {315, -60}, {260, -170}, {430, -40}, {540, -140}, {650, -60}}
local COLOURS = {C(255, 60, 60), C(255, 150, 40), C(255, 230, 60), C(80, 230, 90), C(60, 220, 255), C(80, 120, 255), C(180, 90, 255), C(255, 90, 200)}
local function sound(id, parent, vol)
	if not id or id == "" then return end
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = 700; s.RollOffMinDistance = 40; s.Parent = parent; s:Play()
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
local function rocket(x, z)
	local colour = COLOURS[math.random(1, #COLOURS)]
	local topY = math.random(80, 120)
	-- a bright spark going up with only a short, faint wisp behind it (Shannon: "less of a tail traveling up")
	local r = Instance.new("Part"); r.Name = "Rocket"; r.Shape = Enum.PartType.Ball; r.Size = Vector3.new(0.45, 0.45, 0.45); r.Anchored = true; r.CanCollide = false; r.CanQuery = false
	r.CastShadow = false; r.Material = Enum.Material.Neon; r.Color = colour; r.CFrame = CFrame.new(x, 4, z); r.Parent = workspace
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
		local b = Instance.new("Part"); b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.Transparency = 1; b.Size = Vector3.new(1, 1, 1); b.CFrame = at; b.Parent = workspace
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
	local id = F:GetAttribute("FireworkShow")
	if id and id ~= "" then
		local s = Instance.new("Sound"); s.Name = "FireworkShow"; s.SoundId = id; s.Looped = true; s.Volume = F:GetAttribute("FireworkVolume") or 0.6
		s.Parent = game:GetService("SoundService"); s:Play()
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
				if math.random() < chance then local st = order[k].s; rocket(st[1] + math.random(-18, 18), st[2] + math.random(-18, 18)) end
			end
			if math.random() < 0.25 then local st = order[math.random(4, #order)].s; rocket(st[1] + math.random(-15, 15), st[2] + math.random(-15, 15)) end
			task.wait(0.35 + math.random() * 0.2)
		end
		showing = false
	end)
end

-- the Keepers are numbered in the order they won (Shannon, Sep 26): "the 3rd Grand Keeper", not "Day 3"
ev.OnClientEvent:Connect(function(what, a, b, c)
	if what == "crowned" and type(a) == "table" then
		local all = tonumber(a.total) or 44
		local who = a.no and ("the " .. ordinal(a.no) .. " Grand Keeper") or "today's Grand Keeper"
		if a.uid == player.UserId then
			announce("You are " .. who .. "!", "Of the Great Acorn - your statue stands by the fountain")
		else
			announce(tostring(a.name) .. " is " .. who .. "!", "First to find all " .. all .. " squirrels today")
		end
		chat(string.format("%s found all %d squirrels first today and is %s of the Great Acorn! Their statue now stands by the fountain.", tostring(a.name), all, who))
		fireworks(F:GetAttribute("FireworkSeconds") or 25)
	elseif what == "late" then
		-- SAY IT PLAINLY (Shannon, Sep 26, finishing second: "it said I got all 44 and I am the grand keeper, but no fireworks"):
		-- today's statue is someone else's, and when the next chance comes (the day turns at the daily gift's DayOffsetHours UTC)
		local daily = workspace:FindFirstChild("Daily")
		local off = (daily and daily:GetAttribute("DayOffsetHours")) or 9
		local now = workspace:GetServerTimeNow()
		local nextAt = (math.floor((now - off * 3600) / 86400) + 1) * 86400 + off * 3600
		local left = math.max(0, nextAt - now)
		local h, m = math.floor(left / 3600), math.floor(left % 3600 / 60)
		local untilNext = (h > 0) and string.format("%dh %dm", h, m) or string.format("%d minutes", math.max(1, m))
		announce("Today's statue is already " .. tostring(a) .. "'s", "Next chance in " .. untilNext .. " - be the first to find all " .. (tonumber(c) or 44) .. " after the daily reset!", 14)
		chat(string.format("Today's Grand Keeper statue went to %s. The next one goes to whoever finds all %d squirrels first after the daily reset - in %s.", tostring(a), tonumber(c) or 44, untilNext))
	elseif what == "already" then
		announce("All " .. (tonumber(b) or 44) .. " found again!", "You're already the " .. ordinal(a) .. " Grand Keeper. New squirrels mean a new race!")
	end
end)

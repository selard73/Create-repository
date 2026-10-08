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
ance.new("TextLabel"); l1.BackgroundTransparency = 1; l1.Position = UDim2.fromOffset(12, 8); l1.Size = UDim2.new(1, -24, 0, 32)
l1.Font = FONT; l1.TextScaled = true; l1.TextColor3 = GOLD; l1.Text = ""; l1.Parent = card
local l1c = Instance.new("UITextSizeConstraint"); l1c.MaxTextSize = 26; l1c.Parent = l1
local l2 = Instance.new("TextLabel"); l2.BackgroundTransparency = 1; l2.Position = UDim2.fromOffset(12, 42); l2.Size = UDim2.new(1, -24, 0, 26)
l2.Font = FONT; l2.TextScaled = true; l2.TextColor3 = CREAM; l2.Text = ""; l2.Parent = card
local l2c = Instance.new("UITextSizeConstraint"); l2c.MaxTextSize = 17; l2c.Parent = l2
local shownAt = 0
local function dailyCardUp()                          -- the daily acorns card is showing (nothing goes on top of it: Shannon)
	local dg = pg:FindFirstChild("DailyGui")
	local dc = dg and dg:FindFirstChild("DailyCard")
	return dc ~= nil and dc:IsA("GuiObject") and dcait(0.3) end
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
local SITES = {{0, -60}, {-70, -140}, {70, -170}, {205, -50}, {315, -60}, {26local c = COLOURS[math.random(1, #COLOURS)]
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
	local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachme b.CanCollide = false; b.CanQuery = false; b.Transparency = 1; b.Size = Vector3.new(1, 1, 1); b.CFrame = at; b.Parent = workspace
		local att = Instance.new("Attachment"); att.Parent = b
		-- three colours in every burst, big bright stars that read against a daytime sky, and a glitter of white
		local picks = threeColours(colour)
		picks[#picks + 1] = C(255, 250, 225)
		for k, col in ipairs(picks) do
			local white = k == #picks
			local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.LightEmission = 1; pe.LightInfluence = 0
			pe.Brightness = 2; pe.Color = ColorSequence.new(col); pe.Speed = NumberRange.new(white and 20 or 34, white and 30 or 52)
			pe.SpreadAngle = Vector2.new(180, 180); pe.Drag = 2.2; pe.Acceleration = Vector3.new(0, -9, 0); pe.Lifetime = NumberRange.new(1.6, 2.6)
			pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, whry = false; ball.CanTouch = false; ball.Size = Vector3.new(2, 2, 2); ball.Transparency = 0.2; ball.CFrame = at; ball.Parent = workspace
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
		local s = Instance.new("Sound"); s.Name = "FireworkShow"; s.SoundId = id; s.Looped = true; s.Volume = F:GetAttribute("FireworkVdo order[k] = {s = st, d = (Vector2.new(st[1], st[2]) - Vector2.new(here.X, here.Z)).Magnitude} end
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
		if a.uid == plao fireworks"):
		-- today's statue is someone else's, and when the next chance comes (the day turns at the daily gift's DayOffsetHours UTC)
		local daily = workspace:FindFirstChild("Daily")
		local off = (daily and daily:GetAttribute("DayOffsetHours")) or 9
		local now = workspace:GetServerTimeNow()
		local nextAt = (math.floor((now - off * 3600) / 86400) + 1) * 86400 + off * 3600
		local left = math.max(0, nextAt - now)
		local h, m = math.floor(left / 3600), math.floor(left % 3600 / 60)
		local untilNext = (h > 0) and string.format("%dh %dm", h, m) or string.format("%d minutes", math.max(1, m))
		announce("Today's statue is already " .. tostring(a) .. "'s", "Next chance in " .. untilNext .. " - be the first to find all " .. (tonumber(c) or 44) .. " after the daily reset!", 14)
		chat(string.format("Today's Grand Keeper statue went to %s. The next one goes to whoever finds all %d squirrels first after 
-- Daily loop: a reason to come back tomorrow. Shannon (Sep 24): "please build the first loop".
--   1. DAILY ACORNS - on your first visit each day a card drops in: "Daily Acorns, Day N in a row, +R acorns, Collect".
--      The reward climbs with the streak (Base + Step per day, capped at Max) and the streak resets if you skip a day.
--   2. THE GOLDEN SQUIRREL - each day one of the 44 takes a golden turn: a gold clone of that squirrel hides at one of
--      the acorn hiding places on its own map (a new spot every day, the same for everyone). Click it for GoldReward
--      acorns, once per day per player. A small pill under the purse says who it is and which area to search.
-- Nothing here touches the DataStore: the day counters ride on the ledger as items (Item_daily_day = the day index,
-- Item_daily_streak, Item_daily_gold = the day it was found), written as deltas through AwardItems so they merge
-- like every other item, and acorns go through AwardAcorns like every other spend and earn.
-- The day rolls over at DayOffsetHours UTC (9 = 5 am Eastern in summer).
-- Attributes on workspace.Daily: BaseReward, StepReward, MaxReward, GoldReward, DayOffsetHours; GoldName/GoldArea/GoldDay
-- are written at run time. Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local old = workspace:FindFirstChild("Daily"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "Daily"
	F:SetAttribute("BaseReward", opts.base or 10); F:SetAttribute("StepReward", opts.step or 5); F:SetAttribute("MaxReward", opts.max or 40)
	F:SetAttribute("GoldReward", opts.gold or 30); F:SetAttribute("DayOffsetHours", opts.offsetHours or 9)
	local action = RS:FindFirstChild("DailyAction")
	if not action then action = Instance.new("RemoteFunction"); action.Name = "DailyAction"; action.Parent = RS end
	local ev = RS:FindFirstChild("DailyEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "DailyEvent"; ev.Parent = RS end

	local SERVER = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local action = RS:WaitForChild("DailyAction")
local ev = RS:WaitForChild("DailyEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local AREA = {forest = "The Great Acorn Forest", village = "Rue de Noisette", domaine = "Ch" .. utf8.char(226) .. "teau de l'Acorn"}
local GOLD = Color3.fromRGB(255, 200, 60)

local function today() return math.floor((os.time() - (F:GetAttribute("DayOffsetHours") or 9) * 3600) / 86400) end
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function rewardFor(streak)
	return math.min((F:GetAttribute("BaseReward") or 10) + (F:GetAttribute("StepReward") or 5) * (streak - 1), F:GetAttribute("MaxReward") or 40)
end
local function nextStreak(player, day)
	local last, streak = item(player, "daily_day"), item(player, "daily_streak")
	if last == day - 1 then return math.max(1, streak + 1) end
	return 1
end
local function giveAcorns(player, n)
	awardAcorns:Fire(player, n)
	player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + n)
end

-- ---------------------------------------------------------------- the golden squirrel ----
local gold = {day = nil, model = nil, entry = nil, area = nil}
local function stateOf(player)
	local day = today()
	local streak = nextStreak(player, day)
	return {
		day = day, claimable = item(player, "daily_day") ~= day, streak = streak, reward = rewardFor(streak),
		goldName = F:GetAttribute("GoldName") or "", goldArea = F:GetAttribute("GoldArea") or "", goldFound = item(player, "daily_gold") == day,
	}
end
local goldClaimed={}
local function goldFound(player)
 local char=player.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart")
 if not hrp or not player:GetAttribute("SaveLoaded") or not gold.model or (hrp.Position-gold.model:GetPivot().Position).Magnitude>34 then return end
	local day = today()
	if item(player, "daily_gold") == day or goldClaimed[player]==day then return end
	goldClaimed[player]=day
	setItem(player, "daily_gold", day)
	local r = F:GetAttribute("GoldReward") or 30
	giveAcorns(player, r)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"gold",{name=gold.entry and gold.entry.name or "the Golden Squirrel",area=gold.area,prize=r}) end
	ev:FireClient(player, "gold", r, gold.entry and gold.entry.name or "the Golden Squirrel")
	print(string.format("Daily: %s found the golden %s (+%d)", player.Name, gold.entry and gold.entry.name or "?", r))
end
local function pickGold(day)
	local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
	local list = Registry.squirrels
	local n = #list
	for k = 0, n - 1 do
		local e = list[(day + k) % n + 1]
		local model
		for _, m in ipairs(workspace:GetDescendants()) do
			if m:IsA("Model") and m.Name:lower() == e.id .. "_color" and m:FindFirstChildWhichIsA("MeshPart", true) then model = m break end
		end
		if model and model:GetAttribute("SquirrelId") then return e, model end
	end
end
local function spotFor(day, map)
	local spots = workspace:FindFirstChild("AcornSpots")
	if not spots then return nil end
	local list = {}
	for _, a in ipairs(spots:GetChildren()) do if a:IsA("Attachment") and (a:GetAttribute("Section") or "forest") == map then list[#list + 1] = a end end
	if #list == 0 then for _, a in ipairs(spots:GetChildren()) do if a:IsA("Attachment") then list[#list + 1] = a end end end
	if #list == 0 then return nil end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list[Random.new(day * 7919 + 13):NextInteger(1, #list)]
end
local function makeGold(day)
	if gold.model then gold.model:Destroy(); gold.model = nil end
	local entry, source = pickGold(day)
	if not entry then warn("Daily: no squirrel model to make golden") return end
	local spot = spotFor(day, entry.map)
	if not spot then warn("Daily: no AcornSpots to hide in") return end
	local clone = source:Clone()
	clone.Name = "GoldenSquirrel"
	-- strip every attribute (the squirrel scripts paint any mesh that carries GrayTexture/ColorTexture) and the
	-- bones (that is how they recognise a squirrel mesh); RBX_ attributes belong to Roblox and cannot be touched
	local function stripAttributes(inst)
		for k in pairs(inst:GetAttributes()) do
			if not k:match("^RBX_") then pcall(function() inst:SetAttribute(k, nil) end) end
		end
	end
	local CS = game:GetService("CollectionService")
	for _, t in ipairs(CS:GetTags(clone)) do CS:RemoveTag(clone, t) end      -- not a collectible: no "Squirrel" tag
	stripAttributes(clone)
	for _, d in ipairs(clone:GetDescendants()) do
		for _, t in ipairs(CS:GetTags(d)) do CS:RemoveTag(d, t) end
		stripAttributes(d)
		if d:IsA("Bone") then d:Destroy() end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("Highlight") or d:IsA("BillboardGui") or d:IsA("BaseScript")
			or d:IsA("SurfaceAppearance") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Decal") then d:Destroy() end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.Transparency = 0
			if d:IsA("MeshPart") then d.TextureID = "" end
			d.Color = GOLD; d.Material = Enum.Material.SmoothPlastic; d.Reflectance = 0.25   -- Metal went dark in the shade
		end
	end
	-- before he is found he is a pale cream-gold with a glow outline (only where you can see him: no peeking through
	-- walls); the click turns him bright shiny yellow on the finder's screen
	local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(255, 244, 205); hl.FillTransparency = 0.35; hl.OutlineColor = Color3.fromRGB(255, 240, 150)
	hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Parent = clone
	clone.Parent = F
	local pos = spot.WorldPosition
	-- keep the original's own rotation (Meshy meshes stand up through their pivot) and only turn it about the vertical
	local srcRot = source:GetPivot().Rotation
	clone:PivotTo(CFrame.new(pos) * CFrame.Angles(0, Random.new(day):NextNumber(0, math.pi * 2), 0) * srcRot)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {clone, workspace:FindFirstChild("Acorns") or clone, workspace:FindFirstChild("AcornSpots") or clone}
	local hit = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -12, 0), rp)
	local groundY = hit and hit.Position.Y or pos.Y
	local cf, size = clone:GetBoundingBox()
	clone:PivotTo(clone:GetPivot() + Vector3.new(0, groundY + 0.05 - (cf.Position.Y - size.Y / 2), 0))
	-- one invisible box round the whole squirrel takes the click (its meshes are several parts, and a click on a
	-- lamb or a staff must count too); the sparkles and the glow ride on it
	local bcf, bsize = clone:GetBoundingBox()
	local box = Instance.new("Part"); box.Name = "Hitbox"; box.Size = bsize + Vector3.new(0.4, 0.4, 0.4); box.CFrame = bcf; box.Transparency = 1
	box.Anchored = true; box.CanCollide = false; box.CanQuery = true; box.CastShadow = false; box.Parent = clone
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Color = ColorSequence.new(GOLD); pe.LightEmission = 1
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0)}); pe.Lifetime = NumberRange.new(0.8, 1.4); pe.Rate = 12
	pe.Speed = NumberRange.new(0.5, 1.5); pe.SpreadAngle = Vector2.new(180, 180); pe.Transparency = NumberSequence.new(0.2); pe.Parent = box
	local l = Instance.new("PointLight"); l.Color = GOLD; l.Brightness = 0.8; l.Range = 8; l.Parent = box
	local cd = Instance.new("ClickDetector"); cd.MaxActivationDistance = 28; cd.Parent = box
	cd.MouseClick:Connect(goldFound)
 box.CanTouch=true
 box.Touched:Connect(function(hit)
  local char=hit:FindFirstAncestorOfClass("Model");local player=char and Players:GetPlayerFromCharacter(char)
  if player then goldFound(player) end
 end)
	gold.day, gold.model, gold.entry, gold.area = day, clone, entry, AREA[entry.map] or entry.map
	F:SetAttribute("GoldName", entry.name); F:SetAttribute("GoldArea", gold.area); F:SetAttribute("GoldDay", day)
	print(string.format("Daily: the golden %s is hiding in %s at (%.0f,%.0f,%.0f)", entry.name, gold.area, pos.X, groundY, pos.Z))
end

-- ---------------------------------------------------------------- players ----
local function offer(player) ev:FireClient(player, "state", stateOf(player)) end
local function watch(player)
	task.spawn(function()
		local t0 = os.clock()
		while player.Parent and not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 15 do task.wait(0.25) end
		if not player.Parent then return end
		task.wait(2)
		while not gold.model and os.clock() - t0 < 30 do task.wait(0.5) end
		offer(player)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
action.OnServerInvoke = function(player, what)
	if what == "claim" then
		local day = today()
		if item(player, "daily_day") == day then return false, "already collected today" end
		local streak = nextStreak(player, day)
		local r = rewardFor(streak)
		setItem(player, "daily_day", day); setItem(player, "daily_streak", streak)
		giveAcorns(player, r)
		print(string.format("Daily: %s collected day %d of a %d-day streak (+%d)", player.Name, day, streak, r))
		return true, {streak = streak, reward = r}
	elseif what == "state" then
		return true, stateOf(player)
	end
	return false, "no such thing"
end
-- the day rolls over while people are playing, too
task.spawn(function()
	-- the squirrels are scaled and tagged by SquirrelSetup first; wait for one to carry its id
	local t0 = os.clock()
	while os.clock() - t0 < 30 do
		local any = false
		for _, m in ipairs(workspace:GetDescendants()) do if m:IsA("Model") and m:GetAttribute("SquirrelId") then any = true break end end
		if any then break end
		task.wait(0.5)
	end
	makeGold(today())
	while true do
		task.wait(60)
		if today() ~= gold.day then
			makeGold(today())
			for _, p in ipairs(Players:GetPlayers()) do offer(p) end
		end
	end
end)
print("Daily: ready")

Players.PlayerRemoving:Connect(function(p) goldClaimed[p]=nil end)
]==]

	local CLIENT = [==[
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
local btn = Instance.new("TextButton"); btn.AnchorPoint = Vector2.new(0.5, 0); btn.Position = UDim2.new(0.5, 0, 0, 148); btn.Size = UDim2.fromOffset(150, 38)
btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0; btn.Font = FONT; btn.TextSize = 19; btn.TextColor3 = DEEP; btn.Text = "Collect"; btn.AutoButtonColor = false; btn.Parent = card
corner(btn, 12)
local shown, busy = false, false
local function slide(y, secs) return TweenService:Create(card, TweenInfo.new(secs, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, y)}) end
local function showCard(state)
	sub.Text = state.streak > 1 and string.format("Day %d in a row", state.streak) or "Welcome back"
	big.Text = string.format("+%d acorns", state.reward)
	goldLine.Text = (state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""
	btn.Text = "Collect"; btn.BackgroundColor3 = GOLD
	card.Visible = true; shown = true
	local openY = phone and 66 or 62
	slide(openY, 0.6):Play()                           -- phones sit four pixels lower; desktop spacing stays unchanged
end
local function hideCard()
	local t = slide(-260, 0.45); t:Play()
	t.Completed:Connect(function() card.Visible = false; shown = false end)
end
btn.Activated:Connect(function()
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
end)

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
	if not state.goldName or state.goldName == "" then pill.Visible = false return end
	pill.Text = state.goldFound and ("Golden Squirrel: found today!") or string.format("Golden Squirrel: %s is hiding in %s", state.goldName, state.goldArea)
	pill.Visible = pillPhase == "on"
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
]==]
	local s = Instance.new("Script"); s.Name = "DailyServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "DailyClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print(string.format("Daily: installed - gift %d + %d per streak day (max %d), golden squirrel worth %d, day rolls at %d:00 UTC", F:GetAttribute("BaseReward"), F:GetAttribute("StepReward"), F:GetAttribute("MaxReward"), F:GetAttribute("GoldReward"), F:GetAttribute("DayOffsetHours")))
	return F
end

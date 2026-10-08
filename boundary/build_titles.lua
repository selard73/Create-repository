-- Honours: a player's title grows as they complete sections 100%: The Great Acorn Forest -> "Squirrel Friend",
-- Rue de Noisette -> "Squirrel Whisperer", Château de l'Acorn -> "Squirrel Sage" (each needs the
-- earlier sections complete too). The title shows under the player's name over their head and in a pill on screen; the
-- moment a title is earned there is a banner, sparkles, a fanfare and a chat announcement, and a Roblox badge is
-- awarded when its id is set in the Badge_<map> attributes (create the three badges on the Creator Dashboard).
-- Run in edit mode: require(workspace.Titles.PatchModule)()  (packed by village/make_patch.py)
return function()
	local old = workspace:FindFirstChild("Honours")
	local keep = {}                                                -- badge ids already entered survive a reinstall
	if old then for _, k in ipairs({"Badge_forest", "Badge_village", "Badge_domaine"}) do keep[k] = old:GetAttribute(k) end; old:Destroy() end
	local H = Instance.new("Folder"); H.Name = "Honours"
	local DEFAULT = {Badge_forest = 2980609362202333, Badge_village = 3066275971523339, Badge_domaine = 1304762848867330}   -- Shannon's Roblox badges (0 = not created yet)
	for _, k in ipairs({"Badge_forest", "Badge_village", "Badge_domaine"}) do
		local kept = tonumber(keep[k]) or 0
		H:SetAttribute(k, (kept > 0) and kept or DEFAULT[k])
	end
	H.Parent = workspace
	local ev = Instance.new("RemoteEvent"); ev.Name = "HonourEarned"; ev.Parent = H
	local dbg = Instance.new("RemoteEvent"); dbg.Name = "HonourDebug"; dbg.Parent = H

	local SERVER = [==[
-- TitleServer: works out each player's honour from their per-map finds, keeps the name tag over their head, announces
-- newly earned titles and awards the matching Roblox badge when one is configured.
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local RunService = game:GetService("RunService")
local H = script.Parent
local ev = H:WaitForChild("HonourEarned")
local dbg = H:WaitForChild("HonourDebug")
local C = Color3.fromRGB
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local TOTAL = {}
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1 end
local TIERS = {
	{map = "forest",  title = "Squirrel Friend",                 badge = "Badge_forest",  colour = C(205, 127, 50)},
	{map = "village", title = "Squirrel Whisperer",             badge = "Badge_village", colour = C(200, 204, 212)},
	{map = "domaine", title = "Squirrel Sage", badge = "Badge_domaine", colour = C(240, 196, 60)},   -- (was "Grand Keeper of the Great Acorn": too like the statue - Shannon, Sep 26)
}
local tierOf = {}          -- player -> current tier (0..3)
local forced = {}          -- Studio-only test override
local function computeTier(player)
	if forced[player] then return forced[player] end
	local tier = 0
	for i, t in ipairs(TIERS) do
		local n = player:GetAttribute("Found_" .. t.map)
		if n == nil or n < (TOTAL[t.map] or 1) then break end
		tier = i
	end
	return tier
end
local function award(player, tier)
	local t = TIERS[tier]
	local id = t and H:GetAttribute(t.badge)
	if not id or id <= 0 then return end
	task.spawn(function()
		local ok, err = pcall(function() BadgeService:AwardBadgeAsync(player.UserId, id) end)
		if not ok then ok, err = pcall(function() BadgeService:AwardBadge(player.UserId, id) end) end
		if not ok then warn("TitleServer: badge award failed: " .. tostring(err)) end
	end)
end
-- the name tag: name on top, the title underneath with a medallion
local function tag(player, char)
	local head = char:WaitForChild("Head", 10)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not head then return end
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	local old = head:FindFirstChild("HonourTag"); if old then old:Destroy() end
	local gui = Instance.new("BillboardGui"); gui.Name = "HonourTag"; gui.Size = UDim2.new(0, 260, 0, 64); gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.MaxDistance = 70; gui.LightInfluence = 0; gui.Parent = head
	local name = Instance.new("TextLabel"); name.Name = "Name"; name.Size = UDim2.new(1, 0, 0, 30); name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne; name.TextSize = 24; name.TextColor3 = C(255, 255, 255); name.TextStrokeTransparency = 0.4; name.Text = player.DisplayName; name.Parent = gui
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Size = UDim2.new(1, 0, 0, 24); title.Position = UDim2.new(0, 0, 0, 30); title.BackgroundTransparency = 1
	title.Font = Enum.Font.Antique; title.TextSize = 21; title.TextColor3 = C(255, 222, 110); title.TextStrokeTransparency = 0.3; title.Text = ""; title.Parent = gui
	return gui
end
local function refreshTag(player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local gui = head and head:FindFirstChild("HonourTag")
	if not gui then return end
	local tier = tierOf[player] or 0
	local champ = player:GetAttribute("ChampionTitle"); if champ == "" then champ = nil end; gui.Size = UDim2.new(0, champ and 380 or 260, 0, 64); gui.Title.Text = champ or (tier > 0 and TIERS[tier].title or "")
	gui.Title.TextColor3 = champ and C(255, 214, 60) or (tier > 0 and TIERS[tier].colour or C(255, 222, 110))
end
local function update(player, announce)
	local tier = computeTier(player)
	local was = tierOf[player] or 0
	tierOf[player] = tier
	player:SetAttribute("HonourTier", tier)
	local champT = player:GetAttribute("ChampionTitle"); player:SetAttribute("HonourTitle", (champT and champT ~= "") and champT or (tier > 0 and TIERS[tier].title or ""))
	refreshTag(player)
	if tier > was then
		for i = was + 1, tier do award(player, i) end            -- every badge earned, not only the top one
		if announce then ev:FireAllClients(player, tier, TIERS[tier].title) end
	end
end
local function watch(player)
	tierOf[player] = 0
	player.CharacterAdded:Connect(function(char) task.defer(function() tag(player, char); refreshTag(player) end) end)
	if player.Character then task.defer(function() tag(player, player.Character); refreshTag(player) end) end
	for _, t in ipairs(TIERS) do
		player:GetAttributeChangedSignal("Found_" .. t.map):Connect(function() update(player, true) end)
	end
	player:GetAttributeChangedSignal("ChampionTitle"):Connect(function() update(player, false) end); task.delay(1, function() if player.Parent then update(player, false) end end)   -- the saved finds arrive a moment after joining
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) tierOf[p] = nil; forced[p] = nil end)
if RunService:IsStudio() then                                        -- Studio-only: pretend a tier, to see the honours without 35 finds
	dbg.OnServerEvent:Connect(function(player, tier)
		forced[player] = (tier and tier > 0) and math.clamp(tier, 1, 3) or nil
		update(player, true)
	end)
end
]==]
	local CLIENT = [==[
-- TitleClient: the honour pill on screen, and the celebration when a title is earned (banner, sparkles, fanfare, chat).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local H = script.Parent
local ev = H:WaitForChild("HonourEarned")
local C = Color3.fromRGB
local COLOURS = {C(205, 127, 50), C(200, 204, 212), C(240, 196, 60)}
local function medallion(parent, size, colour)                        -- a round medal with a little acorn drawn from frames
	local m = Instance.new("Frame"); m.Name = "Medal"; m.Size = UDim2.new(0, size, 0, size); m.BackgroundColor3 = colour; m.BorderSizePixel = 0; m.Parent = parent
	local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0.5, 0); mc.Parent = m
	local ring = Instance.new("UIStroke"); ring.Color = C(80, 52, 30); ring.Thickness = 2; ring.Parent = m
	local nut = Instance.new("Frame"); nut.Size = UDim2.new(0.42, 0, 0.44, 0); nut.Position = UDim2.new(0.29, 0, 0.36, 0); nut.BackgroundColor3 = C(196, 138, 78); nut.BorderSizePixel = 0; nut.Parent = m
	local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0.5, 0); nc.Parent = nut
	local cap = Instance.new("Frame"); cap.Size = UDim2.new(0.52, 0, 0.26, 0); cap.Position = UDim2.new(0.24, 0, 0.2, 0); cap.BackgroundColor3 = C(104, 66, 38); cap.BorderSizePixel = 0; cap.Parent = m
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0.45, 0); cc.Parent = cap
	local stem = Instance.new("Frame"); stem.Size = UDim2.new(0.08, 0, 0.14, 0); stem.Position = UDim2.new(0.46, 0, 0.1, 0); stem.BackgroundColor3 = C(80, 52, 30); stem.BorderSizePixel = 0; stem.Parent = m
	return m
end
local gui = Instance.new("ScreenGui"); gui.Name = "HonourBar"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = player:WaitForChild("PlayerGui")
local pill = Instance.new("Frame"); pill.Name = "Pill"; pill.Size = UDim2.new(0, 400, 0, 44); pill.Position = UDim2.new(0.5, -200, 0, 10); pill.BackgroundColor3 = C(38, 30, 52)
pill.BackgroundTransparency = 0.15; pill.BorderSizePixel = 0; pill.Visible = false; pill.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 22); pc.Parent = pill
local ps = Instance.new("UIStroke"); ps.Color = C(240, 200, 90); ps.Thickness = 2; ps.Parent = pill
local pm = medallion(pill, 34, COLOURS[1]); pm.Position = UDim2.new(0, 6, 0, 5)
local pt = Instance.new("TextLabel"); pt.Size = UDim2.new(1, -52, 1, 0); pt.Position = UDim2.new(0, 46, 0, 0); pt.BackgroundTransparency = 1
pt.Font = Enum.Font.Antique; pt.TextSize = 24; pt.TextColor3 = C(255, 214, 90); pt.TextScaled = false; pt.TextWrapped = false; pt.Text = ""; pt.Parent = pill
-- ONE LINE, ALWAYS. TextScaled quietly turns wrapping on, and in a phone-width pill it broke the long title over
-- two lines (Shannon: "that looks bad"). The size is measured instead: the largest, up to 24, at which the whole
-- title fits the label on a single line.
local TextService = game:GetService("TextService")
local pillW = 400
local function fitTitle()
	local avail = pillW - 52 - 10
	local size = 24
	while size > 10 do
		local b = TextService:GetTextSize(pt.Text, size, pt.Font, Vector2.new(4000, 100))
		if b.X <= avail then break end
		size -= 1
	end
	pt.TextSize = size
end
-- THE WIDTH COMES FROM THE SCREEN. A fixed 400 ran into the buttons top-left (menu, chat, mic, Hint: about 330 px)
-- and the counters top-right (about 220 px) on a phone (Shannon). The pill takes what is left between them, at
-- most 400, at least 230, and TextScaled shrinks the longest title to fit.
local function fitPill()
	local cam = workspace.CurrentCamera
	local vw = cam and cam.ViewportSize.X or 1280
	local w = math.clamp(vw - 2 * 345, 230, 400)
	pillW = w
	pill.Size = UDim2.new(0, w, 0, 44); pill.Position = UDim2.new(0.5, -w / 2, 0, 10)
	fitTitle()
end
fitPill()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPill) end
local function refreshPill()
	local tier = player:GetAttribute("HonourTier") or 0
	pill.Visible = tier > 0
	if tier > 0 then pt.Text = player:GetAttribute("HonourTitle") or ""; pm.BackgroundColor3 = COLOURS[tier]; fitTitle() end
end
player:GetAttributeChangedSignal("HonourTier"):Connect(refreshPill)
player:GetAttributeChangedSignal("HonourTitle"):Connect(refreshPill)
refreshPill()
-- the celebration
local banner = Instance.new("Frame"); banner.Name = "Banner"; banner.Size = UDim2.new(0, 640, 0, 120); banner.Position = UDim2.new(0.5, -320, 0.3, 0); banner.BackgroundColor3 = C(38, 30, 52)
banner.BackgroundTransparency = 0.1; banner.BorderSizePixel = 0; banner.Visible = false; banner.Parent = gui
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = banner
local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 3; bs.Parent = banner
local bm = medallion(banner, 72, COLOURS[1]); bm.Position = UDim2.new(0, 22, 0.5, -36)
local b1 = Instance.new("TextLabel"); b1.Size = UDim2.new(1, -120, 0, 40); b1.Position = UDim2.new(0, 108, 0, 18); b1.BackgroundTransparency = 1
b1.Font = Enum.Font.FredokaOne; b1.TextSize = 26; b1.TextColor3 = C(255, 246, 220); b1.TextXAlignment = Enum.TextXAlignment.Left; b1.Text = ""; b1.Parent = banner
local b2 = Instance.new("TextLabel"); b2.Size = UDim2.new(1, -120, 0, 44); b2.Position = UDim2.new(0, 108, 0, 58); b2.BackgroundTransparency = 1
b2.Font = Enum.Font.Antique; b2.TextSize = 40; b2.TextColor3 = C(255, 214, 90); b2.TextXAlignment = Enum.TextXAlignment.Left; b2.TextScaled = true; b2.Text = ""; b2.Parent = banner
local b2c = Instance.new("UITextSizeConstraint"); b2c.MaxTextSize = 40; b2c.Parent = b2
local shownAt = 0
local function celebrate(tier, title)
	bm.BackgroundColor3 = COLOURS[tier] or COLOURS[1]
	b1.Text = tier == 3 and "All 44 squirrels found! You are now a" or "A section complete! You are now a"
	b2.Text = title
	banner.Visible = true; banner.Position = UDim2.new(0.5, -320, 0.24, 0)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -320, 0.3, 0)}):Play()
	local t = os.clock(); shownAt = t
	task.delay(6, function() if shownAt == t then banner.Visible = false end end)
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://1845415163"; s.Volume = 0.6; s.Parent = gui; s:Play(); Debris:AddItem(s, 6)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if head then
		local a = Instance.new("Attachment"); a.Position = Vector3.new(0, 1, 0); a.Parent = head
		local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(COLOURS[tier] or COLOURS[1], C(255, 250, 220)); pe.Size = NumberSequence.new(0.6, 0); pe.Lifetime = NumberRange.new(1, 1.6)
		pe.Speed = NumberRange.new(4, 7); pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, -6, 0); pe.LightEmission = 0.8; pe.Rate = 0; pe.Parent = a
		pe:Emit(60); task.delay(0.8, function() pe:Emit(40) end)
		Debris:AddItem(a, 5)
	end
end
ev.OnClientEvent:Connect(function(who, tier, title)
	if who == player then celebrate(tier, title) end
	pcall(function()
		local tcs = game:GetService("TextChatService")
		local ch = tcs:FindFirstChild("TextChannels") and tcs.TextChannels:FindFirstChild("RBXGeneral")
		if ch then ch:DisplaySystemMessage(string.format("%s is now a %s!", who.DisplayName, title)) end   -- ("a": everyone who finds all 44 is a Squirrel Sage)
	end)
end)
]==]
	local function install(name, ctx, src)
		local s = Instance.new("Script"); s.Name = name; s.RunContext = ctx; s.Source = src; s.Parent = H
	end
	install("TitleServer", Enum.RunContext.Server, SERVER)
	install("TitleClient", Enum.RunContext.Client, CLIENT)
	print("Honours installed: titles Squirrel Friend / Squirrel Whisperer / Squirrel Sage; badge ids in workspace.Honours attributes")
end

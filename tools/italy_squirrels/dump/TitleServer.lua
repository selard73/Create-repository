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
	{map = "village", title = "Squirrel Whisperer",             badge = "Badge_village", colour = C(200, 204urn forced[player] end
	local tier = 0
	for i, t in ipairs(TIERS) do
		local n = player:GetAttribute("Found_" .. t.map)
		if n == nil or n < (t.need or TOTAL[t.map] or 1) then break end
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
	if hum then hum.DisplayDistanceType = 4; name.Text = player.DisplayName; name.Parent = gui
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
	gui.Title.TextColor3 = champ and C(255, 214, 60) or (tier > 0 and TIEtier].title) end
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
if RunService:IsStudio() then                                        -- Studio-only
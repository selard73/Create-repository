local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local MPS = game:GetService("MarketplaceService")
local F = script.Parent
local template = SS:WaitForChild("BinocularsTool")

-- ---- ownership comes from the Game Pass: checked when you arrive, granted the moment a purchase completes
local function passId() return tonumber(F:GetAttribute("BinocularsPassId")) or 0 end
local function grant(player)
	if (player:GetAttribute("Item_binoculars") or 0) > 0 then return end
	player:SetAttribute("Item_binoculars", 1)
end
local function checkPass(player)
	local id = passId()
	if id <= 0 then return end
	local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(player.UserId, id) end)
	if ok and owns then grant(player) end
end
MPS.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	if purchased and id == passId() then grant(player) end
end)

-- ---- the tool follows ownership: whoever has Item_binoculars carries one, on every spawn
local function give(player)
	if (player:GetAttribute("Item_stow_binoculars") or 0) > 0 then return end   -- put away from the Acorn Store (StowServer, Oct 4 2026)
	if (player:GetAttribute("Item_binoculars") or 0) <= 0 then return end
	local char = player.Character
	if not char then return end
	local pack = player:FindFirstChildOfClass("Backpack")
	if (pack and pack:FindFirstChild("Binoculars")) or char:FindFirstChild("Binoculars") then return end
	local t = template:Clone()
	t.Name = "Binoculars"
	t.Parent = pack or player
end
local function watch(player)
	player.CharacterAdded:Connect(function() task.wait(0.6); give(player) end)
	player:GetAttributeChangedSignal("Item_binoculars"):Connect(function() give(player) end)
	player:GetAttributeChangedSignal("Item_stow_binoculars"):Connect(function() give(player) end)
	task.spawn(checkPass, player)
	if player.Character then task.defer(give, player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
print("BinocularsServer: ready" .. (passId() > 0 and (" (game pass " .. passId() .. ")") or " (no game pass id yet - nobody can buy them)"))

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("SpeedEvent")
local function now() return workspace:GetServerTimeNow() end

-- coffee: only for someone sitting at that very table
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "CoffeePrompt" or not prompt:IsDescendantOf(F) then return end
	local cup = prompt:FindFirstAncestorOfClass("Model")
	local link = cup and cup:FindFirstChild("Table")
	local tbl = link and link.Value
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tbl and hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(tbl)) then return end
	local secs = F:GetAttribute("CoffeeSeconds") or 300
	local untilT = tonumber(player:GetAttribute("CoffeeUntil")) or 0
	if untilT - now() > secs - 4 then return end                  -- the last cup is still going down
	player:SetAttribute("CoffeeUntil", now() + secs)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"coffee",{seconds=secs,boost=math.floor(((F:GetAttribute("CoffeeBoost") or 1.35)-1)*100+0.5)}) end
	ev:FireClient(player, "coffee", secs, cup)
	print(string.format("Speed: %s drank a coffee (%ds)", player.Name, secs))
end)

-- zoomies: bought in the Acorn Store, where the ShopServer moves the clock (Item_zoomiesuntil); this only reads it

-- the speed itself, from everything above
local lastSet = setmetatable({}, {__mode = "k"})
while true do
	local t = now()
	local base = F:GetAttribute("BaseSpeed") or 16
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local m = 1
			if (tonumber(player:GetAttribute("CoffeeUntil")) or 0) > t then m *= F:GetAttribute("CoffeeBoost") or 1.35 end
			local racing = player:GetAttribute("Racing") == true
			if (tonumber(player:GetAttribute("Item_zoomiesuntil")) or 0) > t and (not racing or F:GetAttribute("PaidInRace") == true) then
				m *= F:GetAttribute("ZoomiesBoost") or 1.3
			end
			local want = math.floor(base * m * 10 + 0.5) / 10
			-- only while the speed is ours to set: something else (a ride, say) may have its own idea for a moment
			-- (WalkSpeed is stored at lower precision, so 21.6 reads back as 21.600000381: compare with a tolerance)
			local mine = lastSet[hum]
			if mine == nil or math.abs(hum.WalkSpeed - mine) < 0.05 or math.abs(hum.WalkSpeed - base) < 0.05 then
				if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
				lastSet[hum] = want
			end
			if player:GetAttribute("SpeedMult") ~= m then player:SetAttribute("SpeedMult", m) end
		end
	end
	task.wait(0.25)
end

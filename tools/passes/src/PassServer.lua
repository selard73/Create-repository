-- PassServer (workspace.Passes, RunContext Server). Job 109 (Shannon, Oct 15 2026: "give the chance to purchase with a LOT of acorns OR
-- purchase for robux ... the hand glider, and the zip line handle"). Game Passes stand beside the Acorn Store's once-items: the
-- folder's attributes Pass_<itemId> hold the pass ids (Pass_ziphandle = 2036372649, Pass_glider = 2037656625; 0 = not for sale for Robux). Whoever OWNS a pass gets the item on arrival (UserOwnsGamePassAsync, once the save is loaded), and whoever BUYS
-- one gets it the moment Roblox says the purchase went through (PromptGamePassPurchaseFinished) - through the game's AwardItems
-- ledger, so it is kept on the save exactly like an acorn purchase (Item_<id> = 1; the tower and the ramp check that attribute).
-- The Acorn Store's own prompt for the pass lives in ShopClient (its Robux button). Never a DataStore here.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local F = script.Parent
local awardItems = RS:WaitForChild("AwardItems", 60)
if not awardItems then warn("PassServer: no ReplicatedStorage.AwardItems; passes grant nothing") return end
local function passes()
	local t = {}
	for k, v in pairs(F:GetAttributes()) do
		local id = k:match("^Pass_(.+)$")
		if id and tonumber(v) and tonumber(v) > 0 then t[id] = tonumber(v) end
	end
	return t
end
local function grant(p, id, how)
	if (tonumber(p:GetAttribute("Item_" .. id)) or 0) > 0 then return end
	awardItems:Fire(p, id, 1)
	print(string.format("PassServer: %s gets %s (%s)", p.Name, id, how))
end
local function check(p)
	local t0 = os.clock()
	while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
	if not p.Parent then return end
	for id, passId in pairs(passes()) do
		if (tonumber(p:GetAttribute("Item_" .. id)) or 0) <= 0 then
			local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(p.UserId, passId) end)
			if ok and owns then grant(p, id, "owns the pass") end
		end
	end
end
MPS.PromptGamePassPurchaseFinished:Connect(function(p, passId, purchased)
	for id, x in pairs(passes()) do
		if x == passId then
			if purchased then grant(p, id, "bought the pass")
			else   -- (Roblox refuses to sell a pass you already own: a player whose arrival check failed still gets the item here)
				local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(p.UserId, passId) end)
				if ok and owns then grant(p, id, "owns the pass (checked again)") end
			end
		end
	end
end)
Players.PlayerAdded:Connect(function(p) task.spawn(check, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(check, p) end
local n = 0
for _ in pairs(passes()) do n += 1 end
print(string.format("PassServer: %d pass(es) on sale", n))

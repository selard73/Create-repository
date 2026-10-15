-- TreehouseReset (Script, server; in workspace.Treehouse). Job 117: start the Homebase Treehouse over for chosen players (Shannon, Oct 15
-- 2026: "reset selbell's treehouse build so that she can ... experience it from the beginning"). The folder's attributes:
--   ResetUserIds  "9611145467"  user ids, comma-separated
--   ResetRound    1             bump it to reset the same people again
-- When a listed player joins (after their save is in), every Item_tree_* they hold is taken back through the game's own ledger
-- (RS.AwardItems with a negative count - "how something is consumed"; no DataStore here) - the pieces first, Item_tree_done last -
-- and Item_treereset_r<round> = 1 marks the round done on their save, so it happens once per round. The squirrels, acorns and every
-- other item stay. The 100-acorn builder's prize can be won again.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local awardItems = RS:WaitForChild("AwardItems", 60)
if not awardItems then warn("TreehouseReset: no ReplicatedStorage.AwardItems; off") return end
local function listed(p)
	for id in tostring(F:GetAttribute("ResetUserIds") or ""):gmatch("%d+") do if tonumber(id) == p.UserId then return true end end
	return false
end
local function run(p)
	if not listed(p) then return end
	local t0 = os.clock()
	while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
	if not p.Parent or p:GetAttribute("SaveLoaded") ~= true then return end
	task.wait(2)                                                                -- the save's items are on the player by now
	local round = math.max(1, math.floor(tonumber(F:GetAttribute("ResetRound")) or 1))
	local flag = "treereset_r" .. round
	if (tonumber(p:GetAttribute("Item_" .. flag)) or 0) >= 1 then return end
	local pieces, done = {}, 0
	for name, v in pairs(p:GetAttributes()) do
		local id = name:match("^Item_(tree_.+)$")
		local n = tonumber(v) or 0
		if id and n > 0 then if id == "tree_done" then done = n else table.insert(pieces, {id, n}) end end
	end
	for _, e in ipairs(pieces) do awardItems:Fire(p, e[1], -e[2]) end
	task.wait(1)
	if done > 0 then awardItems:Fire(p, "tree_done", -done) end
	awardItems:Fire(p, flag, 1)
	p:SetAttribute("TreePieces", 0)                                           -- (TreehouseServer's count, set at join; its next refresh agrees)
	print(string.format("TreehouseReset: %s - %d pieces taken back%s (round %d); the treehouse starts over", p.Name, #pieces, done > 0 and " and the done flag" or "", round))
end
Players.PlayerAdded:Connect(function(p) task.spawn(run, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(run, p) end

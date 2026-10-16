-- treehouse/install_treehouse_reset1.lua (job 117; Studio EDIT; re-runnable). Adds workspace.Treehouse.TreehouseReset (server Script,
-- 3137 chars) with the folder attributes ResetUserIds "9611145467" (SelBell) and ResetRound 1: on her next join after the publish, her
-- treehouse pieces and the done flag are taken back through RS.AwardItems (negative counts, the game's own ledger) - once per round.
-- Squirrels, acorns, everything else stay. To reset again later: bump ResetRound. Undo: delete the script. No DataStore, no publish.
if game:GetService("RunService"):IsRunning() then print("QQ TRESET ABORT - Play mode") return end
local F = workspace:FindFirstChild("Treehouse")
if not F then print("QQ TRESET ABORT - no workspace.Treehouse") return end
local SRC = [===[
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
	print(string.format("TreehouseReset: %s (%d) joined - listed, round %s; waiting for the save", p.Name, p.UserId, tostring(F:GetAttribute("ResetRound"))))   -- (round 2: F9 says what happened)
	local t0 = os.clock()
	while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
	if not p.Parent or p:GetAttribute("SaveLoaded") ~= true then print("TreehouseReset: " .. p.Name .. " - the save never loaded; nothing done") return end
	task.wait(2)                                                                -- the save's items are on the player by now
	local round = math.max(1, math.floor(tonumber(F:GetAttribute("ResetRound")) or 1))
	local flag = "treereset_r" .. round
	if (tonumber(p:GetAttribute("Item_" .. flag)) or 0) >= 1 then print(string.format("TreehouseReset: %s - round %d was already done on this save; bump ResetRound to reset again", p.Name, round)) return end
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
]===]
do local ok, f, err = pcall(function() return loadstring(SRC) end); if ok and not f then print("QQ TRESET ABORT - does not compile: " .. tostring(err)) return end end
local old = F:FindFirstChild("TreehouseReset"); if old then old:Destroy() end
if F:GetAttribute("ResetUserIds") == nil then F:SetAttribute("ResetUserIds", "9611145467") end
if F:GetAttribute("ResetRound") == nil then F:SetAttribute("ResetRound", 1) end   -- (a re-run keeps the round already set)
local s = Instance.new("Script"); s.Name = "TreehouseReset"; s.RunContext = Enum.RunContext.Server; s.Source = SRC; s.Parent = F
print(string.format("QQ TRESET DONE: workspace.Treehouse.TreehouseReset (%d chars); ResetUserIds %q, ResetRound %s", #s.Source, tostring(F:GetAttribute("ResetUserIds")), tostring(F:GetAttribute("ResetRound"))))

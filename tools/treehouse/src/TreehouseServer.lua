-- TreehouseServer (workspace.Treehouse, RunContext Server). Job 103 (Shannon, Oct 15 2026: "finding parts and building a treehouse
-- in the forest ... strew the pieces throughout the french map, and have a count somewhere to show how many more they need, and they
-- can piece it together as they collect the pieces"). The pieces and the half-built house are PER PLAYER (each builds their own, drawn
-- by TreehouseClient on their own screen); this script is the only authority: it hands out a piece once, checks the player really
-- stands by it, keeps it on the save as Item_tree_<id> through the game's AwardItems ledger (no new store), and pays the builder's
-- 100 acorns once (Item_tree_done) through AwardAcorns + the Acorns attribute, the way the thank-you gifts do. Never touches a
-- DataStore. Attributes it sets on the player: TreePieces (how many so far; the dashboards can read it).
-- Pieces: the folder's attribute Pieces (JSON: [{id, x, y, z, kind}], written by the installer).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local REACH = 20                                    -- studs from the piece a pick-up is honoured within (the prompt shows at 10)
local PRIZE = 100
local ev = RS:WaitForChild("TreehousePick", 60)
local awardItems = RS:WaitForChild("AwardItems", 60)
local awardAcorns = RS:WaitForChild("AwardAcorns", 60)
if not (ev and awardItems and awardAcorns) then warn("Treehouse: ReplicatedStorage is missing TreehousePick / AwardItems / AwardAcorns; the treehouse is off") return end
local pieces, byId = {}, {}
do
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute("Pieces") or "[]") end)
	if ok and type(t) == "table" then pieces = t end
	for _, p in ipairs(pieces) do if type(p) == "table" and p.id then byId[p.id] = p end end
end
local TOTAL = #pieces
if TOTAL == 0 then warn("Treehouse: no pieces in the Pieces attribute; the treehouse is off") return end
local got = {}                                      -- got[player][id] = true, this session (the attribute follows at once, this is belt and braces)
local last = {}                                     -- last[player] = os.clock() of the last honoured pick
local function has(p, id) return (got[p] and got[p][id]) or (tonumber(p:GetAttribute("Item_tree_" .. id)) or 0) >= 1 end
local function count(p)
	local n = 0
	for _, pc in ipairs(pieces) do if has(p, pc.id) then n += 1 end end
	return n
end
local function refresh(p)
	local n = count(p)
	if p:GetAttribute("TreePieces") ~= n then p:SetAttribute("TreePieces", n) end
	return n
end
local function pay(p)
	if (tonumber(p:GetAttribute("Item_tree_done")) or 0) >= 1 or (got[p] and got[p].done) then return false end
	got[p] = got[p] or {}; got[p].done = true
	awardItems:Fire(p, "tree_done", 1)
	awardAcorns:Fire(p, PRIZE)
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + PRIZE)
	return true
end
ev.OnServerEvent:Connect(function(p, what, id)
	if what ~= "pick" or type(id) ~= "string" then return end
	local pc = byId[id]
	if not pc then return end
	if p:GetAttribute("SaveLoaded") ~= true then ev:FireClient(p, "wait") return end
	if has(p, id) then ev:FireClient(p, "got", id, refresh(p)) return end        -- (already theirs: the client just tidies up)
	local now = os.clock()
	if last[p] and now - last[p] < 0.25 then return end
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local d = (root.Position - Vector3.new(pc.x, pc.y, pc.z)).Magnitude
	if d > REACH then return end                                                -- (not there: a stale prompt or a hacked client; nothing happens)
	last[p] = now
	got[p] = got[p] or {}; got[p][id] = true
	awardItems:Fire(p, "tree_" .. id, 1)
	local n = refresh(p)
	ev:FireClient(p, "got", id, n)
	if n >= TOTAL and pay(p) then ev:FireClient(p, "done", PRIZE, n) end
end)
local function join(p)
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
		if p.Parent then refresh(p) end
	end)
end
Players.PlayerAdded:Connect(join)
for _, p in ipairs(Players:GetPlayers()) do join(p) end
Players.PlayerRemoving:Connect(function(p) got[p] = nil; last[p] = nil end)
print(string.format("Treehouse: %d pieces, %d acorns for the builder", TOTAL, PRIZE))

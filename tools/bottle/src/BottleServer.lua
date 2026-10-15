-- BottleServer (Script, server; in workspace.Bottles). The message-in-a-bottle game (job 118). Shannon (Oct 6 / Oct 15 2026):
--  * at the stand on the Porto beach a player writes a fill-in-the-blank note TO someone at sea (pirate, lighthouse keeper, whale, ...),
--    pays SendCost acorns and tosses it; ONE a day. After the game's daily reset a reply washes up for them by the stand, answering
--    what they picked, signed by whoever they wrote to.
--  * silly bottles wash up along the beach on their own (MaxBeach at a time); uncorking one pays FindPrize acorns, FindCap a day.
-- The save holds only numbers, through the game's own ledger (RS.AwardItems deltas - no DataStore here):
--   Item_bottle_out   = the day it was sent + 1 (0 = nothing at sea)   Item_bottle_card = to*1e6 + card*1e4 + a*100 + b
--   Item_bottle_paid  = day*10 + finds paid that day                    Item_bottles_found / Item_bottle_replies = counts
-- The day is the Daily's: floor((os.time() - DayOffsetHours h) / 86400), DayOffsetHours from workspace.Daily (9 by default).
-- Studio only: the folder attribute TestDayOffset moves "today" forward, to see a reply without waiting.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local Text = require(F:WaitForChild("BottleText"))
local ev = F:WaitForChild("BottleEvent")
local awardItems = RS:WaitForChild("AwardItems", 60)
local awardAcorns = RS:WaitForChild("AwardAcorns", 60)
if not (awardItems and awardAcorns) then warn("Bottles: ReplicatedStorage is missing AwardItems / AwardAcorns; the bottles are off") return end
local function A(name, default) local v = F:GetAttribute(name); if v == nil then return default end; return v end
local function today()
	local D = workspace:FindFirstChild("Daily")
	local off = (D and tonumber(D:GetAttribute("DayOffsetHours"))) or 9
	local t = math.floor((os.time() - off * 3600) / 86400)
	if RunService:IsStudio() then t += math.floor(tonumber(F:GetAttribute("TestDayOffset")) or 0) end
	return t
end
local function item(p, id) return math.floor(tonumber(p:GetAttribute("Item_" .. id)) or 0) end
-- the ledger answers at the end of the frame, so the server keeps its own view of each player's numbers while they play
local view = {}
local function get(p, id) local v = view[p]; if v and v[id] ~= nil then return v[id] end; return item(p, id) end
local function put(p, id, value)
	value = math.max(0, math.floor(value))
	local d = value - get(p, id)
	view[p] = view[p] or {}; view[p][id] = value
	if d ~= 0 then awardItems:Fire(p, id, d) end
end
local function pay(p, n)
	if n == 0 then return end
	awardAcorns:Fire(p, n)
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + n)
end
local function ready(p) return p:GetAttribute("SaveLoaded") == true end
local function decode(code)
	return math.floor(code / 1e6) % 100, math.floor(code / 1e4) % 100, math.floor(code / 100) % 100, code % 100
end
-- what this player's stand should say, and whether a reply is waiting
local function state(p)
	local out, day = get(p, "bottle_out"), today()
	local s = {cost = A("SendCost", 15), acorns = tonumber(p:GetAttribute("Acorns")) or 0, ready = ready(p)}
	if out > 0 then
		s.sentDay = out - 1
		s.replyReady = day > out - 1
		local to, card, a, b = decode(get(p, "bottle_card"))
		if Text.valid(to, card, a, b) then s.sent = {to, card, a, b} end
	end
	return s
end
local function push(p) ev:FireClient(p, "state", state(p)) end
local last = {}
local function throttle(p) local t = os.clock(); if last[p] and t - last[p] < 1 then return false end; last[p] = t; return true end
ev.OnServerEvent:Connect(function(p, what, a1, a2, a3, a4)
	if what == "state" then push(p) return end
	if not throttle(p) then return end
	if not ready(p) then ev:FireClient(p, "msg", "Your save is still loading - try again in a moment") return end
	if what == "send" then
		local to, card, a, b = tonumber(a1), tonumber(a2), tonumber(a3), tonumber(a4)
		if not (to and card and a and b and Text.valid(to, card, a, b)) then return end
		local s = state(p)
		if s.sentDay then
			ev:FireClient(p, "msg", s.replyReady and "Your reply has washed up by the stand - read it first!" or "Your bottle is already out at sea. Check the beach tomorrow!")
			return
		end
		local cost = math.max(0, math.floor(A("SendCost", 15)))
		local have = tonumber(p:GetAttribute("Acorns")) or 0
		if have < cost then ev:FireClient(p, "msg", string.format("A bottle costs %d acorns - you have %d", cost, have)) return end
		pay(p, -cost)
		put(p, "bottle_card", to * 1e6 + card * 1e4 + a * 100 + b)
		put(p, "bottle_out", today() + 1)
		ev:FireClient(p, "sent", to, card, a, b)
		push(p)
	elseif what == "reply" then
		local out = get(p, "bottle_out")
		if out <= 0 or today() <= out - 1 then push(p) return end
		local to, card, a, b = decode(get(p, "bottle_card"))
		put(p, "bottle_out", 0); put(p, "bottle_card", 0)
		put(p, "bottle_replies", get(p, "bottle_replies") + 1)
		if Text.valid(to, card, a, b) then
			local seed = (out * 31 + card * 7 + a * 3 + b) % 997
			ev:FireClient(p, "reply", to, card, a, b, seed)
		end
		push(p)
	end
end)
-- ---------- the silly bottles on the beach ----------
local spots = {}
pcall(function() spots = HttpService:JSONDecode(F:GetAttribute("WashSpots") or "[]") end)
local beachF = F:FindFirstChild("Beach") or Instance.new("Folder"); beachF.Name = "Beach"; beachF.Parent = F
beachF:ClearAllChildren()
local template = RS:FindFirstChild("BottleTemplate")
local taken = {}
local function wash()
	if #spots == 0 or not template then return end
	local free = {}
	for i = 1, #spots do if not taken[i] then table.insert(free, i) end end
	if #free == 0 then return end
	local i = free[math.random(#free)]
	local s = spots[i]
	local m = template:Clone(); m.Name = "BeachBottle"
	m:PivotTo(CFrame.new(s[1], s[2] + 0.35, s[3]) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0) * CFrame.Angles(0, 0, math.rad(8)))   -- lying on its side (a Cylinder's length is X), neck a little up
	m.Parent = beachF
	taken[i] = m
	local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(p)
			if taken[i] ~= m or not ready(p) then return end
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - m:GetPivot().Position).Magnitude > 14 then return end
			taken[i] = nil; m:Destroy()
			local day, paid = today(), get(p, "bottle_paid")
			local n = (math.floor(paid / 10) == day) and (paid % 10) or 0
			local prize = 0
			if n < math.min(9, math.floor(A("FindCap", 5))) then prize = math.floor(A("FindPrize", 10)); put(p, "bottle_paid", day * 10 + n + 1) end
			pay(p, prize)
			put(p, "bottles_found", get(p, "bottles_found") + 1)
			ev:FireClient(p, "beach", math.random(#Text.BEACH), prize)
		end)
	end
end
task.spawn(function()
	for _ = 1, math.max(0, math.floor(A("MaxBeach", 3))) do wash() end
	while true do
		task.wait(math.max(10, tonumber(A("RespawnSeconds", 75)) or 75))
		local n = 0
		for _, m in pairs(taken) do if m and m.Parent then n += 1 end end
		if n < math.floor(A("MaxBeach", 3)) then wash() end
	end
end)
Players.PlayerRemoving:Connect(function(p) view[p] = nil; last[p] = nil end)
Players.PlayerAdded:Connect(function(p)
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and not ready(p) and os.clock() - t0 < 120 do task.wait(0.5) end
		if p.Parent then push(p) end
	end)
end)
print(string.format("Bottles: %d wash-up spots, send %d acorns, find %d acorns (%d a day)", #spots, A("SendCost", 15), A("FindPrize", 10), A("FindCap", 5)))

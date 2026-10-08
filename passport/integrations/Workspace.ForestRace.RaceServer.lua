local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("RaceEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local MAP = F:GetAttribute("Map") or "forest"
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local isRace = {}
for _, e in ipairs(Registry.squirrels) do if e.map == MAP then isRace[e.id] = true end end

local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- which squirrels are in the race, and hearing their clicks ----
local races = {}                                            -- player -> {phase, found, n, total, t0}
local ids, total = {}, 0
local hooked = setmetatable({}, {__mode = "k"})
local finish
local function stop(player, why)
	if not races[player] then return end
	races[player] = nil
	player:SetAttribute("Racing", nil)
	ev:FireClient(player, "stop", why)
end
local function onClick(player, id)
	local r = races[player]
	if not r or r.phase ~= "run" or r.found[id] then return end
	r.found[id] = true; r.n += 1
	ev:FireClient(player, "tick", id, r.n, r.total, os.clock() - r.t0)
	if r.n >= r.total then finish(player) end
end
local function scan()
	local list, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and isRace[id] and not list[id] then
			list[id] = true; n += 1
   for _,part in ipairs(m:GetDescendants()) do
    if part:IsA("BasePart") and not hooked[part] then
     hooked[part]=true;part.CanTouch=true
     part.Touched:Connect(function(hit)
      local char=hit:FindFirstAncestorOfClass("Model");local player=char and Players:GetPlayerFromCharacter(char)
      if player then onClick(player,id) end
     end)
    end
   end
			for _, cd in ipairs(m:GetDescendants()) do
				if cd:IsA("ClickDetector") and not hooked[cd] then
					hooked[cd] = true
					cd.MouseClick:Connect(function(player) onClick(player, id) end)
				end
			end
		end
	end
	ids, total = list, n
	F:SetAttribute("Total", n)
end
task.spawn(function() while true do scan(); task.wait(total == 0 and 1 or 8) end end)

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "ForestRace_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("RaceBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}     -- gold, silver, bronze
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil                                   -- no empty stripes
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a squirrel finder"
			end
		end
	end
 local ranks={};for i,e in ipairs(list) do if i<=10 then ranks[e.uid]=i end end
 for _,p in ipairs(Players:GetPlayers()) do
  local scope=ok and "global" or (RunService:IsStudio() and "server" or "unavailable")
  p:SetAttribute("PassportBoard_race",game:GetService("HttpService"):JSONEncode({rank=scope~="unavailable" and (ranks[p.UserId] or 0) or 0,scope=scope,checked=workspace:GetServerTimeNow()}))
 end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end         -- the board keeps a player's fastest
				return cs
			end)
		end)
		if not ok then warn("ForestRace: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a race ----
local function idList() local t = {} for id in pairs(ids) do t[#t + 1] = id end return t end
local function start(player)
	if races[player] or total == 0 or not player:GetAttribute("SaveLoaded") then return end
	local r = {phase = "count", found = {}, n = 0, total = total}
	races[player] = r
	player:SetAttribute("Racing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, r.total, idList(), item(player, "race_best"))
	task.delay(cd, function()
		if races[player] ~= r then return end
		r.phase = "run"; r.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 20) * 60, function() if races[player] == r then stop(player, "time") end end)
	end)
end
finish = function(player)
	local r = races[player]
	if not r then return end
	local secs = os.clock() - r.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	races[player] = nil
	player:SetAttribute("Racing", nil)
	local best = item(player, "race_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "race_best", cs) end
	-- a few acorns for beating your own best (Shannon: "a few acorns if you beat your best time ok"); not for a time too
	-- quick to be real (the same MinSeconds that keeps it off the board)
	local prize = 0
	if isBest and secs >= (F:GetAttribute("MinSeconds") or 45) then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player,"race",{cs=cs,previousBest=best,improvement=best>cs and best-cs or 0,prize=prize,boardReady=false}) end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("ForestRace: %s ran the forest in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= (F:GetAttribute("MinSeconds") or 45) then
		task.spawn(submit, player, isBest and cs or best)
	else
		player:SetAttribute("PassportBoard_race",game:GetService("HttpService"):JSONEncode({rank=0,scope="unavailable",time=workspace:GetServerTimeNow()}))
		warn(string.format("ForestRace: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not races[player] then
		local char = player.Character
		local p = Vector3.new(F:GetAttribute("StartX"), F:GetAttribute("StartY"), F:GetAttribute("StartZ"))
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(1, 0, 0))) end
		task.wait(0.3)
		start(player)
	end
end)
Players.PlayerRemoving:Connect(function(p) races[p] = nil end)
if RunService:IsStudio() then                               -- Studio only: count n more squirrels as found, as if clicked
	local dbg = Instance.new("BindableFunction"); dbg.Name = "RaceDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player, n)
		local r = races[player]
		if not r or r.phase ~= "run" then return "not racing" end
		local k = 0
		for id in pairs(ids) do
			if k >= n then break end
			if not r.found[id] then k += 1; onClick(player, id) end
		end
		return tostring(r.n) .. "/" .. tostring(r.total)
	end
end
print("ForestRace: ready")

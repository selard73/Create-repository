-- ClimbServer: the Sandstone Climb's clock (server-side), the bell, the board and the personal-best acorns
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("ClimbEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local zone = F:WaitForChild("Summit"):WaitForChild("BellZone")
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

-- ---- the bell: whoever reaches it rings it for everyone, one ring at a time ----
local lastRing = 0
local function ring(player)
	if os.clock() - lastRing < 6 then return end
	lastRing = os.clock()
	ev:FireAllClients("ring", player and player.DisplayName or "")
end

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "CliffClimb_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("ClimbBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil
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
				names[uid] = ok2 and n or "a climber"
			end
		end
	end
 local ranks={};for i,e in ipairs(list) do if i<=10 then ranks[e.uid]=i end end
 for _,p in ipairs(Players:GetPlayers()) do
  local scope=ok and "global" or (RunService:IsStudio() and "server" or "unavailable")
  p:SetAttribute("PassportBoard_climb",game:GetService("HttpService"):JSONEncode({rank=scope~="unavailable" and (ranks[p.UserId] or 0) or 0,scope=scope,checked=workspace:GetServerTimeNow()}))
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
				if old and old <= cs then return nil end
				return cs
			end)
		end)
		if not ok then warn("SandstoneClimb: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a climb ----
local climbs = {}                                            -- player -> {phase, t0}
local function stop(player, why)
	local c = climbs[player]
	if not c then return end
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	ev:FireClient(player, "stop", why)
end
local function start(player)
	if climbs[player] then stop(player, "restart") end
	if player:GetAttribute("Racing") then ev:FireClient(player, "busy"); return end
	if not player:GetAttribute("SaveLoaded") then return end
	local c = {phase = "count"}
	climbs[player] = c
	player:SetAttribute("Climbing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, item(player, "climb_best"))
	task.delay(cd, function()
		if climbs[player] ~= c then return end
		c.phase = "run"; c.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 10) * 60, function() if climbs[player] == c then stop(player, "time") end end)
	end)
end
local function finish(player)
	local c = climbs[player]
	if not c or c.phase ~= "run" then return end
	local secs = os.clock() - c.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	local best = item(player, "climb_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "climb_best", cs) end
	local minS = F:GetAttribute("MinSeconds") or 10
	local prize = 0
	if isBest and secs >= minS then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player,"climb",{cs=cs,previousBest=best,improvement=best>cs and best-cs or 0,prize=prize,boardReady=false}) end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("SandstoneClimb: %s climbed to the bell in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= minS then
		task.spawn(submit, player, isBest and cs or best)
	else
		player:SetAttribute("PassportBoard_climb",game:GetService("HttpService"):JSONEncode({rank=0,scope="unavailable",time=workspace:GetServerTimeNow()}))
		warn(string.format("SandstoneClimb: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
zone.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	ring(player)
	if climbs[player] then finish(player) end
end)
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
local function startSpot()
	local st = F:FindFirstChild("StartStone", true)
	local y = F:GetAttribute("StartY") or ((st and st.Position.Y or 5) + 3)
	return Vector3.new(st and st.Position.X or 498, y, st and st.Position.Z or -243)
end
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not climbs[player] then
		local char = player.Character
		local p = startSpot()
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1))) end
		task.wait(0.3)
		start(player)
	end
end)
local function watch(player)
	player.CharacterAdded:Connect(function() if climbs[player] then stop(player, "fell") end end)
end
Players.PlayerAdded:Connect(watch)
for _, pl in ipairs(Players:GetPlayers()) do watch(pl) end
Players.PlayerRemoving:Connect(function(pl) climbs[pl] = nil end)
if RunService:IsStudio() then                               -- Studio only: start a climb without the prompt (for tests)
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ClimbDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) start(player); return "started" end
end
print("SandstoneClimb: ready")

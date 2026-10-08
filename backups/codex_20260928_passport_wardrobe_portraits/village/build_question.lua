-- DailyQuestion: the Questions of the Day. Shannon (Sep 25 2026): "A daily question or riddle, must submit the answer at
-- the post office by 6pm est. All correct answers for that day are awarded 25 acorns; drawing for one right answer to get
-- a 200 acorn reward and a 'Wise Squirrel' badge" ... "mostly about the game story and info. rewarding players for knowing
-- the game" ... and then "what if we put a first question of the day by the entrance dias in the forest to draw players in
-- right away to try and find answers and give them instant acorns?, then this board could be a 2nd question of the day?"
--   TWO BOARDS, two questions a day:
--     #1 "forest" - a chalkboard in front of the forest spawn, asking what a brand-new player can find out: the forest
--        squirrels' own stories (read on their cards when you find them), the forest itself, and riddles;
--     #2 "poste"  - a chalkboard at LA POSTE's corner on the Rue de Noisette (beside the window, not in front of it:
--        Shannon, "more over to the side so you can see in the La Poste window"): the village and Chateau squirrels,
--        the books in the Librairie, the village.
--   Walk up, press Answer, pick one of four answers (shuffled for each player; one try a day per board). The card pops up
--   at the top of the screen, above your character (Shannon: "should pop up above the players head not covering over top
--   of them"), and closes when you walk away.
--   A RIGHT ANSWER: Reward (25) acorns at once, and an entry in the day's draw (one per board, so two right answers are
--   two chances).
--   THE DAY: 6pm Eastern (US) to 6pm Eastern, daylight saving handled; each board's question is pinned per day in the
--   DataStore so every server asks the same.
--   THE DRAW: DrawDelay seconds after 6pm one server draws a single entry from every server's (DataStore DailyQuestion_v1:
--   e_<day>_<shard>, d_<day> claimed with UpdateAsync, so it happens exactly once) and tells every server
--   (MessagingService). A server that starts after a 6pm nobody was around for holds that draw late. The winner gets
--   Prize (200) acorns and the Wise Squirrel badge - straight away if online, else the next time they join (p_<userId>).
--   THE BADGE: kept in the save (Item_wise_day = the day of the first win, Item_wise_wins) and shown in the badge case;
--   the Roblox badge is Badge_wise.
-- Ledger items: q_round_<board> / q_right_<board> (the last day answered / answered right on that board), wise_last (the
-- last prize delivered, so none is paid twice). The questions are a ModuleScript in ServerStorage: clients never see
-- the answers. In Studio (API access off) everything lives in memory; QuestionDebug (Studio only) closes the day early.
-- Run in edit mode (re-runnable). opts.bankSource = the bank module's source (village/question_bank.lua).
return function(opts)
	opts = opts or {}
	local ServerStorage = game:GetService("ServerStorage")
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("DailyQuestion")
	local keepBadge = old and tonumber(old:GetAttribute("Badge_wise")) or 0          -- a badge id entered in Properties survives a reinstall
	if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "DailyQuestion"
	F:SetAttribute("Reward", opts.reward or 25); F:SetAttribute("Prize", opts.prize or 200)
	F:SetAttribute("DeadlineHour", opts.deadlineHour or 18)                           -- 6pm Eastern
	F:SetAttribute("DrawDelay", opts.drawDelay or 90)
	F:SetAttribute("Badge_wise", opts.badgeId or (keepBadge > 0 and keepBadge) or 4354922527612323)   -- "Wise Squirrel" (Shannon, Sep 25)
	F:SetAttribute("CloseDistance", 16)                                              -- walk this far from the board and the card closes
	local action = Instance.new("RemoteFunction"); action.Name = "QuestionAction"; action.Parent = F
	local ev = Instance.new("RemoteEvent"); ev.Name = "QuestionEvent"; ev.Parent = F
	if opts.bankSource then
		local oldBank = ServerStorage:FindFirstChild("QuestionBank"); if oldBank then oldBank:Destroy() end
		local m = Instance.new("ModuleScript"); m.Name = "QuestionBank"; m.Source = opts.bankSource; m.Parent = ServerStorage
	end
	assert(ServerStorage:FindFirstChild("QuestionBank"), "DailyQuestion: no QuestionBank - pass opts.bankSource")

	-- ---------------------------------------------------------------- the chalkboards ----
	local BOARDS = {
		{id = "forest", title = "QUESTION OF THE DAY #1", at = opts.forestAt or Vector3.new(-5.5, 0, -8), faceTo = Vector3.new(3, 0, 1),       -- facing the spawn, off the dais edge by the bush (Shannon)
		 how = "Answer by 6pm Eastern for 25 acorns! The squirrels' stories hold the answers."},
		{id = "poste", title = "QUESTION OF THE DAY #2", at = opts.posteAt or Vector3.new(168.4, 0, -135.2), facing = Vector3.new(0.5, 0, 0.87),   -- the street, turned in toward the town (Shannon)
		 how = "Answer here by 6pm Eastern. Right answers win 25 acorns!"},
	}
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
	local WOOD, CHALK = C(120, 78, 44), C(36, 50, 42)
	local function makeBoard(b)
		local hit = workspace:Raycast(Vector3.new(b.at.X, 60, b.at.Z), Vector3.new(0, -120, 0), rp)
		local at = Vector3.new(b.at.X, hit and hit.Position.Y or b.at.Y, b.at.Z)
		local facing = b.facing or Vector3.new(b.faceTo.X - at.X, 0, b.faceTo.Z - at.Z).Unit
		local base = CFrame.lookAt(at, at + facing)                                       -- local -z = the way it faces
		local board = Instance.new("Model"); board.Name = "Board_" .. b.id
		board:SetAttribute("BoardId", b.id)
		local function part(name, size, cf, colour, material)
			local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
			p.Material = material or Enum.Material.Wood; p.Anchored = true; p.CanCollide = true
			p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = board
			return p
		end
		local H, W, TILT = 4.8, 3.6, math.rad(12)
		local spread = H * math.sin(TILT)
		local cy = (H / 2) * math.cos(TILT) + 0.02
		local front = part("Front", Vector3.new(W, H, 0.2), base * CFrame.new(0, cy, -spread / 2) * CFrame.Angles(TILT, 0, 0), WOOD)
		part("Back", Vector3.new(W, H, 0.2), base * CFrame.new(0, cy, spread / 2) * CFrame.Angles(-TILT, 0, 0), WOOD)
		local hinge = part("Hinge", Vector3.new(W + 0.2, 0.3, 0.3), base * CFrame.new(0, cy + (H / 2) * math.cos(TILT) - 0.1, 0), C(90, 58, 32), Enum.Material.Metal)
		hinge.Shape = Enum.PartType.Cylinder
		local face = part("Face", Vector3.new(W - 0.4, H - 0.5, 0.05), front.CFrame * CFrame.new(0, 0, -0.125), CHALK, Enum.Material.Slate)
		face.CanCollide = false
		local sg = Instance.new("SurfaceGui"); sg.Name = "Words"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 100; sg.LightInfluence = 0.3; sg.Parent = face
		local function line(name, y, h, maxSize, font, colour, text)
			local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 14, 0, y); l.Size = UDim2.new(1, -28, 0, h)
			l.Font = font; l.TextScaled = true; l.TextWrapped = true; l.TextColor3 = colour; l.Text = text or ""; l.Parent = sg
			local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = maxSize; cap.Parent = l
			return l
		end
		line("Title", 10, 44, 36, Enum.Font.FredokaOne, C(250, 226, 120), b.title)
		line("Question", 62, 170, 34, Enum.Font.PatrickHand, C(244, 242, 232), "")
		line("How", 238, 56, 24, Enum.Font.PatrickHand, C(196, 232, 196), b.how)
		local rule = Instance.new("Frame"); rule.BackgroundColor3 = C(200, 206, 196); rule.BackgroundTransparency = 0.4; rule.BorderSizePixel = 0
		rule.Position = UDim2.new(0, 30, 0, 300); rule.Size = UDim2.new(1, -60, 0, 2); rule.Parent = sg
		line("Yesterday", 308, 58, 22, Enum.Font.PatrickHand, C(230, 226, 214), "")
		line("Winner", 368, 40, 24, Enum.Font.PatrickHand, C(250, 226, 120), "")
		local prompt = Instance.new("ProximityPrompt"); prompt.Name = "QuestionPrompt"; prompt.ActionText = "Answer"; prompt.ObjectText = (b.id == "forest") and "Question of the Day #1" or "Question of the Day #2"
		prompt.KeyboardKeyCode = Enum.KeyCode.E; prompt.MaxActivationDistance = 10; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0
		prompt:SetAttribute("BoardId", b.id)
		prompt.Parent = face
		board.PrimaryPart = front
		pcall(function() board.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
		board.Parent = F
	end
	for _, b in ipairs(BOARDS) do makeBoard(b) end

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
local BadgeService = game:GetService("BadgeService")
local ServerStorage = game:GetService("ServerStorage")
local F = script.Parent
local action = F:WaitForChild("QuestionAction")
local ev = F:WaitForChild("QuestionEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local BANK = require(ServerStorage:WaitForChild("QuestionBank"))
local STUDIO = RunService:IsStudio()
local store
if not STUDIO then pcall(function() store = DSS:GetDataStore("DailyQuestion_v1") end) end
local TOPIC, SHARDS = "DailyQuestion_v1", 8
local BOARDS = {"forest", "poste"}
local byId, words = {}, {}
for _, b in ipairs(BOARDS) do
	byId[b] = {}
	for _, q in ipairs(BANK[b]) do byId[b][q.id] = q end
	words[b] = F:WaitForChild("Board_" .. b):WaitForChild("Face"):WaitForChild("Words")
end
local function isBoard(b) return type(b) == "string" and byId[b] ~= nil end

local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function giveAcorns(player, n)
	awardAcorns:Fire(player, n)
	player:SetAttribute("Acorns", (tonumber(player:GetAttribute("Acorns")) or 0) + n)
end

-- ---- Eastern time: a day of questions runs from one 6pm Eastern to the next ----
local function daysFromCivil(y, m, d)
	y = (m <= 2) and (y - 1) or y
	local era = math.floor(y / 400)
	local yoe = y - era * 400
	local mp = (m + 9) % 12
	local doy = math.floor((153 * mp + 2) / 5) + d - 1
	local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
	return era * 146097 + doe - 719468
end
local function nthSunday(y, m, n)
	local first = daysFromCivil(y, m, 1)
	return first + (7 - (first + 4) % 7) % 7 + 7 * (n - 1)       -- (days + 4) % 7 == 0 on a Sunday
end
local function easternOffset(t)                                  -- hours from UTC: -4 in daylight time, -5 otherwise
	local y = tonumber(os.date("!%Y", t))
	local start = nthSunday(y, 3, 2) * 86400 + 7 * 3600          -- 2am EST on the second Sunday of March
	local finish = nthSunday(y, 11, 1) * 86400 + 6 * 3600        -- 2am EDT on the first Sunday of November
	return (t >= start and t < finish) and -4 or -5
end
local shift = 0                                                  -- Studio test: QuestionDebug moves the clock on
local function now() return os.time() + shift end
local function hour() return F:GetAttribute("DeadlineHour") or 18 end
local function roundAt(t) return math.floor((t + easternOffset(t) * 3600 - hour() * 3600) / 86400) end
local function closesAt(r)
	local localClose = (r + 1) * 86400 + hour() * 3600
	return localClose - easternOffset(localClose + 5 * 3600) * 3600
end
local function dayOf(r) local c = closesAt(r); return math.floor((c + easternOffset(c) * 3600) / 86400) end   -- the Eastern calendar day it closes on

-- ---- each board's question for a day: the same on every server ----
local pinned = {forest = {}, poste = {}}
local function questionFor(b, r)
	local id = pinned[b][r]
	if id and byId[b][id] then return byId[b][id] end
	local list = BANK[b]
	local candidate = list[(r % #list) + 1].id
	id = candidate
	if store then
		local chosen = candidate
		local ok = pcall(function()
			store:UpdateAsync("q_" .. b .. "_" .. tostring(r), function(old)
				if type(old) == "string" and byId[b][old] then chosen = old; return nil end
				chosen = candidate
				return candidate
			end)
		end)
		if ok then id = chosen end
	end
	pinned[b][r] = id
	return byId[b][id]
end
local function orderFor(player, b, r, n)                         -- the four answers, shuffled for this player, board and day
	local rng = Random.new((player.UserId % 1000003) * 1000 + (r % 500) + (b == "poste" and 500 or 0))
	local idx = {}
	for i = 1, n do idx[i] = i end
	for i = n, 2, -1 do local j = rng:NextInteger(1, i); idx[i], idx[j] = idx[j], idx[i] end
	return idx
end

-- ---- the right answers, for the draw ----
local shard = 0
do local h = 0; for i = 1, #game.JobId do h = (h * 31 + string.byte(game.JobId, i)) % 1000003 end; shard = h % SHARDS end
local buffer, localEntries = {}, {}
local function addEntry(player, b, r)
	local e = {u = player.UserId, n = player.DisplayName, b = b}
	if not store then localEntries[r] = localEntries[r] or {}; table.insert(localEntries[r], e) return end
	buffer[r] = buffer[r] or {}
	table.insert(buffer[r], e)
end
local function flush()
	if not store then return end
	for r, list in pairs(buffer) do
		if #list > 0 then
			buffer[r] = {}
			local ok, err = pcall(function()
				store:UpdateAsync("e_" .. r .. "_" .. shard, function(old)
					old = type(old) == "table" and old or {}
					for _, e in ipairs(list) do table.insert(old, e) end
					return old
				end)
			end)
			if not ok then
				warn("DailyQuestion: could not save the right answers yet - " .. tostring(err))
				for _, e in ipairs(list) do table.insert(buffer[r], e) end
			end
		end
	end
end
local function readAll(r)
	local all = {}
	if not store then
		for _, e in ipairs(localEntries[r] or {}) do table.insert(all, e) end
	else
		for s = 0, SHARDS - 1 do
			local ok, list = pcall(function() return store:GetAsync("e_" .. r .. "_" .. s) end)
			if ok and type(list) == "table" then for _, e in ipairs(list) do table.insert(all, e) end end
		end
	end
	local seen, out = {}, {}                                     -- one entry per player per board
	for _, e in ipairs(all) do
		local key = type(e) == "table" and e.u and (tostring(e.u) .. ":" .. tostring(e.b))
		if key and not seen[key] then seen[key] = true; table.insert(out, e) end
	end
	return out
end

-- ---- the badge and the prize ----
local function giveBadge(player)
	local id = tonumber(F:GetAttribute("Badge_wise")) or 0
	if id <= 0 or STUDIO then return end
	task.spawn(function()
		local okH, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, id) end)
		if okH and not has then
			local ok, err = pcall(function() BadgeService:AwardBadgeAsync(player.UserId, id) end)            -- the current name
			if not ok then ok, err = pcall(function() BadgeService:AwardBadge(player.UserId, id) end) end    -- the older one
			if not ok then warn("DailyQuestion: badge award failed: " .. tostring(err)) end
		end
	end)
end
local studioPrizes, delivering = {}, {}
local function deliverPrizes(player)
	if delivering[player] then return end
	delivering[player] = true
	local t0 = os.clock()
	while player.Parent and not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 30 do task.wait(0.5) end
	task.wait(2)                                                 -- the saved counts land just after SaveLoaded
	local rounds = {}
	if store then
		local ok, list = pcall(function() return store:GetAsync("p_" .. tostring(player.UserId)) end)
		if ok and type(list) == "table" then rounds = list end
	else
		rounds = studioPrizes[player.UserId] or {}
	end
	table.sort(rounds)
	local last = item(player, "wise_last")
	local newest
	for _, r in ipairs(rounds) do
		if type(r) == "number" and r > last and player.Parent then
			local prize = F:GetAttribute("Prize") or 200
			giveAcorns(player, prize)
			awardItems:Fire(player, "wise_last", r - last); last = r          -- never paid twice: the ledger remembers
			if item(player, "wise_day") <= 0 and not newest then setItem(player, "wise_day", dayOf(r)) end
			awardItems:Fire(player, "wise_wins", 1)
			newest = r
			ev:FireClient(player, "prize", {prize = prize, day = dayOf(r)})
			print(string.format("DailyQuestion: %s collected the Wise Squirrel prize for day %d", player.Name, r))
		end
	end
	if newest then
		giveBadge(player)
		if store then
			pcall(function()
				store:UpdateAsync("p_" .. tostring(player.UserId), function(old)
					if type(old) ~= "table" then return nil end
					local keep = {}
					for _, r in ipairs(old) do if type(r) == "number" and r > newest then table.insert(keep, r) end end
					return keep
				end)
			end)
		else
			studioPrizes[player.UserId] = nil
		end
	end
	delivering[player] = nil
end

-- ---- the boards ----
local drawn, shown, localDraws = {}, {}, {}
local current = roundAt(now())
local function updateBoards()
	local rec = drawn[current - 1]
	for _, b in ipairs(BOARDS) do
		local w = words[b]
		local q = questionFor(b, current)
		w.Question.Text = q and q.q or ""
		local pq = questionFor(b, current - 1)
		w.Yesterday.Text = pq and ("Yesterday: " .. pq.q .. "  Answer: " .. pq.a[1]) or ""
		if rec and rec.n then w.Winner.Text = "Wise Squirrel: " .. rec.n
		elseif rec then w.Winner.Text = "Wise Squirrel: nobody got one right"
		else w.Winner.Text = "Wise Squirrel: drawn just after 6pm" end
	end
end
local function onDrawn(rec, quiet)
	if type(rec) ~= "table" or type(rec.r) ~= "number" then return end
	drawn[rec.r] = rec
	if shown[rec.r] then return end
	shown[rec.r] = true
	updateBoards()
	if not quiet then
		local a = {}
		for _, b in ipairs(BOARDS) do local q = questionFor(b, rec.r); a[b] = q and q.a[1] or "" end
		ev:FireAllClients("drawn", {name = rec.n, count = rec.count or 0, answers = a})
	end
	if rec.u then local p = Players:GetPlayerByUserId(rec.u); if p then task.spawn(deliverPrizes, p) end end
end
local function draw(r)
	if drawn[r] then return drawn[r] end
	local all = readAll(r)
	local rec, mine = nil, false
	local pick = (#all > 0) and all[Random.new():NextInteger(1, #all)] or nil
	if not store then
		rec = localDraws[r]
		if not rec then
			rec = pick and {u = pick.u, n = pick.n, r = r, count = #all} or {r = r, count = 0}
			localDraws[r] = rec; mine = true
		end
	else
		local ok = pcall(function()
			store:UpdateAsync("d_" .. tostring(r), function(old)
				if type(old) == "table" then rec = old; mine = false; return nil end
				rec = pick and {u = pick.u, n = pick.n, r = r, count = #all} or {r = r, count = 0}
				mine = true
				return rec
			end)
		end)
		if not ok or not rec then return nil end
	end
	if mine and rec.u then
		if store then
			pcall(function()
				store:UpdateAsync("p_" .. tostring(rec.u), function(old)
					old = type(old) == "table" and old or {}
					if not table.find(old, r) then table.insert(old, r) end
					return old
				end)
			end)
		else
			studioPrizes[rec.u] = studioPrizes[rec.u] or {}
			table.insert(studioPrizes[rec.u], r)
		end
		print(string.format("DailyQuestion: day %d drawn - %s is the Wise Squirrel (%d right answers)", r, tostring(rec.n), rec.count or 0))
	elseif mine then
		print(string.format("DailyQuestion: day %d drawn - nobody got one right", r))
	end
	if mine and store then pcall(function() MS:PublishAsync(TOPIC, rec) end) end
	onDrawn(rec, false)
	return rec
end
if store then
	pcall(function() MS:SubscribeAsync(TOPIC, function(msg) onDrawn(msg.Data, false) end) end)
end

-- ---- asking and answering ----
local answered, rightNow = {}, {}                                -- player -> {board -> day}, set before anything yields
local function stateOf(player, b, r)
	local a = answered[player] and answered[player][b]
	if a == r or item(player, "q_round_" .. b) == r then
		return ((rightNow[player] and rightNow[player][b] == r) or item(player, "q_right_" .. b) == r) and "right" or "wrong"
	end
	return "open"
end
action.OnServerInvoke = function(player, what, b, a, c)
	local r = roundAt(now())
	if what == "status" then
		return {ok = true, forest = stateOf(player, "forest", r), poste = stateOf(player, "poste", r), reward = F:GetAttribute("Reward") or 25}
	end
	if not isBoard(b) then return {ok = false, why = "no such board"} end
	local q = questionFor(b, r)
	if not q then return {ok = false, why = "no question today"} end
	if what == "get" then
		local order = orderFor(player, b, r, #q.a)
		local options = {}
		for pos, i in ipairs(order) do options[pos] = q.a[i] end
		local pq = questionFor(b, r - 1)
		local rec = drawn[r - 1]
		return {ok = true, board = b, round = r, q = q.q, kind = q.kind, options = options, state = stateOf(player, b, r), closes = closesAt(r),
			reward = F:GetAttribute("Reward") or 25, prize = F:GetAttribute("Prize") or 200,
			yq = pq and pq.q or "", ya = pq and pq.a[1] or "", yw = rec and rec.n or nil}
	elseif what == "answer" then
		if a ~= r then return {ok = false, why = "closed"} end                         -- the day turned while the card was open
		if stateOf(player, b, r) ~= "open" then return {ok = false, why = "already"} end
		local order = orderFor(player, b, r, #q.a)
		local i = order[tonumber(c) or 0]
		if not i then return {ok = false, why = "pick one"} end
		answered[player] = answered[player] or {}
		answered[player][b] = r                                                          -- one try: marked before anything can yield
		setItem(player, "q_round_" .. b, r)
		local right = (i == 1)
		local reward = F:GetAttribute("Reward") or 25
		if right then
			rightNow[player] = rightNow[player] or {}
			rightNow[player][b] = r
			setItem(player, "q_right_" .. b, r)
			giveAcorns(player, reward)
			addEntry(player, b, r)
		end
		print(string.format("DailyQuestion: %s answered %s day %d (%s): %s", player.Name, b, r, q.id, right and "right" or "wrong"))
		return {ok = true, right = right, reward = right and reward or 0, closes = closesAt(r)}
	end
	return {ok = false}
end

Players.PlayerAdded:Connect(function(p)
	task.spawn(deliverPrizes, p)
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 30 do task.wait(0.5) end
		task.wait(2)
		if p.Parent and item(p, "wise_day") > 0 then giveBadge(p) end              -- anyone who won before the badge existed
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(deliverPrizes, p) end
Players.PlayerRemoving:Connect(function(p) answered[p] = nil; rightNow[p] = nil; delivering[p] = nil end)
game:BindToClose(function() flush() end)

-- ---- the day turning over ----
task.spawn(function()
	-- yesterday's draw: already made (just show it), or never made because no server was up at 6pm (make it now)
	for back = 1, 3 do
		local r = current - back
		if store then
			local ok, rec = pcall(function() return store:GetAsync("d_" .. tostring(r)) end)
			if ok and type(rec) == "table" then onDrawn(rec, true)
			elseif ok then draw(r) end
		end
	end
	updateBoards()
end)
local lastFlush = os.clock()
task.spawn(function()
	while true do
		local r = roundAt(now())
		if r ~= current then
			local closed = current
			current = r
			flush()
			updateBoards()
			ev:FireAllClients("newday", {})
			task.delay((F:GetAttribute("DrawDelay") or 90) + math.random() * (STUDIO and 0 or 30), function() draw(closed) end)
		end
		if os.clock() - lastFlush > 30 then lastFlush = os.clock(); task.spawn(flush) end
		task.wait(1)
	end
end)
if STUDIO then
	local dbg = Instance.new("BindableFunction"); dbg.Name = "QuestionDebug"; dbg.Parent = F
	dbg.OnInvoke = function(what)
		if what == "close" then shift = closesAt(current) - os.time() + 1 end          -- jump to just after 6pm
		return {round = current, closes = closesAt(current), now = now(), forest = questionFor("forest", current).id, poste = questionFor("poste", current).id}
	end
end
print(string.format("DailyQuestion: ready - %d + %d questions, today's close %s UTC", #BANK.forest, #BANK.poste, os.date("!%Y-%m-%d %H:%M", closesAt(current))))
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local action = F:WaitForChild("QuestionAction")
local ev = F:WaitForChild("QuestionEvent")
local C = Color3.fromRGB
local NAVY, NAVY2, GOLD, CREAM, DIM, INK = C(38, 30, 52), C(56, 46, 76), C(240, 200, 90), C(255, 246, 220), C(160, 150, 180), C(255, 214, 90)
local GREEN, RED = C(70, 150, 90), C(170, 70, 70)
local NUMBER = {forest = "#1", poste = "#2"}
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0, 12); c.Parent = o; return c end
local function stroke(o, col, th) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th or 2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s end
local function text(parent, t, font, size, colour, x, y, w, h, align, scaled, minSize)
	local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, h)
	l.Font = font; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true
	l.TextXAlignment = align or Enum.TextXAlignment.Left; l.TextYAlignment = Enum.TextYAlignment.Top; l.Parent = parent
	if scaled then l.TextScaled = true; local k = Instance.new("UITextSizeConstraint"); k.MaxTextSize = size; k.MinTextSize = minSize or 8; k.Parent = l end
	return l
end
local function sound(id, vol) local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 0.6; s.Parent = pg; s:Play(); Debris:AddItem(s, 6) end

-- ---------------------------------------------------------------- the card: at the top of the screen, above your character ----
local gui = Instance.new("ScreenGui"); gui.Name = "QuestionCard"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 25; gui.Enabled = false; gui.Parent = pg
local W, H = 700, 262
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, 62); card.Size = UDim2.fromOffset(W, H)
card.BackgroundColor3 = NAVY; card.BackgroundTransparency = 0.04; card.BorderSizePixel = 0; card.Parent = gui
corner(card, UDim.new(0, 18)); stroke(card, GOLD, 3)
local scale = Instance.new("UIScale"); scale.Parent = card
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	-- the top part of the screen only: the character stands in the middle, and the card must not cover them
	scale.Scale = math.clamp(math.min((vp.Y * 0.6 - 62) / H, (vp.X - 24) / W), 0.4, 1)
end
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end)
local title = text(card, "Question of the Day", Enum.Font.Antique, 24, INK, 18, 8, 400, 26)
local kind = text(card, "", Enum.Font.FredokaOne, 13, DIM, 18, 33, 400, 16)
local close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -12, 0, 12); close.Size = UDim2.fromOffset(30, 30)
close.BackgroundColor3 = C(60, 50, 80); close.Font = Enum.Font.FredokaOne; close.TextSize = 18; close.TextColor3 = CREAM; close.Text = "X"; close.Parent = card
corner(close, UDim.new(0, 9))
local qText = text(card, "", Enum.Font.FredokaOne, 21, CREAM, 18, 52, W - 36, 44, nil, true, 8)
local buttons = {}
local BW = math.floor((W - 36 - 10) / 2)
for i = 1, 4 do
	local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
	local b = Instance.new("TextButton"); b.Name = "Answer" .. i; b.Position = UDim2.fromOffset(18 + col * (BW + 10), 100 + row * 46); b.Size = UDim2.fromOffset(BW, 40)
	b.BackgroundColor3 = NAVY2; b.AutoButtonColor = true; b.Font = Enum.Font.FredokaOne; b.TextSize = 17; b.TextColor3 = CREAM; b.TextWrapped = true; b.Text = ""
	b.TextScaled = true; b.Parent = card
	corner(b, UDim.new(0, 12)); local bs = stroke(b, C(110, 96, 140), 2)
	local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = 17; cap.MinTextSize = 6; cap.Parent = b
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.PaddingTop = UDim.new(0, 2); pad.PaddingBottom = UDim.new(0, 2); pad.Parent = b
	buttons[i] = {btn = b, stroke = bs}
end
local status = text(card, "", Enum.Font.FredokaOne, 15, INK, 18, 193, W - 36, 30, Enum.TextXAlignment.Center, true, 7)
local clock = text(card, "", Enum.Font.FredokaOne, 13, DIM, 18, 225, W - 36, 16, Enum.TextXAlignment.Center)
local yline = text(card, "", Enum.Font.FredokaOne, 12, DIM, 18, 243, W - 36, 14, Enum.TextXAlignment.Center, true, 6)

local data, busy, boardOpen = nil, false, nil
-- THE ANSWER BUTTON GOES ONCE YOU HAVE ANSWERED THAT BOARD TODAY. Shannon: "when I log on again, the E button is still by
-- the chalk boards to answer the question; that should go away permanently when player has answered the questions for
-- the day, the interact button should no longer be there." Each board's prompt is switched off on this screen once its
-- question is answered - the server's answered-today rides on the save, so it holds across visits - and comes back when
-- the next question goes up at 6pm Eastern ("newday", and a look every two minutes in case that was missed).
local doneToday = {}
local function applyPrompts()
	for _, d in ipairs(F:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Name == "QuestionPrompt" then d.Enabled = not doneToday[d:GetAttribute("BoardId") or "forest"] end
	end
end
local refreshing = false
local function refreshPrompts()
	if refreshing then return end
	refreshing = true
	local ok, st = pcall(function() return action:InvokeServer("status") end)
	refreshing = false
	if not (ok and type(st) == "table" and st.ok) then return end
	doneToday = {forest = st.forest ~= "open", poste = st.poste ~= "open"}
	applyPrompts()
end
-- AND THE MOMENT A BOARD'S BUTTON IS ABOUT TO SHOW, it is checked first (Shannon, after the first go: "I already answered
-- the question of the day, but I still get the button when I walk next to the chalk board"): answered today and it is
-- switched off on the spot; not known yet and your save has loaded, the server is asked, and it goes if it should.
PPS.PromptShown:Connect(function(prompt)
	if prompt.Name ~= "QuestionPrompt" or not prompt:IsDescendantOf(F) then return end
	if doneToday[prompt:GetAttribute("BoardId") or "forest"] then prompt.Enabled = false return end
	if player:GetAttribute("SaveLoaded") then task.spawn(refreshPrompts) end
end)
F.DescendantAdded:Connect(function(d)                         -- a board streaming back in brings a fresh prompt
	if d:IsA("ProximityPrompt") and d.Name == "QuestionPrompt" then task.defer(applyPrompts) end
end)
task.spawn(function()
	local t0 = os.clock()
	while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 40 do task.wait(0.5) end
	refreshPrompts()
	while true do task.wait(120); refreshPrompts() end
end)
local function styleButtons(enabled)
	for _, e in ipairs(buttons) do
		e.btn.AutoButtonColor = enabled
		e.btn.BackgroundColor3 = NAVY2; e.stroke.Color = C(110, 96, 140)
		e.btn.TextColor3 = enabled and CREAM or DIM
	end
end
local function fmtLeft(secs)
	secs = math.max(0, math.floor(secs))
	local h, m = math.floor(secs / 3600), math.floor((secs % 3600) / 60)
	if h > 0 then return string.format("%dh %02dm", h, m) end
	return string.format("%dm %02ds", m, secs % 60)
end
local function render()
	if not data then return end
	title.Text = "Question of the Day " .. (NUMBER[data.board] or "")
	kind.Text = (data.kind or "") ~= "" and ("Today: " .. string.lower(data.kind)) or ""
	qText.Text = data.q or ""
	for i, e in ipairs(buttons) do
		local opt = data.options and data.options[i]
		e.btn.Visible = opt ~= nil
		e.btn.Text = opt or ""
	end
	styleButtons(data.state == "open")
	if data.state == "open" then
		status.TextColor3 = INK
		status.Text = string.format("One try a day. Right answers win %d acorns and a place in tonight's draw for %d acorns and the Wise Squirrel badge.", data.reward or 25, data.prize or 200)
	elseif data.state == "right" then
		status.TextColor3 = C(150, 230, 160)
		status.Text = "You got this one right! You're in tonight's draw for the Wise Squirrel badge."
	else
		status.TextColor3 = C(240, 170, 160)
		status.Text = "Not this time. A new question goes up at 6pm Eastern."
	end
	if (data.yq or "") ~= "" then
		yline.Text = "Yesterday: " .. data.yq .. "  Answer: " .. (data.ya or "") .. (data.yw and ("  -  Wise Squirrel: " .. data.yw) or "")
	else
		yline.Text = ""
	end
end
local function load(b)
	local ok, res = pcall(function() return action:InvokeServer("get", b) end)
	if ok and type(res) == "table" and res.ok then data = res; render() end
	return data
end
local function boardFace(b)
	local m = F:FindFirstChild("Board_" .. tostring(b))
	return m and m:FindFirstChild("Face")
end
local function setOpen(on, b)
	gui.Enabled = on
	boardOpen = on and b or nil
	if on then
		fit()
		data = nil
		title.Text = "Question of the Day " .. (NUMBER[b] or ""); kind.Text = ""
		qText.Text = "..."; status.Text = ""; clock.Text = ""; yline.Text = ""
		for _, e in ipairs(buttons) do e.btn.Text = "" end
		task.spawn(load, b)
	end
end
close.MouseButton1Click:Connect(function() setOpen(false) end)
for pos, e in ipairs(buttons) do
	e.btn.MouseButton1Click:Connect(function()
		if busy or not data or data.state ~= "open" then return end
		busy = true
		styleButtons(false)
		e.btn.BackgroundColor3 = C(90, 80, 120)
		status.TextColor3 = DIM; status.Text = "Posting your answer..."
		local ok, res = pcall(function() return action:InvokeServer("answer", data.board, data.round, pos) end)
		busy = false
		if ok and type(res) == "table" and res.ok then
			data.state = res.right and "right" or "wrong"
			doneToday[data.board] = true; applyPrompts()                -- answered: this board's button goes for today
			render()
			e.btn.BackgroundColor3 = res.right and GREEN or RED
			e.stroke.Color = res.right and C(150, 230, 160) or C(240, 170, 160)
			e.btn.TextColor3 = CREAM
			if res.right then
				status.Text = string.format("Right! +%d acorns. You're in tonight's draw for %d acorns and the Wise Squirrel badge.", res.reward or 25, data.prize or 200)
				sound("rbxassetid://1845415163", 0.5)
			end
		elseif ok and type(res) == "table" and (res.why == "closed" or res.why == "already") then
			if res.why == "already" then doneToday[data.board] = true; applyPrompts() end
			status.Text = res.why == "closed" and "Time's up - a new question just went up!" or "You've already answered this one today."
			task.delay(1.2, function() if boardOpen then load(boardOpen) end end)
		else
			status.Text = "The chalk snapped - try again in a moment."
			styleButtons(true)
		end
	end)
end
-- the countdown, and walking away closes the card
task.spawn(function()
	while true do
		if gui.Enabled and boardOpen then
			if data and data.closes then clock.Text = "Closes in " .. fmtLeft(data.closes - workspace:GetServerTimeNow()) .. "  (6pm Eastern)" end
			local face = boardFace(boardOpen)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if face and hrp and (hrp.Position - face.Position).Magnitude > (F:GetAttribute("CloseDistance") or 16) then setOpen(false) end
		end
		task.wait(0.5)
	end
end)
PPS.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "QuestionPrompt" and prompt:IsDescendantOf(F) then setOpen(true, prompt:GetAttribute("BoardId") or "forest") end
end)

-- ---------------------------------------------------------------- news ----
local news = Instance.new("ScreenGui"); news.Name = "QuestionNews"; news.ResetOnSpawn = false; news.IgnoreGuiInset = true; news.DisplayOrder = 24; news.Parent = pg
local banner = Instance.new("Frame"); banner.AnchorPoint = Vector2.new(0.5, 0); banner.Position = UDim2.new(0.5, 0, 0, -140); banner.Size = UDim2.new(0.9, 0, 0, 84)
banner.BackgroundColor3 = NAVY; banner.BackgroundTransparency = 0.05; banner.Visible = false; banner.Parent = news
corner(banner, UDim.new(0, 16)); stroke(banner, GOLD, 3)
local bsz = Instance.new("UISizeConstraint"); bsz.MaxSize = Vector2.new(560, 84); bsz.Parent = banner
local b1 = Instance.new("TextLabel"); b1.BackgroundTransparency = 1; b1.Position = UDim2.new(0, 16, 0, 10); b1.Size = UDim2.new(1, -32, 0, 32)
b1.Font = Enum.Font.FredokaOne; b1.TextScaled = true; b1.TextColor3 = INK; b1.Text = ""; b1.Parent = banner
local b1c = Instance.new("UITextSizeConstraint"); b1c.MaxTextSize = 28; b1c.Parent = b1
local b2 = Instance.new("TextLabel"); b2.BackgroundTransparency = 1; b2.Position = UDim2.new(0, 16, 0, 44); b2.Size = UDim2.new(1, -32, 0, 30)
b2.Font = Enum.Font.FredokaOne; b2.TextScaled = true; b2.TextColor3 = CREAM; b2.Text = ""; b2.TextWrapped = true; b2.Parent = banner
local b2c = Instance.new("UITextSizeConstraint"); b2c.MaxTextSize = 17; b2c.Parent = b2
local shownAt = 0
local function announce(t1, t2, secs)
	b1.Text = t1; b2.Text = t2 or ""
	banner.Visible = true; banner.Position = UDim2.new(0.5, 0, 0, -140)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 128)}):Play()
	local mine = os.clock(); shownAt = mine
	task.delay(secs or 7, function()
		if shownAt ~= mine then return end
		local t = TweenService:Create(banner, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, -140)}); t:Play()
		t.Completed:Connect(function() if shownAt == mine then banner.Visible = false end end)
	end)
end
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118); toast.Size = UDim2.fromOffset(460, 44)
toast.BackgroundColor3 = NAVY; toast.BackgroundTransparency = 0.1; toast.Font = Enum.Font.FredokaOne; toast.TextSize = 17; toast.TextColor3 = INK; toast.TextWrapped = true
toast.Text = ""; toast.Visible = false; toast.Parent = news
corner(toast, UDim.new(0, 14)); stroke(toast, GOLD, 2)
local toastAt = 0
-- ON A PHONE the note finds a clear place (Shannon, Sep 26: "it should be higher so it doesn't collide with the start the
-- race"; "Ideally on that phone, nothing should be overlapping. At any time."): from just under Roblox's top bar downwards,
-- the first spot clear of everything else showing; computers keep it where it always was
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local PHONE = UIS.TouchEnabled and not UIS.MouseEnabled
if PHONE then
	local tp = Instance.new("UIPadding"); tp.PaddingLeft = UDim.new(0, 14); tp.PaddingRight = UDim.new(0, 14)
	tp.PaddingTop = UDim.new(0, 7); tp.PaddingBottom = UDim.new(0, 7); tp.Parent = toast
end
local function screenRect(o)
	local sg = o:FindFirstAncestorOfClass("ScreenGui")
	local inset = (sg and not sg.IgnoreGuiInset) and GuiService:GetGuiInset() or Vector2.zero
	local p = o.AbsolutePosition + inset
	return {p.X, p.Y, p.X + o.AbsoluteSize.X, p.Y + o.AbsoluteSize.Y}
end
local function othersShown()
	local out, vs = {}, workspace.CurrentCamera.ViewportSize
	for _, sg in ipairs(pg:GetChildren()) do
		if sg:IsA("ScreenGui") and sg.Enabled then
			for _, o in ipairs(sg:GetDescendants()) do
				if o:IsA("GuiObject") and o ~= toast and not o:IsDescendantOf(toast) and o.Visible and o.AbsoluteSize.X > 4 and o.AbsoluteSize.Y > 4
					and o.AbsoluteSize.X < vs.X * 0.9 and o.AbsoluteSize.Y < vs.Y * 0.9 then
					local seen = o.BackgroundTransparency < 0.9
						or ((o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and o.TextTransparency < 0.9)
						or ((o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and o.ImageTransparency < 0.9)
					local a = o.Parent
					while seen and a and a ~= sg do
						if a:IsA("GuiObject") and not a.Visible then seen = false end
						a = a.Parent
					end
					if seen then table.insert(out, screenRect(o)) end
				end
			end
		end
	end
	local tb = GuiService.TopbarInset
	table.insert(out, {0, 0, tb.Min.X, tb.Max.Y})                   -- Roblox's own buttons, top left
	return out
end
local function placeToast()
	local vs = workspace.CurrentCamera.ViewportSize
	local w = math.min(460, vs.X - 40)
	toast.Size = UDim2.fromOffset(w, 0); toast.AutomaticSize = Enum.AutomaticSize.Y
	task.wait()                                                      -- (let it measure its wrapped text)
	local h = math.max(toast.AbsoluteSize.Y, 30)
	local rects = othersShown()
	local x0 = (vs.X - w) / 2
	for y = GuiService.TopbarInset.Max.Y + 6, vs.Y * 0.5, 4 do
		local r = {x0 - 3, y - 3, x0 + w + 3, y + h + 3}
		local clear = true
		for _, q in ipairs(rects) do
			if r[1] < q[3] and r[3] > q[1] and r[2] < q[4] and r[4] > q[2] then clear = false break end
		end
		if clear then toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0, y) return end
	end
	toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118)   -- nowhere clear: where it always was
end
local function say(t, secs)
	toast.Text = t
	local mine = os.clock(); toastAt = mine
	if PHONE then
		task.spawn(function() placeToast(); if toastAt == mine then toast.Visible = true end end)
	else
		toast.Visible = true
	end
	task.delay(secs or 6, function() if toastAt == mine then toast.Visible = false end end)
end
local function chat(t)
	pcall(function()
		local ch = game:GetService("TextChatService"):WaitForChild("TextChannels", 3):WaitForChild("RBXGeneral", 3)
		ch:DisplaySystemMessage(t)
	end)
end
ev.OnClientEvent:Connect(function(what, info)
	info = type(info) == "table" and info or {}
	if what == "drawn" then
		local a = type(info.answers) == "table" and info.answers or {}
		if info.name then
			announce("Today's Wise Squirrel: " .. tostring(info.name) .. "!", "The answers were: " .. tostring(a.forest or "") .. "  and  " .. tostring(a.poste or ""), 8)
			chat(string.format("%s is today's Wise Squirrel! (%d right answers were in the draw)", tostring(info.name), info.count or 0))
		else
			chat("Nobody got a Question of the Day right today. New ones are up!")
		end
		if gui.Enabled and boardOpen then task.spawn(load, boardOpen) end
	elseif what == "prize" then
		task.delay(2, function()
			announce("You're the Wise Squirrel!", string.format("Your right answer was drawn: +%d acorns and the Wise Squirrel badge. Tap your title to see it.", info.prize or 200), 10)
			sound("rbxassetid://1845415163", 0.7)
		end)
	elseif what == "newday" then
		doneToday = {}; applyPrompts(); task.delay(5, refreshPrompts)   -- new questions: the buttons come back
		if gui.Enabled and boardOpen then task.spawn(load, boardOpen) end
		task.delay(3, function() say("New Questions of the Day are up!") end)
	end
end)

-- A LITTLE ARROW TO THE BOARD after the reminder (Shannon, Sep 26: "put a small glowy pointy arrow at the chalkboard so
-- people know to go up to it and interact with it" - "above it from the right pointing down", "a small one"): gold with a
-- soft glow, angled down at the board from its top right corner, bobbing gently; on this screen only, and gone once you
-- reach the board or open it (or after two minutes)
local arrowGui
-- THE ARROW IS REAL NEON: thin Neon pieces in the world rather than a flat label, so it glows like the neon sign in Shannon's
-- example ("like this shape, but neon green and pointing down not up and the tail not quite that long") and has no seams -
-- a flat label's see-through glow could only be built in sections ("why is it made up of little splotchy sections ... white
-- in between"). Two thin strokes side by side come in from the right and arc down, drawing together into an open
-- two-armed point aimed at the board; round joints; darker neon green (Shannon: "it should be darker green neon"); the whole
-- arrow keeps turning to face your camera, bobbing gently. On this screen only.
local function pointAt(b)
	if arrowGui then arrowGui:Destroy(); arrowGui = nil end
	local m = F:FindFirstChild("Board_" .. tostring(b))
	local face = m and m:FindFirstChild("Face")
	if not face then return end
	local right = -face.CFrame.RightVector                                    -- the right as you stand facing the board
	right = Vector3.new(right.X, 0, right.Z).Unit
	local pos = face.Position + right * 0.55 + Vector3.new(0, face.Size.Y / 2 + 2.7, 0)   -- over the middle of the board, a touch right
	local NEON = C(45, 215, 85)
	local model = Instance.new("Model"); model.Name = "BoardArrow"
	local SIZE = 2.6                                                         -- studs across
	-- the shape in the arrow's own flat frame: u to your right, v up (from the drawing: 0..1 across, 0..1 down)
	local P0, P1, P2 = Vector2.new(0.9, 0.3), Vector2.new(0.64, 0.24), Vector2.new(0.4, 0.72)
	local function at(s) local w = 1 - s; return P0 * (w * w) + P1 * (2 * w * s) + P2 * (s * s) end
	local function tangent(s) local d = (P1 - P0) * (2 * (1 - s)) + (P2 - P1) * (2 * s); return d.Unit end
	local function local3(p) return Vector3.new(-(p.X - 0.5) * SIZE, (0.5 - p.Y) * SIZE, 0) end   -- (-X: the model faces the camera)
	local function neon(shape, size, cf)
		local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.CFrame = cf; p.Material = Enum.Material.Neon; p.Color = NEON
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false; p.Parent = model
		return p
	end
	local THICK = 0.075
	local function stroke(pts)
		for i = 1, #pts - 1 do
			local a3, b3 = local3(pts[i]), local3(pts[i + 1])
			local len = (b3 - a3).Magnitude
			if len > 1e-3 then
				neon(Enum.PartType.Cylinder, Vector3.new(len, THICK, THICK), CFrame.lookAt((a3 + b3) / 2, b3) * CFrame.Angles(0, math.rad(90), 0))
			end
			neon(Enum.PartType.Ball, Vector3.new(THICK, THICK, THICK), CFrame.new(b3))       -- a round joint
		end
		neon(Enum.PartType.Ball, Vector3.new(THICK, THICK, THICK), CFrame.new(local3(pts[1])))
	end
	-- the two strokes of the shaft, drawing together toward the point (one starts a touch later: drawn by hand)
	local N = 16
	for _, side in ipairs({1, -1}) do
		local pts = {}
		local from = (side == 1) and 0 or 0.07
		for i = 0, N do
			local s = from + (1 - from) * i / N
			local d = tangent(s)
			local n = Vector2.new(-d.Y, d.X)
			pts[#pts + 1] = at(s) + n * (side * 0.026 * (1 - 0.8 * s))
		end
		stroke(pts)
	end
	-- the open point: two straight arms back from the tip
	local e = tangent(1)
	local tip = P2 + e * 0.02
	local function turn(v, deg)
		local r = math.rad(deg)
		return Vector2.new(v.X * math.cos(r) - v.Y * math.sin(r), v.X * math.sin(r) + v.Y * math.cos(r))
	end
	for _, side in ipairs({1, -1}) do
		local d = turn(-e, 40 * side)
		stroke({tip, tip + d * 0.22})
	end
	-- a green light on the board below it
	local core = Instance.new("Part"); core.Name = "Light"; core.Size = Vector3.new(0.1, 0.1, 0.1); core.Transparency = 1; core.Anchored = true
	core.CanCollide = false; core.CanQuery = false; core.CanTouch = false; core.CFrame = CFrame.new(local3(P2)); core.Parent = model
	local lamp = Instance.new("PointLight"); lamp.Color = NEON; lamp.Brightness = 2.2; lamp.Range = 8; lamp.Shadows = false; lamp.Parent = core
	model.WorldPivot = CFrame.new()
	model.Parent = workspace.CurrentCamera                                   -- (this screen's alone)
	arrowGui = model
	local cam = workspace.CurrentCamera
	local t0 = os.clock()
	local conn
	conn = game:GetService("RunService").RenderStepped:Connect(function()
		if arrowGui ~= model or not model.Parent then conn:Disconnect() return end
		local here = pos + Vector3.new(0, 0.18 * math.sin((os.clock() - t0) * 3.4), 0)     -- a gentle bob
		local look = cam.CFrame.Position
		if (look - here).Magnitude < 0.5 then return end
		model:PivotTo(CFrame.lookAt(here, look))                               -- always facing you
	end)
	task.spawn(function()
		while arrowGui == model do
			task.wait(0.4)
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if (hrp and (hrp.Position - face.Position).Magnitude < 9) or boardOpen or os.clock() - t0 > 120 then
				if arrowGui == model then model:Destroy(); arrowGui = nil end
			end
		end
	end)
end

-- a reminder once a visit: the forest board first; La Poste's once the bridge is open to you
task.spawn(function()
	local t0 = os.clock()
	while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 40 do task.wait(0.5) end
	task.wait(12)
	-- not while the daily acorns card is up: after it's collected (Shannon: "maybe it only needs to pop up after you
	-- collect the acorn"), once the acorns have flown into the purse
	local dg = pg:FindFirstChild("DailyGui")
	local card = dg and dg:FindFirstChild("DailyCard")
	local t1 = os.clock()
	while card and card.Visible and os.clock() - t1 < 300 do task.wait(0.5) end
	if os.clock() - t1 > 0.6 then task.wait(2.5) end
	local ok, st = pcall(function() return action:InvokeServer("status") end)
	if not (ok and type(st) == "table" and st.ok) then return end
	local need = (workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need")) or 10
	local canPoste = (tonumber(player:GetAttribute("Found_forest")) or 0) >= need
	if st.forest == "open" then
		say(string.format("Question of the Day #1 is at the forest entrance: answer it for %d acorns!", st.reward or 25), 7)
		pointAt("forest")
	elseif st.poste == "open" and canPoste then
		say(string.format("Question of the Day #2 is at La Poste on the Rue de Noisette: %d more acorns!", st.reward or 25), 7)
		pointAt("poste")
	end
end)
]==]
	local s = Instance.new("Script"); s.Name = "QuestionServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "QuestionClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print("DailyQuestion: installed - board #1 at the forest entrance, board #2 at LA POSTE's corner")
	return F
end

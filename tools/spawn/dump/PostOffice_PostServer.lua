-- PostServer: the letters (send / status / read) and the dev desk (list / reply); the DataStore, the text filter, the purse
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local PO = script.Parent
local action = PO:WaitForChild("PostAction")
local notify = PO:WaitForChild("PostNotify")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local store
do
	local ok, err = pcall(function() store = DataStoreService:GetDataStore("PostOffice_v1") end)
	if not ok then warn("PostOffice: no store (" .. tostring(err) .. "); letters live in memory this session") end
end
local records = {}                                            -- uid -> record: {letter = {text, t, name, user}, reply = {text, t, by}, state}
local pending                                                 -- list of uids with a letter waiting (mirror of the "pending" key)
local storeDown = false

local function devs()
	local set = {}
	for id in string.gmatch(tostring(PO:GetAttribute("DevIds") or ""), "%d+") do set[tonumber(id)] = true end
	return set
end
local function isDev(player) return devs()[player.UserId] == true end
local function firstDev() for id in pairs(devs()) do return id end return 0 end

local function load(uid)
	if records[uid] then return records[uid] end
	local rec
	if store then
		local ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
		if ok then if type(data) == "table" then rec = data end
		else if not storeDown then warn("PostOffice: could not read the store (" .. tostring(data) .. ")"); storeDown = true end end
	end
	rec = rec or {}
	records[uid] = rec
	return rec
end
-- A store call, tried up to three times a second apart; true once it goes through. In Studio with API access off the
-- store refuses everything and the records simply live in memory for the session, so there it counts as done.
local function tryStore(what, fn)
	if not store then return RunService:IsStudio() end
	for i = 1, 3 do
		local ok, err = pcall(fn)
		if ok then return true end
		if RunService:IsStudio() then return true end
		warn("PostOffice: could not " .. what .. " (" .. tostring(err) .. ")" .. (i < 3 and " - trying again" or " - giving up"))
		if i < 3 then task.wait(1) end
	end
	return false
end
local function save(uid, rec)
	records[uid] = rec
	return tryStore("save u" .. uid, function() store:SetAsync("u" .. uid, rec) end)
end
-- the waiting list: this server's copy (read from the store the first time) ...
local function withPending()
	if pending == nil then
		pending = {}
		if store then
			local ok, data = pcall(function() return store:GetAsync("pending") end)
			if ok and type(data) == "table" then pending = data end
		end
	end
	return pending
end
-- ... and a change to it, made to the copy and to the store; true if the store took it
local function updatePending(fn)
	pending = fn(withPending()) or pending
	return tryStore("update the waiting list", function()
		store:UpdateAsync("pending", function(old) return fn(type(old) == "table" and old or {}) end)
	end)
end
local function addPending(uid) return function(list) for _, u in ipairs(list) do if u == uid then return list end end; table.insert(list, uid); return list end end
local function dropPending(uid) return function(list) local out = {} for _, u in ipairs(list) do if u ~= uid then table.insert(out, u) end end return out end end
-- FRESH READS. A server used to read a record or the waiting list once and trust its copy from then on, so a letter
-- posted in another server never showed on this server's dev desk, and a reply written in another server never
-- reached someone whose record this server had already read (even after they left and came back to it). Now the
-- box, the desk and a reply read the store each time; the copy is only the fallback when the store does not answer.
local function fresh(uid)
	if store then
		local ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
		if ok and type(data) == "table" then records[uid] = data end
	end
	return load(uid)
end
local function freshPending()
	if store then
		local ok, data = pcall(function() return store:GetAsync("pending") end)
		if ok and type(data) == "table" then pending = data end
	end
	return withPending()
end

-- Roblox's filter. For ONE known reader when that reader is in this server; otherwise - the usual case: the dev is
-- rarely in the writer's server, and a writer is rarely still here when the dev answers - the version that is safe
-- for anyone to read. (The first version always filtered for the reader, and Roblox only does that for someone
-- connected to the same server, so on the live game every letter came back "could not read that" - Shannon, on her
-- second account on her phone: "I tried to send it and it would not send".) The raw text is kept only in Studio,
-- where the filter will not answer.
local function filtered(text, fromUid, toUid)
	local ok, res = pcall(function()
		local obj = TextService:FilterStringAsync(text, fromUid)
		if toUid and Players:GetPlayerByUserId(toUid) then
			local ok2, one = pcall(function() return obj:GetNonChatStringForUserAsync(toUid) end)
			if ok2 then return one end
		end
		return obj:GetNonChatStringForBroadcastAsync()
	end)
	if ok then return res end
	if RunService:IsStudio() then return text end
	warn("PostOffice: the filter did not answer (" .. tostring(res) .. ")")
	return nil
end
local function trimmed(text)
	text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
	return text
end
local function view(player, rec)
	return {
		price = PO:GetAttribute("Price") or 30, max = PO:GetAttribute("MaxChars") or 240, open = PO:GetAttribute("Open") ~= false,
		state = rec.state, letter = rec.letter and rec.letter.text, sentAt = rec.letter and rec.letter.t,
		reply = rec.reply and rec.reply.text, repliedAt = rec.reply and rec.reply.t, by = rec.reply and rec.reply.by,
		dev = isDev(player), acorns = player:GetAttribute("Acorns") or 0,
	}
end
-- a dev in this server hears about a new letter at once; one elsewhere hears the moment she next joins (onJoin)
local function tellDevs(from)
	for _, p in ipairs(Players:GetPlayers()) do
		if isDev(p) and p ~= from then
			p:SetAttribute("LettersWaiting", (p:GetAttribute("LettersWaiting") or 0) + 1)
			notify:FireClient(p, "A new letter from " .. from.DisplayName .. " is waiting at La Poste!")
		end
	end
end
local busy = {}
local function handle(player, kind, a, b)
	local uid = player.UserId
	if kind == "status" then return true, view(player, fresh(uid)) end
	if kind == "send" then
		if PO:GetAttribute("Open") == false then return false, "the post office is closed" end
		if type(a) ~= "string" then return false, "write something first" end
		local text = trimmed(a)
		local max = PO:GetAttribute("MaxChars") or 240
		if #text == 0 then return false, "write something first" end
		if #text > max then return false, "too long - " .. max .. " letters at most" end
		local rec = load(uid)
		if rec.state == "sent" then return false, "your letter is still with the dev" end
		local price = PO:GetAttribute("Price") or 30
		local have = player:GetAttribute("Acorns") or 0
		if have < price then return false, "not enough acorns" end
		local clean = filtered(text, uid, firstDev())
		if not clean then return false, "the post office could not read that; try again in a moment" end
		-- NOTHING IS CHARGED UNTIL THE LETTER IS SAFE IN THE STORE. Shannon: "I just want to make sure I get messages if any
		-- user sends one". It used to take the acorns first and save after, ignoring a failed save, so a hiccup in the
		-- store could lose a letter its writer had paid for and been told was posted. Now: onto the waiting list first (a
		-- name on the list with no letter behind it is simply skipped by the desk), then the letter, each tried three
		-- times; if either fails the writer is told to try again and nothing is taken.
		local SORRY = "the post office could not send that just now - try again in a minute (no acorns taken)"
		if not updatePending(addPending(uid)) then return false, SORRY end
		local before = {letter = rec.letter, reply = rec.reply, state = rec.state}
		rec.letter = {text = clean, t = os.time(), name = player.DisplayName, user = player.Name}
		rec.reply = nil
		rec.state = "sent"
		if not save(uid, rec) then
			rec.letter, rec.reply, rec.state = before.letter, before.reply, before.state
			return false, SORRY
		end
		awardAcorns:Fire(player, -price)                       -- the stamp: a negative award, same ledger as every spend
		player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or have) - price)
		player:SetAttribute("MailWaiting", false)
		print(string.format("PostOffice: %s posted a letter (%d chars)", player.Name, #clean))
		tellDevs(player)
		return true, view(player, rec)
	end
	if kind == "read" then
		local rec = load(uid)
		if rec.state == "answered" then rec.state = "read"; save(uid, rec) end
		player:SetAttribute("MailWaiting", false)
		return true, view(player, rec)
	end
	if not isDev(player) then return false, "not for you" end
	if kind == "list" then
		local out = {}
		for _, u in ipairs(freshPending()) do
			local rec = fresh(u)
			if rec.state == "sent" and rec.letter then
				table.insert(out, {uid = u, name = rec.letter.name or "?", user = rec.letter.user or "?", text = rec.letter.text, t = rec.letter.t})
			end
			if #out >= 60 then break end
		end
		table.sort(out, function(x, y) return (x.t or 0) < (y.t or 0) end)
		player:SetAttribute("LettersWaiting", #out)
		return true, out
	end
	if kind == "reply" then
		local toUid, text = tonumber(a), (type(b) == "string") and trimmed(b) or ""
		if not toUid then return false, "who to?" end
		if #text == 0 then return false, "write the reply first" end
		if #text > 1000 then return false, "too long" end
		local rec = fresh(toUid)
		if not rec.letter then return false, "no letter from them" end
		local clean = filtered(text, uid, toUid)
		if not clean then return false, "the filter did not answer; try again" end
		local before = {reply = rec.reply, state = rec.state}
		rec.reply = {text = clean, t = os.time(), by = player.DisplayName}
		rec.state = "answered"
		if not save(toUid, rec) then
			rec.reply, rec.state = before.reply, before.state
			return false, "the store did not take that - try again in a minute"
		end
		updatePending(dropPending(toUid))                    -- if this fails the desk skips it anyway: it is answered
		player:SetAttribute("LettersWaiting", math.max(0, (player:GetAttribute("LettersWaiting") or 1) - 1))
		local them = Players:GetPlayerByUserId(toUid)
		if them then them:SetAttribute("MailWaiting", true); notify:FireClient(them, "There is a letter for you at the post office!") end
		print(string.format("PostOffice: %s replied to u%d", player.Name, toUid))
		return true
	end
	return false, "no such thing"
end
action.OnServerInvoke = function(player, kind, a, b)
	if busy[player] then return false, "one thing at a time" end
	busy[player] = true
	local ok, res, extra = pcall(handle, player, kind, a, b)
	busy[player] = nil
	if not ok then warn("PostOffice: " .. tostring(kind) .. " failed - " .. tostring(res)); return false, "the post office is not answering" end
	return res, extra
end
local function onJoin(player)
	task.spawn(function()
		local rec = fresh(player.UserId)
		if rec.state == "answered" then
			player:SetAttribute("MailWaiting", true)
			task.wait(6)
			if player.Parent then notify:FireClient(player, "There is a letter for you at the post office!") end
		end
	end)
	-- the dev hears how many letters are waiting for her, the moment she joins
	if isDev(player) then
		task.spawn(function()
			local n = 0
			for i, u in ipairs(freshPending()) do
				if i > 40 then break end
				local r = fresh(u)
				if r.state == "sent" and r.letter then n += 1 end
			end
			player:SetAttribute("LettersWaiting", n)
			if n > 0 then
				task.wait(8)
				if player.Parent then notify:FireClient(player, n == 1 and "A letter is waiting for you at La Poste!" or (n .. " letters are waiting for you at La Poste!")) end
			end
		end)
	end
end
Players.PlayerAdded:Connect(onJoin)
for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; records[p.UserId] = nil end)   -- read afresh if they come back
print("PostOffice: open - " .. tostring(PO:GetAttribute("Price")) .. " acorns a letter")

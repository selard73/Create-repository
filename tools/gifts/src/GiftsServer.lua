-- GiftsServer (workspace.Gifts): the squirrel friends' gifts (Shannon, Oct 10 2026). Three gifts a player can earn:
--   like + favourite + notifications -> the Backpack (on trust: Roblox offers no way to check a like, a favourite or
--     the notification switch for an experience; the client shows Roblox's own notifications prompt and asks for the
--     thumbs-up and the star in the Roblox menu, then the player claims once);
--   join the 1001 Squirrels community -> CommunityAcorns (checked here: GroupService:GetGroupsAsync, fresh each time);
--   invite a friend -> DOUBLE ACORNS for both while they play in the same server (the friend's join carries
--     Player:GetJoinData().ReferredByPlayerId; every acorn gain under BoostMaxGain is paid again - the Robux acorn
--     packs start at 150 and are never doubled; a single in-game gain of 150 or more is not doubled either).
-- Claims persist through the AwardItems ledger (Item_gift_like, Item_gift_community, Item_gift_invites on the inviter,
-- Item_ref_<inviterId> on the invitee so a friend counts once). Attributes on the folder: GroupId, CommunityAcorns,
-- BoostMaxGain, LikeReward ("backpack"), BoostOn, PopupDelay / FirstFind / AutoPopup (the client's).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")
local F = script.Parent
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local action = RS:WaitForChild("GiftsAction")
local ev = RS:WaitForChild("GiftsEvent")
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function str(name, d) local v = F:GetAttribute(name) return type(v) == "string" and v or d end
local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end
local function giveAcorns(p, n)
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + n)
	awardAcorns:Fire(p, n, "gift")   -- (the third argument marks our own payments; SquirrelSetup's handler ignores it)
end
local function loaded(p) return p:GetAttribute("SaveLoaded") == true end

-- ---------- the state a client sees ----------
local function state(p)
	return {
		like = item(p, "gift_like") > 0, community = item(p, "gift_community") > 0, invites = item(p, "gift_invites"),
		backpack = item(p, str("LikeReward", "backpack")) > 0, communityAcorns = num("CommunityAcorns", 150),
		boosted = p:GetAttribute("AcornBoost") == 2, boostWith = p:GetAttribute("BoostWith") or "",
	}
end

-- ---------- the community ----------
local function inCommunity(p)
	local gid = num("GroupId", 0)
	if gid <= 0 then return false, "no community set" end
	local ok, groups = pcall(function() return GroupService:GetGroupsAsync(p.UserId) end)
	if ok and type(groups) == "table" then
		for _, g in ipairs(groups) do if tonumber(g.Id) == gid then return true end end
		return false
	end
	local ok2, r = pcall(function() return p:IsInGroupAsync(gid) end)   -- (cached per server; the fallback only)
	return ok2 and r == true
end

-- ---------- the counter (one request at a time per player, a breath between them) ----------
local lastAsk, busy = {}, {}
local function settled(p, patch)   -- the state once the ledger's attribute writes have landed (they may be deferred a frame)
	task.wait()
	local st = state(p)
	for k, v in pairs(patch or {}) do st[k] = v end
	return st
end
action.OnServerInvoke = function(p, what)
	if typeof(p) ~= "Instance" or not p:IsA("Player") then return false, "?" end
	if not loaded(p) then return false, "loading" end
	if what == "state" then return true, state(p) end
	local now = os.clock()
	if busy[p] or (lastAsk[p] and now - lastAsk[p] < 1.5) then return false, "a moment" end
	lastAsk[p] = now; busy[p] = true
	local ok, a, b = pcall(function()
		if what == "claimLike" then
			if item(p, "gift_like") > 0 then return true, state(p) end
			local reward = str("LikeReward", "backpack")
			if reward ~= "" and item(p, reward) <= 0 then awardItems:Fire(p, reward, 1) end
			awardItems:Fire(p, "gift_like", 1)
			print(string.format("Gifts: %s claimed the like gift (%s)", p.Name, reward))
			return true, settled(p, {like = true, backpack = reward ~= "" or nil})
		elseif what == "checkCommunity" then
			if item(p, "gift_community") > 0 then return true, state(p) end
			local member, why = inCommunity(p)
			if p.Parent ~= Players then return false, "gone" end
			if item(p, "gift_community") > 0 then return true, state(p) end
			if not member then return false, why or "not yet" end
			giveAcorns(p, num("CommunityAcorns", 150))
			awardItems:Fire(p, "gift_community", 1)
			print(string.format("Gifts: %s joined the community (+%d acorns)", p.Name, num("CommunityAcorns", 150)))
			return true, settled(p, {community = true})
		end
		return false, "?"
	end)
	busy[p] = nil
	if not ok then warn("Gifts: " .. tostring(a)) return false, "later" end
	return a, b
end
Players.PlayerRemoving:Connect(function(p) lastAsk[p] = nil; busy[p] = nil end)

-- ---------- friends who came on an invite: double acorns while both are here ----------
local partners = {}   -- [player] = {[other] = true}
local function refresh(p)
	if p.Parent ~= Players then return end
	local with
	for o in pairs(partners[p] or {}) do if o.Parent == Players then with = o break end end
	local on = with ~= nil and F:GetAttribute("BoostOn") ~= false
	local was = p:GetAttribute("AcornBoost") == 2
	p:SetAttribute("AcornBoost", on and 2 or nil)
	p:SetAttribute("BoostWith", on and with.Name or nil)
	if on and not was then ev:FireClient(p, "boost", with.Name) elseif was and not on then ev:FireClient(p, "boostoff") end
end
local function link(a, b)
	partners[a] = partners[a] or {}; partners[b] = partners[b] or {}
	partners[a][b] = true; partners[b][a] = true
	refresh(a); refresh(b)
end
local function onJoin(p)
	local refId
	for _ = 1, 10 do   -- (the invite's data can take a few seconds to arrive, as the launch data does)
		local ok, jd = pcall(function() return p:GetJoinData() end)
		refId = ok and type(jd) == "table" and tonumber(jd.ReferredByPlayerId) or nil
		if refId and refId ~= 0 then break end
		if p.Parent ~= Players then return end
		task.wait(1)
	end
	if not (refId and refId ~= 0 and refId ~= p.UserId) then return end
	local t0 = os.clock()
	while p.Parent == Players and not loaded(p) and os.clock() - t0 < 30 do task.wait(0.5) end
	if p.Parent ~= Players then return end
	local inviter = Players:GetPlayerByUserId(refId)
	if loaded(p) and item(p, "ref_" .. refId) == 0 then   -- this friend counts once for that inviter (never while the save is unknown)
		awardItems:Fire(p, "ref_" .. refId, 1)
		if inviter then awardItems:Fire(inviter, "gift_invites", 1) end
	end
	if inviter then
		link(inviter, p)
		print(string.format("Gifts: %s came on %s's invite - double acorns while both are here", p.Name, inviter.Name))
	end
end
-- a pair that is already on record (Item_ref_<inviterId> on the friend) is linked again whenever either of them joins
local function relink(p)
	local t0 = os.clock()
	while p.Parent == Players and not loaded(p) and os.clock() - t0 < 30 do task.wait(0.5) end
	if p.Parent ~= Players or not loaded(p) then return end
	for _, o in ipairs(Players:GetPlayers()) do
		if o ~= p and loaded(o) then
			if item(p, "ref_" .. o.UserId) > 0 or item(o, "ref_" .. p.UserId) > 0 then link(p, o) end
		end
	end
end
Players.PlayerAdded:Connect(function(p) task.spawn(onJoin, p); task.spawn(relink, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onJoin, p); task.spawn(relink, p) end
Players.PlayerRemoving:Connect(function(p)
	for o in pairs(partners[p] or {}) do if partners[o] then partners[o][p] = nil end; refresh(o) end
	partners[p] = nil
end)
F:GetAttributeChangedSignal("BoostOn"):Connect(function() for _, p in ipairs(Players:GetPlayers()) do refresh(p) end end)

-- the doubling: every gain that goes through the ledger, except our own and the big Robux packs, is paid once more
awardAcorns.Event:Connect(function(p, n, tag)
	if tag == "gift" then return end
	if typeof(p) ~= "Instance" or not p:IsA("Player") then return end
	n = tonumber(n) or 0
	if n <= 0 or n >= num("BoostMaxGain", 150) then return end   -- (the Robux packs start at 150)
	if p:GetAttribute("AcornBoost") ~= 2 then return end
	giveAcorns(p, n)
end)
print("GiftsServer: ready")

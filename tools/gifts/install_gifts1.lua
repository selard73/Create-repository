-- install_gifts1.lua (Studio EDIT mode; re-runnable). Job 87. The Gifts system: like + favourite + notifications -> the
-- Backpack (on trust), join the community -> acorns (checked), invite a friend -> double acorns while you play together
-- (checked by the friend's join data). workspace.Gifts with GiftsServer (8379 chars) and GiftsClient (19282 chars);
-- ReplicatedStorage.GiftsAction / GiftsEvent. Undo: delete workspace.Gifts and the two remotes. No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
for _, need in ipairs({"AwardItems", "AwardAcorns"}) do if not RS:FindFirstChild(need) then print("QQ GIFTS ABORT: ReplicatedStorage." .. need .. " not found (the shop / acorn system must be in)") return end end
local SERVER = [===[
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
]===]
local CLIENT = [===[
-- GiftsClient (workspace.Gifts, RunContext Client): the "Gifts for squirrel friends" card (Shannon, Oct 10 2026) - three
-- rows: like + favourite + notifications (the Backpack), join the community (acorns), invite a friend (double acorns
-- while you play together). It pops up once per session, a few seconds after the first squirrel found (or PopupDelay
-- seconds after the save has loaded if no squirrel turns up), while the first two gifts are unclaimed and no other panel
-- or the daily card is up; a Gifts button in the HUD bar opens it any time. The gold buttons shimmer and twinkle.
-- A small "x2" rides on the purse while the doubling is on. Same look as the daily card (navy, gold, cream).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SocialService = game:GetService("SocialService")
local GroupService = game:GetService("GroupService")
local ENS = game:GetService("ExperienceNotificationService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local action = RS:WaitForChild("GiftsAction")
local ev = RS:WaitForChild("GiftsEvent")
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP, DIM, GREEN = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18), C(200, 190, 210), C(150, 210, 120)
local FONT = Enum.Font.FredokaOne
local phone = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c end

local gui = Instance.new("ScreenGui"); gui.Name = "GiftsGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15; gui.Enabled = false; gui.Parent = pg
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(20, 12, 6); shade.BackgroundTransparency = 0.5; shade.Text = ""; shade.AutoButtonColor = false; shade.Parent = gui
local W, ROW, TOP, FOOT = 340, phone and 56 or 62, phone and 52 or 60, phone and 62 or 70
local card = Instance.new("Frame"); card.Name = "GiftsCard"; card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 62)   -- (78 clears the HUD row on a phone, as the daily card does)
card.Size = UDim2.fromOffset(W, TOP + ROW * 3 + FOOT); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui
corner(card, 16); local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(parent, t, size, colour, x, y, w, h, align)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.TextXAlignment = align or Enum.TextXAlignment.Left; l.Parent = parent
	return l
end
text(card, "Gifts for squirrel friends", phone and 20 or 22, CREAM, 15, 8, W - 30, 26, Enum.TextXAlignment.Center)
text(card, "Three ways to help the squirrels, three thank-yous.", 12, GOLD, 15, TOP - 20, W - 30, 16, Enum.TextXAlignment.Center)
local rows = {}
local function row(i, title, gift)
	local y = TOP + (i - 1) * ROW
	local line = Instance.new("Frame"); line.Position = UDim2.fromOffset(15, y); line.Size = UDim2.fromOffset(W - 30, 1); line.BackgroundColor3 = GOLD; line.BackgroundTransparency = 0.7; line.BorderSizePixel = 0; line.Parent = card
	local t = text(card, title, 15, CREAM, 15, y + 5, W - 150, 20)
	local g = text(card, gift, 12, GOLD, 15, y + 25, W - 150, ROW - 28); g.TextTransparency = 0.1
	local btn = Instance.new("TextButton"); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -15, 0, y + ROW / 2); btn.Size = UDim2.fromOffset(112, 36)
	btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0; btn.Font = FONT; btn.TextSize = 16; btn.TextColor3 = DEEP; btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = card
	corner(btn, 12)
	rows[i] = {title = t, gift = g, btn = btn}
	return rows[i]
end
-- the sparkle on a gold button: a sheen that sweeps across, a pale rim that breathes, and little four-point twinkles
-- (a UIGradient multiplies the button's own colour, so a sparkling button is white underneath and the gradient is the gold)
local sparkles = {}
local function sparkle(btn)
	btn.ClipsDescendants = true
	local grad = Instance.new("UIGradient"); grad.Name = "Sheen"; grad.Rotation = 18; grad.Offset = Vector2.new(-0.8, 0)
	grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(0.42, GOLD), ColorSequenceKeypoint.new(0.5, C(255, 248, 212)), ColorSequenceKeypoint.new(0.58, GOLD), ColorSequenceKeypoint.new(1, GOLD)})
	grad.Parent = btn
	local rim = Instance.new("UIStroke"); rim.Name = "Rim"; rim.Color = C(255, 242, 196); rim.Thickness = 1.5; rim.Transparency = 0.3; rim.Parent = btn
	local sp = {btn = btn, grad = grad, rim = rim, on = true, stars = {}}
	for i = 1, 4 do
		local star = Instance.new("Frame"); star.Name = "Twinkle"; star.AnchorPoint = Vector2.new(0.5, 0.5); star.Size = UDim2.fromOffset(0, 0); star.BackgroundTransparency = 1; star.ZIndex = 3; star.Parent = btn
		for _, dims in ipairs({{0.22, 1}, {1, 0.22}}) do   -- (a thin upright bar and a thin flat bar make the four points)
			local bar = Instance.new("Frame"); bar.AnchorPoint = Vector2.new(0.5, 0.5); bar.Position = UDim2.fromScale(0.5, 0.5); bar.Size = UDim2.fromScale(dims[1], dims[2])
			bar.BackgroundColor3 = C(255, 255, 240); bar.BorderSizePixel = 0; bar.ZIndex = 3; bar.Parent = star
		end
		sp.stars[i] = star
	end
	sparkles[btn] = sp
	-- the sheen sweep
	task.spawn(function()
		while btn.Parent do
			if sp.on and gui.Enabled then
				grad.Offset = Vector2.new(-0.8, 0)
				local tw = TweenService:Create(grad, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Offset = Vector2.new(0.8, 0)}); tw:Play(); tw.Completed:Wait()
				task.wait(1.6)
			else task.wait(0.5) end
		end
	end)
	-- the rim breathing
	task.spawn(function()
		while btn.Parent do
			if sp.on and gui.Enabled then
				local tw = TweenService:Create(rim, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {Transparency = 0.75}); tw:Play(); tw.Completed:Wait()
			else task.wait(0.5) end
		end
	end)
	-- the twinkles, each on its own beat, away from the middle where the word sits
	for i, star in ipairs(sp.stars) do
		task.spawn(function()
			task.wait(i * 0.37)
			while btn.Parent do
				if sp.on and gui.Enabled then
					local w, h = btn.AbsoluteSize.X, btn.AbsoluteSize.Y
					local x = (math.random() < 0.5) and math.random(6, math.max(7, math.floor(w * 0.24))) or math.random(math.floor(w * 0.76), math.max(math.floor(w * 0.76) + 1, w - 6))
					star.Position = UDim2.fromOffset(x, math.random(5, math.max(6, h - 5))); star.Rotation = math.random(-20, 20)
					local size = math.random(8, 13)
					local up = TweenService:Create(star, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(size, size), Rotation = star.Rotation + 45}); up:Play(); up.Completed:Wait()
					local down = TweenService:Create(star, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0), Rotation = star.Rotation + 45}); down:Play(); down.Completed:Wait()
					task.wait(0.5 + math.random() * 1.4)
				else
					if star.Size.X.Offset ~= 0 then star.Size = UDim2.fromOffset(0, 0) end
					task.wait(0.5)
				end
			end
		end)
	end
end
local function sparkleOn(btn, on)
	local sp = sparkles[btn]; if not sp then return end
	sp.on = on; sp.grad.Enabled = on; sp.rim.Enabled = on
	if on then btn.BackgroundColor3 = C(255, 255, 255) else for _, star in ipairs(sp.stars) do star.Size = UDim2.fromOffset(0, 0) end end
end
local rLike = row(1, "Like, star & notifications", "Gift: the Backpack")
local rComm = row(2, "Join our community", "The 1001 Squirrels community. Gift: " .. num("CommunityAcorns", 150) .. " acorns")
local rInv = row(3, "Invite a friend", "Double acorns while you play together")
for _, r in ipairs(rows) do sparkle(r.btn) end
local later = Instance.new("TextButton"); later.AnchorPoint = Vector2.new(0.5, 1); later.Position = UDim2.new(0.5, 0, 1, -4); later.Size = UDim2.fromOffset(120, 26)
later.BackgroundTransparency = 1; later.Font = FONT; later.TextSize = 15; later.TextColor3 = DIM; later.Text = "Later"; later.Parent = card
local note = text(card, "", 12, CREAM, 15, TOP + ROW * 3 + 2, W - 30, FOOT - 34, Enum.TextXAlignment.Center); note.TextTransparency = 0.1
local noteAt = 0
local function say(t, secs) note.Text = t; local my = os.clock(); noteAt = my; task.delay(secs or 6, function() if noteAt == my then note.Text = "" end end) end

-- ---------- state ----------
local S = {}
local function set(btn, label, done)
	btn.Text = label
	btn.BackgroundColor3 = done and GREEN or GOLD
	btn.Active = not done; btn.AutoButtonColor = false
	sparkleOn(btn, not done)
end
local likePrompted = false
local function paint()
	if S.like then set(rLike.btn, S.backpack and "Yours!" or "Thank you", true)
	elseif likePrompted then set(rLike.btn, "Claim", false)
	else set(rLike.btn, "Turn on", false) end
	if S.community then set(rComm.btn, "Thank you", true) else set(rComm.btn, "Join", false) end
	if S.boosted then rInv.gift.Text = "x2 acorns on, with " .. tostring(S.boostWith)
	elseif (S.invites or 0) > 0 then rInv.gift.Text = string.format("%d friend%s brought. Double acorns while you play together", S.invites, S.invites == 1 and "" or "s")
	else rInv.gift.Text = "Double acorns while you play together" end
	set(rInv.btn, "Invite", false)
end
local function ask(what)
	local ok, a, b = pcall(function() return action:InvokeServer(what) end)
	if not ok then return false, "no answer" end
	return a, b
end
local function refresh()
	local ok, st = ask("state")
	if ok and type(st) == "table" then S = st; paint(); return true end
	return false
end
paint()

-- ---------- the card ----------
local shownThisSession = false
local MODAL = {shop = true, passport = true, book = true, portrait = true, question = true, wardrobe = true, seaglass = true, album = true}
local function setOpen(on)
	if on then
		if not refresh() then task.spawn(function() for _ = 1, 10 do task.wait(0.5); if not gui.Enabled or refresh() then return end end end) end   -- (the save may still be loading)
		gui.Enabled = true; pg:SetAttribute("OpenPanel", "gifts"); shownThisSession = true   -- (the map and the squirrel panel never clear OpenPanel; taking over is the convention)
	else
		gui.Enabled = false
		if pg:GetAttribute("OpenPanel") == "gifts" then pg:SetAttribute("OpenPanel", nil) end
	end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if gui.Enabled and pg:GetAttribute("OpenPanel") ~= "gifts" then gui.Enabled = false end end)
later.Activated:Connect(function() setOpen(false) end)
shade.Activated:Connect(function() setOpen(false) end)

-- row 1: the notifications prompt, then the menu's thumbs-up and star, then the claim
rLike.btn.Activated:Connect(function()
	if S.like then return end
	if not likePrompted then
		likePrompted = true
		local ok, can = pcall(function() return ENS:CanPromptOptInAsync() end)
		if ok and can then
			local closed = false
			local conn; conn = ENS.OptInPromptClosed:Connect(function() closed = true; if conn then conn:Disconnect() end end)
			pcall(function() ENS:PromptOptIn() end)
			task.delay(45, function() if conn then conn:Disconnect() end end)
		end
		say("Now open the Roblox menu, press the thumbs-up and the star, then Claim.", 12)
		paint()
		return
	end
	local ok, res = ask("claimLike")
	if ok and type(res) == "table" then S = res; paint(); say("The Backpack is yours - it is on your back now, and in the Acorn Store's row to take off.", 8)
	else say(tostring(res or "later"), 4) end
end)
-- row 2: Roblox's own join prompt, then the server checks
rComm.btn.Activated:Connect(function()
	if S.community then return end
	local gid = num("GroupId", 0)
	local status
	if gid > 0 then local ok, r = pcall(function() return GroupService:PromptJoinAsync(gid) end); if ok then status = r end end
	if status == Enum.GroupMembershipStatus.JoinRequestPending then say("Your request is in - press Join again once it is accepted.", 6) return end
	local ok, res = ask("checkCommunity")
	if ok and type(res) == "table" then S = res; paint(); say(string.format("Welcome to the community! %d acorns are in your purse.", num("CommunityAcorns", 150)), 8)
	else say(res == "not yet" and "Not a member yet - join from the prompt or the community page, then press Join again." or tostring(res or "later"), 7) end
end)
-- row 3: Roblox's invite prompt; the server sees the friend arrive
rInv.btn.Activated:Connect(function()
	local ok, can = pcall(function() return SocialService:CanSendGameInviteAsync(player) end)
	if not (ok and can) then say("Invites are not available on this device or account.", 5) return end
	local opts = Instance.new("ExperienceInviteOptions")
	opts.PromptMessage = "Come find squirrels with me - we both get double acorns while we play!"
	pcall(function() SocialService:PromptGameInvite(player, opts) end)
	say("When your friend joins from the invite, you both earn double acorns while you are here together.", 8)
end)

-- ---------- the HUD button (left of the others) and the x2 on the purse ----------
task.spawn(function()
	for _ = 1, 120 do
		local bar = pg:FindFirstChild("HudBar"); bar = bar and bar:FindFirstChild("Bar")
		if bar then
			if not bar:FindFirstChild("Gifts") then
				if bar.Size.X.Offset > 0 and bar.Size.X.Offset < 272 then bar.Size = UDim2.new(bar.Size.X.Scale, 272, bar.Size.Y.Scale, bar.Size.Y.Offset) end   -- (four squares + one)
				local b = Instance.new("TextButton"); b.Name = "Gifts"; b.Size = UDim2.fromOffset(48, 48); b.BackgroundColor3 = NAVY; b.Text = ""; b.AutoButtonColor = false; b.LayoutOrder = -3; b.Parent = bar
				corner(b, 14); local s = Instance.new("UIStroke"); s.Color = C(255, 214, 90); s.Thickness = 2; s.Transparency = 0.35; s.Parent = b
				-- a little gift box: the box, the lid, the ribbon
				local box = Instance.new("Frame"); box.AnchorPoint = Vector2.new(0.5, 1); box.Position = UDim2.new(0.5, 0, 1, -9); box.Size = UDim2.fromOffset(22, 16); box.BackgroundColor3 = C(220, 90, 90); box.BorderSizePixel = 0; box.Parent = b; corner(box, 3)
				local lid = Instance.new("Frame"); lid.AnchorPoint = Vector2.new(0.5, 1); lid.Position = UDim2.new(0.5, 0, 1, -24); lid.Size = UDim2.fromOffset(26, 6); lid.BackgroundColor3 = C(240, 110, 110); lid.BorderSizePixel = 0; lid.Parent = b; corner(lid, 2)
				local rib = Instance.new("Frame"); rib.AnchorPoint = Vector2.new(0.5, 1); rib.Position = UDim2.new(0.5, 0, 1, -9); rib.Size = UDim2.fromOffset(4, 22); rib.BackgroundColor3 = GOLD; rib.BorderSizePixel = 0; rib.Parent = b
				local bow = Instance.new("TextLabel"); bow.AnchorPoint = Vector2.new(0.5, 1); bow.Position = UDim2.new(0.5, 0, 1, -29); bow.Size = UDim2.fromOffset(20, 10); bow.BackgroundTransparency = 1; bow.Font = FONT; bow.TextSize = 12; bow.TextColor3 = GOLD; bow.Text = "~"; bow.Parent = b
				b.MouseEnter:Connect(function() s.Transparency = 0 end); b.MouseLeave:Connect(function() s.Transparency = 0.35 end)
				b.Activated:Connect(function() if gui.Enabled then setOpen(false) else setOpen(true) end end)
			end
			local purse = bar:FindFirstChild("Purse")
			if purse and not purse:FindFirstChild("Boost") then
				local x2 = Instance.new("TextLabel"); x2.Name = "Boost"; x2.AnchorPoint = Vector2.new(1, 0); x2.Position = UDim2.new(1, 4, 0, -6); x2.Size = UDim2.fromOffset(26, 16)
				x2.BackgroundColor3 = GREEN; x2.Font = FONT; x2.TextSize = 12; x2.TextColor3 = DEEP; x2.Text = "x2"; x2.Visible = player:GetAttribute("AcornBoost") == 2; x2.Parent = purse; corner(x2, 8)
				player:GetAttributeChangedSignal("AcornBoost"):Connect(function() x2.Visible = player:GetAttribute("AcornBoost") == 2 end)
			end
			return
		end
		task.wait(0.5)
	end
end)

-- ---------- the toast when the doubling starts ----------
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118); toast.Size = UDim2.fromOffset(440, 44)
toast.BackgroundColor3 = NAVY; toast.BackgroundTransparency = 1; toast.Font = FONT; toast.TextSize = 17; toast.TextColor3 = GOLD; toast.TextTransparency = 1; toast.Text = ""; toast.TextWrapped = true
local tg = Instance.new("ScreenGui"); tg.Name = "GiftsToast"; tg.ResetOnSpawn = false; tg.IgnoreGuiInset = true; tg.DisplayOrder = 8; tg.Parent = pg; toast.Parent = tg; corner(toast, 12)
local toastAt = 0
local function showToast(t)
	toast.Text = t; toast.BackgroundTransparency = 0.1; toast.TextTransparency = 0
	local my = os.clock(); toastAt = my
	task.delay(6, function() if toastAt == my then TweenService:Create(toast, TweenInfo.new(0.6), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end end)
end
ev.OnClientEvent:Connect(function(what, name)
	if what == "boost" then showToast(string.format("Double acorns! You and %s earn twice as many while you play together.", tostring(name))); refresh()
	elseif what == "boostoff" then showToast("Your friend has left - acorns are back to normal."); refresh() end
end)

-- ---------- the popup, once per session: a few seconds after the first squirrel found, or PopupDelay seconds in ----------
local function foundCount()   -- (SquirrelsFound is the running total; FoundIds the comma list - whichever is further along)
	local n = tonumber(player:GetAttribute("SquirrelsFound")) or 0
	local ids = player:GetAttribute("FoundIds")
	if type(ids) == "string" and #ids > 0 then local k = 0; for _ in ids:gmatch("[^,]+") do k += 1 end; if k > n then n = k end end
	return n
end
task.spawn(function()
	if F:GetAttribute("AutoPopup") == false then return end
	local t0 = os.clock()
	while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 60 do task.wait(0.5) end
	task.wait(1.5)   -- (let the saved counts land before taking the baseline)
	local last, tStart, limit = foundCount(), os.clock(), num("PopupDelay", 180)
	while os.clock() - tStart < limit do
		if shownThisSession then return end
		local n = foundCount()
		if F:GetAttribute("FirstFind") ~= false and n > last and n - last <= 2 then task.wait(num("FindSettle", 5)) break end   -- (one find, not a save arriving)
		last = math.max(last, n)
		task.wait(0.5)
	end
	local deadline = os.clock() + 300
	while os.clock() < deadline do
		if shownThisSession then return end
		if refresh() and (S.like and S.community) then return end   -- (both thank-yous given: the HUD button is enough)
		local daily = pg:FindFirstChild("DailyGui"); local dcard = daily and daily:FindFirstChild("DailyCard")
		local dailyUp = daily ~= nil and daily.Enabled and dcard ~= nil and dcard.Visible
		if not MODAL[pg:GetAttribute("OpenPanel")] and not dailyUp and player.Character then setOpen(true) return end
		task.wait(10)
	end
end)
print("GiftsClient: ready")
]===]
for _, pair in ipairs({{"server", SERVER}, {"client", CLIENT}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ GIFTS ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
end
local act = RS:FindFirstChild("GiftsAction"); if not act then act = Instance.new("RemoteFunction"); act.Name = "GiftsAction"; act.Parent = RS end
local ev = RS:FindFirstChild("GiftsEvent"); if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "GiftsEvent"; ev.Parent = RS end
local old = workspace:FindFirstChild("Gifts")
local attrs = {}
if old then
	for k, v in pairs(old:GetAttributes()) do attrs[k] = v end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Gifts_pre_" .. n) do n += 1 end
	old.Name = "Gifts_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetChildren()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "Gifts"
local defaults = {GroupId = 969906332, CommunityAcorns = 150, BoostMaxGain = 150, LikeReward = "backpack", BoostOn = true, PopupDelay = 180, FirstFind = true, AutoPopup = true}
for k, v in pairs(defaults) do if attrs[k] ~= nil then F:SetAttribute(k, attrs[k]) else F:SetAttribute(k, v) end end
local s = Instance.new("Script"); s.Name = "GiftsServer"; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "GiftsClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ GIFTS DONE: workspace.Gifts (GiftsServer %d, GiftsClient %d chars; GroupId %s, CommunityAcorns %s, BoostMaxGain %s, LikeReward %s, PopupDelay %s, FirstFind %s, AutoPopup %s, BoostOn %s)%s",
	#s.Source, #c.Source, tostring(F:GetAttribute("GroupId")), tostring(F:GetAttribute("CommunityAcorns")), tostring(F:GetAttribute("BoostMaxGain")), tostring(F:GetAttribute("LikeReward")), tostring(F:GetAttribute("PopupDelay")), tostring(F:GetAttribute("FirstFind")), tostring(F:GetAttribute("AutoPopup")), tostring(F:GetAttribute("BoostOn")),
	old and ("; the old Gifts folder is HudBackup." .. old.Name) or ""))

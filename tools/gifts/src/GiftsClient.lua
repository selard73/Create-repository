-- GiftsClient (workspace.Gifts, RunContext Client): the "Gifts for squirrel friends" card (Shannon, Oct 10 2026) - three
-- rows: like + favourite + notifications (the Backpack), join the community (acorns), invite a friend (double acorns
-- while you play together). It pops up once per session, a few seconds after the first squirrel found (or PopupDelay
-- seconds after the save has loaded if no squirrel turns up), while the first two gifts are unclaimed and no other panel
-- or the daily card is up; a Gifts button in the HUD bar opens it any time, and while it is open it sits above everything
-- else on the screen. The gold buttons have a glinting gold outline.
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

local gui = Instance.new("ScreenGui"); gui.Name = "GiftsGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Enabled = false; gui.Parent = pg   -- (100: above every other ScreenGui, the interact pills at 30 and the film menu at 60 included - Shannon: "on top of anything else on the screen until it is closed")
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(20, 12, 6); shade.BackgroundTransparency = 0.5; shade.Text = ""; shade.AutoButtonColor = false; shade.Parent = gui
local W, ROW, TOP, FOOT = 340, phone and 44 or 62, phone and 52 or 60, phone and 32 or 70   -- (phone: 52 + 132 + 32 = 216 tall from y 78, ending at 294, above Roblox's tool hotbar at 305)
local card = Instance.new("Frame"); card.Name = "GiftsCard"; card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 62)   -- (78 clears the HUD row on a phone, as the daily card does; the card must end above y 305 there, where the tool hotbar starts)
card.Size = UDim2.fromOffset(W, TOP + ROW * 3 + FOOT); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui
corner(card, 16); local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(parent, t, size, colour, x, y, w, h, align)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.TextXAlignment = align or Enum.TextXAlignment.Left; l.Parent = parent
	return l
end
text(card, "Gifts for squirrel friends", phone and 20 or 22, CREAM, 15, 8, W - 30, 26, Enum.TextXAlignment.Center)
local SUBTITLE = "Three ways to help the squirrels, three thank-yous."
local sub = text(card, SUBTITLE, 12, GOLD, 15, TOP - 20, W - 30, 16, Enum.TextXAlignment.Center)
local rows = {}
local function row(i, title, gift)
	local y = TOP + (i - 1) * ROW
	local line = Instance.new("Frame"); line.Position = UDim2.fromOffset(15, y); line.Size = UDim2.fromOffset(W - 30, 1); line.BackgroundColor3 = GOLD; line.BackgroundTransparency = 0.7; line.BorderSizePixel = 0; line.Parent = card
	local t = text(card, title, 15, CREAM, 15, y + (phone and 4 or 5), W - 150, 20)
	local g = text(card, gift, 12, GOLD, 15, y + (phone and 22 or 25), W - 150, phone and 18 or ROW - 28); g.TextTransparency = 0.1
	local btn = Instance.new("TextButton"); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -15, 0, y + ROW / 2); btn.Size = UDim2.fromOffset(112, 36)
	btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0; btn.Font = FONT; btn.TextSize = 16; btn.TextColor3 = DEEP; btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = card
	corner(btn, 12)
	rows[i] = {title = t, gift = g, btn = btn}
	return rows[i]
end
-- the sparkle on a gold button (Shannon: no twinkle shapes; "a sparkle gold outline around the buttons"): a gold outline
-- with a bright glint that travels round it (a UIGradient on the stroke, its Rotation turning), and a pale sheen sweeping
-- across the face. A UIGradient multiplies the colour under it, so the face and the stroke are white underneath and the
-- gradients carry the gold.
local sparkles = {}
local function sparkle(btn)
	local grad = Instance.new("UIGradient"); grad.Name = "Sheen"; grad.Rotation = 18; grad.Offset = Vector2.new(-0.8, 0)
	grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(0.4, GOLD), ColorSequenceKeypoint.new(0.5, C(255, 250, 220)), ColorSequenceKeypoint.new(0.6, GOLD), ColorSequenceKeypoint.new(1, GOLD)})
	grad.Parent = btn
	local rim = Instance.new("UIStroke"); rim.Name = "Rim"; rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; rim.Color = C(255, 255, 255); rim.Thickness = 3; rim.Transparency = 0; rim.LineJoinMode = Enum.LineJoinMode.Round; rim.Parent = btn   -- (Border: the button's edge, not the letters, which is what a UIStroke on a TextButton strokes by default)
	local glint = Instance.new("UIGradient"); glint.Name = "Glint"; glint.Rotation = 0
	glint.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 252, 232)), ColorSequenceKeypoint.new(0.2, C(255, 222, 110)), ColorSequenceKeypoint.new(0.55, C(206, 156, 46)), ColorSequenceKeypoint.new(1, C(188, 138, 36))})
	glint.Parent = rim
	local sp = {btn = btn, grad = grad, rim = rim, glint = glint, on = true}
	sparkles[btn] = sp
	-- the sheen sweep across the face
	task.spawn(function()
		while btn.Parent do
			if sp.on and gui.Enabled then
				grad.Offset = Vector2.new(-0.8, 0)
				local tw = TweenService:Create(grad, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Offset = Vector2.new(0.8, 0)}); tw:Play(); tw.Completed:Wait()
				task.wait(1.6)
			else task.wait(0.5) end
		end
	end)
	-- the glint going round the outline
	task.spawn(function()
		while btn.Parent do
			if sp.on and gui.Enabled then
				glint.Rotation = 0
				local tw = TweenService:Create(glint, TweenInfo.new(2.4, Enum.EasingStyle.Linear), {Rotation = 360}); tw:Play(); tw.Completed:Wait()
			else task.wait(0.5) end
		end
	end)
end
local function sparkleOn(btn, on)
	local sp = sparkles[btn]; if not sp then return end
	sp.on = on; sp.grad.Enabled = on; sp.rim.Enabled = on
	if on then btn.BackgroundColor3 = C(255, 255, 255) end
end
local rLike = row(1, "Like, star & notifications", "Gift: the Backpack")
local rComm = row(2, "Join our community", (phone and "Gift: " or "The 1001 Squirrels community. Gift: ") .. num("CommunityAcorns", 150) .. " acorns")
local INVITE = phone and "Double acorns together" or "Double acorns while you play together"   -- (one line on a phone)
local rInv = row(3, "Invite a friend", INVITE)
for _, r in ipairs(rows) do sparkle(r.btn) end
local later = Instance.new("TextButton"); later.AnchorPoint = Vector2.new(0.5, 1); later.Position = UDim2.new(0.5, 0, 1, -4); later.Size = UDim2.fromOffset(120, 26)
later.BackgroundTransparency = 1; later.Font = FONT; later.TextSize = 15; later.TextColor3 = DIM; later.Text = "Later"; later.Parent = card
local note = text(card, "", 12, CREAM, 15, TOP + ROW * 3 + 2, W - 30, math.max(FOOT - 34, 0), Enum.TextXAlignment.Center); note.TextTransparency = 0.1
if phone then note.Visible = false end   -- (no room under the rows on a phone: a note takes the subtitle's line instead)
local noteAt = 0
local function say(t, secs, short)   -- (short: the one-line version for the phone's subtitle slot, 16 px tall)
	local my = os.clock(); noteAt = my
	if phone then sub.Text = short or t; sub.TextColor3 = CREAM else note.Text = t end
	task.delay(secs or 6, function() if noteAt == my then if phone then sub.Text = SUBTITLE; sub.TextColor3 = GOLD else note.Text = "" end end end)
end

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
	elseif (S.invites or 0) > 0 then rInv.gift.Text = string.format(phone and "%d friend%s brought. Double acorns together" or "%d friend%s brought. Double acorns while you play together", S.invites, S.invites == 1 and "" or "s")
	else rInv.gift.Text = INVITE end
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
		say("Now open the Roblox menu, press the thumbs-up and the star, then Claim.", 12, "Menu > thumbs-up and star, then Claim.")
		paint()
		return
	end
	local ok, res = ask("claimLike")
	if ok and type(res) == "table" then S = res; paint(); say("The Backpack is yours - it is on your back now, and in the Acorn Store's row to take off.", 8, "The Backpack is yours - it is on your back now.")
	else say(tostring(res or "later"), 4) end
end)
-- row 2: Roblox's own join prompt, then the server checks
rComm.btn.Activated:Connect(function()
	if S.community then return end
	local gid = num("GroupId", 0)
	local status
	if gid > 0 then local ok, r = pcall(function() return GroupService:PromptJoinAsync(gid) end); if ok then status = r end end
	if status == Enum.GroupMembershipStatus.JoinRequestPending then say("Your request is in - press Join again once it is accepted.", 6, "Request sent - press Join again once accepted.") return end
	local ok, res = ask("checkCommunity")
	if ok and type(res) == "table" then S = res; paint(); say(string.format("Welcome to the community! %d acorns are in your purse.", num("CommunityAcorns", 150)), 8, string.format("Welcome! %d acorns are in your purse.", num("CommunityAcorns", 150)))
	else say(res == "not yet" and "Not a member yet - join from the prompt or the community page, then press Join again." or tostring(res or "later"), 7, res == "not yet" and "Not a member yet - join, then press Join again." or nil) end
end)
-- row 3: Roblox's invite prompt; the server sees the friend arrive
rInv.btn.Activated:Connect(function()
	local ok, can = pcall(function() return SocialService:CanSendGameInviteAsync(player) end)
	if not (ok and can) then say("Invites are not available on this device or account.", 5, "Invites are not available here.") return end
	local opts = Instance.new("ExperienceInviteOptions")
	opts.PromptMessage = "Come find squirrels with me - we both get double acorns while we play!"
	pcall(function() SocialService:PromptGameInvite(player, opts) end)
	say("When your friend joins from the invite, you both earn double acorns while you are here together.", 8, "Friend joins = double acorns for you both.")
end)

-- ---------- the HUD button and the x2 on the purse ----------
-- Desktop: the gift box joins the row, left of the others (the bar widened to 272). Phone (Shannon, Oct 11: "that row on
-- mobile is suddenly very crowded up there, could we stack those icons down the right side instead and keep the gift icon
-- top to the left of the passport", then "when you click the icon boxes, the modal should open to the right and under
-- them, not on top of them" - her pick: the squares never move; the squirrel list and the map open under the top row and
-- to the LEFT of the column, a little narrower, clear of the Hint button): the bar's four squares become a column down the
-- right edge (Passport, Purse, Squirrels, Map), the gift box sits on the top row to the left of the Passport, and the two
-- panels HudBarClient opens top-right get their right edge moved left of the column and of Roblox's capture bar at its
-- default spot (x 557..601 on the 667-wide phone), with their UIScale capped so they end right of the Hint button.
local COLUMN_X = -(10 + 48 + 8)                 -- the gift box's right edge (the bar sits at -10)
local PANEL_RIGHT = -(10 + 48 + 8 + 44 + 8)     -- the panels' right edge: left of the column and of the capture bar (44 wide)
local HINT_RIGHT = 124                          -- the Hint button ends at x 116
local function placePanel(panel)
	if not (panel and panel:IsA("GuiObject")) then return end
	if panel.Position.X.Scale == 1 and panel.Position.X.Offset ~= PANEL_RIGHT then panel.Position = UDim2.new(1, PANEL_RIGHT, panel.Position.Y.Scale, panel.Position.Y.Offset) end
	local sc, cam, w = panel:FindFirstChildOfClass("UIScale"), workspace.CurrentCamera, panel.Size.X.Offset
	if sc and cam and w > 0 then
		local cap = (cam.ViewportSize.X + PANEL_RIGHT - HINT_RIGHT) / w   -- (the room between the Hint and the panels' right edge)
		if sc.Scale > cap then sc.Scale = math.max(0.45, cap) end
	end
end
local function watchPanel(panel)   -- HudBarClient puts the panel back at -10 and refits its scale on hook, size and viewport changes: follow every one
	placePanel(panel)
	panel:GetPropertyChangedSignal("Position"):Connect(function() placePanel(panel) end)
	panel:GetPropertyChangedSignal("Size"):Connect(function() task.defer(placePanel, panel) end)
	local function hookScale(sc) sc:GetPropertyChangedSignal("Scale"):Connect(function() placePanel(panel) end) end
	local sc = panel:FindFirstChildOfClass("UIScale"); if sc then hookScale(sc) end
	panel.ChildAdded:Connect(function(c) if c:IsA("UIScale") then hookScale(c); task.defer(placePanel, panel) end end)
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() task.defer(placePanel, panel) end) end
end
local function watchPanels(hud)
	local map = hud:FindFirstChild("MapPanel"); if map then watchPanel(map) end
	local function hookSquirrelHud(g) local panel = g:WaitForChild("Panel", 30); if panel then watchPanel(panel) end end
	local sh = pg:FindFirstChild("SquirrelHUD"); if sh then task.spawn(hookSquirrelHud, sh) end
	pg.ChildAdded:Connect(function(c) if c.Name == "SquirrelHUD" then task.defer(hookSquirrelHud, c) end end)
end
task.spawn(function()
	for _ = 1, 120 do
		local hud = pg:FindFirstChild("HudBar"); local bar = hud and hud:FindFirstChild("Bar")
		if bar then
			if not bar:FindFirstChild("Gifts") and not hud:FindFirstChild("Gifts") then
				if phone then
					local lay = bar:FindFirstChildOfClass("UIListLayout")
					if lay then lay.FillDirection = Enum.FillDirection.Vertical; lay.HorizontalAlignment = Enum.HorizontalAlignment.Right; lay.VerticalAlignment = Enum.VerticalAlignment.Top end
					bar.Size = UDim2.new(bar.Size.X.Scale, 48, 0, 216)   -- (four squares and three gaps, down the right edge)
					task.defer(watchPanels, hud)
				elseif bar.Size.X.Offset > 0 and bar.Size.X.Offset < 272 then
					bar.Size = UDim2.new(bar.Size.X.Scale, 272, bar.Size.Y.Scale, bar.Size.Y.Offset)   -- (four squares + one)
				end
				local b = Instance.new("TextButton"); b.Name = "Gifts"; b.Size = UDim2.fromOffset(48, 48); b.BackgroundColor3 = NAVY; b.Text = ""; b.AutoButtonColor = false; b.LayoutOrder = -3
				if phone then b.AnchorPoint = Vector2.new(1, 0); b.Position = UDim2.new(1, COLUMN_X, 0, bar.Position.Y.Offset); b.Parent = hud else b.Parent = bar end
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
				local x2 = Instance.new("TextLabel"); x2.Name = "Boost"; x2.AnchorPoint = Vector2.new(1, 0); x2.Position = phone and UDim2.new(0, -4, 0.5, -8) or UDim2.new(1, 4, 0, -6); x2.Size = UDim2.fromOffset(26, 16)   -- (phone: beside the purse, left; the column has no room above it)
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
	print(string.format("GiftsClient: popup armed - found %d (SquirrelsFound %s, FoundIds %d chars), fallback %ds", last, tostring(player:GetAttribute("SquirrelsFound")), #tostring(player:GetAttribute("FoundIds") or ""), limit))
	local why = "the fallback"
	while os.clock() - tStart < limit do
		if shownThisSession then return end
		local n = foundCount()
		if F:GetAttribute("FirstFind") ~= false and n > last and n - last <= 2 then   -- (one find, not a save arriving)
			why = string.format("a find at %.1fs (found %d -> %d; SquirrelsFound %s, FoundIds %d chars)", os.clock() - tStart, last, n, tostring(player:GetAttribute("SquirrelsFound")), #tostring(player:GetAttribute("FoundIds") or ""))
			task.wait(num("FindSettle", 5)) break
		end
		last = math.max(last, n)
		task.wait(0.5)
	end
	print("GiftsClient: popup due after " .. why)
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

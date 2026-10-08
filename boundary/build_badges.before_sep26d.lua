-- Badges: a case for the honours a player keeps. Shannon (Sep 25 2026): "if someone earns the statue, they should get
-- a permanent badge to keep somewhere, that says the title and the day #" - and the Wise Squirrel badge from the
-- Question of the Day draw.
-- Tap the title pill at the top of the screen - or the little medal beside it, which appears once you hold a special
-- badge - and the case opens:
--   * GRAND KEEPER OF THE GREAT ACORN, No. N: your number in the order the Keepers won (Shannon, Sep 26: "count it by
--     order instead 1st, 2nd, 3rd, 4th"), with the date - ChampionNo/ChampionDay/ChampionTotal/ChampionWins, set on join
--     by the ChampionServer from its hall (Item_champion_day, the first day won, still marks a Keeper while they load).
--   * WISE SQUIRREL: your right answer to the Question of the Day was the one drawn (Item_wise_day = the day of the
--     first win, Item_wise_wins = how many).
--   * the three area medals - Squirrel Friend, Squirrel Whisperer, Grand Keeper of the Great Acorn - in colour once
--     earned (HonourTier), the rest waiting in grey with what it takes.
-- Everything is read from attributes the save ledger and the honours already set; nothing new is stored here. The
-- Roblox (profile) badges are awarded by the ChampionServer and the QuestionServer once their ids are set.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local old = workspace:FindFirstChild("BadgeCase"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "BadgeCase"
	-- the pictures on Shannon's Roblox badges (icon image ids from badges.roblox.com, Sep 25), shown in the case instead of the
	-- drawn medals; the BadgeIcons script refreshes them from Roblox at start, so a new picture shows up by itself
	local ICONS = {Icon_champion = 113682285120013, Icon_wise = 94969527536194, Icon_forest = 87016299744105,
		Icon_village = 95431163854850, Icon_domaine = 72483908574728}
	for k, v in pairs(ICONS) do F:SetAttribute(k, (opts.icons and opts.icons[k]) or v) end
	local ICON_SERVER = [==[
-- BadgeIcons: each badge's current picture, straight from Roblox, onto this folder for the case to show
local BadgeService = game:GetService("BadgeService")
local F = script.Parent
local SOURCES = {
	Icon_champion = {"Champion", "Badge_champion"}, Icon_wise = {"DailyQuestion", "Badge_wise"},
	Icon_forest = {"Honours", "Badge_forest"}, Icon_village = {"Honours", "Badge_village"}, Icon_domaine = {"Honours", "Badge_domaine"},
}
for attr, src in pairs(SOURCES) do
	task.spawn(function()
		local home = workspace:WaitForChild(src[1], 30)
		local id = home and tonumber(home:GetAttribute(src[2])) or 0
		if id <= 0 then return end
		local ok, info = pcall(function() return BadgeService:GetBadgeInfoAsync(id) end)
		if ok and type(info) == "table" and (tonumber(info.IconImageId) or 0) > 0 then F:SetAttribute(attr, info.IconImageId) end
	end)
end
]==]
	local iconSrv = Instance.new("Script"); iconSrv.Name = "BadgeIcons"; iconSrv.RunContext = Enum.RunContext.Server; iconSrv.Source = ICON_SERVER; iconSrv.Parent = F

	local CLIENT = [==[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local function iconOf(attr) return tonumber(F:GetAttribute(attr)) or 0 end
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DIM, INK = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(150, 140, 170), C(255, 214, 90)
local GREY = C(92, 86, 110)
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local TOTAL, NAME, ALL = {}, {}, 0
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1; ALL += 1 end
for _, m in ipairs(Registry.maps) do NAME[m.id] = m.name end
local AREAS = {
	{map = "forest",  title = "Squirrel Friend",                 colour = C(205, 127, 50)},
	{map = "village", title = "Squirrel Whisperer",             colour = C(200, 204, 212)},
	{map = "domaine", title = "Grand Keeper of the Great Acorn", colour = C(240, 196, 60)},
}
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0, 12); c.Parent = o; return c end
local function stroke(o, col, th) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th or 2; s.Parent = o; return s end
local function label(parent, text, font, size, colour, x, y, w, h, align)
	local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, h)
	l.Font = font; l.TextSize = size; l.TextColor3 = colour; l.Text = text; l.TextWrapped = true
	l.TextXAlignment = align or Enum.TextXAlignment.Left; l.TextYAlignment = Enum.TextYAlignment.Top; l.Parent = parent
	return l
end
-- the honours' own medal: a round medal with a little acorn drawn from frames (the same one as the title pill)
local function medallion(parent, size, colour)
	local m = Instance.new("Frame"); m.Size = UDim2.fromOffset(size, size); m.BackgroundColor3 = colour; m.BorderSizePixel = 0; m.Parent = parent
	corner(m, UDim.new(0.5, 0)); stroke(m, C(80, 52, 30), 2)
	local nut = Instance.new("Frame"); nut.Size = UDim2.new(0.42, 0, 0.44, 0); nut.Position = UDim2.new(0.29, 0, 0.36, 0); nut.BackgroundColor3 = C(196, 138, 78); nut.BorderSizePixel = 0; nut.Parent = m
	corner(nut, UDim.new(0.5, 0))
	local cap = Instance.new("Frame"); cap.Size = UDim2.new(0.52, 0, 0.26, 0); cap.Position = UDim2.new(0.24, 0, 0.2, 0); cap.BackgroundColor3 = C(104, 66, 38); cap.BorderSizePixel = 0; cap.Parent = m
	corner(cap, UDim.new(0.45, 0))
	local stem = Instance.new("Frame"); stem.Size = UDim2.new(0.08, 0, 0.14, 0); stem.Position = UDim2.new(0.46, 0, 0.1, 0); stem.BackgroundColor3 = C(80, 52, 30); stem.BorderSizePixel = 0; stem.Parent = m
	return m
end

local function num(attr) return tonumber(player:GetAttribute(attr)) or 0 end
local function championDay() return num("Item_champion_day") end
-- a Keeper's NUMBER: 1st, 2nd, 3rd ... in the order they won (Shannon, Sep 26), set by the ChampionServer from its hall
local function championNo() return num("ChampionNo") end
local function isKeeper() return championNo() > 0 or championDay() > 0 end
local function championWins() return math.max(num("ChampionWins"), num("Item_champion_wins"), isKeeper() and 1 or 0) end
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end
local function wiseDay() return num("Item_wise_day") end
local function wiseWins() return math.max(num("Item_wise_wins"), wiseDay() > 0 and 1 or 0) end
local function dateOfChampionDay(n)
	local CH = workspace:FindFirstChild("Champion")
	local launch = (CH and CH:GetAttribute("LaunchDay")) or 20721
	return os.date("!%B %d, %Y", (launch + n - 1) * 86400 + 12 * 3600)
end
local function dateOfDayIndex(d) return os.date("!%B %d, %Y", d * 86400 + 12 * 3600) end

-- ---------------------------------------------------------------- the case ----
local gui = Instance.new("ScreenGui"); gui.Name = "BadgeCase"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 25; gui.Enabled = false; gui.Parent = pg
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(10, 6, 20); shade.BackgroundTransparency = 0.45
shade.Text = ""; shade.AutoButtonColor = false; shade.BorderSizePixel = 0; shade.Parent = gui
local W, H = 470, 540
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5); card.Size = UDim2.fromOffset(W, H)
card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui
corner(card, UDim.new(0, 18)); stroke(card, GOLD, 3)
local scale = Instance.new("UIScale"); scale.Parent = card
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min((vp.Y - 24) / H, (vp.X - 24) / W), 0.4, 1)      -- a phone held sideways gets the whole case
end
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end)
label(card, "Your Badges", Enum.Font.Antique, 30, INK, 22, 14, 300, 36)
local close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -14, 0, 14); close.Size = UDim2.fromOffset(34, 34)
close.BackgroundColor3 = C(60, 50, 80); close.Font = Enum.Font.FredokaOne; close.TextSize = 20; close.TextColor3 = CREAM; close.Text = "X"; close.AutoButtonColor = true; close.Parent = card
corner(close, UDim.new(0, 10))

-- a special badge: a big medal on a ribbon, a word and a number (or a mark) on its face, and three lines beside it
local function makeSpecial(y)
	local s = {}
	s.frame = Instance.new("Frame"); s.frame.Position = UDim2.fromOffset(16, y); s.frame.Size = UDim2.fromOffset(W - 32, 138)
	s.frame.BackgroundColor3 = C(52, 42, 70); s.frame.BorderSizePixel = 0; s.frame.Parent = card
	corner(s.frame, UDim.new(0, 14))
	s.ribbon = {}
	for i, rot in ipairs({-18, 18}) do
		local r = Instance.new("Frame"); r.AnchorPoint = Vector2.new(0.5, 0); r.Position = UDim2.fromOffset(66 + (i == 1 and -13 or 13), 84); r.Size = UDim2.fromOffset(19, 46)
		r.Rotation = rot; r.BorderSizePixel = 0; r.Parent = s.frame
		s.ribbon[i] = r
	end
	s.big = Instance.new("Frame"); s.big.Position = UDim2.fromOffset(20, 10); s.big.Size = UDim2.fromOffset(92, 92); s.big.BorderSizePixel = 0; s.big.ZIndex = 2; s.big.Parent = s.frame
	corner(s.big, UDim.new(0.5, 0)); s.ring = stroke(s.big, C(150, 104, 30), 4)
	local inner = Instance.new("Frame"); inner.AnchorPoint = Vector2.new(0.5, 0.5); inner.Position = UDim2.fromScale(0.5, 0.5); inner.Size = UDim2.fromScale(0.78, 0.78)
	inner.BackgroundTransparency = 1; inner.ZIndex = 2; inner.Parent = s.big
	corner(inner, UDim.new(0.5, 0)); s.inner = stroke(inner, C(255, 236, 160), 2)
	s.word = label(s.big, "", Enum.Font.FredokaOne, 14, C(110, 70, 20), 0, 15, 92, 18, Enum.TextXAlignment.Center); s.word.ZIndex = 3
	s.mark = label(s.big, "", Enum.Font.FredokaOne, 38, C(90, 56, 14), 0, 32, 92, 44, Enum.TextXAlignment.Center); s.mark.ZIndex = 3
	-- the badge's own picture (shown instead of the drawn medal when there is one), and a small tag under it
	s.icon = Instance.new("ImageLabel"); s.icon.Position = UDim2.fromOffset(20, 8); s.icon.Size = UDim2.fromOffset(96, 96); s.icon.BackgroundTransparency = 1
	s.icon.ScaleType = Enum.ScaleType.Fit; s.icon.ZIndex = 4; s.icon.Visible = false; s.icon.Parent = s.frame
	corner(s.icon, UDim.new(0.5, 0))
	s.tag = Instance.new("TextLabel"); s.tag.AnchorPoint = Vector2.new(0.5, 0); s.tag.Position = UDim2.fromOffset(68, 104); s.tag.Size = UDim2.fromOffset(70, 22)
	s.tag.BackgroundColor3 = NAVY; s.tag.Font = Enum.Font.FredokaOne; s.tag.TextSize = 14; s.tag.TextColor3 = INK; s.tag.Text = ""; s.tag.ZIndex = 5
	s.tag.Visible = false; s.tag.Parent = s.frame
	corner(s.tag, UDim.new(0, 11)); stroke(s.tag, GOLD, 2)
	s.title = label(s.frame, "", Enum.Font.Antique, 23, INK, 130, 10, W - 32 - 144, 52)
	s.line = label(s.frame, "", Enum.Font.FredokaOne, 17, CREAM, 130, 66, W - 32 - 144, 22)
	s.note = label(s.frame, "", Enum.Font.FredokaOne, 13, DIM, 130, 90, W - 32 - 144, 42)
	return s
end
local function paint(s, owned, look, iconId)
	local pic = (tonumber(iconId) or 0) > 0
	s.icon.Visible = pic; s.big.Visible = not pic
	for _, r in ipairs(s.ribbon) do r.Visible = not pic end
	if pic then
		s.icon.Image = "rbxassetid://" .. tostring(iconId)
		s.icon.ImageColor3 = owned and C(255, 255, 255) or C(120, 116, 140)          -- still to win: dimmed
		s.icon.ImageTransparency = owned and 0 or 0.45
	end
	if owned then
		s.big.BackgroundColor3 = look.face; s.ring.Color = look.ring; s.inner.Color = look.inner
		for _, r in ipairs(s.ribbon) do r.BackgroundColor3 = look.ribbon end
		s.word.TextColor3 = look.ink; s.mark.TextColor3 = look.markInk or look.ink
		s.title.TextColor3 = INK
	else
		s.big.BackgroundColor3 = GREY; s.ring.Color = C(70, 64, 86); s.inner.Color = C(120, 112, 140)
		for _, r in ipairs(s.ribbon) do r.BackgroundColor3 = C(80, 70, 96) end
		s.word.TextColor3 = C(60, 56, 76); s.mark.TextColor3 = C(60, 56, 76)
		s.title.TextColor3 = DIM
	end
end
local KEEPER = {face = C(240, 196, 60), ring = C(150, 104, 30), inner = C(255, 236, 160), ribbon = C(196, 40, 52), ink = C(110, 70, 20), markInk = C(90, 56, 14)}
local WISE = {face = C(70, 110, 210), ring = C(30, 56, 130), inner = C(170, 200, 255), ribbon = C(128, 64, 186), ink = C(228, 238, 255), markInk = C(255, 214, 90)}
local keeper = makeSpecial(60)
local wise = makeSpecial(206)

-- the three area medals
label(card, "Area honours", Enum.Font.FredokaOne, 16, DIM, 22, 354, 300, 20)
local areaCells = {}
for i, a in ipairs(AREAS) do
	local cellW = math.floor((W - 32) / 3)
	local cell = Instance.new("Frame"); cell.BackgroundTransparency = 1; cell.Position = UDim2.fromOffset(16 + (i - 1) * cellW, 378); cell.Size = UDim2.fromOffset(cellW, 140); cell.Parent = card
	local m = medallion(cell, 56, a.colour); m.Position = UDim2.fromOffset(math.floor(cellW / 2) - 28, 0)
	local pic = Instance.new("ImageLabel"); pic.Size = UDim2.fromOffset(60, 60); pic.Position = UDim2.fromOffset(math.floor(cellW / 2) - 30, -2)
	pic.BackgroundTransparency = 1; pic.ScaleType = Enum.ScaleType.Fit; pic.Visible = false; pic.ZIndex = 3; pic.Parent = cell
	corner(pic, UDim.new(0.5, 0))
	local t = label(cell, a.title, Enum.Font.FredokaOne, 15, CREAM, 4, 62, cellW - 8, 38, Enum.TextXAlignment.Center)
	local sub = label(cell, "", Enum.Font.FredokaOne, 12, DIM, 4, 100, cellW - 8, 34, Enum.TextXAlignment.Center)
	areaCells[i] = {medal = m, pic = pic, title = t, sub = sub, colour = a.colour, map = a.map}
end

local function refresh()
	local no, have = championNo(), isKeeper()
	paint(keeper, have, KEEPER, iconOf("Icon_champion"))
	keeper.tag.Visible = no > 0 and iconOf("Icon_champion") > 0; keeper.tag.Text = ordinal(no):upper()   -- the number stays on the badge
	keeper.word.Text = "No."
	keeper.mark.Text = (no > 0) and tostring(no) or "?"
	keeper.title.Text = "Grand Keeper of the Great Acorn"
	if have then
		local d = num("ChampionDay")
		keeper.line.Text = ((no > 0) and (ordinal(no) .. " Grand Keeper") or "Grand Keeper") .. ((d > 0) and ("  -  " .. dateOfDayIndex(d)) or "")
		local wins = championWins()
		local all = num("ChampionTotal"); if all <= 0 then all = ALL end
		keeper.note.Text = "First to find all " .. tostring(all) .. " squirrels that day" .. ((wins > 1) and ("  -  won " .. tostring(wins) .. " times") or "")
	else
		keeper.line.Text = "Not yet yours"
		keeper.note.Text = "Be the first to find all " .. tostring(ALL) .. " squirrels in a day - your statue goes up by the fountain"
	end
	local d = wiseDay()
	paint(wise, d > 0, WISE, iconOf("Icon_wise"))
	wise.word.Text = "WISE"
	wise.mark.Text = "?"
	wise.title.Text = "Wise Squirrel"
	if d > 0 then
		wise.line.Text = dateOfDayIndex(d)
		local wins = wiseWins()
		wise.note.Text = "Drawn from the right answers to the Question of the Day" .. ((wins > 1) and ("  -  won " .. tostring(wins) .. " times") or "")
	else
		wise.line.Text = "Not yet yours"
		wise.note.Text = "Answer the Question of the Day at La Poste - one right answer is drawn every day at 6pm Eastern"
	end
	local tier = tonumber(player:GetAttribute("HonourTier")) or 0
	for i, cell in ipairs(areaCells) do
		local have = tier >= i
		cell.medal.BackgroundColor3 = have and cell.colour or GREY
		local icon = 0                                            -- the area medals stay the drawn acorns (Shannon: the pictures were too small to see)
		cell.pic.Visible = icon > 0; cell.medal.Visible = icon <= 0
		if icon > 0 then
			cell.pic.Image = "rbxassetid://" .. tostring(icon)
			cell.pic.ImageColor3 = have and C(255, 255, 255) or C(120, 116, 140)
			cell.pic.ImageTransparency = have and 0 or 0.45
		end
		cell.title.TextColor3 = have and CREAM or DIM
		cell.sub.Text = have and (NAME[cell.map] or "") or ("Find all " .. tostring(TOTAL[cell.map] or "?") .. " in " .. (NAME[cell.map] or "this area"))
	end
end

local function setOpen(on)
	if on then refresh(); fit() end
	gui.Enabled = on
end
shade.MouseButton1Click:Connect(function() setOpen(false) end)
close.MouseButton1Click:Connect(function() setOpen(false) end)

-- ---------------------------------------------------------------- how you open it ----
-- the title pill at the top of the screen (the honours' own) becomes a button, and badge holders get a medal beside it
local btnGui = Instance.new("ScreenGui"); btnGui.Name = "BadgeButton"; btnGui.ResetOnSpawn = false; btnGui.IgnoreGuiInset = true; btnGui.DisplayOrder = 5; btnGui.Parent = pg
local medalBtn = Instance.new("TextButton"); medalBtn.Name = "Medal"; medalBtn.Size = UDim2.fromOffset(34, 34)
medalBtn.Text = ""; medalBtn.AutoButtonColor = true; medalBtn.Visible = false; medalBtn.Parent = btnGui
corner(medalBtn, UDim.new(0.5, 0)); local mRing = stroke(medalBtn, C(150, 104, 30), 3)
local mRib = Instance.new("Frame"); mRib.Size = UDim2.fromOffset(10, 12); mRib.Position = UDim2.fromOffset(12, 30); mRib.BorderSizePixel = 0; mRib.ZIndex = 0; mRib.Parent = medalBtn
local mTxt = label(medalBtn, "", Enum.Font.FredokaOne, 15, C(90, 56, 14), 0, 8, 34, 18, Enum.TextXAlignment.Center)
local mImg = Instance.new("ImageLabel"); mImg.Size = UDim2.fromScale(1, 1); mImg.BackgroundTransparency = 1; mImg.ScaleType = Enum.ScaleType.Fit
mImg.Visible = false; mImg.ZIndex = 2; mImg.Parent = medalBtn
corner(mImg, UDim.new(0.5, 0))
medalBtn.MouseButton1Click:Connect(function() setOpen(not gui.Enabled) end)
local pill
local function placeMedal()
	local n, d = championNo(), wiseDay()
	medalBtn.Visible = isKeeper() or d > 0
	if isKeeper() then
		medalBtn.BackgroundColor3 = KEEPER.face; mRing.Color = KEEPER.ring; mRib.BackgroundColor3 = KEEPER.ribbon
		mTxt.Text = (n > 0) and tostring(n) or ""; mTxt.TextColor3 = KEEPER.markInk
	elseif d > 0 then
		medalBtn.BackgroundColor3 = WISE.face; mRing.Color = WISE.ring; mRib.BackgroundColor3 = WISE.ribbon
		mTxt.Text = "?"; mTxt.TextColor3 = WISE.markInk
	end
	local icon = 0                                             -- the little medal by the title stays drawn too: a picture that small does not read
	mImg.Visible = icon > 0; mTxt.Visible = icon <= 0; mRib.Visible = icon <= 0
	if icon > 0 then mImg.Image = "rbxassetid://" .. tostring(icon) end
	if pill and pill.Visible then
		medalBtn.Position = UDim2.new(0.5, pill.AbsoluteSize.X / 2 + 8, 0, 15)
	else
		medalBtn.Position = UDim2.new(0.5, -17, 0, 15)
	end
end
task.spawn(function()
	local bar = pg:WaitForChild("HonourBar", 60)
	pill = bar and bar:WaitForChild("Pill", 30)
	if pill then
		local hit = Instance.new("TextButton"); hit.Name = "OpenBadges"; hit.BackgroundTransparency = 1; hit.Text = ""; hit.Size = UDim2.fromScale(1, 1); hit.ZIndex = 10; hit.Parent = pill
		hit.MouseButton1Click:Connect(function() setOpen(not gui.Enabled) end)
		pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeMedal)
		pill:GetPropertyChangedSignal("Visible"):Connect(placeMedal)
	end
	placeMedal()
end)

-- ---------------------------------------------------------------- a new badge: say so ----
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118); toast.Size = UDim2.fromOffset(440, 44)
toast.BackgroundColor3 = NAVY; toast.BackgroundTransparency = 0.1; toast.Font = Enum.Font.FredokaOne; toast.TextSize = 18; toast.TextColor3 = INK; toast.TextWrapped = true
toast.Text = ""; toast.Visible = false; toast.Parent = btnGui
corner(toast, UDim.new(0, 14)); stroke(toast, GOLD, 2)
local function newBadge(textLine)
	task.delay(7, function()                                      -- after the celebration banner has had its moment
		toast.Text = textLine
		toast.Visible = true
		medalBtn.Size = UDim2.fromOffset(46, 46)
		TweenService:Create(medalBtn, TweenInfo.new(0.6, Enum.EasingStyle.Elastic), {Size = UDim2.fromOffset(34, 34)}):Play()
		task.delay(6, function() toast.Visible = false end)
	end)
end
local lastNo, lastWise = championNo(), wiseDay()
player:GetAttributeChangedSignal("Item_champion_day"):Connect(function()
	placeMedal()
	if gui.Enabled then refresh() end
end)
-- the number arrives from the server's hall on every join; "new badge" is only for a win just now (ChampionNew)
player:GetAttributeChangedSignal("ChampionNo"):Connect(function()
	local no = championNo()
	placeMedal()
	if no > 0 and no ~= lastNo and player:GetAttribute("ChampionNew") then newBadge("New badge: " .. ordinal(no) .. " Grand Keeper!  Tap your title to see it.") end
	lastNo = no
	if gui.Enabled then refresh() end
end)
player:GetAttributeChangedSignal("Item_wise_day"):Connect(function()
	local d = wiseDay()
	placeMedal()
	if d > 0 and lastWise <= 0 then newBadge("New badge: Wise Squirrel!  Tap your title to see it.") end
	lastWise = d
	if gui.Enabled then refresh() end
end)
F.AttributeChanged:Connect(function() placeMedal(); if gui.Enabled then refresh() end end)
for _, a in ipairs({"Item_champion_wins", "Item_wise_wins", "HonourTier", "ChampionWins", "ChampionDay", "ChampionTotal"}) do
	player:GetAttributeChangedSignal(a):Connect(function() if gui.Enabled then refresh() end end)
end
]==]
	local c = Instance.new("Script"); c.Name = "BadgeCaseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print("BadgeCase: installed - tap the title pill (or the medal beside it) to open the case")
	return F
end

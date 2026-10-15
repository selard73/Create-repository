-- BottleClient (Script, RunContext Client; in workspace.Bottles). The stand's writing panel, the toss, the reply bottle by the stand
-- (only its sender sees it), and the note card for every bottle opened. Job 118. All the words come from BottleText.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local Text = require(F:WaitForChild("BottleText"))
local ev = F:WaitForChild("BottleEvent")
local RGB = Color3.fromRGB
local FACE, RIM, PAPER = RGB(250, 241, 219), RGB(118, 80, 46), RGB(255, 250, 236)
local SLOT, INK, INK_DIM, GOLD, BTN_INK, SEA = RGB(228, 212, 179), RGB(64, 42, 22), RGB(132, 108, 80), RGB(255, 202, 62), RGB(84, 48, 18), RGB(40, 118, 160)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end
local function stroke(o, col, th) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o end
local function label(parent, text, x, y, w, h, size, colour, align)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, h); l.BackgroundTransparency = 1
	l.FontFace = FONT; l.TextSize = size; l.TextColor3 = colour or INK; l.Text = text; l.TextWrapped = true
	l.TextXAlignment = align or Enum.TextXAlignment.Left; l.ZIndex = 4; l.Parent = parent
	return l
end
local function button(parent, text, x, y, w, h, fill, size)
	local b = Instance.new("TextButton"); b.Position = UDim2.fromOffset(x, y); b.Size = UDim2.fromOffset(w, h); b.BackgroundColor3 = fill or GOLD
	b.BorderSizePixel = 0; b.FontFace = FONT; b.TextSize = size or 18; b.TextColor3 = BTN_INK; b.Text = text; b.AutoButtonColor = true; b.ZIndex = 4; b.Parent = parent
	corner(b, 10); stroke(b, RGB(150, 98, 36), 2)
	return b
end
local function fit(frame, w, h)
	local sc = Instance.new("UIScale"); sc.Parent = frame
	local function upd()
		local cam = workspace.CurrentCamera; local v = cam and cam.ViewportSize or Vector2.new(1000, 800)
		sc.Scale = math.clamp(math.min((v.X - 24) / w, (v.Y - 40) / h), 0.5, 1)
	end
	upd(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(upd) end
end
for _, n in ipairs({"BottleGui"}) do local g = pg:FindFirstChild(n); if g then g:Destroy() end end
local gui = Instance.new("ScreenGui"); gui.Name = "BottleGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 8; gui.Parent = pg
-- ---------- the toast ----------
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -150); toast.Size = UDim2.fromOffset(420, 44)
toast.BackgroundColor3 = RGB(38, 30, 52); toast.BackgroundTransparency = 1; toast.TextTransparency = 1; toast.FontFace = FONT; toast.TextSize = 17
toast.TextColor3 = RGB(255, 244, 214); toast.TextWrapped = true; toast.ZIndex = 10; toast.Parent = gui
corner(toast, 14)
local toastAt = 0
local function say(text, secs)
	toast.Text = text; toast.BackgroundTransparency = 0.15; toast.TextTransparency = 0
	local mine = os.clock(); toastAt = mine
	task.delay(secs or 3.5, function()
		if toastAt ~= mine then return end
		TweenService:Create(toast, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
	end)
end
-- ---------- the note card (every bottle opened) ----------
local note = Instance.new("Frame"); note.AnchorPoint = Vector2.new(0.5, 0.5); note.Position = UDim2.fromScale(0.5, 0.5); note.Size = UDim2.fromOffset(400, 300)
note.BackgroundColor3 = PAPER; note.BorderSizePixel = 0; note.Visible = false; note.ZIndex = 3; note.Parent = gui
corner(note, 18); stroke(note, RIM, 3); fit(note, 400, 300)
local nHead = label(note, "", 20, 16, 360, 30, 22, SEA, Enum.TextXAlignment.Center)
local nBody = label(note, "", 26, 56, 348, 140, 19, INK, Enum.TextXAlignment.Center); nBody.TextYAlignment = Enum.TextYAlignment.Center
local nSign = label(note, "", 26, 198, 348, 24, 15, INK_DIM, Enum.TextXAlignment.Right)
local nPrize = label(note, "", 26, 224, 348, 20, 15, RGB(176, 120, 20), Enum.TextXAlignment.Center)
local nClose = button(note, "Lovely!", 140, 250, 120, 38)
local function chime()
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9116394876"; s.Volume = 0.3; s.PlaybackSpeed = 1.1; s.Parent = gui; s:Play(); Debris:AddItem(s, 4)
end
local function showNote(head, body, sign, prize)
	nHead.Text = head; nBody.Text = body; nSign.Text = sign and ("- " .. sign) or ""; nPrize.Text = prize or ""
	note.Visible = true; pg:SetAttribute("OpenPanel", "bottle"); chime()
end
nClose.Activated:Connect(function() note.Visible = false; if pg:GetAttribute("OpenPanel") == "bottle" then pg:SetAttribute("OpenPanel", nil) end end)
-- ---------- the writing panel ----------
local W, H = 440, 470
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = RGB(20, 12, 6); shade.BackgroundTransparency = 0.5
shade.Text = ""; shade.AutoButtonColor = false; shade.BorderSizePixel = 0; shade.Visible = false; shade.ZIndex = 1; shade.Parent = gui
local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5); panel.Size = UDim2.fromOffset(W, H)
panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.Visible = false; panel.ZIndex = 2; panel.Parent = gui
corner(panel, 18); stroke(panel, RIM, 3); fit(panel, W, H)
label(panel, "Messaggi in Bottiglia", 20, 14, 340, 30, 24, INK)
label(panel, "Write a note, cork it, and toss it out to sea", 20, 44, 400, 20, 14, INK_DIM)
local close = button(panel, "X", W - 52, 14, 36, 36, SLOT, 20)
local status = label(panel, "", 20, 70, 400, 36, 15, SEA)
local choice = {to = 1, card = 1, a = 1, b = 1}
local rows = {}
local function cycler(y, title, get, count, set)
	label(panel, title, 20, y + 8, 70, 24, 16, INK_DIM)
	local prev = button(panel, "<", 90, y, 40, 40, SLOT, 22)
	local mid = Instance.new("TextLabel"); mid.Position = UDim2.fromOffset(136, y); mid.Size = UDim2.fromOffset(238, 40); mid.BackgroundColor3 = PAPER
	mid.BorderSizePixel = 0; mid.FontFace = FONT; mid.TextSize = 16; mid.TextColor3 = INK; mid.TextWrapped = true; mid.ZIndex = 4; mid.Parent = panel
	corner(mid, 8)
	local nxt = button(panel, ">", 380, y, 40, 40, SLOT, 22)
	local row = {mid = mid, get = get}
	prev.Activated:Connect(function() set(((get() - 2) % count()) + 1) end)
	nxt.Activated:Connect(function() set((get() % count()) + 1) end)
	table.insert(rows, row)
	return row
end
local preview, send
local function card() return Text.CARDS[choice.card] end
local function refresh()
	rows[1].mid.Text = Text.TO[choice.to].label
	rows[2].mid.Text = "Note " .. choice.card .. ": " .. card().text:gsub("{A}", "___"):gsub("{B}", "___")
	rows[3].mid.Text = card().A[choice.a]
	rows[4].mid.Text = card().B[choice.b]
	preview.Text = Text.message(choice.to, choice.card, choice.a, choice.b)
end
cycler(112, "To:", function() return choice.to end, function() return #Text.TO end, function(v) choice.to = v; refresh() end)
cycler(160, "Note:", function() return choice.card end, function() return #Text.CARDS end, function(v) choice.card = v; choice.a = 1; choice.b = 1; refresh() end)
cycler(208, "Blank 1:", function() return choice.a end, function() return #card().A end, function(v) choice.a = v; refresh() end)
cycler(256, "Blank 2:", function() return choice.b end, function() return #card().B end, function(v) choice.b = v; refresh() end)
local paper = Instance.new("Frame"); paper.Position = UDim2.fromOffset(20, 306); paper.Size = UDim2.fromOffset(400, 92); paper.BackgroundColor3 = PAPER
paper.BorderSizePixel = 0; paper.ZIndex = 3; paper.Parent = panel
corner(paper, 10); stroke(paper, RGB(196, 170, 120), 1.5)
preview = label(paper, "", 12, 8, 376, 76, 17, INK, Enum.TextXAlignment.Center); preview.TextYAlignment = Enum.TextYAlignment.Center
send = button(panel, "Cork it & toss it!", 90, 410, 260, 44)
local st = {}
local function setStatus()
	if st.sentDay and st.replyReady then status.Text = "A reply to your bottle has washed up by the stand. Go and read it!"; send.Visible = false
	elseif st.sentDay then status.Text = "Your bottle is out at sea. A reply will wash up here tomorrow!"; send.Visible = false
	else status.Text = "One bottle a day. A reply washes up tomorrow."; send.Visible = true; send.Text = string.format("Cork it & toss it! (%d acorns)", st.cost or 15) end
end
local function open()
	ev:FireServer("state")
	refresh(); setStatus()
	shade.Visible = true; panel.Visible = true; pg:SetAttribute("OpenPanel", "bottle")
end
local function closePanel() shade.Visible = false; panel.Visible = false; if pg:GetAttribute("OpenPanel") == "bottle" then pg:SetAttribute("OpenPanel", nil) end end
close.Activated:Connect(closePanel); shade.Activated:Connect(closePanel)
send.Activated:Connect(function() ev:FireServer("send", choice.to, choice.card, choice.a, choice.b) end)
-- ---------- the bottle in the world (the toss, the reply) ----------
local stand = F:WaitForChild("Stand", 60)
local template = RS:WaitForChild("BottleTemplate", 60)
local function standCF() return stand and stand:GetPivot() or CFrame.new() end
local function seaward()                                                  -- the stand's back faces the sea
	local cf = standCF(); return -cf.LookVector
end
local function toss()
	if not template then return end
	local b = template:Clone(); b.Name = "TossedBottle"
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("ProximityPrompt") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	local from = standCF().Position + Vector3.new(0, 4, 0)
	local to = from + seaward() * 42 + Vector3.new(0, -5, 0)
	b:PivotTo(CFrame.new(from)); b.Parent = workspace
	local v = Instance.new("NumberValue"); v.Value = 0
	v.Changed:Connect(function(t)
		local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 14, 0)
		b:PivotTo(CFrame.new(p) * CFrame.Angles(t * 9, 0, t * 4))
	end)
	local tw = TweenService:Create(v, TweenInfo.new(1.6, Enum.EasingStyle.Linear), {Value = 1}); tw:Play()
	tw.Completed:Connect(function() b:Destroy(); v:Destroy() end)
end
local replyBottle
local function placeReply(want)
	if not want then if replyBottle then replyBottle:Destroy(); replyBottle = nil end return end
	if replyBottle or not template then return end
	local spot
	pcall(function() spot = HttpService:JSONDecode(F:GetAttribute("ReplySpot") or "null") end)
	local pos = spot and Vector3.new(spot[1], spot[2] + 0.35, spot[3]) or (standCF().Position + seaward() * 8)
	local b = template:Clone(); b.Name = "ReplyBottle"
	b:PivotTo(CFrame.new(pos) * CFrame.Angles(0, 0.6, math.rad(8))); b.Parent = workspace   -- lying on its side
	local prompt = b:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then prompt.ObjectText = "A reply to your bottle!"; prompt.ActionText = "Read it"; prompt.Triggered:Connect(function() ev:FireServer("reply") end) end
	local glow = Instance.new("Highlight"); glow.FillColor = GOLD; glow.OutlineColor = RGB(255, 236, 160); glow.FillTransparency = 0.7; glow.Parent = b
	replyBottle = b
end
local told = false
ev.OnClientEvent:Connect(function(what, a, b, c, d, e)
	if what == "state" then
		st = type(a) == "table" and a or {}
		setStatus(); placeReply(st.replyReady == true)
		if st.replyReady and not told then told = true; task.delay(4, function() say("A reply to your bottle has washed up by the bottle stand on the beach!", 5) end) end
	elseif what == "sent" then
		closePanel(); toss()
		task.delay(1.7, function() say("Off it goes! Check the beach tomorrow for a reply.", 4) end)
	elseif what == "reply" then
		if replyBottle then replyBottle:Destroy(); replyBottle = nil end
		local body, sign = Text.reply(a, b, c, d, e or 0)
		showNote("A reply washed up!", body, sign, "You wrote: " .. Text.CARDS[b].text:gsub("{A}", Text.CARDS[b].A[c]):gsub("{B}", Text.CARDS[b].B[d]))
	elseif what == "beach" then
		local n = Text.BEACH[a]
		if n then showNote("A message in a bottle!", n[1], n[2], (b or 0) > 0 and ("+" .. b .. " acorns") or "You've found all the paid bottles for today - this one's just for fun") end
	elseif what == "msg" then
		say(tostring(a), 4)
	end
end)
local prompt = stand and stand:FindFirstChild("WritePrompt", true)
if prompt then prompt.Triggered:Connect(open) end
ev:FireServer("state")

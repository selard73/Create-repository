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
		sc.Scale = math.clamp(math.min((v.X - 24) / w, (v.Y - 110) / h), 0.5, 1)   -- (round 2: 110 px kept clear for the top HUD bar)
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
local NW, NH = 420, 340                                                    -- (round 3b: Dear <name> and a one-line reply)
local note = Instance.new("Frame"); note.AnchorPoint = Vector2.new(0.5, 0.5); note.Position = UDim2.new(0.5, 0, 0.5, 24); note.Size = UDim2.fromOffset(NW, NH)
note.BackgroundColor3 = PAPER; note.BorderSizePixel = 0; note.Visible = false; note.ZIndex = 3; note.Parent = gui
corner(note, 18); stroke(note, RIM, 3); fit(note, NW, NH)
local nHead = label(note, "", 20, 14, NW - 40, 30, 22, SEA, Enum.TextXAlignment.Center)
local nBody = label(note, "", 26, 50, NW - 52, 120, 19, INK, Enum.TextXAlignment.Center); nBody.TextYAlignment = Enum.TextYAlignment.Center
nBody.TextScaled = true; do local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 20; c.MinTextSize = 12; c.Parent = nBody end
local nSign = label(note, "", 26, 176, NW - 52, 22, 15, INK_DIM, Enum.TextXAlignment.Right)
local nPrize = label(note, "", 26, 204, NW - 52, 64, 14, RGB(150, 104, 20), Enum.TextXAlignment.Center); nPrize.TextYAlignment = Enum.TextYAlignment.Top
nPrize.TextScaled = true; do local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 15; c.MinTextSize = 10; c.Parent = nPrize end
local nClose = button(note, "Lovely!", (NW - 130) / 2, 282, 130, 40)
local function chime()
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9116394876"; s.Volume = 0.3; s.PlaybackSpeed = 1.1; s.Parent = gui; s:Play(); Debris:AddItem(s, 4)
end
local function showNote(head, body, sign, prize)
	nHead.Text = head; nBody.Text = body; nSign.Text = sign and ("- " .. sign) or ""; nPrize.Text = prize or ""
	note.Visible = true; pg:SetAttribute("OpenPanel", "bottle"); chime()
end
nClose.Activated:Connect(function() note.Visible = false; if pg:GetAttribute("OpenPanel") == "bottle" then pg:SetAttribute("OpenPanel", nil) end end)
-- ---------- the writing panel ----------
local W, H = 640, 330                                                      -- (round 2: wide and short, two columns - a landscape phone keeps ~0.9 scale)
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = RGB(20, 12, 6); shade.BackgroundTransparency = 0.5
shade.Text = ""; shade.AutoButtonColor = false; shade.BorderSizePixel = 0; shade.Visible = false; shade.ZIndex = 1; shade.Parent = gui
local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.new(0.5, 0, 0.5, 24); panel.Size = UDim2.fromOffset(W, H)
panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.Visible = false; panel.ZIndex = 2; panel.Parent = gui
corner(panel, 18); stroke(panel, RIM, 3); fit(panel, W, H)
label(panel, "Messaggi in Bottiglia", 20, 12, 420, 30, 24, INK)
local close = button(panel, "X", W - 52, 12, 38, 38, SLOT, 20)
local status = label(panel, "", 20, 46, W - 80, 22, 15, SEA)
local choice = {to = 1, card = 1, a = 1, b = 1, q = 1}
local rows = {}
local function cycler(y, title, get, count, set)
	label(panel, title, 20, y + 10, 70, 24, 15, INK_DIM)
	local prev = button(panel, "<", 92, y, 40, 44, SLOT, 22)
	local mid = Instance.new("TextLabel"); mid.Position = UDim2.fromOffset(138, y); mid.Size = UDim2.fromOffset(170, 44); mid.BackgroundColor3 = PAPER
	mid.BorderSizePixel = 0; mid.FontFace = FONT; mid.TextScaled = true; mid.TextColor3 = INK; mid.TextWrapped = true; mid.ZIndex = 4; mid.Parent = panel
	local mc = Instance.new("UITextSizeConstraint"); mc.MaxTextSize = 17; mc.MinTextSize = 10; mc.Parent = mid
	local mp = Instance.new("UIPadding"); mp.PaddingLeft = UDim.new(0, 6); mp.PaddingRight = UDim.new(0, 6); mp.Parent = mid
	corner(mid, 8)
	local nxt = button(panel, ">", 314, y, 40, 44, SLOT, 22)
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
	rows[2].mid.Text = "Note " .. choice.card .. " of " .. #Text.CARDS        -- (round 2: the whole sentence is in the preview)
	rows[3].mid.Text = card().A[choice.a]
	rows[4].mid.Text = card().B[choice.b]
	rows[5].mid.Text = Text.QUESTIONS[choice.q]
	preview.Text = Text.message(choice.to, choice.card, choice.a, choice.b, choice.q, player.DisplayName)
end
cycler(76, "To:", function() return choice.to end, function() return #Text.TO end, function(v) choice.to = v; refresh() end)
cycler(124, "Note:", function() return choice.card end, function() return #Text.CARDS end, function(v) choice.card = v; choice.a = 1; choice.b = 1; refresh() end)
cycler(172, "Blank 1:", function() return choice.a end, function() return #card().A end, function(v) choice.a = v; refresh() end)
cycler(220, "Blank 2:", function() return choice.b end, function() return #card().B end, function(v) choice.b = v; refresh() end)
cycler(268, "Ask:", function() return choice.q end, function() return #Text.QUESTIONS end, function(v) choice.q = v; refresh() end)   -- (round 3: they answer it tomorrow)
local paper = Instance.new("Frame"); paper.Position = UDim2.fromOffset(372, 76); paper.Size = UDim2.fromOffset(W - 392, 180); paper.BackgroundColor3 = PAPER
paper.BorderSizePixel = 0; paper.ZIndex = 3; paper.Parent = panel
corner(paper, 10); stroke(paper, RGB(196, 170, 120), 1.5)
preview = label(paper, "", 12, 10, W - 416, 160, 18, INK, Enum.TextXAlignment.Center); preview.TextYAlignment = Enum.TextYAlignment.Center
preview.TextScaled = true; local pc = Instance.new("UITextSizeConstraint"); pc.MaxTextSize = 19; pc.MinTextSize = 11; pc.Parent = preview
send = button(panel, "Cork it & toss it!", 372, 268, W - 392, 44)
send.TextScaled = true; local sc2 = Instance.new("UITextSizeConstraint"); sc2.MaxTextSize = 18; sc2.MinTextSize = 11; sc2.Parent = send
local sp2 = Instance.new("UIPadding"); sp2.PaddingLeft = UDim.new(0, 8); sp2.PaddingRight = UDim.new(0, 8); sp2.Parent = send
local st = {}
local function setStatus()
	if st.sentDay and st.replyReady then status.Text = "A reply to your bottle is waiting right here by the kiosk. Go and read it!"; send.Visible = false
	elseif st.sentDay then status.Text = "Your bottle is out at sea. A reply will wash up here tomorrow!"; send.Visible = false
	else status.Text = "One bottle a day. A reply washes up tomorrow."; send.Visible = true; send.Text = string.format("Cork it & toss it! (%d acorns)", st.cost or 15) end
end
local function open()
	ev:FireServer("state")
	refresh(); setStatus()
	shade.Visible = true; panel.Visible = true; pg:SetAttribute("OpenPanel", "bottle")
	toastAt = 0; toast.BackgroundTransparency = 1; toast.TextTransparency = 1          -- (round 5: no toast left over the panel)
end
local function closePanel() shade.Visible = false; panel.Visible = false; if pg:GetAttribute("OpenPanel") == "bottle" then pg:SetAttribute("OpenPanel", nil) end end
close.Activated:Connect(closePanel); shade.Activated:Connect(closePanel)
send.Activated:Connect(function() ev:FireServer("send", choice.to, choice.card, choice.a, choice.b, choice.q) end)
-- ---------- the bottle in the world (the toss, the reply) ----------
local stand = F:WaitForChild("Stand", 60)
local template = RS:WaitForChild("BottleTemplate", 60)
local function standCF() return stand and stand:GetPivot() or CFrame.new() end
local function seaward()                                                  -- the stand's back faces the sea
	local cf = standCF(); return -cf.LookVector
end
local function toss()                                                      -- (round 5, Shannon: "so quick you can't tell what is happening") ~7 s:
	if not template then return end                                        -- the shore, a big bottle flying out, the camera following it, the
	local view                                                             -- landing, a long bob out to sea
	pcall(function() view = HttpService:JSONDecode(F:GetAttribute("TossView") or "null") end)
	local b = template:Clone(); b.Name = "TossedBottle"
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("ProximityPrompt") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	pcall(function() b:ScaleTo(2.2) end)                                    -- big enough to see from the shore
	local glass = b:FindFirstChild("Glass")
	if glass then local sp = Instance.new("Sparkles"); sp.SparkleColor = Color3.fromRGB(255, 240, 180); sp.Parent = glass end
	local from, to, camAt
	if view then
		from, to, camAt = Vector3.new(view.from[1], view.from[2], view.from[3]), Vector3.new(view.to[1], view.to[2], view.to[3]), Vector3.new(view.cam[1], view.cam[2], view.cam[3])
	else
		from = standCF().Position + Vector3.new(0, 4, 0); to = from + seaward() * 42 + Vector3.new(0, -5, 0)
	end
	local cam = workspace.CurrentCamera
	local before = cam and cam.CFrame
	local function look(at) if camAt and cam then cam.CFrame = CFrame.lookAt(camAt, at) end end
	if camAt and cam then cam.CameraType = Enum.CameraType.Scriptable end
	b:PivotTo(CFrame.new(from) * CFrame.Angles(0, 0, math.rad(60))); b.Parent = F
	look(from:Lerp(to, 0.3))
	task.wait(0.9)                                                         -- a moment on the shore with the bottle before it goes
	local v = Instance.new("NumberValue"); v.Value = 0
	v.Changed:Connect(function(t)
		local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 14, 0)
		b:PivotTo(CFrame.new(p) * CFrame.Angles(t * 6, 0, math.rad(60) + t * 3))
		look(p:Lerp(to, 0.25))
	end)
	local tw = TweenService:Create(v, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = 1}); tw:Play()
	tw.Completed:Wait()
	-- the landing: a splash of spray and the toss sound, then a long bob out to sea
	local sp = Instance.new("Part"); sp.Anchored = true; sp.CanCollide = false; sp.CanQuery = false; sp.CanTouch = false; sp.Transparency = 1; sp.Size = Vector3.new(1, 1, 1)
	sp.CFrame = CFrame.new(to); sp.Parent = F
	local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(10, 16); e.SpreadAngle = Vector2.new(35, 35); e.EmissionDirection = Enum.NormalId.Top
	e.Lifetime = NumberRange.new(0.6, 1.1); e.Acceleration = Vector3.new(0, -30, 0); e.Size = NumberSequence.new(0.9, 0.2); e.Color = ColorSequence.new(Color3.fromRGB(230, 245, 255))
	e.Transparency = NumberSequence.new(0.1, 1); e.Parent = sp; e:Emit(60); Debris:AddItem(sp, 2.5)
	local sid = tostring(F:GetAttribute("TossSound") or "")
	if sid ~= "" then local s = Instance.new("Sound"); s.SoundId = sid; s.Volume = 0.45; s.PlaybackSpeed = 0.9; s.Parent = gui; s:Play(); Debris:AddItem(s, 4) end
	local drift = Instance.new("NumberValue"); drift.Value = 0
	local away = (to - from) * Vector3.new(1, 0, 1); away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, -1)
	drift.Changed:Connect(function(t)
		local p = to + away * t * 16 + Vector3.new(0, math.sin(t * 14) * 0.4 - 0.3, 0)
		b:PivotTo(CFrame.new(p) * CFrame.Angles(0, t * 1.5, math.rad(80) + math.sin(t * 9) * 0.2))
		look(p)
	end)
	local tw2 = TweenService:Create(drift, TweenInfo.new(3.0, Enum.EasingStyle.Linear), {Value = 1}); tw2:Play()
	tw2.Completed:Wait()
	task.wait(0.3)
	b:Destroy(); v:Destroy(); drift:Destroy()
	if camAt and cam then
		cam.CameraType = Enum.CameraType.Custom
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then cam.CameraSubject = h end
		if before then cam.CFrame = before end
	end
end
local replyBottle
local function placeReply(want)
	if not want then if replyBottle then replyBottle:Destroy(); replyBottle = nil end return end
	if replyBottle or not template then return end
	local spot
	pcall(function() spot = HttpService:JSONDecode(F:GetAttribute("ReplySpot") or "null") end)
	local pos = spot and Vector3.new(spot[1], spot[2] + 0.35, spot[3]) or (standCF().Position + seaward() * 8)
	local b = template:Clone(); b.Name = "ReplyBottle"
	b:PivotTo(CFrame.new(pos) * CFrame.Angles(0, 0.6, math.rad(8))); b.Parent = F   -- lying on its side; (round 2: kept in the game's folder)
	local prompt = b:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then prompt.ObjectText = "A reply to your bottle!"; prompt.ActionText = "Read it"; prompt.MaxActivationDistance = 14; prompt.Triggered:Connect(function() ev:FireServer("reply") end) end
	local glow = Instance.new("Highlight"); glow.FillColor = GOLD; glow.OutlineColor = RGB(255, 236, 160); glow.FillTransparency = 0.7; glow.Parent = b
	replyBottle = b
end
local told = false
ev.OnClientEvent:Connect(function(what, a, b, c, d, e, f, g)
	if what == "state" then
		st = type(a) == "table" and a or {}
		setStatus(); placeReply(st.replyReady == true)
		if st.replyReady and not told then told = true; task.delay(4, function() say("A reply to your bottle is waiting at the bottle kiosk by the boat club!", 5) end) end
	elseif what == "sent" then
		closePanel()
		task.spawn(toss)
		task.delay(4.2, function() say("Off it goes! Come back to the kiosk tomorrow for a reply.", 4) end)   -- (round 5: as it lands)
	elseif what == "reply" then
		if replyBottle then replyBottle:Destroy(); replyBottle = nil end
		local q, info = f, g
		local body, sign = Text.reply(a, b, c, d, e or 0, q, info, player.DisplayName)
		local wrote = Text.CARDS[b].text:gsub("{A}", Text.CARDS[b].A[c]):gsub("{B}", Text.CARDS[b].B[d])
		if q and Text.QUESTIONS[q] then wrote ..= " " .. Text.QUESTIONS[q] end
		showNote("A reply washed up!", body, sign, "You wrote: " .. wrote)
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

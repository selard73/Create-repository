-- FRENCH_QUESTION_REMINDERS_20261002_V1
local function frenchQuestionReminderAllowed()
    local area = game:GetService("Players").LocalPlayer:GetAttribute("Area")
    return area == "forest" or area == "village" or area == "domaine"
end
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
local title,kind,close,qText,buttons,status,clock,yline
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	if not title then return end
	scale.Scale=1
	local w=math.min(700,vp.X-28);local h=math.min(262,math.max(213,vp.Y-160))
	card.Size=UDim2.fromOffset(w,h);card.Position=UDim2.new(.5,0,0,68)
	title.Position=UDim2.fromOffset(14,7);title.Size=UDim2.fromOffset(w-80,26);title.TextSize=20
	kind.Visible=false
	close.Size=UDim2.fromOffset(44,44);close.Position=UDim2.new(1,-6,0,4)
	qText.Position=UDim2.fromOffset(14,37);qText.Size=UDim2.fromOffset(w-80,32)
	local bw=(w-38)/2
	for i,e in ipairs(buttons)do e.btn.Position=UDim2.fromOffset(14+((i-1)%2)*(bw+10),73+math.floor((i-1)/2)*48);e.btn.Size=UDim2.fromOffset(bw,44)end
	status.Position=UDim2.fromOffset(14,168);status.Size=UDim2.fromOffset(w-28,27)
	clock.Position=UDim2.fromOffset(14,198);clock.Size=UDim2.fromOffset(w-28,14);clock.TextSize=11
	yline.Visible=h>=242;yline.Position=UDim2.fromOffset(14,224);yline.Size=UDim2.fromOffset(w-28,26)

end
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end)
title = text(card, "Question of the Day", Enum.Font.Antique, 24, INK, 18, 8, 400, 26)
kind = text(card, "", Enum.Font.FredokaOne, 13, DIM, 18, 33, 400, 16)
close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -12, 0, 12); close.Size = UDim2.fromOffset(30, 30)
close.BackgroundColor3 = C(60, 50, 80); close.Font = Enum.Font.FredokaOne; close.TextSize = 18; close.TextColor3 = CREAM; close.Text = "X"; close.Parent = card
corner(close, UDim.new(0, 9))
qText = text(card, "", Enum.Font.FredokaOne, 21, CREAM, 18, 52, W - 36, 44, nil, true, 8)
buttons = {}
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
status = text(card, "", Enum.Font.FredokaOne, 15, INK, 18, 193, W - 36, 30, Enum.TextXAlignment.Center, true, 7)
clock = text(card, "", Enum.Font.FredokaOne, 13, DIM, 18, 225, W - 36, 16, Enum.TextXAlignment.Center)
yline = text(card, "", Enum.Font.FredokaOne, 12, DIM, 18, 243, W - 36, 14, Enum.TextXAlignment.Center, true, 6)

fit()
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
local latestStatus,remind
local refreshing = false
local function refreshPrompts()
	if refreshing then return end
	refreshing = true
	local ok, st = pcall(function() return action:InvokeServer("status") end)
	refreshing = false
	if not (ok and type(st) == "table" and st.ok) then return end
	latestStatus=st
	pg:SetAttribute("QuestionRound",st.round);pg:SetAttribute("QuestionCloses",st.closes)
	pg:SetAttribute("QuestionForest",st.forest);pg:SetAttribute("QuestionPoste",st.poste)
	doneToday = {forest = st.forest ~= "open", poste = st.poste ~= "open"}
	applyPrompts()
	if remind then task.defer(remind)end
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
	while true do task.wait(latestStatus and 60 or 5); refreshPrompts() end
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
	if ok and type(res) == "table" and res.ok then data = res; render()
	else qText.Text="The question is loading. Please try again in a moment." end
	return data
end
local function boardFace(b)
	local m = F:FindFirstChild("Board_" .. tostring(b))
	return m and m:FindFirstChild("Face")
end
local fromPassport=false
local function setOpen(on, b, anywhere)
	fromPassport=on and anywhere==true
	if on then pg:SetAttribute("OpenPanel","question") elseif pg:GetAttribute("OpenPanel")=="question"then pg:SetAttribute("OpenPanel",nil)end
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
			doneToday[data.board] = true; applyPrompts();task.defer(refreshPrompts)                -- answered: this board's button goes for today
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
			if not fromPassport and face and hrp and (hrp.Position - face.Position).Magnitude > (F:GetAttribute("CloseDistance") or 16) then setOpen(false) end
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
toast.Name = "QuestionReminder"; toast.Text = ""; toast.Visible = false; toast.Parent = news
corner(toast, UDim.new(0, 14)); stroke(toast, GOLD, 2)
local toastAt = 0
-- ON A PHONE the note finds a clear place (Shannon, Sep 26: "it should be higher so it doesn't collide with the start the
-- race"; "Ideally on that phone, nothing should be overlapping. At any time."): from just under Roblox's top bar downwards,
-- the first spot clear of everything else showing; computers keep it where it always was
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local PHONE = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()   -- (PreferredInput: MouseEnabled can read true on a touch phone - Oct 10)
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
	if not frenchQuestionReminderAllowed() then return end
	toast.Text = t
	local mine = os.clock(); toastAt = mine
	if PHONE then
		task.spawn(function() placeToast(); if toastAt == mine and frenchQuestionReminderAllowed() then toast.Visible = true end end)
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
		task.defer(refreshPrompts)
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
	if not frenchQuestionReminderAllowed() then return end
	if arrowGui then arrowGui:Destroy(); arrowGui = nil end
	local m = F:FindFirstChild("Board_" .. tostring(b))
	local face = m and m:FindFirstChild("Face")
	if not face then return end
	local right = -face.CFrame.RightVector                                    -- the right as you stand facing the board
	right = Vector3.new(right.X, 0, right.Z).Unit
	local pos = face.Position + right * 0.55 + Vector3.new(0, face.Size.Y / 2 + 2.7, 0)   -- over the middle of the board, a touch right
	local NEON = C(45, 230, 88)
	local model = Instance.new("Model"); model.Name = "BoardArrow"
	local SIZE = 3.25                                                         -- studs across
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
	local THICK = 0.13
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
	local lamp = Instance.new("PointLight"); lamp.Color = NEON; lamp.Brightness = 2.8; lamp.Range = 10; lamp.Shadows = false; lamp.Parent = core
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
			if (hrp and (hrp.Position - face.Position).Magnitude < 4) or boardOpen or os.clock() - t0 > 120 then
				if arrowGui == model then model:Destroy(); arrowGui = nil end
			end
		end
	end)
end

-- Retry after loading / a transient request failure; announce each available board once per round.
-- An answered board stays quiet. Missing the newday event is recovered by the status poll.
local reminded={};local joinedAt=os.clock()
local function blocked()
 if not frenchQuestionReminderAllowed() then return true end
 if os.clock()-joinedAt<8 or not player:GetAttribute("SaveLoaded")then return true end
 if pg:GetAttribute("OpenPanel") or gui.Enabled then return true end
 local dg=pg:FindFirstChild("DailyGui");local dc=dg and dg:FindFirstChild("DailyCard")
 return dg and dg.Enabled and dc and dc.Visible
end
remind=function()
 if not latestStatus or blocked()then return end
 local need=(workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need"))or 10
 local board=latestStatus.forest=="open" and "forest" or (player:GetAttribute("Found_forest")or 0)>=need and latestStatus.poste=="open" and "poste" or nil
 if not board then return end
 local key=tostring(latestStatus.round)..board
 if reminded[key]then return end;reminded[key]=true
 say(board=="forest" and "Today's forest question is ready! Open Passport → Clues or visit the forest board." or "A second question awaits at La Poste! Open Passport → Clues or visit the board.",10)
 pointAt(board)
end
task.spawn(function()while news.Parent do task.wait(3);remind()end end)
local RS=game:GetService("ReplicatedStorage")
local qt=RS:FindFirstChild("QuestionToggle")or Instance.new("BindableEvent");qt.Name="QuestionToggle";qt.Parent=RS
qt.Event:Connect(function(b)if b=="forest" or b=="poste" then setOpen(true,b,true)end end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if gui.Enabled and pg:GetAttribute("OpenPanel")~="question"then setOpen(false)end end)

local function updateFrenchQuestionReminder()
    if frenchQuestionReminderAllowed() then
        -- blocked() runs before reminded[key] is consumed, so Italy never
        -- uses up a pending French reminder. Existing once-per-day rules stay.
        task.defer(remind)
    else
        toastAt = -1 -- invalidate an in-flight phone placement callback
        toast.Visible = false
        if arrowGui then arrowGui:Destroy(); arrowGui = nil end
    end
end
player:GetAttributeChangedSignal("Area"):Connect(updateFrenchQuestionReminder)
updateFrenchQuestionReminder()

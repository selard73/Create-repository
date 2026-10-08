-- PostClient: the prompt opens the panel; write and send, or read what came back; the dev desk for Shannon
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
-- On a phone the keyboard covers the Send button, and the only way to put it away was to tap outside the box - which
-- closed the whole panel and lost the letter (Shannon). Now the box is one wrapping line on touch screens, so the
-- keyboard's Done key puts it away; a tap outside only puts the keyboard away; and what you wrote is kept until sent.
local TOUCH = UIS.TouchEnabled
local draft, replyDrafts = "", {}
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local PO = script.Parent
local action = PO:WaitForChild("PostAction")
local notify = PO:WaitForChild("PostNotify")
local RGB = Color3.fromRGB
local FACE, FACE_DEEP, RIM = RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)
local SLOT, SLOT_EDGE = RGB(228, 212, 179), RGB(162, 131, 90)
local INK, INK_DIM, GOLD, BTN_INK, NAVY = RGB(64, 42, 22), RGB(132, 108, 80), RGB(255, 202, 62), RGB(84, 48, 18), RGB(30, 50, 100)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o; return c end
local function stroke(o, col, th, tr) local st = Instance.new("UIStroke"); st.Color = col; st.Thickness = th; st.Transparency = tr or 0; st.Parent = o; return st end
local function label(parent, text, x, y, w, h, size, colour, wrap, align)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.new(1, -x - 24, 0, h)
	if w then l.Size = UDim2.fromOffset(w, h) end
	l.BackgroundTransparency = 1; l.FontFace = FONT; l.TextSize = size; l.TextColor3 = colour or INK; l.Text = text
	l.TextWrapped = wrap ~= false; l.TextXAlignment = align or Enum.TextXAlignment.Left; l.TextYAlignment = Enum.TextYAlignment.Top
	l.ZIndex = 4; l.Parent = parent
	return l
end
local function button(parent, text, x, y, w, h, fill, ink)
	local b = Instance.new("TextButton"); b.Position = UDim2.fromOffset(x, y); b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = fill or GOLD; b.BorderSizePixel = 0; b.FontFace = FONT; b.TextSize = 18; b.TextColor3 = ink or BTN_INK
	b.Text = text; b.AutoButtonColor = false; b.ZIndex = 4; b.Parent = parent
	corner(b, UDim.new(0, 10)); stroke(b, RGB(150, 98, 36), 2, 0.2)
	return b
end
local function ago(t)
	if not t then return "" end
	local d = os.time() - t
	if d < 3600 then return math.max(1, math.floor(d / 60)) .. " min ago" end
	if d < 86400 then return math.floor(d / 3600) .. " h ago" end
	return math.floor(d / 86400) .. " days ago"
end

local gui = Instance.new("ScreenGui"); gui.Name = "PostOffice"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 7; gui.Enabled = false; gui.Parent = pg
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = RGB(20, 12, 6); shade.BackgroundTransparency = 0.45
shade.Text = ""; shade.AutoButtonColor = false; shade.BorderSizePixel = 0; shade.ZIndex = 1; shade.Parent = gui
local W, H = 460, 430
local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(W, H); panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.ZIndex = 2; panel.Parent = gui
corner(panel, UDim.new(0, 22)); stroke(panel, RIM, 4, 0)
local scale = Instance.new("UIScale"); scale.Parent = panel
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min((vp.Y - 40) / H, (vp.X - 40) / W), 0.5, 1)
end
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end)
local title = label(panel, "La Poste", 24, 16, 300, 34, 28, RGB(58, 36, 16), false)
local close = button(panel, "X", W - 50, 18, 32, 32, SLOT, INK)
local page = Instance.new("Frame"); page.Position = UDim2.fromOffset(16, 62); page.Size = UDim2.new(1, -32, 1, -78); page.BackgroundTransparency = 1; page.ZIndex = 3; page.Parent = panel

-- the toast (its own gui, shown whether or not the panel is open)
local toastGui = Instance.new("ScreenGui"); toastGui.Name = "PostToast"; toastGui.ResetOnSpawn = false; toastGui.IgnoreGuiInset = true; toastGui.DisplayOrder = 8; toastGui.Parent = pg
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118); toast.Size = UDim2.fromOffset(420, 48)   -- above the hotbar, under any panel
toast.BackgroundColor3 = NAVY; toast.BackgroundTransparency = 0.08; toast.BorderSizePixel = 0; toast.FontFace = FONT; toast.TextSize = 20
toast.TextColor3 = RGB(255, 205, 40); toast.TextWrapped = true; toast.Text = ""; toast.Visible = false; toast.Parent = toastGui
corner(toast, UDim.new(0, 14)); stroke(toast, RGB(255, 205, 40), 2, 0.2)
local toastAt = 0
local function say(text, secs)
	toast.Text = text; toast.Visible = true
	local t = os.clock(); toastAt = t
	task.delay(secs or 5, function() if toastAt == t then toast.Visible = false end end)
end
notify.OnClientEvent:Connect(function(msg) say(msg, 6) end)
-- the envelope: built from frames, it pops out of the panel, wobbles, and flies off to the top right with a whoosh
local function flyEnvelope()
	local env = Instance.new("Frame"); env.AnchorPoint = Vector2.new(0.5, 0.5); env.Position = UDim2.fromScale(0.5, 0.52); env.Size = UDim2.fromOffset(150, 96)
	env.BackgroundColor3 = RGB(250, 244, 226); env.BorderSizePixel = 0; env.Rotation = -8; env.ZIndex = 20; env.Parent = toastGui
	corner(env, UDim.new(0, 8)); stroke(env, RGB(150, 118, 76), 3, 0)
	local flapL = Instance.new("Frame"); flapL.AnchorPoint = Vector2.new(0, 0); flapL.Position = UDim2.fromScale(0.03, 0.04); flapL.Size = UDim2.fromScale(0.54, 0.09)
	flapL.BackgroundColor3 = RGB(150, 118, 76); flapL.BorderSizePixel = 0; flapL.Rotation = 34; flapL.ZIndex = 21; flapL.Parent = env
	local flapR = flapL:Clone(); flapR.AnchorPoint = Vector2.new(1, 0); flapR.Position = UDim2.fromScale(0.97, 0.04); flapR.Rotation = -34; flapR.Parent = env
	local stamp = Instance.new("Frame"); stamp.AnchorPoint = Vector2.new(1, 0); stamp.Position = UDim2.new(1, -8, 0, 8); stamp.Size = UDim2.fromOffset(34, 40)
	stamp.BackgroundColor3 = RGB(255, 205, 40); stamp.BorderSizePixel = 0; stamp.ZIndex = 22; stamp.Parent = env
	stroke(stamp, RGB(250, 244, 226), 3, 0)
	local nut = Instance.new("Frame"); nut.AnchorPoint = Vector2.new(0.5, 0.5); nut.Position = UDim2.fromScale(0.5, 0.55); nut.Size = UDim2.fromOffset(16, 18)
	nut.BackgroundColor3 = RGB(196, 136, 66); nut.BorderSizePixel = 0; nut.ZIndex = 23; nut.Parent = stamp; corner(nut, UDim.new(1, 0))
	local cap = Instance.new("Frame"); cap.AnchorPoint = Vector2.new(0.5, 1); cap.Position = UDim2.fromScale(0.5, 0.36); cap.Size = UDim2.fromOffset(18, 8)
	cap.BackgroundColor3 = RGB(120, 78, 40); cap.BorderSizePixel = 0; cap.ZIndex = 24; cap.Parent = stamp; corner(cap, UDim.new(0, 4))
	local mark = Instance.new("Frame"); mark.AnchorPoint = Vector2.new(0.5, 0.5); mark.Position = UDim2.fromScale(0.5, 0.5); mark.Size = UDim2.fromOffset(44, 44)
	mark.BackgroundTransparency = 1; mark.ZIndex = 25; mark.Parent = stamp; stroke(mark, RGB(200, 60, 60), 2, 0.25); corner(mark, UDim.new(1, 0))
	for i, y in ipairs({0.46, 0.6, 0.74}) do
		local line = Instance.new("Frame"); line.Position = UDim2.fromScale(0.1, y); line.Size = UDim2.fromScale(i == 3 and 0.35 or 0.5, 0.05)
		line.BackgroundColor3 = RGB(150, 118, 76); line.BackgroundTransparency = 0.35; line.BorderSizePixel = 0; line.ZIndex = 21; line.Parent = env
	end
	local s = Instance.new("Sound"); s.SoundId = "rbxasset://sounds/button.wav"; s.Volume = 0.7; s.PlaybackSpeed = 0.6; s.Parent = toastGui; s:Play(); game:GetService("Debris"):AddItem(s, 3)
	-- pop, wobble, then away
	env.Size = UDim2.fromOffset(20, 12)
	TweenService:Create(env, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(150, 96), Rotation = 6}):Play()
	task.delay(0.35, function()
		TweenService:Create(env, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = -10}):Play()
	end)
	task.delay(0.7, function()
		TweenService:Create(env, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.fromScale(0.92, 0.06), Size = UDim2.fromOffset(30, 20), Rotation = 40}):Play()
		task.delay(0.95, function() env:Destroy() end)
	end)
end

local status
local render
local function call(kind, a, b)
	local ok, res, extra = pcall(function() return action:InvokeServer(kind, a, b) end)
	if not ok then return false, "the post office is not answering" end
	return res, extra
end
local function clearPage() for _, c in ipairs(page:GetChildren()) do c:Destroy() end end
local function noteLine(text, y, colour)
	return label(page, text, 0, y, nil, 40, 14, colour or INK_DIM)
end

-- the compose page: a box to write in, the price, the promise
local function composePage()
	clearPage()
	label(page, "Write to the dev", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	noteLine("Ask a question, tell her something, say hello. Replies take about a day - come back and check the box.", 26)
	local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(0, 70); slot.Size = UDim2.new(1, 0, 0, 150); slot.BackgroundColor3 = RGB(255, 252, 244)
	slot.BorderSizePixel = 0; slot.ZIndex = 4; slot.Parent = page; corner(slot, UDim.new(0, 12)); stroke(slot, SLOT_EDGE, 2, 0.3)
	local tb = Instance.new("TextBox"); tb.Position = UDim2.fromOffset(10, 8); tb.Size = UDim2.new(1, -20, 1, -16); tb.BackgroundTransparency = 1
	tb.FontFace = FONT; tb.TextSize = 16; tb.TextColor3 = INK; tb.PlaceholderText = "Dear dev, ..."; tb.PlaceholderColor3 = INK_DIM; tb.Text = ""
	tb.TextWrapped = true; tb.MultiLine = not TOUCH; tb.ClearTextOnFocus = false; tb.TextXAlignment = Enum.TextXAlignment.Left; tb.TextYAlignment = Enum.TextYAlignment.Top
	tb.Text = draft
	tb.ZIndex = 5; tb.Parent = slot
	local count = label(page, "0 / " .. tostring(status.max), 0, 226, nil, 18, 13, INK_DIM, false, Enum.TextXAlignment.Right)
	local send = button(page, "", 0, 256, 220, 42)
	local line = noteLine("", 306)
	local function refreshSend()
		local n = utf8.len(tb.Text) or #tb.Text
		count.Text = tostring(n) .. " / " .. tostring(status.max)
		local can = status.open and n > 0 and n <= status.max and status.acorns >= status.price
		send.Text = "Send for " .. tostring(status.price) .. " acorns"
		send.BackgroundColor3 = can and GOLD or RGB(214, 202, 176); send.TextColor3 = can and BTN_INK or INK_DIM
		if not status.open then line.Text = "The post office is closed just now."
		elseif status.acorns < status.price then line.Text = string.format("You have %d acorns; a stamp is %d.", status.acorns, status.price)
		elseif n > status.max then line.Text = "That is more than the envelope holds."
		else line.Text = "" end
	end
	tb:GetPropertyChangedSignal("Text"):Connect(function()
		if (utf8.len(tb.Text) or #tb.Text) > status.max + 40 then tb.Text = string.sub(tb.Text, 1, status.max + 40) end
		draft = tb.Text
		refreshSend()
	end)
	refreshSend()
	if status.reply then
		local again = button(page, "Read the dev's last letter", 232, 256, 196, 42, SLOT, INK)
		again.Activated:Connect(function() render("reply") end)
	end
	send.Activated:Connect(function()
		local n = utf8.len(tb.Text) or #tb.Text
		if not (status.open and n > 0 and n <= status.max and status.acorns >= status.price) then return end
		send.Text = "..."
		local ok, res = call("send", tb.Text)
		if ok then draft = ""; status = res; flyEnvelope(); say("Posted. The dev will write back in about a day.", 6); render()
		else line.Text = tostring(res); refreshSend() end
	end)
end
-- the letter is with the dev
local function sentPage()
	clearPage()
	label(page, "Your letter is with the dev", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	noteLine("Sent " .. ago(status.sentAt) .. ". Replies take about a day - come back and check the box.", 26)
	local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(0, 70); slot.Size = UDim2.new(1, 0, 0, 170); slot.BackgroundColor3 = RGB(255, 252, 244)
	slot.BorderSizePixel = 0; slot.ZIndex = 4; slot.Parent = page; corner(slot, UDim.new(0, 12)); stroke(slot, SLOT_EDGE, 2, 0.3)
	local l = label(slot, status.letter or "", 10, 8, nil, 150, 15, INK); l.Size = UDim2.new(1, -20, 1, -16); l.ZIndex = 5
end
-- a letter from the dev
local function replyPage()
	clearPage()
	label(page, "A letter for you", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	noteLine("From " .. tostring(status.by or "the dev") .. ", " .. ago(status.repliedAt) .. (status.letter and ("  -  in answer to: " .. string.sub(status.letter, 1, 60) .. ((#status.letter > 60) and "..." or "")) or ""), 26)
	local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(0, 70); slot.Size = UDim2.new(1, 0, 0, 190); slot.BackgroundColor3 = RGB(255, 252, 244)
	slot.BorderSizePixel = 0; slot.ZIndex = 4; slot.Parent = page; corner(slot, UDim.new(0, 12)); stroke(slot, SLOT_EDGE, 2, 0.3)
	local l = label(slot, status.reply or "", 10, 8, nil, 170, 15, INK); l.Size = UDim2.new(1, -20, 1, -16); l.ZIndex = 5
	local keep = button(page, status.state == "answered" and "Keep it" or "Write another", 0, 272, 220, 42)
	keep.Activated:Connect(function()
		if status.state == "answered" then local ok, res = call("read"); if ok then status = res end end
		render("compose")
	end)
end
-- the dev desk: every letter waiting, each with a reply box
local function deskPage()
	clearPage()
	label(page, "Dev desk", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	local back = button(page, "My own letters", W - 32 - 170, 0, 170, 30, SLOT, INK)
	back.Activated:Connect(function() render("compose") end)
	local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(0, 36); list.Size = UDim2.new(1, 0, 1, -36); list.BackgroundTransparency = 1
	list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new(); list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ZIndex = 4; list.Parent = page
	local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 10); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list
	local ok, letters = call("list")
	if not ok then noteLine(tostring(letters), 40); return end
	if #letters == 0 then label(list, "Nothing waiting. The box is empty.", 0, 0, nil, 30, 15, INK_DIM); return end
	for i, e in ipairs(letters) do
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, -8, 0, 250); row.BackgroundColor3 = FACE_DEEP; row.BorderSizePixel = 0; row.LayoutOrder = i; row.ZIndex = 4; row.Parent = list
		corner(row, UDim.new(0, 14)); stroke(row, SLOT_EDGE, 2, 0.45)
		label(row, string.format("%s  (@%s)  -  %s", e.name, e.user, ago(e.t)), 12, 8, nil, 20, 15, RGB(58, 36, 16), false)
		local body = label(row, e.text, 12, 30, nil, 78, 14, INK); body.Size = UDim2.new(1, -24, 0, 78)
		local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(12, 112); slot.Size = UDim2.new(1, -24, 0, 84); slot.BackgroundColor3 = RGB(255, 252, 244)
		slot.BorderSizePixel = 0; slot.ZIndex = 5; slot.Parent = row; corner(slot, UDim.new(0, 10)); stroke(slot, SLOT_EDGE, 2, 0.3)
		local tb = Instance.new("TextBox"); tb.Position = UDim2.fromOffset(8, 6); tb.Size = UDim2.new(1, -16, 1, -12); tb.BackgroundTransparency = 1
		tb.FontFace = FONT; tb.TextSize = 14; tb.TextColor3 = INK; tb.PlaceholderText = "Your reply..."; tb.PlaceholderColor3 = INK_DIM; tb.Text = ""
		tb.TextWrapped = true; tb.MultiLine = not TOUCH; tb.ClearTextOnFocus = false; tb.TextXAlignment = Enum.TextXAlignment.Left; tb.TextYAlignment = Enum.TextYAlignment.Top
		tb.Text = replyDrafts[e.uid] or ""
		tb:GetPropertyChangedSignal("Text"):Connect(function() replyDrafts[e.uid] = tb.Text end)
		tb.ZIndex = 6; tb.Parent = slot
		local send = button(row, "Send reply", 12, 204, 160, 36)
		local note = label(row, "", 184, 212, nil, 20, 13, INK_DIM, false)
		send.Activated:Connect(function()
			if #tb.Text == 0 then note.Text = "write the reply first"; return end
			send.Text = "..."
			local ok2, why = call("reply", e.uid, tb.Text)
			if ok2 then replyDrafts[e.uid] = nil; row:Destroy() else send.Text = "Send reply"; note.Text = tostring(why) end
		end)
	end
end
render = function(which)
	if not status then return end
	if which == "desk" then deskPage(); return end
	if which == "reply" and status.reply then replyPage(); return end
	if which == "compose" then composePage(); return end
	if status.state == "sent" then sentPage()
	elseif status.state == "answered" then replyPage()
	else composePage() end
end
local deskBtn = button(panel, "Dev desk", W - 50 - 12 - 110, 18, 110, 32, NAVY, RGB(255, 205, 40)); deskBtn.Visible = false
deskBtn.Activated:Connect(function() render("desk") end)
local function open()
	local ok, res = call("status")
	gui:SetAttribute("LastStatus", tostring(ok) .. " " .. tostring(res))
	if not ok then say(tostring(res), 4); return end
	status = res
	deskBtn.Visible = status.dev == true
	gui.Enabled = true
	fit()
	local want = scale.Scale; scale.Scale = want * 0.86
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = want}):Play()
	local okr, err = pcall(render)
	if not okr then gui:SetAttribute("RenderError", tostring(err)); warn("PostClient: render failed - " .. tostring(err)) end
end
local function closePanel() gui.Enabled = false end
close.Activated:Connect(closePanel)
-- (a tap on the shade only puts the keyboard away - it no longer closes the panel; the X does)

-- the prompt on the box, and its label when a letter is waiting
local function hookPrompt()
	-- at join the box model can arrive before the prompt inside it, so wait for the prompt itself, not just the model
	local box = PO:WaitForChild("PostBox", 60)
	local body = box and box:WaitForChild("Body", 60)
	local prompt = body and body:WaitForChild("PostPrompt", 60)
	if not prompt then warn("PostClient: no prompt on the post box"); return end
	gui:SetAttribute("Hooked", true)
	prompt.Triggered:Connect(function() gui:SetAttribute("Triggers", (gui:GetAttribute("Triggers") or 0) + 1); open() end)   -- on the client this fires for the local player only
	local function relabel()
		local n = player:GetAttribute("LettersWaiting") or 0              -- only the dev ever has these
		if player:GetAttribute("MailWaiting") then prompt.ObjectText = "La Poste - a letter is waiting for you!"
		elseif n > 0 then prompt.ObjectText = "La Poste - " .. n .. (n == 1 and " letter" or " letters") .. " to answer"
		else prompt.ObjectText = "La Poste - write to the dev" end
	end
	relabel()
	player:GetAttributeChangedSignal("MailWaiting"):Connect(relabel)
	player:GetAttributeChangedSignal("LettersWaiting"):Connect(relabel)
end
task.spawn(hookPrompt)

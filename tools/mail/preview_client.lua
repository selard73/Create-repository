-- PLAY-TEST PREVIEW ONLY (mail3): name the mailbox's parts as the install will, then run the MailClient code
do
	local house = workspace:WaitForChild("Treehouse_local"):WaitForChild("House")
	local m
	local t0 = os.clock()
	while not m and os.clock() - t0 < 15 do m = house:FindFirstChild("Mailbox"); if not m then task.wait(0.3) end end
	if m and not m:FindFirstChild("Flag") then
		local flag = Instance.new("Model"); flag.Name = "Flag"
		local rivet
		for _, p in ipairs(m:GetChildren()) do
			if p:IsA("BasePart") then
				if p.Material == Enum.Material.WoodPlanks then p.Name = "Box"
				elseif p.Size == Vector3.new(1.76, 0.99, 0.08) then p.Name = "Door"
				elseif p.Size == Vector3.new(0.12, 1.3, 0.12) or p.Size == Vector3.new(0.08, 0.55, 0.8) then p.Parent = flag
				elseif p.Shape == Enum.PartType.Ball and p.Material == Enum.Material.Metal then p.Name = "FlagPivot"; rivet = p end
			end
		end
		flag.Parent = m
		if rivet then flag.WorldPivot = rivet.CFrame end
	end
end
-- MailClient (workspace.Mail, RunContext Client; mail3, Oct 22 2026): the treehouse mailbox, for this player. Shannon: "We
-- need a system to notify the player that they have mail and to check and when they open the mailbox, it should have an
-- animated letter fly out and open on the screen." + "if the player is in a different map, there should be a note to pops
-- up briefly telling them. 'You have mail. When you get the chance, check your mailbox at Homebase.'"
--   a letter waiting (Item_mail_wait > 0, MailServer): the flag goes up, the mailbox glows gold, a little envelope bobs
--   over it, and a short note pops up once (in the forest: at your treehouse; anywhere else: her words);
--   "Check mail" (the game's own prompt pill) opens it: an envelope pops out of the mailbox door, flies to the middle of
--   the screen, the seal pops, the flap folds open, the letter slides out and unfolds - "Dear <name>," in a squirrel's
--   own words, signed, with any acorns tucked inside. No letter: a friendly "check back tomorrow".
-- The mailbox itself is TreehouseClient's (rebuilt with the house), so everything here re-attaches whenever it is rebuilt.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local act = RS:WaitForChild("MailAction", 60)
if not act then return end
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, PAPER, INK = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(255, 251, 238), C(70, 44, 22)
local FONT, HAND = Enum.Font.FredokaOne, Enum.Font.PatrickHand
local function waitingNo() return tonumber(player:GetAttribute("Item_mail_wait")) or 0 end
local function tw(o, t, goal, style, dir)
	local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	x:Play(); return x
end
local function screen()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o; return c end
local function stroke(o, col, th) local s = Instance.new("UIStroke"); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = col; s.Thickness = th; s.Parent = o; return s end

-- ---------- a short note at the top, under the question note when that is up ----------
local function note(text, secs)
	local old = pg:FindFirstChild("MailNote"); if old then old:Destroy() end
	local g = Instance.new("ScreenGui"); g.Name = "MailNote"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 24; g.Parent = pg
	local vp = screen()
	local small = vp.Y < 500
	local inset = GuiService:GetGuiInset()
	local y = 62
	local qn = pg:FindFirstChild("QuestionNews"); local q = qn and qn.Enabled and qn:FindFirstChild("QuestionReminder")
	if q and q:IsA("GuiObject") and q.Visible then y = math.max(y, q.AbsolutePosition.Y + inset.Y + q.AbsoluteSize.Y + 8) end
	local box = Instance.new("TextLabel"); box.AnchorPoint = Vector2.new(0.5, 0); box.Position = UDim2.fromOffset(vp.X / 2, y)
	box.Size = UDim2.fromOffset(math.min(small and 380 or 460, vp.X - 40), 0); box.AutomaticSize = Enum.AutomaticSize.Y
	box.BackgroundColor3 = NAVY; box.BackgroundTransparency = 0.05; box.Font = FONT; box.TextSize = small and 15 or 18
	box.TextColor3 = CREAM; box.TextWrapped = true; box.Text = utf8.char(0x1F4EC) .. "  " .. text; box.Parent = g
	corner(box, UDim.new(0, 14)); local s = stroke(box, GOLD, 2)
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 9); pad.PaddingBottom = UDim.new(0, 9)
	pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14); pad.Parent = box
	local sc = Instance.new("UIScale"); sc.Scale = 0.5; sc.Parent = box
	tw(sc, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
	task.delay(secs or 6, function()
		if not g.Parent then return end
		tw(box, 0.3, {BackgroundTransparency = 1, TextTransparency = 1}); tw(s, 0.3, {Transparency = 1})
		task.delay(0.35, function() g:Destroy() end)
	end)
end
local noticed = {}                                               -- the arrival note: once a session per letter
local function arrivalNote()
	local i = waitingNo()
	if i < 1 or noticed[i] then return end
	noticed[i] = true
	if player:GetAttribute("Area") == "forest" then
		note("You've got mail! A letter is waiting in your treehouse mailbox.", 6)
	else
		note("You have mail. When you get the chance, check your mailbox at Homebase.", 6)   -- (her words)
	end
end

-- ---------- the mailbox: its prompt, its flag, a gold glow and an envelope over it while a letter waits ----------
local open                                                       -- (defined below)
local box = {model = nil}
local promptUp = false                                           -- the "Check mail" pill is showing: the envelope over the box steps aside
local function flagTo(m, up, animate)
	local flag, pivot = m:FindFirstChild("Flag"), m:FindFirstChild("FlagPivot")
	if not (flag and pivot) then return end
	local upCF = flag:GetAttribute("UpCF")
	if not upCF then flag:SetAttribute("UpCF", flag:GetPivot()); upCF = flag:GetPivot() end
	local downCF = upCF * CFrame.Angles(math.rad(90), 0, 0)      -- the pole swings forward along the side
	local goal = up and upCF or downCF
	if not animate then flag:PivotTo(goal) return end
	local from = flag:GetPivot()
	local v = Instance.new("NumberValue"); v.Value = 0
	v.Changed:Connect(function(a) if flag.Parent then flag:PivotTo(from:Lerp(goal, a)) end end)
	local t = tw(v, 0.5, {Value = 1}, Enum.EasingStyle.Back)
	t.Completed:Connect(function() v:Destroy() end)
end
local function dress(m, animate)
	local on = waitingNo() > 0
	flagTo(m, on, animate)
	local glow = m:FindFirstChild("MailGlow")
	local tag = m:FindFirstChild("MailTag", true)
	if on then
		if not glow then
			glow = Instance.new("Highlight"); glow.Name = "MailGlow"; glow.Adornee = m; glow.FillColor = C(255, 214, 90); glow.FillTransparency = 0.8
			glow.OutlineColor = C(255, 214, 90); glow.OutlineTransparency = 0; glow.DepthMode = Enum.HighlightDepthMode.Occluded; glow.Parent = m
		end
		local b = m:FindFirstChild("Box")
		if not tag and b then
			tag = Instance.new("BillboardGui"); tag.Name = "MailTag"; tag.Size = UDim2.fromOffset(52, 52); tag.StudsOffset = Vector3.new(0, 2.6, 0)
			tag.AlwaysOnTop = true; tag.MaxDistance = 140; tag.LightInfluence = 0; tag.Parent = b
			local env = Instance.new("TextLabel"); env.Size = UDim2.fromScale(1, 1); env.BackgroundColor3 = CREAM; env.Font = FONT; env.TextScaled = true
			env.Text = utf8.char(0x2709); env.TextColor3 = C(200, 70, 60); env.Parent = tag
			corner(env, UDim.new(0, 12)); stroke(env, GOLD, 3)
			local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6); pad.Parent = env
			local dot = Instance.new("TextLabel"); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.new(1, -4, 0, 4); dot.Size = UDim2.fromOffset(20, 20)
			dot.BackgroundColor3 = C(214, 64, 56); dot.Font = FONT; dot.TextSize = 13; dot.TextColor3 = C(255, 255, 255); dot.Text = "1"; dot.ZIndex = 2; dot.Parent = tag
			corner(dot, UDim.new(0.5, 0))
		end
		if tag then tag.Enabled = not promptUp end
	else
		if glow then glow:Destroy() end
		if tag then tag:Destroy() end
	end
end
local function attach(m)
	if box.model == m then return end
	box.model = m
	local b = m:WaitForChild("Box", 5)
	if not b then return end
	local pr = Instance.new("ProximityPrompt"); pr.Name = "CheckMail"; pr.Style = Enum.ProximityPromptStyle.Custom
	pr.ObjectText = "Mailbox"; pr.ActionText = "Check mail"; pr.MaxActivationDistance = 10; pr.HoldDuration = 0; pr.RequiresLineOfSight = false
	pr.Parent = b
	pr.Triggered:Connect(function() if open then open(m) end end)
	pr.PromptShown:Connect(function() promptUp = true; local t = m:FindFirstChild("MailTag", true); if t then t.Enabled = false end end)
	pr.PromptHidden:Connect(function() promptUp = false; local t = m:FindFirstChild("MailTag", true); if t then t.Enabled = true end end)
	dress(m, false)
end
task.spawn(function()
	local lf = workspace:WaitForChild("Treehouse_local", 120)
	local house = lf and lf:WaitForChild("House", 30)
	if not house then return end
	local m = house:FindFirstChild("Mailbox"); if m then attach(m) end
	house.ChildAdded:Connect(function(c) if c.Name == "Mailbox" then task.defer(attach, c) end end)
end)
RunService.Heartbeat:Connect(function()                          -- the glow breathes and the envelope bobs
	local m = box.model
	if not (m and m.Parent) then return end
	local g = m:FindFirstChild("MailGlow"); if g then g.FillTransparency = 0.72 + 0.16 * math.sin(os.clock() * 2.2) end
	local t = m:FindFirstChild("MailTag", true); if t then t.StudsOffset = Vector3.new(0, 2.6 + 0.25 * math.sin(os.clock() * 2.6), 0) end
end)
player:GetAttributeChangedSignal("Item_mail_wait"):Connect(function()
	if box.model and box.model.Parent then dress(box.model, true) end
	arrivalNote()
end)
task.spawn(function()
	local t0 = os.clock()
	while player:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
	task.wait(8)                                                  -- (after the daily card and the start-up notes)
	arrivalNote()
end)

-- ---------- the letter: out of the mailbox, onto the screen, open ----------
local reading = false
local function slicesTriangle(parent, w, h, colour, z, up)        -- a triangle from thin slices (a rotated frame will not clip)
	local f = Instance.new("Frame"); f.BackgroundTransparency = 1; f.Size = UDim2.fromScale(1, 1); f.ZIndex = z; f.Parent = parent
	local n = 48
	for i = 0, n - 1 do
		local s = Instance.new("Frame"); s.BorderSizePixel = 0; s.BackgroundColor3 = colour; s.ZIndex = z
		local frac = up and ((i + 1) / n) or (1 - i / n)            -- down: widest at the top; up: widest at the bottom
		s.AnchorPoint = Vector2.new(0.5, 0); s.Position = UDim2.new(0.5, 0, i / n, 0); s.Size = UDim2.new(frac, 0, 1 / n, 1)
		s.Parent = f
	end
	return f
end
-- the sender's face for the stamp: MailServer leaves a bare copy of the squirrel in RS.MailPortraits; framed like the
-- squirrel cards - forward is root -> head, the camera close in front of the head
local function portraitIn(stamp, id)
	local folder = RS:FindFirstChild("MailPortraits")
	local src = folder and folder:WaitForChild(id, 2)
	if not src then return nil end
	local vp = Instance.new("ViewportFrame"); vp.Name = "Face"; vp.Size = UDim2.new(1, -10, 1, -10); vp.Position = UDim2.fromOffset(5, 5)
	vp.BackgroundColor3 = C(206, 230, 242); vp.BackgroundTransparency = 1; vp.ImageTransparency = 1; vp.ZIndex = 13
	vp.Ambient = C(190, 190, 200); vp.LightColor = C(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6); vp.Parent = stamp
	local copy = src:Clone(); copy.CFrame = CFrame.new(); copy.Parent = vp
	local bones = {}
	for _, b in ipairs(copy:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local head = bones.Head and bones.Head.WorldPosition or copy.Position
	local root = bones.Root and bones.Root.WorldPosition or copy.Position
	local f = head - root; f = Vector3.new(f.X, 0, f.Z)
	f = f.Magnitude > 0.05 and f.Unit or Vector3.new(0, 0, -1)
	local reach = copy.Size.Magnitude
	local target = head:Lerp(root, 0.2)
	local cam = Instance.new("Camera"); cam.FieldOfView = 30; cam.Parent = vp; vp.CurrentCamera = cam
	cam.CFrame = CFrame.lookAt(target + f * reach * 0.62 + Vector3.new(0, reach * 0.1, 0), target)
	return vp
end
local function showLetter(L, fromScreen)
	local vp = screen()
	local small = vp.Y < 500
	local g = Instance.new("ScreenGui"); g.Name = "MailLetter"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 32; g.Parent = pg
	local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(0, 0, 0); shade.BackgroundTransparency = 1
	shade.Text = ""; shade.AutoButtonColor = false; shade.Parent = g
	tw(shade, 0.35, {BackgroundTransparency = 0.45})
	local centre = Vector2.new(vp.X / 2, vp.Y / 2)
	local finish                                                  -- (defined once the letter is up)
	local gone = false
	local con; con = pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
		if pg:GetAttribute("OpenPanel") ~= "mail" then con:Disconnect(); gone = true; if finish then finish() else g:Destroy(); reading = false end end
	end)
	-- the envelope
	local EW, EH = small and 200 or 260, small and 130 or 170
	local env = Instance.new("Frame"); env.Name = "Envelope"; env.AnchorPoint = Vector2.new(0.5, 0.5); env.Size = UDim2.fromOffset(EW, EH)
	env.Position = UDim2.fromOffset(fromScreen.X, fromScreen.Y); env.BackgroundTransparency = 1; env.Rotation = -18; env.Parent = g
	local es = Instance.new("UIScale"); es.Scale = 0.2; es.Parent = env
	local back = Instance.new("Frame"); back.Size = UDim2.fromScale(1, 1); back.BackgroundColor3 = C(232, 214, 176); back.ZIndex = 1; back.Parent = env
	corner(back, UDim.new(0, 10)); stroke(back, C(186, 150, 98), 2)
	local paper = Instance.new("Frame"); paper.AnchorPoint = Vector2.new(0.5, 0); paper.Position = UDim2.new(0.5, 0, 0, 10)
	paper.Size = UDim2.new(1, -28, 1, -18); paper.BackgroundColor3 = PAPER; paper.ZIndex = 2; paper.Parent = env
	corner(paper, UDim.new(0, 6))
	for k = 1, 4 do                                              -- a few written lines on the folded letter
		local ln = Instance.new("Frame"); ln.BorderSizePixel = 0; ln.BackgroundColor3 = C(200, 186, 160); ln.ZIndex = 2
		ln.Position = UDim2.new(0.12, 0, 0.12 + k * 0.1, 0); ln.Size = UDim2.new(k == 4 and 0.45 or 0.76, 0, 0, 2); ln.Parent = paper
	end
	local front = Instance.new("Frame"); front.AnchorPoint = Vector2.new(0, 1); front.Position = UDim2.fromScale(0, 1); front.Size = UDim2.fromScale(1, 0.62)
	front.BackgroundColor3 = C(248, 234, 202); front.ZIndex = 3; front.Parent = env
	corner(front, UDim.new(0, 10)); stroke(front, C(186, 150, 98), 2)
	local flapHolder = Instance.new("Frame"); flapHolder.Name = "Flap"; flapHolder.BackgroundTransparency = 1; flapHolder.Size = UDim2.new(1, 0, 0.58, 0)
	flapHolder.ZIndex = 4; flapHolder.Parent = env
	slicesTriangle(flapHolder, EW, EH * 0.58, C(240, 224, 188), 4, false)
	local seal = Instance.new("TextLabel"); seal.AnchorPoint = Vector2.new(0.5, 0.5); seal.Position = UDim2.new(0.5, 0, 0.56, 0); seal.Size = UDim2.fromOffset(small and 34 or 42, small and 34 or 42)
	seal.BackgroundColor3 = C(196, 58, 52); seal.Text = utf8.char(0x1F330); seal.TextScaled = true; seal.ZIndex = 6; seal.Parent = env
	corner(seal, UDim.new(0.5, 0)); stroke(seal, C(150, 36, 32), 2)
	-- 1. it flies in from the mailbox
	tw(env, 0.55, {Position = UDim2.fromOffset(centre.X, centre.Y), Rotation = 0}, Enum.EasingStyle.Back)
	tw(es, 0.55, {Scale = 1}, Enum.EasingStyle.Back)
	task.wait(0.75)
	if gone then return end
	-- 2. the seal pops, the flap folds up and over
	local ss = Instance.new("UIScale"); ss.Parent = seal
	tw(ss, 0.25, {Scale = 1.6}); tw(seal, 0.25, {BackgroundTransparency = 1, TextTransparency = 1})
	task.wait(0.15)
	local fold = tw(flapHolder, 0.22, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	fold.Completed:Wait()
	if gone then return end
	flapHolder:ClearAllChildren(); flapHolder.AnchorPoint = Vector2.new(0, 1); flapHolder.Position = UDim2.fromScale(0, 0); flapHolder.ZIndex = 0
	slicesTriangle(flapHolder, EW, EH * 0.5, C(232, 214, 176), 0, true)
	tw(flapHolder, 0.22, {Size = UDim2.new(1, 0, 0.5, 0)})
	task.wait(0.3)
	if gone then return end
	-- 3. the letter slides up out of the envelope
	tw(paper, 0.45, {Position = UDim2.new(0.5, 0, 0, -EH * 0.62)}, Enum.EasingStyle.Quad)
	task.wait(0.5)
	if gone then return end
	-- 4. ... and unfolds: the envelope drops away, the letter opens up to full size
	local LW = math.min(small and 440 or 520, vp.X - 40)
	local card = Instance.new("Frame"); card.Name = "Letter"; card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromOffset(paper.AbsolutePosition.X + paper.AbsoluteSize.X / 2, paper.AbsolutePosition.Y + paper.AbsoluteSize.Y / 2)
	card.Size = UDim2.fromOffset(paper.AbsoluteSize.X, paper.AbsoluteSize.Y); card.BackgroundColor3 = PAPER; card.ZIndex = 10; card.ClipsDescendants = true; card.Parent = g
	corner(card, UDim.new(0, 14)); local cs = stroke(card, GOLD, 3)
	paper.Visible = false
	for _, d in ipairs(env:GetDescendants()) do
		if d:IsA("GuiObject") then tw(d, 0.35, {BackgroundTransparency = 1}) end
		if d:IsA("TextLabel") then tw(d, 0.35, {TextTransparency = 1}) end
		if d:IsA("UIStroke") then tw(d, 0.35, {Transparency = 1}) end
	end
	tw(env, 0.35, {Position = UDim2.fromOffset(centre.X, centre.Y + 60)})
	-- the letter's contents (measured first, so it opens to exactly its size)
	local inner = Instance.new("Frame"); inner.BackgroundTransparency = 1; inner.Size = UDim2.fromOffset(LW, 0); inner.AutomaticSize = Enum.AutomaticSize.Y
	inner.ZIndex = 11; inner.Parent = card
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, small and 14 or 22); pad.PaddingBottom = UDim.new(0, small and 14 or 20)
	pad.PaddingLeft = UDim.new(0, small and 18 or 26); pad.PaddingRight = UDim.new(0, small and 18 or 26); pad.Parent = inner
	local list = Instance.new("UIListLayout"); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0, small and 6 or 10); list.Parent = inner
	local texts = {}
	local function line(txt, font, size, colour, order, align)
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 0); l.AutomaticSize = Enum.AutomaticSize.Y; l.BackgroundTransparency = 1
		l.Font = font; l.TextSize = size; l.TextColor3 = colour; l.TextWrapped = true; l.Text = txt; l.LayoutOrder = order; l.ZIndex = 11
		l.TextXAlignment = align or Enum.TextXAlignment.Left; l.TextTransparency = 1; l.Parent = inner
		table.insert(texts, l)
		return l
	end
	local greet = line("Dear " .. player.DisplayName .. ",", HAND, small and 22 or 28, INK, 1)
	greet.AutomaticSize = Enum.AutomaticSize.None; greet.TextYAlignment = Enum.TextYAlignment.Bottom
	greet.Size = UDim2.new(1, -(small and 66 or 84), 0, (small and 66 or 86) + 12 - (small and 14 or 22))   -- (the words start below the stamp)
	line(L.text, HAND, small and 18 or 22, INK, 2)
	if L.sign ~= "" then line(L.sign, HAND, small and 18 or 22, INK, 3, Enum.TextXAlignment.Right) end
	line(L.signer .. "  " .. utf8.char(0x1F43F), FONT, small and 16 or 19, C(120, 76, 36), 4, Enum.TextXAlignment.Right)
	if L.gift > 0 then line(utf8.char(0x1F330) .. "  " .. L.gift .. " acorns were tucked inside!", FONT, small and 15 or 17, C(64, 112, 48), 5, Enum.TextXAlignment.Center) end
	local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(small and 110 or 130, small and 32 or 38); close.BackgroundColor3 = GOLD
	close.Font = FONT; close.TextSize = small and 16 or 18; close.TextColor3 = NAVY; close.Text = "Close"; close.LayoutOrder = 6; close.ZIndex = 11
	close.BackgroundTransparency = 1; close.TextTransparency = 1; close.AutoButtonColor = true; close.Parent = inner
	corner(close, UDim.new(0, 12))
	local hold = Instance.new("Frame"); hold.BackgroundTransparency = 1; hold.Size = UDim2.new(1, 0, 0, 0); hold.LayoutOrder = 6; hold.Parent = inner
	close.Parent = hold; close.AnchorPoint = Vector2.new(0.5, 0); close.Position = UDim2.fromScale(0.5, 0); hold.Size = UDim2.new(1, 0, 0, close.Size.Y.Offset)
	-- a postage stamp in the corner with the sender's own face on it (Shannon: "please make sure to include the image of
	-- that particular squirrel rather than a generic one") - its 3D model framed head-on, the way the squirrel cards are
	local SW, SH = small and 56 or 72, small and 66 or 86
	local stamp = Instance.new("Frame"); stamp.Name = "Stamp"; stamp.AnchorPoint = Vector2.new(1, 0); stamp.Position = UDim2.new(1, -14, 0, 12)
	stamp.Size = UDim2.fromOffset(SW, SH); stamp.BackgroundColor3 = C(250, 244, 228); stamp.Rotation = 6; stamp.ZIndex = 12; stamp.BackgroundTransparency = 1
	stamp.Parent = card
	local stS = stroke(stamp, C(196, 58, 52), 2); stS.Transparency = 1
	local face = portraitIn(stamp, L.from)
	if not face then                                              -- (no model to hand: the little squirrel sign instead)
		local t = Instance.new("TextLabel"); t.Name = "Face"; t.Size = UDim2.new(1, -10, 1, -10); t.Position = UDim2.fromOffset(5, 5); t.BackgroundTransparency = 1
		t.Text = utf8.char(0x1F43F); t.TextScaled = true; t.ZIndex = 13; t.TextTransparency = 1; t.Parent = stamp
	end
	for i = 0, 5 do                                               -- the perforated edge: little bites out of each side
		for _, side in ipairs({"top", "bottom", "left", "right"}) do
			local d = Instance.new("Frame"); d.Name = "Perf"; d.AnchorPoint = Vector2.new(0.5, 0.5); d.Size = UDim2.fromOffset(6, 6); d.BorderSizePixel = 0
			d.BackgroundColor3 = PAPER; d.BackgroundTransparency = 1; d.ZIndex = 15
			local f = (i + 0.5) / 6
			if side == "top" then d.Position = UDim2.new(f, 0, 0, 0) elseif side == "bottom" then d.Position = UDim2.new(f, 0, 1, 0)
			elseif side == "left" then d.Position = UDim2.new(0, 0, f, 0) else d.Position = UDim2.new(1, 0, f, 0) end
			corner(d, UDim.new(0.5, 0)); d.Parent = stamp
		end
	end
	for _ = 1, 3 do RunService.Heartbeat:Wait() end              -- (let the layout settle before measuring)
	if gone then return end
	-- the letter's size follows its words: the handwriting font can finish loading a moment later and the lines grow, so
	-- it is measured again whenever they do (a long letter on a short screen scales down to fit)
	local room = vp.Y - 30
	local fit = Instance.new("UIScale"); fit.Parent = inner
	local function fitSize()
		local h = list.AbsoluteContentSize.Y + pad.PaddingTop.Offset + pad.PaddingBottom.Offset
		local s = math.min(1, room / math.max(h, 1))
		fit.Scale = s
		return UDim2.fromOffset(LW * s, h * s)
	end
	local opened = false
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if opened and card.Parent then card.Size = fitSize() end end)
	tw(card, 0.45, {Size = fitSize(), Position = UDim2.fromOffset(centre.X, centre.Y)}, Enum.EasingStyle.Back).Completed:Connect(function()
		opened = true
		if card.Parent then card.Size = fitSize() end
	end)
	task.wait(0.4)
	if gone then return end
	for _, l in ipairs(texts) do tw(l, 0.3, {TextTransparency = 0}) end
	tw(close, 0.3, {BackgroundTransparency = 0, TextTransparency = 0}); tw(stamp, 0.3, {BackgroundTransparency = 0}); tw(stS, 0.3, {Transparency = 0})
	for _, d in ipairs(stamp:GetDescendants()) do
		if d.Name == "Perf" then tw(d, 0.3, {BackgroundTransparency = 0})
		elseif d:IsA("TextLabel") then tw(d, 0.3, {TextTransparency = 0})
		elseif d:IsA("ViewportFrame") then tw(d, 0.3, {ImageTransparency = 0, BackgroundTransparency = 0}) end
	end
	task.delay(0.4, function() env:Destroy() end)
	-- closing
	local done = false
	finish = function()
		if done then return end
		done = true
		tw(shade, 0.25, {BackgroundTransparency = 1})
		local cs2 = Instance.new("UIScale"); cs2.Parent = card
		tw(cs2, 0.25, {Scale = 0.6}); tw(card, 0.25, {BackgroundTransparency = 1}); tw(cs, 0.25, {Transparency = 1})
		for _, l in ipairs(texts) do tw(l, 0.2, {TextTransparency = 1}) end
		close.Visible = false; stamp.Visible = false
		task.delay(0.3, function() g:Destroy() end)
		if con.Connected then con:Disconnect() end
		if pg:GetAttribute("OpenPanel") == "mail" then pg:SetAttribute("OpenPanel", nil) end
		reading = false
	end
	close.Activated:Connect(finish)
	shade.Activated:Connect(finish)
	if gone then finish() end
end
open = function(m)
	if reading then return end
	reading = true
	local ok, L = pcall(function() return act:InvokeServer("open") end)
	if not ok or type(L) ~= "table" then reading = false return end
	if L.none then
		note(L.more and "No new mail yet. The squirrels send one letter a day - check back tomorrow!" or "You have read every letter so far. More are on the way!", 5)
		reading = false
		return
	end
	pg:SetAttribute("OpenPanel", "mail")
	-- the envelope pops out of the mailbox door first
	local cam = workspace.CurrentCamera
	local start = Vector2.new(screen().X / 2, screen().Y * 0.8)
	local door = m and m:FindFirstChild("Door", true)
	if door and cam then
		local e = Instance.new("Part"); e.Name = "FlyingLetter"; e.Size = Vector3.new(1.1, 0.75, 0.05); e.Color = CREAM; e.Material = Enum.Material.SmoothPlastic
		e.Anchored = true; e.CanCollide = false; e.CanQuery = false; e.CanTouch = false; e.CFrame = door.CFrame; e.Parent = workspace
		local sealP = Instance.new("Part"); sealP.Shape = Enum.PartType.Cylinder; sealP.Size = Vector3.new(0.06, 0.28, 0.28); sealP.Color = C(196, 58, 52)
		sealP.Anchored = true; sealP.CanCollide = false; sealP.CanQuery = false; sealP.CanTouch = false; sealP.Parent = e
		local goalPos = door.Position + door.CFrame.LookVector * -1.6 + Vector3.new(0, 1.4, 0)   -- out of the door (its Back face looks out) and up
		local v = Instance.new("NumberValue")
		local c0 = door.CFrame
		v.Changed:Connect(function(a)
			local p = c0.Position:Lerp(goalPos, a)
			local cf = CFrame.lookAt(p, cam.CFrame.Position) * CFrame.Angles(0, 0, math.rad(25 * (1 - a)))
			e.CFrame = cf; sealP.CFrame = cf * CFrame.new(0, 0, -0.04) * CFrame.Angles(0, math.rad(90), 0)
		end)
		tw(v, 0.45, {Value = 1}, Enum.EasingStyle.Back).Completed:Wait()
		local sp, onScreen = cam:WorldToViewportPoint(e.Position)
		if onScreen then start = Vector2.new(sp.X, sp.Y) end
		v:Destroy(); e:Destroy()
	end
	showLetter(L, start)
end

_G.MailPreviewOpen = function() task.spawn(open, box.model) end
return "client preview running"

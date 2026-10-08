-- PolpoClient (RunContext Client, lives in workspace.Grotta): draws Polpo Brontolone from the server's state - his body in
-- the pool (lifts when he is roused, sinks to sulk), his eight arms (a lazy wave, the front pair raised when he watches
-- you, one arm whipping up for the grab and curling in front of his face with the player in it, the fling), bonk flinches,
-- dizzy stars; the grabbed player's own screen (pinned in the tentacle, flung out of the cave in a somersault, a wobble on
-- landing) and the ink - a cloud in the cave and a dark splat over the victim's screen. Cages open and the captives hop
-- out as in the croc game; the "all three free" toast; his grumbles through ReplicatedStorage.SquirrelBubble (no sound).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local G = script.Parent
local polpo = G:WaitForChild("PolpoBrontolone")
local evt = G:WaitForChild("PolpoEvent")
local C = Color3.fromRGB
local function A(n, d) local v = G:GetAttribute(n); if v == nil then return d end return v end
local function now() return workspace:GetServerTimeNow() end
local WATER_Y = A("WaterY", -53)
local FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local HOME = polpo:GetAttribute("Home")
local NAME = A("PolpoName", "Polpo Brontolone")

-- ---- the model and its bones (streaming may swap the part: looked up again when it changes)
local body, bones, armAxes
local ARMS = {}
for k = 0, 7 do ARMS[k] = {"Arm" .. k .. "a", "Arm" .. k .. "b", "Arm" .. k .. "c"} end
local function bind()
	local b = polpo:FindFirstChild("Octopus")
	if not b then body = nil return end
	if b == body then return end
	body = b; bones = {}; armAxes = {}
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("Bone") then bones[d.Name] = d end end
	for k = 0, 7 do
		local a, c = bones["Arm" .. k .. "a"], bones["Arm" .. k .. "c"]
		if a and c then
			local r = b.CFrame:VectorToObjectSpace(c.WorldPosition - a.WorldPosition)
			r = Vector3.new(r.X, 0, r.Z)
			r = r.Magnitude > 0.01 and r.Unit or Vector3.new(0, 0, -1)
			armAxes[k] = {radial = r, tangent = Vector3.yAxis:Cross(r)}
		end
	end
	if not HOME then HOME = polpo:GetAttribute("Home") or b.CFrame end
end
bind()
polpo.DescendantAdded:Connect(function() task.defer(bind) end)

-- ---- bones: a pose is {lift, sweep, twist} per arm bone (degrees; lift positive raises the arm, LiftSign fixes the
-- mesh's handedness), {pitch, yaw, roll} for the Head. The croc's method: an axis-angle in each bone's own frame.
local cur = {}
local function applyBones(want, dt)
	if not body or not bones then return end
	local k = 1 - math.exp(-dt * 10)
	local mcf = body.CFrame
	local upW, rightW, fwdW = mcf.UpVector, mcf.RightVector, mcf.LookVector
	local SIGN = A("LiftSign", -1)
	local function set(name, ax1, a1, ax2, a2, ax3, a3)
		local b = bones[name]; if not b then return end
		local c = cur[name]; if not c then c = {0, 0, 0}; cur[name] = c end
		c[1] += (a1 - c[1]) * k; c[2] += (a2 - c[2]) * k; c[3] += (a3 - c[3]) * k
		if math.abs(c[1]) + math.abs(c[2]) + math.abs(c[3]) < 0.01 then b.Transform = CFrame.identity return end
		local parent = b.Parent
		local pw = (parent:IsA("Bone") and parent.TransformedWorldCFrame) or mcf
		local R = (pw * b.CFrame).Rotation
		b.Transform = CFrame.fromAxisAngle(R:VectorToObjectSpace(ax1), math.rad(c[1]))
			* CFrame.fromAxisAngle(R:VectorToObjectSpace(ax2), math.rad(c[2]))
			* CFrame.fromAxisAngle(R:VectorToObjectSpace(ax3), math.rad(c[3]))
	end
	for ki = 0, 7 do
		local ax = armAxes and armAxes[ki]
		if ax then
			local tanW, radW = mcf:VectorToWorldSpace(ax.tangent), mcf:VectorToWorldSpace(ax.radial)
			for _, name in ipairs(ARMS[ki]) do
				local w = want[name]
				set(name, tanW, (w and w[1] or 0) * SIGN, upW, w and w[2] or 0, radW, w and w[3] or 0)
			end
		end
	end
	local h = want.Head
	set("Head", rightW, h and h[1] or 0, upW, h and h[2] or 0, fwdW, h and h[3] or 0)
end

-- ---- little effects (the croc's)
local function billboard(text, at, colour, secs, size)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(at); p.Parent = workspace
	local g = Instance.new("BillboardGui"); g.Size = UDim2.fromOffset(240, 60); g.AlwaysOnTop = true; g.LightInfluence = 0
	g.MaxDistance = 120; g.Parent = p
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Text = text
	t.FontFace = FONT; t.TextSize = size or 30; t.TextColor3 = colour or C(255, 255, 255); t.Parent = g
	local st = Instance.new("UIStroke"); st.Thickness = 2.5; st.Color = C(40, 26, 14); st.Parent = t
	TweenService:Create(p, TweenInfo.new(secs or 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(at + Vector3.new(0, 2.2, 0))}):Play()
	TweenService:Create(t, TweenInfo.new(secs or 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
	TweenService:Create(st, TweenInfo.new(secs or 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
	Debris:AddItem(p, (secs or 1.1) + 0.1)
end
local function soundAt(id, at, vol, maxSecs)
	if type(id) == "number" then id = id > 0 and ("rbxassetid://" .. id) or "" end
	id = tostring(id or "")
	if id == "" then return end
	if not id:find("rbxassetid") then id = "rbxassetid://" .. id end
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(at); p.Parent = workspace
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = (vol or 1) * A("SoundVolume", 0.9)
	s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 12; s.RollOffMaxDistance = 140; s.Parent = p
	s:Play(); Debris:AddItem(p, 8)
	if maxSecs then task.delay(maxSecs, function() if s.Parent then TweenService:Create(s, TweenInfo.new(0.15), {Volume = 0}):Play() end end) end   -- a long clip, cut short
end
local function sound(attr, at, vol, maxSecs) soundAt(A(attr, ""), at, vol, maxSecs) end
local function soundOne(attr, at, vol)
	local ids = {}
	for d in tostring(A(attr, "")):gmatch("%d+") do table.insert(ids, d) end
	if #ids > 0 then soundAt(ids[math.random(#ids)], at, vol) end
end
local function splash(at, n)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(2, 0.2, 2); p.CFrame = CFrame.new(at.X, WATER_Y + 0.1, at.Z); p.Parent = workspace
	local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(6, 12); e.SpreadAngle = Vector2.new(35, 35)
	e.EmissionDirection = Enum.NormalId.Top; e.Lifetime = NumberRange.new(0.5, 0.9); e.Acceleration = Vector3.new(0, -40, 0)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.1)})
	e.Color = ColorSequence.new(C(220, 240, 255)); e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
	e.LightEmission = 0.3; e.Parent = p
	e:Emit(n or 30)
	Debris:AddItem(p, 2)
end
-- INK (Shannon: ink cloud on the grab and the fling): a dark cloud boils up from the water in front of him
local function inkCloud(at, n)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(5, 1, 5); p.CFrame = CFrame.new(at.X, WATER_Y + 0.6, at.Z); p.Parent = workspace
	local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(4, 9); e.SpreadAngle = Vector2.new(70, 70)
	e.EmissionDirection = Enum.NormalId.Top; e.Lifetime = NumberRange.new(1.3, 2.0); e.Acceleration = Vector3.new(0, -2, 0); e.Drag = 2.5
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(0.5, 6), NumberSequenceKeypoint.new(1, 7.5)})
	e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(38, 16, 52)), ColorSequenceKeypoint.new(1, C(20, 10, 30))})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.6, 0.45), NumberSequenceKeypoint.new(1, 1)})
	e.LightEmission = 0; e.LightInfluence = 0.6; e.RotSpeed = NumberRange.new(-40, 40); e.Rotation = NumberRange.new(0, 360)
	e.Parent = p
	e:Emit(n or 40)
	Debris:AddItem(p, 3)
end
-- the victim's screen: ink splats that fade (no buttons, so nothing on a phone is under it)
local function inkScreen()
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
	local old = pg:FindFirstChild("PolpoInk"); if old then old:Destroy() end
	local g = Instance.new("ScreenGui"); g.Name = "PolpoInk"; g.ResetOnSpawn = false; g.DisplayOrder = 18; g.IgnoreGuiInset = true; g.Parent = pg
	local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900, 420)
	for i = 1, 9 do
		local f = Instance.new("Frame"); f.BorderSizePixel = 0; f.BackgroundColor3 = C(30, 12, 42); f.Active = false
		local d = math.random(math.floor(vs.Y * 0.25), math.floor(vs.Y * 0.6))
		f.Size = UDim2.fromOffset(d, d); f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset(math.random(0, vs.X), math.random(0, vs.Y))
		f.BackgroundTransparency = 0.25 + math.random() * 0.2
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.5, 0); c.Parent = f
		f.Parent = g
		TweenService:Create(f, TweenInfo.new(1.6 + math.random() * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1, Size = UDim2.fromOffset(d * 1.3, d * 1.3)}):Play()
	end
	Debris:AddItem(g, 2.8)
end
local stars
local function showStars(secs)
	if stars then stars:Destroy() end
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2); p.Parent = workspace
	local g = Instance.new("BillboardGui"); g.Size = UDim2.fromOffset(230, 90); g.AlwaysOnTop = false; g.LightInfluence = 0; g.Parent = p
	for i = 1, 3 do
		local t = Instance.new("TextLabel"); t.Name = "Star"; t.BackgroundTransparency = 1; t.Size = UDim2.fromOffset(40, 40)
		t.AnchorPoint = Vector2.new(0.5, 0.5); t.Text = utf8.char(0x2605); t.TextSize = 36; t.TextColor3 = C(255, 222, 80); t.Parent = g
		local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = C(120, 80, 10); st.Parent = t
	end
	stars = p
	Debris:AddItem(p, secs)
end
local function bonkSign(at, sub)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(at); p.Parent = workspace
	local g = Instance.new("BillboardGui"); g.Size = UDim2.fromOffset(280, 96); g.AlwaysOnTop = true; g.LightInfluence = 0
	g.MaxDistance = 140; g.Parent = p
	local fades = {}
	local function line(text, y, h, size, colour)
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.fromOffset(0, y); t.Size = UDim2.new(1, 0, 0, h)
		t.Text = text; t.FontFace = FONT; t.TextSize = size; t.TextColor3 = colour; t.Parent = g
		local st = Instance.new("UIStroke"); st.Thickness = 2.5; st.Color = C(40, 26, 14); st.Parent = t
		table.insert(fades, t); table.insert(fades, st)
	end
	line("BONK!", 0, 54, 46, C(255, 236, 140))
	if sub then line(sub, 56, 32, 24, C(255, 255, 255)) end
	local secs = 1.3
	TweenService:Create(p, TweenInfo.new(secs, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(at + Vector3.new(0, 2.2, 0))}):Play()
	for _, o in ipairs(fades) do
		TweenService:Create(o, TweenInfo.new(secs, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {[o:IsA("UIStroke") and "Transparency" or "TextTransparency"] = 1}):Play()
	end
	Debris:AddItem(p, secs + 0.1)
end
local function dizzyBirds(who, secs)
	local ch = who and who.Character
	local head = ch and ch:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("PolpoDizzy"); if old then old:Destroy() end
	local g = Instance.new("BillboardGui"); g.Name = "PolpoDizzy"; g.Adornee = head; g.Size = UDim2.new(4.4, 0, 1.7, 0)
	g.StudsOffset = Vector3.new(0, 1.05, 0); g.LightInfluence = 0; g.MaxDistance = 90; g.Parent = head
	local items = {}
	for i = 1, 5 do
		local star = i <= 3
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Size = star and UDim2.fromScale(0.2, 0.52) or UDim2.fromScale(0.12, 0.32)
		t.Text = star and utf8.char(0x2605) or utf8.char(0x2726); t.TextScaled = true; t.FontFace = FONT
		t.TextColor3 = star and C(255, 214, 64) or C(255, 246, 190); t.Parent = g
		if star then local st = Instance.new("UIStroke"); st.Thickness = 1.2; st.Color = C(150, 96, 12); st.Parent = t end
		table.insert(items, t)
	end
	local id = A("DizzySound", "")
	if type(id) == "number" then id = id > 0 and ("rbxassetid://" .. id) or "" end
	if id ~= "" then
		local s = Instance.new("Sound"); s.SoundId = id; s.Volume = A("SoundVolume", 0.9)
		s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 90; s.Parent = head
		s:Play(); Debris:AddItem(s, math.max(secs, 4))
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local u = os.clock() - t0
		if u > secs or not g.Parent then conn:Disconnect(); if g.Parent then g:Destroy() end return end
		local fade = math.clamp((secs - u) / 0.5, 0, 1)
		for i, lbl in ipairs(items) do
			local a = u * 7.5 + (i <= 3 and (i - 1) * (math.pi * 2 / 3) or (i - 3.5) * math.pi + 0.9)
			local depth = math.sin(a)
			lbl.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.36, 0.5 + depth * 0.2)
			local glint = i > 3 and (0.35 + 0.65 * math.abs(math.sin(u * 9 + i))) or 1
			lbl.TextTransparency = 1 - fade * glint * (0.45 + 0.55 * (depth + 1) / 2)
			local st = lbl:FindFirstChildOfClass("UIStroke"); if st then st.Transparency = lbl.TextTransparency end
			lbl.ZIndex = depth > 0 and 2 or 1
		end
	end)
end
-- his grumbles: the one bubble every squirrel uses, without the squirrel sound; not too often, only for players near
local BubbleMod, lastBubble = nil, 0
local function grumble(text, secs)
	if os.clock() - lastBubble < 5 then return end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (hrp and HOME) or (hrp.Position - HOME.Position).Magnitude > 70 then return end
	if not BubbleMod then
		local ok, mod = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("SquirrelBubble", 5)) end)
		if ok then BubbleMod = mod end
	end
	if BubbleMod then lastBubble = os.clock(); BubbleMod.say(polpo, text, {secs = secs or 3, sound = false}) end
end
local function celebrate(names)
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
	local old = pg:FindFirstChild("PolpoToast"); if old then old:Destroy() end
	local g = Instance.new("ScreenGui"); g.Name = "PolpoToast"; g.ResetOnSpawn = false; g.DisplayOrder = 19; g.IgnoreGuiInset = true; g.Parent = pg
	local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, -150)
	card.Size = UDim2.fromOffset(390, 104); card.BackgroundColor3 = C(38, 30, 52); card.BorderSizePixel = 0; card.Parent = g
	local ck = Instance.new("UICorner"); ck.CornerRadius = UDim.new(0, 16); ck.Parent = card
	local cs = Instance.new("UIStroke"); cs.Color = C(240, 196, 110); cs.Thickness = 2; cs.Parent = card
	local list = {}
	for _, n in ipairs(type(names) == "table" and names or {}) do if type(n) == "string" then table.insert(list, n) end end
	local who = #list == 0 and "you" or (#list == 1 and list[1]) or (table.concat(list, ", ", 1, #list - 1) .. " & " .. list[#list])
	local function line(text, y, h, size, colour)
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.new(0, 14, 0, y); t.Size = UDim2.new(1, -28, 0, h)
		t.Text = text; t.FontFace = FONT; t.TextSize = size; t.TextColor3 = colour; t.TextWrapped = true; t.Parent = card
		return t
	end
	line("Evviva! All 3 squirrels are free!", 14, 32, 24, C(255, 244, 214))
	line("The squirrels say grazie, " .. who .. "! " .. NAME .. " grumbles.", 52, 40, 18, C(240, 196, 110))
	TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 62)}):Play()
	local COLOURS = {C(255, 120, 120), C(255, 206, 90), C(120, 210, 140), C(120, 170, 255), C(230, 140, 230), C(255, 255, 255)}
	task.delay(0.45, function()
		for i = 1, 34 do
			local bit = Instance.new("Frame"); bit.BorderSizePixel = 0; bit.Size = UDim2.fromOffset(math.random(6, 10), math.random(8, 14))
			bit.BackgroundColor3 = COLOURS[math.random(#COLOURS)]; bit.AnchorPoint = Vector2.new(0.5, 0.5)
			local x0 = math.random(-190, 190)
			bit.Position = UDim2.new(0.5, x0, 0, 70 + math.random(0, 40)); bit.Rotation = math.random(0, 360); bit.Parent = g
			local fall = math.random(260, 420)
			TweenService:Create(bit, TweenInfo.new(math.random(14, 22) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, x0 + math.random(-60, 60), 0, 70 + fall), Rotation = bit.Rotation + math.random(-360, 360), BackgroundTransparency = 1}):Play()
		end
	end)
	local ss = workspace:FindFirstChild("SquirrelScripts")
	local fid = tostring(ss and (ss:GetAttribute("FoundSound_porto") or ss:GetAttribute("FoundSound")) or "9116394876"):match("%d+")
	if fid then local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. fid; s.Volume = 0.8; s.Parent = g; s:Play() end
	local lx, lz = A("LedgeX", nil), A("LedgeZ", nil)
	if lx and lz then
		local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
		p.Size = Vector3.new(4, 0.2, 4); p.CFrame = CFrame.new(lx, WATER_Y + 4, lz); p.Parent = workspace
		local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(14, 24); e.SpreadAngle = Vector2.new(40, 40)
		e.EmissionDirection = Enum.NormalId.Top; e.Lifetime = NumberRange.new(1.6, 2.6); e.Acceleration = Vector3.new(0, -26, 0)
		e.Drag = 1.5; e.RotSpeed = NumberRange.new(-220, 220); e.Rotation = NumberRange.new(0, 360)
		e.Size = NumberSequence.new(0.35); e.Shape = Enum.ParticleEmitterShape.Box
		e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 120, 120)), ColorSequenceKeypoint.new(0.33, C(255, 206, 90)),
			ColorSequenceKeypoint.new(0.66, C(120, 170, 255)), ColorSequenceKeypoint.new(1, C(120, 210, 140))})
		e.Parent = p; e:Emit(90)
		Debris:AddItem(p, 4)
	end
	task.delay(5.2, function()
		if not card.Parent then return end
		local t = TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -150)})
		t:Play(); t.Completed:Connect(function() g:Destroy() end)
	end)
end

-- ---- the grabbed player's own screen
local held, heldUntil = false, 0
local dizzyUntil = nil
local flying = nil
local function myChar() local c = player.Character; return c, c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid") end
local function banner(text, sub)
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
	local old = pg:FindFirstChild("PolpoBanner"); if old then old:Destroy() end
	-- PHONES: nothing overlaps (Shannon) - his bubble sits where he is on the screen, which is right where the banner goes
	-- when he has you; any bubble showing goes away first, and he says nothing new to the player he is holding
	local bg = pg:FindFirstChild("SquirrelBubbleGui")
	if bg then for _, b in ipairs(bg:GetChildren()) do if b.Name == "SquirrelBubble" then b:Destroy() end end end
	lastBubble = os.clock()
	local g = Instance.new("ScreenGui"); g.Name = "PolpoBanner"; g.ResetOnSpawn = false; g.DisplayOrder = 20; g.Parent = pg
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.AnchorPoint = Vector2.new(0.5, 0); t.Position = UDim2.new(0.5, 0, 0.16, 0)
	t.Size = UDim2.fromOffset(520, 70); t.Text = text; t.FontFace = FONT; t.TextSize = 56; t.TextColor3 = C(255, 244, 214); t.Parent = g
	local st = Instance.new("UIStroke"); st.Thickness = 4; st.Color = C(60, 30, 14); st.Parent = t
	if sub then
		local u = Instance.new("TextLabel"); u.BackgroundTransparency = 1; u.AnchorPoint = Vector2.new(0.5, 0); u.Position = UDim2.new(0.5, 0, 0.16, 68)
		u.Size = UDim2.fromOffset(520, 34); u.Text = sub; u.FontFace = FONT; u.TextSize = 24; u.TextColor3 = C(255, 255, 255); u.Parent = g
		local us = Instance.new("UIStroke"); us.Thickness = 2.5; us.Color = C(60, 30, 14); us.Parent = u
	end
	task.delay(1.6, function()
		for _, d in ipairs(g:GetDescendants()) do
			if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.5), {TextTransparency = 1}):Play() end
			if d:IsA("UIStroke") then TweenService:Create(d, TweenInfo.new(0.5), {Transparency = 1}):Play() end
		end
		Debris:AddItem(g, 0.6)
	end)
end
local function armIndex() return polpo:GetAttribute("Arm") or 1 end
local function tipCF(k)
	local b = bones and bones["Arm" .. k .. "c"]
	if not b then return body and body.CFrame end
	return b.TransformedWorldCFrame
end
evt.OnClientEvent:Connect(function(kind, a, b)
	if kind == "grab" then
		held = true; heldUntil = os.clock() + (a or 1.7) + 2.5
		local _, _, hum = myChar()
		if hum then hum.PlatformStand = true end
		banner("PRESO!", NAME .. " grabbed you!")
		inkScreen()
	elseif kind == "fling" then
		held = false
		local _, hrp = myChar()
		if hrp then
			local p0, p1 = hrp.Position, a + Vector3.new(0, 3, 0)
			flying = {p0 = p0, p1 = p1, t0 = os.clock(), tf = b or 1.1, h = 5 + (p1 - p0).Magnitude * 0.18}
		end
		banner("VIA!", "Out of my grotto!")
	elseif kind == "fled" then
		banner("BONK!", "He's dizzy and sulking - free the squirrels!")
	elseif kind == "capped" then
		banner("Grazie!", "The squirrels thank you - no more acorns for rescues this hour.")
	end
end)
RunService:BindToRenderStep("PolpoHold", Enum.RenderPriority.Character.Value + 1, function()
	if dizzyUntil then
		local _, _, hum = myChar()
		local left = dizzyUntil - os.clock()
		if not hum or left <= 0 then
			if hum then hum.CameraOffset = Vector3.zero end
			dizzyUntil = nil
		else
			local k = math.clamp(left / 1.0, 0, 1)
			local tt = os.clock()
			hum.CameraOffset = Vector3.new(math.sin(tt * 5.5) * 0.55, math.sin(tt * 3.3) * 0.25, 0) * k
		end
	end
	if flying then
		local _, hrp, hum = myChar()
		if not hrp or not hum then flying = nil return end
		local u = (os.clock() - flying.t0) / flying.tf
		local dir = (flying.p1 - flying.p0) * Vector3.new(1, 0, 1)
		local look = dir.Magnitude > 0.1 and dir.Unit or Vector3.zAxis
		if u >= 1 then
			hrp.CFrame = CFrame.lookAt(flying.p1, flying.p1 - look)
			hrp.AssemblyLinearVelocity = Vector3.new(0, -8, 0); hrp.AssemblyAngularVelocity = Vector3.zero
			hum.PlatformStand = false
			flying = nil
			dizzyUntil = os.clock() + 3.2
			return
		end
		local pos = flying.p0:Lerp(flying.p1, u) + Vector3.new(0, flying.h * 4 * u * (1 - u), 0)
		hrp.CFrame = CFrame.lookAt(pos, pos - look) * CFrame.Angles(u * math.pi * 2, 0, 0)
		hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
		return
	end
	if not held then return end
	if os.clock() > heldUntil then held = false; local _, _, hum = myChar(); if hum then hum.PlatformStand = false end return end
	local _, hrp = myChar()
	local tip = tipCF(armIndex())
	if hrp and tip and body then
		-- wrapped in the tentacle's tip, looking back at him
		local at = tip.Position + Vector3.new(0, 1.0, 0)
		local look = body.Position + Vector3.new(0, 2, 0)
		hrp.CFrame = CFrame.lookAt(at, Vector3.new(look.X, at.Y, look.Z))
		hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
	end
end)

-- ---- effects everyone sees
local bonkedAt, missAt = nil, nil
local function frontPos() return body and (body.CFrame * CFrame.new(0, 0, -A("FrontOffset", 7))).Position or (HOME and HOME.Position) or Vector3.zero end
local function headTop() return body and body.Position + Vector3.new(0, A("HeadUp", 2.2) + 2.6, 0) or Vector3.zero end
evt.OnClientEvent:Connect(function(kind, a, b, c, d)
	if kind == "bonk" then
		bonkedAt = os.clock()
		local top = headTop()
		splash(frontPos(), 22)
		local n, need = c or 0, d or 3
		if not (n > 0 and n >= need) then showStars(1.4) end
		local sub
		if b == player.UserId and n > 0 and n < need then sub = (need - n == 1) and "1 more bonk!" or ((need - n) .. " more bonks!") end
		bonkSign(a + Vector3.new(0, 1.8, 0), sub)
		sound("BonkSound", a, 1, A("BonkSoundMax", 1.0))        -- her pick, shortened (BonkSoundMax seconds)
		task.delay(0.12, function() soundOne("OuchSound", top, 1) end)
		if b == player.UserId then billboard("+" .. tostring(A("BonkPrize", 1)), a + Vector3.new(2.2, 0.6, 0), C(255, 214, 90), 1.0, 24) end
	elseif kind == "grabfx" then
		local f = frontPos()
		splash(f, 40); inkCloud(f, 45); sound("SplashSound", f, 0.8); sound("InkSound", f, 1); sound("GrabSound", f, 1)
		billboard("PRESO!", f + Vector3.new(0, 4, 0), C(255, 244, 214), 1.0, 36)
		if a ~= player.UserId then grumble("Preso! Nessuno entra nella mia grotta!", 2.5) end
	elseif kind == "flingfx" then
		local f = frontPos()
		inkCloud(f, 30); sound("InkSound", f, 0.8)
		billboard("Via!", f + Vector3.new(0, 5, 0), C(200, 240, 255), 1.0, 30)
		local who = Players:GetPlayerByUserId(a or 0)
		if who then task.delay((b or 1.1) + 0.05, function() dizzyBirds(who, 3.8) end) end
	elseif kind == "stomp" then
		-- someone landed on his head (Shannon: "he should grumble like when you hit him with the acorn")
		bonkedAt = os.clock()
		splash(frontPos(), 16)
		task.delay(0.1, function() soundOne("OuchSound", headTop(), 1) end)
		grumble("Ehi! Giu' dalla mia testa!", 2.5)
	elseif kind == "miss" then
		missAt = os.clock()
		local f = frontPos()
		splash(f, 26); sound("SplashSound", f, 0.7)
	elseif kind == "allfree" then
		celebrate(a)
	elseif kind == "rescued" then
		local cage = G:FindFirstChild("Cages") and G.Cages:FindFirstChild(a)
		local captive = cage and cage:FindFirstChild("Captive")
		local door = cage and cage:FindFirstChild("Door")
		grumble("Ehi! I miei prigionieri!", 2.5)
		if door then
			local hinge = door:GetAttribute("Hinge")
			if hinge then
				for _, dd in ipairs(door:GetChildren()) do
					if dd:IsA("BasePart") then
						local rel = hinge:ToObjectSpace(dd.CFrame)
						local v = Instance.new("NumberValue"); v.Value = 0
						v.Changed:Connect(function(x) dd.CFrame = hinge * CFrame.Angles(0, math.rad(x), 0) * rel end)
						TweenService:Create(v, TweenInfo.new(0.45, Enum.EasingStyle.Back), {Value = 105}):Play()
						Debris:AddItem(v, 1)
					end
				end
			end
		end
		if captive then
			local cf0 = captive:GetPivot()
			local out = cf0.LookVector
			billboard("Grazie!", cf0.Position + Vector3.new(0, 2.4, 0), C(255, 255, 255), 1.4, 30)
			sound("RescueSound", cf0.Position, 1)
			local v = Instance.new("NumberValue"); v.Value = 0
			v.Changed:Connect(function(u)
				local hop = math.abs(math.sin(u * math.pi * 2)) * 1.6
				captive:PivotTo(cf0 + out * (u * 3) + Vector3.new(0, hop, 0))
			end)
			TweenService:Create(v, TweenInfo.new(1.1, Enum.EasingStyle.Linear), {Value = 1}):Play()
			task.delay(1.15, function()
				for _, dd in ipairs(captive:GetDescendants()) do if dd:IsA("BasePart") then dd.LocalTransparencyModifier = 1 end end
			end)
			Debris:AddItem(v, 2)
		end
	end
end)
-- cages follow their Occupied attribute (late joiners too)
local function syncCage(cage)
	local occ = cage:GetAttribute("Occupied")
	local captive = cage:FindFirstChild("Captive")
	if captive then
		if not cage:GetAttribute("CapHome") then cage:SetAttribute("CapHome", captive:GetPivot()) end
		if occ then
			captive:PivotTo(cage:GetAttribute("CapHome"))
			for _, d in ipairs(captive:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end
		else
			for _, d in ipairs(captive:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end
		end
	end
	local door = cage:FindFirstChild("Door")
	local hinge = door and door:GetAttribute("Hinge")
	if door and hinge then
		for _, d in ipairs(door:GetChildren()) do
			if d:IsA("BasePart") then
				if not d:GetAttribute("Home") then d:SetAttribute("Home", d.CFrame) end
				local home = d:GetAttribute("Home")
				d.CFrame = occ and home or (hinge * CFrame.Angles(0, math.rad(105), 0) * hinge:ToObjectSpace(home))
			end
		end
	end
end
local function watchCages()
	local cg = G:FindFirstChild("Cages")
	if not cg then return end
	for _, cage in ipairs(cg:GetChildren()) do
		if not cage:GetAttribute("Watched") then
			cage:SetAttribute("Watched", true)
			cage:GetAttributeChangedSignal("Occupied"):Connect(function()
				if cage:GetAttribute("Occupied") then syncCage(cage) else task.delay(1.3, function() syncCage(cage) end) end
			end)
			syncCage(cage)
		end
	end
end
watchCages()
G.DescendantAdded:Connect(function(d) if d:IsA("Model") and d.Parent and d.Parent.Name == "Cages" then task.defer(watchCages) end end)

-- ---- every frame: place him, then pose him
local yawCur, lift = 0, 0
local lastState, grumbled = nil, {}
RunService.RenderStepped:Connect(function(dt)
	if not body then bind(); if not body then return end end
	if not HOME then return end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and (hrp.Position - HOME.Position).Magnitude > 160 then return end        -- far away: leave him be
	local t = now()
	local state = polpo:GetAttribute("State") or "lurk"
	local sAt = polpo:GetAttribute("StateAt") or 0
	local since = ((t % 4096) - sAt + 4096) % 4096
	local k = polpo:GetAttribute("Arm") or 1
	if state ~= lastState then
		lastState = state
		local fight = (state == "alert" or state == "grab" or state == "hold" or state == "smug" or state == "dizzy") or nil
		if player:GetAttribute("PolpoFight") ~= fight then player:SetAttribute("PolpoFight", fight) end   -- the music client plays the adventure track
		if state == "alert" then grumble(({"Chi va la'?!", "Vattene dalla mia grotta!", "Brontolo... brontolo...", "Via! Via dalla mia grotta!"})[math.random(4)], 3)
		elseif state == "sulk" then grumble("Uffa... brontolo...", 3) end
	end
	-- yaw follows the server's, eased
	local wantYaw = polpo:GetAttribute("Yaw") or 0
	yawCur += (wantYaw - yawCur) * (1 - math.exp(-dt * 3))
	-- height: eyes at the water when he lurks; up when roused; curled high with someone in his grip; down to sulk
	local liftGoal = (state == "alert" and 1.2) or (state == "grab" and 1.6) or (state == "hold" and 2.2) or (state == "smug" and 1.0)
		or (state == "dizzy" and 0.8) or (state == "sulk" and -3.8) or 0
	lift += (liftGoal - lift) * (1 - math.exp(-dt * 3))
	local bob = math.sin(t * 1.1) * 0.25
	if bonkedAt then bob -= 0.5 * math.sin(math.pi * math.clamp((os.clock() - bonkedAt) / 0.45, 0, 1)) end
	local roll = math.sin(t * 0.7) * 1.5
	body.CFrame = HOME * CFrame.Angles(0, math.rad(yawCur), 0) * CFrame.new(0, lift + bob, 0) * CFrame.Angles(0, 0, math.rad(roll))
	-- the stepping stones over him (Shannon: "make the top of his head solid so you can jump over him"): an invisible
	-- collar at his mantle and a dome on his head, kept on his body on this screen (the local character collides with them)
	local hs, col = polpo:FindFirstChild("HeadStep"), polpo:FindFirstChild("Collar")
	if hs then hs.CFrame = body.CFrame * CFrame.new(0, 1.0, 0) end
	if col then col.CFrame = body.CFrame * CFrame.new(0, -6.5, 0) * CFrame.Angles(0, 0, math.pi / 2) end   -- a column from the bed to the waterline: no swimming under him

	-- ---- the pose
	local W = {}
	local function add(n, l, s, tw) local w = W[n]; if not w then w = {0, 0, 0}; W[n] = w end; w[1] += l or 0; w[2] += s or 0; w[3] += tw or 0 end
	-- the lazy wave, travelling out along each arm; slower and lower when he sulks
	local amp = (state == "sulk") and 0.4 or 1
	for ki = 0, 7 do
		local ph = t * 0.9 + ki * 0.8
		add(ARMS[ki][1], 5 * amp * math.sin(ph), 2 * math.sin(ph * 0.5 + ki), 0)
		add(ARMS[ki][2], 9 * amp * math.sin(ph - 0.7), 0, 0)
		add(ARMS[ki][3], 14 * amp * math.sin(ph - 1.4), 0, 0)
	end
	if state == "sulk" then
		for ki = 0, 7 do add(ARMS[ki][1], -8, 0, 0); add(ARMS[ki][2], -6, 0, 0); add(ARMS[ki][3], -4, 0, 0) end
		add("Head", 6, 10 * math.sin(t * 0.6), 0)
	elseif state == "alert" then
		-- the front pair raised, trembling; he leans at you
		local tr = 3 * math.sin(t * 9)
		for _, ki in ipairs({1, 2}) do add(ARMS[ki][1], 18 + tr, 0, 0); add(ARMS[ki][2], 14 + tr, 0, 0); add(ARMS[ki][3], 12 - tr, 0, 0) end
		add("Head", -6, 0, 0)
	elseif state == "grab" then
		-- the wind-up: the grabbing arm whips up and over
		local u = math.clamp(since / A("GrabWindup", 0.9), 0, 1)
		local other = k == 1 and 2 or 1
		add(ARMS[other][1], 16, 0, 0); add(ARMS[other][2], 12, 0, 0); add(ARMS[other][3], 10, 0, 0)
		add(ARMS[k][1], 12 + 33 * u, 0, 0); add(ARMS[k][2], 10 + 20 * u, 0, 0); add(ARMS[k][3], 12 + 10 * u, 0, 0)
		add("Head", -10 * u, 0, 0)
	elseif state == "hold" then
		local sq = 4 * math.sin(since * 14)
		add(ARMS[k][1], 45 + sq, 0, 0); add(ARMS[k][2], 30 + sq, 0, 0); add(ARMS[k][3], 22 - sq, 0, 0)
		local other = k == 1 and 2 or 1
		add(ARMS[other][1], 16, 0, 0); add(ARMS[other][2], 12, 0, 0); add(ARMS[other][3], 10, 0, 0)
		add("Head", -8, k == 1 and 10 or -10, 0)
	elseif state == "smug" then
		-- the fling: the arm snaps down, then he settles
		local u = math.clamp(since / 0.5, 0, 1)
		add(ARMS[k][1], 45 - 62 * u, 0, 0); add(ARMS[k][2], 30 - 42 * u, 0, 0); add(ARMS[k][3], 22 - 30 * u, 0, 0)
		add("Head", -4 + 8 * u, 0, 0)
	elseif state == "dizzy" then
		add("Head", 6 * math.sin(t * 5), 14 * math.sin(t * 5 + 1), 12 * math.cos(t * 5))
		for ki = 0, 7 do add(ARMS[ki][2], 10 * math.sin(t * 6 + ki), 0, 0); add(ARMS[ki][3], 16 * math.sin(t * 6 + ki + 1), 0, 0) end
		if not stars or not stars.Parent then showStars(A("DizzySeconds", 3) + 0.2); sound("GrumbleSound", body.Position, 1) end
	end
	if missAt then
		local u = os.clock() - missAt
		if u > 0.8 then missAt = nil else add(ARMS[k][1], -20 * math.sin(u / 0.8 * math.pi), 0, 0); add(ARMS[k][3], -30 * math.sin(u / 0.8 * math.pi), 0, 0) end
	end
	if bonkedAt then
		local u = os.clock() - bonkedAt
		if u > 1.2 then bonkedAt = nil
		else
			local knock = (u < 0.1 and 18 * u / 0.1) or (u < 0.35 and 18 - 32 * (u - 0.1) / 0.25) or (-14 * math.clamp(1 - (u - 0.35) / 0.5, 0, 1))
			local shake = math.clamp(1 - u / 1.2, 0, 1) * math.clamp((u - 0.25) / 0.15, 0, 1)
			add("Head", knock, 16 * math.sin(u * 24) * shake, 10 * math.sin(u * 19 + 1) * shake)
			local flinch = math.clamp(1 - math.abs(u - 0.15) / 0.35, 0, 1)
			for ki = 0, 7 do add(ARMS[ki][1], 14 * flinch, 0, 0); add(ARMS[ki][3], 20 * flinch, 0, 0) end
		end
	end
	applyBones(W, dt)
	if stars and stars.Parent then
		stars.CFrame = CFrame.new(headTop())
		local g = stars:FindFirstChildOfClass("BillboardGui")
		if g then
			for i, st in ipairs(g:GetChildren()) do
				if st.Name == "Star" then
					local a = t * 4 + i * (math.pi * 2 / 3)
					st.Position = UDim2.new(0.5, math.cos(a) * 80, 0.5, math.sin(a) * 18)
				end
			end
		end
	end
end)

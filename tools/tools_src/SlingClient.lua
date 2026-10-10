local tool = script.Parent
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local shoot = RS:WaitForChild("SlingShot")
local drawEvt = workspace:WaitForChild("Hoop"):WaitForChild("DrawEvent")
local C = Color3.fromRGB
local CollectionService = game:GetService("CollectionService")
local touchAim = (UIS.TouchEnabled and not UIS.MouseEnabled) or workspace.Hoop:GetAttribute("ForceTouch") == true   -- a phone: hold a button, the shot aims itself; a mouse aims with the cursor
if touchAim then tool.ManualActivationOnly = true end          -- so a tap on the screen (or a camera drag) is not a shot

local gui = Instance.new("ScreenGui"); gui.Name = "SlingUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 6; gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
-- a crosshair at the centre, for camera aiming
local cross = Instance.new("Frame"); cross.AnchorPoint = Vector2.new(0.5, 0.5); cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.fromOffset(26, 26); cross.BackgroundTransparency = 1; cross.Visible = false; cross.Parent = gui
-- the phone's trigger: a big round button, bottom right, that you hold to draw and let go of to shoot
local hold = Instance.new("TextButton"); hold.Name = "Shoot"; hold.AnchorPoint = Vector2.new(1, 1); hold.Position = UDim2.new(1, -26, 1, -150)
hold.Size = UDim2.fromOffset(150, 150); hold.BackgroundColor3 = C(255, 202, 62); hold.BackgroundTransparency = 0.08; hold.BorderSizePixel = 0
hold.Text = "HOLD\nTO SHOOT"; hold.Font = Enum.Font.FredokaOne; hold.TextSize = 24; hold.TextColor3 = C(84, 48, 18); hold.AutoButtonColor = false
hold.Visible = touchAim; hold.Parent = gui
local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(1, 0); hc.Parent = hold
local hs = Instance.new("UIStroke"); hs.Color = C(150, 98, 36); hs.Thickness = 3; hs.Parent = hold
local cs = Instance.new("UIStroke"); cs.Color = C(255, 246, 220); cs.Thickness = 2; cs.Parent = cross
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = cross
-- the draw: a bar that fills while you hold
local barBack = Instance.new("Frame"); barBack.AnchorPoint = Vector2.new(0.5, 1); barBack.Position = UDim2.new(0.5, 0, 1, -110)
barBack.Size = UDim2.fromOffset(220, 14); barBack.BackgroundColor3 = C(38, 30, 52); barBack.BackgroundTransparency = 0.25
barBack.BorderSizePixel = 0; barBack.Visible = false; barBack.Parent = gui
local bb = Instance.new("UICorner"); bb.CornerRadius = UDim.new(0, 7); bb.Parent = barBack
local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 1.5; bs.Parent = barBack
local bar = Instance.new("Frame"); bar.Size = UDim2.fromScale(0, 1); bar.BackgroundColor3 = C(255, 202, 62); bar.BorderSizePixel = 0; bar.Parent = barBack
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 7); bc.Parent = bar
-- a line of text: "BASKET!", "you need an acorn", the help line. The box HUGS ITS WORDS and wraps them inside it, in
-- crisp BuilderSans, with the gold line round the box rather than round the letters. The first one was a fixed 420 wide
-- in FredokaOne with its UIStroke on the text, and the help line ran out of both ends of it in fuzzy gold (Shannon:
-- "this will not do"). On a phone it stays clear of the big round button.
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -132)
note.Size = UDim2.fromOffset(0, 0); note.AutomaticSize = Enum.AutomaticSize.XY; note.TextWrapped = true
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0
note.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
note.TextSize = 20; note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1; note.Text = ""; note.Parent = gui
local nmax = Instance.new("UISizeConstraint"); nmax.MaxSize = Vector2.new(440, math.huge); nmax.Parent = note
local np = Instance.new("UIPadding"); np.PaddingLeft = UDim.new(0, 16); np.PaddingRight = UDim.new(0, 16)
np.PaddingTop = UDim.new(0, 8); np.PaddingBottom = UDim.new(0, 8); np.Parent = note
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local ns = Instance.new("UIStroke"); ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ns.Color = C(240, 200, 90); ns.Thickness = 1.5; ns.Transparency = 1; ns.Parent = note
local shownAt = 0
local function say(text, gold, secs)
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	nmax.MaxSize = Vector2.new(math.clamp(vw - (touchAim and 360 or 60), 240, 440), math.huge)
	note.Text = text; note.TextColor3 = gold and C(255, 214, 90) or C(255, 246, 220)
	note.BackgroundTransparency = 0.15; note.TextTransparency = 0; ns.Transparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(secs or (gold and 3.2 or 2.4), function()
		if shownAt ~= mine then return end
		local ti = TweenInfo.new(0.5)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(ns, ti, {Transparency = 1}):Play()
	end)
end

local charging, t0, conn = false, 0, nil
local function chargeSecs()
	local H = workspace:FindFirstChild("Hoop")
	return (H and H:GetAttribute("Charge")) or 1.5
end
local function stopBar()
	if conn then conn:Disconnect(); conn = nil end
	barBack.Visible = false; bar.Size = UDim2.fromScale(0, 1)
end
-- AT THE LAGOON THE SLINGSHOT IS FOR THE CROC (Shannon: "set me up with a slingshot so I can test the acorn to the head
-- of the croc"): within CrocRange of him, and nearer him than any hoop, a shot flies at his head (the cursor on him, or
-- a phone's button) or at the spot under the cursor, and the help line says so. Anywhere else it's the hoop game.
local function nearestHoopDist(pos)
	local best = math.huge
	for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
		local rx, rz = m:GetAttribute("RingX"), m:GetAttribute("RingZ")
		if rx and rz then best = math.min(best, Vector3.new(rx - pos.X, 0, rz - pos.Z).Magnitude) end
	end
	return best
end
-- (Oct 8 2026) and AT THE GROTTA AZZURRA it is for Polpo Brontolone, the octopus - the same way; targetKind says which
local targetKind = "croc"
local function nearCroc()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local lag = workspace:FindFirstChild("Lagoon")
	local croc = lag and lag:FindFirstChild("Croc")
	local body = croc and croc:FindFirstChild("Body")
	if body then
		local d = Vector3.new(body.Position.X - root.Position.X, 0, body.Position.Z - root.Position.Z).Magnitude
		if d <= (workspace.Hoop:GetAttribute("CrocRange") or 70) and d <= nearestHoopDist(root.Position) then
			targetKind = "croc"
			return body, lag:GetAttribute("CrocName") or "the croc"
		end
	end
	local gr = workspace:FindFirstChild("Grotta")
	local polpo = gr and gr:FindFirstChild("PolpoBrontolone")
	local ob = polpo and polpo:FindFirstChild("Octopus")
	if ob then
		local d = Vector3.new(ob.Position.X - root.Position.X, 0, ob.Position.Z - root.Position.Z).Magnitude
		if d <= (workspace.Hoop:GetAttribute("PolpoRange") or 70) and d <= nearestHoopDist(root.Position) then
			targetKind = "polpo"
			return ob, gr:GetAttribute("PolpoName") or "the octopus"
		end
	end
	return nil
end
-- does the line from the camera through the cursor pass through a box (his body, grown a little: he's a moving target)?
local function rayHitsBox(o, d, cf, half)
	local lo, ld = cf:PointToObjectSpace(o), cf:VectorToObjectSpace(d)
	local tmin, tmax = 0, 1e9
	for _, ax in ipairs({"X", "Y", "Z"}) do
		local oa, da, h = lo[ax], ld[ax], half[ax]
		if math.abs(da) < 1e-8 then
			if oa < -h or oa > h then return false end
		else
			local t1, t2 = (-h - oa) / da, (h - oa) / da
			if t1 > t2 then t1, t2 = t2, t1 end
			tmin, tmax = math.max(tmin, t1), math.min(tmax, t2)
			if tmin > tmax then return false end
		end
	end
	return true
end
local shownMode
local function helpLine()
	local body, name = nearCroc()
	shownMode = body and "croc" or "hoop"
	if body then
		say(touchAim and ("Hold the big button and let go - the acorn flies at " .. name .. "'s head!")
			or ("Put the cursor on " .. name .. ". Hold to draw, let go to bonk him on the head!"), false, 4.5)
	else
		say(touchAim and "Hold the big button to draw - longer goes further - let go to shoot. It flies at the nearest hoop."
			or "Put the cursor on the hoop. Hold to draw - longer goes further - let go to shoot.", false, 4.5)
	end
end
tool.Equipped:Connect(function()
	gui.Enabled = true
	helpLine()
end)
-- walking from one game to the other with it out: the help line changes with the game
task.spawn(function()
	while tool.Parent do
		task.wait(0.5)
		if gui.Enabled and shownMode and not charging then
			if (nearCroc() and "croc" or "hoop") ~= shownMode then helpLine() end
		end
	end
end)
-- the pull: plays from the handle while you hold, stops the moment you let go
local function drawSound()
	local handle = tool:FindFirstChild("Handle")
	return handle and handle:FindFirstChild("Draw")
end
-- the draw flag: on this screen at once, and through the server for everyone else's (SlingPose reads it)
local function drawing(on)
	local ch = player.Character
	if ch then ch:SetAttribute("SlingshotDraw", on or nil) end
	drawEvt:FireServer(on == true)
end
tool.Unequipped:Connect(function() gui.Enabled = false; charging = false; stopBar(); drawing(false); local snd = drawSound(); if snd then snd:Stop() end end)
-- THE REST (three shots, then the slingshot rests, at the croc and the hoops - the server counts and says so; this only
-- shows it): a line when the rest begins or a shot is tried, the phone's button counting down, a word when it's ready
local restUntil = 0
local function restLeft() return math.max(0, math.ceil(restUntil - os.clock())) end
local function resting(secs, started)
	restUntil = os.clock() + secs
	if started then
		local when = (secs == 60 and "a minute") or (secs > 60 and (math.floor(secs / 60 + 0.5) .. " minutes")) or (secs .. " seconds")
		say("That's three shots! Your slingshot needs a rest - ready again in " .. when .. ".", false, 4)
	else
		say("Your slingshot is resting - ready in " .. restLeft() .. " s.", false, 2.4)
	end
	local mine = restUntil
	task.spawn(function()
		while restUntil == mine and os.clock() < restUntil do
			if touchAim then hold.Text = "REST\n" .. restLeft(); hold.BackgroundColor3 = C(196, 184, 160) end
			task.wait(0.25)
		end
		if restUntil ~= mine then return end
		hold.Text = "HOLD\nTO SHOOT"; hold.BackgroundColor3 = C(255, 202, 62)
		if gui.Enabled then say("Your slingshot is ready again!", true, 2.4) end
	end)
end
local function beginDraw()
	if charging then return end
	if os.clock() < restUntil then say("Your slingshot is resting - ready in " .. restLeft() .. " s.", false, 2.4) return end
	charging = true; t0 = os.clock()
	drawing(true)
	barBack.Visible = true
	stopBar(); barBack.Visible = true
	local snd = drawSound()
	if snd then
		local H = workspace:FindFirstChild("Hoop")
		local id = H and tonumber(H:GetAttribute("DrawSoundId")) or 0
		if id > 0 then
			snd.SoundId = "rbxassetid://" .. id
			snd.Volume = (H and H:GetAttribute("DrawVolume")) or 0.8
			snd.TimePosition = 0
			snd:Play()
		end
	end
	conn = RunService.RenderStepped:Connect(function()
		bar.Size = UDim2.fromScale(math.clamp((os.clock() - t0) / chargeSecs(), 0, 1), 1)
	end)
end
local function endDraw()
	local snd = drawSound(); if snd then snd:Stop() end
	drawing(false)
	if not charging then return end
	charging = false
	local power = math.clamp((os.clock() - t0) / chargeSecs(), 0.12, 1)
	stopBar()
	local dir, kind, point
	local body = nearCroc()
	if body then
		-- at the lagoon: at his head (a phone always; with a mouse, the cursor on him or near him), or else at whatever
		-- is under the cursor. The server works out the arc.
		if touchAim then kind = targetKind
		else
			local ray = player:GetMouse().UnitRay
			if rayHitsBox(ray.Origin, ray.Direction, body.CFrame, body.Size / 2 + Vector3.new(2, 2, 2)) then kind = targetKind
			else
				local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
				local skip = {player.Character}
				local dl = workspace:FindFirstChild("SlingDraw_local"); if dl then table.insert(skip, dl) end
				rp.FilterDescendantsInstances = skip
				local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, rp)
				if hit then kind, point = "point", hit.Position end
			end
		end
	end
	if touchAim then
		-- a phone does not aim: the acorn flies at the nearest hoop; only the hold decides the distance
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local best, bestD
		for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
			local rx, rz = m:GetAttribute("RingX"), m:GetAttribute("RingZ")
			if rx and root then
				local d = Vector3.new(rx - root.Position.X, 0, rz - root.Position.Z)
				if not bestD or d.Magnitude < bestD then best, bestD = d, d.Magnitude end
			end
		end
		dir = (best and best.Magnitude > 0.1) and best.Unit or workspace.CurrentCamera.CFrame.LookVector
	else
		dir = player:GetMouse().UnitRay.Direction
	end
	shoot:FireServer(dir, power, kind, point)
end
tool.Activated:Connect(function() if not touchAim then beginDraw() end end)
tool.Deactivated:Connect(function() if not touchAim then endDraw() end end)
hold.InputBegan:Connect(function(io)
	if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then hold.BackgroundColor3 = C(255, 232, 150); beginDraw() end
end)
hold.InputEnded:Connect(function(io)
	if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end
end)
UIS.InputEnded:Connect(function(io)                              -- a finger that slid off the button still lets go
	if charging and touchAim and io.UserInputType == Enum.UserInputType.Touch then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end
end)
-- THE CLOSE-UP. Beside the ring, a little above it and a touch back towards the shooter, so the acorn is seen
-- coming in from the side and dropping through; it follows the acorn with the ring kept in frame, holds a
-- moment on the net, and hands the camera back.
local cineConn
local function closeUp(nut, rc, dur)
	local cam = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local approach = ((rc - (root and root.Position or cam.CFrame.Position)) * Vector3.new(1, 0, 1))
	approach = approach.Magnitude > 0.1 and approach.Unit or Vector3.new(0, 0, -1)
	local side = approach:Cross(Vector3.yAxis)
	local camPos = rc + side * 6.5 - approach * 3.0 + Vector3.new(0, 2.8, 0)
	if cineConn then cineConn:Disconnect() end
	cam.CameraType = Enum.CameraType.Scriptable
	local start = os.clock()
	cineConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		if t > dur + 0.7 or not nut.Parent then
			cineConn:Disconnect(); cineConn = nil
			cam.CameraType = Enum.CameraType.Custom
			return
		end
		local target = nut.Position:Lerp(rc, 0.4)
		cam.CFrame = CFrame.lookAt(camPos, target)
	end)
end
tool.Unequipped:Connect(function()
	if cineConn then cineConn:Disconnect(); cineConn = nil; workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
end)
-- the crowd's "ohhh" for a miss: flat, for this player only
local function missSound()
	local H = workspace:FindFirstChild("Hoop")
	local id = H and tonumber(H:GetAttribute("MissSoundId")) or 0
	if id <= 0 then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = (H and H:GetAttribute("MissVolume")) or 0.8
	s.Parent = game:GetService("SoundService"); s:Play()
	game:GetService("Debris"):AddItem(s, 10)
end
shoot.OnClientEvent:Connect(function(what, a, b, c)
	if what == "basket" then say(string.format("BASKET!  +%d acorns", a), true)
	elseif what == "cine" then closeUp(a, b, c)
	elseif what == "miss" then missSound()
	elseif what == "no" then say(a)
	elseif what == "rest" then resting(tonumber(a) or 0, b == true) end
end)

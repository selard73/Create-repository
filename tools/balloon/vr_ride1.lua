-- vr_ride1.lua (Studio EDIT mode; re-running is a no-op). Job 80.
-- In VR the balloon ride hazes the far view and runs lighter (Shannon, Oct 10: the funicolare and the far hills "come in and
-- out" on the headset with everything loaded - the Quest's renderer, not streaming). workspace.BalloonField.BalloonClient
-- 32702 -> 34193 chars (exact-string patch; backup HudBackup.BalloonClient_pre_vrride1). Attributes to tune on
-- BalloonField: VRHazeStart 350, VRHazeEnd 900 (0 = no haze), VRShadowsOff true, VRWindRate 36, VRBoltShare 0.5.
-- Undo: BalloonClient.Source = HudBackup.BalloonClient_pre_vrride1.Source. No publish.
local SS = game:GetService("ServerStorage")
local bf = workspace:FindFirstChild("BalloonField"); local bc = bf and bf:FindFirstChild("BalloonClient")
if not bc then print("QQ VRRIDE ABORT: workspace.BalloonField.BalloonClient not found") return end
local NEW = [===[
-- BalloonClient (workspace.BalloonField, RunContext Client): the show balloons drift and bob (moved locally from the
-- server clock, so every player sees the same sky), every flame flickers, and the flight's weather and signs happen here:
-- the gust, the storm fog and lightning, the "To Be Continued" sign, the fade and the return. World-space where it can be,
-- so a VR headset sees it with the control panel closed. Oct 9 late: the map music drops as you climb, the lighthouse turns
-- its light once the storm is dark (the film of a flight is FilmMode's "Balloon flight" tour, F8). The flying balloon is
-- drawn from a short history of the server's positions so it moves smoothly from any camera (see "smooth flight").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local F = script.Parent
local ev = RS:WaitForChild("BalloonEvent")
local VR = UIS.VREnabled
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function vec(name, d) local v = F:GetAttribute(name) return typeof(v) == "Vector3" and v or d end

-- ---------- show balloons and flames ----------
local drift, flames, tethered = {}, {}, {}
local function adopt(m)
	if not m:IsA("Model") then return end
	local kind = m:GetAttribute("Kind")
	if kind == "drift" then drift[m] = {pivot = m:GetPivot(), h = m:GetAttribute("Height") or 15, period = m:GetAttribute("Period") or 150, phase = m:GetAttribute("Phase") or 0}
	elseif kind == "tethered" then tethered[m] = m:GetPivot() end
	local fl = m:FindFirstChild("Flame", true)
	if fl and fl:IsA("BasePart") then flames[fl] = {size = fl.Size, light = fl:FindFirstChildOfClass("PointLight"), flare = 0} end
end
for _, m in ipairs(F:GetChildren()) do adopt(m) end
F.ChildAdded:Connect(function(m) task.wait(0.2); adopt(m) end)
F.ChildRemoved:Connect(function(m) drift[m] = nil; tethered[m] = nil end)
local DC, DR = vec("DriftCenter", Vector3.new(190, 18, -650)), num("DriftRadius", 55)
local signBasket, signPart, yours, wind, windPart, beamModel = nil, nil, nil, nil, nil, nil   -- (made below; the loop runs first)
local LIGHT_AT = vec("LightAt", Vector3.new(520, 60, -1172))   -- the Faro's lantern (the installer measures it)
RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow()
	if signBasket and signBasket.Parent then signPart.CFrame = signBasket.CFrame * CFrame.new(0, 7, -14) end
	if beamModel then beamModel:PivotTo(CFrame.new(LIGHT_AT) * CFrame.Angles(0, t * num("BeamSpin", 0.5), 0)) end
	if wind and wind.Enabled then
		local b = yours and yours:FindFirstChild("Basket", true)
		if b then local d = vec("GustDir", Vector3.new(0.45, 0, -1)); d = Vector3.new(d.X, 0, d.Z).Unit; windPart.CFrame = CFrame.lookAt(b.Position - d * 26 + Vector3.new(0, 4, 0), b.Position + d * 10) end
	end
	for m, d in pairs(drift) do
		if m.Parent then
			local a = d.phase + 2 * math.pi * t / d.period
			local pos = Vector3.new(DC.X + DR * math.cos(a), d.h + 5 * math.sin(t * 0.25 + d.phase), DC.Z + DR * math.sin(a))
			m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, -a + math.pi / 2 + 0.4 * math.sin(t * 0.1), 0))
		else drift[m] = nil end
	end
	for m, cf in pairs(tethered) do
		if m.Parent then m:PivotTo(cf * CFrame.new(0, 0.5 + 0.45 * math.sin(t * 0.6), 0) * CFrame.Angles(0, 0.03 * t, 0)) else tethered[m] = nil end
	end
	for fl, d in pairs(flames) do
		if fl.Parent then
			local k = 0.75 + 0.25 * math.sin(t * 17 + fl.Position.X) * math.sin(t * 7.3) + d.flare
			fl.Size = Vector3.new(d.size.X * (0.9 + 0.3 * d.flare), d.size.Y * k, d.size.Z * (0.9 + 0.3 * d.flare))
			if d.light then d.light.Brightness = 1.5 * k end
		else flames[fl] = nil end
	end
end)

-- ---------- screen and world text ----------
local pg = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui"); gui.Name = "BalloonGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 17; gui:SetAttribute("VRWindowSkip", true); gui.Parent = pg   -- (in VR everything here is a world thing instead)
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0, 92); toast.Size = UDim2.fromOffset(420, 36)
toast.BackgroundColor3 = Color3.fromRGB(255, 246, 220); toast.TextColor3 = Color3.fromRGB(58, 36, 16); toast.Font = Enum.Font.GothamBold; toast.TextSize = 16
toast.TextWrapped = true; toast.Visible = false; toast.Parent = gui
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 10); tc.Parent = toast
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.ZIndex = 20; black.Parent = gui
local flash = Instance.new("Frame"); flash.Size = UDim2.fromScale(1, 1); flash.BackgroundColor3 = Color3.new(1, 1, 1); flash.BackgroundTransparency = 1; flash.BorderSizePixel = 0; flash.ZIndex = 19; flash.Parent = gui
local sign = Instance.new("TextLabel"); sign.AnchorPoint = Vector2.new(0.5, 0.5); sign.Position = UDim2.fromScale(0.5, 0.42); sign.Size = UDim2.fromOffset(520, 120)
sign.BackgroundColor3 = Color3.fromRGB(255, 246, 220); sign.BackgroundTransparency = 0.08; sign.TextColor3 = Color3.fromRGB(58, 36, 16); sign.Font = Enum.Font.GothamBold; sign.TextSize = 30; sign.TextWrapped = true
sign.Text = "To Be Continued\nMore to come soon"; sign.Visible = false; sign.ZIndex = 21; sign.Parent = gui
local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 14); sc.Parent = sign
local toastUntil = 0
-- VR: a note is a sign in the world, not screen text (Shannon: the screen notes were "super super tiny ... you might not see
-- it at all"): the ride's words hang over the basket, where you are or where you look from
local rideNote, rideNoteText = nil, nil
local function vrNote(text, secs)
	local b = yours and yours:FindFirstChild("Basket", true)
	if not b then return end
	if not (rideNote and rideNote.Parent) then
		rideNote = Instance.new("BillboardGui"); rideNote.Name = "RideNote"; rideNote.Size = UDim2.fromScale(12, 2.4); rideNote.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)
		rideNote.AlwaysOnTop = true; rideNote.LightInfluence = 0; rideNote.MaxDistance = 250; rideNote.Adornee = b; rideNote.Enabled = false; rideNote.Parent = b
		rideNoteText = Instance.new("TextLabel"); rideNoteText.Size = UDim2.fromScale(1, 1); rideNoteText.BackgroundColor3 = Color3.fromRGB(255, 246, 220); rideNoteText.BackgroundTransparency = 0.12
		rideNoteText.TextColor3 = Color3.fromRGB(58, 36, 16); rideNoteText.Font = Enum.Font.GothamBold; rideNoteText.TextScaled = true; rideNoteText.TextWrapped = true; rideNoteText.Parent = rideNote
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.2, 0); c.Parent = rideNoteText
		local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0.03, 0); p.PaddingRight = UDim.new(0.03, 0); p.PaddingTop = UDim.new(0.08, 0); p.PaddingBottom = UDim.new(0.08, 0); p.Parent = rideNoteText
	end
	rideNoteText.Text = text; rideNote.Enabled = true; toastUntil = os.clock() + secs
	task.delay(secs, function() if os.clock() >= toastUntil - 0.05 and rideNote then rideNote.Enabled = false end end)
end
local function showToast(text, secs)
	if VR then vrNote(text, secs or 3) return end
	toast.Text = text; toast.Visible = true; toastUntil = os.clock() + (secs or 3)
	task.delay(secs or 3, function() if os.clock() >= toastUntil - 0.05 then toast.Visible = false end end)
end
-- the sign in the sky as well: a billboard in front of the basket (readable in VR with the panel closed)
signPart = Instance.new("Part"); signPart.Name = "SkySign"; signPart.Anchored = true; signPart.CanCollide = false; signPart.CanQuery = false; signPart.Transparency = 1; signPart.Size = Vector3.new(1, 1, 1)
local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromScale(13, 3); bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.MaxDistance = 200; bb.Enabled = false; bb.Parent = signPart
local bbText = sign:Clone(); bbText.Visible = true; bbText.Size = UDim2.fromScale(1, 1); bbText.Position = UDim2.fromScale(0.5, 0.5); bbText.TextScaled = true; bbText.Parent = bb
signPart.Parent = workspace.CurrentCamera

-- ---------- the board prompt knows your count (world-space text, good in VR) ----------
yours = F:WaitForChild("YourBalloon", 30)
local prompt = yours and yours:FindFirstChild("BoardPrompt", true)
local PORTO_ID = {}
pcall(function()
	local FRENCH = {forest = true, village = true, domaine = true}
	local R = require(workspace:WaitForChild("SquirrelScripts", 10):WaitForChild("SquirrelRegistry", 10))
	for _, q in ipairs(R.squirrels or {}) do if not FRENCH[q.map] then PORTO_ID[q.id] = true end end
end)
local function mine()
	local s = player:GetAttribute("FoundIds")
	if type(s) ~= "string" or next(PORTO_ID) == nil then return tonumber(player:GetAttribute("Found_porto")) or 0 end
	local n = 0
	for id in s:gmatch("[^,]+") do if PORTO_ID[id] then n += 1 end end
	return n
end
local function flown() return (tonumber(player:GetAttribute("Item_balloon_flights")) or 0) > 0 end
-- the one word when the last squirrel is found: it floats up the screen once and drifts off the top (Shannon, Oct 9:
-- the sign that hung over the balloon was "messy and all over the place ... not permanent")
local function floatNotice(text, secs)
	if VR then   -- a card where you are looking at this moment (not pinned to your head), floating up and away
		local cam = workspace.CurrentCamera
		local ok, cf = pcall(function() return cam:GetRenderCFrame() end); cf = ok and cf or cam.CFrame
		local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z); look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local part = Instance.new("Part"); part.Name = "FloatNote"; part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.Transparency = 1; part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.CFrame = CFrame.new(cf.Position + look * 6 - Vector3.new(0, 0.6, 0)); part.Parent = cam
		local g = Instance.new("BillboardGui"); g.Size = UDim2.fromScale(7, 2.2); g.AlwaysOnTop = true; g.LightInfluence = 0; g.Parent = part
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundColor3 = Color3.fromRGB(255, 246, 220); l.BackgroundTransparency = 0.1; l.TextColor3 = Color3.fromRGB(58, 36, 16)
		l.Font = Enum.Font.GothamBold; l.TextScaled = true; l.TextWrapped = true; l.Text = text; l.Parent = g
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.15, 0); c.Parent = l
		local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0.04, 0); p.PaddingRight = UDim.new(0.04, 0); p.PaddingTop = UDim.new(0.08, 0); p.PaddingBottom = UDim.new(0.08, 0); p.Parent = l
		TweenService:Create(part, TweenInfo.new(secs + 2, Enum.EasingStyle.Sine), {CFrame = part.CFrame + Vector3.new(0, 3, 0)}):Play()
		task.delay(secs, function() TweenService:Create(l, TweenInfo.new(2), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
		game:GetService("Debris"):AddItem(part, secs + 2.2)
		return
	end
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local l = Instance.new("TextLabel"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Size = UDim2.fromOffset(math.min(520, v.X - 60), 0); l.AutomaticSize = Enum.AutomaticSize.Y
	l.Position = UDim2.fromScale(0.5, 0.8); l.BackgroundColor3 = Color3.fromRGB(255, 246, 220); l.BackgroundTransparency = 1; l.TextTransparency = 1
	l.TextColor3 = Color3.fromRGB(58, 36, 16); l.Font = Enum.Font.GothamBold; l.TextSize = 20; l.TextWrapped = true; l.Text = text; l.ZIndex = 20; l.Parent = gui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = l
	local p = Instance.new("UIPadding"); p.PaddingTop = UDim.new(0, 10); p.PaddingBottom = UDim.new(0, 10); p.PaddingLeft = UDim.new(0, 14); p.PaddingRight = UDim.new(0, 14); p.Parent = l
	TweenService:Create(l, TweenInfo.new(0.8), {BackgroundTransparency = 0.1, TextTransparency = 0}):Play()
	TweenService:Create(l, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.5, 0.3)}):Play()   -- floats up
	task.delay(secs, function()
		TweenService:Create(l, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, -0.2), BackgroundTransparency = 1, TextTransparency = 1}):Play()   -- and off the top
		game:GetService("Debris"):AddItem(l, 2.4)
	end)
end
local function updatePrompt()
	local n, need = mine(), num("Need", 44)
	if prompt then
		if n >= need then prompt.ObjectText = "Your balloon"; prompt.ActionText = "All aboard"
		else prompt.ObjectText = string.format("Your balloon (%d of %d squirrels)", n, need); prompt.ActionText = "Find them all first" end
	end
end
updatePrompt()
player:GetAttributeChangedSignal("Item_balloon_flights"):Connect(updatePrompt)
-- the moment the last Porto squirrel is found (Shannon: "it tells you to get over there and you get in the balloon")
local lastCount = mine()
local announced = false
local function onCount()
	local n, need = mine(), num("Need", 44)
	updatePrompt()
	if n >= need and lastCount < need and not announced and not flown() then
		announced = true
		task.delay(1.5, function()
			floatNotice(string.format("All %d squirrels of Porto Nocciola found! Your balloon is waiting on the far shore across the harbour. All aboard!", need), 7)
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9116394876"; s.Volume = 0.5; s.Parent = SoundService; s:Play(); game:GetService("Debris"):AddItem(s, 10)
		end)
	end
	lastCount = n
end
player:GetAttributeChangedSignal("FoundIds"):Connect(onCount)
player:GetAttributeChangedSignal("Found_porto"):Connect(onCount)

-- ---------- the weather ----------
local saved = nil
local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "BalloonFade"; cc.Brightness = 0; cc.Parent = Lighting   -- the fade a headset sees too
local function sound(id, volume, parent)
	if not id or id == 0 then return nil end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. tostring(id); s.Volume = volume or 0.5; s.Parent = parent or SoundService; s:Play()
	game:GetService("Debris"):AddItem(s, 20)
	return s
end
wind = Instance.new("ParticleEmitter"); wind.Name = "WindStreaks"; wind.Enabled = false; wind.Rate = VR and num("VRWindRate", 36) or 90; wind.Lifetime = NumberRange.new(0.5, 0.9)
wind.Speed = NumberRange.new(55, 80); wind.SpreadAngle = Vector2.new(8, 8); wind.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.05)})
wind.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)}); wind.Color = ColorSequence.new(Color3.fromRGB(235, 240, 250))
wind.LightEmission = 0.4; wind.Orientation = Enum.ParticleOrientation.VelocityParallel; wind.Squash = NumberSequence.new(-1.6)
wind.EmissionDirection = Enum.NormalId.Front   -- along the gust, past the basket (the default, Top, sent the streaks straight up - review, Oct 9)
windPart = Instance.new("Part"); windPart.Name = "WindSource"; windPart.Anchored = true; windPart.CanCollide = false; windPart.CanQuery = false; windPart.Transparency = 1; windPart.Size = Vector3.new(14, 10, 1); wind.Parent = windPart; windPart.Parent = workspace
local storming = false
local stormSound, windSound = nil, nil   -- Shannon's picks: the wind (WindSoundId) loops through the gust, then the storm (StormSoundId) takes over
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
if not clouds then   -- the place has no cloud layer: a clear one of our own, rolled in by the storm (local to this client)
	clouds = Instance.new("Clouds"); clouds.Cover = 0; clouds.Density = 0; clouds.Enabled = true; clouds.Parent = workspace.Terrain
end
local function bolt(near)
	-- a jagged bolt of Neon parts from the clouds down towards the sea, gone in a blink
	local top = near + Vector3.new((math.random() - 0.5) * 160, 70 + math.random() * 30, (math.random() - 0.5) * 160)
	local m = Instance.new("Model"); m.Name = "Lightning"
	local p = top
	for i = 1, 7 do
		local q = p + Vector3.new((math.random() - 0.5) * 18, -(10 + math.random() * 8), (math.random() - 0.5) * 18)
		local seg = Instance.new("Part"); seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.Material = Enum.Material.Neon; seg.Color = Color3.fromRGB(225, 235, 255)
		seg.Size = Vector3.new(0.5, 0.5, (q - p).Magnitude); seg.CFrame = CFrame.lookAt((p + q) / 2, q); seg.Parent = m
		p = q
	end
	local l = Instance.new("PointLight"); l.Brightness = 6; l.Range = 90; l.Color = Color3.fromRGB(220, 230, 255); l.Parent = m:FindFirstChildWhichIsA("BasePart")
	m.Parent = workspace; game:GetService("Debris"):AddItem(m, 0.12 + math.random() * 0.1)
end
-- the lighthouse: once the storm has the sky dark its light turns (Shannon: "shows the light from the lighthouse spinning
-- like they do"), off again on the ground. Local, like the storm. LightAt = the lantern, measured by the installer.
local function beamOn()
	if beamModel then return end
	local m = Instance.new("Model"); m.Name = "FaroBeam"
	local warm = Color3.fromRGB(255, 244, 205)
	local function part(name, size, trans, cf)
		local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = Enum.Material.Neon; p.Color = warm; p.Size = size; p.Transparency = trans; p.CFrame = cf; p.Parent = m
		return p
	end
	local lamp = part("Lamp", Vector3.new(4, 4, 4), 0.05, CFrame.new(LIGHT_AT)); lamp.Shape = Enum.PartType.Ball
	local pl = Instance.new("PointLight"); pl.Color = warm; pl.Brightness = 4; pl.Range = 60; pl.Parent = lamp
	local sp = Instance.new("SpotLight"); sp.Color = warm; sp.Brightness = 6; sp.Range = 60; sp.Angle = 14; sp.Face = Enum.NormalId.Front; sp.Parent = lamp
	-- the beam: four lengths, thin and bright at the lamp, wide and faint far out (it has to show through the storm)
	local L = num("BeamLength", 600) / 4
	for i, w in ipairs({{2, 0.25}, {6, 0.45}, {12, 0.62}, {22, 0.8}}) do part("Beam" .. i, Vector3.new(w[1], w[1], L), w[2], CFrame.new(LIGHT_AT) * CFrame.new(0, 0, -(i - 0.5) * L)) end
	m.PrimaryPart = lamp; m.Parent = workspace; beamModel = m
end
local function beamOff() if beamModel then beamModel:Destroy(); beamModel = nil end end
-- the lighting as it was before the ride touched it (the storm and, in VR, the haze share one snapshot)
local function snapshot()
	if not saved then saved = {FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
		density = atmo and atmo.Density, haze = atmo and atmo.Haze, color = atmo and atmo.Color, cover = clouds and clouds.Cover, cdensity = clouds and clouds.Density, ccolor = clouds and clouds.Color} end
end
local function stormOn(secs)
	snapshot()
	local sid = num("StormSoundId", 0)
	if sid > 0 and not stormSound then
		stormSound = Instance.new("Sound"); stormSound.SoundId = "rbxassetid://" .. tostring(sid); stormSound.Looped = true; stormSound.Volume = 0; stormSound.Parent = SoundService; stormSound:Play()
		TweenService:Create(stormSound, TweenInfo.new(4), {Volume = 0.6}):Play()
	end
	if windSound then local w = windSound; windSound = nil; TweenService:Create(w, TweenInfo.new(5), {Volume = 0}):Play(); game:GetService("Debris"):AddItem(w, 5.5) end   -- the wind gives way to the storm
	-- clouds close in first, then the light goes, then the fog
	if clouds then TweenService:Create(clouds, TweenInfo.new(7, Enum.EasingStyle.Sine), {Cover = 1, Density = 1, Color = Color3.fromRGB(70, 72, 80)}):Play() end
	TweenService:Create(Lighting, TweenInfo.new(9, Enum.EasingStyle.Sine), {OutdoorAmbient = Color3.fromRGB(55, 58, 68), FogColor = Color3.fromRGB(96, 100, 110)}):Play()
	TweenService:Create(Lighting, TweenInfo.new(2.2, Enum.EasingStyle.Sine), {Brightness = 0.35}):Play()   -- settled before the first bolt, so the flashes show (a 9 s tween would overwrite them - review)
	task.delay(4, function() if storming then TweenService:Create(Lighting, TweenInfo.new(6, Enum.EasingStyle.Sine), {FogEnd = num("StormFogEnd", 90), FogStart = 4}):Play() end end)
	if atmo then TweenService:Create(atmo, TweenInfo.new(8, Enum.EasingStyle.Sine), {Density = num("StormDensity", 0.85), Haze = 8, Color = Color3.fromRGB(110, 114, 122)}):Play() end
	storming = true
	task.delay(num("BeamAfter", 6), function() if storming then beamOn() end end)   -- the lighthouse lights once it is dark
	local amb = saved.Ambient
	task.spawn(function()
		local t0 = os.clock()
		task.wait(2.5)
		while storming and os.clock() - t0 < secs + 8 do
			-- lightning: a bolt in the sky, a flash on the world, thunder a moment later
			local hold = 0.08 + math.random() * 0.1
			local b = yours and yours:FindFirstChild("Basket", true)
			if not VR or math.random() < num("VRBoltShare", 0.5) then bolt(b and b.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position) or Vector3.zero) end   -- (fewer bolts on a headset)
			if not VR then flash.BackgroundTransparency = 0.45 end
			Lighting.Brightness = 2.2; Lighting.Ambient = Color3.fromRGB(200, 205, 225)
			task.wait(hold)
			flash.BackgroundTransparency = 1
			if not storming then break end
			Lighting.Brightness = 0.35; Lighting.Ambient = amb
			task.delay(0.4 + math.random() * 0.8, function() sound(num("ThunderSoundId", 0), 0.6) end)
			task.wait(1.4 + math.random() * 2.2)
		end
	end)
end
local function stormOff()
	storming = false
	beamOff()
	if not saved then return end
	TweenService:Create(Lighting, TweenInfo.new(3, Enum.EasingStyle.Sine), {FogEnd = saved.FogEnd, FogStart = saved.FogStart, FogColor = saved.FogColor, Brightness = saved.Brightness, OutdoorAmbient = saved.OutdoorAmbient}):Play()
	Lighting.Ambient = saved.Ambient
	if saved.shadows ~= nil then Lighting.GlobalShadows = saved.shadows end
	if atmo then TweenService:Create(atmo, TweenInfo.new(3, Enum.EasingStyle.Sine), {Density = saved.density, Haze = saved.haze, Color = saved.color}):Play() end
	if clouds and saved.cover ~= nil then TweenService:Create(clouds, TweenInfo.new(4, Enum.EasingStyle.Sine), {Cover = saved.cover, Density = saved.cdensity, Color = saved.ccolor}):Play() end
	wind.Enabled = false
	if stormSound then local s = stormSound; stormSound = nil; TweenService:Create(s, TweenInfo.new(3), {Volume = 0}):Play(); game:GetService("Debris"):AddItem(s, 3.5) end
	if windSound then local w = windSound; windSound = nil; TweenService:Create(w, TweenInfo.new(2), {Volume = 0}):Play(); game:GetService("Debris"):AddItem(w, 2.5) end
	saved = nil
end
-- IN VR THE FAR VIEW IS HAZED AND THE RIDE RUNS LIGHTER (Shannon, Oct 10: on the headset the funicolare and the far hills
-- "come in and out" with everything loaded - the Quest's renderer at a low quality step, and the step bounces). A haze
-- hides the popping; no shadows, fewer streaks and bolts keep the frame rate up so the step holds. Attributes on the
-- folder: VRHazeStart 350, VRHazeEnd 900 (0 = no haze; with an Atmosphere present its Haze goes to VRHazeAtmo 2.5
-- instead), VRShadowsOff true, VRWindRate 36, VRBoltShare 0.5. The storm takes over later; stormOff puts it all back.
local function hazeOn()
	if not VR then return end
	snapshot()
	if F:GetAttribute("VRShadowsOff") ~= false then saved.shadows = Lighting.GlobalShadows; Lighting.GlobalShadows = false end
	local hEnd = num("VRHazeEnd", 900)
	if hEnd <= 0 then return end
	if atmo then TweenService:Create(atmo, TweenInfo.new(3, Enum.EasingStyle.Sine), {Haze = num("VRHazeAtmo", 2.5)}):Play()
	else TweenService:Create(Lighting, TweenInfo.new(3, Enum.EasingStyle.Sine), {FogStart = math.min(num("VRHazeStart", 350), hEnd - 50), FogEnd = hEnd}):Play() end
end

-- ---------- smooth flight ----------
-- The server moves the balloon every heartbeat, but a client is sent about twenty positions a second, so seen from a
-- camera that is not riding along the balloon moved in steps (Shannon, filming it: "jittery"). While a flight is on,
-- this client keeps the positions it is sent and draws the balloon a tenth of a second behind them, moving smoothly in
-- between; the seat goes with it, so the rider does too. Written before physics (Stepped) so the rider and the basket
-- agree, and again before the frame is drawn in case a server position landed in between. Local only.
local smooth = nil   -- {basket, parts = {part -> offset from the basket}, samples = {{arrived, cf}, ...}, written, shown}
local function smoothWrite(S, cf)
	S.basket.CFrame = cf
	for p, o in pairs(S.parts) do if p.Parent then p.CFrame = cf * o end end
	S.written = cf; S.shown = cf
end
local function smoothStart()
	local b = yours and yours:FindFirstChild("Basket", true)
	if not b then return end
	local parts = {}
	for _, p in ipairs(yours:GetDescendants()) do if p:IsA("BasePart") and p ~= b then parts[p] = b.CFrame:Inverse() * p.CFrame end end
	smooth = {basket = b, parts = parts, samples = {}, written = nil, shown = nil}
end
local function smoothStop()
	-- nothing is written here: the server's home position comes down the same stream as the "home" event, properties first,
	-- so by now the parts hold it (writing our newest sample over it would leave the balloon in the sky - review, Oct 9)
	smooth = nil
end
local function smoothSample(S, now)
	local cf = S.basket.CFrame
	if S.written == nil or not cf:FuzzyEq(S.written, 1e-3) then   -- not what we wrote: a position from the server
		local last = S.samples[#S.samples]
		if last and (cf.Position - last[2].Position).Magnitude > 40 then   -- a jump (set down at home): no gliding there, it is there now (Shannon, VR: "the balloon stayed in the air")
			S.samples = {{now, cf}}
			smoothWrite(S, cf)
			return
		end
		table.insert(S.samples, {now, cf})
		if #S.samples > 10 then table.remove(S.samples, 1) end
	end
end
local function smoothStep(advance)
	local S = smooth; if not S then return end
	if not S.basket.Parent then smooth = nil return end
	local now = os.clock()
	smoothSample(S, now)
	local n = #S.samples
	if n == 0 then return end
	if now - S.samples[n][1] > 2 then smoothWrite(S, S.samples[n][2]); smoothStop() return end   -- nothing from the server for two seconds: the flight is over; sit on its last position
	if not advance then if S.shown then smoothWrite(S, S.shown) end return end
	local r = now - num("SmoothDelay", 0.1)
	local show
	if r <= S.samples[1][1] then show = S.samples[1][2]
	elseif r >= S.samples[n][1] then
		local a, c = S.samples[n - 1], S.samples[n]
		if a and c[1] - a[1] > 1e-3 then   -- past the newest: carry on at the last speed, a moment at most
			local k = math.min((r - c[1]) / (c[1] - a[1]), 2)
			show = CFrame.new(c[2].Position + (c[2].Position - a[2].Position) * k) * c[2].Rotation
		else show = c[2] end
	else
		for i = 1, n - 1 do
			local a, c = S.samples[i], S.samples[i + 1]
			if r >= a[1] and r < c[1] then show = a[2]:Lerp(c[2], (r - a[1]) / math.max(c[1] - a[1], 1e-3)) break end
		end
		show = show or S.samples[n][2]
	end
	smoothWrite(S, show)
end
RunService.Stepped:Connect(function() smoothStep(true) end)
RunService:BindToRenderStep("BalloonSmooth", Enum.RenderPriority.Camera.Value - 10, function() smoothStep(false) end)

-- ---------- the map music ----------
-- The map music drops as the balloon climbs and comes back on the field (Shannon: "the game music should become a little
-- less as the balloon ascends"). MapMusic.MusicClient plays SoundService.MusicA / MusicB; this only ever lowers a track
-- (one it is fading out is left to finish), and lifts the one playing again at home. MusicDuck = the fraction kept.
local ducked, duckTw = false, {}
local function musicFull() local mm = workspace:FindFirstChild("MapMusic"); local v = mm and mm:GetAttribute("Volume"); return type(v) == "number" and v or 0.28 end
local function musicTween(s, target, secs) if duckTw[s] then duckTw[s]:Cancel() end local tw = TweenService:Create(s, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Volume = target}); duckTw[s] = tw; tw:Play() end
local function duckMusic(on, secs)
	ducked = on
	for _, n in ipairs({"MusicA", "MusicB"}) do
		local s = SoundService:FindFirstChild(n)
		if s and s:IsA("Sound") and s.IsPlaying then
			local low = musicFull() * num("MusicDuck", 0.4)
			if on then if s.Volume > low + 0.01 and not (duckTw[s] and duckTw[s].PlaybackState == Enum.PlaybackState.Playing) then musicTween(s, low, secs) end
			elseif s.Volume > 0.001 then musicTween(s, musicFull(), secs) end
		end
	end
end
task.spawn(function() while true do task.wait(1) if ducked then duckMusic(true, 1.5) end end end)   -- a track MusicClient changes mid-flight drops too

-- ---------- the ride's camera in VR ----------
-- Shannon (VR): "the view is tied directly to the player ... very close up to the basket and you cannot see anything around
-- you ... make it video like ... or make the VR so that you can reorient the camera". While you fly, the camera stands off the
-- balloon - 30 studs out, a little above - and turns slowly round it; a flick of the right thumbstick turns it 30 degrees;
-- your head looks around from there as always. Back to the normal camera on the ground. Headsets only.
local vrCam = nil
local function vrCamStart()
	if not VR or vrCam then return end
	local S = {angle = math.pi, target = math.pi, dist = num("VRCamDistance", 30), height = num("VRCamHeight", 4), held = false}
	vrCam = S
	S.conn = UIS.InputChanged:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick2 then return end
		local x = input.Position.X
		if math.abs(x) > 0.75 then if not S.held then S.held = true; S.target += (x > 0 and -1 or 1) * math.rad(30) end
		elseif math.abs(x) < 0.3 then S.held = false end
	end)
	RunService:BindToRenderStep("BalloonVRCam", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if vrCam ~= S or not (yours and yours.Parent) then return end
		local b = yours:GetPivot().Position
		S.target += dt * 0.05   -- a slow turn round the balloon on its own
		S.angle += (S.target - S.angle) * (1 - math.exp(-dt * 4))
		local want = b + Vector3.new(math.cos(S.angle) * S.dist, S.height, math.sin(S.angle) * S.dist)
		S.pos = S.pos and S.pos:Lerp(want, 1 - math.exp(-dt * 3)) or want
		local cam = workspace.CurrentCamera; cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(S.pos, b + Vector3.new(0, 6, 0))
	end)
end
local function vrCamStop()
	local S = vrCam; vrCam = nil
	if not S then return end
	RunService:UnbindFromRenderStep("BalloonVRCam")
	if S.conn then S.conn:Disconnect() end
	local cam = workspace.CurrentCamera; cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then cam.CameraSubject = hum end
end

-- ---------- phases ----------
local flying = false
local restCF = nil   -- where the balloon stood when you boarded (its pad)
ev.OnClientEvent:Connect(function(what, who, name, secs)
	if what == "locked" then showToast(string.format("Find all %d squirrels of Porto Nocciola to fly. %d so far.", name, who), 4)
	elseif what == "busy" then showToast("The balloon is away. It will be back on the field soon.", 3)
	elseif what == "phase" then
		local m = yours
		local fl = m and m:FindFirstChild("Flame", true)
		if name == "board" and fl and flames[fl] then flames[fl].flare = 1; task.delay(3, function() if flames[fl] then flames[fl].flare = 0 end end) end
		if name == "board" then smoothStart(); restCF = yours and yours:GetPivot() or nil
		elseif name == "home" then
			smoothStop()
			task.delay(0.8, function()   -- and whatever the order things arrived in, the balloon is on its pad now
				if restCF and yours and yours.Parent and not smooth and (yours:GetPivot().Position - restCF.Position).Magnitude > 3 then yours:PivotTo(restCF) end
			end)
		end
		if who ~= player then return end
		if name == "board" then flying = true; vrCamStart(); hazeOn() end
		if name == "rise" then showToast("Up you go, traveler! Look at Porto Nocciola from the sky.", 5); duckMusic(true, secs)
		elseif name == "gust" then
			showToast("Oh no! Looks like we are in for some bad weather!", 4)
			local wid = num("WindSoundId", 0)
			if wid > 0 and not windSound then
				windSound = Instance.new("Sound"); windSound.SoundId = "rbxassetid://" .. tostring(wid); windSound.Looped = true; windSound.Volume = 0; windSound.Parent = SoundService; windSound:Play()
				TweenService:Create(windSound, TweenInfo.new(1.5), {Volume = 0.7}):Play()
			end
			wind.Enabled = true
			task.delay(secs + num("StormTime", 12) * 0.6, function() wind.Enabled = false end)
			task.delay(math.max(0, secs - 6), function() if flying then stormOn(num("StormTime", 12) + num("SignTime", 6) + 3) end end)
		elseif name == "sign" then
			signBasket = m and m:FindFirstChild("Basket", true)
			bb.Enabled = VR; sign.Visible = not VR
		elseif name == "fade" then
			TweenService:Create(black, TweenInfo.new(1.6), {BackgroundTransparency = 0}):Play()
			TweenService:Create(cc, TweenInfo.new(1.6), {Brightness = -1}):Play()
			task.delay(1.8, function() bb.Enabled = false; sign.Visible = false end)
		elseif name == "home" then
			flying = false; signBasket = nil; bb.Enabled = false; sign.Visible = false
			stormOff(); duckMusic(false, 3); vrCamStop()
			task.delay(0.6, function() TweenService:Create(black, TweenInfo.new(1.4), {BackgroundTransparency = 1}):Play(); TweenService:Create(cc, TweenInfo.new(1.4), {Brightness = 0}):Play() end)
			showToast("Back on the balloon field. More of the journey is coming soon!", 5)
		end
	end
end)
player.CharacterAdded:Connect(function() flying = false; if storming then stormOff() end; duckMusic(false, 1); vrCamStop(); black.BackgroundTransparency = 1; cc.Brightness = 0; bb.Enabled = false; sign.Visible = false end)
print("BalloonClient: ready" .. (VR and " (VR)" or ""))
]===]
if #bc.Source == 34193 and bc.Source == NEW then print("QQ VRRIDE DONE (already installed): BalloonClient 34193") return end
if #bc.Source ~= 32702 then print(string.format("QQ VRRIDE ABORT: BalloonClient is %d chars, expected 32702 (not the job 56 text; export it first); nothing changed", #bc.Source)) return end
local f, err = loadstring(NEW); if not f then print("QQ VRRIDE ABORT: the new client does not compile: " .. tostring(err)) return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
if not hb:FindFirstChild("BalloonClient_pre_vrride1") then local b = Instance.new("ModuleScript"); b.Name = "BalloonClient_pre_vrride1"; b.Source = bc.Source; b.Parent = hb end
bc.Source = NEW
for k, v in pairs({VRHazeStart = 350, VRHazeEnd = 900, VRHazeAtmo = 2.5, VRWindRate = 36, VRBoltShare = 0.5}) do if bf:GetAttribute(k) == nil then bf:SetAttribute(k, v) end end
if bf:GetAttribute("VRShadowsOff") == nil then bf:SetAttribute("VRShadowsOff", true) end
local atmo = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
print(string.format("QQ VRRIDE DONE: BalloonClient %d -> %d chars (backup HudBackup.BalloonClient_pre_vrride1); haze %s; Lighting has %s", 32702, #bc.Source,
	atmo and "by Atmosphere.Haze (an Atmosphere is present)" or "by Lighting fog 350..900", atmo and ("an Atmosphere (Density " .. tostring(atmo.Density) .. ", Haze " .. tostring(atmo.Haze) .. ")") or "no Atmosphere"))

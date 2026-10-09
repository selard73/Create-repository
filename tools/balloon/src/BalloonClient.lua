-- BalloonClient (workspace.BalloonField, RunContext Client): the show balloons drift and bob (moved locally from the
-- server clock, so every player sees the same sky), every flame flickers, and the flight's weather and signs happen here:
-- the gust, the storm fog and lightning, the "To Be Continued" sign, the fade and the return. World-space where it can be,
-- so a VR headset sees it with the control panel closed.
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
local signBasket, signPart, yours, wind, windPart = nil, nil, nil, nil, nil   -- (made below; the loop runs first)
RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow()
	if signBasket and signBasket.Parent then signPart.CFrame = signBasket.CFrame * CFrame.new(0, 7, -14) end
	if wind.Enabled then
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
local gui = Instance.new("ScreenGui"); gui.Name = "BalloonGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 17; gui.Parent = pg
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
local function showToast(text, secs)
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
-- the sign over your balloon, seen from across the harbour, until your first flight
local beacon = Instance.new("BillboardGui"); beacon.Name = "ReadyBeacon"; beacon.Size = UDim2.fromOffset(360, 96); beacon.StudsOffsetWorldSpace = Vector3.new(0, 34, 0)
beacon.AlwaysOnTop = true; beacon.LightInfluence = 0; beacon.MaxDistance = 1400; beacon.Enabled = false
local beaconText = Instance.new("TextLabel"); beaconText.Size = UDim2.fromScale(1, 1); beaconText.BackgroundColor3 = Color3.fromRGB(255, 246, 220); beaconText.BackgroundTransparency = 0.15
beaconText.TextColor3 = Color3.fromRGB(58, 36, 16); beaconText.Font = Enum.Font.GothamBold; beaconText.TextScaled = true; beaconText.TextWrapped = true
beaconText.Text = "Your balloon is ready!\nClimb aboard"; beaconText.Parent = beacon
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 14); bc.Parent = beaconText
if yours then beacon.Adornee = yours:FindFirstChild("Envelope", true) or yours.PrimaryPart; beacon.Parent = pg end
local function updatePrompt()
	local n, need = mine(), num("Need", 44)
	if prompt then
		if n >= need then prompt.ObjectText = "Your balloon"; prompt.ActionText = "Board"
		else prompt.ObjectText = string.format("Your balloon (%d of %d squirrels)", n, need); prompt.ActionText = "Find them all first" end
	end
	beacon.Enabled = n >= need and not flown()
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
			showToast(string.format("You found all %d squirrels of Porto Nocciola! Your balloon is waiting on the far shore across the harbour. Get yourself over there and climb aboard!", need), 12)
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
wind = Instance.new("ParticleEmitter"); wind.Name = "WindStreaks"; wind.Enabled = false; wind.Rate = 90; wind.Lifetime = NumberRange.new(0.5, 0.9)
wind.Speed = NumberRange.new(55, 80); wind.SpreadAngle = Vector2.new(8, 8); wind.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.05)})
wind.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)}); wind.Color = ColorSequence.new(Color3.fromRGB(235, 240, 250))
wind.LightEmission = 0.4; wind.Orientation = Enum.ParticleOrientation.VelocityParallel; wind.Squash = NumberSequence.new(-1.6)
windPart = Instance.new("Part"); windPart.Name = "WindSource"; windPart.Anchored = true; windPart.CanCollide = false; windPart.CanQuery = false; windPart.Transparency = 1; windPart.Size = Vector3.new(14, 10, 1); wind.Parent = windPart; windPart.Parent = workspace
local storming = false
local stormSound = nil   -- the storm's own sound (StormSoundId, Shannon's pick), looped from the clouds closing in until home
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
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
local function stormOn(secs)
	if not saved then saved = {FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
		density = atmo and atmo.Density, haze = atmo and atmo.Haze, color = atmo and atmo.Color, cover = clouds and clouds.Cover, cdensity = clouds and clouds.Density, ccolor = clouds and clouds.Color} end
	local sid = num("StormSoundId", 0)
	if sid > 0 and not stormSound then
		stormSound = Instance.new("Sound"); stormSound.SoundId = "rbxassetid://" .. tostring(sid); stormSound.Looped = true; stormSound.Volume = 0; stormSound.Parent = SoundService; stormSound:Play()
		TweenService:Create(stormSound, TweenInfo.new(4), {Volume = 0.6}):Play()
	end
	-- clouds close in first, then the light goes, then the fog
	if clouds then TweenService:Create(clouds, TweenInfo.new(7, Enum.EasingStyle.Sine), {Cover = 1, Density = 1, Color = Color3.fromRGB(70, 72, 80)}):Play() end
	TweenService:Create(Lighting, TweenInfo.new(9, Enum.EasingStyle.Sine), {Brightness = 0.35, OutdoorAmbient = Color3.fromRGB(55, 58, 68), FogColor = Color3.fromRGB(96, 100, 110)}):Play()
	task.delay(4, function() if storming then TweenService:Create(Lighting, TweenInfo.new(6, Enum.EasingStyle.Sine), {FogEnd = 45, FogStart = 4}):Play() end end)
	if atmo then TweenService:Create(atmo, TweenInfo.new(8, Enum.EasingStyle.Sine), {Density = 0.95, Haze = 10, Color = Color3.fromRGB(110, 114, 122)}):Play() end
	storming = true
	local amb = saved.Ambient
	task.spawn(function()
		local t0 = os.clock()
		task.wait(2.5)
		while storming and os.clock() - t0 < secs + 8 do
			-- lightning: a bolt in the sky, a flash on the world, thunder a moment later
			local hold = 0.08 + math.random() * 0.1
			local b = yours and yours:FindFirstChild("Basket", true)
			bolt(b and b.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position) or Vector3.zero)
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
	if not saved then return end
	TweenService:Create(Lighting, TweenInfo.new(3, Enum.EasingStyle.Sine), {FogEnd = saved.FogEnd, FogStart = saved.FogStart, FogColor = saved.FogColor, Brightness = saved.Brightness, OutdoorAmbient = saved.OutdoorAmbient}):Play()
	Lighting.Ambient = saved.Ambient
	if atmo then TweenService:Create(atmo, TweenInfo.new(3, Enum.EasingStyle.Sine), {Density = saved.density, Haze = saved.haze, Color = saved.color}):Play() end
	if clouds and saved.cover ~= nil then TweenService:Create(clouds, TweenInfo.new(4, Enum.EasingStyle.Sine), {Cover = saved.cover, Density = saved.cdensity, Color = saved.ccolor}):Play() end
	wind.Enabled = false
	if stormSound then local s = stormSound; stormSound = nil; TweenService:Create(s, TweenInfo.new(3), {Volume = 0}):Play(); game:GetService("Debris"):AddItem(s, 3.5) end
	saved = nil
end

-- ---------- phases ----------
local flying = false
ev.OnClientEvent:Connect(function(what, who, name, secs)
	if what == "locked" then showToast(string.format("Find all %d squirrels of Porto Nocciola to fly. %d so far.", name, who), 4)
	elseif what == "busy" then showToast("The balloon is away. It will be back on the field soon.", 3)
	elseif what == "phase" then
		local m = yours
		local fl = m and m:FindFirstChild("Flame", true)
		if name == "board" and fl and flames[fl] then flames[fl].flare = 1; task.delay(3, function() if flames[fl] then flames[fl].flare = 0 end end) end
		if who ~= player then return end
		if name == "board" then flying = true end
		if name == "rise" then showToast("Up you go! Look at Porto Nocciola from the sky.", 5)
		elseif name == "gust" then
			showToast("Whoosh! A gust takes the balloon out to sea!", 4)
			sound(num("WindSoundId", 0), 0.7)
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
			stormOff()
			task.delay(0.6, function() TweenService:Create(black, TweenInfo.new(1.4), {BackgroundTransparency = 1}):Play(); TweenService:Create(cc, TweenInfo.new(1.4), {Brightness = 0}):Play() end)
			showToast("Back on the balloon field. More of the journey is coming soon!", 5)
		end
	end
end)
player.CharacterAdded:Connect(function() flying = false; if storming then stormOff() end; black.BackgroundTransparency = 1; cc.Brightness = 0; bb.Enabled = false; sign.Visible = false end)
print("BalloonClient: ready" .. (VR and " (VR)" or ""))

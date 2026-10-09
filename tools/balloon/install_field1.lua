-- balloon/install_field1 (job 33): EDIT mode. The hot air balloon field on the far shore (Shannon, Oct 9 2026).
-- Needs the balloon she imported (File > Import 3D of balloon_meshy.fbx: a Model with MeshParts Envelope, Basket, Rigging,
-- Burner, Flame). Makes it ServerStorage.BalloonTemplate, builds workspace.BalloonField with its scripts, RS.BalloonEvent.
-- Undo: tools/balloon/balloon_undo1.lua. Output lines start with "QQ FIELD".
if game:GetService("RunService"):IsRunning() then warn("QQ FIELD ABORT - Play mode") return end
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local oldF = workspace:FindFirstChild("BalloonField")
local keep = oldF and oldF:GetAttributes() or {}   -- re-runnable: the field is rebuilt from the template; attributes already set (sounds, tuning) are kept
if oldF then oldF:Destroy() end
local tpl = SS:FindFirstChild("BalloonTemplate")
if not tpl then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("MeshPart") and d.Name == "Envelope" then local m = d:FindFirstAncestorWhichIsA("Model"); if m and m:FindFirstChild("Basket", true) then tpl = m break end end
	end
end
if not tpl then warn("QQ FIELD ABORT - no imported balloon (a Model with MeshParts Envelope and Basket) in the workspace") return end
-- the template: anchored, no collisions (the field adds its own basket floor), colours for the untextured pieces
local COLOURS = {Rigging = {Color3.fromRGB(190, 160, 110), Enum.Material.SmoothPlastic}, Burner = {Color3.fromRGB(160, 162, 168), Enum.Material.Metal}, Flame = {Color3.fromRGB(255, 140, 30), Enum.Material.Neon}}
local names = {}
for _, d in ipairs(tpl:GetDescendants()) do
	if d:IsA("BasePart") then
		d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
		local c = COLOURS[d.Name]
		if c then d.Color = c[1]; d.Material = c[2] end
		if d.Name == "Flame" then
			d.CastShadow = false
			local l = d:FindFirstChildOfClass("PointLight") or Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 170, 70); l.Brightness = 1.5; l.Range = 16; l.Shadows = false; l.Parent = d
		end
		table.insert(names, d.Name)
	end
end
local basket = tpl:FindFirstChild("Basket", true)
if basket then
	-- the model pivot = the basket floor, upright (a PrimaryPart's PivotOffset is what PivotTo uses; WorldPivot would be ignored)
	tpl.PrimaryPart = basket
	basket.PivotOffset = basket.CFrame:Inverse() * CFrame.new(basket.Position - Vector3.new(0, basket.Size.Y / 2, 0))
end
tpl.Name = "BalloonTemplate"; tpl.Parent = SS
local evt = RS:FindFirstChild("BalloonEvent") or Instance.new("RemoteEvent"); evt.Name = "BalloonEvent"; evt.Parent = RS
local F = Instance.new("Folder"); F.Name = "BalloonField"
F:SetAttribute("Center", Vector3.new(106, -48.5, -648)); F:SetAttribute("Need", 44)
F:SetAttribute("PadYours", Vector3.new(72, 0, -646)); F:SetAttribute("ShowBalloons", false); F:SetAttribute("GustLean", 18); F:SetAttribute("PadYaw", 70); F:SetAttribute("PadTethered", Vector3.new(128, 0, -676))
F:SetAttribute("DriftCenter", Vector3.new(190, 18, -650)); F:SetAttribute("DriftRadius", 55); F:SetAttribute("DriftHeights", "18,33"); F:SetAttribute("DriftPeriods", "150,110")
F:SetAttribute("RiseHeight", 85); F:SetAttribute("RiseTime", 16); F:SetAttribute("HoverTime", 8); F:SetAttribute("GustTime", 18); F:SetAttribute("StormTime", 12); F:SetAttribute("SignTime", 6)
F:SetAttribute("MusicDuck", 0.4); F:SetAttribute("BeamSpin", 0.5); F:SetAttribute("BeamLength", 600); F:SetAttribute("BeamAfter", 6); F:SetAttribute("StormFogEnd", 90); F:SetAttribute("StormDensity", 0.85)
-- the Faro's lantern for the storm beam: the highest part standing within 18 studs of the lighthouse (door 520,2..8,-1169; keeper's base), roof cap less 3
local best, bestTop = nil, -math.huge
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d.Transparency < 1 and d.Size.Y >= 0.5 then
		local dx, dz = d.Position.X - 520, d.Position.Z + 1172
		local top = d.Position.Y + d.Size.Y / 2
		local name = d:GetFullName():lower()
		if dx * dx + dz * dz < 18 * 18 and top > bestTop and top < 140 and not (name:find("drone") or name:find("squirrel") or name:find("gull") or name:find("bird") or name:find("balloon")) then best, bestTop = d, top end
	end
end
local lightAt = best and Vector3.new(best.Position.X, bestTop - 3, best.Position.Z) or Vector3.new(520, 60, -1172)
F:SetAttribute("LightAt", lightAt)
F:SetAttribute("GustDir", Vector3.new(0.45, 0, -1)); F:SetAttribute("GustSpeed", 22); F:SetAttribute("ThunderSoundId", 92640524897440); F:SetAttribute("StormSoundId", 74201402219129); F:SetAttribute("WindSoundId", 93035214379043)
for _, k in ipairs({"ThunderSoundId", "StormSoundId", "WindSoundId"}) do local v = keep[k]; if type(v) == "number" and v > 0 then F:SetAttribute(k, v) end end   -- sounds Shannon set survive a re-run; positions and tuning take the new defaults
local sv = Instance.new("Script"); sv.Name = "BalloonServer"; sv.RunContext = Enum.RunContext.Server; sv.Source = [===[
-- BalloonServer (workspace.BalloonField): the hot air balloon field on the far shore across the harbour (Shannon, Oct 9
-- 2026). Show balloons drift round the shore (the clients move those); YOUR balloon waits on its pad: once a player has
-- found all of Porto Nocciola's squirrels, "Board" seats them and it rises for a view of the town, a gust blows it out
-- over the water, fog and lightning close in, a sign says "To Be Continued", and they are set down back on the field.
-- Every balloon is a clone of ServerStorage.BalloonTemplate (Shannon's Meshy balloon; pivot at the basket floor).
-- Attributes on the folder: Center, PadYours, PadTethered (Vector3; Y is found from the ground), Need (44),
-- DriftCenter, DriftRadius, DriftHeights ("10,25"), DriftPeriods ("150,110"), RiseHeight, GustDir (Vector3), GustSpeed,
-- ThunderSoundId, WindSoundId (0 = none).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local F = script.Parent
local ev = RS:WaitForChild("BalloonEvent")
local awardItems = RS:WaitForChild("AwardItems", 10)   -- Item_balloon_flights: the first flight turns the "your balloon is ready" sign off
local template = SS:WaitForChild("BalloonTemplate", 30)
if not template then warn("BalloonServer: no ServerStorage.BalloonTemplate") return end

local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function vec(name, d) local v = F:GetAttribute(name) return typeof(v) == "Vector3" and v or d end
local CENTER = vec("Center", Vector3.new(106, -48.5, -648))

-- ---------- the ground ----------
local gparams = RaycastParams.new(); gparams.FilterType = Enum.RaycastFilterType.Exclude; gparams.FilterDescendantsInstances = {F}; gparams.IgnoreWater = true
local function groundY(x, z, fallback)
	local hit = workspace:Raycast(Vector3.new(x, CENTER.Y + 60, z), Vector3.new(0, -140, 0), gparams)
	return hit and hit.Position.Y or fallback
end

-- ---------- Porto's squirrels (as the Guardian counts them) ----------
local PORTO_ID = {}
do
	local FRENCH = {forest = true, village = true, domaine = true}
	local ok, R = pcall(function() return require(workspace:WaitForChild("SquirrelScripts", 10):WaitForChild("SquirrelRegistry", 10)) end)
	if ok and R then for _, q in ipairs(R.squirrels or {}) do if not FRENCH[q.map] then PORTO_ID[q.id] = true end end end
end
local function portoFound(p)
	local s = p:GetAttribute("FoundIds")
	if type(s) ~= "string" or next(PORTO_ID) == nil then return tonumber(p:GetAttribute("Found_porto")) or 0 end
	local n = 0
	for id in s:gmatch("[^,]+") do if PORTO_ID[id] then n += 1 end end
	return n
end
local function need() return num("Need", 44) end

-- ---------- balloons ----------
local function makeBalloon(name, kind, cf)
	local m = template:Clone(); m.Name = name
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
	end
	m:SetAttribute("Kind", kind)
	m.ModelStreamingMode = (kind == "yours") and Enum.ModelStreamingMode.Persistent or Enum.ModelStreamingMode.Atomic   -- streaming is on: whole balloons, yours always present
	m:PivotTo(cf)
	m.Parent = F
	return m
end
local function invisible(p) p.Transparency = 1; p.Anchored = true; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false; return p end

local padYours = vec("PadYours", Vector3.new(72, 0, -646))
local padY = groundY(padYours.X, padYours.Z, CENTER.Y) + 0.1
local homeCF = CFrame.new(padYours.X, padY, padYours.Z) * CFrame.Angles(0, math.rad(num("PadYaw", 70)), 0)
local yours = makeBalloon("YourBalloon", "yours", homeCF)
local basket = yours:FindFirstChild("Basket", true)
-- a floor and walls inside the wicker (the mesh itself does not collide), and the seat the flight carries
local floor = invisible(Instance.new("Part")); floor.Name = "Floor"; floor.Size = Vector3.new(8.2, 0.4, 8.2); floor.CanCollide = true
floor.CFrame = homeCF * CFrame.new(0, 0.45, 0); floor.Parent = yours
for i, off in ipairs({Vector3.new(4.2, 2.6, 0), Vector3.new(-4.2, 2.6, 0), Vector3.new(0, 2.6, 4.2), Vector3.new(0, 2.6, -4.2)}) do
	local w = invisible(Instance.new("Part")); w.Name = "Wall" .. i; w.CanCollide = true
	w.Size = (i <= 2) and Vector3.new(0.3, 4.6, 8.6) or Vector3.new(8.6, 4.6, 0.3)
	w.CFrame = homeCF * CFrame.new(off); w.Parent = yours
end
local seat = invisible(Instance.new("Seat")); seat.Name = "FlightSeat"; seat.Size = Vector3.new(2, 0.6, 2); seat.CanCollide = false
seat.CFrame = homeCF * CFrame.new(0, num("SeatHeight", 2.0), 0); seat.Parent = yours
local prompt = Instance.new("ProximityPrompt"); prompt.Name = "BoardPrompt"; prompt.ObjectText = "Your balloon"; prompt.ActionText = "All aboard"
prompt.MaxActivationDistance = 14; prompt.HoldDuration = 0.3; prompt.RequiresLineOfSight = false; prompt.UIOffset = Vector2.new(0, -40)
prompt.Parent = basket or yours.PrimaryPart or yours:FindFirstChildWhichIsA("BasePart")

if F:GetAttribute("ShowBalloons") == true then   -- Shannon, Oct 9 evening: just the one balloon you travel in
local padT = vec("PadTethered", Vector3.new(128, 0, -676))
makeBalloon("TetheredBalloon", "tethered", CFrame.new(padT.X, groundY(padT.X, padT.Z, CENTER.Y) + 0.1, padT.Z) * CFrame.Angles(0, math.rad(-30), 0))
do
	local heights, periods = {}, {}
	for v in tostring(F:GetAttribute("DriftHeights") or "10,25"):gmatch("[-%d%.]+") do table.insert(heights, tonumber(v)) end
	for v in tostring(F:GetAttribute("DriftPeriods") or "150,110"):gmatch("[-%d%.]+") do table.insert(periods, tonumber(v)) end
	local dc = vec("DriftCenter", Vector3.new(190, 18, -650))
	for i = 1, math.max(1, #heights) do
		local m = makeBalloon("DriftBalloon" .. i, "drift", CFrame.new(dc.X + num("DriftRadius", 55), heights[i] or 18, dc.Z))
		m:SetAttribute("Index", i); m:SetAttribute("Height", heights[i] or 15); m:SetAttribute("Period", periods[i] or 150)
		m:SetAttribute("Phase", (i - 1) * 2.4)
	end
end
end
print("BalloonServer: balloon on the field")

-- ---------- the flight ----------
local busy = nil
local function ease(t) t = math.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
local function setHome() yours:PivotTo(homeCF) end
local function flight(p)
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root and hum.Health > 0) then busy = nil return end
	local jp, jh, ujp = hum.JumpPower, hum.JumpHeight, hum.UseJumpPower
	hum.Sit = false
	char:PivotTo(seat.CFrame * CFrame.new(0, 2.6, 0))
	task.wait(0.1)
	seat:Sit(hum)
	task.wait()
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)   -- a jump would break the seat weld and end the flight
	hum.UseJumpPower = true; hum.JumpPower = 0; hum.JumpHeight = 0
	local T = {rise = num("RiseTime", 16), hover = num("HoverTime", 8), gust = num("GustTime", 18), storm = num("StormTime", 12), sign = num("SignTime", 6), fade = 2.5}
	ev:FireAllClients("phase", p, "board", 2)
	ev:FireAllClients("phase", p, "rise", T.rise)
	local H = num("RiseHeight", 85)
	local dir = vec("GustDir", Vector3.new(0.45, 0, -1)); dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local speed = num("GustSpeed", 22)
	local order = {"rise", "hover", "gust", "storm", "sign", "fade"}
	local t0 = os.clock(); local phaseIndex, phaseStart = 1, 0
	local drift = Vector3.zero
	local aborted = false
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - t0
		local name = order[phaseIndex]
		if t - phaseStart >= T[name] then
			phaseIndex += 1; phaseStart = t
			if phaseIndex > #order then conn:Disconnect() return end
			name = order[phaseIndex]
			ev:FireAllClients("phase", p, name, T[name])
		end
		-- height: up during rise, then level, a little higher in the gust
		local y
		if name == "rise" then y = H * ease((t - phaseStart) / T.rise)
		else y = H + (phaseIndex >= 3 and 12 * ease((t - (T.rise + T.hover)) / 10) or 0) end
		-- the gust: speed ramps up over 3 s and eases off in the storm
		if phaseIndex >= 3 then
			local since = t - (T.rise + T.hover)
			local v = speed * ease(since / 3) * (phaseIndex >= 4 and math.max(0.35, 1 - (t - (T.rise + T.hover + T.gust)) / (T.storm + T.sign + T.fade) * 0.6) or 1)
			drift += dir * v * dt
		end
		local sway = Vector3.new(1.4 * math.sin(t * 0.7), 0.4 * math.sin(t * 1.3), 1.1 * math.sin(t * 0.5 + 1))
		-- the gust: a hard lean downwind that wobbles, easing as the storm takes over
		local gustK = (phaseIndex >= 3) and ease((t - (T.rise + T.hover)) / 2.5) * (phaseIndex >= 4 and 0.55 or 1) or 0
		local tilt = math.rad(num("GustLean", 18)) * gustK * (0.75 + 0.25 * math.sin(t * 2.3)) + math.rad(3) * gustK * math.sin(t * 5.1)
		local cf = CFrame.new(homeCF.Position + Vector3.new(0, y, 0) + drift + sway) * CFrame.Angles(0, math.rad(num("PadYaw", 70)) + t * 0.04, 0) * CFrame.Angles(tilt * -dir.Z, 0, tilt * dir.X)
		yours:PivotTo(cf)
		if (t > 0.6 and seat.Occupant ~= hum) or hum.Health <= 0 or p.Parent ~= Players then aborted = true; conn:Disconnect() end   -- (the weld takes a physics step to land)
	end)
	while conn.Connected do task.wait(0.1) end
	-- home again
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	hum.Sit = false
	task.wait(0.15)
	setHome()
	if p.Parent == Players and char.Parent and hum.Health > 0 then
		hum.UseJumpPower = ujp; hum.JumpPower = jp; hum.JumpHeight = jh
		char:PivotTo(homeCF * CFrame.new(7, 3, 2))
	end
	ev:FireAllClients("phase", p, "home", 2)
	prompt.Enabled = true
	if aborted then print("BalloonServer: flight of " .. p.Name .. " cut short")
	elseif awardItems and p.Parent == Players then awardItems:Fire(p, "balloon_flights", 1) end
	busy = nil
end
prompt.Triggered:Connect(function(p)
	if busy then ev:FireClient(p, "busy") return end
	local n = portoFound(p)
	if n < need() then ev:FireClient(p, "locked", n, need()) return end
	busy = p
	prompt.Enabled = false   -- no boarding prompt while the balloon is away (Shannon)
	task.spawn(flight, p)
end)
Players.PlayerRemoving:Connect(function(p) if busy == p then busy = nil; prompt.Enabled = true; task.delay(0.5, setHome) end end)
print(string.format("BalloonServer: ready (your balloon at %.0f,%.0f,%.0f; %d squirrels to fly)", homeCF.Position.X, homeCF.Position.Y, homeCF.Position.Z, need()))
]===]; sv.Parent = F
local cl = Instance.new("Script"); cl.Name = "BalloonClient"; cl.RunContext = Enum.RunContext.Client; cl.Source = [===[
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
		if n >= need then prompt.ObjectText = "Your balloon"; prompt.ActionText = "All aboard"
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
local function stormOn(secs)
	if not saved then saved = {FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
		density = atmo and atmo.Density, haze = atmo and atmo.Haze, color = atmo and atmo.Color, cover = clouds and clouds.Cover, cdensity = clouds and clouds.Density, ccolor = clouds and clouds.Color} end
	local sid = num("StormSoundId", 0)
	if sid > 0 and not stormSound then
		stormSound = Instance.new("Sound"); stormSound.SoundId = "rbxassetid://" .. tostring(sid); stormSound.Looped = true; stormSound.Volume = 0; stormSound.Parent = SoundService; stormSound:Play()
		TweenService:Create(stormSound, TweenInfo.new(4), {Volume = 0.6}):Play()
	end
	if windSound then local w = windSound; windSound = nil; TweenService:Create(w, TweenInfo.new(5), {Volume = 0}):Play(); game:GetService("Debris"):AddItem(w, 5.5) end   -- the wind gives way to the storm
	-- clouds close in first, then the light goes, then the fog
	if clouds then TweenService:Create(clouds, TweenInfo.new(7, Enum.EasingStyle.Sine), {Cover = 1, Density = 1, Color = Color3.fromRGB(70, 72, 80)}):Play() end
	TweenService:Create(Lighting, TweenInfo.new(9, Enum.EasingStyle.Sine), {Brightness = 0.35, OutdoorAmbient = Color3.fromRGB(55, 58, 68), FogColor = Color3.fromRGB(96, 100, 110)}):Play()
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
	beamOff()
	if not saved then return end
	TweenService:Create(Lighting, TweenInfo.new(3, Enum.EasingStyle.Sine), {FogEnd = saved.FogEnd, FogStart = saved.FogStart, FogColor = saved.FogColor, Brightness = saved.Brightness, OutdoorAmbient = saved.OutdoorAmbient}):Play()
	Lighting.Ambient = saved.Ambient
	if atmo then TweenService:Create(atmo, TweenInfo.new(3, Enum.EasingStyle.Sine), {Density = saved.density, Haze = saved.haze, Color = saved.color}):Play() end
	if clouds and saved.cover ~= nil then TweenService:Create(clouds, TweenInfo.new(4, Enum.EasingStyle.Sine), {Cover = saved.cover, Density = saved.cdensity, Color = saved.ccolor}):Play() end
	wind.Enabled = false
	if stormSound then local s = stormSound; stormSound = nil; TweenService:Create(s, TweenInfo.new(3), {Volume = 0}):Play(); game:GetService("Debris"):AddItem(s, 3.5) end
	if windSound then local w = windSound; windSound = nil; TweenService:Create(w, TweenInfo.new(2), {Volume = 0}):Play(); game:GetService("Debris"):AddItem(w, 2.5) end
	saved = nil
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

-- ---------- phases ----------
local flying = false
ev.OnClientEvent:Connect(function(what, who, name, secs)
	if what == "locked" then showToast(string.format("Find all %d squirrels of Porto Nocciola to fly. %d so far.", name, who), 4)
	elseif what == "busy" then showToast("The balloon is away. It will be back on the field soon.", 3)
	elseif what == "phase" then
		local m = yours
		local fl = m and m:FindFirstChild("Flame", true)
		if name == "board" and fl and flames[fl] then flames[fl].flare = 1; task.delay(3, function() if flames[fl] then flames[fl].flare = 0 end end) end
		if name == "board" then smoothStart() elseif name == "home" then smoothStop() end
		if who ~= player then return end
		if name == "board" then flying = true end
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
			stormOff(); duckMusic(false, 3)
			task.delay(0.6, function() TweenService:Create(black, TweenInfo.new(1.4), {BackgroundTransparency = 1}):Play(); TweenService:Create(cc, TweenInfo.new(1.4), {Brightness = 0}):Play() end)
			showToast("Back on the balloon field. More of the journey is coming soon!", 5)
		end
	end
end)
player.CharacterAdded:Connect(function() flying = false; if storming then stormOff() end; duckMusic(false, 1); black.BackgroundTransparency = 1; cc.Brightness = 0; bb.Enabled = false; sign.Visible = false end)
print("BalloonClient: ready" .. (VR and " (VR)" or ""))
]===]; cl.Parent = F
for _, s in ipairs({sv, cl}) do local f, err = loadstring(s.Source); if not f then warn("QQ FIELD ABORT - " .. s.Name .. " does not compile: " .. tostring(err)); F:Destroy(); return end end
F.Parent = workspace
print(string.format("QQ FIELD DONE: template %s (%s) -> ServerStorage.BalloonTemplate; workspace.BalloonField with BalloonServer %d / BalloonClient %d chars; RS.BalloonEvent; lantern %s from %s", tpl.Name, table.concat(names, ","), #sv.Source, #cl.Source, tostring(lightAt), best and best:GetFullName() or "GUESS (no part found)"))

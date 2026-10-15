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
local PreviewAccess = require(game.ServerScriptService:WaitForChild("JapanPreviewAccess"))
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
-- WHAT THE RIDER MUST KEEP SEEING from up there (Shannon, Oct 10: the funicolare "fades in and out" on the ride - streaming
-- drops it at that distance on a headset): every model named in the folder's RidePersistent attribute (workspace paths,
-- ";" apart; the installer sets them to ModelStreamingMode PersistentPerPlayer) stays loaded for the rider for the ride.
local function ridePersist(p, on)
	for path in string.gmatch(tostring(F:GetAttribute("RidePersistent") or ""), "[^;]+") do
		path = path:match("^%s*(.-)%s*$")
		local m = workspace
		for seg in string.gmatch(path, "[^/]+") do m = m and m:FindFirstChild(seg) end
		if m and m:IsA("Model") then
			pcall(function() if on then m:AddPersistentPlayer(p) else m:RemovePersistentPlayer(p) end end)
		elseif on and path ~= "" then warn("BalloonServer: RidePersistent names no Model at workspace/" .. path) end
	end
end
local function flight(p)
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root and hum.Health > 0) then busy = nil; prompt.Enabled = true return end   -- (the prompt went off at the trigger)
	local jp, jh, ujp = hum.JumpPower, hum.JumpHeight, hum.UseJumpPower
	local couldJump = hum:GetStateEnabled(Enum.HumanoidStateType.Jumping)
	local preview = PreviewAccess.IsAllowed(p)
	local landed = false
	local connection
	local landCF = CFrame.new(6090, .1, 270) * CFrame.Angles(0, math.rad(180), 0)
	local approachCF = CFrame.new(6120, 100, 350) * CFrame.Angles(0, math.rad(180), 0)
	local function live()
		return p.Parent == Players and p.Character == char and char.Parent and hum.Health > 0 and seat.Occupant == hum
	end
	local function phase(name, secs)
		p:SetAttribute("JapanBalloonPhase", name)
		ev:FireClient(p, "phase", p, name, secs)
	end
	local function waitAboard(seconds)
		local untilTime = os.clock()+seconds
		repeat task.wait(.05); if not live() then error("Flight interrupted") end until os.clock()>=untilTime
	end
	if preview then
		p:SetAttribute("JapanPreviewInFlight", true)
	end
	local ok, flightError = xpcall(function()
	hum.Sit = false
	char:PivotTo(seat.CFrame * CFrame.new(0, 2.6, 0))
	task.wait(0.1)
	seat:Sit(hum)
	task.wait()
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)   -- a jump would break the seat weld and end the flight
	hum.UseJumpPower = true; hum.JumpPower = 0; hum.JumpHeight = 0
	local T = {rise = num("RiseTime", 16), hover = num("HoverTime", 8), gust = num("GustTime", 18), storm = num("StormTime", 12), sign = num("SignTime", 6), fade = 2.5}
	ridePersist(p, true)
	ev:FireAllClients("phase", p, "board", 2)
	ev:FireAllClients("phase", p, "rise", T.rise)
	local H = num("RiseHeight", 85)
	local dir = vec("GustDir", Vector3.new(0.45, 0, -1)); dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local speed = num("GustSpeed", 22)
	local order = preview and {"rise", "hover", "gust", "storm", "sign"} or {"rise", "hover", "gust", "storm", "sign", "fade"}
	p:SetAttribute("JapanBalloonPhase", "rise")
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
			p:SetAttribute("JapanBalloonPhase", name)
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
	connection=conn
	while conn.Connected do task.wait(0.1) end
	if aborted then error("Flight interrupted") end
	if preview then
		assert(PreviewAccess.IsAllowed(p), "Preview access revoked")
		phase("previewCloud", 2.5)
		waitAboard(2.5)
		-- Streaming is requested on the server with a finite timeout, while cloud hides the move.
		p:RequestStreamAroundAsync(landCF.Position, 8)
		assert(live(), "Flight interrupted during loading")
		yours:PivotTo(approachCF)
		p:RequestStreamAroundAsync(approachCF.Position, 5)
		waitAboard(1.5)
		phase("previewReveal", 6)
		waitAboard(6)
		phase("previewDescent", 16)
		local descentStart=os.clock()
		while os.clock()-descentStart<16 do
			assert(live() and PreviewAccess.IsAllowed(p), "Landing interrupted")
			local t=math.clamp((os.clock()-descentStart)/16,0,1)
			local sway=Vector3.new(math.sin(t*math.pi*4)*.7*(1-t),0,math.sin(t*math.pi*3)*.4*(1-t))
			yours:PivotTo(approachCF:Lerp(landCF,ease(t))+sway)
			RunService.Heartbeat:Wait()
		end
		yours:PivotTo(landCF)
		phase("previewTouchdown", 2)
		waitAboard(2)
		landed=true
	end
	end, debug.traceback)
	if connection and connection.Connected then connection:Disconnect() end
	local weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end
	hum.Sit=false
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,couldJump)
	hum.UseJumpPower=ujp;hum.JumpPower=jp;hum.JumpHeight=jh
	task.wait(.15)
	if p.Parent==Players and p.Character==char and char.Parent and hum.Health>0 then
		local target=landed and CFrame.new(6100,4,270) or homeCF*CFrame.new(7,3,2)
		char:PivotTo(target);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
		if landed then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end
	p:SetAttribute("JapanPreviewInFlight",nil)
	ridePersist(p,false)
	if landed then
		phase("previewLanded",3)
		-- Leave the basket down long enough to see the arrival before returning it for the next rider.
		task.wait(2)
		setHome()
		ev:FireAllClients("phase",p,"reset",0)
	else
		setHome()
		ev:FireAllClients("phase",p,"home",2)
		p:SetAttribute("JapanBalloonPhase","home")
	end
	prompt.Enabled=true
	busy=nil
	if not ok then warn("BalloonServer: "..tostring(flightError))
	elseif not preview and awardItems and p.Parent==Players then awardItems:Fire(p,"balloon_flights",1) end
end
prompt.Triggered:Connect(function(p)
	if busy then ev:FireClient(p, "busy") return end
	local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local parent=prompt.Parent
	if not prompt.Enabled or not root or not parent:IsA("BasePart") or (root.Position-parent.Position).Magnitude>18 then return end
	local n = portoFound(p)
	if n < need() and not PreviewAccess.IsAllowed(p) then ev:FireClient(p, "locked", n, need()) return end
	busy = p
	prompt.Enabled = false   -- no boarding prompt while the balloon is away (Shannon)
	task.spawn(flight, p)
end)
-- The active flight owns cleanup; a disconnect cannot reset another rider's balloon.
print(string.format("BalloonServer: ready (your balloon at %.0f,%.0f,%.0f; %d squirrels to fly)", homeCF.Position.X, homeCF.Position.Y, homeCF.Position.Z, need()))


-- FilmClient (workspace.FilmMode, RunContext Client): Shannon's filming mode for TikTok (Oct 8 2026). Only for the game's
-- owner (FilmMode.OwnerIds; anyone in Studio). F8 opens a small menu: hide my name & title, hide the screen UI, the scenic
-- camera tours (Tours module, framed for a 9:16 portrait window) and a free-fly drone camera. While a tour runs the
-- character is carried invisibly with the camera, so the place around it streams in and France / Porto show the right map;
-- it is put back where it was at the end. F8 stops a tour or the drone (F7 belongs to Roblox). Record with Win+Alt+R.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer
local F = script.Parent
local function allowed()
	if RunService:IsStudio() then return true end
	for id in string.gmatch(tostring(F:GetAttribute("OwnerIds") or ""), "%d+") do if tonumber(id) == player.UserId then return true end end
	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end
if not allowed() then return end
local Tours = require(F:WaitForChild("Tours"))
local pg = player:WaitForChild("PlayerGui")
local C = Color3.fromRGB
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local nameHidden, uiHidden, running, stopFlag, speed = false, false, nil, false, 1
local menuGui

-- ---------- hiding names and titles (every character's billboards: the honour tag, bubbles over heads) ----------
local nameStore = {}
local function applyNames()
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if char then
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BillboardGui") then
					if nameHidden then
						if nameStore[d] == nil then nameStore[d] = d.Enabled end
						d.Enabled = false
					elseif nameStore[d] ~= nil then
						d.Enabled = nameStore[d]; nameStore[d] = nil
					end
				end
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and nameHidden then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
		end
	end
end
task.spawn(function() while true do task.wait(1) if nameHidden then applyNames() end end end)   -- titles that come back are hidden again

-- ---------- hiding the screen UI (our ScreenGuis, Roblox's own bars, prompts, chat bubbles, signs drawn on top) ----------
local uiStore, worldStore, addedConn = {}, {}, nil
local function hideGui(g)
	if g == menuGui then return end
	if (g:IsA("ScreenGui") or g:IsA("BillboardGui") or g:IsA("SurfaceGui")) and g.Enabled then uiStore[g] = true; g.Enabled = false end
end
local function setUIHidden(on)
	if on == uiHidden then return end
	uiHidden = on
	if on then
		for _, g in ipairs(pg:GetChildren()) do hideGui(g) end
		addedConn = pg.ChildAdded:Connect(function(g) task.defer(function() if uiHidden then hideGui(g) end end) end)
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BillboardGui") and d.AlwaysOnTop and d.Enabled then worldStore[d] = true; d.Enabled = false end
		end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
		pcall(function() game:GetService("ProximityPromptService").Enabled = false end)
		pcall(function() TextChatService.BubbleChatConfiguration.Enabled = false end)
	else
		if addedConn then addedConn:Disconnect(); addedConn = nil end
		for g in pairs(uiStore) do if g.Parent then g.Enabled = true end end
		for g in pairs(worldStore) do if g.Parent then g.Enabled = true end end
		uiStore, worldStore = {}, {}
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
		pcall(function() game:GetService("ProximityPromptService").Enabled = true end)
		pcall(function() TextChatService.BubbleChatConfiguration.Enabled = true end)
	end
end

-- ---------- carrying the character, invisible, with the camera (so the map streams in around the shot) ----------
local carry, controls = {}, nil
local function startCarry()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum) then return false end
	carry = {home = root.CFrame, parts = {}, root = root, hum = hum}
	hum.PlatformStand = true
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then carry.parts[d] = {d.CanCollide, d.LocalTransparencyModifier}; d.CanCollide = false; d.LocalTransparencyModifier = 1
		elseif d:IsA("Decal") then carry.parts[d] = {nil, d.LocalTransparencyModifier}; d.LocalTransparencyModifier = 1 end
	end
	controls = nil                                          -- the standard controls, if this game has them (never wait for them)
	local ps = player:FindFirstChild("PlayerScripts")
	local pm = ps and ps:FindFirstChild("PlayerModule")
	if pm then pcall(function() controls = require(pm):GetControls(); controls:Disable() end) end
	return true
end
local function carryTo(pos)
	local r = carry.root
	if r and r.Parent then r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero; r.CFrame = CFrame.new(pos) end
	for d, st in pairs(carry.parts or {}) do if d.Parent then d.LocalTransparencyModifier = 1 end end
end
local function endCarry()
	local r = carry.root
	if r and r.Parent and carry.home then r.AssemblyLinearVelocity = Vector3.zero; r.CFrame = carry.home end
	for d, st in pairs(carry.parts or {}) do if d.Parent then if st[1] ~= nil then d.CanCollide = st[1] end; d.LocalTransparencyModifier = st[2] end end
	if carry.hum and carry.hum.Parent then carry.hum.PlatformStand = false end
	pcall(function() if controls then controls:Enable() end end)
	carry = {}
end
local function streamNear(pos) task.spawn(function() pcall(function() player:RequestStreamAroundAsync(pos, 3) end) end) end

-- ---------- the camera paths ----------
local function catmull(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end
local function makePath(keys)
	local P, L = {}, {}
	for _, k in ipairs(keys) do table.insert(P, k[1]); table.insert(L, k[2]) end
	local n = #P
	local function at(list, x)
		local i = math.clamp(math.floor(x), 0, n - 2)
		local t = x - i
		local function g(j) return list[math.clamp(j, 1, n)] end
		return catmull(g(i), g(i + 1), g(i + 2), g(i + 3), t)
	end
	local xs, ds, total, last = {}, {}, 0, nil
	for k = 0, 600 do
		local x = (n - 1) * k / 600
		local p = at(P, x)
		if last then total += (p - last).Magnitude end
		last = p; xs[k + 1] = x; ds[k + 1] = total
	end
	return function(u)                                     -- u in 0..1 of the distance -> position, look-at point
		local s = math.clamp(u, 0, 1) * total
		local lo, hi = 1, #ds
		while hi - lo > 1 do local mid = (lo + hi) // 2; if ds[mid] <= s then lo = mid else hi = mid end end
		local f = ds[hi] > ds[lo] and (s - ds[lo]) / (ds[hi] - ds[lo]) or 0
		local x = xs[lo] + (xs[hi] - xs[lo]) * f
		return at(P, x), at(L, x)
	end, total
end
local function ease(u, r)                                  -- an even glide with soft starts and stops
	if u < r then return (u * u) / (2 * r * (1 - r)) end
	if u > 1 - r then return 1 - ((1 - u) * (1 - u)) / (2 * r * (1 - r)) end
	return (u - r / 2) / (1 - r)
end

local function camera() return workspace.CurrentCamera end
local function hold(cf, fov, secs)
	local t0 = os.clock()
	while os.clock() - t0 < secs and not stopFlag do
		local cam = camera(); cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = cf; cam.FieldOfView = fov
		carryTo(cf.Position)
		RunService.RenderStepped:Wait()
	end
end
local function finish(wasUI)
	endCarry()
	local cam = camera()
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
	cam.FieldOfView = 70
	if not wasUI then setUIHidden(false) end
	running, stopFlag = nil, false
end
local function closeMenu() if menuGui then menuGui.Enabled = false end end

local function runTour(tour)
	if running then return end
	running, stopFlag = tour.id, false
	closeMenu()
	local wasUI = uiHidden
	setUIHidden(true)
	if not startCarry() then finish(wasUI) return end
	local sample, length = makePath(tour.keys)
	local p0, l0 = sample(0)
	pcall(function() player:RequestStreamAroundAsync(p0, 4) end)
	hold(CFrame.lookAt(p0, l0), tour.fov, 2.0)                -- the opening frame stands still while the place loads
	local dur = tour.secs / speed
	local start, nextStream = os.clock(), 0
	while not stopFlag do
		local t = (os.clock() - start) / dur
		if t >= 1 then break end
		local pos, look = sample(ease(t, 0.18))
		if os.clock() > nextStream then nextStream = os.clock() + 1; streamNear(sample(math.min(1, ease(t, 0.18) + 0.12))) end
		local cam = camera(); cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(pos, look); cam.FieldOfView = tour.fov
		carryTo(pos)
		RunService.RenderStepped:Wait()
	end
	if not stopFlag then local pe, le = sample(1); hold(CFrame.lookAt(pe, le), tour.fov, 1.5) end
	finish(wasUI)
end

-- ---------- the whale: its timetable (as WhaleClient works it out) for the countdown, and a slow orbit round it ----------
local whale, W
local function getWhale()
	if not (whale and whale.Parent) then whale = workspace:FindFirstChild("PortoWhale"); W = nil end
	return whale
end
local function buildWhale()
	if not getWhale() then return nil end
	local function wn(name, d) local v = whale:GetAttribute(name) return typeof(v) == "number" and v or d end
	local route = {}
	for x, z in string.gmatch(whale:GetAttribute("Route") or "", "([-%d%.]+),([-%d%.]+)") do table.insert(route, Vector3.new(tonumber(x), 0, tonumber(z))) end
	local n = #route
	if n < 3 then return nil end
	local blowIdx = {}
	for i in string.gmatch(whale:GetAttribute("BlowAt") or "1", "%d+") do blowIdx[tonumber(i)] = true end
	local function P(i) return route[((i - 1) % n) + 1] end
	local stations, acc, first, last = {}, 0, nil, nil
	for i = 1, n do
		if blowIdx[i] then table.insert(stations, acc) end
		for k = 0, 23 do
			local p = catmull(P(i - 1), P(i), P(i + 1), P(i + 2), k / 24)
			if last then acc += (p - last).Magnitude end
			last = p; first = first or p
		end
	end
	acc += (first - last).Magnitude
	if #stations == 0 then stations = {0} end
	table.sort(stations)
	local BLOW, SPEED = wn("BlowDur", 12), wn("Speed", 7)
	local starts, T = {}, 0
	for k, s in ipairs(stations) do
		table.insert(starts, T + 2) T += BLOW
		local s2 = stations[k + 1] or (stations[1] + acc)
		local dur = (s2 - s) / SPEED
		if dur > 0.01 then T += dur end
	end
	return {starts = starts, T = T, lag = wn("TimeLag", 0)}
end
local function nextSpout()
	getWhale()
	W = W or buildWhale()
	if not W then return nil end
	local spout = (whale and whale:GetAttribute("SpoutSecs")) or 2
	local t = (workspace:GetServerTimeNow() - W.lag) % W.T
	local best = math.huge
	for _, s0 in ipairs(W.starts) do
		if t >= s0 and t < s0 + spout then return 0 end
		local d = (s0 - t) % W.T
		if d < best then best = d end
	end
	return best
end
local function runWhale(tour)
	if running then return end
	getWhale()
	local mesh = whale and whale:FindFirstChildWhichIsA("MeshPart", true)
	if not mesh then return end
	running, stopFlag = tour.id, false
	closeMenu()
	local wasUI = uiHidden
	setUIHidden(true)
	if not startCarry() then finish(wasUI) return end
	local water = whale:GetAttribute("WaterY") or -52.9
	local a = math.rad(200)
	local camPos, look
	local nextStream = 0
	while not stopFlag do
		local dt = RunService.RenderStepped:Wait()
		local target = mesh.Position + Vector3.new(0, 3, 0)
		a += dt * 0.07 * speed
		local desired = target + Vector3.new(math.cos(a) * 44, 11, math.sin(a) * 44)
		desired = Vector3.new(desired.X, math.max(desired.Y, water + 4), desired.Z)
		camPos = camPos and camPos:Lerp(desired, 1 - math.exp(-dt * 1.2)) or desired
		look = look and look:Lerp(target, 1 - math.exp(-dt * 2.5)) or target
		local cam = camera(); cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(camPos, look); cam.FieldOfView = tour.fov
		carryTo(camPos)
		if os.clock() > nextStream then nextStream = os.clock() + 1.5; streamNear(camPos) end
	end
	finish(wasUI)
end

-- ---------- the drone: WASD to fly, E up, Q down, hold the right mouse button to look, wheel for speed, Shift = slow ----------
local function runDrone(tour)
	if running then return end
	running, stopFlag = tour.id, false
	closeMenu()
	local wasUI = uiHidden
	setUIHidden(true)
	if not startCarry() then finish(wasUI) return end
	local cam = camera()
	local pos = cam.CFrame.Position
	local _, yaw, _ = cam.CFrame:ToEulerAnglesYXZ()
	local pitch = math.asin(math.clamp(cam.CFrame.LookVector.Y, -0.99, 0.99))
	local wantYaw, wantPitch = yaw, pitch
	local vel, spd = Vector3.zero, 18
	local looking = false
	local conns = {}
	table.insert(conns, UIS.InputBegan:Connect(function(input, gp)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then looking = true; UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then looking = false; UIS.MouseBehavior = Enum.MouseBehavior.Default end
	end))
	table.insert(conns, UIS.InputChanged:Connect(function(input, gp)
		if input.UserInputType == Enum.UserInputType.MouseMovement and looking then
			wantYaw -= input.Delta.X * 0.0035
			wantPitch = math.clamp(wantPitch - input.Delta.Y * 0.0035, -1.45, 1.45)
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			spd = math.clamp(spd * (input.Position.Z > 0 and 1.25 or 0.8), 3, 140)
		end
	end))
	local nextStream = 0
	while not stopFlag do
		local dt = RunService.RenderStepped:Wait()
		local move = Vector3.zero
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
			if UIS:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1) end
			if UIS:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0) end
		end
		yaw += (wantYaw - yaw) * (1 - math.exp(-dt * 8))
		pitch += (wantPitch - pitch) * (1 - math.exp(-dt * 8))
		local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
		local world = rot:VectorToWorldSpace(move)
		if UIS:IsKeyDown(Enum.KeyCode.E) then world += Vector3.new(0, 1, 0) end
		if UIS:IsKeyDown(Enum.KeyCode.Q) then world -= Vector3.new(0, 1, 0) end
		local slow = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 0.3 or 1
		local target = world.Magnitude > 0 and world.Unit * spd * slow or Vector3.zero
		vel = vel:Lerp(target, 1 - math.exp(-dt * 2.5))
		pos += vel * dt
		cam = camera(); cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.new(pos) * rot; cam.FieldOfView = tour.fov
		carryTo(pos)
		if os.clock() > nextStream then nextStream = os.clock() + 1; streamNear(pos + rot.LookVector * 60) end
	end
	for _, c in ipairs(conns) do c:Disconnect() end
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	finish(wasUI)
end

-- ---------- the balloon flight (Oct 9): press it, climb aboard, and the flight is filmed from liftoff to landing ----------
-- Shannon: "one of those camera tour things of going up in the balloon into the storm ending with coming soon". The rider
-- stays in the basket (the flight needs them in the seat), so the character is not carried; the camera is its own: liftoff
-- from the grass, a slow circle in the climb with the town behind, a chase through the gust, close in the storm, the sign.
-- BalloonGui (the words, the sign, the fade to black) stays on; everything else is hidden as in every tour. F8 stops the
-- filming; the flight goes on. The camera is set after BalloonClient's smoothing (render priority Camera + 1).
local function runBalloon(tour)
	if running then return end
	local BF = workspace:FindFirstChild("BalloonField")
	local yours = BF and BF:FindFirstChild("YourBalloon")
	local seat = yours and yours:FindFirstChild("FlightSeat", true)
	if not (yours and seat) then return end
	running, stopFlag = tour.id, false
	closeMenu()
	local function bn(name, d) local v = BF:GetAttribute(name) return typeof(v) == "number" and v or d end
	local function bv(name, d) local v = BF:GetAttribute(name) return typeof(v) == "Vector3" and v or d end
	local function seated() local c = player.Character; local h = c and c:FindFirstChildOfClass("Humanoid") return h ~= nil and h.SeatPart == seat end
	-- first the rider climbs aboard (the prompt needs the UI, so nothing is hidden yet)
	local waitGui = Instance.new("ScreenGui"); waitGui.Name = "FilmWait"; waitGui.ResetOnSpawn = false; waitGui.DisplayOrder = 61
	local w = Instance.new("TextLabel"); w.AnchorPoint = Vector2.new(0.5, 1); w.Position = UDim2.new(0.5, 0, 1, -40); w.Size = UDim2.fromOffset(460, 40)
	w.BackgroundColor3 = C(34, 26, 46); w.BackgroundTransparency = 0.15; w.FontFace = FONT; w.TextSize = 16; w.TextColor3 = C(255, 246, 220); w.TextWrapped = true
	w.Text = "Balloon flight: climb aboard (All aboard) - filming starts as it lifts off.  F8 cancels."; w.Parent = waitGui
	local wc = Instance.new("UICorner"); wc.CornerRadius = UDim.new(0, 10); wc.Parent = w
	waitGui.Parent = pg
	local t0 = os.clock()
	while not stopFlag and not seated() do
		if os.clock() - t0 > 240 then stopFlag = true end
		task.wait(0.1)
	end
	waitGui:Destroy()
	if stopFlag then running, stopFlag = nil, false return end
	local wasUI = uiHidden
	setUIHidden(true)
	local bg = pg:FindFirstChild("BalloonGui"); if bg then bg.Enabled = true end   -- her words, the sign and the fade are part of the film
	local dir = bv("GustDir", Vector3.new(0.45, 0, -1)); dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local side = dir:Cross(Vector3.yAxis)
	local home = yours:GetPivot().Position
	local grass = home - dir * 12 - side * 22   -- the liftoff camera stands on the field, inland of the pad
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {BF, player.Character}
	local hit = workspace:Raycast(grass + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), rp)
	grass = Vector3.new(grass.X, (hit and hit.Position.Y or home.Y) + 2.5, grass.Z)
	local T = {rise = bn("RiseTime", 16), hover = bn("HoverTime", 8), gust = bn("GustTime", 18)}
	local lift, pos, lookS, lastShot, unseatAt = nil, nil, nil, nil, nil
	RunService:BindToRenderStep("FilmBalloon", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if not yours.Parent then stopFlag = true return end
		local b = yours:GetPivot().Position
		if not lift and b.Y - home.Y > 0.3 then lift = os.clock() end
		local t = lift and (os.clock() - lift) or 0
		local L = b + Vector3.new(0, 6, 0)   -- the basket and the balloon above it
		local shot, want, look
		if t < 7 then shot = 1; want = grass; look = L   -- liftoff, from the grass
		elseif t < T.rise + T.hover then shot = 2; local a = math.pi + (t - 7) * 0.13; want = L + Vector3.new(math.cos(a) * 36, -2, math.sin(a) * 36); look = L   -- a slow circle, the town behind
		elseif t < T.rise + T.hover + T.gust then shot = 3; want = L - dir * 42 + side * 10 + Vector3.new(0, 10, 0); look = L + dir * 12   -- the chase out to sea
		else shot = 4; local a = (t - T.rise - T.hover - T.gust) * 0.08; want = L + (dir * math.cos(a) + side * math.sin(a)) * 18 + Vector3.new(0, 3, 0); look = L end   -- close, in the storm; the sign comes up on the screen
		if shot ~= lastShot or not pos then pos = want; lookS = look; lastShot = shot
		else pos = pos:Lerp(want, 1 - math.exp(-dt * (shot == 3 and 1.6 or 4))); lookS = lookS:Lerp(look, 1 - math.exp(-dt * 8)) end
		local cam = camera(); cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(pos, lookS); cam.FieldOfView = tour.fov
	end)
	while not stopFlag do
		task.wait(0.1)
		if seated() then unseatAt = nil
		else unseatAt = unseatAt or os.clock(); if os.clock() - unseatAt > 2.2 then break end end   -- set down (or out of the seat): a moment under the black, then back to normal
	end
	RunService:UnbindFromRenderStep("FilmBalloon")
	finish(wasUI)
end

-- ---------- the menu (F8) ----------
menuGui = Instance.new("ScreenGui")
menuGui.Name = "FilmMenu"; menuGui.ResetOnSpawn = false; menuGui.IgnoreGuiInset = true; menuGui.DisplayOrder = 60; menuGui.Enabled = false
menuGui.Parent = pg
local panel = Instance.new("Frame")
panel.Position = UDim2.fromOffset(12, 70); panel.Size = UDim2.fromOffset(250, 0); panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = C(34, 26, 46); panel.BackgroundTransparency = 0.08; panel.BorderSizePixel = 0; panel.Parent = menuGui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 14); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = C(255, 214, 90); ps.Thickness = 2; ps.Parent = panel
local pad = Instance.new("UIPadding"); for _, k in ipairs({"PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"}) do pad[k] = UDim.new(0, 10) end; pad.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 6); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = panel
local order = 0
local clicks = {}                                          -- name -> what the button does (for the test hook below)
local function label(text, size, col)
	order += 1
	local l = Instance.new("TextLabel"); l.LayoutOrder = order; l.Size = UDim2.new(1, 0, 0, 0); l.AutomaticSize = Enum.AutomaticSize.Y
	l.BackgroundTransparency = 1; l.FontFace = FONT; l.TextSize = size; l.TextColor3 = col or C(255, 246, 220); l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left; l.Text = text; l.Parent = panel
	return l
end
local function button(text, onClick, name)
	order += 1
	local b = Instance.new("TextButton"); b.Name = name or ("Btn" .. order); b.LayoutOrder = order; b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = C(255, 202, 62); b.BorderSizePixel = 0; b.AutoButtonColor = true
	b.FontFace = FONT; b.TextSize = 15; b.TextColor3 = C(64, 36, 14); b.Text = text; b.Parent = panel
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 9); c.Parent = b
	b.MouseButton1Click:Connect(function() onClick(b) end)
	clicks[b.Name] = function() onClick(b) end
	return b
end
label("Filming mode  (F8)", 20, C(255, 214, 90))
local nameBtn, uiBtn, speedBtn
nameBtn = button("Hide my name & title", function(b)
	nameHidden = not nameHidden; applyNames()
	b.Text = nameHidden and "Show my name & title" or "Hide my name & title"
end, "NameButton")
uiBtn = button("Hide screen UI", function(b)
	setUIHidden(not uiHidden)
	b.Text = uiHidden and "Show screen UI" or "Hide screen UI"
end, "UIButton")
label("Camera tours - framed for a 9:16 window. F8 stops.", 13)
local whaleBtn
for _, tour in ipairs(Tours) do
	local b = button(tour.name, function()
		task.spawn(function()
			if tour.kind == "whale" then runWhale(tour)
			elseif tour.kind == "drone" then runDrone(tour)
			elseif tour.kind == "balloon" then runBalloon(tour)
			else runTour(tour) end
			uiBtn.Text = uiHidden and "Show screen UI" or "Hide screen UI"
		end)
	end, "Tour_" .. tour.id)
	if tour.kind == "whale" then whaleBtn = b end
end
speedBtn = button("Tour speed: 1x", function(b)
	speed = speed == 1 and 0.75 or (speed == 0.75 and 0.5 or 1)
	b.Text = "Tour speed: " .. tostring(speed) .. "x"
end)
label("Drone: WASD fly, E up, Q down, hold right mouse to look, wheel = speed, Shift = slow.\nRecord: Win+Alt+R.", 12, C(220, 210, 235))
task.spawn(function()                                      -- the whale's countdown on its button
	while true do
		task.wait(0.5)
		if menuGui.Enabled and whaleBtn then
			local d = nextSpout()
			whaleBtn.Text = d == nil and "Whale chase" or (d == 0 and "Whale chase  (spouting now!)" or string.format("Whale chase  (spout in %d:%02d)", math.floor(d / 60), math.floor(d) % 60))
		end
	end
end)
UIS.InputBegan:Connect(function(input, gp)
	if input.KeyCode ~= Enum.KeyCode.F8 then return end
	if running then stopFlag = true return end
	menuGui.Enabled = not menuGui.Enabled
end)
-- a test hook (Studio only): FilmMenu.Press:Fire("Tour_square") presses that button, "stop" stops
if RunService:IsStudio() then
	local press = Instance.new("BindableEvent"); press.Name = "Press"; press.Parent = menuGui
	press.Event:Connect(function(name) if name == "stop" then stopFlag = true elseif clicks[name] then clicks[name]() end end)
end
print("FilmMode: ready - F8 opens the filming menu")

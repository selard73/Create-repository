-- i1 (Shannon approved) install the drivable boat: new folder workspace.Boat (BoatServer, BoatClient, BoatEvent) + the "Take the boat" prompt on River.BoatPreview
local old = workspace:FindFirstChild("Boat"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "Boat"; F:SetAttribute("Built", "i1 2026-09-30")
local ev = Instance.new("RemoteEvent"); ev.Name = "BoatEvent"; ev.Parent = F
local s = Instance.new("Script"); s.Name = "BoatServer"; s.RunContext = Enum.RunContext.Server
s.Source = [=====[-- BoatServer: the 1001 Squirrels motorboat. "Take the boat" at the jetty (after all 44 squirrels in the forest, the Rue
-- and the Chateau), one boat per player, at most MAX_BOATS on the water. The driver's client steers it (BoatClient);
-- this script builds the boat, seats the player, gives them the physics, runs the wake and cleans up.
-- Getting out (jump) puts the player back on the jetty and the boat goes away.
local Players = game:GetService("Players")
local B = script.Parent
local ev = B:WaitForChild("BoatEvent")
local River = workspace:WaitForChild("River")
local preview = River:WaitForChild("BoatPreview")
local visual = preview:FindFirstChildWhichIsA("MeshPart", true)
local prompt = preview:FindFirstChild("BoatPrompt", true)

local NEED = 44
local MAPS = {"forest", "village", "domaine"}      -- fixed: squirrels added on later maps never lock the boat again
local MAX_BOATS = 6
local KEEL_Y = -1.45                                -- keel under WaterY -0.9
local HULL = Vector3.new(3.7, 1.3, 7.4)
local HULL_Y = KEEL_Y + HULL.Y / 2
local JETTY_OUT = Vector3.new(161.9, 0.6 + 3, -164.5)
local SLOTS = {Vector3.new(151.5, 0, -157.5), Vector3.new(151.2, 0, -147.5), Vector3.new(151, 0, -137.5), Vector3.new(151.5, 0, -178), Vector3.new(152.5, 0, -189)}
local BOX = {xmin = 140, xmax = 176, zmin = -210, zmax = -118}
local boats = {}                                    -- player -> model

local function found(p)
	local n = 0
	for _, m in ipairs(MAPS) do n += (p:GetAttribute("Found_" .. m) or 0) end
	return n
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint"); w.Part0 = a; w.Part1 = b; w.Parent = a
end

local function clear(p, putBack)
	local m = boats[p]; boats[p] = nil
	if m then m:Destroy() end
	if putBack then
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			char:PivotTo(CFrame.lookAt(JETTY_OUT, JETTY_OUT + Vector3.new(1, 0, 0)))
		end
	end
end

local function build(p, pos)
	local m = Instance.new("Model"); m.Name = "Boat_" .. p.UserId
	local hull = Instance.new("Part"); hull.Name = "Hull"; hull.Size = HULL; hull.Transparency = 1
	hull.CanCollide = true; hull.CanTouch = false; hull.TopSurface = Enum.SurfaceType.Smooth; hull.BottomSurface = Enum.SurfaceType.Smooth
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.3, 0.2, 1, 1)
	hull.CFrame = CFrame.new(pos.X, HULL_Y, pos.Z)   -- identity = bow downstream (-z), like the moored boat
	hull.Parent = m; m.PrimaryPart = hull
	local vis = visual:Clone(); vis.Name = "Visual"; vis.Anchored = false; vis.CanCollide = false; vis.CanQuery = false; vis.CanTouch = false; vis.Massless = true
	for _, c in ipairs(vis:GetChildren()) do c:Destroy() end
	vis.CFrame = hull.CFrame * CFrame.new(0, (KEEL_Y + vis.Size.Y / 2) - HULL_Y, 0); vis.Parent = m
	weld(hull, vis)
	local seat = Instance.new("VehicleSeat"); seat.Name = "BoatSeat"; seat.Size = Vector3.new(2.2, 0.3, 1.2); seat.Transparency = 1
	seat.CanCollide = false; seat.Massless = true; seat.MaxSpeed = 0; seat.Torque = 0; seat.TurnSpeed = 0; seat.HeadsUpDisplay = false
	seat.CFrame = hull.CFrame * CFrame.new(0, (KEEL_Y + 1.25) - HULL_Y, 0); seat.Parent = m
	weld(hull, seat)
	local a = Instance.new("Attachment"); a.Name = "Drive"; a.Parent = hull
	local lv = Instance.new("LinearVelocity"); lv.Name = "Move"; lv.Attachment0 = a; lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = 4e5; lv.VectorVelocity = Vector3.zero; lv.Parent = hull
	local ao = Instance.new("AlignOrientation"); ao.Name = "Level"; ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Attachment0 = a
	ao.MaxTorque = 4e6; ao.Responsiveness = 18; ao.CFrame = CFrame.new(); ao.Parent = hull
	-- wake: soft white puffs off the stern, rate set from the speed below
	local stern = Instance.new("Attachment"); stern.Name = "Wake"; stern.Position = Vector3.new(0, (-0.8) - HULL_Y, 4.1); stern.Parent = hull
	for i, side in ipairs({-1, 1}) do
		local pe = Instance.new("ParticleEmitter"); pe.Name = "Wake" .. i
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(245, 250, 252))
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1)})
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2.2)})
		pe.Lifetime = NumberRange.new(1.0, 1.5); pe.Speed = NumberRange.new(1.5, 2.5); pe.SpreadAngle = Vector2.new(25, 5)
		pe.EmissionDirection = Enum.NormalId.Back; pe.Drag = 2; pe.Rate = 0; pe.LightInfluence = 0.6
		pe.Acceleration = Vector3.new(side * 1.2, 0, 0); pe.Parent = stern
	end
	m:SetAttribute("Owner", p.UserId)
	m.Parent = B
	return m, seat, hull
end

local function take(p)
	if boats[p] then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) or hum.Health <= 0 then return end
	local n = found(p)
	if n < NEED then
		ev:FireClient(p, "no", string.format("Find all %d squirrels to take the boat out. You have found %d.", NEED, n))
		return
	end
	if (hrp.Position - visual.Position).Magnitude > 16 then return end
	local count = 0
	for _ in pairs(boats) do count += 1 end
	if count >= MAX_BOATS then ev:FireClient(p, "no", "All the boats are out on the river. Try again in a moment."); return end
	local slot
	for _, s in ipairs(SLOTS) do
		local free = true
		for _, m in pairs(boats) do
			if m.PrimaryPart and (m.PrimaryPart.Position * Vector3.new(1, 0, 1) - s).Magnitude < 7.5 then free = false end
		end
		if free then slot = s break end
	end
	if not slot then ev:FireClient(p, "no", "The water by the jetty is busy. Try again in a moment."); return end
	local m, seat, hull = build(p, slot)
	boats[p] = m
	hum.Sit = false
	seat:Sit(hum)
	task.defer(function() pcall(function() hull:SetNetworkOwner(p) end) end)
	ev:FireClient(p, "go")
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant == nil and boats[p] == m then task.wait(0.15); if boats[p] == m then clear(p, true) end end
	end)
	hum.Died:Connect(function() if boats[p] == m then clear(p, false) end end)
end

if prompt then prompt.Triggered:Connect(take) else warn("BoatServer: no BoatPrompt on River.BoatPreview") end
Players.PlayerRemoving:Connect(function(p) clear(p, false) end)
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() if boats[p] then clear(p, false) end end) end)
for _, p in ipairs(Players:GetPlayers()) do p.CharacterAdded:Connect(function() if boats[p] then clear(p, false) end end) end

-- watchdog + wake, 5 times a second
while true do
	task.wait(0.2)
	for p, m in pairs(boats) do
		local hull = m.PrimaryPart
		local seat = m:FindFirstChild("BoatSeat")
		if not (hull and seat) or not seat.Occupant then
			if m:GetAttribute("Empty") then clear(p, true) else m:SetAttribute("Empty", true) end
		else
			m:SetAttribute("Empty", nil)
			local q = hull.Position
			if q.X < BOX.xmin or q.X > BOX.xmax or q.Z < BOX.zmin or q.Z > BOX.zmax or q.Y < -6 or q.Y > 6 then
				clear(p, true)
			else
				local v = hull.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
				local rate = math.clamp((v.Magnitude - 1.5) * 3, 0, 36)
				for _, pe in ipairs(hull.Wake:GetChildren()) do pe.Rate = rate end
			end
		end
	end
end
]=====]
s.Parent = F
local c = Instance.new("Script"); c.Name = "BoatClient"; c.RunContext = Enum.RunContext.Client
c.Source = [=====[-- BoatClient: steers the player's own boat (the server gives the driver the physics), keeps it inside the river,
-- bobs it on the water, and shows the jetty prompt text and the short notes. Runs on every client.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local B = script.Parent
local ev = B:WaitForChild("BoatEvent")
local River = workspace:WaitForChild("River")
local preview = River:WaitForChild("BoatPreview")
local prompt = preview:FindFirstChild("BoatPrompt", true)

local NEED, MAPS = 44, {"forest", "village", "domaine"}
local MAXF, MAXR = 13, 4.5            -- studs/s forward, reverse: gentle
local ACC, DEC = 0.9, 1.6             -- how fast the speed follows the stick
local TURN = 1.05                     -- rad/s at speed
local FLOW = 1.1                      -- the current's nudge downstream
local R = 2.0                         -- the boat as three circles of this radius: bow, middle, stern
local HULL_Y = -1.45 + 0.65
local Z_NORTH, Z_SOUTH = -127 - R, -205 + R + 0.4   -- a few studs short of the bridge; the village rim
-- things the boat must not run into (x/z boxes): the jetty deck and posts, the moored boat
local BLOCKS = {
	{x0 = 159.9, x1 = 164.5, z0 = -168.4, z1 = -145.6},
	{x0 = 155.4, x1 = 159.9, z0 = -171.0, z1 = -162.0},
}

-- the river's centre line, downstream order: "x,z,halfWidth;..."
local pts = {}
for x, z, w in string.gmatch(River:GetAttribute("Line") or "", "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
	table.insert(pts, {x = tonumber(x), z = tonumber(z), w = tonumber(w)})
end
local function nearest(x, z)
	local bd, bw, bnx, bnz, bdx, bdz = math.huge, 8, 0, 0, 0, -1
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local ex, ez = b.x - a.x, b.z - a.z
		local L2 = ex * ex + ez * ez
		local t = math.clamp(((x - a.x) * ex + (z - a.z) * ez) / L2, 0, 1)
		local px, pz = a.x + ex * t, a.z + ez * t
		local dx, dz = x - px, z - pz
		local d = math.sqrt(dx * dx + dz * dz)
		if d < bd then
			local L = math.sqrt(L2)
			bd, bw = d, a.w + (b.w - a.w) * t
			if d > 1e-4 then bnx, bnz = dx / d, dz / d else bnx, bnz = 0, 0 end
			bdx, bdz = ex / L, ez / L
		end
	end
	return bd, bw, bnx, bnz, bdx, bdz
end
-- how far (x, z) a circle at (x, z) has to move to be back where it may be
local function push(x, z)
	local cx, cz = 0, 0
	local d, w, nx, nz = nearest(x, z)
	local lim = w - R - 0.8
	if d > lim then cx -= nx * (d - lim); cz -= nz * (d - lim) end
	if z > Z_NORTH then cz -= z - Z_NORTH end
	if z < Z_SOUTH then cz += Z_SOUTH - z end
	for _, b in ipairs(BLOCKS) do
		local x0, x1, z0, z1 = b.x0 - R, b.x1 + R, b.z0 - R, b.z1 + R
		if x > x0 and x < x1 and z > z0 and z < z1 then
			local best, bx, bz = x - x0, -(x - x0), 0
			if x1 - x < best then best, bx, bz = x1 - x, x1 - x, 0 end
			if z - z0 < best then best, bx, bz = z - z0, 0, -(z - z0) end
			if z1 - z < best then best, bx, bz = z1 - z, 0, z1 - z end
			cx += bx; cz += bz
		end
	end
	return cx, cz
end

-- short notes (the same bottom toast the shops use; fits a phone)
local gui = Instance.new("ScreenGui"); gui.Name = "BoatUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 5; gui.Parent = player:WaitForChild("PlayerGui")
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118)
toast.Size = UDim2.new(0.92, 0, 0, 56); toast.BackgroundColor3 = Color3.fromRGB(58, 36, 16); toast.BackgroundTransparency = 0.1
toast.BorderSizePixel = 0; toast.Font = Enum.Font.FredokaOne; toast.TextSize = 17; toast.TextWrapped = true
toast.TextColor3 = Color3.fromRGB(255, 244, 214); toast.Visible = false; toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)
local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(460, 56); lim.Parent = toast
local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = toast
local shown = 0
local function note(text, secs)
	shown += 1
	local me = shown
	toast.Text = text; toast.Visible = true
	task.delay(secs or 4, function() if shown == me then toast.Visible = false end end)
end
ev.OnClientEvent:Connect(function(what, text)
	if what == "no" then
		note(text, 4.5)
	elseif what == "go" then
		note(UIS.TouchEnabled and "Steer with the thumbstick. Tap jump to get out." or "Steer with W A S D. Press space to get out.", 5)
	end
end)

-- the jetty prompt says what it needs
local function found()
	local n = 0
	for _, m in ipairs(MAPS) do n += (player:GetAttribute("Found_" .. m) or 0) end
	return n
end
local function refreshPrompt()
	if not prompt then return end
	local n = found()
	prompt.ActionText = "Take the boat"
	prompt.ObjectText = n >= NEED and "Bateau" or string.format("Needs all %d squirrels (%d/%d)", NEED, n, NEED)
end
for _, m in ipairs(MAPS) do player:GetAttributeChangedSignal("Found_" .. m):Connect(refreshPrompt) end
refreshPrompt()

-- driving
local speed, yaw = 0, nil
RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not (seat and seat.Name == "BoatSeat") then
		if yaw then speed, yaw = 0, nil; if prompt then prompt.Enabled = true end end
		return
	end
	local hull = seat.Parent and seat.Parent:FindFirstChild("Hull")
	local lv, ao = hull and hull:FindFirstChild("Move"), hull and hull:FindFirstChild("Level")
	if not (lv and ao) then return end
	if not yaw then
		local lk = hull.CFrame.LookVector
		yaw = math.atan2(-lk.X, -lk.Z)
		if prompt then prompt.Enabled = false end
	end
	dt = math.min(dt, 0.1)
	local th, st = seat.ThrottleFloat, seat.SteerFloat
	local target = th > 0 and th * MAXF or th * MAXR
	local rate = math.abs(target) > math.abs(speed) and ACC or DEC
	speed += (target - speed) * math.min(1, rate * dt)
	local turnScale = math.clamp(0.45 + math.abs(speed) / MAXF * 0.7, 0, 1.15)
	yaw -= st * TURN * turnScale * dt * (speed < -0.5 and -1 or 1)
	local rot = CFrame.Angles(0, yaw, 0)
	local fwd = rot.LookVector
	local p = hull.Position
	local _, _, _, _, dx, dz = nearest(p.X, p.Z)
	local v = fwd * speed + Vector3.new(dx, 0, dz) * FLOW
	local cx, cz = 0, 0
	for _, s in ipairs({-2.4, 0, 2.4}) do
		local q = p + fwd * s
		local a, b = push(q.X, q.Z)
		cx += a; cz += b
	end
	if cx ~= 0 or cz ~= 0 then
		local n = Vector3.new(cx, 0, cz)
		local nu = n.Unit
		local into = v:Dot(-nu)
		if into > 0 then v += nu * into end
		v += n * 5
		speed *= 1 - math.min(1, 1.5 * dt)
	end
	local t = os.clock()
	local frac = math.clamp(speed / MAXF, -1, 1)
	local ty = HULL_Y + 0.07 * math.sin(t * 1.7)
	lv.VectorVelocity = Vector3.new(v.X, (ty - p.Y) * 6, v.Z)
	local pitch = 0.018 * math.sin(t * 1.1 + 1) + math.max(frac, 0) * 0.035
	local roll = 0.025 * math.sin(t * 1.3) - st * math.abs(frac) * 0.06
	ao.CFrame = rot * CFrame.Angles(pitch, 0, roll)
end)
]=====]
c.Parent = F
local mp = workspace.River.BoatPreview:FindFirstChildWhichIsA("MeshPart", true)
local oldp = mp:FindFirstChild("PromptSpot"); if oldp then oldp:Destroy() end
local a = Instance.new("Attachment"); a.Name = "PromptSpot"; a.Position = Vector3.new(1.2, 0.6, 0); a.Parent = mp
local p = Instance.new("ProximityPrompt"); p.Name = "BoatPrompt"; p.ActionText = "Take the boat"; p.ObjectText = "Bateau"
p.HoldDuration = 0.35; p.MaxActivationDistance = 8; p.RequiresLineOfSight = false; p.KeyboardKeyCode = Enum.KeyCode.E; p.Parent = a
F.Parent = workspace
print("QQ DONE i1 " .. #s.Source .. " " .. #c.Source)

-- install_boat_i6 v21 (steerable parachute: keys or thumbstick relative to the camera, drift away from the fall, dry-landing note): sets workspace.Boat.BoatServer and
-- workspace.Boat.BoatClient with v2 (tools/boat/BoatServer.server.v2.lua / BoatClient.client.v2.lua): past the brink the boat
-- falls, the passenger is thrown out (parachute if they found the Sky Diving Squirrel), the hull breaks up on the pool, two
-- pieces wash along the shore, a welcome note. Everything else about the boat is unchanged. BoatEvent and the folder stay.
-- The previous sources are kept in ServerStorage.GorgeBackup.BoatScripts_v1 (BoatServer_v1 / BoatClient_v1) the first time.
local B = workspace.Boat
local SS = game:GetService("ServerStorage")
local GB = SS:FindFirstChild("GorgeBackup") or Instance.new("Folder", SS); GB.Name = "GorgeBackup"
local bk = GB:FindFirstChild("BoatScripts_v1")
if not bk then
	bk = Instance.new("Folder"); bk.Name = "BoatScripts_v1"; bk.Parent = GB
	local a = B.BoatServer:Clone(); a.Name = "BoatServer_v1"; a.Disabled = true; a.Parent = bk
	local b = B.BoatClient:Clone(); b.Name = "BoatClient_v1"; b.Disabled = true; b.Parent = bk
end
B.BoatServer.Source = [=====[-- BoatServer: the 1001 Squirrels motorboat. "Take the boat" at the jetty (after all 44 squirrels in the forest, the Rue
-- and the Chateau; the game's owner may always), one boat per player, at most MAX_BOATS on the water. The driver's client
-- steers it (BoatClient); this script builds the boat, seats the player, gives them the physics, runs the wake and cleans up.
-- Getting out (jump) puts the player back on the jetty and the boat goes away.
-- v2 (Oct 1 2026): OVER THE FALLS. Past the brink (z < LIP_Z) the boat stops obeying the stick, tips and falls; a moment
-- later the passenger is thrown out forward and lands in the plunge pool - unless they have found the Sky Diving Squirrel,
-- then a parachute opens and they float down (their client steers it). When the hull hits the pool it breaks into pieces
-- that scatter and float; most fade, a couple survive and wash along the shore as wreckage. A fresh boat waits at the jetty.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
local BOX = {xmin = 130, xmax = 225, zmin = -560, zmax = -118}
local boats = {}                                    -- player -> model
local ENGINE = {vol0 = 0.22, vol1 = 0.5, pitch0 = 1.5, pitch1 = 2.0, top = 13}   -- idle -> full speed
-- the falls
local LIP_Z = -547.5                                -- the brink line (the walls' last column)
local SEA_Y = -52.9                                 -- the plunge pool / harbour water
-- the parachute is lent by the Sky Diving Squirrel (workspace.parachute_squirrel_color) once all 44 are found; see the end
local EJECT_AFTER = 0.25                            -- seconds past the brink before the passenger is thrown out
local MAX_WRECKS = 8

local function found(p)
	local n = 0
	for _, m in ipairs(MAPS) do n += (p:GetAttribute("Found_" .. m) or 0) end
	return n
end
local function hasChute(p)
	return p:GetAttribute("HasChute") == true           -- lent by the Sky Diving Squirrel after all 44; worn until it opens over the falls; never saved
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint"); w.Part0 = a; w.Part1 = b; w.Parent = a
end

-- boats (and their drivers while seated) only bump into other boats: the Baseplate is a union whose rough collision
-- shape bulges out of the channel walls and snagged the hull, so the river's edges are kept by BoatClient instead
local PhysicsService = game:GetService("PhysicsService")
local GROUP = "Boats"
pcall(function() PhysicsService:RegisterCollisionGroup(GROUP) end)
local function isolate()
	for _, g in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
		if g.name ~= GROUP then PhysicsService:CollisionGroupSetCollidable(GROUP, g.name, false) end
	end
end
isolate(); task.delay(10, isolate)
local function riderGroup(char, on)
	if not char then return end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			if on then
				if d:GetAttribute("BoatOldGroup") == nil then d:SetAttribute("BoatOldGroup", d.CollisionGroup) end
				d.CollisionGroup = GROUP
			elseif d:GetAttribute("BoatOldGroup") ~= nil then
				d.CollisionGroup = d:GetAttribute("BoatOldGroup"); d:SetAttribute("BoatOldGroup", nil)
			end
		end
	end
end

local removePack
local function clear(p, putBack)
	local m = boats[p]; boats[p] = nil
	if m then m:Destroy() end
	riderGroup(p.Character, false)
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
	hull.CanCollide = true; hull.CanTouch = false; hull.CollisionGroup = GROUP; hull.TopSurface = Enum.SurfaceType.Smooth; hull.BottomSurface = Enum.SurfaceType.Smooth
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.3, 0.2, 1, 1)
	hull.CFrame = CFrame.new(pos.X, HULL_Y, pos.Z)   -- identity = bow downstream (-z), like the moored boat
	hull.Parent = m; m.PrimaryPart = hull
	local vis = visual:Clone(); vis.Name = "Visual"; vis.Anchored = false; vis.CanCollide = false; vis.CanQuery = false; vis.CanTouch = false; vis.Massless = true
	for _, c in ipairs(vis:GetChildren()) do c:Destroy() end
	vis.CFrame = hull.CFrame * CFrame.new(0, (KEEL_Y + vis.Size.Y / 2) - HULL_Y, 0); vis.Parent = m
	weld(hull, vis)
	-- the bow ring and stern cleat, copied from the moored boat
	local fit = preview:FindFirstChild("Fittings")
	if fit then
		for _, f in ipairs(fit:GetChildren()) do
			if f:IsA("BasePart") then
				local c = f:Clone(); c.Anchored = false; c.Massless = true
				c.CFrame = vis.CFrame * visual.CFrame:ToObjectSpace(f.CFrame); c.Parent = m
				weld(hull, c)
			end
		end
	end
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
	-- engine: Shannon's pick (15067494918, a big diesel), played faster so it sounds like a small outboard;
	-- volume and pitch follow the speed in the loop below. On the hull, so nearby players hear it too.
	local snd = Instance.new("Sound"); snd.Name = "Engine"; snd.SoundId = "rbxassetid://15067494918"; snd.Looped = true
	snd.Volume = ENGINE.vol0; snd.PlaybackSpeed = ENGINE.pitch0
	snd.RollOffMode = Enum.RollOffMode.InverseTapered; snd.RollOffMinDistance = 8; snd.RollOffMaxDistance = 80
	snd.Parent = hull
	snd:Play()
	m:SetAttribute("Owner", p.UserId)
	m.Parent = B
	return m, seat, hull
end

-- ============================================================ over the falls ============================================================
local wreckage = B:FindFirstChild("Wreckage") or Instance.new("Folder"); wreckage.Name = "Wreckage"; wreckage.Parent = B
local rng = Random.new()
local OLIVE, WOOD, DARK = Color3.fromRGB(96, 104, 66), Color3.fromRGB(122, 86, 52), Color3.fromRGB(54, 54, 58)

local function splash(pos)
	local sp = Instance.new("Part"); sp.Name = "Splash"; sp.Size = Vector3.new(6, 1, 6); sp.Transparency = 1; sp.Anchored = true
	sp.CanCollide = false; sp.CanQuery = false; sp.CanTouch = false; sp.CFrame = CFrame.new(pos.X, SEA_Y + 0.3, pos.Z); sp.Parent = B
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(244, 250, 255)); pe.LightEmission = 0.4; pe.LightInfluence = 0.3
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.6, 0.6), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(0.8, 1.5); pe.Speed = NumberRange.new(14, 26); pe.SpreadAngle = Vector2.new(55, 55)
	pe.EmissionDirection = Enum.NormalId.Top; pe.Acceleration = Vector3.new(0, -24, 0); pe.Rate = 0
	pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-40, 40); pe.Parent = sp
	pe:Emit(110)
	task.delay(4, function() sp:Destroy() end)
end

local function piece(cf, size, color, vel, wreck)
	local q = Instance.new("Part"); q.Name = wreck and "Wreck" or "Piece"; q.Size = size; q.Color = color
	q.Material = Enum.Material.Wood; q.CFrame = cf; q.Anchored = false; q.CanCollide = true; q.CanQuery = false; q.CanTouch = false
	q.CustomPhysicalProperties = PhysicalProperties.new(0.45, 0.6, 0.1, 1, 1)
	q.AssemblyLinearVelocity = vel
	q.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8))
	q.Parent = wreck and wreckage or B
	return q
end

local function breakUp(hull)
	local hcf, hv = hull.CFrame, hull.AssemblyLinearVelocity
	local base = Vector3.new(hv.X, 0, hv.Z) * 0.3
	splash(hcf.Position)
	local pieces = {}
	-- planks from the hull, the bench, the motor
	for i = 1, 14 do
		local off = CFrame.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(-0.3, 0.6), rng:NextNumber(-3.4, 3.4)) * CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(-3, 3), rng:NextNumber(-1, 1))
		local size = Vector3.new(rng:NextNumber(0.5, 1.4), 0.25, rng:NextNumber(1.6, 3.2))
		local vel = base + Vector3.new(rng:NextNumber(-13, 13), rng:NextNumber(9, 24), rng:NextNumber(-13, 13))
		pieces[#pieces + 1] = piece(hcf * off, size, OLIVE, vel, false)
	end
	for i = 1, 3 do
		local off = CFrame.new(rng:NextNumber(-1, 1), 0.6, rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(0, rng:NextNumber(-3, 3), 0)
		pieces[#pieces + 1] = piece(hcf * off, Vector3.new(rng:NextNumber(0.8, 1.6), 0.25, 0.9), WOOD, base + Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(8, 20), rng:NextNumber(-10, 10)), false)
	end
	pieces[#pieces + 1] = piece(hcf * CFrame.new(0, 0.4, 3.2), Vector3.new(1.0, 1.1, 0.8), DARK, base + Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(6, 14), rng:NextNumber(-8, 4)), false)
	-- two pieces survive: they drift along the shore, then stay as wreckage
	local keep = {}
	for i = 1, 2 do
		local off = CFrame.new(rng:NextNumber(-1.4, 1.4), 0.3, rng:NextNumber(-2.5, 2.5)) * CFrame.Angles(0, rng:NextNumber(-3, 3), rng:NextNumber(-0.3, 0.3))
		keep[i] = piece(hcf * off, Vector3.new(rng:NextNumber(1.2, 1.8), 0.3, rng:NextNumber(2.6, 3.6)), OLIVE, base + Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(8, 16), rng:NextNumber(-8, 8)), true)
	end
	-- after the scatter the pieces settle: anchored at the water line with a small tilt, no physics jitter
	local function settle(q, yaw)
		if not q.Parent then return end
		local p = q.Position
		q.Anchored = true; q.CanCollide = false
		q.CFrame = CFrame.new(p.X, SEA_Y + 0.12, p.Z) * CFrame.Angles(math.rad(rng:NextNumber(-7, 7)), yaw, math.rad(rng:NextNumber(-7, 7)))
	end
	task.delay(2.2, function()
		for _, q in ipairs(pieces) do settle(q, rng:NextNumber(0, 2 * math.pi)) end
		for _, q in ipairs(keep) do settle(q, rng:NextNumber(0, 2 * math.pi)) end
	end)
	-- the rest fade after a while
	task.delay(11, function()
		for _, q in ipairs(pieces) do
			if q.Parent then
				TweenService:Create(q, TweenInfo.new(3), {Transparency = 1}):Play()
				task.delay(3.2, function() q:Destroy() end)
			end
		end
	end)
	-- the survivors wash slowly east along the cove shore (a smooth tween, easing out), then rest there
	task.delay(3.5, function()
		for i, q in ipairs(keep) do
			if q.Parent then
				local p = q.Position
				local dest = CFrame.new(p.X + rng:NextNumber(22, 34), SEA_Y + 0.12, p.Z - rng:NextNumber(4, 12)) * CFrame.Angles(math.rad(rng:NextNumber(-6, 6)), rng:NextNumber(0, 2 * math.pi), math.rad(rng:NextNumber(-6, 6)))
				TweenService:Create(q, TweenInfo.new(28 + i * 4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = dest}):Play()
			end
		end
	end)
	-- never more than MAX_WRECKS pieces of wreckage on the shore
	local wrecks = wreckage:GetChildren()
	if #wrecks > MAX_WRECKS then
		table.sort(wrecks, function(a, b) return (a:GetAttribute("Born") or 0) < (b:GetAttribute("Born") or 0) end)
		for i = 1, #wrecks - MAX_WRECKS do wrecks[i]:Destroy() end
	end
	for _, q in ipairs(keep) do q:SetAttribute("Born", os.time()) end
end

-- the parachute: a small striped pack on the back while it is packed, a stylized rainbow canopy when it opens
local RAINBOW = {Color3.fromRGB(235, 60, 60), Color3.fromRGB(245, 140, 40), Color3.fromRGB(250, 220, 60), Color3.fromRGB(90, 200, 90), Color3.fromRGB(70, 140, 235), Color3.fromRGB(100, 80, 200), Color3.fromRGB(190, 90, 210), Color3.fromRGB(240, 120, 170)}
local function deco(name, size, color)
	local q = Instance.new("Part"); q.Name = name; q.Size = size; q.Color = color; q.Material = Enum.Material.SmoothPlastic
	q.Massless = true; q.CanCollide = false; q.CanQuery = false; q.CanTouch = false; q.CastShadow = true
	return q
end
local function torsoOf(char)
	return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
end
local function attachPack(char)
	local torso = torsoOf(char)
	if not torso or char:FindFirstChild("ChutePack") then return end
	local m = Instance.new("Model"); m.Name = "ChutePack"
	local base = torso.CFrame * CFrame.new(0, 0.15, 0.78)
	local pack = deco("Pack", Vector3.new(1.5, 1.7, 0.6), Color3.fromRGB(112, 104, 72)); pack.Material = Enum.Material.Fabric; pack.CFrame = base; pack.Parent = m; weld(torso, pack)
	local flap = deco("Flap", Vector3.new(1.55, 0.7, 0.66), Color3.fromRGB(96, 88, 60)); flap.Material = Enum.Material.Fabric
	flap.CFrame = base * CFrame.new(0, 0.5, 0.03); flap.Parent = m; weld(torso, flap)
	local buckle = deco("Buckle", Vector3.new(0.3, 0.2, 0.08), Color3.fromRGB(190, 170, 110))
	buckle.CFrame = base * CFrame.new(0, 0.1, 0.34); buckle.Parent = m; weld(torso, buckle)
	for _, sx in ipairs({-0.5, 0.5}) do
		local strap = deco("Strap", Vector3.new(0.25, 1.4, 0.12), Color3.fromRGB(50, 50, 48))
		strap.CFrame = torso.CFrame * CFrame.new(sx, 0.2, 0.2); strap.Parent = m; weld(torso, strap)
	end
	m.Parent = char
end
removePack = function(char)
	local m = char and char:FindFirstChild("ChutePack"); if m then m:Destroy() end
end
local function attachChute(char)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or char:FindFirstChild("Parachute") then return end
	removePack(char)
	local m = Instance.new("Model"); m.Name = "Parachute"
	-- the canopy: the imported rainbow-gore dome mesh (ServerStorage.ChuteKit.ChuteCanopy, italy/chute/chute_canopy.obj) when it
	-- is there; eight ellipsoid petals as the fallback
	local R, H = 5.4, 4.6                                             -- rim radius, dome height
	local rimY = hrp.CFrame.Position.Y + 6.2
	local cx, cz = hrp.CFrame.Position.X, hrp.CFrame.Position.Z
	local crown = Vector3.new(cx, rimY + H, cz)
	local kit = game:GetService("ServerStorage"):FindFirstChild("ChuteKit")
	local tmpl = kit and kit:FindFirstChild("ChuteCanopy")
	if tmpl then
		local dome = tmpl:Clone(); dome.Name = "Canopy"
		dome.Size = Vector3.new(2 * R, H, 2 * R); dome.Anchored = false; dome.Massless = true; dome.CanCollide = false; dome.CanQuery = false; dome.CanTouch = false
		dome.Transparency = 0; dome.CastShadow = true
		dome.CFrame = CFrame.new(cx, rimY + H / 2, cz); dome.Parent = m; weld(hrp, dome)
	else
		local N = 8
		for i = 1, N do
			local ang = (i - 1) / N * 2 * math.pi
			local rimPt = Vector3.new(cx + math.cos(ang) * R, rimY, cz + math.sin(ang) * R)
			local mid = crown:Lerp(rimPt, 0.56)
			local petal = deco("Gore" .. i, Vector3.new(4.8, 2.7, 6.6), RAINBOW[((i - 1) % #RAINBOW) + 1]); petal.Shape = Enum.PartType.Ball
			petal.CFrame = CFrame.lookAt(mid, rimPt); petal.Parent = m; weld(hrp, petal)
		end
		local cap = deco("Crown", Vector3.new(2.2, 1.6, 2.2), Color3.fromRGB(252, 240, 210)); cap.Shape = Enum.PartType.Ball
		cap.CFrame = CFrame.new(crown + Vector3.new(0, -0.3, 0)); cap.Parent = m; weld(hrp, cap)
	end
	local top = crown	-- lines from the rim to the shoulders
	for i = 1, 8 do
		local ang = (i - 1) / 8 * 2 * math.pi
		local a = Vector3.new(cx + math.cos(ang) * R, rimY, cz + math.sin(ang) * R)
		local b = hrp.CFrame.Position + Vector3.new(math.cos(ang) * 0.6, 1.3, math.sin(ang) * 0.6)
		local L = (a - b).Magnitude
		local line = deco("Line" .. i, Vector3.new(0.08, 0.08, L), Color3.fromRGB(245, 245, 240))
		line.CFrame = CFrame.lookAt((a + b) / 2, a); line.Parent = m; weld(hrp, line)
	end
	m.Parent = char
	task.delay(30, function() if m.Parent then m:Destroy() end end)
end
local function startFall(p, m)
	if m:GetAttribute("Falling") then return end
	m:SetAttribute("Falling", true)
	local hull = m.PrimaryPart
	local seat = m:FindFirstChild("BoatSeat")
	if not hull then clear(p, false); return end
	local lv, ao = hull:FindFirstChild("Move"), hull:FindFirstChild("Level")
	if lv then lv.Enabled = false end
	if ao then ao.Enabled = false end
	pcall(function() hull:SetNetworkOwner(nil) end)              -- the server flies it now; the fall and the impact are exact
	-- it shoots off the edge: forward with a touch of lift, then gravity arcs it down into the pool; the bow dips as it goes
	local fwd0 = hull.CFrame.LookVector
	hull.AssemblyLinearVelocity = Vector3.new(fwd0.X, 0, fwd0.Z).Unit * 18 + Vector3.new(0, 3, 0)
	hull.AssemblyAngularVelocity = Vector3.new(0.5, 0, 0)
	-- the fall is slowed so it can be watched: a lift force carries most of the hull's weight (about 1.5 s in the air)
	local drive = hull:FindFirstChild("Drive")
	if drive then
		local lift = Instance.new("VectorForce"); lift.Name = "Lift"; lift.Attachment0 = drive; lift.RelativeTo = Enum.ActuatorRelativeTo.World
		lift.ApplyAtCenterOfMass = true; lift.Force = Vector3.new(0, hull.Mass * workspace.Gravity * 0.84, 0); lift.Parent = hull   -- the hull's own mass: the seated passenger must not count, or the empty boat floats up
	end
	local snd = hull:FindFirstChild("Engine"); if snd then snd:Stop() end
	for _, pe in ipairs(hull.Wake:GetChildren()) do pe.Rate = 0 end
	-- a moment later: out you go (with or without the chute)
	task.delay(EJECT_AFTER, function()
		local hum = seat and seat.Occupant
		local char = hum and hum.Parent
		if hum and char and char:FindFirstChild("HumanoidRootPart") then
			local chute = hasChute(p)
			if chute then p:SetAttribute("HasChute", nil) end        -- used up
			riderGroup(char, false)
			hum.Sit = false
			local fwd = hull.CFrame.LookVector
			local vel = Vector3.new(fwd.X, 0, fwd.Z).Unit * 36 + Vector3.new(0, 14, 0) + Vector3.new(hull.AssemblyLinearVelocity.X, 0, hull.AssemblyLinearVelocity.Z) * 0.5   -- lands ~30 studs out in the pool, clear of the mist
			ev:FireClient(p, "eject", {vel = vel, chute = chute, seaY = SEA_Y})
			if chute then task.delay(0.2, function() if char.Parent then attachChute(char) end end) end
		end
	end)
	-- the impact
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not hull.Parent or boats[p] ~= m then conn:Disconnect(); return end
		local lf = hull:FindFirstChild("Lift")
		if lf then lf.Force = Vector3.new(0, math.min(hull.AssemblyMass, hull.Mass) * workspace.Gravity * 0.84, 0) end
		if hull.Position.Y <= SEA_Y + 0.6 then
			conn:Disconnect()
			breakUp(hull)
			clear(p, false)
		end
	end)
	task.delay(12, function() if conn.Connected then conn:Disconnect(); if boats[p] == m then clear(p, false) end end end)
end

ev.OnServerEvent:Connect(function(p, what)
	if what == "landed" then
		local char = p.Character
		local chute = char and char:FindFirstChild("Parachute")
		if chute then chute:Destroy() end
	end
end)

local function take(p)
	if boats[p] then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) or hum.Health <= 0 then return end
	local n = found(p)
	if n < NEED and p.UserId ~= game.CreatorId then
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
	-- move the player into the boat first: seating them from the jetty dragged the boat onto the jetty
	char:PivotTo(seat.CFrame * CFrame.new(0, 2.6, 0))
	riderGroup(char, true)
	pcall(function() hull:SetNetworkOwner(p) end)
	seat:Sit(hum)
	if hasChute(p) then attachPack(char) end
	ev:FireClient(p, "go")
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant == nil and boats[p] == m and not m:GetAttribute("Falling") then task.wait(0.15); if boats[p] == m and not m:GetAttribute("Falling") then clear(p, true) end end
	end)
	hum.Died:Connect(function() if boats[p] == m then clear(p, false) end end)
end

if prompt then prompt.Triggered:Connect(take) else warn("BoatServer: no BoatPrompt on River.BoatPreview") end

-- ============================================================ the Sky Diving Squirrel lends the parachute ============================================================
local CHUTE_LINES = {"All 44 found! Take my spare chute.", "I packed it myself, so it will probably open.", "The river ends in a big drop... you will want it."}
local CHUTE_NO = "Find all %d squirrels first (%d so far), then come and see me about the falls!"
local CHUTE_AGAIN = "You already have my chute on your back. Go on, the falls are waiting!"
local sq = workspace:FindFirstChild("parachute_squirrel_color")
local sqMesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if sqMesh then
	local sp = sqMesh:FindFirstChild("ChutePrompt") or Instance.new("ProximityPrompt")
	sp.Name = "ChutePrompt"; sp.ObjectText = "Sky Diving Squirrel"; sp.ActionText = "Talk"; sp.HoldDuration = 0.3
	sp.MaxActivationDistance = 10; sp.RequiresLineOfSight = false; sp.KeyboardKeyCode = Enum.KeyCode.E; sp.Parent = sqMesh
	local noise = sqMesh:FindFirstChild("Chitter") or Instance.new("Sound")
	local scripts = workspace:FindFirstChild("SquirrelScripts")
	noise.Name = "Chitter"; noise.SoundId = (scripts and scripts:GetAttribute("FoundSound")) or "rbxassetid://1845415163"
	noise.Volume = 0.8; noise.RollOffMaxDistance = 60; noise.Parent = sqMesh
	sp.Triggered:Connect(function(p)
		local n = found(p)
		-- he speaks the way every squirrel speaks: the bubble over him, with one of her squirrel sounds (BoatClient draws it)
		if n < NEED and p.UserId ~= game.CreatorId then ev:FireClient(p, "squirrelsay", {string.format(CHUTE_NO, NEED, n)}); return end
		if hasChute(p) then ev:FireClient(p, "squirrelsay", {CHUTE_AGAIN}); return end
		p:SetAttribute("HasChute", true)
		if p.Character then attachPack(p.Character) end
		ev:FireClient(p, "squirrelsay", CHUTE_LINES)
	end)
else
	warn("BoatServer: parachute_squirrel_color not found; no chute to lend")
end
-- the note board on the jetty, read before you take the boat
do
	local jetty = River:FindFirstChild("Jetty")
	if jetty and not jetty:FindFirstChild("ChuteNote") then
		local board = Instance.new("Part"); board.Name = "ChuteNote"; board.Size = Vector3.new(0.25, 2.4, 3.6)
		board.Color = Color3.fromRGB(118, 84, 52); board.Material = Enum.Material.Wood; board.Anchored = true; board.CanCollide = false
		board.CFrame = CFrame.new(163.75, 4.4, -150.0)             -- on the jetty's street side, facing the street (+x), before the deck
		local post = Instance.new("Part"); post.Name = "Post"; post.Size = Vector3.new(0.3, 3.8, 0.3); post.Color = Color3.fromRGB(96, 68, 42)
		post.Material = Enum.Material.Wood; post.Anchored = true; post.CanCollide = false; post.CFrame = CFrame.new(163.75, 2.4, -150.0); post.Parent = board
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Right; gui.CanvasSize = Vector2.new(540, 360); gui.LightInfluence = 0.6; gui.Parent = board
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -36, 1, -30); t.Position = UDim2.new(0, 18, 0, 15); t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.TextWrapped = true; t.TextColor3 = Color3.fromRGB(255, 244, 214)
		t.Text = "Sailing to Italy? The river ends in a WATERFALL!\nSquirrels who have found all 44 can borrow a parachute from the Sky Diving Squirrel in the forest. Ask him first!"
		t.Parent = gui
		board.Parent = jetty
	end
end
Players.PlayerRemoving:Connect(function(p) clear(p, false) end)
local function onCharacter(p, char)
	if boats[p] then clear(p, false) end
	if hasChute(p) then task.delay(1, function() if char.Parent then attachPack(char) end end) end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(char) onCharacter(p, char) end) end)
for _, p in ipairs(Players:GetPlayers()) do p.CharacterAdded:Connect(function(char) onCharacter(p, char) end) end

-- watchdog + wake, 5 times a second
while true do
	task.wait(0.2)
	for p, m in pairs(boats) do
		local hull = m.PrimaryPart
		local seat = m:FindFirstChild("BoatSeat")
		if m:GetAttribute("Falling") then
			-- the fall is handled above
		elseif not (hull and seat) or not seat.Occupant then
			if m:GetAttribute("Empty") then clear(p, true) else m:SetAttribute("Empty", true) end
		else
			m:SetAttribute("Empty", nil)
			local q = hull.Position
			if q.Z < LIP_Z then
				startFall(p, m)
			elseif q.X < BOX.xmin or q.X > BOX.xmax or q.Z < BOX.zmin or q.Z > BOX.zmax or q.Y < -6 or q.Y > 6 then
				clear(p, true)
			else
				local v = hull.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
				local rate = math.clamp((v.Magnitude - 1.5) * 3, 0, 36)
				for _, pe in ipairs(hull.Wake:GetChildren()) do pe.Rate = rate end
				local snd = hull:FindFirstChild("Engine")
				if snd then
					local f = math.clamp(v.Magnitude / ENGINE.top, 0, 1)
					snd.Volume += ((ENGINE.vol0 + (ENGINE.vol1 - ENGINE.vol0) * f) - snd.Volume) * 0.5
					snd.PlaybackSpeed += ((ENGINE.pitch0 + (ENGINE.pitch1 - ENGINE.pitch0) * f) - snd.PlaybackSpeed) * 0.5
				end
			end
		end
	end
end
]=====]
B.BoatClient.Source = [=====[-- BoatClient: steers the player's own boat (the server gives the driver the physics), keeps it inside the river,
-- bobs it on the water, and shows the jetty prompt text and the short notes. Runs on every client.
-- v2 (Oct 1 2026): over the falls. Past the brink the server flags the boat Falling and this script lets go of it; on the
-- server's "eject" it throws the character out, and if they carry the parachute (the Sky Diving Squirrel) it flies the
-- descent: steerable with the stick or the keys, sinking gently, until the water or the shore. Then a short welcome note.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local B = script.Parent
local ev = B:WaitForChild("BoatEvent")
local River = workspace:WaitForChild("River")
local preview = River:WaitForChild("BoatPreview")
-- the moored boat streams in late when the player starts far away, so look the prompt up whenever it's needed
local function getPrompt() return preview:FindFirstChild("BoatPrompt", true) end

local NEED, MAPS = 44, {"forest", "village", "domaine"}
local MAXF, MAXR = 13, 4.5            -- studs/s forward, reverse: gentle
local ACC, DEC = 0.9, 1.6             -- how fast the speed follows the stick
local TURN = 1.05                     -- rad/s at speed
local FLOW = 1.1                      -- the current's nudge downstream
local R = 2.0                         -- the boat as three circles of this radius: bow, middle, stern
local HULL_Y = -1.45 + 0.65
local Z_NORTH, Z_SOUTH = -127 - R, -620           -- the bridge; past the brink the server takes over
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
	local lim = w - R - 1.3
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
-- over the falls: the camera. The moment the boat crosses the brink the camera cuts to a fixed spot out over the pool,
-- west of the fall and below the lip, and keeps the boat and the passenger in frame until a little after the landing.
local CINE_OFFSET = Vector3.new(-32, 10, -16)   -- a close tracking shot: west of the action, a little above, out over the pool
local cine = nil
local function startCinematic(watch)
	if cine then return end
	local cam = workspace.CurrentCamera
	cine = {cam = cam, conn = nil}
	cam.CameraType = Enum.CameraType.Scriptable
	local pos = nil
	cine.conn = RunService.RenderStepped:Connect(function(dt)
		local target = watch()
		if not target then return end
		local want = target + CINE_OFFSET
		pos = pos and pos:Lerp(want, math.min(1, dt * 4)) or want
		cam.CFrame = CFrame.lookAt(pos, target)
		-- widen the view while the boat and the passenger are far apart, so both stay in frame
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local m = workspace.Boat:FindFirstChild("Boat_" .. player.UserId)
		local hull = m and m:FindFirstChild("Hull")
		local sep = (hrp and hull) and (hull.Position - hrp.Position).Magnitude or 0
		cam.FieldOfView = math.clamp(70 + sep * 0.7, 70, 100)
	end)
	task.delay(35, function() if cine and cine.cam == cam then cine.conn:Disconnect(); cam.CameraType = Enum.CameraType.Custom; cam.FieldOfView = 70; cine = nil end end)
end
local function endCinematic(after)
	task.delay(after or 0, function()
		if not cine then return end
		cine.conn:Disconnect()
		cine.cam.CameraType = Enum.CameraType.Custom
		cine.cam.FieldOfView = 70
		cine = nil
	end)
end
local function watchMe()
	return function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local m = workspace.Boat:FindFirstChild("Boat_" .. player.UserId)
		local hull = m and m:FindFirstChild("Hull")
		if hull and (hull.Position - hrp.Position).Magnitude < 40 then
			return hrp.Position + (hull.Position - hrp.Position) * 0.5    -- between them while they are close; the view widens with the gap
		end
		return hrp.Position
	end
end
player.CharacterAdded:Connect(function() endCinematic(0) end)
-- over the falls: the throw, the parachute flight, the welcome
local SEA_Y = -52.9
local flying = false
local function landedNote(dry)
	note(dry and "Dry feet! Welcome to Porto Nocciola!" or "Welcome to Porto Nocciola!", 5)
end
-- the parachute is steerable: the keys or the thumbstick, relative to the camera (left on the screen is left in the
-- air), on top of a gentle drift away from the fall and a slow sink. STEER studs/s of steering, DRIFT of drift, SINK down.
local STEER, DRIFT, SINK = 12, 4.5, 6.0
local controls = nil
pcall(function() controls = require(player:WaitForChild("PlayerScripts", 5):WaitForChild("PlayerModule", 5)):GetControls() end)
local function steerInput(hum)
	local cam = workspace.CurrentCamera
	local mv = nil
	if controls then
		local ok, v = pcall(function() return controls:GetMoveVector() end)
		if ok and typeof(v) == "Vector3" then mv = v end
	end
	if mv and cam and mv.Magnitude > 0.05 then
		local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local right = look:Cross(Vector3.yAxis)
		local w = right * mv.X - look * mv.Z               -- the move vector: x right, -z forward
		return w.Magnitude > 1 and w.Unit or w
	end
	local md = hum.MoveDirection                           -- fallback: the humanoid's own (camera-relative) move direction
	return Vector3.new(md.X, 0, md.Z)
end
local function flyChute(char, hum, hrp)
	flying = true
	hum.PlatformStand = true
	local v0 = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(v0.X * 0.3, -3, v0.Z * 0.3)
	local fwd = Vector3.new(v0.X, 0, v0.Z)
	fwd = fwd.Magnitude > 0.5 and fwd.Unit or Vector3.new(0, 0, -1)       -- the throw's direction: away from the fall
	local horiz = fwd * DRIFT
	note(UIS.TouchEnabled and "Steer with the thumbstick to reach the shore." or "Steer with W A S D to reach the shore.", 3.5)
	-- landing = terrain (the pool's water, the beaches) or the lip rocks; never the falling boat or its pieces
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.IgnoreWater = false
	rp.FilterDescendantsInstances = {workspace.Terrain, workspace:FindFirstChild("SouthGorge") and workspace.SouthGorge:FindFirstChild("LipRocks") or workspace.Terrain}
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not (hrp.Parent and hum.Parent and hum.Health > 0) then conn:Disconnect(); flying = false; return end
		local want = fwd * DRIFT + steerInput(hum) * STEER
		horiz = horiz:Lerp(want, math.min(1, dt * 3))                      -- the canopy answers the stick with a little lag
		hrp.AssemblyLinearVelocity = Vector3.new(horiz.X, -SINK, horiz.Z)
		hrp.AssemblyAngularVelocity = Vector3.zero
		if horiz.Magnitude > 0.5 then
			local look = CFrame.lookAt(hrp.Position, hrp.Position + horiz)
			hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position) * look.Rotation, math.min(1, dt * 4))
		end
		local hit = (os.clock() - t0 > 0.5) and workspace:Raycast(hrp.Position, Vector3.new(0, -4.2, 0), rp) or nil
		local down = hit ~= nil or hrp.Position.Y < SEA_Y + 1.2 or os.clock() - t0 > 40
		if down then
			conn:Disconnect(); flying = false
			hum.PlatformStand = false
			local water = (hit and hit.Material == Enum.Material.Water) or hrp.Position.Y < SEA_Y + 1.2
			if not water then hrp.AssemblyLinearVelocity = Vector3.new(horiz.X * 0.3, -2, horiz.Z * 0.3) end
			hum:ChangeState(water and Enum.HumanoidStateType.Swimming or Enum.HumanoidStateType.Landed)
			ev:FireServer("landed")
			task.delay(0.6, function() landedNote(not water) end)
			endCinematic(2.5)
		end
	end)
end
local function onEject(info)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return end
	task.wait(0.1)                                              -- the seat lets go first
	hum.Sit = false
	hrp.AssemblyLinearVelocity = info.vel or Vector3.new(0, 10, -20)
	if info.chute then
		task.wait(0.15)                                          -- a moment of free fall, then the chute opens (a 52-stud drop takes 0.73 s)
		if hum.Parent and hum.Health > 0 then flyChute(char, hum, hrp) end
	else
		-- free fall into the pool: the note when they are in the water
		local t0 = os.clock()
		repeat task.wait(0.2) until not hum.Parent or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Swimming or hrp.Position.Y < SEA_Y + 1 or os.clock() - t0 > 8
		if hum.Parent and hum.Health > 0 then task.delay(0.8, landedNote) end
		endCinematic(2.5)
	end
end

-- the Sky Diving Squirrel speaks the way every squirrel speaks: the chase squirrels' bubble over him (Baguette.ChaseClient
-- speak(), copied) with one of Shannon's squirrel sounds from the Lagoon's SpeechSounds; a long line comes as several bubbles
local NAVY, CREAM, FONT = Color3.fromRGB(38, 30, 52), Color3.fromRGB(255, 246, 220), Enum.Font.FredokaOne
local sqBubble = nil
local function squirrelBubble(model, text, secs, withSound)
	local anchor = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	if not (anchor and text) then return end
	if sqBubble and sqBubble.Parent then sqBubble:Destroy() end
	local bb = Instance.new("BillboardGui"); bb.Name = "ChaseBubble"; bb.Size = UDim2.fromOffset(240, 60); bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.MaxDistance = 80; bb.Adornee = anchor; bb.AlwaysOnTop = true
	local f = Instance.new("TextLabel"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = NAVY; f.BackgroundTransparency = 0.1
	f.Font = FONT; f.TextScaled = true; f.TextColor3 = CREAM; f.Text = text; f.Parent = bb
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 14); cr.Parent = f
	local pd = Instance.new("UIPadding"); pd.PaddingLeft = UDim.new(0, 10); pd.PaddingRight = UDim.new(0, 10); pd.PaddingTop = UDim.new(0, 6); pd.PaddingBottom = UDim.new(0, 6); pd.Parent = f
	bb.Parent = player:WaitForChild("PlayerGui")
	sqBubble = bb
	if withSound then
		local lag = workspace:FindFirstChild("Lagoon")
		local ids = {}
		for d in tostring(lag and lag:GetAttribute("SpeechSounds") or "73324775979494, 90860503936571, 9119556839"):gmatch("%d+") do table.insert(ids, d) end
		if #ids > 0 then
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. ids[math.random(#ids)]; s.Volume = 0.9
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 80; s.Parent = anchor
			s:Play(); game:GetService("Debris"):AddItem(s, 8)
			task.delay((lag and lag:GetAttribute("SpeechMax")) or 4, function()
				if s.Parent and s.IsPlaying then game:GetService("TweenService"):Create(s, TweenInfo.new(0.5), {Volume = 0}):Play() end
			end)
		end
	end
	task.delay(secs or 3.5, function() if bb.Parent then bb:Destroy() end end)
end
local function squirrelSay(lines)
	local sq = workspace:FindFirstChild("parachute_squirrel_color")
	if not sq then return end
	task.spawn(function()
		for i, line in ipairs(lines) do
			squirrelBubble(sq, line, 3.5, i == 1)
			task.wait(3.6)
		end
	end)
end
ev.OnClientEvent:Connect(function(what, text)
	if what == "no" then
		note(text, 4.5)
	elseif what == "go" then
		note(UIS.TouchEnabled and "Steer with the thumbstick. Tap jump to get out." or "Steer with W A S D. Press space to get out.", 5)
	elseif what == "note" then
		note(text, #text > 90 and 7 or 4.5)
	elseif what == "squirrelsay" then
		squirrelSay(type(text) == "table" and text or {tostring(text)})
	elseif what == "eject" then
		task.spawn(onEject, text)
	end
end)

-- the jetty prompt says what it needs
local function found()
	local n = 0
	for _, m in ipairs(MAPS) do n += (player:GetAttribute("Found_" .. m) or 0) end
	return n
end
local function refreshPrompt()
	local prompt = getPrompt()
	if not prompt then return end
	local n = found()
	prompt.ActionText = "Take the boat"
	prompt.ObjectText = (n >= NEED or player.UserId == game.CreatorId) and "Bateau" or string.format("Needs all %d squirrels (%d/%d)", NEED, n, NEED)
end
-- the Sky Diving Squirrel's prompt says what it needs, for this player
local function refreshChutePrompt()
	local sq = workspace:FindFirstChild("parachute_squirrel_color")
	local sp = sq and sq:FindFirstChild("ChutePrompt", true)
	if not sp then return end
	local n = found()
	sp.ActionText = (n >= NEED or player.UserId == game.CreatorId) and "Talk" or string.format("Talk (needs all %d, %d/%d)", NEED, n, NEED)
end
for _, m in ipairs(MAPS) do player:GetAttributeChangedSignal("Found_" .. m):Connect(refreshChutePrompt) end
task.delay(3, refreshChutePrompt)
workspace.DescendantAdded:Connect(function(d) if d.Name == "ChutePrompt" then task.delay(0.5, refreshChutePrompt) end end)
for _, m in ipairs(MAPS) do player:GetAttributeChangedSignal("Found_" .. m):Connect(refreshPrompt) end
preview.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then refreshPrompt() end end)
refreshPrompt()
local function showPrompt(on)
	local prompt = getPrompt()
	if prompt then prompt.Enabled = on end
end

-- driving
local speed, yaw = 0, nil
RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not (seat and seat.Name == "BoatSeat") then
		if yaw then speed, yaw = 0, nil; showPrompt(true) end
		return
	end
	local hull = seat.Parent and seat.Parent:FindFirstChild("Hull")
	local lv, ao = hull and hull:FindFirstChild("Move"), hull and hull:FindFirstChild("Level")
	if not (lv and ao) then return end
	if seat.Parent:GetAttribute("Falling") then startCinematic(watchMe()); return end        -- over the brink: the server flies it, the stick is dead; the camera cuts to the pool
	if not yaw then
		local lk = hull.CFrame.LookVector
		yaw = math.atan2(-lk.X, -lk.Z)
		showPrompt(false)
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
B:SetAttribute("Built", "i6 2026-10-01 over the falls v21")
local ns, nc = 0, 0
for _ in (B.BoatServer.Source .. "\n"):gmatch("(.-)\n") do ns += 1 end
for _ in (B.BoatClient.Source .. "\n"):gmatch("(.-)\n") do nc += 1 end
print(string.format("QQ I6 v21 installed: BoatServer %d lines, BoatClient %d lines; backup %s", ns, nc, bk:GetFullName()))
print("QQ I6 DONE")
-- install_give44 v1: puts a TEST-ONLY server script in ServerScriptService that, in Studio play tests only, gives every
-- player all 44 squirrel finds (as the attributes the game reads). Delete the script before publishing; it is also inert
-- outside Studio. Re-running replaces it. tools/boat/remove_give44.lua takes it out.
local SSS = game:GetService("ServerScriptService")
local NAME = "ZZ_TEST_Give44_DELETE_BEFORE_PUBLISH"
local old = SSS:FindFirstChild(NAME); if old then old:Destroy() end
local s = Instance.new("Script")
s.Name = NAME
s.Source = [=====[-- ZZ_TEST_Give44 (TEST ONLY - delete this script before publishing; it also does nothing outside Studio).
-- In Studio play tests it gives every player all 44 squirrel finds as the attributes the game reads (Found_forest,
-- Found_village, Found_domaine, FoundIds, SquirrelsFound), so the gates, the shop, the boat and the Sky Diving Squirrel
-- treat them as finished. It never touches the DataStore or SquirrelSetup's own list, and it puts the counts back whenever
-- something lowers them (finding a squirrel, Reset progress). Installed Oct 1 2026 for the waterfall tests.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local folder = workspace:WaitForChild("SquirrelScripts")
local Registry = require(folder:WaitForChild("SquirrelRegistry"))
local per, ids, total = {}, {}, 0
for _, e in ipairs(Registry.squirrels) do
	per[e.map] = (per[e.map] or 0) + 1
	ids[#ids + 1] = e.id
	total += 1
end
table.sort(ids)
local idList = table.concat(ids, ",")
local names = {"FoundIds", "SquirrelsFound"}
for _, m in ipairs(Registry.maps) do names[#names + 1] = "Found_" .. m.id end
local function assert44(p)
	if not p.Parent then return end
	for _, m in ipairs(Registry.maps) do
		if p:GetAttribute("Found_" .. m.id) ~= (per[m.id] or 0) then p:SetAttribute("Found_" .. m.id, per[m.id] or 0) end
	end
	if p:GetAttribute("FoundIds") ~= idList then p:SetAttribute("FoundIds", idList) end
	if p:GetAttribute("SquirrelsFound") ~= total then p:SetAttribute("SquirrelsFound", total) end
end
local function setup(p)
	-- wait for SquirrelSetup's own load (with API access off it retries the DataStore for a few seconds) so that its
	-- publish does not overwrite ours
	local t0 = os.clock()
	while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 20 do task.wait(0.25) end
	task.wait(0.5)
	if not p.Parent then return end
	assert44(p)
	for _, n in ipairs(names) do
		p:GetAttributeChangedSignal(n):Connect(function() task.defer(assert44, p) end)
	end
	print(string.format("ZZ_TEST_Give44: %s has all %d squirrels for this Studio session (nothing is saved)", p.Name, total))
end
Players.PlayerAdded:Connect(setup)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(setup, p) end
]=====]
s.Parent = SSS
print("QQ G44 installed " .. s:GetFullName())

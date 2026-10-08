-- BoatServer: the 1001 Squirrels motorboat. "Take the boat" at the jetty (after all 44 squirrels in the forest, the Rue
-- and the Chateau; the game's owner may always), one boat per player, at most MAX_BOATS on the water. The driver's client
-- steers it (BoatClient); this script builds the boat, seats the player, gives them the physics, runs the wake and cleans up.
-- Getting out (jump) puts the player back on the jetty and the boat goes away.
-- v2 (Oct 1 2026): OVER THE FALLS. Past the brink (z < LIP_Z) the boat stops obeying the stick, tips and falls; a moment
-- later the passenger is thrown out forward and lands in the plunge pool - unless they have found the Sky Diving Squirrel,
-- then a parachute opens and they float down (their client steers it). When the hull hits the pool it breaks into pieces
-- that scatter and float; most fade, a couple survive and wash along the shore as wreckage. A fresh boat waits at the jetty.
-- v41 (Oct 1 2026, her phone / VR notes): jump out within DOCK_R of the jetty and you step back onto it, farther out you are
-- in the water where you are; the moored boat and its prompt are gone while the taken boat is still in the dock half of the
-- river (they come back once it passes HALF_Z, or the boat is cleared); BoatClient reads the thumbstick as well as the seat.
-- v42 (Oct 1 2026, her next note): out on the river the boat is NOT put away when the driver leaves - the driver falls in the
-- water and the empty boat carries on down the river by itself (adrift: the server steers it along River.Line at DRIFT_SPEED,
-- nobody can climb in, and it goes over the falls like any other). Near the jetty it is still put away and you step back on.
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
-- the x limits follow the river itself (River.Line: centre x +- half width, plus slack): the gorge swings out to x 110
-- around z -380, and the fixed 130 sent boats home halfway down (her report, Oct 1 2026)
local LINE = {}                                     -- the river's centre line {x, z, w = half width}, downstream order (adrift boats follow it)
do
	local lo, hi = math.huge, -math.huge
	for x, z, w in string.gmatch(River:GetAttribute("Line") or "", "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
		x, z, w = tonumber(x), tonumber(z), tonumber(w)
		if x and w then lo = math.min(lo, x - w); hi = math.max(hi, x + w) end
		if x and z and w then LINE[#LINE + 1] = {x = x, z = z, w = w} end
	end
	if lo < hi then BOX.xmin = math.floor(lo) - 14; BOX.xmax = math.ceil(hi) + 14 end
end
local activity = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")   -- v43: the Passport hears boat / falls / chute
local function stamp(p, id, data) if activity and p then activity:Fire(p, id, data or {}) end end
local boats = {}                                    -- player -> model
local adrift = {}                                   -- model -> true: boats whose driver left out on the river; they carry on by themselves
local DRIFT_SPEED = 7                               -- studs/s for a runaway boat (a little over half throttle)
local warned = {}                                   -- player -> {n = holds so far without a parachute, t = os.clock() of the last}
local ENGINE = {vol0 = 0.22, vol1 = 0.5, pitch0 = 1.5, pitch1 = 2.0, top = 13}   -- idle -> full speed
-- the falls
local LIP_Z = -547.5                                -- the brink line (the walls' last column)
local SEA_Y = -52.9                                 -- the plunge pool / harbour water
-- the parachute is lent by the Sky Diving Squirrel (workspace.parachute_squirrel_color) once all 44 are found; see the end
local EJECT_AFTER = 0.25                            -- seconds past the brink before the passenger is thrown out
local MAX_WRECKS = 8
local DOCK_R = 24                                   -- jump out within this of the jetty and you step back onto it; farther out you stay in the water
local HALF_Z = (JETTY_OUT.Z + LIP_Z) / 2            -- halfway from the dock to the brink: the moored boat returns once the taken one is past this
local dock = nil                                    -- {p = player, m = model} while the moored boat is "taken"

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

-- the moored boat is "taken": it and its prompt disappear while the new boat is still in the dock half of the river
local function dockFree()
	if not dock then return end
	dock = nil
	for _, d in ipairs(preview:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("DockT") ~= nil then d.Transparency = d:GetAttribute("DockT"); d:SetAttribute("DockT", nil) end
	end
	if prompt then prompt.Enabled = true end
	B:SetAttribute("DockBusy", nil)
end
local function dockTake(p, m)
	dockFree()
	dock = {p = p, m = m}
	for _, d in ipairs(preview:GetDescendants()) do
		if d:IsA("BasePart") then d:SetAttribute("DockT", d.Transparency); d.Transparency = 1 end
	end
	if prompt then prompt.Enabled = false end
	B:SetAttribute("DockBusy", p.UserId)
end

local removePack
-- putBack: step back onto the jetty - but only from near it (DOCK_R); out on the river you are left in the water where you
-- are (her note, Oct 1). force: always back to the jetty (a boat that escaped the river box).
local function clear(p, putBack, force)
	local m = boats[p]; boats[p] = nil
	if dock and m and dock.m == m then dockFree() end
	local hull = m and m.PrimaryPart
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local at = (hull and hull.Position) or (root and root.Position)
	local nearDock = at ~= nil and (at - JETTY_OUT).Magnitude <= DOCK_R
	if m then m:Destroy() end
	riderGroup(char, false)
	if putBack and (force or nearDock) then
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			char:PivotTo(CFrame.lookAt(JETTY_OUT, JETTY_OUT + Vector3.new(1, 0, 0)))
		end
	end
end
-- the driver has left out on the river (jumped, died, quit): the boat carries on down the river by itself (her note, Oct 1)
local function release(p, m)
	if boats[p] ~= m then return end
	boats[p] = nil
	adrift[m] = true
	m:SetAttribute("Adrift", true)
	riderGroup(p.Character, false)
	local seat = m:FindFirstChild("BoatSeat")
	if seat then seat.Disabled = true end                      -- nobody climbs into a runaway boat
	local hull = m.PrimaryPart
	if hull then pcall(function() hull:SetNetworkOwner(nil) end) end
end
-- the driver is out of the seat: near the jetty the boat is put away (and they step back on), farther out it carries on
local function leave(p, backOnJetty)
	local m = boats[p]
	if not m then return end
	local hull = m.PrimaryPart
	local at = hull and hull.Position
	if at and (at - JETTY_OUT).Magnitude > DOCK_R and not m:GetAttribute("Falling") then release(p, m) else clear(p, backOnJetty) end
end
-- an adrift boat follows the river's centre line downstream, held in the channel
local function nearestOnLine(x, z)
	local bd, bnx, bnz, bdx, bdz = math.huge, 0, 0, 0, -1
	for i = 1, #LINE - 1 do
		local a, b = LINE[i], LINE[i + 1]
		local ex, ez = b.x - a.x, b.z - a.z
		local L2 = ex * ex + ez * ez
		if L2 > 0 then
			local t = math.clamp(((x - a.x) * ex + (z - a.z) * ez) / L2, 0, 1)
			local px, pz = a.x + ex * t, a.z + ez * t
			local dx, dz = x - px, z - pz
			local d = math.sqrt(dx * dx + dz * dz)
			if d < bd then
				local L = math.sqrt(L2)
				bd = d
				if d > 1e-4 then bnx, bnz = dx / d, dz / d else bnx, bnz = 0, 0 end
				bdx, bdz = ex / L, ez / L
			end
		end
	end
	return bd, bnx, bnz, bdx, bdz
end
local function driftStep(m)
	local hull = m.PrimaryPart
	local lv, ao = hull:FindFirstChild("Move"), hull:FindFirstChild("Level")
	if not (lv and ao) then return end
	local q = hull.Position
	local d, nx, nz, dx, dz = nearestOnLine(q.X, q.Z)
	local pull = math.min(d, 6) * 0.5                          -- eases it back toward the centre line
	lv.VectorVelocity = Vector3.new(dx * DRIFT_SPEED - nx * pull, (HULL_Y - q.Y) * 6, dz * DRIFT_SPEED - nz * pull)
	local t = os.clock()
	ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(dx, 0, dz)) * CFrame.Angles(0.018 * math.sin(t * 1.1 + 1) + 0.02, 0, 0.025 * math.sin(t * 1.3))
	for _, pe in ipairs(hull.Wake:GetChildren()) do pe.Rate = 14 end
	local snd = hull:FindFirstChild("Engine")
	if snd then snd.Volume = ENGINE.vol0 + (ENGINE.vol1 - ENGINE.vol0) * 0.4; snd.PlaybackSpeed = ENGINE.pitch0 + (ENGINE.pitch1 - ENGINE.pitch0) * 0.4 end
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
	-- the pack the Sky Diving Squirrel lends: an olive nylon tactical pack with orange trim - her reference picture (Oct 1 2026):
	-- boxy body, darker lid band, a front zip pocket, a side pocket, an orange webbing strap down the front with a clip and an
	-- orange zip pull, an orange logo tag low on the front, a grab handle on top, olive shoulder straps
	local OLIVE, OLIVE2, OLIVE3 = Color3.fromRGB(88, 100, 66), Color3.fromRGB(98, 112, 74), Color3.fromRGB(64, 74, 48)
	local ORANGE, STEEL = Color3.fromRGB(238, 118, 28), Color3.fromRGB(205, 205, 210)
	local m = Instance.new("Model"); m.Name = "ChutePack"
	local base = torso.CFrame * CFrame.new(0, 0.1, 0.8)                        -- behind the torso (+z is behind)
	local function piece(name, size, colour, cf, material)
		local q = deco(name, size, colour); q.Material = material or Enum.Material.Fabric; q.CFrame = cf; q.Parent = m; weld(torso, q); return q
	end
	piece("Pack", Vector3.new(1.5, 1.9, 0.7), OLIVE, base)                                                   -- the body
	piece("Lid", Vector3.new(1.52, 0.34, 0.74), OLIVE3, base * CFrame.new(0, 0.86, 0))                       -- the darker top band
	piece("Pocket", Vector3.new(1.3, 0.85, 0.16), OLIVE2, base * CFrame.new(0, -0.42, 0.42))                  -- the front pocket
	piece("PocketZip", Vector3.new(1.3, 0.06, 0.18), OLIVE3, base * CFrame.new(0, 0.02, 0.42))                -- its zip line
	piece("SidePocket", Vector3.new(0.18, 0.8, 0.5), OLIVE2, base * CFrame.new(0.82, -0.2, 0.02))             -- the side pocket
	piece("Strip", Vector3.new(0.28, 1.5, 0.07), ORANGE, base * CFrame.new(-0.3, 0.0, 0.51), Enum.Material.SmoothPlastic)    -- the orange webbing
	piece("Pull", Vector3.new(0.34, 0.3, 0.1), ORANGE, base * CFrame.new(-0.3, 0.84, 0.53), Enum.Material.SmoothPlastic)      -- the orange zip pull
	piece("Clip", Vector3.new(0.16, 0.22, 0.12), STEEL, base * CFrame.new(-0.3, 1.08, 0.5), Enum.Material.Metal)              -- the clip on top of it
	piece("Tag", Vector3.new(0.5, 0.2, 0.05), ORANGE, base * CFrame.new(0.32, -0.72, 0.52), Enum.Material.SmoothPlastic)       -- the orange logo tag
	piece("Handle", Vector3.new(0.6, 0.1, 0.12), OLIVE3, base * CFrame.new(0, 1.1, -0.05))                     -- the grab handle on top
	for _, sx in ipairs({-0.5, 0.5}) do
		piece("Strap", Vector3.new(0.26, 1.45, 0.12), OLIVE3, torso.CFrame * CFrame.new(sx, 0.2, 0.2))         -- the shoulder straps
	end
	m.Parent = char
end
removePack = function(char)
	local m = char and char:FindFirstChild("ChutePack"); if m then m:Destroy() end
end
-- the rider's pose under the open chute: hips and knees bent a little, hands up on the risers (her note, Oct 1 2026).
-- Characters now use AnimationConstraint joints (C0 is read only), so the bend is made by turning the PARENT-side rig
-- attachment of each joint; the original CFrame is kept in an attribute so the landing puts it back. Old Motor6D rigs get
-- the same bend through C0.
local function poseRider(char, on)
	if not char then return end
	local function bend(parentName, attName, childName, motorName, rot)
		local parent = char:FindFirstChild(parentName)
		local child = char:FindFirstChild(childName)
		local motor = child and child:FindFirstChild(motorName)
		if motor and motor:IsA("Motor6D") then
			if on then
				if motor:GetAttribute("ChuteC0") == nil then motor:SetAttribute("ChuteC0", motor.C0) end
				motor.C0 = motor:GetAttribute("ChuteC0") * rot
			else
				local c0 = motor:GetAttribute("ChuteC0"); if c0 then motor.C0 = c0; motor:SetAttribute("ChuteC0", nil) end
			end
			return
		end
		local a = parent and parent:FindFirstChild(attName)
		if not (a and a:IsA("Attachment")) then return end
		if on then
			if a:GetAttribute("ChuteCF") == nil then a:SetAttribute("ChuteCF", a.CFrame) end
			a.CFrame = a:GetAttribute("ChuteCF") * rot
		else
			local cf = a:GetAttribute("ChuteCF"); if cf then a.CFrame = cf; a:SetAttribute("ChuteCF", nil) end
		end
	end
	local HIP, KNEE, ARM = math.rad(28), math.rad(-44), math.rad(160)
	bend("LowerTorso", "LeftHipRigAttachment", "LeftUpperLeg", "LeftHip", CFrame.Angles(HIP, 0, 0))
	bend("LowerTorso", "RightHipRigAttachment", "RightUpperLeg", "RightHip", CFrame.Angles(HIP, 0, 0))
	bend("LeftUpperLeg", "LeftKneeRigAttachment", "LeftLowerLeg", "LeftKnee", CFrame.Angles(KNEE, 0, 0))
	bend("RightUpperLeg", "RightKneeRigAttachment", "RightLowerLeg", "RightKnee", CFrame.Angles(KNEE, 0, 0))
	bend("UpperTorso", "LeftShoulderRigAttachment", "LeftUpperArm", "LeftShoulder", CFrame.Angles(ARM, 0, 0) * CFrame.Angles(0, 0, math.rad(14)))
	bend("UpperTorso", "RightShoulderRigAttachment", "RightUpperArm", "RightShoulder", CFrame.Angles(ARM, 0, 0) * CFrame.Angles(0, 0, math.rad(-14)))
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
	poseRider(char, true)
	task.delay(30, function() if m.Parent then m:Destroy(); poseRider(char, false) end end)
end
local function startFall(p, m)                     -- p is nil for an adrift boat (nobody aboard)
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
		if p and hum and char and char:FindFirstChild("HumanoidRootPart") then
			local chute = hasChute(p)
			stamp(p, "falls", {chute = chute})                        -- Passport: went over the falls (with or without the chute)
			if chute then stamp(p, "chute") end                       -- Passport: the rainbow landing
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
	local function mine() if p then return boats[p] == m else return adrift[m] == true end end
	local function gone() if p then clear(p, false) else adrift[m] = nil; m:Destroy() end end
	conn = RunService.Heartbeat:Connect(function()
		if not hull.Parent or not mine() then conn:Disconnect(); return end
		local lf = hull:FindFirstChild("Lift")
		if lf then lf.Force = Vector3.new(0, math.min(hull.AssemblyMass, hull.Mass) * workspace.Gravity * 0.84, 0) end
		if hull.Position.Y <= SEA_Y + 0.6 then
			conn:Disconnect()
			breakUp(hull)
			gone()
		end
	end)
	task.delay(12, function() if conn.Connected then conn:Disconnect(); if mine() then gone() end end end)
end

ev.OnServerEvent:Connect(function(p, what)
	if what == "landed" then
		local char = p.Character
		local chute = char and char:FindFirstChild("Parachute")
		if chute then chute:Destroy() end
		poseRider(char, false)
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
	-- all 44 but no parachute: three warnings, her words (Oct 1 2026); the fourth hold sails. The count forgets after a minute.
	if not hasChute(p) then
		local w = warned[p]
		if not w or os.clock() - w.t > 60 then w = {n = 0, t = 0}; warned[p] = w end
		w.n += 1; w.t = os.clock()
		local LINES = {"Wait! Stop! You might want to talk to Sky Diving Squirrel before you go.", "So hard headed! Sure you don't want to talk to Sky Dive first?", "Don't say I didn't warn you."}
		if w.n <= #LINES then ev:FireClient(p, "note", LINES[w.n]); return end
		warned[p] = nil
	end
	if (hrp.Position - visual.Position).Magnitude > 16 then return end
	if dock and (boats[dock.p] == dock.m or adrift[dock.m]) then ev:FireClient(p, "no", "The boat is out on the river. Another one comes in once it is well on its way."); return end
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
	dockTake(p, m)                                        -- the moored boat is this one now: gone from the jetty until it is halfway down
	hum.Sit = false
	-- move the player into the boat first: seating them from the jetty dragged the boat onto the jetty
	char:PivotTo(seat.CFrame * CFrame.new(0, 2.6, 0))
	riderGroup(char, true)
	char:SetAttribute("NoMusic", true)                    -- the music stops once they are in the boat and stays off (MapMusic reads this)
	pcall(function() hull:SetNetworkOwner(p) end)
	seat:Sit(hum)
	if hasChute(p) then attachPack(char) end
	ev:FireClient(p, "go")
	stamp(p, "boat")                                      -- Passport: took the boat
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant == nil and boats[p] == m and not m:GetAttribute("Falling") then task.wait(0.15); if boats[p] == m and not m:GetAttribute("Falling") then leave(p, true) end end
	end)
	hum.Died:Connect(function() if boats[p] == m then leave(p, false) end end)
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
	local oldNote = jetty and jetty:FindFirstChild("ChuteNote"); if oldNote then oldNote:Destroy() end   -- v44: always the current board
	if jetty then
		local board = Instance.new("Part"); board.Name = "ChuteNote"; board.Size = Vector3.new(0.25, 2.4, 3.6)
		board.Color = Color3.fromRGB(118, 84, 52); board.Material = Enum.Material.Wood; board.Anchored = true; board.CanCollide = false
		board.CFrame = CFrame.new(163.75, 4.4, -150.0)             -- on the jetty's street side, facing the street (+x), before the deck
		local post = Instance.new("Part"); post.Name = "Post"; post.Size = Vector3.new(0.3, 4.9, 0.3); post.Color = Color3.fromRGB(96, 68, 42)
		-- v44 (her note, Oct 1: "the post holding up this sign is covering the text"): the post stands BEHIND the board (-x), from the
		-- deck to just under the board's top edge, so the face (+x, the street side) is clear
		post.Material = Enum.Material.Wood; post.Anchored = true; post.CanCollide = false; post.CFrame = CFrame.new(163.75 - 0.125 - 0.15 - 0.02, 2.95, -150.0); post.Parent = board
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Right; gui.CanvasSize = Vector2.new(540, 360); gui.LightInfluence = 0.6; gui.Parent = board
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -36, 1, -30); t.Position = UDim2.new(0, 18, 0, 15); t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.TextWrapped = true; t.TextColor3 = Color3.fromRGB(255, 244, 214)
		t.Text = "Sailing to Italy today?\nIf you have found all 44 squirrels, you can take the boat.\nSee Sky Diving Squirrel first."   -- her words, Oct 1 (last line shortened the same evening)
		t.Parent = gui
		board.Parent = jetty
	end
end
Players.PlayerRemoving:Connect(function(p) leave(p, false) end)
local function onCharacter(p, char)
	if boats[p] then leave(p, false) end
	if hasChute(p) then task.delay(1, function() if char.Parent then attachPack(char) end end) end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(char) onCharacter(p, char) end) end)
for _, p in ipairs(Players:GetPlayers()) do p.CharacterAdded:Connect(function(char) onCharacter(p, char) end) end

-- watchdog + wake, 5 times a second
while true do
	task.wait(0.2)
	if dock then                                                  -- the moored boat comes back once the taken one is halfway to the brink (or gone)
		local m = dock.m
		local hull = m.Parent and m.PrimaryPart
		if not hull or (boats[dock.p] ~= m and not adrift[m]) or hull.Position.Z < HALF_Z then dockFree() end
	end
	for m in pairs(adrift) do                                     -- runaway boats: down the river by themselves, over the falls like any other
		local hull = m.Parent and m.PrimaryPart
		if not hull then
			adrift[m] = nil; if m.Parent then m:Destroy() end
		elseif not m:GetAttribute("Falling") then
			local q = hull.Position
			if q.Z < LIP_Z then startFall(nil, m)
			elseif q.X < BOX.xmin or q.X > BOX.xmax or q.Z < BOX.zmin or q.Z > BOX.zmax or q.Y < -6 or q.Y > 6 then adrift[m] = nil; m:Destroy()
			else driftStep(m) end
		end
	end
	for p, m in pairs(boats) do
		local hull = m.PrimaryPart
		local seat = m:FindFirstChild("BoatSeat")
		if m:GetAttribute("Falling") then
			-- the fall is handled above
		elseif not (hull and seat) or not seat.Occupant then
			if m:GetAttribute("Empty") then leave(p, true) else m:SetAttribute("Empty", true) end
		else
			m:SetAttribute("Empty", nil)
			local q = hull.Position
			if q.Z < LIP_Z then
				startFall(p, m)
			elseif q.X < BOX.xmin or q.X > BOX.xmax or q.Z < BOX.zmin or q.Z > BOX.zmax or q.Y < -6 or q.Y > 6 then
				clear(p, true, true)
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

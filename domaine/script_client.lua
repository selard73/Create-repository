-- DomaineClient (runs on every client): the breeze in the lavender, the hens, the pump's water and the grain scatter.
-- Everything here is cosmetic and simulated locally, so it stays smooth instead of stepping at the replication rate.
-- The place streams, so props arrive and leave as the player moves: each one is registered when it appears.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local domaine = script.Parent
local props = domaine:WaitForChild("Props")

local groundParams = RaycastParams.new(); groundParams.FilterType = Enum.RaycastFilterType.Include
local groundList = {workspace.Terrain}
local bp = workspace:FindFirstChild("Baseplate"); if bp then table.insert(groundList, bp) end
local pad = domaine:FindFirstChild("GardenPad"); if pad then table.insert(groundList, pad) end
groundParams.FilterDescendantsInstances = groundList
local function groundY(x, z, fallback)
	local r = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), groundParams)
	return r and r.Position.Y or fallback
end

-- ------------------------------------------------------------------ wind ----
-- each lavender and sunflower part rocks about the line where it meets the ground; a slow gust envelope and a phase
-- that runs with position make the field ripple rather than shiver in unison
local sway = {}                                                        -- part -> item
local function swayAmp(m, p)
	if m.Name:match("^lavender_row") then return p.Name == "Lav" and math.rad(4.5) or math.rad(1.6) end
	if m.Name == "sunflower_patch" then return math.rad(2.2) end
end
local function addSway(m, p)
	if not p:IsA("BasePart") or sway[p] then return end
	local amp = swayAmp(m, p)
	if not amp then return end
	local hinge = CFrame.new(0, -p.Size.Y / 2, 0)
	local pos = p.Position
	sway[p] = {part = p, base = p.CFrame, amp = amp, phase = pos.X * 0.23 + pos.Z * 0.11 + math.random() * 0.6,
		speed = 1.1 + math.random() * 0.5, hinge = hinge, hingeInv = hinge:Inverse()}
end

-- ------------------------------------------------------------------ hens ----
local runPos = domaine:GetAttribute("HenRunPos") or Vector3.zero
local runCF = CFrame.new(runPos) * CFrame.Angles(0, domaine:GetAttribute("HenRunYaw") or 0, 0)
local RUN = {x0 = -5.2, x1 = 5.2, z0 = -11.2, z1 = -3.8}           -- the wire run, in the coop's own frame
local GATE_IN, GATE_OUT = Vector3.new(4.8, 0, -7.5), Vector3.new(9.0, 0, -7.5)
local function inRun(worldPos)
	local l = runCF:PointToObjectSpace(worldPos)
	return l.X > RUN.x0 - 0.3 and l.X < RUN.x1 + 0.3 and l.Z > RUN.z0 - 0.3 and l.Z < RUN.z1 + 0.3
end
local function runPoint(u, v) return runCF:PointToWorldSpace(Vector3.new(RUN.x0 + (RUN.x1 - RUN.x0) * u, 0, RUN.z0 + (RUN.z1 - RUN.z0) * v)) end
local FENCE = {x0 = -6, x1 = 6, z0 = -12, z1 = -3}                    -- the wire itself, in the coop's frame
local function fenced(l) return l.X > FENCE.x0 and l.X < FENCE.x1 and l.Z > FENCE.z0 and l.Z < FENCE.z1 end
local function throughGate(l) return l.X > 5 and l.Z > -9.0 and l.Z < -6.0 end
local function cutsWire(a, b)
	-- does the straight walk a -> b (world) cross the fence line anywhere but the gateway? sampled every half stud
	local n = math.max(1, math.ceil((b - a).Magnitude / 0.5))
	local prev = runCF:PointToObjectSpace(a)
	for i = 1, n do
		local l = runCF:PointToObjectSpace(a:Lerp(b, i / n))
		if fenced(l) ~= fenced(prev) and not throughGate((l + prev) / 2) then return true end
		prev = l
	end
	return false
end
local function routeOK(from, route)
	local a = from
	for _, b in ipairs(route) do
		if cutsWire(a, b) then return false end
		a = b
	end
	return true
end
local PathfindingService = game:GetService("PathfindingService")
local hens = {}                                                        -- model -> state
local henModels = {}
local henCount = 0
local probeParams = RaycastParams.new(); probeParams.FilterType = Enum.RaycastFilterType.Exclude
local function addHen(m)
	if hens[m] or not m.Parent then return end
	local bb, size = m:GetBoundingBox()
	if size.Magnitude < 0.5 then return end
	local feet = Vector3.new(bb.Position.X, bb.Position.Y - size.Y / 2, bb.Position.Z)
	local yaw = m:GetAttribute("Yaw") or 0
	local feetCF = CFrame.new(feet) * CFrame.Angles(0, yaw, 0)
	henCount += 1
	local a = math.random() * 6.283
	hens[m] = {model = m, pos = feet, yaw = yaw, inv = feetCF:ToObjectSpace(m:GetPivot()), goal = feet, route = {}, planId = 0, lastPlan = 0, blocked = 0,
		wait = math.random() * 3, peck = 1 + math.random() * 2, pecking = 0, phase0 = henCount * 1.7,
		followOffset = Vector3.new(math.cos(a) * 4.5, 0, math.sin(a) * 4.5),
		path = PathfindingService:CreatePath({AgentRadius = 0.7, AgentHeight = 2.2, AgentCanJump = false, WaypointSpacing = 1.2})}
	table.insert(henModels, m)
	probeParams.FilterDescendantsInstances = henModels
end
local feedChar, feedUntil = nil, 0
local plan
local function wanderPoint() return runPoint(0.1 + math.random() * 0.8, 0.1 + math.random() * 0.8) end
plan = function(h, target, wander, tries)
	-- walk around solid things: paths over the navmesh (walls, bins, buildings). A fence crossing is always taken in
	-- two legs through the gateway, and any route that would still cut the wire is refused (the hen waits and retries).
	h.goal = target
	if h.planning and os.clock() - h.lastPlan < 1.5 then return end
	h.planning = true
	h.lastPlan = os.clock()
	task.spawn(function()
		local from = h.pos
		local function leg(a, b)
			local ok = pcall(function() h.path:ComputeAsync(a + Vector3.new(0, 0.5, 0), Vector3.new(b.X, groundY(b.X, b.Z, a.Y) + 0.5, b.Z)) end)
			if not (ok and h.path.Status == Enum.PathStatus.Success) then return nil end
			local wps, out = h.path:GetWaypoints(), {}
			for i = 2, #wps do table.insert(out, Vector3.new(wps[i].Position.X, b.Y, wps[i].Position.Z)) end
			table.insert(out, b)
			return out
		end
		local route
		local lf = runCF:PointToObjectSpace(from)
		local fromIn, toIn = fenced(lf), fenced(runCF:PointToObjectSpace(target))
		if fromIn ~= toIn then
			local gIn, gOut = runCF:PointToWorldSpace(GATE_IN), runCF:PointToWorldSpace(GATE_OUT)
			gIn = Vector3.new(gIn.X, from.Y, gIn.Z); gOut = Vector3.new(gOut.X, from.Y, gOut.Z)
			local first, second = fromIn and gIn or gOut, fromIn and gOut or gIn
			local inCorridor = lf.Z > -9.2 and lf.Z < -5.8 and lf.X > 3.8 and lf.X < 10.0
			local leg1 = inCorridor and {} or (leg(from, first) or {first})     -- already in the gateway: straight on through
			local leg2 = leg(second, target)
			if leg2 then
				route = leg1
				table.insert(route, second)
				for _, w in ipairs(leg2) do table.insert(route, w) end
			end
		else
			route = leg(from, target)
		end
		h.planning = false
		if not h.model.Parent then return end
		if route and routeOK(from, route) then
			h.route = route
		elseif wander and (tries or 0) < 3 then
			plan(h, wanderPoint(), true, (tries or 0) + 1)                     -- that spot is not reachable: pick another
			return
		else
			h.route = {}                                                          -- no clean way there: wait, try again shortly
			h.lastPlan = os.clock() + 0.8
			return
		end
		if (Vector3.new(h.goal.X, 0, h.goal.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude > 2 then plan(h, h.goal) end
	end)
end
local function blockedAhead(h, u)
	-- things that move (people, the tractor) are not in the navmesh: wait for them rather than walk through them.
	-- Static props are the path's business; stopping for them here only deadlocks a hen against a corner it is skirting.
	local side = Vector3.new(-u.Z, 0, u.X)
	for _, off in ipairs({-0.5, 0, 0.5}) do
		local hit = workspace:Raycast(h.pos + Vector3.new(0, 0.9, 0) + side * off, u * 1.7, probeParams)
		if hit and hit.Instance ~= workspace.Terrain and hit.Instance.CanCollide then
			local model = hit.Instance:FindFirstAncestorOfClass("Model")
			while model do
				if model.Name == "tractor" or model:FindFirstChildOfClass("Humanoid") then return true end
				model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
			end
		end
	end
	return false
end
local function rotY(v, a)
	local c, s = math.cos(a), math.sin(a)
	return Vector3.new(v.X * c + v.Z * s, 0, -v.X * s + v.Z * c)
end
local function clearStep(h, v, len)
	-- a free step: nothing solid in the way (people, props, walls) and not through the wire
	local side = Vector3.new(-v.Z, 0, v.X)
	for _, off in ipairs({-0.5, 0, 0.5}) do
		local hit = workspace:Raycast(h.pos + Vector3.new(0, 0.9, 0) + side * off, v * len, probeParams)
		if hit and hit.Instance ~= workspace.Terrain and hit.Instance.CanCollide then return false end
	end
	return not cutsWire(h.pos, h.pos + v * len)
end
local function personNear(h, r)
	for _, pl in ipairs(Players:GetPlayers()) do
		local ch = pl.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = Vector3.new(h.pos.X - hrp.Position.X, 0, h.pos.Z - hrp.Position.Z)
			if d.Magnitude < r and math.abs(hrp.Position.Y - h.pos.Y) < 5 then return hrp, d end
		end
	end
end
local function turnTo(h, v, dt)
	local want = math.atan2(-v.X, -v.Z)
	local diff = (want - h.yaw + math.pi) % (2 * math.pi) - math.pi
	h.yaw = h.yaw + diff * math.min(1, 9 * dt)
end
local function stepHen(h, dt, now)
	local hrp = feedChar and feedChar.Parent and feedChar:FindFirstChild("HumanoidRootPart")
	local following = hrp and now < feedUntil
	local speed = 2.6
	if following then
		speed = 7.0
		local target = hrp.Position + h.followOffset
		local far = (Vector3.new(target.X, 0, target.Z) - Vector3.new(h.goal.X, 0, h.goal.Z)).Magnitude > 2.0
		local away = (Vector3.new(target.X, 0, target.Z) - Vector3.new(h.pos.X, 0, h.pos.Z)).Magnitude > 2.2
		local stale = away and now - (h.lastMove or now) > 3                      -- standing still while far from the feeder: try again
		if (far or (#h.route == 0 and away) or stale) and os.clock() - h.lastPlan > 0.4 then
			plan(h, target); h.lastMove = now
		end
		h.wasFollowing = true
	else
		if h.wasFollowing then h.wasFollowing = false; plan(h, wanderPoint(), true) end
		h.wait -= dt
		if h.wait <= 0 then
			plan(h, wanderPoint(), true)
			h.wait = 3 + math.random() * 5
		end
	end
	-- waypoints already reached are dropped first, so the pace carries straight through them
	-- (reached = within a stud, or already past it: a hen at speed turns on a radius wider than a waypoint is close,
	-- and would otherwise circle a point it can never quite touch)
	while #h.route > 1 do
		local w, w2 = h.route[1], h.route[2]
		local toW = Vector3.new(w.X - h.pos.X, 0, w.Z - h.pos.Z)
		local ahead = Vector3.new(w2.X - w.X, 0, w2.Z - w.Z)
		if toW.Magnitude <= 0.9 or toW:Dot(ahead) < 0 then table.remove(h.route, 1) else break end
	end
	-- where to go this frame: a desired direction and speed, smoothed below so nothing flips frame to frame
	local target = h.route[1] or h.goal
	local d = Vector3.new(target.X - h.pos.X, 0, target.Z - h.pos.Z)
	local dist = d.Magnitude
	local last = #h.route <= 1
	local arrive = last and (following and 1.2 or 0.5) or 0.45
	if last and h.arrived then arrive = arrive + 1.2 end                  -- once there, stay put until the goal really moves away
	local desired, want = nil, 0
	local hrpNear, awayV = personNear(h, h.scatter and 3.4 or 2.2)         -- hysteresis: starts at 2.2 studs, ends past 3.4
	h.scatter = hrpNear ~= nil
	if hrpNear then
		-- someone is right on top of the hen: ease away from them, around whatever is behind
		local a = awayV.Magnitude > 0.05 and awayV.Unit or Vector3.new(1, 0, 0)
		for _, ang in ipairs({0, 0.8, -0.8, 1.6, -1.6}) do
			local v = rotY(a, ang)
			if clearStep(h, v, 1.4) then desired = v; want = 4.5; break end
		end
	elseif dist > arrive then
		local u = d / dist
		if blockedAhead(h, u) then
			-- a person (or the tractor) in the way: pick a side once and keep to it until the way ahead is clear again
			if not h.side then
				local best
				for _, ang in ipairs({0.9, -0.9, 1.5, -1.5}) do
					if clearStep(h, rotY(u, ang), 1.6) then best = ang; break end
				end
				h.side = best
			end
			if h.side and clearStep(h, rotY(u, h.side), 1.4) then desired = rotY(u, h.side); want = speed * 0.8; h.blocked = 0
			else h.blocked += dt; if h.blocked > 0.9 then h.blocked = 0; h.side = nil; plan(h, h.goal) end end
			h.clearSince = now
		else
			if h.side and now - (h.clearSince or 0) > 0.3 then h.side = nil end
			desired = u; h.blocked = 0
			-- ease in over the last couple of studs of the final leg instead of overshooting and turning back
			want = last and speed * math.clamp((dist - arrive) / 2.0 + 0.2, 0.2, 1) or speed
		end
		h.arrived = false
	else
		h.route = {}                                                          -- arrived
		h.arrived = true
	end
	-- smooth the heading and the pace: hens lean into turns and slow down instead of snapping
	local moving = false
	if desired then
		local k = math.min(1, 12 * dt)
		h.dir = h.dir and (h.dir * (1 - k) + desired * k) or desired
		if h.dir.Magnitude > 0.01 then h.dir = h.dir.Unit else h.dir = desired end
		h.pace = (h.pace or 0) + (want - (h.pace or 0)) * math.min(1, (want > (h.pace or 0) and 6 or 10) * dt)
		local step = math.min(h.pace * dt, hrpNear and 10 or math.max(dist - arrive * 0.5, 0))
		if step > 0.002 then
			h.pos = h.pos + h.dir * step
			turnTo(h, h.dir, dt)
			h.lastMove = now
			moving = h.pace > 0.25
		end
	else
		h.pace = 0
	end
	if not moving then
		h.peck -= dt
		if h.peck <= 0 then h.pecking = 0.9; h.peck = 1.4 + math.random() * 2.6 end
	end
	for _, o in pairs(hens) do                                            -- hens keep a little room from each other
		if o ~= h then
			local dd = Vector3.new(h.pos.X - o.pos.X, 0, h.pos.Z - o.pos.Z)
			local l = dd.Magnitude
			if l > 0.01 and l < 0.9 then h.pos = h.pos + dd / l * (0.9 - l) * 0.5 end
		end
	end
	local pitch = 0
	if h.pecking > 0 then
		h.pecking -= dt
		local u = 1 - math.max(h.pecking, 0) / 0.9
		pitch = math.rad(30) * math.sin(u * math.pi)                              -- one unhurried dip of the head
	end
	local bob = moving and math.abs(math.sin(now * (following and 22 or 15) + h.phase0)) * 0.14 * math.min(1, h.pace / 2.6) or 0
	local gy = groundY(h.pos.X, h.pos.Z, h.pos.Y)
	h.pos = Vector3.new(h.pos.X, gy, h.pos.Z)
	local feetCF = CFrame.new(h.pos.X, gy + bob, h.pos.Z) * CFrame.Angles(0, h.yaw, 0) * CFrame.Angles(-pitch, 0, 0)
	h.model:PivotTo(feetCF * h.inv)
end
local function grainScatter(at)
	local a = Instance.new("Attachment"); a.Parent = workspace.Terrain; a.WorldPosition = at + Vector3.new(0, 0.6, 0)
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(236, 196, 96), Color3.fromRGB(214, 160, 70)); pe.Size = NumberSequence.new(0.22, 0.14)
	pe.Lifetime = NumberRange.new(0.5, 0.9); pe.Speed = NumberRange.new(5, 8); pe.SpreadAngle = Vector2.new(60, 60)
	pe.Acceleration = Vector3.new(0, -30, 0); pe.Rate = 0; pe.LightEmission = 0.15; pe.Parent = a
	pe:Emit(60)
	local pile = Instance.new("Part"); pile.Anchored = true; pile.CanCollide = false; pile.CanQuery = false; pile.Shape = Enum.PartType.Cylinder
	pile.Size = Vector3.new(0.08, 1.6, 1.6); pile.Color = Color3.fromRGB(228, 186, 88); pile.Material = Enum.Material.Sand
	pile.CFrame = CFrame.new(at.X, groundY(at.X, at.Z, at.Y) + 0.03, at.Z) * CFrame.Angles(0, 0, math.pi / 2); pile.Parent = workspace.Terrain
	task.delay(3, function() a:Destroy() end)
	task.delay(28, function() TweenService:Create(pile, TweenInfo.new(2), {Transparency = 1}):Play() end)
	task.delay(31, function() pile:Destroy() end)
end
local function onFeed()
	local uid = domaine:GetAttribute("FeedBy")
	local until_ = domaine:GetAttribute("FeedUntil") or 0
	local at = domaine:GetAttribute("FeedAt")
	local player = uid and Players:GetPlayerByUserId(uid)
	if player and player.Character then
		feedChar = player.Character; feedUntil = until_
		for _, h in pairs(hens) do
			local a = math.random() * 6.283; local r = 4.0 + math.random() * 2.0
			h.followOffset = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			h.route = {}
		end
	end
	if at then grainScatter(at) end
end
domaine:GetAttributeChangedSignal("FeedUntil"):Connect(onFeed)

-- ------------------------------------------------------------------ the pump ----
local pumps = {}                                                       -- trough model -> true
local function addPump(trough)
	if pumps[trough] or not trough.Parent then return end
	local handle = trough:FindFirstChild("Handle")
	local spout = trough:FindFirstChild("Spout", true)
	local hinge = trough:FindFirstChild("Hinge", true)
	local water = trough:FindFirstChild("Water")
	if not (handle and spout and hinge) then return end
	pumps[trough] = true
	local handle0 = handle.CFrame
	local hingeCF = hinge.WorldCFrame
	local rel = hingeCF:ToObjectSpace(handle0)
	local fall = Instance.new("Attachment"); fall.Name = "Fall"; fall.Parent = spout.Parent
	fall.WorldCFrame = CFrame.new(spout.WorldPosition - Vector3.new(0, 0.12, 0))            -- world-upright: "Bottom" is straight down whatever the pump's rotation
	local stream = Instance.new("ParticleEmitter"); stream.Name = "Stream"; stream.Texture = "rbxasset://textures/particles/smoke_main.dds"
	stream.Color = ColorSequence.new(Color3.fromRGB(110, 170, 255), Color3.fromRGB(170, 215, 255)); stream.Size = NumberSequence.new(0.34, 0.42)
	stream.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.35)}); stream.Squash = NumberSequence.new(-1.2)
	stream.Orientation = Enum.ParticleOrientation.VelocityParallel; stream.Lifetime = NumberRange.new(0.3, 0.36); stream.Rate = 0
	stream.Speed = NumberRange.new(0.8, 1.2); stream.SpreadAngle = Vector2.new(2, 2); stream.Acceleration = Vector3.new(0, -22, 0)
	stream.EmissionDirection = Enum.NormalId.Bottom; stream.LightEmission = 0.1; stream.Parent = fall
	local snd = Instance.new("Sound"); snd.SoundId = "rbxasset://sounds/impact_water.mp3"; snd.Volume = 0.5; snd.RollOffMaxDistance = 45; snd.Parent = handle
	local water0 = water and water.CFrame
	local conn
	trough:GetAttributeChangedSignal("PumpAt"):Connect(function()
		if conn then conn:Disconnect() end
		local t0 = os.clock()
		stream.Rate = 120
		task.delay(0.3, function() snd:Play() end); task.delay(1.2, function() snd:Play() end); task.delay(2.1, function() snd:Play() end)
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			local a = -math.rad(42) * (0.5 - 0.5 * math.cos(t * 2 * math.pi / 0.9))         -- three strokes, pushed down and back up
			handle.CFrame = hingeCF * CFrame.Angles(0, 0, a) * rel
			if water and water0 then water.CFrame = water0 + Vector3.new(0, math.min(0.18, t * 0.07), 0) end
			if t > 2.7 or not trough.Parent then
				conn:Disconnect(); conn = nil
				handle.CFrame = handle0; stream.Rate = 0
				if water and water0 then TweenService:Create(water, TweenInfo.new(16, Enum.EasingStyle.Linear), {CFrame = water0}):Play() end
			end
		end)
	end)
end

-- ------------------------------------------------------------------ registration ----
local function register(m)
	if not m:IsA("Model") then return end
	if m.Name:match("^lavender_row") or m.Name == "sunflower_patch" then
		for _, p in ipairs(m:GetChildren()) do addSway(m, p) end
		m.ChildAdded:Connect(function(p) addSway(m, p) end)
	elseif m.Name == "hen" then
		task.defer(addHen, m)
		task.delay(0.5, addHen, m)
	elseif m.Name == "trough" then
		task.defer(addPump, m)
		task.delay(0.5, addPump, m)
	end
end
for _, m in ipairs(props:GetChildren()) do register(m) end
props.ChildAdded:Connect(register)
props.ChildRemoved:Connect(function(m)
	hens[m] = nil; pumps[m] = nil
	local i = table.find(henModels, m); if i then table.remove(henModels, i); probeParams.FilterDescendantsInstances = henModels end
	for p in pairs(sway) do if p.Parent == nil or p:IsDescendantOf(m) then sway[p] = nil end end
end)

-- ------------------------------------------------------------------ frame ----
local t = 0
RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.05)
	t += dt
	local gust = 0.55 + 0.45 * math.sin(t * 0.31) * math.sin(t * 0.17 + 1.0)
	for p, it in pairs(sway) do
		if p.Parent then
			local a = it.amp * (gust * math.sin(t * it.speed + it.phase) + 0.25 * math.sin(t * 3.1 + it.phase * 2))
			p.CFrame = it.base * it.hinge * CFrame.Angles(a, 0, 0) * it.hingeInv
		else
			sway[p] = nil
		end
	end
	local now = workspace:GetServerTimeNow()
	for m, h in pairs(hens) do
		if m.Parent then stepHen(h, dt, now) else hens[m] = nil end
	end
end)

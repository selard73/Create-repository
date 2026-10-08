-- TidePoolLife (LocalScript, StarterPlayerScripts) - Oct 4 2026, Porto Nocciola's natural tide pools.
-- 1) Wading: while your feet are in a pool you slow a little, ripples spread from your feet, water splashes when you step in
--    and a soft splash plays as you walk. (The pool water is a see-through mesh; Roblox terrain water cannot fit pools this small.)
-- 2) Crabs: a few rigged crabs (ReplicatedStorage.TidePoolCrab) scuttle sideways round the shelf, stop, wave their claws.
--    Everything runs on this player's own screen only, and only while they are near the cove.
-- Source: roblox-props/italy/tidepools/TidePoolLife.client.lua (POINTS are filled in by make_life_lua.py).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local COVE_CENTRE = Vector3.new(298, -52, -785)
local NEAR = 140                 -- studs: crabs only exist / move while you are this close
local CRAB_COUNT = 4
local POINTS = %POINTS%

local function poolsFolder()
	local p = workspace:FindFirstChild("PortoNocciola")
	p = p and p:FindFirstChild("14 Lighthouse coast")
	p = p and p:FindFirstChild("Cala della Sabbia and tide pools")
	return p and p:FindFirstChild("Natural tide pools")
end

-- ================= wading =================
local SPLASH = "rbxasset://sounds/impact_water.mp3"
local inWater, slowedTo, baseSpeed = false, nil, nil
local lastRipple, lastStep = 0, 0
local fx = Instance.new("Folder") fx.Name = "TidePoolFX" fx.Parent = workspace

local function sound(pos, vol, pitch)
	local a = Instance.new("Part") a.Anchored = true a.CanCollide = false a.CanQuery = false a.CanTouch = false
	a.Transparency = 1 a.Size = Vector3.new(0.2, 0.2, 0.2) a.CFrame = CFrame.new(pos) a.Parent = fx
	local s = Instance.new("Sound") s.SoundId = SPLASH s.Volume = vol s.PlaybackSpeed = pitch s.RollOffMaxDistance = 60 s.Parent = a
	s:Play()
	task.delay(2, function() a:Destroy() end)
end

local function ripple(pos, size)
	local r = Instance.new("Part") r.Shape = Enum.PartType.Cylinder r.Anchored = true r.CanCollide = false r.CanQuery = false r.CanTouch = false
	r.CastShadow = false r.Material = Enum.Material.SmoothPlastic r.Color = Color3.fromRGB(235, 250, 252) r.Transparency = 0.45
	r.Size = Vector3.new(0.02, 0.5, 0.5)
	r.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	r.Parent = fx
	TweenService:Create(r, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.02, size, size), Transparency = 1}):Play()
	task.delay(1, function() r:Destroy() end)
end

local function droplets(pos, n)
	local a = Instance.new("Part") a.Anchored = true a.CanCollide = false a.CanQuery = false a.CanTouch = false a.Transparency = 1
	a.Size = Vector3.new(0.2, 0.2, 0.2) a.CFrame = CFrame.new(pos) a.Parent = fx
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(220, 244, 250)) e.LightEmission = 0.3
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.05)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(0.35, 0.6) e.Speed = NumberRange.new(4, 7) e.SpreadAngle = Vector2.new(35, 35)
	e.Acceleration = Vector3.new(0, -30, 0) e.EmissionDirection = Enum.NormalId.Top e.Rate = 0 e.Parent = a
	e:Emit(n)
	task.delay(1.2, function() a:Destroy() end)
end

local function wadeStep(char, dt, folder)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	local water = folder and folder:FindFirstChild("TidePoolWater")
	if not (hrp and hum and water) then return end
	local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = {water}
	local hit = workspace:Raycast(hrp.Position + Vector3.new(0, 1, 0), Vector3.new(0, -8, 0), rp)
	local feetY = hrp.Position.Y - hrp.Size.Y / 2 - hum.HipHeight
	local nowIn = hit ~= nil and feetY < hit.Position.Y + 0.05 and feetY > hit.Position.Y - 2.5
	local now = os.clock()
	if nowIn and not inWater then
		inWater = true
		baseSpeed = hum.WalkSpeed
		slowedTo = baseSpeed * 0.75
		hum.WalkSpeed = slowedTo
		local p = Vector3.new(hrp.Position.X, hit.Position.Y + 0.03, hrp.Position.Z)
		sound(p, 0.55, 1.0 + math.random() * 0.15) droplets(p, 14) ripple(p, 4)
	elseif not nowIn and inWater then
		inWater = false
		if slowedTo and math.abs(hum.WalkSpeed - slowedTo) < 0.01 and baseSpeed then hum.WalkSpeed = baseSpeed end
		slowedTo, baseSpeed = nil, nil
	end
	if inWater and hum.MoveDirection.Magnitude > 0.1 then
		local p = Vector3.new(hrp.Position.X, hit.Position.Y + 0.03, hrp.Position.Z)
		if now - lastRipple > 0.32 then lastRipple = now ripple(p, 2.6) end
		if now - lastStep > 0.42 then lastStep = now sound(p, 0.22, 1.15 + math.random() * 0.25) droplets(p, 4) end
	end
end

-- ================= crabs =================
local crabs = {}
local rng = Random.new()

local function surface(folder, x, z)
	local shelf = folder and folder:FindFirstChild("TidePoolShelf")
	if not shelf then return nil end
	local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Include rp.FilterDescendantsInstances = {shelf}
	local r = workspace:Raycast(Vector3.new(x, -40, z), Vector3.new(0, -20, 0), rp)
	return r and r.Position, r and r.Normal
end

local function pick() local p = POINTS[rng:NextInteger(1, #POINTS)] return Vector2.new(p[1], p[2]) end

local function makeCrab(template)
	local m = template:Clone()
	local mesh = m:FindFirstChildWhichIsA("MeshPart", true)
	if not mesh then m:Destroy() return nil end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanQuery = false d.CanTouch = false end
	end
	m.Parent = fx
	local bones = {}
	for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local c = {model = m, mesh = mesh, bones = bones, pos = pick(), target = nil, wait = rng:NextNumber(0, 2),
		facing = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)).Unit, phase = rng:NextNumber(0, 6), claw = 0, clawT = 0}
	-- each leg/claw bone's own axis for "the crab's forward" and "the crab's right", measured at rest
	mesh.CFrame = CFrame.new(0, 0, 0)
	c.axes = {}
	for name, b in pairs(bones) do
		local w = b.WorldCFrame
		c.axes[name] = {fwd = w:VectorToObjectSpace(Vector3.new(0, 0, -1)), right = w:VectorToObjectSpace(Vector3.new(1, 0, 0))}
	end
	return c
end

local function poseCrab(c, moving, dt)
	local b = c.bones
	c.phase += dt * (moving and 14 or 0)
	local s1, s2 = math.sin(c.phase), math.sin(c.phase + math.pi)
	local lift = moving and 0.32 or 0
	local function leg(name, s, side)
		local bone = b[name] if not bone then return end
		bone.Transform = CFrame.fromAxisAngle(c.axes[name].fwd, side * math.max(0, s) * lift - side * 0.04)
	end
	leg("LegsLF", s1, 1) leg("LegsRB", s1, -1) leg("LegsLB", s2, 1) leg("LegsRF", s2, -1)
	-- claws: now and then, when standing still, a little wave
	local clawAngle = 0
	if c.clawT > 0 then clawAngle = math.sin((1.2 - c.clawT) * 8) * 0.35 + 0.25 end
	for _, name in ipairs({"ClawL", "ClawR"}) do
		local bone = b[name]
		if bone then bone.Transform = CFrame.fromAxisAngle(c.axes[name].right, clawAngle) end
	end
end

local function stepCrab(c, dt, folder)
	local speed = 2.2
	if c.wait > 0 then
		c.wait -= dt
		if c.clawT > 0 then c.clawT -= dt end
		if c.wait <= 0 then c.target = pick() end
	elseif c.target then
		local d = c.target - c.pos
		if d.Magnitude < 0.3 then
			c.target = nil c.wait = rng:NextNumber(0.8, 3.5)
			if rng:NextNumber() < 0.45 then c.clawT = 1.2 end
		else
			local dir = d.Unit
			c.pos += dir * math.min(d.Magnitude, speed * dt)
			-- crabs walk sideways: face across the direction of travel, turning gently
			local want = Vector3.new(-dir.Y, 0, dir.X)
			if want:Dot(c.facing) < 0 then want = -want end
			c.facing = c.facing:Lerp(want, math.min(1, dt * 4)).Unit
		end
	end
	local p, n = surface(folder, c.pos.X, c.pos.Y)
	if not p then return end
	local up = n:Lerp(Vector3.yAxis, 0.5).Unit
	local fwd = (c.facing - up * c.facing:Dot(up)).Unit
	local right = fwd:Cross(up)
	local cf = CFrame.fromMatrix(p + up * (c.mesh.Size.Y / 2), right, up, -fwd)
	c.mesh.CFrame = cf
	poseCrab(c, c.target ~= nil and c.wait <= 0, dt)
end

-- ================= loop =================
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local folder = poolsFolder()
	local near = hrp and folder and (hrp.Position - COVE_CENTRE).Magnitude < NEAR
	if near then
		pcall(wadeStep, char, dt, folder)
		if #crabs == 0 then
			local template = RS:FindFirstChild("TidePoolCrab")
			if template then for i = 1, CRAB_COUNT do local c = makeCrab(template) if c then table.insert(crabs, c) end end end
		end
		for _, c in ipairs(crabs) do pcall(stepCrab, c, dt, folder) end
	else
		if inWater then                 -- left the cove (or the pools streamed out) while wading: give the speed back
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and slowedTo and math.abs(hum.WalkSpeed - slowedTo) < 0.01 and baseSpeed then hum.WalkSpeed = baseSpeed end
			inWater, slowedTo, baseSpeed = false, nil, nil
		end
		if #crabs > 0 then for _, c in ipairs(crabs) do c.model:Destroy() end crabs = {} end
	end
end)

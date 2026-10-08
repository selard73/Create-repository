-- TractorClient (every client, inside the tractor). The driver's client moves the tractor: throttle and steering from the
-- seat, a bicycle-model turn, the body set on the ground under its four wheels, stopped by anything solid in its way.
-- Every client turns the wheels from the motion it sees, so passengers and bystanders get spinning, steering wheels too.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local model = script.Parent
local seat = model:WaitForChild("DriverSeat")
local chassis = model:WaitForChild("Chassis")
local player = Players.LocalPlayer
local axles = {}
for _, j in ipairs(chassis:GetChildren()) do
	local w = j.Name:match("^Axle(..)$")
	if w and j:IsA("Motor6D") then axles[w] = j end
end
if not (axles.RL and axles.RR and axles.FL and axles.FR) then warn("TractorClient: axles missing") return end
local rRear, rFront = axles.RL.Part1.Size.Y / 2, axles.FL.Part1.Size.Y / 2
local zRear = (axles.RL.C0.Position.Z + axles.RR.C0.Position.Z) / 2
local zFront = (axles.FL.C0.Position.Z + axles.FR.C0.Position.Z) / 2
local wheelbase = zRear - zFront                                           -- the front is toward -z
local track = math.abs(axles.RL.C0.Position.X - axles.RR.C0.Position.X)
local tOrigin = (0 - zRear) / (zFront - zRear)                             -- where the chassis origin sits between the axles
local MAX_STEER, TOP, REVERSE = math.rad(30), 16, 7
local BOUNDS = {x0 = 386, x1 = 700, z0 = -250, z1 = 30}

local groundParams = RaycastParams.new(); groundParams.FilterType = Enum.RaycastFilterType.Include
local gl = {workspace.Terrain}
local bp = workspace:FindFirstChild("Baseplate"); if bp then table.insert(gl, bp) end
local dom = workspace:FindFirstChild("Domaine")
local pad = dom and dom:FindFirstChild("GardenPad"); if pad then table.insert(gl, pad) end
groundParams.FilterDescendantsInstances = gl
local function groundY(x, z, fb)
	local r = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), groundParams)
	return r and r.Position.Y or fb
end
local blockParams = RaycastParams.new(); blockParams.FilterType = Enum.RaycastFilterType.Exclude
local function blocked(origin, dir, char)
	blockParams.FilterDescendantsInstances = {model, char}
	local right = CFrame.lookAt(Vector3.zero, dir).RightVector
	for _, side in ipairs({-2.6, 0, 2.6}) do
		for _, up in ipairs({0.9, 2.2}) do
			local hit = workspace:Raycast(origin + right * side + Vector3.new(0, up, 0), dir, blockParams)
			if hit and hit.Instance ~= workspace.Terrain and hit.Instance.CanCollide then return true end
		end
	end
	return false
end

local pos, heading, speed, steer = nil, 0, 0, 0
local spinVis, steerVis, lastCF = 0, 0, chassis.CFrame
local function input()
	local th = seat.ThrottleFloat; if th == 0 then th = seat.Throttle end
	local st = seat.SteerFloat; if st == 0 then st = seat.Steer end
	return math.clamp(th, -1, 1), math.clamp(st, -1, 1)
end
local function drive(dt, char)
	if not pos then
		local cf = chassis.CFrame
		pos = cf.Position; heading = math.atan2(-cf.LookVector.X, -cf.LookVector.Z); speed = 0; steer = 0
	end
	local th, st = input()
	if th ~= 0 then
		speed = math.clamp(speed + th * 9 * dt, -REVERSE, TOP)
	else
		speed = speed * math.max(0, 1 - 2.5 * dt)
		if math.abs(speed) < 0.05 then speed = 0 end
	end
	steer = steer + (st * MAX_STEER - steer) * math.min(1, 6 * dt)
	if speed ~= 0 then heading = heading - math.tan(steer) * (speed / wheelbase) * dt end
	local yawCF = CFrame.Angles(0, heading, 0)
	local dir = yawCF.LookVector
	local newPos = pos + dir * speed * dt
	if speed ~= 0 then
		local sgn = speed > 0 and 1 or -1
		local reach = (sgn > 0 and -zFront + 1.6 or zRear + 3.0) + math.abs(speed) * dt
		if blocked(pos, dir * sgn * reach, char) then speed = 0; newPos = pos end
		if newPos.X < BOUNDS.x0 or newPos.X > BOUNDS.x1 or newPos.Z < BOUNDS.z0 or newPos.Z > BOUNDS.z1 then speed = 0; newPos = pos end
	end
	pos = newPos
	local h = {}
	for w, j in pairs(axles) do
		local o = j.C0.Position
		local wp = pos + yawCF:VectorToWorldSpace(Vector3.new(o.X, 0, o.Z))
		h[w] = groundY(wp.X, wp.Z, pos.Y)
	end
	local hF, hR = (h.FL + h.FR) / 2, (h.RL + h.RR) / 2
	local hL, hRt = (h.FL + h.RL) / 2, (h.FR + h.RR) / 2
	local pitch = math.atan2(hF - hR, wheelbase)
	local roll = math.atan2(hL - hRt, track)
	pos = Vector3.new(pos.X, hR + (hF - hR) * tOrigin, pos.Z)
	chassis.CFrame = CFrame.new(pos) * yawCF * CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, -roll)
	chassis.AssemblyLinearVelocity = dir * speed
	chassis.AssemblyAngularVelocity = Vector3.new(0, -math.tan(steer) * speed / wheelbase, 0)
	steerVis = steer
end
local function wheels(dt, driving)
	local cf = chassis.CFrame
	local fwd = -cf:VectorToObjectSpace(cf.Position - lastCF.Position).Z          -- travel along the tractor's own forward
	local l0, l1 = lastCF.LookVector, cf.LookVector
	local dyaw = math.atan2(l0.X * l1.Z - l0.Z * l1.X, l0.X * l1.X + l0.Z * l1.Z)
	lastCF = cf
	spinVis = spinVis + fwd / rRear
	if not driving then
		local v = fwd / dt
		local target = math.abs(v) > 0.3 and math.clamp(math.atan(wheelbase * (dyaw / dt) / v), -MAX_STEER, MAX_STEER) or 0
		steerVis = steerVis + (target - steerVis) * math.min(1, 5 * dt)
	end
	for w, j in pairs(axles) do
		local front = w == "FL" or w == "FR"
		local s = front and spinVis * rRear / rFront or spinVis
		j.Transform = (front and CFrame.Angles(0, -steerVis, 0) or CFrame.identity) * CFrame.Angles(-s, 0, 0)
	end
end
RunService.Heartbeat:Connect(function(dt)
	dt = math.min(math.max(dt, 1 / 240), 0.05)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local driving = hum ~= nil and hum.SeatPart == seat and not chassis.Anchored
	if driving then drive(dt, char) else pos = nil end
	wheels(dt, driving)
end)

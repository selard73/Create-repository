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

-- BoatClient: steers the player's own boat (the server gives the driver the physics), keeps it inside the river,
-- bobs it on the water, and shows the jetty prompt text and the short notes. Runs on every client.
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
	local prompt = getPrompt()
	if not prompt then return end
	local n = found()
	prompt.ActionText = "Take the boat"
	prompt.ObjectText = n >= NEED and "Bateau" or string.format("Needs all %d squirrels (%d/%d)", NEED, n, NEED)
end
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

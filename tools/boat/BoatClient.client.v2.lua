-- BoatClient: steers the player's own boat (the server gives the driver the physics), keeps it inside the river,
-- bobs it on the water, and shows the jetty prompt text and the short notes. Runs on every client.
-- v2 (Oct 1 2026): over the falls. Past the brink the server flags the boat Falling and this script lets go of it; on the
-- server's "eject" it throws the character out, and if they carry the parachute (the Sky Diving Squirrel) it flies the
-- descent: steerable with the stick or the keys, sinking gently, until the water or the shore. Then a short welcome note.
-- v41 (Oct 1 2026): phones and VR. The seat's Throttle/Steer (keyboard, gamepad) stay first; when they are idle the
-- thumbstick is read directly (PlayerModule move vector, then the humanoid's move direction) as a camera-relative direction
-- to go, turned into throttle and steer for the hull - push the stick where you want the boat to head.
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

-- short notes (a toast high on the screen, under the title banner; fits a phone)
local gui = Instance.new("ScreenGui"); gui.Name = "BoatUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 5; gui.Parent = player:WaitForChild("PlayerGui")
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0, 72)   -- high on the screen, under the title banner (her note, Oct 1)
toast.Size = UDim2.new(0.92, 0, 0, 56); toast.BackgroundColor3 = Color3.fromRGB(58, 36, 16); toast.BackgroundTransparency = 0.1
toast.BorderSizePixel = 0; toast.Font = Enum.Font.FredokaOne; toast.TextSize = 17; toast.TextWrapped = true
toast.TextColor3 = Color3.fromRGB(255, 244, 214); toast.Visible = false; toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)
local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(460, 56); lim.Parent = toast
local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = toast
-- v45 (her note, Oct 1: on a phone the parachute warnings hid behind the boat's prompt button): on a touch screen the note
-- looks for a spot clear of everything else showing - the prompt buttons in PromptTouch included - starting under the title
-- banner and moving down the middle, then down the left and right; a computer keeps the spot under the title banner.
local GuiService = game:GetService("GuiService")
local function shownRects()                                      -- every other thing showing, in real screen space
	local out = {}
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(900, 420)
	local inset = GuiService:GetGuiInset()
	for _, sg in ipairs(gui.Parent:GetChildren()) do
		if sg:IsA("ScreenGui") and sg.Enabled and sg ~= gui then
			for _, o in ipairs(sg:GetDescendants()) do
				if o:IsA("GuiObject") and o.Visible and o.AbsoluteSize.X > 4 and o.AbsoluteSize.Y > 4
					and not (o.AbsoluteSize.X >= vs.X * 0.9 and o.AbsoluteSize.Y >= vs.Y * 0.9) then   -- a full-screen layer is not a thing
					local seen = o.BackgroundTransparency < 0.9
						or ((o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and o.TextTransparency < 0.9)
						or ((o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and o.ImageTransparency < 0.9)
					local a = o.Parent
					while seen and a and a ~= sg do
						if a:IsA("GuiObject") and not a.Visible then seen = false end
						a = a.Parent
					end
					if seen then
						local p = o.AbsolutePosition + inset                 -- AbsolutePosition counts from below the top bar, for every ScreenGui
						out[#out + 1] = {p.X, p.Y, p.X + o.AbsoluteSize.X, p.Y + o.AbsoluteSize.Y}
					end
				end
			end
		end
	end
	return out
end
local function placeToast()
	gui.DisplayOrder = 5
	toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0, 72)
	if not UIS.TouchEnabled then return end
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(900, 420)
	local inset = GuiService:GetGuiInset()
	local w, h = math.min((vs.X - inset.X) * 0.92, 460), 56
	local rects = shownRects()
	local function clear(cx, top)                                 -- cx: the note's centre; top: in this ScreenGui's space (below the top bar)
		local r = {cx - w / 2 - 4, top + inset.Y - 4, cx + w / 2 + 4, top + inset.Y + h + 4}
		if r[1] < 2 or r[3] > vs.X - 2 or r[4] > vs.Y - 96 then return false end   -- (the bottom keeps clear of the hotbar)
		for _, q in ipairs(rects) do
			if r[1] < q[3] and r[3] > q[1] and r[2] < q[4] and r[4] > q[2] then return false end
		end
		return true
	end
	for _, cx in ipairs({vs.X / 2, w / 2 + 8, vs.X - w / 2 - 8}) do
		for top = 72, vs.Y, 6 do
			if top + inset.Y + h > vs.Y - 96 then break end
			if clear(cx, top) then toast.Position = UDim2.fromOffset(cx, top) return end
		end
	end
	gui.DisplayOrder = 31                                         -- nowhere clear at all: at least draw the words above the buttons
end
local shown = 0
local function note(text, secs)
	shown += 1
	local me = shown
	toast.Visible = false
	toast.Text = text
	placeToast()
	toast.Visible = true
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
		local off = player:GetAttribute("CineOffset")                       -- (test hook: a Vector3 attribute on the player overrides the shot)
		local want = target + (typeof(off) == "Vector3" and off or CINE_OFFSET)
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

-- the Sky Diving Squirrel speaks the way every squirrel speaks: ReplicatedStorage.SquirrelBubble (the drawn comic bubble on
-- the screen layer, with her squirrel sounds). A long line comes as several bubbles; his Talk prompt steps aside meanwhile.
local BubbleMod = nil
local function squirrelBubble(model, text, secs, withSound)
	if not BubbleMod then
		local ok, mod = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("SquirrelBubble", 5)) end)
		if ok then BubbleMod = mod end
	end
	if BubbleMod then BubbleMod.say(model, text, {secs = secs or 3.5, sound = withSound == true}) end
end
local function squirrelSay(lines)
	local sq = workspace:FindFirstChild("parachute_squirrel_color")
	if not sq then return end
	local prompt = sq:FindFirstChild("ChutePrompt", true)                    -- his Talk prompt steps aside while he speaks
	task.spawn(function()
		if prompt then prompt.Enabled = false end
		for i, line in ipairs(lines) do
			squirrelBubble(sq, line, 3.5, i == 1)
			task.wait(3.6)
		end
		if prompt and prompt.Parent then prompt.Enabled = true end
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
	local may = n >= NEED or player.UserId == game.CreatorId
	prompt.ActionText = (may and not player:GetAttribute("HasChute")) and "Take the boat (no parachute!)" or "Take the boat"
	prompt.ObjectText = may and (player:GetAttribute("HasChute") and "Bateau" or "Bateau - see the Sky Diving Squirrel first") or string.format("Needs all %d squirrels (%d/%d)", NEED, n, NEED)
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
player:GetAttributeChangedSignal("HasChute"):Connect(refreshPrompt)
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
	if math.abs(th) < 0.05 and math.abs(st) < 0.05 then
		-- phones and VR (her note, Oct 1): the stick as a direction to go, relative to the camera, made into throttle and steer
		local w = steerInput(hum)
		if w.Magnitude > 0.05 then
			local fwdW = CFrame.Angles(0, yaw, 0).LookVector
			local rightW = fwdW:Cross(Vector3.yAxis)
			th = math.clamp(w:Dot(fwdW), -1, 1)
			st = math.clamp(w:Dot(rightW), -1, 1)
			if th < -0.2 and math.abs(st) > 0.5 then th = 0 end   -- pushed sideways-back: turn, do not reverse
		end
	end
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

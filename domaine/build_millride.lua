-- MillRide: grab a sail of the windmill as it sweeps past the bottom and ride it all the way round. Shannon (Sep 24):
-- "make it so that a player can grab onto one of the arms of the windmill and ride it all the way around".
--
-- The windmill's Sails part turns on its own (TurnSails, 0.35 rad/s about the sails' look axis). The four arms run
-- along the mesh's diagonals (Picnic Pierre's OnSail seat sits at (-6, 6)), so four Tip attachments go a little in
-- from the ends, just off the face that looks away from the tower (the sails' LookVector points into the tower). A stone pad on the ground under the bottom of the sweep carries the prompt.
-- THE RIDE works the zipline's way: the SERVER picks a free arm (the one that reaches the bottom soonest), tells the
-- rider's client to wait for it, then on "grab" platform-stands the humanoid and poses the arms straight up (for
-- everyone to see); the rider's OWN CLIENT moves the character (a client owns its character's physics) - it hangs
-- the root part Hang studs under the tip, faces the way the sails face, predicts the sail angle between replicated
-- updates so the ride is smooth, and lets go after one full turn (or on a jump). Then the server puts everything back.
-- Attributes on workspace.MillRide: Hang (3.8), Speed (0.35 - must match TurnSails), Turns (1), Reach (grab distance).
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local Props = workspace:WaitForChild("Domaine"):WaitForChild("Props")
	local mill = Props:FindFirstChild("windmill")
	local sails = mill and mill:FindFirstChild("Sails", true)
	if not sails then error("MillRide: the windmill's Sails part is missing") end
	local C = Color3.fromRGB
	local STONE, WOODC, CREAM = C(128, 124, 118), C(118, 84, 52), C(255, 246, 220)

	-- the tips: on the diagonals, R in from the centre each way, on the front face
	local R = opts.reach or 6.6
	local FRONT = opts.front or 1.15                        -- local +z: the sails' look points INTO the tower, so the open side is -look
	for _, old in ipairs(sails:GetChildren()) do if old.Name:match("^Tip%d$") then old:Destroy() end end
	for i, t in ipairs({{R, R}, {-R, R}, {-R, -R}, {R, -R}}) do
		local a = Instance.new("Attachment"); a.Name = "Tip" .. i; a.CFrame = CFrame.new(t[1], t[2], FRONT); a.Parent = sails
	end
	local radius = math.sqrt(2) * R

	local old = workspace:FindFirstChild("MillRide"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "MillRide"
	local hub = sails.Position
	local look = sails.CFrame.LookVector                     -- points from the sails into the tower (measured: the tower parts sit at +7..+8 along it)
	local padSpot = hub - look * 2.4 - Vector3.new(0, radius, 0)     -- the pad on the open side
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {mill}
	local hit = workspace:Raycast(Vector3.new(padSpot.X, hub.Y, padSpot.Z), Vector3.new(0, -80, 0), rp)
	local g = hit and hit.Position.Y or (padSpot.Y - 6)
	local function part(name, size, cf, colour, material, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = F
		return p
	end
	local pad = part("Pad", Vector3.new(0.3, 5.6, 5.6), CFrame.new(padSpot.X, g + 0.15, padSpot.Z) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Slate, Enum.PartType.Cylinder)
	local prompt = Instance.new("ProximityPrompt"); prompt.Name = "GrabPrompt"; prompt.ActionText = "Grab a sail"; prompt.ObjectText = "Windmill  -  ride it round"
	prompt.KeyboardKeyCode = Enum.KeyCode.E; prompt.HoldDuration = 0; prompt.MaxActivationDistance = 9; prompt.RequiresLineOfSight = false; prompt.Parent = pad
	-- a little sign beside the pad, facing it
	local signSpot = padSpot + look:Cross(Vector3.new(0, 1, 0)).Unit * 4.2
	local sg = workspace:Raycast(Vector3.new(signSpot.X, hub.Y, signSpot.Z), Vector3.new(0, -80, 0), rp)
	local sy = sg and sg.Position.Y or g
	local face = CFrame.lookAt(Vector3.new(signSpot.X, 0, signSpot.Z), Vector3.new(padSpot.X, 0, padSpot.Z))
	part("SignPost", Vector3.new(0.35, 3.6, 0.35), CFrame.new(signSpot.X, sy + 1.8, signSpot.Z) * face.Rotation, WOODC, Enum.Material.Wood)
	local board = part("Sign", Vector3.new(3.6, 1.3, 0.14), CFrame.new(signSpot.X, sy + 3.2, signSpot.Z) * face.Rotation * CFrame.new(0, 0, -0.25), WOODC, Enum.Material.Wood)
	board.CanCollide = false
	local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 40; gui.Parent = board
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1; tl.Font = Enum.Font.FredokaOne; tl.TextScaled = true; tl.TextWrapped = true
	tl.TextColor3 = CREAM; tl.Text = "CATCH A SAIL\nand ride it all the way round"; tl.Parent = gui

	F:SetAttribute("HubX", hub.X); F:SetAttribute("HubY", hub.Y); F:SetAttribute("HubZ", hub.Z)
	F:SetAttribute("LookX", look.X); F:SetAttribute("LookY", look.Y); F:SetAttribute("LookZ", look.Z)
	F:SetAttribute("PadX", padSpot.X); F:SetAttribute("PadY", g); F:SetAttribute("PadZ", padSpot.Z)
	F:SetAttribute("Radius", radius)
	F:SetAttribute("Hang", opts.hang or 3.8); F:SetAttribute("Speed", opts.speed or 0.35); F:SetAttribute("Turns", opts.turns or 1); F:SetAttribute("Reach", opts.grabReach or 11)
	local ev = RS:FindFirstChild("MillRide")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "MillRide"; ev.Parent = RS end

	-- ---------------------------------------------------------------- the ride: server ----
	local SERVER = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("MillRide")
local sails
repeat local mill = workspace:WaitForChild("Domaine"):WaitForChild("Props"):FindFirstChild("windmill"); sails = mill and mill:FindFirstChild("Sails", true); if not sails then task.wait(1) end until sails
local HUB = Vector3.new(F:GetAttribute("HubX"), F:GetAttribute("HubY"), F:GetAttribute("HubZ"))
local N = Vector3.new(F:GetAttribute("LookX"), F:GetAttribute("LookY"), F:GetAttribute("LookZ"))
local E1 = Vector3.new(0, 1, 0)
local E2 = N:Cross(E1).Unit
local SPEED = F:GetAttribute("Speed") or 0.35
local function angleOf(att)                               -- 0 = straight up, pi = the bottom of the sweep
	local r = att.WorldPosition - HUB
	return math.atan2(r:Dot(E2), r:Dot(E1))
end
local turn = 1                                            -- which way round the sails go, measured once
task.spawn(function()
	local a1 = angleOf(sails.Tip1); task.wait(0.4); local a2 = angleOf(sails.Tip1)
	local d = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
	turn = d >= 0 and 1 or -1
	F:SetAttribute("Turn", turn)
end)

local arms = {}                                           -- arm index -> player
local riding = {}                                         -- player -> {arm, char, c0, att, stage, since}

-- THE POSE, the zipline's: arms straight up and a touch forward, legs hanging - on the server so everyone sees it
local ARM_UP, ARM_OUT, HIP, KNEE = math.rad(175), math.rad(6), math.rad(24), math.rad(-42)
local function armTurn(out) return CFrame.Angles(0, 0, ARM_OUT * out) * CFrame.Angles(ARM_UP, 0, 0) end
local POSE = {
	{part = "LeftUpperArm",  joint = "LeftShoulder",  turn = armTurn(1)},
	{part = "RightUpperArm", joint = "RightShoulder", turn = armTurn(-1)},
	{part = "LeftUpperLeg",  joint = "LeftHip",       turn = CFrame.Angles(HIP, 0, 0)},
	{part = "RightUpperLeg", joint = "RightHip",      turn = CFrame.Angles(HIP, 0, 0)},
	{part = "LeftLowerLeg",  joint = "LeftKnee",      turn = CFrame.Angles(KNEE, 0, 0)},
	{part = "RightLowerLeg", joint = "RightKnee",     turn = CFrame.Angles(KNEE, 0, 0)},
}
local function pose(char, r)
	for _, p in ipairs(POSE) do
		local part = char:FindFirstChild(p.part)
		local joint = part and part:FindFirstChild(p.joint)
		if joint then
			if joint:IsA("Motor6D") then r.c0[joint] = joint.C0; joint.C0 = joint.C0 * p.turn
			elseif joint:IsA("AnimationConstraint") and joint.Attachment0 then
				local att = joint.Attachment0
				r.att[att] = r.att[att] or att.CFrame
				att.CFrame = att.CFrame * p.turn
			end
		end
	end
end
local function finish(player)
	local r = riding[player]; if not r then return end
	riding[player] = nil
	if r.arm then arms[r.arm] = nil end
	local char = r.char
	if char and char.Parent then
		for joint, c0 in pairs(r.c0) do if joint.Parent then joint.C0 = c0 end end
		for att, cf in pairs(r.att) do if att.Parent then att.CFrame = cf end end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		char:SetAttribute("MillRiding", nil)
	end
end
-- the free arm that reaches the bottom of the sweep soonest, going the way the sails go
local function nextArm()
	local best, bestT
	for i = 1, 4 do
		local att = sails:FindFirstChild("Tip" .. i)
		if att and not arms[i] then
			local ahead = ((math.pi - angleOf(att)) * turn) % (2 * math.pi)
			if not bestT or ahead < bestT then best, bestT = i, ahead end
		end
	end
	return best, bestT and bestT / SPEED or nil
end
local function start(player)
	if riding[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then return end
	local pad = Vector3.new(F:GetAttribute("PadX"), F:GetAttribute("PadY"), F:GetAttribute("PadZ"))
	if (hrp.Position - pad).Magnitude > (F:GetAttribute("Reach") or 11) then ev:FireClient(player, "no", "Stand on the stone pad under the sails.") return end
	local arm, secs = nextArm()
	if not arm then ev:FireClient(player, "no", "Every sail has a rider - wait for one to come round.") return end
	riding[player] = {arm = arm, char = char, c0 = {}, att = {}, stage = "wait", since = os.clock()}
	arms[arm] = player
	char:SetAttribute("MillRiding", true)                              -- not "Riding": MapMusic mutes that one (the zipline wants quiet; Shannon wants the music on here)
	ev:FireClient(player, "wait", arm, secs)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "GrabPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	local r = riding[player]
	if not r then return end
	if what == "grab" and r.stage == "wait" then
		local hum = r.char and r.char:FindFirstChildOfClass("Humanoid")
		if not hum then finish(player) return end
		r.stage = "ride"; r.since = os.clock()
		hum.PlatformStand = true
		pose(r.char, r)
		local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"windmill",{}) end
		ev:FireClient(player, "ride")
		print(string.format("MillRide: %s grabbed sail %d", player.Name, r.arm))
	elseif what == "done" then
		print(string.format("MillRide: %s let go of sail %d after %.0fs", player.Name, r.arm, os.clock() - r.since))
		finish(player)
	end
end)
-- nobody stays stuck: a wait longer than a turn and a half, or a ride longer than a turn and some, is over
task.spawn(function()
	while true do
		task.wait(1)
		local lap = 2 * math.pi / SPEED
		for player, r in pairs(riding) do
			local limit = (r.stage == "wait") and lap * 1.5 or lap * (F:GetAttribute("Turns") or 1) + 6
			if os.clock() - r.since > limit or not (r.char and r.char.Parent) then
				ev:FireClient(player, "off")
				finish(player)
			end
		end
	end
end)
Players.PlayerRemoving:Connect(finish)
Players.PlayerAdded:Connect(function(p) p.CharacterRemoving:Connect(function() finish(p) end) end)
for _, p in ipairs(Players:GetPlayers()) do p.CharacterRemoving:Connect(function() finish(p) end) end
print("MillServer: ready - four sails, one rider each")
]==]

	-- ---------------------------------------------------------------- the ride: client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local F = script.Parent
local ev = RS:WaitForChild("MillRide")
local C = Color3.fromRGB
local sails
repeat
	local mill = workspace:WaitForChild("Domaine"):WaitForChild("Props"):FindFirstChild("windmill")
	sails = mill and mill:FindFirstChild("Sails", true)
	if not sails then task.wait(1) end
until sails
local HUB = Vector3.new(F:GetAttribute("HubX"), F:GetAttribute("HubY"), F:GetAttribute("HubZ"))
local N = Vector3.new(F:GetAttribute("LookX"), F:GetAttribute("LookY"), F:GetAttribute("LookZ"))
local E1 = Vector3.new(0, 1, 0)
local E2 = N:Cross(E1).Unit
local SPEED = F:GetAttribute("Speed") or 0.35
local HANG = F:GetAttribute("Hang") or 3.8
local function angleOf(att) local r = att.WorldPosition - HUB; return math.atan2(r:Dot(E2), r:Dot(E1)) end

-- a line at the foot of the screen, the game's own note style
local gui = Instance.new("ScreenGui"); gui.Name = "MillNote"; gui.ResetOnSpawn = false; gui.DisplayOrder = 6; gui.Parent = player:WaitForChild("PlayerGui")
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -72); note.Size = UDim2.fromOffset(460, 40)
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0; note.Font = Enum.Font.FredokaOne; note.TextSize = 18
note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local ns = Instance.new("UIStroke"); ns.Color = C(240, 200, 90); ns.Thickness = 1.5; ns.Transparency = 1; ns.Parent = note
local shownAt = 0
local function say(text, secs)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0; ns.Transparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(secs or 2.8, function()
		if shownAt ~= mine then return end
		local ti = TweenInfo.new(0.5)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(ns, ti, {Transparency = 1}):Play()
	end)
end

local BIND = "MillRide"
local bound = false
local function unbind() if bound then RunService:UnbindFromRenderStep(BIND); bound = false end end
local state = nil                                            -- {arm, att, stage, ...}

local function letGo(reason)
	local s = state; if not s then return end
	state = nil
	unbind()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
	ev:FireServer("done")
	if reason then say(reason) end
end

-- the sail's angle is predicted between replicated updates, so the rider moves smoothly at every frame rate
local function follow(s, dt)
	local obs = angleOf(s.att)
	if obs ~= s.lastObs then s.lastObs = obs; s.theta = obs; s.obsAt = os.clock() end
	local theta = s.theta + s.turn * SPEED * (os.clock() - s.obsAt)
	local P = HUB + N * s.off + (E1 * math.cos(theta) + E2 * math.sin(theta)) * s.rad
	return P, theta
end
local function beginWait(arm, secs)
	local att = sails:FindFirstChild("Tip" .. arm)
	if not att then return end
	local rv = att.WorldPosition - HUB
	local off = rv:Dot(N)
	local rad = (rv - N * off).Magnitude
	state = {arm = arm, att = att, stage = "wait", theta = angleOf(att), lastObs = nil, obsAt = os.clock(), off = off, rad = rad, turn = F:GetAttribute("Turn") or 1, travelled = 0}
	say(string.format("Sail %d is coming round - hold still...", arm), math.max(2, (secs or 3) + 1))
	unbind()
	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value - 1, function(dt)
		local s = state; if not s then unbind() return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum) or hum.Health <= 0 then letGo() return end
		local P, theta = follow(s, dt)
		if s.stage == "wait" then
			local pad = Vector3.new(F:GetAttribute("PadX"), F:GetAttribute("PadY"), F:GetAttribute("PadZ"))
			if ((hrp.Position - pad) * Vector3.new(1, 0, 1)).Magnitude > 9 then letGo("You wandered off the pad.") return end
			-- the tip is at the bottom when its angle is pi; grab it a touch before, so the lift feels like catching it
			local toBottom = ((math.pi - theta) * s.turn) % (2 * math.pi)
			if toBottom < 0.16 or toBottom > 2 * math.pi - 0.05 then
				s.stage = "grab"; s.grabAt = os.clock(); s.startCF = hrp.CFrame; s.theta0 = theta; s.lastTheta = theta
				hum.PlatformStand = true
				ev:FireServer("grab")
			end
		end
		if s.stage == "grab" or s.stage == "ride" then
			local target = CFrame.lookAt(P, P - N) * CFrame.new(0, -HANG, 0)         -- facing away from the tower
			local t = os.clock() - s.grabAt
			if t < 0.35 then hrp.CFrame = s.startCF:Lerp(target, t / 0.35) else s.stage = "ride"; hrp.CFrame = target end
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			local d = (theta - s.lastTheta + math.pi) % (2 * math.pi) - math.pi
			s.lastTheta = theta
			s.travelled += math.abs(d)
			if s.travelled >= 2 * math.pi * (F:GetAttribute("Turns") or 1) - 0.08 then letGo("Whee! All the way round.") end
		end
	end)
	bound = true
end
UIS.JumpRequest:Connect(function()
	local s = state
	if s and (s.stage == "ride") and os.clock() - s.grabAt > 1 then letGo("Let go!") end
end)
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "wait" then beginWait(a, b)
	elseif what == "ride" then if state and state.stage ~= "ride" then say("Hang on!") end
	elseif what == "off" then if state then state = nil; unbind(); local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand = false end end
	elseif what == "no" then say(a) end
end)
]==]
	local s = Instance.new("Script"); s.Name = "MillServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "MillClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print(string.format("MillRide: 4 tips %.1f from the hub at (%.1f,%.1f,%.1f), the sweep's bottom %.1f up; pad at (%.1f,%.1f,%.1f); hang %.1f; %s", radius, hub.X, hub.Y, hub.Z, hub.Y - radius, padSpot.X, g, padSpot.Z, F:GetAttribute("Hang"), "one turn a ride"))
	return F
end

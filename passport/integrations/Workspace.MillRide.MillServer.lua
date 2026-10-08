local Players = game:GetService("Players")
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

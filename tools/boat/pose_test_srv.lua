-- pose_test v1 (PLAY, SERVER, test only): is the rider pose code in the running BoatServer, and does a hip/knee bend set
-- on the server show on the first player's character? Bends for 4 s, prints, restores.
local src = workspace.Boat.BoatServer.Source
warn(string.format("QQ PT BoatServer has poseRider: %s; calls it after the chute: %s; version line: %s", tostring(src:find("local function poseRider", 1, true) ~= nil), tostring(src:find("poseRider(char, true)", 1, true) ~= nil), tostring(workspace.Boat:GetAttribute("Built"))))
local p = game.Players:GetPlayers()[1]
local c = p and p.Character
if not c then warn("QQ PT no character"); return end
local names = {}
for _, d in ipairs(c:GetDescendants()) do if d:IsA("Motor6D") then names[#names + 1] = d.Parent.Name .. "." .. d.Name end end
warn("QQ PT motors: " .. table.concat(names, ", "))
local function bend(partName, motorName, rot)
	local part = c:FindFirstChild(partName); local m = part and part:FindFirstChild(motorName)
	if not m then warn("QQ PT no motor " .. partName .. "." .. motorName); return end
	local ok, err = pcall(function() m:SetAttribute("ChuteC0", m.C0) end)
	if not ok then warn("QQ PT SetAttribute failed: " .. tostring(err)) end
	m.C0 = m.C0 * rot
	warn(string.format("QQ PT %s.%s C0 x-angle now %.0f deg, attribute set: %s", partName, motorName, math.deg(select(1, m.C0:ToEulerAnglesXYZ())), tostring(m:GetAttribute("ChuteC0") ~= nil)))
end
bend("LeftUpperLeg", "LeftHip", CFrame.Angles(math.rad(28), 0, 0)); bend("RightUpperLeg", "RightHip", CFrame.Angles(math.rad(28), 0, 0))
bend("LeftLowerLeg", "LeftKnee", CFrame.Angles(math.rad(-44), 0, 0)); bend("RightLowerLeg", "RightKnee", CFrame.Angles(math.rad(-44), 0, 0))
task.wait(4)
for _, pair in ipairs({{"LeftUpperLeg", "LeftHip"}, {"RightUpperLeg", "RightHip"}, {"LeftLowerLeg", "LeftKnee"}, {"RightLowerLeg", "RightKnee"}}) do
	local part = c:FindFirstChild(pair[1]); local m = part and part:FindFirstChild(pair[2])
	if m and m:GetAttribute("ChuteC0") then m.C0 = m:GetAttribute("ChuteC0"); m:SetAttribute("ChuteC0", nil) end
end
warn("QQ PT restored")

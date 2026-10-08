-- pose_test2 v1 (PLAY, SERVER, test only): bends the first player's hips and knees by rotating the parent-side rig
-- attachments (the new constraint joints have read-only C0), lists the joint objects, holds 4 s, restores.
local p = game.Players:GetPlayers()[1]
local c = p and p.Character
if not c then warn("QQ PT2 no character"); return end
local kinds = {}
for _, d in ipairs(c:GetDescendants()) do if d:IsA("AnimationConstraint") or d:IsA("Motor6D") or d:IsA("JointInstance") then kinds[#kinds + 1] = d.Parent.Name .. "." .. d.Name .. "[" .. d.ClassName .. "]" end end
warn("QQ PT2 joints: " .. table.concat(kinds, ", "))
local function bendAt(partName, attName, rot)
	local part = c:FindFirstChild(partName); local a = part and part:FindFirstChild(attName)
	if not a then warn("QQ PT2 no attachment " .. partName .. "." .. attName); return end
	a:SetAttribute("ChuteCF", a.CFrame)
	a.CFrame = a.CFrame * rot
end
local HIP, KNEE, ARM = math.rad(28), math.rad(-44), math.rad(160)
bendAt("LowerTorso", "LeftHipRigAttachment", CFrame.Angles(HIP, 0, 0)); bendAt("LowerTorso", "RightHipRigAttachment", CFrame.Angles(HIP, 0, 0))
bendAt("LeftUpperLeg", "LeftKneeRigAttachment", CFrame.Angles(KNEE, 0, 0)); bendAt("RightUpperLeg", "RightKneeRigAttachment", CFrame.Angles(KNEE, 0, 0))
bendAt("UpperTorso", "LeftShoulderRigAttachment", CFrame.Angles(ARM, 0, 0)); bendAt("UpperTorso", "RightShoulderRigAttachment", CFrame.Angles(ARM, 0, 0))
warn("QQ PT2 bent via attachments for 4 s")
task.wait(4)
for _, pair in ipairs({{"LowerTorso", "LeftHipRigAttachment"}, {"LowerTorso", "RightHipRigAttachment"}, {"LeftUpperLeg", "LeftKneeRigAttachment"}, {"RightUpperLeg", "RightKneeRigAttachment"}, {"UpperTorso", "LeftShoulderRigAttachment"}, {"UpperTorso", "RightShoulderRigAttachment"}}) do
	local part = c:FindFirstChild(pair[1]); local a = part and part:FindFirstChild(pair[2])
	if a and a:GetAttribute("ChuteCF") then a.CFrame = a:GetAttribute("ChuteCF"); a:SetAttribute("ChuteCF", nil) end
end
warn("QQ PT2 restored")

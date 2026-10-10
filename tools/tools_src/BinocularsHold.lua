local TweenService = game:GetService("TweenService")
local tool = script.Parent
local body = tool:WaitForChild("Body")
local F = workspace:WaitForChild("Binoculars")
local raise = F:WaitForChild("Raise")
local FWD = CFrame.Angles(0, math.rad(90), 0)
local BODY = CFrame.new(-0.4, 0, 0) * FWD                      -- the Body's place in the binoculars' own frame
local function cfg(name, default) local v = F:GetAttribute(name); return v ~= nil and v or default end
local function frames(j)                                       -- parent-side and child-side frames of a joint
	if j:IsA("Motor6D") then return j.C0, j.C1 end
	if j:IsA("AnimationConstraint") then return j.Attachment0 and j.Attachment0.CFrame or CFrame.new(), j.Attachment1 and j.Attachment1.CFrame or CFrame.new() end
	return nil
end
local function chestFrame(torso)
	return CFrame.new(0, cfg("ChestUp", 0.15), -(torso.Size.Z / 2 + cfg("ChestForward", 0.75))) * CFrame.Angles(math.rad(cfg("ChestTilt", -25)), 0, 0)
end
local function eyeFrame(torso, head)
	local neck = head:FindFirstChild("Neck")
	local n0, n1
	if neck then n0, n1 = frames(neck) end                    -- ("neck and frames(neck)" would keep only n0)
	local headF = (n0 and n1) and (n0 * n1:Inverse()) or CFrame.new(0, torso.Size.Y / 2 + head.Size.Y / 2, 0)
	return headF * CFrame.new(0, cfg("EyeUp", 0.05), -(head.Size.Z / 2 + cfg("EyeForward", 0.8)))
end
local weld, holder, tween
local function down()
	if tween then tween:Cancel(); tween = nil end
	if weld then weld:Destroy(); weld = nil end
	if holder then holder:SetAttribute("BinocularsUp", nil); holder = nil end
end
local function up(char)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso then return end
	down()
	weld = Instance.new("Weld"); weld.Name = "HoldWeld"; weld.Part0 = torso; weld.Part1 = body
	weld.C0 = chestFrame(torso) * BODY; weld.C1 = CFrame.new(); weld.Parent = body
	holder = char
	char:SetAttribute("BinocularsUp", "chest")
end
local function setRaised(on)
	if not (weld and holder) then return end
	local torso, head = weld.Part0, holder:FindFirstChild("Head")
	if not (torso and head) then return end
	if tween then tween:Cancel() end
	tween = TweenService:Create(weld, TweenInfo.new(cfg("ZoomTime", 0.25), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C0 = (on and eyeFrame(torso, head) or chestFrame(torso)) * BODY})
	tween:Play()
	holder:SetAttribute("BinocularsUp", on and "eyes" or "chest")
end
tool.Equipped:Connect(function()
	local char = tool.Parent
	if char and char:FindFirstChildOfClass("Humanoid") then up(char) end
end)
tool.Unequipped:Connect(down)
tool.AncestryChanged:Connect(function() if not tool:IsDescendantOf(game) then down() end end)
raise.OnServerEvent:Connect(function(pl, on)
	if holder and pl.Character == holder then setRaised(on == true) end
end)

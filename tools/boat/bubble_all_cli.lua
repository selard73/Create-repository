-- bubble_all v1 (PLAY, CLIENT, test only): the one bubble on three speakers - the Sky Diving Squirrel through his Talk
-- prompt (the real path), a Baguette chase squirrel and a lagoon squirrel through the module directly (their real triggers
-- are a click and a rescue). The camera is parked on each for a look.
local plr = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local ok, Bubble = pcall(function() return require(RS:WaitForChild("SquirrelBubble", 5)) end)
warn("QQ BA module: " .. tostring(ok) .. " " .. tostring(Bubble ~= nil))
local cam = workspace.CurrentCamera
local ch = plr.Character
-- 1. the Sky Diving Squirrel, the real way
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if mesh then
	local hum = ch:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
	ch:PivotTo(CFrame.lookAt(mesh.Position + Vector3.new(3.5, 1.5, 5), mesh.Position))
	task.wait(1.2)
	local sp = mesh:FindFirstChild("ChutePrompt")
	if sp then sp.MaxActivationDistance = 30; sp:InputHoldBegin(); task.wait(0.5); sp:InputHoldEnd() end
	task.wait(0.4)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(mesh.Position + Vector3.new(-5, 1.0, 9), mesh.Position + Vector3.new(1.5, 1.6, 0))
	task.wait(3.5)
	cam.CameraType = Enum.CameraType.Custom
end
-- 2. a chase squirrel (any model under Baguette with a ClickDetector)
local chase = nil
for _, d in ipairs(workspace.Baguette:GetDescendants()) do
	if d:IsA("ClickDetector") then local m = d:FindFirstAncestorOfClass("Model"); if m and m ~= workspace.Baguette then chase = m; break end end
end
if chase and Bubble then
	local part = chase.PrimaryPart or chase:FindFirstChildWhichIsA("BasePart", true)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(part.Position + Vector3.new(-5, 2, 8), part.Position + Vector3.new(1, 1, 0))
	Bubble.say(chase, "A fresh baguette at the Boulangerie - vite!", {secs = 3.5})
	warn("QQ BA chase squirrel: " .. chase:GetFullName())
	task.wait(3.5)
	cam.CameraType = Enum.CameraType.Custom
else
	warn("QQ BA no chase squirrel found")
end
-- 3. a lagoon squirrel
local lagoon = workspace:FindFirstChild("Lagoon")
local lsq = nil
if lagoon then for _, d in ipairs(lagoon:GetDescendants()) do if d:IsA("Model") and d.Name:lower():find("squirrel") then lsq = d; break end end end
if lsq and Bubble then
	local part = lsq.PrimaryPart or lsq:FindFirstChildWhichIsA("BasePart", true)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(part.Position + Vector3.new(-5, 2, 8), part.Position + Vector3.new(1, 1, 0))
	Bubble.say(lsq, "Thank you for saving Madame Margaux's petits enfants!", {secs = 4.5})
	warn("QQ BA lagoon squirrel: " .. lsq:GetFullName())
	task.wait(4.5)
	cam.CameraType = Enum.CameraType.Custom
else
	warn("QQ BA no lagoon squirrel found")
end
warn("QQ BA done")

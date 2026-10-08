-- t26_cam_cli.lua v2 (PLAY, CLIENT view): Shannon's character just behind the launch arch, facing down the ramp, and the
-- camera turned off to one side: straight behind her, the bell gable (7.8 studs back, right on the ramp's line) hides
-- everything. Tries the side angles in turn and keeps the first with nothing between her head and the camera.
local cam = workspace.CurrentCamera
local G = workspace.HangGlider
local dir = Vector3.new(G:GetAttribute("RampDirX"), 0, G:GetAttribute("RampDirZ")).Unit
local B = Vector3.new(G:GetAttribute("RampX"), G:GetAttribute("RampY"), G:GetAttribute("RampZ"))
local char = game.Players.LocalPlayer.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local at = B - dir * 1.6 + Vector3.new(0, 3.2, 0)
hrp.AssemblyLinearVelocity = Vector3.zero
char:PivotTo(CFrame.lookAt(at, at + dir))
task.wait(0.3)
local head = char:WaitForChild("Head")
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {char}
local picked
for _, deg in ipairs({-45, -55, -35, 45, 55, 35, -70, 70}) do
	local look = (CFrame.Angles(0, math.rad(deg), 0):VectorToWorldSpace(dir) + Vector3.new(0, -0.22, 0)).Unit
	local camPos = head.Position - look * 13
	if not workspace:Raycast(head.Position, camPos - head.Position, rp) then
		picked = deg
		cam.CameraType = Enum.CameraType.Custom
		cam.CFrame = CFrame.lookAt(camPos, head.Position)
		break
	end
end
task.wait(0.5)
local c = cam.CFrame.Position
warn(string.format("QQ T26C v2 - yaw %s | camera (%.1f, %.1f, %.1f), %.1f from the head", tostring(picked), c.X, c.Y, c.Z, (c - head.Position).Magnitude))

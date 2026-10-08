-- v27 check tour: bank tops (seam), bridge east landing, bend, south stretch; 6 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 60
local views = {
	{Vector3.new(152, 4, -40), Vector3.new(157, -1, -75)},
	{Vector3.new(174, 5, -127), Vector3.new(165, 0.3, -120)},
	{Vector3.new(196, 9, -44), Vector3.new(160, -1, -24)},
	{Vector3.new(176, 12, -176), Vector3.new(152, -1, -208)},
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(6)
end

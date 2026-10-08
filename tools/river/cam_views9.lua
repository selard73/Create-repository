-- v53 check: forest waterline by the bridge, gallery edge, forest bank wide; 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(152, 2.5, -86), Vector3.new(145, -0.6, -100)},
	{Vector3.new(180, 3, -2), Vector3.new(192, 0.8, -12)},
	{Vector3.new(128, 5, -80), Vector3.new(140, -0.5, -100)},
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(5)
end

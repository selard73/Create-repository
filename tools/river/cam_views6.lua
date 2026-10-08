-- v40 look at the rocks at the bend + the fishing squirrel, 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(158, 1.5, -20), Vector3.new(165, -0.6, -27)},
	{Vector3.new(160, 2, -50), Vector3.new(165.6, 0.3, -55)},
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(5)
end

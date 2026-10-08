-- v61 check: under the paving at both quay ends, the street by the bridge, the easels from the water side; 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(161, 1.2, -62), Vector3.new(167, 0, -70)},
	{Vector3.new(161, 1.2, -178), Vector3.new(167, 0, -170)},
	{Vector3.new(172, 3, -128), Vector3.new(166, 0.3, -116)},
	{Vector3.new(183, 2.5, -20), Vector3.new(192, 1, -8)},
	{Vector3.new(170, 14, -12), Vector3.new(190, 0, -10)},
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(5)
end

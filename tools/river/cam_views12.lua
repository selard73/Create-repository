-- v71 check: walkway end at the gate (grass?), cap under the bridge from the water, kerb from the forest side; 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(131, 3.5, -117), Vector3.new(141, 0.3, -120)},
	{Vector3.new(152, 1.5, -132), Vector3.new(144, 0, -121)},
	{Vector3.new(132, 2.5, -134), Vector3.new(144, 0.3, -122)},
	{Vector3.new(133, 2.5, -104), Vector3.new(144, 0.3, -118)},
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(5)
end

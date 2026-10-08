-- v68 forest-side bridge end: from the water (like Shannon's shot), from the walkway, from the south bank; 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(152, 1.5, -132), Vector3.new(144, 0, -121)},
	{Vector3.new(128, 4, -120), Vector3.new(146, 0, -120)},
	{Vector3.new(150, 3, -142), Vector3.new(144, 0, -118)},
	{Vector3.new(150, 3, -98), Vector3.new(144, 0, -122)},
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(5)
end

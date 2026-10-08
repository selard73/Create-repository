-- v8 editor camera tour of the new river: 4 views, 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 60
local views = {
	{Vector3.new(185, 14, -150), Vector3.new(156, -1, -120)},   -- bridge from the village bank, south side
	{Vector3.new(200, 12, -60), Vector3.new(160, -1, -30)},     -- the bend + rock islet, painter behind
	{Vector3.new(156, 3, -80), Vector3.new(156, -1, -118)},     -- down at the water, looking downstream at the bridge
	{Vector3.new(175, 22, -150), Vector3.new(160, -2, -205)},   -- the south stretch toward the exit
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	print("QQ view", i)
	task.wait(5)
end

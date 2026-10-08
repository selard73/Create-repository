-- v19 bank tour: 5 views, 6 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 60
local views = {
	{Vector3.new(128, 9, -100), Vector3.new(160, -1, -126)},    -- west (forest) bank + bridge from the forest side
	{Vector3.new(196, 9, -44), Vector3.new(160, -1, -24)},      -- the bend by the painter, natural banks + rock islet
	{Vector3.new(150, 6, -40), Vector3.new(170, -1, -60)},      -- fishing squirrel on his bank
	{Vector3.new(176, 12, -176), Vector3.new(152, -1, -208)},   -- south stretch, quay end -> natural bank -> exit
	{Vector3.new(158, 10, -142), Vector3.new(169, 0.5, -134)},  -- the Daily Question board by the quay
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	print("QQ view", i)
	task.wait(6)
end

-- v49 close-up tour after v47-v48, 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(152, 2.5, -86), Vector3.new(145, -0.6, -100)},    -- 1 forest-side waterline, close
	{Vector3.new(172, 3, -200), Vector3.new(160, -0.6, -215)},    -- 2 south stretch waterline, close
	{Vector3.new(158, 1.5, -20), Vector3.new(165, -0.8, -27)},    -- 3 rocks at the bend
	{Vector3.new(160, 2, -50), Vector3.new(165.6, 0.6, -55)},     -- 4 fishing squirrel on his rocks
	{Vector3.new(158, 2, -62), Vector3.new(164, 0, -70)},         -- 5 quay north end
	{Vector3.new(158, 2, -180), Vector3.new(164, 0, -171)},       -- 6 quay south end
	{Vector3.new(180, 3, -2), Vector3.new(192, 0.8, -12)},        -- 7 painter, easel, gallery
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(5)
end

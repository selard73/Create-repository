-- v46 close-up tour after v43-v45, 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(128, 5, -80), Vector3.new(140, -0.5, -100)},     -- 1 forest-side bank: one ground?
	{Vector3.new(120, 3, -140), Vector3.new(146, -0.5, -150)},    -- 2 forest bank south of the bridge
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

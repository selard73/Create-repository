-- v38 close-up tour of Shannon's six spots, 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 55
local views = {
	{Vector3.new(160, 2.5, -132), Vector3.new(165, 0.5, -120)},  -- 1 kerb under the bridge
	{Vector3.new(128, 5, -80), Vector3.new(140, -0.5, -100)},     -- 2 forest-side bank top (the seam)
	{Vector3.new(158, 1.5, -20), Vector3.new(165, -0.6, -27)},    -- 3 the rocks at the bend
	{Vector3.new(160, 2, -50), Vector3.new(165.6, 0.3, -55)},     -- 4 fishing squirrel
	{Vector3.new(182, 2.5, -14), Vector3.new(187, 0.4, -20)},     -- 5 painter + his easel
	{Vector3.new(180, 3, -2), Vector3.new(195, 0.8, -10)},        -- 6 gallery easels by the water
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	task.wait(5)
end

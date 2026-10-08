-- v9 terrain colours + 3 more views, 6 s apart
local T = workspace.Terrain
for _, m in ipairs({"Sand", "Mud", "Rock", "Grass", "Ground"}) do print("QQ col", m, T:GetMaterialColor(Enum.Material[m]):ToHex()) end
print("QQ bankcol", workspace.Village.Props.river.BankL.Color:ToHex(), workspace.Village.Props.river.BankL.Material.Name)
local cam = workspace.CurrentCamera
cam.FieldOfView = 60
local views = {
	{Vector3.new(150, 30, -10), Vector3.new(168, -1, -30)},     -- the rock islet at the bend, from above
	{Vector3.new(172, 20, -160), Vector3.new(158, -2, -210)},   -- the south stretch toward the exit
	{Vector3.new(146, 1.5, -100), Vector3.new(164, -3, -104)},  -- the east bank, eye level, across the water
}
for i, v in ipairs(views) do
	cam.CFrame = CFrame.lookAt(v[1], v[2])
	print("QQ view", i)
	task.wait(6)
end

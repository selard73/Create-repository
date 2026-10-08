-- gorge_cam3: moves ONLY the editor camera: prints the current camera first (to put it back), then view A (overview)
local cam = workspace.CurrentCamera
print("QQ GC3 CAM", cam.FieldOfView, table.concat({cam.CFrame:GetComponents()}, ","))
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(430, 230, -70), Vector3.new(250, 10, -470))

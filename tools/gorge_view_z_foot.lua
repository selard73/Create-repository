-- gorge_view_z_foot: moves ONLY the editor camera (from the cove shore on the plain, 4 studs up, looking at the foot of the falls)
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(196.0, -43.0, -608.0), Vector3.new(185.4, -46.0, -556.0))

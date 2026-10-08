-- gorge_cam2: moves ONLY the editor camera: high oblique over the south rim and the river channel beyond
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(260, 260, -60), Vector3.new(180, 0, -480))
print("QQ GC2 set")

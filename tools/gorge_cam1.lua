-- gorge_cam1: moves ONLY the editor camera: boater's-eye view from the jetty looking south over the rim
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(160, 6, -150), Vector3.new(185, 2, -300))
print("QQ GC1 set")

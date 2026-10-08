-- gorge_cam3b: moves ONLY the editor camera: view B, from the jetty looking south
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(158, 7, -150), Vector3.new(188, 12, -300))

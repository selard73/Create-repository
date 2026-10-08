-- gorge_view_c_high: moves ONLY the editor camera
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(250, 120, -300), Vector3.new(130, 0, -420))

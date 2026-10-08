-- gorge_view_x_rapidshead: moves ONLY the editor camera (in the boat lane 24 studs below the rapids head, looking upstream at the boulder line)
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(199.5, 3.0, -519.0), Vector3.new(197.3, -1.0, -494.0))

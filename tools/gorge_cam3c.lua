-- gorge_cam3c: moves ONLY the editor camera: view C, over the basin where the aqueduct will stand
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(150, 70, -320), Vector3.new(110, 0, -390))

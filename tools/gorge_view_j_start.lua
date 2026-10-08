-- gorge_view_j_start: moves ONLY the editor camera: Shannon's starting view for the close-up round (aqueduct + basin)
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(178, 52, -326), Vector3.new(110, 14, -386))
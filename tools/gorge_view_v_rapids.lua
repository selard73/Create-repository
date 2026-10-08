-- gorge_view_v_rapids: moves ONLY the editor camera (over the last 40 studs of river, looking down at the brink)
local cam = workspace.CurrentCamera
cam.FieldOfView = 60
cam.CFrame = CFrame.lookAt(Vector3.new(190.0, 26.0, -492.0), Vector3.new(183.8, -2.0, -542.0))

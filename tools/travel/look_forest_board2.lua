-- look_forest_board2: editor camera close on the forest travel board, from the dais side (read-only; restore with cam_restore_shannon4)
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.lookAt(Vector3.new(3.5, 4.2, 5.5), Vector3.new(10.5, 2.6, 1))
print("QQ LK forest board close")

-- cam_save: READ-ONLY. Prints the editor camera so it can be put back exactly (paste the QQ CAM line's CFrame into a restore script).
local cam = workspace.CurrentCamera
local c = cam.CFrame
print(string.format("QQ CAM FOV %.2f CFrame.new(%s)", cam.FieldOfView, table.concat({c:GetComponents()}, ",")))
print("QQ CAM DONE")

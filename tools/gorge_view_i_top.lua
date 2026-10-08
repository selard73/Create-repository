-- gorge_view_i_top: moves ONLY the editor camera: close top-down look at the west rim's top strip at z -300
local cam = workspace.CurrentCamera
cam.FieldOfView = 60
cam.CFrame = CFrame.lookAt(Vector3.new(141, 60, -286), Vector3.new(147, 41, -302))
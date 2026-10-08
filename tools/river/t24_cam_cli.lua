-- v24 (PLAY, CLIENT): camera low over the water looking downstream for 10 s, then back to normal
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
cam.FieldOfView = 55
cam.CFrame = CFrame.lookAt(Vector3.new(152, 4, -40), Vector3.new(157, -1, -75))
task.wait(10)
cam.CFrame = CFrame.lookAt(Vector3.new(170, 7, -20), Vector3.new(160, -1, -45))
task.wait(8)
cam.CameraType = Enum.CameraType.Custom
cam.FieldOfView = 70

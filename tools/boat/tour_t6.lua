-- t6 camera-only: top-down and bow-on views of the bow line (no edits)
local cam = workspace.CurrentCamera
cam.FieldOfView = 30
cam.CFrame = CFrame.lookAt(Vector3.new(159.2, 9, -168.6), Vector3.new(159.2, 0.4, -168.61))   -- straight down
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(160.5, 1.3, -174.5), Vector3.new(158.9, 0.5, -168.5))   -- low, from past the bow
print("QQ DONE t6")

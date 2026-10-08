-- t12 camera-only: wider view of the stern line from the water, then restore Shannon's editor camera (no edits)
local cam = workspace.CurrentCamera
cam.FieldOfView = 35
cam.CFrame = CFrame.lookAt(Vector3.new(155.2, 2.4, -159.6), Vector3.new(159.4, 0.6, -163.8))
task.wait(5)
cam.FieldOfView = 70
cam.CFrame = CFrame.new(474.600006, 85.4792938, -230, 0.923076928, 0.125811741, -0.36345616, -0, 0.944986045, 0.327110529, 0.384615362, -0.30194819, 0.872294784)
print("QQ DONE t12 camera restored")

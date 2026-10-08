-- t2 camera-only tour of the still boat (no edits): 3 views, 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 45
cam.CFrame = CFrame.lookAt(Vector3.new(150, 1.2, -162), Vector3.new(158, 0, -157))        -- low on the water, from the south-west
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(163, 7, -150), Vector3.new(157.6, -0.5, -157.5))   -- from the jetty, looking down into it
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(151, 3, -147), Vector3.new(159, 0.5, -157))        -- bow on, dummy for scale
print("QQ DONE t2")
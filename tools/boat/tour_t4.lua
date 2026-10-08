-- t4 camera-only close-ups of the bow ring and the stern cleat (no edits)
local cam = workspace.CurrentCamera
cam.FieldOfView = 30
cam.CFrame = CFrame.lookAt(Vector3.new(161.2, 2.2, -171.8), Vector3.new(158.3, 0.55, -170.2))   -- bow ring, from the jetty end
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(161.8, 2.6, -165.3), Vector3.new(159.1, 0.5, -163.8))    -- stern cleat, from the jetty
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(156.5, 3.4, -160.5), Vector3.new(159.1, 0.5, -163.9))    -- cleat from inside/behind the boat
print("QQ DONE t4")

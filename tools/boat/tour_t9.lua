-- t9 camera-only close-ups of the stern line and cleat (no edits)
local cam = workspace.CurrentCamera
local cl = Vector3.new(159.08, 0.52, -163.78)
cam.FieldOfView = 14
cam.CFrame = CFrame.lookAt(cl + Vector3.new(2.3, 0.0, -0.3), cl)                    -- dead level from outside the boat
task.wait(5)
cam.FieldOfView = 25
cam.CFrame = CFrame.lookAt(cl + Vector3.new(1.4, 1.3, -1.6), cl + Vector3.new(0.3, 0, 0.1))    -- from above, toward the jetty post
task.wait(5)
cam.CFrame = CFrame.lookAt(cl + Vector3.new(-1.3, 1.2, 1.2), cl)                   -- from inside the boat, behind
task.wait(5)
cam.FieldOfView = 40
cam.CFrame = CFrame.lookAt(Vector3.new(163.2, 3.0, -158.8), Vector3.new(159.6, 0.5, -163.4))   -- wider, from the jetty
print("QQ DONE t9")

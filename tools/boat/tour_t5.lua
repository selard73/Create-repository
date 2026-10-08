-- t5 camera-only views of the knot, the whole mooring and the stern (no edits)
local cam = workspace.CurrentCamera
cam.FieldOfView = 30
cam.CFrame = CFrame.lookAt(Vector3.new(161.2, 2.2, -171.8), Vector3.new(158.3, 0.55, -170.2))   -- bow, from the jetty end
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(158.9, 2.0, -172.4), Vector3.new(158.4, 0.55, -170.3))   -- bow, from in front
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(161.8, 2.6, -165.3), Vector3.new(159.1, 0.5, -163.8))    -- stern cleat
task.wait(5)
cam.FieldOfView = 45
cam.CFrame = CFrame.lookAt(Vector3.new(150, 3.5, -176), Vector3.new(158.5, 0.2, -165))         -- whole boat
print("QQ DONE t5")

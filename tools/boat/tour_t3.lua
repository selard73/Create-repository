-- t3 camera-only close-ups of the mooring ropes (no edits)
local cam = workspace.CurrentCamera
cam.FieldOfView = 40
cam.CFrame = CFrame.lookAt(Vector3.new(163.5, 5.5, -172.5), Vector3.new(159, 0.5, -166))   -- from the street corner, down onto the bow line
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(162.5, 4.2, -158), Vector3.new(158.8, 0.4, -164))    -- from the jetty, stern line + motor
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(152, 1.5, -175), Vector3.new(158, 0.4, -165))        -- low from the water, bow on
print("QQ DONE t3")
-- t1 camera-only tour of the jetty (no edits): 3 views, 5 s apart
local cam = workspace.CurrentCamera
cam.FieldOfView = 50
cam.CFrame = CFrame.lookAt(Vector3.new(171, 6.5, -178), Vector3.new(162, 0.8, -160))       -- from the street, south end
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(168.5, 3.4, -167.3), Vector3.new(162.6, 2.4, -167.3)) -- sign front
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(154, -0.4, -150), Vector3.new(162, -0.2, -157))      -- water level, under the boards
task.wait(5)
cam.CFrame = CFrame.lookAt(Vector3.new(161.9, 9, -140), Vector3.new(161.9, 0.5, -155))      -- down the deck
print("QQ DONE t1")

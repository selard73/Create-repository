-- t11 camera-only: 3/4 close-up of the stern cleat hitch + the stern line from the jetty (no edits)
local p = workspace.River.BoatPreview.Fittings:FindFirstChild("CleatBar").Position
local cam = workspace.CurrentCamera
cam.FieldOfView = 28
cam.CFrame = CFrame.lookAt(p + Vector3.new(1.3, 1.25, -1.1), p + Vector3.new(0, 0, 0.05))
task.wait(5)
cam.FieldOfView = 40
cam.CFrame = CFrame.lookAt(Vector3.new(162.6, 2.6, -167.6), Vector3.new(159.4, 0.5, -163.6))
print("QQ DONE t11")

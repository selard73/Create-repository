-- t10 camera-only: straight down on the stern cleat, then dead level from outboard (no edits)
local M = workspace.River.BoatPreview
local bar = M.Fittings:FindFirstChild("CleatBar")
local p = bar.Position
local cam = workspace.CurrentCamera
cam.FieldOfView = 25
cam.CFrame = CFrame.lookAt(p + Vector3.new(0, 2.6, 0.001), p)
task.wait(5)
cam.FieldOfView = 18
cam.CFrame = CFrame.lookAt(p + Vector3.new(2.4, 0.02, -0.2), p)
print("QQ DONE t10 bar " .. tostring(p) .. " look " .. tostring(bar.CFrame.RightVector))

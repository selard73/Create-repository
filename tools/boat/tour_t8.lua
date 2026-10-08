-- t8 camera-only: dead-level side-on look at the bow ring plate (no edits)
local M = workspace.River.BoatPreview
local plate = M.Fittings:FindFirstChild("BowPlate")
local p = plate.Position
local n = plate.CFrame.RightVector
local cam = workspace.CurrentCamera
cam.FieldOfView = 12
cam.CFrame = CFrame.lookAt(p + n * 2.2 + Vector3.new(0, 0.0, 0), p)
print("QQ DONE t8 plate top y " .. string.format("%.3f", p.Y + plate.Size.Y / 2))

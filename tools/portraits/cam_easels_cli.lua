-- v16 (PLAY, CLIENT view): stand back from the first four easels, square to their faces
local cam = workspace.CurrentCamera
local S = workspace.PortraitGallery.Slots
local c1, c4 = S.Slot1:FindFirstChild("Canvas", true), S.Slot4:FindFirstChild("Canvas", true)
local n = c1.CFrame:VectorToWorldSpace(Vector3.FromNormalId(c1.Picture.Face))
local mid = (c1.Position + c4.Position) / 2
cam.CameraType = Enum.CameraType.Scriptable
cam.FieldOfView = 50
cam.CFrame = CFrame.lookAt(mid + n * 9.5 + Vector3.new(0, 1.0, 0), mid + Vector3.new(0, 0.2, 0))
warn("QQ P13 camera on easels 1-4")

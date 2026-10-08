-- river_look v1 (PLAY, CLIENT, test only): parks the camera low over the river just downstream of the jetty for 3 s so the
-- drifting leaves and twigs can be seen, then gives the camera back.
local cam = workspace.CurrentCamera
local folder = workspace:FindFirstChild("RiverDrift")
local n, sample = 0, {}
if folder then for _, p in ipairs(folder:GetChildren()) do n += 1; if #sample < 3 then sample[#sample + 1] = string.format("(%.0f,%.0f,%.0f)", p.Position.X, p.Position.Y, p.Position.Z) end end end
warn(string.format("QQ RL drifters %d, e.g. %s", n, table.concat(sample, " ")))
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CFrame.lookAt(Vector3.new(150, 5, -200), Vector3.new(153, -1, -222))
task.wait(3)
cam.CFrame = CFrame.lookAt(Vector3.new(158, 9, -240), Vector3.new(152, -1, -262))
task.wait(3)
cam.CameraType = Enum.CameraType.Custom
warn("QQ RL camera back")

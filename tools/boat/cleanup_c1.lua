-- c1 cleanup after the boat pictures: delete the temporary scale dummy, restore Shannon's editor camera
local d = workspace:FindFirstChild("ScaleDummy_temp"); if d then d:Destroy() end
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.new(474.600006, 85.4792938, -230, 0.923076928, 0.125811741, -0.36345616, -0, 0.944986045, 0.327110529, 0.384615362, -0.30194819, 0.872294784)
print("QQ DONE c1 dummy gone: " .. tostring(workspace:FindFirstChild("ScaleDummy_temp") == nil))
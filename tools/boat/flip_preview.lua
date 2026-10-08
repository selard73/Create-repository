-- p2 turn the still boat 180 so the bow faces upstream (motor to the south)
local mp = workspace.River.BoatPreview:FindFirstChildWhichIsA("MeshPart", true)
mp.CFrame = mp.CFrame * CFrame.Angles(0, math.pi, 0)
print("QQ DONE p2 " .. tostring(mp.CFrame.LookVector))
-- falls_test3: TEMPORARY. Rapids back to flat (FaceCamera false) with ZOffset 6 so they sort in front of the river
-- surface; the test rig from falls_test2 removed.
local F = workspace.SouthGorge.Falls
local t = F:FindFirstChild("FallsTestRig"); if t then t:Destroy() end
local n = 0
for _, b in ipairs(F:GetDescendants()) do
	if b:IsA("Beam") and b.Name:sub(1, 6) == "Rapids" then b.FaceCamera = false; b.ZOffset = 6; n += 1 end
end
print(string.format("QQ FT3 %d rapids beams flat again with ZOffset 6; test rig removed", n))
print("QQ FT3 DONE")

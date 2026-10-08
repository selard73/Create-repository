-- falls_lipview1 v1 (EDIT): parks the editor camera where the going-over camera sits as the boat leaves the brink (her
-- "weird angled extra sheet of water" report) and lists every part and beam of SouthGorge.FallsB and Falls, so the stray
-- sheet can be named. Read-only apart from the camera (cam_restore_shannon4.lua puts hers back).
local cam = workspace.CurrentCamera
cam.CFrame = CFrame.lookAt(Vector3.new(152, 9, -564), Vector3.new(184, -1, -548))
cam.Focus = CFrame.new(184, -1, -548)
local SG = workspace:FindFirstChild("SouthGorge")
for _, name in ipairs({"FallsB", "Falls"}) do
	local f = SG and SG:FindFirstChild(name)
	if f then
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("BasePart") then
				print(string.format("QQ LV %s.%s [%s] size %.1fx%.1fx%.1f at (%.1f,%.1f,%.1f) transp %.2f", name, d.Name, d.ClassName, d.Size.X, d.Size.Y, d.Size.Z, d.Position.X, d.Position.Y, d.Position.Z, d.Transparency))
			elseif d:IsA("Beam") then
				local a0, a1 = d.Attachment0, d.Attachment1
				print(string.format("QQ LV %s.%s [Beam] on=%s facecam=%s w %.1f/%.1f segs %d from (%s) to (%s)", name, d.Name, tostring(d.Enabled), tostring(d.FaceCamera), d.Width0, d.Width1, d.Segments, a0 and tostring(a0.WorldPosition) or "?", a1 and tostring(a1.WorldPosition) or "?"))
			end
		end
	else
		print("QQ LV no " .. name)
	end
end
print("QQ LV DONE")

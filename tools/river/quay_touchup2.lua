-- v72 forest-side quay: white kerb back to a top edge (0.2..0.75) + a white skirt only on the LAND side (x 142.6..143.05,
-- down to -1) so the forest sees white, the water sees stone under a white top; the cap under the deck made a thin top
local Q = workspace.River.Quay
local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("QuayTouchup2")
local function set(p, x0, x1, y0, y1, z0, z1)
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
end
local n = 0
for _, p in ipairs(Q:GetChildren()) do
	if p.Name == "KerbSkirtW" then p:Destroy() end
end
for _, p in ipairs(Q:GetChildren()) do
	if p.Name == "KerbW" then
		local z0, z1 = p.Position.Z - p.Size.Z / 2, p.Position.Z + p.Size.Z / 2
		set(p, 142.6, 144.5, 0.2, 0.75, z0, z1)
		local s = p:Clone(); s.Name = "KerbSkirtW"; s.Parent = Q
		set(s, 142.6, 143.05, -1.0, 0.25, z0, z1)
		n += 1
	elseif p.Name == "CapW" then
		local z0, z1 = p.Position.Z - p.Size.Z / 2, p.Position.Z + p.Size.Z / 2
		local top = p.Position.Y + p.Size.Y / 2
		set(p, 143.95, 144.5, 0.0, top, z0, z1)
	end
end
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
print("QQ touchup2", n)
local cam = workspace.CurrentCamera
cam.CFrame = CFrame.lookAt(Vector3.new(152, 1.5, -132), Vector3.new(144, 0, -121))
task.wait(4)
cam.CFrame = CFrame.lookAt(Vector3.new(132, 2.5, -134), Vector3.new(144, 0.3, -122))

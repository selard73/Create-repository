-- v65 move the bridge gate (Gates.VillageGate) 4 studs west onto land, posts reach down into the ground; the sign
-- another 3 studs west so it stays clear of the gate; camera on it
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local gate, sign
for _, d in ipairs(workspace:GetDescendants()) do
	if d.Parent and d.Parent.Name == "Gates" then
		if d.Name == "VillageGate" then gate = d elseif d.Name == "SignVillage" then sign = d end
	end
end
if not gate or not sign then P("STOP", gate, sign) return end
local CHS = game:GetService("ChangeHistoryService")
local rec = CHS:TryBeginRecording("MoveGate")
gate:PivotTo(gate:GetPivot() + Vector3.new(-4, 0, 0))
sign:PivotTo(sign:GetPivot() + Vector3.new(-3, 0, 0))
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = {workspace.Terrain, workspace.Baseplate, workspace.Village.Ground}; rp.IgnoreWater = true
local n = 0
for _, p in ipairs(gate:GetDescendants()) do
	if p:IsA("BasePart") and p.Transparency < 1 and p.Size.Y > 2.5 then
		local bottom = p.Position.Y - p.Size.Y / 2
		if bottom < 1.5 then
			local h = workspace:Raycast(Vector3.new(p.Position.X, bottom + 2, p.Position.Z), Vector3.new(0, -12, 0), rp)
			if h and h.Position.Y < bottom + 0.3 then
				local ext = bottom - h.Position.Y + 0.3                          -- reach 0.3 into the ground
				if ext > 0 and ext < 3 then
					p.Size = p.Size + Vector3.new(0, ext, 0)
					p.CFrame = p.CFrame - Vector3.new(0, ext / 2, 0)
					n += 1
					P("post", p.Name, string.format("%.1f,%.1f", p.Position.X, p.Position.Z), string.format("extended %.2f", ext))
				end
			end
		end
	end
end
if rec then CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
local cf = gate:GetBoundingBox()
P("gate now", string.format("%.1f,%.1f", cf.Position.X, cf.Position.Z), n, "posts")
local cam = workspace.CurrentCamera
cam.CFrame = CFrame.lookAt(Vector3.new(131, 6, -106), Vector3.new(141, 0, -120))

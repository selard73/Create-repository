-- b4 READ-ONLY: restore Shannon's editor camera + check the wire over the river near z -170
local cam = workspace.CurrentCamera
cam.FieldOfView = 70
cam.CFrame = CFrame.new(474.600006, 85.4792938, -230, 0.923076928, 0.125811741, -0.36345616, -0, 0.944986045, 0.327110529, 0.384615362, -0.30194819, 0.872294784)
local rp = RaycastParams.new(); rp.IgnoreWater = true; rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {workspace.Terrain}
for _, x in ipairs({148, 152, 156, 160, 163}) do
	for z = -150, -200, -2 do
		local r = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -79, 0), rp)
		if r and r.Position.Y > 2 then print(("QQ OVER %d %d %s %.1f"):format(x, z, r.Instance:GetFullName(), r.Position.Y)) end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do
	if (d:IsA("Beam") or d:IsA("RopeConstraint")) then
		local a0 = d:IsA("Beam") and d.Attachment0 or d.Attachment0
		local a1 = d.Attachment1
		if a0 and a1 then
			local p0, p1 = a0.WorldPosition, a1.WorldPosition
			if math.min(p0.X, p1.X) < 175 and math.max(p0.X, p1.X) > 140 and math.min(p0.Z, p1.Z) < -140 and math.max(p0.Z, p1.Z) > -210 then
				print(("QQ WIRE %s (%.0f %.1f %.0f) -> (%.0f %.1f %.0f)"):format(d:GetFullName(), p0.X, p0.Y, p0.Z, p1.X, p1.Y, p1.Z))
			end
		end
	end
end
print("QQ DONE b4")
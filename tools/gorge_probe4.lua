-- gorge_probe4: READ-ONLY. What Import 3D created for the gorge: every MeshPart under workspace.rock_roblox and
-- workspace.aqueduct_roblox, with its size, texture and orientation. Nothing is changed.
for _, top in ipairs({"rock_roblox", "aqueduct_roblox"}) do
	local m = workspace:FindFirstChild(top)
	print("QQ G4 MODEL", top, m and m.ClassName, m and #m:GetDescendants())
	if m then
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("MeshPart") then
				local sa = d:FindFirstChildWhichIsA("SurfaceAppearance")
				local rx, ry, rz = d.CFrame:ToOrientation()
				print(string.format("QQ G4 PART %s parent=%s size=%.2f,%.2f,%.2f pos=%.1f,%.1f,%.1f rot=%.0f,%.0f,%.0f tex=%s sa=%s anch=%s",
					d.Name, d.Parent.Name, d.Size.X, d.Size.Y, d.Size.Z, d.Position.X, d.Position.Y, d.Position.Z,
					math.deg(rx), math.deg(ry), math.deg(rz), d.TextureID, sa and sa.ColorMap or "-", tostring(d.Anchored)))
			elseif not d:IsA("MeshPart") and d.Parent == m then
				print("QQ G4 CHILD", d.Name, d.ClassName)
			end
		end
	end
end
print("QQ G4 DONE")

-- b6 READ-ONLY: materials/colours of the bridge and the quay, so the jetty matches
local function dump(root, max)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and n < max then
			n += 1
			local c = d.Color
			print(("QQ MAT %s | %s %s | rgb %d %d %d | size %.2f %.2f %.2f | pos %.1f %.1f %.1f%s"):format(d:GetFullName(), d.ClassName, d.Material.Name,
				c.R*255, c.G*255, c.B*255, d.Size.X, d.Size.Y, d.Size.Z, d.Position.X, d.Position.Y, d.Position.Z,
				d:IsA("MeshPart") and (" tex " .. d.TextureID) or ""))
		end
	end
end
dump(workspace.Village.Props.bridge, 40)
dump(workspace.River.Quay, 40)
print("QQ DONE b6")
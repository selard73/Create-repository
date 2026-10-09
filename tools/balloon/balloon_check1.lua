-- balloon/balloon_check1 (job 23): READ-ONLY, EDIT mode. After Shannon imports tools/balloon/model/balloon.fbx with
-- File > Import 3D: reports what the importer made (names, sizes, textures), so the balloon-field installer can use it.
-- Output lines start with "QQ BLN".
local found = 0
for _, d in ipairs(game:GetDescendants()) do
	if d:IsA("MeshPart") and d.Name == "Envelope" then
		local m = d:FindFirstAncestorWhichIsA("Model")
		found += 1
		if not m then print("QQ BLN Envelope with no Model ancestor: " .. d:GetFullName())
		else
			local cf, size = m:GetBoundingBox()
			print(string.format("QQ BLN model %s | pivot %s | bounding size %.1f x %.1f x %.1f", m:GetFullName(), tostring(m:GetPivot().Position), size.X, size.Y, size.Z))
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") then
					print(string.format("QQ BLN   %s (%s) size %.2f,%.2f,%.2f pos %.1f,%.1f,%.1f anchored=%s texture=%s mesh=%s doubleSided=%s",
						p:GetFullName():sub(#m:GetFullName() + 2), p.ClassName, p.Size.X, p.Size.Y, p.Size.Z, p.Position.X, p.Position.Y, p.Position.Z,
						tostring(p.Anchored), p:IsA("MeshPart") and (p.TextureID ~= "" and p.TextureID or "NONE") or "-",
						p:IsA("MeshPart") and p.MeshId or "-", p:IsA("MeshPart") and tostring(p.DoubleSided) or "-"))
				elseif not p:IsA("Model") then
					print("QQ BLN   " .. p.ClassName .. " " .. p.Name)
				end
			end
		end
	end
end
if found == 0 then warn("QQ BLN no MeshPart named Envelope anywhere - was balloon.fbx imported?") end

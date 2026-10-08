-- riverbits_tex_probe v1: reads the two image asset ids uploaded with italy/riverbits/riverbits_carrier.obj (Import 3D),
-- prints them, and removes the carrier from the workspace (the assets stay on Roblox).
local m = workspace:FindFirstChild("riverbits_carrier")
if not m then print("QQ RTEX no carrier in workspace"); return end
for _, mp in ipairs(m:GetDescendants()) do
	if mp:IsA("MeshPart") then
		local sa = mp:FindFirstChildWhichIsA("SurfaceAppearance")
		print(string.format("QQ RTEX %s texture %s%s", mp.Name, tostring(mp.TextureID), sa and (" colormap " .. tostring(sa.ColorMap)) or ""))
	end
end
m:Destroy()
print("QQ RTEX carrier removed")

-- bubble_tex_probe v1: reads the image asset id uploaded with italy/bubble/bubble_carrier.obj (Import 3D), prints it, and
-- removes the carrier from the workspace (the asset stays on Roblox).
local m = workspace:FindFirstChild("bubble_carrier") or workspace:FindFirstChild("BubbleBlob")
if not m then print("QQ BTEX no carrier in workspace"); return end
local mp = m:IsA("MeshPart") and m or m:FindFirstChildWhichIsA("MeshPart", true)
if not mp then print("QQ BTEX no MeshPart in " .. m:GetFullName()); return end
print("QQ BTEX " .. m:GetFullName() .. " mesh " .. mp.MeshId .. " texture " .. tostring(mp.TextureID))
local sa = mp:FindFirstChildWhichIsA("SurfaceAppearance")
if sa then print("QQ BTEX SurfaceAppearance ColorMap " .. tostring(sa.ColorMap)) end
m:Destroy()
print("QQ BTEX carrier removed")

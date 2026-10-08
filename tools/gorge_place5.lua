-- gorge_place5: CHANGES THE PLACE (the gorge's end, take two: the FALLS, Sep 30 evening). Moves the headwall pieces
-- (SouthRock_End, SouthRock_Cave, CaveBack) out of workspace.SouthGorge.Rock into ServerStorage.GorgeBackup.OldEnd and
-- places the freshly imported cliff pieces (workspace.cliff_roblox: two arms + the sill face, each split at river-bed
-- level for its texture). Sizes are checked against the file first; nothing changes unless all 18 match. Material and
-- colour copied from an existing wall piece. The arms collide (players walk up to them on the plain), the sill face
-- under the falls does not (the boat passes over it).
local PIECES = {{"SouthCliff_E01", 225.0582, 17.8298, -547.7039, 51.45, 51.66, 31.82},{"SouthCliff_E01_Lo", 220.2143, -36.0000, -554.2457, 41.61, 56.00, 18.95},{"SouthCliff_E02", 264.9454, 17.5709, -565.8044, 51.85, 51.14, 34.10},{"SouthCliff_E02_Lo", 259.5788, -36.0000, -572.2960, 41.30, 56.00, 21.90},{"SouthCliff_E03", 298.2614, 17.2642, -567.9032, 39.61, 50.53, 39.95},{"SouthCliff_E03_Lo", 298.1917, -36.0000, -581.8718, 40.19, 56.00, 12.37},{"SouthCliff_E04", 323.8709, 17.0141, -554.3181, 12.83, 50.03, 45.37},{"SouthCliff_E04_Lo", 324.1614, -36.0000, -578.8789, 12.25, 56.00, 19.24},{"SouthCliff_L01", 184.3678, -5.2800, -542.0177, 33.94, 5.44, 13.04},{"SouthCliff_L01_Lo", 184.6370, -36.0000, -547.6345, 35.66, 56.00, 2.92},{"SouthCliff_W01", 144.4646, 17.8298, -548.4751, 50.29, 51.66, 30.08},{"SouthCliff_W01_Lo", 149.6817, -36.0000, -553.9652, 39.50, 56.00, 18.43},{"SouthCliff_W02", 105.3006, 17.5709, -565.1655, 52.67, 51.14, 33.31},{"SouthCliff_W02_Lo", 110.3864, -36.0000, -571.7513, 41.91, 56.00, 20.34},{"SouthCliff_W03", 72.0042, 17.2642, -567.9838, 38.67, 50.53, 40.24},{"SouthCliff_W03_Lo", 71.9416, -36.0000, -582.0539, 38.97, 56.00, 12.55},{"SouthCliff_W04", 46.8737, 17.0141, -554.5773, 12.83, 50.03, 45.60},{"SouthCliff_W04_Lo", 46.5816, -36.0000, -578.6109, 12.25, 56.00, 21.02}}
local src = workspace:FindFirstChild("cliff_roblox")
assert(src, "imported cliff_roblox model not found - run Import 3D first")
local bad = {}
for _, e in ipairs(PIECES) do
	local p = src:FindFirstChild(e[1], true)
	if not p then table.insert(bad, e[1] .. " missing")
	elseif (p.Size - Vector3.new(e[5], e[6], e[7])).Magnitude > 0.2 then table.insert(bad, string.format("%s size %s vs %.2f,%.2f,%.2f", e[1], tostring(p.Size), e[5], e[6], e[7])) end
end
if #bad > 0 then print("QQ P5 STOP (nothing changed):", table.concat(bad, " | ")) return end
local G = workspace.SouthGorge; local fR = G.Rock
local ref = fR:FindFirstChild("SouthRock_W01")
assert(ref, "SouthRock_W01 not found")
local bk = game:GetService("ServerStorage"):FindFirstChild("GorgeBackup") or Instance.new("Folder")
bk.Name = "GorgeBackup"; bk.Parent = game:GetService("ServerStorage")
local old = bk:FindFirstChild("OldEnd") or Instance.new("Folder"); old.Name = "OldEnd"; old.Parent = bk
local moved = 0
for _, n in ipairs({"SouthRock_End", "SouthRock_Cave", "CaveBack"}) do
	local p = fR:FindFirstChild(n); if p then p.Parent = old; moved += 1 end
end
local notex = 0
for _, e in ipairs(PIECES) do
	local p = src:FindFirstChild(e[1], true)
	local lip = e[1]:sub(1, 13) == "SouthCliff_L0"
	p.Anchored = true; p.CastShadow = true
	p.CanCollide = not lip; p.CanQuery = not lip; p.CanTouch = false
	pcall(function() p.CollisionFidelity = lip and Enum.CollisionFidelity.Box or Enum.CollisionFidelity.PreciseConvexDecomposition end)
	p.Material = ref.Material; p.Color = ref.Color; p.Reflectance = ref.Reflectance
	if p.TextureID == "" then notex += 1 end
	p.CFrame = CFrame.new(e[2], e[3], e[4])
	p.Parent = fR
end
if #src:GetChildren() == 0 then src:Destroy() end
G:SetAttribute("EndVersion", "falls: cliff arms + sill, Sep 30 2026")
local tex = {}
for _, p in ipairs(fR:GetChildren()) do if p.Name:sub(1, 10) == "SouthCliff" then tex[p.TextureID] = (tex[p.TextureID] or 0) + 1 end end
local tl = {}; for k, v in pairs(tex) do table.insert(tl, string.format("%s x%d", k, v)) end
print(string.format("QQ P5 moved %d headwall pieces to ServerStorage.GorgeBackup.OldEnd, placed %d cliff pieces (no texture: %d); rock pieces now %d; import model removed: %s; textures: %s", moved, #PIECES, notex, #fR:GetChildren(), tostring(workspace:FindFirstChild("cliff_roblox") == nil), table.concat(tl, ", ")))
print("QQ P5 DONE")

-- falls_cornerfix3 v1: CHANGES THE PLACE. Her 00:14 notes: the new sandstone must look like the other sandstone, and the big
-- blue blobs at the corners must go. falls_probe9 found the blobs are the river's terrain WATER bulging 4-5 studs past the
-- brink at both corners: the voxel smoothing pulled the water along the sandstone terrain fills. So:
--   1. the terrain fills are undone: both corner regions pasted back from the backups taken before any fill
--      (ServerStorage.GorgeBackup.CornerFillE_before / CornerFillW_before), so the water ends flat at the brink again;
--   2. the water pockets past each corner are hidden by two real sandstone boulders cloned from ServerStorage.SandCliffKit
--      (the Sandstone Climb look the cliffs were modelled on, textured and layered), one wedged at the foot of each wall at
--      the lip, half in the water, in workspace.SouthGorge.LipRocks; CanCollide on (outside the boat lane);
--   3. the fall body (FallsB Back) is nearly opaque and pale over its top 8 studs so the flat end face inside the notch is
--      covered without a teal band; and the fall body's top loses the teal tint;
--   4. the two grey forest-kit rocks on the east bank beside the corner (Rock_18, Rock_20) are parked in
--      ServerStorage.GorgeBackup.RapidsRocks_removed so the corner reads as one sandstone shoulder.
-- Re-running repeats the paste-back (harmless) and rebuilds LipRocks.
local T = workspace.Terrain
local SS = game:GetService("ServerStorage")
local GB = SS:FindFirstChild("GorgeBackup"); assert(GB, "GorgeBackup missing")
local G = workspace.SouthGorge
local ZC, WATER_Y = -547.5, -0.9
-- 1. undo the terrain fills
local bE, bW = GB:FindFirstChild("CornerFillE_before"), GB:FindFirstChild("CornerFillW_before")
assert(bE and bW, "corner backups missing")
T:PasteRegion(bE, Vector3int16.new(50, -4, -138), true)
T:PasteRegion(bW, Vector3int16.new(40, -4, -138), true)
-- 2. sandstone boulders at the corners
local kit = SS:FindFirstChild("SandCliffKit"); assert(kit, "SandCliffKit missing")
local old = G:FindFirstChild("LipRocks"); if old then old:Destroy() end
local LR = Instance.new("Model"); LR.Name = "LipRocks"; LR.Parent = G
local placed = {}
for _, r in ipairs({
	{name = "LipRockE", src = "SandBoulder_4", scale = 1.6, pos = Vector3.new(203.8, -3.8, -547.2), yaw = 25, tilt = 6},
	{name = "LipRockW", src = "SandBoulder_1", scale = 1.7, pos = Vector3.new(166.9, -3.7, -547.2), yaw = -40, tilt = -5},
}) do
	local src = kit:FindFirstChild(r.src); assert(src, r.src .. " missing")
	local p = src:Clone(); p.Name = r.name
	p.Size = src.Size * r.scale
	p.Transparency = 0; p.Anchored = true; p.CanCollide = true; p.CanTouch = false; p.CanQuery = true; p.CastShadow = true
	p.CFrame = CFrame.new(r.pos) * CFrame.Angles(math.rad(r.tilt), math.rad(r.yaw), 0)
	p.Parent = LR
	placed[#placed + 1] = string.format("%s %.1fx%.1fx%.1f at (%.1f, %.1f, %.1f) top y %.1f", r.name, p.Size.X, p.Size.Y, p.Size.Z, r.pos.X, r.pos.Y, r.pos.Z, r.pos.Y + p.Size.Y / 2)
end
-- 3. the fall body: pale, opaque at the top
local back = G.FallsB.Rig:FindFirstChild("Back")
if back then
	back.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(196, 226, 232)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(182, 216, 228)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 228, 236))})
	back.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.06), NumberSequenceKeypoint.new(0.12, 0.1), NumberSequenceKeypoint.new(0.22, 0.4), NumberSequenceKeypoint.new(0.7, 0.5), NumberSequenceKeypoint.new(0.9, 0.85), NumberSequenceKeypoint.new(1, 1)})
end
-- 4. the two grey rocks on the east bank by the corner
local store = GB:FindFirstChild("RapidsRocks_removed") or Instance.new("Folder", GB); store.Name = "RapidsRocks_removed"
local moved = 0
local R = G:FindFirstChild("RapidsRocks")
if R then for _, p in ipairs(R:GetChildren()) do if p:IsA("BasePart") and p.Position.Z < -530 and p.Position.X > 200 then p.Parent = store; moved += 1 end end end
-- check: where does the water end now at the corners and the centre?
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {T}; rp.IgnoreWater = false
local ends = {}
for _, x in ipairs({172, 185, 199}) do
	local r = T.Parent:Raycast(Vector3.new(x, -3, ZC - 8), Vector3.new(0, 0, 12), rp)
	ends[#ends + 1] = string.format("x%d: %s", x, r and string.format("%s z %.1f", r.Material.Name, r.Position.Z) or "none")
end
print(string.format("QQ CF3 fills undone; %s; body top opaque; %d grey rocks parked; water end faces (ray from the south at y -3): %s", table.concat(placed, " | "), moved, table.concat(ends, ", ")))
print("QQ CF3 DONE")

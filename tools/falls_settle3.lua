-- falls_settle3 v1: CHANGES THE PLACE: her yes of 00:08 = falls_corner_sand (both corners solid sandstone, backed up) + falls_topfix (teal roll off, strands start at the surface and curl) + falls_rapids_patch (patchy foam texture on the 30 rapids beams, foam puffs thinned)
-- Both corner pockets of the brink row (where the river's water, the bank's grass/sand and my first fill showed as mixed
-- lumps from below) become SOLID Sandstone from the bed up to 0.4 above the water line, flush with each wall's foot:
-- east x 200.0..205.0, west x 164.5..169.6, y -14..-0.5, z -549.0..-543.5. They read as rock shoulders at the foot of
-- the walls. Backups: ServerStorage.GorgeBackup.CornerFillE_before (already there from the first fill) and
-- CornerFillW_before (made now); Terrain:PasteRegion puts either back. Re-running is harmless.
local T = workspace.Terrain
local SS = game:GetService("ServerStorage")
local GB = SS:FindFirstChild("GorgeBackup") or Instance.new("Folder", SS); GB.Name = "GorgeBackup"
if not GB:FindFirstChild("CornerFillW_before") then
	local copy = T:CopyRegion(Region3int16.new(Vector3int16.new(40, -4, -138), Vector3int16.new(43, 1, -135)))   -- x 160..172, y -16..4, z -552..-540
	copy.Name = "CornerFillW_before"; copy.Parent = GB
end
if not GB:FindFirstChild("CornerFillE_before") then
	local copy = T:CopyRegion(Region3int16.new(Vector3int16.new(50, -4, -138), Vector3int16.new(52, 1, -135)))
	copy.Name = "CornerFillE_before"; copy.Parent = GB
end
local out = {}
for _, c in ipairs({{name = "E", x0 = 200.0, x1 = 205.0}, {name = "W", x0 = 164.5, x1 = 169.6}}) do
	local y0, y1, z0, z1 = -14, -0.5, -549.0, -543.5
	local cf = CFrame.new((c.x0 + c.x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	local size = Vector3.new(c.x1 - c.x0, y1 - y0, z1 - z0)
	T:FillBlock(cf, size, Enum.Material.Sandstone)
	out[#out + 1] = string.format("%s %.1fx%.1fx%.1f at (%.1f, %.1f, %.1f)", c.name, size.X, size.Y, size.Z, cf.X, cf.Y, cf.Z)
end
-- what the corner cells are now
local function mats(x0, x1)
	local r = Region3.new(Vector3.new(x0, -16, -552), Vector3.new(x1, 4, -540)):ExpandToGrid(4)
	local v = T:ReadVoxels(r, 4); local sz = v.Size; local cnt = {}
	for x = 1, sz.X do for y = 1, sz.Y do for z = 1, sz.Z do local m = v[x][y][z].Name; cnt[m] = (cnt[m] or 0) + 1 end end end
	local s = {}; for k, n in pairs(cnt) do s[#s + 1] = k .. "=" .. n end; table.sort(s); return table.concat(s, " ")
end
print(string.format("QQ CS1 filled %s; east cells now: %s; west cells now: %s", table.concat(out, " | "), mats(200, 208), mats(160, 172)))
print("QQ CS1 DONE")

-- lip reads as a flat band from below. So: the Crest beam goes (disabled, kept), and the strand layers and the body start AT
-- the water surface on the brink line and curl over the sill themselves (CurveSize0 3.2, like the roll did), so the top of the
-- fall is the strands' own ragged textured edge, white like Skogafoss, with no flat plane. Spray stays. Re-running is harmless.
local B = workspace.SouthGorge.FallsB
local rig = B.Rig
local ZC, WATER_Y = -547.5, -0.9
local XL = (169.4583 + 201.2856) / 2
local crest = rig:FindFirstChild("Crest"); if crest then crest.Enabled = false end
local function top(attName, x, dy, dz)
	local a = rig:FindFirstChild(attName)
	if a then a.WorldCFrame = CFrame.fromMatrix(Vector3.new(x, WATER_Y + dy, ZC + dz), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)) end
end
top("TopK", XL, -0.1, 0.3); top("TopS1", XL, -0.05, 0.3); top("TopS2", XL + 0.9, -0.15, 0.1); top("TopW", XL, 0.0, 0.4)
local out = {}
for name, c0 in pairs({Back = 3.2, Strands1 = 3.2, Strands2 = 3.0, Wisps = 3.4}) do
	local b = rig:FindFirstChild(name)
	if b then b.CurveSize0 = c0; out[#out + 1] = string.format("%s c0 %.1f top y %.2f", name, b.CurveSize0, b.Attachment0.WorldPosition.Y) end
end
-- the body's top takes a hint of the river's teal so the brink still reads as water turning over, without a flat band
local back = rig:FindFirstChild("Back")
if back then
	back.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 212, 215)), ColorSequenceKeypoint.new(0.12, Color3.fromRGB(176, 214, 224)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(182, 216, 228)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 228, 236))})
end
table.sort(out)
print("QQ TF1 crest off; " .. table.concat(out, "; "))
print("QQ TF1 DONE")

-- Her rapids reference (00:00): dark teal water with white foam in PATCHES and streaks, not a solid white sheet. The three
-- flat foam chains get the new patchy foam texture (italy/falls/falls2_foam.png, ~40% coverage, transparent between) so
-- the dark water shows between the foam; same studs-per-second as before; the flat foam puffs thin out (Rate 32 -> 18).
-- The texture id is read from the Import 3D carrier (workspace.falls2_foam_carrier.Falls2Foam) and the carrier is removed.
local F = workspace.SouthGorge.Falls
local TEX = "%FOAM%"
local car = workspace:FindFirstChild("falls2_foam_carrier")
if car then
	local q = car:FindFirstChild("Falls2Foam", true)
	if q and q:IsA("MeshPart") and q.TextureID ~= "" then TEX = q.TextureID end
	car:Destroy()
end
assert(TEX:find("rbxassetid://"), "foam texture id missing: import italy/falls/falls2_foam_carrier.obj first")
local SPEED = {Rapids1 = 0.22 * 26 / 24, Rapids2 = 0.32 * 26 / 24, Rapids3 = 0.45 * 26 / 24}   -- keep studs/s with TextureLength 24
local nb = 0
for _, b in ipairs(F:GetDescendants()) do
	if b:IsA("Beam") and b.Name:match("^Rapids%d_%d+$") then
		local layer = b.Name:match("^(Rapids%d)")
		b.Texture = TEX; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = 24; b.TextureSpeed = SPEED[layer] or 0.3
		nb += 1
	end
end
local ne = 0
for _, p in ipairs(F:GetChildren()) do
	if p:IsA("BasePart") and p.Name:match("^Foam_%d+$") then
		local e = p:FindFirstChildOfClass("ParticleEmitter"); if e then e.Rate = 18; ne += 1 end
	end
end
print(string.format("QQ RP1 rapids: %d beams textured with %s (TextureLength 24), %d foam boxes thinned to rate 18", nb, TEX, ne))
print("QQ RP1 DONE")


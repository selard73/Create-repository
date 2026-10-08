-- falls_corner_sand v1: CHANGES THE PLACE (terrain, backed up). Her ask (00:06): "just patch those sides with more sandstone".
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

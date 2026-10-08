-- falls_settle2 v1: CHANGES THE PLACE: the two parts of falls_settle that did not run (keepB did): falls_cornerfill v2 (east corner sandstone, backed up as Region3int16) + falls_wetface (sill face tinted wet, reversible)
-- pocket past the EAST corner (x 201.3..203.5, y -8..-1, z -548..-544, inside the wall's footprint) shows as a teal slab.
-- Beams hanging past the corner were rejected, so the pocket is filled with Sandstone terrain instead: a small rock lump at the
-- corner's foot, flush with the wall face, poking ~0.4 above the water line. The region is copied to
-- ServerStorage.GorgeBackup.CornerFillE_before first (Terrain:PasteRegion puts it back). Only the east corner; the west one
-- has not shown. Re-running is harmless (same fill).
local T = workspace.Terrain
local SS = game:GetService("ServerStorage")
local GB = SS:FindFirstChild("GorgeBackup") or Instance.new("Folder", SS); GB.Name = "GorgeBackup"
local region = Region3.new(Vector3.new(200, -16, -552), Vector3.new(208, 0, -540)):ExpandToGrid(4)
if not GB:FindFirstChild("CornerFillE_before") then
	local r16 = Region3int16.new(Vector3int16.new(50, -4, -138), Vector3int16.new(52, 0, -135))   -- x 200..208, y -16..0, z -552..-540 in voxels
	local copy = T:CopyRegion(r16); copy.Name = "CornerFillE_before"; copy.Parent = GB
end
-- what is there now, for the record
local before = T:ReadVoxels(region, 4)
local water = 0
local sz = before.Size
for x = 1, sz.X do for y = 1, sz.Y do for z = 1, sz.Z do if before[x][y][z] == Enum.Material.Water then water += 1 end end end end
-- the fill: x from the wall face east to the cell edge, y bed to just above the water, z the brink row
local cf = CFrame.new((201.3 + 204.2) / 2, (-12 + (-0.5)) / 2, (-548.6 + (-543.8)) / 2)
local size = Vector3.new(204.2 - 201.3, -0.5 - (-12), -543.8 - (-548.6))
T:FillBlock(cf, size, Enum.Material.Sandstone)
local after = T:ReadVoxels(region, 4)
local sand, water2 = 0, 0
for x = 1, sz.X do for y = 1, sz.Y do for z = 1, sz.Z do
	local m = after[x][y][z]
	if m == Enum.Material.Sandstone then sand += 1 elseif m == Enum.Material.Water then water2 += 1 end
end end end
print(string.format("QQ CF1 east corner filled: block %.1f x %.1f x %.1f at (%.1f, %.1f, %.1f); region water cells %d -> %d, sandstone now %d; backup %s", size.X, size.Y, size.Z, cf.X, cf.Y, cf.Z, water, water2, sand, GB.CornerFillE_before:GetFullName()))
print("QQ CF1 DONE")

-- SouthCliff_L01 and SouthCliff_L01_Lo) is tinted dark like wet rock, the way the cliff behind Skogafoss is black and wet,
-- so the white strands read against it. The original colours are kept in an attribute "OrigColor"; falls_wetface_revert
-- puts them back. MODE: set WET = true to tint, false to revert.
local WET = true
local R = workspace.SouthGorge.Rock
local out = {}
for _, n in ipairs({"SouthCliff_L01", "SouthCliff_L01_Lo"}) do
	local p = R:FindFirstChild(n)
	if p then
		if WET then
			if p:GetAttribute("OrigColor") == nil then p:SetAttribute("OrigColor", p.Color) end
			p.Color = Color3.fromRGB(74, 70, 66)
		else
			local c = p:GetAttribute("OrigColor"); if c then p.Color = c end
		end
		out[#out + 1] = string.format("%s -> %s", n, tostring(p.Color))
	else
		out[#out + 1] = n .. " MISSING"
	end
end
print("QQ WF " .. (WET and "wet" or "reverted") .. ": " .. table.concat(out, "; "))
print("QQ WF DONE")


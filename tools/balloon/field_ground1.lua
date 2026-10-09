-- balloon/field_ground1 (job 47): EDIT mode, terrain. Shannon (Oct 9): "if I turn the camera in a certain direction on
-- this part of land I can see under the ground" (the balloon field, the far shore). Looks for hollows under the field's
-- ground: 80 studs each way round BalloonField.Center, from 36 studs under the grass to 12 above, in 4-stud voxels. In
-- every column the top solid voxel is the cap; each air voxel under it is filled with the cap's material, down to solid
-- rock, the sea (water is left as it is; it runs under the shore) or the bottom of the box. Reads first and writes nothing
-- if there is no hollow. Backup before writing: ServerStorage.HudBackup.FieldGround_pre1 (a TerrainRegion; undo =
-- workspace.Terrain:PasteRegion(it, Vector3int16.new(it:GetAttribute("CX"), it:GetAttribute("CY"), it:GetAttribute("CZ")), true)).
-- Output lines "QQ GROUND".
if game:GetService("RunService"):IsRunning() then warn("QQ GROUND ABORT - Play mode") return end
local T = workspace.Terrain
local F = workspace:FindFirstChild("BalloonField")
local C = F and F:GetAttribute("Center") or Vector3.new(106, -48.5, -648)
local R, DOWN, UP = 80, 36, 12
local region = Region3.new(Vector3.new(C.X - R, C.Y - DOWN, C.Z - R), Vector3.new(C.X + R, C.Y + UP, C.Z + R)):ExpandToGrid(4)
local mats, occs = T:ReadVoxels(region, 4)
local size = mats.Size
local lo = region.CFrame.Position - region.Size / 2
local Air, Water = Enum.Material.Air, Enum.Material.Water
local filled, hollowCols, lowY, highY, examples = 0, 0, math.huge, -math.huge, {}
for x = 1, size.X do
	for z = 1, size.Z do
		local capMat, colFilled = nil, 0
		for y = size.Y, 1, -1 do
			local m, o = mats[x][y][z], occs[x][y][z]
			if m == Water then capMat = nil   -- the sea under the shore: leave it, and whatever lies under it
			elseif m ~= Air and o > 0 then capMat = capMat or m   -- the cap (the first solid voxel from the top), or rock under it
			elseif capMat then   -- air under the cap: a hollow
				mats[x][y][z] = capMat; occs[x][y][z] = 1
				filled += 1; colFilled += 1
				local wy = lo.Y + (y - 0.5) * 4
				lowY = math.min(lowY, wy); highY = math.max(highY, wy)
				if #examples < 6 and colFilled == 1 then table.insert(examples, string.format("%.0f,%.0f,%.0f", lo.X + (x - 0.5) * 4, wy, lo.Z + (z - 0.5) * 4)) end
			end
		end
		if colFilled > 0 then hollowCols += 1 end
	end
end
print(string.format("QQ GROUND box %s..%s (%dx%dx%d voxels): %d columns, %d with a hollow, %d air voxels under a cap", tostring(lo), tostring(lo + region.Size), size.X, size.Y, size.Z, size.X * size.Z, hollowCols, filled))
if filled == 0 then print("QQ GROUND DONE: nothing to fill - no air under the ground here; the see-through is something else (tell the cloud session where you stand and which way you look)") return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local old = hb:FindFirstChild("FieldGround_pre1"); if old then old:Destroy() end
local cMin = Vector3int16.new(math.floor(lo.X / 4 + 0.5), math.floor(lo.Y / 4 + 0.5), math.floor(lo.Z / 4 + 0.5))
local cMax = Vector3int16.new(cMin.X + size.X, cMin.Y + size.Y, cMin.Z + size.Z)
local backup = T:CopyRegion(Region3int16.new(cMin, cMax))
backup.Name = "FieldGround_pre1"; backup:SetAttribute("CX", cMin.X); backup:SetAttribute("CY", cMin.Y); backup:SetAttribute("CZ", cMin.Z); backup.Parent = hb
T:WriteVoxels(region, 4, mats, occs)
game:GetService("ChangeHistoryService"):SetWaypoint("Balloon field ground filled")
print(string.format("QQ GROUND DONE: %d voxels filled in %d columns, y %.0f..%.0f; first hollows at %s; backup ServerStorage.HudBackup.FieldGround_pre1 (corner %d,%d,%d)", filled, hollowCols, lowY, highY, table.concat(examples, " | "), cMin.X, cMin.Y, cMin.Z))

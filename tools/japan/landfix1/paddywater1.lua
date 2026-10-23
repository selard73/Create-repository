-- paddywater1.lua (Oct 22 2026): Shannon: "the water in the rice paddies at the edges bulges downward, like it is curved, water
-- doesn't do that in real life". Cause: the paddies are terrain Water (layer y 0..4, occupancy 0.5625 = surface 2.25) and the
-- 4-stud cells under the bank meshes are AIR, so the smoothed water surface rounds off downward where water meets air.
-- Fix: every Air cell under a bank crown (RiceBankCollision1 ray >= 2.5 at the cell centre) that touches a water cell becomes
-- Water at the same occupancy - hidden inside the bank (crown 2.7-2.85 > surface 2.25), so the visible surface stays flat up to
-- the bank. Backup: ServerStorage.HudBackup.RicePaddyWater_pre_paddywater1 (one TerrainRegion per paddy, PasteCorner attribute;
-- restore with Terrain:PasteRegion(region, corner, true)). Re-runnable (filled cells are water, so they are skipped). "QQ PADDYWATER1".
local T = workspace.Terrain
local col = workspace.JapanMap:FindFirstChild("RiceBankCollision1")
if not col then return "QQ PADDYWATER1 ABORT: no JapanMap.RiceBankCollision1" end
local HB = game:GetService("ServerStorage").HudBackup
local rpB = RaycastParams.new(); rpB.FilterType = Enum.RaycastFilterType.Include; rpB.FilterDescendantsInstances = {col}
local PADDIES = {{5496, 83}, {5556, 83}, {5616, 83}}
local HALF_X, HALF_Z = 29.5 + 8, 26 + 8
local out = {}
local bk = HB:FindFirstChild("RicePaddyWater_pre_paddywater1")
if not bk then bk = Instance.new("Folder"); bk.Name = "RicePaddyWater_pre_paddywater1"; bk.Parent = HB end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before paddywater1") end)
local total, saved = 0, 0
for i, c in ipairs(PADDIES) do
	local x0, x1 = math.floor((c[1] - HALF_X) / 4) * 4, math.ceil((c[1] + HALF_X) / 4) * 4
	local z0, z1 = math.floor((c[2] - HALF_Z) / 4) * 4, math.ceil((c[2] + HALF_Z) / 4) * 4
	if not bk:FindFirstChild("Paddy" .. i) then                      -- the backup is in VOXEL coordinates (studs / 4)
		local big = Region3int16.new(Vector3int16.new(x0 / 4, -2, z0 / 4), Vector3int16.new(x1 / 4, 2, z1 / 4))
		local tr = T:CopyRegion(big)
		tr.Name = "Paddy" .. i
		tr:SetAttribute("PasteCorner", Vector3.new(x0 / 4, -2, z0 / 4))   -- voxel coords; Vector3int16 can't be an attribute
		tr:SetAttribute("Note", "Terrain:PasteRegion(region, Vector3int16.new(PasteCorner.X, PasteCorner.Y, PasteCorner.Z), true) restores paddy " .. i)
		tr.Parent = bk
		saved += 1
	end
	local region = Region3.new(Vector3.new(x0, 0, z0), Vector3.new(x1, 4, z1)):ExpandToGrid(4)
	local mats, occ = T:ReadVoxels(region, 4)
	local sz = mats.Size
	local waterOcc = nil
	for ix = 1, sz.X do for iz = 1, sz.Z do
		if mats[ix][1][iz] == Enum.Material.Water then waterOcc = waterOcc or occ[ix][1][iz] end
	end end
	assert(waterOcc, "paddy " .. i .. " has no water cells")
	local fill = {}
	for ix = 1, sz.X do
		for iz = 1, sz.Z do
			if mats[ix][1][iz] == Enum.Material.Air then
				local cx, cz = x0 + (ix - 0.5) * 4, z0 + (iz - 0.5) * 4
				local h = workspace:Raycast(Vector3.new(cx, 20, cz), Vector3.new(0, -30, 0), rpB)
				if h and h.Position.Y >= 2.5 then
					for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
						local jx, jz = ix + d[1], iz + d[2]
						if jx >= 1 and jx <= sz.X and jz >= 1 and jz <= sz.Z and mats[jx][1][jz] == Enum.Material.Water then
							table.insert(fill, {ix, iz}); break
						end
					end
				end
			end
		end
	end
	for _, f in ipairs(fill) do
		mats[f[1]][1][f[2]] = Enum.Material.Water
		occ[f[1]][1][f[2]] = waterOcc
	end
	T:WriteVoxels(region, 4, mats, occ)
	total += #fill
	table.insert(out, string.format("QQ PADDYWATER1 paddy %d: %d bank cells filled with water (occupancy %.4f) under the crown", i, #fill, waterOcc))
	task.wait()
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after paddywater1") end)
table.insert(out, string.format("QQ PADDYWATER1 total %d cells; %d terrain backups saved this run - EDIT INSTALLED; NOT PUBLISHED", total, saved))
return table.concat(out, "\n")

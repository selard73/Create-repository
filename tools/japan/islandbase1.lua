-- islandbase1.lua (runner 7, Oct 17 2026): Japan's floating ground. Shannon: "the ground was floating, make it look right please".
-- WHAT IS WRONG (read-only survey, 8- and 4-stud ray grids): the island's lawn is ONE grass mesh sheet (JM_JR_BasinGround_1..8,
-- x 5356..6644, z -391..466, top -0.04, 4 thick, bottom -4.04) and under 13,000 of its 17,000 cells the terrain is the SEA at -6:
-- a 2-stud void of water under the whole lawn. Wherever the sheet's edge shows (the lake cut by the pier, the east shore, stream cuts),
-- you see a green slab hanging over water. The lake pier's stilts end at y 1.0, a stud above the lawn.
-- THE FIX (terrain, the grass sheet untouched - "I do not want to change the grass"):
--  1. a solid BASE under the sheet: terrain row [-8..-4] made solid Ground wherever it is water or air under the sheet, so the sheet
--     sits on land (its bottom -4.04 on earth at -4).
--  2. a SHORE where the sheet ends over the sea: outside cells at sea level (-7 < top < -5) within 2 cells of the sheet get a bank -
--     the first cell earth to -1.5, the second a sand bar to -4 - so the turf edge sits on an earth bank that runs down into the water.
--     Cells whose terrain is deeper (stream beds at -16/-30) or higher (hills, the coast lip) are left alone; the pond and canal (water
--     above -4.5) are left alone.
--  3. the lake pier (JM_JR_Lake_Boardwalk + its Promenade approach treads / end landing / swim-exit treads) lowered 1.0 so its stilts
--     stand on the lawn (attribute IslandBaseWasY on each, undo = put it back).
-- Backup: HudBackup.IslandBase_pre1 (TerrainRegion of rows [-8..0] over the footprint; undo = Terrain:PasteRegion(it,
-- Vector3int16.new(1338, -2, -98), true)). Work in 24-stud strips with task.wait. Output "QQ ISLANDBASE1".
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local J = workspace:FindFirstChild("JapanMap")
local F = J and J:FindFirstChild("Reference refinement - Blender") and J["Reference refinement - Blender"]:FindFirstChild("Water-cut terrain and leafy planting")
if not F then print("QQ ISLANDBASE1 ABORT: the grass sheet folder is missing") return end
local slabs = {}
for i = 1, 8 do local s = F:FindFirstChild("JM_JR_BasinGround_" .. i); if s then table.insert(slabs, s) end end
if #slabs ~= 8 then print("QQ ISLANDBASE1 ABORT: expected 8 JM_JR_BasinGround slabs, found " .. #slabs) return end
local X0, X1, Z0, Z1 = 5352, 6648, -392, 472                                           -- on the 4-grid, the sheet plus one cell
local BANK = {{-1.5, Enum.Material.Ground}, {-4.0, Enum.Material.Sand}}                -- the shore: top height + material, by distance from the sheet
local PIER_DROP = 1.0
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before islandbase1") end)
if not hb:FindFirstChild("IslandBase_pre1") then
	local tr = T:CopyRegion(Region3int16.new(Vector3int16.new(X0 / 4, -2, Z0 / 4), Vector3int16.new(X1 / 4 - 1, -1, Z1 / 4 - 1)))
	tr.Name = "IslandBase_pre1"; tr:SetAttribute("PasteCorner", Vector3.new(X0 / 4, -2, Z0 / 4)); tr.Parent = hb
end
-- the sheet map at 4 studs (the slabs are CanQuery false: on for the rays, then back)
local was = {}
for _, s in ipairs(slabs) do was[s] = s.CanQuery; s.CanQuery = true end
local rpS = RaycastParams.new(); rpS.FilterType = Enum.RaycastFilterType.Include; rpS.FilterDescendantsInstances = slabs
local NX, NZ = (X1 - X0) / 4, (Z1 - Z0) / 4
local sheet = {}
local n = 0
for i = 0, NX - 1 do
	for k = 0, NZ - 1 do
		n += 1; if n % 3000 == 0 then task.wait() end
		sheet[k * NX + i] = workspace:Raycast(Vector3.new(X0 + (i + 0.5) * 4, 3, Z0 + (k + 0.5) * 4), Vector3.new(0, -10, 0), rpS) ~= nil
	end
end
for s, v in pairs(was) do s.CanQuery = v end
local function onSheet(i, k) return i >= 0 and i < NX and k >= 0 and k < NZ and sheet[k * NX + i] == true end
local function distToSheet(i, k)                                                        -- 1 if a 4-neighbour is sheet, 2 if a cell two away is, else 0
	for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do if onSheet(i + d[1], k + d[2]) then return 1 end end
	for _, d in ipairs({{2, 0}, {-2, 0}, {0, 2}, {0, -2}, {1, 1}, {1, -1}, {-1, 1}, {-1, -1}}) do if onSheet(i + d[1], k + d[2]) then return 2 end end
	return 0
end
-- terrain in strips: rows [-8..-4] (j = 1) and [-4..0] (j = 2) of a region whose Y span is -8..0
local nBase, nBank, nSand, strips = 0, 0, 0, 0
local STRIP = 24
for zs = Z0, Z1 - 1, STRIP do
	local ze = math.min(zs + STRIP, Z1)
	local reg = Region3.new(Vector3.new(X0, -8, zs), Vector3.new(X1, 0, ze))
	local mats, occ = T:ReadVoxels(reg, 4)
	local sx, sz = mats.Size.X, mats.Size.Z
	for ii = 1, sx do
		for kk = 1, sz do
			local i, k = ii - 1, (zs - Z0) / 4 + kk - 1
			local m1, o1, m2, o2 = mats[ii][1][kk], occ[ii][1][kk], mats[ii][2][kk], occ[ii][2][kk]
			local solidTop
			if m2 ~= Enum.Material.Air and m2 ~= Enum.Material.Water and o2 > 0 then solidTop = -4 + 4 * o2
			elseif m1 ~= Enum.Material.Air and m1 ~= Enum.Material.Water and o1 > 0 then solidTop = -8 + 4 * o1
			else solidTop = -99 end
			if onSheet(i, k) then
				if solidTop < -4.01 then mats[ii][1][kk] = Enum.Material.Ground; occ[ii][1][kk] = 1; nBase += 1 end   -- 1. the base
			else
				local waterTop = (m1 == Enum.Material.Water) and (-8 + 4 * o1) or ((m2 == Enum.Material.Water) and (-4 + 4 * o2) or nil)
				if solidTop < -5 and waterTop and waterTop > -7 and waterTop < -5 then                                    -- the sea beside the sheet
					local d = distToSheet(i, k)
					if d > 0 then                                                                                           -- 2. the shore
						local top, mat = BANK[d][1], BANK[d][2]
						mats[ii][1][kk] = mat; occ[ii][1][kk] = 1
						mats[ii][2][kk] = mat; occ[ii][2][kk] = math.clamp((top + 4) / 4, 0, 1)
						if occ[ii][2][kk] == 0 then mats[ii][2][kk] = Enum.Material.Air end
						if d == 1 then nBank += 1 else nSand += 1 end
					end
				end
			end
		end
	end
	T:WriteVoxels(reg, 4, mats, occ)
	strips += 1
	task.wait()
end
-- 3. the pier
local nPier = 0
local pier = J:FindFirstChild("JM_JR_Lake_Boardwalk", true)
local moved = {}
if pier then table.insert(moved, pier) end
for _, d in ipairs(J:GetDescendants()) do
	if d:IsA("BasePart") and (d.Name == "Promenade approach tread" or d.Name == "Promenade end landing" or d.Name:find("^Lake submerged swim exit")) then table.insert(moved, d) end
end
for _, p in ipairs(moved) do
	if p:GetAttribute("IslandBaseWasY") == nil then
		p:SetAttribute("IslandBaseWasY", p.Position.Y)
		p.CFrame = p.CFrame - Vector3.new(0, PIER_DROP, 0); nPier += 1
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after islandbase1") end)
print(string.format("QQ ISLANDBASE1 DONE: %d strips; base filled under %d sheet cells (Ground to -4); shore: %d earth bank cells + %d sand bar cells; pier + %d promenade parts lowered %.1f (now %d parts carry IslandBaseWasY); backup HudBackup.IslandBase_pre1",
	strips, nBase, nBank, nSand, nPier - (pier and 1 or 0), PIER_DROP, nPier))

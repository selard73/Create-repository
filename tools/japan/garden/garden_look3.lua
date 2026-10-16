-- garden_look3.lua (job 125, LOOK TEST 3: the canal kept as a canal; a play-test PREVIEW first, then Studio EDIT on her word; re-runnable).
-- 1. finds the canal from LanternStreet's two "Canal stone bank" parts (the water at 1.3 stays); 2. TERRAIN along the whole channel:
-- a flat Slate bed at -1.3 ("dark floor"; the jagged rock ridge at -10 buried), the rock poking above the water cleared, the water flat
-- at 1.3 up to the end walls; 3. RETIRES to HudBackup.MomijiGardenReplaced: both concrete banks, the black JP_Canal_Rocks_* strips,
-- the three "Canal footbridge"s, their white "approach steps", the "Canal weir" folder, the old "Canal boat", the six brown "Walkway"
-- paths at the crossings ("I do not like the pavement"), and the black-cobble sheet JM_Garden_Weathered_Cobbles ("little black
-- stones everywhere"); 5. PLACES only imported meshes: the stone-block canal walls with their coping along both sides and across both
-- ends (two block patterns alternating), a taiko bridge at each old crossing with landing steps at its ends, a stepping-stone path
-- (kit slabs) along each old walkway line from the landings out to the paths beyond, stone steps down into the water
-- beside each bridge, the waterfall pouring into the south end, koi swimming slow loops along the canal (Shannon's Meshy koi), a Yanagawa
-- boat moored at the steps and one poled back and forth along the long reach (CanalLife client script; the old "Canal boat" retired), and
-- look test 1's torii, pine, lit lanterns, rocks and stepping slabs; 7. the floating maple by the north bridge set down on the lawn.
-- Re-runnable in Edit (the previous MomijiGarden -> HudBackup.MomijiGarden_prev; the bridges' and walkways' places are read back from
-- HudBackup.MomijiGardenReplaced). Output "QQ GARDEN3".
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
if not (KIT and J) then print("QQ GARDEN3 ABORT: ServerStorage.JapanGardenKit or workspace.JapanMap missing") return end
for _, n in ipairs({"torii", "lantern", "bridge", "pine", "rocks", "slabs", "waterfall", "canal_wall", "canal_wall_b", "canal_steps", "bridge_steps", "boat"}) do
	if not KIT:FindFirstChild(n) then print("QQ GARDEN3 ABORT: the kit has no Model '" .. n .. "' - import tools/japan/garden/out3/*.fbx too") return end
end
local KOI = KIT:FindFirstChild("koi_meshy") or KIT:FindFirstChild("koi")
if not KOI then print("QQ GARDEN3 ABORT: the kit has neither 'koi_meshy' (Shannon's Meshy koi) nor 'koi' (out2/koi.fbx)") return end
local MESHY_KOI = KOI.Name == "koi_meshy"
local MESHY_KOI_FACING = CFrame.Angles(0, 0, 0)               -- Shannon (installed look 3): "the koi are swimming backward" with 180 -> 0: the Meshy koi's head is its -Z, CanalLife's lookAt points -Z along the way
print("QQ GARDEN3 koi: " .. (MESHY_KOI and "Shannon's Meshy koi (kit 'koi_meshy')" or "out2/koi.fbx (no 'koi_meshy' in the kit)"))
local BB = {
	["torii"] = {min = Vector3.new(-9.881, 0.0, -0.85), max = Vector3.new(9.881, 16.843, 1.1)},
	["lantern"] = {min = Vector3.new(-1.55, 0.0, -1.342), max = Vector3.new(1.55, 5.566, 1.342)},
	["bridge"] = {min = Vector3.new(-20.232, -2.4, -4.4), max = Vector3.new(20.232, 8.6, 4.4)},
	["maple_a"] = {min = Vector3.new(-5.727, -0.046, -5.657), max = Vector3.new(5.364, 9.639, 4.668)},
	["maple_b"] = {min = Vector3.new(-4.909, -0.056, -5.891), max = Vector3.new(5.128, 10.535, 5.688)},
	["pine"] = {min = Vector3.new(-5.87, -0.186, -5.552), max = Vector3.new(6.83, 8.686, 3.381)},
	["rocks"] = {min = Vector3.new(-2.704, -0.462, -2.328), max = Vector3.new(2.418, 1.394, 2.366)},
	["slabs"] = {min = Vector3.new(-1.861, 0.0, -1.962), max = Vector3.new(2.07, 0.35, 2.063)},
	["waterfall"] = {min = Vector3.new(-8.555, -0.414, -6.462), max = Vector3.new(8.742, 10.425, 3.761)},
	["rocks/Rock1"] = {min = Vector3.new(-1.551, -0.392, -1.823), max = Vector3.new(1.714, 1.14, 1.387)},
	["slabs/Slab1"] = {min = Vector3.new(-1.338, 0.0, -1.277), max = Vector3.new(1.37, 0.35, 1.546)},
	["rocks/Rock2"] = {min = Vector3.new(-2.704, -0.462, -2.328), max = Vector3.new(2.418, 1.394, 2.366)},
	["slabs/Slab2"] = {min = Vector3.new(-1.861, 0.0, -1.962), max = Vector3.new(2.07, 0.35, 2.063)},
	["rocks/Rock3"] = {min = Vector3.new(-1.098, -0.347, -1.303), max = Vector3.new(1.166, 1.03, 1.089)},
	["slabs/Slab3"] = {min = Vector3.new(-1.336, 0.0, -1.039), max = Vector3.new(1.034, 0.35, 1.101)},
	["canal_edge"] = {min = Vector3.new(-5.4, -3.2, -4.0), max = Vector3.new(0.258, 0.621, 4.0)},
	["canal_edge_b"] = {min = Vector3.new(-5.4, -3.2, -4.0), max = Vector3.new(0.21, 0.621, 4.0)},
	["reeds"] = {min = Vector3.new(-0.831, 0.0, -1.039), max = Vector3.new(0.649, 2.506, 0.564)},
	["pond_rim"] = {min = Vector3.new(-17.9, -3.2, -8.0), max = Vector3.new(17.9, 0.614, 16.5)},
	["stepstone"] = {min = Vector3.new(-1.939, -3.2, -1.801), max = Vector3.new(1.743, 0.197, 1.705)},
	["koi"] = {min = Vector3.new(-1.5, -0.3, -0.45), max = Vector3.new(0.9, 0.42, 0.45)},
	["lilies"] = {min = Vector3.new(-1.585, 0.0, -1.403), max = Vector3.new(1.98, 0.551, 1.952)},
	["stepstone/Step1"] = {min = Vector3.new(-1.226, -3.2, -1.42), max = Vector3.new(1.237, 0.151, 1.614)},
	["stepstone/Step2"] = {min = Vector3.new(-1.298, -3.2, -1.208), max = Vector3.new(1.102, 0.124, 1.113)},
	["stepstone/Step3"] = {min = Vector3.new(-1.939, -3.2, -1.801), max = Vector3.new(1.743, 0.197, 1.705)},
	["koi/Koi_Orange"] = {min = Vector3.new(-1.5, -0.3, -0.45), max = Vector3.new(0.9, 0.42, 0.45)},
	["koi/Koi_White"] = {min = Vector3.new(-1.5, -0.3, -0.45), max = Vector3.new(0.9, 0.42, 0.45)},
	["koi/Koi_Gold"] = {min = Vector3.new(-1.5, -0.3, -0.45), max = Vector3.new(0.9, 0.42, 0.45)},
	["canal_wall"] = {min = Vector3.new(-4.324, -1.2, -4.0), max = Vector3.new(0.311, 2.127, 4.0)},
	["canal_wall_b"] = {min = Vector3.new(-4.329, -1.2, -4.0), max = Vector3.new(0.309, 2.102, 4.0)},
	["canal_steps"] = {min = Vector3.new(0.0, -1.2, -2.3), max = Vector3.new(4.5, 1.9, 2.3)},
	["bridge_steps"] = {min = Vector3.new(-3.0, 0.0, -4.4), max = Vector3.new(0.0, 1.0, 4.4)},
	["skiff"] = {min = Vector3.new(-8.467, -0.965, -1.9), max = Vector3.new(7.0, 4.647, 1.9)},
	["boat"] = {min = Vector3.new(-3.63, -0.033, -13.35), max = Vector3.new(3.63, 3.612, 13.75)}
}
local COL = {
	Torii_Red = Color3.new(0.8, 0.2, 0.13),
	Torii_Black = Color3.new(0.13, 0.12, 0.12),
	Torii_Plaque = Color3.new(0.2, 0.16, 0.14),
	Lantern_Stone = Color3.new(0.62, 0.62, 0.6),
	Lantern_Paper = Color3.new(1.0, 0.88, 0.62),
	Bridge_Red = Color3.new(0.82, 0.18, 0.12),
	Bridge_Deck = Color3.new(0.55, 0.38, 0.24),
	Bridge_Gold = Color3.new(0.93, 0.74, 0.3),
	Bridge_Stone = Color3.new(0.58, 0.57, 0.55),
	Maple_Bark = Color3.new(0.36, 0.25, 0.19),
	Maple_Red = Color3.new(0.86, 0.24, 0.16),
	Maple_Orange = Color3.new(0.95, 0.52, 0.18),
	Maple_Gold = Color3.new(0.98, 0.74, 0.28),
	Pine_Bark = Color3.new(0.3, 0.22, 0.18),
	Pine_Needles = Color3.new(0.2, 0.42, 0.26),
	Rock_Grey = Color3.new(0.55, 0.55, 0.54),
	Rock_Moss = Color3.new(0.42, 0.58, 0.3),
	Slab_Stone = Color3.new(0.66, 0.65, 0.62),
	Fall_Rock = Color3.new(0.5, 0.5, 0.5),
	Fall_Moss = Color3.new(0.4, 0.56, 0.3),
	Fall_Water = Color3.new(0.72, 0.88, 0.97),
	Fall_Foam = Color3.new(0.95, 0.98, 1.0),
	Edge_Stone = Color3.new(0.6, 0.59, 0.56),
	Edge_Moss = Color3.new(0.42, 0.58, 0.3),
	Step_Stone = Color3.new(0.55, 0.54, 0.52),
	Step_Moss = Color3.new(0.4, 0.56, 0.28),
	Koi_Orange = Color3.new(0.95, 0.42, 0.1),
	Koi_White = Color3.new(0.96, 0.94, 0.9),
	Koi_Gold = Color3.new(0.98, 0.72, 0.22),
	Lily_Pad = Color3.new(0.26, 0.5, 0.24),
	Lily_Flower = Color3.new(0.96, 0.62, 0.78),
	Wall_Stone = Color3.new(0.56, 0.55, 0.51),
	Wall_Coping = Color3.new(0.66, 0.65, 0.61),
	Steps_Stone = Color3.new(0.63, 0.62, 0.58),
	Steps_Landing = Color3.new(0.63, 0.62, 0.58),
	Skiff_Wood = Color3.new(0.72, 0.5, 0.28),
	Skiff_Trim = Color3.new(0.46, 0.29, 0.15),
	Skiff_Pole = Color3.new(0.55, 0.47, 0.35),
	Boat_Hull = Color3.new(0.86, 0.63, 0.39),
	Boat_Seam = Color3.new(0.5, 0.32, 0.18),
	Boat_Rail = Color3.new(0.72, 0.48, 0.27),
	Boat_Beam = Color3.new(0.64, 0.42, 0.24),
	Boat_Floor = Color3.new(0.78, 0.58, 0.38),
	Boat_Deck = Color3.new(0.8, 0.57, 0.35),
	Boat_Bench = Color3.new(0.75, 0.53, 0.31),
	Boat_Hat = Color3.new(0.88, 0.78, 0.55),
	Boat_Pole = Color3.new(0.74, 0.68, 0.44),
	Boat_Rope = Color3.new(0.92, 0.9, 0.84)
}
local function colourKey(name)
	local n = name:gsub("^[ABP]_", ""):gsub("^Rock%d_", "Rock_"):gsub("%.%d+$", "")
	if n:match("^Slab%d") then return "Slab_Stone" end
	return n
end
local SOLID = {Bridge_Deck = true, Bridge_Red = true, Bridge_Stone = true, Torii_Red = true, Torii_Black = true, Lantern_Stone = true, Rock_Grey = true,
	Rock_Moss = true, Slab_Stone = true, Fall_Rock = true, Fall_Moss = true, Pine_Bark = true, Wall_Stone = true, Wall_Coping = true, Steps_Stone = true,
	Steps_Landing = true, Skiff_Wood = true, Skiff_Trim = true, Boat_Hull = true, Boat_Floor = true, Boat_Deck = true, Boat_Bench = true, Boat_Rail = true}
local WATER = 1.3                                                           -- the canal's water surface, kept
local MOSS = false                                                          -- false: the kit rocks' and the falls' green bands go plain grey ("that moss on those rocks does not look like moss")
local BOAT_WOOD = false                                                     -- false: the boats in SmoothPlastic (the colour truer to her photo); true: Wood (box UVs, the grain along the length)
local BRIDGE_LANDING_TURN = 180                                             -- runner 7's profiles (look 3c): the landings came out with the low tread against the deck end -> turned, the high tread meets the deck
local KOI_TOP_UNDER = 0.2                                                   -- the koi's TOP this far under the surface (Shannon: "the koi should be swimming under the water not above it"); "Clear canal, dark floor"
local BED_Y = -4.0                                                          -- the canal's flat Slate bed ("the boats and the fish are in mid air" at -1.3): 5.3 of water, chest-deep; the lower wall copies reach -4.05
local WALL_DROP = 0.0                                                       -- (the "teeth" at the lawn were the deep joints between the lawn-face blocks: fixed in the mesh, gen_garden3; the coping stays at 2.1)
local GARDEN_BRIDGE_FROM, GARDEN_BRIDGE_TO = -215, -203                     -- the garden bridge moves 12 north so the waterfall (now on the lawn behind the south end wall) clears it
local COL_OVERRIDE = {Lantern_Stone = Color3.new(0.40, 0.40, 0.39)}        -- "the lanterns should be a darker gray stone than everything else" (walls 0.56 / 0.66, landings 0.63, slabs 0.66)
local FLAGSTONE_WALLS = true                                                -- "what if the stone sides were the same color/texture as this?" (the palace wall): Wall_Stone in Pavement + MaterialVariant JM_PhotographicPath, white; the coping stays cut stone
local WALL_LOWER_COPY = 2.85                                                -- a second, coping-less copy of every wall segment and water stair this much lower, so the stonework reaches the deeper bed
local BOAT_COL = {Boat_Hull = Color3.fromRGB(103, 72, 48), Boat_Rail = Color3.fromRGB(65, 47, 33), Boat_Beam = Color3.fromRGB(65, 47, 33), Boat_Seam = Color3.fromRGB(44, 33, 28),
	Boat_Floor = Color3.fromRGB(120, 80, 50), Boat_Deck = Color3.fromRGB(120, 80, 50), Boat_Bench = Color3.fromRGB(120, 80, 50)}   -- the canal houses' wood colours ("the color of the boat ... sticks out")
-- ---------- 1. the canal ----------
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local replaced = hb:FindFirstChild("MomijiGardenReplaced") or Instance.new("Folder"); replaced.Name = "MomijiGardenReplaced"; replaced.Parent = hb
local banks = {}
for _, d in ipairs(J:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Canal stone bank" then table.insert(banks, d) end end
if #banks ~= 2 then                                                          -- a re-run: the first run retired them - read them from the backup
	banks = {}
	for _, d in ipairs(replaced:GetChildren()) do if d:IsA("BasePart") and d.Name == "Canal stone bank" then table.insert(banks, d) end end
	if #banks == 2 then print("QQ GARDEN3 re-run: the canal read from the retired 'Canal stone bank' parts in HudBackup.MomijiGardenReplaced") end
end
local WEST, EAST, Z1, Z2
if #banks == 2 then
	table.sort(banks, function(a, b) return a.Position.X < b.Position.X end)
	WEST = banks[1].Position.X + banks[1].Size.X / 2                           -- the water-side faces
	EAST = banks[2].Position.X - banks[2].Size.X / 2
	Z1 = math.min(banks[1].Position.Z - banks[1].Size.Z / 2, banks[2].Position.Z - banks[2].Size.Z / 2)
	Z2 = math.max(banks[1].Position.Z + banks[1].Size.Z / 2, banks[2].Position.Z + banks[2].Size.Z / 2)
else
	WEST, EAST, Z1, Z2 = 6088.5, 6113.5, -223, 103                             -- the surveyed canal (runner 7, Oct 16), when neither the map nor the backup has the banks
	print("QQ GARDEN3 no 'Canal stone bank' parts in the map or the backup - using the surveyed canal x 6088.5 / 6113.5, z -223 .. 103")
end
local CX = (WEST + EAST) / 2
local ZS, ZN = Z1 + 3.5, Z2 - 0.5                                             -- the end walls (south: where the weir stood; north: 0.5 inside the side walls' end, so the corners close - at Z2 + 1.5 a 1.2 slot of water showed at both north corners)
print(string.format("QQ GARDEN3 canal: water faces x %.1f / %.1f (centre %.1f), z %.1f .. %.1f, water %.1f; end walls at z %.1f / %.1f", WEST, EAST, CX, Z1, Z2, WATER, ZS, ZN))
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Momiji garden look test 3") end)
-- ---------- 2. the terrain: a flat dark Slate bed along the whole channel, the water flat at 1.3 to the end walls ----------
-- (Roblox draws a row's surface at (its top - 2) + 4 x occupancy: the -4..0 row at 0.825 = the water at 1.3; the same row's solid at
-- (BED_Y + 2) / 4 = the bed at BED_Y, with every row below full Slate)
local tbed, tw = 0, 0
do
	local x0, x1 = math.floor(WEST / 4) * 4, math.ceil(EAST / 4) * 4
	local zA, zB = math.floor((Z1 - 2) / 4) * 4, math.ceil((Z2 + 4) / 4) * 4
	local TB = 4 * math.floor((BED_Y + 2) / 4)                                -- the row whose surface is the bed, and its occupancy
	local bedOcc = (BED_Y - TB + 2) / 4
	for zs = zA, zB - 1, 64 do
		local r = Region3.new(Vector3.new(x0, -16, zs), Vector3.new(x1, 8, math.min(zs + 64, zB)))
		local ch = T:ReadVoxelChannels(r, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
		local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
		for ix = 1, #SO do
			local x = x0 + (ix - 0.5) * 4
			if x + 2 > WEST and x - 2 < EAST then                              -- every cell column the water touches, the edge ones under the walls included (else a trench along the wall)
				for iy = 1, #SO[ix] do
					local y0 = -16 + (iy - 1) * 4
					for iz = 1, #SO[ix][iy] do
						local T = y0 + 4                                            -- the row's top
						if T < TB then SM[ix][iy][iz] = Enum.Material.Slate; SO[ix][iy][iz] = 1; LO[ix][iy][iz] = 0; tbed += 1
						elseif T == TB then SM[ix][iy][iz] = Enum.Material.Slate; SO[ix][iy][iz] = bedOcc; LO[ix][iy][iz] = (T == 0) and 0.825 or (1 - bedOcc); tw += 1   -- the bed at BED_Y, water above it
						elseif T < 0 then SO[ix][iy][iz] = 0; LO[ix][iy][iz] = 1; tw += 1                                   -- full water between the bed and the surface row
						elseif T == 0 then SO[ix][iy][iz] = 0; LO[ix][iy][iz] = 0.825; tw += 1                               -- the surface at 1.3
						else SO[ix][iy][iz] = 0; LO[ix][iy][iz] = 0 end
					end
				end
			end
		end
		T:WriteVoxelChannels(r, 4, {SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO})
	end
end
print(string.format("QQ GARDEN3 terrain: a flat Slate bed at %.1f along the channel (%d cells below, %d bed/water cells), the water flat at %.1f (%.1f deep)", BED_Y, tbed, tw, WATER, WATER - BED_Y))
-- ---------- 3. retire the concrete banks, the black strips, the old bridges and steps, the weir ----------
local retire, bridgesZ, walkways = {}, {}, {}
local function near(cf, r) return math.abs(cf.X - CX) < r end
for _, d in ipairs(J:GetDescendants()) do
	if d.Parent and not d:IsDescendantOf(replaced) then
		if d.Name == "Canal weir" or d.Name == "Canal boat" or d.Name == "Canal stone bank" or d.Name == "JM_Garden_Weathered_Cobbles" or (d:IsA("BasePart") and d.Name:match("^JP_Canal_Rocks")) then
			table.insert(retire, d)                                             -- (by name whatever the class: "Canal weir" is a FOLDER of Weir / Weir lip / Weir stones)
		elseif d:IsA("BasePart") and d.Name == "Walkway" and d.Size.Y < 4 and near(d.CFrame, 85) and d.Position.Z > Z1 - 20 and d.Position.Z < Z2 + 10 then
			table.insert(retire, d); table.insert(walkways, {pos = d.Position, size = d.Size, right = d.CFrame.RightVector, look = d.CFrame.LookVector})   -- the brown paths at the crossings (the station's at z 139 stays)
		else
			local ok, cf = pcall(function() return d:IsA("Model") and d:GetPivot() or (d:IsA("BasePart") and d.CFrame) end)
			if ok and cf then
				if d:IsA("Model") and d.Name == "Canal footbridge" then table.insert(retire, d); table.insert(bridgesZ, cf.Z)
				elseif d.Name:lower():find("approach steps") and near(cf, 30) then table.insert(retire, d) end
			end
		end
	end
end
-- re-runs: the footbridges and walkways are already in HudBackup.MomijiGardenReplaced - read their places from there
for _, d in ipairs(replaced:GetChildren()) do
	if d:IsA("Model") and d.Name == "Canal footbridge" then
		local z = d:GetPivot().Z; local dup = false
		for _, bz in ipairs(bridgesZ) do if math.abs(bz - z) < 2 then dup = true end end
		if not dup then table.insert(bridgesZ, z) end
	elseif d:IsA("BasePart") and d.Name == "Walkway" then
		table.insert(walkways, {pos = d.Position, size = d.Size, right = d.CFrame.RightVector, look = d.CFrame.LookVector})
	end
end
local seen = {}
for _, d in ipairs(retire) do
	local up = d.Parent; local inner = false
	while up and up ~= J do if seen[up] then inner = true end; up = up.Parent end
	if not inner then seen[d] = true; d:SetAttribute("GardenWasIn", d.Parent:GetFullName()); d.Parent = replaced end
end
local nret = 0; for _ in pairs(seen) do nret += 1 end
table.sort(bridgesZ)
-- the garden bridge (the southernmost) moves north, its path line with it
for i, bz in ipairs(bridgesZ) do if math.abs(bz - GARDEN_BRIDGE_FROM) < 3 then bridgesZ[i] = GARDEN_BRIDGE_TO end end
for _, w in ipairs(walkways) do if math.abs(w.pos.Z - GARDEN_BRIDGE_FROM) < 6 then w.pos = Vector3.new(w.pos.X, w.pos.Y, w.pos.Z + (GARDEN_BRIDGE_TO - GARDEN_BRIDGE_FROM)) end end
print(string.format("QQ GARDEN3 retired %d (banks, black strips, footbridges at z %s, approach steps, the weir, the old canal boat, %d walkway paths, the black-cobble sheet) -> HudBackup.MomijiGardenReplaced", nret,
	(function() local t = {}; for _, z in ipairs(bridgesZ) do table.insert(t, string.format("%.0f", z)) end; return table.concat(t, " / ") end)(), #walkways))
-- ---------- 5. the meshes ----------
local old = J:FindFirstChild("MomijiGarden")
if old then
	local prev = hb:FindFirstChild("MomijiGarden_prev"); if prev then prev:Destroy() end      -- (one previous build kept, not a pile of 380-mesh backups)
	old.Name = "MomijiGarden_prev"; old.Parent = hb; print("QQ GARDEN3 the previous MomijiGarden -> HudBackup.MomijiGarden_prev (the one before it dropped)")
end
local G = Instance.new("Folder"); G.Name = "MomijiGarden"; G.Parent = J
local made, meshes, missing = 0, 0, {}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local key = colourKey(p.Name)
			p.Anchored = true; p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			local ckey = key
			if not MOSS then ckey = (key == "Rock_Moss" and "Rock_Grey") or (key == "Fall_Moss" and "Fall_Rock") or key end
			if BOAT_COL[key] then p.Color = BOAT_COL[key] elseif COL_OVERRIDE[key] then p.Color = COL_OVERRIDE[key] elseif COL[ckey] then p.Color = COL[ckey] else table.insert(missing, p.Name) end
			p.CanCollide = SOLID[key] == true; p.CanQuery = p.CanCollide; p.CanTouch = false
			if p:IsA("MeshPart") and (key == "Bridge_Deck" or key == "Slab_Stone" or key == "Wall_Coping" or key == "Wall_Stone" or key == "Steps_Stone" or key == "Steps_Landing" or key == "Skiff_Wood" or key == "Boat_Hull" or key == "Boat_Floor") then
				pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end)
			end
			if key == "Lantern_Paper" then
				p.Material = Enum.Material.Neon
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 214, 150); l.Range = 12; l.Brightness = 1.2; l.Shadows = false; l.Parent = p
			elseif key == "Fall_Water" then p.Material = Enum.Material.Glass; p.Transparency = 0.25; p.CastShadow = false; pcall(function() p.DoubleSided = true end)
			elseif key == "Fall_Foam" then p.Transparency = 0.15; p.CastShadow = false
			elseif key == "Wall_Stone" and FLAGSTONE_WALLS then p.Material = Enum.Material.Pavement; p.Color = Color3.new(1, 1, 1); pcall(function() p.MaterialVariant = "JM_PhotographicPath" end)
			elseif key:sub(1, 4) == "Koi_" then p.CastShadow = false
			elseif key:sub(1, 6) == "Skiff_" then p.Material = Enum.Material.Wood
			elseif key:sub(1, 5) == "Boat_" then
				if BOAT_WOOD and key ~= "Boat_Hat" and key ~= "Boat_Rope" then p.Material = Enum.Material.Wood end   -- (else SmoothPlastic: the colour truer to her photo)
				p.CastShadow = key ~= "Boat_Rope"
			end
			meshes += 1
		end
	end
end
local lowerCopies = 0
local function placeLower(kitName, at, yaw, label, parent)
	-- the same piece WALL_LOWER_COPY lower with its coping removed: the stonework continues down to the deeper bed (all under water)
	local m = place(kitName, at - Vector3.new(0, WALL_LOWER_COPY, 0), yaw, nil, label .. "_low", 1, parent)
	if m then
		for _, q in ipairs(m:GetDescendants()) do if q:IsA("BasePart") and colourKey(q.Name) == "Wall_Coping" then q:Destroy(); meshes -= 1 end end
		lowerCopies += 1
	end
	return m
end
function place(kitName, at, yaw, group, label, scale, parent)
	local src = KIT:FindFirstChild(kitName)
	if not src then table.insert(missing, kitName) return nil end
	local m
	if group then
		m = Instance.new("Model")
		for _, p in ipairs(src:GetDescendants()) do if p:IsA("BasePart") and (p.Name == group or p.Name:sub(1, #group + 1) == group .. "_") then p:Clone().Parent = m end end
		if #m:GetChildren() == 0 then table.insert(missing, kitName .. "/" .. group) return nil end
	else m = src:Clone() end
	m.Name = label or kitName
	local box = BB[group and (kitName .. "/" .. group) or kitName]
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position - (box.min + box.max) / 2)
	if scale and scale ~= 1 then pcall(function() m:ScaleTo(scale) end) end
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	dress(m); m.Parent = parent or G; made += 1
	return m
end
local rnd = Random.new(1003)
if #bridgesZ == 0 then bridgesZ = {-215} end
local function nearBridge(z, r) for _, bz in ipairs(bridgesZ) do if math.abs(z - bz) < r then return true end end; return false end
-- the walls: both sides, alternating patterns, then across both ends (the water face toward the canal)
local WF = Instance.new("Folder"); WF.Name = "CanalWalls"; WF.Parent = G
local k = 0
local z = Z1 + 4
while true do
	k += 1
	place(k % 2 == 0 and "canal_wall" or "canal_wall_b", Vector3.new(WEST, -WALL_DROP, z), 0, nil, "WallW" .. k, 1, WF)
	place(k % 2 == 1 and "canal_wall" or "canal_wall_b", Vector3.new(EAST, -WALL_DROP, z), 180, nil, "WallE" .. k, 1, WF)
	placeLower(k % 2 == 0 and "canal_wall" or "canal_wall_b", Vector3.new(WEST, -WALL_DROP, z), 0, "WallW" .. k, WF)
	placeLower(k % 2 == 1 and "canal_wall" or "canal_wall_b", Vector3.new(EAST, -WALL_DROP, z), 180, "WallE" .. k, WF)
	if z + 4 >= Z2 - 0.01 then break end
	z = math.min(z + 8, Z2 - 4)
end
local ends = 0
for i, dx in ipairs({-12, -4, 4, 12}) do
	place(i % 2 == 0 and "canal_wall" or "canal_wall_b", Vector3.new(CX + dx, -WALL_DROP, ZS), -90, nil, "WallS" .. i, 1, WF); ends += 1   -- its face toward +z (the water)
	place(i % 2 == 1 and "canal_wall" or "canal_wall_b", Vector3.new(CX + dx, -WALL_DROP, ZN), 90, nil, "WallN" .. i, 1, WF); ends += 1    -- its face toward -z
	placeLower(i % 2 == 0 and "canal_wall" or "canal_wall_b", Vector3.new(CX + dx, -WALL_DROP, ZS), -90, "WallS" .. i, WF)
	placeLower(i % 2 == 1 and "canal_wall" or "canal_wall_b", Vector3.new(CX + dx, -WALL_DROP, ZN), 90, "WallN" .. i, WF)
end
-- the bridges (deck ends at 1.0 = the levelled walkways' tops), their landing steps, and the stone steps down to the water beside each
local BF = Instance.new("Folder"); BF.Name = "Bridges"; BF.Parent = G
local BRIDGE_Y = 0.7
local stepsAt = {}
for i, bz in ipairs(bridgesZ) do
	place("bridge", Vector3.new(CX, BRIDGE_Y, bz), 0, nil, "TaikoBridge" .. i, 1, BF)
	local lo = BRIDGE_LANDING_TURN == 180 and -BB.bridge_steps.min.X or 0    -- the piece's origin is its top edge (x -3..0): turned round, it is set 3 outward so the treads stay outside the deck
	place("bridge_steps", Vector3.new(CX - BB.bridge.max.X - lo, 0, bz), 0 + BRIDGE_LANDING_TURN, nil, "LandingW" .. i, 1, BF)
	place("bridge_steps", Vector3.new(CX + BB.bridge.max.X + lo, 0, bz), 180 + BRIDGE_LANDING_TURN, nil, "LandingE" .. i, 1, BF)
	local sz = bz + BB.bridge.max.Z + 3.5                                   -- the stair just downstream (north) of the bridge
	place("canal_steps", Vector3.new(WEST, 0, sz), 0, nil, "WaterStepsW" .. i, 1, BF)
	place("canal_steps", Vector3.new(EAST, 0, sz), 180, nil, "WaterStepsE" .. i, 1, BF)
	placeLower("canal_steps", Vector3.new(WEST, 0, sz), 0, "WaterStepsW" .. i, BF)        -- the stair carries on down to the bed
	placeLower("canal_steps", Vector3.new(EAST, 0, sz), 180, "WaterStepsE" .. i, BF)
	table.insert(stepsAt, sz)
end
-- stepping-stone paths (the kit slabs) along each retired walkway's line, from the landing's foot out to the far end
local PF = Instance.new("Folder"); PF.Name = "SteppingStonePaths"; PF.Parent = G
local nslab = 0
for wi, w in ipairs(walkways) do
	local along = w.size.X >= w.size.Z and w.right or w.look                 -- the path's long axis
	local half = math.max(w.size.X, w.size.Z) / 2
	local e1, e2 = w.pos + along * half, w.pos - along * half
	local inner, outer = e1, e2
	if math.abs(e1.X - CX) > math.abs(e2.X - CX) then inner, outer = e2, e1 end
	local dir = (Vector3.new(outer.X, 0, outer.Z) - Vector3.new(inner.X, 0, inner.Z)).Unit
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local startD = BB.bridge.max.X - math.abs(inner.X - CX) + 3 + 1.4      -- the landing's foot (3 out from the deck end) plus half a slab
	local total = (outer - inner).Magnitude
	local d = math.max(startD, 1.4)
	while d < total - 0.8 do
		local at = Vector3.new(inner.X, 0, inner.Z) + dir * d + side * rnd:NextNumber(-0.7, 0.7)
		place("slabs", Vector3.new(at.X, rnd:NextNumber(-0.12, 0.0), at.Z), rnd:NextInteger(0, 359), "Slab" .. rnd:NextInteger(1, 3), "Path" .. wi .. "_" .. (nslab + 1), rnd:NextNumber(1.0, 1.25), PF)
		nslab += 1
		d += rnd:NextNumber(2.3, 2.6)
	end
end
print(string.format("QQ GARDEN3 stepping-stone paths: %d slabs along %d old walkway lines (tops 0.23-0.35 above the lawn, stride 2.3-2.6); bridge landings turned %d", nslab, #walkways, BRIDGE_LANDING_TURN))
-- the waterfall feeding the south end (its rocks over the end wall, the sheet landing in the water)
-- (the piece pours toward +z: its sheet runs from z -0.4 (top) to +1.0 (landing) with the foam at +1.2, its rocks behind at z -1..-7.5.
--  Origin 0.1 behind the end wall's face (ZS + 0.3 - 0.4): the sheet lands in the water just in front of the wall, the rocks pile on the
--  wall's end and the lawn behind - it was INSIDE the garden bridge before, "MAJOR issues")
place("waterfall", Vector3.new(CX, 1.0, ZS - 0.1), 0, nil, "Waterfall")
-- look test 1's approved pieces, by the garden bridge (the southernmost crossing)
local BZ = bridgesZ[1]
place("torii", Vector3.new(CX - 43, 0, BZ), 90, nil, "Torii")
place("pine", Vector3.new(CX + 28, 0, BZ + 13), 200, nil, "BlackPine")
local nl = 0
for i, bz in ipairs(bridgesZ) do
	for _, d in ipairs(i == 1 and {{-24, 6}, {-24, -6}, {24, 6}, {24, -6}} or {{-24, 6}, {24, 6}}) do
		place("lantern", Vector3.new(CX + d[1], 0, bz + d[2]), 0, nil, "StoneLantern" .. (nl + 1)); nl += 1
	end
end
for i, s in ipairs({{23, -9, "Slab1"}, {25.5, -13.5, "Slab2"}, {23.5, -18, "Slab3"}, {26, -22.5, "Slab1"}}) do place("slabs", Vector3.new(CX + s[1], 0.02, BZ + s[2]), i * 37, s[3], "Slab" .. i) end
-- kit rocks at the walls' feet on the lawn side, and by the falls
local RR = Instance.new("Folder"); RR.Name = "Rocks"; RR.Parent = G
local nr = 0
for zr = Z1 + 14, Z2 - 10, 37 do
	if not nearBridge(zr, 14) and rnd:NextNumber() < 0.75 then
		local side = rnd:NextNumber() < 0.5 and -1 or 1
		local x = side < 0 and (WEST + BB.canal_wall.min.X - rnd:NextNumber(0.8, 1.6)) or (EAST - BB.canal_wall.min.X + rnd:NextNumber(0.8, 1.6))
		place("rocks", Vector3.new(x, 0.1, zr + rnd:NextNumber(-3, 3)), rnd:NextInteger(0, 359), "Rock" .. rnd:NextInteger(1, 3), "WallRock", rnd:NextNumber(0.8, 1.3), RR); nr += 1
	end
end
for _, d in ipairs({{-11, -5}, {11.5, -4.5}, {-13.5, -8}}) do place("rocks", Vector3.new(CX + d[1], 0.15, ZS + d[2]), rnd:NextInteger(0, 359), "Rock" .. rnd:NextInteger(1, 3), "FallsRock", rnd:NextNumber(1.0, 1.4), RR); nr += 1 end   -- on the lawn behind the end wall, with the falls
-- ---------- 6. life on the water: koi swimming slow loops, a skiff moored at the steps and one gliding along the long reach ----------
-- (each Model gets Life* attributes; the CanalLife client script moves it round an oval: z = Mid + Half sin a, x = X + Amp cos a, nose along the way)
local LF = Instance.new("Folder"); LF.Name = "CanalLife"; LF.Parent = G
local reaches = {}
do
	local marks = {Z1 + 10}
	for _, bz in ipairs(bridgesZ) do table.insert(marks, bz) end
	table.insert(marks, Z2 - 6)
	for i = 1, #marks - 1 do
		local a, b = marks[i] + (i > 1 and 14 or 0), marks[i + 1] - (i < #marks - 1 and 14 or 0)
		if b - a > 24 then table.insert(reaches, {a, b}) end
	end
	table.sort(reaches, function(p, q) return (p[2] - p[1]) > (q[2] - q[1]) end)
end
local function life(m, x, mid, half, amp, y, speed, bob)
	-- a meander, not a line: x = X + A1 sin(a + p1) + A2 sin(2.7a + p2) (within CX +- 8), z = Mid + Half sin(0.6a + p3), a = phase + t speed;
	-- the nose follows the way with gentle turns (CanalLife eases the heading)
	m:SetAttribute("LifeX", x); m:SetAttribute("LifeMid", mid); m:SetAttribute("LifeHalf", half); m:SetAttribute("LifeAmp", amp)
	m:SetAttribute("LifeA2", amp * 0.5); m:SetAttribute("LifeP1", rnd:NextNumber(0, 6.28)); m:SetAttribute("LifeP2", rnd:NextNumber(0, 6.28)); m:SetAttribute("LifeP3", rnd:NextNumber(0, 6.28))
	m:SetAttribute("LifeY", y); m:SetAttribute("LifeSpeed", speed); m:SetAttribute("LifePhase", rnd:NextNumber(0, 6.28)); m:SetAttribute("LifeBob", bob)
	m:PivotTo(CFrame.new(x, y, mid))
end
local nkoi = 0
for i = 1, 5 do
	local r = reaches[(i - 1) % math.max(1, #reaches) + 1] or {Z1 + 20, Z2 - 20}
	local half = math.min(40, (r[2] - r[1]) / 2 - 4)
	local mid = (r[1] + r[2]) / 2 + rnd:NextNumber(-(r[2] - r[1]) / 2 + half + 2, (r[2] - r[1]) / 2 - half - 2)
	local m
	if MESHY_KOI then
		m = KOI:Clone(); m.Name = "Koi" .. i
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false end end
		local cf, size = m:GetBoundingBox()
		local long = math.max(size.X, size.Y, size.Z)
		if long > 0 then pcall(function() m:ScaleTo(2.4 / long) end) end
		cf = m:GetBoundingBox()
		m.WorldPivot = CFrame.new(cf.Position) * MESHY_KOI_FACING
		m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic                   -- (streams in whole: CanalLife moves the pivot from the first frame)
		m.Parent = LF; made += 1
	else
		m = place("koi", Vector3.new(CX, WATER - 0.6, mid), 0, ({"Koi_Orange", "Koi_White", "Koi_Gold"})[(i - 1) % 3 + 1], "Koi" .. i, rnd:NextNumber(0.85, 1.15), LF)
		if m then local cf = m:GetBoundingBox(); m.WorldPivot = CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(-90), 0); m.Parent = nil; m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic; m.Parent = LF end   -- (built along +x: its -Z is then the head)
	end
	if m then
		local _, size = m:GetBoundingBox()
		life(m, CX + rnd:NextNumber(-2, 2), mid, half, rnd:NextNumber(3.5, 4.0), WATER - KOI_TOP_UNDER - size.Y / 2, (i % 2 == 0 and 1 or -1) * rnd:NextNumber(0.06, 0.1), 0.04); nkoi += 1   -- its top KOI_TOP_UNDER under the surface; x within CX +- 8
	end
end
-- the boats (runner 7's "boat" from her Yanagawa photo: 27 long with the bow horns, 7.3 wide, the bow at +Z; its origin on the flat
-- bottom goes at WATER - 0.75 so the floor boards sit 0.3 above the water). The pivot is turned so its -Z is the bow (like the koi).
local BOAT_Y = WATER - 0.75
local function boat(label, at, bowYaw)
	local m = place("boat", at, 0, nil, label, 1, LF)
	if m then
		m.WorldPivot = CFrame.new(m:GetPivot().Position) * CFrame.Angles(0, math.rad(180), 0)
		m:PivotTo(CFrame.new(at) * CFrame.Angles(0, bowYaw, 0))
		m.Parent = nil; m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic; m.Parent = LF   -- (streams in whole, so the rope never trails 17 studs behind the hull)
	end
	return m
end
-- moored along the west wall just past the garden bridge's water steps, bow to the north, a touch off the wall
local BOAT_Z = stepsAt[1] + 19                                              -- ("only one boat is needed in the waterway, not 2": the moored one stays, clear of the garden bridge's water steps)
boat("BoatMoored", Vector3.new(WEST + 5.0, BOAT_Y, BOAT_Z), math.pi + 0.05)
local lifeScript = Instance.new("Script"); lifeScript.Name = "CanalLifeScript"; lifeScript.RunContext = Enum.RunContext.Client
lifeScript.Source = [==[
-- the koi meander along the canal (Life* attributes on each Model): x = X + A1 sin(a + p1) + A2 sin(2.7 a + p2), z = Mid + Half sin(0.6 a + p3),
-- a = phase + t speed; the nose follows the way, the heading eased so the turns are gentle; client-side, synced by server time
local RunService = game:GetService("RunService")
local folder = script.Parent
local yaws = {}
RunService.Heartbeat:Connect(function(dt)
	local t = workspace:GetServerTimeNow()
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("LifeHalf") then
			local x0, mid, half, a1 = m:GetAttribute("LifeX"), m:GetAttribute("LifeMid"), m:GetAttribute("LifeHalf"), m:GetAttribute("LifeAmp")
			local a2, p1, p2, p3 = m:GetAttribute("LifeA2") or 0, m:GetAttribute("LifeP1") or 0, m:GetAttribute("LifeP2") or 0, m:GetAttribute("LifeP3") or 0
			local sp, ph = m:GetAttribute("LifeSpeed"), m:GetAttribute("LifePhase")
			local a = ph + t * sp
			local bob = math.sin(t * 1.3 + ph * 3) * m:GetAttribute("LifeBob")
			local x = x0 + a1 * math.sin(a + p1) + a2 * math.sin(2.7 * a + p2)
			local z = mid + half * math.sin(0.6 * a + p3)
			local dx = (a1 * math.cos(a + p1) + 2.7 * a2 * math.cos(2.7 * a + p2)) * sp
			local dz = 0.6 * half * math.cos(0.6 * a + p3) * sp
			local pos = Vector3.new(x, m:GetAttribute("LifeY") + bob, z)
			local heading = m:GetAttribute("LifeHeading")
			if heading then
				m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, heading, 0) * CFrame.Angles(0.5 * bob, 0, 0.4 * bob))   -- a fixed heading, a slow rock
			else
				local want = yaws[m]
				if dx * dx + dz * dz > 1e-6 then want = math.atan2(-dx, -dz) end      -- the yaw whose -Z points along (dx, dz)
				if want then
					local cur = yaws[m] or want
					local diff = (want - cur + math.pi) % (2 * math.pi) - math.pi
					cur = cur + diff * math.min(1, dt * 1.5)                       -- eased: gentle turns
					yaws[m] = cur
					m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, cur, 0) * CFrame.Angles(0, 0, 0.06 * bob))
				end
			end
		end
	end
end)
]==]
lifeScript.Parent = LF
print(string.format("QQ GARDEN3 life: %d koi (%s, tops %.2f under the surface, meandering) in %d reaches, ONE boat moored at z %.0f, all Atomic; CanalLife client script; moss %s, boat %s in the houses' wood colours", nkoi, MESHY_KOI and "Meshy" or "koi.fbx", KOI_TOP_UNDER, #reaches, BOAT_Z, MOSS and "on" or "off (grey)", BOAT_WOOD and "Wood" or "SmoothPlastic"))
-- ---------- 7. the floating maple by the north bridge (east side): it stood on the old walkway at z 80, 1.9 above the lawn ----------
local lowered = 0
local groves = J:FindFirstChild("Blender maple and blossom groves")
if groves then
	for _, d in ipairs(groves:GetChildren()) do
		if d:IsA("BasePart") and (d.Name == "Solid branching trunk" or d.Name == "Vermilion maple - individual Blender leaves") and d:GetAttribute("GardenOldCF") == nil then
			local want = d.Name == "Solid branching trunk" and Vector3.new(6125.1, 5.22, 83.0) or Vector3.new(6125.0, 9.02, 83.1)
			if (d.Position - want).Magnitude < 1.0 then d:SetAttribute("GardenOldCF", d.CFrame); d.CFrame = d.CFrame - Vector3.new(0, 1.92, 0); lowered += 1 end
		end
	end
end
print(string.format("QQ GARDEN3 the floating maple at (6125, 83) lowered 1.92 to the lawn: %d parts (trunk + leaves; 0 on a re-run)", lowered))
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Momiji garden look test 3") end)
if #missing > 0 then print("QQ GARDEN3 missing or uncoloured: " .. table.concat(missing, ", ")) end
print(string.format("QQ GARDEN3 DONE: MomijiGarden - %d pieces (%d wall segments + %d end segments, %d lower copies down to the bed, %d bridges with landings and water steps, %d path slabs, %d lanterns, %d rocks), %d meshes; walls %s; no parts built", made, k * 2, ends, lowerCopies, #bridgesZ, nslab, nl, nr, meshes, FLAGSTONE_WALLS and "in the palace flagstone (Pavement / JM_PhotographicPath)" or "in cut stone"))

#!/usr/bin/env python3
"""Builds tools/japan/garden/garden_look3.lua (job 125, LOOK TEST 3 - the canal KEPT as a canal). Shannon after look test 2: "actually, I
like the look as a canal, how can we keep it as a canal?"; via runner 7: a proper Japanese town canal (Kyoto's Shirakawa, Tsuwano) -
the channel straight, the same width, the water at 1.3 as now; stone-block walls with a coping replacing the flat concrete slabs; stone
steps down to the water by each bridge; the taiko bridges seated so their ends meet the walkways (no white approach steps); the
walkways flat on the ground; the black JP_Canal_Rocks strips retired and the terrain rock in the end pool cleared; "The waterfall feeds
it"; "Yes, koi in the canal" (her Meshy koi, facing 180, swimming slowly along it); "skiff in the water too?" (a wooden punt moored at
the steps, another gliding along the long reach - now runner 7's "boat" from her Yanagawa photo, out_boat/gen_boat.py, in place of
out3's skiff: "to go in the water instead of that terrible thing in there now" = LanternStreet."Canal boat", retired); the approved
torii, lanterns, pine, rocks and slabs where they fit. NO moss, reeds, lilies or pond rim; the grass unchanged; meshes only. Kit =
ServerStorage.JapanGardenKit: out1's Models + out3's canal_wall, canal_wall_b, canal_steps, bridge_steps + out_boat's boat + koi_meshy
(else out2's koi). Placed by bounding box (pieces.json). Run from the repo root."""
import json, pathlib, re, ast
HERE = pathlib.Path(__file__).resolve().parent
info = json.load(open(HERE / "out1/pieces.json")); info.update(json.load(open(HERE / "out2/pieces.json"))); info.update(json.load(open(HERE / "out2/pieces_2b.json")))
info.update(json.load(open(HERE / "out3/pieces.json"))); info.update(json.load(open(HERE / "out_boat/pieces.json")))
COL = {}
for g in ("gen_garden1.py", "gen_garden2b.py", "gen_garden3.py", "gen_boat.py"):
    src = re.sub(r"#[^\n]*", "", (HERE / g).read_text())
    COL.update(ast.literal_eval(re.search(r"COL = (\{.*?\})\n", src, re.S).group(1)))
def v3(v): return "Vector3.new(%s, %s, %s)" % tuple(v)
bb = ",\n".join('\t["%s"] = {min = %s, max = %s}' % (k, v3(v["min"]), v3(v["max"])) for k, v in info.items())
cols = ",\n".join('\t%s = Color3.new(%s, %s, %s)' % (k, *v) for k, v in COL.items())
lua = r'''-- garden_look3.lua (job 125, LOOK TEST 3: the canal kept as a canal; a play-test PREVIEW first, then Studio EDIT on her word; re-runnable).
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
-- look test 1's torii, pine, lit lanterns, rocks and stepping slabs. No parts are built. Output "QQ GARDEN3".
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
local MESHY_KOI_FACING = CFrame.Angles(0, math.rad(180), 0)   -- the Meshy koi's head points +Z (runner 7's renders); Roblox forward is -Z, so half a turn. If they swim backwards/sideways: 0 or math.rad(90)
print("QQ GARDEN3 koi: " .. (MESHY_KOI and "Shannon's Meshy koi (kit 'koi_meshy')" or "out2/koi.fbx (no 'koi_meshy' in the kit)"))
local BB = {
@@BB@@
}
local COL = {
@@COL@@
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
local BED_Y = -1.3                                                          -- the canal's new flat Slate bed (the wall meshes reach -1.2), burying the jagged rock ridge at -10
local WALL_DROP = 0.0                                                       -- (the "teeth" at the lawn were the deep joints between the lawn-face blocks: fixed in the mesh, gen_garden3; the coping stays at 2.1)
local BOAT_COL = {Boat_Hull = Color3.fromRGB(103, 72, 48), Boat_Rail = Color3.fromRGB(65, 47, 33), Boat_Beam = Color3.fromRGB(65, 47, 33), Boat_Seam = Color3.fromRGB(44, 33, 28),
	Boat_Floor = Color3.fromRGB(120, 80, 50), Boat_Deck = Color3.fromRGB(120, 80, 50), Boat_Bench = Color3.fromRGB(120, 80, 50)}   -- the canal houses' wood colours ("the color of the boat ... sticks out")
-- ---------- 1. the canal ----------
local banks = {}
for _, d in ipairs(J:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Canal stone bank" then table.insert(banks, d) end end
if #banks ~= 2 then print("QQ GARDEN3 ABORT: expected 2 'Canal stone bank' parts, found " .. #banks) return end
table.sort(banks, function(a, b) return a.Position.X < b.Position.X end)
local WEST = banks[1].Position.X + banks[1].Size.X / 2                      -- the water-side faces
local EAST = banks[2].Position.X - banks[2].Size.X / 2
local CX = (WEST + EAST) / 2
local Z1 = math.min(banks[1].Position.Z - banks[1].Size.Z / 2, banks[2].Position.Z - banks[2].Size.Z / 2)
local Z2 = math.max(banks[1].Position.Z + banks[1].Size.Z / 2, banks[2].Position.Z + banks[2].Size.Z / 2)
local ZS, ZN = Z1 + 3.5, Z2 + 1.5                                             -- the end walls' water faces (south: where the weir stood; north: at the closure)
print(string.format("QQ GARDEN3 canal: water faces x %.1f / %.1f (centre %.1f), z %.1f .. %.1f, water %.1f; end walls at z %.1f / %.1f", WEST, EAST, CX, Z1, Z2, WATER, ZS, ZN))
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Momiji garden look test 3") end)
-- ---------- 2. the terrain: a flat dark Slate bed along the whole channel, the water flat at 1.3 to the end walls ----------
-- (Roblox draws a row's surface at (its top - 2) + 4 x occupancy: the -4..0 row at 0.825 = the water at 1.3; the same row's solid at
-- (BED_Y + 2) / 4 = the bed at BED_Y, with every row below full Slate)
local tbed, tw = 0, 0
do
	local x0, x1 = math.floor(WEST / 4) * 4, math.ceil(EAST / 4) * 4
	local zA, zB = math.floor((Z1 - 2) / 4) * 4, math.ceil((Z2 + 4) / 4) * 4
	local bedOcc = (BED_Y + 2) / 4
	for zs = zA, zB - 1, 64 do
		local r = Region3.new(Vector3.new(x0, -16, zs), Vector3.new(x1, 8, math.min(zs + 64, zB)))
		local ch = T:ReadVoxelChannels(r, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
		local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
		for ix = 1, #SO do
			local x = x0 + (ix - 0.5) * 4
			if x > WEST and x < EAST then
				for iy = 1, #SO[ix] do
					local y0 = -16 + (iy - 1) * 4
					for iz = 1, #SO[ix][iy] do
						if y0 <= -8 then SM[ix][iy][iz] = Enum.Material.Slate; SO[ix][iy][iz] = 1; LO[ix][iy][iz] = 0; tbed += 1
						elseif y0 == -4 then
							SM[ix][iy][iz] = Enum.Material.Slate; SO[ix][iy][iz] = bedOcc; LO[ix][iy][iz] = 0.825; tw += 1   -- the bed at BED_Y, the water to 1.3
						else SO[ix][iy][iz] = 0; LO[ix][iy][iz] = 0 end
					end
				end
			end
		end
		T:WriteVoxelChannels(r, 4, {SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO})
	end
end
print(string.format("QQ GARDEN3 terrain: a flat Slate bed at %.1f along the channel (%d cells below, %d bed/water cells), the water flat at %.1f", BED_Y, tbed, tw, WATER))
-- ---------- 3. retire the concrete banks, the black strips, the old bridges and steps, the weir ----------
local replaced = hb:FindFirstChild("MomijiGardenReplaced") or Instance.new("Folder"); replaced.Name = "MomijiGardenReplaced"; replaced.Parent = hb
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
local seen = {}
for _, d in ipairs(retire) do
	local up = d.Parent; local inner = false
	while up and up ~= J do if seen[up] then inner = true end; up = up.Parent end
	if not inner then seen[d] = true; d:SetAttribute("GardenWasIn", d.Parent:GetFullName()); d.Parent = replaced end
end
local nret = 0; for _ in pairs(seen) do nret += 1 end
table.sort(bridgesZ)
print(string.format("QQ GARDEN3 retired %d (banks, black strips, footbridges at z %s, approach steps, the weir, the old canal boat, %d walkway paths, the black-cobble sheet) -> HudBackup.MomijiGardenReplaced", nret,
	(function() local t = {}; for _, z in ipairs(bridgesZ) do table.insert(t, string.format("%.0f", z)) end; return table.concat(t, " / ") end)(), #walkways))
-- ---------- 5. the meshes ----------
local old = J:FindFirstChild("MomijiGarden")
if old then local n = 1; while hb:FindFirstChild("MomijiGarden_pre_" .. n) do n += 1 end; old.Name = "MomijiGarden_pre_" .. n; old.Parent = hb end
local G = Instance.new("Folder"); G.Name = "MomijiGarden"; G.Parent = J
local made, meshes, missing = 0, 0, {}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local key = colourKey(p.Name)
			p.Anchored = true; p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			local ckey = key
			if not MOSS then ckey = (key == "Rock_Moss" and "Rock_Grey") or (key == "Fall_Moss" and "Fall_Rock") or key end
			if BOAT_COL[key] then p.Color = BOAT_COL[key] elseif COL[ckey] then p.Color = COL[ckey] else table.insert(missing, p.Name) end
			p.CanCollide = SOLID[key] == true; p.CanQuery = p.CanCollide; p.CanTouch = false
			if p:IsA("MeshPart") and (key == "Bridge_Deck" or key == "Slab_Stone" or key == "Wall_Coping" or key == "Wall_Stone" or key == "Steps_Stone" or key == "Steps_Landing" or key == "Skiff_Wood" or key == "Boat_Hull" or key == "Boat_Floor") then
				pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end)
			end
			if key == "Lantern_Paper" then
				p.Material = Enum.Material.Neon
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 214, 150); l.Range = 12; l.Brightness = 1.2; l.Shadows = false; l.Parent = p
			elseif key == "Fall_Water" then p.Material = Enum.Material.Glass; p.Transparency = 0.25; p.CastShadow = false; pcall(function() p.DoubleSided = true end)
			elseif key == "Fall_Foam" then p.Transparency = 0.15; p.CastShadow = false
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
local function place(kitName, at, yaw, group, label, scale, parent)
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
	if z + 4 >= Z2 - 0.01 then break end
	z = math.min(z + 8, Z2 - 4)
end
local ends = 0
for i, dx in ipairs({-12, -4, 4, 12}) do
	place(i % 2 == 0 and "canal_wall" or "canal_wall_b", Vector3.new(CX + dx, -WALL_DROP, ZS), -90, nil, "WallS" .. i, 1, WF); ends += 1   -- its face toward +z (the water)
	place(i % 2 == 1 and "canal_wall" or "canal_wall_b", Vector3.new(CX + dx, -WALL_DROP, ZN), 90, nil, "WallN" .. i, 1, WF); ends += 1    -- its face toward -z
end
-- the bridges (deck ends at 1.0 = the levelled walkways' tops), their landing steps, and the stone steps down to the water beside each
local BF = Instance.new("Folder"); BF.Name = "Bridges"; BF.Parent = G
local BRIDGE_Y = 0.7
local stepsAt = {}
for i, bz in ipairs(bridgesZ) do
	place("bridge", Vector3.new(CX, BRIDGE_Y, bz), 0, nil, "TaikoBridge" .. i, 1, BF)
	place("bridge_steps", Vector3.new(CX - BB.bridge.max.X, 0, bz), 0 + BRIDGE_LANDING_TURN, nil, "LandingW" .. i, 1, BF)
	place("bridge_steps", Vector3.new(CX + BB.bridge.max.X, 0, bz), 180 + BRIDGE_LANDING_TURN, nil, "LandingE" .. i, 1, BF)
	local sz = bz + BB.bridge.max.Z + 3.5                                   -- the stair just downstream (north) of the bridge
	place("canal_steps", Vector3.new(WEST, 0, sz), 0, nil, "WaterStepsW" .. i, 1, BF)
	place("canal_steps", Vector3.new(EAST, 0, sz), 180, nil, "WaterStepsE" .. i, 1, BF)
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
place("waterfall", Vector3.new(CX, 1.0, ZS + 1.5), 0, nil, "Waterfall")
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
for _, d in ipairs({{-11, -2}, {11.5, -1}, {-13.5, 3}}) do place("rocks", Vector3.new(CX + d[1], 0.15, ZS + d[2]), rnd:NextInteger(0, 359), "Rock" .. rnd:NextInteger(1, 3), "FallsRock", rnd:NextNumber(1.0, 1.4), RR); nr += 1 end
-- ---------- 6. life on the water: koi swimming slow loops, a skiff moored at the steps and one gliding along the long reach ----------
-- (each Model gets Life* attributes; the CanalLife client script moves it round an oval: z = Mid + Half sin a, x = X + Amp cos a, nose along the way)
local LF = Instance.new("Folder"); LF.Name = "CanalLife"; LF.Parent = G
local reaches = {}
do
	local marks = {Z1 + 10}
	for _, bz in ipairs(bridgesZ) do table.insert(marks, bz) end
	table.insert(marks, Z2 - 6)
	for i = 1, #marks - 1 do
		local a, b = marks[i] + (i > 1 and 10 or 0), marks[i + 1] - (i < #marks - 1 and 10 or 0)
		if b - a > 24 then table.insert(reaches, {a, b}) end
	end
	table.sort(reaches, function(p, q) return (p[2] - p[1]) > (q[2] - q[1]) end)
end
local function life(m, x, mid, half, amp, y, speed, bob)
	m:SetAttribute("LifeX", x); m:SetAttribute("LifeMid", mid); m:SetAttribute("LifeHalf", half); m:SetAttribute("LifeAmp", amp)
	m:SetAttribute("LifeY", y); m:SetAttribute("LifeSpeed", speed); m:SetAttribute("LifePhase", rnd:NextNumber(0, 6.28)); m:SetAttribute("LifeBob", bob)
	m:PivotTo(CFrame.new(x + amp, y, mid))
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
		life(m, CX + rnd:NextNumber(-4, 4), mid, half, rnd:NextNumber(2.5, 5), WATER - KOI_TOP_UNDER - size.Y / 2, (i % 2 == 0 and 1 or -1) * rnd:NextNumber(0.05, 0.09), 0.04); nkoi += 1   -- its top KOI_TOP_UNDER under the surface
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
boat("BoatMoored", Vector3.new(WEST + 5.0, BOAT_Y, stepsAt[1] + 17), math.pi + 0.05)
do
	-- poled back and forth along the longest reach with a FIXED heading (a punt goes stern-first on the way back): no turning in a 25-wide canal
	local r = reaches[1] or {Z1 + 30, Z2 - 30}
	local half = math.max(6, (r[2] - r[1]) / 2 - 16)
	local m = boat("BoatPoled", Vector3.new(CX + 2, BOAT_Y, (r[1] + r[2]) / 2), math.pi)
	if m then life(m, CX + 2, (r[1] + r[2]) / 2, half, 0.6, BOAT_Y, 0.035, 0.03); m:SetAttribute("LifeHeading", math.pi) end
end
local lifeScript = Instance.new("Script"); lifeScript.Name = "CanalLifeScript"; lifeScript.RunContext = Enum.RunContext.Client
lifeScript.Source = [==[
-- the koi and the gliding skiff move round slow ovals along the canal (Life* attributes on each Model); client-side, synced by server time
local RunService = game:GetService("RunService")
local folder = script.Parent
RunService.Heartbeat:Connect(function()
	local t = workspace:GetServerTimeNow()
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("LifeHalf") then
			local x0, mid, half, amp = m:GetAttribute("LifeX"), m:GetAttribute("LifeMid"), m:GetAttribute("LifeHalf"), m:GetAttribute("LifeAmp")
			local sp, ph = m:GetAttribute("LifeSpeed"), m:GetAttribute("LifePhase")
			local a = ph + t * sp
			local bob = math.sin(t * 1.3 + ph * 3) * m:GetAttribute("LifeBob")
			local pos = Vector3.new(x0 + amp * math.cos(a), m:GetAttribute("LifeY") + bob, mid + half * math.sin(a))
			local vel = Vector3.new(-amp * math.sin(a), 0, half * math.cos(a)) * sp
			local heading = m:GetAttribute("LifeHeading")
			if heading then m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, heading, 0) * CFrame.Angles(0.5 * bob, 0, 0.4 * bob))   -- a fixed heading, a slow rock
			elseif vel.Magnitude > 1e-4 then m:PivotTo(CFrame.lookAt(pos, pos + vel.Unit) * CFrame.Angles(0, 0, 0.06 * bob)) end
		end
	end
end)
]==]
lifeScript.Parent = LF
print(string.format("QQ GARDEN3 life: %d koi (%s, tops %.2f under the surface) in %d reaches, a boat moored at z %.0f and one poled along the longest reach, all Atomic; CanalLife client script; moss %s, boats %s in the houses' wood colours", nkoi, MESHY_KOI and "Meshy" or "koi.fbx", KOI_TOP_UNDER, #reaches, stepsAt[1] + 17, MOSS and "on" or "off (grey)", BOAT_WOOD and "Wood" or "SmoothPlastic"))
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Momiji garden look test 3") end)
if #missing > 0 then print("QQ GARDEN3 missing or uncoloured: " .. table.concat(missing, ", ")) end
print(string.format("QQ GARDEN3 DONE: MomijiGarden - %d pieces (%d wall segments + %d end segments, %d bridges with landings and water steps, %d path slabs, %d lanterns, %d rocks), %d meshes; no parts built", made, k * 2, ends, #bridgesZ, nslab, nl, nr, meshes))
'''
lua = lua.replace("@@BB@@", bb).replace("@@COL@@", cols)
assert "@@" not in lua
(HERE / "garden_look3.lua").write_text(lua, encoding="utf-8")
print("garden_look3.lua", len(lua.encode()), "bytes")

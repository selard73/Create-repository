-- shopbacks2.lua (runner 7, Oct 17 2026): the backs of the ten market shops finished, round 2. Round 1 (shopbacks1 / kit19) was
-- previewed and rejected: "the doors are not connected to the wall", "what are those red white and blue hanging things?", "that looks
-- terrible" - never installed. Round 2 (kit japan_kit20_shop_backs2.fbx, gen_shop_back2.py): the door and window are SET INTO the wall
-- (a dark recess 0.5 deep behind the wall plane), hoods in the shops' roof tile, a vertical lattice window, and yard things that read:
-- a wide water tub with a ladle, a firewood lean-to with its own tile roof, crates, a sake barrel, a broom against the wall, a drainpipe
-- down a corner. No laundry, no bins. For each shop: the back wall plane by a ray from behind; door off centre; window on the other
-- side; drainpipe at one corner; two or three yard things along the wall inside the shop's width, clear of the door; all on the lawn (y 0).
-- Re-runnable (JapanMap.ShopBacks is rebuilt). Output "QQ SHOPBACKS2". Undo: delete JapanMap.ShopBacks.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local M = J and J:FindFirstChild("Outdoor market revision")
local KIT = SS:FindFirstChild("JapanGardenKit")
if not (M and KIT) then print("QQ SHOPBACKS2 ABORT: JapanMap.'Outdoor market revision' or ServerStorage.JapanGardenKit missing") return end
local PIECES = {"back_door2", "back_window2", "lattice_panel", "awning_section", "chochin", "crate_stack2", "sake_barrel2", "water_tub", "wood_shed", "broom", "drainpipe"}
for _, n in ipairs(PIECES) do if not KIT:FindFirstChild(n) then print("QQ SHOPBACKS2 ABORT: the kit has no Model '" .. n .. "' - import japan_kit20_shop_backs2.fbx") return end end
local RECESS = 0.5                                                                        -- how far the door / window recess goes into the wall
-- each shop its own back (Shannon: "the rear for each should vary, it is not exactly the same in real life"):
--   yard = the things on the lawn; lattice = the dark band: full / left / right / none; awning = full / door (over the door only);
--   doors = 1 or 2 (a double door for the storerooms); gwin = ground-floor windows 0..2; upper = upper-floor windows 0..2 (two-storey shops);
--   lanterns 0..2; pipes = S / N / both corners; doorAt = -1 (south) / 0 (centre) / 1 (north)
local SHOPS = {
	{"Sushi bar",            {"sake_barrel2", "water_tub", "crate_stack2"}, lattice = "full",  awning = "full", doors = 1, gwin = 2, upper = 0, lanterns = 1, pipes = "S",    doorAt = 1},
	{"Rice and provisions",  {"crate_stack2", "crate_stack2", "sake_barrel2"}, lattice = "none", awning = "door", doors = 2, gwin = 1, upper = 0, lanterns = 0, pipes = "N",    doorAt = 0},
	{"Paper umbrella craft", {"crate_stack2", "broom"},                  lattice = "left",  awning = "full", doors = 1, gwin = 2, upper = 2, lanterns = 1, pipes = "S",    doorAt = -1},
	{"Calligraphy teahouse", {"wood_shed", "water_tub", "broom"},        lattice = "right", awning = "full", doors = 1, gwin = 2, upper = 2, lanterns = 1, pipes = "N",    doorAt = 1},
	{"Mikan greengrocer",    {"crate_stack2", "crate_stack2", "crate_stack2"}, lattice = "none", awning = "door", doors = 2, gwin = 1, upper = 0, lanterns = 0, pipes = "S",    doorAt = 0},
	{"Ramen kitchen",        {"sake_barrel2", "water_tub", "wood_shed"},  lattice = "full",  awning = "full", doors = 1, gwin = 2, upper = 0, lanterns = 1, pipes = "N",    doorAt = -1},
	{"Lantern workshop",     {"wood_shed", "crate_stack2"},               lattice = "left",  awning = "full", doors = 1, gwin = 2, upper = 2, lanterns = 2, pipes = "both", doorAt = -1},
	{"Kimono atelier",       {"water_tub", "broom"},                      lattice = "full",  awning = "full", doors = 1, gwin = 2, upper = 2, lanterns = 1, pipes = "N",    doorAt = 1},
	{"Kimono shop",          {"crate_stack2", "broom"},                   lattice = "right", awning = "door", doors = 1, gwin = 2, upper = 2, lanterns = 0, pipes = "S",    doorAt = -1},
	{"Cat cafe",             {"water_tub", "crate_stack2", "broom"},      lattice = "full",  awning = "full", doors = 1, gwin = 2, upper = 2, lanterns = 1, pipes = "both", doorAt = 0},
}
local C = Color3.fromRGB
local TILE = {Enum.Material.Slate, C(58, 58, 66)}
local LOOK = {
	Door_Reveal = {Enum.Material.SmoothPlastic, C(31, 26, 21)}, Door_Wood = {Enum.Material.Wood, C(115, 77, 46)}, Door_Frame = {Enum.Material.Wood, C(76, 54, 36)}, Door_Step = {Enum.Material.Slate, C(128, 125, 118)}, Door_Hood = {Enum.Material.Wood, C(76, 54, 36)}, Door_Tile = TILE,
	Win_Reveal = {Enum.Material.SmoothPlastic, C(31, 26, 21)}, Win_Paper = {Enum.Material.SmoothPlastic, C(230, 219, 189)}, Win_Bars = {Enum.Material.Wood, C(76, 54, 36)}, Win_Frame = {Enum.Material.Wood, C(76, 54, 36)}, Win_Sill = {Enum.Material.Wood, C(92, 66, 43)}, Win_Tile = TILE,
	Crate_Wood = {Enum.Material.WoodPlanks, C(158, 120, 77)}, Crate_Band = {Enum.Material.Wood, C(102, 77, 48)},
	Barrel_Straw = {Enum.Material.Fabric, C(199, 168, 97)}, Barrel_Rope = {Enum.Material.Fabric, C(140, 115, 71)}, Barrel_Lid = {Enum.Material.Wood, C(140, 107, 66)},
	Tub_Wood = {Enum.Material.Wood, C(133, 97, 61)}, Tub_Hoop = {Enum.Material.Metal, C(56, 54, 51)}, Tub_Ladle = {Enum.Material.SmoothPlastic, C(179, 168, 97)},
	Shed_Post = {Enum.Material.Wood, C(92, 69, 46)}, Shed_Tile = TILE, Wood_Log = {Enum.Material.Wood, C(102, 71, 46)}, Wood_End = {Enum.Material.Wood, C(194, 158, 107)},
	Broom_Handle = {Enum.Material.SmoothPlastic, C(179, 168, 97)}, Broom_Head = {Enum.Material.Fabric, C(153, 128, 71)},
	Pipe_Metal = {Enum.Material.Metal, C(77, 77, 82)}, Pipe_Shoe = {Enum.Material.Slate, C(128, 125, 118)},
	Lattice_Wood = {Enum.Material.Wood, C(56, 38, 26)}, Lattice_Plinth = {Enum.Material.Slate, C(77, 74, 71)}, Lattice_Back = {Enum.Material.SmoothPlastic, C(41, 31, 23)},
	Awning_Tile = TILE, Awning_Wood = {Enum.Material.Wood, C(76, 54, 36)}, Door_Paper = {Enum.Material.SmoothPlastic, C(230, 219, 189)},
	Chochin_Arm = {Enum.Material.Wood, C(76, 54, 36)}, Chochin_Paper = {Enum.Material.Neon, C(245, 237, 214)}, Chochin_Band = {Enum.Material.SmoothPlastic, C(184, 41, 31)},
}
local NOCOLLIDE = {Win_Paper = true, Win_Bars = true, Win_Reveal = true, Door_Reveal = true, Door_Paper = true, Tub_Ladle = true, Broom_Head = true, Pipe_Metal = true, Lattice_Back = true, Awning_Tile = true, Awning_Wood = true, Chochin_Arm = true, Chochin_Paper = true, Chochin_Band = true}
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p)
			local lk = LOOK[k] or {Enum.Material.Wood, C(92, 69, 46)}
			p.Anchored = true; p.CanTouch = false; p.CastShadow = true; p.Material = lk[1]; p.Color = lk[2]
			p.CanCollide = not NOCOLLIDE[k]; p.CanQuery = p.CanCollide
		end
	end
end
local WALLSIDE = {back_door2 = true, back_window2 = true, broom = true, drainpipe = true, wood_shed = true, lattice_panel = true, awning_section = true, chochin = true}
local YMIN = {back_window2 = 5.3, chochin = 5.3, awning_section = 7.9}                    -- pieces whose geometry starts above the ground (out_shopback2/pieces.json)
local function prep(src, n)
	for _, p in ipairs(src:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	local cf, sz = src:GetBoundingBox()
	src.WorldPivot = CFrame.new(cf.X, cf.Y - sz.Y / 2 - (YMIN[n] or 0), cf.Z)             -- the pivot at the piece's GROUND line, not its lowest point
end
for _, n in ipairs(PIECES) do prep(KIT[n], n) end
-- the kit's "out" is +z; an import may face -z: detect by the door's step (on the out side) against the door's reveal (into the wall)
local flipped
do
	local step, reveal
	for _, p in ipairs(KIT.back_door2:GetDescendants()) do if p:IsA("BasePart") then if key(p) == "Door_Step" then step = p elseif key(p) == "Door_Reveal" then reveal = p end end end
	flipped = (step and reveal) and (step.Position.Z < reveal.Position.Z) or false
end
local KITR = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
-- for the wall-side pieces: how far their local z-min (the recess / the back) sits behind the piece's centre, so the WALL PLANE lands at local z = 0
local ZOFF = {}
for _, n in ipairs(PIECES) do
	local cf, sz = KIT[n]:GetBoundingBox()
	local zmin = flipped and -(cf.Z + sz.Z / 2) or (cf.Z - sz.Z / 2)                      -- in the kit's own frame (out = +z)
	local centreZ = flipped and -cf.Z or cf.Z
	local recess = (n == "back_door2" or n == "back_window2") and RECESS or ((n == "drainpipe" or n == "broom" or n == "wood_shed" or n == "lattice_panel" or n == "awning_section" or n == "chochin") and 0.08 or 0)
	ZOFF[n] = -(zmin - centreZ) - recess                                                   -- move the piece out by this so its z-min is RECESS behind the wall
end
local old = J:FindFirstChild("ShopBacks"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "ShopBacks"
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before shopbacks2") end)
local report, nplaced, flips = {}, 0, 0
local rnd = Random.new(1020)
local function place(name, n, wallX, z, outDir, off, yaw, y)
	local m = KIT[n]:Clone(); m.Name = name
	local baseYaw = (outDir > 0) and math.pi / 2 or -math.pi / 2                           -- R_y(+90) sends local +z to world +x
	local x = wallX + outDir * ((WALLSIDE[n] and ZOFF[n] or 0) + (off or 0))
	local pivot = CFrame.new(x, y or 0, z) * CFrame.Angles(0, baseYaw + (yaw or 0), 0) * KITR
	m:PivotTo(pivot)
	if WALLSIDE[n] then                                                                    -- the piece must stand on the OUT side of the wall; if it landed inside, turn it round
		local cf = m:GetBoundingBox()
		if (cf.X - wallX) * outDir < 0 then m:PivotTo(pivot * CFrame.Angles(0, math.pi, 0)); flips += 1 end
	end
	dress(m); m.Parent = F; nplaced += 1
	return m
end
for si, S in ipairs(SHOPS) do
	local shop = M:FindFirstChild(S[1])
	if not shop then table.insert(report, S[1] .. ": NOT FOUND") continue end
	local cf, sz = shop:GetBoundingBox()
	local outDir = (cf.X < 6000) and -1 or 1
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {shop}
	local h = workspace:Raycast(Vector3.new(cf.X + outDir * (sz.X / 2 + 12), 5, cf.Z), Vector3.new(-outDir * 30, 0, 0), rp)
	if not h then table.insert(report, S[1] .. ": no back wall found - skipped") continue end
	local wallX = h.Position.X
	local z0, z1 = cf.Z - sz.Z / 2 + 0.6, cf.Z + sz.Z / 2 - 0.6                                -- the usable wall, off the corner posts
	local taken = {}                                                                             -- z spans already used on the wall: {a, b}
	local function free(a, b) for _, t in ipairs(taken) do if a < t[2] and b > t[1] then return false end end return true end
	local function take(a, b) table.insert(taken, {a, b}) end
	-- the door(s)
	local doorZ = cf.Z + S.doorAt * rnd:NextNumber(4.0, 6.0)
	local doorW = (S.doors == 2) and 9.6 or 5.9
	if S.doors == 2 then
		place(S[1] .. "_doorA", "back_door2", wallX, doorZ - 2.4, outDir); place(S[1] .. "_doorB", "back_door2", wallX, doorZ + 2.4, outDir)
	else place(S[1] .. "_door", "back_door2", wallX, doorZ, outDir) end
	take(doorZ - doorW / 2, doorZ + doorW / 2)
	-- ground-floor windows: away from the door, spread over the wall
	local wins = {}
	local cands = {}                                                                             -- every 3 studs along the wall, the spots farthest from the door first
	for wz = z0 + 2.4, z1 - 2.4, 3.0 do table.insert(cands, wz) end
	table.sort(cands, function(p, q) return math.abs(p - doorZ) > math.abs(q - doorZ) end)
	for _, wz in ipairs(cands) do
		if #wins < S.gwin and free(wz - 2.4, wz + 2.4) and wz - 2.2 > z0 and wz + 2.2 < z1 then
			place(string.format("%s_window%d", S[1], #wins), "back_window2", wallX, wz, outDir); take(wz - 2.4, wz + 2.4); table.insert(wins, wz)
		end
	end
	-- lanterns beside the door
	for k = 1, S.lanterns do
		local lz = doorZ + (k == 1 and -1 or 1) * (doorW / 2 + 1.3)
		place(string.format("%s_lantern%d", S[1], k), "chochin", wallX, lz, outDir, 0, 0)
	end
	-- upper-floor windows (two-storey shops): 2 spread, 1 centred
	local nup = 0
	if sz.Y >= 22 and S.upper > 0 then
		local ups = (S.upper == 2) and {cf.Z - 5.5, cf.Z + 5.5} or {cf.Z}
		for _, uz in ipairs(ups) do
			place(string.format("%s_upper%d", S[1], nup), "back_window2", wallX, uz, outDir, 0, 0, 8.0)
			place(string.format("%s_upperhood%d", S[1], nup), "awning_section", wallX, uz, outDir, 0, 0, 8.6)
			nup += 1
		end
	end
	-- the lattice band: full / one half / none, never across the door or a window
	local nlat = 0
	if S.lattice ~= "none" then
		local la, lb = z0, z1
		if S.lattice == "left" then lb = cf.Z - 0.5 elseif S.lattice == "right" then la = cf.Z + 0.5 end
		local z = la + 2.0
		while z + 2.0 <= lb + 0.01 do
			if free(z - 2.0, z + 2.0) then place(string.format("%s_lattice%d", S[1], nlat), "lattice_panel", wallX, z, outDir); nlat += 1 end
			z += 4.0
		end
	end
	-- the awning: the whole width, or three sections over the door only
	local nawn = 0
	if S.awning == "full" then
		local z = z0 + 2.0
		while z - 2.0 < z1 - 0.5 do place(string.format("%s_awning%d", S[1], nawn), "awning_section", wallX, math.min(z, z1 - 2.0), outDir); nawn += 1; z += 4.0 end
	else
		for _, dz in ipairs({-4.0, 0, 4.0}) do place(string.format("%s_awning%d", S[1], nawn), "awning_section", wallX, doorZ + dz, outDir); nawn += 1 end
	end
	-- drainpipes at the corners
	local npipe = 0
	for _, c in ipairs({{"S", -1}, {"N", 1}}) do
		if S.pipes == "both" or S.pipes == c[1] then place(S[1] .. "_pipe" .. c[1], "drainpipe", wallX, cf.Z + c[2] * (sz.Z / 2 - 1.1), outDir); npipe += 1 end
	end
	-- the yard things: in front of the wall, out of the door's way, spread along it
	local slots = {}
	for _, z in ipairs({z0 + 2.6, z1 - 2.6, z0 + 7.0, z1 - 7.0, cf.Z}) do
		if math.abs(z - doorZ) > doorW / 2 + 2.6 then table.insert(slots, z) end
	end
	for k, pn in ipairs(S[2]) do
		local z = slots[((k - 1) % math.max(#slots, 1)) + 1] or cf.Z
		local off = (pn == "crate_stack2" or pn == "sake_barrel2" or pn == "water_tub") and rnd:NextNumber(1.6, 2.6) or 0
		local yaw = (pn == "crate_stack2" or pn == "sake_barrel2") and rnd:NextNumber(-0.4, 0.4) or 0
		place(string.format("%s_%s%d", S[1], pn, k), pn, wallX, z, outDir, off, yaw)
	end
	table.insert(report, string.format("%s: wall x %.1f, %s door at z %.0f, %d ground windows, %d upper, %d lanterns, lattice %s (%d), awning %s (%d), %d pipes, %d yard things", S[1], wallX, S.doors == 2 and "double" or "single", doorZ, #wins, nup, S.lanterns, S.lattice, nlat, S.awning, nawn, npipe, #S[2]))
end
F.Parent = J
task.wait()
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after shopbacks2") end)
for _, r in ipairs(report) do print("QQ SHOPBACKS2 " .. r) end
print(string.format("QQ SHOPBACKS2 DONE: %d pieces behind %d shops in JapanMap.ShopBacks (kit %s; %d pieces turned round by the side check)", nplaced, #SHOPS, flipped and "turned back" or "as imported", flips))

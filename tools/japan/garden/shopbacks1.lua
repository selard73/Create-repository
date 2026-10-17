-- shopbacks1.lua (runner 7, Oct 17 2026): the backs of the ten market shops finished. Shannon: "the back sides of the shops are just plain
-- walls, they need to be finished to look like the back of the shops would actually look like". Each shop's back is a flat plaster
-- "Back wall" on the lawn under a brown eave (measured: the wall plane 10.8..13.3 from the shop's centre, the eave 9.2..12.2 up).
-- Kit japan_kit19_shop_backs.fbx (gen_shop_back.py): back_door, back_window, crate_stack, sake_barrel, water_butt, firewood,
-- laundry_pole, bin. For each shop this script finds the back wall plane by a ray from behind, then places on the lawn (y 0) against it:
-- a back door (off centre, its hood under the eave), a barred window, and three or four yard things picked per shop (the sushi bar and
-- ramen kitchen get barrels and a water butt, the teahouse firewood, the kimono shops laundry, the cafe bins...), each turned to face
-- away from the wall, kept inside the shop's width and clear of its corner posts. Everything solid but the cloths. Backs of the two
-- rows face the lawns on both sides, so every piece is seen from a lawn.
-- Re-runnable (JapanMap.ShopBacks is rebuilt). Output "QQ SHOPBACKS1". Undo: delete JapanMap.ShopBacks.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local M = J and J:FindFirstChild("Outdoor market revision")
local KIT = SS:FindFirstChild("JapanGardenKit")
if not (M and KIT) then print("QQ SHOPBACKS1 ABORT: JapanMap.'Outdoor market revision' or ServerStorage.JapanGardenKit missing") return end
local PIECES = {"back_door", "back_window", "crate_stack", "sake_barrel", "water_butt", "firewood", "laundry_pole", "bin"}
for _, n in ipairs(PIECES) do if not KIT:FindFirstChild(n) then print("QQ SHOPBACKS1 ABORT: the kit has no Model '" .. n .. "' - import japan_kit19_shop_backs.fbx") return end end
local SHOPS = {
	{"Sushi bar", {"sake_barrel", "water_butt", "crate_stack", "bin"}},
	{"Rice and provisions", {"crate_stack", "sake_barrel", "bin"}},
	{"Paper umbrella craft", {"laundry_pole", "crate_stack", "bin"}},
	{"Calligraphy teahouse", {"firewood", "water_butt", "bin"}},
	{"Mikan greengrocer", {"crate_stack", "crate_stack", "bin"}},
	{"Ramen kitchen", {"sake_barrel", "water_butt", "firewood", "bin"}},
	{"Lantern workshop", {"firewood", "crate_stack", "laundry_pole"}},
	{"Kimono atelier", {"laundry_pole", "water_butt", "bin"}},
	{"Kimono shop", {"laundry_pole", "crate_stack", "bin"}},
	{"Cat cafe", {"bin", "bin", "water_butt", "crate_stack"}},
}
local C = Color3.fromRGB
local LOOK = {
	Door_Wood = {Enum.Material.Wood, C(115, 77, 46)}, Door_Frame = {Enum.Material.Wood, C(76, 54, 36)}, Door_Step = {Enum.Material.Slate, C(128, 125, 118)}, Door_Hood = {Enum.Material.Wood, C(84, 61, 41)},
	Win_Frame = {Enum.Material.Wood, C(76, 54, 36)}, Win_Bars = {Enum.Material.Wood, C(64, 46, 31)}, Win_Paper = {Enum.Material.SmoothPlastic, C(237, 227, 199)}, Win_Sill = {Enum.Material.Wood, C(92, 66, 43)},
	Crate_Wood = {Enum.Material.WoodPlanks, C(158, 120, 77)}, Crate_Band = {Enum.Material.Wood, C(102, 77, 48)},
	Barrel_Straw = {Enum.Material.Fabric, C(199, 168, 97)}, Barrel_Rope = {Enum.Material.Fabric, C(140, 115, 71)}, Barrel_Lid = {Enum.Material.Wood, C(140, 107, 66)},
	Butt_Wood = {Enum.Material.Wood, C(71, 51, 36)}, Butt_Hoop = {Enum.Material.Metal, C(56, 54, 51)},
	Wood_Log = {Enum.Material.Wood, C(102, 71, 46)}, Wood_End = {Enum.Material.Wood, C(194, 158, 107)},
	Pole_Post = {Enum.Material.Wood, C(92, 69, 46)}, Pole_Bamboo = {Enum.Material.SmoothPlastic, C(179, 168, 97)},
	Cloth_A = {Enum.Material.Fabric, C(77, 97, 158)}, Cloth_B = {Enum.Material.Fabric, C(235, 230, 214)}, Cloth_C = {Enum.Material.Fabric, C(158, 71, 66)},
	Bin_Wood = {Enum.Material.Wood, C(87, 64, 43)}, Bin_Lid = {Enum.Material.Wood, C(71, 54, 38)},
}
local NOCOLLIDE = {Cloth_A = true, Cloth_B = true, Cloth_C = true, Win_Paper = true, Win_Bars = true}
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p)
			local lk = LOOK[k] or {Enum.Material.Wood, C(92, 69, 46)}
			p.Anchored = true; p.CanTouch = false; p.CastShadow = true; p.Material = lk[1]; p.Color = lk[2]
			p.CanCollide = not NOCOLLIDE[k]; p.CanQuery = p.CanCollide
			if k == "Cloth_A" or k == "Cloth_B" or k == "Cloth_C" then pcall(function() p.DoubleSided = true end) end
		end
	end
end
-- each kit piece's pivot at its local origin: ground level, the wall side (z min) for the door and window, the centre for the rest
local function prep(src, wallSide)
	for _, p in ipairs(src:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	local cf, sz = src:GetBoundingBox()
	local z = wallSide and (cf.Z - sz.Z / 2) or cf.Z
	src.WorldPivot = CFrame.new(cf.X, cf.Y - sz.Y / 2, z)
end
for _, n in ipairs(PIECES) do prep(KIT[n], n == "back_door" or n == "back_window") end
-- the kit's "out" is +z; an imported piece may face -z: detect by the door's step (it lies on the out side)
local flipped
do
	local d = KIT.back_door
	local step
	for _, p in ipairs(d:GetDescendants()) do if p:IsA("BasePart") and key(p) == "Door_Step" then step = p end end
	local cf = d:GetBoundingBox()
	flipped = step and (step.Position.Z < cf.Position.Z) or false
end
local KITR = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
local old = J:FindFirstChild("ShopBacks"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "ShopBacks"
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before shopbacks1") end)
local report, nplaced = {}, 0
local rnd = Random.new(1019)
local function place(name, src, at, outDir, yaw)                                          -- at = (x, 0, z) where the pivot goes; outDir = +1 / -1 in x
	local m = src:Clone(); m.Name = name
	local face = (outDir > 0) and 0 or math.pi                                             -- +z of the piece along +x (out) : yaw -90; along -x: yaw +90
	local baseYaw = (outDir > 0) and -math.pi / 2 or math.pi / 2
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, baseYaw + (yaw or 0), 0) * KITR)
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
	local half = sz.Z / 2 - 3.0                                                            -- stay off the corner posts
	-- the door: off centre, toward the lane end of the row for variety; the window on the other side
	local side = (si % 2 == 0) and 1 or -1
	local doorZ = cf.Z + side * rnd:NextNumber(2.5, 5.0)
	local winZ = cf.Z - side * rnd:NextNumber(5.5, 7.5)
	place(S[1] .. "_door", KIT.back_door, Vector3.new(wallX, 0, doorZ), outDir)
	place(S[1] .. "_window", KIT.back_window, Vector3.new(wallX, 0, winZ), outDir)
	-- the yard things: along the wall, out of the door's way, each a little way off the wall
	local slots = {}
	for _, z in ipairs({cf.Z - half + 1.5, cf.Z - half + 5.5, cf.Z + half - 1.5, cf.Z + half - 5.5, winZ + (side > 0 and -3.6 or 3.6)}) do
		if math.abs(z - doorZ) > 4.2 then table.insert(slots, z) end
	end
	for k, pn in ipairs(S[2]) do
		local z = slots[((k - 1) % #slots) + 1] + rnd:NextNumber(-0.4, 0.4)
		local off = (pn == "laundry_pole") and 3.6 or ((pn == "firewood") and 1.0 or rnd:NextNumber(1.2, 2.2))
		local yaw = (pn == "laundry_pole") and 0 or rnd:NextNumber(-0.35, 0.35)
		place(string.format("%s_%s%d", S[1], pn, k), KIT[pn], Vector3.new(wallX + outDir * off, 0, z), outDir, yaw)
	end
	table.insert(report, string.format("%s: back wall x %.1f (%s), door at z %.0f, window at z %.0f, %d yard things", S[1], wallX, outDir > 0 and "east side" or "west side", doorZ, winZ, #S[2]))
end
F.Parent = J
task.wait()
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after shopbacks1") end)
for _, r in ipairs(report) do print("QQ SHOPBACKS1 " .. r) end
print(string.format("QQ SHOPBACKS1 DONE: %d pieces behind %d shops in JapanMap.ShopBacks (kit %s)", nplaced, #SHOPS, flipped and "turned back" or "as imported"))

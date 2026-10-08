"""Builds VillageBuilder.rbxmx: Folder "VillageBuilder" with a ModuleScript (BuildModule) and a runner Script (Build).
Lays out a small old-town street from the village kit next to the forest, joined by an arched bridge:
  street along X with sidewalks, townhouses on both sides facing the street, a fountain square in the middle
  with plane trees and benches, cafe tables with parasols, lamp posts, planters, bollards, signs, bicycles.
Also creates workspace.Zones (one flat part per map, MapId attribute) so the HUD knows where the player is,
records hiding spots, and moves the registry's "village" squirrels into them.
Edit mode: require(workspace.VillageBuilder.BuildModule)()   then set Enabled=false.
Attributes on the folder: CenterX/CenterZ (default 260,-120), Length (180), Seed, Palette ("color"/"gray"),
  HideSquirrels, BridgeToX (forest edge, default 110), MapId ("village").
Run: python make_village_scripts.py
"""
from pathlib import Path
import xml.dom.minidom as m
OUT = Path(__file__).parent / "VillageBuilder.rbxmx"

BUILD = r'''
-- VillageBuilder: builds the village street from the imported village kit.
return function()
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local folder = script.Parent
local function attr(name, default)
	local v = folder:GetAttribute(name)
	if v == nil then folder:SetAttribute(name, default); return default end
	return v
end
if attr("Enabled", true) == false then print("VillageBuilder: disabled") return end
local CX, CZ = attr("CenterX", 260), attr("CenterZ", -120)
local LEN = attr("Length", 180)
local SEED = attr("Seed", 3)
local PALETTE = attr("Palette", "color")
local HIDE = attr("HideSquirrels", true)
local BRIDGE_TO_X = attr("BridgeToX", 110)          -- where the forest ends
local MAP_ID = attr("MapId", "village")
local GROUND_FALLBACK = attr("GroundY", 0)
local rng = Random.new(SEED)

-- kit lookup (village_kit.obj imports as pieces named "<kit>__<piece>"; regroup into one Model per kit name)
local KIT = {"townhouse_a", "townhouse_b", "townhouse_c", "townhouse_d", "townhouse_e", "cafe_table", "parasol", "lamp_post", "planter", "fountain",
	"bollards", "shop_sign", "bench", "bicycle", "bridge", "plane_tree", "river", "pot", "crates",
	"disp_bakery", "disp_dress", "disp_shelves", "disp_flowers", "disp_cafe", "disp_hats", "disp_cheese", "disp_chocolate",
	"disp_grocery", "disp_pharmacy", "disp_post", "disp_post_b", "disp_bakery_b", "chalkboard",
	"basket_flowers", "basket_bread", "basket_mixed", "table_setting"}
do
	local groups = {}
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("MeshPart") and not p:FindFirstAncestor("Village") then
			local kit, piece = p.Name:match("^(.-)__(.+)$")
			if kit and piece and table.find(KIT, kit) then
				local g = groups[kit]
				if not g then
					g = Instance.new("Model"); g.Name = kit
					g.Parent = workspace:FindFirstChild("VillageKit") or (function()
						local f = Instance.new("Folder"); f.Name = "VillageKit"; f.Parent = workspace; return f end)()
					groups[kit] = g
				end
				p.Name = piece; p.Parent = g
			end
		end
	end
	for _, g in pairs(groups) do g.PrimaryPart = g:FindFirstChildWhichIsA("BasePart") end
	for _, mdl in ipairs(workspace:GetChildren()) do
		if mdl:IsA("Model") and mdl.Name:lower():find("village_kit") and not mdl:FindFirstChildWhichIsA("BasePart", true) then mdl:Destroy() end
	end
end
local templates = {}
local kitFolder = workspace:FindFirstChild("VillageKit")
if kitFolder then for _, k in ipairs(KIT) do templates[k] = kitFolder:FindFirstChild(k) end end
local missing = {}
for _, k in ipairs(KIT) do if not templates[k] then table.insert(missing, k) end end
if #missing > 0 then warn("VillageBuilder: kit pieces not found (import village_kit.obj, Merge Meshes OFF): " .. table.concat(missing, ", ")) end
if not templates.townhouse_a then warn("VillageBuilder: nothing to build with") return end

-- palette
local C = Color3.fromRGB
local WALLS = {C(247, 236, 205), C(242, 205, 205), C(203, 218, 238), C(246, 228, 170), C(210, 228, 200), C(226, 210, 236), C(250, 222, 198)}
local SHOPFRONTS = {C(118, 82, 58), C(132, 128, 190), C(106, 140, 108), C(112, 132, 162), C(186, 112, 122), C(76, 84, 122)}
local AWNINGS = {C(214, 88, 84), C(118, 140, 208), C(108, 168, 118), C(228, 148, 168), C(150, 130, 200), C(226, 176, 80)}
local SHUTTERS = {C(106, 140, 108), C(118, 140, 170), C(150, 130, 200)}
local CANOPIES = {C(245, 235, 215), C(200, 70, 60), C(80, 120, 90)}
local FLOWERS = {C(230, 90, 120), C(240, 200, 70), C(220, 70, 60), C(200, 120, 220)}
local GRAY = {Wall = C(215, 213, 208), Roof = C(150, 140, 135), Shutter = C(150, 155, 165), Awning = C(170, 150, 150), Door = C(120, 110, 105),
	Window = C(170, 180, 190), Trim = C(235, 233, 228), Chimney = C(170, 160, 155), Table = C(90, 88, 86), Chair = C(105, 100, 96), Pole = C(100, 96, 92),
	Canopy = C(220, 215, 205), Post = C(70, 75, 72), Lantern = C(240, 235, 210), Planter = C(170, 140, 125), Leaf = C(190, 195, 190), Flower = C(220, 200, 205),
	Stone = C(190, 188, 182), Water = C(190, 200, 210), Sign = C(120, 110, 105), Bench = C(135, 120, 108), Frame = C(100, 105, 120), Wheel = C(60, 60, 60),
	Plank = C(160, 140, 120), Rail = C(140, 120, 105), Trunk = C(120, 110, 100), Bank = C(200, 195, 185),
	Shopfront = C(150, 140, 135), DoorShop = C(130, 120, 112), AwningStripe = C(232, 230, 226), Iron = C(70, 70, 72), Bread = C(190, 180, 165),
	Glass = C(200, 210, 218), Interior = C(225, 218, 205), Brass = C(200, 190, 160), Cake = C(240, 238, 232), Icing = C(220, 200, 205),
	Dress = C(200, 190, 195), Head = C(225, 215, 205), Jar = C(190, 170, 150), Box = C(160, 140, 125), Round = C(220, 205, 170),
	Book = C(170, 150, 150), Hat = C(90, 85, 82), Brick = C(165, 140, 130), Cheese = C(225, 210, 170), Choc = C(95, 80, 72), Wrap = C(200, 185, 160),
	Fruit = C(200, 185, 170), Sack = C(190, 180, 165), Bottle = C(220, 222, 224), Pill = C(235, 235, 235), Cross = C(150, 190, 160), Band = C(210, 205, 195), Yellow = C(225, 215, 170),
	Cloth = C(232, 230, 226), Plate = C(240, 240, 238), Cup = C(240, 240, 238), Napkin = C(200, 190, 190), Rose = C(215, 200, 205), Cutlery = C(190, 190, 195)}
local COLOR = {Roof = C(200, 120, 95), Door = C(120, 85, 60), Window = C(140, 160, 190), Trim = C(250, 247, 238), Chimney = C(170, 150, 140),
	Table = C(70, 60, 55), Chair = C(150, 115, 80), Pole = C(70, 60, 55), Post = C(45, 70, 60), Lantern = C(255, 240, 190), Planter = C(180, 110, 85),
	Leaf = C(100, 160, 90), Stone = C(190, 185, 175), Water = C(120, 190, 220), Sign = C(58, 46, 40), Bench = C(140, 110, 85), Frame = C(70, 90, 140),
	Wheel = C(50, 50, 50), Plank = C(160, 120, 85), Rail = C(130, 100, 75), Trunk = C(110, 85, 60), Bank = C(196, 176, 136),
	AwningStripe = C(250, 247, 240), Iron = C(45, 45, 50), Bread = C(226, 172, 92),
	Glass = C(205, 228, 240), Interior = C(238, 206, 160), Brass = C(218, 178, 88), Cake = C(250, 246, 236), Icing = C(240, 170, 190),
	Dress = C(230, 120, 140), Head = C(236, 216, 200), Jar = C(200, 140, 90), Box = C(154, 108, 78), Round = C(240, 208, 120),
	Book = C(200, 70, 70), Hat = C(60, 50, 45), Brick = C(152, 94, 78), Cheese = C(240, 204, 100), Choc = C(64, 38, 26), Wrap = C(218, 178, 88),
	Fruit = C(240, 140, 40), Sack = C(196, 168, 120), Bottle = C(240, 244, 246), Pill = C(248, 248, 246), Cross = C(40, 205, 95), Band = C(245, 235, 210), Yellow = C(245, 200, 40),
	Cloth = C(250, 248, 244), Plate = C(252, 252, 250), Cup = C(252, 252, 250), Napkin = C(196, 58, 58), Rose = C(228, 88, 118), Cutlery = C(182, 184, 192)}
local BANDS = {C(245, 235, 210), C(190, 50, 60), C(40, 40, 45), C(218, 178, 88), C(70, 90, 150)}
local FRUITS = {C(240, 140, 40), C(210, 50, 50), C(120, 180, 70), C(240, 210, 70), C(140, 80, 160), C(180, 210, 120), C(230, 90, 60)}
local PILLS = {C(248, 248, 246), C(248, 248, 246), C(80, 170, 110), C(120, 170, 230), C(240, 180, 200), C(250, 240, 200)}
local BOTTLES = {C(240, 244, 246), C(200, 140, 60), C(160, 200, 230), C(240, 244, 246)}
local CHEESES = {C(240, 204, 100), C(250, 236, 190), C(232, 152, 62), C(246, 240, 214), C(222, 190, 80), C(200, 200, 150)}
local CHOCS = {C(64, 38, 26), C(122, 74, 46), C(236, 220, 190), C(78, 48, 34)}
local WRAPS = {C(218, 178, 88), C(190, 50, 60), C(70, 90, 150), C(120, 70, 140), C(60, 130, 100), C(230, 230, 225)}
local DRESSES = {C(230, 120, 140), C(120, 150, 210), C(240, 210, 120), C(150, 200, 150), C(200, 150, 220), C(245, 240, 232), C(90, 100, 140)}
local HATS = {C(60, 50, 45), C(200, 60, 70), C(230, 220, 200), C(70, 90, 140), C(120, 160, 120), C(170, 120, 80)}
local BOOKS = {C(200, 70, 70), C(70, 110, 180), C(90, 150, 100), C(230, 190, 80), C(120, 90, 160), C(240, 235, 220), C(60, 60, 70)}
local ICINGS = {C(240, 170, 190), C(250, 240, 225), C(200, 150, 110), C(170, 220, 190), C(240, 220, 140)}
local JARS = {
	FROMAGERIE = {C(240, 210, 120), C(250, 240, 210), C(230, 180, 90), C(200, 200, 150)},
	CHOCOLATIER = {C(90, 60, 45), C(140, 90, 60), C(200, 170, 140), C(220, 60, 80)},
	["GRAND MARCHÉ"] = {C(200, 90, 80), C(230, 190, 90), C(120, 160, 120), C(150, 180, 220), C(240, 235, 220), C(120, 90, 160)},
	["LA POSTE"] = {C(196, 152, 100), C(168, 124, 82), C(228, 190, 50), C(70, 88, 150), C(214, 178, 128)},
	PHARMACIE = {C(245, 245, 242), C(60, 170, 100), C(200, 230, 210), C(120, 180, 230), C(240, 240, 235)},
	PARFUMERIE = {C(230, 190, 220), C(170, 200, 240), C(250, 240, 200), C(220, 150, 160)},
	default = {C(200, 90, 80), C(230, 190, 90), C(120, 160, 120), C(150, 180, 220), C(240, 230, 210)},
}
local function pick(t) return t[rng:NextInteger(1, #t)] end
local function tintModel(model, kitName, idx, shop)
	-- buildings get their colours from their position in the row so neighbours never match
	local function at(t, i) return idx and t[(i - 1) % #t + 1] or pick(t) end
	local wall, shop, awning = at(WALLS, idx or 1), at(SHOPFRONTS, (idx or 1) * 2 + 1), at(AWNINGS, (idx or 1) + 2)
	local shutter, canopy = pick(SHUTTERS), pick(CANOPIES)
	local jars = (shop and JARS[shop]) or JARS.default
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true; p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			local key
			for k in pairs(GRAY) do if p.Name:sub(1, #k) == k and (not key or #k > #key) then key = k end end
			if PALETTE == "color" then
				if key == "Wall" then p.Color = wall elseif key == "Shutter" then p.Color = shutter elseif key == "Awning" then p.Color = awning
				elseif key == "Shopfront" then p.Color = shop
				elseif key == "DoorShop" then p.Color = C(112, 74, 46)
				elseif key == "Canopy" then p.Color = (kitName == "plane_tree") and C(110, 165, 95) or canopy
				elseif key == "Flower" then p.Color = pick(FLOWERS)
				elseif key == "Dress" then p.Color = pick(DRESSES)
				elseif key == "Hat" then p.Color = pick(HATS)
				elseif key == "Band" then p.Color = pick(BANDS)
				elseif key == "Book" then p.Color = pick(BOOKS)
				elseif key == "Icing" then p.Color = pick(ICINGS)
				elseif key == "Cheese" then p.Color = pick(CHEESES)
				elseif key == "Fruit" then p.Color = pick(FRUITS)
				elseif key == "Pill" then p.Color = pick(PILLS)
				elseif key == "Bottle" then p.Color = pick(BOTTLES)
				elseif key == "Choc" then p.Color = pick(CHOCS)
				elseif key == "Wrap" then p.Color = pick(WRAPS)
				elseif key == "Jar" or key == "Round" or key == "Box" then p.Color = pick(jars)
				elseif key and COLOR[key] then p.Color = COLOR[key] end
				if key == "Glass" then p.Transparency = 0.62; p.Color = C(232, 240, 244); p.Reflectance = 0.04; p.CanQuery = false; p.CastShadow = false end
				if key == "Brass" then p.Reflectance = 0.2 end
				if key == "Water" then p.Material = Enum.Material.SmoothPlastic; p.Color = (kitName == "river") and C(74, 146, 178) or p.Color; p.Transparency = (kitName == "river") and 0.05 or 0.25; p.Reflectance = 0.12 end
				if key == "Bank" then p.Material = Enum.Material.Sand end
				if key == "Lantern" then p.Material = Enum.Material.Neon; p.Color = C(255, 236, 170) end
				if key == "Cross" then p.Material = Enum.Material.Neon end
				if key == "Window" then p.Reflectance = 0.08 end
			elseif key then p.Color = GRAY[key] end
		end
	end
end
for _, t in pairs(templates) do
	for _, p in ipairs(t:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.Transparency = 1; p.CanCollide = false; p.CanQuery = false end end
end

-- output folders
local old = workspace:FindFirstChild("Village"); if old then old:Destroy() end
local village = Instance.new("Folder"); village.Name = "Village"; village.Parent = workspace
local ground = Instance.new("Folder"); ground.Name = "Ground"; ground.Parent = village     -- street, sidewalks, square
local props = Instance.new("Folder"); props.Name = "Props"; props.Parent = village         -- everything that stands on them
local spots = Instance.new("Folder"); spots.Name = "HidingSpots"; spots.Parent = village
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local ignore = {props, spots}          -- the ground slabs stay raycastable so props rest on the pavement, not under it
for _, t in pairs(templates) do table.insert(ignore, t) end
if kitFolder then table.insert(ignore, kitFolder) end
for _, mdl in ipairs(CollectionService:GetTagged("Squirrel")) do table.insert(ignore, mdl) end
rp.FilterDescendantsInstances = ignore
local function groundAt(x, z)
	local r = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), rp)
	return r and r.Position.Y or GROUND_FALLBACK
end
local GY = groundAt(CX, CZ)

-- ground: street, sidewalks, square, path to the bridge, river
local function slab(name, cx, cz, sx, sz, y, h, color, material)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.Size = Vector3.new(sx, h, sz)
	p.Position = Vector3.new(cx, y + h / 2, cz); p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Locked = true; p.Parent = ground
	return p
end
local STREET_W, WALK_W = 22, 9
local QUAY = 5                     -- the pavement runs this far past the row toward the river and meets the east bank
local HOUSE_D = 26                 -- shop-house depth (gen_village.py DEPTH)
slab("Street", CX - QUAY / 2, CZ, LEN + QUAY, STREET_W, GY, 0.3, PALETTE == "color" and C(150, 148, 142) or C(168, 167, 163), Enum.Material.Cobblestone)
slab("SidewalkN", CX - QUAY / 2, CZ + STREET_W / 2 + WALK_W / 2, LEN + QUAY, WALK_W, GY, 0.55, PALETTE == "color" and C(205, 200, 190) or C(205, 204, 200), Enum.Material.Concrete)
slab("SidewalkS", CX - QUAY / 2, CZ - STREET_W / 2 - WALK_W / 2, LEN + QUAY, WALK_W, GY, 0.55, PALETTE == "color" and C(205, 200, 190) or C(205, 204, 200), Enum.Material.Concrete)
-- plots the buildings stand on, level with the sidewalk, so every door sits at pavement height
slab("PlotN", CX - QUAY / 2, CZ + STREET_W / 2 + WALK_W + HOUSE_D / 2 + 2, LEN + QUAY, HOUSE_D + 4, GY, 0.5, PALETTE == "color" and C(205, 200, 190) or C(205, 204, 200), Enum.Material.Concrete)
slab("PlotS", CX - QUAY / 2, CZ - STREET_W / 2 - WALK_W - HOUSE_D / 2 - 2, LEN + QUAY, HOUSE_D + 4, GY, 0.5, PALETTE == "color" and C(205, 200, 190) or C(205, 204, 200), Enum.Material.Concrete)
local SQ = 46      -- square width, cut into the north row
slab("Square", CX, CZ + STREET_W / 2 + WALK_W + 14, SQ, 28, GY, 0.55, PALETTE == "color" and C(205, 200, 190) or C(205, 204, 200), Enum.Material.Concrete)
-- the crossing: cobbled walkway from the forest edge to the river bank, a river (a blue plane just above the
-- grass, since the ground is a solid baseplate) with sand banks, and the bridge spanning bank to bank
local westEnd = CX - LEN / 2
local bridgeLen = 30
local bridgeCX = westEnd - bridgeLen / 2 + 1            -- east end of the bridge meets the street
local RIVER_W = 18
local bankW = 3
local riverX0, riverX1 = bridgeCX - RIVER_W / 2, bridgeCX + RIVER_W / 2
local walkColor = PALETTE == "color" and C(150, 148, 142) or C(168, 167, 163)
slab("Walkway", (BRIDGE_TO_X + riverX0 - bankW) / 2, CZ, (riverX0 - bankW) - BRIDGE_TO_X, 9, GY, 0.3, walkColor, Enum.Material.Cobblestone)
-- the river: a meandering mesh (village kit "river"), straight only under the bridge. riverAt() mirrors the
-- shape baked into the mesh so rocks and shrubs can sit on its banks.
local RIVER_K = 2 * math.pi / 260
local function riverEnv(d) local t = math.clamp((math.abs(d) - 50) / 120, 0, 1) return t * t * (3 - 2 * t) end
local function riverAt(dz)      -- returns centre x offset, half width
	return 45 * riverEnv(dz) * math.cos(RIVER_K * math.abs(dz)), 9 + 3.5 * riverEnv(dz) * math.cos(RIVER_K * math.abs(dz) + 1.7) + 1.5 * riverEnv(dz)
end
local riverModel
if templates.river then
	riverModel = templates.river:Clone(); riverModel.Name = "river"
	for _, pp in ipairs(riverModel:GetDescendants()) do
		if pp:IsA("BasePart") then
			pp.Transparency = 0; pp.CanCollide = true; pp.CanQuery = true
			-- a 1600-stud mesh gets thinned by automatic LOD at a distance (grass shows through): keep it full detail.
			-- Only settable in edit mode (command bar), which is where the builder is meant to run.
			pcall(function() pp.RenderFidelity = Enum.RenderFidelity.Precise end)
		end
	end
	riverModel.Parent = props
	tintModel(riverModel, "river")
	riverModel:PivotTo(CFrame.new(bridgeCX, GY, CZ))
	local bb, size = riverModel:GetBoundingBox()
	riverModel:PivotTo(riverModel:GetPivot() + Vector3.new(bridgeCX - bb.Position.X, GY - 0.45 - (bb.Position.Y - size.Y / 2), CZ - bb.Position.Z))
else
	warn("VillageBuilder: river mesh not found (import river.obj); using a plain strip")
	slab("River", bridgeCX, CZ, RIVER_W, 1600, GY, 0.2, C(74, 146, 178), Enum.Material.SmoothPlastic)
end
-- gentle distance fog so the river (and everything else) fades out instead of stopping at a hard edge
if attr("DistanceFog", true) then
	local L = game:GetService("Lighting")
	L.FogColor = C(205, 218, 232); L.FogStart = 350; L.FogEnd = 1100
end
local placed = {}
local function place(kitName, x, z, yaw, scale, spotKinds, tint, idx, shop, fixedY)
	local t = templates[kitName]
	if not t then return end
	local model = t:Clone(); model.Name = kitName
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 0; p.CanCollide = true; p.CanQuery = true; p.Locked = true end end
	model.Parent = props
	if tint ~= false then tintModel(model, kitName, idx, shop) end
	if scale and scale ~= 1 then model:ScaleTo(scale) end
	local gy = fixedY or groundAt(x, z)
	if kitName == "bridge" then gy = GY end
	-- Import 3D mirrors the kit's front: the townhouses' doors end up on +Z, so turn them around
	local modelYaw = yaw + ((kitName:find("townhouse") or kitName == "bench" or kitName:sub(1, 5) == "disp_") and math.pi or 0)
	model:PivotTo(CFrame.new(x, gy, z) * CFrame.Angles(0, modelYaw, 0))
	local bb, size = model:GetBoundingBox()
	-- centre the footprint on (x, z) and rest the bottom on the ground (the kit's own bottom is its y = 0)
	model:PivotTo(model:GetPivot() + Vector3.new(x - bb.Position.X, gy - (bb.Position.Y - size.Y / 2), z - bb.Position.Z))
	if kitName == "bridge" then model:PivotTo(model:GetPivot() + Vector3.new(0, -0.20, 0)) end   -- deck-end tops meet the cobbles
	table.insert(placed, model)
	for _, kind in ipairs(spotKinds or {}) do
		local a = Instance.new("Attachment"); a.Name = kind; a.Parent = spots
		local base = CFrame.new(x, gy, z) * CFrame.Angles(0, yaw, 0)
		if kind == "UnderTable" then a.WorldCFrame = base * CFrame.new(0, 0, 0)
		elseif kind == "OnBench" then a.WorldCFrame = CFrame.new(x, gy + 1.6, z) * CFrame.Angles(0, yaw, 0)
		elseif kind == "BehindPlanter" then a.WorldCFrame = base * CFrame.new(0, 0, 1.6)
		elseif kind == "InFountain" then a.WorldCFrame = CFrame.new(x, gy + 1.15, z) * CFrame.Angles(0, yaw, 0)
		elseif kind == "ByLamp" then a.WorldCFrame = base * CFrame.new(1.2, 0, 0.6)
		elseif kind == "OnAwning" then a.WorldCFrame = base * CFrame.new(rng:NextNumber(-3, 3), size.Y * 0.28, -7.2)
		elseif kind == "InDoorway" then a.WorldCFrame = base * CFrame.new(0, 0, -6.6)
		elseif kind == "BesideBike" then a.WorldCFrame = base * CFrame.new(0, 0, 1.4)
		elseif kind == "UnderBridge" then a.WorldCFrame = CFrame.new(x + 8, GY - 2.4, z + 3) * CFrame.Angles(0, yaw, 0)
		elseif kind == "InTree" then a.WorldCFrame = CFrame.new(x + rng:NextNumber(-2, 2), gy + size.Y * 0.62, z + rng:NextNumber(-2, 2)) * CFrame.Angles(0, yaw, 0)
		end
	end
	return model
end

-- bike basket fillers (gen_baskets.py): cycle bread / mixed / flowers; fixed colours so the shared rng is not consumed
-- (the approved building colours depend on the rng order). Kit offsets are the fillers' bounds centres relative to
-- the basket floor-top centre; Import 3D turns kits 180 degrees, hence the (-x, y, -z).
local BASKET_FILLS = {"basket_bread", "basket_mixed", "basket_flowers"}
local BASKET_C = {basket_flowers = Vector3.new(0.005, 0.85, -0.015), basket_bread = Vector3.new(-0.235, 0.80, 0.03), basket_mixed = Vector3.new(-0.025, 0.86, 0.07)}
local BASKET_COL = {Lavender = C(160, 120, 210), Leaf = C(100, 160, 90), Bread = C(226, 172, 92), Trim = C(250, 247, 238)}
local nBasket = 0
function addBasket(bike)
	local B = bike:FindFirstChild("Bench", true)
	if not B then return end
	nBasket += 1
	local fill = BASKET_FILLS[(nBasket - 1) % #BASKET_FILLS + 1]
	local t = templates[fill]
	if not t then return end
	local s = bike:GetScale()
	local cl = t:Clone(); cl.Name = "BasketFill"
	for _, p in ipairs(cl:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Transparency = 0; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Locked = true; p.Anchored = true
			p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			local d = tonumber(p.Name:match("^Flower(%d+)$"))
			if d then p.Color = FLOWERS[(d - 1) % #FLOWERS + 1] else
				for key, col in pairs(BASKET_COL) do if p.Name:sub(1, #key) == key then p.Color = col end end
			end
		end
	end
	cl.Parent = bike
	cl:ScaleTo(s)
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(cl:GetDescendants()) do if p:IsA("BasePart") then mn = mn:Min(p.Position - p.Size / 2); mx = mx:Max(p.Position + p.Size / 2) end end
	local c0 = (mn + mx) / 2
	cl:PivotTo(CFrame.new(c0) * B.CFrame.Rotation * CFrame.new(-c0) * cl:GetPivot())
	local k = BASKET_C[fill]
	local target = (B.CFrame * CFrame.new(0, -0.25 * s, 0) * CFrame.new(-k.X * s, k.Y * s, -k.Z * s)).Position
	cl:PivotTo(CFrame.new(target - c0) * cl:GetPivot())
end

-- a parked bike leans 9 degrees toward the shop side on a kickstand (the whole model tilts about the wheels' contact line)
local function parkBike(bike, dz)
	local bb, size = bike:GetBoundingBox()
	local s = bike:GetScale()
	local P0 = Vector3.new(bb.Position.X, bb.Position.Y - size.Y / 2, bb.Position.Z)
	local top = P0 + Vector3.new(0, 0.78 * s, 0)
	local foot = P0 + Vector3.new(0.1 * s, 0.1 * s, dz * 0.55 * s)
	local ks = Instance.new("Part"); ks.Name = "Kickstand"; ks.Anchored = true; ks.CanCollide = false; ks.CanQuery = false; ks.Locked = true
	ks.Material = Enum.Material.SmoothPlastic; ks.Color = PALETTE == "color" and C(50, 50, 50) or C(60, 60, 60)
	ks.Size = Vector3.new(0.1 * s, 0.1 * s, (foot - top).Magnitude)
	ks.CFrame = CFrame.lookAt((top + foot) / 2, foot)
	ks.Parent = bike
	local R = CFrame.new(P0) * CFrame.fromAxisAngle(Vector3.xAxis, math.rad(9) * dz) * CFrame.new(-P0)
	bike:PivotTo(R * bike:GetPivot())
end

-- chalkboard: the placeholder chalk squiggles become a written menu on each outer face
local MENUS = {
	"MENU DU JOUR\n\nSoupe à l'oignon ........ 5€\nCroque-monsieur ....... 6€\nQuiche lorraine ......... 5€\nSalade niçoise ........... 7€\nTarte aux noisettes ... 4€",
	"BOISSONS\n\nCafé crème ................ 2€\nChocolat chaud .......... 3€\nCitron pressé ............. 3€\nJus de pomme ........ 2€50\nCroissant .................. 1€50",
}
local function menuBoard(cb)
	local post = cb:FindFirstChild("Post", true)
	if not post then return end
	for _, p in ipairs(cb:GetDescendants()) do if p:IsA("BasePart") and p.Name == "Trim" then p:Destroy() end end
	local s = cb:GetScale()
	for i, sgn in ipairs({-1, 1}) do
		local out = post.CFrame.LookVector * sgn
		local n = (out * 0.978 + Vector3.yAxis * 0.204).Unit               -- the boards lean 12 degrees, so the faces tilt up
		local c = post.Position + Vector3.new(0, -1.795 * s, 0) + out * (0.453 * s) + n * 0.03
		local part = Instance.new("Part"); part.Name = "MenuText"; part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.Locked = true
		part.Transparency = 1; part.Size = Vector3.new(1.9 * s, 2.6 * s, 0.04)
		part.CFrame = CFrame.lookAt(c, c + n)
		part.Parent = cb
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.LightInfluence = 0; gui.Brightness = 1.2
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 60; gui.Parent = part
		local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.fromScale(0.92, 0.92); lbl.Position = UDim2.fromScale(0.04, 0.04); lbl.BackgroundTransparency = 1
		lbl.FontFace = Font.new("rbxasset://fonts/families/PatrickHand.json"); lbl.TextColor3 = C(246, 240, 226)
		lbl.TextScaled = true; lbl.TextWrapped = true; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.Text = MENUS[i]; lbl.Parent = gui
	end
end

-- a cafe table with its setting (cloth, vase, plates; the kit's y = 0 is 0.6 below the table top) and two invisible
-- Seats over the chairs, facing the table, so players can sit (touch) and stand up (jump)
local function cafeTable(x, z, yaw)
	local tbl = place("cafe_table", x, z, yaw, 1, {"UnderTable"})
	local gy = groundAt(x, z)
	local st = place("table_setting", x, z, yaw, 1, {}, true, nil, nil, gy + 2.3 - 0.6)
	if st then for _, p in ipairs(st:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
	if tbl then
		for _, sgn in ipairs({-1, 1}) do
			local off = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(Vector3.new(0, 0, sgn * 2.1))
			local pos = Vector3.new(x, gy + 1.375, z) + off
			local seat = Instance.new("Seat"); seat.Name = "ChairSeat"; seat.Anchored = true; seat.CanCollide = true; seat.CanQuery = false
			seat.Transparency = 1; seat.Locked = true; seat.Size = Vector3.new(1.3, 0.2, 1.3)
			seat.CFrame = CFrame.lookAt(pos, Vector3.new(x, pos.Y, z))
			seat.Parent = tbl
		end
	end
end

-- fountain: a water jet from the top of the column that arcs back down into the bowls
local function fountainSpray(model)
	if not model then return model end
	local base = model:FindFirstChildWhichIsA("BasePart", true)
	local bb, size = model:GetBoundingBox()
	if not base then return model end
	local a = Instance.new("Attachment"); a.Name = "Spout"
	a.Parent = base
	a.WorldCFrame = CFrame.new(bb.Position.X, bb.Position.Y + size.Y / 2 - 0.15, bb.Position.Z)
	local pe = Instance.new("ParticleEmitter"); pe.Name = "Jet"
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(C(205, 236, 255), C(240, 250, 255))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 1.3)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.6, 0.45), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(1.0, 1.3); pe.Rate = 45; pe.Speed = NumberRange.new(15, 18)
	pe.SpreadAngle = Vector2.new(9, 9); pe.Acceleration = Vector3.new(0, -38, 0)
	pe.EmissionDirection = Enum.NormalId.Top; pe.LightEmission = 0.25; pe.LightInfluence = 0.6
	pe.Parent = a
	return model
end

-- 1. shop-houses along both sides (north row faces -Z toward the street; south row is turned around)
local kinds = {"townhouse_a", "townhouse_b", "townhouse_c", "townhouse_d", "townhouse_e"}
local widths = {townhouse_a = 28, townhouse_b = 22, townhouse_c = 34, townhouse_d = 18, townhouse_e = 26}
local lastKind, lastKind2
local SHOPS = {"BOULANGERIE", "CAFÉ DE L'ÉCUREUIL", "MODE ET STYLE", "FLEURISTE", "LA POSTE", "FROMAGERIE", "GRAND MARCHÉ",
	"PHARMACIE", "CHOCOLATIER", "CHAPELIER", "LIBRAIRIE", "PARFUMERIE", "GLACES", "MODE ET ROBES", "PÂTISSERIE", "CAFÉ LUNA"}
local frontN = CZ + STREET_W / 2 + WALK_W           -- building fronts sit at the back of the sidewalk
local frontS = CZ - STREET_W / 2 - WALK_W
local cafes = {}
local ends = {}          -- exposed side walls: {x = wall x, cz = building centre z, out = -1 or 1}
local nHouse = 0
local nWindow = 0
local DISPLAY = {BOULANGERIE = "disp_bakery", ["PÂTISSERIE"] = "disp_bakery", FLEURISTE = "disp_flowers", CHAPELIER = "disp_hats",
	FROMAGERIE = "disp_cheese", CHOCOLATIER = "disp_chocolate", ["GRAND MARCHÉ"] = "disp_grocery", ["ÉPICERIE"] = "disp_grocery",
	PHARMACIE = "disp_pharmacy", ["LA POSTE"] = "disp_post"}
local function displayFor(shop)
	if DISPLAY[shop] then return DISPLAY[shop] end
	if shop:find("CAF") or shop == "GLACES" then return "disp_cafe" end
	if shop:find("MODE") then return "disp_dress" end
	return "disp_shelves"
end
-- Shannon's request: the red hat gets a green ribbon, the blue hats get white or yellow ribbons of varying
-- thickness; every other hat keeps whatever it had
local blueTurn = 0
local function ribbonFix(dm)
	local hats, bands = {}, {}
	for _, p in ipairs(dm:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = p.Name:match("^Hat(%d+)$"); if k then hats[k] = p end
			k = p.Name:match("^Band(%d+)$"); if k then bands[k] = p end
		end
	end
	for k, hat in pairs(hats) do
		local band = bands[k]
		if band then
			if hat.Color == HATS[2] then
				band.Color = C(60, 150, 90)
			elseif hat.Color == HATS[4] then
				blueTurn += 1
				band.Color = (blueTurn % 2 == 1) and C(245, 240, 230) or C(240, 200, 70)
				local f = ({0.7, 1.15, 1.5})[(blueTurn % 3) + 1]
				band.Size = Vector3.new(band.Size.X, band.Size.Y * f, band.Size.Z)
			end
		end
	end
end
local function firstPart(model, prefix)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Name:sub(1, #prefix) == prefix then return p end
	end
end
local function signText(model, text, dz)
	local sp = firstPart(model, "Sign")
	if not sp then return end
	local part = Instance.new("Part"); part.Name = "SignText"; part.Anchored = true; part.CanCollide = false; part.CanQuery = false
	part.Transparency = 1; part.Size = Vector3.new(sp.Size.X * 0.94, sp.Size.Y * 0.78, 0.1)
	part.CFrame = CFrame.new(sp.Position + Vector3.new(0, 0, dz * (sp.Size.Z / 2 + 0.06))) * CFrame.Angles(0, dz < 0 and 0 or math.pi, 0)
	part.Parent = model
	local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.LightInfluence = 0; gui.Brightness = 1.3
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 40; gui.Parent = part
	local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 1
	lbl.Text = text; lbl.TextScaled = true; lbl.Font = Enum.Font.Antique; lbl.TextColor3 = C(238, 208, 130)
	lbl.TextStrokeTransparency = 0.75; lbl.TextStrokeColor3 = C(40, 30, 25); lbl.Parent = gui
end
local function row(front, yaw, skipSquare)
	local x = CX - LEN / 2 + 1
	local dz = (yaw == 0) and -1 or 1          -- toward the street
	local first, last
	while x < CX + LEN / 2 - 12 do
		local k
		repeat k = pick(kinds) until k ~= lastKind and k ~= lastKind2
		local w = widths[k]
		if x + w > CX + LEN / 2 - 1 then break end
		lastKind2 = lastKind; lastKind = k
		local cx = x + w / 2
		local inSquare = skipSquare and (cx + w / 2 > CX - SQ / 2 - 1) and (cx - w / 2 < CX + SQ / 2 + 1)
		if inSquare then
			x = CX + SQ / 2 + 1
		else
			nHouse += 1
			local cz = front - dz * HOUSE_D / 2
			local shop = SHOPS[(nHouse - 1) % #SHOPS + 1]
			local mdl = place(k, cx, cz, yaw, 1, {}, nil, nHouse, shop)
			-- the footprint was centred by bounding box (awning included); slide it so the wall meets the sidewalk
			local doorP = firstPart(mdl, "DoorShop")
			if doorP then
				local face = doorP.Position.Z + dz * doorP.Size.Z / 2
				mdl:PivotTo(mdl:GetPivot() + Vector3.new(0, 0, (front + dz * 0.45) - face))
			end
			if not first then first = {x = cx - w / 2, cz = cz, out = -1} end
			last = {x = cx + w / 2, cz = cz, out = 1}
			signText(mdl, shop, dz)
			if shop == "PHARMACIE" then
				-- the green cross every French pharmacy hangs out over the pavement
				local side = ((doorP and doorP.Position.X or cx) < cx) and 1 or -1
				local cxr, cy, czr = cx + side * (w / 2 - 1.2), 13.6, front + dz * 1.6
				for _, sz in ipairs({Vector3.new(0.3, 2.6, 0.8), Vector3.new(0.3, 0.8, 2.6)}) do
					local part = Instance.new("Part"); part.Name = "PharmacyCross"; part.Anchored = true; part.CanCollide = false
					part.Size = sz; part.Position = Vector3.new(cxr, cy, czr); part.Material = Enum.Material.Neon; part.Color = C(40, 205, 95)
					part.Parent = mdl
				end
				local arm = Instance.new("Part"); arm.Name = "PharmacyCrossArm"; arm.Anchored = true; arm.CanCollide = false
				arm.Size = Vector3.new(0.12, 0.12, 1.8); arm.Position = Vector3.new(cxr, cy + 1.2, front + dz * 0.9)
				arm.Material = Enum.Material.SmoothPlastic; arm.Color = C(45, 45, 50); arm.Parent = mdl
			end
			-- window displays behind every Glass<n> pane, lit, with a hiding spot in every other one
			local kit = displayFor(shop)
			local nBay = 0
			if not templates[kit] then warn("VillageBuilder: no display kit " .. kit .. " for " .. shop .. ", using shelves"); kit = templates.disp_shelves and "disp_shelves" or nil end
			for _, g in ipairs(mdl:GetDescendants()) do
				if kit and g:IsA("BasePart") and g.Name:sub(1, 5) == "Glass" and g.Name:sub(1, 9) ~= "GlassDoor" and g.Size.X > 4 then
					local n = math.max(1, math.floor(g.Size.X / 6.2 + 0.3))
					do local _, tsz = templates[kit]:GetBoundingBox(); if tsz.X > 8 then n = 1 end end   -- wide kits: one continuous interior
					local x0 = g.Position.X - g.Size.X / 2
					local floorY = g.Position.Y - g.Size.Y / 2 + 0.14
					local _, ksz = templates[kit]:GetBoundingBox()
					local gz = g.Position.Z - dz * (ksz.Z / 2 + 0.35)
					for i = 1, n do
						-- a shop with two windows gets two different interiors, never the same one mirrored
						nBay = (nBay or 0) + 1
						local kitHere = kit
						if kit == "disp_post" and nBay % 2 == 0 and templates.disp_post_b then kitHere = "disp_post_b" end
						if kit == "disp_bakery" and nBay % 2 == 0 and templates.disp_bakery_b then kitHere = "disp_bakery_b" end
						local dm = place(kitHere, x0 + g.Size.X * (i - 0.5) / n, gz, yaw, 1, {}, nil, nHouse, shop, floorY)
						if dm and shop == "CHAPELIER" then ribbonFix(dm) end
					end
					local lp = Instance.new("Part"); lp.Name = "DisplayLight"; lp.Anchored = true; lp.CanCollide = false; lp.CanQuery = false
					lp.Transparency = 1; lp.Size = Vector3.new(0.4, 0.4, 0.4)
					lp.Position = Vector3.new(g.Position.X, floorY + 5.2, g.Position.Z - dz * 2.0); lp.Parent = mdl
					local L = Instance.new("PointLight"); L.Range = 12; L.Brightness = 1.3; L.Color = C(255, 224, 176); L.Shadows = false; L.Parent = lp
					nWindow = (nWindow or 0) + 1
					if nWindow % 2 == 1 then
						local a = Instance.new("Attachment"); a.Name = "InWindow"; a.Parent = spots
						a.WorldCFrame = CFrame.new(x0 + rng:NextNumber(1.5, g.Size.X - 1.5), floorY, g.Position.Z - dz * 1.3) * CFrame.Angles(0, yaw, 0)
					end
				end
			end
			local doorX = doorP and doorP.Position.X or cx
			-- hiding spots: on the awning and in the doorway
			local awn = firstPart(mdl, "Awning")
			if awn then
				local a = Instance.new("Attachment"); a.Name = "OnAwning"; a.Parent = spots
				a.WorldCFrame = CFrame.new(cx + rng:NextNumber(-w * 0.3, w * 0.3), awn.Position.Y + awn.Size.Y / 2 - 0.8, front + dz * 2.3) * CFrame.Angles(0, yaw, 0)
			end
			do
				local a = Instance.new("Attachment"); a.Name = "InDoorway"; a.Parent = spots
				a.WorldCFrame = CFrame.new(doorX, groundAt(doorX, front + dz * 1.0), front + dz * 1.0) * CFrame.Angles(0, yaw, 0)
			end
			-- what stands outside depends on the shop; beside() keeps things on this building's own frontage
			local wallZ = front + dz * 1.5
			local function beside(off)
				local lo, hi = cx - w / 2 + 1.8, cx + w / 2 - 1.8
				local px = doorX + off
				if px < lo or px > hi then px = doorX - off end
				return math.clamp(px, lo, hi)
			end
			if shop:find("CAF") then
				table.insert(cafes, {x = cx, z = front + dz * 3.8, yaw = yaw, doorX = doorX})
				-- chalk menu board on the pavement by the door (placed untinted so the colour sequence stays put)
				local cb = place("chalkboard", beside(3.6), front + dz * 6.6, yaw + 0.35, 1, {}, false)
				if cb then menuBoard(cb) end
				if cb then
					local fixed = {Plank = COLOR.Plank, Sign = COLOR.Sign, Trim = COLOR.Trim, Post = COLOR.Post}
					for _, pp in ipairs(cb:GetDescendants()) do
						if pp:IsA("BasePart") then
							pp.Anchored = true; pp.Material = Enum.Material.SmoothPlastic
							for key, col in pairs(fixed) do if pp.Name:sub(1, #key) == key then pp.Color = col end end
						end
					end
				end
			elseif shop == "BOULANGERIE" or shop == "PÂTISSERIE" then
				place("crates", beside(-3.4), wallZ, yaw, 1, {})
				place("crates", beside(3.4), wallZ, yaw, 1, {})
			elseif shop == "FLEURISTE" then
				place("planter", beside(4.6), wallZ, yaw, 1, {"BehindPlanter"})
				place("pot", beside(-3.0), wallZ, yaw, 1, {})
				place("pot", beside(-4.9), wallZ, yaw, 0.85, {})
			else
				place("pot", beside(3.0), wallZ, yaw, 1, {})
				if nHouse % 3 == 0 then
					-- bikes lean at the kerb, not against the shop window
					local bike = place("bicycle", beside(-5.8), front + dz * (WALK_W - 1.5), yaw, 0.85, {"BesideBike"})
					if bike then addBasket(bike); parkBike(bike, dz) end
				end
			end
			x += w + 0.8
		end
	end
	if first then table.insert(ends, first) end
	if last then table.insert(ends, last) end
end
row(frontN, 0, true)
row(frontS, math.pi, false)

-- hedges along the exposed side walls of the buildings at both ends of the street (bushes from the forest kit)
local forestKit = workspace:FindFirstChild("ForestKit")
local bushT = forestKit and (forestKit:FindFirstChild("bush_small") or forestKit:FindFirstChild("bush_big"))
if bushT then
	for _, e in ipairs(ends) do
		for _, dz in ipairs({-9.6, -3.2, 3.2, 9.6}) do
			local mdl = bushT:Clone(); mdl.Name = "hedge"
			for _, pp in ipairs(mdl:GetDescendants()) do
				if pp:IsA("BasePart") then
					pp.Transparency = 0; pp.CanCollide = true; pp.CanQuery = true; pp.Anchored = true
					pp.Color = PALETTE == "color" and C(95, 150, 85) or C(200, 205, 200)
				end
			end
			mdl.Parent = props
			local sc = rng:NextNumber(1.25, 1.55); mdl:ScaleTo(sc)
			local x, z = e.x + e.out * 2.1, e.cz + dz
			local gy = groundAt(x, z)
			mdl:PivotTo(CFrame.new(x, gy, z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
			local bb, size = mdl:GetBoundingBox()
			mdl:PivotTo(mdl:GetPivot() + Vector3.new(x - bb.Position.X, gy - (bb.Position.Y - size.Y / 2) - 0.2, z - bb.Position.Z))
			table.insert(placed, mdl)
		end
		local a = Instance.new("Attachment"); a.Name = "UnderHedge"; a.Parent = spots
		a.WorldCFrame = CFrame.new(e.x + e.out * 2.1, groundAt(e.x, e.cz), e.cz)
	end
else
	warn("VillageBuilder: forest kit bushes not found, no hedges")
end
-- along the river: rocks, shrubs and a few trees on the banks (never near the bridge or the street)
do
	local rockT = forestKit and forestKit:FindFirstChild("rock_cluster")
	local shrubT = forestKit and (forestKit:FindFirstChild("bush_small") or forestKit:FindFirstChild("bush_big"))
	local function drop(t, x, z, scale, tintFn)
		local mdl = t:Clone(); mdl.Name = "riverside"
		for _, pp in ipairs(mdl:GetDescendants()) do
			if pp:IsA("BasePart") then pp.Transparency = 0; pp.CanCollide = true; pp.CanQuery = true; pp.Anchored = true; if tintFn then tintFn(pp) end end
		end
		mdl.Parent = props
		if scale ~= 1 then mdl:ScaleTo(scale) end
		local gy = groundAt(x, z)
		mdl:PivotTo(CFrame.new(x, gy, z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
		local bb, size = mdl:GetBoundingBox()
		mdl:PivotTo(mdl:GetPivot() + Vector3.new(x - bb.Position.X, gy - (bb.Position.Y - size.Y / 2) - 0.15, z - bb.Position.Z))
		table.insert(placed, mdl)
	end
	local rockTint = function(pp) if pp.Name:sub(1, 4) == "Rock" then pp.Color = PALETTE == "color" and C(150, 152, 160) or C(170, 172, 178) end end
	local leafTint = function(pp) pp.Color = PALETTE == "color" and C(95, 150, 85) or C(200, 205, 200) end
	for dz = -720, 720, 26 do
		if math.abs(dz) > 34 then
			local off, half = riverAt(dz)
			for _, side in ipairs({-1, 1}) do
				local r = rng:NextNumber()
				local x = bridgeCX + off + side * (half + 4 + rng:NextNumber(0, 5))
				local z = CZ + dz + rng:NextNumber(-8, 8)
				-- keep the street side clear next to the village
				local nearVillage = math.abs(dz) < 60 and side == 1
				if not nearVillage then
					if r < 0.28 and rockT then drop(rockT, x, z, rng:NextNumber(0.7, 1.3), rockTint)
					elseif r < 0.6 and shrubT then drop(shrubT, x, z, rng:NextNumber(0.8, 1.3), leafTint)
					elseif r < 0.7 and templates.plane_tree then
						local mdl = place("plane_tree", x + side * 4, z, rng:NextNumber(0, 6.28), rng:NextNumber(1.5, 1.9), {"InTree"})
					end
				end
			end
		end
	end
end

-- 2. the square: fountain, plane trees, benches
local sqZ = CZ + STREET_W / 2 + WALK_W + 14
fountainSpray(place("fountain", CX, sqZ, 0, 1.4, {"InFountain"}))
for _, dx in ipairs({-17, 17}) do
	place("plane_tree", CX + dx, sqZ + 6, rng:NextNumber(0, 6.28), rng:NextNumber(1.7, 2.0), {"InTree"})
	place("bench", CX + dx, sqZ - 8, math.pi, 1, {"OnBench"})
	-- a parasol table on each side of the fountain
	cafeTable(CX + dx * 0.55, sqZ + 11, math.pi / 2)
	place("parasol", CX + dx * 0.55, sqZ + 11, 0, 1, {})
end
place("bench", CX, sqZ + 12, math.pi, 1, {"OnBench"})

-- 3. cafés: two tables (chairs along the wall) under the awning, kept clear of the door
for _, cafe in ipairs(cafes) do
	for _, j in ipairs({-1, 1}) do
		local tx = cafe.x + j * 5.2
		if math.abs(tx - cafe.doorX) < 4.4 then tx = tx + j * 3.8 end
		cafeTable(tx, cafe.z, cafe.yaw + math.pi / 2)
	end
end

-- 4. lamp posts, bollards at both ends
for x = CX - LEN / 2 + 14, CX + LEN / 2 - 14, 36 do
	place("lamp_post", x, CZ + STREET_W / 2 + 1.2, 0, 1.1, {"ByLamp"})
	place("lamp_post", x + 18, CZ - STREET_W / 2 - 1.2, math.pi, 1.1, {"ByLamp"})
end
place("bollards", CX + LEN / 2 - 3, CZ, math.pi / 2, 1, {})
place("bollards", CX - LEN / 2 + 3, CZ + STREET_W / 2 + 2, 0, 1, {})

-- 5. the bridge to the forest
place("bridge", bridgeCX, CZ, 0, 1, {"UnderBridge"})

-- 6. zones for the HUD (one flat part per map)
local zones = workspace:FindFirstChild("Zones") or Instance.new("Folder")
zones.Name = "Zones"; zones.Parent = workspace
local function zone(id, cx, cz, sx, sz)
	local z = zones:FindFirstChild(id) or Instance.new("Part")
	z.Name = id; z.Anchored = true; z.CanCollide = false; z.CanQuery = false; z.CanTouch = false; z.Transparency = 1
	-- the HUD only reads a zone's X/Z footprint; keep the box well below the ground so Studio drag-and-drop never lands things on it
	z.Size = Vector3.new(sx, 2, sz); z.Position = Vector3.new(cx, GY - 50, cz); z:SetAttribute("MapId", id); z.Parent = zones
end
zone("forest", attr("ForestCenterX", 0), attr("ForestCenterZ", -120), attr("ForestWidth", 240), attr("ForestDepth", 180))
zone(MAP_ID, CX, CZ, LEN + 20, 140)
print(string.format("VillageBuilder: %d props, %d hiding spots", #placed, #spots:GetChildren()))

-- 7. hide this map's squirrels (from the registry) in the village spots
if HIDE then
	local ss = workspace:FindFirstChild("SquirrelScripts", true)
	local reg = ss and ss:FindFirstChild("SquirrelRegistry")
	local Registry = reg and require(reg)
	if Registry then
		local mine = {}
		for _, e in ipairs(Registry.squirrels) do if e.map == MAP_ID then mine[e.id] = true end end
		local squirrels = {}
		for _, inst in ipairs(workspace:GetChildren()) do
			local mp = inst:IsA("Model") and inst:FindFirstChildWhichIsA("MeshPart", true)
			if mp and mp:FindFirstChild("Tail2", true) and not inst.Name:lower():find("gray") then
				local id = inst.Name:lower():gsub("_color$", "")
				if mine[id] then table.insert(squirrels, inst) end
			end
		end
		local list = spots:GetChildren()
		local rank = {InWindow = 1, InFountain = 2, UnderTable = 3, UnderBridge = 4, UnderHedge = 5, InTree = 6, BehindPlanter = 7, OnAwning = 8, InDoorway = 9, OnBench = 10, BesideBike = 11, ByLamp = 12}
		for _, a in ipairs(list) do a:SetAttribute("r", rng:NextNumber()) end
		table.sort(list, function(a, b)
			local ra, rb = rank[a.Name] or 9, rank[b.Name] or 9
			if ra ~= rb then return ra < rb end
			return a:GetAttribute("r") < b:GetAttribute("r")
		end)
		for i, sq in ipairs(squirrels) do
			local spot = list[i]
			if not spot then break end
			local wc = spot.WorldCFrame
			local rot0 = sq:GetPivot().Rotation
			sq:PivotTo(CFrame.new(wc.Position) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0) * rot0)
			local cf, size = sq:GetBoundingBox()
			sq:PivotTo(sq:GetPivot() + Vector3.new(wc.Position.X - cf.Position.X, wc.Position.Y - (cf.Position.Y - size.Y / 2), wc.Position.Z - cf.Position.Z))
			spot:SetAttribute("Squirrel", sq.Name)
		end
		print(string.format("VillageBuilder: hid %d village squirrels", math.min(#squirrels, #list)))
	else
		warn("VillageBuilder: SquirrelRegistry not found; squirrels left where they are")
	end
end
folder:SetAttribute("Done", true)
end
'''

RUNNER = r'''
-- Build (server): rebuilds the village when the game starts unless the folder's Enabled attribute is false.
-- To build it permanently into the place, run in the command bar while NOT playing:
--     require(workspace.VillageBuilder.BuildModule)()
-- then set the folder's Enabled attribute to false.
require(script.Parent.BuildModule)()
'''

def module_item(name, source, ref):
    return f'''
  <Item class="ModuleScript" referent="{ref}">
    <Properties>
      <string name="Name">{name}</string>
      <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
    </Properties>
  </Item>'''

def script_item(name, source, run_context, ref):
    return f'''
  <Item class="Script" referent="{ref}">
    <Properties>
      <string name="Name">{name}</string>
      <token name="RunContext">{run_context}</token>
      <bool name="Enabled">true</bool>
      <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
    </Properties>
  </Item>'''

xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Folder" referent="RBX0">
    <Properties><string name="Name">VillageBuilder</string></Properties>{module_item("BuildModule", BUILD, "RBX1")}{script_item("Build", RUNNER, 1, "RBX2")}
  </Item>
</roblox>
'''
m.parseString(xml)
OUT.write_text(xml, encoding="utf-8")
print("wrote", OUT)

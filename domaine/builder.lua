-- DomaineBuilder.BuildModule: builds "Château de l'Acorn" (Provençal countryside: lavender field, vineyard, farm)
-- east of the French street, on rolling Roblox Terrain. Edit mode: require(workspace.DomaineBuilder.BuildModule)()
-- then set Enabled = false. Attributes on the folder: Enabled, Seed, MapId ("domaine"), MapName, HideSquirrels,
-- StreetEndX (350), StreetZ (-120), GroundY (0.55).
return function()
local CollectionService = game:GetService("CollectionService")
local folder = script.Parent
local function attr(name, default)
	local v = folder:GetAttribute(name)
	if v == nil then return default end
	return v
end
if attr("Enabled", true) == false then print("DomaineBuilder: disabled") return end
local SEED = attr("Seed", 7)
local MAP_ID = attr("MapId", "domaine")
local MAP_NAME = attr("MapName", "Château de l'Acorn")
local HIDE = attr("HideSquirrels", true)
local X0 = attr("StreetEndX", 350)          -- the French street ends here
local CZ = attr("StreetZ", -120)            -- and runs along this z
local GY0 = attr("GroundY", 0.55)           -- the pavement height the countryside starts from
local rng = Random.new(SEED)
local C = Color3.fromRGB

-- ---------------------------------------------------------------- kit lookup ----
-- domaine_a.obj / domaine_b.obj import as pieces named "<kit>__<piece>"; regroup into one Model per kit
local KIT = {"lavender_row_a", "lavender_row_b", "vine_row_a", "vine_row_b", "cypress", "olive_tree", "sunflower_patch", "boxwood", "oleander",
	"mas", "barn", "chapel", "windmill", "cellar_front", "hut", "coop", "hen",
	"well", "beehive", "lavender_cart", "barrel", "barrel_rack", "wine_press", "crate_grapes", "tasting_table", "long_table", "tractor",
	"trailer", "hay_round", "hay_stack", "scarecrow", "trough", "stone_wall", "stone_wall_b", "stone_pillar", "farm_gate", "picket_fence",
	"picket_gate", "sign_post", "still", "garden", "barrel_open"}
do
	local groups = {}
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("MeshPart") and not p:FindFirstAncestor("Domaine") and not p:FindFirstAncestor("Village") then
			local kit, piece = p.Name:match("^(.-)__(.+)$")
			if kit and piece and table.find(KIT, kit) then
				local g = groups[kit]
				if not g then
					g = Instance.new("Model"); g.Name = kit
					g.Parent = workspace:FindFirstChild("DomaineKit") or (function()
						local f = Instance.new("Folder"); f.Name = "DomaineKit"; f.Parent = workspace; return f end)()
					groups[kit] = g
				end
				p.Name = piece; p.Parent = g
			end
		end
	end
	for _, g in pairs(groups) do g.PrimaryPart = g:FindFirstChildWhichIsA("BasePart") end
	for _, mdl in ipairs(workspace:GetChildren()) do
		if mdl:IsA("Model") and mdl.Name:lower():find("domaine_") and not mdl:FindFirstChildWhichIsA("BasePart", true) then mdl:Destroy() end
	end
end
local templates = {}
local kitFolder = workspace:FindFirstChild("DomaineKit")
if kitFolder then for _, k in ipairs(KIT) do templates[k] = kitFolder:FindFirstChild(k) end end
local villageKit = workspace:FindFirstChild("VillageKit")
local missing = {}
for _, k in ipairs(KIT) do if not templates[k] then table.insert(missing, k) end end
if #missing > 0 then warn("DomaineBuilder: kit pieces not found (import domaine_a.obj and domaine_b.obj, Merge Meshes OFF): " .. table.concat(missing, ", ")) end
if not templates.mas then warn("DomaineBuilder: nothing to build with") return end
-- the templates stay in the kit folder, invisible and inert; every placed prop is a clone
for _, t in pairs(templates) do
	for _, p in ipairs(t:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true; p.Transparency = 1; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false end
	end
end

-- ---------------------------------------------------------------- palette ----
local FLOWERS = {C(230, 90, 120), C(240, 200, 70), C(220, 70, 60), C(200, 120, 220)}
local COLOR = {
	Lav = C(146, 96, 214), Sage = C(152, 172, 150), Soil = C(96, 72, 52),
	VPost = C(120, 92, 62), Wire = C(72, 72, 78), VTrunk = C(94, 70, 50), VLeaf = C(108, 158, 66), GrapeG = C(164, 196, 92), Grape = C(98, 58, 132),
	Cypress = C(54, 88, 58), OTrunk = C(108, 88, 66), Olive = C(152, 170, 132),
	SStem = C(90, 130, 64), SLeaf = C(100, 148, 70), Petal = C(250, 200, 42), Seed = C(92, 56, 30),
	Boxwood = C(72, 116, 62), Oleander = C(84, 132, 76), Bloom = C(250, 248, 240),
	Walls = C(202, 186, 158), Quoin = C(224, 214, 194), Roof = C(186, 116, 90), Tile = C(170, 104, 82), Slate = C(92, 96, 108), Trim = C(234, 228, 212),
	Window = C(150, 180, 200), Shutter = C(98, 140, 178), ShutterB = C(76, 112, 148), Door = C(116, 82, 60), Wood = C(140, 106, 76), Plank = C(160, 128, 96),
	Dark = C(26, 24, 24), Iron = C(48, 48, 52), Brass = C(214, 178, 92), Glass = C(216, 230, 240), Chimney = C(204, 190, 170), Hay = C(230, 198, 102),
	Stone = C(178, 168, 150), Vault = C(116, 108, 98), Water = C(110, 170, 200), Bell = C(204, 168, 76), Cross = C(76, 76, 82),
	Hen = C(236, 226, 204), Comb = C(216, 50, 50), Beak = C(230, 178, 64), HenLeg = C(216, 166, 76), Sails = C(212, 206, 190),
	Hive = C(240, 234, 220), Wicker = C(184, 148, 102), Barrel = C(140, 102, 70), Copper = C(204, 128, 76), Brick = C(166, 90, 72), Bottle = C(90, 128, 90),
	Plate = C(245, 242, 235), Cheese = C(240, 204, 100), Body = C(204, 46, 38), Tread = C(40, 40, 42), Hub = C(234, 184, 40), Twine = C(158, 132, 86),
	Shirt = C(192, 64, 52), Patch = C(76, 116, 178), Pants = C(76, 88, 128), Straw = C(230, 198, 102), Sack = C(204, 178, 128), Hat = C(216, 178, 102),
	Crow = C(26, 26, 30), Picket = C(242, 242, 236), Sign = C(216, 204, 178), Lettuce = C(140, 190, 90), Tomato = C(216, 50, 50), Pumpkin = C(234, 140, 38),
	Gravel = C(192, 178, 154), Leaf = C(114, 158, 76), Crate = C(178, 142, 102), Bench = C(128, 108, 92),
	Handle = C(48, 48, 52), StoneB = C(118, 102, 80),
}
local ORDER = {}
for k in pairs(COLOR) do table.insert(ORDER, k) end
table.sort(ORDER, function(a, b) return #a > #b end)          -- longest prefix wins (ShutterB before Shutter, GrapeG before Grape)
local function colourFor(name)
	local d = tonumber(name:match("^Flower(%d+)$"))
	if d then return FLOWERS[(d - 1) % #FLOWERS + 1] end
	for _, k in ipairs(ORDER) do if name:sub(1, #k) == k then return COLOR[k] end end
	return nil
end
local function tintModel(model, overrides)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local col = (overrides and overrides[p.Name]) or colourFor(p.Name)
			if col then p.Color = col end
			p.Material = Enum.Material.SmoothPlastic
			if p.Name == "Glass" or p.Name == "Window" then p.Material = Enum.Material.Glass; p.Transparency = 0.35 end
			if p.Name == "Water" then p.Transparency = 0.25; p.Reflectance = 0.1 end
			p.CastShadow = true
		end
	end
end

-- ---------------------------------------------------------------- the map folder ----
local old = workspace:FindFirstChild("Domaine")
if old then old:Destroy() end
local domaine = Instance.new("Folder"); domaine.Name = "Domaine"; domaine.Parent = workspace
local props = Instance.new("Folder"); props.Name = "Props"; props.Parent = domaine
local spots = Instance.new("Folder"); spots.Name = "HidingSpots"; spots.Parent = domaine

-- ---------------------------------------------------------------- terrain ----
-- Region: x 380..724, z -284..64 (the play area is x 384..680, z -240..20; the rest falls back to the baseplate).
-- Height: flat pavement level at the garden, then a gentle rise east with a vineyard slope up to a ridge, a rise for
-- the windmill, and a flat terrace for the lavender.
local T = workspace.Terrain
local RES = 4
local RX0, RX1, RZ0, RZ1, RY0, RY1 = 380, 724, -284, 64, -12, 44
local function smooth(t) t = math.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
local function bump(x, z, cx, cz, r, amp) local d = math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2) return amp * (1 - smooth(d / r)) end
local function heightRaw(x, z)
	local h = GY0
	h += 5.5 * smooth((x - 400) / 260)                                   -- the general rise to the east
	h += bump(x, z, 612, -172, 95, 9.0)                                  -- the vineyard ridge (chapel on top)
	h += bump(x, z, 588, -62, 46, 6.5)                                   -- the windmill rise
	h += bump(x, z, 690, -30, 90, 6.0)                                   -- far corner hill
	h += bump(x, z, 662, -240, 70, 5.0)
	h -= bump(x, z, 468, -166, 58, 2.5)                                  -- the lavender terrace stays flat and low
	-- fade to the baseplate outside the play area
	local edge = math.min(smooth((x - 380) / 10), smooth((RX1 - x) / 40), smooth((z - RZ0) / 40), smooth((RZ1 - z) / 40))
	h = h * edge                                                          -- thins to nothing at the border, so the baseplate takes over
	-- the strip that meets the street stays exactly at pavement height
	if x < 400 then h = GY0 + (h - GY0) * smooth((x - 388) / 12) end
	return h
end
local MILL_PAD = {x = 588, z = -62, r0 = 9, r1 = 15}                   -- a level pad on the knoll's crown, so the tower's round base meets the ground all round
local function heightAt(x, z)
	local h = heightRaw(x, z)
	local d = math.sqrt((x - MILL_PAD.x) ^ 2 + (z - MILL_PAD.z) ^ 2)
	if d < MILL_PAD.r1 then
		local hc = heightRaw(MILL_PAD.x, MILL_PAD.z)
		h = hc + (h - hc) * smooth((d - MILL_PAD.r0) / (MILL_PAD.r1 - MILL_PAD.r0))
	end
	-- a rim of hills just beyond the estate's east, south and north walls, so the boundary reads as the land rising
	local rim = 11 * smooth((x - 701) / 11) * (1 - smooth((x - 716) / 8))
	rim = math.max(rim, 11 * smooth((-z - 251) / 11) * (1 - smooth((-z - 268) / 10)))
	rim = math.max(rim, 11 * smooth((z - 31) / 11) * (1 - smooth((z - 48) / 10)))
	return h + rim
end
-- the dirt lane: east along the street axis, then bending to the cellar door; two footpaths branch off it
local LANE = {{X0, CZ}, {392, CZ}, {520, CZ}, {560, -116}, {596, -112}}
local PATHS = {LANE, {{482, CZ}, {482, -80}}, {{596, -112}, {628, -140}, {650, -160}}}
local function distToLane(x, z)
	local best = 1e9
	for _, poly in ipairs(PATHS) do
		for i = 1, #poly - 1 do
			local ax, az, bx, bz = poly[i][1], poly[i][2], poly[i + 1][1], poly[i + 1][2]
			local dx, dz = bx - ax, bz - az
			local t = math.clamp(((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz), 0, 1)
			local px, pz = ax + dx * t, az + dz * t
			best = math.min(best, math.sqrt((x - px) ^ 2 + (z - pz) ^ 2))
		end
	end
	return best
end
local FIELD = {x0 = 424, x1 = 492, z0 = -200, z1 = -132}       -- lavender terrace (soil)
local VINES = {x0 = 528, x1 = 636, z0 = -236, z1 = -118}       -- vineyard (grass with soil lines)
local COURT = {x0 = 452, x1 = 512, z0 = -84, z1 = -52}         -- gravel courtyard in front of the mas
local LAWN = {x0 = 452, x1 = 512, z0 = -52, z1 = -20}
local function materialAt(x, z, h)
	if x >= FIELD.x0 and x <= FIELD.x1 and z >= FIELD.z0 and z <= FIELD.z1 then return Enum.Material.Ground end
	if distToLane(x, z) < 4.5 then return Enum.Material.Ground end
	if x >= COURT.x0 and x <= COURT.x1 and z >= COURT.z0 and z <= COURT.z1 then return Enum.Material.Sand end
	if x >= LAWN.x0 and x <= LAWN.x1 and z >= LAWN.z0 and z <= LAWN.z1 then return Enum.Material.LeafyGrass end
	if x >= VINES.x0 and x <= VINES.x1 and z >= VINES.z0 and z <= VINES.z1 then
		local row = (z - VINES.z0) % 8
		if row < 1.6 then return Enum.Material.Ground end
		return Enum.Material.LeafyGrass
	end
	if h > 14 and rng:NextNumber() < 0.2 then return Enum.Material.Rock end
	return Enum.Material.Grass
end
do
	local region = Region3.new(Vector3.new(RX0, RY0, RZ0), Vector3.new(RX1, RY1, RZ1)):ExpandToGrid(RES)
	T:FillRegion(region, RES, Enum.Material.Air)
	local size = region.Size / RES
	local nx, ny, nz = math.floor(size.X + 0.5), math.floor(size.Y + 0.5), math.floor(size.Z + 0.5)
	local mats, occ = {}, {}
	local rmin = region.CFrame.Position - region.Size / 2
	for ix = 1, nx do
		mats[ix] = {}; occ[ix] = {}
		local x = rmin.X + (ix - 0.5) * RES
		for iy = 1, ny do
			mats[ix][iy] = {}; occ[ix][iy] = {}
			local yb = rmin.Y + (iy - 1) * RES
			for iz = 1, nz do
				local z = rmin.Z + (iz - 0.5) * RES
				local h = heightAt(x, z)
				local fill = math.clamp((h - yb) / RES, 0, 1)
				if fill > 0.001 then
					mats[ix][iy][iz] = materialAt(x, z, h); occ[ix][iy][iz] = fill
				else
					mats[ix][iy][iz] = Enum.Material.Air; occ[ix][iy][iz] = 0
				end
			end
		end
	end
	T:WriteVoxels(region, RES, mats, occ)
	-- terrain colours matched to the world: the baseplate green for grass, warm earth for the lane and the lavender soil
	local bp = workspace:FindFirstChild("Baseplate")
	local green = bp and bp.Color or C(94, 142, 76)
	T:SetMaterialColor(Enum.Material.Grass, green)
	T:SetMaterialColor(Enum.Material.LeafyGrass, green)
	T:SetMaterialColor(Enum.Material.Ground, C(118, 90, 60))
	T:SetMaterialColor(Enum.Material.Sand, C(198, 184, 156))
	T:SetMaterialColor(Enum.Material.Rock, C(150, 146, 138))
	print("DomaineBuilder: terrain written", nx, ny, nz)
	task.wait(0.5)                                                        -- terrain collision updates a frame later: the ground raycasts must see the NEW voxels
end

-- ---------------------------------------------------------------- placement ----
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local ignore = {props, spots}
for _, t in pairs(templates) do table.insert(ignore, t) end
if kitFolder then table.insert(ignore, kitFolder) end
if villageKit then table.insert(ignore, villageKit) end
for _, mdl in ipairs(CollectionService:GetTagged("Squirrel")) do table.insert(ignore, mdl) end
for _, z in ipairs((workspace:FindFirstChild("Zones") or Instance.new("Folder")):GetChildren()) do table.insert(ignore, z) end
if workspace:FindFirstChild("Boundary") then table.insert(ignore, workspace.Boundary) end   -- the invisible boundary walls are raycast-visible (CanQuery is forced on by CanCollide)
rp.FilterDescendantsInstances = ignore
local function groundAt(x, z)
	local r = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rp)
	return r and r.Position.Y or GY0
end
-- bounding-box centres of the kits whose own coordinates the builder needs after placement (measured from the OBJ files)
local KIT_CENTRE = {trough = Vector3.new(1.010, 2.300, 0.000), tractor = Vector3.new(0.000, 4.335, -0.500), coop = Vector3.new(1.017, 4.731, -3.400),
	hen = Vector3.new(-0.013, 1.023, -0.063), trailer = Vector3.new(0.000, 2.633, -2.235), garden = Vector3.new(0.000, 1.900, -0.100)}
local ATOMIC = {hen = true, tractor = true, trailer = true, trough = true, coop = true, lavender_row_a = true, lavender_row_b = true, sunflower_patch = true}
local placed = {}
-- ---------------------------------------------------------------- table dressing (plain Parts) ----
local function mkPart(parent, name, size, cf, col, shape)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Locked = true
	p.Material = Enum.Material.SmoothPlastic; p.Color = col; p.Size = size; p.CFrame = cf; p.CastShadow = true
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local function mkBall(parent, name, d, cf, col) return mkPart(parent, name, Vector3.new(d, d, d), cf, col, Enum.PartType.Ball) end
local function mkEgg(parent, name, size, cf, col)                     -- a Block with a Sphere mesh: an ellipsoid of any proportions
	local p = mkPart(parent, name, size, cf, col)
	local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
	return p
end
local function mkDisc(parent, name, r, h, cf, col)                   -- an upright cylinder (Roblox cylinders lie along X)
	return mkPart(parent, name, Vector3.new(h, r * 2, r * 2), cf * CFrame.Angles(0, 0, math.pi / 2), col, Enum.PartType.Cylinder)
end
-- a cafe table: cream cloth with a blue hem, two settings with croissants, a posy in a vase
local function dressCafeTable(ct)
	local tbl = ct:FindFirstChild("Table")
	if not tbl then return end
	local top = tbl.Position.Y + tbl.Size.Y / 2
	local c = Vector3.new(tbl.Position.X, top, tbl.Position.Z)
	local r = math.max(tbl.Size.X, tbl.Size.Z) / 2
	local CLOTH, HEM, SILVER = C(250, 246, 232), C(96, 140, 190), C(206, 210, 216)
	mkDisc(ct, "Cloth", r + 0.16, 0.06, CFrame.new(c + Vector3.new(0, 0.03, 0)), CLOTH)
	mkDisc(ct, "Cloth", r + 0.10, 0.52, CFrame.new(c - Vector3.new(0, 0.26, 0)), CLOTH)
	mkDisc(ct, "Hem", r + 0.12, 0.07, CFrame.new(c - Vector3.new(0, 0.50, 0)), HEM)
	for _, sz in ipairs({-0.62, 0.62}) do
		local dir = sz > 0 and 1 or -1
		mkDisc(ct, "Plate", 0.36, 0.04, CFrame.new(c + Vector3.new(0, 0.08, sz)), C(252, 252, 248))
		mkDisc(ct, "PlateRim", 0.24, 0.015, CFrame.new(c + Vector3.new(0, 0.105, sz)), C(226, 234, 242))
		local g = mkDisc(ct, "Glass", 0.1, 0.32, CFrame.new(c + Vector3.new(0.52, 0.22, sz * 0.7)), C(214, 232, 242)); g.Transparency = 0.45
		mkPart(ct, "Knife", Vector3.new(0.05, 0.02, 0.5), CFrame.new(c + Vector3.new(0.48, 0.07, sz)), SILVER)
		mkPart(ct, "Fork", Vector3.new(0.05, 0.02, 0.5), CFrame.new(c + Vector3.new(-0.48, 0.07, sz)), SILVER)
		for _, o in ipairs({{-0.14, 0.05}, {0, 0.1}, {0.14, 0.05}}) do
			mkBall(ct, "Croissant", 0.15, CFrame.new(c + Vector3.new(o[1], 0.16, sz + o[2] * dir)), C(224, 172, 94))
		end
	end
	mkDisc(ct, "Vase", 0.12, 0.34, CFrame.new(c + Vector3.new(0, 0.23, 0)), C(80, 120, 180))
	for _, o in ipairs({{-0.1, 0.02, C(240, 90, 120)}, {0.09, -0.05, C(250, 200, 70)}, {0.02, 0.1, C(230, 80, 70)}}) do
		mkPart(ct, "Stem", Vector3.new(0.03, 0.32, 0.03), CFrame.new(c + Vector3.new(o[1] * 0.5, 0.56, o[2] * 0.5)), C(90, 140, 70))
		mkBall(ct, "Bloom", 0.17, CFrame.new(c + Vector3.new(o[1], 0.74, o[2])), o[3])
	end
end
-- the long table: the kit's plates, glasses and bottles come off; twelve settings go back on at the table's edges
-- (plate, glass, knife, fork) so the middle 1.2 studs stay free for the food, which is sized to fit that band
local function dressLongTable(lt)
	local plank = lt:FindFirstChild("Plank")
	if not plank then return end
	for _, p in ipairs(lt:GetChildren()) do
		if p:IsA("BasePart") and (p.Name:sub(1, 6) == "Bottle" or p.Name == "Plate" or p.Name == "Glass") then p:Destroy() end
	end
	local topY = plank.Position.Y + plank.Size.Y / 2
	local function at(x, y, z)
		local w = plank.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
		return CFrame.new(w.X, topY + y, w.Z)
	end
	local function atR(x, y, z, yaw) return at(x, y, z) * plank.CFrame.Rotation * CFrame.Angles(0, yaw, 0) end
	local SILVER, WOOD, WHITE, GLASS = C(206, 210, 216), C(150, 112, 76), C(252, 252, 248), C(214, 232, 242)
	for i = 0, 5 do
		local x = -5.0 + i * 2.0
		for _, s in ipairs({-1, 1}) do
			local z = s * 1.22
			mkDisc(lt, "Plate", 0.52, 0.04, at(x, 0.02, z), WHITE)
			mkDisc(lt, "PlateRim", 0.36, 0.015, at(x, 0.045, z), C(226, 234, 242))
			local g = mkDisc(lt, "Glass", 0.1, 0.32, at(x + 0.95, 0.16, s * 0.88), GLASS); g.Transparency = 0.45
			mkPart(lt, "Fork", Vector3.new(0.05, 0.02, 0.5), atR(x - 0.70, 0.01, z, 0), SILVER)
			mkPart(lt, "Knife", Vector3.new(0.05, 0.02, 0.5), atR(x + 0.70, 0.01, z, 0), SILVER)
		end
	end
	-- bread basket
	mkDisc(lt, "Basket", 0.5, 0.22, at(-5.0, 0.11, 0), C(184, 148, 102))
	for k, o in ipairs({{0.25, 0.12}, {-0.2, -0.1}, {0.05, 0.02}}) do
		mkPart(lt, "Baguette", Vector3.new(1.3, 0.24, 0.24), atR(-5.0 + o[2], 0.32 + k * 0.03, o[2] * 0.8, o[1]), C(216, 170, 98), Enum.PartType.Cylinder)
	end
	-- cheese board
	mkDisc(lt, "Board", 0.6, 0.06, at(-3.0, 0.03, 0), WOOD)
	mkDisc(lt, "Cheese", 0.32, 0.2, at(-3.2, 0.16, 0.1), C(240, 204, 100))
	mkPart(lt, "Cheese", Vector3.new(0.4, 0.18, 0.26), atR(-2.62, 0.15, -0.2, 0.6), C(240, 204, 100))
	mkDisc(lt, "Brie", 0.2, 0.11, at(-2.68, 0.115, 0.3), C(250, 246, 226))
	for _, o in ipairs({{-3.35, -0.35}, {-3.25, -0.44}, {-3.45, -0.45}}) do mkBall(lt, "Grape", 0.13, at(o[1], 0.125, o[2]), C(98, 58, 132)) end
	-- roast chicken on a platter with potatoes
	mkDisc(lt, "Platter", 0.6, 0.05, at(-1.0, 0.025, 0), WHITE)
	mkEgg(lt, "Chicken", Vector3.new(1.0, 0.58, 0.7), atR(-1.0, 0.34, 0, 0), C(200, 128, 62))
	mkEgg(lt, "Drumstick", Vector3.new(0.34, 0.22, 0.22), atR(-0.55, 0.19, 0.32, 0.5), C(196, 120, 58))
	mkEgg(lt, "Drumstick", Vector3.new(0.34, 0.22, 0.22), atR(-1.45, 0.19, 0.32, -0.5), C(196, 120, 58))
	for _, o in ipairs({{-1.5, -0.38}, {-1.2, -0.45}, {-0.7, -0.42}, {-0.45, -0.25}}) do mkBall(lt, "Potato", 0.2, at(o[1], 0.15, o[2]), C(232, 196, 110)) end
	-- salad
	mkDisc(lt, "Bowl", 0.5, 0.34, at(1.0, 0.17, 0), C(250, 246, 232))
	mkEgg(lt, "Salad", Vector3.new(0.9, 0.42, 0.9), at(1.0, 0.44, 0), C(100, 168, 70))
	for _, o in ipairs({{0.8, 0.12}, {1.18, -0.15}, {1.03, 0.26}}) do mkBall(lt, "Tomato", 0.17, at(o[1], 0.62, o[2]), C(216, 50, 50)) end
	-- strawberry tart
	mkDisc(lt, "Tart", 0.55, 0.14, at(3.0, 0.07, 0), C(222, 178, 110))
	mkDisc(lt, "Tart", 0.46, 0.05, at(3.0, 0.165, 0), C(204, 58, 58))
	for i = 0, 5 do local a = i / 6 * 6.283 mkBall(lt, "Strawberry", 0.14, at(3.0 + math.cos(a) * 0.3, 0.24, math.sin(a) * 0.3), C(214, 40, 44)) end
	-- fruit bowl
	mkDisc(lt, "Bowl", 0.5, 0.3, at(5.0, 0.15, 0), C(96, 140, 190))
	mkBall(lt, "Apple", 0.28, at(4.85, 0.4, -0.12), C(200, 50, 50)); mkBall(lt, "Apple", 0.27, at(5.2, 0.38, 0.14), C(140, 190, 60))
	mkBall(lt, "Orange", 0.25, at(4.88, 0.55, 0.18), C(240, 150, 40)); mkEgg(lt, "Pear", Vector3.new(0.24, 0.34, 0.24), at(5.24, 0.56, -0.17), C(200, 210, 90))
	for i = 0, 5 do mkBall(lt, "Grape", 0.13, at(5.0 + (i % 3 - 1) * 0.12, 0.66 + math.floor(i / 3) * 0.09, (i % 2) * 0.1 - 0.02), C(98, 58, 132)) end
end
-- a stone foundation course under a building's walls: the ground slopes, the building is level, and without it the
-- downhill corner hangs in the air. Mostly buried; only the downhill side shows.
local function plinth(model, depth)
	local walls = model and model:FindFirstChild("Walls")
	if not walls then return end
	local f = Instance.new("Part"); f.Name = "Foundation"; f.Anchored = true; f.CanCollide = true; f.CanQuery = true; f.Locked = true
	f.Material = Enum.Material.SmoothPlastic; f.CastShadow = true
	local c = walls.Color; f.Color = Color3.new(c.R * 0.8, c.G * 0.78, c.B * 0.74)
	f.Size = Vector3.new(walls.Size.X + 0.5, depth, walls.Size.Z + 0.5)
	f.CFrame = walls.CFrame * CFrame.new(0, -walls.Size.Y / 2 - depth / 2 + 0.15, 0)
	f.Parent = model
end
local function unlock(model) for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Locked = false end end end
-- place(kit, x, z, yaw, opts): opts.scale, opts.tint (overrides table), opts.tilt (follow the slope along the model's x),
-- opts.sink (studs below ground), opts.spots = { {kind, dx, dy, dz}, ... } in the model's frame, opts.precise
local function place(kitName, x, z, yaw, opts)
	opts = opts or {}
	local t = templates[kitName] or (villageKit and villageKit:FindFirstChild(kitName))
	if not t then return end
	local model = t:Clone(); model.Name = kitName
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.Transparency = 0; p.CanCollide = true; p.CanQuery = true; p.Locked = true; p.Anchored = true end
	end
	if ATOMIC[kitName] then model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end
	model.Parent = props
	if opts.tint == nil and (kitName == "stone_wall" or kitName == "stone_wall_b" or kitName == "stone_pillar") then opts.tint = {Stone = C(172, 146, 108), StoneB = C(108, 86, 60), Quoin = C(188, 170, 142)} end   -- must precede tintModel
	tintModel(model, opts.tint)
	if opts.scale and opts.scale ~= 1 then model:ScaleTo(opts.scale) end
	local gy = opts.fixedY or groundAt(x, z)          -- fixedY: props inside the cellar, under the earth knoll
	-- Import 3D turns every kit 180 degrees about Y (kit front -Z ends up on +Z), so turn it back; spot offsets below are
	-- given in kit coordinates and the two flips cancel there
	local rot = CFrame.Angles(0, yaw + math.pi, 0)
	if opts.tilt then                  -- slope along the model's own x axis (rows): sample the ground at both ends
		local bb0, size0 = model:GetBoundingBox()
		local half = size0.X / 2 * 0.9
		local ex = rot:VectorToWorldSpace(Vector3.new(half, 0, 0))
		local ya, yb = groundAt(x + ex.X, z + ex.Z), groundAt(x - ex.X, z - ex.Z)
		local pitch = math.atan2(ya - yb, 2 * half)
		rot = rot * CFrame.Angles(0, 0, pitch)
		gy = (ya + yb) / 2
	end
	model:PivotTo(CFrame.new(x, gy, z) * rot)
	local bb, size = model:GetBoundingBox()
	-- centre the footprint on (x, z) and rest the bottom on the ground (the kit's own bottom is its y = 0). The box is
	-- oriented with the model, so the centre of its bottom face is what meets the ground (tilted rows follow the slope).
	local bottom = bb.Position.Y - bb.UpVector.Y * size.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(x - bb.Position.X, gy - bottom - (opts.sink or 0), z - bb.Position.Z))
	do
		local bb2 = model:GetBoundingBox()
		if not model.PrimaryPart then model.WorldPivot = CFrame.new(bb2.Position) * model:GetPivot().Rotation end   -- a pivot on the prop, not off in space
		local kc = KIT_CENTRE[kitName]
		if kc then                                     -- KitOrigin: the kit's own (0,0,0) and axes, in world space (kit coordinates -> world)
			local sc = opts.scale or 1
			model:SetAttribute("KitOrigin", CFrame.new(bb2.Position) * CFrame.Angles(0, yaw, 0) * CFrame.new(-kc.X * sc, -kc.Y * sc, -kc.Z * sc))
		end
	end
	if opts.precise then
		for _, p in ipairs(model:GetDescendants()) do if p:IsA("MeshPart") then p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end end
	end
	if opts.spots then
		local base = CFrame.new(x, gy, z) * CFrame.Angles(0, yaw, 0)
		for _, sp in ipairs(opts.spots) do
			local a = Instance.new("Attachment"); a.Name = sp[1]; a.Parent = spots
			a.WorldCFrame = base * CFrame.new(sp[2], sp[3], sp[4])
			a:SetAttribute("Face", sp[5] or yaw)
		end
	end
	table.insert(placed, model)
	return model
end
local function spotAt(kind, x, y, z, face)
	local a = Instance.new("Attachment"); a.Name = kind; a.Parent = spots
	a.WorldCFrame = CFrame.new(x, y, z) * CFrame.Angles(0, face or 0, 0)
	return a
end
local function signText(model, text, size)
	local board = model:FindFirstChild("Sign", true)
	if not board then return end
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local gui = Instance.new("SurfaceGui"); gui.Face = face; gui.LightInfluence = 0.6; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 60
		gui.Parent = board
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Text = text
		l.FontFace = Font.new("rbxasset://fonts/families/PatrickHand.json"); l.TextScaled = true; l.TextColor3 = C(70, 50, 30); l.Parent = gui
		local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = size or 40; tc.Parent = l
	end
end

-- ---------------------------------------------------------------- 1. the gate: garden at the end of the street ----
-- The street (22 wide, sidewalks 9 each side) ends at X0. A picket fence closes it off with a gate on the axis; inside,
-- two garden plots either side of a gravel path, and a second gate lets the lane out on the east side.
local GX0, GX1 = X0 + 2, X0 + 38
local GZ0, GZ1 = CZ - 22, CZ + 22
do
	-- a flat pavement-coloured pad so the garden sits level with the street
	local pad = Instance.new("Part"); pad.Name = "GardenPad"; pad.Anchored = true; pad.Size = Vector3.new(GX1 - GX0 + 2, 0.6, GZ1 - GZ0 + 2)
	pad.Position = Vector3.new((GX0 + GX1) / 2, GY0 - 0.3, CZ); pad.Color = C(178, 164, 136); pad.Material = Enum.Material.Sand; pad.Locked = true
	pad.TopSurface = Enum.SurfaceType.Smooth; pad.Parent = domaine
	local path = Instance.new("Part"); path.Name = "GardenPath"; path.Anchored = true; path.Size = Vector3.new(GX1 - GX0 + 2, 0.12, 7)
	path.Position = Vector3.new((GX0 + GX1) / 2, GY0 + 0.06, CZ); path.Color = C(192, 178, 154); path.Material = Enum.Material.Sand; path.Locked = true; path.Parent = domaine
	-- fence: west side (with the street gate), north and south sides, east side (with the lane gate)
	local function fenceRun(x0, z0, x1, z1, gateAt, noLeaf, gateW)
		local L = math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
		local yaw = math.atan2(-(z1 - z0), x1 - x0)
		local ux, uz = (x1 - x0) / L, (z1 - z0) / L
		local function fill(s0, s1)                        -- picket segments (about 8 studs each, scaled to fit) over [s0, s1]
			local len = s1 - s0
			if len < 0.6 then return end
			local n = math.max(1, math.floor(len / 8 + 0.5))
			local seg = len / n
			for k = 0, n - 1 do
				local sm = s0 + (k + 0.5) * seg
				place("picket_fence", x0 + ux * sm, z0 + uz * sm, yaw, {scale = seg / 8})
			end
		end
		if gateAt then
			local g, w = L * gateAt, gateW or 6                -- the opening is centred exactly where asked (the street axis)
			fill(0, g - w / 2); fill(g + w / 2, L)
			if not noLeaf then place("picket_gate", x0 + ux * g, z0 + uz * g, yaw, {scale = w / 4}) end
		else
			fill(0, L)
		end
	end
	fenceRun(GX0, GZ0, GX0, GZ1, 0.5, true)       -- west, gate on the street axis (its locking leaf comes from the Boundary build)
	fenceRun(GX0, GZ1, GX1, GZ1)                  -- north
	fenceRun(GX0, GZ0, GX1, GZ0)                  -- south
	fenceRun(GX1, GZ0, GX1, GZ1, 0.5)             -- east, gate to the lane
	place("garden", (GX0 + GX1) / 2, CZ + 12.5, math.pi, {spots = {{"InGarden", 5.5, 1.2, 4.0}}})
	place("garden", (GX0 + GX1) / 2, CZ - 12.5, 0)
	place("boxwood", GX0 + 4, GZ1 - 4, 0); place("boxwood", GX0 + 4, GZ0 + 4, 0)
	place("oleander", GX1 - 6, GZ1 - 5, 0.4); place("oleander", GX1 - 6, GZ0 + 5, 2.1)
end
local TREE_TINT = {Canopy = C(96, 150, 72), Trunk = C(110, 85, 60)}
local PARASOL_TINT = {Canopy = C(200, 70, 60), Pole = C(70, 60, 55)}

-- ---------------------------------------------------------------- 2. the lane ----
local function alongLane(fromX, toX, step, fn)
	-- walk the polyline and call fn(x, z, yaw, side normal) every `step` studs
	local acc = 0
	for i = 1, #LANE - 1 do
		local ax, az, bx, bz = LANE[i][1], LANE[i][2], LANE[i + 1][1], LANE[i + 1][2]
		local L = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
		local yaw = math.atan2(-(bz - az), bx - ax)
		local nx, nz = -(bz - az) / L, (bx - ax) / L
		local d = acc
		while d < acc + L do
			local f = (d - acc) / L
			local x, z = ax + (bx - ax) * f, az + (bz - az) * f
			if x >= fromX and x <= toX then fn(x, z, yaw, nx, nz) end
			d += step
		end
		acc += L
	end
end
do
	-- dry-stone walls line the straight part of the lane, with openings for the farm path (north) and the lavender
	-- field (south), and cypresses behind them
	local k = 0
	local off = 8.5
	local function opening(x, lo, hi) return x > lo and x < hi end
	alongLane(GX1 + 8, 518, 12, function(x, z, yaw, nx, nz)
		k += 1
		if not opening(x, 470, 494) then place(k % 2 == 0 and "stone_wall" or "stone_wall_b", x + nx * off, z + nz * off, yaw, {tilt = true, precise = true}) end
		if not opening(x, 448, 472) then place(k % 2 == 1 and "stone_wall" or "stone_wall_b", x - nx * off, z - nz * off, yaw, {tilt = true, precise = true}) end
		if k % 3 == 0 then
			local cy, cs = rng:NextNumber(0, 6.28), rng:NextNumber(0.9, 1.15)
			if k ~= 3 then place("cypress", x + nx * (off + 4), z + nz * (off + 4), cy, {scale = cs}) end       -- k = 3 stood in the sunflowers
		end
		if k % 4 == 2 then
			local cy, cs = rng:NextNumber(0, 6.28), rng:NextNumber(0.9, 1.15)
			if k ~= 2 then place("cypress", x - nx * (off + 4), z - nz * (off + 4), cy, {scale = cs}) end       -- k = 2 stood inside the plane tree
		end
	end)
	for _, px in ipairs({470, 494}) do place("stone_pillar", px, CZ + off, 0) end
	for _, px in ipairs({448, 472}) do place("stone_pillar", px, CZ - off, 0) end
	place("stone_pillar", GX1 + 6, CZ + 9, 0); place("stone_pillar", GX1 + 6, CZ - 9, 0)
	place("plane_tree", 410, CZ - 14, 0.6, {scale = 1.6, tint = TREE_TINT})
	place("cypress", 540, -128, 0.4, {scale = 1.1}); place("cypress", 578, -122, 1.3, {scale = 1.0})
end

-- ---------------------------------------------------------------- 3. the lavender field ----
do
	local rows = 12
	local LILAC = C(196, 168, 232)
	for r = 0, rows - 1 do
		local z = FIELD.z0 + 3.5 + r * ((FIELD.z1 - FIELD.z0 - 7) / (rows - 1))
		local lilac = (r == 3 or r == 8)
		for s = 0, 2 do
			local x = FIELD.x0 + 11 + s * 21.5
			local m = place((r + s) % 2 == 0 and "lavender_row_a" or "lavender_row_b", x, z, 0, {tilt = true, tint = lilac and {Lav = LILAC} or nil,
				spots = (r == 5 and s == 1) and {{"InLavender", 2.0, 0.6, 0.0}} or nil})
		end
	end
	place("well", FIELD.x0 - 5, FIELD.z1 + 6, 0.3, {spots = {{"InWell", 0.0, 0.9, 0.0}}})
	for i = 0, 4 do
		local z = FIELD.z0 + 8 + i * 12
		local hive = place("beehive", FIELD.x1 + 6, z, -math.pi / 2, {spots = (i == 2) and {{"OnHive", 0.0, 4.15, 0.0, -math.pi / 2}} or nil})
		if hive then
			local top = hive:FindFirstChild("Hive", true) or hive:FindFirstChildWhichIsA("BasePart")
			local a = Instance.new("Attachment"); a.Name = "Bees"; a.Parent = top
			a.WorldCFrame = CFrame.new(FIELD.x1 + 5.2, groundAt(FIELD.x1 + 6, z) + 1.6, z)
			local pe = Instance.new("ParticleEmitter"); pe.Name = "Bees"; pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Color = ColorSequence.new(C(60, 50, 20)); pe.Size = NumberSequence.new(0.18); pe.Transparency = NumberSequence.new(0.1)
			pe.Lifetime = NumberRange.new(2.5, 4); pe.Rate = 4; pe.Speed = NumberRange.new(1.2, 2.4); pe.SpreadAngle = Vector2.new(180, 180)
			pe.Acceleration = Vector3.new(0, 0.3, 0); pe.Drag = 1.5; pe.Rotation = NumberRange.new(0, 360); pe.LightEmission = 0.1; pe.Parent = a
		end
	end
	place("lavender_cart", FIELD.x0 + 26, FIELD.z1 + 7, math.pi * 0.95)
	local hutX, hutZ = FIELD.x1 + 22, FIELD.z1 - 14
	plinth(place("hut", hutX, hutZ, 0), 2.0)
	place("still", hutX + 8.5, hutZ - 0.5, 0)
	place("olive_tree", FIELD.x0 - 12, FIELD.z0 + 10, 1.2, {scale = 1.3})
	place("olive_tree", FIELD.x1 + 16, FIELD.z0 - 6, 2.4, {scale = 1.1})
end

-- ---------------------------------------------------------------- 4. the vineyard ----
do
	local rows = math.floor((VINES.z1 - VINES.z0) / 8)
	for r = 1, rows - 1 do          -- row 0, beside the wall, came out on Sep 25 2026 for the toadstool hop line (build_hopline.lua)
		local z = VINES.z0 + 0.8 + r * 8
		local green = (r % 3 == 1)
		for s = 0, 3 do
			local x = VINES.x0 + 12 + s * 25
			local nm = (r + s) % 2 == 0 and "vine_row_a" or "vine_row_b"
			place(nm, x, z, 0, {tilt = true, tint = green and {Grape = C(164, 196, 92)} or nil,
				spots = (r == 4 and s == 2) and {{"InVines", 0.0, 1.0, -1.2}} or nil})
		end
	end
	-- the cellar at the end of the lane: a stone room with earth heaped over it, door facing the lane (south)
	local cx, cz = 600, -108
	local cellar = place("cellar_front", cx, cz, 0, {sink = 0.2, precise = true})
	if cellar then
		local gy = groundAt(cx, cz)
		-- earth heaped over the room: a buried core, a low dome on top and banks either side, then the room and the
		-- doorway carved hollow again (terrain fills ignore parts)
		T:FillBlock(CFrame.new(cx, gy + 4.6, cz + 6.0), Vector3.new(11.5, 9.6, 10.5), Enum.Material.Grass)
		T:FillBall(Vector3.new(cx, gy + 4.5, cz + 6.5), 7.8, Enum.Material.Grass)
		T:FillBall(Vector3.new(cx - 7.5, gy + 0.5, cz + 6.5), 6.0, Enum.Material.Grass)
		T:FillBall(Vector3.new(cx + 7.5, gy + 0.5, cz + 6.5), 6.0, Enum.Material.Grass)
		T:FillBall(Vector3.new(cx, gy + 0.5, cz + 13), 6.0, Enum.Material.Grass)
		T:FillBlock(CFrame.new(cx, gy + 3.7, cz + 5.6), Vector3.new(5.6, 9.4, 9.2), Enum.Material.Air)     -- the room stays hollow, down to its stone floor
		T:FillBlock(CFrame.new(cx, gy + 4.6, cz - 1.5), Vector3.new(7.0, 9.0, 5.5), Enum.Material.Air)     -- and the doorway clear
		local floorY = gy - 0.2                                                                   -- the cellar floor slab (sink 0.2)
		-- the room's meshes are one piece each, so their collision hulls would fill the room and block the arch; swap
		-- them for explicit invisible colliders: floor, three walls, ceiling, the two piers and the header over the arch
		for _, p in ipairs(cellar:GetDescendants()) do
			if p:IsA("BasePart") and (p.Name == "Vault" or p.Name == "Walls" or p.Name == "Stone") then p.CanCollide = false end
		end
		local function collider(name, pos, size)
			local q = Instance.new("Part"); q.Name = name; q.Anchored = true; q.CanCollide = true; q.CanQuery = true; q.Transparency = 1
			q.Locked = true; q.Size = size; q.CFrame = CFrame.new(pos); q.Parent = cellar
		end
		collider("CellarFloor", Vector3.new(cx, floorY - 0.25, cz + 5.5), Vector3.new(7.2, 0.5, 12.6))
		collider("CellarWallL", Vector3.new(cx - 3.0, floorY + 4.3, cz + 5.6), Vector3.new(1.0, 8.6, 8.4))
		collider("CellarWallR", Vector3.new(cx + 3.0, floorY + 4.3, cz + 5.6), Vector3.new(1.0, 8.6, 8.4))
		collider("CellarBack", Vector3.new(cx, floorY + 4.3, cz + 9.9), Vector3.new(7.2, 8.6, 1.0))
		collider("CellarCeiling", Vector3.new(cx, floorY + 8.6, cz + 5.5), Vector3.new(7.2, 1.0, 12.6))
		collider("CellarPierL", Vector3.new(cx - 5.25, floorY + 4.5, cz), Vector3.new(5.5, 9.0, 3.0))
		collider("CellarPierR", Vector3.new(cx + 5.25, floorY + 4.5, cz), Vector3.new(5.5, 9.0, 3.0))
		collider("CellarHeader", Vector3.new(cx, floorY + 8.3, cz), Vector3.new(5.4, 1.4, 3.0))
		place("barrel_rack", cx - 0.6, cz + 6.8, math.pi / 2, {fixedY = floorY})
		place("barrel_open", cx + 1.7, cz + 3.4, 0.3, {fixedY = floorY, spots = {{"InBarrel", 0.0, 0.25, 0.0}}})
		place("crate_grapes", cx - 4.8, cz - 5.0, 0.4, {spots = {{"InCrate", 0.0, 1.1, 0.0}}})
		place("crate_grapes", cx - 6.6, cz - 3.2, 2.2)
		place("wine_press", cx + 7.5, cz - 4.5, 0)
		place("tasting_table", cx - 10, cz - 7, 0.2)
		place("barrel", cx + 12.5, cz - 3, 1.0)
	end
	plinth(place("chapel", 655, -172, math.pi * 0.75, {spots = {{"InBelfry", 3.5, 20.3, -7.5}}, precise = true}), 2.4)
	place("cypress", 665, -165, 0, {scale = 1.2}); place("cypress", 645, -183, 0, {scale = 1.1})     -- flanking the nave, clear of the door
	place("olive_tree", 560, -100, 0.8, {scale = 1.2})
end

-- ---------------------------------------------------------------- 5. the farm ----
do
	local MX, MZ = 482, -36
	plinth(place("mas", MX, MZ, 0, {precise = true}), 2.0)
	-- courtyard: long table with parasols under a plane tree, boxwood balls, oleanders
	local ltable = place("long_table", MX + 2, MZ - 30, 0, {spots = {{"UnderTable", 0.0, 1.4, 0.0}}})
	if ltable then                                     -- seats along both benches, facing the table (kit coords: benches at z = +-3, top 1.76)
		local gyT = groundAt(MX + 2, MZ - 30)
		local base = CFrame.new(MX + 2, gyT, MZ - 30)
		for _, sz in ipairs({-3.0, 3.0}) do
			for _, sx in ipairs({-4.5, -1.5, 1.5, 4.5}) do
				local pos = (base * CFrame.new(sx, 1.9, sz)).Position
				local seat = Instance.new("Seat"); seat.Name = "BenchSeat"; seat.Anchored = true; seat.CanCollide = true; seat.CanQuery = false
				seat.Transparency = 1; seat.Locked = true; seat.Size = Vector3.new(2.6, 0.3, 1.3)
				seat.CFrame = CFrame.lookAt(pos, (base * CFrame.new(sx, 1.9, 0)).Position)
				seat.Parent = ltable
			end
		end
		dressLongTable(ltable)
	end
	-- a small terrace by the front door: two café tables with chairs, each with its own parasol standing beside it
	for i, tx in ipairs({MX - 9, MX + 11}) do
		local tz = MZ - 21
		local ct = place("cafe_table", tx, tz, 0)
		if ct then
			local gyC = groundAt(tx, tz)
			for _, sz in ipairs({-2.05, 2.05}) do
				local seat = Instance.new("Seat"); seat.Name = "ChairSeat"; seat.Anchored = true; seat.CanCollide = true; seat.CanQuery = false
				seat.Transparency = 1; seat.Locked = true; seat.Size = Vector3.new(1.6, 0.3, 1.4)
				seat.CFrame = CFrame.lookAt(Vector3.new(tx, gyC + 1.55, tz + sz), Vector3.new(tx, gyC + 1.55, tz))
				seat.Parent = ct
			end
			dressCafeTable(ct)
		end
		place("parasol", tx + (i == 1 and 2.7 or -2.7), tz, 0, {tint = PARASOL_TINT, scale = 1.25})
	end
	place("plane_tree", MX - 16, MZ - 26, 0.3, {scale = 1.8, tint = TREE_TINT})
	for i = 0, 5 do place("boxwood", MX - 20 + i * 8, MZ - 14, 0, {scale = rng:NextNumber(0.8, 1.1)}) end
	place("oleander", MX - 22, MZ - 4, 0.5); place("oleander", MX + 22, MZ - 6, 2.0)
	place("cypress", MX + 21, MZ + 6, 0, {scale = 1.15}); place("cypress", MX + 25, MZ + 2, 0, {scale = 0.95})
	place("stone_wall", MX - 24, MZ - 44, 0, {tilt = true, precise = true}); place("stone_wall_b", MX - 12, MZ - 44, 0, {tilt = true, precise = true})
	place("stone_wall", MX + 12, MZ - 44, 0, {tilt = true, precise = true}); place("stone_wall_b", MX + 24, MZ - 44, 0, {tilt = true, precise = true})
	place("stone_pillar", MX - 5, MZ - 44, 0); place("stone_pillar", MX + 5, MZ - 44, 0)
	place("farm_gate", MX - 2, MZ - 44, 0.35)
	-- barn, coop, tractor, hay, sunflowers, trough, olives
	local BX, BZ = 536, -40
	plinth(place("barn", BX, BZ, 0, {spots = {{"InLoft", 0.0, 15.0, -11.2}}, precise = true}), 2.0)
	local TX, TZ, TYAW = BX - 22, BZ - 20, -1.0                 -- nose toward the open meadow east of the yard
	local tractor = place("tractor", TX, TZ, TYAW)
	if tractor then
		-- a drivable tractor: an invisible Chassis part is the assembly root (kit coordinates = its own frame), the body is
		-- welded to it and each wheel hangs on a Motor6D so it can spin and steer. TractorDrive/TractorClient (below) do the rest.
		local base = tractor:GetAttribute("KitOrigin")
		local chassis = Instance.new("Part"); chassis.Name = "Chassis"; chassis.Anchored = true; chassis.CanCollide = false; chassis.CanQuery = false
		chassis.CanTouch = false; chassis.Transparency = 1; chassis.Locked = true; chassis.Size = Vector3.new(4, 0.4, 8); chassis.RootPriority = 127
		chassis.CFrame = base; chassis.Parent = tractor
		tractor.PrimaryPart = chassis
		local seat = Instance.new("VehicleSeat"); seat.Name = "DriverSeat"; seat.CanCollide = true; seat.CanQuery = false; seat.Transparency = 1
		seat.Locked = true; seat.Size = Vector3.new(1.6, 0.4, 1.4); seat.HeadsUpDisplay = false; seat.MaxSpeed = 0; seat.Torque = 0
		seat.CFrame = base * CFrame.new(0, 4.75, 1.3)                          -- on the saddle, facing the kit's front (-z)
		seat.Parent = tractor
		local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Drive the tractor"; prompt.ObjectText = "Tractor"
		prompt.MaxActivationDistance = 10; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false; prompt.Parent = seat
		for _, p in ipairs(tractor:GetChildren()) do
			if p:IsA("BasePart") and p ~= chassis then
				p.Anchored = false
				local w = p.Name:match("^Tread(..)$")
				if w then
					local m = Instance.new("Motor6D"); m.Name = "Axle" .. w; m.Part0 = chassis; m.Part1 = p
					m.C0 = CFrame.new(chassis.CFrame:PointToObjectSpace(p.Position))   -- position only: the hub frame keeps the chassis axes (X = axle)
					m.C1 = p.CFrame:ToObjectSpace(chassis.CFrame * m.C0)
					m.Parent = chassis
				elseif p.Name:match("^Hub(..)$") then
					local wc = Instance.new("WeldConstraint"); wc.Part0 = tractor:FindFirstChild("Tread" .. p.Name:sub(-2)); wc.Part1 = p; wc.Parent = p
				else
					local wc = Instance.new("WeldConstraint"); wc.Part0 = chassis; wc.Part1 = p; wc.Parent = p
				end
			end
		end
		local att = Instance.new("Attachment"); att.Name = "Centre"; att.Parent = chassis
		local lift = Instance.new("VectorForce"); lift.Name = "Float"; lift.Attachment0 = att; lift.RelativeTo = Enum.ActuatorRelativeTo.World
		lift.ApplyAtCenterOfMass = true; lift.Force = Vector3.zero; lift.Enabled = false; lift.Parent = chassis
	end
	place("trailer", BX, BZ - 23, 0.35, {spots = {{"OnTractor", 0.0, 5.3, 0.0, 0.35 + math.pi / 2}}})    -- parked by the barn; Toto rides in the hay
	place("hay_round", BX + 16, BZ - 18, 0.4); place("hay_round", BX + 21, BZ - 16, 1.1); place("hay_stack", BX + 12, BZ - 26, 0.2)
	local CX, CZ2 = 446, -70
	local coop = place("coop", CX, CZ2, 0.2, {spots = {{"InCoop", -1.8, 1.9, -3.3}}, precise = true})
	local coopO = coop and coop:GetAttribute("KitOrigin") or CFrame.new(CX, groundAt(CX, CZ2), CZ2) * CFrame.Angles(0, 0.2, 0)
	domaine:SetAttribute("HenRunPos", coopO.Position); domaine:SetAttribute("HenRunYaw", 0.2)
	if coop then
		-- the run's wire is too thin for the navmesh to see, so invisible pathfinding-only walls trace every fence segment
		-- (and the open gate leaf); nothing collides with them, the hens' paths just treat them as fence
		local segs = {{-6, -12, 6, -12}, {-6, -12, -6, -3}, {6, -12, 6, -8.7}, {6, -6.3, 6, -3}, {-6, -3, -4, -3}, {4, -3, 6, -3}}
		local function fence(cf, size)
			local f = Instance.new("Part"); f.Name = "HenFence"; f.Anchored = true; f.CanCollide = false; f.CanQuery = false; f.CanTouch = false
			f.Transparency = 1; f.Locked = true; f.Size = size; f.CFrame = cf; f.Parent = coop
			local pm = Instance.new("PathfindingModifier"); pm.PassThrough = false; pm.Parent = f
		end
		for _, sg in ipairs(segs) do
			local dx, dz = sg[3] - sg[1], sg[4] - sg[2]
			fence(coopO * CFrame.new((sg[1] + sg[3]) / 2, 1.4, (sg[2] + sg[4]) / 2), Vector3.new(math.max(math.abs(dx), 1.2) + 0.6, 2.8, math.max(math.abs(dz), 1.2) + 0.6))
		end
		local hinge, tip = Vector3.new(6.15, 1.4, -8.55), Vector3.new(6.15 + 0.94 * 2.1, 1.4, -8.55 - 0.34 * 2.1)
		fence(coopO * CFrame.lookAt((hinge + tip) / 2, tip), Vector3.new(1.2, 2.8, 2.4))
	end
	do                                                 -- a feed bin by the run; DomaineLife (below) makes the hens come running
		local base = coopO
		local bin = Instance.new("Part"); bin.Name = "FeedBin"; bin.Anchored = true; bin.Size = Vector3.new(1.5, 1.7, 1.5); bin.Color = C(176, 142, 96)
		bin.Material = Enum.Material.Fabric; bin.Locked = true; bin.CFrame = base * CFrame.new(10.2, 0.85, -3.6) * CFrame.Angles(0, 0.3, 0); bin.Parent = props      -- clear of the gateway
		local lid = Instance.new("Part"); lid.Name = "FeedGrain"; lid.Anchored = true; lid.Size = Vector3.new(1.2, 0.2, 1.2); lid.Color = C(232, 190, 92)
		lid.Material = Enum.Material.Sand; lid.Locked = true; lid.CFrame = bin.CFrame * CFrame.new(0, 0.8, 0); lid.Parent = bin
		local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Feed the hens"; prompt.ObjectText = "Feed bin"
		prompt.MaxActivationDistance = 8; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false; prompt.Parent = bin
	end
	for i = 1, 5 do
		local lx, lz, hyaw = rng:NextNumber(-4.5, 4.5), -5.5 - rng:NextNumber(0, 5), rng:NextNumber(0, 6.28)
		local hp = coopO * Vector3.new(lx, 0, lz)                                                  -- inside the run, in the coop's frame
		local hen = place("hen", hp.X, hp.Z, hyaw, {scale = rng:NextNumber(0.9, 1.1), tint = (i % 2 == 0) and {Hen = C(150, 96, 60)} or nil})
		if hen then
			hen:SetAttribute("Yaw", hyaw)
			for _, p in ipairs(hen:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
			-- a solid body: an invisible collider the height of a player's chest, so you bump into the bird rather than
			-- stepping onto its back; the navmesh ignores it so the hens do not wall each other in
			local o = hen:GetAttribute("KitOrigin")
			local col = Instance.new("Part"); col.Name = "HenCollider"; col.Anchored = true; col.CanCollide = true; col.CanQuery = true; col.CanTouch = false
			col.Transparency = 1; col.Locked = true; col.Size = Vector3.new(1.2, 3.4, 2.0)
			col.CFrame = (o or hen:GetPivot()) * CFrame.new(0, 1.7, -0.06); col.Parent = hen
			local pm = Instance.new("PathfindingModifier"); pm.PassThrough = true; pm.Parent = col
		end
	end
	place("sunflower_patch", 428, -104, 0.3, {spots = {{"OnSunflower", 0.2, 5.6, -2.6}}})
	place("sunflower_patch", 436, -98, 1.4); place("sunflower_patch", 424, -94, 2.6)
	place("scarecrow", 441, -96, 0.1, {spots = {{"OnScarecrow", 1.7, 5.9, 0.0}}})
	local trough = place("trough", 512, -72, 0.2, {spots = {{"InTrough", 0.0, 1.7, 0.0}}})
	if trough then                                     -- the pump: spout and hinge attachments plus a prompt on the handle (DomaineLife works it)
		local base = trough:GetAttribute("KitOrigin")
		local handle = trough:FindFirstChild("Handle")
		local iron = trough:FindFirstChild("Iron") or handle
		if iron then
			local spout = Instance.new("Attachment"); spout.Name = "Spout"; spout.Parent = iron
			spout.WorldCFrame = base * CFrame.new(2.6, 2.55, 0)
			local hinge = Instance.new("Attachment"); hinge.Name = "Hinge"; hinge.Parent = iron
			hinge.WorldCFrame = base * CFrame.new(3.6, 3.3, 0.1)
		end
		if handle then
			local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Pump water"; prompt.ObjectText = "Pump"
			prompt.MaxActivationDistance = 8; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false; prompt.UIOffset = Vector2.new(0, -64); prompt.Parent = handle
		end
	end
	place("olive_tree", 520, -95, 1.1, {scale = 1.25}); place("olive_tree", 470, -100, 2.0, {scale = 1.1})
	-- the windmill on its rise; the sails turn
	local WX, WZ = 588, -62
	local mill = place("windmill", WX, WZ, math.pi * 0.85, {precise = true})
	if mill then
		local sails = mill:FindFirstChild("Sails", true)
		if sails then
			sails.CanCollide = false
			local base = sails.CFrame
			local axis = base:VectorToObjectSpace(mill:GetPivot().LookVector)
			local scr = Instance.new("Script"); scr.Name = "TurnSails"
			scr.Source = [[
local sails = script.Parent
local base = sails.CFrame
local axis = script:GetAttribute("Axis") or Vector3.new(0, 0, 1)
local t = 0
-- a squirrel seated on the sail rides round with it
local rider, riderOffset
task.defer(function()
	task.wait(2)
	local spot = workspace:FindFirstChild("Domaine") and workspace.Domaine.HidingSpots:FindFirstChild("OnSail")
	local name = spot and spot:GetAttribute("Squirrel")
	local mdl = name and workspace:FindFirstChild(name)
	if mdl then rider = mdl; riderOffset = sails.CFrame:ToObjectSpace(mdl:GetPivot()) end
end)
game:GetService("RunService").Heartbeat:Connect(function(dt)
	t += dt * 0.35
	sails.CFrame = base * CFrame.fromAxisAngle(axis, t)
	if rider and rider.Parent then rider:PivotTo(sails.CFrame * riderOffset) end
end)]]
			scr:SetAttribute("Axis", axis)
			scr.Parent = sails
			-- Picnic Pierre rides a sail: an attachment on the sails part itself, so the squirrel turns with it
			local a = Instance.new("Attachment"); a.Name = "OnSail"; a.Parent = sails
			a.CFrame = CFrame.new(-6.0, 6.0, -0.9)
			spotAt("OnSail", (sails.CFrame * a.CFrame).Position.X, (sails.CFrame * a.CFrame).Position.Y, (sails.CFrame * a.CFrame).Position.Z, 0)
		end
	end
end
-- ---------------------------------------------------------------- 5a. the estate's edges: stone walls and cypress rows ----
do
	for _, x in ipairs({358, 370, 394, 406, 418, 430, 442, 454, 466, 478, 490, 502, 514, 526, 538, 550, 562, 574, 586, 598, 610, 622, 634, 646, 658, 670, 682, 694}) do
		place("stone_wall_b", x, -247, 0, {tilt = true, precise = true}); place("stone_wall_b", x, 27, 0, {tilt = true, precise = true})   -- x 382 skipped: it straddles the terrain's edge fade
	end
	place("cypress", 382, -246, 0.4, {scale = 1.1}); place("cypress", 382, 26, 1.1, {scale = 1.1})
	for z = -241, 21, 12 do place("stone_wall_b", 696, z, math.pi / 2, {tilt = true, precise = true}) end
	for z = -244, 24, 9 do place("cypress", 691, z, rng:NextNumber(0, 6.28), {scale = rng:NextNumber(0.95, 1.3)}) end
	for x = 362, 690, 16 do
		place("cypress", x, -242, rng:NextNumber(0, 6.28), {scale = rng:NextNumber(0.95, 1.25)})
		place("cypress", x, 22, rng:NextNumber(0, 6.28), {scale = rng:NextNumber(0.95, 1.25)})
	end
	for z = -246, -146, 9 do place("cypress", 357, z, rng:NextNumber(0, 6.28), {scale = rng:NextNumber(0.9, 1.2)}) end   -- fence line, south of the garden
	for z = -94, 26, 9 do place("cypress", 357, z, rng:NextNumber(0, 6.28), {scale = rng:NextNumber(0.9, 1.2)}) end       -- fence line, north of the garden
end
-- ---------------------------------------------------------------- 5b. life: wind, hens, pump, tractor ----
do
	local SRC = {
		Client = [=[@@CLIENT@@]=],
		Life = [=[@@LIFE@@]=],
		Drive = [=[@@DRIVE@@]=],
		DriveClient = [=[@@DRIVECLIENT@@]=],
		Garden = [=[@@GARDEN@@]=],
	}
	local function install(name, parent, ctx, src)
		local scr = Instance.new("Script"); scr.Name = name; scr.RunContext = ctx; scr.Source = src; scr.Parent = parent
	end
	install("DomaineClient", domaine, Enum.RunContext.Client, SRC.Client)
	install("DomaineLife", domaine, Enum.RunContext.Server, SRC.Life)
	install("GardenCans", domaine, Enum.RunContext.Server, SRC.Garden)
	for _, m in ipairs(props:GetChildren()) do
		if m.Name == "tractor" and m:FindFirstChild("Chassis") then
			install("TractorDrive", m, Enum.RunContext.Server, SRC.Drive)
			install("TractorClient", m, Enum.RunContext.Client, SRC.DriveClient)
		end
	end
end
print(string.format("DomaineBuilder: %d props, %d hiding spots", #placed, #spots:GetChildren()))
-- self-check: every prop's footprint centre must meet the ground it was placed on (reports anything hovering)
do
	local floaters = {}
	local chk = RaycastParams.new(); chk.FilterType = Enum.RaycastFilterType.Exclude
	for _, m in ipairs(placed) do
		if m:FindFirstChild("CellarFloor") then continue end            -- the cellar stands in carved-out terrain by design
		local bb, size = m:GetBoundingBox()
		local bottom = bb.Position - bb.UpVector * (size.Y / 2)
		local fnd = m:FindFirstChild("Foundation")
		if fnd then bottom = Vector3.new(bottom.X, fnd.Position.Y + fnd.Size.Y / 2 - 0.15, bottom.Z) end   -- judge the walls, not the buried course
		chk.FilterDescendantsInstances = {m, spots, kitFolder or m, workspace:FindFirstChild("Boundary") or m}
		local r = workspace:Raycast(bottom + Vector3.new(0, 0.5, 0), Vector3.new(0, -12, 0), chk)
		local gap = r and (bottom.Y - r.Position.Y) or 99
		if gap > 1.0 then table.insert(floaters, string.format("%s@%.0f,%.0f gap %.1f", m.Name, bb.Position.X, bb.Position.Z, gap)) end
	end
	if #floaters > 0 then warn("DomaineBuilder FLOAT CHECK: " .. table.concat(floaters, " | ")) else print("DomaineBuilder float check: all props grounded") end
end

-- ---------------------------------------------------------------- 6. the zone ----
local zones = workspace:FindFirstChild("Zones") or Instance.new("Folder")
zones.Name = "Zones"; zones.Parent = workspace
local z = zones:FindFirstChild(MAP_ID) or Instance.new("Part")
z.Name = MAP_ID; z.Anchored = true; z.CanCollide = false; z.CanQuery = false; z.CanTouch = false; z.Transparency = 1
z.Size = Vector3.new(700 - GX0, 2, 260); z.Position = Vector3.new((GX0 + 700) / 2, GY0 - 50, -110); z:SetAttribute("MapId", MAP_ID); z.Parent = zones

-- ---------------------------------------------------------------- 7. squirrels into the spots ----
if HIDE then
	local ss = workspace:FindFirstChild("SquirrelScripts", true)
	local reg = ss and ss:FindFirstChild("SquirrelRegistry")
	if reg then
		local R = require(reg:Clone())
		local BY_SPOT = {vintner_squirrel = "InBarrel", lavender_lucie = "InLavender", beekeeper_squirrel = "OnHive", farmer_fernand = "InLoft",
			scarecrow_squirrel = "OnScarecrow", tractor_toto = "OnTractor", sunflower_squirrel = "OnSunflower", grape_stomper_gigi = "InCrate",
			shepherd_squirrel = "InTrough", chevre_squirrel = "InWell", truffle_hunter = "InBelfry", picnic_pierre = "OnSail"}
		local n = 0
		for _, e in ipairs(R.squirrels) do
			if e.map == MAP_ID then
				local spot = spots:FindFirstChild(BY_SPOT[e.id] or "")
				for _, mdl in ipairs(workspace:GetChildren()) do
					if mdl:IsA("Model") and (mdl.Name == e.id .. "_color" or mdl.Name == e.id .. "_gray") and spot then
						local yaw = spot:GetAttribute("Face") or 0
						mdl:PivotTo(CFrame.new(spot.WorldPosition) * CFrame.Angles(0, yaw, 0))
						spot:SetAttribute("Squirrel", mdl.Name); n += 1
					end
				end
			end
		end
		print("DomaineBuilder: seated", n, "squirrel models")
	else
		warn("DomaineBuilder: SquirrelRegistry not found; squirrels left where they are")
	end
end
end

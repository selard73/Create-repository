"""VillageBuilder v3: see-through shop glass with a lit interior, window displays picked by shop (bakery, dress,
shelves, flowers, cafe, hats) placed behind each Glass<n> pane, per-part colours for dresses/hats/books/jars/icing,
brick door surrounds and wooden doors, and InWindow hiding spots."""
from pathlib import Path
p = Path(__file__).parent / "make_village_scripts.py"
s = p.read_text(encoding="utf-8")
def rep(old, new, count=1):
    global s
    assert s.count(old) == count, (s.count(old), old[:80])
    s = s.replace(old, new)

rep('''	"bollards", "shop_sign", "bench", "bicycle", "bridge", "plane_tree", "river", "pot", "crates"}''',
'''	"bollards", "shop_sign", "bench", "bicycle", "bridge", "plane_tree", "river", "pot", "crates",
	"disp_bakery", "disp_dress", "disp_shelves", "disp_flowers", "disp_cafe", "disp_hats"}''')

# ---- colours ----------------------------------------------------------------------------------------
rep('''	Shopfront = C(150, 140, 135), DoorShop = C(150, 140, 135), AwningStripe = C(232, 230, 226), Iron = C(70, 70, 72), Bread = C(190, 180, 165)}''',
'''	Shopfront = C(150, 140, 135), DoorShop = C(130, 120, 112), AwningStripe = C(232, 230, 226), Iron = C(70, 70, 72), Bread = C(190, 180, 165),
	Glass = C(200, 210, 218), Interior = C(225, 218, 205), Brass = C(200, 190, 160), Cake = C(240, 238, 232), Icing = C(220, 200, 205),
	Dress = C(200, 190, 195), Head = C(225, 215, 205), Jar = C(190, 170, 150), Box = C(160, 140, 125), Round = C(220, 205, 170),
	Book = C(170, 150, 150), Hat = C(90, 85, 82), Brick = C(165, 140, 130)}''')
rep('''	AwningStripe = C(250, 247, 240), Iron = C(45, 45, 50), Bread = C(226, 172, 92)}''',
'''	AwningStripe = C(250, 247, 240), Iron = C(45, 45, 50), Bread = C(226, 172, 92),
	Glass = C(205, 228, 240), Interior = C(238, 206, 160), Brass = C(218, 178, 88), Cake = C(250, 246, 236), Icing = C(240, 170, 190),
	Dress = C(230, 120, 140), Head = C(236, 216, 200), Jar = C(200, 140, 90), Box = C(154, 108, 78), Round = C(240, 208, 120),
	Book = C(200, 70, 70), Hat = C(60, 50, 45), Brick = C(152, 94, 78)}
local DRESSES = {C(230, 120, 140), C(120, 150, 210), C(240, 210, 120), C(150, 200, 150), C(200, 150, 220), C(245, 240, 232), C(90, 100, 140)}
local HATS = {C(60, 50, 45), C(200, 60, 70), C(230, 220, 200), C(70, 90, 140), C(120, 160, 120), C(170, 120, 80)}
local BOOKS = {C(200, 70, 70), C(70, 110, 180), C(90, 150, 100), C(230, 190, 80), C(120, 90, 160), C(240, 235, 220), C(60, 60, 70)}
local ICINGS = {C(240, 170, 190), C(250, 240, 225), C(200, 150, 110), C(170, 220, 190), C(240, 220, 140)}
local JARS = {
	FROMAGERIE = {C(240, 210, 120), C(250, 240, 210), C(230, 180, 90), C(200, 200, 150)},
	CHOCOLATIER = {C(90, 60, 45), C(140, 90, 60), C(200, 170, 140), C(220, 60, 80)},
	["NOISETTES & CIE"] = {C(190, 140, 90), C(150, 100, 60), C(220, 190, 150), C(120, 80, 50)},
	PARFUMERIE = {C(230, 190, 220), C(170, 200, 240), C(250, 240, 200), C(220, 150, 160)},
	default = {C(200, 90, 80), C(230, 190, 90), C(120, 160, 120), C(150, 180, 220), C(240, 230, 210)},
}''')

# ---- tinting: per-shop, per-part variety, glass, wood doors --------------------------------------------
rep('''local function tintModel(model, kitName, idx)''', '''local function tintModel(model, kitName, idx, shop)''')
rep('''	local shutter, canopy, flower = pick(SHUTTERS), pick(CANOPIES), pick(FLOWERS)''',
'''	local shutter, canopy = pick(SHUTTERS), pick(CANOPIES)
	local jars = (shop and JARS[shop]) or JARS.default''')
rep('''				elseif key == "Shopfront" or key == "DoorShop" then p.Color = shop
				elseif key == "Canopy" then p.Color = (kitName == "plane_tree") and C(110, 165, 95) or canopy
				elseif key == "Flower" then p.Color = flower
				elseif key and COLOR[key] then p.Color = COLOR[key] end''',
'''				elseif key == "Shopfront" then p.Color = shop
				elseif key == "DoorShop" then p.Color = C(112, 74, 46)
				elseif key == "Canopy" then p.Color = (kitName == "plane_tree") and C(110, 165, 95) or canopy
				elseif key == "Flower" then p.Color = pick(FLOWERS)
				elseif key == "Dress" then p.Color = pick(DRESSES)
				elseif key == "Hat" then p.Color = pick(HATS)
				elseif key == "Book" then p.Color = pick(BOOKS)
				elseif key == "Icing" then p.Color = pick(ICINGS)
				elseif key == "Jar" or key == "Round" or key == "Box" then p.Color = pick(jars)
				elseif key and COLOR[key] then p.Color = COLOR[key] end
				if key == "Glass" then p.Transparency = 0.45; p.Reflectance = 0.1; p.CanQuery = false; p.CastShadow = false end
				if key == "Brass" then p.Reflectance = 0.2 end''')

# ---- place(): shop + fixed height, displays turn like the houses ------------------------------------------
rep("local function place(kitName, x, z, yaw, scale, spotKinds, tint, idx)", "local function place(kitName, x, z, yaw, scale, spotKinds, tint, idx, shop, fixedY)")
rep("\tif tint ~= false then tintModel(model, kitName, idx) end", "\tif tint ~= false then tintModel(model, kitName, idx, shop) end")
rep("\tlocal gy = groundAt(x, z)\n\tif kitName == \"bridge\" then gy = GY end",
    "\tlocal gy = fixedY or groundAt(x, z)\n\tif kitName == \"bridge\" then gy = GY end")
rep('''	local modelYaw = yaw + ((kitName:find("townhouse") or kitName == "bench") and math.pi or 0)''',
    '''	local modelYaw = yaw + ((kitName:find("townhouse") or kitName == "bench" or kitName:sub(1, 5) == "disp_") and math.pi or 0)''')

# ---- rows: colours by shop, displays behind the glass, lights, InWindow spots --------------------------------
rep('''			local mdl = place(k, cx, cz, yaw, 1, {}, nil, nHouse)''',
'''			local shop = SHOPS[(nHouse - 1) % #SHOPS + 1]
			local mdl = place(k, cx, cz, yaw, 1, {}, nil, nHouse, shop)''')
rep('''			local shop = SHOPS[(nHouse - 1) % #SHOPS + 1]
			signText(mdl, shop, dz)''',
'''			signText(mdl, shop, dz)
			-- window displays behind every Glass<n> pane, lit, with a hiding spot in every other one
			local kit = displayFor(shop)
			for _, g in ipairs(mdl:GetDescendants()) do
				if g:IsA("BasePart") and g.Name:sub(1, 5) == "Glass" and g.Name:sub(1, 9) ~= "GlassDoor" and g.Size.X > 4 then
					local n = math.max(1, math.floor(g.Size.X / 6.2 + 0.3))
					local x0 = g.Position.X - g.Size.X / 2
					local floorY = g.Position.Y - g.Size.Y / 2 + 0.14
					local gz = g.Position.Z - dz * 2.8
					for i = 1, n do
						place(kit, x0 + g.Size.X * (i - 0.5) / n, gz, yaw, 1, {}, nil, nHouse, shop, floorY)
					end
					local lp = Instance.new("Part"); lp.Name = "DisplayLight"; lp.Anchored = true; lp.CanCollide = false; lp.CanQuery = false
					lp.Transparency = 1; lp.Size = Vector3.new(0.4, 0.4, 0.4)
					lp.Position = Vector3.new(g.Position.X, floorY + 5.2, g.Position.Z - dz * 2.0); lp.Parent = mdl
					local L = Instance.new("PointLight"); L.Range = 12; L.Brightness = 1.8; L.Color = C(255, 224, 176); L.Shadows = false; L.Parent = lp
					nWindow = (nWindow or 0) + 1
					if nWindow % 2 == 1 then
						local a = Instance.new("Attachment"); a.Name = "InWindow"; a.Parent = spots
						a.WorldCFrame = CFrame.new(x0 + rng:NextNumber(1.5, g.Size.X - 1.5), floorY, g.Position.Z - dz * 1.3) * CFrame.Angles(0, yaw, 0)
					end
				end
			end''')
rep('''local nHouse = 0
local function firstPart(model, prefix)''',
'''local nHouse = 0
local nWindow = 0
local DISPLAY = {BOULANGERIE = "disp_bakery", ["PÂTISSERIE"] = "disp_bakery", FLEURISTE = "disp_flowers", CHAPELIER = "disp_hats"}
local function displayFor(shop)
	if DISPLAY[shop] then return DISPLAY[shop] end
	if shop:find("CAF") or shop == "GLACES" then return "disp_cafe" end
	if shop:find("MODE") then return "disp_dress" end
	return "disp_shelves"
end
local function firstPart(model, prefix)''')
rep('''		local rank = {InFountain = 1, UnderTable = 2, UnderBridge = 3, UnderHedge = 4, InTree = 5, BehindPlanter = 6, OnAwning = 7, InDoorway = 8, OnBench = 9, BesideBike = 10, ByLamp = 11}''',
    '''		local rank = {InWindow = 1, InFountain = 2, UnderTable = 3, UnderBridge = 4, UnderHedge = 5, InTree = 6, BehindPlanter = 7, OnAwning = 8, InDoorway = 9, OnBench = 10, BesideBike = 11, ByLamp = 12}''')
p.write_text(s, encoding="utf-8"); print("builder v3 patched")

"""VillageBuilder for the human-scale shop-house kit: pastel palette per building, shop signs (SurfaceGui text),
crates / pots / tables outside each shop according to what it sells, plots under the buildings so doors sit at
sidewalk level, bigger trees and fountain, hedges sized to the new walls."""
from pathlib import Path
p = Path(__file__).parent / "make_village_scripts.py"
s = p.read_text(encoding="utf-8")
def rep(old, new, count=1):
    global s
    assert s.count(old) == count, (s.count(old), old[:80])
    s = s.replace(old, new)

rep('''local KIT = {"townhouse_a", "townhouse_b", "townhouse_c", "cafe_table", "parasol", "lamp_post", "planter", "fountain",
	"bollards", "shop_sign", "bench", "bicycle", "bridge", "plane_tree", "river"}''',
'''local KIT = {"townhouse_a", "townhouse_b", "townhouse_c", "cafe_table", "parasol", "lamp_post", "planter", "fountain",
	"bollards", "shop_sign", "bench", "bicycle", "bridge", "plane_tree", "river", "pot", "crates"}''')

# ---- palette + tinting -------------------------------------------------------------------------
old_start = s.index("local WALLS = {")
old_end = s.index("for _, t in pairs(templates) do\n\tfor _, p in ipairs(t:GetDescendants()) do if p:IsA(\"BasePart\") then p.Anchored = true; p.Transparency = 1")
s = s[:old_start] + '''local WALLS = {C(247, 236, 205), C(242, 205, 205), C(203, 218, 238), C(246, 228, 170), C(210, 228, 200), C(226, 210, 236), C(250, 222, 198)}
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
	Shopfront = C(150, 140, 135), DoorShop = C(150, 140, 135), AwningStripe = C(232, 230, 226), Iron = C(70, 70, 72), Bread = C(190, 180, 165)}
local COLOR = {Roof = C(200, 120, 95), Door = C(120, 85, 60), Window = C(140, 160, 190), Trim = C(250, 247, 238), Chimney = C(170, 150, 140),
	Table = C(70, 60, 55), Chair = C(150, 115, 80), Pole = C(70, 60, 55), Post = C(45, 70, 60), Lantern = C(255, 240, 190), Planter = C(180, 110, 85),
	Leaf = C(100, 160, 90), Stone = C(190, 185, 175), Water = C(120, 190, 220), Sign = C(58, 46, 40), Bench = C(140, 110, 85), Frame = C(70, 90, 140),
	Wheel = C(50, 50, 50), Plank = C(160, 120, 85), Rail = C(130, 100, 75), Trunk = C(110, 85, 60), Bank = C(196, 176, 136),
	AwningStripe = C(250, 247, 240), Iron = C(45, 45, 50), Bread = C(226, 172, 92)}
local function pick(t) return t[rng:NextInteger(1, #t)] end
local function tintModel(model, kitName, idx)
	-- buildings get their colours from their position in the row so neighbours never match
	local function at(t, i) return idx and t[(i - 1) % #t + 1] or pick(t) end
	local wall, shop, awning = at(WALLS, idx or 1), at(SHOPFRONTS, (idx or 1) * 2 + 1), at(AWNINGS, (idx or 1) + 2)
	local shutter, canopy, flower = pick(SHUTTERS), pick(CANOPIES), pick(FLOWERS)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true; p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			local key
			for k in pairs(GRAY) do if p.Name:sub(1, #k) == k and (not key or #k > #key) then key = k end end
			if PALETTE == "color" then
				if key == "Wall" then p.Color = wall elseif key == "Shutter" then p.Color = shutter elseif key == "Awning" then p.Color = awning
				elseif key == "Shopfront" or key == "DoorShop" then p.Color = shop
				elseif key == "Canopy" then p.Color = (kitName == "plane_tree") and C(110, 165, 95) or canopy
				elseif key == "Flower" then p.Color = flower
				elseif key and COLOR[key] then p.Color = COLOR[key] end
				if key == "Water" then p.Material = Enum.Material.SmoothPlastic; p.Color = (kitName == "river") and C(74, 146, 178) or p.Color; p.Transparency = (kitName == "river") and 0.05 or 0.25; p.Reflectance = 0.12 end
				if key == "Bank" then p.Material = Enum.Material.Sand end
				if key == "Lantern" then p.Material = Enum.Material.Neon; p.Color = C(255, 236, 170) end
				if key == "Window" then p.Reflectance = 0.08 end
			elseif key then p.Color = GRAY[key] end
		end
	end
end
''' + s[old_end:]

# ---- ground: wider sidewalks and plots under the building rows ---------------------------------
rep("local STREET_W, WALK_W = 22, 7", "local STREET_W, WALK_W = 22, 9\nlocal HOUSE_D = 26                 -- shop-house depth (gen_village.py DEPTH)")
rep('''local SQ = 46      -- square width, cut into the north row''',
'''-- plots the buildings stand on, level with the sidewalk, so every door sits at pavement height
slab("PlotN", CX, CZ + STREET_W / 2 + WALK_W + HOUSE_D / 2 + 2, LEN, HOUSE_D + 4, GY, 0.5, PALETTE == "color" and C(205, 200, 190) or C(205, 204, 200), Enum.Material.Concrete)
slab("PlotS", CX, CZ - STREET_W / 2 - WALK_W - HOUSE_D / 2 - 2, LEN, HOUSE_D + 4, GY, 0.5, PALETTE == "color" and C(205, 200, 190) or C(205, 204, 200), Enum.Material.Concrete)
local SQ = 46      -- square width, cut into the north row''')

# ---- place(): pass the building index to the tinting ---------------------------------------------
rep("local function place(kitName, x, z, yaw, scale, spotKinds, tint)", "local function place(kitName, x, z, yaw, scale, spotKinds, tint, idx)")
rep("\tif tint ~= false then tintModel(model, kitName) end", "\tif tint ~= false then tintModel(model, kitName, idx) end")

# ---- the rows ------------------------------------------------------------------------------------
r0 = s.index("-- 1. townhouses along both sides")
r1 = s.index("row(frontS, math.pi, false)\n") + len("row(frontS, math.pi, false)\n")
s = s[:r0] + r'''-- 1. shop-houses along both sides (north row faces -Z toward the street; south row is turned around)
local kinds = {"townhouse_a", "townhouse_b", "townhouse_c"}
local widths = {townhouse_a = 28, townhouse_b = 22, townhouse_c = 34}
local SHOPS = {"BOULANGERIE", "CAFÉ DE L'ÉCUREUIL", "MODE ET STYLE", "FLEURISTE", "PÂTISSERIE", "FROMAGERIE", "NOISETTES & CIE",
	"LIBRAIRIE", "CHOCOLATIER", "GLACES", "CHAPELIER", "ÉPICERIE", "CAFÉ LUNA", "BOULANGERIE", "PARFUMERIE", "MODE ET ROBES"}
local frontN = CZ + STREET_W / 2 + WALK_W           -- building fronts sit at the back of the sidewalk
local frontS = CZ - STREET_W / 2 - WALK_W
local cafes = {}
local ends = {}          -- exposed side walls: {x = wall x, cz = building centre z, out = -1 or 1}
local nHouse = 0
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
		local k = pick(kinds); local w = widths[k]
		if x + w > CX + LEN / 2 - 1 then break end
		local cx = x + w / 2
		local inSquare = skipSquare and (cx + w / 2 > CX - SQ / 2 - 1) and (cx - w / 2 < CX + SQ / 2 + 1)
		if inSquare then
			x = CX + SQ / 2 + 1
		else
			nHouse += 1
			local cz = front - dz * HOUSE_D / 2
			local mdl = place(k, cx, cz, yaw, 1, {}, nil, nHouse)
			-- the footprint was centred by bounding box (awning included); slide it so the wall meets the sidewalk
			local doorP = firstPart(mdl, "DoorShop")
			if doorP then
				local face = doorP.Position.Z + dz * doorP.Size.Z / 2
				mdl:PivotTo(mdl:GetPivot() + Vector3.new(0, 0, (front + dz * 0.45) - face))
			end
			if not first then first = {x = cx - w / 2, cz = cz, out = -1} end
			last = {x = cx + w / 2, cz = cz, out = 1}
			local shop = SHOPS[(nHouse - 1) % #SHOPS + 1]
			signText(mdl, shop, dz)
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
			-- what stands outside depends on the shop
			local wallZ = front + dz * 1.5
			if shop:find("CAF") then
				table.insert(cafes, {x = cx, z = front + dz * 3.8, yaw = yaw, doorX = doorX})
			elseif shop == "BOULANGERIE" or shop == "PÂTISSERIE" then
				place("crates", doorX - 3.4, wallZ, yaw, 1, {})
				place("crates", doorX + 3.4, wallZ, yaw, 1, {})
			elseif shop == "FLEURISTE" then
				place("planter", doorX + 4.4, wallZ, yaw, 1, {"BehindPlanter"})
				place("pot", doorX - 3.0, wallZ, yaw, 1, {})
				place("pot", doorX - 4.9, wallZ, yaw, 0.85, {})
			else
				place("pot", doorX + 3.0, wallZ, yaw, 1, {})
				if nHouse % 3 == 0 then
					place("bicycle", doorX - 5.5, wallZ, yaw, 0.85, {"BesideBike"})
				elseif nHouse % 3 == 1 then
					place("shop_sign", cx + ((cx > doorX) and 1 or -1) * (w / 2 - 2.2), front + dz * 1.4, yaw, 1, {})
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
''' + s[r1:]

# ---- hedges sized to the new walls ---------------------------------------------------------------
rep("\t\tfor _, dz in ipairs({-4.4, -1.5, 1.5, 4.4}) do", "\t\tfor _, dz in ipairs({-9.6, -3.2, 3.2, 9.6}) do")
rep("\t\t\tlocal sc = rng:NextNumber(0.9, 1.15); mdl:ScaleTo(sc)\n\t\t\tlocal x, z = e.x + e.out * 1.6, e.cz + dz",
    "\t\t\tlocal sc = rng:NextNumber(1.25, 1.55); mdl:ScaleTo(sc)\n\t\t\tlocal x, z = e.x + e.out * 2.1, e.cz + dz")
rep("\t\ta.WorldCFrame = CFrame.new(e.x + e.out * 1.6, groundAt(e.x, e.cz), e.cz)", "\t\ta.WorldCFrame = CFrame.new(e.x + e.out * 2.1, groundAt(e.x, e.cz), e.cz)")
# riverside trees
rep('local mdl = place("plane_tree", x + side * 4, z, rng:NextNumber(0, 6.28), rng:NextNumber(0.8, 1.05), {"InTree"})',
    'local mdl = place("plane_tree", x + side * 4, z, rng:NextNumber(0, 6.28), rng:NextNumber(1.5, 1.9), {"InTree"})')

# ---- the square ----------------------------------------------------------------------------------
rep('''place("fountain", CX, sqZ, 0, 1, {"InFountain"})
for _, dx in ipairs({-17, 17}) do
	place("plane_tree", CX + dx, sqZ + 6, rng:NextNumber(0, 6.28), rng:NextNumber(0.9, 1.1), {"InTree"})
	place("bench", CX + dx, sqZ - 8, math.pi, 1, {"OnBench"})
end
place("bench", CX, sqZ + 11, math.pi, 1, {"OnBench"})''',
'''place("fountain", CX, sqZ, 0, 1.4, {"InFountain"})
for _, dx in ipairs({-17, 17}) do
	place("plane_tree", CX + dx, sqZ + 6, rng:NextNumber(0, 6.28), rng:NextNumber(1.7, 2.0), {"InTree"})
	place("bench", CX + dx, sqZ - 8, math.pi, 1, {"OnBench"})
	-- a parasol table on each side of the fountain
	place("cafe_table", CX + dx * 0.55, sqZ + 11, math.pi / 2, 1, {"UnderTable"})
	place("parasol", CX + dx * 0.55, sqZ + 11, 0, 1, {})
end
place("bench", CX, sqZ + 12, math.pi, 1, {"OnBench"})''')

# ---- cafés: two tables under the awning, clear of the door -----------------------------------------
rep('''-- 3. cafes: two tables (chairs along the wall) near the curb, one parasol standing between them
for _, cafe in ipairs(cafes) do
	for _, j in ipairs({-1, 1}) do
		place("cafe_table", cafe.x + j * 3.6, cafe.z, cafe.yaw + math.pi / 2, 0.95, {"UnderTable"})
	end
	place("parasol", cafe.x, cafe.z, 0, 1, {})
end''',
'''-- 3. cafés: two tables (chairs along the wall) under the awning, kept clear of the door
for _, cafe in ipairs(cafes) do
	for _, j in ipairs({-1, 1}) do
		local tx = cafe.x + j * 5.2
		if math.abs(tx - cafe.doorX) < 4.4 then tx = tx + j * 3.8 end
		place("cafe_table", tx, cafe.z, cafe.yaw + math.pi / 2, 1, {"UnderTable"})
	end
end''')

# ---- lamps, zone -----------------------------------------------------------------------------------
rep('''for x = CX - LEN / 2 + 14, CX + LEN / 2 - 14, 32 do
	place("lamp_post", x, CZ + STREET_W / 2 + 1.2, 0, 1, {"ByLamp"})
	place("lamp_post", x + 16, CZ - STREET_W / 2 - 1.2, math.pi, 1, {"ByLamp"})
end''',
'''for x = CX - LEN / 2 + 14, CX + LEN / 2 - 14, 36 do
	place("lamp_post", x, CZ + STREET_W / 2 + 1.2, 0, 1.1, {"ByLamp"})
	place("lamp_post", x + 18, CZ - STREET_W / 2 - 1.2, math.pi, 1.1, {"ByLamp"})
end''')
rep("zone(MAP_ID, CX, CZ, LEN + 20, 90)", "zone(MAP_ID, CX, CZ, LEN + 20, 140)")
p.write_text(s, encoding="utf-8"); print("builder v2 patched")

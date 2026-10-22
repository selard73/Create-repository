-- shelf1 (Oct 22 2026): the trophy shelf in your treehouse. Shannon: "2 types of book shelves (2 styles to pick from) where
-- we will store souvenirs and trophies like a little keeper of the great acorn award and an award for saving the baby
-- squirrels from the croc" + the trophies she made herself in Meshy (the acorn "needs some sort of plaque on it", the key
-- "needs a kind of stand and and a plaque of what it is", the cup "for the save the baby squirrels award"). Previewed in
-- play tests on both styles and approved: "Install the trophy shelf with my three trophies, both shelf styles and the Shelf
-- rows in the Treehouse tab, with backups."
--   workspace.Treehouse.ShelfClient (new, RunContext Client): the shelf on the left wall (the bookcase by default, or the
--     plank ledges), books and a plant, and each trophy once earned: her models from ReplicatedStorage.TrophyModels
--     (Acorn, Key, Rescue - already there, moved in from her imports).
--   DecorServer: "shelf" bookcase / planks / store (Item_shelfon_planks, Item_shelf_bare), through RS.AwardItems.
--   DecorClient: the SHELF rows (two styles, Place / Store) between the rugs and the wall; the subtitle mentions it.
-- Run in Studio EDIT. Backs DecorServer and DecorClient up to ServerStorage.HudBackup (<name>_pre_shelf1) first.
local SES = game:GetService("ScriptEditorService")
local RS = game:GetService("ReplicatedStorage")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
assert(not workspace.Treehouse:FindFirstChild("ShelfClient"), "ShelfClient already exists - nothing changed")
local tm = RS:FindFirstChild("TrophyModels")
assert(tm and tm:FindFirstChild("Acorn") and tm:FindFirstChild("Key") and tm:FindFirstChild("Rescue"), "ReplicatedStorage.TrophyModels is missing a trophy - nothing changed")
local function patched(script, edits)
	local src = script.Source
	assert(not src:find("(shelf1", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	return src
end
local ds = workspace.Treehouse.DecorServer
local dsSrc = patched(ds, {
	{[==[	elseif what == "wall" then]==],
	 [==[	elseif what == "shelf" then                                  -- (shelf1) the trophy shelf: the bookcase (the default), the plank ledges, or stored
		if id ~= "bookcase" and id ~= "planks" and id ~= "store" then return false, "no such shelf" end
		if (tonumber(p:GetAttribute("Item_shelfon_planks")) or 0) > 0 then award:Fire(p, "shelfon_planks", -1) end
		if (tonumber(p:GetAttribute("Item_shelf_bare")) or 0) > 0 then award:Fire(p, "shelf_bare", -1) end
		if id == "planks" then award:Fire(p, "shelfon_planks", 1) elseif id == "store" then award:Fire(p, "shelf_bare", 1) end
		return true
	elseif what == "wall" then]==], "the wall action"},
})
local dc = workspace.Treehouse.DecorClient
local dcSrc = patched(dc, {
	{[==[label("Place a rug, hang your portrait, or store them for later.", 3, 24, 420, 16, 13, C(110, 70, 30), Enum.Font.BuilderSans)   -- (wall1)]==],
	 [==[label("Place a rug and a shelf, hang your portrait, or store them for later.", 3, 24, 460, 16, 13, C(110, 70, 30), Enum.Font.BuilderSans)   -- (wall1, shelf1)]==], "the subtitle"},
	{[==[local wy = 72 + #RUGS * 60 + 6]==],
	 [==[-- (shelf1, Oct 22 2026) SHELF - the trophy shelf on the left wall (ShelfClient; Shannon: "2 types of book shelves (2 styles
-- to pick from)"): the bookcase (the default) or the plank ledges, or stored. Your trophies stand on it once earned.
local SHELVES = {
	{id = "bookcase", name = "Bookcase", wood = C(150, 108, 62)},
	{id = "planks", name = "Plank Ledges", wood = C(184, 140, 90)},
}
local function shelfOn()
	if (tonumber(player:GetAttribute("Item_shelf_bare")) or 0) >= 1 then return nil end
	if (tonumber(player:GetAttribute("Item_shelfon_planks")) or 0) >= 1 then return "planks" end
	return "bookcase"
end
local shelfRows = {}
local function refreshShelf()
	local on = shelfOn()
	for id, r in pairs(shelfRows) do
		r.tag.Text = (id == on) and "On the wall" or "Stored"
		r.tag.TextColor3 = (id == on) and C(64, 112, 48) or MUTED
		r.btn.Text = (id == on) and "Store" or "Place"
		r.btn.BackgroundColor3 = (id == on) and C(236, 226, 206) or C(245, 170, 60)
	end
end
local sy = 72 + #RUGS * 60 + 6
label("SHELF", 3, sy, 100, 14, 12, MUTED)
for i, s in ipairs(SHELVES) do
	local r, nm, tag, b = row("Shelf_" .. s.id, sy + 20 + (i - 1) * 60, 86)
	nm.Text = s.name
	local icon = Instance.new("Frame"); icon.Position = UDim2.fromOffset(10, 6); icon.Size = UDim2.fromOffset(34, 40)   -- a little picture of the style
	icon.BackgroundColor3 = (s.id == "bookcase") and C(70, 48, 30) or C(236, 226, 206); icon.BorderSizePixel = 0; icon.ZIndex = 5; icon.Parent = r
	round(icon, 4)
	if s.id == "bookcase" then local st = Instance.new("UIStroke"); st.Color = s.wood; st.Thickness = 3; st.Parent = icon end
	for k = 1, 3 do
		local bar = Instance.new("Frame"); bar.BorderSizePixel = 0; bar.BackgroundColor3 = s.wood; bar.ZIndex = 6
		bar.Position = UDim2.fromOffset((s.id == "bookcase") and 0 or 2, 8 + (k - 1) * 12)
		bar.Size = UDim2.new(1, (s.id == "bookcase") and 0 or -4, 0, 3); bar.Parent = icon
	end
	shelfRows[s.id] = {tag = tag, btn = b}
	b.Activated:Connect(function()
		if busy then return end
		busy = true
		pcall(function() act:InvokeServer("shelf", (shelfOn() == s.id) and "store" or s.id) end)
		task.wait(0.2)
		busy = false
		refreshShelf()
	end)
end
player.AttributeChanged:Connect(function(name)
	if name == "Item_shelf_bare" or name == "Item_shelfon_planks" then refreshShelf() end
end)
refreshShelf()
local wy = sy + 20 + #SHELVES * 60 + 6]==], "the wall heading's place"},
})
for _, s in ipairs({ds, dc}) do
	local b = s:Clone(); b.Name = s.Name .. "_pre_shelf1"; b.Enabled = false; b.Parent = backup
end
SES:UpdateSourceAsync(ds, function() return dsSrc end)
SES:UpdateSourceAsync(dc, function() return dcSrc end)
local sc = Instance.new("Script"); sc.Name = "ShelfClient"; sc.RunContext = Enum.RunContext.Client; sc.Parent = workspace.Treehouse
SES:UpdateSourceAsync(sc, function() return [==[
-- ShelfClient (workspace.Treehouse, RunContext Client; shelf1, Oct 22 2026): the trophy shelf in your treehouse. Shannon:
-- "2 types of book shelves (2 styles to pick from) where we will store souvenirs and trophies like a little keeper of the
-- great acorn award and an award for saving the baby squirrels from the croc; it might be a little tricky placing them
-- since there is not a lot of wall space" + "the keeper could just be a golden acorn with a plaque and the guardian of the
-- harbour could just be a golden key with a plaque".
-- The one clear stretch of wall: the left wall between the back corner and the window (house frame x -9.3, z -8.7..-2.1),
-- nothing in front of it. Two styles: a bookcase like the village bookshop's, or rustic plank ledges on brackets in the
-- treehouse's honey wood. Books and a plant always; each trophy only once it is earned:
--   Keeper of the Great Acorn - her gold acorn trophy on a walnut base with a plaque     Item_passport_keeper / ChampionNo
--   Swamp Rescue              - her gold cup with the croc plaque (Margaux's babies)     Item_croc_rescues
--   Guardian of the Harbour   - her gold key in a walnut stand with a plaque             PortoKeeperTitle
-- Drawn on this screen only, like the house. Style: Item_shelfon_planks = the plank ledges, Item_shelf_bare = stored
-- (DecorClient's SHELF rows), nothing = the bookcase.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local TH = script.Parent
local function J(name)
	local ok, t = pcall(function() return HttpService:JSONDecode(TH:GetAttribute(name) or "") end)
	return (ok and type(t) == "table") and t or nil
end
local TREE, PIECES = J("Tree"), J("Pieces") or {}
if not (TREE and tonumber(TREE.x) and tonumber(TREE.y) and tonumber(TREE.z)) then return end
local base = CFrame.new(TREE.x, TREE.y, TREE.z) * CFrame.Angles(0, math.rad(tonumber(TREE.yaw) or 0), 0)   -- TreehouseClient's frame: +z faces the spawn
local WALLS = math.max(4, math.round(#PIECES * 0.58))            -- (TreehouseClient's STAGES.walls)
local function item(id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function roomUp()
	local n = 0
	for _, pc in ipairs(PIECES) do if item("tree_" .. tostring(pc.id)) >= 1 then n += 1 end end
	return n >= WALLS
end
-- the shelf's own frame: on the floor (y 10.5) against the left wall's inner face, +z out into the room, +x to the right
-- as you face it (towards the back wall)
local F0 = base * CFrame.new(-9.3, 10.5, -5.4) * CFrame.Angles(0, math.rad(90), 0)
local C = Color3.fromRGB
local WOOD, WOOD_DARK, HONEY, BACK = C(150, 108, 62), C(104, 70, 40), C(184, 140, 90), C(70, 48, 30)
local GOLD, GOLD_D, GOLD_DD, BRASS, INK = C(255, 206, 64), C(214, 160, 44), C(190, 136, 40), C(190, 146, 44), C(60, 40, 16)
local SPINES = {C(70, 70, 76), C(220, 110, 60), C(200, 150, 60), C(46, 92, 140), C(58, 120, 72), C(160, 48, 44), C(232, 214, 176), C(120, 70, 130)}

local function part(size, colour, cf, parent, material, shape, collide)
	local p = Instance.new("Part"); p.Size = size; p.Color = colour; p.Material = material or Enum.Material.Wood
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.CFrame = cf; p.Parent = parent
	return p
end
local function gold(p, shade) p.Material = Enum.Material.Metal; p.Color = shade or GOLD; p.Reflectance = 0.2; return p end
local ROT_UP = CFrame.Angles(0, 0, math.rad(90))                 -- (a Cylinder's axis is X: this stands it up)

-- ---------- the trophies (each stands with its bottom centre at cf, facing +z) ----------
-- (Shannon on the first ones: blocky, too big, the gold wrong - then she made the three herself in Meshy) her models in
-- RS.TrophyModels (Acorn, Key, Rescue: gold with their own metal finish), about 0.8 tall; the acorn on a slim walnut base
-- with a brass plaque, the key slotted into a walnut stand with a brass keyhole plate and a plaque ("it needs a kind of
-- stand and a plaque of what it is"), the rescue cup on its own base and engraved plaque
local function plinth(parent, cf, words)
	part(Vector3.new(0.62, 0.16, 0.42), C(74, 48, 30), cf * CFrame.new(0, 0.08, 0), parent, Enum.Material.Wood)
	local plate = gold(part(Vector3.new(0.5, 0.11, 0.02), BRASS, cf * CFrame.new(0, 0.08, 0.215), parent), BRASS)
	plate.Reflectance = 0.05
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Back; sg.CanvasSize = Vector2.new(300, 66); sg.LightInfluence = 0.7; sg.Parent = plate
	local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -12, 1, -8); t.Position = UDim2.fromOffset(6, 4); t.BackgroundTransparency = 1
	t.Font = Enum.Font.Antique; t.TextScaled = true; t.TextWrapped = true; t.TextColor3 = INK; t.Text = words; t.Parent = sg
	return cf * CFrame.new(0, 0.16, 0)                            -- the base's top
end
local function model(parent, top, name, height, sink, yaw)         -- one of her models, standing on top, facing +z (turned by yaw degrees)
	local src = RS:FindFirstChild("TrophyModels") and RS.TrophyModels:FindFirstChild(name)
	if not src then return end
	local m = src:Clone()
	m.Anchored = true; m.CanCollide = false; m.CanQuery = false; m.CanTouch = false
	m.Size = m.Size * (height / m.Size.Y)
	m.CFrame = top * CFrame.new(0, m.Size.Y / 2 - (sink or 0), 0) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	m.Parent = parent
end
local function acornTrophy(parent, cf) model(parent, plinth(parent, cf, "KEEPER OF THE GREAT ACORN"), "Acorn", 0.8) end
local function rescueTrophy(parent, cf) model(parent, cf, "Rescue", 0.85, 0, 180) end   -- (turned: its engraved squirrel-and-croc plaque faces you)
local function keyTrophy(parent, cf)
	local top = plinth(parent, cf, "GUARDIAN OF THE HARBOUR")
	gold(part(Vector3.new(0.025, 0.16, 0.16), BRASS, top * CFrame.new(0, 0.0125, 0) * ROT_UP, parent, nil, Enum.PartType.Cylinder), BRASS)   -- the keyhole plate
	model(parent, top, "Key", 0.8, 0.02)                           -- (its tip just into the stand)
end

-- ---------- books, a plant ----------
local rng = Random.new(player.UserId)                             -- (your own books: the same every visit)
local function bookRow(parent, cf, width, maxH, depth)            -- cf = the row's left end on the shelf top
	local x = 0
	while x < width - 0.3 do
		local w = rng:NextNumber(0.2, 0.34)
		local h = rng:NextNumber(maxH * 0.72, maxH)
		local lean = (rng:NextNumber() < 0.12 and x > 0.5) and math.rad(rng:NextNumber(8, 14)) or 0
		local c = SPINES[rng:NextInteger(1, #SPINES)]
		part(Vector3.new(w, h, depth), c, cf * CFrame.new(x + w / 2, h / 2, 0) * CFrame.Angles(0, 0, -lean), parent, Enum.Material.SmoothPlastic)
		x += w + (lean > 0 and 0.12 or 0.01)
	end
end
local function bookStack(parent, cf, n)                           -- books lying flat
	local y = 0
	for i = 1, n do
		local h = rng:NextNumber(0.12, 0.18)
		part(Vector3.new(rng:NextNumber(0.8, 1.0), h, rng:NextNumber(0.55, 0.7)), SPINES[rng:NextInteger(1, #SPINES)],
			cf * CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, math.rad(rng:NextNumber(-8, 8)), 0), parent, Enum.Material.SmoothPlastic)
		y += h
	end
end
local function plant(parent, cf)                                  -- the potted plant like the one under the window
	part(Vector3.new(0.5, 0.45, 0.5), C(178, 96, 62), cf * CFrame.new(0, 0.225, 0), parent, Enum.Material.SmoothPlastic)
	part(Vector3.new(0.7, 0.62, 0.7), C(92, 150, 70), cf * CFrame.new(0, 0.72, 0), parent, Enum.Material.Grass)
end

-- ---------- the two shelves ----------
-- the trophies' places on each, left to right as you face the shelf: the acorn, the rescue award, the key
local TROPHIES = {
	{id = "keeper", build = acornTrophy, earned = function() return item("passport_keeper") >= 1 or (tonumber(player:GetAttribute("ChampionNo")) or 0) > 0 end},
	{id = "rescue", build = rescueTrophy, earned = function() return item("croc_rescues") >= 1 end},
	{id = "guardian", build = keyTrophy, earned = function() return player:GetAttribute("PortoKeeperTitle") ~= nil end},
}
local function trophiesOn(parent, cf, spacing)                    -- cf = the middle of the trophy shelf's top; the earned ones, centred
	local got = {}
	for _, t in ipairs(TROPHIES) do if t.earned() then table.insert(got, t) end end
	for i, t in ipairs(got) do t.build(parent, cf * CFrame.new((i - (#got + 1) / 2) * spacing, 0, 0)) end
end
local function bookcase(parent)                                    -- like the village bookshop's: 4.6 wide, 6.6 tall
	local W, H, D = 4.6, 6.6, 1.15
	part(Vector3.new(W, H, 0.1), BACK, F0 * CFrame.new(0, H / 2, 0.05), parent, Enum.Material.Wood, nil, true)
	for _, sx in ipairs({-1, 1}) do part(Vector3.new(0.25, H, D), WOOD, F0 * CFrame.new(sx * (W / 2 - 0.125), H / 2, D / 2), parent, Enum.Material.Wood, nil, true) end
	part(Vector3.new(W + 0.3, 0.28, D + 0.15), WOOD_DARK, F0 * CFrame.new(0, H + 0.14, (D + 0.15) / 2), parent, Enum.Material.Wood, nil, true)   -- the crown
	part(Vector3.new(W, 0.4, D), WOOD_DARK, F0 * CFrame.new(0, 0.2, D / 2), parent, Enum.Material.Wood, nil, true)                          -- the plinth
	local inner = W - 0.5
	local floors = {0.4}
	for _, y in ipairs({2.0, 3.6, 5.1}) do
		part(Vector3.new(inner, 0.16, D - 0.1), WOOD, F0 * CFrame.new(0, y - 0.08, (D - 0.1) / 2 + 0.1), parent, Enum.Material.Wood)
		table.insert(floors, y)
	end
	bookRow(parent, F0 * CFrame.new(-inner / 2 + 0.05, floors[1], 0.55), inner - 0.1, 1.4, 0.85)
	bookRow(parent, F0 * CFrame.new(-inner / 2 + 0.05, floors[2], 0.55), inner - 1.0, 1.35, 0.85)
	bookStack(parent, F0 * CFrame.new(inner / 2 - 0.55, floors[2], 0.55), 3)
	trophiesOn(parent, F0 * CFrame.new(0, floors[3], 0.62), 1.32)  -- (eye height)
	plant(parent, F0 * CFrame.new(-1.4, floors[4], 0.6))
	bookStack(parent, F0 * CFrame.new(1.3, floors[4], 0.6), 4)
	local glow = part(Vector3.new(0.2, 0.05, 0.2), WOOD_DARK, F0 * CFrame.new(0, H - 0.05, D - 0.2), parent)   -- a warm little light under the crown
	local l = Instance.new("PointLight"); l.Color = C(255, 214, 160); l.Range = 7; l.Brightness = 0.7; l.Shadows = false; l.Parent = glow
end
local function planks(parent)                                      -- three honey planks on dark brackets, staggered a little
	local W, D, T = 4.6, 1.0, 0.18
	local rows = {{y = 2.4, dx = -0.2}, {y = 3.9, dx = 0.2}, {y = 5.4, dx = -0.1}}
	for _, r in ipairs(rows) do
		part(Vector3.new(W, T, D), HONEY, F0 * CFrame.new(r.dx, r.y - T / 2, D / 2), parent, Enum.Material.WoodPlanks, nil, true)
		for _, sx in ipairs({-1, 1}) do                            -- an L bracket and its brace under each end
			local bx = r.dx + sx * (W / 2 - 0.5)
			part(Vector3.new(0.12, 0.62, 0.1), WOOD_DARK, F0 * CFrame.new(bx, r.y - T - 0.31, 0.05), parent)
			part(Vector3.new(0.12, 0.1, D * 0.75), WOOD_DARK, F0 * CFrame.new(bx, r.y - T - 0.05, D * 0.375), parent)
			part(Vector3.new(0.1, 0.1, 0.78), WOOD_DARK, F0 * CFrame.new(bx, r.y - T - 0.3, 0.3) * CFrame.Angles(math.rad(45), 0, 0), parent)
		end
	end
	bookRow(parent, F0 * CFrame.new(rows[1].dx - W / 2 + 0.15, rows[1].y, 0.5), W - 1.4, 1.25, 0.8)
	plant(parent, F0 * CFrame.new(rows[1].dx + W / 2 - 0.55, rows[1].y, 0.5))
	trophiesOn(parent, F0 * CFrame.new(rows[2].dx, rows[2].y, 0.5), 1.35)
	bookStack(parent, F0 * CFrame.new(rows[3].dx - 1.3, rows[3].y, 0.5), 3)
	bookRow(parent, F0 * CFrame.new(rows[3].dx + 0.2, rows[3].y, 0.5), 1.9, 1.1, 0.75)
end

-- ---------- on the wall ----------
local STYLES = {bookcase = bookcase, planks = planks}
local function style()
	if item("shelf_bare") >= 1 then return nil end
	if item("shelfon_planks") >= 1 then return "planks" end
	return "bookcase"
end
local shown, shownKey
local function key()
	local k = tostring(style())
	for _, t in ipairs(TROPHIES) do k ..= (t.earned() and "1" or "0") end
	return k
end
local function draw()
	local lf = workspace:FindFirstChild("Treehouse_local")
	local want = roomUp() and style()
	if not (lf and want) then
		if shown then shown:Destroy(); shown, shownKey = nil, nil end
		return
	end
	local k = key()
	if shown and shown.Parent and shownKey == k then return end
	if shown then shown:Destroy() end
	rng = Random.new(player.UserId)
	local m = Instance.new("Model"); m.Name = "TrophyShelf"
	STYLES[want](m)
	m.Parent = lf
	shown, shownKey = m, k
end
player.AttributeChanged:Connect(function(n)
	if n:sub(1, 10) == "Item_tree_" or n:find("^Item_shelf") or n == "Item_passport_keeper" or n == "Item_croc_rescues"
		or n == "ChampionNo" or n == "PortoKeeperTitle" then task.defer(draw) end
end)
task.spawn(function()
	workspace:WaitForChild("Treehouse_local", 120)
	while true do draw(); task.wait(5) end                        -- (a reset round can take the room away)
end)
print("ShelfClient: ready - the trophy shelf on the left wall")
]==] end)
print(string.format("shelf1: DecorServer %d, DecorClient %d, ShelfClient %d chars", #ds.Source, #dc.Source, #sc.Source))
return "shelf1 installed"

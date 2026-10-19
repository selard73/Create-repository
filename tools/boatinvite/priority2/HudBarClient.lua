-- FRENCH_ONLY_HUD_20261002_V1
-- Area is the authoritative live destination, not the permanent Item_porto unlock.
local function frenchMapHudAllowed()
    local area = game:GetService("Players").LocalPlayer:GetAttribute("Area")
    return area == "forest" or area == "village" or area == "domaine"
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local C = Color3.fromRGB
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local NEED = (workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need")) or 10
local UIS = game:GetService("UserInputService")
local isMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or script.Parent:GetAttribute("ForceMobile") == true
local PANEL_Y = 64                              -- right under the icons; on phones the Hint button moved to the left (Oct 7 2026), so the panel gets that room
local PANEL, CREAM, GOLD, DIM = C(38, 30, 52), C(255, 246, 220), C(255, 214, 90), C(120, 110, 140)

-- ---------------------------------------------------------------- the areas ----
-- world rectangles (the same ones the boundary walls use), the order you travel them, and what unlocks each
local AREAS = {
	{id = "forest",  x0 = -130, x1 = 142, z0 = -215, z1 = 25,  needs = nil},
	{id = "village", x0 = 150,  x1 = 352, z0 = -205, z1 = 5,   needs = "forest"},
	{id = "domaine", x0 = 352,  x1 = 700, z0 = -250, z1 = 30,  needs = "village"},
	-- Porto Nocciola's three areas (Oct 8 2026, world chart v2): rects {x0, z0, x1, z1} = the Zones parts of each area; the first carries the name plate
	{id = "porto_harbour", porto = "harbour", needs = "porto", name = "The Harbour", long = "Porto Nocciola · The Harbour",
	 rects = {{150, -880, 355, -540}, {150, -1300, 300, -880}}},
	{id = "porto_borgo", porto = "borgo", needs = "porto_harbour", name = "Via della Piazza", long = "Porto Nocciola · Via della Piazza",
	 rects = {{355.5, -1000, 617, -540}, {617, -756, 800.5, -540}, {300, -1000, 355, -880}}},
	{id = "porto_groves", porto = "groves", needs = "porto_borgo", name = "The Groves", long = "Porto Nocciola · The Groves",
	 rects = {{300, -1300, 800, -1000}, {617, -1000, 800.5, -756}}},   -- Oct 8 2026: the strip south of the terraces joined The Groves (option A)
}
for _, a in ipairs(AREAS) do if not a.rects then a.rects = {{a.x0, a.z0, a.x1, a.z1}} end end
local NAME, TOTAL = {}, {}
for _, m in ipairs(Registry.maps) do NAME[m.id] = m.name end
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1 end
local AREA_OF = {}                                              -- Porto squirrel id -> its area (harbour / borgo / groves)
for _, e in ipairs(Registry.squirrels) do
	if e.map == "porto" and e.area then AREA_OF[e.id] = e.area; TOTAL["porto_" .. e.area] = (TOTAL["porto_" .. e.area] or 0) + 1 end
end
local function portoFound(area)                                 -- finds in one Porto area, from the FoundIds list the server publishes
	local n = 0
	for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do if AREA_OF[id] == area then n += 1 end end
	return n
end
local function unlocked(a)
	if a.needs == "porto" then return (player:GetAttribute("Item_porto") or 0) >= 1 end
	if a.needs and a.needs:sub(1, 6) == "porto_" then            -- the town and the groves: the Porto gates' rule (10 found in the area before)
		return (player:GetAttribute("Item_porto") or 0) >= 1 and (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED
	end
	return (not a.needs) or (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED
end
local function areaAt(pos)
	for _, a in ipairs(AREAS) do
		for _, r in ipairs(a.rects) do
			if pos.X >= r[1] and pos.X <= r[3] and pos.Z >= r[2] and pos.Z <= r[4] then return a end
		end
	end
end

-- ---------------------------------------------------------------- the bar ----
pcall(function() pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor end)         -- phones stay in landscape, either way up
for _, g in ipairs(pg:GetChildren()) do if g.Name == "HudBar" then g:Destroy() end end        -- never two bars
local gui = Instance.new("ScreenGui"); gui.Name = "HudBar"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 6; gui.Parent = pg
local bar = Instance.new("Frame"); bar.Name = "Bar"; bar.AnchorPoint = Vector2.new(1, 0); bar.Position = UDim2.new(1, -10, 0, 8)
bar.Size = UDim2.fromOffset(216, 48); bar.BackgroundTransparency = 1; bar.Parent = gui
local layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = bar

local function iconButton(order, tip)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(48, 48); b.BackgroundColor3 = PANEL; b.BackgroundTransparency = 0
	b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.LayoutOrder = order; b.Parent = bar
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.35; s.Parent = b
	local label = Instance.new("TextLabel"); label.Name = "Tip"; label.AnchorPoint = Vector2.new(0.5, 1); label.Position = UDim2.new(0.5, 0, 0, -4)
	label.Size = UDim2.fromOffset(96, 20); label.BackgroundColor3 = PANEL; label.BackgroundTransparency = 0.15; label.TextColor3 = CREAM
	label.Font = Enum.Font.FredokaOne; label.TextSize = 13; label.Text = tip; label.Visible = false; label.Parent = b
	local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 8); lc.Parent = label
	b.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 0}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.35}):Play() end)
	return b, s
end
local function acorn(parent, size, cx, cy)                      -- a little acorn drawn from frames
	local nut = Instance.new("Frame"); nut.Size = UDim2.fromOffset(size * 0.62, size * 0.62); nut.Position = UDim2.fromOffset(cx - size * 0.31, cy - size * 0.18)
	nut.BackgroundColor3 = C(206, 146, 82); nut.BorderSizePixel = 0; nut.Parent = parent
	local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0.45, 0); nc.Parent = nut
	local cap = Instance.new("Frame"); cap.Size = UDim2.fromOffset(size * 0.78, size * 0.34); cap.Position = UDim2.fromOffset(cx - size * 0.39, cy - size * 0.40)
	cap.BackgroundColor3 = C(110, 70, 40); cap.BorderSizePixel = 0; cap.Parent = parent
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0.4, 0); cc.Parent = cap
	local stem = Instance.new("Frame"); stem.Size = UDim2.fromOffset(size * 0.12, size * 0.2); stem.Position = UDim2.fromOffset(cx - size * 0.06, cy - size * 0.56)
	stem.BackgroundColor3 = C(86, 56, 34); stem.BorderSizePixel = 0; stem.Parent = parent
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0.4, 0); sc.Parent = stem
end

-- Clean static silhouette: smooth curves stay readable at phone sizes.
-- Avoids copying a furred game mesh or waiting for world models to load.
local function squirrelIcon(parent, size, cx, cy)
 local icon=Instance.new("ImageLabel")
 icon.Name="SquirrelIcon"
 icon.AnchorPoint=Vector2.new(0.5,0.5)
 icon.Position=UDim2.fromOffset(cx,cy)
 icon.Size=UDim2.fromOffset(size,size)
 icon.BackgroundTransparency=1
 icon.Image="rbxassetid://90886407221518"
 icon.ScaleType=Enum.ScaleType.Fit
 icon.Parent=parent
 local edge=Instance.new("UICorner");edge.CornerRadius=UDim.new(0,5);edge.Parent=icon
end

local squirrelBtn = iconButton(1, "Squirrels")
squirrelIcon(squirrelBtn, 30, 24, 16)                            -- a squirrel for the squirrels; the acorn
                                                                 -- belongs to the purse beside it
local countTag = Instance.new("TextLabel"); countTag.AnchorPoint = Vector2.new(0.5, 1); countTag.Position = UDim2.new(0.5, 0, 1, -2); countTag.Size = UDim2.fromOffset(44, 14)
countTag.BackgroundTransparency = 1; countTag.Font = Enum.Font.FredokaOne; countTag.TextSize = 13; countTag.TextColor3 = GOLD; countTag.Text = "0"; countTag.Parent = squirrelBtn
local mapBtn = iconButton(2, "Map")
do                                                               -- a folded map: three panels, a route and a pin
	for i, tint in ipairs({C(228, 216, 186), C(214, 200, 166), C(228, 216, 186)}) do
		local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(8, i == 2 and 25 or 21); p.Position = UDim2.fromOffset(11 + (i - 1) * 9, i == 2 and 4 or 6)
		p.BackgroundColor3 = tint; p.BorderSizePixel = 0; p.Parent = mapBtn
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 2); c.Parent = p
	end
	local pin = Instance.new("Frame"); pin.Size = UDim2.fromOffset(8, 8); pin.Position = UDim2.fromOffset(25, 9); pin.BackgroundColor3 = C(214, 60, 60); pin.BorderSizePixel = 0; pin.Parent = mapBtn
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pin
end

-- ---- the acorn purse: a square LEFT of the two icons, showing what you have collected ----
-- Now a button: it opens the store. LayoutOrder 0 puts it leftmost - the row is right-aligned and lays its
-- children out in order.
local purse = Instance.new("TextButton")
purse.Name = "Purse"; purse.Size = UDim2.fromOffset(48, 48); purse.BackgroundColor3 = PANEL
purse.BackgroundTransparency = 0; purse.BorderSizePixel = 0; purse.LayoutOrder = 0
purse.Text = ""; purse.AutoButtonColor = false; purse.Parent = bar
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = purse
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Transparency = 0.35; st.Parent = purse
end
acorn(purse, 21, 24, 14)                                         -- the same acorn as the collectible on the ground
local purseCount = Instance.new("TextLabel")
purseCount.Name = "Count"; purseCount.AnchorPoint = Vector2.new(0.5, 1); purseCount.Position = UDim2.new(0.5, 0, 1, -2)
purseCount.Size = UDim2.fromOffset(44, 14); purseCount.BackgroundTransparency = 1
purseCount.Font = Enum.Font.FredokaOne; purseCount.TextSize = 13; purseCount.TextColor3 = GOLD
purseCount.Text = "0"; purseCount.Parent = purse
-- lemons (Oct 8 2026, bought from Porto's Lemon Seller, for making perfume in France): a small lemon on the purse's top-left
-- corner with the count, shown once you have one - inside the purse, so it never overlaps anything else
local lemonBadge = Instance.new("Frame"); lemonBadge.Name = "Lemons"; lemonBadge.Size = UDim2.fromOffset(19, 14); lemonBadge.Position = UDim2.fromOffset(2, 2)
lemonBadge.BackgroundColor3 = C(250, 222, 96); lemonBadge.BorderSizePixel = 0; lemonBadge.Visible = false; lemonBadge.ZIndex = 3; lemonBadge.Parent = purse
local lbc = Instance.new("UICorner"); lbc.CornerRadius = UDim.new(0.5, 0); lbc.Parent = lemonBadge
local lbs = Instance.new("UIStroke"); lbs.Color = C(150, 120, 30); lbs.Thickness = 1; lbs.Parent = lemonBadge
local lemonCount = Instance.new("TextLabel"); lemonCount.Name = "Count"; lemonCount.Size = UDim2.fromScale(1, 1); lemonCount.BackgroundTransparency = 1
lemonCount.Font = Enum.Font.FredokaOne; lemonCount.TextSize = 11; lemonCount.TextColor3 = C(90, 60, 10); lemonCount.ZIndex = 4; lemonCount.Parent = lemonBadge
local function refreshLemons()
	local n = player:GetAttribute("Item_lemon") or 0
	lemonBadge.Visible = n > 0
	lemonCount.Text = tostring(n)
end
player:GetAttributeChangedSignal("Item_lemon"):Connect(refreshLemons)
refreshLemons()

-- ---------------------------------------------------------------- the squirrel panel (the existing HUD) ----
local hudGui, hudPanel
local function viewport()
	local c = workspace.CurrentCamera
	return c and c.ViewportSize or Vector2.new(1280, 720)
end
-- the squirrel panel and the squirrel card are built at a fixed pixel size; on a phone they run off the screen, so
-- each gets a UIScale that shrinks it to whatever room is left
local function fitPanel()
	if not hudPanel then return end
	local sc = hudPanel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", hudPanel)
	local vp = viewport()
	local w, h = hudPanel.Size.X.Offset, hudPanel.Size.Y.Offset
	if w <= 0 or h <= 0 then return end
	sc.Scale = math.clamp(math.min((vp.Y - PANEL_Y - 16 - 76) / h, (vp.X - 40) / w), 0.45, 1)   -- Oct 7 2026: 76 px reserved for the Roblox hotbar / jump button (Shannon: phones overlapping; 72 left the panel 2 px over the jump button)
end
-- the squirrel card is built tall and narrow, which does not suit a phone held sideways. On a phone it is laid out
-- again in landscape: the portrait on the left, the name and story on the right. The card's own pop animation drives
-- its UIScale, so any size clamp has to be applied after that tween has finished.
local CARD_W, CARD_H = 646, 306
local function relayoutCard(prim)
	local big, ring, hint, title, bio
	for _, d in ipairs(prim:GetDescendants()) do
		if d:IsA("Frame") and d.Size.X.Offset == 326 then big = d
		elseif d:IsA("Frame") and d.Size.X.Offset == 288 then ring = d
		elseif d:IsA("TextLabel") then
			local y = d.Position.Y.Offset
			if y == 350 then hint = d elseif y == 368 then title = d elseif y == 414 then bio = d end
		end
	end
	prim.Size = UDim2.fromOffset(CARD_W, CARD_H)
	if big then
		big.AnchorPoint = Vector2.new(0, 0.5); big.Position = UDim2.new(0, 16, 0.5, 0); big.Size = UDim2.fromOffset(252, 252)
	end
	if ring then ring.Size = UDim2.fromOffset(228, 228); ring.Position = UDim2.new(0.5, 0, 0.5, 0) end
	if hint then hint.Position = UDim2.new(0, 16, 1, -24); hint.Size = UDim2.fromOffset(252, 16) end
	if title then title.Position = UDim2.new(0, 288, 0, 30); title.Size = UDim2.new(1, -312, 0, 42) end
	if bio then bio.Position = UDim2.new(0, 290, 0, 84); bio.Size = UDim2.new(1, -314, 1, -118) end
end
local function fitCard(card)
	for _, d in ipairs(card:GetChildren()) do
		if d:IsA("Frame") and d.AnchorPoint.X == 0.5 and d.Size.X.Offset > 200 then
			if d:GetAttribute("SelfFit") then continue end                -- Oct 7 2026: the card now lays itself out above the hotbar (SquirrelAnim modalBand); nothing to do here
			if isMobile then relayoutCard(d) end
			task.delay(0.45, function()                        -- after the card's pop-in tween has settled
				if not d.Parent then return end
				local sc = d:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", d)
				local vp = viewport()
				sc.Scale = math.clamp(math.min((vp.Y - 20) / d.Size.Y.Offset, (vp.X - 20) / d.Size.X.Offset), 0.4, 1)
			end)
		end
	end
end
-- takes charge of a squirrel HUD: its panel goes below the bar (and the Hint button on phones), closed, fitted to the screen
local function hookHud(g)
	hudGui = g
	local p = g:WaitForChild("Panel", 30)
	if not p or hudGui ~= g then return end
	hudPanel = p
	-- Release only our own modal claim when this panel is hidden.
	p:GetPropertyChangedSignal("Visible"):Connect(function()
		if not p.Visible and pg:GetAttribute("OpenPanel") == "collection" then pg:SetAttribute("OpenPanel", nil) end
	end)
	p.Position = UDim2.new(1, -10, 0, PANEL_Y)
	p.Visible = false
	p.AnchorPoint = Vector2.new(1, 0)
	fitPanel()
	p:GetPropertyChangedSignal("Size"):Connect(fitPanel)
	for _, c in ipairs(g:GetChildren()) do if c.Name == "Card" then fitCard(c) end end
	g.ChildAdded:Connect(function(c)                            -- the card is rebuilt every time one is opened
		if c.Name == "Card" then task.defer(fitCard, c) end
	end)
end
task.spawn(function()
	local g = pg:WaitForChild("SquirrelHUD", 60)
	if g then hookHud(g) end
end)
-- A RESET REBUILDS THE SQUIRREL HUD (Shannon, Sep 26, on her phone: "I reset my count for squirrels and the squirrel
-- inventory is open and it will not close ... the menu is also overlapping with the 3 pills at the upper right"): the
-- squirrels' own script destroys the HUD and makes a new one, open, in its old corner under these icons - and the icon was
-- still opening and closing the old one. Every new one is taken over the same way, so the icon keeps working.
pg.ChildAdded:Connect(function(c)
	if c.Name == "SquirrelHUD" and c ~= hudGui then task.defer(hookHud, c) end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel) end
local function squirrelOpen() return hudPanel and hudPanel.Visible end

-- ---------------------------------------------------------------- the map panel ----
-- a drawn parchment chart (marketing/make_map.py, uploaded as an image); the names, tallies, the "?" covers over
-- areas you have not reached and the "you are here" dot are drawn on top of it
local MAP_ID = 126434655912945                                   -- the first world chart (France + the harbour), until Oct 8 2026
local MAP_TILES = {{id = 76679301986389, y0 = 0, h = 712}, {id = 121118886486203, y0 = 712, h = 711}}   -- Oct 8 2026: world chart v2 (make_map_world2.py), rows 0..711 and 712..1422
-- ONE draggable chart of the whole world (Shannon's choice, Oct 1 2026): France, the gorge the river leaves through, the
-- falls, Porto Nocciola's harbour and shore, drawn as one parchment (marketing/make_map_world.py). The panel is a window
-- onto it: drag with the mouse or a finger, zoom with the wheel, a pinch or the + / - buttons, "Me" centres on you. The
-- names, tallies, the "?" covers over places you have not reached and the you-are-here dot ride on the chart.
local IMG_W, IMG_H, IMG_M = 1024, 1423, 26                    -- the image (v2: all of Porto Nocciola), and the margin its world area starts at
local WX0, WX1, WZ0, WZ1 = -130, 820, -1310, 30               -- the world the image covers (make_map_world2.py)
local IS = math.min((IMG_W - 2 * IMG_M) / (WX1 - WX0), (IMG_H - 2 * IMG_M) / (WZ1 - WZ0))
local IOX = (IMG_W - (WX1 - WX0) * IS) / 2
local IOZ = (IMG_H - (WZ1 - WZ0) * IS) / 2
local function toImg(x, z) return IOX + (x - WX0) * IS, IOZ + (z - WZ0) * IS end   -- world -> chart pixels
local DISP_W, DISP_H = 560, 380                                   -- the window onto the chart
local MINZ, MAXZ = math.min(DISP_W / IMG_W, DISP_H / IMG_H), 2.6   -- the whole world .. close up
local zoom, panX, panY = 1, 0, 0                                  -- chart pixels -> window pixels, and where the chart's corner sits

local map = Instance.new("Frame"); map.Name = "MapPanel"; map.AnchorPoint = Vector2.new(1, 0); map.Position = UDim2.new(1, -10, 0, PANEL_Y)
map.Size = UDim2.fromOffset(DISP_W + 16, DISP_H + 48); map.BackgroundColor3 = PANEL; map.BackgroundTransparency = 0.08
map.BorderSizePixel = 0; map.Visible = false; map.Parent = gui
map:GetPropertyChangedSignal("Visible"):Connect(function()
	if not map.Visible and pg:GetAttribute("OpenPanel") == "map" then pg:SetAttribute("OpenPanel", nil) end
end)
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = map
local ms = Instance.new("UIStroke"); ms.Color = GOLD; ms.Thickness = 2; ms.Parent = map
local here = Instance.new("TextLabel"); here.Size = UDim2.new(1, -20, 0, 26); here.Position = UDim2.new(0, 10, 0, 6); here.BackgroundTransparency = 1
here.Font = Enum.Font.FredokaOne; here.TextSize = 17; here.TextColor3 = CREAM; here.TextXAlignment = Enum.TextXAlignment.Left
here.TextTruncate = Enum.TextTruncate.AtEnd; here.Text = "You are here"; here.Parent = map
local view = Instance.new("Frame"); view.Name = "View"; view.Position = UDim2.new(0, 8, 0, 36); view.Size = UDim2.fromOffset(DISP_W, DISP_H)
view.BackgroundColor3 = C(214, 190, 140); view.BorderSizePixel = 0; view.ClipsDescendants = true; view.Active = true; view.Parent = map
local vc = Instance.new("UICorner"); vc.CornerRadius = UDim.new(0, 8); vc.Parent = view
-- the chart is 1024 x 1423, taller than one Roblox image may be, so it is two tiles stacked (the top one a pixel deeper, under the
-- bottom one, so no seam opens at any zoom); the tiles come first so the covers, names and the dot draw over them
local chart = Instance.new("Frame"); chart.Name = "Chart"; chart.BackgroundTransparency = 1; chart.BorderSizePixel = 0; chart.Parent = view
for i, t in ipairs(MAP_TILES) do
	local tile = Instance.new("ImageLabel"); tile.Name = "Tile" .. i; tile.BackgroundTransparency = 1; tile.BorderSizePixel = 0
	tile.Image = "rbxassetid://" .. t.id; tile.ScaleType = Enum.ScaleType.Stretch
	tile.Position = UDim2.fromScale(0, t.y0 / IMG_H); tile.Size = UDim2.fromScale(1, (t.h + (i < #MAP_TILES and 1 or 0)) / IMG_H)
	tile.Parent = chart
end
-- the zoom and centre buttons sit in the window's bottom corner (the top of the panel is where the game's notices appear)
local function viewBtn(text, bottom, w)
	local b = Instance.new("TextButton"); b.Name = "Btn_" .. text; b.AnchorPoint = Vector2.new(1, 1); b.Position = UDim2.new(1, -8, 1, -bottom); b.Size = UDim2.fromOffset(w, 30)
	b.BackgroundColor3 = C(58, 48, 76); b.BackgroundTransparency = 0.08; b.BorderSizePixel = 0; b.Font = Enum.Font.FredokaOne; b.TextSize = 18; b.TextColor3 = CREAM
	b.Text = text; b.AutoButtonColor = true; b.ZIndex = 8; b.Parent = view
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 9); bc.Parent = b
	local bs = Instance.new("UIStroke"); bs.Color = GOLD; bs.Thickness = 1; bs.Transparency = 0.4; bs.Parent = b
	return b
end
local centreMe, zoomOut, zoomIn = viewBtn("Me", 8, 46), viewBtn("-", 46, 30), viewBtn("+", 84, 30)

local layouts = {}                                                -- everything that rides on the chart re-places itself here
local function clampPan()
	local cw, ch = IMG_W * zoom, IMG_H * zoom
	panX = cw <= DISP_W and (DISP_W - cw) / 2 or math.clamp(panX, DISP_W - cw, 0)
	panY = ch <= DISP_H and (DISP_H - ch) / 2 or math.clamp(panY, DISP_H - ch, 0)
end
local function relayout()
	clampPan()
	chart.Position = UDim2.fromOffset(panX, panY); chart.Size = UDim2.fromOffset(IMG_W * zoom, IMG_H * zoom)
	for _, f in ipairs(layouts) do f() end
end
local function toCanvas(x, z) local ix, iz = toImg(x, z) return ix * zoom, iz * zoom end   -- world -> pixels on the chart frame
local function centreOn(x, z) local ix, iz = toImg(x, z); panX = DISP_W / 2 - ix * zoom; panY = DISP_H / 2 - iz * zoom; relayout() end
local function zoomAt(f, vx, vy)                                  -- zoom about a point of the window
	local nz = math.clamp(zoom * f, MINZ, MAXZ); if nz == zoom then return end
	local ix, iy = (vx - panX) / zoom, (vy - panY) / zoom
	zoom = nz; panX = vx - ix * zoom; panY = vy - iy * zoom; relayout()
end
local function viewPoint(sx, sy)                                  -- a screen position -> window pixels (the panel is scaled down on phones)
	local s = math.max(view.AbsoluteSize.X / DISP_W, 0.01)
	return (sx - view.AbsolutePosition.X) / s, (sy - view.AbsolutePosition.Y) / s
end

local cards = {}
for _, a in ipairs(AREAS) do
	local card = {open = false}
	for i, r in ipairs(a.rects) do                                -- Porto's areas are several rects; each gets a cover, the first the name plate
		local holder = Instance.new("Frame"); holder.Name = i == 1 and a.id or (a.id .. "_" .. i); holder.BackgroundTransparency = 1; holder.Parent = chart
		-- the cover that hides an area you have not reached
		local cover = Instance.new("Frame"); cover.Name = "Cover"; cover.Size = UDim2.fromScale(1, 1); cover.BackgroundColor3 = C(226, 208, 166)
		cover.BorderSizePixel = 0; cover.Parent = holder
		local cs = Instance.new("UIStroke"); cs.Color = C(150, 118, 74); cs.Thickness = 2; cs.Parent = cover
		local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Font = Enum.Font.Antique
		q.TextSize = 44; q.TextColor3 = C(126, 96, 58); q.Text = "?"; q.Parent = cover
		local plate
		if i == 1 then
			-- the name plate for an area you have reached
			plate = Instance.new("Frame"); plate.Name = "Plate"; plate.AnchorPoint = Vector2.new(0.5, 0); plate.Position = UDim2.new(0.5, 0, 0, 4)
			plate.Size = UDim2.fromOffset(190, 34); plate.BackgroundColor3 = C(248, 240, 214); plate.BackgroundTransparency = 0.12
			plate.BorderSizePixel = 0; plate.Parent = holder
			local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = plate
			local pstroke = Instance.new("UIStroke"); pstroke.Color = C(150, 118, 74); pstroke.Thickness = 1; pstroke.Parent = plate
			local title = Instance.new("TextLabel"); title.Name = "Title"; title.Size = UDim2.new(1, -6, 0, 17); title.Position = UDim2.new(0, 3, 0, 2)
			title.BackgroundTransparency = 1; title.Font = Enum.Font.Antique; title.TextSize = 15; title.TextColor3 = C(88, 58, 32)
			title.TextTruncate = Enum.TextTruncate.AtEnd; title.Parent = plate
			local tally = Instance.new("TextLabel"); tally.Name = "Tally"; tally.Size = UDim2.new(1, -6, 0, 13); tally.Position = UDim2.new(0, 3, 0, 18)
			tally.BackgroundTransparency = 1; tally.Font = Enum.Font.FredokaOne; tally.TextSize = 12; tally.TextColor3 = C(120, 84, 44); tally.Parent = plate
			card.cover, card.plate, card.title, card.tally = cover, plate, title, tally
		end
		table.insert(layouts, function()
			local x0, z0 = toCanvas(r[1], r[2]); local x1, z1 = toCanvas(r[3], r[4])
			holder.Position = UDim2.fromOffset(x0, z0); holder.Size = UDim2.fromOffset(x1 - x0, z1 - z0)
			if plate then
				plate.Size = UDim2.fromOffset(math.max(70, math.min(x1 - x0 - 8, 190)), 34)
				plate.Visible = card.open and (x1 - x0) > 80            -- too small to read: the chart speaks for itself
			end
			cover.Visible = not card.open
			q.TextSize = math.clamp(44 * zoom, 16, 72)
			q.Visible = (x1 - x0) > 24 and (z1 - z0) > 24              -- no "?" squeezed into a sliver
		end)
	end
	cards[a.id] = card
end

local dot = Instance.new("Frame"); dot.Name = "You"; dot.Size = UDim2.fromOffset(13, 13); dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = C(210, 50, 50); dot.BorderSizePixel = 0; dot.ZIndex = 6; dot.Parent = chart
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
local ds = Instance.new("UIStroke"); ds.Color = C(252, 246, 230); ds.Thickness = 2; ds.Parent = dot
local ring = Instance.new("Frame"); ring.Size = UDim2.fromOffset(26, 26); ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.5, 0.5)
ring.BackgroundTransparency = 1; ring.ZIndex = 5; ring.Parent = dot
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
local rs = Instance.new("UIStroke"); rs.Color = C(210, 70, 70); rs.Thickness = 2; rs.Transparency = 0.4; rs.Parent = ring

-- dragging and zooming: the mouse or a finger drags, the wheel or a pinch zooms, the buttons too
local drag, pinch = nil, nil
local touches = {}
local function touchCount() local n = 0 for _ in pairs(touches) do n += 1 end return n end
local function pinchUpdate()
	local pts = {}
	for _, v in pairs(touches) do pts[#pts + 1] = v end
	if #pts < 2 then pinch = nil return end
	local dist = (pts[1] - pts[2]).Magnitude
	local mid = (pts[1] + pts[2]) / 2
	local vx, vy = viewPoint(mid.X, mid.Y)
	if not pinch or dist < 1 then pinch = {d0 = math.max(dist, 1), z0 = zoom, ix = (vx - panX) / zoom, iy = (vy - panY) / zoom} return end
	zoom = math.clamp(pinch.z0 * dist / pinch.d0, MINZ, MAXZ)
	panX = vx - pinch.ix * zoom; panY = vy - pinch.iy * zoom
	relayout()
end
view.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if input.UserInputType == Enum.UserInputType.Touch then touches[input] = Vector2.new(input.Position.X, input.Position.Y) end
		if touchCount() >= 2 then drag = nil; pinch = nil; pinchUpdate() return end
		drag = {x = input.Position.X, y = input.Position.Y, px = panX, py = panY, input = input}
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		local vx, vy = viewPoint(input.Position.X, input.Position.Y)
		zoomAt(input.Position.Z > 0 and 1.25 or 0.8, vx, vy)
	end
end)
UIS.InputChanged:Connect(function(input)
	if not map.Visible then return end
	if touches[input] then
		touches[input] = Vector2.new(input.Position.X, input.Position.Y)
		if touchCount() >= 2 then pinchUpdate() return end
	end
	if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input == drag.input) then
		local s = math.max(view.AbsoluteSize.X / DISP_W, 0.01)
		panX = drag.px + (input.Position.X - drag.x) / s
		panY = drag.py + (input.Position.Y - drag.y) / s
		relayout()
	end
end)
UIS.InputEnded:Connect(function(input)
	if touches[input] then touches[input] = nil; pinch = nil; drag = nil end
	if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input) then drag = nil end
end)
zoomIn.Activated:Connect(function() zoomAt(1.3, DISP_W / 2, DISP_H / 2) end)
zoomOut.Activated:Connect(function() zoomAt(1 / 1.3, DISP_W / 2, DISP_H / 2) end)
local function centreOnMe()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if zoom < 1 then zoom = 1 end
	centreOn(math.clamp(root.Position.X, WX0, WX1), math.clamp(root.Position.Z, WZ0, WZ1))
end
centreMe.Activated:Connect(centreOnMe)

local function refreshMap()
	for _, a in ipairs(AREAS) do
		local card = cards[a.id]
		local open = unlocked(a)
		card.open = open
		if open then
			card.title.Text = a.name or NAME[a.id] or a.id
			local found = a.porto and portoFound(a.porto) or (player:GetAttribute("Found_" .. a.id) or 0)
			card.tally.Text = string.format("%d / %d found", found, TOTAL[a.id] or 0)
		end
	end
	relayout()
end
local function refreshCount()
	local n = player:GetAttribute("SquirrelsFound") or 0
	local all = #Registry.squirrels
	countTag.Text = string.format("%d/%d", n, all)
end

-- ---------------------------------------------------------------- opening and closing ----
local function setSquirrels(open)
	if open then pg:SetAttribute("OpenPanel","collection") end
	if hudPanel then hudPanel.Visible = open end
	if open then map.Visible = false end
end
local function setMap(open)
	if open then pg:SetAttribute("OpenPanel","map") end
	map.Visible = open
	if open then refreshMap(); centreOnMe(); if hudPanel then hudPanel.Visible = false end end
end
squirrelBtn.Activated:Connect(function() setSquirrels(not squirrelOpen()) end)
mapBtn.Activated:Connect(function() setMap(not map.Visible) end)
for _, a in ipairs(AREAS) do
	if a.needs == "porto" or a.needs == "porto_inner" then player:GetAttributeChangedSignal("Item_porto"):Connect(refreshMap)
	elseif a.needs then player:GetAttributeChangedSignal("Found_" .. a.needs):Connect(refreshMap) end
	if not a.porto then player:GetAttributeChangedSignal("Found_" .. a.id):Connect(refreshMap) end
end
player:GetAttributeChangedSignal("FoundIds"):Connect(refreshMap)          -- Porto's per-area tallies
player:GetAttributeChangedSignal("Found_porto"):Connect(refreshMap)       -- the town + groves unlock
player:GetAttributeChangedSignal("SquirrelsFound"):Connect(refreshCount)

-- the purse follows the Acorns attribute, which the server sets; a small pop so a pickup is felt as well as seen
local purseScale = Instance.new("UIScale"); purseScale.Parent = purse
local function refreshPurse()
	purseCount.Text = tostring(player:GetAttribute("Acorns") or 0)
end
player:GetAttributeChangedSignal("Acorns"):Connect(function()
	refreshPurse()
	purseScale.Scale = 1.22
	TweenService:Create(purseScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1}):Play()
	-- a backstop: an interrupted tween once left a UIScale stuck large over the panel, and a counter frozen
	-- mid-bounce looks broken in a way that is hard to explain
	task.delay(0.6, function() if purseScale then purseScale.Scale = 1 end end)
end)
refreshPurse()
refreshCount(); refreshMap()

-- on a narrow screen (phones) the map shrinks to fit rather than covering everything
local mapScale = Instance.new("UIScale"); mapScale.Parent = map
local function fitMap()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	mapScale.Scale = math.clamp(math.min((vp.X - 30) / (DISP_W + 16), (vp.Y - PANEL_Y - 16 - 76) / (DISP_H + 48)), 0.45, 1)   -- Oct 8 2026: 76 px kept clear for the hotbar / jump button, like fitPanel (it covered the jump button on phones)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMap) end
fitMap()

-- the "you are here" dot follows the player while the map is open (the chart itself stays where you dragged it)
RunService.RenderStepped:Connect(function()
	if not map.Visible then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then dot.Visible = false; return end
	local p = root.Position
	local cx, cz = toCanvas(math.clamp(p.X, WX0, WX1), math.clamp(p.Z, WZ0, WZ1))
	dot.Visible = true
	dot.Position = UDim2.fromOffset(cx, cz)
	local a = areaAt(p)
	here.Text = a and ("You are here: " .. (a.long or a.name or NAME[a.id] or a.id)) or "You are here"
	rs.Transparency = 0.25 + 0.35 * math.abs(math.sin(os.clock() * 2))
end)

-- the Golden Squirrel pill (DailyGui.GoldPill, computers only) sits on the panels' header line at the top right: it steps
-- aside while the map or the squirrels panel is open and comes back when they close (Shannon, Oct 1: "fix the overlap")
-- Daily owns phone/state eligibility; this existing coordinator owns panel overlap.
RunService.Heartbeat:Connect(function()
    local daily = pg:FindFirstChild("DailyGui")
    local pill = daily and daily:FindFirstChild("GoldPill")
    if not pill then return end
    local blocked = map.Visible or (hudPanel ~= nil and hudPanel.Visible)
    pill:SetAttribute("FrenchHudPanelBlocked", blocked)
    pill.Visible = frenchMapHudAllowed() and not blocked
        and pill:GetAttribute("FrenchHudPillEligible") == true
end)

-- Passport entry uses the same top-right control row, without an extra floating widget.
local passportBtn = iconButton(-1,"Passport"); passportBtn.Name="Passport"
local art = require(game:GetService("ReplicatedStorage"):WaitForChild("SquirrelIllustrations"))
local illustration
local function passportCover()
 if illustration then illustration:Destroy() end
 illustration=art.draw(passportBtn,(player:GetAttribute("Item_passport_outings") or 0)>=5 and "goldpassport" or "passport",30);illustration.Position=UDim2.fromOffset(9,1)
end
local function hudCaption(parent,value)
 local l=Instance.new("TextLabel");l.Name="Caption";l.AnchorPoint=Vector2.new(.5,1);l.Position=UDim2.new(.5,0,1,-2);l.Size=UDim2.fromOffset(46,14)
 l.BackgroundTransparency=1;l.Font=Enum.Font.FredokaOne;l.TextSize=10;l.TextColor3=GOLD;l.Text=value;l.Parent=parent
end
hudCaption(passportBtn,"Passport");hudCaption(mapBtn,"Map")
passportCover();player:GetAttributeChangedSignal("Item_passport_outings"):Connect(passportCover)
passportBtn.Activated:Connect(function() game:GetService("ReplicatedStorage").PassportToggle:Fire() end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
 local active=pg:GetAttribute("OpenPanel")
 if active and active~="map" then map.Visible=false end
 if active and active~="collection" and hudPanel then hudPanel.Visible=false end
end)
-- world-map v3 (Oct 1 2026)

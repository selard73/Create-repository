-- HudBar: the squirrel panel no longer sits open across the screen. Two small icons in the top right corner open it:
-- an acorn (the squirrel list, with the count on it) and a folded map (the three areas, where you are, and a "?" over
-- any area you have not unlocked yet). Only one panel is open at a time, and both start closed.
-- Run in edit mode: require(workspace.HudBar.PatchModule)()  (packed by village/make_patch.py)
return function()
	local old = workspace:FindFirstChild("HudBarUI"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "HudBarUI"; F.Parent = workspace
	local CLIENT = [==[
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
local PANEL_Y = isMobile and 114 or 64          -- phones keep room for the Hint button under the icons
local PANEL, CREAM, GOLD, DIM = C(38, 30, 52), C(255, 246, 220), C(255, 214, 90), C(120, 110, 140)

-- ---------------------------------------------------------------- the areas ----
-- world rectangles (the same ones the boundary walls use), the order you travel them, and what unlocks each
local AREAS = {
	{id = "forest",  x0 = -130, x1 = 142, z0 = -215, z1 = 25,  needs = nil},
	{id = "village", x0 = 150,  x1 = 352, z0 = -205, z1 = 5,   needs = "forest"},
	{id = "domaine", x0 = 352,  x1 = 700, z0 = -250, z1 = 30,  needs = "village"},
}
local NAME, TOTAL = {}, {}
for _, m in ipairs(Registry.maps) do NAME[m.id] = m.name end
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1 end
local function unlocked(a) return (not a.needs) or (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED end
local function areaAt(pos)
	for _, a in ipairs(AREAS) do
		if pos.X >= a.x0 and pos.X <= a.x1 and pos.Z >= a.z0 and pos.Z <= a.z1 then return a end
	end
end

-- ---------------------------------------------------------------- the bar ----
pcall(function() pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor end)         -- phones stay in landscape, either way up
for _, g in ipairs(pg:GetChildren()) do if g.Name == "HudBar" then g:Destroy() end end        -- never two bars
local gui = Instance.new("ScreenGui"); gui.Name = "HudBar"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 6; gui.Parent = pg
local bar = Instance.new("Frame"); bar.Name = "Bar"; bar.AnchorPoint = Vector2.new(1, 0); bar.Position = UDim2.new(1, -10, 0, 8)
bar.Size = UDim2.fromOffset(160, 48); bar.BackgroundTransparency = 1; bar.Parent = gui
local layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = bar

local function iconButton(order, tip)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(48, 48); b.BackgroundColor3 = PANEL; b.BackgroundTransparency = 0.1
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

-- A squirrel in profile, using the GAME'S OWN mesh rather than an approximation assembled from rounded frames.
-- The frames version came out looking like a fluffy caterpillar: at thirty pixels a tail drawn as a row of
-- circles merges with the body and the head disappears. This is the actual squirrel, lit from nowhere and
-- flattened to one colour, so it reads as a true silhouette of the thing the inventory holds.
-- The squirrels face local -Z, so a camera out along local X sees one side-on.
local function squirrelIcon(parent, size, cx, cy)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "SquirrelIcon"
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromOffset(cx, cy)
	-- square and no larger than asked: the button is 48 across and the found-count owns the bottom of it,
	-- so an icon that overruns its size sits on top of the numbers
	vp.Size = UDim2.fromOffset(size, size)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.new(1, 1, 1)                             -- no shading at all: a flat cut-out shape
	vp.LightColor = Color3.new(0, 0, 0)
	vp.Parent = parent

	task.spawn(function()
		local src
		for attempt = 1, 60 do
			for _, o in ipairs(workspace:GetDescendants()) do
				if o:IsA("Model") and o.Name:sub(-6) == "_color" then
					for _, q in ipairs(o:GetDescendants()) do
						-- skip the wide ones; those are the squirrels posed lying down
						if q:IsA("MeshPart") and q.Size.X < 2.4 then src = q break end
					end
				end
				if src then break end
			end
			if src then break end
			task.wait(0.5)                                       -- the squirrels may not have loaded in yet
		end
		if not src or not vp.Parent then return end
		local m = src:Clone()
		for _, c in ipairs(m:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
		m.TextureID = ""                                         -- no fur texture; the shape is the whole point
		m.Color = CREAM
		m.Material = Enum.Material.SmoothPlastic
		m.Transparency = 0
		m.CFrame = CFrame.new()
		m.Parent = vp
		local cam = Instance.new("Camera")
		cam.FieldOfView = 26
		cam.Parent = vp
		vp.CurrentCamera = cam
		-- close enough that the squirrel fills its corner of the bar; at thirty pixels every one counts
		cam.CFrame = CFrame.lookAt(Vector3.new(m.Size.Magnitude * 1.72, 0, 0), Vector3.new())
	end)
end

local squirrelBtn = iconButton(1, "Squirrels")
squirrelIcon(squirrelBtn, 32, 24, 17)                            -- a squirrel for the squirrels; the acorn
                                                                 -- belongs to the purse beside it
local countTag = Instance.new("TextLabel"); countTag.AnchorPoint = Vector2.new(0.5, 1); countTag.Position = UDim2.new(0.5, 0, 1, -2); countTag.Size = UDim2.fromOffset(44, 14)
countTag.BackgroundTransparency = 1; countTag.Font = Enum.Font.FredokaOne; countTag.TextSize = 13; countTag.TextColor3 = GOLD; countTag.Text = "0"; countTag.Parent = squirrelBtn
local mapBtn = iconButton(2, "Map")
do                                                               -- a folded map: three panels, a route and a pin
	for i, tint in ipairs({C(228, 216, 186), C(214, 200, 166), C(228, 216, 186)}) do
		local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(9, i == 2 and 26 or 22); p.Position = UDim2.fromOffset(10 + (i - 1) * 10, i == 2 and 10 or 13)
		p.BackgroundColor3 = tint; p.BorderSizePixel = 0; p.Parent = mapBtn
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 2); c.Parent = p
	end
	local pin = Instance.new("Frame"); pin.Size = UDim2.fromOffset(8, 8); pin.Position = UDim2.fromOffset(26, 16); pin.BackgroundColor3 = C(214, 60, 60); pin.BorderSizePixel = 0; pin.Parent = mapBtn
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pin
end

-- ---- the acorn purse: a square LEFT of the two icons, showing what you have collected ----
-- Now a button: it opens the store. LayoutOrder 0 puts it leftmost - the row is right-aligned and lays its
-- children out in order.
local purse = Instance.new("TextButton")
purse.Name = "Purse"; purse.Size = UDim2.fromOffset(48, 48); purse.BackgroundColor3 = PANEL
purse.BackgroundTransparency = 0.1; purse.BorderSizePixel = 0; purse.LayoutOrder = 0
purse.Text = ""; purse.AutoButtonColor = false; purse.Parent = bar
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = purse
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Transparency = 0.35; st.Parent = purse
end
acorn(purse, 21, 24, 14)                                         -- the same acorn as the collectible on the ground
local purseCount = Instance.new("TextLabel")
purseCount.Name = "Count"; purseCount.AnchorPoint = Vector2.new(0.5, 1); purseCount.Position = UDim2.new(0.5, 0, 1, -3)
purseCount.Size = UDim2.fromOffset(44, 17); purseCount.BackgroundTransparency = 1
purseCount.Font = Enum.Font.FredokaOne; purseCount.TextSize = 15; purseCount.TextColor3 = GOLD
purseCount.Text = "0"; purseCount.Parent = purse

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
	sc.Scale = math.clamp(math.min((vp.Y - PANEL_Y - 16) / h, (vp.X * 0.52) / w), 0.45, 1)
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
task.spawn(function()
	hudGui = pg:WaitForChild("SquirrelHUD", 60)
	if not hudGui then return end
	hudPanel = hudGui:WaitForChild("Panel", 30)
	if not hudPanel then return end
	hudPanel.Position = UDim2.new(1, -10, 0, PANEL_Y)            -- below the bar (and the Hint button on phones)
	hudPanel.Visible = false
	hudPanel.AnchorPoint = Vector2.new(1, 0)
	fitPanel()
	hudPanel:GetPropertyChangedSignal("Size"):Connect(fitPanel)
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel) end
	for _, c in ipairs(hudGui:GetChildren()) do if c.Name == "Card" then fitCard(c) end end
	hudGui.ChildAdded:Connect(function(c)                        -- the card is rebuilt every time one is opened
		if c.Name == "Card" then task.defer(fitCard, c) end
	end)
end)
local function squirrelOpen() return hudPanel and hudPanel.Visible end

-- ---------------------------------------------------------------- the map panel ----
-- a drawn parchment chart (marketing/make_map.py, uploaded as an image); the names, tallies, the "?" covers over
-- areas you have not reached and the "you are here" dot are drawn on top of it
local MAP_ID = 127000767898563
local IMG_W, IMG_H, IMG_M = 1024, 560, 26                     -- the image, and the margin its world area starts at
local DISP_W = 560                                            -- how wide the chart is drawn in the panel
local DISP_H = DISP_W * IMG_H / IMG_W
local F = DISP_W / IMG_W
local WX0, WX1, WZ0, WZ1 = -130, 700, -250, 30
local IS = math.min((IMG_W - 2 * IMG_M) / (WX1 - WX0), (IMG_H - 2 * IMG_M) / (WZ1 - WZ0))
local IOX = (IMG_W - (WX1 - WX0) * IS) / 2
local IOZ = (IMG_H - (WZ1 - WZ0) * IS) / 2
local function toMap(x, z)                                    -- world -> panel pixels
	return (IOX + (x - WX0) * IS) * F, (IOZ + (z - WZ0) * IS) * F
end

local map = Instance.new("Frame"); map.Name = "MapPanel"; map.AnchorPoint = Vector2.new(1, 0); map.Position = UDim2.new(1, -10, 0, PANEL_Y)
map.Size = UDim2.fromOffset(DISP_W + 16, DISP_H + 48); map.BackgroundColor3 = PANEL; map.BackgroundTransparency = 0.08
map.BorderSizePixel = 0; map.Visible = false; map.Parent = gui
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = map
local ms = Instance.new("UIStroke"); ms.Color = GOLD; ms.Thickness = 2; ms.Parent = map
local here = Instance.new("TextLabel"); here.Size = UDim2.new(1, -20, 0, 26); here.Position = UDim2.new(0, 10, 0, 6); here.BackgroundTransparency = 1
here.Font = Enum.Font.FredokaOne; here.TextSize = 17; here.TextColor3 = CREAM; here.TextXAlignment = Enum.TextXAlignment.Left
here.Text = "You are here"; here.Parent = map
local chart = Instance.new("ImageLabel"); chart.Name = "Chart"; chart.Position = UDim2.new(0, 8, 0, 36)
chart.Size = UDim2.fromOffset(DISP_W, DISP_H); chart.BackgroundTransparency = 1; chart.Image = "rbxassetid://" .. MAP_ID
chart.ScaleType = Enum.ScaleType.Stretch; chart.Parent = map
local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0, 8); cc2.Parent = chart

local cards = {}
for _, a in ipairs(AREAS) do
	local x0, z0 = toMap(a.x0, a.z0)
	local x1, z1 = toMap(a.x1, a.z1)
	local holder = Instance.new("Frame"); holder.Name = a.id; holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(x0, z0); holder.Size = UDim2.fromOffset(x1 - x0, z1 - z0); holder.Parent = chart
	-- the cover that hides an area you have not reached
	local cover = Instance.new("Frame"); cover.Name = "Cover"; cover.Size = UDim2.fromScale(1, 1); cover.BackgroundColor3 = C(226, 208, 166)
	cover.BorderSizePixel = 0; cover.Parent = holder
	local cs = Instance.new("UIStroke"); cs.Color = C(150, 118, 74); cs.Thickness = 2; cs.Parent = cover
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Font = Enum.Font.Antique
	q.TextSize = 44; q.TextColor3 = C(126, 96, 58); q.Text = "?"; q.Parent = cover
	-- the name plate for an area you have reached
	local plate = Instance.new("Frame"); plate.Name = "Plate"; plate.AnchorPoint = Vector2.new(0.5, 0); plate.Position = UDim2.new(0.5, 0, 0, 4)
	plate.Size = UDim2.fromOffset(math.min(x1 - x0 - 8, 190), 34); plate.BackgroundColor3 = C(248, 240, 214); plate.BackgroundTransparency = 0.12
	plate.BorderSizePixel = 0; plate.Parent = holder
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = plate
	local pstroke = Instance.new("UIStroke"); pstroke.Color = C(150, 118, 74); pstroke.Thickness = 1; pstroke.Parent = plate
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Size = UDim2.new(1, -6, 0, 17); title.Position = UDim2.new(0, 3, 0, 2)
	title.BackgroundTransparency = 1; title.Font = Enum.Font.Antique; title.TextSize = 15; title.TextColor3 = C(88, 58, 32)
	title.TextScaled = false; title.Parent = plate
	local tally = Instance.new("TextLabel"); tally.Name = "Tally"; tally.Size = UDim2.new(1, -6, 0, 13); tally.Position = UDim2.new(0, 3, 0, 18)
	tally.BackgroundTransparency = 1; tally.Font = Enum.Font.FredokaOne; tally.TextSize = 12; tally.TextColor3 = C(120, 84, 44); tally.Parent = plate
	cards[a.id] = {cover = cover, plate = plate, title = title, tally = tally}
end

local dot = Instance.new("Frame"); dot.Name = "You"; dot.Size = UDim2.fromOffset(13, 13); dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = C(210, 50, 50); dot.BorderSizePixel = 0; dot.ZIndex = 6; dot.Parent = chart
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
local ds = Instance.new("UIStroke"); ds.Color = C(252, 246, 230); ds.Thickness = 2; ds.Parent = dot
local ring = Instance.new("Frame"); ring.Size = UDim2.fromOffset(26, 26); ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.5, 0.5)
ring.BackgroundTransparency = 1; ring.ZIndex = 5; ring.Parent = dot
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
local rs = Instance.new("UIStroke"); rs.Color = C(210, 70, 70); rs.Thickness = 2; rs.Transparency = 0.4; rs.Parent = ring

local function refreshMap()
	for _, a in ipairs(AREAS) do
		local card = cards[a.id]
		local open = unlocked(a)
		card.cover.Visible = not open
		card.plate.Visible = open
		if open then
			card.title.Text = NAME[a.id] or a.id
			local found = player:GetAttribute("Found_" .. a.id) or 0
			card.tally.Text = string.format("%d / %d found", found, TOTAL[a.id] or 0)
		end
	end
end
local function refreshCount()
	local n = player:GetAttribute("SquirrelsFound") or 0
	local all = #Registry.squirrels
	countTag.Text = string.format("%d/%d", n, all)
end

-- ---------------------------------------------------------------- opening and closing ----
local function setSquirrels(open)
	if hudPanel then hudPanel.Visible = open end
	if open then map.Visible = false end
end
local function setMap(open)
	map.Visible = open
	if open then refreshMap(); if hudPanel then hudPanel.Visible = false end end
end
squirrelBtn.Activated:Connect(function() setSquirrels(not squirrelOpen()) end)
mapBtn.Activated:Connect(function() setMap(not map.Visible) end)
for _, a in ipairs(AREAS) do
	if a.needs then player:GetAttributeChangedSignal("Found_" .. a.needs):Connect(refreshMap) end
	player:GetAttributeChangedSignal("Found_" .. a.id):Connect(refreshMap)
end
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
	mapScale.Scale = math.clamp(math.min((vp.X - 30) / (DISP_W + 16), (vp.Y - PANEL_Y - 16) / (DISP_H + 48)), 0.5, 1)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMap) end
fitMap()

-- the "you are here" dot follows the player while the map is open
RunService.RenderStepped:Connect(function()
	if not map.Visible then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then dot.Visible = false; return end
	local p = root.Position
	local cx, cz = toMap(math.clamp(p.X, WX0, WX1), math.clamp(p.Z, WZ0, WZ1))
	dot.Visible = true
	dot.Position = UDim2.fromOffset(cx, cz)
	local a = areaAt(p)
	here.Text = a and ("You are here: " .. (NAME[a.id] or a.id)) or "You are here"
	rs.Transparency = 0.25 + 0.35 * math.abs(math.sin(os.clock() * 2))
end)
]==]
	local s = Instance.new("Script"); s.Name = "HudBarClient"; s.RunContext = Enum.RunContext.Client; s.Source = CLIENT; s.Parent = F
	print("HudBar installed: acorn + map icons top right, both panels start closed")
end

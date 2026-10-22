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
-- (shelf2, Oct 22 2026) tap or click a trophy to look closer (the card at "look closer" below); the light under the
-- crown is a soft white now (the warm one turned the gold orange - Shannon: "they look orangy").
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
-- RS.TrophyModels (Acorn, Key, Rescue; shelf2: the gold's shine is baked into their colour maps, no metal maps - many
-- devices draw only the colour, and the metal-only gold went flat orange there), about 0.8 tall; the acorn on a slim walnut base
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

-- ---------- look closer (shelf2, Oct 22 2026) ----------
-- Shannon: "can we also make them so if you click on them it zooms in and makes them bigger so its easier to see them
-- well?" Tap or click a trophy: a card like the portrait viewer's zooms in on it, big and slowly turning (drag it to turn
-- it yourself), with its name and what it was for. × / Esc / any other panel closes it. Not in VR (headsets draw
-- ViewportFrames unreliably - lean in instead).
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local pg = player:WaitForChild("PlayerGui")
local ABOUT = {
	keeper = {title = "Keeper of the Great Acorn", model = "Acorn", line = "First to find all 44 squirrels in French Squirrel Country that day."},
	rescue = {title = "Swamp Rescue", model = "Rescue", yaw = 180, line = "For freeing Madame Margaux's babies from Croque Monsieur's swamp."},
	guardian = {title = "Guardian of the Harbour", model = "Key", line = "First to find all 44 squirrels in Porto Nocciola that day."},
}
local viewer = Instance.new("ScreenGui"); viewer.Name = "TrophyViewer"; viewer.IgnoreGuiInset = true; viewer.ResetOnSpawn = false
viewer.DisplayOrder = 10; viewer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; viewer.Parent = pg
local page = Instance.new("Frame"); page.Name = "Page"; page.AnchorPoint = Vector2.new(0.5, 0); page.BackgroundColor3 = C(255, 246, 220)
page.BorderSizePixel = 0; page.Active = true; page.Visible = false; page.Parent = viewer
local function rounded(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end
rounded(page, 16)
local outline = Instance.new("UIStroke"); outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; outline.Color = C(233, 184, 65); outline.Thickness = 3; outline.Parent = page
local foil = Instance.new("UIGradient"); foil.Color = ColorSequence.new(C(193, 132, 34), C(255, 231, 147)); foil.Rotation = 35; foil.Parent = outline
local pop = Instance.new("UIScale"); pop.Parent = page
local view = Instance.new("ViewportFrame"); view.Name = "Trophy"; view.BackgroundColor3 = C(250, 244, 230); view.BorderSizePixel = 0
view.Ambient = C(165, 160, 150); view.LightColor = C(255, 250, 240); view.LightDirection = Vector3.new(-0.5, -1, -0.7); view.Parent = page
rounded(view, 10)
local inner = Instance.new("UIStroke"); inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; inner.Color = C(184, 135, 44); inner.Thickness = 2; inner.Parent = view
local vcam = Instance.new("Camera"); vcam.FieldOfView = 30; vcam.Parent = view; view.CurrentCamera = vcam
local function text(name, size, col, font)
	local t = Instance.new("TextLabel"); t.Name = name; t.Font = font; t.TextScaled = true; t.TextColor3 = col; t.BackgroundTransparency = 1
	t.TextXAlignment = Enum.TextXAlignment.Left; t.TextYAlignment = Enum.TextYAlignment.Top; t.TextWrapped = true; t.Text = ""; t.Parent = page
	local k = Instance.new("UITextSizeConstraint"); k.MaxTextSize = size; k.MinTextSize = 10; k.Parent = t
	return t
end
local heading = text("Heading", 22, C(64, 42, 22), Enum.Font.FredokaOne)
local about = text("About", 17, C(113, 79, 45), Enum.Font.BuilderSans)
local hint = text("Hint", 13, C(150, 116, 76), Enum.Font.BuilderSans); hint.Text = "Drag to turn it"
local close = Instance.new("TextButton"); close.Name = "Close"; close.Text = "×"; close.Font = Enum.Font.FredokaOne; close.TextSize = 25
close.TextColor3 = C(64, 42, 22); close.BackgroundColor3 = C(237, 223, 195); close.BorderSizePixel = 0; close.Size = UDim2.fromOffset(44, 44)
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -8, 0, 8); close.Parent = page
rounded(close, 11)
local function fit()                                              -- (the portrait viewer's frame: clear of the top bar and the hotbar)
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local avail = math.max(120, math.min(520, vp.Y - 148))
	local side = vp.X < 600 and 154 or 190
	-- (and 150 clear of each side: the chase button on the left ends at 142, the gift / acorn column on the right starts
	-- 126 in - measured on a tablet in the Device Simulator, Oct 22)
	local s = math.floor(math.min(avail - 24, math.max(140, vp.X - 300 - side - 36)))
	local w, h = s + side + 36, s + 24
	page.Size = UDim2.fromOffset(w, h); page.Position = UDim2.new(0.5, 0, 0, 68 + math.floor((avail - h) / 2))
	view.Position = UDim2.fromOffset(12, 12); view.Size = UDim2.fromOffset(s, s)
	local x = s + 28
	heading.Position = UDim2.fromOffset(x, 58); heading.Size = UDim2.fromOffset(side - 8, 54)
	about.Position = UDim2.fromOffset(x, 116); about.Size = UDim2.fromOffset(side - 8, math.max(30, h - 148))
	hint.Position = UDim2.fromOffset(x, h - 28); hint.Size = UDim2.fromOffset(side - 8, 16)
end
local shownModel, spinConn
local spin, dragging, lastX, idleAt = 0, false, 0, 0
local function closeTrophy()
	page.Visible = false; dragging = false
	if spinConn then spinConn:Disconnect(); spinConn = nil end
	if shownModel then shownModel:Destroy(); shownModel = nil end
	if pg:GetAttribute("OpenPanel") == "trophy" then pg:SetAttribute("OpenPanel", nil) end
end
local function openTrophy(id)
	local a = ABOUT[id]
	local src = a and RS:FindFirstChild("TrophyModels") and RS.TrophyModels:FindFirstChild(a.model)
	local active = pg:GetAttribute("OpenPanel")
	if not src or (active and active ~= "trophy") then return end
	closeTrophy()
	local m = src:Clone(); m.Anchored = true; m.CFrame = CFrame.new(); m.Parent = view; shownModel = m
	heading.Text = a.title; about.Text = a.line
	pg:SetAttribute("OpenPanel", "trophy"); fit(); page.Visible = true
	local dist = (m.Size.Magnitude / 2) / math.sin(math.rad(vcam.FieldOfView / 2)) * 1.02   -- (the whole trophy in view as it turns)
	local dir = Vector3.new(0, 0.2, 1).Unit                       -- (from the front, a little above, like standing at the shelf)
	spin, idleAt = 0, 0
	local t0 = os.clock()
	pop.Scale = 0.8; TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	spinConn = RunService.RenderStepped:Connect(function(dt)
		if not dragging and os.clock() > idleAt then spin += dt * 30 end
		m.CFrame = CFrame.Angles(0, math.rad((a.yaw or 0) + spin), 0)
		local z = 1 + 0.7 * (1 - math.min(1, (os.clock() - t0) / 0.5)) ^ 2   -- (the zoom in: from further out to close)
		vcam.CFrame = CFrame.lookAt(dir * dist * z, Vector3.zero)
	end)
end
view.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true; lastX = input.Position.X
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		spin += (input.Position.X - lastX) * 0.6; lastX = input.Position.X
	end
end)
UIS.InputEnded:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		dragging = false; idleAt = os.clock() + 1.5                 -- (it turns on by itself again after a moment)
	end
end)
close.Activated:Connect(closeTrophy)
UIS.InputBegan:Connect(function(input, processed) if not processed and input.KeyCode == Enum.KeyCode.Escape then closeTrophy() end end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if pg:GetAttribute("OpenPanel") ~= "trophy" and page.Visible then closeTrophy() end end)
player.CharacterAdded:Connect(closeTrophy)
local camConn
local function cameraChanged()
	if camConn then camConn:Disconnect() end
	if workspace.CurrentCamera then camConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if page.Visible then fit() end end) end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged); cameraChanged()
local function lookCloser(tm, id)                                 -- the trophy (and its base) answer a tap or a click
	if UIS.VREnabled or not ABOUT[id] then return end
	for _, p in ipairs(tm:GetDescendants()) do if p:IsA("BasePart") then p.CanQuery = true end end
	tm:SetAttribute("TrophyId", id)
end
-- (a ClickDetector never fires on these parts: they are this screen's own, the server has never heard of them) a quick
-- tap or click - not a drag of the camera - that lands on a trophy within 32 studs of you
local downAt = {}
UIS.InputBegan:Connect(function(input, processed)
	if processed or UIS.VREnabled then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		downAt[input] = {pos = input.Position, t = os.clock()}
	end
end)
UIS.InputEnded:Connect(function(input)
	local d = downAt[input]; downAt[input] = nil
	if not d or os.clock() - d.t > 0.45 or (input.Position - d.pos).Magnitude > 14 or page.Visible then return end
	local cam = workspace.CurrentCamera
	local ray                                                     -- (the mouse's place counts the top bar, a touch's doesn't)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local at = UIS:GetMouseLocation(); ray = cam:ViewportPointToRay(at.X, at.Y)
	else
		ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
	end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 80, params)
	local m = hit and hit.Instance:FindFirstAncestorWhichIsA("Model")
	while m and not m:GetAttribute("TrophyId") do m = m:FindFirstAncestorWhichIsA("Model") end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if m and root and (root.Position - hit.Position).Magnitude <= 32 then openTrophy(m:GetAttribute("TrophyId")) end
end)

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
	for i, t in ipairs(got) do
		local tm = Instance.new("Model"); tm.Name = "Trophy_" .. t.id; tm.Parent = parent   -- (shelf2: each in its own model, to tap)
		t.build(tm, cf * CFrame.new((i - (#got + 1) / 2) * spacing, 0, 0))
		lookCloser(tm, t.id)
	end
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
	local glow = part(Vector3.new(0.2, 0.05, 0.2), WOOD_DARK, F0 * CFrame.new(0, H - 0.05, D - 0.2), parent)   -- a soft little light under the crown
	local l = Instance.new("PointLight"); l.Color = C(255, 244, 228); l.Range = 7; l.Brightness = 0.7; l.Shadows = false; l.Parent = glow   -- (shelf2: was C(255, 214, 160))
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

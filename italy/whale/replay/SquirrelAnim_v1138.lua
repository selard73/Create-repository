
-- SquirrelAnim (client): idle bones + reveal effect. Runs on the client because Bone.Transform must be set there.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function isSquirrelMesh(p)
	return p:IsA("MeshPart") and p:FindFirstChild("Tail2", true) ~= nil and p:FindFirstChild("Root", true) ~= nil
end
local function getTex(mesh)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then return sa.ColorMap end
	return mesh.TextureID
end
local function setTex(mesh, id)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then sa.ColorMap = id else mesh.TextureID = id end
end

local ev = ReplicatedStorage:WaitForChild("SquirrelFound", 30)
local sync = ReplicatedStorage:WaitForChild("SquirrelSync", 30)
local rng = Random.new()
local BLENDER_HEIGHT = 2.4
local ORDER = {"Root", "Chest", "Neck", "Head", "Tail1", "Tail2"}

local squirrels = {}     -- model -> state
local setCompanion
local ensureHud, updateCounter, addBadge, fillBadge, ensureBadges, openCard, closeCard, nameTag, faceCamera, makeViewport, circleWindow, openAlbum, closeAlbum   -- defined below
local CIRCLE = 46            -- portrait diameter inside a 62 px tile
local foundIds = {}        -- every id this player has found, on any map (from the server)
local function addSquirrel(model)
	if squirrels[model] then return end
	local mesh
	for _, p in ipairs(model:GetDescendants()) do if isSquirrelMesh(p) then mesh = p break end end
	if not mesh then return end
	local bones = {}
	for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	-- squirrel axes in the mesh's own frame: forward = root -> head, up = world up
	local fwdL = Vector3.new(0, 0, -1)
	if bones.Root and bones.Head then
		local f = bones.Head.WorldPosition - bones.Root.WorldPosition
		f = Vector3.new(f.X, 0, f.Z)
		if f.Magnitude > 0.05 then fwdL = mesh.CFrame:VectorToObjectSpace(f.Unit) end
	end
	local upL = mesh.CFrame:VectorToObjectSpace(Vector3.yAxis)
	local st = {
		mesh = mesh, bones = bones, fwdL = fwdL, upL = upL, leftL = upL:Cross(fwdL),
		t = rng:NextNumber(0, 10), lookYaw = 0, lookTarget = 0, lookTimer = rng:NextNumber(1, 4), tilt = 0, tiltTarget = 0,
		flick = 0, flickTimer = rng:NextNumber(4, 10), hop = 0, hopTimer = rng:NextNumber(8, 20),
		found = false, revealT = -1, want = {},
		noHead = model:GetAttribute("NoHeadAnim") == true or model:GetAttribute("NoTurn") == true,
		noTurn = model:GetAttribute("NoTurn") == true,
		idleHop = model:GetAttribute("IdleHop") == true or model:GetAttribute("Hops") == true,
		bouncy = model:GetAttribute("Bouncy") == true or mesh:GetAttribute("Bouncy") == true,
		driftDown = model:GetAttribute("DriftDown") == true, dr = nil, landed = false,
		home = mesh.CFrame,          -- where the place put him; a reset sends him back up there
	}
	squirrels[model] = st
end
local tracked = 0
local applyInitial      -- defined below
local function scan()
	local added = false
	for _, model in ipairs(CollectionService:GetTagged("Squirrel")) do
		if not squirrels[model] then addSquirrel(model); if squirrels[model] then added = true end end
	end
	if added then
		local n = 0
		for _ in pairs(squirrels) do n += 1 end
		tracked = n
		print("SquirrelAnim: tracking " .. n .. " squirrels")
		if applyInitial then task.defer(applyInitial) end
	end
end
-- tags can replicate after this script starts and the added-signal does not always fire for them, so keep looking
CollectionService:GetInstanceAddedSignal("Squirrel"):Connect(function() scan() end)
CollectionService:GetInstanceRemovedSignal("Squirrel"):Connect(function(model) squirrels[model] = nil end)
task.spawn(function()
	while true do scan(); task.wait(tracked == 0 and 0.5 or 3) end
end)

local function byId(id)
	for model, st in pairs(squirrels) do if model:GetAttribute("SquirrelId") == id then return model, st end end
end

-- start gray for everything this player has not found yet (per-player mode); shared mode already has the right texture
-- how far a squirrel's lowest corner sits above the ground below him
local function groundDropOf(mesh)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {mesh:FindFirstAncestorOfClass("Model") or mesh}
	local hit = workspace:Raycast(mesh.Position + Vector3.new(0, 4, 0), Vector3.new(0, -500, 0), rp)
	local gy = hit and hit.Position.Y or 0
	local lo = math.huge
	for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
		local w = mesh.CFrame:PointToWorldSpace(Vector3.new(sx * mesh.Size.X / 2, sy * mesh.Size.Y / 2, sz * mesh.Size.Z / 2))
		if w.Y < lo then lo = w.Y end
	end end end
	return lo - gy
end
-- upright, feet on the ground, keeping the way he is facing
local function setDown(mesh)
	local fl = Vector3.new(mesh.CFrame.LookVector.X, 0, mesh.CFrame.LookVector.Z)
	if fl.Magnitude < 0.05 then fl = Vector3.new(0, 0, -1) end
	local p = mesh.CFrame.Position
	mesh.CFrame = CFrame.lookAt(p, p + fl.Unit)
	mesh.CFrame = mesh.CFrame - Vector3.new(0, groundDropOf(mesh), 0)
end
applyInitial = function()
	local list = sync and sync:InvokeServer() or {}
	local foundSet = {}
	for _, id in ipairs(list) do foundSet[id] = true; foundIds[id] = true end
	local perPlayer = script.Parent:GetAttribute("PerPlayer") ~= false
	for model, st in pairs(squirrels) do
		local id = model:GetAttribute("SquirrelId")
		local gray, color = st.mesh:GetAttribute("GrayTexture"), st.mesh:GetAttribute("ColorTexture")
		if foundSet[id] then st.found = true; if color then setTex(st.mesh, color) end
			if st.driftDown and not st.landed then setDown(st.mesh); st.landed = true end
		elseif perPlayer and gray then setTex(st.mesh, gray) end
		setCompanion(model, foundSet[id] == true)
	end
	ensureHud(); ensureBadges(); updateCounter()
end
scan()

-- floating name tag: rises out of the squirrel with sparkles, holds, then fades
local TweenService = game:GetService("TweenService")
local Registry = require(script.Parent:WaitForChild("SquirrelRegistry"))
local regById, regOrder = {}, {}
for i, e in ipairs(Registry.squirrels) do regById[e.id] = e; regOrder[e.id] = i end
local function idOf(model) return model:GetAttribute("SquirrelId") or (model.Name:lower():gsub("_color$", "")) end
local function prettyName(model)
	local dn = model:GetAttribute("DisplayName")
	if dn and dn ~= "" then return dn end
	local e = regById[idOf(model)]
	if e then return e.name end
	local n = model.Name:gsub("_color$", ""):gsub("_gray$", ""):gsub("_", " ")
	n = n:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end)
	return n
end
-- ---- HUD: counter + a round face badge for every squirrel this player has found ----
local Players = game:GetService("Players")
local hud, grid, counter
local badges = {}
-- theme (Shannon's mock-up, Sep 17): navy panel in a dark rim with a neon cyan edge, tiles like pressed buttons, gold and
-- cyan ringed portraits with an acorn tag, dim "?" tiles for squirrels not found yet, a glossy yellow pill button
local RGB = Color3.fromRGB
local FACE, FACE_DEEP, RIM = RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)
local SLOT, SLOT_LO, SLOT_EDGE = RGB(228, 212, 179), RGB(210, 191, 153), RGB(162, 131, 90)
local EDGE, INK, INK_DIM = RGB(203, 150, 48), RGB(64, 42, 22), RGB(132, 108, 80)
local GOLD, GOLD_LIGHT, GOLD_DARK = RGB(255, 202, 62), RGB(255, 236, 150), RGB(190, 128, 22)
local BTN_INK, BTN_RIM = RGB(84, 48, 18), RGB(150, 98, 36)        -- the button lettering and its rim, in acorn brown
local BUTTON_GRADIENT = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 226, 96)), ColorSequenceKeypoint.new(0.3, RGB(251, 203, 38)), ColorSequenceKeypoint.new(0.7, RGB(238, 174, 22)), ColorSequenceKeypoint.new(1, RGB(212, 142, 10))})
local BTN_H = 38
local CREAM = RGB(255, 248, 225)
local PANEL = SLOT                                  -- mask tint: hides the square corners of each portrait, so it matches the tile
local TILE, COLS, HUD_W = 62, 5, 358
local PORTRAIT_ZOOM, PORTRAIT_DOWN = 1.15, 0.05    -- the coin shows head, shoulders and paws, not just the face
local hudHolder
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")                          -- the lettering the signs and the HUD use
local FONT_BUTTON = Font.new("rbxasset://fonts/families/FredokaOne.json")
local FONT_TEXT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local function maskId() return script.Parent:GetAttribute("MaskImage") or "rbxassetid://77268792392056" end
local function corner(parent, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = parent; return c end
local function stroke(parent, color, th, tr) local st = Instance.new("UIStroke"); st.Color = color; st.Thickness = th; st.Transparency = tr or 0; st.Parent = parent; return st end
local function gradient(parent, top, bottom, rot) local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(top, bottom); g.Rotation = rot or 90; g.Parent = parent; return g end
-- a faint cloudy texture over a surface (the built-in smoke tile) so panels and tiles read as material, not flat colour
local function texture(parent, z, tileSize, tr, radius, color)
	local t = Instance.new("ImageLabel"); t.Name = "Texture"; t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Image = TEXTURE; t.ScaleType = Enum.ScaleType.Tile; t.TileSize = UDim2.fromOffset(tileSize, tileSize); t.ImageTransparency = tr
	t.ImageColor3 = color or RGB(188, 158, 110); t.ZIndex = z; t.Parent = parent
	corner(t, radius)
	return t
end
-- panel: dark rim with a soft outer glow, the neon line, a navy face with a vertical sheen and texture.
-- Returns the face (content goes in it) and the rim (position and size go on it).
local function neonPanel(parent, z, radius)
	local rim = Instance.new("Frame"); rim.Name = "Rim"; rim.BackgroundColor3 = RIM; rim.ZIndex = z; rim.Parent = parent
	corner(rim, UDim.new(0, radius + 5)); stroke(rim, EDGE, 6, 0.8)
	local rp = Instance.new("UIPadding"); rp.PaddingTop = UDim.new(0, 5); rp.PaddingBottom = UDim.new(0, 5); rp.PaddingLeft = UDim.new(0, 5); rp.PaddingRight = UDim.new(0, 5); rp.Parent = rim
	local face = Instance.new("Frame"); face.Name = "Face"; face.Size = UDim2.fromScale(1, 1); face.BackgroundColor3 = FACE; face.ZIndex = z + 1; face.Parent = rim
	corner(face, UDim.new(0, radius)); stroke(face, EDGE, 3, 0.05)
	gradient(face, RGB(253, 247, 232), FACE_DEEP)
	texture(face, z + 1, 180, 0.9, UDim.new(0, radius))
	local sheen = Instance.new("Frame"); sheen.Name = "Sheen"; sheen.Size = UDim2.new(1, -10, 0, 70); sheen.Position = UDim2.fromOffset(5, 5)
	sheen.BackgroundColor3 = RGB(255, 255, 255); sheen.BackgroundTransparency = 0.94; sheen.ZIndex = z + 1; sheen.Parent = face
	corner(sheen, UDim.new(0, radius - 3)); gradient(sheen, RGB(255, 255, 255), FACE)
	return face, rim
end
-- a pressed tile a portrait sits in (flat colour on purpose: the portrait mask is tinted to match it)
local function tile(parent, size, z)
	local t = Instance.new("Frame"); t.Name = "Tile"; t.Size = UDim2.fromOffset(size, size); t.BackgroundColor3 = SLOT; t.ZIndex = z; t.Parent = parent
	corner(t, UDim.new(0, 12)); stroke(t, SLOT_EDGE, 2, 0.1)
	texture(t, z, 90, 0.93, UDim.new(0, 12))
	return t
end
-- a little acorn hanging off the bottom of a ring
local function acorn(parent, w, z)
	local a = Instance.new("Frame"); a.Name = "Acorn"; a.Size = UDim2.fromOffset(w, math.floor(w * 1.2)); a.AnchorPoint = Vector2.new(0.5, 0)
	a.Position = UDim2.new(0.5, 0, 1, -math.floor(w * 0.6)); a.BackgroundTransparency = 1; a.ZIndex = z; a.Parent = parent
	local nut = Instance.new("Frame"); nut.Size = UDim2.new(0.78, 0, 0.7, 0); nut.AnchorPoint = Vector2.new(0.5, 1); nut.Position = UDim2.new(0.5, 0, 1, 0)
	nut.BackgroundColor3 = RGB(206, 136, 62); nut.ZIndex = z; nut.Parent = a
	corner(nut, UDim.new(0.5, 0)); stroke(nut, RGB(92, 52, 18), 1, 0.15); gradient(nut, RGB(230, 164, 86), RGB(160, 96, 36))
	local cap = Instance.new("Frame"); cap.Size = UDim2.new(1, 0, 0.42, 0); cap.Position = UDim2.new(0, 0, 0.14, 0)
	cap.BackgroundColor3 = RGB(126, 76, 34); cap.ZIndex = z + 1; cap.Parent = a
	corner(cap, UDim.new(0.5, 0)); stroke(cap, RGB(70, 40, 14), 1, 0.15); gradient(cap, RGB(156, 100, 48), RGB(96, 56, 22))
	local stem = Instance.new("Frame"); stem.Size = UDim2.new(0.16, 0, 0.22, 0); stem.AnchorPoint = Vector2.new(0.5, 0); stem.Position = UDim2.new(0.5, 0, 0, 0)
	stem.BackgroundColor3 = RGB(88, 52, 20); stem.ZIndex = z; stem.Parent = a
	corner(stem, UDim.new(0.5, 0))
	return a
end
-- the chunky yellow pill button: saturated gold shaded like a tube (lemon highlight on top, amber below), a thick bright
-- cyan rim with a soft glow outside it, and big rounded teal lettering with a dark-teal edge and a shadow so it stands
-- off the button. The background stays white so the gradient shows its own colours (BackgroundColor3 multiplies it);
-- the lettering sits ABOVE the gloss strip so it stays crisp.
-- a glowing neon line on the edge of a rounded object: a bright core plus halo bands fading outward and inward.
-- UIStroke draws outward from its frame's edge, so inset frames put their bands inside the object.
local function neonEdge(target, z)
	-- concentric rings: each frame is expanded so its stroke starts where the previous one ends
	local function ring(expand, th, tr, col)
		local f = Instance.new("Frame"); f.Name = "Glow"; f.Size = UDim2.new(1, 2 * expand, 1, 2 * expand); f.Position = UDim2.fromOffset(-expand, -expand)
		f.BackgroundTransparency = 1; f.ZIndex = z; f.Parent = target
		corner(f, UDim.new(1, 0)); stroke(f, col, th, tr)
	end
	stroke(target, RGB(96, 58, 22), 1.5, 0.15)                     -- dark hairline between the yellow and the line
	ring(1.5, 2.5, 0, RGB(255, 231, 160))                         -- the teal line; no glow (Shannon: the line is enough)
end
local function pillButton(parent, text, height, textSize, z)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, height); b.BackgroundColor3 = RGB(255, 255, 255); b.Text = ""
	b.AutoButtonColor = false; b.ZIndex = z; b.Parent = parent
	corner(b, UDim.new(1, 0))
	local g = Instance.new("UIGradient"); g.Color = BUTTON_GRADIENT; g.Rotation = 90; g.Parent = b
	neonEdge(b, z)
	local gloss = Instance.new("Frame"); gloss.Size = UDim2.new(1, -26, 0.3, 0); gloss.Position = UDim2.new(0, 13, 0, 4); gloss.BackgroundColor3 = RGB(255, 250, 215)
	gloss.BackgroundTransparency = 0.78; gloss.ZIndex = z + 1; gloss.Parent = b
	corner(gloss, UDim.new(1, 0))
	-- molded-plastic lettering: the glyph face is shaded light teal (top) to deeper teal (bottom), and its outline is
	-- shaded the same way, pale along the top edges and dark along the bottom edges, so every letter reads as a lit,
	-- rounded solid. Underneath, a soft amber shadow (the yellow going darker) seats it on the button.
	local function glyphs(dx, dy, color, tr, zz)
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.Position = UDim2.fromOffset(dx, dy); l.BackgroundTransparency = 1
		l.Text = text; l.FontFace = FONT_BUTTON; l.TextSize = textSize; l.TextColor3 = color; l.TextTransparency = tr; l.ZIndex = zz; l.Parent = b
		return l
	end
	-- extruded lettering (Shannon's crop: the letters have squared-off side walls under the face, like pieces cut from
	-- a slab and set on the button). Copies of the text step down in the side colour to build the wall, a warm contact
	-- shadow pools under the wall, and the flat face goes on top with a hairline edge that is lit on top.
	local shade = glyphs(0, 3, RGB(176, 114, 16), 0.84, z + 2)
	local ss = Instance.new("UIStroke"); ss.Color = RGB(190, 124, 20); ss.Thickness = 1.5; ss.Transparency = 0.82; ss.LineJoinMode = Enum.LineJoinMode.Round; ss.Parent = shade
	local wall = {{0, 1, RGB(104, 62, 26)}}
	for i, w in ipairs(wall) do
		local side = glyphs(w[1], w[2], w[3], 0, z + 2 + i)
		local ws = Instance.new("UIStroke"); ws.Color = w[3]; ws.Thickness = 0.8; ws.LineJoinMode = Enum.LineJoinMode.Miter; ws.Parent = side
	end
	local label = glyphs(0, 0, RGB(255, 255, 255), 0, z + 6)
	local tg = Instance.new("UIGradient"); tg.Rotation = 90
	tg.Color = ColorSequence.new(RGB(88, 50, 20))                               -- flat face: the shading was doing too much
	tg.Parent = label
	local ls = Instance.new("UIStroke"); ls.Color = RGB(255, 255, 255); ls.Thickness = 1; ls.Transparency = 0.25; ls.LineJoinMode = Enum.LineJoinMode.Miter; ls.Parent = label
	local lg = Instance.new("UIGradient"); lg.Rotation = 90                     -- the face's squared edge: lit on top, side colour below
	lg.Color = ColorSequence.new(RGB(255, 246, 220))                            -- one clean cream hairline, not a bevel
	lg.Parent = ls
	b.MouseEnter:Connect(function() TweenService:Create(gloss, TweenInfo.new(0.12), {BackgroundTransparency = 0.6}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(gloss, TweenInfo.new(0.12), {BackgroundTransparency = 0.78}):Play() end)
	return b
end
-- a round yellow button with an x, for closing the album and the card
local function closeButton(parent, z, onClick)
	local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(34, 34); close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10); close.BackgroundColor3 = RGB(255, 255, 255); close.Text = "x"; close.AutoButtonColor = false
	close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = BTN_INK; close.ZIndex = z; close.Parent = parent
	corner(close, UDim.new(1, 0)); stroke(close, BTN_RIM, 2, 0.05)
	local g = Instance.new("UIGradient"); g.Color = BUTTON_GRADIENT; g.Rotation = 90; g.Parent = close
	close.MouseEnter:Connect(function() close.BackgroundColor3 = RGB(255, 255, 235) end)
	close.MouseLeave:Connect(function() close.BackgroundColor3 = RGB(255, 255, 255) end)
	close.MouseButton1Click:Connect(onClick)
	return close
end
ensureHud = function()
	if hud then return end
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	hud = Instance.new("ScreenGui"); hud.Name = "SquirrelHUD"; hud.ResetOnSpawn = false; hud.IgnoreGuiInset = true
	hud.DisplayOrder = 5; hud.Parent = pg
	-- sizes are set by hand in updateCounter (no AutomaticSize: the texture and sheen layers would feed back into it)
	hudHolder = Instance.new("Frame"); hudHolder.Name = "Panel"; hudHolder.AnchorPoint = Vector2.new(1, 0); hudHolder.Position = UDim2.new(1, -10, 0, 8)
	hudHolder.Size = UDim2.fromOffset(HUD_W, 200); hudHolder.BackgroundTransparency = 1; hudHolder.Parent = hud
	local face, rim = neonPanel(hudHolder, 1, 16)
	rim.Size = UDim2.fromScale(1, 1)
	local content = Instance.new("Frame"); content.Name = "Content"; content.Size = UDim2.fromScale(1, 1); content.BackgroundTransparency = 1; content.ZIndex = 3; content.Parent = face
	local ppad = Instance.new("UIPadding"); ppad.PaddingTop = UDim.new(0, 8); ppad.PaddingBottom = UDim.new(0, 10)
	ppad.PaddingLeft = UDim.new(0, 10); ppad.PaddingRight = UDim.new(0, 10); ppad.Parent = content
	local list = Instance.new("UIListLayout"); list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.Padding = UDim.new(0, 8); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = content
	counter = Instance.new("TextLabel"); counter.Name = "Counter"; counter.Size = UDim2.new(1, 0, 0, 22); counter.BackgroundTransparency = 1; counter.TextWrapped = true
	counter.FontFace = FONT; counter.TextScaled = true; counter.TextColor3 = INK; counter.TextXAlignment = Enum.TextXAlignment.Center; counter.Text = ""
	counter.ZIndex = 3; counter.LayoutOrder = 1; counter.Parent = content
	local ctc = Instance.new("UITextSizeConstraint"); ctc.MaxTextSize = 16; ctc.MinTextSize = 10; ctc.Parent = counter   -- one line shrinks to fit the panel
	stroke(counter, RGB(255, 250, 233), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
	grid = Instance.new("Frame"); grid.Name = "Badges"; grid.Size = UDim2.new(1, 0, 0, TILE)
	grid.BackgroundTransparency = 1; grid.LayoutOrder = 2; grid.ZIndex = 3; grid.Parent = content
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(TILE, TILE); gl.CellPadding = UDim2.fromOffset(4, 4)
	gl.FillDirection = Enum.FillDirection.Horizontal; gl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gl.StartCorner = Enum.StartCorner.TopLeft; gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
	local albumBtn = pillButton(content, "Open Album", BTN_H, 24, 3); albumBtn.LayoutOrder = 3
	albumBtn.MouseButton1Click:Connect(function() if album then closeAlbum() else openAlbum() end end)
end
updateCounter = function()
	if not counter then return end
	local n = 0
	for _, st in pairs(squirrels) do if st.found then n += 1 end end
	-- which map is the player standing in? (workspace.Zones holds one Part per map with a MapId attribute)
	local mapId = script.Parent:GetAttribute("MapId") or "forest"
	local zones = workspace:FindFirstChild("Zones")
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if zones and root then
		for _, z in ipairs(zones:GetChildren()) do
			if z:IsA("BasePart") and z:GetAttribute("MapId") then
				local rel = z.CFrame:PointToObjectSpace(root.Position)
				if math.abs(rel.X) <= z.Size.X / 2 and math.abs(rel.Z) <= z.Size.Z / 2 then mapId = z:GetAttribute("MapId") break end
			end
		end
	end
	local hereFound, hereTotal, all = 0, 0, 0
	for _, e in ipairs(Registry.squirrels) do
		if e.map == mapId then hereTotal += 1; if foundIds[e.id] then hereFound += 1 end end
	end
	for _ in pairs(foundIds) do all += 1 end
	local mapName = mapId
	for _, m in ipairs(Registry.maps) do if m.id == mapId then mapName = m.name end end
	local counts = string.format("%d / %d      All maps  %d / %d", hereFound, hereTotal, all, script.Parent:GetAttribute("AllTotal") or #Registry.squirrels)
	-- long map names get their own (wrapping) line so the counts are never pushed out of the panel
	if (utf8.len(mapName) or #mapName) > 28 then
		counter.Text = mapName .. string.char(10) .. counts
	else
		counter.Text = mapName .. "  " .. counts
	end
	-- the badge panel shows only the squirrels of the map the player is standing in
	local visible = 0
	for model, b in pairs(badges) do
		local e = regById[idOf(model)]
		b.cell.Visible = (e == nil) or (e.map == mapId)
		if b.cell.Visible then visible += 1 end
	end
	local rows = math.max(1, math.ceil(visible / COLS))
	local lines = select(2, counter.Text:gsub("\n", "")) + 1
	counter.Size = UDim2.new(1, 0, 0, 22 * lines)
	grid.Size = UDim2.new(1, 0, 0, rows * (TILE + 4) - 4)
	if hudHolder then hudHolder.Size = UDim2.fromOffset(HUD_W, 10 + 8 + 22 * lines + 8 + rows * (TILE + 4) - 4 + 8 + BTN_H + 10) end
end
-- ---- the card: full squirrel turning slowly, name, and a bio ----
local card, cardConn, cardInputs
closeCard = function()
	if cardConn then cardConn:Disconnect(); cardConn = nil end
	if cardInputs then for _, c in ipairs(cardInputs) do c:Disconnect() end; cardInputs = nil end
	if card then card:Destroy(); card = nil end
end
openCard = function(model, st)
	closeCard(); ensureHud()
	local mesh = st.mesh
	card = Instance.new("Frame"); card.Name = "Card"; card.Size = UDim2.fromScale(1, 1); card.BackgroundColor3 = Color3.new(0, 0, 0)
	card.BackgroundTransparency = 0.45; card.ZIndex = 20; card.Parent = hud
	local backdrop = Instance.new("TextButton"); backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundTransparency = 1; backdrop.Text = ""
	backdrop.ZIndex = 20; backdrop.Parent = card; backdrop.MouseButton1Click:Connect(closeCard)
	local panel, prim = neonPanel(card, 21, 22)
	prim.AnchorPoint = Vector2.new(0.5, 0.5); prim.Position = UDim2.fromScale(0.5, 0.5); prim.Size = UDim2.fromOffset(432, 566)
	local big = tile(panel, 326, 22); big.AnchorPoint = Vector2.new(0.5, 0); big.Position = UDim2.new(0.5, 0, 0, 16)
	local ring = circleWindow(big, 288, 22, true)
	ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.new(0.5, 0, 0.5, -6)
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(150, 150, 165); vp.LightColor = Color3.fromRGB(255, 252, 245); vp.LightDirection = Vector3.new(-0.5, -1, -0.4)
	vp.ZIndex = 24; vp.Parent = ring
	local copy = mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local color = mesh:GetAttribute("ColorTexture"); if color then setTex(copy, color) end
	copy.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView = 30; cam.Parent = vp; vp.CurrentCamera = cam
	local centre = mesh.Position
	local dist = mesh.Size.Magnitude * 1.3         -- close: fills the circle for a sharper render, the mask crops the spill that the whole squirrel, tail included, stays inside the circle
	local fwd = mesh.CFrame:VectorToWorldSpace(st.fwdL)
	local ang0 = math.atan2(fwd.X, fwd.Z)
	-- turntable: spins slowly on its own; click and drag on the squirrel to turn it yourself
	local UIS = game:GetService("UserInputService")
	local ang, elev = ang0, 0.22
	local dragging, lastPos, idle = false, nil, 0
	vp.Active = false
	local grab = Instance.new("TextButton"); grab.Name = "Spin"; grab.Size = UDim2.fromScale(1, 1)
	grab.BackgroundTransparency = 1; grab.Text = ""; grab.AutoButtonColor = false; grab.ZIndex = 25; grab.Parent = ring
	grab.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; lastPos = input.Position; idle = 0
		end
	end)
	local c1 = UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - lastPos; lastPos = input.Position
			ang -= d.X * 0.012
			elev = math.clamp(elev + d.Y * 0.006, -0.5, 0.9)
		end
	end)
	local c2 = UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	cardInputs = {c1, c2}
	cardConn = RunService.RenderStepped:Connect(function(dt)
		local off = Vector3.new(math.sin(ang), 0, math.cos(ang)) * dist + Vector3.new(0, dist * elev, 0)
		cam.CFrame = CFrame.lookAt(centre + off, centre)
	end)
	local hint = Instance.new("TextLabel"); hint.Size = UDim2.new(1, 0, 0, 16); hint.Position = UDim2.new(0, 0, 0, 350)
	hint.BackgroundTransparency = 1; hint.Text = "drag to spin"; hint.TextSize = 12
	hint.FontFace = FONT_TEXT; hint.TextColor3 = INK_DIM
	hint.ZIndex = 22; hint.Parent = panel
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -40, 0, 40); title.Position = UDim2.new(0, 20, 0, 368)
	title.BackgroundTransparency = 1; title.Text = prettyName(model); title.TextScaled = true
	title.FontFace = FONT; title.TextColor3 = RGB(58, 36, 16)                   -- darkest thing on the page, so it leads
	title.ZIndex = 22; title.Parent = panel
	local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 28; tc.Parent = title
	local bio = Instance.new("TextLabel"); bio.Size = UDim2.new(1, -44, 0, 120); bio.Position = UDim2.new(0, 22, 0, 414)
	bio.BackgroundTransparency = 1; bio.Text = model:GetAttribute("Bio") or ""; bio.TextWrapped = true; bio.TextScaled = true
	bio.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); bio.TextColor3 = INK
	bio.TextYAlignment = Enum.TextYAlignment.Top; bio.ZIndex = 22; bio.Parent = panel
	local bc = Instance.new("UITextSizeConstraint"); bc.MaxTextSize = 17; bc.MinTextSize = 11; bc.Parent = bio
	closeButton(panel, 23, closeCard)
	local sc = Instance.new("UIScale"); sc.Scale = 0.7; sc.Parent = prim
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- ---- the album: every squirrel on every map, opened from the "Album" button ----
local album
closeAlbum = function() if album then album:Destroy(); album = nil end end
openAlbum = function()
	closeAlbum(); ensureHud()
	album = Instance.new("Frame"); album.Name = "Album"; album.Size = UDim2.fromScale(1, 1); album.BackgroundColor3 = Color3.new(0, 0, 0)
	album.BackgroundTransparency = 0.45; album.ZIndex = 30; album.Parent = hud
	local backdrop = Instance.new("TextButton"); backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundTransparency = 1; backdrop.Text = ""
	backdrop.ZIndex = 30; backdrop.Parent = album; backdrop.MouseButton1Click:Connect(closeAlbum)
	local panel, rim = neonPanel(album, 31, 22)
	rim.AnchorPoint = Vector2.new(0.5, 0.5); rim.Position = UDim2.fromScale(0.5, 0.5); rim.Size = UDim2.new(0, 600, 0.82, 0)
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -80, 0, 44); title.Position = UDim2.new(0, 24, 0, 12)
	title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.TextSize = 28
	title.FontFace = FONT; title.TextColor3 = INK
	local all, allTotal = 0, script.Parent:GetAttribute("AllTotal") or #Registry.squirrels
	for _ in pairs(foundIds) do all += 1 end
	title.Text = string.format("Squirrel Album   %d / %d", all, allTotal); title.ZIndex = 33; title.Parent = panel
	stroke(title, RGB(255, 250, 233), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
	closeButton(panel, 34, closeAlbum)
	local scroll = Instance.new("ScrollingFrame"); scroll.Position = UDim2.new(0, 18, 0, 64); scroll.Size = UDim2.new(1, -36, 1, -80)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 6; scroll.ScrollBarImageColor3 = EDGE; scroll.ZIndex = 33
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(); scroll.Parent = panel
	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 12); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
	-- squirrels present on this map, by id, for faces and cards
	local here = {}
	for model, st in pairs(squirrels) do here[idOf(model)] = {model = model, st = st} end
	for mi, map in ipairs(Registry.maps) do
		local mapFound, mapTotal = 0, 0
		for _, e in ipairs(Registry.squirrels) do if e.map == map.id then mapTotal += 1; if foundIds[e.id] then mapFound += 1 end end end
		local section = Instance.new("Frame"); section.Size = UDim2.new(1, 0, 0, 0); section.AutomaticSize = Enum.AutomaticSize.Y
		section.BackgroundTransparency = 1; section.LayoutOrder = mi; section.ZIndex = 33; section.Parent = scroll
		local sl = Instance.new("UIListLayout"); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Padding = UDim.new(0, 6); sl.Parent = section
		local head = Instance.new("TextLabel"); head.Size = UDim2.new(1, 0, 0, 24); head.BackgroundTransparency = 1
		head.AutomaticSize = Enum.AutomaticSize.Y; head.TextWrapped = true; head.LayoutOrder = 1
		head.TextXAlignment = Enum.TextXAlignment.Left; head.TextSize = 18; head.ZIndex = 33
		head.FontFace = FONT; head.TextColor3 = INK
		head.Text = string.format("%s   %d / %d", map.name, mapFound, mapTotal); head.Parent = section
		stroke(head, RGB(255, 250, 233), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
		local grid = Instance.new("Frame"); grid.LayoutOrder = 2; grid.Size = UDim2.new(1, 0, 0, 0)
		grid.AutomaticSize = Enum.AutomaticSize.Y; grid.BackgroundTransparency = 1; grid.ZIndex = 33; grid.Parent = section
		local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(TILE + 6, TILE + 24); gl.CellPadding = UDim2.fromOffset(4, 6)
		gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
		local order = 0
		for _, e in ipairs(Registry.squirrels) do
			if e.map == map.id then
				order += 1
				local cell = Instance.new("Frame"); cell.BackgroundTransparency = 1; cell.LayoutOrder = order; cell.ZIndex = 33; cell.Parent = grid
				local isFound = foundIds[e.id] == true
				local t = tile(cell, TILE, 34); t.AnchorPoint = Vector2.new(0.5, 0); t.Position = UDim2.new(0.5, 0, 0, 0)
				local box = circleWindow(t, CIRCLE, 35, isFound)
				box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
				if isFound then acorn(box, 15, 44) end
				local h = here[e.id]
				if isFound and h then
					makeViewport(box, h.st, faceCamera(h.st))
				else
					local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1
					q.Text = isFound and e.name:sub(1, 1) or "?"; q.TextSize = isFound and 26 or 30
					q.FontFace = FONT; q.TextColor3 = isFound and INK or INK_DIM; q.TextTransparency = isFound and 0 or 0.15; q.ZIndex = 43; q.Parent = box
				end
				local name = Instance.new("TextLabel"); name.Size = UDim2.new(1, 0, 0, 20); name.Position = UDim2.new(0, 0, 0, TILE + 3)
				name.BackgroundTransparency = 1; name.Text = isFound and e.name or ""; name.TextWrapped = true; name.TextScaled = true
				name.FontFace = FONT_TEXT; name.TextColor3 = INK; name.ZIndex = 34; name.Parent = cell
				local nc = Instance.new("UITextSizeConstraint"); nc.MaxTextSize = 10; nc.MinTextSize = 7; nc.Parent = name
				if isFound and h then
					local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
					btn.ZIndex = 45; btn.Parent = cell
					btn.MouseButton1Click:Connect(function() closeAlbum(); openCard(h.model, h.st) end)
				end
			end
		end
	end
	local sc = Instance.new("UIScale"); sc.Scale = 0.85; sc.Parent = rim
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local badgeOrder = 0
-- per-squirrel framing tweaks (fractions of body height); a model's FaceDist / FaceUp / FaceCamUp attributes override
local FACE = setmetatable({}, {__index = function(_, name)
	for _, e in ipairs(Registry.squirrels) do if e.name == name and e.face then return e.face end end
	return nil
end})
faceCamera = function(st)
	-- portrait crop: head and shoulders fill the circle, the rest is hidden by the mask
	local mesh, model = st.mesh, st.mesh:FindFirstAncestorOfClass("Model")
	local H = mesh.Size.Y
	local fwd = mesh.CFrame:VectorToWorldSpace(st.fwdL)
	local left = Vector3.yAxis:Cross(fwd)
	local tw = (model and FACE[model:GetAttribute("DisplayName") or ""]) or {}
	local dist = ((model and model:GetAttribute("FaceDist")) or tw.dist or 1.35) * PORTRAIT_ZOOM
	local up = (model and model:GetAttribute("FaceUp")) or tw.up or 0
	local camUp = (model and model:GetAttribute("FaceCamUp")) or tw.camUp or 0.05
	local side = (model and model:GetAttribute("FaceSide")) or tw.side or 0
	local bottom = mesh.Position - Vector3.new(0, H / 2, 0)
	local centre = bottom + Vector3.new(0, (0.70 + up - PORTRAIT_DOWN) * H, 0) + fwd * (0.30 * H)
	-- centre sideways on where the head actually is (some squirrels lean or turn a little)
	if st.bones.Head then
		local d = st.bones.Head.WorldPosition - centre
		centre = centre + left * d:Dot(left)
	end
	centre = centre + left * (side * H)   -- per-squirrel sideways nudge (turned heads, big side tails)
	local cam = Instance.new("Camera"); cam.FieldOfView = 24
	cam.CFrame = CFrame.lookAt(centre + fwd * (dist * H) + Vector3.new(0, camUp * H, 0), centre)
	return cam
end
makeViewport = function(parent, st, cam)
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 200); vp.LightColor = Color3.fromRGB(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.ZIndex = parent.ZIndex + 2; vp.Parent = parent
	local copy = st.mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local color = st.mesh:GetAttribute("ColorTexture"); if color then setTex(copy, color) end
	copy.Parent = vp
	cam.Parent = vp; vp.CurrentCamera = cam
	return vp
end
-- the coin: a portrait window that sits proud of its tile. Layers, bottom up: drop shadow, dark disc, the 3D render
-- (makeViewport puts it at z + 2), the mask (transparent circle tinted like the tile), a soft cyan glow, the cyan ring,
-- the gold bevel (a gradient-lit stroke, light on top, dark amber below), a thin highlight on the inner lip.
-- Squirrels not found yet get a plain dim ring instead.
circleWindow = function(parent, size, z, found)
	local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(size, size); box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 0); box.BackgroundTransparency = 1; box.ZIndex = z; box.Parent = parent
	local function ringFrame(inset, zz)
		local f = Instance.new("Frame"); f.Size = UDim2.new(1, -2 * inset, 1, -2 * inset); f.Position = UDim2.fromOffset(inset, inset)
		f.BackgroundTransparency = 1; f.ZIndex = zz; f.Parent = box
		corner(f, UDim.new(1, 0))
		return f
	end
	if found then
		local shadow = ringFrame(-1, z); shadow.Name = "Shadow"; shadow.Position = UDim2.fromOffset(-1, 3)
		shadow.BackgroundColor3 = RGB(0, 0, 0); shadow.BackgroundTransparency = 0.5
	end
	local disc = Instance.new("Frame"); disc.Name = "Disc"; disc.Size = UDim2.fromScale(1, 1); disc.BackgroundColor3 = found and RGB(206, 230, 242) or SLOT_LO; disc.ZIndex = z + 1; disc.Parent = box
	corner(disc, UDim.new(1, 0))
	if found then gradient(disc, RGB(210, 234, 246), RGB(244, 233, 202)) end    -- sky at the top, warm ground below
	local mask = Instance.new("ImageLabel"); mask.Name = "Mask"; mask.Size = UDim2.fromScale(1, 1); mask.BackgroundTransparency = 1
	mask.Image = maskId(); mask.ImageColor3 = PANEL; mask.ScaleType = Enum.ScaleType.Fit; mask.ZIndex = z + 3; mask.Parent = box
	if found then
		stroke(ringFrame(3, z + 4), EDGE, 6, 0.78)                                  -- soft glow
		stroke(ringFrame(4, z + 5), EDGE, 2, 0.05)                                  -- the gold ring
		stroke(ringFrame(-1, z + 5), RGB(90, 56, 8), 1.5, 0.35)                     -- dark edge under the bevel
		local bevel = stroke(ringFrame(0, z + 6), GOLD, 4)
		local gg = Instance.new("UIGradient"); gg.Rotation = 90
		gg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 244, 190)), ColorSequenceKeypoint.new(0.35, RGB(252, 206, 70)), ColorSequenceKeypoint.new(1, RGB(160, 100, 16))})
		gg.Parent = bevel
		stroke(ringFrame(2, z + 7), RGB(255, 252, 230), 1, 0.55)                    -- highlight on the inner lip
	else
		stroke(ringFrame(1, z + 5), INK_DIM, 2, 0.45)
	end
	return box, disc, mask
end
addBadge = function(model, st)
	ensureHud()
	if badges[model] then return badges[model] end
	badgeOrder += 1
	local cell = Instance.new("Frame"); cell.Name = model.Name; cell.BackgroundTransparency = 1; cell.LayoutOrder = badgeOrder; cell.ZIndex = 3; cell.Parent = grid
	local t = tile(cell, TILE, 3)
	local box = circleWindow(t, CIRCLE, 4, false)
	box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Text = "?"
	q.FontFace = FONT; q.TextSize = 30; q.TextColor3 = INK_DIM; q.TextTransparency = 0.15; q.ZIndex = 12; q.Parent = box
	local b = {cell = cell, tile = t, box = box, filled = false}
	local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.ZIndex = 16; btn.Parent = cell
	btn.MouseButton1Click:Connect(function() if b.filled then openCard(model, st) end end)
	btn.MouseEnter:Connect(function() if b.filled then TweenService:Create(b.box, TweenInfo.new(0.15), {Position = UDim2.new(0.5, 0, 0.5, -4)}):Play() end end)
	btn.MouseLeave:Connect(function() if b.filled then TweenService:Create(b.box, TweenInfo.new(0.15), {Position = UDim2.new(0.5, 0, 0.5, -2)}):Play() end end)
	badges[model] = b
	updateCounter()
	return b
end
fillBadge = function(model, st)
	local b = addBadge(model, st)
	if b.filled then return end
	b.filled = true
	b.box:Destroy()                                   -- the "?" window goes; a proper coin takes its place
	local box = circleWindow(b.tile, CIRCLE, 4, true)
	box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
	b.box = box
	makeViewport(box, st, faceCamera(st))             -- z 6: over the disc (5), under the mask (7) and the rings (8 to 11)
	acorn(box, 15, 13)
	local scale = Instance.new("UIScale"); scale.Scale = 0.4; scale.Parent = b.cell
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	updateCounter()
end
ensureBadges = function()
	local list = {}
	for model, st in pairs(squirrels) do table.insert(list, {model = model, st = st}) end
	table.sort(list, function(a, b) return (regOrder[idOf(a.model)] or 999) < (regOrder[idOf(b.model)] or 999) end)
	for _, e in ipairs(list) do addBadge(e.model, e.st); if e.st.found then fillBadge(e.model, e.st) end end
end

nameTag = function(model, mesh)
	local folder = script.Parent
	local T = folder:GetAttribute("NameTagSeconds") or 3.2        -- seconds from appear to gone
	local RISE = 3.5
	local top = mesh.Position + Vector3.new(0, mesh.Size.Y * 0.5 + 0.5, 0)
	local anchor = Instance.new("Part"); anchor.Name = "NameTagAnchor"; anchor.Anchored = true; anchor.CanCollide = false
	anchor.CanQuery = false; anchor.CanTouch = false; anchor.Transparency = 1; anchor.Size = Vector3.new(3, 1.2, 3)
	anchor.Position = top; anchor.Parent = workspace
	local W, H = 120, 52
	local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(W, H); gui.AlwaysOnTop = true
	gui.MaxDistance = 150; gui.LightInfluence = 0; gui.Parent = anchor
	local function makeLabel(z)
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1
		l.Text = prettyName(model); l.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)
		l.TextWrapped = true; l.TextScaled = true; l.ZIndex = z; l.TextTransparency = 1; l.Parent = gui
		local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 13; c.MinTextSize = 8; c.Parent = l
		return l
	end
	local shadow = makeLabel(1)
	shadow.Position = UDim2.new(0, 2, 0, 3); shadow.TextColor3 = Color3.fromRGB(0, 0, 0)
	local ss = Instance.new("UIStroke"); ss.Thickness = 2; ss.Color = Color3.fromRGB(0, 0, 0); ss.Transparency = 1; ss.Parent = shadow
	local label = makeLabel(2)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0, 0, 0); stroke.LineJoinMode = Enum.LineJoinMode.Round; stroke.Transparency = 1; stroke.Parent = label
	-- sparkles: spawn on a sphere around the words and fly outward, big enough to read from a distance
	local function emitter(color, size, rate, life, speed)
		local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = color
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, size), NumberSequenceKeypoint.new(1, 0)})
		pe.Transparency = NumberSequence.new(0); pe.Lifetime = life; pe.Speed = speed
		pe.Shape = Enum.ParticleEmitterShape.Sphere; pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		pe.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward; pe.SpreadAngle = Vector2.new(25, 25)
		pe.Rate = rate; pe.LightEmission = 1; pe.LightInfluence = 0; pe.Brightness = 2
		pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-150, 150); pe.Drag = 2
		pe.Acceleration = Vector3.new(0, 1.5, 0); pe.ZOffset = 0.5; pe.Parent = anchor
		return pe
	end
	local gold = emitter(ColorSequence.new(Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 200, 90)), 0.9, 30, NumberRange.new(0.9, 1.6), NumberRange.new(2, 5))
	local white = emitter(ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 240, 255)), 0.6, 22, NumberRange.new(0.7, 1.3), NumberRange.new(1.5, 4))
	gold:Emit(60); white:Emit(40)
	-- straight up, fade in fast, fade out as it climbs
	local FADE_FROM = 0.25
	local t = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		local k = math.clamp(t / T, 0, 1)
		local ease = 1 - (1 - k) ^ 2
		anchor.Position = top + Vector3.new(0, RISE * ease, 0)
		local vis = math.clamp(1 - t / 0.3, 0, 1)                   -- fade in over 0.3 s
		if k > FADE_FROM then vis = math.max(vis, (k - FADE_FROM) / (1 - FADE_FROM)) end
		label.TextTransparency = vis; stroke.Transparency = vis
		shadow.TextTransparency = 0.55 + 0.45 * vis; ss.Transparency = 0.55 + 0.45 * vis
		if k > 0.55 then gold.Enabled = false; white.Enabled = false end
		if k >= 1 then conn:Disconnect(); task.delay(1.5, function() anchor:Destroy() end) end
	end)
end

-- a squirrel can have a Companion: a prop that turns to colour with him (the truffle hunter's pig)
setCompanion = function(model, found)
	local name = model and model:GetAttribute("Companion")
	if not name then return end
	local c = workspace:FindFirstChild(name)
	if not c then return end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("MeshPart") then
			local id = found and p:GetAttribute("ColorTexture") or p:GetAttribute("GrayTexture")
			if id then setTex(p, id) end
		end
	end
end

-- ---- the reveal that takes over the screen: starburst, the squirrel large, its name, then away into the menu ----
local revealGui
local function screenReveal(model, st)
	if revealGui then revealGui:Destroy(); revealGui = nil end
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	local cam0 = workspace.CurrentCamera
	local vpSize = cam0 and cam0.ViewportSize or Vector2.new(1280, 720)
	local S = math.min(vpSize.X, vpSize.Y)

	local gui = Instance.new("ScreenGui")
	gui.Name = "SquirrelReveal"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 9
	gui.Parent = pg
	revealGui = gui
	game:GetService("Debris"):AddItem(gui, 8)   -- a backstop: the overlay can never be left on screen

	-- everything lives in one square holder, so the flight to the menu is a single tween of this frame
	local hold = Instance.new("Frame"); hold.Name = "Hold"; hold.AnchorPoint = Vector2.new(0.5, 0.5)
	hold.Position = UDim2.fromScale(0.5, 0.46); hold.Size = UDim2.fromOffset(S * 0.5, S * 0.5)
	hold.BackgroundTransparency = 1; hold.Parent = gui
	local scale = Instance.new("UIScale"); scale.Scale = 0.55; scale.Parent = hold

	-- ---- the light behind: rings of gold fading outward, and a wheel of rays turning slowly ----
	local burst = Instance.new("Frame"); burst.Name = "Burst"; burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.fromScale(0.5, 0.5); burst.Size = UDim2.fromScale(1, 1)
	burst.BackgroundTransparency = 1; burst.ZIndex = 2; burst.Parent = hold
	for i, band in ipairs({{0.52, 0.3}, {0.68, 0.62}, {0.86, 0.82}, {1.06, 0.92}}) do
		local r = Instance.new("Frame"); r.AnchorPoint = Vector2.new(0.5, 0.5); r.Position = UDim2.fromScale(0.5, 0.5)
		r.Size = UDim2.fromScale(band[1], band[1]); r.BackgroundColor3 = GOLD; r.BackgroundTransparency = band[2]
		r.BorderSizePixel = 0; r.ZIndex = 2; r.Parent = burst
		corner(r, UDim.new(1, 0))
	end
	local rays = Instance.new("Frame"); rays.Name = "Rays"; rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5); rays.Size = UDim2.fromScale(1, 1); rays.BackgroundTransparency = 1
	rays.ZIndex = 3; rays.Parent = burst
	for i = 1, 12 do
		local ray = Instance.new("Frame"); ray.AnchorPoint = Vector2.new(0.5, 1)
		ray.Position = UDim2.fromScale(0.5, 0.5); ray.Size = UDim2.new(0.035, 0, 0.62, 0)
		ray.Rotation = (i - 1) * 30; ray.BackgroundColor3 = RGB(255, 236, 170); ray.BorderSizePixel = 0
		ray.ZIndex = 3; ray.Parent = rays
		gradient(ray, RGB(255, 245, 205), RGB(255, 210, 90), 90).Transparency =
			NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.45)})
	end

	-- ---- the squirrel, turning ----
	local frame = Instance.new("Frame"); frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.82, 0.82); frame.BackgroundTransparency = 1; frame.ZIndex = 5; frame.Parent = hold
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = RGB(188, 186, 196); vp.LightColor = RGB(255, 251, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.5)
	vp.ZIndex = 5; vp.Parent = frame
	local copy = st.mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local tex = st.mesh:GetAttribute("ColorTexture"); if tex then setTex(copy, tex) end
	copy.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView = 28; cam.Parent = vp; vp.CurrentCamera = cam
	local centre, dist = copy.Position, copy.Size.Magnitude * 1.45
	local fwd = copy.CFrame:VectorToWorldSpace(st.fwdL or Vector3.new(0, 0, 1))
	local ang = math.atan2(fwd.X, fwd.Z)

	-- ---- the name ----
	local name = Instance.new("TextLabel"); name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.fromScale(0.5, 0.86); name.Size = UDim2.new(1.5, 0, 0.16, 0)
	name.BackgroundTransparency = 1; name.Text = prettyName(model); name.TextScaled = true
	name.FontFace = FONT; name.TextColor3 = RGB(255, 250, 232); name.ZIndex = 7; name.Parent = hold
	local nsc = Instance.new("UITextSizeConstraint"); nsc.MaxTextSize = math.floor(S * 0.075); nsc.Parent = name
	local nst = stroke(name, RGB(74, 44, 18), math.max(2, S * 0.005), 0)
	nst.LineJoinMode = Enum.LineJoinMode.Round

	-- ---- sparks thrown outward ----
	for i = 1, 16 do
		local a = (i / 16) * math.pi * 2 + math.random() * 0.3
		local d = Instance.new("Frame"); d.AnchorPoint = Vector2.new(0.5, 0.5); d.Position = UDim2.fromScale(0.5, 0.5)
		local px = math.random(6, 13) / 1000 * S
		d.Size = UDim2.fromOffset(px, px); d.BackgroundColor3 = RGB(255, 236, 158); d.BorderSizePixel = 0
		d.ZIndex = 8; d.Parent = hold
		corner(d, UDim.new(1, 0))
		local far = 0.5 + (0.42 + math.random() * 0.3)
		TweenService:Create(d, TweenInfo.new(0.62 + math.random() * 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = UDim2.fromScale(0.5 + math.cos(a) * (far - 0.5) * 2, 0.5 + math.sin(a) * (far - 0.5) * 2),
			 BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2)}):Play()
	end

	-- ---- in, turn, then away into the acorn icon ----
	TweenService:Create(scale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	-- exactly one revolution over the hold, eased in and out, finishing back where it started - which is face-on,
	-- because ang was taken from the squirrel's own forward vector. Then it holds that pose for the flight.
	local HOLD = 2.2
	local spin, t = nil, 0
	spin = RunService.RenderStepped:Connect(function(dt)
		if not gui.Parent then spin:Disconnect() return end
		t = math.min(t + dt, HOLD)
		local k = t / HOLD
		local turn = (k * k * (3 - 2 * k)) * math.pi * 2
		rays.Rotation += dt * 9
		cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(ang + turn), 0.2, math.cos(ang + turn)) * dist, centre)
	end)

	local function menuIcon()                       -- the acorn in the HUD bar, if it is up
		local bar = pg:FindFirstChild("HudBar")
		local row = bar and bar:FindFirstChild("Bar")
		if not row then return nil end
		for _, c in ipairs(row:GetChildren()) do
			if c:IsA("TextButton") and c.LayoutOrder == 1 then return c end
		end
		return nil
	end

	task.delay(HOLD, function()
		if not gui.Parent then return end
		local icon = menuIcon()                     -- only to know the acorn is up; it is never touched
		-- the acorn sits in the top-right corner on every screen, so aim there by fraction: AbsolutePosition is
		-- reported in the inset-adjusted space and would send the squirrel sailing over the top of the screen
		local flight = TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		TweenService:Create(hold, flight, {Position = UDim2.fromScale(0.955, 0.052)}):Play()
		TweenService:Create(scale, flight, {Scale = 0.1}):Play()
		local fade = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, d in ipairs(hold:GetDescendants()) do
			if d:IsA("ViewportFrame") then TweenService:Create(d, flight, {ImageTransparency = 1}):Play()
			elseif d:IsA("TextLabel") then TweenService:Create(d, fade, {TextTransparency = 1}):Play()
			elseif d:IsA("UIStroke") then TweenService:Create(d, fade, {Transparency = 1}):Play()
			elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
				TweenService:Create(d, fade, {BackgroundTransparency = 1}):Play()
			end
		end
		task.delay(1.1, function()
			if spin then spin:Disconnect() end
			if gui then gui:Destroy() end
			if revealGui == gui then revealGui = nil end
		end)
	end)
end

local function reveal(model, st, again)            -- again: a find in the Forest Race, played out in the world only
	local mesh = st.mesh
	local color = mesh:GetAttribute("ColorTexture")
	st.found = true; st.revealT = 0; st.revealAt = os.clock()
	if st.driftDown and not st.landed then
		local drop = groundDropOf(mesh)
		if drop > 1 then
			st.dr = {t = 0, dur = 4.2, from = mesh.CFrame, drop = drop}
			st.revealT = -1
		end
	end
	if not again then                              -- the full-screen card and the badge belong to the first find
		task.spawn(function()                          -- the flourish must never be able to break a find
			local ok, err = pcall(screenReveal, model, st)
			if not ok then warn("SquirrelAnim: screen reveal failed - " .. tostring(err)) end
		end)
		task.delay(0.6, function() fillBadge(model, st) end)
	end
	-- sparkle burst in rainbow colours
	local att = Instance.new("Attachment"); att.Name = "RevealSparkle"; att.Parent = mesh
	att.Position = mesh.CFrame:PointToObjectSpace(mesh.Position + Vector3.new(0, mesh.Size.Y * 0.2, 0))
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 230, 90)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 170, 255)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 90, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 220))})
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new(0.1); pe.Lifetime = NumberRange.new(0.6, 1.1); pe.Speed = NumberRange.new(4, 8)
	pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.LightEmission = 0.8; pe.Parent = att
	pe:Emit(40)
	-- FoundSound: which sound a found squirrel rings, held as attributes on the folder so it can be changed
	-- without touching code. A SECTION can have its own: the Chateau's music is a busy French rap track and the
	-- ta-da fanfare disappeared underneath it, so that section rings a bright chime instead - chimes sit high in
	-- the spectrum, above where a rap vocal and its beat live, so they cut through rather than fight it.
	--     FoundSound_forest / _village / _domaine     a sound id for that section
	--     FoundVolume_forest / _village / _domaine    how loud, over that section's own music
	--     FoundSound / FoundVolume                    the fallback for a section with nothing set
	-- The x lines are the ones the music, the gates and the boundary all use, so the sound that rings always
	-- belongs to the music that is playing.
	local SF = script.Parent
	local zone = mesh.Position.X >= 353 and "domaine" or (mesh.Position.X >= 150 and "village" or "forest")
	local want = SF:GetAttribute("FoundSound_" .. zone) or SF:GetAttribute("FoundSound")
	local digits = want and tostring(want):match("%d+")
	local snd = Instance.new("Sound")
	snd.SoundId = digits and ("rbxassetid://" .. digits) or "rbxassetid://1845415163"
	snd.Volume = SF:GetAttribute("FoundVolume_" .. zone) or SF:GetAttribute("FoundVolume") or 0.9
	snd.PlaybackSpeed = 1; snd.RollOffMaxDistance = 60; snd.Parent = mesh; snd:Play()
	task.delay(0.15, function() if color then setTex(mesh, color) end; setCompanion(model, true) end)
	task.delay(4, function() att:Destroy(); snd:Destroy() end)
	nameTag(model, mesh)
end
if ev then
	ev.OnClientEvent:Connect(function(id)
		foundIds[id] = true
		local model, st = byId(id)
		if model and not st.found then reveal(model, st) end
		updateCounter()
	end)
end
-- THE FOREST RACE: a squirrel found again in a race rings and pops just as it did the first time (Shannon: "the
-- squirrels should still make a ding and an appear when you choose them, just like when you find them for the first
-- time"). The race client fires RaceFlourish with the id. Only for a squirrel already found for real: a race find that
-- is also the first ever gets the whole reveal from the server event above, and is not played twice.
local flourish = script.Parent:FindFirstChild("RaceFlourish")
if flourish then
	flourish.Event:Connect(function(id)
		local model, st = byId(id)
		if model and st and st.found and not (st.revealAt and os.clock() - st.revealAt < 2) then
			local ok, err = pcall(reveal, model, st, true)
			if not ok then warn("SquirrelAnim: race flourish failed - " .. tostring(err)) end
		end
	end)
end

-- bone posing in squirrel-space axes (same trick as the pup)
local function pose(st, name, pitch, yaw, roll, offF, offU, offL)
	local w = st.want[name]
	if not w then w = {0, 0, 0, 0, 0, 0}; st.want[name] = w end
	w[1] += pitch or 0; w[2] += yaw or 0; w[3] += roll or 0; w[4] += offF or 0; w[5] += offU or 0; w[6] += offL or 0
end
local function apply(st, fwdW, upW, leftW, scale)
	for _, name in ipairs(ORDER) do
		local b = st.bones[name]
		if b then
			local w = st.want[name]
			if not w then b.Transform = CFrame.identity
			else
				local parent = b.Parent
				local pw = (parent:IsA("Bone") and parent.TransformedWorldCFrame) or st.mesh.CFrame
				local R = (pw * b.CFrame).Rotation
				local lLeft, lUp, lFwd = R:VectorToObjectSpace(leftW), R:VectorToObjectSpace(upW), R:VectorToObjectSpace(fwdW)
				local off = R:VectorToObjectSpace((fwdW * w[4] + upW * w[5] + leftW * w[6]) * scale)
				b.Transform = CFrame.new(off) * CFrame.fromAxisAngle(lUp, math.rad(w[2])) * CFrame.fromAxisAngle(lLeft, math.rad(w[1])) * CFrame.fromAxisAngle(lFwd, math.rad(w[3]))
			end
		end
	end
end

task.spawn(function() while true do task.wait(2) if counter then updateCounter() end end end)
local cam = workspace.CurrentCamera
RunService.Heartbeat:Connect(function(dt)
	for model, st in pairs(squirrels) do
		local mesh = st.mesh
		if not mesh.Parent then squirrels[model] = nil continue end
		-- skip the maths for squirrels far from the camera
		if cam and (cam.CFrame.Position - mesh.Position).Magnitude > 180 then continue end
		st.t += dt
		local t = st.t
		local scale = mesh.Size.Y / BLENDER_HEIGHT
		local fwdW, upW, leftW = mesh.CFrame:VectorToWorldSpace(st.fwdL), mesh.CFrame:VectorToWorldSpace(st.upL), mesh.CFrame:VectorToWorldSpace(st.leftL)
		table.clear(st.want)
		local calm = st.found and 1 or 0.6          -- gray ones are a little sleepier
		-- breathing
		local isBouncy = st.bouncy or model:GetAttribute("Bouncy") == true
		local breathe = math.sin(t * 1.6) * 0.5 + 0.5
		if not isBouncy then
			pose(st, "Chest", -1.5 * breathe * calm, 0, 0, 0, 0.012 * breathe, 0)
			pose(st, "Root", 0, 0, 0, 0, 0.008 * math.sin(t * 1.6), 0)
		else
			-- Slower, higher pogo bounce with spring takeoff sound
			local CYCLE = 1.15
			local phase = t % CYCLE
			local groundDur = 0.22
			if phase < groundDur then
				local squashK = math.sin((phase / groundDur) * math.pi)
				pose(st, "Chest", squashK * 9, 0, 0)
				pose(st, "Tail1", -squashK * 6, 0, 0)
				pose(st, "Tail2", -squashK * 10, 0, 0)
				st.inAir = false
			else
				if not st.inAir then
					st.inAir = true
					local snd = mesh:FindFirstChild("PogoBounceSound")
					if not snd then
						snd = Instance.new("Sound")
						snd.Name = "PogoBounceSound"
						snd.SoundId = "rbxassetid://12222124"
						snd.Volume = 0.6
						snd.RollOffMinDistance = 8
						snd.RollOffMaxDistance = 50
						snd.RollOffMode = Enum.RollOffMode.InverseTapered
						snd.Parent = mesh
					end
					if cam and (cam.CFrame.Position - mesh.Position).Magnitude < 65 then
						snd:Play()
					end
				end
				local airU = (phase - groundDur) / (CYCLE - groundDur)
				local arc = 4 * airU * (1 - airU)
				local bounceH = arc * 0.95
				pose(st, "Root", 0, 0, 0, 0, bounceH, 0)
				pose(st, "Chest", -arc * 4, 0, 0)
				pose(st, "Tail1", arc * 16, 0, 0)
				pose(st, "Tail2", arc * 24, 0, 0)
			end
		end
		-- head: look around, tilt when curious
		st.lookTimer -= dt
		if st.lookTimer <= 0 then
			st.lookTarget = rng:NextNumber(-22, 22); st.lookTimer = rng:NextNumber(2, 5)
			st.tiltTarget = (rng:NextNumber() < 0.35) and rng:NextNumber(-12, 12) or 0
		end
		st.lookYaw += (st.lookTarget - st.lookYaw) * math.min(1, dt * 4)
		st.tilt += (st.tiltTarget - st.tilt) * math.min(1, dt * 3)
		if not st.noHead and not st.noTurn then
			pose(st, "Neck", 0, st.lookYaw * 0.35, 0)
			pose(st, "Head", math.sin(t * 0.9) * 1.5, st.lookYaw * 0.65, st.tilt)
		end
		-- tail: slow sway with a lag down the tail, plus a quick flick now and then
		if not st.noTurn then
			st.flickTimer -= dt
			if st.flickTimer <= 0 then st.flick = 1; st.flickTimer = rng:NextNumber(4, 11) end
			st.flick = math.max(0, st.flick - dt * 2.2)
			local sway1 = math.sin(t * 1.4) * 5 * calm
			local sway2 = math.sin(t * 1.4 - 0.9) * 8 * calm
			local fl = math.sin(st.flick * math.pi) * 18
			pose(st, "Tail1", sway1 * 0.4 + fl * 0.6, sway1, 0)
			pose(st, "Tail2", sway2 * 0.5 + fl, sway2, 0)
		end
		-- parachuting down to the ground after being found
		if st.dr then
			local d = st.dr
			d.t += dt
			local k = math.min(d.t / d.dur, 1)
			local ease = k * k * (3 - 2 * k)
			local fade = 1 - ease
			local base = d.from
			local sway = math.sin(d.t * 1.7) * fade * 0.9
			local pos = base.Position + Vector3.new(0, -d.drop * ease, 0)
				+ base.RightVector * sway + base.LookVector * (ease * 1.8)
			local fl = Vector3.new(base.LookVector.X, 0, base.LookVector.Z)
			if fl.Magnitude < 0.05 then fl = Vector3.new(0, 0, -1) end
			mesh.CFrame = CFrame.lookAt(pos, pos + fl.Unit)
				* CFrame.Angles(math.rad(-12 * fade), 0, math.rad(math.sin(d.t * 1.7 + 0.4) * fade * 5))
			if k >= 1 then
				setDown(mesh)
				st.dr = nil; st.landed = true; st.revealT = 0
			end
		end
		-- an occasional little hop (found squirrels only, or idleHop) and the reveal hop
		st.hopTimer -= dt
		if st.hopTimer <= 0 then
			if st.found or st.idleHop then st.hop = 1 end
			st.hopTimer = st.idleHop and rng:NextNumber(4, 8) or rng:NextNumber(10, 25)
		end
		st.hop = math.max(0, st.hop - dt * 3)
		local hopK = math.sin(st.hop * math.pi)
		if st.revealT >= 0 then
			st.revealT += dt
			local k = math.min(st.revealT / 0.9, 1)
			hopK = math.max(hopK, math.sin(k * math.pi) * 1.6)
			if k >= 1 then st.revealT = -1 end
		end
		if hopK > 0 then
			pose(st, "Root", 0, 0, 0, 0, 0.28 * hopK, 0)
			if not st.noTurn then
				pose(st, "Chest", -6 * hopK, 0, 0)
				pose(st, "Tail1", 12 * hopK, 0, 0); pose(st, "Tail2", 10 * hopK, 0, 0)
			end
		end
		apply(st, fwdW, upW, leftW, scale)
	end
end)
print("SquirrelAnim running")

-- ---- reset: the server wiped this player's finds, so put every squirrel back to gray and rebuild the HUD ----
do
	local resetEv = ReplicatedStorage:WaitForChild("SquirrelReset", 30)
	if resetEv then
		resetEv.OnClientEvent:Connect(function()
			for id in pairs(foundIds) do foundIds[id] = nil end
			for model, st in pairs(squirrels) do
				st.found = false
				if st.driftDown and st.home then          -- back into the air, chute still packed
					st.mesh.CFrame = st.home
					st.landed = false; st.dr = nil
				end
				local gray = st.mesh and st.mesh:GetAttribute("GrayTexture")
				if gray then setTex(st.mesh, gray) end
				setCompanion(model, false)
			end
			for model in pairs(badges) do badges[model] = nil end
			if hud then hud:Destroy() end
			hud, grid, counter = nil, nil, nil
			ensureHud(); ensureBadges(); updateCounter()
		end)
	end
end

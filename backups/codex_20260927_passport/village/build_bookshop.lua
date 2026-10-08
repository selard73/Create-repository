-- Bookshop: go INTO the Librairie. Shannon (Sep 24): "make it so that you can go into the bookstore ... make it look
-- like you are going through the door and then change it to a different space that looks like the inside".
-- Round 2 (her notes): "the shop front on the inside should mirror the shop front on the outside" - the street wall
-- is the Librairie's: the door on the same side at x 340.5 under the same arch with bars and a brass knob, the big
-- display window, the striped awning seen through it; "the lights are way way way too bright" (a third of the
-- light, daylight through the window instead); the books "sit weird ... wrong shape" (flat hardbacks now).
-- Round 3: "not big enough" (24 x 26 now, 11 high), "the lamp is stuck inside the shelf; the lamp has to have a base",
-- "the chair should be against the wall", "the counter should have a cash register", "more space between the right
-- side of the door and the window (more wall)" (2.3 studs of wall between them now).
-- Round 4: the armchair's Seat faced the backrest (a Seat sits you facing its front); the camera could be scrolled
-- out through the glass (the camera popper ignores parts over 25% transparent, so the glass is 0.2 now, and inside
-- the zoom is leashed to 16 studs); the counter stood 1.4 studs from the wall, now 3.2 so someone fits behind it.
--
-- The townhouse is one solid mesh, so the inside is a room built 300 studs straight up over the shop (still inside
-- the village's rectangle, so the music and the saved area carry on). A prompt on the street door fades the screen
-- to black and the server moves the character in; the door inside does the same back out.
-- THE BOOKS: three on a display table, each with a prompt. Owned books are ledger items (Item_book_<id>, once, bought
-- with acorns through AwardAcorns/AwardItems - nothing here touches the DataStore). Reading opens a book on screen:
-- two pages at a time, arrows, a close button, and Listen when the book has a narration audio id. The stories live in
-- the Books ModuleScript in workspace.Bookshop as plain text (blank line = new paragraph); the reader flows the text
-- into pages itself, so Shannon's own two stories go in as they are when she sends them.
-- Attributes on workspace.Bookshop: RoomX/Y/Z, DoorX/Y/Z, InX/Y/Z, OutX/Y/Z, FadeSeconds.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local C = Color3.fromRGB
	local rng = Random.new(opts.seed or 1901)
	local WOOD, PLANK, DARK = C(118, 84, 52), C(146, 108, 66), C(62, 42, 26)
	local CREAM, PLASTER, RUG, LEATHER, BRASS, IRON = C(255, 246, 220), C(214, 196, 164), C(150, 60, 56), C(96, 58, 40), C(218, 178, 88), C(46, 46, 51)
	local SPINES = {C(160, 48, 44), C(46, 92, 140), C(58, 120, 72), C(200, 150, 60), C(120, 70, 130), C(220, 110, 60), C(70, 70, 76), C(232, 214, 176)}

	local old = workspace:FindFirstChild("Bookshop"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "Bookshop"
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end

	-- ---------------------------------------------------------------- the street door ----
	-- the LIBRAIRIE sign hangs on townhouse_d at (334.8, 10.3, -139) looking +z; its door is under the awning at x 340.5
	local SX = opts.signX or 334.8                        -- the shop's centre line
	local DX = opts.doorX or 340.5
	local DZ = opts.doorZ or -139.15
	-- the Librairie itself (there is another townhouse_d further down the street), for its real colours
	local shop
	local props = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Props")
	if props then
		for _, m in ipairs(props:GetChildren()) do
			if m.Name == "townhouse_d" and m:IsA("Model") then
				local cf = m:GetBoundingBox()
				if math.abs(cf.Position.X - SX) < 12 then shop = m end
			end
		end
	end
	local function shopColour(name, fallback)
		local p = shop and shop:FindFirstChild(name, true)
		return (p and p:IsA("BasePart")) and p.Color or fallback
	end
	local FACADE = shopColour("Shopfront", C(214, 120, 140))
	local AWNING, STRIPE = shopColour("Awning", C(191, 115, 107)), shopColour("AwningStripe", C(247, 245, 237))
	local DOORC, GLASSC = shopColour("DoorShop", C(115, 82, 66)), shopColour("GlassDoor", C(199, 219, 235))
	local groundY = 0
	do
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
		local hit = workspace:Raycast(Vector3.new(DX, 5, DZ + 2), Vector3.new(0, -40, 0), rp)   -- from under the awning
		if hit then groundY = hit.Position.Y end
	end
	local doorPad = part("DoorPad", Vector3.new(4, 5.5, 0.6), CFrame.new(DX, groundY + 2.9, DZ), CREAM, nil, F)
	doorPad.Transparency = 1; doorPad.CanCollide = false; doorPad.CanQuery = false
	local mat = part("Doormat", Vector3.new(3.0, 0.12, 1.6), CFrame.new(DX, groundY + 0.06, DZ + 1.2), C(120, 40, 36), Enum.Material.Fabric)
	mat.CanCollide = false
	local enter = Instance.new("ProximityPrompt"); enter.Name = "EnterPrompt"; enter.ActionText = "Go inside"; enter.ObjectText = "Librairie"
	enter.KeyboardKeyCode = Enum.KeyCode.E; enter.HoldDuration = 0; enter.MaxActivationDistance = 8; enter.RequiresLineOfSight = false; enter.Parent = doorPad

	-- ---------------------------------------------------------------- the room ----
	-- roomier than the shop's footprint, but its street wall is still the Librairie's: the door where the real door
	-- is, the display window beside it; x is measured from the shop's centre line
	local W, D, H = opts.width or 24, opts.depth or 26, 11
	local O = Vector3.new(SX, opts.roomY or 300, DZ - 0.45 - D / 2)    -- floor centre; the street wall's inner face sits at the facade
	local room = Instance.new("Model"); room.Name = "Room"; room.Parent = F
	local function at(x, y, z) return CFrame.new(O.X + x, O.Y + y, O.Z + z) end
	local dxr = DX - SX                                   -- the door's x in room terms (+5.7)
	part("Floor", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, -0.3, 0), PLANK, Enum.Material.WoodPlanks, room)
	part("Ceiling", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, H + 0.3, 0), C(205, 195, 178), Enum.Material.SmoothPlastic, room)
	part("WallN", Vector3.new(W, H, 0.6), at(0, H / 2, -D / 2 - 0.3), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallE", Vector3.new(0.6, H, D + 1.2), at(W / 2 + 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallW", Vector3.new(0.6, H, D + 1.2), at(-W / 2 - 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)

	-- the street wall, painted the facade's colour: the display window (11 wide, y 1.4..8.4) with a good stretch of
	-- wall between it and the door (x 4.0..7.4), built in pieces
	local zS = D / 2 + 0.3
	local wx0, wx1, wy0, wy1 = -9.3, 1.7, 1.4, 8.4
	local ddx0, ddx1 = dxr - 1.7, dxr + 1.7
	local function wall(x0, x1, y0, y1) part("WallS", Vector3.new(x1 - x0, y1 - y0, 0.6), at((x0 + x1) / 2, (y0 + y1) / 2, zS), FACADE, Enum.Material.SmoothPlastic, room) end
	wall(-W / 2, W / 2, wy1, H)                           -- the band above the window and door
	wall(-W / 2, wx0, 0, wy1)                             -- west pier
	wall(wx0, wx1, 0, wy0)                                -- the stall riser under the window
	wall(wx1, ddx0, 0, wy1)                               -- between window and door
	wall(ddx0, ddx1, 0, wy1)                              -- the door is mounted on the wall (nothing but sky behind it)
	wall(ddx1, W / 2, 0, wy1)                             -- east pier
	-- the display window: one big pane of glass with a cream frame, two slim mullions, daylight coming through
	local pane = part("Window", Vector3.new(wx1 - wx0, wy1 - wy0, 0.25), at((wx0 + wx1) / 2, (wy0 + wy1) / 2, zS), GLASSC, Enum.Material.Glass, room)
	pane.Transparency = 0.2; pane.CastShadow = false          -- under 0.25, or the camera treats the glass as open air and scrolls out of the shop
	part("Frame", Vector3.new(0.4, wy1 - wy0 + 0.4, 0.8), at(wx0 - 0.1, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room)
	part("Frame", Vector3.new(0.4, wy1 - wy0 + 0.4, 0.8), at(wx1 + 0.1, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room)
	part("Frame", Vector3.new(wx1 - wx0 + 0.8, 0.4, 0.8), at((wx0 + wx1) / 2, wy1 + 0.1, zS), CREAM, Enum.Material.SmoothPlastic, room)
	part("Sill", Vector3.new(wx1 - wx0 + 0.8, 0.4, 1.0), at((wx0 + wx1) / 2, wy0 - 0.1, zS - 0.1), CREAM, Enum.Material.SmoothPlastic, room)
	for k = 1, 2 do part("Mullion", Vector3.new(0.25, wy1 - wy0, 0.5), at(wx0 + (wx1 - wx0) * k / 3, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	-- the awning outside the window, seen through the glass: red and white stripes sloping down to the street
	do
		local tilt = math.rad(37)
		local n, wA, cx = 12, 18, -1
		for i = 0, n - 1 do
			local sx = cx - wA / 2 + wA / n * (i + 0.5)
			local s = part("Awning", Vector3.new(wA / n + 0.02, 0.12, 4.0), at(sx, 7.85, zS + 2.05) * CFrame.Angles(tilt, 0, 0), (i % 2 == 0) and AWNING or STRIPE, Enum.Material.Fabric, room)
			s.CanCollide = false
		end
		part("AwningRod", Vector3.new(wA, 0.15, 0.15), at(cx, 6.55, zS + 3.8), IRON, Enum.Material.Metal, room).CanCollide = false
	end
	-- the arched door with its barred glass, on the wall (the real one is a leaf in the mesh; this is its twin)
	local doorZ = zS - 0.3
	local function arched(name, w, hStraight, thick, z, colour)
		-- solid, so the camera cannot sit inside the door when you arrive in front of it
		local slab = part(name, Vector3.new(w, hStraight, thick), at(dxr, hStraight / 2, z), colour, Enum.Material.Wood, room)
		part(name .. "Top", Vector3.new(thick, w, w), at(dxr, hStraight, z) * CFrame.Angles(0, math.rad(90), 0), colour, Enum.Material.Wood, room, Enum.PartType.Cylinder)
		return slab
	end
	arched("DoorFrame", 3.8, 5.3, 0.2, doorZ - 0.1, DOORC)
	local door = arched("Door", 3.4, 5.1, 0.2, doorZ - 0.2, C(78, 52, 40))
	local dglass = part("DoorGlass", Vector3.new(2.4, 3.2, 0.1), at(dxr, 4.6, doorZ - 0.32), GLASSC, Enum.Material.Glass, room); dglass.Transparency = 0.2
	for _, bx in ipairs({-0.6, 0, 0.6}) do part("Bar", Vector3.new(0.08, 3.2, 0.08), at(dxr + bx, 4.6, doorZ - 0.4), IRON, Enum.Material.Metal, room).CanCollide = false end
	part("Bar", Vector3.new(2.4, 0.08, 0.08), at(dxr, 4.6, doorZ - 0.4), IRON, Enum.Material.Metal, room).CanCollide = false
	for _, px in ipairs({-0.72, 0.72}) do part("Panel", Vector3.new(1.2, 1.7, 0.06), at(dxr + px, 1.5, doorZ - 0.32), C(92, 62, 46), Enum.Material.Wood, room).CanCollide = false end
	local knob = part("Knob", Vector3.new(0.3, 0.3, 0.3), at(dxr - 1.2, 3.6, doorZ - 0.42), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball); knob.CanCollide = false
	local exit = Instance.new("ProximityPrompt"); exit.Name = "ExitPrompt"; exit.ActionText = "Go outside"; exit.ObjectText = "Rue de Noisette"
	exit.KeyboardKeyCode = Enum.KeyCode.E; exit.HoldDuration = 0; exit.MaxActivationDistance = 7; exit.RequiresLineOfSight = false; exit.Parent = door

	-- the window display: a ledge behind the glass with stacks of new books and the NOUVEAUTES card, like outside
	do
		local ledgeZ = zS - 0.3 - 0.85
		local wc = (wx0 + wx1) / 2
		part("Ledge", Vector3.new(wx1 - wx0, 0.3, 1.6), at(wc, wy0 + 0.15, ledgeZ), WOOD, Enum.Material.Wood, room)
		local top = wy0 + 0.3
		local function flatStack(x, z, n, yaw)
			for i = 0, n - 1 do
				local b = part("Spine", Vector3.new(1.4, 0.26, 1.9), at(x, top + 0.13 + i * 0.27, z) * CFrame.Angles(0, math.rad(yaw + i * 5), 0), SPINES[rng:NextInteger(1, #SPINES)], Enum.Material.SmoothPlastic, room)
				b.CanCollide = false
			end
		end
		flatStack(wc - 4.4, ledgeZ, 3, -8); flatStack(wc - 1.8, ledgeZ + 0.1, 2, 6); flatStack(wc + 4.7, ledgeZ, 4, -4)
		for i = 0, 3 do   -- a row standing up, leaning a touch
			local b = part("Spine", Vector3.new(0.34, 1.9, 1.3), at(wc + 0.2 + i * 0.42, top + 0.95, ledgeZ) * CFrame.Angles(0, 0, math.rad(-6)), SPINES[(i * 3) % #SPINES + 1], Enum.Material.SmoothPlastic, room)
			b.CanCollide = false
		end
		local card = part("Card", Vector3.new(1.5, 0.9, 0.06), at(wc + 2.8, top + 0.45, ledgeZ - 0.6) * CFrame.Angles(0, math.rad(-8), 0), CREAM, Enum.Material.SmoothPlastic, room)
		card.CanCollide = false
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 80; sg.Parent = card
		local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(0.9, 0.7); tl.Position = UDim2.fromScale(0.05, 0.15); tl.BackgroundTransparency = 1; tl.Font = Enum.Font.Antique; tl.TextScaled = true; tl.TextColor3 = C(60, 44, 34); tl.Text = "Nouveaut" .. utf8.char(233) .. "s"; tl.Parent = sg
	end

	-- shelves: units along the back wall, the west wall and the east wall beyond the counter, packed with spines
	local function shelfUnit(cf, width)
		local unit = Instance.new("Model"); unit.Name = "Shelf"; unit.Parent = room
		local hgt, depth = 9.2, 1.3
		part("Side", Vector3.new(0.25, hgt, depth), cf * CFrame.new(-width / 2, hgt / 2, 0), WOOD, Enum.Material.Wood, unit)
		part("Side", Vector3.new(0.25, hgt, depth), cf * CFrame.new(width / 2, hgt / 2, 0), WOOD, Enum.Material.Wood, unit)
		part("Back", Vector3.new(width, hgt, 0.15), cf * CFrame.new(0, hgt / 2, depth / 2 - 0.05), DARK, Enum.Material.Wood, unit)
		local rows = 5
		for r = 0, rows do
			local y = 0.2 + r * (hgt - 0.4) / rows
			part("Board", Vector3.new(width, 0.2, depth), cf * CFrame.new(0, y, 0), WOOD, Enum.Material.Wood, unit)
			if r < rows then
				local x = -width / 2 + 0.25
				while x < width / 2 - 0.45 do
					local bw = rng:NextNumber(0.28, 0.5); local bh = rng:NextNumber(1.0, 1.4)
					if rng:NextNumber() > 0.08 then                     -- a gap now and then, where somebody took one
						local s = part("Spine", Vector3.new(bw, bh, depth - 0.35), cf * CFrame.new(x + bw / 2, y + 0.1 + bh / 2, -0.05), SPINES[rng:NextInteger(1, #SPINES)], Enum.Material.SmoothPlastic, unit)
						s.CanCollide = false
					end
					x += bw + 0.05
				end
			end
		end
		return unit
	end
	for _, x in ipairs({-8.7, -2.9, 2.9, 8.7}) do shelfUnit(at(x, 0, -D / 2 + 0.7) * CFrame.Angles(0, math.rad(180), 0), 5.5) end
	for _, z in ipairs({-8.5, -2.9}) do shelfUnit(at(-W / 2 + 0.7, 0, z) * CFrame.Angles(0, math.rad(-90), 0), 5.5) end
	shelfUnit(at(W / 2 - 0.7, 0, -8.5) * CFrame.Angles(0, math.rad(90), 0), 5.5)
	-- ceiling beams and three hanging lamps (the bulb sits under the shade so the shade does not glare)
	for _, z in ipairs({-8, 0, 8}) do part("Beam", Vector3.new(W, 0.5, 0.5), at(0, H - 0.25, z), DARK, Enum.Material.Wood, room) end
	for _, lx in ipairs({-6, 0, 6}) do
		part("Cord", Vector3.new(0.08, 2.2, 0.08), at(lx, H - 1.1, -3), DARK, Enum.Material.SmoothPlastic, room).CanCollide = false
		local shade = part("Lamp", Vector3.new(1.1, 2.2, 2.2), at(lx, H - 2.6, -3) * CFrame.Angles(0, 0, math.rad(90)), C(232, 196, 120), Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder)
		shade.CanCollide = false
		local bulb = part("Bulb", Vector3.new(0.2, 0.2, 0.2), at(lx, H - 3.5, -3), CREAM, nil, room); bulb.Transparency = 1; bulb.CanCollide = false; bulb.CanQuery = false
		local l = Instance.new("PointLight"); l.Brightness = opts.lampLight or 0.4; l.Range = 24; l.Color = C(255, 230, 180); l.Parent = bulb
	end
	-- the counter, a good stride out from the east wall so there is room to stand behind it, with a cash register
	-- and a stack of books
	local cx, cz = W / 2 - 4.0, -2.5
	part("Counter", Vector3.new(1.6, 3.2, 7), at(cx, 1.6, cz), WOOD, Enum.Material.Wood, room)
	part("CounterTop", Vector3.new(2.0, 0.2, 7.4), at(cx, 3.3, cz), DARK, Enum.Material.Wood, room)
	for i = 0, 2 do local b = part("Spine", Vector3.new(1.0, 0.24, 1.3), at(cx, 3.52 + i * 0.25, cz - 2.2) * CFrame.Angles(0, math.rad(i * 9), 0), SPINES[i + 2], Enum.Material.SmoothPlastic, room); b.CanCollide = false end
	do   -- the cash register: body, sloping keys toward the shopkeeper, a display facing the customer, a drawer, a paper roll
		local reg = Instance.new("Model"); reg.Name = "Register"; reg.Parent = room
		local rz, ty = cz + 2.0, 3.4
		local GREY, KEY = C(52, 54, 60), C(236, 230, 214)
		part("Body", Vector3.new(1.3, 0.75, 1.15), at(cx, ty + 0.375, rz), GREY, Enum.Material.Metal, reg)
		part("Drawer", Vector3.new(0.12, 0.34, 1.0), at(cx + 0.68, ty + 0.2, rz), C(70, 72, 80), Enum.Material.Metal, reg).CanCollide = false
		part("DrawerHandle", Vector3.new(0.06, 0.06, 0.4), at(cx + 0.77, ty + 0.2, rz), BRASS, Enum.Material.Metal, reg).CanCollide = false
		local keys = part("Keys", Vector3.new(0.7, 0.1, 0.9), at(cx + 0.25, ty + 0.85, rz) * CFrame.Angles(0, 0, math.rad(-18)), C(40, 42, 48), Enum.Material.SmoothPlastic, reg)
		keys.CanCollide = false
		for r = 0, 2 do
			for c = 0, 2 do
				local k = part("Key", Vector3.new(0.14, 0.1, 0.18), keys.CFrame * CFrame.new(-0.2 + r * 0.2, 0.08, -0.28 + c * 0.28), (r == 2 and c == 2) and C(200, 60, 50) or KEY, Enum.Material.SmoothPlastic, reg)
				k.CanCollide = false
			end
		end
		local screen = part("Screen", Vector3.new(0.1, 0.5, 0.95), at(cx - 0.5, ty + 1.0, rz) * CFrame.Angles(0, 0, math.rad(8)), C(20, 30, 28), Enum.Material.SmoothPlastic, reg)
		screen.CanCollide = false
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Left; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 100; sg.Parent = screen
		local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(0.9, 0.8); tl.Position = UDim2.fromScale(0.05, 0.1); tl.BackgroundTransparency = 1; tl.Font = Enum.Font.Code; tl.TextScaled = true; tl.TextColor3 = C(120, 255, 140); tl.Text = "25 acorns"; tl.Parent = sg
		local roll = part("Roll", Vector3.new(0.5, 0.36, 0.36), at(cx - 0.2, ty + 0.95, rz - 0.62), KEY, Enum.Material.SmoothPlastic, reg, Enum.PartType.Cylinder)
		roll.CFrame = at(cx - 0.2, ty + 0.95, rz - 0.62) * CFrame.Angles(0, math.rad(90), 0); roll.CanCollide = false
		part("Slip", Vector3.new(0.3, 0.5, 0.02), at(cx - 0.2, ty + 1.15, rz - 0.8) * CFrame.Angles(math.rad(-20), 0, 0), KEY, Enum.Material.SmoothPlastic, reg).CanCollide = false
	end
	-- the rug in the window's light, the armchair with its back to the west wall, the floor lamp beside it
	local rug = part("Rug", Vector3.new(8, 0.08, 6), at(-6.5, 0.04, 6), RUG, Enum.Material.Fabric, room); rug.CanCollide = false
	local chair = Instance.new("Model"); chair.Name = "Armchair"; chair.Parent = room
	local ccf = at(-W / 2 + 1.3, 0, 6.5) * CFrame.Angles(0, math.rad(90), 0)      -- faces into the room
	part("Seat", Vector3.new(2.6, 1.1, 2.4), ccf * CFrame.new(0, 0.9, 0), LEATHER, Enum.Material.Fabric, chair)
	part("Back", Vector3.new(2.6, 2.2, 0.6), ccf * CFrame.new(0, 2.4, -0.9), LEATHER, Enum.Material.Fabric, chair)
	part("Arm", Vector3.new(0.5, 1.0, 2.4), ccf * CFrame.new(-1.3, 1.9, 0), LEATHER, Enum.Material.Fabric, chair)
	part("Arm", Vector3.new(0.5, 1.0, 2.4), ccf * CFrame.new(1.3, 1.9, 0), LEATHER, Enum.Material.Fabric, chair)
	-- a Seat sits you facing its front (-z), so it is turned to face the chair's open side, away from the backrest
	local seat = Instance.new("Seat"); seat.Name = "Sit"; seat.Size = Vector3.new(2.2, 0.3, 2.0); seat.CFrame = ccf * CFrame.new(0, 1.6, 0.1) * CFrame.Angles(0, math.pi, 0); seat.Transparency = 1; seat.Anchored = true; seat.Parent = chair
	do
		local lx, lz = -W / 2 + 1.3, 9.8
		local base = part("LampBase", Vector3.new(0.16, 1.3, 1.3), at(lx, 0.08, lz) * CFrame.Angles(0, 0, math.rad(90)), BRASS, Enum.Material.Metal, room, Enum.PartType.Cylinder)
		base.CanCollide = false
		part("LampPole", Vector3.new(0.14, 5.4, 0.14), at(lx, 2.8, lz), BRASS, Enum.Material.Metal, room).CanCollide = false
		local fl = part("LampShade", Vector3.new(1.2, 1.6, 1.6), at(lx, 5.7, lz) * CFrame.Angles(0, 0, math.rad(90)), C(232, 196, 120), Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder)
		fl.CanCollide = false
		local fbulb = part("Bulb", Vector3.new(0.2, 0.2, 0.2), at(lx, 5.0, lz), CREAM, nil, room); fbulb.Transparency = 1; fbulb.CanCollide = false; fbulb.CanQuery = false
		local fll = Instance.new("PointLight"); fll.Brightness = opts.floorLight or 0.3; fll.Range = 14; fll.Color = C(255, 222, 160); fll.Parent = fbulb
	end

	-- ---------------------------------------------------------------- the display table and the three books ----
	part("Table", Vector3.new(9, 0.3, 3.4), at(0, 2.35, -3), WOOD, Enum.Material.Wood, room)
	for _, c in ipairs({{-4.1, -1.4}, {4.1, -1.4}, {-4.1, 1.4}, {4.1, 1.4}}) do part("TableLeg", Vector3.new(0.3, 2.2, 0.3), at(c[1], 1.1, -3 + c[2]), WOOD, Enum.Material.Wood, room) end
	local cloth = part("Cloth", Vector3.new(9.4, 0.06, 3.8), at(0, 2.53, -3), C(58, 90, 74), Enum.Material.Fabric, room); cloth.CanCollide = false
	local BOOKS = {
		{id = "crumbs", title = "The Spy Who Came In From the Crumbs", price = 25, cover = C(46, 92, 140), yaw = -6},
		{id = "story2", title = "La Tortue", price = 25, cover = C(160, 48, 44), yaw = 3},
		{id = "story3", title = "Picnic Pierre Will Not Come Down", price = 25, cover = C(58, 120, 72), yaw = -2},
	}
	for i, b in ipairs(BOOKS) do
		-- a flat hardback: bottom board, block of pages set in from the edges, top board, and a spine down the left
		local base = at((i - 2) * 2.8, 2.56, -3) * CFrame.Angles(0, math.rad(b.yaw), 0)
		local bottom = part("Board", Vector3.new(2.0, 0.08, 2.6), base * CFrame.new(0, 0.04, 0), b.cover, Enum.Material.SmoothPlastic, room); bottom.CanCollide = false
		local pages = part("Pages", Vector3.new(1.82, 0.3, 2.44), base * CFrame.new(0.06, 0.23, 0), CREAM, Enum.Material.SmoothPlastic, room); pages.CanCollide = false
		local book = part("Book_" .. b.id, Vector3.new(2.0, 0.08, 2.6), base * CFrame.new(0, 0.42, 0), b.cover, Enum.Material.SmoothPlastic, room); book.CanCollide = false
		local spine = part("Spine", Vector3.new(0.12, 0.46, 2.6), base * CFrame.new(-0.94, 0.23, 0), b.cover, Enum.Material.SmoothPlastic, room); spine.CanCollide = false
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Top; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 60; sg.Parent = book
		local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(0.8, 0, 0.7, 0); tl.Position = UDim2.new(0.15, 0, 0.15, 0); tl.BackgroundTransparency = 1; tl.Font = Enum.Font.Antique; tl.TextScaled = true; tl.TextWrapped = true; tl.TextColor3 = CREAM; tl.Text = b.title; tl.Rotation = opts.coverRotation or 90; tl.Parent = sg   -- the Top face's gui runs along z; 90 reads it from the room
		book:SetAttribute("BookId", b.id)
		local pr = Instance.new("ProximityPrompt"); pr.Name = "BookPrompt"; pr.ActionText = b.soon and "Coming soon" or ("Buy  -  " .. b.price .. " acorns"); pr.ObjectText = b.title
		pr.KeyboardKeyCode = Enum.KeyCode.E; pr.HoldDuration = 0; pr.MaxActivationDistance = 7; pr.RequiresLineOfSight = false; pr.Enabled = not b.soon; pr.Parent = book
		pr:SetAttribute("BookId", b.id)
	end

	-- ---------------------------------------------------------------- the stories ----
	local BOOKSRC = [==[
-- Books: the three books on the Librairie's table. text = the story (a blank line starts a new paragraph; the reader
-- flows it into pages; <i>..</i> and <b>..</b> work); audio = a narration sound id, or 0 for none yet; soon = still
-- being written. The source stays plain ASCII: "@e" becomes an e-acute and "--" an em dash when the module loads.
local E, EG, AC, DASH = utf8.char(233), utf8.char(232), utf8.char(226), utf8.char(8212)   -- e-acute, e-grave, a-circumflex, em dash
local function fix(s) return (s:gsub("@e", E):gsub("@g", EG):gsub("@b", AC):gsub("%-%-", DASH)) end
local books = {
	{id = "crumbs", title = "The Spy Who Came In From the Crumbs", by = "as told to G@erard the Mailman Squirrel", price = 25, audio = 0, text = [[
The International Spy Squirrel had a secret code name, a secret hideout and a secret handshake, and on Tuesday morning he forgot all three at once.

"Part of the cover," he told his reflection in the boulangerie window.

Behind the glass, the French Waiter Squirrel glided past with a tray held high on one paw. The tray was covered with a silver dome. A DOME. Nobody covers a croissant with a dome unless it is not a croissant.

The Spy narrowed his eyes. "Mission," he whispered, and pulled his beret down so far that he walked into a lamp post.

He tailed the tray across the Rue de Noisette.

Past the fountain, where the Bird Feeder Squirrel's pigeons saluted. Past the cafe, where the Philosopher Squirrel looked up from a cup he had been drinking since spring and asked, "If a secret can be smelled from the bridge, is it still a secret?"

The Spy did not answer. Spies do not answer. Also his stomach was making a noise like a small motorbike.

Outside the bookshop, Marcel the Mime pressed both paws against an invisible wall and mouthed something urgent. It was either "DANGER" or "BUTTER". It was hard to tell with Marcel.

At the corner the Waiter stopped, turned, and lifted the dome with a sigh so dramatic that three flowerpots wilted.

Underneath sat one warm croissant, golden as a medal.

"For you, monsieur," said the Waiter. "You have followed me for eleven minutes. In this town, that is practically a reservation."

The Spy took the croissant. He ate it in two bites, which is not how spies eat, but it had been a long morning.

That evening, in his secret hideout (the third bench on the left), he wrote his report:

MISSION ACCOMPLISHED. TARGET DELICIOUS. HANDSHAKE STILL MISSING.

Then he fell asleep with crumbs in his beret, which is how every good spy story ends.
]]},
	{id = "story2", title = "La Tortue", by = "by Shannon", price = 25, audio = 0, text = [[
In the village of Saint-Bidule, the mail arrived at 4 p.m., which was impressive, because it left the post office at 8 a.m. and the village had eleven houses.

This was because of G@erard.

G@erard was a gray squirrel who had delivered the mail for thirty-one years. He stopped to bury an acorn in every third flowerpot, and he believed every letter deserved to be read aloud to its recipient, with commentary.

"A postcard from your sister in Nice," he told Madame Fournier, holding it up to the light. "She says the pinecones are lovely. Her lowercase <i>g</i>, however, is a cry for help."

Madame Fournier snatched it and slammed her door shut. G@erard nodded, satisfied, and scampered up the hill to the last house on his route: the atelier of Margaux Delacroix-Pim, fashion designer and red squirrel.

Margaux was not having a good week.

Her show at Paris Fashion Week was in three days. She had nothing. Her floor was covered in chewed-up sketches, and pinned above her desk was the review that had haunted her for a year. It came from La Tortue, the most feared fashion critic among the squirrels of France, whom no one had ever seen. La Tortue had described her last collection in four words:

<i>"A beige apology. Pass."</i>

G@erard knocked. Margaux opened the door with a pencil behind each ear and a third in her tail.

"Acorn bill," G@erard announced. "The font is aggressive. I would not pay it."

"G@erard, I don't have time--"

He was already looking past her at the sketches. "Those tail sleeves," he said gently, "are too polite."

She shut the door on him.

* * *

That was when the tourist appeared.

His name was Dale, he was a fox squirrel from Tulsa, and he had arrived in France by stowing away in a family's carry-on bag, which he described as "a real nice flight, a little snug." He was wearing a white hotel bathrobe belted over cargo shorts, a sun visor, a fanny pack, one hiking boot, and one flip-flop. A souvenir beret sat on top of the visor. A paper map was knotted around his neck like a cape, flapping in the wind.

"Hi there!" Dale said. "The airline lost my luggage. Is this the way to the Eiffel Tower? I hear it's the tallest tree in France."

G@erard considered this. "It is 700 kilometers that way. And it is not a tree. Many have been disappointed."

"Well, shoot. Is it hoppable?"

Margaux's door flew open. She had seen Dale through the window, and she was staring at him the way other squirrels stare at a bird feeder.

"Don't. Move."

Dale froze, which, for a squirrel, is an emergency setting. "Is there a hawk?"

"The bathrobe," Margaux whispered. "Over the <i>cargo shorts</i>. The beret <i>on top</i> of the visor. One boot, one <i>flip-flop</i>. It's wrong in every way. It's <i>magnificent</i>."

She dragged Dale inside, sat him on a stool, and began sketching so fast her whiskers vibrated.

G@erard leaned in the doorway. "Make the visor bigger," he said.

"Nobody asked you, G@erard."

He shrugged and left. Margaux made the visor bigger.

* * *

Three days later, the lights went down on a park bench in the Jardin du Luxembourg, and the collection called <b>PERDUE</b> -- "Lost" -- came down the runway.

Squirrels in silk bathrobes. Squirrels in cashmere cargo shorts. A gown made entirely of folded maps. Visors so wide they cast shade on the front row. Every model wore one boot and one flip-flop, which made the walk sound like <i>clomp-flap, clomp-flap</i>, and gave the whole show the rhythm of a very confused horse.

The bench was silent.

Then a chipmunk editor from Milan stood up and began to applaud. Then everyone did.

Dale, in the front row in his same bathrobe, turned to the squirrel next to him. "I don't get it, but I love it."

She was taking notes on a leaf. "That's fashion, darling."

* * *

The next morning, Margaux was pacing her tiny Paris hotel room when there was a knock.

It was G@erard, holding a single envelope.

"G@erard? You're three hours from your route!"

"Special delivery," he said. "I rode in a baguette delivery truck. It was very slow. I felt at home."

Margaux tore open the envelope. Inside was a review, handwritten on the famous green leaf paper:

<i>"Finally, she was brave. Five stars. -- La Tortue."</i>

She read it twice. Then she studied the handwriting. The slanted capitals. The small, judgmental dot over the <i>i</i>.

She had seen that handwriting before. On a note stuck to her acorn bill last spring that read, <i>Pay this, but know that I disapprove of the font.</i>

Her tail puffed up to twice its size.

"<i>You're</i> La Tortue?"

G@erard adjusted his cap. "Every letter in France passes through a mail squirrel's paws. You learn a great deal about taste."

"But why a <i>turtle</i>?"

He gave her a long, patient look. "Madame. Have you seen how I deliver the mail?"

* * *

Dale hopped in to say goodbye, still in the bathrobe. G@erard reached into his mail pouch and pulled out a battered suitcase with a tag reading <i>DALE -- TULSA</i>.

"This arrived at my post office in March," he said.

"<i>March?</i> It's June!"

"The tag was written in Comic Sans. I needed time to recover."

Margaux held her breath as Dale unzipped it. This was it. The real Dale. The proper clothes. The end of the magic.

Dale lifted out a fresh white bathrobe. Then a second pair of cargo shorts. Then another visor, another beret, one hiking boot, and one flip-flop.

"Oh, thank goodness," Dale said. "My backups."

Margaux fell over sideways, the way squirrels do.

G@erard nodded approvingly. "Now <i>that</i>," he said, "is a squirrel who is not apologizing."
]]},
	{id = "story3", title = "Picnic Pierre Will Not Come Down", by = "as told by Sleepy Sylvain, who slept through it", price = 25, audio = 0, text = [[
Picnic Pierre climbed the windmill on a Tuesday with a baguette under one arm and a small round cheese under the other, and he did not come back down.

"Lunch tastes better up here," he called, from the very tip of the highest sail. "Also I cannot get down. But mostly the first thing."

By Wednesday the whole Ch@bteau had gathered at the bottom of the hill.

Farmer Fernand brought the tractor, in case a tractor helped. It did not help. The rooster crowed at Pierre several times, which was not so much a plan as a habit.

Grape Stomper Gigi stomped a great heap of grapes into a purple cushion at the foot of the mill, in case Pierre fell. "It is either a cushion or a jam," she said. "We will find out."

The Beekeeper sent up a bee with a message. The bee came back with crumbs on it. The message had not been read. The bee had been fed.

The Truffle Hunter's pig sniffed the windmill carefully from every side and then found a truffle, which was not the point, but was still quite a good truffle.

The Shepherd and his lamb stood together and looked worried. The lamb looked more worried. It is hard to say why.

Sleepy Sylvain slept through the entire thing on a hay bale and was, in the end, the only one who did not get sunburnt.

"Has anyone asked," said the Ch@gvre Squirrel from the well, "whether he <i>wants</i> to come down?"

Everybody looked at everybody else. Then everybody looked up.

"NO," said Pierre, and bit into his baguette, and the sail turned him gently out of sight.

* * *

On Thursday a small figure came puffing up the lavender path with a letter bag over his shoulder. It was G@erard, the mail squirrel from the village, and he had a postcard for Pierre.

"It is from his aunt in Lyon," G@erard told the crowd, holding it up to the light. "She hopes he is eating well. The exclamation marks are excessive. Three, for a postcard. Who does she think she is?"

"He is up there," said Gigi, pointing.

G@erard looked at the sail. Then he took off his cap, tucked it into his bag, waited for the lowest arm to sweep past, and grabbed on.

The Ch@bteau watched a mail squirrel go all the way round a windmill, upside down at the top, holding a postcard in his teeth and giving no sign whatsoever that this was unusual.

At the tip of the highest sail he handed Pierre the postcard, read it to him anyway, sat down, and was given some cheese.

"Well?" shouted the Beekeeper, when the sail brought them round again.

"He is right," G@erard called down. "Lunch does taste better up here."

* * *

That is how the Ch@bteau came to have its picnic on the windmill.

Gigi went up first, because someone had to test the cushion and she wanted it to be her. Then the Shepherd, carrying the lamb, who was fine about it. Then the Beekeeper, who left the bees behind, and the Truffle Hunter, who did not leave the pig behind, and regretted it a little at the top.

Farmer Fernand parked the tractor and went up with a basket of tomatoes, and the rooster went up on the tractor's roof, then on Fernand's head, then on the sail, and crowed at the whole valley from the highest point in it, which he had always wanted to do.

Sleepy Sylvain woke at noon, saw the entire Ch@bteau turning slowly in the sky, eating lunch, and decided he was still asleep. He turned over. He was, for once, the only one on the ground.

And Picnic Pierre, who still could not get down and no longer wished to, passed the baguette along the sail and said what he always says.

"It tastes better up here."

Nobody, that day, disagreed.
]]},
}
for _, b in ipairs(books) do b.title = fix(b.title); b.by = fix(b.by or ""); b.text = fix(b.text) end
return books
]==]
	local mod = Instance.new("ModuleScript"); mod.Name = "Books"; mod.Source = BOOKSRC; mod.Parent = F

	-- ---------------------------------------------------------------- plumbing ----
	local action = RS:FindFirstChild("BookAction")
	if not action then action = Instance.new("RemoteFunction"); action.Name = "BookAction"; action.Parent = RS end
	local ev = RS:FindFirstChild("BookEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "BookEvent"; ev.Parent = RS end
	F:SetAttribute("RoomX", O.X); F:SetAttribute("RoomY", O.Y); F:SetAttribute("RoomZ", O.Z)
	F:SetAttribute("DoorX", DX); F:SetAttribute("DoorY", groundY); F:SetAttribute("DoorZ", DZ)
	F:SetAttribute("FadeSeconds", opts.fade or 0.45)
	-- the shop's sounds (Shannon's picks): the door as you go through it, and its own music, low, while you are in
	F:SetAttribute("DoorSound", opts.doorSound or "rbxassetid://131845870598154"); F:SetAttribute("DoorVolume", opts.doorVolume or 0.6)
	F:SetAttribute("ShopMusic", opts.music or "rbxassetid://9045766377"); F:SetAttribute("MusicVolume", opts.musicVolume or 0.1)
	-- where you arrive: just inside the door facing into the shop, and just outside it facing the street
	F:SetAttribute("InX", O.X + dxr); F:SetAttribute("InY", O.Y + 3.4); F:SetAttribute("InZ", O.Z + D / 2 - 5.5)   -- room behind you for the camera
	F:SetAttribute("OutX", DX); F:SetAttribute("OutY", groundY + 3.4); F:SetAttribute("OutZ", DZ + 2.6)

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local action = RS:WaitForChild("BookAction")
local ev = RS:WaitForChild("BookEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local Books = require(F:WaitForChild("Books"))
local byId = {}
for _, b in ipairs(Books) do byId[b.id] = b end
local function owned(player, id) return (player:GetAttribute("Item_book_" .. id) or 0) > 0 end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out past the walls: a short zoom leash, given back at the door (or on respawn)
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player)
	player.CharacterAdded:Connect(function() leash(player, false) end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)
-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InBookshop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "BookPrompt" then
		local id = prompt:GetAttribute("BookId")
		local b = byId[id]
		if not b or b.soon then return end
		ev:FireClient(player, "book", id, owned(player, id))
	end
end)
-- buying and reading, asked by the client
action.OnServerInvoke = function(player, what, id)
	local b = byId[id]
	if not b or b.soon then return false, "no such book" end
	if what == "buy" then
		if owned(player, id) then return true, "yours already" end
		local have = player:GetAttribute("Acorns") or 0
		if have < b.price then return false, string.format("You need %d acorns for this one.", b.price) end
		awardAcorns:Fire(player, -b.price)               -- spending is a negative award, same ledger as the shop
		player:SetAttribute("Acorns", have - b.price)
		awardItems:Fire(player, "book_" .. id, 1)
		print(string.format("Bookshop: %s bought '%s' for %d", player.Name, b.title, b.price))
		return true, "bought"
	elseif what == "read" then
		if not owned(player, id) then return false, "buy it first" end
		return true, {title = b.title, by = b.by, text = b.text, audio = b.audio or 0}
	elseif what == "owned" then
		return true, owned(player, id)
	end
	return false, "no such thing"
end
print("BookServer: ready - " .. #Books .. " books on the table")
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local function hotbar(on) pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, on) end) end   -- the hotbar sits where the book's buttons go on a small screen
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local action = RS:WaitForChild("BookAction")
local ev = RS:WaitForChild("BookEvent")
local C = Color3.fromRGB
local Books = require(F:WaitForChild("Books"))
local byId = {}
for _, b in ipairs(Books) do byId[b.id] = b end
local COVER = {crumbs = C(46, 92, 140), story2 = C(160, 48, 44), story3 = C(58, 120, 72)}

-- the shop's sounds: the door as you go through it, and its own music, low, while you are inside; the music stops
-- while a book is open and comes back when it is closed (the map music goes quiet in here: MusicClient checks InBookshop)
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local doorSfx = Instance.new("Sound"); doorSfx.Name = "ShopDoor"; doorSfx.SoundId = F:GetAttribute("DoorSound") or "rbxassetid://131845870598154"; doorSfx.Volume = F:GetAttribute("DoorVolume") or 0.6; doorSfx.Parent = SoundService
local music = Instance.new("Sound"); music.Name = "ShopMusic"; music.SoundId = F:GetAttribute("ShopMusic") or "rbxassetid://9045766377"; music.Looped = true; music.Volume = 0; music.Parent = SoundService
task.spawn(function() pcall(function() ContentProvider:PreloadAsync({doorSfx, music}) end) end)
local MUSIC_VOL = F:GetAttribute("MusicVolume") or 0.1
local inside, reading = false, false
local musicTween
local function musicTo(target, secs)
	if musicTween then musicTween:Cancel() end
	musicTween = TweenService:Create(music, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Volume = target}); musicTween:Play()
end
local function updateMusic()
	if inside and not reading then
		if music.IsPaused then music:Resume() elseif not music.IsPlaying then music.Volume = 0; music:Play() end
		musicTo(MUSIC_VOL, 1.2)
	elseif inside then                                   -- a book is open: quiet, and hold the place in the tune
		musicTo(0, 0.4)
		task.delay(0.45, function() if inside and reading and music.IsPlaying then music:Pause() end end)
	else
		musicTo(0, 0.8)
		task.delay(0.85, function() if not inside and music.Volume <= 0.001 then music:Stop() end end)
	end
end
local function watchChar(char)
	inside = char:GetAttribute("InBookshop") == true
	updateMusic()
	char:GetAttributeChangedSignal("InBookshop"):Connect(function()
		inside = char:GetAttribute("InBookshop") == true
		updateMusic()
	end)
end
if player.Character then watchChar(player.Character) end
player.CharacterAdded:Connect(watchChar)

-- the fade to black for the doors
local fadeGui = Instance.new("ScreenGui"); fadeGui.Name = "BookshopFade"; fadeGui.ResetOnSpawn = false; fadeGui.IgnoreGuiInset = true; fadeGui.DisplayOrder = 20; fadeGui.Parent = pg
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.Parent = fadeGui
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -100); note.Size = UDim2.fromOffset(460, 40); note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1
note.BorderSizePixel = 0; note.Font = Enum.Font.FredokaOne; note.TextSize = 18; note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = fadeGui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local shownAt = 0
local function say(text)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(3, function() if shownAt ~= mine then return end; TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
end

-- the book on screen: a 760x470 spread scaled to fit the screen
local FONT, SIZE, PAGE_W, PAGE_H = Enum.Font.Merriweather, 16, 312, 340
local gui = Instance.new("ScreenGui"); gui.Name = "BookReader"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 12; gui.Enabled = false; gui.Parent = pg
local dim = Instance.new("TextButton"); dim.Size = UDim2.fromScale(1, 1); dim.BackgroundColor3 = Color3.new(0, 0, 0); dim.BackgroundTransparency = 0.45; dim.Text = ""; dim.AutoButtonColor = false; dim.Parent = gui
local book = Instance.new("Frame"); book.AnchorPoint = Vector2.new(0.5, 0.5); book.Position = UDim2.fromScale(0.5, 0.5); book.Size = UDim2.fromOffset(760, 470)
book.BackgroundColor3 = C(92, 58, 40); book.BorderSizePixel = 0; book.Active = true; book.Parent = gui
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 14); bc.Parent = book
local scale = Instance.new("UIScale"); scale.Parent = book
local function fit()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 600)
	scale.Scale = math.clamp(math.min((vp.X - 30) / 760, (vp.Y - 30) / 470), 0.45, 1)
end
fit(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
local function page(x)
	local p = Instance.new("Frame"); p.Position = UDim2.fromOffset(x, 18); p.Size = UDim2.fromOffset(356, 400); p.BackgroundColor3 = C(250, 242, 222); p.BorderSizePixel = 0; p.ClipsDescendants = true; p.Parent = book
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = p
	local t = Instance.new("TextLabel"); t.Name = "Text"; t.Position = UDim2.fromOffset(22, 20); t.Size = UDim2.fromOffset(PAGE_W, PAGE_H); t.BackgroundTransparency = 1
	t.Font = FONT; t.TextSize = SIZE; t.TextColor3 = C(52, 40, 30); t.TextWrapped = true; t.RichText = true; t.TextXAlignment = Enum.TextXAlignment.Left; t.TextYAlignment = Enum.TextYAlignment.Top; t.Text = ""; t.Parent = p
	local n = Instance.new("TextLabel"); n.Name = "Num"; n.AnchorPoint = Vector2.new(0.5, 1); n.Position = UDim2.new(0.5, 0, 1, -10); n.Size = UDim2.fromOffset(60, 16); n.BackgroundTransparency = 1
	n.Font = FONT; n.TextSize = 13; n.TextColor3 = C(140, 120, 100); n.Text = ""; n.Parent = p
	return p
end
local left, right = page(18), page(386)
local function pill(text, x, w)
	local b = Instance.new("TextButton"); b.Position = UDim2.fromOffset(x, 426); b.Size = UDim2.fromOffset(w, 34); b.BackgroundColor3 = C(240, 200, 90); b.BorderSizePixel = 0
	b.Font = Enum.Font.FredokaOne; b.TextSize = 17; b.TextColor3 = C(84, 48, 18); b.Text = text; b.AutoButtonColor = false; b.Visible = false; b.Parent = book
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
	return b
end
local prev, nxt = pill("<", 26, 44), pill(">", 690, 44)
local listen, close, buy = pill("Listen", 300, 160), pill("Close", 560, 110), pill("Buy", 240, 280)
-- a cover, for a book you do not own yet
local cover = Instance.new("Frame"); cover.Position = UDim2.fromOffset(18, 18); cover.Size = UDim2.fromOffset(724, 400); cover.BackgroundColor3 = C(46, 92, 140); cover.BorderSizePixel = 0; cover.Visible = false; cover.Parent = book
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = cover
local ct = Instance.new("TextLabel"); ct.Position = UDim2.fromOffset(40, 50); ct.Size = UDim2.new(1, -80, 0, 150); ct.BackgroundTransparency = 1; ct.Font = Enum.Font.Antique; ct.TextScaled = true; ct.TextWrapped = true; ct.TextColor3 = C(255, 246, 220); ct.Parent = cover
local cb = Instance.new("TextLabel"); cb.Position = UDim2.fromOffset(40, 215); cb.Size = UDim2.new(1, -80, 0, 30); cb.BackgroundTransparency = 1; cb.Font = FONT; cb.TextSize = 18; cb.TextColor3 = C(255, 246, 220); cb.Parent = cover
local cp = Instance.new("TextLabel"); cp.Position = UDim2.fromOffset(40, 290); cp.Size = UDim2.new(1, -80, 0, 60); cp.BackgroundTransparency = 1; cp.Font = Enum.Font.FredokaOne; cp.TextSize = 22; cp.TextColor3 = C(255, 246, 220); cp.TextWrapped = true; cp.Parent = cover

-- flowing a story into pages: paragraph by paragraph, and word by word when a paragraph is longer than a page
local function fits(text) return TextService:GetTextSize(text, SIZE, FONT, Vector2.new(PAGE_W, 100000)).Y <= PAGE_H end
local function paginate(text)
	text = text:gsub("\r", "")
	local pages, cur = {}, ""
	local function push() if cur ~= "" then pages[#pages + 1] = cur; cur = "" end end
	for para in string.gmatch(text .. "\n\n", "(.-)\n\n") do
		para = para:gsub("^%s+", ""):gsub("%s+$", "")
		if para ~= "" then
			local cand = (cur == "") and para or (cur .. "\n\n" .. para)
			if fits(cand) then
				cur = cand
			else
				push()
				if fits(para) then
					cur = para
				else
					for word in para:gmatch("%S+") do
						local c2 = (cur == "") and word or (cur .. " " .. word)
						if fits(c2) then cur = c2 else push(); cur = word end
					end
				end
			end
		end
	end
	push()
	if #pages == 0 then pages[1] = "" end
	return pages
end

local current                                                -- {id, pages, spread, audio, sound}
local function stopSound()
	if current and current.sound then current.sound:Stop(); current.sound:Destroy(); current.sound = nil end
	listen.Text = "Listen"
end
local function show(spread)
	local pages = current.pages
	current.spread = spread
	local li, ri = spread * 2 - 1, spread * 2
	left.Text.Text = pages[li] or ""; left.Num.Text = pages[li] and tostring(li) or ""
	right.Text.Text = pages[ri] or ""; right.Num.Text = pages[ri] and tostring(ri) or ""
	prev.Visible = spread > 1
	nxt.Visible = ri < #pages
end
local function openReader(id, data)
	stopSound()
	local head = string.upper(data.title) .. "\n" .. (data.by or "") .. "\n\n"
	current = {id = id, pages = paginate(head .. (data.text or "")), spread = 1, audio = tonumber(data.audio) or 0}
	cover.Visible = false; buy.Visible = false
	left.Visible, right.Visible = true, true
	close.Visible = true; listen.Visible = current.audio > 0
	show(1)
	gui.Enabled = true; hotbar(false)
	reading = true; updateMusic()
end
local function openCover(id)
	stopSound()
	local b = byId[id]; if not b then return end
	current = {id = id}
	left.Visible, right.Visible = false, false
	prev.Visible, nxt.Visible, listen.Visible = false, false, false
	cover.Visible = true; cover.BackgroundColor3 = COVER[id] or C(46, 92, 140)
	ct.Text = b.title; cb.Text = b.by or ""; cp.Text = string.format("%d acorns - yours to keep, to read any time you come in", b.price)
	buy.Visible = true; buy.Text = string.format("Buy for %d acorns", b.price); close.Visible = true
	gui.Enabled = true; hotbar(false)
end
local busy = false
buy.Activated:Connect(function()
	if not current or busy then return end
	busy = true; buy.Text = "..."
	local ok, res = action:InvokeServer("buy", current.id)
	if not ok then say(tostring(res)); buy.Text = string.format("Buy for %d acorns", byId[current.id].price); busy = false; return end
	local ok2, data = action:InvokeServer("read", current.id)
	busy = false
	if ok2 then say("It is yours. Enjoy."); openReader(current.id, data) end
end)
prev.Activated:Connect(function() if current and current.spread and current.spread > 1 then show(current.spread - 1) end end)
nxt.Activated:Connect(function() if current and current.spread then show(current.spread + 1) end end)
local function shut() stopSound(); gui.Enabled = false; current = nil; hotbar(true); reading = false; updateMusic() end
close.Activated:Connect(shut)
dim.Activated:Connect(shut)
listen.Activated:Connect(function()
	if not current then return end
	if current.sound then stopSound() return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. tostring(current.audio); s.Volume = 1; s.Parent = book; s:Play()
	current.sound = s; listen.Text = "Stop"
	s.Ended:Connect(function() if current and current.sound == s then stopSound() end end)
end)
-- the prompts say Buy or Read depending on what you own (locally: a prompt's text is per screen)
local function refreshPrompts()
	for _, pr in ipairs(F:GetDescendants()) do
		if pr:IsA("ProximityPrompt") and pr.Name == "BookPrompt" then
			local id = pr:GetAttribute("BookId"); local b = byId[id]
			if b and not b.soon then
				local text = ((player:GetAttribute("Item_book_" .. id) or 0) > 0) and "Read" or string.format("Buy  -  %d acorns", b.price)
				if pr.ActionText ~= text then
					pr.ActionText = text
					-- the prompt pill only reads its text when the prompt appears, so blink it if it is showing (a
					-- same-frame toggle is a no-op to the engine; it needs a frame or two off)
					pr.Enabled = false; task.delay(0.15, function() pr.Enabled = true end)
				end
			end
		end
	end
end
refreshPrompts()
for _, b in ipairs(Books) do player:GetAttributeChangedSignal("Item_book_" .. b.id):Connect(refreshPrompts) end
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "fade" then
		doorSfx.TimePosition = 0; doorSfx:Play()                 -- the door, going in and coming out
		TweenService:Create(black, TweenInfo.new(a or 0.45), {BackgroundTransparency = 0}):Play()
	elseif what == "unfade" then
		TweenService:Create(black, TweenInfo.new((a or 0.45) * 1.4), {BackgroundTransparency = 1}):Play()
	elseif what == "book" then
		if b then
			local ok, data = action:InvokeServer("read", a)
			if ok then openReader(a, data) else say(tostring(data)) end
		else
			openCover(a)
		end
	end
end)
]==]
	local s = Instance.new("Script"); s.Name = "BookServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "BookClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	-- the room hangs over the map: RoomHide (village/build_roomhide.lua) keeps it off every screen but the ones inside
	local boxCF, boxSize = room:GetBoundingBox()
	room:SetAttribute("BoxCF", boxCF); room:SetAttribute("BoxSize", boxSize)
	game:GetService("CollectionService"):AddTag(room, "SkyRoom")
	F.Parent = workspace
	-- the village music goes quiet inside, the way it does on the zipline: MusicClient's quiet test gains InBookshop
	local musicPatched = "no MusicClient"
	local mm = workspace:FindFirstChild("MapMusic")
	local mc = mm and mm:FindFirstChild("MusicClient")
	if mc then
		if mc.Source:find("InBookshop", 1, true) then
			musicPatched = "already"
		else
			local old = 'if char:GetAttribute("Riding") or onZipDeck(root.Position) then'
			local i, j = mc.Source:find(old, 1, true)
			if i then
				mc.Source = mc.Source:sub(1, i - 1) .. 'if char:GetAttribute("Riding") or char:GetAttribute("InBookshop") or onZipDeck(root.Position) then' .. mc.Source:sub(j + 1)
				musicPatched = "patched"
			else
				musicPatched = "LINE NOT FOUND"
			end
		end
	end
	print("Bookshop: MapMusic quiet-inside patch: " .. musicPatched)
	local parts = 0
	for _, p in ipairs(F:GetDescendants()) do if p:IsA("BasePart") then parts += 1 end end
	print(string.format("Bookshop: %d parts | street door at (%.1f,%.1f,%.1f) | room %.1fx%dx%d at (%.1f,%.0f,%.1f) | shop model %s | 3 books on the table", parts, DX, groundY, DZ, W, D, H, O.X, O.Y, O.Z, tostring(shop ~= nil)))
	return F
end

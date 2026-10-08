-- Mode et Style dress boutique, whimsical 30-piece collection. Draft; publish separately after review.
return function(opts)
 opts=opts or {};local RS=game:GetService("ReplicatedStorage");local CS=game:GetService("CollectionService");local C=Color3.fromRGB;local rng=Random.new(2710)
 local kit=assert(RS:FindFirstChild("DressKit"),"Import Dresses.obj and run kit installer first")
 local CAT=[====[
__CAT__
]====]
 local SERVER=[====[
__SERVER__
]====]
 local CLIENT=[====[
__CLIENT__
]====]
 local Cat=assert(loadstring(CAT))();assert(loadstring(SERVER));assert(loadstring(CLIENT))
 for name in pairs(Cat.sizes) do assert(kit:FindFirstChild(name),"Missing dress mesh "..name) end
 local F=Instance.new("Folder");F.Name="DressShop"
 for _,s in ipairs(Cat.styles) do F:SetAttribute("Price_"..s.id,(opts.prices and opts.prices[s.id]) or s.price) end
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end
	local function soft(p) p.CanCollide = false; return p end

	-- ---------------------------------------------------------------- the street door ----
	-- the MODE ET STYLE sign is on the townhouse_e at x 312 looking +z; its door (DoorShop) is at x 303, the window x 305..323
	local SX, DX, DZ=304,295,-100.6
 local shop
 for _,m in ipairs(workspace.Village.Props:GetChildren()) do
  local t=m:FindFirstChild("SignText",true)
  if t then for _,l in ipairs(t:GetDescendants()) do if l:IsA("TextLabel") and l.Text=="MODE ET STYLE" then shop=m end end end
 end
 assert(shop,"MODE ET STYLE storefront missing")
	local function shopColour(name, fallback)
		local p = shop and shop:FindFirstChild(name, true)
		return (p and p:IsA("BasePart")) and p.Color or fallback
	end
	local FACADE = shopColour("Shopfront", C(38, 94, 65))
	local AWNING, STRIPE = shopColour("Awning", C(226, 176, 80)), shopColour("AwningStripe", C(250, 247, 240))
	local DOORC, GLASSC = shopColour("DoorShop", C(112, 74, 46)), shopColour("GlassDoor", C(232, 240, 244))
	local groundY = 0.65
	do
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
		local ground = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Ground")
		if ground then rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {ground, workspace.Terrain} end
		local hit = workspace:Raycast(Vector3.new(DX, 20, DZ + 2), Vector3.new(0, -40, 0), rp)
		if hit then groundY = hit.Position.Y end
	end
	local doorPad = part("DoorPad", Vector3.new(4, 5.5, 0.6), CFrame.new(DX, groundY + 2.9, DZ), C(255, 246, 220), nil, F)
	doorPad.Transparency = 1; doorPad.CanCollide = false; doorPad.CanQuery = false
	local mat = part("Doormat", Vector3.new(3.0, 0.12, 1.6), CFrame.new(DX, groundY + 0.06, DZ - 1.2), C(46, 70, 52), Enum.Material.Fabric)
	mat.CanCollide = false
	local enter = Instance.new("ProximityPrompt"); enter.Name = "EnterPrompt"; enter.ActionText = "Go inside"; enter.ObjectText = "Mode et Style"
	enter.KeyboardKeyCode = Enum.KeyCode.E; enter.HoldDuration = 0; enter.MaxActivationDistance = 8; enter.RequiresLineOfSight = false; enter.Parent = doorPad

	-- ---------------------------------------------------------------- the room ----
	local W, D, H = opts.width or 24, opts.depth or 22, 11
	local O = Vector3.new(SX, opts.roomY or 390, DZ - 0.45 - D / 2)         -- floor centre; the street wall's inner face at the facade
	local room = Instance.new("Model"); room.Name = "Room"; room.Parent = F
	local function at(x, y, z) return CFrame.new(O.X + x, O.Y + y, O.Z + z) end
	local dxr = DX - SX                                                       -- the door's x in room terms (-9)
	local PLASTER, WOOD, DARK, PARQUET = C(238, 227, 204), C(122, 86, 54), C(70, 48, 32), C(156, 112, 72)
	local BRASS, IRON, CREAM, VELVET = C(218, 178, 88), C(46, 46, 51), C(255, 246, 220), C(155, 72, 48)
	part("Floor", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, -0.3, 0), PARQUET, Enum.Material.WoodPlanks, room)
	part("Ceiling", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, H + 0.3, 0), C(232, 222, 202), Enum.Material.SmoothPlastic, room)
	part("WallN", Vector3.new(W, H, 0.6), at(0, H / 2, -D / 2 - 0.3), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallE", Vector3.new(0.6, H, D + 1.2), at(W / 2 + 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallW", Vector3.new(0.6, H, D + 1.2), at(-W / 2 - 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	-- a sage wainscot to the height of a chair back, capped with a dark rail, round the three plaster walls
	local WAIN = 3.1
	for _, w in ipairs({{0, -D / 2 + 0.08, W, 0.16}, {W / 2 - 0.08, 0, 0.16, D}, {-W / 2 + 0.08, 0, 0.16, D}}) do
		soft(part("Wainscot", Vector3.new(w[3], WAIN, w[4]), at(w[1], WAIN / 2, w[2]), FACADE, Enum.Material.Wood, room))
		soft(part("Rail", Vector3.new(math.max(w[3], 0.3), 0.22, math.max(w[4], 0.3)), at(w[1], WAIN + 0.1, w[2]), DARK, Enum.Material.Wood, room))
		soft(part("Skirting", Vector3.new(math.max(w[3], 0.26), 0.36, math.max(w[4], 0.26)), at(w[1], 0.18, w[2]), DARK, Enum.Material.Wood, room))
	end

	-- the street wall, in the shopfront's green: the display window (16 wide, y 1.4..8.4), wall, then the door at x -9
	local zS = D / 2 + 0.3
	local wx0, wx1, wy0, wy1 = -4.6, 11.4, 1.4, 8.4
	local ddx0, ddx1 = dxr - 1.7, dxr + 1.7
	local function wall(x0, x1, y0, y1) part("WallS", Vector3.new(x1 - x0, y1 - y0, 0.6), at((x0 + x1) / 2, (y0 + y1) / 2, zS), FACADE, Enum.Material.SmoothPlastic, room) end
	wall(-W / 2, W / 2, wy1, H)                              -- the band over the window and the door
	wall(-W / 2, ddx0, 0, wy1)                               -- west pier
	wall(ddx0, ddx1, 0, wy1)                                 -- behind the door (it is mounted on the wall)
	wall(ddx1, wx0, 0, wy1)                                  -- between the door and the window
	wall(wx0, wx1, 0, wy0)                                   -- under the window
	wall(wx1, W / 2, 0, wy1)                                 -- east pier
	local pane = part("Window", Vector3.new(wx1 - wx0, wy1 - wy0, 0.25), at((wx0 + wx1) / 2, (wy0 + wy1) / 2, zS), GLASSC, Enum.Material.Glass, room)
	pane.Transparency = 0.2; pane.CastShadow = false          -- under 0.25, so the camera treats the glass as solid
	for _, fx in ipairs({wx0 - 0.1, wx1 + 0.1}) do part("Frame", Vector3.new(0.4, wy1 - wy0 + 0.4, 0.8), at(fx, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	part("Frame", Vector3.new(wx1 - wx0 + 0.8, 0.4, 0.8), at((wx0 + wx1) / 2, wy1 + 0.1, zS), CREAM, Enum.Material.SmoothPlastic, room)
	part("Sill", Vector3.new(wx1 - wx0 + 0.8, 0.4, 1.0), at((wx0 + wx1) / 2, wy0 - 0.1, zS - 0.1), CREAM, Enum.Material.SmoothPlastic, room)
	for k = 1, 3 do part("Mullion", Vector3.new(0.25, wy1 - wy0, 0.5), at(wx0 + (wx1 - wx0) * k / 4, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	-- the mustard awning outside the window, seen through the glass
	do
		local tilt = math.rad(37)
		local n, wA, cx = 12, 18, (wx0 + wx1) / 2
		for i = 0, n - 1 do
			local sx = cx - wA / 2 + wA / n * (i + 0.5)
			soft(part("Awning", Vector3.new(wA / n + 0.02, 0.12, 4.0), at(sx, 7.85, zS + 2.05) * CFrame.Angles(tilt, 0, 0), (i % 2 == 0) and AWNING or STRIPE, Enum.Material.Fabric, room))
		end
		soft(part("AwningRod", Vector3.new(wA, 0.15, 0.15), at(cx, 6.55, zS + 3.8), IRON, Enum.Material.Metal, room))
	end
	-- the door, the Mode et Style's own brown with its glass, on the wall
	local doorZ = zS - 0.3
	part("DoorFrame", Vector3.new(3.8, 7.1, 0.2), at(dxr, 3.55, doorZ - 0.1), DARK, Enum.Material.Wood, room)
	local door = part("Door", Vector3.new(3.4, 6.8, 0.2), at(dxr, 3.4, doorZ - 0.2), DOORC, Enum.Material.Wood, room)
	local dglass = part("DoorGlass", Vector3.new(2.4, 3.6, 0.1), at(dxr, 4.4, doorZ - 0.32), GLASSC, Enum.Material.Glass, room); dglass.Transparency = 0.2
	for _, px in ipairs({-0.72, 0.72}) do soft(part("Panel", Vector3.new(1.2, 1.6, 0.06), at(dxr + px, 1.3, doorZ - 0.32), C(92, 62, 46), Enum.Material.Wood, room)) end
	soft(part("Knob", Vector3.new(0.3, 0.3, 0.3), at(dxr + 1.2, 3.4, doorZ - 0.42), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))
	local exit = Instance.new("ProximityPrompt"); exit.Name = "ExitPrompt"; exit.ActionText = "Go outside"; exit.ObjectText = "Rue de Noisette"
	exit.KeyboardKeyCode = Enum.KeyCode.E; exit.HoldDuration = 0; exit.MaxActivationDistance = 7; exit.RequiresLineOfSight = false; exit.Parent = door
	-- a bell over the door on a curled bracket (shops like this have one)
	soft(part("BellBracket", Vector3.new(0.12, 0.12, 1.0), at(dxr + 1.3, 7.5, doorZ - 0.8), IRON, Enum.Material.Metal, room))
	soft(part("ShopBell", Vector3.new(0.45, 0.45, 0.45), at(dxr + 1.3, 7.25, doorZ - 1.25), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))

__DISPLAYS__	-- THE MIRROR on the west wall: an arched glass in a gilded frame, a little rug where you stand, a sign over it
	local MZ = opts.mirrorZ or -2.6
	local mx = -W / 2 + 0.2
	local MIR = Instance.new("Model"); MIR.Name = "Mirror"; MIR.Parent = room
	part("FrameSlab", Vector3.new(0.3, 5.8, 4.5), at(mx + 0.05, 1.0 + 2.9, MZ), BRASS, Enum.Material.Metal, MIR)
	part("FrameTop", Vector3.new(0.3, 4.5, 4.5), at(mx + 0.05, 6.8, MZ) * CFrame.Angles(0, 0, 0), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Cylinder)
	local glass = part("Glass", Vector3.new(0.12, 5.4, 3.8), at(mx + 0.22, 1.2 + 2.7, MZ), C(206, 220, 230), Enum.Material.Glass, MIR)
	glass.Reflectance = 0.35
	local gtop = part("GlassTop", Vector3.new(0.12, 3.8, 3.8), at(mx + 0.22, 6.6, MZ), C(206, 220, 230), Enum.Material.Glass, MIR, Enum.PartType.Cylinder)
	gtop.Reflectance = 0.35
	soft(part("Crest", Vector3.new(0.3, 0.9, 0.9), at(mx + 0.1, 9.05, MZ), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Ball))
	local spot = Vector3.new(O.X - 3.2, O.Y, O.Z + MZ)                      -- where you stand to look in it
	soft(part("MirrorRug", Vector3.new(0.1, 4.2, 4.2), CFrame.new(spot.X, O.Y + 0.08, spot.Z) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, MIR, Enum.PartType.Cylinder))
	local ask = Instance.new("ProximityPrompt"); ask.Name = "MirrorPrompt"; ask.ActionText = "Try on outfits & accessories"; ask.ObjectText = "Mirror"
	ask.KeyboardKeyCode = Enum.KeyCode.E; ask.HoldDuration = 0; ask.MaxActivationDistance = 10; ask.RequiresLineOfSight = false; ask.Parent = glass
	do
		local card = soft(part("MirrorSign", Vector3.new(0.08, 0.8, 3.0), at(mx + 0.3, 10.1, MZ), CREAM, Enum.Material.SmoothPlastic, MIR))
		local g = Instance.new("SurfaceGui"); g.Face = Enum.NormalId.Right; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 80; g.LightInfluence = 0.3; g.Parent = card
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -10, 1, -6); l.Position = UDim2.fromOffset(5, 3)
		l.Font = Enum.Font.Antique; l.TextScaled = true; l.TextColor3 = C(70, 46, 22); l.Text = "Essayez !"; l.Parent = g
	end
	-- Fabric rolls in a brass basket beside the mirror.
 for i,col in ipairs({C(230,185,81),C(169,78,50),C(44,91,63)}) do
  local x,z=-10.4+(i-2)*.45,3.3
  soft(part("FabricRoll",Vector3.new(3.1,.44,.44),at(x,1.7,z)*CFrame.Angles(0,0,math.rad(86+i*2)),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end
 part("FabricBasket",Vector3.new(1.8,.8,1.1),at(-10.4,.4,3.3),WOOD,Enum.Material.Wood,room)
	-- the counter on the east side: a till, striped hat boxes, a little lamp
	do
		local cx, cz = W / 2 - 2.4, 2.6
		part("Counter", Vector3.new(1.6, 3.4, 7.0), at(cx, 1.7, cz), WOOD, Enum.Material.Wood, room)
		part("CounterTop", Vector3.new(1.9, 0.2, 7.3), at(cx, 3.5, cz), DARK, Enum.Material.Wood, room)
		soft(part("Front", Vector3.new(0.1, 2.6, 6.4), at(cx - 0.85, 1.6, cz), FACADE, Enum.Material.Wood, room))
		part("Till", Vector3.new(1.0, 0.8, 1.3), at(cx, 4.0, cz - 1.8), BRASS, Enum.Material.Metal, room)
		soft(part("TillTop", Vector3.new(0.7, 0.35, 1.1), at(cx + 0.15, 4.55, cz - 1.8) * CFrame.Angles(0, 0, math.rad(-20)), BRASS, Enum.Material.Metal, room))
		soft(part("LampPole", Vector3.new(0.1, 1.2, 0.1), at(cx, 4.2, cz + 2.4), BRASS, Enum.Material.Metal, room))
		local shade = soft(part("LampShade", Vector3.new(0.6, 0.8, 0.8), at(cx, 4.9, cz + 2.4) * CFrame.Angles(0, 0, math.rad(90)), C(240, 214, 160), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.5; pl.Range = 8; pl.Color = C(255, 214, 160); pl.Parent = shade
		-- hat boxes: striped rounds stacked on the counter's end and on the floor behind it
		local function hatBox(x, y, z, r, h, c1, c2)
			part("HatBox", Vector3.new(h, r * 2, r * 2), at(x, y + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), c1, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder)
			soft(part("BoxLid", Vector3.new(0.22, r * 2 + 0.1, r * 2 + 0.1), at(x, y + h - 0.08, z) * CFrame.Angles(0, 0, math.rad(90)), c2, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder))
		end
		hatBox(cx, 3.6, cz + 0.6, 0.62, 0.7, C(240, 226, 196), C(172, 42, 50))
		hatBox(cx, 4.3, cz + 0.6, 0.5, 0.55, C(128, 158, 118), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0, cz - 2.4, 0.7, 0.8, C(206, 122, 132), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0.8, cz - 2.4, 0.6, 0.7, C(240, 226, 196), C(42, 50, 94))
		hatBox(W / 2 - 0.9, 0, cz + 4.8, 0.65, 0.75, C(42, 50, 94), C(224, 180, 82))
	end

	-- a round rug in the middle, a velvet pouf to sit on, and three low pendant lamps (dim - the Librairie's were
	-- "way way way too bright" before they were cut to a third)
	-- (east of the mirror's own rug, and a little lower, so the two never overlap or flicker)
	soft(part("Rug", Vector3.new(0.1, 9, 9), at(3.9, 0.05, -1) * CFrame.Angles(0, 0, math.rad(90)), C(160, 60, 64), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	soft(part("RugBorder", Vector3.new(0.08, 9.6, 9.6), at(3.9, 0.03, -1) * CFrame.Angles(0, 0, math.rad(90)), C(218, 178, 88), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	local pouf = part("Pouf", Vector3.new(1.5, 2.4, 2.4), at(4.6, 0.75, -0.5) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, room, Enum.PartType.Cylinder)
	local seat = Instance.new("Seat"); seat.Name = "PoufSeat"; seat.Size = Vector3.new(2.0, 0.2, 2.0); seat.CFrame = at(4.6, 1.55, -0.5); seat.Transparency = 1; seat.Anchored = true; seat.Parent = room
	for i, lx in ipairs({-5, 1.5, 8}) do
		local ly = H - 2.3
		soft(part("Cord", Vector3.new(0.06, 2.0, 0.06), at(lx, H - 1.0, -2), IRON, Enum.Material.Metal, room))
		local sh = soft(part("Shade", Vector3.new(0.7, 1.4, 1.4), at(lx, ly, -2) * CFrame.Angles(0, 0, math.rad(90)), (i == 2) and C(224, 180, 82) or C(38, 94, 65), Enum.Material.Metal, room, Enum.PartType.Cylinder))
		local bulb = soft(part("Bulb", Vector3.new(0.4, 0.4, 0.4), at(lx, ly - 0.4, -2), C(255, 240, 200), Enum.Material.Neon, room, Enum.PartType.Ball))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.55; pl.Range = 16; pl.Color = C(255, 222, 176); pl.Shadows = false; pl.Parent = bulb
	end

	-- ---------------------------------------------------------------- plumbing ----
	local action = RS:FindFirstChild("DressShopAction")
	if not action then action = Instance.new("RemoteFunction"); action.Name = "DressShopAction"; action.Parent = RS end
	local ev = RS:FindFirstChild("DressShopEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "DressShopEvent"; ev.Parent = RS end
	F:SetAttribute("RoomX", O.X); F:SetAttribute("RoomY", O.Y); F:SetAttribute("RoomZ", O.Z)
	F:SetAttribute("FadeSeconds", opts.fade or 0.45)
	F:SetAttribute("DoorSound", opts.doorSound or "rbxassetid://131845870598154"); F:SetAttribute("DoorVolume", opts.doorVolume or 0.6)   -- the Librairie's door (Shannon's pick)
	F:SetAttribute("InsideZoom", 16)
	F:SetAttribute("InX", O.X + dxr); F:SetAttribute("InY", O.Y + 3.4); F:SetAttribute("InZ", O.Z + D / 2 - 5.5)
	F:SetAttribute("OutX", DX); F:SetAttribute("OutY", groundY + 3.4); F:SetAttribute("OutZ", DZ - 2.6)
	F:SetAttribute("SpotX", spot.X); F:SetAttribute("SpotY", spot.Y); F:SetAttribute("SpotZ", spot.Z)
	F:SetAttribute("MirrorX", O.X + mx); F:SetAttribute("MirrorZ", O.Z + MZ)
	if not F:FindFirstChild("DressDebug") then local d = Instance.new("BindableFunction"); d.Name = "DressDebug"; d.Parent = F end   -- Studio tests


 for i,col in ipairs({C(230,187,86),C(245,230,197),C(153,58,64)}) do
  soft(part("RibbonSpool",Vector3.new(.3,.5,.5),at(9.6,3.85,1+i*.5)*CFrame.Angles(0,0,math.pi/2),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end

 local old=workspace:FindFirstChild("DressShop");if old then old:Destroy() end
 local oldCat=kit:FindFirstChild("Catalogue");if oldCat then oldCat:Destroy() end
 local cm=Instance.new("ModuleScript");cm.Name="Catalogue";cm.Source=CAT;cm.Parent=kit
 local s=Instance.new("Script");s.Name="DressServer";s.RunContext=Enum.RunContext.Server;s.Source=SERVER;s.Parent=F
 local c=Instance.new("Script");c.Name="DressClient";c.RunContext=Enum.RunContext.Client;c.Source=CLIENT;c.Parent=F
 local cf,sz=room:GetBoundingBox();room:SetAttribute("BoxCF",cf);room:SetAttribute("BoxSize",sz);CS:AddTag(room,"SkyRoom")
 F.Parent=workspace
 return F
end

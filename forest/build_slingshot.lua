-- Slingshot + Hoop: the forest's shooting game. A very tall basketball-style hoop stands in a forest clearing
-- south-east of the spawn dais, facing a stone pad twenty studs away that marks the shooting spot; players who
-- own a slingshot (Acorn Store, Item_slingshot) carry it as a Tool and shoot ACORNS
-- at the hoop - an acorn a shot, three back for a basket. Shannon: "genuinely hard, but not impossible."
--
-- HOW A SHOT WORKS: you aim LEFT-RIGHT (the cursor on the hoop, or the camera on a phone) and the DRAW decides
-- how far it goes; every shot leaves at the same high arc (Elevation, 72 degrees). The first version took the
-- elevation from the cursor too, which meant a 70-degree lob needed the cursor pointed into the sky with the
-- camera tilted up until the hoop was out of view - "I can't shoot the acorns high enough". Now the skill is
-- timing the draw: from the pad 20 studs out the acorn must leave at about 93 studs/s, and the window that
-- goes in is a few studs a second wide - roughly a fifth of a second of the hold. The backboard gives you a
-- bank shot. The installer prints the window, so the difficulty is a measured fact rather than an opinion.
--
-- The SERVER owns everything that matters: it spends the acorn, launches the projectile, watches it cross the
-- plane of the ring, and pays the prize. The client only says which way it is aiming and how hard it pulled.
-- Nothing here touches the DataStore: acorns and baskets go through AwardAcorns / AwardItems like everything else.
--
-- THE BASKET CINEMATIC. Flight is drag-free, so once the acorn is coming down the server knows exactly where
-- it will cross the plane of the ring. A shot that is going IN, about SlowLead seconds from the ring, is taken
-- over and walked along its own parabola at SlowMo speed - everyone sees the slow motion - while the shooter's
-- camera cuts to a close-up beside the hoop and follows it down through the ring and the net, then cuts back.
-- Shannon: "do a closeup shot at an angle where you can see it going in and make it slow motion right before".
--
-- Tunable in Properties on workspace.Hoop: RingHeight, MinSpeed, MaxSpeed, Charge (seconds to full draw),
-- ShotCost, Prize, BasketWhistleId + BasketCheerId + MissSoundId (0 = none), DrawSoundId, FlySoundId, SlowMo (speed of the
-- slow motion), SlowLead (seconds before the ring it begins).
-- Re-runnable: rebuilds the hoop, the tool template and both scripts.
-- Run in edit mode: require(workspace.Hoop.PatchModule)()  (packed by village/make_patch.py)
-- AT THE LAGOON (Sep 26, for the croc): near Croque-Monsieur the slingshot aims itself - the cursor on him (or a
-- phone's button) sends the acorn in an arc onto the top of his head, where he'll be when it lands; the cursor anywhere
-- else sends it to that spot. The help line says which game you're in. CrocRange / AimRange on the Hoop.
-- THE DRAW POSE. Roblox's tool-hold animation holds the fork out in the right hand; while you draw, the LEFT
-- hand is pulled back to the right cheek (SlingPose, on every client: a two-bone IK on the rig's real bones,
-- written to the joints' Transform each Stepped and blended in and out over DrawBlend), and the pouch, an acorn
-- and both bands are redrawn locally from the prong tips to that hand, the tool's own pouch and bands hidden
-- meanwhile. The drawing player flags the character at once for their own screen and tells the server through
-- the DrawEvent, which sets SlingshotDraw on the character for everyone else. Shannon: "when you pull it back,
-- the players hand should also go back like it is pulling back and aiming".
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local SS = game:GetService("ServerStorage")
	-- THE SITE IS INSIDE THE FOREST'S WALLS. The first two stood south of the dais at z 36-50, which is past the
	-- forest's own boundary wall (z 25) on the decorative hills outside the map - only reachable with the gates
	-- opened, on a slope, with the camera stuck in the edge trees. The forest interior is x -131..137,
	-- z -216..26; this spot was chosen by scoring every interior site for scatter props to remove versus
	-- distance from the dais: one prop, 83 studs south-east, the pad nearer the dais than the ring so you meet
	-- the game face-on. The hoop faces the pad.
	local NAME = opts.name or "Hoop"                      -- the forest hoop is "Hoop" and owns the game; other maps' hoops are geometry only
	local GEOMETRY_ONLY = opts.geometryOnly == true
	local CollectionService = game:GetService("CollectionService")
	local HX, HZ = opts.x or 51, opts.z or -65
	local FACE_X, FACE_Z = opts.faceX or 31, opts.faceZ or -65
	local RING_UP = opts.ringHeight or 22
	local RING_R = opts.ringRadius or 2.0                  -- the opening's inner radius (was 1.7 for a 0.6 acorn)
	local SHOT_SCALE = opts.shotScale or 1.7               -- the flying acorn, relative to the ones on the ground
	local TUBE = 0.3
	local MARK = opts.markDistance or 20                   -- how far out the stone circle sits
	local C = Color3.fromRGB
	local ORANGE, WHITE, STEEL, STONE = C(232, 120, 40), C(245, 240, 230), C(150, 150, 156), C(128, 124, 118)
	local WOODC, DARK, CREAM = C(118, 84, 52), C(62, 42, 26), C(255, 246, 220)

	-- THE WALKABLE FLOOR at a spot: the first surface from above that is not part of a tree or a bush. Terrain
	-- counts as ground - the "lowest surface in the column" rule the other builders use is right under
	-- canopies and wrong on hills, and it buried the first hoop 5.5 studs into a terrain rise at the tree line.
	local TREEISH = {"canopy", "foliage", "leaf", "leaves", "trunk", "tree", "pine", "bush", "shrub", "fern", "mushroom", "stump", "branch"}
	local function treeish(inst)
		local n = inst.Name:lower()
		for _, k in ipairs(TREEISH) do if n:find(k, 1, true) then return true end end
		local o = inst.Parent
		while o and o ~= workspace do
			local pn = o.Name:lower()
			for _, k in ipairs(TREEISH) do if pn:find(k, 1, true) then return true end end
			o = o.Parent
		end
		return false
	end
	local function groundAt(x, z)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
		local skip, probe = {}, Vector3.new(x, 300, z)
		for pass = 1, 14 do
			rp.FilterDescendantsInstances = skip
			local h = workspace:Raycast(probe, Vector3.new(0, -500, 0), rp)
			if not h then break end
			if h.Instance:IsA("Terrain") or not treeish(h.Instance) then return h.Position.Y end
			table.insert(skip, h.Instance); probe = Vector3.new(x, h.Position.Y - 0.1, z)
		end
		return 0
	end

	-- The old hoop goes first, and the build waits a frame: a part destroyed this frame still answers spatial
	-- queries this frame, and the sign search below found its own predecessor "standing" on the best spot.
	local old = workspace:FindFirstChild(NAME); if old then old:Destroy(); task.wait() end

	-- CLEAR THE SITE: any tree, bush, rock, stump, log or mushroom whose footprint touches the ring's ground, the
	-- shooting lane or the pad comes out, the same rule the tower uses; squirrels, spawn pads and the like are
	-- never touched. The site was chosen so this removes one prop.
	local cleared = {}
	if opts.clear ~= false then                              -- the forest clearing; the shaded sites keep their trees
		local Forest = workspace:FindFirstChild("Forest")
		local KINDS = {"tree", "pine", "bush", "rock", "stump", "log_", "mushroom", "shrub", "fern"}
		local function isProp(n)
			n = n:lower()
			if n:find("squirrel") or n:find("dais") or n:find("spawn") or n:find("acorn") then return false end
			for _, k in ipairs(KINDS) do if n:find(k, 1, true) then return true end end
			return false
		end
		local dir = Vector3.new(FACE_X - HX, 0, FACE_Z - HZ).Unit
		local px, pz = HX + dir.X * MARK, HZ + dir.Z * MARK
		local boxes = {{HX - 7, HX + 7, HZ - 7, HZ + 7}, {px - 6, px + 6, pz - 6, pz + 6},
			{math.min(HX, px) - 5, math.max(HX, px) + 5, math.min(HZ, pz) - 5, math.max(HZ, pz) + 5}}
		for _, o in ipairs(Forest and Forest:GetChildren() or {}) do
			if (o:IsA("Model") or o:IsA("BasePart")) and isProp(o.Name) then
				local ok, cf, size = pcall(function() return o:GetBoundingBox() end)
				if ok then
					local x0, x1 = cf.Position.X - size.X / 2, cf.Position.X + size.X / 2
					local z0, z1 = cf.Position.Z - size.Z / 2, cf.Position.Z + size.Z / 2
					for _, b in ipairs(boxes) do
						if x0 < b[2] and x1 > b[1] and z0 < b[4] and z1 > b[3] then table.insert(cleared, o.Name); o:Destroy(); break end
					end
				end
			end
		end
	end
	local H = Instance.new("Model"); H.Name = NAME
	CollectionService:AddTag(H, "AcornHoop")
	local g = groundAt(HX, HZ)
	local ringY = g + RING_UP

	-- It FACES THE SHOOTING PAD: the frame's -Z points from the ring towards where you stand, so the ring is seen
	-- face-on from the pad and the board and pole stand behind it. Everything below is placed in this frame.
	local look = Vector3.new(FACE_X - HX, 0, FACE_Z - HZ)
	local L = CFrame.lookAt(Vector3.new(HX, g, HZ), Vector3.new(HX, g, HZ) + look.Unit)
	local function at(x, y, z) return L * CFrame.new(x, y, z) end

	local function part(name, size, cf, color, material, shape, parent)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
		p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.Anchored = true; p.CanCollide = true; p.CanTouch = false; p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or H
		return p
	end

	-- ---------------------------------------------------------------- the stand ----
	local BOARD_Z, POLE_Z = 2.4, 3.2                       -- ring at 0, board behind it, pole behind that
	local poleH = RING_UP + 1.6
	part("Pole", Vector3.new(0.7, poleH, 0.7), at(0, poleH / 2 - 0.4, POLE_Z), STEEL, Enum.Material.Metal)
	part("Footing", Vector3.new(2.2, 0.8, 2.2), at(0, 0.2, POLE_Z), STONE, Enum.Material.Concrete)
	part("Board", Vector3.new(4.4, 3.0, 0.25), at(0, RING_UP + 1.1, BOARD_Z), WHITE)
	part("BoardTrim", Vector3.new(4.5, 0.18, 0.32), at(0, RING_UP + 2.62, BOARD_Z), ORANGE)
	part("Arm", Vector3.new(0.4, 0.4, POLE_Z - BOARD_Z + 0.3), at(0, RING_UP + 1.6, (POLE_Z + BOARD_Z) / 2), STEEL, Enum.Material.Metal)
	part("Bracket", Vector3.new(0.5, 0.22, 0.55), at(0, RING_UP - 0.08, RING_R + TUBE + 0.15), STEEL, Enum.Material.Metal)

	-- ---------------------------------------------------------------- the ring ----
	-- a torus of short blocks; the rim collides, so a shot that clips it rattles off like a real one
	local SEG = 18
	local rr = RING_R + TUBE / 2
	for i = 0, SEG - 1 do
		local a = (i + 0.5) / SEG * math.pi * 2
		part("Ring", Vector3.new(2 * math.pi * rr / SEG + 0.06, TUBE, TUBE),
			at(math.sin(a) * rr, RING_UP, math.cos(a) * rr) * CFrame.Angles(0, a, 0), ORANGE)
	end
	-- the net: strings from the rim down to a smaller ring, open at the bottom so the acorn drops through; none
	-- of it collides, a net is not a wall
	local NET_DROP, NET_R2, STRINGS = 2.6, 0.95, 12
	for i = 0, STRINGS - 1 do
		local a = i / STRINGS * math.pi * 2
		local top = at(math.sin(a) * rr, RING_UP - TUBE / 2, math.cos(a) * rr).Position
		local bot = at(math.sin(a) * NET_R2, RING_UP - NET_DROP, math.cos(a) * NET_R2).Position
		local s = part("String", Vector3.new((bot - top).Magnitude, 0.09, 0.09),
			CFrame.lookAt((top + bot) / 2, bot) * CFrame.Angles(0, math.rad(90), 0), WHITE, nil, Enum.PartType.Cylinder)
		s.CanCollide = false
	end
	local r2 = NET_R2
	for i = 0, STRINGS - 1 do
		local a = (i + 0.5) / STRINGS * math.pi * 2
		local s = part("NetRing", Vector3.new(2 * math.pi * r2 / STRINGS + 0.04, 0.09, 0.09),
			at(math.sin(a) * r2, RING_UP - NET_DROP, math.cos(a) * r2) * CFrame.Angles(0, a, 0), WHITE)
		s.CanCollide = false
	end

	-- a sparkle burst for baskets, pulsed from the server by Rate so everyone sees it
	local centre = Instance.new("Part"); centre.Name = "RingCentre"; centre.Size = Vector3.new(0.2, 0.2, 0.2)
	centre.CFrame = at(0, RING_UP, 0); centre.Transparency = 1; centre.Anchored = true
	centre.CanCollide = false; centre.CanTouch = false; centre.CanQuery = false; centre.Parent = H
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(C(255, 240, 190), C(255, 200, 90))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
	pe.Lifetime = NumberRange.new(0.6, 1.2); pe.Rate = 0; pe.Speed = NumberRange.new(6, 12)
	pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, -8, 0)
	pe.LightEmission = 0.9; pe.LightInfluence = 0; pe.Parent = centre

	-- ---------------------------------------------------------------- the shooting spot ----
	-- a circle of stones on the ground in front, so people know where the game is played from, and a sign
	local mk = at(0, 0, -MARK).Position
	local mg = groundAt(mk.X, mk.Z)
	-- a flagstone pad to stand on - flat footing, and it says "here" without a word
	part("Pad", Vector3.new(0.3, 6.6, 6.6), CFrame.new(mk.X, mg + 0.15, mk.Z) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Slate, Enum.PartType.Cylinder)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local s = part("Stone", Vector3.new(0.9, 0.5, 0.7), CFrame.new(mk.X + math.sin(a) * 3.9, mg + 0.2, mk.Z + math.cos(a) * 3.9) * CFrame.Angles(0, a, 0), STONE, Enum.Material.Slate)
		s.CanCollide = false
	end
	-- THE SIGN STANDS WHERE IT CAN BE SEEN. The first one went 3.6 studs left of the circle by rule and ended
	-- up behind a tree ("you cannot see the sign you made because its hidden behind a tree"). This one tries
	-- the spots around the circle in turn, takes the first with nothing standing on it, and faces the circle.
	local function clearAt(pos)
		for _, q in ipairs(workspace:GetPartBoundsInBox(CFrame.new(pos.X, mg + 3.2, pos.Z), Vector3.new(5.5, 6.4, 5.5))) do
			local mine = q.Name == "Sign" or q.Name == "SignPost" or q.Name == "Stone"
			if q.Name ~= "Baseplate" and not q:IsDescendantOf(H) and not mine and q.Transparency < 0.9 then return false end
		end
		return true
	end
	-- Beside the circle first; failing that, between the circle and the hoop, five studs off the shooting line -
	-- a tree line runs right behind the circle, so "beside" is usually a trunk (the probe found Boundary trees
	-- on every spot behind and beside it), while the ground towards the hoop is open and in the shooter's view.
	local signPos, picked
	for i, o in ipairs({{4.6, -1.0}, {-4.6, -1.0}, {5.2, 1.5}, {-5.2, 1.5}, {5.0, 4.5}, {-5.0, 4.5}, {5.5, 7.5}, {-5.5, 7.5},
		{4.5, 10.5}, {-4.5, 10.5}, {3.8, -4.0}, {-3.8, -4.0}, {0, -4.8}, {6.0, 0}, {-6.0, 0}}) do
		local cand = at(o[1], 0, -MARK + o[2]).Position
		if clearAt(cand) then signPos = cand; picked = i break end
	end
	H:SetAttribute("SignCandidate", picked or 0)
	if not signPos then warn("Hoop: no clear spot for the sign beside the circle; using the old one") end
	signPos = signPos or at(-3.6, 0, -MARK - 1.5).Position
	local sg = groundAt(signPos.X, signPos.Z)
	local face = CFrame.lookAt(Vector3.new(signPos.X, 0, signPos.Z), Vector3.new(mk.X, 0, mk.Z))    -- -Z towards the circle
	part("SignPost", Vector3.new(0.4, 4.0, 0.4), CFrame.new(signPos.X, sg + 2.0, signPos.Z) * face.Rotation, WOODC, Enum.Material.Wood)
	local board = part("Sign", Vector3.new(4.2, 1.5, 0.14), CFrame.new(signPos.X, sg + 3.6, signPos.Z) * face.Rotation * CFrame.new(0, 0, -0.27), WOODC, Enum.Material.Wood)
	H:SetAttribute("SignX", signPos.X); H:SetAttribute("SignZ", signPos.Z)
	board.CanCollide = false
	local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 40; gui.Parent = board
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne; tl.TextScaled = true; tl.TextWrapped = true; tl.TextColor3 = CREAM
	tl.Text = "ACORN HOOP\nan acorn a shot - three for a basket"; tl.Parent = gui

	-- ---------------------------------------------------------------- the plumbing ----
	local shoot = RS:FindFirstChild("SlingShot")
	if not shoot then shoot = Instance.new("RemoteEvent"); shoot.Name = "SlingShot"; shoot.Parent = RS end
	local ringWorld = at(0, RING_UP, 0).Position
	H:SetAttribute("RingX", ringWorld.X); H:SetAttribute("RingY", ringWorld.Y); H:SetAttribute("RingZ", ringWorld.Z)
	H:SetAttribute("RingRadius", RING_R); H:SetAttribute("RingHeight", RING_UP); H:SetAttribute("ShotScale", SHOT_SCALE)
	H:SetAttribute("MarkX", mk.X); H:SetAttribute("MarkZ", mk.Z); H:SetAttribute("Ground", g)
	if GEOMETRY_ONLY then                                   -- another map's hoop: no tool, no scripts; workspace.Hoop's settings apply
		H.Parent = workspace
		local parts = 0
		for _, q in ipairs(H:GetDescendants()) do if q:IsA("BasePart") then parts += 1 end end
		print(string.format("%s: %d parts at %.0f,%.0f | ring %.1f up | circle at %.0f,%.0f | scored by workspace.Hoop", NAME, parts, HX, HZ, RING_UP, mk.X, mk.Z))
		return H
	end
	-- MinSpeed 70, not 45: below 70 the acorn cannot reach ring height at all, so the bottom of the draw was
	-- frustration rather than difficulty. The skill window (92-115 at a high arc) is unchanged.
	H:SetAttribute("MinSpeed", opts.minSpeed or 70); H:SetAttribute("MaxSpeed", opts.maxSpeed or 120)
	-- Charge 2.0 and Elevation 72, measured: at 66 degrees and a 1.5s draw the draws that score from the pad
	-- spanned 0.09s of the hold; a steeper lob comes down more vertically and forgives more, and a slower draw
	-- turns the same few studs a second into a fifth of a second. Hard, and possible.
	H:SetAttribute("Charge", opts.charge or 2.0)
	H:SetAttribute("Elevation", opts.elevation or 72)      -- degrees; every shot leaves at this arc
	H:SetAttribute("ShotCost", opts.shotCost or 1); H:SetAttribute("Prize", opts.prize or 3)
	-- the lagoon: this near the croc (and nearer him than any hoop) a shot flies at him; an aimed shot goes this far at most
	H:SetAttribute("CrocRange", opts.crocRange or 70); H:SetAttribute("AimRange", opts.aimRange or 90)
	-- three shots and then the slingshot rests (seconds) - at the croc and the hoops alike
	H:SetAttribute("ShotsBeforeRest", opts.shotsBeforeRest or 3); H:SetAttribute("RestSeconds", opts.restSeconds or 60)
	H:SetAttribute("BasketSoundId", nil)
	-- a whistle the moment it drops through, and a cheer a beat later while the camera is still on the ring
	H:SetAttribute("BasketWhistleId", opts.whistle or 9118113825)      -- Referee Whistle 2 (Roblox library, 1.8s)
	H:SetAttribute("BasketCheerId", opts.cheer or 7755719721)          -- Crowd cheering sound effect (6.0s)
	H:SetAttribute("BasketVolume", opts.basketVolume or 1.0)
	-- and for the shooter alone, a crowd going "ohhh" when a shot misses
	H:SetAttribute("MissSoundId", opts.miss or 111856617036858)        -- Crowd Ohhh (1.7s)
	H:SetAttribute("MissVolume", opts.missVolume or 0.8)
	H:SetAttribute("DrawSoundId", opts.drawSound or 113130964350852)   -- the pull, Shannon's pick; read at each draw
	H:SetAttribute("DrawVolume", opts.drawVolume or 0.8)
	H:SetAttribute("FlySoundId", opts.flySound or 82398084015744)     -- the flight, Shannon's pick; rides on the acorn
	H:SetAttribute("FlyVolume", opts.flyVolume or 0.8)
	H:SetAttribute("SlowMo", opts.slowMo or 0.35); H:SetAttribute("SlowLead", opts.slowLead or 0.7)
	-- the draw pose (SlingPose): where the pulling hand goes, in the UpperTorso's frame, which way its elbow
	-- points, and how long the arm takes to get there and back
	H:SetAttribute("DrawHandX", opts.drawHandX or 0.45); H:SetAttribute("DrawHandY", opts.drawHandY or 1.15); H:SetAttribute("DrawHandZ", opts.drawHandZ or -0.45)
	H:SetAttribute("DrawPoleX", opts.drawPoleX or -0.8); H:SetAttribute("DrawPoleY", opts.drawPoleY or -0.1); H:SetAttribute("DrawPoleZ", opts.drawPoleZ or 0.4)
	H:SetAttribute("DrawBlend", opts.drawBlend or 0.12)
	local drawEvt = H:FindFirstChild("DrawEvent")
	if not drawEvt then drawEvt = Instance.new("RemoteEvent"); drawEvt.Name = "DrawEvent"; drawEvt.Parent = H end

	-- ---------------------------------------------------------------- the tool ----
	-- A wooden fork with a band, welded to its handle; the hand holds the lower part of the stick and the fork
	-- points up with the pouch drawn back towards the player.
	local oldT = SS:FindFirstChild("SlingshotTool"); if oldT then oldT:Destroy() end
	-- stored as SlingshotTool, handed out as Slingshot: the template and the copies must not share a name, or
	-- the server finds the wrong one
	local tool = Instance.new("Tool"); tool.Name = "SlingshotTool"; tool.ToolTip = "Hold to draw, let go to shoot an acorn"
	tool.CanBeDropped = false; tool.RequiresHandle = true
	tool.TextureId = "rbxassetid://" .. (opts.icon or 122120262360584)   -- the hotbar icon (marketing/icon_slingshot.png, decal 77426317466042)
	tool.Grip = CFrame.new(0, -0.45, 0)
	local function tpart(name, size, cf, color, material, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
		p.Color = color; p.Material = material or Enum.Material.Wood
		if shape then p.Shape = shape end
		p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = tool
		return p
	end
	local handle = tpart("Handle", Vector3.new(0.34, 1.7, 0.34), CFrame.new(), WOODC)
	handle.Massless = false
	-- the sound of the pull, on the handle so it comes from the slingshot; the client plays and stops it
	local draw = Instance.new("Sound"); draw.Name = "Draw"; draw.SoundId = "rbxassetid://" .. tostring(H:GetAttribute("DrawSoundId"))
	draw.Volume = H:GetAttribute("DrawVolume") or 0.8; draw.RollOffMaxDistance = 40; draw.Parent = handle
	local function weld(p) local w = Instance.new("WeldConstraint"); w.Part0 = handle; w.Part1 = p; w.Parent = p end
	local SPREAD = math.rad(24)
	local tips = {}
	for _, sx in ipairs({-1, 1}) do
		local prong = tpart("Prong", Vector3.new(0.28, 1.15, 0.28),
			CFrame.new(sx * math.sin(SPREAD) * 0.575, 0.85 + math.cos(SPREAD) * 0.575, 0) * CFrame.Angles(0, 0, -sx * SPREAD), WOODC)
		weld(prong)
		tips[sx] = Vector3.new(sx * math.sin(SPREAD) * 1.15, 0.85 + math.cos(SPREAD) * 1.15, 0)
	end
	local pouchPos = Vector3.new(0, 1.72, 0.55)
	for _, sx in ipairs({-1, 1}) do
		local a, b = tips[sx], pouchPos
		local band = tpart("Band", Vector3.new((b - a).Magnitude, 0.09, 0.09),
			CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), DARK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		weld(band)
	end
	weld(tpart("Pouch", Vector3.new(0.34, 0.24, 0.12), CFrame.new(pouchPos), C(96, 64, 40), Enum.Material.Fabric))
	tool.Parent = SS

	-- ---------------------------------------------------------------- the client half, inside the tool ----
	local CLIENT = [==[
local tool = script.Parent
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local shoot = RS:WaitForChild("SlingShot")
local drawEvt = workspace:WaitForChild("Hoop"):WaitForChild("DrawEvent")
local C = Color3.fromRGB
local CollectionService = game:GetService("CollectionService")
local touchAim = (UIS.TouchEnabled and not UIS.MouseEnabled) or workspace.Hoop:GetAttribute("ForceTouch") == true   -- a phone: hold a button, the shot aims itself; a mouse aims with the cursor
if touchAim then tool.ManualActivationOnly = true end          -- so a tap on the screen (or a camera drag) is not a shot

local gui = Instance.new("ScreenGui"); gui.Name = "SlingUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 6; gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
-- a crosshair at the centre, for camera aiming
local cross = Instance.new("Frame"); cross.AnchorPoint = Vector2.new(0.5, 0.5); cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.fromOffset(26, 26); cross.BackgroundTransparency = 1; cross.Visible = false; cross.Parent = gui
-- the phone's trigger: a big round button, bottom right, that you hold to draw and let go of to shoot
local hold = Instance.new("TextButton"); hold.Name = "Shoot"; hold.AnchorPoint = Vector2.new(1, 1); hold.Position = UDim2.new(1, -26, 1, -150)
hold.Size = UDim2.fromOffset(150, 150); hold.BackgroundColor3 = C(255, 202, 62); hold.BackgroundTransparency = 0.08; hold.BorderSizePixel = 0
hold.Text = "HOLD\nTO SHOOT"; hold.Font = Enum.Font.FredokaOne; hold.TextSize = 24; hold.TextColor3 = C(84, 48, 18); hold.AutoButtonColor = false
hold.Visible = touchAim; hold.Parent = gui
local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(1, 0); hc.Parent = hold
local hs = Instance.new("UIStroke"); hs.Color = C(150, 98, 36); hs.Thickness = 3; hs.Parent = hold
local cs = Instance.new("UIStroke"); cs.Color = C(255, 246, 220); cs.Thickness = 2; cs.Parent = cross
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = cross
-- the draw: a bar that fills while you hold
local barBack = Instance.new("Frame"); barBack.AnchorPoint = Vector2.new(0.5, 1); barBack.Position = UDim2.new(0.5, 0, 1, -110)
barBack.Size = UDim2.fromOffset(220, 14); barBack.BackgroundColor3 = C(38, 30, 52); barBack.BackgroundTransparency = 0.25
barBack.BorderSizePixel = 0; barBack.Visible = false; barBack.Parent = gui
local bb = Instance.new("UICorner"); bb.CornerRadius = UDim.new(0, 7); bb.Parent = barBack
local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 1.5; bs.Parent = barBack
local bar = Instance.new("Frame"); bar.Size = UDim2.fromScale(0, 1); bar.BackgroundColor3 = C(255, 202, 62); bar.BorderSizePixel = 0; bar.Parent = barBack
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 7); bc.Parent = bar
-- a line of text: "BASKET!", "you need an acorn", the help line. The box HUGS ITS WORDS and wraps them inside it, in
-- crisp BuilderSans, with the gold line round the box rather than round the letters. The first one was a fixed 420 wide
-- in FredokaOne with its UIStroke on the text, and the help line ran out of both ends of it in fuzzy gold (Shannon:
-- "this will not do"). On a phone it stays clear of the big round button.
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -132)
note.Size = UDim2.fromOffset(0, 0); note.AutomaticSize = Enum.AutomaticSize.XY; note.TextWrapped = true
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0
note.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
note.TextSize = 20; note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1; note.Text = ""; note.Parent = gui
local nmax = Instance.new("UISizeConstraint"); nmax.MaxSize = Vector2.new(440, math.huge); nmax.Parent = note
local np = Instance.new("UIPadding"); np.PaddingLeft = UDim.new(0, 16); np.PaddingRight = UDim.new(0, 16)
np.PaddingTop = UDim.new(0, 8); np.PaddingBottom = UDim.new(0, 8); np.Parent = note
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local ns = Instance.new("UIStroke"); ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ns.Color = C(240, 200, 90); ns.Thickness = 1.5; ns.Transparency = 1; ns.Parent = note
local shownAt = 0
local function say(text, gold, secs)
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	nmax.MaxSize = Vector2.new(math.clamp(vw - (touchAim and 360 or 60), 240, 440), math.huge)
	note.Text = text; note.TextColor3 = gold and C(255, 214, 90) or C(255, 246, 220)
	note.BackgroundTransparency = 0.15; note.TextTransparency = 0; ns.Transparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(secs or (gold and 3.2 or 2.4), function()
		if shownAt ~= mine then return end
		local ti = TweenInfo.new(0.5)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(ns, ti, {Transparency = 1}):Play()
	end)
end

local charging, t0, conn = false, 0, nil
local function chargeSecs()
	local H = workspace:FindFirstChild("Hoop")
	return (H and H:GetAttribute("Charge")) or 1.5
end
local function stopBar()
	if conn then conn:Disconnect(); conn = nil end
	barBack.Visible = false; bar.Size = UDim2.fromScale(0, 1)
end
-- AT THE LAGOON THE SLINGSHOT IS FOR THE CROC (Shannon: "set me up with a slingshot so I can test the acorn to the head
-- of the croc"): within CrocRange of him, and nearer him than any hoop, a shot flies at his head (the cursor on him, or
-- a phone's button) or at the spot under the cursor, and the help line says so. Anywhere else it's the hoop game.
local function nearestHoopDist(pos)
	local best = math.huge
	for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
		local rx, rz = m:GetAttribute("RingX"), m:GetAttribute("RingZ")
		if rx and rz then best = math.min(best, Vector3.new(rx - pos.X, 0, rz - pos.Z).Magnitude) end
	end
	return best
end
local function nearCroc()
	local lag = workspace:FindFirstChild("Lagoon")
	local croc = lag and lag:FindFirstChild("Croc")
	local body = croc and croc:FindFirstChild("Body")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (body and root) then return nil end
	local d = Vector3.new(body.Position.X - root.Position.X, 0, body.Position.Z - root.Position.Z).Magnitude
	if d > (workspace.Hoop:GetAttribute("CrocRange") or 70) or d > nearestHoopDist(root.Position) then return nil end
	return body, lag:GetAttribute("CrocName") or "the croc"
end
-- does the line from the camera through the cursor pass through a box (his body, grown a little: he's a moving target)?
local function rayHitsBox(o, d, cf, half)
	local lo, ld = cf:PointToObjectSpace(o), cf:VectorToObjectSpace(d)
	local tmin, tmax = 0, 1e9
	for _, ax in ipairs({"X", "Y", "Z"}) do
		local oa, da, h = lo[ax], ld[ax], half[ax]
		if math.abs(da) < 1e-8 then
			if oa < -h or oa > h then return false end
		else
			local t1, t2 = (-h - oa) / da, (h - oa) / da
			if t1 > t2 then t1, t2 = t2, t1 end
			tmin, tmax = math.max(tmin, t1), math.min(tmax, t2)
			if tmin > tmax then return false end
		end
	end
	return true
end
local shownMode
local function helpLine()
	local body, name = nearCroc()
	shownMode = body and "croc" or "hoop"
	if body then
		say(touchAim and ("Hold the big button and let go - the acorn flies at " .. name .. "'s head!")
			or ("Put the cursor on " .. name .. ". Hold to draw, let go to bonk him on the head!"), false, 4.5)
	else
		say(touchAim and "Hold the big button to draw - longer goes further - let go to shoot. It flies at the nearest hoop."
			or "Put the cursor on the hoop. Hold to draw - longer goes further - let go to shoot.", false, 4.5)
	end
end
tool.Equipped:Connect(function()
	gui.Enabled = true
	helpLine()
end)
-- walking from one game to the other with it out: the help line changes with the game
task.spawn(function()
	while tool.Parent do
		task.wait(0.5)
		if gui.Enabled and shownMode and not charging then
			if (nearCroc() and "croc" or "hoop") ~= shownMode then helpLine() end
		end
	end
end)
-- the pull: plays from the handle while you hold, stops the moment you let go
local function drawSound()
	local handle = tool:FindFirstChild("Handle")
	return handle and handle:FindFirstChild("Draw")
end
-- the draw flag: on this screen at once, and through the server for everyone else's (SlingPose reads it)
local function drawing(on)
	local ch = player.Character
	if ch then ch:SetAttribute("SlingshotDraw", on or nil) end
	drawEvt:FireServer(on == true)
end
tool.Unequipped:Connect(function() gui.Enabled = false; charging = false; stopBar(); drawing(false); local snd = drawSound(); if snd then snd:Stop() end end)
-- THE REST (three shots, then the slingshot rests, at the croc and the hoops - the server counts and says so; this only
-- shows it): a line when the rest begins or a shot is tried, the phone's button counting down, a word when it's ready
local restUntil = 0
local function restLeft() return math.max(0, math.ceil(restUntil - os.clock())) end
local function resting(secs, started)
	restUntil = os.clock() + secs
	if started then
		local when = (secs == 60 and "a minute") or (secs > 60 and (math.floor(secs / 60 + 0.5) .. " minutes")) or (secs .. " seconds")
		say("That's three shots! Your slingshot needs a rest - ready again in " .. when .. ".", false, 4)
	else
		say("Your slingshot is resting - ready in " .. restLeft() .. " s.", false, 2.4)
	end
	local mine = restUntil
	task.spawn(function()
		while restUntil == mine and os.clock() < restUntil do
			if touchAim then hold.Text = "REST\n" .. restLeft(); hold.BackgroundColor3 = C(196, 184, 160) end
			task.wait(0.25)
		end
		if restUntil ~= mine then return end
		hold.Text = "HOLD\nTO SHOOT"; hold.BackgroundColor3 = C(255, 202, 62)
		if gui.Enabled then say("Your slingshot is ready again!", true, 2.4) end
	end)
end
local function beginDraw()
	if charging then return end
	if os.clock() < restUntil then say("Your slingshot is resting - ready in " .. restLeft() .. " s.", false, 2.4) return end
	charging = true; t0 = os.clock()
	drawing(true)
	barBack.Visible = true
	stopBar(); barBack.Visible = true
	local snd = drawSound()
	if snd then
		local H = workspace:FindFirstChild("Hoop")
		local id = H and tonumber(H:GetAttribute("DrawSoundId")) or 0
		if id > 0 then
			snd.SoundId = "rbxassetid://" .. id
			snd.Volume = (H and H:GetAttribute("DrawVolume")) or 0.8
			snd.TimePosition = 0
			snd:Play()
		end
	end
	conn = RunService.RenderStepped:Connect(function()
		bar.Size = UDim2.fromScale(math.clamp((os.clock() - t0) / chargeSecs(), 0, 1), 1)
	end)
end
local function endDraw()
	local snd = drawSound(); if snd then snd:Stop() end
	drawing(false)
	if not charging then return end
	charging = false
	local power = math.clamp((os.clock() - t0) / chargeSecs(), 0.12, 1)
	stopBar()
	local dir, kind, point
	local body = nearCroc()
	if body then
		-- at the lagoon: at his head (a phone always; with a mouse, the cursor on him or near him), or else at whatever
		-- is under the cursor. The server works out the arc.
		if touchAim then kind = "croc"
		else
			local ray = player:GetMouse().UnitRay
			if rayHitsBox(ray.Origin, ray.Direction, body.CFrame, body.Size / 2 + Vector3.new(2, 2, 2)) then kind = "croc"
			else
				local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
				local skip = {player.Character}
				local dl = workspace:FindFirstChild("SlingDraw_local"); if dl then table.insert(skip, dl) end
				rp.FilterDescendantsInstances = skip
				local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, rp)
				if hit then kind, point = "point", hit.Position end
			end
		end
	end
	if touchAim then
		-- a phone does not aim: the acorn flies at the nearest hoop; only the hold decides the distance
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local best, bestD
		for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
			local rx, rz = m:GetAttribute("RingX"), m:GetAttribute("RingZ")
			if rx and root then
				local d = Vector3.new(rx - root.Position.X, 0, rz - root.Position.Z)
				if not bestD or d.Magnitude < bestD then best, bestD = d, d.Magnitude end
			end
		end
		dir = (best and best.Magnitude > 0.1) and best.Unit or workspace.CurrentCamera.CFrame.LookVector
	else
		dir = player:GetMouse().UnitRay.Direction
	end
	shoot:FireServer(dir, power, kind, point)
end
tool.Activated:Connect(function() if not touchAim then beginDraw() end end)
tool.Deactivated:Connect(function() if not touchAim then endDraw() end end)
hold.InputBegan:Connect(function(io)
	if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then hold.BackgroundColor3 = C(255, 232, 150); beginDraw() end
end)
hold.InputEnded:Connect(function(io)
	if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end
end)
UIS.InputEnded:Connect(function(io)                              -- a finger that slid off the button still lets go
	if charging and touchAim and io.UserInputType == Enum.UserInputType.Touch then hold.BackgroundColor3 = C(255, 202, 62); endDraw() end
end)
-- THE CLOSE-UP. Beside the ring, a little above it and a touch back towards the shooter, so the acorn is seen
-- coming in from the side and dropping through; it follows the acorn with the ring kept in frame, holds a
-- moment on the net, and hands the camera back.
local cineConn
local function closeUp(nut, rc, dur)
	local cam = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local approach = ((rc - (root and root.Position or cam.CFrame.Position)) * Vector3.new(1, 0, 1))
	approach = approach.Magnitude > 0.1 and approach.Unit or Vector3.new(0, 0, -1)
	local side = approach:Cross(Vector3.yAxis)
	local camPos = rc + side * 6.5 - approach * 3.0 + Vector3.new(0, 2.8, 0)
	if cineConn then cineConn:Disconnect() end
	cam.CameraType = Enum.CameraType.Scriptable
	local start = os.clock()
	cineConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		if t > dur + 0.7 or not nut.Parent then
			cineConn:Disconnect(); cineConn = nil
			cam.CameraType = Enum.CameraType.Custom
			return
		end
		local target = nut.Position:Lerp(rc, 0.4)
		cam.CFrame = CFrame.lookAt(camPos, target)
	end)
end
tool.Unequipped:Connect(function()
	if cineConn then cineConn:Disconnect(); cineConn = nil; workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
end)
-- the crowd's "ohhh" for a miss: flat, for this player only
local function missSound()
	local H = workspace:FindFirstChild("Hoop")
	local id = H and tonumber(H:GetAttribute("MissSoundId")) or 0
	if id <= 0 then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = (H and H:GetAttribute("MissVolume")) or 0.8
	s.Parent = game:GetService("SoundService"); s:Play()
	game:GetService("Debris"):AddItem(s, 10)
end
shoot.OnClientEvent:Connect(function(what, a, b, c)
	if what == "basket" then say(string.format("BASKET!  +%d acorns", a), true)
	elseif what == "cine" then closeUp(a, b, c)
	elseif what == "miss" then missSound()
	elseif what == "no" then say(a)
	elseif what == "rest" then resting(tonumber(a) or 0, b == true) end
end)
]==]
	local ls = Instance.new("LocalScript"); ls.Name = "SlingClient"; ls.Source = CLIENT; ls.Parent = tool

	-- ---------------------------------------------------------------- the draw pose (every client) ----
	local POSE = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local H = script.Parent
local function cfg(name, default) local v = H:GetAttribute(name); return v ~= nil and v or default end
local function frames(j)                                       -- parent-side and child-side frames of a joint
	if j:IsA("Motor6D") then return j.C0, j.C1 end
	if j:IsA("AnimationConstraint") then return j.Attachment0 and j.Attachment0.CFrame or CFrame.new(), j.Attachment1 and j.Attachment1.CFrame or CFrame.new() end
	return nil
end
local function jointOf(char, part, name) local p = char:FindFirstChild(part); return p and p:FindFirstChild(name) end

-- THE LEFT ARM, hand drawn back to the right cheek: two-bone IK on the rig's real bones in the UpperTorso's frame
-- (the same solver as BinocularsPose: Part1 = Part0 * C0 * Transform * C1^-1, bones read off the attachments)
local function solve(char)
	local torso = char:FindFirstChild("UpperTorso")
	local sh, el, wr = jointOf(char, "LeftUpperArm", "LeftShoulder"), jointOf(char, "LeftLowerArm", "LeftElbow"), jointOf(char, "LeftHand", "LeftWrist")
	if not (torso and sh and el and wr and frames(sh) and frames(el) and frames(wr)) then return nil end
	local s0, s1 = frames(sh); local e0, e1 = frames(el); local w0, w1 = frames(wr)
	local S = s0.Position
	local u = e0.Position - s1.Position
	local w = (w0.Position - e1.Position) - w1.Position
	local T = Vector3.new(cfg("DrawHandX", 0.45), cfg("DrawHandY", 1.15), cfg("DrawHandZ", -0.45))
	local d = T - S
	local D = d.Magnitude
	local K = u.X * w.X
	local A = u.Y * w.Y + u.Z * w.Z
	local B = u.Z * w.Y - u.Y * w.Z
	local M = (D * D - u.Magnitude ^ 2 - w.Magnitude ^ 2) / 2
	local delta = math.atan2(B, A)
	local alpha = math.acos(math.clamp((M - K) / math.max(math.sqrt(A * A + B * B), 1e-6), -1, 1))
	local function norm(x) return math.atan2(math.sin(x), math.cos(x)) end
	local phi, phi2 = norm(delta + alpha), norm(delta - alpha)
	local ok1, ok2 = phi > 0 and phi < math.pi, phi2 > 0 and phi2 < math.pi
	if ok2 and (not ok1 or math.abs(phi2 - math.rad(110)) < math.abs(phi - math.rad(110))) then phi = phi2 end
	local R2 = CFrame.Angles(phi, 0, 0)
	local e = u + R2 * w
	local ne = u:Cross(e); if ne.Magnitude < 1e-4 then ne = Vector3.new(1, 0, 0) end
	local pole = Vector3.new(cfg("DrawPoleX", -0.8), cfg("DrawPoleY", -0.1), cfg("DrawPoleZ", 0.4))
	local nd = pole:Cross(d); if nd.Magnitude < 1e-4 then nd = Vector3.new(-1, 0, 0) end
	return {
		[sh] = CFrame.fromMatrix(Vector3.zero, nd.Unit, d.Unit) * CFrame.fromMatrix(Vector3.zero, ne.Unit, e.Unit):Inverse(),
		[el] = R2,
		[wr] = CFrame.new(),
	}
end

-- THE STRETCHED BAND. The tool's pouch and bands are hidden on this screen and redrawn from the prong tips to the
-- pulling hand, with an acorn sitting in the pouch. Local parts, this client's alone.
local TIP = {Vector3.new(-0.468, 1.900, 0), Vector3.new(0.468, 1.900, 0)}      -- the prong tips, handle frame
local FORK = Vector3.new(0, 1.72, 0)
local folder = Instance.new("Folder"); folder.Name = "SlingDraw_local"; folder.Parent = workspace
local function newPart(name, size, color, material, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = material
	if shape then p.Shape = shape end
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Parent = folder
	return p
end
local function makeVisual()
	return {
		pouch = newPart("Pouch", Vector3.new(0.34, 0.24, 0.12), Color3.fromRGB(96, 64, 40), Enum.Material.Fabric),
		nut = newPart("Acorn", Vector3.new(0.42, 0.42, 0.42), Color3.fromRGB(128, 84, 42), Enum.Material.SmoothPlastic, Enum.PartType.Ball),
		bands = {newPart("Band", Vector3.new(1, 0.09, 0.09), Color3.fromRGB(40, 36, 36), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder),
			newPart("Band", Vector3.new(1, 0.09, 0.09), Color3.fromRGB(40, 36, 36), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)},
	}
end
local function killVisual(v)
	v.pouch:Destroy(); v.nut:Destroy(); v.bands[1]:Destroy(); v.bands[2]:Destroy()
end
local function updateVisual(v, char, tool)
	local handle = tool:FindFirstChild("Handle")
	local hand = char:FindFirstChild("LeftHand")
	if not (handle and hand) then return end
	local fork = handle.CFrame:PointToWorldSpace(FORK)
	local toFork = fork - hand.Position
	local pouch = hand.Position + (toFork.Magnitude > 0.01 and toFork.Unit * 0.22 or Vector3.zero)
	v.pouch.CFrame = CFrame.lookAt(pouch, fork)
	v.nut.Position = pouch
	for i, tip in ipairs(TIP) do
		local a = handle.CFrame:PointToWorldSpace(tip)
		local len = (pouch - a).Magnitude
		v.bands[i].Size = Vector3.new(math.max(len, 0.1), 0.09, 0.09)
		v.bands[i].CFrame = CFrame.lookAt((a + pouch) / 2, pouch) * CFrame.Angles(0, math.rad(90), 0)
	end
end
local function setToolHidden(tool, hidden)
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") and (p.Name == "Pouch" or p.Name == "Band") then p.LocalTransparencyModifier = hidden and 1 or 0 end
	end
end

-- Each drawing character's record: on/off, when that changed, the solved pose, the local band parts
local recs = setmetatable({}, {__mode = "k"})
local function drop(char, rec)
	if rec.visual then killVisual(rec.visual); rec.visual = nil end
	local tool = char:FindFirstChild("Slingshot")
	if tool then setToolHidden(tool, false) end
	recs[char] = nil
end
RunService.Stepped:Connect(function()
	local now = os.clock()
	local B = math.max(cfg("DrawBlend", 0.12), 0.02)
	for _, pl in ipairs(Players:GetPlayers()) do
		local char = pl.Character
		if char then
			local on = char:GetAttribute("SlingshotDraw") == true
			local rec = recs[char]
			if on and not rec then rec = {on = true, t0 = now, pose = solve(char)}; recs[char] = rec
			elseif rec and rec.on ~= on then rec.on = on; rec.t0 = now end
			if rec then
				if not rec.pose then rec.pose = solve(char) end            -- parts still arriving: try again
				local k = math.clamp((now - rec.t0) / B, 0, 1)
				local alpha = rec.on and k or (1 - k)
				if alpha <= 0 or not rec.pose then
					if not rec.on then drop(char, rec) end
				else
					-- blended with what the animator just wrote, so the arm swings up and back down smoothly
					for j, cf in pairs(rec.pose) do
						if j.Parent then pcall(function() j.Transform = j.Transform:Lerp(cf, alpha) end) end
					end
				end
			end
		end
	end
	for char, rec in pairs(recs) do if not char.Parent then drop(char, rec) end end
end)
RunService.RenderStepped:Connect(function()
	for char, rec in pairs(recs) do
		local tool = char:FindFirstChild("Slingshot")
		if rec.on and tool then
			if not rec.visual then rec.visual = makeVisual(); setToolHidden(tool, true) end
			updateVisual(rec.visual, char, tool)
		elseif rec.visual then
			killVisual(rec.visual); rec.visual = nil
			if tool then setToolHidden(tool, false) end
		end
	end
end)
]==]
	local oldPose = H:FindFirstChild("SlingPose"); if oldPose then oldPose:Destroy() end
	local pose = Instance.new("Script"); pose.Name = "SlingPose"; pose.RunContext = Enum.RunContext.Client; pose.Source = POSE; pose.Parent = H

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local H = script.Parent
local shoot = RS:WaitForChild("SlingShot")
local award = RS:WaitForChild("AwardAcorns")
local items = RS:WaitForChild("AwardItems")
local picked = RS:WaitForChild("AcornPicked")
local template = SS:WaitForChild("AcornTemplate")
local toolTemplate = SS:WaitForChild("SlingshotTool")
local drawEvt = H:WaitForChild("DrawEvent")

-- ---- the draw flag: the drawing player says so; the character carries it for every other screen
drawEvt.OnServerEvent:Connect(function(pl, on)
	local ch = pl.Character
	if not ch then return end
	if on == true and ch:FindFirstChild("Slingshot") then ch:SetAttribute("SlingshotDraw", true) else ch:SetAttribute("SlingshotDraw", nil) end
end)

local function ring() return Vector3.new(H:GetAttribute("RingX"), H:GetAttribute("RingY"), H:GetAttribute("RingZ")) end
-- every hoop in the game (tagged AcornHoop by the builder); a shot is scored against the one nearest to where it left
local CollectionService = game:GetService("CollectionService")
local function ringOf(m) return Vector3.new(m:GetAttribute("RingX") or 0, m:GetAttribute("RingY") or 0, m:GetAttribute("RingZ") or 0) end
local function hoopFor(pos)
	local best, bestD = H, nil
	for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
		if m:IsA("Model") and m:GetAttribute("RingX") then
			local d = (ringOf(m) - pos).Magnitude
			if not bestD or d < bestD then best, bestD = m, d end
		end
	end
	return best
end

-- ---- the tool follows ownership: whoever has Item_slingshot carries one, on every spawn and the moment it is bought
local function give(player)
	if (player:GetAttribute("Item_slingshot") or 0) <= 0 then return end
	local char = player.Character
	if not char then return end
	local pack = player:FindFirstChildOfClass("Backpack")
	if (pack and pack:FindFirstChild("Slingshot")) or char:FindFirstChild("Slingshot") then return end
	local t = toolTemplate:Clone()
	t.Name = "Slingshot"
	t.Parent = pack or player
end
local function watch(player)
	player.CharacterAdded:Connect(function() task.wait(0.6); give(player) end)
	player:GetAttributeChangedSignal("Item_slingshot"):Connect(function() give(player) end)
	if player.Character then task.defer(give, player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- the projectile: the same acorn that lies about the map, cut loose and welded into one piece
local function makeAcorn(from, velocity)
	local m = template:Clone()
	m.Name = "ShotAcorn"
	local nut = m.PrimaryPart or m:FindFirstChild("Nut")
	for _, d in ipairs(m:GetDescendants()) do
		if d.Name == "Hit" then d:Destroy() end
	end
	-- A SHOT YOU CAN SEE. The acorns on the ground are small on purpose; one of those doing a hundred studs a
	-- second twenty studs away is a speck ("the visual of the acorn flying is very difficult to see"). So the
	-- shot is bigger, throws off far more sparkle, and drags a golden ribbon that draws the whole arc.
	m:ScaleTo(H:GetAttribute("ShotScale") or 1)
	m:PivotTo(CFrame.new(from))
	local sp = nut:FindFirstChildOfClass("ParticleEmitter")
	if sp then
		sp.Rate = 40; sp.Speed = NumberRange.new(1, 3); sp.Lifetime = NumberRange.new(0.4, 0.9)
		sp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
		sp.Transparency = NumberSequence.new(0.1)
	end
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(-nut.Size.X * 0.4, 0, 0); a0.Parent = nut
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(nut.Size.X * 0.4, 0, 0); a1.Parent = nut
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 244, 210))
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1)})
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15)})
	trail.Lifetime = 0.6; trail.MinLength = 0.05; trail.LightEmission = 1; trail.FaceCamera = true
	trail.Parent = nut
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanQuery = false
			if p == nut then
				p.CanCollide = true; p.CanTouch = true; p.Massless = false
			else
				p.CanCollide = false; p.CanTouch = false; p.Massless = true
				local w = Instance.new("WeldConstraint"); w.Part0 = nut; w.Part1 = p; w.Parent = p
			end
		end
	end
	-- the sound of the flight, on the acorn so it goes where the acorn goes; slowed with the acorn in the cinematic
	local flyId = tonumber(H:GetAttribute("FlySoundId")) or 0
	local fly
	if flyId > 0 then
		fly = Instance.new("Sound"); fly.Name = "Fly"; fly.SoundId = "rbxassetid://" .. flyId
		fly.Volume = H:GetAttribute("FlyVolume") or 0.8; fly.RollOffMaxDistance = 90; fly.Parent = nut
	end
	m.Parent = workspace
	if fly then fly:Play() end
	nut:SetNetworkOwner(nil)                                -- the server flies it, so the ring sees the truth
	nut.AssemblyLinearVelocity = velocity
	nut.AssemblyAngularVelocity = Vector3.new(6, 2, 4)
	Debris:AddItem(m, 14)
	return nut
end

local passportRounds,passportShots={},{}
local function recordShot(nut,scored,prize)
 local rec=passportShots[nut];if not rec then return end;passportShots[nut]=nil
 local r=rec.round;r.results[rec.index]={scored=scored,prize=prize or 0}
 local streak,best,baskets,won,resolved=0,0,0,0,0
 for i=1,r.n do
  local result=r.results[i];if not result then break end
  resolved+=1
  if result.scored then streak+=1;baskets+=1;won+=result.prize;best=math.max(best,streak) else streak=0 end
 end
 if resolved==0 or not r.player.Parent then return end
 local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(r.player,"hoop",{streak=math.min(3,best),baskets=baskets,prize=won,shots=resolved,ongoing=resolved<r.n}) end
end
local function trackShot(player,nut,near)
 if not near then return end
 local r=passportRounds[player]
 if not r or r.n>=3 or os.clock()-r.started>(H:GetAttribute("RestSeconds") or 60) then r={player=player,n=0,results={},started=os.clock()};passportRounds[player]=r end
 r.n+=1;passportShots[nut]={round=r,index=r.n}
end

-- ---- the basket
local function basket(player, nut, hoop)
	hoop = hoop or H
	local centre = hoop:FindFirstChild("RingCentre")
	local burst = centre and centre:FindFirstChildOfClass("ParticleEmitter")
	local prize = H:GetAttribute("Prize") or 3
 recordShot(nut,true,prize)
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + prize)
	award:Fire(player, prize)
	items:Fire(player, "baskets", 1)
	picked:FireClient(player, have + prize, ringOf(hoop))
	shoot:FireClient(player, "basket", prize)
	if burst then burst.Rate = 120; task.delay(0.6, function() burst.Rate = 0 end) end
	-- the whistle as it drops through, the cheer a beat later, both from the ring so the clearing hears them
	local function ringSound(attr, delay)
		local id = tonumber(H:GetAttribute(attr)) or 0
		if id <= 0 or not centre then return end
		task.delay(delay, function()
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = H:GetAttribute("BasketVolume") or 1.0
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 20; s.RollOffMaxDistance = 250
			s.Parent = centre; s:Play(); Debris:AddItem(s, 15)
		end)
	end
	ringSound("BasketWhistleId", 0)
	ringSound("BasketCheerId", 0.35)
	print(string.format("%s: BASKET by %s (+%d, now %d)", hoop.Name, player.Name, prize, have + prize))
end

-- ---- shots
local live = {}                                          -- nut -> {player, last, born}
local lastShot = {}
-- THREE SHOTS, THEN A REST, at the croc and the hoops alike (Shannon, Sep 26: "make a cooldown so players don't just stay
-- there for 5 minutes shooting to harvest acorns ... allow 3 shots and then a cooldown period" - "cool down for both").
-- Counted here, on the server. ShotsBeforeRest / RestSeconds on the Hoop.
local volleys = {}                                       -- player -> {n = shots so far, last = when, restUntil = when}
-- AT THE LAGOON a shot flies AT something (the client says what): "croc" is the top of his head where it will be when
-- the acorn gets there (CrocServer's CrocAim function answers with where his head is and how fast he's going), "point"
-- the spot under the cursor. The flight is an arc that comes down exactly there - the farther, the longer and higher.
-- The hoop's fixed high lob, timed by the draw, could not hit a swimming croc.
local function flightTime(d) return math.clamp(0.35 + d / 90, 0.45, 1.1) end
local function aimedTarget(kind, point, from)
	if kind == "croc" then
		local lag = workspace:FindFirstChild("Lagoon")
		local fn = lag and lag:FindFirstChild("CrocAim")
		if fn and fn:IsA("BindableFunction") then
			local ok, head, vel = pcall(function() return fn:Invoke() end)
			if ok and typeof(head) == "Vector3" then
				local target = head
				if typeof(vel) == "Vector3" then
					for _ = 1, 3 do target = head + vel * flightTime((target - from).Magnitude) end   -- where he'll be
				end
				return target
			end
		end
	end
	if typeof(point) == "Vector3" and point.X == point.X and point.Y == point.Y and point.Z == point.Z then return point end
	return nil
end
shoot.OnServerEvent:Connect(function(player, dir, power, kind, point)
	if typeof(dir) ~= "Vector3" or type(power) ~= "number" then return end
	if dir.Magnitude < 0.5 or dir.X ~= dir.X then return end
	power = math.clamp(power, 0, 1)
	local char = player.Character
	local tool = char and char:FindFirstChild("Slingshot")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tool and hum and hum.Health > 0) then return end
	local now = os.clock()
	if now - (lastShot[player] or 0) < 0.5 then return end
	lastShot[player] = now
	local volley = volleys[player] or {n = 0, last = 0, restUntil = 0}; volleys[player] = volley
	if now < volley.restUntil then shoot:FireClient(player, "rest", math.ceil(volley.restUntil - now)) return end
	if now - volley.last > (H:GetAttribute("RestSeconds") or 60) then volley.n = 0 end
	local cost = H:GetAttribute("ShotCost") or 1
	local have = player:GetAttribute("Acorns") or 0
	if have < cost then shoot:FireClient(player, "no", "You need an acorn to shoot. Find one first.") return end
	player:SetAttribute("Acorns", have - cost)
	award:Fire(player, -cost)
	if volley then
		volley.n += 1; volley.last = now
		if volley.n >= (H:GetAttribute("ShotsBeforeRest") or 3) then
			local rest = H:GetAttribute("RestSeconds") or 60
			volley.n = 0; volley.restUntil = now + rest
			shoot:FireClient(player, "rest", rest, true)
		end
	end
	local eyeP = char:FindFirstChild("Head")
	local eye = eyeP and eyeP.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))
	local target = (kind == "croc" or kind == "point") and aimedTarget(kind, point, eye)
	if target then
		local flat = (target - eye) * Vector3.new(1, 0, 1)
		local range = H:GetAttribute("AimRange") or 90
		if flat.Magnitude > range then target = Vector3.new(eye.X, target.Y, eye.Z) + flat.Unit * range; flat = flat.Unit * range end
		local from = eye + (flat.Magnitude > 0.1 and flat.Unit * 2.0 or Vector3.zero) + Vector3.new(0, 0.4, 0)
		local T = flightTime((target - from).Magnitude)
		local nut = makeAcorn(from, (target - from) / T + Vector3.new(0, 0.5 * workspace.Gravity * T, 0))
		nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
		shoot:FireClient(player, "shot", power)
		return
	end
	-- LAUNCH FROM THE HEAD, not from the tool's handle: the server's copy of the handle sits about a stud and
	-- a half from where the client sees it (the arm's tool-hold pose is not the same on both sides), and a
	-- launch point the two disagree on is an arc the player cannot learn. The head replicates exactly, and
	-- two studs along the aim from there is clear of the body.
	-- the aim gives the direction along the ground; the arc is fixed
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.05 then flat = char.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1) end
	local e = math.rad(H:GetAttribute("Elevation") or 66)
	dir = flat.Unit * math.cos(e) + Vector3.new(0, math.sin(e), 0)
	local head = char:FindFirstChild("Head")
	local from = (head and head.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))) + dir * 2.2
	local lo, hi = H:GetAttribute("MinSpeed") or 45, H:GetAttribute("MaxSpeed") or 115
	local nut = makeAcorn(from, dir * (lo + (hi - lo) * power))
	nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
	live[nut] = {player = player, last = nut.Position, born = now, start = nut.Position, hoop = hoopFor(from)}
 trackShot(player,nut,((from-ringOf(hoopFor(from)))*Vector3.new(1,0,1)).Magnitude<=(H:GetAttribute("MissRange") or 80))
	shoot:FireClient(player, "shot", power)
end)

-- Every frame, each acorn in the air is checked. Two things happen here:
--   * SCORING: crossing the plane of the ring on the way DOWN inside the opening. A trigger part would miss a
--     fast acorn between physics steps; a line between two positions cannot.
--   * THE CINEMATIC: once an acorn is descending, its landing point is known (no drag). If it will cross inside
--     the opening within SlowLead seconds, it is anchored and walked along that same parabola at SlowMo speed,
--     the shooter's camera is told to cut in, and the basket is paid at the moment it passes the ring. Then it
--     is handed back to physics to drop through the net.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local g = workspace.Gravity
	local nutR = ((template.PrimaryPart or template:FindFirstChild("Nut")).Size.X * (H:GetAttribute("ShotScale") or 1)) / 2
	local R = (H:GetAttribute("RingRadius") or 2.0) - nutR - 0.1        -- the whole acorn inside the opening
	local SLOW = H:GetAttribute("SlowMo") or 0.35
	local LEAD = H:GetAttribute("SlowLead") or 0.7
	for nut, rec in pairs(live) do
		local rc = ringOf(rec.hoop or H)
		if not nut.Parent or now - rec.born > 14 then
   recordShot(nut,false,0)
			live[nut] = nil
		elseif rec.cine then
			local c = rec.cine
			local tau = (now - c.t0) * SLOW                                   -- flight time, slowed
			local pos = c.p0 + c.v0 * tau + Vector3.new(0, -0.5 * g * tau * tau, 0)
			nut.CFrame = CFrame.new(pos) * CFrame.Angles(tau * 4, tau * 2.5, 0)
			if not c.scored and tau >= c.tCross then
				c.scored = true
				basket(rec.player, nut, rec.hoop)
			end
			if tau >= c.tCross + 0.22 then                                    -- through the net: physics again
				nut.Anchored = false
				nut.AssemblyLinearVelocity = c.v0 + Vector3.new(0, -g * tau, 0)
				live[nut] = nil
			end
		else
			local cur, vel = nut.Position, nut.AssemblyLinearVelocity
			if vel.Y < 0 then rec.peaked = true end
			-- A MISS: it has peaked and come back down past the ring's plane, or past where it started for a
			-- shot that never got that high, without scoring. The shooter hears the crowd's "ohhh"; nobody else.
			if rec.peaked and not rec.missed and (cur.Y < rc.Y - 1.5 or cur.Y < rec.start.Y - 0.5)
				and ((rec.start - rc) * Vector3.new(1, 0, 1)).Magnitude < (H:GetAttribute("MissRange") or 80) then   -- no crowd "ohhh" for shots nowhere near a hoop
				rec.missed = true
    recordShot(nut,false,0)
				live[nut] = nil
				shoot:FireClient(rec.player, "miss")
			elseif rec.last.Y > rc.Y and cur.Y <= rc.Y then
				local f = (rec.last.Y - rc.Y) / math.max(rec.last.Y - cur.Y, 1e-6)
				local x = rec.last:Lerp(cur, f)
				if ((x - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					live[nut] = nil
					basket(rec.player, nut, rec.hoop)
				end
			elseif now - rec.born > 0.05 then
				-- where will it come down through the ring plane, and when? (the larger root is the descending
				-- crossing, whether the acorn is still rising or already falling - so the slow motion can begin
				-- before the peak and the shooter sees it crest and drop)
				local h = cur.Y - rc.Y
				local disc = vel.Y * vel.Y + 2 * g * h
				local t = disc >= 0 and (vel.Y + math.sqrt(disc)) / g or -1
				local land = cur + Vector3.new(vel.X * t, 0, vel.Z * t)
				if t >= 0.1 and t <= LEAD and ((land - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					rec.cine = {t0 = now, p0 = cur, v0 = vel, tCross = t, scored = false}
					local fly = nut:FindFirstChild("Fly"); if fly then fly.PlaybackSpeed = SLOW end
					nut.Anchored = true
					nut.AssemblyLinearVelocity = Vector3.zero
					shoot:FireClient(rec.player, "cine", nut, rc, (t + 0.22) / SLOW)
				end
			end
			rec.last = cur
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) lastShot[p] = nil; volleys[p] = nil;passportRounds[p]=nil;for nut,r in pairs(passportShots) do if r.round.player==p then passportShots[nut]=nil end end end)
print("SlingServer: ready")
]==]
	local s = Instance.new("Script"); s.Name = "SlingServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = H
	H.Parent = workspace

	local parts = 0
	for _, p in ipairs(H:GetDescendants()) do if p:IsA("BasePart") then parts += 1 end end
	print(string.format("Hoop: %d parts at %.0f,%.0f | cleared %d: %s | ring %.1f up, opening %.1f wide | stone circle %.0f studs out at %.0f,%.0f | slingshot tool in ServerStorage | %d-%d studs/s over %.1fs, %d acorn a shot, %d for a basket",
		parts, HX, HZ, #cleared, #cleared > 0 and table.concat(cleared, ", ") or "nothing", RING_UP, RING_R * 2, MARK, mk.X, mk.Z, H:GetAttribute("MinSpeed"), H:GetAttribute("MaxSpeed"), H:GetAttribute("Charge"),
		H:GetAttribute("ShotCost"), H:GetAttribute("Prize")))
	return H
end

-- The painter's gallery: the Acorn Store's "Sit for a portrait" (id "portrait", 80 acorns, as often as you like).
-- The painter squirrel stays exactly where he is, painting the river; along the hedge row at the back of his lawn
-- stand TWELVE EASELS in a line facing the buildings, each holding one framed portrait - the twelve newest
-- sitters anyone has bought, newest at the left (as you face them). A portrait is a head-and-shoulders likeness
-- (Roblox's own render of that player's current avatar, given a warm, painted finish) with a brass name plaque
-- on the easel's ledge. Buy again and you move back to the newest easel. Shannon: "separate paintings on easels
-- lined up facing toward the buildings, back up against the back bushes next to him" (the first version was a
-- display wall, which "really does not go with the scenery").
--
-- The easels are the painter's own easel's wood and canvas, copied (the village kit's "easel", without his
-- river painting, pot and brush), so they match him; kit models carry pivots far from their parts, so every clone is placed by its
-- bounding box, and turned by measuring which way its canvas faces.
--
-- HOW IT IS KEPT: the list of sitters (user id, name, time) is the gallery's own save, DataStore "PortraitWall"
-- key "latest", merged with UpdateAsync so two servers cannot lose each other's sitters. The purchase itself is
-- the shop's: its AwardItems(player, "portrait", 1) is the signal (Sep 26: the old signal, a RISING Item_portrait,
-- missed every first purchase), and the count painted per player is kept beside the list (painted_u<id>) so an
-- unpainted purchase is made good on the next visit. Nothing here touches the progress save. Without DataStore access (Studio, API off) the gallery runs from
-- memory for the session.
-- Re-runnable: rebuilds the easels and both scripts (and removes the old PortraitWall if it is still about).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local GILT, BRASS, CANVAS = C(214, 176, 60), C(190, 146, 44), C(246, 240, 226)
	local rng = Random.new(7)
	-- THE L. Four easels follow the river bank south from the painter (the bank runs diagonally from beside him to
	-- the hedge corner: edge x = his x - 6 + 0.77 * (z - his z), measured), standing 2.8 studs inland with their
	-- backs to the water, facing the lawn; eight more stand across the back in front of the hedges facing the
	-- buildings. Slot 1, the newest sitter, is the easel nearest the painter - his latest work. Shannon: "line them
	-- along the river from the painter to the hill for a few and the rest across the back".
	local RIVER, BACK = opts.river or 4, opts.back or 8
	local N = RIVER + BACK
	-- Shannon (Sep 25): "There are too many easels; please remove the last 3 on the end" - the three at the far end of
	-- the back row go. The layout is still worked out for all twelve, so the nine that stay do not move.
	local SHOW = math.min(N, opts.show or 9)
	local BACK_X0, BACK_X1, BACK_Z = opts.x0 or 202, opts.x1 or 229, opts.z or -3.5

	-- every earlier copy goes (by name, over a snapshot: an ipairs over {FindFirstChild(a), FindFirstChild(b)} stops at
	-- the first nil, which once left three galleries stacked on the same spot)
	for _, old in ipairs(workspace:GetChildren()) do
		if old.Name == "PortraitWall" or old.Name == "PortraitGallery" then old:Destroy() end
	end
	-- the painter's easel is the pattern
	local painter, pattern
	for _, m in ipairs(workspace:GetDescendants()) do if m:IsA("Model") and m.Name:lower() == "painter_squirrel_color" then painter = m break end end
	local pc = painter and painter:GetBoundingBox().Position
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name:lower():find("easel") and pc and (m:GetBoundingBox().Position - pc).Magnitude < 12 then pattern = m break end
	end
	assert(pattern, "PortraitGallery: the painter's easel was not found")

	local G = Instance.new("Model"); G.Name = "PortraitGallery"
	-- Keep the portrait reveal distinct from the squirrel-find fanfare. These attributes make the
	-- cue easy to retune without rebuilding the gallery; the default is a gentle cluster of chimes.
	G:SetAttribute("RevealSound", opts.revealSound or "rbxassetid://9116394876")
	G:SetAttribute("RevealVolume", opts.revealVolume or 0.32)
	G:SetAttribute("RevealSpeed", opts.revealSpeed or 0.88)
	local slots = Instance.new("Folder"); slots.Name = "Slots"; slots.Parent = G
	local function part(name, size, cf, colour, material, parent)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
		p.Color = colour; p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true; p.CanCollide = false; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	-- an easel, standing on the ground at (x, z), its front turned to faceDir (plus a small turn), by bounding box
	local function placeEasel(slot, x, z, faceDir, turn)
		-- only the wood and the blank canvas come along: the pattern carries the painter's own river painting as
		-- little parts (Sky, Meadow, River, Bank, Shore, Trunk, Pine, Tree, Rock, Sun) plus his pot and brush, so
		-- rather than clone the model and prune it (pruning eleven fresh clones in one go left strokes behind),
		-- the two parts are copied out on their own
		local e = Instance.new("Model"); e.Name = "Easel"
		for _, name in ipairs({"Easel", "Canvas"}) do
			local src = pattern:FindFirstChild(name, true)
			assert(src, "PortraitGallery: the pattern has no " .. name)
			src:Clone().Parent = e
		end
		e.Parent = slot
		local canvas = e:FindFirstChild("Canvas", true)
		assert(canvas, "PortraitGallery: the easel has no Canvas")
		-- WHICH WAY IS THE FRONT: the side the canvas hangs on, read off the geometry (canvas centre minus wood
		-- centre, flat). The kit mesh imports facing +z and the village builder turns every easel by a half turn,
		-- so a part axis is not to be trusted here ("your easels are facing the wrong direction").
		local wood = e:FindFirstChild("Easel", true)
		local function front()
			local v = (canvas.Position - wood.Position) * Vector3.new(1, 0, 1)
			return v.Unit
		end
		local target = faceDir
		local f = front()
		local ang = math.atan2(f:Cross(target).Y, f:Dot(target))
		e:PivotTo(e:GetPivot() * CFrame.Angles(0, ang, 0))
		if front():Dot(target) < 0.99 then e:PivotTo(e:GetPivot() * CFrame.Angles(0, -2 * ang, 0)) end
		e:PivotTo(e:GetPivot() * CFrame.Angles(0, turn, 0))                 -- the small hand-placed turn
		-- then stand it where it belongs, feet on the ground
		local cf, size = e:GetBoundingBox()
		-- a WORLD-space move (translation on the left): after the half-turn, a move on the right would go the
		-- other way and mirror the row across the lawn
		e:PivotTo(CFrame.new(Vector3.new(x, size.Y / 2, z) - cf.Position) * e:GetPivot())
		for _, d in ipairs(e:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
		return canvas, front()
	end

	-- the positions: along the bank first (nearest the painter first), then across the back west to east
	local LAYOUT = {}
	local bankDir = Vector3.new(0.77, 0, 1).Unit                         -- the bank, heading south-east
	local inland = Vector3.new(bankDir.Z, 0, -bankDir.X)                  -- its inland normal (+x, -z)
	for k = 0, RIVER - 1 do
		local dz = 7 + 3.5 * k
		local edge = Vector3.new(pc.X - 6 + 0.77 * dz, 0, pc.Z + dz)
		local pos = edge + inland * 2.8
		LAYOUT[#LAYOUT + 1] = {x = pos.X, z = pos.Z, face = inland}
	end
	for k = 0, BACK - 1 do
		LAYOUT[#LAYOUT + 1] = {x = BACK_X0 + (BACK_X1 - BACK_X0) * k / (BACK - 1), z = BACK_Z + rng:NextNumber(-0.3, 0.3), face = Vector3.new(0, 0, -1)}
	end

	-- THE PICTURE'S DRESSING. Shannon: "do it with a background and maybe silly looking in some way ... different
	-- variations of backgrounds from places in the game and some funny things", "I like the different backgrounds and
	-- companions", then, of the first drawn set, "so far the only one that has looked nice background wise was the one
	-- of the lavender fields" and "it should look like a painting ... use my screenshots as the example". The avatar
	-- render is transparent round the figure, so a painted scene sits behind it and a companion on top: five scenes
	-- composed after her screenshots (pines on the lawn, the fountain courtyard, the lavender field, the windmill in
	-- the distance, the cafe terrace) and four companions (a squirrel on the shoulder, a photobomber hanging from the
	-- top edge, the painter's own cameo, a pigeon on the bottom edge) - one sitter in five gets none. Nothing goes on
	-- the head or face: an acorn crown and a monocle were tried and looked pasted on. The server picks from the
	-- sitter's user id, so a player always gets the same picture.
	local function shape(parent, name, pos, size, colour, round, rot, z)
		local f = Instance.new("Frame"); f.Name = name; f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(pos[1], pos[2])
		f.Size = UDim2.fromScale(size[1], size[2]); f.BackgroundColor3 = colour; f.BorderSizePixel = 0; f.Rotation = rot or 0; f.ZIndex = z or 5
		if round then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(round, 0); c.Parent = f end
		f.Parent = parent
		return f
	end
	local function gradient(f, top, bottom)
		local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(top, bottom); g.Rotation = 90; g.Parent = f
	end
	local function group(parent, name)
		local g = Instance.new("Frame"); g.Name = name; g.Size = UDim2.fromScale(1, 1); g.BackgroundTransparency = 1; g.Visible = false; g.ZIndex = 5; g.Parent = parent
		return g
	end
	-- THE PAINTER'S HAND. Shannon: "it should look like a painting, not photo image of the game" and "why can't you
	-- just use my screenshots as the example?" - so each backdrop is composed after her own screenshot of the spot, in
	-- soft shapes and dabs of colour: pines on the lawn, the fountain courtyard, the lavender field (the first to pass,
	-- kept as it was), the windmill on its rise in the distance, the cafe terrace with the macaron table. One template
	-- per scene lives in the gallery's Scenes folder (Frames render nowhere there); the server clones the chosen one
	-- into an easel's Backdrop, so an easel carries one scene, not six.
	local function blob(parent, name, x, y, w, h, colour, t, rot)
		local f = shape(parent, name, {x, y}, {w, h}, colour, 1, rot)
		if t and t > 0 then f.BackgroundTransparency = t end
		return f
	end
	local function stroke(parent, name, x, y, len, thick, colour, rot, t)
		local f = shape(parent, name, {x, y}, {len, thick}, colour, 0.5, rot)
		if t and t > 0 then f.BackgroundTransparency = t end
		return f
	end
	local function dabs(parent, name, rng, x0, y0, x1, y1, n, w, h, colours, t)
		for _ = 1, n do
			blob(parent, name, rng:NextNumber(x0, x1), rng:NextNumber(y0, y1), w * rng:NextNumber(0.6, 1.4), h * rng:NextNumber(0.6, 1.4),
				colours[rng:NextInteger(1, #colours)], math.clamp(t + rng:NextNumber(-0.12, 0.12), 0, 0.95), rng:NextNumber(-20, 20))
		end
	end
	local function sky(parent, name, top, bottom)
		local f = shape(parent, name, {0.5, 0.5}, {1, 1}, top, nil, 0, 1); f.Visible = false; f.ClipsDescendants = true; gradient(f, top, bottom)
		return f
	end
	local function canopy(parent, rng, x, y, r, dark, mid, light)
		blob(parent, "Canopy", x, y, r * 2, r * 1.75, dark)
		for _ = 1, 6 do blob(parent, "Canopy", x + rng:NextNumber(-0.55, 0.55) * r, y + rng:NextNumber(-0.45, 0.4) * r, r * 0.95, r * 0.8, mid, 0.15, rng:NextNumber(-30, 30)) end
		for _ = 1, 4 do blob(parent, "Canopy", x + rng:NextNumber(-0.6, 0.15) * r, y + rng:NextNumber(-0.7, -0.15) * r, r * 0.5, r * 0.4, light, 0.3, rng:NextNumber(-30, 30)) end
	end
	local function pine(parent, x, top, h, dark, mid, light)                -- four tiers of soft diamonds, lit on the left
		local w = 0.36 * h
		for _, tier in ipairs({{0.55, 1.0}, {0.36, 0.8}, {0.18, 0.6}, {0, 0.4}}) do    -- bottom tier first; each upper one sits on the one below
			local side, tip = w * tier[2], top + tier[1] * h
			shape(parent, "Tier", {x, tip + 0.72 * side}, {side, side}, dark, 0.1, 45)
			shape(parent, "Tier", {x - 0.14 * side, tip + 0.62 * side}, {side * 0.5, side * 0.5}, mid, 0.1, 45)
			blob(parent, "Tip", x - 0.04 * side, tip + 0.28 * side, side * 0.42, side * 0.2, light, 0.2)
		end
	end
	local function cypress(parent, x, base, h, w, colour)
		blob(parent, "Cypress", x, base - h / 2, w, h, colour)
		blob(parent, "Cypress", x - w * 0.18, base - h * 0.55, w * 0.4, h * 0.62, C(78, 126, 86), 0.35)
	end
	local function tree(parent, rng, x, base, r, dark, mid, light)         -- a small round tree standing on a line
		shape(parent, "Trunk", {x, base - r * 0.5}, {r * 0.16, r * 1.1}, C(110, 82, 58), 0.4)
		canopy(parent, rng, x, base - r * 1.5, r, dark, mid, light)
	end
	local function paintScenes(scenes)
		-- scene 1: pines on the lawn (her first screenshot) - conifers either side, far pines in the haze, the sky open
		-- where the head goes
		do
			local rng = Random.new(101)
			local s = sky(scenes, "Scene1", C(128, 176, 234), C(222, 236, 248))
			blob(s, "Cloud", 0.2, 0.12, 0.26, 0.07, C(255, 255, 255), 0.35)
			blob(s, "Cloud", 0.74, 0.08, 0.3, 0.08, C(255, 255, 255), 0.3)
			blob(s, "Haze", 0.5, 0.57, 1.5, 0.2, C(168, 202, 206), 0.4)
			for _, f in ipairs({{0.36, 0.4, 0.2}, {0.48, 0.43, 0.16}, {0.6, 0.41, 0.18}, {0.68, 0.44, 0.14}}) do pine(s, f[1], f[2], f[3], C(96, 146, 126), C(112, 160, 138), C(150, 190, 160)) end
			pine(s, 0.02, 0.24, 0.44, C(38, 92, 62), C(58, 122, 78), C(122, 178, 104))
			pine(s, 0.25, 0.3, 0.36, C(44, 100, 66), C(64, 128, 82), C(128, 182, 108))
			pine(s, 0.11, 0.06, 0.68, C(36, 88, 60), C(56, 118, 76), C(118, 174, 102))
			pine(s, 0.76, 0.32, 0.34, C(44, 100, 66), C(64, 128, 82), C(128, 182, 108))
			pine(s, 0.9, 0.02, 0.72, C(34, 86, 58), C(54, 116, 74), C(116, 172, 100))
			local grass = shape(s, "Grass", {0.5, 0.79}, {1, 0.44}, C(112, 172, 92)); gradient(grass, C(128, 190, 102), C(84, 142, 78))
			blob(s, "Sunlit", 0.5, 0.6, 1.2, 0.08, C(160, 210, 118), 0.3)
			for _, x in ipairs({0.11, 0.9}) do blob(s, "Shade", x, 0.63, 0.24, 0.05, C(70, 128, 72), 0.3); shape(s, "Trunk", {x, 0.585}, {0.03, 0.09}, C(96, 66, 40), 0.3) end
			blob(s, "Bush", 0.07, 0.65, 0.22, 0.1, C(66, 124, 70))
			blob(s, "Bush", 0.1, 0.63, 0.1, 0.06, C(92, 150, 84), 0.2)
			dabs(s, "Dab", rng, -0.05, 0.62, 1.05, 1.02, 40, 0.12, 0.028, {C(140, 196, 104), C(98, 156, 84), C(122, 180, 96), C(166, 212, 122)}, 0.3)
		end
		-- scene 2: the fountain courtyard (her second) - the fountain beside the sitter: plume and crown top left, basin
		-- bottom left, a plane tree behind it; the pink townhouse with its balcony and shutters on the right
		do
			local rng = Random.new(202)
			local s = sky(scenes, "Scene2", C(150, 192, 238), C(226, 238, 250))
			local wall = shape(s, "Wall", {0.7, 0.3}, {0.64, 0.62}, C(240, 190, 200), 0.03); gradient(wall, C(246, 204, 212), C(232, 176, 190))
			dabs(s, "Plaster", rng, 0.4, 0, 1, 0.55, 12, 0.12, 0.05, {C(248, 210, 216), C(236, 182, 194)}, 0.6)
			stroke(s, "Rail", 0.7, 0.2, 0.56, 0.012, C(250, 248, 244), 0)
			for k = 0, 6 do shape(s, "Baluster", {0.45 + 0.083 * k, 0.235}, {0.008, 0.06}, C(250, 248, 244)) end
			stroke(s, "Rail", 0.7, 0.265, 0.56, 0.012, C(250, 248, 244), 0)
			for _, x in ipairs({0.56, 0.86}) do
				shape(s, "Window", {x, 0.42}, {0.09, 0.2}, C(150, 176, 206), 0.06)
				shape(s, "Shutter", {x - 0.065, 0.42}, {0.035, 0.2}, C(88, 140, 100), 0.1)
				shape(s, "Shutter", {x + 0.065, 0.42}, {0.035, 0.2}, C(88, 140, 100), 0.1)
			end
			shape(s, "Awning", {0.7, 0.555}, {0.58, 0.05}, C(80, 134, 94), 0.4)
			for k = 0, 5 do blob(s, "Scallop", 0.44 + 0.104 * k, 0.58, 0.1, 0.035, C(80, 134, 94)) end
			blob(s, "Haze", 0.2, 0.6, 0.7, 0.1, C(214, 226, 236), 0.4)
			canopy(s, rng, 0.1, 0.22, 0.17, C(62, 122, 66), C(90, 156, 84), C(140, 200, 110))
			shape(s, "Trunk", {0.1, 0.48}, {0.03, 0.22}, C(110, 82, 58), 0.4)
			shape(s, "Paving", {0.5, 0.92}, {1, 0.18}, C(202, 194, 182))
			dabs(s, "Dab", rng, 0, 0.84, 1, 1.0, 30, 0.09, 0.02, {C(188, 180, 168), C(216, 210, 200), C(196, 190, 178)}, 0.3)
			local fx = 0.24
			shape(s, "Column", {fx, 0.36}, {0.09, 0.6}, C(226, 240, 252), 1); s.Column.BackgroundTransparency = 0.08
			blob(s, "Crown", fx, 0.06, 0.22, 0.08, C(246, 251, 255), 0.1)
			blob(s, "Crown", fx - 0.12, 0.09, 0.09, 0.055, C(246, 251, 255), 0.25)
			blob(s, "Crown", fx + 0.12, 0.09, 0.09, 0.055, C(246, 251, 255), 0.25)
			blob(s, "Crown", fx, 0.125, 0.14, 0.05, C(230, 244, 255), 0.3)
			for k = 0, 8 do                                                     -- droplets falling in two arcs, crown to basin
				local t = k / 8
				blob(s, "Drop", fx - 0.05 - 0.26 * t, 0.08 + 0.54 * t * t, 0.046 - 0.014 * t, 0.05 - 0.016 * t, C(244, 250, 255), 0.08 + 0.1 * t)
				blob(s, "Drop", fx + 0.05 + 0.26 * t, 0.08 + 0.54 * t * t, 0.046 - 0.014 * t, 0.05 - 0.016 * t, C(244, 250, 255), 0.08 + 0.1 * t)
			end
			dabs(s, "Mist", rng, 0, 0.25, 0.5, 0.62, 16, 0.022, 0.022, {C(240, 248, 255), C(200, 228, 250)}, 0.4)
			blob(s, "Basin", fx, 0.69, 0.62, 0.17, C(198, 188, 172))
			blob(s, "Water", fx, 0.68, 0.52, 0.1, C(88, 168, 214))
			dabs(s, "Ripple", rng, 0, 0.65, 0.48, 0.71, 12, 0.09, 0.014, {C(176, 220, 244), C(70, 140, 190)}, 0.3)
			blob(s, "Rim", fx, 0.75, 0.6, 0.05, C(236, 230, 218))
			blob(s, "Foot", fx, 0.8, 0.46, 0.05, C(186, 176, 160))
		end
			-- scene 3: lavender rows before the chateau
			local s3 = shape(scenes, "Scene3", {0.5, 0.5}, {1, 1}, C(240, 205, 220), nil, 0, 1); s3.Visible = false; s3.ClipsDescendants = true; gradient(s3, C(236, 196, 214), C(255, 236, 226))
			shape(s3, "Hill", {0.6, 0.62}, {1.4, 0.4}, C(140, 168, 110), 1)
			shape(s3, "Roof", {0.3, 0.4}, {0.12, 0.12}, C(96, 112, 138), 0, 45)
			shape(s3, "Keep", {0.3, 0.52}, {0.14, 0.24}, C(214, 206, 190))
			shape(s3, "Roof", {0.4, 0.44}, {0.07, 0.07}, C(96, 112, 138), 0, 45)
			shape(s3, "Tower", {0.4, 0.54}, {0.06, 0.2}, C(226, 218, 200))
			for i, y in ipairs({0.7, 0.78, 0.86, 0.94}) do shape(s3, "Row", {0.5, y}, {1.3, 0.05 + 0.01 * i}, C(150 + 10 * i, 96, 190), 1, -8) end
		-- scene 4: the windmill on its rise (her fourth, but in the distance as she asked) - small, left of the head,
		-- the cypress row along the right horizon, meadow dabs in front
		do
			local rng = Random.new(404)
			local s = sky(scenes, "Scene4", C(118, 168, 230), C(206, 228, 246))
			blob(s, "Cloud", 0.78, 0.13, 0.3, 0.08, C(255, 255, 255), 0.3)
			blob(s, "Cloud", 0.7, 0.16, 0.2, 0.06, C(255, 255, 255), 0.35)
			blob(s, "Cloud", 0.16, 0.1, 0.22, 0.06, C(255, 255, 255), 0.45)
			blob(s, "FarHill", 0.2, 0.58, 0.8, 0.14, C(136, 172, 150), 0.25)
			blob(s, "FarHill", 0.78, 0.585, 0.9, 0.12, C(126, 166, 146), 0.3)
			local rise = blob(s, "Rise", 0.42, 0.82, 1.6, 0.56, C(104, 166, 84)); gradient(rise, C(124, 184, 96), C(82, 140, 74))
			blob(s, "Crest", 0.28, 0.62, 0.9, 0.12, C(132, 190, 100), 0.15)
			local mx = 0.22
			local tower = shape(s, "Tower", {mx, 0.465}, {0.08, 0.21}, C(232, 226, 212), 0.15); gradient(tower, C(240, 236, 226), C(212, 202, 186))
			shape(s, "Base", {mx, 0.555}, {0.1, 0.03}, C(200, 190, 174), 0.3)
			blob(s, "Cap", mx, 0.365, 0.105, 0.05, C(70, 64, 68))
			shape(s, "Door", {mx, 0.535}, {0.02, 0.04}, C(84, 58, 40), 0.5)
			blob(s, "Pane", mx, 0.45, 0.016, 0.02, C(120, 140, 160))
			for _, a in ipairs({25, 115}) do stroke(s, "Lattice", mx, 0.365, 0.3, 0.032, C(240, 238, 230), a, 0.62); stroke(s, "Sail", mx, 0.365, 0.32, 0.012, C(244, 242, 236), a, 0) end
			blob(s, "Hub", mx, 0.365, 0.016, 0.014, C(60, 54, 56))
			tree(s, rng, 0.07, 0.58, 0.035, C(62, 122, 66), C(90, 156, 84), C(140, 200, 110))
			tree(s, rng, 0.35, 0.585, 0.03, C(62, 122, 66), C(90, 156, 84), C(140, 200, 110))
			for k, x in ipairs({0.6, 0.66, 0.73, 0.79, 0.86, 0.92, 0.98}) do cypress(s, x, 0.585 + 0.004 * k, 0.17 + 0.03 * ((k % 3) / 2), 0.024, C(40, 82, 56)) end
			dabs(s, "Dab", rng, -0.05, 0.66, 1.05, 1.02, 50, 0.1, 0.024, {C(140, 198, 106), C(100, 158, 84), C(124, 182, 96), C(164, 210, 120)}, 0.35)
			dabs(s, "Poppy", rng, 0, 0.8, 1, 1.0, 10, 0.02, 0.016, {C(220, 70, 60), C(236, 100, 80)}, 0.2)
		end
		-- scene 5: the cafe terrace (her third) - the pink front and green awning to the left over a mullioned window,
		-- the street hazy to the right with a lamp post, a bentwood chair beside the sitter, and at their left hand the
		-- little round table with the cake stand of macarons
		do
			local rng = Random.new(505)
			local s = sky(scenes, "Scene5", C(178, 206, 240), C(236, 240, 246))
			blob(s, "FarHouse", 0.8, 0.5, 0.5, 0.36, C(214, 206, 226), 0.5)
			local roof = shape(s, "Roof", {0.82, 0.36}, {0.3, 0.05}, C(196, 182, 206), 0.5); roof.BackgroundTransparency = 0.45
			shape(s, "Street", {0.75, 0.93}, {0.7, 0.18}, C(196, 190, 180))
			dabs(s, "Dab", rng, 0.4, 0.85, 1.02, 1.02, 22, 0.09, 0.02, {C(182, 176, 166), C(212, 206, 196)}, 0.3)
			shape(s, "Post", {0.68, 0.46}, {0.012, 0.42}, C(58, 56, 60), 0.5)
			shape(s, "Lantern", {0.68, 0.24}, {0.036, 0.05}, C(255, 232, 170), 0.3)
			blob(s, "Glow", 0.68, 0.24, 0.09, 0.1, C(255, 240, 200), 0.7)
			blob(s, "Cap", 0.68, 0.208, 0.046, 0.016, C(58, 56, 60))
			local wall = shape(s, "Wall", {0.22, 0.43}, {0.46, 0.9}, C(236, 178, 188), 0.02); gradient(wall, C(244, 196, 204), C(226, 162, 176))
			dabs(s, "Plaster", rng, 0, 0.3, 0.44, 0.85, 10, 0.1, 0.05, {C(246, 196, 204), C(228, 166, 178)}, 0.6)
			shape(s, "Frame", {0.2, 0.47}, {0.32, 0.36}, C(250, 248, 244), 0.04)
			local glass = shape(s, "Glass", {0.2, 0.47}, {0.27, 0.31}, C(232, 200, 160), 0.03); gradient(glass, C(246, 222, 184), C(214, 174, 130))
			blob(s, "Glow", 0.16, 0.42, 0.12, 0.1, C(255, 244, 220), 0.35)
			shape(s, "Mullion", {0.2, 0.47}, {0.012, 0.31}, C(250, 248, 244))
			shape(s, "Mullion", {0.2, 0.47}, {0.27, 0.012}, C(250, 248, 244))
			shape(s, "Awning", {0.22, 0.22}, {0.5, 0.09}, C(76, 136, 96), 0.3)
			for k = 0, 2 do shape(s, "Stripe", {0.07 + 0.15 * k, 0.22}, {0.03, 0.09}, C(120, 176, 130)) end
			for k = 0, 4 do blob(s, "Scallop", 0.02 + 0.1 * k, 0.265, 0.1, 0.04, C(76, 136, 96)) end
			shape(s, "Box", {0.2, 0.665}, {0.3, 0.045}, C(150, 110, 80), 0.2)
			dabs(s, "Flower", rng, 0.07, 0.63, 0.33, 0.655, 12, 0.03, 0.025, {C(240, 120, 150), C(220, 70, 80), C(250, 170, 190)}, 0.15)
			dabs(s, "Leaf", rng, 0.06, 0.64, 0.34, 0.665, 8, 0.03, 0.02, {C(90, 150, 90)}, 0.3)
			stroke(s, "ChairBack", 0.85, 0.5, 0.16, 0.03, C(128, 88, 58), 0, 0)
			shape(s, "ChairPost", {0.78, 0.6}, {0.02, 0.2}, C(128, 88, 58), 0.5)
			shape(s, "ChairPost", {0.92, 0.6}, {0.02, 0.2}, C(128, 88, 58), 0.5)
			stroke(s, "ChairSeat", 0.85, 0.7, 0.2, 0.03, C(128, 88, 58), 0, 0)
			shape(s, "ChairLeg", {0.79, 0.82}, {0.016, 0.2}, C(128, 88, 58), 0.5)
			shape(s, "ChairLeg", {0.91, 0.82}, {0.016, 0.2}, C(128, 88, 58), 0.5)
			shape(s, "TableLeg", {0.12, 0.8}, {0.024, 0.24}, C(70, 60, 55), 0.5)
		blob(s, "TableFoot", 0.12, 0.92, 0.14, 0.03, C(70, 60, 55))
		blob(s, "TableTop", 0.12, 0.665, 0.32, 0.09, C(230, 226, 220))
		blob(s, "Cloth", 0.12, 0.66, 0.3, 0.075, C(250, 248, 244))
			-- the cake stand of macarons on the window ledge, the cafe's display, where no sitter can hide it
			blob(s, "Plate", 0.14, 0.51, 0.19, 0.045, C(250, 250, 248))
			shape(s, "Stem", {0.14, 0.538}, {0.018, 0.05}, C(250, 250, 248))
			blob(s, "Foot", 0.14, 0.565, 0.09, 0.02, C(250, 250, 248))
			for _, m in ipairs({{0.08, 0.485, C(240, 130, 170)}, {0.145, 0.475, C(200, 120, 210)}, {0.21, 0.485, C(250, 170, 190)}, {0.13, 0.443, C(236, 110, 150)}}) do
				blob(s, "Macaron", m[1], m[2], 0.06, 0.042, m[3])
				stroke(s, "Filling", m[1], m[2], 0.056, 0.012, C(255, 236, 240), 0, 0.2)
			end
			blob(s, "Cup", 0.27, 0.62, 0.05, 0.045, C(250, 250, 248), nil)
			blob(s, "Coffee", 0.27, 0.605, 0.038, 0.014, C(90, 60, 40))
		end
	end
	local function dress(gui, img)
		local back = Instance.new("Frame"); back.Name = "Backdrop"; back.Size = UDim2.fromScale(1, 1); back.BackgroundTransparency = 1; back.ZIndex = 1; back.ClipsDescendants = true; back.Parent = gui   -- clipped: a tilted lavender row was showing over the gilt frame
		local over = Instance.new("Frame"); over.Name = "Overlay"; over.Size = UDim2.fromScale(1, 1); over.BackgroundTransparency = 1; over.ZIndex = 5; over.ClipsDescendants = true; over.Parent = gui
		-- THE COMPANIONS (Shannon: props on the head and face "do not look good" - they have to line up with features
		-- that differ between avatars; these live on the sitter's shoulder and in the corners, where nothing does).
		-- The shoulder squirrel is a child of the Portrait image, so he moves and scales with the sitter; the three
		-- corner companions are built twice, as drawn and mirrored ("M"), and the server shows the copy on the far
		-- side from a sitter who has been placed to one side of the picture (Shannon: "them sitting to the side").
		-- 1: a squirrel on the shoulder, with an acorn (in the sitter's own frame)
		local b1 = group(img, "Buddy1")
		shape(b1, "Tail", {0.9, 0.56}, {0.1, 0.24}, C(176, 96, 52), 1, 25)
		shape(b1, "Tail", {0.92, 0.46}, {0.09, 0.14}, C(196, 116, 64), 1, -30)
		shape(b1, "Body", {0.82, 0.68}, {0.13, 0.15}, C(186, 106, 56), 1)
		shape(b1, "Belly", {0.81, 0.7}, {0.07, 0.09}, C(240, 216, 190), 1)
		shape(b1, "Head", {0.8, 0.57}, {0.1, 0.1}, C(190, 110, 60), 1)
		shape(b1, "Ear", {0.77, 0.51}, {0.035, 0.05}, C(190, 110, 60), 1)
		shape(b1, "Ear", {0.84, 0.51}, {0.035, 0.05}, C(190, 110, 60), 1)
		shape(b1, "Eye", {0.79, 0.565}, {0.02, 0.02}, C(30, 20, 16), 1)
		shape(b1, "Nut", {0.75, 0.66}, {0.045, 0.055}, C(140, 92, 46), 1)
		local function corner(mirror)
			local sfx = mirror and "M" or ""
			local function S(parent, name, pos, size, colour, round, rot)
				return shape(parent, name, {mirror and (1 - pos[1]) or pos[1], pos[2]}, size, colour, round, (rot and mirror) and -rot or rot)
			end
			-- 2: the photobomber - hanging upside down from the top edge (top right as drawn), tail along the top, peering in
			local b2 = group(over, "Buddy2" .. sfx)
			S(b2, "Tail", {0.93, 0.06}, {0.22, 0.09}, C(176, 96, 52), 1, -15)
			S(b2, "Tail", {0.99, 0.13}, {0.08, 0.14}, C(196, 116, 64), 1, 20)
			S(b2, "Paw", {0.75, 0.025}, {0.04, 0.05}, C(160, 90, 50), 1)
			S(b2, "Paw", {0.87, 0.025}, {0.04, 0.05}, C(160, 90, 50), 1)
			S(b2, "Body", {0.81, 0.11}, {0.14, 0.17}, C(186, 106, 56), 1)
			S(b2, "Belly", {0.81, 0.12}, {0.075, 0.1}, C(240, 216, 190), 1)
			S(b2, "Head", {0.81, 0.235}, {0.11, 0.11}, C(190, 110, 60), 1)
			S(b2, "Ear", {0.775, 0.29}, {0.035, 0.05}, C(190, 110, 60), 1)
			S(b2, "Ear", {0.845, 0.29}, {0.035, 0.05}, C(190, 110, 60), 1)
			S(b2, "Eye", {0.79, 0.245}, {0.022, 0.022}, C(30, 20, 16), 1)
			S(b2, "Eye", {0.83, 0.245}, {0.022, 0.022}, C(30, 20, 16), 1)
			S(b2, "Nose", {0.81, 0.275}, {0.02, 0.016}, C(60, 30, 24), 1)
			-- 3: the painter's cameo - beret, palette and brush, peeking in (bottom left as drawn)
			local b3 = group(over, "Buddy3" .. sfx)
			S(b3, "Tail", {0.03, 0.78}, {0.09, 0.22}, C(176, 96, 52), 1, -20)
			S(b3, "Body", {0.12, 0.88}, {0.16, 0.2}, C(186, 106, 56), 1)
			S(b3, "Belly", {0.12, 0.9}, {0.09, 0.12}, C(240, 216, 190), 1)
			S(b3, "Head", {0.13, 0.735}, {0.12, 0.12}, C(190, 110, 60), 1)
			S(b3, "Ear", {0.095, 0.675}, {0.04, 0.055}, C(190, 110, 60), 1)
			S(b3, "Ear", {0.165, 0.675}, {0.04, 0.055}, C(190, 110, 60), 1)
			S(b3, "Eye", {0.155, 0.73}, {0.022, 0.022}, C(30, 20, 16), 1)
			S(b3, "Beret", {0.115, 0.665}, {0.16, 0.055}, C(30, 30, 38), 1, -12)
			S(b3, "Pompom", {0.09, 0.64}, {0.03, 0.03}, C(200, 50, 50), 1)
			S(b3, "Palette", {0.26, 0.86}, {0.14, 0.1}, C(232, 214, 176), 1, -15)
			S(b3, "Paint", {0.235, 0.845}, {0.03, 0.03}, C(220, 70, 70), 1)
			S(b3, "Paint", {0.27, 0.835}, {0.03, 0.03}, C(80, 140, 220), 1)
			S(b3, "Paint", {0.29, 0.87}, {0.03, 0.03}, C(240, 200, 70), 1)
			S(b3, "Brush", {0.21, 0.72}, {0.018, 0.18}, C(120, 84, 52), 1, 35)
			S(b3, "Tip", {0.265, 0.65}, {0.03, 0.04}, C(220, 70, 70), 1, 35)
			-- 4: a village pigeon on the bottom edge (bottom right as drawn), looking up at the sitter
			local b4 = group(over, "Buddy4" .. sfx)
			S(b4, "Body", {0.86, 0.9}, {0.15, 0.12}, C(150, 152, 160), 1)
			S(b4, "Wing", {0.89, 0.88}, {0.11, 0.07}, C(110, 112, 122), 1, 20)
			S(b4, "Neck", {0.8, 0.85}, {0.06, 0.06}, C(120, 150, 130), 1)
			S(b4, "Head", {0.785, 0.815}, {0.065, 0.065}, C(150, 152, 160), 1)
			S(b4, "Eye", {0.775, 0.81}, {0.018, 0.018}, C(240, 120, 40), 1)
			S(b4, "Beak", {0.745, 0.82}, {0.03, 0.03}, C(230, 150, 60), 0, 45)
			S(b4, "Foot", {0.84, 0.965}, {0.012, 0.03}, C(220, 120, 60))
			S(b4, "Foot", {0.88, 0.965}, {0.012, 0.03}, C(220, 120, 60))
		end
		corner(false); corner(true)
	end
	local scenes = Instance.new("Folder"); scenes.Name = "Scenes"; scenes.Parent = G
	paintScenes(scenes)
	for i = 1, SHOW do
		local slot = Instance.new("Model"); slot.Name = "Slot" .. i; slot.Parent = slots
		local L = LAYOUT[i]
		slot:SetAttribute("FaceX", L.face.X); slot:SetAttribute("FaceZ", L.face.Z)
		local canvas, outward = placeEasel(slot, L.x, L.z, L.face, math.rad(rng:NextNumber(-5, 5)))
		canvas.Name = "Canvas"; canvas.Color = CANVAS
		local ccf, csz = canvas.CFrame, canvas.Size                          -- the canvas: x across, y up, z thin
		local faceOut = (ccf.LookVector:Dot(outward) > 0) and Enum.NormalId.Front or Enum.NormalId.Back   -- the face that looks at the viewer
		-- a slim gilt frame round the canvas
		local b, fd = 0.14, csz.Z + 0.06
		part("Frame", Vector3.new(csz.X + 2 * b, b, fd), ccf * CFrame.new(0, csz.Y / 2 + b / 2, 0), GILT, Enum.Material.Metal, slot)
		part("Frame", Vector3.new(csz.X + 2 * b, b, fd), ccf * CFrame.new(0, -csz.Y / 2 - b / 2, 0), GILT, Enum.Material.Metal, slot)
		part("Frame", Vector3.new(b, csz.Y, fd), ccf * CFrame.new(csz.X / 2 + b / 2, 0, 0), GILT, Enum.Material.Metal, slot)
		part("Frame", Vector3.new(b, csz.Y, fd), ccf * CFrame.new(-csz.X / 2 - b / 2, 0, 0), GILT, Enum.Material.Metal, slot)
		-- the picture on the canvas's front face, empty until the server fills it
		local gui = Instance.new("SurfaceGui"); gui.Name = "Picture"; gui.Face = faceOut; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 140
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling            -- so the Overlay tree draws over the Portrait (Global mode ordered every shape by its own ZIndex, under the avatar)
		gui.Parent = canvas
		local img = Instance.new("ImageLabel"); img.Name = "Portrait"; img.Size = UDim2.fromScale(1, 1); img.BackgroundTransparency = 1; img.ZIndex = 2
		img.ScaleType = Enum.ScaleType.Crop; img.ImageColor3 = C(255, 236, 212); img.Image = ""; img.Visible = false; img.Parent = gui
		-- A live viewport can include the clothes and accessories equipped inside this experience;
		-- Roblox's user thumbnail only contains the player's website avatar.
		local vp = Instance.new("ViewportFrame"); vp.Name = "Portrait3D"; vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
		vp.Ambient = C(190, 176, 160); vp.LightColor = C(255, 238, 208); vp.LightDirection = Vector3.new(-0.5, -0.35, -1); vp.ZIndex = 2; vp.Visible = false; vp.Parent = gui
		local world = Instance.new("WorldModel"); world.Name = "World"; world.Parent = vp
		local cam = Instance.new("Camera"); cam.Name = "PortraitCamera"; cam.FieldOfView = 30; cam.Parent = vp; vp.CurrentCamera = cam
		img.ZIndex = 3
		dress(gui, img)
		local wash = Instance.new("Frame"); wash.Name = "Wash"; wash.Size = UDim2.fromScale(1, 1); wash.BackgroundColor3 = C(250, 226, 180); wash.BackgroundTransparency = 0.86; wash.BorderSizePixel = 0; wash.Visible = false; wash.ZIndex = 8; wash.Parent = gui
		local edge = Instance.new("UIStroke"); edge.Color = C(70, 46, 26); edge.Thickness = 3; edge.Transparency = 0.35; edge.Parent = wash
		-- the plaque on the ledge, just under the frame
		local ppos = ccf.Position - ccf.UpVector * (csz.Y / 2 + b + 0.26) + outward * (csz.Z / 2 + 0.04)
		local plaque = part("Plaque", Vector3.new(1.3, 0.3, 0.06), CFrame.lookAt(ppos, ppos + outward), BRASS, Enum.Material.Metal, slot)
		local pg = Instance.new("SurfaceGui"); pg.Face = Enum.NormalId.Front; pg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; pg.PixelsPerStud = 100; pg.Parent = plaque
		local pt = Instance.new("TextLabel"); pt.Name = "Name"; pt.Size = UDim2.fromScale(1, 1); pt.BackgroundTransparency = 1; pt.Font = Enum.Font.Antique
		pt.TextColor3 = C(60, 40, 16); pt.TextScaled = true; pt.Text = ""; pt.Parent = pg
		-- sparkle for the moment a portrait is set up
		local att = Instance.new("Attachment"); att.Name = "Sparkle"; att.Parent = canvas
		att.WorldPosition = canvas.Position + outward * 0.4
		local em = Instance.new("ParticleEmitter"); em.Rate = 0; em.Lifetime = NumberRange.new(0.6, 1.2); em.Speed = NumberRange.new(2, 5)
		em.SpreadAngle = Vector2.new(180, 180); em.Color = ColorSequence.new(GILT, C(255, 246, 220)); em.LightEmission = 0.8
		em.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0)}); em.Texture = "rbxassetid://6490035152"; em.Parent = att
	end
	G:SetAttribute("Slots", SHOW)
	local done = Instance.new("RemoteEvent"); done.Name = "PortraitDone"; done.Parent = G
-- A small upholstered sitter's chair on the lawn, facing the painter.
local chair=G:FindFirstChild("SitterChair")
if not chair then
 local painter
 for _,m in ipairs(workspace:GetDescendants())do if m.Name=="painter_squirrel_color" and m:IsA("Model")then painter=m;break end end
 assert(painter,"Painter missing")
 local pc=painter:GetBoundingBox().Position
 local at=pc+Vector3.new(7,0,1.8)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={G,painter}
 local hit=workspace:Raycast(Vector3.new(at.X,pc.Y+12,at.Z),Vector3.new(0,-50,0),rp)
 assert(hit,"Sitter's chair needs ground")
 local base=CFrame.lookAt(Vector3.new(at.X,hit.Position.Y,at.Z),Vector3.new(pc.X,hit.Position.Y,pc.Z))
 chair=Instance.new("Model");chair.Name="SitterChair"
 local function piece(name,size,offset,col,kind)
  local p=Instance.new(kind or "Part");p.Name=name;p.Size=size;p.CFrame=base*CFrame.new(offset);p.Color=col;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=chair;return p
 end
 local wood=Color3.fromRGB(100,57,29);local cream=Color3.fromRGB(236,205,147);local pine=Color3.fromRGB(31,81,54)
 for _,x in ipairs({-.94,.94})do for _,z in ipairs({-.83,.83})do piece("Leg",Vector3.new(.2,1.55,.2),Vector3.new(x,.775,z),wood)end end
 piece("SeatFrame",Vector3.new(2.25,.22,2.08),Vector3.new(0,1.53,0),wood)
 local seat=piece("PortraitSeat",Vector3.new(2.06,.3,1.9),Vector3.new(0,1.78,0),cream,"Seat");seat.Disabled=true
 for _,x in ipairs({-.94,.94})do piece("BackPost",Vector3.new(.2,2.5,.2),Vector3.new(x,2.75,.83),wood)end
 piece("BackCushion",Vector3.new(1.72,1.45,.24),Vector3.new(0,3.08,.86),pine)
 piece("BrassTrim",Vector3.new(2.18,.16,.3),Vector3.new(0,3.91,.86),Color3.fromRGB(207,164,67))
 for _,x in ipairs({-.45,0,.45})do local stud=piece("Button",Vector3.new(.1,.1,.07),Vector3.new(x,3.1,.70),cream);stud.Shape=Enum.PartType.Ball end
 chair.Parent=G
end

	G.Parent = workspace

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[-- PortraitServer: the sitters' list (newest first, at most Slots), its save, and the easels' pictures
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local G = script.Parent
local slots = G:WaitForChild("Slots")
local done = G:WaitForChild("PortraitDone")
local MAX = G:GetAttribute("Slots") or 12
local store
if not game:GetService("RunService"):IsStudio()then pcall(function() store = DSS:GetDataStore("PortraitWall") end)end
local portraitModels=RS:FindFirstChild("PortraitGalleryModels") or Instance.new("Folder");portraitModels.Name="PortraitGalleryModels";portraitModels.Parent=RS
-- Per-painting crops: keep this requested close-up on the existing sitting only.
local portraitCrops={["9611145467:1790618485"]="waist"}
local list = {}                                              -- {id=, name=, t=, look=}, newest first
local dressKit = RS:FindFirstChild("DressKit")
local dressModule = dressKit and dressKit:FindFirstChild("Catalogue")
local okCat, Cat = false, nil
if dressModule then okCat, Cat = pcall(require, dressModule) end
if not okCat then Cat = nil end
local hatKit=RS:FindFirstChild("HatKit")
local HatCat=hatKit and require(hatKit:WaitForChild("Catalogue"))
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function wornLook(player)
 local look,ids={},{}
 if Cat then for _,id in ipairs(Cat.order)do
  if item(player,"dress_"..id)>0 and item(player,"dresswear_"..id)>0 then ids[#ids+1]=id end
 end end
 if #ids>0 then look.boutique=table.concat(ids,",")end
 if HatCat then for name,value in pairs(player:GetAttributes())do
  local id=name:match("^Item_hatwear_(.+)$")
  if id and (tonumber(value)or 0)>0 and item(player,"hat_"..id)>0 and HatCat.byId[id]then look.hat=id;break end
 end end
 return next(look)and look or nil
end
-- A sitting stores appearance data, never the live character's pose or seat.
local appearanceNumbers={"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg","Face","Shirt","Pants","GraphicTShirt","HeadScale","HeightScale","WidthScale","DepthScale","BodyTypeScale","ProportionScale","MoodAnimation","StaticFacialAnimation"}
local appearanceColors={"HeadColor","TorsoColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor"}
local function saveDescription(desc)
 local data={version=1,properties={},colors={},accessories={}}
 for _,key in ipairs(appearanceNumbers)do
  local ok,value=pcall(function()return desc[key]end)
  if ok and type(value)=="number"then data.properties[key]=value end
 end
 for _,key in ipairs(appearanceColors)do local c=desc[key];data.colors[key]={c.R,c.G,c.B}end
 for _,accessory in ipairs(desc:GetAccessories(true))do
  local copy={}
  for key,value in pairs(accessory)do
   if typeof(value)=="EnumItem"then copy[key]={enum=value.Name}
   elseif typeof(value)=="Vector3"then copy[key]={vector={value.X,value.Y,value.Z}}
   else assert(type(value)=="number"or type(value)=="boolean"or type(value)=="string","Unsupported accessory appearance");copy[key]=value end
  end
  data.accessories[#data.accessories+1]=copy
 end
 return data
end
local function restoreDescription(data)
 assert(type(data)=="table"and data.version==1,"Unsupported portrait appearance")
 local desc=Instance.new("HumanoidDescription")
 for _,key in ipairs(appearanceNumbers)do if data.properties[key]~=nil then desc[key]=data.properties[key]end end
 for _,key in ipairs(appearanceColors)do local c=assert(data.colors[key]);desc[key]=Color3.new(c[1],c[2],c[3])end
 local accessories={}
 for _,entry in ipairs(data.accessories)do
  local copy={}
  for key,value in pairs(entry)do
   if type(value)=="table"and value.enum then copy[key]=assert(Enum.AccessoryType[value.enum])
   elseif type(value)=="table"and value.vector then copy[key]=Vector3.new(table.unpack(value.vector))
   else copy[key]=value end
  end
  accessories[#accessories+1]=copy
 end
 desc:SetAccessories(accessories,true)
 return desc
end
local function validateBody(model,desc,rig)
 local names=rig==Enum.HumanoidRigType.R6 and {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}or
  {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
 for _,name in ipairs(names)do local p=model:FindFirstChild(name);assert(p and p:IsA("BasePart"),"Portrait is missing "..name)end
 local accessories=0
 for _,a in ipairs(model:GetChildren())do if a:IsA("Accessory")then
  assert(a:FindFirstChild("Handle"),"Portrait accessory did not load");accessories+=1
 end end
 assert(accessories>=#desc:GetAccessories(true),"Portrait accessories did not finish loading")
end

local function applyLook(model, look)
	if type(look) ~= "table" or type(look.boutique) ~= "string" then return end
	assert(Cat and dressKit,"Portrait wardrobe is unavailable")
	for id in look.boutique:gmatch("[^,]+") do
		assert(Cat.byId and Cat.byId[id],"Portrait clothing is unavailable: "..id)
		do
			local slot = Cat.slot(id)
			local worn = Cat.attach(dressKit, id, model, Cat.models[slot])
			assert(worn,"Portrait clothing did not fit: "..id)
			do
				if type(Cat.clothing) == "function" then
					for _, entry in ipairs(Cat.clothing(model, id)) do entry[1][entry[2]] = "" end
				end
				if type(Cat.covered) == "function" then
					for _, part in ipairs(Cat.covered(model, id)) do part.Transparency = 1 end
				end
			end
		end
	end
end
local function applyHat(model,look)
 local id=type(look)=="table"and look.hat
 if not id then return end
 assert(HatCat and HatCat.byId[id],"Portrait hat is unavailable")
 local head=assert(model:FindFirstChild("Head"))
 local fit,scale=HatCat.fit(head,HatCat.byId[id].style.id)
 local hair,why=HatCat.clippedHair(head,HatCat.byId[id].style.id,fit)
 assert(hair,why)
 local pieces=assert(HatCat.pieces(hatKit,id,head.CFrame*fit,scale))
 for _,a in ipairs(model:GetChildren())do if a:IsA("Accessory")then
  local h=a:FindFirstChild("Handle")
  if HatCat.isHairAccessory(a)or a.AccessoryType==Enum.AccessoryType.Hat or (h and h:FindFirstChild("HatAttachment",true))then
   for _,p in ipairs(a:GetDescendants())do if p:IsA("BasePart")then p.Transparency=1 end end
  end
 end end
 local hat=Instance.new("Model");hat.Name="WornHat";hat:SetAttribute("HatId",id)
 for _,p in ipairs(pieces)do p.Parent=hat end
 for _,p in ipairs(hair)do p.Parent=hat end
 hat.Parent=model
end
local function assemblePortrait(model)
 local root=model:FindFirstChild("HumanoidRootPart")
 if not root then return end
 root.CFrame=CFrame.new()
 local placed={[root]=true}
 local joints={}
 for _,d in ipairs(model:GetDescendants())do if d:IsA("JointInstance") or d:IsA("AnimationConstraint")then joints[#joints+1]=d end end
 -- Newly generated heads/accessories may still carry their asset positions.
 -- Resolve the rig from its root before freezing it outside the physics world.
 for _=1,#joints do
  local progress=false
  for _,j in ipairs(joints)do
   local a,b,c0,c1,transform
   if j:IsA("AnimationConstraint")then
    local a0,a1=j.Attachment0,j.Attachment1
    if a0 and a1 then a,b,c0,c1=a0.Parent,a1.Parent,a0.CFrame,a1.CFrame end
    transform=CFrame.new()
   else a,b,c0,c1=j.Part0,j.Part1,j.C0,j.C1;transform=CFrame.new() end
   if a and b then
    if placed[a] and not placed[b] then b.CFrame=a.CFrame*c0*transform*c1:Inverse();placed[b]=true;progress=true
    elseif placed[b] and not placed[a] then a.CFrame=b.CFrame*c1*transform:Inverse()*c0:Inverse();placed[a]=true;progress=true end
   end
  end
  if not progress then break end
 end
end
local building,pendingPortraits={},{}
local function portraitKey(e)return "Painting_"..tostring(e.id).."_"..tostring(e.receipt or e.t or 0)end
local function prepareModel(e,description)
 local key=portraitKey(e)
 while building[key]do task.wait(.1)end
 local existing=portraitModels:FindFirstChild(key)
 if existing then return existing end
 building[key]=true
 local result,lastError
 for attempt=1,3 do
  local model
  local ok,err=xpcall(function()
   local desc=description or(e.appearance and restoreDescription(e.appearance))or Players:GetHumanoidDescriptionFromUserIdAsync(tonumber(e.id)or 0)
   local rig=e.rig=="R6"and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
   model=Players:CreateHumanoidModelFromDescriptionAsync(desc,rig)
   validateBody(model,desc,rig)
   model.Name=key;assemblePortrait(model)
   local hum=assert(model:FindFirstChildOfClass("Humanoid"));hum.Sit=false
   hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
   hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
   applyLook(model,e.look);applyHat(model,e.look)
   if Cat and type(e.look)=="table"and type(e.look.boutique)=="string"then
    for id in e.look.boutique:gmatch("[^,]+")do if Cat.byId[id]and Cat.skin then
     for _,entry in ipairs(Cat.skin(model,id))do entry[1].Color=entry[2]end
    end end
   end
   model:SetAttribute("PortraitCrop",portraitCrops[tostring(e.id)..":"..tostring(e.t)])
   model:SetAttribute("PortraitKey",key)
   for _,d in ipairs(model:GetDescendants())do
    if d:IsA("BaseScript")or d:IsA("Animator")or d:IsA("Tool")then d:Destroy()
    elseif d:IsA("BasePart")then d.Anchored=true;d.CanCollide=false;d.CanTouch=false;d.CanQuery=false;d.LocalTransparencyModifier=0 end
   end
   local count=0
   for _,d in ipairs(model:GetDescendants())do if d:IsA("BasePart")then count+=1 end end
   assert(model:FindFirstChild("Head")and model:FindFirstChild("HumanoidRootPart")and count>=7,"Incomplete portrait avatar")
   model:SetAttribute("PortraitPartCount",count)
   local visualCount=0
   for _,d in ipairs(model:GetDescendants())do
    if d:IsA("BasePart")or d:IsA("DataModelMesh")or d:IsA("Decal")or d:IsA("SurfaceAppearance")then visualCount+=1 end
   end
   model:SetAttribute("PortraitVisualCount",visualCount)
   model.Parent=portraitModels
   result=model
  end,debug.traceback)
  if ok then break end
  lastError=err;if model then model:Destroy()end
  if attempt<3 then task.wait(attempt)end
 end
 building[key]=nil
 if not result then error("Could not prepare portrait: "..tostring(lastError))end
 return result
end
local function retireUnusedModels()
 task.delay(60,function()
  local wanted={};for _,e in ipairs(list)do wanted[portraitKey(e)]=true end
  for _,m in ipairs(portraitModels:GetChildren())do
   if not wanted[m.Name]and not building[m.Name]and not pendingPortraits[m.Name]then m:Destroy()end
  end
 end)
end
local function renderPortrait(vp,e)
 if not vp then return end
 local token=(tonumber(vp:GetAttribute("RenderToken"))or 0)+1
 vp:SetAttribute("RenderToken",token)
 if not e then vp:SetAttribute("GalleryModelKey",nil);vp.Visible=false;return end
 task.spawn(function()
  local ok,model=pcall(prepareModel,e)
  if vp:GetAttribute("RenderToken")~=token then return end
  if not ok then warn("PortraitServer: "..tostring(model));return end
  vp:SetAttribute("GalleryModelKey",model.Name);vp.Visible=true
 end)
end

local function show()
	for i = 1, MAX do
		local slot = slots:FindFirstChild("Slot" .. i)
		local canvas = slot and slot:FindFirstChild("Canvas", true)
		local gui = canvas and canvas:FindFirstChild("Picture")
		local plaque = slot and slot:FindFirstChild("Plaque")
		local e = list[i]
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
			local vp = gui:FindFirstChild("Portrait3D")
			-- Each sitting has an immutable model key; moving slots never changes its appearance.
			local back, over = gui:FindFirstChild("Backdrop"), gui:FindFirstChild("Overlay")
			-- the dressing, from the user id: one of five painted scenes always, a companion four times in five (Shannon: "I
			-- like the different backgrounds and companions")
			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
			-- the sitter's place: centred, or to one side when the scene asks (SitX / SitScale attributes on the scene frame);
			-- a corner companion then shows on the far side - its mirrored copy when it was drawn on the sitter's side
			local sf = e and G:FindFirstChild("Scenes") and G.Scenes:FindFirstChild("Scene" .. scene)   -- the template to clone
			local sitX, sitS = (sf and sf:GetAttribute("SitX")) or 0.5, (sf and sf:GetAttribute("SitScale")) or 1
			img.Size = UDim2.fromScale(sitS, sitS); img.Position = UDim2.fromScale(sitX - sitS / 2, 1 - sitS)
			if vp then vp.Size = img.Size; vp.Position = img.Position end
			local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
			local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
			local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
			if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
			if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (e ~= nil) and (c.Name == want) end end
			local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (e ~= nil) and (buddy == 1) end
			if e then
				img.Image = ""; img.Visible = true; wash.Visible = true; renderPortrait(vp, e)
			else
				img.Image = ""; img.Visible = false; wash.Visible = false; renderPortrait(vp, nil)
			end
		end
		if plaque then
			local sg = plaque:FindFirstChildWhichIsA("SurfaceGui")
			local t = sg and sg:FindFirstChild("Name")
			if t then t.Text = e and tostring(e.name) or "" end
		end
	end
end

local function merge(saved, entry)
	local out = {}
	if entry then out[1] = entry end
	for _, e in ipairs(saved or {}) do
		if type(e) == "table" and e.id and (not entry or e.id ~= entry.id) and #out < MAX then out[#out + 1] = e end
	end
	return out
end

local listLoaded = false
local function load()
	if not store then listLoaded = true return end
	local attempt=0
	while true do
		attempt+=1
		local ok,saved=pcall(function()return store:GetAsync("latest")end)
		if ok then
			if type(saved)=="table"then list=merge(saved,nil);show()end
			listLoaded=true;return
		end
		warn("PortraitServer: gallery load failed; retrying: "..tostring(saved))
		task.wait(math.min(attempt*5,60))
	end
end

local function newEntry(player)
 local char=assert(player.Character,"Character is not ready")
 local hum=assert(char:FindFirstChildOfClass("Humanoid"),"Character is not ready")
 local look=wornLook(player)
 -- Do not silently photograph a wardrobe change that has not finished applying.
 if look and look.boutique then for id in look.boutique:gmatch("[^,]+")do
  local worn=char:FindFirstChild(Cat.models[Cat.slot(id)])
  assert(worn and worn:GetAttribute("DressId")==id,"Clothing is still changing")
 end end
 if look and look.hat then local worn=char:FindFirstChild("WornHat");assert(worn and worn:GetAttribute("HatId")==look.hat,"Hat is still changing")end
 return {id=player.UserId,name=player.DisplayName,t=os.time(),receipt=game:GetService("HttpService"):GenerateGUID(false),look=look,rig=hum.RigType.Name,appearance=saveDescription(hum:GetAppliedDescription())}
end
local function hang(player,late,entry)
 entry=entry or newEntry(player)
 local ok,model=pcall(prepareModel,entry)
 if not ok then warn("PortraitServer: "..tostring(model));return false end
 local savedOk,savedList=not store,nil
 if store then
  for attempt=1,3 do
   local err
   savedOk,err=pcall(function()return store:UpdateAsync("latest",function(saved)return merge(saved,entry)end)end)
   if savedOk then savedList=err;break end
   warn("PortraitServer: gallery save attempt "..attempt.." failed: "..tostring(err))
   if attempt<3 then task.wait(attempt)end
  end
 end
 list=type(savedList)=="table"and merge(savedList,nil)or merge(list,entry)
 show();retireUnusedModels()
 if not savedOk then return false end
 local canvas=slots:FindFirstChild("Slot1")and slots.Slot1:FindFirstChild("Canvas",true)
 local em=canvas and canvas:FindFirstChild("Sparkle")and canvas.Sparkle:FindFirstChildOfClass("ParticleEmitter")
 if em then em:Emit(70)end
 local passport=RS:FindFirstChild("PassportActivity");if passport and player.Parent then passport:Fire(player,"portrait",{})end
 if player.Parent then done:FireClient(player,"hung",{late=late==true,modelKey=model.Name})end
 return true
end

local function paintedKey(uid)return "painted_u"..tostring(uid)end
local function pendingKey(uid)return "pending_u"..tostring(uid)end
local function remember(player,target)
 if not store then return true end
 local ok,err=pcall(function()store:UpdateAsync(paintedKey(player.UserId),function(old)return math.max(tonumber(old)or 0,target)end)end)
 if not ok then warn("PortraitServer: painted receipt save failed: "..tostring(err))end
 return ok
end
local seat=G:WaitForChild("SitterChair"):WaitForChild("PortraitSeat")
local active,prepared,unsettled={},{},{}
local function cancelPreparation(player)
 local prep=prepared[player];prepared[player]=nil
 if prep then pendingPortraits[portraitKey(prep.entry)]=nil;retireUnusedModels()end
 if not active[player]and G:GetAttribute("SessionUser")==player.UserId then G:SetAttribute("SessionUser",nil)end
end
local preparePurchase=G:FindFirstChild("PortraitPrepare")or Instance.new("BindableFunction")
preparePurchase.Name="PortraitPrepare";preparePurchase.Parent=G
preparePurchase.OnInvoke=function(player,action)
 if action=="cancel"then cancelPreparation(player);return true end
 if active[player]or unsettled[player]then return false,"your paid portrait is still being saved; no new purchase needed"end
 if G:GetAttribute("SessionUser")~=player.UserId then return false,"the painter is busy"end
 local ok,err=xpcall(function()
  assert(listLoaded,"Gallery is still loading")
  local char=assert(player.Character);local hum=assert(char:FindFirstChildOfClass("Humanoid"))
  assert(hum.Health>0 and player:HasAppearanceLoaded(),"Character appearance is still loading")
  local entry=newEntry(player)
  prepared[player]={entry=entry,target=item(player,"portrait")+1,character=char}
  pendingPortraits[portraitKey(entry)]=true
  prepareModel(entry)
  -- Save the immutable likeness before charging. A reconnect can finish this
  -- exact sitting once the purchase count proves it was paid for.
  if store then
   local receipt={entry=entry,target=prepared[player].target}
   local saved,lastError=false,nil
   for attempt=1,3 do
    saved,lastError=pcall(function()store:UpdateAsync(pendingKey(player.UserId),function()return receipt end)end)
    if saved then break end
    if attempt<3 then task.wait(attempt)end
   end
   assert(saved,"Could not reserve portrait save: "..tostring(lastError))
  end
  assert(player.Parent and player.Character==char and hum.Health>0,"Character changed during preparation")
 end,debug.traceback)
 if not ok then cancelPreparation(player);warn("Portrait preparation: "..tostring(err));return false,"the painter couldn't prepare your portrait. No acorns were taken; please try again."end
 return true
end
G:SetAttribute("SessionUser",nil)
G:SetAttribute("PortraitReady",store~=nil or game:GetService("RunService"):IsStudio())

local function deliver(player,entry,target,late)
 unsettled[player]=true;pendingPortraits[portraitKey(entry)]=true
 local attempt=0
 while true do
  attempt+=1
  local ok,result=pcall(function()
   if not hang(player,late or attempt>1,entry)then return false end
   return remember(player,target)
  end)
  if ok and result then break end
  warn("PortraitServer: paid receipt awaiting retry "..entry.receipt..": "..tostring(result))
  if attempt==1 and player.Parent then done:FireClient(player,"deferred",{})end
  -- The pending receipt remains durable if the server closes between retries.
  task.wait(math.min(10*2^(math.min(attempt-1,5)),120))
 end
 unsettled[player]=nil;pendingPortraits[portraitKey(entry)]=nil;retireUnusedModels()
end
local function sitting(player,target)
 if active[player]then return end
 active[player]=true
 local prep=prepared[player];prepared[player]=nil
 local entry=prep and prep.entry
 local hum,oldJump
 local ok,err=xpcall(function()
  while not listLoaded do task.wait(.2)end
  entry=entry or newEntry(player)
  pendingPortraits[portraitKey(entry)]=true
  local paintedModel=prepareModel(entry)
  if not player.Parent then return end
  local char=player.Character;hum=char and char:FindFirstChildOfClass("Humanoid")
  if not hum or hum.Health<=0 then return end
  G:SetAttribute("SessionUser",player.UserId);player:SetAttribute("PortraitSitting",true)
  oldJump=hum:GetStateEnabled(Enum.HumanoidStateType.Jumping);hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
  seat.Disabled=false;char:PivotTo(seat.CFrame*CFrame.new(0,2.8,0));task.wait(.15);seat:Sit(hum)
  local finish=workspace:GetServerTimeNow()+8
  done:FireClient(player,"painting",{finish=finish,duration=8})
  while workspace:GetServerTimeNow()<finish do
   if not player.Parent or not hum.Parent or hum.Health<=0 then return end
   task.wait(.1)
  end
  done:FireClient(player,"reveal",{id=entry.id,name=entry.name,modelKey=paintedModel.Name})
  task.wait(4)
 end,debug.traceback)
 if hum and hum.Parent then
  if oldJump~=nil then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,oldJump)end
  if hum.SeatPart==seat then hum.Sit=false end
 end
 seat.Disabled=true;player:SetAttribute("PortraitSitting",nil)
 if G:GetAttribute("SessionUser")==player.UserId then G:SetAttribute("SessionUser",nil)end
 active[player]=nil
 if not ok then warn("Portrait sitting: "..tostring(err))end
 -- Finishing the paid image does not depend on the player staying in the chair,
 -- keeping this character alive, or even remaining connected.
 if entry then unsettled[player]=true;task.spawn(deliver,player,entry,prep and prep.target or target,false)end
 if player.Parent then done:FireClient(player,"sessionEnd",{})end
end
local itemEv=RS:WaitForChild("AwardItems",30)
if itemEv and itemEv:IsA("BindableEvent")then
 itemEv.Event:Connect(function(player,id,n)
  if id~="portrait"or(tonumber(n)or 0)<=0 or typeof(player)~="Instance"or not player:IsA("Player")then return end
  task.defer(sitting,player,item(player,"portrait"))
 end)
else warn("PortraitServer: no AwardItems event - portraits cannot be bought")end
local function owed(player)
 if not store then return end
 while player.Parent and not(player:GetAttribute("SaveLoaded")and listLoaded)do task.wait(.5)end
 if not player.Parent then return end
 local bought=item(player,"portrait")
 if bought<=0 or active[player]or prepared[player]or unsettled[player]then return end
 local ok,painted,receipt=pcall(function()return store:GetAsync(paintedKey(player.UserId)),store:GetAsync(pendingKey(player.UserId))end)
 if not ok then task.delay(15,owed,player);return end
 if active[player]or prepared[player]or unsettled[player]then return end
 painted=tonumber(painted)
 local onWall=false
 for _,e in ipairs(list)do if tonumber(e.id)==player.UserId then onWall=true end end
 if painted==nil and onWall and not receipt then remember(player,bought);return end
 if bought<=(painted or 0)then return end
 local entry=type(receipt)=="table"and receipt.target<=bought and receipt.target>(painted or 0)and receipt.entry or nil
 local target=entry and receipt.target or bought
 if not entry then
  -- Only legacy purchases lack a saved likeness. New purchases always carry one.
  local good,result=pcall(newEntry,player)
  if not good then task.delay(15,owed,player);return end
  entry=result
 end
 unsettled[player]=true
 task.wait(5)
 deliver(player,entry,target,true)
end
Players.PlayerRemoving:Connect(function(player)
 -- A paid sitting owns its snapshot until delivery; only unpaid preparation is canceled.
 if not active[player]then cancelPreparation(player)end
end)
Players.PlayerAdded:Connect(function(p)task.spawn(owed,p)end)
for _,p in ipairs(Players:GetPlayers())do task.spawn(owed,p)end
show();task.spawn(load)
print("PortraitServer: ready - saved appearance, prepayment validation, automatic delivery retry")
]==]
	local ss = Instance.new("Script"); ss.Name = "PortraitServer"; ss.RunContext = Enum.RunContext.Server; ss.Source = SERVER; ss.Parent = G

	-- ---------------------------------------------------------------- the client ----
	local CLIENT = [==[
-- PortraitClient: the word to the sitter when their portrait is set up
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local G = script.Parent
local done = G:WaitForChild("PortraitDone")
-- Nearby chair interaction uses the shared desktop/touch prompt design.
-- Open the existing store row; only its purchase button spends acorns.
task.spawn(function()
 local pg=player:WaitForChild("PlayerGui")
 local prompt
 local function offerAvailable(shop,seat)
  local char=player.Character
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  local daily=pg:FindFirstChild("DailyGui")
  local card=daily and daily:FindFirstChild("DailyCard")
  return shop and shop:GetAttribute("Open")~=false
   and (shop:GetAttribute("Selling")==true or shop:GetAttribute("Sell_portrait")==true)
   and type(shop:GetAttribute("Price_portrait"))=="number"
   and G:GetAttribute("PortraitReady")==true and not G:GetAttribute("SessionUser")
   and not seat.Occupant and hum and hum.Health>0
   and not player:GetAttribute("PortraitSitting") and not pg:GetAttribute("OpenPanel")
   and not (daily and daily.Enabled and card and card.Visible)
 end
 while G:IsDescendantOf(workspace) do
  local chair=G:FindFirstChild("SitterChair")
  local seat=chair and chair:FindFirstChild("PortraitSeat")
  local shop=workspace:FindFirstChild("Shop")
  local openAt=shop and shop:FindFirstChild("OpenAt")
  if prompt and prompt.Parent~=seat then prompt:Destroy();prompt=nil end
  if seat and openAt and not prompt then
   local p=Instance.new("ProximityPrompt");p.Name="PortraitChairPrompt"
   p.Style=Enum.ProximityPromptStyle.Custom;p.ActionText="Sit for a portrait"
   p.KeyboardKeyCode=Enum.KeyCode.E;p.GamepadKeyCode=Enum.KeyCode.ButtonX
   p.MaxActivationDistance=8;p.RequiresLineOfSight=true;p.HoldDuration=0
   p.ClickablePrompt=true;p.Enabled=false
   p.Triggered:Connect(function()
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position-seat.Position).Magnitude>p.MaxActivationDistance+1 then return end
    if offerAvailable(shop,seat) and openAt.Parent==shop then
     p.Enabled=false;openAt:Fire("portrait")
    end
   end)
   p.Parent=seat;prompt=p
  end
  if prompt then
   local text=tostring(shop and shop:GetAttribute("Price_portrait") or "").." acorns"
   if prompt.ObjectText~=text then prompt.Enabled=false;prompt.ObjectText=text
   else prompt.Enabled=openAt~=nil and offerAvailable(shop,seat) and true or false end
  end
  task.wait(.2)
 end
 if prompt then prompt:Destroy()end
end)


local C = Color3.fromRGB

local gui = Instance.new("ScreenGui"); gui.Name = "PortraitNote"; gui.ResetOnSpawn = false; gui.DisplayOrder = 7; gui.Parent = player:WaitForChild("PlayerGui")
-- the note hugs its words and wraps inside its box, in crisp BuilderSans, with the gold line round the box (not round
-- the letters)
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 0); note.Position = UDim2.new(0.5, 0, 0, 70)
note.Size = UDim2.fromOffset(0, 0); note.AutomaticSize = Enum.AutomaticSize.XY; note.TextWrapped = true
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0
note.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold); note.TextSize = 20
note.TextColor3 = C(255, 214, 90); note.TextTransparency = 1; note.Text = ""; note.Parent = gui
local nmax = Instance.new("UISizeConstraint"); nmax.MaxSize = Vector2.new(460, math.huge); nmax.Parent = note
local np = Instance.new("UIPadding"); np.PaddingLeft = UDim.new(0, 16); np.PaddingRight = UDim.new(0, 16)
np.PaddingTop = UDim.new(0, 9); np.PaddingBottom = UDim.new(0, 9); np.Parent = note
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 14); nc.Parent = note
local ns = Instance.new("UIStroke"); ns.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ns.Color = C(240, 200, 90); ns.Thickness = 1.5; ns.Transparency = 1; ns.Parent = note
local shownAt = 0
done.OnClientEvent:Connect(function(what, late)
	if what ~= "hung" and what ~= "deferred" then return end
	local v=player.PlayerGui:FindFirstChild("PortraitViewer");if what=="hung"and v and v.Page.Visible then return end
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	nmax.MaxSize = Vector2.new(math.clamp(vw - 40, 240, 460), math.huge)
	note.Text = ((type(late)=="table"and late.late or late==true)and "Sorry for the wait! "or "") .. "The painter has finished your portrait - it stands on an easel in his gallery by the river."
	if what=="deferred"then note.Text="Your paid portrait is still being prepared. You do not need to buy it again; the painter is retrying automatically, even if you leave."end
	note.BackgroundTransparency = 0.15; note.TextTransparency = 0; ns.Transparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(5, function()
		if shownAt ~= mine then return end
		local ti = TweenInfo.new(0.6)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(ns, ti, {Transparency = 1}):Play()
	end)
end)

-- Inspect the whole painting, including its scene and companions, from its easel.
local pg=player:WaitForChild("PlayerGui")
local UIS=game:GetService("UserInputService")
local viewer=Instance.new("ScreenGui");viewer.Name="PortraitViewer";viewer.IgnoreGuiInset=true;viewer.ResetOnSpawn=false;viewer.DisplayOrder=10;viewer.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;viewer.Parent=pg
local page=Instance.new("Frame");page.Name="Page";page.AnchorPoint=Vector2.new(.5,0);page.BackgroundColor3=C(255,246,220);page.BorderSizePixel=0;page.Active=true;page.Visible=false;page.Parent=viewer
local function rounded(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
rounded(page,16)
local outline=Instance.new("UIStroke");outline.Color=C(233,184,65);outline.Thickness=3;outline.Parent=page
local foil=Instance.new("UIGradient");foil.Color=ColorSequence.new(C(193,132,34),C(255,231,147));foil.Rotation=35;foil.Parent=outline
local painting=Instance.new("Frame");painting.Name="Painting";painting.BackgroundColor3=C(246,240,226);painting.BorderSizePixel=0;painting.ClipsDescendants=true;painting.Parent=page
local inner=Instance.new("UIStroke");inner.Color=C(184,135,44);inner.Thickness=2;inner.Parent=painting
local function text(name,value,size,col)
 local t=Instance.new("TextLabel");t.Name=name;t.Text=value;t.Font=Enum.Font.FredokaOne;t.TextSize=size;t.TextColor3=col;t.BackgroundTransparency=1;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Top;t.TextWrapped=true;t.Parent=page;return t
end
local heading=text("Heading","Garden portrait",18,C(64,42,22))
local sitter=text("Sitter","",16,C(64,42,22))
local caption=text("Caption","From the painter's gallery",12,C(113,79,45));caption.Font=Enum.Font.BuilderSans
local close=Instance.new("TextButton");close.Name="Close";close.Text="×";close.Font=Enum.Font.FredokaOne;close.TextSize=25;close.TextColor3=C(64,42,22);close.BackgroundColor3=C(237,223,195);close.BorderSizePixel=0;close.Size=UDim2.fromOffset(44,44);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-8,0,8);close.Parent=page;rounded(close,11)
local current,canvas,source,revealSource
local paintings={};local connections={}
local function disconnect()
 for _,c in ipairs(connections)do c:Disconnect()end;table.clear(connections)
end
local function clearPainting()for _,o in ipairs(paintings)do o:Destroy()end;table.clear(paintings)end
local function closePortrait()
 page.Visible=false;current=nil;canvas=nil;source=nil;disconnect();clearPainting()
 if revealSource then revealSource:Destroy();revealSource=nil end
 if pg:GetAttribute("OpenPanel")=="portrait" then pg:SetAttribute("OpenPanel",nil)end
end
local portraitFrameWatches=setmetatable({},{__mode="k"})
local function frameViewport(vp,model)
 if not vp or not model or not model:FindFirstChild("Head")then return false end
 local cam=vp:FindFirstChild("PortraitCamera")
 if not cam then cam=Instance.new("Camera");cam.Name="PortraitCamera";cam.FieldOfView=28;cam.Parent=vp end
 local points={};local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
 for _,part in ipairs(model:GetDescendants())do if part:IsA("BasePart")and part.Transparency<.99 then
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
   points[#points+1]=p;low=low:Min(p);high=high:Max(p)
  end end end
 end end
 if #points==0 then return false end
 local focus=(low+high)/2
 local direction=Vector3.new(.18,.06,-1).Unit
 local orientation=CFrame.lookAt(focus+direction,focus).Rotation
 local aspect=vp.AbsoluteSize.Y>0 and vp.AbsoluteSize.X/vp.AbsoluteSize.Y or .78
 local tanY=math.tan(math.rad(cam.FieldOfView/2));local tanX=tanY*math.max(.1,aspect)
 local dist=0
 for _,p in ipairs(points)do
  local localPoint=orientation:VectorToObjectSpace(p-focus)
  dist=math.max(dist,math.abs(localPoint.X)/tanX+localPoint.Z,math.abs(localPoint.Y)/tanY+localPoint.Z)
 end
 dist*=1.10
 local torso=model:FindFirstChild("UpperTorso")or model:FindFirstChild("Torso")
 if model:GetAttribute("PortraitCrop")=="waist"and torso then
  local waist=torso.Position.Y-torso.Size.Y/2
  local height=math.max(model.Head.Size.Y*1.6,high.Y-waist)
  focus=Vector3.new(torso.Position.X,waist+height/2,focus.Z)
  dist=height/(2*tanY)*1.10
 end
 cam.CFrame=CFrame.lookAt(focus+direction*dist,focus)
 vp.CurrentCamera=cam;vp.Visible=true
 if not portraitFrameWatches[vp]then
  portraitFrameWatches[vp]=true
  vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
   local world=vp:FindFirstChild("World")or vp:FindFirstChildOfClass("WorldModel")
   local currentModel=world and world:FindFirstChildOfClass("Model")
   if currentModel then frameViewport(vp,currentModel)end
  end)
 end
 return true
end


local function fitPortrait()
 if not canvas then return end
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local available=math.max(80,math.min(600,vp.Y-148))
 local ratio=canvas.Size.X/math.max(.01,canvas.Size.Y)
 local side=vp.X<600 and 154 or 190
 local imageH=math.min(available-24,(vp.X-side-52)/ratio)
 local imageW=math.floor(imageH*ratio);imageH=math.floor(imageH)
 local w=imageW+side+36;local h=imageH+24
 page.Size=UDim2.fromOffset(w,h);page.Position=UDim2.new(.5,0,0,68+math.floor((available-h)/2))
 painting.Position=UDim2.fromOffset(12,12);painting.Size=UDim2.fromOffset(imageW,imageH)
 local left=imageW+28
 heading.Position=UDim2.fromOffset(left,58);heading.Size=UDim2.fromOffset(side-8,46)
 sitter.Position=UDim2.fromOffset(left,110);sitter.Size=UDim2.fromOffset(side-8,math.max(24,h-150));sitter.TextSize=vp.Y<500 and 15 or 20;sitter.TextTruncate=Enum.TextTruncate.AtEnd
 caption.Position=UDim2.fromOffset(left,h-30);caption.Size=UDim2.fromOffset(side-8,22)
end
local function copyPainting()
 if not current or not source or (source~=revealSource and not source:IsDescendantOf(G))then closePortrait();return end
 local portrait=source:FindFirstChild("Portrait")
 local pv=source:FindFirstChild("Portrait3D");local pw=pv and pv:FindFirstChild("World");local hasViewport=pv and pv.Visible and pw and #pw:GetChildren()>0
 if not portrait or not portrait.Visible or (portrait.Image=="" and not hasViewport) then closePortrait();return end
 clearPainting()
 for _,child in ipairs(source:GetChildren())do
  if child:IsA("GuiObject")then
   local copy=child:Clone();copy.Parent=painting
   if copy:IsA("ViewportFrame")then
    local world=copy:FindFirstChild("World");local model=world and world:FindFirstChildOfClass("Model")
    if model then frameViewport(copy,model)end
   end
   paintings[#paintings+1]=copy
  end
 end
 local plaque=current:FindFirstChild("Plaque")
 local sg=plaque and plaque:FindFirstChildOfClass("SurfaceGui")
 local name=sg and sg:FindFirstChild("Name")
 sitter.Text=name and name.Text or ""
end
local function showPortrait(slot)
 local active=pg:GetAttribute("OpenPanel")
 if active and active~="portrait" then return end
 local c=slot:FindFirstChild("Canvas",true);local s=c and c:FindFirstChild("Picture");local img=s and s:FindFirstChild("Portrait")
 local pv=s and s:FindFirstChild("Portrait3D");local pw=pv and pv:FindFirstChild("World");local hasViewport=pv and pv.Visible and pw and #pw:GetChildren()>0
 if not img or not img.Visible or (img.Image=="" and not hasViewport) then return end
 closePortrait();current=slot;canvas=c;source=s
 heading.Text="Garden portrait";caption.Text="From the painter's gallery"
 pg:SetAttribute("OpenPanel","portrait");copyPainting();fitPortrait();page.Visible=true
 connections[#connections+1]=slot.AncestryChanged:Connect(function()if not slot:IsDescendantOf(G)then closePortrait()end end)
 connections[#connections+1]=img:GetPropertyChangedSignal("Image"):Connect(function()task.defer(copyPainting)end)
 connections[#connections+1]=img:GetPropertyChangedSignal("Visible"):Connect(function()task.defer(copyPainting)end)
end
close.Activated:Connect(closePortrait)
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then closePortrait()end end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if pg:GetAttribute("OpenPanel")~="portrait" and page.Visible then closePortrait()end end)
player.CharacterAdded:Connect(closePortrait)
local cameraConnection
local function cameraChanged()if cameraConnection then cameraConnection:Disconnect()end;fitPortrait();if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPortrait)end end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
-- ViewportFrames render on a world surface only when the SurfaceGui lives in
-- PlayerGui. Keep the server-owned Picture as the replicated template, and
-- mount a local copy onto its canvas with Adornee. Saved portraits use this
-- same path, so fixing the display does not require another purchase.
local galleryPictures=Instance.new("Folder");galleryPictures.Name="PortraitGalleryPictures";galleryPictures.Parent=pg
local portraitModels=game:GetService("ReplicatedStorage"):WaitForChild("PortraitGalleryModels")
local function portraitComplete(model)
 if not model or not model:FindFirstChild("Head")or not model:FindFirstChild("HumanoidRootPart")then return false end
 local expected=model:GetAttribute("PortraitPartCount")
 if type(expected)~="number"then return false end
 local count,visualCount=0,0
 for _,d in ipairs(model:GetDescendants())do
  if d:IsA("BasePart")then count+=1 end
  if d:IsA("BasePart")or d:IsA("DataModelMesh")or d:IsA("Decal")or d:IsA("SurfaceAppearance")then visualCount+=1 end
 end
 return count>=expected and visualCount>=(model:GetAttribute("PortraitVisualCount")or math.huge)
end
local boundCanvases={}
local slots=G:WaitForChild("Slots")
local function hookCanvas(c)
 if c.Name~="Canvas" or not c:IsA("BasePart") or boundCanvases[c] then return end
 local slot=c.Parent
 while slot and slot.Parent~=slots do slot=slot.Parent end
 if not slot or not slot:IsA("Model") then return end
 boundCanvases[c]=true
 task.spawn(function()
  local picture=c:WaitForChild("Picture",10)
  if not picture or not c:IsDescendantOf(slots) then boundCanvases[c]=nil;return end
  local listeners,watched={},{}
  local mounted,queued,stopped=nil,false,false
  local installedModel
  local function connect(signal,fn) local con=signal:Connect(fn);listeners[#listeners+1]=con;return con end
  local function cleanup()
   stopped=true
   for _,con in ipairs(listeners) do con:Disconnect() end
   for _,con in pairs(watched) do con:Disconnect() end
   if mounted then mounted:Destroy();mounted=nil end
   boundCanvases[c]=nil
  end
  local refresh,schedule
  refresh=function()
   queued=false
   if stopped or not c:IsDescendantOf(slots) then return end
   local vp=picture:FindFirstChild("Portrait3D")
   local world=vp and vp:FindFirstChild("World")
   local key=vp and vp:GetAttribute("GalleryModelKey")
   local stored=key and portraitModels:FindFirstChild(key)
   if vp and vp.Visible then
    if not portraitComplete(stored)then schedule();return end
    if stored~=installedModel then
     world:ClearAllChildren();local sitter=stored:Clone();sitter.Name="PaintedSitter";sitter.Parent=world;installedModel=stored
    end
   elseif world then world:ClearAllChildren();installedModel=nil end
   local model=world and world:FindFirstChild("PaintedSitter")
   -- A model can arrive over several replication frames. Keep the previous
   -- picture until the new sitter has a usable camera target.
   if vp and vp.Visible and (not model or not frameViewport(vp,model)) then return end
   local copy=picture:Clone();copy.Name=slot.Name;copy.Adornee=c;copy.Enabled=true;copy.ResetOnSpawn=false
   local cv=copy:FindFirstChild("Portrait3D")
   local cm=cv and cv:FindFirstChild("World") and cv.World:FindFirstChild("PaintedSitter")
   if cm then frameViewport(cv,cm) end
   copy.Parent=galleryPictures
   picture.Enabled=false -- local only; the server continues updating its template
   if mounted then mounted:Destroy() end
   mounted=copy
   if current==slot and source==picture and page.Visible then copyPainting() end
  end
  schedule=function()
   if queued or stopped then return end
   queued=true;task.delay(.1,refresh)
  end
  local function watch(obj)
   if watched[obj] or not obj:IsA("GuiObject") then return end
   watched[obj]=obj.Changed:Connect(function(property)
    if property=="Visible" or property=="Image" or property=="Size" or property=="Position" then schedule() end
   end)
  end
  connect(portraitModels.ChildAdded,schedule)
  connect(portraitModels.DescendantAdded,function(obj)
   local key=picture.Portrait3D:GetAttribute("GalleryModelKey")
   if key and obj:FindFirstAncestor(key)then installedModel=nil;schedule()end
  end)
  connect(portraitModels.ChildRemoved,schedule)
  connect(picture.Portrait3D:GetAttributeChangedSignal("RenderToken"),schedule)
  connect(picture.Portrait3D:GetAttributeChangedSignal("GalleryModelKey"),schedule)
  for _,obj in ipairs(picture:GetDescendants()) do watch(obj) end
  connect(picture.DescendantAdded,function(obj)watch(obj);schedule()end)
  connect(picture.DescendantRemoving,function(obj)
   if watched[obj] then watched[obj]:Disconnect();watched[obj]=nil end
   schedule()
  end)
  connect(c.AncestryChanged,function()if not c:IsDescendantOf(slots) then cleanup() end end)
  local click=c:FindFirstChild("ViewPortrait")
  if not click then click=Instance.new("ClickDetector");click.Name="ViewPortrait";click.MaxActivationDistance=48;click.Parent=c end
  connect(click.MouseClick,function(who)if who==player then showPortrait(slot)end end)
  schedule()
 end)
end
for _,c in ipairs(slots:GetDescendants())do hookCanvas(c)end
slots.DescendantAdded:Connect(hookCanvas)
print("Portrait viewer: river canvases mounted in PlayerGui; tap or click to inspect")

local function renderPreparedLook(vp,key)
 if not vp or type(key)~="string"then return false end
 local world=vp:FindFirstChild("World");if not world then return false end
 local model,deadline=nil,os.clock()+20
 repeat
  model=portraitModels:FindFirstChild(key)
  if portraitComplete(model)then break end
  task.wait(.1)
 until os.clock()>deadline
 if not portraitComplete(model)then return false end
 world:ClearAllChildren()
 local copy=model:Clone();copy.Name="PaintedSitter";copy.Parent=world
 return frameViewport(vp,copy)
end

local function configurePicture(gui,e)
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
			local vp = gui:FindFirstChild("Portrait3D")
			local back, over = gui:FindFirstChild("Backdrop"), gui:FindFirstChild("Overlay")
			-- the dressing, from the user id: one of five painted scenes always, a companion four times in five (Shannon: "I
			-- like the different backgrounds and companions")
			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
			-- the sitter's place: centred, or to one side when the scene asks (SitX / SitScale attributes on the scene frame);
			-- a corner companion then shows on the far side - its mirrored copy when it was drawn on the sitter's side
			local sf = e and G:FindFirstChild("Scenes") and G.Scenes:FindFirstChild("Scene" .. scene)   -- the template to clone
			local sitX, sitS = (sf and sf:GetAttribute("SitX")) or 0.5, (sf and sf:GetAttribute("SitScale")) or 1
			img.Size = UDim2.fromScale(sitS, sitS); img.Position = UDim2.fromScale(sitX - sitS / 2, 1 - sitS)
			if vp then vp.Size = img.Size; vp.Position = img.Position end
			local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
			local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
			local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
			if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
			if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (e ~= nil) and (c.Name == want) end end
			local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (e ~= nil) and (buddy == 1) end
			if e then
				img.Image = ""; img.Visible = true; wash.Visible = true
				if not renderPreparedLook(vp,e.modelKey)then return false end
			else
				img.Image = ""; img.Visible = false; wash.Visible = false; if vp then vp.Visible = false end
			end
		end
return true
end
-- A compact progress card lets the sitter see the painter and their seated avatar.
local progress=Instance.new("Frame");progress.Name="PaintingProgress";progress.AnchorPoint=Vector2.new(.5,1);progress.Size=UDim2.fromOffset(300,64);progress.Position=UDim2.new(.5,0,1,-100);progress.BackgroundColor3=C(255,246,220);progress.BorderSizePixel=0;progress.Visible=false;progress.Parent=viewer;rounded(progress,13)
local pr=Instance.new("UIStroke");pr.Color=C(236,181,55);pr.Thickness=2;pr.Parent=progress
local progressText=Instance.new("TextLabel");progressText.Name="Caption";progressText.Size=UDim2.new(1,-20,0,29);progressText.Position=UDim2.fromOffset(10,5);progressText.BackgroundTransparency=1;progressText.Font=Enum.Font.FredokaOne;progressText.TextSize=16;progressText.TextColor3=C(64,42,22);progressText.Parent=progress
local track=Instance.new("Frame");track.Size=UDim2.new(1,-24,0,12);track.Position=UDim2.fromOffset(12,40);track.BackgroundColor3=C(219,199,155);track.BorderSizePixel=0;track.Parent=progress;rounded(track,6)
local fill=Instance.new("Frame");fill.Name="Fill";fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=C(255,199,62);fill.BorderSizePixel=0;fill.Parent=track;rounded(fill,6)
local fg=Instance.new("UIGradient");fg.Color=ColorSequence.new(C(215,151,31),C(255,227,128));fg.Parent=fill
local paintingUntil,duration=0,8
local publishedPortraits={}
game:GetService("RunService").Heartbeat:Connect(function()
 if progress.Visible then local left=math.max(0,paintingUntil-workspace:GetServerTimeNow());fill.Size=UDim2.fromScale(math.clamp(1-left/duration,0,1),1);progressText.Text=left>0 and ("Painting your portrait · "..math.ceil(left).."s")or"Adding the finishing touches…" end
end)
done.OnClientEvent:Connect(function(what,info)
 if what=="painting"then
  closePortrait();pg:SetAttribute("OpenPanel","portrait");paintingUntil=info.finish;duration=info.duration;progress.Visible=true
 elseif what=="reveal"then
  progress.Visible=false;closePortrait()
  local slot=slots:FindFirstChild("Slot1");local c=slot and slot:FindFirstChild("Canvas",true)
  if not c or not c:FindFirstChild("Picture")then return end
  current=G;canvas=c;source=c.Picture:Clone();revealSource=source
  if not configurePicture(source,info)then closePortrait();return end
  pg:SetAttribute("OpenPanel","portrait");copyPainting();fitPortrait();page.Visible=true
  heading.Text="Your portrait!";sitter.Text=info.name;caption.Text=publishedPortraits[info.modelKey]and "Saved to the river gallery"or "Next stop: the river gallery"
  local ding=Instance.new("Sound");ding.Name="PortraitRevealChime";ding.SoundId=G:GetAttribute("RevealSound")or"rbxassetid://9116394876";ding.Volume=G:GetAttribute("RevealVolume")or.32;ding.PlaybackSpeed=G:GetAttribute("RevealSpeed")or.88;ding.Parent=viewer;ding:Play();game:GetService("Debris"):AddItem(ding,6)
 elseif what=="hung"then
  if type(info)=="table"then publishedPortraits[info.modelKey]=true end
  if revealSource then caption.Text="Saved to the river gallery"end
 elseif what=="deferred"then
  progress.Visible=false
  if revealSource then caption.Text="Save pending — no new purchase needed"end
 elseif what=="sessionEnd"then
  progress.Visible=false
  if not page.Visible and pg:GetAttribute("OpenPanel")=="portrait"then pg:SetAttribute("OpenPanel",nil)end
 end
end)
player.CharacterAdded:Connect(function()progress.Visible=false end)

-- Humanoid state enablement is local too; restore the player's own jump state after the sitting.
local sittingHum,wasJumping
local function syncSitting()
 if player:GetAttribute("PortraitSitting")then
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if hum and hum~=sittingHum then sittingHum=hum;wasJumping=hum:GetStateEnabled(Enum.HumanoidStateType.Jumping);hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)end
 elseif sittingHum then
  if sittingHum.Parent then sittingHum:SetStateEnabled(Enum.HumanoidStateType.Jumping,wasJumping)end
  sittingHum=nil;wasJumping=nil
 end
end
player:GetAttributeChangedSignal("PortraitSitting"):Connect(syncSitting);syncSitting()
]==]
	local cs = Instance.new("Script"); cs.Name = "PortraitClient"; cs.RunContext = Enum.RunContext.Client; cs.Source = CLIENT; cs.Parent = G

	print(string.format("PortraitGallery: %d easels - %d along the river bank from the painter, %d across the back (x %.0f-%.0f at z %.1f) | sitters saved in DataStore PortraitWall", N, RIVER, BACK, BACK_X0, BACK_X1, BACK_Z))
	return G
end

-- The painter's gallery: the Acorn Store's "Sit for a portrait" (id "portrait", 120 acorns, as often as you like).
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
	G.Parent = workspace

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[
-- PortraitServer: the sitters' list (newest first, at most Slots), its save, and the easels' pictures
local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local G = script.Parent
local slots = G:WaitForChild("Slots")
local done = G:WaitForChild("PortraitDone")
local MAX = G:GetAttribute("Slots") or 12
local store
pcall(function() store = DSS:GetDataStore("PortraitWall") end)
local list = {}                                              -- {id=, name=, t=}, newest first

local function show()
	for i = 1, MAX do
		local slot = slots:FindFirstChild("Slot" .. i)
		local canvas = slot and slot:FindFirstChild("Canvas", true)
		local gui = canvas and canvas:FindFirstChild("Picture")
		local plaque = slot and slot:FindFirstChild("Plaque")
		local e = list[i]
		if gui then
			local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
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
			local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
			local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
			local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
			if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
			if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (e ~= nil) and (c.Name == want) end end
			local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (e ~= nil) and (buddy == 1) end
			if e then
				img.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(e.id) .. "&w=420&h=420"
				img.Visible = true; wash.Visible = true
			else
				img.Image = ""; img.Visible = false; wash.Visible = false
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
	local ok, saved = pcall(function() return store:GetAsync("latest") end)
	if ok and type(saved) == "table" then list = merge(saved, nil); show() end
	listLoaded = true
end

local function hang(player, late)
	local entry = {id = player.UserId, name = player.DisplayName, t = os.time()}
	list = merge(list, entry)
	show()
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync("latest", function(saved) return merge(saved, entry) end)
		end)
		if not ok then warn("PortraitServer: could not save the gallery - " .. tostring(err)) end
	end
	-- the flourish: sparkle at the newest easel, and a word to the sitter
	local canvas = slots:FindFirstChild("Slot1") and slots.Slot1:FindFirstChild("Canvas", true)
	local em = canvas and canvas:FindFirstChild("Sparkle") and canvas.Sparkle:FindFirstChildOfClass("ParticleEmitter")
	if em then em:Emit(70) end
	done:FireClient(player, "hung", late == true)
end

-- A PURCHASE IS THE SHOP'S AWARD: the shop pays for a portrait with AwardItems(player, "portrait", 1), and that event
-- is the signal. (It used to be a RISING Item_portrait, which missed every FIRST purchase: a player who had never
-- bought one has no count in their save, so the count went from nothing to 1 - which looked like the save loading.
-- Shannon's alt paid 120 acorns and got no painting.)
local function paintedKey(uid) return "painted_u" .. tostring(uid) end
local function remember(player)                          -- how many of their portraits have been painted, kept per player
	if not store then return end
	local n = tonumber(player:GetAttribute("Item_portrait")) or 0
	local ok, err = pcall(function() store:SetAsync(paintedKey(player.UserId), n) end)
	if not ok then warn("PortraitServer: could not note " .. player.Name .. "'s painted count - " .. tostring(err)) end
end
local itemEv = game:GetService("ReplicatedStorage"):WaitForChild("AwardItems", 30)
if itemEv and itemEv:IsA("BindableEvent") then
	itemEv.Event:Connect(function(player, id, n)
		if id ~= "portrait" or (tonumber(n) or 0) <= 0 then return end
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		task.defer(function()
			hang(player)
			remember(player)
			print("PortraitServer: painted " .. player.Name .. " (bought " .. tostring(player:GetAttribute("Item_portrait")) .. ")")
		end)
	end)
else
	warn("PortraitServer: no AwardItems event - portraits cannot be bought")
end
-- MAKING GOOD: anyone who has paid for a portrait but was never painted - those missed first purchases above all - gets
-- it painted when they next come in, with an apology in the note. The count painted is kept per player, so a sitter
-- moved off the easels by newer ones is not hung again on every visit.
local function owed(player)
	if not store then return end
	local t0 = os.clock()
	while player.Parent and not (player:GetAttribute("SaveLoaded") and listLoaded) and os.clock() - t0 < 40 do task.wait(0.5) end
	if not player.Parent or not listLoaded then return end
	local bought = tonumber(player:GetAttribute("Item_portrait")) or 0
	if bought <= 0 then return end
	local ok, painted = pcall(function() return store:GetAsync(paintedKey(player.UserId)) end)
	if not ok then return end
	painted = tonumber(painted)
	local onWall = false
	for _, e in ipairs(list) do if tonumber(e.id) == player.UserId then onWall = true end end
	if (painted == nil and not onWall) or (painted ~= nil and bought > painted) then
		task.wait(5)                                        -- their screen is up by now, so they see the note
		if not player.Parent then return end
		hang(player, true)
		print("PortraitServer: made good " .. player.Name .. "'s unpainted portrait (bought " .. bought .. ", painted " .. tostring(painted) .. ")")
	end
	if painted == nil or bought > painted then remember(player) end
end
Players.PlayerAdded:Connect(function(p) task.spawn(owed, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(owed, p) end
show()
task.spawn(load)
print("PortraitServer: ready - " .. (store and "gallery saved in DataStore PortraitWall" or "no DataStore, gallery kept in memory"))
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
	if what ~= "hung" then return end
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	nmax.MaxSize = Vector2.new(math.clamp(vw - 40, 240, 460), math.huge)
	note.Text = (late and "Sorry for the wait! " or "") .. "The painter has finished your portrait - it stands on an easel in his gallery by the river."
	note.BackgroundTransparency = 0.15; note.TextTransparency = 0; ns.Transparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(5, function()
		if shownAt ~= mine then return end
		local ti = TweenInfo.new(0.6)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(ns, ti, {Transparency = 1}):Play()
	end)
end)
]==]
	local cs = Instance.new("Script"); cs.Name = "PortraitClient"; cs.RunContext = Enum.RunContext.Client; cs.Source = CLIENT; cs.Parent = G

	print(string.format("PortraitGallery: %d easels - %d along the river bank from the painter, %d across the back (x %.0f-%.0f at z %.1f) | sitters saved in DataStore PortraitWall", N, RIVER, BACK, BACK_X0, BACK_X1, BACK_Z))
	return G
end

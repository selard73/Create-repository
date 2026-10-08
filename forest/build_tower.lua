-- ForestTower: the lookout at the forest spawn, and the launch end of the zipline.
--
-- It is 70 studs tall and that height is not a preference, it is arithmetic: the boundary walls top out at
-- exactly 56, and a wire strung from here to the far end of the farm has to pass over them rather than through.
-- So it is a real climb - five decks, switchback stairs, and a view at the top that earns the walk.
--
-- Built against the ground, not floated: every post is dropped onto whatever is actually under it, and the
-- footprint is cleared of the forest scatter first (those props carry a Scatter attribute, so removing them is
-- clean and they can be regrown around the tower afterwards).
-- Re-runnable: it deletes the previous tower before building.
-- Run in edit mode: require(workspace.ForestTower.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	-- The HEIGHT is arithmetic and cannot move: the wire has to clear walls at 56. The BULK is a choice, and
	-- the first one was far too heavy - a fifteen-stud fort on foot-thick legs dwarfed the whole forest. Same
	-- climb, built as a slender lookout: a narrow frame on slim posts, open enough to see the trees through.
	local NAME     = opts.name or "ForestTower"   -- a second one stands on the farm (FarmTower) for the return line
	local ANCHOR_SIDE = opts.anchorSide or 1       -- +1: the wire leaves eastward (the forest); -1: westward (the farm)
	local HEIGHT   = opts.height or 70
	local SIDE     = opts.side or 9.5           -- was 15, which read as a keep rather than a lookout
	local LEVELS   = 5
	local RISE     = HEIGHT / LEVELS
	local POST     = 0.85                       -- was 1.5

	local rng = Random.new(opts.seed or 70119)
	local WOOD   = {Color3.fromRGB(104, 72, 44), Color3.fromRGB(118, 84, 52), Color3.fromRGB(92, 62, 38)}
	local PLANK  = {Color3.fromRGB(146, 108, 66), Color3.fromRGB(132, 96, 58), Color3.fromRGB(158, 119, 74)}
	local DARK   = Color3.fromRGB(62, 42, 26)
	local ROOF   = Color3.fromRGB(78, 54, 34)

	-- ---------------------------------------------------------------- where it stands ----
	local centre
	if opts.centre then
		centre = Vector3.new(opts.centre[1], 0, opts.centre[2])          -- told where: the farm tower
	else
	local dais = workspace:FindFirstChild("SpawnDais_forest")
	assert(dais, "ForestTower: the forest spawn dais is missing")
	local mn, mx
	for _, p in ipairs(dais:GetDescendants()) do
		if p:IsA("BasePart") then
			for sx = -1, 1, 2 do for sz = -1, 1, 2 do
				local v = (p.CFrame * CFrame.new(p.Size.X / 2 * sx, 0, p.Size.Z / 2 * sz)).Position
				mn = mn and Vector3.new(math.min(mn.X, v.X), 0, math.min(mn.Z, v.Z)) or Vector3.new(v.X, 0, v.Z)
				mx = mx and Vector3.new(math.max(mx.X, v.X), 0, math.max(mx.Z, v.Z)) or Vector3.new(v.X, 0, v.Z)
			end end
		end
	end
	local daisC = (mn + mx) / 2
	-- Behind the spawn and off to one side, so it is the first thing you see when you turn round but does not
	-- stand on the pad itself. The wire runs east, so the tower sits WEST of the dais and you launch over it.
	centre = Vector3.new(daisC.X - (opts.offset or 26), 0, daisC.Z + (opts.side_offset or 4))
	end

	-- The old tower goes FIRST. Measuring before demolishing meant the second run read the first tower's roof
	-- as ground level and built a second tower ninety studs up, on top of the first.
	local old = workspace:FindFirstChild(NAME); if old then old:Destroy() end

	-- And the ground is the LOWEST surface in the column, not the first one the ray meets. At this spot the
	-- first hit is a tree canopy at 7.8 while the forest floor is at 0; a tower footed on foliage is a tower
	-- standing in mid-air. Everything above the floor is something the tower should pass through, not sit on.
	local function groundAt(x, z)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
		local skip, y, probe = {}, nil, Vector3.new(x, 250, z)
		for pass = 1, 14 do
			rp.FilterDescendantsInstances = skip
			local h = workspace:Raycast(probe, Vector3.new(0, -400, 0), rp)
			if not h then break end
			if h.Instance:IsA("Terrain") then return h.Position.Y end       -- terrain IS the ground (the farm sits on it, over a baseplate at 0)
			y = h.Position.Y
			table.insert(skip, h.Instance)
			probe = Vector3.new(x, h.Position.Y - 0.1, z)
		end
		return y or 0
	end
	local base = groundAt(centre.X, centre.Z)

	-- ---------------------------------------------------------------- clear the site ----
	-- CLEAR THE SITE PROPERLY. The first pass only removed props carrying a Scatter attribute - the ones I
	-- planted - so the forest's own trees stayed put and one grew straight through the middle of the tower.
	-- It reported "cleared 0" and I believed it. Anything that is a tree, bush, rock, stump, log or mushroom
	-- standing in the footprint comes out now, tagged or not; squirrels and the spawn dais are left alone.
	local cleared, names = 0, {}
	local reach = SIDE / 2 + 4
	local KINDS = {"tree", "pine", "bush", "rock", "stump", "log_", "mushroom", "shrub", "fern"}
	local function isProp(n)
		n = n:lower()
		if n:find("squirrel") or n:find("dais") or n:find("spawn") or n:find("acorn") then return false end
		for _, k in ipairs(KINDS) do if n:find(k, 1, true) then return true end end
		return false
	end
	local function boxOf(m)
		local a, b
		for _, q in ipairs(m:IsA("BasePart") and {m} or m:GetDescendants()) do
			if q:IsA("BasePart") then
				for sx = -1, 1, 2 do for sz = -1, 1, 2 do
					local v = (q.CFrame * CFrame.new(q.Size.X / 2 * sx, 0, q.Size.Z / 2 * sz)).Position
					a = a and Vector2.new(math.min(a.X, v.X), math.min(a.Y, v.Z)) or Vector2.new(v.X, v.Z)
					b = b and Vector2.new(math.max(b.X, v.X), math.max(b.Y, v.Z)) or Vector2.new(v.X, v.Z)
				end end
			end
		end
		return a, b
	end
	for _, root in ipairs(workspace:GetChildren()) do
		if root.Name ~= "Baseplate" then
			for _, o in ipairs(root:GetChildren()) do
				if (o:IsA("Model") or o:IsA("BasePart")) and isProp(o.Name) then
					local a, b = boxOf(o)
					-- its FOOTPRINT has to clear the tower, not just its centre: a tree whose trunk is outside
					-- but whose canopy fills the third floor is still a tree in the middle of the tower
					if a and a.X < centre.X + reach and b.X > centre.X - reach
					   and a.Y < centre.Z + reach and b.Y > centre.Z - reach then
						table.insert(names, o.Name)
						o:Destroy(); cleared += 1
					end
				end
			end
		end
	end

	local T = Instance.new("Model"); T.Name = NAME

	local function wood(name, size, cf, palette, parent)
		local p = Instance.new("Part")
		p.Name = name; p.Size = size; p.CFrame = cf
		-- a palette is a LIST of tones, picked from at random so no two planks match exactly; passing a
		-- single Color3 here dies on the length operator, so accept both
		if typeof(palette) == "Color3" then palette = {palette} end
		p.Color = palette[rng:NextInteger(1, #palette)]
		p.Material = Enum.Material.Wood
		p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or T
		return p
	end

	local h = SIDE / 2

	-- ---------------------------------------------------------------- four legs ----
	-- each dropped onto its own patch of ground, because the forest floor is not flat and a leg that starts at
	-- the average height hangs in the air on one corner
	local corners = {{-h, -h}, {h, -h}, {h, h}, {-h, h}}
	local footY = {}
	for i, c in ipairs(corners) do
		local gy = groundAt(centre.X + c[1], centre.Z + c[2])
		footY[i] = gy
		local top = base + HEIGHT + 2
		local len = top - (gy - 1)
		wood("Leg" .. i, Vector3.new(POST, len, POST),
			CFrame.new(centre.X + c[1], (gy - 1) + len / 2, centre.Z + c[2]), WOOD)
		-- a stone footing, so it does not look like a stick pushed into the grass
		wood("Footing" .. i, Vector3.new(POST + 0.9, 0.9, POST + 0.9),
			CFrame.new(centre.X + c[1], gy + 0.2, centre.Z + c[2]), {Color3.fromRGB(128, 124, 118)})
	end

	-- ---------------------------------------------------------------- the stairs, in numbers ----
	-- These are needed by the decks as well as by the stairs themselves: the opening in each floor is worked
	-- out FROM the climb rather than guessed at, which is what went wrong before - the hole covered where the
	-- flight finished, but you meet the underside of the boards several steps earlier and stop dead.
	local STEPS = 11
	local TREAD = 3.4
	local OFF = 2.3
	local RUN = (SIDE - 2.2) / STEPS
	local STAIR_RISE = RISE / (STEPS * 2)
	local HEADROOM = 5.2                                  -- a character, with a little to spare

	-- the first tread of the SECOND flight that comes within head height of the deck above it
	local firstUnder = STEPS
	for i = 1, STEPS do
		if STAIR_RISE * (STEPS + i) > RISE - HEADROOM then firstUnder = i break end
	end
	local function treadX(flight, i)
		local dir = flight == 0 and 1 or -1
		return dir * (-(SIDE - 2.2) / 2 + RUN * (i - 0.5))
	end
	-- the well runs from there to the top of the flight, with a tread's width either side
	local wellX0 = math.min(treadX(1, firstUnder), treadX(1, STEPS)) - RUN
	local wellX1 = math.max(treadX(1, firstUnder), treadX(1, STEPS)) + RUN
	local wellZ0 = OFF - TREAD / 2 - 0.4
	local wellZ1 = OFF + TREAD / 2 + 0.4

	-- ---------------------------------------------------------------- decks and rails ----
	local decks = {}
	for level = 1, LEVELS do
		local y = base + RISE * level
		decks[level] = y

		-- THE DECK HAS A HOLE IN IT. A solid floor is a ceiling to whoever is on the stairs underneath, and the
		-- climb dead-ended into it - you came up the flight and your head hit the boards. The opening sits over
		-- the top of the second flight, where you actually emerge, and the deck is laid as four boards round it.
		local w = SIDE + (level == LEVELS and 2.2 or 1.0)
		local e = w / 2
		local hx0, hx1 = math.max(wellX0, -e), math.min(wellX1, e)
		local hz0, hz1 = math.max(wellZ0, -e), math.min(wellZ1, e)
		local function board(name, x0, x1, z0, z1)
			if x1 - x0 < 0.05 or z1 - z0 < 0.05 then return end
			wood(name, Vector3.new(x1 - x0, 0.55, z1 - z0),
				CFrame.new(centre.X + (x0 + x1) / 2, y, centre.Z + (z0 + z1) / 2), PLANK)
		end
		board("Deck" .. level, -e, hx0, -e, e)            -- west of the opening
		board("Deck" .. level, hx1, e, -e, e)             -- east of it
		board("Deck" .. level, hx0, hx1, -e, hz0)         -- north of it
		board("Deck" .. level, hx0, hx1, hz1, e)          -- south of it

		-- the beams it sits on
		for _, s in ipairs({-1, 1}) do
			wood("BeamX" .. level, Vector3.new(SIDE + POST, 0.5, 0.55),
				CFrame.new(centre.X, y - 0.65, centre.Z + s * h), WOOD)
			wood("BeamZ" .. level, Vector3.new(0.55, 0.5, SIDE + POST),
				CFrame.new(centre.X + s * h, y - 0.65, centre.Z), WOOD)
		end

		-- Railings on three sides, open to the EAST. That is the way the village and the farm lie, it is where
		-- the wire goes, and it is the whole reason for climbing up here - so that is the side left clear to
		-- look out of. The gap used to be on the north face, left over from when the stairs arrived over an
		-- edge; they come up through the floor now, so nothing needs an opening but the view.
		for _, side in ipairs({{0, -1}, {0, 1}, {-1, 0}, {1, 0}}) do
			local along = side[1] == 0 and Vector3.new(w, 0, 0) or Vector3.new(0, 0, w)
			local outlook = (side[1] == ANCHOR_SIDE)      -- the rail-free side faces the wire
			for _, railY in ipairs({1.0, 2.0}) do
				if not outlook then
					wood("Rail" .. level, along + Vector3.new(0.22, 0.18, 0.22),
						CFrame.new(centre.X + side[1] * w / 2, y + railY, centre.Z + side[2] * w / 2), WOOD)
				end
			end
			-- uprights
			if not outlook then
				for t = -1, 1 do
					local px = centre.X + side[1] * w / 2 + (side[1] == 0 and t * w / 3 or 0)
					local pz = centre.Z + side[2] * w / 2 + (side[2] == 0 and t * w / 3 or 0)
					wood("Baluster", Vector3.new(0.22, 2.3, 0.22), CFrame.new(px, y + 1.15, pz), WOOD)
				end
			end
		end

		-- NO DIAGONAL BRACING. It was awkward to look at and worse to walk through, and a tower this slender
		-- reads better as a clean frame of posts and beams. The legs run unbroken from footing to roof, which
		-- is what is actually holding it up.
	end

	-- ---------------------------------------------------------------- the climb ----
	-- switchback stairs: a flight out along +x, a landing, a flight back along -x, one level gained
	-- The treads have to FIT the frame. At fifteen studs wide a 5.4-stud tread sat comfortably inside; at nine
	-- and a half it hung over both edges, and the two flights ran into each other in the middle. Narrower
	-- treads, flights tucked to either side of the centre line, and the first step low enough to walk onto.
	for level = 1, LEVELS do
		local y0 = level == 1 and base or decks[level - 1]
		local y1 = decks[level]
		local rise, run = STAIR_RISE, RUN
		for flight = 0, 1 do
			local dir = flight == 0 and 1 or -1
			local z = centre.Z + (flight == 0 and -OFF or OFF)
			for i = 1, STEPS do
				local y = y0 + rise * (i + flight * STEPS)
				local x = centre.X + dir * (-(SIDE - 2.2) / 2 + run * (i - 0.5))
				wood("Step", Vector3.new(run + 0.12, 0.35, TREAD), CFrame.new(x, y, z), PLANK)
			end
			if flight == 0 then
				wood("Landing", Vector3.new(2.8, 0.45, OFF * 2 + TREAD),
					CFrame.new(centre.X + (SIDE - 2.2) / 2 + 0.9, y0 + (y1 - y0) / 2, centre.Z), PLANK)
			end
		end
	end

	-- The way in, so it is obvious where the climb starts. The north face is left clear of bracing and gets a
	-- stone step up to the first tread; without it the bottom stair is a floating plank you have to find.
	local firstStepX = centre.X - (SIDE - 2.2) / 2
	wood("Threshold", Vector3.new(3.2, 0.45, 3.0),
		CFrame.new(firstStepX - 1.4, base + 0.22, centre.Z - OFF), {Color3.fromRGB(132, 128, 120)})
	wood("Threshold2", Vector3.new(2.4, 0.4, 2.6),
		CFrame.new(firstStepX - 3.2, base + 0.1, centre.Z - OFF), {Color3.fromRGB(122, 118, 110)})

	-- ---------------------------------------------------------------- the top ----
	local topY = decks[LEVELS]
	local W = SIDE + 2.2

	-- ---------------------------------------------------------------- the roof ----
	-- Worked out before the posts, because the posts have to REACH it. They stand two studs inside the eaves
	-- and the roof slopes upward from the eave to the ridge, so a post cut to eave height stops short and the
	-- roof appears to hover - which is exactly how it looked.
	local RW, RD = W + 2.4, W + 2.4
	local PITCH = 3.0
	-- THE EAVE IS SET BY THE ZIPLINE, not by looks. The rider reaches UP to a trolley on the wire and hangs
	-- from it, so the wire has to leave the tower about 8.8 studs above the boards, and the trolley riding on
	-- it stands most of a stud higher again. At 6.4 the ridge sat right where the trolley needed to be.
	local eaveY = topY + 8.4
	local slant = math.sqrt((RD / 2) ^ 2 + PITCH ^ 2)
	local tilt = math.atan2(PITCH, RD / 2)
	local THICK = 0.45
	local postInset = W / 2 - 0.8

	-- how high the underside of the roof is directly over a post
	local roofUnderAt = eaveY + PITCH * (1 - postInset / (RD / 2)) - THICK / 2

	for _, c in ipairs({{-1, -1}, {1, -1}, {1, 1}, {-1, 1}}) do
		local foot = topY + 0.275
		local len = (roofUnderAt - foot) + 0.5          -- the half stud buries it in the boards, no seam
		wood("RoofPost", Vector3.new(0.45, len, 0.45),
			CFrame.new(centre.X + c[1] * postInset, foot + len / 2, centre.Z + c[2] * postInset), WOOD)
	end

	-- A PITCHED ROOF, built from two angled slabs rather than wedges. The wedge version came out as a V with a
	-- block hovering over it: two wedges mirrored about the vertical axis both slope the same way, so instead
	-- of meeting at a ridge they fell away from each other. Slabs can be reasoned about.
	for _, sgn in ipairs({-1, 1}) do
		local slab = Instance.new("Part")
		slab.Name = "Roof"; slab.Size = Vector3.new(RW, THICK, slant)
		slab.Color = ROOF; slab.Material = Enum.Material.Wood
		slab.Anchored = true; slab.CanCollide = true
		slab.TopSurface = Enum.SurfaceType.Smooth; slab.BottomSurface = Enum.SurfaceType.Smooth
		slab.CFrame = CFrame.new(centre.X, eaveY + PITCH / 2, centre.Z + sgn * RD / 4)
			* CFrame.Angles(sgn * tilt, 0, 0)
		slab.Parent = T
	end
	wood("Ridge", Vector3.new(RW + 0.4, 0.45, 0.7), CFrame.new(centre.X, eaveY + PITCH + 0.2, centre.Z), {DARK})

	-- THE WIRE IS TIED AT HAND HEIGHT, not at the rail. The rider hangs from a trolley on it - shoulder, a
	-- raised arm, the bar, a stem, the wheels - which puts the wire about 8.8 studs above the boards. It used
	-- to be tied 2.4 up, and a rider hanging from THAT would have been standing waist-deep in the deck. A
	-- header runs between the two east roof posts to carry it, under the gable where the roof is highest.
	local ANCHOR_UP = 8.8
	wood("ZipHeader", Vector3.new(0.45, 0.45, postInset * 2 + 0.45),
		CFrame.new(centre.X + ANCHOR_SIDE * postInset, topY + ANCHOR_UP - 0.625, centre.Z), WOOD)
	local anchor = wood("ZipAnchor", Vector3.new(1.1, 0.8, 1.6),
		CFrame.new(centre.X + ANCHOR_SIDE * (W / 2 - 0.4), topY + ANCHOR_UP, centre.Z), {DARK})
	anchor.CanCollide = false
	T:SetAttribute("AnchorY", topY + ANCHOR_UP)
	T:SetAttribute("AnchorSide", ANCHOR_SIDE)
	T:SetAttribute("DeckY", topY)
	T:SetAttribute("Centre", tostring(centre.X) .. "," .. tostring(centre.Z))

	T.Parent = workspace
	local parts = 0
	for _, p in ipairs(T:GetDescendants()) do if p:IsA("BasePart") then parts += 1 end end
	print(string.format(NAME .. ": %d parts at %.0f,%.0f | %.1f wide on %.2f posts | ground %.1f, launch deck %.1f, wire tied %.1f above it | cleared %d: %s",
		parts, centre.X, centre.Z, SIDE, POST, base, topY, ANCHOR_UP, cleared,
		#names > 0 and table.concat(names, ", ") or "nothing"))
	print(string.format("ForestTower: the stairwell opening runs x %.1f..%.1f, z %.1f..%.1f from the centre",
		wellX0, wellX1, wellZ0, wellZ1))
	return T
end

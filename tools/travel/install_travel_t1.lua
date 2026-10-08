-- install_travel_t1 v3 (Oct 1 2026): TRAVEL BETWEEN CITIES for 1001 Squirrels. Safe to re-run (rebuilds its own things only).
-- v2: the forest board moved to the south side of its dais (v1 put it on the Forest Race start pad).
-- v3 (her call, 16:40): no signs at all. ONE travel point in France - a wooden luggage cart with a sticker-covered trunk, a
-- suitcase and a hat box on the Hall of Fame lawn at the Chateau (where everyone walks past) - and its twin on the Porto
-- shore beside the Porto dais. The carts show for everyone; only the hold prompt waits for Item_porto (TravelClient).
--  1. Spawn_porto + SpawnDais_porto: the fourth acorn dais (same artwork and scale as build_spawnpads.lua) on the dry grass
--     east of the plunge pool at (232, -580), tip toward the water; an invisible SpawnLocation on it (attribute Area = porto).
--  2. workspace.Travel: TravelEvent (RemoteEvent), Points (two luggage carts: one on the Hall of Fame lawn at the Chateau
--     bound for Porto Nocciola, one on the Porto shore bound for France), TravelServer (teleport + Item_porto /
--     Item_frenchrank bookkeeping), TravelClient (fade; the carts show for everyone, the hold prompt only once Porto is
--     opened). Back to France lands in the LAST French section the player stood in (Item_frenchrank, saved like any item
--     through ReplicatedStorage.AwardItems).
--  3. SpawnReturnServer patch: south of z -300 is "porto"; a player whose last area is porto respawns there once Item_porto >= 1,
--     otherwise in their last French section. Nothing else in SpawnReturn changes.
-- Persistence: only AwardItems (SquirrelSetup owns the key). Music: NoMusic cleared on arrival in France, set at Porto.
local Players = game:GetService("Players")
local report = {}
local C = Color3.fromRGB

-- ================================================================ 1. the Porto dais + spawn ====
do
	local S = 0.35                                                -- everything across the ground scales by this (as the other three)
	local CREAM, STONE, RIM = C(238, 230, 208), C(206, 194, 166), C(176, 160, 128)
	local GOLD, NUT, CAP, CAP_DK = C(232, 196, 104), C(208, 148, 84), C(112, 72, 42), C(86, 54, 32)
	local LEAF = C(126, 170, 84)
	local spot = {id = "porto", x = 232, z = -580, face = Vector3.new(190, 0, -580)}   -- the landing shore; tip toward the pool
	local skip = {}
	for _, n in ipairs({"Boundary", "SquirrelTwins", "Zones", "Camera", "Travel"}) do local o = workspace:FindFirstChild(n); if o then table.insert(skip, o) end end
	for _, o in ipairs(workspace:GetChildren()) do
		if o:FindFirstChildWhichIsA("Humanoid") or o.Name:sub(1, 9) == "SpawnDais" or o:IsA("SpawnLocation") then table.insert(skip, o) end
	end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = skip; rp.IgnoreWater = true
	local cx, cz = spot.x, spot.z
	local yaw = spot.face and math.atan2(spot.face.X - cx, spot.face.Z - cz) or 0
	local old = workspace:FindFirstChild("SpawnDais_" .. spot.id); if old then old:Destroy() end
	local hit = workspace:Raycast(Vector3.new(cx, 40, cz), Vector3.new(0, -160, 0), rp)
	assert(hit, "Travel: no ground under porto at " .. cx .. ", " .. cz)
	local groundY = hit.Position.Y
	local model = Instance.new("Model"); model.Name = "SpawnDais_" .. spot.id
	local function part(name, size, cf, col, collide)
		local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = false; p.CanTouch = false; p.Locked = true
		p.Material = Enum.Material.SmoothPlastic; p.Color = col; p.Size = size; p.CFrame = cf; p.CastShadow = true
		p.Parent = model
		return p
	end
	local function discAt(name, dx, dz, w, d, y, col, thick, yaw2)
		local p = part(name, Vector3.new(w * S, thick or 0.22, d * S), CFrame.new(cx + dx * S, y, cz + dz * S) * CFrame.Angles(0, yaw2 or 0, 0), col)
		local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
		return p
	end
	local function box(name, w, d, dx, dz, h, y, col, yaw2)
		return part(name, Vector3.new(w * S, h, d * S), CFrame.new(cx + dx * S, y, cz + dz * S) * CFrame.Angles(0, yaw2 or 0, 0), col)
	end
	local topY = groundY + 1.0
	part("Step", Vector3.new(30 * S, 1.64, 30 * S), CFrame.new(cx, groundY - 0.38, cz), RIM, true)
	part("Step", Vector3.new(26 * S, 0.4, 26 * S), CFrame.new(cx, groundY + 0.6, cz), STONE, true)
	local top = part("Top", Vector3.new(22 * S, 0.4, 22 * S), CFrame.new(cx, topY - 0.2, cz), CREAM, true)
	top.TopSurface = Enum.SurfaceType.Smooth
	for _, o in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
		part("Band", Vector3.new(o[1] ~= 0 and 0.4 or 22.4 * S, 0.16, o[2] ~= 0 and 0.4 or 22.4 * S),
			CFrame.new(cx + o[1] * 11.2 * S, topY - 0.02, cz + o[2] * 11.2 * S), GOLD)
	end
	for _, o in ipairs({{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}) do
		part("Stud", Vector3.new(1.4 * S, 0.2, 1.4 * S), CFrame.new(cx + o[1] * 10.3 * S, topY, cz + o[2] * 10.3 * S), GOLD)
	end
	local A = topY + 0.06
	for _, sx in ipairs({-1, 1}) do
		box("LeafStem", 3.4, 0.5, sx * 3.0, -7.9, 0.14, A, C(96, 132, 62), sx * 0.55)
		discAt("Leaf", sx * 6.4, -9.0, 5.6, 2.4, A + 0.02, LEAF, 0.18)
	end
	local PROFILE = {{0.0, -1.2, 5.0}, {0.0, 0.2, 5.3}, {-0.1, 1.7, 5.2}, {-0.2, 3.1, 4.9}, {-0.3, 4.4, 4.4},
		{-0.4, 5.6, 3.8}, {-0.6, 6.7, 3.1}, {-0.8, 7.7, 2.4}, {-1.0, 8.5, 1.7}, {-1.1, 9.1, 1.1}}
	for i, c in ipairs(PROFILE) do
		discAt("Nut", c[1], c[2], c[3] * 2, c[3] * 2, A + 0.02 + i * 0.004, NUT, 0.24)
	end
	box("NutTip", 1.5, 1.5, -1.3, 9.5, 0.2, A + 0.08, NUT, math.pi / 4)
	local function nutAt(z)
		for i = 1, #PROFILE - 1 do
			local a, b = PROFILE[i], PROFILE[i + 1]
			if z >= a[2] and z <= b[2] then
				local f = (z - a[2]) / (b[2] - a[2])
				return a[1] + (b[1] - a[1]) * f, a[3] + (b[3] - a[3]) * f
			end
		end
		return PROFILE[#PROFILE][1], PROFILE[#PROFILE][3]
	end
	local px, pz
	for k = 0, 12 do
		local z = 2.1 + k * 0.48
		local dx, r = nutAt(z)
		local x = dx - r * 0.55
		if px then
			local sx, sz = x - px, z - pz
			local len = math.sqrt(sx * sx + sz * sz)
			box("NutAccent", 0.3, len + 0.1, (x + px) / 2, (z + pz) / 2, 0.16, A + 0.1, C(201, 142, 79), math.atan2(sx, sz))
		end
		px, pz = x, z
	end
	discAt("Cap", 0, -2.6, 14.6, 7.6, A + 0.12, CAP, 0.24)
	discAt("CapBrim", 0, 0.2, 14.8, 2.4, A + 0.14, CAP_DK, 0.18)
	for row = 0, 1 do
		for i = -2, 2 do
			discAt("Scale", i * 2.6 + (row == 1 and 1.3 or 0), -3.8 + row * 2.0, 1.7, 1.2, A + 0.16, C(94, 60, 34), 0.16)
		end
	end
	box("Stem", 1.6, 3.0, 0, -7.2, 0.14, A + 0.12, CAP_DK)
	discAt("StemTop", 0, -8.7, 2.4, 1.5, A + 0.12, CAP_DK, 0.18)
	if yaw ~= 0 then
		local piv = Vector3.new(cx, topY, cz)
		model:PivotTo(CFrame.new(piv) * CFrame.Angles(0, yaw, 0) * CFrame.new(-piv) * model:GetPivot())
	end
	model.Parent = workspace
	local sp = workspace:FindFirstChild("Spawn_" .. spot.id) or Instance.new("SpawnLocation")
	sp.Name = "Spawn_" .. spot.id
	for _, d in ipairs(sp:GetChildren()) do if d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end end
	sp.Anchored = true
	sp.Size = Vector3.new(16 * S, 1, 16 * S)
	sp.CFrame = CFrame.new(cx, topY + 0.5, cz) * CFrame.Angles(0, yaw, 0)
	sp.Transparency = 1
	sp.CanCollide = false                                         -- the dais is the floor; this is only a marker (as the other three)
	sp.Neutral = true
	sp.Enabled = true
	sp.Duration = 0
	sp.AllowTeamChangeOnTouch = false
	sp.TopSurface = Enum.SurfaceType.Smooth
	sp.Parent = workspace
	sp:SetAttribute("Area", spot.id)
	table.insert(report, string.format("Porto dais at %d, %d on %s (ground %.1f, top %.2f)", cx, cz, hit.Instance.Name, groundY, topY))
end

-- ================================================================ 2. the Travel folder ====
local oldT = workspace:FindFirstChild("Travel"); if oldT then oldT:Destroy() end
local F = Instance.new("Folder"); F.Name = "Travel"
local ev = Instance.new("RemoteEvent"); ev.Name = "TravelEvent"; ev.Parent = F
local points = Instance.new("Folder"); points.Name = "Points"; points.Parent = F

local CART_X, CART_Z, CART_FX, CART_FZ = 427, -46, 428, -53   -- the Chateau cart: on the Hall of Fame lawn, facing the gravel path
-- the travel point: a wooden luggage cart carrying a sticker-covered leather trunk, a tan suitcase and a hat box, a luggage
-- tag with the destination, a rolled map leaning on the trunk. Built in a local frame whose +X is the side people see (the
-- stickers, the lock, the tag); the cart's length runs along local Z, the handle rises at the back (-Z). The hold prompt is
-- on the trunk. Everything parts, the game's own flat-colour look.
local function cart(home, dest, label, x, z, facePoint)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = true
	local ex = {F}
	for _, n in ipairs({"Spawn_" .. home, "SpawnDais_" .. home}) do local o = workspace:FindFirstChild(n); if o then ex[#ex + 1] = o end end
	for _, o in ipairs(workspace:GetChildren()) do if o:FindFirstChildWhichIsA("Humanoid") then ex[#ex + 1] = o end end
	rp.FilterDescendantsInstances = ex
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), rp)
	assert(hit, "Travel: no ground for the " .. home .. " cart")
	local g = hit.Position.Y
	local dir = Vector3.new(facePoint.X - x, 0, facePoint.Z - z).Unit
	local yaw = math.atan2(-dir.Z, dir.X)                          -- CFrame.Angles(0, yaw, 0) sends local +X to (cos yaw, 0, -sin yaw)
	local base = CFrame.new(x, g, z) * CFrame.Angles(0, yaw, 0)
	local m = Instance.new("Model"); m.Name = "TravelCart_" .. home
	m:SetAttribute("Dest", dest); m:SetAttribute("Home", home)
	local WOOD, WOOD_DK, IRON = C(156, 112, 64), C(104, 72, 42), C(58, 54, 52)
	local LEATHER, LEATHER_DK, BRASS = C(122, 74, 44), C(86, 50, 30), C(214, 170, 76)
	local TAN, TAN_DK, TEAL, TEAL_DK = C(200, 154, 98), C(148, 106, 64), C(70, 126, 134), C(50, 96, 104)
	local CREAM, RED, GREEN, INK = C(248, 238, 212), C(190, 58, 44), C(98, 142, 72), C(84, 40, 10)
	local function part(name, size, cf, col, mat, collide, shape)
		local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = collide == true; p.CanTouch = false; p.Locked = true
		p.Material = mat or Enum.Material.SmoothPlastic; p.Color = col; p.Size = size; p.CFrame = base * cf; p.CastShadow = true
		if shape then p.Shape = shape end
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local CYL = Enum.PartType.Cylinder                             -- a Cylinder part's axis runs along its X
	-- ---- the cart: a plank bed on an iron axle with two wooden wheels, side rails, a handle rising at the back
	local BED_Y = 1.0
	part("Bed", Vector3.new(2.0, 0.18, 3.4), CFrame.new(0, BED_Y, 0), WOOD, Enum.Material.Wood, true)
	part("Axle", Vector3.new(2.7, 0.14, 0.14), CFrame.new(0, 0.7, 0.3), IRON, Enum.Material.Metal, false, CYL)
	for _, s in ipairs({-1, 1}) do
		part("Rail", Vector3.new(0.16, 0.34, 3.4), CFrame.new(s * 0.98, BED_Y + 0.26, 0), WOOD_DK, Enum.Material.Wood)
		part("Wheel", Vector3.new(0.22, 1.4, 1.4), CFrame.new(s * 1.2, 0.7, 0.3), WOOD_DK, Enum.Material.Wood, true, CYL)
		part("Hub", Vector3.new(0.3, 0.42, 0.42), CFrame.new(s * 1.24, 0.7, 0.3), IRON, Enum.Material.Metal, false, CYL)
		part("HandleRail", Vector3.new(0.12, 0.12, 2.2), CFrame.new(s * 0.6, 1.78, -2.57) * CFrame.Angles(math.rad(38), 0, 0), WOOD_DK, Enum.Material.Wood)
		part("Leg", Vector3.new(0.14, 0.9, 0.14), CFrame.new(s * 0.8, 0.46, 1.5), WOOD_DK, Enum.Material.Wood)   -- the cart rests level on two legs at the front
	end
	part("Grip", Vector3.new(1.4, 0.14, 0.14), CFrame.new(0, 2.45, -3.43), WOOD, Enum.Material.Wood, false, CYL)
	-- ---- the trunk: leather, two dark straps with brass buckles, brass corners, a lock, end handles, stickers, a tag
	local TY = BED_Y + 0.09 + 0.65
	local trunk = part("Trunk", Vector3.new(1.5, 1.3, 2.6), CFrame.new(0, TY, 0.2), LEATHER, Enum.Material.Fabric, true)
	part("Lid", Vector3.new(1.6, 0.24, 2.7), CFrame.new(0, TY + 0.77, 0.2), LEATHER_DK, Enum.Material.Fabric, true)
	for _, dz in ipairs({-0.95, 0.95}) do
		part("Strap", Vector3.new(1.58, 1.34, 0.22), CFrame.new(0, TY, 0.2 + dz), LEATHER_DK, Enum.Material.Fabric)
		part("Buckle", Vector3.new(0.06, 0.3, 0.26), CFrame.new(0.81, TY - 0.15, 0.2 + dz), BRASS, Enum.Material.Metal)
	end
	for _, sx in ipairs({-1, 1}) do
		for _, sy in ipairs({-1, 1}) do
			for _, sz in ipairs({-1, 1}) do
				part("Corner", Vector3.new(0.24, 0.24, 0.24), CFrame.new(sx * 0.72, TY + sy * 0.6, 0.2 + sz * 1.27), BRASS, Enum.Material.Metal)
			end
		end
		part("EndHandle", Vector3.new(0.6, 0.12, 0.12), CFrame.new(0, TY + 0.1, 0.2 + sx * 1.37), BRASS, Enum.Material.Metal, false, CYL)
	end
	part("Lock", Vector3.new(0.05, 0.5, 0.42), CFrame.new(0.78, TY + 0.22, 0.2), BRASS, Enum.Material.Metal)
	part("Keyhole", Vector3.new(0.02, 0.14, 0.08), CFrame.new(0.81, TY + 0.2, 0.2), IRON, Enum.Material.Metal)
	-- stickers on the side people see (+X), each a little proud of the leather, a touch askew
	local lab = part("Sticker", Vector3.new(0.04, 0.6, 0.95), CFrame.new(0.77, TY + 0.05, 0.55) * CFrame.Angles(math.rad(5), 0, 0), CREAM)
	do
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Right; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 240; gui.LightInfluence = 0.6; gui.Parent = lab
		local t1 = Instance.new("TextLabel"); t1.Size = UDim2.new(1, -16, 0.56, 0); t1.Position = UDim2.new(0, 8, 0, 6); t1.BackgroundTransparency = 1
		t1.Font = Enum.Font.FredokaOne; t1.TextScaled = true; t1.TextColor3 = RED; t1.Text = "PORTO NOCCIOLA"; t1.Parent = gui
		local t2 = Instance.new("TextLabel"); t2.Size = UDim2.new(1, -16, 0.3, 0); t2.Position = UDim2.new(0, 8, 0.6, 0); t2.BackgroundTransparency = 1
		t2.Font = Enum.Font.BuilderSansMedium; t2.TextScaled = true; t2.TextColor3 = C(70, 110, 60); t2.Text = "ITALIA  -  by the river"; t2.Parent = gui
		local stripe = Instance.new("Frame"); stripe.Size = UDim2.new(1, 0, 0, 10); stripe.Position = UDim2.new(0, 0, 1, -10); stripe.BackgroundColor3 = GREEN; stripe.BorderSizePixel = 0; stripe.Parent = gui
	end
	part("Badge", Vector3.new(0.04, 0.56, 0.56), CFrame.new(0.775, TY - 0.3, -0.3), TEAL, nil, false, CYL)
	part("BadgeInner", Vector3.new(0.04, 0.36, 0.36), CFrame.new(0.79, TY - 0.3, -0.3), CREAM, nil, false, CYL)
	part("Sticker2", Vector3.new(0.04, 0.3, 0.5), CFrame.new(0.78, TY + 0.47, -0.2) * CFrame.Angles(math.rad(-14), 0, 0), GREEN)
	part("Sticker3", Vector3.new(0.04, 0.26, 0.26), CFrame.new(0.78, TY - 0.45, 1.0) * CFrame.Angles(math.rad(20), 0, 0), C(236, 190, 70))
	-- the luggage tag, on a string from the lock, with where this cart goes
	part("String", Vector3.new(0.4, 0.03, 0.03), CFrame.new(0.8, TY - 0.2, 0.26) * CFrame.Angles(0, 0, math.pi / 2), CREAM, nil, false, CYL)
	local tag = part("Tag", Vector3.new(0.03, 0.32, 0.46), CFrame.new(0.81, TY - 0.56, 0.3) * CFrame.Angles(math.rad(-10), 0, 0), CREAM)
	do
		local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Right; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 300; gui.LightInfluence = 0.6; gui.Parent = tag
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -12, 1, -12); t.Position = UDim2.new(0, 6, 0, 6); t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.TextWrapped = true; t.TextColor3 = INK; t.Text = label; t.Parent = gui
		local ring = Instance.new("Frame"); ring.Size = UDim2.new(1, -6, 1, -6); ring.Position = UDim2.new(0, 3, 0, 3); ring.BackgroundTransparency = 1; ring.Parent = gui
		local st = Instance.new("UIStroke"); st.Color = C(150, 108, 58); st.Thickness = 2; st.Parent = ring
	end
	-- ---- the suitcase on the lid (a little askew), its seam, handle and latches; the hat box on top of it
	local SY = TY + 0.89 + 0.275
	local scf = CFrame.new(0, SY, 0.1) * CFrame.Angles(0, math.rad(9), 0)
	part("Suitcase", Vector3.new(1.0, 0.55, 1.8), scf, TAN, nil, true)
	part("SuitcaseSeam", Vector3.new(1.04, 0.08, 1.84), scf, TAN_DK)
	part("SuitcaseHandle", Vector3.new(0.12, 0.1, 0.5), scf * CFrame.new(0.52, 0.06, 0), TAN_DK)
	for _, dz in ipairs({-0.62, 0.62}) do part("Latch", Vector3.new(0.06, 0.14, 0.22), scf * CFrame.new(0.52, 0.04, dz), BRASS, Enum.Material.Metal) end
	local HY = SY + 0.275 + 0.35
	local hcf = CFrame.new(0.05, HY, -0.25) * CFrame.Angles(0, 0, math.pi / 2)
	part("HatBox", Vector3.new(0.7, 1.05, 1.05), hcf, TEAL, nil, true, CYL)
	part("HatBoxLid", Vector3.new(0.12, 1.1, 1.1), hcf * CFrame.new(0.3, 0, 0), TEAL_DK, nil, false, CYL)
	part("HatBoxRibbon", Vector3.new(0.14, 1.08, 1.08), hcf * CFrame.new(-0.05, 0, 0), CREAM, nil, false, CYL)
	-- a rolled map leaning on the back of the trunk
	do
		local mid = Vector3.new(0.35, BED_Y + 0.09 + 0.6, -1.5)
		local top = mid + Vector3.new(0, 0.55, 0.24)
		part("MapRoll", Vector3.new(1.3, 0.22, 0.22), CFrame.lookAt(mid, top) * CFrame.Angles(0, math.pi / 2, 0), CREAM, nil, false, CYL)
		part("MapBand", Vector3.new(0.2, 0.25, 0.25), CFrame.lookAt(mid, top) * CFrame.Angles(0, math.pi / 2, 0), RED, nil, false, CYL)
	end
	local pr = Instance.new("ProximityPrompt"); pr.Name = "TravelPrompt"; pr.ObjectText = "Travel"; pr.ActionText = label
	pr.HoldDuration = 0.5; pr.MaxActivationDistance = 9; pr.RequiresLineOfSight = false; pr.KeyboardKeyCode = Enum.KeyCode.E
	pr:SetAttribute("Dest", dest); pr.Parent = trunk
	m.PrimaryPart = trunk
	m.Parent = points
	return string.format("%s cart at %.1f, %.1f (ground %.1f, facing %.0f deg)", home, x, z, g, math.deg(yaw))
end
-- ONE travel point in France: on the Hall of Fame lawn at the Chateau, beside the gravel path, facing it (her call, Oct 1)
table.insert(report, cart("domaine", "porto", "Porto Nocciola", CART_X, CART_Z, Vector3.new(CART_FX, 0, CART_FZ)))
-- and its twin on the Porto shore, 7.5 studs east of the Porto dais, facing the dais and the water
table.insert(report, cart("porto", "france", "French Squirrel Country", 239.5, -580, Vector3.new(232, 0, -580)))

local SERVER = [==[
-- TravelServer: the travel boards beside the spawn daises. Hold the prompt and you are at the other city's dais after a
-- short fade (TravelClient draws it). Porto Nocciola opens the first time a player gets there (Item_porto, awarded here when
-- they are down on the shore or in the pool); travelling back to France lands in the LAST French section they stood in
-- (Item_frenchrank 1/2/3 = forest/village/domaine, kept up to date from the Area attribute SpawnReturn sets). Items are saved
-- by SquirrelSetup through ReplicatedStorage.AwardItems; this script never touches the DataStore.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local ev = F:WaitForChild("TravelEvent")
local award = RS:WaitForChild("AwardItems")
local activity = RS:FindFirstChild("PassportActivity")
local SEA_Y = -52.9
local FRENCH = {forest = 1, village = 2, domaine = 3}
local FRENCH_ID = {"forest", "village", "domaine"}
local NAMES = {porto = "Porto Nocciola", forest = "French Squirrel Country", village = "French Squirrel Country", domaine = "French Squirrel Country"}
local busy = {}

local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end
local function opened(p) return item(p, "porto") >= 1 end
local function lastFrench(p)
	local a = p:GetAttribute("Area")
	if FRENCH[a] then return a end
	local r = FRENCH_ID[item(p, "frenchrank")]
	if r then return r end
	local s = p:GetAttribute("SavedArea")
	if FRENCH[s] then return s end
	return "forest"
end
local function travel(p, dest)
	if busy[p] then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 then return end
	local id = dest == "porto" and "porto" or lastFrench(p)
	local sp = workspace:FindFirstChild("Spawn_" .. id)
	if not sp then warn("Travel: no Spawn_" .. id); return end
	busy[p] = true
	ev:FireClient(p, "fade", NAMES[id] or id)
	task.wait(0.45)                                              -- the screen is dark before anything moves
	if not (char.Parent and root.Parent and hum.Parent and hum.Health > 0) then busy[p] = nil; return end
	hum.Sit = false
	local target = CFrame.new(sp.Position + Vector3.new(0, 3.5, 0)) * sp.CFrame.Rotation
	pcall(function() p:RequestStreamAroundAsync(target.Position, 3) end)   -- streaming is on: have the other city there first
	root.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(target)
	p:SetAttribute("Area", id)                                   -- SpawnReturn would catch up within 2 s; this keeps the save and the respawn exact
	p.RespawnLocation = sp
	if id == "porto" then char:SetAttribute("NoMusic", true) else char:SetAttribute("NoMusic", nil) end   -- the map music comes back in France
	ev:FireClient(p, "arrived", NAMES[id] or id)
	print(string.format("Travel: %s -> %s", p.Name, id))
	task.delay(1.5, function() busy[p] = nil end)
end
local function hook(pr)
	if not (pr:IsA("ProximityPrompt") and pr.Name == "TravelPrompt") then return end
	pr.Triggered:Connect(function(p)
		local dest = pr:GetAttribute("Dest") or "porto"
		if dest == "porto" and not opened(p) then
			ev:FireClient(p, "note", "Porto Nocciola opens after your first boat trip down the river.")
			return
		end
		travel(p, dest)
	end)
end
for _, d in ipairs(F:GetDescendants()) do hook(d) end
F.DescendantAdded:Connect(hook)

-- bookkeeping from the Area attribute: the last French section, and the first arrival at Porto Nocciola
local function onArea(p)
	local a = p:GetAttribute("Area")
	if p:GetAttribute("SaveLoaded") ~= true then return end     -- items are not in yet; the next change will do
	if FRENCH[a] then
		local have = item(p, "frenchrank")
		if have ~= FRENCH[a] then award:Fire(p, "frenchrank", FRENCH[a] - have) end
	elseif a == "porto" and not opened(p) then
		task.spawn(function()                                    -- when they are actually down (not still under the chute)
			for _ = 1, 60 do
				if p.Parent ~= Players or p:GetAttribute("Area") ~= "porto" or opened(p) then return end
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and not char:FindFirstChild("Parachute") and root.Position.Y < SEA_Y + 12 then
					award:Fire(p, "porto", 1)
					if activity then activity:Fire(p, "porto", {}) end
					print("Travel: " .. p.Name .. " arrived at Porto Nocciola")
					return
				end
				task.wait(1.5)
			end
		end)
	end
end
local function watch(p)
	p:GetAttributeChangedSignal("Area"):Connect(function() onArea(p) end)
	p:GetAttributeChangedSignal("SaveLoaded"):Connect(function() onArea(p) end)
	onArea(p)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("Travel: boards ready (France <-> Porto Nocciola)")
]==]

local CLIENT = [==[
-- TravelClient: the fade between cities (dark, the destination's name, then the new place), the small notes, and the
-- travel carts' prompts, which this player only gets once Porto Nocciola is opened (Item_porto >= 1).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local p = Players.LocalPlayer
local F = script.Parent
local ev = F:WaitForChild("TravelEvent")
local gui = Instance.new("ScreenGui"); gui.Name = "TravelGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 30; gui.Parent = p:WaitForChild("PlayerGui")
local dark = Instance.new("Frame"); dark.Name = "Dark"; dark.Size = UDim2.fromScale(1, 1); dark.BackgroundColor3 = Color3.fromRGB(22, 15, 10)
dark.BackgroundTransparency = 1; dark.BorderSizePixel = 0; dark.Visible = false; dark.ZIndex = 10; dark.Parent = gui
local name = Instance.new("TextLabel"); name.AnchorPoint = Vector2.new(0.5, 0.5); name.Position = UDim2.fromScale(0.5, 0.5); name.Size = UDim2.new(0.9, 0, 0, 60)
name.BackgroundTransparency = 1; name.Font = Enum.Font.FredokaOne; name.TextSize = 34; name.TextWrapped = true; name.TextColor3 = Color3.fromRGB(255, 244, 214)
name.TextTransparency = 1; name.ZIndex = 11; name.Parent = dark
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 0); toast.Position = UDim2.new(0.5, 0, 0, 72)
toast.Size = UDim2.new(0.92, 0, 0, 56); toast.BackgroundColor3 = Color3.fromRGB(58, 36, 16); toast.BackgroundTransparency = 0.1
toast.BorderSizePixel = 0; toast.Font = Enum.Font.FredokaOne; toast.TextSize = 17; toast.TextWrapped = true
toast.TextColor3 = Color3.fromRGB(255, 244, 214); toast.Visible = false; toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)
local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(460, 56); lim.Parent = toast
local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = toast
local shown = 0
local function note(text, secs)
	shown += 1
	local me = shown
	toast.Text = text; toast.Visible = true
	task.delay(secs or 4, function() if shown == me then toast.Visible = false end end)
end
local trip = 0
local fadeIn
local function fadeOut(where)
	trip += 1
	local me = trip
	name.Text = where or ""
	dark.Visible = true
	TweenService:Create(dark, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	TweenService:Create(name, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	task.delay(5, function() if trip == me and dark.Visible then fadeIn() end end)   -- never stuck in the dark
end
fadeIn = function()
	trip += 1
	TweenService:Create(name, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
	local tw = TweenService:Create(dark, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
	tw:Play()
	tw.Completed:Once(function() if dark.BackgroundTransparency >= 0.99 then dark.Visible = false end end)
end
ev.OnClientEvent:Connect(function(what, arg)
	if what == "fade" then fadeOut(arg)
	elseif what == "arrived" then task.delay(0.5, fadeIn)
	elseif what == "note" then note(arg, 5) end
end)
-- the travel carts stand for everyone; their hold prompt shows for this player only once Porto Nocciola is opened
-- (prompts stream in and out with their parts, so apply on every arrival)
local function opened() return (tonumber(p:GetAttribute("Item_porto")) or 0) >= 1 end
local function apply(d)
	if d:IsA("ProximityPrompt") then d.Enabled = opened() end
end
local function applyAll() for _, d in ipairs(F:GetDescendants()) do apply(d) end end
F.DescendantAdded:Connect(function(d) task.defer(apply, d) end)
p:GetAttributeChangedSignal("Item_porto"):Connect(applyAll)
applyAll()
]==]
local s = Instance.new("Script"); s.Name = "TravelServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "TravelClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F:SetAttribute("Built", "t1 v3 2026-10-01 travel carts")
F.Parent = workspace
table.insert(report, "Travel folder: TravelEvent, Points, TravelServer, TravelClient")

-- ================================================================ 3. SpawnReturn knows the south ====
do
	local sr = workspace:FindFirstChild("SpawnReturn") and workspace.SpawnReturn:FindFirstChild("SpawnReturnServer")
	assert(sr, "Travel: SpawnReturnServer not found")
	local src = sr.Source
	if src:find("porto", 1, true) then
		table.insert(report, "SpawnReturn already knows porto")
	else
		local a = "local function areaAt(pos)\n"
		local i = src:find(a, 1, true); assert(i, "Travel: areaAt not found in SpawnReturnServer")
		src = src:sub(1, i - 1 + #a) .. "\tif pos.Z < -300 then return \"porto\" end                   -- the gorge, the plunge pool and the shore: Porto Nocciola (Travel)\n" .. src:sub(i + #a)
		local i1 = src:find("local function target(player)", 1, true); assert(i1, "Travel: target not found")
		local w = src:find("local want = RANK[", i1, true); assert(w, "Travel: want line not found")
		local j1 = src:find("\n", w, true); assert(j1, "Travel: want line end not found")
		local head = table.concat({
			"local function target(player)                                    -- never past a gate that is still shut",
			"\tlocal area = player:GetAttribute(\"Area\") or player:GetAttribute(\"SavedArea\") or \"forest\"",
			"\t-- Porto Nocciola (Travel): a player who has landed there (Item_porto) comes back to its dais; anyone else whose last",
			"\t-- area is the south (in transit down the river) comes back to the last French section they stood in (Item_frenchrank)",
			"\tif area == \"porto\" then",
			"\t\tif (player:GetAttribute(\"Item_porto\") or 0) >= 1 then return \"porto\" end",
			"\t\tarea = ORDER[player:GetAttribute(\"Item_frenchrank\") or 0] or \"forest\"",
			"\tend",
			"\tlocal want = RANK[area] or 1",
		}, "\n")
		src = src:sub(1, i1 - 1) .. head .. src:sub(j1)
		sr.Source = src
		table.insert(report, "SpawnReturnServer patched (areaAt south = porto; target honours Item_porto / Item_frenchrank)")
	end
end

for _, line in ipairs(report) do print("QQ T1 " .. line) end
print("QQ T1 DONE")

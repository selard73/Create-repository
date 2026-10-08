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

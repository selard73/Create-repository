-- Hall of Fame: every Grand Keeper of the Great Acorn, one at a time, in a big gilded frame. Shannon (Sep 26 2026): "in the
-- forest or maybe some grassy area in the rue, or maybe by the great chateau, I want a 'hall of fame' structure, where you
-- can scroll through and see all of the statues that have been won one at a time in order, sortof like in a big frame";
-- she picked spot A: the entrance lawn of the Chateau, just inside the gate from the Rue, where everyone walks past.
--   THE PAVILION: a small open stone pavilion in the estate's own limestone and terracotta - a back wall, two columns,
--   a beam that reads HALL OF THE GRAND KEEPERS, a pediment with the gilded acorn, a low tiled roof.
--   THE FRAME: a deep gilded shadow-box on the back wall, lined in burgundy velvet and lit from above; inside it, on a
--   marble plinth, the Keeper's statue - the very statue the fountain has (the ChampionServer's MakeStatue: their own
--   avatar in marble, the gilded acorn held up high) - with the Forest Ranger Squirrel saluting beside it.
--   ONE AT A TIME, IN ORDER, EVERYONE THEIR OWN: it opens on the newest Keeper; the gilded buttons either side (tap or
--   click) step to older and newer; the bronze plaque on its stand in front reads "3RD GRAND KEEPER / OF THE GREAT
--   ACORN", the name, the day, and "3 of 12". Each player scrolls their own view: the statue they see is a copy on
--   their own screen. The server makes each statue once (out of sight, well below the hall), keeps it in
--   ReplicatedStorage.HallStatues and hands it over; the squirrel is built once for everyone. Before there is a Keeper, a
--   gilded acorn waits on the plinth.
-- The list is workspace.Champion's HallJson - the ChampionServer's hall, 1st, 2nd, 3rd ... in the order they won.
-- Run in edit mode (re-runnable): require(...)({x = 404, z = -32.9, yaw = -30})   (yaw 0 = the front faces north, -z; Shannon:
-- "a little bit farther back in the corner, like kind of parallel to the chateau" ... "turn it a little ... a little bit diagonal")
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local ServerStorage = game:GetService("ServerStorage")
	local old = workspace:FindFirstChild("HallOfFame"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "HallOfFame"
	local CX, CZ, YAW = opts.x or 404, opts.z or -32.9, math.rad(opts.yaw or -30)   -- (Sep 26: 8 forward - Shannon: "move it forward a little, but at the same angle")
	-- the lawn under it (terrain only): the lowest of the middle and the four corners, so no corner floats
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain}
	local lowest = math.huge
	for _, d in ipairs({{0, 0}, {-11, -9}, {11, -9}, {-11, 8}, {11, 8}}) do
		local p = (CFrame.new(CX, 0, CZ) * CFrame.Angles(0, YAW, 0)) * Vector3.new(d[1], 0, d[2])
		local hit = workspace:Raycast(Vector3.new(p.X, 100, p.Z), Vector3.new(0, -200, 0), rp)
		if hit then lowest = math.min(lowest, hit.Position.Y) end
	end
	local g = (lowest < math.huge) and (lowest - 0.1) or 2.5
	local BASE = CFrame.new(CX, g, CZ) * CFrame.Angles(0, YAW, 0)
	local function at(x, y, z) return BASE * CFrame.new(x, y, z) end
	-- the estate's own colours (domaine/builder.lua): walls, quoins, trim, roof
	local STONE, QUOIN, TRIM, ROOF = C(202, 186, 158), C(224, 214, 194), C(234, 228, 212), C(186, 116, 90)
	local GOLD, VELVET, MARBLE, BRONZE, INK = C(222, 180, 70), C(150, 40, 58), C(236, 232, 224), C(150, 108, 58), C(92, 60, 26)
	local LIME = Enum.Material.Limestone
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end
	local function wedge(name, size, cf, colour, material, parent)
		local p = Instance.new("WedgePart"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or F
		return p
	end
	local function gold(p) p.Reflectance = 0.12; return p end
	local pav = Instance.new("Model"); pav.Name = "Pavilion"; pav.Parent = F

	-- ---------------------------------------------------------------- the pavilion ----
	-- (Shannon: "move the pillars back a little bit and don't make the platform at the bottom quite so big")
	local CZ0 = -3.6                                                     -- the columns' line (z); the back wall is at WZ
	part("Step1", Vector3.new(22.4, 0.5, 14.2), at(0, 0.25, 0.8), QUOIN, LIME, pav)
	part("Step2", Vector3.new(21.2, 0.5, 12.8), at(0, 0.75, 1.0), QUOIN, LIME, pav)
	local Y0 = 1.0                                                       -- the floor
	local WZ, WH = 6.4, 15.1                                             -- the back wall's middle (z) and height
	part("BackWall", Vector3.new(20.6, WH, 1.4), at(0, Y0 + WH / 2, WZ), STONE, LIME, pav)
	part("Dado", Vector3.new(20.9, 0.8, 1.7), at(0, Y0 + 0.4, WZ), QUOIN, LIME, pav)
	local SBL = (WZ - 0.7) - CZ0                                         -- side beams: from the front beam back to the wall
	for _, s in ipairs({-1, 1}) do
		local x, z = s * 8.7, CZ0
		part("ColumnBase", Vector3.new(2.2, 0.6, 2.2), at(x, Y0 + 0.3, z), QUOIN, LIME, pav)
		part("Column", Vector3.new(13.0, 1.6, 1.6), at(x, Y0 + 7.1, z) * CFrame.Angles(0, 0, math.pi / 2), TRIM, LIME, pav, Enum.PartType.Cylinder)
		part("Capital", Vector3.new(2.3, 0.7, 2.3), at(x, Y0 + 13.95, z), QUOIN, LIME, pav)
		part("Pilaster", Vector3.new(1.6, WH, 0.4), at(x, Y0 + WH / 2, WZ - 0.9), QUOIN, LIME, pav)
		part("SideBeam", Vector3.new(1.8, 1.8, SBL + 0.4), at(s * 9.4, Y0 + 15.2, CZ0 + SBL / 2), STONE, LIME, pav)
	end
	local beam = part("Beam", Vector3.new(21.0, 1.8, 1.8), at(0, Y0 + 15.2, CZ0), STONE, LIME, pav)
	local RD0, RD1 = CZ0 - 1.4, WZ + 1.4                                 -- the roof's front and back edges (z)
	part("Cornice", Vector3.new(22.8, 0.5, RD1 - RD0), at(0, Y0 + 16.35, (RD0 + RD1) / 2), QUOIN, LIME, pav)
	-- the low roof: two tiled slopes meeting over the middle, a pediment at each end (the front one with the acorn)
	local RH, RW = 2.6, 11.4                                             -- the rise of the roof, and half its width
	local th = math.atan2(RH, RW)
	for _, s in ipairs({-1, 1}) do
		part("RoofSlope", Vector3.new(math.sqrt(RW * RW + RH * RH) + 0.3, 0.45, RD1 - RD0 + 0.4), at(s * RW / 2, Y0 + 16.6 + RH / 2 + 0.2, (RD0 + RD1) / 2) * CFrame.Angles(0, 0, -s * th), ROOF, Enum.Material.Slate, pav)
		for _, pz in ipairs({RD0 + 0.45, RD1 - 0.45}) do
			wedge("Pediment", Vector3.new(0.9, RH, RW - 0.2), at(s * (RW - 0.2) / 2, Y0 + 16.6 + RH / 2, pz) * CFrame.Angles(0, s * -math.pi / 2, 0), STONE, LIME, pav)
		end
	end
	-- the words on the beam
	local sg = Instance.new("SurfaceGui"); sg.Name = "Title"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50; sg.LightInfluence = 0.3; sg.Parent = beam
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Font = Enum.Font.Antique
	t.Text = "HALL OF THE GRAND KEEPERS"; t.TextScaled = true; t.TextColor3 = INK; t.Parent = sg
	local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 62; tc.Parent = t
	local tp = Instance.new("UIPadding"); tp.PaddingTop = UDim.new(0.12, 0); tp.PaddingBottom = UDim.new(0.12, 0); tp.PaddingLeft = UDim.new(0.04, 0); tp.PaddingRight = UDim.new(0.04, 0); tp.Parent = t
	-- the gilded acorn in the front pediment (the same template as the Keeper's)
	local tpl = ServerStorage:FindFirstChild("ChampionAcorn")
	if tpl then
		local a = tpl:Clone(); a.Name = "PedimentAcorn"
		local _, size = a:GetBoundingBox()
		if size.Y > 0 then pcall(function() a:ScaleTo(a:GetScale() * 1.7 / size.Y) end) end
		for _, p in ipairs(a:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false end end
		a:PivotTo(at(0, Y0 + 16.6 + 1.0, RD0 - 0.1) * CFrame.Angles(0, math.pi, 0))
		local want = at(0, Y0 + 16.6 + 1.05, RD0 - 0.25).Position            -- (by its box: the template's pivot is off-centre)
		local cf = a:GetBoundingBox()
		a:PivotTo(a:GetPivot() + (want - cf.Position))
		a.Parent = pav
	end

	-- ---------------------------------------------------------------- the frame ----
	-- a shadow-box: the inside is 10 wide and 10.8 high, 3 deep from the wall's face; gilded all round, velvet behind
	local frame = Instance.new("Model"); frame.Name = "Frame"; frame.Parent = F
	local FW, FH, FB, FD = 10, 10.8, 0.9, 3.0                            -- inside width, height, border, depth
	local FY0 = Y0 + 2.4                                                 -- the inside's floor
	local face = WZ - 0.7                                                -- the wall's front face (z)
	local zc = face - FD / 2
	for _, s in ipairs({-1, 1}) do
		gold(part("Side", Vector3.new(FB, FH + 2 * FB, FD), at(s * (FW / 2 + FB / 2), FY0 + FH / 2, zc), GOLD, nil, frame))
		gold(part("Lip", Vector3.new(0.5, FH + 2 * FB + 1.0, 0.45), at(s * (FW / 2 + FB + 0.25), FY0 + FH / 2, face - FD + 0.1), GOLD, nil, frame))
	end
	gold(part("Top", Vector3.new(FW + 2 * FB, FB, FD), at(0, FY0 + FH + FB / 2, zc), GOLD, nil, frame))
	gold(part("Bottom", Vector3.new(FW + 2 * FB, FB, FD), at(0, FY0 - FB / 2, zc), GOLD, nil, frame))
	gold(part("LipTop", Vector3.new(FW + 2 * FB + 1.0, 0.5, 0.45), at(0, FY0 + FH + FB + 0.25, face - FD + 0.1), GOLD, nil, frame))
	gold(part("LipBottom", Vector3.new(FW + 2 * FB + 1.0, 0.5, 0.45), at(0, FY0 - FB - 0.25, face - FD + 0.1), GOLD, nil, frame))
	for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({0, 1}) do
		gold(part("Boss", Vector3.new(1.0, 1.0, 1.0), at(sx * (FW / 2 + FB + 0.25), FY0 + (sy == 1 and (FH + FB + 0.25) or (-FB - 0.25)), face - FD + 0.05), GOLD, nil, frame, Enum.PartType.Ball))
	end end
	part("Velvet", Vector3.new(FW, FH, 0.2), at(0, FY0 + FH / 2, face - 0.1), VELVET, Enum.Material.Fabric, frame)
	local plinth = part("Plinth", Vector3.new(6.6, 1.2, 2.4), at(0, FY0 + 0.6, zc + 0.1), MARBLE, Enum.Material.Marble, frame)
	gold(part("PlinthBand", Vector3.new(6.7, 0.14, 2.5), at(0, FY0 + 1.05, zc + 0.1), GOLD, nil, frame))
	local lamp = Instance.new("SpotLight"); lamp.Face = Enum.NormalId.Bottom; lamp.Angle = 90; lamp.Range = 16; lamp.Brightness = 4
	lamp.Color = C(255, 236, 200); lamp.Shadows = true; lamp.Parent = frame:FindFirstChild("Top")
	-- where the statue and the squirrel stand on the plinth, which way they face, how tall a statue may be
	local top = FY0 + 1.2
	F:SetAttribute("FigureSpot", at(1.3, top, zc + 0.1).Position)
	F:SetAttribute("SquirrelSpot", at(-2.3, top, zc + 0.1).Position)
	F:SetAttribute("Look", (BASE.LookVector))                           -- out of the frame, toward the lawn
	F:SetAttribute("MaxHeight", FH - 1.2 - 0.45)                         -- from the plinth's top to just under the frame
	F:SetAttribute("Scale", opts.scale or 1.25)
	F:SetAttribute("SquirrelScale", opts.squirrelScale or 1.2)

	-- ---------------------------------------------------------------- the plaque, on a stand in front ----
	local stand = Instance.new("Model"); stand.Name = "PlaqueStand"; stand.Parent = F
	part("Post", Vector3.new(1.6, 2.4, 1.1), at(0, Y0 + 1.2, -1.3), QUOIN, LIME, stand)
	-- the plaque leans back, its lettered face turned up toward the viewer (the words go on its Front face: a Top face
	-- lays its words along the part's depth, so they came out sideways); big enough to read from the steps
	local plaque = part("Plaque", Vector3.new(7.2, 2.8, 0.2), at(0, Y0 + 2.9, -1.3) * CFrame.Angles(math.rad(52), 0, 0), BRONZE, nil, stand)
	local psg = Instance.new("SurfaceGui"); psg.Name = "Words"; psg.Face = Enum.NormalId.Front; psg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	psg.PixelsPerStud = 70; psg.LightInfluence = 0.35; psg.Parent = plaque
	local function line(name, y, h, size, font, colour)
		local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 12, 0, y); l.Size = UDim2.new(1, -24, 0, h)
		l.Font = font; l.TextScaled = true; l.TextColor3 = colour; l.TextWrapped = true; l.Text = ""; l.Parent = psg
		local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = size; cap.Parent = l
		local st = Instance.new("UIStroke"); st.Color = C(70, 44, 18); st.Thickness = 1.5; st.Transparency = 0.2; st.Parent = l
		return l
	end
	-- (the plaque's face is 7.2 x 2.8 studs = 504 x 196 px at 70 per stud)
	line("Title", 8, 40, 36, Enum.Font.Antique, C(255, 226, 150)).Text = "THE GRAND KEEPERS"
	line("Sub", 48, 22, 20, Enum.Font.Antique, C(255, 236, 190)).Text = "OF THE GREAT ACORN"
	line("Who", 72, 48, 44, Enum.Font.FredokaOne, C(255, 246, 220)).Text = ""
	line("When", 122, 34, 19, Enum.Font.Merriweather, C(255, 236, 190)).Text = ""
	line("Count", 158, 30, 20, Enum.Font.FredokaOne, C(255, 214, 120)).Text = ""

	-- ---------------------------------------------------------------- the buttons, older and newer ----
	-- (facing the hall, its local +x is on your LEFT: older on the left, newer on the right)
	for _, b in ipairs({{name = "Older", s = 1, glyph = "<", word = "older"}, {name = "Newer", s = -1, glyph = ">", word = "newer"}}) do
		local m = Instance.new("Model"); m.Name = b.name; m.Parent = F
		local x = b.s * 7.0
		part("Post", Vector3.new(1.3, 3.2, 1.3), at(x, Y0 + 1.6, -1.9), QUOIN, LIME, m)
		part("Cap", Vector3.new(1.6, 0.3, 1.6), at(x, Y0 + 3.35, -1.9), TRIM, LIME, m)
		local disc = gold(part("Button", Vector3.new(0.35, 2.0, 2.0), at(x, Y0 + 4.5, -1.9) * CFrame.Angles(0, math.pi / 2, 0), GOLD, nil, m, Enum.PartType.Cylinder))
		local dsg = Instance.new("SurfaceGui"); dsg.Face = Enum.NormalId.Right; dsg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; dsg.PixelsPerStud = 60
		dsg.LightInfluence = 0.3; dsg.Parent = disc
		local gl = Instance.new("TextLabel"); gl.BackgroundTransparency = 1; gl.Size = UDim2.fromScale(1, 1); gl.Font = Enum.Font.FredokaOne
		gl.Text = b.glyph; gl.TextScaled = true; gl.TextColor3 = INK; gl.Parent = dsg
		-- (no words on the posts - Shannon: "take off the where it says older and newer, you don't need that")
		for _, p in ipairs({disc, m:FindFirstChild("Post"), m:FindFirstChild("Cap")}) do
			local cd = Instance.new("ClickDetector"); cd.MaxActivationDistance = 40; cd.Parent = p
		end
	end

	-- ---------------------------------------------------------------- the setting ----
	-- Standing alone on the lawn it looked "a little awkward" (Shannon); so it belongs to the garden: a gravel path from its
	-- steps out and round to the farm courtyard, two of the estate's own cypresses behind it, oleanders by its steps.
	local rpAny = RaycastParams.new(); rpAny.FilterType = Enum.RaycastFilterType.Exclude; rpAny.FilterDescendantsInstances = {F}
	local function ground(x, z)
		local hit = workspace:Raycast(Vector3.new(x, 100, z), Vector3.new(0, -200, 0), rpAny)
		return hit and hit.Position.Y or g
	end
	local set = Instance.new("Model"); set.Name = "Setting"; set.Parent = F
	local GRAVEL = C(206, 194, 170)
	local PW = 5                                                         -- the path's width
	local function strip(a, b)                                           -- a straight run of gravel from a to b (world x/z)
		local mid = (a + b) / 2
		local y = ground(mid.X, mid.Z)
		local from = Vector3.new(mid.X, y - 0.05, mid.Z)
		local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		part("Path", Vector3.new(PW, 0.3, d.Magnitude), CFrame.lookAt(from, from + d), GRAVEL, Enum.Material.Pebble, set)
	end
	local function round(p)                                              -- a round patch where two runs meet
		local y = ground(p.X, p.Z)
		part("PathBend", Vector3.new(0.3, PW, PW), CFrame.new(p.X, y - 0.05, p.Z) * CFrame.Angles(0, 0, math.pi / 2), GRAVEL, Enum.Material.Pebble, set, Enum.PartType.Cylinder)
	end
	local p0 = at(0, 0, -6.3).Position                                   -- the foot of the steps
	local p1 = at(0, 0, -20.3).Position                                  -- straight out from them
	local to = opts.pathTo or Vector3.new(452, 0, -58)                   -- the edge of the farm courtyard
	strip(p0, p1); round(p1); strip(p1, Vector3.new(to.X, 0, to.Z))
	-- the estate's own trees and shrubs, a little smaller, their tags removed (a copy must not join what the original is part of)
	local function copyOf(name, scale, lx, lz)
		local src
		for _, m in ipairs(workspace.Domaine.Props:GetChildren()) do if m:IsA("Model") and m.Name == name then src = m break end end
		if not src then return end
		local c = src:Clone(); c.Name = "Hall_" .. name
		local CS = game:GetService("CollectionService")
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BaseScript") then d:Destroy() else for _, t in ipairs(CS:GetTags(d)) do CS:RemoveTag(d, t) end end
		end
		for _, t in ipairs(CS:GetTags(c)) do CS:RemoveTag(c, t) end
		pcall(function() c:ScaleTo(c:GetScale() * scale) end)
		local want = at(lx, 0, lz).Position
		local cf, size = c:GetBoundingBox()
		c:PivotTo(c:GetPivot() + Vector3.new(want.X - cf.X, ground(want.X, want.Z) - (cf.Y - size.Y / 2) - 0.15, want.Z - cf.Z))
		c.Parent = set
	end
	for _, s in ipairs({-1, 1}) do
		copyOf("cypress", 0.8, s * 13.6, 5.2)                            -- behind the back corners
		copyOf("oleander", 0.8, s * 14.2, -4.2)                          -- by the steps
	end

	-- ---------------------------------------------------------------- the signpost in the Rue ----
	-- beside the Keeper's statue by the fountain, pointing the way to the Chateau gate: the game's own fingerpost style
	-- (boundary/build_boundary.lua: dark post, cream board with an arrow tip along +X, words on both faces)
	do
		local SX, SZ = opts.signX or 271, opts.signZ or -62
		local gate = opts.signTo or Vector3.new(352, 0, -120)
		local dx, dz = gate.X - SX, gate.Z - SZ
		local yaw = math.atan2(-dz, dx)                                  -- CFrame.Angles(0, yaw, 0) turns +X toward the gate
		local BOARD, SINK, POSTC = C(244, 232, 204), C(62, 40, 26), C(96, 66, 44)
		local m = Instance.new("Model"); m.Name = "HallSign"; m.Parent = F
		local gy = ground(SX, SZ)
		part("Post", Vector3.new(0.6, 5.6, 0.6), CFrame.new(SX, gy + 2.8, SZ), POSTC, nil, m)
		part("Cap", Vector3.new(0.9, 0.3, 0.9), CFrame.new(SX, gy + 5.75, SZ), POSTC, nil, m)
		local Lb, H, Tk, tip = 8.4, 2.4, 0.32, 1.5
		local base = CFrame.new(SX, gy + 4.25, SZ) * CFrame.Angles(0, yaw, 0)
		local board = part("Board", Vector3.new(Lb, H, Tk), base * CFrame.new(Lb / 2 + 0.35, 0, 0), BOARD, nil, m)
		local up = wedge("Tip", Vector3.new(Tk, H / 2, tip), base * CFrame.new(Lb + 0.35 + tip / 2, H / 4, 0) * CFrame.Angles(0, -math.pi / 2, 0), BOARD, nil, m)
		wedge("Tip", Vector3.new(Tk, H / 2, tip), base * CFrame.new(Lb + 0.35 + tip / 2, -H / 4, 0) * CFrame.Angles(math.pi, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), BOARD, nil, m)
		for _, p in ipairs(m:GetChildren()) do if p:IsA("BasePart") and p ~= m:FindFirstChild("Post") then p.CanCollide = false end end
		for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
			local gui = Instance.new("SurfaceGui"); gui.Face = face; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 50; gui.LightInfluence = 0.5; gui.Parent = board
			local l1 = Instance.new("TextLabel"); l1.Size = UDim2.new(1, -60, 0, 62); l1.Position = UDim2.new(0, 30, 0, 8); l1.BackgroundTransparency = 1
			l1.Text = "Hall of the Grand Keepers"; l1.Font = Enum.Font.FredokaOne; l1.TextScaled = true; l1.TextColor3 = SINK; l1.Parent = gui
			local l2 = Instance.new("TextLabel"); l2.Size = UDim2.new(1, -60, 0, 36); l2.Position = UDim2.new(0, 30, 0, 72); l2.BackgroundTransparency = 1
			l2.Text = "at the Ch\u{E2}teau"; l2.Font = Enum.Font.FredokaOne; l2.TextScaled = true; l2.TextColor3 = C(120, 84, 50); l2.Parent = gui
		end
	end

	-- ---------------------------------------------------------------- the scripts ----
	local fn = Instance.new("RemoteFunction"); fn.Name = "HallStatue"; fn.Parent = F
	local SERVER = [==[
-- HallServer: the statues for the Hall of Fame - made once each (the ChampionServer's own MakeStatue, out of sight well
-- below the hall), kept in ReplicatedStorage.HallStatues, handed to whoever asks; the saluting squirrel, once; the
-- waiting acorn while there is no Keeper yet
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local CH = workspace:WaitForChild("Champion")
local makeStatue = CH:WaitForChild("MakeStatue")
local makeSquirrel = CH:WaitForChild("MakeSquirrel")
local fn = F:WaitForChild("HallStatue")
local store = RS:FindFirstChild("HallStatues")
if not store then store = Instance.new("Folder"); store.Name = "HallStatues"; store.Parent = RS end
for _, o in ipairs(store:GetChildren()) do o:Destroy() end
local SPOT, SQ, LOOK = F:GetAttribute("FigureSpot"), F:GetAttribute("SquirrelSpot"), F:GetAttribute("Look")
local DROP = 300                                                     -- made this far below the hall, out of sight
local function list()
	local ok, t = pcall(function() return HttpService:JSONDecode(CH:GetAttribute("HallJson") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local function entry(no) for _, e in ipairs(list()) do if e.no == no then return e end end return nil end
-- on its feet: the lowest corner of the visible feet (never the invisible root - Shannon's baby avatar floated)
local function feetLow(m)
	local low = math.huge
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "LeftFoot" or d.Name == "RightFoot") and d.Transparency < 0.95 then
			local h = d.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				low = math.min(low, (d.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end end end
		end
	end
	if low == math.huge then local cf, s = m:GetBoundingBox(); low = cf.Y - s.Y / 2 end
	return low
end
local function visibleTop(m)
	local top = -math.huge
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			local h = d.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				top = math.max(top, (d.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end end end
		end
	end
	return top
end
local cache, used, busy, building = {}, {}, {}, false
local function build(no)
	if cache[no] and cache[no].Parent then used[no] = os.clock(); return cache[no] end
	while busy[no] do task.wait(0.2) end
	if cache[no] and cache[no].Parent then return cache[no] end
	local e = entry(no)
	if not e then return nil end
	busy[no] = true
	while building do task.wait(0.2) end
	building = true
	local stage = F:FindFirstChild("Staging")
	if not stage then stage = Instance.new("Folder"); stage.Name = "Staging"; stage.Parent = F end
	local low = Vector3.new(SPOT.X, SPOT.Y - DROP, SPOT.Z)
	local ok, fig, acorn = pcall(function()
		return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = F:GetAttribute("Scale") or 1.25, look = LOOK})
	end)
	local m
	if ok and fig then
		m = Instance.new("Model"); m.Name = "No_" .. tostring(no)
		fig.Parent = m
		if acorn then acorn.Parent = m end
		m.WorldPivot = (m:GetBoundingBox())                              -- (a new Model's pivot is the world origin)
		-- never taller than the frame: the whole statue, acorn and all, scaled down if its top would touch the gilding
		local maxH = F:GetAttribute("MaxHeight") or 9.2
		local h = visibleTop(m) - feetLow(m)
		if h > maxH then pcall(function() m:ScaleTo(m:GetScale() * maxH / h) end) end
		-- back on its feet in the middle of its spot, then up into the frame
		local cf = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(low.X - cf.X, low.Y - feetLow(m), low.Z - cf.Z) + Vector3.new(0, DROP, 0))
		m.Parent = store
		cache[no] = m; used[no] = os.clock()
		-- keep the forty seen most recently
		local n = 0
		for _ in pairs(cache) do n += 1 end
		if n > 40 then
			local oldest, ot
			for k, t in pairs(used) do if cache[k] and (not ot or t < ot) then oldest, ot = k, t end end
			if oldest and oldest ~= no then cache[oldest]:Destroy(); cache[oldest] = nil; used[oldest] = nil end
		end
	else
		warn("HallServer: no statue for No. " .. tostring(no) .. ": " .. tostring(fig))
	end
	building = false
	busy[no] = nil
	return m
end
fn.OnServerInvoke = function(player, no)
	no = tonumber(no)
	if not no then return nil end
	local m = build(math.floor(no))
	return m and m.Name or nil
end
-- the squirrel, saluting, the same for everyone
task.spawn(function()
	if F:FindFirstChild("Squirrel") then return end
	pcall(function()
		makeSquirrel:Invoke({x = SQ.X, y = SQ.Y, z = SQ.Z, tx = SPOT.X, tz = SPOT.Z, parent = F, name = "Squirrel", scale = F:GetAttribute("SquirrelScale") or 1.2})
	end)
end)
-- the acorn that waits on the plinth while there is no Keeper; the newest statue made ahead of anyone asking
local function refresh()
	local l = list()
	local waiting = F:FindFirstChild("WaitingAcorn")
	if #l == 0 and not waiting then
		local tpl = ServerStorage:FindFirstChild("ChampionAcorn")
		if tpl then
			local a = tpl:Clone(); a.Name = "WaitingAcorn"
			local _, size = a:GetBoundingBox()
			if size.Y > 0 then pcall(function() a:ScaleTo(a:GetScale() * 2.2 / size.Y) end) end
			local cf, s2 = a:GetBoundingBox()
			a:PivotTo(a:GetPivot() + Vector3.new(SPOT.X - cf.X, SPOT.Y - (cf.Y - s2.Y / 2), SPOT.Z - cf.Z))
			a.Parent = F
		end
	elseif #l > 0 and waiting then
		waiting:Destroy()
	end
	if #l > 0 then task.spawn(build, l[#l].no) end
end
CH:GetAttributeChangedSignal("HallJson"):Connect(refresh)
refresh()
print("HallServer: ready - " .. #list() .. " Keepers in the hall")
]==]
	local CLIENT = [==[
-- HallClient: this player's own view of the Hall of Fame - the newest Keeper first, older and newer with the buttons
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local F = script.Parent
local CH = workspace:WaitForChild("Champion")
local fn = F:WaitForChild("HallStatue")
local store = RS:WaitForChild("HallStatues")
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end
local function dateOf(day) return os.date("!%B %d, %Y", (tonumber(day) or 0) * 86400 + 12 * 3600) end
local function list()
	local ok, t = pcall(function() return HttpService:JSONDecode(CH:GetAttribute("HallJson") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local view = Instance.new("Folder"); view.Name = "HallView_local"; view.Parent = workspace
local keepers, idx, shownNo = {}, 0, nil
local want = 0                                                       -- the newest request (older ones are dropped)
local function words()
	local stand = F:FindFirstChild("PlaqueStand")
	local plaque = stand and stand:FindFirstChild("Plaque")
	return plaque and plaque:FindFirstChild("Words")
end
local function setPlaque()
	local w = words()
	if not w then return end
	local e = keepers[idx]
	if e then
		w.Title.Text = "THE " .. ordinal(e.no):upper() .. " GRAND KEEPER"
		w.Sub.Text = "OF THE GREAT ACORN"
		w.Who.Text = tostring(e.name or "?")
		w.When.Text = "First to find all " .. tostring(e.total or 44) .. " squirrels on " .. dateOf(e.day)
		w.Count.Text = string.format("%d of %d", idx, #keepers)
	else
		w.Title.Text = "THE GRAND KEEPERS"
		w.Sub.Text = "OF THE GREAT ACORN"
		w.Who.Text = "No Keeper yet"
		w.When.Text = "Be the first to find every squirrel in a day - your statue will stand here"
		w.Count.Text = ""
	end
end
local function setButtons()
	for _, b in ipairs({{name = "Older", on = idx > 1}, {name = "Newer", on = idx < #keepers}}) do
		local m = F:FindFirstChild(b.name)
		local disc = m and m:FindFirstChild("Button")
		if disc then disc.Transparency = b.on and 0 or 0.55 end
	end
end
local function show()
	setPlaque(); setButtons()
	local e = keepers[idx]
	if not e then
		view:ClearAllChildren(); shownNo = nil
		return
	end
	if shownNo == e.no and #view:GetChildren() > 0 then return end
	want += 1
	local mine = want
	task.spawn(function()
		local ok, name = pcall(function() return fn:InvokeServer(e.no) end)
		if mine ~= want then return end                                  -- (scrolled on while it was being made)
		local src = ok and name and store:WaitForChild(name, 15)
		if mine ~= want then return end
		view:ClearAllChildren()
		if src then
			local c = src:Clone()
			c.Parent = view
			shownNo = e.no
		end
	end)
end
local function step(d)
	local n = math.clamp(idx + d, math.min(1, #keepers), #keepers)
	if n ~= idx then idx = n; show() end
end
local function hookButtons()
	for _, b in ipairs({{name = "Older", d = -1}, {name = "Newer", d = 1}}) do
		local m = F:WaitForChild(b.name)
		local function hook(p)
			local cd = p:IsA("BasePart") and p:FindFirstChildOfClass("ClickDetector")
			if cd and not cd:GetAttribute("Hooked") then
				cd:SetAttribute("Hooked", true)
				cd.MouseClick:Connect(function() step(b.d) end)
			end
		end
		for _, p in ipairs(m:GetChildren()) do hook(p) end
		m.ChildAdded:Connect(function(p) task.defer(hook, p) end)          -- (streamed in later)
	end
end
local function reload()
	local atNewest = (idx == #keepers)
	keepers = list()
	if atNewest or idx > #keepers or idx == 0 then idx = #keepers end   -- a new Keeper: the hall moves on to them
	show()
end
task.spawn(hookButtons)
CH:GetAttributeChangedSignal("HallJson"):Connect(reload)
F.DescendantAdded:Connect(function(d) if d.Name == "Words" then task.defer(setPlaque) elseif d.Name == "Button" then task.defer(setButtons) end end)
reload()
]==]
	local s = Instance.new("Script"); s.Name = "HallServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "HallClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print(string.format("HallOfFame: installed at (%.0f, %.1f, %.0f), facing %s", CX, g, CZ, tostring(BASE.LookVector)))
	return F
end

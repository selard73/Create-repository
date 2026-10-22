-- mail2 (Oct 22 2026): the mailbox remade in the treehouse's own wood and moved to a clear spot (Shannon, after seeing
-- mail1 live: "it is cute but can we make it wood, so that it matches the treehouse? ... also, it is sitting right behind a
-- rock, so it is hard for the player to access it"). Players walk up from the forest spawn straight in front (+z, 110 studs);
-- at L(9.5, 23) the big rock (x 7-12, z 27-33) stood between them and it. Now L(4, 24.5), just right of the ladder, nothing
-- in front. Honey plank box (a shade lighter than WOOD - "a little lighter"), a WOOD dome, a darker door with the acorn, gold knob, red flag, a cream nameplate
-- with the name on each side (dark ink - wood on wood would not read), flowers. Previewed in a play test.
-- Run in Studio EDIT. Backs TreehouseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local tc = workspace.Treehouse.TreehouseClient
local src = tc.Source
assert(not src:find("(mail1/mail2)", 1, true), "TreehouseClient already patched")
local a, b = src:find([==[
-- (mail1) the mailbox, right of the ladder (the sign stands left of it), facing the path: a rounded mint box on a
-- wooden post, a cream door with an acorn and a gold knob, a red flag up at the back, your name on both sides,
-- flowers at its foot. Yours from the first piece, like the ladder. Letters come later (roadmap step 8).
local function mailbox()
	local X, Z = 9.5, 23
	local MINT, INK = C(150, 206, 170), C(40, 84, 56)
	local W, H, D = 2.0, 1.05, 2.8                                   -- the box: width, straight sides, depth
	local y0 = 3.3                                                   -- the shelf's top
	local m = Instance.new("Model"); m.Name = "Mailbox"; m.Parent = houseF
	part(Vector3.new(0.65, y0 - 0.25, 0.65), WOOD_DARK, L(X, (y0 - 0.25) / 2, Z), m, Enum.Material.Wood, true)       -- the post
	part(Vector3.new(1.4, 0.25, 2.2), WOOD, L(X, y0 - 0.125, Z), m, Enum.Material.Wood, true)                        -- the shelf
	local body = part(Vector3.new(W, H, D), MINT, L(X, y0 + H / 2, Z), m, Enum.Material.SmoothPlastic, true)
	local dome = part(Vector3.new(D, W, W), MINT, L(X, y0 + H, Z, 0, 90, 0), m, Enum.Material.SmoothPlastic, true)
	dome.Shape = Enum.PartType.Cylinder
	local fz = Z + D / 2 + 0.04                                      -- the front face
	local door = part(Vector3.new(W - 0.24, H - 0.06, 0.08), CREAM, L(X, y0 + (H + 0.06) / 2, fz), m, Enum.Material.SmoothPlastic, false)
	local arch = part(Vector3.new(0.08, W - 0.24, W - 0.24), CREAM, L(X, y0 + H, fz, 0, 90, 0), m, Enum.Material.SmoothPlastic, false)
	arch.Shape = Enum.PartType.Cylinder
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Back; sg.CanvasSize = Vector2.new(176, 100); sg.LightInfluence = 0.5; sg.Parent = door
	local nut = Instance.new("TextLabel"); nut.Size = UDim2.fromScale(1, 1); nut.BackgroundTransparency = 1; nut.TextScaled = true
	nut.Text = utf8.char(0x1F330); nut.Parent = sg
	local knob = part(Vector3.new(0.28, 0.28, 0.28), GOLD, L(X + W * 0.3, y0 + 0.4, fz + 0.08), m, Enum.Material.SmoothPlastic, false)
	knob.Shape = Enum.PartType.Ball
	-- the flag, up, at the back end of the outer side
	local fx, bz = X + W / 2 + 0.08, Z - D / 2 + 0.3
	part(Vector3.new(0.12, 1.3, 0.12), C(60, 60, 64), L(fx, y0 + H + 0.25, bz), m, Enum.Material.Metal, false)
	part(Vector3.new(0.08, 0.55, 0.8), C(214, 64, 56), L(fx, y0 + H + 0.62, bz + 0.38), m, Enum.Material.SmoothPlastic, false)
	local rivet = part(Vector3.new(0.2, 0.2, 0.2), C(60, 60, 64), L(fx, y0 + H - 0.3, bz), m, Enum.Material.Metal, false)
	rivet.Shape = Enum.PartType.Ball
	-- the name on both sides, on the straight part; on the flag's side (+X, where the canvas's RIGHT edge is the back
	-- end) it stops short of the pole
	for _, face in ipairs({Enum.NormalId.Right, Enum.NormalId.Left}) do
		local s = Instance.new("SurfaceGui"); s.Face = face; s.CanvasSize = Vector2.new(280, 105); s.LightInfluence = 0.5; s.Parent = body
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Font = FONT; t.TextScaled = true; t.TextColor3 = INK; t.Text = player.DisplayName
		if face == Enum.NormalId.Right then t.Size = UDim2.new(1, -62, 1, -12); t.Position = UDim2.fromOffset(10, 6)
		else t.Size = UDim2.new(1, -20, 1, -12); t.Position = UDim2.fromOffset(10, 6) end
		t.Parent = s
	end
	-- flowers at its foot
	local blooms = {{-0.65, 0.55, C(240, 140, 170)}, {0.7, 0.45, C(250, 214, 90)}, {-0.25, -0.7, C(250, 250, 245)}, {0.6, -0.6, C(240, 140, 170)}, {0.05, 0.8, C(180, 150, 230)}}
	for _, b in ipairs(blooms) do
		part(Vector3.new(0.1, 0.9, 0.1), C(86, 150, 70), L(X + b[1], 0.45, Z + b[2]), m, Enum.Material.SmoothPlastic, false)
		part(Vector3.new(0.35, 0.08, 0.18), C(96, 170, 80), L(X + b[1] + 0.15, 0.35, Z + b[2], 0, 0, 25), m, Enum.Material.SmoothPlastic, false)
		local head = part(Vector3.new(0.5, 0.5, 0.5), b[3], L(X + b[1], 0.98, Z + b[2]), m, Enum.Material.SmoothPlastic, false)
		head.Shape = Enum.PartType.Ball
		local eye = part(Vector3.new(0.2, 0.2, 0.2), C(250, 196, 60), L(X + b[1], 1.05, Z + b[2] + 0.2), m, Enum.Material.SmoothPlastic, false)
		eye.Shape = Enum.PartType.Ball
	end
	return m
end
]==], 1, true)
assert(a, "TreehouseClient: the mail1 mailbox not found - nothing changed")
src = src:sub(1, a - 1) .. [==[
-- (mail1/mail2) the mailbox, just right of the ladder in plain view of the path (mail2: it first stood behind the big rock
-- - "it is sitting right behind a rock, so it is hard for the player to access it"), made of the treehouse's own wood
-- ("can we make it wood, so that it matches the treehouse" - "a little lighter, but still matching"): a honey plank box, a
-- dome in the house's plank colour, a darker wood door with an acorn and a gold knob, a red flag up at the back, a cream nameplate with your name on each side, flowers at its foot.
-- Yours from the first piece, like the ladder. Letters come later (roadmap step 8).
local function mailbox()
	local X, Z = 4, 24.5
	local INK = C(64, 40, 20)
	local LIGHT, DOOR = C(184, 140, 90), C(122, 86, 50)          -- a shade lighter than the house's planks (hers: "a little lighter")
	local W, H, D = 2.0, 1.05, 2.8                                   -- the box: width, straight sides, depth
	local y0 = 3.3                                                   -- the shelf's top
	local m = Instance.new("Model"); m.Name = "Mailbox"; m.Parent = houseF
	part(Vector3.new(0.65, y0 - 0.25, 0.65), WOOD_DARK, L(X, (y0 - 0.25) / 2, Z), m, Enum.Material.Wood, true)       -- the post
	part(Vector3.new(1.4, 0.25, 2.2), WOOD, L(X, y0 - 0.125, Z), m, Enum.Material.Wood, true)                   -- the shelf
	local body = part(Vector3.new(W, H, D), LIGHT, L(X, y0 + H / 2, Z), m, Enum.Material.WoodPlanks, true)
	local dome = part(Vector3.new(D, W, W), WOOD, L(X, y0 + H, Z, 0, 90, 0), m, Enum.Material.Wood, true)
	dome.Shape = Enum.PartType.Cylinder
	local fz = Z + D / 2 + 0.04                                      -- the front face
	local door = part(Vector3.new(W - 0.24, H - 0.06, 0.08), DOOR, L(X, y0 + (H + 0.06) / 2, fz), m, Enum.Material.Wood, false)
	local arch = part(Vector3.new(0.08, W - 0.24, W - 0.24), DOOR, L(X, y0 + H, fz, 0, 90, 0), m, Enum.Material.Wood, false)
	arch.Shape = Enum.PartType.Cylinder
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Back; sg.CanvasSize = Vector2.new(176, 100); sg.LightInfluence = 0.5; sg.Parent = door
	local nut = Instance.new("TextLabel"); nut.Size = UDim2.fromScale(1, 1); nut.BackgroundTransparency = 1; nut.TextScaled = true
	nut.Text = utf8.char(0x1F330); nut.Parent = sg
	local knob = part(Vector3.new(0.28, 0.28, 0.28), GOLD, L(X + W * 0.3, y0 + 0.4, fz + 0.08), m, Enum.Material.SmoothPlastic, false)
	knob.Shape = Enum.PartType.Ball
	-- the flag, up, at the back end of the outer side
	local fx, bz = X + W / 2 + 0.08, Z - D / 2 + 0.3
	part(Vector3.new(0.12, 1.3, 0.12), C(60, 60, 64), L(fx, y0 + H + 0.25, bz), m, Enum.Material.Metal, false)
	part(Vector3.new(0.08, 0.55, 0.8), C(214, 64, 56), L(fx, y0 + H + 0.62, bz + 0.38), m, Enum.Material.SmoothPlastic, false)
	local rivet = part(Vector3.new(0.2, 0.2, 0.2), C(60, 60, 64), L(fx, y0 + H - 0.3, bz), m, Enum.Material.Metal, false)
	rivet.Shape = Enum.PartType.Ball
	-- a cream nameplate on each side (wood on wood would not read), clear of the flag's pole
	for _, side in ipairs({1, -1}) do
		local plate = part(Vector3.new(0.06, 0.62, 1.85), CREAM, L(X + side * (W / 2 + 0.03), y0 + H / 2, Z + 0.05), m, Enum.Material.SmoothPlastic, false)
		local s = Instance.new("SurfaceGui"); s.Face = side == 1 and Enum.NormalId.Right or Enum.NormalId.Left; s.CanvasSize = Vector2.new(260, 87); s.LightInfluence = 0.5; s.Parent = plate
		local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -16, 1, -10); t.Position = UDim2.fromOffset(8, 5); t.BackgroundTransparency = 1
		t.Font = FONT; t.TextScaled = true; t.TextColor3 = INK; t.Text = player.DisplayName; t.Parent = s
	end
	-- flowers at its foot
	local blooms = {{-0.65, 0.55, C(240, 140, 170)}, {0.7, 0.45, C(250, 214, 90)}, {-0.25, -0.7, C(250, 250, 245)}, {0.6, -0.6, C(240, 140, 170)}, {0.05, 0.8, C(180, 150, 230)}}
	for _, b in ipairs(blooms) do
		part(Vector3.new(0.1, 0.9, 0.1), C(86, 150, 70), L(X + b[1], 0.45, Z + b[2]), m, Enum.Material.SmoothPlastic, false)
		part(Vector3.new(0.35, 0.08, 0.18), C(96, 170, 80), L(X + b[1] + 0.15, 0.35, Z + b[2], 0, 0, 25), m, Enum.Material.SmoothPlastic, false)
		local head = part(Vector3.new(0.5, 0.5, 0.5), b[3], L(X + b[1], 0.98, Z + b[2]), m, Enum.Material.SmoothPlastic, false)
		head.Shape = Enum.PartType.Ball
		local eye = part(Vector3.new(0.2, 0.2, 0.2), C(250, 196, 60), L(X + b[1], 1.05, Z + b[2] + 0.2), m, Enum.Material.SmoothPlastic, false)
		eye.Shape = Enum.PartType.Ball
	end
	return m
end
]==] .. src:sub(b + 1)
local bk = tc:Clone(); bk.Name = "TreehouseClient_pre_mail2"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(tc, function() return src end)
print(string.format("mail2: TreehouseClient -> %d chars", #tc.Source))
return "mail2 installed"

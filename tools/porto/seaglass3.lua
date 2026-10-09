-- porto/seaglass3 (job 34): EDIT mode. The reveal (what Bella made rises and spins in front of you with sparkles), the
-- pearl (one oyster at the back of the Grotta, one pearl per player) and the "Shell box with a pearl" recipe.
-- Exact finds in workspace.SeaGlass.Recipes (2701 chars), SeaGlassClient (10622) and SeaGlassServer (9327, after job 32);
-- every result compiled before anything is written; originals -> ServerStorage.HudBackup.*_pre_seaglass3. Output "QQ SG3".
if game:GetService("RunService"):IsRunning() then warn("QQ SG3 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local Rc, Cl, Sv = G and G:FindFirstChild("Recipes"), G and G:FindFirstChild("SeaGlassClient"), G and G:FindFirstChild("SeaGlassServer")
if not (Rc and Cl and Sv) then warn("QQ SG3 ABORT - missing workspace.SeaGlass.Recipes / SeaGlassClient / SeaGlassServer") return end
for s, n in pairs({[Rc] = 2701, [Cl] = 10622, [Sv] = 9327}) do
	if #s.Source ~= n then warn(string.format("QQ SG3 ABORT - %s is %d chars, expected %d (already patched, or changed); nothing changed", s.Name, #s.Source, n)) return end
end
local PATCHES = {{Rc, "Recipes", {{[===[
	{id = "shell_cowrie",    name = "Cowrie shell",      short = "cowrie",  colour = Color3.fromRGB(215, 170, 130), shell = "cowrie",  weight = 16},
}
]===], [===[
	{id = "shell_cowrie",    name = "Cowrie shell",      short = "cowrie",  colour = Color3.fromRGB(215, 170, 130), shell = "cowrie",  weight = 16},
	{id = "pearl",          name = "Pearl",             short = "pearl",   colour = Color3.fromRGB(246, 242, 236), pearl = true, weight = 0, rare = true},   -- never on a beach: one oyster at the back of the Grotta (Oct 9 2026)
}
]===]}, {[===[
		line = "The purple one! A bottle like this deserves a scent of its own. Keep it safe for France."},
}
]===], [===[
		line = "The purple one! A bottle like this deserves a scent of its own. Keep it safe for France."},
	{id = "shellbox", name = "Shell box with a pearl", needs = {shell_scallop = 2, shell_spiral = 1, shell_cowrie = 1, pearl = 1}, keep = "shell_box",
		line = "A pearl from the Grotta! It needs a box of shells to live in. Keep it with your treasures."},
}
]===]}, {[===[
function R.needsText(r)
]===], [===[
-- what each thing looks like (Oct 9 2026, the reveal): a Model of anchored parts round a hidden Core at its middle
local function part(m, shape, size, colour, material, cf, transparency)
	local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.Color = colour; p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.CFrame = cf; p.Parent = m
	return p
end
local function glass(m, size, colour, cf) local p = part(m, Enum.PartType.Ball, size, colour, Enum.Material.Glass, cf, 0.15); p.Reflectance = 0.1 return p end
function R.build(id)
	local m = Instance.new("Model"); m.Name = "Made_" .. tostring(id)
	local core = part(m, Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), Color3.new(1, 1, 1), nil, CFrame.new(), 1); core.Name = "Core"; m.PrimaryPart = core
	local K = R.byId
	local STRING = Color3.fromRGB(230, 220, 200)
	if id == "suncatcher" then
		part(m, Enum.PartType.Cylinder, Vector3.new(0.12, 2.6, 2.6), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)))
		for i, kid in ipairs({"seaglass_green", "seaglass_blue", "seaglass_white", "seaglass_green", "seaglass_blue", "seaglass_green"}) do
			local a = math.rad(i * 60); local x, z = 0.95 * math.cos(a), 0.95 * math.sin(a)
			part(m, Enum.PartType.Cylinder, Vector3.new(0.9, 0.04, 0.04), STRING, nil, CFrame.new(x, 0.1, z) * CFrame.Angles(0, 0, math.rad(90)))
			glass(m, Vector3.new(0.42, 0.26, 0.34), K[kid].colour, CFrame.new(x, -0.45, z) * CFrame.Angles(0, a, 0))
		end
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_blue.colour, CFrame.new(0, 0.6, 0))
		part(m, Enum.PartType.Cylinder, Vector3.new(1.2, 0.04, 0.04), STRING, nil, CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif id == "necklace" then
		for i = 1, 14 do
			local a = math.rad(i * 360 / 14); local r = 1.05
			local kid = (i % 3 == 0) and "shell_spiral" or "shell_cowrie"
			part(m, Enum.PartType.Ball, Vector3.new(0.34, 0.24, 0.26), K[kid].colour, Enum.Material.Sandstone, CFrame.new(r * math.cos(a), 0.15 * math.cos(a), r * math.sin(a)) * CFrame.Angles(0, -a, math.rad(20)))
		end
		part(m, Enum.PartType.Cylinder, Vector3.new(0.05, 2.2, 2.2), STRING, nil, CFrame.new() * CFrame.Angles(math.rad(90), 0, 0), 0.3)
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_white.colour, CFrame.new(-1.05, -0.3, 0))
	elseif id == "vase" then
		part(m, Enum.PartType.Cylinder, Vector3.new(2.0, 1.1, 1.1), Color3.fromRGB(150, 120, 80), Enum.Material.Pebble, CFrame.new() * CFrame.Angles(0, 0, math.rad(90)))
		for row = 0, 4 do
			for i = 1, 8 do
				local a = math.rad(i * 45 + row * 20)
				local kid = (row % 2 == 0) and ((i % 3 == 0) and "seaglass_brown" or "seaglass_green") or ((i % 2 == 0) and "seaglass_green" or "seaglass_brown")
				glass(m, Vector3.new(0.3, 0.26, 0.18), K[kid].colour, CFrame.new(0.58 * math.cos(a), -0.75 + row * 0.37, 0.58 * math.sin(a)) * CFrame.Angles(0, -a, 0))
			end
		end
		part(m, Enum.PartType.Cylinder, Vector3.new(0.1, 0.6, 0.6), K.shell_scallop.colour, Enum.Material.Sandstone, CFrame.new(0, 0.1, -0.62))
		part(m, Enum.PartType.Cylinder, Vector3.new(0.3, 0.8, 0.8), Color3.fromRGB(150, 120, 80), Enum.Material.Pebble, CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif id == "parfum" then
		local body = part(m, Enum.PartType.Block, Vector3.new(0.9, 1.1, 0.5), K.seaglass_white.colour, Enum.Material.Glass, CFrame.new(0, -0.2, 0), 0.25); body.Reflectance = 0.15
		glass(m, Vector3.new(0.36, 0.36, 0.36), K.seaglass_blue.colour, CFrame.new(0.3, -0.5, 0.2))
		part(m, Enum.PartType.Cylinder, Vector3.new(0.35, 0.3, 0.3), Color3.fromRGB(230, 200, 120), Enum.Material.Metal, CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)))
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_purple.colour, CFrame.new(0, 0.9, 0))
	elseif id == "shellbox" then
		part(m, Enum.PartType.Block, Vector3.new(1.6, 0.8, 1.1), Color3.fromRGB(150, 110, 70), Enum.Material.Wood, CFrame.new(0, -0.3, 0))
		part(m, Enum.PartType.Block, Vector3.new(1.66, 0.22, 1.16), Color3.fromRGB(170, 128, 82), Enum.Material.Wood, CFrame.new(0, 0.21, 0))
		for i, kid in ipairs({"shell_scallop", "shell_spiral", "shell_cowrie", "shell_scallop", "shell_cowrie", "shell_spiral"}) do
			local a = math.rad(i * 60 + 20)
			part(m, Enum.PartType.Ball, Vector3.new(0.34, 0.16, 0.3), K[kid].colour, Enum.Material.Sandstone, CFrame.new(0.55 * math.cos(a), 0.37, 0.32 * math.sin(a)) * CFrame.Angles(0, -a, 0))
		end
		local pearl = part(m, Enum.PartType.Ball, Vector3.new(0.4, 0.4, 0.4), K.pearl and K.pearl.colour or Color3.fromRGB(246, 242, 236), Enum.Material.SmoothPlastic, CFrame.new(0, 0.5, 0)); pearl.Reflectance = 0.35
	else
		glass(m, Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(200, 200, 220), CFrame.new())
	end
	return m
end
function R.needsText(r)
]===]}}}, {Cl, "SeaGlassClient", {{[===[
ev.OnClientEvent:Connect(function(what, a, b, c, d)
]===], [===[
-- the reveal (Oct 9 2026): what Bella made with you rises and spins in front of you, sparkling, then fades
local Debris = game:GetService("Debris")
local function reveal(id)
	local ok, m = pcall(R.build, id)
	if not ok or not m then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	local base = root and (root.CFrame * CFrame.new(0, 1.2, -3.2)) or (cam and cam.CFrame * CFrame.new(0, -0.5, -5)) or CFrame.new()
	local look = cam and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)
	if look.Magnitude > 0.01 then base = CFrame.new(base.Position, base.Position - look.Unit) end
	local core = m.PrimaryPart
	local sp = Instance.new("Sparkles"); sp.SparkleColor = Color3.fromRGB(255, 220, 120); sp.Parent = core
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 230, 170); l.Brightness = 1.5; l.Range = 9; l.Shadows = false; l.Parent = core
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9116394876"; s.Volume = 0.45; s.Parent = core
	m:PivotTo(base); m.Parent = workspace; s:Play()
	local parts = {}
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and p ~= core then table.insert(parts, {p = p, t = p.Transparency}) end end
	local t0 = os.clock(); local LIFE = 5.2
	local conn; conn = game:GetService("RunService").RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > LIFE or not m.Parent then conn:Disconnect(); return end
		local k = math.min(1, t / 1.6); k = k * k * (3 - 2 * k)
		local lift = 2.4 * k + 0.15 * math.sin(t * 2.2)
		local spin = t * (3.2 - 1.6 * k) + 0.4 * math.sin(t * 1.1)
		m:PivotTo(base * CFrame.new(0, lift, 0) * CFrame.Angles(0, spin, math.rad(8) * math.sin(t * 1.7)))
		if t > LIFE - 0.9 then
			local f = (t - (LIFE - 0.9)) / 0.9
			for _, e in ipairs(parts) do e.p.Transparency = e.t + (1 - e.t) * f end
			sp.Enabled = false; l.Brightness = 1.5 * (1 - f)
		end
	end)
	Debris:AddItem(m, LIFE + 0.2)
end
ev.OnClientEvent:Connect(function(what, a, b, c, d)
]===]}, {[===[
		say(line or "Bellissima!", 5)
		refresh()
]===], [===[
		say(line or "Bellissima!", 5)
		refresh()
		reveal(a)
]===]}, {[===[
		if rare then say("Is that... the purple one?! Bring it to me!", 5) end
]===], [===[
		if rare then say(a == "pearl" and "A pearl! Bring it to me: a pearl deserves a box of shells." or "Is that... the purple one?! Bring it to me!", 5) end
]===]}, {[===[
	elseif what == "nope" then
]===], [===[
	elseif what == "toast" then showToast(tostring(a), 4)
	elseif what == "nope" then
]===]}, {[===[
player:GetAttributeChangedSignal("Item_parfum_bottle"):Connect(function() if open then refresh() end end)
]===], [===[
player:GetAttributeChangedSignal("Item_parfum_bottle"):Connect(function() if open then refresh() end end)
player:GetAttributeChangedSignal("Item_shell_box"):Connect(function() if open then refresh() end end)
]===]}}}, {Sv, "SeaGlassServer", {{[===[
	else
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.42, 0.26, 0.3); body.Material = Enum.Material.SmoothPlastic; body.Reflectance = 0.1
]===], [===[
	elseif kind.pearl then
		-- an open oyster: two shells and the pearl between them, with a soft glow to find it by in the dark of the Grotta
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.5, 0.5, 0.5); body.Material = Enum.Material.SmoothPlastic; body.Reflectance = 0.35
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.36, 0))
		for i, ang in ipairs({math.rad(6), math.rad(-58)}) do
			local sh = Instance.new("Part"); sh.Name = "Shell" .. i; sh.Shape = Enum.PartType.Ball; sh.Size = Vector3.new(1.3, 0.3, 1.1); sh.Color = Color3.fromRGB(214, 196, 170)
			sh.Material = Enum.Material.Sandstone; sh.Anchored = true; sh.CanCollide = false; sh.CanQuery = false; sh.CanTouch = false; sh.CastShadow = false
			sh.CFrame = CFrame.new(pos + Vector3.new(0, i == 1 and 0.12 or 0.55, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, i == 1 and 0 or -0.4) * CFrame.Angles(ang, 0, 0); sh.Parent = m
		end
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(230, 235, 255); l.Brightness = 0.9; l.Range = 6; l.Shadows = false; l.Parent = body
	else
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.42, 0.26, 0.3); body.Material = Enum.Material.SmoothPlastic; body.Reflectance = 0.1
]===]}, {[===[
for _, box in ipairs(boxes) do for _ = 1, box.count do spawnOne(box) end end
]===], [===[
for _, box in ipairs(boxes) do for _ = 1, box.count do spawnOne(box) end end

-- the pearl (Oct 9 2026, Shannon): one oyster at the back of the Grotta Azzurra, behind Polpo's cages. One pearl per
-- player (Item_pearl); after a pickup the oyster is back PearlRespawn seconds later for the next player.
local pearlKind = R.byId.pearl
if pearlKind then
	local want = G:GetAttribute("PearlSpot"); if typeof(want) ~= "Vector3" then want = Vector3.new(515, -44, -1121) end
	local pparams = RaycastParams.new(); pparams.FilterType = Enum.RaycastFilterType.Exclude; pparams.FilterDescendantsInstances = {pieces}; pparams.IgnoreWater = true
	local spot
	for _, d in ipairs({Vector3.zero, Vector3.new(2, 0, 0), Vector3.new(-2, 0, 0), Vector3.new(0, 0, 2), Vector3.new(0, 0, -2), Vector3.new(-4, 0, 0), Vector3.new(-4, 0, 3), Vector3.new(-4, 0, -3), Vector3.new(-7, 0, 0)}) do
		local hit = workspace:Raycast(want + d, Vector3.new(0, -14, 0), pparams)
		if hit and hit.Normal.Y > 0.6 then spot = hit.Position break end
	end
	if not spot then spot = Vector3.new(want.X, want.Y - 5, want.Z); warn("SeaGlassServer: no floor under the pearl spot; using " .. tostring(spot)) end
	local function spawnPearl()
		local m, pr = build(pearlKind, spot, rng)
		pr.ActionText = "Take the pearl"
		pr.Triggered:Connect(function(p)
			if taking[m] or not m.Parent then return end
			if item(p, "pearl") >= 1 then ev:FireClient(p, "toast", "You already found the pearl. Bella can make a shell box for it!") return end
			taking[m] = true
			awardItems:Fire(p, "pearl", 1)
			ev:FireClient(p, "found", "pearl", pearlKind.name, 1, true)
			m:Destroy()
			task.delay(num("PearlRespawn", 300), spawnPearl)
		end)
	end
	spawnPearl()
	print(string.format("SeaGlassServer: the pearl waits at %.0f,%.1f,%.0f", spot.X, spot.Y, spot.Z))
end
]===]}}}}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, list = pt[1], pt[2], pt[3]
	local o = s.Source
	for i, p in ipairs(list) do
		local a, b = o:find(p[1], 1, true)
		if not a then warn("QQ SG3 ABORT - " .. name .. " find " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then warn("QQ SG3 ABORT - " .. name .. " find " .. i .. " matches more than once; nothing changed") return end
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ SG3 ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
for s, o in pairs(out) do
	local b = s:Clone(); b.Name = s.Name .. "_pre_seaglass3"
	if b:IsA("BaseScript") then b.Enabled = false end
	b.Parent = backup; s.Source = o
end
G:SetAttribute("PearlSpot", Vector3.new(515, -44, -1121)); G:SetAttribute("PearlRespawn", 300)
print(string.format("QQ SG3 DONE: Recipes %d, SeaGlassClient %d, SeaGlassServer %d chars; PearlSpot 515,-44,-1121; backups ServerStorage.HudBackup.*_pre_seaglass3", #Rc.Source, #Cl.Source, #Sv.Source))

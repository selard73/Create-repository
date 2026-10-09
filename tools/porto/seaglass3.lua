-- porto/seaglass3 (job 34): EDIT mode. The reveal: what Bella made with you rises and spins in front of you with
-- sparkles, then fades. Exact finds in workspace.SeaGlass.Recipes (2701 chars) and SeaGlassClient (10622 chars, the
-- job 18 text); compiled before writing; originals -> ServerStorage.HudBackup.*_pre_seaglass3. Output lines "QQ SG3".
if game:GetService("RunService"):IsRunning() then warn("QQ SG3 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local Rc, Cl = G and G:FindFirstChild("Recipes"), G and G:FindFirstChild("SeaGlassClient")
if not (Rc and Cl) then warn("QQ SG3 ABORT - missing workspace.SeaGlass.Recipes / SeaGlassClient") return end
for s, n in pairs({[Rc] = 2701, [Cl] = 10622}) do
	if #s.Source ~= n then warn(string.format("QQ SG3 ABORT - %s is %d chars, expected %d (already patched, or changed); nothing changed", s.Name, #s.Source, n)) return end
end
local PATCHES = {{Rc, "Recipes", {{[===[
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
	if id == "suncatcher" then
		local ring = part(m, Enum.PartType.Cylinder, Vector3.new(0.12, 2.6, 2.6), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)))
		for i, kid in ipairs({"seaglass_green", "seaglass_blue", "seaglass_white", "seaglass_green", "seaglass_blue", "seaglass_green"}) do
			local a = math.rad(i * 60); local x = 0.95 * math.cos(a)
			part(m, Enum.PartType.Cylinder, Vector3.new(0.9, 0.04, 0.04), Color3.fromRGB(230, 220, 200), nil, CFrame.new(x, 0.1, 0.95 * math.sin(a)) * CFrame.Angles(0, 0, math.rad(90)))
			glass(m, Vector3.new(0.42, 0.26, 0.34), K[kid].colour, CFrame.new(x, -0.45, 0.95 * math.sin(a)) * CFrame.Angles(0, a, 0))
		end
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_blue.colour, CFrame.new(0, 0.6, 0))
		part(m, Enum.PartType.Cylinder, Vector3.new(1.2, 0.04, 0.04), Color3.fromRGB(230, 220, 200), nil, CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif id == "necklace" then
		for i = 1, 14 do
			local a = math.rad(i * 360 / 14); local r = 1.05
			local kid = (i % 3 == 0) and "shell_spiral" or "shell_cowrie"
			part(m, Enum.PartType.Ball, Vector3.new(0.34, 0.24, 0.26), K[kid].colour, Enum.Material.Sandstone, CFrame.new(r * math.cos(a), 0.15 * math.cos(a), r * math.sin(a)) * CFrame.Angles(0, -a, math.rad(20)))
		end
		part(m, Enum.PartType.Cylinder, Vector3.new(0.05, 2.2, 2.2), Color3.fromRGB(230, 220, 200), nil, CFrame.new() * CFrame.Angles(math.rad(90), 0, 0), 0.3)
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_white.colour, CFrame.new(-1.05, -0.3, 0))
	elseif id == "vase" then
		part(m, Enum.PartType.Cylinder, Vector3.new(2.0, 1.1, 1.1), Color3.fromRGB(150, 120, 80), Enum.Material.Pebble, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)))
		for row = 0, 4 do
			for i = 1, 8 do
				local a = math.rad(i * 45 + row * 20); local kid = (row % 2 == 0) and ((i % 3 == 0) and "seaglass_brown" or "seaglass_green") or ((i % 2 == 0) and "seaglass_green" or "seaglass_brown")
				glass(m, Vector3.new(0.3, 0.26, 0.18), K[kid].colour, CFrame.new(0.58 * math.cos(a), -0.75 + row * 0.37, 0.58 * math.sin(a)) * CFrame.Angles(0, -a, 0))
			end
		end
		part(m, Enum.PartType.Cylinder, Vector3.new(0.1, 0.6, 0.6), K.shell_scallop.colour, Enum.Material.Sandstone, CFrame.new(0, 0.1, -0.62) * CFrame.Angles(0, 0, 0))
		part(m, Enum.PartType.Cylinder, Vector3.new(0.3, 0.8, 0.8), Color3.fromRGB(150, 120, 80), Enum.Material.Pebble, CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif id == "parfum" then
		local body = part(m, Enum.PartType.Block, Vector3.new(0.9, 1.1, 0.5), K.seaglass_white.colour, Enum.Material.Glass, CFrame.new(0, -0.2, 0), 0.25); body.Reflectance = 0.15
		glass(m, Vector3.new(0.36, 0.36, 0.36), K.seaglass_blue.colour, CFrame.new(0.3, -0.5, 0.2))
		part(m, Enum.PartType.Cylinder, Vector3.new(0.35, 0.3, 0.3), Color3.fromRGB(230, 200, 120), Enum.Material.Metal, CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)))
		glass(m, Vector3.new(0.5, 0.5, 0.5), K.seaglass_purple.colour, CFrame.new(0, 0.9, 0))
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
	base = CFrame.new(base.Position, base.Position + Vector3.new(cam and cam.CFrame.LookVector.X or 0, 0, cam and cam.CFrame.LookVector.Z or -1) * -1)
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
print(string.format("QQ SG3 DONE: Recipes %d, SeaGlassClient %d chars; backups ServerStorage.HudBackup.*_pre_seaglass3", #Rc.Source, #Cl.Source))

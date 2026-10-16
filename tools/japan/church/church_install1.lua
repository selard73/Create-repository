-- church_install1.lua: the church (Goto-islands style) at SITE (a play-test PREVIEW first; Studio EDIT on Shannon's word; re-runnable).
-- The kit Models "church_shell" and "church_interior" are placed by bounding box with the door facing the yaw; pews get Seats, the
-- door leaves swing on a prompt, the bell rope rings the bell, candles glow. Output "QQ CHURCH1".
local SITE_X, SITE_Z, SITE_YAW, GROUND_Y = 6101, -266, 0, 0            -- site A (runner 7): the lawn behind the falls, x 6060..6140, z -285..-242; the nave 33.7 long runs north-south, its door (+z) facing the canal at z -249, the back at -283, the hill behind from -320
local BELL_SOUND = ""                                                   -- a bell toll sound id (rbxassetid://...) when she has picked one; "" = the bell swings silently
local SS = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
if not (KIT and J) then print("QQ CHURCH1 ABORT: ServerStorage.JapanGardenKit or workspace.JapanMap missing") return end
for _, n in ipairs({"church_shell", "church_interior"}) do
	if not KIT:FindFirstChild(n) then print("QQ CHURCH1 ABORT: the kit has no Model '" .. n .. "' - import tools/japan/church/out/*.fbx") return end
end
local BB = {
	["church_shell"] = {min = Vector3.new(-9.37, 0.0, -16.3), max = Vector3.new(9.37, 25.1, 17.4)},
	["church_interior"] = {min = Vector3.new(-7.4, 0.78, -14.4), max = Vector3.new(7.4, 14.9, 14.4)}
}
local COL = {
	Church_Plaster = Color3.new(0.93, 0.91, 0.85),
	Church_Timber = Color3.new(0.24, 0.17, 0.12),
	Church_Stone = Color3.new(0.58, 0.57, 0.54),
	Church_Roof = Color3.new(0.3, 0.33, 0.38),
	Church_Ridge = Color3.new(0.24, 0.26, 0.3),
	Church_Door_L = Color3.new(0.4, 0.26, 0.15),
	Church_Door_R = Color3.new(0.4, 0.26, 0.15),
	Church_Door_L_Trim = Color3.new(0.24, 0.17, 0.12),
	Church_Door_R_Trim = Color3.new(0.24, 0.17, 0.12),
	Church_Glass_Blue = Color3.new(0.55, 0.72, 0.92),
	Church_Glass_Gold = Color3.new(0.95, 0.72, 0.3),
	Church_Glass_Red = Color3.new(0.8, 0.22, 0.24),
	Church_Cross = Color3.new(0.55, 0.42, 0.22),
	Church_Bell = Color3.new(0.62, 0.48, 0.24),
	Church_Louvre = Color3.new(0.3, 0.22, 0.15),
	Church_Floor = Color3.new(0.45, 0.31, 0.19),
	Church_Pew = Color3.new(0.46, 0.3, 0.17),
	Church_Altar = Color3.new(0.92, 0.9, 0.86),
	Church_Cloth = Color3.new(0.75, 0.16, 0.18),
	Church_Candle = Color3.new(0.97, 0.95, 0.88),
	Church_Flame = Color3.new(1.0, 0.8, 0.35),
	Church_Rope = Color3.new(0.72, 0.62, 0.45)
}
local SEATS = {
	{x = -3.8, y = 1.4, z = 10.120000000000001, w = 5.0},
	{x = -3.8, y = 1.4, z = 7.0200000000000005, w = 5.0},
	{x = -3.8, y = 1.4, z = 3.92, w = 5.0},
	{x = -3.8, y = 1.4, z = 0.8199999999999996, w = 5.0},
	{x = -3.8, y = 1.4, z = -2.2800000000000002, w = 5.0},
	{x = 3.8, y = 1.4, z = 10.120000000000001, w = 5.0},
	{x = 3.8, y = 1.4, z = 7.0200000000000005, w = 5.0},
	{x = 3.8, y = 1.4, z = 3.92, w = 5.0},
	{x = 3.8, y = 1.4, z = 0.8199999999999996, w = 5.0},
	{x = 3.8, y = 1.4, z = -2.2800000000000002, w = 5.0}
}
local ROPE = Vector3.new(-5.8, 2.1, 12.8)
local DOOR = {hingeL = -1.25, hingeR = 1.25, leafZ = 14.65, y = 0.9}
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local old = J:FindFirstChild("Church")
if old then local prev = hb:FindFirstChild("Church_prev"); if prev then prev:Destroy() end; old.Name = "Church_prev"; old.Parent = hb end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before church1") end)
local G = Instance.new("Folder"); G.Name = "Church"; G.Parent = J
local ORIGIN = CFrame.new(SITE_X, GROUND_Y, SITE_Z) * CFrame.Angles(0, math.rad(SITE_YAW), 0)   -- the model's origin (ground level, the nave's centre)
local meshes, missing = 0, {}
local SOLID_OFF = {Church_Flame = true, Church_Rope = true, Church_Candle = false}
local PRECISE = {Church_Plaster = true, Church_Stone = true, Church_Floor = true, Church_Pew = true, Church_Timber = true, Church_Roof = true, Church_Door_L = true, Church_Door_R = true}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local key = p.Name:gsub("%.%d+$", "")
			p.Anchored = true; p.CastShadow = true; p.Material = Enum.Material.SmoothPlastic
			if COL[key] then p.Color = COL[key] else table.insert(missing, p.Name) end
			p.CanCollide = not SOLID_OFF[key]; p.CanQuery = p.CanCollide; p.CanTouch = false
			if p:IsA("MeshPart") and PRECISE[key] then pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) end
			if key == "Church_Timber" or key == "Church_Pew" or key == "Church_Floor" or key:sub(1, 11) == "Church_Door" or key == "Church_Louvre" then p.Material = Enum.Material.Wood
			elseif key == "Church_Stone" or key == "Church_Roof" or key == "Church_Ridge" then p.Material = Enum.Material.Slate
			elseif key == "Church_Altar" then p.Material = Enum.Material.Marble
			elseif key == "Church_Cloth" then p.Material = Enum.Material.Fabric
			elseif key == "Church_Bell" or key == "Church_Cross" or key == "Church_Cross_Altar" then p.Material = Enum.Material.Metal
			elseif key:sub(1, 12) == "Church_Glass" then p.Material = Enum.Material.Glass; p.Transparency = 0.3; p.CastShadow = false
			elseif key == "Church_Flame" then
				p.Material = Enum.Material.Neon; p.CastShadow = false
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 200, 130); l.Range = 9; l.Brightness = 0.9; l.Shadows = false; l.Parent = p
			end
			meshes += 1
		end
	end
end
local function place(kitName, label)
	local m = KIT:FindFirstChild(kitName):Clone(); m.Name = label
	local box = BB[kitName]
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position - (box.min + box.max) / 2)
	m:PivotTo(ORIGIN)
	dress(m); m.Parent = G
	return m
end
local shell = place("church_shell", "Shell")
local interior = place("church_interior", "Interior")
-- the doors: the two leaves swing 100 degrees inward about their outer edges on a prompt, and close again after 10 s
local function leaf(name) for _, p in ipairs(shell:GetDescendants()) do if p:IsA("BasePart") and p.Name:gsub("%.%d+$", "") == name then return p end end end
local leaves = {}
for _, side in ipairs({{"Church_Door_L", "Church_Door_L_Trim", DOOR.hingeL, 1}, {"Church_Door_R", "Church_Door_R_Trim", DOOR.hingeR, -1}}) do
	local door, trim = leaf(side[1]), leaf(side[2])
	if door then
		local hinge = ORIGIN * CFrame.new(side[3], DOOR.y, DOOR.leafZ)              -- the hinge line, world
		table.insert(leaves, {door = door, trim = trim, hinge = hinge, dir = side[4], doorRel = hinge:ToObjectSpace(door.CFrame), trimRel = trim and hinge:ToObjectSpace(trim.CFrame)})
	end
end
local doorOpen, doorBusy = false, false
local function setDoors(open)
	for _, l in ipairs(leaves) do
		local h = l.hinge * CFrame.Angles(0, open and math.rad(100 * l.dir) or 0, 0)
		TS:Create(l.door, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = h * l.doorRel}):Play()
		if l.trim then TS:Create(l.trim, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = h * l.trimRel}):Play() end
	end
end
if #leaves == 2 then
	local pp = Instance.new("ProximityPrompt"); pp.Name = "DoorPrompt"; pp.ActionText = "Open the door"; pp.ObjectText = "Church"; pp.KeyboardKeyCode = Enum.KeyCode.E
	pp.MaxActivationDistance = 9; pp.RequiresLineOfSight = false; pp.HoldDuration = 0; pp.Parent = leaves[2].door
	pp.Triggered:Connect(function()
		if doorBusy then return end
		doorBusy = true; doorOpen = not doorOpen; setDoors(doorOpen); pp.ActionText = doorOpen and "Close the door" or "Open the door"
		task.delay(1.2, function() doorBusy = false end)
		if doorOpen then task.delay(10, function() if doorOpen then doorOpen = false; setDoors(false); pp.ActionText = "Open the door" end end) end
	end)
	-- the leaves must not block while open: collision follows the mesh (PreciseConvexDecomposition), so nothing more to do
end
-- the pews: an invisible Seat on each (automatic sit, like the treehouse chairs)
local SF = Instance.new("Folder"); SF.Name = "Seats"; SF.Parent = G
local nseat = 0
for i, s in ipairs(SEATS) do
	for k = -1, 1 do                                                             -- three seats per pew
		local seat = Instance.new("Seat"); seat.Name = "PewSeat" .. i .. "_" .. (k + 2)
		seat.Size = Vector3.new(1.6, 0.3, 0.9); seat.Transparency = 1; seat.Anchored = true; seat.CanCollide = false; seat.CanQuery = false
		seat.CFrame = ORIGIN * CFrame.new(s.x + k * 1.6, s.y + 0.15, s.z) * CFrame.Angles(0, math.rad(180), 0)   -- facing the altar (-z of the model)
		seat.Parent = SF; nseat += 1
	end
end
-- the bell rope: pull it and the bell swings (and tolls when BELL_SOUND is set); one pull per 8 s
local bell = leaf("Church_Bell")
local ropePart
for _, p in ipairs(interior:GetDescendants()) do if p:IsA("BasePart") and p.Name:gsub("%.%d+$", "") == "Church_Rope" then ropePart = p end end
if bell and ropePart then
	local pp = Instance.new("ProximityPrompt"); pp.Name = "BellPrompt"; pp.ActionText = "Ring the bell"; pp.ObjectText = "Bell rope"; pp.KeyboardKeyCode = Enum.KeyCode.E
	pp.MaxActivationDistance = 7; pp.RequiresLineOfSight = false; pp.HoldDuration = 0.4; pp.Parent = ropePart
	local base = bell.CFrame
	local hanger = ORIGIN * CFrame.new(ROPE.X, 16.6, ROPE.Z)                       -- the bell hangs from its beam at 16.6
	local rel = hanger:ToObjectSpace(base)
	local snd
	if BELL_SOUND ~= "" then snd = Instance.new("Sound"); snd.SoundId = BELL_SOUND; snd.Volume = 0.9; snd.RollOffMaxDistance = 220; snd.RollOffMinDistance = 25; snd.Parent = bell end
	local ringing = false
	pp.Triggered:Connect(function()
		if ringing then return end
		ringing = true; pp.Enabled = false
		task.spawn(function()
			for i = 1, 6 do
				local a = math.rad(28) * (1 - i / 8) * ((i % 2 == 0) and 1 or -1)
				TS:Create(bell, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = hanger * CFrame.Angles(a, 0, 0) * rel}):Play()
				if snd and i <= 4 then task.delay(0.25, function() snd:Play() end) end
				task.wait(0.55)
			end
			TS:Create(bell, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = base}):Play()
			task.wait(2); ringing = false; pp.Enabled = true
		end)
	end)
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after church1") end)
if #missing > 0 then print("QQ CHURCH1 uncoloured: " .. table.concat(missing, ", ")) end
print(string.format("QQ CHURCH1 DONE: JapanMap.Church at (%d, %d) yaw %d - shell + interior, %d meshes, %d pew seats, %d door leaves (prompt), bell rope %s; no parts built but the invisible Seats", SITE_X, SITE_Z, SITE_YAW, meshes, nseat, #leaves, (bell and ropePart) and ("ready" .. (BELL_SOUND ~= "" and " with sound" or " (silent until BELL_SOUND is set)")) or "MISSING"))

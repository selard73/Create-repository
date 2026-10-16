-- church_install2.lua (runner 7, Oct 16 2026, solo): the Goto-islands church, built twice the first size (Shannon: "that church is too
-- small, the windows are too low and the door comes up to my knees, the roof must be much taller"), on site A behind the canal falls.
-- Kit Models (ServerStorage.JapanGardenKit) "church_shell" and "church_interior" from tools/japan/church/out3 (gen_church.py r3: S = 2,
-- mirrored so the tower stands on the east front corner and Fuji shows from the garden bridge, the arches cut properly, the floor above the plinth).
-- * placed by bounding box: the import may turn a model half round, so each one's turn is DETECTED (the shell's door / the interior's
--   altar against its box centre) and undone; the door faces +z (north, toward the canal and the garden bridge)
-- * dressed (colours, Wood / Slate / Glass / Marble / Neon), precise collision on the walls, floor, pews and door leaves
-- * 30 Seats on the 10 pews (three each), facing the altar
-- * the doors: a "Open the door" prompt at the doorway; the two leaves swing 100 degrees inward about their outer edges and close again
--   after 12 s - done by a SERVER SCRIPT left in the church (JapanMap.Church.ChurchScript), so it works in live servers too
-- * the bell: a "Ring the bell" prompt by the tower's inner door; the bell swings; it tolls only when the church folder's BellSound
--   attribute holds a sound id (empty = silent)
-- Re-runnable (the previous JapanMap.Church goes to HudBackup.Church_prev). Studio EDIT on Shannon's word; a play-test preview first.
-- Output "QQ CHURCH2".
local SITE_X, SITE_Z, GROUND_Y = 6115, -280.8, 0   -- the nave centre at ground level: the steps' front edge lands at z -246 (7 clear of the
                                                    -- falls' rocks at -239), the back wall at about -313; x 6115 keeps the west eave (6096)
                                                    -- clear of the vermilion maple at (6080, -294)
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
if not (KIT and J) then print("QQ CHURCH2 ABORT: ServerStorage.JapanGardenKit or workspace.JapanMap missing") return end
for _, n in ipairs({"church_shell", "church_interior"}) do
	if not KIT:FindFirstChild(n) then print("QQ CHURCH2 ABORT: the kit has no Model '" .. n .. "'") return end
end
local BB = {   -- each model's box in Roblox axes from its Blender origin (out2/pieces.json): the door at +z, the altar at -z
	church_shell = {min = Vector3.new(-18.894, 0.0, -32.6), max = Vector3.new(18.894, 50.2, 34.8)},
	church_interior = {min = Vector3.new(-14.8, 1.86, -28.8), max = Vector3.new(14.8, 29.8, 28.8)}
}
local SEATS = {   -- the seat tops (out2/pieces.json), each pew 10 wide
	{-7.6, 4.0, 20.24}, {-7.6, 4.0, 14.04}, {-7.6, 4.0, 7.84}, {-7.6, 4.0, 1.64}, {-7.6, 4.0, -4.56},
	{7.6, 4.0, 20.24}, {7.6, 4.0, 14.04}, {7.6, 4.0, 7.84}, {7.6, 4.0, 1.64}, {7.6, 4.0, -4.56}
}
local BELL_PROMPT = Vector3.new(6.6, 4.9, 25.6)   -- (out3: the church mirrored - the tower on the east front corner)   -- in the nave, by the tower's inner door (the rope hangs inside the tower)
local COL = {
	Church_Plaster = Color3.new(0.93, 0.91, 0.85), Church_Timber = Color3.new(0.24, 0.17, 0.12), Church_Stone = Color3.new(0.58, 0.57, 0.54),
	Church_Roof = Color3.new(0.3, 0.33, 0.38), Church_Ridge = Color3.new(0.24, 0.26, 0.3), Church_Door_L = Color3.new(0.4, 0.26, 0.15),
	Church_Door_R = Color3.new(0.4, 0.26, 0.15), Church_Door_L_Trim = Color3.new(0.24, 0.17, 0.12), Church_Door_R_Trim = Color3.new(0.24, 0.17, 0.12),
	Church_Glass_Blue = Color3.new(0.55, 0.72, 0.92), Church_Glass_Gold = Color3.new(0.95, 0.72, 0.3), Church_Glass_Red = Color3.new(0.8, 0.22, 0.24),
	Church_Cross = Color3.new(0.55, 0.42, 0.22), Church_Cross_Altar = Color3.new(0.55, 0.42, 0.22), Church_Bell = Color3.new(0.62, 0.48, 0.24),
	Church_Louvre = Color3.new(0.3, 0.22, 0.15), Church_Floor = Color3.new(0.45, 0.31, 0.19), Church_Pew = Color3.new(0.46, 0.3, 0.17),
	Church_Altar = Color3.new(0.92, 0.9, 0.86), Church_Cloth = Color3.new(0.75, 0.16, 0.18), Church_Candle = Color3.new(0.97, 0.95, 0.88),
	Church_Flame = Color3.new(1.0, 0.8, 0.35), Church_Rope = Color3.new(0.72, 0.62, 0.45)
}
local PRECISE = {Church_Plaster = true, Church_Stone = true, Church_Floor = true, Church_Pew = true, Church_Timber = true, Church_Roof = true,
	Church_Door_L = true, Church_Door_R = true}
local NOCOLLIDE = {Church_Flame = true, Church_Rope = true, Church_Door_L_Trim = true, Church_Door_R_Trim = true, Church_Cloth = true}
local TARGET = CFrame.new(SITE_X, GROUND_Y, SITE_Z)   -- the church's own frame: +z = the door side
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local old = J:FindFirstChild("Church")
if old then local prev = hb:FindFirstChild("Church_prev"); if prev then prev:Destroy() end; old.Name = "Church_prev"; old.Parent = hb end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before church2") end)
local G = Instance.new("Folder"); G.Name = "Church"
G:SetAttribute("BellSound", "")   -- a toll sound id (rbxassetid://...) when Shannon picks one
local fidelityFailed, missing = 0, {}
local function keyOf(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, key) for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") and keyOf(p) == key then return p end end end
local function place(kitName, label, markerKey, markerSign)
	local m = KIT[kitName]:Clone(); m.Name = label
	local box = BB[kitName]
	local centreLocal = (box.min + box.max) / 2
	local cf = m:GetBoundingBox()
	local marker = find(m, markerKey)
	-- the marker (door +z / altar -z) tells which way the import left the model
	local flipped = marker and ((marker.Position.Z - cf.Position.Z) * markerSign < 0) or false
	local R = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
	m.WorldPivot = CFrame.new(cf.Position - R:VectorToWorldSpace(centreLocal)) * R
	m:PivotTo(TARGET)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local key = keyOf(p)
			p.Anchored = true; p.CastShadow = true; p.Material = Enum.Material.SmoothPlastic
			if COL[key] then p.Color = COL[key] else table.insert(missing, p.Name) end
			p.CanCollide = not NOCOLLIDE[key]; p.CanQuery = p.CanCollide or key == "Church_Rope"; p.CanTouch = false
			if p:IsA("MeshPart") and PRECISE[key] then
				local ok = pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end)
				if not ok then fidelityFailed += 1 end
			end
			if key == "Church_Timber" or key == "Church_Pew" or key == "Church_Floor" or key:sub(1, 11) == "Church_Door" or key == "Church_Louvre" then p.Material = Enum.Material.Wood
			elseif key == "Church_Stone" or key == "Church_Roof" or key == "Church_Ridge" then p.Material = Enum.Material.Slate
			elseif key == "Church_Altar" then p.Material = Enum.Material.Marble
			elseif key == "Church_Cloth" then p.Material = Enum.Material.Fabric
			elseif key == "Church_Bell" or key == "Church_Cross" or key == "Church_Cross_Altar" then p.Material = Enum.Material.Metal
			elseif key:sub(1, 12) == "Church_Glass" then p.Material = Enum.Material.Glass; p.Transparency = 0.3; p.CastShadow = false
			elseif key == "Church_Flame" then
				p.Material = Enum.Material.Neon; p.CastShadow = false
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 200, 130); l.Range = 14; l.Brightness = 0.9; l.Shadows = false; l.Parent = p
			end
		end
	end
	m.Parent = G
	return m, flipped
end
local shell, flipS = place("church_shell", "Shell", "Church_Door_R", 1)
local interior, flipI = place("church_interior", "Interior", "Church_Altar", -1)
-- the door leaves: each swings about its OUTER vertical edge (the side away from the doorway's centre line), inward (toward -z)
local leaves = 0
for _, pair in ipairs({{"Church_Door_L", "Church_Door_L_Trim"}, {"Church_Door_R", "Church_Door_R_Trim"}}) do
	local door, trim = find(shell, pair[1]), find(shell, pair[2])
	if door then
		local loc = TARGET:PointToObjectSpace(door.Position)
		local side = loc.X < 0 and -1 or 1                                  -- which half of the doorway this leaf fills
		local hinge = TARGET * CFrame.new(loc.X + side * door.Size.X / 2, loc.Y, loc.Z)
		local swing = side < 0 and 100 or -100                              -- (+ turns local +x toward -z: the left leaf's free edge goes in)
		for _, p in ipairs({door, trim}) do
			if p then p:SetAttribute("Hinge", hinge); p:SetAttribute("ClosedCF", p.CFrame); p:SetAttribute("Swing", swing) end
		end
		leaves += 1
	end
end
-- the prompts on small invisible markers
local function marker(name, posLocal)
	local p = Instance.new("Part"); p.Name = name; p.Size = Vector3.new(1, 1, 1); p.Transparency = 1; p.Anchored = true
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CFrame = TARGET * CFrame.new(posLocal); p.Parent = G
	return p
end
local doorL = find(shell, "Church_Door_L")
local doorZ = doorL and TARGET:PointToObjectSpace(doorL.Position).Z or 30
local dp = marker("DoorPromptPoint", Vector3.new(0, 4.5, doorZ))
local pp = Instance.new("ProximityPrompt"); pp.Name = "DoorPrompt"; pp.ActionText = "Open the door"; pp.ObjectText = "Church"
pp.KeyboardKeyCode = Enum.KeyCode.E; pp.MaxActivationDistance = 10; pp.RequiresLineOfSight = false; pp.HoldDuration = 0; pp.Parent = dp
local bp = marker("BellPromptPoint", BELL_PROMPT)
local bpp = Instance.new("ProximityPrompt"); bpp.Name = "BellPrompt"; bpp.ActionText = "Ring the bell"; bpp.ObjectText = "Church bell"
bpp.KeyboardKeyCode = Enum.KeyCode.E; bpp.MaxActivationDistance = 8; bpp.RequiresLineOfSight = false; bpp.HoldDuration = 0; bpp.Parent = bp
-- the seats: three per pew, facing the altar (-z)
local SF = Instance.new("Folder"); SF.Name = "Seats"; SF.Parent = G
local nseat = 0
for _, s in ipairs(SEATS) do
	for k = -1, 1 do
		local seat = Instance.new("Seat"); seat.Name = "PewSeat"; seat.Size = Vector3.new(2.4, 0.3, 1.6); seat.Transparency = 1
		seat.Anchored = true; seat.CanCollide = false; seat.CanQuery = false; seat.CanTouch = true
		seat.CFrame = TARGET * CFrame.new(s[1] + k * 3.2, s[2] - 0.15, s[3]); seat.Parent = SF; nseat += 1
	end
end
-- the server script for the doors and the bell (lives in the church, runs in live servers)
local sc = Instance.new("Script"); sc.Name = "ChurchScript"
sc.Source = [==[
-- ChurchScript (installed by church_install2.lua): the church doors and the bell. Server only; never touches a DataStore.
local TS = game:GetService("TweenService")
local F = script.Parent
local leaves = {}
for _, p in ipairs(F:GetDescendants()) do
	if p:IsA("BasePart") and p:GetAttribute("Hinge") then
		local h = p:GetAttribute("Hinge")
		table.insert(leaves, {p = p, h = h, rel = h:ToObjectSpace(p:GetAttribute("ClosedCF")), swing = p:GetAttribute("Swing") or 100})
	end
end
local doorPrompt = F:FindFirstChild("DoorPrompt", true)
local open, busy, token = false, false, 0
local function set(o)
	open = o
	for _, l in ipairs(leaves) do
		local goal = l.h * CFrame.Angles(0, o and math.rad(l.swing) or 0, 0) * l.rel
		if o and l.p.CanCollide ~= nil and l.p.Name:find("Trim") == nil then l.p.CanCollide = false end
		local tw = TS:Create(l.p, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = goal}); tw:Play()
		if not o and l.p.Name:find("Trim") == nil then tw.Completed:Once(function() if not open then l.p.CanCollide = true end end) end
	end
	if doorPrompt then doorPrompt.ActionText = o and "Close the door" or "Open the door" end
end
if doorPrompt then
	doorPrompt.Triggered:Connect(function()
		if busy then return end
		busy = true; token += 1; local my = token
		set(not open)
		task.delay(1.2, function() busy = false end)
		if open then task.delay(12, function() if open and token == my then set(false) end end) end
	end)
end
local bell = nil
for _, p in ipairs(F:GetDescendants()) do if p:IsA("BasePart") and p.Name:gsub("%.%d+$", "") == "Church_Bell" then bell = p end end
local bellPrompt = F:FindFirstChild("BellPrompt", true)
local ringing = false
if bell and bellPrompt then
	local rest = bell.CFrame
	local top = rest * CFrame.new(0, bell.Size.Y / 2, 0)
	local rel = top:ToObjectSpace(rest)
	bellPrompt.Triggered:Connect(function()
		if ringing then return end
		ringing = true
		local id = F:GetAttribute("BellSound")
		if type(id) == "string" and id ~= "" then
			local s = Instance.new("Sound"); s.SoundId = id; s.Volume = 0.8; s.RollOffMaxDistance = 400; s.Parent = bell; s:Play()
			game:GetService("Debris"):AddItem(s, 12)
		end
		for _, a in ipairs({22, -18, 14, -10, 6, 0}) do
			local tw = TS:Create(bell, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = top * CFrame.Angles(math.rad(a), 0, 0) * rel})
			tw:Play(); tw.Completed:Wait()
		end
		ringing = false
	end)
end
]==]
sc.Parent = G
G.Parent = J
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after church2") end)
local cf, size = shell:GetBoundingBox()
print(string.format("QQ CHURCH2 placed: shell %s, interior %s (the import's half turn undone); shell box (%.1f, %.1f, %.1f) %.1f x %.1f x %.1f, z %.1f..%.1f",
	flipS and "turned back" or "as imported", flipI and "turned back" or "as imported", cf.X, cf.Y, cf.Z, size.X, size.Y, size.Z, cf.Z - size.Z / 2, cf.Z + size.Z / 2))
if #missing > 0 then print("QQ CHURCH2 uncoloured: " .. table.concat(missing, ", ")) end
if fidelityFailed > 0 then print(string.format("QQ CHURCH2 precise collision NOT set on %d parts (a play test cannot set it; Edit can)", fidelityFailed)) end
print(string.format("QQ CHURCH2 DONE: JapanMap.Church at (%.0f, %.1f) door north - %d door leaves, %d pew seats, bell %s; ChurchScript runs the doors and the bell", SITE_X, SITE_Z, leaves, nseat, "silent until BellSound is set"))

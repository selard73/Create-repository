-- camera/vrzoom_patch: EDIT mode. Second camera patch, Oct 9 2026 (Shannon: VR "does not allow to zoom out or zoom in ...
-- make the right controller stick for zoom"; photos "only picking up certain things ... not the whale or the ocean ... not
-- the beach"). Patches workspace.PhotoGame.CameraClient.Source with exact string finds: right stick up/down zooms the VR
-- shot (14..70 degrees, 50 = before) with a floating square viewfinder sized to the shot; photos gather parts from a box
-- along the line of sight (far subjects like the whale were falling between the old spheres), stand-in ground and sea tiles
-- coloured like the terrain, and the whale itself is always in a whale photo. Desktop / phone photos get the tiles and the
-- box too; nothing else changes there. Refuses to run unless the Source is the job 6 text (60574 chars) and every find
-- hits exactly once. Original -> ServerStorage.HudBackup.CameraClient_v3_pre_vrzoom. Output: "QQ VRZ".
if game:GetService("RunService"):IsRunning() then warn("QQ VRZ ABORT - Play mode") return end
local G = workspace:FindFirstChild("PhotoGame")
local S = G and G:FindFirstChild("CameraClient")
if not (S and S:IsA("LuaSourceContainer")) then warn("QQ VRZ ABORT - workspace.PhotoGame.CameraClient not found") return end
local src = S.Source
if #src ~= 60574 then warn("QQ VRZ ABORT - CameraClient.Source is " .. #src .. " chars, expected 60574 (job 6 not applied, or already patched)") return end
local PAIRS = {
	{[==[
local holding, raised = false, false
]==],
	[==[
local holding, raised = false, false
local vrFov = 50   -- VR zoom (Oct 9): the shot's field of view, right stick up/down; 50 was the fixed value before
]==]},
	{[==[
		return ang < 22, ang / 22
]==],
	[==[
		local lim = vrFov * 0.44
		return ang < lim, ang / lim
]==]},
	{[==[
local function buildWorld(cf, fov, extra, ignore)
	local world = Instance.new("WorldModel"); world.Name = "Scene"
	local look = cf.LookVector
	local params = OverlapParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {workspace.CurrentCamera}
	if player.Character then table.insert(ex, player.Character) end
	for _, x in ipairs(ignore or {}) do table.insert(ex, x) end
	params.FilterDescendantsInstances = ex
	local cosLim = math.cos(math.rad(math.min(80, fov * 0.9)))
	local list = {}
	for _, ring in ipairs({{30, 32}, {95, 70}, {200, 110}}) do
		for _, p in ipairs(workspace:GetPartBoundsInRadius(cf.Position + look * ring[1], ring[2], params)) do
			if not list[p] and p.Transparency < 0.95 then
				local d = p.Position - cf.Position
				local dist = d.Magnitude
				if dist < 320 and (dist < p.Size.Magnitude * 0.6 or look:Dot(d.Unit) > cosLim) then list[p] = dist end
			end
		end
	end
	local arr = {}
	for p, d in pairs(list) do table.insert(arr, {p, d}) end
	table.sort(arr, function(a, b) return a[2] < b[2] end)
	for i = 1, math.min(600, #arr) do local c = stripCopy(arr[i][1]); if c then c.Parent = world end end
	if extra then pcall(extra, world) end
	return world, #arr
end
]==],
	[==[
-- terrain can't be copied into a scene, so the ground and the sea in the shot are stood in for by flat tiles coloured
-- and textured like the terrain under them (Oct 9, Shannon: "the whale picture only got the water spray, not the whale
-- or the ocean; the treasure hunter got the squirrel but not the beach or water or anything around him").
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Include
tparams.FilterDescendantsInstances = {workspace.Terrain}; tparams.IgnoreWater = false
local PART_MAT = {Sand = Enum.Material.Sand, Grass = Enum.Material.Grass, LeafyGrass = Enum.Material.Grass, Rock = Enum.Material.Slate,
	Slate = Enum.Material.Slate, Ground = Enum.Material.Ground, Mud = Enum.Material.Ground, Cobblestone = Enum.Material.Cobblestone,
	Limestone = Enum.Material.Limestone, Pavement = Enum.Material.Pavement, Basalt = Enum.Material.Basalt, Sandstone = Enum.Material.Sandstone,
	Snow = Enum.Material.Snow, Ice = Enum.Material.Ice, Salt = Enum.Material.Salt, Asphalt = Enum.Material.Asphalt, Concrete = Enum.Material.Concrete,
	Brick = Enum.Material.Brick, WoodPlanks = Enum.Material.WoodPlanks, CrackedLava = Enum.Material.CrackedLava, Glacier = Enum.Material.Glacier}
local function terrainTiles(world, cf, fov)
	local T = workspace.Terrain
	if not T then return end
	local look, right = cf.LookVector, cf.RightVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local side = Vector3.new(right.X, 0, right.Z)
	if flat.Magnitude < 0.05 or side.Magnitude < 0.05 then return end
	flat, side = flat.Unit, side.Unit
	local half = math.tan(math.rad(math.min(fov, 80) / 2)) * 1.25
	local r, n = 3, 0
	while r < 300 and n < 240 do
		local stepR = math.max(2.5, r * 0.28)
		local width = r * half * 2 + 6
		local across = math.clamp(math.ceil(width / stepR), 3, 13)
		local sp = width / across
		for k = 0, across - 1 do
			local x = cf.Position + flat * r + side * ((k - (across - 1) / 2) * sp)
			local hit = workspace:Raycast(Vector3.new(x.X, cf.Y + 60, x.Z), Vector3.new(0, -260, 0), tparams)
			if hit then
				local mat = hit.Material
				local t = Instance.new("Part"); t.Anchored = true; t.CanCollide = false; t.CastShadow = false
				t.Size = Vector3.new(sp * 1.08, 0.3, stepR * 1.12)
				local at = hit.Position - Vector3.new(0, 0.15, 0)
				t.CFrame = CFrame.lookAt(at, at + flat)
				if mat == Enum.Material.Water then
					t.Color = T.WaterColor; t.Material = Enum.Material.Glass; t.Transparency = 0.15; t.Reflectance = 0.1
				else
					local okc, col = pcall(T.GetMaterialColor, T, mat)
					t.Color = okc and col or C(150, 140, 120); t.Material = PART_MAT[mat.Name] or Enum.Material.SmoothPlastic
				end
				t.Parent = world
				n += 1
			end
		end
		r += stepR
	end
end
local function buildWorld(cf, fov, extra, ignore)
	local world = Instance.new("WorldModel"); world.Name = "Scene"
	local look = cf.LookVector
	local params = OverlapParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.MaxParts = 4000
	local ex = {workspace.CurrentCamera, workspace.Terrain}
	if player.Character then table.insert(ex, player.Character) end
	for _, x in ipairs(ignore or {}) do table.insert(ex, x) end
	params.FilterDescendantsInstances = ex
	local cosLim = math.cos(math.rad(math.min(80, fov * 0.9)))
	local list = {}
	-- everything in a box along the line of sight (0..320 studs, as wide as the field of view needs), then the ones in the cone
	local half = math.tan(math.rad(math.min(fov, 80) / 2))
	local boxCF = CFrame.lookAt(cf.Position, cf.Position + look) * CFrame.new(0, 0, -160)
	local boxSize = Vector3.new(math.min(640, 320 * half * 2 + 40), math.min(400, 320 * half * 2 + 40), 320)
	for _, p in ipairs(workspace:GetPartBoundsInBox(boxCF, boxSize, params)) do
		if not list[p] and p.Transparency < 0.95 then
			local d = p.Position - cf.Position
			local dist = d.Magnitude
			if dist < 320 and (dist < p.Size.Magnitude * 0.6 or look:Dot(d.Unit) > cosLim) then list[p] = dist end
		end
	end
	local arr = {}
	for p, d in pairs(list) do table.insert(arr, {p, d}) end
	table.sort(arr, function(a, b) return a[2] < b[2] end)
	for i = 1, math.min(600, #arr) do local c = stripCopy(arr[i][1]); if c then c.Parent = world end end
	pcall(terrainTiles, world, cf, fov)
	if extra then pcall(extra, world, list) end
	return world, #arr
end
]==]},
	{[==[
		extra = function(world) local _, mesh = whaleMesh(); spoutBalls(world, whaleSpoutBase(mesh)) end
]==],
	[==[
		extra = function(world, list)
			local _, mesh = whaleMesh()
			if mesh and not (list and list[mesh]) then local c = stripCopy(mesh); if c then c.Parent = world end end
			spoutBalls(world, whaleSpoutBase(mesh))
		end
]==]},
	{[==[
	local camFov = vr() and 50 or workspace.CurrentCamera.FieldOfView
]==],
	[==[
	local camFov = vr() and vrFov or workspace.CurrentCamera.FieldOfView
]==]},
	{[==[
local aimParams = RaycastParams.new(); aimParams.FilterType = Enum.RaycastFilterType.Exclude
local function aimHit(cf)   -- where the controller points; invisible parts (boundary walls, prompt spots) are looked through
	local ex = {player.Character}
	local origin, left = cf.Position, 80
	for _ = 1, 5 do
		aimParams.FilterDescendantsInstances = ex
		local hit = workspace:Raycast(origin, cf.LookVector * left, aimParams)
		if not hit then return nil end
		if hit.Instance == workspace.Terrain or hit.Instance.Transparency < 1 then return hit.Position end
		table.insert(ex, hit.Instance)
		left -= (hit.Position - origin).Magnitude; origin = hit.Position
		if left <= 0 then return nil end
	end
	return nil
end
RunService.RenderStepped:Connect(function()
	if raised then hideHeld(true) end
	local on = holding and vr()
	aim.Enabled = on
	if on then
		local cf = shotCF()
		handAtt.WorldPosition = cf.Position
		aimAtt.WorldPosition = aimHit(cf) or (cf.Position + cf.LookVector * 40)
		beam.Enabled = vrHandCF() ~= nil
		if os.clock() - aimCheckAt > 0.05 then
			aimCheckAt = os.clock()
			local ok, s = pcall(evaluate, cf)
			local locked = ok and s ~= nil and (player:GetAttribute("Item_photo_" .. s.id) or 0) < 1
			if locked ~= aimLocked then aimLocked = locked; setRing(locked) end
		end
	else
		beam.Enabled = false
		if aimLocked then aimLocked = false; setRing(false) end
	end
end)
]==],
	[==[
local aimParams = RaycastParams.new(); aimParams.FilterType = Enum.RaycastFilterType.Exclude
local function aimHit(cf)   -- where the controller points; invisible parts (boundary walls, prompt spots) are looked through
	local ex = {player.Character}
	local origin, left = cf.Position, 80
	for _ = 1, 5 do
		aimParams.FilterDescendantsInstances = ex
		local hit = workspace:Raycast(origin, cf.LookVector * left, aimParams)
		if not hit then return nil end
		if hit.Instance == workspace.Terrain or hit.Instance.Transparency < 1 then return hit.Position end
		table.insert(ex, hit.Instance)
		left -= (hit.Position - origin).Magnitude; origin = hit.Position
		if left <= 0 then return nil end
	end
	return nil
end
-- the frame of the shot, floating at the aim point: a square as wide as the photo will be at that distance (Oct 9)
local frame = Instance.new("BillboardGui"); frame.Name = "CameraFrame"; frame.AlwaysOnTop = true; frame.LightInfluence = 0; frame.ResetOnSpawn = false
frame.Adornee = aimAtt; frame.Enabled = false; frame.Size = UDim2.fromScale(4, 4); frame.Parent = pg
local frameBox = Instance.new("Frame"); frameBox.Size = UDim2.fromScale(1, 1); frameBox.BackgroundTransparency = 1; frameBox.Parent = frame
local frameStroke = stroke(frameBox, GOLD, 2); frameStroke.Transparency = 0.25
-- right stick up / down = zoom in / out (Shannon, Oct 9); left / right stays Roblox's snap turn
local stickY, zoomSaidAt = 0, 0
UIS.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2 then stickY = input.Position.Y end
end)
RunService.RenderStepped:Connect(function(dt)
	if raised then hideHeld(true) end
	local on = holding and vr()
	aim.Enabled = on; frame.Enabled = on
	if on then
		if math.abs(stickY) > 0.25 then
			local f = math.clamp(vrFov - stickY * dt * 40, 14, 70)
			if f ~= vrFov then
				vrFov = f
				if os.clock() - zoomSaidAt > 0.3 then zoomSaidAt = os.clock(); toast(string.format("Zoom %.1fx", 50 / vrFov), 1.5) end
			end
		end
		local cf = shotCF()
		handAtt.WorldPosition = cf.Position
		local at = aimHit(cf) or (cf.Position + cf.LookVector * 40)
		aimAtt.WorldPosition = at
		local w = 2 * (at - cf.Position).Magnitude * math.tan(math.rad(vrFov) / 2) * 0.9
		frame.Size = UDim2.fromScale(w, w)
		beam.Enabled = vrHandCF() ~= nil
		if os.clock() - aimCheckAt > 0.05 then
			aimCheckAt = os.clock()
			local ok, s = pcall(evaluate, cf)
			local locked = ok and s ~= nil and (player:GetAttribute("Item_photo_" .. s.id) or 0) < 1
			if locked ~= aimLocked then aimLocked = locked; setRing(locked) end
		end
	else
		beam.Enabled = false
		if aimLocked then aimLocked = false; setRing(false) end
	end
end)
]==]},
}
for i, p in ipairs(PAIRS) do
	local a, b = src:find(p[1], 1, true)
	if not a then warn("QQ VRZ ABORT - find " .. i .. " not found; nothing changed") return end
	if src:find(p[1], b + 1, true) then warn("QQ VRZ ABORT - find " .. i .. " matches more than once; nothing changed") return end
end
local out = src
for i, p in ipairs(PAIRS) do
	local a, b = out:find(p[1], 1, true)
	out = out:sub(1, a - 1) .. p[2] .. out:sub(b + 1)
end
local f, err = loadstring(out)
if not f then warn("QQ VRZ ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup")
if not hb then hb = Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS end
if not hb:FindFirstChild("CameraClient_v3_pre_vrzoom") then
	local bk = S:Clone(); bk.Name = "CameraClient_v3_pre_vrzoom"
	pcall(function() bk.Enabled = false end)
	bk.Parent = hb
end
S.Source = out
print(string.format("QQ VRZ DONE: CameraClient patched, %d -> %d chars, %d finds, backup ServerStorage.HudBackup.CameraClient_v3_pre_vrzoom", #src, #out, #PAIRS))

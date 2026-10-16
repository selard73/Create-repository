-- planting3.lua (runner 7, Oct 16 2026, solo): the railway-side irises SCATTERED. Shannon on planting2's preview: "the irises are pretty but
-- they should be scattered definitely not in a line like they were planted, more like they just sprung up, and they might be a tad big".
-- 1. retires the old part-built irises ("Blue iris" / "Iris stem" in JapanMap.Landscape) to ServerStorage.HudBackup.IrisReplaced and a
--    previous JapanMap.MomijiPlanting to HudBackup.MomijiPlanting_prev
-- 2. places iris clumps (the kit's "iris_card": two crossed quads with the iris picture) in loose DRIFTS of 1-6 across the lawn between the
--    walkway and the railway (x 5440..6560, z 116..166): each spot checked by a raycast - it must land on the grass floor at y ~0 with nothing
--    above it (no paths, lanterns, buildings, trees' trunks), and keep 1.2 from the other clumps. Sizes 1.4-2.1, random yaw. The picture
--    goes through a SurfaceAppearance with AlphaMode Transparency (a plain TextureID drew its clear background black).
-- Re-runnable (seeded: the same layout each run). Output "QQ PLANTING3".
local SEED, DRIFTS, X0, X1, Z0, Z1 = 20261016, 34, 5440, 6560, 116, 166
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
if not (KIT and J) then print("QQ PLANTING3 ABORT: ServerStorage.JapanGardenKit or workspace.JapanMap missing") return end
local CARD = KIT:FindFirstChild("iris_card")
local cardMesh = CARD and (CARD:IsA("MeshPart") and CARD or CARD:FindFirstChildWhichIsA("MeshPart", true))
if not cardMesh then print("QQ PLANTING3 ABORT: the kit has no 'iris_card' MeshPart - import japan_iris_card.fbx") return end
local IMAGE = cardMesh.TextureID
local saOld = cardMesh:FindFirstChildOfClass("SurfaceAppearance")
if IMAGE == "" and saOld then IMAGE = saOld.ColorMap end
if IMAGE == "" then print("QQ PLANTING3 ABORT: the kit's iris_card has no picture") return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("IrisReplaced") or Instance.new("Folder"); bak.Name = "IrisReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before planting3") end)
local retired = 0
local land = J:FindFirstChild("Landscape")
if land then
	for _, d in ipairs(land:GetChildren()) do
		if d:IsA("BasePart") and (d.Name == "Blue iris" or d.Name == "Iris stem") then d:SetAttribute("IrisWasIn", land:GetFullName()); d.Parent = bak; retired += 1 end
	end
end
local old = J:FindFirstChild("MomijiPlanting")
if old then local prev = hb:FindFirstChild("MomijiPlanting_prev"); if prev then prev:Destroy() end; old.Name = "MomijiPlanting_prev"; old.Parent = hb end
local P = Instance.new("Folder"); P.Name = "MomijiPlanting"
local rnd = Random.new(SEED)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {P}
local placed = {}
local function free(x, z)
	local r = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -90, 0), rp)
	if not (r and r.Instance.Name == "Japan land foundation basin cut" and math.abs(r.Position.Y) < 0.15) then return false end
	for _, q in ipairs(placed) do if (q - Vector3.new(x, 0, z)).Magnitude < 1.2 then return false end end
	-- a little room around it: four short rays must land on the grass too (keeps it off path edges and plinths)
	for _, o in ipairs({Vector3.new(0.9, 0, 0), Vector3.new(-0.9, 0, 0), Vector3.new(0, 0, 0.9), Vector3.new(0, 0, -0.9)}) do
		local r2 = workspace:Raycast(Vector3.new(x, 60, z) + o, Vector3.new(0, -90, 0), rp)
		if not (r2 and r2.Instance.Name == "Japan land foundation basin cut") then return false end
	end
	return true
end
local made = 0
local function plant(x, z)
	local s = rnd:NextNumber(1.4, 2.1)
	local p = cardMesh:Clone(); p.Name = "IrisClump"
	p.Size = Vector3.new(s, s, s)
	p.CFrame = CFrame.new(x, s / 2 - 0.08, z) * CFrame.Angles(0, rnd:NextNumber(0, math.pi * 2), 0)
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Color = Color3.new(1, 1, 1); p.Material = Enum.Material.SmoothPlastic; p.Transparency = 0
	pcall(function() p.DoubleSided = true end)
	for _, o in ipairs(p:GetChildren()) do if o:IsA("SurfaceAppearance") then o:Destroy() end end
	local sa = Instance.new("SurfaceAppearance"); sa.AlphaMode = Enum.AlphaMode.Transparency; sa.ColorMap = IMAGE; sa.Parent = p
	p.TextureID = ""
	p.Parent = P
	table.insert(placed, Vector3.new(x, 0, z)); made += 1
end
local drifts, singles = 0, 0
for d = 1, DRIFTS do
	-- a drift: a centre somewhere in the band (spread along x so they don't bunch), then 1-6 clumps around it, closer near the middle
	local cx = X0 + (X1 - X0) * (d - 1 + rnd:NextNumber(0.1, 0.9)) / DRIFTS
	local cz = rnd:NextNumber(Z0 + 3, Z1 - 3)
	local n = ({1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 6})[rnd:NextInteger(1, 11)]
	local got = 0
	for k = 1, n * 6 do
		if got >= n then break end
		-- a loose cloud, not a ring (points on a ring read as a planted row): Gaussian offsets, the drift a little longer one way
		local sig = 1.2 + n * 0.45
		local g1 = math.sqrt(-2 * math.log(math.max(rnd:NextNumber(), 1e-6))) * math.cos(2 * math.pi * rnd:NextNumber())
		local g2 = math.sqrt(-2 * math.log(math.max(rnd:NextNumber(), 1e-6))) * math.cos(2 * math.pi * rnd:NextNumber())
		local x, z = cx + ((got == 0) and 0 or g1 * sig * 1.3), cz + ((got == 0) and 0 or g2 * sig * 0.8)
		if z > Z0 and z < Z1 and free(x, z) then plant(x, z); got += 1 end
		if got == 0 and k > 4 then cx = cx + rnd:NextNumber(-6, 6); cz = rnd:NextNumber(Z0 + 3, Z1 - 3) end
	end
	if got == 1 then singles += 1 elseif got > 1 then drifts += 1 end
	if d % 8 == 0 then task.wait() end
end
P.Parent = J
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after planting3") end)
print(string.format("QQ PLANTING3 retired %d old iris parts -> HudBackup.IrisReplaced", retired))
print(string.format("QQ PLANTING3 DONE: JapanMap.MomijiPlanting - %d iris clumps in %d drifts + %d single ones (x %d..%d, z %d..%d, 1.4-2.1 tall, %s); no parts built",
	made, drifts, singles, X0, X1, Z0, Z1, IMAGE))

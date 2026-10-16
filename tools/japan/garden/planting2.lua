-- planting2.lua (job 125): the railway strip's blue irises -> flower CARDS with the rendered iris picture (a play-test PREVIEW first;
-- Studio EDIT on her word; re-runnable). 1. finds the "Blue iris" / "Iris stem" parts in JapanMap.Landscape (or the retired ones in
-- HudBackup.IrisReplaced on a re-run) and groups the blooms into clusters (three in a row 0.35 apart); 2. RETIRES all of them to
-- HudBackup.IrisReplaced (attribute IrisWasIn); 3. PLACES one "flower_card" MeshPart per cluster (the kit's crossed quads, TextureID =
-- IMAGE, DoubleSided, 2.2-3.0 studs, random yaw), its bottom in the lawn. Output "QQ PLANTING2".
local IMAGE = "rbxassetid://0"                                              -- <- the uploaded iris_card.png (image asset id). 0 = ABORT, so nothing is placed blank
local SIZE = 2.6                                                            -- the clump's height and width at scale 1 (the picture is square)
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
if not (KIT and J) then print("QQ PLANTING2 ABORT: ServerStorage.JapanGardenKit or workspace.JapanMap missing") return end
local CARD = KIT:FindFirstChild("iris_card") or KIT:FindFirstChild("flower_card")   -- (runner 7: "iris_card" = the card imported WITH its picture, japan_iris_card.fbx)
if not CARD then print("QQ PLANTING2 ABORT: the kit has no Model 'flower_card' - import tools/japan/garden/out_iris/flower_card.fbx") return end
local cardMesh = CARD:IsA("MeshPart") and CARD or CARD:FindFirstChildWhichIsA("MeshPart", true)
if not cardMesh then print("QQ PLANTING2 ABORT: 'flower_card' holds no MeshPart") return end
if IMAGE == "rbxassetid://0" and cardMesh.TextureID ~= "" then IMAGE = cardMesh.TextureID end   -- (the importer uploaded the picture and set this)
if IMAGE == "rbxassetid://0" then print("QQ PLANTING2 ABORT: no picture - import japan_iris_card.fbx (the card with its picture) or set IMAGE") return end
print("QQ PLANTING2 picture: " .. IMAGE)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("IrisReplaced") or Instance.new("Folder"); bak.Name = "IrisReplaced"; bak.Parent = hb
-- ---------- 1. the irises and their clusters ----------
local land = J:FindFirstChild("Landscape")
local blooms, stems = {}, {}
local function collect(folder)
	for _, d in ipairs(folder:GetChildren()) do
		if d:IsA("BasePart") then
			if d.Name == "Blue iris" then table.insert(blooms, d) elseif d.Name == "Iris stem" then table.insert(stems, d) end
		end
	end
end
if land then collect(land) end
local fromBackup = false
if #blooms == 0 then collect(bak); fromBackup = true end
if #blooms == 0 then print("QQ PLANTING2 ABORT: no 'Blue iris' parts in JapanMap.Landscape nor in HudBackup.IrisReplaced") return end
table.sort(blooms, function(a, b) if math.abs(a.Position.Z - b.Position.Z) > 0.3 then return a.Position.Z < b.Position.Z end return a.Position.X < b.Position.X end)
local clusters = {}
for _, b in ipairs(blooms) do
	local c = clusters[#clusters]
	if c and math.abs(b.Position.Z - c.z) < 0.3 and b.Position.X - c.lastX < 0.6 then
		c.n += 1; c.sx += b.Position.X; c.lastX = b.Position.X
	else
		table.insert(clusters, {n = 1, sx = b.Position.X, z = b.Position.Z, lastX = b.Position.X})
	end
end
print(string.format("QQ PLANTING2 found %d blooms + %d stems%s -> %d clusters, x %.0f .. %.0f", #blooms, #stems,
	fromBackup and " (from HudBackup.IrisReplaced, a re-run)" or " in JapanMap.Landscape", #clusters, blooms[1].Position.X, blooms[#blooms].Position.X))
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before planting2") end)
-- ---------- 2. retire them ----------
local retired = 0
if not fromBackup then
	for _, list in ipairs({blooms, stems}) do
		for _, d in ipairs(list) do d:SetAttribute("IrisWasIn", d.Parent:GetFullName()); d.Parent = bak; retired += 1 end
	end
end
print(string.format("QQ PLANTING2 retired %d iris parts -> HudBackup.IrisReplaced", retired))
-- ---------- 3. the cards ----------
local old = J:FindFirstChild("MomijiPlanting")
if old then local prev = hb:FindFirstChild("MomijiPlanting_prev"); if prev then prev:Destroy() end; old.Name = "MomijiPlanting_prev"; old.Parent = hb end
local G = Instance.new("Folder"); G.Name = "MomijiPlanting"; G.Parent = J
local rnd = Random.new(4242)
local made = 0
for i, c in ipairs(clusters) do
	local s = SIZE * rnd:NextNumber(0.85, 1.15)
	local p = cardMesh:Clone(); p.Name = "IrisClump" .. i
	p.Size = Vector3.new(s, s, s)                                          -- the unit quads: 1 wide, 1 tall, 1 across
	p.TextureID = IMAGE; p.Color = Color3.new(1, 1, 1); p.Material = Enum.Material.SmoothPlastic; p.Transparency = 0
	pcall(function() p.DoubleSided = true end)
	-- (runner 7) the picture through a SurfaceAppearance with AlphaMode Transparency: as a plain TextureID its clear background drew black
	for _, old in ipairs(p:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
	local sa = Instance.new("SurfaceAppearance"); sa.AlphaMode = Enum.AlphaMode.Transparency; sa.ColorMap = IMAGE; sa.Parent = p
	p.TextureID = ""
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.CFrame = CFrame.new(c.sx / c.n + rnd:NextNumber(-0.3, 0.3), s / 2 - 0.08, c.z + rnd:NextNumber(-0.3, 0.3)) * CFrame.Angles(0, math.rad(rnd:NextInteger(0, 359)), 0)
	p.Parent = G; made += 1
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after planting2") end)
print(string.format("QQ PLANTING2 DONE: JapanMap.MomijiPlanting - %d iris clumps (one DoubleSided card MeshPart each, %s) for %d clusters; no parts built", made, IMAGE, #clusters))

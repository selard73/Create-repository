-- moonbridgeend2.lua (runner 7, Oct 17 2026): the Vermilion moon bridge's two entrances at the palace pond, round 2. Round 1
-- (moonbridgeend1: white cut-stone landing, steps and cheek walls, lanterns in front) was never installed - Shannon: "that looks
-- really bad", "really really bad", "figure it out please". Round 2 keeps to the bridge's OWN look (kit "moon_bridge_end2",
-- gen_moonbridge_end2.py): the deck carries on down to the court as three wooden steps in the deck's planks, red side boards and the
-- red handrails run down to a pair of red posts at the foot, a red post at the deck end (the north end never had any), gold giboshi
-- finials (kit "post_finial") on all the posts; the only stone is dark grey and low: a footing under the deck end and a sill at the foot.
-- At both ends (found from the bridge's "Bridge deck" parts: the south end z ~-21.1, the north end z ~65.1), the piece is placed with
-- its deck-end edge at the deck end, on the court (3.10), turned to face outward. The two plain pond-set "Walkway" slabs go to
-- ServerStorage.HudBackup.MoonBridgeReplaced (attribute MoonBridgeWasIn). Re-runnable (MoonBridgeEnds is rebuilt). Output "QQ MOONBRIDGEEND2".
-- Undo: delete the pond set's MoonBridgeEnds folder; HudBackup.MoonBridgeReplaced's slabs back to their MoonBridgeWasIn.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local pond = J and J:FindFirstChild("PalaceGrounds") and J.PalaceGrounds:FindFirstChild("Koi pond set piece")
local br = pond and pond:FindFirstChild("Vermilion moon bridge")
local KIT = SS:FindFirstChild("JapanGardenKit")
-- everything this needs is found BEFORE anything changes
if not (pond and br and KIT) then print("QQ MOONBRIDGEEND2 ABORT: the pond set, its moon bridge or ServerStorage.JapanGardenKit missing") return end
local SRC, FIN = KIT:FindFirstChild("moon_bridge_end2"), KIT:FindFirstChild("post_finial")
if not SRC then print("QQ MOONBRIDGEEND2 ABORT: the kit has no 'moon_bridge_end2' - import japan_kit16_moonbridge_end2.fbx") return end
if not FIN then print("QQ MOONBRIDGEEND2 ABORT: the kit has no 'post_finial' (kit15)") return end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, name) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and key(d) == name then return d end end end
for _, n in ipairs({"MB2_Wood", "MB2_Red", "MB2_Stone"}) do if not find(SRC, n) then print("QQ MOONBRIDGEEND2 ABORT: the kit's moon_bridge_end2 has no " .. n) return end end
local function ext(p)
	local s, r = p.Size, p.CFrame
	local function e(ax) return math.abs(r.RightVector[ax]) * s.X + math.abs(r.UpVector[ax]) * s.Y + math.abs(r.LookVector[ax]) * s.Z end
	local h = Vector3.new(e("X"), e("Y"), e("Z")) / 2
	return p.Position - h, p.Position + h
end
local zS, zN, xs, nd = math.huge, -math.huge, 0, 0
for _, p in ipairs(br:GetDescendants()) do
	if p:IsA("BasePart") and key(p) == "Bridge deck" then
		local a, b = ext(p); zS = math.min(zS, a.Z); zN = math.max(zN, b.Z); xs += p.Position.X; nd += 1
	end
end
if nd == 0 then print("QQ MOONBRIDGEEND2 ABORT: no 'Bridge deck' parts in the moon bridge") return end
local CX, G = xs / nd, 3.10                                                                   -- the bridge's centre line; the court
local BB = {min = Vector3.new(-5.0, -0.3, -2.1), max = Vector3.new(5.0, 5.15, 5.4)}               -- out_moonbridge2/pieces.json (local: z outward)
local STEPS_Z = 2.1                                                                               -- the steps' middle (z 0..4.2): outward
local POSTS = {{4.3, 5.15, 0.0}, {-4.3, 5.15, 0.0}, {4.3, 3.3, 4.45}, {-4.3, 3.3, 4.45}}          -- (x, top, z) of the piece's four posts
local DECK = Color3.fromRGB(103, 72, 48)
local RED = Color3.fromRGB(179, 54, 31)
local STONE = Color3.fromRGB(87, 84, 82)
local GOLD = Color3.new(0.85, 0.66, 0.30)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("MoonBridgeReplaced") or Instance.new("Folder"); bak.Name = "MoonBridgeReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before moonbridgeend2") end)
local retired = 0
for _, w in ipairs(pond:GetChildren()) do
	if w:IsA("BasePart") and w.Name == "Walkway" then w:SetAttribute("MoonBridgeWasIn", w.Parent:GetFullName()); w.Parent = bak; retired += 1 end
end
local old = pond:FindFirstChild("MoonBridgeEnds"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "MoonBridgeEnds"
for _, p in ipairs(SRC:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
do	-- the kit's pivot at its local origin (the deck end, court level); the import's half turn detected by the steps (outward side)
	local cf = SRC:GetBoundingBox()
	local steps = find(SRC, "MB2_Wood")
	local centreLocal = (BB.min + BB.max) / 2
	local flipped = (steps.Position.Z - cf.Position.Z) * (STEPS_Z - centreLocal.Z) < 0
	local R = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
	SRC.WorldPivot = CFrame.new(cf.Position - R:VectorToWorldSpace(centreLocal)) * R
end
local placed, nfin = {}, 0
for _, e in ipairs({{"North", zN, 0}, {"South", zS, math.pi}}) do
	local base = CFrame.new(CX, G, e[2]) * CFrame.Angles(0, e[3], 0)
	local m = SRC:Clone(); m.Name = "MoonBridgeEnd" .. e[1]
	m:PivotTo(base)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p)
			p.Anchored = true; p.CanCollide = true; p.CanQuery = true; p.CanTouch = false; p.CastShadow = true
			if k == "MB2_Wood" then p.Material = Enum.Material.WoodPlanks; p.Color = DECK
			elseif k == "MB2_Red" then p.Material = Enum.Material.Wood; p.Color = RED
			else p.Material = Enum.Material.Slate; p.Color = STONE end
		end
	end
	m.Parent = F
	table.insert(placed, m)
	for _, q in ipairs(POSTS) do
		local f = FIN:Clone(); f.Name = "Finial"
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Material = Enum.Material.Metal; d.Color = GOLD end
		end
		pcall(function() f:ScaleTo(0.9) end)
		local fcf, fsz = f:GetBoundingBox()
		local top = base:PointToWorldSpace(Vector3.new(q[1], q[2], q[3]))
		f:PivotTo(f:GetPivot() + (top - Vector3.new(fcf.X, fcf.Y - fsz.Y / 2 + 0.02, fcf.Z)))
		f.Parent = F; nfin += 1
	end
end
F.Parent = pond
task.wait()
local nfid = 0
for _, m in ipairs(placed) do
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("MeshPart") and pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) and p.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition then nfid += 1 end
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after moonbridgeend2") end)
local s1, s2 = placed[1]:GetBoundingBox(), placed[2]:GetBoundingBox()
print(string.format("QQ MOONBRIDGEEND2 DONE: ends at the deck ends z %.2f / %.2f (x %.1f): North at (%.1f, %.2f, %.1f), South at (%.1f, %.2f, %.1f); %d finials; %d slabs -> HudBackup.MoonBridgeReplaced; precise collision on %d",
	zS, zN, CX, s1.X, s1.Y, s1.Z, s2.X, s2.Y, s2.Z, nfin, retired, nfid))

-- moonbridgeend3.lua (runner 7, Oct 17 2026): the Vermilion moon bridge's two ends at the palace pond, round 3. Rounds 1 (white stone
-- landing + steps, lanterns) and 2 (a straight wooden stair with its own posts) were never installed: "really really bad", then "still
-- got issues ... look at how other japanese bridges are designed, be smart please". Round 3 does what a taiko-bashi does: the arch
-- ITSELF runs on down to the court (kit "moon_bridge_end3", gen_moonbridge_end3.py: two more deck segments on the bridge's own curve,
-- 9 wide, 0.4 thick, WoodPlanks in the deck's colour), the curved red rails run with it to a pair of heavy end posts at the foot (the
-- only posts with gold giboshi - kit "post_finial"), and a dark fitted-stone abutment fills under the end of the arch, with a sill at
-- the foot. At both ends (found from the bridge's "Bridge deck" parts: south z ~-21.1, north z ~65.1) the piece is placed with its
-- start at the deck end, on the pond apron (3.19), turned to face outward. The two plain pond-set "Walkway" slabs go to
-- ServerStorage.HudBackup.MoonBridgeReplaced (attribute MoonBridgeWasIn). Re-runnable (MoonBridgeEnds is rebuilt). Output "QQ MOONBRIDGEEND3".
-- Undo: delete the pond set's MoonBridgeEnds folder; HudBackup.MoonBridgeReplaced's slabs back to their MoonBridgeWasIn.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local pond = J and J:FindFirstChild("PalaceGrounds") and J.PalaceGrounds:FindFirstChild("Koi pond set piece")
local br = pond and pond:FindFirstChild("Vermilion moon bridge")
local KIT = SS:FindFirstChild("JapanGardenKit")
-- everything this needs is found BEFORE anything changes
if not (pond and br and KIT) then print("QQ MOONBRIDGEEND3 ABORT: the pond set, its moon bridge or ServerStorage.JapanGardenKit missing") return end
local SRC, FIN = KIT:FindFirstChild("moon_bridge_end3"), KIT:FindFirstChild("post_finial")
if not SRC then print("QQ MOONBRIDGEEND3 ABORT: the kit has no 'moon_bridge_end3' - import japan_kit17_moonbridge_end3.fbx") return end
if not FIN then print("QQ MOONBRIDGEEND3 ABORT: the kit has no 'post_finial' (kit15)") return end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, name) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and key(d) == name then return d end end end
for _, n in ipairs({"MB3_Deck", "MB3_Red", "MB3_Stone"}) do if not find(SRC, n) then print("QQ MOONBRIDGEEND3 ABORT: the kit's moon_bridge_end3 has no " .. n) return end end
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
if nd == 0 then print("QQ MOONBRIDGEEND3 ABORT: no 'Bridge deck' parts in the moon bridge") return end
local CX, G = xs / nd, 3.19                                                                   -- the bridge's centre line; the pond apron
local BB = {min = Vector3.new(-4.9, -0.35, -2.1), max = Vector3.new(4.9, 5.12, 7.0)}              -- out_moonbridge3/pieces.json (local: z outward)
local DECK_Z = 3.0                                                                                -- the deck extension's middle: outward
local END_POSTS = {{4.3, 3.55, 5.6}, {-4.3, 3.55, 5.6}}                                           -- (x, top, z) of the heavy end posts
local DECK = Color3.fromRGB(103, 72, 48)
local RED = Color3.fromRGB(179, 54, 31)
local STONE = Color3.fromRGB(58, 56, 54)
local GOLD = Color3.new(0.85, 0.66, 0.30)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("MoonBridgeReplaced") or Instance.new("Folder"); bak.Name = "MoonBridgeReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before moonbridgeend3") end)
local retired = 0
for _, w in ipairs(pond:GetChildren()) do
	if w:IsA("BasePart") and w.Name == "Walkway" then w:SetAttribute("MoonBridgeWasIn", w.Parent:GetFullName()); w.Parent = bak; retired += 1 end
end
local old = pond:FindFirstChild("MoonBridgeEnds"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "MoonBridgeEnds"
for _, p in ipairs(SRC:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
do	-- the kit's pivot at its local origin (the old deck end, court level); the import's half turn detected by the deck (outward side)
	local cf = SRC:GetBoundingBox()
	local deck = find(SRC, "MB3_Deck")
	local centreLocal = (BB.min + BB.max) / 2
	local flipped = (deck.Position.Z - cf.Position.Z) * (DECK_Z - centreLocal.Z) < 0
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
			if k == "MB3_Deck" then p.Material = Enum.Material.WoodPlanks; p.Color = DECK
			elseif k == "MB3_Red" then p.Material = Enum.Material.Wood; p.Color = RED
			else p.Material = Enum.Material.Slate; p.Color = STONE end
		end
	end
	m.Parent = F
	table.insert(placed, m)
	for _, q in ipairs(END_POSTS) do
		local f = FIN:Clone(); f.Name = "Finial"
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.Material = Enum.Material.Metal; d.Color = GOLD end
		end
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
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after moonbridgeend3") end)
local s1, s2 = placed[1]:GetBoundingBox(), placed[2]:GetBoundingBox()
print(string.format("QQ MOONBRIDGEEND3 DONE: the arch runs on to the court at both ends (deck ends z %.2f / %.2f, x %.1f): North at (%.1f, %.2f, %.1f), South at (%.1f, %.2f, %.1f); %d giboshi; %d slabs -> HudBackup.MoonBridgeReplaced; precise collision on %d",
	zS, zN, CX, s1.X, s1.Y, s1.Z, s2.X, s2.Y, s2.Z, nfin, retired, nfid))

-- moonbridgeend1.lua (runner 7, Oct 17 2026): the Vermilion moon bridge's two entrances at the palace pond. Shannon: "you fixed the
-- palace pond but did not fix the entrances of the bridge going across please fix it and make it look nice and complete". Each end
-- just stopped: the last plank (top 5.02) came down onto a plain pavement slab (the pond set's "Walkway", top 4.15) on the court (~3.1).
-- This script, at both ends (found from the bridge's "Bridge deck" parts: the south end z ~-21.1, the north end z ~65.1):
--  * retires the two pond-set "Walkway" slabs to ServerStorage.HudBackup.MoonBridgeReplaced (attribute MoonBridgeWasIn)
--  * places the kit Model "moon_bridge_end" (gen_moonbridge_end.py): a flagstone abutment that meets the pond wall's ledge and rises
--    under the deck, a cut-stone landing flush with the deck end, two cut-stone steps down to the court between low flagstone cheek walls
--    with stone caps (the pond wall's materials: Pavement + JM_PhotographicPath white; cut stone 0.66 / 0.63); solid, precise collision
--    set once parented
--  * a pair of stone lanterns at the foot of the steps: copies of the canal's StoneLantern1 (her darker stone, dimmed glow)
--  * a gold giboshi (onion finial, kit "post_finial") on top of each of the four red end posts
-- Re-runnable (the MoonBridgeEnds folder is rebuilt). Output "QQ MOONBRIDGEEND1".
-- Undo: delete the pond set's MoonBridgeEnds folder; HudBackup.MoonBridgeReplaced's two slabs back to their MoonBridgeWasIn.
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local pond = J and J:FindFirstChild("PalaceGrounds") and J.PalaceGrounds:FindFirstChild("Koi pond set piece")
local br = pond and pond:FindFirstChild("Vermilion moon bridge")
local KIT = SS:FindFirstChild("JapanGardenKit")
-- everything this needs is found BEFORE anything changes
if not (pond and br and KIT) then print("QQ MOONBRIDGEEND1 ABORT: the pond set, its moon bridge or ServerStorage.JapanGardenKit missing") return end
local SRC, FIN = KIT:FindFirstChild("moon_bridge_end"), KIT:FindFirstChild("post_finial")
if not (SRC and FIN) then print("QQ MOONBRIDGEEND1 ABORT: the kit has no 'moon_bridge_end' / 'post_finial' - import japan_kit15_moonbridge_end.fbx") return end
local LANTERN = J:FindFirstChild("MomijiGarden") and J.MomijiGarden:FindFirstChild("StoneLantern1")
if not LANTERN then print("QQ MOONBRIDGEEND1 ABORT: MomijiGarden.StoneLantern1 (the lantern to copy) missing") return end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, name) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and key(d) == name then return d end end end
if not find(SRC, "MB_Steps") then print("QQ MOONBRIDGEEND1 ABORT: the kit's moon_bridge_end has no MB_Steps") return end
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
if nd == 0 then print("QQ MOONBRIDGEEND1 ABORT: no 'Bridge deck' parts in the moon bridge") return end
local CX, G = xs / nd, 3.10                                                                   -- the bridge's centre line; the court
local BB = {min = Vector3.new(-5.66, -0.3, -2.5), max = Vector3.new(5.66, 2.25, 5.2)}              -- out_moonbridge/pieces.json (local: z outward)
local STEPS_Z = (2.75 + 4.95) / 2                                                                 -- the steps' middle: outward
local FLAG = {MB_Stone = true, MB_Cheek = true}
local COL = {MB_Cap = Color3.new(0.66, 0.65, 0.61), MB_CheekCap = Color3.new(0.66, 0.65, 0.61), MB_Steps = Color3.new(0.63, 0.62, 0.58)}
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("MoonBridgeReplaced") or Instance.new("Folder"); bak.Name = "MoonBridgeReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before moonbridgeend1") end)
-- 1. the two slabs
local retired = 0
for _, w in ipairs(pond:GetChildren()) do
	if w:IsA("BasePart") and w.Name == "Walkway" then w:SetAttribute("MoonBridgeWasIn", w.Parent:GetFullName()); w.Parent = bak; retired += 1 end
end
local old = pond:FindFirstChild("MoonBridgeEnds"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "MoonBridgeEnds"
-- 2. the ends
for _, p in ipairs(SRC:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
do
	local cf = SRC:GetBoundingBox()
	local steps = find(SRC, "MB_Steps")
	local centreLocal = (BB.min + BB.max) / 2
	local flipped = (steps.Position.Z - cf.Position.Z) * (STEPS_Z - centreLocal.Z) < 0
	local R = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
	SRC.WorldPivot = CFrame.new(cf.Position - R:VectorToWorldSpace(centreLocal)) * R
end
local placed = {}
for _, e in ipairs({{"North", zN, 0}, {"South", zS, math.pi}}) do
	local m = SRC:Clone(); m.Name = "MoonBridgeEnd" .. e[1]
	m:PivotTo(CFrame.new(CX, G, e[2]) * CFrame.Angles(0, e[3], 0))
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local k = key(p)
			p.Anchored = true; p.CanCollide = true; p.CanQuery = true; p.CanTouch = false; p.CastShadow = true
			if FLAG[k] then p.Material = Enum.Material.Pavement; p.Color = Color3.new(1, 1, 1); pcall(function() p.MaterialVariant = "JM_PhotographicPath" end)
			else p.Material = Enum.Material.SmoothPlastic; p.Color = COL[k] or p.Color end
		end
	end
	m.Parent = F
	table.insert(placed, m)
	-- the lanterns at the foot of the steps, either side
	for _, s in ipairs({1, -1}) do
		local L = LANTERN:Clone(); L.Name = "Lantern" .. e[1] .. (s > 0 and "E" or "W")
		local lcf, lsz = L:GetBoundingBox()
		local base = CFrame.new(CX, G, e[2]) * CFrame.Angles(0, e[3], 0) * CFrame.new(s * 7.4, 0, 4.2)
		L:PivotTo(L:GetPivot() + (base.Position - Vector3.new(lcf.X, lcf.Y - lsz.Y / 2 + 0.05, lcf.Z)))
		L.Parent = F
	end
end
-- 3. the finials on the four end posts
local nfin = 0
for _, p in ipairs(br:GetDescendants()) do
	if p:IsA("BasePart") and key(p) == "Bridge post" then
		local a, b = ext(p)
		if math.abs(a.Z - zS) < 1 or math.abs(b.Z - zN) < 1 then
			local f = FIN:Clone(); f.Name = "Finial"
			for _, q in ipairs(f:GetDescendants()) do
				if q:IsA("BasePart") then q.Anchored = true; q.CanCollide = false; q.CanQuery = false; q.CanTouch = false; q.Material = Enum.Material.Metal; q.Color = Color3.new(0.85, 0.66, 0.30) end
			end
			pcall(function() f:ScaleTo(0.85) end)
			local fcf, fsz = f:GetBoundingBox()
			f:PivotTo(f:GetPivot() + (Vector3.new(p.Position.X, b.Y, p.Position.Z) - Vector3.new(fcf.X, fcf.Y - fsz.Y / 2 + 0.02, fcf.Z)))
			f.Parent = F; nfin += 1
		end
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
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after moonbridgeend1") end)
local s1, s2 = placed[1]:GetBoundingBox(), placed[2]:GetBoundingBox()
print(string.format("QQ MOONBRIDGEEND1 DONE: ends at the deck ends z %.2f / %.2f (x %.1f): North at (%.1f, %.2f, %.1f), South at (%.1f, %.2f, %.1f); 4 lanterns, %d finials; %d slabs -> HudBackup.MoonBridgeReplaced; precise collision on %d",
	zS, zN, CX, s1.X, s1.Y, s1.Z, s2.X, s2.Y, s2.Z, nfin, retired, nfid))

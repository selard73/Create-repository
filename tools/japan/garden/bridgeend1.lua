-- bridgeend1.lua (cloud, Oct 16 2026): the taiko bridges' ends rebuilt. Shannon circled two slots at a bridge end: canalfix1 raised
-- every TaikoBridge 1.6 and stretched its landings x2.6, so the 0.13 gap between the landing and the bridge's stone footing (the
-- landing starts at the beam tips, 20.232 out; the footing ends at 20.1) became a 2.1-tall slit, the 0.7..1.0 gap between the footing
-- (from 17.5) and the canal wall (lawn face 16.5, coping 16.8) a slot under the beam, and the steps 1.3-tall blocks.
-- The kit Model "bridge_end" (gen_bridge_end.py) is one piece per end: a stone abutment from inside the wall (16.15) to the deck end
-- in the walls' flagstone, a coping cap at 2.18 (0.08 over the wall's) the beams rest on, and steps from the deck end (top tread 2.3,
-- flush) down to the lawn in 4 risers of 0.575, the foot where the old landing's was (23.25). This script, for every TaikoBridge:
--  * measures the bridge (its Bridge_Stone footings: the centre, and the deck end = the footing top + 0.2) and the lawn (the old
--    landing's bottom), and checks the deck end is 2.3 over the lawn (canalfix1's raise)
--  * moves LandingW<i> / LandingE<i> (and any earlier BridgeEnd*) to ServerStorage.HudBackup.BridgeEndReplaced
--  * places bridge_end at both ends, 20 out from the centre (the west one turned round), detecting the import's half turn by the steps
--    (they lie on the piece's outward side), and dresses it (the abutment as the walls: Pavement + JM_PhotographicPath, white; coping and
--    steps the walls' / landings' stone; all solid). The old footings stay, hidden inside (0.05 in from every face).
-- Re-runnable. Output "QQ BRIDGEEND1".
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local G = workspace:FindFirstChild("JapanMap") and workspace.JapanMap:FindFirstChild("MomijiGarden")
if not (KIT and G) then print("QQ BRIDGEEND1 ABORT: ServerStorage.JapanGardenKit or JapanMap.MomijiGarden missing") return end
local SRC = KIT:FindFirstChild("bridge_end")
if not SRC then print("QQ BRIDGEEND1 ABORT: the kit has no Model 'bridge_end' - import japan_kit11_falls3_bridge_end.fbx") return end
local BB = {min = Vector3.new(-3.9, -0.6, -4.75), max = Vector3.new(3.25, 2.3, 4.75)}           -- out_bridge_end/pieces.json (Roblox axes)
local STEPS_X = (-0.1 + 3.25) / 2                                                               -- the steps' centre: on the outward (+x) side
local END_OUT, DECK_OVER_LAWN = 20.0, 2.3                                                       -- the deck end, 20 out from the centre, 2.3 up
local COL = {Abut_Coping = Color3.new(0.66, 0.65, 0.61), Abut_Steps = Color3.new(0.63, 0.62, 0.58)}
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function extents(p)                                                                       -- a part's world-axis box: centre, size
	local s, r = p.Size, p.CFrame
	local function e(ax) return math.abs(r.RightVector[ax]) * s.X + math.abs(r.UpVector[ax]) * s.Y + math.abs(r.LookVector[ax]) * s.Z end
	return p.Position, Vector3.new(e("X"), e("Y"), e("Z"))
end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("BridgeEndReplaced") or Instance.new("Folder"); bak.Name = "BridgeEndReplaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before bridgeend1") end)
-- the steps must collide as steps: set on the kit (CollisionFidelity can't be set in a play test - there the clone keeps the kit's)
for _, p in ipairs(SRC:GetDescendants()) do
	if p:IsA("MeshPart") then pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) end
end
local bridges = {}
for _, d in ipairs(G:GetDescendants()) do
	if d:IsA("Model") and d.Name:match("^TaikoBridge%d+$") and not d:IsDescendantOf(bak) then table.insert(bridges, d) end
end
table.sort(bridges, function(a, b) return a.Name < b.Name end)
local placed, retired, skipped = 0, 0, {}
for _, br in ipairs(bridges) do
	local i = br.Name:match("%d+$")
	local foot
	for _, p in ipairs(br:GetDescendants()) do if p:IsA("BasePart") and key(p) == "Bridge_Stone" then foot = p end end
	if not foot then table.insert(skipped, br.Name .. " (no Bridge_Stone)") continue end
	local c, s = extents(foot)
	if s.X < s.Z then table.insert(skipped, br.Name .. " (not along x)") continue end
	local deckTop = c.Y + s.Y / 2 + 0.2
	local parent = br.Parent
	-- the lawn: the old landings' bottom (or, on a re-run, the earlier BridgeEnd's bottom + 0.6)
	local ground, olds = nil, {}
	for _, d in ipairs(parent:GetChildren()) do
		if d:IsA("Model") and (d.Name == "LandingW" .. i or d.Name == "LandingE" .. i or d.Name == "BridgeEndW" .. i or d.Name == "BridgeEndE" .. i) then
			local cf, sz = d:GetBoundingBox()
			local bottom = cf.Y - sz.Y / 2 + (d.Name:sub(1, 9) == "BridgeEnd" and 0.6 or 0)
			ground = ground and math.min(ground, bottom) or bottom
			table.insert(olds, d)
		end
	end
	ground = ground or 0
	local off = deckTop - ground - DECK_OVER_LAWN
	if math.abs(off) > 0.2 then table.insert(skipped, string.format("%s (deck end %.2f over the lawn, expected %.1f)", br.Name, deckTop - ground, DECK_OVER_LAWN)) continue end
	for _, d in ipairs(olds) do d:SetAttribute("BridgeEndWasIn", d.Parent:GetFullName()); d.Parent = bak; retired += 1 end
	for _, side in ipairs({1, -1}) do
		local m = SRC:Clone(); m.Name = (side > 0 and "BridgeEndE" or "BridgeEndW") .. i
		local cf = m:GetBoundingBox()
		local steps = m:FindFirstChild("Abut_Steps", true)
		local centreLocal = (BB.min + BB.max) / 2
		local flipped = steps and ((steps.Position.X - cf.Position.X) * (STEPS_X - centreLocal.X) < 0) or false
		local R = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
		m.WorldPivot = CFrame.new(cf.Position - R:VectorToWorldSpace(centreLocal)) * R
		m:PivotTo(CFrame.new(c.X + side * END_OUT, ground, c.Z) * CFrame.Angles(0, side > 0 and 0 or math.pi, 0))
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				local k = key(p)
				p.Anchored = true; p.CanCollide = true; p.CanQuery = true; p.CanTouch = false; p.CastShadow = true
				if k == "Abut_Stone" then
					p.Material = Enum.Material.Pavement; p.Color = Color3.new(1, 1, 1); pcall(function() p.MaterialVariant = "JM_PhotographicPath" end)
				else
					p.Material = Enum.Material.SmoothPlastic; p.Color = COL[k] or COL.Abut_Steps
				end
			end
		end
		m.Parent = parent
		local st = m:FindFirstChild("Abut_Steps", true)
		local out = st and (st.Position.X - c.X) * side or 0
		print(string.format("QQ BRIDGEEND1 %s %s: at x %.1f, lawn %.2f, deck end %.2f (%+.2f), steps' centre %.2f out (expected %.2f)",
			m.Name, flipped and "(turned back)" or "(as imported)", c.X + side * END_OUT, ground, deckTop, off, out, END_OUT + STEPS_X))
		placed += 1
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after bridgeend1") end)
if #skipped > 0 then print("QQ BRIDGEEND1 SKIPPED: " .. table.concat(skipped, "; ")) end
print(string.format("QQ BRIDGEEND1 DONE: %d bridge ends placed on %d bridges, %d old landings / ends -> HudBackup.BridgeEndReplaced", placed, #bridges, retired))

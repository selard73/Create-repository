-- walkfix1.lua (runner 7, Oct 17 2026): Japan's "jacked up" walkways. Shannon: "there are many walkways that are jacked up and sitting
-- above the main ground they are on, we need all of those fixed". Survey (read-only, both rays and pictures): Japan's lawns are an
-- invisible CanCollide floor at y 0 with a grass mesh top at -0.04; most Walkway slabs sit at y 0.08 (sunk 0.1 into the grass - fine).
-- The ones that float, and what this script does to each (everything measured again at run time, nothing moved blind):
--  A. FLAT slabs over the lawn: TeaHills (5689, 0.68, 70) and (5802, 0.68, 70) -> lowered to y 0.085 like the others.
--  B. TeaHills (5657, 1.50, -82): a flat slab 1.3 over the lawn at its west end, into the hill at its east end (it meets the tea lookout
--     ramp) -> tilted into a gentle ramp (lawn end top 0.31, hill end as it was) with a solid earth wedge under it.
--  C. The three station approaches (Tea Hills / Lantern Street / Palace Grounds): slabs at 0.98 and ~1.56 stepping up to the platform
--     (2.10) with air under -> solid stone blocks fill under each slab down to the lawn, so they read as built terraces.
--  D. The three RAMPS (the palace gate passage 5 deg from the lawn to the court at 3.0; the keep approach 14 deg from the court to 13.8;
--     the volcano lookout 19 deg from the lawn to the deck at 10) -> a solid WedgePart fill under each from its lowest ground up to its
--     underside: the gate in the court's flagstone (a paved ramp), the keep and the lookout in dark stone (an embankment).
-- The lake pier (JM_JR_Lake_Boardwalk on stilts over the lawn + the Promenade end landing 16 up) is NOT touched: its own decision.
-- All fills go in JapanMap.WalkFills (undo: delete it); moved slabs keep their old CFrame in attribute WalkFixWasCFrame (undo: put it
-- back). Re-runnable. Output "QQ WALKFIX1".
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ WALKFIX1 ABORT: JapanMap missing") return end
local LAWN_Y, SLAB_Y = 0.0, 0.085
local FLAG = {Enum.Material.Pavement, Color3.new(1, 1, 1), "JM_PhotographicPath"}
local DARK = {Enum.Material.Slate, Color3.fromRGB(72, 70, 68), nil}
local EARTH = {Enum.Material.Ground, Color3.fromRGB(96, 78, 58), nil}
local function walkways(folder, test)
	local t = {}
	for _, d in ipairs(folder:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Walkway" and test(d) then table.insert(t, d) end end
	return t
end
local function near(p, x, y, z, tol) return math.abs(p.Position.X - x) < tol and math.abs(p.Position.Y - y) < 0.3 and math.abs(p.Position.Z - z) < tol end
local report = {}
local function say(s) table.insert(report, s) end
local old = J:FindFirstChild("WalkFills"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "WalkFills"
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before walkfix1") end)
local function paint(p, look) p.Material = look[1]; p.Color = look[2]; if look[3] then pcall(function() p.MaterialVariant = look[3] end) end end
local function keepOld(p) if not p:GetAttribute("WalkFixWasCFrame") then p:SetAttribute("WalkFixWasCFrame", p.CFrame) end end
local function longAxis(p)                                                            -- the slab's long direction and length, and its width
	if p.Size.Z >= p.Size.X then return p.CFrame.LookVector, p.Size.Z, p.Size.X end
	return p.CFrame.RightVector, p.Size.X, p.Size.Z
end
local function block(name, cf, size, look, parent)
	local b = Instance.new("Part"); b.Name = name; b.Anchored = true; b.CanCollide = true; b.CanQuery = true; b.CanTouch = false; b.CastShadow = true
	b.Size = size; b.CFrame = cf; paint(b, look); b.Parent = parent or F; return b
end
-- ---------- A. flat slabs over the lawn ----------
local nA = 0
for _, p in ipairs(walkways(J, function(d) return (near(d, 5689, 0.68, 70, 3) or near(d, 5802, 0.68, 70, 3)) and d.Orientation.Magnitude < 1 end)) do
	keepOld(p); p.CFrame = CFrame.new(p.Position.X, SLAB_Y, p.Position.Z) * (p.CFrame - p.Position); nA += 1
	say(string.format("A: %s at (%.0f, %.0f) lowered to y %.3f", p.Name, p.Position.X, p.Position.Z, SLAB_Y))
end
-- ---------- B. the tea lookout approach slab -> a gentle ramp with earth under ----------
for _, p in ipairs(walkways(J, function(d) return near(d, 5657, 1.50, -82, 3) end)) do
	keepOld(p)
	local dir, L, W = longAxis(p)
	local a, b = p.Position - dir * (L / 2), p.Position + dir * (L / 2)                -- which end is over the lawn? the one with terrain far below is the lawn end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain}
	local ta = workspace:Raycast(a + Vector3.new(0, 10, 0), Vector3.new(0, -60, 0), rp)
	local tb = workspace:Raycast(b + Vector3.new(0, 10, 0), Vector3.new(0, -60, 0), rp)
	local ya, yb = ta and ta.Position.Y or -99, tb and tb.Position.Y or -99
	local lawnEnd, hillEnd = a, b
	if yb < ya then lawnEnd, hillEnd = b, a end                                         -- the lower terrain is the lawn's -6
	local topLawn, topHill = SLAB_Y + p.Size.Y / 2, p.Position.Y + p.Size.Y / 2
	local lo = Vector3.new(lawnEnd.X, topLawn - p.Size.Y / 2, lawnEnd.Z)
	local hi = Vector3.new(hillEnd.X, topHill - p.Size.Y / 2, hillEnd.Z)
	local mid = (lo + hi) / 2
	local look = CFrame.lookAt(mid, hi)                                                 -- -Z toward the hill end
	p.CFrame = CFrame.fromMatrix(mid, look.RightVector, look.UpVector, look.ZVector)
	if p.Size.Z < p.Size.X then p.CFrame = p.CFrame * CFrame.Angles(0, math.pi / 2, 0) end
	local rise = topHill - topLawn
	local Lh = (Vector3.new(hi.X, 0, hi.Z) - Vector3.new(lo.X, 0, lo.Z)).Magnitude
	local w = Instance.new("WedgePart"); w.Name = "Fill_TeaLookoutRamp"; w.Anchored = true; w.CanCollide = true; w.CanTouch = false
	w.Size = Vector3.new(W - 0.1, rise + (SLAB_Y - LAWN_Y), Lh)
	local base = Vector3.new(mid.X, LAWN_Y - 0.1 + w.Size.Y / 2, mid.Z)
	w.CFrame = CFrame.lookAt(base, base - Vector3.new(hi.X - lo.X, 0, hi.Z - lo.Z))     -- the wedge's +Z (its tall back) toward the hill end
	paint(w, EARTH); w.Parent = F
	say(string.format("B: tea lookout slab tilted: lawn end top %.2f, hill end top %.2f over %.0f (%.1f deg); earth wedge %s", topLawn, topHill, Lh, math.deg(math.atan(rise / Lh)), tostring(w.Size)))
end
-- ---------- C. the station approaches: solid blocks under the stepped slabs ----------
local nC = 0
for _, st in ipairs({{"Tea Hills station", 5630}, {"Lantern Street station", 6000}, {"Palace Grounds station", 6379}}) do
	local s = J.Railway:FindFirstChild(st[1])
	if s then
		for _, p in ipairs(walkways(s, function(d) return d.Position.Y - d.Size.Y / 2 > LAWN_Y + 0.2 and d.Orientation.Magnitude < 1 end)) do
			local bottom = p.Position.Y - p.Size.Y / 2
			local h = bottom - (LAWN_Y - 0.1)
			block("Fill_" .. st[1]:gsub(" ", "") .. "_" .. math.floor(p.Position.Z), CFrame.new(p.Position.X, LAWN_Y - 0.1 + h / 2, p.Position.Z) * (p.CFrame - p.Position), Vector3.new(p.Size.X - 0.1, h, p.Size.Z - 0.1), DARK)
			nC += 1
			say(string.format("C: %s slab at z %.0f (top %.2f): stone block %.2f tall under it", st[1], p.Position.Z, p.Position.Y + p.Size.Y / 2, h))
		end
	end
end
-- ---------- D. the ramps: a wedge under each ----------
local RAMPS = {
	{"Fill_GateRamp", 6379, 1.63, 120.5, FLAG, nil},
	{"Fill_KeepRamp", 6438, 8.43, -161, DARK, nil},
	{"Fill_LookoutRamp", 5417.5, 4.88, -288, DARK, nil},
}
local nD = 0
for _, r in ipairs(RAMPS) do
	local found
	for _, d in ipairs(J:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Walkway" and near(d, r[2], r[3], r[4], 2.5) then found = d break end end
	if not found then say("D: ramp not found at " .. r[2] .. "," .. r[4]) continue end
	local p = found
	local dir, L, W = longAxis(p)
	local a, b = p.Position - dir * (L / 2), p.Position + dir * (L / 2)
	local lo, hi = a, b
	if b.Y < a.Y then lo, hi = b, a end
	local under = p.Size.Y / 2
	local loU, hiU = lo.Y - under, hi.Y - under                                        -- the underside at both ends
	-- the lowest ground under the ramp: rays at 9 points, the first CanCollide hit that is not a walkway
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F, p}
	local g = math.huge
	for k = 0, 8 do
		local q = lo + (hi - lo) * (k / 8)
		local o = Vector3.new(q.X, q.Y + 0.3, q.Z)
		for _ = 1, 8 do
			local h = workspace:Raycast(o, Vector3.new(0, -60, 0), rp)
			if not h then break end
			if h.Instance == workspace.Terrain or h.Instance.CanCollide then if h.Instance.Name ~= "Walkway" then g = math.min(g, h.Position.Y) end break end
			o = h.Position - Vector3.new(0, 0.05, 0)
		end
	end
	if g == math.huge then say("D: no ground under " .. r[1]) continue end
	local H = hiU - g
	local flat = Vector3.new(hi.X - lo.X, 0, hi.Z - lo.Z)
	local Lh = flat.Magnitude
	local w = Instance.new("WedgePart"); w.Name = r[1]; w.Anchored = true; w.CanCollide = true; w.CanTouch = false; w.CastShadow = true
	w.Size = Vector3.new(W - 0.1, H, Lh)
	local base = Vector3.new((lo.X + hi.X) / 2, g + H / 2, (lo.Z + hi.Z) / 2)
	w.CFrame = CFrame.lookAt(base, base - flat)                                         -- +Z (the tall back) toward the high end
	paint(w, r[5]); w.Parent = F; nD += 1
	say(string.format("D: %s: wedge %.1f wide x %.2f tall x %.1f long from ground %.2f (ramp tops %.2f -> %.2f, underside at the low end %.2f)", r[1], W, H, Lh, g, lo.Y, hi.Y, loU))
end
F.Parent = J
task.wait()
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after walkfix1") end)
for _, s in ipairs(report) do print("QQ WALKFIX1 " .. s) end
print(string.format("QQ WALKFIX1 DONE: %d slabs lowered, 1 slab made a ramp, %d station blocks, %d ramp wedges in JapanMap.WalkFills; the lake pier left for its own decision", nA, nC, nD))

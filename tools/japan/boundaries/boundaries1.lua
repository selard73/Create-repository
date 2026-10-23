-- boundaries1.lua (Oct 23 2026): Japan's area boundaries, like Porto's gates. Shannon: "we need boundaries like in the other maps
-- ... how are we going to block off sections on this map seeing as how it is flat and wide open?" -> her yes to the plan:
-- Lantern Street opens first, Tea Hills second, the Palace last. The stream and the canal are the lines; fences close their ends
-- and run along the north edge of the railway-side path (the stations, the train and the arrival lawn stay on the open side);
-- gates: the farm bridge's west landing (wood), the three taiko bridges' east landings in a bamboo fence along the canal's east
-- bank (vermilion), the Tea Hills station's exit ramp (wood) and the palace main gate's passage (vermilion, scaled to it).
-- The safety net: JapanGateServer walks anyone past a line back to the nearest gate on the open side (swimming the stream,
-- climbing a mountain). Kit japan_fence_kit.fbx (gen_fence_kit.py), imported by her, adopted into ServerStorage.JapanGardenKit.
-- PART 1 (this file): the kit + the fences. PART 2 (boundaries2.lua): gates + signs. PART 3 (boundaries3.lua): the scripts.
-- Everything new lives in workspace.JapanGates (Gates / Walls / the two scripts); nothing existing is changed. "QQ BOUNDARIES1".
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local KIT = SS:FindFirstChild("JapanGardenKit")
if not (J and KIT) then return "QQ BOUNDARIES1 ABORT: JapanMap or JapanGardenKit missing" end
local out = {}
local function say(s) table.insert(out, "QQ BOUNDARIES1 " .. s) end
local PIECES = {"JF_WoodSection", "JF_WoodPost", "JF_BambooSection", "JF_BambooPost", "JF_GateWood", "JF_GateVermilion", "JF_SignBoard"}

-- the kit: a loose import (a Model holding the pieces; multi-colour pieces come as "<piece>__<colour>" parts)
local function key(n) return (n:gsub("%.%d+$", "")) end
local function adoptKit()
	local found, missing = {}, 0
	for _, n in ipairs(PIECES) do if KIT:FindFirstChild(n) then found[n] = KIT[n] else missing += 1 end end
	if missing == 0 then return found end
	local imp
	for _, top in ipairs(workspace:GetChildren()) do
		if top:IsA("Model") and top ~= J then
			for _, d in ipairs(top:GetDescendants()) do if d:IsA("BasePart") and d.Name:find("^JF_") then imp = top break end end
			if imp then break end
		end
	end
	if not imp then return nil, "no japan_fence_kit import in workspace (import japan_fence_kit.fbx first)" end
	local groups = {}
	for _, d in ipairs(imp:GetDescendants()) do
		if d:IsA("BasePart") then
			local p = key(d.Name):match("^(JF_%a+)")
			if p then groups[p] = groups[p] or {}; table.insert(groups[p], d) end
		end
	end
	for _, n in ipairs(PIECES) do
		if not found[n] then
			local parts = groups[n]
			if not parts then return nil, "kit piece " .. n .. " missing from the import" end
			local m = Instance.new("Model"); m.Name = n
			for _, p in ipairs(parts) do
				p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
				local col = key(p.Name):match("__([%a_]+)$")             -- colour names carry underscores (Wood_Mid): [%a_], not %a
				p.Name = n .. (col and ("__" .. col) or "")
				p.Parent = m
			end
			m.Parent = KIT
			found[n] = m
		end
	end
	if #imp:GetDescendants() == 0 then imp:Destroy() end
	-- the import comes in turned 180 about y (the vending kit did too): the wood section's post is at the design's low-x end
	local ws = found.JF_WoodSection
	local postPart = ws:FindFirstChild("JF_WoodSection__Wood_Dark")
	local cf = ws:GetBoundingBox()
	local turned = postPart and (postPart.Position.X > cf.Position.X)
	if turned then
		for _, n in ipairs(PIECES) do local m = found[n]; m:PivotTo(m:GetPivot() * CFrame.Angles(0, math.pi, 0)) end
	end
	say("kit adopted into JapanGardenKit" .. (turned and " (turned back 180)" or ""))
	return found
end
local kit, err = adoptKit()
if not kit then return "QQ BOUNDARIES1 ABORT: " .. err end

-- looks: Studio materials per colour suffix
local C = Color3.fromRGB
local LOOK = {
	Wood_Dark = {Enum.Material.Wood, C(86, 60, 38)}, Wood_Mid = {Enum.Material.WoodPlanks, C(150, 108, 62)}, Wood_Cap = {Enum.Material.Wood, C(66, 44, 28)},
	Bamboo = {Enum.Material.SmoothPlastic, C(196, 166, 96)}, Bamboo_Dark = {Enum.Material.SmoothPlastic, C(142, 116, 62)}, Rope = {Enum.Material.Fabric, C(26, 24, 22)},
	Vermilion = {Enum.Material.SmoothPlastic, C(200, 48, 28)}, Black = {Enum.Material.SmoothPlastic, C(28, 26, 26)}, Board = {Enum.Material.WoodPlanks, C(160, 120, 70)},
}
local function dress(m, solid)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local col = p.Name:match("__([%a_]+)$") or "Wood_Dark"
			local d = LOOK[col] or LOOK.Wood_Dark
			p.Material, p.Color = d[1], d[2]
			p.Anchored = true; p.CanCollide = solid; p.CanQuery = true; p.CanTouch = false; p.CastShadow = true
			if p:IsA("MeshPart") then p.DoubleSided = false end
		end
	end
end
-- a kit piece as a Model whose WorldPivot is its design origin (the post's centre at ground level / the hinge edge at ground)
local DESIGN = {                        -- each piece's bbox minimum x and y in its own frame (gen_fence_kit.py)
	JF_WoodSection = {-0.36, -0.5}, JF_WoodPost = {-0.36, -0.5}, JF_BambooSection = {-0.24, -0.5}, JF_BambooPost = {-0.24, -0.5},
	JF_GateWood = {0, 0}, JF_GateVermilion = {0, 0}, JF_SignBoard = {-2.6, -0.4},
}
local function piece(name)
	local m = kit[name]:Clone()
	local cf, sz = m:GetBoundingBox()
	local d = DESIGN[name]
	m.WorldPivot = CFrame.new(cf.Position.X - sz.X / 2 - d[1], cf.Position.Y - sz.Y / 2 - d[2], cf.Position.Z)
	return m
end
-- the ground under a point: the first hit that is terrain or a known ground part (not a tree crown, a lantern, a fence)
local GROUND = {"Japan land", "Walkway", "River end", "Railway", "Market paving", "Abut_", "JP_Island", "Fall_Rock", "Stone", "paving", "Path", "Lawn"}
local function ground(x, z)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local excl = {workspace.JapanGates}
	local o, first = Vector3.new(x, 90, z), nil
	for _ = 1, 10 do
		rp.FilterDescendantsInstances = excl
		local r = workspace:Raycast(o, Vector3.new(0, -140, 0), rp)
		if not r then break end
		first = first or r
		if r.Instance == workspace.Terrain then return r.Position.Y, r end
		for _, g in ipairs(GROUND) do if r.Instance.Name:find(g, 1, true) then return r.Position.Y, r end end
		table.insert(excl, r.Instance); o = r.Position + Vector3.new(0, 0.01, 0)
	end
	return first and first.Position.Y or 0, first
end

local G = workspace:FindFirstChild("JapanGates")
if not G then
	G = Instance.new("Folder"); G.Name = "JapanGates"; G.Parent = workspace
	local gates = Instance.new("Folder"); gates.Name = "Gates"; gates.Parent = G
	local walls = Instance.new("Model"); walls.Name = "Walls"; walls.Parent = G
end
if G:GetAttribute("Boundaries1Fences") then return "QQ BOUNDARIES1 fences already installed (" .. tostring(G:GetAttribute("Boundaries1Fences")) .. ")" end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before boundaries1") end)

-- ======================================================================== PART 1: the fences
local SINK = 0.4                                   -- posts sit this much into the ground
local function fenceRun(style, pts, label, front, gapsX, gapsZ)
	-- pts: a polyline of Vector2 (x, z); front: the world direction the boards face (the open side, where players walk);
	-- gapsX / gapsZ: spans left open for gates, by the section's middle x or z
	local sec, post = (style == "wood") and "JF_WoodSection" or "JF_BambooSection", (style == "wood") and "JF_WoodPost" or "JF_BambooPost"
	local run = Instance.new("Model"); run.Name = label; run:SetAttribute("Style", style); run.Parent = G.Walls
	local n, skipped = 0, 0
	local function inGap(mid)
		for _, g in ipairs(gapsX or {}) do if mid.X > g[1] and mid.X < g[2] then return true end end
		for _, g in ipairs(gapsZ or {}) do if mid.Y > g[1] and mid.Y < g[2] then return true end end
		return false
	end
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local L = (b - a).Magnitude
		local dir = (b - a) / L
		local t = 0
		local wasGap = false
		while t < L - 0.05 do
			local len = math.min(4.0, L - t)
			local p0, p1 = a + dir * t, a + dir * (t + len)
			local mid = (p0 + p1) / 2
			if inGap(mid) then
				if not wasGap then                                   -- a post at the gap's start, so the gate hangs between posts
					local y = ground(p0.X, p0.Y)
					local pp = piece(post); dress(pp, true); pp:PivotTo(CFrame.new(p0.X, y - SINK, p0.Y)); pp.Name = post .. " gap"; pp.Parent = run
				end
				wasGap = true
				t += len; skipped += 1
				continue
			end
			wasGap = false
			local y0 = ground(p0.X, p0.Y)
			local y1 = ground(p1.X, p1.Y)
			-- sections stay LEVEL (a tilted section looks sheared); on steep ground they get short so the steps stay small
			if math.abs(y1 - y0) > 0.8 and len > 2.0 then
				len = 2.0; p1 = a + dir * (t + len); y1 = ground(p1.X, p1.Y)
				if math.abs(y1 - y0) > 1.0 then len = 1.0; p1 = a + dir * (t + len); y1 = ground(p1.X, p1.Y) end
			end
			local base = math.min(y0, y1) + math.abs(y1 - y0) / 2
			local s = piece(sec)
			dress(s, true)
			if len < 3.99 then                                  -- the last section of a run: squeezed to fit
				local f = math.max(len / 4.0, 0.25)
				local pv = s.WorldPivot
				for _, p in ipairs(s:GetDescendants()) do
					if p:IsA("BasePart") then
						local rel = pv:ToObjectSpace(p.CFrame)
						p.Size = Vector3.new(p.Size.X * f, p.Size.Y, p.Size.Z)
						p.CFrame = pv * CFrame.new(rel.Position.X * f, rel.Position.Y, rel.Position.Z) * rel.Rotation
					end
				end
			end
			local P0 = Vector3.new(p0.X, base - SINK, p0.Y)
			local P1 = Vector3.new(p1.X, base - SINK, p1.Y)
			local along = (P1 - P0).Unit
			local up = Vector3.yAxis
			-- the piece's boards are on its local +z; run it from P0 or from P1 so that side faces `front`
			if along:Cross(up):Dot(front) >= 0 then
				s:PivotTo(CFrame.fromMatrix(P0, along, up))
			else
				s:PivotTo(CFrame.fromMatrix(P1, -along, up))
			end
			s.Name = string.format("%s %d", sec, n + 1)
			s.Parent = run
			n += 1
			t += len
		end
	end
	local e = pts[#pts]
	local ye = ground(e.X, e.Y)
	local pEnd = piece(post); dress(pEnd, true)
	pEnd:PivotTo(CFrame.new(e.X, ye - SINK, e.Y)); pEnd.Name = post .. " end"; pEnd.Parent = run
	say(string.format("%s: %d sections (%s), %d left open for gates", label, n, style, skipped))
	return run
end
local V = Vector2.new
-- WEST (wood): the stream's south end -> the railway-side path, along the path's north edge to the shore (gap = the Tea Hills
-- station's exit ramp, x 5623..5637), and the stream's north end up the slope behind the waterfall
local X, Z = Vector3.xAxis, Vector3.zAxis
fenceRun("wood", {V(5765, 85), V(5765, 117), V(5358, 117)}, "West fence - farmland", (X + Z).Unit, {{5622, 5638}})
fenceRun("wood", {V(5765, -298), V(5765, -402)}, "West fence - stream head", X)
-- EAST (bamboo): along the canal's east bank (gaps = the three bridge gates at z -203 / -75 / 80), round the church to the
-- slope; the path edge from the canal to the palace's west corner; the palace's east corner to the lake
fenceRun("bamboo", {V(6126.5, 117), V(6126.5, -226), V(6132.5, -242), V(6132.5, -250)}, "East fence - canal bank", -X, nil, {{-208.5, -197.5}, {-80.5, -69.5}, {74.5, 85.5}})
fenceRun("bamboo", {V(6132.5, -310), V(6132.5, -402)}, "East fence - behind the church", -X)
fenceRun("bamboo", {V(6126.5, 117), V(6212, 117)}, "East fence - path edge to the palace", Z)
fenceRun("bamboo", {V(6552, 117), V(6640, 117)}, "East fence - palace corner to the lake", Z)

-- what the fences run into (trees, lanterns, paths excepted below): a list for her, nothing moved
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {G, workspace.Terrain}
local hits, total = {}, 0
for _, p in ipairs(G.Walls:GetDescendants()) do
	if p:IsA("BasePart") then
		for _, q in ipairs(workspace:GetPartsInPart(p, op)) do
			local n = q.Name
			local isGround = false
			for _, g in ipairs(GROUND) do if n:find(g, 1, true) then isGround = true end end
			if not isGround and q.Transparency < 0.95 then
				local k = q:GetFullName():gsub("Workspace.JapanMap.", ""):gsub("%.%d+$", "")
				if not hits[k] then hits[k] = true; total += 1 end
			end
		end
	end
	if total > 40 then break end
end
local hl = {}; for k in pairs(hits) do table.insert(hl, k) end; table.sort(hl)
say(#hl > 0 and ("fences run into: " .. table.concat(hl, " | ")) or "fences run into nothing")
G:SetAttribute("Boundaries1Fences", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after boundaries1 fences") end)
say("DONE part 1 (fences) - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")

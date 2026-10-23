-- boundaries2.lua (Oct 23 2026): PART 2 of the Japan boundaries - the six gates and their signs, on Porto's gate contract
-- (PortoGateClient: a Model with NeedArea / FromName / ToName / Kind, a Block part, LeafL / LeafR models with Hinge + OpenAngle,
-- plus ToArea for Japan's "coming soon"). Leaves are the kit's gate pieces, hinge edge at the pivot, scaled to the opening:
--   Farm bridge gate (wood)      the bridge's west landing, x 5748, z 65..75, facing Tea Hills; opens at 10 in Lantern Street
--   Tea Hills station gate (wood) the station's exit ramp, x 5621..5637 on the path edge z 117; opens at 10 in Lantern Street
--   Canal bridge gates N / M / S (vermilion) the taiko bridges' east landings at x 6126.5, z -203 / -75 / 80; open at 10 in Tea Hills
--   Palace gate (vermilion, big) the gatehouse passage x 6364.5..6393.5 at z 115, floor 1.9, doors 14.5 x 11; opens at 10 in Tea Hills
-- GateNBack attributes on workspace.JapanGates = where the server puts a player it walks back (the open side of each gate).
-- Also: the fence runs left a post at the start of every skipped section inside a gap - only the first of each gap stays.
-- Guarded by JapanGates attribute Boundaries2Gates. "QQ BOUNDARIES2".
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local G = workspace:FindFirstChild("JapanGates")
if not (KIT and G and G:GetAttribute("Boundaries1Fences")) then return "QQ BOUNDARIES2 ABORT: run part 1 first" end
if G:GetAttribute("Boundaries2Gates") then return "QQ BOUNDARIES2 already installed (" .. tostring(G:GetAttribute("Boundaries2Gates")) .. ")" end
local out = {}
local function say(s) table.insert(out, "QQ BOUNDARIES2 " .. s) end
local C = Color3.fromRGB
local LOOK = {
	Wood_Dark = {Enum.Material.Wood, C(86, 60, 38)}, Wood_Mid = {Enum.Material.WoodPlanks, C(150, 108, 62)}, Wood_Cap = {Enum.Material.Wood, C(66, 44, 28)},
	Vermilion = {Enum.Material.SmoothPlastic, C(200, 48, 28)}, Black = {Enum.Material.SmoothPlastic, C(28, 26, 26)}, Board = {Enum.Material.WoodPlanks, C(160, 120, 70)},
}
local function dress(m, solid)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local col = p.Name:match("__([%a_]+)$") or "Wood_Dark"           -- (the first run used %a and lost Wood_Mid etc.; fixed by size after)
			local d = LOOK[col] or LOOK.Wood_Dark
			p.Material, p.Color = d[1], d[2]
			p.Anchored = true; p.CanCollide = solid; p.CanQuery = true; p.CanTouch = false; p.CastShadow = true
			if p:IsA("MeshPart") then p.DoubleSided = false end
		end
	end
end
local DESIGN = {JF_GateWood = {0, 0}, JF_GateVermilion = {0, 0}, JF_SignBoard = {-2.6, -0.4}}
local function piece(name)
	local m = KIT[name]:Clone()
	local cf, sz = m:GetBoundingBox()
	local d = DESIGN[name]
	m.WorldPivot = CFrame.new(cf.Position.X - sz.X / 2 - d[1], cf.Position.Y - sz.Y / 2 - d[2], cf.Position.Z)
	return m
end
local function scalePiece(m, sx, sy)                     -- about the model's pivot (the hinge edge at ground)
	local pv = m.WorldPivot
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local rel = pv:ToObjectSpace(p.CFrame)
			p.Size = Vector3.new(p.Size.X * sx, p.Size.Y * sy, p.Size.Z)
			p.CFrame = pv * CFrame.new(rel.Position.X * sx, rel.Position.Y * sy, rel.Position.Z) * rel.Rotation
		end
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before boundaries2") end)

-- the extra gap posts: in each run, of consecutive " gap" posts (4 apart) keep the first along the run
local removed = 0
for _, run in ipairs(G.Walls:GetChildren()) do
	local gaps = {}
	for _, c in ipairs(run:GetChildren()) do if c.Name:find(" gap") then table.insert(gaps, c) end end
	-- the run's order: by distance along it = the order the children were added (gap posts were added in order)
	local prev
	for _, c in ipairs(gaps) do
		if prev and (c:GetPivot().Position - prev:GetPivot().Position).Magnitude < 4.5 then c:Destroy(); removed += 1 else prev = c end
		if not c.Parent then else prev = c end
	end
end
say(removed .. " extra posts inside the gate gaps removed")

local OPEN = math.rad(80)
local function gate(spec)
	-- spec: name, kind ("wood"/"vermilion"), postL, postR (Vector3 at ground), front (toward the open side), leafH, needArea,
	-- toArea, fromName, toName, back (Vector3 for the walked-back spot), backFace (Vector3 to face), sign (Vector3), signFace
	local g = Instance.new("Model"); g.Name = spec.name
	g:SetAttribute("Kind", spec.kind); g:SetAttribute("NeedArea", spec.needArea); g:SetAttribute("ToArea", spec.toArea)
	g:SetAttribute("FromName", spec.fromName); g:SetAttribute("ToName", spec.toName)
	local pL, pR = spec.postL, spec.postR
	local line = (pR - pL); local W = line.Magnitude; local lineDir = line.Unit
	local up = Vector3.yAxis
	local hingeL = CFrame.fromMatrix(pL, lineDir, up)
	local hingeR = CFrame.fromMatrix(pR, -lineDir, up)
	local zL = lineDir:Cross(up)
	local sgn = (zL:Dot(spec.front) > 0) and 1 or -1                 -- swing away from the open side
	local leafW = W / 2 - 0.05
	local pieceName = (spec.kind == "wood") and "JF_GateWood" or "JF_GateVermilion"
	for _, side in ipairs({{"LeafL", hingeL, sgn * OPEN}, {"LeafR", hingeR, -sgn * OPEN}}) do
		local leaf = piece(pieceName); dress(leaf, false)
		scalePiece(leaf, leafW / 4.0, (spec.leafH or 6.0) / 6.0)
		leaf.Name = side[1]
		leaf:SetAttribute("Hinge", side[2]); leaf:SetAttribute("OpenAngle", side[3])
		leaf:PivotTo(side[2])
		leaf.Parent = g
	end
	local blockH = spec.blockH or 9
	local block = Instance.new("Part"); block.Name = "Block"; block.Anchored = true; block.CanCollide = true; block.CanQuery = true; block.CanTouch = false
	block.Transparency = 1; block.Size = Vector3.new(W + 1, blockH, 0.8)
	block.CFrame = CFrame.fromMatrix((pL + pR) / 2 + Vector3.new(0, blockH / 2, 0), lineDir, up); block.Parent = g
	local sp = Instance.new("Part"); sp.Name = "SignPost"; sp.Anchored = true; sp.CanCollide = false; sp.CanQuery = false; sp.Transparency = 1
	sp.Size = Vector3.new(0.5, 0.5, 0.5); sp.CFrame = CFrame.new((pL + pR) / 2 + Vector3.new(0, 7, 0)); sp.Parent = g
	-- the sign board, on the open side, its text facing `signFace`
	local sb = piece("JF_SignBoard"); dress(sb, true); sb.Name = "Sign"
	local look = (spec.signFace - spec.sign) * Vector3.new(1, 0, 1)
	sb:PivotTo(CFrame.lookAt(spec.sign, spec.sign + look))         -- the board's front (+z) toward the reader... see below
	sb:PivotTo(sb:GetPivot() * CFrame.Angles(0, math.pi, 0))     -- lookAt points -z at the target; the front is +z
	local tp = Instance.new("Part"); tp.Name = "SignText"; tp.Anchored = true; tp.CanCollide = false; tp.CanQuery = false; tp.Transparency = 1
	tp.Size = Vector3.new(4.8, 1.5, 0.05)
	tp.CFrame = sb:GetPivot() * CFrame.new(0, 3.2, 0.12) * CFrame.Angles(0, math.pi, 0)
	tp.Parent = sb
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 60; sg.LightInfluence = 0.9; sg.Parent = tp
	local tl = Instance.new("TextLabel"); tl.Name = "Label"; tl.BackgroundTransparency = 1; tl.Size = UDim2.fromScale(0.94, 0.9); tl.Position = UDim2.fromScale(0.03, 0.05)
	tl.Font = Enum.Font.FredokaOne; tl.TextScaled = true; tl.TextColor3 = C(56, 36, 20); tl.TextWrapped = true
	tl.Text = spec.toName .. "\nCOMING SOON"; tl.Parent = sg
	sb.Parent = g                                                  -- (the first run forgot this line: signs added by a fix-up)
	g.Parent = G.Gates
	G:SetAttribute(spec.backKey, CFrame.lookAt(spec.back, spec.back + (spec.backFace - spec.back) * Vector3.new(1, 0, 1)))
	say(string.format("%s: %.1f wide, leaves %.1f x %.1f (%s), block %d tall; back spot %s", spec.name, W, leafW, spec.leafH or 6, spec.kind, blockH, tostring(spec.back)))
end
local V3 = Vector3.new
-- facing the gate from the open side: left post first
gate({name = "Farm bridge gate", kind = "wood", postL = V3(5748, 4.5, 75), postR = V3(5748, 4.5, 65), front = Vector3.xAxis,
	needArea = "japan_lantern", toArea = "teahills", fromName = "Lantern Street", toName = "Tea Hills",
	back = V3(5790, 4.2, 70), backFace = V3(5748, 4.2, 70), backKey = "Gate1Back", sign = V3(5748, 4.5, 59.5), signFace = V3(5790, 4.5, 59.5)})
gate({name = "Tea Hills station gate", kind = "wood", postL = V3(5621, 0.2, 117), postR = V3(5637, 0.2, 117), front = Vector3.zAxis,
	needArea = "japan_lantern", toArea = "teahills", fromName = "Lantern Street", toName = "Tea Hills",
	back = V3(5629, 0.2, 128), backFace = V3(5629, 0.2, 117), backKey = "Gate5Back", sign = V3(5642, 0.2, 121), signFace = V3(5642, 0.2, 140)})
for i, zc in ipairs({-203, -75, 80}) do
	gate({name = "Canal bridge gate " .. ({"N", "M", "S"})[i], kind = "vermilion", postL = V3(6126.5, 0, zc - 5.5), postR = V3(6126.5, 0, zc + 5.5), front = -Vector3.xAxis,
		needArea = "japan_teahills", toArea = "palace", fromName = "Tea Hills", toName = "the Palace",
		back = V3(6072, 0.3, zc), backFace = V3(6126, 0.3, zc), backKey = "Gate" .. (i + 1) .. "Back", sign = V3(6123.5, 0, zc + 9), signFace = V3(6100, 0, zc + 9)})
end
gate({name = "Palace gate", kind = "vermilion", postL = V3(6364.5, 1.9, 115), postR = V3(6393.5, 1.9, 115), front = Vector3.zAxis, leafH = 11, blockH = 18,
	needArea = "japan_teahills", toArea = "palace", fromName = "Tea Hills", toName = "the Palace",
	back = V3(6379, 1.0, 134), backFace = V3(6379, 1.0, 115), backKey = "Gate6Back", sign = V3(6400, 1.0, 131), signFace = V3(6400, 1.0, 150)})
G:SetAttribute("Boundaries2Gates", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after boundaries2") end)
say("DONE part 2 (gates + signs) - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")

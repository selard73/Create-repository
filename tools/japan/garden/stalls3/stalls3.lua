-- stalls3.lua (Oct 23 2026, after her publish of stalls2): "the backs of the stalls should be parallel with the edge of the
-- pavement and the front of the Takoyaki and Taiyaki stalls should form a V with each other"; "there is not enough on the
-- shaved ice table, it looks bare".
--  1. All four stalls square to the paving (Market paving is axis-aligned; the market's stalls sat 8 deg off): back row faces
--     +z, the leg faces +x. The Mochi turns IN PLACE about its pivot (not moved).
--  2. The Taiyaki beside the Mochi as before (backs in line, GAP). The leg now starts at the back row's FRONT line: the
--     Takoyaki's front runs on from the Taiyaki's west end and its south end sits on the Taiyaki's front line - the two counters
--     meet at one corner (her V); the Shaved ice follows north, fronts in line, LEG_GAP between. Checked against the paving's
--     north edge (z 122.5); the gaps shrink if the leg would run off it.
--  3. The shaved ice counter: two more copies of the (half-size) served set kakigori_b in the counter's free stretches.
-- Undo: Stalls3WasPivot on each stall; the copies carry Stalls3Added. Guarded by JapanMap attribute Stalls3. "QQ STALLS3".
local J = workspace:FindFirstChild("JapanMap")
local mk = J and J:FindFirstChild("Outdoor market revision")
if not mk then return "QQ STALLS3 ABORT: no market" end
if J:GetAttribute("Stalls3") then return "QQ STALLS3 already installed (" .. tostring(J:GetAttribute("Stalls3")) .. ")" end
local mochi, taiyaki, tako, ice = mk["Mochi stall"], mk["Taiyaki stall"], mk["Takoyaki stall"], mk["Shaved ice stall"]
local pav = J.LanternStreet["Market square"]["Market paving"]
local out = {}
local function say(s) table.insert(out, "QQ STALLS3 " .. s) end
local GAP, CORNER, LEG_GAP, EDGE = 2.5, 0.3, 1.2, 0.3
local function flat(v) return Vector3.new(v.X, 0, v.Z).Unit end
local function halfAlong(p, n)
	local cf, s = p.CFrame, p.Size
	return (math.abs(cf.RightVector:Dot(n)) * s.X + math.abs(cf.UpVector:Dot(n)) * s.Y + math.abs(cf.LookVector:Dot(n)) * s.Z) / 2
end
local function span(parts, origin, n)
	local lo, hi = math.huge, -math.huge
	for _, p in ipairs(parts) do
		local c = (p.Position - origin):Dot(n); local h = halfAlong(p, n)
		lo = math.min(lo, c - h); hi = math.max(hi, c + h)
	end
	return lo, hi
end
local function partsOf(m) local t = {} for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then table.insert(t, d) end end return t end
local function extents(model)
	local pv = model:GetPivot()
	local look, right = flat(pv.LookVector), flat(pv.RightVector)
	local ps = partsOf(model)
	local l0, l1 = span(ps, pv.Position, look)
	local r0, r1 = span(ps, pv.Position, right)
	return {l0 = l0, l1 = l1, r0 = r0, r1 = r1, y = pv.Position.Y}
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls3") end)

-- 3 first (in the stall's own frame): fill the shaved ice counter
do
	local pv = ice:GetPivot()
	local look, right = flat(pv.LookVector), flat(pv.RightVector)
	local counter = ice["Service counter"]
	local c0, c1 = span({counter}, pv.Position, right)
	local served = ice.kakigori_b
	local taken = {}
	for _, n in ipairs({"kakigori_a", "kakigori_b"}) do
		local lo, hi = span(partsOf(ice[n]), pv.Position, right)
		table.insert(taken, {lo, hi})
	end
	table.sort(taken, function(a, b) return a[1] < b[1] end)
	local sLo, sHi = span(partsOf(served), pv.Position, right)
	local w = sHi - sLo
	local free, at = {}, c0 + 0.3
	for _, t in ipairs(taken) do
		if t[1] - 0.25 - at >= w + 0.3 then table.insert(free, {at, t[1] - 0.25}) end
		at = math.max(at, t[2] + 0.25)
	end
	if c1 - 0.3 - at >= w + 0.3 then table.insert(free, {at, c1 - 0.3}) end
	-- one copy per free stretch, the widest first, two at most; a stretch wide enough for two gets two
	local slots = {}
	table.sort(free, function(a, b) return (a[2] - a[1]) > (b[2] - b[1]) end)
	for _, f in ipairs(free) do
		local room = f[2] - f[1]
		local k = math.min(2 - #slots, math.floor((room + 0.4) / (w + 0.4)))
		for i = 1, k do table.insert(slots, f[1] + room * (2 * i - 1) / (2 * k)) end
		if #slots >= 2 then break end
	end
	local sCf = served:GetPivot()
	local sMid = (sLo + sHi) / 2
	for i, centre in ipairs(slots) do
		local m = served:Clone()
		m.Name = "kakigori_b" .. (i + 1)
		m:SetAttribute("Stalls3Added", true); m:SetAttribute("Stalls2WasScale", nil)
		local turn = (i == 1) and CFrame.Angles(0, math.pi, 0) or CFrame.new()          -- the first copy turned round: the trays read differently
		local c = served:GetBoundingBox().Position                                        -- turned about its own middle, slid along the counter
		m:PivotTo(CFrame.new(c + right * (centre - sMid)) * turn * (CFrame.new(c):Inverse() * sCf))
		m.Parent = ice
	end
	say(string.format("shaved ice counter (%.1f long): %d more served sets of blue / rainbow bear / strawberry in its free stretches", c1 - c0, #slots))
end

-- 1-2. square to the paving, the V at the corner
local mp = mochi:GetPivot()
local P = mp.Position
local LK, RT = Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0)            -- the square's +z (the back row's customer side); west
local Rrow = CFrame.lookAt(Vector3.zero, LK).Rotation                  -- right = west
local Rleg = CFrame.lookAt(Vector3.zero, -RT).Rotation                 -- facing east; right = north
assert((Rrow.RightVector - RT).Magnitude < 1e-3 and (Rleg.RightVector - LK).Magnitude < 1e-3, "frame check")
local em, et, ek, ei = extents(mochi), extents(taiyaki), extents(tako), extents(ice)
local function at(u, v, y) return Vector3.new(P.X, y, P.Z) + RT * u + LK * v end
local function place(model, cf, label)
	if model:GetAttribute("Stalls3WasPivot") == nil then model:SetAttribute("Stalls3WasPivot", model:GetPivot()) end
	local was = model:GetPivot()
	model:PivotTo(cf)
	local turned = math.deg(math.acos(math.clamp(flat(was.LookVector):Dot(cf.LookVector), -1, 1)))
	say(string.format("%s: (%.1f, %.1f) -> (%.1f, %.1f), turned %.1f deg", label, was.X, was.Z, cf.X, cf.Z, turned))
end
place(mochi, CFrame.new(P) * Rrow, "Mochi stall (in place, squared)")
local back = em.l0
local tu, tv = em.r1 + GAP - et.r0, back - et.l0
place(taiyaki, CFrame.new(at(tu, tv, et.y)) * Rrow, "Taiyaki stall")
local taiWest, taiFront = tu + et.r1, tv + et.l1
-- the leg: a leg stall at (u, v) spans u in [u - l1, u - l0] (front at u - l1), v in [v + r0, v + r1]
local zMax = pav.Position.Z + pav.Size.Z / 2 - EDGE
local need = (ek.r1 - ek.r0) + (ei.r1 - ei.r0)
local room = (zMax - P.Z) - taiFront
local corner, legGap = CORNER, LEG_GAP
if need + corner + legGap > room then legGap = math.max(0.4, room - need - corner) end
if need + corner + legGap > room then corner = math.max(0, room - need - legGap) end
local uf = taiWest + corner
local kv = taiFront + corner - ek.r0
place(tako, CFrame.new(at(uf + ek.l1, kv, ek.y)) * Rleg, "Takoyaki stall")
local iv = kv + ek.r1 + legGap - ei.r0
place(ice, CFrame.new(at(uf + ei.l1, iv, ei.y)) * Rleg, "Shaved ice stall")
say(string.format("the V: the Taiyaki's front (z %.2f) and the Takoyaki's front (x %.2f) meet at the corner, %.1f apart; leg gap %.1f; the leg ends at z %.2f (paving edge %.2f)",
	P.Z + taiFront, P.X - uf, corner, legGap, P.Z + iv + ei.r1, zMax + EDGE))

-- checks: on the paving, overlaps
local pc, ps = pav.CFrame, pav.Size
for _, m in ipairs({mochi, taiyaki, tako, ice}) do
	local cf, sz = m:GetBoundingBox()
	local n = 0
	for _, sx in ipairs({-1, 1}) do for _, sz2 in ipairs({-1, 1}) do
		local l = pc:PointToObjectSpace(cf * Vector3.new(sx * sz.X / 2, 0, sz2 * sz.Z / 2))
		if math.abs(l.X) <= ps.X / 2 and math.abs(l.Z) <= ps.Z / 2 then n += 1 end
	end end
	say(string.format("  %s: %d of 4 corners on the paving", m.Name, n))
end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude
op.FilterDescendantsInstances = {mochi, taiyaki, tako, ice, pav, workspace.Terrain}
local hit = {}
for _, m in ipairs({mochi, taiyaki, tako, ice}) do
	for _, p in ipairs(partsOf(m)) do
		for _, q in ipairs(workspace:GetPartsInPart(p, op)) do
			if q.Transparency < 0.95 and q.Position.Y + q.Size.Y / 2 > 0.6 then hit[m.Name .. " x " .. q:GetFullName():gsub("Workspace.JapanMap.", "")] = true end
		end
	end
end
local function boxHit(a, b)
	local ca, sa = a:GetBoundingBox()
	local o = OverlapParams.new(); o.FilterType = Enum.RaycastFilterType.Include; o.FilterDescendantsInstances = {b}
	return #workspace:GetPartBoundsInBox(ca, sa - Vector3.new(0.4, 0.4, 0.4), o) > 0
end
for _, pr in ipairs({{mochi, taiyaki}, {taiyaki, tako}, {tako, ice}, {taiyaki, ice}, {mochi, tako}}) do if boxHit(pr[1], pr[2]) then hit[pr[1].Name .. " box x " .. pr[2].Name] = true end end
local hits = {}; for k in pairs(hit) do table.insert(hits, k) end
table.sort(hits)
say(#hits > 0 and ("OVERLAPS " .. table.concat(hits, " | ")) or "no overlaps")
J:SetAttribute("Stalls3", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls3") end)
say("DONE - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")

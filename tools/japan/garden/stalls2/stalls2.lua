-- stalls2.lua (Oct 23 2026): Shannon on the market stalls: "they should be lined up in an 'L' shape with the ice stall and the
-- Takoyaki stall lined up side by side and the Taiyaki and Mochi stalls lined up side by side ... leave the mochi stall where it
-- is at, and line everything else up with that one in the L shape"; "the shaved ice is comparatively way too big"; "the middle
-- white thing at the mochi stall is too big (it should be the same size as the other balls)"; the JAPAN sign "is just floating
-- and seems like it might even be a little confusing".
--  1. Mochi stall: not moved (the L is built on its frame: look = its customer side, right = its customer's left = west).
--  2. Taiyaki stall: beside the Mochi on the west, backs in one line, GAP between them.
--  3. The leg: Takoyaki (at the corner) then Shaved ice, turned to face east into the square, backs in one line, the Takoyaki's
--     south end on the back row's back line, its counter AISLE studs west of the Taiyaki's end (the paving is too shallow for the
--     leg to start in front of the back row: 50 studs from the Mochi's back to the paving's edge, the leg needs ~38 + the row's 13).
--  4. The served kakigori set (kakigori_b) at 0.5 size, still on its counter spot; the strawberry daifuku feature plate at 0.55
--     (each daifuku ~0.55 like the other mochi), still on its shelf spot.
--  5. The floating "Sign · JAPAN Tea Hills | Lantern Street | Palace" (no script uses it) -> HudBackup.Stalls2Originals.
-- Undo data: Stalls2WasPivot on each moved stall, Stalls2WasScale on each scaled model, the sign in the backup with its parent
-- path. Guarded by JapanMap attribute Stalls2. Output "QQ STALLS2".
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local mk = J and J:FindFirstChild("Outdoor market revision")
local hb = SS:FindFirstChild("HudBackup")
if not (mk and hb) then return "QQ STALLS2 ABORT: market or HudBackup missing" end
if J:GetAttribute("Stalls2") then return "QQ STALLS2 already installed (" .. tostring(J:GetAttribute("Stalls2")) .. ") - nothing done" end
local mochi, taiyaki, tako, ice = mk:FindFirstChild("Mochi stall"), mk:FindFirstChild("Taiyaki stall"), mk:FindFirstChild("Takoyaki stall"), mk:FindFirstChild("Shaved ice stall")
if not (mochi and taiyaki and tako and ice) then return "QQ STALLS2 ABORT: a stall is missing" end
local out = {}
local function say(s) table.insert(out, "QQ STALLS2 " .. s) end
local GAP, AISLE = 2.5, 6.0

local function flat(v) return Vector3.new(v.X, 0, v.Z).Unit end
local function halfAlong(p, n)
	local cf, s = p.CFrame, p.Size
	return (math.abs(cf.RightVector:Dot(n)) * s.X + math.abs(cf.UpVector:Dot(n)) * s.Y + math.abs(cf.LookVector:Dot(n)) * s.Z) / 2
end
local function extents(model)                       -- along the model's own look and right, relative to its pivot
	local pv = model:GetPivot()
	local look, right = flat(pv.LookVector), flat(pv.RightVector)
	local l0, l1, r0, r1 = math.huge, -math.huge, math.huge, -math.huge
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local d = p.Position - pv.Position
			local hl, hr = halfAlong(p, look), halfAlong(p, right)
			l0 = math.min(l0, d:Dot(look) - hl); l1 = math.max(l1, d:Dot(look) + hl)
			r0 = math.min(r0, d:Dot(right) - hr); r1 = math.max(r1, d:Dot(right) + hr)
		end
	end
	return {l0 = l0, l1 = l1, r0 = r0, r1 = r1, y = pv.Position.Y}
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls2") end)
local bk = hb:FindFirstChild("Stalls2Originals") or Instance.new("Folder"); bk.Name = "Stalls2Originals"; bk.Parent = hb

-- 4. sizes first (the stalls move as wholes afterwards)
local function rescale(model, s, label)
	local cf, sz = model:GetBoundingBox()
	if model:GetAttribute("Stalls2WasScale") == nil then model:SetAttribute("Stalls2WasScale", model:GetScale()) end
	model:ScaleTo(model:GetScale() * s)
	local cf2, sz2 = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(cf.X - cf2.X, (cf.Y - sz.Y / 2) - (cf2.Y - sz2.Y / 2), cf.Z - cf2.Z))   -- same spot, same base
	local _, sz3 = model:GetBoundingBox()
	say(string.format("%s: %.2f x %.2f x %.2f -> %.2f x %.2f x %.2f (x%.2f), base and spot kept", label, sz.X, sz.Y, sz.Z, sz3.X, sz3.Y, sz3.Z, s))
end
local served = ice:FindFirstChild("kakigori_b")
if not served then return "QQ STALLS2 ABORT: no kakigori_b on the Shaved ice stall" end
rescale(served, 0.5, "served kakigori (kakigori_b)")
local plate = mochi:FindFirstChild("Strawberry daifuku feature plate")
if not plate then return "QQ STALLS2 ABORT: no Strawberry daifuku feature plate" end
rescale(plate, 0.55, "strawberry daifuku feature plate")
do
	local card = mochi:FindFirstChild("Strawberry feature card")
	local mg = plate:FindFirstChild("mochi_geom", true)
	if card and mg then
		say(string.format("  the daifuku's top at y %.2f, the いちご大福 card's top at y %.2f", mg.Position.Y + mg.Size.Y / 2, card.Position.Y + card.Size.Y / 2))
	end
end

-- 1-3. the L on the Mochi's frame
local mp = mochi:GetPivot()
local P, Rm = mp.Position, mp.Rotation
local LK, RT = flat(mp.LookVector), flat(mp.RightVector)       -- v = along LK (the customer side), u = along RT (west)
local Rleg = CFrame.lookAt(Vector3.zero, -RT).Rotation          -- the leg faces east; its own right is then LK
local em, et, ek, ei = extents(mochi), extents(taiyaki), extents(tako), extents(ice)
local function at(u, v, y) return Vector3.new(P.X, y, P.Z) + RT * u + LK * v end
local function move(model, cf, label)
	if model:GetAttribute("Stalls2WasPivot") == nil then model:SetAttribute("Stalls2WasPivot", model:GetPivot()) end
	local was = model:GetPivot().Position
	model:PivotTo(cf)
	say(string.format("%s: (%.1f, %.1f) -> (%.1f, %.1f), facing %s", label, was.X, was.Z, cf.X, cf.Z, cf.LookVector:Dot(LK) > 0.9 and "the square (as the Mochi)" or "east into the square"))
end
local back = em.l0                                              -- the back row's back line (the Mochi's back)
-- the Taiyaki: west of the Mochi, backs in line
local tu, tv = em.r1 + GAP - et.r0, back - et.l0
move(taiyaki, CFrame.new(at(tu, tv, et.y)) * Rm, "Taiyaki stall")
local taiWest = tu + et.r1
-- the leg: backs on one line ub; a leg stall at (u, v) spans u in [u - l1, u - l0], v in [v + r0, v + r1]
local ub = taiWest + AISLE + (ek.l1 - ek.l0)
local ku, kv = ub + ek.l0, back - ek.r0
move(tako, CFrame.new(at(ku, kv, ek.y)) * Rleg, "Takoyaki stall")
local iu, iv = ub + ei.l0, kv + ek.r1 + GAP - ei.r0
move(ice, CFrame.new(at(iu, iv, ei.y)) * Rleg, "Shaved ice stall")
say(string.format("the L: back row backs on v %.2f (Mochi + Taiyaki, gap %.1f); leg backs on u %.2f, the Takoyaki's counter %.1f studs west of the Taiyaki's end", back, GAP, ub, AISLE))

-- 5. the floating sign
local sq = J.LanternStreet:FindFirstChild("Market square")
local sign
for _, c in ipairs(sq:GetChildren()) do if c:IsA("BasePart") and c.Name:find("^Sign · JAPAN") then sign = c break end end
if sign then
	sign:SetAttribute("Stalls2From", sign:GetFullName()); sign.Parent = bk
	say("the floating JAPAN / Tea Hills | Lantern Street | Palace sign moved to HudBackup.Stalls2Originals")
else
	say("no floating JAPAN sign found (already gone?)")
end

-- the paving: is every stall on it?  overlaps: what the moved stalls run into
local pav = sq:FindFirstChild("Market paving")
local pc, ps = pav.CFrame, pav.Size
for _, m in ipairs({taiyaki, tako, ice}) do
	local cf, sz = m:GetBoundingBox()
	local corners = 0
	for _, sx in ipairs({-1, 1}) do for _, sz2 in ipairs({-1, 1}) do
		local w = cf * Vector3.new(sx * sz.X / 2, 0, sz2 * sz.Z / 2)
		local l = pc:PointToObjectSpace(w)
		if math.abs(l.X) <= ps.X / 2 and math.abs(l.Z) <= ps.Z / 2 then corners += 1 end
	end end
	say(string.format("  %s: %d of 4 box corners on the paving", m.Name, corners))
end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude
op.FilterDescendantsInstances = {mochi, taiyaki, tako, ice, pav, workspace.Terrain}
local hit = {}
for _, m in ipairs({taiyaki, tako, ice}) do
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			for _, q in ipairs(workspace:GetPartsInPart(p, op)) do
				if q.Transparency < 0.95 and q.Position.Y + q.Size.Y / 2 > 0.6 then hit[m.Name .. " x " .. q:GetFullName():gsub("Workspace.JapanMap.", "")] = true end
			end
		end
	end
end
-- between the stalls themselves (boxes, 0.2 clearance)
local function boxHit(a, b)
	local ca, sa = a:GetBoundingBox()
	return #workspace:GetPartBoundsInBox(ca, sa - Vector3.new(0.4, 0.4, 0.4), (function() local o = OverlapParams.new(); o.FilterType = Enum.RaycastFilterType.Include; o.FilterDescendantsInstances = {b}; return o end)()) > 0
end
local pairsList = {{mochi, taiyaki}, {taiyaki, tako}, {tako, ice}, {taiyaki, ice}, {mochi, tako}}
for _, pr in ipairs(pairsList) do if boxHit(pr[1], pr[2]) then hit[pr[1].Name .. " box x " .. pr[2].Name] = true end end
local hits = {}; for k in pairs(hit) do table.insert(hits, k) end
table.sort(hits)
say(#hits > 0 and ("OVERLAPS " .. table.concat(hits, " | ")) or "no overlaps")
J:SetAttribute("Stalls2", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls2") end)
say("DONE - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")

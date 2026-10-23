-- stalls3d (Oct 23 2026): her "they shouldn't be all lined up in a row like that, that looks unnatural" - the three served trays
-- on the shaved ice counter set down the way a vendor would: different distances from the front edge, each turned its own way,
-- uneven gaps (the shaver / bottles / ice case end is left as it is). Each tray turns about its own middle. Checked: every tray
-- inside the counter top (0.1 margin), no two trays' footprints overlapping (oriented boxes), clear of the shaver set.
-- Undo: Stalls3dWasPivot on each tray. "QQ STALLS3D".
local ice = workspace.JapanMap["Outdoor market revision"]["Shaved ice stall"]
if ice:GetAttribute("Stalls3d") then return "QQ STALLS3D already done" end
local pv = ice:GetPivot()
local function flat(v) return Vector3.new(v.X, 0, v.Z).Unit end
local right, look = flat(pv.RightVector), flat(pv.LookVector)
local counter = ice["Service counter"]
-- (along, depth, turn in degrees) for each tray's middle, in the stall's frame: along = its right, depth = towards the customer
local PLACE = {kakigori_b = {-5.95, 4.95, 16}, kakigori_b2 = {-3.05, 3.5, -24}, kakigori_b3 = {-0.35, 4.6, 38}}
local function corners2(m)                                       -- the footprint's four corners in (along, depth)
	local cf, sz = m:GetBoundingBox()
	local t = {}
	for _, s in ipairs({{-1, -1}, {1, -1}, {1, 1}, {-1, 1}}) do
		local w = cf * Vector3.new(s[1] * sz.X / 2, 0, s[2] * sz.Z / 2)
		local d = w - pv.Position
		table.insert(t, Vector2.new(d:Dot(right), d:Dot(look)))
	end
	return t
end
local function sepAxis(a, b)                                     -- SAT for two convex quads
	for _, poly in ipairs({a, b}) do
		for i = 1, #poly do
			local e = poly[i % #poly + 1] - poly[i]
			local n = Vector2.new(-e.Y, e.X)
			local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
			for _, p in ipairs(a) do local v = p:Dot(n); amin = math.min(amin, v); amax = math.max(amax, v) end
			for _, p in ipairs(b) do local v = p:Dot(n); bmin = math.min(bmin, v); bmax = math.max(bmax, v) end
			if amax < bmin or bmax < amin then return true end
		end
	end
	return false
end
local function counterRect()
	local h = counter.Size / 2
	local c = counter.Position - pv.Position
	local ca, cd = c:Dot(right), c:Dot(look)
	local ha = math.abs(counter.CFrame.RightVector:Dot(right)) * h.X + math.abs(counter.CFrame.LookVector:Dot(right)) * h.Z
	local hd = math.abs(counter.CFrame.RightVector:Dot(look)) * h.X + math.abs(counter.CFrame.LookVector:Dot(look)) * h.Z
	return ca - ha, ca + ha, cd - hd, cd + hd
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls3d") end)
local start = {}
for name, pl in pairs(PLACE) do
	local m = ice[name]
	start[m] = m:GetPivot()
	if m:GetAttribute("Stalls3dWasPivot") == nil then m:SetAttribute("Stalls3dWasPivot", m:GetPivot()) end
	local mid = m:GetBoundingBox().Position
	local target = Vector3.new(pv.Position.X, mid.Y, pv.Position.Z) + right * pl[1] + look * pl[2]
	m:PivotTo(CFrame.new(target) * CFrame.Angles(0, math.rad(pl[3]), 0) * (CFrame.new(mid):Inverse() * m:GetPivot()))
end
-- checks
local a0, a1, d0, d1 = counterRect()
local bad = {}
local polys = {}
for name in pairs(PLACE) do
	polys[name] = corners2(ice[name])
	for _, p in ipairs(polys[name]) do
		if p.X < a0 + 0.1 or p.X > a1 - 0.1 or p.Y < d0 + 0.1 or p.Y > d1 - 0.1 then table.insert(bad, name .. " off the counter") break end
	end
end
polys.kakigori_a = corners2(ice.kakigori_a)
local names = {"kakigori_b", "kakigori_b2", "kakigori_b3", "kakigori_a"}
for i = 1, #names do for j = i + 1, #names do
	if not sepAxis(polys[names[i]], polys[names[j]]) then table.insert(bad, names[i] .. " x " .. names[j]) end
end end
if #bad > 0 then
	for m, cf in pairs(start) do m:PivotTo(cf) end
	return "QQ STALLS3D ABORT (put back): " .. table.concat(bad, ", ")
end
ice:SetAttribute("Stalls3d", "2026-10-23")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls3d") end)
return "QQ STALLS3D trays set down at different depths and turns (16, -24, 38 deg); all on the counter, none overlapping - EDIT INSTALLED; NOT PUBLISHED"

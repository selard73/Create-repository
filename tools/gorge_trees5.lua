-- gorge_trees5: CHANGES THE PLACE: removes the kit trees in workspace.SouthGorge.Trees that stood on the hills SOUTH of
-- the ridge's crest line (the land that is now the plain and the sea, 50 studs lower), and re-seats the rest on the
-- ground that is really there now (terrain, or a rock piece's top where that is higher). Reports counts.
local ZC, XCW, XCE = -547.5, 169.4583, 201.2856
local ARM_L, COVE_A, COVE_L = 130.0, 40.0, 110.0
local function ss(e0, e1, x) local t = math.clamp((x - e0) / (e1 - e0), 0, 1) return t * t * (3 - 2 * t) end
local function cove(a)
	local sc = 4 * math.sin(a / 6.4 + 1.1) * ss(6, 30, a) * (1 - ss(ARM_L - 40, ARM_L - 10, a))
	return COVE_A * ss(0, COVE_L, a) + sc
end
local function crest_z(x)
	local a = math.max(0, XCW - x, x - XCE)
	return ZC - cove(a)
end
local F = workspace.SouthGorge.Trees
local removed, kinds = 0, {}
for _, m in ipairs(F:GetChildren()) do
	local p = m:GetPivot().Position
	if p.Z < crest_z(p.X) + 6 then
		kinds[m.Name] = (kinds[m.Name] or 0) + 1
		m:Destroy(); removed += 1
	end
end
-- re-seat what is left: each tree's lowest point onto the ground under its pivot (terrain or the rock's top strip)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = {workspace.Terrain, workspace.SouthGorge.Rock}
local moved, big, dropped = 0, 0, 0
for _, m in ipairs(F:GetChildren()) do
	local cf, size = m:GetBoundingBox()
	local base = cf.Position.Y - size.Y / 2
	local piv = m:GetPivot().Position
	local r = workspace:Raycast(Vector3.new(piv.X, base + 30, piv.Z), Vector3.new(0, -120, 0), rp)
	if r then
		local dy = (r.Position.Y - 0.1) - base
		if math.abs(dy) > 0.05 then
			m:PivotTo(m:GetPivot() + Vector3.new(0, dy, 0)); moved += 1
			if math.abs(dy) > 1.5 then big += 1 end
		end
	else
		m:Destroy(); dropped += 1                                 -- no ground at all under it any more
	end
end
local kl = {}
for k, v in pairs(kinds) do kl[#kl + 1] = k .. " x" .. v end
print(string.format("QQ TR5 removed %d trees south of the crest (%s); re-seated %d (%d by more than 1.5), dropped %d with no ground; %d trees left", removed, table.concat(kl, ", "), moved, big, dropped, #F:GetChildren()))
print("QQ TR5 DONE")

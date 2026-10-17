-- propground1.lua (runner 7, Oct 17 2026): every floating prop in Japan set down on real ground. Shannon: "those rocks by the water are
-- floating in mid air, please please please, clean this up! do a good job". The quality bar (her French-village lessons): measure every
-- prop's real underside against the ground under it and fix the lot, not the one she pointed at.
-- WHAT IT DOES, for every Model or standalone MeshPart whose name says rock / boulder / stone / tree / maple / blossom / pine / persimmon /
-- cherry / wisteria / bamboo clump / lantern / bush / shrub / hedge / azalea / hydrangea (buildings, bridges, walkways, the grass sheet,
-- collision supports, cliffs and my own installs are skipped by ancestor or name; sizes 1..70 only):
--  * GROUND under it = the first thing a player could stand on: terrain that is not water, or a CanCollide part not of the prop itself
--    (the lawn's invisible floor at y 0 counts). Trees and lanterns are measured at the trunk (centre); rocks and bushes at 5 points
--    under the footprint, the highest ground wins.
--  * a prop whose bottom is more than GAP (0.25) above its ground is lowered onto it, plus a SINK (rocks 18 % of their height, bushes
--    0.3, trees 0.15, lanterns 0.03) so nothing perches on a point.
--  * a ROCK over WATER: its bottom goes to the bed if its top still clears the water by 0.6; otherwise it sits with 40 % of its height
--    out of the water AND the terrain under its footprint is filled with Sand up to its bottom, so it stands on a shoal, not on nothing.
--  * props more than 3 studs UNDER their ground (buried) are left alone and listed; so are props over nothing (no ground within 80).
-- DRY = true only reports. Every moved prop keeps its old pivot in attribute PropGroundWasCF (undo = put it back). Output "QQ PROPGROUND1".
local DRY = false
local GAP = 0.25
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ PROPGROUND1 ABORT: JapanMap missing") return end
local T = workspace.Terrain
local SKIP_ANC = {BambooMaze = true, Wayfinding = true, MomijiGarden = true, WalkFills = true, Railway = true, Church = true, MountainBackdrop = true,
	["Horizon sea"] = true, ["Koi pond set piece"] = true, ["White castle keep"] = true, ["Outdoor market revision"] = true,
	["Water basin collision supports"] = true, ["Reference collision supports"] = true, ["Water bank walking supports"] = true, ["Volcano overlook"] = true}
local KIND = {
	{"bamboo clump", "tree"}, {"maple", "tree"}, {"blossom", "tree"}, {"pine", "tree"}, {"persimmon", "tree"}, {"cherry", "tree"}, {"wisteria", "tree"}, {"tree", "tree"},
	{"lantern", "lantern"}, {"azalea", "bush"}, {"hydrangea", "bush"}, {"bush", "bush"}, {"shrub", "bush"}, {"hedge", "bush"},
	{"boulder", "rock"}, {"rock", "rock"}, {"stone", "rock"},
}
local SINK = {rock = nil, bush = 0.3, tree = 0.15, lantern = 0.03}
local function kindOf(name)
	local n = name:lower()
	if n:find("cliff") or n:find("rockface") or n:find("ridgeline") or n:find("volcano") or n:find("shore") or n:find("berm") or n:find("basin") or n:find("stepping") or n:find("slab") or n:find("wall") or n:find("coping") or n:find("path") or n:find("lantern street") or n:find("post") then return nil end
	for _, k in ipairs(KIND) do if n:find(k[1], 1, true) then return k[2] end end
	return nil
end
local function skipped(inst)
	local a = inst.Parent
	while a and a ~= J do if SKIP_ANC[a.Name] then return true end; a = a.Parent end
	return false
end
-- candidates: Models (whole), or MeshParts that are not inside a candidate Model
local cands, seen = {}, {}
local n = 0
for _, d in ipairs(J:GetDescendants()) do
	n += 1; if n % 6000 == 0 then task.wait() end
	if (d:IsA("Model") or d:IsA("MeshPart")) and kindOf(d.Name) and not skipped(d) then
		local inside = false
		local a = d.Parent
		while a and a ~= J do if seen[a] then inside = true break end; a = a.Parent end
		if not inside then
			local big = false                                                            -- a GROUP named like a rock ("Natural bank rocks") is not a rock: look inside it
			if d:IsA("Model") then local _, sz = d:GetBoundingBox(); big = math.max(sz.X, sz.Y, sz.Z) > 70 end
			if not big then seen[d] = true; table.insert(cands, d) end
		end
	end
end
local function box(inst) if inst:IsA("Model") then return inst:GetBoundingBox() end return inst.CFrame, inst.Size end
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local function groundAt(inst, x, z, fromY)
	rp.FilterDescendantsInstances = {inst}
	local o = Vector3.new(x, fromY, z)
	local water
	for _ = 1, 10 do
		local h = workspace:Raycast(o, Vector3.new(0, -80, 0), rp)
		if not h then return nil, water end
		if h.Instance == T then
			if h.Material == Enum.Material.Water then water = water or h.Position.Y else return h.Position.Y, water end
		elseif h.Instance.CanCollide and not h.Instance:IsDescendantOf(inst) then return h.Position.Y, water end
		o = h.Position - Vector3.new(0, 0.05, 0)
	end
	return nil, water
end
local moved, buried, nothing, byKind = 0, 0, 0, {}
local worst = {}
local shoals = 0
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before propground1") end)
for ci, inst in ipairs(cands) do
	if ci % 60 == 0 then task.wait() end
	local kind = kindOf(inst.Name)
	local cf, sz = box(inst)
	local long = math.max(sz.X, sz.Y, sz.Z)
	if long >= 1 and long <= 70 then
		local bottom = cf.Y - sz.Y / 2
		local pts = {{cf.X, cf.Z}}
		if kind == "rock" or kind == "bush" then
			for _, d in ipairs({{0.35, 0}, {-0.35, 0}, {0, 0.35}, {0, -0.35}}) do table.insert(pts, {cf.X + d[1] * sz.X, cf.Z + d[2] * sz.Z}) end
		end
		local g, water = nil, nil
		for _, p in ipairs(pts) do
			local gy, w = groundAt(inst, p[1], p[2], bottom + 0.6)
			if gy and (g == nil or gy > g) then g = gy end
			if w and (water == nil or w > water) then water = w end
		end
		byKind[kind] = (byKind[kind] or 0) + 1
		if g == nil and kind == "rock" and water then g = water - 4 end                   -- a rock over open water: a shoal 4 under the surface is its ground
		if g == nil then nothing += 1
		else
			local gap = bottom - g
			if gap > GAP then
				local sink = SINK[kind] or (0.18 * sz.Y)
				local target = g - sink                                                   -- the new bottom
				local shoal = false
				if kind == "rock" and water and water > g and water > target + sz.Y - 0.6 then   -- too deep: a shoal under it
					target = water - 0.6 * sz.Y
					shoal = true
				end
				if not DRY then
					if not inst:GetAttribute("PropGroundWasCF") then inst:SetAttribute("PropGroundWasCF", inst:GetPivot()) end
					local piv = inst:GetPivot()
					inst:PivotTo(piv + Vector3.new(0, target - bottom, 0))
					if shoal then
						local w, l = sz.X + 2, sz.Z + 2
						local h = (target + 0.4) - (g - 2)
						pcall(function() T:FillBlock(CFrame.new(cf.X, (target + 0.4 + g - 2) / 2, cf.Z), Vector3.new(w, h, l), Enum.Material.Sand) end)
						shoals += 1
					end
				end
				moved += 1
				table.insert(worst, {gap, string.format("%s '%s' (%.0f, %.1f, %.0f) %s gap %.2f -> %s%s", kind, inst.Name:sub(1, 26), cf.X, bottom, cf.Z, inst.ClassName:sub(1, 5), gap, DRY and "would lower" or "lowered", shoal and " on a sand shoal" or (water and " (over water, bed reached)" or ""))})
			elseif gap < -3 then buried += 1 end
		end
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after propground1") end)
table.sort(worst, function(a, b) return a[1] > b[1] end)
local kinds = {}
for k, v in pairs(byKind) do table.insert(kinds, k .. " " .. v) end
table.sort(kinds)
for i = 1, math.min(#worst, 40) do print("QQ PROPGROUND1 " .. worst[i][2]) end
print(string.format("QQ PROPGROUND1 %s: %d props looked at (%s); %d floating by more than %.2f %s, %d of them rocks over deep water given a sand shoal; %d buried > 3 left alone; %d over nothing",
	DRY and "DRY RUN" or "DONE", #cands, table.concat(kinds, ", "), moved, GAP, DRY and "(not moved)" or "lowered", shoals, buried, nothing))

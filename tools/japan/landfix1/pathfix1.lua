-- pathfix1.lua (Oct 22 2026): Shannon: "most of the ground walkways are either brown which looks fine or stone which looks fine
-- but where one is laid over the other it looks bad, like a brown carpet was laid over the stone or under it" + "it looks like
-- brown runner mats laid across each other". Cause: Japan's brown paths (variant JM_PhotographicPath) are 0.45-thick slabs with
-- tops at 0.20 / 0.25 / 0.31 / 0.40 / 0.41 / 0.46, so every crossing shows a slab edge (or flickers where two sit at the same height).
-- Fix, one cluster of touching brown slabs per run, biggest first (a merged cluster drops out of the list, so just run it again
-- until it says "none left"):
--  * every slab of the cluster to ONE height: the median top of the stone pavings it meets, else the top of its biggest slab
--  * the slabs merged into one seamless union (Pavement + JM_PhotographicPath, like before)
--  * where the cluster meets stone paving (JapanMarketStone), the brown is cut away under the stone's whole footprint, so the
--    brown path ends at the stone's edge instead of running over or under it
-- The original slabs move whole into ServerStorage.HudBackup.PathFix1Originals (attribute PathFix1From). Ramps, station platforms
-- and stairs (other height bands) are left as they are. Output "QQ PATHFIX1".
local CLUSTER = 1
local J = workspace.JapanMap
local VAR, STONE = "JM_PhotographicPath", "JapanMarketStone"
local HB = game:GetService("ServerStorage").HudBackup
local BK = HB:FindFirstChild("PathFix1Originals") or Instance.new("Folder")
BK.Name = "PathFix1Originals"; BK.Parent = HB
local function topOf(d)
	local cf, s = d.CFrame, d.Size
	local ey = math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z
	return d.Position.Y + ey / 2
end
local cand, stones = {}, {}
for _, d in ipairs(J:GetDescendants()) do
	if d:IsA("BasePart") and d.Transparency < 0.5 and d.CFrame.UpVector.Y > 0.999 and not d.Name:lower():find("slope") then
		local t = topOf(d)
		if d:IsA("Part") and d.MaterialVariant == VAR and ((t > 0.15 and t < 0.5) or (t > 3.2 and t < 3.36)) then table.insert(cand, d)
		elseif d.MaterialVariant == STONE then table.insert(stones, d) end
	end
end
local idx = {}; for i, d in ipairs(cand) do idx[d] = i end
local up = {}; for i = 1, #cand do up[i] = i end
local function root(i) while up[i] ~= i do up[i] = up[up[i]]; i = up[i] end return i end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Include; op.FilterDescendantsInstances = cand
for i, d in ipairs(cand) do
	for _, q in ipairs(workspace:GetPartsInPart(d, op)) do
		local j = idx[q]
		if j and math.abs(topOf(q) - topOf(d)) < 1 then up[root(i)] = root(j) end
	end
end
local byRoot = {}
for i, d in ipairs(cand) do local r = root(i); byRoot[r] = byRoot[r] or {}; table.insert(byRoot[r], d) end
local clusters = {}
for _, m in pairs(byRoot) do if #m >= 2 then table.insert(clusters, m) end end
local function bigArea(m) local a = 0 for _, d in ipairs(m) do a = math.max(a, d.Size.X * d.Size.Z) end return a end
table.sort(clusters, function(a, b) if #a ~= #b then return #a > #b end return bigArea(a) > bigArea(b) end)
local members = clusters[CLUSTER]
if not members then return "QQ PATHFIX1 cluster " .. tostring(CLUSTER) .. ": none left (" .. #clusters .. " clusters remain)" end

local big, area = nil, 0
local met = {}
local sop = OverlapParams.new(); sop.FilterType = Enum.RaycastFilterType.Include; sop.FilterDescendantsInstances = stones
for _, d in ipairs(members) do
	if d.Size.X * d.Size.Z > area then big, area = d, d.Size.X * d.Size.Z end
	for _, s in ipairs(workspace:GetPartsInPart(d, sop)) do met[s] = true end
end
local stoneList, stoneTops = {}, {}
for s in pairs(met) do table.insert(stoneList, s); table.insert(stoneTops, topOf(s)) end
table.sort(stoneTops)
local level = #stoneTops > 0 and stoneTops[math.ceil(#stoneTops / 2)] or topOf(big)
local home = big.Parent

pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before pathfix1 cluster " .. CLUSTER) end)
for _, d in ipairs(members) do
	if d:GetAttribute("PathFix1WasCFrame") == nil then d:SetAttribute("PathFix1WasCFrame", d.CFrame) end   -- a re-run keeps the first
	if d:GetAttribute("PathFix1From") == nil then d:SetAttribute("PathFix1From", d:GetFullName()) end
	d.CFrame = d.CFrame + Vector3.new(0, level - topOf(d), 0)
end
local rest = {}
for _, d in ipairs(members) do if d ~= big then table.insert(rest, d) end end
local ok, merged = pcall(function()
	return big:UnionAsync(rest, Enum.CollisionFidelity.PreciseConvexDecomposition, Enum.RenderFidelity.Precise)
end)
if not ok then
	for _, d in ipairs(members) do d.CFrame = d:GetAttribute("PathFix1WasCFrame") end
	return "QQ PATHFIX1 cluster " .. CLUSTER .. " UNION FAILED, heights put back: " .. tostring(merged)
end
local cut = 0
if #stoneList > 0 then
	local cutters = {}
	for _, s in ipairs(stoneList) do
		local c = Instance.new("Part")
		c.Anchored = true
		c.Size = Vector3.new(s.Size.X, 30, s.Size.Z)
		c.CFrame = CFrame.new(s.Position.X, level, s.Position.Z) * s.CFrame.Rotation
		table.insert(cutters, c)
	end
	merged.Parent = home                                          -- the CSG API needs one object in the DataModel
	local ok2, sub = pcall(function()
		return merged:SubtractAsync(cutters, Enum.CollisionFidelity.PreciseConvexDecomposition, Enum.RenderFidelity.Precise)
	end)
	for _, c in ipairs(cutters) do c:Destroy() end
	merged:Destroy()
	if ok2 then merged = sub; cut = #cutters
	else return "QQ PATHFIX1 cluster " .. CLUSTER .. " SUBTRACT FAILED (nothing placed, slabs levelled but not merged): " .. tostring(sub) end
end
merged.Name = "Walkway (merged)"
merged.Anchored = true; merged.CanCollide = true; merged.CanQuery = true; merged.CanTouch = false
merged.UsePartColor = true; merged.Color = big.Color
merged.Material = big.Material; merged.MaterialVariant = VAR
merged.CastShadow = big.CastShadow
merged:SetAttribute("PathFix1Level", level)
merged:SetAttribute("PathFix1Slabs", #members)
merged.Parent = home
for _, d in ipairs(members) do d.Parent = BK end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after pathfix1 cluster " .. CLUSTER) end)
return string.format("QQ PATHFIX1 cluster %d: %d slabs -> one seamless path at top %.2f in %s; brown cut away under %d stone paving(s); originals in HudBackup.PathFix1Originals",
	CLUSTER, #members, level, home:GetFullName():gsub("^Workspace%.", ""), cut)

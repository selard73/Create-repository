-- flicker/square_fix1: EDIT mode. With DRY = true it is READ-ONLY and only reports what it would cut.
-- Removes the hidden lower floor faces in the square so no two floor surfaces are stacked: every lower floor part is
-- CSG-cut (GeometryService:SubtractAsync) by the footprint of each part sitting on top of it, so only one surface exists
-- where they overlap. No gap is needed, nothing moves, and it looks the same from above. Pairs come from the same ray
-- grid as square_survey1 (step 0.25). The fountain (Fontana del Limone) is left alone.
-- Originals go to ServerStorage.CSGBackup_Square (attrs CSGJob, CSGBackupId, CSGOrigParent). Each union gets the
-- original's name, material, colour, attributes and tags, plus CSGJob = "square1", CSGCutFrom, CSGBackupId, CSGCutters.
-- square_undo1.lua puts everything back. Output lines start with "QQ SQF". Re-surveys at the end when not DRY.

local DRY = true   -- true: report only, change nothing. false: cut.

local CENTRE = Vector3.new(455, -12, -785)
local RADIUS = 45
local STEP = 0.25
local MAXGAP = 0.3
local FLOOR_Y_MIN, FLOOR_Y_MAX = CENTRE.Y - 8, CENTRE.Y + 8
local START_Y = CENTRE.Y + 40
local UP = 0.7
local THICK = 3
local GROW_V = 1.0       -- cutters grow this much along their vertical axis (0.5 up, 0.5 down)
local GROW_H = 0.004     -- and this much sideways (0.002 per side) so CSG never sees exactly coplanar walls
local MIN_POINTS = 3     -- a lower part is only cut when at least this many grid points (0.25 apart) are hidden under it
local NOT_FLOOR = {"cup", "saucer", "chair", "seat", "table", "squirrel", "lamp", "sign", "pot", "plant", "flower", "umbrella",
	"awning", "canopy", "bench", "cart", "crate", "barrel", "basket", "fountain", "statue", "pizza", "glass", "bottle", "menu",
	"trunk", "foliage", "crown", "bush", "hedge", "pad", "prompt", "handle", "bubble", "marker"}
local LEAVE_ALONE = {"fontana", "water"}   -- pairs whose upper or lower path contains these are never cut

if game:GetService("RunService"):IsRunning() then warn("QQ SQF ABORT - Play mode") return end

local Terrain = workspace.Terrain
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true
local excl = {}
if workspace.CurrentCamera then table.insert(excl, workspace.CurrentCamera) end
local twins = workspace:FindFirstChild("SquirrelTwins"); if twins then table.insert(excl, twins) end
params.FilterDescendantsInstances = excl

local function label(p)
	if p == Terrain then return "Terrain" end
	local names, a = {}, p
	for _ = 1, 3 do
		if not a or a == workspace or a == game then break end
		table.insert(names, 1, a.Name); a = a.Parent
	end
	return table.concat(names, ".")
end
local function vext(p)
	if p == Terrain then return 0 end
	local c, s = p.CFrame, p.Size / 2
	return 2 * (math.abs(c.RightVector.Y) * s.X + math.abs(c.UpVector.Y) * s.Y + math.abs(c.LookVector.Y) * s.Z)
end
local function topY(p) return p.Position.Y + vext(p) / 2 end
local function isNotFloorName(p)
	local n = p.Name:lower()
	for _, w in ipairs(NOT_FLOOR) do if n:find(w, 1, true) then return true end end
	return false
end
local function leaveAlone(p)
	local n = p:GetFullName():lower()
	for _, w in ipairs(LEAVE_ALONE) do if n:find(w, 1, true) then return true end end
	return false
end
local function v3(v) return string.format("(%.1f,%.2f,%.1f)", v.X, v.Y, v.Z) end
local function count(t) local c = 0; for _ in pairs(t) do c += 1 end; return c end

local function floorHit(x, z)
	local origin = Vector3.new(x, START_Y, z)
	for _ = 1, 14 do
		local r = workspace:Raycast(origin, Vector3.new(0, FLOOR_Y_MIN - 2 - origin.Y, 0), params)
		if not r then return nil end
		local p, y = r.Instance, r.Position.Y
		if y < FLOOR_Y_MIN then return nil end
		local pass = false
		if y > FLOOR_Y_MAX then
			if p ~= Terrain and vext(p) > THICK then return nil end
			pass = true
		elseif p ~= Terrain and p.Transparency >= 1 then pass = true
		elseif r.Normal.Y < UP then
			if p == Terrain then return nil end
			pass = true
		elseif p ~= Terrain and isNotFloorName(p) then pass = true
		end
		if not pass then return r end
		origin = r.Position - Vector3.new(0, 0.01, 0)
	end
	return nil
end
local function under(r1)
	local origin = r1.Position - Vector3.new(0, 0.005, 0)
	local floorY = r1.Position.Y - MAXGAP - 0.01
	for _ = 1, 8 do
		local r = workspace:Raycast(origin, Vector3.new(0, floorY - origin.Y, 0), params)
		if not r then return nil end
		local gap = r1.Position.Y - r.Position.Y
		if gap > MAXGAP then return nil end
		local p = r.Instance
		if r.Normal.Y >= UP and (p == Terrain or p.Transparency < 1) then return r, gap end
		origin = r.Position - Vector3.new(0, 0.005, 0)
	end
	return nil
end

-- survey: over[L][U] = points where U is the visible floor and L the hidden face under it
local function survey()
	local over, stacked, floors, skipped = {}, 0, 0, 0
	local n = 0
	for x = CENTRE.X - RADIUS, CENTRE.X + RADIUS, STEP do
		for z = CENTRE.Z - RADIUS, CENTRE.Z + RADIUS, STEP do
			if (Vector3.new(x, 0, z) - Vector3.new(CENTRE.X, 0, CENTRE.Z)).Magnitude <= RADIUS then
				local r1 = floorHit(x, z)
				if r1 then
					floors += 1
					local r2 = under(r1)
					if r2 then
						local U, L = r1.Instance, r2.Instance
						if L == Terrain or U == Terrain or leaveAlone(U) or leaveAlone(L) then
							skipped += 1
						else
							stacked += 1
							over[L] = over[L] or {}
							over[L][U] = (over[L][U] or 0) + 1
						end
					end
				end
			end
			n += 1
			if n % 4000 == 0 then task.wait() end
		end
	end
	return over, stacked, floors, skipped
end

local t0 = os.clock()
local over, stacked, floors, skipped = survey()
print(string.format("QQ SQF SURVEY step %.2f | floor %d | stacked %d (+%d terrain/fountain, left alone) | %.1f s", STEP, floors, stacked, skipped, os.clock() - t0))

-- a pair that goes both ways (A over B here, B over A there: two nearly coplanar pieces) is cut one way only:
-- the one that is on top at more points stays whole and cuts the other
for L, ups in pairs(over) do
	for U, nLU in pairs(ups) do
		local back = over[U] and over[U][L]
		if back then
			if back > nLU or (back == nLU and topY(L) > topY(U)) then ups[U] = nil
			else over[U][L] = nil end
		end
	end
end

-- the plan
local plan = {}
for L, ups in pairs(over) do
	local total, names = 0, {}
	for U, c in pairs(ups) do total += c; names[U.Name] = (names[U.Name] or 0) + 1 end
	if total >= MIN_POINTS then table.insert(plan, {L = L, ups = ups, total = total, names = names}) end
end
table.sort(plan, function(a, b) return a.total > b.total end)
print(string.format("QQ SQF PLAN %d parts to cut (%s):", #plan, DRY and "DRY RUN, nothing changes" or "CUTTING"))
for i, e in ipairs(plan) do
	local nl = {}
	for nm, c in pairs(e.names) do table.insert(nl, c .. "x " .. nm) end
	table.sort(nl)
	print(string.format("QQ SQF CUT %2d hidden=%-5d %s [%s] size %.2fx%.2fx%.2f top %.3f @ %s | by %d: %s", i, e.total, label(e.L), e.L.ClassName,
		e.L.Size.X, e.L.Size.Y, e.L.Size.Z, topY(e.L), v3(e.L.Position), count(e.ups), table.concat(nl, ", ")))
end
if DRY then print("QQ SQF DONE (dry run)") return end

-- cutting
local GS = game:GetService("GeometryService")
local CS = game:GetService("CollectionService")
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("CSGBackup_Square")
if not backup then backup = Instance.new("Folder"); backup.Name = "CSGBackup_Square"; backup.Parent = SS end
local stamp = os.date("%y%m%d%H%M")
local okN, failN = 0, 0
for i, e in ipairs(plan) do
	local L = e.L
	local cutters = {}
	for U in pairs(e.ups) do
		local c = U:Clone()
		for _, ch in ipairs(c:GetChildren()) do ch:Destroy() end
		local cf = c.CFrame
		local ax = {math.abs(cf.RightVector.Y), math.abs(cf.UpVector.Y), math.abs(cf.LookVector.Y)}
		local g
		if ax[1] >= ax[2] and ax[1] >= ax[3] then g = Vector3.new(GROW_V, GROW_H, GROW_H)
		elseif ax[2] >= ax[3] then g = Vector3.new(GROW_H, GROW_V, GROW_H)
		else g = Vector3.new(GROW_H, GROW_H, GROW_V) end
		c.Size = c.Size + g
		c.Anchored = true; c.CanCollide = false
		table.insert(cutters, c)
	end
	local t1 = os.clock()
	local ok, res = pcall(function()
		return GS:SubtractAsync(L, cutters, {CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition,
			RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false})
	end)
	for _, c in ipairs(cutters) do c:Destroy() end
	if not ok or type(res) ~= "table" or #res == 0 then
		failN += 1
		warn(string.format("QQ SQF CUT %2d FAILED %s: %s", i, label(L), tostring(res)))
	else
		local id = string.format("square1-%s-%02d", stamp, i)
		local parent = L.Parent
		for k, u in ipairs(res) do
			u.Name = L.Name
			u.UsePartColor = true
			u.Color = L.Color; u.Material = L.Material
			pcall(function() u.MaterialVariant = L.MaterialVariant end)
			u.Transparency = L.Transparency; u.Reflectance = L.Reflectance
			u.Anchored = true; u.CanCollide = L.CanCollide; u.CanTouch = L.CanTouch; u.CanQuery = L.CanQuery
			u.CastShadow = L.CastShadow; u.CollisionGroup = L.CollisionGroup
			for ak, av in pairs(L:GetAttributes()) do u:SetAttribute(ak, av) end
			for _, tag in ipairs(CS:GetTags(L)) do CS:AddTag(u, tag) end
			u:SetAttribute("CSGJob", "square1"); u:SetAttribute("CSGCutFrom", L.Name)
			u:SetAttribute("CSGBackupId", id); u:SetAttribute("CSGCutters", count(e.ups))
			if k == 1 then for _, ch in ipairs(L:GetChildren()) do ch.Parent = u end end
		end
		L:SetAttribute("CSGJob", "square1"); L:SetAttribute("CSGBackupId", id); L:SetAttribute("CSGOrigParent", parent:GetFullName())
		L.Parent = backup
		for _, u in ipairs(res) do u.Parent = parent end
		okN += 1
		print(string.format("QQ SQF CUT %2d ok %s -> %d union%s in %.1f s (backup id %s)", i, label(res[1]), #res, #res == 1 and "" or "s", os.clock() - t1, id))
	end
	task.wait()
end
print(string.format("QQ SQF CUTS done: %d ok, %d failed, originals in ServerStorage.CSGBackup_Square", okN, failN))

-- verify
local over2, stacked2, floors2, skipped2 = survey()
print(string.format("QQ SQF VERIFY stacked %d -> %d (floor %d, +%d terrain/fountain left alone)", stacked, stacked2, floors2, skipped2))
local left = {}
for L, ups in pairs(over2) do for U, c in pairs(ups) do table.insert(left, {k = label(U) .. "  OVER  " .. label(L), c = c}) end end
table.sort(left, function(a, b) return a.c > b.c end)
for i = 1, math.min(15, #left) do print(string.format("QQ SQF LEFT %2d n=%-4d %s", i, left[i].c, left[i].k)) end
print("QQ SQF DONE")

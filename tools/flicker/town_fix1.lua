-- flicker/town_fix1: EDIT mode. With DRY = true it is READ-ONLY and only reports. Town-wide version of square_fix1 for
-- Porto Nocciola (Oct 9: Shannon's VR shows the flicker "all over, where two things are layered": the quay at the spawn,
-- the paths, the funicular). Every (x, z) column of a grid is scanned from the sky down through ALL layers (streets, quays,
-- steps, balconies, roofs; props, squirrels and invisible parts are passed through). Two faces within MAXGAP of each other
-- in one column are a stacked pair: the lower part is cut by the upper's footprint (GeometryService:SubtractAsync), only
-- down to just below the upper's underside, so one face remains and thick parts keep their body. Terrain is reported,
-- never cut. MeshParts are reported, not cut (MESH_LOWERS). Runs synchronously with a time budget; rerun to continue
-- (cut parts no longer pair). Originals -> ServerStorage.CSGBackup_Town; unions get CSGJob = "town1" etc. (same scheme as
-- square_fix1, so town_undo1.lua walks every pass back). Output lines start with "QQ TWN".

local DRY = true            -- true: survey + plan only, nothing changes. false: cut.
local BOX = {x1 = 250, x2 = 800, z1 = -1250, z2 = -500}   -- Porto Nocciola; the square (455,-785), the bottom stop (345,-605), the Grotta (450,-1110)
local TOP_Y, BOTTOM_Y = 200, -70
local STEP = 0.5            -- grid spacing; 0.5 town-wide (~1.5M columns). The cut uses the upper's whole footprint, so a
                            -- pair only needs to be seen once.
local MAXGAP = 0.3
local UP = 0.7
local MAX_LAYERS = 24
local MIN_POINTS = 4        -- at 0.5 spacing = 1 square stud hidden under the upper before the lower is cut
local MAX_CUTS = 400        -- per run; the rest next run
local TIME_BUDGET = 240     -- seconds; the run stops cutting (and skips the verify) past this, rerun to continue
local CUT_BELOW = 0.12      -- the cut goes this far below the upper's underside (or below the lower's top, if higher)
local GROW_H = 0.004
local MESH_LOWERS = false   -- cut MeshParts that are the lower of a pair? false = report them only
local NOT_FLOOR = {"cup", "saucer", "chair", "seat", "table", "squirrel", "lamp", "sign", "pot", "plant", "flower", "umbrella",
	"awning", "canopy", "bench", "cart", "crate", "barrel", "basket", "fountain", "statue", "pizza", "glass", "bottle", "menu",
	"trunk", "foliage", "crown", "bush", "hedge", "pad", "prompt", "handle", "bubble", "marker", "pebble", "lemon", "shell",
	"acorn", "lantern", "banner", "buoy", "anchor", "lifering", "towel", "book", "cushion"}   -- no "flag" (flagstone), "oar" (board), "rope", "net", "bag" (bagno)
-- never cut, never used as a cutter (lower-case substrings of the full name)
local LEAVE_ALONE = {"fontana", "whale", "boat", "car_", "portogates", "filmmode", "photogame", "squirreltwins", "camerastops",
	"glider", "zip", "polpo", "cage", "latch", "door", "gate", "window", "shutter", "balcon"}   -- not "water": quays may be named after it

if game:GetService("RunService"):IsRunning() then warn("QQ TWN ABORT - Play mode") return end
local t0 = os.clock()
local Terrain = workspace.Terrain
local CS = game:GetService("CollectionService")
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
local function axes(p)   -- the local axis that is most vertical: 1 = X, 2 = Y, 3 = Z, and how vertical it is
	local cf = p.CFrame
	local a = {math.abs(cf.RightVector.Y), math.abs(cf.UpVector.Y), math.abs(cf.LookVector.Y)}
	local best = 1
	if a[2] > a[best] then best = 2 end
	if a[3] > a[best] then best = 3 end
	return best, a[best]
end
local function vext(p)
	if p == Terrain then return 0 end
	local c, s = p.CFrame, p.Size / 2
	return 2 * (math.abs(c.RightVector.Y) * s.X + math.abs(c.UpVector.Y) * s.Y + math.abs(c.LookVector.Y) * s.Z)
end
local function topY(p) return p.Position.Y + vext(p) / 2 end
local function bottomY(p) return p.Position.Y - vext(p) / 2 end
local function hasWord(s, words) s = s:lower(); for _, w in ipairs(words) do if s:find(w, 1, true) then return true end end return false end
local squirrelCache = {}
local function isSquirrel(p)   -- any ancestor model tagged "Squirrel"
	local a, n = p, 0
	while a and a ~= workspace and n < 6 do
		if squirrelCache[a] ~= nil then return squirrelCache[a] end
		if a:IsA("Model") and CS:HasTag(a, "Squirrel") then squirrelCache[p] = true return true end
		a = a.Parent; n += 1
	end
	squirrelCache[p] = false
	return false
end
local leaveCache = {}
local function leaveAlone(p)
	local v = leaveCache[p]
	if v == nil then v = hasWord(p:GetFullName(), LEAVE_ALONE); leaveCache[p] = v end
	return v
end
local passCache = {}
local function passThrough(p)   -- not a surface we care about: props, squirrels, invisible parts
	local v = passCache[p]
	if v == nil then v = (p ~= Terrain) and (p.Transparency >= 1 or hasWord(p.Name, NOT_FLOOR) or isSquirrel(p)); passCache[p] = v end
	return v
end
local function v3(v) return string.format("(%.1f,%.2f,%.1f)", v.X, v.Y, v.Z) end
local function count(t) local c = 0; for _ in pairs(t) do c += 1 end; return c end
local function bump(t, k, n) t[k] = (t[k] or 0) + (n or 1) end

-- all visible upward faces in one column, top to bottom
local function column(x, z, out)
	local origin = Vector3.new(x, TOP_Y, z)
	local n = 0
	for _ = 1, MAX_LAYERS do
		local r = workspace:Raycast(origin, Vector3.new(0, BOTTOM_Y - origin.Y, 0), params)
		if not r then break end
		local p = r.Instance
		if r.Normal.Y >= UP and not passThrough(p) then n += 1; out[n] = p; out[n + MAX_LAYERS] = r.Position.Y end
		origin = r.Position - Vector3.new(0, 0.01, 0)
	end
	return n
end

-- survey: over[L][U] = columns where U's face sits within MAXGAP above L's face
local function survey(budget)
	local over, terrainUnder, alone = {}, {}, 0
	local columns, faces, stackedPts = 0, 0, 0
	local buf = {}
	local nx = 0
	for x = BOX.x1, BOX.x2, STEP do
		for z = BOX.z1, BOX.z2, STEP do
			columns += 1
			local n = column(x, z, buf)
			faces += n
			for i = 1, n - 1 do
				for j = i + 1, n do
					local gap = buf[i + MAX_LAYERS] - buf[j + MAX_LAYERS]
					if gap > MAXGAP then break end
					local U, L = buf[i], buf[j]
					if U ~= L then
						if L == Terrain then bump(terrainUnder, label(U))
						elseif U == Terrain or leaveAlone(U) or leaveAlone(L) then alone += 1
						else
							stackedPts += 1
							over[L] = over[L] or {}
							bump(over[L], U)
						end
					end
				end
			end
		end
		nx += 1
		if nx % 8 == 0 then task.wait() end
		if budget and os.clock() - t0 > budget then return nil, columns end
	end
	return over, columns, faces, stackedPts, terrainUnder, alone
end

print(string.format("QQ TWN SURVEY box x %d..%d z %d..%d step %.2f maxgap %.2f (%s)", BOX.x1, BOX.x2, BOX.z1, BOX.z2, STEP, MAXGAP, DRY and "DRY RUN, nothing changes" or "CUTTING"))
local over, columns, faces, stackedPts, terrainUnder, alone = survey(TIME_BUDGET * 0.6)
if not over then warn(string.format("QQ TWN ABORT - survey ran out of time after %d columns; raise TIME_BUDGET or STEP", columns)) return end
print(string.format("QQ TWN columns %d | faces %d | stacked pairs seen %d | left alone (water, whale, boats, cars, gates, ...) %d | %.0f s", columns, faces, stackedPts, alone, os.clock() - t0))

-- a pair that goes both ways is cut one way only: the one that is on top at more points stays whole
for L, ups in pairs(over) do
	for U, nLU in pairs(ups) do
		local back = over[U] and over[U][L]
		if back then
			if back > nLU or (back == nLU and topY(L) > topY(U)) then ups[U] = nil else over[U][L] = nil end
		end
	end
end

-- the plan
local plan, meshSkipped, byName = {}, {}, {}
for L, ups in pairs(over) do
	local total, names = 0, {}
	for U, c in pairs(ups) do total += c; bump(names, U.Name) end
	if total >= MIN_POINTS then
		if L:IsA("MeshPart") and not MESH_LOWERS then bump(meshSkipped, label(L), total)
		else
			table.insert(plan, {L = L, ups = ups, total = total, names = names})
			for U, c in pairs(ups) do bump(byName, U.Name .. "  OVER  " .. L.Name, c) end
		end
	end
end
table.sort(plan, function(a, b) return a.total > b.total end)
local planPts = 0
for _, e in ipairs(plan) do planPts += e.total end
print(string.format("QQ TWN PLAN %d parts to cut covering %d stacked points (MIN_POINTS %d)", #plan, planPts, MIN_POINTS))
local bn = {}
for k, c in pairs(byName) do table.insert(bn, {k = k, c = c}) end
table.sort(bn, function(a, b) return a.c > b.c end)
for i = 1, math.min(40, #bn) do print(string.format("QQ TWN PAIR %2d n=%-6d %s", i, bn[i].c, bn[i].k)) end
for i = 1, math.min(25, #plan) do
	local e = plan[i]
	local nl = {}
	for nm, c in pairs(e.names) do table.insert(nl, c .. "x " .. nm) end
	table.sort(nl)
	print(string.format("QQ TWN CUT %3d hidden=%-6d %s [%s] size %.2fx%.2fx%.2f top %.3f @ %s | by %d: %s", i, e.total, label(e.L), e.L.ClassName,
		e.L.Size.X, e.L.Size.Y, e.L.Size.Z, topY(e.L), v3(e.L.Position), count(e.ups), table.concat(nl, ", ")))
end
if #plan > 25 then print(string.format("QQ TWN ... and %d more parts (smaller)", #plan - 25)) end
local tu = {}
for k, c in pairs(terrainUnder) do table.insert(tu, {k = k, c = c}) end
table.sort(tu, function(a, b) return a.c > b.c end)
print(string.format("QQ TWN TERRAIN under a part within %.1f (not cut): %d kinds, top 10:", MAXGAP, #tu))
for i = 1, math.min(10, #tu) do print(string.format("QQ TWN TERRAIN %2d n=%-6d %s", i, tu[i].c, tu[i].k)) end
local ms = {}
for k, c in pairs(meshSkipped) do table.insert(ms, {k = k, c = c}) end
table.sort(ms, function(a, b) return a.c > b.c end)
if #ms > 0 then
	print(string.format("QQ TWN MESH lowers skipped (MESH_LOWERS false): %d, top 10:", #ms))
	for i = 1, math.min(10, #ms) do print(string.format("QQ TWN MESH %2d n=%-6d %s", i, ms[i].c, ms[i].k)) end
end
if DRY then print(string.format("QQ TWN DONE (dry run) %.0f s", os.clock() - t0)) return end

-- cutting
local GS = game:GetService("GeometryService")
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("CSGBackup_Town")
if not backup then backup = Instance.new("Folder"); backup.Name = "CSGBackup_Town"; backup.Parent = SS end
local stamp = os.date("%y%m%d%H%M")
local okN, failN, doneN = 0, 0, 0
for i, e in ipairs(plan) do
	if i > MAX_CUTS then print(string.format("QQ TWN stopped at MAX_CUTS %d; %d parts left for the next run", MAX_CUTS, #plan - MAX_CUTS)) break end
	if os.clock() - t0 > TIME_BUDGET then print(string.format("QQ TWN stopped at the time budget after %d cuts; %d parts left for the next run", doneN, #plan - doneN)) break end
	local L = e.L
	local Ltop = topY(L)
	local cutters = {}
	for U in pairs(e.ups) do
		local c = U:Clone()
		for _, ch in ipairs(c:GetChildren()) do ch:Destroy() end
		local ax, vert = axes(c)
		local s = c.Size
		if vert > 0.9 then
			-- upright: top = U's top + 0.5, bottom = just below U's underside (or below L's top if U's underside is lower than that)
			local newTop = topY(U) + 0.5
			local newBottom = math.min(bottomY(U), Ltop) - CUT_BELOW
			local h = newTop - newBottom
			local sz = {s.X + GROW_H, s.Y + GROW_H, s.Z + GROW_H}
			sz[ax] = h
			c.Size = Vector3.new(sz[1], sz[2], sz[3])
			local centreY = (newTop + newBottom) / 2
			c.CFrame = c.CFrame + Vector3.new(0, centreY - c.Position.Y, 0)
		else
			-- tilted (ramp, slope): grow 0.5 each way along its most vertical axis, as square_fix1 did
			local sz = {s.X + GROW_H, s.Y + GROW_H, s.Z + GROW_H}
			sz[ax] = sz[ax] + 1.0
			c.Size = Vector3.new(sz[1], sz[2], sz[3])
		end
		c.Anchored = true; c.CanCollide = false
		table.insert(cutters, c)
	end
	local t1 = os.clock()
	local ok, res = pcall(function()
		return GS:SubtractAsync(L, cutters, {CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition,
			RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false})
	end)
	for _, c in ipairs(cutters) do c:Destroy() end
	doneN += 1
	if not ok or type(res) ~= "table" or #res == 0 then
		failN += 1
		warn(string.format("QQ TWN CUT %3d FAILED %s: %s", i, label(L), tostring(res)))
	else
		local id = string.format("town1-%s-%04d", stamp, i)
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
			u:SetAttribute("CSGJob", "town1"); u:SetAttribute("CSGCutFrom", L.Name)
			u:SetAttribute("CSGBackupId", id); u:SetAttribute("CSGCutters", count(e.ups))
			u:SetAttribute("CSGRestoreFrom", nil); u:SetAttribute("CSGIntermediate", nil)
			if k == 1 then for _, ch in ipairs(L:GetChildren()) do ch.Parent = u end end
		end
		local prevJob = L:GetAttribute("CSGJob")
		if prevJob == "town1" or prevJob == "square1" then   -- L is itself a cut from an earlier pass: keep the link to ITS original
			L:SetAttribute("CSGRestoreFrom", L:GetAttribute("CSGBackupId")); L:SetAttribute("CSGIntermediate", true)
			L:SetAttribute("CSGPrevJob", prevJob)
		end
		L:SetAttribute("CSGJob", "town1"); L:SetAttribute("CSGBackupId", id); L:SetAttribute("CSGOrigParent", parent:GetFullName())
		L.Parent = backup
		for _, u in ipairs(res) do u.Parent = parent end
		okN += 1
		if okN % 25 == 0 or i <= 5 then print(string.format("QQ TWN CUT %3d ok %s -> %d union%s in %.1f s", i, label(res[1]), #res, #res == 1 and "" or "s", os.clock() - t1)) end
	end
	if doneN % 5 == 0 then task.wait() end
end
print(string.format("QQ TWN CUTS done: %d ok, %d failed, %d of %d planned, originals in ServerStorage.CSGBackup_Town | %.0f s", okN, failN, doneN, #plan, os.clock() - t0))

-- verify, if there is time
if os.clock() - t0 < TIME_BUDGET then
	local over2, c2, f2, s2, _, a2 = survey(TIME_BUDGET)
	if over2 then
		print(string.format("QQ TWN VERIFY stacked points %d -> %d (columns %d, faces %d, left alone %d)", stackedPts, s2, c2, f2, a2))
		local left = {}
		for L, ups in pairs(over2) do for U, c in pairs(ups) do bump(left, U.Name .. "  OVER  " .. L.Name, c) end end
		local ll = {}
		for k, c in pairs(left) do table.insert(ll, {k = k, c = c}) end
		table.sort(ll, function(a, b) return a.c > b.c end)
		for i = 1, math.min(20, #ll) do print(string.format("QQ TWN LEFT %2d n=%-6d %s", i, ll[i].c, ll[i].k)) end
	else
		print("QQ TWN VERIFY skipped (time budget); run the DRY survey to see what is left")
	end
else
	print("QQ TWN VERIFY skipped (time budget); run the DRY survey to see what is left")
end
print(string.format("QQ TWN DONE %.0f s", os.clock() - t0))

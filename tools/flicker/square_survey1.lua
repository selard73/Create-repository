-- flicker/square_survey1: READ-ONLY. Ray-grid survey of the square (Piazza del Limone / Via della Piazza) for STACKED
-- floor surfaces. For every grid point: the first floor surface hit from above, then the next upward-facing surface
-- underneath within MAXGAP. Shannon's headset flickers wherever two floor faces sit within ~0.3 of each other
-- (Oct 8: the ZFix2 gaps of 0.02-0.06 and the bottom-stop CSG pilot still flickered), so the target is 0 stacked points.
-- Changes nothing. Run in EDIT mode. Output lines all start with "QQ SQ1". Save the Output as square_survey1_out.txt.

local CENTRE = Vector3.new(455, -12, -785)      -- the square: VR test pads at (458,-11.85,-783) and (452,-11.85,-786)
local RADIUS = 45                                -- survey disc radius (studs); the Oct 8 survey used r45
local STEP = 0.5                                 -- grid spacing; 0.25 = 4x the points, use it for the final check
local MAXGAP = 0.3                               -- a 2nd top face this close under the floor counts as stacked
local FLOOR_Y_MIN, FLOOR_Y_MAX = CENTRE.Y - 8, CENTRE.Y + 8   -- a floor hit must be in this band (steps up/down from the square)
local START_Y = CENTRE.Y + 40                    -- rays start here and go down
local UP = 0.7                                   -- hit normal.Y at least this = a top face you can stand on
local THICK = 3                                  -- a non-floor hit above the band on a part this tall = we are over a building: skip the point
-- things a ray can land on first inside the floor band that are not floor: the ray passes through them
local NOT_FLOOR = {"cup", "saucer", "chair", "seat", "table", "squirrel", "lamp", "sign", "pot", "plant", "flower", "umbrella",
	"awning", "canopy", "bench", "cart", "crate", "barrel", "basket", "fountain", "statue", "pizza", "glass", "bottle", "menu",
	"trunk", "foliage", "crown", "bush", "hedge", "pad", "prompt", "handle", "bubble", "marker"}

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
local function vext(p)   -- vertical extent of a part's bounding box
	if p == Terrain then return 0 end
	local c, s = p.CFrame, p.Size / 2
	return 2 * (math.abs(c.RightVector.Y) * s.X + math.abs(c.UpVector.Y) * s.Y + math.abs(c.LookVector.Y) * s.Z)
end
local function isNotFloorName(p)
	local n = p.Name:lower()
	for _, w in ipairs(NOT_FLOOR) do if n:find(w, 1, true) then return true end end
	return false
end

local skipped, noFloor = {}, {}
local function bump(t, k) t[k] = (t[k] or 0) + 1 end

-- first floor surface under (x, z): returns the RaycastResult, or nil + reason
local function floorHit(x, z)
	local origin = Vector3.new(x, START_Y, z)
	for _ = 1, 14 do
		local r = workspace:Raycast(origin, Vector3.new(0, FLOOR_Y_MIN - 2 - origin.Y, 0), params)
		if not r then return nil, "nothing in band" end
		local p, y = r.Instance, r.Position.Y
		if y < FLOOR_Y_MIN then return nil, "below band" end
		local pass = false
		if y > FLOOR_Y_MAX then
			if p ~= Terrain and vext(p) > THICK then return nil, "over a building" end
			pass = true
		elseif p ~= Terrain and p.Transparency >= 1 then pass = true
		elseif r.Normal.Y < UP then
			if p == Terrain then return nil, "terrain slope" end
			pass = true
		elseif p ~= Terrain and isNotFloorName(p) then pass = true
		end
		if not pass then return r end
		bump(skipped, label(p))
		origin = r.Position - Vector3.new(0, 0.01, 0)
	end
	return nil, "too many layers"
end

-- next visible top face under the floor hit within MAXGAP: returns RaycastResult + gap, or nil
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

local t0 = os.clock()
local points, floors, stacked = 0, 0, 0
local buckets = {0, 0, 0, 0}   -- gap < 0.015, < 0.05, < 0.1, <= MAXGAP
local pairsT = {}              -- "upper OVER lower" -> stats
local visible, hidden = {}, {} -- part -> count as the first floor hit / as a hidden 2nd surface
local n = 0
for x = CENTRE.X - RADIUS, CENTRE.X + RADIUS, STEP do
	for z = CENTRE.Z - RADIUS, CENTRE.Z + RADIUS, STEP do
		if (Vector3.new(x, 0, z) - Vector3.new(CENTRE.X, 0, CENTRE.Z)).Magnitude <= RADIUS then
			points += 1
			local r1, why = floorHit(x, z)
			if not r1 then
				bump(noFloor, why)
			else
				floors += 1
				bump(visible, r1.Instance)
				local r2, gap = under(r1)
				if r2 and gap then
					stacked += 1
					bump(hidden, r2.Instance)
					if gap < 0.015 then buckets[1] += 1 elseif gap < 0.05 then buckets[2] += 1 elseif gap < 0.1 then buckets[3] += 1 else buckets[4] += 1 end
					local key = label(r1.Instance) .. "  OVER  " .. label(r2.Instance)
					local s = pairsT[key]
					if not s then s = {n = 0, gmin = 1e9, gmax = -1e9, up = {}, low = {}, ex = r1.Position}; pairsT[key] = s end
					s.n += 1; s.gmin = math.min(s.gmin, gap); s.gmax = math.max(s.gmax, gap)
					s.up[r1.Instance] = true; s.low[r2.Instance] = true
				end
			end
		end
		n += 1
		if n % 4000 == 0 then task.wait() end
	end
end

local function count(t) local c = 0; for _ in pairs(t) do c += 1 end; return c end
local function v3(v) return string.format("(%.1f,%.2f,%.1f)", v.X, v.Y, v.Z) end

print(string.format("QQ SQ1 SURVEY centre %s r%d step %.2f maxgap %.2f band y %.0f..%.0f | %.1f s", v3(CENTRE), RADIUS, STEP, MAXGAP, FLOOR_Y_MIN, FLOOR_Y_MAX, os.clock() - t0))
print(string.format("QQ SQ1 points %d | floor found %d | stacked %d (%.1f%% of floor) | gap <0.015: %d  <0.05: %d  <0.1: %d  <=%.1f: %d",
	points, floors, stacked, floors > 0 and 100 * stacked / floors or 0, buckets[1], buckets[2], buckets[3], MAXGAP, buckets[4]))

local nf = {}
for k, v in pairs(noFloor) do table.insert(nf, string.format("%s %d", k, v)) end
table.sort(nf)
print("QQ SQ1 no floor: " .. (#nf > 0 and table.concat(nf, " | ") or "none"))

local sk = {}
for k, v in pairs(skipped) do table.insert(sk, {k = k, v = v}) end
table.sort(sk, function(a, b) return a.v > b.v end)
local skl = {}
for i = 1, math.min(15, #sk) do table.insert(skl, string.format("%s %d", sk[i].k, sk[i].v)) end
print("QQ SQ1 passed through (not floor), top 15: " .. (#skl > 0 and table.concat(skl, " | ") or "none"))

local pl = {}
for k, s in pairs(pairsT) do table.insert(pl, {k = k, s = s}) end
table.sort(pl, function(a, b) return a.s.n > b.s.n end)
print(string.format("QQ SQ1 PAIRS %d distinct (upper OVER lower), top %d by points:", #pl, math.min(30, #pl)))
for i = 1, math.min(30, #pl) do
	local s = pl[i].s
	print(string.format("QQ SQ1 PAIR %2d n=%-5d gap %.3f..%.3f  up %dx low %dx | %s  @ %s", i, s.n, s.gmin, s.gmax, count(s.up), count(s.low), pl[i].k, v3(s.ex)))
end

-- the hidden lower parts: which ones never show their top anywhere in the disc (candidates to sink / trim)
local hl = {}
for p, c in pairs(hidden) do if c >= 5 then table.insert(hl, {p = p, c = c}) end end
table.sort(hl, function(a, b) return a.c > b.c end)
print(string.format("QQ SQ1 LOWER PARTS with >= 5 hidden points: %d, top %d:", #hl, math.min(25, #hl)))
for i = 1, math.min(25, #hl) do
	local p, c = hl[i].p, hl[i].c
	local vis = visible[p] or 0
	local size, top = "terrain", "-"
	if p ~= Terrain then
		size = string.format("%.2fx%.2fx%.2f", p.Size.X, p.Size.Y, p.Size.Z)
		top = string.format("%.3f", p.Position.Y + vext(p) / 2)
	end
	print(string.format("QQ SQ1 LOW %2d hidden=%-5d visible=%-5d %s size %s top %s | %s @ %s", i, c, vis,
		vis == 0 and "NO VISIBLE TOP IN DISC" or "partly visible", size, top, label(p), p ~= Terrain and v3(p.Position) or "-"))
end
print("QQ SQ1 DONE")

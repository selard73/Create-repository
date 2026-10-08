-- falls_rocks2 v2: CHANGES THE PLACE (scenery only: no scripts, no save data). Replaces the RapidsRocks model with rocks of
-- the game's own shape, randomly spaced. Shannon (23:20): the rapids rocks must be the same shape and look as the rocks at the
-- start of the game, i.e. the smooth rounded forest-kit rocks (workspace.ForestKit.rock_big Rock1-3 and rock_cluster
-- Rock1-4, the same meshes as the river's FishRocks by the village), in the village river rocks' grey; and (23:22) not evenly
-- spaced: random. Layout: a broken line at the rapids' head (z ~ -492..-499, positions jittered) keeping a 13-stud clear boat
-- lane on the river's centre line, plus rocks scattered at random down the run (random z, random bank, random distance
-- from the lane edge to the bank, random size; a third of them get a small companion so they cluster), rejected if they
-- would overlap one already placed. Seated by raycast (in water 45-60% of the height shows; on a bank sunk 30%), anchored,
-- CanCollide OFF, random yaw and slight tilt. Fixed seed (11): re-running gives the same rocks. Re-running replaces the model.
local ZC, WATER_Y = -547.5, -0.9
local CHANNEL_HALF = 6.5
local COLOR = Color3.fromRGB(150, 152, 160)              -- workspace.River.FishRocks (the rocks in the river at the start)
local RIVER = {{-547.10, 184.12, 14.06}, {-543.10, 186.76, 14.36}, {-539.10, 188.95, 14.81}, {-535.10, 190.98, 15.03}, {-531.10, 193.10, 15.15}, {-527.10, 195.14, 15.19}, {-523.10, 196.87, 14.86}, {-519.10, 198.49, 14.18}, {-515.10, 199.97, 13.33}, {-511.10, 200.75, 12.69}, {-507.10, 200.58, 12.44}, {-503.10, 199.80, 12.17}, {-499.10, 198.84, 11.93}, {-495.10, 197.34, 12.27}}
local function river_at(z)
	if z <= RIVER[1][1] then return RIVER[1][2], RIVER[1][3] end
	for i = 1, #RIVER - 1 do
		local p, q = RIVER[i], RIVER[i + 1]
		if z >= p[1] and z <= q[1] then
			local t = (z - p[1]) / (q[1] - p[1])
			return p[2] + (q[2] - p[2]) * t, p[3] + (q[3] - p[3]) * t
		end
	end
	return RIVER[#RIVER][2], RIVER[#RIVER][3]
end
local FK = workspace:FindFirstChild("ForestKit"); assert(FK, "workspace.ForestKit missing")
local big, clu = FK:FindFirstChild("rock_big"), FK:FindFirstChild("rock_cluster"); assert(big and clu, "ForestKit rock_big / rock_cluster missing")
local SRC = {B1 = big.Rock1, B2 = big.Rock2, B3 = big.Rock3, C1 = clu.Rock1, C2 = clu.Rock3, C3 = clu.Rock2}
for k, v in pairs(SRC) do assert(v and v:IsA("MeshPart"), "source " .. k .. " missing") end
local rng = Random.new(11)
local function pick(t) return t[rng:NextInteger(1, #t)] end
-- {z, dx from the river centre (negative = west), source, scale, share of height above the water}
local ROCKS = {}
-- the line at the head of the rapids: big flat boulders either side of the lane, a bank rock each side, each jittered
for _, h in ipairs({{-495.5, -10.3, "B1", 1.35}, {-492.0, -8.3, "B3", 1.5}, {-494.5, 10.2, "B2", 1.8}, {-498.5, 8.9, "B1", 1.0}, {-497.0, 14.2, "B2", 1.3}, {-498.5, -15.3, "C1", 1.4}}) do
	ROCKS[#ROCKS + 1] = {h[1] + rng:NextNumber(-2, 2), h[2] + rng:NextNumber(-1.5, 1.5), h[3], h[4] * rng:NextNumber(0.9, 1.1), rng:NextNumber(0.5, 0.6)}
end
-- the scatter down the run: random, with clusters, no overlaps
local KINDS = {"B1", "B2", "B2", "B3", "B3", "C1", "C1", "C2", "C3"}
local SCALE = {B1 = {0.7, 1.0}, B2 = {0.8, 1.3}, B3 = {1.1, 1.7}, C1 = {1.1, 1.6}, C2 = {1.2, 1.7}, C3 = {1.3, 1.8}}
local function footprint(k, s) local sz = SRC[k].Size * s; return math.max(sz.X, sz.Z) / 2 end
local function clear(z, x, r)
	for _, o in ipairs(ROCKS) do
		local cx0 = river_at(o[1])
		local d = (Vector2.new(x, z) - Vector2.new(cx0 + o[2], o[1])).Magnitude
		if d < (r + footprint(o[3], o[4])) * 0.85 then return false end
	end
	return true
end
local want, tries = 14, 0
while #ROCKS < 6 + want and tries < 400 do
	tries += 1
	local z = rng:NextNumber(-543, -501)
	local cx, hw = river_at(z)
	local side = (rng:NextNumber() < 0.5) and -1 or 1
	local k = pick(KINDS)
	local s = rng:NextNumber(SCALE[k][1], SCALE[k][2])
	local r = footprint(k, s)
	local dx = side * rng:NextNumber(CHANNEL_HALF + r + 0.3, hw + 1.5)
	if dx * side >= CHANNEL_HALF + r and clear(z, cx + dx, r) then
		ROCKS[#ROCKS + 1] = {z, dx, k, s, rng:NextNumber(0.45, 0.6)}
		if rng:NextNumber() < 0.35 then                        -- a small companion beside it: rocks come in groups
			local k2 = pick({"B3", "C1", "C2", "C3"})
			local s2 = rng:NextNumber(SCALE[k2][1], SCALE[k2][2])
			local r2 = footprint(k2, s2)
			local z2 = z + rng:NextNumber(-4, 4)
			local cx2, hw2 = river_at(z2)
			local dx2 = dx + side * rng:NextNumber(r + r2 + 0.3, r + r2 + 2.5) * (rng:NextNumber() < 0.5 and 1 or -1)
			if dx2 * side >= CHANNEL_HALF + r2 and dx2 * side <= hw2 + 2 and clear(z2, cx2 + dx2, r2) then
				ROCKS[#ROCKS + 1] = {z2, dx2, k2, s2, rng:NextNumber(0.45, 0.6)}
			end
		end
	end
end
local G = workspace.SouthGorge
local old = G:FindFirstChild("RapidsRocks"); if old then old:Destroy() end
local M = Instance.new("Model"); M.Name = "RapidsRocks"; M.Parent = G
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain}; rp.IgnoreWater = false
local function aabbHalfX(cf, size)
	local r = cf.Rotation
	return math.abs(r.XVector.X) * size.X / 2 + math.abs(r.YVector.X) * size.Y / 2 + math.abs(r.ZVector.X) * size.Z / 2
end
table.sort(ROCKS, function(a, b) return a[1] > b[1] end)      -- upstream first in the report
local placed, nudged, lines = 0, 0, {}
for i, R in ipairs(ROCKS) do
	local z, dx, k, s, show = R[1], R[2], R[3], R[4], R[5]
	local cx = river_at(z)
	local src = SRC[k]
	local p = src:Clone()
	p.Name = string.format("Rock_%02d", i)
	p.Size = src.Size * s
	p.Color = COLOR; p.Material = Enum.Material.SmoothPlastic; p.Transparency = 0; p.LocalTransparencyModifier = 0   -- the kit templates are invisible
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = true; p.CastShadow = true
	local yaw = rng:NextNumber(0, 2 * math.pi)
	local tilt = CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), 0, math.rad(rng:NextNumber(-10, 10)))
	local rot = CFrame.Angles(0, yaw, 0) * tilt
	local x = cx + dx
	local hx = aabbHalfX(rot, p.Size)
	local inner = (dx < 0) and (x + hx) or (x - hx)
	local limit = (dx < 0) and (cx - CHANNEL_HALF) or (cx + CHANNEL_HALF)
	if (dx < 0 and inner > limit) or (dx > 0 and inner < limit) then x = x + (limit - inner); nudged += 1 end
	local h = p.Size.Y
	local hit = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -80, 0), rp)
	local y, where
	if hit and hit.Material ~= Enum.Material.Water and hit.Position.Y > WATER_Y + 0.05 then
		y = hit.Position.Y + h * 0.2; where = "bank"
	else
		y = WATER_Y - h * (0.5 - show); where = "water"
	end
	p.CFrame = CFrame.new(x, y, z) * rot
	p.Parent = M
	placed += 1
	lines[#lines + 1] = string.format("%02d %s x%.1f z%.0f w%.1f top+%.1f %s", i, k, x, z, math.max(p.Size.X, p.Size.Z), y + h / 2 - WATER_Y, where)
end
local westMax, eastMin = -math.huge, math.huge
for _, p in ipairs(M:GetChildren()) do
	if p.Position.Z > -500 and p.Position.Z < -490 then
		local cx = river_at(p.Position.Z)
		local hx = aabbHalfX(p.CFrame, p.Size)
		if p.Position.X < cx then westMax = math.max(westMax, p.Position.X + hx) else eastMin = math.min(eastMin, p.Position.X - hx) end
	end
end
print(string.format("QQ RK2 placed %d forest-kit rocks (%d nudged, %d tries); head line clear lane x %.1f..%.1f = %.1f studs (boat 4.1); colour %s", placed, nudged, tries, westMax, eastMin, eastMin - westMax, tostring(COLOR)))
print("QQ RK2 " .. table.concat(lines, " | "))
print("QQ RK2 DONE")

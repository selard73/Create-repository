-- falls_rocks1 v1: CHANGES THE PLACE (scenery only: no scripts, no save data). Her note 3 and her ask of 23:10: rocks in the
-- rapids. Builds workspace.SouthGorge.RapidsRocks from clones of the Sandstone Climb boulders in ServerStorage.SandCliffKit
-- (the gorge's own cream sandstone, textured): a broken line of half-sunk boulders across the river at the rapids' head
-- (z -492..-499, where the white water starts) with a CLEAR CHANNEL of 13 studs on the river's centre line for the boat
-- (4.1 wide), plus a scatter of smaller rocks down the run, alternating banks, none inside the channel, a few on the
-- bank edges. Every rock is seated by raycast: in water its centre sits so 35-55% of its height shows; on a bank it sinks
-- 30% into the ground. All anchored, CanCollide OFF (nothing can snag the boat or a swimmer), random yaw and a slight
-- tilt from a fixed seed so re-running gives the same rocks. Re-running replaces the model.
local ZC, WATER_Y = -547.5, -0.9
local CHANNEL_HALF = 6.5                                   -- the boat lane: 13 studs centred on the river's centre line
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
local kit = game:GetService("ServerStorage"):FindFirstChild("SandCliffKit")
assert(kit, "ServerStorage.SandCliffKit missing")
local SRC = {}
for i = 1, 4 do SRC[i] = kit:FindFirstChild("SandBoulder_" .. i); assert(SRC[i], "SandBoulder_" .. i .. " missing") end
local G = workspace.SouthGorge
local old = G:FindFirstChild("RapidsRocks"); if old then old:Destroy() end
local M = Instance.new("Model"); M.Name = "RapidsRocks"; M.Parent = G
-- {z, dx from the river centre (negative = west), boulder 1-4, scale, share of height above the water}
local ROCKS = {
	-- the line at the head of the rapids (z -492..-499): big ones at the lane's edges, a bank rock each side
	{-495.5, -10.3, 4, 0.95, 0.50}, {-492.0, -8.3, 2, 0.60, 0.40},
	{-494.5, 10.2, 1, 1.00, 0.45}, {-498.5, 8.9, 3, 0.70, 0.40},
	{-497.0, 14.2, 2, 0.80, 0.50}, {-498.5, -15.3, 3, 0.55, 0.45},
	-- the scatter down the run: alternating banks, smaller, breaking the foam's pattern
	{-503, -9.0, 3, 0.55, 0.45}, {-506, -11.5, 2, 0.35, 0.50},
	{-508, 9.5, 1, 0.50, 0.40}, {-513, -8.5, 2, 0.70, 0.50},
	{-516, 12.0, 2, 0.35, 0.45}, {-518, 10.0, 4, 0.50, 0.35},
	{-523, -10.5, 1, 0.60, 0.45}, {-528, 8.5, 3, 0.65, 0.40},
	{-530, -12.0, 2, 0.35, 0.50}, {-533, -9.5, 2, 0.55, 0.50},
	{-537, 8.0, 4, 0.45, 0.40}, {-541, -8.5, 3, 0.45, 0.45},
}
local rng = Random.new(7)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain}; rp.IgnoreWater = false
local function aabbHalfX(cf, size)                        -- half extent along world x of a rotated box
	local r = cf.Rotation
	return math.abs(r.XVector.X) * size.X / 2 + math.abs(r.YVector.X) * size.Y / 2 + math.abs(r.ZVector.X) * size.Z / 2
end
local placed, nudged, lines = 0, 0, {}
for i, R in ipairs(ROCKS) do
	local z, dx, k, s, show = R[1], R[2], R[3], R[4], R[5]
	local cx = river_at(z)
	local p = SRC[k]:Clone()
	p.Name = string.format("Rock_%02d", i)
	p.Size = SRC[k].Size * s
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = true; p.CastShadow = true
	local yaw = rng:NextNumber(0, 2 * math.pi)
	local tilt = CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), 0, math.rad(rng:NextNumber(-10, 10)))
	local rot = CFrame.Angles(0, yaw, 0) * tilt
	local x = cx + dx
	-- keep the boat lane clear: push the rock outward until its x-extent is outside cx +- CHANNEL_HALF
	local hx = aabbHalfX(rot, p.Size)
	local inner = (dx < 0) and (x + hx) or (x - hx)
	local limit = (dx < 0) and (cx - CHANNEL_HALF) or (cx + CHANNEL_HALF)
	if (dx < 0 and inner > limit) or (dx > 0 and inner < limit) then
		x = x + (limit - inner); nudged += 1
	end
	-- seat it: on the water or on the bank
	local h = p.Size.Y
	local hit = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -80, 0), rp)
	local y, where
	if hit and hit.Material ~= Enum.Material.Water and hit.Position.Y > WATER_Y + 0.05 then
		y = hit.Position.Y + h * 0.2; where = "bank"                -- 30% of the rock in the ground
	else
		y = WATER_Y - h * (0.5 - show); where = "water"
	end
	p.CFrame = CFrame.new(x, y, z) * rot
	p.Parent = M
	placed += 1
	lines[#lines + 1] = string.format("%02d %s x%.1f z%.0f top+%.1f %s", i, "SB" .. k, x, z, y + h / 2 - WATER_Y, where)
end
-- the clear lane at the head line, measured from the rocks' real extents
local westMax, eastMin = -math.huge, math.huge
for _, p in ipairs(M:GetChildren()) do
	if p.Position.Z > -500 and p.Position.Z < -490 then
		local cx = river_at(p.Position.Z)
		local hx = aabbHalfX(p.CFrame, p.Size)
		if p.Position.X < cx then westMax = math.max(westMax, p.Position.X + hx) else eastMin = math.min(eastMin, p.Position.X - hx) end
	end
end
print(string.format("QQ RK1 placed %d rocks (%d nudged outward); head line clear lane x %.1f..%.1f = %.1f studs (boat 4.1)", placed, nudged, westMax, eastMin, eastMin - westMax))
print("QQ RK1 " .. table.concat(lines, " | "))
print("QQ RK1 DONE")

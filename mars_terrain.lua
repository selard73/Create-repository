-- Mars terrain sculptor. Paste into the Command Bar once (edit mode). Safe to run again: it clears
-- the terrain it made last time before rebuilding. Run mars_environment.lua first or after for colours.
--
-- Builds: a big flat plain of red sand, a rolling ring of dunes around it, a few rocky mesas at the far
-- edge, and a pinch of darker ground scattered across the plain. The centre stays flat for your scene.

local SIZE        = 900     -- width of the whole desert (studs)
local FLAT_RADIUS = 140     -- flat area in the middle for your props/field
local DUNES       = 34      -- how many dune mounds in the ring
local MESAS       = 6       -- rocky mesas at the far edge
local GROUND_Y    = 0       -- surface height of the plain
local SEED        = 7       -- change for a different layout

local T = workspace.Terrain
local rng = Random.new(SEED)
local hide = workspace:FindFirstChild("Baseplate")
if hide and hide:IsA("BasePart") then hide.Transparency = 1; hide.CanCollide = false end

-- wipe our previous terrain (everything under the plain + a margin)
T:Clear()

-- plain: a thick slab of sand whose top is at GROUND_Y
T:FillBlock(CFrame.new(0, GROUND_Y - 30, 0), Vector3.new(SIZE, 60, SIZE), Enum.Material.Sand)

-- dunes: soft mounds in a ring outside the flat area, lower near the flat edge, taller further out
for i = 1, DUNES do
	local a = (i / DUNES) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
	local d = rng:NextNumber(FLAT_RADIUS + 40, SIZE * 0.42)
	local size = rng:NextNumber(35, 80) * (0.6 + 0.4 * (d / (SIZE * 0.45)))
	local x, z = math.cos(a) * d, math.sin(a) * d
	local mat = rng:NextNumber() < 0.7 and Enum.Material.Sand or Enum.Material.Sandstone
	T:FillBall(Vector3.new(x, GROUND_Y - size * 0.55, z), size, mat)
	-- a smaller companion mound so the dunes read as a range, not single bumps
	local a2 = a + rng:NextNumber(-0.25, 0.25)
	local d2 = d + rng:NextNumber(-30, 30)
	T:FillBall(Vector3.new(math.cos(a2) * d2, GROUND_Y - size * 0.6, math.sin(a2) * d2), size * 0.7, mat)
end

-- mesas: stacked rock cylinders at the far edge
for i = 1, MESAS do
	local a = (i / MESAS) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
	local d = rng:NextNumber(SIZE * 0.36, SIZE * 0.46)
	local x, z = math.cos(a) * d, math.sin(a) * d
	local r = rng:NextNumber(40, 70)
	local h = rng:NextNumber(35, 70)
	local tiers = 3
	for t = 0, tiers - 1 do
		local tr = r * (1 - t * 0.18)
		local ty = GROUND_Y + h * (t / tiers)
		local th = h / tiers + 4
		local yaw = rng:NextNumber(0, math.pi)
		T:FillCylinder(CFrame.new(x + rng:NextNumber(-6, 6), ty + th / 2, z + rng:NextNumber(-6, 6)) * CFrame.Angles(0, yaw, 0), th, tr, Enum.Material.Rock)
	end
	-- sandy skirt at the base
	T:FillBall(Vector3.new(x, GROUND_Y - r * 0.5, z), r * 1.25, Enum.Material.Sand)
end

-- scattered darker ground patches on the plain for variety (very shallow)
for i = 1, 40 do
	local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, SIZE * 0.44)
	local x, z = math.cos(a) * d, math.sin(a) * d
	local r = rng:NextNumber(8, 22)
	local mat = rng:NextNumber() < 0.5 and Enum.Material.Ground or Enum.Material.Sandstone
	T:FillBall(Vector3.new(x, GROUND_Y - r * 0.92, z), r, mat)
end

print(string.format("Mars terrain built: %d-stud desert, flat centre radius %d, %d dunes, %d mesas", SIZE, FLAT_RADIUS, DUNES, MESAS))

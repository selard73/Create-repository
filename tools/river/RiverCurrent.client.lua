-- RiverCurrent (client): the river's slow north -> south current. Terrain water can't flow, so it is shown and felt:
--   leaves + petals and a few leafy twigs drifting downstream (decal images: real leaf and twig shapes - Shannon, Oct 1
--   2026: not squares and lines), and a gentle push on a swimmer.
-- Reads workspace.River: Line = "x,z,halfWidth;..." ordered downstream, WaterY = the surface height.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local R = workspace:WaitForChild("River")
local WATER_Y = R:GetAttribute("WaterY") or -0.9
local SPEED = R:GetAttribute("FlowSpeed") or 2.6            -- studs/s the leaves drift
local PUSH = R:GetAttribute("PushSpeed") or 4               -- the most the current will carry a swimmer
local ACCEL = R:GetAttribute("PushAccel") or 14            -- how hard it nudges (the swimmer's own controls damp it)
local Z_TOP, Z_END = 60, -250                               -- the stretch the drifters use (inside the map + a margin)

local pts = {}
for x, z, w in string.gmatch(R:GetAttribute("Line") or "", "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
	pts[#pts + 1] = {p = Vector3.new(tonumber(x), WATER_Y, tonumber(z)), w = tonumber(w)}
end
if #pts < 2 then return end
local segs, total = {}, 0
for i = 1, #pts - 1 do
	local a, b = pts[i], pts[i + 1]
	local d = b.p - a.p
	segs[i] = {a = a.p, dir = d.Unit, len = d.Magnitude, w0 = a.w, w1 = b.w, s0 = total}
	total += d.Magnitude
end
-- a point along the line: distance s -> position, flow direction, half width
local function at(s)
	s = math.clamp(s, 0, total - 0.01)
	local lo, hi = 1, #segs
	while lo < hi do local m = (lo + hi + 1) // 2; if segs[m].s0 <= s then lo = m else hi = m - 1 end end
	local g = segs[lo]
	local t = (s - g.s0) / g.len
	return g.a + g.dir * (s - g.s0), g.dir, g.w0 + (g.w1 - g.w0) * t
end
local function sOfZ(z) -- first distance whose z is at or below z
	for _, g in ipairs(segs) do if g.a.Z + g.dir.Z * g.len <= z then return g.s0 + math.max(0, (g.a.Z - z) / math.max(-g.dir.Z, 0.1)) end end
	return total
end
local S_TOP, S_END = sOfZ(Z_TOP), sOfZ(Z_END)
local rnd = Random.new()

local folder = Instance.new("Folder"); folder.Name = "RiverDrift"; folder.Parent = workspace
local LEAF_COLS = {Color3.fromRGB(106, 150, 72), Color3.fromRGB(150, 170, 70), Color3.fromRGB(196, 150, 60),
	Color3.fromRGB(178, 96, 52), Color3.fromRGB(240, 186, 200), Color3.fromRGB(250, 236, 240)}
local LEAF_TEX, TWIG_TEX = "rbxassetid://101757587087924", "rbxassetid://118085542281363"   -- italy/riverbits: a pale leaf (tinted per leaf), a leafy twig
local function newPart(size, col, transp)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Size = size; p.Color = col; p.Transparency = transp; p.Material = Enum.Material.SmoothPlastic
	p.Parent = folder
	return p
end
-- a drifting bit: the part itself is invisible, the leaf or twig is a decal on its top (and underside, for a swimmer)
local function newBit(size, tex, tint)
	local p = newPart(size, Color3.new(1, 1, 1), 1)
	for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
		local d = Instance.new("Decal"); d.Face = face; d.Texture = tex; d.Color3 = tint or Color3.new(1, 1, 1); d.Parent = p
	end
	return p
end
local drifters = {}
local function place(d, s)
	d.s = s; d.off = rnd:NextNumber(-0.6, 0.6); d.spin = rnd:NextNumber(-0.6, 0.6); d.phase = rnd:NextNumber(0, 6.28)
	d.speed = SPEED * rnd:NextNumber(0.8, 1.2) * (d.streak and 1.15 or 1)
end
for i = 1, 28 do                                               -- leaves and petals
	local petal = i % 3 == 0
	local col = LEAF_COLS[petal and rnd:NextInteger(5, 6) or rnd:NextInteger(1, 4)]
	local d = {part = newBit(petal and Vector3.new(0.7, 0.05, 0.7) or Vector3.new(1.2, 0.05, 1.2), LEAF_TEX, col), yaw = rnd:NextNumber(0, 6.28)}
	place(d, rnd:NextNumber(S_TOP, S_END)); drifters[#drifters + 1] = d
end
for i = 1, 12 do                                               -- leafy twigs, turning slowly
	local k = rnd:NextNumber(1.8, 2.6)
	local d = {part = newBit(Vector3.new(k, 0.05, k), TWIG_TEX, nil), yaw = rnd:NextNumber(0, 6.28)}
	place(d, rnd:NextNumber(S_TOP, S_END)); d.spin = d.spin * 0.35
	drifters[#drifters + 1] = d
end

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	-- only animate when someone is near enough to see it
	local near = true
	if root then
		local rp = root.Position
		near = rp.X > 40 and rp.X < 330 and rp.Z > -380 and rp.Z < 180
	end
	if near then
		for _, d in ipairs(drifters) do
			d.s += d.speed * dt
			if d.s > S_END then place(d, S_TOP + rnd:NextNumber(0, 6)); if d.streak then d.life = 0 end end
			local pos, dir, w = at(d.s)
			local side = dir:Cross(Vector3.yAxis)
			local p = pos + side * (d.off * w) + Vector3.new(0, 0.04 + 0.03 * math.sin(t * 1.3 + d.phase), 0)
			if d.streak then
				d.life += dt
				if d.life > d.max then d.life = 0; d.off = rnd:NextNumber(-0.6, 0.6) end
				local k = d.life / d.max
				d.part.Transparency = 1 - 0.32 * math.sin(math.pi * k)       -- fade in and out
				d.part.CFrame = CFrame.lookAt(p, p + dir)
			else
				d.yaw += d.spin * dt
				d.part.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0.08 * math.sin(t * 1.7 + d.phase), d.yaw, 0)
			end
		end
	end
	-- the push: only while swimming in the river
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if root and hum and hum:GetState() == Enum.HumanoidStateType.Swimming and root.Position.Y < WATER_Y + 3 then
		local rp = root.Position
		local best, bd, bw = nil, math.huge, 0
		for _, g in ipairs(segs) do
			local v = Vector3.new(rp.X - g.a.X, 0, rp.Z - g.a.Z)
			local along = math.clamp(v:Dot(g.dir), 0, g.len)
			local q = g.a + g.dir * along
			local dd = (Vector3.new(rp.X, 0, rp.Z) - Vector3.new(q.X, 0, q.Z)).Magnitude
			if dd < bd then bd, best, bw = dd, g, g.w0 + (g.w1 - g.w0) * along / g.len end
		end
		if best and bd < bw + 2 then
			local v = root.AssemblyLinearVelocity
			local now = v:Dot(best.dir)
			if now < PUSH then root.AssemblyLinearVelocity = v + best.dir * math.min(PUSH - now, ACCEL * dt) end
		end
	end
end)

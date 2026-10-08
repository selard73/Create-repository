-- WhaleClient (Script, RunContext Client, parented in workspace.PortoWhale): Porto Nocciola's whale.
-- Swims a closed route out at sea, pauses at its blow stations to spout, then dives on and surfaces again.
-- Everything is computed from the server clock, so every player sees the same whale in the same place.
local RunService = game:GetService("RunService")
local model = script.Parent
local mesh = model:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("Whale: no mesh") return end
local bones = {}
for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
local blowAtt = mesh:FindFirstChild("Blowhole")
local spout = blowAtt and blowAtt:FindFirstChild("Spout")
local blowSound = blowAtt and blowAtt:FindFirstChild("Blow")
local function num(name, default) local v = model:GetAttribute(name) return typeof(v) == "number" and v or default end

-- object-space axes measured by the installer (which way the nose and the back point inside the mesh)
local fwdObj = model:GetAttribute("FwdObj") or Vector3.new(0, 0, -1)
local upObj = model:GetAttribute("UpObj") or Vector3.new(0, 1, 0)
local backObj = -fwdObj
local rightObj = upObj:Cross(backObj)
local R_inv = CFrame.fromMatrix(Vector3.zero, rightObj, upObj, backObj):Inverse()
local function along(v) return math.abs(v.X) * mesh.Size.X + math.abs(v.Y) * mesh.Size.Y + math.abs(v.Z) * mesh.Size.Z end
local L, H = along(fwdObj), along(upObj)

local WATER_Y = num("WaterY", -52.9)
local SPEED = num("Speed", 7)          -- studs/s while cruising
local BLOW = num("BlowDur", 12)        -- seconds paused at a blow station
local RAMP = num("Ramp", 8)            -- seconds to slow down / speed up at a station
local DIVE = num("DiveDepth", 0.45)    -- fraction of the body height it sinks after the blow
local SHOW = num("CruiseShow", 0.2)    -- fraction of the body height above the water while cruising
local STROKE = num("Stroke", 0.8)      -- one tail stroke per this fraction of the body length
local BED_Y = model:GetAttribute("BedY")  -- optional floor: the belly never goes below this

-- ---------- route: closed Catmull-Rom spline through the waypoints ----------
local route = {}
for x, z in string.gmatch(model:GetAttribute("Route") or "", "([-%d%.]+),([-%d%.]+)") do
	table.insert(route, Vector3.new(tonumber(x), 0, tonumber(z)))
end
if #route < 3 then warn("Whale: Route needs 3+ points") return end
local blowIdx = {}
for i in string.gmatch(model:GetAttribute("BlowAt") or "1", "%d+") do blowIdx[tonumber(i)] = true end
local n = #route
local function P(i) return route[((i - 1) % n) + 1] end
local function cr(i, u)
	local p0, p1, p2, p3 = P(i - 1), P(i), P(i + 1), P(i + 2)
	local u2, u3 = u * u, u * u * u
	return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (-p0 + 3 * p1 - 3 * p2 + p3) * u3)
end
local SAMP = 24
local pts, dist = {}, {}      -- sampled points and their arc length
local stationS = {}            -- arc length of each blow station
local acc = 0
for i = 1, n do
	if blowIdx[i] then table.insert(stationS, acc) end
	for k = 0, SAMP - 1 do
		local p = cr(i, k / SAMP)
		if #pts > 0 then acc += (p - pts[#pts]).Magnitude end
		table.insert(pts, p) table.insert(dist, acc)
	end
end
local p0 = pts[1]
acc += (p0 - pts[#pts]).Magnitude
table.insert(pts, p0) table.insert(dist, acc)
local LEN = acc
if #stationS == 0 then stationS = {0} end
table.sort(stationS)

local function posAt(s)
	s = s % LEN
	local lo, hi = 1, #dist
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if dist[mid] <= s then lo = mid else hi = mid end
	end
	local d0, d1 = dist[lo], dist[hi]
	local t = d1 > d0 and (s - d0) / (d1 - d0) or 0
	local p = pts[lo]:Lerp(pts[hi], t)
	local dir = (pts[hi] - pts[lo])
	if dir.Magnitude < 1e-3 then dir = pts[math.min(hi + 1, #pts)] - pts[lo] end
	return p, dir.Unit
end

-- ---------- schedule: blow at station 1, swim to station 2, blow, ... swim back round to station 1 ----------
local segs = {}
local T = 0
for k, s in ipairs(stationS) do
	table.insert(segs, {kind = "blow", t0 = T, t1 = T + BLOW, s = s}) T += BLOW
	local s2 = stationS[k + 1] or (stationS[1] + LEN)
	local dur = (s2 - s) / SPEED
	if dur > 0.01 then table.insert(segs, {kind = "swim", t0 = T, t1 = T + dur, s0 = s, s1 = s2}) T += dur end
end

local function trapezoid(u, r)      -- distance fraction at time fraction u, ramps of fraction r at both ends
	if r <= 0 then return u end
	local vp = 1 / (1 - r)
	if u < r then return vp * u * u / (2 * r) end
	if u > 1 - r then return 1 - vp * (1 - u) * (1 - u) / (2 * r) end
	return vp * (r / 2 + (u - r))
end
local function smooth(x) x = math.clamp(x, 0, 1) return x * x * (3 - 2 * x) end
local function bump(x) return math.sin(math.pi * math.clamp(x, 0, 1)) end

-- ---------- bones: each one's pitch / flap axis in its own frame, measured at rest ----------
local axis = {}
for name, b in pairs(bones) do
	local w = b.WorldCFrame
	axis[name] = {
		pitch = w:VectorToObjectSpace(mesh.CFrame:VectorToWorldSpace(rightObj)),
		flap = w:VectorToObjectSpace(mesh.CFrame:VectorToWorldSpace(fwdObj)),
	}
end
local SPINE = {{"Head", -3, 0}, {"Spine1", 4, 0.6}, {"Spine2", 7, 1.2}, {"Tail", 11, 1.8}, {"Flukes", 16, 2.4}}
local LIFT = {Spine1 = 0.15, Spine2 = 0.35, Tail = 0.65, Flukes = 1.0}
local SIGN = num("TailSign", 1)   -- flip if the tail lifts the wrong way in Studio

local phi, lastS, lastBlowKey = 0, nil, nil
local function step(dt)
	local now = workspace:GetServerTimeNow()
	local t = now % T
	local seg
	for _, sg in ipairs(segs) do if t >= sg.t0 and t < sg.t1 then seg = sg break end end
	seg = seg or segs[#segs]
	local s, speedNow, blowT, sinceBlow, blowKey = 0, 0, nil, nil, nil
	if seg.kind == "blow" then
		s = seg.s
		blowT = t - seg.t0
		blowKey = math.floor(now / T) * 100 + seg.t0
	else
		local dur = seg.t1 - seg.t0
		local u = (t - seg.t0) / dur
		local r = math.min(0.3, RAMP / dur)
		s = seg.s0 + (seg.s1 - seg.s0) * trapezoid(u, r)
		sinceBlow = t - seg.t0
	end
	if lastS then
		local ds = (s - lastS) % LEN
		if ds > LEN / 2 then ds = 0 end
		speedNow = ds / math.max(dt, 1e-3)
		phi += ds * 2 * math.pi / (STROKE * L)
	end
	lastS = s
	if speedNow < 0.5 then phi += dt * 0.5 end

	-- depth, pitch, tail lift
	local y = WATER_Y - H / 2 + SHOW * H
	local pitch, lift = 0, 0
	if blowT then
		y += 0.08 * H * smooth(blowT / 1.5)
	elseif sinceBlow then
		local d = sinceBlow
		local sink = d < 4 and smooth(d / 4) or math.exp(-(d - 4) / 14)
		y -= DIVE * H * sink
		pitch = -math.rad(22) * bump(d / 6)
		lift = math.rad(32) * bump((d - 0.3) / 5)
	end
	if typeof(BED_Y) == "number" then y = math.max(y, BED_Y + H / 2 + 0.5) end
	y += 0.03 * H * math.sin(phi)

	local p, dir = posAt(s)
	local gain = 0.15 + 0.85 * math.clamp(speedNow / SPEED, 0, 1)
	local roll = math.rad(2) * math.sin(phi - 1) * gain
	mesh.CFrame = CFrame.lookAt(Vector3.new(p.X, y, p.Z), Vector3.new(p.X + dir.X, y, p.Z + dir.Z))
		* CFrame.Angles(pitch, 0, roll) * R_inv

	for _, e in ipairs(SPINE) do
		local b = bones[e[1]]
		if b then
			local a = math.rad(e[2]) * math.sin(phi - e[3]) * gain + SIGN * lift * (LIFT[e[1]] or 0)
			b.Transform = CFrame.fromAxisAngle(axis[e[1]].pitch, a)
		end
	end
	local flap = math.rad(7) * math.sin(phi * 0.5) * (0.4 + 0.6 * gain)
	if bones.FlipperL then bones.FlipperL.Transform = CFrame.fromAxisAngle(axis.FlipperL.flap, flap) end
	if bones.FlipperR then bones.FlipperR.Transform = CFrame.fromAxisAngle(axis.FlipperR.flap, -flap) end

	-- the spout: 2 s into the pause, for 2 s
	if spout then spout.Enabled = (blowT ~= nil and blowT >= 2 and blowT < 4) end
	if blowT and blowT >= 2 and blowKey ~= lastBlowKey then
		lastBlowKey = blowKey
		if blowSound and blowSound.SoundId ~= "" then blowSound:Play() end
	end
end
RunService.Heartbeat:Connect(step)

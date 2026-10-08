local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local L = script.Parent
local croc = L:WaitForChild("Croc")
local evt = L:WaitForChild("CrocEvent")
local cages = L:WaitForChild("Cages")
local award = RS:WaitForChild("AwardAcorns", 30)
local items = RS:WaitForChild("AwardItems", 30)
local picked = RS:FindFirstChild("AcornPicked")
local function A(n, d) local v = L:GetAttribute(n); if v == nil then return d end return v end
local function now() return workspace:GetServerTimeNow() end
local rng = Random.new()

-- the lagoon
local WATER_Y = A("WaterY", -1)
local LOBES = {}
for x, z, r in string.gmatch(A("Lobes", ""), "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do table.insert(LOBES, {tonumber(x), tonumber(z), tonumber(r)}) end
local IX, IZ, IR = A("IslandX", 118), A("IslandZ", -181), A("IslandR", 6.5)
local function sdfWater(x, z) local b = -math.huge for _, l in ipairs(LOBES) do b = math.max(b, l[3] - math.sqrt((x - l[1]) ^ 2 + (z - l[2]) ^ 2)) end return b end
local function sdfIsland(x, z) return IR - math.sqrt((x - IX) ^ 2 + (z - IZ) ^ 2) end
-- where he naps (the lobe nearest the path's west) and sulks (the lobe farthest from the path)
local function lobeFarthestFrom(px, pz, nearest)
	local best, bd = LOBES[1], nil
	for i, l in ipairs(LOBES) do
		if i > 1 then
			local d = (l[1] - px) ^ 2 + (l[2] - pz) ^ 2
			if not bd or (nearest and d < bd) or (not nearest and d > bd) then best, bd = l, d end
		end
	end
	return best
end
local SIGN_X, SIGN_Z = A("SignX", 104), A("SignZ", -147)
local napLobe = lobeFarthestFrom(SIGN_X - 20, SIGN_Z - 53, true)   -- the north-west arm, away from the path in and the log
local napX, napZ = napLobe[1], napLobe[2]
local sulkLobe = lobeFarthestFrom(SIGN_X, SIGN_Z, false)
local SPITS = {}
for x, z in string.gmatch(A("SpitSpots", ""), "([%-%d%.]+),([%-%d%.]+)") do table.insert(SPITS, Vector3.new(tonumber(x), 0.2, tonumber(z))) end
if #SPITS == 0 then SPITS = {Vector3.new(112, 0.2, -142)} end

-- the croc's measurements (studs, his own frame: bottom centre, facing -Z)
local SINK = croc:GetAttribute("SwimSink") or 2.3
local SNOUT = croc:GetAttribute("SnoutOffset") or Vector3.new(0, 2.8, -6.3)
local TAILB = croc:GetAttribute("TailBaseOffset") or Vector3.new(0, 1.6, 3.4)
local TAILT = croc:GetAttribute("TailTipOffset") or Vector3.new(-0.7, 3.4, 5.8)
local BODY_R = croc:GetAttribute("BodyRadius") or 1.8
-- the snout tip and both sides of his head: none of them may reach the island (Shannon: "his snout actually goes into
-- the hill")
local HEAD_PTS = {SNOUT, SNOUT + Vector3.new(1.1, 0, 2.2), SNOUT + Vector3.new(-1.1, 0, 2.2), SNOUT + Vector3.new(1.4, 0, 4.2), SNOUT + Vector3.new(-1.4, 0, 4.2)}
-- THE LOG IS SOLID (Shannon: "the croc still goes through the log with his tail and his snout"): its footprint on the
-- water (written by the lagoon builder) may not hold any part of him - snout, head, body, tail - so he swims round it,
-- and a turn that would swing his snout or tail into it doesn't happen
local LOG = nil
do
	local c, ax, ha, hb = L:GetAttribute("LogCenter"), L:GetAttribute("LogAxis"), L:GetAttribute("LogHalfA"), L:GetAttribute("LogHalfB")
	if typeof(c) == "Vector3" and typeof(ax) == "Vector3" and ha and hb then
		local a = Vector3.new(ax.X, 0, ax.Z).Unit
		LOG = {c = c, a = a, b = Vector3.new(-a.Z, 0, a.X), ha = ha, hb = hb}
	end
end
local BODY_PTS = {{SNOUT, 0.6}, {SNOUT + Vector3.new(0, 0, 2.4), 1.2}, {Vector3.new(0, 0, SNOUT.Z * 0.45), 1.8},
	{Vector3.new(0, 0, 0), 2.0}, {Vector3.new(0, 0, -SNOUT.Z * 0.3), 1.9}, {TAILB, 1.3}, {(TAILB + TAILT) / 2, 1.0}, {TAILT, 0.8}}
local function hitsLog(f)
	if not LOG then return false end
	for _, bp in ipairs(BODY_PTS) do
		local w = f * bp[1]
		local d = Vector3.new(w.X - LOG.c.X, 0, w.Z - LOG.c.Z)
		if math.abs(d:Dot(LOG.a)) < LOG.ha + bp[2] and math.abs(d:Dot(LOG.b)) < LOG.hb + bp[2] then return true end
	end
	return false
end
-- (with the log in the nap arm, he naps in the part of it farthest from the log)
if LOG then
	local bestD = -1
	for gx = -4, 4 do
		for gz = -4, 4 do
			local px, pz = napLobe[1] + gx, napLobe[2] + gz
			if sdfWater(px, pz) >= 3.5 and sdfIsland(px, pz) < -6 then
				local dd = Vector3.new(px - LOG.c.X, 0, pz - LOG.c.Z).Magnitude
				if dd > bestD then bestD, napX, napZ = dd, px, pz end
			end
		end
	end
end

local x, z, yaw = croc:GetAttribute("HomeX"), croc:GetAttribute("HomeZ"), croc:GetAttribute("HomeYaw") or 0
local function frameAt(px, pz, pyaw) return CFrame.new(px, WATER_Y - SINK, pz) * CFrame.Angles(0, pyaw, 0) end
local function snoutAt(px, pz, pyaw) return frameAt(px, pz, pyaw) * SNOUT end
-- WHERE TO AIM (SlingServer asks when someone near him shoots): the top of his head between the eyes, and how fast he's
-- going, so the acorn can be sent to where he'll be when it lands
local AIM_OFF = SNOUT + Vector3.new(0, 0.6, 3.0)
local velX, velZ, lastVX, lastVZ, lastVT = 0, 0, nil, nil, nil
local aimFn = L:FindFirstChild("CrocAim")
if not aimFn then aimFn = Instance.new("BindableFunction"); aimFn.Name = "CrocAim"; aimFn.Parent = L end
aimFn.OnInvoke = function() return frameAt(x, z, yaw) * AIM_OFF, Vector3.new(velX, 0, velZ) end

local state, stateAt, target = "patrol", now(), nil
local lastMoved = 0
local function setState(s, who)
	if s == "chase" and state ~= "lunge" then lastMoved = now() end   -- (snaps at the air don't reset his patience)
	state = s; stateAt = now(); target = who
	croc:SetAttribute("State", s); croc:SetAttribute("StateAt", stateAt % 4096)
	croc:SetAttribute("Target", who and who.UserId or 0)
end
setState("patrol")

-- ---- who's in his lagoon
local immune, held, ignoreUntil = {}, {}, {}
local function hrpOf(p) local c = p.Character; local h = c and c:FindFirstChild("HumanoidRootPart"); local hum = c and c:FindFirstChildOfClass("Humanoid"); if h and hum and hum.Health > 0 then return h end end
local function inLagoon(pos)
	if pos.Y > WATER_Y + 7 or pos.Y < WATER_Y - 12 then return false end
	if sdfIsland(pos.X, pos.Z) > -0.8 then return true end
	return sdfWater(pos.X, pos.Z) > -1.0
end
local function intruder(maxDist)
	local s = snoutAt(x, z, yaw)
	local best, bd = nil, maxDist or math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if h and not held[p] and (immune[p] or 0) < now() and (ignoreUntil[p] or 0) < now() and inLagoon(h.Position) then
			local d = (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(s.X, 0, s.Z)).Magnitude
			if d < bd then best, bd = p, d end
		end
	end
	return best, bd
end

-- ---- moving: he goes where he faces, turns at TurnRate, keeps off the island and in the water
-- THE GROUND UNDER HIS HEAD (Shannon, twice: "his nose is in the hill again"). The water's outline is only an outline:
-- the bank's grass slopes up out of the water inside it, and the first rule let the snout 2.5 studs past it - onto the
-- grass. Now the real terrain height is looked up (a raycast per stud of ground, remembered) and his snout and the
-- sides of his head must stay over water, the bed below them under the surface.
local bedRp = RaycastParams.new(); bedRp.FilterType = Enum.RaycastFilterType.Include; bedRp.IgnoreWater = true
bedRp.FilterDescendantsInstances = {workspace.Terrain, workspace:FindFirstChild("Baseplate")}
local bedCache = {}
local function bedCell(cx, cz)
	local col = bedCache[cx]; if not col then col = {}; bedCache[cx] = col end
	local v = col[cz]
	if v == nil then
		local r = workspace:Raycast(Vector3.new(cx, WATER_Y + 14, cz), Vector3.new(0, -40, 0), bedRp)
		v = r and r.Position.Y or (WATER_Y - 20)
		col[cz] = v
	end
	return v
end
local function bedH(px, pz)
	local cx, cz = math.floor(px), math.floor(pz)
	local fx, fz = px - cx, pz - cz
	local a, b, c, d = bedCell(cx, cz), bedCell(cx + 1, cz), bedCell(cx, cz + 1), bedCell(cx + 1, cz + 1)
	return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz
end
local function headClear(f)
	local sn = f * SNOUT
	if bedH(sn.X, sn.Z) > WATER_Y - A("SnoutDepth", 0.45) then return false end
	for i = 2, #HEAD_PTS do
		local q = f * HEAD_PTS[i]
		if bedH(q.X, q.Z) > WATER_Y - A("HeadDepth", 0.25) then return false end
	end
	return true
end
local function okAt(px, pz, pyaw, margin)
	if sdfWater(px, pz) < margin then return false end
	if sdfIsland(px, pz) > -2.6 then return false end
	local f = frameAt(px, pz, pyaw)
	if hitsLog(f) then return false end
	for i, o in ipairs(HEAD_PTS) do
		local q = f * o
		-- his head stays clear of the island: the terrain's slope reaches further out than the waterline (a stud off
		-- still touched the grass), so the snout keeps 2.6 studs off, the sides of his head 2
		if sdfIsland(q.X, q.Z) > (i == 1 and -2.6 or -2.0) then return false end
	end
	return headClear(f)                                              -- and over water, not on the bank
end
local function turnToward(want, dt)
	local d = (want - yaw + math.pi) % (2 * math.pi) - math.pi
	local m = math.rad(A("TurnRate", 150)) * dt
	local ny = yaw + math.clamp(d, -m, m)
	if LOG and hitsLog(frameAt(x, z, ny)) and not hitsLog(frameAt(x, z, yaw)) then return math.abs(d) end   -- not into the log
	-- nor his nose into the bank: he backs off a touch instead, and the turn comes when there's room
	if not headClear(frameAt(x, z, ny)) and headClear(frameAt(x, z, yaw)) then
		local bx, bz = x + math.sin(yaw) * 0.12, z + math.cos(yaw) * 0.12
		if okAt(bx, bz, yaw, 0.3) then x, z = bx, bz end
		return math.abs(d)
	end
	yaw = ny
	return math.abs(d)
end
local detourSide = nil
local waypoint = nil                                              -- {x, z, until}: a stop on the way, when he was stuck
local tried = false                                               -- he wanted to move this tick
local function aimAround(tx, tz)                                   -- round the island rather than through it
	if waypoint then
		if Vector3.new(waypoint[1] - x, 0, waypoint[2] - z).Magnitude < 1.5 or now() > waypoint[3] then waypoint = nil
		else return waypoint[1], waypoint[2] end
	end
	local Rr = IR + 4.2
	local px, pz, qx, qz = x - IX, z - IZ, tx - IX, tz - IZ
	local dx, dz = qx - px, qz - pz
	local len2 = dx * dx + dz * dz
	if len2 < 1e-4 then detourSide = nil return tx, tz end
	local t = math.clamp(-(px * dx + pz * dz) / len2, 0, 1)
	-- nearest approach where he already is (heading away) or at the target itself (a player on the island): straight on
	if t <= 0.03 or t >= 0.97 then detourSide = nil return tx, tz end
	local cx, cz = px + dx * t, pz + dz * t
	if cx * cx + cz * cz >= Rr * Rr then detourSide = nil return tx, tz end
	-- the side is chosen once and kept until the way is clear (a target straight across made him dither)
	if not detourSide then detourSide = (px * qz - pz * qx) >= 0 and 1 or -1 end
	local a = math.atan2(pz, px) + detourSide * math.rad(50)
	local r = math.clamp(math.sqrt(px * px + pz * pz), Rr + 0.5, math.max(A("PatrolRadius", 12), Rr + 0.5))
	return IX + math.cos(a) * r, IZ + math.sin(a) * r
end
local function moveToward(tx, tz, speed, dt, margin)
	local ax, az = aimAround(tx, tz)
	local dx, dz = ax - x, az - z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 0.25 then return dist end
	tried = true
	local offBy = turnToward(math.atan2(-dx, -dz), dt)
	local step = math.min(dist, speed * dt * math.clamp(1.2 - offBy / math.rad(80), 0.12, 1))
	for _, a in ipairs({0, 0.45, -0.45, 0.9, -0.9}) do
		local fx, fz = -math.sin(yaw + a), -math.cos(yaw + a)
		local nx, nz = x + fx * step * (a == 0 and 1 or 0.7), z + fz * step * (a == 0 and 1 or 0.7)
		if okAt(nx, nz, yaw, margin) then x, z = nx, nz break end
	end
	return dist
end

-- ---- acorns
local hourly = {}
local function pay(player, n, from)
	if n <= 0 then return end
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + n)
	if award then award:Fire(player, n) end
	if picked and from then picked:FireClient(player, have + n, from, n) end      -- n acorns fly to the purse
end

-- ---- slingshot bonks: every shot acorn is followed; a line from frame to frame that crosses his body is a hit
local shots, bonks = {}, {}
local fleeHourly = {}
local flinchUntil = -1                                            -- a bonk stops him dead for a moment
local function segDist(p1, q1, p2, q2)                           -- closest distance between two segments
	local d1, d2, r = q1 - p1, q2 - p2, p1 - p2
	local a, e, f = d1:Dot(d1), d2:Dot(d2), d2:Dot(r)
	local sN, tN
	if a <= 1e-6 and e <= 1e-6 then return r.Magnitude end
	if a <= 1e-6 then sN = 0; tN = math.clamp(f / e, 0, 1)
	else
		local c = d1:Dot(r)
		if e <= 1e-6 then tN = 0; sN = math.clamp(-c / a, 0, 1)
		else
			local b = d1:Dot(d2); local den = a * e - b * b
			sN = den ~= 0 and math.clamp((b * f - c * e) / den, 0, 1) or 0
			tN = (b * sN + f) / e
			if tN < 0 then tN = 0; sN = math.clamp(-c / a, 0, 1) elseif tN > 1 then tN = 1; sN = math.clamp((b - c) / a, 0, 1) end
		end
	end
	return ((p1 + d1 * sN) - (p2 + d2 * tN)).Magnitude
end
local function hitsCroc(a, b)
	local f = frameAt(x, z, yaw)
	local sn, tb, tt = f * SNOUT, f * TAILB, f * TAILT
	return segDist(a, b, sn, tb) < BODY_R + 0.7 or segDist(a, b, tb, tt) < BODY_R * 0.55 + 0.6
end
workspace.ChildAdded:Connect(function(c)
	if c.Name ~= "ShotAcorn" then return end
	task.defer(function()
		local nut = c.PrimaryPart or c:FindFirstChild("Nut") or c:FindFirstChildWhichIsA("BasePart")
		if not nut then return end
		local id = nut:GetAttribute("ShooterId") or c:GetAttribute("ShooterId")
		local shooter = id and Players:GetPlayerByUserId(id)
		if not shooter then
			local bd = 7
			for _, p in ipairs(Players:GetPlayers()) do
				local h = p.Character and p.Character:FindFirstChild("Head")
				if h and (h.Position - nut.Position).Magnitude < bd then shooter, bd = p, (h.Position - nut.Position).Magnitude end
			end
		end
		shots[nut] = {model = c, last = nut.Position, shooter = shooter, born = os.clock()}
	end)
end)
local function bonk(shooter, at)
	local t = now()
	if shooter then pay(shooter, A("BonkPrize", 1), at) end
	local counts = not (state == "dizzy" or state == "sulk" or state == "hold" or state == "spit")
	if counts then
		for i = #bonks, 1, -1 do if t - bonks[i] > A("BonkWindow", 25) then table.remove(bonks, i) end end
		table.insert(bonks, t)
	end
	local n, need = counts and #bonks or 0, A("BonksToFlee", 3)
	-- EVERY BONK SHOWS (Shannon: "he does not react when you bonk him"): he flinches on every screen (CrocClient), and
	-- stops dead for a moment - a bonk buys a chased player a second; the shooter sees how many more it takes
	evt:FireAllClients("bonk", at, shooter and shooter.UserId or 0, n, need)
	print(string.format("CrocServer: bonk by %s - %d of %d (%s)", shooter and shooter.Name or "?", n, need, state))
	if not counts then return end
	flinchUntil = t + 0.7
	if n >= need then
		bonks = {}
		if shooter then
			-- capped per hour like the rescues: a slingshot that flies at his head must not be an acorn farm
			local list = fleeHourly[shooter] or {}; fleeHourly[shooter] = list
			for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
			if #list < A("FleeCap", 3) then table.insert(list, t); pay(shooter, A("FleePrize", 3), at) end
			evt:FireClient(shooter, "fled")
		end
		setState("dizzy")
	elseif state == "nap" or state == "tonap" then
		setState("patrol")
	end
end

-- ---- the chomp
local function chomp(victim)
	held[victim] = true
	setState("hold", victim)
	evt:FireClient(victim, "chomp", A("HoldTime", 1.7))
	evt:FireAllClients("chompfx", victim.UserId)
end
local function spit(victim)
	held[victim] = nil
	local best, bd = SPITS[1], math.huge
	local s = snoutAt(x, z, yaw)
	for _, p in ipairs(SPITS) do
		local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(s.X, 0, s.Z)).Magnitude + rng:NextNumber(0, 6)
		if d < bd then best, bd = p, d end
	end
	local flight = math.clamp(bd / 26, 0.8, 1.6)
	immune[victim] = now() + flight + A("Immune", 6)
	if victim.Parent then evt:FireClient(victim, "spit", best, flight) end
	evt:FireAllClients("spitfx", victim.UserId, flight)
	setState("smug")
end

-- ---- rescues
local rescues = {}
local roundRescuers = {}                                          -- names of whoever freed squirrels since the last full set
-- PRAISE (Shannon): after a rescue, the next squirrel you walk by says "Thank you for saving Madame Margaux's petits
-- enfants!" and the one after that "<name> is a hero! Yay for <name>!". The rescuer's screen picks the squirrel; the
-- server checks it (a tagged squirrel, near them, a different one, not too soon) and everyone nearby sees the bubble.
local CS = game:GetService("CollectionService")
local heroes = {}
evt.OnServerEvent:Connect(function(player, kind, model)
	if kind ~= "praise" then return end
	local h = heroes[player]
	if not h or typeof(model) ~= "Instance" or not model:IsA("Model") or not CS:HasTag(model, "Squirrel") or model == h.last then return end
	local t = now()
	if t - h.at < 3 then return end
	local hr = hrpOf(player)
	local ok, pos = pcall(function() return model:GetPivot().Position end)
	if not hr or not ok or (pos - hr.Position).Magnitude > 26 then return end
	local name = player.DisplayName
	local text = h.stage == 1 and "Thank you for saving Madame Margaux's petits enfants!" or string.format("%s is a hero! Yay for %s!", name, name)
	evt:FireAllClients("praise", model, text)
	evt:FireClient(player, "praiseok", h.stage)                   -- the rescuer's screen moves on only when this comes
	h.stage += 1; h.at = t; h.last = model
	if h.stage > 2 then heroes[player] = nil end
end)
local function openCount(cage) return cage:GetAttribute("Occupied") end
for _, cage in ipairs(cages:GetChildren()) do
	local pp = cage:FindFirstChild("RescuePrompt", true)
	if pp then
		pp.Enabled = cage:GetAttribute("Occupied") == true and cage:GetAttribute("HasCaptive") == true
		pp.Triggered:Connect(function(player)
			if not cage:GetAttribute("Occupied") then return end
			local h = hrpOf(player)
			local spot = pp.Parent
			if not h or (h.Position - spot.Position).Magnitude > 10 then return end
			local t = now()
			local list = rescues[player] or {}
			for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
			rescues[player] = list
			cage:SetAttribute("Occupied", false); pp.Enabled = false
			evt:FireAllClients("rescued", cage.Name, player.UserId)
			local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"rescue",{}) end
			-- ALL THREE FREE (Shannon: "there should be some kind of toast after all 3 squirrels are free"): everyone in
			-- the game gets the toast, naming whoever freed them this time round
			local nm = player.DisplayName
			local seen = false
			for _, n in ipairs(roundRescuers) do if n == nm then seen = true end end
			if not seen then table.insert(roundRescuers, nm) end
			local allFree = true
			for _, c in ipairs(cages:GetChildren()) do if c:GetAttribute("Occupied") then allFree = false end end
			if allFree then
				local names = roundRescuers
				roundRescuers = {}
				task.delay(1.3, function() evt:FireAllClients("allfree", names) end)     -- after the last one's hop out
			end
			if #list < A("RescueCap", 20) then
				table.insert(list, t)
				pay(player, A("RescuePrize", 5), spot.Position)
				if items then items:Fire(player, "croc_rescues", 1) end
				if not heroes[player] then heroes[player] = {stage = 1, at = now(), last = nil} end
			else
				evt:FireClient(player, "capped")
			end
			-- he's not having it
			if state == "patrol" or state == "nap" or state == "tonap" or state == "smug" or state == "guard" then setState("chase", player) end
			task.delay(A("RespawnSeconds", 90), function()
				while true do
					local busy = false
					for _, p in ipairs(Players:GetPlayers()) do
						local hh = hrpOf(p)
						if hh and (Vector3.new(hh.Position.X, 0, hh.Position.Z) - Vector3.new(IX, 0, IZ)).Magnitude < 16 then busy = true end
					end
					if not busy then break end
					task.wait(3)
				end
				cage:SetAttribute("Occupied", true)
				pp.Enabled = cage:GetAttribute("HasCaptive") == true
			end)
		end)
	end
end

-- ---- the brain: 20 times a second; the pose goes out 10 times a second
local ringDir, ringAng = 1, math.atan2(z - IZ, x - IX)
local nextStop, nextNap = now() + rng:NextNumber(12, 22), now() + A("NapEvery", 70) * rng:NextNumber(0.6, 1.1)
local seenSince, lostSince, lungeReady = nil, nil, 0
local stuckT, stuckAt
local lungeFrom
local acc, pubAcc = 0, 0
RunService.Heartbeat:Connect(function(dtFrame)
	-- shots first (every frame: a fast acorn crosses him between ticks)
	for nut, sh in pairs(shots) do
		if not nut.Parent or os.clock() - sh.born > 10 then shots[nut] = nil
		else
			local cur = nut.Position
			if hitsCroc(sh.last, cur) then
				shots[nut] = nil
				local at = cur
				sh.model:Destroy()
				bonk(sh.shooter, at)
			else sh.last = cur end
		end
	end
	acc += dtFrame
	if acc < 0.05 then return end
	local dt = math.min(acc, 0.2); acc = 0
	local t = now()
	local since = t - stateAt
	local R = A("PatrolRadius", 12)
	local slow = math.clamp((t - flinchUntil) / 0.5, 0, 1)         -- 0 while he's flinching from a bonk, back to 1 in half a second

	if state == "patrol" or state == "guard" then
		local who = intruder(60)
		if who then
			seenSince = seenSince or t
			if t - seenSince > A("NoticeDelay", 0.6) then seenSince = nil; setState("chase", who) end
		else seenSince = nil end
		if state == "patrol" then
			local lead = math.rad(30)
			ringAng = math.atan2(z - IZ, x - IX) + ringDir * lead
			local r2 = R / math.cos(lead)                           -- chasing a point this far out settles him on the ring
			moveToward(IX + math.cos(ringAng) * r2, IZ + math.sin(ringAng) * r2, A("SwimSpeed", 4.5) * slow, dt, 2.2)
			if t > nextStop then setState("guard"); nextStop = t + rng:NextNumber(14, 26) end
			if t > nextNap then setState("tonap") end
		elseif state == "guard" then
			-- a look-out: turn to face out over the lagoon, then carry on (sometimes the other way round)
			local out = math.atan2(-(x - IX), -(z - IZ))            -- the island at his back, looking out at the shore
			turnToward(out, dt * 0.5)
			if since > 4.5 then
				if rng:NextNumber() < 0.35 then ringDir = -ringDir end
				setState("patrol")
			end
		end
	elseif state == "tonap" then
		local d = moveToward(napX, napZ, A("SwimSpeed", 4.5) * slow, dt, 1.6)
		if d < 1.2 or since > 25 then setState("nap") end
	elseif state == "nap" then
		local who, dist = intruder(A("WakeRadius", 4.5) + 3)
		if who then setState("chase", who)
		elseif since > A("NapSeconds", 22) then nextNap = t + A("NapEvery", 70) * rng:NextNumber(0.8, 1.3); setState("patrol") end
	elseif state == "chase" then
		local h = target and hrpOf(target)
		if not h or held[target] or (immune[target] or 0) > t then setState("patrol")
		else
			if not inLagoon(h.Position) then
				lostSince = lostSince or t
				if t - lostSince > 1.5 then lostSince = nil; setState("guard") end
			else lostSince = nil end
			if state == "chase" then
				local bx, bz = x, z
				moveToward(h.Position.X, h.Position.Z, A("ChaseSpeed", 9.5) * slow, dt, 1.0)
				if t < flinchUntil then lastMoved = t end                -- (stopped by a bonk, not by the bank)
				if Vector3.new(x - bx, 0, z - bz).Magnitude > 0.05 then lastMoved = t end
				local s = snoutAt(x, z, yaw)
				local flat = Vector3.new(h.Position.X - s.X, 0, h.Position.Z - s.Z).Magnitude
				local blocked = t - lastMoved > 0.8                    -- at the island's edge (or the bank) and can't get nearer
				if flat < A("Reach", 3.4) and math.abs(h.Position.Y - s.Y) < 5 and t > lungeReady and t > flinchUntil then
					lungeFrom = Vector3.new(x, 0, z); setState("lunge", target)
				elseif blocked and flat < A("Reach", 3.4) + 3.5 and t > lungeReady + 2.2 then
					-- just out of reach: a snap at the air anyway (a miss, a splash)
					lungeFrom = Vector3.new(x, 0, z); setState("lunge", target)
				elseif blocked and t - lastMoved > 7 then
					-- they're safe where they are: he gives up for now and looks out over the water - their moment to run
					ignoreUntil[target] = t + 6
					setState("guard")
				end
			end
		end
	elseif state == "lunge" then
		-- a quick surge at the snout's target; the jaws shut at 0.3 s: caught, or a miss and a short breather
		local h = target and hrpOf(target)
		if since < 0.3 then
			local fx, fz = -math.sin(yaw), -math.cos(yaw)
			local nx, nz = x + fx * 7 * dt, z + fz * 7 * dt
			if okAt(nx, nz, yaw, 0.6) then x, z = nx, nz end
			if h then turnToward(math.atan2(-(h.Position.X - x), -(h.Position.Z - z)), dt) end
		else
			local s = snoutAt(x, z, yaw)
			if h and not held[target] and (immune[target] or 0) < t
				and Vector3.new(h.Position.X - s.X, 0, h.Position.Z - s.Z).Magnitude < A("Reach", 3.4) + 1.4 and math.abs(h.Position.Y - s.Y) < 6 then
				chomp(target)
			else
				lungeReady = t + 1.2
				evt:FireAllClients("miss")
				setState(target and "chase" or "patrol", target)
			end
		end
	elseif state == "hold" then
		local who = target
		if not who or not who.Parent then setState("patrol")
		elseif since > A("HoldTime", 1.7) then spit(who) end
	elseif state == "smug" then
		if since > 1.6 then setState("patrol") end
	elseif state == "dizzy" then
		if since > A("DizzySeconds", 3) then setState("sulk") end
	elseif state == "sulk" then
		local d = moveToward(sulkLobe[1], sulkLobe[2], A("SwimSpeed", 4.5) * 1.3, dt, 1.4)
		if d < 1.5 then turnToward(math.atan2(-(sulkLobe[1] - IX), -(sulkLobe[2] - IZ)), dt * 0.4) end
		if since > A("SulkSeconds", 20) + 4 then setState("patrol") end
	end
	-- stuck? (trying to go somewhere, getting nowhere): a stop on his patrol ring first, then on his way
	if tried and state ~= "chase" and state ~= "lunge" then
		stuckT = stuckT or t; stuckAt = stuckAt or Vector3.new(x, 0, z)
		if (Vector3.new(x, 0, z) - stuckAt).Magnitude > 0.6 then stuckT, stuckAt = t, Vector3.new(x, 0, z)
		elseif t - stuckT > 2.5 then
			stuckT, stuckAt = t, Vector3.new(x, 0, z)
			detourSide = nil
			local Rring = A("PatrolRadius", 12)
			local a = math.atan2(z - IZ, x - IX)
			local rNow = math.sqrt((x - IX) ^ 2 + (z - IZ) ^ 2)
			if math.abs(rNow - Rring) < 2 then a = a + ringDir * math.rad(60) end
			waypoint = {IX + math.cos(a) * Rring, IZ + math.sin(a) * Rring, t + 5}
		end
	else stuckT, stuckAt = nil, nil end
	tried = false
	-- anyone let go without a spit (left, died) is freed
	for p in pairs(held) do if not p.Parent or state ~= "hold" then held[p] = nil end end

	-- (his speed, for the slingshot's aim)
	local cv = os.clock()
	if lastVT and cv - lastVT > 0.02 then
		velX = velX + ((x - lastVX) / (cv - lastVT) - velX) * 0.6
		velZ = velZ + ((z - lastVZ) / (cv - lastVT) - velZ) * 0.6
	end
	lastVX, lastVZ, lastVT = x, z, cv
	pubAcc += dt
	if pubAcc >= 0.1 then
		pubAcc = 0
		croc:SetAttribute("Pose", CFrame.new(x, t % 4096, z) * CFrame.Angles(0, yaw, 0))
	end
end)
Players.PlayerRemoving:Connect(function(p) immune[p] = nil; held[p] = nil; rescues[p] = nil; ignoreUntil[p] = nil; heroes[p] = nil; fleeHourly[p] = nil end)
-- STUDIO TEST KIT (Shannon: "set me up with a slingshot so I can test the acorn to the head of the croc"): in Studio
-- only, and only while Studio cannot reach the saved data (API access off - a test can save nothing), everyone who joins
-- gets a slingshot and 100 acorns to shoot with. If the probe read works, the kit is not given (it could be saved).
-- Switch it off with the Lagoon attribute StudioKit = false.
if RunService:IsStudio() and L:GetAttribute("StudioKit") ~= false then
	task.spawn(function()
		local ok = pcall(function() return game:GetService("DataStoreService"):GetDataStore("SquirrelFinds_v1"):GetAsync("studio_kit_probe") end)
		if ok then warn("CrocServer: Studio test kit NOT given - Studio can reach the saved data (API access is on)") return end
		local function kit(p)
			local t0 = os.clock()
			while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 20 do task.wait(0.25) end   -- after the (failed) load
			if not p.Parent then return end
			p:SetAttribute("Item_slingshot", 1)
			p:SetAttribute("Acorns", math.max(p:GetAttribute("Acorns") or 0, 100))
			print("CrocServer: Studio test kit - a slingshot and 100 acorns for " .. p.Name .. " (not saved: Studio has no data access)")
		end
		Players.PlayerAdded:Connect(kit)
		for _, p in ipairs(Players:GetPlayers()) do task.spawn(kit, p) end
	end)
end
print("CrocServer: ready")

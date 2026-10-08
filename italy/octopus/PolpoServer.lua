-- PolpoServer: Polpo Brontolone, the grumpy octopus of the Grotta Azzurra (Porto Nocciola). The cave game, built like the
-- croc's (workspace.Lagoon.CrocServer): three caged squirrels on the ledge, him in the pool behind it. Anyone who comes past
-- the mouth wakes him; on the ledge within his reach a tentacle winds up and grabs - held a moment in front of his face,
-- then flung out of the cave onto the sand in a cloud of ink. Three slingshot bonks on his head inside BonkWindow make him
-- dizzy, and he sinks to sulk on the bottom - the ledge is safe while he sulks. Free a cage with its prompt for acorns
-- (hourly cap), an "all three free" toast for everyone, the cages fill again after RespawnSeconds. He never moves out of
-- the pool: the server keeps the state (State/StateAt/Target/Yaw/Arm attributes on the model); PolpoClient draws him.
-- Items are saved by SquirrelSetup through ReplicatedStorage.AwardItems; this script never touches the DataStore.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local G = script.Parent
local polpo = G:WaitForChild("PolpoBrontolone")
local body = polpo:WaitForChild("Octopus")
local evt = G:WaitForChild("PolpoEvent")
local cages = G:WaitForChild("Cages")
local award = RS:WaitForChild("AwardAcorns", 30)
local items = RS:WaitForChild("AwardItems", 30)
local picked = RS:FindFirstChild("AcornPicked")
local function A(n, d) local v = G:GetAttribute(n); if v == nil then return d end return v end
local function now() return workspace:GetServerTimeNow() end
local rng = Random.new()

-- the cave: his home frame (facing the mouth), the pool, the ledge
local HOME = polpo:GetAttribute("Home") or body.CFrame
local WATER_Y = A("WaterY", -53)
local CX, CZ = HOME.Position.X, HOME.Position.Z
local MOUTH_X = A("MouthX", 442)                                   -- west of this you are out of the cave (the sand)
local HALF_Z = A("HalfZ", 17)                                      -- the cave's half width
local FRONT = A("FrontOffset", 7)                                  -- his face is this far toward the mouth from his pivot
local function front() return Vector3.new(CX - FRONT, WATER_Y, CZ) end
local function inGrotto(pos)
	if pos.Y > WATER_Y + 16 or pos.Y < WATER_Y - 12 then return false end
	return pos.X > MOUTH_X and math.abs(pos.Z - CZ) < HALF_Z
end
local SPITS = {}
for x, z in string.gmatch(A("SpitSpots", ""), "([%-%d%.]+),([%-%d%.]+)") do table.insert(SPITS, Vector3.new(tonumber(x), WATER_Y + 1.6, tonumber(z))) end
if #SPITS == 0 then SPITS = {Vector3.new(MOUTH_X - 8, WATER_Y + 1.6, CZ)} end

local state, stateAt, target = "lurk", now(), nil
local yaw, armIdx = 0, 1
local function setState(s, who)
	state = s; stateAt = now(); target = who
	polpo:SetAttribute("State", s); polpo:SetAttribute("StateAt", stateAt % 4096)
	polpo:SetAttribute("Target", who and who.UserId or 0)
	if s == "lurk" then yaw = 0; polpo:SetAttribute("Yaw", 0) end          -- back to watching the mouth
end
setState("lurk")
polpo:SetAttribute("Yaw", 0); polpo:SetAttribute("Arm", 1)

-- ---- who is in his cave
local immune, held, ignoreUntil = {}, {}, {}
local function hrpOf(p) local c = p.Character; local h = c and c:FindFirstChild("HumanoidRootPart"); local hum = c and c:FindFirstChildOfClass("Humanoid"); if h and hum and hum.Health > 0 then return h end end
-- ON HIS HEAD (Shannon: "make the top of his head solid so you can jump over him"): standing on him is the way past - he
-- cannot reach you up there, and for OverHimGrace seconds after you hop off the far side he is too baffled to grab
local lastOn, wasOn = {}, {}
local function onHim(h)
	local d = Vector3.new(h.Position.X - HOME.Position.X, 0, h.Position.Z - HOME.Position.Z).Magnitude
	return d < A("OnHimRadius", 8.5) and h.Position.Y > WATER_Y - 1.5
end
local function intruder()
	-- (v2) his reach is from his pivot: the whole pool and the first studs of BOTH ledges - he turns round for the back one
	local f = HOME.Position
	local best, bd = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if h and not held[p] and (immune[p] or 0) < now() and (ignoreUntil[p] or 0) < now() and inGrotto(h.Position)
			and not onHim(h) and now() - (lastOn[p] or -1e9) > A("OverHimGrace", 3.5) then
			local d = (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(f.X, 0, f.Z)).Magnitude
			if d < bd then best, bd = p, d end
		end
	end
	return best, bd
end
-- facing: he turns his head toward whoever he watches (the client eases it); the arm is the one on their side
local function faceToward(pos)
	local rel = HOME:PointToObjectSpace(pos)
	local want = math.deg(math.atan2(-rel.X, -rel.Z))               -- 0 = straight at the mouth
	yaw = math.clamp(want, -A("MaxYaw", 55), A("MaxYaw", 55))
	polpo:SetAttribute("Yaw", yaw)
	armIdx = rel.X < 0 and 2 or 1                                   -- his left arm for someone on his left
	polpo:SetAttribute("Arm", armIdx)
end

-- ---- acorns
local function pay(player, n, from)
	if n <= 0 then return end
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + n)
	if award then award:Fire(player, n) end
	if picked and from then picked:FireClient(player, have + n, from, n) end
end

-- ---- slingshot bonks: every shot acorn is followed; a line from frame to frame through his head is a hit
local shots, bonks = {}, {}
local fleeHourly = {}
local flinchUntil = -1
local function headCentre() return HOME.Position + Vector3.new(0, A("HeadUp", 2.2), 0) end
local function segPointDist(p1, q1, c)
	local d = q1 - p1
	local L2 = d:Dot(d)
	if L2 < 1e-6 then return (p1 - c).Magnitude end
	local t = math.clamp((c - p1):Dot(d) / L2, 0, 1)
	return (p1 + d * t - c).Magnitude
end
local function hitsPolpo(a, b)
	if state == "sulk" then return segPointDist(a, b, HOME.Position - Vector3.new(0, 3, 0)) < A("BodyR", 5.5) end
	return segPointDist(a, b, headCentre()) < A("HeadR", 5.6)
end
-- where to aim (SlingServer asks): the top of his head, and he isn't going anywhere
local aimFn = G:FindFirstChild("PolpoAim")
if not aimFn then aimFn = Instance.new("BindableFunction"); aimFn.Name = "PolpoAim"; aimFn.Parent = G end
aimFn.OnInvoke = function()
	local lift = (state == "sulk" and -3.5) or (state == "hold" and 2.0) or (state == "alert" or state == "grab") and 1.2 or 0
	return headCentre() + Vector3.new(0, 2.2 + lift, 0), Vector3.zero
end
workspace.ChildAdded:Connect(function(c)
	if c.Name ~= "ShotAcorn" then return end
	task.defer(function()
		local nut = c.PrimaryPart or c:FindFirstChild("Nut") or c:FindFirstChildWhichIsA("BasePart")
		if not nut then return end
		if (nut.Position - HOME.Position).Magnitude > 160 then return end     -- a shot nowhere near the cave
		local id = nut:GetAttribute("ShooterId") or c:GetAttribute("ShooterId")
		local shooter = id and Players:GetPlayerByUserId(id)
		shots[nut] = {model = c, last = nut.Position, shooter = shooter, born = os.clock()}
	end)
end)
local function bonk(shooter, at)
	local t = now()
	if shooter then pay(shooter, A("BonkPrize", 1), at) end
	local counts = not (state == "dizzy" or state == "sulk" or state == "hold" or state == "fling")
	if counts then
		for i = #bonks, 1, -1 do if t - bonks[i] > A("BonkWindow", 25) then table.remove(bonks, i) end end
		table.insert(bonks, t)
	end
	local n, need = counts and #bonks or 0, A("BonksToFlee", 3)
	evt:FireAllClients("bonk", at, shooter and shooter.UserId or 0, n, need)
	print(string.format("PolpoServer: bonk by %s - %d of %d (%s)", shooter and shooter.Name or "?", n, need, state))
	if not counts then return end
	flinchUntil = t + 0.8
	if n >= need then
		bonks = {}
		if shooter then
			local list = fleeHourly[shooter] or {}; fleeHourly[shooter] = list
			for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
			if #list < A("FleeCap", 3) then table.insert(list, t); pay(shooter, A("FleePrize", 3), at) end
			evt:FireClient(shooter, "fled")
		end
		setState("dizzy")
	end
end

-- ---- the grab and the fling
local function grab(victim)
	held[victim] = true
	setState("hold", victim)
	evt:FireClient(victim, "grab", A("HoldTime", 1.7))
	evt:FireAllClients("grabfx", victim.UserId, armIdx)
end
local function fling(victim)
	held[victim] = nil
	local best, bd = SPITS[1], math.huge
	local h = hrpOf(victim)
	for _, s in ipairs(SPITS) do
		local d = rng:NextNumber(0, 8) + (h and (Vector3.new(s.X - h.Position.X, 0, s.Z - h.Position.Z).Magnitude) or 0)
		if d < bd then best, bd = s, d end
	end
	local flight = math.clamp((best - front()).Magnitude / 24, 0.9, 1.6)
	immune[victim] = now() + flight + A("Immune", 6)
	if victim.Parent then evt:FireClient(victim, "fling", best, flight) end
	evt:FireAllClients("flingfx", victim.UserId, flight, armIdx)
	setState("smug")
end

-- ---- rescues (the croc's rules)
local rescues = {}
local roundRescuers = {}
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
			local passport = RS:FindFirstChild("PassportActivity"); if passport then passport:Fire(player, "rescue", {}) end
			local nm = player.DisplayName
			local seen = false
			for _, n in ipairs(roundRescuers) do if n == nm then seen = true end end
			if not seen then table.insert(roundRescuers, nm) end
			local allFree = true
			for _, c in ipairs(cages:GetChildren()) do if c:GetAttribute("Occupied") then allFree = false end end
			if allFree then
				local names = roundRescuers
				roundRescuers = {}
				task.delay(1.3, function() evt:FireAllClients("allfree", names) end)
			end
			if #list < A("RescueCap", 20) then
				table.insert(list, t)
				pay(player, A("RescuePrize", 5), spot.Position)
				if items then items:Fire(player, "polpo_rescues", 1) end
			else
				evt:FireClient(player, "capped")
			end
			-- he is not having it: whoever is on his ledge is next
			if state == "lurk" or state == "smug" then setState("alert", player); faceToward(h.Position) end
			task.delay(A("RespawnSeconds", 90), function()
				while true do
					local busy = false
					for _, p in ipairs(Players:GetPlayers()) do
						local hh = hrpOf(p)
						if hh and inGrotto(hh.Position) then busy = true end
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

-- ---- the brain: 20 times a second
local grabReady = 0
local seenSince, lostSince = nil, nil
local acc = 0
RunService.Heartbeat:Connect(function(dtFrame)
	for nut, sh in pairs(shots) do
		if not nut.Parent or os.clock() - sh.born > 10 then shots[nut] = nil
		else
			local cur = nut.Position
			if hitsPolpo(sh.last, cur) then
				shots[nut] = nil
				sh.model:Destroy()
				bonk(sh.shooter, cur)
			else sh.last = cur end
		end
	end
	acc += dtFrame
	if acc < 0.05 then return end
	acc = 0
	local t = now()
	local since = t - stateAt
	-- on his head: a stomp the moment someone lands on him (the client growls and flinches); time on him is remembered
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		local on = (h and onHim(h)) or false
		if on then lastOn[p] = t; if not wasOn[p] then evt:FireAllClients("stomp", h.Position) end end
		wasOn[p] = on
	end
	if state == "lurk" then
		local who = intruder()
		if who then
			seenSince = seenSince or t
			if t - seenSince > A("NoticeDelay", 0.5) then seenSince = nil; setState("alert", who); faceToward(hrpOf(who).Position) end
		else seenSince = nil end
	elseif state == "alert" then
		local who, dist = intruder()
		if who then
			lostSince = nil
			local h = hrpOf(who)
			faceToward(h.Position)
			if dist < A("Reach", 15) and t > grabReady and t > flinchUntil and math.abs(h.Position.Y - WATER_Y) < 9 then
				setState("grab", who)
			end
		else
			lostSince = lostSince or t
			if t - lostSince > 3 then lostSince = nil; setState("lurk") end
		end
	elseif state == "grab" then
		-- the wind-up: the arm rises; at the end, caught or a miss (a slap on the water) and a short breather
		local h = target and hrpOf(target)
		if h then faceToward(h.Position) end
		if since > A("GrabWindup", 0.9) then
			local f = HOME.Position
			if h and not held[target] and (immune[target] or 0) < t and inGrotto(h.Position)
				and Vector3.new(h.Position.X - f.X, 0, h.Position.Z - f.Z).Magnitude < A("Reach", 15) + 2.5 and math.abs(h.Position.Y - WATER_Y) < 10 then
				grab(target)
			else
				grabReady = t + A("GrabCooldown", 2.5)
				evt:FireAllClients("miss", armIdx)
				setState("alert", target)
			end
		end
	elseif state == "hold" then
		local who = target
		if not who or not who.Parent then setState("lurk")
		elseif since > A("HoldTime", 1.7) then fling(who) end
	elseif state == "smug" then
		if since > 1.6 then grabReady = t + A("GrabCooldown", 2.5); setState("lurk") end
	elseif state == "dizzy" then
		if since > A("DizzySeconds", 3) then setState("sulk") end
	elseif state == "sulk" then
		if since > A("SulkSeconds", 20) then setState("lurk") end
	end
	for p in pairs(held) do if not p.Parent or state ~= "hold" then held[p] = nil end end
end)
Players.PlayerRemoving:Connect(function(p) immune[p] = nil; held[p] = nil; rescues[p] = nil; ignoreUntil[p] = nil; fleeHourly[p] = nil end)
print("PolpoServer: ready")

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local H = script.Parent
local shoot = RS:WaitForChild("SlingShot")
local award = RS:WaitForChild("AwardAcorns")
local items = RS:WaitForChild("AwardItems")
local picked = RS:WaitForChild("AcornPicked")
local template = SS:WaitForChild("AcornTemplate")
local toolTemplate = SS:WaitForChild("SlingshotTool")
local drawEvt = H:WaitForChild("DrawEvent")

-- ---- the draw flag: the drawing player says so; the character carries it for every other screen
drawEvt.OnServerEvent:Connect(function(pl, on)
	local ch = pl.Character
	if not ch then return end
	if on == true and ch:FindFirstChild("Slingshot") then ch:SetAttribute("SlingshotDraw", true) else ch:SetAttribute("SlingshotDraw", nil) end
end)

local function ring() return Vector3.new(H:GetAttribute("RingX"), H:GetAttribute("RingY"), H:GetAttribute("RingZ")) end
-- every hoop in the game (tagged AcornHoop by the builder); a shot is scored against the one nearest to where it left
local CollectionService = game:GetService("CollectionService")
local function ringOf(m) return Vector3.new(m:GetAttribute("RingX") or 0, m:GetAttribute("RingY") or 0, m:GetAttribute("RingZ") or 0) end
local function hoopFor(pos)
	local best, bestD = H, nil
	for _, m in ipairs(CollectionService:GetTagged("AcornHoop")) do
		if m:IsA("Model") and m:GetAttribute("RingX") then
			local d = (ringOf(m) - pos).Magnitude
			if not bestD or d < bestD then best, bestD = m, d end
		end
	end
	return best
end

-- ---- the tool follows ownership: whoever has Item_slingshot carries one, on every spawn and the moment it is bought
local function give(player)
	if (player:GetAttribute("Item_stow_slingshot") or 0) > 0 then return end   -- put away from the Acorn Store (StowServer, Oct 4 2026)
	if (player:GetAttribute("Item_slingshot") or 0) <= 0 then return end
	local char = player.Character
	if not char then return end
	local pack = player:FindFirstChildOfClass("Backpack")
	if (pack and pack:FindFirstChild("Slingshot")) or char:FindFirstChild("Slingshot") then return end
	local t = toolTemplate:Clone()
	t.Name = "Slingshot"
	t.Parent = pack or player
end
local function watch(player)
	player.CharacterAdded:Connect(function() task.wait(0.6); give(player) end)
	player:GetAttributeChangedSignal("Item_slingshot"):Connect(function() give(player) end)
	player:GetAttributeChangedSignal("Item_stow_slingshot"):Connect(function() give(player) end)
	if player.Character then task.defer(give, player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- the projectile: the same acorn that lies about the map, cut loose and welded into one piece
local function makeAcorn(from, velocity)
	local m = template:Clone()
	m.Name = "ShotAcorn"
	local nut = m.PrimaryPart or m:FindFirstChild("Nut")
	for _, d in ipairs(m:GetDescendants()) do
		if d.Name == "Hit" then d:Destroy() end
	end
	-- A SHOT YOU CAN SEE. The acorns on the ground are small on purpose; one of those doing a hundred studs a
	-- second twenty studs away is a speck ("the visual of the acorn flying is very difficult to see"). So the
	-- shot is bigger, throws off far more sparkle, and drags a golden ribbon that draws the whole arc.
	m:ScaleTo(H:GetAttribute("ShotScale") or 1)
	m:PivotTo(CFrame.new(from))
	local sp = nut:FindFirstChildOfClass("ParticleEmitter")
	if sp then
		sp.Rate = 40; sp.Speed = NumberRange.new(1, 3); sp.Lifetime = NumberRange.new(0.4, 0.9)
		sp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
		sp.Transparency = NumberSequence.new(0.1)
	end
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(-nut.Size.X * 0.4, 0, 0); a0.Parent = nut
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(nut.Size.X * 0.4, 0, 0); a1.Parent = nut
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 244, 210))
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1)})
	trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15)})
	trail.Lifetime = 0.6; trail.MinLength = 0.05; trail.LightEmission = 1; trail.FaceCamera = true
	trail.Parent = nut
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanQuery = false
			if p == nut then
				p.CanCollide = true; p.CanTouch = true; p.Massless = false
			else
				p.CanCollide = false; p.CanTouch = false; p.Massless = true
				local w = Instance.new("WeldConstraint"); w.Part0 = nut; w.Part1 = p; w.Parent = p
			end
		end
	end
	-- the sound of the flight, on the acorn so it goes where the acorn goes; slowed with the acorn in the cinematic
	local flyId = tonumber(H:GetAttribute("FlySoundId")) or 0
	local fly
	if flyId > 0 then
		fly = Instance.new("Sound"); fly.Name = "Fly"; fly.SoundId = "rbxassetid://" .. flyId
		fly.Volume = H:GetAttribute("FlyVolume") or 0.8; fly.RollOffMaxDistance = 90; fly.Parent = nut
	end
	m.Parent = workspace
	if fly then fly:Play() end
	nut:SetNetworkOwner(nil)                                -- the server flies it, so the ring sees the truth
	nut.AssemblyLinearVelocity = velocity
	nut.AssemblyAngularVelocity = Vector3.new(6, 2, 4)
	Debris:AddItem(m, 14)
	return nut
end

local passportRounds,passportShots={},{}
local function recordShot(nut,scored,prize)
 local rec=passportShots[nut];if not rec then return end;passportShots[nut]=nil
 local r=rec.round;r.results[rec.index]={scored=scored,prize=prize or 0}
 local streak,best,baskets,won,resolved=0,0,0,0,0
 for i=1,r.n do
  local result=r.results[i];if not result then break end
  resolved+=1
  if result.scored then streak+=1;baskets+=1;won+=result.prize;best=math.max(best,streak) else streak=0 end
 end
 if resolved==0 or not r.player.Parent then return end
 local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(r.player,"hoop",{streak=math.min(3,best),baskets=baskets,prize=won,shots=resolved,ongoing=resolved<r.n}) end
end
local function trackShot(player,nut,near)
 if not near then return end
 local r=passportRounds[player]
 if not r or r.n>=3 or os.clock()-r.started>(H:GetAttribute("RestSeconds") or 60) then r={player=player,n=0,results={},started=os.clock()};passportRounds[player]=r end
 r.n+=1;passportShots[nut]={round=r,index=r.n}
end

-- ---- the basket
local function basket(player, nut, hoop)
	hoop = hoop or H
	local centre = hoop:FindFirstChild("RingCentre")
	local burst = centre and centre:FindFirstChildOfClass("ParticleEmitter")
	local prize = H:GetAttribute("Prize") or 3
 recordShot(nut,true,prize)
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + prize)
	award:Fire(player, prize)
	items:Fire(player, "baskets", 1)
	picked:FireClient(player, have + prize, ringOf(hoop))
	shoot:FireClient(player, "basket", prize)
	if burst then burst.Rate = 120; task.delay(0.6, function() burst.Rate = 0 end) end
	-- the whistle as it drops through, the cheer a beat later, both from the ring so the clearing hears them
	local function ringSound(attr, delay)
		local id = tonumber(H:GetAttribute(attr)) or 0
		if id <= 0 or not centre then return end
		task.delay(delay, function()
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = H:GetAttribute("BasketVolume") or 1.0
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 20; s.RollOffMaxDistance = 250
			s.Parent = centre; s:Play(); Debris:AddItem(s, 15)
		end)
	end
	ringSound("BasketWhistleId", 0)
	ringSound("BasketCheerId", 0.35)
	print(string.format("%s: BASKET by %s (+%d, now %d)", hoop.Name, player.Name, prize, have + prize))
end

-- ---- shots
local live = {}                                          -- nut -> {player, last, born}
local lastShot = {}
-- THREE SHOTS, THEN A REST, at the croc and the hoops alike (Shannon, Sep 26: "make a cooldown so players don't just stay
-- there for 5 minutes shooting to harvest acorns ... allow 3 shots and then a cooldown period" - "cool down for both").
-- Counted here, on the server. ShotsBeforeRest / RestSeconds on the Hoop.
local volleys = {}                                       -- player -> {n = shots so far, last = when, restUntil = when}
-- AT THE LAGOON a shot flies AT something (the client says what): "croc" is the top of his head where it will be when
-- the acorn gets there (CrocServer's CrocAim function answers with where his head is and how fast he's going), "point"
-- the spot under the cursor. The flight is an arc that comes down exactly there - the farther, the longer and higher.
-- The hoop's fixed high lob, timed by the draw, could not hit a swimming croc.
local function flightTime(d) return math.clamp(0.35 + d / 90, 0.45, 1.1) end
local function aimedTarget(kind, point, from)
	if kind == "croc" or kind == "polpo" then
		-- (Oct 8 2026) "polpo" = Polpo Brontolone in the Grotta Azzurra: the same deal, his own aim function
		local lag = kind == "polpo" and workspace:FindFirstChild("Grotta") or workspace:FindFirstChild("Lagoon")
		local fn = lag and lag:FindFirstChild(kind == "polpo" and "PolpoAim" or "CrocAim")
		if fn and fn:IsA("BindableFunction") then
			local ok, head, vel = pcall(function() return fn:Invoke() end)
			if ok and typeof(head) == "Vector3" then
				local target = head
				if typeof(vel) == "Vector3" then
					for _ = 1, 3 do target = head + vel * flightTime((target - from).Magnitude) end   -- where he'll be
				end
				return target
			end
		end
	end
	if typeof(point) == "Vector3" and point.X == point.X and point.Y == point.Y and point.Z == point.Z then return point end
	return nil
end
shoot.OnServerEvent:Connect(function(player, dir, power, kind, point)
	if typeof(dir) ~= "Vector3" or type(power) ~= "number" then return end
	if dir.Magnitude < 0.5 or dir.X ~= dir.X then return end
	power = math.clamp(power, 0, 1)
	local char = player.Character
	local tool = char and char:FindFirstChild("Slingshot")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tool and hum and hum.Health > 0) then return end
	local now = os.clock()
	if now - (lastShot[player] or 0) < 0.5 then return end
	lastShot[player] = now
	local volley = volleys[player] or {n = 0, last = 0, restUntil = 0}; volleys[player] = volley
	if now < volley.restUntil then shoot:FireClient(player, "rest", math.ceil(volley.restUntil - now)) return end
	if now - volley.last > (H:GetAttribute("RestSeconds") or 60) then volley.n = 0 end
	local cost = H:GetAttribute("ShotCost") or 1
	local have = player:GetAttribute("Acorns") or 0
	if have < cost then shoot:FireClient(player, "no", "You need an acorn to shoot. Find one first.") return end
	player:SetAttribute("Acorns", have - cost)
	award:Fire(player, -cost)
	if volley then
		volley.n += 1; volley.last = now
		if volley.n >= (H:GetAttribute("ShotsBeforeRest") or 3) then
			local rest = H:GetAttribute("RestSeconds") or 60
			volley.n = 0; volley.restUntil = now + rest
			shoot:FireClient(player, "rest", rest, true)
		end
	end
	local eyeP = char:FindFirstChild("Head")
	local eye = eyeP and eyeP.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))
	local target = (kind == "croc" or kind == "polpo" or kind == "point") and aimedTarget(kind, point, eye)
	if target then
		local flat = (target - eye) * Vector3.new(1, 0, 1)
		local range = H:GetAttribute("AimRange") or 90
		if flat.Magnitude > range then target = Vector3.new(eye.X, target.Y, eye.Z) + flat.Unit * range; flat = flat.Unit * range end
		local from = eye + (flat.Magnitude > 0.1 and flat.Unit * 2.0 or Vector3.zero) + Vector3.new(0, 0.4, 0)
		local T = flightTime((target - from).Magnitude)
		local nut = makeAcorn(from, (target - from) / T + Vector3.new(0, 0.5 * workspace.Gravity * T, 0))
		nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
		shoot:FireClient(player, "shot", power)
		return
	end
	-- LAUNCH FROM THE HEAD, not from the tool's handle: the server's copy of the handle sits about a stud and
	-- a half from where the client sees it (the arm's tool-hold pose is not the same on both sides), and a
	-- launch point the two disagree on is an arc the player cannot learn. The head replicates exactly, and
	-- two studs along the aim from there is clear of the body.
	-- the aim gives the direction along the ground; the arc is fixed
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.05 then flat = char.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1) end
	local e = math.rad(H:GetAttribute("Elevation") or 66)
	dir = flat.Unit * math.cos(e) + Vector3.new(0, math.sin(e), 0)
	local head = char:FindFirstChild("Head")
	local from = (head and head.Position or (char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0))) + dir * 2.2
	local lo, hi = H:GetAttribute("MinSpeed") or 45, H:GetAttribute("MaxSpeed") or 115
	local nut = makeAcorn(from, dir * (lo + (hi - lo) * power))
	nut:SetAttribute("ShooterId", player.UserId)                  -- the croc needs to know who bonked him
	live[nut] = {player = player, last = nut.Position, born = now, start = nut.Position, hoop = hoopFor(from)}
 trackShot(player,nut,((from-ringOf(hoopFor(from)))*Vector3.new(1,0,1)).Magnitude<=(H:GetAttribute("MissRange") or 80))
	shoot:FireClient(player, "shot", power)
end)

-- Every frame, each acorn in the air is checked. Two things happen here:
--   * SCORING: crossing the plane of the ring on the way DOWN inside the opening. A trigger part would miss a
--     fast acorn between physics steps; a line between two positions cannot.
--   * THE CINEMATIC: once an acorn is descending, its landing point is known (no drag). If it will cross inside
--     the opening within SlowLead seconds, it is anchored and walked along that same parabola at SlowMo speed,
--     the shooter's camera is told to cut in, and the basket is paid at the moment it passes the ring. Then it
--     is handed back to physics to drop through the net.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local g = workspace.Gravity
	local nutR = ((template.PrimaryPart or template:FindFirstChild("Nut")).Size.X * (H:GetAttribute("ShotScale") or 1)) / 2
	local R = (H:GetAttribute("RingRadius") or 2.0) - nutR - 0.1        -- the whole acorn inside the opening
	local SLOW = H:GetAttribute("SlowMo") or 0.35
	local LEAD = H:GetAttribute("SlowLead") or 0.7
	for nut, rec in pairs(live) do
		local rc = ringOf(rec.hoop or H)
		if not nut.Parent or now - rec.born > 14 then
   recordShot(nut,false,0)
			live[nut] = nil
		elseif rec.cine then
			local c = rec.cine
			local tau = (now - c.t0) * SLOW                                   -- flight time, slowed
			local pos = c.p0 + c.v0 * tau + Vector3.new(0, -0.5 * g * tau * tau, 0)
			nut.CFrame = CFrame.new(pos) * CFrame.Angles(tau * 4, tau * 2.5, 0)
			if not c.scored and tau >= c.tCross then
				c.scored = true
				basket(rec.player, nut, rec.hoop)
			end
			if tau >= c.tCross + 0.22 then                                    -- through the net: physics again
				nut.Anchored = false
				nut.AssemblyLinearVelocity = c.v0 + Vector3.new(0, -g * tau, 0)
				live[nut] = nil
			end
		else
			local cur, vel = nut.Position, nut.AssemblyLinearVelocity
			if vel.Y < 0 then rec.peaked = true end
			-- A MISS: it has peaked and come back down past the ring's plane, or past where it started for a
			-- shot that never got that high, without scoring. The shooter hears the crowd's "ohhh"; nobody else.
			if rec.peaked and not rec.missed and (cur.Y < rc.Y - 1.5 or cur.Y < rec.start.Y - 0.5)
				and ((rec.start - rc) * Vector3.new(1, 0, 1)).Magnitude < (H:GetAttribute("MissRange") or 80) then   -- no crowd "ohhh" for shots nowhere near a hoop
				rec.missed = true
    recordShot(nut,false,0)
				live[nut] = nil
				shoot:FireClient(rec.player, "miss")
			elseif rec.last.Y > rc.Y and cur.Y <= rc.Y then
				local f = (rec.last.Y - rc.Y) / math.max(rec.last.Y - cur.Y, 1e-6)
				local x = rec.last:Lerp(cur, f)
				if ((x - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					live[nut] = nil
					basket(rec.player, nut, rec.hoop)
				end
			elseif now - rec.born > 0.05 then
				-- where will it come down through the ring plane, and when? (the larger root is the descending
				-- crossing, whether the acorn is still rising or already falling - so the slow motion can begin
				-- before the peak and the shooter sees it crest and drop)
				local h = cur.Y - rc.Y
				local disc = vel.Y * vel.Y + 2 * g * h
				local t = disc >= 0 and (vel.Y + math.sqrt(disc)) / g or -1
				local land = cur + Vector3.new(vel.X * t, 0, vel.Z * t)
				if t >= 0.1 and t <= LEAD and ((land - rc) * Vector3.new(1, 0, 1)).Magnitude <= R then
					rec.cine = {t0 = now, p0 = cur, v0 = vel, tCross = t, scored = false}
					local fly = nut:FindFirstChild("Fly"); if fly then fly.PlaybackSpeed = SLOW end
					nut.Anchored = true
					nut.AssemblyLinearVelocity = Vector3.zero
					shoot:FireClient(rec.player, "cine", nut, rc, (t + 0.22) / SLOW)
				end
			end
			rec.last = cur
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) lastShot[p] = nil; volleys[p] = nil;passportRounds[p]=nil;for nut,r in pairs(passportShots) do if r.round.player==p then passportShots[nut]=nil end end end)
print("SlingServer: ready")

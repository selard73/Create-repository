-- The lagoon's crocodile (Shannon, Sep 26 2026). Her Meshy "Chompy the Crocodile", rigged in Blender (croc/rig_croc.py: 22
-- bones - Hips, Chest, Neck, Head, a hinged Jaw weighted by hand under the mouth line, five tail bones round the curl, and
-- sprawled 3-bone legs), imported with Import 3D (croc/croc_rigged.fbx). Her brief: a cute scary croc who can chase and
-- chomp you, or you save the squirrels from him - guard-and-rescue, with the acorn slingshot.
--   HE GUARDS: swims a ring round the island where his captured squirrels sit in cages; now and then stops to look out,
--         and every minute or so naps in the west arm (sneak past him then). Only players in the lagoon count - in the
--         water, on the lily pads, on the island or right at the water's edge. Nobody on the grass is ever chased.
--   CHASE + CHOMP (harmless): he swims after an intruder (slower than a walking player), lunges when his snout is close,
--         holds the player in his jaws for a moment (legs dangling), shakes, and spits them out onto the south shore -
--         "CROQUE !" - then they can't be caught again for a few seconds.
--   BONK: a slingshot acorn that lands on him bonks him (the shot is refunded). BonksToFlee bonks inside BonkWindow
--         seconds and he's dizzy (stars round his head), then swims off to sulk in the far arm for SulkSeconds - the
--         island is free. The last bonk earns FleePrize (FleeCap times an hour). Near him the slingshot aims itself at
--         the top of his head (SlingServer asks the CrocAim function where it is and how fast he's going).
--   RESCUE: a cage's prompt frees its squirrel (RescuePrize acorns, capped per hour); he notices and comes for you. An
--         empty cage fills again RespawnSeconds later, when nobody is near the island.
-- Everything he does is decided on the server (CrocServer) and published as attributes on the Croc model: Pose (a
-- CFrame: x, server time mod 4096 in Y, z, and his heading), State, StateAt, Target. Every screen draws him itself
-- (CrocClient): it moves the model smoothly between the published poses and animates the bones (Bone.Transform, which
-- only works from a client script), plus the effects. The croc's name is the Lagoon's CrocName attribute.
-- Needs build_lagoon first (workspace.Lagoon). Run in edit mode (re-runnable; picks up workspace.croc_rigged if present).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local RS = game:GetService("ReplicatedStorage")
	local L = workspace:FindFirstChild("Lagoon")
	assert(L, "build the lagoon first (build_lagoon.lua)")
	local report = {}
	local function note(s) table.insert(report, s) end
	local SCALE = opts.scale or 0.8

	-- ---------------------------------------------------------------- tuning (attributes on the Lagoon) ----
	local DEFAULTS = {
		CrocName = "Croque-Monsieur",
		SwimSpeed = 4.5, ChaseSpeed = 9.5, TurnRate = 150, PatrolRadius = 12, Reach = 3.4, NoticeDelay = 0.6,
		HoldTime = 1.7, Immune = 6, NapEvery = 70, NapSeconds = 22, WakeRadius = 4.5,
		BonksToFlee = 3, BonkWindow = 25, DizzySeconds = 3, SulkSeconds = 20, BonkPrize = 1, FleePrize = 3, FleeCap = 3,
		RescuePrize = 5, RescueCap = 20, RespawnSeconds = 90,
		SnoutDepth = 0.45, HeadDepth = 0.25,                       -- how far under the surface the bed must be below his snout / head
		SplashSound = "rbxassetid://76469933896339",               -- Shannon's pick (Sep 26)
		DizzySound = "rbxassetid://266278159",                    -- Shannon's pick: a spat-out player seeing stars
		SpeechSounds = "73324775979494, 90860503936571, 9119556839",   -- Shannon's picks: a squirrel speaking (one at random; Sep 26: Squirrel/bug squeaking in for the too-short Squirrel Monkey 12)
		SpeechMax = 4,                                            -- a longer one fades out after this many seconds
		ChompSound = "", BurpSound = "", SnoreSound = "",
		GrumbleSound = "", BonkSound = "", RescueSound = "", SoundVolume = 0.9,
		OuchSound = "9125470306, 9125470288",                     -- HIS reaction to a bonk (one at random): Creature Growls Lion Deep Guttural Rumbling (SFX) - Shannon: "more like a low growl"
	}
	for k, v in pairs(DEFAULTS) do
		if opts[k] ~= nil then L:SetAttribute(k, opts[k]) elseif L:GetAttribute(k) == nil then L:SetAttribute(k, v) end
	end

	-- ---------------------------------------------------------------- the lagoon's shape ----
	local WATER_Y, GROW = L:GetAttribute("WaterY"), L:GetAttribute("Grow")
	local LOBES = {}
	for x, z, r in string.gmatch(L:GetAttribute("Lobes"), "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do table.insert(LOBES, {tonumber(x), tonumber(z), tonumber(r)}) end
	local IX, IZ, IR = L:GetAttribute("IslandX"), L:GetAttribute("IslandZ"), L:GetAttribute("IslandR")
	local function sdfWater(x, z) local b = -math.huge for _, l in ipairs(LOBES) do b = math.max(b, l[3] - math.sqrt((x - l[1]) ^ 2 + (z - l[2]) ^ 2)) end return b end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = {workspace.Terrain, workspace:FindFirstChild("Baseplate")}; rp.IgnoreWater = true
	local function groundAt(x, z)
		local r = workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), rp)
		return r and r.Position.Y or 0
	end

	-- ---------------------------------------------------------------- the model ----
	local croc = L:FindFirstChild("Croc")
	local imported = workspace:FindFirstChild("croc_rigged")
	if imported then
		if croc then croc:Destroy() end
		croc = imported; croc.Name = "Croc"; croc.Parent = L
	end
	assert(croc, "no croc model: Import 3D croc/croc_rigged.fbx first")
	local body = croc:FindFirstChild("Body") or croc:FindFirstChild("Croc") or croc:FindFirstChildWhichIsA("MeshPart")
	body.Name = "Body"
	for _, d in ipairs(croc:GetChildren()) do if d:IsA("AnimationController") then d:Destroy() end end
	croc.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	croc:ScaleTo(SCALE)
	body.Anchored = true; body.CanCollide = false; body.CanTouch = false; body.CanQuery = false
	body.CastShadow = true; body.Massless = true
	local s = croc:GetScale()
	local size = body.Size
	-- his own frame: origin at the bottom centre of his body, facing -Z at heading 0 (as Import 3D left him). Offsets in
	-- studs, measured on the Blender model (snout at y 0, tail tip at 16, belly z 0; Blender +X = his left = -X here).
	local SINK = opts.sink or 2.9 * s                                  -- in the water his bottom sits this far down
	local function off(bx, by, bz) return Vector3.new(-bx * s, bz * s, (by - 8) * s) end
	croc:SetAttribute("SwimSink", SINK)
	croc:SetAttribute("SnoutOffset", off(0, 0.1, 3.45))
	croc:SetAttribute("MouthOffset", off(0, 2.0, 2.55))
	croc:SetAttribute("TailBaseOffset", off(-0.5, 12.3, 2.0))
	croc:SetAttribute("TailTipOffset", off(0.9, 15.2, 4.3))
	croc:SetAttribute("HeadTopOffset", off(0, 3.3, 6.4))
	croc:SetAttribute("BodyRadius", 2.3 * s)
	croc:SetAttribute("MeshOffset", CFrame.new(0, size.Y / 2, 0))
	-- home: on his ring, west of the island, looking south at the path in
	local R = L:GetAttribute("PatrolRadius")
	local hx, hz, hyaw = IX - R, IZ, math.pi
	croc:SetAttribute("HomeX", hx); croc:SetAttribute("HomeZ", hz); croc:SetAttribute("HomeYaw", hyaw)
	body.CFrame = CFrame.new(hx, WATER_Y - SINK, hz) * CFrame.Angles(0, hyaw, 0) * CFrame.new(0, size.Y / 2, 0)
	croc:SetAttribute("Pose", CFrame.new(hx, 0, hz) * CFrame.Angles(0, hyaw, 0))
	croc:SetAttribute("State", "patrol"); croc:SetAttribute("StateAt", 0); croc:SetAttribute("Target", 0)
	local nb = 0
	for _, b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then nb += 1 end end
	note(string.format("croc: scale %.2f, %.1f x %.1f x %.1f studs, %d bones, home %.0f,%.0f", s, size.X, size.Y, size.Z, nb, hx, hz))

	-- ---------------------------------------------------------------- spit-out spots: open grass on the south shore ----
	local F = workspace:FindFirstChild("Forest")
	local trees = {}
	if F then
		for _, m in ipairs(F:GetChildren()) do
			if m:IsA("Model") then
				local ok, cf, sz = pcall(function() return m:GetBoundingBox() end)
				if ok then table.insert(trees, {cf.Position, math.max(sz.X, sz.Z) / 2}) end
			end
		end
	end
	local spots = {}
	local sign = Vector3.new(L:GetAttribute("SignX") or 104, 0, L:GetAttribute("SignZ") or -147)
	for x = 94, 130, 3 do
		for _, z in ipairs({-141, -144}) do
			local p = Vector3.new(x, 0, z)
			local clear = sdfWater(x, z) < -(GROW + 2) and (p - sign).Magnitude > 3.5
			for _, t in ipairs(trees) do
				if (Vector3.new(t[1].X, 0, t[1].Z) - p).Magnitude < t[2] + 2.5 then clear = false end
			end
			if clear then table.insert(spots, string.format("%d,%d", x, z)) break end
		end
	end
	L:SetAttribute("SpitSpots", table.concat(spots, ";"))
	note(#spots .. " spit-out spots on the south shore")

	-- ---------------------------------------------------------------- the cages on the island ----
	local old = L:FindFirstChild("Cages"); if old then old:Destroy() end
	local cages = Instance.new("Folder"); cages.Name = "Cages"; cages.Parent = L
	local WOOD, DARK, IRON = C(150, 104, 64), C(92, 62, 40), C(64, 64, 72)
	local function part(name, sz, cf, colour, material, shape, parent)
		local p = Instance.new("Part"); p.Name = name; p.Size = sz; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
	local twins = workspace:FindFirstChild("SquirrelTwins")
	local captiveNames = opts.captives or {"gordo_squirrel_gray", "ballerina_squirrel_gray", "baking_betty_squirrel_gray"}
	local W, H = 2.5, 2.7
	for k = 1, 3 do
		local ang = math.rad((opts.cageAngles and opts.cageAngles[k]) or (30 + (k - 1) * 120))   -- 30/150/270: the south (the pads) stays open
		local cx, cz = IX + math.cos(ang) * 2.9, IZ + math.sin(ang) * 2.9
		local gy = groundAt(cx, cz)
		-- the doors face the middle of the island: his snout reaches the beach, not the middle, so a rescuer standing
		-- there is safe - the danger is the crossing
		local out = -Vector3.new(math.cos(ang), 0, math.sin(ang))
		local base = CFrame.lookAt(Vector3.new(cx, gy, cz), Vector3.new(cx, gy, cz) + out)
		local cage = Instance.new("Model"); cage.Name = "Cage" .. k; cage.Parent = cages
		cage:SetAttribute("Occupied", true); cage:SetAttribute("Index", k)
		part("Floor", Vector3.new(W, 0.3, W), base * CFrame.new(0, 0.15, 0), WOOD, Enum.Material.WoodPlanks, nil, cage)
		part("Roof", Vector3.new(W + 0.3, 0.26, W + 0.3), base * CFrame.new(0, H, 0), DARK, Enum.Material.Wood, nil, cage)
		local ring = part("Handle", Vector3.new(0.14, 0.9, 0.9), base * CFrame.new(0, H + 0.5, 0) * CFrame.Angles(0, math.rad(90), 0), IRON, Enum.Material.Metal, Enum.PartType.Cylinder, cage)
		ring.Transparency = 0
		for _, c in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do
			part("Post", Vector3.new(0.26, H, 0.26), base * CFrame.new(c[1] * (W / 2 - 0.13), H / 2, c[2] * (W / 2 - 0.13)), DARK, Enum.Material.Wood, nil, cage)
		end
		local function bars(fromX, fromZ, toX, toZ, parent)
			for b = 1, 3 do
				local t = b / 4
				local x, z = fromX + (toX - fromX) * t, fromZ + (toZ - fromZ) * t
				local bar = part("Bar", Vector3.new(H - 0.2, 0.13, 0.13), base * CFrame.new(x, H / 2, z) * UPRIGHT, IRON, Enum.Material.Metal, Enum.PartType.Cylinder, parent)
				bar.CanCollide = false
			end
		end
		local h = W / 2 - 0.13
		bars(-h, h, h, h, cage)            -- back
		bars(-h, -h, -h, h, cage)          -- left
		bars(h, -h, h, h, cage)            -- right
		-- the door (front, facing out), hinged on its left post
		local door = Instance.new("Model"); door.Name = "Door"; door.Parent = cage
		local hinge = base * CFrame.new(-h, H / 2, -h)
		door:SetAttribute("Hinge", hinge)
		part("DoorTop", Vector3.new(W - 0.3, 0.16, 0.16), base * CFrame.new(0, H - 0.25, -h), DARK, Enum.Material.Wood, nil, door)
		part("DoorLow", Vector3.new(W - 0.3, 0.16, 0.16), base * CFrame.new(0, 0.45, -h), DARK, Enum.Material.Wood, nil, door)
		bars(-h, -h, h, -h, door)
		local lock = part("Lock", Vector3.new(0.3, 0.36, 0.2), base * CFrame.new(h - 0.2, H / 2, -h - 0.12), C(196, 160, 60), Enum.Material.Metal, nil, door)
		lock.CanCollide = false
		-- the captive: a squirrel's mesh borrowed from the gray twins (a stand-in until Shannon makes baby squirrels)
		local twin = twins and twins:FindFirstChild(captiveNames[k])
		local captive
		if twin then
			local c2 = twin:Clone()
			for _, d in ipairs(c2:GetDescendants()) do
				if d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("AnimationController") or d:IsA("BillboardGui") then d:Destroy() end
			end
			for _, tag in ipairs(game:GetService("CollectionService"):GetTags(c2)) do game:GetService("CollectionService"):RemoveTag(c2, tag) end
			for key in pairs(c2:GetAttributes()) do if key:sub(1, 4) ~= "RBX_" then c2:SetAttribute(key, nil) end end   -- (RBX_ ones are Roblox's)
			c2.Name = "Captive"
			-- (the twins' pivots are tipped, so size and facing come from the mesh itself: its world box, and the line
			-- from its tail bone to its head bone)
			local mp = c2:FindFirstChildWhichIsA("MeshPart", true)
			local function box()
				local cf, hs = mp.CFrame, mp.Size / 2
				local ex = Vector3.new(
					math.abs(cf.RightVector.X) * hs.X + math.abs(cf.UpVector.X) * hs.Y + math.abs(cf.LookVector.X) * hs.Z,
					math.abs(cf.RightVector.Y) * hs.X + math.abs(cf.UpVector.Y) * hs.Y + math.abs(cf.LookVector.Y) * hs.Z,
					math.abs(cf.RightVector.Z) * hs.X + math.abs(cf.UpVector.Z) * hs.Y + math.abs(cf.LookVector.Z) * hs.Z)
				return cf.Position, ex
			end
			local _, ex0 = box()
			c2:ScaleTo(c2:GetScale() * (1.55 / (ex0.Y * 2)))
			local hb, tb = mp:FindFirstChild("Head", true), mp:FindFirstChild("Tail1", true)
			local front = (hb and tb) and (hb.WorldPosition - tb.WorldPosition) or Vector3.new(0, 0, -1)
			front = Vector3.new(front.X, 0, front.Z)
			front = front.Magnitude > 0.01 and front.Unit or Vector3.new(0, 0, -1)
			local turn = math.atan2(-out.X, -out.Z) - math.atan2(-front.X, -front.Z)     -- face out through the door
			local c0 = box()
			c2:PivotTo(CFrame.new(c0) * CFrame.Angles(0, turn, 0) * CFrame.new(-c0) * c2:GetPivot())
			local c1, ex1 = box()
			local seat = base * CFrame.new(0, 0.3, 0.15)
			c2:PivotTo(CFrame.new(seat.Position.X - c1.X, seat.Position.Y + ex1.Y - c1.Y, seat.Position.Z - c1.Z) * c2:GetPivot())
			for _, d in ipairs(c2:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false end end
			-- no bones: SquirrelSetup counts any mesh with Root and Tail2 bones as a collectible squirrel (it found these
			-- and started them "in colour"); a captive never moves, so it keeps its pose without them
			for _, d in ipairs(c2:GetDescendants()) do
				if d.Parent and (d:IsA("Bone") or (d:IsA("Folder") and d.Name == "InitialPoses")) then d:Destroy() end
			end
			c2.Parent = cage
			captive = c2
		end
		cage:SetAttribute("HasCaptive", captive ~= nil)
		local spot = part("PromptSpot", Vector3.new(0.4, 0.4, 0.4), base * CFrame.new(0, 1.2, -h - 0.6), WOOD, nil, nil, cage)
		spot.Transparency = 1; spot.CanCollide = false; spot.CanQuery = false
		local pp = Instance.new("ProximityPrompt"); pp.Name = "RescuePrompt"; pp.ActionText = "Rescue"; pp.ObjectText = "Squirrel"
		pp.HoldDuration = 0.5; pp.MaxActivationDistance = 4; pp.RequiresLineOfSight = false; pp.Parent = spot
	end
	note("3 cages on the island" .. (twins and "" or " (no SquirrelTwins: empty cages)"))

	-- ---------------------------------------------------------------- the sign shows his name ----
	local signModel = L:FindFirstChild("Props") and L.Props:FindFirstChild("WarningSign")
	local label = signModel and signModel:FindFirstChild("CrocName", true)
	if label then label.Text = L:GetAttribute("CrocName") end

	local evt = L:FindFirstChild("CrocEvent")
	if not evt then evt = Instance.new("RemoteEvent"); evt.Name = "CrocEvent"; evt.Parent = L end

	-- ================================================================ SERVER ================================================
	local SERVER = [==[local Players = game:GetService("Players")
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
]==]

	-- ================================================================ CLIENT ================================================
	local CLIENT = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local L = script.Parent
local croc = L:WaitForChild("Croc")
local evt = L:WaitForChild("CrocEvent")
local C = Color3.fromRGB
local function A(n, d) local v = L:GetAttribute(n); if v == nil then return d end return v end
local function now() return workspace:GetServerTimeNow() end
local WATER_Y = A("WaterY", -1)
local FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)

-- ---- the model (streaming may swap the parts, so everything is looked up again when the body changes)
local body, bones, rest
local ORDER = {"Hips", "Chest", "Neck", "Head", "Jaw", "Tail1", "Tail2", "Tail3", "Tail4", "Tail5",
	"FrontUpper.L", "FrontLower.L", "FrontFoot.L", "FrontUpper.R", "FrontLower.R", "FrontFoot.R",
	"HindUpper.L", "HindLower.L", "HindFoot.L", "HindUpper.R", "HindLower.R", "HindFoot.R"}
local fwdL, upL, leftL
local MESH_OFF = croc:GetAttribute("MeshOffset") or CFrame.new(0, 2.4, 0)
local SINK = croc:GetAttribute("SwimSink") or 2.3
local MOUTH = croc:GetAttribute("MouthOffset") or Vector3.new(0, 2.0, -4.8)
local SNOUT = croc:GetAttribute("SnoutOffset") or Vector3.new(0, 2.8, -6.3)
local HEADTOP = croc:GetAttribute("HeadTopOffset") or Vector3.new(0, 5.0, -3.6)

local function bind()
	local b = croc:FindFirstChild("Body")
	if not b then body = nil return end
	if b == body then return end
	body = b; bones = {}
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("Bone") then bones[d.Name] = d end end
	-- his axes, in the mesh's own frame (measured from the bones, whichever way Import 3D turned them)
	local hips, head = bones.Hips, bones.Head
	local f = (head and hips) and (head.WorldPosition - hips.WorldPosition) or b.CFrame.LookVector
	f = Vector3.new(f.X, 0, f.Z).Unit
	fwdL = b.CFrame:VectorToObjectSpace(f)
	upL = b.CFrame:VectorToObjectSpace(Vector3.yAxis)
	leftL = upL:Cross(fwdL)
end
bind()
croc.DescendantAdded:Connect(function() task.defer(bind) end)

-- ---- where he is: the server's poses, drawn 0.15 s behind so there is always a next one to glide to
local samples = {}
local function unwrap(tm)
	local n = now()
	local d = ((tm - n % 4096 + 2048) % 4096) - 2048
	return n + d
end
local function takePose()
	local cf = croc:GetAttribute("Pose")
	if typeof(cf) ~= "CFrame" then return end
	local _, ry = cf:ToOrientation()
	table.insert(samples, {t = unwrap(cf.Y), x = cf.X, z = cf.Z, yaw = ry})
	while #samples > 40 do table.remove(samples, 1) end
end
takePose()
croc:GetAttributeChangedSignal("Pose"):Connect(takePose)
local function angLerp(a, b, t) local d = (b - a + math.pi) % (2 * math.pi) - math.pi return a + d * t end
local function poseAt(rt)
	local n = #samples
	if n == 0 then return croc:GetAttribute("HomeX") or 0, croc:GetAttribute("HomeZ") or 0, croc:GetAttribute("HomeYaw") or 0 end
	if rt <= samples[1].t then local s = samples[1] return s.x, s.z, s.yaw end
	for i = n - 1, 1, -1 do
		local a, b = samples[i], samples[i + 1]
		if rt >= a.t and rt <= b.t then
			local u = (rt - a.t) / math.max(b.t - a.t, 1e-3)
			return a.x + (b.x - a.x) * u, a.z + (b.z - a.z) * u, angLerp(a.yaw, b.yaw, u)
		end
	end
	local s = samples[n]
	return s.x, s.z, s.yaw
end

-- ---- the ground under him (the bank lifts him when he comes out of the water)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.IgnoreWater = true
rp.FilterDescendantsInstances = {workspace.Terrain}
local function bedAt(px, pz)
	local r = workspace:Raycast(Vector3.new(px, 6, pz), Vector3.new(0, -30, 0), rp)
	return r and r.Position.Y or -50
end

-- ---- bones: a pose is {pitch, yaw, roll} per bone in HIS axes (pitch about his left: negative lifts the front/tip;
-- yaw about up: positive turns to his left; roll about his forward) - the same numbers as the Blender test poses
local cur = {}
for _, n in ipairs(ORDER) do cur[n] = {0, 0, 0} end
local function applyBones(want, dt)
	if not body or not bones then return end
	local k = 1 - math.exp(-dt * 12)
	local mcf = body.CFrame
	local leftW, upW, fwdW = mcf:VectorToWorldSpace(leftL), mcf:VectorToWorldSpace(upL), mcf:VectorToWorldSpace(fwdL)
	for _, name in ipairs(ORDER) do
		local b = bones[name]
		local c = cur[name]
		local w = want[name]
		c[1] += ((w and w[1] or 0) - c[1]) * k; c[2] += ((w and w[2] or 0) - c[2]) * k; c[3] += ((w and w[3] or 0) - c[3]) * k
		if b then
			if math.abs(c[1]) + math.abs(c[2]) + math.abs(c[3]) < 0.01 then b.Transform = CFrame.identity
			else
				local parent = b.Parent
				local pw = (parent:IsA("Bone") and parent.TransformedWorldCFrame) or mcf
				local R = (pw * b.CFrame).Rotation
				b.Transform = CFrame.fromAxisAngle(R:VectorToObjectSpace(upW), math.rad(c[2]))
					* CFrame.fromAxisAngle(R:VectorToObjectSpace(leftW), math.rad(c[1]))
					* CFrame.fromAxisAngle(R:VectorToObjectSpace(fwdW), math.rad(c[3]))
			end
		end
	end
end

-- ---- little effects
local function billboard(text, at, colour, secs, size)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(at); p.Parent = workspace
	local g = Instance.new("BillboardGui"); g.Size = UDim2.fromOffset(220, 60); g.AlwaysOnTop = true; g.LightInfluence = 0
	g.MaxDistance = 120; g.Parent = p
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Text = text
	t.FontFace = FONT; t.TextSize = size or 30; t.TextColor3 = colour or C(255, 255, 255); t.Parent = g
	local st = Instance.new("UIStroke"); st.Thickness = 2.5; st.Color = C(40, 26, 14); st.Parent = t
	TweenService:Create(p, TweenInfo.new(secs or 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(at + Vector3.new(0, 2.2, 0))}):Play()
	TweenService:Create(t, TweenInfo.new(secs or 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
	TweenService:Create(st, TweenInfo.new(secs or 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
	Debris:AddItem(p, (secs or 1.1) + 0.1)
end
local function sound(attr, at, vol)
	local id = A(attr, "")
	if type(id) == "number" then id = id > 0 and ("rbxassetid://" .. id) or "" end
	if id == "" then return end
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(at); p.Parent = workspace
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = (vol or 1) * A("SoundVolume", 0.9)
	s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 12; s.RollOffMaxDistance = 140; s.Parent = p
	s:Play(); Debris:AddItem(p, 8)
end
-- one id at random from a list attribute ("id, id, ...")
local function soundOne(attr, at, vol)
	local ids = {}
	for d in tostring(A(attr, "")):gmatch("%d+") do table.insert(ids, d) end
	if #ids == 0 then return end
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(at); p.Parent = workspace
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. ids[math.random(#ids)]; s.Volume = (vol or 1) * A("SoundVolume", 0.9)
	s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 12; s.RollOffMaxDistance = 140; s.Parent = p
	s:Play(); Debris:AddItem(p, 8)
end
local function splash(at, n)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(2, 0.2, 2); p.CFrame = CFrame.new(at.X, WATER_Y + 0.1, at.Z); p.Parent = workspace
	local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(6, 12); e.SpreadAngle = Vector2.new(35, 35)
	e.EmissionDirection = Enum.NormalId.Top; e.Lifetime = NumberRange.new(0.5, 0.9); e.Acceleration = Vector3.new(0, -40, 0)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.1)})
	e.Color = ColorSequence.new(C(220, 240, 255)); e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
	e.LightEmission = 0.3; e.Parent = p
	e:Emit(n or 30)
	Debris:AddItem(p, 2)
end
local stars
local function showStars(secs)
	if stars then stars:Destroy() end
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2); p.Parent = workspace
	local g = Instance.new("BillboardGui"); g.Size = UDim2.fromOffset(170, 80); g.AlwaysOnTop = false; g.LightInfluence = 0; g.Parent = p
	for i = 1, 3 do
		local t = Instance.new("TextLabel"); t.Name = "Star"; t.BackgroundTransparency = 1; t.Size = UDim2.fromOffset(36, 36)
		t.AnchorPoint = Vector2.new(0.5, 0.5); t.Text = utf8.char(0x2605); t.TextSize = 32; t.TextColor3 = C(255, 222, 80); t.Parent = g
		local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = C(120, 80, 10); st.Parent = t
	end
	stars = p
	Debris:AddItem(p, secs)
end
local zzzT = 0
local bonkedAt = nil                                              -- when the last bonk landed: he flinches
-- the BONK! sign: the word, and for the shooter how many more it takes, in one sign so they never overlap
local function bonkSign(at, sub)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = CFrame.new(at); p.Parent = workspace
	local g = Instance.new("BillboardGui"); g.Size = UDim2.fromOffset(280, 96); g.AlwaysOnTop = true; g.LightInfluence = 0
	g.MaxDistance = 140; g.Parent = p
	local fades = {}
	local function line(text, y, h, size, colour)
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.fromOffset(0, y); t.Size = UDim2.new(1, 0, 0, h)
		t.Text = text; t.FontFace = FONT; t.TextSize = size; t.TextColor3 = colour; t.Parent = g
		local st = Instance.new("UIStroke"); st.Thickness = 2.5; st.Color = C(40, 26, 14); st.Parent = t
		table.insert(fades, t); table.insert(fades, st)
	end
	line("BONK!", 0, 54, 46, C(255, 236, 140))
	if sub then line(sub, 56, 32, 24, C(255, 255, 255)) end
	local secs = 1.3
	TweenService:Create(p, TweenInfo.new(secs, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(at + Vector3.new(0, 2.2, 0))}):Play()
	for _, o in ipairs(fades) do
		TweenService:Create(o, TweenInfo.new(secs, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {[o:IsA("UIStroke") and "Transparency" or "TextTransparency"] = 1}):Play()
	end
	Debris:AddItem(p, secs + 0.1)
end

-- ---- the chomped player's own screen: held in the jaws, then spat out
local held, heldUntil = false, 0
local dizzyUntil = nil                                            -- my camera sways a moment after I land
-- DIZZY (Shannon: "for a few seconds after the player is back on land, animation around their head like with birds or
-- squiggly lines"): little birds and stars circle the spat-out player's head, on every screen
local function dizzyBirds(who, secs)
	local ch = who and who.Character
	local head = ch and ch:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("CrocDizzy"); if old then old:Destroy() end
	-- sized in studs, so it stays the size of a head at any distance; just above the head, tight to it
	local g = Instance.new("BillboardGui"); g.Name = "CrocDizzy"; g.Adornee = head; g.Size = UDim2.new(4.4, 0, 1.7, 0)
	g.StudsOffset = Vector3.new(0, 1.05, 0); g.LightInfluence = 0; g.MaxDistance = 90; g.Parent = head
	local items = {}
	for i = 1, 5 do
		local star = i <= 3
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Size = star and UDim2.fromScale(0.2, 0.52) or UDim2.fromScale(0.12, 0.32)
		t.Text = star and utf8.char(0x2605) or utf8.char(0x2726); t.TextScaled = true; t.FontFace = FONT
		t.TextColor3 = star and C(255, 214, 64) or C(255, 246, 190); t.Parent = g
		if star then local st = Instance.new("UIStroke"); st.Thickness = 1.2; st.Color = C(150, 96, 12); st.Parent = t end
		table.insert(items, t)
	end
	local id = A("DizzySound", "")
	if type(id) == "number" then id = id > 0 and ("rbxassetid://" .. id) or "" end
	if id ~= "" then
		local s = Instance.new("Sound"); s.SoundId = id; s.Volume = A("SoundVolume", 0.9)
		s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 90; s.Parent = head
		s:Play(); Debris:AddItem(s, math.max(secs, 4))
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local u = os.clock() - t0
		if u > secs or not g.Parent then conn:Disconnect(); if g.Parent then g:Destroy() end return end
		local fade = math.clamp((secs - u) / 0.5, 0, 1)
		for i, lbl in ipairs(items) do
			-- three stars racing round a tilted ring, two little glints further round it
			local a = u * 7.5 + (i <= 3 and (i - 1) * (math.pi * 2 / 3) or (i - 3.5) * math.pi + 0.9)
			local depth = math.sin(a)
			lbl.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.36, 0.5 + depth * 0.2)
			local glint = i > 3 and (0.35 + 0.65 * math.abs(math.sin(u * 9 + i))) or 1
			lbl.TextTransparency = 1 - fade * glint * (0.45 + 0.55 * (depth + 1) / 2)
			local st = lbl:FindFirstChildOfClass("UIStroke"); if st then st.Transparency = lbl.TextTransparency end
			lbl.ZIndex = depth > 0 and 2 or 1
		end
	end)
end
-- PRAISE bubbles: the squirrel the server names says the line, for everyone near (the baguette chase's bubble look)
local function praiseBubble(model, text)
	if typeof(model) ~= "Instance" or not model.Parent or type(text) ~= "string" then return end
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not anchor or not pg then return end
	local bb = Instance.new("BillboardGui"); bb.Name = "PraiseBubble"; bb.Size = UDim2.fromOffset(280, 70); bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.MaxDistance = 80; bb.Adornee = anchor; bb.AlwaysOnTop = true; bb.Parent = pg
	local f = Instance.new("TextLabel"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = C(34, 30, 64); f.BackgroundTransparency = 0.08
	f.FontFace = FONT; f.TextScaled = true; f.TextColor3 = C(255, 244, 214); f.Text = text; f.Parent = bb
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = f
	local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 12); p.PaddingRight = UDim.new(0, 12); p.PaddingTop = UDim.new(0, 7); p.PaddingBottom = UDim.new(0, 7); p.Parent = f
	local ids = {}
	for d in tostring(A("SpeechSounds", "")):gmatch("%d+") do table.insert(ids, d) end
	if #ids > 0 then
		local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. ids[math.random(#ids)]; s.Volume = A("SoundVolume", 0.9)
		s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 80; s.Parent = anchor
		s:Play(); Debris:AddItem(s, 8)
		-- a long one is cut short, faded out after SpeechMax seconds (Shannon: "not quite the whole 8 seconds")
		task.delay(A("SpeechMax", 4), function() if s.Parent and s.IsPlaying then TweenService:Create(s, TweenInfo.new(0.5), {Volume = 0}):Play() end end)
	end
	task.delay(4.5, function() if bb.Parent then bb:Destroy() end end)
end
local heroStage, heroLast, heroNext = nil, nil, 0
-- THE TOAST when all three are free: a card drops in at the top (the daily card's look), confetti falls from it, and
-- the game's found-a-squirrel fanfare plays; confetti bursts over the island too for anyone near
local function celebrate(names)
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
	local old = pg:FindFirstChild("CrocToast"); if old then old:Destroy() end
	local g = Instance.new("ScreenGui"); g.Name = "CrocToast"; g.ResetOnSpawn = false; g.DisplayOrder = 19; g.IgnoreGuiInset = true; g.Parent = pg
	local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, -150)
	card.Size = UDim2.fromOffset(390, 104); card.BackgroundColor3 = C(38, 30, 52); card.BorderSizePixel = 0; card.Parent = g
	local ck = Instance.new("UICorner"); ck.CornerRadius = UDim.new(0, 16); ck.Parent = card
	local cs = Instance.new("UIStroke"); cs.Color = C(240, 196, 110); cs.Thickness = 2; cs.Parent = card
	local list = {}
	for _, n in ipairs(type(names) == "table" and names or {}) do if type(n) == "string" then table.insert(list, n) end end
	local who = #list == 0 and "you" or (#list == 1 and list[1]) or (table.concat(list, ", ", 1, #list - 1) .. " & " .. list[#list])
	local function line(text, y, h, size, colour)
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.new(0, 14, 0, y); t.Size = UDim2.new(1, -28, 0, h)
		t.Text = text; t.FontFace = FONT; t.TextSize = size; t.TextColor3 = colour; t.TextWrapped = true; t.Parent = card
		return t
	end
	line("Hooray! All 3 squirrels are free!", 14, 32, 24, C(255, 244, 214))
	line("Madame Margaux says merci, " .. who .. "!", 52, 40, 18, C(240, 196, 110))
	TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 62)}):Play()
	-- confetti from the card
	local COLOURS = {C(255, 120, 120), C(255, 206, 90), C(120, 210, 140), C(120, 170, 255), C(230, 140, 230), C(255, 255, 255)}
	task.delay(0.45, function()
		for i = 1, 34 do
			local bit = Instance.new("Frame"); bit.BorderSizePixel = 0; bit.Size = UDim2.fromOffset(math.random(6, 10), math.random(8, 14))
			bit.BackgroundColor3 = COLOURS[math.random(#COLOURS)]; bit.AnchorPoint = Vector2.new(0.5, 0.5)
			local x0 = math.random(-190, 190)
			bit.Position = UDim2.new(0.5, x0, 0, 70 + math.random(0, 40)); bit.Rotation = math.random(0, 360); bit.Parent = g
			local fall = math.random(260, 420)
			TweenService:Create(bit, TweenInfo.new(math.random(14, 22) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, x0 + math.random(-60, 60), 0, 70 + fall), Rotation = bit.Rotation + math.random(-360, 360), BackgroundTransparency = 1}):Play()
		end
	end)
	-- the fanfare the game plays for a find
	local ss = workspace:FindFirstChild("SquirrelScripts")
	local fid = tostring(ss and (ss:GetAttribute("FoundSound") or ss:GetAttribute("FoundSound_village")) or "1845415163"):match("%d+")
	if fid then
		local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. fid; s.Volume = 0.8; s.Parent = g; s:Play()
	end
	-- a burst over the island for anyone near
	local ix, iz = L:GetAttribute("IslandX"), L:GetAttribute("IslandZ")
	if ix and iz then
		local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
		p.Size = Vector3.new(4, 0.2, 4); p.CFrame = CFrame.new(ix, 4, iz); p.Parent = workspace
		local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(14, 24); e.SpreadAngle = Vector2.new(40, 40)
		e.EmissionDirection = Enum.NormalId.Top; e.Lifetime = NumberRange.new(1.6, 2.6); e.Acceleration = Vector3.new(0, -26, 0)
		e.Drag = 1.5; e.RotSpeed = NumberRange.new(-220, 220); e.Rotation = NumberRange.new(0, 360)
		e.Size = NumberSequence.new(0.35); e.Shape = Enum.ParticleEmitterShape.Box
		e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(255, 120, 120)), ColorSequenceKeypoint.new(0.33, C(255, 206, 90)),
			ColorSequenceKeypoint.new(0.66, C(120, 170, 255)), ColorSequenceKeypoint.new(1, C(120, 210, 140))})
		e.Parent = p; e:Emit(90)
		Debris:AddItem(p, 4)
	end
	task.delay(5.2, function()
		if not card.Parent then return end
		local t = TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -150)})
		t:Play(); t.Completed:Connect(function() g:Destroy() end)
	end)
end
local heroAsked = nil
local flying = nil
local function myChar() local c = player.Character; return c, c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid") end
local function banner(text, sub)
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
	local old = pg:FindFirstChild("CrocBanner"); if old then old:Destroy() end
	local g = Instance.new("ScreenGui"); g.Name = "CrocBanner"; g.ResetOnSpawn = false; g.DisplayOrder = 20; g.Parent = pg
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.AnchorPoint = Vector2.new(0.5, 0); t.Position = UDim2.new(0.5, 0, 0.16, 0)
	t.Size = UDim2.fromOffset(520, 70); t.Text = text; t.FontFace = FONT; t.TextSize = 56; t.TextColor3 = C(255, 244, 214); t.Parent = g
	local st = Instance.new("UIStroke"); st.Thickness = 4; st.Color = C(60, 30, 14); st.Parent = t
	if sub then
		local u = Instance.new("TextLabel"); u.BackgroundTransparency = 1; u.AnchorPoint = Vector2.new(0.5, 0); u.Position = UDim2.new(0.5, 0, 0.16, 68)
		u.Size = UDim2.fromOffset(520, 34); u.Text = sub; u.FontFace = FONT; u.TextSize = 24; u.TextColor3 = C(255, 255, 255); u.Parent = g
		local us = Instance.new("UIStroke"); us.Thickness = 2.5; us.Color = C(60, 30, 14); us.Parent = u
	end
	task.delay(1.6, function()
		for _, d in ipairs(g:GetDescendants()) do
			if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.5), {TextTransparency = 1}):Play() end
			if d:IsA("UIStroke") then TweenService:Create(d, TweenInfo.new(0.5), {Transparency = 1}):Play() end
		end
		Debris:AddItem(g, 0.6)
	end)
end
local function mouthCF()
	if not body or not bones or not bones.Head then return nil end
	local head = bones.Head
	return head.TransformedWorldCFrame * (head.WorldCFrame:Inverse() * (body.CFrame * MESH_OFF:Inverse() * CFrame.new(MOUTH)))
end
evt.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "chomp" then
		held = true; heldUntil = os.clock() + (a or 1.7) + 2.5
		local _, hrp, hum = myChar()
		if hum then hum.PlatformStand = true end
		banner("CROQUE !", A("CrocName", "The croc") .. " caught you!")
	elseif kind == "spit" then
		-- flown along the arc frame by frame (a thrown velocity got eaten by the humanoid getting up), with a somersault
		held = false
		local _, hrp = myChar()
		if hrp then
			local p0, p1 = hrp.Position, a + Vector3.new(0, 3, 0)
			flying = {p0 = p0, p1 = p1, t0 = os.clock(), tf = b or 1.1, h = 5 + (p1 - p0).Magnitude * 0.18}
		end
		banner("Ptooey!", nil)
	elseif kind == "fled" then
		banner("BONK!", "He's off to sulk - rescue the squirrels!")
	elseif kind == "capped" then
		banner("Merci !", "The squirrels thank you - no more acorns for rescues this hour.")
	end
end)
RunService:BindToRenderStep("CrocHold", Enum.RenderPriority.Character.Value + 1, function()
	if dizzyUntil then
		local _, _, hum = myChar()
		local left = dizzyUntil - os.clock()
		if not hum or left <= 0 then
			if hum then hum.CameraOffset = Vector3.zero end
			dizzyUntil = nil
		else
			local k = math.clamp(left / 1.0, 0, 1)
			local tt = os.clock()
			hum.CameraOffset = Vector3.new(math.sin(tt * 5.5) * 0.55, math.sin(tt * 3.3) * 0.25, 0) * k
		end
	end
	if flying then
		local _, hrp, hum = myChar()
		if not hrp or not hum then flying = nil return end
		local u = (os.clock() - flying.t0) / flying.tf
		local dir = (flying.p1 - flying.p0) * Vector3.new(1, 0, 1)
		local look = dir.Magnitude > 0.1 and dir.Unit or Vector3.zAxis
		if u >= 1 then
			hrp.CFrame = CFrame.lookAt(flying.p1, flying.p1 - look)      -- landing facing the lagoon (and him)
			hrp.AssemblyLinearVelocity = Vector3.new(0, -8, 0); hrp.AssemblyAngularVelocity = Vector3.zero
			hum.PlatformStand = false
			flying = nil
			dizzyUntil = os.clock() + 3.2
			return
		end
		local pos = flying.p0:Lerp(flying.p1, u) + Vector3.new(0, flying.h * 4 * u * (1 - u), 0)
		hrp.CFrame = CFrame.lookAt(pos, pos - look) * CFrame.Angles(u * math.pi * 2, 0, 0)   -- flying backwards, a back flip
		hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
		return
	end
	if not held then return end
	if os.clock() > heldUntil then held = false; local _, _, hum = myChar(); if hum then hum.PlatformStand = false end return end
	local _, hrp = myChar()
	local m = mouthCF()
	if hrp and m then
		-- torso in his jaws, legs dangling out under the chin, looking back at him
		local look = m.Position - (body and body.CFrame.LookVector or Vector3.zAxis) * 3
		hrp.CFrame = CFrame.lookAt(m.Position + Vector3.new(0, -0.9, 0), Vector3.new(look.X, m.Position.Y - 0.9, look.Z))
		hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
	end
end)

-- ---- effects everyone sees
evt.OnClientEvent:Connect(function(kind, a, b, c, d)
	local bodyPos = body and body.Position or Vector3.zero
	if kind == "bonk" then
		-- he flinches (the pose, below), splashes as his head is knocked down, and stars circle his head for a moment
		-- (the third bonk's stars are the dizzy ones)
		bonkedAt = os.clock()
		local top = body and (body.CFrame * MESH_OFF:Inverse() * HEADTOP) or a
		splash(top, 22)
		local n, need = c or 0, d or 3
		if not (n > 0 and n >= need) then showStars(1.4) end
		local sub
		if b == player.UserId and n > 0 and n < need then sub = (need - n == 1) and "1 more bonk!" or ((need - n) .. " more bonks!") end
		bonkSign(a + Vector3.new(0, 1.8, 0), sub)
		sound("BonkSound", a, 1)
		-- and HIS reaction a beat after the hit (Shannon: "his reaction sound to the bonk"), from his head
		task.delay(0.12, function() soundOne("OuchSound", top, 1) end)
		if b == player.UserId then billboard("+" .. tostring(A("BonkPrize", 1)), a + Vector3.new(2.2, 0.6, 0), C(255, 214, 90), 1.0, 24) end
	elseif kind == "chompfx" then
		local m = body and body.CFrame * MESH_OFF:Inverse() * SNOUT or bodyPos
		splash(m, 40); sound("SplashSound", m, 0.8); sound("ChompSound", m, 1)
		billboard("CROQUE !", m + Vector3.new(0, 3, 0), C(255, 244, 214), 1.0, 36)
	elseif kind == "spitfx" then
		local m = body and body.CFrame * MESH_OFF:Inverse() * SNOUT or bodyPos
		billboard("Ptooey!", m + Vector3.new(0, 2.5, 0), C(200, 240, 255), 1.0, 30)
		task.delay(0.7, function() sound("BurpSound", m, 1) end)
		local who = Players:GetPlayerByUserId(a or 0)
		if who then task.delay((b or 1.1) + 0.05, function() dizzyBirds(who, 3.8) end) end
	elseif kind == "praise" then
		praiseBubble(a, b)
	elseif kind == "allfree" then
		celebrate(a)
	elseif kind == "praiseok" then
		heroLast = heroAsked; heroAsked = nil; heroNext = os.clock() + 4
		heroStage = (a or 1) + 1
		if heroStage > 2 then heroStage = nil end
	elseif kind == "miss" then
		local m = body and body.CFrame * MESH_OFF:Inverse() * SNOUT or bodyPos
		splash(m, 20); sound("SplashSound", m, 0.6)
	elseif kind == "rescued" then
		if b == player.UserId and not heroStage then heroStage = 1; heroLast = nil; heroNext = os.clock() + 2 end
		local cage = L:FindFirstChild("Cages") and L.Cages:FindFirstChild(a)
		local captive = cage and cage:FindFirstChild("Captive")
		local door = cage and cage:FindFirstChild("Door")
		if door then
			local hinge = door:GetAttribute("Hinge")
			if hinge then
				for _, d in ipairs(door:GetChildren()) do
					if d:IsA("BasePart") then
						local rel = hinge:ToObjectSpace(d.CFrame)
						local v = Instance.new("NumberValue"); v.Value = 0
						v.Changed:Connect(function(x) d.CFrame = hinge * CFrame.Angles(0, math.rad(x), 0) * rel end)
						TweenService:Create(v, TweenInfo.new(0.45, Enum.EasingStyle.Back), {Value = 105}):Play()
						Debris:AddItem(v, 1)
					end
				end
			end
		end
		if captive then
			local cf0 = captive:GetPivot()
			local out = cf0.LookVector
			billboard("Merci !", cf0.Position + Vector3.new(0, 2.4, 0), C(255, 255, 255), 1.4, 30)
			sound("RescueSound", cf0.Position, 1)
			local v = Instance.new("NumberValue"); v.Value = 0
			v.Changed:Connect(function(u)
				local hop = math.abs(math.sin(u * math.pi * 2)) * 1.6
				captive:PivotTo(cf0 + out * (u * 3) + Vector3.new(0, hop, 0))
			end)
			TweenService:Create(v, TweenInfo.new(1.1, Enum.EasingStyle.Linear), {Value = 1}):Play()
			task.delay(1.15, function()
				for _, d in ipairs(captive:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end
				splash(cf0.Position + out * 3, 12)
			end)
			Debris:AddItem(v, 2)
		end
	end
end)
task.spawn(function()
	local CS = game:GetService("CollectionService")
	while true do
		task.wait(0.4)
		if heroStage and os.clock() > heroNext then
			local _, hrp = myChar()
			if hrp then
				local best, bd = nil, 12
				for _, m in ipairs(CS:GetTagged("Squirrel")) do
					if m ~= heroLast and m:IsA("Model") then
						local ok, pos = pcall(function() return m:GetPivot().Position end)
						if ok then
							local d = (pos - hrp.Position).Magnitude
							if d < bd then best, bd = m, d end
						end
					end
				end
				if best then
					evt:FireServer("praise", best)
					heroAsked = best
					heroNext = os.clock() + 1.5                          -- no answer by then: ask again
				end
			end
		end
	end
end)
-- cages follow their Occupied attribute (a squirrel back in a closed cage when it fills again, for everyone,
-- late joiners too)
local function syncCage(cage)
	local occ = cage:GetAttribute("Occupied")
	local captive = cage:FindFirstChild("Captive")
	if captive then
		if not cage:GetAttribute("CapHome") then cage:SetAttribute("CapHome", captive:GetPivot()) end
		if occ then
			captive:PivotTo(cage:GetAttribute("CapHome"))
			for _, d in ipairs(captive:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end
		else
			for _, d in ipairs(captive:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end
		end
	end
	local door = cage:FindFirstChild("Door")
	local hinge = door and door:GetAttribute("Hinge")
	if door and hinge then
		for _, d in ipairs(door:GetChildren()) do
			if d:IsA("BasePart") then
				if not d:GetAttribute("Home") then d:SetAttribute("Home", d.CFrame) end
				local home = d:GetAttribute("Home")
				d.CFrame = occ and home or (hinge * CFrame.Angles(0, math.rad(105), 0) * hinge:ToObjectSpace(home))
			end
		end
	end
end
local function watchCages()
	local cages = L:FindFirstChild("Cages")
	if not cages then return end
	for _, cage in ipairs(cages:GetChildren()) do
		if not cage:GetAttribute("Watched") then
			cage:SetAttribute("Watched", true)
			cage:GetAttributeChangedSignal("Occupied"):Connect(function()
				if cage:GetAttribute("Occupied") then syncCage(cage) else task.delay(1.3, function() syncCage(cage) end) end
			end)
			syncCage(cage)
		end
	end
end
watchCages()
L.DescendantAdded:Connect(function(d) if d:IsA("Model") and d.Parent and d.Parent.Name == "Cages" then task.defer(watchCages) end end)

-- ---- every frame: place him, then pose him
local phase, lastYaw, yawRate, lastX, lastZ, speed = 0, nil, 0, nil, nil, 0
local clack, nextClack = -1, os.clock() + 6
local lift, liftGoal = 0, 0
RunService.RenderStepped:Connect(function(dt)
	if not body then bind(); if not body then return end end
	local t = now()
	local px, pz, pyaw = poseAt(t - 0.15)
	if lastX then
		local sp = Vector3.new(px - lastX, 0, pz - lastZ).Magnitude / math.max(dt, 1e-3)
		speed += (sp - speed) * (1 - math.exp(-dt * 6))
		local dy = (pyaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
		yawRate += (dy / math.max(dt, 1e-3) - yawRate) * (1 - math.exp(-dt * 5))
	end
	lastX, lastZ, lastYaw = px, pz, pyaw
	local state = croc:GetAttribute("State") or "patrol"
	local sAt = croc:GetAttribute("StateAt") or 0
	local since = ((t % 4096) - sAt + 4096) % 4096
	-- height: afloat (eyes and back above the water), lifted when he lunges or holds someone, lower when he naps;
	-- never through the bed of the lagoon
	liftGoal = (state == "lunge" and 0.7) or (state == "hold" and 1.1) or (state == "spit" and 0.9) or (state == "smug" and 0.5)
		or (state == "nap" and -0.45) or (state == "sulk" and -0.25) or 0
	lift += (liftGoal - lift) * (1 - math.exp(-dt * 5))
	local bob = math.sin(t * 1.3) * 0.06
	if bonkedAt then bob -= 0.3 * math.sin(math.pi * math.clamp((os.clock() - bonkedAt) / 0.45, 0, 1)) end   -- knocked down a little
	local bottom = math.max(WATER_Y - SINK + lift + bob, bedAt(px, pz) - 0.25)
	body.CFrame = CFrame.new(px, bottom, pz) * CFrame.Angles(0, pyaw, 0) * MESH_OFF

	-- ---- the pose
	local W = {}
	local function add(n, p, y, r) local w = W[n]; if not w then w = {0, 0, 0}; W[n] = w end; w[1] += p or 0; w[2] += y or 0; w[3] += r or 0 end
	local amp = math.clamp(speed / 5, 0.3, 1.25)
	phase += dt * (1.3 + speed * 0.32) * math.pi * 2 * 0.5
	-- swimming: legs folded back along his sides, the tail sculls, the body answers it
	-- (gently: big turns at the shoulder crease the mesh - Blender check pc_swim_*.png)
	local paddle = 7 * math.clamp(1.4 - speed / 4, 0, 1) * math.sin(phase * 0.5)
	add("FrontUpper.L", 0, 18 + paddle, 7); add("FrontUpper.R", 0, -18 + paddle, -7)
	add("HindUpper.L", 0, 16 - paddle, 5); add("HindUpper.R", 0, -16 - paddle, -5)
	local tails = {{"Tail1", 7, 0}, {"Tail2", 10, 0.8}, {"Tail3", 13, 1.6}, {"Tail4", 12, 2.4}, {"Tail5", 10, 3.2}}
	for _, tl in ipairs(tails) do add(tl[1], 0, tl[2] * amp * math.sin(phase - tl[3]), 0) end
	add("Hips", 0, -4 * amp * math.sin(phase + 0.6), 0); add("Chest", 0, 3 * amp * math.sin(phase + 1.2), 0)
	add("Neck", 0, -2.5 * amp * math.sin(phase + 1.8), 0)
	-- turning bends him along his path
	local bend = math.clamp(math.deg(yawRate) * 0.25, -16, 16)
	add("Chest", 0, bend * 0.5, 0); add("Neck", 0, bend * 0.45, 0)
	add("Tail1", 0, -bend * 0.4, 0); add("Tail2", 0, -bend * 0.5, 0); add("Tail3", 0, -bend * 0.5, 0)
	-- the jaw: mostly shut (a toothy grin) unless he means business; a lazy clack now and then
	local jaw = -15
	if os.clock() > nextClack and (state == "patrol" or state == "guard") then clack = os.clock(); nextClack = os.clock() + math.random(6, 12) end
	if clack > 0 then
		local u = os.clock() - clack
		if u < 0.45 then jaw += math.sin(u / 0.45 * math.pi) * 16 else clack = -1 end
	end
	-- looking at the nearest player close by (patrol, guard, chase)
	local lookYaw = 0
	if state == "patrol" or state == "guard" or state == "chase" or state == "smug" then
		local best, bd = nil, 26
		for _, p in ipairs(Players:GetPlayers()) do
			local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if h then
				local d = (h.Position - body.Position).Magnitude
				if d < bd then best, bd = h, d end
			end
		end
		if best then
			local rel = body.CFrame:PointToObjectSpace(best.Position)
			local fwd = MESH_OFF:Inverse()
			local ang = math.deg(math.atan2(-rel.X, -rel.Z))
			lookYaw = math.clamp(ang, -35, 35)
		end
	end
	add("Neck", 0, lookYaw * 0.45, 0); add("Head", 0, lookYaw * 0.55, 0)
	if state == "chase" then
		jaw = 2; add("Head", -5, 0, 0); add("Neck", -3, 0, 0)
	elseif state == "lunge" then
		local u = math.clamp(since / 0.35, 0, 1)
		jaw = u < 0.6 and (16 * u / 0.6) or (16 - 38 * (u - 0.6) / 0.4)
		add("Neck", -8, 0, 0); add("Head", -6 * (1 - u), 0, 0)
	elseif state == "hold" then
		jaw = -16
		add("Neck", -10, 0, 0); add("Head", -16, 14 * math.sin(since * 17) * math.clamp((since - 0.15) * 3, 0, 1) * math.clamp(1.3 - since, 0, 1), 0)
	elseif state == "spit" or (state == "smug" and since < 0.45) then
		local u = math.clamp(since / 0.45, 0, 1)
		jaw = 18 * math.sin(u * math.pi)
		add("Neck", -12 * math.sin(u * math.pi), 0, 0); add("Head", -18 * math.sin(u * math.pi), 0, 0)
	elseif state == "smug" then
		jaw = -20; add("Head", -6, 0, 0)
	elseif state == "nap" then
		jaw = -22; add("Neck", 7, 0, 0); add("Head", 5, 0, 0)
		add("Chest", 1.5 * math.sin(t * 1.2), 0, 0)
		if os.clock() > zzzT then
			zzzT = os.clock() + 1.4
			local top = body.CFrame * MESH_OFF:Inverse() * HEADTOP
			billboard(zzzT % 2 < 1 and "z" or "Z", top + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5), C(235, 245, 255), 1.6, 26)
			if math.random() < 0.3 then sound("SnoreSound", top, 0.6) end
		end
	elseif state == "dizzy" then
		jaw = 6
		add("Head", 0, 12 * math.sin(t * 5), 12 * math.cos(t * 5)); add("Neck", 4, 0, 0)
		if not stars or not stars.Parent then showStars(A("DizzySeconds", 3) + 0.2); sound("GrumbleSound", body.Position, 1) end
	elseif state == "sulk" then
		jaw = -22; add("Neck", 5, 0, 0); add("Head", 6, 0, 0)
		add("Tail3", 0, 8 * math.sin(t * 0.8), 0)
	end
	-- BONKED (Shannon: "he does not react when you bonk him"): his head is knocked down, springs back up with his mouth
	-- open in an "ow", and he shakes it off; his tail thrashes and his front legs flinch
	if bonkedAt then
		local u = os.clock() - bonkedAt
		if u > 1.25 then bonkedAt = nil
		else
			local knock = (u < 0.1 and 16 * u / 0.1) or (u < 0.35 and 16 - 30 * (u - 0.1) / 0.25) or (-14 * math.clamp(1 - (u - 0.35) / 0.5, 0, 1))
			local shake = math.clamp(1 - u / 1.25, 0, 1) * math.clamp((u - 0.25) / 0.15, 0, 1)
			add("Neck", knock * 0.45, 0, 0)
			add("Head", knock, 16 * math.sin(u * 24) * shake, 10 * math.sin(u * 19 + 1) * shake)
			if u > 0.1 and u < 0.8 then jaw = math.max(jaw, 8) end                                   -- "ow"
			add("Tail2", 0, 18 * math.sin(u * 16) * shake, 0); add("Tail3", 0, 24 * math.sin(u * 16 - 0.9) * shake, 0)
			add("Tail4", 0, 20 * math.sin(u * 16 - 1.8) * shake, 0)
			local flinch = math.clamp(1 - math.abs(u - 0.15) / 0.35, 0, 1)
			add("FrontUpper.L", 0, -12 * flinch, 0); add("FrontUpper.R", 0, 12 * flinch, 0)
		end
	end
	add("Jaw", jaw + 0, 0, 0)
	applyBones(W, dt)
	-- stars circle his head while he's dizzy
	if stars and stars.Parent then
		local top = body.CFrame * MESH_OFF:Inverse() * HEADTOP
		stars.CFrame = CFrame.new(top)
		local g = stars:FindFirstChildOfClass("BillboardGui")
		if g then
			for i, st in ipairs(g:GetChildren()) do
				if st.Name == "Star" then
					local a = t * 4 + i * (math.pi * 2 / 3)
					st.Position = UDim2.new(0.5, math.cos(a) * 60, 0.5, math.sin(a) * 16)
				end
			end
		end
	end
end)
]==]

	for _, n in ipairs({"CrocServer", "CrocClient"}) do local o = L:FindFirstChild(n); if o then o:Destroy() end end
	local s1 = Instance.new("Script"); s1.Name = "CrocServer"; s1.RunContext = Enum.RunContext.Server; s1.Source = SERVER; s1.Parent = L
	local s2 = Instance.new("Script"); s2.Name = "CrocClient"; s2.RunContext = Enum.RunContext.Client; s2.Source = CLIENT; s2.Parent = L

	-- ---------------------------------------------------------------- the slingshot tells us who fired ----
	local hoop = workspace:FindFirstChild("Hoop")
	local sling = hoop and hoop:FindFirstChild("SlingServer")
	if sling then
		local src = sling.Source
		local A1 = "\tlocal nut = makeAcorn(from, dir * (lo + (hi - lo) * power))\n"
		local B1 = A1 .. "\tnut:SetAttribute(\"ShooterId\", player.UserId)                  -- the croc needs to know who bonked him\n"
		local A2 = "\t\t\tif rec.peaked and not rec.missed and (cur.Y < rc.Y - 1.5 or cur.Y < rec.start.Y - 0.5) then\n"
		local B2 = "\t\t\tif rec.peaked and not rec.missed and (cur.Y < rc.Y - 1.5 or cur.Y < rec.start.Y - 0.5)\n"
			.. "\t\t\t\tand ((rec.start - rc) * Vector3.new(1, 0, 1)).Magnitude < (H:GetAttribute(\"MissRange\") or 80) then   -- no crowd \"ohhh\" for shots nowhere near a hoop\n"
		local n = 0
		if not src:find("ShooterId", 1, true) then
			local a, b = src:find(A1, 1, true)
			if a and not src:find(A1, b + 1, true) then src = src:sub(1, a - 1) .. B1 .. src:sub(b + 1); n += 1 end
		end
		if not src:find("MissRange", 1, true) then
			local a, b = src:find(A2, 1, true)
			if a and not src:find(A2, b + 1, true) then src = src:sub(1, a - 1) .. B2 .. src:sub(b + 1); n += 1 end
		end
		sling.Source = src
		note("SlingServer patched: " .. n .. " of 2 (ShooterId " .. tostring(src:find("ShooterId", 1, true) ~= nil) .. ", MissRange " .. tostring(src:find("MissRange", 1, true) ~= nil) .. ")")
	else
		note("no SlingServer found - bonks will guess the shooter")
	end
	return table.concat(report, " | ")
end

-- Trampolines: big red toadstools scattered through the Great Acorn Forest that bounce you sky high - the garden's
-- trampoline toadstool (domaine/build_garden.lua, BUILD[4], the one a seed packet can grow) made large and planted
-- in the wild. Shannon (Sep 25 2026): "can we put a bunch of those trampoline mushrooms scattered throughout the
-- forest too; i think that would be fun" ... "keep the current mushrooms in the forest, just add the trampoline ones
-- too as extras throughout". The forest's own mushrooms are left exactly as they are.
-- The spots are picked here, in edit mode, on open and level forest floor:
--   * clear of everything else (trees, logs, rocks, the forest's own mushrooms, paths, the race gate), with open sky
--     above, so a bounce never throws anyone into the branches;
--   * well inside the boundary walls (they are 60 studs tall and a bounce peaks about 30 up, so nobody is ever
--     carried over one), away from the spawn, the race gate, the bridge gate, every squirrel and every acorn spot;
--   * spread out: never nearer each other than MinGap.
-- Jump on a cap, or into its brim, and it bounces you; the small ones bounce you when you simply run into them. The
-- push is given on each player's own screen, since a character is its player's to move (the garden does the same) -
-- and a player's movement is shared with the whole server, so everyone sees them fly. Shannon: "the bounce should be
-- seen by everyone in the server". The squash of the cap and the spring are passed on too: the bouncer's screen tells
-- the server (TrampolineServer checks they are really standing at that toadstool), and the server tells everyone.
-- Attributes on workspace.Trampolines: Count, Bounce (upward speed), MinGap, Seed; Report (how the spots were
-- chosen). Run in edit mode (re-runnable: it rebuilds the folder and picks the same spots for the same Seed).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("Trampolines")
	local F = Instance.new("Folder"); F.Name = "Trampolines"
	if old then
		-- the vineyard's hop line (domaine/build_hopline.lua) lives in this folder too: carry it over, do not lose it
		for _, m in ipairs(old:GetChildren()) do if m:IsA("Model") and m:GetAttribute("Line") then m.Parent = F end end
		for _, a in ipairs({"VineyardHops", "VineyardReport"}) do F:SetAttribute(a, old:GetAttribute(a)) end
		old:Destroy()
	end
	F:SetAttribute("Count", opts.count or 14); F:SetAttribute("Bounce", opts.bounce or 100)
	F:SetAttribute("MinGap", opts.gap or 34); F:SetAttribute("Seed", opts.seed or 25)
	local rng = Random.new(F:GetAttribute("Seed"))

	-- ---------------------------------------------------------------- where the forest is ----
	-- the river line the boundary walls follow (boundary/build_boundary.lua, riverWestBank)
	local RIVER_X, BRIDGE_Z, K = 156, -120, 2 * math.pi / 260
	local function smooth(t) t = math.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
	local function riverEnv(d) return smooth((math.abs(d) - 50) / 120) end
	local function riverWestBank(z)
		local d = z - BRIDGE_Z
		local centre = 45 * riverEnv(d) * math.cos(K * math.abs(d))
		local half = 9 + 3.5 * riverEnv(d) * math.cos(K * math.abs(d) + 1.7) + 1.5 * riverEnv(d)
		return RIVER_X + centre - half - 5
	end
	local X0, Z0, Z1 = -130, -215, 25                                   -- the forest's west, south and north walls
	local WALL_GAP = opts.wallGap or 30

	-- ---------------------------------------------------------------- what to keep away from ----
	local walls = {}
	local B = workspace:FindFirstChild("Boundary")
	if B and B:FindFirstChild("Walls") then
		for _, w in ipairs(B.Walls:GetChildren()) do if w:IsA("BasePart") then walls[#walls + 1] = w end end
	end
	local function wallDist(x, z)
		local best = math.huge
		for _, w in ipairs(walls) do
			local lp = w.CFrame:PointToObjectSpace(Vector3.new(x, w.Position.Y, z))
			local half = w.Size.X / 2
			local along = math.clamp(lp.X, -half, half)
			local d = math.sqrt((lp.X - along) ^ 2 + lp.Z ^ 2)
			if d < best then best = d end
		end
		return best
	end
	local avoid = {}                                                    -- {flat position, radius}
	local function keepAway(pos, r) avoid[#avoid + 1] = {Vector2.new(pos.X, pos.Z), r} end
	local spawnPad = workspace:FindFirstChild("Spawn_forest", true)
	keepAway(spawnPad and spawnPad.Position or Vector3.new(3, 0, 1), 30)
	local race = workspace:FindFirstChild("ForestRace")
	if race then for _, d in ipairs(race:GetDescendants()) do if d:IsA("BasePart") then keepAway(d.Position, 16) end end end
	if B and B:FindFirstChild("Gates") then for _, d in ipairs(B.Gates:GetDescendants()) do if d:IsA("BasePart") then keepAway(d.Position, 40) end end end
	local squirrels = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		-- a squirrel is a skinned mesh with a Root and a Tail2 bone (tags are only added once the game runs)
		if d:IsA("MeshPart") and d:FindFirstChild("Root", true) and d:FindFirstChild("Tail2", true) then keepAway(d.Position, 14); squirrels += 1 end
	end
	local acornSpots = 0
	local spots = workspace:FindFirstChild("AcornSpots")
	if spots then for _, a in ipairs(spots:GetDescendants()) do if a:IsA("Attachment") then keepAway(a.WorldPosition, 9); acornSpots += 1 end end end
	local function nearAvoided(x, z)
		local p = Vector2.new(x, z)
		for _, a in ipairs(avoid) do if (p - a[1]).Magnitude < a[2] then return true end end
		return false
	end

	-- ---------------------------------------------------------------- is a spot clear? ----
	local exclude = {F}
	for _, n in ipairs({"Baseplate", "Terrain"}) do local o = workspace:FindFirstChild(n); if o then exclude[#exclude + 1] = o end end
	local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = exclude
	local rpG = RaycastParams.new(); rpG.FilterType = Enum.RaycastFilterType.Exclude; rpG.FilterDescendantsInstances = {F}
	local function groundAt(x, z)
		local hit = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -120, 0), rpG)
		if not hit then return nil end
		if hit.Instance ~= workspace.Terrain and hit.Instance.Name ~= "Baseplate" then return nil end   -- bare forest floor only
		return hit.Position.Y
	end
	local function blocked(cf, size)
		for _, p in ipairs(workspace:GetPartBoundsInBox(cf, size, op)) do
			local huge = p.Size.X > 150 or p.Size.Y > 150 or p.Size.Z > 150
			local ghost = p.Transparency >= 0.95 and not p.CanCollide              -- an invisible trigger is no obstacle
			if not huge and not ghost then return true end
		end
		return false
	end
	local function spotOk(x, z, s)
		local g = groundAt(x, z)
		if not g then return nil, "ground" end
		local brim = 2.8 * s
		for k = 0, 5 do
			local a = k * math.pi / 3
			local gk = groundAt(x + math.cos(a) * brim, z + math.sin(a) * brim)
			if not gk or math.abs(gk - g) > 0.6 then return nil, "ground" end
		end
		local H = 5.2 * s                                                        -- ground to the top of the cap
		local reach = 2 * (brim + 2.5)                                           -- the brim and room to walk round it
		if blocked(CFrame.new(x, g + 0.05 + (H + 2) / 2, z), Vector3.new(reach, H + 2, reach)) then return nil, "busy" end
		if blocked(CFrame.new(x, g + H + 2 + 20, z), Vector3.new(2 * brim + 6, 40, 2 * brim + 6)) then return nil, "sky" end
		return g
	end

	-- ---------------------------------------------------------------- choose the spots ----
	local cands = {}
	for x = X0 + WALL_GAP, 150, 3 do
		for z = Z0 + WALL_GAP, Z1 - WALL_GAP, 3 do
			if x < riverWestBank(z) - WALL_GAP then cands[#cands + 1] = Vector2.new(x + rng:NextNumber(-1, 1), z + rng:NextNumber(-1, 1)) end
		end
	end
	for i = #cands, 2, -1 do local j = rng:NextInteger(1, i); cands[i], cands[j] = cands[j], cands[i] end
	local want, gap = F:GetAttribute("Count"), F:GetAttribute("MinGap")
	local chosen, tried = {}, 0
	local why = {wall = 0, avoid = 0, gap = 0, ground = 0, busy = 0, sky = 0}
	for _, c in ipairs(cands) do
		if #chosen >= want then break end
		tried += 1
		local x, z = c.X, c.Y
		local near = false
		for _, o in ipairs(chosen) do if (Vector2.new(o.x, o.z) - c).Magnitude < gap then near = true break end end
		if near then why.gap += 1
		elseif wallDist(x, z) < WALL_GAP then why.wall += 1
		elseif nearAvoided(x, z) then why.avoid += 1
		else
			local s = rng:NextNumber(opts.minScale or 1.3, opts.maxScale or 2.0)
			local g, reason = spotOk(x, z, s)
			if g then chosen[#chosen + 1] = {x = x, z = z, g = g, s = s} else why[reason] += 1 end
		end
	end

	-- ---------------------------------------------------------------- the toadstools ----
	local CYL = Enum.PartType.Cylinder
	local UPR = CFrame.Angles(0, 0, math.rad(90))                      -- a cylinder's axis is x; this stands it up
	local RED, STALK, SPOT = C(214, 50, 46), C(246, 236, 210), C(250, 246, 236)
	local function piece(m, name, size, cf, colour, shape)
		local p = Instance.new("Part"); p.Name = name; p.Shape = shape or CYL; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true; p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local TIERS = {{5.6, 0.5}, {5.1, 0.5}, {4.3, 0.5}, {3.2, 0.45}, {1.8, 0.4}}   -- the garden's stepped dome: diameter, thickness
	for i, spot in ipairs(chosen) do
		local s = spot.s
		local m = Instance.new("Model"); m.Name = "Toadstool" .. i
		pcall(function() m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)   -- streams in whole, brim and all
		local base = CFrame.new(spot.x, spot.g, spot.z) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0)
		local stalk = piece(m, "Stalk", Vector3.new(2.8 * s, 1.8 * s, 1.8 * s), base * CFrame.new(0, 1.4 * s, 0) * UPR, STALK)
		for k, d in ipairs(TIERS) do
			local y = (3.05 + (k - 1) * 0.47) * s
			local cap = piece(m, "Cap", Vector3.new(d[2] * s, d[1] * s, d[1] * s), base * CFrame.new(0, y, 0) * UPR, RED)
			cap.CanTouch = true                                                 -- the bouncy part
			cap:SetAttribute("Size0", cap.Size)
		end
		-- white spots: little bumps on the edge of each step of the dome
		for k = 1, 4 do
			local r = TIERS[k][1] / 2 - 0.15
			local top = 3.05 + (k - 1) * 0.47 + TIERS[k][2] / 2
			local n = (k <= 2) and 3 or 2
			local turn = rng:NextNumber(0, 2 * math.pi)
			for j = 1, n do
				local a = turn + j * 2 * math.pi / n
				local b = piece(m, "Spot", Vector3.new(0.55 * s, 0.55 * s, 0.55 * s), base * CFrame.new(math.cos(a) * r * s, (top - 0.05) * s, math.sin(a) * r * s), SPOT, Enum.PartType.Ball)
				b.CanCollide = false; b.CanQuery = false
			end
		end
		m.PrimaryPart = stalk
		m:SetAttribute("RimY", spot.g + 3.05 * s); m:SetAttribute("Scale", math.floor(s * 100 + 0.5) / 100)
		m.Parent = F
	end
	F:SetAttribute("Report", string.format("tried %d of %d; skipped wall %d, near things %d, too close %d, ground %d, busy %d, branches %d (kept away from %d squirrels, %d acorn spots)",
		tried, #cands, why.wall, why.avoid, why.gap, why.ground, why.busy, why.sky, squirrels, acornSpots))

	-- ---------------------------------------------------------------- the bounce (each player's own screen) ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local F = script.Parent
local bounced = F:WaitForChild("Bounced")
local last = 0
local hooked = setmetatable({}, {__mode = "k"})

local function spring(cap)
	local s = Instance.new("Sound"); s.SoundId = "rbxasset://sounds/Short spring sound.wav"; s.Volume = 0.8
	s.RollOffMinDistance = 10; s.RollOffMaxDistance = 90; s.Parent = cap; s:Play()
	Debris:AddItem(s, 3)
end

-- the cap squashes flat and spreads for a moment, then springs back
local function squash(model)
	for _, c in ipairs(model:GetChildren()) do
		if c.Name == "Cap" and c:IsA("BasePart") then
			local s0 = c:GetAttribute("Size0") or c.Size
			c.Size = s0
			TweenService:Create(c, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = Vector3.new(s0.X * 0.6, s0.Y * 1.08, s0.Z * 1.08)}):Play()
		end
	end
end

local function bounce(cap, hit)
	local char = player.Character
	if not (char and hit:IsDescendantOf(char)) then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 or hum.SeatPart then return end
	local model = cap.Parent
	local rim = model and model:GetAttribute("RimY")
	if rim and hrp.Position.Y < rim - 1.6 then return end                  -- bumping the underside of the brim is not a bounce
	if os.clock() - last < 0.6 then return end
	last = os.clock()
	hum:ChangeState(Enum.HumanoidStateType.Jumping)                       -- off the ground first, or the humanoid eats the push
	local up = F:GetAttribute("Bounce") or 100
	task.defer(function()
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X * 0.3, up, v.Z * 0.3)
	end)
	spring(cap)
	if model then squash(model); bounced:FireServer(model) end               -- and everyone else sees the cap give
end

-- someone else bounced: their flight is already on this screen; add the squash and the spring
bounced.OnClientEvent:Connect(function(model, who)
	if who == player or typeof(model) ~= "Instance" or not model.Parent then return end   -- not streamed in here: nothing to show
	local cap = model:FindFirstChild("Cap")
	if cap then spring(cap); squash(model) end
end)

-- caps stream in and out with distance: hook each one as it arrives
local function hook(d)
	if d:IsA("BasePart") and d.Name == "Cap" and not hooked[d] then
		hooked[d] = true
		d.Touched:Connect(function(hit) bounce(d, hit) end)
	end
end
for _, d in ipairs(F:GetDescendants()) do hook(d) end
F.DescendantAdded:Connect(hook)
]==]
	-- the server passes a bounce on to everyone, once it is sure the bouncer is really at that toadstool
	local SERVER = [==[
local Players = game:GetService("Players")
local F = script.Parent
local bounced = F:WaitForChild("Bounced")
local lastBy = {}
bounced.OnServerEvent:Connect(function(player, model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or model.Parent ~= F then return end
	local t = os.clock()
	if lastBy[player] and t - lastBy[player] < 0.4 then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local at = model:GetPivot().Position
	local reach = 2.8 * (model:GetAttribute("Scale") or 2) + 10
	if (Vector3.new(hrp.Position.X - at.X, 0, hrp.Position.Z - at.Z)).Magnitude > reach then return end
	lastBy[player] = t
	bounced:FireAllClients(model, player)
end)
Players.PlayerRemoving:Connect(function(p) lastBy[p] = nil end)
]==]
	local ev = Instance.new("RemoteEvent"); ev.Name = "Bounced"; ev.Parent = F
	local srv = Instance.new("Script"); srv.Name = "TrampolineServer"; srv.RunContext = Enum.RunContext.Server; srv.Source = SERVER; srv.Parent = F
	local c = Instance.new("Script"); c.Name = "TrampolineClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print(string.format("Trampolines: %d toadstools in the forest - %s", #chosen, F:GetAttribute("Report")))
	return F
end

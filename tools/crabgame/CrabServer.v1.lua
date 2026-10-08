-- CrabServer (workspace.CrabGame): the crab game at Porto Nocciola (Oct 4 2026, Shannon: "buy a crab trap from the acorn
-- store, cast the net into the ocean, wait a short time, pull it in and take it to the fish seller to exchange for acorns").
-- Everything that matters is decided HERE: where the trap lands, when it is ready, what is in it, what Beppe pays.
-- Saved through the same ledger as everything else (AwardItems / AwardAcorns): Item_crabtrap (owned, bought in the Acorn
-- Store), Item_crabs and Item_goldcrabs (the bucket - kept between visits). This script never touches a DataStore.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local G = script.Parent
local kit = RS:WaitForChild("CrabGame")
local ev = kit:WaitForChild("CrabEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")

local function num(name, default) local v = G:GetAttribute(name) return type(v) == "number" and v or default end
-- the Crab Catching Area: the tide-pool shelf and the little sandy cove beside it (ZoneMin/ZoneMax attributes)
local function inZone(pos)
	local a, b = G:GetAttribute("ZoneMin"), G:GetAttribute("ZoneMax")
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return false end
	return pos.X >= a.X and pos.X <= b.X and pos.Y >= a.Y and pos.Y <= b.Y and pos.Z >= a.Z and pos.Z <= b.Z
end
local function bucket(p) return (p:GetAttribute("Item_crabs") or 0) + (p:GetAttribute("Item_goldcrabs") or 0) end

local casts = {}            -- [player] = {trap, buoy, beam, a0, readyAt, target}
local busy = {}

local function hand(char)
	local h = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("HumanoidRootPart")
	local a = h and h:FindFirstChild("CrabLine")
	if h and not a then a = Instance.new("Attachment") a.Name = "CrabLine" a.Position = Vector3.new(0, -0.25, 0) a.Parent = h end
	return a
end

-- open sea in front of the player: walk out along the way they face, then try a little to either side
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
local function findWater(root)
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.1 then return nil end
	look = look.Unit
	local ex = {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ex, p.Character) end end
	for _, v in ipairs(G:GetDescendants()) do if v:IsA("BasePart") then table.insert(ex, v) end end
	rp.FilterDescendantsInstances = ex
	local sea = num("SeaY", -52.9)
	for _, turn in ipairs({0, 20, -20, 40, -40, 60, -60}) do
		local dir = CFrame.Angles(0, math.rad(turn), 0):VectorToWorldSpace(look)
		for d = 9, 17, 2 do
			local p = root.Position + dir * d
			local q = workspace:Raycast(Vector3.new(p.X, sea + 12, p.Z), Vector3.new(0, -16, 0), rp)
			if q and q.Instance == workspace.Terrain and q.Material == Enum.Material.Water and math.abs(q.Position.Y - sea) < 0.6 then
				-- and nothing solid just under the surface (the shelf's foot)
				local under = workspace:Raycast(Vector3.new(p.X, sea - 0.2, p.Z), Vector3.new(0, -1.5, 0), rp)
				if not under or under.Material == Enum.Material.Water then
					return Vector3.new(p.X, sea, p.Z), dir
				end
			end
		end
	end
	return nil
end

local function splash(pos)
	local a = Instance.new("Part") a.Name = "Splash" a.Anchored = true a.CanCollide = false a.CanQuery = false a.CanTouch = false
	a.Transparency = 1 a.Size = Vector3.new(0.2, 0.2, 0.2) a.Position = pos a.Parent = G
	local pe = Instance.new("ParticleEmitter") pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(235, 250, 255)) pe.Size = NumberSequence.new(0.35, 0)
	pe.Speed = NumberRange.new(6, 10) pe.SpreadAngle = Vector2.new(35, 35) pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Acceleration = Vector3.new(0, -30, 0) pe.EmissionDirection = Enum.NormalId.Top pe.Rate = 0 pe.Parent = a
	pe:Emit(26)
	local s = Instance.new("Sound") s.SoundId = "rbxasset://sounds/impact_water.mp3" s.Volume = 0.8
	s.RollOffMinDistance = 8 s.RollOffMaxDistance = 70 s.Parent = a s:Play()
	Debris:AddItem(a, 3)
end

-- fly a model along an arc (server steps it; everyone sees it)
local function arc(model, from, to, secs, height)
	local rot = model:GetPivot().Rotation
	local n = math.max(8, math.floor(secs * 30))
	for i = 1, n do
		local t = i / n
		local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * height, 0)
		model:PivotTo(CFrame.new(p) * rot)
		task.wait(secs / n)
		if not model.Parent then return end
	end
end

local function clear(p, keepTrap)
	local c = casts[p]
	casts[p] = nil
	if not c then return end
	if c.beam then c.beam:Destroy() end
	if c.buoy then c.buoy:Destroy() end
	if c.trap and not keepTrap then c.trap:Destroy() end
	p:SetAttribute("CrabCast", nil)
end

local function cast(p)
	if casts[p] or busy[p] then return end
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end
	if (p:GetAttribute("Item_crabtrap") or 0) < 1 then ev:FireClient(p, "say", "You need a crab trap - they're in the Acorn Store.") return end
	if not inZone(root.Position) then ev:FireClient(p, "say", "Crabs live by the tide pools - cast from the Crab Catching Area.") return end
	if bucket(p) >= num("Bucket", 6) then ev:FireClient(p, "say", "Your bucket is full! Sell your crabs to Beppe at the fish stall.") return end
	local target, dir = findWater(root)
	if not target then ev:FireClient(p, "say", "Face the open sea to cast your trap.") return end
	busy[p] = true
	local trap = kit.Trap:Clone()
	trap.Name = "Trap_" .. p.UserId
	for _, v in ipairs(trap:GetDescendants()) do if v:IsA("BasePart") then v.Anchored = true v.CanCollide = false v.CanQuery = false v.CanTouch = false end end
	local start = root.Position + dir * 1.5 + Vector3.new(0, 1.2, 0)
	trap:PivotTo(CFrame.lookAt(start, start + dir))
	trap.Parent = G
	local buoy = kit.Buoy:Clone() buoy.Name = "Buoy_" .. p.UserId
	buoy:PivotTo(CFrame.new(start)) buoy.Parent = G
	local a1 = buoy.PrimaryPart:FindFirstChild("LineEnd")
	local beam = kit.Line:Clone() beam.Attachment0 = hand(char) beam.Attachment1 = a1 beam.Parent = buoy.PrimaryPart
	local wait = math.random() * (num("WaitMax", 15) - num("WaitMin", 10)) + num("WaitMin", 10)
	casts[p] = {trap = trap, buoy = buoy, beam = beam, target = target}
	p:SetAttribute("CrabCast", "flying")
	task.spawn(function() arc(buoy, start, target + Vector3.new(0, 0.15, 0), 0.75, 4) end)
	arc(trap, start, target, 0.75, 4)
	if casts[p] == nil or casts[p].trap ~= trap then busy[p] = nil return end
	splash(target)
	-- the trap sinks out of sight; only the float stays, bobbing
	trap:PivotTo(trap:GetPivot() + Vector3.new(0, -2.4, 0))
	local bob = TweenService:Create(buoy.PrimaryPart, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{CFrame = buoy.PrimaryPart.CFrame + Vector3.new(0, 0.18, 0)})
	bob:Play()
	casts[p].readyAt = workspace:GetServerTimeNow() + wait
	p:SetAttribute("CrabCast", casts[p].readyAt)
	busy[p] = nil
	ev:FireClient(p, "cast", casts[p].readyAt)
end

local function rollCatch()
	local r = math.random()
	local n = r < 0.15 and 0 or r < 0.55 and 1 or r < 0.85 and 2 or 3
	local gold = math.random() < num("GoldChance", 0.05)
	if gold then n = math.max(n, 1) end
	return n, gold and 1 or 0
end

local function pull(p)
	local c = casts[p]
	if not c or busy[p] or not c.readyAt then return end
	busy[p] = true
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local early = workspace:GetServerTimeNow() < c.readyAt
	local n, gold = 0, 0
	if not early then n, gold = rollCatch() end
	-- room in the bucket? the golden one goes in first; whatever doesn't fit is let go
	local room = math.max(0, num("Bucket", 6) - bucket(p))
	local g = math.min(gold, room) room -= g
	local plain = math.min(n - gold, room)
	local let = (gold - g) + (n - gold - plain)
	gold = g
	-- crabs ride up inside the trap
	local trap = c.trap
	trap:PivotTo(CFrame.new(c.target) * trap:GetPivot().Rotation)
	local shown = {}
	for i = 1, plain + gold do
		local crab = kit.Crab:Clone()
		for _, v in ipairs(crab:GetDescendants()) do if v:IsA("BasePart") then v.Anchored = true v.CanCollide = false v.CanQuery = false v.CanTouch = false end end
		if i <= gold then
			for _, v in ipairs(crab:GetDescendants()) do if v:IsA("MeshPart") then v.TextureID = "" v.Color = Color3.fromRGB(255, 196, 46) v.Material = Enum.Material.Foil end end
		end
		crab.Parent = trap
		table.insert(shown, {crab, Vector3.new((i - (plain + gold + 1) / 2) * 0.45, -0.5, (i % 2) * 0.25 - 0.1)})
	end
	local function place()
		for _, s in ipairs(shown) do s[1]:PivotTo(trap:GetPivot() * CFrame.new(s[2])) end
	end
	place()
	splash(c.target)
	if c.beam then c.beam:Destroy() c.beam = nil end
	if c.buoy then c.buoy:Destroy() c.buoy = nil end
	local to = root and (root.Position + root.CFrame.LookVector * 1.6 + Vector3.new(0, 0.6, 0)) or c.target + Vector3.new(0, 3, 0)
	local n2 = 20
	local from = c.target
	for i = 1, n2 do
		local t = i / n2
		trap:PivotTo(CFrame.new(from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 3, 0)) * trap:GetPivot().Rotation)
		place()
		task.wait(0.6 / n2)
	end
	if plain > 0 then awardItems:Fire(p, "crabs", plain) end
	if gold > 0 then awardItems:Fire(p, "goldcrabs", gold) end
	ev:FireClient(p, "caught", plain, gold, let, early)
	clear(p, true)
	Debris:AddItem(trap, 1.6)
	busy[p] = nil
end

ev.OnServerEvent:Connect(function(p, what)
	if what == "cast" then cast(p)
	elseif what == "pull" then pull(p) end
end)

-- leaving the area (or the game) brings the trap home empty
task.spawn(function()
	while true do
		task.wait(0.5)
		for p, c in pairs(casts) do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not p.Parent or not root or (not busy[p] and not inZone(root.Position)) then
				clear(p) if p.Parent then ev:FireClient(p, "lost") end
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) clear(p) busy[p] = nil end)

-- BEPPE BUYS THE CATCH: a prompt at his crate (each client shows it only while it has crabs)
local sellPrompt = G:FindFirstChild("SellPrompt", true)
if sellPrompt then
	sellPrompt.Triggered:Connect(function(p)
		if busy[p] then return end
		local plain, gold = p:GetAttribute("Item_crabs") or 0, p:GetAttribute("Item_goldcrabs") or 0
		if plain + gold <= 0 then ev:FireClient(p, "sold", 0, 0, 0) return end
		busy[p] = true
		local pay = plain * num("CrabPay", 3) + gold * num("GoldPay", 100)
		if plain > 0 then awardItems:Fire(p, "crabs", -plain) end
		if gold > 0 then awardItems:Fire(p, "goldcrabs", -gold) end
		awardAcorns:Fire(p, pay)                                   -- same ledger the shop spends from
		p:SetAttribute("Acorns", (p:GetAttribute("Acorns") or 0) + pay)
		busy[p] = nil
		ev:FireClient(p, "sold", plain, gold, pay)
	end)
else
	warn("CrabServer: no SellPrompt - Beppe cannot buy crabs")
end
print("CrabServer: ready")

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local join = F:WaitForChild("ChaseJoin")
local ev = F:WaitForChild("ChaseEvent")
local stand = F:WaitForChild("Stand")
local prize = stand:WaitForChild("ChaseBaguette")
local award = RS:WaitForChild("AwardAcorns", 30)
local C = Color3.fromRGB
local UP = CFrame.Angles(0, 0, math.rad(90))
local LAND = {}
for entry in string.gmatch(F:GetAttribute("Landmarks") or "", "[^;]+") do
	local name, x, z = entry:match("^(.-)|(%-?%d+)|(%-?%d+)$")
	if name then table.insert(LAND, {name, tonumber(x), tonumber(z)}) end
end
local function A(k) return F:GetAttribute(k) end

local joined = {}                                       -- player -> true
local holder, immuneUntil, heldSince, earnedThisHold = nil, 0, 0, 0
local noTakeBack = {}                                   -- player -> clock until which they can't take it back
local grabs = {}                                        -- UserId -> {count, since}

local function parts(p)
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid"), c
end
local function count() local n = 0; for p in pairs(joined) do if p.Parent then n += 1 end end; return n end
local function give(p, n)
	if n <= 0 then return end
	if award then award:Fire(p, n) end
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + n)
end

-- the baguette on the holder's back, crumbs falling behind
local function removeHeld(p)
	local _, _, c = parts(p)
	local m = c and c:FindFirstChild("ChaseBaguette")
	if m then m:Destroy() end
end
local function attach(p)
	local hrp, _, c = parts(p)
	local torso = c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
	if not (hrp and torso) then return end
	removeHeld(p)
	local m = Instance.new("Model"); m.Name = "ChaseBaguette"
	local function piece(name, size, colour, shape, offset)
		local q = Instance.new("Part"); q.Name = name; q.Size = size; q.Color = colour; q.Material = Enum.Material.SmoothPlastic
		if shape then q.Shape = shape end
		q.CanCollide = false; q.CanQuery = false; q.CanTouch = false; q.Massless = true
		local cf = CFrame.new(0, 0.2, 0.62) * CFrame.Angles(0, 0, math.rad(55)) * offset     -- slung across the back
		q.CFrame = torso.CFrame * cf
		local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = q; w.C0 = cf; w.Parent = q
		q.Parent = m
		return q
	end
	local loaf = piece("Loaf", Vector3.new(3.1, 0.44, 0.44), C(226, 172, 96), Enum.PartType.Cylinder, CFrame.new())
	for i = -1, 1 do
		piece("Slash", Vector3.new(0.4, 0.06, 0.3), C(240, 206, 150), nil, CFrame.new(i * 0.8, 0, -0.19) * CFrame.Angles(0, math.rad(35), 0))
	end
	piece("Ribbon", Vector3.new(0.3, 0.48, 0.48), C(200, 60, 70), Enum.PartType.Cylinder, CFrame.new(0, 0, 0))
	local a = Instance.new("Attachment"); a.Parent = loaf
	local crumbs = Instance.new("ParticleEmitter"); crumbs.Name = "Crumbs"; crumbs.Color = ColorSequence.new(C(214, 164, 100))
	crumbs.Size = NumberSequence.new(0.14); crumbs.Rate = 7; crumbs.Lifetime = NumberRange.new(1.2, 1.8); crumbs.Speed = NumberRange.new(0.5, 1.5)
	crumbs.Acceleration = Vector3.new(0, -18, 0); crumbs.SpreadAngle = Vector2.new(60, 60); crumbs.Parent = a
	m.Parent = c
end

local function where(p)
	local hrp = parts(p)
	if not hrp or #LAND == 0 then return "" end
	local best, bd = LAND[1][1], math.huge
	for _, l in ipairs(LAND) do
		local d = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(l[2], l[3])).Magnitude
		if d < bd then best, bd = l[1], d end
	end
	return best
end

local function showAtBakery(on)
	F:SetAttribute("AtBakery", on)
	prize.Transparency = on and 0 or 1
	prize.ShineAt.Shine.Enabled = on
end
local function recordHold(ongoing)
 if holder and holder.Parent then
  local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(holder,"baguette",{seconds=math.max(0,os.clock()-heldSince),prize=earnedThisHold,ongoing=ongoing}) end
 end
end
local function setHolder(p, reason, from)
 recordHold(false)
	if holder then removeHeld(holder) end
	holder = p
	if p then

			attach(p)
		F:SetAttribute("Holder", p.UserId); F:SetAttribute("HolderName", p.DisplayName); F:SetAttribute("HolderWhere", where(p))
		immuneUntil = os.clock() + (A("Immune") or 5); heldSince = os.clock(); earnedThisHold = 0
		recordHold(true)
		showAtBakery(false)
	else
		F:SetAttribute("Holder", 0); F:SetAttribute("HolderName", ""); F:SetAttribute("HolderWhere", "")
	end
	for q in pairs(joined) do
		if q.Parent then ev:FireClient(q, "holder", p and p.DisplayName or "", from and from.DisplayName or "", reason or "", p and p.UserId or 0, from and from.UserId or 0) end
	end
end
local function grabPrize(p)
	local now = os.clock()
	local g = grabs[p.UserId]
	if not g or now - g.since > 3600 then g = {count = 0, since = now}; grabs[p.UserId] = g end
	g.count += 1
	if g.count <= (A("GrabCap") or 12) then give(p, A("GrabPrize") or 10) return true end
	return false
end

local function setJoined(p, on)
	if on then joined[p] = true; p:SetAttribute("InChase", true)
	else
		joined[p] = nil; p:SetAttribute("InChase", nil)
		if holder == p then setHolder(nil, "left") end
	end
	F:SetAttribute("Playing", count())
end
join.OnServerEvent:Connect(function(p, on) setJoined(p, on == true) end)
PPS.PromptTriggered:Connect(function(prompt, p)
	if prompt.Name == "ChasePrompt" and prompt:IsDescendantOf(F) then setJoined(p, true); ev:FireClient(p, "joined") end
end)
Players.PlayerRemoving:Connect(function(p) setJoined(p, false); noTakeBack[p] = nil end)
local function watch(p) p.CharacterAdded:Connect(function() task.wait(0.5); if holder == p then attach(p) end end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- the holder's whereabouts for the hints, and the slow reward for keeping it
task.spawn(function()
	local lastPay = os.clock()
 local lastMemory=0
	while true do
		task.wait(1)
		if holder then F:SetAttribute("HolderWhere", where(holder)) end
  if holder and os.clock()-lastMemory>=5 then lastMemory=os.clock();recordHold(true) end
		if holder and os.clock() - lastPay >= (A("HoldEvery") or 10) then
			lastPay = os.clock()
			local cap = A("HoldCap") or 30
			if count() >= (A("MinPlayers") or 2) and earnedThisHold < cap then
				local n = math.min(A("HoldPrize") or 1, cap - earnedThisHold)
				earnedThisHold += n
				give(holder, n)
			end
		end
	end
end)

-- the chase itself
while true do
	task.wait(0.1)
	local n = count()
	if n < (A("MinPlayers") or 2) then
		if holder then setHolder(nil, "waiting") end
		if F:GetAttribute("AtBakery") then showAtBakery(false) end
	elseif not holder then
		if not F:GetAttribute("AtBakery") then
			showAtBakery(true)
			for q in pairs(joined) do if q.Parent then ev:FireClient(q, "bakery") end end
		end
		for q in pairs(joined) do                       -- first to the basket takes it
			local r, h = parts(q)
			if r and h and h.Health > 0 and (r.Position - prize.Position).Magnitude < 6 then
				setHolder(q, "bakery")
				local paid = grabPrize(q)
				ev:FireClient(q, "grabbed", paid)
				break
			end
		end
	elseif os.clock() > immuneUntil then
		local hr, hh = parts(holder)
		if hr and hh and hh.Health > 0 then
			for q in pairs(joined) do
				if q ~= holder and q.Parent and os.clock() > (noTakeBack[q] or 0) then
					local r, h = parts(q)
					if r and h and h.Health > 0 and (r.Position - hr.Position).Magnitude < (A("Range") or 4) then
						local lost = holder
						noTakeBack[lost] = os.clock() + (A("NoTakeBack") or 30)
						setHolder(q, "stolen", lost)
						local paid = grabPrize(q)
						ev:FireClient(q, "grabbed", paid)
						break
					end
				end
			end
		end
	end
end

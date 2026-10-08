-- Speed: the one place that decides how fast a player runs, and the two ways to run faster.
--   COFFEE (free): sit at one of the cafe tables on the Rue de Noisette and "Drink a coffee". The cup comes up for two
--   sips and you run faster for five minutes (CoffeeBoost, CoffeeSeconds; Shannon: "the coffee zoomies should last
--   for 5 minutes"). It counts in the Forest Race - anyone can have one, so it is fair.
--   ZOOMIES (acorns, in the Acorn Store): ZoomiesMinutes of running faster everywhere; buying again adds more. Never
--   for good (Shannon: "I do not want to sell permanent zoomies"). The store's ShopServer sells it and keeps its clock
--   as the item "zoomiesuntil" (the moment it runs out, server time), so it keeps running while you are away. It does
--   not count while you are on the Forest Race clock, so the leaderboard stays fair (PaidInRace = true lets it in).
-- The server sets Humanoid.WalkSpeed every quarter second as BaseSpeed x coffee x zoomies. Player attributes it reads:
-- CoffeeUntil (server time), Item_zoomiesuntil (server time), Racing.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("Speed")
	if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "Speed"
	F:SetAttribute("BaseSpeed", opts.base or 16)
	F:SetAttribute("CoffeeBoost", opts.coffeeBoost or 1.35); F:SetAttribute("CoffeeSeconds", opts.coffeeSeconds or 300)
	F:SetAttribute("ZoomiesBoost", opts.zoomiesBoost or 1.3); F:SetAttribute("ZoomiesMinutes", opts.zoomiesMinutes or 10)
	F:SetAttribute("PaidInRace", opts.paidInRace == true)
	local ev = RS:FindFirstChild("SpeedEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "SpeedEvent"; ev.Parent = RS end

	-- ---------------------------------------------------------------- a cup of coffee on every cafe table ----
	local cups = Instance.new("Folder"); cups.Name = "Coffee"; cups.Parent = F
	local props = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Props")
	local made = 0
	local function part(name, size, cf, colour, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = false; p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	local UP = CFrame.Angles(0, 0, math.rad(90))            -- a cylinder's axis is x; this stands it up
	if props then
		for _, tbl in ipairs(props:GetChildren()) do
			if tbl:IsA("Model") and tbl.Name == "cafe_table" then
				local cf = tbl:GetBoundingBox()
				local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {tbl}
				local hit = workspace:Raycast(cf.Position + Vector3.new(0, 8, 0), Vector3.new(0, -16, 0), rp)
				if hit then
					made += 1
					local top = hit.Position
					local m = Instance.new("Model"); m.Name = "CoffeeCup"; m.Parent = cups
					local link = Instance.new("ObjectValue"); link.Name = "Table"; link.Value = tbl; link.Parent = m
					local WHITE = C(250, 247, 240)
					part("Saucer", Vector3.new(0.08, 1.0, 1.0), CFrame.new(top + Vector3.new(0, 0.04, 0)) * UP, WHITE, m, Enum.PartType.Cylinder)
					local cup = part("Cup", Vector3.new(0.55, 0.6, 0.6), CFrame.new(top + Vector3.new(0, 0.355, 0)) * UP, WHITE, m, Enum.PartType.Cylinder)
					local brew = part("Brew", Vector3.new(0.04, 0.5, 0.5), CFrame.new(top + Vector3.new(0, 0.6, 0)) * UP, C(96, 58, 32), m, Enum.PartType.Cylinder)
					part("Handle", Vector3.new(0.12, 0.3, 0.1), CFrame.new(top + Vector3.new(0.36, 0.36, 0)), WHITE, m)
					local at = Instance.new("Attachment"); at.Position = Vector3.new(0, 0, 0); at.Parent = brew
					local steam = Instance.new("ParticleEmitter"); steam.Name = "Steam"; steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
					steam.Color = ColorSequence.new(C(255, 255, 255)); steam.LightInfluence = 0; steam.Rate = 2; steam.Speed = NumberRange.new(0.4, 0.8)
					steam.Lifetime = NumberRange.new(1.2, 1.8); steam.SpreadAngle = Vector2.new(8, 8); steam.EmissionDirection = Enum.NormalId.Top
					steam.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.55)})
					steam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(1, 1)}); steam.Parent = at
					local pr = Instance.new("ProximityPrompt"); pr.Name = "CoffeePrompt"; pr.ActionText = "Drink a coffee"; pr.ObjectText = "Caf" .. utf8.char(233)
					pr.KeyboardKeyCode = Enum.KeyCode.E; pr.HoldDuration = 0.4; pr.MaxActivationDistance = 7; pr.RequiresLineOfSight = false
					-- on at the server; each player's screen hides it unless they are sitting at this very table
					pr.Parent = cup
				end
			end
		end
	end

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("SpeedEvent")
local function now() return workspace:GetServerTimeNow() end

-- coffee: only for someone sitting at that very table
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "CoffeePrompt" or not prompt:IsDescendantOf(F) then return end
	local cup = prompt:FindFirstAncestorOfClass("Model")
	local link = cup and cup:FindFirstChild("Table")
	local tbl = link and link.Value
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (tbl and hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(tbl)) then return end
	local secs = F:GetAttribute("CoffeeSeconds") or 300
	local untilT = tonumber(player:GetAttribute("CoffeeUntil")) or 0
	if untilT - now() > secs - 4 then return end                  -- the last cup is still going down
	player:SetAttribute("CoffeeUntil", now() + secs)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"coffee",{seconds=secs,boost=math.floor(((F:GetAttribute("CoffeeBoost") or 1.35)-1)*100+0.5)}) end
	ev:FireClient(player, "coffee", secs, cup)
	print(string.format("Speed: %s drank a coffee (%ds)", player.Name, secs))
end)

-- zoomies: bought in the Acorn Store, where the ShopServer moves the clock (Item_zoomiesuntil); this only reads it

-- the speed itself, from everything above
local lastSet = setmetatable({}, {__mode = "k"})
while true do
	local t = now()
	local base = F:GetAttribute("BaseSpeed") or 16
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local m = 1
			if (tonumber(player:GetAttribute("CoffeeUntil")) or 0) > t then m *= F:GetAttribute("CoffeeBoost") or 1.35 end
			local racing = player:GetAttribute("Racing") == true
			if (tonumber(player:GetAttribute("Item_zoomiesuntil")) or 0) > t and (not racing or F:GetAttribute("PaidInRace") == true) then
				m *= F:GetAttribute("ZoomiesBoost") or 1.3
			end
			local want = math.floor(base * m * 10 + 0.5) / 10
			-- only while the speed is ours to set: something else (a ride, say) may have its own idea for a moment
			-- (WalkSpeed is stored at lower precision, so 21.6 reads back as 21.600000381: compare with a tolerance)
			local mine = lastSet[hum]
			if mine == nil or math.abs(hum.WalkSpeed - mine) < 0.05 or math.abs(hum.WalkSpeed - base) < 0.05 then
				if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
				lastSet[hum] = want
			end
			if player:GetAttribute("SpeedMult") ~= m then player:SetAttribute("SpeedMult", m) end
		end
	end
	task.wait(0.25)
end
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local cups = F:WaitForChild("Coffee")
local ev = RS:WaitForChild("SpeedEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220)
local FONT = Enum.Font.FredokaOne

-- the prompt on a table's cup only shows while you are sitting at that table
local function tableOf(cupModel) local link = cupModel:FindFirstChild("Table"); return link and link.Value end
local function refreshPrompts(seat)
	for _, m in ipairs(cups:GetChildren()) do
		local pr = m:FindFirstChild("CoffeePrompt", true)
		local tbl = tableOf(m)
		if pr then pr.Enabled = (seat ~= nil and tbl ~= nil and seat:IsDescendantOf(tbl)) end
	end
end
local function currentSeat()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum.SeatPart
end
local function watchChar(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	refreshPrompts(hum.SeatPart)
	hum:GetPropertyChangedSignal("SeatPart"):Connect(function() refreshPrompts(hum.SeatPart) end)
end
-- cups stream in and out with distance and come back switched on, so check again whenever one arrives
cups.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then refreshPrompts(currentSeat()) end end)
task.spawn(function() while true do task.wait(1); refreshPrompts(currentSeat()) end end)
if player.Character then task.spawn(watchChar, player.Character) end
player.CharacterAdded:Connect(watchChar)

-- the pills that count the boosts down, top right under the golden-squirrel pill: coffee, then store zoomies
local gui = Instance.new("ScreenGui"); gui.Name = "SpeedGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 14; gui.Parent = pg
local function makePill(name, colour)
	local pill = Instance.new("TextLabel"); pill.Name = name; pill.AnchorPoint = Vector2.new(1, 0); pill.Position = UDim2.new(1, -12, 0, 102)
	pill.AutomaticSize = Enum.AutomaticSize.X; pill.Size = UDim2.fromOffset(0, 24); pill.BackgroundColor3 = NAVY; pill.BackgroundTransparency = 0.15
	pill.Font = FONT; pill.TextSize = 13; pill.TextColor3 = colour; pill.Text = ""; pill.Visible = false; pill.Parent = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 12); pc.Parent = pill
	local pp = Instance.new("UIPadding"); pp.PaddingLeft = UDim.new(0, 10); pp.PaddingRight = UDim.new(0, 10); pp.Parent = pill
	local ps = Instance.new("UIStroke"); ps.Color = C(200, 150, 90); ps.Thickness = 1; ps.Transparency = 0.4; ps.Parent = pill
	return pill
end
local coffeePill = makePill("CoffeePill", C(255, 214, 150))
local zoomPill = makePill("ZoomiesPill", C(170, 230, 255))
local function mmss(secs) secs = math.max(0, secs) return string.format("%d:%02d", math.floor(secs / 60), math.floor(secs % 60)) end
task.spawn(function()
	while true do
		local now = workspace:GetServerTimeNow()
		local y = 102
		local cLeft = (tonumber(player:GetAttribute("CoffeeUntil")) or 0) - now
		coffeePill.Visible = cLeft > 0
		if cLeft > 0 then coffeePill.Text = "Coffee zoomies  " .. mmss(cLeft); coffeePill.Position = UDim2.new(1, -12, 0, y); y += 28 end
		local zLeft = (tonumber(player:GetAttribute("Item_zoomiesuntil")) or 0) - now
		zoomPill.Visible = zLeft > 0
		if zLeft > 0 then
			local held = player:GetAttribute("Racing") == true and F:GetAttribute("PaidInRace") ~= true
			zoomPill.Text = (held and "Zoomies (not in races)  " or "Zoomies  ") .. mmss(zLeft); zoomPill.Position = UDim2.new(1, -12, 0, y)
		end
		task.wait(0.25)
	end
end)

-- a word at the bottom of the screen
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -110); note.Size = UDim2.fromOffset(420, 40)
note.BackgroundColor3 = NAVY; note.BackgroundTransparency = 1; note.BorderSizePixel = 0; note.Font = FONT; note.TextSize = 18; note.TextColor3 = CREAM
note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local noteAt = 0
local function say(text)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); noteAt = mine
	task.delay(3.2, function() if noteAt ~= mine then return end; TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
end

-- two sips, by hand. The right hand reaches for the cup, lifts it to the mouth, tips it for a sip, dips it and sips
-- again, then sets it back on its saucer and comes to rest. Shannon: "the cup comes up but not by player's hand, it just
-- floats up ... that looks weird". The arm is posed on the drinker's own screen by writing the shoulder's and elbow's
-- Transform just before each physics step (after the sitting animation has written its own, so the turn goes on top of
-- it). Turning the joint's attachment instead, the way the zipline does on the server, does nothing on the client to
-- this game's avatars (AnimationConstraint joints): measured, the hand moved 0.00 studs that way and 2 studs this way.
-- The angles are found by trying them against this very rig - shoulder, elbow, wrist, down to the hand's grip - until
-- the grip lands beside the cup, and then beside the mouth. A rig without those joints (R6) gets the old way: the cup
-- rises on its own.
local RunService = game:GetService("RunService")
local function floatSip(cupModel, carried, place, home, head)
	local root = Instance.new("CFrameValue"); root.Value = home
	local conn = root.Changed:Connect(place)
	local function to(cf, secs) local t = TweenService:Create(root, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Value = cf}); t:Play(); t.Completed:Wait() end
	for i = 1, 2 do
		local face = CFrame.new(head.Position + head.CFrame.LookVector * 0.85 - Vector3.new(0, 0.35, 0)) * (home - home.Position)
		to(face, 0.55); task.wait(0.5); to(face - Vector3.new(0, 0.5, 0), 0.35)
	end
	to(home, 0.5)
	conn:Disconnect(); root:Destroy()
end
local function jointInfo(j)                           -- the joint's two frames and its pose right now
	if not j then return nil end
	if j:IsA("Motor6D") then
		return j.C0, j.C1, j.Transform
	elseif j:IsA("AnimationConstraint") and j.Attachment0 and j.Attachment1 then
		return j.Attachment0.CFrame, j.Attachment1.CFrame, j.Transform
	end
	return nil
end
local sipping = false
local function sip(cupModel)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local cup = cupModel and cupModel:FindFirstChild("Cup")
	if not (head and hum and cup) or sipping then return end
	sipping = true
	-- a copy of the cup, its coffee and its handle goes where the hand takes it; the ones on the table hide meanwhile, and
	-- the saucer stays where it is
	local carried = {}
	for _, p in ipairs(cupModel:GetChildren()) do if p:IsA("BasePart") and p.Name ~= "Saucer" then carried[#carried + 1] = p end end
	local held = Instance.new("Model"); held.Name = "HeldCup"; held.Parent = workspace
	local copies = {}
	for _, p in ipairs(carried) do
		local c = p:Clone(); for _, k in ipairs(c:GetChildren()) do if not k:IsA("Attachment") then k:Destroy() end end
		c.Parent = held; copies[#copies + 1] = {part = c, offset = cup.CFrame:ToObjectSpace(p.CFrame)}
		p.LocalTransparencyModifier = 1
	end
	local home = cup.CFrame
	local upright = home - home.Position
	local function place(cf) for _, e in ipairs(copies) do if e.part.Parent then e.part.CFrame = cf * e.offset end end end
	place(home)

	local ut, ua, la, hand = char:FindFirstChild("UpperTorso"), char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm"), char:FindFirstChild("RightHand")
	local sJ = ua and ua:FindFirstChild("RightShoulder")
	local eJ = la and la:FindFirstChild("RightElbow")
	local wJ = hand and hand:FindFirstChild("RightWrist")
	local s0, s1, sT = jointInfo(sJ)                    -- sT, eT, wT: the seated pose the turns go on top of
	local e0, e1, eT = jointInfo(eJ)
	local w0, w1, wT = jointInfo(wJ)
	local gA = hand and hand:FindFirstChild("RightGripAttachment")
	local ok, err = pcall(function()
		if not (ut and s0 and e0 and w0 and gA) then floatSip(cupModel, carried, place, home, head) return end
		local grip = gA.CFrame
		-- the shoulder: raise the arm forward (x), then swing it in across the front of the body (y), the way an arm brings
		-- a cup up; the zipline's sideways spread (about z) is for arms overhead, and here it flung the elbow up and out
		local function turnS(x, y) return CFrame.Angles(0, y, 0) * CFrame.Angles(x, 0, 0) end
		local function turnE(e) return CFrame.Angles(e, 0, 0) end                             -- bend the elbow
		local function gripAt(x, z, e)
			local uaCF = ut.CFrame * s0 * turnS(x, z) * sT * s1:Inverse()
			local laCF = uaCF * e0 * turnE(e) * eT * e1:Inverse()
			return laCF * w0 * wT * w1:Inverse() * grip
		end
		-- the angles that bring miss(grip) nearest zero: a coarse sweep, then a finer one round the best. Every direction
		-- is tried, the elbow's too: which way a joint bends for "up" depends on the rig (the first try let the elbow
		-- bend one way only, and she held the cup to her ear like a telephone)
		-- an elbow only folds one way: whichever way sends the hand forward from an arm hanging down
		local fwd = ut.CFrame.LookVector
		local flex = ((gripAt(0, 0, math.rad(60)).Position - gripAt(0, 0, math.rad(-60)).Position):Dot(fwd) >= 0) and 1 or -1
		-- near: the pose the arm is coming from (degrees). Each pose stays close to the one before, so the arm moves the short
		-- way round; left free, it found the mouth with the elbow flung up beside the head and swung the long way there
		local function solve(miss, near)
			local best, bestD = {0, 0, 0}, math.huge
			local function try(x, z, bend)
				bend = math.clamp(bend, 0, 150)
				local d = miss(gripAt(math.rad(x), math.rad(z), math.rad(bend * flex)))
					+ 0.002 * (math.abs(x - near[1]) + math.abs(z - near[2]) + math.abs(bend - near[3]))
				if d < bestD then best, bestD = {x, z, bend}, d end
			end
			for x = -10, 130, 10 do for z = -30, 100, 10 do for bend = 0, 150, 10 do try(x, z, bend) end end end
			local b = best
			for x = b[1] - 8, b[1] + 8, 4 do for z = b[2] - 8, b[2] + 8, 4 do for bend = b[3] - 8, b[3] + 8, 4 do try(x, z, bend) end end end
			return {math.rad(best[1]), math.rad(best[2]), math.rad(best[3] * flex)}, best
		end
		-- where the hand goes: the side of the cup nearest the shoulder, then just short of the mouth on that side
		local shoulder = (ut.CFrame * s0).Position
		local flat = Vector3.new(shoulder.X - home.Position.X, 0, shoulder.Z - home.Position.Z)
		local toShoulder = flat.Magnitude > 0.01 and flat.Unit or Vector3.zero
		local grab = home.Position + toShoulder * 0.34 + Vector3.new(0, 0.05, 0)
		local TABLE, tableDeg = solve(function(g) return (g.Position - grab).Magnitude end, {0, 0, 0})
		-- where the cup sits in the hand, from the hand at the cup; then the pose that puts the CUP (not the hand) at the lips
		local held0 = gripAt(TABLE[1], TABLE[2], TABLE[3]):PointToObjectSpace(home.Position)
		-- the lips: low on the face, in front of it - the first go aimed at the middle of the head, and Shannon said "it
		-- looks like she is pouring coffee in her eyes". Scaled to the head, so a big or small head gets it at its mouth too.
		local mouth = head.Position - head.CFrame.UpVector * (head.Size.Y * 0.42 + 0.25) + head.CFrame.LookVector * (head.Size.Z * 0.5 + 0.3)   -- the cup's middle, so its rim is at the lips
		-- on the way: the cup halfway up, in front of the chest - the arm passes through here going up and coming down
		local lift = (home.Position + mouth) / 2 + head.CFrame.LookVector * 0.15
		local MID, midDeg = solve(function(g) return (g:PointToWorldSpace(held0) - lift).Magnitude end, tableDeg)
		local MOUTH = solve(function(g) return (g:PointToWorldSpace(held0) - mouth).Magnitude end, midDeg)
		if _G.SIPDEBUG then
			local cupAt = gripAt(MOUTH[1], MOUTH[2], MOUTH[3]):PointToWorldSpace(held0)
			warn(string.format("QQ SIPDBG - elbow folds %d | table pose %.0f,%.0f,%.0f miss %.2f | mouth pose %.0f,%.0f,%.0f cup misses the lips by %.2f",
				flex, math.deg(TABLE[1]), math.deg(TABLE[2]), math.deg(TABLE[3]), (gripAt(TABLE[1], TABLE[2], TABLE[3]).Position - grab).Magnitude,
				math.deg(MOUTH[1]), math.deg(MOUTH[2]), math.deg(MOUTH[3]), (cupAt - mouth).Magnitude))
		end
		local REST = {0, 0, 0}
		local cur, tilt, offset = {0, 0, 0}, 0, nil
		local pose = RunService.Stepped:Connect(function()            -- after the animation, before the physics
			sJ.Transform = turnS(cur[1], cur[2]) * sT
			eJ.Transform = turnE(cur[3]) * eT
		end)
		local conn = RunService.RenderStepped:Connect(function()
			if offset then                                -- the cup rides in the hand, upright but for the tip at the lips
				local pos = (hand.CFrame * grip):PointToWorldSpace(offset)
				place(CFrame.new(pos) * CFrame.fromAxisAngle(head.CFrame.RightVector, tilt) * upright)
			end
		end)
		local function stillSeated() return char.Parent and hum.Health > 0 and hum.SeatPart ~= nil end
		local function go(to, secs, tiltTo)
			local from, tilt0, t = {cur[1], cur[2], cur[3]}, tilt, 0
			while t < secs do
				t += RunService.RenderStepped:Wait()
				if not stillSeated() then error("stood up") end
				local k = math.min(t / secs, 1); k = k * k * (3 - 2 * k)
				for i = 1, 3 do cur[i] = from[i] + (to[i] - from[i]) * k end
				if tiltTo then tilt = tilt0 + (tiltTo - tilt0) * k end
			end
		end
		local SIP = math.rad(20)                                       -- a tip, not a pour
		local fine = pcall(function()
			go(TABLE, 0.45)                                              -- reach for it
			offset = held0
			go(MID, 0.3); go(MOUTH, 0.35); go(MOUTH, 0.3, SIP); task.wait(0.4)       -- up to the lips, tip, sip
			go(MOUTH, 0.15, 0); go(MID, 0.35); go(MOUTH, 0.4); go(MOUTH, 0.3, SIP); task.wait(0.35)   -- down a little, and a second sip
			go(MOUTH, 0.2, 0); go(MID, 0.3); go(TABLE, 0.35)             -- back down to the saucer
			offset = nil; place(home)
			go(REST, 0.4)                                                -- and the hand comes away
		end)
		conn:Disconnect(); pose:Disconnect()
		sJ.Transform = sT; eJ.Transform = eT                             -- the arm as it was; the animation carries on from there
		if not fine then place(home) end
	end)
	held:Destroy()
	for _, p in ipairs(carried) do p.LocalTransparencyModifier = 0 end
	sipping = false
	if not ok then warn("SpeedClient: sip - " .. tostring(err)) end
end
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "coffee" then
		task.spawn(sip, b)
		say("Mmm. Caf" .. utf8.char(233) .. "! You feel quicker already.")
	end
end)
-- a new stretch of store zoomies: say so
local lastZ = tonumber(player:GetAttribute("Item_zoomiesuntil")) or 0
player:GetAttributeChangedSignal("Item_zoomiesuntil"):Connect(function()
	local v = tonumber(player:GetAttribute("Item_zoomiesuntil")) or 0
	local left = v - workspace:GetServerTimeNow()
	if v > lastZ and left > 0 then say("Zoomies! You run faster for " .. mmss(left) .. ".") end
	lastZ = v
end)
]==]
	local s = Instance.new("Script"); s.Name = "SpeedServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "SpeedClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print(string.format("Speed: installed - coffee cups on %d cafe tables (x%.2f for %ds), store zoomies x%.2f for %d min", made, F:GetAttribute("CoffeeBoost"), F:GetAttribute("CoffeeSeconds"), F:GetAttribute("ZoomiesBoost"), F:GetAttribute("ZoomiesMinutes")))
	return F
end

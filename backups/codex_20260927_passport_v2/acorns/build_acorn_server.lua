-- AcornServer: the acorns are SHARED. One set exists in the world, made by the server, and everybody in that
-- server sees the same ones in the same places. Walk into one and it is deleted - it vanishes from everyone's
-- screen at that moment, not just yours - and some minutes later a fresh one appears at a DIFFERENT free spot.
-- So two people hunting the same street are genuinely racing each other, and the map never looks the same twice.
--
-- The respawn, not the number on the ground, is what governs the economy: with N live acorns and a respawn of R
-- seconds, a whole server can earn at most N/R acorns a second once it has swept the map. The live count only
-- decides how often you stumble on one. Prices later get set against that ceiling.
--
-- Nothing moves. The acorns are placed once and then sit there, so they cost twenty parts of replication ONCE
-- and nothing thereafter - no server stepping, no client stepping.
--
-- Attributes on workspace.AcornSystem:
--     Respawn     seconds before a collected acorn comes back somewhere else (default 300 - five minutes)
--     Density     what fraction of the hiding places hold an acorn at any moment (default 0.33)
--     Value       acorns awarded per pickup (default 1)
-- Run in edit mode: require(workspace.AcornSystem.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local F = workspace:FindFirstChild("AcornSystem")
	if not F then F = Instance.new("Folder"); F.Name = "AcornSystem"; F.Parent = workspace end
	if F:GetAttribute("Respawn") == nil then F:SetAttribute("Respawn", opts.respawn or 300) end
	if F:GetAttribute("Density") == nil then F:SetAttribute("Density", opts.density or 0.33) end
	if F:GetAttribute("Value") == nil then F:SetAttribute("Value", opts.value or 1) end

	-- the client needs telling when a pickup happened, for the sound and the counter
	local RS = game:GetService("ReplicatedStorage")
	local ev = RS:FindFirstChild("AcornPicked")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "AcornPicked"; ev.Parent = RS end
	-- and the save layer needs telling, WITHOUT this script ever touching the DataStore itself: every write to
	-- a player's saved data stays inside SquirrelSetup, which already owns that key and merges properly
	local award = RS:FindFirstChild("AwardAcorns")
	if not award then award = Instance.new("BindableEvent"); award.Name = "AwardAcorns"; award.Parent = RS end

	local old = F:FindFirstChild("AcornServer"); if old then old:Destroy() end
	local SRC = [==[
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent

local template = ServerStorage:WaitForChild("AcornTemplate")
local spots = workspace:WaitForChild("AcornSpots")
local picked = RS:WaitForChild("AcornPicked")
local award = RS:WaitForChild("AwardAcorns")
local REST = template:GetAttribute("Rest") or 0.3

local live = Instance.new("Folder")                    -- run-time only; never saved into the place
live.Name = "Acorns"
live.Parent = workspace

-- every spot, grouped by section, so a collected acorn comes back in the same part of the map and the three
-- sections do not slowly drain into one
local bySection, free, holder = {}, {}, {}
for _, at in ipairs(spots:GetChildren()) do
	if at:IsA("Attachment") then
		local s = at:GetAttribute("Section") or "forest"
		bySection[s] = bySection[s] or {}
		table.insert(bySection[s], at)
	end
end
for s, list in pairs(bySection) do
	free[s] = {}
	for _, at in ipairs(list) do free[s][at] = true end
end

local rng = Random.new()
local function takeFreeSpot(section, avoid)
	local pool = {}
	for at in pairs(free[section] or {}) do
		if at ~= avoid then table.insert(pool, at) end
	end
	if #pool == 0 then return nil end
	return pool[rng:NextInteger(1, #pool)]
end

local function lieAt(model, surface, yaw)
	-- the same placement the preview uses: on its side, turned a different way each time, belly on the surface.
	-- The tilt goes in the PivotTo rather than the parts, because PivotTo would otherwise cancel it out.
	model:PivotTo(CFrame.new(surface + Vector3.new(0, REST, 0))
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(math.rad(90), 0, 0))
end

local spawnAt
local function collect(model, at, section, player)
	-- one collector only. Touched fires many times as a character brushes past, and two limbs can arrive in the
	-- same instant, so the flag is set BEFORE anything else happens.
	if model:GetAttribute("Taken") then return end
	model:SetAttribute("Taken", true)

	local value = F:GetAttribute("Value") or 1
	player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + value)
	award:Fire(player, value)                          -- SquirrelSetup owns the saving
	picked:FireClient(player, player:GetAttribute("Acorns"), model:GetPivot().Position)

	model:Destroy()
	free[section][at] = true
	holder[at] = nil

	local wait = F:GetAttribute("Respawn") or 300
	task.delay(wait, function()
		-- somewhere ELSE, which is the whole point: the map is never the same twice
		local spot = takeFreeSpot(section, at)
		if spot then spawnAt(spot, section) end
	end)
end

function spawnAt(at, section)
	if holder[at] then return end
	local m = template:Clone()
	m.Name = "Acorn"
	lieAt(m, at.Position, rng:NextNumber(0, math.pi * 2))
	m.Parent = live
	free[section][at] = nil
	holder[at] = m

	local hit = m:FindFirstChild("Hit")
	hit.Touched:Connect(function(other)
		local char = other and other.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if player then collect(m, at, section, player) end
	end)
	return m
end

-- fill the map
local density = F:GetAttribute("Density") or 0.33
local planted = {}
for section, list in pairs(bySection) do
	local want = math.max(1, math.floor(#list * density + 0.5))
	local n = 0
	while n < want do
		local spot = takeFreeSpot(section)
		if not spot then break end
		spawnAt(spot, section)
		n += 1
	end
	planted[section] = n
end
print(string.format("AcornServer: %d in the forest, %d in the Rue, %d at the Chateau (%.0f%% of %d hiding places); back after %ds",
	planted.forest or 0, planted.village or 0, planted.domaine or 0, density * 100,
	#spots:GetChildren(), F:GetAttribute("Respawn") or 300))

-- a player who has never played still needs the attribute to exist, so the counter has something to read
Players.PlayerAdded:Connect(function(p)
	if p:GetAttribute("Acorns") == nil then p:SetAttribute("Acorns", 0) end
end)
for _, p in ipairs(Players:GetPlayers()) do
	if p:GetAttribute("Acorns") == nil then p:SetAttribute("Acorns", 0) end
end
]==]
	local s = Instance.new("Script"); s.Name = "AcornServer"; s.RunContext = Enum.RunContext.Server
	s.Source = SRC; s.Parent = F

	-- "bonk": short, percussive, and nothing like the three squirrel toasts. SET rather than defaulted, so a
	-- rebuild does not quietly restore the soft pop that could not be heard.
	F:SetAttribute("PickSound", opts.pickSound or 123582256549202)
	-- 0.6 was almost inaudible under the music. This is a confirmation that a pickup happened, so it has to
	-- carry; the music sits at 0.35 and the squirrel toasts run from 0.9 to 2.2.
	F:SetAttribute("PickVolume", opts.pickVolume or 2.5)

	local oldC = F:FindFirstChild("AcornClient"); if oldC then oldC:Destroy() end
	local CLIENT = [==[
-- AcornClient: the sound and sparkle when an acorn is picked up. Nothing else - the acorns themselves sit
-- perfectly still, so there is no animation here and no per-frame cost at all.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local picked = RS:WaitForChild("AcornPicked")
-- deliberately NOT waiting on workspace.Acorns any more: with nothing to animate there is nothing to wait for,
-- and a WaitForChild that never returns would leave the pickup sound silently unconnected

-- The acorns do NOT move. An acorn that turns and bobs announces itself as a game object; one lying still in
-- the grass reads as an acorn somebody dropped, which is the whole point of hiding them. It also means this
-- script does no per-frame work at all - it only waits for a pickup.


-- The acorn flies to the purse. Picking one up and seeing a number tick somewhere in the corner is easy to
-- miss; watching the thing you just took travel there says what happened without a word, and it points at the
-- counter for anyone who has not noticed it yet.
local function flyToPurse(pos, screen)                          -- screen: a Vector2 to start from instead of a place
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local cam = workspace.CurrentCamera
	if not pg or not cam then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AcornFlight"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 8
	gui.Parent = pg
	Debris:AddItem(gui, 5)                             -- it can never be left on screen, tween or no tween

	-- where it was taken from, in screen pixels
	local from
	if typeof(screen) == "Vector2" then
		from = UDim2.fromOffset(screen.X, screen.Y)
	else
		local sp, onScreen = cam:WorldToViewportPoint(pos)
		from = (onScreen and sp.Z > 0)
			and UDim2.fromOffset(sp.X, sp.Y)
			or UDim2.fromOffset(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.62)
	end

	-- Where the purse is, worked out from the bar's own layout rather than read off AbsolutePosition. A gui that
	-- ignores the inset reports AbsolutePosition with the inset SUBTRACTED, so a square sitting 8 pixels from
	-- the top reads as -28, and aiming at that sends the acorn off the top of the screen. The bar is anchored
	-- top-right at (-10, 8), 160 wide, and the purse is the leftmost of its three 48-pixel squares.
	local to = UDim2.fromOffset(cam.ViewportSize.X - 10 - 160 + 24, 8 + 24)

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5); holder.Position = from
	holder.Size = UDim2.fromOffset(32, 32); holder.BackgroundTransparency = 1; holder.Parent = gui

	local nut = Instance.new("Frame")
	nut.AnchorPoint = Vector2.new(0.5, 0.5); nut.Position = UDim2.fromScale(0.5, 0.62)
	nut.Size = UDim2.fromScale(0.62, 0.62); nut.BackgroundColor3 = Color3.fromRGB(206, 146, 82)
	nut.BorderSizePixel = 0; nut.ZIndex = 2; nut.Parent = holder
	local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0.45, 0); nc.Parent = nut
	local cap = Instance.new("Frame")
	cap.AnchorPoint = Vector2.new(0.5, 0.5); cap.Position = UDim2.fromScale(0.5, 0.26)
	cap.Size = UDim2.fromScale(0.78, 0.34); cap.BackgroundColor3 = Color3.fromRGB(110, 70, 40)
	cap.BorderSizePixel = 0; cap.ZIndex = 3; cap.Parent = holder
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0.4, 0); cc.Parent = cap

	-- up first, then in. A straight line from the grass to the corner reads as a glitch; an arc reads as a throw.
	local lift = UDim2.fromOffset((from.X.Offset + to.X.Offset) / 2,
		math.min(from.Y.Offset, to.Y.Offset) - 64)
	local up = TweenService:Create(holder, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = lift})
	up:Play()
	up.Completed:Connect(function()
		if not gui.Parent then return end
		local home = TweenService:Create(holder,
			TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = to, Size = UDim2.fromOffset(13, 13)})
		home:Play()
		home.Completed:Connect(function() gui:Destroy() end)
	end)
end

-- EVERY GAIN SHOWS (Shannon, Sep 26: "there should be a ding and a visual with the acorns going into your purse when
-- you collect your daily reward or acorns"): whatever pays you - the daily card, a race, a rescue, a prize - you hear
-- the ding and see the acorns fly into the purse, up to a dozen of them. A pickup (AcornPicked) or a claim that shows
-- its own flight (the RewardFly bindable: the daily card sends it from its "+10 acorns") is not shown twice. RewardSound
-- on this folder, if set, is the ding; otherwise the pickup sound.
local me = Players.LocalPlayer
local shownAt = {}                                                -- total -> when it was shown (-1: any gain just now)
local function remember(total)
	shownAt[total or -1] = os.clock()
	for k, at in pairs(shownAt) do if os.clock() - at > 5 then shownAt[k] = nil end end
end
local function ding()
	local id = tostring(F:GetAttribute("RewardSound") or F:GetAttribute("PickSound") or ""):match("%d+")
	if not id then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = F:GetAttribute("PickVolume") or 3
	s.Parent = SoundService; s:Play(); Debris:AddItem(s, 4)
end
local function shower(n, pos, screen)
	local k = math.clamp(math.floor((n or 1) + 0.5), 1, 12)
	for i = 1, k do
		task.delay((i - 1) * 0.08, function()
			local jit = Vector2.new(math.random(-18, 18), math.random(-10, 10))
			if typeof(screen) == "Vector2" then
				flyToPurse(nil, screen + jit)
			elseif typeof(pos) == "Vector3" then
				flyToPurse(pos + Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5))
			else
				local cam = workspace.CurrentCamera
				flyToPurse(nil, Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.55) + jit)
			end
		end)
	end
end
task.spawn(function()
	local rf = F:WaitForChild("RewardFly", 30)
	if rf then rf.Event:Connect(function(screen, n) remember(-1); ding(); shower(n, nil, screen) end) end
end)
do
	local last = me:GetAttribute("Acorns")
	local t0 = os.clock()
	local loadedAt = me:GetAttribute("SaveLoaded") and os.clock() or nil
	me:GetAttributeChangedSignal("SaveLoaded"):Connect(function() if me:GetAttribute("SaveLoaded") then loadedAt = os.clock() end end)
	me:GetAttributeChangedSignal("Acorns"):Connect(function()
		local v = me:GetAttribute("Acorns")
		local prev = last; last = v
		if type(v) ~= "number" or type(prev) ~= "number" or v <= prev then return end
		-- not the save arriving at join (or, where nothing is saved, the first seconds)
		if loadedAt then if os.clock() - loadedAt < 3 then return end elseif os.clock() - t0 < 20 then return end
		task.delay(0.35, function()
			for tot, at in pairs(shownAt) do
				if os.clock() - at < 1.5 and (tot == v or tot == -1) then return end
			end
			local head = me.Character and me.Character:FindFirstChild("Head")
			ding(); shower(v - prev, head and head.Position, nil)
		end)
	end)
end

picked.OnClientEvent:Connect(function(total, pos, count)
	remember(total)
	-- 2D, so it is a confirmation rather than something happening over there in the world
	local s = Instance.new("Sound")
	local id = tostring(F:GetAttribute("PickSound") or ""):match("%d+")
	if id then
		s.SoundId = "rbxassetid://" .. id
		s.Volume = F:GetAttribute("PickVolume") or 3
		s.Parent = SoundService
		s:Play()
		Debris:AddItem(s, 4)
	end
	if typeof(pos) ~= "Vector3" then return end
	shower(count or 1, pos, nil)
	local a = Instance.new("Part")
	a.Size = Vector3.new(0.2, 0.2, 0.2); a.CFrame = CFrame.new(pos)
	a.Anchored = true; a.CanCollide = false; a.CanQuery = false; a.CanTouch = false; a.Transparency = 1
	a.Parent = workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 226, 150))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	pe.Lifetime = NumberRange.new(0.4, 0.8); pe.Speed = NumberRange.new(3, 7)
	pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.LightEmission = 0.9
	pe.Parent = a
	pe:Emit(14)
	Debris:AddItem(a, 2)
end)
]==]
	if not F:FindFirstChild("RewardFly") then local b = Instance.new("BindableEvent"); b.Name = "RewardFly"; b.Parent = F end
	local c = Instance.new("Script"); c.Name = "AcornClient"; c.RunContext = Enum.RunContext.Client
	c.Source = CLIENT; c.Parent = F

	-- the preview belongs to edit mode only; the real acorns are made at run time
	local prev = workspace:FindFirstChild("AcornPreview")
	local cleared = prev and #prev:GetChildren() or 0
	if prev and opts.keepPreview ~= true then prev:Destroy() end

	local spots = workspace:FindFirstChild("AcornSpots")
	print(string.format("AcornServer: installed against %d hiding places; %d a time, back after %ds%s",
		spots and #spots:GetChildren() or 0,
		math.floor((spots and #spots:GetChildren() or 0) * (F:GetAttribute("Density")) + 0.5),
		F:GetAttribute("Respawn"),
		cleared > 0 and string.format("; cleared %d preview acorns", cleared) or ""))
end

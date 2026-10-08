-- The baguette chase. Shannon (Sep 25 2026), after her first players: "easy wins win". A game of tag turned the right
-- way round: "why don't we make the it person a holder of a golden acorn, everyone tries to find him, when they do and
-- tag him, that goes to the person who tags him and that person gets a prize of acorns? then they are it?" - and then
-- a baguette instead of a golden acorn (too close to the Golden Squirrel and the Grand Keeper).
--   JOIN: a button on the screen (and a prompt at the Boulangerie's basket). The button opens a window with what the
--         chase is and its rules, and Join / Leave there (Shannon: make it flashier, and explain before joining).
--         Only those who join play; nobody else is
--         chased, tagged, told about it, or has their whereabouts given away. Map-wide.
--   THE BAGUETTE: with MinPlayers or more in the chase, a fresh one sits in the basket outside the Boulangerie. The
--         first player in the chase to reach it takes it and GrabPrize acorns. Whoever holds it carries it on their back,
--         dropping crumbs, and earns HoldPrize every HoldEvery seconds (up to HoldCap a hold). Tag the holder (within
--         Range) to steal it and the prize; a new holder can't be tagged for Immune seconds, the one who lost it can't
--         take it straight back for NoTakeBack seconds, and grab prizes stop after GrabCap an hour (the chase goes on).
--   HINTS: for players in the chase, squirrels say where it is: "My baguette! SelBell ran off with it toward the
--         chapel!" (tap a squirrel, or the nearest one calls out now and then).
-- Attributes on workspace.Baguette: MinPlayers, GrabPrize, HoldPrize, HoldEvery, HoldCap, Range, Immune, NoTakeBack,
-- GrabCap, HintEvery, Landmarks; live: Holder (UserId, 0 none), HolderName, HolderWhere, AtBakery, Playing.
-- Player attribute InChase = true while joined.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("Baguette")
	if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "Baguette"
	for k, v in pairs({MinPlayers = 2, GrabPrize = 10, HoldPrize = 1, HoldEvery = 10, HoldCap = 30, Range = 4, Immune = 5,
		NoTakeBack = 30, GrabCap = 12, HintEvery = 25}) do F:SetAttribute(k, (opts[k] ~= nil) and opts[k] or v) end
	F:SetAttribute("Holder", 0); F:SetAttribute("HolderName", ""); F:SetAttribute("HolderWhere", "")
	F:SetAttribute("AtBakery", false); F:SetAttribute("Playing", 0)
	local LANDMARKS = {
		{"the forest tower", -23, 5}, {"the Forest Race", 16, 4}, {"the forest trampolines", 60, -60}, {"the river bridge", 156, -120},
		{"the portrait easels", 200, -8}, {"the village spawn", 196, -36}, {"the fountain", 260, -86}, {"the Grand Keeper statue", 260, -58},
		{"the ice cream cart", 247, -63}, {"the Boulangerie", 182, -104}, {"the cafe", 205, -104}, {"the post office", 180, -139},
		{"the Grand Marche", 227, -139}, {"the pharmacie", 258, -139}, {"the hat shop", 312, -139}, {"the bookshop", 335, -143},
		{"the flower shop", 320, -101}, {"the lavender fields", 456, -166}, {"the sunflowers", 430, -99}, {"the farmhouse", 482, -36},
		{"the barn", 536, -40}, {"the windmill", 588, -62}, {"the vineyard", 578, -179}, {"the toadstool run", 500, -233}, {"the chapel", 655, -172},
	}
	local lm = {}
	for _, l in ipairs(LANDMARKS) do table.insert(lm, string.format("%s|%d|%d", l[1], l[2], l[3])) end
	F:SetAttribute("Landmarks", table.concat(lm, ";"))

	-- ---------------------------------------------------------------- the basket outside the Boulangerie ----
	local at = opts.at or Vector3.new(189, 0, -104.5)                  -- right of the door, on the pavement
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local g = workspace:Raycast(Vector3.new(at.X, 40, at.Z), Vector3.new(0, -80, 0), rp)
	at = Vector3.new(at.X, g and g.Position.Y or at.Y, at.Z)
	local base = CFrame.new(at) * CFrame.Angles(0, math.rad(opts.turn or 0), 0)
	local stand = Instance.new("Model"); stand.Name = "Stand"; stand.Parent = F
	local UP = CFrame.Angles(0, 0, math.rad(90))
	local BREAD, CRUST, SLASH, WICKER, WOOD = C(214, 160, 90), C(176, 120, 60), C(236, 200, 140), C(170, 120, 70), C(122, 86, 60)
	local function part(name, size, cf, colour, material, shape, parent)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or stand
		return p
	end
	part("Crate", Vector3.new(1.7, 1.2, 1.7), base * CFrame.new(0, 0.6, 0), WOOD, Enum.Material.WoodPlanks)
	part("Basket", Vector3.new(1.3, 1.5, 1.5), base * CFrame.new(0, 1.85, 0) * UP, WICKER, Enum.Material.Fabric, Enum.PartType.Cylinder)
	part("BasketRim", Vector3.new(0.18, 1.62, 1.62), base * CFrame.new(0, 2.5, 0) * UP, C(150, 104, 60), nil, Enum.PartType.Cylinder)
	for i, lean in ipairs({{-0.35, 14, 0.2}, {0.3, -10, -0.25}, {0.05, 4, 0.35}}) do          -- everyday baguettes, leaning
		local cf = base * CFrame.new(lean[1], 3.0, lean[3]) * CFrame.Angles(math.rad(lean[2]), 0, math.rad(lean[2] * 0.6)) * UP
		part("Loaf", Vector3.new(2.3, 0.34, 0.34), cf, BREAD, nil, Enum.PartType.Cylinder)
	end
	-- the chase baguette, standing up in the middle when it is there to be taken; it shines a little
	local prize = part("ChaseBaguette", Vector3.new(2.9, 0.42, 0.42), base * CFrame.new(0, 3.35, 0) * UP, C(226, 172, 96), nil, Enum.PartType.Cylinder)
	prize.CanCollide = false; prize.Transparency = 1
	local shine = Instance.new("Attachment"); shine.Name = "ShineAt"; shine.Parent = prize
	local sp = Instance.new("ParticleEmitter"); sp.Name = "Shine"; sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Color = ColorSequence.new(C(255, 230, 160)); sp.LightEmission = 0.7; sp.Rate = 8; sp.Lifetime = NumberRange.new(0.6, 1.1)
	sp.Speed = NumberRange.new(0.5, 1.5); sp.SpreadAngle = Vector2.new(180, 180); sp.Enabled = false
	sp.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)}); sp.Parent = shine
	-- a little sign on the crate
	local signPart = part("Sign", Vector3.new(1.5, 0.7, 0.06), base * CFrame.new(0, 0.7, -0.88), C(52, 64, 58))
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 70
	sg.LightInfluence = 0.5; sg.Parent = signPart
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(0.94, 0.9); tl.Position = UDim2.fromScale(0.03, 0.05); tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne; tl.TextScaled = true; tl.TextColor3 = C(245, 240, 230); tl.Text = "Steal the baguette!"; tl.Parent = sg
	local prompt = Instance.new("ProximityPrompt"); prompt.Name = "ChasePrompt"; prompt.ActionText = "Join the baguette chase"
	prompt.ObjectText = "Boulangerie"; prompt.HoldDuration = 0.2; prompt.MaxActivationDistance = 9; prompt.RequiresLineOfSight = false
	prompt.Parent = signPart

	local join = Instance.new("RemoteEvent"); join.Name = "ChaseJoin"; join.Parent = F
	local ev = Instance.new("RemoteEvent"); ev.Name = "ChaseEvent"; ev.Parent = F

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[
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
local function setHolder(p, reason, from)
	if holder then removeHeld(holder) end
	holder = p
	if p then
		attach(p)
		F:SetAttribute("Holder", p.UserId); F:SetAttribute("HolderName", p.DisplayName); F:SetAttribute("HolderWhere", where(p))
		immuneUntil = os.clock() + (A("Immune") or 5); heldSince = os.clock(); earnedThisHold = 0
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
	while true do
		task.wait(1)
		if holder then F:SetAttribute("HolderWhere", where(holder)) end
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
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local F = script.Parent
local join = F:WaitForChild("ChaseJoin")
local ev = F:WaitForChild("ChaseEvent")
local C = Color3.fromRGB
local NAVY, CREAM, GOLDEN = C(38, 30, 52), C(255, 246, 220), C(240, 196, 110)
local FONT = Enum.Font.FredokaOne
local BREAD = utf8.char(0x1F956)
local OU = "O" .. utf8.char(249) .. " est"
local function A(k) return F:GetAttribute(k) end
local function inChase() return player:GetAttribute("InChase") == true end

local gui = Instance.new("ScreenGui"); gui.Name = "ChaseGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 8; gui.Parent = player:WaitForChild("PlayerGui")
-- the join button, for everyone, top left under Roblox's own buttons. Shannon: "the Join to Baguette Chase button should
-- be flashier so that people really see it, and instead of it just signing you up for it with a click, when you click
-- that button it should open a modal that explains what it is and the rules and lets you join from the modal." Warm
-- gold and orange with a bright rim while you are not in the chase - and NOTHING on it moves: no growing, no fading rim,
-- no shine (Shannon, twice: "the button still has the 'expanding' motion I asked you to get rid of");
-- plain navy once you are. Either way a tap opens the window below, never joins or leaves by itself.
local UIS = game:GetService("UserInputService")
local PHONE = (UIS.TouchEnabled and not UIS.KeyboardEnabled)        -- phones and tablets: little room, so tighter layouts
	or F:GetAttribute("ForcePhoneLayout") == true                   -- (a test switch on workspace.Baguette; off in the live game)
local button = Instance.new("TextButton"); button.Name = "Join"; button.Position = UDim2.new(0, 12, 0, PHONE and 10 or 58)  -- phones: tucked up under Roblox's icons (Sep 26: "too high ... move it down very, very slightly")
button.AutomaticSize = Enum.AutomaticSize.X
button.Size = UDim2.fromOffset(0, 30); button.BackgroundColor3 = C(255, 255, 255); button.Font = FONT; button.TextSize = 14
button.AutoButtonColor = false; button.ClipsDescendants = true; button.Parent = gui
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 15); bc.Parent = button
local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 10); bp.PaddingRight = UDim.new(0, 10); bp.Parent = button
local bs = Instance.new("UIStroke"); bs.Color = C(255, 244, 200); bs.Thickness = 2; bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; bs.Parent = button
local bg = Instance.new("UIGradient"); bg.Rotation = 90
bg.Color = ColorSequence.new(C(255, 200, 80), C(236, 122, 44)); bg.Parent = button
local bscale = Instance.new("UIScale"); bscale.Parent = button
local bshine = Instance.new("Frame"); bshine.Name = "Shine"; bshine.BackgroundColor3 = C(255, 255, 255); bshine.BorderSizePixel = 0
bshine.Size = UDim2.new(0, 40, 1, 0); bshine.Position = UDim2.new(0, -60, 0, 0); bshine.Parent = button
local bsg = Instance.new("UIGradient")
bsg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1)}); bsg.Parent = bshine
local function dress()
	if inChase() then
		bg.Enabled = false; button.BackgroundColor3 = NAVY; button.BackgroundTransparency = 0.12; button.TextColor3 = CREAM
		bs.Color = GOLDEN; bs.Thickness = 1.2; bs.Transparency = 0.3; bshine.Visible = false
	else
		bg.Enabled = true; button.BackgroundColor3 = C(255, 255, 255); button.BackgroundTransparency = 0; button.TextColor3 = C(84, 40, 10)
		bs.Color = C(255, 236, 170); bs.Thickness = 2; bs.Transparency = 0; bshine.Visible = false
	end
end
-- the banner, only for those in the chase
local banner = Instance.new("TextLabel"); banner.AnchorPoint = Vector2.new(0.5, 0); banner.Position = UDim2.new(0.5, 0, 0, 58)
banner.AutomaticSize = Enum.AutomaticSize.X; banner.Size = UDim2.fromOffset(0, 30); banner.BackgroundColor3 = NAVY; banner.BackgroundTransparency = 0.12
banner.Font = FONT; banner.TextSize = 17; banner.TextColor3 = GOLDEN; banner.Visible = false; banner.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 15); nc.Parent = banner
local np = Instance.new("UIPadding"); np.PaddingLeft = UDim.new(0, 14); np.PaddingRight = UDim.new(0, 14); np.Parent = banner

local function refresh()
	local playing = A("Playing") or 0
	dress()
	if inChase() then
		button.Text = string.format("%s Chasing (%d)", BREAD, playing)
	else
		button.Text = string.format("%s Baguette Chase%s", BREAD, playing > 0 and string.format(" (%d)", playing) or "")
	end
	if not inChase() then banner.Visible = false return end
	banner.Visible = true
	local holderId, name = A("Holder") or 0, A("HolderName") or ""
	if playing < (A("MinPlayers") or 2) then
		banner.Text = "Waiting for another player to join the chase..."
	elseif holderId == player.UserId then
		banner.Text = string.format("You have the baguette! +%d acorn every %ds - don't get tagged!", A("HoldPrize") or 1, A("HoldEvery") or 10)
	elseif holderId ~= 0 then
		banner.Text = string.format("%s has the baguette! Tag them for %d acorns!", name, A("GrabPrize") or 10)
	elseif A("AtBakery") then
		banner.Text = "A fresh baguette is out at the Boulangerie - grab it!"
	else
		banner.Text = "The baguette chase is on!"
	end
end
for _, k in ipairs({"Playing", "Holder", "HolderName", "AtBakery", "MinPlayers"}) do F:GetAttributeChangedSignal(k):Connect(refresh) end
player:GetAttributeChangedSignal("InChase"):Connect(refresh)
refresh()
-- ---- the window: what the chase is, the rules (from the chase's own settings), and Join / Leave ----
-- its own layer, above the daily acorns card and every other panel, so nothing sits on top of it
local igui = Instance.new("ScreenGui"); igui.Name = "ChaseInfoGui"; igui.ResetOnSpawn = false; igui.DisplayOrder = 30
igui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; igui.Parent = player:WaitForChild("PlayerGui")
local shade = Instance.new("TextButton"); shade.Name = "Shade"; shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(20, 12, 6)
shade.BackgroundTransparency = 0.45; shade.Text = ""; shade.AutoButtonColor = false; shade.Visible = false; shade.ZIndex = 20; shade.Parent = igui
local modal = Instance.new("Frame"); modal.Name = "ChaseInfo"; modal.AnchorPoint = Vector2.new(0.5, 0.5); modal.Position = UDim2.fromScale(0.5, 0.45)
modal.Size = UDim2.fromOffset(440, 0); modal.AutomaticSize = Enum.AutomaticSize.Y; modal.BackgroundColor3 = CREAM; modal.Visible = false
modal.ZIndex = 21; modal.Parent = igui
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 18); mc.Parent = modal
local ms = Instance.new("UIStroke"); ms.Color = GOLDEN; ms.Thickness = 3; ms.Parent = modal
-- THE BORDER GLOWS GOLD WITH A LIGHT RUNNING ROUND IT (Shannon: "make the boarder around the modal glowy gold in a
-- circular motion around the boarder"): a gradient on the border, darker gold to a bright pale gold, turned a little every
-- frame while the window is open, so the bright side travels round and round. Nothing changes size.
ms.Color = C(255, 255, 255); ms.Thickness = 4
local ring = Instance.new("UIGradient"); ring.Name = "Ring"
ring.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(196, 136, 36)), ColorSequenceKeypoint.new(0.55, C(228, 170, 58)),
	ColorSequenceKeypoint.new(0.85, C(255, 222, 120)), ColorSequenceKeypoint.new(1, C(255, 250, 215))})
ring.Parent = ms
game:GetService("RunService").RenderStepped:Connect(function(dt)
	if modal.Visible then ring.Rotation = (ring.Rotation + dt * 120) % 360 end   -- once round every three seconds
end)
local mscale = Instance.new("UIScale"); mscale.Parent = modal
-- the words and buttons stack in a body frame; the X sits on the window itself, outside the stack
local body = Instance.new("Frame"); body.Name = "Body"; body.BackgroundTransparency = 1; body.Size = UDim2.new(1, 0, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y; body.ZIndex = 21; body.Parent = modal
local mpad = Instance.new("UIPadding"); mpad.PaddingTop = UDim.new(0, 18); mpad.PaddingBottom = UDim.new(0, 18)
mpad.PaddingLeft = UDim.new(0, 20); mpad.PaddingRight = UDim.new(0, 20); mpad.Parent = body
local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 10); list.SortOrder = Enum.SortOrder.LayoutOrder
list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.Parent = body
local BROWN = C(84, 40, 10)
local function mtext(order, size, colour, rich)
	local l = Instance.new("TextLabel"); l.LayoutOrder = order; l.BackgroundTransparency = 1; l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y; l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.TextWrapped = true
	l.RichText = rich == true; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 22; l.Parent = body
	return l
end
local mtitle = mtext(1, 26, BROWN); mtitle.TextXAlignment = Enum.TextXAlignment.Center
mtitle.Text = BREAD .. " The Baguette Chase"
local mintro = mtext(2, 17, C(110, 70, 30)); mintro.TextXAlignment = Enum.TextXAlignment.Center
mintro.Text = "Tag, the French way! There's one baguette, and everyone in the chase wants it."
mintro.Visible = false                                       -- the simple version everywhere: no intro line
local mrules = mtext(3, 18, BROWN, true)
local mstatus = mtext(4, 16, C(58, 120, 72)); mstatus.TextXAlignment = Enum.TextXAlignment.Center
-- CRISP WORDS (Shannon: "the text looks blurred ... it should not look muddy"): the rules and the status line in Roblox's
-- own clean face, which has a real bold (FredokaOne has none, so <b> smeared it), and darker ink on the cream. The title
-- and the buttons keep FredokaOne - at their size it reads cleanly.
mrules.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
mrules.TextColor3 = C(40, 24, 10)
mstatus.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
mstatus.TextColor3 = C(30, 96, 46)
local row = Instance.new("Frame"); row.LayoutOrder = 5; row.BackgroundTransparency = 1; row.Size = UDim2.new(1, 0, 0, 46); row.ZIndex = 22; row.Parent = body
local rl = Instance.new("UIListLayout"); rl.FillDirection = Enum.FillDirection.Horizontal; rl.Padding = UDim.new(0, 12)
rl.HorizontalAlignment = Enum.HorizontalAlignment.Center; rl.VerticalAlignment = Enum.VerticalAlignment.Center; rl.Parent = row
local function mbutton(order, primary)
	local b = Instance.new("TextButton"); b.LayoutOrder = order; b.Size = UDim2.fromOffset(180, 44); b.Font = FONT; b.TextSize = 18
	b.AutoButtonColor = true; b.ZIndex = 23; b.Parent = row
	b.BackgroundColor3 = primary and C(245, 170, 60) or C(236, 226, 206); b.TextColor3 = BROWN
	local k = Instance.new("UICorner"); k.CornerRadius = UDim.new(0, 14); k.Parent = b
	local s = Instance.new("UIStroke"); s.Color = primary and C(200, 120, 30) or C(200, 180, 150); s.Thickness = 2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = b
	return b
end
local mgo = mbutton(1, true)
local mno = mbutton(2, false)
local mx = Instance.new("TextButton"); mx.Name = "Close"; mx.AnchorPoint = Vector2.new(1, 0); mx.Position = UDim2.new(1, 8, 0, -8)
mx.Size = UDim2.fromOffset(34, 34); mx.BackgroundColor3 = C(236, 226, 206); mx.Text = "X"; mx.Font = FONT; mx.TextSize = 18; mx.TextColor3 = BROWN
mx.ZIndex = 24; mx.Parent = modal
local xk = Instance.new("UICorner"); xk.CornerRadius = UDim.new(1, 0); xk.Parent = mx
-- ON A PHONE: wide and short, at the top of the screen, clear of the hotbar (the binoculars and the slingshot) at the
-- bottom; four short rules instead of seven long ones, in bigger letters, and it never shrinks them past easy reading
if PHONE then
	modal.Size = UDim2.fromOffset(600, 0); modal.AnchorPoint = Vector2.new(0.5, 0); modal.Position = UDim2.new(0.5, 0, 0, 4)
	mpad.PaddingTop = UDim.new(0, 12); mpad.PaddingBottom = UDim.new(0, 12); mpad.PaddingLeft = UDim.new(0, 18); mpad.PaddingRight = UDim.new(0, 18)
	list.Padding = UDim.new(0, 6)
	mtitle.TextSize = 24; mintro.Visible = false; mrules.TextSize = 19; mstatus.TextSize = 17
	for _, b in ipairs({mgo, mno}) do b.Size = UDim2.fromOffset(200, 46); b.TextSize = 20 end
end
local function rulesText()                                   -- the short rules, on phones and computers alike (Shannon)
	local lines = {
		string.format("<b>Grab the baguette</b> at the Boulangerie: +%d acorns", A("GrabPrize") or 10),
		string.format("<b>Hold on to it</b>: +%d acorn every %d seconds", A("HoldPrize") or 1, A("HoldEvery") or 10),
		string.format("<b>Run into the holder</b> to steal it: +%d acorns", A("GrabPrize") or 10),
		string.format("Starts when %d players join. <b>Tap a squirrel</b> for hints", A("MinPlayers") or 2),
	}
	for i, l in ipairs(lines) do lines[i] = utf8.char(0x2022) .. "  " .. l end
	return table.concat(lines, "\n")
end
local function fillModal()
	mrules.Text = rulesText()
	local playing = A("Playing") or 0
	if inChase() then
		mstatus.Text = string.format("You're in the chase with %d player%s.", math.max(playing - 1, 0), (playing - 1 == 1) and "" or "s")
		mgo.Text = "Keep chasing"; mno.Text = "Leave the chase"
	else
		mstatus.Text = playing > 0 and string.format("%d player%s in the chase right now!", playing, playing == 1 and " is" or "s are")
			or "Nobody's chasing yet - join and wait for a friend!"
		mgo.Text = "Join the chase!"; mno.Text = "Maybe later"
	end
end
local function fitModal()                                    -- small screens: shrink the whole window to fit
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local h = (modal.AbsoluteSize.Y / math.max(mscale.Scale, 0.01))
	if PHONE then
		local inset = game:GetService("GuiService"):GetGuiInset().Y
		local room = vp.Y - inset - 4 - 84                        -- above the hotbar (binoculars, slingshot) at the bottom
		mscale.Scale = math.clamp(math.min((vp.X - 24) / 600, room / math.max(h, 1)), 0.8, 1)   -- never below 80%: readable
	else
		mscale.Scale = math.clamp(math.min((vp.X - 24) / 440, (vp.Y - 24) / math.max(h, 1)), 0.55, 1)
	end
end
local function openModal()
	fillModal()
	shade.Visible = true; modal.Visible = true
	task.defer(fitModal)                                     -- no pop: it simply appears (Shannon: no expanding motion)
	task.delay(0.1, fitModal)
end
local function closeModal() shade.Visible = false; modal.Visible = false end
mgo.Activated:Connect(function()
	if not inChase() then join:FireServer(true) end
	closeModal()
end)
mno.Activated:Connect(function()
	if inChase() then join:FireServer(false) end
	closeModal()
end)
mx.Activated:Connect(closeModal)
shade.Activated:Connect(closeModal)                          -- nothing to type in here, so a tap outside may close it
for _, k in ipairs({"Playing", "MinPlayers", "GrabPrize", "HoldPrize", "HoldEvery", "HoldCap", "Immune", "NoTakeBack"}) do
	F:GetAttributeChangedSignal(k):Connect(function() if modal.Visible then fillModal() end end)
end
player:GetAttributeChangedSignal("InChase"):Connect(function() if modal.Visible then fillModal() end end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if modal.Visible then fitModal() end end) end
button.Activated:Connect(openModal)

-- a word at the bottom of the screen
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -150); note.Size = UDim2.fromOffset(470, 40)
note.BackgroundColor3 = NAVY; note.BackgroundTransparency = 1; note.BorderSizePixel = 0; note.Font = FONT; note.TextSize = 18; note.TextColor3 = CREAM
note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = gui
local nnc = Instance.new("UICorner"); nnc.CornerRadius = UDim.new(0, 12); nnc.Parent = note
local shown = 0
local function say(text)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); shown = mine
	task.delay(3.6, function() if shown ~= mine then return end; TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
end
ev.OnClientEvent:Connect(function(what, a, b, reason, id, fromId)
	if what == "joined" then
		say("You're in the baguette chase! " .. ((A("Playing") or 0) < (A("MinPlayers") or 2) and "Waiting for someone else to join..." or "Go get it!"))
	elseif what == "bakery" then
		say("A fresh baguette is out at the Boulangerie!")
	elseif what == "grabbed" then
		if a then say(string.format("You've got the baguette! +%d acorns. Now run!", A("GrabPrize") or 10))
		else say("You've got the baguette! (No more grab prizes this hour - keep playing!)") end
	elseif what == "holder" and a ~= "" and reason == "stolen" then
		if fromId == player.UserId then say(a .. " stole your baguette!")
		elseif id ~= player.UserId then say(a .. " stole the baguette from " .. b .. "!") end
	elseif what == "holder" and a ~= "" and reason == "bakery" and id ~= player.UserId then
		say(a .. " grabbed the fresh baguette!")
	end
end)

-- the squirrels speak up, for players in the chase: tap one, or the nearest calls out now and then
local HOLDER_LINES = {"My baguette! %s ran off with it toward %s!", "%s has the baguette - near %s!", "I saw %s with the baguette by %s!",
	"Vite! %s went past %s!"}
local NAME_LINES = {OU .. " la baguette? %s has it!", "Catch %s - that's my baguette!", "Get my baguette back from %s!"}
local MINE = {"Run! They want your baguette!", "Keep that baguette safe!", "Cours! Don't let them catch you!", "Psst - hide in the trees!"}
local function line()
	if not inChase() or (A("Playing") or 0) < (A("MinPlayers") or 2) then return nil end
	local holderId, name, whereName = A("Holder") or 0, A("HolderName") or "", A("HolderWhere") or ""
	if holderId == player.UserId then return MINE[math.random(#MINE)] end
	if holderId ~= 0 and name ~= "" then
		if whereName ~= "" and math.random() < 0.6 then return string.format(HOLDER_LINES[math.random(#HOLDER_LINES)], name, whereName) end
		return string.format(NAME_LINES[math.random(#NAME_LINES)], name)
	end
	if A("AtBakery") then return "A fresh baguette at the Boulangerie - vite!" end
	return nil
end
local bubbles = setmetatable({}, {__mode = "k"})
local function speak(model, text)
	if not (model and text) then return end
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not anchor then return end
	if bubbles[model] and bubbles[model].Parent then bubbles[model]:Destroy() end
	local bb = Instance.new("BillboardGui"); bb.Name = "ChaseBubble"; bb.Size = UDim2.fromOffset(240, 60); bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.MaxDistance = 80; bb.Adornee = anchor; bb.AlwaysOnTop = true
	local f = Instance.new("TextLabel"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = NAVY; f.BackgroundTransparency = 0.1
	f.Font = FONT; f.TextScaled = true; f.TextColor3 = CREAM; f.Text = text; f.Parent = bb
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = f
	local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 10); p.PaddingRight = UDim.new(0, 10); p.PaddingTop = UDim.new(0, 6); p.PaddingBottom = UDim.new(0, 6); p.Parent = f
	bb.Parent = player.PlayerGui
	bubbles[model] = bb
	-- a squirrel sound with the bubble (Shannon's picks, shared with the croc's squirrels: workspace.Lagoon.SpeechSounds)
	local lag = workspace:FindFirstChild("Lagoon")
	local ids = {}
	for d in tostring(lag and lag:GetAttribute("SpeechSounds") or "73324775979494, 90860503936571, 9119556839"):gmatch("%d+") do table.insert(ids, d) end
	if #ids > 0 then
		local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. ids[math.random(#ids)]; s.Volume = 0.9
		s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 80; s.Parent = anchor
		s:Play(); game:GetService("Debris"):AddItem(s, 8)
		-- a long one is cut short, faded out after SpeechMax seconds (Shannon: "not quite the whole 8 seconds")
		task.delay((lag and lag:GetAttribute("SpeechMax")) or 4, function()
			if s.Parent and s.IsPlaying then game:GetService("TweenService"):Create(s, TweenInfo.new(0.5), {Volume = 0}):Play() end
		end)
	end
	task.delay(3.5, function() if bb.Parent then bb:Destroy() end end)
end
local hooked = setmetatable({}, {__mode = "k"})
local function hook(model)
	for _, cd in ipairs(model:GetDescendants()) do
		if cd:IsA("ClickDetector") and not hooked[cd] then
			hooked[cd] = true
			cd.MouseClick:Connect(function() speak(model, line()) end)
		end
	end
end
for _, m in ipairs(CS:GetTagged("Squirrel")) do hook(m) end
CS:GetInstanceAddedSignal("Squirrel"):Connect(function(m) task.wait(1); hook(m) end)
task.spawn(function() while true do task.wait(10); for _, m in ipairs(CS:GetTagged("Squirrel")) do hook(m) end end end)
task.spawn(function()
	while true do
		task.wait((A("HintEvery") or 25) * (0.8 + math.random() * 0.4))
		local text = line()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if text and hrp then
			local best, bd
			for _, m in ipairs(CS:GetTagged("Squirrel")) do
				local ok, pos = pcall(function() return m:GetPivot().Position end)
				if ok then
					local d = (pos - hrp.Position).Magnitude
					if d < 45 and (not bd or d < bd) then best, bd = m, d end
				end
			end
			if best then speak(best, text) end
		end
	end
end)
]==]
	local s = Instance.new("Script"); s.Name = "ChaseServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "ChaseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	local n = 0
	for _, d in ipairs(stand:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	return string.format("Baguette chase: basket at %.1f,%.2f,%.1f (%d parts) | %d+ players, %d a grab, +%d per %ds held", at.X, at.Y, at.Z, n,
		F:GetAttribute("MinPlayers"), F:GetAttribute("GrabPrize"), F:GetAttribute("HoldPrize"), F:GetAttribute("HoldEvery"))
end

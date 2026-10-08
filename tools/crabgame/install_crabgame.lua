-- Oct 4 2026: install the crab game (Shannon approved the whole plan; golden crab = 100 acorns).
-- Needs the imported trap model workspace.crabtrap (TrapFrame + TrapNet from italy/crabtrap/crabtrap.fbx).
-- Builds ReplicatedStorage.CrabGame (CrabEvent, Trap, Buoy, Line, Crab), workspace.CrabGame (settings, CrabServer, SellSpot
-- prompt at Beppe's crate), StarterPlayerScripts.CrabClient; adds the crab trap to the Acorn Store (ShopServer, ShopClient,
-- Price/Sell attributes) and its icon to SquirrelIllustrations. Every source edit is an exact-anchor insert; a missing anchor
-- warns and skips. Re-runnable (rebuilds its own pieces, never inserts twice). No asserts after the first edit.
local RS=game.ReplicatedStorage
local SPS=game.StarterPlayer.StarterPlayerScripts
local imp=workspace:FindFirstChild('crabtrap')
local frameP=imp and imp:FindFirstChild('TrapFrame',true)
local netP=imp and imp:FindFirstChild('TrapNet',true)
if not (frameP and netP) and not (RS:FindFirstChild('CrabGame') and RS.CrabGame:FindFirstChild('Trap')) then warn('QK@ABORT no imported crabtrap') return end
local crabT=RS:FindFirstChild('TidePoolCrab')
if not crabT then warn('QK@ABORT no TidePoolCrab') return end
local beppeCrate=workspace.PortoNocciola:FindFirstChild('BeppeCrate',true)
if not beppeCrate then warn('QK@ABORT no BeppeCrate') return end

-- ReplicatedStorage kit
local kit=RS:FindFirstChild('CrabGame')
local oldTrap=kit and kit:FindFirstChild('Trap')
if not kit then kit=Instance.new('Folder') kit.Name='CrabGame' kit.Parent=RS end
for _,n in ipairs({'CrabEvent','Buoy','Line','Crab'}) do local o=kit:FindFirstChild(n) if o then o:Destroy() end end
local re=Instance.new('RemoteEvent') re.Name='CrabEvent' re.Parent=kit
if frameP and netP then
	if oldTrap then oldTrap:Destroy() end
	local trap=Instance.new('Model') trap.Name='Trap'
	for _,p in ipairs({frameP,netP}) do p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Parent=trap end
	frameP.Color=Color3.fromRGB(118,122,126) frameP.Material=Enum.Material.Metal frameP.TextureID=''
	pcall(function() netP.DoubleSided=true end)
	trap.PrimaryPart=frameP
	trap.Parent=kit
	imp:Destroy()
end
-- the float: a red ball with a white band, a line end on top
local buoy=Instance.new('Model') buoy.Name='Buoy'
local ball=Instance.new('Part') ball.Name='Float' ball.Shape=Enum.PartType.Ball ball.Size=Vector3.new(0.7,0.7,0.7)
ball.Color=Color3.fromRGB(214,56,44) ball.Material=Enum.Material.SmoothPlastic ball.Anchored=true ball.CanCollide=false ball.CanQuery=false ball.CanTouch=false ball.Parent=buoy
local band=Instance.new('Part') band.Name='Band' band.Shape=Enum.PartType.Cylinder band.Size=Vector3.new(0.16,0.74,0.74)
band.CFrame=ball.CFrame*CFrame.Angles(0,0,math.rad(90)) band.Color=Color3.fromRGB(250,248,240) band.Material=Enum.Material.SmoothPlastic
band.Anchored=false band.CanCollide=false band.CanQuery=false band.CanTouch=false band.Massless=true band.Parent=buoy
local w=Instance.new('WeldConstraint') w.Part0=ball w.Part1=band w.Parent=ball
local le=Instance.new('Attachment') le.Name='LineEnd' le.Position=Vector3.new(0,0.3,0) le.Parent=ball
buoy.PrimaryPart=ball buoy.Parent=kit
-- the rope
local line=Instance.new('Beam') line.Name='Line' line.Color=ColorSequence.new(Color3.fromRGB(150,118,78)) line.Width0=0.06 line.Width1=0.06
line.FaceCamera=true line.Segments=12 line.LightInfluence=1 line.Transparency=NumberSequence.new(0) line.Parent=kit
-- a crab for the catch (the tide-pool crab, smaller)
local crab=crabT:Clone() crab.Name='Crab'
pcall(function() crab:ScaleTo(0.65) end)
crab.Parent=kit

-- workspace.CrabGame: settings, the server, Beppe's sell spot
local G=workspace:FindFirstChild('CrabGame')
if not G then G=Instance.new('Folder') G.Name='CrabGame' G.Parent=workspace end
for _,n in ipairs({'CrabServer','SellSpot'}) do local o=G:FindFirstChild(n) if o then o:Destroy() end end
G:SetAttribute('ZoneMin',Vector3.new(280,-58,-814)) G:SetAttribute('ZoneMax',Vector3.new(318,-43,-758))
G:SetAttribute('SeaY',-52.9) G:SetAttribute('Bucket',6) G:SetAttribute('CrabPay',3) G:SetAttribute('GoldPay',100)
G:SetAttribute('GoldChance',0.05) G:SetAttribute('WaitMin',10) G:SetAttribute('WaitMax',15)
local spotCF,spotSize=beppeCrate:GetBoundingBox()
local spot=Instance.new('Part') spot.Name='SellSpot' spot.Size=Vector3.new(1,1,1) spot.Transparency=1
spot.Anchored=true spot.CanCollide=false spot.CanQuery=false spot.CanTouch=false
spot.CFrame=CFrame.new(spotCF.Position+Vector3.new(0,spotSize.Y/2+0.2,0)) spot.Parent=G
local pr=Instance.new('ProximityPrompt') pr.Name='SellPrompt' pr.ActionText='Sell crabs' pr.ObjectText='Beppe the Fishmonger'
pr.HoldDuration=0.25 pr.MaxActivationDistance=9 pr.RequiresLineOfSight=false pr.Parent=spot
local srv=Instance.new('Script') srv.Name='CrabServer' srv.Source=[==[-- CrabServer (workspace.CrabGame): the crab game at Porto Nocciola (Oct 4 2026, Shannon: "buy a crab trap from the acorn
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
]==] srv.Parent=G
local oldc=SPS:FindFirstChild('CrabClient') if oldc then oldc:Destroy() end
local cli=Instance.new('LocalScript') cli.Name='CrabClient' cli.Source=[==[-- CrabClient (StarterPlayerScripts): the crab game's button and bucket (Oct 4 2026). The server (workspace.CrabGame.CrabServer)
-- decides everything; this only shows it. In the Crab Catching Area with a trap: one round button - Cast, then a filling
-- ring while the crabs find the trap, then Pull in! The bucket count rides on the button; away from the area with crabs
-- in the bucket it shrinks to a little "sell to Beppe" pill. Beppe and Enzo talk through the SquirrelBubble like every squirrel.
-- PHONES: nothing may overlap anything - the panel tries a list of corners and takes the first one clear of every other
-- visible thing on screen (measured with the gui inset, the way phone_overlap_probe does).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local G = workspace:WaitForChild("CrabGame")
local kit = RS:WaitForChild("CrabGame")
local ev = kit:WaitForChild("CrabEvent")
local okBubble, Bubble = pcall(function() return require(RS:WaitForChild("SquirrelBubble", 10)) end)
local okArt, Art = pcall(function() return require(RS:WaitForChild("SquirrelIllustrations", 10)) end)

local RGB = Color3.fromRGB
local FACE, RIM, INK, GOLD = RGB(250, 241, 219), RGB(118, 80, 46), RGB(64, 42, 22), RGB(255, 202, 62)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

local function inZone(pos)
	local a, b = G:GetAttribute("ZoneMin"), G:GetAttribute("ZoneMax")
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return false end
	return pos.X >= a.X and pos.X <= b.X and pos.Y >= a.Y and pos.Y <= b.Y and pos.Z >= a.Z and pos.Z <= b.Z
end
local function counts() return player:GetAttribute("Item_crabs") or 0, player:GetAttribute("Item_goldcrabs") or 0 end
local function bucketMax() return G:GetAttribute("Bucket") or 6 end

-- ---------------------------------------------------------------- the panel
local gui = Instance.new("ScreenGui")
gui.Name = "CrabGui" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 6 gui.Enabled = false gui.Parent = pg
local root = Instance.new("Frame") root.Name = "Root" root.BackgroundTransparency = 1 root.Size = UDim2.fromOffset(190, 176)
root.AnchorPoint = Vector2.new(1, 1) root.Parent = gui

local btn = Instance.new("TextButton") btn.Name = "CastButton" btn.Text = "" btn.AutoButtonColor = false
btn.Size = UDim2.fromOffset(92, 92) btn.Position = UDim2.new(0.5, -46, 0, 44) btn.BackgroundColor3 = FACE btn.Parent = root
Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
local rim = Instance.new("UIStroke") rim.Color = RIM rim.Thickness = 4 rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border rim.Parent = btn
local icon = okArt and Art.draw(btn, "crabtrap", 58) or Instance.new("Frame")
icon.Position = UDim2.fromOffset(17, 8) icon.Size = UDim2.fromOffset(58, 58) icon.BackgroundTransparency = 1
local word = Instance.new("TextLabel") word.BackgroundTransparency = 1 word.Size = UDim2.new(1, 0, 0, 22) word.Position = UDim2.fromOffset(0, 62)
word.FontFace = FONT word.TextSize = 17 word.TextColor3 = INK word.Text = "Cast" word.ZIndex = 5 word.Parent = btn
-- the waiting ring: a gold fill rising behind the icon
local fill = Instance.new("Frame") fill.Name = "Fill" fill.BackgroundColor3 = RGB(255, 226, 140) fill.BorderSizePixel = 0
fill.AnchorPoint = Vector2.new(0, 1) fill.Position = UDim2.fromScale(0, 1) fill.Size = UDim2.fromScale(1, 0) fill.ZIndex = 1 fill.Parent = btn
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
btn.ClipsDescendants = true

local pill = Instance.new("Frame") pill.Name = "Bucket" pill.Size = UDim2.fromOffset(118, 24) pill.Position = UDim2.new(0.5, -59, 0, 144)
pill.BackgroundColor3 = FACE pill.Parent = root
Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
local ps = Instance.new("UIStroke") ps.Color = RIM ps.Thickness = 2 ps.Parent = pill
local pillText = Instance.new("TextLabel") pillText.BackgroundTransparency = 1 pillText.Size = UDim2.fromScale(1, 1)
pillText.FontFace = FONT pillText.TextSize = 14 pillText.TextColor3 = INK pillText.Parent = pill

local note = Instance.new("TextLabel") note.Name = "Note" note.BackgroundTransparency = 1 note.Size = UDim2.fromOffset(190, 40)
note.Position = UDim2.fromOffset(0, 0) note.FontFace = FONT note.TextSize = 14 note.TextColor3 = RGB(255, 255, 255)
note.TextStrokeTransparency = 0.35 note.TextWrapped = true note.TextYAlignment = Enum.TextYAlignment.Bottom note.Text = "" note.Parent = root

local function say(text, secs)
	note.Text = text note.TextTransparency = 0 note.TextStrokeTransparency = 0.35
	local myText = text
	task.delay(secs or 3, function()
		if note.Text == myText then
			TweenService:Create(note, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end

-- ---------------------------------------------------------------- state
local state = "idle"        -- idle | flying | waiting | ready
local readyAt, castAt = 0, 0
local pulse
local function setWord(t, col) word.Text = t word.TextColor3 = col or INK end
local function stopPulse() if pulse then pulse:Cancel() pulse = nil end rim.Color = RIM rim.Thickness = 4 end
local function toIdle() state = "idle" stopPulse() fill.Size = UDim2.fromScale(1, 0) setWord("Cast") end

local function press()
	if state == "idle" then
		state = "flying" setWord("...") ev:FireServer("cast")
		task.delay(3, function() if state == "flying" then toIdle() end end)     -- the server said no (it also says why)
	elseif state == "waiting" or state == "ready" then
		ev:FireServer("pull") setWord("...")
	end
end
btn.Activated:Connect(press)

ev.OnClientEvent:Connect(function(what, a, b, c, d)
	if what == "say" then say(a, 3.5) if state == "flying" then toIdle() end
	elseif what == "cast" then
		state = "waiting" readyAt = a castAt = workspace:GetServerTimeNow() setWord("Wait...")
	elseif what == "caught" then
		local plain, gold, let, early = a, b, c, d
		toIdle()
		if early then say("Too soon - the crabs weren't in yet!", 3)
		elseif gold > 0 then say("A GOLDEN CRAB!" .. (plain > 0 and ("  +" .. plain .. " more") or ""), 4)
		elseif plain == 0 then say("Empty this time. Try again!", 3)
		else say(plain == 1 and "You caught a crab!" or ("You caught " .. plain .. " crabs!"), 3) end
		if let > 0 then task.delay(2.2, function() say("Bucket full - you let " .. let .. " go.", 3) end) end
	elseif what == "lost" then toIdle() say("You left the crab area - trap reeled in.", 3)
	elseif what == "sold" then
		local plain, gold, pay = a, b, c
		local beppe = workspace:FindFirstChild("fishmonger_squirrel_color")
		local line
		if pay == 0 then line = "No crabs? Come back when your bucket's full!"
		elseif gold > 0 then line = "A GOLDEN crab?! Mamma mia! " .. pay .. " acorns for you!"
		else line = ({"Grazie! Fresh from the rocks - " .. pay .. " acorns.", "Bellissimi! " .. pay .. " acorns for these.", "Ah, lovely crabs! Here's " .. pay .. " acorns."})[math.random(1, 3)] end
		if okBubble and beppe then pcall(Bubble.say, beppe, line, {secs = 3.5}) else say(line, 3.5) end
	end
end)

-- ---------------------------------------------------------------- placement clear of everything else
local function rectOf(o)
	local inset = GuiService:GetGuiInset()
	local p, s = o.AbsolutePosition + inset, o.AbsoluteSize
	return p.X, p.Y, p.X + s.X, p.Y + s.Y
end
local function visible(o)
	local x = o
	while x and x ~= pg do
		if x:IsA("GuiObject") and not x.Visible then return false end
		if x:IsA("ScreenGui") and not x.Enabled then return false end
		x = x.Parent
	end
	return true
end
local function others()
	local list = {}
	local vp = workspace.CurrentCamera.ViewportSize
	for _, sg in ipairs(pg:GetChildren()) do
		if sg:IsA("ScreenGui") and sg ~= gui and sg.Enabled and sg.Name ~= "SquirrelBubbleGui" then
			for _, o in ipairs(sg:GetDescendants()) do
				if o:IsA("GuiObject") and o.AbsoluteSize.X > 4 and o.AbsoluteSize.Y > 4 and visible(o)
					and (o.BackgroundTransparency < 1 or o:IsA("ImageLabel") or o:IsA("ImageButton") or o:IsA("TextButton") or (o:IsA("TextLabel") and o.Text ~= "")) then
					local s = o.AbsoluteSize
					if not (s.X >= vp.X * 0.9 and s.Y >= vp.Y * 0.9) then table.insert(list, {rectOf(o)}) end
				end
			end
		end
	end
	return list
end
local function clearAt(x0, y0, x1, y1, list)
	for _, r in ipairs(list) do
		if x0 < r[3] + 4 and x1 > r[1] - 4 and y0 < r[4] + 4 and y1 > r[2] - 4 then return false end
	end
	return true
end
local function place()
	local vp = workspace.CurrentCamera.ViewportSize
	local w, h = root.AbsoluteSize.X, root.AbsoluteSize.Y
	local list = others()
	-- bottom-right corner first (above a phone's jump button), then up the right side, then the bottom middle and left
	local tries = {}
	for _, fy in ipairs({0.62, 0.5, 0.75, 0.38}) do table.insert(tries, Vector2.new(vp.X - 16, vp.Y * fy + h / 2)) end
	for _, fy in ipairs({0.62, 0.5}) do table.insert(tries, Vector2.new(vp.X - 120, vp.Y * fy + h / 2)) end
	table.insert(tries, Vector2.new(vp.X / 2 + w / 2, vp.Y - 16))
	table.insert(tries, Vector2.new(vp.X * 0.3 + w / 2, vp.Y * 0.5 + h / 2))
	for _, t in ipairs(tries) do
		local x1, y1 = t.X, t.Y
		if clearAt(x1 - w, y1 - h, x1, y1, list) then
			root.Position = UDim2.fromOffset(x1, y1) return true
		end
	end
	root.Position = UDim2.fromOffset(tries[1].X, tries[1].Y)
	return false
end

-- ---------------------------------------------------------------- every frame: show/hide, ring, prompt
local sellPrompt = G:FindFirstChild("SellPrompt", true)
local lastPlace, wasShown, compact = 0, false, nil
local enzoSaid = 0
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local plain, gold = counts()
	local have = (player:GetAttribute("Item_crabtrap") or 0) > 0
	local zone = hrp and inZone(hrp.Position)
	local castOn = have and zone or state ~= "idle"
	local show = castOn or (plain + gold > 0)
	gui.Enabled = show
	btn.Visible = castOn
	pill.Visible = plain + gold > 0 or castOn
	pillText.Text = (gold > 0 and ("Crabs " .. (plain + gold) .. "/" .. bucketMax() .. "  (1 gold)") or ("Crabs " .. plain .. "/" .. bucketMax()))
		.. ((not castOn and plain + gold > 0) and " - sell to Beppe" or "")
	pill.Size = UDim2.fromOffset((not castOn and plain + gold > 0) and 190 or 118, 24)
	pill.Position = UDim2.new(0.5, -pill.Size.X.Offset / 2, 0, 144)
	if sellPrompt then sellPrompt.Enabled = plain + gold > 0 end
	if state == "waiting" or state == "ready" then
		local now = workspace:GetServerTimeNow()
		local t = math.clamp((now - castAt) / math.max(0.1, readyAt - castAt), 0, 1)
		fill.Size = UDim2.fromScale(1, t)
		if t >= 1 and state == "waiting" then
			state = "ready" setWord("Pull in!", RGB(150, 52, 30))
			rim.Color = GOLD
			pulse = TweenService:Create(rim, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 7})
			pulse:Play()
		end
	end
	if show and (not wasShown or compact ~= castOn or os.clock() - lastPlace > 2) then
		lastPlace = os.clock() compact = castOn
		task.defer(place)
	end
	wasShown = show
	-- Enzo's tip for anybody at the pools without a trap
	if hrp and not have and os.clock() - enzoSaid > 60 then
		local enzo = workspace:FindFirstChild("crabcatcher_squirrel_color")
		local cm = enzo and enzo:FindFirstChild("Squirrel")
		if cm and (cm.Position - hrp.Position).Magnitude < 12 then
			enzoSaid = os.clock()
			if okBubble then pcall(Bubble.say, enzo, "Want to catch crabs? Get a crab trap in the Acorn Store!", {secs = 4}) end
		end
	end
end)

-- PC: F casts and pulls while the button is up
CAS:BindAction("CrabCast", function(_, st)
	if st == Enum.UserInputState.Begin and gui.Enabled and btn.Visible then press() return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F)
]==] cli.Parent=SPS

-- the Acorn Store
local shop=workspace.Shop
shop:SetAttribute('Price_crabtrap',40) shop:SetAttribute('Sell_crabtrap',true)
local function insert(scr,anchor,add,dupKey)
	local s=scr.Source
	if s:find(dupKey,1,true) then warn('QK@SKIP already there',scr:GetFullName()) return true end
	local a=s:find(anchor,1,true)
	if not a then warn('QK@MISSING anchor in',scr:GetFullName()) return false end
	scr.Source=s:sub(1,a-1)..add..s:sub(a)
	return true
end
local ok1=insert(shop.ShopServer,'\tzoomies    = {repeatable = true, clock = "zoomiesuntil"',
	'\tcrabtrap   = {once = true},                           -- Oct 4 2026: the crab game at Porto Nocciola (workspace.CrabGame)\n','crabtrap')
local ok2=insert(shop.ShopClient,'\t{id = "backpack",',
	'\t{id = "crabtrap",   name = "Crab trap",       blurb = "Yours to keep. Cast it off the rocks in the Crab Catching Area at Porto Nocciola, then sell your catch to Beppe.", once = true},\n','"crabtrap"')
local ok3=insert(RS.SquirrelIllustrations,' else -- A friendly squirrel profile',
	' elseif id=="crabtrap" then\n'..
	'  local grey,orange=C(120,124,128),C(222,106,52)\n'..
	'  circle(.17,.17,.66,grey);circle(.22,.22,.56,green)\n'..
	'  for _,r in ipairs({45,-45,0,90}) do line(.25,.485,.5,.03,cream,r) end\n'..
	'  circle(.37,.37,.26,grey);circle(.42,.42,.16,C(48,84,64))\n'..
	'  circle(.60,.62,.20,orange);circle(.55,.57,.09,orange);circle(.76,.57,.09,orange)\n'..
	' elseif id=="crab" or id=="goldcrab" then\n'..
	'  local orange=id=="goldcrab" and gold or C(222,106,52)\n'..
	'  shape(.26,.44,.48,.28,orange,.5);circle(.12,.28,.2,orange);circle(.68,.28,.2,orange)\n'..
	'  circle(.38,.36,.08,cream);circle(.54,.36,.08,cream)\n'..
	'  for i=0,2 do line(.14,.6+i*.07,.16,.035,orange,20);line(.70,.6+i*.07,.16,.035,orange,-20) end\n','id=="crabtrap"')
game:GetService('ChangeHistoryService'):SetWaypoint('Crab game installed')
warn('QK@OK store',ok1,ok2,ok3,'trap',kit:FindFirstChild('Trap')~=nil,'sell spot',spot.Position,'server',#srv.Source,'client',#cli.Source)

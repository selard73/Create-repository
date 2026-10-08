-- Glaces: an ice cream cart on the lawn by the painter. Shannon (Sep 25 2026): "we do not have a glaces built right now.
-- But it could be a cart on the grass side where the painter is?" - after watching new players: "easy wins win; not
-- anything that takes effort". So: one press at the cart and a cone is in your hand - one to three scoops of the day's
-- flavours, at random. Tap (use it) to lick the top scoop down; the last lick is a BRAIN FREEZE and the cone is gone with
-- a crunch. Free, quick, and everyone around sees it.
-- The cone is a Tool, so the character holds it up the way Roblox holds any tool, and a tap anywhere licks it.
-- Each lick, the licker's arm brings the cone up to the mouth on every screen (GlaceClient); the last is a bite of the cone.
-- Attributes on workspace.Glaces: GetSound, LickSound, FreezeSound, CrunchSound (asset ids; 0 = no sound), Licks (per
-- scoop), GripX/GripY/GripZ (degrees: how the cone sits in the hand), MysteryChance (a scoop's chance of being the
-- secret Mystere: white with rainbow sprinkles).
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("Glaces")
	if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "Glaces"
	for k, v in pairs({GetSound = 109359226723492, LickSound = 9114634609, FreezeSound = 78869058955345, CrunchSound = 95510889867083, Licks = 2, GripX = 0, GripY = 0, GripZ = 0, MysteryChance = 0.12}) do
		F:SetAttribute(k, (opts[k] ~= nil) and opts[k] or v)
	end

	-- where: on the lawn just north of the fountain square, west of the path up to the Grand Keeper statue, facing the
	-- fountain (Shannon: "it might be better over close to the fountain but in the grass?" - first try was by the painter)
	local at = opts.at or Vector3.new(247, 0, -63)
	local toward = opts.toward or Vector3.new(260, 0, -86)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	local ground = workspace:Raycast(Vector3.new(at.X, at.Y + 60, at.Z), Vector3.new(0, -120, 0), rp)
	at = Vector3.new(at.X, ground and ground.Position.Y or at.Y, at.Z)          -- standing on the grass, whatever its height
	local face = Vector3.new(toward.X - at.X, 0, toward.Z - at.Z).Unit
	local base = CFrame.lookAt(at, at + face)                -- -Z, the LookVector, is the customers' side
	local function L(x, y, z) return base * CFrame.new(x, y, z) end
	local UP = CFrame.Angles(0, 0, math.rad(90))              -- a cylinder's axis is X; this stands it up
	local ACROSS = CFrame.Angles(0, math.rad(90), 0)          -- lays a cylinder's axis across the cart (wheels)

	local MINT, CREAM, PINK, BERRY = C(170, 222, 200), C(250, 244, 228), C(238, 150, 172), C(214, 92, 128)
	local BROWN, SILVER, WAFFLE, WAFFLE2 = C(122, 86, 60), C(200, 204, 210), C(214, 166, 96), C(190, 140, 78)
	local FLAVOURS = {{"Lavande", C(186, 160, 222)}, {"Pistache", C(170, 210, 130)}, {"Fraise", C(245, 150, 170)},
		{"Chocolat", C(125, 78, 52)}, {"Citron", C(250, 232, 120)}, {"Vanille", C(252, 244, 220)}}

	local cart = Instance.new("Model"); cart.Name = "Cart"; cart.Parent = F
	local function part(name, size, cf, colour, material, shape, parent)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or cart
		return p
	end
	-- a flat triangle a-b-c from two wedges (the usual way to draw any triangle with Roblox parts)
	local function tri(a, b, c, colour, parent)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then c, a = a, c elseif acd > bcd and acd > abd then a, b = b, a end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		for i, pair in ipairs({{a + b, ab, right, back}, {a + c, ac, -right, -back}}) do
			local w = Instance.new("WedgePart"); w.Name = "Canopy"; w.Anchored = true; w.Color = colour
			w.Material = Enum.Material.SmoothPlastic; w.TopSurface = Enum.SurfaceType.Smooth; w.BottomSurface = Enum.SurfaceType.Smooth
			w.Size = Vector3.new(0.06, height, math.abs(pair[2]:Dot(back)))
			w.CFrame = CFrame.fromMatrix(pair[1] / 2, pair[3], up, pair[4])
			w.Parent = parent or cart
		end
	end

	-- ---------------------------------------------------------------- the cart ----
	for _, sz in ipairs({-1, 1}) do                            -- two big wheels at one end
		part("Tyre", Vector3.new(0.18, 2.0, 2.0), L(-1.7, 1.0, sz * 1.3) * ACROSS, BROWN, nil, Enum.PartType.Cylinder)
		part("Wheel", Vector3.new(0.22, 1.86, 1.86), L(-1.7, 1.0, sz * 1.33) * ACROSS, CREAM, nil, Enum.PartType.Cylinder)
		part("Hub", Vector3.new(0.3, 0.5, 0.5), L(-1.7, 1.0, sz * 1.43) * ACROSS, PINK, nil, Enum.PartType.Cylinder)
		part("Leg", Vector3.new(0.22, 0.95, 0.22), L(1.95, 0.475, sz * 0.9), BROWN)      -- and legs at the other
	end
	part("Axle", Vector3.new(2.9, 0.16, 0.16), L(-1.7, 1.0, 0) * ACROSS, BROWN, nil, Enum.PartType.Cylinder)
	part("Body", Vector3.new(5.0, 1.8, 2.4), L(0, 1.85, 0), MINT)
	part("Band", Vector3.new(5.1, 0.14, 2.5), L(0, 0.99, 0), PINK)
	part("Rim", Vector3.new(5.1, 0.2, 2.5), L(0, 2.78, 0), CREAM)
	part("Counter", Vector3.new(5.0, 0.1, 2.4), L(0, 2.93, 0), CREAM)
	for _, sx in ipairs({-2.35, 2.35}) do part("Stripe", Vector3.new(0.18, 1.6, 2.46), L(sx, 1.86, 0), PINK) end
	-- the handle at the leg end, for pushing it about the square
	part("Handlebar", Vector3.new(2.3, 0.14, 0.14), L(3.05, 2.2, 0) * ACROSS, BROWN, nil, Enum.PartType.Cylinder)
	for _, sz in ipairs({-1, 1}) do part("HandleArm", Vector3.new(0.6, 0.12, 0.12), L(2.75, 2.2, sz * 1.05), BROWN) end

	-- the sign on the customers' side
	local sign = part("SignPanel", Vector3.new(3.6, 0.95, 0.06), L(-0.1, 1.9, -1.23), CREAM)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 60; sg.LightInfluence = 0.4; sg.Parent = sign
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1; tl.Font = Enum.Font.FredokaOne
	tl.TextScaled = true; tl.TextColor3 = BERRY; tl.Text = "GLACES"; tl.Parent = sg

	-- under glass: the six tubs of the day
	local case = part("Case", Vector3.new(3.3, 0.85, 1.7), L(-0.45, 3.4, 0.05), C(215, 238, 248), Enum.Material.Glass)
	case.Transparency = 0.7
	local k = 0
	for _, z in ipairs({-0.38, 0.48}) do
		for _, x in ipairs({-1.5, -0.45, 0.6}) do
			k += 1
			part("Tub", Vector3.new(0.45, 0.72, 0.72), L(x, 3.2, z) * UP, SILVER, Enum.Material.Metal, Enum.PartType.Cylinder)
			part("Tub" .. FLAVOURS[k][1], Vector3.new(0.64, 0.64, 0.64), L(x, 3.47, z), FLAVOURS[k][2], nil, Enum.PartType.Ball)
		end
	end
	-- empty cones waiting in a stand
	local function coneRings(parentModel, cf, anchored)
		local rings = {}
		for i, r in ipairs({0.07, 0.12, 0.17, 0.22, 0.27}) do
			local p = part("Cone", Vector3.new(0.14, r * 2, r * 2), cf * CFrame.new(0, -0.62 + i * 0.13, 0) * UP, (i % 2 == 0) and WAFFLE2 or WAFFLE,
				nil, Enum.PartType.Cylinder, parentModel)
			p.Anchored = anchored
			rings[#rings + 1] = p
		end
		return rings
	end
	part("ConeStand", Vector3.new(0.95, 0.32, 0.5), L(1.8, 3.12, -0.2), CREAM)
	for i = -1, 1 do coneRings(cart, L(1.8 + i * 0.3, 3.62, -0.2), true) end

	-- the parasol: a pole and an eight-sided striped canopy, pink and cream, with a little ball on top
	local poleX, poleZ, ringY, apexY, R = 0.35, 0.75, 7.35, 8.55, 3.3
	part("Pole", Vector3.new(4.9, 0.14, 0.14), L(poleX, 5.35, poleZ) * UP, CREAM, nil, Enum.PartType.Cylinder)
	local apex = L(poleX, apexY, poleZ).Position
	local ring = {}
	for i = 0, 8 do
		local th = math.rad(22.5 + i * 45)
		ring[i] = L(poleX + math.cos(th) * R, ringY, poleZ + math.sin(th) * R).Position
	end
	for i = 0, 7 do
		local colour = (i % 2 == 0) and PINK or CREAM
		tri(apex, ring[i], ring[i + 1], colour)
		part("Scallop", Vector3.new(0.5, 0.5, 0.5), CFrame.new((ring[i] + ring[i + 1]) / 2 - Vector3.new(0, 0.12, 0)), colour, nil, Enum.PartType.Ball)
	end
	part("Finial", Vector3.new(0.34, 0.34, 0.34), CFrame.new(apex + Vector3.new(0, 0.1, 0)), BERRY, nil, Enum.PartType.Ball)

	-- the chalkboard: today's flavours, an easel leaning back on one rear leg. The first version turned the board 25
	-- degrees AFTER tipping it, so it tipped sideways, and its leg leaned the other way across it - Shannon: "it is not
	-- tilted properly". Now it is turned first, then leaned straight back about its own bottom edge, and the leg runs
	-- from just under the top of the board down to the grass behind it.
	local LEAN = math.rad(12)
	local foot = L(-3.9, 0, -1.2) * CFrame.Angles(0, math.rad(25), 0)          -- the board's bottom edge, facing the customers
	local up = Vector3.new(0, math.cos(LEAN), math.sin(LEAN))                   -- up the board (its top leaning back, +Z)
	local backN = Vector3.new(0, -math.sin(LEAN), math.cos(LEAN))               -- straight out of the board's back
	local board = part("Chalkboard", Vector3.new(1.7, 2.1, 0.12), foot * CFrame.new(up * 1.05 + Vector3.new(0, 0.02, 0)) * CFrame.Angles(LEAN, 0, 0), C(52, 64, 58))
	local legTop, legToe = up * 1.9 + backN * 0.13, Vector3.new(0, 0.05, 1.45)
	part("BoardLeg", Vector3.new(0.14, (legTop - legToe).Magnitude, 0.14), foot * CFrame.fromMatrix((legTop + legToe) / 2, Vector3.xAxis, (legTop - legToe).Unit), BROWN)
	local bg = Instance.new("SurfaceGui"); bg.Face = Enum.NormalId.Front; bg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	bg.PixelsPerStud = 70; bg.LightInfluence = 0.5; bg.Parent = board
	local bl = Instance.new("TextLabel"); bl.Size = UDim2.fromScale(0.9, 0.9); bl.Position = UDim2.fromScale(0.05, 0.05); bl.BackgroundTransparency = 1
	bl.Font = Enum.Font.FredokaOne; bl.TextScaled = true; bl.TextColor3 = C(245, 245, 240); bl.RichText = true
	bl.Text = '<font color="#F7B6C8">Parfums du jour</font>\nLavande\nPistache\nFraise\nChocolat\nCitron\nVanille'
	bl.Parent = bg

	-- the press: on the sign, at arm's length
	local prompt = Instance.new("ProximityPrompt"); prompt.Name = "GlacePrompt"
	prompt.ActionText = "Get an ice cream!"; prompt.ObjectText = "Glaces"; prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10; prompt.RequiresLineOfSight = false; prompt.Parent = sign

	local ev = Instance.new("RemoteEvent"); ev.Name = "GlaceEvent"; ev.Parent = F

	-- ---------------------------------------------------------------- the cone, and the licking: server ----
	local SERVER = [==[local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")
local F = script.Parent
local ev = F:WaitForChild("GlaceEvent")
local C = Color3.fromRGB
local FLAVOURS = {{"Lavande", C(186, 160, 222)}, {"Pistache", C(170, 210, 130)}, {"Fraise", C(245, 150, 170)},
	{"Chocolat", C(125, 78, 52)}, {"Citron", C(250, 232, 120)}, {"Vanille", C(252, 244, 220)}}
local WAFFLE, WAFFLE2 = C(214, 166, 96), C(190, 140, 78)
local UP = CFrame.Angles(0, 0, math.rad(90))
local MYSTERE = "Myst" .. utf8.char(232) .. "re"
local SPRINKLES = {C(255, 90, 110), C(255, 200, 60), C(90, 200, 120), C(90, 160, 255), C(200, 110, 230), C(255, 140, 60)}

local function sound(key, parent)
	local id = tonumber(F:GetAttribute(key)) or 0
	if id <= 0 or not parent then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = 0.7
	s.RollOffMinDistance = 8; s.RollOffMaxDistance = 60; s.Parent = parent; s:Play()
	Debris:AddItem(s, 7)
	return s
end

local function piece(name, size, colour, shape, handle, offset, tool)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = colour; p.Material = Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = handle.CFrame * offset
	local w = Instance.new("Weld"); w.Part0 = handle; w.Part1 = p; w.C0 = offset; w.Parent = p
	p.Parent = tool
	return p, w
end

-- the cone: five waffle rings narrowing to a point, the Handle an invisible block at the rim; scoops of 0.56
-- stacked on top, each on its own weld so a lick can shrink it and settle it back down on the one below
local function makeCone(n)
	local tool = Instance.new("Tool"); tool.Name = "Ice Cream"; tool.CanBeDropped = false; tool.RequiresHandle = true
	tool.ToolTip = "Tap to lick!"
	local gx, gy, gz = F:GetAttribute("GripX") or 0, F:GetAttribute("GripY") or 0, F:GetAttribute("GripZ") or 0
	tool.Grip = CFrame.Angles(math.rad(gx), math.rad(gy), math.rad(gz))
	local h = Instance.new("Part"); h.Name = "Handle"; h.Size = Vector3.new(0.3, 0.3, 0.3); h.Transparency = 1
	h.CanCollide = false; h.CanQuery = false; h.CanTouch = false; h.Massless = true; h.CFrame = CFrame.new(0, 100, 0); h.Parent = tool
	for i, r in ipairs({0.07, 0.12, 0.17, 0.22, 0.27}) do
		piece("Cone", Vector3.new(0.14, r * 2, r * 2), (i % 2 == 0) and WAFFLE2 or WAFFLE, Enum.PartType.Cylinder, h,
			CFrame.new(0, -0.62 + i * 0.13, 0) * UP, tool)
	end
	local scoops, names, mystery = {}, {}, false
	for i = 1, n do
		-- the secret flavour: now and then one scoop is the Mystere - white, with rainbow sprinkles - just for the surprise
		local secret = not mystery and math.random() < (F:GetAttribute("MysteryChance") or 0.12)
		local f = secret and {MYSTERE, C(252, 244, 250)} or FLAVOURS[math.random(#FLAVOURS)]
		local p, w = piece("Scoop", Vector3.new(0.56, 0.56, 0.56), f[2], Enum.PartType.Ball, h, CFrame.new(0, 0.28 + (i - 1) * 0.42, 0), tool)
		if secret then
			mystery = true
			for k = 1, 9 do                                      -- sprinkles, riding on the scoop (and gone with it)
				local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.1, math.random() - 0.5).Unit
				local s = Instance.new("Part"); s.Name = "Sprinkle"; s.Shape = Enum.PartType.Ball; s.Size = Vector3.new(0.1, 0.1, 0.1)
				s.Color = SPRINKLES[(k - 1) % #SPRINKLES + 1]; s.Material = Enum.Material.SmoothPlastic
				s.CanCollide = false; s.CanQuery = false; s.CanTouch = false; s.Massless = true; s.CFrame = p.CFrame * CFrame.new(dir * 0.28)
				local sw = Instance.new("Weld"); sw.Name = "SprinkleWeld"; sw.Part0 = p; sw.Part1 = s; sw.C0 = CFrame.new(dir * 0.28); sw.Parent = s
				s.Parent = p
			end
		end
		scoops[i] = {part = p, weld = w, licks = 0}
		if not table.find(names, f[1]) then names[#names + 1] = f[1] end
	end
	return tool, scoops, names, mystery
end

local holding = {}                                   -- player -> the tool they are holding
local function brainFreeze(player, char)
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local a = Instance.new("Attachment"); a.Parent = head
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255), Color3.fromRGB(150, 210, 255)); pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}); pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(3, 7); pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.Parent = a
	pe:Emit(40)
	Debris:AddItem(a, 2)
	local bb = Instance.new("BillboardGui"); bb.Name = "BrainFreeze"; bb.Size = UDim2.fromOffset(220, 54); bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true; bb.MaxDistance = 70; bb.Adornee = head
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.FredokaOne
	t.TextScaled = true; t.Text = "BRAIN FREEZE!"; t.TextColor3 = Color3.fromRGB(150, 215, 255); t.TextStrokeTransparency = 0
	t.TextStrokeColor3 = Color3.fromRGB(255, 255, 255); t.Parent = bb
	bb.Parent = head
	Debris:AddItem(bb, 2.2)
	sound("FreezeSound", head)
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "glace") end
	ev:FireClient(player, "freeze")
end

local function give(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	if holding[player] and holding[player].Parent then holding[player]:Destroy() end
	local roll = math.random()
	local tool, scoops, names, mystery = makeCone(roll < 0.3 and 1 or (roll < 0.75 and 2 or 3))
	holding[player] = tool
	local busy = false
	-- one lick sound at a time: Shannon's lick runs 4.7 s and taps can come every 0.2 s, so each new lick stops the last,
	-- and the brain freeze stops the final one just after it starts
	local lickSnd
	local function hush() if lickSnd then lickSnd:Stop(); lickSnd:Destroy(); lickSnd = nil end end
	tool.Activated:Connect(function()
		if busy then return end
		busy = true
		-- the arm brings the cone up to the mouth on every screen (GlaceClient), and the lick lands when it gets there
		ev:FireAllClients("lick", player, tool)
		task.wait(0.3)
		local top = scoops[#scoops]
		if top then
			top.licks += 1
			local per = F:GetAttribute("Licks") or 2
			hush(); lickSnd = sound("LickSound", tool:FindFirstChild("Handle"))
			if top.licks >= per then
				top.part:Destroy(); scoops[#scoops] = nil
			else
				local s = 0.56 * (1 - top.licks / (per + 0.6))       -- a lick smaller, its bottom where it was: still on the one below
				top.part.Size = Vector3.new(s, s, s)
				top.weld.C0 = CFrame.new(0, 0.28 + (#scoops - 1) * 0.42 - (0.56 - s) / 2, 0)
				for _, sp in ipairs(top.part:GetChildren()) do          -- the sprinkles stay on the surface
					local sw = sp:FindFirstChild("SprinkleWeld")
					if sw then sw.C0 = CFrame.new(sw.C0.Position.Unit * (s / 2)) end
				end
			end
		end
		if #scoops == 0 then
			task.delay(0.6, hush)
			brainFreeze(player, char)
			-- then a bite of the cone: up to the mouth once more, the crunch, and it is gone (the tool goes once the arm is
			-- back down, so the arm is not left hanging in the air)
			task.delay(0.85, function() if tool.Parent then ev:FireAllClients("lick", player, tool, true) end end)
			task.delay(1.2, function()
				if not tool.Parent then return end
				sound("CrunchSound", char and char:FindFirstChild("Head"))
				for _, d in ipairs(tool:GetDescendants()) do if d:IsA("BasePart") then d.Transparency = 1 end end
				task.delay(0.75, function() if tool.Parent then tool:Destroy() end end)
			end)
			return
		end
		task.wait(0.25)
		busy = false
	end)
	tool.Parent = char                                   -- straight into the hand
	sound("GetSound", char:FindFirstChild("Head"))
	ev:FireClient(player, "got", names)
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "GlacePrompt" and prompt:IsDescendantOf(F) then give(player) end
end)
Players.PlayerRemoving:Connect(function(p) holding[p] = nil end)
print("Glaces: the cart is open")
]==]

	-- ---------------------------------------------------------------- a word on screen, and the shiver: client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local F = script.Parent
local ev = F:WaitForChild("GlaceEvent")
local C = Color3.fromRGB
local gui = Instance.new("ScreenGui"); gui.Name = "GlacesNote"; gui.ResetOnSpawn = false; gui.DisplayOrder = 7; gui.Parent = player:WaitForChild("PlayerGui")
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -110); note.Size = UDim2.fromOffset(440, 40)
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0; note.Font = Enum.Font.FredokaOne; note.TextSize = 18
note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local shown = 0
local function say(text)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); shown = mine
	task.delay(3.2, function()
		if shown ~= mine then return end
		TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
	end)
end
local function shiver()                                  -- the camera shivers for half a second
	local t0 = os.clock()
	local name = "GlaceShiver"
	pcall(function() RunService:UnbindFromRenderStep(name) end)
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - t0
		if t > 0.6 then RunService:UnbindFromRenderStep(name) return end
		local a = 0.02 * (1 - t / 0.6)
		workspace.CurrentCamera.CFrame *= CFrame.Angles(math.sin(t * 90) * a, math.cos(t * 77) * a, 0)
	end)
end

-- ---- the lick: the arm brings the cone up to the mouth
-- Shannon: "can you make her put the icecream to her mouth when she eats it? right now she is just holding it and the
-- scoops disappear a little at a time." Every screen poses the licker's arm (the server tells everyone), the way the
-- cafe's sip does: the shoulder's, elbow's and wrist's Transform are written just before each physics step, on top of
-- the tool-holding pose (turning the joints' attachments does nothing on the client to this game's AnimationConstraint
-- avatars). The angles are found by trying them against the licker's own rig until the top scoop sits at the lips with
-- the cone upright, its top leaning in a little; they are kept per cone and scoop, so only the first lick of each scoop
-- searches. The shoulder can raise, swing in and TWIST the upper arm (a real arm brings a cone in to the mouth by
-- turning the upper arm, not by flinging it across the chest), and the search keeps the elbow down and the wrist and the
-- swing easy - the first go, without the twist, found the mouth with the arm across the chest and the wrist bent back
-- 100 degrees; the second, without turning the hand, held it at the lips leaning 45 degrees sideways. A rig without
-- those joints (R6) licks where it holds it. Tuning on workspace.Glaces: LipsDown (how far
-- down the head the lips are, in head heights), LipsOut (studs in front of the face), Lean (degrees). Testing:
-- LickDebug (reports the poses) and LickHold (keeps the cone at the mouth), set on the client.
local function jointInfo(j)
	if not j then return nil end
	if j:IsA("Motor6D") then return j.C0, j.C1, j.Transform end
	if j:IsA("AnimationConstraint") and j.Attachment0 and j.Attachment1 then return j.Attachment0.CFrame, j.Attachment1.CFrame, j.Transform end
	return nil
end
local function turnS(x, y) return CFrame.Angles(0, y, 0) * CFrame.Angles(x, 0, 0) end   -- the arm forward (x), then in (y)
local function turnY(a) return CFrame.Angles(0, a, 0) end                              -- the upper arm's twist
local function turnX(a) return CFrame.Angles(a, 0, 0) end                              -- elbow and wrist
local REST = {0, 0, 0, 0, 0, 0}
local licking = {}                                   -- character -> the lick going on
local cache = setmetatable({}, {__mode = "k"})       -- character -> the poses for its cone as it was
local function rig(char)
	local ua, la, hand = char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm"), char:FindFirstChild("RightHand")
	local r = {ut = char:FindFirstChild("UpperTorso"), head = char:FindFirstChild("Head"), hand = hand, s = ua and ua:FindFirstChild("RightShoulder"),
		e = la and la:FindFirstChild("RightElbow"), w = hand and hand:FindFirstChild("RightWrist"), gA = hand and hand:FindFirstChild("RightGripAttachment")}
	if not (r.ut and r.head and hand and r.gA and jointInfo(r.s) and jointInfo(r.e) and jointInfo(r.w)) then return nil end
	return r
end
-- the poses for the cone as it is now: MOUTH (the top scoop at the lips - or, with no scoop left, the rim, for the bite)
-- and LICK (the same a little higher: the tongue drawing up the scoop). Each is {raise, swing, twist, elbow, wrist, and
-- the hand's turn about the forearm}.
local function posesFor(char, tool, r, base)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return nil end
	local n, top, topY = 0, nil, nil
	for _, d in ipairs(tool:GetChildren()) do
		if d.Name == "Scoop" and d:IsA("BasePart") then
			n += 1
			local y = handle.CFrame:PointToObjectSpace(d.Position).Y
			if not topY or y > topY then top, topY = d, y end
		end
	end
	local c = cache[char]
	if c and c.tool == tool and c.n == n then return c.poses end
	local G = r.hand.CFrame * r.gA.CFrame
	local point = G:PointToObjectSpace(top and top.Position or handle.Position)   -- what goes to the lips, in the hand's grip
	local axis = G:VectorToObjectSpace(handle.CFrame.UpVector)                    -- the cone's axis, in the grip
	local s0, s1 = jointInfo(r.s); local e0, e1 = jointInfo(r.e); local w0, w1 = jointInfo(r.w)
	local A = r.ut.CFrame * s0
	local S1i = s1:Inverse()
	local sT = base[1]
	local E = base[2] * e1:Inverse() * w0
	local W = base[3] * w1:Inverse() * r.gA.CFrame
	local shoulderY = A.Position.Y
	local function arm(x, y, t, e, w, h)                -- the elbow's place and the grip, for these turns (radians)
		local elbow = A * turnS(x, y) * sT * turnY(t) * S1i * e0
		return elbow.Position, elbow * turnX(e) * E * turnY(h) * turnX(w) * W
	end
	local head = r.head
	local look, up = head.CFrame.LookVector, head.CFrame.UpVector
	local flat = Vector3.new(look.X, 0, look.Z); flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
	local lips = head.Position - up * (head.Size.Y * (F:GetAttribute("LipsDown") or 0.3) + 0.08) + look * (head.Size.Z * 0.5 + (F:GetAttribute("LipsOut") or 0.3))
	local lean = math.rad(F:GetAttribute("Lean") or 25)
	local want = Vector3.yAxis * math.cos(lean) - flat * math.sin(lean)         -- upright, the top leaning in a little
	-- an elbow folds one way only: whichever way lifts the hand
	local _, gUp = arm(0, 0, 0, math.rad(60), 0, 0)
	local _, gDown = arm(0, 0, 0, math.rad(-60), 0, 0)
	local flex = (gUp.Position.Y >= gDown.Position.Y) and 1 or -1
	local evals = 0
	local function cost(v, target, near)
		local ep, g = arm(math.rad(v[1]), math.rad(v[2]), math.rad(v[3]), math.rad(v[4] * flex), math.rad(v[5]), math.rad(v[6]))
		local ang = math.acos(math.clamp(g:VectorToWorldSpace(axis):Dot(want), -1, 1))
		local d = (g:PointToWorldSpace(point) - target).Magnitude + 0.5 * ang
		d += 1.0 * math.max(0, ep.Y - (shoulderY - 0.15))                             -- the elbow stays down
		d += 0.004 * (math.max(0, math.abs(v[5]) - 45) + math.max(0, v[2] - 40) + math.max(0, math.abs(v[6]) - 70))   -- all easy
		for i = 1, 6 do d += 0.0005 * math.abs(v[i] - near[i]) end                    -- and not far from where it was
		evals += 1
		if evals % 2500 == 0 then task.wait() end         -- a phone keeps its frame rate while it thinks
		return d
	end
	local function solve(target, near, sweep)
		local best = table.clone(near)
		local bestD = cost(best, target, near)
		local function try(v)
			v[4] = math.clamp(v[4], 0, 150); v[5] = math.clamp(v[5], -70, 70)
			local d = cost(v, target, near)
			if d < bestD then best, bestD = v, d; return true end
			return false
		end
		if sweep then
			for x = -100, 20, 20 do for y = -20, 40, 20 do for t = -90, 90, 30 do for b = 25, 150, 25 do for w = -60, 60, 30 do for h = -60, 60, 60 do
				try({x, y, t, b, w, h})
			end end end end end end
		end
		for _, s in ipairs({10, 5, 2.5}) do                -- then downhill, a joint at a time, in finer and finer steps
			local moved, guard = true, 0
			while moved and guard < 40 do
				moved, guard = false, guard + 1
				for i = 1, 6 do
					for _, dir in ipairs({s, -s}) do
						local v = table.clone(best); v[i] += dir
						if try(v) then moved = true end
					end
				end
			end
		end
		return best, bestD
	end
	local md = solve(lips, REST, true)
	local ld = solve(lips + up * 0.14, md, false)
	local function rad(d) return {math.rad(d[1]), math.rad(d[2]), math.rad(d[3]), math.rad(d[4] * flex), math.rad(d[5]), math.rad(d[6])} end
	local poses = {MOUTH = rad(md), LICK = rad(ld)}
	if F:GetAttribute("LickDebug") then
		local m = poses.MOUTH
		local ep, g = arm(m[1], m[2], m[3], m[4], m[5], m[6])
		warn(string.format("QQ LICKDBG - %d scoops | raise %.0f swing %.0f twist %.0f elbow %.0f wrist %.0f hand %.0f | the %s misses the lips by %.2f, cone %.0f deg off | elbow %.2f below the shoulder | %d tries",
			n, md[1], md[2], md[3], md[4], md[5], md[6], top and "scoop" or "rim", (g:PointToWorldSpace(point) - lips).Magnitude,
			math.deg(math.acos(math.clamp(g:VectorToWorldSpace(axis):Dot(want), -1, 1))), shoulderY - ep.Y, evals))
	end
	cache[char] = {tool = tool, n = n, poses = poses}
	return poses
end
local function lick(who, tool, bite)
	local char = typeof(who) == "Instance" and who:IsA("Player") and who.Character
	if not (char and typeof(tool) == "Instance" and tool.Parent == char) then return end
	local head, cam = char:FindFirstChild("Head"), workspace.CurrentCamera
	if not head or (cam and (head.Position - cam.CFrame.Position).Magnitude > 150) then return end   -- too far off to see
	local now = os.clock()
	local hold = bite and 0.4 or 0.62
	local L = licking[char]
	if L then                                            -- already up there: stay a little longer, and lick again
		L.tool = tool; L.upUntil = now + hold; L.lickAt = now + 0.3
		if not L.solving then
			L.solving = true
			task.spawn(function() local p = posesFor(char, tool, L.r, L.base); if p then L.poses = p end; L.solving = false end)
		end
		return
	end
	local r = rig(char)
	if F:GetAttribute("LickDebug") then warn("QQ LICKDBG - a lick for " .. who.Name .. (r and "" or " - no R15 arm joints, so no arm")) end
	if not r then return end
	local _, _, sT = jointInfo(r.s); local _, _, eT = jointInfo(r.e); local _, _, wT = jointInfo(r.w)
	L = {r = r, base = {sT, eT, wT}, cur = {0, 0, 0, 0, 0, 0}, tool = tool, upUntil = now + hold, lickAt = now + 0.3, solving = true}
	licking[char] = L
	local pose
	local ok, err = pcall(function()
		L.poses = posesFor(char, tool, r, L.base)
		L.solving = false
		if not L.poses then return end
		pose = RunService.Stepped:Connect(function()          -- after the animation, before the physics
			r.s.Transform = turnS(L.cur[1], L.cur[2]) * L.base[1] * turnY(L.cur[3])
			r.e.Transform = turnX(L.cur[4]) * L.base[2]
			r.w.Transform = turnY(L.cur[6]) * turnX(L.cur[5]) * L.base[3]
		end)
		while true do
			local dt = RunService.Heartbeat:Wait()
			if not (char.Parent and L.tool.Parent == char) then break end
			local t = os.clock()
			local target = REST
			if F:GetAttribute("LickHold") or t < L.upUntil then
				target = (t >= L.lickAt and t < L.lickAt + 0.16) and L.poses.LICK or L.poses.MOUTH
			end
			local k = math.min(1, dt * 12)
			local still = true
			for i = 1, 6 do
				L.cur[i] += (target[i] - L.cur[i]) * k
				if math.abs(target[i] - L.cur[i]) > 0.01 then still = false end
			end
			if target == REST and still then break end
		end
	end)
	if pose then pose:Disconnect() end
	r.s.Transform = L.base[1]; r.e.Transform = L.base[2]; r.w.Transform = L.base[3]   -- the arm as it was; the animation carries on
	licking[char] = nil
	if not ok then warn("GlaceClient: lick - " .. tostring(err)) end
end
ev.OnClientEvent:Connect(function(what, a, b, c)
	if what == "got" and type(a) == "table" then
		say(table.concat(a, " & ") .. "! Tap to lick.")
	elseif what == "freeze" then
		shiver()
		say("Brrr! Brain freeze!")
	elseif what == "lick" then
		task.spawn(lick, a, b, c)
	end
end)
]==]
	local s = Instance.new("Script"); s.Name = "GlaceServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "GlaceClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	local n = 0
	for _, d in ipairs(cart:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	return string.format("Glaces cart at %.1f,%.2f,%.1f facing %.2f,%.2f | ground %s | %d parts", at.X, at.Y, at.Z, face.X, face.Z,
		ground and (ground.Instance:GetFullName() .. " " .. ground.Material.Name) or "none", n)
end

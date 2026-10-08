local Players = game:GetService("Players")
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
local function brainFreeze(player, char, names)
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
	if passport then passport:Fire(player, "glace",{flavours=table.concat(names or {},", ")}) end
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
			brainFreeze(player, char, names)
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

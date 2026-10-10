-- opera/install_lights1 (job 68): EDIT mode, re-runnable. The opera spotlight: for the player who presses Listen, the world
-- dims and warm spotlights come up over the singer and the accordion player until the aria ends. workspace.OperaLights
-- (Folder; attributes to tune) + OperaLightsClient. Undo: delete workspace.OperaLights. Output "QQ OPERA".
if game:GetService("RunService"):IsRunning() then warn("QQ OPERA ABORT - Play mode") return end
local singer = workspace:FindFirstChild("operasinger_squirrel_color")
local prompt = singer and singer:FindFirstChild("OperaPrompt", true)
local nino = workspace:FindFirstChild("accordion_squirrel_color")
if not nino then for _, d in ipairs(workspace:GetChildren()) do if d:IsA("Model") and d.Name:lower():find("accordion", 1, true) and d.Name:lower():find("color", 1, true) then nino = d break end end end
local old = workspace:FindFirstChild("OperaLights"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "OperaLights"
F:SetAttribute("Singer", "operasinger_squirrel_color"); F:SetAttribute("Accordion", nino and nino.Name or "accordion_squirrel_color")
F:SetAttribute("PromptName", "OperaPrompt"); F:SetAttribute("SoundName", "OperaSong")
F:SetAttribute("SpotHeight", 9); F:SetAttribute("SpotAngle", 55); F:SetAttribute("SpotBrightness", 9); F:SetAttribute("BeamStrength", 0.14)
F:SetAttribute("DimBrightness", 0.28); F:SetAttribute("DimExposure", 0.7); F:SetAttribute("FadeDown", 1.6); F:SetAttribute("FadeUp", 2.2); F:SetAttribute("Reach", 45)
local c = Instance.new("Script"); c.Name = "OperaLightsClient"; c.RunContext = Enum.RunContext.Client; c.Source = [===[
-- OperaLightsClient (workspace.OperaLights, RunContext Client): Shannon, Oct 10 2026: "just for the player who presses the
-- button to hear the opera singer: for a moment dim the lights in the world and put a spotlight on her and the accordion
-- player until she finishes singing, then bring the lights up again". When THIS player triggers the singer's Listen prompt
-- (the OperaPrompt that PortoActivities makes), the world dims on this client only - a colour-correction fade and the
-- Lighting pulled down - and two warm spotlights with visible beams come on over the singer and Nino the accordion player.
-- They stay until the aria ends (the OperaSong sound stops), the player walks away or respawns; then the lights come up
-- again over a couple of seconds. Nothing is replicated; other players see nothing.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local F = script.Parent
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function str(name, d) local v = F:GetAttribute(name) return type(v) == "string" and v or d end

local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "OperaDim"; cc.Enabled = false; cc.Parent = Lighting
local WARM = Color3.fromRGB(255, 232, 190)
local on, gen = false, 0
local saved = nil
local rig = nil

local function findModel(name)
	local m = workspace:FindFirstChild(name)
	if m then return m end
	local key = name:lower():gsub("_squirrel_color", "")
	for _, d in ipairs(workspace:GetChildren()) do if d:IsA("Model") and d.Name:lower():find(key, 1, true) and d.Name:lower():find("color", 1, true) then return d end end
	return nil
end
local function spotOver(m, height)
	-- an invisible lamp high over the performer: a warm spotlight down, a soft visible beam, a pool of light on the ground
	local cf, size = m:GetBoundingBox()
	local top = cf.Position + Vector3.new(0, size.Y / 2 + height, 0)
	local foot = Vector3.new(cf.Position.X, cf.Position.Y - size.Y / 2 + 0.05, cf.Position.Z)
	local lamp = Instance.new("Part"); lamp.Name = "OperaLamp"; lamp.Anchored = true; lamp.CanCollide = false; lamp.CanQuery = false; lamp.CanTouch = false; lamp.Transparency = 1; lamp.Size = Vector3.new(0.4, 0.4, 0.4)
	lamp.CFrame = CFrame.new(top)
	local light = Instance.new("SpotLight"); light.Face = Enum.NormalId.Bottom; light.Angle = num("SpotAngle", 55); light.Range = height + size.Y + 6; light.Brightness = 0; light.Color = WARM; light.Shadows = true; light.Parent = lamp
	local a0 = Instance.new("Attachment"); a0.Parent = lamp; a0.WorldPosition = top     -- (parented first, then placed)
	local a1 = Instance.new("Attachment"); a1.Parent = lamp; a1.WorldPosition = foot
	local beam = Instance.new("Beam"); beam.Attachment0 = a0; beam.Attachment1 = a1; beam.Width0 = 0.5; beam.Width1 = math.max(size.X, size.Z) * 1.6 + 2
	beam.Color = ColorSequence.new(WARM); beam.LightEmission = 1; beam.LightInfluence = 0; beam.FaceCamera = true; beam.Segments = 1
	beam.Transparency = NumberSequence.new(1); beam.Parent = lamp
	local pool = Instance.new("Part"); pool.Name = "OperaPool"; pool.Anchored = true; pool.CanCollide = false; pool.CanQuery = false; pool.CanTouch = false; pool.CastShadow = false
	pool.Shape = Enum.PartType.Cylinder; pool.Size = Vector3.new(0.05, beam.Width1, beam.Width1); pool.CFrame = CFrame.new(foot + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pool.Material = Enum.Material.Neon; pool.Color = WARM; pool.Transparency = 1; pool.Parent = lamp
	lamp.Parent = workspace.CurrentCamera
	return {lamp = lamp, light = light, beam = beam, pool = pool}
end
local function setBeam(spot, k)   -- k 0..1: how much light
	spot.light.Brightness = num("SpotBrightness", 9) * k
	local bt = 1 - num("BeamStrength", 0.14) * k
	spot.beam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, bt), NumberSequenceKeypoint.new(1, math.min(1, bt + 0.08))})
	spot.pool.Transparency = 1 - 0.35 * k
end
local function lightsDown(singer, nino)
	if on then return end
	on = true; gen += 1
	saved = {Brightness = Lighting.Brightness, OutdoorAmbient = Lighting.OutdoorAmbient, Ambient = Lighting.Ambient, Exposure = Lighting.ExposureCompensation}
	local secs = num("FadeDown", 1.6)
	cc.Brightness = 0; cc.Contrast = 0; cc.Saturation = 0; cc.TintColor = Color3.new(1, 1, 1); cc.Enabled = true
	TweenService:Create(cc, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Brightness = -num("DimBrightness", 0.28), Saturation = -0.25, TintColor = Color3.fromRGB(205, 210, 240)}):Play()
	TweenService:Create(Lighting, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Brightness = math.min(Lighting.Brightness, 0.4), OutdoorAmbient = Color3.fromRGB(38, 40, 55), Ambient = Color3.fromRGB(30, 30, 42), ExposureCompensation = saved.Exposure - num("DimExposure", 0.7)}):Play()
	rig = {spots = {}}
	for _, m in ipairs({singer, nino}) do if m then table.insert(rig.spots, spotOver(m, num("SpotHeight", 9))) end end
	local my = gen
	task.spawn(function()   -- the spots come up as the house goes down
		local t0 = os.clock()
		while gen == my and rig do
			local k = math.min(1, (os.clock() - t0) / secs)
			for _, sp in ipairs(rig.spots) do setBeam(sp, k) end
			if k >= 1 then break end
			RunService.RenderStepped:Wait()
		end
	end)
end
local function lightsUp()
	if not on then return end
	on = false; gen += 1
	local secs = num("FadeUp", 2.2)
	TweenService:Create(cc, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Brightness = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1)}):Play()
	if saved then TweenService:Create(Lighting, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Brightness = saved.Brightness, OutdoorAmbient = saved.OutdoorAmbient, Ambient = saved.Ambient, ExposureCompensation = saved.Exposure}):Play() end
	local r = rig; rig = nil
	task.delay(secs + 0.1, function() if not on then cc.Enabled = false end end)
	if r then
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < secs do
				local k = 1 - (os.clock() - t0) / secs
				for _, sp in ipairs(r.spots) do if sp.lamp.Parent then setBeam(sp, k) end end
				RunService.RenderStepped:Wait()
			end
			for _, sp in ipairs(r.spots) do sp.lamp:Destroy() end
		end)
	end
end

PPS.PromptTriggered:Connect(function(prompt, who)
	if who ~= player or prompt.Name ~= str("PromptName", "OperaPrompt") then return end
	local singer = findModel(str("Singer", "operasinger_squirrel_color"))
	local nino = findModel(str("Accordion", "accordion_squirrel_color"))
	local sound = prompt.Parent and prompt.Parent:FindFirstChild(str("SoundName", "OperaSong"))
	if not (singer and sound) then return end
	lightsDown(singer, nino)
	local my = gen
	task.spawn(function()
		task.wait(0.5)   -- give the song a moment to start
		local quiet = 0
		while gen == my and on do
			if not sound.IsPlaying then quiet += 0.25 else quiet = 0 end
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local far = not root or (root.Position - singer:GetPivot().Position).Magnitude > num("Reach", 45)
			if quiet >= 1.5 or far then break end
			task.wait(0.25)
		end
		if gen == my then lightsUp() end
	end)
end)
player.CharacterAdded:Connect(function() if on then lightsUp() end end)
print("OperaLights: ready")
]===]; c.Parent = F
local f, err = loadstring(c.Source); if not f then warn("QQ OPERA ABORT - OperaLightsClient does not compile: " .. tostring(err)); F:Destroy(); return end
F.Parent = workspace
print(string.format("QQ OPERA DONE: workspace.OperaLights with OperaLightsClient (%d chars); singer %s (prompt %s); accordion player %s", #c.Source, singer and "found" or "NOT FOUND (operasinger_squirrel_color)", prompt and "found" or "not found yet (PortoActivities makes it at run time)", nino and nino:GetFullName() or "NOT FOUND - the spotlight will be on the singer only"))

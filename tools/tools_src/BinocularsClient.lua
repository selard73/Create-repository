local tool = script.Parent
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local touch = UIS.TouchEnabled and not UIS.MouseEnabled       -- a phone toggles; a mouse holds
local raise = workspace:WaitForChild("Binoculars"):WaitForChild("Raise")
local function cfg(name, default)
	local F = workspace:FindFirstChild("Binoculars")
	local v = F and F:GetAttribute(name)
	return v ~= nil and v or default
end

-- the mask: one wide oval of clear glass in a black field (the film-binocular shape), a seam and a fine ring
local gui = Instance.new("ScreenGui"); gui.Name = "BinocularMask"; gui.ResetOnSpawn = false; gui.DisplayOrder = 9
gui.IgnoreGuiInset = true; gui.Enabled = false; gui.Parent = player:WaitForChild("PlayerGui")
local eye = Instance.new("Frame"); eye.AnchorPoint = Vector2.new(0.5, 0.5); eye.Position = UDim2.fromScale(0.5, 0.5)
eye.BackgroundTransparency = 1; eye.Parent = gui
local ring = Instance.new("UIStroke"); ring.Color = C(0, 0, 0); ring.Thickness = 900; ring.Parent = eye
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = eye
local seam = Instance.new("Frame"); seam.AnchorPoint = Vector2.new(0.5, 0.5); seam.Position = UDim2.fromScale(0.5, 0.5)
seam.Size = UDim2.new(0, 3, 1, 0); seam.BackgroundColor3 = C(0, 0, 0); seam.BackgroundTransparency = 0.55; seam.BorderSizePixel = 0; seam.Parent = gui
local cross = Instance.new("Frame"); cross.AnchorPoint = Vector2.new(0.5, 0.5); cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.fromOffset(18, 18); cross.BackgroundTransparency = 1; cross.Parent = gui
local cs = Instance.new("UIStroke"); cs.Color = C(255, 120, 120); cs.Thickness = 1.5; cs.Transparency = 0.3; cs.Parent = cross
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = cross
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local d = math.min(vp.X * 0.62, vp.Y * 0.92)
	eye.Size = UDim2.fromOffset(d * 1.45, d)
end
fit()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

-- THE REVEAL. Every squirrel this player has not found, within RevealRange, gets a red Highlight drawn on top of
-- everything - so it shows through the tree it is hiding behind. Highlights made here exist on this client only.
-- "Not found" is the FoundIds attribute the server publishes for the hint shop; the colour model is the one
-- players see, the gray twin is skipped.
local glows = {}                                              -- model -> Highlight
local squirrels, scannedAt = {}, 0
local function idOf(m) return m:GetAttribute("SquirrelId") or (m.Name:lower():gsub("_color$", "")) end
local function scan()
	squirrels = {}
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and (m:GetAttribute("SquirrelId") or m.Name:lower():match("_color$")) and not m.Name:lower():find("gray") then
			table.insert(squirrels, m)
		end
	end
	scannedAt = os.clock()
end
local function foundSet()
	local s = {}
	for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do s[id] = true end
	return s
end
local function clearGlows()
	for m, hl in pairs(glows) do if hl then hl:Destroy() end end
	glows = {}
end
local function reveal()
	if os.clock() - scannedAt > 15 or #squirrels == 0 then scan() end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local found = foundSet()
	local range = cfg("RevealRange", 110)
	local keep = {}
	for _, m in ipairs(squirrels) do
		if m.Parent and not found[idOf(m)] then
			local d = (m:GetPivot().Position - root.Position).Magnitude
			if d <= range then
				keep[m] = true
				if not glows[m] then
					local hl = Instance.new("Highlight"); hl.Name = "BinoGlow"; hl.Adornee = m
					hl.FillColor = C(255, 60, 60); hl.FillTransparency = 0.3
					hl.OutlineColor = C(255, 150, 150); hl.OutlineTransparency = 0
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = m
					glows[m] = hl
				end
			end
		end
	end
	for m, hl in pairs(glows) do
		if not keep[m] then hl:Destroy(); glows[m] = nil end
	end
end

local zoomed = false
local savedFov, savedMode, savedSens, savedDist
local revealConn
local function setZoom(on)
	if on == zoomed then return end
	zoomed = on
	raise:FireServer(on)                                      -- the binoculars and the hands rise, for everyone
	local cam = workspace.CurrentCamera
	if not cam then return end
	local t = cfg("ZoomTime", 0.25)
	if on then
		savedFov, savedMode, savedSens = cam.FieldOfView, player.CameraMode, UIS.MouseDeltaSensitivity
		local head = player.Character and player.Character:FindFirstChild("Head")
		savedDist = head and (cam.CFrame.Position - head.Position).Magnitude or nil
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		UIS.MouseDeltaSensitivity = cfg("ZoomSensitivity", 0.3)
		gui.Enabled = true; fit()
		TweenService:Create(cam, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = cfg("ZoomFov", 18)}):Play()
		local id = tonumber(cfg("ZoomSoundId", 0)) or 0
		if id > 0 then
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = cfg("ZoomVolume", 0.6)
			s.Parent = game:GetService("SoundService"); s:Play(); Debris:AddItem(s, 6)
		end
		reveal()
		revealConn = task.spawn(function()
			while zoomed do task.wait(0.4); if zoomed then reveal() end end
		end)
	else
		gui.Enabled = false
		TweenService:Create(cam, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = savedFov or 70}):Play()
		player.CameraMode = savedMode or Enum.CameraMode.Classic
		UIS.MouseDeltaSensitivity = savedSens or 1
		clearGlows()
		-- leaving first person does not bring the camera back out by itself (measured: it stayed 0.6 from the
		-- head), so the minimum zoom is raised to where the camera was for a moment, which pushes it back there
		if savedDist and savedDist > 1.5 then
			local minWas = player.CameraMinZoomDistance
			local pushed = math.min(savedDist, player.CameraMaxZoomDistance)
			player.CameraMinZoomDistance = pushed
			task.delay(0.15, function() if player.CameraMinZoomDistance == pushed then player.CameraMinZoomDistance = minWas end end)
		end
	end
end

-- YOUR OWN BINOCULARS ARE INVISIBLE TO YOU while you look through them (the mask stands in for them) and whenever
-- the camera is right at your face, or they would fill the screen. Everyone else sees them.
local parts = {}
for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then table.insert(parts, p) end end
local function setHidden(h) for _, p in ipairs(parts) do p.LocalTransparencyModifier = h and 1 or 0 end end
local hideConn
tool.Equipped:Connect(function()
	if hideConn then hideConn:Disconnect() end
	hideConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local head = player.Character and player.Character:FindFirstChild("Head")
		setHidden(zoomed or (cam ~= nil and head ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.8))
	end)
end)
tool.Unequipped:Connect(function()
	if hideConn then hideConn:Disconnect(); hideConn = nil end
	setHidden(false)
end)

tool.Activated:Connect(function()
	if touch then setZoom(not zoomed) else setZoom(true) end
end)
tool.Deactivated:Connect(function()
	if not touch then setZoom(false) end
end)
tool.Unequipped:Connect(function() setZoom(false) end)
tool.AncestryChanged:Connect(function() if not tool:IsDescendantOf(game) then setZoom(false) end end)
-- a squirrel found while looking loses its glow at once
player:GetAttributeChangedSignal("FoundIds"):Connect(function() if zoomed then reveal() end end)

-- BoatInviteClient priority2: the 44th French squirrel opens this invitation immediately
-- above other game windows. A five-second boat view follows; only Take the boat moves the player.
-- Returning players with all 44 and no Italy arrival also receive the invitation once per visit.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = F:WaitForChild("BoatInviteEvent")
local MAPS = {"forest", "village", "domaine"}
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function found() local n = 0; for _, m in ipairs(MAPS) do n += tonumber(player:GetAttribute("Found_" .. m)) or 0 end; return n end
local function reachedItaly() return (tonumber(player:GetAttribute("Item_porto")) or 0) >= 1 end
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP, DIM = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18), C(200, 190, 210)
local FONT = Enum.Font.FredokaOne
local phone = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end

local gui = Instance.new("ScreenGui"); gui.Name = "BoatInviteGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 20000; gui.Enabled = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = pg
local shield = Instance.new("TextButton"); shield.Name = "ModalShield"; shield.Size = UDim2.fromScale(1, 1); shield.Text = ""; shield.AutoButtonColor = false; shield.BackgroundColor3 = Color3.new(); shield.BackgroundTransparency = 0.65; shield.BorderSizePixel = 0; shield.Modal = true; shield.Parent = gui
local W, H = 320, 168
local card = Instance.new("Frame"); card.Name = "Card"; card.ZIndex = 2; card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 110)   -- (phone: under the HUD row, ending at 246, above the tool hotbar)
card.Size = UDim2.fromOffset(W, H); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui; corner(card, 16)
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(t, size, colour, y, h)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(16, y); l.Size = UDim2.fromOffset(W - 32, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = card
	return l
end
text("All 44 found!", 22, CREAM, 10, 28)
text("The boat to Italy is waiting at the river dock.", 15, GOLD, 44, 44)
local go = Instance.new("TextButton"); go.Name = "TakeBoat"; go.AnchorPoint = Vector2.new(0.5, 0); go.Position = UDim2.new(0.5, 0, 0, 98); go.Size = UDim2.fromOffset(170, 38)
go.BackgroundColor3 = GOLD; go.BorderSizePixel = 0; go.Font = FONT; go.TextSize = 18; go.TextColor3 = DEEP; go.Text = "Take the boat"; go.AutoButtonColor = true; go.Parent = card; corner(go, 12)
local later = Instance.new("TextButton"); later.Name = "Later"; later.AnchorPoint = Vector2.new(0.5, 1); later.Position = UDim2.new(0.5, 0, 1, -4); later.Size = UDim2.fromOffset(120, 24)
later.BackgroundTransparency = 1; later.Font = FONT; later.TextSize = 15; later.TextColor3 = DIM; later.Text = "Later"; later.Parent = card

-- Shannon: the 44th find takes priority immediately, even with another window open.
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local dismissed, shown, previewRequested = false, false, false
local cameraState, cameraTween, savedGuis, cineToken = nil, nil, {}, 0
local function fitCard()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local scale = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", card)
	scale.Scale = math.min(1, (vp.X - 24) / W, (vp.Y - 100) / H)
	if cameraState then
		if vp.X > vp.Y then
			card.AnchorPoint = Vector2.new(1, 0.5); card.Position = UDim2.new(1, -18, 0.5, 0)
		else
			card.AnchorPoint = Vector2.new(0.5, 1); card.Position = UDim2.new(0.5, 0, 1, -82)
		end
	else
		card.AnchorPoint = Vector2.new(0.5, 0)
		card.Position = UDim2.new(0.5, 0, 0, math.min(phone and 78 or 110, math.max(60, vp.Y - H - 80)))
	end
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCard) end
fitCard()
local function restoreCamera()
	cineToken += 1
	if cameraTween then cameraTween:Cancel(); cameraTween = nil end
	Run:UnbindFromRenderStep("BoatInvitePreview")
	CAS:UnbindAction("BoatInviteMovement")
	local s = cameraState
	cameraState = nil
	if s and s.camera.Parent then
		s.camera.CFrame = s.cf; s.camera.Focus = s.focus; s.camera.FieldOfView = s.fov
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		s.camera.CameraSubject = hum or s.subject
		s.camera.CameraType = s.kind
	end
	for g, wasEnabled in pairs(savedGuis) do if g.Parent then g.Enabled = wasEnabled end end
	table.clear(savedGuis)
	shield.BackgroundTransparency = 0.65
	gui:SetAttribute("CameraPreviewActive", false)
	fitCard()
end
local function hush(g)
	if cameraState and g:IsA("ScreenGui") and g ~= gui and savedGuis[g] == nil then
		savedGuis[g] = g.Enabled
		g.Enabled = false
	end
end
pg.ChildAdded:Connect(hush)
local function cameraPreview(boatPosition)
	if not gui.Enabled or cameraState or typeof(boatPosition) ~= "Vector3" then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	cameraState = {camera=cam, cf=cam.CFrame, focus=cam.Focus, fov=cam.FieldOfView, subject=cam.CameraSubject, kind=cam.CameraType}
	cineToken += 1
	local token = cineToken
	for _, g in ipairs(pg:GetChildren()) do hush(g) end
	local root = char:FindFirstChild("HumanoidRootPart")
	CAS:BindActionAtPriority("BoatInviteMovement", function() return Enum.ContextActionResult.Sink end, false, 3000, unpack(Enum.PlayerActions:GetEnumItems()))
	local target = boatPosition + Vector3.new(0, 0.8, 0)
	local view = CFrame.lookAt(target + Vector3.new(-11, 10, 15), target)
	-- Leave clear screen space for the invitation beside/below the boat.
	if cam.ViewportSize.X > cam.ViewportSize.Y then view = view * CFrame.new(4, 0, 0)
	else view = view * CFrame.new(0, -3, 0) end
	local value = Instance.new("CFrameValue"); value.Value = cam.CFrame
	cam.CameraType = Enum.CameraType.Scriptable
	Run:BindToRenderStep("BoatInvitePreview", Enum.RenderPriority.Last.Value + 20, function()
		cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = value.Value; cam.Focus = CFrame.new(target)
		cam.FieldOfView = 55
		if hum.Parent then hum:Move(Vector3.zero, false) end
		for g in pairs(savedGuis) do if g.Parent and g.Enabled then g.Enabled = false end end
	end)
	shield.BackgroundTransparency = 1
	gui:SetAttribute("CameraPreviewActive", true)
	fitCard()
	cameraTween = Tween:Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value=view})
	cameraTween:Play()
	task.delay(4.4, function()
		if token ~= cineToken then value:Destroy(); return end
		cameraTween = Tween:Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value=cameraState.cf})
		cameraTween:Play()
		task.delay(0.6, function()
			if token == cineToken then restoreCamera() end
			value:Destroy()
		end)
	end)
end
local function close()
	dismissed = true
	gui.Enabled = false
	restoreCamera()
	if pg:GetAttribute("OpenPanel") == "boat" then pg:SetAttribute("OpenPanel", nil) end
end
later.Activated:Connect(close)
go.Activated:Connect(function() close(); ev:FireServer("go") end)
-- Other panels may close themselves normally, but none can dismiss this invitation.
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
	if gui.Enabled and pg:GetAttribute("OpenPanel") ~= "boat" then
		task.defer(function() if gui.Enabled then pg:SetAttribute("OpenPanel", "boat") end end)
	end
end)
ev.OnClientEvent:Connect(function(what, position)
	if what == "preview" and previewRequested and gui.Enabled then cameraPreview(position) end
end)
player.CharacterRemoving:Connect(restoreCamera)
local function show()
	if shown or dismissed or F:GetAttribute("Enabled") == false then return end
	shown = true; gui.Enabled = true
	pg:SetAttribute("OpenPanel", "boat")
	previewRequested = true
	ev:FireServer("preview")
end
local function check()
	if dismissed or shown or player:GetAttribute("SaveLoaded") ~= true then return end
	if found() >= num("Need", 44) and not reachedItaly() then show() end
end
for _, name in ipairs({"Found_forest", "Found_village", "Found_domaine", "SaveLoaded", "Item_porto"}) do
	player:GetAttributeChangedSignal(name):Connect(check)
end
F:GetAttributeChangedSignal("Enabled"):Connect(check)
-- Catches returning eligible players and any ordering of profile/count replication.
task.defer(check)
print("BoatInviteClient: priority invitation and five-second boat view ready")

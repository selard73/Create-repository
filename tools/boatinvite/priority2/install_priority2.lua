-- Install after mechanical play-test verification; Shannon authorized this workflow Oct18/19.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or BOATINVITE2_ALLOW_EDIT==true,"Installation authorization required")
local F=workspace.BoatInvite
local hud=workspace.HudBarUI.HudBarClient
local function norm(s)return (s:gsub("\r\n","\n"))end
local clientOld=[====[-- BoatInviteClient (workspace.BoatInvite, RunContext Client): the "to the boat" card (Shannon, Oct 11 2026). When the player
-- finds the last of the 44 French squirrels, a few seconds after the reveal: "All 44 found! The boat to Italy is waiting at
-- the river dock" with "Take the boat" (one click: the fade, the jetty, aboard, off down the river) and "Later". It shows again
-- once per visit, a little after joining, until the player has reached Italy (Item_porto). Same look as the daily card.
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

local gui = Instance.new("ScreenGui"); gui.Name = "BoatInviteGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Enabled = false; gui.Parent = pg   -- (100: on top of everything until it is closed, the interact pills at 30 included - Shannon's rule for the gifts card)
local W, H = 320, 168
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 110)   -- (phone: under the HUD row, ending at 246, above the tool hotbar)
card.Size = UDim2.fromOffset(W, H); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui; corner(card, 16)
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(t, size, colour, y, h)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(16, y); l.Size = UDim2.fromOffset(W - 32, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = card
	return l
end
text("All 44 found!", 22, CREAM, 10, 28)
text("The boat to Italy is waiting at the river dock.", 15, GOLD, 44, 44)
local go = Instance.new("TextButton"); go.AnchorPoint = Vector2.new(0.5, 0); go.Position = UDim2.new(0.5, 0, 0, 98); go.Size = UDim2.fromOffset(170, 38)
go.BackgroundColor3 = GOLD; go.BorderSizePixel = 0; go.Font = FONT; go.TextSize = 18; go.TextColor3 = DEEP; go.Text = "Take the boat"; go.AutoButtonColor = true; go.Parent = card; corner(go, 12)
local later = Instance.new("TextButton"); later.AnchorPoint = Vector2.new(0.5, 1); later.Position = UDim2.new(0.5, 0, 1, -4); later.Size = UDim2.fromOffset(120, 24)
later.BackgroundTransparency = 1; later.Font = FONT; later.TextSize = 15; later.TextColor3 = DIM; later.Text = "Later"; later.Parent = card

local shown = false
local function setOpen(on)
	gui.Enabled = on
	if on then pg:SetAttribute("OpenPanel", "boat")
	elseif pg:GetAttribute("OpenPanel") == "boat" then pg:SetAttribute("OpenPanel", nil) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if gui.Enabled and pg:GetAttribute("OpenPanel") ~= "boat" then gui.Enabled = false end end)
later.Activated:Connect(function() setOpen(false) end)
go.Activated:Connect(function() setOpen(false); ev:FireServer("go") end)

-- a clear moment: nothing else open, the squirrel's reveal card closed, not riding anything, still in France
local function clear()
	if pg:GetAttribute("OpenPanel") ~= nil then return false end
	local sh = pg:FindFirstChild("SquirrelHUD"); local cardUp = sh and sh:FindFirstChild("Card")
	if cardUp and cardUp:IsA("GuiObject") and cardUp.Visible then return false end
	local daily = pg:FindFirstChild("DailyGui"); local dcard = daily and daily:FindFirstChild("DailyCard")
	if daily and daily.Enabled and dcard and dcard.Visible then return false end
	local char = player.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 or hum.SeatPart then return false end
	return root.Position.Z > -300                                -- (south of z -300 is Porto Nocciola)
end
local function offer(waitFor, within)
	if shown or F:GetAttribute("Enabled") == false then return end
	task.wait(waitFor)
	local t0 = os.clock()
	while os.clock() - t0 < within do
		if shown or reachedItaly() or found() < num("Need", 44) then return end
		if clear() then shown = true; setOpen(true); return end
		task.wait(1)
	end
end

-- the moment the last French squirrel is found this visit
local before = found()
for _, m in ipairs(MAPS) do
	player:GetAttributeChangedSignal("Found_" .. m):Connect(function()
		local now = found()
		if before < num("Need", 44) and now >= num("Need", 44) and player:GetAttribute("SaveLoaded") then task.spawn(offer, num("RevealDelay", 6), 120) end
		before = now
	end)
end
-- a visit that starts with all 44 found and Italy not reached yet
task.spawn(function()
	local t0 = os.clock()
	while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 60 do task.wait(0.5) end
	before = found()
	if before >= num("Need", 44) and not reachedItaly() then offer(num("JoinDelay", 25), 180) end
end)
print("BoatInviteClient: ready")
]====]
local clientNew=[====[-- BoatInviteClient priority2: the 44th French squirrel opens this invitation immediately
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
]====]
local serverOld=[====[-- BoatInviteServer (workspace.BoatInvite): the one-click trip to the boat (Shannon, Oct 11 2026: "when the player finds the
-- last squirrel on the France map, we need a way to get their character to the dock where the boat is in a non awkward way";
-- "they should be able to take the boat with one click"). The card (BoatInviteClient) sends "go"; this checks the player has
-- found all 44 French squirrels, fades their screen with the luggage cart's fade (workspace.Travel.TravelEvent), puts them on
-- the jetty facing the moored boat, and fires ReplicatedStorage.BoatTake, which BoatServer answers by boarding them exactly
-- as its own jetty prompt does (the parachute is packed for everyone who has found all 44).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local ev = F:WaitForChild("BoatInviteEvent")
local MAPS = {"forest", "village", "domaine"}
local function need() local v = F:GetAttribute("Need"); return type(v) == "number" and v or 44 end
local function found(p) local n = 0; for _, m in ipairs(MAPS) do n += tonumber(p:GetAttribute("Found_" .. m)) or 0 end; return n end
local busy, last = {}, {}

local function travelEvent() local t = workspace:FindFirstChild("Travel"); return t and t:FindFirstChild("TravelEvent") end
local function note(p, text) local tev = travelEvent(); if tev then tev:FireClient(p, "note", text) end end

-- the jetty deck (x 160.4..163.9) beside the moored boat, found by a ray down; facing the boat
local function jettySpot()
	local River = workspace:FindFirstChild("River")
	local preview = River and River:FindFirstChild("BoatPreview")
	local visual = preview and preview:FindFirstChildWhichIsA("MeshPart", true)
	if not visual then return nil end
	local x, z = 162.2, math.clamp(visual.Position.Z + 3, -164, -148)   -- (a little up the deck from the boat: clear of the BATEAUX sign at -166..-168.5)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
	local skip = {preview}
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
	local boat = workspace:FindFirstChild("Boat"); if boat then table.insert(skip, boat) end
	rp.FilterDescendantsInstances = skip
	local top                                                    -- the highest of three rays (one may fall between two planks onto a stringer)
	for _, dz in ipairs({0, 0.45, -0.45}) do
		local hit = workspace:Raycast(Vector3.new(x, visual.Position.Y + 10, z + dz), Vector3.new(0, -25, 0), rp)   -- (from low: no tree or bridge above counts)
		if hit and (not top or hit.Position.Y > top) then top = hit.Position.Y end
	end
	top = top or visual.Position.Y + 2
	if top > visual.Position.Y + 8 or top < visual.Position.Y - 4 then top = visual.Position.Y + 2 end
	local pos = Vector3.new(x, top + 3.2, z)
	return CFrame.lookAt(pos, Vector3.new(visual.Position.X, pos.Y, visual.Position.Z))
end

ev.OnServerEvent:Connect(function(p, what)
	if what ~= "go" or busy[p] or os.clock() - (last[p] or 0) < 8 then return end
	if found(p) < need() and p.UserId ~= game.CreatorId then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 then return end
	if hum.SeatPart then note(p, "Hop off first, then the boat is yours.") return end
	local take = RS:FindFirstChild("BoatTake")
	local cf = jettySpot()
	if not (take and take:IsA("BindableEvent") and cf) then note(p, "The boat is at the river dock, by the bridge.") return end
	busy[p] = true; last[p] = os.clock()
	local tev = travelEvent()
	if tev then tev:FireClient(p, "fade", F:GetAttribute("Place") or "The River Dock") end
	task.wait(0.45)                                              -- the screen is dark before anything moves (as the luggage cart)
	if char.Parent and root.Parent and hum.Health > 0 then
		pcall(function() p:RequestStreamAroundAsync(cf.Position, 3) end)
		root.AssemblyLinearVelocity = Vector3.zero
		char:PivotTo(cf)
		task.wait(0.25)
		take:Fire(p)                                             -- BoatServer boards them (its own checks: all 44, a free slot)
		print(string.format("BoatInvite: %s -> the boat", p.Name))
	end
	if tev then tev:FireClient(p, "arrived") end
	task.delay(2, function() busy[p] = nil end)
end)
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; last[p] = nil end)
print("BoatInviteServer: ready")
]====]
local serverNew=[====[-- BoatInviteServer (workspace.BoatInvite): the one-click trip to the boat (Shannon, Oct 11 2026: "when the player finds the
-- last squirrel on the France map, we need a way to get their character to the dock where the boat is in a non awkward way";
-- "they should be able to take the boat with one click"). The card (BoatInviteClient) sends "go"; this checks the player has
-- found all 44 French squirrels, fades their screen with the luggage cart's fade (workspace.Travel.TravelEvent), puts them on
-- the jetty facing the moored boat, and fires ReplicatedStorage.BoatTake, which BoatServer answers by boarding them exactly
-- as its own jetty prompt does (the parachute is packed for everyone who has found all 44).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local ev = F:WaitForChild("BoatInviteEvent")
local MAPS = {"forest", "village", "domaine"}
local function need() local v = F:GetAttribute("Need"); return type(v) == "number" and v or 44 end
local function found(p) local n = 0; for _, m in ipairs(MAPS) do n += tonumber(p:GetAttribute("Found_" .. m)) or 0 end; return n end
local busy, last = {}, {}

local function travelEvent() local t = workspace:FindFirstChild("Travel"); return t and t:FindFirstChild("TravelEvent") end
local function note(p, text) local tev = travelEvent(); if tev then tev:FireClient(p, "note", text) end end

-- the jetty deck (x 160.4..163.9) beside the moored boat, found by a ray down; facing the boat
local function jettySpot()
	local River = workspace:FindFirstChild("River")
	local preview = River and River:FindFirstChild("BoatPreview")
	local visual = preview and preview:FindFirstChildWhichIsA("MeshPart", true)
	if not visual then return nil end
	local x, z = 162.2, math.clamp(visual.Position.Z + 3, -164, -148)   -- (a little up the deck from the boat: clear of the BATEAUX sign at -166..-168.5)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
	local skip = {preview}
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
	local boat = workspace:FindFirstChild("Boat"); if boat then table.insert(skip, boat) end
	rp.FilterDescendantsInstances = skip
	local top                                                    -- the highest of three rays (one may fall between two planks onto a stringer)
	for _, dz in ipairs({0, 0.45, -0.45}) do
		local hit = workspace:Raycast(Vector3.new(x, visual.Position.Y + 10, z + dz), Vector3.new(0, -25, 0), rp)   -- (from low: no tree or bridge above counts)
		if hit and (not top or hit.Position.Y > top) then top = hit.Position.Y end
	end
	top = top or visual.Position.Y + 2
	if top > visual.Position.Y + 8 or top < visual.Position.Y - 4 then top = visual.Position.Y + 2 end
	local pos = Vector3.new(x, top + 3.2, z)
	return CFrame.lookAt(pos, Vector3.new(visual.Position.X, pos.Y, visual.Position.Z))
end

local previewLast = {}
ev.OnServerEvent:Connect(function(p, what)
	if what == "preview" then
		if p:GetAttribute("SaveLoaded") ~= true or found(p) < need() or F:GetAttribute("Enabled") == false then return end
		local now = os.clock()
		if previewLast[p] and now - previewLast[p] < 10 then return end
		previewLast[p] = now
		local river = workspace:FindFirstChild("River")
		local model = river and river:FindFirstChild("BoatPreview")
		local visual = model and model:FindFirstChild("Boat")
		if not (visual and visual:IsA("BasePart")) then return end
		local position = visual.Position
		-- Load scenery only; the player is not moved until they choose Take the boat.
		pcall(function() p:RequestStreamAroundAsync(position, 3) end)
		if p.Parent == Players then ev:FireClient(p, "preview", position) end
		return
	end
	if what ~= "go" or busy[p] or os.clock() - (last[p] or 0) < 8 then return end
	if found(p) < need() and p.UserId ~= game.CreatorId then return end
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Health <= 0 then return end
	if hum.SeatPart then note(p, "Hop off first, then the boat is yours.") return end
	local take = RS:FindFirstChild("BoatTake")
	local cf = jettySpot()
	if not (take and take:IsA("BindableEvent") and cf) then note(p, "The boat is at the river dock, by the bridge.") return end
	busy[p] = true; last[p] = os.clock()
	local tev = travelEvent()
	if tev then tev:FireClient(p, "fade", F:GetAttribute("Place") or "The River Dock") end
	task.wait(0.45)                                              -- the screen is dark before anything moves (as the luggage cart)
	if char.Parent and root.Parent and hum.Health > 0 then
		pcall(function() p:RequestStreamAroundAsync(cf.Position, 3) end)
		root.AssemblyLinearVelocity = Vector3.zero
		char:PivotTo(cf)
		task.wait(0.25)
		take:Fire(p)                                             -- BoatServer boards them (its own checks: all 44, a free slot)
		print(string.format("BoatInvite: %s -> the boat", p.Name))
	end
	if tev then tev:FireClient(p, "arrived") end
	task.delay(2, function() busy[p] = nil end)
end)
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; last[p] = nil; previewLast[p] = nil end)
print("BoatInviteServer: ready")
]====]
local hudOld=norm(hud.Source)
local a="\thudPanel = p\n"
local b="\thudPanel = p\n\t-- Release only our own modal claim when this panel is hidden.\n\tp:GetPropertyChangedSignal(\"Visible\"):Connect(function()\n\t\tif not p.Visible and pg:GetAttribute(\"OpenPanel\") == \"collection\" then pg:SetAttribute(\"OpenPanel\", nil) end\n\tend)\n"
local a2="map.BorderSizePixel = 0; map.Visible = false; map.Parent = gui\n"
local b2=a2.."map:GetPropertyChangedSignal(\"Visible\"):Connect(function()\n\tif not map.Visible and pg:GetAttribute(\"OpenPanel\") == \"map\" then pg:SetAttribute(\"OpenPanel\", nil) end\nend)\n"
local function replaceOnce(s,old,new)
 local i,j=s:find(old,1,true);assert(i and not s:find(old,j+1,true),"HUD patch anchor not unique");return s:sub(1,i-1)..new..s:sub(j+1)
end
assert(not F:GetAttribute("PriorityInviteVersion"),"Already installed; inspect")
assert(norm(F.BoatInviteClient.Source)==norm(clientOld),"Boat client changed")
assert(norm(F.BoatInviteServer.Source)==norm(serverOld),"Boat server changed")
local hudNew=replaceOnce(replaceOnce(hudOld,a,b),a2,b2)
local backup=Instance.new("Folder");backup.Name="BoatInvitePriority2"
local hb=game.ServerStorage.HudBackup;assert(not hb:FindFirstChild(backup.Name),"Backup exists")
local rows={{F.BoatInviteClient,clientNew},{F.BoatInviteServer,serverNew},{hud,hudNew}}
for _,row in ipairs(rows)do local c=row[1]:Clone();c:SetAttribute("OriginalPath",row[1]:GetFullName());c.Parent=backup end
backup.Parent=hb
local ok,err=pcall(function()
 for _,row in ipairs(rows)do row[1].Source=row[2] end
 F:SetAttribute("PriorityInviteVersion","priority2")
 for _,row in ipairs(rows)do assert(norm(row[1].Source)==norm(row[2]),"Source readback mismatch")end
end)
if not ok then for _,row in ipairs(rows)do row[1].Source=backup[row[1].Name].Source end F:SetAttribute("PriorityInviteVersion",nil) error(err)end
print("QQ BOAT INVITE PRIORITY2: 44th find opens immediately above all other game windows; five-second boat camera; Take the boat boards via existing validated travel")
print("QQ BOAT INVITE PRIORITY2: late profile load and returning eligible players covered; map/collection stale flags released; originals backed up")
print("QQ BOAT INVITE PRIORITY2 STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")

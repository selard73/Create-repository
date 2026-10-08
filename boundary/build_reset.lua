-- Reset progress: a small "Reset progress" link low on the screen. Clicking it opens an "Are you sure?" panel; only the
-- second click wipes this player's saved finds (DataStore, attributes, titles) and turns every squirrel gray again.
-- It patches the live SquirrelSetup (server) and SquirrelAnim (client) to add the reset, then installs the button.
-- Run in edit mode: require(workspace.Reset.PatchModule)()  (packed by village/make_patch.py)
return function()
	local old = workspace:FindFirstChild("ResetUI"); if old then old:Destroy() end
	local scripts = workspace:WaitForChild("SquirrelScripts")
	local report = {}

	-- ---------------------------------------------------------------- 1. the server side of the wipe ----
	local setup = scripts:WaitForChild("SquirrelSetup")
	if not setup.Source:find("SquirrelReset", 1, true) then
		setup.Source = setup.Source .. [==[

-- ---- reset: wipe this player's finds on request (the "Reset progress" button asks twice before sending it) ----
local resetEv = ReplicatedStorage:FindFirstChild("SquirrelReset") or Instance.new("RemoteEvent")
resetEv.Name = "SquirrelReset"; resetEv.Parent = ReplicatedStorage
local resetAt = {}
resetEv.OnServerEvent:Connect(function(player)
	local uid = player.UserId
	if os.clock() - (resetAt[uid] or -60) < 5 then return end          -- one wipe at a time
	resetAt[uid] = os.clock()
	found[uid] = {}
	dirty[uid] = nil
	if store and canSave[uid] then
		local ok, err = pcall(function()
			store:UpdateAsync("u" .. uid, function() return {found = {}, updated = os.time()} end)   -- a true wipe, not a merge
		end)
		if not ok then warn("SquirrelSetup: reset save failed for " .. player.Name .. ": " .. tostring(err)) end
	end
	player:SetAttribute("SquirrelsFound", 0)
	publishCounts(player)
	resetEv:FireClient(player)
	print("SquirrelSetup: " .. player.Name .. " reset their progress")
end)
]==]
		table.insert(report, "server reset added")
	end

	-- ---------------------------------------------------------------- 2. the client turns everything back to gray ----
	local anim = scripts:WaitForChild("SquirrelAnim")
	if not anim.Source:find("SquirrelReset", 1, true) then
		anim.Source = anim.Source .. [==[

-- ---- reset: the server wiped this player's finds, so put every squirrel back to gray and rebuild the HUD ----
do
	local resetEv = ReplicatedStorage:WaitForChild("SquirrelReset", 30)
	if resetEv then
		resetEv.OnClientEvent:Connect(function()
			for id in pairs(foundIds) do foundIds[id] = nil end
			for model, st in pairs(squirrels) do
				st.found = false
				if st.driftDown and st.home then          -- back into the air, chute still packed
					st.mesh.CFrame = st.home
					st.landed = false; st.dr = nil
				end
				local gray = st.mesh and st.mesh:GetAttribute("GrayTexture")
				if gray then setTex(st.mesh, gray) end
				if setCompanion then setCompanion(model, false) end
			end
			for model in pairs(badges) do badges[model] = nil end
			if hud then hud:Destroy() end
			hud, grid, counter = nil, nil, nil
			ensureHud(); ensureBadges(); updateCounter()
		end)
	end
end
]==]
		table.insert(report, "client reset added")
	end

	-- ---------------------------------------------------------------- 3. the button ----
	local F = Instance.new("Folder"); F.Name = "ResetUI"; F.Parent = workspace
	local CLIENT = [==[
-- ResetButton: a quiet "Reset progress" link; the first click opens a confirmation, only the second click wipes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local ev = ReplicatedStorage:WaitForChild("SquirrelReset", 60)
local gui = Instance.new("ScreenGui"); gui.Name = "ResetGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 8; gui.Parent = player:WaitForChild("PlayerGui")

-- the quiet link, bottom left
local link = Instance.new("TextButton"); link.Name = "ResetLink"; link.Size = UDim2.new(0, 132, 0, 26); link.Position = UDim2.new(0, 12, 1, -36)
link.BackgroundColor3 = C(28, 22, 38); link.BackgroundTransparency = 0.55; link.BorderSizePixel = 0; link.AutoButtonColor = false
link.Font = Enum.Font.FredokaOne; link.TextSize = 13; link.TextColor3 = C(210, 200, 220); link.TextTransparency = 0.25; link.Text = "Reset progress"; link.Parent = gui
local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 13); lc.Parent = link
-- A readable 128 x 44 touch target, below the resting stick when it fits.
-- If the stick leaves too little space, use the adjacent lower-left space.
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local function fitResetLink()
 local camera=workspace.CurrentCamera;if not camera then return false end
 local vp=camera.ViewportSize
 local mobile=UIS.TouchEnabled or vp.Y<500
 link.Size=UDim2.fromOffset(mobile and 128 or 132,44)
 link.TextSize=14;link.TextTransparency=0
 local x,y=12,vp.Y-52
 local tg=player.PlayerGui:FindFirstChild("TouchGui")
 local stick=tg and (tg:FindFirstChild("ThumbstickFrame",true) or tg:FindFirstChild("ThumbstickStart",true))
 if mobile and stick and stick:IsA("GuiObject") and stick.AbsoluteSize.Y>0 then
  local sg=stick:FindFirstAncestorOfClass("ScreenGui")
  local inset=(sg and not sg.IgnoreGuiInset) and GuiService:GetGuiInset().Y or 0
  local pos,size=stick.AbsolutePosition,stick.AbsoluteSize
  x=math.max(8,pos.X+size.X/2-64)
  if pos.Y+inset+size.Y+8>y then x=pos.X+size.X+12 end
 end
 link.Position=UDim2.fromOffset(math.clamp(x,8,math.max(8,vp.X-136)),y)
 return stick~=nil or not mobile
end
fitResetLink()
task.spawn(function()
 local t0=os.clock()
 while not fitResetLink() and os.clock()-t0<30 do task.wait(.5)end
end)

link.MouseEnter:Connect(function() TweenService:Create(link, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, TextTransparency = 0}):Play() end)
link.MouseLeave:Connect(function() TweenService:Create(link, TweenInfo.new(0.25), {BackgroundTransparency = 0.55, TextTransparency = 0}):Play() end)

-- the confirmation
local shade = Instance.new("TextButton"); shade.Name = "Shade"; shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(0, 0, 0); shade.BackgroundTransparency = 0.45
shade.BorderSizePixel = 0; shade.Text = ""; shade.AutoButtonColor = false; shade.Visible = false; shade.ZIndex = 20; shade.Parent = gui
local box = Instance.new("Frame"); box.Size = UDim2.new(0, 460, 0, 250); box.Position = UDim2.new(0.5, -230, 0.5, -125); box.BackgroundColor3 = C(38, 30, 52)
box.BorderSizePixel = 0; box.ZIndex = 21; box.Parent = shade
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = box
local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 2; bs.Parent = box
local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -40, 0, 44); title.Position = UDim2.new(0, 20, 0, 18); title.BackgroundTransparency = 1
title.Font = Enum.Font.Antique; title.TextSize = 34; title.TextColor3 = C(255, 214, 90); title.Text = "Are you sure?"; title.ZIndex = 22; title.Parent = box
local body = Instance.new("TextLabel"); body.Name = "Body"; body.Size = UDim2.new(1, -44, 0, 92); body.Position = UDim2.new(0, 22, 0, 62); body.BackgroundTransparency = 1
body.Font = Enum.Font.FredokaOne; body.TextSize = 17; body.TextWrapped = true; body.TextColor3 = C(255, 246, 220); body.ZIndex = 22; body.Parent = box
local function mkButton(name, text, x, fill, ink)
	local b = Instance.new("TextButton"); b.Name = name; b.Size = UDim2.new(0, 190, 0, 46); b.Position = UDim2.new(0, x, 1, -62); b.BackgroundColor3 = fill
	b.BorderSizePixel = 0; b.Font = Enum.Font.FredokaOne; b.TextSize = 19; b.TextColor3 = ink; b.Text = text; b.ZIndex = 22; b.Parent = box
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 23); c.Parent = b
	return b
end
local keep = mkButton("Keep", "Keep my squirrels", 20, C(70, 60, 90), C(255, 246, 220))
local wipe = mkButton("Wipe", "Reset squirrels", 250, C(196, 58, 58), C(255, 250, 244))
local function fitReset()
 fitResetLink()
 local vp=workspace.CurrentCamera.ViewportSize
 local width=math.min(460,vp.X-24)
 box.AnchorPoint=Vector2.new(.5,.5);box.Position=UDim2.fromScale(.5,.5);box.Size=UDim2.fromOffset(width,250)
 local buttonWidth=(width-52)/2
 keep.Position=UDim2.new(0,20,1,-62);keep.Size=UDim2.fromOffset(buttonWidth,46)
 wipe.Position=UDim2.new(1,-20-buttonWidth,1,-62);wipe.Size=UDim2.fromOffset(buttonWidth,46)
 keep.TextSize=width<400 and 14 or 17;wipe.TextSize=keep.TextSize
 title.TextSize=width<400 and 28 or 34;body.TextSize=width<400 and 15 or 17
end
fitReset()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()task.delay(.5,fitReset)end)
local function refreshBody()
	local n = player:GetAttribute("SquirrelsFound") or 0
	body.Text = string.format("Reset all %d squirrel%s you have found? Your acorns, purchases and Passport stamps stay. Your squirrel finds start at zero. This cannot be undone.", n, n == 1 and "" or "s")
end
local function close() shade.Visible = false; gui.DisplayOrder = 8 end
link.Activated:Connect(function() refreshBody(); gui.DisplayOrder = 100; shade.Visible = true end)
keep.Activated:Connect(close)
shade.Activated:Connect(close)
wipe.Activated:Connect(function()
	wipe.Text = "Resetting..."; wipe.AutoButtonColor = false
	if ev then ev:FireServer() end
	task.delay(1.5, function() wipe.Text = "Reset squirrels"; wipe.AutoButtonColor = true; close() end)
end)
if ev then
	ev.OnClientEvent:Connect(function()
		local done = Instance.new("TextLabel"); done.Size = UDim2.new(0, 420, 0, 54); done.Position = UDim2.new(0.5, -210, 0.24, 0); done.BackgroundColor3 = C(38, 30, 52)
		done.BackgroundTransparency = 0.15; done.Font = Enum.Font.FredokaOne; done.TextSize = 20; done.TextColor3 = C(255, 246, 220)
		done.Text = "Progress reset. Every squirrel is hidden again!"; done.ZIndex = 25; done.Parent = gui
		local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 14); dc.Parent = done
		task.delay(4, function() done:Destroy() end)
	end)
end
]==]
	local s = Instance.new("Script"); s.Name = "ResetClient"; s.RunContext = Enum.RunContext.Client; s.Source = CLIENT; s.Parent = F
	table.insert(report, "button installed")
	print("Reset: " .. table.concat(report, ", "))
end

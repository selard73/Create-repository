-- FindReveal: finding a new squirrel now takes over the screen for a moment. A gold starburst opens behind the
-- middle of the screen, the squirrel turns there large and lit, its name comes up under it, sparks scatter - and then
-- the whole thing shrinks and flies into the acorn icon in the corner, which gives a little bounce as it lands. That
-- last part is the point: it shows the player, without a word, where the one they just found has gone.
-- It never blocks anything: nothing in it takes input, and it clears itself up whether or not the tween finishes.
-- Run in edit mode: require(workspace.FindReveal.PatchModule)()  (packed by village/make_patch.py)
return function()
	local anim = workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelAnim")
	local src = anim.Source
	if src:find("screenReveal", 1, true) then
		print("FindReveal: already installed")
		return
	end

	local BLOCK = [==[
-- ---- the reveal that takes over the screen: starburst, the squirrel large, its name, then away into the menu ----
local revealGui
local function screenReveal(model, st)
	if revealGui then revealGui:Destroy(); revealGui = nil end
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	local cam0 = workspace.CurrentCamera
	local vpSize = cam0 and cam0.ViewportSize or Vector2.new(1280, 720)
	local S = math.min(vpSize.X, vpSize.Y)

	local gui = Instance.new("ScreenGui")
	gui.Name = "SquirrelReveal"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 9
	gui.Parent = pg
	revealGui = gui
	game:GetService("Debris"):AddItem(gui, 8)   -- a backstop: the overlay can never be left on screen

	-- everything lives in one square holder, so the flight to the menu is a single tween of this frame
	local hold = Instance.new("Frame"); hold.Name = "Hold"; hold.AnchorPoint = Vector2.new(0.5, 0.5)
	hold.Position = UDim2.fromScale(0.5, 0.46); hold.Size = UDim2.fromOffset(S * 0.5, S * 0.5)
	hold.BackgroundTransparency = 1; hold.Parent = gui
	local scale = Instance.new("UIScale"); scale.Scale = 0.55; scale.Parent = hold

	-- ---- the light behind: rings of gold fading outward, and a wheel of rays turning slowly ----
	local burst = Instance.new("Frame"); burst.Name = "Burst"; burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.fromScale(0.5, 0.5); burst.Size = UDim2.fromScale(1, 1)
	burst.BackgroundTransparency = 1; burst.ZIndex = 2; burst.Parent = hold
	for i, band in ipairs({{0.52, 0.3}, {0.68, 0.62}, {0.86, 0.82}, {1.06, 0.92}}) do
		local r = Instance.new("Frame"); r.AnchorPoint = Vector2.new(0.5, 0.5); r.Position = UDim2.fromScale(0.5, 0.5)
		r.Size = UDim2.fromScale(band[1], band[1]); r.BackgroundColor3 = GOLD; r.BackgroundTransparency = band[2]
		r.BorderSizePixel = 0; r.ZIndex = 2; r.Parent = burst
		corner(r, UDim.new(1, 0))
	end
	local rays = Instance.new("Frame"); rays.Name = "Rays"; rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5); rays.Size = UDim2.fromScale(1, 1); rays.BackgroundTransparency = 1
	rays.ZIndex = 3; rays.Parent = burst
	for i = 1, 12 do
		local ray = Instance.new("Frame"); ray.AnchorPoint = Vector2.new(0.5, 1)
		ray.Position = UDim2.fromScale(0.5, 0.5); ray.Size = UDim2.new(0.035, 0, 0.62, 0)
		ray.Rotation = (i - 1) * 30; ray.BackgroundColor3 = RGB(255, 236, 170); ray.BorderSizePixel = 0
		ray.ZIndex = 3; ray.Parent = rays
		gradient(ray, RGB(255, 245, 205), RGB(255, 210, 90), 90).Transparency =
			NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.45)})
	end

	-- ---- the squirrel, turning ----
	local frame = Instance.new("Frame"); frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.82, 0.82); frame.BackgroundTransparency = 1; frame.ZIndex = 5; frame.Parent = hold
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = RGB(188, 186, 196); vp.LightColor = RGB(255, 251, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.5)
	vp.ZIndex = 5; vp.Parent = frame
	local copy = st.mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local tex = st.mesh:GetAttribute("ColorTexture"); if tex then setTex(copy, tex) end
	copy.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView = 28; cam.Parent = vp; vp.CurrentCamera = cam
	local centre, dist = copy.Position, copy.Size.Magnitude * 1.45
	local fwd = copy.CFrame:VectorToWorldSpace(st.fwdL or Vector3.new(0, 0, 1))
	local ang = math.atan2(fwd.X, fwd.Z)

	-- ---- the name ----
	local name = Instance.new("TextLabel"); name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.fromScale(0.5, 0.86); name.Size = UDim2.new(1.5, 0, 0.16, 0)
	name.BackgroundTransparency = 1; name.Text = prettyName(model); name.TextScaled = true
	name.FontFace = FONT; name.TextColor3 = RGB(255, 250, 232); name.ZIndex = 7; name.Parent = hold
	local nsc = Instance.new("UITextSizeConstraint"); nsc.MaxTextSize = math.floor(S * 0.075); nsc.Parent = name
	local nst = stroke(name, RGB(74, 44, 18), math.max(2, S * 0.005), 0)
	nst.LineJoinMode = Enum.LineJoinMode.Round

	-- ---- sparks thrown outward ----
	for i = 1, 16 do
		local a = (i / 16) * math.pi * 2 + math.random() * 0.3
		local d = Instance.new("Frame"); d.AnchorPoint = Vector2.new(0.5, 0.5); d.Position = UDim2.fromScale(0.5, 0.5)
		local px = math.random(6, 13) / 1000 * S
		d.Size = UDim2.fromOffset(px, px); d.BackgroundColor3 = RGB(255, 236, 158); d.BorderSizePixel = 0
		d.ZIndex = 8; d.Parent = hold
		corner(d, UDim.new(1, 0))
		local far = 0.5 + (0.42 + math.random() * 0.3)
		TweenService:Create(d, TweenInfo.new(0.62 + math.random() * 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = UDim2.fromScale(0.5 + math.cos(a) * (far - 0.5) * 2, 0.5 + math.sin(a) * (far - 0.5) * 2),
			 BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2)}):Play()
	end

	-- ---- in, turn, then away into the acorn icon ----
	TweenService:Create(scale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	-- exactly one revolution over the hold, eased in and out, finishing back where it started - which is face-on,
	-- because ang was taken from the squirrel's own forward vector. Then it holds that pose for the flight.
	local HOLD = 2.2
	local spin, t = nil, 0
	spin = RunService.RenderStepped:Connect(function(dt)
		if not gui.Parent then spin:Disconnect() return end
		t = math.min(t + dt, HOLD)
		local k = t / HOLD
		local turn = (k * k * (3 - 2 * k)) * math.pi * 2
		rays.Rotation += dt * 9
		cam.CFrame = CFrame.lookAt(centre + Vector3.new(math.sin(ang + turn), 0.2, math.cos(ang + turn)) * dist, centre)
	end)

	local function menuIcon()                       -- the acorn in the HUD bar, if it is up
		local bar = pg:FindFirstChild("HudBar")
		local row = bar and bar:FindFirstChild("Bar")
		if not row then return nil end
		for _, c in ipairs(row:GetChildren()) do
			if c:IsA("TextButton") and c.LayoutOrder == 1 then return c end
		end
		return nil
	end

	task.delay(HOLD, function()                     -- it leaves the moment the turn is complete
		if not gui.Parent then return end
		local icon = menuIcon()                     -- only to know the acorn is up; it is never touched
		-- the acorn sits in the top-right corner on every screen, so aim there by fraction: AbsolutePosition is
		-- reported in the inset-adjusted space and would send the squirrel sailing over the top of the screen
		local flight = TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		TweenService:Create(hold, flight, {Position = UDim2.fromScale(0.955, 0.052)}):Play()
		TweenService:Create(scale, flight, {Scale = 0.1}):Play()
		local fade = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, d in ipairs(hold:GetDescendants()) do
			if d:IsA("ViewportFrame") then TweenService:Create(d, flight, {ImageTransparency = 1}):Play()
			elseif d:IsA("TextLabel") then TweenService:Create(d, fade, {TextTransparency = 1}):Play()
			elseif d:IsA("UIStroke") then TweenService:Create(d, fade, {Transparency = 1}):Play()
			elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
				TweenService:Create(d, fade, {BackgroundTransparency = 1}):Play()
			end
		end
		task.delay(1.1, function()
			if spin then spin:Disconnect() end
			if gui then gui:Destroy() end
			if revealGui == gui then revealGui = nil end
		end)
	end)
end
]==]

	-- put it in just above reveal(), which is where it is called from
	local anchor = "local function reveal(model, st)"
	local i = src:find(anchor, 1, true)
	assert(i, "FindReveal: could not find reveal() in SquirrelAnim")
	src = src:sub(1, i - 1) .. BLOCK .. "\n" .. src:sub(i)

	-- and call it as the squirrel turns to colour
	local callAnchor = "\ttask.delay(0.6, function() fillBadge(model, st) end)"
	local j = src:find(callAnchor, 1, true)
	assert(j, "FindReveal: could not find the fillBadge line in reveal()")
	src = src:sub(1, j - 1) .. "\tscreenReveal(model, st)\n" .. src:sub(j)

	anim.Source = src
	print("FindReveal: installed - the reveal now plays on screen and flies into the acorn icon")
end

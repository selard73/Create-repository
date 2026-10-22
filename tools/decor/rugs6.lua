-- rugs6 (Oct 21 2026): the first-climb tutorial restyled on Shannon's live notes in a play-test preview:
--   the note: "should not be so small and at the bottom of the screen, it should be bigger and briefly in the middle",
--     with new words ("something cute and witty, something about the squirrels, and hint that you can decorate as you
--     like") -> a big centred card, "Welcome home!" / "The squirrels have opinions about your floor... Open your Passport
--     and decorate it however you like!", gone after 6 s or as soon as a panel opens; above the prompt pills.
--   the Passport button: its whole box breathes gold behind its picture (word dark while it does), little firework
--     sparks around it every breath, a tiny 4-degree wiggle every other breath, a short green neon arrow pointing at it.
--   the Treehouse tab (and the Place buttons): fill breathing between two greens with a deep-gold border, same word size.
--   Tried and turned down on the way: a ring outside the button, a 12-degree wiggle, a word that grew, fading to white,
--   rings inside the edge, a round light, a thin two-stroke arrow over the tab.
-- Run in Studio EDIT. Backs TreehouseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local tc = workspace.Treehouse.TreehouseClient
local src = tc.Source
assert(not src:find("rugs6", 1, true), "TreehouseClient already patched")
local function swap(old, new, what)
	local a, b = src:find(old, 1, true)
	assert(a, "TreehouseClient: " .. what .. " not found - nothing changed")
	assert(not src:find(old, b + 1, true), "TreehouseClient: " .. what .. " found twice - nothing changed")
	src = src:sub(1, a - 1) .. new .. src:sub(b + 1)
end
-- 1. the two helpers (say + glowOn, rugs4) become the rugs6 set: say, glowOn, sparks, arrowAt
local a = src:find("\tlocal function say(txt, secs)\n", 1, true)
local b = src:find("\tlocal function passportButton()", 1, true)
assert(a and b and b > a, "TreehouseClient: helper block not found - nothing changed")
assert(not src:find("\tlocal function say(txt, secs)\n", a + 1, true), "TreehouseClient: say found twice - nothing changed")
local helpers = [==[
	-- (rugs6) the note: a big card that pops up in the MIDDLE of the screen for a few seconds, then shrinks away.
	-- It sits above the prompt pills (PromptTouch, 30) while it shows, and bows out early once any panel opens.
	local function say(title, body, secs)
		local old = pg:FindFirstChild("DecorTut"); if old then old:Destroy() end
		local tg = Instance.new("ScreenGui"); tg.Name = "DecorTut"; tg.ResetOnSpawn = false; tg.DisplayOrder = 31; tg.Parent = pg
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local small = vp.Y < 500                                          -- phones: the same card in smaller type
		local card = Instance.new("Frame"); card.Name = "Card"; card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.45)
		card.Size = UDim2.fromOffset(math.min(small and 420 or 540, vp.X - 48), 0); card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = NAVY; card.BackgroundTransparency = 0; card.Parent = tg
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 22); cc.Parent = card
		local cs = Instance.new("UIStroke"); cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; cs.Color = GOLD; cs.Thickness = 3; cs.Parent = card
		local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, small and 12 or 18); pad.PaddingBottom = UDim.new(0, small and 14 or 20)
		pad.PaddingLeft = UDim.new(0, 20); pad.PaddingRight = UDim.new(0, 20); pad.Parent = card
		local list = Instance.new("UIListLayout"); list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.Padding = UDim.new(0, small and 4 or 8)
		list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = card
		local function line(txt, size, colour, order)
			local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 0); l.AutomaticSize = Enum.AutomaticSize.Y; l.BackgroundTransparency = 1
			l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.TextWrapped = true; l.Text = txt; l.LayoutOrder = order; l.Parent = card
			return l
		end
		local t = line(title, small and 26 or 36, GOLD, 1)
		local b = body and line(body, small and 17 or 21, CREAM, 2)
		local sc = Instance.new("UIScale"); sc.Scale = 0.3; sc.Parent = card
		TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		local gone, con = false, nil
		local function away()
			if gone or not tg.Parent then return end
			gone = true
			if con then con:Disconnect() end
			local out = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(sc, out, {Scale = 0.7}):Play()
			TweenService:Create(card, out, {BackgroundTransparency = 1}):Play()
			TweenService:Create(cs, out, {Transparency = 1}):Play()
			TweenService:Create(t, out, {TextTransparency = 1}):Play()
			if b then TweenService:Create(b, out, {TextTransparency = 1}):Play() end
			Debris:AddItem(tg, 0.4)
		end
		task.delay(secs or 5, away)
		con = pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
			if pg:GetAttribute("OpenPanel") ~= nil then away() end
		end)
	end
	-- (rugs6) the glow, in each thing's OWN look and inside its own edges (Shannon, after a ring that spilled onto the
	-- row below, a word that jumped in size and a 12-degree wiggle: "that looks TERRIBLE"):
	--   a word button (the Treehouse tab, the Place buttons): a green layer INSIDE the button, under its own little
	--   pictures, breathing between two greens, with a gold border and a copy of its word at the same size. The button
	--   itself is never touched, so when the glow ends the Passport's own colours (selected or not) are as it left them.
	--   a picture button (the Passport): its whole box breathes gold, sparks, and - wiggle - a tiny 4-degree wiggle
	--   every other breath. A UIScale on a HUD button pushes the column, so nothing is ever scaled.
	local DEEP_GOLD = C(222, 158, 30)
	-- a word button: green breathing between two shades, a deep-gold border, its word in cream (hers: "maybe it
	-- should be green with a gold border")
	local FILL_LIGHT, FILL_DARK, FILL_WORD = C(104, 164, 72), C(70, 124, 48), C(255, 246, 220)
	-- (rugs6) little firework sparks: a burst of short gold streaks flying out from all round the thing and fading,
	-- drawn on a layer of their own just above it (so its wiggle never carries them)
	local SPARK_COLOURS = {GOLD, CREAM, DEEP_GOLD}
	local BOX_LIGHT, BOX_DARK, BOX_INK = C(240, 192, 76), C(214, 148, 26), C(84, 40, 10)   -- the Passport button's gold box
	local function sparks(obj)
		local host = obj:FindFirstAncestorOfClass("ScreenGui")
		local sg = Instance.new("ScreenGui"); sg.Name = "DecorTutSparks"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = false
		sg.DisplayOrder = (host and host.DisplayOrder or 6) + 1
		local c = obj.AbsolutePosition + obj.AbsoluteSize / 2
		local half = math.max(obj.AbsoluteSize.X, obj.AbsoluteSize.Y) / 2
		local n = 10
		local spin = math.random() * 360
		for i = 1, n do
			local ang = math.rad(spin + i * 360 / n + math.random(-8, 8))
			local dir = Vector2.new(math.cos(ang), math.sin(ang))
			local from, to = c + dir * (half + 1), c + dir * (half + 9 + math.random(0, 6))
			local s = Instance.new("Frame"); s.AnchorPoint = Vector2.new(0.5, 0.5); s.BorderSizePixel = 0
			s.Size = UDim2.fromOffset(2, 6); s.Rotation = math.deg(ang) + 90; s.Position = UDim2.fromOffset(from.X, from.Y)
			s.BackgroundColor3 = SPARK_COLOURS[math.random(1, #SPARK_COLOURS)]; s.Parent = sg
			local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = s
			local fly = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(s, fly, {Position = UDim2.fromOffset(to.X, to.Y), Size = UDim2.fromOffset(2, 2)}):Play()
			TweenService:Create(s, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		end
		sg.Parent = pg
		Debris:AddItem(sg, 0.7)
	end
	local function glowOn(obj, wiggle)
		local live = {}                                                   -- the latest tween per object + property
		local function tw(o, secs, goal, style)
			local t = TweenService:Create(o, TweenInfo.new(secs, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
			live[o] = live[o] or {}
			for prop in pairs(goal) do live[o][prop] = t end
			t:Play(); return t
		end
		local rot0 = obj.Rotation
		local made                                                        -- the one thing added to obj; removed at the end
		local lifted                                                      -- children raised above the glow, to put back
		local inked                                                       -- words darkened on the gold, to put back
		local pulse                                                       -- function(on): one breath in or out
		if obj:IsA("TextButton") and obj.Text ~= "" then
			local lowest = obj.ZIndex
			for _, c in ipairs(obj:GetChildren()) do if c:IsA("GuiObject") then lowest = math.min(lowest, c.ZIndex) end end
			local fill = Instance.new("Frame"); fill.Name = "DecorTutGlow"; fill.Size = UDim2.fromScale(1, 1); fill.BorderSizePixel = 0
			fill.BackgroundColor3 = FILL_LIGHT; fill.BackgroundTransparency = 1; fill.ZIndex = lowest - 1   -- under its pictures
			local oc = obj:FindFirstChildOfClass("UICorner")
			if oc then local fc = oc:Clone(); fc.Parent = fill end
			local edge = Instance.new("UIStroke"); edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; edge.Color = DEEP_GOLD
			edge.Thickness = 2; edge.Transparency = 1; edge.Parent = fill
			local word = Instance.new("TextLabel"); word.Size = UDim2.fromScale(1, 1); word.BackgroundTransparency = 1
			word.Font = obj.Font; word.TextSize = obj.TextSize; word.TextColor3 = FILL_WORD; word.Text = obj.Text
			word.TextXAlignment = obj.TextXAlignment; word.TextYAlignment = obj.TextYAlignment; word.TextTransparency = 1
			word.ZIndex = fill.ZIndex; word.Parent = fill
			local op = obj:FindFirstChildOfClass("UIPadding")
			if op then local wp = op:Clone(); wp.Parent = word end
			fill.Parent = obj
			made = fill
			tw(fill, 0.3, {BackgroundTransparency = 0}); tw(word, 0.3, {TextTransparency = 0}); tw(edge, 0.3, {Transparency = 0})
			pulse = function(on)                                            -- (hers: "it should not go complete white, it
				tw(fill, 0.8, {BackgroundColor3 = on and FILL_DARK or FILL_LIGHT})   -- should just get darker and less dark")
			end
		else
			-- a picture button: its whole box fills with gold behind its picture and word, corners and all, breathing
			-- between a lighter and a darker gold like the tab (hers: "make the glowy from inside the icon"; a circle of
			-- light left "the outside of the icon box still brown"), its word dark for the while so it still reads; and
			-- little firework sparks popping out around it on every breath ("the sparks look fine")
			local fill = Instance.new("Frame"); fill.Name = "DecorTutGlow"; fill.Size = UDim2.fromScale(1, 1); fill.BorderSizePixel = 0
			fill.BackgroundColor3 = BOX_LIGHT; fill.BackgroundTransparency = 1; fill.ZIndex = obj.ZIndex
			local oc = obj:FindFirstChildOfClass("UICorner")
			if oc then local fc = oc:Clone(); fc.Parent = fill end
			inked = {}
			for _, c in ipairs(obj:GetChildren()) do
				if c:IsA("TextLabel") and c.Visible and c.Text ~= "" then inked[c] = c.TextColor3; tw(c, 0.3, {TextColor3 = BOX_INK}) end
			end
			lifted = {}                                                     -- its picture and word stay on top of the glow
			for _, c in ipairs(obj:GetChildren()) do
				if c:IsA("GuiObject") and c.ZIndex <= obj.ZIndex then lifted[c] = c.ZIndex; c.ZIndex = obj.ZIndex + 1 end
			end
			fill.Parent = obj
			made = fill
			tw(fill, 0.3, {BackgroundTransparency = 0})
			pulse = function(on)
				tw(fill, 0.8, {BackgroundColor3 = on and BOX_DARK or BOX_LIGHT})
				if on then sparks(obj) end
			end
		end
		local alive = true
		local handle = {}
		function handle:Destroy()                                         -- stops at once, everything as it was
			if not alive then return end
			alive = false
			for _, props in pairs(live) do for _, t in pairs(props) do t:Cancel() end end
			obj.Rotation = rot0
			for c, z in pairs(lifted or {}) do c.ZIndex = z end
			for c, col in pairs(inked or {}) do c.TextColor3 = col end
			made:Destroy()
		end
		local function on() return alive and made.Parent ~= nil end
		local beat = 0
		task.spawn(function()
			while on() do
				beat += 1
				pulse(true); task.wait(0.8)
				if not on() then break end
				if wiggle and beat % 2 == 0 then                          -- the tiny wiggle, every other breath
					for _, r in ipairs({4, -4, 2}) do
						if not on() then break end
						tw(obj, 0.09, {Rotation = rot0 + r}); task.wait(0.09)
					end
					if not on() then break end
					tw(obj, 0.09, {Rotation = rot0}); task.wait(0.09)
				end
				if not on() then break end
				pulse(false); task.wait(0.8)
			end
			if alive then handle:Destroy() end                            -- the thing itself went away: tidy up anyway
		end)
		return handle
	end
	-- (rugs6) a green neon arrow at the Passport button (hers: "a green neon arrow pointing to it? maybe with a shorter
	-- tail"): the question board's curve with only its last part kept, drawn as ONE neon tube in three layers - a darker
	-- green edge, the board's neon green, a pale hot core - so it reads as neon without see-through glow pieces (her
	-- board note: "little splotchy sections"; the thin two-stroke tab arrow "looks bad"). dir = the way it points;
	-- mirror flips the side the tail curls to. It bobs gently, backing off from the button, never onto it; it follows
	-- the button if the layout moves and hides while the button is hidden.
	local NEON_LAYERS = {{9, C(24, 150, 62)}, {5.5, C(45, 230, 88)}, {2, C(205, 255, 215)}}
	local function arrowAt(obj, dir, mirror)
		local host = obj:FindFirstAncestorOfClass("ScreenGui")
		local ag = Instance.new("ScreenGui"); ag.Name = "DecorTutArrow"; ag.ResetOnSpawn = false
		ag.IgnoreGuiInset = false                                         -- AbsolutePosition is measured below the top bar
		ag.DisplayOrder = (host and host.DisplayOrder or 6) + 1
		local holder = Instance.new("Frame"); holder.Size = UDim2.fromScale(1, 1); holder.BackgroundTransparency = 1; holder.Parent = ag
		local cam = workspace.CurrentCamera
		local k = (cam ~= nil and cam.ViewportSize.Y < 500) and 0.8 or 1  -- phones: a little smaller
		local SIZE = 80 * k
		local P0, P1, P2 = Vector2.new(0.9, 0.3), Vector2.new(0.64, 0.24), Vector2.new(0.4, 0.72)   -- the board arrow's curve
		local function at(s) local w = 1 - s; return P0 * (w * w) + P1 * (2 * w * s) + P2 * (s * s) end
		local function tangent(s) local d = (P1 - P0) * (2 * (1 - s)) + (P2 - P1) * (2 * s); return d.Unit end
		local function turn(v, deg)
			local r = math.rad(deg)
			return Vector2.new(v.X * math.cos(r) - v.Y * math.sin(r), v.X * math.sin(r) + v.Y * math.cos(r))
		end
		local e = tangent(1)
		local tip = P2 + e * 0.02
		local shaft = {}
		for i = 0, 10 do shaft[#shaft + 1] = at(0.4 + 0.6 * i / 10) end  -- the short tail: the last 60 % of the curve
		shaft[#shaft + 1] = tip
		local head = {tip + turn(-e, 40) * 0.2, tip, tip + turn(-e, -40) * 0.2}
		local du = dir.Unit
		local spin = math.deg(math.atan2(du.Y, du.X) - math.atan2(e.Y, e.X))
		local function place(pts)
			local out = {}
			for i, p in ipairs(pts) do
				local q = turn((p - tip) * SIZE, spin)
				if mirror then q = du * (2 * q:Dot(du)) - q end
				out[i] = q
			end
			return out
		end
		local shapes = {place(shaft), place(head)}
		local paths = {}
		for z, layer in ipairs(NEON_LAYERS) do
			for _, pts in ipairs(shapes) do
				local path = Instance.new("Path2D"); path.Color3 = layer[2]; path.Thickness = layer[1] * k; path.ZIndex = z
				path.Parent = holder
				table.insert(paths, {path = path, pts = pts})
			end
		end
		ag.Parent = pg
		local last
		local function shown()
			if not (host and host.Enabled and obj:IsDescendantOf(host)) then return false end
			local o = obj
			while o and o ~= host do
				if o:IsA("GuiObject") and not o.Visible then return false end
				o = o.Parent
			end
			return obj.AbsoluteSize.X > 0
		end
		local t0 = os.clock()
		local conn = game:GetService("RunService").RenderStepped:Connect(function()
			local vis = shown()
			holder.Visible = vis
			if not vis then return end
			local c = obj.AbsolutePosition + obj.AbsoluteSize / 2               -- the tip just outside its edge, facing it
			local hx, hy = obj.AbsoluteSize.X / 2, obj.AbsoluteSize.Y / 2
			local reach = math.min(du.X ~= 0 and hx / math.abs(du.X) or math.huge, du.Y ~= 0 and hy / math.abs(du.Y) or math.huge)
			local anchor = c - du * (reach + 8 * k)
			if not last or (anchor - last).Magnitude > 0.5 then
				last = anchor
				for _, it in ipairs(paths) do
					local cps = {}
					for i, q in ipairs(it.pts) do cps[i] = Path2DControlPoint.new(UDim2.fromOffset(anchor.X + q.X, anchor.Y + q.Y)) end
					it.path:SetControlPoints(cps)
				end
			end
			local b = 3 + 3 * math.sin((os.clock() - t0) * 3.4)               -- the bob: 0..6 px back from the button
			holder.Position = UDim2.fromOffset(-du.X * b, -du.Y * b)
		end)
		local handle = {}
		function handle:Destroy() conn:Disconnect(); ag:Destroy() end
		return handle
	end
]==]
src = src:sub(1, a - 1) .. helpers .. src:sub(b)
-- 2. step 1: the new note, and the Passport button's glow + wiggle + arrow
swap([=[		say("Welcome home! You can decorate this place - open your Passport.", 10)
		local pb = passportButton()
		local g1 = pb and glowOn(pb)
		local opened = waitFor(function() return pg:GetAttribute("OpenPanel") == "passport" end, 120)
		if g1 then g1:Destroy() end]=],
[=[		say("Welcome home!", "The squirrels have opinions about your floor...\nOpen your Passport and decorate it however you like!", 6)
		local pb = passportButton()
		local g1 = pb and glowOn(pb, true)                                 -- (rugs6) gold box, sparks, tiny wiggle
		local a1 = pb and arrowAt(pb, Vector2.new(1, 0), true)             -- (rugs6) the short neon arrow, from the left
		local opened = waitFor(function() return pg:GetAttribute("OpenPanel") == "passport" end, 120)
		if g1 then g1:Destroy() end
		if a1 then a1:Destroy() end]=], "step 1")
-- 3. the last word in the new card
swap([=[say("Looks lovely in here! Swap or store your rugs any time.", 7)]=],
	[=[say("Looks lovely in here!", "Swap or store your rugs any time.", 5)]=], "the last word")
local bk = tc:Clone(); bk.Name = "TreehouseClient_pre_rugs6"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(tc, function() return src end)
print(string.format("rugs6: TreehouseClient -> %d chars", #tc.Source))
return "rugs6 installed"

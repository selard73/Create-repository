-- Oct 4 2026 crab game fix 5: shorter panel (message left of the button) so it fits narrow phones between Hint and jump
local cli=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('CrabClient')
if cli then cli.Source=[==[-- CrabClient (StarterPlayerScripts): the crab game's button and bucket (Oct 4 2026). The server (workspace.CrabGame.CrabServer)
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
local root = Instance.new("Frame") root.Name = "Root" root.BackgroundTransparency = 1 root.Size = UDim2.fromOffset(300, 128)
root.AnchorPoint = Vector2.new(1, 1) root.Parent = gui

local btn = Instance.new("TextButton") btn.Name = "CastButton" btn.Text = "" btn.AutoButtonColor = false
btn.Size = UDim2.fromOffset(92, 92) btn.Position = UDim2.new(1, -96, 0, 0) btn.BackgroundColor3 = FACE btn.Parent = root
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

local pill = Instance.new("Frame") pill.Name = "Bucket" pill.Size = UDim2.fromOffset(118, 24) pill.Position = UDim2.new(1, -109, 0, 102)
pill.BackgroundColor3 = FACE pill.Parent = root
Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 12)
local ps = Instance.new("UIStroke") ps.Color = RIM ps.Thickness = 2 ps.Parent = pill
local pillText = Instance.new("TextLabel") pillText.BackgroundTransparency = 1 pillText.Size = UDim2.fromScale(1, 1)
pillText.FontFace = FONT pillText.TextSize = 14 pillText.TextColor3 = INK pillText.Parent = pill

local note = Instance.new("TextLabel") note.Name = "Note" note.BackgroundTransparency = 1 note.Size = UDim2.fromOffset(196, 56)
note.Position = UDim2.fromOffset(0, 18) note.TextXAlignment = Enum.TextXAlignment.Right note.FontFace = FONT note.TextSize = 14 note.TextColor3 = RGB(255, 255, 255)
note.TextStrokeTransparency = 0.35 note.TextWrapped = true note.TextYAlignment = Enum.TextYAlignment.Center note.Text = "" note.Parent = root

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
local function drawn(o)
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then return o.BackgroundTransparency < 1 or (o.Text ~= "" and o.TextTransparency < 1) end
	if o:IsA("ImageLabel") or o:IsA("ImageButton") then return o.BackgroundTransparency < 1 or (o.Image ~= "" and o.ImageTransparency < 1) end
	return o.BackgroundTransparency < 1
end
local StarterGui = game:GetService("StarterGui")
local function others()
	local list = {}
	local vp = workspace.CurrentCamera.ViewportSize
	for _, sg in ipairs(pg:GetChildren()) do
		if sg:IsA("ScreenGui") and sg ~= gui and sg.Enabled and sg.Name ~= "SquirrelBubbleGui" and sg.Name ~= "DailyGui" then   -- (Shannon: the daily card only shows at spawn and is closed right away - it may overlap)
			for _, o in ipairs(sg:GetDescendants()) do
				if o:IsA("GuiObject") and o.AbsoluteSize.X > 2 and o.AbsoluteSize.Y > 2 and visible(o) and drawn(o) then
					local s = o.AbsoluteSize
					if not (s.X >= vp.X * 0.9 and s.Y >= vp.Y * 0.9) then table.insert(list, {rectOf(o)}) end
				end
			end
		end
	end
	-- Roblox's own hotbar (CoreGui, invisible to this list): keep the bottom middle free while it is on
	local okBP, bp = pcall(function() return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) end)
	if not okBP or bp then
		-- (this panel ignores the inset, so its spots are in whole-screen pixels, the same space as rectOf and the viewport)
		local half = math.min(vp.X * 0.5, 340)
		table.insert(list, {vp.X / 2 - half / 2, vp.Y - 96, vp.X / 2 + half / 2, vp.Y})
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
	for _, fy in ipairs({0.62, 0.5, 0.75, 0.38, 0.85, 0.28}) do table.insert(tries, Vector2.new(vp.X - 16, vp.Y * fy + h / 2)) end
	for _, fy in ipairs({0.62, 0.5, 0.38}) do table.insert(tries, Vector2.new(vp.X - 120, vp.Y * fy + h / 2)) end
	for _, fx in ipairs({0.5, 0.65, 0.35}) do table.insert(tries, Vector2.new(vp.X * fx + w / 2, vp.Y - 16)) end
	for _, fy in ipairs({0.5, 0.38, 0.28}) do table.insert(tries, Vector2.new(16 + w, vp.Y * fy + h / 2)) end
	table.insert(tries, Vector2.new(vp.X * 0.3 + w / 2, vp.Y * 0.5 + h / 2))
	for _, t in ipairs(tries) do
		local x1, y1 = t.X, t.Y
		if clearAt(x1 - w, y1 - h, x1, y1, list) then
			root.Position = UDim2.fromOffset(x1, y1) root.Visible = true return true
		end
	end
	root.Position = UDim2.fromOffset(tries[1].X, tries[1].Y)
	if not btn.Visible then root.Visible = false end         -- just the bucket pill: wait for room rather than overlap
	return false
end

-- ---------------------------------------------------------------- every frame: show/hide, ring, prompt
local sellPrompt = nil                 -- looked up again while missing: with streaming the sell spot arrives only near Beppe
local lastLook = 0
local lastPlace, wasShown, compact, lastW = 0, false, nil, 0
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
	local compactNow = (not castOn) and plain + gold > 0
	pillText.Text = (gold > 0 and ("Crabs " .. (plain + gold) .. "/" .. bucketMax() .. "  (" .. gold .. " gold)") or ("Crabs " .. plain .. "/" .. bucketMax()))
		.. (compactNow and "\nsell to Beppe" or "")
	-- the pill fits its words; away from the area it is the whole panel (so it can tuck into any free spot)
	local pw = math.max(118, math.ceil(pillText.TextBounds.X) + 26)
	pill.Size = UDim2.fromOffset(pw, compactNow and 40 or 24)
	if compactNow then
		root.Size = UDim2.fromOffset(pw, 42) pill.Position = UDim2.fromOffset(0, 1) note.Visible = false
	else
		root.Size = UDim2.fromOffset(300, 128) pill.Position = UDim2.fromOffset(math.min(250 - math.ceil(pw / 2), 300 - pw), 102) note.Visible = true   -- under the button, never past the panel edge
	end
	if (not sellPrompt or not sellPrompt.Parent) and os.clock() - lastLook > 1 then lastLook = os.clock() sellPrompt = G:FindFirstChild("SellPrompt", true) end
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
	if show and (not wasShown or compact ~= castOn or lastW ~= root.Size.X.Offset or os.clock() - lastPlace > 2) then
		lastPlace = os.clock() compact = castOn lastW = root.Size.X.Offset
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
]==] end
game:GetService('ChangeHistoryService'):SetWaypoint('Crab game fix 5')
warn('QX@OK5 client',cli and #cli.Source)

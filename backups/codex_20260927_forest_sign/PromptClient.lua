local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local TextService = game:GetService("TextService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local FONT = Enum.Font.FredokaOne
local function customise(p) if p:IsA("ProximityPrompt") then p.Style = Enum.ProximityPromptStyle.Custom end end
for _, d in ipairs(workspace:GetDescendants()) do customise(d) end
workspace.DescendantAdded:Connect(customise)
-- Shannon: the pill over the object hid whatever the character was doing, and at the screen edge it stopped reading as a
-- prompt. It rides beside the player now: a small pill to the right of their head, level with the name tag; several
-- prompts stack under it. A BillboardGui on the head, Active so it can be tapped; SizeOffset puts its LEFT edge at the
-- anchor, so the pills grow out to the right of the head whatever their width.
local pg = player:WaitForChild("PlayerGui")
-- the same anchor as the name tag (HonourTag: 260x64 px, 2.4 studs over the head, the name on its top 30 px row), so the
-- pill keeps a fixed spot beside the name whatever the camera does: its bottom just above the title row (level with the
-- name), its left edge a little right of the name's own text; more prompts stack upward, away from the tag
local gui = Instance.new("BillboardGui"); gui.Name = "PromptUI"; gui.Size = UDim2.fromOffset(460, 400); gui.AlwaysOnTop = true; gui.MaxDistance = 80; gui.LightInfluence = 0
gui.Active = true; gui.StudsOffset = Vector3.new(0, 2.4, 0); gui.SizeOffset = Vector2.new(0.5, 0); gui.ResetOnSpawn = false; gui.Parent = pg
local stack = Instance.new("Frame"); stack.Name = "Stack"; stack.AnchorPoint = Vector2.new(0, 1); stack.Position = UDim2.new(0, 44, 0.5, -3); stack.Size = UDim2.new(1, -44, 0, 190); stack.BackgroundTransparency = 1; stack.Parent = gui
local lay = Instance.new("UIListLayout"); lay.FillDirection = Enum.FillDirection.Vertical; lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
lay.VerticalAlignment = Enum.VerticalAlignment.Bottom; lay.Padding = UDim.new(0, 5); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = stack
-- ON A PHONE THE BUTTON HAS A FIXED SPOT (Shannon, Sep 26: "on mobile there is no button to free the squirrels or it is
-- hidden behind something else" - zoomed in close, the pill beside the name rose up under the title banner and the golden
-- squirrel note): on the right, straight ABOVE THE JUMP ARROW ("under the forest sign ... above the jump arrow"), where the
-- thumb is and nothing covers it - measured from the jump button itself, so it fits every phone; when the slingshot is out
-- its big round button has that corner, so the pill sits just left of it. It slides in from the right, and whatever it
-- belongs to - the cage, the post box - gets a gold outline while it shows, so it's clear what the button is for.
local GuiService = game:GetService("GuiService")
local touchGui = Instance.new("ScreenGui"); touchGui.Name = "PromptTouch"; touchGui.ResetOnSpawn = false; touchGui.DisplayOrder = 30
touchGui.IgnoreGuiInset = true; touchGui.Parent = pg
local touchStack = Instance.new("Frame"); touchStack.Name = "Stack"; touchStack.AnchorPoint = Vector2.new(1, 1); touchStack.Position = UDim2.new(1, -20, 1, -110)
touchStack.Size = UDim2.fromOffset(320, 260); touchStack.BackgroundTransparency = 1; touchStack.Parent = touchGui
local tlay = Instance.new("UIListLayout"); tlay.FillDirection = Enum.FillDirection.Vertical; tlay.HorizontalAlignment = Enum.HorizontalAlignment.Right
tlay.VerticalAlignment = Enum.VerticalAlignment.Bottom; tlay.Padding = UDim.new(0, 8); tlay.SortOrder = Enum.SortOrder.LayoutOrder; tlay.Parent = touchStack
local function screenPos(o)                           -- top-left on the real screen, whatever inset its ScreenGui keeps
	local sg = o:FindFirstAncestorOfClass("ScreenGui")
	local inset = (sg and not sg.IgnoreGuiInset) and GuiService:GetGuiInset() or Vector2.zero
	return o.AbsolutePosition + inset
end
-- every other thing showing on a phone's screen, as rects in real screen space (for the pills to keep clear of)
local function shownRects()
	local out = {}
	local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900, 420)
	for _, sg in ipairs(pg:GetChildren()) do
		if sg:IsA("ScreenGui") and sg.Enabled and sg ~= touchGui then
			for _, o in ipairs(sg:GetDescendants()) do
				if o:IsA("GuiObject") and o.Visible and o.AbsoluteSize.X > 4 and o.AbsoluteSize.Y > 4
					and o.AbsoluteSize.X < vs.X * 0.9 and o.AbsoluteSize.Y < vs.Y * 0.9 then       -- (a full-screen layer is not a thing)
					local seen = o.BackgroundTransparency < 0.9
						or ((o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and o.TextTransparency < 0.9)
						or ((o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image ~= "" and o.ImageTransparency < 0.9)
					local a = o.Parent
					while seen and a and a ~= sg do
						if a:IsA("GuiObject") and not a.Visible then seen = false end
						a = a.Parent
					end
					if seen then
						local p = screenPos(o)
						table.insert(out, {p.X, p.Y, p.X + o.AbsoluteSize.X, p.Y + o.AbsoluteSize.Y})
					end
				end
			end
		end
	end
	-- the hotbar is Roblox's own (out of a script's sight): its slots sit centred along the bottom
	local n = 0
	local bp = player:FindFirstChildOfClass("Backpack")
	for _, t in ipairs(bp and bp:GetChildren() or {}) do if t:IsA("Tool") then n += 1 end end
	if player.Character and player.Character:FindFirstChildOfClass("Tool") then n += 1 end
	if n > 0 then
		local hw = math.min(n, 10) * 66 / 2 + 6
		table.insert(out, {vs.X / 2 - hw, vs.Y - 76, vs.X / 2 + hw, vs.Y})
	end
	return out
end
local function clearOf(r, rects)
	for _, q in ipairs(rects) do
		if r[1] < q[3] and r[3] > q[1] and r[2] < q[4] and r[4] > q[2] then return false end
	end
	return true
end
-- NEXT TO YOU ON A PHONE (Shannon, Sep 26: "the rescue button should definitely be next to the [player] ... If possible, up
-- and to the right of the player's [head]"): the pills sit just up and to the right of your character's head, following it
-- across the screen, and nudge themselves clear of anything else showing. A prompt can ask for the fixed spot above the
-- jump arrow instead with PhoneSpot = "jump", or to sit under a sign with PhoneSpot = "sign" (see placeSign).
local headStack = Instance.new("Frame"); headStack.Name = "HeadStack"; headStack.AnchorPoint = Vector2.new(0, 1)
headStack.Size = UDim2.fromOffset(320, 200); headStack.BackgroundTransparency = 1; headStack.Parent = touchGui
local hlay = Instance.new("UIListLayout"); hlay.FillDirection = Enum.FillDirection.Vertical; hlay.HorizontalAlignment = Enum.HorizontalAlignment.Left
hlay.VerticalAlignment = Enum.VerticalAlignment.Bottom; hlay.Padding = UDim.new(0, 8); hlay.SortOrder = Enum.SortOrder.LayoutOrder; hlay.Parent = headStack
-- UNDER THE SIGN ON A PHONE (Shannon, Sep 26: "the button for start the race should move on the screen depending on the
-- orientation you're standing, looking at the sign. It should always be under the sign, no matter what direction you're
-- looking at it"): PhoneSpot = "sign" with PhoneAnchor = a point in the world (the bottom middle of the sign); the pill
-- sits just under that point wherever it is on the screen, following it as the camera turns, and clear of everything
-- else; while the sign is behind you or off the screen, it waits in the spot above the jump arrow
local signStack = Instance.new("Frame"); signStack.Name = "SignStack"; signStack.AnchorPoint = Vector2.new(0, 0)
signStack.Size = UDim2.fromOffset(320, 200); signStack.BackgroundTransparency = 1; signStack.Parent = touchGui
local slay = Instance.new("UIListLayout"); slay.FillDirection = Enum.FillDirection.Vertical; slay.HorizontalAlignment = Enum.HorizontalAlignment.Left
slay.VerticalAlignment = Enum.VerticalAlignment.Top; slay.Padding = UDim.new(0, 8); slay.SortOrder = Enum.SortOrder.LayoutOrder; slay.Parent = signStack
local signAnchor
local function stackRects(st, into)                  -- the pills already placed in another of our stacks (never on top of each other)
	for _, s in ipairs(st:GetChildren()) do
		if s:IsA("GuiObject") and s.AbsoluteSize.X > 0 then
			local p = s.AbsolutePosition
			table.insert(into, {p.X, p.Y, p.X + s.AbsoluteSize.X, p.Y + s.AbsoluteSize.Y})
		end
	end
	return into
end
local rectCache, rectAt = {}, 0
local function placeHead()
	local cam = workspace.CurrentCamera
	local head = player.Character and player.Character:FindFirstChild("Head")
	local w, h = 0, 0
	for _, s in ipairs(headStack:GetChildren()) do
		if s:IsA("GuiObject") then w = math.max(w, s.AbsoluteSize.X); h += s.AbsoluteSize.Y + 8 end
	end
	if h == 0 or not (cam and head) then return end
	local vs = cam.ViewportSize
	local p, on = cam:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y * 0.5, 0))
	local x0, y0
	if on and p.Z > 0 then x0, y0 = p.X + 30, p.Y - 4 else x0, y0 = vs.X - 24 - w, vs.Y - 110 end
	if os.clock() - rectAt > 0.25 then rectCache = shownRects(); rectAt = os.clock() end
	local others = stackRects(signStack, {})
	local function fits(x, y)
		local r = {x - 3, y - h - 3, x + w + 3, y + 3}
		return r[1] > 4 and r[2] > 4 and r[3] < vs.X - 4 and r[4] < vs.Y - 4 and clearOf(r, rectCache) and clearOf(r, others)
	end
	local best
	for _, d in ipairs({{0, 0}, {0, -12}, {0, -24}, {16, 0}, {32, 0}, {0, 16}, {16, 32}, {0, 48}, {24, 64}, {-40, -24}, {40, 80}}) do
		if fits(x0 + d[1], y0 + d[2]) then best = {x0 + d[1], y0 + d[2]} break end
	end
	if not best then best = {math.clamp(x0, 4, math.max(4, vs.X - w - 4)), math.clamp(y0, h + 4, vs.Y - 4)} end
	headStack.Position = UDim2.fromOffset(best[1], best[2])
end
game:GetService("RunService").RenderStepped:Connect(placeHead)
local function placeTouch()
	local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900, 420)
	local right, bottom = vs.X - 20, vs.Y - 110
	local tg = pg:FindFirstChild("TouchGui")
	local jump = tg and tg:FindFirstChild("JumpButton", true)
	if jump and jump:IsA("GuiObject") and jump.Visible and jump.AbsoluteSize.Y > 0 then
		local p = screenPos(jump)
		right, bottom = p.X + jump.AbsoluteSize.X + 12, p.Y - 10         -- a touch right of the arrow's edge, clear of the daily card
	end
	local sui = pg:FindFirstChild("SlingUI")
	local hold = sui and sui.Enabled and sui:FindFirstChild("Shoot")
	if hold and hold.Visible and hold.AbsoluteSize.Y > 0 then
		local p = screenPos(hold)
		right, bottom = p.X - 10, p.Y + hold.AbsoluteSize.Y
	end
	-- NOTHING OVERLAPS ON A PHONE (Shannon: "Ideally on that phone, nothing should be overlapping. At any time."): everything
	-- else showing on the screen is measured, and the pills move up - then left - until they are clear of all of it
	local w, h = 0, 0
	for _, s in ipairs(touchStack:GetChildren()) do
		if s:IsA("GuiObject") then w = math.max(w, s.AbsoluteSize.X); h += s.AbsoluteSize.Y + 8 end
	end
	if h > 0 then
		local rects = shownRects()
		local function try(rx, by)
			local r = {rx - w - 3, by - h - 3, rx + 3, by + 3}
			return r[1] > 2 and r[2] > 2 and clearOf(r, rects)
		end
		for dy = 0, 240, 6 do if try(right, bottom - dy) then touchStack.Position = UDim2.fromOffset(right, bottom - dy) return end end
		for dx = 6, 360, 6 do if try(right - dx, bottom) then touchStack.Position = UDim2.fromOffset(right - dx, bottom) return end end
	end
	touchStack.Position = UDim2.fromOffset(right, bottom)
end
local function placeSign()
	local cam = workspace.CurrentCamera
	local w, h = 0, 0
	for _, s in ipairs(signStack:GetChildren()) do
		if s:IsA("GuiObject") then w = math.max(w, s.AbsoluteSize.X); h += s.AbsoluteSize.Y + 8 end
	end
	if h == 0 or not cam or typeof(signAnchor) ~= "Vector3" then return end
	h -= 8
	local vs = cam.ViewportSize
	if os.clock() - rectAt > 0.25 then rectCache = shownRects(); rectAt = os.clock() end
	local others = stackRects(touchStack, stackRects(headStack, {}))
	local function fits(x, y)
		local r = {x - 3, y - 3, x + w + 3, y + h + 3}
		return r[1] > 4 and r[2] > 4 and r[3] < vs.X - 4 and r[4] < vs.Y - 4 and clearOf(r, rectCache) and clearOf(r, others)
	end
	local p = cam:WorldToViewportPoint(signAnchor)
	local best
	if p.Z > 0 and p.X > 0 and p.X < vs.X and p.Y > 0 and p.Y < vs.Y then
		local x0, y0 = p.X - w / 2, p.Y + 10                            -- centred, just under the sign's bottom edge
		for _, d in ipairs({{0, 0}, {0, 12}, {0, 24}, {-40, 0}, {40, 0}, {0, 40}, {-80, 12}, {80, 12}, {0, 60}, {-120, 24}, {120, 24}}) do
			if fits(x0 + d[1], y0 + d[2]) then best = {x0 + d[1], y0 + d[2]} break end
		end
		if not best then best = {math.clamp(x0, 4, math.max(4, vs.X - w - 4)), math.clamp(y0, 4, math.max(4, vs.Y - h - 4))} end
	else
		local right, bottom = vs.X - 20, vs.Y - 110                      -- the sign is out of sight: above the jump arrow
		local tg = pg:FindFirstChild("TouchGui")
		local jump = tg and tg:FindFirstChild("JumpButton", true)
		if jump and jump:IsA("GuiObject") and jump.Visible and jump.AbsoluteSize.Y > 0 then
			local jp = screenPos(jump)
			right, bottom = jp.X + jump.AbsoluteSize.X + 12, jp.Y - 10
		end
		best = {right - w, bottom - h}
		for dy = 0, 240, 6 do if fits(right - w, bottom - h - dy) then best = {right - w, bottom - h - dy} break end end
	end
	signStack.Position = UDim2.fromOffset(best[1], best[2])
end
game:GetService("RunService").RenderStepped:Connect(placeSign)
local function outlineFor(prompt)                     -- the thing the button is for: its model if that's object-sized, else its part
	local target = prompt.Parent
	local m = target and target:FindFirstAncestorOfClass("Model")
	if m then
		local ok, _, size = pcall(function() return m:GetBoundingBox() end)
		if ok and size.Magnitude < 30 then target = m end
	end
	if not target or not (target:IsA("Model") or (target:IsA("BasePart") and target.Transparency < 1)) then return nil end
	local hl = Instance.new("Highlight"); hl.Name = "PromptOutline"; hl.Adornee = target; hl.FillTransparency = 1
	hl.OutlineColor = C(255, 214, 90); hl.OutlineTransparency = 0.05; hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = workspace.CurrentCamera
	return hl
end
local function place()                                -- just right of the name text (a fixed gap when there is no tag)
	local head = gui.Adornee
	local tag = head and head:FindFirstChild("HonourTag")
	local nameLabel = tag and tag:FindFirstChild("Name")
	local x = 44
	if nameLabel and nameLabel:IsA("TextLabel") and nameLabel.TextBounds.X > 0 then x = math.max(30, math.min(150, nameLabel.TextBounds.X / 2 + 10)) end
	stack.Position = UDim2.new(0, x, 0.5, -3); stack.Size = UDim2.new(1, -x, 0, 190)
end
local function adorn(char)
	local head = char and char:WaitForChild("Head", 10)
	gui.Adornee = head
	place()
end
adorn(player.Character)
player.CharacterAdded:Connect(adorn)
local shown = 0
local live = {}
local pressed                                         -- the one pill being held right now, if any
local function release()
	if not pressed then return end
	local p = pressed; pressed = nil
	p.stroke.Color = C(240, 200, 90)
	pcall(function() p.prompt:InputHoldEnd() end)
end
UIS.InputEnded:Connect(function(io)                   -- a finger that slides off the pill still ends the hold
	if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then release() end
end)
local function keyName(prompt, inputType)
	if inputType == Enum.ProximityPromptInputType.Touch then return nil end
	if inputType == Enum.ProximityPromptInputType.Gamepad then return (prompt.GamepadKeyCode.Name:gsub("^Button", "")) end
	return prompt.KeyboardKeyCode.Name
end
PPS.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	local touch = inputType == Enum.ProximityPromptInputType.Touch or script.Parent:GetAttribute("ForceMobile") == true
	local S = touch and 1.25 or 1                     -- a thumb needs a bigger target than a mouse pointer (not too big: Shannon)
	local key = (not touch) and keyName(prompt, inputType) or nil
	local action, object = prompt.ActionText, prompt.ObjectText
	local wA = TextService:GetTextSize(action, 15, FONT, Vector2.new(500, 40)).X
	local wO = object ~= "" and TextService:GetTextSize(object, 11, FONT, Vector2.new(500, 40)).X or 0
	local badge = key ~= nil or touch
	local x = badge and 36 or 10
	local w = math.min(300, (math.max(wA, wO) + x + 14) * S)
	local h = (object ~= "" and 38 or 28) * S
	local btn = Instance.new("TextButton"); btn.Name = "Pill"; btn.Size = UDim2.fromOffset(w, h); btn.BackgroundColor3 = C(38, 30, 52); btn.BackgroundTransparency = 0.12
	btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.Active = true; btn.ClipsDescendants = true
	local holder                                      -- (on a phone) the pill's place in the fixed stack; the pill slides into it
	if touch then
		holder = Instance.new("Frame"); holder.Name = "Slot"; holder.BackgroundTransparency = 1; holder.Size = UDim2.fromOffset(w, h)
		local spot = prompt:GetAttribute("PhoneSpot")
		if spot == "jump" then holder.Parent = touchStack; placeTouch()
		elseif spot == "sign" and typeof(prompt:GetAttribute("PhoneAnchor")) == "Vector3" then
			signAnchor = prompt:GetAttribute("PhoneAnchor"); holder.Parent = signStack; placeSign()
		else holder.Parent = headStack; placeHead() end
		btn.Position = UDim2.fromOffset(80, 0); btn.Parent = holder
		TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)}):Play()
	else
		btn.Parent = stack
	end
	shown += 1; btn.LayoutOrder = -shown; if holder then holder.LayoutOrder = -shown end; place()   -- the newest goes above the others
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12 * S); c.Parent = btn
	local s = Instance.new("UIStroke"); s.Color = C(240, 200, 90); s.Thickness = 1.5 * S; s.Parent = btn
	-- the fill that grows while a hold-prompt is held
	local fill = Instance.new("Frame"); fill.Name = "Fill"; fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = C(240, 200, 90); fill.BackgroundTransparency = 0.7; fill.BorderSizePixel = 0; fill.ZIndex = 1; fill.Parent = btn
	if badge then
		local kb = Instance.new("TextLabel"); kb.Size = UDim2.fromOffset(24 * S, 24 * S); kb.Position = UDim2.new(0, 6 * S, 0.5, -12 * S); kb.BackgroundColor3 = C(255, 246, 220)
		kb.Text = key or ""; kb.Font = FONT; kb.TextSize = 14 * S; kb.TextColor3 = C(38, 30, 52); kb.ZIndex = 2; kb.Parent = btn
		local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 6 * S); kc.Parent = kb
		if not key then                               -- a filled dot reads as "press here" in any language
			local dot = Instance.new("Frame"); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.fromScale(0.5, 0.5)
			dot.Size = UDim2.fromOffset(12 * S, 12 * S); dot.BackgroundColor3 = C(38, 30, 52); dot.BorderSizePixel = 0; dot.ZIndex = 3; dot.Parent = kb
			local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
		end
	end
	if object ~= "" then
		local o = Instance.new("TextLabel"); o.Size = UDim2.new(1, (-x - 6) * S, 0, 12 * S); o.Position = UDim2.new(0, x * S, 0, 4 * S); o.BackgroundTransparency = 1
		o.Font = FONT; o.TextSize = 11 * S; o.TextColor3 = C(200, 190, 210); o.TextXAlignment = Enum.TextXAlignment.Left; o.TextTruncate = Enum.TextTruncate.AtEnd; o.Text = object; o.ZIndex = 2; o.Parent = btn
	end
	local a = Instance.new("TextLabel"); a.Size = UDim2.new(1, (-x - 6) * S, 0, 17 * S); a.Position = UDim2.new(0, x * S, 0, (object ~= "" and 17 or 5) * S); a.BackgroundTransparency = 1
	a.Font = FONT; a.TextSize = 15 * S; a.TextColor3 = C(255, 246, 220); a.TextXAlignment = Enum.TextXAlignment.Left; a.TextTruncate = Enum.TextTruncate.AtEnd; a.Text = action; a.ZIndex = 2; a.Parent = btn
	btn.InputBegan:Connect(function(io)
		if io.UserInputType ~= Enum.UserInputType.Touch and io.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		release()
		pressed = {prompt = prompt, stroke = s}
		s.Color = C(255, 246, 220)
		prompt:InputHoldBegin()
	end)
	btn.InputEnded:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then release() end
	end)
	if live[prompt] then local o = live[prompt]; (o.holder or o.pill):Destroy(); if o.hl then o.hl:Destroy() end end
	live[prompt] = {pill = btn, fill = fill, stroke = s, holder = holder, hl = touch and outlineFor(prompt) or nil}
end)
PPS.PromptButtonHoldBegan:Connect(function(prompt)
	local rec = live[prompt]; if not rec then return end
	rec.fill.Size = UDim2.new(0, 0, 1, 0)
	rec.tween = TweenService:Create(rec.fill, TweenInfo.new(math.max(0.05, prompt.HoldDuration), Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}); rec.tween:Play()
end)
PPS.PromptButtonHoldEnded:Connect(function(prompt)
	local rec = live[prompt]; if not rec then return end
	if rec.tween then rec.tween:Cancel() end
	rec.fill.Size = UDim2.new(0, 0, 1, 0)
end)
PPS.PromptTriggered:Connect(function(prompt)
	local rec = live[prompt]; if not rec then return end
	rec.fill.Size = UDim2.new(1, 0, 1, 0)
	TweenService:Create(rec.fill, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
	task.delay(0.4, function() if rec.fill.Parent then rec.fill.BackgroundTransparency = 0.7; rec.fill.Size = UDim2.new(0, 0, 1, 0) end end)
end)
PPS.PromptHidden:Connect(function(prompt)
	if pressed and pressed.prompt == prompt then pressed = nil end
	local rec = live[prompt]
	if rec then (rec.holder or rec.pill):Destroy(); if rec.hl then rec.hl:Destroy() end; live[prompt] = nil end
end)
-- (the phone's spot follows the jump button - and the slingshot's big button when it comes out)
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, rec in pairs(live) do if rec.holder then placeTouch() break end end
	end
end)

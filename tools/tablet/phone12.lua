-- phone12 (Oct 20 2026), two fixes, Shannon: "we need to make the same fix on the phones for the mailbox feature, its having
-- the same issue; also, that little medal thing now is hiding under the baguette chase button".
--  1. PostClient (rebuilt from HudBackup.PostClient_pre_tablet4 + this block): TOUCH screens. A tablet keeps tablet5's
--     "shrink to fit above the keyboard"; a PHONE (iPhone 7: keyboard y 213-375 of 375 - too little room to shrink into)
--     keeps the panel's size and slides it up until the writing box itself sits just above the keyboard (the title may
--     leave the top for a moment; Done puts the keyboard away and the panel - and Send - come back). The post box prompt is
--     hidden while the panel is open on every touch screen.
--  2. ChaseClient: the Keeper / Wise Squirrel medal (BadgeCaseClient, BadgeButton.Medal) is drawn just under the Hint button;
--     while it shows, the Baguette Chase button sits under the medal (Hint, medal, Baguette Chase) instead of on it.
-- Run in Studio EDIT. Backs both scripts up first. No DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no HudBackup")

-- ---------- 1. PostClient ----------
local post = workspace.PostOffice.PostClient
local was = backup:FindFirstChild("PostClient_pre_tablet4")
assert(was and not was.Source:find("tablet check", 1, true), "no clean PostClient_pre_tablet4 backup")
local anchor = "task.spawn(hookPrompt)\n"
local block = anchor .. [[

-- (Oct 20 2026, tablet check; Shannon: "please just fix the ipad version for now" - later: "we need to make the same fix on
-- the phones for the mailbox feature") on a touch screen the keyboard covers the bottom of the screen (iPad Air y 407-820,
-- iPhone 7 y 213-375), which hid the Send button and the writing box while typing, and the post box's own "Open" button sat
-- on the writing box. TOUCH SCREENS: on a tablet the panel sits just under the top bar and shrinks just enough that the box
-- and its Send button end above the keyboard; on a phone (too little room for that) the panel keeps its size and slides up
-- until the box itself sits just above the keyboard (the title may leave the top for a moment; Done puts the keyboard away
-- and the panel comes back, Send with it). Studio's practice keyboard draws a bar ~30-40 px above the edge Roblox reports,
-- hence the wide gap. The post box's button is hidden while the panel is open. Computers keep everything as it was.
local GuiService = game:GetService("GuiService")
local TYPE_TOP, TYPE_GAP = 60, 52
local function isTablet()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.zero
	return TOUCH and math.min(vp.X, vp.Y) >= 600
end
local focusedBox, typing = nil, false
local function rest()                                                       -- back to the normal size and place
	typing = false
	fit()
	panel.Position = UDim2.fromScale(0.5, 0.5)
end
local function adjust()
	if not (gui.Enabled and focusedBox and focusedBox.Parent and TOUCH and UIS.OnScreenKeyboardVisible) then
		if typing then rest() end
		return
	end
	local kbTop = UIS.OnScreenKeyboardPosition.Y                            -- (real screen space, from the very top)
	local s = panel.AbsoluteSize.Y / H                                      -- the panel's scale right now
	if kbTop <= 0 or s <= 0 then return end
	local inset = GuiService:GetGuiInset().Y
	local top = panel.AbsolutePosition.Y + inset
	-- in the panel's own units: the box's bottom, and the lowest thing that must stay in sight on a tablet (a Send just under it)
	local boxBottom = (focusedBox.AbsolutePosition.Y + inset + focusedBox.AbsoluteSize.Y - top) / s
	local bottom = boxBottom
	for _, d in ipairs(panel:GetDescendants()) do
		if d:IsA("TextButton") and d.Visible and string.find(d.Text, "^Send") then
			local b = (d.AbsolutePosition.Y + inset + d.AbsoluteSize.Y - top) / s
			if b > bottom and b - bottom < 160 then bottom = b end
		end
	end
	if bottom <= 0 then return end
	fit()
	if isTablet() then
		local want = math.clamp((kbTop - TYPE_GAP - TYPE_TOP) / bottom, 0.5, scale.Scale)
		scale.Scale = want
		panel.Position = UDim2.new(0.5, 0, 0, TYPE_TOP + H * want / 2)
	else
		local sc = scale.Scale
		local newTop = math.min(TYPE_TOP, kbTop - TYPE_GAP - boxBottom * sc)
		panel.Position = UDim2.new(0.5, 0, 0, newTop + H * sc / 2)
	end
	typing = true
end
UIS.TextBoxFocused:Connect(function(box)
	if not box:IsDescendantOf(gui) then return end
	focusedBox = box
	task.spawn(function() for _ = 1, 10 do adjust(); task.wait(0.1) end end)   -- (the keyboard's size arrives a moment after the focus)
end)
UIS.TextBoxFocusReleased:Connect(function(box)
	if box == focusedBox then focusedBox = nil; adjust() end
end)
for _, prop in ipairs({"OnScreenKeyboardVisible", "OnScreenKeyboardPosition", "OnScreenKeyboardSize"}) do
	pcall(function() UIS:GetPropertyChangedSignal(prop):Connect(adjust) end)
end
local hiddenPrompt
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	local box = PO:FindFirstChild("PostBox"); local body = box and box:FindFirstChild("Body")
	local prompt = body and body:FindFirstChild("PostPrompt")
	if gui.Enabled then
		if TOUCH and prompt and prompt.Enabled then prompt.Enabled = false; hiddenPrompt = prompt end
	else
		if hiddenPrompt then hiddenPrompt.Enabled = true; hiddenPrompt = nil end
		focusedBox = nil
		if typing then rest() end
	end
end)
]]
local src = was.Source
local a, b = src:find(anchor, 1, true)
assert(a and not src:find(anchor, b + 1, true), "PostClient backup: anchor not found once - nothing changed")
local newPost = src:sub(1, a - 1) .. block .. src:sub(b + 1)

-- ---------- 2. ChaseClient ----------
local cc = workspace.Baguette.ChaseClient
local cs = cc.Source
local oldPlace = [[			if hg.Enabled and hb.Visible and hb.AbsoluteSize.Y > 0 then
				button.Position = UDim2.fromOffset(12, hb.AbsolutePosition.Y + hb.AbsoluteSize.Y + 8)   -- (both count from under the top bar)
			else]]
local newPlace = [[			if hg.Enabled and hb.Visible and hb.AbsoluteSize.Y > 0 then
				local bottom = hb.AbsolutePosition.Y + hb.AbsoluteSize.Y                -- (both count from under the top bar)
				-- the Keeper / Wise Squirrel medal hangs just under Hint (BadgeCaseClient): then go under the medal and its ribbon
				local bb = player.PlayerGui:FindFirstChild("BadgeButton"); local medal = bb and bb:FindFirstChild("Medal")
				if medal and medal.Visible and bb.Enabled then bottom = math.max(bottom, medal.AbsolutePosition.Y + 44) end
				button.Position = UDim2.fromOffset(12, bottom + 8)
			else]]
local p1, p2 = cs:find(oldPlace, 1, true)
assert(p1 and not cs:find(oldPlace, p2 + 1, true), "ChaseClient: place() not found once - nothing changed")
cs = cs:sub(1, p1 - 1) .. newPlace .. cs:sub(p2 + 1)
local oldHook = [[		hg:GetPropertyChangedSignal("Enabled"):Connect(place)
]]
local newHook = [[		hg:GetPropertyChangedSignal("Enabled"):Connect(place)
		task.spawn(function()                                                -- (the medal may arrive later, and comes and goes)
			local bb = player.PlayerGui:WaitForChild("BadgeButton", 60); local medal = bb and bb:WaitForChild("Medal", 30)
			if not medal then return end
			for _, prop in ipairs({"Visible", "AbsolutePosition"}) do medal:GetPropertyChangedSignal(prop):Connect(place) end
			bb:GetPropertyChangedSignal("Enabled"):Connect(place)
			place()
		end)
]]
local h1, h2 = cs:find(oldHook, 1, true)
assert(h1 and not cs:find(oldHook, h2 + 1, true), "ChaseClient: hook line not found once - nothing changed")
cs = cs:sub(1, h1 - 1) .. newHook .. cs:sub(h2 + 1)

-- ---------- backups, then write ----------
local b1 = post:Clone(); b1.Name = "PostClient_pre_phone12"; b1.Enabled = false; b1.Parent = backup
local b2 = cc:Clone(); b2.Name = "ChaseClient_pre_phone12"; b2.Enabled = false; b2.Parent = backup
SES:UpdateSourceAsync(post, function() return newPost end)
SES:UpdateSourceAsync(cc, function() return cs end)
return "phone12 installed (PostClient, ChaseClient)"

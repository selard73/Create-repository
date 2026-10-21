-- phone21 (Oct 20 2026): Shannon (iPhone): "when the keyboard is open is it still covering the send button?" - yes on a phone
-- (the letter slides up so the box sits above the keyboard, but the letter's Send stays under it) -> "yes that sounds good":
-- while the mayor's letter is being typed on a PHONE, a small Send button waits beside it, right of the panel and level with
-- the writing box; it sends exactly as the letter's own button does (the text is the draft, kept on every key). Rebuilds
-- PostClient from HudBackup.PostClient_pre_tablet4 + the phone12 block + this. Tablets / computers unchanged. Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
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
-- until the box itself sits just above the keyboard, and a small Send button waits beside it (Shannon: "yes that sounds
-- good") - Done puts the keyboard away and the panel comes back. Studio's practice keyboard draws a bar ~30-40 px above the
-- edge Roblox reports, hence the wide gap. The post box's button is hidden while the panel is open. Computers unchanged.
local GuiService = game:GetService("GuiService")
local TYPE_TOP, TYPE_GAP = 60, 52
local function isTablet()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.zero
	return TOUCH and math.min(vp.X, vp.Y) >= 600
end
local focusedBox, typing = nil, false
-- the phone's Send-while-typing button (right of the panel, level with the box)
local quickSend = Instance.new("TextButton"); quickSend.Name = "QuickSend"; quickSend.AnchorPoint = Vector2.new(0, 0.5)
quickSend.Size = UDim2.fromOffset(86, 40); quickSend.BackgroundColor3 = GOLD; quickSend.BorderSizePixel = 0; quickSend.FontFace = FONT
quickSend.TextSize = 18; quickSend.TextColor3 = BTN_INK; quickSend.Text = "Send"; quickSend.AutoButtonColor = false; quickSend.ZIndex = 20
quickSend.Visible = false; quickSend.Parent = gui
corner(quickSend, UDim.new(0, 10)); stroke(quickSend, RGB(150, 98, 36), 2, 0.2)
local function canSend()
	local n = utf8.len(draft) or #draft
	return status ~= nil and status.open == true and n > 0 and n <= status.max and status.acorns >= status.price
end
local function paintQuick()
	local ok = canSend()
	quickSend.BackgroundColor3 = ok and GOLD or RGB(214, 202, 176); quickSend.TextColor3 = ok and BTN_INK or INK_DIM
end
local sendingQuick = false
quickSend.Activated:Connect(function()
	if sendingQuick or not canSend() then return end
	sendingQuick = true
	local text = draft
	if focusedBox then focusedBox:ReleaseFocus() end
	quickSend.Text = "..."
	local ok, res = call("send", text)
	quickSend.Text = "Send"; sendingQuick = false
	if ok then draft = ""; status = res; flyEnvelope(); say("Posted. The mayor will write back in about a day.", 6); render()
	else say(tostring(res), 4) end
end)
local function rest()                                                       -- back to the normal size and place
	typing = false
	fit()
	panel.Position = UDim2.fromScale(0.5, 0.5)
	task.delay(0.4, function() if not typing then quickSend.Visible = false end end)   -- (a moment, so a tap on it still lands)
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
	-- in the panel's own units: the box's top and bottom, and the lowest thing that must stay in sight on a tablet (a Send just under it)
	local boxTop = (focusedBox.AbsolutePosition.Y + inset - top) / s
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
	local vp = workspace.CurrentCamera.ViewportSize
	if isTablet() then
		local want = math.clamp((kbTop - TYPE_GAP - TYPE_TOP) / bottom, 0.5, scale.Scale)
		scale.Scale = want
		panel.Position = UDim2.new(0.5, 0, 0, TYPE_TOP + H * want / 2)
		quickSend.Visible = false
	else
		local sc = scale.Scale
		local newTop = math.min(TYPE_TOP, kbTop - TYPE_GAP - boxBottom * sc)
		panel.Position = UDim2.new(0.5, 0, 0, newTop + H * sc / 2)
		-- the letter's own Send is under the keyboard now: a small one beside the box (the mayor's letter only, not the dev desk)
		if string.find(focusedBox.PlaceholderText, "^Dear Mayor") then
			local right = vp.X / 2 + W * sc / 2
			local midY = newTop + (boxTop + boxBottom) / 2 * sc
			if vp.X - right - 10 >= 86 + 64 then                             -- (room between the panel and the HUD column)
				quickSend.Position = UDim2.fromOffset(right + 10, midY)
			else                                                              -- (no room: on the panel, just above the box's right end)
				quickSend.Position = UDim2.fromOffset(right - 86 - 16 * sc, newTop + boxTop * sc - 26)
			end
			paintQuick()
			quickSend.Visible = true
		end
	end
	typing = true
end
local textConn
UIS.TextBoxFocused:Connect(function(box)
	if not box:IsDescendantOf(gui) then return end
	focusedBox = box
	if textConn then textConn:Disconnect() end
	textConn = box:GetPropertyChangedSignal("Text"):Connect(function() task.defer(paintQuick) end)   -- (after the page's own handler keeps the draft)
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
		focusedBox = nil; quickSend.Visible = false
		if typing then rest() end
	end
end)
]]
local src = was.Source
local a, b = src:find(anchor, 1, true)
assert(a and not src:find(anchor, b + 1, true), "PostClient backup: anchor not found once - nothing changed")
local newPost = src:sub(1, a - 1) .. block .. src:sub(b + 1)
local bk = post:Clone(); bk.Name = "PostClient_pre_phone21"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(post, function() return newPost end)
return "phone21 installed"

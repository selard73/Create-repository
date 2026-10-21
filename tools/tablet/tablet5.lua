-- tablet5 (Oct 20 2026): replaces tablet4's block in PostClient. tablet4 lifted the panel 158 px so Send sat 10 px above the
-- keyboard Roblox reports (top y 407), but Studio's own keyboard draws a white bar from about y 365, so the Send button
-- touched it on Shannon's screen; and lifting further would push the title under the honours pill. Now, TABLETS ONLY, while
-- the keyboard is out the panel sits just under the top bar (y 60) and shrinks just enough (iPad Air: to ~0.82) that the
-- box and its Send button end 52 px above the keyboard; when the keyboard goes, it is back to its normal size and place.
-- The post box prompt stays hidden while the panel is open (as tablet4). Phones and computers unchanged.
-- Run in Studio EDIT: rebuilds PostClient from HudBackup.PostClient_pre_tablet4 plus this block. No DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local was = backup and backup:FindFirstChild("PostClient_pre_tablet4")
assert(was and not was.Source:find("tablet check", 1, true), "no clean PostClient_pre_tablet4 backup")
local post = workspace.PostOffice.PostClient
local anchor = "task.spawn(hookPrompt)\n"
local add = anchor .. [[

-- (Oct 20 2026, tablet check; Shannon: "please just fix the ipad version for now, we will check and tackle phone next")
-- on a tablet the keyboard covers the bottom half of the screen (iPad Air: y 407-820), which hid the Send button and half
-- the writing box while typing, and the post box's own "Open" button sat on the writing box. TABLETS ONLY: while the
-- keyboard is out the panel sits just under the top bar and shrinks just enough that the box and its Send button end well
-- above the keyboard (Studio's practice keyboard draws a bar ~40 px above the edge Roblox reports, hence the wide gap);
-- the post box's button is hidden while the panel is open. Phones and computers keep everything as it was.
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
	if not (gui.Enabled and focusedBox and focusedBox.Parent and isTablet() and UIS.OnScreenKeyboardVisible) then
		if typing then rest() end
		return
	end
	local kbTop = UIS.OnScreenKeyboardPosition.Y                            -- (real screen space, from the very top)
	local s = panel.AbsoluteSize.Y / H                                      -- the panel's scale right now
	if kbTop <= 0 or s <= 0 then return end
	local inset = GuiService:GetGuiInset().Y
	local top = panel.AbsolutePosition.Y + inset
	-- the lowest thing that must stay in sight, in the panel's own units: the box, and a Send button just under it
	local bottom = (focusedBox.AbsolutePosition.Y + inset + focusedBox.AbsoluteSize.Y - top) / s
	for _, d in ipairs(panel:GetDescendants()) do
		if d:IsA("TextButton") and d.Visible and string.find(d.Text, "^Send") then
			local b = (d.AbsolutePosition.Y + inset + d.AbsoluteSize.Y - top) / s
			if b > bottom and b - bottom < 160 then bottom = b end
		end
	end
	if bottom <= 0 then return end
	fit()
	local want = math.clamp((kbTop - TYPE_GAP - TYPE_TOP) / bottom, 0.5, scale.Scale)
	scale.Scale = want
	panel.Position = UDim2.new(0.5, 0, 0, TYPE_TOP + H * want / 2)
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
		if isTablet() and prompt and prompt.Enabled then prompt.Enabled = false; hiddenPrompt = prompt end
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
local newSrc = src:sub(1, a - 1) .. add .. src:sub(b + 1)
SES:UpdateSourceAsync(post, function() return newSrc end)
return string.format("tablet5 installed: PostClient %d chars (from the pre-tablet4 backup + the new block)", #post.Source)

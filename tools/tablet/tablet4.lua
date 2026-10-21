-- tablet4 (Oct 20 2026): the mayor's letter on a tablet. Shannon: "please just fix the ipad version for now, we will check
-- and tackle phone next". On the iPad Air the keyboard covers y 407-820 (UIS.OnScreenKeyboardPosition/Size), hiding the
-- Send button (y 513-555) and half the writing box while typing, and the post box's "Open" pill sat on the writing box.
-- PostClient, TABLETS ONLY (touch + the screen's short side 600+): the panel slides up while the keyboard is out so the
-- focused box and the Send button just under it sit 10 px above the keyboard; the post box prompt is hidden (locally)
-- while the panel is open. Phones and computers unchanged. Run in Studio EDIT; backs PostClient up first. No DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local post = workspace.PostOffice.PostClient
local anchor = "task.spawn(hookPrompt)\n"
local add = anchor .. [[

-- (Oct 20 2026, tablet check; Shannon: "please just fix the ipad version for now, we will check and tackle phone next")
-- on a tablet the keyboard covers the bottom half of the screen (iPad Air: y 407-820), which hid the Send button and half
-- the writing box while typing, and the post box's own "Open" button sat on the writing box. TABLETS ONLY: the panel
-- slides up while the keyboard is out so the box and its Send button sit just above it, and the post box's button is
-- hidden while the panel is open. Phones and computers keep everything as it was.
local GuiService = game:GetService("GuiService")
local function isTablet()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.zero
	return TOUCH and math.min(vp.X, vp.Y) >= 600
end
local focusedBox
local function applied() return -panel.Position.Y.Offset end          -- how far the panel is lifted right now
local function setLift(px, instant)
	local to = UDim2.new(0.5, 0, 0.5, -px)
	if instant then panel.Position = to; return end
	TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = to}):Play()
end
local function adjust()
	if not (gui.Enabled and focusedBox and focusedBox.Parent and isTablet() and UIS.OnScreenKeyboardVisible) then
		if applied() ~= 0 then setLift(0) end
		return
	end
	local kbTop = UIS.OnScreenKeyboardPosition.Y                            -- (real screen space, from the very top)
	if kbTop <= 0 then return end
	local inset, now = GuiService:GetGuiInset().Y, applied()
	-- the lowest thing that must stay in sight, as it would sit with the panel NOT lifted: the box, and a Send button just under it
	local bottom = focusedBox.AbsolutePosition.Y + inset + focusedBox.AbsoluteSize.Y + now
	for _, d in ipairs(panel:GetDescendants()) do
		if d:IsA("TextButton") and d.Visible and string.find(d.Text, "^Send") then
			local b = d.AbsolutePosition.Y + inset + d.AbsoluteSize.Y + now
			if b > bottom and b - bottom < 140 then bottom = b end
		end
	end
	local top = panel.AbsolutePosition.Y + inset + now                     -- never lift the panel off the top of the screen
	local want = math.clamp(bottom + 10 - kbTop, 0, math.max(0, top - 4))
	if math.abs(want - now) > 1 then setLift(want) end
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
		focusedBox = nil; setLift(0, true)
	end
end)
]]
local src = post.Source
assert(not src:find("tablet check", 1, true), "PostClient already patched")
local a, b = src:find(anchor, 1, true)
assert(a, "PostClient: anchor not found - nothing changed")
assert(not src:find(anchor, b + 1, true), "PostClient: anchor found twice - nothing changed")
local newSrc = src:sub(1, a - 1) .. add .. src:sub(b + 1)
local bk = post:Clone(); bk.Name = "PostClient_pre_tablet4"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(post, function() return newSrc end)
return string.format("tablet4 installed: PostClient %d -> %d chars; backup PostClient_pre_tablet4", #bk.Source, #post.Source)

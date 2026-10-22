-- rugs7 (Oct 21 2026): the desktop zoom. Shannon, after testing rugs6 live on her computer: "for the desktop the arrow
-- does not work because the icons are arranged differently. Just for the desktop version, please do not use the arrow
-- but use a quick zoom in cartoon screen to the passport icon". Where the HUD is a ROW (the Gifts script's own test:
-- not a touch screen - computers, and VR, which shows the same row) the neon arrow is left out and a cartoon iris
-- closes the screen to a gold-rimmed circle round the Passport button for ~1.6 s, then opens again; touch screens
-- (the right-hand column) keep the arrow. The note moves up to DisplayOrder 32 so it sits over the iris (31), which
-- itself sits over the prompt pills (30). Previewed and approved in a play test ("yes please").
-- Run in Studio EDIT. Backs TreehouseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local tc = workspace.Treehouse.TreehouseClient
local src = tc.Source
assert(src:find("rugs6", 1, true), "TreehouseClient: rugs6 is not in - nothing changed")
assert(not src:find("rugs7", 1, true), "TreehouseClient already patched")
local function swap(old, new, what)
	local a, b = src:find(old, 1, true)
	assert(a, "TreehouseClient: " .. what .. " not found - nothing changed")
	assert(not src:find(old, b + 1, true), "TreehouseClient: " .. what .. " found twice - nothing changed")
	src = src:sub(1, a - 1) .. new .. src:sub(b + 1)
end
-- 1. the note over the iris
swap([=[	-- It sits above the prompt pills (PromptTouch, 30) while it shows, and bows out early once any panel opens.]=],
	[=[	-- It sits above the prompt pills (PromptTouch, 30) and the desktop iris (31), and bows out early once a panel opens.]=],
	"the note's comment")
swap([=[tg.Name = "DecorTut"; tg.ResetOnSpawn = false; tg.DisplayOrder = 31; tg.Parent = pg]=],
	[=[tg.Name = "DecorTut"; tg.ResetOnSpawn = false; tg.DisplayOrder = 32; tg.Parent = pg]=], "the note's layer")
-- 2. the iris helpers, just before passportButton
swap([=[	local function passportButton()]=], [=[	-- (rugs7) on a computer (and anything else that lays the HUD out as a ROW - the Gifts script's own test: not a
	-- touch screen) the arrow points the wrong way (hers: "for the desktop the arrow does not work because the icons
	-- are arranged differently"), so there a quick cartoon IRIS zooms in on the Passport button instead (hers: "a
	-- quick zoom in cartoon screen to the passport icon"): the screen closes to a circle round the button with a gold
	-- rim, holds a moment, and opens again. One frame with a huge stroke makes the dark (a stroke draws outside its
	-- frame, so the frame itself is the hole); it opens early if a panel opens.
	local function touchLayout()
		local ok, pi = pcall(function() return UIS.PreferredInput end)
		if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end
		return UIS.TouchEnabled and not UIS.MouseEnabled
	end
	local function irisAt(obj)
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local inset = game:GetService("GuiService"):GetGuiInset()
		local ig = Instance.new("ScreenGui"); ig.Name = "DecorTutIris"; ig.ResetOnSpawn = false; ig.IgnoreGuiInset = true
		ig.DisplayOrder = 31                                              -- over the HUD, panels and prompt pills (30); under the note (32)
		local c = obj.AbsolutePosition + obj.AbsoluteSize / 2 + inset
		local far = 0                                                     -- the farthest screen corner from the button
		for _, k in ipairs({Vector2.new(0, 0), Vector2.new(vp.X, 0), Vector2.new(0, vp.Y), vp}) do far = math.max(far, (k - c).Magnitude) end
		local open, shut = 2 * far + 40, math.max(obj.AbsoluteSize.X, obj.AbsoluteSize.Y) + 48
		local function circle(stroke, colour)
			local f = Instance.new("Frame"); f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromOffset(c.X, c.Y)
			f.Size = UDim2.fromOffset(open, open); f.BackgroundTransparency = 1; f.Parent = ig
			local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0.5, 0); fc.Parent = f
			local fs = Instance.new("UIStroke"); fs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; fs.Color = colour; fs.Thickness = stroke; fs.Parent = f
			return f
		end
		local dark = circle(far + 60, C(16, 12, 26))
		local rim = circle(4, GOLD)
		ig.Parent = pg
		local closing = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		for _, f in ipairs({dark, rim}) do TweenService:Create(f, closing, {Size = UDim2.fromOffset(shut, shut)}):Play() end
		local done = false
		local function reopen()
			if done or not ig.Parent then return end
			done = true
			local opening = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			for _, f in ipairs({dark, rim}) do TweenService:Create(f, opening, {Size = UDim2.fromOffset(open, open)}):Play() end
			Debris:AddItem(ig, 0.45)
		end
		task.delay(1.6, reopen)
		local con; con = pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
			if pg:GetAttribute("OpenPanel") ~= nil then con:Disconnect(); reopen() end
		end)
		task.delay(3, function() if con.Connected then con:Disconnect() end end)
	end
	local function passportButton()]=], "passportButton")
-- 3. step 1: the arrow on touch screens only, the iris everywhere else
swap([=[		local a1 = pb and arrowAt(pb, Vector2.new(1, 0), true)             -- (rugs6) the short neon arrow, from the left]=],
	[=[		local a1 = pb and touchLayout() and arrowAt(pb, Vector2.new(1, 0), true) or nil   -- (rugs6) the neon arrow: touch screens only (rugs7)
		if pb and not touchLayout() then irisAt(pb) end                    -- (rugs7) the HUD row (computers, VR): the cartoon iris]=], "step 1's arrow")
local bk = tc:Clone(); bk.Name = "TreehouseClient_pre_rugs7"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(tc, function() return src end)
print(string.format("rugs7: TreehouseClient -> %d chars", #tc.Source))
return "rugs7 installed"

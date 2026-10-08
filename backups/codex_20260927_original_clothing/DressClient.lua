
-- DressClient: the door fades, and the mirror - the camera turns round to be the mirror, the Chapelier's panel beside
-- you, every hat a little 3D picture; tap one to try it on (on your screen only), then buy it or wear it
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = RS:WaitForChild("DressShopEvent")
local action = RS:WaitForChild("DressShopAction")
local kit = RS:WaitForChild("DressKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local RGB = Color3.fromRGB
-- the Acorn Store's own colours, so this reads as another page of the same book
local FACE, FACE_DEEP, RIM = RGB(255, 246, 220), RGB(250, 235, 201), RGB(226, 175, 68)
local SLOT, SLOT_EDGE = RGB(242, 229, 203), RGB(218, 174, 83)
local INK, INK_DIM, GOLD, BTN_INK = RGB(64, 42, 22), RGB(132, 108, 80), RGB(255, 202, 62), RGB(84, 48, 18)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o; return c end
local function stroke(o, col, th, tr) local s = Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color = col; s.Thickness = th; s.Transparency = tr or 0; s.Parent = o; return s end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- ---- the fade for the doors, and the door's sound
local fadeGui = Instance.new("ScreenGui"); fadeGui.Name = "DressShopFade"; fadeGui.ResetOnSpawn = false; fadeGui.IgnoreGuiInset = true; fadeGui.DisplayOrder = 20; fadeGui.Parent = pg
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.Visible=false; black.Parent = fadeGui
local fadeRevision=0
local doorSfx = Instance.new("Sound"); doorSfx.SoundId = F:GetAttribute("DoorSound") or ""; doorSfx.Volume = F:GetAttribute("DoorVolume") or 0.6; doorSfx.Parent = fadeGui

-- ---- the panel
local gui = Instance.new("ScreenGui"); gui.Name = "DressShopGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 18; gui.Enabled = false; gui.Parent = pg
local W, H = 320, 410
local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(1, 0.5); panel.Position = UDim2.new(1, -16, 0.5, 0)
panel.Size = UDim2.fromOffset(W, H); panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.Parent = gui
corner(panel, 22); stroke(panel, RIM, 4)
local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 W=math.min(350,math.floor(vp.X*.49)-12);H=math.min(480,math.floor(vp.Y)-40)
 panel.Size=UDim2.fromOffset(W,H);panel.Position=UDim2.new(1,-12,.5,8)
end
local title = Instance.new("TextLabel"); title.Position = UDim2.fromOffset(20, 14); title.Size = UDim2.fromOffset(100, 30); title.BackgroundTransparency = 1
title.Text = "Boutique"; title.TextXAlignment = Enum.TextXAlignment.Left; title.FontFace = FONT; title.TextSize = 22; title.TextColor3 = RGB(58, 36, 16); title.Parent = panel
local purse = Instance.new("TextLabel"); purse.AnchorPoint = Vector2.new(1, 0); purse.Position = UDim2.new(1, -56, 0, 16); purse.Size = UDim2.fromOffset(89, 28)
purse.BackgroundColor3 = SLOT; purse.BorderSizePixel = 0; purse.FontFace = FONT; purse.TextSize = 12; purse.TextColor3 = INK; purse.Text = ""; purse.Parent = panel
corner(purse, 10); stroke(purse, SLOT_EDGE, 2, 0.3)
local close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -10, 0, 10); close.Size = UDim2.fromOffset(40, 40)
close.BackgroundColor3 = SLOT; close.BorderSizePixel = 0; close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = INK; close.Text = "X"; close.AutoButtonColor = false; close.Parent = panel
corner(close, 10); stroke(close, SLOT_EDGE, 2, 0.3)
local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(14, 98); list.Size = UDim2.new(1, -28, 1, -98 - 119)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Active=true; list.ScrollingDirection=Enum.ScrollingDirection.Y; list.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 8); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list
-- the foot of the panel: the hat you are trying, what it costs, and the buttons
local foot = Instance.new("Frame"); foot.AnchorPoint = Vector2.new(0, 1); foot.Position = UDim2.new(0, 14, 1, -12); foot.Size = UDim2.new(1, -28, 0, 106)
foot.BackgroundColor3 = FACE_DEEP; foot.BorderSizePixel = 0; foot.Parent = panel
corner(foot, 14); stroke(foot, SLOT_EDGE, 2, 0.45)
local picked = Instance.new("TextLabel"); picked.Position = UDim2.fromOffset(12, 6); picked.Size = UDim2.new(1, -24, 0, 22); picked.BackgroundTransparency = 1
picked.FontFace = FONT; picked.TextSize = 14; picked.TextColor3 = RGB(58, 36, 16); picked.TextXAlignment = Enum.TextXAlignment.Left; picked.TextTruncate = Enum.TextTruncate.AtEnd
picked.Text = "Choose a style to try on"; picked.Parent = foot
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0, 0); note.Position = UDim2.fromOffset(12, 28); note.Size = UDim2.new(1,-24,0,16); note.BackgroundTransparency = 1
note.Font = Enum.Font.BuilderSans; note.TextSize = 13; note.TextXAlignment = Enum.TextXAlignment.Left; note.TextTransparency = 1; note.Text = ""; note.Parent = foot
local function button(text, pos, size, colour)
	local b = Instance.new("TextButton"); b.Position = pos; b.Size = size; b.BackgroundColor3 = colour; b.BorderSizePixel = 0; b.AutoButtonColor = false
	b.FontFace = FONT; b.TextSize = 14; b.TextColor3 = BTN_INK; b.Text = text; b.Parent = foot
	corner(b, 10); stroke(b, RGB(150, 98, 36), 2, 0.2)
	return b
end
local main = button("", UDim2.fromOffset(12, 51), UDim2.new(1, -112, 0, 42), GOLD)
local bare = button("Take off", UDim2.new(1, -92, 0, 51), UDim2.fromOffset(80, 42), RGB(214, 202, 176))
local function say(text, good)
	note.Text = text; note.TextColor3 = good and RGB(64, 112, 48) or RGB(150, 52, 30); note.TextTransparency = 0
	TweenService:Create(note, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.4), {TextTransparency = 1}):Play()
end

-- a little 3D picture of a hat
local function picture(id, parent)
	local vf = Instance.new("ViewportFrame"); vf.Size = UDim2.fromScale(1, 1); vf.BackgroundTransparency = 1; vf.Ambient = RGB(200, 190, 180)
	vf.LightColor = RGB(255, 246, 230); vf.LightDirection = Vector3.new(-.6,-.5,-1); vf.Parent = parent
	local m = Instance.new("Model")
	for _, p in ipairs(Cat.pieces(kit, id, CFrame.new(), 1)) do p.Anchored = true; p.Parent = m end
	m.Parent = vf
	local cf, size = m:GetBoundingBox()
	local cam = Instance.new("Camera"); cam.FieldOfView = 30
	local dist = math.max(size.X, size.Y * 1.4) / (2 * math.tan(math.rad(15))) * 1.12
	local dir = Vector3.new(0.22,0.1,-1).Unit
	cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
	cam.Parent = vf; vf.CurrentCamera = cam
	return vf
end

local tiles, sections = {}, {}
local selected
local activeSlot="dress"
local activeCategory="dress"
local busy=false
local categoryButtons={}
local function owned(id) return (player:GetAttribute("Item_dress_" .. id) or 0) > 0 end
local function wornId(slot)
 slot=slot or activeSlot
 for _,id in ipairs(Cat.order)do if Cat.slot(id)==slot and (player:GetAttribute("Item_dresswear_"..id) or 0)>0 then return id end end
end
local function priceOf(styleId) return F:GetAttribute("Price_" .. styleId) end
for i,choice in ipairs({{"dress","Dresses"},{"outfit","Outfits"},{"eyewear","Shades"},{"necklace","Jewels"}})do
 local b=Instance.new("TextButton");b.Name="Category_"..choice[1];b.Position=UDim2.new((i-1)/4,14-(i-1)*6,0,53);b.Size=UDim2.new(1/4,-13,0,38);b.BackgroundColor3=SLOT;b.BorderSizePixel=0;b.FontFace=FONT;b.TextSize=13;b.TextColor3=INK;b.Text=choice[2];b.Parent=panel;corner(b,11)
 categoryButtons[choice[1]]=b
end
for i, s in ipairs(Cat.styles) do
	local sec = Instance.new("Frame"); sec.Name = s.id; sec.Size = UDim2.new(1, -6, 0, 140); sec.BackgroundColor3 = FACE_DEEP; sec.BorderSizePixel = 0
	sec.LayoutOrder = i; sec.Visible=Cat.category(s)==activeCategory;sec.Parent = list
	corner(sec, 14); stroke(sec, SLOT_EDGE, 2, 0.45)
	local nm = Instance.new("TextLabel"); nm.Position = UDim2.fromOffset(12, 6); nm.Size = UDim2.new(1,-86,0,20); nm.BackgroundTransparency = 1
	nm.FontFace = FONT; nm.TextSize = 13; nm.TextColor3 = RGB(58, 36, 16); nm.TextXAlignment = Enum.TextXAlignment.Left; nm.Text = s.name; nm.Parent = sec
	local pr = Instance.new("TextLabel"); pr.AnchorPoint = Vector2.new(1, 0); pr.Position = UDim2.new(1, -12, 0, 8); pr.Size = UDim2.fromOffset(76, 18)
	pr.BackgroundTransparency = 1; pr.FontFace = FONT; pr.TextSize = 11; pr.TextColor3 = INK_DIM; pr.TextXAlignment = Enum.TextXAlignment.Right; pr.Parent = sec
	sections[s.id] = {frame = sec, price = pr}
	for k = 1, #s.colours do
		local id = s.id .. "_" .. k
		local t = Instance.new("TextButton"); t.Name = id; t.Text = ""; t.AutoButtonColor = false; t.BackgroundColor3 = FACE; t.BorderSizePixel = 0
		t.Size = UDim2.new(1/3,-12,0,98); t.Position = UDim2.new((k-1)/3,7,0,32); t.Parent = sec
		corner(t, 12)
		local st = stroke(t, SLOT_EDGE, 2, 0.35)
		local pic = picture(id, t); pic.Name="ProductPreview";pic.Size = UDim2.new(1, -8, 1, -33); pic.Position = UDim2.fromOffset(4, 2)
		local tag = Instance.new("TextLabel"); tag.AnchorPoint = Vector2.new(0.5, 1); tag.Position = UDim2.new(0.5, 0, 1, -3); tag.Size = UDim2.fromOffset(70, 14)
		tag.BackgroundTransparency = 1; tag.FontFace = FONT; tag.TextSize = 11; tag.TextColor3 = RGB(64, 112, 48); tag.Text = ""; tag.Parent = t
		local color=Instance.new("TextLabel");color.Name="Colour";color.BackgroundTransparency=1;color.Position=UDim2.new(0,2,1,-31);color.Size=UDim2.new(1,-4,0,14);color.Font=Enum.Font.BuilderSans;color.TextSize=11;color.TextColor3=INK;color.Text=s.colours[k].name;color.Parent=t
        tiles[id] = {button = t, stroke = st, tag = tag}
	end
end

-- Trying on is local. Keep covered body parts hidden after the camera's
-- transparency update, which can reset LocalTransparencyModifier on camera changes.
local preview
local hiddenParts = {}
local hiddenClothing={}
local PREVIEW_COVERAGE="BoutiquePreviewCoverage"
local function maintainPreviewCoverage()
 for p in pairs(hiddenParts)do
  if p.Parent and p.LocalTransparencyModifier~=1 then p.LocalTransparencyModifier=1 end
 end
end
local function hideWorn(hide)
 local char=player.Character
 if hide and char then
  for _,entry in ipairs(Cat.clothing(char,selected)) do local o,key=entry[1],entry[2];if hiddenClothing[o]==nil then hiddenClothing[o]={key,o[key]} end;o[key]="" end
  local all=Cat.covered(char,selected);local w=char:FindFirstChild(Cat.models[Cat.slot(selected)])
  if w then for _,p in ipairs(w:GetDescendants()) do if p:IsA("BasePart") then table.insert(all,p) end end end
  for _,p in ipairs(all) do if hiddenParts[p]==nil then hiddenParts[p]=p.LocalTransparencyModifier end;p.LocalTransparencyModifier=1 end
  RunService:BindToRenderStep(PREVIEW_COVERAGE,Enum.RenderPriority.Last.Value,maintainPreviewCoverage)
 else
  RunService:UnbindFromRenderStep(PREVIEW_COVERAGE)
  for o,v in pairs(hiddenClothing) do if o.Parent then o[v[1]]=o:GetAttribute("DressClothingWas")~=nil and "" or v[2] end end;hiddenClothing={}
  for p,was in pairs(hiddenParts) do if p.Parent then p.LocalTransparencyModifier=was end end;hiddenParts={}
 end
end
local function clearPreview() if preview then preview:Destroy();preview=nil end end
script.Destroying:Connect(function() clearPreview();hideWorn(false) end)
local function tryOn(id)
 clearPreview();hideWorn(false)
 local char=player.Character;if not char then return end
 preview=Cat.attach(kit,id,char,"DressPreview");hideWorn(true)
end

local function refresh()
 for slot,b in pairs(categoryButtons)do b.BackgroundColor3=slot==activeCategory and GOLD or SLOT end
	purse.Text = tostring(player:GetAttribute("Acorns") or 0) .. "  acorns"
	local have = player:GetAttribute("Acorns") or 0
	local on = wornId()
	for _, s in ipairs(Cat.styles) do
		local p = priceOf(s.id)
		sections[s.id].price.Text = p and (tostring(p) .. " acorns") or ""
	end
	for id, t in pairs(tiles) do
		local mine, wearing = owned(id), (id == wornId(Cat.slot(id)))
		t.tag.Text = wearing and "wearing" or (mine and "yours" or "")
		t.tag.TextColor3 = wearing and RGB(170, 110, 20) or RGB(64, 112, 48)
		local sel = (id == selected)
		t.stroke.Color = sel and GOLD or (wearing and RGB(200, 150, 48) or SLOT_EDGE)
		t.stroke.Thickness = sel and 3 or 2; t.stroke.Transparency = sel and 0 or 0.35
		t.button.BackgroundColor3 = sel and RGB(255, 248, 228) or FACE
	end
	if not selected then
		picked.Text = on and ("You're wearing the " .. Cat.title(on):lower()) or "Choose a style to try on"
		main.Text = "Choose a style"; main.BackgroundColor3 = RGB(214, 202, 176); main.TextColor3 = INK_DIM
	else
		local h = Cat.byId[selected]
		picked.Text = Cat.title(selected)
		if selected == on then
			main.Text = "Wearing"; main.BackgroundColor3 = RGB(214, 202, 176); main.TextColor3 = INK_DIM
		elseif owned(selected) then
			main.Text = "Wear it"; main.BackgroundColor3 = GOLD; main.TextColor3 = BTN_INK
		else
			local p = priceOf(h.style.id) or 0
			main.Text = "Buy - " .. tostring(p) .. " acorns"
			local can = have >= p
			main.BackgroundColor3 = can and GOLD or RGB(214, 202, 176); main.TextColor3 = can and BTN_INK or INK_DIM
		end
	end
	bare.BackgroundColor3 = on and RGB(214, 202, 176) or RGB(228, 218, 196)
end
for slot,b in pairs(categoryButtons)do
 b.Activated:Connect(function()
  if busy then return end
  clearPreview();hideWorn(false);selected=nil;activeCategory=slot;activeSlot=slot=="outfit" and "dress" or slot
  for _,style in ipairs(Cat.styles)do sections[style.id].frame.Visible=Cat.category(style)==slot end
  list.CanvasPosition=Vector2.zero;refresh()
 end)
end
for id, t in pairs(tiles) do
 t.button.Activated:Connect(function()
		if busy then return end
		selected = id
		tryOn(id)
		refresh()
	end)
end

main.Activated:Connect(function()
	if busy or not selected then return end
	local on = wornId()
	if selected == on then return end
	busy = true
	local what = owned(selected) and "wear" or "buy"
	if what == "buy" then
		local p = priceOf(Cat.byId[selected].style.id) or 0
		if (player:GetAttribute("Acorns") or 0) < p then busy = false; say("not enough acorns", false) return end
	end
	main.Text = "..."
	local want = selected
	local ok, res, why = pcall(function() return action:InvokeServer(what, want) end)
	busy = false
	if not ok then say("the shop did not answer", false)
	elseif res then
		say(what == "buy" and "it's yours!" or "on it goes", true)
		-- the real one arrives from the server in a moment: then the try-on steps down, so there are never two
		task.spawn(function()
			local char = player.Character
			for _ = 1, 40 do
				local w = char and char:FindFirstChild(Cat.models[Cat.slot(want)])
				if w and w:GetAttribute("DressId") == want then break end
				task.wait(0.05)
			end
			if selected == want and preview then clearPreview(); hideWorn(false) end
		end)
	else say(tostring(why or "no"), false) end
	refresh()
end)
bare.Activated:Connect(function()
	if busy then return end
	selected = nil
	clearPreview(); hideWorn(false)
	busy = true
	local ok,res,why=pcall(function() return action:InvokeServer("off", activeSlot) end)
	busy = false
	say(ok and res and "Taken off" or tostring(why or "Try again"),ok and res)
	refresh()
end)

-- ---- at the mirror: stand on the rug facing it, the camera becomes the mirror, the rest of the screen steps aside
local open = false
local savedGuis, backpackWas, camWas = {}, nil, nil
-- you stay on the rug while the panel is open: the walking keys (and a pad's stick and jump) are swallowed here, at a
-- higher priority than the controls; on a phone the joystick is hidden with the rest of the screen. (This game's
-- PlayerScripts has no PlayerModule to switch the controls off with - waiting for one stalled this script.)
local CAS = game:GetService("ContextActionService")
local FREEZE = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left,
	Enum.KeyCode.Right, Enum.KeyCode.Space, Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA}
local function stepAside(on)
	if on then
		savedGuis = {}
		for _, g in ipairs(pg:GetChildren()) do
			if (g:IsA("ScreenGui") or g:IsA("BillboardGui")) and g ~= gui and g ~= fadeGui and g.Enabled then savedGuis[g] = true; g.Enabled = false end
		end
		-- and your own name tag over your head (on a phone the mirror's framing put it beside Roblox's buttons)
		local char = player.Character
		for _, g in ipairs(char and char:GetDescendants() or {}) do
			if g:IsA("BillboardGui") and g.Enabled then savedGuis[g] = true; g.Enabled = false end
		end
		pcall(function() backpackWas = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
		CAS:BindActionAtPriority("DressMirrorStay", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value + 100, table.unpack(FREEZE))
	else
		for g in pairs(savedGuis) do if g.Parent then g.Enabled = true end end
		savedGuis = {}
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, backpackWas ~= false) end)
		CAS:UnbindAction("DressMirrorStay")
	end
end
local function mirrorPrompt() return F:FindFirstChild("MirrorPrompt", true) end
local function setOpen(on)
	if on == open then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	local cam = workspace.CurrentCamera
	if on and not (hrp and hum and head and cam) then return end
	open = on
	local mp = mirrorPrompt()
	if on then
		if mp then mp.Enabled = false end
		-- on the rug, facing the glass
		local spot = v3("Spot")
		local toMirror = (Vector3.new(F:GetAttribute("MirrorX"), 0, F:GetAttribute("MirrorZ")) - Vector3.new(spot.X, 0, spot.Z)).Unit
		local legs = hum.HipHeight + hrp.Size.Y / 2
		local at = spot + Vector3.new(0, legs + 0.05, 0)
		hrp.CFrame = CFrame.lookAt(at, at + toMirror)
		hrp.AssemblyLinearVelocity = Vector3.zero
		stepAside(true)
		gui.Enabled = true
		fit()
		-- the camera stands where the glass is, looking back at your face; you on the left, the panel on the right
		task.defer(function()
            if not open or player.Character~=char then return end
			local hp = hrp.Position - Vector3.new(0,.2,0)
			local camRight = (-toMirror):Cross(Vector3.new(0, 1, 0))
			camWas = cam.CameraType
			cam.CameraType = Enum.CameraType.Scriptable
			local eye = hp + toMirror * 7.3 + camRight * 0.4 + Vector3.new(0, 0.2, 0)      -- (nearly level: from above, a brim hid the eyes)
			cam.CFrame = CFrame.lookAt(eye, hp + camRight * 2.7)
		end)
		selected = nil
		refresh()
	else
		gui.Enabled = false
		clearPreview(); hideWorn(false)
		selected = nil
		stepAside(false)
		cam.CameraType = (camWas and camWas ~= Enum.CameraType.Scriptable) and camWas or Enum.CameraType.Custom
		if mp then mp.Enabled = true end
	end
end
close.Activated:Connect(function() setOpen(false) end)
game:GetService("UserInputService").InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.Escape and open then setOpen(false) end end)
player.CharacterAdded:Connect(function() if open then open = true; setOpen(false) end end)
player:GetAttributeChangedSignal("Acorns"):Connect(function() if open then refresh() end end)
player.AttributeChanged:Connect(function(name) if open and (name:sub(1, 11) == "Item_dress_" or name:sub(1, 15) == "Item_dresswear_") then refresh() end end)
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end)

ev.OnClientEvent:Connect(function(what, a)
	if what == "fade" then
        fadeRevision+=1;black.Visible=true
        if open then setOpen(false) end
		doorSfx.TimePosition = 0; doorSfx:Play()
		TweenService:Create(black, TweenInfo.new(a or 0.45), {BackgroundTransparency = 0}):Play()
	elseif what == "unfade" then
		-- A transparent fullscreen frame still intercepts scroll input; remove it after the transition.
        fadeRevision+=1;local revision=fadeRevision
        local fade=TweenService:Create(black, TweenInfo.new((a or 0.45) * 1.4), {BackgroundTransparency = 1})
        fade.Completed:Once(function(state)if revision==fadeRevision and state==Enum.PlaybackState.Completed then black.Visible=false end end)
        fade:Play()
	elseif what == "mirror" then
		setOpen(true)
	end
end)

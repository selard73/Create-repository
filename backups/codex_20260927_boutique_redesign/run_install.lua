-- DRESS SHOP v1: EDIT ONLY; isolated boutique, no village rebuild.
assert(not game:GetService("RunService"):IsRunning(),"Edit only")
local build=(function()
-- Mode et Style dress boutique, original 9-dress collection. Draft; publish separately after review.
return function(opts)
 opts=opts or {};local RS=game:GetService("ReplicatedStorage");local CS=game:GetService("CollectionService");local C=Color3.fromRGB;local rng=Random.new(2710)
 local kit=assert(RS:FindFirstChild("DressKit"),"Import Dresses.obj and run kit installer first")
 local CAT=[====[
-- Original boutique dresses. Separate torso and skirt fitting supports R6 and R15.
local C=Color3.fromRGB
local M={}
M.styles={
 {id='rue',name='Rue sundress',price=60,length=1.65,colours={
  {name='Buttercup',fabric=C(240,192,75),trim=C(255,244,212)},
  {name='Rose',fabric=C(192,100,116),trim=C(255,229,197)},
  {name='Pine',fabric=C(39,103,69),trim=C(226,184,94)}}},
 {id='cafe',name='Cafe day dress',price=90,length=1.95,colours={
  {name='Rust',fabric=C(170,79,47),trim=C(249,220,178)},
  {name='Blueberry',fabric=C(53,64,113),trim=C(247,218,165)},
  {name='Honey',fabric=C(202,151,54),trim=C(89,58,41)}}},
 {id='chateau',name='Chateau evening',price=140,length=2.5,colours={
  {name='Midnight',fabric=C(43,43,73),trim=C(229,187,94)},
  {name='Burgundy',fabric=C(129,41,62),trim=C(239,197,119)},
  {name='Ivory',fabric=C(245,233,206),trim=C(175,126,44)}}}
}
M.byId={};M.byStyle={};M.order={}
for _,s in ipairs(M.styles) do M.byStyle[s.id]=s;for k,c in ipairs(s.colours) do
 local id=s.id..'_'..k;M.byId[id]={id=id,style=s,colour=c};table.insert(M.order,id)
end end
function M.title(id) local d=M.byId[id];return d and (d.colour.name..' '..d.style.name) or '' end
M.centres={["Bodice_rue"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_rue"]=Vector3.new(0.000000,-0.825000,0.000000),["Belt_rue"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_rue"]=Vector3.new(0.000000,-1.602500,0.000000),["Collar_rue"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_cafe"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_cafe"]=Vector3.new(0.000000,-0.975000,0.000000),["Belt_cafe"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_cafe"]=Vector3.new(0.000000,-1.902500,0.000000),["Collar_cafe"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_chateau"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_chateau"]=Vector3.new(0.000000,-1.250000,0.000000),["Belt_chateau"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_chateau"]=Vector3.new(0.000000,-2.452500,0.000000),["Collar_chateau"]=Vector3.new(0.000000,0.983500,0.000000)}
M.sizes={["Bodice_rue"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_rue"]=Vector3.new(3.045000,1.650000,2.375100),["Belt_rue"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_rue"]=Vector3.new(3.061240,0.075000,2.391340),["Collar_rue"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_cafe"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_cafe"]=Vector3.new(3.536000,1.950000,2.758080),["Belt_cafe"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_cafe"]=Vector3.new(3.552640,0.075000,2.774720),["Collar_cafe"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_chateau"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_chateau"]=Vector3.new(3.845600,2.500000,2.999568),["Belt_chateau"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_chateau"]=Vector3.new(3.861792,0.075000,3.015760),["Collar_chateau"]=Vector3.new(0.960000,0.057000,0.794000)}
local function mult(a,b) return Vector3.new(a.X*b.X,a.Y*b.Y,a.Z*b.Z) end
-- cf is waist centre; reference torso occupies y=0..2, skirt y=0 downward.
function M.pieces(kit,id,cf,s)
 local d=M.byId[id];if not d then return {} end
 s=type(s)=='number' and Vector3.new(s,s,s) or s or Vector3.one
 local out={}
 for _,prefix in ipairs({'Bodice_','Skirt_','Belt_','Hem_','Collar_'}) do
  local name=prefix..d.style.id;local p=assert(kit:FindFirstChild(name),'Missing dress mesh '..name):Clone()
  local center=M.centres[name];if prefix=='Bodice_' or prefix=='Collar_' then center+=Vector3.new(0,1,0) end
  p.Size=mult(M.sizes[name],s);p.CFrame=cf*CFrame.new(mult(center,s))
  p.Color=(prefix=='Bodice_' or prefix=='Skirt_') and d.colour.fabric or d.colour.trim
  p.TextureID='';p.Material=Enum.Material.Fabric;p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true
  p:SetAttribute('DressSection',(prefix=='Bodice_' or prefix=='Collar_') and 'upper' or 'lower')
  table.insert(out,p)
 end
 return out
end
function M.attach(kit,id,char,name)
 local upper=char:FindFirstChild('UpperTorso') or char:FindFirstChild('Torso')
 local lower=char:FindFirstChild('LowerTorso') or upper
 if not upper or not lower or not M.byId[id] then return nil end
 local scale=Vector3.new(math.clamp(upper.Size.X/2,0.45,2),math.clamp(upper.Size.Y/2,0.4,2),math.clamp(upper.Size.Z/1.1,0.45,2))
 -- Use standing height, avoiding inflated mesh bounds on stylized legs.
 local hum=char:FindFirstChildOfClass('Humanoid');local root=char:FindFirstChild('HumanoidRootPart')
 local waist=upper.CFrame*CFrame.new(0,-upper.Size.Y/2,0)
 local floorY=root and (root.Position.Y-root.Size.Y/2-(hum and hum.HipHeight or 2)) or (waist.Position.Y-2.5)
 if lower==upper then floorY=waist.Position.Y-2 end
 local height=math.max(1.4,waist.Position.Y-floorY-.12)
 local skirtScale=Vector3.new(scale.X*1.23,math.clamp(height/2.5,.45,2),scale.Z*1.7)
 local lowerWaist=waist
 local m=Instance.new('Model');m.Name=name or 'WornDress';m:SetAttribute('DressId',id)
 for _,p in ipairs(M.pieces(kit,id,CFrame.new(),1)) do
  local top=p:GetAttribute('DressSection')=='upper';local sc=top and scale or skirtScale
  p.Size=mult(p.Size,sc);p.CFrame=(top and waist or lowerWaist)*CFrame.new(mult(p.Position,sc));p.Parent=m
  local weld=Instance.new('WeldConstraint');weld.Part0=upper;weld.Part1=p;weld.Parent=p
 end
 m.Parent=char;return m
end
-- Only costume-covered layers are hidden; hair, hats, face accessories and shoes stay.
function M.covered(char,id)
 local out={}
 for _,o in ipairs(char:GetChildren()) do
  if o:IsA('BasePart') and (o.Name=='UpperTorso' or o.Name=='LowerTorso' or o.Name=='Torso' or o.Name=='LeftUpperLeg' or o.Name=='RightUpperLeg' or ((id or ''):sub(1,7)=='chateau' and (o.Name=='LeftLowerLeg' or o.Name=='RightLowerLeg'))) then table.insert(out,o)
  elseif o:IsA('Accessory') then
   local t=o.AccessoryType.Name
   if t=='Jacket' or t=='Sweater' or t=='Shirt' or t=='TShirt' or t=='DressSkirt' or t=='Waist' or t=='Pants' or t=='Shorts' then
    for _,p in ipairs(o:GetDescendants()) do if p:IsA('BasePart') then table.insert(out,p) end end
   end
  end
 end
 return out
end
function M.clothing(char)
 local out={}
 for _,o in ipairs(char:GetChildren()) do
  if o:IsA('Shirt') then table.insert(out,{o,'ShirtTemplate'})
  elseif o:IsA('Pants') then table.insert(out,{o,'PantsTemplate'})
  elseif o:IsA('ShirtGraphic') then table.insert(out,{o,'Graphic'}) end
 end
 return out
end
return M


]====]
 local SERVER=[====[
-- DressServer: the doors, buying, wearing, and dressing everyone in the hat they chose
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local F = script.Parent
local action = RS:WaitForChild("DressShopAction")
local ev = RS:WaitForChild("DressShopEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local kit = RS:WaitForChild("DressKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end
local function owns(player, id) return (player:GetAttribute("Item_dress_" .. id) or 0) > 0 end
local function worn(player)                                -- the Item_dresswear_<id> that is 1
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 15) == "Item_dresswear_" and (tonumber(v) or 0) > 0 and Cat.byId[name:sub(16)] then return name:sub(16) end
	end
	return nil
end

-- ---- wearing: the chosen hat as an Accessory at the head's HatAttachment, sized to the head; the avatar's own hats
-- are hidden while it is on (and shown again when it comes off)
local function uncover(char)
 for _,entry in ipairs(Cat.clothing(char)) do local o,key=entry[1],entry[2];local was=o:GetAttribute("DressClothingWas");if was~=nil then o[key]=was;o:SetAttribute("DressClothingWas",nil) end end
 for _,p in ipairs(char:GetDescendants()) do
  if p:IsA("BasePart") then local was=p:GetAttribute("DressWas");if was~=nil then p.Transparency=was;p:SetAttribute("DressWas",nil) end end
 end
end
local function cover(char,id)
 for _,entry in ipairs(Cat.clothing(char)) do local o,key=entry[1],entry[2];if o:GetAttribute("DressClothingWas")==nil then o:SetAttribute("DressClothingWas",o[key]) end;o[key]="" end
 for _,p in ipairs(Cat.covered(char,id)) do if p:GetAttribute("DressWas")==nil then p:SetAttribute("DressWas",p.Transparency) end;p.Transparency=1 end
end
local function dress(player)
 local char=player.Character;if not char then return end
 local id=worn(player);local cur=char:FindFirstChild("WornDress")
 if cur and cur:GetAttribute("DressId")==id and owns(player,id) then cover(char,id);return end
 if cur then cur:Destroy() end;uncover(char)
 if id and owns(player,id) and Cat.attach(kit,id,char,"WornDress") then cover(char,id) end
end
local pending = {}
local function redress(player)                             -- once, shortly: a swap changes two ledger lines
	if pending[player] then return end
	pending[player] = true
	task.delay(0.2, function() pending[player] = nil; dress(player) end)
end

-- ---- the doors: fade, move, unfade (the client draws the fade; the server moves you while it is dark); inside, the
-- camera is leashed so it cannot be scrolled out through the walls
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom, moving = {}, {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
 local target=toInside and F.DoorPad.Position or F.Room.Door.Position
 if (hrp.Position-target).Magnitude>12 then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			end
			char:SetAttribute("InDressShop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "MirrorPrompt" then
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if root and (root.Position-prompt.Parent.Position).Magnitude<=13 then ev:FireClient(player,"mirror") end end
end)

-- ---- buying and wearing, asked by the client; decided here
local busy, lastCall = {}, {}
local function wear(player, id)
	local cur = worn(player)
	if cur == id then return end
	if cur then awardItems:Fire(player, "dresswear_" .. cur, -1) end
	if id then awardItems:Fire(player, "dresswear_" .. id, 1) end
end
local function request(player, what, id)
 if type(what)~="string" or type(id)~="string" then return false,"Choose a dress" end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or (root.Position-v3("Spot")).Magnitude>14 then return false,"Visit the boutique mirror" end
 if not player:GetAttribute("SaveLoaded") then return false,"Your wardrobe is still loading" end
 local now=os.clock();if busy[player] or now-(lastCall[player] or 0)<0.25 then return false,"One moment" end;lastCall[player]=now

	if what == "wear" then
		if id == "" or id == nil then wear(player, nil); return true end
		if type(id) ~= "string" or not Cat.byId[id] then return false, "Unknown dress" end
		if not owns(player, id) then return false, "Buy this dress first" end
		wear(player, id)
		return true
	elseif what == "buy" then
		if type(id) ~= "string" or not Cat.byId[id] then return false, "Unknown dress" end
		if owns(player, id) then return false, "it's already yours" end
		if busy[player] then return false, "one at a time" end
		busy[player] = true
		local ok, res, why = pcall(function()
			local price = F:GetAttribute("Price_" .. Cat.byId[id].style.id)
			if type(price) ~= "number" or price~=price or price<0 or price%1~=0 then return false, "no price set" end
			local have = player:GetAttribute("Acorns") or 0     -- the purse as the SERVER sees it
			if have < price then return false, "not enough acorns" end
			awardAcorns:Fire(player, -price)                   -- spending is a negative award, same ledger, same merge
			player:SetAttribute("Acorns", have - price)
			awardItems:Fire(player, "dress_" .. id, 1)
			task.wait()
			wear(player, id)
			task.wait()
			return true, price
		end)
		busy[player] = nil
		if not ok then warn("DressServer: buying " .. tostring(id) .. " failed - " .. tostring(res)); return false, "something went wrong" end
		if res then print(string.format("DressShop: %s bought the %s for %d acorns", player.Name, Cat.title(id), why)) end
		return res, why
	end
	return false, "Unknown action"
end
action.OnServerInvoke=request

local function watch(player)
	player.CharacterAdded:Connect(function(char)
		leash(player, false)
		task.delay(1.2, function() if player.Character == char then dress(player) end end)
	end)
	player.CharacterAppearanceLoaded:Connect(function() redress(player) end)
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 15) == "Item_dresswear_" or name:sub(1, 11) == "Item_dress_" then redress(player) end
	end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function() redress(player) end)
	if player.Character then dress(player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil; busy[p] = nil; moving[p] = nil;lastCall[p]=nil;pending[p]=nil end)
-- Studio tests: give a hat and/or wear it without acorns (never in a live game)
local dbg = F:FindFirstChild("DressDebug")
if dbg and RunService:IsStudio() then
	dbg.OnInvoke = function(player, what, id)
		if what == "request" then return request(player,id[1],id[2])
        elseif what == "give" then awardItems:Fire(player, "dress_" .. id, 1)
			task.wait() return true
		elseif what == "wear" then wear(player, id) return true
		elseif what == "in" then through(player, true) return true
		elseif what == "out" then through(player, false) return true end
	end
end
print("DressServer: ready")

]====]
 local CLIENT=[====[

-- DressClient: the door fades, and the mirror - the camera turns round to be the mirror, the Chapelier's panel beside
-- you, every hat a little 3D picture; tap one to try it on (on your screen only), then buy it or wear it
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
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
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.Parent = fadeGui
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
local title = Instance.new("TextLabel"); title.Position = UDim2.fromOffset(20, 14); title.Size = UDim2.fromOffset(112, 30); title.BackgroundTransparency = 1
title.Text = "Boutique"; title.TextXAlignment = Enum.TextXAlignment.Left; title.FontFace = FONT; title.TextSize = 24; title.TextColor3 = RGB(58, 36, 16); title.Parent = panel
local purse = Instance.new("TextLabel"); purse.AnchorPoint = Vector2.new(1, 0); purse.Position = UDim2.new(1, -56, 0, 16); purse.Size = UDim2.fromOffset(105, 28)
purse.BackgroundColor3 = SLOT; purse.BorderSizePixel = 0; purse.FontFace = FONT; purse.TextSize = 14; purse.TextColor3 = INK; purse.Text = ""; purse.Parent = panel
corner(purse, 10); stroke(purse, SLOT_EDGE, 2, 0.3)
local close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -16, 0, 14); close.Size = UDim2.fromOffset(32, 32)
close.BackgroundColor3 = SLOT; close.BorderSizePixel = 0; close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = INK; close.Text = "X"; close.AutoButtonColor = false; close.Parent = panel
corner(close, 10); stroke(close, SLOT_EDGE, 2, 0.3)
local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(14, 54); list.Size = UDim2.new(1, -28, 1, -54 - 119)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 8); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list
-- the foot of the panel: the hat you are trying, what it costs, and the buttons
local foot = Instance.new("Frame"); foot.AnchorPoint = Vector2.new(0, 1); foot.Position = UDim2.new(0, 14, 1, -12); foot.Size = UDim2.new(1, -28, 0, 106)
foot.BackgroundColor3 = FACE_DEEP; foot.BorderSizePixel = 0; foot.Parent = panel
corner(foot, 14); stroke(foot, SLOT_EDGE, 2, 0.45)
local picked = Instance.new("TextLabel"); picked.Position = UDim2.fromOffset(12, 6); picked.Size = UDim2.new(1, -24, 0, 22); picked.BackgroundTransparency = 1
picked.FontFace = FONT; picked.TextSize = 14; picked.TextColor3 = RGB(58, 36, 16); picked.TextXAlignment = Enum.TextXAlignment.Left; picked.TextTruncate = Enum.TextTruncate.AtEnd
picked.Text = "Tap a dress to try it on"; picked.Parent = foot
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
	vf.LightColor = RGB(255, 246, 230); vf.LightDirection = Vector3.new(-0.4, -1, -0.6); vf.Parent = parent
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
local function owned(id) return (player:GetAttribute("Item_dress_" .. id) or 0) > 0 end
local function wornId()
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 15) == "Item_dresswear_" and (tonumber(v) or 0) > 0 then return name:sub(16) end
	end
end
local function priceOf(styleId) return F:GetAttribute("Price_" .. styleId) end
for i, s in ipairs(Cat.styles) do
	local sec = Instance.new("Frame"); sec.Name = s.id; sec.Size = UDim2.new(1, -6, 0, 154); sec.BackgroundColor3 = FACE_DEEP; sec.BorderSizePixel = 0
	sec.LayoutOrder = i; sec.Parent = list
	corner(sec, 14); stroke(sec, SLOT_EDGE, 2, 0.45)
	local nm = Instance.new("TextLabel"); nm.Position = UDim2.fromOffset(12, 6); nm.Size = UDim2.new(1,-110,0,20); nm.BackgroundTransparency = 1
	nm.FontFace = FONT; nm.TextSize = 15; nm.TextColor3 = RGB(58, 36, 16); nm.TextXAlignment = Enum.TextXAlignment.Left; nm.Text = s.name; nm.Parent = sec
	local pr = Instance.new("TextLabel"); pr.AnchorPoint = Vector2.new(1, 0); pr.Position = UDim2.new(1, -12, 0, 8); pr.Size = UDim2.fromOffset(95, 18)
	pr.BackgroundTransparency = 1; pr.FontFace = FONT; pr.TextSize = 12; pr.TextColor3 = INK_DIM; pr.TextXAlignment = Enum.TextXAlignment.Right; pr.Parent = sec
	sections[s.id] = {frame = sec, price = pr}
	for k = 1, #s.colours do
		local id = s.id .. "_" .. k
		local t = Instance.new("TextButton"); t.Name = id; t.Text = ""; t.AutoButtonColor = false; t.BackgroundColor3 = FACE; t.BorderSizePixel = 0
		t.Size = UDim2.new(1/3,-12,0,111); t.Position = UDim2.new((k-1)/3,7,0,32); t.Parent = sec
		corner(t, 12)
		local st = stroke(t, SLOT_EDGE, 2, 0.35)
		local pic = picture(id, t); pic.Size = UDim2.new(1, -8, 1, -33); pic.Position = UDim2.fromOffset(4, 2)
		local tag = Instance.new("TextLabel"); tag.AnchorPoint = Vector2.new(0.5, 1); tag.Position = UDim2.new(0.5, 0, 1, -3); tag.Size = UDim2.fromOffset(70, 14)
		tag.BackgroundTransparency = 1; tag.FontFace = FONT; tag.TextSize = 11; tag.TextColor3 = RGB(64, 112, 48); tag.Text = ""; tag.Parent = t
		local color=Instance.new("TextLabel");color.Name="Colour";color.BackgroundTransparency=1;color.Position=UDim2.new(0,2,1,-31);color.Size=UDim2.new(1,-4,0,14);color.Font=Enum.Font.BuilderSans;color.TextSize=11;color.TextColor3=INK;color.Text=s.colours[k].name;color.Parent=t
        tiles[id] = {button = t, stroke = st, tag = tag}
	end
end

-- ---- trying on: the hat on YOUR head, on your screen only, while the one you wear (and your own hats) step aside
local preview
local hiddenParts = {}
local hiddenClothing={}
local function hideWorn(hide)
 local char=player.Character
 if hide and char then
  for _,entry in ipairs(Cat.clothing(char)) do local o,key=entry[1],entry[2];if hiddenClothing[o]==nil then hiddenClothing[o]={key,o[key]} end;o[key]="" end
  local all=Cat.covered(char,selected);local w=char:FindFirstChild("WornDress")
  if w then for _,p in ipairs(w:GetDescendants()) do if p:IsA("BasePart") then table.insert(all,p) end end end
  for _,p in ipairs(all) do if hiddenParts[p]==nil then hiddenParts[p]=p.LocalTransparencyModifier end;p.LocalTransparencyModifier=1 end
 else
  for o,v in pairs(hiddenClothing) do if o.Parent then o[v[1]]=o:GetAttribute("DressClothingWas")~=nil and "" or v[2] end end;hiddenClothing={}
  for p,was in pairs(hiddenParts) do if p.Parent then p.LocalTransparencyModifier=was end end;hiddenParts={}
 end
end
local function clearPreview() if preview then preview:Destroy();preview=nil end end
local function tryOn(id)
 clearPreview();hideWorn(false)
 local char=player.Character;if not char then return end
 preview=Cat.attach(kit,id,char,"DressPreview");hideWorn(true)
end

local function refresh()
	purse.Text = tostring(player:GetAttribute("Acorns") or 0) .. "  acorns"
	local have = player:GetAttribute("Acorns") or 0
	local on = wornId()
	for _, s in ipairs(Cat.styles) do
		local p = priceOf(s.id)
		sections[s.id].price.Text = p and (tostring(p) .. " acorns") or ""
	end
	for id, t in pairs(tiles) do
		local mine, wearing = owned(id), (id == on)
		t.tag.Text = wearing and "wearing" or (mine and "yours" or "")
		t.tag.TextColor3 = wearing and RGB(170, 110, 20) or RGB(64, 112, 48)
		local sel = (id == selected)
		t.stroke.Color = sel and GOLD or (wearing and RGB(200, 150, 48) or SLOT_EDGE)
		t.stroke.Thickness = sel and 3 or 2; t.stroke.Transparency = sel and 0 or 0.35
		t.button.BackgroundColor3 = sel and RGB(255, 248, 228) or FACE
	end
	if not selected then
		picked.Text = on and ("You're wearing the " .. Cat.title(on):lower()) or "Tap a dress to try it on"
		main.Text = "Pick a dress"; main.BackgroundColor3 = RGB(214, 202, 176); main.TextColor3 = INK_DIM
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
for id, t in pairs(tiles) do
	t.button.MouseButton1Click:Connect(function()
		if busy then return end
		selected = id
		tryOn(id)
		refresh()
	end)
end

local busy = false
main.MouseButton1Click:Connect(function()
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
				local w = char and char:FindFirstChild("WornDress")
				if w and w:GetAttribute("DressId") == want then break end
				task.wait(0.05)
			end
			if selected == want and preview then clearPreview(); hideWorn(false) end
		end)
	else say(tostring(why or "no"), false) end
	refresh()
end)
bare.MouseButton1Click:Connect(function()
	if busy then return end
	selected = nil
	clearPreview(); hideWorn(false)
	busy = true
	local ok,res,why=pcall(function() return action:InvokeServer("wear", "") end)
	busy = false
	say(ok and res and "Original outfit" or tostring(why or "Try again"),ok and res)
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
close.MouseButton1Click:Connect(function() setOpen(false) end)
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
        if open then setOpen(false) end
		doorSfx.TimePosition = 0; doorSfx:Play()
		TweenService:Create(black, TweenInfo.new(a or 0.45), {BackgroundTransparency = 0}):Play()
	elseif what == "unfade" then
		TweenService:Create(black, TweenInfo.new((a or 0.45) * 1.4), {BackgroundTransparency = 1}):Play()
	elseif what == "mirror" then
		setOpen(true)
	end
end)

]====]
 local Cat=assert(loadstring(CAT))();assert(loadstring(SERVER));assert(loadstring(CLIENT))
 for name in pairs(Cat.sizes) do assert(kit:FindFirstChild(name),"Missing dress mesh "..name) end
 local F=Instance.new("Folder");F.Name="DressShop"
 for _,s in ipairs(Cat.styles) do F:SetAttribute("Price_"..s.id,(opts.prices and opts.prices[s.id]) or s.price) end
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end
	local function soft(p) p.CanCollide = false; return p end

	-- ---------------------------------------------------------------- the street door ----
	-- the MODE ET STYLE sign is on the townhouse_e at x 312 looking +z; its door (DoorShop) is at x 303, the window x 305..323
	local SX, DX, DZ=304,295,-100.6
 local shop
 for _,m in ipairs(workspace.Village.Props:GetChildren()) do
  local t=m:FindFirstChild("SignText",true)
  if t then for _,l in ipairs(t:GetDescendants()) do if l:IsA("TextLabel") and l.Text=="MODE ET STYLE" then shop=m end end end
 end
 assert(shop,"MODE ET STYLE storefront missing")
	local function shopColour(name, fallback)
		local p = shop and shop:FindFirstChild(name, true)
		return (p and p:IsA("BasePart")) and p.Color or fallback
	end
	local FACADE = shopColour("Shopfront", C(38, 94, 65))
	local AWNING, STRIPE = shopColour("Awning", C(226, 176, 80)), shopColour("AwningStripe", C(250, 247, 240))
	local DOORC, GLASSC = shopColour("DoorShop", C(112, 74, 46)), shopColour("GlassDoor", C(232, 240, 244))
	local groundY = 0.65
	do
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
		local ground = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Ground")
		if ground then rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {ground, workspace.Terrain} end
		local hit = workspace:Raycast(Vector3.new(DX, 20, DZ + 2), Vector3.new(0, -40, 0), rp)
		if hit then groundY = hit.Position.Y end
	end
	local doorPad = part("DoorPad", Vector3.new(4, 5.5, 0.6), CFrame.new(DX, groundY + 2.9, DZ), C(255, 246, 220), nil, F)
	doorPad.Transparency = 1; doorPad.CanCollide = false; doorPad.CanQuery = false
	local mat = part("Doormat", Vector3.new(3.0, 0.12, 1.6), CFrame.new(DX, groundY + 0.06, DZ - 1.2), C(46, 70, 52), Enum.Material.Fabric)
	mat.CanCollide = false
	local enter = Instance.new("ProximityPrompt"); enter.Name = "EnterPrompt"; enter.ActionText = "Go inside"; enter.ObjectText = "Mode et Style"
	enter.KeyboardKeyCode = Enum.KeyCode.E; enter.HoldDuration = 0; enter.MaxActivationDistance = 8; enter.RequiresLineOfSight = false; enter.Parent = doorPad

	-- ---------------------------------------------------------------- the room ----
	local W, D, H = opts.width or 24, opts.depth or 22, 11
	local O = Vector3.new(SX, opts.roomY or 390, DZ - 0.45 - D / 2)         -- floor centre; the street wall's inner face at the facade
	local room = Instance.new("Model"); room.Name = "Room"; room.Parent = F
	local function at(x, y, z) return CFrame.new(O.X + x, O.Y + y, O.Z + z) end
	local dxr = DX - SX                                                       -- the door's x in room terms (-9)
	local PLASTER, WOOD, DARK, PARQUET = C(238, 227, 204), C(122, 86, 54), C(70, 48, 32), C(156, 112, 72)
	local BRASS, IRON, CREAM, VELVET = C(218, 178, 88), C(46, 46, 51), C(255, 246, 220), C(155, 72, 48)
	part("Floor", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, -0.3, 0), PARQUET, Enum.Material.WoodPlanks, room)
	part("Ceiling", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, H + 0.3, 0), C(232, 222, 202), Enum.Material.SmoothPlastic, room)
	part("WallN", Vector3.new(W, H, 0.6), at(0, H / 2, -D / 2 - 0.3), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallE", Vector3.new(0.6, H, D + 1.2), at(W / 2 + 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallW", Vector3.new(0.6, H, D + 1.2), at(-W / 2 - 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	-- a sage wainscot to the height of a chair back, capped with a dark rail, round the three plaster walls
	local WAIN = 3.1
	for _, w in ipairs({{0, -D / 2 + 0.08, W, 0.16}, {W / 2 - 0.08, 0, 0.16, D}, {-W / 2 + 0.08, 0, 0.16, D}}) do
		soft(part("Wainscot", Vector3.new(w[3], WAIN, w[4]), at(w[1], WAIN / 2, w[2]), FACADE, Enum.Material.Wood, room))
		soft(part("Rail", Vector3.new(math.max(w[3], 0.3), 0.22, math.max(w[4], 0.3)), at(w[1], WAIN + 0.1, w[2]), DARK, Enum.Material.Wood, room))
		soft(part("Skirting", Vector3.new(math.max(w[3], 0.26), 0.36, math.max(w[4], 0.26)), at(w[1], 0.18, w[2]), DARK, Enum.Material.Wood, room))
	end

	-- the street wall, in the shopfront's green: the display window (16 wide, y 1.4..8.4), wall, then the door at x -9
	local zS = D / 2 + 0.3
	local wx0, wx1, wy0, wy1 = -4.6, 11.4, 1.4, 8.4
	local ddx0, ddx1 = dxr - 1.7, dxr + 1.7
	local function wall(x0, x1, y0, y1) part("WallS", Vector3.new(x1 - x0, y1 - y0, 0.6), at((x0 + x1) / 2, (y0 + y1) / 2, zS), FACADE, Enum.Material.SmoothPlastic, room) end
	wall(-W / 2, W / 2, wy1, H)                              -- the band over the window and the door
	wall(-W / 2, ddx0, 0, wy1)                               -- west pier
	wall(ddx0, ddx1, 0, wy1)                                 -- behind the door (it is mounted on the wall)
	wall(ddx1, wx0, 0, wy1)                                  -- between the door and the window
	wall(wx0, wx1, 0, wy0)                                   -- under the window
	wall(wx1, W / 2, 0, wy1)                                 -- east pier
	local pane = part("Window", Vector3.new(wx1 - wx0, wy1 - wy0, 0.25), at((wx0 + wx1) / 2, (wy0 + wy1) / 2, zS), GLASSC, Enum.Material.Glass, room)
	pane.Transparency = 0.2; pane.CastShadow = false          -- under 0.25, so the camera treats the glass as solid
	for _, fx in ipairs({wx0 - 0.1, wx1 + 0.1}) do part("Frame", Vector3.new(0.4, wy1 - wy0 + 0.4, 0.8), at(fx, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	part("Frame", Vector3.new(wx1 - wx0 + 0.8, 0.4, 0.8), at((wx0 + wx1) / 2, wy1 + 0.1, zS), CREAM, Enum.Material.SmoothPlastic, room)
	part("Sill", Vector3.new(wx1 - wx0 + 0.8, 0.4, 1.0), at((wx0 + wx1) / 2, wy0 - 0.1, zS - 0.1), CREAM, Enum.Material.SmoothPlastic, room)
	for k = 1, 3 do part("Mullion", Vector3.new(0.25, wy1 - wy0, 0.5), at(wx0 + (wx1 - wx0) * k / 4, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	-- the mustard awning outside the window, seen through the glass
	do
		local tilt = math.rad(37)
		local n, wA, cx = 12, 18, (wx0 + wx1) / 2
		for i = 0, n - 1 do
			local sx = cx - wA / 2 + wA / n * (i + 0.5)
			soft(part("Awning", Vector3.new(wA / n + 0.02, 0.12, 4.0), at(sx, 7.85, zS + 2.05) * CFrame.Angles(tilt, 0, 0), (i % 2 == 0) and AWNING or STRIPE, Enum.Material.Fabric, room))
		end
		soft(part("AwningRod", Vector3.new(wA, 0.15, 0.15), at(cx, 6.55, zS + 3.8), IRON, Enum.Material.Metal, room))
	end
	-- the door, the Mode et Style's own brown with its glass, on the wall
	local doorZ = zS - 0.3
	part("DoorFrame", Vector3.new(3.8, 7.1, 0.2), at(dxr, 3.55, doorZ - 0.1), DARK, Enum.Material.Wood, room)
	local door = part("Door", Vector3.new(3.4, 6.8, 0.2), at(dxr, 3.4, doorZ - 0.2), DOORC, Enum.Material.Wood, room)
	local dglass = part("DoorGlass", Vector3.new(2.4, 3.6, 0.1), at(dxr, 4.4, doorZ - 0.32), GLASSC, Enum.Material.Glass, room); dglass.Transparency = 0.2
	for _, px in ipairs({-0.72, 0.72}) do soft(part("Panel", Vector3.new(1.2, 1.6, 0.06), at(dxr + px, 1.3, doorZ - 0.32), C(92, 62, 46), Enum.Material.Wood, room)) end
	soft(part("Knob", Vector3.new(0.3, 0.3, 0.3), at(dxr + 1.2, 3.4, doorZ - 0.42), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))
	local exit = Instance.new("ProximityPrompt"); exit.Name = "ExitPrompt"; exit.ActionText = "Go outside"; exit.ObjectText = "Rue de Noisette"
	exit.KeyboardKeyCode = Enum.KeyCode.E; exit.HoldDuration = 0; exit.MaxActivationDistance = 7; exit.RequiresLineOfSight = false; exit.Parent = door
	-- a bell over the door on a curled bracket (shops like this have one)
	soft(part("BellBracket", Vector3.new(0.12, 0.12, 1.0), at(dxr + 1.3, 7.5, doorZ - 0.8), IRON, Enum.Material.Metal, room))
	soft(part("ShopBell", Vector3.new(0.45, 0.45, 0.45), at(dxr + 1.3, 7.25, doorZ - 1.25), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))

 -- Three full-size dress forms; their actual wearable meshes double as the display art.
 local function mannequin(id,x,y,z,s,yaw,parent)
  local d=Cat.byId[id];local waist=y+d.style.length*s+.32
  local cf=at(x,waist,z)*CFrame.Angles(0,math.rad(yaw or 0),0)
  local model=Instance.new('Model');model.Name='Display_'..id;model.Parent=parent or room
  for _,p in ipairs(Cat.pieces(kit,id,cf,s)) do p.Anchored=true;p.Parent=model end
  soft(part('DressStand',Vector3.new(.16,1.5,1.5),at(x,y+.08,z)*CFrame.Angles(0,0,math.pi/2),BRASS,Enum.Material.Metal,model,Enum.PartType.Cylinder))
  soft(part('DressPole',Vector3.new(.12,waist-y,.12),at(x,(waist+y)/2,z),BRASS,Enum.Material.Metal,model))
  soft(part('MannequinNeck',Vector3.new(.36,.36,.36),at(x,waist+2.05*s,z),CREAM,Enum.Material.SmoothPlastic,model,Enum.PartType.Ball))
  return model
 end
 local function words(p,text,size)
  p.CFrame*=CFrame.Angles(0,math.pi,0)
  local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=70;g.LightInfluence=.2;g.Parent=p
  local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(6,4);l.Size=UDim2.new(1,-12,1,-8);l.Font=Enum.Font.FredokaOne;l.TextScaled=true;l.TextColor3=DARK;l.Text=text;l.Parent=g
 end
 for i,s in ipairs(Cat.styles) do
  local x=(i-2)*6.6;local z=-D/2+2.2
  part('DisplayPlinth',Vector3.new(5.4,.32,3.4),at(x,.16,z),WOOD,Enum.Material.Wood,room)
  mannequin(s.id..'_1',x,.33,z,.94,180)
  soft(part('DisplayBack',Vector3.new(5.5,7.6,.1),at(x,4.3,-D/2+.2),C(244,232,207),Enum.Material.SmoothPlastic,room))
  for _,side in ipairs({-1,1}) do soft(part('DisplayTrim',Vector3.new(.065,7.6,.16),at(x+side*2.7,4.3,-D/2+.28),BRASS,Enum.Material.Metal,room)) end
  local plaque=soft(part('StylePlaque',Vector3.new(5.2,.7,.12),at(x,7.65,-D/2+.32),BRASS,Enum.Material.Metal,room))
  words(plaque,s.name..' · '..tostring(F:GetAttribute('Price_'..s.id))..' acorns')
  for k,c in ipairs(s.colours) do
   soft(part('FabricSwatch',Vector3.new(.8,.8,.07),at(x+(k-2)*1.1,6.55,-D/2+.37),c.fabric,Enum.Material.Fabric,room))
  end
 end
 local sign=soft(part('BoutiqueSign',Vector3.new(13,1.1,.12),at(0,9.6,-D/2+.18),CREAM,Enum.Material.SmoothPlastic,room))
 words(sign,'MODE ET STYLE')
 -- Two colourways in the shop window, with plenty of daylight between them.
 mannequin('rue_2',-.8,1.55,D/2-1.45,.8,0)
 mannequin('chateau_3',6.7,1.55,D/2-1.45,.8,-12)
	-- THE MIRROR on the west wall: an arched glass in a gilded frame, a little rug where you stand, a sign over it
	local MZ = opts.mirrorZ or -2.6
	local mx = -W / 2 + 0.2
	local MIR = Instance.new("Model"); MIR.Name = "Mirror"; MIR.Parent = room
	part("FrameSlab", Vector3.new(0.3, 5.8, 4.5), at(mx + 0.05, 1.0 + 2.9, MZ), BRASS, Enum.Material.Metal, MIR)
	part("FrameTop", Vector3.new(0.3, 4.5, 4.5), at(mx + 0.05, 6.8, MZ) * CFrame.Angles(0, 0, 0), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Cylinder)
	local glass = part("Glass", Vector3.new(0.12, 5.4, 3.8), at(mx + 0.22, 1.2 + 2.7, MZ), C(206, 220, 230), Enum.Material.Glass, MIR)
	glass.Reflectance = 0.35
	local gtop = part("GlassTop", Vector3.new(0.12, 3.8, 3.8), at(mx + 0.22, 6.6, MZ), C(206, 220, 230), Enum.Material.Glass, MIR, Enum.PartType.Cylinder)
	gtop.Reflectance = 0.35
	soft(part("Crest", Vector3.new(0.3, 0.9, 0.9), at(mx + 0.1, 9.05, MZ), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Ball))
	local spot = Vector3.new(O.X - 3.2, O.Y, O.Z + MZ)                      -- where you stand to look in it
	soft(part("MirrorRug", Vector3.new(0.1, 4.2, 4.2), CFrame.new(spot.X, O.Y + 0.08, spot.Z) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, MIR, Enum.PartType.Cylinder))
	local ask = Instance.new("ProximityPrompt"); ask.Name = "MirrorPrompt"; ask.ActionText = "Try on dresses"; ask.ObjectText = "Mirror"
	ask.KeyboardKeyCode = Enum.KeyCode.E; ask.HoldDuration = 0; ask.MaxActivationDistance = 10; ask.RequiresLineOfSight = false; ask.Parent = glass
	do
		local card = soft(part("MirrorSign", Vector3.new(0.08, 0.8, 3.0), at(mx + 0.3, 10.1, MZ), CREAM, Enum.Material.SmoothPlastic, MIR))
		local g = Instance.new("SurfaceGui"); g.Face = Enum.NormalId.Right; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 80; g.LightInfluence = 0.3; g.Parent = card
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -10, 1, -6); l.Position = UDim2.fromOffset(5, 3)
		l.Font = Enum.Font.Antique; l.TextScaled = true; l.TextColor3 = C(70, 46, 22); l.Text = "Essayez !"; l.Parent = g
	end
	-- Fabric rolls in a brass basket beside the mirror.
 for i,col in ipairs({C(230,185,81),C(169,78,50),C(44,91,63)}) do
  local x,z=-10.4+(i-2)*.45,3.3
  soft(part("FabricRoll",Vector3.new(3.1,.44,.44),at(x,1.7,z)*CFrame.Angles(0,0,math.rad(86+i*2)),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end
 part("FabricBasket",Vector3.new(1.8,.8,1.1),at(-10.4,.4,3.3),WOOD,Enum.Material.Wood,room)
	-- the counter on the east side: a till, striped hat boxes, a little lamp
	do
		local cx, cz = W / 2 - 2.4, 2.6
		part("Counter", Vector3.new(1.6, 3.4, 7.0), at(cx, 1.7, cz), WOOD, Enum.Material.Wood, room)
		part("CounterTop", Vector3.new(1.9, 0.2, 7.3), at(cx, 3.5, cz), DARK, Enum.Material.Wood, room)
		soft(part("Front", Vector3.new(0.1, 2.6, 6.4), at(cx - 0.85, 1.6, cz), FACADE, Enum.Material.Wood, room))
		part("Till", Vector3.new(1.0, 0.8, 1.3), at(cx, 4.0, cz - 1.8), BRASS, Enum.Material.Metal, room)
		soft(part("TillTop", Vector3.new(0.7, 0.35, 1.1), at(cx + 0.15, 4.55, cz - 1.8) * CFrame.Angles(0, 0, math.rad(-20)), BRASS, Enum.Material.Metal, room))
		soft(part("LampPole", Vector3.new(0.1, 1.2, 0.1), at(cx, 4.2, cz + 2.4), BRASS, Enum.Material.Metal, room))
		local shade = soft(part("LampShade", Vector3.new(0.6, 0.8, 0.8), at(cx, 4.9, cz + 2.4) * CFrame.Angles(0, 0, math.rad(90)), C(240, 214, 160), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.5; pl.Range = 8; pl.Color = C(255, 214, 160); pl.Parent = shade
		-- hat boxes: striped rounds stacked on the counter's end and on the floor behind it
		local function hatBox(x, y, z, r, h, c1, c2)
			part("HatBox", Vector3.new(h, r * 2, r * 2), at(x, y + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), c1, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder)
			soft(part("BoxLid", Vector3.new(0.22, r * 2 + 0.1, r * 2 + 0.1), at(x, y + h - 0.08, z) * CFrame.Angles(0, 0, math.rad(90)), c2, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder))
		end
		hatBox(cx, 3.6, cz + 0.6, 0.62, 0.7, C(240, 226, 196), C(172, 42, 50))
		hatBox(cx, 4.3, cz + 0.6, 0.5, 0.55, C(128, 158, 118), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0, cz - 2.4, 0.7, 0.8, C(206, 122, 132), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0.8, cz - 2.4, 0.6, 0.7, C(240, 226, 196), C(42, 50, 94))
		hatBox(W / 2 - 0.9, 0, cz + 4.8, 0.65, 0.75, C(42, 50, 94), C(224, 180, 82))
	end

	-- a round rug in the middle, a velvet pouf to sit on, and three low pendant lamps (dim - the Librairie's were
	-- "way way way too bright" before they were cut to a third)
	-- (east of the mirror's own rug, and a little lower, so the two never overlap or flicker)
	soft(part("Rug", Vector3.new(0.1, 9, 9), at(3.9, 0.05, -1) * CFrame.Angles(0, 0, math.rad(90)), C(160, 60, 64), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	soft(part("RugBorder", Vector3.new(0.08, 9.6, 9.6), at(3.9, 0.03, -1) * CFrame.Angles(0, 0, math.rad(90)), C(218, 178, 88), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	local pouf = part("Pouf", Vector3.new(1.5, 2.4, 2.4), at(4.6, 0.75, -0.5) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, room, Enum.PartType.Cylinder)
	local seat = Instance.new("Seat"); seat.Name = "PoufSeat"; seat.Size = Vector3.new(2.0, 0.2, 2.0); seat.CFrame = at(4.6, 1.55, -0.5); seat.Transparency = 1; seat.Anchored = true; seat.Parent = room
	for i, lx in ipairs({-5, 1.5, 8}) do
		local ly = H - 2.3
		soft(part("Cord", Vector3.new(0.06, 2.0, 0.06), at(lx, H - 1.0, -2), IRON, Enum.Material.Metal, room))
		local sh = soft(part("Shade", Vector3.new(0.7, 1.4, 1.4), at(lx, ly, -2) * CFrame.Angles(0, 0, math.rad(90)), (i == 2) and C(224, 180, 82) or C(38, 94, 65), Enum.Material.Metal, room, Enum.PartType.Cylinder))
		local bulb = soft(part("Bulb", Vector3.new(0.4, 0.4, 0.4), at(lx, ly - 0.4, -2), C(255, 240, 200), Enum.Material.Neon, room, Enum.PartType.Ball))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.55; pl.Range = 16; pl.Color = C(255, 222, 176); pl.Shadows = false; pl.Parent = bulb
	end

	-- ---------------------------------------------------------------- plumbing ----
	local action = RS:FindFirstChild("DressShopAction")
	if not action then action = Instance.new("RemoteFunction"); action.Name = "DressShopAction"; action.Parent = RS end
	local ev = RS:FindFirstChild("DressShopEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "DressShopEvent"; ev.Parent = RS end
	F:SetAttribute("RoomX", O.X); F:SetAttribute("RoomY", O.Y); F:SetAttribute("RoomZ", O.Z)
	F:SetAttribute("FadeSeconds", opts.fade or 0.45)
	F:SetAttribute("DoorSound", opts.doorSound or "rbxassetid://131845870598154"); F:SetAttribute("DoorVolume", opts.doorVolume or 0.6)   -- the Librairie's door (Shannon's pick)
	F:SetAttribute("InsideZoom", 16)
	F:SetAttribute("InX", O.X + dxr); F:SetAttribute("InY", O.Y + 3.4); F:SetAttribute("InZ", O.Z + D / 2 - 5.5)
	F:SetAttribute("OutX", DX); F:SetAttribute("OutY", groundY + 3.4); F:SetAttribute("OutZ", DZ - 2.6)
	F:SetAttribute("SpotX", spot.X); F:SetAttribute("SpotY", spot.Y); F:SetAttribute("SpotZ", spot.Z)
	F:SetAttribute("MirrorX", O.X + mx); F:SetAttribute("MirrorZ", O.Z + MZ)
	if not F:FindFirstChild("DressDebug") then local d = Instance.new("BindableFunction"); d.Name = "DressDebug"; d.Parent = F end   -- Studio tests


 for i,col in ipairs({C(230,187,86),C(245,230,197),C(153,58,64)}) do
  soft(part("RibbonSpool",Vector3.new(.3,.5,.5),at(9.6,3.85,1+i*.5)*CFrame.Angles(0,0,math.pi/2),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end

 local old=workspace:FindFirstChild("DressShop");if old then old:Destroy() end
 local oldCat=kit:FindFirstChild("Catalogue");if oldCat then oldCat:Destroy() end
 local cm=Instance.new("ModuleScript");cm.Name="Catalogue";cm.Source=CAT;cm.Parent=kit
 local s=Instance.new("Script");s.Name="DressServer";s.RunContext=Enum.RunContext.Server;s.Source=SERVER;s.Parent=F
 local c=Instance.new("Script");c.Name="DressClient";c.RunContext=Enum.RunContext.Client;c.Source=CLIENT;c.Parent=F
 local cf,sz=room:GetBoundingBox();room:SetAttribute("BoxCF",cf);room:SetAttribute("BoxSize",sz);CS:AddTag(room,"SkyRoom")
 F.Parent=workspace
 return F
end

end)()
local f=build({})
warn("QQ DRESS BUILD PASS "..f:GetFullName().." / nine dresses")

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

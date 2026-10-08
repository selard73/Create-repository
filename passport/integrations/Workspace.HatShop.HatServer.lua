-- HatServer: the doors, buying, wearing, and dressing everyone in the hat they chose
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local F = script.Parent
local action = RS:WaitForChild("HatShopAction")
local ev = RS:WaitForChild("HatShopEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local kit = RS:WaitForChild("HatKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end
local function owns(player, id) return (player:GetAttribute("Item_hat_" .. id) or 0) > 0 end
local function worn(player)                                -- the Item_hatwear_<id> that is 1
	for name, v in pairs(player:GetAttributes()) do
		if name:sub(1, 13) == "Item_hatwear_" and (tonumber(v) or 0) > 0 and Cat.byId[name:sub(14)] then return name:sub(14) end
	end
	return nil
end

-- ---- wearing: the chosen hat as an Accessory at the head's HatAttachment, sized to the head; the avatar's own hats
-- are hidden while it is on (and shown again when it comes off)
local function showOwnHats(char, show)
	for _, acc in ipairs(char:GetChildren()) do
		if acc:IsA("Accessory") and acc.Name ~= "WornHat" and acc.AccessoryType == Enum.AccessoryType.Hat then
			local h = acc:FindFirstChild("Handle")
			if h then
				if show then
					local was = h:GetAttribute("HatShopWas")
					if was ~= nil then h.Transparency = was; h:SetAttribute("HatShopWas", nil) end
				elseif h:GetAttribute("HatShopWas") == nil then
					h:SetAttribute("HatShopWas", h.Transparency); h.Transparency = 1
				end
			end
		end
	end
end
local function undress(char)
	local old = char and char:FindFirstChild("WornHat")
	if old then old:Destroy() end
	if char then showOwnHats(char, true) end
end
local function dress(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	if not (hum and head) then return end
	local id = worn(player)
	local cur = char:FindFirstChild("WornHat")
	if cur and cur:GetAttribute("HatId") == id then showOwnHats(char, false) return end   -- (own hats that loaded late go aside too)
	undress(char)
	if not id or not owns(player, id) then return end
	local h = Cat.byId[id]
	local fitCF, s = Cat.fit(head, h.style.id)
	local pieces = Cat.pieces(kit, id, head.CFrame * fitCF, s)
	if not pieces or not pieces[1] then return end
	local acc = Instance.new("Accessory"); acc.Name = "WornHat"; acc.AccessoryType = Enum.AccessoryType.Hat
	acc:SetAttribute("HatId", id)
	local handle = pieces[1]; handle.Name = "Handle"; handle.Parent = acc
	for i = 2, #pieces do
		local p = pieces[i]; p.Parent = acc
		local w = Instance.new("WeldConstraint"); w.Part0 = handle; w.Part1 = p; w.Parent = p
	end
	-- the handle's HatAttachment is where the head's will be, so the Humanoid puts the hat exactly here
	local headAtt = head:FindFirstChild("HatAttachment")
	local a = Instance.new("Attachment"); a.Name = "HatAttachment"
	a.CFrame = handle.CFrame:ToObjectSpace(headAtt and headAtt.WorldCFrame or head.CFrame * CFrame.new(0, head.Size.Y / 2, 0))
	a.Parent = handle
	showOwnHats(char, false)
	if headAtt then
		hum:AddAccessory(acc)
	else                                                    -- a head with no HatAttachment: weld it where it is
		local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = handle; w.Parent = handle
		acc.Parent = char
	end
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
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InHatShop", toInside or nil)
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
	elseif prompt.Name == "MirrorPrompt" then ev:FireClient(player, "mirror") end
end)

-- ---- buying and wearing, asked by the client; decided here
local busy = {}
local function wear(player, id)
	local cur = worn(player)
	if cur == id then return end
	if cur then awardItems:Fire(player, "hatwear_" .. cur, -1) end
	if id then awardItems:Fire(player, "hatwear_" .. id, 1) end
end
action.OnServerInvoke = function(player, what, id)
	if what == "wear" then
		if id == "" or id == nil then wear(player, nil); return true end
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if not owns(player, id) then return false, "that one isn't yours yet" end
		wear(player, id)
		return true
	elseif what == "buy" then
		if type(id) ~= "string" or not Cat.byId[id] then return false, "no such hat" end
		if owns(player, id) then return false, "it's already yours" end
		if busy[player] then return false, "one at a time" end
		busy[player] = true
		local ok, res, why = pcall(function()
			local price = F:GetAttribute("Price_" .. Cat.byId[id].style.id)
			if type(price) ~= "number" then return false, "no price set" end
			local have = player:GetAttribute("Acorns") or 0     -- the purse as the SERVER sees it
			if have < price then return false, "not enough acorns" end
			awardAcorns:Fire(player, -price)                   -- spending is a negative award, same ledger, same merge
			player:SetAttribute("Acorns", have - price)
			awardItems:Fire(player, "hat_" .. id, 1)
			wear(player, id)                                   -- a new hat goes straight on
			local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"hat",{hat=Cat.title(id),action="buy"}) end
			return true, price
		end)
		busy[player] = nil
		if not ok then warn("HatServer: buying " .. tostring(id) .. " failed - " .. tostring(res)); return false, "something went wrong" end
		if res then print(string.format("HatShop: %s bought the %s for %d acorns", player.Name, Cat.title(id), why)) end
		return res, why
	end
	return false, "?"
end

local function watch(player)
	player.CharacterAdded:Connect(function(char)
		leash(player, false)
		task.delay(1.2, function() if player.Character == char then dress(player) end end)
	end)
	player.CharacterAppearanceLoaded:Connect(function() redress(player) end)
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 13) == "Item_hatwear_" or name:sub(1, 9) == "Item_hat_" then redress(player) end
	end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function() redress(player) end)
	if player.Character then dress(player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil; busy[p] = nil; moving[p] = nil end)
-- Studio tests: give a hat and/or wear it without acorns (never in a live game)
local dbg = F:FindFirstChild("HatDebug")
if dbg and RunService:IsStudio() then
	dbg.OnInvoke = function(player, what, id)
		if what == "give" then awardItems:Fire(player, "hat_" .. id, 1) return true
		elseif what == "wear" then wear(player, id) return true
		elseif what == "in" then through(player, true) return true
		elseif what == "out" then through(player, false) return true end
	end
end
print("HatServer: ready")

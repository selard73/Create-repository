local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local action = RS:WaitForChild("BookAction")
local ev = RS:WaitForChild("BookEvent")
local Books = require(F:WaitForChild("Books"))
local byId = {}
for _, b in ipairs(Books) do byId[b.id] = b end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out past the walls: a short zoom leash, given back at the door (or on respawn)
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player)
	player.CharacterAdded:Connect(function() leash(player, false) end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)
-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InBookshop", toInside or nil)
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
	elseif prompt.Name == "BookPrompt" then
		local id = prompt:GetAttribute("BookId")
		local b = byId[id]
		if not b or b.soon then return end
		ev:FireClient(player, "book", id, true) -- everyone may read
	end
end)
-- Free reading: no purchase, ownership grant, or acorn deduction.
action.OnServerInvoke = function(player, what, id)
	local b = type(id) == "string" and byId[id]
	if not b or b.soon then return false, "no such book" end
	if what == "buy" or what == "owned" then return true, "Free to read" end
	if what == "read" then
		local char = player.Character
		local passport = RS:FindFirstChild("PassportActivity")
		if passport and char and char:GetAttribute("InBookshop") then passport:Fire(player,"book",{title=b.title,character=({crumbs="the amazing International Spy Squirrel",story2="the charming Gérard and the determined Margaux Delacroix-Pim",story3="the wonderfully stubborn Picnic Pierre"})[id]}) end
		return true, {title = b.title, by = b.by, text = b.text, audio = b.audio or 0}
	end
	return false, "no such thing"
end
print("BookServer: ready - " .. #Books .. " books on the table")

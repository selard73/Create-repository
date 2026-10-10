-- StowServer (workspace.Shop): Equip / Store for the things you own that ride in the hotbar (Oct 4 2026, Shannon: "On the
-- acorn store, if you bought something, you should have a button to equip (which puts it at the bottom of the screen) or
-- store (which would take it off the bottom of the screen)"). Storing is saved like any item: Item_stow_<id> = 1 through
-- AwardItems. Each tool's own giver (SlingServer, BinocularsServer, CrabServer, CameraServer) skips a stored tool and hands
-- it back the moment it is equipped again (they watch Item_stow_<id>); storing takes it out of the backpack and the hand here.
-- Oct 9 2026 (Shannon: "where did the camera go on my mobile game???"): Roblox's hotbar has only 3 slots on a phone-sized
-- screen, so a 4th equipped tool never shows and phones have no way to reach it. The client now says how many slots it has
-- (3 or 10): equipping past that stores the tool equipped longest ago, and a phone asks on arrival ("fit") to trim to its
-- slots. Equipped_<id> on the player = when each tool was last equipped (this session; ties go crab trap, slingshot,
-- binoculars, camera). The client is told which tool went away.
local RS = game:GetService("ReplicatedStorage")
local awardItems = RS:WaitForChild("AwardItems")
local ev = RS:WaitForChild("HotbarStow")
local TOOLS = {binoculars = "Binoculars", slingshot = "Slingshot", crabtrap = "Crab trap", camera = "Camera"}
local TIE = {crabtrap = 1, slingshot = 2, binoculars = 3, camera = 4}   -- lower goes to the bag first when nothing else decides

local function owned(p, id) return (p:GetAttribute("Item_" .. id) or 0) > 0 end
local function stowed(p, id) return (p:GetAttribute("Item_stow_" .. id) or 0) > 0 end
local function takeTool(p, toolName)
	local pack = p:FindFirstChildOfClass("Backpack")
	local t = pack and pack:FindFirstChild(toolName)
	if t then t:Destroy() end
	t = p.Character and p.Character:FindFirstChild(toolName)
	if t and t:IsA("Tool") then t:Destroy() end
end
local function setStow(p, id, want)
	local cur = p:GetAttribute("Item_stow_" .. id) or 0
	if cur ~= want then awardItems:Fire(p, "stow_" .. id, want - cur) end
	if want == 1 then takeTool(p, TOOLS[id]) end
end
-- more tools on the bar than the screen has slots: store the ones equipped longest ago (never `keep`)
local function fit(p, slots, keep)
	if type(slots) ~= "number" or slots < 1 or slots > 9 then return end
	local on = {}
	for id in pairs(TOOLS) do if owned(p, id) and not stowed(p, id) then table.insert(on, id) end end
	table.sort(on, function(a, b)
		local ta, tb = p:GetAttribute("Equipped_" .. a) or 0, p:GetAttribute("Equipped_" .. b) or 0
		if ta ~= tb then return ta < tb end
		return (TIE[a] or 9) < (TIE[b] or 9)
	end)
	local gone = {}
	for _, id in ipairs(on) do
		if #on - #gone <= slots then break end
		if id ~= keep then setStow(p, id, 1); table.insert(gone, TOOLS[id]) end
	end
	if #gone > 0 then ev:FireClient(p, "autostow", table.concat(gone, " and "), slots) end
end

ev.OnServerEvent:Connect(function(p, id, stow, slots)
	if id == "fit" then fit(p, slots) return end
	local toolName = type(id) == "string" and TOOLS[id]
	if not toolName then return end
	if not owned(p, id) then return end          -- only what is yours
	local want = stow == true and 1 or 0
	setStow(p, id, want)
	if want == 0 then
		p:SetAttribute("Equipped_" .. id, os.time())
		fit(p, slots, id)
	end
end)
print("StowServer: ready (hotbar slots aware)")

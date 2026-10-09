-- shop/phone_slots_patch: EDIT mode. Oct 9 2026, Shannon: "where did the camera go on my mobile game???". Roblox's own
-- hotbar shows only 3 tools on a phone-sized screen (viewport under 1024 px wide) and phones have no inventory button,
-- so a 4th equipped tool (she owns binoculars, slingshot, crab trap, camera) never shows. This patch:
--   StowServer (workspace.Shop, replaced whole; it was 27 lines): the client sends its slot count with every Equip/Store;
--     equipping past it stores the tool equipped longest ago (never the one just equipped); "fit" trims to the slots on
--     arrival; Equipped_<id> on the player = when each tool was last equipped (this session); ties go crab trap, slingshot,
--     binoculars, camera. The client is told which tool went away.
--   ShopClient (two exact-string finds): stowIt() sends the slot count and shows the server's note on the row; a phone
--     asks for "fit" 4 s after the store script starts.
-- Refuses to run unless both Sources are the Oct 8 texts (1534 and 33513 chars) and every find hits once. Compiles the
-- results before writing. Originals -> ServerStorage.HudBackup.StowServer_pre_slots / ShopClient_pre_slots. Output "QQ SLOT".
if game:GetService("RunService"):IsRunning() then warn("QQ SLOT ABORT - Play mode") return end
local Shop = workspace:FindFirstChild("Shop")
local SV = Shop and Shop:FindFirstChild("StowServer")
local CL = Shop and Shop:FindFirstChild("ShopClient")
if not (SV and SV:IsA("LuaSourceContainer") and CL and CL:IsA("LuaSourceContainer")) then warn("QQ SLOT ABORT - workspace.Shop.StowServer / ShopClient not found") return end
if #SV.Source ~= 1534 then warn("QQ SLOT ABORT - StowServer.Source is " .. #SV.Source .. " chars, expected 1534") return end
if #CL.Source ~= 33513 then warn("QQ SLOT ABORT - ShopClient.Source is " .. #CL.Source .. " chars, expected 33513") return end

local NEW_SERVER = [==[
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
]==]

local PAIRS = {
	{[==[
local function stowIt(item, rec, stow)
	local e = RS:FindFirstChild("HotbarStow")
	if not e then say(rec, "not ready yet", false) return end
	e:FireServer(item.id, stow)
	say(rec, stow and "stored - off your hotbar" or "equipped - on your hotbar", true)
end
]==], [==[
-- Oct 9 (Shannon: "where did the camera go on my mobile game???"): Roblox's hotbar shows only 3 tools on a phone-sized
-- screen (under 1024 px wide), so the server is told how many slots there are and stores a tool that does not fit.
local function hotbarSlots() local c = workspace.CurrentCamera; return (c and c.ViewportSize.X < 1024) and 3 or 10 end
local lastStowRec
local function stowIt(item, rec, stow)
	local e = RS:FindFirstChild("HotbarStow")
	if not e then say(rec, "not ready yet", false) return end
	lastStowRec = rec
	e:FireServer(item.id, stow, hotbarSlots())
	say(rec, stow and "stored - off your hotbar" or "equipped - on your hotbar", true)
end
do
	local e = RS:FindFirstChild("HotbarStow")
	if e then
		e.OnClientEvent:Connect(function(kind, names, slots)
			if kind ~= "autostow" or not lastStowRec then return end
			say(lastStowRec, string.format("equipped - the %s went to your bag (%d slots on this screen)", tostring(names), tonumber(slots) or 3), true)
		end)
	end
end
]==]},
	{[==[
refresh()
player:GetAttributeChangedSignal("Acorns"):Connect(refresh)
]==], [==[
refresh()
if hotbarSlots() <= 3 then                           -- a phone: trim the bar to what it can show (the server picks what goes)
	task.delay(4, function() local e = RS:FindFirstChild("HotbarStow"); if e then e:FireServer("fit", false, hotbarSlots()) end end)
end
player:GetAttributeChangedSignal("Acorns"):Connect(refresh)
]==]},
}

local src = CL.Source
for i, p in ipairs(PAIRS) do
	local a, b = src:find(p[1], 1, true)
	if not a then warn("QQ SLOT ABORT - ShopClient find " .. i .. " not found; nothing changed") return end
	if src:find(p[1], b + 1, true) then warn("QQ SLOT ABORT - ShopClient find " .. i .. " matches more than once; nothing changed") return end
end
local out = src
for _, p in ipairs(PAIRS) do
	local a, b = out:find(p[1], 1, true)
	out = out:sub(1, a - 1) .. p[2] .. out:sub(b + 1)
end
local f1, e1 = loadstring(NEW_SERVER)
if not f1 then warn("QQ SLOT ABORT - new StowServer does not compile: " .. tostring(e1)) return end
local f2, e2 = loadstring(out)
if not f2 then warn("QQ SLOT ABORT - patched ShopClient does not compile: " .. tostring(e2)) return end

local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup")
if not hb then hb = Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS end
for _, pair in ipairs({{SV, "StowServer_pre_slots"}, {CL, "ShopClient_pre_slots"}}) do
	if not hb:FindFirstChild(pair[2]) then
		local bk = pair[1]:Clone(); bk.Name = pair[2]
		pcall(function() bk.Enabled = false end)
		bk.Parent = hb
	end
end
SV.Source = NEW_SERVER
CL.Source = out
print(string.format("QQ SLOT DONE: StowServer 1534 -> %d chars, ShopClient 33513 -> %d chars, backups ServerStorage.HudBackup.StowServer_pre_slots / ShopClient_pre_slots", #NEW_SERVER, #out))

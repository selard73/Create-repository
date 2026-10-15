-- japan/japan_guest1 (job 116): EDIT mode. A guest on the private Japan preview: Shademade (user id 3121141), at Shannon's ask (Oct 15
-- 2026). Exact-string patches of the eight scripts that gate the preview (JapanPreviewAccess, BalloonClient, JapanPreviewVisibility,
-- JapanAtmosphere, JapanWaterAppearance, MapMusic.MusicClient, JapanMap's AutomaticFoodSeatContact x3); every anchor counted before any
-- script changes (a miss = that script skipped, said in a line), each result compiled, originals -> HudBackup.<Name>_pre_japanguest1.
-- More guests later: JapanPreviewAccess's attribute GuestUserIds (ids, comma-separated). Remove a guest: take the id out (the table one
-- needs the module edited, or restore HudBackup.JapanPreviewAccess_pre_japanguest1). No publish. Output lines "QQ JGUEST".
if game:GetService("RunService"):IsRunning() then print("QQ JGUEST ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local MARK = [===[
JAPANGUEST1_20261015]===]
local SCRIPTS = {
	{name = "JapanPreviewAccess", path = {"ServerScriptService", "JapanPreviewAccess"}, patches = {{[===[
function Access.IsAllowed(player)
	return player ~= nil and player.UserId == Access.OwnerUserId
end
]===], [===[
-- JAPANGUEST1_20261015: guests on the private preview (Shannon). Add more in Properties: this module's attribute GuestUserIds, ids comma-separated.
Access.GuestUserIds = {[3121141] = true}   -- Shademade
function Access.IsAllowed(player)
	if player == nil then return false end
	if player.UserId == Access.OwnerUserId or Access.GuestUserIds[player.UserId] then return true end
	local extra = script:GetAttribute("GuestUserIds")
	if type(extra) == "string" then for id in extra:gmatch("%d+") do if tonumber(id) == player.UserId then return true end end end
	return false
end
]===], 1}}},
	{name = "BalloonClient", path = {"Workspace", "BalloonField", "BalloonClient"}, patches = {{[===[
local previewOwner = player.UserId == 9611145467
]===], [===[
local previewOwner = player.UserId == 9611145467 or player:GetAttribute("JapanPreviewAllowed") == true   -- JAPANGUEST1_20261015: the owner or a guest
]===], 1}, {[===[
player:GetAttributeChangedSignal("Item_balloon_flights"):Connect(updatePrompt)
]===], [===[
player:GetAttributeChangedSignal("Item_balloon_flights"):Connect(updatePrompt)
player:GetAttributeChangedSignal("JapanPreviewAllowed"):Connect(function() previewOwner = player.UserId == 9611145467 or player:GetAttribute("JapanPreviewAllowed") == true; updatePrompt() end)   -- (JAPANGUEST1)
]===], 1}}},
	{name = "JapanPreviewVisibility", path = {"StarterPlayer", "StarterPlayerScripts", "JapanPreviewVisibility"}, patches = {{[===[
if player.UserId==9611145467 then return end
]===], [===[
do local t0=os.clock(); while player:GetAttribute('JapanPreviewAllowed')==nil and os.clock()-t0<8 do task.wait(0.1) end end   -- JAPANGUEST1_20261015: the server's word first
if player.UserId==9611145467 or player:GetAttribute('JapanPreviewAllowed')==true then return end
]===], 1}}},
	{name = "JapanAtmosphere", path = {"StarterPlayer", "StarterPlayerScripts", "JapanAtmosphere"}, patches = {{[===[
local inside=hrp and player.UserId==9611145467 and ]===], [===[
local inside=hrp and (player.UserId==9611145467 or player:GetAttribute('JapanPreviewAllowed')==true --[[JAPANGUEST1_20261015]]) and ]===], 1}}},
	{name = "JapanWaterAppearance", path = {"StarterPlayer", "StarterPlayerScripts", "JapanWaterAppearance"}, patches = {{[===[
local inside=p and Players.LocalPlayer.UserId==9611145467 and ]===], [===[
local inside=p and (Players.LocalPlayer.UserId==9611145467 or Players.LocalPlayer:GetAttribute('JapanPreviewAllowed')==true --[[JAPANGUEST1_20261015]]) and ]===], 1}}},
	{name = "MusicClient", path = {"Workspace", "MapMusic", "MusicClient"}, patches = {{[===[
local function areaAt(pos)
]===], [===[
local function isPreview() return player.UserId == 9611145467 or player:GetAttribute("JapanPreviewAllowed") == true end   -- JAPANGUEST1_20261015: the owner or a guest
local function areaAt(pos)
]===], 1}, {[===[
if player.UserId == 9611145467]===], [===[
if isPreview()]===], 4}}},
	{name = "AutomaticFoodSeatContact", path = nil, patches = {{[===[
if not player or player.UserId~=9611145467 or busy[player]then return end
]===], [===[
if not player or not (player.UserId==9611145467 or player:GetAttribute("JapanPreviewAllowed")==true) or busy[player]then return end   -- JAPANGUEST1_20261015
]===], 1}}},
}
local function find(path)
	local o = game
	for i, n in ipairs(path) do
		if i == 1 then o = game:GetService(n) else o = o:FindFirstChild(n) end
		if not o then return nil end
	end
	return o
end
local function countOf(s, f) local n, i = 0, 1; while true do local a, b = s:find(f, i, true); if not a then return n end; n += 1; i = b + 1 end end
local function patchOne(label, s, patches)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ JGUEST " .. label .. ": not found; skipped") return "missing" end
	local o = s.Source
	if o:find(MARK, 1, true) then print("QQ JGUEST " .. label .. ": already patched (" .. #o .. ")") return "already" end
	for i, p in ipairs(patches) do
		local c = countOf(o, p[1])
		if c ~= p[3] then print(string.format("QQ JGUEST %s: anchor %d found %d times (want %d); skipped - tell the cloud thread", label, i, c, p[3])) return "anchor" end
	end
	local n = o
	for _, p in ipairs(patches) do
		local out, i = {}, 1
		while true do
			local a, b = n:find(p[1], i, true)
			if not a then table.insert(out, n:sub(i)) break end
			table.insert(out, n:sub(i, a - 1)); table.insert(out, p[2]); i = b + 1
		end
		n = table.concat(out)
	end
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ JGUEST " .. label .. ": patched source does not compile: " .. tostring(err) .. "; skipped") return "compile" end
	local bn = s.Name .. "_pre_japanguest1"
	local k = 1; while hb:FindFirstChild(bn .. (k > 1 and ("_" .. k) or "")) do k += 1 end
	local c = s:Clone(); c.Name = bn .. (k > 1 and ("_" .. k) or ""); if c:IsA("BaseScript") then c.Enabled = false end; c.Parent = hb
	s.Source = n
	print(string.format("QQ JGUEST %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, c.Name))
	return "ok"
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before JapanGuest1") end)
local results = {}
for _, sc in ipairs(SCRIPTS) do
	if sc.path then
		table.insert(results, sc.name .. " " .. patchOne(sc.name, find(sc.path), sc.patches))
	else
		local J = workspace:FindFirstChild("JapanMap"); local n = 0
		for _, d in ipairs(J and J:GetDescendants() or {}) do
			if d.Name == sc.name and d:IsA("LuaSourceContainer") then n += 1; table.insert(results, sc.name .. "#" .. n .. " " .. patchOne(sc.name .. " (" .. d.Parent.Name .. ")", d, sc.patches)) end
		end
		if n == 0 then table.insert(results, sc.name .. " none found") end
	end
end
local acc = game:GetService("ServerScriptService"):FindFirstChild("JapanPreviewAccess")
if acc and acc:GetAttribute("GuestUserIds") == nil then acc:SetAttribute("GuestUserIds", "") end
local BF = workspace:FindFirstChild("BalloonField")
print("QQ JGUEST BalloonField.JapanPreview = " .. tostring(BF and BF:GetAttribute("JapanPreview")) .. " (false would give everyone, guests included, the ordinary ride)")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after JapanGuest1") end)
print("QQ JGUEST DONE: " .. table.concat(results, " | "))

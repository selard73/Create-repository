-- champion/once1 (job 26): EDIT mode. The Grand Keeper statue once per player, counted on France's 44 squirrels only
-- (Porto's 44 no longer raise the bar to 88 or let a Keeper win again). Four exact finds in
-- workspace.Champion.ChampionServer; compiled before writing; original -> ServerStorage.HudBackup.ChampionServer_pre_once1.
-- Output lines start with "QQ ONCE".
if game:GetService("RunService"):IsRunning() then warn("QQ ONCE ABORT - Play mode") return end
local C = workspace:FindFirstChild("Champion")
local s = C and C:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ ONCE ABORT - missing workspace.Champion.ChampionServer") return end
print("QQ ONCE ChampionServer is " .. #s.Source .. " chars")
local o = s.Source
for i, p in ipairs({{[===[
	for _, e in ipairs(hall) do if e.uid == uid and (tonumber(e.total) or 44) >= total then return true end end
]===], [===[
	for _, e in ipairs(hall) do if e.uid == uid then return true end end   -- once per player, whatever the total (Shannon, Oct 9 2026)
]===]}, {[===[
local function totalSquirrels()
	local ids, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and not ids[id] then ids[id] = true; n += 1 end
	end
	return n
end
]===], [===[
-- France only (Shannon, Oct 9 2026): the Keeper is French Squirrel Country's statue; Porto Nocciola has its own Guardian.
local frenchIds, FRANCE = {}, {forest = true, village = true, domaine = true}
pcall(function()
	local reg = require(workspace:WaitForChild("SquirrelScripts", 10):WaitForChild("SquirrelRegistry", 10))
	for _, e in ipairs(reg.squirrels or {}) do if FRANCE[e.map] then frenchIds[e.id] = true end end
end)
local function isPorto(m, id)
	if next(frenchIds) then return not frenchIds[id] end
	local ok, p = pcall(function() return m:GetPivot().Position end)   -- no registry to ask: Porto lies south of z -400
	return ok and p.Z < -400
end
local function totalSquirrels()
	local ids, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and not ids[id] and not isPorto(m, id) then ids[id] = true; n += 1 end
	end
	return n
end
local function frenchFound(pl) return (pl:GetAttribute("Found_forest") or 0) + (pl:GetAttribute("Found_village") or 0) + (pl:GetAttribute("Found_domaine") or 0) end
]===]}, {[===[
		local last = tonumber(player:GetAttribute("SquirrelsFound")) or 0
]===], [===[
		local last = frenchFound(player)
]===]}, {[===[
			local now = tonumber(player:GetAttribute("SquirrelsFound")) or 0
]===], [===[
			local now = frenchFound(player)
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ ONCE ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ ONCE ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ ONCE ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "ChampionServer_pre_once1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ ONCE DONE: ChampionServer %d chars; backup ServerStorage.HudBackup.ChampionServer_pre_once1", #s.Source))

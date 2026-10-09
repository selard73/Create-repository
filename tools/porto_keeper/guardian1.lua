-- porto_keeper/guardian1 (job 28): EDIT mode. The Guardian of the Harbour crowns a player who already holds all of
-- Porto's squirrels (counted from FoundIds; FoundIds changes watched; crowned on arrival when no Guardian stands yet).
-- Two exact finds in workspace.PortoKeeper.PortoKeeperServer (10419 chars, the job 24 text); compiled before writing;
-- original -> ServerStorage.HudBackup.PortoKeeperServer_pre_guardian1. Output lines start with "QQ GUARD".
if game:GetService("RunService"):IsRunning() then warn("QQ GUARD ABORT - Play mode") return end
print(string.format("QQ GUARD game.CreatorType=%s CreatorId=%d (the owner exclusion applies only to CreatorType User)", tostring(game.CreatorType), game.CreatorId))
local K = workspace:FindFirstChild("PortoKeeper")
local s = K and K:FindFirstChild("PortoKeeperServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ GUARD ABORT - missing workspace.PortoKeeper.PortoKeeperServer") return end
if #s.Source ~= 10419 then warn(string.format("QQ GUARD ABORT - PortoKeeperServer is %d chars, expected 10419 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{[===[
local function dateOf(t) return os.date("!%B %d, %Y", t) end
]===], [===[
local function dateOf(t) return os.date("!%B %d, %Y", t) end
-- Porto's finds counted from FoundIds (Oct 9 2026; Found_porto may lag or be missing), as the French Keeper counts
local PORTO_ID = {}
do
	local FRENCH = {forest = true, village = true, domaine = true}
	local ok, R = pcall(require, workspace.SquirrelScripts.SquirrelRegistry)
	if ok then for _, q in ipairs(R.squirrels) do if not FRENCH[q.map] then PORTO_ID[q.id] = true end end end
end
local function portoFound(player)
	local s = player:GetAttribute("FoundIds")
	if type(s) ~= "string" or next(PORTO_ID) == nil then return tonumber(player:GetAttribute("Found_porto")) or 0 end
	local n = 0
	for id in s:gmatch("[^,]+") do if PORTO_ID[id] then n += 1 end end
	return n
end
]===]}, {[===[
		local last = tonumber(player:GetAttribute("Found_porto")) or 0
		player:GetAttributeChangedSignal("Found_porto"):Connect(function()
			local now = tonumber(player:GetAttribute("Found_porto")) or 0
			if now >= need() and last < need() then task.spawn(crown, player) end
			last = now
		end)
]===], [===[
		local last = portoFound(player)
		if last >= need() and not first then task.spawn(crown, player) end   -- found them all before the Guardian stood here (Oct 9 2026)
		local function check()
			task.wait(0.2); local now = portoFound(player)
			if now >= need() and last < need() then task.spawn(crown, player) end
			last = now
		end
		player:GetAttributeChangedSignal("Found_porto"):Connect(check)
		player:GetAttributeChangedSignal("FoundIds"):Connect(check)
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ GUARD ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ GUARD ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ GUARD ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PortoKeeperServer_pre_guardian1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ GUARD DONE: PortoKeeperServer %d chars; backup ServerStorage.HudBackup.PortoKeeperServer_pre_guardian1", #s.Source))

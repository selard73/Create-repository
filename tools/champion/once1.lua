-- champion/once1 (job 26): EDIT mode. The Grand Keeper statue once per player: a Keeper never wins again, whatever the
-- squirrel total becomes. One exact find in workspace.Champion.ChampionServer (34314 chars, the job 24 text); compiled
-- before writing; original -> ServerStorage.HudBackup.ChampionServer_pre_once1.
-- Output lines start with "QQ ONCE".
if game:GetService("RunService"):IsRunning() then warn("QQ ONCE ABORT - Play mode") return end
local C = workspace:FindFirstChild("Champion")
local s = C and C:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ ONCE ABORT - missing workspace.Champion.ChampionServer") return end
if #s.Source ~= 34314 then warn(string.format("QQ ONCE ABORT - ChampionServer is %d chars, expected 34314 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{[===[
	for _, e in ipairs(hall) do if e.uid == uid and (tonumber(e.total) or 44) >= total then return true end end
]===], [===[
	for _, e in ipairs(hall) do if e.uid == uid then return true end end   -- once per player, whatever the total (Shannon, Oct 9 2026)
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

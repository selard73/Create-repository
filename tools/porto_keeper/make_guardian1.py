#!/usr/bin/env python3
"""Builds tools/porto_keeper/guardian1.lua (job 28): the Guardian of the Harbour fires for a player who already has all of
Porto Nocciola's squirrels. Shannon, Oct 9: "I am not sure that the guardian of the harbor statue thing works". Job 24
(the full PortoKeeperServer text, 10419 chars): it crowns only when Found_porto CHANGES across Need while the player is
in the server; Shannon had all 44 before the Guardian stood (Oct 7), so the moment never came. Now the count comes from
FoundIds (the Porto ids of the registry, as the French Keeper counts), FoundIds changes are watched too, and a player who
arrives with them all is crowned if no Guardian stands yet. Two exact finds; compiled before writing;
original -> ServerStorage.HudBackup.PortoKeeperServer_pre_guardian1. Also prints game.CreatorType / CreatorId, so we know
whether the owner exclusion (CreatorType User and the owner's id) applies to Shannon.
Run from the repo root: python3 tools/porto_keeper/make_guardian1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

F1 = 'local function dateOf(t) return os.date("!%B %d, %Y", t) end\n'
R1 = F1 + '''-- Porto's finds counted from FoundIds (Oct 9 2026; Found_porto may lag or be missing), as the French Keeper counts
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
'''
F2 = '''\t\tlocal last = tonumber(player:GetAttribute("Found_porto")) or 0
\t\tplayer:GetAttributeChangedSignal("Found_porto"):Connect(function()
\t\t\tlocal now = tonumber(player:GetAttribute("Found_porto")) or 0
\t\t\tif now >= need() and last < need() then task.spawn(crown, player) end
\t\t\tlast = now
\t\tend)
'''
R2 = '''\t\tlocal last = portoFound(player)
\t\tif last >= need() and not first then task.spawn(crown, player) end   -- found them all before the Guardian stood here (Oct 9 2026)
\t\tlocal function check()
\t\t\ttask.wait(0.2); local now = portoFound(player)
\t\t\tif now >= need() and last < need() then task.spawn(crown, player) end
\t\t\tlast = now
\t\tend
\t\tplayer:GetAttributeChangedSignal("Found_porto"):Connect(check)
\t\tplayer:GetAttributeChangedSignal("FoundIds"):Connect(check)
'''
# a syntax check of the new pieces in a stub of the script's surroundings
stub = ('local workspace, task, tonumber, type, next, pcall, require, ipairs, os = workspace, task, tonumber, type, next, pcall, require, ipairs, os\n'
        'local first, player; local function need() return 44 end; local function crown() end\n' + R1 + 'do\n' + R2 + 'end\n')
chk = ROOT / "tools/porto_keeper/check"; chk.mkdir(parents=True, exist_ok=True)
(chk / "pieces.lua").write_text(stub, encoding="utf-8")

lua = r'''-- porto_keeper/guardian1 (job 28): EDIT mode. The Guardian of the Harbour crowns a player who already holds all of
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
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}}) do
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
'''
for k, v in {"F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto_keeper/guardian1.lua").write_text(lua, encoding="utf-8")
print("guardian1.lua", len(lua.encode()), "chars; syntax stub tools/porto_keeper/check/pieces.lua")

#!/usr/bin/env python3
"""Builds tools/porto/opera_hush1.lua (job 19): the map music goes silent while the opera singer sings and comes back
2 s after she stops (Shannon, Oct 9). Patches workspace.PortoPassport.PortoActivities (job 17 text) by one exact find:
while OperaSong plays, every character within its RollOffMaxDistance gets NoMusic (MapMusic.MusicClient already goes
silent on it, as on the boat); 2 s (attr OperaMusicPause) after the song ends, the ones set here are cleared.
Characters that already had NoMusic (the boat) are never touched. Updates tools/porto/src/PortoActivities.lua.
Run from the repo root: python3 tools/porto/make_opera_hush1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/porto/src/PortoActivities.lua"

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

OLD = '\tsound.Ended:Connect(function() prompt.ActionText = "Listen"; listeners = {} end)\n'
NEW = OLD + '''\t-- Shannon, Oct 9: "the background music should go silent when she is singing, then pause for 2 seconds after she
\t-- stops, then resume". MusicClient goes silent while the character has NoMusic; hushed[] holds only the ones set here.
\tlocal hushed = {}
\tlocal function release(char) if hushed[char] then hushed[char] = nil; if char.Parent then char:SetAttribute("NoMusic", nil) end end end
\tlocal endedAt
\twhile true do
\t\ttask.wait(0.25)
\t\tif sound.IsPlaying then
\t\t\tendedAt = nil
\t\t\tfor _, pl in ipairs(Players:GetPlayers()) do
\t\t\t\tlocal char = pl.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
\t\t\t\tif root and (root.Position - part.Position).Magnitude <= sound.RollOffMaxDistance then
\t\t\t\t\tif not hushed[char] and not char:GetAttribute("NoMusic") then hushed[char] = true; char:SetAttribute("NoMusic", true) end
\t\t\t\telseif char and hushed[char] then release(char) end
\t\t\tend
\t\telseif next(hushed) then
\t\t\tendedAt = endedAt or os.clock()
\t\t\tif os.clock() - endedAt >= num("OperaMusicPause", 2) then for char in pairs(hushed) do release(char) end end
\t\tend
\tend
'''
src = SRC.read_text(encoding="utf-8")
if NEW in src: src = src.replace(NEW, OLD)
assert src.count(OLD) == 1
N = len(src.encode()); out = src.replace(OLD, NEW)
lua = r'''-- porto/opera_hush1 (job 19): EDIT mode. Map music silent while the opera singer sings, back 2 s after she stops.
-- One exact find in workspace.PortoPassport.PortoActivities (the job 17 text, @@N@@ chars); compiled before writing;
-- original -> ServerStorage.HudBackup.PortoActivities_pre_hush1. Output lines start with "QQ HUSH".
if game:GetService("RunService"):IsRunning() then warn("QQ HUSH ABORT - Play mode") return end
local PP = workspace:FindFirstChild("PortoPassport")
local s = PP and PP:FindFirstChild("PortoActivities")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ HUSH ABORT - missing workspace.PortoPassport.PortoActivities") return end
if #s.Source ~= @@N@@ then warn(string.format("QQ HUSH ABORT - PortoActivities is %d chars, expected @@N@@ (already patched, or changed); nothing changed", #s.Source)) return end
local OLD, NEW = @@OLD@@, @@NEW@@
local a, b = s.Source:find(OLD, 1, true)
if not a or s.Source:find(OLD, b + 1, true) then warn("QQ HUSH ABORT - the find does not match exactly once; nothing changed") return end
local o = s.Source:sub(1, a - 1) .. NEW .. s.Source:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ HUSH ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PortoActivities_pre_hush1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ HUSH DONE: PortoActivities %d -> %d chars; backup ServerStorage.HudBackup.PortoActivities_pre_hush1", @@N@@, #s.Source))
'''
for k, v in {"N": str(N), "OLD": L(OLD), "NEW": L(NEW)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/opera_hush1.lua").write_text(lua, encoding="utf-8")
SRC.write_text(out, encoding="utf-8")
print("opera_hush1.lua", len(lua.encode()), "; PortoActivities", N, "->", len(out.encode()))

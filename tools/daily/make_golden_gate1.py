#!/usr/bin/env python3
"""Builds tools/daily/golden_gate1.lua (job 101): the golden squirrel announcements show only on the French map (Shannon, Oct 15
2026: "that announcement about the daily questions and the golden squirrel in the french section carries over into the italy map,
those things should only show if you are on the french map"). Exact-string patches of workspace.Daily.DailyClient (the CLIENT
string of boundary/build_daily.lua): the pill under the purse and the card's golden line need the player's Area to be forest /
village / domaine, and the pill follows every Area change. The daily acorns card itself still shows everywhere (the acorns are
for everyone). The Question of the Day's reminders already carry their own French gate (QuestionClient,
FRENCH_QUESTION_REMINDERS_20261002_V1); the installer reports whether the live one has it.
Self-test: the patches applied to the repo's CLIENT and compiled with the luau CLI. Run from the repo root."""
import pathlib, re, subprocess, os
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

F1 = 'local pillPhase = phone and "gone" or "on"\n'
R1 = F1 + '''-- (Oct 15 2026, Shannon: the golden squirrel is a French affair - "those things should only show if you are on the french map")
local function inFrance() local a = player:GetAttribute("Area"); return a == "forest" or a == "village" or a == "domaine" end
'''
F2 = '\tgoldLine.Text = (state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""\n'
R2 = '\tgoldLine.Text = (inFrance() and state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""\n'
F3 = '\tpill.Visible = pillPhase == "on"\n'
R3 = '\tpill.Visible = pillPhase == "on" and inFrance()\n'
F4 = 'ev.OnClientEvent:Connect(function(what, a, b)\n\tif what == "state" and type(a) == "table" then\n\t\tsetPill(a)\n'
R4 = 'local lastState\nev.OnClientEvent:Connect(function(what, a, b)\n\tif what == "state" and type(a) == "table" then\n\t\tlastState = a\n\t\tsetPill(a)\n'
APPEND = '''
-- the pill follows the player from map to map (shown in France, hidden in Porto Nocciola)
player:GetAttributeChangedSignal("Area"):Connect(function() if lastState then setPill(lastState) end end)
'''
MARK = "local function inFrance()"

# ---- self-test on the repo's CLIENT ----
src = (ROOT / "boundary/build_daily.lua").read_text(encoding="utf-8")
client = re.search(r"local CLIENT = \[==\[\n(.*?)\]==\]", src, re.S).group(1)
test = client
for a, b in [(F1, R1), (F2, R2), (F3, R3), (F4, R4)]:
    assert test.count(a) == 1, a[:60]
    test = test.replace(a, b)
test += APPEND
chk = HERE / "check"; chk.mkdir(exist_ok=True)
(chk / "DailyClient_patched.lua").write_text(test, encoding="utf-8")
luau = os.environ.get("LUAU_COMPILE")
if luau:
    r = subprocess.run([luau, "--null", str(chk / "DailyClient_patched.lua")], capture_output=True, text=True)
    assert "Error" not in (r.stdout + r.stderr), r.stdout + r.stderr
    print("self-test: the patched DailyClient compiles")

lua = r'''-- daily/golden_gate1 (job 101): EDIT mode. The golden squirrel announcements show only on the French map (Shannon, Oct 15 2026).
-- Four exact-string patches of workspace.Daily.DailyClient + one appended watcher: the pill under the purse and the card's golden
-- line need the player's Area to be forest / village / domaine; the pill follows every Area change. The daily acorns card still
-- shows everywhere. Every anchor counted before anything changes; compiled where loadstring runs; original ->
-- ServerStorage.HudBackup.DailyClient_pre_golden1. Also reports whether workspace.DailyQuestion.QuestionClient carries its own
-- French gate (FRENCH_QUESTION_REMINDERS). Output lines "QQ GOLD".
if game:GetService("RunService"):IsRunning() then print("QQ GOLD ABORT - Play mode") return end
local Q = workspace:FindFirstChild("DailyQuestion"); local qc = Q and Q:FindFirstChild("QuestionClient")
print("QQ GOLD QuestionClient " .. (qc and (#qc.Source .. " chars, French gate " .. (qc.Source:find("FRENCH_QUESTION_REMINDERS", 1, true) and "present" or "ABSENT")) or "not found"))
local D = workspace:FindFirstChild("Daily")
local s = D and D:FindFirstChild("DailyClient")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ GOLD ABORT - missing workspace.Daily.DailyClient") return end
local o = s.Source
print("QQ GOLD DailyClient is " .. #o .. " chars")
local MARK = @@MARK@@
if o:find(MARK, 1, true) then print("QQ GOLD DONE (already patched): DailyClient " .. #o) return end
local P = {{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}, {@@F4@@, @@R4@@}}
for i, p in ipairs(P) do
	local a, b = o:find(p[1], 1, true)
	if not a then print("QQ GOLD ABORT - anchor " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then print("QQ GOLD ABORT - anchor " .. i .. " matches more than once; nothing changed") return end
end
local n = o
for _, p in ipairs(P) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
n = n .. @@APPEND@@
do
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ GOLD ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
if not backup:FindFirstChild("DailyClient_pre_golden1") then local c = s:Clone(); c.Name = "DailyClient_pre_golden1"; c.Enabled = false; c.Parent = backup end
s.Source = n
print(string.format("QQ GOLD DONE: DailyClient %d -> %d chars; backup ServerStorage.HudBackup.DailyClient_pre_golden1", #o, #n))
'''
for k, v in {"F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2), "F3": L(F3), "R3": L(R3), "F4": L(F4), "R4": L(R4), "APPEND": L(APPEND), "MARK": L(MARK)}.items():
    assert lua.count("@@" + k + "@@") == 1, k
    lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(HERE / "golden_gate1.lua").write_text(lua, encoding="utf-8")
print("golden_gate1.lua", len(lua.encode()), "bytes")

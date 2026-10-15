#!/usr/bin/env python3
"""Builds tools/daily/golden_gate2.lua (job 101 round 2): the Wise Squirrel draw announcement shows only on the French map.
Round 1 (golden_gate1) aborted: the live DailyClient already carries the Oct 2 French gate (FRENCH_ONLY_HUD_20261002_V1), so the
golden pill and the card's golden line are gated. What is NOT gated in the live QuestionClient (tools/tools_src/QuestionClient_phone1.lua
= the live 28598 chars): the "drawn" event - the banner "Today's Wise Squirrel: <name>!" sliding in at the top of EVERY player's screen
plus the chat line "<name> is today's Wise Squirrel!" / "Nobody got a Question of the Day right today. New ones are up!" - Italy
included. Shannon (Oct 15): "that announcement about the daily questions and the golden squirrel in the french section carries over
into the italy map, those things should only show if you are on the french map". One exact-string patch: the drawn block runs only
when frenchQuestionReminderAllowed() (Area forest / village / domaine; the function the reminders already use). The personal
"You're the Wise Squirrel!" prize banner stays everywhere (it explains the acorns that just arrived). Self-test: the patch applied to
the repo's live copy and compiled with the luau CLI (LUAU_COMPILE=path). Run from the repo root."""
import pathlib, subprocess, os
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

F1 = '''		if info.name then
			announce("Today's Wise Squirrel: " .. tostring(info.name) .. "!", "The answers were: " .. tostring(a.forest or "") .. "  and  " .. tostring(a.poste or ""), 8)
			chat(string.format("%s is today's Wise Squirrel! (%d right answers were in the draw)", tostring(info.name), info.count or 0))
		else
			chat("Nobody got a Question of the Day right today. New ones are up!")
		end
'''
R1 = '''		if not frenchQuestionReminderAllowed() then
			-- FRENCH_DRAWN_ANNOUNCE_20261015_V1 (Shannon, Oct 15 2026: the draw is a French affair - "those things should only show if you are on the french map")
		elseif info.name then
			announce("Today's Wise Squirrel: " .. tostring(info.name) .. "!", "The answers were: " .. tostring(a.forest or "") .. "  and  " .. tostring(a.poste or ""), 8)
			chat(string.format("%s is today's Wise Squirrel! (%d right answers were in the draw)", tostring(info.name), info.count or 0))
		else
			chat("Nobody got a Question of the Day right today. New ones are up!")
		end
'''
MARK = "FRENCH_DRAWN_ANNOUNCE_20261015_V1"
NEED = "local function frenchQuestionReminderAllowed()"

# ---- self-test on the repo's live copy ----
live = (ROOT / "tools/tools_src/QuestionClient_phone1.lua").read_text(encoding="utf-8")
assert len(live.encode("utf-8")) == 28598, len(live.encode("utf-8"))   # (the live script is 28598 bytes: the runner counts bytes)
assert live.count(F1) == 1 and NEED in live and MARK not in live
test = live.replace(F1, R1)
chk = HERE / "check"; chk.mkdir(exist_ok=True)
(chk / "QuestionClient_patched2.lua").write_text(test, encoding="utf-8")
luau = os.environ.get("LUAU_COMPILE")
if luau:
    r = subprocess.run([luau, "--null", str(chk / "QuestionClient_patched2.lua")], capture_output=True, text=True)
    assert "Error" not in (r.stdout + r.stderr), r.stdout + r.stderr
    print("self-test: the patched QuestionClient compiles")

lua = r'''-- daily/golden_gate2 (job 101 round 2): EDIT mode. The Wise Squirrel draw announcement (banner + chat line) shows only on the
-- French map (Shannon, Oct 15 2026). ONE exact-string patch of workspace.DailyQuestion.QuestionClient: the "drawn" block runs only
-- when frenchQuestionReminderAllowed() (the gate the reminders already use). The personal prize banner stays everywhere. The anchor
-- is counted before anything changes; the result is compiled where loadstring runs; original ->
-- ServerStorage.HudBackup.QuestionClient_pre_golden2. Output lines "QQ GOLD".
if game:GetService("RunService"):IsRunning() then print("QQ GOLD ABORT - Play mode") return end
local Q = workspace:FindFirstChild("DailyQuestion")
local s = Q and Q:FindFirstChild("QuestionClient")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ GOLD ABORT - missing workspace.DailyQuestion.QuestionClient") return end
local o = s.Source
print("QQ GOLD QuestionClient is " .. #o .. " chars")
local MARK = @@MARK@@
if o:find(MARK, 1, true) then print("QQ GOLD DONE (already patched): QuestionClient " .. #o) return end
if not o:find(@@NEED@@, 1, true) then print("QQ GOLD ABORT - QuestionClient has no frenchQuestionReminderAllowed(); nothing changed") return end
local F1, R1 = @@F1@@, @@R1@@
local a, b = o:find(F1, 1, true)
if not a then print("QQ GOLD ABORT - the drawn block was not found; nothing changed") return end
if o:find(F1, b + 1, true) then print("QQ GOLD ABORT - the drawn block matches more than once; nothing changed") return end
local n = o:sub(1, a - 1) .. R1 .. o:sub(b + 1)
do
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ GOLD ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
if not backup:FindFirstChild("QuestionClient_pre_golden2") then local c = s:Clone(); c.Name = "QuestionClient_pre_golden2"; c.Enabled = false; c.Parent = backup end
s.Source = n
print(string.format("QQ GOLD DONE: QuestionClient %d -> %d chars; backup ServerStorage.HudBackup.QuestionClient_pre_golden2", #o, #n))
'''
for k, v in {"F1": L(F1), "R1": L(R1), "MARK": L(MARK), "NEED": L(NEED)}.items():
    assert lua.count("@@" + k + "@@") == 1, k
    lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(HERE / "golden_gate2.lua").write_text(lua, encoding="utf-8")
print("golden_gate2.lua", len(lua.encode()), "bytes")

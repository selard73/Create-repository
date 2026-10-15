#!/usr/bin/env python3
"""Builds tools/croc/croc_portrait2.lua (job 113 round 2): the croc all-free card and the top-of-screen notes take turns. Runner 7's
play check of croc_portrait1 (phone rule): the croc card (y 62, DisplayOrder 19, now 138 tall for the heroes) covers the DailyCard when
both show at join, and the PortraitNote (y 70) when a portrait is hung during the card. Two exact-string patches over croc_portrait1:
 1. workspace.Lagoon.CrocClient celebrate(): waits (up to 8 s) while the daily card is down or the portrait note is showing;
 2. workspace.PortraitGallery.PortraitClient note handler: a note waits (up to 7 s) while the croc card (PlayerGui.CrocToast) is up.
No deadlock: the croc card waits only BEFORE it exists, the note only while it exists. Self-test against croc_portrait1's patched
builders (tools/croc/check/, written by make_croc_portrait1.py); LUAU_COMPILE=path compiles them. Run from the repo root."""
import pathlib, subprocess, os
HERE = pathlib.Path(__file__).resolve().parent
MARK = "CROCPORTRAIT2_20261015"
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
C1 = '''	celebratedOnce = true
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
'''
C1R = C1 + '''	-- CROCPORTRAIT2_20261015: the top of the screen is shared - wait (up to 8 s) while the daily card is down or the portrait note shows
	local function busy()
		local dg = pg:FindFirstChild("DailyGui"); local dc = dg and dg:FindFirstChild("DailyCard", true)
		if dc and dg.Enabled and dc.Visible and dc.Position.Y.Offset > -100 then return true end
		local pn = pg:FindFirstChild("PortraitNote"); local nt = pn and pn:FindFirstChildOfClass("TextLabel")
		if nt and nt.TextTransparency < 0.9 then return true end
		return false
	end
	local t0 = os.clock(); while busy() and os.clock() - t0 < 8 do task.wait(0.25) end
'''
P1 = '''	if what == "hungall" and uid == player.UserId then return end   -- CROCPORTRAIT1_20261015: the sitter has their own note
'''
P1R = P1 + '''	do local t0 = os.clock(); while player.PlayerGui:FindFirstChild("CrocToast") and os.clock() - t0 < 7 do task.wait(0.25) end end   -- CROCPORTRAIT2_20261015: after the croc card
'''
chk = HERE / "check"
croc = (chk / "build_croc_patched.lua").read_text(encoding="utf-8")
port = (chk / "build_portraits_patched.lua").read_text(encoding="utf-8")
assert croc.count(C1) == 1 and port.count(P1) == 1 and MARK not in croc and MARK not in port
(chk / "build_croc_patched2.lua").write_text(croc.replace(C1, C1R), encoding="utf-8")
(chk / "build_portraits_patched2.lua").write_text(port.replace(P1, P1R), encoding="utf-8")
luau = os.environ.get("LUAU_COMPILE")
if luau:
    for name in ("build_croc_patched2.lua", "build_portraits_patched2.lua"):
        s = (chk / name).read_text(encoding="utf-8"); i = 0; k = 0
        while True:
            a = s.find("[==[", i)
            if a < 0: break
            b = s.find("]==]", a); body = s[a + 4:b].lstrip("\n")
            f = chk / f"{name}_{k}.lua"; f.write_text(body, encoding="utf-8")
            r = subprocess.run([luau, "--null", str(f)], capture_output=True, text=True)
            assert "Error" not in (r.stdout + r.stderr), name + str(k) + r.stdout + r.stderr
            i = b + 4; k += 1
    print("self-test: the round-2 patched sources compile")
lua = r'''-- croc/croc_portrait2 (job 113 round 2): EDIT mode, after croc_portrait1. The croc all-free card and the top-of-screen notes take
-- turns (runner 7's phone check): (1) workspace.Lagoon.CrocClient celebrate() waits up to 8 s while the DailyCard is down or the
-- PortraitNote shows; (2) workspace.PortraitGallery.PortraitClient's note waits up to 7 s while PlayerGui.CrocToast is up. Each anchor
-- counted first, each result compiled, originals -> ServerStorage.HudBackup.<Name>_pre_crocportrait2. Output lines "QQ CROCP2".
if game:GetService("RunService"):IsRunning() then print("QQ CROCP2 ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local MARK = @@MARK@@
local function patch(label, s, find, repl)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ CROCP2 " .. label .. ": script not found; skipped") return false end
	local o = s.Source
	if o:find(MARK, 1, true) then print("QQ CROCP2 " .. label .. ": already patched (" .. #o .. " chars)") return true end
	local a, b = o:find(find, 1, true)
	if not a then print("QQ CROCP2 " .. label .. ": anchor not found (is croc_portrait1 in?); nothing changed") return false end
	if o:find(find, b + 1, true) then print("QQ CROCP2 " .. label .. ": anchor matches more than once; nothing changed") return false end
	local n = o:sub(1, a - 1) .. repl .. o:sub(b + 1)
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ CROCP2 " .. label .. ": patched source does not compile: " .. tostring(err) .. "; nothing changed") return false end
	local bn = s.Name .. "_pre_crocportrait2"
	if not backup:FindFirstChild(bn) then local c = s:Clone(); c.Name = bn; c.Enabled = false; c.Parent = backup end
	s.Source = n
	print(string.format("QQ CROCP2 %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, bn))
	return true
end
local Lg = workspace:FindFirstChild("Lagoon")
local G = workspace:FindFirstChild("PortraitGallery")
local r1 = patch("CrocClient", Lg and Lg:FindFirstChild("CrocClient"), @@C1@@, @@C1R@@)
local r2 = patch("PortraitClient", G and G:FindFirstChild("PortraitClient"), @@P1@@, @@P1R@@)
print(string.format("QQ CROCP2 DONE: CrocClient %s, PortraitClient %s", tostring(r1), tostring(r2)))
'''
for k, v in {"MARK": L(MARK), "C1": L(C1), "C1R": L(C1R), "P1": L(P1), "P1R": L(P1R)}.items():
    assert lua.count("@@" + k + "@@") == 1, k
    lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(HERE / "croc_portrait2.lua").write_text(lua, encoding="utf-8")
print("croc_portrait2.lua", len(lua.encode()), "bytes")

#!/usr/bin/env python3
"""Builds tools/croc/croc_portrait1.lua (job 113): the croc game's all-free shout capped for onlookers, the heroes pointed at the
painter, and a hung portrait announced game-wide. Shannon (Oct 15 2026): "almost everyone plays the save the squirrels from croc game
... game wide announcement ... not sure that's the best thing"; "no one is getting their portrait painted"; her picks: cap the shout
("you suggestion for the croc, yes"), option 1 + 3, wording "Heroes should have a portrait done! the painter is waiting...".
Three exact-string patches (each anchor counted first, the result compiled, the original kept in HudBackup):
 1. workspace.Lagoon.CrocClient, celebrate(names): onlookers (not among the rescuers) see the all-free card once a session; the
    rescuers always see it, and their card carries a third line: "Heroes should have a portrait done! The painter is waiting by the river."
 2. workspace.PortraitGallery.PortraitServer, hang(): after the sitter's "hung", everyone gets "hungall" with the sitter's name.
 3. workspace.PortraitGallery.PortraitClient, the note handler: "hungall" (not the sitter) shows "<name>'s new portrait is hanging in
    the painter's gallery by the river." for five seconds, the same note the sitter gets for their own.
Self-test: the anchors are found once in the repo's builders (forest/build_croc.lua, village/build_portraits.lua) and the patched
texts compile (LUAU_COMPILE=path). Run from the repo root."""
import pathlib, subprocess, os
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
MARK = "CROCPORTRAIT1_20261015"
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

# ---- 1. CrocClient ----
C1 = '''local function celebrate(names)
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
'''
C1R = '''local celebratedOnce = false                                                   -- CROCPORTRAIT1_20261015: onlookers see the all-free card once a session; the rescuers always do
local function celebrate(names)
	local mine = false
	for _, n in ipairs(type(names) == "table" and names or {}) do if n == player.DisplayName then mine = true end end
	if not mine and celebratedOnce then return end
	celebratedOnce = true
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
'''
C2 = '''	line("Madame Margaux says merci, " .. who .. "!", 52, 40, 18, C(240, 196, 110))
'''
C2R = C2 + '''	if mine then card.Size = UDim2.fromOffset(390, 138); line("Heroes should have a portrait done! The painter is waiting by the river.", 92, 40, 15, C(255, 244, 214)) end   -- (CROCPORTRAIT1: Shannon's line for the heroes)
'''
# ---- 2. PortraitServer ----
S1 = ''' if player.Parent then done:FireClient(player,"hung",{late=late==true,modelKey=model.Name})end
 return true
end
'''
S1R = ''' if player.Parent then done:FireClient(player,"hung",{late=late==true,modelKey=model.Name})end
 if player.Parent then done:FireAllClients("hungall",player.DisplayName,player.UserId)end   -- CROCPORTRAIT1_20261015: everyone hears a portrait was hung
 return true
end
'''
# ---- 3. PortraitClient (the note) ----
P1 = '''done.OnClientEvent:Connect(function(what, late)
	if what ~= "hung" and what ~= "deferred" then return end
	local v=player.PlayerGui:FindFirstChild("PortraitViewer");if what=="hung"and v and v.Page.Visible then return end
'''
P1R = '''done.OnClientEvent:Connect(function(what, late, uid)
	if what ~= "hung" and what ~= "deferred" and what ~= "hungall" then return end
	if what == "hungall" and uid == player.UserId then return end   -- CROCPORTRAIT1_20261015: the sitter has their own note
	local v=player.PlayerGui:FindFirstChild("PortraitViewer");if what=="hung"and v and v.Page.Visible then return end
'''
P2 = '''	if what=="deferred"then note.Text="Your paid portrait is still being prepared. You do not need to buy it again; the painter is retrying automatically, even if you leave."end
'''
P2R = P2 + '''	if what=="hungall"then note.Text=tostring(late).."'s new portrait is hanging in the painter's gallery by the river."end
'''
# ---- self-test on the repo's builders ----
croc = (ROOT / "forest/build_croc.lua").read_text(encoding="utf-8")
port = (ROOT / "village/build_portraits.lua").read_text(encoding="utf-8")
for src, f in ((croc, C1), (croc, C2), (port, S1), (port, P1), (port, P2)):
    assert src.count(f) == 1, f[:60]
assert MARK not in croc and MARK not in port
chk = HERE / "check"; chk.mkdir(exist_ok=True)
t1 = croc.replace(C1, C1R).replace(C2, C2R); t2 = port.replace(S1, S1R).replace(P1, P1R).replace(P2, P2R)
(chk / "build_croc_patched.lua").write_text(t1, encoding="utf-8"); (chk / "build_portraits_patched.lua").write_text(t2, encoding="utf-8")
luau = os.environ.get("LUAU_COMPILE")
if luau:
    for f in ("build_croc_patched.lua", "build_portraits_patched.lua"):
        r = subprocess.run([luau, "--null", str(chk / f)], capture_output=True, text=True)
        assert "Error" not in (r.stdout + r.stderr), f + r.stdout + r.stderr
    print("self-test: the patched builders compile")

lua = r'''-- croc/croc_portrait1 (job 113): EDIT mode. Three exact-string patches (Shannon, Oct 15 2026): (1) workspace.Lagoon.CrocClient - the
-- all-free card shows to onlookers once a session, always to the rescuers, whose card adds "Heroes should have a portrait done! The
-- painter is waiting by the river."; (2) workspace.PortraitGallery.PortraitServer - a hung portrait fires "hungall" to everyone;
-- (3) workspace.PortraitGallery.PortraitClient - "hungall" shows "<name>'s new portrait is hanging in the painter's gallery by the
-- river." Each anchor is counted before anything changes; each result is compiled; originals -> ServerStorage.HudBackup.<Name>_pre_crocportrait1.
-- Independent: a script that fails its checks is skipped and the others still go in. Output lines "QQ CROCP".
if game:GetService("RunService"):IsRunning() then print("QQ CROCP ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local MARK = @@MARK@@
local function patch(label, s, pairs_)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ CROCP " .. label .. ": script not found; skipped") return false end
	local o = s.Source
	if o:find(MARK, 1, true) then print("QQ CROCP " .. label .. ": already patched (" .. #o .. " chars)") return true end
	local n = o
	for i, pr in ipairs(pairs_) do
		local a, b = n:find(pr[1], 1, true)
		if not a then print("QQ CROCP " .. label .. ": anchor " .. i .. " not found; nothing changed - tell the cloud thread") return false end
		if n:find(pr[1], b + 1, true) then print("QQ CROCP " .. label .. ": anchor " .. i .. " matches more than once; nothing changed") return false end
		n = n:sub(1, a - 1) .. pr[2] .. n:sub(b + 1)
	end
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ CROCP " .. label .. ": patched source does not compile: " .. tostring(err) .. "; nothing changed") return false end
	local bn = s.Name .. "_pre_crocportrait1"
	if not backup:FindFirstChild(bn) then local c = s:Clone(); c.Name = bn; c.Enabled = false; c.Parent = backup end
	s.Source = n
	print(string.format("QQ CROCP %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, bn))
	return true
end
local Lg = workspace:FindFirstChild("Lagoon")
local G = workspace:FindFirstChild("PortraitGallery")
local r1 = patch("CrocClient", Lg and Lg:FindFirstChild("CrocClient"), {{@@C1@@, @@C1R@@}, {@@C2@@, @@C2R@@}})
local r2 = patch("PortraitServer", G and G:FindFirstChild("PortraitServer"), {{@@S1@@, @@S1R@@}})
local r3 = patch("PortraitClient", G and G:FindFirstChild("PortraitClient"), {{@@P1@@, @@P1R@@}, {@@P2@@, @@P2R@@}})
if r2 and not r3 then print("QQ CROCP NOTE: the server now fires 'hungall' but the client patch did not go in - harmless (the client ignores it), but the game-wide line will not show until it does") end
print(string.format("QQ CROCP DONE: CrocClient %s, PortraitServer %s, PortraitClient %s", tostring(r1), tostring(r2), tostring(r3)))
'''
for k, v in {"MARK": L(MARK), "C1": L(C1), "C1R": L(C1R), "C2": L(C2), "C2R": L(C2R), "S1": L(S1), "S1R": L(S1R), "P1": L(P1), "P1R": L(P1R), "P2": L(P2), "P2R": L(P2R)}.items():
    assert lua.count("@@" + k + "@@") == 1, k
    lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(HERE / "croc_portrait1.lua").write_text(lua, encoding="utf-8")
print("croc_portrait1.lua", len(lua.encode()), "bytes")

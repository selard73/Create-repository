#!/usr/bin/env python3
"""Builds tools/race/passport_race1.lua (job 38): the Passport outing for the Piazza Race (fired as "porto_race" by
PortoRace.RaceServer). Exact finds in workspace.Passport.Catalogue (11291 chars), Journal (14168) and PassportVisuals
(4105), the texts after jobs 17 and 25; originals -> ServerStorage.HudBackup.*_pre_race1.
Run from the repo root: python3 tools/race/make_passport_race1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
CAT_F = ' {id="keeper",name="Keeper of the Great Acorn"'
CAT_R = (' {id="porto_race",name="Piazza Race",area="porto",icon="flag",hint="Race to find all 15 squirrels of the Via della Piazza.",'
         'detail="Start at the gate by the piazza and find all fifteen squirrels of the Via della Piazza against the clock. Beat your own best time for a few acorns; the ten fastest go on the board."},\n' + CAT_F)
JR_F = ' elseif id=="keeper" then return "First to complete all 44 squirrels that day!'
JR_R = (' elseif id=="porto_race" then return string.format("Found all fifteen squirrels of the Via della Piazza in %d:%05.2f%s",math.floor((d.cs or 0)/6000),((d.cs or 0)%6000)/100,(d.improvement or 0)>0 and " - a personal best!" or ".")\n' + JR_F)
VIS_F = 'porto_beach="surfing_squirrel"}'
VIS_R = 'porto_beach="surfing_squirrel",porto_race="super_squirrel"}'
lua = r'''-- race/passport_race1 (job 38): EDIT mode. The Passport outing "Piazza Race" (porto_race). Exact finds in
-- workspace.Passport.Catalogue (11291), Journal (14168), PassportVisuals (4105); compiled before writing; originals ->
-- ServerStorage.HudBackup.*_pre_race1. Output lines "QQ PRACE".
if game:GetService("RunService"):IsRunning() then warn("QQ PRACE ABORT - Play mode") return end
local P = workspace:FindFirstChild("Passport")
local Cat, Jr, Vis = P and P:FindFirstChild("Catalogue"), P and P:FindFirstChild("Journal"), P and P:FindFirstChild("PassportVisuals")
if not (Cat and Jr and Vis) then warn("QQ PRACE ABORT - missing Passport.Catalogue / Journal / PassportVisuals") return end
for s, n in pairs({[Cat] = 11291, [Jr] = 14168, [Vis] = 4105}) do
	if #s.Source ~= n then warn(string.format("QQ PRACE ABORT - %s is %d chars, expected %d (already patched, or changed); nothing changed", s.Name, #s.Source, n)) return end
end
local PATCHES = {{Cat, "Catalogue", @@CAT_F@@, @@CAT_R@@}, {Jr, "Journal", @@JR_F@@, @@JR_R@@}, {Vis, "PassportVisuals", @@VIS_F@@, @@VIS_R@@}}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, f, r = pt[1], pt[2], pt[3], pt[4]
	local o = s.Source
	local a, b = o:find(f, 1, true)
	if not a then warn("QQ PRACE ABORT - " .. name .. " find not found; nothing changed") return end
	if o:find(f, b + 1, true) then warn("QQ PRACE ABORT - " .. name .. " find matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. r .. o:sub(b + 1)
	local fn, err = loadstring(o)
	if not fn then warn("QQ PRACE ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
for s, o in pairs(out) do local b = s:Clone(); b.Name = s.Name .. "_pre_race1"; b.Parent = backup; s.Source = o end
print(string.format("QQ PRACE DONE: Catalogue %d, Journal %d, PassportVisuals %d chars; backups ServerStorage.HudBackup.*_pre_race1", #Cat.Source, #Jr.Source, #Vis.Source))
'''
for k, v in {"CAT_F": L(CAT_F), "CAT_R": L(CAT_R), "JR_F": L(JR_F), "JR_R": L(JR_R), "VIS_F": L(VIS_F), "VIS_R": L(VIS_R)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/race/passport_race1.lua").write_text(lua, encoding="utf-8")
# the repo texts must hold the finds (Catalogue after job 17's insertion, Journal after job 17's lines)
import runpy
_w = pathlib.Path.write_text; pathlib.Path.write_text = lambda self, *a, **k: None
j17 = runpy.run_path(str(ROOT / "tools/porto/make_install_italy.py"), run_name="x")
pathlib.Path.write_text = _w
cat = (ROOT / "passport/src/Catalogue.lua").read_text(encoding="utf-8").replace(j17["CAT_OLD"], j17["CAT_NEW"])
jr = (ROOT / "passport/src/Journal.lua").read_text(encoding="utf-8").replace(j17["JOURNAL_OLD"], j17["JOURNAL_NEW"])
vis = (ROOT / "passport/src/PassportVisuals.lua").read_text(encoding="utf-8").replace(j17["VIS_OLD"], j17["VIS_NEW"])
for nm, txt, f in (("Catalogue", cat, CAT_F), ("Journal", jr, JR_F), ("PassportVisuals", vis, VIS_F)):
    if txt.count(f) != 1: print("note: the repo copy of", nm, "holds the find", txt.count(f), "times (Studio text differs from the repo; the Studio guard decides)")
chk = ROOT / "tools/race/check"; chk.mkdir(parents=True, exist_ok=True)
(chk / "Catalogue.lua").write_text(cat.replace(CAT_F, CAT_R), encoding="utf-8")
(chk / "Journal.lua").write_text(jr.replace(JR_F, JR_R), encoding="utf-8")
(chk / "PassportVisuals.lua").write_text(vis.replace(VIS_F, VIS_R), encoding="utf-8")
print("passport_race1.lua", len(lua.encode()), "chars; check copies in tools/race/check")

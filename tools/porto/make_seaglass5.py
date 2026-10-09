#!/usr/bin/env python3
"""Builds tools/porto/seaglass5.lua (job 41): Bella's panel steps aside for the reveal. Shannon (VR, Oct 9): "the menu for
what to sell her blocks the actual reveal and her dialogue; it sits right on top of it". When something is made the panel
hides for six seconds (her words and the reveal show), then comes back if still open. One exact find in
workspace.SeaGlass.SeaGlassClient as it stands after job 39 (12895 chars + job 39's two lines); original ->
ServerStorage.HudBackup.SeaGlassClient_pre_seaglass5. Run from the repo root: python3 tools/porto/make_seaglass5.py
"""
import pathlib, runpy
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
_w = pathlib.Path.write_text; pathlib.Path.write_text = lambda self, *a, **k: None
g4 = runpy.run_path(str(ROOT / "tools/porto/make_seaglass4.py"), run_name="x")
pathlib.Path.write_text = _w
N = 12895 + sum(len(b.encode()) - len(a.encode()) for a, b in g4["CLI"])
F1 = "\t\tsay(line or \"Bellissima!\", 5)\n\t\trefresh()\n\t\treveal(a)\n"
R1 = F1 + "\t\tpanel.Visible = false; task.delay(6, function() if open then panel.Visible = true; refresh() end end)   -- the panel would sit on the reveal and her words (Shannon, VR)\n"
# the panel sat dead centre, over Bella and her speech bubble (Shannon, desktop): it moves to the right side of the screen
F2 = "local panel = Instance.new(\"Frame\"); panel.Name = \"Panel\"; panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)\n"
R2 = "local panel = Instance.new(\"Frame\"); panel.Name = \"Panel\"; panel.AnchorPoint = Vector2.new(1, 0.5); panel.Position = UDim2.new(1, -14, 0.5, 0)   -- at the right: Bella and her words stay in view (Oct 9)\n"
src = ROOT / "tools/porto/src/SeaGlassClient.lua"; t = src.read_text(encoding="utf-8")
for a, b in ((F1, R1), (F2, R2)):
    if b not in t: assert t.count(a) == 1, a[:50]; t = t.replace(a, b)
src.write_text(t, encoding="utf-8")
lua = r'''-- porto/seaglass5 (job 41): EDIT mode. Bella's panel moves to the right side of the screen (it covered her and her speech
-- bubble) and hides for six seconds when something is made, so the reveal and her words are seen. Two exact finds in workspace.SeaGlass.SeaGlassClient (@@N@@ chars, after job 39); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass5. Output "QQ SG5".
if game:GetService("RunService"):IsRunning() then warn("QQ SG5 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG5 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if #s.Source ~= @@N@@ then warn(string.format("QQ SG5 ABORT - SeaGlassClient is %d chars, expected @@N@@ (job 39 not run yet, already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG5 ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG5 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG5 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass5"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG5 DONE: SeaGlassClient %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass5", #s.Source))
'''
for k, v in {"N": str(N), "F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass5.lua").write_text(lua, encoding="utf-8")
print("seaglass5.lua", len(lua.encode()), "chars; expects SeaGlassClient", N)

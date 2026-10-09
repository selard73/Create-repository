#!/usr/bin/env python3
"""Builds tools/passport/pages2.lua (job 30): one-line fix to job 25. mark() looked up the stamped outing's page
(_batch_porto for Porto) but wrote it back as _batch, so every Porto stamp copied the Porto page over the French page
(seen in the job 25 play test: both pages identical, French tab empty, Porto header 0 of 5). PassportServer is 9188
chars after pages1. Original -> ServerStorage.HudBackup.PassportServer_pre_pages2. Run: python3 tools/passport/make_pages2.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = ' local batch=s.journal[J.cityOf(id)=="italy" and "_batch_porto" or "_batch"]\n if batch then\n'
R1 = ' local pageKey=J.cityOf(id)=="italy" and "_batch_porto" or "_batch"\n local batch=s.journal[pageKey]\n if batch then\n'
F2 = '  if changed then write(p,"_batch",b) end\n'
R2 = '  if changed then write(p,pageKey,b) end\n'
lua = r'''-- passport/pages2 (job 30): EDIT mode. Fix to job 25: a stamp updated the right page but wrote it back under the French
-- key, so Porto stamps copied the Porto page over the French page. Two exact finds in workspace.Passport.PassportServer
-- (9188 chars); compiled before writing; original -> ServerStorage.HudBackup.PassportServer_pre_pages2. Output "QQ PAGE2".
if game:GetService("RunService"):IsRunning() then warn("QQ PAGE2 ABORT - Play mode") return end
local P = workspace:FindFirstChild("Passport")
local s = P and P:FindFirstChild("PassportServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ PAGE2 ABORT - missing Passport.PassportServer") return end
if #s.Source ~= 9188 then warn(string.format("QQ PAGE2 ABORT - PassportServer is %d chars, expected 9188 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ PAGE2 ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ PAGE2 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ PAGE2 ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PassportServer_pre_pages2"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ PAGE2 DONE: PassportServer %d chars; backup ServerStorage.HudBackup.PassportServer_pre_pages2", #s.Source))
'''
for k, v in {"F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
(ROOT / "tools/passport/pages2.lua").write_text(lua, encoding="utf-8")
# the repo server with pages1 applied must contain both finds exactly once
import runpy
_w = pathlib.Path.write_text; pathlib.Path.write_text = lambda self, *a, **k: None
p1 = runpy.run_path(str(ROOT / "tools/passport/make_pages1.py"), run_name="x")
pathlib.Path.write_text = _w
srv = (ROOT / "passport/src/PassportServer.lua").read_text(encoding="utf-8")
for a, b in p1["SERVER"][:3] + p1["SERVER"][5:]: srv = srv.replace(a, b)          # pages1 without its own mark fix = Studio after job 25
srv = srv.replace(' local batch=s.journal._batch\n if batch then\n', F1)
assert srv.count(F1) == 1 and srv.count(F2) == 1, "finds"
print("pages2.lua", len(lua.encode()), "chars; Studio-state check ok")

#!/usr/bin/env python3
"""Builds tools/passport/pages1.lua (job 25): the Passport gives five outings at a time PER MAP (Shannon, Oct 9 VR test:
"I thought it was just supposed to give you 5 then when you finish those give you 5 more, but here it seems to just give
all of them"). Before: one page (_batch) drew from the whole catalogue; the Porto tab showed either nothing or, after job
18, every Porto outing. Now: _batch is the French page and _batch_porto the Porto page (opened once Item_porto >= 1); each
is five outings, "Explore more" turns that map's page. Patches workspace.Passport.Journal, PassportServer, PassportClient
by exact finds (guards: Journal 13882 and PassportClient 28273 chars, the job 18 texts; PassportServer any length, every
find once). Originals -> ServerStorage.HudBackup.*_pre_pages1. Run from the repo root: python3 tools/passport/make_pages1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

JOURNAL = [
    ('J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end\n',
     'J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end\n'
     'function J.cityOf(id) local e=J.byId[id];return (e and e.area=="porto") and "italy" or "france" end -- pages are per map (Oct 9 2026)\n'),
    (' if not J.byId[id] and id~="_batch" then return nil end',
     ' if not J.byId[id] and id~="_batch" and id~="_batch_porto" then return nil end'),
    ('function J.nextBatch(prior,eligible,memories)\n', 'function J.nextBatch(prior,eligible,memories,city)\n'),
    ('  for _,e in ipairs(catalogue) do if eligible(e) and not seen[e.id] and not (memories and memories[e.id]) and #ids<5 then ids[#ids+1]=e.id end end',
     '  for _,e in ipairs(catalogue) do if J.cityOf(e.id)==(city or "france") and eligible(e) and not seen[e.id] and not (memories and memories[e.id]) and #ids<5 then ids[#ids+1]=e.id end end'),
    ('function J.reconcileBatch(prior,eligible,memories)\n if not prior then return J.nextBatch(nil,eligible,memories)end',
     'function J.reconcileBatch(prior,eligible,memories,city)\n if not prior then return J.nextBatch(nil,eligible,memories,city)end'),
    ("  if (record and record.data.historical) or (not record and not oldDone[id] and not eligible(J.byId[id]))then",
     "  if (record and record.data.historical) or J.cityOf(id)~=(city or \"france\") or (not record and not oldDone[id] and not eligible(J.byId[id]))then"),
    ('   if #ids<5 and eligible(e) and not used[e.id] and not memories[e.id] and not oldDone[e.id] then',
     '   if #ids<5 and J.cityOf(e.id)==(city or "france") and eligible(e) and not used[e.id] and not memories[e.id] and not oldDone[e.id] then'),
]
SERVER = [
    (' if e.bonus then return false end\n',
     ' if e.bonus then return false end\n if e.area=="porto" and item(p,"porto")<1 then return false end -- the Porto page opens on arrival in the harbour\n'),
    ('''local function repairPage(p)
 local s=states[p];if not s then return end
 local old=s.journal._batch
 local b=J.reconcileBatch(old and old.data,function(e)return eligible(p,e)end,s.journal)
 if not old or old.data.ids~=b.ids or old.data.done~=b.done or old.data.seen~=b.seen then write(p,"_batch",b)end
end
''', '''-- One page of five per map (Oct 9 2026): _batch is French Squirrel Country, _batch_porto is Porto Nocciola.
local PAGES={{key="_batch",city="france"},{key="_batch_porto",city="italy"}}
local function pageOpen(p,pg) return pg.city=="france" or item(p,"porto")>=1 end
local function repairPage(p)
 local s=states[p];if not s then return end
 for _,pg in ipairs(PAGES) do
  local old=s.journal[pg.key]
  if old or pageOpen(p,pg) then
   local b=J.reconcileBatch(old and old.data,function(e)return eligible(p,e)end,s.journal,pg.city)
   if not old or old.data.ids~=b.ids or old.data.done~=b.done or old.data.seen~=b.seen then write(p,pg.key,b)end
  end
 end
end
'''),
    ('''local function advance(p)
 local s=states[p];if not s then return false,"Your Passport is still loading." end
 repairPage(p)
 local b=s.journal._batch
 if b and #J.ids(b.data.ids)>0 and not J.batchDone(b.data) then return false,"Stamp these outings before opening the next page." end
 write(p,"_batch",J.nextBatch(b and b.data,function(e) return eligible(p,e) end,s.journal))
 return true
end
local function fillEmpty(p)
 local s=states[p];local b=s and s.journal._batch
 if not b or #J.ids(b.data.ids)>0 then return end
 local nextPage=J.nextBatch(b.data,function(e)return eligible(p,e)end,s.journal)
 if #J.ids(nextPage.ids)>0 then write(p,"_batch",nextPage)end
end
''', '''local function advance(p,city)
 local s=states[p];if not s then return false,"Your Passport is still loading." end
 repairPage(p)
 local pg=city=="italy" and PAGES[2] or PAGES[1]
 local b=s.journal[pg.key]
 if b and #J.ids(b.data.ids)>0 and not J.batchDone(b.data) then return false,"Stamp these outings before opening the next page." end
 write(p,pg.key,J.nextBatch(b and b.data,function(e) return eligible(p,e) end,s.journal,pg.city))
 return true
end
local function fillEmpty(p)
 local s=states[p];if not s then return end
 for _,pg in ipairs(PAGES) do
  local b=s.journal[pg.key]
  if b and #J.ids(b.data.ids)==0 then
   local nextPage=J.nextBatch(b.data,function(e)return eligible(p,e)end,s.journal,pg.city)
   if #J.ids(nextPage.ids)>0 then write(p,pg.key,nextPage)end
  end
 end
end
'''),
    (' local batch=s.journal._batch\n if batch then\n',
     ' local pageKey=J.cityOf(id)=="italy" and "_batch_porto" or "_batch"\n local batch=s.journal[pageKey]\n if batch then\n'),
    ('  if changed then write(p,"_batch",b) end\n', '  if changed then write(p,pageKey,b) end\n'),   # (pages2 fixed this in Studio: the stamp went back under the French key)
    (' p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" or name=="Found_domaine" then task.defer(fillEmpty,p)end end)',
     ' p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" or name=="Found_domaine" or name=="Item_porto" then task.defer(function()repairPage(p);fillEmpty(p)end)end end)'),
    ('action.OnServerInvoke=function(p,what)\n', 'action.OnServerInvoke=function(p,what,city)\n'),
    (' return advance(p)\nend', ' return advance(p,city)\nend'),
]
CLIENT = [
    ('\n  if showCities() and city=="italy" then ids,done={},{} for _,e in ipairs(catalogue)do if e.area=="porto" then ids[#ids+1]=e.id;if journal[e.id]then done[#done+1]=e.id end end end end',
     ''),
    ('local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)',
     'local pageKey=(showCities() and city=="italy") and "_batch_porto" or "_batch";local batch=journal[pageKey] and journal[pageKey].data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)'),
    ('if J.batchDone(batch) and not (showCities() and city=="italy") then', 'if J.batchDone(batch) then'),
    ('return F.PassportAction:InvokeServer("more")', 'return F.PassportAction:InvokeServer("more",(showCities() and city=="italy") and "italy" or "france")'),
    ('addRow("porto","Porto Nocciola is new","Your Italian outings are the boat trip, the falls, the parachute landing and the arrival itself. More arrive as the harbour grows.",nil,nil,true,"More to come")',
     'addRow("porto","Porto Nocciola","Your Italian outings appear here five at a time once you have arrived in the harbour. Finish them and the next five follow.",nil,nil,true,"More to come")'),
]
# the repo copies: every find must exist in them (PassportClient's job 18 lines are applied first to mirror Studio)
src = {n: (ROOT / "passport/src" / (n + ".lua")).read_text(encoding="utf-8") for n in ("Journal", "PassportServer", "PassportClient")}
import runpy
for name, pairs in (("Journal", JOURNAL), ("PassportServer", SERVER)):
    for a, b in pairs: assert src[name].count(a) == 1, (name, a[:60])
for a, b in CLIENT[1:]:
    if a.startswith("if J.batchDone(batch) and not (showCities() and city==\"italy\")"): continue   # job 18 text, Studio only
    assert src["PassportClient"].count(a) == 1 or a.startswith("local batch=journal._batch"), ("PassportClient", a[:60])

lua = r'''-- passport/pages1 (job 25): EDIT mode. Five outings at a time PER MAP: _batch = French Squirrel Country, _batch_porto =
-- Porto Nocciola (opens once Item_porto >= 1). "Explore more" turns that map's page. Exact-find patches on
-- workspace.Passport.Journal (13882 chars), PassportServer (any length) and PassportClient (28273); every find must hit
-- exactly once and every result must compile, or nothing is written. Originals -> ServerStorage.HudBackup.*_pre_pages1.
-- Output lines start with "QQ PAGE".
if game:GetService("RunService"):IsRunning() then warn("QQ PAGE ABORT - Play mode") return end
local P = workspace:FindFirstChild("Passport")
local Jr, Sv, Cl = P and P:FindFirstChild("Journal"), P and P:FindFirstChild("PassportServer"), P and P:FindFirstChild("PassportClient")
for _, pair in ipairs({{Jr, "Journal"}, {Sv, "PassportServer"}, {Cl, "PassportClient"}}) do
	if not (pair[1] and pair[1]:IsA("LuaSourceContainer")) then warn("QQ PAGE ABORT - missing Passport." .. pair[2]) return end
end
for s, n in pairs({[Jr] = 13882, [Cl] = 28273}) do
	if #s.Source ~= n then warn(string.format("QQ PAGE ABORT - %s.Source is %d chars, expected %d (already patched, or changed); nothing changed", s.Name, #s.Source, n)) return end
end
print("QQ PAGE PassportServer is " .. #Sv.Source .. " chars")
local PATCHES = {{Jr, "Journal", @@JOURNAL@@}, {Sv, "PassportServer", @@SERVER@@}, {Cl, "PassportClient", @@CLIENT@@}}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, list = pt[1], pt[2], pt[3]
	local o = s.Source
	for i, p in ipairs(list) do
		local a, b = o:find(p[1], 1, true)
		if not a then warn("QQ PAGE ABORT - " .. name .. " find " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then warn("QQ PAGE ABORT - " .. name .. " find " .. i .. " matches more than once; nothing changed") return end
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ PAGE ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
for s, o in pairs(out) do
	local b = s:Clone(); b.Name = s.Name .. "_pre_pages1"
	if b:IsA("BaseScript") then b.Enabled = false end
	b.Parent = backup; s.Source = o
end
print(string.format("QQ PAGE DONE: Journal %d, PassportServer %d, PassportClient %d chars; backups ServerStorage.HudBackup.*_pre_pages1", #Jr.Source, #Sv.Source, #Cl.Source))
'''
def tbl(pairs): return "{" + ", ".join("{%s, %s}" % (L(a), L(b)) for a, b in pairs) + "}"
for k, v in {"JOURNAL": tbl(JOURNAL), "SERVER": tbl(SERVER), "CLIENT": tbl(CLIENT)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/passport").mkdir(exist_ok=True)
(ROOT / "tools/passport/pages1.lua").write_text(lua, encoding="utf-8")
# syntax check material: the repo copies with the patches applied (PassportClient after the job 17 + 18 texts)
chk = ROOT / "tools/passport/check"; chk.mkdir(exist_ok=True)
for name, pairs in (("Journal", JOURNAL), ("PassportServer", SERVER)):
    t = src[name]
    for a, b in pairs: t = t.replace(a, b)
    (chk / (name + ".lua")).write_text(t, encoding="utf-8")
_write = pathlib.Path.write_text; pathlib.Path.write_text = lambda self, *a, **k: None   # the job 17/18 generators must not rewrite their files here
j17 = runpy.run_path(str(ROOT / "tools/porto/make_install_italy.py"), run_name="x")
t = src["PassportClient"]
for a, b in ((j17["CL_OLD_1"], j17["CL_NEW_1"]), (j17["CL_OLD_2"], j17["CL_NEW_2"]), (j17["CL_OLD_3"], j17["CL_NEW_3"])): t = t.replace(a, b)
j18 = runpy.run_path(str(ROOT / "tools/porto/make_italy_fix1.py"), run_name="x")
pathlib.Path.write_text = _write
t = t.replace(j18["PC_OLD_1"], j18["PC_NEW_1"]).replace(j18["PC_OLD_2"], j18["PC_NEW_2"])
for a, b in CLIENT: assert t.count(a) == 1, ("client find", a[:50]); t = t.replace(a, b)
(chk / "PassportClient.lua").write_text(t, encoding="utf-8")
print("pages1.lua", len(lua.encode()), "chars; check copies in tools/passport/check")

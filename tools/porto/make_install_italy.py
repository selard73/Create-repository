#!/usr/bin/env python3
"""Builds tools/porto/install_italy.lua: ONE Studio script (EDIT mode) that installs the Italy passport outings and Bella's
beach game. Everything is exact-string patching with guards, or new instances; originals go to ServerStorage.HudBackup.

Passport (workspace.Passport), patched by exact finds:
  Catalogue (7793 chars)      ten Porto entries inserted before the Keeper entry
  Journal (12486 chars)       describe lines for them, inserted before the keeper line
  PassportVisuals (3783)      map[...] gets an art key per new id (existing PassportArt models reused)
  PassportClient (27056)      hintFor(e): progress lines for the three find outings and the beach; re-render on FoundIds / finds
Workspace.Grotta.PolpoServer: its "rescue" fire (the French swamp stamp) becomes "porto_polpo".
New: RS.PortoAreas (ModuleScript), workspace.PortoPassport.PortoActivities (Script), workspace.SeaGlass {SeaGlassServer,
SeaGlassClient (RunContext Client), Recipes, SeaGlassEvent (RemoteEvent), Pieces (Folder)} with attributes.
Run from the repo root: python3 tools/porto/make_install_italy.py
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/porto/src"

def read(name):
    return (SRC / name).read_text(encoding="utf-8")

def L(s, lvl="==="):      # a Lua long string; its first newline is dropped by Lua, so start the content on the next line
    assert ("]" + lvl + "]") not in s, "long-string terminator inside embedded text"
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

# ---------------- the catalogue entries ----------------
CAT_OLD = ' {id="keeper",name="Keeper of the Great Acorn"'
CAT_NEW = ''' {id="porto_harbour",name="Friends of the harbour",area="porto",icon="rescue",hint="Meet every squirrel at the harbour.",detail="Fifteen squirrels live and work round the harbour of Porto Nocciola: on the quay, the piers, the fish market and the beach beside it. Click each one or run into it. Your Passport counts them as you go."},
 {id="porto_borgo",name="Friends of the Via della Piazza",area="porto",icon="rescue",hint="Meet every squirrel in the town.",detail="Fifteen squirrels are up the hill in the town: the piazza with its fountain, the pizzeria and the bakery, the clock tower and the lanes. Click each one or run into it."},
 {id="porto_groves",name="Friends of the Groves",area="porto",icon="rescue",hint="Meet every squirrel in the Groves.",detail="Fourteen squirrels are out in the Groves and along the coast: the lemon and olive terraces, the lighthouse, the cliffs, the sand spit and the beach. Click each one or run into it."},
 {id="porto_bell",name="A ringing buongiorno",area="porto",icon="bell",hint="Ring the brass bell at the harbour office.",detail="The Capitaneria del Porto by the quay keeps a brass harbour bell. Walk up to it and give it a ring to tell Porto Nocciola you have arrived."},
 {id="cappuccino",name="Cappuccino zoomies",area="porto",icon="coffee",hint="Drink a cappuccino at the piazza.",detail="Sit at a table at the pizzeria, the bakery or the gelateria and drink a cappuccino for 5 acorns. It gives you extra speed for five minutes. Try it on the Scalinata dei Fiori!"},
 {id="porto_lemon",name="When life gives you lemons",area="porto",icon="acorn",hint="Buy a lemon from the Lemon Seller.",detail="The Lemon Seller Squirrel in the Groves sells lemons for 8 acorns. Buy one and it goes in your purse. They say the parfumerie in France will want them one day."},
 {id="porto_crabs",name="Beppe's bucket",area="porto",icon="boat",hint="Catch crabs and sell them to Beppe at the fish market.",detail="Buy a crab trap in the Acorn Store, cast it from the tide pools or the little cove, wait, and pull it in. Take your catch to Beppe at the fish market: 3 acorns a crab, and a golden crab is worth 100!"},
 {id="porto_funicular",name="Up the hill",area="porto",icon="flag",hint="Ride the funicular up from the harbour.",detail="The funicular runs from the bottom stop by the harbour up to the town. Step into a car at either end and ride it all the way. Mind the view out of the left side on the way up."},
 {id="porto_opera",name="Bravo!",area="porto",icon="book",hint="Listen to the opera duet in the piazza.",detail="The Fat Lady Squirrel and Nino the accordion player perform in the piazza. Walk up to her and choose Listen to hear her sing. Bravo, bravissima!"},
 {id="porto_polpo",name="Grotta rescue",area="porto",icon="rescue",hint="Free the young squirrels from Polpo Brontolone.",detail="Polpo Brontolone, the grumpy octopus, keeps three young squirrels in cages at the back of the Grotta Azzurra. Climb over him while he dozes and open every cage. If he wakes, the slingshot helps."},
 {id="porto_beach",name="Bella's beach finds",area="porto",icon="glace",hint="Collect sea glass and shells on the beach and make something with Bella.",detail="The sand round the Sea Glass Collector Squirrel (call her Bella) is scattered with sea glass and shells. Pick them up and show them to her: she makes a suncatcher, a shell necklace or a vase with you and pays you acorns. Find the purple piece and she makes you a parfum bottle to keep for France."},
''' + CAT_OLD

# ---------------- the journal lines ----------------
JOURNAL_OLD = ' elseif id=="keeper" then return "First to complete all 44 squirrels that day!'
JOURNAL_NEW = ''' elseif id=="porto_harbour" or id=="porto_borgo" or id=="porto_groves" then return "Met every squirrel in "..(d.area or "that part of Porto Nocciola").."! "..tostring(d.found or "All").." new friends."
 elseif id=="porto_bell" then return "Rang the brass bell at the Capitaneria del Porto. Buongiorno, Porto Nocciola!"
 elseif id=="cappuccino" then return string.format("Drank a cappuccino in the piazza and zoomed round Porto Nocciola at +%d%% for %s minutes.",d.boost or 35,tostring((d.seconds or 300)/60))
 elseif id=="porto_lemon" then return "Bought a lemon from the Lemon Seller in the Groves. Keep it for the parfumerie!"
 elseif id=="porto_crabs" then return "Sold your catch to Beppe at the fish market"..((d.gold or 0)>0 and ", and one of them was golden!" or ".")
 elseif id=="porto_funicular" then return "Rode the funicular up the hill above Porto Nocciola. What a view!"
 elseif id=="porto_opera" then return "Stood in the piazza and heard The Fat Lady Squirrel sing, with Nino on the accordion. Bravo!"
 elseif id=="porto_polpo" then return "Freed the young squirrels from Polpo Brontolone's cages in the Grotta Azzurra."
 elseif id=="porto_beach" then return "Combed the beach for sea glass and shells and made a "..(d.made and d.made:lower() or "treasure").." with Bella."..((d.prize or 0)>0 and (" She paid "..d.prize.." acorns.") or (d.kept and " It is yours to keep." or ""))
''' + JOURNAL_OLD

# ---------------- the visuals map ----------------
VIS_OLD = 'photos="camera"}'
VIS_NEW = ('photos="camera",porto_harbour="fishing_squirrel",porto_borgo="waiter_squirrel",porto_groves="birdwatch_squirrel",'
           'porto_bell="church",cappuccino="coffee",porto_lemon="sunflower_squirrel",porto_crabs="squirrel_buccaneer",'
           'porto_funicular="ski_squirrel",porto_opera="glam_squirrel",porto_polpo="super_squirrel",porto_beach="surfing_squirrel"}')

# ---------------- PassportClient: progress hints and re-render ----------------
CL_OLD_1 = ''' return #have.." of 4 photos ("..table.concat(have,", ").."). Still to find: "..table.concat(need,", ").."."
end
'''
CL_NEW_1 = CL_OLD_1 + '''-- Porto outings (Oct 9 2026): the three "meet every squirrel" lines count from FoundIds; the beach counts kinds found
local PortoAreas;pcall(function()PortoAreas=require(game:GetService("ReplicatedStorage"):WaitForChild("PortoAreas",5))end)
local function hintFor(e)
 if e.id=="photos" then return photoHint() end
 if PortoAreas then
  for area,ids in pairs(PortoAreas.lists)do
   if PortoAreas.outing[area]==e.id then
    local have={};for id in string.gmatch(p:GetAttribute("FoundIds") or "","[^,]+")do have[id]=true end
    local n=0;for _,id in ipairs(ids)do if have[id] then n+=1 end end
    return string.format("%d of %d squirrels found in %s.",n,#ids,PortoAreas.names[area])
   end
  end
  if e.id=="porto_beach" then
   local n=0;for _,k in ipairs(PortoAreas.beachKinds)do if item(k)>0 then n+=1 end end
   if n>0 then return string.format("%d of %d kinds of beach finds so far. Show them to Bella on the Spiaggia.",n,#PortoAreas.beachKinds) end
  end
 end
 return e.hint
end
'''
CL_OLD_2 = 'addRow(e.id,e.name,e.id=="photos" and photoHint() or e.hint,nil,function()openDetail(id)end)'
CL_NEW_2 = 'addRow(e.id,e.name,hintFor(e),nil,function()openDetail(id)end)'
CL_OLD_3 = 'or name=="Item_porto" or name:find("^Item_photo")~=nil) and not pending then'
CL_NEW_3 = 'or name=="Item_porto" or name=="FoundIds" or name:find("^Item_photo")~=nil or name:find("^Item_seaglass")~=nil or name:find("^Item_shell")~=nil) and not pending then'

# ---------------- PolpoServer: its own stamp ----------------
POLPO_OLD = 'passport:Fire(player, "rescue", {})'
POLPO_NEW = 'passport:Fire(player, "porto_polpo", {})'

areas = read("PortoAreas.lua")
activities = read("PortoActivities.lua")
recipes = read("SeaGlassRecipes.lua")
server = read("SeaGlassServer.lua")
client = read("SeaGlassClient.lua")

lua = r'''-- porto/install_italy: EDIT mode. Installs the Italy page of the Passport and Bella's beach game (Oct 9 2026, Shannon:
-- "please can you check how we did that system with the French map and duplicate it for the Italy map" + the sea glass /
-- shell game with Bella on the beach). Everything is exact-string patching with guards, or new instances. Nothing runs
-- unless every find hits exactly once and every patched Source compiles; originals -> ServerStorage.HudBackup.*_pre_italy.
-- Output lines start with "QQ ITA". Re-running is refused by the guards (already patched) except for the new instances,
-- which are left alone if present.
if game:GetService("RunService"):IsRunning() then warn("QQ ITA ABORT - Play mode") return end
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local P = workspace:FindFirstChild("Passport")
local Grotta = workspace:FindFirstChild("Grotta")
local Cat, Jr, Vis, Cl = P and P:FindFirstChild("Catalogue"), P and P:FindFirstChild("Journal"), P and P:FindFirstChild("PassportVisuals"), P and P:FindFirstChild("PassportClient")
local Polpo = Grotta and Grotta:FindFirstChild("PolpoServer")
for _, pair in ipairs({{Cat, "Catalogue"}, {Jr, "Journal"}, {Vis, "PassportVisuals"}, {Cl, "PassportClient"}, {Polpo, "Grotta.PolpoServer"}}) do
	if not (pair[1] and pair[1]:IsA("LuaSourceContainer")) then warn("QQ ITA ABORT - missing " .. pair[2]) return end
end
local LEN = {[Cat] = 7793, [Jr] = 12486, [Vis] = 3783, [Cl] = 27056}
for s, n in pairs(LEN) do
	if #s.Source ~= n then warn(string.format("QQ ITA ABORT - %s.Source is %d chars, expected %d (already patched, or changed since Oct 9)", s.Name, #s.Source, n)) return end
end

local PATCHES = {
	{Cat, "Catalogue", {{@@CAT_OLD@@, @@CAT_NEW@@}}},
	{Jr, "Journal", {{@@JOURNAL_OLD@@, @@JOURNAL_NEW@@}}},
	{Vis, "PassportVisuals", {{@@VIS_OLD@@, @@VIS_NEW@@}}},
	{Cl, "PassportClient", {{@@CL_OLD_1@@, @@CL_NEW_1@@}, {@@CL_OLD_2@@, @@CL_NEW_2@@}, {@@CL_OLD_3@@, @@CL_NEW_3@@}}},
	{Polpo, "PolpoServer", {{@@POLPO_OLD@@, @@POLPO_NEW@@}}},
}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, pairs_ = pt[1], pt[2], pt[3]
	local src = s.Source
	for i, p in ipairs(pairs_) do
		local a, b = src:find(p[1], 1, true)
		if not a then warn("QQ ITA ABORT - " .. name .. " find " .. i .. " not found; nothing changed") return end
		if src:find(p[1], b + 1, true) then warn("QQ ITA ABORT - " .. name .. " find " .. i .. " matches more than once; nothing changed") return end
	end
	local o = src
	for _, p in ipairs(pairs_) do
		local a, b = o:find(p[1], 1, true)
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ ITA ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end

local NEW = {
	PortoAreas = @@AREAS@@,
	PortoActivities = @@ACTIVITIES@@,
	Recipes = @@RECIPES@@,
	SeaGlassServer = @@SERVER@@,
	SeaGlassClient = @@CLIENT@@,
}
for name, src in pairs(NEW) do
	local f, err = loadstring(src)
	if not f then warn("QQ ITA ABORT - new script " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
end

-- backups, then the patches
local hb = SS:FindFirstChild("HudBackup")
if not hb then hb = Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS end
for _, pt in ipairs(PATCHES) do
	local s = pt[1]
	local bname = pt[2]:gsub("%.", "_") .. "_pre_italy"
	if not hb:FindFirstChild(bname) then
		local bk = s:Clone(); bk.Name = bname
		pcall(function() bk.Enabled = false end)
		bk.Parent = hb
	end
end
for s, o in pairs(out) do s.Source = o end

-- the new pieces
local function module(parent, name, src)
	local m = parent:FindFirstChild(name)
	if m and m:IsA("ModuleScript") then m.Source = src return m end
	m = Instance.new("ModuleScript"); m.Name = name; m.Source = src; m.Parent = parent
	return m
end
module(RS, "PortoAreas", NEW.PortoAreas)

local PP = workspace:FindFirstChild("PortoPassport")
if not PP then PP = Instance.new("Folder"); PP.Name = "PortoPassport"; PP.Parent = workspace end
if PP:GetAttribute("OperaSoundId") == nil then PP:SetAttribute("OperaSoundId", "9042832054") end
if PP:GetAttribute("OperaVolume") == nil then PP:SetAttribute("OperaVolume", 0.8) end
if PP:GetAttribute("RideHeight") == nil then PP:SetAttribute("RideHeight", 20) end
local act = PP:FindFirstChild("PortoActivities")
if not act then act = Instance.new("Script"); act.Name = "PortoActivities"; act.Parent = PP end
act.RunContext = Enum.RunContext.Server
act.Source = NEW.PortoActivities

local SG = workspace:FindFirstChild("SeaGlass")
if not SG then SG = Instance.new("Folder"); SG.Name = "SeaGlass"; SG.Parent = workspace end
if SG:GetAttribute("Count") == nil then SG:SetAttribute("Count", 8) end
if SG:GetAttribute("RespawnMin") == nil then SG:SetAttribute("RespawnMin", 45) end
if SG:GetAttribute("RespawnMax") == nil then SG:SetAttribute("RespawnMax", 90) end
if SG:GetAttribute("BoxMin") == nil then SG:SetAttribute("BoxMin", Vector3.new(388, -60, -1095)) end
if SG:GetAttribute("BoxMax") == nil then SG:SetAttribute("BoxMax", Vector3.new(445, -40, -1046)) end
if not SG:FindFirstChild("Pieces") then local f = Instance.new("Folder"); f.Name = "Pieces"; f.Parent = SG end
if not SG:FindFirstChild("SeaGlassEvent") then local e = Instance.new("RemoteEvent"); e.Name = "SeaGlassEvent"; e.Parent = SG end
module(SG, "Recipes", NEW.Recipes)
local sv = SG:FindFirstChild("SeaGlassServer")
if not sv then sv = Instance.new("Script"); sv.Name = "SeaGlassServer"; sv.Parent = SG end
sv.RunContext = Enum.RunContext.Server; sv.Source = NEW.SeaGlassServer
local cl = SG:FindFirstChild("SeaGlassClient")
if not cl then cl = Instance.new("Script"); cl.Name = "SeaGlassClient"; cl.Parent = SG end
cl.RunContext = Enum.RunContext.Client; cl.Source = NEW.SeaGlassClient

print(string.format("QQ ITA DONE: Catalogue %d, Journal %d, PassportVisuals %d, PassportClient %d chars; PolpoServer stamps porto_polpo; RS.PortoAreas, workspace.PortoPassport.PortoActivities, workspace.SeaGlass {SeaGlassServer, SeaGlassClient, Recipes, SeaGlassEvent, Pieces}; backups ServerStorage.HudBackup.*_pre_italy",
	#out[Cat], #out[Jr], #out[Vis], #out[Cl]))
'''

subs = {
    "CAT_OLD": L(CAT_OLD), "CAT_NEW": L(CAT_NEW),
    "JOURNAL_OLD": L(JOURNAL_OLD), "JOURNAL_NEW": L(JOURNAL_NEW),
    "VIS_OLD": L(VIS_OLD), "VIS_NEW": L(VIS_NEW),
    "CL_OLD_1": L(CL_OLD_1), "CL_NEW_1": L(CL_NEW_1),
    "CL_OLD_2": L(CL_OLD_2), "CL_NEW_2": L(CL_NEW_2),
    "CL_OLD_3": L(CL_OLD_3), "CL_NEW_3": L(CL_NEW_3),
    "POLPO_OLD": L(POLPO_OLD), "POLPO_NEW": L(POLPO_NEW),
    "AREAS": L(areas, "===="), "ACTIVITIES": L(activities, "===="), "RECIPES": L(recipes, "===="),
    "SERVER": L(server, "===="), "CLIENT": L(client, "===="),
}
text = lua
for k, v in subs.items():
    assert text.count("@@" + k + "@@") == 1, k
    text = text.replace("@@" + k + "@@", v)
assert "@@" not in text
(ROOT / "tools/porto/install_italy.lua").write_text(text, encoding="utf-8")
print(f"wrote tools/porto/install_italy.lua ({len(text)} chars)")

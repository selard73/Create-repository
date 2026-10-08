"""patch_travel.py (Oct 1 2026): the cities round for the Passport.
Four new outings (boat, falls, chute, porto - offered once all 44 squirrels are found), their stamp texts, their artwork,
and per-city sub-tabs (French Squirrel Country | Porto Nocciola) under Outings / Completed / Clues once Porto is opened
(Item_porto >= 1); the Italian Clues tab says coming soon. The SAME text replacements are applied to passport/src/*.lua and
to the copies embedded in build_passport.lua, and written out as install_passport_travel.lua, which applies them to the
LIVE scripts in workspace.Passport (asserting every anchor) and adds the four artwork previews to ReplicatedStorage.PassportArt.
Run: python patch_travel.py   (from passport/)"""
from pathlib import Path
import re

D = Path(__file__).parent
MARK = "-- travel-passport v1 (Oct 1 2026)"

CATALOGUE_NEW = r''' {id="boat",name="Down the river",area="village",icon="boat",needAll=true,hint="Take the motorboat out from the jetty on the Rue.",detail="Once you have found all 44 squirrels, hold the prompt at the jetty on the Rue to take the boat out. Steer down the river and see where it goes. The Sky Diving Squirrel in the forest has something you will want before you leave."},
 {id="falls",name="Over the edge",area="village",icon="falls",needAll=true,hint="Ride the river all the way to the waterfall.",detail="The river leaves French Squirrel Country through a gorge and ends in a great waterfall. Keep going past the brink and over you go, boat and all. Wet or dry, you arrive at Porto Nocciola."},
 {id="chute",name="Rainbow landing",area="porto",icon="chute",needAll=true,hint="Float down to Porto Nocciola under the Sky Diving Squirrel's parachute.",detail="After you have found all 44 squirrels, talk to the Sky Diving Squirrel in the forest and he lends you his spare parachute. Wear it over the falls and steer your way down to the shore."},
 {id="porto",name="Benvenuti a Porto Nocciola",area="porto",icon="porto",needAll=true,hint="Arrive at Porto Nocciola, your first stop in Italy.",detail="Porto Nocciola lies at the foot of the falls. Once you have landed there, the luggage cart by the Hall of Fame at the château takes you back any time, and the cart on the Porto shore brings you home to French Squirrel Country."},
'''

# (module, [ (old, new, replace_all) ... ])
PATCH = {
 "Catalogue": [
  (' {id="keeper",name="Keeper of the Great Acorn"', CATALOGUE_NEW + ' {id="keeper",name="Keeper of the Great Acorn"', False),
 ],
 "Journal": [
  ('rank=true,scope=true,boardReady=true,run=true,keeperNo=true,historical=true,ongoing=true,visited=true,',
   'rank=true,scope=true,boardReady=true,run=true,keeperNo=true,historical=true,ongoing=true,visited=true,chute=true,', False),
  (' elseif id=="keeper" then return "First to complete all 44',
   ''' elseif id=="boat" then return "Took the motorboat out from the jetty on the Rue and set off down the river."
 elseif id=="falls" then return "Went over the great waterfall at the end of the river, boat and all"..(d.chute and ", with the parachute on." or ", and landed in the pool with a splash!")
 elseif id=="chute" then return "Floated down to Porto Nocciola under the Sky Diving Squirrel's rainbow parachute."
 elseif id=="porto" then return "Arrived at Porto Nocciola, your first stop in Italy. Benvenuti!"
 elseif id=="keeper" then return "First to complete all 44''', False),
 ],
 "PassportServer": [
  (' if e.bonus then return false end',
   ' if e.bonus then return false end\n if e.needAll and ((p:GetAttribute("Found_forest") or 0)+(p:GetAttribute("Found_village") or 0)+(p:GetAttribute("Found_domaine") or 0))<44 then return false end', False),
  ('if name=="Found_forest" or name=="Found_village" then task.defer(fillEmpty,p)end',
   'if name=="Found_forest" or name=="Found_village" or name=="Found_domaine" then task.defer(fillEmpty,p)end', False),
 ],
 "PassportVisuals": [
  ('glider="glider",gold="fairy_squirrel",keeper="tourist_squirrel"}',
   'glider="glider",gold="fairy_squirrel",keeper="tourist_squirrel",boat="boat",falls="falls",chute="chute",porto="porto"}', False),
 ],
 "PassportClient": [
  # the count of normal outings replaces the hard-coded 21 (first, so later anchors are stable)
  ('total>=21', 'total>=NORMAL', True),
  ('"21 adventures completed"', '(NORMAL.." adventures completed")', True),
  ('local catalogue=require(F:WaitForChild("Catalogue"));local J=require(F:WaitForChild("Journal"))',
   'local catalogue=require(F:WaitForChild("Catalogue"));local J=require(F:WaitForChild("Journal"))\nlocal NORMAL=0;for _,e in ipairs(catalogue)do if not e.bonus then NORMAL+=1 end end', False),
  # the city sub-tabs
  ('for _,name in ipairs({"Outings","Completed","Clues","Wardrobe"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end',
   '''for _,name in ipairs({"Outings","Completed","Clues","Wardrobe"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end
-- per-city pages once a second city is opened: French Squirrel Country | Porto Nocciola (Item_porto, awarded on the first landing)
local CITIES={{id="france",name="French Squirrel Country"},{id="italy",name="Porto Nocciola"}};local city="france";local cityTabs={}
for _,c in ipairs(CITIES)do cityTabs[c.id]=button(panel,"City_"..c.id,c.name,0,90,95,26);cityTabs[c.id].TextSize=12;cityTabs[c.id].Visible=false end
local function hasCities()return (tonumber(p:GetAttribute("Item_porto")) or 0)>=1 end
local function cityOf(id)local e=J.byId[id];return (e and e.area=="porto") and "italy" or "france" end
local function showCities()return hasCities() and not detail and selected~="Wardrobe" end''', False),
  (' for name,b in pairs(tabs)do b.BackgroundColor3=name==selected and C(245,170,60) or C(236,226,206);b.TextColor3=INK;b.Visible=not detail and (name~="Wardrobe" or hasWardrobe()) end',
   ''' for name,b in pairs(tabs)do b.BackgroundColor3=name==selected and C(245,170,60) or C(236,226,206);b.TextColor3=INK;b.Visible=not detail and (name~="Wardrobe" or hasWardrobe()) end
 for id,b in pairs(cityTabs)do b.Visible=showCities();b.BackgroundColor3=id==city and C(245,170,60) or C(236,226,206);b.TextColor3=INK end''', False),
  # Outings: only this city's outings
  ('  local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)',
   '''  local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)
  if showCities() then local fi,fd={},{} for _,id in ipairs(ids)do if cityOf(id)==city then fi[#fi+1]=id end end for _,id in ipairs(done)do if cityOf(id)==city then fd[#fd+1]=id end end ids,done=fi,fd end''', False),
  ('  if #ids==0 then\n   summary.Text=',
   '''  if #ids==0 and showCities() and city=="italy" then
   summary.Text="Porto Nocciola";addRow("porto","Porto Nocciola is new","Your Italian outings are the boat trip, the falls, the parachute landing and the arrival itself. More arrive as the harbour grows.",nil,nil,true,"More to come")
  elseif #ids==0 then
   summary.Text=''', False),
  ('  if J.batchDone(batch)then', '  if J.batchDone(batch) and not (showCities() and city=="italy" and #ids==0) then', False),
  # Completed: only this city's stamps
  ('  if total==0 then addRow("find","No outings completed yet","Pick an outing and complete it to earn a passport stamp.")end\n  local entries={};for _,e in ipairs(catalogue)do if journal[e.id]then entries[#entries+1]=e end end',
   '''  local entries={};for _,e in ipairs(catalogue)do if journal[e.id] and (not showCities() or cityOf(e.id)==city) then entries[#entries+1]=e end end
  if showCities() then summary.Text=string.format("%d %s completed in %s",#entries,#entries==1 and "adventure" or "adventures",city=="italy" and "Porto Nocciola" or "French Squirrel Country") end
  if #entries==0 then addRow((showCities() and city=="italy") and "porto" or "find","No outings completed yet","Pick an outing and complete it to earn a passport stamp.")end''', False),
  # Clues: Italy says coming soon
  ('  summary.Text="Daily finds & bonus challenges"',
   '''  if showCities() and city=="italy" then
   summary.Text="Porto Nocciola · coming soon"
   addRow("porto","Italian clues: coming soon","Italian squirrels and a daily Italian question are on their way to Porto Nocciola. Check back once the harbour opens.",nil,nil,true,"Coming soon")
  else
  summary.Text="Daily finds & bonus challenges"''', False),
  ('nil,nil,true)\n end\n arrangeRows(rows)', 'nil,nil,true)\n  end\n end\n arrangeRows(rows)', False),
  # layout: the sub-tab row sits under the tabs; the list starts lower while it shows
  (' local top=detail and 60 or 93', ' local sub=showCities()\n local top=detail and 60 or (sub and 124 or 93)', False),
  (' for i,name in ipairs(names)do tabs[name].Position=UDim2.fromOffset(14+(i-1)*(tw+4),56);tabs[name].Size=UDim2.fromOffset(tw,30)end',
   ''' for i,name in ipairs(names)do tabs[name].Position=UDim2.fromOffset(14+(i-1)*(tw+4),56);tabs[name].Size=UDim2.fromOffset(tw,30)end
 local cw=(width-28-4)/2
 for i,c in ipairs(CITIES)do cityTabs[c.id].Position=UDim2.fromOffset(14+(i-1)*(cw+4),90);cityTabs[c.id].Size=UDim2.fromOffset(cw,26);cityTabs[c.id].Visible=sub end''', False),
  ('for name,b in pairs(tabs) do b.Activated:Connect(function()selected=name;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end',
   '''for name,b in pairs(tabs) do b.Activated:Connect(function()selected=name;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end
for id,b in pairs(cityTabs) do b.Activated:Connect(function()city=id;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end''', False),
  ('if panel.Visible and (name=="PassportJournal" or name=="PassportReady" or name=="Item_passport_outings") and not pending then pending=true;task.defer(function()pending=false;render()end)end',
   'if panel.Visible and (name=="PassportJournal" or name=="PassportReady" or name=="Item_passport_outings" or name=="Item_porto") and not pending then pending=true;task.defer(function()pending=false;fit();render()end)end', False),
 ],
}


def apply(src, pairs, label):
    for k, (old, new, all_) in enumerate(pairs):
        n = src.count(old)
        if all_:
            assert n >= 1, f"{label}: pair {k} not found"
        else:
            assert n == 1, f"{label}: pair {k} found {n} times (want 1): {old[:60]!r}"
        src = src.replace(old, new)
    return src


def main():
    # 1. the local module sources
    for name, pairs in PATCH.items():
        p = D / "src" / f"{name}.lua"
        src = p.read_text(encoding="utf-8")
        if MARK in src:
            print(name, "already patched locally"); continue
        src = apply(src, pairs, f"src/{name}") + ("\n" if not src.endswith("\n") else "") + MARK + "\n"
        p.write_text(src, encoding="utf-8"); print("patched src/", name)
    # 2. the copies embedded in the builder
    bp = D / "build_passport.lua"
    b = bp.read_text(encoding="utf-8")
    if MARK not in b:
        for name, pairs in PATCH.items():
            b = apply(b, pairs, f"build_passport/{name}")
        b = b.replace("sources.Catalogue=[====[", "-- " + MARK + " applied to the sources below (patch_travel.py)\nsources.Catalogue=[====[", 1)
        bp.write_text(b, encoding="utf-8"); print("patched build_passport.lua")
    else:
        print("build_passport.lua already patched")
    # 3. the Studio installer (PatchModule-ready chunk)
    def lua_str(s):
        assert "]==]" not in s
        return "[==[" + s + "]==]"
    out = ["-- install_passport_travel v1 (" + MARK + "): the cities round for the Passport, applied to the LIVE scripts in",
           "-- workspace.Passport (every anchor asserted, each script assigned once) + four artwork previews in ReplicatedStorage.PassportArt.",
           "-- Generated by passport/patch_travel.py - edit the pairs there, not here. Edit mode. Safe to re-run (marker).",
           'local RS = game:GetService("ReplicatedStorage"); local CS = game:GetService("CollectionService")',
           'local F = workspace:WaitForChild("Passport")',
           'local MARK = ' + lua_str(MARK),
           'local function count(src, old) local n, i = 0, 1 while true do local a, b = src:find(old, i, true) if not a then break end n += 1; i = b + 1 end return n end',
           'local function replace(src, old, new, all) local out, i = {}, 1 while true do local a, b = src:find(old, i, true) if not a then break end out[#out + 1] = src:sub(i, a - 1); out[#out + 1] = new; i = b + 1; if not all then break end end out[#out + 1] = src:sub(i) return table.concat(out) end',
           'local PATCH = {']
    for name, pairs in PATCH.items():
        out.append('\t{name = "%s", pairs = {' % name)
        for old, new, all_ in pairs:
            out.append('\t\t{old = %s, new = %s, all = %s},' % (lua_str(old), lua_str(new), "true" if all_ else "false"))
        out.append('\t}},')
    out.append('}')
    out.append('''for _, mod in ipairs(PATCH) do
	local s = F:FindFirstChild(mod.name); assert(s, "Passport." .. mod.name .. " missing")
	local src = s.Source
	if src:find(MARK, 1, true) then
		print("QQ PP " .. mod.name .. " already patched")
	else
		for k, pr in ipairs(mod.pairs) do
			local n = count(src, pr.old)
			assert(n >= 1, string.format("QQ PP %s: pair %d not found in the live source", mod.name, k))
			assert(pr.all or n == 1, string.format("QQ PP %s: pair %d found %d times", mod.name, k, n))
			src = replace(src, pr.old, pr.new, pr.all)
		end
		s.Source = src .. (src:sub(-1) == "\\n" and "" or "\\n") .. MARK .. "\\n"
		print("QQ PP " .. mod.name .. " patched (" .. #mod.pairs .. " changes)")
	end
end
-- the artwork: inert copies of the game's own things, like install_art.lua makes them
local art = RS:FindFirstChild("PassportArt"); assert(art, "ReplicatedStorage.PassportArt missing")
local function preview(id, source, viewDir)
	assert(source, "no artwork source for " .. id)
	local old = art:FindFirstChild(id); if old then old:Destroy() end
	local model = Instance.new("Model"); model.Name = id
	local copy = source:Clone(); copy.Parent = model
	for _, d in ipairs(model:GetDescendants()) do
		for _, tag in ipairs(CS:GetTags(d)) do CS:RemoveTag(d, tag) end
		if d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("Constraint") or d:IsA("JointInstance") or d:IsA("LayerCollector") or d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("Highlight") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
	end
	if viewDir then model:SetAttribute("ViewDirection", viewDir) end
	model.Parent = art
end
if not art:FindFirstChild("boat") then preview("boat", workspace.River.BoatPreview:FindFirstChildWhichIsA("MeshPart", true), Vector3.new(0.8, 0.45, 1)) end
-- the rainbow canopy: wherever the kit keeps it (by name, then by its mesh id), else the Sky Diving Squirrel himself
local canopy = nil
for _, root in ipairs({RS, game:GetService("ServerStorage"), workspace}) do
	if not canopy then
		local kit = root:FindFirstChild("ChuteKit", true)
		canopy = kit and (kit:FindFirstChild("ChuteCanopy", true) or kit:FindFirstChildWhichIsA("MeshPart", true))
	end
	if not canopy then
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("MeshPart") and tostring(d.MeshId):find("111732351991483", 1, true) then canopy = d break end
		end
	end
end
if not canopy then local sq = workspace:FindFirstChild("parachute_squirrel_color"); canopy = sq and sq:FindFirstChildWhichIsA("MeshPart", true); print("QQ PP chute art: canopy not found, using the Sky Diving Squirrel") end
preview("chute", canopy, Vector3.new(0.6, 0.25, 1))
preview("porto", workspace.Travel.Points.TravelCart_porto, Vector3.new(-1, 0.45, -0.55))
do -- the falls: a cliff block, the river on top, the sheet, the foam and the pool
	local f = Instance.new("Model"); f.Name = "FallsArtSource"
	local function fp(name, size, pos, col, tr) local q = Instance.new("Part"); q.Name = name; q.Size = size; q.Position = pos; q.Color = col; q.Material = Enum.Material.SmoothPlastic; q.Anchored = true; q.Transparency = tr or 0; q.Parent = f end
	fp("Cliff", Vector3.new(3, 4, 2), Vector3.new(0, 2, 0), Color3.fromRGB(226, 206, 160))
	fp("CliffTop", Vector3.new(3.2, 0.4, 2.2), Vector3.new(0, 4.1, 0), Color3.fromRGB(150, 176, 112))
	fp("River", Vector3.new(1.6, 0.25, 1.4), Vector3.new(0, 4.35, 0.2), Color3.fromRGB(150, 186, 206))
	fp("Sheet", Vector3.new(1.5, 4.2, 0.35), Vector3.new(0, 2.2, 1.15), Color3.fromRGB(214, 236, 242), 0.1)
	fp("Foam", Vector3.new(2.6, 0.6, 1.6), Vector3.new(0, 0.3, 1.5), Color3.fromRGB(240, 248, 250))
	fp("Pool", Vector3.new(3.6, 0.3, 2.6), Vector3.new(0, 0.05, 1.6), Color3.fromRGB(120, 170, 200))
	preview("falls", f, Vector3.new(0.5, 0.35, 1)); f:Destroy()
end
print("QQ PP ART boat/falls/chute/porto in PassportArt (" .. #art:GetChildren() .. " previews)")
print("QQ PP DONE")''')
    (D / "install_passport_travel.lua").write_text("\n".join(out) + "\n", encoding="utf-8")
    print("wrote install_passport_travel.lua")


if __name__ == "__main__":
    main()

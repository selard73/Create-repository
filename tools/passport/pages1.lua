-- passport/pages1 (job 25): EDIT mode. Five outings at a time PER MAP: _batch = French Squirrel Country, _batch_porto =
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
local PATCHES = {{Jr, "Journal", {{[===[
J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end
]===], [===[
J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end
function J.cityOf(id) local e=J.byId[id];return (e and e.area=="porto") and "italy" or "france" end -- pages are per map (Oct 9 2026)
]===]}, {[===[
 if not J.byId[id] and id~="_batch" then return nil end]===], [===[
 if not J.byId[id] and id~="_batch" and id~="_batch_porto" then return nil end]===]}, {[===[
function J.nextBatch(prior,eligible,memories)
]===], [===[
function J.nextBatch(prior,eligible,memories,city)
]===]}, {[===[
  for _,e in ipairs(catalogue) do if eligible(e) and not seen[e.id] and not (memories and memories[e.id]) and #ids<5 then ids[#ids+1]=e.id end end]===], [===[
  for _,e in ipairs(catalogue) do if J.cityOf(e.id)==(city or "france") and eligible(e) and not seen[e.id] and not (memories and memories[e.id]) and #ids<5 then ids[#ids+1]=e.id end end]===]}, {[===[
function J.reconcileBatch(prior,eligible,memories)
 if not prior then return J.nextBatch(nil,eligible,memories)end]===], [===[
function J.reconcileBatch(prior,eligible,memories,city)
 if not prior then return J.nextBatch(nil,eligible,memories,city)end]===]}, {[===[
  if (record and record.data.historical) or (not record and not oldDone[id] and not eligible(J.byId[id]))then]===], [===[
  if (record and record.data.historical) or J.cityOf(id)~=(city or "france") or (not record and not oldDone[id] and not eligible(J.byId[id]))then]===]}, {[===[
   if #ids<5 and eligible(e) and not used[e.id] and not memories[e.id] and not oldDone[e.id] then]===], [===[
   if #ids<5 and J.cityOf(e.id)==(city or "france") and eligible(e) and not used[e.id] and not memories[e.id] and not oldDone[e.id] then]===]}}}, {Sv, "PassportServer", {{[===[
 if e.bonus then return false end
]===], [===[
 if e.bonus then return false end
 if e.area=="porto" and item(p,"porto")<1 then return false end -- the Porto page opens on arrival in the harbour
]===]}, {[===[
local function repairPage(p)
 local s=states[p];if not s then return end
 local old=s.journal._batch
 local b=J.reconcileBatch(old and old.data,function(e)return eligible(p,e)end,s.journal)
 if not old or old.data.ids~=b.ids or old.data.done~=b.done or old.data.seen~=b.seen then write(p,"_batch",b)end
end
]===], [===[
-- One page of five per map (Oct 9 2026): _batch is French Squirrel Country, _batch_porto is Porto Nocciola.
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
]===]}, {[===[
local function advance(p)
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
]===], [===[
local function advance(p,city)
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
]===]}, {[===[
 local batch=s.journal._batch
 if batch then
]===], [===[
 local pageKey=J.cityOf(id)=="italy" and "_batch_porto" or "_batch"
 local batch=s.journal[pageKey]
 if batch then
]===]}, {[===[
  if changed then write(p,"_batch",b) end
]===], [===[
  if changed then write(p,pageKey,b) end
]===]}, {[===[
 p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" or name=="Found_domaine" then task.defer(fillEmpty,p)end end)]===], [===[
 p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" or name=="Found_domaine" or name=="Item_porto" then task.defer(function()repairPage(p);fillEmpty(p)end)end end)]===]}, {[===[
action.OnServerInvoke=function(p,what)
]===], [===[
action.OnServerInvoke=function(p,what,city)
]===]}, {[===[
 return advance(p)
end]===], [===[
 return advance(p,city)
end]===]}}}, {Cl, "PassportClient", {{[===[

  if showCities() and city=="italy" then ids,done={},{} for _,e in ipairs(catalogue)do if e.area=="porto" then ids[#ids+1]=e.id;if journal[e.id]then done[#done+1]=e.id end end end end]===], [===[
]===]}, {[===[
local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)]===], [===[
local pageKey=(showCities() and city=="italy") and "_batch_porto" or "_batch";local batch=journal[pageKey] and journal[pageKey].data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)]===]}, {[===[
if J.batchDone(batch) and not (showCities() and city=="italy") then]===], [===[
if J.batchDone(batch) then]===]}, {[===[
return F.PassportAction:InvokeServer("more")]===], [===[
return F.PassportAction:InvokeServer("more",(showCities() and city=="italy") and "italy" or "france")]===]}, {[===[
addRow("porto","Porto Nocciola is new","Your Italian outings are the boat trip, the falls, the parachute landing and the arrival itself. More arrive as the harbour grows.",nil,nil,true,"More to come")]===], [===[
addRow("porto","Porto Nocciola","Your Italian outings appear here five at a time once you have arrived in the harbour. Finish them and the next five follow.",nil,nil,true,"More to come")]===]}}}}
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

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local H=game:GetService("HttpService")
local F=script.Parent
local catalogue=require(F.Catalogue)
local J=require(F.Journal)
local Rules=require(F.Rules)
local registry=require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local hatTitles={}
local hatKit=RS:FindFirstChild("HatKit")
if hatKit and hatKit:FindFirstChild("Catalogue") then
 local hats=require(hatKit.Catalogue)
 for id in pairs(hats.byId)do hatTitles[id]=hats.title(id)end
end
local award=RS:WaitForChild("AwardItems")
local activity=RS:WaitForChild("PassportActivity")
local save=RS:WaitForChild("PassportSave") -- server-only records; SquirrelSetup owns the single save key
local action=F:WaitForChild("PassportAction")
local states,queued,lastRequest={},{},{}
local allowed={};for _,e in ipairs(catalogue) do allowed[e.id]=true end
local function item(p,id) return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function today()
 local daily=workspace:FindFirstChild("Daily")
 return math.floor((os.time()-(daily and daily:GetAttribute("DayOffsetHours") or 9)*3600)/86400)
end
local function decode(s)
 local ok,v=pcall(function() return H:JSONDecode(s or "{}") end)
 return ok and type(v)=="table" and J.merge(v,{}) or {}
end
local function write(p,id,data,at)
 local state=states[p];if not state then return end
 local old=state.journal[id]
 local record=J.clean(id,{at=at or math.max(workspace:GetServerTimeNow(),old and old.at+0.0001 or 0),data=data})
 if not record then return end
 state.journal[id]=record
 p:SetAttribute("PassportJournal",H:JSONEncode(state.journal))
 save:Fire(p,id,record)
end
local function eligible(p,e)
 if e.bonus then return false end
 if e.needAll and ((p:GetAttribute("Found_forest") or 0)+(p:GetAttribute("Found_village") or 0)+(p:GetAttribute("Found_domaine") or 0))<44 then return false end
 local need=workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need") or 10
 if e.area=="village" and (p:GetAttribute("Found_forest") or 0)<need then return false end
 if e.area=="domaine" and (p:GetAttribute("Found_village") or 0)<need then return false end
 if e.multiplayer and #Players:GetPlayers()<(workspace.Baguette:GetAttribute("MinPlayers") or 2) then return false end
 if e.area=="gold" then
  local area=workspace.Daily:GetAttribute("GoldArea") or ""
  if area:find("Rue") and (p:GetAttribute("Found_forest") or 0)<need then return false end
  if (area:find("Château") or area:find("Chateau")) and (p:GetAttribute("Found_village") or 0)<need then return false end
 end
 return true
end
local function repairPage(p)
 local s=states[p];if not s then return end
 local old=s.journal._batch
 local b=J.reconcileBatch(old and old.data,function(e)return eligible(p,e)end,s.journal)
 if not old or old.data.ids~=b.ids or old.data.done~=b.done or old.data.seen~=b.seen then write(p,"_batch",b)end
end
local function restoreHistory(p)
 local s=states[p];if not s then return end
 for id,data in pairs(J.history(p:GetAttributes(),registry,hatTitles))do
  local old=s.journal[id]
  if not old then write(p,id,data,1)
  elseif old.data.historical then
   local merged=table.clone(old.data);local changed=false
   for key,value in pairs(data)do if merged[key]==nil then merged[key]=value;changed=true end end
   if changed then write(p,id,merged,old.at+.0001)end
  end
 end
end
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
local function mark(p,id,data)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players or not allowed[id] then return end
 local s=states[p]
 if not s then queued[p]=queued[p] or {};queued[p][id]=data or {};return end
 data=type(data)=="table" and table.clone(data) or {}
 data.visited=workspace:GetServerTimeNow()
 -- The stamp ledger stays compatible with the first Passport release.
 local changes=Rules.record(s,id,today(),allowed)
 if changes then for _,pair in ipairs(changes) do award:Fire(p,pair[1],pair[2]) end end
 write(p,id,data)
 local batch=s.journal._batch
 if batch then
  local b=table.clone(batch.data);local ids=J.ids(b.ids);local done=J.ids(b.done);local seen=J.ids(b.seen);local changed=false
  if table.find(ids,id) and not table.find(done,id) then done[#done+1]=id;b.done=table.concat(done,",");changed=true end
  if not table.find(seen,id) then seen[#seen+1]=id;b.seen=table.concat(seen,",");changed=true end
  if changed then write(p,"_batch",b) end
 end
end
activity.Event:Connect(mark)
-- These ledger awards are the actual successful action, not loading saved attributes.
award.Event:Connect(function(p,id,n)
 if type(n)~="number" or n<=0 then return end
 if id=="gassy" then mark(p,"cheese")
 elseif id=="q_round_forest" then mark(p,"riddle") end
end)
local function watchCharacter(p,char)
 for attribute,id in pairs({Riding="zipline",Gliding="glider"}) do
  char:GetAttributeChangedSignal(attribute):Connect(function() if char:GetAttribute(attribute)==true then mark(p,id) end end)
 end
end
local function watchBoard(p,id)
 p:GetAttributeChangedSignal("PassportBoard_"..id):Connect(function()
  local s=states[p];local old=s and s.journal[id]
  if not old or not old.data.cs then return end
  local ok,b=pcall(function() return H:JSONDecode(p:GetAttribute("PassportBoard_"..id)) end)
  if not ok or type(b)~="table" then return end
  local d=table.clone(old.data);d.rank=b.rank or 0;d.scope=b.scope;d.boardReady=true
  d.visited=d.visited or old.at
  write(p,id,d) -- result detail update, not another completed outing
 end)
end
local function rememberKeeper(p)
 local s=states[p]
 if s and (p:GetAttribute("ChampionNo") or 0)>0 and not s.journal.keeper then write(p,"keeper",{keeperNo=p:GetAttribute("ChampionNo")},1);s.stamps.keeper=1;award:Fire(p,"passport_keeper",1)end
end
local function watch(p)
 p:SetAttribute("PassportReady",false)
 p.CharacterAdded:Connect(function(char) watchCharacter(p,char) end)
 if p.Character then watchCharacter(p,p.Character) end
 watchBoard(p,"race");watchBoard(p,"climb")
 p:GetAttributeChangedSignal("ChampionNo"):Connect(function()rememberKeeper(p)end)
 p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" or name=="Found_domaine" then task.defer(fillEmpty,p)end end)
 task.spawn(function()
  while p.Parent==Players and not p:GetAttribute("SaveLoaded") do task.wait(0.1) end
  if p.Parent~=Players then return end
  task.wait()
  if p.Parent~=Players then return end
  local s={stamps={},last=item(p,"passport_outing_last"),outings=item(p,"passport_outings"),journal=decode(p:GetAttribute("PassportJournal"))}
  for id in pairs(allowed) do s.stamps[id]=item(p,"passport_"..id) end
  states[p]=s
  for id,day in pairs(s.stamps) do if day>0 and not s.journal[id] then write(p,id,{historical=true},1) end end
  -- Read only this player's fully loaded ledger. Backfills never award new
  -- acorns or count old adventures towards today's three-activity bonus.
  restoreHistory(p)
  -- A known Keeper's honour remains visible even if it predates the Passport.
  rememberKeeper(p)
  repairPage(p)
  fillEmpty(p)
  local waiting=queued[p];queued[p]=nil
  if waiting then for id,data in pairs(waiting) do mark(p,id,data) end end
  p:SetAttribute("PassportReady",true)
  for other in pairs(states)do fillEmpty(other)end
 end)
end
action.OnServerInvoke=function(p,what)
 if what~="more" then return false,"Unknown Passport action." end
 local now=os.clock();if now-(lastRequest[p] or -10)<1 then return false,"One page at a time." end;lastRequest[p]=now
 return advance(p)
end
Players.PlayerAdded:Connect(watch)
for _,p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) states[p]=nil;queued[p]=nil;lastRequest[p]=nil end)
print("Passport: per-player history restored; five unfinished outings; saved completion stamps")
-- travel-passport v1 (Oct 1 2026)

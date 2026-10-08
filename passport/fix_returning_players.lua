assert(not game:GetService("RunService"):IsRunning(),"EDIT only")
local changes={}
table.insert(changes,{target=workspace.Passport.Journal,before=[====[-- Pure, bounded data rules shared by the save owner, server and client.
local J={}
local catalogue=require(script.Parent.Catalogue)
J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end
local keys={name=true,area=true,title=true,character=true,colour=true,flavours=true,hat=true,action=true,
 cs=true,previousBest=true,improvement=true,prize=true,seconds=true,boost=true,streak=true,baskets=true,shots=true,
 rank=true,scope=true,boardReady=true,run=true,keeperNo=true,historical=true,ongoing=true,visited=true,
 ids=true,done=true,seen=true,cycle=true}
function J.clean(id,record)
 if not J.byId[id] and id~="_batch" then return nil end
 if type(record)~="table" or type(record.at)~="number" or record.at~=record.at or record.at<0 or record.at>1e12 or type(record.data)~="table" then return nil end
 local d={}
 for k,v in pairs(record.data) do
  if keys[k] then
   if type(v)=="string" then d[k]=v:sub(1,400)
   elseif type(v)=="boolean" then d[k]=v
   elseif type(v)=="number" and v==v and math.abs(v)<1e12 then d[k]=v end
  end
 end
 return {at=record.at,data=d}
end
function J.merge(a,b)
 local out={}
 for _,source in ipairs({a or {},b or {}}) do
  if type(source)=="table" then for id,record in pairs(source) do
   local v=J.clean(id,record)
   if v and (not out[id] or v.at>=out[id].at) then out[id]=v end
  end end
 end
 return out
end
function J.ids(csv)
 local list,seen={},{}
 for id in tostring(csv or ""):gmatch("[%w_]+") do if J.byId[id] and not seen[id] then list[#list+1]=id;seen[id]=true end end
 return list
end
function J.batchDone(data)
 local ids=J.ids(data and data.ids);local done={}
 for _,id in ipairs(J.ids(data and data.done)) do done[id]=true end
 if #ids==0 then return false end
 for _,id in ipairs(ids) do if not done[id] then return false end end
 return true
end
function J.nextBatch(prior,eligible,memories)
 local seen={};for _,id in ipairs(J.ids(prior and prior.seen)) do seen[id]=true end
 local cycle=prior and prior.cycle or 1
 -- Existing memories count as visited on the first pass; their stamp remains in Stamps.
 if not prior then for id in pairs(memories or {}) do if J.byId[id] then seen[id]=true end end end
 local function choose()
  local ids={}
  for _,e in ipairs(catalogue) do if eligible(e) and not seen[e.id] and not (memories and memories[e.id]) and #ids<5 then ids[#ids+1]=e.id end end
  return ids
 end
 local ids=choose()
 -- Completed outings stay in Completed. An empty page waits for new areas or activities.
 for _,id in ipairs(ids) do seen[id]=true end
 local all={};for _,e in ipairs(catalogue) do if seen[e.id] then all[#all+1]=e.id end end
 return {ids=table.concat(ids,","),done="",seen=table.concat(all,","),cycle=cycle}
end
function J.time(cs)
 local seconds=math.max(0,tonumber(cs) or 0)/100
 return string.format("%d:%05.2f",math.floor(seconds/60),seconds%60)
end
function J.describe(id,record,playerName)
 local d=record and record.data or {};local e=J.byId[id]
 if not e then return "" end
 if d.historical then return "A memory from your earlier adventures. Try it again to add the details to this page." end
 if id=="rescue" then return (playerName or "You").." saves the day! You freed Madame Margaux's babies from Croque Monsieur in the swamp."
 elseif id=="race" or id=="climb" then
  if not d.cs then return "Finished the "..(id=="race" and "forest race." or "Sandstone Climb and rang the summit bell.") end
  local s=(id=="race" and "Finished the forest race in " or "Raced up Sandstone and rang the bell in ")..J.time(d.cs)..". "
  if not d.previousBest or d.previousBest<=0 then s..="Your first recorded time!"
  elseif (d.improvement or 0)>0 then s..="A new personal best — "..J.time(d.improvement).." faster!"
  else s..="Your best remains "..J.time(d.previousBest).."." end
  if (d.rank or 0)>0 then s..=" Leaderboard: #"..tostring(d.rank)..(d.scope=="global" and " worldwide." or " in this server.")
  elseif d.boardReady then s..=d.scope=="unavailable" and " Leaderboard position unavailable." or " Outside the top 10 on this leaderboard."
  else s..=" Leaderboard position is being checked." end
  if (d.prize or 0)>0 then s..=" Earned "..d.prize.." acorns." end
  return s
 elseif id=="hoop" then
  if (d.baskets or 0)==0 then return "No baskets this round. Better luck next time — practice makes perfect! 0 acorns won." end
  return string.format("Scored %d %s this round, with %d in a row! Won %d acorns in basket rewards.",d.baskets,d.baskets==1 and "basket" or "baskets",math.min(3,d.streak or 0),d.prize or 0)
 elseif id=="gold" then return "Found "..(d.name or "the Golden Squirrel").." in "..(d.area or "French Squirrel Country").." and earned "..tostring(d.prize or 0).." acorns."
 elseif id=="find" then return "Found "..(d.name or "a new squirrel")..(d.area and " in "..d.area or "").."!"
 elseif id=="book" then return "Read about "..(d.character or "the wonderful squirrels of French Squirrel Country")..(d.title and " in “"..d.title.."”." or ".")
 elseif id=="coffee" then return string.format("Enjoyed a coffee and increased speed by %d%% for %s minutes. Maybe use that in the race?",d.boost or 35,tostring((d.seconds or 300)/60))
 elseif id=="cheese" then return "Enjoyed some French cheese — the gift that keeps on giving."
 elseif id=="bubbles" then return "Shared your sense of style on the Rue with "..(d.colour or "colourful").." bubbles."
 elseif id=="glace" then return "Enjoyed a "..(d.flavours or "delicious").." glace on the Rue, brain freeze and all."
 elseif id=="hat" then return (d.action=="wear" and "Wore your " or "Purchased a ")..(d.hat or "lovely hat")..(d.action=="wear" and "." or " at the hat shop.")
 elseif id=="portrait" then return "Added your portrait to the collection by the famous French Painter Squirrel."
 elseif id=="baguette" then
  local seconds=math.floor(d.seconds or 0);local t=seconds>=60 and string.format("%d min %d sec",math.floor(seconds/60),seconds%60) or tostring(seconds).." seconds"
  return "Played the baguette chase and held the baguette for "..t..". Earned "..tostring(d.prize or 0).." holding acorns."..(d.ongoing and " Still holding it!" or "")
 elseif id=="riddle" then return "Answered the daily forest question. Be sure to check tomorrow to see if you won the grand prize!"
 elseif id=="church" then return "Rang the church bell and let your hello ring out across French Squirrel Country."
 elseif id=="toadstool" then return "Bounced all the way through the Toadstool Run and earned "..tostring(d.prize or 10).." acorns!"
 elseif id=="windmill" then return "Rode a windmill sail and watched French Squirrel Country go round."
 elseif id=="chickens" then return "Fed the chickens at the farm. A very popular visitor!"
 elseif id=="zipline" then return "Rode the zipline across French Squirrel Country."
 elseif id=="glider" then return "Rode your hang glider down from the Sandstone summit."
 elseif id=="keeper" then return "First to complete all 44 squirrels that day! Your statue joined the Keeper of the Great Acorn Hall of Fame."..((d.keeperNo or 0)>0 and " Keeper #"..d.keeperNo.."." or "") end
 return e.hint
end
return J
]====],after=[====[-- Pure, bounded data rules shared by the save owner, server and client.
local J={}
local catalogue=require(script.Parent.Catalogue)
J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end
local keys={name=true,area=true,title=true,character=true,colour=true,flavours=true,hat=true,action=true,
 cs=true,previousBest=true,improvement=true,prize=true,seconds=true,boost=true,streak=true,baskets=true,shots=true,
 rank=true,scope=true,boardReady=true,run=true,keeperNo=true,historical=true,ongoing=true,visited=true,
 ids=true,done=true,seen=true,cycle=true,foundCount=true}
function J.clean(id,record)
 if not J.byId[id] and id~="_batch" then return nil end
 if type(record)~="table" or type(record.at)~="number" or record.at~=record.at or record.at<0 or record.at>1e12 or type(record.data)~="table" then return nil end
 local d={}
 for k,v in pairs(record.data) do
  if keys[k] then
   if type(v)=="string" then d[k]=v:sub(1,400)
   elseif type(v)=="boolean" then d[k]=v
   elseif type(v)=="number" and v==v and math.abs(v)<1e12 then d[k]=v end
  end
 end
 return {at=record.at,data=d}
end
function J.merge(a,b)
 local out={}
 for _,source in ipairs({a or {},b or {}}) do
  if type(source)=="table" then for id,record in pairs(source) do
   local v=J.clean(id,record)
   if v and (not out[id] or v.at>=out[id].at) then out[id]=v end
  end end
 end
 return out
end
function J.ids(csv)
 local list,seen={},{}
 for id in tostring(csv or ""):gmatch("[%w_]+") do if J.byId[id] and not seen[id] then list[#list+1]=id;seen[id]=true end end
 return list
end
function J.batchDone(data)
 local ids=J.ids(data and data.ids);local done={}
 for _,id in ipairs(J.ids(data and data.done)) do done[id]=true end
 if #ids==0 then return false end
 for _,id in ipairs(ids) do if not done[id] then return false end end
 return true
end
function J.nextBatch(prior,eligible,memories)
 local seen={};for _,id in ipairs(J.ids(prior and prior.seen)) do seen[id]=true end
 local cycle=prior and prior.cycle or 1
 -- Existing memories count as visited on the first pass; their stamp remains in Stamps.
 if not prior then for id in pairs(memories or {}) do if J.byId[id] then seen[id]=true end end end
 local function choose()
  local ids={}
  for _,e in ipairs(catalogue) do if eligible(e) and not seen[e.id] and not (memories and memories[e.id]) and #ids<5 then ids[#ids+1]=e.id end end
  return ids
 end
 local ids=choose()
 -- Completed outings stay in Completed. An empty page waits for new areas or activities.
 for _,id in ipairs(ids) do seen[id]=true end
 local all={};for _,e in ipairs(catalogue) do if seen[e.id] then all[#all+1]=e.id end end
 return {ids=table.concat(ids,","),done="",seen=table.concat(all,","),cycle=cycle}
end
-- Reconstruct only accomplishments evidenced by this player's existing save.
-- No rewards, DataStore calls, or fabricated visit dates are involved.
function J.history(attributes,registry,hatTitles)
 local result={}
 local function n(key)
  local v=tonumber(attributes[key]);return v and v==v and v>0 and v<1e12 and v or 0
 end
 local function add(id,d)d=d or {};d.historical=true;result[id]=d end
 local found={};for id in tostring(attributes.FoundIds or ""):gmatch("[^,]+")do found[id]=true end
 local count=0;for _ in pairs(found)do count+=1 end
 count=math.max(count,n("SquirrelsFound"),n("Found_forest")+n("Found_village")+n("Found_domaine"))
 if count>0 then
  local d={foundCount=count};local areas={}
  for _,m in ipairs(registry and registry.maps or {})do areas[m.id]=m.name end
  for _,e in ipairs(registry and registry.squirrels or {})do
   if found[e.id]then d.name=e.name;d.area=areas[e.map];break end
  end
  add("find",d)
 end
 if n("Item_q_round_forest")>0 then add("riddle")end
 if n("Item_croc_rescues")>0 then add("rescue")end
 for id,key in pairs({race="Item_race_best",climb="Item_climb_best"})do
  if n(key)>0 then add(id,{cs=n(key)})end
 end
 if n("Item_baskets")>0 then add("hoop",{baskets=n("Item_baskets")})end
 if n("Item_daily_gold")>0 then add("gold")end
 if n("Item_gassy")>0 then add("cheese")end
 if n("Item_bubbles")>0 then
  add("bubbles",{colour=({"pink","orange","gold","green","blue","violet"})[n("Item_fountaincolour")]})
 end
 -- Portrait purchases are persistent; the gallery also makes good any missed painting.
 if n("Item_portrait")>0 then add("portrait",{action="paid"})end
 local hats={};for id in pairs(hatTitles or {})do hats[#hats+1]=id end;table.sort(hats)
 for _,id in ipairs(hats)do if n("Item_hat_"..id)>0 then add("hat",{hat=hatTitles[id],action="buy"});break end end
 -- Owning a book, a zipline handle, or a glider does not prove it was used.
 return result
end

-- Repair already-issued pages after historical stamps are restored. Real new
-- completions keep their place in the five-outing count; pre-Passport entries
-- move straight to Completed and their slots offer unfinished activities.
function J.reconcileBatch(prior,eligible,memories)
 if not prior then return J.nextBatch(nil,eligible,memories)end
 local ids,done,used={},{},{}
 local oldDone={};for _,id in ipairs(J.ids(prior.done))do oldDone[id]=true end
 local seen={};for _,id in ipairs(J.ids(prior.seen))do seen[id]=true end
 local changed=false
 for _,id in ipairs(J.ids(prior.ids))do
  local record=memories[id]
  if (record and record.data.historical) or (not record and not oldDone[id] and not eligible(J.byId[id]))then
   changed=true;seen[id]=record~=nil
  else
   ids[#ids+1]=id;used[id]=true
   if record or oldDone[id]then done[#done+1]=id end
  end
 end
 if changed or #ids==0 then
  for _,e in ipairs(catalogue)do
   if #ids<5 and eligible(e) and not used[e.id] and not memories[e.id] and not oldDone[e.id] then
    ids[#ids+1]=e.id;used[e.id]=true;seen[e.id]=true
   end
  end
 end
 local all={};for _,e in ipairs(catalogue)do if seen[e.id] or memories[e.id]then all[#all+1]=e.id end end
 return {ids=table.concat(ids,","),done=table.concat(done,","),seen=table.concat(all,","),cycle=prior.cycle or 1}
end

function J.time(cs)
 local seconds=math.max(0,tonumber(cs) or 0)/100
 return string.format("%d:%05.2f",math.floor(seconds/60),seconds%60)
end
function J.describe(id,record,playerName)
 local d=record and record.data or {};local e=J.byId[id]
 if not e then return "" end
 if d.historical then
  if id=="find" then
   local count=d.foundCount or 0
   if count>0 then return string.format("Found %d %s on your adventures.",count,count==1 and "squirrel" or "squirrels")..(d.name and (" Your finds include "..d.name..(d.area and " in "..d.area or "")..".") or "")end
   return "Found a squirrel on an earlier adventure!"
  elseif id=="riddle" then return "Answered the daily forest question on an earlier visit. A new question awaits each day."
  elseif id=="race" or id=="climb" then
   return (id=="race" and "Completed the forest race." or "Completed the Sandstone Climb and rang the summit bell.")..(d.cs and " Your saved personal best: "..J.time(d.cs).."." or "")
  elseif id=="hoop" then
   return d.baskets and string.format("Scored %d %s across your earlier games!",d.baskets,d.baskets==1 and "basket" or "baskets") or "Played Nothing but Net on an earlier visit."
  elseif id=="gold" then return "Found the Golden Squirrel on an earlier adventure."
  elseif id=="portrait" and d.action=="paid" then return "Commissioned your portrait from the famous French Painter Squirrel."
  elseif id=="rescue" or id=="cheese" or id=="bubbles" or id=="hat" or id=="portrait" or id=="church" or id=="windmill" or id=="chickens" or id=="zipline" or id=="glider" or id=="keeper" then
   -- These completion descriptions do not invent a score, date or reward.
  else return "Completed this adventure on an earlier visit." end
 end
 if id=="rescue" then return (playerName or "You").." saves the day! You freed Madame Margaux's babies from Croque Monsieur in the swamp."
 elseif id=="race" or id=="climb" then
  if not d.cs then return "Finished the "..(id=="race" and "forest race." or "Sandstone Climb and rang the summit bell.") end
  local s=(id=="race" and "Finished the forest race in " or "Raced up Sandstone and rang the bell in ")..J.time(d.cs)..". "
  if not d.previousBest or d.previousBest<=0 then s..="Your first recorded time!"
  elseif (d.improvement or 0)>0 then s..="A new personal best — "..J.time(d.improvement).." faster!"
  else s..="Your best remains "..J.time(d.previousBest).."." end
  if (d.rank or 0)>0 then s..=" Leaderboard: #"..tostring(d.rank)..(d.scope=="global" and " worldwide." or " in this server.")
  elseif d.boardReady then s..=d.scope=="unavailable" and " Leaderboard position unavailable." or " Outside the top 10 on this leaderboard."
  else s..=" Leaderboard position is being checked." end
  if (d.prize or 0)>0 then s..=" Earned "..d.prize.." acorns." end
  return s
 elseif id=="hoop" then
  if (d.baskets or 0)==0 then return "No baskets this round. Better luck next time — practice makes perfect! 0 acorns won." end
  return string.format("Scored %d %s this round, with %d in a row! Won %d acorns in basket rewards.",d.baskets,d.baskets==1 and "basket" or "baskets",math.min(3,d.streak or 0),d.prize or 0)
 elseif id=="gold" then return "Found "..(d.name or "the Golden Squirrel").." in "..(d.area or "French Squirrel Country").." and earned "..tostring(d.prize or 0).." acorns."
 elseif id=="find" then return "Found "..(d.name or "a new squirrel")..(d.area and " in "..d.area or "").."!"
 elseif id=="book" then return "Read about "..(d.character or "the wonderful squirrels of French Squirrel Country")..(d.title and " in “"..d.title.."”." or ".")
 elseif id=="coffee" then return string.format("Enjoyed a coffee and increased speed by %d%% for %s minutes. Maybe use that in the race?",d.boost or 35,tostring((d.seconds or 300)/60))
 elseif id=="cheese" then return "Enjoyed some French cheese — the gift that keeps on giving."
 elseif id=="bubbles" then return "Shared your sense of style on the Rue with "..(d.colour or "colourful").." bubbles."
 elseif id=="glace" then return "Enjoyed a "..(d.flavours or "delicious").." glace on the Rue, brain freeze and all."
 elseif id=="hat" then return (d.action=="wear" and "Wore your " or "Purchased a ")..(d.hat or "lovely hat")..(d.action=="wear" and "." or " at the hat shop.")
 elseif id=="portrait" then return "Added your portrait to the collection by the famous French Painter Squirrel."
 elseif id=="baguette" then
  local seconds=math.floor(d.seconds or 0);local t=seconds>=60 and string.format("%d min %d sec",math.floor(seconds/60),seconds%60) or tostring(seconds).." seconds"
  return "Played the baguette chase and held the baguette for "..t..". Earned "..tostring(d.prize or 0).." holding acorns."..(d.ongoing and " Still holding it!" or "")
 elseif id=="riddle" then return "Answered the daily forest question. Be sure to check tomorrow to see if you won the grand prize!"
 elseif id=="church" then return "Rang the church bell and let your hello ring out across French Squirrel Country."
 elseif id=="toadstool" then return "Bounced all the way through the Toadstool Run and earned "..tostring(d.prize or 10).." acorns!"
 elseif id=="windmill" then return "Rode a windmill sail and watched French Squirrel Country go round."
 elseif id=="chickens" then return "Fed the chickens at the farm. A very popular visitor!"
 elseif id=="zipline" then return "Rode the zipline across French Squirrel Country."
 elseif id=="glider" then return "Rode your hang glider down from the Sandstone summit."
 elseif id=="keeper" then return "First to complete all 44 squirrels that day! Your statue joined the Keeper of the Great Acorn Hall of Fame."..((d.keeperNo or 0)>0 and " Keeper #"..d.keeperNo.."." or "") end
 return e.hint
end
return J
]====]})
table.insert(changes,{target=workspace.Passport.PassportServer,before=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local H=game:GetService("HttpService")
local F=script.Parent
local catalogue=require(F.Catalogue)
local J=require(F.Journal)
local Rules=require(F.Rules)
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
local function advance(p)
 local s=states[p];if not s then return false,"Your Passport is still loading." end
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
 p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" then task.defer(fillEmpty,p)end end)
 task.spawn(function()
  while p.Parent==Players and not p:GetAttribute("SaveLoaded") do task.wait(0.1) end
  if p.Parent~=Players then return end
  task.wait()
  if p.Parent~=Players then return end
  local s={stamps={},last=item(p,"passport_outing_last"),outings=item(p,"passport_outings"),journal=decode(p:GetAttribute("PassportJournal"))}
  for id in pairs(allowed) do s.stamps[id]=item(p,"passport_"..id) end
  states[p]=s
  for id,day in pairs(s.stamps) do if day>0 and not s.journal[id] then write(p,id,{historical=true},1) end end
  -- A known Keeper's honour remains visible even if it predates the Passport.
  rememberKeeper(p)
  if not s.journal._batch then advance(p) end
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
print("Passport: 22 personal memories, five-outing pages, saved details")
]====],after=[====[local Players=game:GetService("Players")
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
 p.AttributeChanged:Connect(function(name)if name=="Found_forest" or name=="Found_village" then task.defer(fillEmpty,p)end end)
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
]====]})
table.insert(changes,{target=workspace.Passport.PassportClient,before=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local H=game:GetService("HttpService")
local TextService=game:GetService("TextService")
local p=Players.LocalPlayer;local pg=p:WaitForChild("PlayerGui")
local F=workspace:WaitForChild("Passport")
local catalogue=require(F:WaitForChild("Catalogue"));local J=require(F:WaitForChild("Journal"))
local Art=require(F:WaitForChild("PassportVisuals"))
local toggle=RS:WaitForChild("PassportToggle")
local C=Color3.fromRGB
local PAPER,INK,MUTED,GOLD,PINE=C(255,246,220),C(84,40,10),C(40,24,10),C(240,196,110),C(27,66,43)
local accents={C(79,106,83),C(176,102,66),C(186,137,48),C(120,86,60),C(143,107,66)}
local gui=Instance.new("ScreenGui");gui.Name="PassportGui";gui.ResetOnSpawn=false;gui.DisplayOrder=8;gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=pg
local function round(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function stroke(o,col,w,tr)local s=Instance.new("UIStroke");s.Color=col;s.Thickness=w;s.Transparency=tr or 0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
local function gradient(o,a,b,rot)local g=Instance.new("UIGradient");g.Color=ColorSequence.new(a,b);g.Rotation=rot or 90;g.Parent=o;return g end
local function text(parent,txt,x,y,w,h,size,col,font)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,h);l.Text=txt;l.TextSize=size;l.Font=font or Enum.Font.FredokaOne;l.TextColor3=col or INK;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.TextWrapped=true;l.ZIndex=parent.ZIndex+1;l.Parent=parent;return l
end
local function gildedHeading(label,dark)
 -- Keep glyphs crisp at phone sizes; gold glow belongs on the surrounding frames.
 label.TextStrokeTransparency=1
 if dark then label.TextColor3=C(255,225,128) end
end
local function button(parent,name,txt,x,y,w,h)
 local b=Instance.new("TextButton");b.Name=name;b.Text=txt;b.Font=Enum.Font.FredokaOne;b.TextSize=14;b.TextColor3=INK;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,h);b.BorderSizePixel=0;b.BackgroundColor3=PAPER;b.ZIndex=parent.ZIndex+1;b.Parent=parent;round(b,11);return b
end
local panel=Instance.new("Frame");panel.Name="Page";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-14,0,68);panel.BackgroundColor3=C(255,255,255);panel.BorderSizePixel=0;panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel,18)
panel.BackgroundColor3=PAPER
-- Match the existing Baguette Chase: cream, brown type, one travelling gold rim.
local edge=stroke(panel,C(255,255,255),4)
local ring=Instance.new("UIGradient");ring.Name="Ring"
ring.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(196,136,36)),ColorSequenceKeypoint.new(.55,C(228,170,58)),ColorSequenceKeypoint.new(.85,C(255,222,120)),ColorSequenceKeypoint.new(1,C(255,250,215))});ring.Parent=edge
RunService.RenderStepped:Connect(function(dt)if panel.Visible then ring.Rotation=(ring.Rotation+dt*120)%360 end end)
local header=Instance.new("Frame");header.Name="Cover";header.Position=UDim2.fromOffset(5,5);header.Size=UDim2.new(1,-10,0,47);header.BackgroundTransparency=1;header.BorderSizePixel=0;header.ZIndex=2;header.Parent=panel
local heading=text(header,"Official Passport",49,3,230,24,21,PAPER);heading.TextWrapped=false;heading.TextTruncate=Enum.TextTruncate.AtEnd
gildedHeading(heading,false);heading.TextColor3=INK;heading.TextXAlignment=Enum.TextXAlignment.Center
local summary=text(header,"French Squirrel Country",50,26,250,15,11,C(110,70,30),Enum.Font.GothamMedium);summary.TextXAlignment=Enum.TextXAlignment.Center;summary.TextWrapped=false;summary.TextTruncate=Enum.TextTruncate.AtEnd
local close=button(header,"Close","×",0,3,40,40);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-3,0,3);close.TextColor3=INK;close.BackgroundColor3=C(236,226,206);close.BackgroundTransparency=0;close.TextSize=25
local back=button(header,"Back","‹",3,3,40,40);back.TextColor3=INK;back.BackgroundColor3=C(236,226,206);back.BackgroundTransparency=0;back.TextSize=27;back.Visible=false
local tabs={};local selected="Outings";local detail=nil;local returnScroll=Vector2.zero
for _,name in ipairs({"Outings","Completed","Clues"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end
local scroll=Instance.new("ScrollingFrame");scroll.Name="Entries";scroll.Position=UDim2.fromOffset(14,93);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=GOLD;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.ZIndex=3;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,9);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local rows={};local journal={};local render,fit
local function refreshData()
 local ok,v=pcall(function()return H:JSONDecode(p:GetAttribute("PassportJournal") or "{}")end)
 journal=ok and type(v)=="table" and J.merge(v,{}) or {}
end
local function item(id)return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function isPending(id)
 local b=journal._batch and journal._batch.data or {}
 return table.find(J.ids(b.ids),id) and not table.find(J.ids(b.done),id)
end
local function stamp(parent,record,accent)
 local seal=Instance.new("Frame");seal.Name="PassportStamp";seal.Size=UDim2.fromOffset(63,35);seal.Position=UDim2.new(0,9,1,-44);seal.BackgroundTransparency=1;seal.Rotation=-11;seal.ZIndex=5;seal.Parent=parent;round(seal,17);stroke(seal,accent,1.5,.48)
 local inner=Instance.new("Frame");inner.Size=UDim2.new(1,-5,1,-5);inner.Position=UDim2.fromOffset(2.5,2.5);inner.BackgroundTransparency=1;inner.Parent=seal;round(inner,15);stroke(inner,accent,1,.7)
 local a=text(seal,"COMPLETED",0,4,63,13,8,accent,Enum.Font.GothamBold);a.TextXAlignment=Enum.TextXAlignment.Center;a.TextTransparency=.2
 local visited=record.data.visited or record.at
 local date=visited>1000000 and os.date("!%d %b %Y",math.floor(visited)) or "SOUVENIR"
 local b=text(seal,date,0,18,63,10,7,accent,Enum.Font.GothamBold);b.TextXAlignment=Enum.TextXAlignment.Center;b.TextTransparency=.3
end
local function artTile(parent,id,size,accent,record)
 local tile=Instance.new("Frame");tile.Name="PortraitTile";tile.Size=UDim2.fromOffset(size,size);tile.Position=UDim2.fromOffset(10,10);tile.BackgroundColor3=C(255,255,255);tile.BorderSizePixel=0;tile.ZIndex=4;tile.ClipsDescendants=true;tile.Parent=parent;round(tile,12)
 gradient(tile,accent:Lerp(C(255,255,255),.78),accent:Lerp(PAPER,.5),45);stroke(tile,accent,1,.4)
 local art=Art.draw(tile,id,size,record);art.Position=UDim2.fromOffset(0,0)
 return tile
end
local function addRow(id,title,body,record,onTap,expanded,footer)
 local width=math.max(180,scroll.AbsoluteSize.X-5)
 local accent=accents[(#rows%#accents)+1]
 local mobile=UIS.TouchEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<500)
 local tx=expanded and 16 or 81;local y=expanded and (mobile and 82 or 98) or 34;local fontSize=expanded and (mobile and 13 or 14) or 13
 local bodyWidth=width-tx-(expanded and 16 or 13);local bh=TextService:GetTextSize(body,fontSize,Enum.Font.BuilderSans,Vector2.new(bodyWidth,10000)).Y+5
 local bodyHeight=(record or expanded) and bh or math.min(34,bh)
 local height=math.max(record and 113 or expanded and (mobile and 137 or 165) or 102,y+bodyHeight+(expanded and 16 or record and 12 or 30))
 local r=Instance.new(onTap and "TextButton" or "Frame");r.Name="Entry_"..id;r.Size=UDim2.new(1,-5,0,height);r.LayoutOrder=#rows+1;r.BackgroundColor3=C(255,255,255);r.BorderSizePixel=0;r.ZIndex=3;r.Parent=scroll;round(r,13)
 if r:IsA("TextButton")then r.Text="";r.AutoButtonColor=true end
 r.BackgroundColor3=C(255,250,234);stroke(r,C(220,170,59),1,expanded and .2 or .35)
 if expanded then
  local rim=Instance.new("Frame");rim.Name="DescriptionGoldGlow";rim.BackgroundTransparency=1;rim.Position=UDim2.fromOffset(2,2);rim.Size=UDim2.new(1,-4,1,-4);rim.ZIndex=3;rim.Parent=r;round(rim,11)
  stroke(rim,C(255,205,79),expanded and 5 or 4,expanded and .83 or .91)
  local foil=Instance.new("Frame");foil.Name="DescriptionGoldEdge";foil.BackgroundTransparency=1;foil.Position=UDim2.fromOffset(1,1);foil.Size=UDim2.new(1,-2,1,-2);foil.ZIndex=3;foil.Parent=r;round(foil,12)
  gradient(stroke(foil,GOLD,1,expanded and .24 or .5),C(255,226,138),C(205,144,36),35)
 end
 local tile=artTile(r,id,expanded and (mobile and 60 or 76) or 60,accent,record)
 if expanded then tile.Position=UDim2.fromOffset(14,12)end
 local titleX=expanded and (mobile and 88 or 106) or tx
 local titleLabel=text(r,title,titleX,expanded and 13 or 9,width-titleX-(onTap and 29 or 16),expanded and (mobile and 56 or 66) or 23,expanded and (mobile and 18 or 20) or 16)
 gildedHeading(titleLabel,false)
 if not expanded then titleLabel.TextWrapped=false;titleLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 local bodyLabel=text(r,body,tx,y,bodyWidth,bodyHeight,fontSize,MUTED,Enum.Font.BuilderSans);bodyLabel.Name="Description";bodyLabel.TextYAlignment=Enum.TextYAlignment.Top
 if expanded then bodyLabel.TextXAlignment=Enum.TextXAlignment.Center end
 if not record and not expanded then bodyLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 if record then stamp(r,record,accent)
 elseif not expanded then
  local foot=text(r,footer or (onTap and "Tap for details" or ""),tx,height-25,width-tx-12,18,10,accent,Enum.Font.GothamBold);foot.TextWrapped=false;foot.TextTruncate=Enum.TextTruncate.AtEnd
 end
 if onTap then local arrow=text(r,"›",width-30,8,20,26,24,accent);arrow.TextXAlignment=Enum.TextXAlignment.Center;r.Activated:Connect(onTap)end
 rows[#rows+1]=r;return r
end
local function openDetail(id)
 if selected=="Completed" or (journal[id] and not isPending(id)) then return end
 returnScroll=scroll.CanvasPosition;detail=id;scroll.CanvasPosition=Vector2.zero;fit();render()
end
local moreBusy=false
render=function()
 if not panel.Visible then return end
 refreshData();local previous=scroll.CanvasPosition
 -- A newly finished outing closes its description and moves to Completed.
 if detail and journal[detail] and not isPending(detail) then detail=nil;fit()end
 for _,r in ipairs(rows)do r:Destroy()end;table.clear(rows)
 local total=0;for _,e in ipairs(catalogue)do if journal[e.id]then total+=1 end end
 local outings=item("passport_outings")
 heading.Text=detail and "How to do it" or "Official Passport";heading.TextSize=detail and 19 or 21
 summary.Text=detail and J.byId[detail].name or "French Squirrel Country"
 for name,b in pairs(tabs)do b.BackgroundColor3=name==selected and C(245,170,60) or C(236,226,206);b.TextColor3=INK;b.Visible=not detail end
 back.Visible=detail~=nil
 if detail then
  local e=J.byId[detail];addRow(e.id,e.name,e.detail,nil,nil,true,"Complete this outing to earn its stamp")
 elseif not p:GetAttribute("PassportReady")then
  addRow("find","Opening your Passport","Loading your progress...")
 elseif selected=="Outings" then
  local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)
  summary.Text=string.format("%d of %d completed · %d left to explore",#done,#ids,#ids-#done)
  if #ids==0 then
   summary.Text=total>=21 and "21 adventures completed" or "More adventures to unlock"
   local need=workspace.Boundary:GetAttribute("Need") or 10
   local hint=(p:GetAttribute("Found_forest") or 0)<need and ("Find "..need.." forest squirrels to unlock the Rue and its outings.") or (p:GetAttribute("Found_village") or 0)<need and ("Find "..need.." squirrels on the Rue to unlock the château and its outings.") or "Bring a friend into this server to play the baguette chase. Check Clues for today's Golden Squirrel."
   addRow("keeper",total>=21 and "All outings completed!" or "Keep exploring",total>=21 and "Beat your best race time, take on the daily question, or check Clues for today's Golden Squirrel." or hint,nil,nil,true,"Your results are saved in Completed")
  end
  for _,id in ipairs(ids)do if not table.find(done,id)then local e=J.byId[id];addRow(e.id,e.name,e.hint,nil,function()openDetail(id)end)end end
  if J.batchDone(batch)then
   summary.Text=total>=21 and "21 adventures completed" or string.format("%d of %d outings completed",#done,#ids)
   local card=Instance.new("Frame");card.Name="BatchComplete";card.BackgroundColor3=C(255,255,255);card.BorderSizePixel=0;card.Size=UDim2.new(1,-5,0,104);card.LayoutOrder=1;card.ZIndex=3;card.Parent=scroll;round(card,13);gradient(card,C(255,251,218),C(246,225,157));stroke(card,GOLD,1,.3);rows[#rows+1]=card
   text(card,"Well done, Squirrel Adventurer!",13,7,scroll.AbsoluteSize.X-31,25,17,INK)
   text(card,total>=21 and "Check Clues for daily finds and bonus challenges." or "Ready to explore more of Squirrel Country?",13,32,scroll.AbsoluteSize.X-31,18,11,MUTED,Enum.Font.Gotham)
   local b=button(card,"CompleteMore",moreBusy and "Opening..." or total>=21 and "Open Clues  ›" or "Explore more  ›",12,55,280,40);b.Size=UDim2.new(1,-24,0,40);b.BackgroundColor3=C(255,255,255);gradient(b,C(255,223,104),C(234,172,37));stroke(b,C(167,110,25),1,.4)
   b.Activated:Connect(function()
    if total>=21 then selected="Clues";scroll.CanvasPosition=Vector2.zero;render();return end
    if moreBusy then return end;moreBusy=true;b.Text="Opening..."
    local ok,accepted,message=pcall(function()return F.PassportAction:InvokeServer("more")end);moreBusy=false
    if ok and accepted then scroll.CanvasPosition=Vector2.zero;render()else b.Text=message or "Try again in a moment" end
   end)
  end
 elseif selected=="Completed"then
  summary.Text=string.format("%d %s completed",total,total==1 and "adventure" or "adventures")
  if total==0 then addRow("find","No outings completed yet","Pick an outing and complete it to earn a passport stamp.")end
  local entries={};for _,e in ipairs(catalogue)do if journal[e.id]then entries[#entries+1]=e end end
  table.sort(entries,function(a,b)return(journal[a.id].data.visited or journal[a.id].at)>(journal[b.id].data.visited or journal[b.id].at)end)
  for _,e in ipairs(entries)do addRow(e.id,e.name,J.describe(e.id,journal[e.id],p.DisplayName),journal[e.id])end
 else
  summary.Text="Daily finds & bonus challenges"
  local daily=workspace:FindFirstChild("Daily");local goldName=daily and daily:GetAttribute("GoldName")or"";local goldArea=daily and daily:GetAttribute("GoldArea")or""
  addRow("gold","Today's Golden Squirrel",goldName~="" and(goldName.." is hiding in "..goldArea..".")or"Today's clue is getting ready.",nil,not journal.gold and function()openDetail("gold")end or nil,false,"A fresh Golden Squirrel each day")
  local e=J.byId.keeper
  addRow("keeper",e.name,journal.keeper and "Your honour is recorded in Completed. Visit your statue at the Hall of Fame!" or e.hint,nil,not journal.keeper and function()openDetail("keeper")end or nil,false,"BONUS · never holds up your outings")
  addRow("gold","Your golden cover","Enjoy three different activities in a day. Five such days earn a golden cover. Missing a day never takes progress away.\n\nProgress: "..math.min(outings,5).." / 5 days.",nil,nil,true)
 end
 scroll.CanvasPosition=previous
end
fit=function()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local mobile=UIS.TouchEnabled or vp.Y<500
 local width=math.min(mobile and 350 or 412,vp.X-28)
 local height=math.min(560,math.max(140,vp.Y-68-(mobile and 92 or 24)))
 panel.Size=UDim2.fromOffset(width,height)
 local top=detail and 60 or 93
 scroll.Position=UDim2.fromOffset(14,top);scroll.Size=UDim2.fromOffset(width-25,height-top-10)
 local hx=49
 heading.Position=UDim2.fromOffset(hx,3);summary.Position=UDim2.fromOffset(hx,26)
 heading.Size=UDim2.fromOffset(width-hx-62,24);summary.Size=UDim2.fromOffset(width-hx-62,15)
 local tw=(width-36)/3
 for i,name in ipairs({"Outings","Completed","Clues"})do tabs[name].Position=UDim2.fromOffset(14+(i-1)*(tw+4),56);tabs[name].Size=UDim2.fromOffset(tw,30)end
end
back.Activated:Connect(function()detail=nil;fit();render();scroll.CanvasPosition=returnScroll end)

local suppressed={};local quietNames={PromptTouch=true,PromptUI=true,HintGui=true,ChaseGui=true,ChaseInfoGui=true,DailyGui=true,SpeedGui=true}
local function coordinatePanels()
 local active=pg:GetAttribute("OpenPanel");local quiet=active=="passport" or active=="shop" or active=="book"
 if quiet then
  for _,g in ipairs(pg:GetChildren()) do if quietNames[g.Name] and (g:IsA("ScreenGui") or g:IsA("BillboardGui")) then if suppressed[g]==nil then suppressed[g]=g.Enabled end;g.Enabled=false end end
 else for g,enabled in pairs(suppressed) do if g.Parent then g.Enabled=enabled end end;table.clear(suppressed) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels);pg.ChildAdded:Connect(function()task.defer(coordinatePanels)end)
local openedAt=0
local function closePage()panel.Visible=false;if pg:GetAttribute("OpenPanel")=="passport" then pg:SetAttribute("OpenPanel",nil) end end
local function openPage()
 pg:SetAttribute("OpenPanel","passport");panel.Visible=true;openedAt=os.clock();fit();render()
end
toggle.Event:Connect(function()if panel.Visible then closePage() else openPage() end end);close.Activated:Connect(closePage)
for name,b in pairs(tabs) do b.Activated:Connect(function()selected=name;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if panel.Visible and pg:GetAttribute("OpenPanel")~="passport" then closePage() end end)
local function watchGui(g)
 if g:IsA("ScreenGui") and (g.Name=="ShopPanel" or g.Name=="BookReader" or g.Name=="HatShopGui" or g.Name=="GoldenReveal") then
  g:GetPropertyChangedSignal("Enabled"):Connect(function()if g.Enabled and panel.Visible then closePage() end end)
 end
end
pg.ChildAdded:Connect(watchGui);for _,g in ipairs(pg:GetChildren())do watchGui(g)end
local pending=false
p.AttributeChanged:Connect(function(name)
 if panel.Visible and (name=="PassportJournal" or name=="PassportReady" or name=="Item_passport_outings") and not pending then pending=true;task.defer(function()pending=false;render()end)end
end)
local cameraConnection
local function cameraChanged()
 if cameraConnection then cameraConnection:Disconnect() end;fit()
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()fit();render()end)end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
UIS.InputBegan:Connect(function(input,processed)if not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB)then closePage()end end)
RunService.Heartbeat:Connect(function()
 if not panel.Visible then return end
 local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not char or p:GetAttribute("Racing") or p:GetAttribute("Climbing") or p:GetAttribute("InChase") or char:GetAttribute("Riding") or char:GetAttribute("Gliding") or char:GetAttribute("MillRiding") then closePage();return end
 if hum and hum.MoveDirection.Magnitude>0.1 and os.clock()-openedAt>0.35 then closePage()end
end)
task.spawn(function()while gui.Parent do task.wait(30);if panel.Visible and selected=="Clues" then render()end end end)
print("Passport: outings and completed stamps ready")
]====],after=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local H=game:GetService("HttpService")
local TextService=game:GetService("TextService")
local p=Players.LocalPlayer;local pg=p:WaitForChild("PlayerGui")
local F=workspace:WaitForChild("Passport")
local catalogue=require(F:WaitForChild("Catalogue"));local J=require(F:WaitForChild("Journal"))
local Art=require(F:WaitForChild("PassportVisuals"))
local toggle=RS:WaitForChild("PassportToggle")
local C=Color3.fromRGB
local PAPER,INK,MUTED,GOLD,PINE=C(255,246,220),C(84,40,10),C(40,24,10),C(240,196,110),C(27,66,43)
local accents={C(79,106,83),C(176,102,66),C(186,137,48),C(120,86,60),C(143,107,66)}
local gui=Instance.new("ScreenGui");gui.Name="PassportGui";gui.ResetOnSpawn=false;gui.DisplayOrder=8;gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=pg
local function round(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function stroke(o,col,w,tr)local s=Instance.new("UIStroke");s.Color=col;s.Thickness=w;s.Transparency=tr or 0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
local function gradient(o,a,b,rot)local g=Instance.new("UIGradient");g.Color=ColorSequence.new(a,b);g.Rotation=rot or 90;g.Parent=o;return g end
local function text(parent,txt,x,y,w,h,size,col,font)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,h);l.Text=txt;l.TextSize=size;l.Font=font or Enum.Font.FredokaOne;l.TextColor3=col or INK;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.TextWrapped=true;l.ZIndex=parent.ZIndex+1;l.Parent=parent;return l
end
local function gildedHeading(label,dark)
 -- Keep glyphs crisp at phone sizes; gold glow belongs on the surrounding frames.
 label.TextStrokeTransparency=1
 if dark then label.TextColor3=C(255,225,128) end
end
local function button(parent,name,txt,x,y,w,h)
 local b=Instance.new("TextButton");b.Name=name;b.Text=txt;b.Font=Enum.Font.FredokaOne;b.TextSize=14;b.TextColor3=INK;b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,h);b.BorderSizePixel=0;b.BackgroundColor3=PAPER;b.ZIndex=parent.ZIndex+1;b.Parent=parent;round(b,11);return b
end
local panel=Instance.new("Frame");panel.Name="Page";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-14,0,68);panel.BackgroundColor3=C(255,255,255);panel.BorderSizePixel=0;panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel,18)
panel.BackgroundColor3=PAPER
-- Match the existing Baguette Chase: cream, brown type, one travelling gold rim.
local edge=stroke(panel,C(255,255,255),4)
local ring=Instance.new("UIGradient");ring.Name="Ring"
ring.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(196,136,36)),ColorSequenceKeypoint.new(.55,C(228,170,58)),ColorSequenceKeypoint.new(.85,C(255,222,120)),ColorSequenceKeypoint.new(1,C(255,250,215))});ring.Parent=edge
RunService.RenderStepped:Connect(function(dt)if panel.Visible then ring.Rotation=(ring.Rotation+dt*120)%360 end end)
local header=Instance.new("Frame");header.Name="Cover";header.Position=UDim2.fromOffset(5,5);header.Size=UDim2.new(1,-10,0,47);header.BackgroundTransparency=1;header.BorderSizePixel=0;header.ZIndex=2;header.Parent=panel
local heading=text(header,"Official Passport",49,3,230,24,21,PAPER);heading.TextWrapped=false;heading.TextTruncate=Enum.TextTruncate.AtEnd
gildedHeading(heading,false);heading.TextColor3=INK;heading.TextXAlignment=Enum.TextXAlignment.Center
local summary=text(header,"French Squirrel Country",50,26,250,15,11,C(110,70,30),Enum.Font.GothamMedium);summary.TextXAlignment=Enum.TextXAlignment.Center;summary.TextWrapped=false;summary.TextTruncate=Enum.TextTruncate.AtEnd
local close=button(header,"Close","×",0,3,40,40);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-3,0,3);close.TextColor3=INK;close.BackgroundColor3=C(236,226,206);close.BackgroundTransparency=0;close.TextSize=25
local back=button(header,"Back","‹",3,3,40,40);back.TextColor3=INK;back.BackgroundColor3=C(236,226,206);back.BackgroundTransparency=0;back.TextSize=27;back.Visible=false
local tabs={};local selected="Outings";local detail=nil;local returnScroll=Vector2.zero
for _,name in ipairs({"Outings","Completed","Clues"})do tabs[name]=button(panel,name,name,0,56,95,30);tabs[name].TextSize=13 end
local scroll=Instance.new("ScrollingFrame");scroll.Name="Entries";scroll.Position=UDim2.fromOffset(14,93);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=GOLD;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.ZIndex=3;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,9);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local rows={};local journal={};local render,fit
local function refreshData()
 local ok,v=pcall(function()return H:JSONDecode(p:GetAttribute("PassportJournal") or "{}")end)
 journal=ok and type(v)=="table" and J.merge(v,{}) or {}
end
local function item(id)return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function isPending(id)
 local b=journal._batch and journal._batch.data or {}
 return not journal[id] and table.find(J.ids(b.ids),id) and not table.find(J.ids(b.done),id)
end
local function stamp(parent,record,accent)
 local seal=Instance.new("Frame");seal.Name="PassportStamp";seal.Size=UDim2.fromOffset(63,35);seal.Position=UDim2.new(0,9,1,-44);seal.BackgroundTransparency=1;seal.Rotation=-11;seal.ZIndex=5;seal.Parent=parent;round(seal,17);stroke(seal,accent,1.5,.48)
 local inner=Instance.new("Frame");inner.Size=UDim2.new(1,-5,1,-5);inner.Position=UDim2.fromOffset(2.5,2.5);inner.BackgroundTransparency=1;inner.Parent=seal;round(inner,15);stroke(inner,accent,1,.7)
 local a=text(seal,"COMPLETED",0,4,63,13,8,accent,Enum.Font.GothamBold);a.TextXAlignment=Enum.TextXAlignment.Center;a.TextTransparency=.2
 local visited=record.data.visited or record.at
 local date=visited>1000000 and os.date("!%d %b %Y",math.floor(visited)) or "EARLIER VISIT"
 local b=text(seal,date,0,18,63,10,7,accent,Enum.Font.GothamBold);b.TextXAlignment=Enum.TextXAlignment.Center;b.TextTransparency=.3
end
local function artTile(parent,id,size,accent,record)
 local tile=Instance.new("Frame");tile.Name="PortraitTile";tile.Size=UDim2.fromOffset(size,size);tile.Position=UDim2.fromOffset(10,10);tile.BackgroundColor3=C(255,255,255);tile.BorderSizePixel=0;tile.ZIndex=4;tile.ClipsDescendants=true;tile.Parent=parent;round(tile,12)
 gradient(tile,accent:Lerp(C(255,255,255),.78),accent:Lerp(PAPER,.5),45);stroke(tile,accent,1,.4)
 local art=Art.draw(tile,id,size,record);art.Position=UDim2.fromOffset(0,0)
 return tile
end
local function addRow(id,title,body,record,onTap,expanded,footer)
 local width=math.max(180,scroll.AbsoluteSize.X-5)
 local accent=accents[(#rows%#accents)+1]
 local mobile=UIS.TouchEnabled or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<500)
 local tx=expanded and 16 or 81;local y=expanded and (mobile and 82 or 98) or 34;local fontSize=expanded and (mobile and 13 or 14) or 13
 local bodyWidth=width-tx-(expanded and 16 or 13);local bh=TextService:GetTextSize(body,fontSize,Enum.Font.BuilderSans,Vector2.new(bodyWidth,10000)).Y+5
 local bodyHeight=(record or expanded) and bh or math.min(34,bh)
 local height=math.max(record and 113 or expanded and (mobile and 137 or 165) or 102,y+bodyHeight+(expanded and 16 or record and 12 or 30))
 local r=Instance.new(onTap and "TextButton" or "Frame");r.Name="Entry_"..id;r.Size=UDim2.new(1,-5,0,height);r.LayoutOrder=#rows+1;r.BackgroundColor3=C(255,255,255);r.BorderSizePixel=0;r.ZIndex=3;r.Parent=scroll;round(r,13)
 if r:IsA("TextButton")then r.Text="";r.AutoButtonColor=true end
 r.BackgroundColor3=C(255,250,234);stroke(r,C(220,170,59),1,expanded and .2 or .35)
 if expanded then
  local rim=Instance.new("Frame");rim.Name="DescriptionGoldGlow";rim.BackgroundTransparency=1;rim.Position=UDim2.fromOffset(2,2);rim.Size=UDim2.new(1,-4,1,-4);rim.ZIndex=3;rim.Parent=r;round(rim,11)
  stroke(rim,C(255,205,79),expanded and 5 or 4,expanded and .83 or .91)
  local foil=Instance.new("Frame");foil.Name="DescriptionGoldEdge";foil.BackgroundTransparency=1;foil.Position=UDim2.fromOffset(1,1);foil.Size=UDim2.new(1,-2,1,-2);foil.ZIndex=3;foil.Parent=r;round(foil,12)
  gradient(stroke(foil,GOLD,1,expanded and .24 or .5),C(255,226,138),C(205,144,36),35)
 end
 local tile=artTile(r,id,expanded and (mobile and 60 or 76) or 60,accent,record)
 if expanded then tile.Position=UDim2.fromOffset(14,12)end
 local titleX=expanded and (mobile and 88 or 106) or tx
 local titleLabel=text(r,title,titleX,expanded and 13 or 9,width-titleX-(onTap and 29 or 16),expanded and (mobile and 56 or 66) or 23,expanded and (mobile and 18 or 20) or 16)
 gildedHeading(titleLabel,false)
 if not expanded then titleLabel.TextWrapped=false;titleLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 local bodyLabel=text(r,body,tx,y,bodyWidth,bodyHeight,fontSize,MUTED,Enum.Font.BuilderSans);bodyLabel.Name="Description";bodyLabel.TextYAlignment=Enum.TextYAlignment.Top
 if expanded then bodyLabel.TextXAlignment=Enum.TextXAlignment.Center end
 if not record and not expanded then bodyLabel.TextTruncate=Enum.TextTruncate.AtEnd end
 if record then stamp(r,record,accent)
 elseif not expanded then
  local foot=text(r,footer or (onTap and "Tap for details" or ""),tx,height-25,width-tx-12,18,10,accent,Enum.Font.GothamBold);foot.TextWrapped=false;foot.TextTruncate=Enum.TextTruncate.AtEnd
 end
 if onTap then local arrow=text(r,"›",width-30,8,20,26,24,accent);arrow.TextXAlignment=Enum.TextXAlignment.Center;r.Activated:Connect(onTap)end
 rows[#rows+1]=r;return r
end
local function openDetail(id)
 if selected=="Completed" or (journal[id] and not isPending(id)) then return end
 returnScroll=scroll.CanvasPosition;detail=id;scroll.CanvasPosition=Vector2.zero;fit();render()
end
local moreBusy=false
render=function()
 if not panel.Visible then return end
 refreshData();local previous=scroll.CanvasPosition
 -- A newly finished outing closes its description and moves to Completed.
 if detail and journal[detail] and not isPending(detail) then detail=nil;fit()end
 for _,r in ipairs(rows)do r:Destroy()end;table.clear(rows)
 local total=0;for _,e in ipairs(catalogue)do if journal[e.id]then total+=1 end end
 local outings=item("passport_outings")
 heading.Text=detail and "How to do it" or "Official Passport";heading.TextSize=detail and 19 or 21
 summary.Text=detail and J.byId[detail].name or "French Squirrel Country"
 for name,b in pairs(tabs)do b.BackgroundColor3=name==selected and C(245,170,60) or C(236,226,206);b.TextColor3=INK;b.Visible=not detail end
 back.Visible=detail~=nil
 if detail then
  local e=J.byId[detail];addRow(e.id,e.name,e.detail,nil,nil,true,"Complete this outing to earn its stamp")
 elseif not p:GetAttribute("PassportReady")then
  addRow("find","Opening your Passport","Loading your progress...")
 elseif selected=="Outings" then
  local batch=journal._batch and journal._batch.data or {};local ids=J.ids(batch.ids);local done=J.ids(batch.done)
  summary.Text=string.format("%d of %d completed · %d left to explore",#done,#ids,#ids-#done)
  if #ids==0 then
   summary.Text=total>=21 and "21 adventures completed" or "More adventures to unlock"
   local need=workspace.Boundary:GetAttribute("Need") or 10
   local hint=(p:GetAttribute("Found_forest") or 0)<need and ("Find "..need.." forest squirrels to unlock the Rue and its outings.") or (p:GetAttribute("Found_village") or 0)<need and ("Find "..need.." squirrels on the Rue to unlock the château and its outings.") or "Bring a friend into this server to play the baguette chase. Check Clues for today's Golden Squirrel."
   addRow("keeper",total>=21 and "All outings completed!" or "Keep exploring",total>=21 and "Beat your best race time, take on the daily question, or check Clues for today's Golden Squirrel." or hint,nil,nil,true,"Your results are saved in Completed")
  end
  for _,id in ipairs(ids)do if not journal[id] and not table.find(done,id)then local e=J.byId[id];addRow(e.id,e.name,e.hint,nil,function()openDetail(id)end)end end
  if J.batchDone(batch)then
   summary.Text=total>=21 and "21 adventures completed" or string.format("%d of %d outings completed",#done,#ids)
   local card=Instance.new("Frame");card.Name="BatchComplete";card.BackgroundColor3=C(255,255,255);card.BorderSizePixel=0;card.Size=UDim2.new(1,-5,0,104);card.LayoutOrder=1;card.ZIndex=3;card.Parent=scroll;round(card,13);gradient(card,C(255,251,218),C(246,225,157));stroke(card,GOLD,1,.3);rows[#rows+1]=card
   text(card,"Well done, Squirrel Adventurer!",13,7,scroll.AbsoluteSize.X-31,25,17,INK)
   text(card,total>=21 and "Check Clues for daily finds and bonus challenges." or "Ready to explore more of Squirrel Country?",13,32,scroll.AbsoluteSize.X-31,18,11,MUTED,Enum.Font.Gotham)
   local b=button(card,"CompleteMore",moreBusy and "Opening..." or total>=21 and "Open Clues  ›" or "Explore more  ›",12,55,280,40);b.Size=UDim2.new(1,-24,0,40);b.BackgroundColor3=C(255,255,255);gradient(b,C(255,223,104),C(234,172,37));stroke(b,C(167,110,25),1,.4)
   b.Activated:Connect(function()
    if total>=21 then selected="Clues";scroll.CanvasPosition=Vector2.zero;render();return end
    if moreBusy then return end;moreBusy=true;b.Text="Opening..."
    local ok,accepted,message=pcall(function()return F.PassportAction:InvokeServer("more")end);moreBusy=false
    if ok and accepted then scroll.CanvasPosition=Vector2.zero;render()else b.Text=message or "Try again in a moment" end
   end)
  end
 elseif selected=="Completed"then
  summary.Text=string.format("%d %s completed",total,total==1 and "adventure" or "adventures")
  if total==0 then addRow("find","No outings completed yet","Pick an outing and complete it to earn a passport stamp.")end
  local entries={};for _,e in ipairs(catalogue)do if journal[e.id]then entries[#entries+1]=e end end
  table.sort(entries,function(a,b)return(journal[a.id].data.visited or journal[a.id].at)>(journal[b.id].data.visited or journal[b.id].at)end)
  for _,e in ipairs(entries)do addRow(e.id,e.name,J.describe(e.id,journal[e.id],p.DisplayName),journal[e.id])end
 else
  summary.Text="Daily finds & bonus challenges"
  local daily=workspace:FindFirstChild("Daily");local goldName=daily and daily:GetAttribute("GoldName")or"";local goldArea=daily and daily:GetAttribute("GoldArea")or""
  addRow("gold","Today's Golden Squirrel",goldName~="" and(goldName.." is hiding in "..goldArea..".")or"Today's clue is getting ready.",nil,not journal.gold and function()openDetail("gold")end or nil,false,"A fresh Golden Squirrel each day")
  local e=J.byId.keeper
  addRow("keeper",e.name,journal.keeper and "Your honour is recorded in Completed. Visit your statue at the Hall of Fame!" or e.hint,nil,not journal.keeper and function()openDetail("keeper")end or nil,false,"BONUS · never holds up your outings")
  addRow("gold","Your golden cover","Enjoy three different activities in a day. Five such days earn a golden cover. Missing a day never takes progress away.\n\nProgress: "..math.min(outings,5).." / 5 days.",nil,nil,true)
 end
 scroll.CanvasPosition=previous
end
fit=function()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local mobile=UIS.TouchEnabled or vp.Y<500
 local width=math.min(mobile and 350 or 412,vp.X-28)
 local height=math.min(560,math.max(140,vp.Y-68-(mobile and 92 or 24)))
 panel.Size=UDim2.fromOffset(width,height)
 local top=detail and 60 or 93
 scroll.Position=UDim2.fromOffset(14,top);scroll.Size=UDim2.fromOffset(width-25,height-top-10)
 local hx=49
 heading.Position=UDim2.fromOffset(hx,3);summary.Position=UDim2.fromOffset(hx,26)
 heading.Size=UDim2.fromOffset(width-hx-62,24);summary.Size=UDim2.fromOffset(width-hx-62,15)
 local tw=(width-36)/3
 for i,name in ipairs({"Outings","Completed","Clues"})do tabs[name].Position=UDim2.fromOffset(14+(i-1)*(tw+4),56);tabs[name].Size=UDim2.fromOffset(tw,30)end
end
back.Activated:Connect(function()detail=nil;fit();render();scroll.CanvasPosition=returnScroll end)

local suppressed={};local quietNames={PromptTouch=true,PromptUI=true,HintGui=true,ChaseGui=true,ChaseInfoGui=true,DailyGui=true,SpeedGui=true}
local function coordinatePanels()
 local active=pg:GetAttribute("OpenPanel");local quiet=active=="passport" or active=="shop" or active=="book"
 if quiet then
  for _,g in ipairs(pg:GetChildren()) do if quietNames[g.Name] and (g:IsA("ScreenGui") or g:IsA("BillboardGui")) then if suppressed[g]==nil then suppressed[g]=g.Enabled end;g.Enabled=false end end
 else for g,enabled in pairs(suppressed) do if g.Parent then g.Enabled=enabled end end;table.clear(suppressed) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels);pg.ChildAdded:Connect(function()task.defer(coordinatePanels)end)
local openedAt=0
local function closePage()panel.Visible=false;if pg:GetAttribute("OpenPanel")=="passport" then pg:SetAttribute("OpenPanel",nil) end end
local function openPage()
 pg:SetAttribute("OpenPanel","passport");panel.Visible=true;openedAt=os.clock();fit();render()
end
toggle.Event:Connect(function()if panel.Visible then closePage() else openPage() end end);close.Activated:Connect(closePage)
for name,b in pairs(tabs) do b.Activated:Connect(function()selected=name;detail=nil;scroll.CanvasPosition=Vector2.zero;fit();render()end) end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()if panel.Visible and pg:GetAttribute("OpenPanel")~="passport" then closePage() end end)
local function watchGui(g)
 if g:IsA("ScreenGui") and (g.Name=="ShopPanel" or g.Name=="BookReader" or g.Name=="HatShopGui" or g.Name=="GoldenReveal") then
  g:GetPropertyChangedSignal("Enabled"):Connect(function()if g.Enabled and panel.Visible then closePage() end end)
 end
end
pg.ChildAdded:Connect(watchGui);for _,g in ipairs(pg:GetChildren())do watchGui(g)end
local pending=false
p.AttributeChanged:Connect(function(name)
 if panel.Visible and (name=="PassportJournal" or name=="PassportReady" or name=="Item_passport_outings") and not pending then pending=true;task.defer(function()pending=false;render()end)end
end)
local cameraConnection
local function cameraChanged()
 if cameraConnection then cameraConnection:Disconnect() end;fit()
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()fit();render()end)end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
UIS.InputBegan:Connect(function(input,processed)if not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB)then closePage()end end)
RunService.Heartbeat:Connect(function()
 if not panel.Visible then return end
 local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not char or p:GetAttribute("Racing") or p:GetAttribute("Climbing") or p:GetAttribute("InChase") or char:GetAttribute("Riding") or char:GetAttribute("Gliding") or char:GetAttribute("MillRiding") then closePage();return end
 if hum and hum.MoveDirection.Magnitude>0.1 and os.clock()-openedAt>0.35 then closePage()end
end)
task.spawn(function()while gui.Parent do task.wait(30);if panel.Visible and selected=="Clues" then render()end end end)
print("Passport: outings and completed stamps ready")
]====]})
table.insert(changes,{target=workspace.ResetUI.ResetClient,before=[====[-- ResetButton: a quiet "Reset progress" link; the first click opens a confirmation, only the second click wipes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local ev = ReplicatedStorage:WaitForChild("SquirrelReset", 60)
local gui = Instance.new("ScreenGui"); gui.Name = "ResetGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 8; gui.Parent = player:WaitForChild("PlayerGui")

-- the quiet link, bottom left
local link = Instance.new("TextButton"); link.Name = "ResetLink"; link.Size = UDim2.new(0, 132, 0, 26); link.Position = UDim2.new(0, 12, 1, -36)
link.BackgroundColor3 = C(28, 22, 38); link.BackgroundTransparency = 0.55; link.BorderSizePixel = 0; link.AutoButtonColor = false
link.Font = Enum.Font.FredokaOne; link.TextSize = 13; link.TextColor3 = C(210, 200, 220); link.TextTransparency = 0.25; link.Text = "Reset progress"; link.Parent = gui
local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 13); lc.Parent = link
-- ON A PHONE it keeps clear of the thumbstick (Shannon, Sep 26: "on that phone, nothing should be overlapping. At any
-- time." ... "reset progress definitely has to go underneath that circle move button, not above"): a smaller link,
-- centred under the thumbstick's resting circle, wherever the phone puts it (re-measured when the screen turns)
local UIS = game:GetService("UserInputService")
if UIS.TouchEnabled and not UIS.MouseEnabled then
	local GuiService = game:GetService("GuiService")
	local function fit()
		local tg = player.PlayerGui:FindFirstChild("TouchGui")
		local stick = tg and (tg:FindFirstChild("ThumbstickStart", true) or tg:FindFirstChild("ThumbstickFrame", true))
		if stick and stick:IsA("GuiObject") and stick.AbsoluteSize.Y > 0 then
			local sg = stick:FindFirstAncestorOfClass("ScreenGui")
			local inset = (sg and not sg.IgnoreGuiInset) and GuiService:GetGuiInset().Y or 0
			local vs = workspace.CurrentCamera.ViewportSize
			local screenH = vs.Y                                            -- (this gui ignores the inset: the whole screen)
			-- as far below the circle as the screen allows, so a thumb on the stick doesn't catch it (Shannon: "a little further
			-- down from the joystick thing, you might accidentally press it while you're playing")
			link.Size = UDim2.new(0, 96, 0, 13); link.TextSize = 10
			local lc2 = link:FindFirstChildOfClass("UICorner"); if lc2 then lc2.CornerRadius = UDim.new(0, 7) end
			local cx = stick.AbsolutePosition.X + stick.AbsoluteSize.X / 2
			local y = math.max(stick.AbsolutePosition.Y + inset + stick.AbsoluteSize.Y + 1, screenH - 14)
			link.Position = UDim2.new(0, math.max(4, cx - 48), 0, y)
			return true
		end
		return false
	end
	task.spawn(function()
		local t0 = os.clock()
		while not fit() and os.clock() - t0 < 30 do task.wait(1) end
	end)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() task.delay(0.5, fit) end)
end
link.MouseEnter:Connect(function() TweenService:Create(link, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, TextTransparency = 0}):Play() end)
link.MouseLeave:Connect(function() TweenService:Create(link, TweenInfo.new(0.25), {BackgroundTransparency = 0.55, TextTransparency = 0.25}):Play() end)

-- the confirmation
local shade = Instance.new("TextButton"); shade.Name = "Shade"; shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(0, 0, 0); shade.BackgroundTransparency = 0.45
shade.BorderSizePixel = 0; shade.Text = ""; shade.AutoButtonColor = false; shade.Visible = false; shade.ZIndex = 20; shade.Parent = gui
local box = Instance.new("Frame"); box.Size = UDim2.new(0, 460, 0, 250); box.Position = UDim2.new(0.5, -230, 0.5, -125); box.BackgroundColor3 = C(38, 30, 52)
box.BorderSizePixel = 0; box.ZIndex = 21; box.Parent = shade
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = box
local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 2; bs.Parent = box
local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -40, 0, 44); title.Position = UDim2.new(0, 20, 0, 18); title.BackgroundTransparency = 1
title.Font = Enum.Font.Antique; title.TextSize = 34; title.TextColor3 = C(255, 214, 90); title.Text = "Are you sure?"; title.ZIndex = 22; title.Parent = box
local body = Instance.new("TextLabel"); body.Name = "Body"; body.Size = UDim2.new(1, -44, 0, 92); body.Position = UDim2.new(0, 22, 0, 62); body.BackgroundTransparency = 1
body.Font = Enum.Font.FredokaOne; body.TextSize = 17; body.TextWrapped = true; body.TextColor3 = C(255, 246, 220); body.ZIndex = 22; body.Parent = box
local function mkButton(name, text, x, fill, ink)
	local b = Instance.new("TextButton"); b.Name = name; b.Size = UDim2.new(0, 190, 0, 46); b.Position = UDim2.new(0, x, 1, -62); b.BackgroundColor3 = fill
	b.BorderSizePixel = 0; b.Font = Enum.Font.FredokaOne; b.TextSize = 19; b.TextColor3 = ink; b.Text = text; b.ZIndex = 22; b.Parent = box
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 23); c.Parent = b
	return b
end
local keep = mkButton("Keep", "Keep my squirrels", 20, C(70, 60, 90), C(255, 246, 220))
local wipe = mkButton("Wipe", "Yes, reset everything", 250, C(196, 58, 58), C(255, 250, 244))
local function refreshBody()
	local n = player:GetAttribute("SquirrelsFound") or 0
	body.Text = string.format("This wipes all %d squirrel%s you have found, and any titles you have earned. You will start again at zero. This cannot be undone.", n, n == 1 and "" or "s")
end
local function close() shade.Visible = false end
link.Activated:Connect(function() refreshBody(); shade.Visible = true end)
keep.Activated:Connect(close)
shade.Activated:Connect(close)
wipe.Activated:Connect(function()
	wipe.Text = "Resetting..."; wipe.AutoButtonColor = false
	if ev then ev:FireServer() end
	task.delay(1.5, function() wipe.Text = "Yes, reset everything"; wipe.AutoButtonColor = true; close() end)
end)
if ev then
	ev.OnClientEvent:Connect(function()
		local done = Instance.new("TextLabel"); done.Size = UDim2.new(0, 420, 0, 54); done.Position = UDim2.new(0.5, -210, 0.24, 0); done.BackgroundColor3 = C(38, 30, 52)
		done.BackgroundTransparency = 0.15; done.Font = Enum.Font.FredokaOne; done.TextSize = 20; done.TextColor3 = C(255, 246, 220)
		done.Text = "Progress reset. Every squirrel is hidden again!"; done.ZIndex = 25; done.Parent = gui
		local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 14); dc.Parent = done
		task.delay(4, function() done:Destroy() end)
	end)
end
]====],after=[====[-- ResetButton: a quiet "Reset progress" link; the first click opens a confirmation, only the second click wipes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local ev = ReplicatedStorage:WaitForChild("SquirrelReset", 60)
local gui = Instance.new("ScreenGui"); gui.Name = "ResetGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 8; gui.Parent = player:WaitForChild("PlayerGui")

-- the quiet link, bottom left
local link = Instance.new("TextButton"); link.Name = "ResetLink"; link.Size = UDim2.new(0, 132, 0, 26); link.Position = UDim2.new(0, 12, 1, -36)
link.BackgroundColor3 = C(28, 22, 38); link.BackgroundTransparency = 0.55; link.BorderSizePixel = 0; link.AutoButtonColor = false
link.Font = Enum.Font.FredokaOne; link.TextSize = 13; link.TextColor3 = C(210, 200, 220); link.TextTransparency = 0.25; link.Text = "Reset progress"; link.Parent = gui
local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 13); lc.Parent = link
-- A readable 128 x 44 touch target, below the resting stick when it fits.
-- If the stick leaves too little space, use the adjacent lower-left space.
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local function fitResetLink()
 local camera=workspace.CurrentCamera;if not camera then return false end
 local vp=camera.ViewportSize
 local mobile=UIS.TouchEnabled or vp.Y<500
 link.Size=UDim2.fromOffset(mobile and 128 or 132,44)
 link.TextSize=14;link.TextTransparency=0
 local x,y=12,vp.Y-52
 local tg=player.PlayerGui:FindFirstChild("TouchGui")
 local stick=tg and (tg:FindFirstChild("ThumbstickFrame",true) or tg:FindFirstChild("ThumbstickStart",true))
 if mobile and stick and stick:IsA("GuiObject") and stick.AbsoluteSize.Y>0 then
  local sg=stick:FindFirstAncestorOfClass("ScreenGui")
  local inset=(sg and not sg.IgnoreGuiInset) and GuiService:GetGuiInset().Y or 0
  local pos,size=stick.AbsolutePosition,stick.AbsoluteSize
  x=math.max(8,pos.X+size.X/2-64)
  if pos.Y+inset+size.Y+8>y then x=pos.X+size.X+12 end
 end
 link.Position=UDim2.fromOffset(math.clamp(x,8,math.max(8,vp.X-136)),y)
 return stick~=nil or not mobile
end
fitResetLink()
task.spawn(function()
 local t0=os.clock()
 while not fitResetLink() and os.clock()-t0<30 do task.wait(.5)end
end)

link.MouseEnter:Connect(function() TweenService:Create(link, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, TextTransparency = 0}):Play() end)
link.MouseLeave:Connect(function() TweenService:Create(link, TweenInfo.new(0.25), {BackgroundTransparency = 0.55, TextTransparency = 0}):Play() end)

-- the confirmation
local shade = Instance.new("TextButton"); shade.Name = "Shade"; shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C(0, 0, 0); shade.BackgroundTransparency = 0.45
shade.BorderSizePixel = 0; shade.Text = ""; shade.AutoButtonColor = false; shade.Visible = false; shade.ZIndex = 20; shade.Parent = gui
local box = Instance.new("Frame"); box.Size = UDim2.new(0, 460, 0, 250); box.Position = UDim2.new(0.5, -230, 0.5, -125); box.BackgroundColor3 = C(38, 30, 52)
box.BorderSizePixel = 0; box.ZIndex = 21; box.Parent = shade
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = box
local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 2; bs.Parent = box
local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -40, 0, 44); title.Position = UDim2.new(0, 20, 0, 18); title.BackgroundTransparency = 1
title.Font = Enum.Font.Antique; title.TextSize = 34; title.TextColor3 = C(255, 214, 90); title.Text = "Are you sure?"; title.ZIndex = 22; title.Parent = box
local body = Instance.new("TextLabel"); body.Name = "Body"; body.Size = UDim2.new(1, -44, 0, 92); body.Position = UDim2.new(0, 22, 0, 62); body.BackgroundTransparency = 1
body.Font = Enum.Font.FredokaOne; body.TextSize = 17; body.TextWrapped = true; body.TextColor3 = C(255, 246, 220); body.ZIndex = 22; body.Parent = box
local function mkButton(name, text, x, fill, ink)
	local b = Instance.new("TextButton"); b.Name = name; b.Size = UDim2.new(0, 190, 0, 46); b.Position = UDim2.new(0, x, 1, -62); b.BackgroundColor3 = fill
	b.BorderSizePixel = 0; b.Font = Enum.Font.FredokaOne; b.TextSize = 19; b.TextColor3 = ink; b.Text = text; b.ZIndex = 22; b.Parent = box
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 23); c.Parent = b
	return b
end
local keep = mkButton("Keep", "Keep my squirrels", 20, C(70, 60, 90), C(255, 246, 220))
local wipe = mkButton("Wipe", "Reset squirrels", 250, C(196, 58, 58), C(255, 250, 244))
local function fitReset()
 fitResetLink()
 local vp=workspace.CurrentCamera.ViewportSize
 local width=math.min(460,vp.X-24)
 box.AnchorPoint=Vector2.new(.5,.5);box.Position=UDim2.fromScale(.5,.5);box.Size=UDim2.fromOffset(width,250)
 local buttonWidth=(width-52)/2
 keep.Position=UDim2.new(0,20,1,-62);keep.Size=UDim2.fromOffset(buttonWidth,46)
 wipe.Position=UDim2.new(1,-20-buttonWidth,1,-62);wipe.Size=UDim2.fromOffset(buttonWidth,46)
 keep.TextSize=width<400 and 14 or 17;wipe.TextSize=keep.TextSize
 title.TextSize=width<400 and 28 or 34;body.TextSize=width<400 and 15 or 17
end
fitReset()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()task.delay(.5,fitReset)end)
local function refreshBody()
	local n = player:GetAttribute("SquirrelsFound") or 0
	body.Text = string.format("Reset all %d squirrel%s you have found? Your acorns, purchases and Passport stamps stay. Your squirrel finds start at zero. This cannot be undone.", n, n == 1 and "" or "s")
end
local function close() shade.Visible = false; gui.DisplayOrder = 8 end
link.Activated:Connect(function() refreshBody(); gui.DisplayOrder = 100; shade.Visible = true end)
keep.Activated:Connect(close)
shade.Activated:Connect(close)
wipe.Activated:Connect(function()
	wipe.Text = "Resetting..."; wipe.AutoButtonColor = false
	if ev then ev:FireServer() end
	task.delay(1.5, function() wipe.Text = "Reset squirrels"; wipe.AutoButtonColor = true; close() end)
end)
if ev then
	ev.OnClientEvent:Connect(function()
		local done = Instance.new("TextLabel"); done.Size = UDim2.new(0, 420, 0, 54); done.Position = UDim2.new(0.5, -210, 0.24, 0); done.BackgroundColor3 = C(38, 30, 52)
		done.BackgroundTransparency = 0.15; done.Font = Enum.Font.FredokaOne; done.TextSize = 20; done.TextColor3 = C(255, 246, 220)
		done.Text = "Progress reset. Every squirrel is hidden again!"; done.ZIndex = 25; done.Parent = gui
		local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 14); dc.Parent = done
		task.delay(4, function() done:Destroy() end)
	end)
end
]====]})
for _,c in ipairs(changes)do assert(c.target.Source==c.before or c.target.Source==c.after,"Source changed: "..c.target:GetFullName());assert(loadstring(c.after))end
for _,c in ipairs(changes)do c.target.Source=c.after end
warn("QQ RETURNING INSTALL PASS: four scripts updated; all compile; unrelated draft preserved")
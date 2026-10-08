-- Pure, bounded data rules shared by the save owner, server and client.
local J={}
local catalogue=require(script.Parent.Catalogue)
J.byId={};for _,e in ipairs(catalogue) do J.byId[e.id]=e end
local keys={name=true,area=true,title=true,character=true,colour=true,flavours=true,hat=true,action=true,
 cs=true,previousBest=true,improvement=true,prize=true,seconds=true,boost=true,streak=true,baskets=true,shots=true,
 rank=true,scope=true,boardReady=true,run=true,keeperNo=true,historical=true,ongoing=true,visited=true,chute=true,
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
 elseif id=="boat" then return "Took the motorboat out from the jetty on the Rue and set off down the river."
 elseif id=="falls" then return "Went over the great waterfall at the end of the river, boat and all"..(d.chute and ", with the parachute on." or ", and landed in the pool with a splash!")
 elseif id=="chute" then return "Floated down to Porto Nocciola under the Sky Diving Squirrel's rainbow parachute."
 elseif id=="porto" then return "Arrived at Porto Nocciola, your first stop in Italy. Benvenuti!"
 elseif id=="keeper" then return "First to complete all 44 squirrels that day! Your statue joined the Keeper of the Great Acorn Hall of Fame."..((d.keeperNo or 0)>0 and " Keeper #"..d.keeperNo.."." or "") end
 return e.hint
end
return J
-- travel-passport v1 (Oct 1 2026)

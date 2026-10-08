-- Pure, bounded data rules shared by the save owner, server and client.
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

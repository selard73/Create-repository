local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local catalogue = require(F.Catalogue)
local Rules = require(F.Rules)
local award = RS:WaitForChild("AwardItems")
local activity = RS:WaitForChild("PassportActivity") -- BindableEvent: never client-callable
local allowed, states, queued = {}, {}, {}
for _, entry in ipairs(catalogue) do allowed[entry.id] = true end
local function item(p,id) return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function today()
 local daily = workspace:FindFirstChild("Daily")
 local offset = daily and daily:GetAttribute("DayOffsetHours") or 9
 return math.floor((os.time()-offset*3600)/86400)
end
local function mark(p,id)
 if not p or p.Parent ~= Players or not allowed[id] then return end
 local state = states[p]
 if not state then
  queued[p] = queued[p] or {}; queued[p][id] = true
  return
 end
 local changes = Rules.record(state,id,today(),allowed)
 if changes then for _, pair in ipairs(changes) do award:Fire(p,pair[1],pair[2]) end end
end
activity.Event:Connect(mark)
award.Event:Connect(function(p,id,n)
 if type(id) ~= "string" or type(n) ~= "number" or n <= 0 then return end
 local mapped = ({baskets="hoop",croc_rescues="rescue",gassy="cheese",bubbles="bubbles",daily_gold="gold",portrait="portrait"})[id]
 if id:match("^hatwear_") or id:match("^hat_") then mapped="hat" end
 if id:match("^q_round_") then mapped="riddle" end
 if mapped then mark(p,mapped) end
end)
local function watchCharacter(p,char)
 for attribute,id in pairs({Riding="zipline",Gliding="glider"}) do
  char:GetAttributeChangedSignal(attribute):Connect(function() if char:GetAttribute(attribute)==true then mark(p,id) end end)
 end
end
local function watch(p)
 if queued[p] == nil then queued[p] = {} end
 p.CharacterAdded:Connect(function(c) watchCharacter(p,c) end)
 if p.Character then watchCharacter(p,p.Character) end
 p:GetAttributeChangedSignal("CoffeeUntil"):Connect(function()
  if (p:GetAttribute("CoffeeUntil") or 0) > workspace:GetServerTimeNow() then mark(p,"coffee") end
 end)
 task.spawn(function()
  while p.Parent==Players and not p:GetAttribute("SaveLoaded") do task.wait(0.1) end
  if p.Parent~=Players then return end
  -- The squirrel total is set just after SaveLoaded; don't mistake loading for a new find.
  task.wait()
  if p.Parent~=Players then return end
  local state={stamps={},last=item(p,"passport_outing_last"),outings=item(p,"passport_outings")}
  for id in pairs(allowed) do state.stamps[id]=item(p,"passport_"..id) end
  states[p]=state
  -- Existing achievements get a permanent stamp, without counting as an activity today.
  local historic={rescue=item(p,"croc_rescues")>0,hoop=item(p,"baskets")>0,race=item(p,"race_best")>0,climb=item(p,"climb_best")>0,find=(p:GetAttribute("SquirrelsFound") or 0)>0,gold=item(p,"daily_gold")>0,riddle=item(p,"q_round_forest")>0}
  for k,v in pairs(p:GetAttributes()) do if k:match("^Item_hat_") and type(v)=="number" and v>0 then historic.hat=true end end
  for id,done in pairs(historic) do if done and state.stamps[id]==0 then state.stamps[id]=1; award:Fire(p,"passport_"..id,1) end end
  local count=p:GetAttribute("SquirrelsFound") or 0
  p:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
   local nextCount=p:GetAttribute("SquirrelsFound") or 0
   if nextCount>count then mark(p,"find") end
   count=nextCount
  end)
  local waiting=queued[p]; queued[p]=nil
  if waiting then for id in pairs(waiting) do mark(p,id) end end
  p:SetAttribute("PassportReady",true)
 end)
end
Players.PlayerAdded:Connect(watch)
for _,p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) states[p]=nil;queued[p]=nil end)
print("Passport: 17 activity stamps; daily outings; existing save ledger")

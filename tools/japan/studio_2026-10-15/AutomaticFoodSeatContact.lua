-- Sit automatically on contact; a brief shared cooldown prevents immediate re-seating.
local Players=game:GetService("Players")
local model=script.Parent
local seats={}
local previous={}
local busy={}
local COOLDOWN_ATTRIBUTE="JapanFoodSeatReadyAt"
local EXIT_DELAY=3
local function playerFromHit(hit)
 local ancestor=hit
 while ancestor and ancestor~=workspace do
  if ancestor:IsA("Model") then
   local h=ancestor:FindFirstChildOfClass("Humanoid")
   if h then return Players:GetPlayerFromCharacter(ancestor),h end
  end
  ancestor=ancestor.Parent
 end
end
for _,seat in ipairs(model:GetChildren())do
 if seat:IsA("Seat")and seat:GetAttribute("FoodSeatGroup")then
  table.insert(seats,seat)
  previous[seat]=seat.Occupant
  seat:GetPropertyChangedSignal("Occupant"):Connect(function()
   local before=previous[seat];local after=seat.Occupant;previous[seat]=after
   if before and before~=after then
    local player=before.Parent and Players:GetPlayerFromCharacter(before.Parent)
    if player then player:SetAttribute(COOLDOWN_ATTRIBUTE,workspace:GetServerTimeNow()+EXIT_DELAY)end
   end
  end)
 end
end
local function onTouch(surface,hit)
 local player,humanoid=playerFromHit(hit)
 if not player or player.UserId~=9611145467 or busy[player]then return end
 if humanoid.Health<=0 or humanoid.SeatPart or humanoid.Sit then return end
 if workspace:GetServerTimeNow()<(player:GetAttribute(COOLDOWN_ATTRIBUTE)or 0)then return end
 local root=humanoid.Parent:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local group=surface:GetAttribute("FoodSeatGroup")
 local selected;local closest=8
 for _,seat in ipairs(seats)do
  if not seat.Occupant and seat:GetAttribute("FoodSeatGroup")==group then
   local distance=(root.Position-seat.Position).Magnitude
   if distance<closest then closest=distance;selected=seat end
  end
 end
 if not selected then return end
 busy[player]=true
 selected:Sit(humanoid)
 task.delay(.25,function()busy[player]=nil end)
end
for _,part in ipairs(model:GetDescendants())do
 if part:IsA("BasePart")and not part:IsA("Seat")and part:GetAttribute("FoodSeatGroup")then
  part.Touched:Connect(function(hit)onTouch(part,hit)end)
 end
end
Players.PlayerRemoving:Connect(function(player)busy[player]=nil end)
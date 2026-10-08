local rail=script.Parent
local RunService=game:GetService('RunService')
local A,B=rail:GetAttribute('Bottom'),rail:GetAttribute('Top')
local direction=Vector3.new(B.X-A.X,0,B.Z-A.Z).Unit
local right=Vector3.new(-direction.Z,0,direction.X)
local rotation=CFrame.lookAt(Vector3.zero,direction).Rotation
local cars=rail.Cars:GetChildren()
-- Oct 4 2026 (Shannon): locked until the player has found all 15 harbour squirrels (Found_porto, set by SquirrelSetup).
-- The owner may always ride (testing); set the rail attribute NoOwnerBypass=true to try the lock as her.
-- A turned-away player gets RS.FunicularLocked; TonioTalk makes Tonio explain (and stands them up if seated).
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local NEED=15
local lockEv=RS:FindFirstChild('FunicularLocked') or Instance.new('RemoteEvent')
lockEv.Name='FunicularLocked' lockEv.Parent=RS
local function mayRide(player)
 if player.UserId==game.CreatorId and not rail:GetAttribute('NoOwnerBypass') then return true end
 return (player:GetAttribute('Found_porto') or 0)>=NEED
end
local lastNote={}
local function refuse(player)
 local t=os.clock()
 if t-(lastNote[player] or 0)<3 then return end
 lastNote[player]=t
 lockEv:FireClient(player)
end
Players.PlayerRemoving:Connect(function(p) lastNote[p]=nil end)
local dwell,travel=12,34
local started=os.clock()
for _,car in ipairs(cars) do
 for _,seat in ipairs(car:GetDescendants()) do if seat:IsA('Seat') then
  seat.Board.Triggered:Connect(function(player)
   if not mayRide(player) then refuse(player) return end
   local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local root=c and c:FindFirstChild('HumanoidRootPart')
   if car:GetAttribute('Docked') and h and root and h.Health>0 and not seat.Occupant and (root.Position-seat.Position).Magnitude<=12 then seat:Sit(h) end
  end)
  seat:GetPropertyChangedSignal('Occupant'):Connect(function()
   local h=seat.Occupant
   local player=h and Players:GetPlayerFromCharacter(h.Parent)
   if player and not mayRide(player) then
    task.defer(function() local w=seat:FindFirstChild('SeatWeld') if w then w:Destroy() end end)
    lockEv:FireClient(player)
   end
  end)
 end end
end
RunService.Heartbeat:Connect(function()
 local phase=(os.clock()-started)%(2*(dwell+travel));local alpha,docked
 if phase<dwell then alpha=0;docked=true
 elseif phase<dwell+travel then alpha=(phase-dwell)/travel;docked=false
 elseif phase<2*dwell+travel then alpha=1;docked=true
 else alpha=1-(phase-2*dwell-travel)/travel;docked=false end
 for _,car in ipairs(cars) do
  local f=car.Name=='Car_Rosso' and alpha or 1-alpha
  car:PivotTo(CFrame.new(A:Lerp(B,f)+right*car:GetAttribute('Offset'))*rotation)
  if car:GetAttribute('Docked')~=docked then
   car:SetAttribute('Docked',docked)
   for _,d in ipairs(car:GetDescendants()) do if d:IsA('ProximityPrompt') then d.Enabled=docked end end
  end
 end
 rail:SetAttribute('TravelAlpha',alpha)
end)
print('Porto funicular ready: two cars, bottom/top stops, eight passenger seats')

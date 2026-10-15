-- Local district travel. Photo-directed Shinkansen with a usable passenger cabin.
local map=script.Parent
-- JAPANFIX1_20261015: the preview module is optional - without it nobody may enter Japan and this script still runs
local PreviewAccess
do
	local m=game.ServerScriptService:FindFirstChild("JapanPreviewAccess")
	local ok, mod=false, nil
	if m then ok, mod=pcall(require, m) end
	PreviewAccess=(ok and type(mod) == "table") and mod or {IsAllowed = function() return false end, IsJapan = function() return false end, CanUsePrompt = function() return false end}
end
local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local train=map.Railway['Indigo bullet train']
local seat=train.JapanPassengerSeat
seat.Disabled=true
local stations={}
for _,s in ipairs(map.Railway:GetChildren())do
 local point=s:FindFirstChild('BoardingPoint')
 if point then stations[point:GetAttribute('StationIndex')]=point end
end
local cabin=train:FindFirstChild('Passenger cabin controls')
local ridePrompt=cabin and cabin.RideControl.JapanInsideRidePrompt
local exitPrompt=cabin and cabin.ExitControl.JapanTrainExitPrompt
local door=train:FindFirstChild('ST_SlidingDoor_Platform')
local blocker=cabin and cabin.PlatformDoorCollision
local busy=false
local function openDoor(open,animate)
 if not door then return end
 local cf=train:GetPivot()*(open and door:GetAttribute('OpenOffset')or door:GetAttribute('ClosedOffset'))
 if animate then TweenService:Create(door,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{CFrame=cf}):Play()
 else door.CFrame=cf end
 if blocker then blocker.CanCollide=not open end
 train:SetAttribute('DoorsOpen',open)
end
local function enablePrompts(enabled)
 for _,point in ipairs(stations)do point.JapanTrainPrompt.Enabled=enabled end
 if ridePrompt then ridePrompt.Enabled=enabled end
 if exitPrompt then exitPrompt.Enabled=enabled end
end
local function inside(character)
 local hrp=character and character:FindFirstChild('HumanoidRootPart')
 if not hrp then return false end
 local q=train:GetPivot():PointToObjectSpace(hrp.Position)
 return math.abs(q.X)<12.2 and math.abs(q.Z)<4.9 and q.Y>3 and q.Y<10.8
end
local function leave(character,point)
 local hrp=character and character:FindFirstChild('HumanoidRootPart')
 if hrp then character:PivotTo(CFrame.new(point.Position+Vector3.new(0,4,-6)));hrp.AssemblyLinearVelocity=Vector3.zero;hrp.AssemblyAngularVelocity=Vector3.zero end
end
local function ride(index,player)
 if not PreviewAccess.IsAllowed(player) then return end
 local point=stations[index];local destination=stations[index%#stations+1]
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 local hrp=character and character:FindFirstChild('HumanoidRootPart')
 if busy or not point or not hrp or not humanoid or humanoid.Health<=0 then return end
 if (hrp.Position-point.Position).Magnitude>20 and not(inside(character)and train:GetAttribute('StationIndex')==index)then return end
 local origin=map:GetAttribute('Origin')
 if typeof(origin)~='Vector3' then warn('Japan train: JapanMap has no Origin attribute') return end   -- (JAPANFIX1: checked before the train is marked busy)
 busy=true;train:SetAttribute('InTransit',true);enablePrompts(false)
 local couldJump=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
 local start=CFrame.new(point.Position.X,0,origin.Z+181)
 local finish=CFrame.new(destination.Position.X,0,origin.Z+181)
 local ok,err=xpcall(function()
  openDoor(false,true);task.wait(.5)
  train:PivotTo(start)
  seat.Disabled=false
  character:PivotTo(seat.CFrame*CFrame.new(0,2.5,0))
  humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
  seat:Sit(humanoid)
  task.wait(.5)
  assert(seat.Occupant==humanoid,'Passenger could not be seated')
  local elapsed=0
  local duration=math.max(8,math.abs(finish.X-start.X)/45)
  while elapsed<duration and character.Parent and humanoid.Health>0 do
   elapsed+=RunService.Heartbeat:Wait()
   local t=math.clamp(elapsed/duration,0,1)
   train:PivotTo(start:Lerp(finish,t*t*(3-2*t)))
  end
  train:PivotTo(finish)
  train:SetAttribute('StationIndex',index%#stations+1)
 end,debug.traceback)
 seat.Disabled=true;humanoid.Sit=false
 local weld=seat:FindFirstChild('SeatWeld');if weld then weld:Destroy()end
 task.wait(.2)
 humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,couldJump)
 local arrived=stations[train:GetAttribute('StationIndex')or index]
 if character.Parent and humanoid.Health>0 then leave(character,arrived);humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end
 openDoor(true,true);train:SetAttribute('InTransit',false)
 enablePrompts(true);busy=false
 if ridePrompt then ridePrompt.ActionText='Ride to '..stations[(train:GetAttribute('StationIndex')or 2)%#stations+1].Parent.Name:gsub(' station','')end
 if not ok then warn('Japan train: '..tostring(err))end
end
for index,point in ipairs(stations)do
 point.JapanTrainPrompt.ActionText='Ride to '..stations[index%#stations+1].Parent.Name:gsub(' station','')
 point.JapanTrainPrompt.Triggered:Connect(function(player)ride(index,player)end)
end
if ridePrompt then
 ridePrompt.ActionText='Ride to '..stations[(train:GetAttribute('StationIndex')or 2)%#stations+1].Parent.Name:gsub(' station','')
 ridePrompt.Triggered:Connect(function(player)if inside(player.Character)then ride(train:GetAttribute('StationIndex')or 2,player)end end)
end
if exitPrompt then exitPrompt.Triggered:Connect(function(player)
 if PreviewAccess.IsAllowed(player) and not busy and inside(player.Character)then leave(player.Character,stations[train:GetAttribute('StationIndex')or 2])end
end)end
train:SetAttribute('InTransit',false);openDoor(true,false)

-- Low, spatial rumble with restrained smoke pulses.
local vent=map.MountainBackdrop['Rumbling volcano']['Volcano crater']
task.spawn(function()
 task.wait(4)
 while map.Parent do
  vent.VolcanoRumble:Play()
  vent['Volcanic plume'].Opacity=.32
  task.wait(5)
  vent['Volcanic plume'].Opacity=.2
  task.wait(19)
 end
end)
-- Arrival links, populated by the installer after surveying the existing travel area.
for _,p in ipairs(map:GetDescendants()) do
 if p:IsA('ProximityPrompt') and p.Name=='JapanAirportPrompt' then
  p.Triggered:Connect(function(player)
   if not PreviewAccess.CanUsePrompt(player,p,22) then return end
   if player:GetAttribute("JapanPreviewInFlight") then return end
   local character=player.Character;local hrp=character and character:FindFirstChild('HumanoidRootPart')
   local target=p:GetAttribute('Destination')
   if hrp and typeof(target)=='Vector3' and (hrp.Position-p.Parent.Position).Magnitude<22 then
    pcall(player.RequestStreamAroundAsync,player,target,5)   -- (JAPANFIX1: the ground loads before the 5,700-stud hop, as TravelServer does)
    if not (player.Parent and player.Character==character and hrp.Parent) then return end
    character:PivotTo(CFrame.new(target+Vector3.new(0,4,0)))
    hrp.AssemblyLinearVelocity=Vector3.zero
   end
  end)
 end
end
print('JAPAN_RUNTIME_OK: train, airport links and volcano active')


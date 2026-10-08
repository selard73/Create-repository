-- fl1 Oct 4 2026: funicular locked until 15 harbour squirrels (Shannon's yes). Backs up the old ride script first.
local srv=workspace.PortoNocciola['15 Funicolare'].FunicularServer
local OLD=[==[local rail=script.Parent
local RunService=game:GetService('RunService')
local A,B=rail:GetAttribute('Bottom'),rail:GetAttribute('Top')
local direction=Vector3.new(B.X-A.X,0,B.Z-A.Z).Unit
local right=Vector3.new(-direction.Z,0,direction.X)
local rotation=CFrame.lookAt(Vector3.zero,direction).Rotation
local cars=rail.Cars:GetChildren()
local dwell,travel=12,34
local started=os.clock()
for _,car in ipairs(cars) do
 for _,seat in ipairs(car:GetDescendants()) do if seat:IsA('Seat') then
  seat.Board.Triggered:Connect(function(player)
   local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local root=c and c:FindFirstChild('HumanoidRootPart')
   if car:GetAttribute('Docked') and h and root and h.Health>0 and not seat.Occupant and (root.Position-seat.Position).Magnitude<=12 then seat:Sit(h) end
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
]==]
local NEW=[==[local rail=script.Parent
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
]==]
local function trim(s) return (s:gsub('%s+$','')) end
if trim(srv.Source)~=trim(OLD) then warn('QY@STOP live FunicularServer differs from SRV.lua',#srv.Source,#OLD) return end
local bk=game.ServerStorage:FindFirstChild('FunicularBackup') or Instance.new('Folder',game.ServerStorage)
bk.Name='FunicularBackup'
if not bk:FindFirstChild('FunicularServer_v1025') then local c=srv:Clone() c.Name='FunicularServer_v1025' c.Disabled=true c.Parent=bk end
srv.Source=NEW
local SPS=game.StarterPlayer.StarterPlayerScripts
local tt=SPS:FindFirstChild('TonioTalk')
if not tt then warn('QY@STOP no TonioTalk') return end
if not bk:FindFirstChild('TonioTalk_v1025') then local c=tt:Clone() c.Name='TonioTalk_v1025' c.Disabled=true c.Parent=bk end
tt.Source=[==[-- TonioTalk (StarterPlayerScripts, Oct 4 2026, Shannon): after you tag Tonio the Conductor he speaks - "Please come back and
-- ride when you have found all 15 squirrels in the harbor", or, once you have found 15 harbour squirrels, something else.
-- Spoken through the SquirrelBubble like every squirrel. He says it when you tag him (just after the reveal), and again
-- when you walk back up to him later (at most once a minute), so a returning player still hears where they stand.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local ID = "conductor_squirrel"
local NEED = 15
local NOT_YET = "Please come back and ride when you have found all 15 squirrels in the harbor."
local READY = "Bravo! All 15 harbour squirrels found. All aboard the funicolare - mind the step!"
local okB, Bubble = pcall(function() return require(RS:WaitForChild("SquirrelBubble", 20)) end)

local function tonio() return workspace:FindFirstChild(ID .. "_color") end
local function found() return (player:GetAttribute("FoundIds") or ""):find(ID, 1, true) ~= nil end
local lastSaid = 0
local function speak()
	local m = tonio()
	if not (m and okB) then return end
	lastSaid = os.clock()
	local n = player:GetAttribute("Found_porto") or 0
	pcall(Bubble.say, m, n >= NEED and READY or NOT_YET, {secs = 4.5})
end

-- the funicular turned this player away (FunicularServer, under 15 harbour squirrels): anyone sitting gets up again,
-- and Tonio explains (at most every 3 seconds, so pressing Board again and again does not spam him)
task.spawn(function()
	local lockEv = RS:WaitForChild("FunicularLocked", 60)
	if not lockEv then return end
	lockEv.OnClientEvent:Connect(function()
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h and h.Sit then h.Sit = false h.Jump = true end
		if os.clock() - lastSaid > 3 then speak() end
	end)
end)

-- tagged: the server tells this player which squirrel they just found
local ev = RS:WaitForChild("SquirrelFound", 30)
if ev then
	ev.OnClientEvent:Connect(function(id)
		if id == ID then task.delay(1.4, speak) end          -- after the ding and the colour reveal
	end)
end

-- walking back up to him once he is yours
local near = false
while true do
	task.wait(0.4)
	local m = tonio()
	local cm = m and m:FindFirstChild("Squirrel")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if cm and hrp and found() then
		local close = (cm.Position - hrp.Position).Magnitude < 10
		if close and not near and os.clock() - lastSaid > 60 then speak() end
		near = close
	else
		near = false
	end
end
]==]
game:GetService('ChangeHistoryService'):SetWaypoint('FunicularLock')
warn('QY@OK fl1',#srv.Source,#tt.Source)

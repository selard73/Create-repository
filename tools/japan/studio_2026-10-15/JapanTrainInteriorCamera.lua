-- Uses an inside view while walking or riding in the Japan passenger cabin.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
local savedMode
local function restore()
 if savedMode then player.CameraMode=savedMode;savedMode=nil end
end
local function inside()
 local character=player.Character
 local h=character and character:FindFirstChildOfClass('Humanoid')
 local hrp=character and character:FindFirstChild('HumanoidRootPart')
 local map=workspace:FindFirstChild('JapanMap')
 local railway=map and map:FindFirstChild('Railway')
 local train=railway and railway:FindFirstChild('Indigo bullet train')
 if not h or h.Health<=0 or not hrp or not train then return false end
 if h.SeatPart and h.SeatPart.Name=='JapanPassengerSeat'and h.SeatPart:IsDescendantOf(train)then return true end
 local p=train:GetPivot():PointToObjectSpace(hrp.Position)
 return math.abs(p.X)<11.7 and math.abs(p.Z)<4.45 and p.Y>3.1 and p.Y<10.4
end
local elapsed=0
local connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 if inside()then
  if not savedMode then savedMode=player.CameraMode;player.CameraMode=Enum.CameraMode.LockFirstPerson end
 else restore()end
end)
player.CharacterAdded:Connect(restore)
script.Destroying:Connect(function()connection:Disconnect();restore()end)


-- Brief fade with a local floor/readiness check. No loading UI remains after failure.
local Players=game:GetService("Players")
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local bridge=game:GetService("ReplicatedStorage"):WaitForChild("CafeInterior2Link")
local event=bridge:WaitForChild("Transition")
local room=workspace:WaitForChild("JapanMap"):WaitForChild("ShopFronts"):WaitForChild("CatCafeInterior")
local frame=bridge:GetAttribute("RoomFrame")
local pg=player:WaitForChild("PlayerGui")
-- A refreshed preview script must not leave a prior fade overlay behind.
for _,old in ipairs(pg:GetChildren())do if old:IsA("ScreenGui")and old.Name=="CafeDoorwayFade"then old:Destroy()end end
local gui=Instance.new("ScreenGui");gui.Name="CafeDoorwayFade";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=10000;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.ScreenInsets=Enum.ScreenInsets.None;gui.ClipToDeviceSafeArea=false
local shade=Instance.new("Frame");shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.fromRGB(28,24,21);shade.BackgroundTransparency=1;shade.BorderSizePixel=0;shade.Parent=gui
gui.Parent=pg
-- Same door bell and volume as the French Bookshop, HatShop and DressShop.
local doorBell=Instance.new("Sound");doorBell.Name="CafeDoorBell"
doorBell.SoundId=bridge:GetAttribute("DoorSound")or"rbxassetid://131845870598154"
doorBell.Volume=bridge:GetAttribute("DoorVolume")or .6;doorBell.PlaybackSpeed=1;doorBell.Looped=false;doorBell.Parent=gui
task.spawn(function()pcall(function()game:GetService("ContentProvider"):PreloadAsync({doorBell})end)end)
local pending;local visible=nil;local runningTween;local alive=true
local function fade(value)
 if runningTween then runningTween:Cancel()end
 runningTween=Tween:Create(shade,TweenInfo.new(.25,Enum.EasingStyle.Quad),{BackgroundTransparency=value});runningTween:Play()
 return runningTween
end
local function showRoom(show)
 if visible==show then return end;visible=show
 for _,p in ipairs(room:GetDescendants())do if p:IsA("BasePart")then p.LocalTransparencyModifier=show and 0 or 1 end end
end
local descendant=room.DescendantAdded:Connect(function(p)
 if p:IsA("BasePart")then p.LocalTransparencyModifier=visible and 0 or 1 end
end)
local visibility=Run.Heartbeat:Connect(function()
 local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart")
 local near=r and math.abs(r.Position.Y-frame.Position.Y)<30
 showRoom(near or pending and pending.inside or false)
end)
local receive=event.OnClientEvent:Connect(function(action,token,inside,target)
 if action=="FadeOut"then
  pending={token=token,inside=inside};local this=pending
  fade(0).Completed:Wait()
  if pending~=this then return end
  event:FireServer("Faded",token)
  task.delay(12,function()if alive and pending==this then event:FireServer("Abort",token);pending=nil;fade(1)end end)
 elseif action=="Arrived"then
  if not pending or pending.token~=token then return end
  local this=pending;local ready=false;local deadline=os.clock()+4
  repeat
   local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
   if root and (root.Position-target).Magnitude<3 then
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.RespectCanCollide=true
    local hit=workspace:Raycast(root.Position+Vector3.new(0,1,0),Vector3.new(0,-12,0),params)
    ready=hit~=nil and (not inside or hit.Instance:IsDescendantOf(room))
    if ready then
     local cam=workspace.CurrentCamera
     if cam then cam.CameraType=Enum.CameraType.Custom;cam.CameraSubject=char:FindFirstChildOfClass("Humanoid");cam.CFrame=CFrame.lookAt(root.Position-root.CFrame.LookVector*4.5+Vector3.new(0,2.5,0),root.Position+Vector3.new(0,1.2,0))end
     break
    end
   end
   task.wait(.05)
  until os.clock()>deadline or pending~=this or not alive
  if pending==this then event:FireServer(ready and "Ready"or"Abort",token)end
 elseif action=="FadeIn"or action=="Abort"then
  if pending and pending.token==token then
   pending=nil
   if action=="FadeIn"then doorBell:Stop();doorBell.TimePosition=0;doorBell:Play()end
   fade(1)
  end
 end
end)
local removing=player.CharacterRemoving:Connect(function()if pending then event:FireServer("Abort",pending.token)end;pending=nil;fade(1)end)
script.Destroying:Connect(function()
 alive=false;receive:Disconnect();visibility:Disconnect();descendant:Disconnect();removing:Disconnect()
 if pending then event:FireServer("Abort",pending.token)end
 if runningTween then runningTween:Cancel()end
 for _,p in ipairs(room:GetDescendants())do if p:IsA("BasePart")then p.LocalTransparencyModifier=0 end end
 gui:Destroy()
end)

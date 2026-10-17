-- Same-server doorway transition. Only the server detects doors and chooses destinations.
-- Client messages can acknowledge an active transition; they cannot request coordinates.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local bridge=game:GetService("ReplicatedStorage"):WaitForChild("CafeInterior2Link")
local event=bridge:WaitForChild("Transition")
local room=workspace.JapanMap.ShopFronts:WaitForChild("CatCafeInterior")
local streetFrame=bridge:GetAttribute("StreetFrame")
local roomFrame=bridge:GetAttribute("RoomFrame")
local active={};local cooldown={};local serial=0;local alive=true
local function character(player)
 local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
 if c and h and r and h.Health>0 then return c,h,r end
end
local entryPrompt=workspace.JapanMap.ShopFronts.CatCafe:WaitForChild("EntranceDoor"):WaitForChild("Door_Reveal"):WaitForChild("DoorInteraction"):WaitForChild("EnterCafe")
local exitPrompt=room:WaitForChild("ExitDoor"):WaitForChild("Door_Reveal"):WaitForChild("DoorInteraction"):WaitForChild("ExitCafe")
local function canUseDoor(root,inside)
 local prompt=inside and entryPrompt or exitPrompt
 if not prompt.Enabled or (root.Position-prompt.Parent.WorldPosition).Magnitude>8.5 then return false end
 local q=(inside and streetFrame or roomFrame):PointToObjectSpace(root.Position)
 local x=inside and -9.36 or -11
 return math.abs(q.X-x)<4.5 and q.Y>-.5 and q.Y<8 and (inside and q.Z>=-.3 and q.Z<8 or not inside and q.Z<.3 and q.Z> -8)
end
local function send(player,...)
 if player.Parent==Players then event:FireClient(player,...)end
end
local function finish(player,success,reason)
 local s=active[player];if not s then return end
 active[player]=nil;cooldown[player]=os.clock()+2
 -- Cleanup must also release a dead or recently replaced character's root.
 if s.root.Parent then
  if not success and s.moved and s.char.Parent then s.char:PivotTo(s.originalPivot)end
  s.root.AssemblyLinearVelocity=Vector3.zero;s.root.AssemblyAngularVelocity=Vector3.zero;s.root.Anchored=s.wasAnchored
 end
 if success then player:SetAttribute("InCatCafeInterior",s.inside)end
 send(player,success and "FadeIn"or"Abort",s.token,reason)
end
local function begin(player,inside)
 local c,h,r=character(player)
 if not c or active[player] or os.clock()<(cooldown[player]or 0) or r.Anchored or h.SeatPart or h.Sit or not canUseDoor(r,inside) then return end
 serial+=1
 active[player]={char=c,root=r,token=serial,inside=inside,phase="Fading",deadline=os.clock()+10,wasAnchored=r.Anchored,originalPivot=c:GetPivot(),moved=false}
 r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;r.Anchored=true
 send(player,"FadeOut",serial,inside)
end
local connection=event.OnServerEvent:Connect(function(player,action,token)
 local s=active[player]
 if not s or type(token)~="number" or token~=s.token then return end
 local c,h,r=character(player)
 if c~=s.char or r~=s.root then finish(player,false,"Character changed");return end
 if action=="Ready" and s.phase=="Arrived" then finish(player,true);return end
 if action=="Abort"then finish(player,false,"Doorway is not ready. Please try again.");return end
 if action~="Faded"or s.phase~="Fading"then return end
 s.phase="Loading"
 local cf=s.inside and roomFrame or streetFrame
 local localPos=s.inside and Vector3.new(-11,0,-5.2) or Vector3.new(-9.36,-.5798532,3.0)
 local ground=cf:PointToWorldSpace(localPos)
 local target=ground+Vector3.new(0,h.HipHeight+r.Size.Y/2+.12,0)
 local look=cf:VectorToWorldSpace(s.inside and Vector3.new(0,0,-1)or Vector3.new(0,0,1))
 local ok,err=pcall(function()
  player:RequestStreamAroundAsync(target,3)
  if not alive or active[player]~=s then return end
  local nowChar,nowHum,nowRoot=character(player)
  if nowChar~=c or nowRoot~=r then error("Character changed")end
  -- Preserve the character pivot offset while positioning the root exactly.
  local desired=CFrame.lookAt(target,target+look)
  c:PivotTo(desired*r.CFrame:ToObjectSpace(c:GetPivot()));s.moved=true
  r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
  s.phase="Arrived";send(player,"Arrived",s.token,s.inside,target)
 end)
 if not ok then warn("Cafe doorway transition interrupted: "..tostring(err));finish(player,false,"Doorway is not ready. Please try again.")end
end)
local removed=Players.PlayerRemoving:Connect(function(p)
 local s=active[p];if s and s.root.Parent then s.root.Anchored=s.wasAnchored end
 active[p]=nil;cooldown[p]=nil
end)
-- A prompt press is the only way to begin. Walking into either door never starts a transition.
local entryConnection=entryPrompt.Triggered:Connect(function(p)begin(p,true)end)
local exitConnection=exitPrompt.Triggered:Connect(function(p)begin(p,false)end)
task.spawn(function()
 while alive and script.Parent do
  local now=os.clock()
  for _,p in ipairs(Players:GetPlayers())do
   local s=active[p]
   if s then
    local c=character(p)
    if c~=s.char or now>s.deadline then finish(p,false,"Doorway is not ready. Please try again.")end
   else
    local c,h,r=character(p)
    if r and p:GetAttribute("InCatCafeInterior") and math.abs(r.Position.Y-roomFrame.Position.Y)>30 then p:SetAttribute("InCatCafeInterior",false)end
   end
  end
  task.wait(.1)
 end
end)
script.Destroying:Connect(function()
 alive=false;connection:Disconnect();removed:Disconnect();entryConnection:Disconnect();exitConnection:Disconnect()
 local list={};for p in pairs(active)do table.insert(list,p)end
 for _,p in ipairs(list)do finish(p,false,"Doorway refreshed")end
end)

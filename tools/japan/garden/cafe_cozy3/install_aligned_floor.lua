-- Preview first; permanent Edit application requires Shannon's approval.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and CAFEFLOOR4_ALLOW_EDIT==true),"Preview first; Edit needs approval")
local room=assert(workspace.JapanMap.ShopFronts:FindFirstChild("CatCafeInterior"))
assert(room:GetAttribute("CafeCozyVersion")=="cozy3","Expected cozy3 cafe")
local saved={}
for _,root in ipairs({room,workspace.JapanMap.ShopFronts.CatCafe})do for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")and not(p.Parent and p.Parent.Name=="AlignedFloorBoards")then
 saved[p]={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,variant=p.MaterialVariant,transparency=p.Transparency,collide=p.CanCollide,touch=p.CanTouch,query=p.CanQuery,anchored=p.Anchored,mesh=p:IsA("MeshPart")and p.MeshId or nil}
end end end
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("Before lengthwise cafe floor")end
-- Reuse the imported box mesh so its material X axis follows each board's length.
-- The original batched floor meshes remain as the unchanged physical floor.
do
 local arch=room.Architecture
 local frame=game.ReplicatedStorage.CafeInterior2Link:GetAttribute("RoomFrame")
 assert(typeof(frame)=="CFrame","Missing cafe room frame")
 local source=arch:FindFirstChild("CI2_VestibuleFloor_Oak")
 assert(source and source:IsA("MeshPart")and source.MeshId=="rbxassetid://95928484054291","Expected imported floor mesh")
 local group=Instance.new("Model");group.Name="AlignedFloorBoards"
 group:SetAttribute("CafeFloorVisualVersion","lengthwise_walnut4")
 local colors={Color3.fromRGB(108,78,53),Color3.fromRGB(113,83,57),Color3.fromRGB(102,73,49)}
 local function board(name,size,cf,color)
  local p=source:Clone();p:ClearAllChildren();p.Name=name
  for k in pairs(p:GetAttributes())do p:SetAttribute(k,nil)end
  p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.Wood;p.MaterialVariant=""
  p.Transparency=0;p.Reflectance=0;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true;p.Parent=group
 end
 for i=0,33 do for j=0,6 do
  board(string.format("WalnutBoard_%02d_%02d",i,j),Vector3.new(3.98,.13,.975),frame*CFrame.new(-16.5+i,-.065,-2-4*j)*CFrame.Angles(0,math.pi/2,0),colors[((i*7+j*3)%11)%3+1])
 end end
 board("WalnutVestibule",Vector3.new(2.8,.13,6.4),frame*CFrame.new(-11,-.065,1.4)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(106,76,52))
 assert(#group:GetChildren()==239,"Expected 238 boards and one vestibule mesh")
 local old=room:FindFirstChild(group.Name)
 if old then assert(old:GetAttribute("CafeFloorVisualVersion")=="lengthwise_walnut4","Unrecognized floor model");old:Destroy()end
 group.Parent=room
 for _,name in ipairs({"CI2_Floor_Oak","CI2_Floor_OakLight","CI2_Floor_OakDark","CI2_VestibuleFloor_Oak"})do
  local p=assert(arch:FindFirstChild(name));p.Transparency=1
  local grain=p:FindFirstChild("CafeSoftWoodGrain");if grain then grain:Destroy()end
 end
 room:SetAttribute("CafeFloorFinish","lengthwise_walnut4")
 print("QQ CAFE FLOOR GRAIN: 238 reused real mesh boards plus vestibule; grain follows board length; original physical floor retained")
end

local bridge=game.ReplicatedStorage.CafeInterior2Link
local old=bridge:FindFirstChild("CafeFloorReflectionClient");if old then old:Destroy()end
local client=Instance.new("Script");client.Name="CafeFloorReflectionClient";client.RunContext=Enum.RunContext.Client
client.Source=[====[-- Cafe-local reflection control. Capture on entry and restore on exit/cleanup.
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local previous=nil
local function update()
 if player:GetAttribute("InCatCafeInterior")==true then
  if previous==nil then previous=Lighting.EnvironmentSpecularScale end
  Lighting.EnvironmentSpecularScale=.12
 elseif previous~=nil then
  Lighting.EnvironmentSpecularScale=previous;previous=nil
 end
end
local connection=player:GetAttributeChangedSignal("InCatCafeInterior"):Connect(update)
script.Destroying:Connect(function()
 connection:Disconnect()
 if previous~=nil then Lighting.EnvironmentSpecularScale=previous;previous=nil end
end)
update()
]====];client.Parent=bridge
local count=0
for p,b in pairs(saved)do
 assert(p.Parent and p.CFrame==b.cf and p.Size==b.size and p.Color==b.color and p.Material==b.material and p.MaterialVariant==b.variant and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query and p.Anchored==b.anchored,"Existing cafe part changed: "..p.Name)
 if b.mesh then assert(p.MeshId==b.mesh,"Original mesh changed")end
 if p.Transparency~=b.transparency then assert(p.Parent==room.Architecture and p.Name:find("Floor")and p.Name~="CI2_FloorBase_OakDark"and p.Transparency==1,"Unexpected hidden part")end
 count+=1
end
assert(count==371,"Expected all371 original cafe parts")
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After lengthwise cafe floor")end
print("QQ CAFE FLOOR CHECK: all371 original parts retain transforms, colors, materials, mesh IDs and physical flags; four old visual surfaces hidden")
print("QQ CAFE FLOOR REFLECTION: client sky reflection .12 only inside cafe; prior value restored on exit; no server lighting change")
print("QQ CAFE FLOOR STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")

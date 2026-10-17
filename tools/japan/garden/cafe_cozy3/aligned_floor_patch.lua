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

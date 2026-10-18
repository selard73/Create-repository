-- One north-wall treatment. Play Server first; saved Edit only after Shannon's picture approval.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or (not Run:IsRunning() and CAFE_SIDES1_ALLOW_EDIT==true),"Preview first; Edit requires approval")
local J=workspace.JapanMap
local shop=J["Outdoor market revision"]["Cat cafe"]
local kit=game.ServerStorage.JapanGardenKit
assert(not shop:FindFirstChild("CafeSideDetails1") and not shop:GetAttribute("SideDetailsVersion"),"Side detail already present; inspect before changing")
local wall
for _,p in shop:GetChildren() do
 if p:IsA("BasePart") and p.Name=="Side wall" and math.abs(p.Position.Z-20)<.01 then wall=p end
end
assert(wall and math.abs(wall.Position.X-6024)<.01 and math.abs(wall.Size.Z-20)<.01 and wall.CanCollide,"North wall changed")
local upper
for _,p in shop["Traditional downtown facade"]:GetChildren() do
 if p:IsA("BasePart") and p.Name=="Upper timber side wall" and math.abs(p.Position.Z-20)<.01 then upper=p end
end
assert(upper and math.abs(upper.Position.Y-14.65)<.01 and math.abs(upper.Size.X-.35)<.001,"Upper wall changed")
local floorTop=shop["Shop floor"].Position.Y+shop["Shop floor"].Size.Y/2
assert(math.abs(floorTop-1.039853179)<.001,"Floor changed")
local sources={back_door2=5,back_window2=5,awning_section=2}
for n,count in pairs(sources) do
 local m=assert(kit:FindFirstChild(n),"Missing source "..n);local c=0
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then assert(p:IsA("MeshPart") and p.Anchored,"Unsafe source");c+=1 end end
 assert(c==count,"Source count changed: "..n)
end
assert(kit.back_door2.Door_Step.Position.Z<kit.back_door2.Door_Reveal.Position.Z,"Source import orientation changed")
local before={}
for i,v in J:GetDescendants() do
 local b={p=v,parent=v.Parent,name=v.Name}
 if v:IsA("BasePart") then
  b.cf=v.CFrame;b.size=v.Size;b.color=v.Color;b.material=v.Material;b.variant=v.MaterialVariant;b.transparency=v.Transparency;b.anchored=v.Anchored;b.collide=v.CanCollide;b.touch=v.CanTouch;b.query=v.CanQuery;b.shadow=v.CastShadow
 end
 if v:IsA("TextLabel") then b.text=v.Text end
 table.insert(before,b);if i%750==0 then task.wait() end
end
local C=Color3.fromRGB
local dark=C(65,47,35)
local looks={
 Door_Frame={Enum.Material.Wood,dark},Door_Wood={Enum.Material.Wood,C(122,89,61)},
 Door_Reveal={Enum.Material.SmoothPlastic,C(27,24,20)},Door_Paper={Enum.Material.SmoothPlastic,C(198,184,153)},
 Door_Step={Enum.Material.Slate,C(113,111,101)},
 Win_Frame={Enum.Material.Wood,dark},Win_Bars={Enum.Material.Wood,dark},Win_Sill={Enum.Material.Wood,C(83,59,40)},
 Win_Reveal={Enum.Material.SmoothPlastic,C(27,24,20)},Win_Paper={Enum.Material.SmoothPlastic,C(198,184,153)},
 Awning_Tile={Enum.Material.Slate,C(58,58,66)},Awning_Wood={Enum.Material.Wood,dark},
}
local root=Instance.new("Model");root.Name="CafeSideDetails1"
local northZ=20.2
local FLIP=CFrame.Angles(0,math.pi,0)
local function component(src,p,frame,sx,sy,sz,zoff,yoff)
 local q=p:Clone()
 for _,v in q:GetChildren() do v:Destroy() end
 for key in q:GetAttributes() do q:SetAttribute(key,nil) end
 local rel=FLIP*src:GetPivot():ToObjectSpace(p.CFrame)
 local pos=rel.Position+Vector3.new(0,yoff or 0,zoff)
 q.Size=p.Size*Vector3.new(sx,sy,sz)
 q.CFrame=frame*CFrame.new(pos*Vector3.new(sx,sy,sz))*rel.Rotation
 local look=assert(looks[p.Name],"Unexpected source part "..p.Name)
 q.Color=look[2];q.Material=look[1];q.MaterialVariant="";q.TextureID=""
 q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=true;q.CastShadow=true
 q.Transparency=0;q.Reflectance=0;q.RenderFidelity=Enum.RenderFidelity.Precise
 return q
end
local door=Instance.new("Model");door.Name="ClosedServiceDoor";door.Parent=root
local doorFrame=CFrame.new(6029,floorTop,northZ)
for _,p in kit.back_door2:GetChildren() do if p:IsA("MeshPart") and p.Name~="Door_Step" then
 local q=component(kit.back_door2,p,doorFrame,1,1,1,.6,0)
 if p.Name=="Door_Reveal" then
  q.Size=Vector3.new(q.Size.X,q.Size.Y,.024);q.CFrame=doorFrame*CFrame.new(0,4,.015)*FLIP
 elseif p.Name=="Door_Paper" then
  q.Size=Vector3.new(q.Size.X,q.Size.Y,.018);q.CFrame=doorFrame*CFrame.new(0,5.375,.04)*FLIP;q.CastShadow=false
 end
 q.Parent=door
end end
for _,row in {{"PullBar",Vector3.new(.10,.64,.10),Vector3.new(1.65,2.8,.38)},
 {"PullMountTop",Vector3.new(.10,.10,.24),Vector3.new(1.65,3.07,.26)},
 {"PullMountBottom",Vector3.new(.10,.10,.24),Vector3.new(1.65,2.53,.26)}} do
 local q=kit.back_door2.Door_Reveal:Clone();q.Name=row[1]
 for _,v in q:GetChildren() do v:Destroy() end
 q.Size=row[2];q.CFrame=doorFrame*CFrame.new(row[3]);q.Color=C(104,91,63);q.Material=Enum.Material.Metal;q.MaterialVariant="";q.TextureID=""
 q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=true;q.CastShadow=true;q.RenderFidelity=Enum.RenderFidelity.Precise
 q.Parent=door
end
-- Two solid mesh risers link the grass at y=0 to the actual shop floor.
for i,row in {{"LowerStep",6.5,floorTop/4,2.9,1.35},{"UpperStep",6,floorTop*.75,1.8,.8}} do
 local q=kit.back_door2.Door_Step:Clone();q.Name=row[1]
 for _,v in q:GetChildren() do v:Destroy() end
 q.Size=Vector3.new(row[2],floorTop/2,row[4]);q.CFrame=CFrame.new(6029,row[3],northZ+row[5])*FLIP
 q.Color=looks.Door_Step[2];q.Material=Enum.Material.Slate;q.MaterialVariant="";q.TextureID=""
 q.Anchored=true;q.CanCollide=true;q.CanTouch=false;q.CanQuery=true;q.CastShadow=true;q.RenderFidelity=Enum.RenderFidelity.Precise
 q.Parent=door
end
-- One broad lower window and a paired upper arrangement, fitted to each wall's outside plane.
for _,row in {
 {"GroundFloorWindow",6019.2,-.8,20.2,1.5},
 {"UpperFrontWindow",6019.4,8.2,20.175,1.35},
 {"UpperRearWindow",6028.6,8.2,20.175,1.35},
} do
 local win=Instance.new("Model");win.Name=row[1];win.Parent=root
 local windowFrame=CFrame.new(row[2],row[3],row[4])
 for _,p in kit.back_window2:GetChildren() do if p:IsA("MeshPart") then
  local q=component(kit.back_window2,p,windowFrame,row[5],1,1,.05,0)
  if p.Name=="Win_Reveal" then
   q.Size=Vector3.new(q.Size.X,q.Size.Y,.024);q.CFrame=windowFrame*CFrame.new(0,7.1,.015)*FLIP
  elseif p.Name=="Win_Paper" then
   q.Size=Vector3.new(q.Size.X,q.Size.Y,.018);q.CFrame=windowFrame*CFrame.new(0,7.1,.04)*FLIP;q.CastShadow=false
  end
  q.Parent=win
 end end
end
-- A short tiled hood shelters the service entrance, matching the existing tile roof.
local hood=Instance.new("Model");hood.Name="ServiceDoorHood";hood.Parent=root
for _,p in kit.awning_section:GetChildren() do if p:IsA("MeshPart") then
 local q=component(kit.awning_section,p,CFrame.new(6029,9.95,northZ),1.5,.8,.65,.95,-9.1)
 q.Parent=hood
end end
local count=0
for _,p in root:GetDescendants() do if p:IsA("BasePart") then assert(p:IsA("MeshPart") and p.Anchored);count+=1 end end
assert(count==26,"Unexpected detail count")
assert(#root:GetDescendants()==31,"Unexpected non-mesh objects")
if not Run:IsRunning() then game.ChangeHistoryService:SetWaypoint("Before cafe north side details") end
local ok,err=pcall(function()
 root.Parent=shop
 for i,b in before do local p=b.p
  assert(p.Parent==b.parent and p.Name==b.name,"Original instance changed")
  if b.cf then assert(p.CFrame==b.cf and p.Size==b.size and p.Color==b.color and p.Material==b.material and p.MaterialVariant==b.variant and p.Transparency==b.transparency and p.Anchored==b.anchored and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query and p.CastShadow==b.shadow,"Original part changed") end
  if b.text then assert(p.Text==b.text,"Original text changed") end
  if i%750==0 then task.wait() end
 end
 shop:SetAttribute("SideDetailsVersion","north1")
end)
if not ok then root:Destroy();error("Side details reverted: "..tostring(err)) end
if not Run:IsRunning() then game.ChangeHistoryService:SetWaypoint("After cafe north side details") end
print("QQ CAFE SIDES: north wall has one closed lattice service door with a brass pull, two stone steps, one broad lower lattice window, paired upper lattice windows and a matching tile hood;26 real mesh parts")
print("QQ CAFE SIDES FIT: door threshold matches shop floor1.039853; steps reach ground0; frames penetrate wall.2 studs; paper sits behind lattice and ahead of opaque backing")
print("QQ CAFE SIDES PRESERVED: all "..#before.." original Japan instances unchanged; both original wood colors and solid walls retained; cafe interior, real front entrance and other shops unchanged; no service-door prompt")
print("QQ CAFE SIDES STATUS: "..(Run:IsRunning() and "SERVER PREVIEW" or "EDIT INSTALLED").."; NOT PUBLISHED")

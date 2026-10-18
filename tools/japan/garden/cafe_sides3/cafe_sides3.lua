-- SUPERSEDED: use cafe_sides4 + cafe_side_tone1 after separate approval.
error("Superseded cafe_sides3 must not run; use cafe_sides4")
-- Rear-matched north side. Server preview first; Edit only after Shannon approves its pictures.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or (not Run:IsRunning() and CAFE_SIDES3_ALLOW_EDIT==true),"Preview first; Edit requires approval")
local J=workspace.JapanMap
local shop=J["Outdoor market revision"]["Cat cafe"]
local backs=J.ShopBacks
assert(not shop:GetAttribute("SideDetailsVersion"),"A side treatment already exists")
assert(not shop:FindFirstChild("CafeSideDetails3"),"Already present")
local lower,upper
for _,p in shop:GetChildren() do
 if p:IsA("BasePart") and p.Name=="Side wall" and math.abs(p.Position.Z-20)<.01 then lower=p end
end
for _,p in shop["Traditional downtown facade"]:GetChildren() do
 if p:IsA("BasePart") and p.Name=="Upper timber side wall" and math.abs(p.Position.Z-20)<.01 then upper=p end
end
assert(lower and upper and lower.CanCollide and upper.CanCollide,"North walls changed")
assert(lower.Color==Color3.fromRGB(220,205,183) and upper.Color==Color3.fromRGB(162,143,119),"Wall colors changed")
local floorTop=shop["Shop floor"].Position.Y+shop["Shop floor"].Size.Y/2
assert(math.abs(floorTop-1.039853185)<.001,"Floor changed")
local doorSource=assert(backs:FindFirstChild("Cat cafe_door"))
local windowSource=assert(backs:FindFirstChild("Cat cafe_upper0"))
local awningSource=assert(backs:FindFirstChild("Cat cafe_awning3"))
local hoodSource=assert(backs:FindFirstChild("Cat cafe_upperhood0"))
for _,row in {{doorSource,5},{windowSource,5},{awningSource,2},{hoodSource,2}} do
 local count=0
 for _,p in row[1]:GetDescendants() do
  assert(p:IsA("MeshPart") and p.Anchored,"Unexpected rear source child")
  count+=1
 end
 assert(count==row[2],"Rear source count changed")
end
local before={}
for i,p in J:GetDescendants() do
 local b={p=p,parent=p.Parent,name=p.Name}
 if p:IsA("BasePart") then
  b.cf=p.CFrame;b.size=p.Size;b.color=p.Color;b.material=p.Material;b.variant=p.MaterialVariant
  b.transparency=p.Transparency;b.anchored=p.Anchored;b.collide=p.CanCollide;b.touch=p.CanTouch;b.query=p.CanQuery;b.shadow=p.CastShadow
 end
 if p:IsA("TextLabel") then b.text=p.Text end
 table.insert(before,b);if i%750==0 then task.wait() end
end
local root=Instance.new("Model");root.Name="CafeSideDetails3"
local ROT=CFrame.Angles(0,-math.pi/2,0)
local function copyRear(src,name,sourceZ,targetX,dy,wallZ,omitStep)
 local m=Instance.new("Model");m.Name=name;m.Parent=root
 local delta=CFrame.new(targetX,dy,wallZ)*ROT*CFrame.new(-6034,0,-sourceZ)
 for _,p in src:GetChildren() do
  if not (omitStep and p.Name=="Door_Step") then
   local q=p:Clone();q.CFrame=delta*p.CFrame
   for _,v in q:GetChildren() do v:Destroy() end
   for k in q:GetAttributes() do q:SetAttribute(k,nil) end
   q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=true
   q.RenderFidelity=Enum.RenderFidelity.Precise
   q:SetAttribute("RearStyleSource",p:GetFullName())
   q.Parent=m
   assert(q.Size==p.Size and q.Color==p.Color and q.Material==p.Material and q.TextureID==p.TextureID,"Rear appearance changed")
  end
 end
 return m
end
local door=copyRear(doorSource,"ClosedServiceDoor",7,6029,floorTop,20.2,true)
-- The source's dark recessed panels, timber grain and original lattice proportions are retained.
copyRear(windowSource,"GroundFloorWindow",1.5,6019.2,-8,20.2,false)
copyRear(windowSource,"UpperFrontWindow",1.5,6019.4,0,20.175,false)
copyRear(windowSource,"UpperRearWindow",1.5,6028.6,0,20.175,false)
for i,x in {6016,6020,6024,6028,6032} do
 copyRear(awningSource,"LowerTiledEave"..i,7.995461940765381,x,floorTop,20.2,false)
end
copyRear(hoodSource,"UpperFrontHood",1.5,6019.4,0,20.175,false)
copyRear(hoodSource,"UpperRearHood",1.5,6028.6,0,20.175,false)
-- Two mesh risers meet the actual floor while keeping the rear step's stone appearance.
for _,r in {{"LowerStep",6.4,floorTop/4,2.8,1.35},{"UpperStep",6,floorTop*.75,1.8,.8}} do
 local p=doorSource.Door_Step:Clone();p.Name=r[1]
 for _,v in p:GetChildren() do v:Destroy() end
 for k in p:GetAttributes() do p:SetAttribute(k,nil) end
 p.Size=Vector3.new(r[2],floorTop/2,r[4])
 p.CFrame=CFrame.new(6029,r[3],20.2+r[5])
 p.Anchored=true;p.CanCollide=true;p.CanTouch=false;p.CanQuery=true
 p.RenderFidelity=Enum.RenderFidelity.Precise;p.Parent=door
end
local n=0
for _,p in root:GetDescendants() do
 if p:IsA("BasePart") then assert(p:IsA("MeshPart") and p.Anchored);n+=1 end
end
assert(n==35,"Unexpected part count")
if not Run:IsRunning() then game.ChangeHistoryService:SetWaypoint("Before cafe rear-matched north side") end
local ok,err=pcall(function()
 root.Parent=shop
 for i,b in before do
  local p=b.p
  assert(p.Parent==b.parent and p.Name==b.name,"Original object changed")
  if b.cf then
   assert(p.CFrame==b.cf and p.Size==b.size and p.Color==b.color and p.Material==b.material and p.MaterialVariant==b.variant and p.Transparency==b.transparency and p.Anchored==b.anchored and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query and p.CastShadow==b.shadow,"Original part changed")
  end
  if b.text then assert(p.Text==b.text,"Original text changed") end
  if i%750==0 then task.wait() end
 end
 shop:SetAttribute("SideDetailsVersion","rear3")
end)
if not ok then root:Destroy();error("Cafe side preview reverted: "..tostring(err)) end
if not Run:IsRunning() then game.ChangeHistoryService:SetWaypoint("After cafe rear-matched north side") end
print("QQ CAFE SIDES3:35 real mesh parts; closed service door, three original-size lattice windows, continuous lower tiled eave and two upper hoods")
print("QQ CAFE SIDES3 STYLE:33 parts copied from the accepted cafe rear with identical size, color, material and texture; original shaded recesses retained; two stone mesh steps fitted to floor1.039853")
print("QQ CAFE SIDES3 PRESERVED:"..#before.." original Japan instances unchanged; both wall colors, all accepted backs, cafe interior/front/cats/audio and other shops retained")
print("QQ CAFE SIDES3 STATUS:"..(Run:IsRunning() and "SERVER PREVIEW" or "EDIT INSTALLED").."; NOT PUBLISHED")

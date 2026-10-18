-- Narrow cafe detail preview; preserve approved floor, walls, rugs, seats, cats and audio.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and CAFEDETAIL1_ALLOW_EDIT==true),"Preview first; Edit needs Shannon's yes")
local room=assert(workspace.JapanMap.ShopFronts:FindFirstChild("CatCafeInterior"))
local frame=game.ReplicatedStorage.CafeInterior2Link:GetAttribute("RoomFrame")
assert(room:GetAttribute("CafeFloorFinish")=="lengthwise_walnut4"and room:GetAttribute("CafeRugPalette")=="moss1","Approved floor/rugs required")
assert(not room:GetAttribute("CafeDetailVersion"),"Already patched; inspect before rerunning")
local furniture=room.Furniture;local nooks=room.CozyNooks
local window=assert(nooks:FindFirstChild("WindowCatPlanter"));local counterPlant=assert(nooks:FindFirstChild("CounterCatPlanter"))
local cushion=assert(furniture:FindFirstChild("C1_WindowBeds_SageSoft"))
local portrait=assert(nooks:FindFirstChild("RearCatPortrait"))
local label=assert(furniture.C1_CounterMenu_Paper:FindFirstChild("CafeLabel")):FindFirstChildOfClass("TextLabel")
assert(label and label.Text=="TEA  &  COFFEE","Counter label changed")
for _,n in ipairs({"C1_Climb2_OakLight","C1_Climb2_OakDark","C1_Climb2_SageSoft"})do assert(furniture:FindFirstChild(n),"Missing perch mesh")end
assert(math.abs(frame:PointToObjectSpace(furniture.C1_Counter_OakLight.Position).Z+25.5)<.01,"Counter changed; inspect first")
local before={};local originals=0;local permitted={}
for _,p in ipairs(room:GetDescendants())do if p:IsA("BasePart")then
 before[p]={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,transparency=p.Transparency,collide=p.CanCollide,touch=p.CanTouch,query=p.CanQuery,anchored=p.Anchored}
 originals+=1
end end
assert(originals==470,"Unexpected interior inventory")
local function allow(model,resize)
 for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then permitted[p]={resize=resize}end end
end
allow(window);allow(counterPlant,true);allow(portrait);permitted[cushion]={}
local movedGroups={C1_Counter=Vector3.new(0,0,3.6),C1_CounterMenu=Vector3.new(3.15,0,3.05),C1_TeaService=Vector3.new(-.7,0,3.6),C1_Pastry=Vector3.new(.65,0,3.6),C1_PastryCover=Vector3.new(.65,0,3.6)}
for _,p in ipairs(furniture:GetChildren())do if p:IsA("BasePart")and movedGroups[p.Name:match("^(.*)_[^_]+$")]then permitted[p]={}end end
if not Run:IsRunning()then
 local hb=assert(game.ServerStorage:FindFirstChild("HudBackup"));assert(not hb:FindFirstChild("CafeInterior_pre_detail1"),"Backup exists; inspect first")
 game.ChangeHistoryService:SetWaypoint("Before cafe service counter and details")
 local backup=room:Clone();backup.Name="CafeInterior_pre_detail1";backup.Parent=hb
end
-- The pot was intersecting a cat cushion; its trailing vine was passing through the bench.
-- Separate the cushion and place the whole planter at the front edge so the vine hangs clear.
window:PivotTo(frame*CFrame.new(-3.25,2.015,-2.64)*CFrame.Angles(0,math.pi,0))
cushion.CFrame=cushion.CFrame+frame:VectorToWorldSpace(Vector3.new(1.15,0,0))
-- Four studs of working clearance behind the counter, with wall shelving left in place.
for _,p in ipairs(furniture:GetChildren())do if p:IsA("BasePart")then
 local delta=movedGroups[p.Name:match("^(.*)_[^_]+$")]
 if delta then p.CFrame=p.CFrame+frame:VectorToWorldSpace(delta)end
end end
counterPlant:ScaleTo(.85)
counterPlant:PivotTo(frame*CFrame.new(-1.8,3.085,-20.68))
label.Text="ORDER & PAY"
local details=Instance.new("Model");details.Name="ServiceCounterDetails"
local tray=window.CW1_CatPlanter_Celadon:Clone();tray.Name="CatEarPaymentTray"
tray.Size=Vector3.new(.85,.15,1.10)
tray.CFrame=frame*CFrame.new(1.9,3.16,-20.98)*CFrame.Angles(0,math.pi/2,0)
tray.Anchored=true;tray.CanCollide=false;tray.CanTouch=false;tray.CanQuery=false
tray.Parent=details;details.Parent=room
-- Reuse the imported three-piece cushioned perch and its wall braces, wrapping onto the rear wall.
local perch=Instance.new("Model");perch.Name="JumpLandingPerch"
local oldFrame=frame*CFrame.new(15.4,6.8,-21.2)
local landingFrame=frame*CFrame.new(11.1,7.05,-26.35)*CFrame.Angles(0,math.pi/2,0)
for _,p in ipairs(furniture:GetChildren())do if p:IsA("MeshPart")and p.Name:match("^(.*)_[^_]+$")=="C1_Climb2"then
 local c=p:Clone();c.CFrame=landingFrame*oldFrame:ToObjectSpace(p.CFrame);c.Anchored=true;c.CanTouch=false;c.Parent=perch
end end
assert(#perch:GetChildren()==3,"Expected complete landing perch")
perch.WorldPivot=landingFrame;perch.Parent=room
portrait:PivotTo(portrait:GetPivot()-Vector3.new(0,.75,0))
-- Existing cat pose and rig stay exactly as approved; the new target follows its head direction.
local moved,resized,unchanged=0,0,0
for p,b in pairs(before)do
 assert(p.Parent,"Removed existing cafe part")
 local permit=permitted[p]
 assert(p.Color==b.color and p.Material==b.material and p.Transparency==b.transparency and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query and p.Anchored==b.anchored,"Unrequested property change: "..p.Name)
 if p.CFrame~=b.cf then assert(permit,"Unrequested move: "..p.Name);moved+=1 else unchanged+=1 end
 if p.Size~=b.size then assert(permit and permit.resize,"Unrequested resize: "..p.Name);resized+=1 end
end
room:SetAttribute("CafeDetailVersion","detail1")
room:SetAttribute("CafeServerStandingPoint",frame:PointToWorldSpace(Vector3.new(1.9,0,-25.2)))
room:SetAttribute("CafeJumpLandingPoint",landingFrame.Position)
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After cafe service counter and details")end
print(string.format("QQ CAFE DETAIL CHECK: %d original interior parts; %d moved, %d resized, %d unchanged transforms; four real-mesh additions",originals,moved,resized,unchanged))
print("QQ CAFE WINDOW: planter on bare bench edge; cushion shifted clear; trailing vine hangs in front of bench")
print("QQ CAFE COUNTER: forward3.6 studs; wall shelves stay; tea and pastries retained; central order/payment area; no attendant or payment gameplay added")
print("QQ CAFE JUMP: new rear-wall cushioned landing in Ginger's facing direction; original cat transform/scale/rig unchanged")
print("QQ CAFE DETAIL STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")

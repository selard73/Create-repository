-- REJECTED DIAGNOSTIC ONLY. Do not install: moving this mesh leaves reversed-face holes. Use kit33 and install_curtain1.lua.
-- Approved-preview workflow: Play Server first; stopped Edit only on Shannon's yes.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and GROCER_CURTAIN1_ALLOW_EDIT==true),"Preview first; Edit needs approval")
local m=workspace.JapanMap.ShopFronts.Mikan
assert(m:GetAttribute("MikanBuildVersion")=="grocer2"and not m:GetAttribute("NorenFacingVersion"),"Inspect current curtain first")
assert(not m:FindFirstChild("NorenSupport1"),"Existing support; inspect first")
local f=m:GetPivot()
local cloth=assert(m:FindFirstChild("M2_Facade_Sage"))
local source=assert(m:FindFirstChild("M2_Label_pickle0_stem_CedarDark"))
assert(cloth:IsA("MeshPart")and source:IsA("MeshPart")and cloth.Anchored and source.Anchored)
local old=f:ToObjectSpace(cloth.CFrame)
assert((old.Position-Vector3.new(-8.8,7.77,.165)).Magnitude<.01 and math.abs(cloth.Size.X-5.52)<.01 and math.abs(cloth.Size.Y-1.02)<.01,"Original curtain differs")
local beam=workspace.JapanMap["Outdoor market revision"]["Mikan greengrocer"]["Lintel over open shop"]
assert((f:PointToObjectSpace(beam.Position)-Vector3.new(0,7.6101465,0)).Magnitude<.01 and math.abs(beam.Size.Z-.5)<.01,"Beam moved; inspect first")
local before={}
for _,p in m:GetDescendants()do if p:IsA("BasePart")then before[p]={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,transparency=p.Transparency,anchored=p.Anchored,collide=p.CanCollide,touch=p.CanTouch,query=p.CanQuery}end end
local support=Instance.new("Model");support.Name="NorenSupport1"
local function timber(name,position,size,rotation)
 local p=source:Clone();p.Name=name
 for _,v in p:GetChildren()do v:Destroy()end
 for key in p:GetAttributes()do p:SetAttribute(key,nil)end
 p.Size=size;p.CFrame=f*CFrame.new(position)*rotation
 p.Color=Color3.fromRGB(65,47,35);p.Material=Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=true
 p.Parent=support
end
timber("CurtainRail",Vector3.new(-8.35,8.35,.37),Vector3.new(.14,5.05,.14),CFrame.Angles(0,0,math.pi/2))
for i,x in {-10.65,-6.05}do timber("RailStandoff"..i,Vector3.new(x,8.35,.205),Vector3.new(.10,.33,.10),CFrame.Angles(math.pi/2,0,0))end
local backup
if not Run:IsRunning()then
 local hb=game.ServerStorage.HudBackup
 assert(not hb:FindFirstChild("GrocerCurtain1Original"),"Backup exists; inspect first")
 backup=cloth:Clone();backup.Name="GrocerCurtain1Original";backup.Parent=hb
 game.ChangeHistoryService:SetWaypoint("Before grocer curtain clearance")
end
local ok,err=pcall(function()
 cloth.Size=Vector3.new(4.7,cloth.Size.Y,cloth.Size.Z)
 cloth.CFrame=f*CFrame.new(-8.35,old.Position.Y,old.Position.Z+.22)*old.Rotation
 support.Parent=m
 local moved=0
 for p,b in pairs(before)do
  assert(p.Color==b.color and p.Material==b.material and p.Transparency==b.transparency and p.Anchored==b.anchored and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query,"Unrequested appearance or physical change")
  if p==cloth then moved+=1 else assert(p.CFrame==b.cf and p.Size==b.size,"Unrelated part changed: "..p.Name)end
 end
 assert(moved==1 and #support:GetChildren()==3)
 local q=f:PointToObjectSpace(cloth.Position)
 assert(q.Z-cloth.Size.Z/2>.30 and q.X-cloth.Size.X/2> -10.71,"Curtain clearance failed")
 m:SetAttribute("NorenFacingVersion","front1")
end)
if not ok then cloth.CFrame=before[cloth].cf;cloth.Size=before[cloth].size;support:Destroy();if backup then backup:Destroy()end;error("Curtain change reverted: "..tostring(err))end
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After grocer curtain clearance")end
print("QQ GROCER CURTAIN: cloth forward.22 studs; width4.70 and centerX-8.35 keep it clear of left lantern; original height/color retained")
print("QQ GROCER CURTAIN SUPPORT: three existing real-mesh copies form a wooden rail and two standoffs connected to the original rear rod; no import required")
print("QQ GROCER CURTAIN PRESERVED: one existing mesh moved/resized; all other original grocer parts, beam, signs, stock and lanterns unchanged")
print("QQ GROCER CURTAIN STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")


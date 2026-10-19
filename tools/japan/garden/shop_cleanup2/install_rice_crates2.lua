-- Move only the two low produce displays fully in front of the rice-shop counter.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert(Run:IsRunning() or VISUAL_FIXES_ALLOW_EDIT==true,"Explicit installation authorization required")
local shop=workspace.JapanMap["Outdoor market revision"]["Rice and provisions"]
assert(not shop:GetAttribute("FrontCrateClearanceVersion"),"Already installed")
local front=assert(shop:FindFirstChild("Counter front boards"))
assert(math.abs(front.Position.X-6010.64990234375)<.01,"Counter moved")
local groups={}
for _,m in shop:GetChildren()do if m:IsA("Model")and m.Name=="Produce display"then local cf=m:GetBoundingBox()
 if cf.Position.X<6015 and cf.Position.Y<3 then table.insert(groups,m)end end end
assert(#groups==2,"Expected two low front crates")
local function bounds(m)
 local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,p in m:GetDescendants()do if p:IsA("BasePart")then
  for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2);lo=lo:Min(v);hi=hi:Max(v)end end end
 end end
 return lo,hi
end
local plans={}
local targetX=front.Position.X-front.Size.Z/2-.16
for _,m in groups do
 local lo,hi=bounds(m);local dx=targetX-hi.X
 assert(dx<0 and dx> -5,"Unexpected move")
 local center=m:GetPivot().Position+Vector3.new(dx,0,0)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.RespectCanCollide=true
 local skip=table.clone(groups);for _,p in game.Players:GetPlayers()do if p.Character then table.insert(skip,p.Character)end end;rp.FilterDescendantsInstances=skip
 local hit=workspace:Raycast(Vector3.new(center.X,3,center.Z),Vector3.new(0,-8,0),rp)
 assert(hit and hit.Position.Y>-.1 and hit.Position.Y<1.5,"Ground not established")
 local delta=Vector3.new(dx,hit.Position.Y-lo.Y+.015,0)
 table.insert(plans,{m=m,cf=m:GetPivot(),delta=delta})
end
local hb=game.ServerStorage.HudBackup;assert(not hb:FindFirstChild("RiceFrontCrates2"))
local backup=Instance.new("Folder");backup.Name="RiceFrontCrates2";backup.Parent=hb
for i,p in plans do local b=p.m:Clone();b.Name="OriginalCrate"..i;b.Parent=backup;p.m:SetAttribute("FrontCrateOriginalPivot",p.cf);p.m:PivotTo(p.cf+p.delta)
 local lo,hi=bounds(p.m);assert(hi.X<=targetX+.01,"Crate still intersects counter")
 print(string.format("QQ RICE CRATES2: display%d moved %.3f X / %.3f Y; counter clearance %.3f studs; all fruit and leaves moved together",i,p.delta.X,p.delta.Y,front.Position.X-front.Size.Z/2-hi.X))
end
shop:SetAttribute("FrontCrateClearanceVersion","front2")
print("QQ RICE CRATES2: two original complete produce models repositioned; countertop stock and all other shop parts retained")

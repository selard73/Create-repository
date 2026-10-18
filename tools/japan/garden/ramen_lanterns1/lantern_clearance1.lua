-- Play Server preview first; Edit only after Shannon approves the pictures.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and RAMEN_LANTERNS1_ALLOW_EDIT==true),"Preview first; Edit requires approval")
local J=workspace.JapanMap
local shop=J["Outdoor market revision"]["Ramen kitchen"]
assert(not shop:GetAttribute("LanternClearanceVersion")and not shop:FindFirstChild("LanternEndBrackets1"),"Inspect current lantern state")
local counts={["Lantern hanging chain"]=2,["Ramen lantern lettering"]=2,["Fine lantern rib"]=32,["Black lantern cap"]=4,["Large cream ramen lantern"]=2}
local found={};local changes={};local moves={};local groups={0,0}
for _,p in shop:GetChildren()do if p:IsA("BasePart")and counts[p.Name]then
 local side=math.abs(p.Position.Z-3.1000013351)<.01 and 1 or(math.abs(p.Position.Z-20.3500003815)<.01 and 2 or nil)
 assert(side,"Lantern group moved")
 assert(p.Anchored and math.abs(p.Position.X-(p.Name=="Ramen lantern lettering"and 5994.5458984375 or 5993.68017578125))<.01,"Unexpected lantern location")
 found[p.Name]=(found[p.Name]or 0)+1;groups[side]+=1
 local z=side==1 and -.25 or 23.8
 local cf=p.CFrame+Vector3.new(0,0,z-p.Position.Z)
 changes[p]=cf;table.insert(moves,p)
end end
for n,c in pairs(counts)do assert(found[n]==c,"Unexpected count: "..n)end
assert(#moves==42 and groups[1]==21 and groups[2]==21)
for i=1,4 do local p=assert(shop:FindFirstChild("Red ramen noren "..i));assert(math.abs(p.Position.X-5993.66015625)<.01 and math.abs(p.Size.X-5.24)<.01)end
local before={}
for i,v in J:GetDescendants()do
 local row={p=v,parent=v.Parent,name=v.Name}
 if v:IsA("BasePart")then row.cf=v.CFrame;row.size=v.Size;row.color=v.Color;row.material=v.Material;row.transparency=v.Transparency;row.anchored=v.Anchored;row.collide=v.CanCollide;row.touch=v.CanTouch;row.query=v.CanQuery end
 if v:IsA("TextLabel")then row.text=v.Text end
 if v:IsA("Light")then row.brightness=v.Brightness;row.enabled=v.Enabled;row.lightColor=v.Color end
 table.insert(before,row);if i%750==0 then task.wait()end
end
local source=J.ShopFronts.Mikan.M2_Label_pickle0_stem_CedarDark
assert(source:IsA("MeshPart"))
local rail=shop["Canopy front rail"]
local support=Instance.new("Model");support.Name="LanternEndBrackets1"
for i,row in {{.375,1.41},{23.2,1.36}}do
 local p=source:Clone();p.Name="LanternEndBracket"..i
 for _,v in p:GetChildren()do v:Destroy()end
 for key in p:GetAttributes()do p:SetAttribute(key,nil)end
 p.Size=Vector3.new(.16,row[2],.14);p.CFrame=CFrame.new(5993.60,8.98,row[1])*CFrame.Angles(math.pi/2,0,0)
 p.Color=rail.Color;p.Material=rail.Material;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=true
 p.Parent=support
end
local backup
if not Run:IsRunning()then
 local hb=game.ServerStorage.HudBackup;assert(not hb:FindFirstChild("RamenLanterns1Originals"),"Backup already exists")
 backup=Instance.new("Folder");backup.Name="RamenLanterns1Originals"
 for _,p in moves do p:Clone().Parent=backup end
 backup.Parent=hb;game.ChangeHistoryService:SetWaypoint("Before ramen lantern clearance")
end
local ok,err=pcall(function()
 for p,cf in pairs(changes)do p.CFrame=cf end
 support.Parent=shop
 local moved=0
 for i,b in before do local p=b.p
  assert(p.Parent==b.parent and p.Name==b.name,"Unrequested object change")
  if b.cf then
   assert(p.Size==b.size and p.Color==b.color and p.Material==b.material and p.Transparency==b.transparency and p.Anchored==b.anchored and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query,"Unrequested part property change")
   if changes[p]then assert(p.CFrame==changes[p]);moved+=1 else assert(p.CFrame==b.cf,"Unrequested part movement")end
  end
  if b.text then assert(p.Text==b.text,"Text changed")end
  if b.brightness then assert(p.Brightness==b.brightness and p.Enabled==b.enabled and p.Color==b.lightColor,"Light changed")end
  if i%750==0 then task.wait()end
 end
 assert(moved==42)
 shop:SetAttribute("LanternClearanceVersion","ends1")
end)
if not ok then for _,b in before do if changes[b.p]then b.p.CFrame=b.cf end end;support:Destroy();if backup then backup:Destroy()end;error("Lantern placement reverted: "..tostring(err))end
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After ramen lantern clearance")end
print("QQ RAMEN LANTERNS: both21-part assemblies moved outside the sign row; new centerZ-.25/23.80; original height, size, lettering and lights retained")
print("QQ RAMEN LANTERNS SUPPORT: two short matching real-mesh brackets connect chains to canopy ends; no import needed")
print("QQ RAMEN LANTERNS PRESERVED:42 existing transforms changed; all other "..(#before-42).." Japan instances and properties unchanged")
print("QQ RAMEN LANTERNS STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")

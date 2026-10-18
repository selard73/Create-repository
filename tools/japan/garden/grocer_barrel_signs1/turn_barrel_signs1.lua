-- Preview on Play Server; save only after Shannon approves the pictures.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and BARRELSIGNS1_ALLOW_EDIT==true),"Preview first; Edit needs approval")
local shop=workspace.JapanMap.ShopFronts.Mikan
assert(shop:GetAttribute("MikanBuildVersion")=="grocer2"and not shop:GetAttribute("BarrelSignFacingVersion"),"Inspect existing sign state first")
local frame=shop:GetPivot();local changes={};local before={}
for _,p in ipairs(shop:GetDescendants())do if p:IsA("BasePart")then before[p]={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,transparency=p.Transparency,collide=p.CanCollide,touch=p.CanTouch,query=p.CanQuery,anchored=p.Anchored}end end
for i=0,2 do
 local barrel=assert(shop:FindFirstChild("M2_Pickle"..i.."_CedarLight"))
 local center=frame:PointToObjectSpace(barrel.Position)
 assert(math.abs(center.X-9.7)<.01 and math.abs(center.Z-(-7.6-4.5*i))<.01,"Barrel moved; inspect first")
 local pivot=frame*CFrame.new(center.X,0,center.Z)
 local delta=pivot*CFrame.Angles(0,-math.pi/2,0)*pivot:Inverse()
 for _,suffix in ipairs({"_Paper","_stem_CedarDark"})do
  local p=assert(shop:FindFirstChild("M2_Label_pickle"..i..suffix))
  assert(p:IsA("MeshPart")and p.Anchored)
  local pos=frame:PointToObjectSpace(p.Position)
  assert(math.abs(pos.X-center.X)<.01 and math.abs(pos.Z-(center.Z-(suffix=="_Paper"and .55 or .58)))<.01,"Sign moved; inspect first")
  if suffix=="_Paper"then
   local gui=assert(p:FindFirstChild("ProductLabel"));local text=assert(gui:FindFirstChildOfClass("TextLabel"))
   assert(gui.Face==Enum.NormalId.Front and text.Text~="")
   assert(frame:VectorToObjectSpace(p.CFrame.LookVector).Z>.999,"Sign already rotated")
  end
  changes[p]=delta*p.CFrame
 end
end
if not Run:IsRunning()then
 local hb=game.ServerStorage.HudBackup;assert(not hb:FindFirstChild("GrocerBarrelSigns1Originals"),"Backup exists; inspect first")
 local backup=Instance.new("Folder");backup.Name="GrocerBarrelSigns1Originals"
 for p in pairs(changes)do p:Clone().Parent=backup end
 backup.Parent=hb;game.ChangeHistoryService:SetWaypoint("Before grocer side-facing barrel signs")
end
for p,cf in pairs(changes)do p.CFrame=cf end
local moved=0;for p,b in pairs(before)do
 assert(p.Size==b.size and p.Color==b.color and p.Material==b.material and p.Transparency==b.transparency and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query and p.Anchored==b.anchored,"Unrequested property change")
 if p.CFrame~=b.cf then assert(changes[p],"Unrequested movement");moved+=1 end
end
assert(moved==6)
for i=0,2 do local p=shop["M2_Label_pickle"..i.."_Paper"];assert(frame:VectorToObjectSpace(p.CFrame.LookVector).X<-.999,"Sign not facing customer aisle")end
shop:SetAttribute("BarrelSignFacingVersion","side1")
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After grocer side-facing barrel signs")end
print("QQ GROCER BARREL SIGNS: three existing boards and their posts rotated90 degrees around their barrel centers; text faces the side customer aisle")
print("QQ GROCER BARREL SIGNS PRESERVED: only six transforms changed; barrels, products, wording, shelf stock and all other shop parts unchanged")
print("QQ GROCER BARREL SIGNS STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")

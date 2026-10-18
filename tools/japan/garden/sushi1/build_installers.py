"""Generate guarded preparation and Play-preview installers from the verified mesh manifest."""
from pathlib import Path
import json
D=Path(__file__).resolve().parent
C=json.loads((D/'out/manifest.json').read_text())
data='local CONFIG=game:GetService("HttpService"):JSONDecode([==['+json.dumps(C,separators=(',',':'))+']==])\n'
common=r'''
local function key(n)return(n:gsub("%.%d+$",""))end
local expected={};for _,r in ipairs(CONFIG.meshes)do expected[r.name]=r end
local function collect(model)
 local parts={};local count=0
 for _,p in ipairs(model:GetDescendants())do
  assert(not p:IsA("LuaSourceContainer"),"Unexpected script in kit")
  if p:IsA("BasePart")then
   if p:IsA("MeshPart")then local n=key(p.Name);assert(expected[n]and not parts[n],"Unexpected/duplicate mesh: "..n);assert(p.MeshId~="","Missing mesh asset");parts[n]=p;count+=1
   else assert(p.Name=="RootPart"and p.Transparency==1,"Unexpected visible non-mesh")end
  end
 end
 for n in pairs(expected)do assert(parts[n],"Missing mesh: "..n)end
 local o=parts.S1_Origin.Position;local r=parts.S1_Right.Position-o;local f=parts.S1_Front.Position-o
 assert(math.abs(r.Magnitude-2)<.03 and math.abs(f.Magnitude-2)<.03 and math.abs(r.Unit:Dot(f.Unit))<.001,"Import scale/orientation differs")
 local frame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
 for n,p in pairs(parts)do
  local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
  for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
   local q=frame:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)));lo=lo:Min(q);hi=hi:Max(q)
  end end end
  local m=expected[n];assert((lo-Vector3.new(table.unpack(m.min))).Magnitude<.08 and(hi-Vector3.new(table.unpack(m.max))).Magnitude<.08,"Bounds differ: "..n)
 end
 return parts,frame,count
end
'''
prepare=r'''-- Run only after Shannon imports kit34 and asks to anchor/prepare it.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and not Run:IsRunning()and game.PlaceId==117372258657114,"Prepare in stopped correct Studio before Play")
'''+data+common+r'''
local kit=assert(game.ServerStorage:FindFirstChild("JapanGardenKit"))
assert(not kit:FindFirstChild("sushi_bar1")and not kit:FindFirstChild("sushi_bar1_raw"),"Source already stored; inspect instead")
local candidates={}
for _,v in ipairs(workspace:GetChildren())do if v:IsA("Model")and v.Name~="JapanMap"then
 for _,p in ipairs(v:GetDescendants())do if p:IsA("MeshPart")and key(p.Name)=="S1_Origin"then table.insert(candidates,v);break end end
end end
assert(#candidates>=1 and #candidates<=2,"Expected one kit34 or two identical imports")
local raw=candidates[1];local parts,frame,count=collect(raw)
for i=2,#candidates do
 local dp,df,dc=collect(candidates[i]);assert(dc==count,"Duplicate import differs")
 for n,p in pairs(parts)do
  local q=dp[n];assert(q.MeshId==p.MeshId and(q.Size-p.Size).Magnitude<.001,"Duplicate asset differs: "..n)
  local a=frame:ToObjectSpace(p.CFrame);local b=df:ToObjectSpace(q.CFrame)
  assert((a.Position-b.Position).Magnitude<.001 and a.RightVector:Dot(b.RightVector)>.99999 and a.UpVector:Dot(b.UpVector)>.99999,"Duplicate transform differs")
 end
 assert(not kit:FindFirstChild("sushi_bar1_raw_duplicate"..i),"Duplicate backup already exists")
end
local source=Instance.new("Model");source.Name="sushi_bar1"
for n,p in pairs(parts)do
 local q=p:Clone();q.Name=n
 for _,v in ipairs(q:GetDescendants())do if v:IsA("JointInstance")or v:IsA("WeldConstraint")then v:Destroy()end end
 q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.Parent=source
end
source.WorldPivot=frame;source:SetAttribute("SushiKitVersion","sushi1")
for _,v in ipairs(candidates)do for _,p in ipairs(v:GetDescendants())do if p:IsA("BasePart")then p.Anchored=true;p.CanTouch=false end end end
raw:SetAttribute("OriginalImportName",raw.Name);raw.Name="sushi_bar1_raw";raw.Parent=kit;source.Parent=kit
for i=2,#candidates do local v=candidates[i];v:SetAttribute("OriginalImportName",v.Name);v.Name="sushi_bar1_raw_duplicate"..i;v.Parent=kit end
print("QQ SUSHI1 PREPARED: "..count.." real mesh sources anchored and stored; "..#candidates.." identical raw imports retained; JapanMap unchanged")
'''
install=r'''-- Play SERVER preview. Stopped Edit additionally needs Shannon's explicit approval.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and SUSHI1_ALLOW_EDIT==true),"Preview first; permanent installation requires Shannon's yes")
'''+data+common+r'''
local J=workspace.JapanMap;local market=J["Outdoor market revision"];local shop=market["Sushi bar"]
local fronts=J:FindFirstChild("ShopFronts")
assert(not(fronts and fronts:FindFirstChild("SushiBar")),"Sushi build already present; inspect instead")
local hb=assert(game.ServerStorage:FindFirstChild("HudBackup"))
assert(not hb:FindFirstChild("SushiBar1Originals"),"Backup already exists; inspect instead")
local source=assert(game.ServerStorage.JapanGardenKit:FindFirstChild("sushi_bar1"),"Import and anchor kit34 first")
local parts,sf,count=collect(source)
for _,p in pairs(parts)do assert(p.Anchored,"Source must be anchored before Play")end
local target=CFrame.new(table.unpack(CONFIG.origin))*CFrame.Angles(0,math.rad(CONFIG.yaw),0)
local floorSource=assert(J.ShopFronts.CatCafeInterior:FindFirstChild("CI2_VestibuleFloor_Oak",true),"Approved real box mesh missing")
assert(floorSource:IsA("MeshPart")and floorSource.MeshId=="rbxassetid://95928484054291","Unexpected floor source")
local shellNames={["Shop floor"]=true,["Stone foundation"]=true,["Back wall"]=true,["Side wall"]=true,["Cedar corner post"]=true,["Lintel over open shop"]=true,["Tiled shop roof"]=true,["Exposed roof beam"]=true}
local removed={};local preserved={};local originalCount=0
for _,v in ipairs(shop:GetChildren())do
 local keep=shellNames[v.Name]
 if v.Name=="Handwritten shop sign"then for _,d in ipairs(v:GetDescendants())do if d:IsA("TextLabel")and d.Text=="寿司  Sushi bar"then keep=true end end end
 if not keep then table.insert(removed,v)end
end
assert(#removed>50,"Unexpected old-shop inventory")
local removeSet={};for _,v in ipairs(removed)do removeSet[v]=true;for _,d in ipairs(v:GetDescendants())do removeSet[d]=true end end
for i,p in ipairs(J:GetDescendants())do
 if not removeSet[p]then
  local rec={parent=p.Parent};if p:IsA("BasePart")then rec.cf=p.CFrame;rec.size=p.Size;rec.color=p.Color;rec.material=p.Material;rec.variant=p.MaterialVariant;rec.alpha=p.Transparency;rec.collide=p.CanCollide end
  preserved[p]=rec;originalCount+=1
 end
 if i%1000==0 then task.wait()end
end
local model=Instance.new("Model");model.Name="SushiBar";model:SetAttribute("SushiBuildVersion","sushi1");model.WorldPivot=target
pcall(function()model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic end)
local collisionGroups={S1_Floor=true,S1_Ceiling=true,S1_BarBody=true,S1_BarTop=true,S1_RearCabinet=true,S1_RearTop=true,S1_StepLower=true,S1_StepUpper=true,S1_RearWall=true}
local made={};local meshes=0
for n,p in pairs(parts)do if n~="S1_Origin"and n~="S1_Right"and n~="S1_Front"then
 local q=p:Clone();q.Name=n;q.CFrame=target*sf:ToObjectSpace(p.CFrame)
 local g,k=n:match("^(.*)_([^_]+)$");local m=assert(CONFIG.materials[k])
 q.Color=Color3.fromRGB(table.unpack(m.rgb));q.Material=Enum.Material[m.material];q.MaterialVariant="";q.TextureID=""
 for _,d in ipairs(q:GetChildren())do if d:IsA("SurfaceAppearance")then d:Destroy()end end
 q.Transparency=k=="Glass"and .75 or 0;q.CastShadow=k~="Glass";q.Anchored=true;q.CanTouch=false;q.CanQuery=true
 if k=="Glass"then q.Material=Enum.Material.SmoothPlastic;q.Transparency=.82;q.Reflectance=0 end
 if n=="S1_SideBacking_Walnut"then q.Size-=Vector3.new(.04,0,0)end
 q.CanCollide=collisionGroups[g]==true;q.Parent=model;made[n]=q;meshes+=1
end end
-- Roblox baked the FBX object rotation into vertices. Use the accepted cafe
-- real box mesh for the visible boards, with local X aligned along each board.
local oldFloor=assert(made.S1_Floor_WalnutLight);oldFloor.Transparency=1;oldFloor.CanQuery=false
local floor=Instance.new("Model");floor.Name="AlignedFloorBoards";floor.Parent=model
local floorColors={{103,76,55},{106,79,57},{100,73,52}}
for i=0,16 do
 local q=floorSource:Clone();q:ClearAllChildren();for k in pairs(q:GetAttributes())do q:SetAttribute(k,nil)end
 q.Name=string.format("WalnutBoard_%02d",i);q.Size=Vector3.new(17.5,.07,1.53);q.CFrame=target*CFrame.new(-12.4+i*1.55,.035,-8.9)*CFrame.Angles(0,math.pi/2,0)
 q.Color=Color3.fromRGB(table.unpack(floorColors[i%3+1]));q.Material=Enum.Material.Wood;q.MaterialVariant="";q.TextureID="";q.Transparency=0;q.Reflectance=0
 q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.CanQuery=false;q.CastShadow=true;q.Parent=floor
end
local normals={{Enum.NormalId.Front,Vector3.new(0,0,-1)},{Enum.NormalId.Back,Vector3.new(0,0,1)},{Enum.NormalId.Left,Vector3.new(-1,0,0)},{Enum.NormalId.Right,Vector3.new(1,0,0)},{Enum.NormalId.Top,Vector3.new(0,1,0)},{Enum.NormalId.Bottom,Vector3.new(0,-1,0)}}
for _,r in ipairs(CONFIG.labels)do
 local p=assert(made[r.name]);local outward=target:VectorToWorldSpace(Vector3.new(table.unpack(r.front)));local face,best=nil,-1
 for _,n in ipairs(normals)do local d=p.CFrame:VectorToWorldSpace(n[2]):Dot(outward);if d>best then face=n[1];best=d end end
 assert(best>.999,"Menu alignment")
 local gui=Instance.new("SurfaceGui");gui.Name="SushiMenu";gui.Face=face;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=120;gui.LightInfluence=.65;gui.Parent=p
 local t=Instance.new("TextLabel");t.Name="English";t.Size=UDim2.fromScale(.88,.15);t.Position=UDim2.fromScale(.06,.80);t.BackgroundTransparency=1;t.Text=r.text;t.TextColor3=Color3.fromRGB(39,45,39);t.Font=Enum.Font.Garamond;t.TextScaled=false;t.TextSize=18;t.TextWrapped=false;t.Parent=gui
 local jp=Instance.new("TextLabel");jp.Name="Japanese";jp.Size=UDim2.fromScale(.78,.70);jp.Position=UDim2.fromScale(.11,.04);jp.BackgroundTransparency=1;jp.Text=r.jp;jp.TextColor3=t.TextColor3;jp.Font=Enum.Font.SourceSans;jp.TextScaled=false;jp.TextSize=40;jp.TextWrapped=false;jp.Parent=gui
end
local seats=Instance.new("Folder");seats.Name="CustomerSeats";seats.Parent=model
for _,s in ipairs(CONFIG.seats)do
 local p=Instance.new("Seat");p.Name=s.name;p.Size=Vector3.new(1.55,.10,1.4)
 local pos=target:PointToWorldSpace(Vector3.new(table.unpack(s.position)));local look=target:VectorToWorldSpace(Vector3.new(table.unpack(s.look)))
 p.CFrame=CFrame.lookAt(pos,pos+look);p.Transparency=1;p.Anchored=true;p.CanCollide=true;p.CanTouch=true;p.CastShadow=false;p.Parent=seats
end
for i,x in ipairs({-8.7,-2.4,4.0})do
 local p=assert(made["S1_Pendant"..(i-1).."_Paper"]);local a=Instance.new("Attachment");a.Name="LampLight";a.Position=p.CFrame:PointToObjectSpace(target:PointToWorldSpace(Vector3.new(x,7.5,-8.2)));a.Parent=p
 local l=Instance.new("PointLight");l.Color=Color3.fromRGB(255,227,191);l.Brightness=.7;l.Range=15;l.Shadows=false;l.Parent=a
end
-- Invisible structural shell remains the collision boundary, so no wall-camera gap is introduced.
model:SetAttribute("ChefStandingPoint",target:PointToWorldSpace(Vector3.new(4,0,-13.2)))
model:SetAttribute("ClearCustomerAisle",4.25);model:SetAttribute("ClearStaffAisle",4.10)
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("Before approved sushi bar")end
local backup=Instance.new("Folder");backup.Name="SushiBar1Originals";backup.Parent=hb
for _,v in ipairs(removed)do v:SetAttribute("SushiBar1OriginalParent",v.Parent:GetFullName());v.Parent=backup end
if not fronts then fronts=Instance.new("Folder");fronts.Name="ShopFronts";fronts.Parent=J end
model.Parent=fronts
local ok,err=pcall(function()
 for p,r in pairs(preserved)do
  assert(p.Parent==r.parent,"Unrelated parent changed: "..p.Name)
  if p:IsA("BasePart")then assert(p.CFrame==r.cf and p.Size==r.size and p.Color==r.color and p.Material==r.material and p.MaterialVariant==r.variant and p.Transparency==r.alpha and p.CanCollide==r.collide,"Unrelated appearance/geometry changed: "..p.Name)end
 end
end)
if not ok then model:Destroy();for _,v in ipairs(backup:GetChildren())do v.Parent=shop;v:SetAttribute("SushiBar1OriginalParent",nil)end;backup:Destroy();error(err)end
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After approved sushi bar")end
print("QQ SUSHI1: "..meshes.." real meshes; six aligned functional seats; counter, chef aisle, prep bench, fish case and individual sushi settings")
print("QQ SUSHI1 FLOOR:17 reused real mesh boards, grain along board length; imported floor retained as invisible collision surface")
print("QQ SUSHI1 PRESERVED: "..originalCount.." other Japan instances; original building shell, roof, main sign and all shop backs retained")
print("QQ SUSHI1 BACKUP: "..#removed.." original sushi fixtures retained in HudBackup.SushiBar1Originals; no other shop rebuilt")
print("QQ SUSHI1 STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")
'''
(D/'prepare_sushi1.lua').write_text(prepare,encoding='utf8')
(D/'install_sushi1.lua').write_text(install,encoding='utf8')
print('Prepared guarded source/preview installers for',len(C['meshes']),'meshes')

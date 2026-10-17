-- Run catcafe1_audio.lua after this build to preview Shannon's playlist and meows.
-- Cat cafe 1. Preview on the play-test Server before any approved Edit install.
-- Shannon imports kit23. Prepare/anchor the source in Edit before starting Play.
-- Uses her existing facade. Her Meshy cats are still in Meshy; no substitute cats.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place or not Studio")
assert(Run:IsRunning() or CATCAFE1_ALLOW_EDIT==true,"Server preview only until Shannon approves the pictures")
local SS=game:GetService("ServerStorage")
local J=assert(workspace:FindFirstChild("JapanMap"))
local market=assert(J:FindFirstChild("Outdoor market revision"))
local shop=assert(market:FindFirstChild("Cat cafe"))
local kit=assert(SS:FindFirstChild("JapanGardenKit"))
local source=assert(kit:FindFirstChild("cat_cafe1"),"Import and prepare cat_cafe1 before Play")
local CONFIG=game:GetService("HttpService"):JSONDecode([==[{"materials":{"Timber":{"rgb":[65,47,35],"material":"Wood"},"TimberEdge":{"rgb":[87,62,42],"material":"Wood"},"Cedar":{"rgb":[149,108,65],"material":"Wood"},"CedarLight":{"rgb":[177,134,86],"material":"Wood"},"CedarPale":{"rgb":[197,156,103],"material":"Wood"},"CedarDark":{"rgb":[124,86,49],"material":"Wood"},"Hoop":{"rgb":[86,75,53],"material":"SmoothPlastic"},"Tile":{"rgb":[72,76,80],"material":"SmoothPlastic"},"TileEdge":{"rgb":[93,96,96],"material":"SmoothPlastic"},"Stone":{"rgb":[120,116,105],"material":"SmoothPlastic"},"Sage":{"rgb":[87,112,86],"material":"SmoothPlastic"},"Cream":{"rgb":[231,222,197],"material":"Fabric"},"Paper":{"rgb":[236,220,179],"material":"SmoothPlastic"},"Ink":{"rgb":[60,46,33],"material":"SmoothPlastic"},"Orange":{"rgb":[229,137,41],"material":"SmoothPlastic"},"OrangeLight":{"rgb":[242,165,61],"material":"SmoothPlastic"},"Leaf":{"rgb":[70,117,58],"material":"SmoothPlastic"},"LeafLight":{"rgb":[126,163,83],"material":"SmoothPlastic"},"Radish":{"rgb":[225,225,197],"material":"SmoothPlastic"},"Purple":{"rgb":[78,50,93],"material":"SmoothPlastic"},"Cucumber":{"rgb":[79,116,48],"material":"SmoothPlastic"},"PickleRed":{"rgb":[151,65,77],"material":"SmoothPlastic"},"PickleGold":{"rgb":[202,168,74],"material":"SmoothPlastic"},"PickleBrine":{"rgb":[143,116,64],"material":"SmoothPlastic"},"Carrot":{"rgb":[218,123,43],"material":"SmoothPlastic"},"Bottle":{"rgb":[79,91,54],"material":"SmoothPlastic"},"BottleBrown":{"rgb":[111,61,34],"material":"SmoothPlastic"},"Ceramic":{"rgb":[119,142,138],"material":"SmoothPlastic"},"Brass":{"rgb":[158,132,75],"material":"SmoothPlastic"},"DarkMetal":{"rgb":[55,59,56],"material":"SmoothPlastic"},"Black":{"rgb":[30,32,29],"material":"SmoothPlastic"},"ClothBag":{"rgb":[200,182,144],"material":"SmoothPlastic"},"Oak":{"rgb":[163,119,77],"material":"Wood"},"OakLight":{"rgb":[190,150,104],"material":"Wood"},"OakDark":{"rgb":[116,81,52],"material":"Wood"},"Wall":{"rgb":[231,223,201],"material":"SmoothPlastic"},"SageSoft":{"rgb":[132,151,121],"material":"Fabric"},"Rose":{"rgb":[170,119,114],"material":"Fabric"},"Indigo":{"rgb":[66,87,105],"material":"Fabric"},"Rope":{"rgb":[194,170,124],"material":"Fabric"},"Rug":{"rgb":[207,195,158],"material":"Fabric"},"Tea":{"rgb":[105,117,58],"material":"SmoothPlastic"},"White":{"rgb":[236,228,209],"material":"SmoothPlastic"},"Glass":{"rgb":[200,219,213],"material":"Glass"}},"labels":[{"name":"C1_CounterMenu_Paper","text":"TEA  &  COFFEE","width":1.55,"height":0.75,"front":[0,0,1]}],"seats":[{"name":"BenchSeat0","position":[-10.65,1.96,-16.65],"look":[0,0,1]},{"name":"BenchSeat1","position":[-7.9,1.96,-16.65],"look":[0,0,1]},{"name":"BenchSeat2","position":[-5.15,1.96,-16.65],"look":[0,0,1]},{"name":"ChairSeat0","position":[-10.05,1.99,-7.7],"look":[0,0,-1]},{"name":"ChairSeat1","position":[-5.75,1.99,-7.7],"look":[0,0,-1]}],"catSpots":[{"name":"Window0","position":[-2.55,2.32,-1.82],"usable":[4.4,2.7],"note":"Adjust after Meshy cats are imported"},{"name":"Window1","position":[3.1,2.32,-1.82],"usable":[4.4,2.7],"note":"Adjust after Meshy cats are imported"},{"name":"Window2","position":[8.75,2.32,-1.82],"usable":[4.4,2.7],"note":"Adjust after Meshy cats are imported"},{"name":"Climb0","position":[10.9,1.84,-5.5],"usable":[3.1,3.2],"note":"Cat size check pending"},{"name":"Climb1","position":[10.9,3.29,-8.9],"usable":[3.1,3.2],"note":"Cat size check pending"},{"name":"Climb2","position":[10.9,4.69,-12.5],"usable":[3.1,3.2],"note":"Cat size check pending"},{"name":"CubbyInside","position":[4.8,0.58,-8.7],"usable":[3.8,3.2],"openingHeight":2.72},{"name":"CubbyTop","position":[4.8,4.05,-8.7],"usable":[4.0,3.3]}],"meshNames":["C1_Lining_Wall","C1_Lining_OakDark","C1_Lining_TimberEdge","C1_Ceiling_OakLight","C1_Ceiling_TimberEdge","C1_Rug_SageSoft","C1_Rug_Rug","C1_Rug_Cream","C1_Threshold_Stone","C1_Lamp0_DarkMetal","C1_Lamp0_Cream","C1_Lamp0_OakDark","C1_Lamp1_DarkMetal","C1_Lamp1_Cream","C1_Lamp1_OakDark","C1_Lamp2_DarkMetal","C1_Lamp2_Cream","C1_Lamp2_OakDark","C1_Bench_Oak","C1_Bench_OakDark","C1_Bench_SageSoft","C1_Table0_OakLight","C1_Table0_OakDark","C1_Table0_Oak","C1_TableGoods0_White","C1_TableGoods0_Tea","C1_TableGoods0_Ceramic","C1_TableGoods0_OakDark","C1_Chair0_Oak","C1_Chair0_Indigo","C1_Chair0_OakLight","C1_Table1_OakLight","C1_Table1_OakDark","C1_Table1_Oak","C1_TableGoods1_White","C1_TableGoods1_Tea","C1_TableGoods1_Ceramic","C1_TableGoods1_Rose","C1_Chair1_Oak","C1_Chair1_Rose","C1_Chair1_OakLight","C1_Art_TimberEdge","C1_Art_Paper","C1_Art_SageSoft","C1_Counter_OakDark","C1_Counter_Oak","C1_Counter_OakLight","C1_Counter_TimberEdge","C1_Shelves_TimberEdge","C1_Shelves_OakLight","C1_TeaJars_White","C1_TeaJars_OakDark","C1_Cups_Ceramic","C1_Cups_Tea","C1_TeaJars_Ceramic","C1_Cups_White","C1_TeaService_Ceramic","C1_TeaService_OakDark","C1_TeaService_White","C1_TeaService_Tea","C1_Pastry_OakDark","C1_Pastry_White","C1_Pastry_Rose","C1_Pastry_Cream","C1_PastryCover_Glass","C1_CounterMenu_Paper","C1_WindowBench_OakLight","C1_WindowBench_Oak","C1_WindowBench_OakDark","C1_WindowBeds_SageSoft","C1_WindowBeds_Rose","C1_WindowBeds_Indigo","C1_Climb0_OakLight","C1_Climb0_OakDark","C1_Climb0_SageSoft","C1_Climb1_OakLight","C1_Climb1_OakDark","C1_Climb1_SageSoft","C1_Climb2_OakLight","C1_Climb2_OakDark","C1_Climb2_SageSoft","C1_Scratcher_OakDark","C1_Scratcher_Rope","C1_Cubby_OakLight","C1_Cubby_OakDark","C1_CubbyBeds_Rose","C1_CubbyBeds_Indigo","C1_Bowls_Oak","C1_Bowls_Ceramic","C1_Bowls_OakDark","C1_Bowls_Glass","C1_Origin","C1_Right","C1_Front"]}]==])
local floor=assert(shop:FindFirstChild("Shop floor"))
assert((floor.Position-Vector3.new(6024,.88985,7)).Magnitude<.1,"Cafe moved since survey")
local floorY=floor.Position.Y+floor.Size.Y/2
local target=CFrame.new(6014,floorY,7)*CFrame.Angles(0,-math.pi/2,0)
local facade=assert(shop:FindFirstChild("Traditional downtown facade"),"Retained facade missing")
local preserve={["Traditional downtown facade"]=true,["Shop floor"]=true,["Back wall"]=true,["Side wall"]=true,["Stone foundation"]=true,["Cedar corner post"]=true,["Exposed roof beam"]=true,["Lintel over open shop"]=true}
local retire={}
for _,v in ipairs(shop:GetChildren())do if not preserve[v.Name]then table.insert(retire,v)end end
local function map(root)
 local found={};local n=0
 for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")then
  assert(p:IsA("MeshPart") and p.Anchored,"Source contains an unanchored or non-mesh part")
  local key=p.Name:gsub("%.%d+$","");assert(not found[key],"Duplicate source name: "..key);found[key]=p;n+=1
 end end
 assert(n==#CONFIG.meshNames,"Unexpected source mesh count")
 for _,name in ipairs(CONFIG.meshNames)do assert(found[name],"Missing source mesh: "..name)end
 return found
end
local function frame(parts)
 local o=parts.C1_Origin.Position;local r=parts.C1_Right.Position-o;local f=parts.C1_Front.Position-o
 assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04,"Wrong import scale")
 assert(math.abs(r.Unit:Dot(f.Unit))<.001,"Bad placement marker angle")
 return CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
end
frame(map(source))
local fronts=J:FindFirstChild("ShopFronts")
local previous=fronts and fronts:FindFirstChild("CatCafe")
if previous then assert(previous:GetAttribute("CatCafeBuildVersion")=="cafe1","Unrelated cafe build exists")end
local hb=SS:FindFirstChild("HudBackup")
local backup=hb and hb:FindFirstChild("CatCafe1Originals")
if not previous then assert(not backup or #backup:GetChildren()==0,"Old cafe backup exists without installed front")end
local backs=assert(J:FindFirstChild("ShopBacks"));local backsCount=#backs:GetDescendants()
local facadeCount=#facade:GetDescendants()
local otherCounts={}
for _,v in ipairs(market:GetChildren())do if v~=shop then otherCounts[v]=#v:GetDescendants()end end
local oldFrontCounts={}
if fronts then for _,v in ipairs(fronts:GetChildren())do if v~=previous then oldFrontCounts[v]=#v:GetDescendants()end end end
local model=source:Clone();model.Name="CatCafe";model:SetAttribute("CatCafeBuildVersion","cafe1")
local parts=map(model);local sourceFrame=frame(parts)
local min=Vector3.new(math.huge,math.huge,math.huge);local max=Vector3.new(-math.huge,-math.huge,-math.huge)
local colliders=0
for name,p in pairs(parts)do
 p.CFrame=target*sourceFrame:ToObjectSpace(p.CFrame);p.Name=name
 if name~="C1_Origin" and name~="C1_Right" and name~="C1_Front"then
  local key=name:match("_([^_]+)$");local look=assert(CONFIG.materials[key],"Unmapped material")
  p.Color=Color3.fromRGB(table.unpack(look.rgb));p.Material=Enum.Material[look.material]
  -- The original FBX liquid caps sit below the closed cup mesh; lift just above it.
  if key=="Tea"then p.CFrame+=Vector3.new(0,.02,0);p:SetAttribute("TeaSurfaceLifted",true)end
  if (name:match("^C1_TableGoods%d_")or name:match("^C1_Pastry_"))and(key=="Rose"or key=="Cream")then p.Material=Enum.Material.SmoothPlastic end
  p.Transparency=key=="Glass" and .72 or 0;p.Anchored=true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=key~="Glass"
  local wood=(key=="Oak" or key=="OakDark" or key=="OakLight" or key=="Timber" or key=="TimberEdge")
  local furniture=name:find("^C1_Bench_")or name:find("^C1_Chair%d_")or name:find("^C1_Table%d_")or name:find("^C1_Counter_")or name:find("^C1_WindowBench_")or name:find("^C1_Climb%d_")or name:find("^C1_Scratcher_")or name:find("^C1_Cubby_")
  p.CanCollide=name=="C1_Threshold_Stone" or (wood and furniture~=nil)
  if p.CanCollide then colliders+=1 end
  for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
   local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z));min=min:Min(v);max=max:Max(v)
  end end end
 end
end
assert(min.X>6011.9 and max.X<6033.7,"Cafe kit leaves the measured depth")
assert(min.Z>-6 and max.Z<20,"Cafe kit leaves the measured width")
local faces={{Enum.NormalId.Front,Vector3.new(0,0,-1)},{Enum.NormalId.Back,Vector3.new(0,0,1)},{Enum.NormalId.Left,Vector3.new(-1,0,0)},{Enum.NormalId.Right,Vector3.new(1,0,0)},{Enum.NormalId.Top,Vector3.new(0,1,0)},{Enum.NormalId.Bottom,Vector3.new(0,-1,0)}}
for _,label in ipairs(CONFIG.labels)do
 local p=assert(parts[label.name]);local outward=target:VectorToWorldSpace(Vector3.new(table.unpack(label.front)))
 local face,dot=nil,-math.huge
 for _,f in ipairs(faces)do local d=p.CFrame:VectorToWorldSpace(f[2]):Dot(outward);if d>dot then face=f[1];dot=d end end
 assert(dot>.999,"Label not aligned")
 local gui=Instance.new("SurfaceGui");gui.Name="CafeLabel";gui.Face=face;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=100;gui.LightInfluence=.45;gui.Parent=p
 local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(.92,.85);text.Position=UDim2.fromScale(.04,.075);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(60,46,33);text.Font=Enum.Font.SourceSans;text.TextScaled=true;text.TextWrapped=true;text.Text=label.text;text.Parent=gui
end
local seats=Instance.new("Folder");seats.Name="VisitorSeats";seats.Parent=model
for _,spec in ipairs(CONFIG.seats)do
 local p=Instance.new("Seat");p.Name=spec.name;p.Size=Vector3.new(1.7,.15,1.7)
 local pos=target:PointToWorldSpace(Vector3.new(table.unpack(spec.position)));local look=target:VectorToWorldSpace(Vector3.new(table.unpack(spec.look)))
 p.CFrame=CFrame.lookAt(pos,pos+look);p.Transparency=1;p.Anchored=true;p.CanCollide=true;p.CanTouch=true;p.CanQuery=true;p.CastShadow=false;p.Parent=seats
end
for i,spot in ipairs({{-7.7,7.05,-11.9},{1.6,7.05,-7.2},{7.2,7.05,-16.2}})do
 local p=assert(parts["C1_Lamp"..(i-1).."_Cream"])
 local a=Instance.new("Attachment");a.Name="LampPosition";a.Position=p.CFrame:PointToObjectSpace(target:PointToWorldSpace(Vector3.new(table.unpack(spot))));a.Parent=p
 local l=Instance.new("PointLight");l.Color=Color3.fromRGB(255,222,180);l.Brightness=.8;l.Range=13;l.Shadows=false;l.Parent=a
end
-- Four hot mugs already exist in kit23: add a quiet wisp at each tea surface.
-- Orient attachments through the placement frame so steam rises upright after FBX import.
local steamingMugs=0
for i,x in ipairs({-10.05,-5.75})do
 local p=assert(parts["C1_TableGoods"..(i-1).."_Tea"])
 for mug,offset in ipairs({{-.5,.25},{.6,-.1}})do
  local a=Instance.new("Attachment");a.Name="TeaSteam"..mug
  a.CFrame=p.CFrame:ToObjectSpace(target*CFrame.new(x+offset[1],3.67,-11.6+offset[2]));a.Parent=p
  local steam=Instance.new("ParticleEmitter");steam.Name="GentleTeaSteam"
  steam.Texture="rbxasset://textures/particles/smoke_main.dds"
  steam.Color=ColorSequence.new(Color3.fromRGB(145,154,158))
  steam.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.12),NumberSequenceKeypoint.new(.4,.3),NumberSequenceKeypoint.new(1,.6)})
  steam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,.38),NumberSequenceKeypoint.new(.6,.7),NumberSequenceKeypoint.new(1,1)})
  steam.Rate=18;steam.Lifetime=NumberRange.new(1.3,1.9);steam.Speed=NumberRange.new(.45,.7)
  steam.Acceleration=target:VectorToWorldSpace(Vector3.new(.035,.12,0))
  steam.EmissionDirection=Enum.NormalId.Top;steam.SpreadAngle=Vector2.new(9,9)
  steam.Rotation=NumberRange.new(0,360);steam.RotSpeed=NumberRange.new(-18,18)
  steam.LightEmission=0;steam.LightInfluence=0;steam.VelocityInheritance=0
  steam.LockedToPart=false;steam.Enabled=true;steam.Parent=a
  steamingMugs+=1
 end
end
-- Metadata only. Meshy cats remain Shannon's assets; fit/animate after she imports them.
model:SetAttribute("CatSpotsLocalJSON",game:GetService("HttpService"):JSONEncode(CONFIG.catSpots))
model:SetAttribute("CatsPendingImport",true)
model.WorldPivot=target
pcall(function()model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic end)
parts.C1_Origin:Destroy();parts.C1_Right:Destroy();parts.C1_Front:Destroy()
if not hb then hb=Instance.new("Folder");hb.Name="HudBackup";hb.Parent=SS end
if not backup then backup=Instance.new("Folder");backup.Name="CatCafe1Originals";backup.Parent=hb end
if not fronts then fronts=Instance.new("Folder");fronts.Name="ShopFronts";fronts.Parent=J end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("Before Cat cafe1")end)
local ok,err=pcall(function()
 for _,v in ipairs(retire)do v:SetAttribute("CatCafe1WasIn",shop:GetFullName());v.Parent=backup end
 if previous then previous.Parent=nil end
 model.Parent=fronts
 assert(#backs:GetDescendants()==backsCount and #facade:GetDescendants()==facadeCount,"Existing backs or facade changed")
 for v,n in pairs(otherCounts)do assert(v.Parent==market and #v:GetDescendants()==n,"Other market shop changed")end
 for v,n in pairs(oldFrontCounts)do assert(v.Parent==fronts and #v:GetDescendants()==n,"Other installed front changed")end
end)
if not ok then
 model:Destroy();for _,v in ipairs(retire)do v.Parent=shop;v:SetAttribute("CatCafe1WasIn",nil)end
 if previous then previous.Parent=fronts end
 error("Cafe install reverted: "..tostring(err))
end
if previous then previous:Destroy()end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("After Cat cafe1")end)
print(string.format("QQ CATCAFE1 DONE: %d meshes, %d visitor Seats, %d reserved cat spots, %d collidable meshes; %d old fixtures backed up",#CONFIG.meshNames-3,#CONFIG.seats,#CONFIG.catSpots,colliders,#retire))
print(string.format("QQ CATCAFE1 BOUNDS: x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f",min.X,max.X,min.Y,max.Y,min.Z,max.Z))
print("QQ CATCAFE1 PRESERVED: existing facade, roof, upper floor, walls and floor; all other shops/fronts and ShopBacks")
print(string.format("QQ CATCAFE1 TEA: %d steaming table mugs; subtle particle wisps",steamingMugs))
print("QQ CATCAFE1 CATS: not imported; cat spots are adjustable placeholders in metadata only")
print("QQ CATCAFE1 STATUS: "..(Run:IsRunning() and "PLAY-TEST SERVER PREVIEW ONLY; discarded on stop" or "EDIT; NOT PUBLISHED"))
-- After approved Edit installation, set precise collision on placed collidable
-- MeshParts in a separate call, then verify readback and a fresh play walk/seat test.

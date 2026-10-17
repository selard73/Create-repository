-- Separate, larger cafe interior. Preview on Server; install only after picture approval.
-- Source import must be anchored/stored before Play. No publishing or DataStore writes.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong environment")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and CAFECOZY3_ALLOW_EDIT==true),"Server preview first; Edit requires picture approval")
local DATA=game:GetService("HttpService"):JSONDecode([==[{"root":"cafe_interior2","layout":{"room":{"width":34,"depth":28,"height":11.3,"origin":[6014,1200,7],"yaw":-90,"doorX":-11},"groups":{"C1_Bench":[-3.5,0,-7.35],"C1_Table0":[-2.95,0,-5.7],"C1_TableGoods0":[-2.95,0,-5.7],"C1_Table1":[-0.55,0,-5.7],"C1_TableGoods1":[-0.55,0,-5.7],"C1_Chair0":[-2.95,0,-5.0],"C1_Chair1":[-0.55,0,-5.0],"C1_Art":[-3.5,0,-8.6],"C1_Counter":[2.9,0,-8.2],"C1_CounterMenu":[2.9,0,-8.2],"C1_Shelves":[2.9,0.4,-8.9],"C1_TeaJars":[2.9,0.4,-8.9],"C1_Cups":[2.9,0.4,-8.9],"C1_TeaService":[2.9,0,-8.2],"C1_Pastry":[2.9,0,-8.2],"C1_PastryCover":[2.9,0,-8.2],"C1_WindowBench":[1.4,0,0],"C1_WindowBeds":[1.4,0,0],"C1_Climb0":[4.5,0,-7.3],"C1_Climb1":[4.5,0.5,-8.1],"C1_Climb2":[4.5,2.4,-8.7],"C1_Scratcher":[4.5,0,-3.9],"C1_Cubby":[7.8,0,0.65],"C1_CubbyBeds":[7.8,0,0.65],"C1_Bowls":[4.3,0,-6.5],"C1_Lamp0":[-3.1,3.2,-5.6],"C1_Lamp1":[0.0,3.2,-1.3],"C1_Lamp2":[2.5,3.2,-6.1]},"wallDecorDelta":[-4.4,1.0,-5.0],"seats":[{"name":"BenchSeat0","position":[-14.15,1.96,-24.0],"look":[0,0,1],"reserved":true},{"name":"BenchSeat1","position":[-11.4,1.96,-24.0],"look":[0,0,1]},{"name":"BenchSeat2","position":[-8.65,1.96,-24.0],"look":[0,0,1]},{"name":"ChairSeat0","position":[-13.0,1.99,-12.7],"look":[0,0,-1]},{"name":"ChairSeat1","position":[-6.3,1.99,-12.7],"look":[0,0,-1]}],"cats":[{"name":"Whisker_Wonder","position":[-5.1,-0.5798532,2.15],"yaw":-15,"scale":0.9,"outside":true,"spot":"SeatedDoorwayGreeter"},{"name":"Emerald_Eyed_Tabby_Ki","position":[4.5,2.32,-1.82],"yaw":125,"scale":0.93,"spot":"SingleWindowCat"},{"name":"Tuxedo_Kitten","position":[14.3,0.01,-19.4],"yaw":180,"scale":0.9,"spot":"BesideFoodBowls"},{"name":"Ginger_Whiskers","position":[15.15,7.09,-21.2],"yaw":-140,"scale":0.94,"spot":"HighPerchPounce"},{"name":"Curious_Little_Tabby","position":[-4.3,0.01,-24.0],"yaw":25,"scale":0.9,"spot":"BesideBenchFloor"},{"name":"Blush_Eared_Kitten","position":[12.6,0.58,-7.2],"yaw":-5,"scale":0.84,"spot":"InsideCubby"},{"name":"Adorable_Tabby_Kitten","position":[-14.15,1.95,-24.0],"yaw":20,"scale":1,"spot":"CornerBench"}]},"materials":{"Oak":{"rgb":[163,119,77],"material":"Wood"},"OakLight":{"rgb":[190,150,104],"material":"Wood"},"OakDark":{"rgb":[116,81,52],"material":"Wood"},"Timber":{"rgb":[65,47,35],"material":"Wood"},"TimberEdge":{"rgb":[87,62,42],"material":"Wood"},"Wall":{"rgb":[231,223,201],"material":"SmoothPlastic"},"Paper":{"rgb":[236,220,179],"material":"SmoothPlastic"},"Cream":{"rgb":[236,228,209],"material":"SmoothPlastic"},"SageSoft":{"rgb":[132,151,121],"material":"Fabric"},"Rug":{"rgb":[207,195,158],"material":"Fabric"},"Washilight":{"rgb":[237,232,209],"material":"SmoothPlastic"},"Ink":{"rgb":[60,46,33],"material":"SmoothPlastic"},"Indigo":{"rgb":[66,87,105],"material":"SmoothPlastic"}},"meshes":[{"name":"CI2_FloorBase_OakDark","min":[-17.200000762939453,-0.28999999165534973,-28.200000762939453],"max":[17.200000762939453,-0.10999999940395355,0.20000000298023224],"triangles":12,"collide":true},{"name":"CI2_Floor_Oak","min":[-16.987499237060547,-0.12999999523162842,-27.989999771118164],"max":[16.987499237060547,0.0,-0.009999999776482582],"triangles":1056,"collide":true},{"name":"CI2_Floor_OakLight","min":[-16.987499237060547,-0.12999999523162842,-27.989999771118164],"max":[16.987499237060547,0.0,-0.009999999776482582],"triangles":1044,"collide":true},{"name":"CI2_Floor_OakDark","min":[-15.987500190734863,-0.12999999523162842,-27.989999771118164],"max":[15.987500190734863,0.0,-0.009999999776482582],"triangles":756,"collide":true},{"name":"CI2_LeftWall_Wall","min":[-17.200000762939453,0.0,-28.200000762939453],"max":[-17.0,11.300000190734863,0.20000000298023224],"triangles":12,"collide":true},{"name":"CI2_RightWall_Wall","min":[17.0,0.0,-28.200000762939453],"max":[17.200000762939453,11.300000190734863,0.20000000298023224],"triangles":12,"collide":true},{"name":"CI2_BackWall_Wall","min":[-17.200000762939453,0.0,-28.200000762939453],"max":[17.200000762939453,11.300000190734863,-28.0],"triangles":12,"collide":true},{"name":"CI2_FrontLeft_Wall","min":[-17.200000762939453,0.0,-0.0],"max":[-14.0,11.300000190734863,0.20000000298023224],"triangles":12,"collide":true},{"name":"CI2_FrontRight_Wall","min":[-8.0,0.0,-0.0],"max":[17.200000762939453,11.300000190734863,0.20000000298023224],"triangles":12,"collide":true},{"name":"CI2_DoorHeader_Wall","min":[-14.0,8.0,-0.0],"max":[-8.0,11.300000190734863,0.20000000298023224],"triangles":12,"collide":true},{"name":"CI2_VestibuleFloor_Oak","min":[-14.199999809265137,-0.12999999523162842,-0.0],"max":[-7.800000190734863,0.0,2.799999952316284],"triangles":12,"collide":true},{"name":"CI2_VestibuleLeft_Wall","min":[-14.199999809265137,0.0,-0.0],"max":[-14.0,11.300000190734863,2.799999952316284],"triangles":12,"collide":true},{"name":"CI2_VestibuleRight_Wall","min":[-8.0,0.0,-0.0],"max":[-7.800000190734863,11.300000190734863,2.799999952316284],"triangles":12,"collide":true},{"name":"CI2_VestibuleEnd_Wall","min":[-14.199999809265137,0.0,2.5999999046325684],"max":[-7.800000190734863,11.300000190734863,2.799999952316284],"triangles":12,"collide":true},{"name":"CI2_CeilingBase_OakDark","min":[-17.200000762939453,11.300000190734863,-28.200000762939453],"max":[17.200000762939453,11.479999542236328,2.799999952316284],"triangles":12,"collide":true},{"name":"CI2_Ceiling_OakLight","min":[-17.0,11.260000228881836,-27.71500015258789],"max":[17.0,11.319999694824219,-0.02500000037252903],"triangles":504,"collide":false},{"name":"CI2_Beams_TimberEdge","min":[-17.0,10.800000190734863,-27.829999923706055],"max":[17.0,11.239999771118164,-0.17000000178813934],"triangles":60,"collide":false},{"name":"CI2_Posts_TimberEdge","min":[-16.969999313354492,0.0,-27.84000015258789],"max":[16.969999313354492,11.100000381469727,-0.1599999964237213],"triangles":120,"collide":false},{"name":"CI2_LeftWainscot_OakDark","min":[-17.010000228881836,0.0,-27.7549991607666],"max":[-16.950000762939453,1.7999999523162842,-0.04500000178813934],"triangles":444,"collide":false},{"name":"CI2_LeftRail_TimberEdge","min":[-17.03499984741211,1.7999999523162842,-28.0],"max":[-16.924999237060547,9.460000038146973,-0.0],"triangles":24,"collide":false},{"name":"CI2_RightWainscot_OakDark","min":[16.950000762939453,0.0,-27.7549991607666],"max":[17.010000228881836,1.7999999523162842,-0.04500000178813934],"triangles":444,"collide":false},{"name":"CI2_RightRail_TimberEdge","min":[16.924999237060547,1.7999999523162842,-28.0],"max":[17.03499984741211,9.460000038146973,-0.0],"triangles":24,"collide":false},{"name":"CI2_BackWainscot_OakDark","min":[-16.854999542236328,0.0,-28.010000228881836],"max":[16.854999542236328,1.7999999523162842,-27.950000762939453],"triangles":540,"collide":false},{"name":"CI2_BackRail_TimberEdge","min":[-17.0,1.7999999523162842,-28.014999389648438],"max":[17.0,9.460000038146973,-27.905000686645508],"triangles":24,"collide":false},{"name":"CI2_Shoji_Washilight","min":[-7.670000076293945,2.0,-0.07500000298023224],"max":[15.869999885559082,7.5,-0.014999999664723873],"triangles":60,"collide":false},{"name":"CI2_WindowFrame_TimberEdge","min":[-7.800000190734863,1.8700000047683716,-0.17000000178813934],"max":[16.0,7.630000114440918,-0.05000000074505806],"triangles":240,"collide":false},{"name":"CI2_Lattice_Oak","min":[-7.670000076293945,2.0,-0.17000000178813934],"max":[15.869999885559082,7.5,-0.09000000357627869],"triangles":540,"collide":false},{"name":"CI2_DoorFrame_Timber","min":[-14.125,0.0,-0.18000000715255737],"max":[-7.875,8.225000381469727,0.10000000149011612],"triangles":36,"collide":false},{"name":"CI2_Noren_SageSoft","min":[-13.970000267028809,5.610000133514404,-0.0625],"max":[-8.029999732971191,7.989999771118164,-0.017500000074505806],"triangles":24,"collide":false},{"name":"CI2_NorenPaw_Cream","min":[-12.890000343322754,6.460000038146973,-0.09799999743700027],"max":[-9.109999656677246,7.21999979019165,-0.06199999898672104],"triangles":1408,"collide":false},{"name":"CI2_Rug_SageSoft","min":[-16.549999237060547,0.0005000000237487257,-26.600000381469727],"max":[-5.050000190734863,0.03550000116229057,-12.199999809265137],"triangles":12,"collide":false},{"name":"CI2_Rug_Rug","min":[-16.299999237060547,0.03500000014901161,-26.350000381469727],"max":[-5.300000190734863,0.04699999839067459,-12.449999809265137],"triangles":12,"collide":false},{"name":"CI2_Rug_Cream","min":[-16.100000381469727,0.04600000008940697,-25.912500381469727],"max":[-5.5,0.05400000140070915,-13.237500190734863],"triangles":288,"collide":false},{"name":"CI2_Origin","min":[-0.02500000037252903,-0.02500000037252903,-0.02500000037252903],"max":[0.02500000037252903,0.02500000037252903,0.02500000037252903],"triangles":12,"collide":false},{"name":"CI2_Right","min":[1.975000023841858,-0.02500000037252903,-0.02500000037252903],"max":[2.0250000953674316,0.02500000037252903,0.02500000037252903],"triangles":12,"collide":false},{"name":"CI2_Front","min":[-0.02500000037252903,-0.02500000037252903,1.975000023841858],"max":[0.02500000037252903,0.02500000037252903,2.0250000953674316],"triangles":12,"collide":false}]}]==])
local L=DATA.layout
local SS=game:GetService("ServerStorage");local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService");local SPS=game:GetService("StarterPlayer").StarterPlayerScripts
local J=assert(workspace:FindFirstChild("JapanMap"));local fronts=assert(J:FindFirstChild("ShopFronts"))
local kit=assert(SS:FindFirstChild("JapanGardenKit"));local src=assert(kit:FindFirstChild("cafe_interior2"),"Import kit29 and prepare the source BEFORE Play")
assert(src:GetAttribute("CafeInteriorSourceVersion")=="interior2","Source preparation missing")
local hb=assert(SS:FindFirstChild("HudBackup"));local backup=hb:FindFirstChild("CafeInterior2Originals")
local current=assert(fronts:FindFirstChild("CatCafe"));local previous=fronts:FindFirstChild("CatCafeInterior")
if previous then assert(previous:GetAttribute("CafeInteriorVersion")=="interior2","Unrelated interior exists")end
local original=backup and backup:FindFirstChild("CatCafe")or current
assert(original:GetAttribute("CatCafeBuildVersion")=="cafe1","Unexpected original cafe")
local originalCats=assert(original:FindFirstChild("Cats"));local idle=assert(originalCats:FindFirstChild("CafeCatsClient"))
local wallDecor=assert(original:FindFirstChild("LeftWallDecor"));local oldSeats=assert(original:FindFirstChild("VisitorSeats"))
local market=J["Outdoor market revision"];local shell=market["Cat cafe"];local floor=shell["Shop floor"]
assert((floor.Position-Vector3.new(6024,.88985,7)).Magnitude<.1,"Street cafe moved; remeasure")
local streetFrame=CFrame.new(6014,floor.Position.Y+floor.Size.Y/2,7)*CFrame.Angles(0,-math.pi/2,0)
local frame=CFrame.new(table.unpack(L.room.origin))*CFrame.Angles(0,math.rad(L.room.yaw),0)
for _,p in ipairs(workspace:GetPartBoundsInBox(frame*CFrame.new(0,5.6,-12.7),Vector3.new(36,14,33)))do
 assert(previous and p:IsDescendantOf(previous),"New interior location is occupied: "..p:GetFullName())
end
for _,p in ipairs(game.Players:GetPlayers())do
 local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 assert(not(h and h.SeatPart and h.SeatPart:IsDescendantOf(current)),"Stand up from the old cafe seat before preparing the larger-room preview")
 assert(not r or math.abs(r.Position.Y-frame.Position.Y)>30,"Move outside the interior before rebuilding its preview")
end
local expected={};for _,m in ipairs(DATA.meshes)do expected[m.name]=m end
local source={};local count=0
for _,p in ipairs(src:GetDescendants())do if p:IsA("BasePart")then
 assert(p:IsA("MeshPart")and p.Anchored and expected[p.Name]and not source[p.Name],"Unexpected source mesh");source[p.Name]=p;count+=1
end end
assert(count==#DATA.meshes,"Wrong source count");for name in pairs(expected)do assert(source[name],"Missing source: "..name)end
local o=source.CI2_Origin.Position;local r=source.CI2_Right.Position-o;local f=source.CI2_Front.Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04 and math.abs(r.Unit:Dot(f.Unit))<.001,"Incorrect import scale/orientation")
local sourceFrame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
local function bounds(p,cf)
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
 local q=cf:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)));lo=lo:Min(q);hi=hi:Max(q)
 end end end
 return lo,hi
end
for name,p in pairs(source)do
 local lo,hi=bounds(p,sourceFrame);local m=expected[name]
 assert((lo-Vector3.new(table.unpack(m.min))).Magnitude<.08 and(hi-Vector3.new(table.unpack(m.max))).Magnitude<.08,"Imported bounds differ: "..name)
end
local lamps={};local facade=shell["Traditional downtown facade"]
for _,v in ipairs(facade:GetChildren())do
 if v:IsA("BasePart")and v.Name=="Warm shop wall lamp"and(streetFrame:PointToObjectSpace(v.Position)-Vector3.new(-9.36,6.510147,-.600097)).Magnitude<.02 then table.insert(lamps,v)end
end
assert(#lamps<=1,"Ambiguous doorway lamp")
local music=workspace.MapMusic;local musicSource=music.MusicClient.Source
assert(musicSource:find("CATCAFE1_AUDIO_20261017",1,true)and musicSource:find("CATCAFE1_MEOWS_20261017",1,true),"Existing cafe audio missing")
local oldMusicFrame=music:GetAttribute("JapanCatCafeFrame");local oldMusicHalf=music:GetAttribute("JapanCatCafeHalfSize")
local oldLink=RS:FindFirstChild("CafeInterior2Link");local oldService=SSS:FindFirstChild("CafeInterior2Doorway");local oldClient=SPS:FindFirstChild("CafeInterior2DoorwayClient")
for _,v in pairs({oldLink,oldService,oldClient})do if v then assert(v:GetAttribute("CafeInteriorVersion")=="interior2","Unrelated doorway controller")end end
local preserved={}
for i,v in ipairs(J:GetDescendants())do
 if v~=current and not v:IsDescendantOf(current)and not(previous and(v==previous or v:IsDescendantOf(previous)))and v~=lamps[1]and not(lamps[1]and v:IsDescendantOf(lamps[1]))then
  local a={v=v,parent=v.Parent,name=v.Name}
  if v:IsA("BasePart")then a.cf=v.CFrame;a.size=v.Size;a.color=v.Color;a.material=v.Material;a.transparency=v.Transparency;a.collide=v.CanCollide;a.anchored=v.Anchored end
  table.insert(preserved,a)
 end
 if i%750==0 then task.wait()end
end
local function verify()
 for i,a in ipairs(preserved)do local v=a.v
  assert(v.Parent==a.parent and v.Name==a.name,"Unrelated object moved: "..a.name)
  if a.cf then assert(v.CFrame==a.cf and v.Size==a.size and v.Color==a.color and v.Material==a.material and v.Transparency==a.transparency and v.CanCollide==a.collide and v.Anchored==a.anchored,"Unrelated part changed: "..a.name)end
  if i%750==0 then task.wait()end
 end
 assert(music.MusicClient.Source==musicSource,"Music controller source changed")
end
local room=Instance.new("Model");room.Name="CatCafeInterior";room:SetAttribute("CafeInteriorVersion","interior2");room.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local architecture=Instance.new("Model");architecture.Name="Architecture";architecture.Parent=room
local shellCount=0
for name,p in pairs(source)do if name~="CI2_Origin"and name~="CI2_Right"and name~="CI2_Front"then
 local c=p:Clone();c.CFrame=frame*sourceFrame:ToObjectSpace(p.CFrame)
 local look=DATA.materials[name:match("_([^_]+)$")];assert(look,"Unknown shell material")
 c.Color=Color3.fromRGB(table.unpack(look.rgb));c.Material=Enum.Material[look.material]
 c.Anchored=true;c.CanCollide=expected[name].collide;c.CanTouch=false;c.CanQuery=true;c.Transparency=0;c.Parent=architecture;shellCount+=1
end end
local furniture=Instance.new("Model");furniture.Name="Furniture";furniture.Parent=room
local furnitureCount=0;local matched={}
for _,p in ipairs(original:GetChildren())do if p:IsA("MeshPart")then
 local group=p.Name:match("^(.*)_[^_]+$");local delta=L.groups[group]
 if delta then
  local c=p:Clone();c.CFrame=frame*CFrame.new(table.unpack(delta))*streetFrame:ToObjectSpace(p.CFrame);c.Anchored=true;c.CanTouch=false;c.Parent=furniture
  assert(c.Size==p.Size,"Furniture dimensions changed")
  for _,light in ipairs(c:GetDescendants())do if light:IsA("PointLight")then light.Range=20;light.Brightness=.85 end end
  furnitureCount+=1;matched[group]=true
 end
end end
for group in pairs(L.groups)do assert(matched[group],"Missing furniture group: "..group)end
assert(furnitureCount==82,"Unexpected furniture count")
local decor=wallDecor:Clone();decor.Name="LeftWallDecor"
for _,p in ipairs(decor:GetDescendants())do if p:IsA("BasePart")then p.CFrame=frame*CFrame.new(table.unpack(L.wallDecorDelta))*streetFrame:ToObjectSpace(p.CFrame)end end
decor.Parent=room
local seats=Instance.new("Folder");seats.Name="VisitorSeats";seats.Parent=room
for _,s in ipairs(L.seats)do
 local seat=assert(oldSeats:FindFirstChild(s.name)):Clone();local pos=frame:PointToWorldSpace(Vector3.new(table.unpack(s.position)));local look=frame:VectorToWorldSpace(Vector3.new(table.unpack(s.look)))
 seat.CFrame=CFrame.lookAt(pos,pos+look);seat.Anchored=true;seat.Disabled=s.reserved==true;seat:SetAttribute("ReservedForCafeCat",s.reserved==true)
 for _,v in ipairs(seat:GetChildren())do if v:IsA("Weld")and v.Name=="SeatWeld"then v:Destroy()end end
 seat.Parent=seats
end
-- The street-facing furnished view stays in place, without visitor Seats or duplicate cats.
local display=original:Clone();display.Name="CatCafe";display.Cats:Destroy();display.VisitorSeats:Destroy();display.CafeCamera:Destroy()
display:SetAttribute("CafeInteriorLinked",true)
local insideCats=Instance.new("Model");insideCats.Name="Cats";insideCats:SetAttribute("CafeCatsVersion","cats3");insideCats.Parent=room
local outsideCats=Instance.new("Model");outsideCats.Name="Cats";outsideCats:SetAttribute("CafeCatsVersion","cats3");outsideCats.Parent=display
local catCount,boneCount=0,0
for _,s in ipairs(L.cats)do
 local cat=assert(originalCats:FindFirstChild(s.name)):Clone();local n=0
 for _,b in ipairs(cat:GetDescendants())do if b:IsA("Bone")then b.Transform=CFrame.identity;n+=1 end end
 assert(n==10,"Incorrect cat rig")
 cat:ScaleTo((cat:GetAttribute("CafeSpread2OriginalScale")or cat:GetScale())*s.scale)
 cat:PivotTo((s.outside and streetFrame or frame)*CFrame.new(table.unpack(s.position))*CFrame.Angles(0,math.rad(s.yaw),0));cat:SetAttribute("CatSpot",s.spot)
 cat.Parent=s.outside and outsideCats or insideCats;catCount+=1;boneCount+=n
end
assert(catCount==7 and boneCount==70)
for _,parent in ipairs({insideCats,outsideCats})do local c=idle:Clone();c.Parent=parent end
local camera=Instance.new("Script");camera.Name="CafeCamera";camera.RunContext=Enum.RunContext.Client;camera.Source=[====[-- Keep the normal orbit controls, but keep the camera's near plane inside this room.
-- The fitted lining is a non-collidable U-shaped mesh; the default camera only sees
-- the outer structural walls and can slip into the gap behind that lining.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local cafe=script.Parent
local binding="CatCafeCamera_"..game:GetService("HttpService"):GenerateGUID(false)
local roomMin=Vector3.new(-16.80,.12,-27.80)
local roomMax=Vector3.new(16.80,9.15,-.15)

local function fitCamera(frame,focus,desired,fov,aspect,near)
 local halfY=math.tan(math.rad(fov)*.5)*near
 local halfX=halfY*aspect
 local lower,upper=roomMin,roomMax
 -- Include both the camera itself and all four corners of its near plane.
 for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do
  local offset=frame:VectorToObjectSpace(desired.LookVector*near+desired.RightVector*(x*halfX)+desired.UpVector*(y*halfY))
  lower=lower:Max(roomMin-offset);upper=upper:Min(roomMax-offset)
 end end
 if lower.X>upper.X or lower.Y>upper.Y or lower.Z>upper.Z then return desired end
 local anchor=frame:PointToObjectSpace(focus)
 anchor=Vector3.new(math.clamp(anchor.X,lower.X,upper.X),math.clamp(anchor.Y,lower.Y,upper.Y),math.clamp(anchor.Z,lower.Z,upper.Z))
 local destination=frame:PointToObjectSpace(desired.Position)
 local delta=destination-anchor
 local t=1
 for _,axis in ipairs({"X","Y","Z"})do
  local d=delta[axis]
  if d>1e-6 then t=math.min(t,(upper[axis]-anchor[axis])/d)
  elseif d< -1e-6 then t=math.min(t,(lower[axis]-anchor[axis])/d)end
 end
 if t>=1 then return desired end
 local position=frame:PointToWorldSpace(anchor+delta*math.max(t,0))
 return CFrame.new(position)*desired.Rotation
end

RunService:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+1,function()
 local camera=workspace.CurrentCamera
 if not camera or (camera.CameraType~=Enum.CameraType.Custom and camera.CameraType~=Enum.CameraType.Follow)then return end
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local humanoid=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 local frame=cafe:GetPivot()
 local p=frame:PointToObjectSpace(root.Position)
 if math.abs(p.X)>17.3 or p.Y< -.5 or p.Y>12.0 or p.Z< -28.3 or p.Z>1.5 then return end
 local view=camera.ViewportSize
 camera.CFrame=fitCamera(frame,camera.Focus.Position,camera.CFrame,camera.FieldOfView,view.X/math.max(view.Y,1),math.abs(camera.NearPlaneZ))
end)
script.Destroying:Connect(function()RunService:UnbindFromRenderStep(binding)end)
]====];camera.Parent=room
room.WorldPivot=frame;display.WorldPivot=streetFrame
local bridge=Instance.new("Folder");bridge.Name="CafeInterior2Link";bridge:SetAttribute("CafeInteriorVersion","interior2");bridge:SetAttribute("StreetFrame",streetFrame);bridge:SetAttribute("RoomFrame",frame)
local event=Instance.new("RemoteEvent");event.Name="Transition";event.Parent=bridge
local server=Instance.new("Script");server.Name="CafeInterior2Doorway";server.Enabled=false;server.Source=[====[-- Same-server doorway transition. Only the server detects doors and chooses destinations.
-- Client messages can acknowledge an active transition; they cannot request coordinates.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local bridge=game:GetService("ReplicatedStorage"):WaitForChild("CafeInterior2Link")
local event=bridge:WaitForChild("Transition")
local room=workspace.JapanMap.ShopFronts:WaitForChild("CatCafeInterior")
local streetFrame=bridge:GetAttribute("StreetFrame")
local roomFrame=bridge:GetAttribute("RoomFrame")
local active={};local cooldown={};local serial=0;local alive=true
local function character(player)
 local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
 if c and h and r and h.Health>0 then return c,h,r end
end
local entryPrompt=workspace.JapanMap.ShopFronts.CatCafe:WaitForChild("EntranceDoor"):WaitForChild("Door_Reveal"):WaitForChild("DoorInteraction"):WaitForChild("EnterCafe")
local exitPrompt=room:WaitForChild("ExitDoor"):WaitForChild("Door_Reveal"):WaitForChild("DoorInteraction"):WaitForChild("ExitCafe")
local function canUseDoor(root,inside)
 local prompt=inside and entryPrompt or exitPrompt
 if not prompt.Enabled or (root.Position-prompt.Parent.WorldPosition).Magnitude>8.5 then return false end
 local q=(inside and streetFrame or roomFrame):PointToObjectSpace(root.Position)
 local x=inside and -9.36 or -11
 return math.abs(q.X-x)<4.5 and q.Y>-.5 and q.Y<8 and (inside and q.Z>=-.3 and q.Z<8 or not inside and q.Z<.3 and q.Z> -8)
end
local function send(player,...)
 if player.Parent==Players then event:FireClient(player,...)end
end
local function finish(player,success,reason)
 local s=active[player];if not s then return end
 active[player]=nil;cooldown[player]=os.clock()+2
 -- Cleanup must also release a dead or recently replaced character's root.
 if s.root.Parent then
  if not success and s.moved and s.char.Parent then s.char:PivotTo(s.originalPivot)end
  s.root.AssemblyLinearVelocity=Vector3.zero;s.root.AssemblyAngularVelocity=Vector3.zero;s.root.Anchored=s.wasAnchored
 end
 if success then player:SetAttribute("InCatCafeInterior",s.inside)end
 send(player,success and "FadeIn"or"Abort",s.token,reason)
end
local function begin(player,inside)
 local c,h,r=character(player)
 if not c or active[player] or os.clock()<(cooldown[player]or 0) or r.Anchored or h.SeatPart or h.Sit or not canUseDoor(r,inside) then return end
 serial+=1
 active[player]={char=c,root=r,token=serial,inside=inside,phase="Fading",deadline=os.clock()+10,wasAnchored=r.Anchored,originalPivot=c:GetPivot(),moved=false}
 r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;r.Anchored=true
 send(player,"FadeOut",serial,inside)
end
local connection=event.OnServerEvent:Connect(function(player,action,token)
 local s=active[player]
 if not s or type(token)~="number" or token~=s.token then return end
 local c,h,r=character(player)
 if c~=s.char or r~=s.root then finish(player,false,"Character changed");return end
 if action=="Ready" and s.phase=="Arrived" then finish(player,true);return end
 if action=="Abort"then finish(player,false,"Doorway is not ready. Please try again.");return end
 if action~="Faded"or s.phase~="Fading"then return end
 s.phase="Loading"
 local cf=s.inside and roomFrame or streetFrame
 local localPos=s.inside and Vector3.new(-11,0,-5.2) or Vector3.new(-9.36,-.5798532,3.0)
 local ground=cf:PointToWorldSpace(localPos)
 local target=ground+Vector3.new(0,h.HipHeight+r.Size.Y/2+.12,0)
 local look=cf:VectorToWorldSpace(s.inside and Vector3.new(0,0,-1)or Vector3.new(0,0,1))
 local ok,err=pcall(function()
  player:RequestStreamAroundAsync(target,3)
  if not alive or active[player]~=s then return end
  local nowChar,nowHum,nowRoot=character(player)
  if nowChar~=c or nowRoot~=r then error("Character changed")end
  -- Preserve the character pivot offset while positioning the root exactly.
  local desired=CFrame.lookAt(target,target+look)
  c:PivotTo(desired*r.CFrame:ToObjectSpace(c:GetPivot()));s.moved=true
  r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
  s.phase="Arrived";send(player,"Arrived",s.token,s.inside,target)
 end)
 if not ok then warn("Cafe doorway transition interrupted: "..tostring(err));finish(player,false,"Doorway is not ready. Please try again.")end
end)
local removed=Players.PlayerRemoving:Connect(function(p)
 local s=active[p];if s and s.root.Parent then s.root.Anchored=s.wasAnchored end
 active[p]=nil;cooldown[p]=nil
end)
-- A prompt press is the only way to begin. Walking into either door never starts a transition.
local entryConnection=entryPrompt.Triggered:Connect(function(p)begin(p,true)end)
local exitConnection=exitPrompt.Triggered:Connect(function(p)begin(p,false)end)
task.spawn(function()
 while alive and script.Parent do
  local now=os.clock()
  for _,p in ipairs(Players:GetPlayers())do
   local s=active[p]
   if s then
    local c=character(p)
    if c~=s.char or now>s.deadline then finish(p,false,"Doorway is not ready. Please try again.")end
   else
    local c,h,r=character(p)
    if r and p:GetAttribute("InCatCafeInterior") and math.abs(r.Position.Y-roomFrame.Position.Y)>30 then p:SetAttribute("InCatCafeInterior",false)end
   end
  end
  task.wait(.1)
 end
end)
script.Destroying:Connect(function()
 alive=false;connection:Disconnect();removed:Disconnect();entryConnection:Disconnect();exitConnection:Disconnect()
 local list={};for p in pairs(active)do table.insert(list,p)end
 for _,p in ipairs(list)do finish(p,false,"Doorway refreshed")end
end)
]====];server:SetAttribute("CafeInteriorVersion","interior2")
local client=Instance.new("Script");client.Name="CafeInterior2DoorwayClient";client.RunContext=Enum.RunContext.Client;client.Enabled=false;client.Source=[====[-- Brief fade with a local floor/readiness check. No loading UI remains after failure.
local Players=game:GetService("Players")
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local bridge=game:GetService("ReplicatedStorage"):WaitForChild("CafeInterior2Link")
local event=bridge:WaitForChild("Transition")
local room=workspace:WaitForChild("JapanMap"):WaitForChild("ShopFronts"):WaitForChild("CatCafeInterior")
local frame=bridge:GetAttribute("RoomFrame")
local pg=player:WaitForChild("PlayerGui")
-- A refreshed preview script must not leave a prior fade overlay behind.
for _,old in ipairs(pg:GetChildren())do if old:IsA("ScreenGui")and old.Name=="CafeDoorwayFade"then old:Destroy()end end
local gui=Instance.new("ScreenGui");gui.Name="CafeDoorwayFade";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=10000;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.ScreenInsets=Enum.ScreenInsets.None;gui.ClipToDeviceSafeArea=false
local shade=Instance.new("Frame");shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.fromRGB(28,24,21);shade.BackgroundTransparency=1;shade.BorderSizePixel=0;shade.Parent=gui
gui.Parent=pg
-- Same door bell and volume as the French Bookshop, HatShop and DressShop.
local doorBell=Instance.new("Sound");doorBell.Name="CafeDoorBell"
doorBell.SoundId=bridge:GetAttribute("DoorSound")or"rbxassetid://131845870598154"
doorBell.Volume=bridge:GetAttribute("DoorVolume")or .6;doorBell.PlaybackSpeed=1;doorBell.Looped=false;doorBell.Parent=gui
task.spawn(function()pcall(function()game:GetService("ContentProvider"):PreloadAsync({doorBell})end)end)
local pending;local visible=nil;local runningTween;local alive=true
local function fade(value)
 if runningTween then runningTween:Cancel()end
 runningTween=Tween:Create(shade,TweenInfo.new(.25,Enum.EasingStyle.Quad),{BackgroundTransparency=value});runningTween:Play()
 return runningTween
end
local function showRoom(show)
 if visible==show then return end;visible=show
 for _,p in ipairs(room:GetDescendants())do if p:IsA("BasePart")then p.LocalTransparencyModifier=show and 0 or 1 end end
end
local descendant=room.DescendantAdded:Connect(function(p)
 if p:IsA("BasePart")then p.LocalTransparencyModifier=visible and 0 or 1 end
end)
local visibility=Run.Heartbeat:Connect(function()
 local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart")
 local near=r and math.abs(r.Position.Y-frame.Position.Y)<30
 showRoom(near or pending and pending.inside or false)
end)
local receive=event.OnClientEvent:Connect(function(action,token,inside,target)
 if action=="FadeOut"then
  pending={token=token,inside=inside};local this=pending
  fade(0).Completed:Wait()
  if pending~=this then return end
  event:FireServer("Faded",token)
  task.delay(12,function()if alive and pending==this then event:FireServer("Abort",token);pending=nil;fade(1)end end)
 elseif action=="Arrived"then
  if not pending or pending.token~=token then return end
  local this=pending;local ready=false;local deadline=os.clock()+4
  repeat
   local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
   if root and (root.Position-target).Magnitude<3 then
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.RespectCanCollide=true
    local hit=workspace:Raycast(root.Position+Vector3.new(0,1,0),Vector3.new(0,-12,0),params)
    ready=hit~=nil and (not inside or hit.Instance:IsDescendantOf(room))
    if ready then
     local cam=workspace.CurrentCamera
     if cam then cam.CameraType=Enum.CameraType.Custom;cam.CameraSubject=char:FindFirstChildOfClass("Humanoid");cam.CFrame=CFrame.lookAt(root.Position-root.CFrame.LookVector*4.5+Vector3.new(0,2.5,0),root.Position+Vector3.new(0,1.2,0))end
     break
    end
   end
   task.wait(.05)
  until os.clock()>deadline or pending~=this or not alive
  if pending==this then event:FireServer(ready and "Ready"or"Abort",token)end
 elseif action=="FadeIn"or action=="Abort"then
  if pending and pending.token==token then
   pending=nil
   if action=="FadeIn"then doorBell:Stop();doorBell.TimePosition=0;doorBell:Play()end
   fade(1)
  end
 end
end)
local removing=player.CharacterRemoving:Connect(function()if pending then event:FireServer("Abort",pending.token)end;pending=nil;fade(1)end)
script.Destroying:Connect(function()
 alive=false;receive:Disconnect();visibility:Disconnect();descendant:Disconnect();removing:Disconnect()
 if pending then event:FireServer("Abort",pending.token)end
 if runningTween then runningTween:Cancel()end
 for _,p in ipairs(room:GetDescendants())do if p:IsA("BasePart")then p.LocalTransparencyModifier=0 end end
 gui:Destroy()
end)
]====];client:SetAttribute("CafeInteriorVersion","interior2")
-- Cozy3 changes operate on the staged room/display before either enters Workspace.
-- Reuse imported meshes; no source assets, unrelated shops, or live published state are changed.
local palette={Oak={181,143,102},OakLight={196,163,124},OakDark={143,108,77},Timber={106,79,59},TimberEdge={119,90,66},Wall={239,230,211},SageSoft={157,177,141},Sage={157,177,141},Rose={199,155,149},Indigo={134,158,162},Rug={224,211,184},Cream={241,232,211},Paper={242,231,208}}
local function recolor(p)
 local key=p.Name:match("_([^_]+)$");local rgb=palette[key]
 if rgb then p.Color=Color3.fromRGB(table.unpack(rgb))end
end
for _,p in ipairs(room:GetDescendants())do if p:IsA("MeshPart")and not p:IsDescendantOf(insideCats)then recolor(p)end end
local function moveGroup(prefix,delta)
 for _,p in ipairs(furniture:GetChildren())do if p.Name:match("^(.*)_[^_]+$")==prefix then p.CFrame=frame*CFrame.new(delta)*frame:ToObjectSpace(p.CFrame)end end
end
-- Quiet honey-oak floor instead of the strong alternating dark checker pattern.
local floors={CI2_Floor_Oak={182,153,119},CI2_Floor_OakLight={187,158,124},CI2_Floor_OakDark={179,150,117},CI2_FloorBase_OakDark={179,150,117}}
for _,p in ipairs(architecture:GetChildren())do
 local q=frame:ToObjectSpace(p.CFrame);local pos=q.Position
 if floors[p.Name]then p.Color=Color3.fromRGB(table.unpack(floors[p.Name]))end
 local isTallWall=p.Name:find("Wall_Wall",1,true)or p.Name:find("FrontLeft_Wall",1,true)or p.Name:find("FrontRight_Wall",1,true)or p.Name:find("VestibuleLeft_Wall",1,true)or p.Name:find("VestibuleRight_Wall",1,true)or p.Name:find("VestibuleEnd_Wall",1,true)
 if isTallWall then p.Size=Vector3.new(p.Size.X,p.Size.Y*9.8/11.3,p.Size.Z);p.CFrame=frame*CFrame.new(pos.X,pos.Y*9.8/11.3,pos.Z)*q.Rotation
 elseif p.Name=="CI2_DoorHeader_Wall"then p.Size=Vector3.new(p.Size.X,1.8,p.Size.Z);p.CFrame=frame*CFrame.new(pos.X,8.9,pos.Z)*q.Rotation
 elseif p.Name:find("CI2_Ceiling",1,true)or p.Name:find("CI2_Beams",1,true)then p.CFrame=p.CFrame-Vector3.new(0,1.5,0)
 elseif p.Name:find("CI2_Posts",1,true)then p.Size=Vector3.new(p.Size.X,9.6,p.Size.Z);p.CFrame=frame*CFrame.new(pos.X,4.8,pos.Z)*q.Rotation
 elseif p.Name:find("Rail_",1,true)then local factor=(p.Size.Y-1.5)/p.Size.Y;p.Size=Vector3.new(p.Size.X,p.Size.Y*factor,p.Size.Z);p.CFrame=p.CFrame-Vector3.new(0,.75,0)end
end
-- Bring the human seating a little forward without narrowing its approaches.
for _,g in ipairs({"C1_Bench","C1_Table0","C1_TableGoods0","C1_Table1","C1_TableGoods1","C1_Chair0","C1_Chair1"})do moveGroup(g,Vector3.new(0,0,1))end
for _,seat in ipairs(seats:GetChildren())do seat.CFrame=seat.CFrame+frame:VectorToWorldSpace(Vector3.new(0,0,1))end
insideCats.Adorable_Tabby_Kitten:PivotTo(frame*CFrame.new(-14.15,1.95,-23)*CFrame.Angles(0,math.rad(20),0))
insideCats.Curious_Little_Tabby:PivotTo(frame*CFrame.new(-5.5,.01,-23.4)*CFrame.Angles(0,math.rad(25),0))
-- Tea counter becomes the center of the rear wall, leaving a coherent right-hand lounge.
for _,g in ipairs({"C1_Counter","C1_CounterMenu","C1_Shelves","C1_TeaJars","C1_Cups","C1_TeaService","C1_Pastry","C1_PastryCover"})do moveGroup(g,Vector3.new(-8.1,0,0))end
-- Lamps hang lower; extend their existing mesh stems up to the new ceiling.
for i=0,2 do
 moveGroup("C1_Lamp"..i,Vector3.new(0,-2.2,0))
 local stem=furniture:FindFirstChild("C1_Lamp"..i.."_DarkMetal");if stem then local q=frame:ToObjectSpace(stem.CFrame);local bottom=q.Position.Y-stem.Size.Y/2;local top=9.74;stem.Size=Vector3.new(stem.Size.X,top-bottom,stem.Size.Z);stem.CFrame=frame*CFrame.new(q.Position.X,(top+bottom)/2,q.Position.Z)*q.Rotation end
end
local additions=Instance.new("Model");additions.Name="CozyNooks";additions.Parent=room
for _,v in ipairs(furniture:GetDescendants())do if v:IsA("PointLight")then v.Brightness=.32;v.Range=18 end end
local function cloneFurniture(prefix,name,origin,target)
 local model=Instance.new("Model");model.Name=name
 for _,p in ipairs(original:GetChildren())do if p:IsA("MeshPart")and p.Name:match("^(.*)_[^_]+$")==prefix then
  local c=p:Clone();c.CFrame=target*CFrame.new(-origin)*streetFrame:ToObjectSpace(p.CFrame);c.Anchored=true;c.CanTouch=false;recolor(c);c.Parent=model
 end end
 assert(#model:GetChildren()>0,"Missing original furniture group "..prefix);model.WorldPivot=target;model.Parent=additions;return model
end
local nookFrame=frame*CFrame.new(10.1,0,-15.5)*CFrame.Angles(0,-math.pi/2,0)
cloneFurniture("C1_Bench","ReadingSofa",Vector3.new(-7.9,0,-16.85),nookFrame)
for _,p in ipairs(additions.ReadingSofa:GetChildren())do if p.Name:find("Sage",1,true)then p.Color=Color3.fromRGB(199,160,151)end end
cloneFurniture("C1_Table1","ReadingTeaTable",Vector3.new(-5.75,0,-11.6),frame*CFrame.new(5.1,0,-15.4))
cloneFurniture("C1_TableGoods1","ReadingTea",Vector3.new(-5.75,0,-11.6),frame*CFrame.new(5.1,0,-15.4))
for i=0,2 do
 local seat=oldSeats["BenchSeat"..i]:Clone();seat.Name="NookSeat"..i;seat.CFrame=nookFrame*CFrame.new(-2.75+i*2.75,1.96,.20)*CFrame.Angles(0,math.pi,0)
 seat.Anchored=true;seat.Disabled=i==2;seat:SetAttribute("ReservedForCafeCat",i==2)
 for _,v in ipairs(seat:GetChildren())do if v.Name=="SeatWeld"then v:Destroy()end end
 seat.Parent=seats
end
insideCats.Tuxedo_Kitten:PivotTo(frame*CFrame.new(9.9,1.95,-12.75)*CFrame.Angles(0,math.rad(-65),0));insideCats.Tuxedo_Kitten:SetAttribute("CatSpot","BesideVisitorsOnReadingSofa")
-- Turn the real hollow cubby toward the room so its resident can be seen.
local oldCubby=frame*CFrame.new(12.6,0,-8.05);local newCubby=frame*CFrame.new(12.3,0,-5.7)*CFrame.Angles(0,-math.pi/2,0)
for _,p in ipairs(furniture:GetChildren())do if p.Name:match("^(.*)_[^_]+$")=="C1_Cubby"or p.Name:match("^(.*)_[^_]+$")=="C1_CubbyBeds"then p.CFrame=newCubby*oldCubby:ToObjectSpace(p.CFrame)end end
insideCats.Blush_Eared_Kitten:PivotTo(newCubby*CFrame.new(0,.58,.55)*CFrame.Angles(0,math.rad(-5),0))
insideCats.Emerald_Eyed_Tabby_Ki:PivotTo(frame*CFrame.new(4.5,2.32,-1.82)*CFrame.Angles(0,math.rad(180),0))
-- A second soft floor area visually groups the reading sofa and tea table.
for _,p in ipairs(architecture:GetChildren())do if p.Name:find("CI2_Rug_",1,true)then
 local c=p:Clone();local localCF=frame:ToObjectSpace(p.CFrame);local delta=localCF.Position-Vector3.new(-10.8,0,-19.4)
 c.Name="ReadingRug_"..p.Name:match("_([^_]+)$");c.Size=Vector3.new(c.Size.X*.78,c.Size.Y,c.Size.Z*.72)
 c.CFrame=frame*CFrame.new(Vector3.new(7.9,0,-15.5)+delta*Vector3.new(.78,1,.72))*localCF.Rotation;c.CanCollide=false
 if c.Name:find("SageSoft",1,true)then c.Color=Color3.fromRGB(186,153,145)elseif c.Name:find("Rug",1,true)and not c.Name:find("Cream",1,true)then c.Color=Color3.fromRGB(230,217,193)end
 c.Parent=additions
end end
local function decorGroup(prefix,name,pivot,target,scale)
 local model=Instance.new("Model");model.Name=name
 for _,p in ipairs(wallDecor:GetDescendants())do if p:IsA("MeshPart")and p.Name:match("^(.*)_[^_]+$")==prefix then local c=p:Clone();c.Anchored=true;c.CanCollide=false;recolor(c);c.Parent=model end end
 assert(#model:GetChildren()>0,"Missing decor "..prefix)
 model.WorldPivot=streetFrame*CFrame.new(pivot)*CFrame.Angles(0,math.pi/2,0);model:ScaleTo(scale or 1);model:PivotTo(target);model.Parent=additions;return model
end
decorGroup("CW1_CatPortrait","RearCatPortrait",Vector3.new(-12.55,5.95,-10.1),frame*CFrame.new(11.2,5.25,-27.80),1.35)
decorGroup("CW1_CatPlanter","CounterCatPlanter",Vector3.new(-12.12,5.17,-7.75),frame*CFrame.new(-1.1,3.09,-25.1),1.3)
decorGroup("CW1_CatPlanter","WindowCatPlanter",Vector3.new(-12.12,5.17,-7.75),frame*CFrame.new(-2.4,2.01,-1.8)*CFrame.Angles(0,math.pi,0),1.7)
decorGroup("CW1_Books","WindowBooks",Vector3.new(-12.15,6.06,-12.40),frame*CFrame.new(10.1,2.01,-1.9)*CFrame.Angles(0,math.pi,0),1.45)
decorGroup("CW1_BudVase","ReadingFlowers",Vector3.new(-12.13,6.06,-16.10),frame*CFrame.new(5.7,3.08,-16.2),1)
decorGroup("CW1_FrontShelf","CubbyWallShelf",Vector3.new(-12.55,5.14,-6.3),frame*CFrame.new(16.87,6.7,-7.2)*CFrame.Angles(0,-math.pi/2,0),1)
decorGroup("CW1_CatPlanter","CubbyWallPlanter",Vector3.new(-12.12,5.17,-7.75),frame*CFrame.new(16.43,6.71,-6.2)*CFrame.Angles(0,-math.pi/2,0),1.2)
decorGroup("CW1_Books","CubbyWallBooks",Vector3.new(-12.15,6.06,-12.40),frame*CFrame.new(16.43,6.71,-8.4)*CFrame.Angles(0,-math.pi/2,0),1)
-- Steam should read as a little warm wisp, not a dark plume.
for _,v in ipairs(room:GetDescendants())do if v:IsA("ParticleEmitter")then v.Rate=3;v.Lifetime=NumberRange.new(1.2,1.8);v.Color=ColorSequence.new(Color3.fromRGB(245,241,230));v.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.82),NumberSequenceKeypoint.new(1,1)});v.LightInfluence=0;v.LightEmission=.12 end end
-- Closed lattice doors, reused from the imported shop-back mesh kit.
local doorSource=assert(kit:FindFirstChild("back_door2"),"Imported lattice door source is missing")
local df=assert(doorSource:FindFirstChild("Door_Frame"));local ds=assert(doorSource:FindFirstChild("Door_Step"));assert(df:IsA("MeshPart")and ds:IsA("MeshPart"))
local outward=Vector3.new(ds.Position.X-df.Position.X,0,ds.Position.Z-df.Position.Z).Unit
local doorOrigin=Vector3.new(df.Position.X,df.Position.Y-df.Size.Y/2,df.Position.Z)
local sourceDoorFrame=CFrame.fromMatrix(doorOrigin,Vector3.yAxis:Cross(outward),Vector3.yAxis,outward)
local function makeDoor(parent,name,target,width,height,entering)
 local m=Instance.new("Model");m.Name=name;local ratio=Vector3.new(width/df.Size.X,height/df.Size.Y,1)
 for _,n in ipairs({"Door_Frame","Door_Wood","Door_Paper","Door_Reveal"})do
  local p=assert(doorSource:FindFirstChild(n));local c=p:Clone();local q=sourceDoorFrame:ToObjectSpace(p.CFrame)
  local offset=n=="Door_Reveal"and Vector3.new(0,0,-.12)or Vector3.zero
  c.Size=p.Size*ratio;c.CFrame=target*CFrame.new(q.Position*ratio+offset)*q.Rotation;c.Anchored=true;c.CanCollide=n=="Door_Reveal";c.CanTouch=false;c.CanQuery=true
  c.Material=n=="Door_Paper"and Enum.Material.SmoothPlastic or Enum.Material.Wood;c.Color=n=="Door_Paper"and Color3.fromRGB(237,224,194)or n=="Door_Reveal"and Color3.fromRGB(91,68,48)or Color3.fromRGB(122,89,61);c.Parent=m
 end
 -- Small cat relief makes this recognisably the cafe entrance without another sign.
 local badge=decorGroup("CW1_CatPortrait","DoorCatRelief",Vector3.new(-12.55,5.95,-10.1),target*CFrame.new(0,2.4,.35),.48);badge.Parent=m
 local host=m.Door_Reveal;local at=Instance.new("Attachment");at.Name="DoorInteraction";at.Position=host.CFrame:PointToObjectSpace(target:PointToWorldSpace(Vector3.new(0,3.5,.55)));at.Parent=host
 local prompt=Instance.new("ProximityPrompt");prompt.Style=Enum.ProximityPromptStyle.Custom;prompt.Name=entering and"EnterCafe"or"ExitCafe";prompt.ActionText=entering and"Enter"or"Return to street";prompt.ObjectText="Cat Café";prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX;prompt.MaxActivationDistance=7;prompt.RequiresLineOfSight=false;prompt.ClickablePrompt=true;prompt.HoldDuration=0;prompt.Parent=at
 m.WorldPivot=target;m.Parent=parent;return m
end
makeDoor(display,"EntranceDoor",streetFrame*CFrame.new(-9.36,0,-.25),5.35,7.10,true)
makeDoor(room,"ExitDoor",frame*CFrame.new(-11,0,.1)*CFrame.Angles(0,math.pi,0),5.85,7.9,false)
room:SetAttribute("CafeCozyVersion","cozy3");room:SetAttribute("InteriorCeilingHeight",9.8);bridge:SetAttribute("DoorwayMode","InteractionOnly")
print("QQ CAFECOZY3: warm quiet floor; two tea/seating nooks; six visitor seats; seven original cats; inward-facing cubby; plants and cat artwork; 9.8 ceiling")
print("QQ CAFECOZY3 DOORS: two closed lattice mesh doors; E/gamepad/tap prompts; walking cannot begin entry or exit; existing shop exterior retained")

-- The same small appearance/audio patch is used by the full staged installer and Play refresh.
local floorCount=0
for _,p in ipairs(room.Architecture:GetChildren())do
 if p:IsA("MeshPart")and(p.Name:find("CI2_Floor",1,true)==1 or p.Name=="CI2_VestibuleFloor_Oak")then
  p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromRGB(187,163,132);floorCount+=1
 end
end
assert(floorCount==5,"Unexpected cafe floor mesh count")
local steamCount=0
for _,root in ipairs({room,display})do for _,v in ipairs(root:GetDescendants())do
 if v:IsA("ParticleEmitter")and v.Name=="GentleTeaSteam"then
  v.Rate=1.2;v.Lifetime=NumberRange.new(.9,1.25);v.Speed=NumberRange.new(.18,.27);v.Acceleration=Vector3.new(0,.04,0)
  v.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.055),NumberSequenceKeypoint.new(.45,.14),NumberSequenceKeypoint.new(1,.23)})
  v.Color=ColorSequence.new(Color3.fromRGB(250,247,240))
  v.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.93),NumberSequenceKeypoint.new(1,1)})
  v.LightInfluence=0;v.LightEmission=1;steamCount+=1
 end
end end
assert(steamCount==10,"Expected six interior mugs and four street-display mugs")
bridge:SetAttribute("DoorSound","rbxassetid://131845870598154");bridge:SetAttribute("DoorVolume",.6)
room:SetAttribute("CafePolishVersion","quiet_floor_steam_bell1")
print("QQ CAFECOZY3 POLISH: five floor meshes in uniform matte honey oak; ten steam emitters reduced to small pale wisps; seven cats retained")
print("QQ CAFECOZY3 BELL: French shop sound 131845870598154 at volume .6; one ring per successful entry or exit")

verify()
local createdBackup=false
if not backup then backup=Instance.new("Folder");backup.Name="CafeInterior2Originals";createdBackup=true end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("Before larger cat cafe interior")end)
local ok,err=pcall(function()
 if createdBackup then
  backup:SetAttribute("OriginalMusicFrame",oldMusicFrame);backup:SetAttribute("OriginalMusicHalfSize",oldMusicHalf);backup.Parent=hb
  original.Parent=backup
 else current.Parent=nil end
 if previous then previous.Parent=nil end
 if lamps[1]then lamps[1]:SetAttribute("OriginalName",lamps[1].Name);lamps[1].Name="DoorwayWallLamp";lamps[1].Parent=backup end
 display.Parent=fronts;room.Parent=fronts
 music:SetAttribute("JapanCatCafeFrame",frame*CFrame.new(0,5.65,-14));music:SetAttribute("JapanCatCafeHalfSize",Vector3.new(17.2,6.0,14.4))
 verify()
end)
if not ok then
 display:Destroy();room:Destroy();bridge:Destroy();server:Destroy();client:Destroy()
 music:SetAttribute("JapanCatCafeFrame",oldMusicFrame);music:SetAttribute("JapanCatCafeHalfSize",oldMusicHalf)
 if lamps[1]then lamps[1].Name="Warm shop wall lamp";lamps[1].Parent=facade end
 current.Parent=fronts;if previous then previous.Parent=fronts end
 if createdBackup then backup:Destroy()end
 error("Larger cafe replacement reverted: "..tostring(err))
end
-- Geometry and preservation checks are complete before enabling doorway behavior.
for _,v in pairs({oldService,oldClient,oldLink})do if v then v:Destroy()end end
-- A single replicated client Script runs for both current players and future joins.
-- PlayerScripts is client-only; adding a LocalScript template during Play cannot
-- populate an already joined player's scripts from the server.
client.Parent=bridge;bridge.Parent=RS;server.Parent=SSS;server.Enabled=true;client.Enabled=true
if previous then previous:Destroy()end
if current~=original then current:Destroy()end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("After larger cat cafe interior")end)
print(string.format("QQ CAFEINTERIOR2 BUILT: %d new shell meshes; %d full-size furniture meshes; 38 original wall decor meshes; 34x28 room, lowered 9.8 ceiling",shellCount,furnitureCount))
print("QQ CAFEINTERIOR2 CATS: six inside in distinct spots; seated Whisker greeter outside; seven intact ten-bone rigs; cream at 84 percent")
print("QQ CAFEINTERIOR2 DOORWAY: same-server fade and destination-floor check; closed mesh doors; E/tap entry and exit only; no walk-through transition")
print(string.format("QQ CAFEINTERIOR2 PRESERVED: %d existing Japan instances outside cafe/doorway lamp; original cafe backed up; exterior dimensions and other shops unchanged",#preserved))
print("QQ CAFEINTERIOR2 AUDIO: existing two-track playlist and four meows retained; listening zone moved to larger room; four original steaming mugs plus two at the new seating nook")
print("QQ CAFEINTERIOR2 STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT").."; NOT PUBLISHED")

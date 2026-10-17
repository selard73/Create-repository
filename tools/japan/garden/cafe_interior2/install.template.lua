-- Separate, larger cafe interior. Preview on Server; install only after picture approval.
-- Source import must be anchored/stored before Play. No publishing or DataStore writes.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong environment")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and CAFEINTERIOR2_ALLOW_EDIT==true),"Server preview first; Edit requires picture approval")
local DATA=game:GetService("HttpService"):JSONDecode([==[__DATA__]==])
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
local camera=Instance.new("Script");camera.Name="CafeCamera";camera.RunContext=Enum.RunContext.Client;camera.Source=[====[__CAMERA__]====];camera.Parent=room
room.WorldPivot=frame;display.WorldPivot=streetFrame
local bridge=Instance.new("Folder");bridge.Name="CafeInterior2Link";bridge:SetAttribute("CafeInteriorVersion","interior2");bridge:SetAttribute("StreetFrame",streetFrame);bridge:SetAttribute("RoomFrame",frame)
local event=Instance.new("RemoteEvent");event.Name="Transition";event.Parent=bridge
local server=Instance.new("Script");server.Name="CafeInterior2Doorway";server.Enabled=false;server.Source=[====[__SERVER__]====];server:SetAttribute("CafeInteriorVersion","interior2")
local client=Instance.new("Script");client.Name="CafeInterior2DoorwayClient";client.RunContext=Enum.RunContext.Client;client.Enabled=false;client.Source=[====[__CLIENT__]====];client:SetAttribute("CafeInteriorVersion","interior2")
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
print(string.format("QQ CAFEINTERIOR2 BUILT: %d new shell meshes; %d full-size furniture meshes; 38 wall decor meshes; 34x28 room, 11.3 ceiling",shellCount,furnitureCount))
print("QQ CAFEINTERIOR2 CATS: six inside in distinct spots; seated Whisker greeter outside; seven intact ten-bone rigs; cream at 84 percent")
print("QQ CAFEINTERIOR2 DOORWAY: same-server fade and destination-floor check; runtime entrance/exit, timeout, respawn and camera tests still required")
print(string.format("QQ CAFEINTERIOR2 PRESERVED: %d existing Japan instances outside cafe/doorway lamp; original cafe backed up; exterior dimensions and other shops unchanged",#preserved))
print("QQ CAFEINTERIOR2 AUDIO: existing two-track playlist and four meows retained; listening zone moved to larger room; four steaming mugs retained")
print("QQ CAFEINTERIOR2 STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT").."; NOT PUBLISHED")

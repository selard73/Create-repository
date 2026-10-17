-- Shannon's revised natural cat distribution: seven distinct resting/activity spots.
-- Preview on Server; permanent installation requires approval of the pictures.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or (not Run:IsRunning() and CAFE_SPREAD2_ALLOW_EDIT==true),"Server preview first; Edit only after approval")
local SS=game:GetService("ServerStorage")
local cafe=assert(workspace.JapanMap.ShopFronts:FindFirstChild("CatCafe"))
local cats=assert(cafe:FindFirstChild("Cats"))
assert(cats:GetAttribute("CafeCatsVersion")=="cats3","Unexpected cat rigs")
local frame=cafe:GetPivot()
local moves={
 {name="Whisker_Wonder",position=Vector3.new(-5.1,-.5798532,2.15),yaw=-15,scale=.90,spot="SeatedDoorwayGreeter"},
 {name="Emerald_Eyed_Tabby_Ki",position=Vector3.new(3.1,2.32,-1.82),yaw=125,scale=.93,spot="SingleWindowCat"},
 {name="Tuxedo_Kitten",position=Vector3.new(10.1,.01,-12.95),yaw=180,scale=.90,spot="BesideFoodBowls"},
 {name="Ginger_Whiskers",position=Vector3.new(10.65,4.69,-12.5),yaw=-140,scale=.94,spot="HighPerchPounce"},
 {name="Curious_Little_Tabby",position=Vector3.new(-2.25,.01,-16.95),yaw=25,scale=.90,spot="BesideBenchFloor"},
 {name="Blush_Eared_Kitten",position=Vector3.new(4.8,.58,-7.85),yaw=-5,scale=.84,spot="InsideCubby"},
 {name="Adorable_Tabby_Kitten",position=Vector3.new(-10.65,1.95,-16.65),yaw=20,scale=1,spot="CornerBench"},
}
local client=assert(cats:FindFirstChild("CafeCatsClient"));assert(client:IsA("Script") and client.RunContext==Enum.RunContext.Client)
local seat=assert(cafe.VisitorSeats:FindFirstChild("BenchSeat0"))
local facade=workspace.JapanMap["Outdoor market revision"]["Cat cafe"]["Traditional downtown facade"]
local lamps={}
for _,v in facade:GetChildren()do
 if v:IsA("BasePart") and v.Name=="Warm shop wall lamp" and (frame:PointToObjectSpace(v.Position)-Vector3.new(-9.36,6.510147,-.600097)).Magnitude<.02 then table.insert(lamps,v)end
end
local backup=SS.HudBackup:FindFirstChild("CafeSpread2Originals")
assert(#lamps==1 or (#lamps==0 and backup and backup:FindFirstChild("DoorwayWallLamp")),"Expected exactly the doorway lamp or its prior backup")
for _,m in moves do
 m.model=assert(cats:FindFirstChild(m.name));assert(m.model:IsA("Model") and m.model.PrimaryPart and m.model.PrimaryPart.Anchored)
 local n=0;for _,b in m.model:GetDescendants()do if b:IsA("Bone")then n+=1 end end;assert(n==10,"Unexpected skeleton")
end
-- All references validated before mutation. Preserve the lamp and original locations.
if not backup then backup=Instance.new("Folder");backup.Name="CafeSpread2Originals";backup.Parent=SS.HudBackup end
if lamps[1]then local lamp=lamps[1];lamp:SetAttribute("CafeSpread2OriginalName",lamp.Name);lamp:SetAttribute("CafeSpread2OriginalParent",facade:GetFullName());lamp.Name="DoorwayWallLamp";lamp.Parent=backup end
local replacement=client:Clone();replacement.Parent=nil;client:Destroy()
for _,m in moves do
 if m.model:GetAttribute("CafeSpread2OriginalPivot")==nil then m.model:SetAttribute("CafeSpread2OriginalPivot",m.model:GetPivot());m.model:SetAttribute("CafeSpread2OriginalSpot",m.model:GetAttribute("CatSpot"))end
 if m.model:GetAttribute("CafeSpread2OriginalScale")==nil then m.model:SetAttribute("CafeSpread2OriginalScale",m.model:GetScale())end
 for _,b in m.model:GetDescendants()do if b:IsA("Bone")then b.Transform=CFrame.identity end end
 m.model:ScaleTo(m.model:GetAttribute("CafeSpread2OriginalScale")*m.scale)
 m.model:PivotTo(frame*CFrame.new(m.position)*CFrame.Angles(0,math.rad(m.yaw),0))
 m.model:SetAttribute("CatSpot",m.spot)
end
if seat:GetAttribute("CafeSpread2WasDisabled")==nil then seat:SetAttribute("CafeSpread2WasDisabled",seat.Disabled)end
seat.Disabled=true;seat:SetAttribute("ReservedForCafeCat",true)
for _,b in cats:GetDescendants()do if b:IsA("Bone")then b.Transform=CFrame.identity end end
-- Restart the unchanged controller so its cached bone axes use the new orientations.
replacement.Parent=cats
cafe:SetAttribute("CafeArrangementVersion","spread2")
print("QQ CAFE SPREAD2: seated Whisker greeter, Adorable on corner bench, Curious beside bench, cream kitten in cubby, Emerald alone at window, Tuxedo by bowls, crouching Ginger on highest perch")
print("QQ CAFE SPREAD2 SIZE: cream kitten at 84 percent; Whisker/Curious/Tuxedo 90 percent, Emerald 93 percent, Ginger 94 percent, Adorable unchanged; original rig proportions retained")
print("QQ CAFE SPREAD2 LAMP: only doorway neon lamp and its PointLight backed up; exterior lantern and other lamps retained")
print("QQ CAFE SPREAD2 SEATS: corner BenchSeat0 reserved for cat; four visitor seats remain enabled")
print("QQ CAFE SPREAD2 PRESERVED: all seven cats/70 bones, original textures and idle controller source; furniture, tea, sound, camera and other shops unchanged")
print("QQ CAFE SPREAD2 STATUS: "..(Run:IsRunning() and "SERVER PREVIEW" or "EDIT").."; NOT PUBLISHED")

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

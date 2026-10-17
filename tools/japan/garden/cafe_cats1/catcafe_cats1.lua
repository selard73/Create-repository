-- Kit24 cats. Run on the play-test SERVER first; no Edit install without Shannon's yes to pictures.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and game.PlaceId==117372258657114,'Wrong place')
assert(Run:IsRunning() or CATCAFE_CATS1_ALLOW_EDIT==true,'Server preview only until Shannon approves')
local SS=game:GetService('ServerStorage')
local cafe=assert(workspace.JapanMap:FindFirstChild('ShopFronts') and workspace.JapanMap.ShopFronts:FindFirstChild('CatCafe'),'Run the cafe furniture preview first')
assert(cafe:GetAttribute('CatCafeBuildVersion')=='cafe1','Unexpected cafe version')
local source=assert(SS.JapanGardenKit:FindFirstChild('cat_cafe_cats1'),'Import and prepare kit24 before Play')
assert(source:GetAttribute('CafeCatsSourceVersion')=='cats1','Source not prepared')
local CONFIG=game:GetService('HttpService'):JSONDecode([==[[{"name":"Whisker_Wonder","label":"Whisker Wonder","mesh_name":"CC1_Whisker_Wonder","source_origin":[0.0,0,0],"position":[-2.55,2.32,-1.82],"yaw":195,"spot":"Window0"},{"name":"Emerald_Eyed_Tabby_Ki","label":"Emerald Tabby","mesh_name":"CC1_Emerald_Eyed_Tabby_Ki","source_origin":[4.5,0,0],"position":[10.65,3.29,-8.9],"yaw":-110,"spot":"Climb1"},{"name":"Tuxedo_Kitten","label":"Tuxedo Kitten","mesh_name":"CC1_Tuxedo_Kitten","source_origin":[9.0,0,0],"position":[10.65,4.69,-12.5],"yaw":-122,"spot":"Climb2"},{"name":"Ginger_Whiskers","label":"Ginger Whiskers","mesh_name":"CC1_Ginger_Whiskers","source_origin":[13.5,0,0],"position":[3.1,2.32,-1.82],"yaw":-105,"spot":"Window1"},{"name":"Curious_Little_Tabby","label":"Curious Tabby","mesh_name":"CC1_Curious_Little_Tabby","source_origin":[18.0,0,0],"position":[4.8,4.05,-8.7],"yaw":-28,"spot":"CubbyTop"},{"name":"Blush_Eared_Kitten","label":"Blush Eared Kitten","mesh_name":"CC1_Blush_Eared_Kitten","source_origin":[22.5,0,0],"position":[8.75,2.32,-1.82],"yaw":194,"spot":"Window2"}]]==])
local parts={}
for _,p in ipairs(source:GetDescendants())do if p:IsA('BasePart')then
 assert(p:IsA('MeshPart') and p.Anchored and not parts[p.Name],'Bad source part');parts[p.Name]=p
end end
local o=assert(parts.CC1_Origin).Position;local r=assert(parts.CC1_Right).Position-o;local f=assert(parts.CC1_Front).Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04 and math.abs(r.Unit:Dot(f.Unit))<.001,'Invalid source markers')
local sourceFrame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
local floor=workspace.JapanMap['Outdoor market revision']['Cat cafe']['Shop floor']
local target=CFrame.new(6014,floor.Position.Y+floor.Size.Y/2,7)*CFrame.Angles(0,-math.pi/2,0)
local previous=cafe:FindFirstChild('Cats')
assert(not previous or previous:GetAttribute('CafeCatsVersion')=='cats1','Unrelated cats already exist')
local container=Instance.new('Model');container.Name='Cats';container:SetAttribute('CafeCatsVersion','cats1')
local count,boneCount=0,0
for i,c in ipairs(CONFIG)do
 local original=assert(parts[c.mesh_name],'Missing cat '..c.name)
 local clone=original:Clone();clone.Name=c.name;clone.Anchored=true;clone.CanCollide=false;clone.CanTouch=false;clone.CanQuery=true;clone.CastShadow=true
 clone.Color=Color3.new(1,1,1);clone.Material=Enum.Material.SmoothPlastic;clone.Transparency=0
 local model=Instance.new('Model');model.Name=c.name;clone.Parent=model;model.PrimaryPart=clone
 local src=sourceFrame*CFrame.new(c.source_origin[1]+4,0,3)
 local desired=target*CFrame.new(table.unpack(c.position))*CFrame.Angles(0,math.rad(c.yaw),0)
 clone.CFrame=desired*src:ToObjectSpace(original.CFrame);clone.PivotOffset=clone.CFrame:ToObjectSpace(desired);model.WorldPivot=desired
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('CafeCatIndex',i);model:SetAttribute('CatDisplayName',c.label);model:SetAttribute('CatSpot',c.spot);model:SetAttribute('CatRigVersion','idle1')
 local nb=0
 for _,b in ipairs(clone:GetDescendants())do if b:IsA('Bone')then b.Transform=CFrame.identity;nb+=1 end end
 assert(nb==10,'Bone count mismatch '..c.name);boneCount+=nb
 local ac=Instance.new('AnimationController');ac.Name='CatAnimation';ac.Parent=model;Instance.new('Animator',ac)
 model.Parent=container;count+=1
end
assert(count==6 and boneCount==60)
local client=Instance.new('Script');client.Name='CafeCatsClient';client.RunContext=Enum.RunContext.Client;client.Source=[====[-- Gentle, stationary cafe-cat idles. The supplied poses are retained; this is not a walking controller.
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local player=Players.LocalPlayer
local root=script.Parent
local cats={}
local function add(model)
 if not model:IsA('Model') or not model:GetAttribute('CafeCatIndex') or cats[model] then return end
 local mesh=model:FindFirstChildWhichIsA('MeshPart',true)
 if not mesh then return end
 local cf=model:GetPivot()
 local bones={}
 for _,b in ipairs(mesh:GetDescendants())do if b:IsA('Bone')then
  b.Transform=CFrame.identity
  bones[b.Name]={bone=b,up=b.WorldCFrame:VectorToObjectSpace(cf.UpVector),right=b.WorldCFrame:VectorToObjectSpace(cf.RightVector),forward=b.WorldCFrame:VectorToObjectSpace(cf.ZVector)}
 end end
 if not bones.Head or not bones.Chest then return end
 cats[model]={mesh=mesh,bones=bones,phase=model:GetAttribute('CafeCatIndex')*1.73,active=false}
end
for _,m in ipairs(root:GetChildren())do add(m)end
local added=root.ChildAdded:Connect(function(m)task.defer(add,m)end)
local streamed=root.DescendantAdded:Connect(function(d)
 if d:IsA('Bone')then task.defer(function()local m=d:FindFirstAncestorWhichIsA('Model');if m then add(m)end end)end
end)
local function turn(b,axis,angle)
 if b then b.bone.Transform=CFrame.fromAxisAngle(b[axis],math.rad(angle))end
end
local elapsed=0
local connection
connection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
 local char=player.Character;local hrp=char and char:FindFirstChild('HumanoidRootPart')
 local now=workspace:GetServerTimeNow()
 for m,c in pairs(cats)do
  if not m:IsDescendantOf(workspace)then cats[m]=nil
  else
   local nearby=hrp and (hrp.Position-c.mesh.Position).Magnitude<85
   if nearby then
    local t=now+c.phase;local b=c.bones
    -- Smooth motions at different rates; no twitching or synchronized cats.
    turn(b.Head,'up',8*math.sin(t*.24)+2*math.sin(t*.51))
    if b.Head then b.Head.bone.Transform*=CFrame.fromAxisAngle(b.Head.forward,math.rad(2.5*math.sin(t*.36)))end
    turn(b.Chest,'right',.35*math.sin(t*1.65))
    for j=1,4 do turn(b['Tail'..j],'up',(j==1 and 1 or 3.2)*math.sin(t*.72+j*.52))end
    local flick=math.max(0,math.sin(t*.37))^18
    turn(b['Ear.L'],'forward',-5*flick);turn(b['Ear.R'],'forward',4*math.max(0,math.sin(t*.31+2))^18)
    c.active=true
   elseif c.active then
    for _,b in pairs(c.bones)do b.bone.Transform=CFrame.identity end;c.active=false
   end
  end
 end
end)
script.Destroying:Connect(function()connection:Disconnect();added:Disconnect();streamed:Disconnect()end)
]====];client.Parent=container
-- Only replace this tagged cat group; preserve the room, furniture, tea, sound, camera and other shops.
if previous then previous:Destroy()end
container.Parent=cafe
print('QQ CATCATS1 DONE: 6 anchored skinned cats, 60 bones, client idle controller; 3 window beds, 2 shelves, cubby top')
print('QQ CATCATS1 PRESERVED: cafe furnishings, steaming tea, playlist/meows, camera guard and other shops')
print('QQ CATCATS1 STATUS: '..(Run:IsRunning() and 'SERVER PREVIEW' or 'EDIT')..'; NOT PUBLISHED')

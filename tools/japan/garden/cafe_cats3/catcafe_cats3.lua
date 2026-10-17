-- Kit27 cats. Run on the play-test SERVER first; no Edit install without Shannon's yes to pictures.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and game.PlaceId==117372258657114,'Wrong place')
assert(Run:IsRunning() or CATCAFE_CATS3_ALLOW_EDIT==true,'Server preview only until Shannon approves')
local SS=game:GetService('ServerStorage')
local cafe=assert(workspace.JapanMap:FindFirstChild('ShopFronts') and workspace.JapanMap.ShopFronts:FindFirstChild('CatCafe'),'Run the cafe furniture preview first')
assert(cafe:GetAttribute('CatCafeBuildVersion')=='cafe1','Unexpected cafe version')
local source=assert(SS.JapanGardenKit:FindFirstChild('cat_cafe_cats3'),'Import and prepare kit27 before Play')
assert(source:GetAttribute('CafeCatsSourceVersion')=='cats3','Source not prepared')
local CONFIG=game:GetService('HttpService'):JSONDecode([==[[{"name":"Whisker_Wonder","label":"Whisker Wonder","mesh_name":"CC3_Whisker_Wonder","source_origin":[0.0,0,0],"position":[-2.55,2.32,-1.82],"yaw":195,"spot":"Window0","bone_prefix":"C01_","bone_parents":{"C01_Root":null,"C01_Body":"C01_Root","C01_Chest":"C01_Body","C01_Head":"C01_Chest","C01_Ear.L":"C01_Head","C01_Ear.R":"C01_Head","C01_Tail1":"C01_Body","C01_Tail2":"C01_Tail1","C01_Tail3":"C01_Tail2","C01_Tail4":"C01_Tail3"}},{"name":"Emerald_Eyed_Tabby_Ki","label":"Emerald Tabby","mesh_name":"CC3_Emerald_Eyed_Tabby_Ki","source_origin":[4.5,0,0],"position":[10.65,3.29,-8.9],"yaw":-110,"spot":"Climb1","bone_prefix":"C02_","bone_parents":{"C02_Root":null,"C02_Body":"C02_Root","C02_Chest":"C02_Body","C02_Head":"C02_Chest","C02_Ear.L":"C02_Head","C02_Ear.R":"C02_Head","C02_Tail1":"C02_Body","C02_Tail2":"C02_Tail1","C02_Tail3":"C02_Tail2","C02_Tail4":"C02_Tail3"}},{"name":"Tuxedo_Kitten","label":"Tuxedo Kitten","mesh_name":"CC3_Tuxedo_Kitten","source_origin":[9.0,0,0],"position":[10.65,4.69,-12.5],"yaw":-122,"spot":"Climb2","bone_prefix":"C03_","bone_parents":{"C03_Root":null,"C03_Body":"C03_Root","C03_Chest":"C03_Body","C03_Head":"C03_Chest","C03_Ear.L":"C03_Head","C03_Ear.R":"C03_Head","C03_Tail1":"C03_Body","C03_Tail2":"C03_Tail1","C03_Tail3":"C03_Tail2","C03_Tail4":"C03_Tail3"}},{"name":"Ginger_Whiskers","label":"Ginger Whiskers","mesh_name":"CC3_Ginger_Whiskers","source_origin":[13.5,0,0],"position":[3.1,2.32,-1.82],"yaw":-105,"spot":"Window1","bone_prefix":"C04_","bone_parents":{"C04_Root":null,"C04_Body":"C04_Root","C04_Chest":"C04_Body","C04_Head":"C04_Chest","C04_Ear.L":"C04_Head","C04_Ear.R":"C04_Head","C04_Tail1":"C04_Body","C04_Tail2":"C04_Tail1","C04_Tail3":"C04_Tail2","C04_Tail4":"C04_Tail3"}},{"name":"Curious_Little_Tabby","label":"Curious Tabby","mesh_name":"CC3_Curious_Little_Tabby","source_origin":[18.0,0,0],"position":[4.8,4.05,-8.7],"yaw":-28,"spot":"CubbyTop","bone_prefix":"C05_","bone_parents":{"C05_Root":null,"C05_Body":"C05_Root","C05_Chest":"C05_Body","C05_Head":"C05_Chest","C05_Ear.L":"C05_Head","C05_Ear.R":"C05_Head","C05_Tail1":"C05_Body","C05_Tail2":"C05_Tail1","C05_Tail3":"C05_Tail2","C05_Tail4":"C05_Tail3"}},{"name":"Blush_Eared_Kitten","label":"Blush Eared Kitten","mesh_name":"CC3_Blush_Eared_Kitten","source_origin":[22.5,0,0],"position":[8.75,2.32,-1.82],"yaw":194,"spot":"Window2","bone_prefix":"C06_","bone_parents":{"C06_Root":null,"C06_Body":"C06_Root","C06_Chest":"C06_Body","C06_Head":"C06_Chest","C06_Ear.L":"C06_Head","C06_Ear.R":"C06_Head","C06_Tail1":"C06_Body","C06_Tail2":"C06_Tail1","C06_Tail3":"C06_Tail2","C06_Tail4":"C06_Tail3"}},{"name":"Adorable_Tabby_Kitten","label":"Adorable Tabby Kitten","mesh_name":"CC3_Adorable_Tabby_Kitten","source_origin":[27.0,0,0],"position":[10.65,1.84,-5.5],"yaw":-100,"spot":"Climb0","bone_prefix":"C07_","bone_parents":{"C07_Root":null,"C07_Body":"C07_Root","C07_Chest":"C07_Body","C07_Head":"C07_Chest","C07_Ear.L":"C07_Head","C07_Ear.R":"C07_Head","C07_Tail1":"C07_Body","C07_Tail2":"C07_Tail1","C07_Tail3":"C07_Tail2","C07_Tail4":"C07_Tail3"}}]]==])
local parts={}
for _,p in ipairs(source:GetDescendants())do if p:IsA('BasePart')then
 assert(p:IsA('MeshPart') and p.Anchored and not parts[p.Name],'Bad source part');parts[p.Name]=p
end end
local o=assert(parts.CC3_Origin).Position;local r=assert(parts.CC3_Right).Position-o;local f=assert(parts.CC3_Front).Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04 and math.abs(r.Unit:Dot(f.Unit))<.001,'Invalid source markers')
local sourceFrame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
local floor=workspace.JapanMap['Outdoor market revision']['Cat cafe']['Shop floor']
local target=CFrame.new(6014,floor.Position.Y+floor.Size.Y/2,7)*CFrame.Angles(0,-math.pi/2,0)
local previous=cafe:FindFirstChild('Cats')
assert(not previous or previous:GetAttribute('CafeCatsVersion')=='cats3' or (Run:IsRunning() and previous:GetAttribute('CafeCatsVersion')=='static_preview2'),'Unrelated cats already exist')
local container=Instance.new('Model');container.Name='Cats';container:SetAttribute('CafeCatsVersion','cats3')
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
 model:SetAttribute('CatBonePrefix',c.bone_prefix);model:SetAttribute('CafeCatIndex',i);model:SetAttribute('CatDisplayName',c.label);model:SetAttribute('CatSpot',c.spot);model:SetAttribute('CatRigVersion','idle1')
 local nb=0
 for _,b in ipairs(clone:GetDescendants())do if b:IsA('Bone')then b.Transform=CFrame.identity;nb+=1 end end
 assert(nb==10,'Bone count mismatch '..c.name);boneCount+=nb
 local ac=Instance.new('AnimationController');ac.Name='CatAnimation';ac.Parent=model;Instance.new('Animator',ac)
 model.Parent=container;count+=1
end
assert(count==7 and boneCount==70)
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
 local prefix=assert(model:GetAttribute("CatBonePrefix"),"Cat bone prefix missing")
 local bones={}
 for _,b in ipairs(mesh:GetDescendants())do if b:IsA('Bone')then
  b.Transform=CFrame.identity
  assert(b.Name:sub(1,#prefix)==prefix,'Unexpected bone prefix')
  bones[b.Name:sub(#prefix+1)]={bone=b,up=b.WorldCFrame:VectorToObjectSpace(cf.UpVector),right=b.WorldCFrame:VectorToObjectSpace(cf.RightVector),forward=b.WorldCFrame:VectorToObjectSpace(cf.ZVector)}
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
print('QQ CATCATS3 DONE: 7 anchored skinned cats, 70 bones, client idle controller; 3 window beds, 3 shelves, cubby top')
print('QQ CATCATS3 PRESERVED: cafe furnishings, steaming tea, playlist/meows, camera guard and other shops')
print('QQ CATCATS3 STATUS: '..(Run:IsRunning() and 'SERVER PREVIEW' or 'EDIT')..'; NOT PUBLISHED')

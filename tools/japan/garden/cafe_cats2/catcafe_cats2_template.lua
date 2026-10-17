-- Kit25 cats. Run on the play-test SERVER first; no Edit install without Shannon's yes to pictures.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and game.PlaceId==117372258657114,'Wrong place')
assert(Run:IsRunning() or CATCAFE_CATS2_ALLOW_EDIT==true,'Server preview only until Shannon approves')
local SS=game:GetService('ServerStorage')
local cafe=assert(workspace.JapanMap:FindFirstChild('ShopFronts') and workspace.JapanMap.ShopFronts:FindFirstChild('CatCafe'),'Run the cafe furniture preview first')
assert(cafe:GetAttribute('CatCafeBuildVersion')=='cafe1','Unexpected cafe version')
local source=assert(SS.JapanGardenKit:FindFirstChild('cat_cafe_cats2'),'Import and prepare kit25 before Play')
assert(source:GetAttribute('CafeCatsSourceVersion')=='cats2','Source not prepared')
local CONFIG=game:GetService('HttpService'):JSONDecode([==[__CONFIG__]==])
local parts={}
for _,p in ipairs(source:GetDescendants())do if p:IsA('BasePart')then
 assert(p:IsA('MeshPart') and p.Anchored and not parts[p.Name],'Bad source part');parts[p.Name]=p
end end
local o=assert(parts.CC2_Origin).Position;local r=assert(parts.CC2_Right).Position-o;local f=assert(parts.CC2_Front).Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04 and math.abs(r.Unit:Dot(f.Unit))<.001,'Invalid source markers')
local sourceFrame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
local floor=workspace.JapanMap['Outdoor market revision']['Cat cafe']['Shop floor']
local target=CFrame.new(6014,floor.Position.Y+floor.Size.Y/2,7)*CFrame.Angles(0,-math.pi/2,0)
local previous=cafe:FindFirstChild('Cats')
assert(not previous or previous:GetAttribute('CafeCatsVersion')=='cats2' or previous:GetAttribute('CafeCatsVersion')=='cats1','Unrelated cats already exist')
local container=Instance.new('Model');container.Name='Cats';container:SetAttribute('CafeCatsVersion','cats2')
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
assert(count==7 and boneCount==70)
local client=Instance.new('Script');client.Name='CafeCatsClient';client.RunContext=Enum.RunContext.Client;client.Source=[====[__CLIENT__]====];client.Parent=container
-- Only replace this tagged cat group; preserve the room, furniture, tea, sound, camera and other shops.
if previous then previous:Destroy()end
container.Parent=cafe
print('QQ CATCATS2 DONE: 7 anchored skinned cats, 70 bones, client idle controller; 3 window beds, 3 shelves, cubby top')
print('QQ CATCATS2 PRESERVED: cafe furnishings, steaming tea, playlist/meows, camera guard and other shops')
print('QQ CATCATS2 STATUS: '..(Run:IsRunning() and 'SERVER PREVIEW' or 'EDIT')..'; NOT PUBLISHED')

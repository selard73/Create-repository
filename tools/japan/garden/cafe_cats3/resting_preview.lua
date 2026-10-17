-- Server-only resting-pose review while the corrected unique-name rigs await import.
assert(game.PlaceId==117372258657114 and game:GetService('RunService'):IsRunning() and game:GetService('RunService'):IsServer(),'Server preview only')
local source=game.ServerStorage.JapanGardenKit.cafe_finishing1_raw
local cafe=assert(workspace.JapanMap.ShopFronts.CatCafe)
assert(not cafe:FindFirstChild('Cats'),'Cats already exist')
local CONFIG=game:GetService('HttpService'):JSONDecode([==[[{"name":"Whisker_Wonder","label":"Whisker Wonder","mesh_name":"CC2_Whisker_Wonder","source_origin":[0.0,0,0],"position":[-2.55,2.32,-1.82],"yaw":195,"spot":"Window0"},{"name":"Emerald_Eyed_Tabby_Ki","label":"Emerald Tabby","mesh_name":"CC2_Emerald_Eyed_Tabby_Ki","source_origin":[4.5,0,0],"position":[10.65,3.29,-8.9],"yaw":-110,"spot":"Climb1"},{"name":"Tuxedo_Kitten","label":"Tuxedo Kitten","mesh_name":"CC2_Tuxedo_Kitten","source_origin":[9.0,0,0],"position":[10.65,4.69,-12.5],"yaw":-122,"spot":"Climb2"},{"name":"Ginger_Whiskers","label":"Ginger Whiskers","mesh_name":"CC2_Ginger_Whiskers","source_origin":[13.5,0,0],"position":[3.1,2.32,-1.82],"yaw":-105,"spot":"Window1"},{"name":"Curious_Little_Tabby","label":"Curious Tabby","mesh_name":"CC2_Curious_Little_Tabby","source_origin":[18.0,0,0],"position":[4.8,4.05,-8.7],"yaw":-28,"spot":"CubbyTop"},{"name":"Blush_Eared_Kitten","label":"Blush Eared Kitten","mesh_name":"CC2_Blush_Eared_Kitten","source_origin":[22.5,0,0],"position":[8.75,2.32,-1.82],"yaw":194,"spot":"Window2"},{"name":"Adorable_Tabby_Kitten","label":"Adorable Tabby Kitten","mesh_name":"CC2_Adorable_Tabby_Kitten","source_origin":[27.0,0,0],"position":[10.65,1.84,-5.5],"yaw":-100,"spot":"Climb0"}]]==])
local o=source.CC2_Origin.Position;local r=source.CC2_Right.Position-o;local f=source.CC2_Front.Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04)
local frame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
local floor=workspace.JapanMap['Outdoor market revision']['Cat cafe']['Shop floor']
local target=CFrame.new(6014,floor.Position.Y+floor.Size.Y/2,7)*CFrame.Angles(0,-math.pi/2,0)
local container=Instance.new('Model');container.Name='Cats';container:SetAttribute('CafeCatsVersion','static_preview2')
local n=0
for i,c in ipairs(CONFIG)do
 local original=assert(source:FindFirstChild(c.mesh_name));local p=original:Clone()
 for _,d in ipairs(p:GetDescendants())do if d:IsA('JointInstance') or d:IsA('Bone')then d:Destroy()end end
 p.Name=c.name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.Color=Color3.new(1,1,1);p.Material=Enum.Material.SmoothPlastic;p.Transparency=0
 local desired=target*CFrame.new(table.unpack(c.position))*CFrame.Angles(0,math.rad(c.yaw),0)
 local src=frame*CFrame.new(c.source_origin[1]+4,0,3)
 p.CFrame=desired*src:ToObjectSpace(original.CFrame);p.PivotOffset=p.CFrame:ToObjectSpace(desired)
 local m=Instance.new('Model');m.Name=c.name;m.PrimaryPart=p;p.Parent=m;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m:SetAttribute('CatSpot',c.spot);m:SetAttribute('CatRigPending',true);m.Parent=container;n+=1
end
assert(n==7);container.Parent=cafe
print('QQ CATCATS RESTING PREVIEW: 7 textured anchored cats at measured pads; idles intentionally pending corrected kit27 import; SERVER ONLY')

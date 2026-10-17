-- Kit27 source preparation AFTER Shannon imports and authorizes. No cafe installation.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and not Run:IsRunning() and game.PlaceId==117372258657114,'Correct Studio Edit place required')
local CONFIG=game:GetService('HttpService'):JSONDecode([==[[{"name":"Whisker_Wonder","label":"Whisker Wonder","mesh_name":"CC3_Whisker_Wonder","source_origin":[0.0,0,0],"position":[-2.55,2.32,-1.82],"yaw":195,"spot":"Window0","bone_prefix":"C01_","bone_parents":{"C01_Root":null,"C01_Body":"C01_Root","C01_Chest":"C01_Body","C01_Head":"C01_Chest","C01_Ear.L":"C01_Head","C01_Ear.R":"C01_Head","C01_Tail1":"C01_Body","C01_Tail2":"C01_Tail1","C01_Tail3":"C01_Tail2","C01_Tail4":"C01_Tail3"}},{"name":"Emerald_Eyed_Tabby_Ki","label":"Emerald Tabby","mesh_name":"CC3_Emerald_Eyed_Tabby_Ki","source_origin":[4.5,0,0],"position":[10.65,3.29,-8.9],"yaw":-110,"spot":"Climb1","bone_prefix":"C02_","bone_parents":{"C02_Root":null,"C02_Body":"C02_Root","C02_Chest":"C02_Body","C02_Head":"C02_Chest","C02_Ear.L":"C02_Head","C02_Ear.R":"C02_Head","C02_Tail1":"C02_Body","C02_Tail2":"C02_Tail1","C02_Tail3":"C02_Tail2","C02_Tail4":"C02_Tail3"}},{"name":"Tuxedo_Kitten","label":"Tuxedo Kitten","mesh_name":"CC3_Tuxedo_Kitten","source_origin":[9.0,0,0],"position":[10.65,4.69,-12.5],"yaw":-122,"spot":"Climb2","bone_prefix":"C03_","bone_parents":{"C03_Root":null,"C03_Body":"C03_Root","C03_Chest":"C03_Body","C03_Head":"C03_Chest","C03_Ear.L":"C03_Head","C03_Ear.R":"C03_Head","C03_Tail1":"C03_Body","C03_Tail2":"C03_Tail1","C03_Tail3":"C03_Tail2","C03_Tail4":"C03_Tail3"}},{"name":"Ginger_Whiskers","label":"Ginger Whiskers","mesh_name":"CC3_Ginger_Whiskers","source_origin":[13.5,0,0],"position":[3.1,2.32,-1.82],"yaw":-105,"spot":"Window1","bone_prefix":"C04_","bone_parents":{"C04_Root":null,"C04_Body":"C04_Root","C04_Chest":"C04_Body","C04_Head":"C04_Chest","C04_Ear.L":"C04_Head","C04_Ear.R":"C04_Head","C04_Tail1":"C04_Body","C04_Tail2":"C04_Tail1","C04_Tail3":"C04_Tail2","C04_Tail4":"C04_Tail3"}},{"name":"Curious_Little_Tabby","label":"Curious Tabby","mesh_name":"CC3_Curious_Little_Tabby","source_origin":[18.0,0,0],"position":[4.8,4.05,-8.7],"yaw":-28,"spot":"CubbyTop","bone_prefix":"C05_","bone_parents":{"C05_Root":null,"C05_Body":"C05_Root","C05_Chest":"C05_Body","C05_Head":"C05_Chest","C05_Ear.L":"C05_Head","C05_Ear.R":"C05_Head","C05_Tail1":"C05_Body","C05_Tail2":"C05_Tail1","C05_Tail3":"C05_Tail2","C05_Tail4":"C05_Tail3"}},{"name":"Blush_Eared_Kitten","label":"Blush Eared Kitten","mesh_name":"CC3_Blush_Eared_Kitten","source_origin":[22.5,0,0],"position":[8.75,2.32,-1.82],"yaw":194,"spot":"Window2","bone_prefix":"C06_","bone_parents":{"C06_Root":null,"C06_Body":"C06_Root","C06_Chest":"C06_Body","C06_Head":"C06_Chest","C06_Ear.L":"C06_Head","C06_Ear.R":"C06_Head","C06_Tail1":"C06_Body","C06_Tail2":"C06_Tail1","C06_Tail3":"C06_Tail2","C06_Tail4":"C06_Tail3"}},{"name":"Adorable_Tabby_Kitten","label":"Adorable Tabby Kitten","mesh_name":"CC3_Adorable_Tabby_Kitten","source_origin":[27.0,0,0],"position":[10.65,1.84,-5.5],"yaw":-100,"spot":"Climb0","bone_prefix":"C07_","bone_parents":{"C07_Root":null,"C07_Body":"C07_Root","C07_Chest":"C07_Body","C07_Head":"C07_Chest","C07_Ear.L":"C07_Head","C07_Ear.R":"C07_Head","C07_Tail1":"C07_Body","C07_Tail2":"C07_Tail1","C07_Tail3":"C07_Tail2","C07_Tail4":"C07_Tail3"}}]]==])
local SS=game:GetService('ServerStorage');local kit=assert(SS:FindFirstChild('JapanGardenKit'))
assert(not kit:FindFirstChild('cat_cafe_cats3') and not kit:FindFirstChild('cafe_cats3_raw'),'Source already exists; inspect before replacing')
local candidates={}
for _,m in ipairs(workspace:GetDescendants())do if m:IsA('Model') and m:FindFirstChild('CC3_Origin') and m:FindFirstChild('CC3_Front')then table.insert(candidates,m)end end
assert(#candidates==1,'Expected one imported kit27 model containing markers; inspect actual hierarchy')
local raw=candidates[1];local expected={CC3_Origin=true,CC3_Right=true,CC3_Front=true};local expectedBones={}
for _,c in ipairs(CONFIG)do expected[c.mesh_name]=true;for name in pairs(c.bone_parents)do expectedBones[name]=true end;expectedBones[c.bone_prefix..'Root']=true end
local parts={};local bones={};local meshes,nb=0,0
for _,d in ipairs(raw:GetDescendants())do
 if d:IsA('MeshPart')then assert(expected[d.Name] and not parts[d.Name],'Unexpected/duplicate mesh '..d.Name);parts[d.Name]=d;meshes+=1
 elseif d:IsA('BasePart')then assert(d.Name=='RootPart' and d:IsA('Part'),'Unexpected import part')
 elseif d:IsA('Bone')then assert(expectedBones[d.Name] and not bones[d.Name],'Unexpected/duplicate bone '..d.Name);bones[d.Name]=d;nb+=1 end
end
assert(meshes==10 and nb==70,'Expected seven cats, three markers, 70 unique bones')
for n in pairs(expected)do assert(parts[n],'Missing '..n)end
for n in pairs(expectedBones)do assert(bones[n],'Missing '..n)end
local o=parts.CC3_Origin.Position;local r=parts.CC3_Right.Position-o;local f=parts.CC3_Front.Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04 and math.abs(r.Unit:Dot(f.Unit))<.001,'Invalid import scale or markers')
-- Inspect the mesh assets' actual bind data, not merely the imported Bone count.
for _,c in ipairs(CONFIG)do
 local p=parts[c.mesh_name];local sa=p:FindFirstChildWhichIsA('SurfaceAppearance')
 assert(p.TextureID~='' or(sa and tostring(sa.ColorMap)~=''),'Missing texture '..p.Name)
 local em=assert(game:GetService('AssetService'):CreateEditableMeshAsync(Content.fromUri(p.MeshId)))
 local ok,err=pcall(function()
  local ids=em:GetBones();assert(#ids==10,'Wrong asset bone count '..p.Name)
  for _,id in ipairs(ids)do
   local name=em:GetBoneName(id);assert(name:sub(1,#c.bone_prefix)==c.bone_prefix and expectedBones[name],'Asset contains another cats bones')
   local b=assert(bones[name]);local parent=em:GetBoneParent(id);local parentName=parent~=0 and em:GetBoneName(parent) or nil
   assert(parentName==c.bone_parents[name],'Asset bone hierarchy differs from source')
   assert((b.Parent:IsA('Bone') and b.Parent.Name or nil)==parentName,'Importer attached bone to wrong parent')
   local bind=p.CFrame*em:GetBoneCFrame(id);local delta=b.WorldCFrame:ToObjectSpace(bind);local _,angle=delta:ToAxisAngle()
   assert(delta.Position.Magnitude<.025 and math.abs(angle)<.005,'Asset/import bind mismatch '..name)
  end
 end)
 em:Destroy();assert(ok,err);task.wait()
end
-- Preflight passed. Preserve raw import and derive one independent skeleton per cat.
local before=#workspace.JapanMap:GetDescendants();local source=Instance.new('Model');source.Name='cat_cafe_cats3'
for _,p in pairs(parts)do
 local clone=p:Clone()
 for _,d in ipairs(clone:GetDescendants())do if d:IsA('JointInstance') or d:IsA('Bone')then d:Destroy()end end
 clone.Anchored=true;clone.CanCollide=false;clone.CanTouch=false;clone.Parent=source
end
for _,c in ipairs(CONFIG)do
 local p=source[c.mesh_name];local made={}
 local function make(name)
  if made[name]then return made[name]end
  local original=assert(bones[name]);local parentName=c.bone_parents[name];local parent=parentName and make(parentName) or p
  local parentWorld=parent:IsA('Bone') and parent.WorldCFrame or parent.CFrame
  local b=Instance.new('Bone');b.Name=name;b.CFrame=parentWorld:ToObjectSpace(original.WorldCFrame);b.Parent=parent;made[name]=b
  return b
 end
 for name in pairs(c.bone_parents)do make(name)end;make(c.bone_prefix..'Root')
 local count=0;for _ in pairs(made)do count+=1 end;assert(count==10)
end
for _,d in ipairs(raw:GetDescendants())do if d:IsA('BasePart')then d.Anchored=true;d.CanCollide=false;d.CanTouch=false end end
raw.Name='cafe_cats3_raw';raw.Parent=kit;source:SetAttribute('CafeCatsSourceVersion','cats3');source.Parent=kit
assert(#workspace.JapanMap:GetDescendants()==before,'Japan map changed during source preparation')
print('QQ CATCATS3 PREP: 10 anchored source meshes, 70 unique bones; all seven asset bind poses verified; independent cat skeletons; raw import preserved; JapanMap unchanged')

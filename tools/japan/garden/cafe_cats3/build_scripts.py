import json
from pathlib import Path
D=Path(__file__).resolve().parent;rows=json.loads((D/'out/manifest.json').read_text())
cfg=[{k:c[k] for k in ['name','label','mesh_name','source_origin','position','yaw','spot','bone_prefix']} for c in rows]
for c,row in zip(cfg,rows):c['bone_parents']={c['bone_prefix']+n:(c['bone_prefix']+b['parent'] if b['parent'] else None) for n,b in row['bones'].items()}
data=json.dumps(cfg,separators=(',',':'))
client=(D.parent/'cafe_cats2/catcafe_cats2_client.lua').read_text()
client=client.replace('local bones={}','local prefix=assert(model:GetAttribute("CatBonePrefix"),"Cat bone prefix missing")\n local bones={}')
client=client.replace("bones[b.Name]={bone=b", "assert(b.Name:sub(1,#prefix)==prefix,'Unexpected bone prefix')\n  bones[b.Name:sub(#prefix+1)]={bone=b")
(D/'catcafe_cats3_client.lua').write_text(client)
installer=(D.parent/'cafe_cats2/catcafe_cats2_template.lua').read_text()
for a,b in [('Kit25','Kit27'),('kit25','kit27'),('cat_cafe_cats2','cat_cafe_cats3'),('CATCAFE_CATS2','CATCAFE_CATS3'),('CATCATS2','CATCATS3'),('CC2_','CC3_'),("'cats2'","'cats3'")]:installer=installer.replace(a,b)
installer=installer.replace("or previous:GetAttribute('CafeCatsVersion')=='cats1'", "or (Run:IsRunning() and previous:GetAttribute('CafeCatsVersion')=='static_preview2')")
installer=installer.replace("model:SetAttribute('CafeCatIndex',i);", "model:SetAttribute('CatBonePrefix',c.bone_prefix);model:SetAttribute('CafeCatIndex',i);")
installer=installer.replace('__CONFIG__',data).replace('__CLIENT__',client)
(D/'catcafe_cats3.lua').write_text(installer)
prep=r'''-- Kit27 source preparation AFTER Shannon imports and authorizes. No cafe installation.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and not Run:IsRunning() and game.PlaceId==117372258657114,'Correct Studio Edit place required')
local CONFIG=game:GetService('HttpService'):JSONDecode([==[__DATA__]==])
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
'''.replace('__DATA__',data)
(D/'prepare_catcafe_cats3.lua').write_text(prep)
print('Wrote guarded kit27 prep, placement and unique-bone client idle controller')

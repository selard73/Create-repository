"""Generate guarded source preparation and a Server-first wall placement script."""
import json
from pathlib import Path
D=Path(__file__).resolve().parent
manifest=json.loads((D/'out/manifest.json').read_text())
data=json.dumps(manifest,separators=(',',':'))
common=r'''local DATA=game:GetService('HttpService'):JSONDecode([==[__DATA__]==])
local expected={};for _,m in ipairs(DATA.meshes)do expected[m.name]=m end
local markers={CW1_Origin=true,CW1_Right=true,CW1_Front=true}
local function inspectWall(root)
 assert(root:IsA('Model'),'Expected inner catwall1 Model')
 local parts={};local n=0
 for _,p in ipairs(root:GetDescendants())do if p:IsA('BasePart')then
  local name=p.Name:gsub('%.%d+$','')
  assert(p:IsA('MeshPart') and expected[name] and not parts[name],'Unexpected/duplicate wall mesh: '..p:GetFullName())
  parts[name]=p;n+=1
 end end
 assert(n==41,'Expected 38 wall decoration meshes and 3 markers')
 for name in pairs(expected)do assert(parts[name],'Missing '..name)end
 local o=parts.CW1_Origin.Position;local r=parts.CW1_Right.Position-o;local f=parts.CW1_Front.Position-o
 assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04 and math.abs(r.Unit:Dot(f.Unit))<.001,'Invalid wall import scale/alignment')
 local frame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
 for name,p in pairs(parts)do
  local lo={math.huge,math.huge,math.huge};local hi={-math.huge,-math.huge,-math.huge}
  for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
   local q=frame:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)))
   for i,v in ipairs({q.X,q.Y,q.Z})do lo[i]=math.min(lo[i],v);hi[i]=math.max(hi[i],v)end
  end end end
  local m=expected[name]
  for i=1,3 do assert(math.abs(lo[i]-m.min[i])<.08 and math.abs(hi[i]-m.max[i])<.08,'Wall bounds mismatch '..name)end
 end
 return parts,frame
end
'''.replace('__DATA__',data)
prepare=r'''-- Only after Shannon imports kit26 and authorizes anchoring/preparation. Source storage only.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and not Run:IsRunning() and game.PlaceId==117372258657114,'Correct Studio Edit place required; prepare BEFORE Play')
'''+common+r'''
local SS=game:GetService('ServerStorage');local kit=SS:FindFirstChild('JapanGardenKit')
local source=kit and kit:FindFirstChild('catwall1')
if source then inspectWall(source);return print('QQ CATWALL1 PREP: existing source validated; no changes')end
local candidates={};for _,d in ipairs(workspace:GetDescendants())do if d:IsA('Model') and d.Name=='catwall1' and d:FindFirstChild('CW1_Origin',true)then table.insert(candidates,d)end end
assert(#candidates==1,'Expected one imported inner catwall1 Model; inspect import hierarchy')
source=candidates[1];local parts=inspectWall(source)
if not kit then kit=Instance.new('Folder');kit.Name='JapanGardenKit';kit.Parent=SS end
for name,p in pairs(parts)do p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false end
source:SetAttribute('CafeWallSourceVersion','catwall1');source.Parent=kit
print('QQ CATWALL1 PREP: 41 anchored source meshes in ServerStorage.JapanGardenKit.catwall1; NOT INSTALLED')
'''
(D/'prepare_catwall1.lua').write_text(prepare)

install=r'''-- Requested left-wall knickknacks. Play-test SERVER first; install only after Shannon approves pictures.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and game.PlaceId==117372258657114,'Wrong place')
assert((Run:IsRunning() and Run:IsServer()) or (not Run:IsRunning() and CATWALL1_ALLOW_EDIT==true),'Server preview only until approved')
'''+common+r'''
local SS=game:GetService('ServerStorage')
local source=assert(SS.JapanGardenKit:FindFirstChild('catwall1'),'Import and prepare kit26 before Play')
assert(source:GetAttribute('CafeWallSourceVersion')=='catwall1','Wall source not prepared')
local parts,sourceFrame=inspectWall(source)
for _,p in pairs(parts)do assert(p.Anchored,'Unanchored source')end
local cafe=assert(workspace.JapanMap:FindFirstChild('ShopFronts') and workspace.JapanMap.ShopFronts:FindFirstChild('CatCafe'),'Run cafe furniture preview first')
assert(cafe:GetAttribute('CatCafeBuildVersion')=='cafe1','Unexpected cafe version')
local previous=cafe:FindFirstChild('LeftWallDecor')
assert(not previous or previous:GetAttribute('CafeWallVersion')=='catwall1','Unrelated existing wall decor')
local floor=workspace.JapanMap['Outdoor market revision']['Cat cafe']['Shop floor']
local target=CFrame.new(6014,floor.Position.Y+floor.Size.Y/2,7)*CFrame.Angles(0,-math.pi/2,0)
local container=Instance.new('Model');container.Name='LeftWallDecor';container:SetAttribute('CafeWallVersion','catwall1')
container.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
local n=0
for name,original in pairs(parts)do if not markers[name]then
 local p=original:Clone();p.Name=name;p.CFrame=target*sourceFrame:ToObjectSpace(original.CFrame)
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=true;p.Transparency=0;p.TextureID=''
 for _,d in ipairs(p:GetDescendants())do if d:IsA('SurfaceAppearance')then d:Destroy()end end
 local m=assert(DATA.materials[name:match('_([^_]+)$')],'Unknown material')
 p.Color=Color3.fromRGB(table.unpack(m.rgb));p.Material=Enum.Material[m.material];p.Parent=container;n+=1
 for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
  local q=target:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)))
  assert(q.X>=-12.64 and q.X<=-11.47 and q.Y>3.72 and q.Y<7.78 and q.Z>-17.08 and q.Z<-3.72,'Decoration outside shallow left wall area: '..name)
 end end end
end end
assert(n==38,'Incomplete wall decor')
if previous then previous:Destroy()end
container.Parent=cafe
print('QQ CATWALL1 DONE: 38 anchored noncollidable meshes; two oak ledges, ceramic cats, planter, books, cup, vase and cat portrait')
print('QQ CATWALL1 PRESERVED: room, furniture, steaming tea, cats, sound, camera and other shops')
print('QQ CATWALL1 STATUS: '..(Run:IsRunning() and 'SERVER PREVIEW' or 'EDIT')..'; NOT PUBLISHED')
'''
(D/'catwall1.lua').write_text(install)

# Combined import preflights BOTH sources fully before its first mutation.
cats=(D.parent/'cafe_cats2/prepare_catcafe_cats2.lua').read_text()
cat_check=cats[cats.index('local names='):cats.index("local SS=game:GetService('ServerStorage')")].replace('local function inspect(root)','local function inspectCats(root)').replace('Kit25','Cat')
combined=r'''-- Kit26 contains the seven waiting cats PLUS requested left-wall decor. Authorize source prep before running.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and not Run:IsRunning() and game.PlaceId==117372258657114,'Correct Studio Edit place required; prepare BEFORE Play')
'''+cat_check+common+r'''
local SS=game:GetService('ServerStorage');local kit=SS:FindFirstChild('JapanGardenKit')
local function findSource(name,marker)
 local found={};if kit and kit:FindFirstChild(name)then table.insert(found,kit[name])end
 for _,d in ipairs(workspace:GetDescendants())do if d:IsA('Model') and d.Name==name and d:FindFirstChild(marker,true)then table.insert(found,d)end end
 assert(#found==1,'Expected one source named '..name..'; inspect hierarchy/duplicates before changing anything')
 return found[1]
end
local cats=findSource('cat_cafe_cats2','CC2_Origin');local wall=findSource('catwall1','CW1_Origin')
local catParts=inspectCats(cats);local wallParts=inspectWall(wall)
-- All validation above is read-only; mutation begins here after both sources pass.
if not kit then kit=Instance.new('Folder');kit.Name='JapanGardenKit';kit.Parent=SS end
for _,parts in ipairs({catParts,wallParts})do for name,p in pairs(parts)do
 p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false
end end
cats:SetAttribute('CafeCatsSourceVersion','cats2');wall:SetAttribute('CafeWallSourceVersion','catwall1');cats.Parent=kit;wall.Parent=kit
print('QQ CAFE_FINISHING1 PREP: 51 meshes anchored, 70 cat bones; both sources in ServerStorage.JapanGardenKit; existing cafe unchanged; NOT INSTALLED')
'''
(D/'prepare_cafe_finishing1.lua').write_text(combined)
print('WROTE prepare_catwall1.lua, catwall1.lua, prepare_cafe_finishing1.lua')

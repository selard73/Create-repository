-- Run in Edit only AFTER Shannon imports kit25 and authorizes anchoring/preparation.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and not Run:IsRunning() and game.PlaceId==117372258657114,'Prepare only in the correct Studio Edit place')
local names={'CC2_Whisker_Wonder','CC2_Emerald_Eyed_Tabby_Ki','CC2_Tuxedo_Kitten','CC2_Ginger_Whiskers','CC2_Curious_Little_Tabby','CC2_Blush_Eared_Kitten','CC2_Adorable_Tabby_Kitten','CC2_Origin','CC2_Right','CC2_Front'}
local expected={};for _,n in ipairs(names)do expected[n]=true end
local function inspect(root)
 local parts={};local count=0;local bones=0
 for _,p in ipairs(root:GetDescendants())do if p:IsA('BasePart')then
  local n=p.Name:gsub('%.%d+$','');assert(p:IsA('MeshPart') and expected[n] and not parts[n],'Unexpected/duplicate imported part: '..p:GetFullName())
  parts[n]=p;count+=1
  if n~='CC2_Origin' and n~='CC2_Right' and n~='CC2_Front'then
   local nb=0;local bn={};for _,b in ipairs(p:GetDescendants())do if b:IsA('Bone')then nb+=1;bn[b.Name]=true end end
   assert(nb==10 and bn.Root and bn.Head and bn.Chest and bn.Tail4,'Cat skin/bones did not import intact: '..n);bones+=nb
   local sa=p:FindFirstChildWhichIsA('SurfaceAppearance');assert(p.TextureID~='' or(sa and tostring(sa.ColorMap)~=''),'Cat texture is missing: '..n)
  end
 end end
 assert(count==10 and bones==70,'Expected 7 skinned cats, 70 bones and 3 markers')
 for _,n in ipairs(names)do assert(parts[n],n..' missing')end
 local o=parts.CC2_Origin.Position;local r=parts.CC2_Right.Position-o;local f=parts.CC2_Front.Position-o
 assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04,'Kit25 import scale is not 1:1; inspect before anchoring')
 assert(math.abs(r.Unit:Dot(f.Unit))<.001,'Invalid alignment markers')
 return parts
end
local SS=game:GetService('ServerStorage');local kit=SS:FindFirstChild('JapanGardenKit');local existing=kit and kit:FindFirstChild('cat_cafe_cats2')
if existing then inspect(existing);return print('QQ CATCATS2 PREP: existing source validated; no changes')end
local candidates={}
for _,d in ipairs(workspace:GetDescendants())do if d:IsA('Model') and d.Name=='cat_cafe_cats2' and d:FindFirstChild('CC2_Origin',true)then table.insert(candidates,d)end end
assert(#candidates==1,'Expected one imported inner cat_cafe_cats2 Model; inspect import hierarchy')
local source=candidates[1];local parts=inspect(source)
if not kit then kit=Instance.new('Folder');kit.Name='JapanGardenKit';kit.Parent=SS end
for n,p in pairs(parts)do p.Name=n;p.Anchored=true;p.CanCollide=false;p.CanTouch=false end
source:SetAttribute('CafeCatsSourceVersion','cats2');source.Parent=kit
print('QQ CATCATS2 PREP: 10 anchored meshes, 70 bones; source ServerStorage.JapanGardenKit.cat_cafe_cats2; NOT INSTALLED')

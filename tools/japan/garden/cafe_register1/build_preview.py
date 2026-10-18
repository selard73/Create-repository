from pathlib import Path
import json
D=Path(__file__).resolve().parent
old=Path(r'C:\Users\slard\Create-repository\tools\japan\garden\cafe_detail1\detail_patch.lua').read_text()
# A new guarded installer starts from the actual installed scene, not the rejected Play variant.
old=old.replace('CAFEDETAIL1_ALLOW_EDIT','CAFEREGISTER1_ALLOW_EDIT')
old=old.replace('CafeInterior_pre_detail1','CafeInterior_pre_register1')
old=old.replace('C1_CounterMenu=Vector3.new(3.15,0,3.05),','')
old=old.replace('C1_TeaService=Vector3.new(-.7,0,3.6)','C1_TeaService=Vector3.new(-1.0,0,3.6)')
old=old.replace('allow(window);allow(counterPlant,true);allow(portrait);permitted[cushion]={}', 'allow(window);allow(counterPlant,true);allow(portrait);permitted[cushion]={};permitted[furniture.C1_CounterMenu_Paper]={hide=true}')
old=old.replace('and p.Transparency==b.transparency','and(p.Transparency==b.transparency or(permit and permit.hide and p.Transparency==1))')
old=old.replace('and p.CanQuery==b.query','and(p.CanQuery==b.query or(permit and permit.hide and not p.CanQuery))')
start=old.index('label.Text="ORDER & PAY"');end=old.index('-- Reuse the imported three-piece',start)
old=old[:start]+'''-- Retire the old little menu board visually; there is no ORDER/PAY sign.
furniture.C1_CounterMenu_Paper.Transparency=1;furniture.C1_CounterMenu_Paper.CanQuery=false
furniture.C1_CounterMenu_Paper.CafeLabel.Enabled=false
local details=Instance.new("Model");details.Name="ServiceCounterDetails"
local targets={Register=frame*CFrame.new(1.85,3.09,-22.15),Tray=frame*CFrame.new(1.90,3.09,-20.95)}
local origins={Register=Vector3.zero,Tray=Vector3.new(3,0,0)}
local made=0
for _,p in ipairs(registerSource:GetDescendants())do if p:IsA("MeshPart")then
 local group,color=p.Name:match("^CR1_(Register)_([^_]+)$")
 if not group then group,color=p.Name:match("^CR1_(Tray)_([^_]+)$")end
 if group then
  local c=p:Clone();c.CFrame=targets[group]*CFrame.new(-origins[group])*registerFrame:ToObjectSpace(p.CFrame)
  c.Color=Color3.fromRGB(table.unpack(REGISTER_COLORS[color]));c.Material=color=="Brass"and Enum.Material.Metal or Enum.Material.SmoothPlastic
  c.Anchored=true;c.CanCollide=false;c.CanTouch=false;c.CanQuery=false;c.CastShadow=true;c.Parent=details;made+=1
 end
end end
assert(made==REGISTER_MESH_COUNT,"Register import inventory mismatch")
details.Parent=room
''' +old[end:]
old=old.replace('room:SetAttribute("CafeDetailVersion","detail1")','room:SetAttribute("CafeDetailVersion","register1")')
old=old.replace('four real-mesh additions','register/tray and three landing-perch real-mesh additions')
old=old.replace('central order/payment area; no attendant or payment gameplay added','proper mesh register with keypad, cash drawer, receipt and two-sided display; change tray; no sign, attendant or payment gameplay')
manifest=json.loads((D/'manifest.json').read_text())
mesh_count=sum(not m['name'].startswith(('CR1_Origin','CR1_Right','CR1_Front'))for m in manifest['meshes'])
pre='''-- Kit31 must be imported and anchored before Play; all checks precede original cafe mutations.
local registerSource=assert(game.ServerStorage.JapanGardenKit:FindFirstChild("cafe_register1"),"Import and anchor kit31 cafe register first")
local function marker(name)local p=assert(registerSource:FindFirstChild(name,true),"Missing register alignment marker "..name);assert(p:IsA("MeshPart"));return p.Position end
local origin=marker("CR1_Origin");local right=marker("CR1_Right")-origin;local front=marker("CR1_Front")-origin
assert(math.abs(right.Magnitude-2)<.01 and math.abs(front.Magnitude-2)<.01 and math.abs(right.Unit:Dot(front.Unit))<.001,"Register scale/alignment differs")
local registerFrame=CFrame.fromMatrix(origin,right.Unit,front.Unit:Cross(right.Unit),front.Unit)
local REGISTER_COLORS=game.HttpService:JSONDecode([==[__COLORS__]==])
local REGISTER_MESH_COUNT=__COUNT__
local seen={};local found=0
for _,p in ipairs(registerSource:GetDescendants())do
 assert(not p:IsA("LuaSourceContainer"),"Unexpected executable kit content")
 if p:IsA("BasePart")then
  assert(p:IsA("MeshPart")and p.Anchored,"Register must be anchored real meshes")
  if p.Name:match("^CR1_Register_")or p.Name:match("^CR1_Tray_")then
   assert(not seen[p.Name],"Duplicate register mesh");seen[p.Name]=true;found+=1
   assert(REGISTER_COLORS[p.Name:match("_([^_]+)$")],"Unknown register material")
  end
 end
end
assert(found==REGISTER_MESH_COUNT,"Expected complete register and tray")
'''.replace('__COLORS__',json.dumps(manifest['materials'],separators=(',',':'))).replace('__COUNT__',str(mesh_count))
anchor='local before={};local originals=0;local permitted={}'
assert old.count(anchor)==1
old=old.replace(anchor,pre+'\n'+anchor)
(D/'preview_register1.lua').write_text(old)
print('Guarded kit31 preview prepared: '+str(mesh_count)+' register/tray meshes, plus three perch meshes')

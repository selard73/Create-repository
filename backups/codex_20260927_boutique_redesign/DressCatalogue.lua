-- Original boutique dresses. Separate torso and skirt fitting supports R6 and R15.
local C=Color3.fromRGB
local M={}
M.styles={
 {id='rue',name='Rue sundress',price=60,length=1.65,colours={
  {name='Buttercup',fabric=C(240,192,75),trim=C(255,244,212)},
  {name='Rose',fabric=C(192,100,116),trim=C(255,229,197)},
  {name='Pine',fabric=C(39,103,69),trim=C(226,184,94)}}},
 {id='cafe',name='Cafe day dress',price=90,length=1.95,colours={
  {name='Rust',fabric=C(170,79,47),trim=C(249,220,178)},
  {name='Blueberry',fabric=C(53,64,113),trim=C(247,218,165)},
  {name='Honey',fabric=C(202,151,54),trim=C(89,58,41)}}},
 {id='chateau',name='Chateau evening',price=140,length=2.5,colours={
  {name='Midnight',fabric=C(43,43,73),trim=C(229,187,94)},
  {name='Burgundy',fabric=C(129,41,62),trim=C(239,197,119)},
  {name='Ivory',fabric=C(245,233,206),trim=C(175,126,44)}}}
}
M.byId={};M.byStyle={};M.order={}
for _,s in ipairs(M.styles) do M.byStyle[s.id]=s;for k,c in ipairs(s.colours) do
 local id=s.id..'_'..k;M.byId[id]={id=id,style=s,colour=c};table.insert(M.order,id)
end end
function M.title(id) local d=M.byId[id];return d and (d.colour.name..' '..d.style.name) or '' end
M.centres={["Bodice_rue"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_rue"]=Vector3.new(0.000000,-0.825000,0.000000),["Belt_rue"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_rue"]=Vector3.new(0.000000,-1.602500,0.000000),["Collar_rue"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_cafe"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_cafe"]=Vector3.new(0.000000,-0.975000,0.000000),["Belt_cafe"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_cafe"]=Vector3.new(0.000000,-1.902500,0.000000),["Collar_cafe"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_chateau"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_chateau"]=Vector3.new(0.000000,-1.250000,0.000000),["Belt_chateau"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_chateau"]=Vector3.new(0.000000,-2.452500,0.000000),["Collar_chateau"]=Vector3.new(0.000000,0.983500,0.000000)}
M.sizes={["Bodice_rue"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_rue"]=Vector3.new(3.045000,1.650000,2.375100),["Belt_rue"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_rue"]=Vector3.new(3.061240,0.075000,2.391340),["Collar_rue"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_cafe"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_cafe"]=Vector3.new(3.536000,1.950000,2.758080),["Belt_cafe"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_cafe"]=Vector3.new(3.552640,0.075000,2.774720),["Collar_cafe"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_chateau"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_chateau"]=Vector3.new(3.845600,2.500000,2.999568),["Belt_chateau"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_chateau"]=Vector3.new(3.861792,0.075000,3.015760),["Collar_chateau"]=Vector3.new(0.960000,0.057000,0.794000)}
local function mult(a,b) return Vector3.new(a.X*b.X,a.Y*b.Y,a.Z*b.Z) end
-- cf is waist centre; reference torso occupies y=0..2, skirt y=0 downward.
function M.pieces(kit,id,cf,s)
 local d=M.byId[id];if not d then return {} end
 s=type(s)=='number' and Vector3.new(s,s,s) or s or Vector3.one
 local out={}
 for _,prefix in ipairs({'Bodice_','Skirt_','Belt_','Hem_','Collar_'}) do
  local name=prefix..d.style.id;local p=assert(kit:FindFirstChild(name),'Missing dress mesh '..name):Clone()
  local center=M.centres[name];if prefix=='Bodice_' or prefix=='Collar_' then center+=Vector3.new(0,1,0) end
  p.Size=mult(M.sizes[name],s);p.CFrame=cf*CFrame.new(mult(center,s))
  p.Color=(prefix=='Bodice_' or prefix=='Skirt_') and d.colour.fabric or d.colour.trim
  p.TextureID='';p.Material=Enum.Material.Fabric;p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true
  p:SetAttribute('DressSection',(prefix=='Bodice_' or prefix=='Collar_') and 'upper' or 'lower')
  table.insert(out,p)
 end
 return out
end
function M.attach(kit,id,char,name)
 local upper=char:FindFirstChild('UpperTorso') or char:FindFirstChild('Torso')
 local lower=char:FindFirstChild('LowerTorso') or upper
 if not upper or not lower or not M.byId[id] then return nil end
 local scale=Vector3.new(math.clamp(upper.Size.X/2,0.45,2),math.clamp(upper.Size.Y/2,0.4,2),math.clamp(upper.Size.Z/1.1,0.45,2))
 -- Use standing height, avoiding inflated mesh bounds on stylized legs.
 local hum=char:FindFirstChildOfClass('Humanoid');local root=char:FindFirstChild('HumanoidRootPart')
 local waist=upper.CFrame*CFrame.new(0,-upper.Size.Y/2,0)
 local floorY=root and (root.Position.Y-root.Size.Y/2-(hum and hum.HipHeight or 2)) or (waist.Position.Y-2.5)
 if lower==upper then floorY=waist.Position.Y-2 end
 local height=math.max(1.4,waist.Position.Y-floorY-.12)
 local skirtScale=Vector3.new(scale.X*1.23,math.clamp(height/2.5,.45,2),scale.Z*1.7)
 local lowerWaist=waist
 local m=Instance.new('Model');m.Name=name or 'WornDress';m:SetAttribute('DressId',id)
 for _,p in ipairs(M.pieces(kit,id,CFrame.new(),1)) do
  local top=p:GetAttribute('DressSection')=='upper';local sc=top and scale or skirtScale
  p.Size=mult(p.Size,sc);p.CFrame=(top and waist or lowerWaist)*CFrame.new(mult(p.Position,sc));p.Parent=m
  local weld=Instance.new('WeldConstraint');weld.Part0=upper;weld.Part1=p;weld.Parent=p
 end
 m.Parent=char;return m
end
-- Only costume-covered layers are hidden; hair, hats, face accessories and shoes stay.
function M.covered(char,id)
 local out={}
 for _,o in ipairs(char:GetChildren()) do
  if o:IsA('BasePart') and (o.Name=='UpperTorso' or o.Name=='LowerTorso' or o.Name=='Torso' or o.Name=='LeftUpperLeg' or o.Name=='RightUpperLeg' or ((id or ''):sub(1,7)=='chateau' and (o.Name=='LeftLowerLeg' or o.Name=='RightLowerLeg'))) then table.insert(out,o)
  elseif o:IsA('Accessory') then
   local t=o.AccessoryType.Name
   if t=='Jacket' or t=='Sweater' or t=='Shirt' or t=='TShirt' or t=='DressSkirt' or t=='Waist' or t=='Pants' or t=='Shorts' then
    for _,p in ipairs(o:GetDescendants()) do if p:IsA('BasePart') then table.insert(out,p) end end
   end
  end
 end
 return out
end
function M.clothing(char)
 local out={}
 for _,o in ipairs(char:GetChildren()) do
  if o:IsA('Shirt') then table.insert(out,{o,'ShirtTemplate'})
  elseif o:IsA('Pants') then table.insert(out,{o,'PantsTemplate'})
  elseif o:IsA('ShirtGraphic') then table.insert(out,{o,'Graphic'}) end
 end
 return out
end
return M


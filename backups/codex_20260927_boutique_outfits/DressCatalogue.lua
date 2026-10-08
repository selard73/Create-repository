-- Mode et Style: six dress silhouettes, three eyewear shapes and pearl jewellery.
-- Original nine purchase IDs remain stable. Geometry is shared by displays,
-- product previews and worn items so the player buys exactly what they see.
local C=Color3.fromRGB
local V=Vector3.new
local M={slots={'dress','eyewear','necklace'},models={dress='WornDress',eyewear='WornSunglasses',necklace='WornNecklace'}}
local function colour(name,fabric,trim,accent)return {name=name,fabric=C(table.unpack(fabric)),trim=C(table.unpack(trim)),accent=C(table.unpack(accent or trim))}end
M.styles={
 {id='rue',name='Acorn picnic',slot='dress',price=60,length=1.95,mesh='rue',neck=.80,detail='bow',colours={
  colour('Buttercup',{245,192,71},{255,245,218},{123,83,35}),colour('Rose',{209,111,134},{255,230,216},{143,58,81}),colour('Pine',{31,103,75},{244,210,136},{217,164,62})}},
 {id='cafe',name='Woodland ribbons',slot='dress',price=90,length=2.10,mesh='cafe',neck=.90,detail='collar',colours={
  colour('Rust',{167,72,46},{255,239,207},{85,49,32}),colour('Blueberry',{51,67,119},{247,224,190},{219,175,71}),colour('Honey',{222,172,62},{255,242,210},{101,63,34})}},
 {id='chateau',name='Starlight gown',slot='dress',price=140,length=2.55,mesh='chateau',neck=.73,detail='pearls',colours={
  colour('Midnight',{37,43,72},{231,185,88},{255,238,196}),colour('Burgundy',{121,31,60},{226,178,89},{255,227,195}),colour('Ivory',{247,229,198},{181,130,47},{228,184,91})}},
 {id='riviera',name='Carousel dress',slot='dress',price=80,length=1.82,mesh='rue',neck=.86,detail='sailor',colours={
  colour('Navy',{36,55,85},{255,244,214},{173,49,52}),colour('Cherry',{177,50,59},{255,240,213},{44,57,84}),colour('Cream',{247,228,190},{40,65,96},{196,129,40})}},
 {id='jardin',name='Petal party',slot='dress',price=110,length=2.14,mesh='cafe',neck=.76,detail='flowers',colours={
  colour('Peony',{226,144,156},{255,233,202},{157,62,91}),colour('Lavender',{151,127,179},{249,229,195},{88,72,123}),colour('Sage',{112,145,114},{255,227,187},{212,137,128})}},
 {id='soiree',name='Golden acorn gown',slot='dress',price=155,length=2.48,mesh='chateau',neck=.72,detail='sash',colours={
  colour('Onyx',{40,37,45},{215,165,75},{247,217,141}),colour('Emerald',{24,89,63},{213,179,108},{243,224,177}),colour('Champagne',{220,188,141},{255,236,195},{148,105,53})}},
 {id='round',name='Sunbeam rounds',slot='eyewear',price=35,detail='round',colours={
  colour('Gold',{197,148,59},{54,46,47}),colour('Tortoise',{111,62,36},{48,51,46}),colour('Rose',{195,100,112},{74,45,67})}},
 {id='cateye',name='Butterfly sunglasses',slot='eyewear',price=50,detail='cateye',colours={
  colour('Black',{38,34,39},{49,48,57}),colour('Cherry',{170,42,54},{63,33,49}),colour('Ivory',{246,226,188},{84,66,48})}},
 {id='aviator',name='Adventure aviators',slot='eyewear',price=60,detail='aviator',colours={
  colour('Brass',{196,152,66},{43,59,50}),colour('Silver',{180,187,192},{43,53,74}),colour('Copper',{184,110,76},{72,49,42})}},
 {id='pearls',name='Pearl pendants',slot='necklace',price=45,detail='pearls',colours={
  colour('Acorn',{252,230,189},{187,130,47},{223,172,71}),colour('Ruby',{255,235,210},{210,164,79},{167,43,68}),colour('Emerald',{251,235,212},{210,164,79},{30,112,76})}}
}
M.byId={};M.byStyle={};M.order={}
for _,s in ipairs(M.styles)do M.byStyle[s.id]=s;for k,c in ipairs(s.colours)do local id=s.id..'_'..k;M.byId[id]={id=id,style=s,colour=c};M.order[#M.order+1]=id end end
function M.title(id)local d=M.byId[id];return d and d.colour.name..' '..d.style.name or '' end
function M.slot(id)return M.byId[id] and M.byId[id].style.slot or 'dress' end
M.centres={["Bodice_rue"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_rue"]=Vector3.new(0.000000,-0.825000,0.000000),["Belt_rue"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_rue"]=Vector3.new(0.000000,-1.602500,0.000000),["Collar_rue"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_cafe"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_cafe"]=Vector3.new(0.000000,-0.975000,0.000000),["Belt_cafe"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_cafe"]=Vector3.new(0.000000,-1.902500,0.000000),["Collar_cafe"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_chateau"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_chateau"]=Vector3.new(0.000000,-1.250000,0.000000),["Belt_chateau"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_chateau"]=Vector3.new(0.000000,-2.452500,0.000000),["Collar_chateau"]=Vector3.new(0.000000,0.983500,0.000000)}
M.sizes={["Bodice_rue"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_rue"]=Vector3.new(3.045000,1.650000,2.375100),["Belt_rue"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_rue"]=Vector3.new(3.061240,0.075000,2.391340),["Collar_rue"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_cafe"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_cafe"]=Vector3.new(3.536000,1.950000,2.758080),["Belt_cafe"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_cafe"]=Vector3.new(3.552640,0.075000,2.774720),["Collar_cafe"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_chateau"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_chateau"]=Vector3.new(3.845600,2.500000,2.999568),["Belt_chateau"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_chateau"]=Vector3.new(3.861792,0.075000,3.015760),["Collar_chateau"]=Vector3.new(0.960000,0.057000,0.794000)}

local function mult(a,b)return V(a.X*b.X,a.Y*b.Y,a.Z*b.Z)end
function M.pieces(kit,id,cf,scale)
 local d=M.byId[id];if not d then return {}end
 local s,c=d.style,d.colour;local out={}
 scale=type(scale)=='number' and V(scale,scale,scale) or scale or Vector3.one
 local function finish(p,name,pos,size,color,section,rot)
  p.Name=name;p.Size=mult(size,scale);p.CFrame=cf*CFrame.new(mult(pos,scale))*(rot or CFrame.new())
  p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Reflectance=0;p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.CastShadow=false
  p:SetAttribute('DressSection',section or 'upper');out[#out+1]=p;return p
 end
 local function part(name,pos,size,color,section,rot,shape)
  local p=Instance.new('Part');p.Shape=shape or Enum.PartType.Block;return finish(p,name,pos,size,color,section,rot)
 end
 local function ball(name,pos,size,color,section,rot)return part(name,pos,size,color,section,rot,Enum.PartType.Ball)end
 local function line(name,a,b,width,color,section)
  local p=part(name,(a+b)/2,V(width,width,(b-a).Magnitude),color,section,CFrame.lookAt(Vector3.zero,b-a));return p
 end
 local function mesh(prefix,style,sizeFactor,offset,color,section)
  local name=prefix..'_'..style;local p=assert(kit:FindFirstChild(name),name):Clone();p.TextureID=''
  return finish(p,prefix,mult(M.centres[name],sizeFactor)+offset,mult(M.sizes[name],sizeFactor),color,section)
 end
 local function bow(pos,color,section,size)
  size=size or 1
  ball('RibbonWing',pos+V(-.17,0,0)*size,V(.40,.24,.10)*size,color,section,CFrame.Angles(0,0,-.30))
  ball('RibbonWing',pos+V(.17,0,0)*size,V(.40,.24,.10)*size,color,section,CFrame.Angles(0,0,.30))
  ball('RibbonKnot',pos+V(0,0,-.05)*size,V(.14,.17,.13)*size,color,section)
  for _,side in ipairs({-1,1})do part('RibbonTail',pos+V(side*.10,-.21,.01)*size,V(.13,.32,.04)*size,color,section,CFrame.Angles(0,0,side*.22))end
 end
 local function flower(pos,r,color,section)
  for k=1,5 do local a=k*math.pi*2/5;ball('Petal',pos+V(math.sin(a)*r*.54,math.cos(a)*r*.54,0),V(r*.9,r*.9,.055),color,section)end
  ball('FlowerHeart',pos+V(0,0,-.035),V(r*.42,r*.42,.08),c.accent,section)
 end
 if s.slot=='eyewear' then
  local round=s.detail=='round';local aviator=s.detail=='aviator';local rx=round and .225 or .26;local ry=round and .225 or aviator and .245 or .18
  for _,side in ipairs({-1,1})do
   local center=V(side*.285,.055,-.59)
   local lens=ball('TintedLens',center,V(rx*1.94,ry*1.94,.055),c.trim,'head');lens.Reflectance=.09
   for k=0,15 do
    local function point(a)
     local x=math.cos(a)*rx;local y=math.sin(a)*ry
     if s.detail=='cateye' then y+=math.max(0,x*side)*.34 end
     if aviator then x*=.95+.12*math.sin(a) end
     return center+V(x,y,-.024)
    end
    line('Rim',point(k*math.pi/8),point((k+1)*math.pi/8),aviator and .023 or .042,c.fabric,'head')
   end
   line('Temple',V(side*.53,.08,-.58),V(side*.57,.08,.12),.035,c.fabric,'head')
   ball('LensGlint',center+V(-.06,.075,-.043),V(.065,.024,.014),c.fabric:Lerp(C(255,255,255),.65),'head',CFrame.Angles(0,0,-.35))
  end
  line('Bridge',V(-.07,.095,-.61),V(.07,.095,-.61),.035,c.fabric,'head')
  if aviator then line('BrowBridge',V(-.12,.23,-.60),V(.12,.23,-.60),.025,c.fabric,'head')end
 elseif s.slot=='necklace' then
  for i=0,12 do local t=i/12*math.pi;ball('Pearl',V(math.cos(t)*.47,1.91-math.sin(t)*.27,-.42-math.sin(t)*.19),V(.083,.083,.083),c.fabric)end
  ball('PendantSetting',V(0,1.48,-.65),V(.22,.25,.07),c.trim)
  ball('Pendant',V(0,1.48,-.70),V(.15,.19,.065),c.accent)
  if c.name=='Acorn' then ball('AcornCap',V(0,1.55,-.72),V(.18,.085,.07),c.trim)end
 else
  local length=s.length;local baseLength=({rue=1.65,cafe=1.95,chateau=2.5})[s.mesh]
  mesh('Bodice',s.mesh,V(1,s.neck,1),V(0,s.neck,0),c.fabric,'upper')
  mesh('Skirt',s.mesh,V(1,length/baseLength,1),Vector3.zero,c.fabric,'lower')
  mesh('Belt',s.mesh,V(1.025,1.15,1.025),V(0,.015,0),c.trim,'lower')
  mesh('Hem',s.mesh,V(1,length/baseLength,.999),Vector3.zero,c.trim,'lower')
  if s.detail~='sash' then
   for _,side in ipairs({-1,1})do
    part('ShoulderRibbon',V(side*.72,1.79,-.43),V(s.detail=='sailor' and .30 or .17,.49,.085),c.fabric,'upper',CFrame.Angles(-.20,0,side*.08))
    part('ShoulderTop',V(side*.72,2.02,0),V(.18,.08,.91),c.fabric)
   end
  end
  if s.detail=='bow' then
   bow(V(-.48,.14,-.63),c.trim,'lower',1)
   for row=1,3 do for col=-2,2 do
    ball('BodiceDot',V(col*.30,.40+row*.28,-.62),V(.055,.055,.014),c.trim)
   end end
  elseif s.detail=='collar' or s.detail=='sailor' then
   for _,side in ipairs({-1,1})do
    part('FoldedCollar',V(side*.26,1.73,-.58),V(.43,.27,.06),c.trim,'upper',CFrame.Angles(0,0,side*.43))
   end
   if s.detail=='sailor' then
    bow(V(0,1.36,-.65),c.accent,'upper',.8)
    for k=1,2 do mesh('Hem',s.mesh,V(.955-k*.025,1-k*.075,.955-k*.025),V(0,-length*.03,0),c.trim,'lower')end
   else
    for k=1,4 do ball('BrassButton',V(0,.38+k*.24,-.63),V(.063,.063,.04),c.accent)end
    bow(V(.58,.14,-.64),c.trim,'lower',1.15)
   end
  elseif s.detail=='pearls' then
   for k=-5,5 do local t=k/5;ball('PearlNeckline',V(t*.58,1.43+.15*math.abs(t),-.58),V(.055,.055,.055),c.accent)end
   ball('WaistBrooch',V(0,.10,-.66),V(.25,.18,.09),c.accent,'lower')
   for i=1,7 do
    local t=(i-4)*.29;local y=-1.0-(i%3)*.25;local r=1.13+(-y/length)*.69
    local pos=V(math.sin(t)*r,y,-math.cos(t)*r*.79)
    for k=0,3 do part('Starlight',pos,V(.024,.20,.023),c.trim,'lower',CFrame.Angles(0,0,k*math.pi/4))end
   end
   for k=-1,1 do part('SatinPleat',V(k*.22,-.44,-.74),V(.035,.83,.026),c.trim,'lower',CFrame.Angles(.28,0,k*.16))end
  elseif s.detail=='flowers' then
   -- Overlapping petal-shaped flounces make a full, playful party skirt.
   for layer=1,2 do
    local factor=layer==1 and .80 or .93
    mesh('Skirt',s.mesh,V(factor,.42,factor),V(0,-.30-(layer-1)*.59,0),c.fabric:Lerp(c.trim,layer==1 and .20 or .08),'lower')
    mesh('Hem',s.mesh,V(factor,.42,factor),V(0,-.30-(layer-1)*.59,0),c.trim,'lower')
   end
   flower(V(-.70,1.70,-.54),.22,c.trim,'upper');bow(V(.48,.10,-.64),c.trim,'lower',.9)
   for i=1,6 do local t=(i-3.5)*.34;local y=-.80-(i%2)*.34;local r=1.1+(-y/length)*.50
    flower(V(math.sin(t)*r,y,-math.cos(t)*r*.79),.12,c.trim,'lower')
   end
  elseif s.detail=='sash' then
   part('OneShoulderSash',V(-.46,1.72,-.49),V(.38,.88,.07),c.trim,'upper',CFrame.Angles(0,0,-.45))
   part('SashShoulder',V(-.72,2.02,0),V(.25,.085,.94),c.trim)
   bow(V(-.66,.10,-.65),c.trim,'lower',1.1)
   ball('AcornClasp',V(-.66,.08,-.79),V(.18,.24,.12),c.accent,'lower')
   ball('AcornCap',V(-.66,.16,-.82),V(.21,.10,.13),c.trim,'lower')
   part('FallingSash',V(-.63,-.72,-.85),V(.27,1.52,.055),c.trim,'lower',CFrame.Angles(.24,0,-.12))
  end
 end
 return out
end
function M.attach(kit,id,char,name)
 local d=M.byId[id];if not d then return nil end
 local upper=char:FindFirstChild('UpperTorso') or char:FindFirstChild('Torso');local lower=char:FindFirstChild('LowerTorso') or upper;local head=char:FindFirstChild('Head')
 if not upper or not lower or (d.style.slot=='eyewear' and not head)then return nil end
 local scale=V(math.clamp(upper.Size.X/2,.45,2),math.clamp(upper.Size.Y/2,.4,2),math.clamp(upper.Size.Z/1.1,.45,2))
 local waist=upper.CFrame*CFrame.new(0,-upper.Size.Y/2,0)
 local hum=char:FindFirstChildOfClass('Humanoid');local root=char:FindFirstChild('HumanoidRootPart')
 local floorY=root and root.Position.Y-root.Size.Y/2-(hum and hum.HipHeight or 2) or waist.Position.Y-2.5
 if lower==upper then floorY=waist.Position.Y-2 end
 local height=math.max(1.4,waist.Position.Y-floorY-.12)
 local skirtScale=V(scale.X*1.26,math.clamp(height/2.55,.45,2),scale.Z*1.42)
 local m=Instance.new('Model');m.Name=name or M.models[d.style.slot];m:SetAttribute('DressId',id);m:SetAttribute('BoutiqueSlot',d.style.slot)
 for _,p in ipairs(M.pieces(kit,id,CFrame.new(),1))do
  local section=p:GetAttribute('DressSection');local base,sc,joint=waist,scale,upper
  if section=='lower' then sc=skirtScale;joint=lower
  elseif section=='head' then base=head.CFrame;sc=V(head.Size.X/1.2,head.Size.Y/1.2,head.Size.Z/1.2);joint=head end
  local rotation=p.CFrame.Rotation;p.Size=mult(p.Size,sc);p.CFrame=base*CFrame.new(mult(p.Position,sc))*rotation;p.Parent=m
  local weld=Instance.new('WeldConstraint');weld.Part0=joint;weld.Part1=p;weld.Parent=p
 end
 m.Parent=char;return m
end
function M.covered(char,id)
 local out={};local slot=M.slot(id)
 for _,o in ipairs(char:GetChildren())do
  if slot=='dress' and o:IsA('BasePart') and (o.Name=='LowerTorso' or o.Name=='LeftUpperLeg' or o.Name=='RightUpperLeg' or o.Name=='LeftLowerLeg' or o.Name=='RightLowerLeg') then out[#out+1]=o
  elseif o:IsA('Accessory') then local t=o.AccessoryType.Name
   local hide=slot=='eyewear' and t=='Face' or slot=='necklace' and t=='Neck' or slot=='dress' and (t=='Jacket' or t=='Sweater' or t=='Shirt' or t=='TShirt' or t=='DressSkirt' or t=='Waist' or t=='Pants' or t=='Shorts')
   if hide then for _,p in ipairs(o:GetDescendants())do if p:IsA('BasePart')then out[#out+1]=p end end end
  end
 end
 return out
end
function M.clothing(char,id)
 local out={};if id and M.slot(id)~='dress' then return out end
 for _,o in ipairs(char:GetChildren())do
  if o:IsA('Shirt')then out[#out+1]={o,'ShirtTemplate'}elseif o:IsA('Pants')then out[#out+1]={o,'PantsTemplate'}elseif o:IsA('ShirtGraphic')then out[#out+1]={o,'Graphic'}end
 end
 return out
end
return M

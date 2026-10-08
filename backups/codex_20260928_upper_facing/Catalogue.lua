-- Mode et Style: six dresses, six trouser outfits, eyewear and pearl jewellery.
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
 {id='adventurer',name='Acorn adventurer',kind='outfit',slot='dress',price=65,detail='explorer',colours={
  colour('Pine',{38,94,66},{245,222,166},{115,70,39}),colour('Rust',{166,77,44},{250,222,164},{65,57,43}),colour('Honey',{208,155,53},{253,235,196},{87,65,37})}},
 {id='skycaptain',name='Sky captain',kind='outfit',slot='dress',price=95,detail='pilot',colours={
  colour('Cocoa',{98,60,43},{249,226,178},{46,56,69}),colour('Navy',{39,59,88},{238,204,135},{92,55,36}),colour('Burgundy',{121,45,58},{247,221,177},{55,43,54})}},
 {id='royalpage',name='Royal page',kind='outfit',slot='dress',price=140,detail='royal',colours={
  colour('Sapphire',{43,68,134},{237,194,86},{43,41,62}),colour('Emerald',{29,99,71},{237,194,86},{43,54,43}),colour('Crimson',{155,40,60},{249,217,139},{57,39,43})}},
 {id='woodlandbard',name='Woodland bard',kind='outfit',slot='dress',price=85,detail='bard',colours={
  colour('Moss',{76,113,63},{252,232,188},{109,66,41}),colour('Plum',{111,66,121},{255,230,181},{65,48,72}),colour('Ochre',{186,124,43},{251,230,184},{91,53,35})}},
 {id='moonmagician',name='Moonlit magician',kind='outfit',slot='dress',price=130,detail='magic',colours={
  colour('Midnight',{39,43,81},{235,196,92},{72,53,98}),colour('Violet',{96,65,145},{243,209,115},{48,38,71}),colour('Garnet',{125,40,72},{240,199,110},{61,36,52})}},
 {id='harborsailor',name='Harbor sailor',kind='outfit',slot='dress',price=75,detail='sailorboy',colours={
  colour('Cream',{248,231,190},{43,68,103},{165,52,48}),colour('Blue',{54,87,143},{253,235,198},{184,64,54}),colour('Cherry',{179,54,63},{252,234,199},{40,59,83})}},
 {id='round',name='Sunbeam rounds',slot='eyewear',price=35,detail='round',colours={
  colour('Gold',{197,148,59},{54,46,47}),colour('Tortoise',{111,62,36},{48,51,46}),colour('Rose',{195,100,112},{74,45,67})}},
 {id='cateye',name='Butterfly sunglasses',slot='eyewear',price=50,detail='cateye',colours={
  colour('Black',{38,34,39},{49,48,57}),colour('Cherry',{170,42,54},{63,33,49}),colour('Ivory',{246,226,188},{84,66,48})}},
 {id='aviator',name='Adventure aviators',slot='eyewear',price=60,detail='aviator',colours={
  colour('Brass',{196,152,66},{43,59,50}),colour('Silver',{180,187,192},{43,53,74}),colour('Copper',{184,110,76},{72,49,42})}},
 {id='pearls',name='Pearl pendants',slot='necklace',price=45,detail='pearls',colours={
  colour('Acorn',{252,230,189},{187,130,47},{223,172,71}),colour('Ruby',{255,235,210},{210,164,79},{167,43,68}),colour('Emerald',{251,235,212},{210,164,79},{30,112,76})}}
}
function M.category(style)return style.kind=='outfit' and 'outfit' or style.slot end
M.byId={};M.byStyle={};M.order={}
for _,s in ipairs(M.styles)do M.byStyle[s.id]=s;for k,c in ipairs(s.colours)do local id=s.id..'_'..k;M.byId[id]={id=id,style=s,colour=c};M.order[#M.order+1]=id end end
function M.title(id)local d=M.byId[id];return d and d.colour.name..' '..d.style.name or '' end
function M.slot(id)return M.byId[id] and M.byId[id].style.slot or 'dress' end
M.centres=__CENTRES__
M.sizes=__SIZES__

-- Canonical limb centres for the product picture; worn pieces use each animated joint.
M.limbs={
 leftArm={pos=V(-1.5,1.4,0),size=V(1,1.1,1),r15='LeftUpperArm',r6='Left Arm',offset=.5},
 rightArm={pos=V(1.5,1.4,0),size=V(1,1.1,1),r15='RightUpperArm',r6='Right Arm',offset=.5},
 leftForearm={pos=V(-1.5,.38,0),size=V(1,1,1),r15='LeftLowerArm',r6='Left Arm',offset=-.5},
 rightForearm={pos=V(1.5,.38,0),size=V(1,1,1),r15='RightLowerArm',r6='Right Arm',offset=-.5},
 hips={pos=V(0,-.26,0),size=V(2,.65,1),r15='LowerTorso',r6='Torso',offset=-.72},
 leftThigh={pos=V(-.5,-.95,0),size=V(1,1.1,1),r15='LeftUpperLeg',r6='Left Leg',offset=.5},
 rightThigh={pos=V(.5,-.95,0),size=V(1,1.1,1),r15='RightUpperLeg',r6='Right Leg',offset=.5},
 leftShin={pos=V(-.5,-1.97,0),size=V(1,1,1),r15='LeftLowerLeg',r6='Left Leg',offset=-.5},
 rightShin={pos=V(.5,-1.97,0),size=V(1,1,1),r15='RightLowerLeg',r6='Right Leg',offset=-.5},
}
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
 -- A continuous ribbon follows the front, crown and back of the shoulder.
 -- Short overlapping facets replace the upright + horizontal square corner.
 local function shoulderRibbon(side,width,color)
  local bottom=math.min(1.76,2*s.neck-.045)
  local function point(t)return V(side*.72,bottom+(2.055-bottom)*math.sin(t),-.565*math.cos(t))end
  for i=0,17 do
   local a,b=point(i*math.pi/18),point((i+1)*math.pi/18)
   local p=part('CurvedShoulderRibbon',(a+b)/2,V(width,.055,(b-a).Magnitude+.016),color,'upper',CFrame.lookAt(Vector3.zero,b-a))
   p:SetAttribute('RibbonStart',a);p:SetAttribute('RibbonEnd',b)
   p:SetAttribute('RibbonWidth',width)
  end
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
 elseif s.kind=='outfit' then
  local shirt=C(251,234,198)
  local pants=(s.detail=='sailorboy') and c.trim or c.accent
  mesh('Bodice','rue',V(1,.98,1.03),V(0,.98,0),c.fabric,'upper')
  -- Tailored trousers and sleeves follow the character's elbows and knees.
  for name,a in pairs(M.limbs)do
   local leg=name=='hips' or name:find('Thigh') or name:find('Shin')
   local fabric=leg and pants or (s.detail=='bard' or s.detail=='explorer') and shirt or c.fabric
   part(leg and 'Trousers' or 'Sleeve',a.pos,a.size+V(.065,.045,.065),fabric,name)
   if name:find('Forearm')then
    part('Cuff',a.pos+V(0,-.38,0),V(1.095,.16,1.095),c.trim,name)
   elseif name:find('Shin')then
    part('TrouserCuff',a.pos+V(0,-.40,0),V(1.09,.13,1.09),c.fabric,name)
   end
  end
  part('ShirtFront',V(0,1.25,-.642),V(.66,1.12,.055),shirt)
  for _,side in ipairs({-1,1})do
   part('TailoredLapel',V(side*.38,1.44,-.685),V(.22,.76,.07),c.trim,'upper',CFrame.Angles(0,0,side*-.30))
   part('WaistPocket',V(side*.63,.47,-.66),V(.43,.32,.075),c.fabric:Lerp(C(0,0,0),.13))
   part('PocketTrim',V(side*.63,.61,-.71),V(.43,.045,.025),c.trim)
  end
  part('Waistband',V(0,-.01,-.58),V(1.95,.17,.09),c.trim,'hips')
  ball('AcornBuckle',V(0,-.02,-.665),V(.20,.24,.10),c.trim,'hips')
  ball('AcornCap',V(0,.05,-.71),V(.24,.10,.075),c.accent,'hips')
  if s.detail=='explorer' then
   part('Neckerchief',V(0,1.72,-.73),V(.58,.21,.10),c.accent)
   for _,side in ipairs({-1,1})do part('ScarfTail',V(side*.10,1.41,-.73),V(.16,.5,.055),c.accent,'upper',CFrame.Angles(0,0,side*.23))end
   ball('LeafBadge',V(-.62,1.17,-.73),V(.15,.29,.05),c.trim,'upper',CFrame.Angles(0,0,-.4))
   for i=1,3 do ball('VestButton',V(0,.3+i*.26,-.72),V(.065,.065,.04),c.trim)end
  elseif s.detail=='pilot' then
   for _,side in ipairs({-1,1})do
    part('ShearlingCollar',V(side*.34,1.80,-.65),V(.59,.29,.15),shirt,'upper',CFrame.Angles(0,0,side*.29))
    part('FlightWing',V(side*.16,1.21,-.75),V(.25,.065,.055),c.trim,'upper',CFrame.Angles(0,0,-side*.25))
   end
   ball('FlightBadge',V(0,1.20,-.79),V(.12,.14,.07),c.trim)
   part('FlightScarf',V(.2,1.56,-.75),V(.25,.65,.06),c.trim,'upper',CFrame.Angles(0,0,.16))
  elseif s.detail=='royal' then
   for _,side in ipairs({-1,1})do
    part('Epaulette',V(side*.84,1.95,0),V(.40,.13,1.06),c.trim)
    for i=1,3 do ball('RoyalButton',V(side*.20,.53+i*.29,-.74),V(.10,.10,.055),c.trim)end
   end
   for i=1,3 do line('GoldBraid',V(-.2,.53+i*.29,-.72),V(.2,.53+i*.29,-.72),.027,c.trim)end
   ball('RoyalGem',V(0,1.78,-.71),V(.16,.20,.09),c.accent)
  elseif s.detail=='bard' then
   bow(V(0,1.75,-.71),c.accent,'upper',.65)
   for i=1,4 do ball('WaistcoatButton',V(0,.32+i*.24,-.72),V(.065,.065,.045),c.trim)end
   for i=0,7 do local t=i/7;ball('WatchChain',V(.17+t*.50,.69-math.sin(t*math.pi)*.16,-.735),V(.045,.045,.045),c.trim)end
   ball('PocketWatch',V(.64,.70,-.75),V(.15,.15,.06),c.trim)
  elseif s.detail=='magic' then
   bow(V(0,1.76,-.72),c.trim,'upper',.65)
   for _,pos in ipairs({V(-.66,1.17,-.73),V(.70,.90,-.73),V(-.58,.52,-.73)})do
    for k=0,3 do part('GoldStar',pos,V(.023,.23,.035),c.trim,'upper',CFrame.Angles(0,0,k*math.pi/4))end
   end
   part('SilkPocketSquare',V(.63,.71,-.72),V(.28,.18,.055),c.trim,'upper',CFrame.Angles(0,0,.24))
  elseif s.detail=='sailorboy' then
   for i=1,3 do part('SailorStripe',V(0,.55+i*.18,-.69),V(1.77,.065,.035),c.trim)end
   bow(V(0,1.54,-.75),c.accent,'upper',.75)
   part('SailorBackCollar',V(0,1.65,.66),V(1.30,.51,.08),c.trim)
  end
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
    shoulderRibbon(side,s.detail=='sailor' and .30 or .17,c.fabric)
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
   shoulderRibbon(-1,.25,c.trim)
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
 -- Fit each skirt's actual authored length to the avatar, not the longest gown.
 local skirtScale=V(scale.X*1.26,math.clamp(height/(d.style.length or 2.55),.25,4),scale.Z*1.42)
 local m=Instance.new('Model');m.Name=name or M.models[d.style.slot];m:SetAttribute('DressId',id);m:SetAttribute('BoutiqueSlot',d.style.slot)
 for _,p in ipairs(M.pieces(kit,id,CFrame.new(),1))do
  local section=p:GetAttribute('DressSection');local base,sc,joint=waist,scale,upper
  local limb=M.limbs[section]
  local localPos=p.Position
  if limb then
   joint=char:FindFirstChild(limb.r15) or char:FindFirstChild(limb.r6)
   if not joint then m:Destroy();return nil end
   localPos-=limb.pos
   if joint.Name==limb.r15 then
    sc=V(joint.Size.X/limb.size.X,joint.Size.Y/limb.size.Y,joint.Size.Z/limb.size.Z);base=joint.CFrame
   else
    sc=V(joint.Size.X/(section=='hips' and 2 or 1),joint.Size.Y/2,joint.Size.Z)
    base=joint.CFrame*CFrame.new(0,limb.offset*sc.Y,0)
   end
  elseif section=='lower' then sc=skirtScale;joint=lower
  elseif section=='head' then base=head.CFrame;sc=V(head.Size.X/1.2,head.Size.Y/1.2,head.Size.Z/1.2);joint=head end
  -- The dress shell needs ease around the torso; exact body dimensions let
  -- the avatar cut through the side seams. Keep its trim on the same surface.
  if section=='upper' and d.style.slot=='dress' and d.style.kind~='outfit' then
   sc=mult(sc,V(1.14,1,1.14))
  end
  local ribbonStart=p:GetAttribute('RibbonStart')
  if ribbonStart then
   -- Scale the curve's endpoints before orienting each facet, so the ribbon
   -- remains joined on avatars whose height and depth differ.
   local collar=upper:FindFirstChild(ribbonStart.X<0 and 'LeftCollarAttachment' or 'RightCollarAttachment')
   local function fittedEndpoint(v)
    local q=mult(v,sc)
    if collar then
     local bottom=math.min(1.76,2*d.style.neck-.045)
     local rise=math.clamp((v.Y-bottom)/(2.055-bottom),0,1)
     local shoulderTop=collar.Position.Y+upper.Size.Y/2+.045*sc.Y
     q=V(q.X,bottom*sc.Y+(math.max(bottom*sc.Y+.045*sc.Y,shoulderTop)-bottom*sc.Y)*rise,q.Z+collar.Position.Z*rise)
    end
    return q
   end
   local a,b=fittedEndpoint(ribbonStart),fittedEndpoint(p:GetAttribute('RibbonEnd'))
   p.Size=V(p:GetAttribute('RibbonWidth')*sc.X,.055*math.min(sc.Y,sc.Z),(b-a).Magnitude+.016*math.max(sc.Y,sc.Z))
   p.CFrame=base*CFrame.lookAt((a+b)/2,b)
  else
   local rotation=p.CFrame.Rotation;p.Size=mult(p.Size,sc);p.CFrame=base*CFrame.new(mult(localPos,sc))*rotation
  end
  p.Parent=m
  local weld=Instance.new('WeldConstraint');weld.Part0=joint;weld.Part1=p;weld.Parent=p
 end
 m.Parent=char;return m
end
function M.covered(char,id)
 local out={};local slot=M.slot(id);local outfit=M.byId[id] and M.byId[id].style.kind=='outfit'
 for _,o in ipairs(char:GetChildren())do
  if slot=='dress' and o:IsA('BasePart') and (o.Name=='LowerTorso' or o.Name=='LeftUpperLeg' or o.Name=='RightUpperLeg' or o.Name=='LeftLowerLeg' or o.Name=='RightLowerLeg' or o.Name=='Left Leg' or o.Name=='Right Leg' or (not outfit and (o.Name=='LeftFoot' or o.Name=='RightFoot'))) then out[#out+1]=o
  elseif outfit and o:IsA('BasePart') and (o.Name:find('Arm') or o.Name=='Left Leg' or o.Name=='Right Leg')then out[#out+1]=o
  elseif o:IsA('Accessory') then local t=o.AccessoryType.Name
   local hide=slot=='eyewear' and t=='Face' or slot=='necklace' and t=='Neck' or slot=='dress' and (t=='Jacket' or t=='Sweater' or t=='Shirt' or t=='TShirt' or t=='DressSkirt' or t=='Waist' or t=='Pants' or t=='Shorts' or (not outfit and (t=='LeftShoe' or t=='RightShoe')))
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

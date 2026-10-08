-- Mode et Style dress boutique, whimsical 48-piece collection. Draft; publish separately after review.
return function(opts)
 opts=opts or {};local RS=game:GetService("ReplicatedStorage");local CS=game:GetService("CollectionService");local C=Color3.fromRGB;local rng=Random.new(2710)
 local kit=assert(RS:FindFirstChild("DressKit"),"Import Dresses.obj and run kit installer first")
 local CAT=[====[
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
M.centres={["Bodice_rue"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_rue"]=Vector3.new(0.000000,-0.825000,0.000000),["Belt_rue"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_rue"]=Vector3.new(0.000000,-1.602500,0.000000),["Collar_rue"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_cafe"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_cafe"]=Vector3.new(0.000000,-0.975000,0.000000),["Belt_cafe"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_cafe"]=Vector3.new(0.000000,-1.902500,0.000000),["Collar_cafe"]=Vector3.new(0.000000,0.983500,0.000000),["Bodice_chateau"]=Vector3.new(0.000000,0.000000,0.000000),["Skirt_chateau"]=Vector3.new(0.000000,-1.250000,0.000000),["Belt_chateau"]=Vector3.new(0.000000,0.050000,0.000000),["Hem_chateau"]=Vector3.new(0.000000,-2.452500,0.000000),["Collar_chateau"]=Vector3.new(0.000000,0.983500,0.000000)}
M.sizes={["Bodice_rue"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_rue"]=Vector3.new(3.045000,1.650000,2.375100),["Belt_rue"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_rue"]=Vector3.new(3.061240,0.075000,2.391340),["Collar_rue"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_cafe"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_cafe"]=Vector3.new(3.536000,1.950000,2.758080),["Belt_cafe"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_cafe"]=Vector3.new(3.552640,0.075000,2.774720),["Collar_cafe"]=Vector3.new(0.960000,0.057000,0.794000),["Bodice_chateau"]=Vector3.new(2.040000,2.000000,1.220000),["Skirt_chateau"]=Vector3.new(3.845600,2.500000,2.999568),["Belt_chateau"]=Vector3.new(1.920000,0.160000,1.210000),["Hem_chateau"]=Vector3.new(3.861792,0.075000,3.015760),["Collar_chateau"]=Vector3.new(0.960000,0.057000,0.794000)}

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
  -- The original shell tapers toward a small neck opening. At a lowered
  -- dress neckline that taper cuts into the chest near both armholes.
  -- A continuous facing keeps the full bust width through the upper edge.
  local facingBottom=1.65*s.neck
  local facingHeight=2*s.neck+.04-facingBottom
  local facing=mesh('Belt',s.mesh,V(.99,facingHeight/.16,.98),V(0,facingBottom+.03*facingHeight/.16,0),c.fabric,'upper')
  facing.Name='BodiceFacing';facing.DoubleSided=true

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

]====]
 local SERVER=[====[
-- Boutique server: validated purchases and independent dress, eyewear and necklace slots.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local F = script.Parent
local action = RS:WaitForChild("DressShopAction")
local ev = RS:WaitForChild("DressShopEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local kit = RS:WaitForChild("DressKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end
local function owns(player, id) return (player:GetAttribute("Item_dress_" .. id) or 0) > 0 end
local function worn(player,slot)
 for _,id in ipairs(Cat.order)do if Cat.slot(id)==slot and (player:GetAttribute("Item_dresswear_"..id) or 0)>0 and owns(player,id)then return id end end
end
local function uncover(char,slot)
 if slot=="dress" then
  for _,entry in ipairs(Cat.clothing(char))do local o,key=entry[1],entry[2];local was=o:GetAttribute("DressClothingWas");if was~=nil then o[key]=was;o:SetAttribute("DressClothingWas",nil)end end
 end
 local key="BoutiqueWas_"..slot
 for _,p in ipairs(char:GetDescendants())do if p:IsA("BasePart")then
  local was=p:GetAttribute(key);if was~=nil then p.Transparency=was;p:SetAttribute(key,nil)end
  if slot=="dress" then local legacy=p:GetAttribute("DressWas");if legacy~=nil then p.Transparency=legacy;p:SetAttribute("DressWas",nil)end end
 end end
end
local function cover(char,id)
 for _,entry in ipairs(Cat.clothing(char,id))do local o,key=entry[1],entry[2];if o:GetAttribute("DressClothingWas")==nil then o:SetAttribute("DressClothingWas",o[key])end;o[key]="" end
 local key="BoutiqueWas_"..Cat.slot(id)
 for _,p in ipairs(Cat.covered(char,id))do if p:GetAttribute(key)==nil then p:SetAttribute(key,p.Transparency)end;p.Transparency=1 end
end
local function dress(player)
 local char=player.Character;if not char then return end
 for _,slot in ipairs(Cat.slots)do
  local id=worn(player,slot);local cur=char:FindFirstChild(Cat.models[slot])
  if cur and cur:GetAttribute("DressId")==id then cover(char,id)
  else
   if cur then cur:Destroy()end;uncover(char,slot)
   if id and Cat.attach(kit,id,char,Cat.models[slot])then cover(char,id)end
  end
 end
end
local pending = {}
local function redress(player)                             -- once, shortly: a swap changes two ledger lines
	if pending[player] then return end
	pending[player] = true
	task.delay(0.2, function() pending[player] = nil; dress(player) end)
end

-- ---- the doors: fade, move, unfade (the client draws the fade; the server moves you while it is dark); inside, the
-- camera is leashed so it cannot be scrolled out through the walls
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom, moving = {}, {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
 local target=toInside and F.DoorPad.Position or F.Room.Door.Position
 if (hrp.Position-target).Magnitude>12 then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			end
			char:SetAttribute("InDressShop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "MirrorPrompt" then
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if root and (root.Position-prompt.Parent.Position).Magnitude<=13 then ev:FireClient(player,"mirror") end end
end)

-- ---- buying and wearing, asked by the client; decided here
local busy, lastCall = {}, {}
local function wear(player,id,slot)
 slot=slot or (id and Cat.slot(id)) or "dress"
 for _,other in ipairs(Cat.order)do
  local n=tonumber(player:GetAttribute("Item_dresswear_"..other)) or 0
  if Cat.slot(other)==slot and other~=id and n>0 then awardItems:Fire(player,"dresswear_"..other,-n)end
 end
 if id and (player:GetAttribute("Item_dresswear_"..id) or 0)<=0 then awardItems:Fire(player,"dresswear_"..id,1)end
end
local function request(player, what, id)
 if type(what)~="string" or type(id)~="string" then return false,"Choose an item" end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or (root.Position-v3("Spot")).Magnitude>14 then return false,"Visit the boutique mirror" end
 if not player:GetAttribute("SaveLoaded") then return false,"Your wardrobe is still loading" end
 local now=os.clock();if busy[player] or now-(lastCall[player] or 0)<0.25 then return false,"One moment" end;lastCall[player]=now

 if what=="off" then
  if not Cat.models[id]then return false,"Choose a wardrobe category" end
  wear(player,nil,id);return true
 elseif what == "wear" then
		if id == "" or id == nil then wear(player, nil); return true end
		if type(id) ~= "string" or not Cat.byId[id] then return false, "Unknown item" end
		if not owns(player, id) then return false, "Buy this item first" end
		wear(player, id)
		return true
	elseif what == "buy" then
		if type(id) ~= "string" or not Cat.byId[id] then return false, "Unknown item" end
		if owns(player, id) then return false, "it's already yours" end
		if busy[player] then return false, "one at a time" end
		busy[player] = true
		local ok, res, why = pcall(function()
			local price = F:GetAttribute("Price_" .. Cat.byId[id].style.id)
			if type(price) ~= "number" or price~=price or price<0 or price%1~=0 then return false, "no price set" end
			local have = player:GetAttribute("Acorns") or 0     -- the purse as the SERVER sees it
			if have < price then return false, "not enough acorns" end
			awardAcorns:Fire(player, -price)                   -- spending is a negative award, same ledger, same merge
			player:SetAttribute("Acorns", have - price)
			awardItems:Fire(player, "dress_" .. id, 1)
			task.wait()
			wear(player, id)
			task.wait()
			return true, price
		end)
		busy[player] = nil
		if not ok then warn("DressServer: buying " .. tostring(id) .. " failed - " .. tostring(res)); return false, "something went wrong" end
		if res then print(string.format("DressShop: %s bought the %s for %d acorns", player.Name, Cat.title(id), why)) end
		return res, why
	end
	return false, "Unknown action"
end
action.OnServerInvoke=request

local function watch(player)
	player.CharacterAdded:Connect(function(char)
		leash(player, false)
		task.delay(1.2, function() if player.Character == char then dress(player) end end)
	end)
	player.CharacterAppearanceLoaded:Connect(function() redress(player) end)
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 15) == "Item_dresswear_" or name:sub(1, 11) == "Item_dress_" then redress(player) end
	end)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(function() redress(player) end)
	if player.Character then dress(player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil; busy[p] = nil; moving[p] = nil;lastCall[p]=nil;pending[p]=nil end)
-- Studio tests: give a hat and/or wear it without acorns (never in a live game)
local dbg = F:FindFirstChild("DressDebug")
if dbg and RunService:IsStudio() then
	dbg.OnInvoke = function(player, what, id)
		if what == "request" then return request(player,id[1],id[2])
        elseif what == "give" then awardItems:Fire(player, "dress_" .. id, 1)
			task.wait() return true
		elseif what == "wear" then wear(player, id) return true
		elseif what == "in" then through(player, true) return true
		elseif what == "out" then through(player, false) return true end
	end
end
print("DressServer: ready")

]====]
 local CLIENT=[====[

-- DressClient: the door fades, and the mirror - the camera turns round to be the mirror, the Chapelier's panel beside
-- you, every hat a little 3D picture; tap one to try it on (on your screen only), then buy it or wear it
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = RS:WaitForChild("DressShopEvent")
local action = RS:WaitForChild("DressShopAction")
local kit = RS:WaitForChild("DressKit")
local Cat = require(kit:WaitForChild("Catalogue"))
local RGB = Color3.fromRGB
-- the Acorn Store's own colours, so this reads as another page of the same book
local FACE, FACE_DEEP, RIM = RGB(255, 246, 220), RGB(250, 235, 201), RGB(226, 175, 68)
local SLOT, SLOT_EDGE = RGB(242, 229, 203), RGB(218, 174, 83)
local INK, INK_DIM, GOLD, BTN_INK = RGB(64, 42, 22), RGB(132, 108, 80), RGB(255, 202, 62), RGB(84, 48, 18)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o; return c end
local function stroke(o, col, th, tr) local s = Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color = col; s.Thickness = th; s.Transparency = tr or 0; s.Parent = o; return s end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- ---- the fade for the doors, and the door's sound
local fadeGui = Instance.new("ScreenGui"); fadeGui.Name = "DressShopFade"; fadeGui.ResetOnSpawn = false; fadeGui.IgnoreGuiInset = true; fadeGui.DisplayOrder = 20; fadeGui.Parent = pg
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.Visible=false; black.Parent = fadeGui
local fadeRevision=0
local doorSfx = Instance.new("Sound"); doorSfx.SoundId = F:GetAttribute("DoorSound") or ""; doorSfx.Volume = F:GetAttribute("DoorVolume") or 0.6; doorSfx.Parent = fadeGui

-- ---- the panel
local gui = Instance.new("ScreenGui"); gui.Name = "DressShopGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 18; gui.Enabled = false; gui.Parent = pg
local W, H = 320, 410
local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(1, 0.5); panel.Position = UDim2.new(1, -16, 0.5, 0)
panel.Size = UDim2.fromOffset(W, H); panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.Parent = gui
corner(panel, 22); stroke(panel, RIM, 4)
local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 W=math.min(350,math.floor(vp.X*.49)-12);H=math.min(480,math.floor(vp.Y)-40)
 panel.Size=UDim2.fromOffset(W,H);panel.Position=UDim2.new(1,-12,.5,8)
end
local title = Instance.new("TextLabel"); title.Position = UDim2.fromOffset(20, 14); title.Size = UDim2.fromOffset(100, 30); title.BackgroundTransparency = 1
title.Text = "Boutique"; title.TextXAlignment = Enum.TextXAlignment.Left; title.FontFace = FONT; title.TextSize = 22; title.TextColor3 = RGB(58, 36, 16); title.Parent = panel
local purse = Instance.new("TextLabel"); purse.AnchorPoint = Vector2.new(1, 0); purse.Position = UDim2.new(1, -56, 0, 16); purse.Size = UDim2.fromOffset(89, 28)
purse.BackgroundColor3 = SLOT; purse.BorderSizePixel = 0; purse.FontFace = FONT; purse.TextSize = 12; purse.TextColor3 = INK; purse.Text = ""; purse.Parent = panel
corner(purse, 10); stroke(purse, SLOT_EDGE, 2, 0.3)
local close = Instance.new("TextButton"); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -10, 0, 10); close.Size = UDim2.fromOffset(40, 40)
close.BackgroundColor3 = SLOT; close.BorderSizePixel = 0; close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = INK; close.Text = "X"; close.AutoButtonColor = false; close.Parent = panel
corner(close, 10); stroke(close, SLOT_EDGE, 2, 0.3)
local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(14, 98); list.Size = UDim2.new(1, -28, 1, -98 - 119)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Active=true; list.ScrollingDirection=Enum.ScrollingDirection.Y; list.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 8); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list
-- the foot of the panel: the hat you are trying, what it costs, and the buttons
local foot = Instance.new("Frame"); foot.AnchorPoint = Vector2.new(0, 1); foot.Position = UDim2.new(0, 14, 1, -12); foot.Size = UDim2.new(1, -28, 0, 106)
foot.BackgroundColor3 = FACE_DEEP; foot.BorderSizePixel = 0; foot.Parent = panel
corner(foot, 14); stroke(foot, SLOT_EDGE, 2, 0.45)
local picked = Instance.new("TextLabel"); picked.Position = UDim2.fromOffset(12, 6); picked.Size = UDim2.new(1, -24, 0, 22); picked.BackgroundTransparency = 1
picked.FontFace = FONT; picked.TextSize = 14; picked.TextColor3 = RGB(58, 36, 16); picked.TextXAlignment = Enum.TextXAlignment.Left; picked.TextTruncate = Enum.TextTruncate.AtEnd
picked.Text = "Choose a style to try on"; picked.Parent = foot
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0, 0); note.Position = UDim2.fromOffset(12, 28); note.Size = UDim2.new(1,-24,0,16); note.BackgroundTransparency = 1
note.Font = Enum.Font.BuilderSans; note.TextSize = 13; note.TextXAlignment = Enum.TextXAlignment.Left; note.TextTransparency = 1; note.Text = ""; note.Parent = foot
local function button(text, pos, size, colour)
	local b = Instance.new("TextButton"); b.Position = pos; b.Size = size; b.BackgroundColor3 = colour; b.BorderSizePixel = 0; b.AutoButtonColor = false
	b.FontFace = FONT; b.TextSize = 14; b.TextColor3 = BTN_INK; b.Text = text; b.Parent = foot
	corner(b, 10); stroke(b, RGB(150, 98, 36), 2, 0.2)
	return b
end
local main = button("", UDim2.fromOffset(12, 51), UDim2.new(1, -112, 0, 42), GOLD)
local bare = button("Original clothing", UDim2.new(1, -92, 0, 51), UDim2.fromOffset(80, 42), RGB(214, 202, 176))
bare.TextWrapped=true;bare.TextSize=13
local function say(text, good)
	note.Text = text; note.TextColor3 = good and RGB(64, 112, 48) or RGB(150, 52, 30); note.TextTransparency = 0
	TweenService:Create(note, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.4), {TextTransparency = 1}):Play()
end

-- a little 3D picture of a hat
local function picture(id, parent)
	local vf = Instance.new("ViewportFrame"); vf.Size = UDim2.fromScale(1, 1); vf.BackgroundTransparency = 1; vf.Ambient = RGB(200, 190, 180)
	vf.LightColor = RGB(255, 246, 230); vf.LightDirection = Vector3.new(-.6,-.5,-1); vf.Parent = parent
	local m = Instance.new("Model")
	for _, p in ipairs(Cat.pieces(kit, id, CFrame.new(), 1)) do p.Anchored = true; p.Parent = m end
	m.Parent = vf
	local cf, size = m:GetBoundingBox()
	local cam = Instance.new("Camera"); cam.FieldOfView = 30
	local dist = math.max(size.X, size.Y * 1.4) / (2 * math.tan(math.rad(15))) * 1.12
	local dir = Vector3.new(0.22,0.1,-1).Unit
	cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
	cam.Parent = vf; vf.CurrentCamera = cam
	return vf
end

local tiles, sections = {}, {}
local selected
local activeSlot="dress"
local activeCategory="dress"
local busy=false
local categoryButtons={}
local function owned(id) return (player:GetAttribute("Item_dress_" .. id) or 0) > 0 end
local function wornId(slot)
 slot=slot or activeSlot
 for _,id in ipairs(Cat.order)do if Cat.slot(id)==slot and (player:GetAttribute("Item_dresswear_"..id) or 0)>0 then return id end end
end
local function priceOf(styleId) return F:GetAttribute("Price_" .. styleId) end
for i,choice in ipairs({{"dress","Dresses"},{"outfit","Outfits"},{"eyewear","Shades"},{"necklace","Jewels"}})do
 local b=Instance.new("TextButton");b.Name="Category_"..choice[1];b.Position=UDim2.new((i-1)/4,14-(i-1)*6,0,53);b.Size=UDim2.new(1/4,-13,0,38);b.BackgroundColor3=SLOT;b.BorderSizePixel=0;b.FontFace=FONT;b.TextSize=13;b.TextColor3=INK;b.Text=choice[2];b.Parent=panel;corner(b,11)
 categoryButtons[choice[1]]=b
end
for i, s in ipairs(Cat.styles) do
	local sec = Instance.new("Frame"); sec.Name = s.id; sec.Size = UDim2.new(1, -6, 0, 140); sec.BackgroundColor3 = FACE_DEEP; sec.BorderSizePixel = 0
	sec.LayoutOrder = i; sec.Visible=Cat.category(s)==activeCategory;sec.Parent = list
	corner(sec, 14); stroke(sec, SLOT_EDGE, 2, 0.45)
	local nm = Instance.new("TextLabel"); nm.Position = UDim2.fromOffset(12, 6); nm.Size = UDim2.new(1,-86,0,20); nm.BackgroundTransparency = 1
	nm.FontFace = FONT; nm.TextSize = 13; nm.TextColor3 = RGB(58, 36, 16); nm.TextXAlignment = Enum.TextXAlignment.Left; nm.Text = s.name; nm.Parent = sec
	local pr = Instance.new("TextLabel"); pr.AnchorPoint = Vector2.new(1, 0); pr.Position = UDim2.new(1, -12, 0, 8); pr.Size = UDim2.fromOffset(76, 18)
	pr.BackgroundTransparency = 1; pr.FontFace = FONT; pr.TextSize = 11; pr.TextColor3 = INK_DIM; pr.TextXAlignment = Enum.TextXAlignment.Right; pr.Parent = sec
	sections[s.id] = {frame = sec, price = pr}
	for k = 1, #s.colours do
		local id = s.id .. "_" .. k
		local t = Instance.new("TextButton"); t.Name = id; t.Text = ""; t.AutoButtonColor = false; t.BackgroundColor3 = FACE; t.BorderSizePixel = 0
		t.Size = UDim2.new(1/3,-12,0,98); t.Position = UDim2.new((k-1)/3,7,0,32); t.Parent = sec
		corner(t, 12)
		local st = stroke(t, SLOT_EDGE, 2, 0.35)
		local pic = picture(id, t); pic.Name="ProductPreview";pic.Size = UDim2.new(1, -8, 1, -33); pic.Position = UDim2.fromOffset(4, 2)
		local tag = Instance.new("TextLabel"); tag.AnchorPoint = Vector2.new(0.5, 1); tag.Position = UDim2.new(0.5, 0, 1, -3); tag.Size = UDim2.fromOffset(70, 14)
		tag.BackgroundTransparency = 1; tag.FontFace = FONT; tag.TextSize = 11; tag.TextColor3 = RGB(64, 112, 48); tag.Text = ""; tag.Parent = t
		local color=Instance.new("TextLabel");color.Name="Colour";color.BackgroundTransparency=1;color.Position=UDim2.new(0,2,1,-31);color.Size=UDim2.new(1,-4,0,14);color.Font=Enum.Font.BuilderSans;color.TextSize=11;color.TextColor3=INK;color.Text=s.colours[k].name;color.Parent=t
        tiles[id] = {button = t, stroke = st, tag = tag}
	end
end

-- Trying on is local. Keep covered body parts hidden after the camera's
-- transparency update, which can reset LocalTransparencyModifier on camera changes.
local preview
local hiddenParts = {}
local hiddenClothing={}
local PREVIEW_COVERAGE="BoutiquePreviewCoverage"
local function maintainPreviewCoverage()
 for p in pairs(hiddenParts)do
  if p.Parent and p.LocalTransparencyModifier~=1 then p.LocalTransparencyModifier=1 end
 end
end
local function hideWorn(hide)
 local char=player.Character
 if hide and char then
  for _,entry in ipairs(Cat.clothing(char,selected)) do local o,key=entry[1],entry[2];if hiddenClothing[o]==nil then hiddenClothing[o]={key,o[key]} end;o[key]="" end
  local all=Cat.covered(char,selected);local w=char:FindFirstChild(Cat.models[Cat.slot(selected)])
  if w then for _,p in ipairs(w:GetDescendants()) do if p:IsA("BasePart") then table.insert(all,p) end end end
  for _,p in ipairs(all) do if hiddenParts[p]==nil then hiddenParts[p]=p.LocalTransparencyModifier end;p.LocalTransparencyModifier=1 end
  RunService:BindToRenderStep(PREVIEW_COVERAGE,Enum.RenderPriority.Last.Value,maintainPreviewCoverage)
 else
  RunService:UnbindFromRenderStep(PREVIEW_COVERAGE)
  for o,v in pairs(hiddenClothing) do if o.Parent then o[v[1]]=o:GetAttribute("DressClothingWas")~=nil and "" or v[2] end end;hiddenClothing={}
  for p,was in pairs(hiddenParts) do if p.Parent then p.LocalTransparencyModifier=was end end;hiddenParts={}
 end
end
local function clearPreview() if preview then preview:Destroy();preview=nil end end
script.Destroying:Connect(function() clearPreview();hideWorn(false) end)
local function tryOn(id)
 clearPreview();hideWorn(false)
 local char=player.Character;if not char then return end
 preview=Cat.attach(kit,id,char,"DressPreview");hideWorn(true)
end

local function refresh()
 for slot,b in pairs(categoryButtons)do b.BackgroundColor3=slot==activeCategory and GOLD or SLOT end
	purse.Text = tostring(player:GetAttribute("Acorns") or 0) .. "  acorns"
	local have = player:GetAttribute("Acorns") or 0
	local on = wornId()
	for _, s in ipairs(Cat.styles) do
		local p = priceOf(s.id)
		sections[s.id].price.Text = p and (tostring(p) .. " acorns") or ""
	end
	for id, t in pairs(tiles) do
		local mine, wearing = owned(id), (id == wornId(Cat.slot(id)))
		t.tag.Text = wearing and "wearing" or (mine and "yours" or "")
		t.tag.TextColor3 = wearing and RGB(170, 110, 20) or RGB(64, 112, 48)
		local sel = (id == selected)
		t.stroke.Color = sel and GOLD or (wearing and RGB(200, 150, 48) or SLOT_EDGE)
		t.stroke.Thickness = sel and 3 or 2; t.stroke.Transparency = sel and 0 or 0.35
		t.button.BackgroundColor3 = sel and RGB(255, 248, 228) or FACE
	end
	if not selected then
		picked.Text = on and ("You're wearing the " .. Cat.title(on):lower()) or "Choose a style to try on"
		main.Text = "Choose a style"; main.BackgroundColor3 = RGB(214, 202, 176); main.TextColor3 = INK_DIM
	else
		local h = Cat.byId[selected]
		picked.Text = Cat.title(selected)
		if selected == on then
			main.Text = "Wearing"; main.BackgroundColor3 = RGB(214, 202, 176); main.TextColor3 = INK_DIM
		elseif owned(selected) then
			main.Text = "Wear it"; main.BackgroundColor3 = GOLD; main.TextColor3 = BTN_INK
		else
			local p = priceOf(h.style.id) or 0
			main.Text = "Buy - " .. tostring(p) .. " acorns"
			local can = have >= p
			main.BackgroundColor3 = can and GOLD or RGB(214, 202, 176); main.TextColor3 = can and BTN_INK or INK_DIM
		end
	end
	bare.BackgroundColor3 = on and RGB(214, 202, 176) or RGB(228, 218, 196)
end
for slot,b in pairs(categoryButtons)do
 b.Activated:Connect(function()
  if busy then return end
  clearPreview();hideWorn(false);selected=nil;activeCategory=slot;activeSlot=slot=="outfit" and "dress" or slot
  for _,style in ipairs(Cat.styles)do sections[style.id].frame.Visible=Cat.category(style)==slot end
  list.CanvasPosition=Vector2.zero;refresh()
 end)
end
for id, t in pairs(tiles) do
 t.button.Activated:Connect(function()
		if busy then return end
		selected = id
		tryOn(id)
		refresh()
	end)
end

main.Activated:Connect(function()
	if busy or not selected then return end
	local on = wornId()
	if selected == on then return end
	busy = true
	local what = owned(selected) and "wear" or "buy"
	if what == "buy" then
		local p = priceOf(Cat.byId[selected].style.id) or 0
		if (player:GetAttribute("Acorns") or 0) < p then busy = false; say("not enough acorns", false) return end
	end
	main.Text = "..."
	local want = selected
	local ok, res, why = pcall(function() return action:InvokeServer(what, want) end)
	busy = false
	if not ok then say("the shop did not answer", false)
	elseif res then
		say(what == "buy" and "it's yours!" or "on it goes", true)
		-- the real one arrives from the server in a moment: then the try-on steps down, so there are never two
		task.spawn(function()
			local char = player.Character
			for _ = 1, 40 do
				local w = char and char:FindFirstChild(Cat.models[Cat.slot(want)])
				if w and w:GetAttribute("DressId") == want then break end
				task.wait(0.05)
			end
			if selected == want and preview then clearPreview(); hideWorn(false) end
		end)
	else say(tostring(why or "no"), false) end
	refresh()
end)
bare.Activated:Connect(function()
	if busy then return end
	selected = nil
	clearPreview(); hideWorn(false)
	busy = true
	local ok,res,why=pcall(function() return action:InvokeServer("off", activeSlot) end)
	busy = false
	say(ok and res and "Original clothing" or tostring(why or "Try again"),ok and res)
	refresh()
end)

-- ---- at the mirror: stand on the rug facing it, the camera becomes the mirror, the rest of the screen steps aside
local open = false
local savedGuis, backpackWas, camWas = {}, nil, nil
-- you stay on the rug while the panel is open: the walking keys (and a pad's stick and jump) are swallowed here, at a
-- higher priority than the controls; on a phone the joystick is hidden with the rest of the screen. (This game's
-- PlayerScripts has no PlayerModule to switch the controls off with - waiting for one stalled this script.)
local CAS = game:GetService("ContextActionService")
local FREEZE = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left,
	Enum.KeyCode.Right, Enum.KeyCode.Space, Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA}
local function stepAside(on)
	if on then
		savedGuis = {}
		for _, g in ipairs(pg:GetChildren()) do
			if (g:IsA("ScreenGui") or g:IsA("BillboardGui")) and g ~= gui and g ~= fadeGui and g.Enabled then savedGuis[g] = true; g.Enabled = false end
		end
		-- and your own name tag over your head (on a phone the mirror's framing put it beside Roblox's buttons)
		local char = player.Character
		for _, g in ipairs(char and char:GetDescendants() or {}) do
			if g:IsA("BillboardGui") and g.Enabled then savedGuis[g] = true; g.Enabled = false end
		end
		pcall(function() backpackWas = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
		CAS:BindActionAtPriority("DressMirrorStay", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value + 100, table.unpack(FREEZE))
	else
		for g in pairs(savedGuis) do if g.Parent then g.Enabled = true end end
		savedGuis = {}
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, backpackWas ~= false) end)
		CAS:UnbindAction("DressMirrorStay")
	end
end
local function mirrorPrompt() return F:FindFirstChild("MirrorPrompt", true) end
local function setOpen(on)
	if on == open then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	local cam = workspace.CurrentCamera
	if on and not (hrp and hum and head and cam) then return end
	open = on
	local mp = mirrorPrompt()
	if on then
		if mp then mp.Enabled = false end
		-- on the rug, facing the glass
		local spot = v3("Spot")
		local toMirror = (Vector3.new(F:GetAttribute("MirrorX"), 0, F:GetAttribute("MirrorZ")) - Vector3.new(spot.X, 0, spot.Z)).Unit
		local legs = hum.HipHeight + hrp.Size.Y / 2
		local at = spot + Vector3.new(0, legs + 0.05, 0)
		hrp.CFrame = CFrame.lookAt(at, at + toMirror)
		hrp.AssemblyLinearVelocity = Vector3.zero
		stepAside(true)
		gui.Enabled = true
		fit()
		-- the camera stands where the glass is, looking back at your face; you on the left, the panel on the right
		task.defer(function()
            if not open or player.Character~=char then return end
			local hp = hrp.Position - Vector3.new(0,.2,0)
			local camRight = (-toMirror):Cross(Vector3.new(0, 1, 0))
			camWas = cam.CameraType
			cam.CameraType = Enum.CameraType.Scriptable
			local eye = hp + toMirror * 7.3 + camRight * 0.4 + Vector3.new(0, 0.2, 0)      -- (nearly level: from above, a brim hid the eyes)
			cam.CFrame = CFrame.lookAt(eye, hp + camRight * 2.7)
		end)
		selected = nil
		refresh()
	else
		gui.Enabled = false
		clearPreview(); hideWorn(false)
		selected = nil
		stepAside(false)
		cam.CameraType = (camWas and camWas ~= Enum.CameraType.Scriptable) and camWas or Enum.CameraType.Custom
		if mp then mp.Enabled = true end
	end
end
close.Activated:Connect(function() setOpen(false) end)
game:GetService("UserInputService").InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.Escape and open then setOpen(false) end end)
player.CharacterAdded:Connect(function() if open then open = true; setOpen(false) end end)
player:GetAttributeChangedSignal("Acorns"):Connect(function() if open then refresh() end end)
player.AttributeChanged:Connect(function(name) if open and (name:sub(1, 11) == "Item_dress_" or name:sub(1, 15) == "Item_dresswear_") then refresh() end end)
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end)

ev.OnClientEvent:Connect(function(what, a)
	if what == "fade" then
        fadeRevision+=1;black.Visible=true
        if open then setOpen(false) end
		doorSfx.TimePosition = 0; doorSfx:Play()
		TweenService:Create(black, TweenInfo.new(a or 0.45), {BackgroundTransparency = 0}):Play()
	elseif what == "unfade" then
		-- A transparent fullscreen frame still intercepts scroll input; remove it after the transition.
        fadeRevision+=1;local revision=fadeRevision
        local fade=TweenService:Create(black, TweenInfo.new((a or 0.45) * 1.4), {BackgroundTransparency = 1})
        fade.Completed:Once(function(state)if revision==fadeRevision and state==Enum.PlaybackState.Completed then black.Visible=false end end)
        fade:Play()
	elseif what == "mirror" then
		setOpen(true)
	end
end)

]====]
 local Cat=assert(loadstring(CAT))();assert(loadstring(SERVER));assert(loadstring(CLIENT))
 for name in pairs(Cat.sizes) do assert(kit:FindFirstChild(name),"Missing dress mesh "..name) end
 local F=Instance.new("Folder");F.Name="DressShop"
 for _,s in ipairs(Cat.styles) do F:SetAttribute("Price_"..s.id,(opts.prices and opts.prices[s.id]) or s.price) end
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent or F
		return p
	end
	local function soft(p) p.CanCollide = false; return p end

	-- ---------------------------------------------------------------- the street door ----
	-- the MODE ET STYLE sign is on the townhouse_e at x 312 looking +z; its door (DoorShop) is at x 303, the window x 305..323
	local SX, DX, DZ=304,295,-100.6
 local shop
 for _,m in ipairs(workspace.Village.Props:GetChildren()) do
  local t=m:FindFirstChild("SignText",true)
  if t then for _,l in ipairs(t:GetDescendants()) do if l:IsA("TextLabel") and l.Text=="MODE ET STYLE" then shop=m end end end
 end
 assert(shop,"MODE ET STYLE storefront missing")
	local function shopColour(name, fallback)
		local p = shop and shop:FindFirstChild(name, true)
		return (p and p:IsA("BasePart")) and p.Color or fallback
	end
	local FACADE = shopColour("Shopfront", C(38, 94, 65))
	local AWNING, STRIPE = shopColour("Awning", C(226, 176, 80)), shopColour("AwningStripe", C(250, 247, 240))
	local DOORC, GLASSC = shopColour("DoorShop", C(112, 74, 46)), shopColour("GlassDoor", C(232, 240, 244))
	local groundY = 0.65
	do
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
		local ground = workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Ground")
		if ground then rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {ground, workspace.Terrain} end
		local hit = workspace:Raycast(Vector3.new(DX, 20, DZ + 2), Vector3.new(0, -40, 0), rp)
		if hit then groundY = hit.Position.Y end
	end
	local doorPad = part("DoorPad", Vector3.new(4, 5.5, 0.6), CFrame.new(DX, groundY + 2.9, DZ), C(255, 246, 220), nil, F)
	doorPad.Transparency = 1; doorPad.CanCollide = false; doorPad.CanQuery = false
	local mat = part("Doormat", Vector3.new(3.0, 0.12, 1.6), CFrame.new(DX, groundY + 0.06, DZ - 1.2), C(46, 70, 52), Enum.Material.Fabric)
	mat.CanCollide = false
	local enter = Instance.new("ProximityPrompt"); enter.Name = "EnterPrompt"; enter.ActionText = "Go inside"; enter.ObjectText = "Mode et Style"
	enter.KeyboardKeyCode = Enum.KeyCode.E; enter.HoldDuration = 0; enter.MaxActivationDistance = 8; enter.RequiresLineOfSight = false; enter.Parent = doorPad

	-- ---------------------------------------------------------------- the room ----
	local W, D, H = opts.width or 24, opts.depth or 22, 11
	local O = Vector3.new(SX, opts.roomY or 390, DZ - 0.45 - D / 2)         -- floor centre; the street wall's inner face at the facade
	local room = Instance.new("Model"); room.Name = "Room"; room.Parent = F
	local function at(x, y, z) return CFrame.new(O.X + x, O.Y + y, O.Z + z) end
	local dxr = DX - SX                                                       -- the door's x in room terms (-9)
	local PLASTER, WOOD, DARK, PARQUET = C(238, 227, 204), C(122, 86, 54), C(70, 48, 32), C(156, 112, 72)
	local BRASS, IRON, CREAM, VELVET = C(218, 178, 88), C(46, 46, 51), C(255, 246, 220), C(155, 72, 48)
	part("Floor", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, -0.3, 0), PARQUET, Enum.Material.WoodPlanks, room)
	part("Ceiling", Vector3.new(W + 1.2, 0.6, D + 1.2), at(0, H + 0.3, 0), C(232, 222, 202), Enum.Material.SmoothPlastic, room)
	part("WallN", Vector3.new(W, H, 0.6), at(0, H / 2, -D / 2 - 0.3), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallE", Vector3.new(0.6, H, D + 1.2), at(W / 2 + 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	part("WallW", Vector3.new(0.6, H, D + 1.2), at(-W / 2 - 0.3, H / 2, 0), PLASTER, Enum.Material.SmoothPlastic, room)
	-- a sage wainscot to the height of a chair back, capped with a dark rail, round the three plaster walls
	local WAIN = 3.1
	for _, w in ipairs({{0, -D / 2 + 0.08, W, 0.16}, {W / 2 - 0.08, 0, 0.16, D}, {-W / 2 + 0.08, 0, 0.16, D}}) do
		soft(part("Wainscot", Vector3.new(w[3], WAIN, w[4]), at(w[1], WAIN / 2, w[2]), FACADE, Enum.Material.Wood, room))
		soft(part("Rail", Vector3.new(math.max(w[3], 0.3), 0.22, math.max(w[4], 0.3)), at(w[1], WAIN + 0.1, w[2]), DARK, Enum.Material.Wood, room))
		soft(part("Skirting", Vector3.new(math.max(w[3], 0.26), 0.36, math.max(w[4], 0.26)), at(w[1], 0.18, w[2]), DARK, Enum.Material.Wood, room))
	end

	-- the street wall, in the shopfront's green: the display window (16 wide, y 1.4..8.4), wall, then the door at x -9
	local zS = D / 2 + 0.3
	local wx0, wx1, wy0, wy1 = -4.6, 11.4, 1.4, 8.4
	local ddx0, ddx1 = dxr - 1.7, dxr + 1.7
	local function wall(x0, x1, y0, y1) part("WallS", Vector3.new(x1 - x0, y1 - y0, 0.6), at((x0 + x1) / 2, (y0 + y1) / 2, zS), FACADE, Enum.Material.SmoothPlastic, room) end
	wall(-W / 2, W / 2, wy1, H)                              -- the band over the window and the door
	wall(-W / 2, ddx0, 0, wy1)                               -- west pier
	wall(ddx0, ddx1, 0, wy1)                                 -- behind the door (it is mounted on the wall)
	wall(ddx1, wx0, 0, wy1)                                  -- between the door and the window
	wall(wx0, wx1, 0, wy0)                                   -- under the window
	wall(wx1, W / 2, 0, wy1)                                 -- east pier
	local pane = part("Window", Vector3.new(wx1 - wx0, wy1 - wy0, 0.25), at((wx0 + wx1) / 2, (wy0 + wy1) / 2, zS), GLASSC, Enum.Material.Glass, room)
	pane.Transparency = 0.2; pane.CastShadow = false          -- under 0.25, so the camera treats the glass as solid
	for _, fx in ipairs({wx0 - 0.1, wx1 + 0.1}) do part("Frame", Vector3.new(0.4, wy1 - wy0 + 0.4, 0.8), at(fx, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	part("Frame", Vector3.new(wx1 - wx0 + 0.8, 0.4, 0.8), at((wx0 + wx1) / 2, wy1 + 0.1, zS), CREAM, Enum.Material.SmoothPlastic, room)
	part("Sill", Vector3.new(wx1 - wx0 + 0.8, 0.4, 1.0), at((wx0 + wx1) / 2, wy0 - 0.1, zS - 0.1), CREAM, Enum.Material.SmoothPlastic, room)
	for k = 1, 3 do part("Mullion", Vector3.new(0.25, wy1 - wy0, 0.5), at(wx0 + (wx1 - wx0) * k / 4, (wy0 + wy1) / 2, zS), CREAM, Enum.Material.SmoothPlastic, room) end
	-- the mustard awning outside the window, seen through the glass
	do
		local tilt = math.rad(37)
		local n, wA, cx = 12, 18, (wx0 + wx1) / 2
		for i = 0, n - 1 do
			local sx = cx - wA / 2 + wA / n * (i + 0.5)
			soft(part("Awning", Vector3.new(wA / n + 0.02, 0.12, 4.0), at(sx, 7.85, zS + 2.05) * CFrame.Angles(tilt, 0, 0), (i % 2 == 0) and AWNING or STRIPE, Enum.Material.Fabric, room))
		end
		soft(part("AwningRod", Vector3.new(wA, 0.15, 0.15), at(cx, 6.55, zS + 3.8), IRON, Enum.Material.Metal, room))
	end
	-- the door, the Mode et Style's own brown with its glass, on the wall
	local doorZ = zS - 0.3
	part("DoorFrame", Vector3.new(3.8, 7.1, 0.2), at(dxr, 3.55, doorZ - 0.1), DARK, Enum.Material.Wood, room)
	local door = part("Door", Vector3.new(3.4, 6.8, 0.2), at(dxr, 3.4, doorZ - 0.2), DOORC, Enum.Material.Wood, room)
	local dglass = part("DoorGlass", Vector3.new(2.4, 3.6, 0.1), at(dxr, 4.4, doorZ - 0.32), GLASSC, Enum.Material.Glass, room); dglass.Transparency = 0.2
	for _, px in ipairs({-0.72, 0.72}) do soft(part("Panel", Vector3.new(1.2, 1.6, 0.06), at(dxr + px, 1.3, doorZ - 0.32), C(92, 62, 46), Enum.Material.Wood, room)) end
	soft(part("Knob", Vector3.new(0.3, 0.3, 0.3), at(dxr + 1.2, 3.4, doorZ - 0.42), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))
	local exit = Instance.new("ProximityPrompt"); exit.Name = "ExitPrompt"; exit.ActionText = "Go outside"; exit.ObjectText = "Rue de Noisette"
	exit.KeyboardKeyCode = Enum.KeyCode.E; exit.HoldDuration = 0; exit.MaxActivationDistance = 7; exit.RequiresLineOfSight = false; exit.Parent = door
	-- a bell over the door on a curled bracket (shops like this have one)
	soft(part("BellBracket", Vector3.new(0.12, 0.12, 1.0), at(dxr + 1.3, 7.5, doorZ - 0.8), IRON, Enum.Material.Metal, room))
	soft(part("ShopBell", Vector3.new(0.45, 0.45, 0.45), at(dxr + 1.3, 7.25, doorZ - 1.25), BRASS, Enum.Material.Metal, room, Enum.PartType.Ball))

 -- Three full-size dress forms; their actual wearable meshes double as the display art.
 local function mannequin(id,x,y,z,s,yaw,parent)
  local d=Cat.byId[id];local waist=y+(d.style.length or 2.55)*s+.32
  local cf=at(x,waist,z)*CFrame.Angles(0,math.rad(yaw or 0),0)
  local model=Instance.new('Model');model.Name='Display_'..id;model.Parent=parent or room
  for _,p in ipairs(Cat.pieces(kit,id,cf,s)) do p.Anchored=true;p.Parent=model end
  soft(part('DressStand',Vector3.new(.16,1.5,1.5),at(x,y+.08,z)*CFrame.Angles(0,0,math.pi/2),BRASS,Enum.Material.Metal,model,Enum.PartType.Cylinder))
  soft(part('DressPole',Vector3.new(.12,waist-y,.12),at(x,(waist+y)/2,z),BRASS,Enum.Material.Metal,model))
  soft(part('MannequinNeck',Vector3.new(.36,.36,.36),at(x,waist+2.05*s,z),CREAM,Enum.Material.SmoothPlastic,model,Enum.PartType.Ball))
  return model
 end
 local function words(p,text,size)
  p.CFrame*=CFrame.Angles(0,math.pi,0)
  local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=70;g.LightInfluence=.2;g.Parent=p
  local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(6,4);l.Size=UDim2.new(1,-12,1,-8);l.Font=Enum.Font.FredokaOne;l.TextScaled=true;l.TextColor3=DARK;l.Text=text;l.Parent=g
 end
 for i,id in ipairs({'rue','adventurer','jardin','skycaptain','chateau','royalpage'})do local s=Cat.byStyle[id]
  local x=(i-3.5)*3.65;local z=-D/2+2.2
  part('DisplayPlinth',Vector3.new(3.35,.32,3.4),at(x,.16,z),WOOD,Enum.Material.Wood,room)
  mannequin(s.id..'_1',x,.33,z,.72,180)
  soft(part('DisplayBack',Vector3.new(3.4,7.6,.1),at(x,4.3,-D/2+.2),C(244,232,207),Enum.Material.SmoothPlastic,room))
  for _,side in ipairs({-1,1}) do soft(part('DisplayTrim',Vector3.new(.065,7.6,.16),at(x+side*1.65,4.3,-D/2+.28),BRASS,Enum.Material.Metal,room)) end
  local plaque=soft(part('StylePlaque',Vector3.new(3.2,.75,.12),at(x,7.65,-D/2+.32),BRASS,Enum.Material.Metal,room))
  words(plaque,s.name..'\n'..tostring(F:GetAttribute('Price_'..s.id))..' acorns')
  for k,c in ipairs(s.colours) do
   soft(part('FabricSwatch',Vector3.new(.55,.55,.07),at(x+(k-2)*.8,6.55,-D/2+.37),c.fabric,Enum.Material.Fabric,room))
  end
 end
 local sign=soft(part('BoutiqueSign',Vector3.new(13,1.1,.12),at(0,9.6,-D/2+.18),CREAM,Enum.Material.SmoothPlastic,room))
 words(sign,'MODE ET STYLE')
 -- Two colourways in the shop window, with plenty of daylight between them.
 mannequin('jardin_2',-.8,1.55,D/2-1.45,.8,0)
 mannequin('royalpage_1',6.7,1.55,D/2-1.45,.8,-12)

 -- Sunglasses and pendants on small velvet stands along the counter.
 for i,id in ipairs({'round_1','cateye_2','aviator_3','pearls_1'})do
  local x,z=9.5,1.1+(i-1)*1.05
  local m=Instance.new('Model');m.Name='AccessoryDisplay_'..id;m.Parent=room
  local atItem=at(x,4.20,z)*CFrame.Angles(0,math.pi/2,0)
  if Cat.slot(id)=='necklace' then atItem=atItem*CFrame.new(0,-1.48,0)end
  for _,p in ipairs(Cat.pieces(kit,id,atItem,.8))do p.Anchored=true;p.Parent=m end
  soft(part('VelvetTray',Vector3.new(.8,.10,.8),at(x,3.91,z),C(40,79,54),Enum.Material.SmoothPlastic,m))
 end
	-- THE MIRROR on the west wall: an arched glass in a gilded frame, a little rug where you stand, a sign over it
	local MZ = opts.mirrorZ or -2.6
	local mx = -W / 2 + 0.2
	local MIR = Instance.new("Model"); MIR.Name = "Mirror"; MIR.Parent = room
	part("FrameSlab", Vector3.new(0.3, 5.8, 4.5), at(mx + 0.05, 1.0 + 2.9, MZ), BRASS, Enum.Material.Metal, MIR)
	part("FrameTop", Vector3.new(0.3, 4.5, 4.5), at(mx + 0.05, 6.8, MZ) * CFrame.Angles(0, 0, 0), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Cylinder)
	local glass = part("Glass", Vector3.new(0.12, 5.4, 3.8), at(mx + 0.22, 1.2 + 2.7, MZ), C(206, 220, 230), Enum.Material.Glass, MIR)
	glass.Reflectance = 0.35
	local gtop = part("GlassTop", Vector3.new(0.12, 3.8, 3.8), at(mx + 0.22, 6.6, MZ), C(206, 220, 230), Enum.Material.Glass, MIR, Enum.PartType.Cylinder)
	gtop.Reflectance = 0.35
	soft(part("Crest", Vector3.new(0.3, 0.9, 0.9), at(mx + 0.1, 9.05, MZ), BRASS, Enum.Material.Metal, MIR, Enum.PartType.Ball))
	local spot = Vector3.new(O.X - 3.2, O.Y, O.Z + MZ)                      -- where you stand to look in it
	soft(part("MirrorRug", Vector3.new(0.1, 4.2, 4.2), CFrame.new(spot.X, O.Y + 0.08, spot.Z) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, MIR, Enum.PartType.Cylinder))
	local ask = Instance.new("ProximityPrompt"); ask.Name = "MirrorPrompt"; ask.ActionText = "Try on outfits & accessories"; ask.ObjectText = "Mirror"
	ask.KeyboardKeyCode = Enum.KeyCode.E; ask.HoldDuration = 0; ask.MaxActivationDistance = 10; ask.RequiresLineOfSight = false; ask.Parent = glass
	do
		local card = soft(part("MirrorSign", Vector3.new(0.08, 0.8, 3.0), at(mx + 0.3, 10.1, MZ), CREAM, Enum.Material.SmoothPlastic, MIR))
		local g = Instance.new("SurfaceGui"); g.Face = Enum.NormalId.Right; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 80; g.LightInfluence = 0.3; g.Parent = card
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -10, 1, -6); l.Position = UDim2.fromOffset(5, 3)
		l.Font = Enum.Font.Antique; l.TextScaled = true; l.TextColor3 = C(70, 46, 22); l.Text = "Essayez !"; l.Parent = g
	end
	-- Fabric rolls in a brass basket beside the mirror.
 for i,col in ipairs({C(230,185,81),C(169,78,50),C(44,91,63)}) do
  local x,z=-10.4+(i-2)*.45,3.3
  soft(part("FabricRoll",Vector3.new(3.1,.44,.44),at(x,1.7,z)*CFrame.Angles(0,0,math.rad(86+i*2)),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end
 part("FabricBasket",Vector3.new(1.8,.8,1.1),at(-10.4,.4,3.3),WOOD,Enum.Material.Wood,room)
	-- the counter on the east side: a till, striped hat boxes, a little lamp
	do
		local cx, cz = W / 2 - 2.4, 2.6
		part("Counter", Vector3.new(1.6, 3.4, 7.0), at(cx, 1.7, cz), WOOD, Enum.Material.Wood, room)
		part("CounterTop", Vector3.new(1.9, 0.2, 7.3), at(cx, 3.5, cz), DARK, Enum.Material.Wood, room)
		soft(part("Front", Vector3.new(0.1, 2.6, 6.4), at(cx - 0.85, 1.6, cz), FACADE, Enum.Material.Wood, room))
		part("Till", Vector3.new(1.0, 0.8, 1.3), at(cx, 4.0, cz - 1.8), BRASS, Enum.Material.Metal, room)
		soft(part("TillTop", Vector3.new(0.7, 0.35, 1.1), at(cx + 0.15, 4.55, cz - 1.8) * CFrame.Angles(0, 0, math.rad(-20)), BRASS, Enum.Material.Metal, room))
		soft(part("LampPole", Vector3.new(0.1, 1.2, 0.1), at(cx, 4.2, cz + 2.4), BRASS, Enum.Material.Metal, room))
		local shade = soft(part("LampShade", Vector3.new(0.6, 0.8, 0.8), at(cx, 4.9, cz + 2.4) * CFrame.Angles(0, 0, math.rad(90)), C(240, 214, 160), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.5; pl.Range = 8; pl.Color = C(255, 214, 160); pl.Parent = shade
		-- hat boxes: striped rounds stacked on the counter's end and on the floor behind it
		local function hatBox(x, y, z, r, h, c1, c2)
			part("HatBox", Vector3.new(h, r * 2, r * 2), at(x, y + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), c1, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder)
			soft(part("BoxLid", Vector3.new(0.22, r * 2 + 0.1, r * 2 + 0.1), at(x, y + h - 0.08, z) * CFrame.Angles(0, 0, math.rad(90)), c2, Enum.Material.SmoothPlastic, room, Enum.PartType.Cylinder))
		end
		hatBox(cx, 3.6, cz + 0.6, 0.62, 0.7, C(240, 226, 196), C(172, 42, 50))
		hatBox(cx, 4.3, cz + 0.6, 0.5, 0.55, C(128, 158, 118), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0, cz - 2.4, 0.7, 0.8, C(206, 122, 132), C(250, 240, 226))
		hatBox(W / 2 - 0.9, 0.8, cz - 2.4, 0.6, 0.7, C(240, 226, 196), C(42, 50, 94))
		hatBox(W / 2 - 0.9, 0, cz + 4.8, 0.65, 0.75, C(42, 50, 94), C(224, 180, 82))
	end

	-- a round rug in the middle, a velvet pouf to sit on, and three low pendant lamps (dim - the Librairie's were
	-- "way way way too bright" before they were cut to a third)
	-- (east of the mirror's own rug, and a little lower, so the two never overlap or flicker)
	soft(part("Rug", Vector3.new(0.1, 9, 9), at(3.9, 0.05, -1) * CFrame.Angles(0, 0, math.rad(90)), C(160, 60, 64), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	soft(part("RugBorder", Vector3.new(0.08, 9.6, 9.6), at(3.9, 0.03, -1) * CFrame.Angles(0, 0, math.rad(90)), C(218, 178, 88), Enum.Material.Fabric, room, Enum.PartType.Cylinder))
	local pouf = part("Pouf", Vector3.new(1.5, 2.4, 2.4), at(4.6, 0.75, -0.5) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, room, Enum.PartType.Cylinder)
	local seat = Instance.new("Seat"); seat.Name = "PoufSeat"; seat.Size = Vector3.new(2.0, 0.2, 2.0); seat.CFrame = at(4.6, 1.55, -0.5); seat.Transparency = 1; seat.Anchored = true; seat.Parent = room
	for i, lx in ipairs({-5, 1.5, 8}) do
		local ly = H - 2.3
		soft(part("Cord", Vector3.new(0.06, 2.0, 0.06), at(lx, H - 1.0, -2), IRON, Enum.Material.Metal, room))
		local sh = soft(part("Shade", Vector3.new(0.7, 1.4, 1.4), at(lx, ly, -2) * CFrame.Angles(0, 0, math.rad(90)), (i == 2) and C(224, 180, 82) or C(38, 94, 65), Enum.Material.Metal, room, Enum.PartType.Cylinder))
		local bulb = soft(part("Bulb", Vector3.new(0.4, 0.4, 0.4), at(lx, ly - 0.4, -2), C(255, 240, 200), Enum.Material.Neon, room, Enum.PartType.Ball))
		local pl = Instance.new("PointLight"); pl.Brightness = 0.55; pl.Range = 16; pl.Color = C(255, 222, 176); pl.Shadows = false; pl.Parent = bulb
	end

	-- ---------------------------------------------------------------- plumbing ----
	local action = RS:FindFirstChild("DressShopAction")
	if not action then action = Instance.new("RemoteFunction"); action.Name = "DressShopAction"; action.Parent = RS end
	local ev = RS:FindFirstChild("DressShopEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "DressShopEvent"; ev.Parent = RS end
	F:SetAttribute("RoomX", O.X); F:SetAttribute("RoomY", O.Y); F:SetAttribute("RoomZ", O.Z)
	F:SetAttribute("FadeSeconds", opts.fade or 0.45)
	F:SetAttribute("DoorSound", opts.doorSound or "rbxassetid://131845870598154"); F:SetAttribute("DoorVolume", opts.doorVolume or 0.6)   -- the Librairie's door (Shannon's pick)
	F:SetAttribute("InsideZoom", 16)
	F:SetAttribute("InX", O.X + dxr); F:SetAttribute("InY", O.Y + 3.4); F:SetAttribute("InZ", O.Z + D / 2 - 5.5)
	F:SetAttribute("OutX", DX); F:SetAttribute("OutY", groundY + 3.4); F:SetAttribute("OutZ", DZ - 2.6)
	F:SetAttribute("SpotX", spot.X); F:SetAttribute("SpotY", spot.Y); F:SetAttribute("SpotZ", spot.Z)
	F:SetAttribute("MirrorX", O.X + mx); F:SetAttribute("MirrorZ", O.Z + MZ)
	if not F:FindFirstChild("DressDebug") then local d = Instance.new("BindableFunction"); d.Name = "DressDebug"; d.Parent = F end   -- Studio tests


 for i,col in ipairs({C(230,187,86),C(245,230,197),C(153,58,64)}) do
  soft(part("RibbonSpool",Vector3.new(.3,.5,.5),at(9.6,3.85,1+i*.5)*CFrame.Angles(0,0,math.pi/2),col,Enum.Material.Fabric,room,Enum.PartType.Cylinder))
 end

 local old=workspace:FindFirstChild("DressShop");if old then old:Destroy() end
 local oldCat=kit:FindFirstChild("Catalogue");if oldCat then oldCat:Destroy() end
 local cm=Instance.new("ModuleScript");cm.Name="Catalogue";cm.Source=CAT;cm.Parent=kit
 local s=Instance.new("Script");s.Name="DressServer";s.RunContext=Enum.RunContext.Server;s.Source=SERVER;s.Parent=F
 local c=Instance.new("Script");c.Name="DressClient";c.RunContext=Enum.RunContext.Client;c.Source=CLIENT;c.Parent=F
 local cf,sz=room:GetBoundingBox();room:SetAttribute("BoxCF",cf);room:SetAttribute("BoxSize",sz);CS:AddTag(room,"SkyRoom")
 F.Parent=workspace
 return F
end

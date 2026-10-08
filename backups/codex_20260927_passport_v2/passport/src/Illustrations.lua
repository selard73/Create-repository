-- Small, still, code-drawn illustrations. No external assets or per-frame animation.
local Art={}
local C=Color3.fromRGB
local colours={brown=C(112,72,42),gold=C(219,165,58),cream=C(255,246,220),green=C(76,119,92),blue=C(93,148,163)}
function Art.draw(parent,id,size)
 local canvas=Instance.new("Frame");canvas.Name="Illustration_"..id;canvas.Size=UDim2.fromOffset(size,size);canvas.BackgroundTransparency=1;canvas.ZIndex=parent.ZIndex+1;canvas.Parent=parent
 local function shape(x,y,w,h,col,r,rot)
  local f=Instance.new("Frame");f.Position=UDim2.fromScale(x,y);f.Size=UDim2.fromScale(w,h);f.BackgroundColor3=col;f.BorderSizePixel=0;f.Rotation=rot or 0;f.ZIndex=canvas.ZIndex;f.Parent=canvas
  if r then local c=Instance.new("UICorner");c.CornerRadius=UDim.new(r,0);c.Parent=f end
  return f
 end
 local function line(x,y,w,h,col,rot) return shape(x,y,w,h,col,0.5,rot) end
 local function circle(x,y,d,col) return shape(x,y,d,d,col,1) end
 local brown,gold,cream,green,blue=colours.brown,colours.gold,colours.cream,colours.green,colours.blue
 circle(.08,.08,.84,C(236,224,195))
 if id=="acorn" then
  shape(.31,.37,.43,.45,gold,.46,-12);shape(.25,.29,.51,.19,brown,.4,-12);line(.47,.17,.075,.17,brown,12)
  line(.40,.53,.025,.15,cream,-12)
 elseif id=="book" or id=="passport" or id=="goldpassport" then
  local cover=id=="goldpassport" and gold or green
  local foil=id=="goldpassport" and brown or gold
  shape(.24,.16,.55,.70,cover,.10,-6);shape(.22,.18,.05,.65,brown,.4,-6)
  shape(.32,.25,.34,.03,foil,.3,-6);shape(.34,.70,.31,.03,foil,.3,-6)
  circle(.40,.39,.21,foil);line(.48,.33,.04,.09,foil,-12)
 elseif id=="coffee" or id=="zoomies" then
  circle(.59,.43,.24,brown);circle(.64,.48,.13,cream)
  shape(.22,.35,.44,.40,cream,.18);shape(.25,.36,.38,.08,brown,1);line(.18,.76,.56,.04,brown)
  line(.31,.13,.04,.16,gold,-14);line(.47,.10,.04,.17,gold,14)
 elseif id=="glace" then
  shape(.40,.50,.20,.35,gold,.1,10);circle(.28,.27,.32,C(227,158,164));circle(.45,.29,.30,cream);circle(.39,.15,.29,C(122,76,50))
 elseif id=="cheese" then
  shape(.20,.38,.59,.36,gold,.10,-12);shape(.25,.31,.46,.12,C(252,208,95),.25,-12)
  for _,p in ipairs({{.30,.51,.10},{.57,.44,.12},{.57,.63,.06}}) do circle(p[1],p[2],p[3],C(166,114,37)) end
 elseif id=="bubbles" then
  shape(.27,.43,.25,.37,blue,.18);shape(.31,.34,.17,.10,gold,.12)
  for _,p in ipairs({{.52,.17,.22,C(205,144,170)},{.66,.42,.16,C(129,172,148)},{.33,.15,.13,C(160,146,197)}}) do circle(p[1],p[2],p[3],p[4]);circle(p[1]+.035,p[2]+.025,p[3]*.25,cream) end
 elseif id=="hat" then
  shape(.28,.24,.44,.44,green,.2);shape(.27,.57,.47,.10,gold,.1);shape(.14,.65,.72,.12,green,1)
 elseif id=="baguette" then
  shape(.34,.14,.31,.74,gold,.5,35)
  for i=1,3 do line(.32+i*.08,.29+i*.14,.18,.04,cream,-18) end
 elseif id=="bell" then
  circle(.31,.25,.39,gold);shape(.30,.43,.41,.29,gold,.10);shape(.21,.69,.60,.08,brown,.5);circle(.45,.74,.12,gold);line(.46,.16,.06,.12,brown)
 elseif id=="glider" then
  for i=0,4 do shape(.14+i*.145,.25+math.abs(i-2)*.075,.155,.26,({C(189,87,64),gold,cream,green,blue})[i+1],.05,(i-2)*13) end
  line(.48,.40,.04,.38,brown);line(.29,.57,.44,.04,brown);line(.31,.39,.035,.20,brown,-34);line(.65,.39,.035,.20,brown,34)
 elseif id=="ziphandle" then
  line(.12,.21,.76,.04,brown,-16);circle(.40,.19,.18,gold);circle(.44,.23,.10,brown);line(.48,.36,.05,.30,brown);line(.26,.65,.49,.09,brown);shape(.20,.62,.12,.16,gold,.3);shape(.68,.62,.12,.16,gold,.3)
 elseif id=="hoop" then
  shape(.48,.15,.34,.29,cream,.08);shape(.51,.19,.27,.21,blue,.08);line(.38,.43,.40,.06,brown)
  for i=0,3 do line(.39+i*.11,.49,.025,.21,cream,(i-1.5)*-15) end
  circle(.18,.58,.26,gold);line(.20,.70,.22,.025,brown,-14)
 elseif id=="flag" then
  line(.29,.19,.05,.63,brown);shape(.35,.21,.41,.28,green,.05);shape(.39,.25,.10,.10,cream);shape(.58,.37,.10,.09,cream)
 elseif id=="seed" then
  shape(.25,.22,.51,.59,cream,.10,-6);line(.48,.41,.03,.26,green);shape(.32,.38,.19,.10,green,.5,32);shape(.49,.33,.19,.10,green,.5,-32);line(.34,.71,.28,.025,brown)
 elseif id=="binoculars" then
  shape(.20,.28,.23,.39,green,.15,10);shape(.57,.28,.23,.39,green,.15,-10);line(.40,.39,.20,.10,brown);circle(.16,.56,.30,brown);circle(.54,.56,.30,brown);circle(.21,.61,.20,blue);circle(.59,.61,.20,blue)
 elseif id=="slingshot" then
  line(.48,.47,.10,.37,brown);line(.31,.22,.09,.36,brown,-35);line(.60,.22,.09,.36,brown,35);line(.23,.22,.51,.04,gold);circle(.42,.18,.16,brown)
 elseif id=="backpack" then
  shape(.29,.18,.42,.64,brown,.28);shape(.24,.31,.52,.51,green,.22);shape(.34,.53,.32,.22,gold,.14);line(.29,.40,.42,.04,cream)
 elseif id=="portrait" then
  shape(.24,.15,.52,.64,brown,.03);shape(.29,.20,.42,.53,cream,.01);circle(.39,.28,.23,gold);shape(.36,.52,.28,.16,green,.4);line(.31,.77,.04,.12,brown,-12);line(.67,.77,.04,.12,brown,12)
 else -- A friendly squirrel profile, including a large curled tail.
  circle(.14,.25,.40,brown);circle(.23,.32,.23,gold);shape(.38,.46,.30,.32,brown,.5,-15);circle(.53,.27,.26,brown);shape(.57,.19,.10,.19,brown,.4,-14);circle(.71,.37,.035,cream);line(.40,.79,.32,.05,brown)
 end
 return canvas
end
return Art

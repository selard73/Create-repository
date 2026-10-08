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
 for i,id in ipairs({'jardin','adventurer','soiree','moonmagician'})do local s=Cat.byStyle[id]
  local x=(i-2.5)*5.4;local z=-D/2+2.2
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
 mannequin('moonmagician_1',6.7,1.55,D/2-1.45,.8,-12)

 -- Sunglasses and pendants on small velvet stands along the counter.
 for i,id in ipairs({'round_1','cateye_2','aviator_3','pearls_1'})do
  local x,z=9.5,1.1+(i-1)*1.05
  local m=Instance.new('Model');m.Name='AccessoryDisplay_'..id;m.Parent=room
  local atItem=at(x,4.20,z)*CFrame.Angles(0,math.pi/2,0)
  if Cat.slot(id)=='necklace' then atItem=atItem*CFrame.new(0,-1.48,0)end
  for _,p in ipairs(Cat.pieces(kit,id,atItem,.8))do p.Anchored=true;p.Parent=m end
  soft(part('VelvetTray',Vector3.new(.8,.10,.8),at(x,3.91,z),C(40,79,54),Enum.Material.SmoothPlastic,m))
 end

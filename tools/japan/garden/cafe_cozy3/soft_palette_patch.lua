-- Soften the large wall and rug surfaces without changing timber, cats or lighting.
do
 local wallCount=0
 for _,p in ipairs(room.Architecture:GetChildren())do
  if p:IsA("MeshPart")and p.Name:match("_Wall$")then
   p.Color=Color3.fromRGB(171,155,132);wallCount+=1
  end
 end
 assert(wallCount==9,"Unexpected interior wall mesh count")
 local rugCount=0
 local function rugPalette(root,prefix,border)
  for _,p in ipairs(root:GetChildren())do
   if p:IsA("MeshPart")and p.Name:find(prefix,1,true)==1 then
    local key=p.Name:match("_([^_]+)$")
    if key=="Rug"then p.Color=Color3.fromRGB(141,124,96)
    elseif key=="Cream"then p.Color=Color3.fromRGB(151,133,105)
    elseif key=="SageSoft"then p.Color=border
    else error("Unexpected rug mesh "..p.Name)end
    rugCount+=1
   end
  end
 end
 rugPalette(room.Architecture,"CI2_Rug_",Color3.fromRGB(117,130,100))
 rugPalette(room.CozyNooks,"ReadingRug_",Color3.fromRGB(145,117,108))
 assert(rugCount==6,"Expected three meshes in each of two rugs")
 room:SetAttribute("CafeSoftPaletteVersion","putty_flax1")
 print("QQ CAFECOZY3 SOFT PALETTE: nine warm putty wall meshes; six muted flax rug meshes with quiet sage/rose borders; dark timber and rustic floor retained")
end

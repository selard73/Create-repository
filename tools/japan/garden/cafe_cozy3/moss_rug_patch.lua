-- Rug color refinement only; preserve the approved putty walls and all other surfaces.
do
 local count=0
 local palette={Rug={91,105,65},Cream={104,116,77},SageSoft={72,86,52}}
 for _,root in ipairs({room.Architecture,room.CozyNooks})do
  for _,p in ipairs(root:GetChildren())do
   if p:IsA("MeshPart")and(p.Name:find("CI2_Rug_",1,true)==1 or p.Name:find("ReadingRug_",1,true)==1)then
    local rgb=assert(palette[p.Name:match("_([^_]+)$")],"Unexpected rug mesh "..p.Name)
    p.Color=Color3.fromRGB(table.unpack(rgb));count+=1
   end
  end
 end
 assert(count==6,"Expected six meshes across two cafe rugs")
 room:SetAttribute("CafeRugPalette","moss1")
 print("QQ CAFE RUG MOSS: six rug meshes recolored; muted moss body, soft green weave and darker moss borders")
end

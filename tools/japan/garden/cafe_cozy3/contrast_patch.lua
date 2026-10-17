-- Interior-only wood contrast, shared by the staged installer and narrow Play refresh.
-- Keep the matte floor, upholstery, ceramics, cat textures and all geometry as previewed.
do
 local espresso=Color3.fromRGB(66,43,31)
 local walnut=Color3.fromRGB(91,60,41)
 local warmTop=Color3.fromRGB(133,93,61)
 local mediumWood=Color3.fromRGB(112,77,51)
 local targets={}
 local function add(p,color)
  assert(p and p:IsA("MeshPart"),"Missing cafe wood mesh")
  targets[p]=color
 end
 for _,p in ipairs(room.Architecture:GetChildren())do
  local n=p.Name
  if n:match("_TimberEdge$")or n:match("_Timber$")then add(p,espresso)
  elseif n:find("Wainscot_",1,true)then add(p,walnut)
  elseif n=="CI2_Lattice_Oak"then add(p,walnut)
  elseif n=="CI2_Ceiling_OakLight"then add(p,Color3.fromRGB(150,116,82))
  elseif n=="CI2_CeilingBase_OakDark"then add(p,espresso)end
 end
 local function furnitureWood(root)
  for _,p in ipairs(root:GetChildren())do if p:IsA("MeshPart")then
   local group,key=p.Name:match("^(C1_.+)_([^_]+)$")
   if group=="C1_Bench"then
    if key=="Oak"then add(p,walnut)elseif key=="OakDark"then add(p,espresso)end
   elseif group and group:match("^C1_Chair%d$")then
    if key=="Oak"then add(p,walnut)elseif key=="OakLight"then add(p,mediumWood)end
   elseif group and group:match("^C1_Table%d$")then
    if key=="Oak"or key=="OakDark"then add(p,espresso)elseif key=="OakLight"then add(p,warmTop)end
   elseif group=="C1_Counter"or group=="C1_WindowBench"then
    if key=="Oak"then add(p,walnut)elseif key=="OakDark"or key=="TimberEdge"then add(p,espresso)elseif key=="OakLight"then add(p,warmTop)end
   elseif group=="C1_Shelves"then
    if key=="TimberEdge"then add(p,espresso)elseif key=="OakLight"then add(p,mediumWood)end
   elseif group and group:match("^C1_Climb%d$")then
    if key=="OakDark"then add(p,espresso)elseif key=="OakLight"then add(p,mediumWood)end
   elseif group=="C1_Cubby"then
    if key=="OakDark"then add(p,espresso)elseif key=="OakLight"then add(p,warmTop)end
   elseif group=="C1_Art"and key=="TimberEdge"then add(p,espresso)end
  end end
 end
 furnitureWood(room.Furniture)
 furnitureWood(room.CozyNooks.ReadingSofa)
 furnitureWood(room.CozyNooks.ReadingTeaTable)
 for _,root in ipairs({room.LeftWallDecor,room.CozyNooks,room.ExitDoor})do
  for _,p in ipairs(root:GetDescendants())do if p:IsA("MeshPart")then
   local group,key=p.Name:match("^(CW1_.+)_([^_]+)$")
   if group=="CW1_FrontShelf"or group=="CW1_BackShelf"then
    if key=="OakDark"then add(p,espresso)elseif key=="Oak"or key=="OakLight"then add(p,mediumWood)end
   elseif group=="CW1_CatPortrait"and key=="OakDark"then add(p,espresso)end
  end end
 end
 for _,n in ipairs({"Door_Frame","Door_Wood","Door_Reveal"})do add(room.ExitDoor:FindFirstChild(n),espresso)end
 local count=0
 for p,color in pairs(targets)do p.Color=color;count+=1 end
 room:SetAttribute("CafeWoodContrastVersion","walnut1")
 print("QQ CAFECOZY3 WOOD: "..count.." interior meshes recolored; espresso beams/trim; walnut furniture/counter; warm brown tops; quiet floor and soft cushions retained")
end

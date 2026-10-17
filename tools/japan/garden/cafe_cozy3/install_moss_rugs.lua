-- Narrow rug-only installer. Preview in Play; install in Edit only on Shannon's yes.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and CAFERUGMOSS_ALLOW_EDIT==true),"Rug preview first; Edit needs approval")
local room=assert(workspace.JapanMap.ShopFronts:FindFirstChild("CatCafeInterior"))
assert(room:GetAttribute("CafeSoftPaletteVersion")=="putty_flax1","Expected installed cafe palette")
local saved={}
for _,root in ipairs({room,workspace.JapanMap.ShopFronts.CatCafe})do for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")then
 saved[p]={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,collide=p.CanCollide,anchored=p.Anchored}
end end end
if not Run:IsRunning()then game:GetService("ChangeHistoryService"):SetWaypoint("Before moss cafe rugs")end
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

local total=0;local changed=0
for p,b in pairs(saved)do
 assert(p.Parent and p.CFrame==b.cf and p.Size==b.size and p.Material==b.material and p.CanCollide==b.collide and p.Anchored==b.anchored,"Unexpected geometry/material change: "..p.Name)
 if p.Color~=b.color then
  assert(p:IsDescendantOf(room)and(p.Name:find("CI2_Rug_",1,true)==1 or p.Name:find("ReadingRug_",1,true)==1),"Unexpected non-rug change")
  changed+=1
 end
 total+=1
end
assert(total==371 and(changed==0 or changed==6),"Unexpected installed cafe inventory or partial color change")
if not Run:IsRunning()then game:GetService("ChangeHistoryService"):SetWaypoint("After moss cafe rugs")end
print("QQ CAFE RUG MOSS CHECK: "..changed.." rug color changes; all371 part transforms/materials/collisions/anchoring and all non-rug colors unchanged")
print("QQ CAFE RUG MOSS STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")

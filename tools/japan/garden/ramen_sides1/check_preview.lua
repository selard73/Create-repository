
local s=workspace.JapanMap["Outdoor market revision"]["Ramen kitchen"]
local r=s.RamenSideDetails1
local function v(a)return{a.X,a.Y,a.Z}end
local rows={};local colliders=0
for _,p in r:GetDescendants() do
 assert(not p:IsA("ProximityPrompt") and not p:IsA("BaseScript"),"Unexpected interaction")
 if p:IsA("BasePart") then assert(p:IsA("MeshPart") and p.Anchored and not p.CanTouch)
  if p.CanCollide then colliders+=1;assert(p.Name=="UpperStep" or p.Name=="LowerStep")end
  table.insert(rows,{path=p:GetFullName(),name=p.Name,cf={p.CFrame:GetComponents()},size=v(p.Size),color=v(Vector3.new(p.Color.R,p.Color.G,p.Color.B)),material=p.Material.Name,variant=p.MaterialVariant,mesh=p.MeshId,texture=p.TextureID,anchored=p.Anchored,collide=p.CanCollide,touch=p.CanTouch,query=p.CanQuery,shadow=p.CastShadow,transparency=p.Transparency,render=p.RenderFidelity.Name,collision=p.CollisionFidelity.Name})
 end
end
assert(#rows==16 and colliders==2)
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={r};rp.RespectCanCollide=true
local lower=workspace:Raycast(Vector3.new(5972,3,32.5),Vector3.new(0,-5,0),rp)
local upper=workspace:Raycast(Vector3.new(5972,3,31),Vector3.new(0,-5,0),rp)
local top=s["Shop floor"].Position.Y+s["Shop floor"].Size.Y/2
assert(lower and upper and math.abs(lower.Position.Y-top/2)<.001 and math.abs(upper.Position.Y-top)<.001,"Step heights")
rp.FilterDescendantsInstances={s}
local hit=workspace:Raycast(Vector3.new(5972,4,35),Vector3.new(0,0,-7),rp)
assert(hit and hit.Instance.Name=="Side wall" and math.abs(hit.Position.Z-30.2)<.001,"Closed wall collision changed")
assert(workspace.JapanMap.ShopFronts.Mikan:GetAttribute("BarrelSignFacingVersion")=="side1")
local result={manifest=rows,checks={message="QQ RAMEN SIDES CHECK:16 anchored real meshes; two exact-height collidable steps; original wall blocks passage; no prompts/scripts; accepted barrel signs preserved",parts=#rows,colliders=colliders,lowerStep=lower.Position.Y,upperStep=upper.Position.Y,wallHit=hit.Instance:GetFullName(),wallPosition=v(hit.Position),sideVersion=s:GetAttribute("SideDetailsVersion"),lanternVersion=s:GetAttribute("LanternClearanceVersion"),grocerStockVersion=workspace.JapanMap.ShopFronts.Mikan:GetAttribute("GrocerStockVersion")}}
return game.HttpService:JSONEncode(result)

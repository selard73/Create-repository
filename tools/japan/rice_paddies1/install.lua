local RS=game:GetService("RunService")
assert(RS:IsRunning() or _G.RICE_PADDIES1_ALLOW_EDIT==true,"Edit requires explicit rice-paddy authorization")
local root=workspace.JapanMap
local terrain=workspace.Terrain
local folder=root.BlenderScenery["Sculpted terrain"]
local imported=game.ServerStorage.JapanGardenKit.rice_bank_grounded1:FindFirstChildWhichIsA("MeshPart",true)
assert(imported and imported.MeshId=="rbxassetid://125379819144461","Expected validated import")
local source=imported
assert(source and source.MeshId=="rbxassetid://125379819144461","Expected validated bank asset")
assert(not folder:GetAttribute("RicePaddiesRepairVersion"),"Already installed; do not rerun")
local sectionData=game:GetService("HttpService"):JSONDecode([==[[{"name":"JP_RiceCollision_01","center":[-26.181503295898438,0,-16.38005828857422],"size":[6.084991455078125,3.049999952316284,11.201263427734375],"vertices":77,"triangles":150,"volume":92.35774549880195,"mesh":"rbxassetid://130689734902277"},{"name":"JP_RiceCollision_02","center":[-24.00421142578125,0,-21.407588958740234],"size":[7.6890869140625,3.049999952316284,6.288444519042969],"vertices":77,"triangles":150,"volume":48.0854504312115,"mesh":"rbxassetid://120001500402311"},{"name":"JP_RiceCollision_03","center":[-4.4962615966796875,0,-23],"size":[39.783660888671875,3.049999952316284,6],"vertices":77,"triangles":150,"volume":403.89663748094495,"mesh":"rbxassetid://135286715030858"},{"name":"JP_RiceCollision_04","center":[18.827178955078125,0,-22.809242248535156],"size":[13.05426025390625,3.049999952316284,5.5074615478515625],"vertices":77,"triangles":150,"volume":96.81604653124307,"mesh":"rbxassetid://120799136882203"},{"name":"JP_RiceCollision_05","center":[24.625762939453125,0,-20.866371154785156],"size":[7.22381591796875,3.049999952316284,6.663299560546875],"vertices":77,"triangles":150,"volume":47.90824632922615,"mesh":"rbxassetid://92924437627485"},{"name":"JP_RiceCollision_06","center":[26.466827392578125,0,-3.9355392456054688],"size":[6.06634521484375,3.049999952316284,34.387725830078125],"vertices":77,"triangles":150,"volume":365.6951048132381,"mesh":"rbxassetid://129217885766813"},{"name":"JP_RiceCollision_07","center":[26.1815185546875,0,16.38005828857422],"size":[6.0849609375,3.049999952316284,11.201263427734375],"vertices":77,"triangles":150,"volume":92.3577850297118,"mesh":"rbxassetid://110696389342893"},{"name":"JP_RiceCollision_08","center":[24.00421142578125,0,21.407588958740234],"size":[7.6890869140625,3.049999952316284,6.288444519042969],"vertices":77,"triangles":150,"volume":48.085410924224746,"mesh":"rbxassetid://99437238812875"},{"name":"JP_RiceCollision_09","center":[4.4962615966796875,0,23],"size":[39.783721923828125,3.049999952316284,6],"vertices":77,"triangles":150,"volume":403.8965946623192,"mesh":"rbxassetid://95951362492085"},{"name":"JP_RiceCollision_10","center":[-18.827194213867188,0,22.809242248535156],"size":[13.054229736328125,3.049999952316284,5.5074615478515625],"vertices":77,"triangles":150,"volume":96.81583600945578,"mesh":"rbxassetid://127746563232185"},{"name":"JP_RiceCollision_11","center":[-24.625762939453125,0,20.866371154785156],"size":[7.22381591796875,3.049999952316284,6.663299560546875],"vertices":77,"triangles":150,"volume":47.90833887654799,"mesh":"rbxassetid://137998821741042"},{"name":"JP_RiceCollision_12","center":[-26.466842651367188,0,3.9355392456054688],"size":[6.066314697265625,3.049999952316284,34.387725830078125],"vertices":77,"triangles":150,"volume":365.69443998468427,"mesh":"rbxassetid://106223110234871"}]]==])
local collisionModel=Instance.new("Model");collisionModel.Name="RiceBankCollision1"
assert(not root:FindFirstChild(collisionModel.Name),"Unexpected bank collision model")
local originals={}
local targets={}
for i=1,3 do local p=folder["JP_Rice_Berm_"..i]
 assert((p.Size-Vector3.new(59,.9,52)).Magnitude<.001)
 assert(math.abs(p.Position.X-(5436+60*i))<.001 and math.abs(p.Position.Y-1.6)<.001 and math.abs(p.Position.Z-83)<.001)
 targets[p]=true; originals[i]=p
end
local props={"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CastShadow"}
local untouched={}
local riceCount=0
for _,p in ipairs(root:GetDescendants()) do
 if p.Name=="Rice seedling" then riceCount+=1 end
 if p:IsA("BasePart") and not targets[p] then
  local row={p=p}; for _,k in ipairs(props) do row[k]=p[k] end
  if p:IsA("MeshPart") then row.MeshId=p.MeshId; row.TextureID=p.TextureID end
  table.insert(untouched,row)
 end
end
assert(riceCount==315,"Unexpected rice planting")
local waterProps={}
for _,k in ipairs({"WaterColor","WaterTransparency","WaterReflectance","WaterWaveSize","WaterWaveSpeed"}) do waterProps[k]=terrain[k] end
local backup=Instance.new("Folder"); backup.Name="RicePaddies_pre_grounded1"
assert(not game.ServerStorage.HudBackup:FindFirstChild(backup.Name),"Backup already exists")
for _,p in ipairs(originals) do p:Clone().Parent=backup end
local channels={"SolidMaterial","SolidOccupancy","LiquidOccupancy"}
local regions={}
for i=1,3 do
 local cx=5436+60*i
 local r=Region3.new(Vector3.new(cx-32,-8,52),Vector3.new(cx+32,8,112)):ExpandToGrid(4)
 local mn=r.CFrame.Position-r.Size/2; local mx=r.CFrame.Position+r.Size/2
 local minCell=Vector3int16.new(mn.X/4,mn.Y/4,mn.Z/4)
 local maxCell=Vector3int16.new(mx.X/4-1,mx.Y/4-1,mx.Z/4-1)
 local copy=terrain:CopyRegion(Region3int16.new(minCell,maxCell))
 copy.Name="PaddyTerrain"..i; copy:SetAttribute("PasteCorner",Vector3.new(minCell.X,minCell.Y,minCell.Z)); copy.Parent=backup
 regions[i]={region=r,before=terrain:ReadVoxelChannels(r,4,channels),corner=mn,cx=cx}
 task.wait()
end
backup.Parent=game.ServerStorage.HudBackup
_G.RiceRepairVerification={untouched=untouched,regions=regions,waterProps=waterProps}
local changed=0
local ok,err=pcall(function()
 for _,p in ipairs(originals) do
  local cf=p.CFrame
  p:ApplyMesh(source); p.Size=Vector3.new(59,3.05,52)
  p.CFrame=CFrame.new(cf.X,1.325,cf.Z)*cf.Rotation
  p.Color=Color3.new(1,1,1); p.Material=Enum.Material.Ground; p.MaterialVariant="JM_PhotographicEarth"
  p.DoubleSided=false; p.Anchored=true; p.CanCollide=false; p.CanQuery=false
  p:SetAttribute("RiceBankVersion","grounded1")
 end
 for _,data in ipairs(sectionData) do
  local importedSection=game.ServerStorage.JapanGardenKit.rice_bank_collision1:FindFirstChild(data.name,true)
  assert(importedSection and importedSection.MeshId==data.mesh,"Collision section asset mismatch")
  local section=game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(data.mesh),{CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition,RenderFidelity=Enum.RenderFidelity.Precise})
  for i,p in ipairs(originals) do
   local q=section:Clone();q.Name="Paddy"..i.."_"..data.name
   -- This FBX import reverses local X/Z. Match measured imported section centers.
   q.Size=Vector3.new(unpack(data.size));q.CFrame=p.CFrame*CFrame.new(-data.center[1],data.center[2],-data.center[3])
   q.Anchored=true;q.CanCollide=true;q.CanQuery=true;q.CanTouch=false;q.Transparency=1;q.CastShadow=false
   q.Parent=collisionModel
  end
  section:Destroy(); task.wait()
 end
 collisionModel.Parent=root
 for _,v in ipairs(regions) do
  local c=terrain:ReadVoxelChannels(v.region,4,channels)
  for x=1,#c.SolidMaterial do for y=1,#c.SolidMaterial[x] do for z=1,#c.SolidMaterial[x][y] do
   local wx=v.corner.X+(x-.5)*4; local wy=v.corner.Y+(y-.5)*4; local wz=v.corner.Z+(z-.5)*4
   if math.abs(wx-v.cx)<=25 and wz>=62 and wz<=104 and wy<0 and c.SolidMaterial[x][y][z]==Enum.Material.Rock then
    c.SolidMaterial[x][y][z]=Enum.Material.Mud; changed+=1
   end
  end end end
  terrain:WriteVoxelChannels(v.region,4,{SolidMaterial=c.SolidMaterial})
  task.wait()
 end
 for _,v in ipairs(regions) do
  local c=terrain:ReadVoxelChannels(v.region,4,channels)
  for x=1,#c.SolidMaterial do for y=1,#c.SolidMaterial[x] do for z=1,#c.SolidMaterial[x][y] do
   assert(c.SolidOccupancy[x][y][z]==v.before.SolidOccupancy[x][y][z],"Solid occupancy changed")
   assert(c.LiquidOccupancy[x][y][z]==v.before.LiquidOccupancy[x][y][z],"Water cell changed")
  end end end
 end
 for _,row in ipairs(untouched) do
  assert(row.p.Parent,"Unrelated part removed")
  for _,k in ipairs(props) do assert(row.p[k]==row[k],"Unrelated property changed "..row.p:GetFullName().." "..k) end
  if row.MeshId then assert(row.p.MeshId==row.MeshId and row.p.TextureID==row.TextureID) end
 end
 for k,v in pairs(waterProps) do assert(terrain[k]==v,"Water appearance changed") end
 folder:SetAttribute("RicePaddiesRepairVersion","grounded1")
end)
if not ok then
 collisionModel:Destroy()
 for _,p in ipairs(originals) do local old=backup[p.Name]; p:ApplyMesh(old); for _,k in ipairs(props) do p[k]=old[k] end; p.DoubleSided=old.DoubleSided; p:SetAttribute("RiceBankVersion",nil) end
 for _,v in ipairs(regions) do terrain:WriteVoxelChannels(v.region,4,v.before) end
 error("Repair rolled back: "..tostring(err))
end
print("QQ RICE PADDIES1:3 closed real-mesh banks; original59x52 footprints and positions retained; ground toeY-.20, crownY2.85")
print("QQ RICE PADDIES1 COLLISION:36 invisible real-mesh sections support bank walking; render rings do not collide")
print("QQ RICE PADDIES1 COLOR:baked dark vertex tint removed; original photographic earth material retained")
print("QQ RICE PADDIES1 BED:"..changed.." Rock cells changed to Mud inside three basin footprints; all solid and liquid occupancy values unchanged")
print("QQ RICE PADDIES1 PRESERVED:"..#untouched.." other Japan parts checked;315 rice seedlings, boats, lawn, paths and water appearance retained")
print("QQ RICE PADDIES1 BACKUP:HudBackup.RicePaddies_pre_grounded1 holds original3 meshes and3 terrain regions")
print("QQ RICE PADDIES1 STATUS:"..(RS:IsRunning() and "SERVER PREVIEW" or "EDIT INSTALLED").."; NOT PUBLISHED")

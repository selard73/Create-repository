-- After Shannon imports kit33, run in stopped Edit BEFORE Play.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and not Run:IsRunning()and game.PlaceId==117372258657114,"Prepare kit33 in stopped Edit")
local CONFIG=game.HttpService:JSONDecode([==[__CONFIG__]==])
local kit=game.ServerStorage.JapanGardenKit
assert(not kit:FindFirstChild("grocer_curtain1")and not kit:FindFirstChild("grocer_curtain1_raw"),"Already prepared; inspect first")
local expected={};for _,row in CONFIG.meshes do expected[row.name]=row end
local function key(n)return(n:gsub("%.%d+$",""))end
local candidates={}
for _,v in workspace:GetChildren()do if v:IsA("Model")and v.Name~="JapanMap"then
 for _,p in v:GetDescendants()do if p:IsA("MeshPart")and key(p.Name)=="GC1_Origin"then table.insert(candidates,v);break end end
end end
assert(#candidates==1,"Expected exactly one new kit33 model")
local raw=candidates[1];local parts={};local all={}
for _,p in raw:GetDescendants()do
 assert(not p:IsA("LuaSourceContainer"),"Unexpected script")
 if p:IsA("BasePart")then
  table.insert(all,p)
  if p:IsA("MeshPart")then local n=key(p.Name);assert(expected[n]and not parts[n]and p.MeshId~="","Unexpected/missing mesh");parts[n]=p
  else assert(p.Name=="RootPart"and p.Transparency==1,"Unexpected non-mesh")end
 end
end
for name in pairs(expected)do assert(parts[name],"Missing "..name)end
local o=parts.GC1_Origin.Position;local r=parts.GC1_Right.Position-o;local z=parts.GC1_Front.Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(z.Magnitude-2)<.04 and math.abs(r.Unit:Dot(z.Unit))<.001,"Import scale/orientation differs")
local frame=CFrame.fromMatrix(o,r.Unit,z.Unit:Cross(r.Unit).Unit,z.Unit)
for name,p in pairs(parts)do
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,x in {-.5,.5}do for _,y in {-.5,.5}do for _,zv in {-.5,.5}do
  local q=frame:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,zv)));lo=lo:Min(q);hi=hi:Max(q)
 end end end
 local row=expected[name];assert((lo-Vector3.new(table.unpack(row.min))).Magnitude<.025 and(hi-Vector3.new(table.unpack(row.max))).Magnitude<.025,"Imported bounds differ: "..name)
end
local source=Instance.new("Model");source.Name="grocer_curtain1";source.WorldPivot=frame
for name,p in pairs(parts)do local c=p:Clone();c.Name=name
 for _,v in c:GetDescendants()do if v:IsA("JointInstance")or v:IsA("WeldConstraint")then v:Destroy()end end
 c.Anchored=true;c.CanCollide=false;c.CanTouch=false;c.Parent=source
end
source:SetAttribute("GrocerCurtainVersion","front1")
for _,p in all do p.Anchored=true;p.CanTouch=false end
raw:SetAttribute("OriginalImportName",raw.Name);raw.Name="grocer_curtain1_raw";raw.Parent=kit;source.Parent=kit
print("QQ GROCER CURTAIN PREPARED:6 real source meshes anchored/stored; raw import preserved; JapanMap unchanged")


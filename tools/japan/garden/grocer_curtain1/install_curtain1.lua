-- Preview on Play Server; install in Edit only after Shannon approves the actual pictures.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and GROCER_CURTAIN1_ALLOW_EDIT==true),"Preview first; Edit requires approval")
local CONFIG=game.HttpService:JSONDecode([==[{
  "version": "front1",
  "materials": {
    "Sage": {
      "rgb": [
        87,
        112,
        86
      ],
      "material": "Fabric"
    },
    "Timber": {
      "rgb": [
        65,
        47,
        35
      ],
      "material": "Wood"
    }
  },
  "meshes": [
    {
      "name": "GC1_Cloth_Sage",
      "min": [
        -10.699999809265137,
        7.260000228881836,
        0.3140000104904175
      ],
      "max": [
        -6.0,
        8.279999732971191,
        0.44600000977516174
      ],
      "triangles": 2088,
      "vertices": 1050
    },
    {
      "name": "GC1_Rail_Timber",
      "min": [
        -10.875,
        8.280000686645508,
        0.2849999964237213
      ],
      "max": [
        -5.824999809265137,
        8.420000076293945,
        0.42499998211860657
      ],
      "triangles": 60,
      "vertices": 32
    },
    {
      "name": "GC1_Mounts_Timber",
      "min": [
        -10.699999809265137,
        8.300000190734863,
        0.03999999910593033
      ],
      "max": [
        -6.0,
        8.40000057220459,
        0.35499998927116394
      ],
      "triangles": 120,
      "vertices": 64
    },
    {
      "name": "GC1_Origin",
      "min": [
        -0.02500000037252903,
        -0.02500000037252903,
        -0.02500000037252903
      ],
      "max": [
        0.02500000037252903,
        0.02500000037252903,
        0.02500000037252903
      ],
      "triangles": 12,
      "vertices": 8
    },
    {
      "name": "GC1_Right",
      "min": [
        1.975000023841858,
        -0.02500000037252903,
        -0.02500000037252903
      ],
      "max": [
        2.0250000953674316,
        0.02500000037252903,
        0.02500000037252903
      ],
      "triangles": 12,
      "vertices": 8
    },
    {
      "name": "GC1_Front",
      "min": [
        -0.02500000037252903,
        -0.02500000037252903,
        1.975000023841858
      ],
      "max": [
        0.02500000037252903,
        0.02500000037252903,
        2.0250000953674316
      ],
      "triangles": 12,
      "vertices": 8
    }
  ],
  "checks": {
    "closedManifold": true,
    "consistentOutwardNormals": true,
    "clothBeamClearance": 0.06400001049041748,
    "clothLanternXClearance": 0.05000019073486328,
    "clothFloorClearance": 7.260000228881836,
    "originalRodRetainedAsRearMount": true
  }
}]==])
local SS=game.ServerStorage;local J=workspace.JapanMap;local m=J.ShopFronts.Mikan
assert(m:GetAttribute("MikanBuildVersion")=="grocer2"and not m:GetAttribute("NorenFacingVersion")and not m:FindFirstChild("Noren1"),"Inspect existing curtain first")
local old=assert(m:FindFirstChild("M2_Facade_Sage"),"Original curtain missing")
local f=m:GetPivot();local pos=f:PointToObjectSpace(old.Position)
assert((pos-Vector3.new(-8.8,7.77,.165)).Magnitude<.01 and math.abs(old.Size.X-5.52)<.01,"Original curtain moved")
local beam=J["Outdoor market revision"]["Mikan greengrocer"]["Lintel over open shop"]
assert((f:PointToObjectSpace(beam.Position)-Vector3.new(0,7.6101465,0)).Magnitude<.01 and math.abs(beam.Size.Z-.5)<.01,"Beam moved")
local source=assert(SS.JapanGardenKit:FindFirstChild("grocer_curtain1"),"Import and anchor/store kit33 before Play")
assert(source:GetAttribute("GrocerCurtainVersion")=="front1","Source not prepared")
local parts={};local count=0;local expected={};for _,row in CONFIG.meshes do expected[row.name]=row end
for _,p in source:GetDescendants()do if p:IsA("BasePart")then assert(p:IsA("MeshPart")and p.Anchored and expected[p.Name]and not parts[p.Name],"Source differs");parts[p.Name]=p;count+=1 end end
assert(count==6);for name in expected do assert(parts[name],"Missing "..name)end
local origin=parts.GC1_Origin.Position;local right=parts.GC1_Right.Position-origin;local front=parts.GC1_Front.Position-origin
assert(math.abs(right.Magnitude-2)<.04 and math.abs(front.Magnitude-2)<.04 and math.abs(right.Unit:Dot(front.Unit))<.001)
local sourceCF=CFrame.fromMatrix(origin,right.Unit,front.Unit:Cross(right.Unit).Unit,front.Unit)
local preserved={}
for i,p in J:GetDescendants()do if p~=old then
 local row={p=p,parent=p.Parent,name=p.Name}
 if p:IsA("BasePart")then row.cf=p.CFrame;row.size=p.Size;row.color=p.Color;row.material=p.Material;row.transparency=p.Transparency;row.collide=p.CanCollide;row.anchored=p.Anchored end
 if p:IsA("TextLabel")then row.text=p.Text end
 table.insert(preserved,row)
end;if i%750==0 then task.wait()end end
local function verify()
 for i,row in preserved do local p=row.p;assert(p.Parent==row.parent and p.Name==row.name,"Unrelated object changed")
  if row.cf then assert(p.CFrame==row.cf and p.Size==row.size and p.Color==row.color and p.Material==row.material and p.Transparency==row.transparency and p.CanCollide==row.collide and p.Anchored==row.anchored,"Unrelated part changed: "..p.Name)end
  if row.text then assert(p.Text==row.text,"Existing text changed")end
  if i%750==0 then task.wait()end
 end
end
local stage=Instance.new("Model");stage.Name="Noren1";stage.WorldPivot=f
for name,p in parts do if name~="GC1_Origin"and name~="GC1_Right"and name~="GC1_Front"then
 local c=p:Clone();c.CFrame=f*sourceCF:ToObjectSpace(p.CFrame)
 local look=assert(CONFIG.materials[name:match("_([^_]+)$")])
 c.Color=Color3.fromRGB(table.unpack(look.rgb));c.Material=Enum.Material[look.material]
 c.Anchored=true;c.CanCollide=false;c.CanTouch=false;c.CanQuery=true;c.CastShadow=true;c.Transparency=0;c.DoubleSided=false;c.RenderFidelity=Enum.RenderFidelity.Precise
 c.Parent=stage
end end
assert(#stage:GetChildren()==3)
local cloth=stage.GC1_Cloth_Sage;local lo=Vector3.new(math.huge,math.huge,math.huge)
for _,x in {-.5,.5}do for _,y in {-.5,.5}do for _,z in {-.5,.5}do local q=f:PointToObjectSpace(cloth.CFrame:PointToWorldSpace(cloth.Size*Vector3.new(x,y,z)));lo=lo:Min(q)end end end
assert(lo.Z>.30 and lo.X> -10.71 and lo.Y>7.25,"Curtain clearance differs")
local hb=SS.HudBackup;assert(not hb:FindFirstChild("GrocerCurtain1Originals"),"Backup exists; inspect first")
local backup=Instance.new("Folder");backup.Name="GrocerCurtain1Originals"
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("Before grocer curtain replacement")end
local ok,err=pcall(function()
 backup.Parent=hb;old.Parent=backup;stage.Parent=m
 verify();m:SetAttribute("NorenFacingVersion","front1")
end)
if not ok then stage:Destroy();old.Parent=m;backup:Destroy();error("Curtain reverted: "..tostring(err))end
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After grocer curtain replacement")end
print("QQ GROCER CURTAIN: three solid folded cloth panels in front of beam; small wooden rail with two standoffs; all3 new mesh batches anchored/noncollidable")
print(string.format("QQ GROCER CURTAIN CLEARANCE: beam %.3f; lanternX %.3f; floor %.3f studs",lo.Z-.25,lo.X+10.75,lo.Y))
print("QQ GROCER CURTAIN PRESERVED: original curtain backed up; all other "..#preserved.." Japan instances unchanged, including beam, lanterns, barrel signs, shelf stock and cafe")
print("QQ GROCER CURTAIN STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")

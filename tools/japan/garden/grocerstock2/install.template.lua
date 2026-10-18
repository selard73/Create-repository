-- Preview on the Play SERVER. Install in stopped Edit only after picture approval,
-- with GROCERSTOCK2_ALLOW_EDIT=true in the wrapper. Never publish.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong environment")
assert((Run:IsRunning() and Run:IsServer()) or (not Run:IsRunning() and GROCERSTOCK2_ALLOW_EDIT==true),"Preview first; Edit requires Shannon's approval")
local CONFIG=game:GetService("HttpService"):JSONDecode([==[__CONFIG__]==])
local SS=game:GetService("ServerStorage")
local J=assert(workspace:FindFirstChild("JapanMap"),"JapanMap missing")
local fronts=assert(J:FindFirstChild("ShopFronts"),"ShopFronts missing")
local shop=assert(fronts:FindFirstChild("Mikan"),"Existing grocer missing")
assert(shop:GetAttribute("MikanBuildVersion")=="grocer2","Unexpected grocer version")
local original=assert(J["Outdoor market revision"]:FindFirstChild("Mikan greengrocer"),"Original shop missing")
local floor=assert(original:FindFirstChild("Shop floor"),"Floor missing")
assert((floor.Position-Vector3.new(6024,.88985,-158)).Magnitude<.1,"Shop moved; remeasure")
local target=CFrame.new(6013,floor.Position.Y+floor.Size.Y/2,-158)*CFrame.Angles(0,-math.pi/2,0)
assert((shop:GetPivot().Position-target.Position).Magnitude<.02,"Installed grocer pivot changed")
local src=assert(SS.JapanGardenKit:FindFirstChild("grocerstock2"),"Import kit32, then anchor/store it BEFORE Play")
assert(src:GetAttribute("GrocerStockVersion")=="stock2","Source preparation missing")
local expected={};for _,m in ipairs(CONFIG.meshes) do expected[m.name]=m end
local parts={};local count=0
for _,p in ipairs(src:GetDescendants()) do
    if p:IsA("BasePart") then
        assert(p:IsA("MeshPart") and expected[p.Name] and not parts[p.Name],"Unexpected source part")
        assert(p.Anchored,"Unanchored source; stop Play and prepare in Edit")
        parts[p.Name]=p;count+=1
    end
end
assert(count==#CONFIG.meshes,"Incorrect source mesh count")
for name in pairs(expected) do assert(parts[name],"Missing source mesh: "..name) end
local o=parts.GS2_Origin.Position;local r=parts.GS2_Right.Position-o;local f=parts.GS2_Front.Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04 and math.abs(r.Unit:Dot(f.Unit))<.001,"Incorrect source scale/orientation")
local frame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
local previous=shop:FindFirstChild("ShelfStock")
if previous then assert(previous:GetAttribute("GrocerStockVersion")=="stock2","Unrelated ShelfStock exists") end
local hb=SS:FindFirstChild("HudBackup")
local backup=hb and hb:FindFirstChild("GrocerStock2Originals")
local retire={};local excluded={}
for _,name in ipairs(CONFIG.removeOld) do
    local current=shop:FindFirstChild(name)
    local saved=backup and backup:FindFirstChild(name)
    assert(current~=nil or saved~=nil,"Original stock mesh missing: "..name)
    assert(not (current and saved),"Duplicate original and backup: "..name)
    if current then assert(current:IsA("MeshPart"),"Unexpected stock class");table.insert(retire,current);excluded[current]=true end
end
for _,name in ipairs({"M2_Pantry_TimberEdge","M2_Pantry_Cedar","M2_Pantry_CedarDark","M2_Label_pantry0_Paper","M2_Label_pantry1_Paper","M2_Label_pantry2_Paper"}) do
    assert(shop:FindFirstChild(name),"Retained shelf/sign missing: "..name)
end
local preserved={}
for i,v in ipairs(J:GetDescendants()) do
    if not excluded[v] and not (previous and (v==previous or v:IsDescendantOf(previous))) then
        local a={v=v,parent=v.Parent,name=v.Name}
        if v:IsA("BasePart") then a.cf=v.CFrame;a.size=v.Size;a.color=v.Color;a.material=v.Material;a.transparency=v.Transparency;a.collide=v.CanCollide;a.anchored=v.Anchored end
        if v:IsA("TextLabel") then a.text=v.Text end
        table.insert(preserved,a)
    end
    if i%750==0 then task.wait() end
end
local function verifyPreserved()
    for i,a in ipairs(preserved) do
        local v=a.v;assert(v.Parent==a.parent and v.Name==a.name,"Unrelated object moved: "..a.name)
        if a.cf then assert(v.CFrame==a.cf and v.Size==a.size and v.Color==a.color and v.Material==a.material and v.Transparency==a.transparency and v.CanCollide==a.collide and v.Anchored==a.anchored,"Unrelated part changed: "..a.name) end
        if a.text then assert(v.Text==a.text,"Existing sign changed") end
        if i%750==0 then task.wait() end
    end
end
local new=Instance.new("Model");new.Name="ShelfStock";new:SetAttribute("GrocerStockVersion","stock2")
new.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
local stockCount=0;local min=Vector3.new(math.huge,math.huge,math.huge);local max=-min
for name,p in pairs(parts) do
    if name~="GS2_Origin" and name~="GS2_Right" and name~="GS2_Front" then
        local localCF=frame:ToObjectSpace(p.CFrame)
        local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
        for _,x in ipairs({-.5,.5}) do for _,y in ipairs({-.5,.5}) do for _,z in ipairs({-.5,.5}) do
            local q=localCF:PointToWorldSpace(p.Size*Vector3.new(x,y,z));lo=lo:Min(q);hi=hi:Max(q)
        end end end
        local m=expected[name]
        assert((lo-Vector3.new(table.unpack(m.min))).Magnitude<.08 and (hi-Vector3.new(table.unpack(m.max))).Magnitude<.08,"Source bounds differ: "..name)
        assert(lo.X>-5.50 and hi.X<11.62 and lo.Y>.40 and hi.Y<6.01 and lo.Z>-21.22 and hi.Z<-19.00,"Stock extends outside shelf: "..name)
        local c=p:Clone();c.CFrame=target*localCF
        local look=assert(CONFIG.materials[name:match("_([^_]+)$")],"Unknown material")
        c.Color=Color3.fromRGB(table.unpack(look.rgb));c.Material=Enum.Material[look.material]
        c.Anchored=true;c.CanCollide=false;c.CanTouch=false;c.CanQuery=true;c.CastShadow=true;c.Transparency=0
        if name:match("_Label$")then
            local appearance=c:FindFirstChildOfClass("SurfaceAppearance")
            assert(c.TextureID~=""or(appearance and appearance.ColorMap~=""),"Printed label texture missing")
            c.Color=Color3.new(1,1,1);c.CastShadow=false;c.RenderFidelity=Enum.RenderFidelity.Precise
        end
        c.Parent=new;stockCount+=1;min=min:Min(lo);max=max:Max(hi)
    end
end
assert(stockCount==#CONFIG.meshes-3,"Incorrect placed stock count")
new.WorldPivot=target
verifyPreserved()
-- Entire replacement is ready. Only the eight named old stock meshes retire.
if not hb then hb=Instance.new("Folder");hb.Name="HudBackup";hb.Parent=SS end
if not backup then backup=Instance.new("Folder");backup.Name="GrocerStock2Originals";backup.Parent=hb end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("Before grocer shelf stock2")end)
local ok,err=pcall(function()
    for _,p in ipairs(retire) do p.Parent=backup end
    if previous then previous.Parent=nil end
    new.Parent=shop;verifyPreserved()
end)
if not ok then
    new:Destroy();for _,p in ipairs(retire) do p.Parent=shop end
    if previous then previous.Parent=shop end
    error("Shelf stock update reverted: "..tostring(err))
end
if previous then previous:Destroy() end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("After grocer shelf stock2")end)
print(string.format("QQ GROCERSTOCK2 DONE: %d anchored noncollidable meshes; tea tins/packets, pantry bottles/miso/spices, noodles/seaweed/shiitake",stockCount))
print(string.format("QQ GROCERSTOCK2 BOUNDS: local x %.3f..%.3f y %.3f..%.3f z %.3f..%.3f; all stock behind shelf front",min.X,max.X,min.Y,max.Y,min.Z,max.Z))
print(string.format("QQ GROCERSTOCK2 PRESERVED: %d existing Japan instances; shelf frames and signs, produce, barrels, cafe and all other shops",#preserved))
print("QQ GROCERSTOCK2 LABELS:44 printed labels; paper follows bottle/tin/tub curves and packet slopes; nine textured label batches, no raised lettering")
print("QQ GROCERSTOCK2 STATUS: "..(Run:IsRunning() and "SERVER PREVIEW; NOT PUBLISHED" or "EDIT; NOT PUBLISHED"))

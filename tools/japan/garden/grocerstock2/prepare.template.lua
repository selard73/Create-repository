-- Run in Edit only after Shannon imports kit32 and authorizes anchor/preparation.
-- Store the raw import intact, derive a clean source, and leave JapanMap unchanged.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and not Run:IsRunning(),"Prepare source in stopped Edit BEFORE Play")
assert(game.PlaceId==117372258657114,"Wrong place")
local CONFIG=game:GetService("HttpService"):JSONDecode([==[__CONFIG__]==])
local SS=game:GetService("ServerStorage")
local kit=assert(SS:FindFirstChild("JapanGardenKit"),"JapanGardenKit missing")
assert(not kit:FindFirstChild("grocerstock2"),"Source already exists; inspect it instead of overwriting")
assert(not kit:FindFirstChild("grocerstock2_raw"),"Raw backup already exists; inspect first")
local expected={};for _,m in ipairs(CONFIG.meshes) do expected[m.name]=m end
local function key(n) return (n:gsub("%.%d+$","")) end
local candidates={}
for _,v in ipairs(workspace:GetChildren()) do
    if v:IsA("Model") and v.Name~="JapanMap" then
        for _,p in ipairs(v:GetDescendants()) do
            if p:IsA("MeshPart") and key(p.Name)=="GS2_Origin" then table.insert(candidates,v);break end
        end
    end
end
assert(#candidates==1,"Expected exactly one newly imported kit32 model")
local raw=candidates[1];local parts={};local anchoredParts={}
for _,p in ipairs(raw:GetDescendants()) do
    assert(not p:IsA("LuaSourceContainer"),"Unexpected script in import")
    if p:IsA("BasePart") then
        table.insert(anchoredParts,p)
        if p:IsA("MeshPart") then
            local name=key(p.Name)
            assert(expected[name] and not parts[name],"Unexpected or duplicate imported mesh: "..name)
            assert(p.MeshId~="","Mesh asset has not imported")
            parts[name]=p
        else assert(p.Name=="RootPart" and p.Transparency==1,"Unexpected non-mesh part") end
    end
end
for name in pairs(expected) do assert(parts[name],"Missing imported mesh: "..name) end
local textured=0
for name,p in pairs(parts)do if name:match("_Label$")then
 local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
 assert(p.TextureID~=""or(appearance and appearance.ColorMap~=""),"Printed label texture missing: "..name.."; import kit32 with textures")
 textured+=1
end end
assert(textured==9,"Expected nine printed-label mesh batches")
local o=parts.GS2_Origin.Position
local r=parts.GS2_Right.Position-o;local f=parts.GS2_Front.Position-o
assert(math.abs(r.Magnitude-2)<.04 and math.abs(f.Magnitude-2)<.04,"Incorrect import scale")
assert(math.abs(r.Unit:Dot(f.Unit))<.001,"Incorrect marker orientation")
local frame=CFrame.fromMatrix(o,r.Unit,f.Unit:Cross(r.Unit).Unit,f.Unit)
for name,p in pairs(parts) do
    local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
    for _,x in ipairs({-.5,.5}) do for _,y in ipairs({-.5,.5}) do for _,z in ipairs({-.5,.5}) do
        local q=frame:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)))
        lo=lo:Min(q);hi=hi:Max(q)
    end end end
    local m=expected[name]
    assert((lo-Vector3.new(table.unpack(m.min))).Magnitude<.08 and (hi-Vector3.new(table.unpack(m.max))).Magnitude<.08,"Imported bounds differ: "..name)
end
local source=Instance.new("Model");source.Name="grocerstock2"
for name,p in pairs(parts) do
    local c=p:Clone();c.Name=name
    for _,v in ipairs(c:GetDescendants()) do
        if v:IsA("JointInstance") or v:IsA("WeldConstraint") then v:Destroy() end
    end
    c.Anchored=true;c.CanCollide=false;c.CanTouch=false;c.Parent=source
end
source.WorldPivot=frame;source:SetAttribute("GrocerStockVersion","stock2")
-- All identity, scale and bounds checks passed before anchoring/storing the import.
for _,p in ipairs(anchoredParts) do p.Anchored=true;p.CanTouch=false end
raw:SetAttribute("OriginalImportName",raw.Name);raw.Name="grocerstock2_raw";raw.Parent=kit
source.Parent=kit
print(string.format("QQ GROCERSTOCK2 PREPARED: %d source meshes anchored; raw import preserved; JapanMap unchanged",#CONFIG.meshes))

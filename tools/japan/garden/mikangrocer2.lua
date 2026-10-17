-- Mikan 2: reference-led greengrocer interior and frontage. Preview FIRST.
-- Run on a play-test SERVER. Edit requires a wrapper variable MIKAN2_ALLOW_EDIT=true
-- only after Shannon approves the close play-test pictures.
-- Precondition: Shannon imports kit22; anchor and store mikan_grocer2 BEFORE play.
-- No publish, DataStore writes, avatar moves, or changes to the other shops/backs.
local Run = game:GetService("RunService")
assert(Run:IsStudio(), "Studio-only installer")
assert(game.PlaceId==117372258657114,"Wrong Roblox place")
assert(Run:IsRunning() or MIKAN2_ALLOW_EDIT == true, "Preview only until Shannon approves installation")
local SS = game:GetService("ServerStorage")
local J = assert(workspace:FindFirstChild("JapanMap"), "JapanMap missing")
local market = assert(J:FindFirstChild("Outdoor market revision"), "Market missing")
local shop = assert(market:FindFirstChild("Mikan greengrocer"), "Mikan greengrocer missing")
local kit = assert(SS:FindFirstChild("JapanGardenKit"), "JapanGardenKit missing")
local src = assert(kit:FindFirstChild("mikan_grocer2"), "Import kit22 and anchor/store mikan_grocer2 before play")
local CONFIG = game:GetService("HttpService"):JSONDecode([==[{"materials":{"Timber":{"rgb":[65,47,35],"material":"Wood"},"TimberEdge":{"rgb":[87,62,42],"material":"Wood"},"Cedar":{"rgb":[149,108,65],"material":"Wood"},"CedarLight":{"rgb":[177,134,86],"material":"Wood"},"CedarPale":{"rgb":[197,156,103],"material":"Wood"},"CedarDark":{"rgb":[124,86,49],"material":"Wood"},"Hoop":{"rgb":[86,75,53],"material":"Wood"},"Tile":{"rgb":[72,76,80],"material":"Slate"},"TileEdge":{"rgb":[93,96,96],"material":"Slate"},"Stone":{"rgb":[120,116,105],"material":"Slate"},"Sage":{"rgb":[87,112,86],"material":"Fabric"},"Cream":{"rgb":[231,222,197],"material":"Fabric"},"Paper":{"rgb":[236,220,179],"material":"SmoothPlastic"},"Ink":{"rgb":[60,46,33],"material":"SmoothPlastic"},"Orange":{"rgb":[229,137,41],"material":"SmoothPlastic"},"OrangeLight":{"rgb":[242,165,61],"material":"SmoothPlastic"},"Leaf":{"rgb":[70,117,58],"material":"SmoothPlastic"},"LeafLight":{"rgb":[126,163,83],"material":"SmoothPlastic"},"Radish":{"rgb":[225,225,197],"material":"SmoothPlastic"},"Purple":{"rgb":[78,50,93],"material":"SmoothPlastic"},"Cucumber":{"rgb":[79,116,48],"material":"SmoothPlastic"},"PickleRed":{"rgb":[151,65,77],"material":"SmoothPlastic"},"PickleGold":{"rgb":[202,168,74],"material":"SmoothPlastic"},"PickleBrine":{"rgb":[143,116,64],"material":"SmoothPlastic"},"Carrot":{"rgb":[218,123,43],"material":"SmoothPlastic"},"Bottle":{"rgb":[79,91,54],"material":"SmoothPlastic"},"BottleBrown":{"rgb":[111,61,34],"material":"SmoothPlastic"},"Ceramic":{"rgb":[119,142,138],"material":"SmoothPlastic"},"Brass":{"rgb":[158,132,75],"material":"Metal"},"DarkMetal":{"rgb":[55,59,56],"material":"Metal"},"Black":{"rgb":[30,32,29],"material":"SmoothPlastic"},"ClothBag":{"rgb":[200,182,144],"material":"Fabric"}},"labels":[{"name":"M2_Label_produce0_Paper","text":"みかん  MIKAN","width":2,"height":0.49,"front":[0,0,1]},{"name":"M2_Label_produce1_Paper","text":"キャベツ  CABBAGE","width":2,"height":0.49,"front":[0,0,1]},{"name":"M2_Label_produce2_Paper","text":"なす  EGGPLANT","width":2,"height":0.49,"front":[0,0,1]},{"name":"M2_Label_produce3_Paper","text":"大根  DAIKON","width":2,"height":0.49,"front":[0,0,1]},{"name":"M2_Label_produce4_Paper","text":"にんじん  CARROTS","width":2,"height":0.49,"front":[0,0,1]},{"name":"M2_Label_produce5_Paper","text":"きゅうり  CUCUMBER","width":2,"height":0.49,"front":[0,0,1]},{"name":"M2_Label_pickle0_Paper","text":"胡瓜漬  CUCUMBER","width":2.25,"height":0.65,"front":[0,0,1]},{"name":"M2_Label_pickle1_Paper","text":"大根漬  DAIKON","width":2.25,"height":0.65,"front":[0,0,1]},{"name":"M2_Label_pickle2_Paper","text":"しば漬  SHIBAZUKE","width":2.25,"height":0.65,"front":[0,0,1]},{"name":"M2_Label_pantry0_Paper","text":"お茶  TEA","width":3.1,"height":0.55,"front":[0,0,1]},{"name":"M2_Label_pantry1_Paper","text":"調味料  PANTRY","width":3.1,"height":0.55,"front":[0,0,1]},{"name":"M2_Label_pantry2_Paper","text":"乾物  DRY GOODS","width":3.1,"height":0.55,"front":[0,0,1]}],"meshNames":["M2_Facade_Tile","M2_Facade_TileEdge","M2_Facade_Timber","M2_Facade_TimberEdge","M2_Facade_Sage","M2_Facade_DarkMetal","M2_Facade_Cream","M2_Facade_CedarDark","M2_Threshold_Stone","M2_Produce_TimberEdge","M2_Produce_CedarDark","M2_Produce_CedarLight","M2_Produce_Cedar","M2_Produce_Orange","M2_Produce_Leaf","M2_Produce_OrangeLight","M2_Label_produce0_Paper","M2_Produce_LeafLight","M2_Label_produce1_Paper","M2_Produce_Purple","M2_Label_produce2_Paper","M2_Produce_Radish","M2_Label_produce3_Paper","M2_Produce_Carrot","M2_Label_produce4_Paper","M2_Produce_Cucumber","M2_Label_produce5_Paper","M2_Pickle0_CedarLight","M2_Pickle0_CedarPale","M2_Pickle0_Cedar","M2_Pickle0_Hoop","M2_Pickle0_CedarDark","M2_Pickle0_PickleBrine","M2_Pickle0_Cucumber","M2_Pickle0_Leaf","M2_Label_pickle0_stem_CedarDark","M2_Label_pickle0_Paper","M2_Pickle1_CedarLight","M2_Pickle1_CedarPale","M2_Pickle1_Cedar","M2_Pickle1_Hoop","M2_Pickle1_CedarDark","M2_Pickle1_PickleBrine","M2_Pickle1_PickleGold","M2_Label_pickle1_stem_CedarDark","M2_Label_pickle1_Paper","M2_Pickle2_CedarLight","M2_Pickle2_CedarPale","M2_Pickle2_Cedar","M2_Pickle2_Hoop","M2_Pickle2_CedarDark","M2_Pickle2_PickleBrine","M2_Pickle2_PickleRed","M2_Label_pickle2_stem_CedarDark","M2_Label_pickle2_Paper","M2_Pantry_TimberEdge","M2_Pantry_Cedar","M2_Pantry_CedarDark","M2_Pantry_ClothBag","M2_Pantry_CedarPale","M2_Pantry_Paper","M2_Pantry_BottleBrown","M2_Pantry_Timber","M2_Pantry_Ceramic","M2_Pantry_CedarLight","M2_Pantry_Sage","M2_Label_pantry0_Paper","M2_Label_pantry1_Paper","M2_Label_pantry2_Paper","M2_Counter_TimberEdge","M2_Counter_CedarLight","M2_Counter_Cedar","M2_Counter_DarkMetal","M2_Counter_Brass","M2_Counter_Cream","M2_Counter_Paper","M2_Counter_CedarDark","M2_Lining_Cream","M2_Lining_Cedar","M2_Lining_CedarDark","M2_Lining_TimberEdge","M2_Ceiling_CedarLight","M2_Lining_DarkMetal","M2_Lining_Timber","M2_Origin","M2_Right","M2_Front"]}]==])
local floor = assert(shop:FindFirstChild("Shop floor"), "Original shop floor missing")
assert((floor.Position - Vector3.new(6024,0.88985,-158)).Magnitude < 0.1, "Shop moved since survey; remeasure")
local floorY = floor.Position.Y + floor.Size.Y / 2
local origin = Vector3.new(6013, floorY, -158)
local target = CFrame.new(origin) * CFrame.Angles(0,-math.pi/2,0)
local function key(name) return (name:gsub("%.%d+$","")) end
local function meshMap(root)
    local found = {}
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") then
            assert(p:IsA("MeshPart"), "Kit contains a non-mesh part: "..p.Name)
            local name=key(p.Name)
            assert(not found[name], "Duplicate mesh name: "..name)
            assert(p.Anchored, "Unanchored kit part: "..name.."; stop and prepare the kit in Edit")
            found[name]=p
        end
    end
    for _,name in ipairs(CONFIG.meshNames) do assert(found[name],"Missing mesh: "..name) end
    return found
end
local sourceParts = meshMap(src)
local function sourceFrame(parts)
    local o=parts.M2_Origin.Position
    local right=parts.M2_Right.Position-o
    local front=parts.M2_Front.Position-o
    assert(math.abs(right.Magnitude-2)<.04 and math.abs(front.Magnitude-2)<.04,
        "Import scale differs from the measured 1-stud units; stop and correct the kit")
    right=right.Unit;front=front.Unit
    assert(math.abs(right:Dot(front))<.001,"Import markers not orthogonal")
    return CFrame.fromMatrix(o,right,front:Cross(right).Unit,front)
end
sourceFrame(sourceParts)
local mainSign
for _,v in ipairs(shop:GetChildren()) do
    if v:IsA("BasePart") and v.Name=="Handwritten shop sign" and math.abs(v.Position.Y-9.45)<.05 then
        assert(not mainSign,"Ambiguous main sign");mainSign=v
    end
end
assert(mainSign,"Existing main sign missing; do not add a duplicate")
local preserve={["Tiled shop roof"]=true,["Shop floor"]=true,["Back wall"]=true,["Side wall"]=true,
    ["Stone foundation"]=true,["Cedar corner post"]=true,["Exposed roof beam"]=true,["Lintel over open shop"]=true}
local retire={}
for _,v in ipairs(shop:GetChildren()) do if not preserve[v.Name] and v~=mainSign then table.insert(retire,v) end end
local fronts=J:FindFirstChild("ShopFronts")
local previous=fronts and fronts:FindFirstChild("Mikan")
if previous then assert(previous:GetAttribute("MikanBuildVersion")=="grocer2","An unrelated Mikan front exists; inspect first") end
local hb=SS:FindFirstChild("HudBackup")
local backup=hb and hb:FindFirstChild("MikanGrocer2Originals")
if not previous then assert(not backup or #backup:GetChildren()==0,"Previous originals backup exists without a preview; inspect first") end
local backs=assert(J:FindFirstChild("ShopBacks"),"ShopBacks missing")
local backCount=#backs:GetDescendants()
local others={}
for _,v in ipairs(market:GetChildren()) do if v~=shop then others[v]=#v:GetDescendants() end end
-- Prepare the entire replacement outside the data model before retiring originals.
local model=src:Clone();model.Name="Mikan";model:SetAttribute("MikanBuildVersion","grocer2")
local parts=meshMap(model);local sourceCF=sourceFrame(parts)
local colliders=0
local worldMin,worldMax=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
for name,p in pairs(parts) do
    p.CFrame=target * sourceCF:ToObjectSpace(p.CFrame)
    p.Name=name
    if name~="M2_Origin" and name~="M2_Right" and name~="M2_Front" then
        local materialKey=name:match("_([^_]+)$")
        local look=assert(CONFIG.materials[materialKey],"Unknown material: "..name)
        p.Color=Color3.fromRGB(table.unpack(look.rgb));p.Material=Enum.Material[look.material]
        p.Anchored=true;p.CanTouch=false;p.CastShadow=true;p.Transparency=0
        local structural=(materialKey:find("Cedar")~=nil or materialKey=="TimberEdge" or materialKey=="Timber")
        local furniture=(name:find("^M2_Produce_") or name:find("^M2_Pickle%d_") or name:find("^M2_Pantry_") or name:find("^M2_Counter_"))~=nil
        p.CanCollide=name=="M2_Threshold_Stone" or (structural and furniture)
        p.CanQuery=true
        if p.CanCollide then colliders+=1 end
        for _,x in ipairs({-.5,.5}) do for _,y in ipairs({-.5,.5}) do for _,z in ipairs({-.5,.5}) do
            local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z))
            worldMin=Vector3.new(math.min(worldMin.X,q.X),math.min(worldMin.Y,q.Y),math.min(worldMin.Z,q.Z))
            worldMax=Vector3.new(math.max(worldMax.X,q.X),math.max(worldMax.Y,q.Y),math.max(worldMax.Z,q.Z))
        end end end
        -- Leaves and noren have both faces in the exported geometry.
    end
end
assert(worldMin.X>6010.4,"Kit projects farther into lane than the measured frontage")
assert(worldMin.Z>-171.2 and worldMax.Z<-144.7,"Kit extends into neighbouring shop frontage")
-- Paper labels attached to their own mesh boards. No new shop-name sign.
local faces={
    {Enum.NormalId.Front,Vector3.new(0,0,-1)},{Enum.NormalId.Back,Vector3.new(0,0,1)},
    {Enum.NormalId.Left,Vector3.new(-1,0,0)},{Enum.NormalId.Right,Vector3.new(1,0,0)},
    {Enum.NormalId.Top,Vector3.new(0,1,0)},{Enum.NormalId.Bottom,Vector3.new(0,-1,0)}}
for _,label in ipairs(CONFIG.labels) do
    local p=assert(parts[label.name],"Label panel missing")
    local worldFace=target:VectorToWorldSpace(Vector3.new(table.unpack(label.front)))
    local best,dot=nil,-math.huge
    for _,f in ipairs(faces) do local score=p.CFrame:VectorToWorldSpace(f[2]):Dot(worldFace);if score>dot then best=f[1];dot=score end end
    assert(dot>.999,"Label panel is not aligned with frontage")
    local gui=Instance.new("SurfaceGui");gui.Name="ProductLabel";gui.Face=best;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud=90;gui.LightInfluence=.55;gui.AlwaysOnTop=false;gui.Parent=p
    local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(.92,.84);text.Position=UDim2.fromScale(.04,.08)
    text.BackgroundTransparency=1;text.Font=Enum.Font.SourceSans;text.TextScaled=true;text.TextWrapped=true
    text.TextColor3=Color3.fromRGB(60,46,33);text.Text=label.text;text.Parent=gui
end
local function lamp(meshName,position,brightness,range)
    local p=assert(parts[meshName],"Lamp mesh missing")
    local a=Instance.new("Attachment");a.Name="LampPosition";a.Position=p.CFrame:PointToObjectSpace(target:PointToWorldSpace(position));a.Parent=p
    local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,220,172);light.Brightness=brightness;light.Range=range;light.Shadows=false;light.Parent=a
end
lamp("M2_Facade_Cream",Vector3.new(-11.25,7.04,.85),.45,9)
lamp("M2_Facade_Cream",Vector3.new(11.15,7.04,.85),.45,9)
lamp("M2_Lining_Cream",Vector3.new(-1,7.7,-7.5),.85,15)
lamp("M2_Lining_Cream",Vector3.new(-1,7.7,-16.5),.85,15)
parts.M2_Origin:Destroy();parts.M2_Right:Destroy();parts.M2_Front:Destroy()
model.WorldPivot=target
pcall(function() model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic end)
-- All preflight checks have succeeded; commit this one-shop change.
if not hb then hb=Instance.new("Folder");hb.Name="HudBackup";hb.Parent=SS end
if not backup then backup=Instance.new("Folder");backup.Name="MikanGrocer2Originals";backup.Parent=hb end
if not fronts then fronts=Instance.new("Folder");fronts.Name="ShopFronts";fronts.Parent=J end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("Before Mikan grocer2") end)
local ok,err=pcall(function()
    for _,v in ipairs(retire) do v:SetAttribute("Mikan2WasIn",shop:GetFullName());v.Parent=backup end
    if previous then previous.Parent=nil end
    model.Parent=fronts
    assert(#backs:GetDescendants()==backCount,"ShopBacks changed unexpectedly")
    for v,count in pairs(others) do assert(v.Parent==market and #v:GetDescendants()==count,"Other market model changed") end
end)
if not ok then
    model:Destroy()
    for _,v in ipairs(retire) do v.Parent=shop;v:SetAttribute("Mikan2WasIn",nil) end
    if previous then previous.Parent=fronts end
    error("Mikan install reverted: "..tostring(err))
end
if previous then previous:Destroy() end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("After Mikan grocer2") end)
print(string.format("QQ MIKANGROCER2 DONE: %d meshes, %d product labels, %d collidable meshes; %d original direct children -> HudBackup.MikanGrocer2Originals",#CONFIG.meshNames-3,#CONFIG.labels,colliders,#retire))
print(string.format("QQ MIKANGROCER2 BOUNDS: x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f; stock inside original front x >= 6013",worldMin.X,worldMax.X,worldMin.Y,worldMax.Y,worldMin.Z,worldMax.Z))
print("QQ MIKANGROCER2 PRESERVED: original roof, shell, floor, main sign; all other shops and all ShopBacks")
print("QQ MIKANGROCER2 STATUS: "..(Run:IsRunning() and "PLAY-TEST SERVER PREVIEW ONLY; discarded on stop" or "EDIT; NOT PUBLISHED"))
-- After an approved Edit installation, set PreciseConvexDecomposition on collidable
-- placed MeshParts in a SEPARATE Studio call, per the established import limitation.

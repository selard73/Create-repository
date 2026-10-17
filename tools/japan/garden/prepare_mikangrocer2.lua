-- Run only after Shannon imports kit22 and authorizes anchoring/storing it.
-- This prepares source assets only; it does not install anything in the shop.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and not Run:IsRunning(),"Prepare the import in Edit BEFORE any play test")
assert(game.PlaceId==117372258657114,"Wrong Roblox place")
local SS=game:GetService("ServerStorage")
local kit=assert(SS:FindFirstChild("JapanGardenKit"),"JapanGardenKit missing")
local source=kit:FindFirstChild("mikan_grocer2")
if not source then source=workspace:FindFirstChild("mikan_grocer2",true) end
assert(source and source:IsA("Model"),"Imported mikan_grocer2 model not found")
assert(source.Parent==kit or source:IsDescendantOf(workspace),"Unexpected import location")
local found={};local count=0
for _,p in ipairs(source:GetDescendants()) do
    if p:IsA("BasePart") then
        assert(p:IsA("MeshPart"),"Unexpected non-mesh source part")
        local name=p.Name:gsub("%.%d+$","")
        assert(not found[name],"Duplicate imported mesh name: "..name)
        found[name]=p;count+=1
    end
end
assert(count==87,"Expected 87 meshes including 3 placement markers; got "..count)
assert(found.M2_Origin and found.M2_Right and found.M2_Front,"Placement markers missing")
local o=found.M2_Origin.Position
assert(math.abs((found.M2_Right.Position-o).Magnitude-2)<.04,"Wrong FBX import scale")
assert(math.abs((found.M2_Front.Position-o).Magnitude-2)<.04,"Wrong FBX import scale")
for _,p in pairs(found) do p.Anchored=true;p.CanTouch=false end
source.Parent=kit
source:SetAttribute("MikanKitVersion","grocer2")
print("QQ MIKANGROCER2 PREPARED: 87 meshes anchored; source in ServerStorage.JapanGardenKit.mikan_grocer2; shop unchanged")

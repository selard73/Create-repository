-- Only after Shannon imports kit23 and authorizes anchoring/preparation.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Edit only: prepare source BEFORE Play")
assert(game.PlaceId==117372258657114,"Wrong place")
local kit=assert(game:GetService("ServerStorage"):FindFirstChild("JapanGardenKit"))
local source=kit:FindFirstChild("cat_cafe1")or workspace:FindFirstChild("cat_cafe1",true)
assert(source and source:IsA("Model"),"Imported cat_cafe1 not found")
assert(source.Parent==kit or source:IsDescendantOf(workspace),"Unexpected source location")
local parts={};local n=0
for _,p in ipairs(source:GetDescendants())do if p:IsA("BasePart")then
 assert(p:IsA("MeshPart"),"Non-mesh import part")
 local name=p.Name:gsub("%.%d+$","");assert(not parts[name],"Duplicate mesh name");parts[name]=p;n+=1
end end
assert(n==94,"Unexpected imported mesh count: "..n)
assert(parts.C1_Origin and parts.C1_Right and parts.C1_Front,"Placement markers missing")
local o=parts.C1_Origin.Position
assert(math.abs((parts.C1_Right.Position-o).Magnitude-2)<.04 and math.abs((parts.C1_Front.Position-o).Magnitude-2)<.04,"Wrong FBX import scale")
for _,p in pairs(parts)do p.Anchored=true;p.CanTouch=false end
source.Parent=kit;source:SetAttribute("CatCafeKitVersion","cafe1")
print("QQ CATCAFE1 PREPARED: "..n.." meshes anchored in ServerStorage.JapanGardenKit.cat_cafe1; existing cafe unchanged")

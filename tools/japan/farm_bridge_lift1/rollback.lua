assert(_G.FARM_BRIDGE_LIFT1_ALLOW_ROLLBACK==true,"Explicit rollback approval required")
local b=workspace.JapanMap.TeaHills["Farm stream bridge"]
assert(b:GetAttribute("FarmBridgeLiftVersion")=="lift1","No lift1 installed")
local p={} for _,i in b:GetDescendants() do if i:IsA("BasePart") then assert(typeof(i:GetAttribute("FarmBridgeLift1WasCFrame"))=="CFrame","Missing original transform") table.insert(p,i) end end
assert(#p==120,"Unexpected bridge part count")
for _,i in p do i.CFrame=i:GetAttribute("FarmBridgeLift1WasCFrame") i:SetAttribute("FarmBridgeLift1WasCFrame",nil) end
b:SetAttribute("FarmBridgeLiftVersion",nil)
print("QQ FARM BRIDGE LIFT1 ROLLBACK:120 original transforms restored; backup retained")

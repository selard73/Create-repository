-- Pair with cafe_sides4. Preview first; Edit only after Shannon approves the combined pictures.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or (not Run:IsRunning() and CAFE_SIDE_TONE1_ALLOW_EDIT==true),"Preview first; Edit requires approval")
local shop=workspace.JapanMap["Outdoor market revision"]["Cat cafe"]
assert(shop:GetAttribute("SideDetailsVersion")=="rear4","Apply approved rear-matched details first")
assert(not shop:GetAttribute("SideWoodToneVersion"),"Tone change already present")
local upper
for _,p in shop["Traditional downtown facade"]:GetChildren() do
 if p:IsA("BasePart") and p.Name=="Upper timber side wall" and math.abs(p.Position.Z-20)<.01 then upper=p end
end
assert(upper and upper.Material==Enum.Material.WoodPlanks and upper.Color==Color3.fromRGB(162,143,119),"Upper north wall changed")
assert(upper:GetAttribute("CafeSideToneWasColor")==nil,"Existing color backup")
local was=upper.Color
if not Run:IsRunning() then game.ChangeHistoryService:SetWaypoint("Before cafe side wood tone") end
upper:SetAttribute("CafeSideToneWasColor",was)
upper.Color=Color3.fromRGB(210,195,172)
shop:SetAttribute("SideWoodToneVersion","warm1")
if not Run:IsRunning() then game.ChangeHistoryService:SetWaypoint("After cafe side wood tone") end
print("QQ CAFE SIDE TONE1:only north upper wall color changed162,143,119 to210,195,172; lower wall220,205,183 retained; original grain/material and geometry retained")
print("QQ CAFE SIDE TONE1 BACKUP:original Color3 stored on upper wall CafeSideToneWasColor; rollback restores it and removes SideWoodToneVersion")
print("QQ CAFE SIDE TONE1 STATUS:"..(Run:IsRunning() and "SERVER PREVIEW" or "EDIT INSTALLED").."; NOT PUBLISHED")

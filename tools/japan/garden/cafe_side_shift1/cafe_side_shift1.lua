-- Further-left upper window on installed cafe side4. Preview first; Edit only after approval.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or (not Run:IsRunning() and CAFE_SIDE_SHIFT1_ALLOW_EDIT==true),"Preview first; Edit requires approval")
local shop=workspace.JapanMap["Outdoor market revision"]["Cat cafe"]
assert(shop:GetAttribute("SideDetailsVersion")=="rear4" and shop:GetAttribute("SideWoodToneVersion")=="warm1","Expected installed cafe side4 and tone1")
assert(not shop:GetAttribute("SideWindowShiftVersion"),"Shift already installed")
local root=assert(shop:FindFirstChild("CafeSideDetails4"))
assert(math.abs(root.UpperFrontWindow.Win_Bars.Position.X-6022.0)<.002 and math.abs(root.UpperRearWindow.Win_Bars.Position.X-6028.6)<.002,"Window positions changed")
local selected={}
for _,name in {"UpperFrontWindow","UpperFrontHood"} do
 for _,p in root[name]:GetChildren() do
  assert(p:IsA("MeshPart") and p.Anchored and not p:GetAttribute("CafeSideShift1WasCFrame"),"Unexpected source")
  table.insert(selected,{p=p,cf=p.CFrame})
 end
end
assert(#selected==7)
if not Run:IsRunning() then game:GetService("ChangeHistoryService"):SetWaypoint("Before cafe upper-left window further left") end
for _,b in selected do
 b.p:SetAttribute("CafeSideShift1WasCFrame",b.cf)
 b.p.CFrame=b.cf+Vector3.new(-1.6,0,0)
end
shop:SetAttribute("SideWindowShiftVersion","left1")
if not Run:IsRunning() then game:GetService("ChangeHistoryService"):SetWaypoint("After cafe upper-left window further left") end
print("QQ CAFE SIDE SHIFT1:7 upper-left window/hood meshes moved1.6 studs left; new center6020.4, lower window6019.2, right upper6028.6;1.2-stud offset from lower window and4.0-stud upper sill gap")
print("QQ CAFE SIDE SHIFT1 BACKUP:7 original CFrames stored on CafeSideShift1WasCFrame; sizes/materials/colors unchanged")
print("QQ CAFE SIDE SHIFT1 STATUS:"..(Run:IsRunning() and "SERVER PREVIEW" or "EDIT INSTALLED").."; NOT PUBLISHED")

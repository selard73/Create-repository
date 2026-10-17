-- Reverse only the existing three-piece mug handle; preserve the current live client.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and not Run:IsRunning()and TREEHOUSEMUG_ALLOW_EDIT==true,"Preview first; approved stopped Edit only")
assert(game.PlaceId==117372258657114,"Wrong place")
local tree=assert(workspace:FindFirstChild("Treehouse"))
local client=assert(tree:FindFirstChild("TreehouseClient"))
local replacements={
 {"L(6.9, 13.65, -5.72)","L(6.9, 13.65, -5.5)"},
 {"L(6.9, 13.9, -5.6)","L(6.9, 13.9, -5.7)"},
 {"L(6.9, 13.4, -5.6)","L(6.9, 13.4, -5.7)"},
}
local source=client.Source;local updated=source;local changed=0
for _,r in ipairs(replacements)do
 local a,b=updated:find(r[1],1,true)
 if a then
  assert(not updated:find(r[1],b+1,true),"Ambiguous mug handle source")
  updated=updated:sub(1,a-1)..r[2]..updated:sub(b+1);changed+=1
 else assert(updated:find(r[2],1,true),"Mug source differs; inspect first")end
end
assert(changed==0 or changed==3,"Partially modified handle; inspect first")
if changed==0 then print("QQ TREEHOUSE MUG: handle already faces the cup correctly");return end
local probe=Instance.new("ModuleScript");probe.Name="MugHandleCompileOnly";probe.Source="return function()\n"..updated.."\nend";probe.Parent=game.ServerStorage
local ok,result=pcall(require,probe);probe:Destroy();assert(ok,result);assert(type(result)=="function","Compile check failed")
local serverSource=tree.TreehouseServer.Source;local resetSource=tree.TreehouseReset.Source;local count=#tree:GetDescendants()
local hb=assert(game.ServerStorage:FindFirstChild("HudBackup"));assert(not hb:FindFirstChild("TreehouseClient_pre_mug_handle1"),"Backup already exists; inspect first")
game.ChangeHistoryService:SetWaypoint("Before treehouse mug handle correction")
local backup=client:Clone();backup.Name="TreehouseClient_pre_mug_handle1";backup.Enabled=false;backup.Parent=hb
client.Source=updated
assert(client.Source==updated and tree.TreehouseServer.Source==serverSource and tree.TreehouseReset.Source==resetSource and #tree:GetDescendants()==count)
game.ChangeHistoryService:SetWaypoint("After treehouse mug handle correction")
print("QQ TREEHOUSE MUG: corrected three handle positions; outer bar away from cup and both arms join the cup")
print("QQ TREEHOUSE PRESERVED: only three coordinate values changed in current client; mug body, table, sign, progress and all other scripts unchanged")
print("QQ TREEHOUSE STATUS: EDIT INSTALLED; NOT PUBLISHED")

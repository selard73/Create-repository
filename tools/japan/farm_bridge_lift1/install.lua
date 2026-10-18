local RunService=game:GetService("RunService")
assert(RunService:IsRunning() or _G.FARM_BRIDGE_LIFT1_ALLOW_EDIT==true,"Preview first; Edit installation requires Shannon's approval.")
assert(not RunService:IsRunning() or not RunService:IsClient(),"Run on Server or approved Edit.")
local bridge=workspace.JapanMap.TeaHills["Farm stream bridge"]
assert(not bridge:GetAttribute("FarmBridgeLiftVersion"),"Bridge lift already installed.")
local before={} local others={}
for _,p in workspace.JapanMap:GetDescendants() do if p:IsA("BasePart") then
 local v={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,variant=p.MaterialVariant,collide=p.CanCollide}
 if p:IsDescendantOf(bridge) then before[p]=v else others[p]=v end
end end
local n=0 for _ in before do n+=1 end assert(n==120,"Unexpected bridge geometry.")
local backupRoot=game.ServerStorage:FindFirstChild("HudBackup") or Instance.new("Folder",game.ServerStorage)
backupRoot.Name="HudBackup"
assert(not backupRoot:FindFirstChild("FarmBridge_pre_lift1"),"Backup already exists.")
local backup=bridge:Clone() backup.Name="FarmBridge_pre_lift1" backup.Parent=backupRoot
local ok,err=pcall(function()
 for p,v in before do p:SetAttribute("FarmBridgeLift1WasCFrame",v.cf) p.CFrame=v.cf+Vector3.new(0,3.2,0) end
 for p,v in before do assert((p.Position-v.cf.Position-Vector3.new(0,3.2,0)).Magnitude<.001 and p.CFrame.Rotation==v.cf.Rotation and p.Size==v.size and p.Color==v.color and p.Material==v.material and p.MaterialVariant==v.variant and p.CanCollide==v.collide,"Bridge mismatch") end
 local count=0
 for p,v in others do assert(p.Parent and p.CFrame==v.cf and p.Size==v.size and p.Color==v.color and p.Material==v.material and p.MaterialVariant==v.variant and p.CanCollide==v.collide,"Unrelated part changed") count+=1 end
 bridge:SetAttribute("FarmBridgeLiftVersion","lift1")
 print("QQ FARM BRIDGE LIFT1:120 existing bridge parts raised3.2 studs; original span, arch, rails, colors and materials retained")
 print("QQ FARM BRIDGE LIFT1 PRESERVED:"..count.." other Japan parts unchanged; no terrain or water writes")
 print("QQ FARM BRIDGE LIFT1 BACKUP:HudBackup.FarmBridge_pre_lift1 plus120 original CFrame attributes")
 print("QQ FARM BRIDGE LIFT1 STATUS:"..(RunService:IsRunning() and "SERVER PREVIEW; NOT INSTALLED" or "EDIT INSTALLED; NOT PUBLISHED"))
end)
if not ok then for p,v in before do p.CFrame=v.cf p:SetAttribute("FarmBridgeLift1WasCFrame",nil) end bridge:SetAttribute("FarmBridgeLiftVersion",nil) backup:Destroy() error(err) end

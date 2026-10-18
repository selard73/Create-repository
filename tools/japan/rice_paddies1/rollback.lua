-- Only run after explicit authorization to undo this rice-paddy repair.
assert(_G.RICE_PADDIES1_ALLOW_ROLLBACK==true,"Explicit rollback authorization required")
assert(not game:GetService("RunService"):IsRunning(),"Use stopped Edit")
local root=workspace.JapanMap
local folder=root.BlenderScenery["Sculpted terrain"]
assert(folder:GetAttribute("RicePaddiesRepairVersion")=="grounded1")
local backup=game.ServerStorage.HudBackup:FindFirstChild("RicePaddies_pre_grounded1")
assert(backup and #backup:GetChildren()==6,"Original backup incomplete")
for i=1,3 do
 local p=folder["JP_Rice_Berm_"..i];local old=backup[p.Name]
 assert(old and old:IsA("MeshPart"))
 p:ApplyMesh(old)
 for _,k in ipairs({"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CastShadow","DoubleSided"})do p[k]=old[k]end
 p:SetAttribute("RiceBankVersion",nil)
 local region=backup["PaddyTerrain"..i];local corner=region:GetAttribute("PasteCorner")
 workspace.Terrain:PasteRegion(region,Vector3int16.new(corner.X,corner.Y,corner.Z),true)
 task.wait()
end
local collision=root:FindFirstChild("RiceBankCollision1");if collision then collision:Destroy()end
folder:SetAttribute("RicePaddiesRepairVersion",nil)
_G.RICE_PADDIES1_ALLOW_ROLLBACK=nil
print("QQ RICE PADDIES1 ROLLBACK:original banks and terrain restored; only repair collision removed; backup retained")

-- Replace only this draft's 15 dress templates with corrected normals.
assert(not game:GetService('RunService'):IsRunning(),'Edit only')
local imp=assert(workspace:FindFirstChild('DressesSmooth'),'Import smoothed meshes first')
local kit=game.ReplicatedStorage.DressKit
local found={}
for _,p in ipairs(imp:GetDescendants()) do if p:IsA('MeshPart') then found[p.Name]=p end end
local n=0;for name in pairs(found) do n+=1;assert(kit:FindFirstChild(name),'Unexpected mesh '..name) end;assert(n==15)
for name,p in pairs(found) do
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.DoubleSided=true;p.Material=Enum.Material.Fabric
 kit[name]:Destroy();p.Parent=kit
end
imp:Destroy();warn('QQ DRESS SMOOTH KIT PASS')

assert(not game:GetService('RunService'):IsRunning(),'Edit only')
local k=game.ReplicatedStorage.DressKit;local f=workspace.DressShop
assert(loadstring(k.Catalogue.Source));assert(loadstring(f.DressServer.Source));assert(loadstring(f.DressClient.Source))
local count=0
for _,m in ipairs(k:GetChildren()) do if m:IsA('MeshPart') then count+=1;warn('QQ DRESS MESH '..game:GetService('HttpService'):JSONEncode({name=m.Name,mesh=m.MeshId,size={m.Size.X,m.Size.Y,m.Size.Z},doubleSided=m.DoubleSided})) end end
assert(count==15);assert(game:GetService('CollectionService'):HasTag(f.Room,'SkyRoom'))
warn('QQ DRESS DRAFT CHECK PASS 15 meshes / all scripts compile / tagged room')

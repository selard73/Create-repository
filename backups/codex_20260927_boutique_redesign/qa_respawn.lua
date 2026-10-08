assert(game:GetService('RunService'):IsStudio() and game:GetService('RunService'):IsRunning() and game:GetService('RunService'):IsServer())
local p=game.Players:GetPlayers()[1];local f=workspace.DressShop
p:SetAttribute('GateBypass',true);p:SetAttribute('Acorns',1000)
f.DressDebug:Invoke(p,'give','rue_2');f.DressDebug:Invoke(p,'wear','rue_2');task.wait(.4)
p:LoadCharacterAsync();task.wait(3)
local c=p.Character;assert(c:FindFirstChild('WornDress') and c.WornDress:GetAttribute('DressId')=='rue_2','Respawn did not restore dress')
warn('QQ DRESS RESPAWN PASS')
local cat=require(game.ReplicatedStorage.DressKit.Catalogue)
local rig=Instance.new('Model');local torso=Instance.new('Part');torso.Name='Torso';torso.Size=Vector3.new(2,2,1);torso.CFrame=CFrame.new(0,5,0);torso.Parent=rig
for _,id in ipairs(cat.order) do local m=cat.attach(game.ReplicatedStorage.DressKit,id,rig,'Test');assert(m and #m:GetChildren()==5);m:Destroy() end;rig:Destroy();warn('QQ DRESS R6 STRUCTURE PASS')
c:PivotTo(CFrame.new(f.DoorPad.Position+Vector3.new(0,0,-3)));f.DressDebug:Invoke(p,'in');task.wait(1.3)
c:PivotTo(CFrame.new(f:GetAttribute('SpotX'),f:GetAttribute('SpotY')+3,f:GetAttribute('SpotZ')))
game.ReplicatedStorage.DressShopEvent:FireClient(p,'mirror')
warn('QQ DRESS FINAL READY')

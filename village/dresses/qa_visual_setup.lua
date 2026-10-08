assert(game:GetService('RunService'):IsStudio() and game:GetService('RunService'):IsServer() and game:GetService('RunService'):IsRunning())
local p=game.Players:GetPlayers()[1];local f=workspace.DressShop;p:SetAttribute('GateBypass',true)
p:SetAttribute('Found_forest',20);p:SetAttribute('Found_village',20)
p.Character:PivotTo(CFrame.new(f.DoorPad.Position+Vector3.new(0,0,-3)))
f.DressDebug:Invoke(p,'in');task.wait(1.3)
local pos=Vector3.new(f:GetAttribute('SpotX'),f:GetAttribute('SpotY')+3,f:GetAttribute('SpotZ'))
p.Character:PivotTo(CFrame.new(pos));game.ReplicatedStorage.DressShopEvent:FireClient(p,'mirror')
for _,o in ipairs(p.Character:GetChildren()) do if o:IsA('Shirt') or o:IsA('Pants') or o:IsA('Accessory') then warn('QQ DRESS OUTFIT '..o.Name..' '..o.ClassName..(o:IsA('Accessory') and (' '..o.AccessoryType.Name) or '')) end end
warn('QQ DRESS VISUAL READY')


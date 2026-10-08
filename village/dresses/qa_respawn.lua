assert(game:GetService('RunService'):IsStudio() and game:GetService('RunService'):IsRunning() and game:GetService('RunService'):IsServer())
local p=game.Players:GetPlayers()[1]
local before=p.Character
local balance=p:GetAttribute('Acorns')
p:LoadCharacterAsync()
task.wait(3)
local c=p.Character
assert(c~=before and c.WornDress:GetAttribute('DressId')=='jardin_2')
assert(c.WornSunglasses:GetAttribute('DressId')=='round_1' and c.WornNecklace:GetAttribute('DressId')=='pearls_1')
assert(p:GetAttribute('Acorns')==balance)
local F=workspace.DressShop
c:PivotTo(CFrame.new(F.DoorPad.Position+Vector3.new(0,0,-3)))
F.DressDebug:Invoke(p,'in');task.wait(1.4)
c:PivotTo(CFrame.new(F:GetAttribute('SpotX'),F:GetAttribute('SpotY')+3,F:GetAttribute('SpotZ')))
game.ReplicatedStorage.DressShopEvent:FireClient(p,'mirror')
warn('QQ BOUTIQUE RESPAWN PASS: all three owned wardrobe slots restored without charges')

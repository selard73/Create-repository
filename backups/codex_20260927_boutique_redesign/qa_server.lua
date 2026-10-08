-- PLAY SERVER ONLY. Studio API access stays OFF; no real player save writes.
assert(game:GetService('RunService'):IsStudio() and game:GetService('RunService'):IsRunning() and game:GetService('RunService'):IsServer(),'Play server only')
local p=game.Players:GetPlayers()[1];assert(p and p:GetAttribute('SaveLoaded'),'Wait for player load')
p:SetAttribute('GateBypass',true);p:SetAttribute('Found_forest',20);p:SetAttribute('Found_village',20)
local f=workspace.DressShop;local d=f.DressDebug
local function request(what,id) task.wait(.3);return d:Invoke(p,'request',{what,id}) end
local function expect(ok,msg) assert(ok,'DRESS QA '..msg);warn('QQ DRESS QA PASS '..msg) end
local char=p.Character;local root=char.HumanoidRootPart;local originalShirt=char.Shirt.ShirtTemplate;local originalPants=char.Pants.PantsTemplate
expect(not request('buy','rue_1'),'remote purchase blocked away from shop')
char:PivotTo(CFrame.new(f.DoorPad.Position+Vector3.new(0,0,-3)))
d:Invoke(p,'in');task.wait(1.3)
warn('QQ DRESS DOOR OBSERVED '..tostring(char:GetAttribute('InDressShop'))..' '..tostring(root.Position)..' pad '..tostring(f.DoorPad.Position))
expect(char:GetAttribute('InDressShop')==true and root.Position.Y>385,'street door enters boutique')
local spot=Vector3.new(f:GetAttribute('SpotX'),f:GetAttribute('SpotY')+3,f:GetAttribute('SpotZ'))
char:PivotTo(CFrame.new(spot));p:SetAttribute('Acorns',0)
expect(not request('buy','rue_1') and not p:GetAttribute('Item_dress_rue_1'),'insufficient funds leave wardrobe untouched')
expect(not request('buy','bogus'),'invalid catalogue ID rejected')
expect(not request('wear','chateau_3'),'unowned dress cannot be worn')
p:SetAttribute('Acorns',1000)
expect(request('buy','rue_1'),'valid purchase accepted');task.wait(.4)
expect(p:GetAttribute('Acorns')==940 and p:GetAttribute('Item_dress_rue_1')==1,'exactly 60 acorns spent; ownership granted once')
expect(char:FindFirstChild('WornDress') and char.WornDress:GetAttribute('DressId')=='rue_1','purchase wears dress')
expect(not request('buy','rue_1') and p:GetAttribute('Acorns')==940,'duplicate purchase blocked without charging')
local count=0;for _,part in ipairs(char.WornDress:GetDescendants()) do if part:IsA('BasePart') then count+=1;expect(not part.CanCollide and not part.Anchored and part.Massless,'wearable piece has safe physics '..count) end end
expect(count==5,'all five garment pieces fitted')
expect(request('wear',''),'take off accepted');task.wait(.4)
expect(not char:FindFirstChild('WornDress') and char.UpperTorso.Transparency==0,'original torso restored')
expect(char.Shirt.ShirtTemplate==originalShirt and char.Pants.PantsTemplate==originalPants,'original clothing restored');expect(request('wear','rue_1'),'owned dress re-equipped without charge');task.wait(.4)
expect(p:GetAttribute('Acorns')==940,'re-equip costs no acorns')
local Cat=require(game.ReplicatedStorage.DressKit.Catalogue)
for _,id in ipairs(Cat.order) do
 local m=Cat.attach(game.ReplicatedStorage.DressKit,id,char,'DressFitTest');expect(m and #m:GetChildren()==5,'fits '..id);m:Destroy()
end
expect(char.Shirt.ShirtTemplate=='' and char.Pants.PantsTemplate=='','classic clothing hidden under dress')
char:PivotTo(CFrame.new(f.Room.Door.Position+Vector3.new(0,0,-3)));d:Invoke(p,'out');task.wait(1.3)
expect(not char:GetAttribute('InDressShop') and root.Position.Y<20,'exit returns to village street')
char:PivotTo(CFrame.new(f.DoorPad.Position+Vector3.new(0,0,-3)));d:Invoke(p,'in');task.wait(1.3)
char:PivotTo(CFrame.new(spot));game.ReplicatedStorage.DressShopEvent:FireClient(p,'mirror')
warn('QQ DRESS QA SERVER COMPLETE; mirror ready for visual review')

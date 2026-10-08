-- Disposable Studio Play server only. Never installed as a running game script.
local Run=game:GetService('RunService')
assert(Run:IsStudio() and Run:IsRunning() and Run:IsServer(),'Play server only')
local p=game.Players:GetPlayers()[1];assert(p and p:GetAttribute('SaveLoaded'))
local F=workspace.DressShop;local debug=F.DressDebug;local Cat=require(game.ReplicatedStorage.DressKit.Catalogue)
local function request(what,id)task.wait(.3);return debug:Invoke(p,'request',{what,id})end
assert(#Cat.order==30 and #Cat.styles==10)
assert(not request('buy','round_1'),'remote purchase blocked away from mirror')
p:SetAttribute('GateBypass',true);p:SetAttribute('Found_forest',20);p:SetAttribute('Found_village',20)
p.Character:PivotTo(CFrame.new(F.DoorPad.Position+Vector3.new(0,0,-3)));debug:Invoke(p,'in');task.wait(1.4)
assert(p.Character:GetAttribute('InDressShop'))
local spot=Vector3.new(F:GetAttribute('SpotX'),F:GetAttribute('SpotY')+3,F:GetAttribute('SpotZ'))
p.Character:PivotTo(CFrame.new(spot))
p:SetAttribute('Acorns',0)
assert(not request('buy','round_1') and not p:GetAttribute('Item_dress_round_1'))
assert(not request('wear','cateye_1') and not request('off','bogus') and not request('buy','bogus'))
p:SetAttribute('Acorns',1000)
local char=p.Character;local shirt=char:FindFirstChildOfClass('Shirt');local pants=char:FindFirstChildOfClass('Pants')
local originalShirt=shirt and shirt.ShirtTemplate;local originalPants=pants and pants.PantsTemplate
assert(request('buy','jardin_2'));assert(request('buy','round_1'));assert(request('buy','pearls_1'));task.wait(.4)
assert(p:GetAttribute('Acorns')==810,'110 + 35 + 45 charged once')
assert(char.WornDress:GetAttribute('DressId')=='jardin_2' and char.WornSunglasses:GetAttribute('DressId')=='round_1' and char.WornNecklace:GetAttribute('DressId')=='pearls_1','three independent slots coexist')
assert(not request('buy','round_1') and p:GetAttribute('Acorns')==810,'no duplicate charging')
assert(request('buy','cateye_2'));task.wait(.4)
assert(p:GetAttribute('Item_dresswear_round_1')==0 and p:GetAttribute('Item_dresswear_cateye_2')==1)
assert(char.WornDress and char.WornNecklace and char.WornSunglasses:GetAttribute('DressId')=='cateye_2')
assert(request('off','dress'));task.wait(.4)
assert(not char:FindFirstChild('WornDress') and char:FindFirstChild('WornSunglasses') and char:FindFirstChild('WornNecklace'))
assert(not shirt or shirt.ShirtTemplate==originalShirt);assert(not pants or pants.PantsTemplate==originalPants)
assert(request('wear','jardin_2'));assert(request('off','eyewear'));task.wait(.4)
assert(char:FindFirstChild('WornDress') and not char:FindFirstChild('WornSunglasses') and char:FindFirstChild('WornNecklace'))
assert(request('wear','round_1'));task.wait(.4)
assert(p:GetAttribute('Acorns')==760,'wearing and taking off are free')
local maxParts=0
for _,id in ipairs(Cat.order)do
 local m=Cat.attach(game.ReplicatedStorage.DressKit,id,char,'FitTest');assert(m,id)
 local count=0
 for _,part in ipairs(m:GetDescendants())do if part:IsA('BasePart')then count+=1;assert(not part.Anchored and not part.CanCollide and part.Massless)end end
 maxParts=math.max(maxParts,count);assert(count<=90,'bounded detail count');m:Destroy()
end
game.ReplicatedStorage.DressShopEvent:FireClient(p,'mirror')
warn('QQ BOUTIQUE QA PASS: 30 products; protected purchases; accurate charges; independent outfit/shades/jewels; free rewear; safe geometry; max '..maxParts..' pieces')

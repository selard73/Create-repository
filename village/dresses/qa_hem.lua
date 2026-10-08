assert(game:GetService('RunService'):IsStudio() and game:GetService('RunService'):IsRunning() and game:GetService('RunService'):IsServer())
local Cat=require(game.ReplicatedStorage.DressKit.Catalogue)
local kit=game.ReplicatedStorage.DressKit
local p=game.Players:GetPlayers()[1];local char=p.Character;local f=workspace.DressShop
p:SetAttribute('GateBypass',true);p:SetAttribute('Found_forest',20);p:SetAttribute('Found_village',20)
char:PivotTo(CFrame.new(f.DoorPad.Position+Vector3.new(0,0,-3)));f.DressDebug:Invoke(p,'in');task.wait(1.4)
char:PivotTo(CFrame.new(f:GetAttribute('SpotX'),f:GetAttribute('SpotY')+3,f:GetAttribute('SpotZ')))
local function request(what,id)task.wait(.35);return f.DressDebug:Invoke(p,'request',{what,id})end
local before={};for _,o in ipairs(char:GetDescendants())do if o:IsA('BasePart')then before[o]=o.Transparency end end
local count=0
for _,style in ipairs(Cat.styles)do if style.slot=='dress' and style.kind~='outfit' then
 local id=style.id..'_1';local m=Cat.attach(kit,id,char,'HemTest');assert(m)
 local hem=m:FindFirstChild('Hem');assert(hem)
 local root=char.HumanoidRootPart;local floor=root.Position.Y-root.Size.Y/2-char.Humanoid.HipHeight
 local bottom=hem.Position.Y-hem.Size.Y/2
 assert(math.abs(bottom-floor)<.3,style.id..' hem misses floor: '..(bottom-floor))
 m:Destroy();count+=1
end end
-- Legacy R6 legs and both R15 feet must be covered by every dress.
local rig=Instance.new('Model')
for _,name in ipairs({'Left Leg','Right Leg','LeftFoot','RightFoot'})do local o=Instance.new('Part');o.Name=name;o.Parent=rig end
for _,style in ipairs(Cat.styles)do if style.slot=='dress' and style.kind~='outfit' then
 local covered=Cat.covered(rig,style.id..'_1');assert(#covered==4,style.id..' missing leg coverage')
end end
assert(#Cat.covered(rig,'adventurer_1')==2,'trousers preserve feet');rig:Destroy()
f.DressDebug:Invoke(p,'give','rue_1');f.DressDebug:Invoke(p,'give','adventurer_1')
assert(request('wear','rue_1'));task.wait(.4)
assert(char.LeftFoot.Transparency==1 and char.RightFoot.Transparency==1,'dress hides feet')
assert(request('wear','adventurer_1'));task.wait(.4)
assert(char.LeftFoot.Transparency==before[char.LeftFoot] and char.RightFoot.Transparency==before[char.RightFoot],'outfit restores feet')
assert(request('wear','rue_1'));assert(request('off','dress'));task.wait(.4)
for o,value in pairs(before)do if o.Parent then assert(o.Transparency==value,'failed restore '..o.Name)end end
game.ReplicatedStorage.DressShopEvent:FireClient(p,'mirror')
warn('QQ HEM QA PASS: '..count..' skirt lengths; R6 legs; R15 feet; dress/outfit switching; original body restored')

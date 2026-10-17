from pathlib import Path
D=Path(__file__).resolve().parent
header='''-- Preview first; permanent Edit application requires Shannon's approval.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and CAFEFLOOR4_ALLOW_EDIT==true),"Preview first; Edit needs approval")
local room=assert(workspace.JapanMap.ShopFronts:FindFirstChild("CatCafeInterior"))
assert(room:GetAttribute("CafeCozyVersion")=="cozy3","Expected cozy3 cafe")
local saved={}
for _,root in ipairs({room,workspace.JapanMap.ShopFronts.CatCafe})do for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")and not(p.Parent and p.Parent.Name=="AlignedFloorBoards")then
 saved[p]={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,variant=p.MaterialVariant,transparency=p.Transparency,collide=p.CanCollide,touch=p.CanTouch,query=p.CanQuery,anchored=p.Anchored,mesh=p:IsA("MeshPart")and p.MeshId or nil}
end end end
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("Before lengthwise cafe floor")end
'''
footer='''
local bridge=game.ReplicatedStorage.CafeInterior2Link
local old=bridge:FindFirstChild("CafeFloorReflectionClient");if old then old:Destroy()end
local client=Instance.new("Script");client.Name="CafeFloorReflectionClient";client.RunContext=Enum.RunContext.Client
client.Source=[====[__CLIENT__]====];client.Parent=bridge
local count=0
for p,b in pairs(saved)do
 assert(p.Parent and p.CFrame==b.cf and p.Size==b.size and p.Color==b.color and p.Material==b.material and p.MaterialVariant==b.variant and p.CanCollide==b.collide and p.CanTouch==b.touch and p.CanQuery==b.query and p.Anchored==b.anchored,"Existing cafe part changed: "..p.Name)
 if b.mesh then assert(p.MeshId==b.mesh,"Original mesh changed")end
 if p.Transparency~=b.transparency then assert(p.Parent==room.Architecture and p.Name:find("Floor")and p.Name~="CI2_FloorBase_OakDark"and p.Transparency==1,"Unexpected hidden part")end
 count+=1
end
assert(count==371,"Expected all371 original cafe parts")
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After lengthwise cafe floor")end
print("QQ CAFE FLOOR CHECK: all371 original parts retain transforms, colors, materials, mesh IDs and physical flags; four old visual surfaces hidden")
print("QQ CAFE FLOOR REFLECTION: client sky reflection .12 only inside cafe; prior value restored on exit; no server lighting change")
print("QQ CAFE FLOOR STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")
'''.replace('__CLIENT__',(D/'floor_reflection_client.lua').read_text())
(D/'install_aligned_floor.lua').write_text(header+(D/'aligned_floor_patch.lua').read_text()+footer)
print('Narrow aligned-floor installer ready')

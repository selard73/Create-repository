from pathlib import Path
D=Path(__file__).resolve().parent
patch=(D/'moss_rug_patch.lua').read_text()
prefix='''-- Narrow rug-only installer. Preview in Play; install in Edit only on Shannon's yes.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and CAFERUGMOSS_ALLOW_EDIT==true),"Rug preview first; Edit needs approval")
local room=assert(workspace.JapanMap.ShopFronts:FindFirstChild("CatCafeInterior"))
assert(room:GetAttribute("CafeSoftPaletteVersion")=="putty_flax1","Expected installed cafe palette")
local saved={};local savedCount=0
for _,root in ipairs({room,workspace.JapanMap.ShopFronts.CatCafe})do for _,p in ipairs(root:GetDescendants())do if p:IsA("BasePart")then
 saved[p]={cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,collide=p.CanCollide,anchored=p.Anchored}
 savedCount+=1
end end end
assert(savedCount==371 or(savedCount==610 and room:FindFirstChild("AlignedFloorBoards")and #room.AlignedFloorBoards:GetChildren()==239),"Unexpected cafe inventory before rug change")
if not Run:IsRunning()then game:GetService("ChangeHistoryService"):SetWaypoint("Before moss cafe rugs")end
'''
suffix='''
local total=0;local changed=0
for p,b in pairs(saved)do
 assert(p.Parent and p.CFrame==b.cf and p.Size==b.size and p.Material==b.material and p.CanCollide==b.collide and p.Anchored==b.anchored,"Unexpected geometry/material change: "..p.Name)
 if p.Color~=b.color then
  assert(p:IsDescendantOf(room)and(p.Name:find("CI2_Rug_",1,true)==1 or p.Name:find("ReadingRug_",1,true)==1),"Unexpected non-rug change")
  changed+=1
 end
 total+=1
end
assert(total==savedCount and(changed==0 or changed==6),"Unexpected installed cafe inventory or partial color change")
if not Run:IsRunning()then game:GetService("ChangeHistoryService"):SetWaypoint("After moss cafe rugs")end
print("QQ CAFE RUG MOSS CHECK: "..changed.." rug color changes; all"..total.." part transforms/materials/collisions/anchoring and all non-rug colors unchanged")
print("QQ CAFE RUG MOSS STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")
'''
(D/'install_moss_rugs.lua').write_text(prefix+patch+suffix)
print('Narrow guarded moss-rug installer prepared')

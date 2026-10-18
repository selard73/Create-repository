-- Exact player-facing wording requested by Shannon. Geometry is untouched.
local Run=game:GetService('RunService')
assert(Run:IsStudio()and game.PlaceId==117372258657114,'Wrong place')
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and POTTERYSTALL_ALLOW_EDIT==true),'Preview first; permanent installation requires approval')
local shop=assert(workspace.JapanMap['Outdoor market revision']:FindFirstChild('Pottery table'))
local label
for _,v in ipairs(shop:GetDescendants())do if v:IsA('TextLabel')and v.Text=='陶器  Pottery table'then assert(not label,'Duplicate pottery label');label=v end end
assert(label,'Expected original pottery label not found; inspect instead')
local hb=assert(game.ServerStorage:FindFirstChild('HudBackup'))
assert(not hb:FindFirstChild('PotteryStallName1'),'Backup exists; inspect instead')
local original=label:Clone()
local backup=Instance.new('Folder');backup.Name='PotteryStallName1'
original.Name='OriginalLabel';original.Parent=backup
backup:SetAttribute('OriginalPath',label:GetFullName())
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint('Before approved pottery stall wording')end
backup.Parent=hb
label:SetAttribute('PotteryStallOriginalText',label.Text)
label.Text='陶器  Pottery stall'
assert(label.Text=='陶器  Pottery stall')
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint('After approved pottery stall wording')end
print('QQ POTTERY STALL1: one visible label changed to 陶器  Pottery stall; original label backed up; geometry and internal model identifier retained')
print('QQ POTTERY STALL1 STATUS: '..(Run:IsRunning()and 'SERVER PREVIEW'or'EDIT INSTALLED')..'; NOT PUBLISHED')

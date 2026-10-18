-- Player-facing tea shop name selected by Shannon. Existing building retained.
local Run=game:GetService('RunService')
assert(Run:IsStudio()and game.PlaceId==117372258657114,'Wrong place')
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and TEAMERCHANT_ALLOW_EDIT==true),'Preview first; permanent installation requires approval')
local shop=assert(workspace.JapanMap['Outdoor market revision']:FindFirstChild('Calligraphy teahouse'))
local label
for _,v in ipairs(shop:GetDescendants())do if v:IsA('TextLabel')and v.Text=='お茶  Calligraphy teahouse'then assert(not label,'Duplicate tea shop label');label=v end end
assert(label,'Expected original tea shop label not found; inspect instead')
local hb=assert(game.ServerStorage:FindFirstChild('HudBackup'))
assert(not hb:FindFirstChild('TeaMerchantName1'),'Backup exists; inspect instead')
local original=label:Clone()
local backup=Instance.new('Folder');backup.Name='TeaMerchantName1'
original.Name='OriginalLabel';original.Parent=backup
backup:SetAttribute('OriginalPath',label:GetFullName())
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint('Before approved tea merchant wording')end
backup.Parent=hb
label:SetAttribute('TeaMerchantOriginalText',label.Text)
label.Text='お茶  Tea Merchant'
assert(label.Text=='お茶  Tea Merchant')
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint('After approved tea merchant wording')end
print('QQ TEA MERCHANT1: one visible label changed to お茶  Tea Merchant; original label backed up; geometry and internal model identifier retained')
print('QQ TEA MERCHANT1 STATUS: '..(Run:IsRunning()and 'SERVER PREVIEW'or'EDIT INSTALLED')..'; NOT PUBLISHED')

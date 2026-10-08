-- pm1 Oct 4 2026 (Shannon): Porto Nocciola gets its own ambient track (1839408249), quiet, starting when you step onto the
-- dock (quay paving begins at z -594). The arrival grass between the falls and the dock is a quiet band like the bridge.
-- Per-area volume: Volume_<area> overrides Volume (Volume_porto 0.15 against 0.28). Patches the live MusicClient in place.
local M=workspace:FindFirstChild('MapMusic')
local mc=M and M:FindFirstChild('MusicClient')
if not mc then warn('QM@ABORT no MusicClient') return end
local s=mc.Source
if s:find('"porto"',1,true) then warn('QM@SKIP already patched') return end
local A1='local x = pos.X\n'
local A2='local vol = folder:GetAttribute("Volume") or 0.35'
local A3='for _, key in ipairs({"forest", "village", "domaine", "race", "climb"}) do'
local miss={}
for k,v in pairs({A1=s:find(A1,1,true),A2=s:find(A2,1,true),A3=s:find(A3,1,true)}) do if not v then table.insert(miss,k) end end
if #miss>0 then warn('QM@ABORT anchors missing',table.concat(miss,',')) return end
local function rep(src,a,b) local i,j=src:find(a,1,true) return src:sub(1,i-1)..b..src:sub(j+1) end
s=rep(s,A1,'local x = pos.X\n'..
	'\tif pos.Z < -540 then                               -- Porto Nocciola (Oct 4 2026): its own track from the dock on;\n'..
	'\t\tif pos.Z < (folder:GetAttribute("PortoZ") or -594) then return "porto" end\n'..
	'\t\treturn nil                                      -- the arrival grass above the quay is a quiet band\n'..
	'\tend\n')
s=rep(s,A2,'local vol = (area and folder:GetAttribute("Volume_" .. area)) or folder:GetAttribute("Volume") or 0.35   -- per-area level (Porto is ambient)')
s=rep(s,A3,'for _, key in ipairs({"forest", "village", "domaine", "race", "climb", "porto"}) do')
s=s..'\n-- a per-area level (Volume_<area>) can be nudged live too\n'..
	'folder.AttributeChanged:Connect(function(n)\n'..
	'\tif current and n == "Volume_" .. tostring(current) and playing.IsPlaying then fadeTo(playing, folder:GetAttribute(n) or folder:GetAttribute("Volume") or 0.35, 0.4) end\n'..
	'end)\n'
local SS=game:GetService('ServerStorage')
local bk=SS:FindFirstChild('MusicBackup') or Instance.new('Folder',SS) bk.Name='MusicBackup'
if not bk:FindFirstChild('MusicClient_v1033') then local x=mc:Clone() x.Name='MusicClient_v1033' x.Disabled=true x.Parent=bk end
mc.Source=s
M:SetAttribute('porto',1839408249) M:SetAttribute('Volume_porto',0.15) M:SetAttribute('PortoZ',-594)
game:GetService('ChangeHistoryService'):SetWaypoint('Porto music')
warn('QM@OK porto music',mc.Source:find('"porto"',1,true)~=nil,M:GetAttribute('porto'),M:GetAttribute('Volume_porto'),#mc.Source)

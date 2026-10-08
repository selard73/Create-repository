-- Oct 5 2026 (Shannon: the tag kept "Grand Keeper of the Great Acorn" instead of Squirrel Maestro): in refreshTag the
-- daily Keeper title (ChampionTitle) always won. Now Squirrel Maestro (tier 4+) shows over it; below tier 4 the Keeper
-- title still wins as before.
local S=workspace.Honours.TitleServer
local s=S.Source
local A='if champ == "" then champ = nil end;'
local n=select(2,s:gsub(A:gsub('%p','%%%0'),''))
if n~=1 then warn('QT2@ABORT anchor count',n) return end
local SS=game:GetService('ServerStorage')
local bk=SS:FindFirstChild('HonoursBackup') or Instance.new('Folder',SS) bk.Name='HonoursBackup'
if not bk:FindFirstChild('TitleServer_v1044') then local x=S:Clone() x.Name='TitleServer_v1044' x.Disabled=true x.Parent=bk end
local i,j=s:find(A,1,true)
S.Source=s:sub(1,i-1)..'if champ == "" or tier >= 4 then champ = nil end; --[[Oct 5 2026: Squirrel Maestro shows over the Keeper title]]'..s:sub(j+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Maestro over Keeper title')
warn('QT2@OK',S.Source:find('tier >= 4 then champ = nil',1,true)~=nil,#S.Source)

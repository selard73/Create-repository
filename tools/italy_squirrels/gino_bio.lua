local reg=workspace.SquirrelScripts.SquirrelRegistry
local s=reg.Source
local old='Swabs the deck of the Azzurra six times a day'
local a,b=s:find(old,1,true)
if not a then warn('QS@NOTFOUND') return end
reg.Source=s:sub(1,a-1)..'Swabs the deck of the Stella Marina six times a day'..s:sub(b+1)
game:GetService('ChangeHistoryService'):SetWaypoint('Gino bio: Stella Marina')
warn('QS@OK',reg.Source:find('Stella Marina six times',1,true)~=nil)

-- READ-ONLY: dump the two tool givers in 450-char chunks (QG2@).
local function dump(tag,s) for i=1,#s,450 do warn('QG2@'..tag..'@'..string.format('%06d',i)..'@'..s:sub(i,i+449)) end end
dump('SLING',workspace.Hoop.SlingServer.Source)
dump('BINO',workspace.Binoculars.BinocularsServer.Source)
warn('QG2@END')

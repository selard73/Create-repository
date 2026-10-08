-- READ-ONLY: SquirrelSetup lines 340-404 and SquirrelAnim lines 870-905 (450-char chunks). QM@
local function lines(scr,a,b)
	local t={} local n=0
	for line in (scr.Source..'\n'):gmatch('(.-)\n') do n+=1 if n>=a and n<=b then table.insert(t,n..': '..line) end end
	return table.concat(t,'\n')
end
local function dump(tag,s) for i=1,#s,450 do warn('QM@'..tag..'@'..string.format('%06d',i)..'@'..s:sub(i,i+449)) end end
dump('SET',lines(workspace.SquirrelScripts.SquirrelSetup,340,404))
dump('ANI',lines(workspace.SquirrelScripts.SquirrelAnim,870,905))
warn('QM@END')

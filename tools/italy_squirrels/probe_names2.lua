-- Oct 5 2026 read-only: every LINE with an old name in the scripts that matter (all occurrences)
local paths={workspace.SquirrelScripts.SquirrelRegistry,workspace.Shop.ShopClient,workspace.CrabGame.CrabServer,game.StarterPlayer.StarterPlayerScripts.CrabClient,game.StarterPlayer.StarterPlayerScripts.TonioTalk}
local OLD={'Timbro','Beppe','Nonno','Giulia','Vito','Remo','Sandro','Enzo','Tonio','Rocco','Lello','Tito'}
for _,s in ipairs(paths) do
	local ln=0
	for line in (s.Source..'\n'):gmatch('(.-)\n') do
		ln+=1
		for _,w in ipairs(OLD) do
			if line:find('%f[%w]'..w..'%f[%W]') then warn('QN2@',s.Name,ln,'::',line:sub(1,400)) break end
		end
	end
end
warn('QN2@DONE')

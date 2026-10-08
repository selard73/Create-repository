-- READ-ONLY probe 5 (Oct 4 2026): SquirrelIllustrations source + which scripts build the HudBar. QF@ lines.
local function dump(tag,s) for i=1,#s,450 do warn('QF@'..tag..'@'..string.format('%06d',i)..'@'..s:sub(i,i+449)) end end
dump('ILLU',game.ReplicatedStorage.SquirrelIllustrations.Source)
for _,d in ipairs(game:GetDescendants()) do
	if d:IsA('LuaSourceContainer') then
		local ok,s=pcall(function() return d.Source end)
		if ok and s:find('HudBar',1,true) then warn('QF@HUD@'..d:GetFullName()..'@'..#s..'@'..(s:find('"HudBar"',1,true) and 'quoted' or '')) end
	end
end
warn('QF@END')

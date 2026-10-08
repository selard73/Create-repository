-- Oct 5 2026 read-only: every script that reads ChampionTitle, with the lines around each use
for _,s in ipairs(game:GetDescendants()) do
	if s:IsA('LuaSourceContainer') and not s:IsDescendantOf(game:GetService('ServerStorage')) then
		local ok,src=pcall(function() return s.Source end)
		if ok and src and src:find('ChampionTitle',1,true) then
			local i=1
			while true do
				local a=src:find('ChampionTitle',i,true) if not a then break end
				local ls=a while ls>1 and src:sub(ls-1,ls-1)~='\n' do ls-=1 end
				local le=src:find('\n',a,true) or #src
				warn('QCH@',s:GetFullName(),s.ClassName,a,'::',src:sub(ls,math.min(le,ls+700)))
				i=le+1
			end
		end
	end
end
warn('QCH@DONE')

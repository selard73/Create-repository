-- READ-ONLY probe 2 (Oct 4 2026): dump ShopServer + ShopClient sources, and every 'Item_' line of the save scripts. QD@ lines.
local function dump(tag,s)
	for i=1,#s,3000 do warn('QD@'..tag..'@'..string.format('%06d',i)..'@'..s:sub(i,i+2999):gsub('\n','\n')) end
end
dump('SSRV',workspace.Shop.ShopServer.Source)
dump('SCLI',workspace.Shop.ShopClient.Source)
for _,d in ipairs(game:GetDescendants()) do
	if d:IsA('LuaSourceContainer') and (d.Name:find('SquirrelSetup') or d.Name:find('Save') or d.Name=='AcornServer') then
		local ok,s=pcall(function() return d.Source end)
		if ok then
			local n=0
			for line in (s..'\n'):gmatch('(.-)\n') do n+=1
				if line:find('Item_',1,true) or line:find('AwardItems',1,true) or line:find('SetAsync',1,true) or line:find('UpdateAsync',1,true) then
					warn('QD@ITEM@'..d:GetFullName()..'@'..n..'@'..line:sub(1,220))
				end
			end
		end
	end
end
warn('QD@END')

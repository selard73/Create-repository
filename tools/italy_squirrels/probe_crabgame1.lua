-- READ-ONLY probe (Oct 4 2026): what the crab-catching game must plug into. Prints QP@ lines to the log; changes nothing.
local pat={'shop','acorn','save','data','fish','pesce','beppe','passport','wardrobe','item','tool','backpack','slingshot','cheese','zoom','tidepool','sign'}
local out={}
for _,d in ipairs(game:GetDescendants()) do
	if d:IsA('LuaSourceContainer') then
		local n=d:GetFullName():lower()
		for _,p in ipairs(pat) do if n:find(p,1,true) then
			local ok,s=pcall(function() return d.Source end)
			table.insert(out,d.ClassName..' '..d:GetFullName()..' '..(ok and #s or -1)) break end end
	end
end
table.sort(out)
for i=1,#out,6 do warn('QP@S',table.concat(out,' | ',i,math.min(i+5,#out))) end
local shop=workspace:FindFirstChild('Shop')
if shop then
	local a={} for k,v in pairs(shop:GetAttributes()) do table.insert(a,k..'='..tostring(v)) end table.sort(a)
	warn('QP@SHOP attrs',table.concat(a,' '))
	local c={} for _,ch in ipairs(shop:GetChildren()) do table.insert(c,ch.Name..':'..ch.ClassName) end
	warn('QP@SHOP kids',table.concat(c,' '))
	warn('QP@SHOP pos',shop:IsA('Model') and tostring(shop:GetPivot().Position) or '-')
end
local rs=game.ReplicatedStorage
local r={} for _,ch in ipairs(rs:GetChildren()) do table.insert(r,ch.Name..':'..ch.ClassName) end
warn('QP@RS',table.concat(r,' '))
-- every 'Shop'-ish model anywhere (Porto may have its own acorn store)
for _,d in ipairs(workspace:GetDescendants()) do
	if (d:IsA('Model') or d:IsA('Folder')) and d.Name:lower():find('shop') then
		local p=d:IsA('Model') and d:GetPivot().Position or nil
		warn('QP@M',d:GetFullName(),p and tostring(p) or '')
	end
end
warn('QP@END')
